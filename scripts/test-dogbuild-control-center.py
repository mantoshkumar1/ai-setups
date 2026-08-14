#!/usr/bin/env python3
"""Focused isolated checks for the local Control Center."""

from __future__ import annotations

import importlib.util
import json
import tempfile
import threading
import unittest
from http.server import ThreadingHTTPServer
from pathlib import Path
from urllib.request import urlopen


SCRIPT = Path(__file__).with_name("dogbuild-control-center.py")
SPEC = importlib.util.spec_from_file_location("control_center", SCRIPT)
control_center = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(control_center)


def report(path: Path, project: str, changed: str, blocked: str = "Nothing") -> None:
    path.write_text(
        "# DogBuild report\n\n"
        "- Project: {}\n- Branch: main\n- Head: abc123\n\n"
        "## What changed\n{}\n\n"
        "## What worked\nFocused checks pass\n\n"
        "## What is blocked\n{}\n\n"
        "## What happens next\nOpen the next task\n".format(project, changed, blocked),
        encoding="utf-8",
    )


class ControlCenterTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.reports = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def test_latest_safe_report_per_project(self):
        report(self.reports / "2026-08-14T010000Z-summary.md", "alpha", "old")
        report(self.reports / "2026-08-14T020000Z-summary.md", "alpha", "new")
        report(self.reports / "2026-08-14T015000Z-summary.md", "beta", "beta work", "Waiting for sandbox")
        report(self.reports / "2026-08-14T030000Z-summary.md", "unsafe", "ghp_abcdefghijklmnopqrstuvwxyz1234567890")
        (self.reports / "2026-08-14T040000Z-summary.md").write_text("not a report", encoding="utf-8")

        projects = control_center.load_projects(self.reports)
        self.assertEqual([project["project"] for project in projects], ["alpha", "beta"])
        self.assertEqual(projects[0]["changed"], "new")
        self.assertEqual(projects[1]["blocked"], "Waiting for sandbox")

        history = control_center.load_history(self.reports, "alpha")
        self.assertEqual([item["changed"] for item in history], ["new", "old"])
        self.assertEqual(control_center.load_history(self.reports, "unsafe"), [])

    def test_local_json_endpoint(self):
        report(self.reports / "2026-08-14T010000Z-summary.md", "alpha", "new")
        server = ThreadingHTTPServer(("127.0.0.1", 0), control_center.handler_for(self.reports))
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            with urlopen("http://127.0.0.1:{}/api/projects".format(server.server_port)) as response:
                payload = json.loads(response.read().decode("utf-8"))
            self.assertEqual(payload["projects"][0]["project"], "alpha")
            self.assertEqual(payload["projects"][0]["next"], "Open the next task")
            with urlopen("http://127.0.0.1:{}/api/projects/alpha/history".format(server.server_port)) as response:
                history = json.loads(response.read().decode("utf-8"))
            self.assertEqual(history["history"][0]["changed"], "new")
        finally:
            server.shutdown()
            server.server_close()


if __name__ == "__main__":
    unittest.main()
