# Codex host setup

The canonical shared context is `context/GLOBAL_AI_CONTEXT.md`, relative to the repository root.

When setting up a host, substitute the location where this repository was cloned.

The host-wide Codex instructions file is `~/.codex/AGENTS.md` (`~` is the current user's home directory). It is host-specific, so this repository documents it rather than committing the contents of `~/.codex`.

Codex's local-only credential for user-owned GitHub Projects v2 is `config/.github-pat`, relative to the repository root.

Never copy, print, or commit that value. Consume it only through a command-scoped mechanism that does not print or persist it; on macOS and Linux, this means shell substitution.

## New-machine template

Create `~/.codex/AGENTS.md` with the following instruction, replacing `<path-to-ai-setups>` with this repository's location on that machine. Then apply any additional host-specific guidance separately:

```md
# Global Codex instructions

Before performing repository or GitHub work, read and follow:

<path-to-ai-setups>/context/GLOBAL_AI_CONTEXT.md
```

Recreate `config/.github-pat` locally; do not place a secret value in this repository. On macOS/Linux, set its mode to `600`. On Windows, restrict its NTFS access-control list to the current user.
