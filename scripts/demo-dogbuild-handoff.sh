#!/usr/bin/env bash

# Show the real DogBuild-to-ai-setups flow without touching a real project.
set -euo pipefail

if ! command -v dogbuild >/dev/null 2>&1; then
  echo 'DogBuild is not installed, so this real demo cannot start.' >&2
  echo 'Use: python3 scripts/dogbuild-control-center.py --demo' >&2
  exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
demo_root="$(mktemp -d "${TMPDIR:-/tmp}/dogbuild-ai-state-demo.XXXXXX")"
project_dir="$demo_root/atlas-web"
source_dir="$demo_root/source"
reports_dir="$demo_root/reports"
handoff="$demo_root/PROJECT_UPDATES.md"

cleanup() {
  rm -rf -- "$demo_root"
}
trap cleanup EXIT

git init -q "$project_dir"
dogbuild report "$project_dir" --output-dir "$source_dir" \
  --changed 'Added a safe local AI-state handoff' \
  --worked 'DogBuild report completed' \
  --blocked 'Nothing' \
  --next 'Open the local Control Center' >/dev/null

source_report="$(find "$source_dir" -maxdepth 1 -type f -name '*-summary*.md' -print -quit)"
if [[ -z "$source_report" ]]; then
  echo 'DogBuild did not write a report, so the demo stopped.' >&2
  exit 1
fi

python3 "$script_dir/dogbuild-import-report.py" "$source_report" --reports-dir "$reports_dir" >/dev/null
python3 "$script_dir/dogbuild-sync-project-updates.py" --reports-dir "$reports_dir" --output "$handoff" >/dev/null

echo 'A temporary DogBuild project created one safe report.'
echo 'ai-setups imported it and built a temporary local handoff.'
echo 'The Control Center below reads only that temporary report folder.'
echo 'Press Ctrl-C when you are done; all demo data will be removed.'
echo
python3 "$script_dir/dogbuild-control-center.py" --reports-dir "$reports_dir" "$@"
