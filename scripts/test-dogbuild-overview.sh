#!/usr/bin/env bash

# Test report grouping and safe parsing in a temporary directory.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/dogbuild-overview-test.XXXXXX")"
reports_dir="$test_root/reports"
output="$test_root/output"

cleanup() {
  rm -rf -- "$test_root"
}
trap cleanup EXIT

mkdir -p "$reports_dir"

report() {
  local file="$1"
  local project="$2"
  local changed="$3"
  cat > "$reports_dir/$file" <<EOF
# DogBuild report

- Project: $project
- Branch: main
- Head: abc123

## What changed
$changed

## What worked
Tests pass

## What is blocked
Nothing

## What happens next
Ship it
EOF
}

report '2026-08-14T010000Z-summary.md' 'alpha' 'old alpha change'
report '2026-08-14T020000Z-summary.md' 'alpha' 'latest alpha change'
report '2026-08-14T020000Z-summary-2.md' 'alpha' 'collision alpha change'
report '2026-08-14T015000Z-summary.md' 'beta' 'beta change'
printf '%s\n' 'not a report' > "$reports_dir/2026-08-14T030000Z-summary.md"
report '2026-08-14T040000Z-summary.md' 'unsafe' 'ghp_abcdefghijklmnopqrstuvwxyz1234567890'

bash "$script_dir/dogbuild-overview.sh" "$reports_dir" > "$output"

grep -Fq 'alpha' "$output"
grep -Fq 'collision alpha change' "$output"
grep -Fq 'beta' "$output"
grep -Fq 'beta change' "$output"
if grep -Fq 'old alpha change' "$output" || grep -Fq 'latest alpha change' "$output" || grep -Fq 'unsafe' "$output" || grep -Fq 'not a report' "$output"; then
  echo 'Overview included an old, malformed, or unsafe report.' >&2
  exit 1
fi

echo 'PASS: overview grouped reports, selected the latest, and skipped malformed or unsafe files'
