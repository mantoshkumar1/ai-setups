#!/usr/bin/env python3
"""A local-only Control Center for safe DogBuild project reports.

The server binds to 127.0.0.1, reads only one selected report directory, and
has no dependencies beyond Python's standard library.
"""

from __future__ import annotations

import argparse
import json
import re
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any, Dict, List, Optional
from urllib.parse import unquote, urlparse


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_REPORTS = ROOT / "reports" / "dogbuild"
DEMO_REPORTS = ROOT / "demo" / "dogbuild-reports"
PROJECT_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
TIMESTAMP_RE = re.compile(r"^(\d{4}-\d{2}-\d{2}T\d{6}Z)-summary\.md$")
UNSAFE_RE = re.compile(
    r"ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|"
    r"AKIA[0-9A-Z]{16}|Bearer\s+\S+|Authorization:\s*\S+",
    re.IGNORECASE,
)
CLEAR_BLOCKERS = frozenset(("nothing", "none", "no blocker", "no blockers", "no active blocker"))


def _meta(lines: List[str], key: str) -> str:
    prefix = "- {}: ".format(key)
    for line in lines:
        if line.startswith(prefix):
            return line[len(prefix):].strip()
    return ""


def _detail(lines: List[str], heading: str) -> str:
    marker = "## " + heading
    for index, line in enumerate(lines[:-1]):
        if line == marker:
            return lines[index + 1].strip()
    return ""


def _display_time(filename: str) -> str:
    match = TIMESTAMP_RE.match(filename)
    if not match:
        return "Unknown time"
    timestamp = match.group(1)
    return "{} {} UTC".format(timestamp[:10], timestamp[11:13] + ":" + timestamp[13:15])


def parse_report(path: Path) -> Optional[Dict[str, str]]:
    """Return one safe, well-formed report or None.

    This intentionally does not try to repair report content. A bad or unsafe
    file should be invisible rather than accidentally become a data source.
    """
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return None
    if UNSAFE_RE.search(text):
        return None

    lines = text.splitlines()
    project = _meta(lines, "Project")
    result = {
        "project": project,
        "branch": _meta(lines, "Branch"),
        "head": _meta(lines, "Head"),
        "changed": _detail(lines, "What changed"),
        "worked": _detail(lines, "What worked"),
        "blocked": _detail(lines, "What is blocked"),
        "next": _detail(lines, "What happens next"),
        "updated": _display_time(path.name),
        "filename": path.name,
    }
    if not PROJECT_RE.match(project or ""):
        return None
    if not all(result[key] for key in ("branch", "head", "changed", "worked", "blocked", "next")):
        return None
    return result


def load_projects(reports_dir: Path) -> List[Dict[str, str]]:
    """Load the lexically newest valid report per project from one directory."""
    if not reports_dir.is_dir():
        return []
    latest: Dict[str, Dict[str, str]] = {}
    for path in sorted(reports_dir.glob("*-summary.md")):
        report = parse_report(path)
        if report is None:
            continue
        current = latest.get(report["project"])
        if current is None or report["filename"] > current["filename"]:
            latest[report["project"]] = report
    return [latest[project] for project in sorted(latest)]


def load_history(reports_dir: Path, project: str) -> List[Dict[str, str]]:
    """Load one project's valid safe reports, newest first."""
    if not PROJECT_RE.match(project or "") or not reports_dir.is_dir():
        return []
    history = []
    for path in sorted(reports_dir.glob("*-summary.md"), reverse=True):
        report = parse_report(path)
        if report is not None and report["project"] == project:
            history.append(report)
    return history


def has_recorded_blocker(blocked: str) -> bool:
    """Return whether a report records a blocker without scoring its urgency."""
    return blocked.strip().lower() not in CLEAR_BLOCKERS


def project_payload(reports_dir: Path) -> List[Dict[str, Any]]:
    return [
        {**report, "has_recorded_blocker": has_recorded_blocker(report["blocked"])}
        for report in load_projects(reports_dir)
    ]


PAGE = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>DogBuild Control Center</title>
  <style>
    :root { --ink:#172033; --muted:#697386; --line:#e6eaf0; --paper:#fffdf9; --bg:#f4f6fa; --accent:#6254ff; --warm:#faecd8; --alert:#fff1ef; }
    * { box-sizing:border-box; } body { margin:0; color:var(--ink); background:var(--bg); font:16px/1.45 ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif; }
    header { padding:54px max(24px,calc((100vw - 1120px)/2)); background:linear-gradient(120deg,#172033 0%,#2b2f70 100%); color:white; }
    .eyebrow { margin:0 0 10px; color:#c9c5ff; font-size:12px; font-weight:700; letter-spacing:.12em; text-transform:uppercase; } h1 { margin:0; font-size:clamp(32px,5vw,54px); line-height:1.04; letter-spacing:-.045em; } .intro { max-width:650px; margin:16px 0 0; color:#e1e4fd; font-size:18px; }
    main { max-width:1120px; margin:0 auto; padding:28px 24px 64px; } .focus { margin-bottom:28px; border:1px solid #f1c5ba; border-radius:18px; background:var(--alert); padding:22px; } .focus h2 { margin:0 0 10px; } .focus-copy { margin:0 0 16px; color:var(--muted); } .attention-list { display:grid; gap:10px; } .attention-item { display:flex; align-items:start; justify-content:space-between; gap:18px; border-radius:12px; background:white; padding:14px; } .attention-project { font-weight:800; } .attention-next { color:#9d3c2c; font-weight:700; text-align:right; } .attention-empty { color:var(--muted); } .bar { display:flex; align-items:center; justify-content:space-between; gap:16px; color:var(--muted); font-size:14px; margin-bottom:20px; } .pill { border:1px solid #d7ddff; background:#eef0ff; color:#4a3fe0; border-radius:999px; padding:5px 10px; font-weight:700; }
    #projects { display:grid; grid-template-columns:repeat(auto-fit,minmax(300px,1fr)); gap:18px; } .card { position:relative; overflow:hidden; border:1px solid var(--line); border-radius:18px; background:var(--paper); box-shadow:0 8px 26px rgba(22,32,51,.06); padding:22px; } .card::before { content:""; position:absolute; inset:0 auto 0 0; width:5px; background:var(--accent); } .card.attention::before { background:#e46b52; } .title { display:flex; justify-content:space-between; gap:12px; align-items:start; } h2 { margin:0; font-size:22px; letter-spacing:-.02em; } .updated { color:var(--muted); font-size:12px; white-space:nowrap; } .git { margin:6px 0 20px; color:var(--muted); font:12px/1.4 ui-monospace,SFMono-Regular,Menlo,monospace; }
    dl { display:grid; gap:14px; margin:0; } dt { margin:0 0 2px; color:var(--muted); font-size:11px; font-weight:800; letter-spacing:.08em; text-transform:uppercase; } dd { margin:0; } .next { margin-top:20px; padding:14px; border-radius:12px; background:var(--warm); } .next dd { font-weight:700; } .history { margin-top:18px; border-top:1px solid var(--line); padding-top:14px; } summary { cursor:pointer; color:#4a3fe0; font-size:14px; font-weight:700; } .history-list { display:grid; gap:12px; margin-top:14px; } .history-item { border-left:3px solid #d7ddff; padding-left:10px; font-size:14px; } .history-time { color:var(--muted); font-size:12px; } .history-label { color:var(--muted); font-size:11px; font-weight:800; letter-spacing:.07em; text-transform:uppercase; } .history-loading { margin:12px 0 0; color:var(--muted); font-size:14px; } .empty { grid-column:1/-1; padding:34px; text-align:center; background:var(--paper); border:1px dashed #cbd2dd; border-radius:16px; color:var(--muted); }
    footer { max-width:1120px; margin:0 auto; padding:0 24px 32px; color:var(--muted); font-size:13px; } @media (max-width:560px) { header { padding-top:38px; } .bar { align-items:flex-start; flex-direction:column; } }
  </style>
</head>
<body>
  <header><p class="eyebrow">Local-only project briefings</p><h1>DogBuild Control Center</h1><p class="intro">A quiet view of what changed, what is blocked, and what needs your attention next.</p></header>
  <main>
    <section class="focus"><p class="eyebrow" style="color:#a14333">Recorded blockers</p><h2>Needs your attention</h2><p class="focus-copy">This is a literal queue from project reports, not an AI priority score.</p><div id="attention" class="attention-list"></div></section>
    <div class="bar"><span id="summary">Loading local reports…</span><span class="pill">Local and read-only</span></div>
    <section id="projects" aria-live="polite"></section>
  </main>
  <footer>Reads one local report folder. No account, cloud sync, repository scanning, or secret access.</footer>
  <script>
    const escapeHtml = value => String(value).replace(/[&<>'"]/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[char]));
    function card(project) {
      const attention = project.has_recorded_blocker;
      return `<article class="card ${attention ? 'attention' : ''}"><div class="title"><h2>${escapeHtml(project.project)}</h2><span class="updated">${escapeHtml(project.updated)}</span></div><p class="git">${escapeHtml(project.branch)} · ${escapeHtml(project.head)}</p><dl><div><dt>Changed</dt><dd>${escapeHtml(project.changed)}</dd></div><div><dt>Worked</dt><dd>${escapeHtml(project.worked)}</dd></div><div><dt>Blocked</dt><dd>${escapeHtml(project.blocked)}</dd></div><div class="next"><dt>Next</dt><dd>${escapeHtml(project.next)}</dd></div></dl><details class="history" data-project="${escapeHtml(project.project)}"><summary>Recent updates</summary><p class="history-loading">Open to load safe local history.</p></details></article>`;
    }
    function renderAttention(projects) {
      const attention = projects.filter(project => project.has_recorded_blocker);
      document.getElementById('attention').innerHTML = attention.length ? attention.map(project => `<div class="attention-item"><div><div class="attention-project">${escapeHtml(project.project)}</div><div>${escapeHtml(project.blocked)}</div></div><div class="attention-next">Next: ${escapeHtml(project.next)}</div></div>`).join('') : '<div class="attention-empty">No project report has a recorded blocker right now.</div>';
    }
    function historyItem(report) {
      return `<div class="history-item"><div class="history-time">${escapeHtml(report.updated)}</div><div><span class="history-label">Changed</span><br>${escapeHtml(report.changed)}</div><div><span class="history-label">Next</span><br>${escapeHtml(report.next)}</div></div>`;
    }
    function attachHistory() {
      document.querySelectorAll('details.history').forEach(details => details.addEventListener('toggle', async () => {
        if (!details.open || details.dataset.loaded) return;
        details.dataset.loaded = 'true';
        const target = details.querySelector('.history-loading');
        try {
          const response = await fetch(`/api/projects/${encodeURIComponent(details.dataset.project)}/history`, {cache:'no-store'});
          const data = await response.json();
          target.outerHTML = data.history.length ? `<div class="history-list">${data.history.map(historyItem).join('')}</div>` : '<p class="history-loading">No safe history is available.</p>';
        } catch (_) { target.textContent = 'Could not read local history.'; }
      }));
    }
    async function refresh() {
      try {
        const response = await fetch('/api/projects', {cache:'no-store'});
        const data = await response.json();
        const blockers = data.projects.filter(project => project.has_recorded_blocker).length;
        document.getElementById('summary').textContent = `${data.projects.length} project${data.projects.length === 1 ? '' : 's'} · ${blockers} recorded blocker${blockers === 1 ? '' : 's'} · refreshed ${data.refreshed}`;
        renderAttention(data.projects);
        document.getElementById('projects').innerHTML = data.projects.length ? data.projects.map(card).join('') : '<div class="empty">No valid safe reports yet. Run DogBuild reporting first, or start this server with <code>--demo</code>.</div>';
        attachHistory();
      } catch (_) { document.getElementById('summary').textContent = 'Could not read local reports.'; }
    }
    refresh(); setInterval(refresh, 5000);
  </script>
</body>
</html>"""


def handler_for(reports_dir: Path):
    class ControlCenterHandler(BaseHTTPRequestHandler):
        def log_message(self, format: str, *args) -> None:  # Keep the demo terminal quiet.
            return

        def _write(self, status: HTTPStatus, content_type: str, body: bytes) -> None:
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self) -> None:  # noqa: N802 (required by BaseHTTPRequestHandler)
            path = urlparse(self.path).path
            if path == "/":
                self._write(HTTPStatus.OK, "text/html; charset=utf-8", PAGE.encode("utf-8"))
                return
            if path == "/api/projects":
                payload = {
                    "projects": project_payload(reports_dir),
                    "refreshed": "from local reports",
                }
                self._write(HTTPStatus.OK, "application/json; charset=utf-8", json.dumps(payload).encode("utf-8"))
                return
            match = re.fullmatch(r"/api/projects/([^/]+)/history", path)
            if match:
                project = unquote(match.group(1))
                if not PROJECT_RE.match(project):
                    self._write(HTTPStatus.BAD_REQUEST, "text/plain; charset=utf-8", b"Invalid project\n")
                    return
                payload = {"project": project, "history": load_history(reports_dir, project)}
                self._write(HTTPStatus.OK, "application/json; charset=utf-8", json.dumps(payload).encode("utf-8"))
                return
            self._write(HTTPStatus.NOT_FOUND, "text/plain; charset=utf-8", b"Not found\n")

    return ControlCenterHandler


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Run the local DogBuild Control Center")
    parser.add_argument("--demo", action="store_true", help="use clearly fictional demo reports")
    parser.add_argument("--reports-dir", type=Path, help="read reports from this directory")
    parser.add_argument("--port", type=int, default=8008, help="localhost port (default: 8008)")
    args = parser.parse_args(argv)
    if args.demo and args.reports_dir:
        parser.error("use either --demo or --reports-dir, not both")
    if not 1 <= args.port <= 65535:
        parser.error("--port must be between 1 and 65535")

    reports_dir = (DEMO_REPORTS if args.demo else args.reports_dir or DEFAULT_REPORTS).resolve()
    server = ThreadingHTTPServer(("127.0.0.1", args.port), handler_for(reports_dir))
    print("DogBuild Control Center")
    print("Reports: {}".format(reports_dir))
    print("Open: http://127.0.0.1:{}".format(args.port))
    print("Press Ctrl-C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
