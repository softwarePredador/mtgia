#!/usr/bin/env python3
"""Fail closed when battle rules stop before the app/deckbuilder product path."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _check(
    path: str,
    *,
    contains: tuple[str, ...] = (),
    absent: tuple[str, ...] = (),
) -> dict[str, object]:
    target = ROOT / path
    text = target.read_text(encoding="utf-8") if target.is_file() else ""
    missing = [marker for marker in contains if marker not in text]
    forbidden = [marker for marker in absent if marker in text]
    return {
        "path": path,
        "status": "pass" if target.is_file() and not missing and not forbidden else "fail",
        "missing": missing,
        "forbidden": forbidden,
    }


def _check_absent(path: str) -> dict[str, object]:
    target = ROOT / path
    return {
        "path": path,
        "status": "pass" if not target.exists() else "fail",
        "missing": [],
        "forbidden": ["rogue_route_path"] if target.exists() else [],
    }


def build_report() -> dict[str, object]:
    checks = [
        _check(
            "app/lib/features/battle/services/battle_replay_service.dart",
            contains=("'/ai/simulate'", "'type': 'battle'", "opponent_deck_id"),
        ),
        _check(
            "server/routes/ai/simulate/index.dart",
            contains=(
                "NativeBattleClient",
                "engineConfig.nativeSidecarUrl",
                "'required_rule_cards'",
                "buildBattleLearningEvidence(",
                "_saveSimulation(",
                "battle_simulations",
            ),
            absent=("BattleSimulator(", "manaloom_native_legacy", "experimental_advisory"),
        ),
        _check(
            "server/lib/ai/battle_engine_config.dart",
            contains=("NATIVE_BATTLE_SIDECAR_URL", "native_not_configured"),
        ),
        _check(
            "server/bin/native_battle_sidecar.py",
            contains=(
                "battle_card_rules",
                "verified_native_rule_missing",
                "native_reviewed_rules_execution",
                "required_rule_cards",
                "json_valid(effect_json)",
            ),
        ),
        _check(
            "server/bin/native_battle_worker.py",
            contains=(
                "import battle_analyst_v9 as battle",
                "simulate_game_v8(",
                "native_battle_learning_v1",
                "DECISION_TRACE_HANDLER",
                "forced_access_diagnostic",
                "MANALOOM_BATTLE_MAX_TURNS",
            ),
        ),
        _check(
            "server/routes/decks/[id]/analysis/index.dart",
            contains=(
                "loadDeckBattleLearningEvidence(",
                "'battle_learning_evidence'",
                "battleLearningEvidence: battleLearningEvidence",
            ),
        ),
        _check(
            "server/lib/ai/deck_battle_learning_evidence.dart",
            contains=(
                "battle_simulations",
                "native_reviewed_rules_execution",
                "evidence['natural_sample'] != true",
                "promotion_allowed",
            ),
        ),
        _check(
            "server/lib/battle/battle_replay_read_service.dart",
            contains=(
                "native_reviewed_rules_execution",
                "reviewed_native_rules_execution",
                "native_residual",
            ),
        ),
        _check(
            "server/routes/decks/[id]/battle-replays/[replayId]/index.dart",
            contains=("fetchReplay(", "String replayId", "ownsDeck("),
        ),
        _check_absent("server/routes/decks/[id]/battle-replays/[replayId].dart"),
        _check(
            "scripts/manaloom_deploy_battle_sidecars.sh",
            contains=(
                "NATIVE_BATTLE_SIDECAR_URL",
                "native_reviewed_rules_execution",
                "MANALOOM_NATIVE_BATTLE_SERVICE",
                "manaloom_battle_product_gate.sh",
            ),
        ),
        _check(
            "scripts/manaloom_deploy_ops_image.sh",
            contains=(
                "MANALOOM_NATIVE_BATTLE_HTTP_ENABLED=1",
                "MANALOOM_NATIVE_BATTLE_SYNC_ON_BOOT=1",
                "known_cards_canonical_snapshot.runtime.json",
                "native_reviewed_rules_execution",
                "manaloom_battle_product_gate.sh",
            ),
        ),
        _check(
            "scripts/manaloom_battle_product_gate.sh",
            contains=(
                "manaloom_battle_product_e2e_audit.py",
                "native_battle_sidecar_test",
                "dart analyze",
                "dart test",
            ),
        ),
        _check(
            "docs/hermes-analysis/EXTERNAL_BATTLE_EXECUTION_CONTRACT.md",
            contains=(
                "manaloom_native_reviewed",
                "NATIVE_BATTLE_SIDECAR_URL",
                "native_battle_learning_v1",
                "manaloom_battle_product_gate.sh",
            ),
            absent=("manaloom_native_legacy",),
        ),
    ]
    failed = [check for check in checks if check["status"] != "pass"]
    return {
        "schema_version": "manaloom_battle_product_e2e_audit_v1",
        "status": "pass" if not failed else "fail",
        "contract": [
            "app_submits_battle",
            "backend_routes_xmage_then_forge_then_reviewed_native",
            "native_requires_verified_rule_provenance",
            "battle_persists_typed_positive_evidence",
            "deck_analysis_consumes_evidence_without_auto_promotion",
        ],
        "summary": {
            "checks": len(checks),
            "passed": len(checks) - len(failed),
            "failed": len(failed),
        },
        "checks": checks,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    report = build_report()
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print(json.dumps({"status": report["status"], "summary": report["summary"]}))
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
