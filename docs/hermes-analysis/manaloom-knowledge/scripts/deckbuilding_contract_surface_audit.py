#!/usr/bin/env python3
"""Audit active Commander deckbuilding surfaces against the frozen contract."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

CONTRACT_DOC = REPO_ROOT / "docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"
SUPPORT_FILE = REPO_ROOT / "server/lib/ai/commander_deckbuilding_contract_support.dart"
GENERATE_ROUTE = REPO_ROOT / "server/routes/ai/generate/index.dart"
SUPPORT_TEST = REPO_ROOT / "server/test/commander_deckbuilding_contract_support_test.dart"
VARIANT_MATRIX = SCRIPT_DIR / "lorehold_variant_strategy_matrix.py"
VARIANT_GATE = SCRIPT_DIR / "lorehold_variant_battle_gate.py"
README = REPO_ROOT / "docs/hermes-analysis/README.md"

CONTRACT_MATRIX_JSON = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.json"
)
CONTRACT_MATRIX_MD = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.md"
)

REQUIRED_FOCUS_CARDS = {
    "Aetherflux Reservoir",
    "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
    "Mana Vault",
    "Molecule Man",
    "Sensei's Divining Top",
    "Scroll Rack",
}

HISTORICAL_BLOCKED_SURFACES = {
    SCRIPT_DIR / "build_optimized_deck.py": "status=historical_disabled",
    SCRIPT_DIR / "universal_optimizer.py": "legacy_deprecated_not_authorized_for_handoff",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    return str(path.relative_to(REPO_ROOT))


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def check_contains(path: Path, patterns: list[str]) -> dict[str, Any]:
    text = read(path)
    missing = [pattern for pattern in patterns if pattern not in text]
    return {
        "path": rel(path),
        "exists": path.exists(),
        "status": "pass" if path.exists() and not missing else "fail",
        "missing": missing,
    }


def build_audit() -> dict[str, Any]:
    checks: list[dict[str, Any]] = []
    checks.append(
        check_contains(
            CONTRACT_DOC,
            [
                "Status: `frozen_operating_contract`",
                "Source Hierarchy",
                "Lorehold Promotion Gate",
            ],
        )
    )
    checks.append(
        check_contains(
            SUPPORT_FILE,
            [
                "commanderDeckbuildingContractVersion",
                "buildCommanderDeckbuildingContractDiagnostics",
                "ready_for_battle_gate",
            ],
        )
    )
    checks.append(
        check_contains(
            GENERATE_ROUTE,
            [
                "commander_deckbuilding_contract_support.dart",
                "'deckbuilding_contract': deckbuildingContractDiagnostics",
            ],
        )
    )
    checks.append(
        check_contains(
            SUPPORT_TEST,
            [
                "ready_for_battle_gate",
                "reference_lanes_missing",
            ],
        )
    )
    checks.append(
        check_contains(
            VARIANT_MATRIX,
            ["lorehold_variant_strategy_matrix_20260629_deckbuilding_contract"],
        )
    )
    checks.append(
        check_contains(
            VARIANT_GATE,
            [
                "lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.json",
                *sorted(REQUIRED_FOCUS_CARDS),
            ],
        )
    )
    checks.append(
        check_contains(
            README,
            [
                "COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md",
                "deckbuilding_contract_surface_audit.py",
            ],
        )
    )
    checks.append(
        {
            "path": rel(CONTRACT_MATRIX_JSON),
            "exists": CONTRACT_MATRIX_JSON.exists(),
            "status": "pass" if CONTRACT_MATRIX_JSON.exists() else "fail",
            "missing": [] if CONTRACT_MATRIX_JSON.exists() else ["matrix_json"],
        }
    )
    checks.append(
        {
            "path": rel(CONTRACT_MATRIX_MD),
            "exists": CONTRACT_MATRIX_MD.exists(),
            "status": "pass" if CONTRACT_MATRIX_MD.exists() else "fail",
            "missing": [] if CONTRACT_MATRIX_MD.exists() else ["matrix_md"],
        }
    )

    historical = []
    for path, marker in HISTORICAL_BLOCKED_SURFACES.items():
        text = read(path)
        historical.append(
            {
                "path": rel(path),
                "exists": path.exists(),
                "marker": marker,
                "status": "pass" if path.exists() and marker in text else "fail",
            }
        )

    failures = [check for check in checks if check["status"] != "pass"]
    failures.extend(row for row in historical if row["status"] != "pass")
    return {
        "generated_at": utc_now(),
        "status": "pass" if not failures else "fail",
        "contract": rel(CONTRACT_DOC),
        "active_surfaces": checks,
        "historical_blocked_surfaces": historical,
        "failures": failures,
    }


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    lines = [
        "# Deckbuilding Contract Surface Audit",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Contract: `{payload['contract']}`",
        "",
        "## Active Surfaces",
        "",
        "| Status | Path | Missing |",
        "| --- | --- | --- |",
    ]
    for row in payload["active_surfaces"]:
        missing = ", ".join(row.get("missing") or [])
        lines.append(f"| {row['status']} | `{row['path']}` | {missing} |")
    lines.extend(["", "## Historical Blocked Surfaces", "", "| Status | Path | Marker |", "| --- | --- | --- |"])
    for row in payload["historical_blocked_surfaces"]:
        lines.append(f"| {row['status']} | `{row['path']}` | `{row['marker']}` |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "deckbuilding_contract_surface_audit_20260629",
    )
    args = parser.parse_args()
    payload = build_audit()
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    write_markdown(payload, md_path)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if payload["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
