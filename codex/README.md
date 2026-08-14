# Codex host setup

The canonical shared context is `context/GLOBAL_AI_CONTEXT.md`, relative to the repository root.

## Recommended: run the setup script

From the repository root, run one command:

```sh
# macOS or Linux
bash scripts/setup.sh
```

```powershell
# Windows PowerShell
.\scripts\setup.ps1
```

The script finds this clone automatically, securely requests a PAT only when no local credential exists, protects the credential file, and adds the shared-context instruction below to your personal Codex file. It preserves unrelated instructions already in that file.

## Starting a session

After setup, open Codex and start a task in the actual repository you want to work on. Use `ai-setups` only when you want to change this setup. Describe the task normally; if it needs GitHub Projects v2, ask for that work without pasting the PAT into the conversation.

## Where `AGENTS.md` lives

`AGENTS.md` is a personal Codex file, not a file in this repository and not a file at the machine root.

- macOS/Linux: `~/.codex/AGENTS.md` (`~` means your home folder)
- Windows: `%USERPROFILE%\.codex\AGENTS.md`

It is host-specific, so this repository documents it rather than committing the contents of `.codex`.

Codex's local-only credential for user-owned GitHub Projects v2 is `config/.github-pat`, relative to the repository root.

Never copy, print, or commit that value. Consume it only through a command-scoped mechanism that does not print or persist it; on macOS and Linux, this means shell substitution.

## Manual fallback

If you cannot run the script, create the file if it does not exist, or add the following instruction to it. Replace `<your-clone>` with this repository's location on that machine:

```md
Before performing repository or GitHub work, read and follow:

<your-clone>/context/GLOBAL_AI_CONTEXT.md
```

Keep `config/.github-pat` only on your computer. Never commit, merge, or push it to remote `main`—or to any remote branch. On macOS/Linux, set its mode to `600`. On Windows, restrict its NTFS access-control list to the current user.

## Validation status

This configuration has been tested only on this MacBook (macOS). The Windows and Linux notes are unverified recovery guidance; validate the Codex instruction path and secret-file permissions on those hosts before use.
