#!/usr/bin/env python3
"""Static fail-closed contract for the Deckbuilder/AI/Learning gate."""

from __future__ import annotations

import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


def source(relative_path: str) -> str:
    return (REPO_ROOT / relative_path).read_text(encoding="utf-8")


class DeckAiLearningGateContractTest(unittest.TestCase):
    def test_gate_is_code_only_by_default_and_never_silently_skips(self) -> None:
        gate = source("scripts/manaloom_deck_ai_learning_gate.sh")

        self.assertIn('PROFILE="${MANALOOM_DECK_AI_GATE_PROFILE:-local}"', gate)
        self.assertIn('write_summary "PASS_CODE_ONLY" 0', gate)
        self.assertIn('write_summary "BLOCKED" 2', gate)
        self.assertIn('write_summary "FAIL" 1', gate)
        self.assertNotIn('write_summary "SKIP"', gate)
        self.assertIn("All other tests passed!", gate)
        self.assertIn("SKIP nao recebe credito de PASS", gate)
        self.assertIn('"network_opened": False', gate)
        self.assertIn('"product_mutations_performed": []', gate)
        self.assertIn('"schema": "manaloom.deck_ai_learning_gate_run.v2"', gate)
        self.assertIn('"start": source_start', gate)
        self.assertIn('"end": source_end', gate)
        self.assertIn('"stable": source_stable', gate)
        self.assertIn('"worktree_digest_sha256": worktree_digest_sha256', gate)
        self.assertIn('"project_logic_source_digest": project_logic_source_digest', gate)
        self.assertIn('"artifact_manifest_sha256": artifact_manifest_sha256', gate)
        self.assertIn('^[0-9a-f]{40}$', gate)
        self.assertIn('^[0-9a-f]{64}$', gate)
        self.assertIn("snapshot-source", gate)
        self.assertIn("verify-source-stable", gate)
        self.assertIn("source.toctou_guard", gate)
        self.assertIn("darwin-sandbox-deny-network", gate)
        self.assertIn("linux-network-namespace", gate)
        self.assertIn("local-step-catalog.json", gate)

        for forbidden_command in (
            "flutter test",
            "flutter analyze",
            "flutter pub",
            "dart pub",
            "manaloom_pg_hermes_sqlite_contract_audit.sh",
            "with_new_server_pg.sh",
        ):
            self.assertNotIn(forbidden_command, gate)

    def test_release_profile_requires_fresh_read_only_receipt_and_credentials(
        self,
    ) -> None:
        gate = source("scripts/manaloom_deck_ai_learning_gate.sh")

        self.assertIn("release-read-only", gate)
        self.assertIn("MANALOOM_NEW_SERVER_ENV", gate)
        self.assertIn("MANALOOM_DECK_AI_RELEASE_RECEIPT", gate)
        self.assertIn("validate-release", gate)
        self.assertIn("deck_ai_learning_gate_policy.json", gate)
        self.assertIn("deck_ai_learning_receipt_validator.py", gate)
        self.assertIn("release.external_receipt_v2", gate)
        self.assertIn("outside temporary roots", gate)
        self.assertNotIn("receipt must contain at least one executed check", gate)

        validator = source(
            "scripts/manaloom_deck_ai_learning_receipt_validator.py"
        )
        self.assertIn("release check catalog mismatch", validator)
        self.assertIn("PG audit semantic check catalog mismatch", validator)
        self.assertIn("source state changed while gate executed", validator)
        self.assertIn("release evidence requires a clean worktree", validator)
        self.assertIn("required migrations are not applied", validator)
        self.assertIn("artifact hash drift", validator)
        self.assertIn("duplicate JSON key", validator)

    def test_canonical_release_receipt_producer_is_network_narrow_and_read_only(
        self,
    ) -> None:
        producer = source(
            "scripts/manaloom_deck_ai_learning_release_receipt.sh"
        )

        self.assertIn('with_new_server_pg.sh" --read-only', producer)
        self.assertIn("manaloom_pg_hermes_sqlite_contract_audit.sh", producer)
        self.assertIn("default_transaction_read_only=on", producer)
        self.assertIn(
            "unset MANALOOM_CONFIRM_LIVE_MUTATIONS MANALOOM_CONFIRM_POSTGRES_WRITES",
            producer,
        )
        self.assertIn("generate_series(38, 58)", producer)
        self.assertIn("verify-source-stable", producer)
        self.assertIn("--require-clean", producer)
        self.assertIn("assemble-release", producer)
        self.assertNotIn("--write-approved", producer)
        self.assertNotIn("curl ", producer)
        self.assertNotIn("wget ", producer)

    def test_quality_gate_dispatch_does_not_require_flutter_for_this_mode(
        self,
    ) -> None:
        quality_gate = source("scripts/quality_gate.sh")

        self.assertIn('if [[ "$MODE" == "deck-ai-learning" ]]', quality_gate)
        self.assertIn("QUALITY_GATE_NEEDS_FLUTTER=0", quality_gate)
        self.assertIn('if [[ "$QUALITY_GATE_NEEDS_FLUTTER" == "1" ]]', quality_gate)
        self.assertIn("run_deck_ai_learning_gate()", quality_gate)
        self.assertIn("deck-ai-learning)", quality_gate)
        self.assertIn('--profile "$DECK_AI_GATE_PROFILE"', quality_gate)

    def test_gate_executes_each_focused_containment_surface_once(self) -> None:
        gate = source("scripts/manaloom_deck_ai_learning_gate.sh")

        required_once = (
            "test/ai_generate_learning_boundary_test.dart",
            "test/deck_learning_event_support_test.dart",
            "test/commander_learned_deck_support_test.dart",
            "test/optimize_cache_support_test.dart",
            "test/optimize_runtime_support_test.dart",
            "test/optimize_learning_pipeline_test.dart",
            "test/commander_reference_read_only_contract_test.dart",
            "test/production_ai_mock_fallback_policy_test.dart",
            "test/ai_generate_performance_support_test.dart",
            "test/source_reachability_audit_test.dart",
            "test/auto_promote_learned_decks_test.py",
            "test/auto_sync_learned_decks_test.py",
            "test/pull_learning_events_schema_test.py",
            "test/deck_ai_learning_gate_contract_test.py",
            "test/deck_ai_learning_receipt_validator_test.py",
            "test/optimizer_loop_tombstone_contract_test.py",
            "test/manaloom_knowledge_import_test.py",
            "test_export_hermes_learned_deck_metadata.py",
            "test_export_hermes_learned_deck_wrapper_parity.py",
            "commander_deckbuilding_flow_research_audit.py",
            "deckbuilding_contract_surface_audit.py",
            "operational_surface_alignment_audit.py",
        )
        # Paths occur twice by design: once in the required-file inventory and
        # once in the command that executes them. Anything else indicates a
        # duplicate execution or an ungoverned implicit dependency.
        for expected in required_once:
            self.assertEqual(gate.count(expected), 2, expected)

    def test_learning_and_promotion_boundaries_are_fail_closed(self) -> None:
        promote = source("server/bin/auto_promote_learned_decks.py")
        sync = source("server/bin/auto_sync_learned_decks.py")
        pull = source("server/bin/pull_learning_events.py")
        generate = source("server/routes/ai/generate/index.dart")
        learning_support = source("server/lib/ai/deck_learning_event_support.dart")
        optimizer_loop = source("server/bin/optimizer_loop.sh")

        for automatic in (promote, sync):
            self.assertIn('"--dry-run"', automatic)
            self.assertIn('"--apply"', automatic)
            self.assertIn("apply_requested", automatic)
            self.assertIn("BLOCKED_DCK_P0_05", automatic)
            self.assertIn("promotion_allowed=false", automatic)

        self.assertIn('USER_CREATED_SOURCE = "user_created"', pull)
        self.assertIn('"learning_status": "quarantined_source"', pull)
        self.assertIn("_backfill_learning_classification(sqlite)", pull)
        self.assertNotIn("logGeneratedDeckForLearning", generate)
        self.assertNotIn("logGeneratedDeckForLearning", learning_support)

        self.assertIn("BLOCKED:", optimizer_loop)
        self.assertIn("historical mutating entrypoint", optimizer_loop)
        self.assertIn("exit 2", optimizer_loop)
        self.assertNotIn("--apply", optimizer_loop)

    def test_optimize_cache_is_sha256_and_tenant_scoped(self) -> None:
        cache = source("server/lib/ai/optimize_cache_support.dart")

        self.assertIn("sha256.convert", cache)
        self.assertIn("optimizeCacheContractVersion = 'v20'", cache)
        self.assertIn("required String userId", cache)
        self.assertIn("required String deckId", cache)
        self.assertIn("required String deckSignature", cache)
        self.assertIn("AND user_id = CAST(@user_id AS uuid)", cache)
        self.assertIn("AND deck_id = CAST(@deck_id AS uuid)", cache)
        self.assertIn("AND deck_signature = @deck_signature", cache)


if __name__ == "__main__":
    unittest.main()
