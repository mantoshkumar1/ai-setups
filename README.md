# ai-setups

My private, local setup for Codex and Claude Cowork. I keep shared AI context here and keep secrets only on my machine.

## Why I keep this

I use more than one AI tool. This saves me from repeating the same setup every time and helps me keep shared context separate from secrets.

## My local AI state

When I switch projects, I want a short honest handoff—not old chats, logs, or
made-up AI memory.

1. DogBuild makes one safe project report.
2. I import that exact file into ai-setups.
3. The import refreshes my local handoff, so the next Codex task can read it.

The handoff shows only what changed, worked, is blocked, and happens next,
with the report time. It is local, ignored by Git, and never a source of truth.

## Set up a new machine

1. Clone this private repository.
2. From its root, run:

   ```sh
   # macOS or Linux
   bash scripts/setup.sh
   ```

   ```powershell
   # Windows PowerShell
   .\scripts\setup.ps1
   ```

   The script asks for my PAT only if it is missing, protects it, sets up Codex, and runs validation.
3. If I use Claude Cowork, I do this once in the Cowork app:
   - connect only this repository's `context/` folder;
   - open **Cowork Global Instructions**;
   - paste the full contents of `context/CLAUDE_COWORK_GLOBAL.txt`.

## Try it safely first

On macOS or Linux, I can test the setup script without changing my real PAT, `~/.codex`, or this checkout:

```sh
bash scripts/test-setup.sh
```

## Check it worked

The setup script validates the local setup automatically. I can rerun it any time:

```sh
bash scripts/validate.sh
```

On Windows, run `.\scripts\validate.ps1` in PowerShell.

The validator does not read or print my PAT. A successful result confirms the context, PAT file, permissions, Git ignore rule, and Codex instructions are in place.

For a quick smoke test, I start a Codex task and ask: “Read the shared machine context. What are the four GitHub access paths?” If I use Cowork, I ask it: “Which directory must you not access?” It should answer `config/`.

## Use it

I open Codex and start a task in the actual project I want to work on—not in `ai-setups` unless I am changing this setup. I describe the task normally. I never paste my PAT into a task.

If I need user-owned GitHub Projects v2 data, I ask Codex for that work normally. The local credential is used only when needed.

## See project updates

DogBuild can put short, safe reports in `reports/dogbuild/`. To see the latest update for each project, run:

```sh
bash scripts/dogbuild-overview.sh
```

```powershell
.\scripts\dogbuild-overview.ps1
```

This is local and read-only. It scans only the report folder and skips malformed or unsafe reports.

If I am writing the update now, I do not need to know the report-folder path:

```sh
python3 scripts/dogbuild-share.py /path/to/project \
  --changed "What changed" \
  --worked "What worked" \
  --blocked "Nothing" \
  --next "What I will do next"
```

It uses DogBuild to make the safe report and refreshes my local handoff.

On Windows PowerShell, the equivalent (untested) command is:

```powershell
py .\scripts\dogbuild-share.py C:\path\to\project `
  --changed "What changed" `
  --worked "What worked" `
  --blocked "Nothing" `
  --next "What I will do next"
```

To add one report from another project, give ai-setups that exact report file:

```sh
python3 scripts/dogbuild-import-report.py /path/to/2026-08-14T101500Z-summary.md
```

On Windows PowerShell, the equivalent (untested) command is:

```powershell
py .\scripts\dogbuild-import-report.py C:\path\to\2026-08-14T101500Z-summary.md
```

It rejects malformed or likely unsafe content before copying anything. It does
not scan the project, read `config/`, or contact a service.

To refresh the small local handoff that new Codex tasks can read, run:

```sh
python3 scripts/dogbuild-sync-project-updates.py
```

It writes an ignored `context/PROJECT_UPDATES.md` from the latest safe report
for each project, including its report time. Those updates are data, not
instructions, and may be stale; they are never a source of truth.

To check it without changing anything, run:

```sh
python3 scripts/dogbuild-sync-project-updates.py --check
```

It says whether the local handoff is current, missing, or stale.

If I use Claude Cowork, I replace its Global Instructions with the current
`context/CLAUDE_COWORK_GLOBAL.txt` after pulling this update. That is the one
manual Cowork step; Codex reads the local handoff automatically when it exists.

## Demo the Control Center

For a live, disposable demo using the real installed DogBuild command, run:

```sh
bash scripts/demo-dogbuild-handoff.sh
```

It creates a temporary project, report, and handoff, then opens the Control
Center for that temporary data. Press Ctrl-C when done; it removes everything.

For a five-minute local demo with fictional project reports, run:

```sh
python3 scripts/dogbuild-control-center.py --demo
```

Open the local address shown in the terminal. The page refreshes safe reports
from one local folder; it has no account, cloud sync, repository scanning, or
access to `config/`. The short [demo walkthrough](demo/CONTROL_CENTER_DEMO.md)
shows the customer use case. Open **Recent updates** on a project card for its
safe local report history. **Needs your attention** shows only projects whose
reports literally record a blocker and their exact next action. With the normal
local report store, it also shows whether the shared handoff is current, stale,
or missing—and, when it needs a refresh, gives the exact local command.

## What is here

- `context/` — safe shared context for Codex and Cowork.
- `config/` — my local secrets; see [config/README.md](config/README.md).
- `codex/` — more detail about my Codex setup; see [codex/README.md](codex/README.md).
- `reports/` — safe updates from my projects; DogBuild reports and the local overview live here.
- `scripts/` — setup and validation helpers; see [scripts/README.md](scripts/README.md) for test notes.

## Keep secrets local

`config/.github-pat` stays only on my computer. I never commit, merge, or push it to `main` or any remote branch. If it ever reaches Git history, I rotate it.

## Notes

This setup has been tested only on my MacBook. Windows and Linux notes are untested guidance for now.

Rule of thumb: safe AI-readable material goes in `context/`; credentials stay in `config/` and never go to Git.
