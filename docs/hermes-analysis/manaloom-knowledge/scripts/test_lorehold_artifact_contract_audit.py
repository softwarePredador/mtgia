#!/usr/bin/env python3
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import lorehold_artifact_contract_audit as audit


class LoreholdArtifactContractAuditTests(unittest.TestCase):
    def test_current_strategy_matrix_schema_normalizes_decks(self) -> None:
        payload = {
            "ranked_deck_keys": ["deck_607", "deck_615", "deck_614"],
            "decks": [
                {"deck_key": "deck_607", "strategy_score": 141.2, "battle_rule_ready_ratio": 1.0},
                {"deck_key": "deck_615", "strategy_score": 134.8, "battle_rule_ready_ratio": 0.988},
                {"deck_key": "deck_614", "strategy_score": 131.7, "battle_rule_ready_ratio": 1.0},
            ],
        }

        normalized = audit.normalize_strategy_matrix(payload)

        self.assertEqual(normalized["schema_version"], "strategy_matrix_current_v1")
        self.assertEqual(normalized["protected_baseline_rank"], 1)
        self.assertEqual(normalized["live_challenger_ranks"]["deck_615"], 2)
        self.assertEqual(normalized["missing_required_decks"], [])

    def test_legacy_ranked_decks_schema_is_classified_not_silent_current(self) -> None:
        payload = {
            "ranked_deck_keys": ["deck_607", "deck_614", "deck_615"],
            "ranked_decks": [
                {"deck_key": "deck_607"},
                {"deck_key": "deck_614"},
                {"deck_key": "deck_615"},
            ],
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "legacy.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "strategy_matrix")
        self.assertEqual(classification.schema_version, "strategy_matrix_legacy_ranked_decks_v0")
        self.assertEqual(classification.status, "pass")

    def test_candidate_strategy_matrix_can_be_partial_without_blocking_contract(self) -> None:
        payload = {
            "ranked_deck_keys": ["candidate_607_test", "deck_607"],
            "decks": [
                {"deck_key": "candidate_607_test", "strategy_score": 141.1},
                {"deck_key": "deck_607", "strategy_score": 141.0},
            ],
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lorehold_variant_strategy_matrix_candidate.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "strategy_matrix")
        self.assertEqual(classification.status, "pass")
        self.assertEqual(classification.detail, "candidate matrix shape")
        self.assertIn("deck_614", classification.canonical_summary["missing_required_decks"])

    def test_equal_battle_gate_is_not_confused_with_package_gate(self) -> None:
        payload = {
            "status": "ready",
            "games_per_opponent": 3,
            "opponents": ["Winota"],
            "results": [
                {
                    "deck_key": "deck_607",
                    "games": 3,
                    "wins": 2,
                    "losses": 1,
                    "telemetry": {
                        "strategic_games": {
                            "miracle_cast": {"games": 2},
                            "topdeck_manipulation_activated": {"games": 1},
                        },
                        "focus_card_access_summary": {"Mana Vault": {"accessed_games": 1}},
                    },
                }
            ],
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "gate.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "equal_battle_gate")
        self.assertEqual(classification.canonical_summary["result_count"], 1)
        self.assertTrue(classification.canonical_summary["contains_baseline"])

    def test_package_gate_is_classified_separately_from_equal_battle_gate(self) -> None:
        payload = {
            "games_per_opponent": 3,
            "packages": [{"package_key": "mana_vault"}],
            "package_status_counts": {"ready": 1},
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "package.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "package_gate")
        self.assertEqual(classification.canonical_summary["package_count"], 1)

    def test_equal_battle_gate_checkpoint_is_recognized(self) -> None:
        payload = {
            "status": "ready",
            "stem": "lorehold_equal_battle_gate_smoke_game_checkpoint",
            "completed_games": 1,
            "total_games": 1,
            "events": [{"deck_key": "deck_607", "result": "win"}],
            "latest": {"deck_key": "deck_607", "result": "win"},
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "checkpoint.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "equal_battle_gate_checkpoint")
        self.assertEqual(classification.status, "pass")

    def test_promotion_gate_decision_audit_is_recognized(self) -> None:
        payload = {
            "gate_paths": ["gate.json"],
            "decision": {"status": "keep_protected_baseline"},
            "deck_aggregates": {"deck_607": {"wins": 1}},
            "candidate_assessments": [{"deck_key": "deck_614", "status": "do_not_promote"}],
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "promotion.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "promotion_gate_decision_audit")
        self.assertEqual(classification.status, "pass")

    def test_cut_methodology_reaudit_payload_is_recognized(self) -> None:
        payload = {
            "candidate_report": "candidate.json",
            "validation_report": "validation.json",
            "pairs": [],
            "metric_contract": [],
            "decision": {"ready_for_real_deck_change": False},
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "cut_methodology.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "cut_methodology_reaudit")
        self.assertEqual(classification.status, "pass")

    def test_molecule_scarlet_validation_payload_is_recognized(self) -> None:
        payload = {
            "natural": {},
            "forced_opening_diagnostic": {},
            "structural_matrix": {},
            "decision": {},
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "molecule_scarlet.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "molecule_scarlet_validation")
        self.assertEqual(classification.status, "pass")

    def test_normalize_promotion_decision_extracts_ready_state(self) -> None:
        payload = {
            "decision": {
                "status": "promote_challenger",
                "protected_baseline": "deck_607",
                "candidate_keys": ["candidate_custom"],
                "promoted_deck_keys": ["candidate_custom"],
                "ready_for_real_deck_change": True,
                "summary": "Promotion allowed for candidate_custom.",
            }
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "promotion.json"
            normalized = audit.normalize_promotion_decision(path, payload)

        self.assertTrue(normalized["ready_for_real_deck_change"])
        self.assertEqual(normalized["promoted_deck_keys"], ["candidate_custom"])
        self.assertEqual(normalized["protected_baseline"], "deck_607")

    def test_commander_learned_deck_import_payload_is_recognized(self) -> None:
        payload = {
            "source_system": "manaloom_candidate_gate",
            "source_ref": "lorehold_candidate_607_v615_mana_engine_v1",
            "commander_name": "Lorehold, the Historian",
            "card_list": "1 Lorehold, the Historian\n1 Sol Ring",
            "card_count": 100,
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "learned_import.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "commander_learned_deck_import")
        self.assertEqual(classification.status, "pass")

    def test_unknown_schema_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "unknown.json"
            classification = audit.classify_payload(path, {"unexpected": True})

        self.assertEqual(classification.artifact_kind, "unknown")
        self.assertEqual(classification.status, "fail")

    def test_current_workspace_artifact_contract_passes(self) -> None:
        report = audit.build_report()
        self.assertEqual(report["status"], "pass")
        self.assertEqual(report["summary"]["unknown_or_invalid_count"], 0)
        self.assertTrue(report["continuation_gate"]["can_run_equal_battle_gate"])
        self.assertFalse(report["continuation_gate"]["ready_for_real_deck_change"])


if __name__ == "__main__":
    unittest.main()
