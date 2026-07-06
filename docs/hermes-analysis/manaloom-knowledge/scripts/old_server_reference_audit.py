#!/usr/bin/env python3
"""Audit active ManaLoom surfaces for old server references.

This is a static guardrail. It does not mutate PostgreSQL, Hermes, EasyPanel,
or local env files. Historical reports can keep old evidence; active runtime,
test, agent, runbook, and handoff surfaces must not point work at the old
server.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DOCS_DIR = REPO_ROOT / "docs" / "hermes-analysis"
REPORT_DIR = DOCS_DIR / "master_optimizer_reports"

NEW_SERVER_DOC = DOCS_DIR / "NEW_SERVER_POSTGRES_WORKFLOW_2026-07-06.md"
QUALITY_GATE = REPO_ROOT / "scripts" / "quality_gate.sh"
OLD_SERVER_WRAPPER = REPO_ROOT / "scripts" / "manaloom_old_server_reference_audit.sh"

ACTIVE_DIRECTORIES = (
    REPO_ROOT / "scripts",
    REPO_ROOT / "server" / "bin",
    REPO_ROOT / "server" / "lib",
    REPO_ROOT / "server" / "routes",
    REPO_ROOT / "server" / "test",
    REPO_ROOT / "app" / "lib",
    REPO_ROOT / "app" / "test",
    REPO_ROOT / "app" / "integration_test",
    REPO_ROOT / ".github",
)

ACTIVE_FILES = (
    REPO_ROOT / "docs" / "EASYPANEL_RUNBOOK_MTGIA_2026-03-24.md",
    DOCS_DIR / "README.md",
)

SKIP_DIRECTORIES = {
    ".dart_tool",
    ".git",
    ".idea",
    ".venv",
    "build",
    "coverage",
    "node_modules",
}

TEXT_SUFFIXES = {
    "",
    ".agent.md",
    ".dart",
    ".env",
    ".example",
    ".json",
    ".md",
    ".py",
    ".sh",
    ".txt",
    ".yaml",
    ".yml",
}

CURRENT_SERVER_REQUIRED_SNIPPETS = (
    "evolution-cartinhas.2ta7qx.easypanel.host",
    "137.184.5.11",
    "server/bin/with_new_server_pg.sh",
    "evolution_manaloom-postgres:5432/halder",
    "127.0.0.1:15432/halder",
)

OLD_SERVER_FORBIDDEN_SNIPPETS = (
    "evolution-cartinhas.8ktevp.easypanel.host",
    "8ktevp.easypanel.host",
    "143.198.230.247",
    ".credentials.env",
)

OLD_PORT_FORBIDDEN_PATTERNS = (
    re.compile(r"\bDB_PORT\s*[:=]\s*[\"']?5433[\"']?"),
    re.compile(r"\bPGPORT\s*[:=]\s*[\"']?5433[\"']?"),
    re.compile(r"\bPort:\s*5433\b"),
    re.compile(r":5433\b"),
    re.compile(r"[\"']5433[\"']"),
)

NEW_SERVER_DOC_REQUIRED_SNIPPETS = (
    "Status: `current_operational_target`",
    "evolution-cartinhas.2ta7qx.easypanel.host",
    "server/bin/with_new_server_pg.sh",
    "historical-only quarantine",
    "evolution-cartinhas.8ktevp.easypanel.host",
    "143.198.230.247",
    ".credentials.env",
)


@dataclass(frozen=True)
class Violation:
    path: str
    line: int
    kind: str
    match: str
    text: str

    def as_dict(self) -> dict[str, Any]:
        return {
            "path": self.path,
            "line": self.line,
            "kind": self.kind,
            "match": self.match,
            "text": self.text,
        }


@dataclass(frozen=True)
class Check:
    name: str
    status: str
    detail: str

    def as_dict(self) -> dict[str, str]:
        return {"name": self.name, "status": self.status, "detail": self.detail}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def is_text_file(path: Path) -> bool:
    if not path.is_file():
        return False
    if path.name.startswith(".") and path.suffix == "":
        return True
    return path.suffix in TEXT_SUFFIXES or path.name.endswith(".agent.md")


def iter_active_runtime_files(extra_files: Iterable[Path] = ()) -> list[Path]:
    files: set[Path] = set()
    for directory in ACTIVE_DIRECTORIES:
        if not directory.exists():
            continue
        for path in directory.rglob("*"):
            if any(part in SKIP_DIRECTORIES for part in path.parts):
                continue
            if is_text_file(path):
                files.add(path)
    for path in ACTIVE_FILES:
        if path.exists() and is_text_file(path):
            files.add(path)
    for path in extra_files:
        if path.exists() and is_text_file(path):
            files.add(path)
    return sorted(files)


def scan_file(path: Path) -> list[Violation]:
    violations: list[Violation] = []
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except UnicodeDecodeError:
        return violations

    for line_number, line in enumerate(lines, start=1):
        for snippet in OLD_SERVER_FORBIDDEN_SNIPPETS:
            if snippet in line:
                violations.append(
                    Violation(
                        path=rel(path),
                        line=line_number,
                        kind="old_server_token",
                        match=snippet,
                        text=line.strip(),
                    )
                )
        for pattern in OLD_PORT_FORBIDDEN_PATTERNS:
            match = pattern.search(line)
            if match is not None:
                violations.append(
                    Violation(
                        path=rel(path),
                        line=line_number,
                        kind="old_postgres_port",
                        match=match.group(0),
                        text=line.strip(),
                    )
                )
    return violations


def check_new_server_doc() -> Check:
    if not NEW_SERVER_DOC.exists():
        return Check("docs.new_server_postgres_workflow_exists", "fail", "missing")
    text = NEW_SERVER_DOC.read_text(encoding="utf-8")
    missing = [snippet for snippet in NEW_SERVER_DOC_REQUIRED_SNIPPETS if snippet not in text]
    if missing:
        return Check(
            "docs.new_server_postgres_workflow_quarantines_old_target",
            "fail",
            "missing=" + json.dumps(missing, ensure_ascii=True),
        )
    return Check(
        "docs.new_server_postgres_workflow_quarantines_old_target",
        "pass",
        rel(NEW_SERVER_DOC),
    )


def check_quality_gate_surface() -> Check:
    if not QUALITY_GATE.exists():
        return Check("scripts.quality_gate_exposes_server_target_audit", "fail", "missing")
    text = QUALITY_GATE.read_text(encoding="utf-8")
    required = (
        "run_old_server_reference_audit",
        "server-target",
        "manaloom_old_server_reference_audit.sh",
    )
    missing = [snippet for snippet in required if snippet not in text]
    if missing:
        return Check(
            "scripts.quality_gate_exposes_server_target_audit",
            "fail",
            "missing=" + json.dumps(missing, ensure_ascii=True),
        )
    return Check("scripts.quality_gate_exposes_server_target_audit", "pass", rel(QUALITY_GATE))


def check_wrapper_exists() -> Check:
    if not OLD_SERVER_WRAPPER.exists():
        return Check("scripts.old_server_reference_audit_wrapper_exists", "fail", "missing")
    text = OLD_SERVER_WRAPPER.read_text(encoding="utf-8")
    required = (
        "old_server_reference_audit.py",
        "MANALOOM_OLD_SERVER_AUDIT_OUT_PREFIX",
    )
    missing = [snippet for snippet in required if snippet not in text]
    if missing:
        return Check(
            "scripts.old_server_reference_audit_wrapper_exists",
            "fail",
            "missing=" + json.dumps(missing, ensure_ascii=True),
        )
    return Check("scripts.old_server_reference_audit_wrapper_exists", "pass", rel(OLD_SERVER_WRAPPER))


def check_current_server_target_present() -> Check:
    missing_by_file: dict[str, list[str]] = {}
    for path in (NEW_SERVER_DOC,):
        text = path.read_text(encoding="utf-8") if path.exists() else ""
        missing = [snippet for snippet in CURRENT_SERVER_REQUIRED_SNIPPETS if snippet not in text]
        if missing:
            missing_by_file[rel(path)] = missing
    if missing_by_file:
        return Check(
            "docs.current_server_target_is_documented",
            "fail",
            json.dumps(missing_by_file, ensure_ascii=True, sort_keys=True),
        )
    return Check("docs.current_server_target_is_documented", "pass", rel(NEW_SERVER_DOC))


def build_report(extra_files: Iterable[Path] = ()) -> dict[str, Any]:
    files = iter_active_runtime_files(extra_files)
    violations: list[Violation] = []
    for path in files:
        violations.extend(scan_file(path))

    checks = [
        check_current_server_target_present(),
        check_new_server_doc(),
        check_quality_gate_surface(),
        check_wrapper_exists(),
        Check(
            "active_runtime_files_have_no_old_server_references",
            "pass" if not violations else "fail",
            f"files_scanned={len(files)} violations={len(violations)}",
        ),
    ]

    status_counts: dict[str, int] = {}
    for check in checks:
        status_counts[check.status] = status_counts.get(check.status, 0) + 1

    return {
        "generated_at": utc_now(),
        "status": "pass" if status_counts.get("fail", 0) == 0 else "fail",
        "active_runtime_files_scanned": len(files),
        "summary": {
            "check_count": len(checks),
            "status_counts": status_counts,
            "violation_count": len(violations),
        },
        "checks": [check.as_dict() for check in checks],
        "violations": [violation.as_dict() for violation in violations],
        "mutations_performed": [],
    }


def write_markdown(report: dict[str, Any], path: Path) -> None:
    lines = [
        "# Old Server Reference Audit",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        f"- Summary: `{json.dumps(report['summary'], sort_keys=True)}`",
        f"- Active runtime files scanned: `{report['active_runtime_files_scanned']}`",
        "",
        "| Check | Status | Detail |",
        "| --- | --- | --- |",
    ]
    for check in report["checks"]:
        detail = str(check.get("detail") or "").replace("|", "\\|")
        lines.append(f"| `{check['name']}` | `{check['status']}` | {detail} |")
    if report["violations"]:
        lines.extend(["", "## Violations", "", "| File | Line | Kind | Match | Text |", "| --- | ---: | --- | --- | --- |"])
        for violation in report["violations"]:
            text = violation["text"].replace("|", "\\|")
            lines.append(
                f"| `{violation['path']}` | {violation['line']} | "
                f"`{violation['kind']}` | `{violation['match']}` | {text} |"
            )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "old_server_reference_audit_current",
    )
    parser.add_argument(
        "--extra-file",
        action="append",
        type=Path,
        default=[],
        help="Additional text file to scan, useful for tests.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_report(args.extra_file)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_markdown(report, md_path)
    print(json.dumps({"status": report["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
