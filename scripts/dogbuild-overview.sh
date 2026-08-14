#!/usr/bin/env bash

# Show the latest safe DogBuild report for each project. This reads only the
# chosen report directory; it never contacts GitHub or reads config/.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
reports_dir="${1:-$repo_root/reports/dogbuild}"

safe_report() {
  local report="$1"
  ! grep -Eiq 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|Bearer[[:space:]]+[^[:space:]]+|Authorization:[[:space:]]*[^[:space:]]+' "$report"
}

meta() {
  local key="$1"
  local report="$2"
  awk -v key="$key" 'index($0, "- " key ": ") == 1 {print substr($0, length(key) + 5); exit}' "$report"
}

detail() {
  local heading="$1"
  local report="$2"
  awk -v heading="$heading" '$0 == "## " heading {getline; print; exit}' "$report"
}

render() {
  local report="$1"
  local project branch head changed worked blocked next_action
  project="$(meta "Project" "$report")"
  branch="$(meta "Branch" "$report")"
  head="$(meta "Head" "$report")"
  changed="$(detail "What changed" "$report")"
  worked="$(detail "What worked" "$report")"
  blocked="$(detail "What is blocked" "$report")"
  next_action="$(detail "What happens next" "$report")"

  printf '%s\n' "$project"
  printf '  Branch: %s  Head: %s\n' "$branch" "$head"
  printf '  Changed: %s\n' "$changed"
  printf '  Worked: %s\n' "$worked"
  printf '  Blocked: %s\n' "$blocked"
  printf '  Next: %s\n\n' "$next_action"
}

if [[ ! -d "$reports_dir" ]]; then
  printf 'No report directory: %s\n' "$reports_dir" >&2
  exit 1
fi

entries="$(mktemp "${TMPDIR:-/tmp}/dogbuild-overview.XXXXXX")"
trap 'rm -f -- "$entries"' EXIT

for report in "$reports_dir"/*-summary.md; do
  [[ -f "$report" ]] || continue
  safe_report "$report" || continue

  project="$(meta "Project" "$report")"
  branch="$(meta "Branch" "$report")"
  head="$(meta "Head" "$report")"
  changed="$(detail "What changed" "$report")"
  worked="$(detail "What worked" "$report")"
  blocked="$(detail "What is blocked" "$report")"
  next_action="$(detail "What happens next" "$report")"

  [[ "$project" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || continue
  [[ -n "$branch" && -n "$head" && -n "$changed" && -n "$worked" && -n "$blocked" && -n "$next_action" ]] || continue
  printf '%s\t%s\n' "$project" "$report" >> "$entries"
done

if [[ ! -s "$entries" ]]; then
  printf 'No valid safe DogBuild reports found in %s\n' "$reports_dir"
  exit 0
fi

printf 'DogBuild report overview\n\n'
last_project=""
last_report=""
while IFS=$'\t' read -r project report; do
  if [[ -n "$last_project" && "$project" != "$last_project" ]]; then
    render "$last_report"
  fi
  last_project="$project"
  last_report="$report"
done < <(LC_ALL=C sort -t $'\t' -k1,1 -k2,2 "$entries")
render "$last_report"
