[CmdletBinding()]
param([string]$SourceRoot)

$ErrorActionPreference = 'Stop'
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$repositoryRoot = Split-Path -Parent $scriptDirectory
$archiveRoot = Join-Path $repositoryRoot 'assets\results\archive'
$manifestPath = Join-Path $repositoryRoot 'assets\data\results-archive.json'
$records = New-Object System.Collections.Generic.List[object]
$copiedCount = 0
$existingCount = 0

if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $profileCandidate = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'OneDrive\Collegians\Results'
    $clubCandidate = 'C:\Users\werne\OneDrive\Collegians\Results'
    $SourceRoot = if (Test-Path -LiteralPath $profileCandidate -PathType Container) { $profileCandidate } else { $clubCandidate }
}
$SourceRoot = [System.IO.Path]::GetFullPath($SourceRoot)

if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container)) {
    throw "Historical results folder not found: $SourceRoot"
}

$monthNumbers = @{
    jan = 1; january = 1; feb = 2; february = 2; mar = 3; march = 3
    apr = 4; april = 4; may = 5; jun = 6; june = 6; jul = 7; july = 7
    aug = 8; august = 8; sep = 9; sept = 9; september = 9
    oct = 10; october = 10; nov = 11; november = 11; dec = 12; december = 12
}

function Get-ResultDate {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [int]$FallbackYear
    )

    if ($Name -match '(?<year>20\d{2})[-_](?<month>\d{2})[-_](?<day>\d{2})') {
        try { return [datetime]::new([int]$Matches.year, [int]$Matches.month, [int]$Matches.day) } catch { return $null }
    }

    if ($Name -match '(?i)(?<day>\d{1,2})\s*(?<month>jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:t|tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s*(?<year>\d{2,4})?') {
        $year = if ($Matches.year) { [int]$Matches.year } else { $FallbackYear }
        if ($year -lt 100) { $year += 2000 }
        try { return [datetime]::new($year, $monthNumbers[$Matches.month.ToLowerInvariant()], [int]$Matches.day) } catch { return $null }
    }

    return $null
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

function Add-ArchivePdf {
    param(
        [Parameter(Mandatory)] [string]$SourcePath,
        [Parameter(Mandatory)] [string]$RelativePath,
        [Parameter(Mandatory)] [string]$Title,
        [Parameter(Mandatory)] [string]$Date,
        [Parameter(Mandatory)] [int]$Season,
        [Parameter(Mandatory)] [string]$Category,
        [string]$DateLabel
    )

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        Write-Warning "Archive source missing and skipped: $SourcePath"
        return
    }
    if (-not (Test-PdfHeader -Path $SourcePath)) {
        Write-Warning "Invalid PDF skipped: $SourcePath"
        return
    }

    $destinationPath = Join-Path $repositoryRoot ($RelativePath.Replace('/', '\'))
    $destinationDirectory = Split-Path -Parent $destinationPath
    [System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null

    if (Test-Path -LiteralPath $destinationPath -PathType Leaf) {
        $sourceHash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash
        $destinationHash = (Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256).Hash
        if ($sourceHash -ne $destinationHash) {
            throw "Published archive file differs from its source. Create a revised filename instead of overwriting: $RelativePath"
        }
        $script:existingCount++
    }
    else {
        Copy-Item -LiteralPath $SourcePath -Destination $destinationPath
        $script:copiedCount++
    }

    $record = [ordered]@{
        title = $Title
        date = $Date
        season = $Season
        category = $Category
        file = $RelativePath
        format = 'PDF'
    }
    if ($DateLabel) { $record['dateLabel'] = $DateLabel }
    $script:records.Add([pscustomobject]$record)
}

# Herman's Delight: one complete, non-template PDF per result date. A small
# reviewed preference map avoids known spreadsheet exports with oversized or
# mostly blank print areas.
$preferredTimeTrialSources = @{
    '2024-01-02' = '2024\Hermans Delight\Hermans Timekeeping - 2 JAN 2024-1.pdf'
    '2024-01-09' = '2024\Hermans Delight\Hermans Timekeeping - 9 JAN 2024-1.pdf'
    '2024-01-30' = '2024\Hermans Delight\Hermans Timekeeping -  30 JAN 2024-1.pdf'
    '2024-02-20' = '2024\Hermans Delight\Hermans Timekeeping -  20 FEB 2024.pdf'
    '2024-02-27' = '2024\Hermans Delight\Hermans Timekeeping -  27 FEB 2024-1.pdf'
    '2024-03-05' = '2024\Hermans Delight\Hermans Timekeeping -  5 MAR 2024.pdf'
    '2024-03-12' = '2024\Hermans Delight\Hermans Timekeeping -  12 MAR 2024-1.pdf'
}

$timeTrialCandidates = Get-ChildItem -LiteralPath $SourceRoot -File -Recurse -Filter '*.pdf' |
    Where-Object {
        $_.FullName -match '(?i)\\HERMANS DELIGHT\\' -and
        $_.Name -notmatch '(?i)template|witness|blank|DBN_DC|Bev|mark|AchesnPains|ASICS|scan|page'
    } |
    ForEach-Object {
        $relativeSource = $_.FullName.Substring($SourceRoot.Length + 1)
        $yearText = ($relativeSource -split '\\')[0]
        if ($yearText -notmatch '^20\d{2}$') { return }
        $date = Get-ResultDate -Name $_.BaseName -FallbackYear ([int]$yearText)
        if ($date) {
            [pscustomobject]@{ Date = $date; Path = $_.FullName; Length = $_.Length }
        }
    } |
    Group-Object { $_.Date.ToString('yyyy-MM-dd') } |
    ForEach-Object {
        $dateKey = $_.Name
        if ($preferredTimeTrialSources.ContainsKey($dateKey)) {
            $preferredPath = Join-Path $SourceRoot $preferredTimeTrialSources[$dateKey]
            [pscustomobject]@{ Date = [datetime]$dateKey; Path = $preferredPath; Length = (Get-Item -LiteralPath $preferredPath).Length }
        }
        else {
            $_.Group | Sort-Object Length -Descending | Select-Object -First 1
        }
    } |
    Where-Object { $_.Date -lt [datetime]'2026-08-25' }

foreach ($result in $timeTrialCandidates) {
    $dateText = $result.Date.ToString('yyyy-MM-dd')
    $season = $result.Date.Year
    Add-ArchivePdf -SourcePath $result.Path `
        -RelativePath "assets/results/archive/$season/time-trial/$dateText-hermans-delight-time-trial.pdf" `
        -Title "Herman's Delight Weekly Results - $($result.Date.ToString('d MMMM yyyy'))" `
        -Date $dateText -Season $season -Category 'time-trial'
}

# Hogsback result sheets retained in the historical download collection.
$hogsbackDownload = Join-Path $SourceRoot '2024\Hogsback 2024\download'
if (Test-Path -LiteralPath $hogsbackDownload -PathType Container) {
    Get-ChildItem -LiteralPath $hogsbackDownload -File -Filter 'Hogsback*.pdf' |
        Where-Object { $_.BaseName -match '^Hogsback(?<year>19\d{2}|20\d{2})$' } |
        ForEach-Object {
            $season = [int]$Matches.year
            Add-ArchivePdf -SourcePath $_.FullName `
                -RelativePath "assets/results/archive/$season/hosted-event/$season-hogsback-trail-run-results.pdf" `
                -Title "Hogsback Trail Run Results - $season" -Date "$season-01-01" `
                -DateLabel "$season event" -Season $season -Category 'hosted-event'
        }
}

$hogsback2024 = Join-Path $SourceRoot '2024\Hogsback 2024\Hogsback Trail run 6 January 2024-12012024.pdf'
Add-ArchivePdf -SourcePath $hogsback2024 `
    -RelativePath 'assets/results/archive/2024/hosted-event/2024-hogsback-trail-run-results.pdf' `
    -Title 'Hogsback Trail Run Results - 2024' -Date '2024-01-06' -Season 2024 -Category 'hosted-event'

# Bill Butler hosted-event results.
$billButlerResults = @(
    @{ Source = '2022\BillButler2022.pdf'; Year = 2022 },
    @{ Source = '2024\Bill Butler\Bill Butler Results 2023.pdf'; Year = 2023 },
    @{ Source = '2024\Bill Butler\Bill Butler Results 2024.pdf'; Year = 2024 },
    @{ Source = '2025\Bill Butler\Bill Butler Results 2025-final.pdf'; Year = 2025 },
    @{ Source = '2026\BILL BUTLER\Bill Butler Results 2026.pdf'; Year = 2026 }
)
foreach ($item in $billButlerResults) {
    $season = [int]$item.Year
    Add-ArchivePdf -SourcePath (Join-Path $SourceRoot $item.Source) `
        -RelativePath "assets/results/archive/$season/hosted-event/$season-bill-butler-results.pdf" `
        -Title "Bill Butler Results - $season" -Date "$season-01-01" `
        -DateLabel "$season event" -Season $season -Category 'hosted-event'
}

# Final championship summaries and selected race result documents.
$additionalResults = @(
    @{ Source = '2023\club champs\Club Champion 2023 Gents Summary_07Nov.pdf'; File = '2023-club-championship-gents-summary.pdf'; Title = 'Club Championship Gents Summary - 2023'; Date = '2023-11-07'; Year = 2023; Category = 'championship' },
    @{ Source = '2023\club champs\Club Champion 2023 Ladies Summary_07Nov.pdf'; File = '2023-club-championship-ladies-summary.pdf'; Title = 'Club Championship Ladies Summary - 2023'; Date = '2023-11-07'; Year = 2023; Category = 'championship' },
    @{ Source = '2025\CHAMPIONSHIP RACE RESULTS\Club Champion 2025 Road.pdf'; File = '2025-road-club-championship.pdf'; Title = 'Road Club Championship - 2025'; Date = '2025-12-31'; DateLabel = '2025 season'; Year = 2025; Category = 'championship' },
    @{ Source = '2024\Club Champs\Save Orion 10-5km Results.pdf'; File = '2024-save-orion-10km-5km-results.pdf'; Title = 'Save Orion 10 km and 5 km Results'; Date = '2024-01-01'; DateLabel = '2024 event'; Year = 2024; Category = 'road' },
    @{ Source = '2024\Club Champs\Save Orion 21km Results.pdf'; File = '2024-save-orion-21km-results.pdf'; Title = 'Save Orion 21 km Results'; Date = '2024-01-01'; DateLabel = '2024 event'; Year = 2024; Category = 'road' },
    @{ Source = '2025\CHAMPIONSHIP RACE RESULTS\HILLCREST 09 FEB25 -21KM.pdf'; File = '2025-02-09-hillcrest-21km-results.pdf'; Title = 'Hillcrest 21 km Results'; Date = '2025-02-09'; Year = 2025; Category = 'road' },
    @{ Source = '2025\CHAMPIONSHIP RACE RESULTS\HILLCREST 09 FEB25 -42KM.pdf'; File = '2025-02-09-hillcrest-42km-results.pdf'; Title = 'Hillcrest 42 km Results'; Date = '2025-02-09'; Year = 2025; Category = 'road' },
    @{ Source = '2025\KZNA TRACK AND FIELD\KZNA ALL AGES LEAGUE 2 SUMMARY OF RESULTS (1 MARCH 2025).pdf'; File = '2025-03-01-kzna-all-ages-league-2-results.pdf'; Title = 'KZNA All Ages League 2 Results'; Date = '2025-03-01'; Year = 2025; Category = 'championship' }
)

$november2024 = Get-ChildItem -LiteralPath (Join-Path $SourceRoot '2024\Club Champs\NOV') -File -Filter '*.pdf' -ErrorAction SilentlyContinue
foreach ($source in $november2024) {
    $slug = $source.BaseName.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $slug = $slug.Trim('-') -replace '-1$', ''
    $title = ($source.BaseName -replace '-1$', '') -replace '\s+-\s+', ' '
    $additionalResults += @{
        Source = $source.FullName.Substring($SourceRoot.Length + 1)
        File = "2024-$slug.pdf"
        Title = "$title"
        Date = '2024-11-01'
        DateLabel = 'Final November 2024 standings'
        Year = 2024
        Category = 'championship'
    }
}

foreach ($item in $additionalResults) {
    $season = [int]$item.Year
    $category = [string]$item.Category
    $parameters = @{
        SourcePath = Join-Path $SourceRoot $item.Source
        RelativePath = "assets/results/archive/$season/$category/$($item.File)"
        Title = [string]$item.Title
        Date = [string]$item.Date
        Season = $season
        Category = $category
    }
    if ($item.DateLabel) { $parameters['DateLabel'] = [string]$item.DateLabel }
    Add-ArchivePdf @parameters
}

# Curated hosted-event records recovered from the previous club website. These
# PDFs live in the repository so future archive rebuilds retain the collection
# even when the separate results inbox is unavailable.
$legacyHostedResults = @(
    @{ Year = 2003; File = '2003-umgeni-water-marathon-results.pdf'; Title = 'uMngeni Water Marathon Results - 2003' },
    @{ Year = 2004; File = '2004-umgeni-water-marathon-results.pdf'; Title = 'uMngeni Water Marathon Results - 2004' },
    @{ Year = 2007; File = '2007-umgeni-water-marathon-results.pdf'; Title = 'uMngeni Water Marathon Results - 2007' },
    @{ Year = 2008; File = '2008-umgeni-water-marathon-results.pdf'; Title = 'uMngeni Water Marathon Results - 2008' },
    @{ Year = 2009; File = '2009-umgeni-water-marathon-results.pdf'; Title = 'uMngeni Water Marathon Results - 2009' },
    @{ Year = 2013; File = '2013-umgeni-water-marathon-results.pdf'; Title = 'uMngeni Water Marathon Results - 2013' },
    @{ Year = 2018; File = '2018-umgeni-water-marathon-results.pdf'; Title = 'uMngeni Water Marathon Results - 2018' },
    @{ Year = 2019; File = '2019-umgeni-water-marathon-results.pdf'; Title = 'uMngeni Water Marathon Results - 2019' },
    @{ Year = 2022; File = '2022-umgeni-water-marathon-results.pdf'; Title = 'uMngeni Water Marathon Results - 2022' },
    @{ Year = 2023; File = '2023-umgeni-water-marathon-results.pdf'; Title = 'uMngeni Water Marathon Results - 2023' },
    @{ Year = 2024; File = '2024-umngeni-uthukela-water-marathon-results.pdf'; Title = 'uMngeni-uThukela Water Marathon Results - 2024'; Date = '2024-03-10' },
    @{ Year = 1983; File = '1983-duke-of-york-results.pdf'; Title = 'Duke of York Results - 1983'; Date = '1983-10-16' },
    @{ Year = 2012; File = '2012-duke-of-york-results.pdf'; Title = 'Duke of York Results - 2012'; Date = '2012-10-28' },
    @{ Year = 2013; File = '2013-duke-of-york-results.pdf'; Title = 'Duke of York Results - 2013'; Date = '2013-10-27' },
    @{ Year = 2014; File = '2014-duke-of-york-results.pdf'; Title = 'Duke of York Results - 2014'; Date = '2014-10-26' },
    @{ Year = 2015; File = '2015-duke-of-york-results.pdf'; Title = 'Duke of York Results - 2015'; Date = '2015-10-25' },
    @{ Year = 2016; File = '2016-duke-of-york-results.pdf'; Title = 'Duke of York Results - 2016'; Date = '2016-10-02' },
    @{ Year = 2017; File = '2017-duke-of-york-results.pdf'; Title = 'Duke of York Results - 2017'; Date = '2017-10-08' },
    @{ Year = 2019; File = '2019-duke-of-york-results.pdf'; Title = 'Duke of York Results - 2019'; Date = '2019-11-03' },
    @{ Year = 2017; File = '2017-longest-day-solo-results.pdf'; Title = 'The Longest Day Solo Results - 2017' },
    @{ Year = 2017; File = '2017-longest-day-team-results.pdf'; Title = 'The Longest Day Team Results - 2017' },
    @{ Year = 2019; File = '2019-longest-day-results.pdf'; Title = 'The Longest Day Results - 2019' }
)

foreach ($item in $legacyHostedResults) {
    $relativePath = "assets/results/archive/$($item.Year)/hosted-event/$($item.File)"
    $parameters = @{
        SourcePath = Join-Path $repositoryRoot ($relativePath.Replace('/', '\'))
        RelativePath = $relativePath
        Title = [string]$item.Title
        Date = if ($item.Date) { [string]$item.Date } else { "$($item.Year)-01-01" }
        DateLabel = if ($item.Date) { $null } else { "$($item.Year) event" }
        Season = [int]$item.Year
        Category = 'hosted-event'
    }
    Add-ArchivePdf @parameters
}

$manifest = [ordered]@{
    updated = Get-Date -Format 'yyyy-MM-dd'
    sourcePolicy = 'Approved result PDFs only; drafts, templates, witness sheets, signed forms and administrative documents excluded.'
    results = @($records | Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'title'; Descending = $false })
}

$json = $manifest | ConvertTo-Json -Depth 8
$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($manifestPath, "$json`n", $utf8WithoutBom)
$null = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json

Write-Host "Archive ready: $($records.Count) approved PDFs registered." -ForegroundColor Green
Write-Host "Copied: $copiedCount  Already present: $existingCount"
Write-Host "Register: $manifestPath"
