#!/usr/bin/env bash

# Validate local setup without reading, printing, or transmitting the PAT.
set -u -o pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
context_file="$repo_root/context/GLOBAL_AI_CONTEXT.md"
pat_file="$repo_root/config/.github-pat"
ai_setups_home="${AI_SETUPS_HOME:-$HOME}"
agent_file="$ai_setups_home/.codex/AGENTS.md"
failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

if [[ -f "$context_file" ]]; then
  pass "shared context exists"
else
  fail "shared context is missing"
fi

if [[ -f "$pat_file" ]]; then
  pass "local PAT file exists"
else
  fail "local PAT file is missing; run bash scripts/setup.sh"
fi

if [[ -f "$pat_file" ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    mode="$(stat -f '%Lp' "$pat_file" 2>/dev/null || true)"
  else
    mode="$(stat -c '%a' "$pat_file" 2>/dev/null || true)"
  fi

  if [[ "$mode" == "600" ]]; then
    pass "local PAT file permissions are 600"
  else
    fail "local PAT file permissions are ${mode:-unknown}; expected 600"
  fi
fi

if git -C "$repo_root" check-ignore -q -- config/.github-pat; then
  pass "local PAT file is ignored by Git"
else
  fail "local PAT file is not ignored by Git"
fi

if git -C "$repo_root" ls-files --error-unmatch -- config/.github-pat >/dev/null 2>&1; then
  fail "local PAT file is tracked by Git"
else
  pass "local PAT file is not tracked by Git"
fi

staged_pat_path="$(git -C "$repo_root" diff --cached --name-only -- config/.github-pat)"
if [[ -n "$staged_pat_path" ]]; then
  fail "local PAT file is staged"
else
  pass "local PAT file is not staged"
fi

if [[ -f "$agent_file" ]] && grep -Fqx "$context_file" "$agent_file"; then
  pass "personal Codex instructions reference this shared context"
else
  fail "personal Codex instructions do not reference this shared context; run bash scripts/setup.sh"
fi

if (( failures > 0 )); then
  printf '\nLocal setup validation failed (%d check(s)).\n' "$failures" >&2
  exit 1
fi

printf '\nLocal setup validation passed. The PAT was not read or displayed.\n'
printf '%s\n' 'Next, run the two manual smoke tests listed in README.md.'
