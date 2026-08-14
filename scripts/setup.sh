#!/usr/bin/env bash

# Bootstrap this checkout without printing or storing the PAT anywhere except
# the ignored config/.github-pat file.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
context_file="$repo_root/context/GLOBAL_AI_CONTEXT.md"
config_dir="$repo_root/config"
pat_file="$config_dir/.github-pat"
agent_dir="$HOME/.codex"
agent_file="$agent_dir/AGENTS.md"
begin_marker="# >>> ai-setups shared context >>>"
end_marker="# <<< ai-setups shared context <<<"

if [[ ! -f "$context_file" ]]; then
  echo "Missing shared context: $context_file" >&2
  exit 1
fi

mkdir -p "$config_dir"

if [[ ! -f "$pat_file" ]]; then
  printf 'Paste your GitHub Personal Access Token (input is hidden): '
  IFS= read -r -s pat_value
  printf '\n'

  if [[ -z "$pat_value" ]]; then
    echo "No token entered; setup stopped without creating a credential file." >&2
    exit 1
  fi

  umask 077
  printf '%s\n' "$pat_value" > "$pat_file"
  unset pat_value
  echo "Created local credential file."
else
  echo "Kept existing local credential file."
fi

chmod 600 "$pat_file"

mkdir -p "$agent_dir"
if [[ ! -e "$agent_file" ]]; then
  umask 077
  : > "$agent_file"
fi

if grep -Fqx "$begin_marker" "$agent_file"; then
  temporary_file="$(mktemp "$agent_dir/.AGENTS.md.XXXXXX")"
  awk -v begin="$begin_marker" -v end="$end_marker" -v context="$context_file" '
    $0 == begin {
      print begin
      print "Before performing repository or GitHub work, read and follow:"
      print ""
      print context
      print end
      inside = 1
      next
    }
    inside && $0 == end { inside = 0; next }
    !inside { print }
  ' "$agent_file" > "$temporary_file"
  mv "$temporary_file" "$agent_file"
  echo "Updated the ai-setups section in your personal Codex instructions."
elif grep -Fqx "$context_file" "$agent_file"; then
  echo "Your personal Codex instructions already reference this shared context."
else
  {
    [[ -s "$agent_file" ]] && printf '\n'
    printf '%s\n' "$begin_marker"
    printf '%s\n' "Before performing repository or GitHub work, read and follow:"
    printf '\n'
    printf '%s\n' "$context_file"
    printf '%s\n' "$end_marker"
  } >> "$agent_file"
  echo "Added the shared context to your personal Codex instructions."
fi

printf '\nChecking your local setup now...\n'
bash "$script_dir/validate.sh"

printf '\nNext steps:\n'
printf '%s\n' '1. Open Codex and start a new task in the actual project you want to work on.'
printf '%s\n' '2. Describe the task normally; never paste the PAT into the conversation.'
printf '%s\n' '3. If you use Claude Cowork:'
printf '%s\n' "   - Connect only: $repo_root/context"
printf '%s\n' "   - Open Cowork Global Instructions and paste the entire contents of: $repo_root/context/CLAUDE_COWORK_GLOBAL.txt"
