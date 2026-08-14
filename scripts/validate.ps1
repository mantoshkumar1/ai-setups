$ErrorActionPreference = 'Stop'

# Validate local setup without reading, printing, or transmitting the PAT.
$repoRoot = Split-Path -Parent $PSScriptRoot
$contextFile = Join-Path $repoRoot 'context/GLOBAL_AI_CONTEXT.md'
$patFile = Join-Path $repoRoot 'config/.github-pat'
$aiSetupsHome = if ($env:AI_SETUPS_HOME) { $env:AI_SETUPS_HOME } else { $HOME }
$agentFile = Join-Path (Join-Path $aiSetupsHome '.codex') 'AGENTS.md'
$failures = 0

function Pass([string]$message) {
    Write-Host "PASS: $message"
}

function Fail([string]$message) {
    Write-Host "FAIL: $message"
    $script:failures++
}

if (Test-Path -LiteralPath $contextFile -PathType Leaf) {
    Pass 'shared context exists'
}
else {
    Fail 'shared context is missing'
}

if (Test-Path -LiteralPath $patFile -PathType Leaf) {
    Pass 'local PAT file exists'
}
else {
    Fail 'local PAT file is missing; run .\scripts\setup.ps1'
}

if (Test-Path -LiteralPath $patFile -PathType Leaf) {
    $acl = Get-Acl -LiteralPath $patFile
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $otherRules = @($acl.Access | Where-Object { $_.IdentityReference.Value -ne $currentUser })
    $currentUserRules = @($acl.Access | Where-Object {
        $_.IdentityReference.Value -eq $currentUser -and $_.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow
    })

    if ($acl.AreAccessRulesProtected -and $currentUserRules.Count -gt 0 -and $otherRules.Count -eq 0) {
        Pass 'local PAT file access is limited to the current Windows user'
    }
    else {
        Fail 'local PAT file access is not limited to the current Windows user'
    }
}

& git -C $repoRoot check-ignore -q -- config/.github-pat
if ($LASTEXITCODE -eq 0) {
    Pass 'local PAT file is ignored by Git'
}
else {
    Fail 'local PAT file is not ignored by Git'
}

& git -C $repoRoot ls-files --error-unmatch -- config/.github-pat 2>$null
if ($LASTEXITCODE -eq 0) {
    Fail 'local PAT file is tracked by Git'
}
else {
    Pass 'local PAT file is not tracked by Git'
}

$stagedPatPath = & git -C $repoRoot diff --cached --name-only -- config/.github-pat
if ($stagedPatPath) {
    Fail 'local PAT file is staged'
}
else {
    Pass 'local PAT file is not staged'
}

if ((Test-Path -LiteralPath $agentFile -PathType Leaf) -and (Select-String -LiteralPath $agentFile -SimpleMatch -Quiet $contextFile)) {
    Pass 'personal Codex instructions reference this shared context'
}
else {
    Fail 'personal Codex instructions do not reference this shared context; run .\scripts\setup.ps1'
}

if ($failures -gt 0) {
    Write-Host "Local setup validation failed ($failures check(s))."
    exit 1
}

Write-Host ''
Write-Host 'Local setup validation passed. The PAT was not read or displayed.'
Write-Host 'Next, run the two manual smoke tests listed in README.md.'
