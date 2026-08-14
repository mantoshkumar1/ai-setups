#!/usr/bin/env python3
"""Add one explicit safe DogBuild report to the local Control Center store."""

from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path


SCRIPT = Path(__file__).with_name("dogbuild-control-center.py")
SPEC = importlib.util.spec_from_file_location("control_center", SCRIPT)
control_center = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(control_center)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Import one explicit safe DogBuild report into the local Control Center store."
    )
    parser.add_argument("source", type=Path, help="report file to import")
    parser.add_argument(
        "--reports-dir",
        type=Path,
        default=control_center.DEFAULT_REPORTS,
        help="local report store (default: this ai-setups checkout's reports/dogbuild)",
    )
    args = parser.parse_args(argv)

    try:
        destination = control_center.import_report(args.source, args.reports_dir)
        handoff = None
        if args.reports_dir.resolve() == control_center.DEFAULT_REPORTS.resolve():
            handoff = control_center.write_project_updates(args.reports_dir)
    except (ValueError, FileExistsError) as error:
        print("Not imported: {}".format(error), file=sys.stderr)
        return 1

    print("Safe report imported locally: {}".format(destination))
    if handoff:
        print("Updated local project handoff: {}".format(handoff))
    print("Open the Control Center to see this project update.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
