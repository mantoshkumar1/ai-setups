# ai-setups

Private, personal machine-level infrastructure for AI tools. This repository keeps safe shared instructions, setup documentation, and future helper tooling in one durable place. Secrets stay local and are never committed.

## Start here: setting up a new machine

1. Clone this private repository.
2. Run one setup script from the repository root:

   ```sh
   # macOS or Linux
   bash scripts/setup.sh
   ```

   ```powershell
   # Windows PowerShell
   .\scripts\setup.ps1
   ```

   The script asks for your PAT only if `config/.github-pat` is missing, protects that file, sets up your personal Codex instructions, and runs the local validator. It ends by showing the remaining manual steps. It never prints the token.
3. If you use Claude Cowork, connect only this repository's `context/` directory and paste `CLAUDE_COWORK_GLOBAL.txt` into Global Instructions. This is the one manual app setting.

## What you still do manually

The script cannot do these personal or app-specific steps for you:

1. Install Codex and sign in to your own account.
2. Clone this private repository on the machine.
3. Paste your own PAT when the script privately prompts for it. The script never creates, prints, or uploads the token for you.
4. If you use Claude Cowork, make its one-time `context/` connection and paste its Global Instructions in the Cowork app.
5. Whenever you want to work, choose the actual project and start a new Codex task there.

## Validate your setup

The setup script runs this automatically. Run it again any time from the repository root:

```sh
# macOS or Linux
bash scripts/validate.sh
```

```powershell
# Windows PowerShell
.\scripts\validate.ps1
```

The validator checks the shared context, the local PAT file, its permissions, Git ignore/tracking status, and the Codex instruction reference. It does not read or display the PAT. A passing result means the local setup is correct.

Then run these two quick smoke tests that no script can perform:

1. In a new Codex task, ask: “Read the shared machine context. What are the four GitHub access paths?” It should answer `gh CLI`, Git transport, the structured GitHub connector/API, and browser/UI.
2. If you use Claude Cowork, start a new Cowork chat connected to `context/` and ask: “Which directory must you not access?” It should identify the sibling `config/` directory.

If you use GitHub Projects v2, also ask Codex to read one known user-owned Project. A successful response confirms the local credential works; never paste the PAT into the task.

## Use it: start a Codex session

1. Open the Codex desktop app.
2. Start a new task in the **actual project** you want to work on. Do not use `ai-setups` as the project unless you are changing this setup itself.
3. Describe the work normally—for example: “Review the open issues in this repository” or “Fix this failing test.”
4. If the work needs your user-owned GitHub Projects v2 data, ask Codex for that task normally. Do **not** paste the PAT into the message; Codex uses the local file only when that capability is needed.

Once the setup script has run, you do not need to repeat it for each Codex session.

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
