# ai-setups

Private, personal machine-level infrastructure for AI tools. This repository keeps safe shared instructions, setup documentation, and future helper tooling in one durable place. Secrets stay local and are never committed.

## Start here: setting up a new machine

1. Clone this private repository.
2. Check for `config/.github-pat`. It is not included in the repository: create it if it is missing. If it already exists and is your local file, replace its contents with **only** your GitHub Personal Access Token—no labels, comments, quotes, or `PASTE ... HERE` text. Never commit or share this file.
3. Restrict the file to your user: run `chmod 600 config/.github-pat` on macOS/Linux, or set a user-only NTFS ACL on Windows.
4. Create or open your personal Codex file: `~/.codex/AGENTS.md` (on Windows: `%USERPROFILE%\.codex\AGENTS.md`). This is inside **your home folder**—not the machine root and not this repository.
5. Add this to that file, replacing `<your-clone>` with this repository's location on your machine:

   ```text
   Before performing repository or GitHub work, read and follow:
   <your-clone>/context/GLOBAL_AI_CONTEXT.md
   ```

6. If you use Claude Cowork, connect only `<your-clone>/context` and paste `CLAUDE_COWORK_GLOBAL.txt` into Global Instructions.

Throughout this documentation, the *repository root* means the directory containing this README. Paths such as `context/` and `config/` are relative to that directory, so the repository can live anywhere on a machine.

## Why this exists

I use multiple AI tools and agents. This gives their shared setup a durable home, so important configuration does not rely on memory or repeated prompts.

## Directory layout

- `context/` — safe AI-readable shared context.
- `config/` — local secret store; never general agent context.
- `codex/` — documentation for Codex-specific host configuration.

## Current agents

### Codex

- Global instructions live at `~/.codex/AGENTS.md` (`~` means the current user's home directory on macOS, Linux, or Windows).
- Codex is configured to read [GLOBAL_AI_CONTEXT.md](context/GLOBAL_AI_CONTEXT.md).
- Codex has a local-only GitHub Projects v2 capability using the credential in `config/`.
- That token may be consumed only through a command-scoped mechanism that does not print or persist it. On macOS and Linux, this means shell substitution.
- The normal structured GitHub connector/API remains preferred for ordinary repository, issue, pull-request, review, and CI work.

### Claude Cowork

- Cowork connects only to this repository's `context/` directory.
- Cowork must never connect to the repository root or its `config/` directory.
- Cowork Global Instructions are sourced from [context/CLAUDE_COWORK_GLOBAL.txt](context/CLAUDE_COWORK_GLOBAL.txt).
- Cowork currently does not receive direct access to the PAT.

## GitHub access model

The structured GitHub connector/API is preferred. The `gh` CLI, Git transport, connector/API, and browser are separate capabilities: failure of one does not imply failure of another. Never switch account, repository, remote, fork, or publication path merely because one access path fails.

User-owned GitHub Projects v2 currently needs a separate local credential path for Codex.

## Authority model

Technical capability is not semantic authority. Repository-specific governance wins whenever it is stricter, and credentials never authorize actions by themselves.

## Secret handling

- `config/` is intentionally ignored by Git except for `README.md`.
- `.github-pat` must never enter Git history.
- Never paste credentials into prompts, logs, issues, pull requests, commits, or artifacts.
- If a secret is ever committed, treat it as compromised and rotate it; deleting the file is not enough.

## Platform support

This setup has been tested only on this MacBook (macOS). The repository layout is intentionally portable, and the Windows/Linux notes are recovery guidance, but they have not yet been validated on those operating systems. Verify the local path, secret-file permissions, and agent configuration before relying on a non-macOS setup.

## Current known limitation

ChatGPT's current GitHub App connector cannot independently read user-owned Projects v2 through its GitHub App token. This repository currently solves that for local Codex. A future sanitized bridge or tool may expose Projects v2 evidence to ChatGPT/Cowork without exposing the PAT.

## Rule of thumb

> If it is safe for an AI to read directly, it belongs in `context/`. If it is a credential or secret, it belongs in `config/` and must not be committed.
