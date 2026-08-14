#!/usr/bin/env bash

# Run setup in a temporary copy so the real checkout, PAT, and home folder stay untouched.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-setups-test.XXXXXX")"
test_repo="$test_root/repo"
test_token='test-token-not-a-real-secret'

pass() {
  printf 'PASS: %s\n' "$1"
}

cleanup() {
  rm -rf -- "$test_root"
}
trap cleanup EXIT

mkdir -p "$test_repo/config"
cp "$repo_root/.gitignore" "$test_repo/"
cp -R "$repo_root/context" "$repo_root/scripts" "$test_repo/"
git -C "$test_repo" init -q
test_repo_real="$(cd -- "$test_repo" && pwd -P)"
pass "created an isolated temporary repository and home folder"

printf '%s\n' "$test_token" | HOME="$test_root/home" bash "$test_repo/scripts/setup.sh" > "$test_root/output"
pass "setup script and its built-in validation completed"

test -f "$test_repo/config/.github-pat"
if [[ "$(uname -s)" == "Darwin" ]]; then
  pat_mode="$(stat -f '%Lp' "$test_repo/config/.github-pat")"
else
  pat_mode="$(stat -c '%a' "$test_repo/config/.github-pat")"
fi
test "$pat_mode" = 600
pass "temporary PAT file was created with restricted permissions"

git -C "$test_repo" check-ignore -q -- config/.github-pat
if git -C "$test_repo" ls-files --error-unmatch -- config/.github-pat >/dev/null 2>&1; then
  echo "The temporary PAT file was unexpectedly tracked by Git." >&2
  exit 1
fi
pass "temporary PAT file is ignored and untracked"

grep -Fqx "$test_repo_real/context/GLOBAL_AI_CONTEXT.md" "$test_root/home/.codex/AGENTS.md"
pass "temporary Codex instructions point at the temporary shared context"

if grep -Fq "$test_token" "$test_root/output"; then
  echo "The test token was unexpectedly printed." >&2
  exit 1
fi
pass "temporary PAT value was not printed"

echo "Temporary setup test passed. Your real setup was not changed."
