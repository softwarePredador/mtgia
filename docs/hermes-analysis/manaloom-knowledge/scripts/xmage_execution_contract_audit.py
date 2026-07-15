#!/usr/bin/env python3
"""Audit XMage primary, Forge secondary, and explicit native fallback."""

from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[4]
SIDECAR = REPO_ROOT / "services/xmage-sidecar"
FORGE_SIDECAR = REPO_ROOT / "services/forge-sidecar"
SERVER = REPO_ROOT / "server"
CONTRACT = REPO_ROOT / "docs/hermes-analysis/EXTERNAL_BATTLE_EXECUTION_CONTRACT.md"
CLOSURE = REPO_ROOT / "docs/hermes-analysis/GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md"
RULE_SYNC = REPO_ROOT / "docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py"
XMAGE_PIN = "34d81ea4995ce15d7e1a788dc6d2a3595d35bcec"
FORGE_PIN = "a62915f500c2411484689294659c6bb84ea215f8"


@dataclass(frozen=True)
class Check:
    name: str
    status: str
    detail: str


def source_check(name: str, path: Path, required: list[str]) -> Check:
    if not path.exists():
        return Check(name, "fail", f"missing={path.relative_to(REPO_ROOT)}")
    text = path.read_text(encoding="utf-8")
    missing = [marker for marker in required if marker not in text]
    if missing:
        return Check(name, "fail", f"missing_markers={missing}")
    return Check(name, "pass", str(path.relative_to(REPO_ROOT)))


def source_absence_check(name: str, path: Path, forbidden: list[str]) -> Check:
    if not path.exists():
        return Check(name, "fail", f"missing={path.relative_to(REPO_ROOT)}")
    text = path.read_text(encoding="utf-8")
    present = [marker for marker in forbidden if marker in text]
    if present:
        return Check(name, "fail", f"forbidden_markers={present}")
    return Check(name, "pass", str(path.relative_to(REPO_ROOT)))


def build_report() -> dict[str, object]:
    pin_file = SIDECAR / "XMAGE_COMMIT"
    pin_value = pin_file.read_text(encoding="utf-8").strip() if pin_file.exists() else ""
    forge_pin_file = FORGE_SIDECAR / "FORGE_COMMIT"
    forge_pin_value = (
        forge_pin_file.read_text(encoding="utf-8").strip()
        if forge_pin_file.exists()
        else ""
    )
    checks = [
        Check(
            "xmage.pin",
            "pass" if pin_value == XMAGE_PIN else "fail",
            f"expected={XMAGE_PIN} actual={pin_value or 'missing'}",
        ),
        source_check(
            "sidecar.http_contract",
            SIDECAR / "src/main/java/com/manaloom/xmage/SidecarMain.java",
            [
                XMAGE_PIN,
                'createContext("/cards/coverage"',
                'createContext("/coverage"',
                'createContext("/simulate"',
                '"xmage_coverage_incomplete"',
                "send(exchange, 422",
                "send(exchange, 504",
                "battleService.warmUp()",
                'body.put("catalog_ready", true)',
                'body.put("indexed_names", battleService.catalogSize())',
                "MAX_REQUEST_BYTES = 8 * 1024 * 1024",
                'body.put("restart_required", true)',
                'result.put("sidecar_process_id", PROCESS_ID)',
                "simulation.get(timeoutMs + HARD_TIMEOUT_GRACE_MS",
                "simulation.cancel(true)",
                "System.exit(70)",
            ],
        ),
        source_check(
            "sidecar.strict_resolution",
            SIDECAR / "src/main/java/com/manaloom/xmage/XmageBattleService.java",
            [
                "UnsupportedCardsException",
                "CardRepository.instance.getNames()",
                "availableCardNames.contains(name)",
                "unresolvedCards(deckKey)",
                "throw new UnsupportedCardsException(missing)",
                'result.put("unsupported_cards", unsupported)',
                '"XMage completed with "',
                '"engine_random_seed_not_event_replay"',
                '"best_effort_visible_state_lower_bound"',
                'learningContract.put("absence_proves_nonuse", false)',
                "connectionUsername",
                "if (!timedOut)",
            ],
        ),
        source_check(
            "sidecar.replay_contract",
            SIDECAR / "src/main/java/com/manaloom/xmage/ReplayNormalizer.java",
            [
                'playerState.put("hand_size"',
                'playerState.put("library_size"',
                'event.put("card_name"',
                'result.put("tapped"',
                'snapshot.put("combat"',
                '"stack_entry"',
                '"attacker_declared"',
                '"counter_change"',
                "StackAbilityView",
                'result.put("source_card_name"',
            ],
        ),
        source_check(
            "sidecar.reproducible_image",
            SIDECAR / "Dockerfile",
            [
                f"ARG XMAGE_COMMIT={XMAGE_PIN}",
                'git checkout "$XMAGE_COMMIT"',
                'test "$(git rev-parse HEAD)" = "$XMAGE_COMMIT"',
                "sqlite-jdbc",
                "mage-server.zip",
            ],
        ),
        source_check(
            "server.strict_client",
            SERVER / "lib/ai/xmage_battle_client.dart",
            [
                "class XmageCoverageIncomplete",
                "class XmageServiceException",
                "response.statusCode == 422",
                "xmage_coverage_incomplete",
            ],
        ),
        Check(
            "forge.pin",
            "pass" if forge_pin_value == FORGE_PIN else "fail",
            f"expected={FORGE_PIN} actual={forge_pin_value or 'missing'}",
        ),
        source_check(
            "forge.strict_sidecar",
            FORGE_SIDECAR / "sidecar.py",
            [
                "class CoverageIncomplete",
                '"forge_coverage_incomplete"',
                "UNSUPPORTED_CARD",
                "GAME_RESULT_WIN",
                "Forge returned no completed game result",
                "Forge completed with {errors} engine errors",
                "run_isolated_process",
                "PROCESS_TIMEOUT_GRACE_SECONDS = 5",
                "timeout=(timeout_ms / 1000) + PROCESS_TIMEOUT_GRACE_SECONDS",
                "except (BrokenPipeError, ConnectionResetError)",
                "start_new_session=True",
                "os.killpg(process.pid, signal.SIGKILL)",
                "SIMULATION_LOCK",
                '"/cards/coverage"',
                '"/coverage"',
                '"/simulate"',
                "MAX_REQUEST_BYTES = 8 * 1024 * 1024",
                '"learning_contract"',
                '"best_effort_engine_log_lower_bound"',
                '"absence_proves_nonuse": False',
            ],
        ),
        source_check(
            "forge.reproducible_image",
            FORGE_SIDECAR / "Dockerfile",
            [
                f"ARG FORGE_COMMIT={FORGE_PIN}",
                'git checkout --detach "${FORGE_COMMIT}"',
                'test "$(git rev-parse HEAD)" = "${FORGE_COMMIT}"',
                "SeededForgeMain.java",
                "libxtst6",
                "xvfb-run -a java",
            ],
        ),
        source_check(
            "forge.seeded_bootstrap",
            FORGE_SIDECAR / "SeededForgeMain.java",
            [
                "MyRandom.setRandom",
                "GuiBase.setInterface(new GuiDesktop())",
                "SimulateMatch.simulate(args)",
                "error.printStackTrace(System.err)",
            ],
        ),
        source_check(
            "server.strict_forge_client",
            SERVER / "lib/ai/forge_battle_client.dart",
            [
                "class ForgeCoverageIncomplete",
                "class ForgeServiceException",
                "response.statusCode == 422",
                "forge_coverage_incomplete",
            ],
        ),
        source_check(
            "server.environment_contract",
            SERVER / ".env.example",
            [
                "BATTLE_ENGINE=auto",
                "XMAGE_SIDECAR_URL=http://xmage-sidecar:8080",
                "FORGE_SIDECAR_URL=http://forge-sidecar:8080",
            ],
        ),
        source_check(
            "deployment.coordinated_sidecars",
            REPO_ROOT / "scripts/manaloom_deploy_battle_sidecars.sh",
            [
                "HEAD must match origin/master before sidecar deploy",
                "services.app.createService",
                "services.app.updateSourceImage",
                "wait_for_sidecar_health()",
                'wait_for_sidecar_health "${PROJECT}_${XMAGE_SERVICE}" "$XMAGE_SERVICE"',
                'wait_for_sidecar_health "${PROJECT}_${FORGE_SERVICE}" "$FORGE_SERVICE"',
                '"$XMAGE_SERVICE" catalog_ready',
                "http://$service_alias:8080/health",
                "upsert_env \"$backend_env\" BATTLE_ENGINE auto",
                "upsert_env \"$backend_env\" DB_HOST \"$DB_HOST\"",
                "docker service update",
                "--update-order stop-first",
                "--rollback-order stop-first",
                "running_image=",
                "update_state=",
                "MANALOOM_XMAGE_MEMORY_LIMIT_MB:-4096",
                "MANALOOM_FORGE_MEMORY_LIMIT_MB:-2560",
            ],
        ),
        source_check(
            "deployment.backend_sha_pinned_task",
            REPO_ROOT / "scripts/manaloom_deploy_backend_image.sh",
            [
                "HEAD local nao esta alinhado com origin/master",
                "--update-order stop-first",
                "--rollback-order stop-first",
                "--detach=true",
                "running_image=",
                "update_state=",
                "deploy convergiu com imagem mutavel ou SHA divergente",
            ],
        ),
        source_check(
            "deployment.current_ops_runtime",
            REPO_ROOT / "scripts/manaloom_deploy_ops_image.sh",
            [
                "HEAD must match origin/master before ops deploy",
                "server/Dockerfile.manaloom-ops",
                "docs/hermes-analysis/manaloom-knowledge",
                "evolution_manaloom-ops",
                "--update-order stop-first",
                "oracle_hash = COALESCE(NULLIF(EXCLUDED.oracle_hash, ''), card_battle_rules.oracle_hash)",
                "backfill_trusted_oracle_hashes",
            ],
        ),
        source_check(
            "postgres.trusted_hash_preservation",
            RULE_SYNC,
            [
                "oracle_hash = COALESCE(NULLIF(EXCLUDED.oracle_hash, ''), card_battle_rules.oracle_hash)",
                "def backfill_trusted_oracle_hashes",
                "backfilled = backfill_trusted_oracle_hashes(cur)",
                "COALESCE(NULLIF(br.oracle_hash, ''), md5(c.oracle_text)) AS oracle_hash",
            ],
        ),
        source_check(
            "ops.pg_hermes_contract_preflight",
            SERVER / "bin/master_optimizer_preflight.sh",
            [
                "pg_hermes_sqlite_contract_audit.py",
                "--sqlite-db \"$SQLITE_DB\"",
                "pg_contract_report=",
            ],
        ),
        source_check(
            "pg.oracle_hash_drift_guard",
            REPO_ROOT
            / "docs/hermes-analysis/manaloom-knowledge/scripts/pg_hermes_sqlite_contract_audit.py",
            [
                "pg_integrity.battle_rules_oracle_hash_current",
                "verified_executable_rules_stale_oracle_hash",
                "pg_sqlite_parity.battle_rule_oracle_hashes",
                "oracle_hash_drift_rows",
            ],
        ),
        source_check(
            "sqlite.priority_safe_hash_backfill",
            REPO_ROOT / "docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py",
            [
                "if incoming_priority < current_priority:",
                "oracle_hash=COALESCE(",
                "NULLIF(oracle_hash, ''),",
                "NULLIF(?, '')",
            ],
        ),
        source_check(
            "sqlite.stale_review_shadow_cleanup",
            RULE_SYNC,
            [
                "def cleanup_stale_local_priority_shadows",
                "if key is None or key in reviewed_keys:",
                "SOURCE_PRIORITY.get(current_source, 0) <= incoming_priority",
                "changed += cleanup_stale_local_priority_shadows(",
            ],
        ),
        source_check(
            "server.engine_configuration",
            SERVER / "lib/ai/battle_engine_config.dart",
            [
                "environment['BATTLE_ENGINE'] ?? 'auto'",
                "XMAGE_SIDECAR_URL is required for BATTLE_ENGINE=$mode",
                "FORGE_SIDECAR_URL is required for BATTLE_ENGINE=$mode",
                "mode == 'native'",
            ],
        ),
        source_check(
            "server.engine_router",
            SERVER / "routes/ai/simulate/index.dart",
            [
                "BattleEngineConfig.fromEnvironment",
                "_engineConfigurationFailure",
                "canonical_rules_execution",
                "canonical_rules_execution_secondary",
                "xmage_coverage_incomplete",
                "forge_coverage_incomplete",
                "manaloom_native_legacy",
                "return _externalEngineFailure(",
                "_publicBattleDefaultTimeoutMs = 40000",
                "_publicBattleMaximumTimeoutMs = 40000",
                "_externalClientGraceMs = 8000",
                "upstreamStatusCode == HttpStatus.gatewayTimeout",
                "'${engine}_timeout'",
                "winner_deck_id",
                "turns_played",
                "_simulationMetrics",
                "buildBattleLearningEvidence(result)",
            ],
        ),
        source_check(
            "server.positive_battle_evidence",
            SERVER / "lib/ai/battle_learning_evidence_support.dart",
            [
                "battle_positive_evidence_v1",
                "external_battle_learning_v1",
                "absence_proves_nonuse",
                "positive_exposure_ready",
                "natural_same_lane_exposure",
                "comparison_input_ready",
                "swap_superiority_proven",
                "promotion_allowed",
            ],
        ),
        source_check(
            "coverage.global_closure",
            REPO_ROOT
            / "docs/hermes-analysis/manaloom-knowledge/scripts/external_card_coverage_closure.py",
            [
                "external_card_coverage_closure_v1",
                'ENGINE_ORDER = ("xmage", "forge", "native")',
                "identity_reconciliation_is_not_coverage_until_runtime_uses_it",
                "residual_semantic_family_counts",
                '"promotion_allowed": False',
            ],
        ),
        source_check(
            "coverage.source_catalog_reconciliation",
            REPO_ROOT
            / "docs/hermes-analysis/manaloom-knowledge/scripts/xmage_source_catalog_reconciliation.py",
            [
                "xmage_source_catalog_reconciliation_v1",
                "local_source_candidate_not_executable",
                "runtime_catalog_confirmation_required",
                "forge_catalog_fallback",
            ],
        ),
        source_check(
            "battle.resumable_async_runner",
            REPO_ROOT
            / "docs/hermes-analysis/manaloom-knowledge/scripts/external_battle_async_runner.py",
            [
                "external_battle_async_registry_v1",
                "external_battle_async_checkpoint_v1",
                "external_battle_comparison_gate_v1",
                "restart_required",
                "sidecar_process_id",
                "comparison_input_ready",
                "swap_superiority_proven",
                "promotion_allowed",
                ".json.gz",
                "registry_hash",
            ],
        ),
        source_check(
            "operations.single_global_closure_entrypoint",
            REPO_ROOT / "scripts/manaloom_global_battle_closure.sh",
            [
                "external_card_coverage_closure.py",
                "xmage_source_catalog_reconciliation.py",
                "external_battle_async_runner.py",
                "easypanel-evolution",
                "rm -rf '$REMOTE_DIR'",
                "global_residual.json",
                "source_catalog_residual.json",
            ],
        ),
        source_absence_check(
            "server.no_silent_configuration_fallback",
            SERVER / "routes/ai/simulate/index.dart",
            ["forge_not_configured", "xmage_sidecar_not_configured"],
        ),
        source_check(
            "server.replay_provenance",
            SERVER / "lib/battle/battle_replay_read_service.dart",
            [
                "isCanonicalRulesExecution",
                "canonical_rules_execution",
                "canonical_rules_execution_secondary",
                "rules_engine_priority",
                "canonical_legality_source",
                "strategy_or_swap_proof",
                "event_learning_grade",
                "event_stream_completeness",
                "absence_proves_nonuse",
                "seed_semantics",
                "named_draw_identity_available",
            ],
        ),
        source_check(
            "tests.server_engine_configuration",
            SERVER / "test/battle_engine_config_test.dart",
            [
                "defaults to auto and requires the primary XMage sidecar",
                "auto requires Forge instead of silently skipping the secondary lane",
                "native is the only mode that does not require a sidecar",
            ],
        ),
        source_check(
            "tests.sidecar",
            SIDECAR / "src/test/java/com/manaloom/xmage/XmageBattleServiceTest.java",
            [
                "coverageReportsUnsupportedCardsWithoutDroppingThem",
                "cardCoverageSupportsCatalogBatchesWithoutDeckShape",
                "simulationTimeoutUsesTheSameBoundsAsTheBattleService",
                "replayEventsExposeVisibleCardActivityWithoutInventingHiddenDraws",
                'abilityEntry.get("source_card_name")',
            ],
        ),
        source_check(
            "tests.server",
            SERVER / "test/xmage_battle_client_test.dart",
            [
                "exposes unsupported cards",
                "does not reinterpret sidecar failures",
                "classifies a client deadline as gateway timeout",
            ],
        ),
        source_check(
            "tests.forge",
            FORGE_SIDECAR / "test_sidecar.py",
            [
                "test_parse_requires_real_game_result",
                "test_parse_completed_game_and_card_use",
                "test_global_corpus_payload_limit_and_process_identity",
            ],
        ),
        source_check(
            "tests.server_forge",
            SERVER / "test/forge_battle_client_test.dart",
            [
                "exposes unsupported cards",
                "does not reinterpret Forge process failures",
            ],
        ),
        source_check(
            "execution.contract",
            CONTRACT,
            [
                "BATTLE_ENGINE=auto",
                "XMAGE_SIDECAR_URL",
                "FORGE_SIDECAR_URL",
                "33,120",
                "1,211",
                "zero residual rows in `conventional_magic_rules`",
                "does not create `card_battle_rules` rows",
                "manaloom_deploy_ops_image.sh",
                "best-effort visible-state lower bound",
                "absence_proves_nonuse=false",
                "GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md",
                "battle_positive_evidence_v1",
            ],
        ),
        source_check(
            "execution.global_closure_runbook",
            CLOSURE,
            [
                "scripts/manaloom_global_battle_closure.sh coverage",
                "external_card_coverage_closure_v1",
                "xmage_source_catalog_reconciliation_v1",
                "external_battle_async_registry_v1",
                "external_battle_async_checkpoint_v1",
                "battle_positive_evidence_v1",
                "promotion_allowed=false",
                "33,120",
                "1,211",
                "zero conventional-rules cards",
            ],
        ),
    ]
    failed = sum(check.status == "fail" for check in checks)
    return {
        "status": "pass" if failed == 0 else "fail",
        "summary": {"checks": len(checks), "passed": len(checks) - failed, "failed": failed},
        "checks": [asdict(check) for check in checks],
        "mutations_performed": [],
    }


def render_markdown(report: dict[str, object]) -> str:
    lines = [
        "# External Battle Execution Contract Audit",
        "",
        f"- Status: `{report['status']}`",
        f"- Summary: `{json.dumps(report['summary'], sort_keys=True)}`",
        "",
        "| Check | Status | Detail |",
        "| --- | --- | --- |",
    ]
    for check in report["checks"]:
        detail = str(check["detail"]).replace("|", "\\|")
        lines.append(f"| `{check['name']}` | `{check['status']}` | {detail} |")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-prefix", required=True)
    args = parser.parse_args()
    report = build_report()
    prefix = Path(args.output_prefix)
    prefix.parent.mkdir(parents=True, exist_ok=True)
    prefix.with_suffix(".json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    prefix.with_suffix(".md").write_text(render_markdown(report), encoding="utf-8")
    print(f"status={report['status']}")
    print(f"summary={json.dumps(report['summary'], sort_keys=True)}")
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
