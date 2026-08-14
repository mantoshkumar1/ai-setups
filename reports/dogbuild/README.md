# DogBuild reports

DogBuild puts short, safe status updates here.

Use one file per update: `YYYY-MM-DDTHHMMSSZ-summary.md`.

Keep each update simple:

- What changed
- What worked
- What is blocked
- What happens next

Do not include tokens, secrets, full logs, or product source code.

To see the latest report for each project, run `bash scripts/dogbuild-overview.sh`
from the repository root. The overview is local and read-only.

To bring in a report made in another project, run:

```sh
python3 scripts/dogbuild-import-report.py /path/to/2026-08-14T101500Z-summary.md
```

The command reads only that explicit file, validates it, and copies a safe
version here. It never overwrites a different report.
