#!/usr/bin/env python3
from __future__ import annotations

"""Audit known-cards runtime environment alignment.

This guard does not mutate data. It exists to catch operational drift between:
- the intended canonical runtime on `master`;
- the Hermes/docs branch checkout actually executing cron jobs;
- fallback assets such as `known_cards_canonical_snapshot.json`.
"""

import argparse
import importlib.util
import json
import subprocess
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
CANONICAL_PATH = SCRIPT_DIR / "known_cards_canonical_snapshot.json"
GENERATED_PATH = SCRIPT_DIR / "known_cards_generated.json"
APPROVED_MASTER_RUNTIME_WAIVERS: set[str] = set()


def load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def git_value(args: list[str], cwd: Path) -> str | None:
    try:
        completed = subprocess.run(
            ["git", *args],
            cwd=str(cwd),
            check=True,
            capture_output=True,
            text=True,
        )
    except Exception:
        return None
    return completed.stdout.strip() or None


def build_summary(
    *,
    git_branch: str | None,
    git_sha: str | None,
    handcrafted_count: int,
    manual_waiver_count: int,
    manual_waiver_names: list[str] | None,
    canonical_fallback_count: int,
    known_cards_count: int,
    canonical_snapshot_exists: bool,
    generated_exists: bool,
) -> dict[str, Any]:
    findings: list[str] = []
    if handcrafted_count > 0:
        findings.append("legacy_handcrafted_inventory_active")
    waiver_names = sorted(manual_waiver_names or [])
    unexpected_waivers = sorted(
        set(waiver_names) - APPROVED_MASTER_RUNTIME_WAIVERS
    )
    if unexpected_waivers:
        findings.append("manual_runtime_waiver_unapproved")
    if not canonical_snapshot_exists:
        findings.append("canonical_snapshot_missing")
    if not generated_exists:
        findings.append("legacy_generated_snapshot_missing")
    if canonical_snapshot_exists and canonical_fallback_count == 0:
        findings.append("canonical_snapshot_not_loaded")
    if (git_branch or "").endswith("hermes-analysis-docs"):
        findings.append("docs_branch_runtime_requires_triage_against_master")

    if findings:
        status = "PASS_WITH_RISKS"
    else:
        status = "PASS"

    return {
        "status": status,
        "git_branch": git_branch,
        "git_sha": git_sha,
        "handcrafted_count": handcrafted_count,
        "manual_waiver_count": manual_waiver_count,
        "manual_waiver_names": waiver_names,
        "unexpected_manual_waivers": unexpected_waivers,
        "canonical_fallback_count": canonical_fallback_count,
        "known_cards_count": known_cards_count,
        "canonical_snapshot_exists": canonical_snapshot_exists,
        "generated_exists": generated_exists,
        "findings": findings,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    battle = load_module(BATTLE_PATH, "battle_runtime_environment_audit")
    repo_root = SCRIPT_DIR.parents[3]

    summary = build_summary(
        git_branch=git_value(["rev-parse", "--abbrev-ref", "HEAD"], repo_root),
        git_sha=git_value(["rev-parse", "--short", "HEAD"], repo_root),
        handcrafted_count=len(getattr(battle, "HANDCRAFTED_KNOWN_CARDS", [])),
        manual_waiver_count=len(getattr(battle, "MANUAL_RULE_RUNTIME_WAIVERS", [])),
        manual_waiver_names=sorted(
            getattr(battle, "MANUAL_RULE_RUNTIME_WAIVERS", [])
        ),
        canonical_fallback_count=len(
            getattr(battle, "CANONICAL_FALLBACK_KNOWN_CARDS", [])
        ),
        known_cards_count=len(getattr(battle, "KNOWN_CARDS", {})),
        canonical_snapshot_exists=CANONICAL_PATH.exists(),
        generated_exists=GENERATED_PATH.exists(),
    )

    encoded = json.dumps(summary, ensure_ascii=True, indent=2, sort_keys=True)
    if args.report:
        report_path = Path(args.report)
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(encoded + "\n", encoding="utf-8")
    print(encoded)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
