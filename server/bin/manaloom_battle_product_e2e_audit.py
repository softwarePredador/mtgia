#!/usr/bin/env python3
"""Fail closed when battle rules stop before the app/deckbuilder product path."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


GATE_TOPOLOGY: tuple[dict[str, str], ...] = (
    {
        "id": "ci_dispatcher",
        "path": ".github/workflows/manaloom-guardrails.yml",
        "classification": "canonical_ci_dispatcher",
        "invocation": "dart run melos run battle",
        "scope": "change-triggered battle product verification",
        "external_state": "none",
    },
    {
        "id": "workspace_dispatcher",
        "path": "scripts/quality_gate.sh",
        "classification": "canonical_local_dispatcher",
        "invocation": "./scripts/quality_gate.sh battle",
        "scope": "discoverable local entrypoint for the canonical battle gate",
        "external_state": "none",
    },
    {
        "id": "workspace_alias",
        "path": "melos.yaml",
        "classification": "canonical_workspace_alias",
        "invocation": "dart run melos run battle",
        "scope": "workspace alias for the canonical battle gate",
        "external_state": "none",
    },
    {
        "id": "broad_e2e_suite",
        "path": "scripts/manaloom_e2e_suite.sh",
        "classification": "canonical_broad_e2e_orchestrator",
        "invocation": "./scripts/quality_gate.sh e2e",
        "scope": "app, server, deckbuilder, battle and optional live product layers",
        "external_state": "optional_live_steps_only",
    },
    {
        "id": "battle_product_gate",
        "path": "scripts/manaloom_battle_product_gate.sh",
        "classification": "canonical_battle_product_gate",
        "invocation": "./scripts/manaloom_battle_product_gate.sh",
        "scope": "native, Forge, XMage, Python, Dart and product contract checks",
        "external_state": "none",
    },
    {
        "id": "pinned_xmage_maven_bootstrap",
        "path": "services/xmage-sidecar/bin/bootstrap_pinned_xmage_maven.sh",
        "classification": "ci_dependency_bootstrap",
        "invocation": "services/xmage-sidecar/bin/bootstrap_pinned_xmage_maven.sh",
        "scope": "install pinned XMage modules absent from Maven Central",
        "external_state": "maven_cache_and_ephemeral_clone",
    },
    {
        "id": "runtime_surface_manifest",
        "path": "docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py",
        "classification": "component_manifest",
        "invocation": "python3 battle_runtime_surface_manifest.py --fail-on-unclassified",
        "scope": "battle-related Python ownership and expected gate coverage",
        "external_state": "none",
    },
    {
        "id": "product_static_contract",
        "path": "server/bin/manaloom_battle_product_e2e_audit.py",
        "classification": "component_static_contract_audit",
        "invocation": "python3 server/bin/manaloom_battle_product_e2e_audit.py",
        "scope": "app-to-engine-to-persistence static product contract",
        "external_state": "none",
    },
    {
        "id": "isolated_battle_product_contract",
        "path": "server/test/battle_product_e2e_test.dart",
        "classification": "isolated_mutating_contract",
        "invocation": "scripts/manaloom_battle_product_gate.sh --isolated-e2e",
        "scope": "harness-owned IPv4-loopback API battle persistence and learning evidence",
        "external_state": "unique_temporary_identity_and_battle_rows_with_audited_cleanup",
    },
    {
        "id": "global_battle_closure",
        "path": "scripts/manaloom_global_battle_closure.sh",
        "classification": "operational_not_quality_gate",
        "invocation": "scripts/manaloom_global_battle_closure.sh coverage|battle",
        "scope": "remote coverage closure and resumable external battle queues",
        "external_state": "remote_artifacts_and_checkpoints",
    },
    {
        "id": "deck_runtime_e2e",
        "path": "server/bin/mana_loom_deck_runtime_e2e.dart",
        "classification": "specialized_manual_live",
        "invocation": "dart run bin/mana_loom_deck_runtime_e2e.dart --dry-run|--apply",
        "scope": "Commander deck CRUD and optimization runtime corpus",
        "external_state": "apply_mode_writes_backend",
    },
    {
        "id": "legacy_live_e2e_guard",
        "path": "server/test/legacy_live_e2e_guard.py",
        "classification": "legacy_live_approval_guard",
        "invocation": "imported by retained legacy live E2E scripts",
        "scope": "explicit staging/local URL and shared textual write approval before any request; known production is blocked",
        "external_state": "none",
    },
    {
        "id": "legacy_general_live_e2e",
        "path": "server/test/e2e_general_tests.py",
        "classification": "legacy_manual_live",
        "invocation": "python3 server/test/e2e_general_tests.py --api URL",
        "scope": "broad historical HTTP endpoint coverage",
        "external_state": "approval_guarded_staging_or_local_test_rows",
    },
    {
        "id": "legacy_ml_live_e2e",
        "path": "server/test/e2e_ml_tests.py",
        "classification": "legacy_manual_live",
        "invocation": "python3 server/test/e2e_ml_tests.py --base-url URL",
        "scope": "historical ML and optimizer HTTP coverage",
        "external_state": "approval_guarded_staging_or_local_test_rows",
    },
    {
        "id": "legacy_trade_live_e2e",
        "path": "server/test/e2e_trade_tests.py",
        "classification": "legacy_manual_live",
        "invocation": "python3 server/test/e2e_trade_tests.py --api URL",
        "scope": "historical trade and binder HTTP coverage",
        "external_state": "approval_guarded_staging_or_local_test_rows",
    },
)


RETIRED_LEGACY_SURFACES: tuple[dict[str, str], ...] = (
    {
        "path": "server/test/quick_audit.py",
        "replacement": "scripts/manaloom_e2e_suite.sh",
        "reason": "unreferenced production-mutating duplicate that did not fail its process on assertion failures",
    },
    {
        "path": "server/test/audit.sh",
        "replacement": "scripts/manaloom_e2e_suite.sh",
        "reason": "unreferenced production-mutating curl duplicate without fail-closed assertions",
    },
    {
        "path": "server/test/audit_ai.sh",
        "replacement": "scripts/manaloom_e2e_suite.sh",
        "reason": "unreferenced production-mutating AI curl duplicate without fail-closed assertions",
    },
    {
        "path": "server/test/deep_audit.py",
        "replacement": "scripts/quality_gate.sh deep-ai",
        "reason": "unreferenced artifact reader whose three required input artifacts no longer exist",
    },
)


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


def _check_absent(
    path: str,
    *,
    forbidden_marker: str = "unexpected_path_present",
) -> dict[str, object]:
    target = ROOT / path
    return {
        "path": path,
        "status": "pass" if not target.exists() else "fail",
        "missing": [],
        "forbidden": [forbidden_marker] if target.exists() else [],
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
        _check_absent(
            "server/routes/decks/[id]/battle-replays/[replayId].dart",
            forbidden_marker="rogue_route_path",
        ),
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
                "services/forge-sidecar/test_sidecar.py",
                "test_external_battle_async_runner.py",
                "test_battle_runtime_surface_manifest.py",
                "battle_runtime_surface_manifest.py",
                "services/xmage-sidecar",
                "mvn -q test",
                "MAVEN_REPO_LOCAL",
                "bootstrap_pinned_xmage_maven.sh",
                "xmage_battle_client_test.dart",
                "forge_battle_client_test.dart",
                "lib/ai/xmage_battle_client.dart",
                "lib/ai/forge_battle_client.dart",
                "dart analyze",
                "dart test",
                "--isolated-e2e",
                "dart_frog dev",
                "--hostname 127.0.0.1",
                "BATTLE_E2E_RUN_TOKEN",
                "BATTLE_E2E_DEFER_CLEANUP_TO_HARNESS",
                "mutation_audit.json",
                '"telemetry_deleted": False',
            ),
        ),
        _check(
            "server/test/battle_product_e2e_test.dart",
            contains=(
                "BATTLE_E2E_RUN_TOKEN",
                "BATTLE_E2E_DEFER_CLEANUP_TO_HARNESS",
                "127.0.0.1",
                "_registerUniqueIdentity",
                "Battle Product E2E Candidate $runToken",
            ),
            absent=(
                "test_battle_product_e2e_v1@example.com",
                "_loginOrRegister",
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
        _check(
            ".github/workflows/manaloom-guardrails.yml",
            contains=(
                '- "services/**"',
                "actions/setup-java@v4",
                "services/xmage-sidecar/XMAGE_COMMIT",
                "bootstrap_pinned_xmage_maven.sh",
                "dart run melos run battle",
            ),
        ),
        _check(
            "scripts/quality_gate.sh",
            contains=(
                "run_battle_product_gate()",
                "manaloom_battle_product_gate.sh",
                "battle)",
            ),
        ),
        _check(
            "services/xmage-sidecar/bin/bootstrap_pinned_xmage_maven.sh",
            contains=(
                "XMAGE_COMMIT",
                "PIN_FINGERPRINT",
                ".manaloom-xmage-pin",
                "rev-parse HEAD",
                "-Dmaven.repo.local",
            ),
        ),
        _check(
            "scripts/manaloom_e2e_suite.sh",
            contains=(
                "Canonical battle product gate",
                'quality_gate.sh\\" battle',
                "Battle product isolated mutating E2E",
                "MANALOOM_RUN_MUTATING_BATTLE_PRODUCT_E2E",
                "run_battle_product_e2e",
                "skip_step",
            ),
        ),
        _check(
            "melos.yaml",
            contains=(
                "battle:",
                "./scripts/quality_gate.sh battle",
            ),
        ),
        _check(
            "server/test/e2e_general_tests.py",
            contains=(
                "require_legacy_live_e2e_approval",
                'add_argument("--api", required=True',
            ),
            absent=("DEFAULT_API",),
        ),
        _check(
            "server/test/e2e_trade_tests.py",
            contains=(
                "require_legacy_live_e2e_approval",
                'add_argument("--api", required=True',
            ),
            absent=("DEFAULT_API",),
        ),
        _check(
            "server/test/e2e_ml_tests.py",
            contains=(
                "require_legacy_live_e2e_approval",
                'add_argument("--base-url", required=True',
            ),
            absent=("DEFAULT_BASE_URL",),
        ),
        _check(
            "server/test/legacy_live_e2e_guard.py",
            contains=(
                "MANALOOM_CONFIRM_LIVE_MUTATIONS",
                "I_HAVE_EXPLICIT_APPROVAL",
                "evolution-cartinhas.2ta7qx.easypanel.host",
                "require_legacy_live_e2e_approval",
            ),
        ),
    ]
    checks.extend(_check(surface["path"]) for surface in GATE_TOPOLOGY)
    checks.extend(
        _check_absent(
            surface["path"],
            forbidden_marker="retired_legacy_surface_present",
        )
        for surface in RETIRED_LEGACY_SURFACES
    )
    failed = [check for check in checks if check["status"] != "pass"]
    topology_counts = Counter(
        surface["classification"] for surface in GATE_TOPOLOGY
    )
    return {
        "schema_version": "manaloom_battle_product_e2e_audit_v1",
        "status": "pass" if not failed else "fail",
        "contract": [
            "app_submits_battle",
            "backend_routes_xmage_then_forge_then_reviewed_native",
            "native_requires_verified_rule_provenance",
            "battle_persists_typed_positive_evidence",
            "deck_analysis_consumes_evidence_without_auto_promotion",
            "battle_gate_topology_is_explicit_and_ci_enforced",
        ],
        "summary": {
            "checks": len(checks),
            "passed": len(checks) - len(failed),
            "failed": len(failed),
        },
        "gate_topology": list(GATE_TOPOLOGY),
        "gate_topology_counts": dict(sorted(topology_counts.items())),
        "retired_legacy_surfaces": list(RETIRED_LEGACY_SURFACES),
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
