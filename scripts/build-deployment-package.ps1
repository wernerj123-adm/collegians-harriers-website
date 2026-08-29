[CmdletBinding()]
param(
    [ValidateSet('staging', 'production')]
    [string]$Channel = 'staging',
    [string]$OutputRoot,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$repositoryRoot = Split-Path -Parent $scriptDirectory
$htaccessTemplate = Join-Path $repositoryRoot 'deployment\production.htaccess'
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $repositoryRoot 'dist'
}
$OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)

function Write-Utf8Text {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Value
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory)] [string]$BasePath,
        [Parameter(Mandatory)] [string]$TargetPath
    )

    $baseFullPath = [System.IO.Path]::GetFullPath($BasePath).TrimEnd('\') + '\'
    $targetFullPath = [System.IO.Path]::GetFullPath($TargetPath)
    $baseUri = New-Object System.Uri($baseFullPath)
    $targetUri = New-Object System.Uri($targetFullPath)
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('/', '\')
}

function Copy-PublicTree {
    param(
        [Parameter(Mandatory)] [string]$Source,
        [Parameter(Mandatory)] [string]$Destination
    )

    $allowedExtensions = @(
        '.css', '.gif', '.html', '.ico', '.jpeg', '.jpg', '.js', '.json',
        '.otf', '.pdf', '.png', '.svg', '.ttf', '.webp', '.woff', '.woff2'
    )
    foreach ($file in Get-ChildItem -LiteralPath $Source -File -Recurse) {
        if ($file.Extension.ToLowerInvariant() -notin $allowedExtensions) { continue }
        $relative = Get-RelativePath -BasePath $Source -TargetPath $file.FullName
        $target = Join-Path $Destination $relative
        [System.IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $target
    }
}

function Resolve-PackageReference {
    param(
        [Parameter(Mandatory)] [string]$Reference,
        [Parameter(Mandatory)] [string]$DocumentDirectory,
        [Parameter(Mandatory)] [string]$SiteRoot,
        [string]$BaseHref
    )

    $clean = ($Reference -split '[?#]', 2)[0].Trim()
    if ([string]::IsNullOrWhiteSpace($clean) -or $clean.StartsWith('#')) { return $null }
    if ($clean -match '^[a-z][a-z0-9+.-]*:' -or $clean.StartsWith('//')) { return $null }
    $clean = [System.Uri]::UnescapeDataString($clean).Replace('/', '\')

    if ($clean.StartsWith('\')) {
        $target = Join-Path $SiteRoot $clean.TrimStart('\')
    }
    else {
        $baseDirectory = $DocumentDirectory
        if (-not [string]::IsNullOrWhiteSpace($BaseHref)) {
            $baseClean = ($BaseHref -split '[?#]', 2)[0].Replace('/', '\')
            if ($baseClean.StartsWith('\')) {
                $baseDirectory = Join-Path $SiteRoot $baseClean.TrimStart('\')
            }
            else {
                $baseDirectory = Join-Path $DocumentDirectory $baseClean
            }
        }
        $target = Join-Path $baseDirectory $clean
    }

    $target = [System.IO.Path]::GetFullPath($target)
    if ($Reference.EndsWith('/')) { $target = Join-Path $target 'index.html' }
    return $target
}

function Test-PackageLinks {
    param([Parameter(Mandatory)] [string]$SiteRoot)

    $missing = New-Object System.Collections.Generic.List[string]
    $sitePrefix = [System.IO.Path]::GetFullPath($SiteRoot).TrimEnd('\') + '\'
    $attributePattern = '(?i)(?:href|src|data-source)\s*=\s*["''](?<url>[^"'']+)["'']'
    $basePattern = '(?i)<base\s+[^>]*href\s*=\s*["''](?<url>[^"'']+)["'']'

    foreach ($document in Get-ChildItem -LiteralPath $SiteRoot -Filter '*.html' -File -Recurse) {
        $content = Get-Content -Raw -LiteralPath $document.FullName
        $baseMatch = [regex]::Match($content, $basePattern)
        $baseHref = if ($baseMatch.Success) { $baseMatch.Groups['url'].Value } else { '' }
        foreach ($match in [regex]::Matches($content, $attributePattern)) {
            $reference = $match.Groups['url'].Value
            if ($baseMatch.Success -and $reference -eq $baseHref) { continue }
            $target = Resolve-PackageReference -Reference $reference -DocumentDirectory $document.DirectoryName -SiteRoot $SiteRoot -BaseHref $baseHref
            if (-not $target) { continue }
            if (-not $target.StartsWith($sitePrefix, [System.StringComparison]::OrdinalIgnoreCase) -and $target.TrimEnd('\') -ne $SiteRoot.TrimEnd('\')) {
                $missing.Add("$($document.FullName): reference escapes package root: $reference") | Out-Null
                continue
            }
            if (-not (Test-Path -LiteralPath $target)) {
                $missing.Add("$($document.FullName): missing $reference") | Out-Null
            }
        }
    }

    $cssPattern = '(?i)url\(\s*["'']?(?<url>[^)"'']+)["'']?\s*\)'
    foreach ($stylesheet in Get-ChildItem -LiteralPath $SiteRoot -Filter '*.css' -File -Recurse) {
        $content = Get-Content -Raw -LiteralPath $stylesheet.FullName
        foreach ($match in [regex]::Matches($content, $cssPattern)) {
            $reference = $match.Groups['url'].Value.Trim()
            $target = Resolve-PackageReference -Reference $reference -DocumentDirectory $stylesheet.DirectoryName -SiteRoot $SiteRoot
            if ($target -and -not (Test-Path -LiteralPath $target)) {
                $missing.Add("$($stylesheet.FullName): missing $reference") | Out-Null
            }
        }
    }

    foreach ($register in Get-ChildItem -LiteralPath (Join-Path $SiteRoot 'assets\data') -Filter '*.json' -File) {
        $content = Get-Content -Raw -LiteralPath $register.FullName
        $referencePattern = '(?i)"(?:file|image|page)"\s*:\s*"(?<url>[^"]+)"'
        foreach ($match in [regex]::Matches($content, $referencePattern)) {
            $reference = $match.Groups['url'].Value
            $target = Resolve-PackageReference -Reference $reference -DocumentDirectory $SiteRoot -SiteRoot $SiteRoot
            if ($target -and -not (Test-Path -LiteralPath $target)) {
                $missing.Add("$($register.FullName): missing $reference") | Out-Null
            }
        }
    }

    if ($missing.Count -gt 0) {
        $details = $missing | ForEach-Object { "  - $_" }
        throw "Package link validation failed:`n$($details -join "`n")"
    }
}

function Optimize-ResultArchivePackage {
    param([Parameter(Mandatory)] [string]$SiteRoot)

    $registerPath = Join-Path $SiteRoot 'assets\data\results-archive.json'
    if (-not (Test-Path -LiteralPath $registerPath -PathType Leaf)) {
        return [pscustomobject]@{ HtmlPages = 0; OmittedPdfs = 0; OmittedPdfBytes = 0 }
    }

    $directPdfReferences = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $attributePattern = '(?i)(?:href|src|data-source)\s*=\s*["''](?<url>[^"'']+\.pdf(?:[?#][^"'']*)?)["'']'
    foreach ($document in Get-ChildItem -LiteralPath $SiteRoot -Filter '*.html' -File -Recurse) {
        $content = Get-Content -Raw -LiteralPath $document.FullName
        foreach ($match in [regex]::Matches($content, $attributePattern)) {
            $reference = ($match.Groups['url'].Value -split '[?#]', 2)[0]
            if ($reference -match '^[a-z][a-z0-9+.-]*:' -or $reference.StartsWith('//')) { continue }
            $target = Resolve-PackageReference -Reference $reference -DocumentDirectory $document.DirectoryName -SiteRoot $SiteRoot
            if ($target -and $target.StartsWith([System.IO.Path]::GetFullPath($SiteRoot), [System.StringComparison]::OrdinalIgnoreCase)) {
                $relative = (Get-RelativePath -BasePath $SiteRoot -TargetPath $target).Replace('\', '/')
                $directPdfReferences.Add($relative) | Out-Null
            }
        }
    }

    $register = Get-Content -Raw -LiteralPath $registerPath | ConvertFrom-Json
    $htmlPages = 0
    $omittedPdfs = 0
    [long]$omittedPdfBytes = 0
    $githubBase = 'https://wernerj123-adm.github.io/collegians-harriers-website/'
    foreach ($record in $register.results) {
        if ([string]::IsNullOrWhiteSpace($record.page) -or [string]::IsNullOrWhiteSpace($record.file)) { continue }
        $htmlPages++
        $localReference = $record.file.Replace('\', '/').TrimStart('/')
        $localPdf = Join-Path $SiteRoot $localReference.Replace('/', '\')
        $record.file = $githubBase + $localReference
        if ($directPdfReferences.Contains($localReference) -or -not (Test-Path -LiteralPath $localPdf -PathType Leaf)) { continue }
        $pdfInfo = Get-Item -LiteralPath $localPdf
        $omittedPdfBytes += $pdfInfo.Length
        Remove-Item -LiteralPath $localPdf -Force
        $omittedPdfs++
    }
    Write-Utf8Text -Path $registerPath -Value (($register | ConvertTo-Json -Depth 8) + "`n")

    $currentRegisterPath = Join-Path $SiteRoot 'assets\data\results.json'
    if (Test-Path -LiteralPath $currentRegisterPath -PathType Leaf) {
        $currentRegister = Get-Content -Raw -LiteralPath $currentRegisterPath | ConvertFrom-Json
        foreach ($record in $currentRegister.results) {
            if ([string]::IsNullOrWhiteSpace($record.page) -or [string]::IsNullOrWhiteSpace($record.file)) { continue }
            $localReference = $record.file.Replace('\', '/').TrimStart('/')
            if (-not $localReference.StartsWith('assets/results/archive/', [System.StringComparison]::OrdinalIgnoreCase)) { continue }
            $record.file = $githubBase + $localReference
        }
        Write-Utf8Text -Path $currentRegisterPath -Value (($currentRegister | ConvertTo-Json -Depth 8) + "`n")
    }

    return [pscustomobject]@{ HtmlPages = $htmlPages; OmittedPdfs = $omittedPdfs; OmittedPdfBytes = $omittedPdfBytes }
}

Push-Location $repositoryRoot
try {
    $branch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Unable to determine the current Git branch.' }
    $requiredBranch = if ($Channel -eq 'production') { 'main' } else { 'develop' }
    if ($branch -ne $requiredBranch) {
        throw "$Channel packages must be built from $requiredBranch. Current branch: $branch"
    }

    $workingChanges = @(& git status --porcelain)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect the Git working tree.' }
    if ($workingChanges.Count -gt 0) {
        throw 'The working tree is not clean. Commit or remove pending changes before building a deployment package.'
    }

    $commit = (& git rev-parse HEAD).Trim()
    $shortCommit = (& git rev-parse --short=8 HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Unable to read the current Git commit.' }
    if (-not (Test-Path -LiteralPath $htaccessTemplate -PathType Leaf)) {
        throw "Deployment server configuration not found: $htaccessTemplate"
    }

    $buildRoot = Join-Path $OutputRoot "$Channel-$shortCommit"
    $siteRoot = Join-Path $buildRoot 'site'
    $zipPath = Join-Path $OutputRoot "collegians-harriers-$Channel-$shortCommit.zip"
    if ((Test-Path -LiteralPath $buildRoot) -or (Test-Path -LiteralPath $zipPath)) {
        if (-not $Force) {
            throw "A package for $shortCommit already exists. Use -Force to rebuild this exact commit."
        }
        $outputPrefix = [System.IO.Path]::GetFullPath($OutputRoot).TrimEnd('\') + '\'
        foreach ($target in @($buildRoot, $zipPath)) {
            $resolvedTarget = [System.IO.Path]::GetFullPath($target)
            if (-not $resolvedTarget.StartsWith($outputPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "Unsafe deployment cleanup target: $resolvedTarget"
            }
            if (Test-Path -LiteralPath $resolvedTarget) { Remove-Item -LiteralPath $resolvedTarget -Recurse -Force }
        }
    }

    [System.IO.Directory]::CreateDirectory($siteRoot) | Out-Null
    foreach ($page in Get-ChildItem -LiteralPath $repositoryRoot -Filter '*.html' -File) {
        Copy-Item -LiteralPath $page.FullName -Destination (Join-Path $siteRoot $page.Name)
    }
    Copy-PublicTree -Source (Join-Path $repositoryRoot 'assets') -Destination (Join-Path $siteRoot 'assets')
    Copy-PublicTree -Source (Join-Path $repositoryRoot 'results') -Destination (Join-Path $siteRoot 'results')
    Copy-Item -LiteralPath $htaccessTemplate -Destination (Join-Path $siteRoot '.htaccess')

    $notFoundPath = Join-Path $siteRoot '404.html'
    $notFound = Get-Content -Raw -LiteralPath $notFoundPath
    $githubBase = '<base href="/collegians-harriers-website/">'
    if (-not $notFound.Contains($githubBase)) {
        throw 'The source 404 base path has changed. Review the production rewrite before packaging.'
    }
    Write-Utf8Text -Path $notFoundPath -Value $notFound.Replace($githubBase, '<base href="/">')

    $archiveOptimization = Optimize-ResultArchivePackage -SiteRoot $siteRoot
    Test-PackageLinks -SiteRoot $siteRoot

    $forbidden = @(Get-ChildItem -LiteralPath $siteRoot -File -Recurse | Where-Object {
        $_.Extension.ToLowerInvariant() -in @('.cmd', '.md', '.ps1', '.py', '.zip')
    })
    if ($forbidden.Count -gt 0) {
        throw "Administrative files entered the public package: $($forbidden.FullName -join ', ')"
    }

    $publicFiles = @(Get-ChildItem -LiteralPath $siteRoot -File -Recurse)
    $manifest = [ordered]@{
        channel       = $Channel
        sourceBranch  = $branch
        sourceCommit  = $commit
        builtAtUtc    = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        productionRoot = '/'
        fileCount     = $publicFiles.Count + 1
        contentBytes  = ($publicFiles | Measure-Object -Property Length -Sum).Sum
        htmlResultPages = $archiveOptimization.HtmlPages
        omittedArchivePdfs = $archiveOptimization.OmittedPdfs
        omittedArchivePdfBytes = $archiveOptimization.OmittedPdfBytes
    }
    Write-Utf8Text -Path (Join-Path $siteRoot 'deployment-manifest.json') -Value (($manifest | ConvertTo-Json -Depth 4) + "`n")

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $siteRoot,
        $zipPath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false
    )

    $archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $archiveNames = @($archive.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
        foreach ($required in @('index.html', '404.html', '.htaccess', 'deployment-manifest.json', 'assets/data/results.json')) {
            if ($required -notin $archiveNames) { throw "Deployment ZIP is missing $required" }
        }
    }
    finally {
        $archive.Dispose()
    }

    Write-Host ''
    Write-Host "$Channel deployment package created successfully." -ForegroundColor Green
    Write-Host "  Source commit: $shortCommit"
    Write-Host "  Public files:  $($manifest.fileCount)"
    Write-Host "  HTML results:  $($manifest.htmlResultPages)"
    Write-Host "  PDFs omitted:  $($manifest.omittedArchivePdfs) ($($manifest.omittedArchivePdfBytes) bytes)"
    Write-Host "  Site folder:   $siteRoot"
    Write-Host "  Upload ZIP:    $zipPath"
    Write-Host ''
    Write-Host 'No hosting account was accessed and no production files were changed.' -ForegroundColor Yellow
}
finally {
    Pop-Location
}
