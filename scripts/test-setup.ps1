$ErrorActionPreference = 'Stop'

# Run setup in a temporary copy so the real checkout, PAT, and home folder stay untouched.
$scriptRoot = $PSScriptRoot
$repoRoot = Split-Path -Parent $scriptRoot
$testRoot = Join-Path ([IO.Path]::GetTempPath()) "ai-setups-test-$([guid]::NewGuid())"
$testRepo = Join-Path $testRoot 'repo'
$testHome = Join-Path $testRoot 'home'
$testToken = 'test-token-not-a-real-secret'
$previousTestHome = $env:AI_SETUPS_HOME

function Pass([string]$message) {
    Write-Host "PASS: $message"
}

function Require([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw $message
    }
}

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $testRepo 'config') | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot '.gitignore') -Destination $testRepo
    Copy-Item -LiteralPath (Join-Path $repoRoot 'context') -Destination $testRepo -Recurse
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts') -Destination $testRepo -Recurse
    & git -C $testRepo init -q
    Require ($LASTEXITCODE -eq 0) 'Could not create the temporary Git repository.'
    $testRepoReal = (Resolve-Path -LiteralPath $testRepo).Path
    Pass 'created an isolated temporary repository and home folder'

    $patFile = Join-Path $testRepo 'config/.github-pat'
    [IO.File]::WriteAllText($patFile, "$testToken`n", [Text.UTF8Encoding]::new($false))
    $env:AI_SETUPS_HOME = $testHome
    $output = (& (Join-Path $testRepo 'scripts/setup.ps1') *>&1 | Out-String)
    Require ($LASTEXITCODE -eq 0) 'The temporary setup script did not complete.'
    Require ($output.Contains('Local setup validation passed.')) 'The temporary setup validation did not pass.'
    Pass 'setup script and its built-in validation completed'

    Require (Test-Path -LiteralPath $patFile -PathType Leaf) 'The temporary PAT file was not created.'
    Pass 'temporary PAT file exists'

    & git -C $testRepo check-ignore -q -- config/.github-pat
    Require ($LASTEXITCODE -eq 0) 'The temporary PAT file is not ignored by Git.'
    & git -C $testRepo ls-files --error-unmatch -- config/.github-pat 2>$null
    Require ($LASTEXITCODE -ne 0) 'The temporary PAT file was unexpectedly tracked by Git.'
    Pass 'temporary PAT file is ignored and untracked'

    $agentFile = Join-Path (Join-Path $testHome '.codex') 'AGENTS.md'
    $expectedContext = Join-Path $testRepoReal 'context/GLOBAL_AI_CONTEXT.md'
    Require ((Test-Path -LiteralPath $agentFile -PathType Leaf) -and (Select-String -LiteralPath $agentFile -SimpleMatch -Quiet $expectedContext)) 'Temporary Codex instructions do not point at the temporary shared context.'
    Pass 'temporary Codex instructions point at the temporary shared context'

    Require (-not $output.Contains($testToken)) 'The test token was unexpectedly printed.'
    Pass 'temporary PAT value was not printed'
    Write-Host 'Temporary setup test passed. Your real setup was not changed.'
}
finally {
    if ($null -eq $previousTestHome) {
        Remove-Item Env:AI_SETUPS_HOME -ErrorAction SilentlyContinue
    }
    else {
        $env:AI_SETUPS_HOME = $previousTestHome
    }
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}

# The expected untracked-file check above exits Git with 1. Do not let that
# expected status become this successful test's process status.
exit 0
