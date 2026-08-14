#!/usr/bin/env python3
"""Write one DogBuild report into this local AI-state store and refresh it."""

from __future__ import annotations

import argparse
import importlib.util
import subprocess
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
        description="Share one DogBuild update with this local ai-setups handoff."
    )
    parser.add_argument("project", type=Path, help="Git project for DogBuild to report on")
    parser.add_argument("--changed", required=True, help="one short line about what changed")
    parser.add_argument("--worked", required=True, help="one short line about what worked")
    parser.add_argument("--blocked", required=True, help="one short line about what is blocked")
    parser.add_argument("--next", dest="next_action", required=True, help="one short line about what happens next")
    parser.add_argument("--reports-dir", type=Path, default=control_center.DEFAULT_REPORTS, help=argparse.SUPPRESS)
    parser.add_argument("--handoff-output", type=Path, default=control_center.PROJECT_UPDATES, help=argparse.SUPPRESS)
    args = parser.parse_args(argv)

    if control_center.is_within(args.reports_dir, control_center.ROOT / "config") or control_center.is_within(
        args.handoff_output, control_center.ROOT / "config"
    ):
        print("Not shared: the config directory is never a report or handoff destination.", file=sys.stderr)
        return 1

    command = [
        "dogbuild",
        "report",
        str(args.project),
        "--output-dir",
        str(args.reports_dir),
        "--changed",
        args.changed,
        "--worked",
        args.worked,
        "--blocked",
        args.blocked,
        "--next",
        args.next_action,
    ]
    try:
        subprocess.run(command, check=True)
    except FileNotFoundError:
        print("DogBuild is not installed. Install it, then run this command again.", file=sys.stderr)
        return 1
    except subprocess.CalledProcessError as error:
        return error.returncode

    try:
        handoff = control_center.write_project_updates(args.reports_dir, args.handoff_output)
    except ValueError as error:
        print("Report was written, but the local handoff was not updated: {}".format(error), file=sys.stderr)
        return 1

    print("Shared with local AI state.")
    print("Updated local handoff: {}".format(handoff))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
