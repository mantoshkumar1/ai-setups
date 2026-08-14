param(
    [string]$ReportsDir
)

# Show the latest safe DogBuild report for each project. This reads only the
# chosen report directory; it never contacts GitHub or reads config/.
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ReportsDir)) {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $ReportsDir = Join-Path $repoRoot 'reports/dogbuild'
}

if (-not (Test-Path -LiteralPath $ReportsDir -PathType Container)) {
    Write-Error "No report directory: $ReportsDir"
    exit 1
}

function Meta([string[]]$Lines, [string]$Key) {
    $match = $Lines | Where-Object { $_ -eq "- $Key:" -or $_ -like "- $Key: *" } | Select-Object -First 1
    if ($null -eq $match) { return '' }
    return $match.Substring(("- $Key: ").Length)
}

function Detail([string[]]$Lines, [string]$Heading) {
    for ($i = 0; $i -lt $Lines.Count - 1; $i++) {
        if ($Lines[$i] -eq "## $Heading") { return $Lines[$i + 1] }
    }
    return ''
}

$unsafe = 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|Bearer\s+\S+|Authorization:\s*\S+'
$entries = foreach ($report in Get-ChildItem -LiteralPath $ReportsDir -File -Filter '*-summary.md' | Sort-Object Name) {
    $lines = @(Get-Content -LiteralPath $report.FullName)
    if (($lines -join "`n") -match $unsafe) { continue }

    $project = Meta $lines 'Project'
    $branch = Meta $lines 'Branch'
    $head = Meta $lines 'Head'
    $changed = Detail $lines 'What changed'
    $worked = Detail $lines 'What worked'
    $blocked = Detail $lines 'What is blocked'
    $next = Detail $lines 'What happens next'

    if ($project -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') { continue }
    if ([string]::IsNullOrWhiteSpace($branch) -or [string]::IsNullOrWhiteSpace($head) -or
        [string]::IsNullOrWhiteSpace($changed) -or [string]::IsNullOrWhiteSpace($worked) -or
        [string]::IsNullOrWhiteSpace($blocked) -or [string]::IsNullOrWhiteSpace($next)) { continue }

    [PSCustomObject]@{
        Project = $project; Name = $report.Name; Branch = $branch; Head = $head
        Changed = $changed; Worked = $worked; Blocked = $blocked; Next = $next
    }
}

if (@($entries).Count -eq 0) {
    Write-Host "No valid safe DogBuild reports found in $ReportsDir"
    exit 0
}

Write-Host 'DogBuild report overview'
Write-Host ''
foreach ($entry in $entries | Group-Object Project | ForEach-Object {
    $_.Group | Sort-Object Name | Select-Object -Last 1
} | Sort-Object Project) {
    Write-Host $entry.Project
    Write-Host "  Branch: $($entry.Branch)  Head: $($entry.Head)"
    Write-Host "  Changed: $($entry.Changed)"
    Write-Host "  Worked: $($entry.Worked)"
    Write-Host "  Blocked: $($entry.Blocked)"
    Write-Host "  Next: $($entry.Next)"
    Write-Host ''
}
