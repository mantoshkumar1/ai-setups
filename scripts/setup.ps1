$ErrorActionPreference = 'Stop'

# Bootstrap this checkout without printing or storing the PAT anywhere except
# the ignored config/.github-pat file.
$repoRoot = Split-Path -Parent $PSScriptRoot
$contextFile = Join-Path $repoRoot 'context/GLOBAL_AI_CONTEXT.md'
$configDir = Join-Path $repoRoot 'config'
$patFile = Join-Path $configDir '.github-pat'
$agentDir = Join-Path $HOME '.codex'
$agentFile = Join-Path $agentDir 'AGENTS.md'
$beginMarker = '# >>> ai-setups shared context >>>'
$endMarker = '# <<< ai-setups shared context <<<'

if (-not (Test-Path -LiteralPath $contextFile -PathType Leaf)) {
    throw "Missing shared context: $contextFile"
}

New-Item -ItemType Directory -Force -Path $configDir | Out-Null

if (-not (Test-Path -LiteralPath $patFile -PathType Leaf)) {
    $securePat = Read-Host 'Paste your GitHub Personal Access Token (input is hidden)' -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePat)
    try {
        $patValue = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        if ([string]::IsNullOrWhiteSpace($patValue)) {
            throw 'No token entered; setup stopped without creating a credential file.'
        }
        [IO.File]::WriteAllText($patFile, "$patValue`n", [Text.UTF8Encoding]::new($false))
    }
    finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
        Remove-Variable patValue -ErrorAction SilentlyContinue
    }
    Write-Host 'Created local credential file.'
}
else {
    Write-Host 'Kept existing local credential file.'
}

# Restrict the credential to the current Windows user.
$acl = Get-Acl -LiteralPath $patFile
$acl.SetAccessRuleProtection($true, $false)
foreach ($rule in @($acl.Access)) {
    [void]$acl.RemoveAccessRuleAll($rule)
}
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$accessRule = [Security.AccessControl.FileSystemAccessRule]::new(
    $currentUser,
    [Security.AccessControl.FileSystemRights]::FullControl,
    [Security.AccessControl.AccessControlType]::Allow
)
$acl.SetAccessRule($accessRule)
Set-Acl -LiteralPath $patFile -AclObject $acl

New-Item -ItemType Directory -Force -Path $agentDir | Out-Null
if (-not (Test-Path -LiteralPath $agentFile -PathType Leaf)) {
    New-Item -ItemType File -Path $agentFile | Out-Null
}

$block = "$beginMarker`r`nBefore performing repository or GitHub work, read and follow:`r`n`r`n$contextFile`r`n$endMarker"
$agentText = [IO.File]::ReadAllText($agentFile)

if ($agentText.Contains($beginMarker)) {
    $pattern = "(?s)$([regex]::Escape($beginMarker)).*?$([regex]::Escape($endMarker))"
    $updatedAgentText = [regex]::Replace($agentText, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $block })
    [IO.File]::WriteAllText($agentFile, $updatedAgentText, [Text.UTF8Encoding]::new($false))
    Write-Host 'Updated the ai-setups section in your personal Codex instructions.'
}
elseif ($agentText.Contains($contextFile)) {
    Write-Host 'Your personal Codex instructions already reference this shared context.'
}
else {
    $separator = if ($agentText.Length -gt 0 -and -not $agentText.EndsWith("`n")) { "`r`n`r`n" } else { "`r`n" }
    [IO.File]::AppendAllText($agentFile, "$separator$block`r`n", [Text.UTF8Encoding]::new($false))
    Write-Host 'Added the shared context to your personal Codex instructions.'
}

Write-Host ''
Write-Host 'Checking your local setup now...'
& (Join-Path $PSScriptRoot 'validate.ps1')
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host ''
Write-Host 'Next steps:'
Write-Host '1. Open Codex and start a new task in the actual project you want to work on.'
Write-Host '2. Describe the task normally; never paste the PAT into the conversation.'
Write-Host '3. If you use Claude Cowork:'
Write-Host "   - Connect only: $repoRoot\context"
Write-Host "   - Open Cowork Global Instructions and paste the entire contents of: $repoRoot\context\CLAUDE_COWORK_GLOBAL.txt"
