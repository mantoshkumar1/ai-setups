#!/usr/bin/env bash

# Run setup in a temporary copy so the real checkout, PAT, and home folder stay untouched.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-setups-test.XXXXXX")"
test_repo="$test_root/repo"
test_token='test-token-not-a-real-secret'

cleanup() {
  rm -rf -- "$test_root"
}
trap cleanup EXIT

mkdir -p "$test_repo/config"
cp "$repo_root/.gitignore" "$test_repo/"
cp -R "$repo_root/context" "$repo_root/scripts" "$test_repo/"
git -C "$test_repo" init -q

printf '%s\n' "$test_token" | HOME="$test_root/home" bash "$test_repo/scripts/setup.sh" > "$test_root/output"

if grep -Fq "$test_token" "$test_root/output"; then
  echo "The test token was unexpectedly printed." >&2
  exit 1
fi

echo "Temporary setup test passed. Your real setup was not changed."
