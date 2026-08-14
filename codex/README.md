# Codex host setup

The canonical shared context is:

`/Users/mantoshkumar/Desktop/project/ai-setups/context/GLOBAL_AI_CONTEXT.md`

The host-wide Codex instructions file is `~/.codex/AGENTS.md`. It is host-specific, so this repository documents it rather than committing the contents of `~/.codex`.

Codex's local-only credential for user-owned GitHub Projects v2 is:

`/Users/mantoshkumar/Desktop/project/ai-setups/config/.github-pat`

Never copy, print, or commit that value. Consume it only through shell substitution for the specific authenticated command that needs it.

## New-machine template

Create `~/.codex/AGENTS.md` with the following instruction, then apply any additional host-specific guidance separately:

```md
# Global Codex instructions

Before performing repository or GitHub work, read and follow:

/Users/mantoshkumar/Desktop/project/ai-setups/context/GLOBAL_AI_CONTEXT.md
```

Recreate `config/.github-pat` locally and set its mode to `600`; do not place a secret value in this repository.
