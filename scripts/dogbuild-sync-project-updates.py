#!/usr/bin/env python3
"""Refresh the local data-only project handoff from safe DogBuild reports."""

from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path
from typing import List, Optional


SCRIPT = Path(__file__).with_name("dogbuild-control-center.py")
SPEC = importlib.util.spec_from_file_location("control_center", SCRIPT)
control_center = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(control_center)


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Refresh the local project-updates handoff from safe DogBuild reports."
    )
    parser.add_argument(
        "--reports-dir",
        type=Path,
        default=control_center.DEFAULT_REPORTS,
        help="report folder to read (default: this ai-setups checkout's reports/dogbuild)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=control_center.PROJECT_UPDATES,
        help="local handoff file to write (default: context/PROJECT_UPDATES.md)",
    )
    parser.add_argument("--check", action="store_true", help="check whether the local handoff is current without writing it")
    args = parser.parse_args(argv)
    try:
        if args.check:
            status = control_center.project_updates_status(args.reports_dir, args.output)
            if status == "current":
                print("Local project handoff is current.")
                return 0
            print("Local project handoff is {}. Run: python3 scripts/dogbuild-sync-project-updates.py".format(status))
            return 1
        destination = control_center.write_project_updates(args.reports_dir, args.output)
    except ValueError as error:
        print("Not updated: {}".format(error), file=sys.stderr)
        return 1
    print("Updated local project handoff: {}".format(destination))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
