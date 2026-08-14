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
source_dir="$test_root/source"
central_dir="$test_root/central"
handoff="$test_root/PROJECT_UPDATES.md"

cleanup() {
  rm -rf -- "$test_root"
}
trap cleanup EXIT

git init -q "$project_dir"
dogbuild report "$project_dir" --output-dir "$source_dir" \
  --changed 'Added isolated handoff coverage' \
  --worked 'DogBuild report completed' \
  --blocked 'Nothing' \
  --next 'Open the local Control Center' >/dev/null

source_report="$(find "$source_dir" -maxdepth 1 -type f -name '*-summary*.md' -print -quit)"
if [[ -z "$source_report" ]]; then
  echo 'FAIL: DogBuild did not write a report.' >&2
  exit 1
fi

python3 "$script_dir/dogbuild-import-report.py" "$source_report" --reports-dir "$central_dir" >/dev/null
python3 "$script_dir/dogbuild-sync-project-updates.py" --reports-dir "$central_dir" --output "$handoff" >/dev/null

grep -Fq '## atlas-web' "$handoff"
grep -Fq 'Next: "Open the local Control Center"' "$handoff"

echo 'PASS: an isolated DogBuild report reached the local ai-setups handoff'
