# DogBuild Control Center — five-minute demo

## Start it

```sh
python3 scripts/dogbuild-control-center.py --demo
```

Open the local address shown in the terminal.

To show the same loop with a real, disposable DogBuild report instead, run:

```sh
bash scripts/demo-dogbuild-handoff.sh
```

It creates no project state outside a temporary folder and removes that folder
when I stop the page.

## Use case

I am working across a few projects with AI help. The useful question is not
"what did every agent say?" It is: **what changed, what is blocked, and what
needs me next?**

The page answers that from short project reports. In the demo, `ledger-api`
needs sandbox access; the other two projects have a clear next action but no
recorded blocker. I can decide what to do without reopening an old agent
session, reading logs, or giving a tool my credentials.

Start with **Needs your attention**. It places `ledger-api` there because its
report literally records a blocker, then shows its exact next action. It does
not pretend to know which work is most important.

Open **Recent updates** on `atlas-web` to see the safe progression from the
earlier checkout-flow review to the current wording change. It gives useful
continuity, not a reconstruction of an agent's hidden conversation.

## Make it real

Start the same page without `--demo` after DogBuild has written reports into
`reports/dogbuild/`:

```sh
python3 scripts/dogbuild-control-center.py
```

The browser refreshes the local report folder every five seconds.

## What it is not

It is not a hosted dashboard, source-code viewer, agent controller, or source
of truth. It only makes the safe report facts easier to see.
