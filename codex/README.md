# Codex host setup

The canonical shared context is `context/GLOBAL_AI_CONTEXT.md`, relative to the repository root.

When setting up a host, substitute the location where this repository was cloned.

## Where `AGENTS.md` lives

`AGENTS.md` is a personal Codex file, not a file in this repository and not a file at the machine root.

- macOS/Linux: `~/.codex/AGENTS.md` (`~` means your home folder)
- Windows: `%USERPROFILE%\.codex\AGENTS.md`

It is host-specific, so this repository documents it rather than committing the contents of `.codex`.

Codex's local-only credential for user-owned GitHub Projects v2 is `config/.github-pat`, relative to the repository root.

Never copy, print, or commit that value. Consume it only through a command-scoped mechanism that does not print or persist it; on macOS and Linux, this means shell substitution.

## What to add

Create the file if it does not exist, or add the following instruction to it. Replace `<your-clone>` with this repository's location on that machine:

```md
Before performing repository or GitHub work, read and follow:

<your-clone>/context/GLOBAL_AI_CONTEXT.md
```

Recreate `config/.github-pat` locally; do not place a secret value in this repository. On macOS/Linux, set its mode to `600`. On Windows, restrict its NTFS access-control list to the current user.

## Validation status

This configuration has been tested only on this MacBook (macOS). The Windows and Linux notes are unverified recovery guidance; validate the Codex instruction path and secret-file permissions on those hosts before use.
