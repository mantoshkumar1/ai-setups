#!/usr/bin/env bash

# Prove the actual installed DogBuild report command reaches an isolated local
# ai-setups handoff. This never uses real reports or configuration.
set -euo pipefail

if ! command -v dogbuild >/dev/null 2>&1; then
  echo 'SKIP: DogBuild is not installed; the isolated integration test was not run.'
  exit 0
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/dogbuild-handoff-test.XXXXXX")"
project_dir="$test_root/atlas-web"
central_dir="$test_root/central"
handoff="$test_root/PROJECT_UPDATES.md"

cleanup() {
  rm -rf -- "$test_root"
}
trap cleanup EXIT

git init -q "$project_dir"
python3 "$script_dir/dogbuild-share.py" "$project_dir" --reports-dir "$central_dir" --handoff-output "$handoff" \
  --changed 'Added isolated handoff coverage' \
  --worked 'DogBuild report completed' \
  --blocked 'Nothing' \
  --next 'Open the local Control Center' >/dev/null

grep -Fq '## atlas-web' "$handoff"
grep -Fq 'Next: "Open the local Control Center"' "$handoff"

echo 'PASS: an isolated DogBuild report reached the local ai-setups handoff'
