#!/usr/bin/env python3
"""Audit retained ManaLoom report data artifacts.

The product truth is PostgreSQL/backend plus executable runtime code. The
`master_optimizer_reports` tree is not a durable data lake. This audit keeps
that boundary explicit by flagging raw report artifacts that are tracked but not
referenced by current scripts/contracts, and by surfacing ignored local
artifacts left on disk.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DOCS_DIR = REPO_ROOT / "docs" / "hermes-analysis"
REPORT_DIR = DOCS_DIR / "master_optimizer_reports"

RAW_REPORT_SUFFIXES = {".json", ".jsonl", ".sql", ".out", ".txt", ".db", ".log", ".tsv", ".err"}

ACTIVE_REFERENCE_ROOTS = (
    DOCS_DIR / "manaloom-knowledge" / "scripts",
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

CURRENT_CONTRACT_FILES = (
    DOCS_DIR / "README.md",
    DOCS_DIR / "MANALOOM_OPERATIONAL_LOOKUP_GUIDE_2026-06-30.md",
    DOCS_DIR / "MANALOOM_FAILURE_MODE_VALIDATION_MATRIX_2026-06-30.md",
    DOCS_DIR / "APP_AI_KNOWLEDGE_BRIDGE_CONTRACT_2026-07-06.md",
    DOCS_DIR / "NEW_SERVER_POSTGRES_WORKFLOW_2026-07-06.md",
    DOCS_DIR / "DATA_FIELD_ALIAS_CONTRACT_2026-06-30.md",
    DOCS_DIR / "BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md",
    DOCS_DIR / "XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md",
    DOCS_DIR / "COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md",
    DOCS_DIR / "MANALOOM_DEEP_AI_DATA_COHERENCE_VALIDATION_2026-07-06.md",
)


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


def git_ls_files(path: Path) -> list[Path]:
    output = subprocess.check_output(
        ["git", "-C", str(REPO_ROOT), "ls-files", str(path.relative_to(REPO_ROOT))],
        text=True,
    )
    return [REPO_ROOT / line for line in output.splitlines() if line.strip()]


def tracked_report_raw_files() -> list[Path]:
    return [
        path
        for path in git_ls_files(REPORT_DIR)
        if path.suffix in RAW_REPORT_SUFFIXES
    ]


def active_reference_files() -> list[Path]:
    files: set[Path] = set()
    for root in ACTIVE_REFERENCE_ROOTS:
        if not root.exists():
            continue
        for path in git_ls_files(root):
            if path.exists() and path.is_file() and not str(path).startswith(str(REPORT_DIR) + "/"):
                files.add(path)
    for path in CURRENT_CONTRACT_FILES:
        if path.exists() and path.is_file():
            files.add(path)
    return sorted(files)


def read_active_reference_text() -> str:
    chunks: list[str] = []
    for path in active_reference_files():
        try:
            chunks.append(path.read_text(encoding="utf-8", errors="ignore"))
        except OSError:
            continue
    return "\n".join(chunks)


def classify_raw_files() -> tuple[list[Path], list[Path]]:
    haystack = read_active_reference_text()
    referenced_tokens = set(
        re.findall(
            r"[\w./-]+\.(?:json|jsonl|sql|out|txt|db|log|tsv|err)",
            haystack,
        )
    )
    referenced_tokens.update(Path(token).name for token in list(referenced_tokens))
    referenced: list[Path] = []
    unreferenced: list[Path] = []
    for path in tracked_report_raw_files():
        if path.name in referenced_tokens or rel(path) in referenced_tokens:
            referenced.append(path)
        else:
            unreferenced.append(path)
    return referenced, unreferenced


def ignored_local_report_files() -> list[Path]:
    if not REPORT_DIR.exists():
        return []
    tracked = {path.resolve() for path in git_ls_files(REPORT_DIR)}
    return sorted(
        path
        for path in REPORT_DIR.rglob("*")
        if path.is_file()
        and path.resolve() not in tracked
        and path.suffix in RAW_REPORT_SUFFIXES.union({".md"})
    )


def byte_size(paths: list[Path]) -> int:
    total = 0
    for path in paths:
        try:
            total += path.stat().st_size
        except OSError:
            continue
    return total


def build_report(*, fail_on_ignored_local: bool) -> dict[str, Any]:
    referenced, unreferenced = classify_raw_files()
    ignored = ignored_local_report_files()
    checks = [
        Check(
            "tracked_raw_report_files_are_referenced_by_current_surfaces",
            "pass" if not unreferenced else "fail",
            f"referenced={len(referenced)} unreferenced={len(unreferenced)}",
        ),
        Check(
            "ignored_local_report_artifacts_absent",
            "pass" if (not fail_on_ignored_local or not ignored) else "fail",
            f"ignored_local_count={len(ignored)} ignored_local_bytes={byte_size(ignored)}",
        ),
    ]
    status_counts: dict[str, int] = {}
    for check in checks:
        status_counts[check.status] = status_counts.get(check.status, 0) + 1
    return {
        "generated_at": utc_now(),
        "status": "pass" if status_counts.get("fail", 0) == 0 else "fail",
        "summary": {
            "check_count": len(checks),
            "status_counts": status_counts,
            "tracked_raw_count": len(referenced) + len(unreferenced),
            "referenced_tracked_raw_count": len(referenced),
            "unreferenced_tracked_raw_count": len(unreferenced),
            "unreferenced_tracked_raw_bytes": byte_size(unreferenced),
            "ignored_local_count": len(ignored),
            "ignored_local_bytes": byte_size(ignored),
        },
        "checks": [check.as_dict() for check in checks],
        "referenced_tracked_raw": [rel(path) for path in referenced],
        "unreferenced_tracked_raw": [rel(path) for path in unreferenced],
        "ignored_local_report_artifacts": [rel(path) for path in ignored],
        "mutations_performed": [],
    }


def write_markdown(report: dict[str, Any], path: Path) -> None:
    lines = [
        "# Report Retention Audit",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        f"- Summary: `{json.dumps(report['summary'], sort_keys=True)}`",
        "",
        "| Check | Status | Detail |",
        "| --- | --- | --- |",
    ]
    for check in report["checks"]:
        detail = str(check.get("detail") or "").replace("|", "\\|")
        lines.append(f"| `{check['name']}` | `{check['status']}` | {detail} |")
    if report["unreferenced_tracked_raw"]:
        lines.extend(["", "## Unreferenced Tracked Raw Files", ""])
        for item in report["unreferenced_tracked_raw"][:200]:
            lines.append(f"- `{item}`")
        if len(report["unreferenced_tracked_raw"]) > 200:
            lines.append(f"- ... {len(report['unreferenced_tracked_raw']) - 200} more")
    if report["ignored_local_report_artifacts"]:
        lines.extend(["", "## Ignored Local Report Artifacts", ""])
        for item in report["ignored_local_report_artifacts"][:200]:
            lines.append(f"- `{item}`")
        if len(report["ignored_local_report_artifacts"]) > 200:
            lines.append(f"- ... {len(report['ignored_local_report_artifacts']) - 200} more")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=Path("/tmp/manaloom_report_retention_audit"),
    )
    parser.add_argument(
        "--fail-on-ignored-local",
        action="store_true",
        help="Fail when ignored local report artifacts are present on disk.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_report(fail_on_ignored_local=args.fail_on_ignored_local)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_markdown(report, md_path)
    print(json.dumps({"status": report["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
