[CmdletBinding()]
param(
    [string]$InboxPath,
    [ValidateSet('time-trial', 'training', 'race-day', 'trail-running', 'hosted-event', 'club-gathering')]
    [string]$DefaultActivity = 'club-gathering',
    [string]$DateOverride,
    [string]$TitleOverride,
    [string]$AltOverride,
    [string]$CaptionOverride,
    [switch]$NonInteractive,
    [switch]$DryRun,
    [switch]$Publish
)

$ErrorActionPreference = 'Stop'

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$repositoryRoot = Split-Path -Parent $scriptDirectory
$manifestPath = Join-Path $repositoryRoot 'assets\data\photos.json'
if ([string]::IsNullOrWhiteSpace($InboxPath)) {
    $InboxPath = Join-Path $repositoryRoot 'photo-inbox'
}
$InboxPath = [System.IO.Path]::GetFullPath($InboxPath)

$activityLabels = [ordered]@{
    'time-trial'     = 'Time trial'
    'training'       = 'Training'
    'race-day'       = 'Race day'
    'trail-running'  = 'Trail running'
    'hosted-event'   = 'Hosted event'
    'club-gathering' = 'Club gathering'
}

function Write-Utf8Json {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] $Value
    )

    $json = $Value | ConvertTo-Json -Depth 8
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, "$json`n", $utf8WithoutBom)
}

function Read-WithDefault {
    param(
        [Parameter(Mandatory)] [string]$Prompt,
        [Parameter(Mandatory)] [string]$Default
    )

    $answer = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
    return $answer.Trim()
}

function Read-ActivityChoice {
    param([Parameter(Mandatory)] [string]$DefaultKey)

    Write-Host 'Choose an activity:'
    $activityKeys = @($activityLabels.Keys)
    for ($index = 0; $index -lt $activityKeys.Count; $index++) {
        Write-Host "  $($index + 1). $($activityLabels[$activityKeys[$index]])"
    }
    $defaultNumber = [array]::IndexOf($activityKeys, $DefaultKey) + 1
    do {
        $activityChoice = Read-Host "Activity number [$defaultNumber]"
        if ([string]::IsNullOrWhiteSpace($activityChoice)) { $activityChoice = [string]$defaultNumber }
        $choiceNumber = 0
        $validChoice = [int]::TryParse($activityChoice, [ref]$choiceNumber) -and $choiceNumber -ge 1 -and $choiceNumber -le $activityKeys.Count
        if (-not $validChoice) { Write-Host 'Enter one of the activity numbers shown above.' -ForegroundColor Yellow }
    } until ($validChoice)
    return $activityKeys[$choiceNumber - 1]
}

function Get-DefaultTitle {
    param([Parameter(Mandatory)] [string]$BaseName)

    $words = $BaseName -replace '^\d{4}-\d{2}-\d{2}-', ''
    $words = ($words -replace '[-_]+', ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($words)) { return 'Club activity' }
    return (Get-Culture).TextInfo.ToTitleCase($words.ToLowerInvariant())
}

function Get-Slug {
    param([Parameter(Mandatory)] [string]$Value)

    $slug = $Value.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $slug = ($slug -replace '-+', '-').Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) { return 'club-photo' }
    return $slug
}

function Get-WeekStart {
    param([Parameter(Mandatory)] [datetime]$Date)

    $daysSinceMonday = (([int]$Date.DayOfWeek + 6) % 7)
    return $Date.Date.AddDays(-$daysSinceMonday).ToString('yyyy-MM-dd')
}

function Test-ImageFile {
    param([Parameter(Mandatory)] [string]$Path)

    Add-Type -AssemblyName System.Drawing
    $image = $null
    try {
        $image = [System.Drawing.Image]::FromFile($Path)
        return $image.Width -gt 0 -and $image.Height -gt 0
    }
    catch {
        return $false
    }
    finally {
        if ($null -ne $image) { $image.Dispose() }
    }
}

if (-not (Test-Path -LiteralPath $InboxPath -PathType Container)) {
    throw "Photo inbox not found: $InboxPath"
}
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Photo register not found: $manifestPath"
}

$photoFiles = @(Get-ChildItem -LiteralPath $InboxPath -File | Where-Object { $_.Extension.ToLowerInvariant() -in @('.jpg', '.jpeg', '.png') } | Sort-Object Name)
if ($photoFiles.Count -eq 0) {
    Write-Host "No JPG, JPEG or PNG files were found in $InboxPath"
    Write-Host 'Add approved photographs to the inbox and run the publisher again.'
    exit 0
}
if ($photoFiles.Count -gt 1 -and (-not [string]::IsNullOrWhiteSpace($TitleOverride) -or -not [string]::IsNullOrWhiteSpace($AltOverride) -or -not [string]::IsNullOrWhiteSpace($CaptionOverride))) {
    throw 'TitleOverride, AltOverride and CaptionOverride can only be used when the inbox contains one photograph.'
}

$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$records = @($manifest.photos)
$preparedPaths = New-Object System.Collections.Generic.List[string]
$preparedCount = 0
$useSharedInfo = $false
$sharedDateText = ''
$sharedActivityKey = $DefaultActivity

if (-not $NonInteractive -and $photoFiles.Count -gt 1) {
    Write-Host ''
    Write-Host "$($photoFiles.Count) photographs found."
    Write-Host '  1. Apply shared weekly information to all files'
    Write-Host '  2. Enter information individually for every file'
    do {
        $informationMode = Read-Host 'Information mode [1]'
        if ([string]::IsNullOrWhiteSpace($informationMode)) { $informationMode = '1' }
        $validMode = $informationMode -in @('1', '2')
        if (-not $validMode) { Write-Host 'Enter 1 or 2.' -ForegroundColor Yellow }
    } until ($validMode)
    $useSharedInfo = $informationMode -eq '1'

    if ($useSharedInfo) {
        $firstDate = if (-not [string]::IsNullOrWhiteSpace($DateOverride)) { $DateOverride.Trim() } elseif ($photoFiles[0].BaseName -match '^(\d{4}-\d{2}-\d{2})') { $Matches[1] } else { Get-Date -Format 'yyyy-MM-dd' }
        do {
            $sharedDateText = Read-WithDefault -Prompt 'Shared activity date (YYYY-MM-DD)' -Default $firstDate
            $sharedParsedDate = [datetime]::MinValue
            $validSharedDate = [datetime]::TryParseExact($sharedDateText, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$sharedParsedDate)
            if (-not $validSharedDate) { Write-Host 'Enter a valid date in YYYY-MM-DD format.' -ForegroundColor Yellow }
        } until ($validSharedDate)
        $sharedActivityKey = Read-ActivityChoice -DefaultKey $DefaultActivity
        Write-Host 'Titles and captions will be generated from filenames. Use descriptive filenames for shared mode.' -ForegroundColor DarkGray
    }
}

foreach ($photo in $photoFiles) {
    Write-Host ''
    Write-Host "Reviewing $($photo.Name)" -ForegroundColor Cyan

    if (-not (Test-ImageFile -Path $photo.FullName)) {
        Write-Warning "$($photo.Name) is not a valid JPG or PNG image and was left in the inbox."
        continue
    }

    if ($photo.Length -gt 3MB) {
        Write-Warning "$($photo.Name) is larger than 3 MB. Consider resizing it for faster website loading."
    }

    $dateText = if ($useSharedInfo) { $sharedDateText } elseif (-not [string]::IsNullOrWhiteSpace($DateOverride)) { $DateOverride.Trim() } elseif ($photo.BaseName -match '^(\d{4}-\d{2}-\d{2})') { $Matches[1] } else { '' }
    if ($NonInteractive -and [string]::IsNullOrWhiteSpace($dateText)) {
        Write-Warning "$($photo.Name) does not begin with YYYY-MM-DD and no DateOverride was supplied. It was skipped."
        continue
    }
    if (-not $NonInteractive -and -not $useSharedInfo) {
        $dateText = Read-WithDefault -Prompt 'Activity date (YYYY-MM-DD)' -Default $(if ($dateText) { $dateText } else { (Get-Date -Format 'yyyy-MM-dd') })
    }

    $parsedDate = [datetime]::MinValue
    if (-not [datetime]::TryParseExact($dateText, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$parsedDate)) {
        Write-Warning "$dateText is not a valid YYYY-MM-DD date. $($photo.Name) was skipped."
        continue
    }

    $defaultTitle = Get-DefaultTitle -BaseName $photo.BaseName
    $title = if (-not [string]::IsNullOrWhiteSpace($TitleOverride)) { $TitleOverride.Trim() } elseif ($NonInteractive -or $useSharedInfo) { $defaultTitle } else { Read-WithDefault -Prompt 'Public photo title' -Default $defaultTitle }
    $activityKey = if ($useSharedInfo) { $sharedActivityKey } else { $DefaultActivity }

    if (-not $NonInteractive -and -not $useSharedInfo) {
        $activityKey = Read-ActivityChoice -DefaultKey $DefaultActivity
    }

    $defaultAlt = if ($useSharedInfo) { "$title - Collegians Harriers $($activityLabels[$activityKey].ToLowerInvariant())" } else { "Collegians Harriers $($activityLabels[$activityKey].ToLowerInvariant()) activity" }
    $alt = if (-not [string]::IsNullOrWhiteSpace($AltOverride)) { $AltOverride.Trim() } elseif ($NonInteractive -or $useSharedInfo) { $defaultAlt } else { Read-WithDefault -Prompt 'Alternative text describing what is visible' -Default $defaultAlt }
    $defaultCaption = $title
    $caption = if (-not [string]::IsNullOrWhiteSpace($CaptionOverride)) { $CaptionOverride.Trim() } elseif ($NonInteractive -or $useSharedInfo) { $defaultCaption } else { Read-WithDefault -Prompt 'Short public caption' -Default $defaultCaption }

    $year = $parsedDate.Year
    $extension = $photo.Extension.ToLowerInvariant()
    $safeName = "$dateText-$(Get-Slug -Value $title)$extension"
    $yearDirectory = Join-Path $repositoryRoot "assets\img\gallery\$year"
    $destinationPath = Join-Path $yearDirectory $safeName
    $relativePath = "assets/img/gallery/$year/$safeName"

    if (Test-Path -LiteralPath $destinationPath) {
        Write-Warning "$relativePath already exists. Nothing was overwritten."
        continue
    }
    if (@($records | Where-Object { $_.image -eq $relativePath }).Count -gt 0) {
        Write-Warning "$relativePath is already registered and was skipped."
        continue
    }

    Write-Host "  Title:    $title"
    Write-Host "  Date:     $dateText"
    Write-Host "  Activity: $($activityLabels[$activityKey])"
    Write-Host "  Image:    $relativePath"
    Write-Host "  Alt text: $alt"
    Write-Host "  Caption:  $caption"

    if ($DryRun) {
        Write-Host '  Dry run: no file or register changes made.' -ForegroundColor Yellow
        $preparedCount++
        continue
    }

    [System.IO.Directory]::CreateDirectory($yearDirectory) | Out-Null
    Move-Item -LiteralPath $photo.FullName -Destination $destinationPath
    $records += [pscustomobject][ordered]@{
        title    = $title
        date     = $dateText
        week     = Get-WeekStart -Date $parsedDate
        year     = $year
        activity = $activityLabels[$activityKey]
        image    = $relativePath
        alt      = $alt
        caption  = $caption
    }
    $preparedPaths.Add($relativePath) | Out-Null
    $preparedCount++
}

if ($DryRun) {
    Write-Host ''
    Write-Host "Dry run complete: $preparedCount photo(s) checked; nothing changed." -ForegroundColor Green
    exit 0
}

if ($preparedCount -eq 0) {
    Write-Host ''
    Write-Host 'No photographs were prepared. The register was not changed.'
    exit 0
}

$manifest.updated = Get-Date -Format 'yyyy-MM-dd'
$manifest.photos = @($records | Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'title'; Descending = $false })
Write-Utf8Json -Path $manifestPath -Value $manifest
$null = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
Write-Host ''
Write-Host "$preparedCount photograph(s) prepared successfully." -ForegroundColor Green

$publishNow = $Publish
if (-not $NonInteractive -and -not $Publish) {
    $publishAnswer = Read-Host 'Commit and push these photos to the develop preview now? (y/N)'
    $publishNow = $publishAnswer -match '^(y|yes)$'
}

if (-not $publishNow) {
    Write-Host 'The photographs are prepared locally but have not been published.'
    Write-Host 'Commit and push the prepared files manually when they are approved.'
    exit 0
}

Push-Location $repositoryRoot
try {
    $branch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'develop') {
        throw "Publishing requires the develop branch. Current branch: $branch"
    }

    & git diff --cached --quiet
    if ($LASTEXITCODE -eq 1) { throw 'Other staged Git changes already exist. Commit or unstage them before publishing photos.' }
    if ($LASTEXITCODE -gt 1) { throw 'Unable to check the staged Git changes.' }

    $gitPaths = @('assets/data/photos.json') + @($preparedPaths)
    & git add -- @gitPaths
    if ($LASTEXITCODE -ne 0) { throw 'Git could not stage the prepared photographs.' }

    $commitMessage = if ($preparedCount -eq 1) { 'content: publish approved club photo' } else { "content: publish $preparedCount approved club photos" }
    & git commit -m $commitMessage
    if ($LASTEXITCODE -ne 0) { throw 'Git could not create the photo commit.' }

    & git push origin develop
    if ($LASTEXITCODE -ne 0) { throw 'The commit was created, but Git could not push it to develop.' }

    Write-Host ''
    Write-Host 'Photos published to develop. Check GitHub Pages after the deployment finishes.' -ForegroundColor Green
}
finally {
    Pop-Location
}
