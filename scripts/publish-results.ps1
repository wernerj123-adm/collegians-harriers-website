[CmdletBinding()]
param(
    [string]$InboxPath,
    [ValidateSet('time-trial', 'road', 'trail', 'championship', 'hosted-event')]
    [string]$DefaultCategory = 'time-trial',
    [string]$TitleOverride,
    [string]$NoteOverride,
    [string]$PagePath,
    [switch]$NonInteractive,
    [switch]$DryRun,
    [switch]$Publish
)

$ErrorActionPreference = 'Stop'

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$repositoryRoot = Split-Path -Parent $scriptDirectory
$manifestPath = Join-Path $repositoryRoot 'assets\data\results.json'
$timeTrialConverterPath = Join-Path $scriptDirectory 'build-time-trial-html.py'
if ([string]::IsNullOrWhiteSpace($InboxPath)) {
    $InboxPath = Join-Path $repositoryRoot 'results-inbox'
}
$InboxPath = [System.IO.Path]::GetFullPath($InboxPath)

$categoryLabels = [ordered]@{
    'time-trial'    = 'Time trial'
    'road'          = 'Road'
    'trail'         = 'Trail'
    'championship'  = 'Championship'
    'hosted-event'  = 'Hosted event'
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

function Test-PdfHeader {
    param([Parameter(Mandatory)] [string]$Path)

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $buffer = New-Object byte[] 5
        if ($stream.Read($buffer, 0, 5) -ne 5) { return $false }
        return [System.Text.Encoding]::ASCII.GetString($buffer) -eq '%PDF-'
    }
    finally {
        $stream.Dispose()
    }
}

function Get-DefaultTitle {
    param([Parameter(Mandatory)] [string]$BaseName)

    $words = $BaseName -replace '^\d{4}-\d{2}-\d{2}-', ''
    $words = $words -replace '-results$', ''
    $words = ($words -replace '[-_]+', ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($words)) { return 'Club results' }
    return (Get-Culture).TextInfo.ToTitleCase($words.ToLowerInvariant())
}

function Get-PythonExecutable {
    foreach ($commandName in @('python', 'py')) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    return $null
}

function Convert-TimeTrialPdf {
    param(
        [Parameter(Mandatory)] [string]$PdfPath,
        [Parameter(Mandatory)] [string]$OutputPath,
        [Parameter(Mandatory)] [string]$Date,
        [Parameter(Mandatory)] [string]$Title,
        [Parameter(Mandatory)] [string]$PdfWebPath,
        [switch]$ValidateOnly
    )

    if (-not (Test-Path -LiteralPath $timeTrialConverterPath -PathType Leaf)) {
        throw "Time-trial HTML converter not found: $timeTrialConverterPath"
    }
    $python = Get-PythonExecutable
    if (-not $python) {
        throw 'Python is required for time-trial HTML conversion. Install Python, then run: py -m pip install pdfplumber'
    }

    $arguments = @(
        $timeTrialConverterPath,
        '--pdf', $PdfPath,
        '--date', $Date,
        '--title', $Title,
        '--pdf-web-path', $PdfWebPath
    )
    if ($ValidateOnly) {
        $arguments += '--validate-only'
    }
    else {
        $arguments += @('--output', $OutputPath)
    }

    $conversionOutput = @(& $python @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        $details = ($conversionOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        if ($details -match 'No module named [''"]pdfplumber[''"]') {
            $details += "`nInstall the required reader with: py -m pip install pdfplumber"
        }
        throw $details
    }
    try {
        return ($conversionOutput[-1].ToString() | ConvertFrom-Json)
    }
    catch {
        throw "The time-trial converter did not return a valid summary for $PdfPath"
    }
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

function Read-CategoryChoice {
    param([Parameter(Mandatory)] [string]$DefaultKey)

    Write-Host 'Choose a category:'
    $categoryKeys = @($categoryLabels.Keys)
    for ($index = 0; $index -lt $categoryKeys.Count; $index++) {
        Write-Host "  $($index + 1). $($categoryLabels[$categoryKeys[$index]])"
    }
    $defaultNumber = [array]::IndexOf($categoryKeys, $DefaultKey) + 1
    do {
        $categoryChoice = Read-Host "Category number [$defaultNumber]"
        if ([string]::IsNullOrWhiteSpace($categoryChoice)) { $categoryChoice = [string]$defaultNumber }
        $choiceNumber = 0
        $validChoice = [int]::TryParse($categoryChoice, [ref]$choiceNumber) -and $choiceNumber -ge 1 -and $choiceNumber -le $categoryKeys.Count
        if (-not $validChoice) { Write-Host 'Enter one of the category numbers shown above.' -ForegroundColor Yellow }
    } until ($validChoice)
    return $categoryKeys[$choiceNumber - 1]
}

if (-not (Test-Path -LiteralPath $InboxPath -PathType Container)) {
    throw "Results inbox not found: $InboxPath"
}
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Results register not found: $manifestPath"
}

$pdfFiles = @(Get-ChildItem -LiteralPath $InboxPath -Filter '*.pdf' -File | Sort-Object Name)
if ($pdfFiles.Count -eq 0) {
    Write-Host "No PDF files were found in $InboxPath"
    Write-Host 'Add approved PDFs to the inbox and run the publisher again.'
    exit 0
}
if ($pdfFiles.Count -gt 1 -and (-not [string]::IsNullOrWhiteSpace($TitleOverride) -or -not [string]::IsNullOrWhiteSpace($NoteOverride) -or -not [string]::IsNullOrWhiteSpace($PagePath))) {
    throw 'TitleOverride, NoteOverride and PagePath can only be used when the inbox contains one PDF.'
}

$relativePagePath = ''
if (-not [string]::IsNullOrWhiteSpace($PagePath)) {
    $relativePagePath = $PagePath.Trim().Replace('\', '/')
    if (-not $relativePagePath.EndsWith('.html', [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'PagePath must point to an HTML file.'
    }
    $resolvedPagePath = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $relativePagePath))
    $repositoryPrefix = [System.IO.Path]::GetFullPath($repositoryRoot).TrimEnd('\') + '\'
    if (-not $resolvedPagePath.StartsWith($repositoryPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'PagePath must stay inside the website repository.'
    }
    if (-not (Test-Path -LiteralPath $resolvedPagePath -PathType Leaf)) {
        throw "HTML result page not found: $relativePagePath"
    }
}

$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$records = @($manifest.results)
$preparedPaths = New-Object System.Collections.Generic.List[string]
$preparedPagePaths = New-Object System.Collections.Generic.List[string]
$knownPdfHashes = @{}
foreach ($record in $records) {
    if ([string]::IsNullOrWhiteSpace($record.file)) { continue }
    $registeredPath = Join-Path $repositoryRoot ($record.file.Replace('/', '\'))
    if (Test-Path -LiteralPath $registeredPath -PathType Leaf) {
        $registeredHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $registeredPath).Hash
        if (-not $knownPdfHashes.ContainsKey($registeredHash)) {
            $knownPdfHashes[$registeredHash] = $record.file
        }
    }
}
$preparedCount = 0
$useSharedInfo = $false
$sharedDateText = ''
$sharedCategory = $DefaultCategory
$sharedNote = ''

if (-not $NonInteractive -and $pdfFiles.Count -gt 1) {
    Write-Host ''
    Write-Host "$($pdfFiles.Count) result files found."
    Write-Host '  1. Apply shared event information to all files'
    Write-Host '  2. Enter information individually for every file'
    do {
        $informationMode = Read-Host 'Information mode [1]'
        if ([string]::IsNullOrWhiteSpace($informationMode)) { $informationMode = '1' }
        $validMode = $informationMode -in @('1', '2')
        if (-not $validMode) { Write-Host 'Enter 1 or 2.' -ForegroundColor Yellow }
    } until ($validMode)
    $useSharedInfo = $informationMode -eq '1'

    if ($useSharedInfo) {
        $firstDate = if ($pdfFiles[0].BaseName -match '^(\d{4}-\d{2}-\d{2})') { $Matches[1] } else { Get-Date -Format 'yyyy-MM-dd' }
        do {
            $sharedDateText = Read-WithDefault -Prompt 'Shared event/result date (YYYY-MM-DD)' -Default $firstDate
            $sharedParsedDate = [datetime]::MinValue
            $validSharedDate = [datetime]::TryParseExact($sharedDateText, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$sharedParsedDate)
            if (-not $validSharedDate) { Write-Host 'Enter a valid date in YYYY-MM-DD format.' -ForegroundColor Yellow }
        } until ($validSharedDate)
        $sharedCategory = Read-CategoryChoice -DefaultKey $DefaultCategory
        $sharedNote = (Read-Host 'Shared optional note, distance or revision (press Enter to skip)').Trim()
        Write-Host 'Titles will be generated from each filename. Use descriptive filenames for shared mode.' -ForegroundColor DarkGray
    }
}

foreach ($pdf in $pdfFiles) {
    Write-Host ''
    Write-Host "Reviewing $($pdf.Name)" -ForegroundColor Cyan

    if (-not (Test-PdfHeader -Path $pdf.FullName)) {
        Write-Warning "$($pdf.Name) is not a valid PDF and was left in the inbox."
        continue
    }

    $dateText = if ($useSharedInfo) { $sharedDateText } elseif ($pdf.BaseName -match '^(\d{4}-\d{2}-\d{2})') { $Matches[1] } else { '' }
    if ($NonInteractive -and [string]::IsNullOrWhiteSpace($dateText)) {
        Write-Warning "$($pdf.Name) does not begin with YYYY-MM-DD and was skipped."
        continue
    }
    if (-not $NonInteractive -and -not $useSharedInfo) {
        $dateText = Read-WithDefault -Prompt 'Event/result date (YYYY-MM-DD)' -Default $(if ($dateText) { $dateText } else { (Get-Date -Format 'yyyy-MM-dd') })
    }

    $parsedDate = [datetime]::MinValue
    if (-not [datetime]::TryParseExact($dateText, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$parsedDate)) {
        Write-Warning "$dateText is not a valid YYYY-MM-DD date. $($pdf.Name) was skipped."
        continue
    }

    $defaultTitle = Get-DefaultTitle -BaseName $pdf.BaseName
    $title = if (-not [string]::IsNullOrWhiteSpace($TitleOverride)) { $TitleOverride.Trim() } elseif ($NonInteractive -or $useSharedInfo) { $defaultTitle } else { Read-WithDefault -Prompt 'Public result title' -Default $defaultTitle }
    $category = if ($useSharedInfo) { $sharedCategory } else { $DefaultCategory }
    $note = if ($useSharedInfo) { $sharedNote } elseif ([string]::IsNullOrWhiteSpace($NoteOverride)) { '' } else { $NoteOverride.Trim() }

    if (-not $NonInteractive -and -not $useSharedInfo) {
        $category = Read-CategoryChoice -DefaultKey $DefaultCategory
        if ([string]::IsNullOrWhiteSpace($NoteOverride)) {
            $note = (Read-Host 'Optional note, distance or revision (press Enter to skip)').Trim()
        }
    }

    $season = $parsedDate.Year
    $safeName = $pdf.Name.ToLowerInvariant() -replace '[^a-z0-9._-]+', '-'
    $safeName = $safeName -replace '-+', '-'
    if ($safeName -notmatch '^\d{4}-\d{2}-\d{2}-') {
        $safeName = "$dateText-$safeName"
    }
    $yearDirectory = Join-Path $repositoryRoot "assets\results\$season"
    $destinationPath = Join-Path $yearDirectory $safeName
    $relativePath = "assets/results/$season/$safeName"

    $sameDayTimeTrial = @($records | Where-Object {
        $_.category -eq 'time-trial' -and $_.date -eq $dateText
    }) | Select-Object -First 1
    if ($category -eq 'time-trial' -and $sameDayTimeTrial) {
        Write-Warning "A weekly time-trial result is already published for ${dateText}: $($sameDayTimeTrial.title). The new file was left in the inbox."
        Write-Host 'Use the documented correction process if the published result must be replaced.' -ForegroundColor Yellow
        continue
    }

    $incomingHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $pdf.FullName).Hash
    if ($knownPdfHashes.ContainsKey($incomingHash)) {
        Write-Warning "$($pdf.Name) has exactly the same contents as $($knownPdfHashes[$incomingHash]) and was left in the inbox."
        continue
    }

    if (Test-Path -LiteralPath $destinationPath) {
        Write-Warning "$relativePath already exists. Rename a corrected file before publishing; nothing was overwritten."
        continue
    }
    if (@($records | Where-Object { $_.file -eq $relativePath }).Count -gt 0) {
        Write-Warning "$relativePath is already registered and was skipped."
        continue
    }

    $currentPagePath = $relativePagePath
    $resolvedCurrentPagePath = $null
    $conversionSummary = $null
    $pageWasGenerated = $false
    if ($category -eq 'time-trial' -and [string]::IsNullOrWhiteSpace($currentPagePath)) {
        $pageFileName = [System.IO.Path]::GetFileNameWithoutExtension($safeName) + '.html'
        $currentPagePath = "results/$season/$pageFileName"
        $resolvedCurrentPagePath = Join-Path $repositoryRoot ($currentPagePath.Replace('/', '\'))
        if (Test-Path -LiteralPath $resolvedCurrentPagePath) {
            Write-Warning "$currentPagePath already exists. The PDF was left in the inbox so no HTML page is overwritten."
            continue
        }
        try {
            $conversionSummary = Convert-TimeTrialPdf -PdfPath $pdf.FullName -OutputPath $resolvedCurrentPagePath -Date $dateText -Title $title -PdfWebPath $relativePath -ValidateOnly:$DryRun
        }
        catch {
            Write-Warning "Could not create a reliable HTML version of $($pdf.Name). The PDF was left in the inbox.`n$($_.Exception.Message)"
            continue
        }
        if (-not $DryRun) { $pageWasGenerated = $true }
        if ([string]::IsNullOrWhiteSpace($note) -and $conversionSummary.note) {
            $note = $conversionSummary.note
        }
    }

    Write-Host "  Title:    $title"
    Write-Host "  Date:     $dateText"
    Write-Host "  Category: $($categoryLabels[$category])"
    Write-Host "  File:     $relativePath"
    if ($currentPagePath) { Write-Host "  Web page: $currentPagePath" }
    if ($note) { Write-Host "  Note:     $note" }

    if ($DryRun) {
        Write-Host '  Dry run: no file or register changes made.' -ForegroundColor Yellow
        $preparedCount++
        continue
    }

    [System.IO.Directory]::CreateDirectory($yearDirectory) | Out-Null
    try {
        Move-Item -LiteralPath $pdf.FullName -Destination $destinationPath
    }
    catch {
        if ($pageWasGenerated -and $resolvedCurrentPagePath -and (Test-Path -LiteralPath $resolvedCurrentPagePath)) {
            Remove-Item -LiteralPath $resolvedCurrentPagePath -Force
        }
        throw
    }
    $record = [ordered]@{
        title    = $title
        date     = $dateText
        category = $category
        season   = $season
    }
    if ($currentPagePath) { $record['page'] = $currentPagePath }
    $record['file'] = $relativePath
    $record['format'] = 'PDF'
    if ($note) { $record['note'] = $note }
    $records += [pscustomobject]$record
    $preparedPaths.Add($relativePath) | Out-Null
    if ($pageWasGenerated) { $preparedPagePaths.Add($currentPagePath) | Out-Null }
    $knownPdfHashes[$incomingHash] = $relativePath
    $preparedCount++
}

if ($DryRun) {
    Write-Host ''
    Write-Host "Dry run complete: $preparedCount file(s) checked; nothing changed." -ForegroundColor Green
    exit 0
}

if ($preparedCount -eq 0) {
    Write-Host ''
    Write-Host 'No result files were prepared. The register was not changed.'
    exit 0
}

$manifest.updated = Get-Date -Format 'yyyy-MM-dd'
$manifest.results = @($records | Sort-Object date -Descending)
Write-Utf8Json -Path $manifestPath -Value $manifest

# Re-read the file so invalid JSON cannot reach Git.
$null = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
Write-Host ''
Write-Host "$preparedCount result file(s) prepared successfully." -ForegroundColor Green

$publishNow = $Publish
if (-not $NonInteractive -and -not $Publish) {
    $publishAnswer = Read-Host 'Commit and push these results to the develop preview now? (y/N)'
    $publishNow = $publishAnswer -match '^(y|yes)$'
}

if (-not $publishNow) {
    Write-Host 'The files are prepared locally but have not been published.'
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
    if ($LASTEXITCODE -eq 1) {
        throw 'Other staged Git changes already exist. Commit or unstage them before publishing results.'
    }
    if ($LASTEXITCODE -gt 1) {
        throw 'Unable to check the staged Git changes.'
    }

    $gitPaths = @('assets/data/results.json') + @($preparedPaths) + @($preparedPagePaths)
    if ($relativePagePath -and $preparedCount -eq 1) { $gitPaths += $relativePagePath }
    & git add -- @gitPaths
    if ($LASTEXITCODE -ne 0) { throw 'Git could not stage the prepared result files.' }

    $commitMessage = if ($preparedCount -eq 1) { 'content: publish approved result file' } else { "content: publish $preparedCount approved result files" }
    & git commit -m $commitMessage
    if ($LASTEXITCODE -ne 0) { throw 'Git could not create the results commit.' }

    & git push origin develop
    if ($LASTEXITCODE -ne 0) { throw 'The commit was created, but Git could not push it to develop.' }

    Write-Host ''
    Write-Host 'Results published to develop. Check GitHub Pages after the deployment finishes.' -ForegroundColor Green
}
finally {
    Pop-Location
}
