#!/usr/bin/env python3
"""Compatibility audit for legacy contamination guardrails.

The active implementation lives in `workspace_contract_drift_audit.py`. This
wrapper keeps the documented command stable and makes the failure mode explicit
instead of leaving a missing-script gap in the operating contract.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import workspace_contract_drift_audit as drift


REPORT_DIR = drift.REPORT_DIR


def build_report() -> dict[str, Any]:
    report = drift.build_report()
    return {
        **report,
        "audit_name": "legacy_contamination_audit",
        "delegates_to": "workspace_contract_drift_audit.py",
        "guardrail_scope": [
            "stale SQLite path contamination",
            "hardcoded PostgreSQL fallback contamination",
            "PG -> Hermes -> SQLite sync sequence drift",
            "unsafe one-to-many card table joins",
            "active operational file existence",
        ],
    }


def markdown(report: dict[str, Any]) -> str:
    lines = [
        "# Legacy Contamination Audit",
        "",
        f"- Status: `{report.get('status')}`",
        f"- Generated at: `{report.get('generated_at')}`",
        f"- Delegates to: `{report.get('delegates_to')}`",
        "",
        "## Summary",
        "",
        f"`{json.dumps(report.get('summary'), sort_keys=True)}`",
        "",
        "## Non-Pass Checks",
        "",
    ]
    non_pass = [check for check in report.get("checks", []) if check.get("status") != "pass"]
    if not non_pass:
        lines.append("- none")
    else:
        for check in non_pass:
            lines.append(
                f"- `{check.get('status')}` `{check.get('name')}`: {check.get('detail')}"
            )
    return "\n".join(lines).rstrip() + "\n"


def write_report(report: dict[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = Path(f"{out_prefix}.json")
    md_path = Path(f"{out_prefix}.md")
    json_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(markdown(report), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-prefix")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_report()
    out_prefix = Path(args.out_prefix or REPORT_DIR / "legacy_contamination_audit_current")
    json_path, md_path = write_report(report, out_prefix)
    print(json.dumps({"status": report["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if report["status"] == "pass" else 2


if __name__ == "__main__":
    raise SystemExit(main())
