[CmdletBinding()]
param(
    [ValidateSet('staging', 'production')]
    [string]$Channel = 'staging',
    [string]$Site,
    # Defaults to the branch the chosen site tracks, not the branch you happen
    # to have checked out: staging follows develop, the live site follows main.
    [string]$Ref
)

$ErrorActionPreference = 'Stop'

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$repositoryRoot = Split-Path -Parent $scriptDirectory
$defaultSites = @{
    staging    = 'https://staging.collegiansharriers.co.za'
    production = 'https://collegiansharriers.co.za'
}
if ([string]::IsNullOrWhiteSpace($Site)) { $Site = $defaultSites[$Channel] }
$Site = $Site.TrimEnd('/')

if ([string]::IsNullOrWhiteSpace($Ref)) {
    $branch = if ($Channel -eq 'production') { 'main' } else { 'develop' }
    Push-Location $repositoryRoot
    try {
        # Prefer the fetched remote branch: a stale local copy would compare
        # the site against work that was never pushed.
        & git rev-parse --verify --quiet "origin/$branch" > $null
        $Ref = if ($LASTEXITCODE -eq 0) { "origin/$branch" } else { $branch }
    } finally { Pop-Location }
}

function Get-Text {
    param(
        [Parameter(Mandatory)] [string]$Url,
        [switch]$MissingOk
    )

    try {
        return (Invoke-WebRequest -Uri $Url -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' }).Content
    } catch {
        $status = $null
        if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
        if ($MissingOk -and $status -eq 404) { return $null }
        throw "Could not read $Url ($($_.Exception.Message))"
    }
}

function Get-Committed {
    param([Parameter(Mandatory)] [string]$Path)

    Push-Location $repositoryRoot
    try {
        $content = & git show "${Ref}:$Path" 2>$null
        if ($LASTEXITCODE -ne 0) { return $null }
        return ($content -join "`n")
    } finally { Pop-Location }
}

function Get-Sha256 {
    param([Parameter(Mandatory)] [string]$Value)

    # Compare rendered text, not bytes: line endings differ between a Git
    # checkout and an uploaded file without the content being different.
    $normalised = $Value -replace "`r`n", "`n"
    $stream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($normalised))
    try { return (Get-FileHash -InputStream $stream -Algorithm SHA256).Hash } finally { $stream.Dispose() }
}

function Get-PackagedFile {
    param(
        # No package on disk is normal: the check then compares registers only.
        [Parameter(Mandatory)] [AllowNull()] [AllowEmptyString()] [string]$SiteRoot,
        [Parameter(Mandatory)] [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($SiteRoot)) { return $null }
    $candidate = Join-Path $SiteRoot ($Path -replace '/', '\')
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { return $null }
    return [System.IO.File]::ReadAllText($candidate)
}

function Read-Register {
    param([Parameter(Mandatory)] [string]$Json)

    $parsed = $Json | ConvertFrom-Json
    if ($null -eq $parsed.results) { throw 'Unexpected register format: no results array.' }
    return @($parsed.results)
}

Push-Location $repositoryRoot
try {
    $resolved = (& git rev-parse --short=8 $Ref).Trim()
    if ($LASTEXITCODE -ne 0) { throw "Unknown Git reference: $Ref" }
} finally { Pop-Location }

Write-Host "Checking $Site against $Ref ($resolved)."
Write-Host ''

$findings = New-Object System.Collections.Generic.List[string]

$manifestJson = Get-Text -Url "$Site/deployment-manifest.json" -MissingOk
if ($null -eq $manifestJson) {
    $findings.Add('No deployment-manifest.json: the site was not deployed from a built package.')
} else {
    $manifest = $manifestJson | ConvertFrom-Json
    $deployed = $manifest.sourceCommit.Substring(0, 8)
    Write-Host "  Deployed package: $($manifest.channel) $deployed ($($manifest.fileCount) files)"
    if ($manifest.sourceCommit -notlike "$resolved*") {
        # A site is not stale when the only newer commits changed things no
        # deployment publishes. The workflows skip docs and Markdown, so a
        # handbook-only release legitimately leaves the sites where they were.
        Push-Location $repositoryRoot
        try {
            $changed = @(& git diff --name-only $manifest.sourceCommit $resolved 2>$null)
            $comparable = $LASTEXITCODE -eq 0 -and $changed.Count -gt 0
        } finally { Pop-Location }
        $unpublished = $comparable -and -not ($changed | Where-Object { $_ -notmatch '^docs/' -and $_ -notmatch '\.md$' })
        if ($unpublished) {
            Write-Host "  Newer commits change only documentation ($($changed.Count) file(s)), which is never deployed."
        } else {
            $findings.Add("The deployed package was built from $deployed, not $resolved. Rebuild or promote before comparing further.")
        }
    }
}

# Published pages are not identical to their sources: the builder rewrites the
# 404 base path and archive references while packaging. Compare against the
# built package for that commit when it is still on disk, and otherwise limit
# the check to what is tracked and registered.
$packagedSiteRoot = $null
if ($null -ne $manifestJson) {
    $candidate = Join-Path $repositoryRoot "dist\$($manifest.channel)-$deployed\site"
    if (Test-Path -LiteralPath $candidate -PathType Container) { $packagedSiteRoot = $candidate }
}
if ($packagedSiteRoot) {
    Write-Host "  Comparing against: dist\$($manifest.channel)-$deployed\site"
} else {
    Write-Host '  Comparing against: register only (build the package for this commit to compare page content)'
}

$registerPath = 'assets/data/results.json'
$liveRegister = Read-Register (Get-Text -Url "$Site/$registerPath")
$committedJson = Get-Committed -Path $registerPath
if ($null -eq $committedJson) { throw "$registerPath is not committed at $Ref." }
$committedRegister = Read-Register $committedJson

Write-Host "  Result register:  $($liveRegister.Count) published, $($committedRegister.Count) tracked"
Write-Host ''

$trackedPages = @{}
foreach ($record in $committedRegister) { $trackedPages[$record.page] = $record }

foreach ($record in $liveRegister) {
    if (-not $trackedPages.ContainsKey($record.page)) {
        $findings.Add("Published but not tracked: $($record.page) ($($record.date), $($record.title))")
        continue
    }
    # The page is registered in both. Confirm the file itself exists in Git and,
    # where the built package is available, that the site serves what it built.
    if ($null -eq (Get-Committed -Path $record.page)) {
        $findings.Add("Registered at $Ref but the file itself is missing from Git: $($record.page)")
        continue
    }
    $publishedPage = Get-Text -Url "$Site/$($record.page)" -MissingOk
    if ($null -eq $publishedPage) {
        $findings.Add("Registered and tracked, but not published on the site: $($record.page)")
        continue
    }
    $packagedPage = Get-PackagedFile -SiteRoot $packagedSiteRoot -Path $record.page
    if ($null -ne $packagedPage -and (Get-Sha256 $publishedPage) -ne (Get-Sha256 $packagedPage)) {
        $findings.Add("Published content differs from the built package: $($record.page)")
    }
}

foreach ($record in $committedRegister) {
    if (-not ($liveRegister | Where-Object { $_.page -eq $record.page })) {
        $findings.Add("Tracked but missing from the published register: $($record.page)")
    }
}

if ($findings.Count -eq 0) {
    Write-Host 'No drift: everything published is tracked in Git and matches it.'
    exit 0
}

Write-Host "Drift found ($($findings.Count)):" -ForegroundColor Yellow
foreach ($finding in $findings) { Write-Host "  - $finding" }
Write-Host ''
Write-Host 'Anything published but not tracked will be removed the next time a deployment'
Write-Host 'package is extracted over this site. Bring it into the repository first.'
exit 1
