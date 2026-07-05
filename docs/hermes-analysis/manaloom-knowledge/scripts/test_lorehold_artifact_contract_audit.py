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

    def test_profiled_cut_package_manifest_is_recognized(self) -> None:
        payload = {
            "source": "lorehold_profiled_cut_benchmark_generator",
            "manual_review": "manual.md",
            "prior_package_reports": ["past.json"],
            "packages": [
                {
                    "package_key": "electro_same_lane",
                    "adds": ["Electro, Assaulting Battery"],
                    "cuts": ["Bender's Waterskin"],
                    "family": "ramp",
                    "hypothesis": "same-lane benchmark",
                }
            ],
            "postgres_writes": False,
            "source_db_mutated": False,
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "manifest.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "profiled_cut_package_manifest")
        self.assertEqual(classification.status, "pass")
        self.assertEqual(classification.canonical_summary["valid_package_row_count"], 1)

    def test_prior_package_decision_compact_is_recognized(self) -> None:
        payload = {
            "generated_at": "2026-06-30T00:00:00Z",
            "source": "lorehold_discard_ramp_value_monument_decision_20260630_goal_learning",
            "postgres_writes": False,
            "source_db_mutated": False,
            "baseline_deck_id": 607,
            "packages": [
                {
                    "package_key": "glint_horn_buccaneer_same_lane_benchmark_cut_monument_to_endurance",
                    "family": "discard_ramp_value_benchmark",
                    "adds": ["Glint-Horn Buccaneer"],
                    "cuts": ["Monument to Endurance"],
                    "decision": "reject_regresses_critical_matchup",
                }
            ],
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "prior_package_decision.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "prior_package_decision")
        self.assertEqual(classification.schema_version, "prior_package_decision_compact_v1")
        self.assertEqual(classification.status, "pass")
        self.assertEqual(classification.canonical_summary["valid_package_row_count"], 1)
        self.assertEqual(
            classification.canonical_summary["decision_counts"],
            {"reject_regresses_critical_matchup": 1},
        )

    def test_from_scratch_challenger_artifacts_are_recognized(self) -> None:
        summary_payload = {
            "candidates": [{"candidate_key": "challenger_lorehold_access_density_control_v1"}],
            "corpus_deck_ids": [607, 608],
            "fixed_opponent_deck_id_for_gate": 607,
            "protected_baseline_deck_id": 607,
            "postgres_writes": False,
            "source_db_mutated": False,
            "status": "ready",
        }
        candidate_payload = {
            "battle_gate_command": ["python3", "gate.py"],
            "candidate_key": "challenger_lorehold_access_density_control_v1",
            "final_deck": [{"card_name": "Lorehold, the Historian"}],
            "mode": "from_scratch",
            "protected_baseline_deck_id": 607,
            "postgres_writes": False,
            "source_db_mutated": False,
        }

        with tempfile.TemporaryDirectory() as tmp:
            summary = audit.classify_payload(Path(tmp) / "summary.json", summary_payload)
            candidate = audit.classify_payload(Path(tmp) / "candidate.json", candidate_payload)

        self.assertEqual(summary.artifact_kind, "from_scratch_challenger_summary")
        self.assertEqual(summary.status, "pass")
        self.assertEqual(candidate.artifact_kind, "from_scratch_challenger_candidate")
        self.assertEqual(candidate.status, "pass")

    def test_compact_gate_summary_is_recognized(self) -> None:
        payload = {
            "generated_at": "2026-06-30T00:00:00Z",
            "results": [
                {"deck_key": "deck_607", "games": 4, "wins": 1, "losses": 3, "stalls": 0},
                {
                    "deck_key": "challenger_lorehold_miracle_pressure_conversion_v1",
                    "games": 4,
                    "wins": 0,
                    "losses": 4,
                    "stalls": 0,
                },
            ],
            "source_gate_markdown": "gate.md",
            "status": "compact_gate_summary",
        }

        with tempfile.TemporaryDirectory() as tmp:
            classification = audit.classify_payload(Path(tmp) / "gate_summary.json", payload)

        self.assertEqual(classification.artifact_kind, "compact_gate_summary")
        self.assertEqual(classification.status, "pass")
        self.assertEqual(classification.canonical_summary["result_count"], 2)

    def test_focus_decision_wrapper_is_recognized(self) -> None:
        payload = {
            "generated_at": "2026-06-30T00:00:00Z",
            "packages": [{"package_key": "candidate"}],
            "postgres_writes": False,
            "source_db_mutated": False,
            "source_wrapper": "lorehold_profiled_cut_benchmark_gate_decision",
            "status": "blocked",
            "summary": {"ready_count": 0},
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "decision_wrapper.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "focus_access_decision_wrapper")
        self.assertEqual(classification.status, "pass")

    def test_runtime_gap_subreports_are_recognized(self) -> None:
        examples = [
            (
                "runtime_gap_blocked_coherence",
                {
                    "cards": [],
                    "deck_id": 607,
                    "generated_at": "2026-06-30T00:00:00Z",
                    "scope": "lorehold_variant_only_cards_blocked_by_runtime_rule_gap",
                    "severity_counts": {},
                    "source": "lorehold_variant_gap_miner",
                    "source_deck_ids": [607],
                    "source_miner_summary": {},
                    "total_cards": 0,
                },
            ),
            (
                "runtime_gap_family_subreport",
                {
                    "cards": [],
                    "families": {},
                    "generated_at": "2026-06-30T00:00:00Z",
                    "mutations_performed": False,
                    "source": "xmage_semantic_family_classifier",
                    "status": "pass",
                    "summary": {},
                },
            ),
            (
                "runtime_gap_validity_subreport",
                {
                    "cards": [],
                    "generated_at": "2026-06-30T00:00:00Z",
                    "mutations_performed": False,
                    "source": "xmage_batch_validity_audit",
                    "status": "pass",
                    "summary": {},
                },
            ),
            (
                "runtime_gap_xmage_index_subreport",
                {
                    "cards": [],
                    "generated_at": "2026-06-30T00:00:00Z",
                    "mutations_performed": False,
                    "source": "xmage_local_rule_indexer",
                    "status": "pass",
                    "summary": {},
                    "xmage_root": "/Users/desenvolvimentomobile/Downloads/mage-master",
                },
            ),
        ]

        with tempfile.TemporaryDirectory() as tmp:
            for expected_kind, payload in examples:
                path = Path(tmp) / f"{expected_kind}.json"
                classification = audit.classify_payload(path, payload)
                self.assertEqual(classification.artifact_kind, expected_kind)
                self.assertEqual(classification.status, "pass")

    def test_unblock_readiness_and_package_manifests_are_recognized(self) -> None:
        examples = [
            (
                "hidden_retreat_unblock_readiness",
                {
                    "blocker_chain": [],
                    "env_status": {},
                    "generated_at": "2026-06-30T00:00:00Z",
                    "guardrails": {},
                    "inputs": {},
                    "manifest_extract": {},
                    "postgres_precheck": {},
                    "postgres_writes": False,
                    "source_db_mutated": False,
                    "summary": {},
                },
            ),
            (
                "expanded_package_manifest",
                {
                    "correction_note": "lane corrected",
                    "generated_from": "hand_filter_cut_model",
                    "packages": [],
                    "purpose": "expanded hand-filter queue",
                },
            ),
            (
                "safe_cut_package_manifest",
                {
                    "generated_at": "2026-06-30T00:00:00Z",
                    "packages": [],
                    "postgres_writes": False,
                    "purpose": "safe cut packages",
                    "source_db_mutated": False,
                    "source_ledger": "ledger.json",
                },
            ),
            (
                "from_scratch_shell_failure_synthesis",
                {
                    "generated_at": "2026-06-30T00:00:00Z",
                    "learning_constraints": [],
                    "next_hypothesis_requirements": {},
                    "postgres_writes": False,
                    "shell_gate_rows": [],
                    "source_db_mutated": False,
                    "summary": {},
                },
            ),
            (
                "closing_window_trace_miner",
                {
                    "closing_window_comparisons": [],
                    "generated_at": "2026-06-30T00:00:00Z",
                    "hypothesis_queue": [],
                    "postgres_writes": False,
                    "protected_baseline": "deck_607",
                    "source_db_mutated": False,
                    "summary": {},
                },
            ),
            (
                "trace_targeted_micro_package_model",
                {
                    "blocked_hypotheses": [],
                    "generated_at": "2026-06-30T00:00:00Z",
                    "postgres_writes": False,
                    "protected_anchor_evidence": {},
                    "ready_packages": [],
                    "source_db_mutated": False,
                    "summary": {},
                },
            ),
            (
                "lorehold_current_champion_snapshot",
                {
                    "cards": [],
                    "champion_decision": {},
                    "generated_at": "2026-06-30T00:00:00Z",
                    "postgres_writes": False,
                    "protected_anchors": [],
                    "source_db_mutated": False,
                    "summary": {},
                },
            ),
            (
                "trace_cut_evidence_expansion_queue",
                {
                    "all_cut_slots": [],
                    "generated_at": "2026-06-30T00:00:00Z",
                    "hard_blocked_queue": [],
                    "postgres_writes": False,
                    "reviewable_evidence_gap_queue": [],
                    "source_db_mutated": False,
                    "summary": {},
                },
            ),
            (
                "lorehold_deckbuilding_final_closure",
                {
                    "final_decision": {},
                    "generated_at": "2026-06-30T00:00:00Z",
                    "postgres_writes": False,
                    "source_db_mutated": False,
                    "source_reports": {},
                    "summary": {},
                    "validation": {},
                },
            ),
        ]

        with tempfile.TemporaryDirectory() as tmp:
            for expected_kind, payload in examples:
                path = Path(tmp) / f"{expected_kind}.json"
                classification = audit.classify_payload(path, payload)
                self.assertEqual(classification.artifact_kind, expected_kind)
                self.assertEqual(classification.status, "pass")

    def test_exposure_aware_gate_queue_is_recognized(self) -> None:
        payload = {
            "readiness_report": "runtime_gap_readiness.json",
            "summary": {
                "natural_gate_ready_count": 0,
                "forced_exposure_probe_ready_count": 11,
                "recommended_next_action": (
                    "forced_exposure_diagnostic_only_review_focus_runtime_before_gate"
                ),
                "status_counts": {"forced_exposure_ready": 11},
            },
            "packages": [{"package_key": "probe"}],
            "ready_queue": [{"package_key": "probe"}],
            "postgres_writes": False,
            "source_db_mutated": False,
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "exposure_queue.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "exposure_aware_gate_queue")
        self.assertEqual(classification.status, "pass")
        self.assertEqual(classification.canonical_summary["forced_exposure_probe_ready_count"], 11)

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

    def test_lorehold_topdeck_mana_trace_gap_scout_is_recognized(self) -> None:
        payload = {
            "artifact_type": "lorehold_topdeck_mana_trace_gap_scout",
            "current_baseline": "deck_607",
            "decision": {
                "keep_607_as_protected_baseline": True,
                "candidate_deck_materialization_allowed_now": False,
            },
            "deck_607_mutated": False,
            "external_research_context": [],
            "generated_at": "2026-07-05T00:00:00Z",
            "mana_trace_gap": {"eligible_pair_count": 0},
            "postgres_writes": False,
            "source_db_mutated": False,
            "source_evidence": {},
            "source_reports": {},
            "status": "topdeck_mana_trace_gap_scout_found_unprobed_floor_sensitive_gaps_keep_607",
            "summary": {
                "unprobed_topdeck_gap_count": 1,
                "candidate_deck_materialization_allowed_now": False,
            },
            "trace_gap_rows": [{"card_name": "Hit the Mother Lode"}],
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lorehold_topdeck_mana_trace_gap_scout.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "lorehold_topdeck_mana_trace_gap_scout")
        self.assertEqual(classification.schema_version, "lorehold_topdeck_mana_trace_gap_scout_v1")
        self.assertEqual(classification.status, "pass")
        self.assertFalse(classification.canonical_summary["deck_607_mutated"])

    def test_lorehold_gap_floor_trace_miner_is_recognized(self) -> None:
        payload = {
            "artifact_type": "lorehold_gap_floor_trace_miner",
            "current_baseline": "deck_607",
            "decision": {
                "keep_607_as_protected_baseline": True,
                "candidate_deck_materialization_allowed_now": False,
            },
            "deck_607_mutated": False,
            "floor_trace_rows": [{"target_card": "Hit the Mother Lode"}],
            "generated_at": "2026-07-05T00:00:00Z",
            "postgres_writes": False,
            "source_db_mutated": False,
            "source_evidence": {},
            "source_reports": {},
            "status": "gap_floor_trace_miner_found_floor_evidence_keep_607",
            "summary": {
                "target_with_floor_trace_count": 1,
                "candidate_deck_materialization_allowed_now": False,
            },
            "target_floor_summaries": [{"card_name": "Hit the Mother Lode"}],
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lorehold_gap_floor_trace_miner.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "lorehold_gap_floor_trace_miner")
        self.assertEqual(classification.schema_version, "lorehold_gap_floor_trace_miner_v1")
        self.assertEqual(classification.status, "pass")
        self.assertFalse(classification.canonical_summary["deck_607_mutated"])

    def test_lorehold_topdeck_sidecar_cut_model_planner_is_recognized(self) -> None:
        payload = {
            "artifact_type": "lorehold_topdeck_sidecar_cut_model_planner",
            "current_baseline": "deck_607",
            "cut_model_targets": [{"add_card": "Penance", "candidate_cut_probes": []}],
            "decision": {
                "keep_607_as_protected_baseline": True,
                "candidate_deck_materialization_allowed_now": False,
            },
            "deck_607_mutated": False,
            "generated_at": "2026-07-05T00:00:00Z",
            "postgres_writes": False,
            "source_db_mutated": False,
            "source_evidence": {
                "floor_trace_cut_blockers": {
                    "hit the mother lode": {"card_name": "Hit the Mother Lode"}
                }
            },
            "source_reports": {},
            "status": "topdeck_sidecar_cut_model_planner_review_probes_ready_no_safe_cut_keep_607",
            "summary": {
                "floor_trace_cut_blocker_count": 1,
                "candidate_deck_materialization_allowed_now": False,
            },
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lorehold_topdeck_sidecar_cut_model_planner.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(
            classification.artifact_kind,
            "lorehold_topdeck_sidecar_cut_model_planner",
        )
        self.assertEqual(
            classification.schema_version,
            "lorehold_topdeck_sidecar_cut_model_planner_v1",
        )
        self.assertEqual(classification.status, "pass")
        self.assertFalse(classification.canonical_summary["deck_607_mutated"])

    def test_lorehold_non_floor_probe_evidence_closure_is_recognized(self) -> None:
        payload = {
            "artifact_type": "lorehold_non_floor_probe_evidence_closure",
            "current_baseline": "deck_607",
            "closure_rows": [
                {
                    "add_card": "Penance",
                    "cut_card": "Artist's Talent",
                    "closure_class": "closed_exposed_topdeck_role",
                }
            ],
            "decision": {
                "keep_607_as_protected_baseline": True,
                "candidate_deck_materialization_allowed_now": False,
            },
            "deck_607_mutated": False,
            "generated_at": "2026-07-05T00:00:00Z",
            "postgres_writes": False,
            "source_db_mutated": False,
            "source_evidence": {"probe_evidence_summary": {}},
            "source_reports": {},
            "status": "non_floor_probe_evidence_closure_closed_no_matrix_rows_keep_607",
            "summary": {
                "non_floor_probe_count": 1,
                "non_floor_safe_cut_ready_count": 0,
                "non_floor_matrix_candidate_row_eligible_count": 0,
                "candidate_deck_materialization_allowed_now": False,
            },
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lorehold_non_floor_probe_evidence_closure.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(
            classification.artifact_kind,
            "lorehold_non_floor_probe_evidence_closure",
        )
        self.assertEqual(
            classification.schema_version,
            "lorehold_non_floor_probe_evidence_closure_v1",
        )
        self.assertEqual(classification.status, "pass")
        self.assertFalse(classification.canonical_summary["deck_607_mutated"])

    def test_lorehold_post_named_frontier_next_evidence_router_is_recognized(self) -> None:
        payload = {
            "artifact_type": "lorehold_post_named_frontier_next_evidence_router",
            "current_baseline": "deck_607",
            "decision": {
                "keep_607_as_protected_baseline": True,
                "deck_action_allowed": False,
            },
            "deck_607_mutated": False,
            "evidence_routes": [
                {
                    "route_key": "topdeck_new_cut_evidence_scout",
                    "learning_allowed_now": True,
                    "execution_allowed_now": False,
                }
            ],
            "generated_at": "2026-07-05T00:00:00Z",
            "postgres_writes": False,
            "source_db_mutated": False,
            "source_evidence": {"named_frontier_summary": {}},
            "source_reports": {},
            "status": "post_named_frontier_next_evidence_router_learning_only_keep_607",
            "summary": {
                "selected_next_route": "topdeck_new_cut_evidence_scout",
                "deck_action_allowed_now": False,
                "natural_battle_gate_allowed_now": False,
            },
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lorehold_post_named_frontier_next_evidence_router.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(
            classification.artifact_kind,
            "lorehold_post_named_frontier_next_evidence_router",
        )
        self.assertEqual(
            classification.schema_version,
            "lorehold_post_named_frontier_next_evidence_router_v1",
        )
        self.assertEqual(classification.status, "pass")
        self.assertFalse(classification.canonical_summary["deck_607_mutated"])

    def test_lorehold_topdeck_new_cut_evidence_scout_is_recognized(self) -> None:
        payload = {
            "artifact_type": "lorehold_topdeck_new_cut_evidence_scout",
            "blocked_internal_near_misses": [],
            "current_baseline": "deck_607",
            "decision": {
                "keep_607_as_protected_baseline": True,
                "allow_deck_mutation_now": False,
                "allow_natural_battle_gate_now": False,
            },
            "deck_607_mutated": False,
            "deckbuilding_priority_rules": {
                "land_quantity_floor": 34,
                "ramp_quantity_floor": 15,
            },
            "evidence_requests": [
                {
                    "request_key": "dragon_rage_channeler_new_nonanchor_same_lane_cut_evidence",
                    "execution_allowed_now": False,
                }
            ],
            "external_research_context": [],
            "generated_at": "2026-07-05T00:00:00Z",
            "hard_blocked_same_lane_slots": [],
            "internal_evidence_targets": [],
            "postgres_writes": False,
            "source_db_mutated": False,
            "source_evidence": {"nonanchor_model_summary": {}},
            "source_reports": {},
            "status": "topdeck_new_cut_evidence_scout_learning_targets_only_keep_607",
            "summary": {
                "primary_target": "Dragon's Rage Channeler",
                "safe_cut_ready_count": 0,
                "natural_battle_gate_allowed_now": False,
            },
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lorehold_topdeck_new_cut_evidence_scout.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(
            classification.artifact_kind,
            "lorehold_topdeck_new_cut_evidence_scout",
        )
        self.assertEqual(
            classification.schema_version,
            "lorehold_topdeck_new_cut_evidence_scout_v1",
        )
        self.assertEqual(classification.status, "pass")
        self.assertFalse(classification.canonical_summary["deck_607_mutated"])

    def test_governed_lorehold_learning_artifact_is_recognized(self) -> None:
        payload = {
            "artifact_type": "lorehold_deckbuilding_value_model",
            "all_card_values": [{"card_name": "Esper Sentinel"}],
            "decision": {"promotion_allowed": False},
            "deck_607_mutated": False,
            "generated_at": "2026-07-05T00:00:00Z",
            "postgres_writes": False,
            "source_db_mutated": False,
            "status": "value_model_ready_keep_607",
            "summary": {"candidate_deck_materialization_allowed_now": False},
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lorehold_deckbuilding_value_model.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "lorehold_deckbuilding_value_model")
        self.assertEqual(
            classification.schema_version,
            "lorehold_deckbuilding_value_model_governed_v1",
        )
        self.assertEqual(classification.status, "pass")
        self.assertEqual(classification.canonical_summary["learning_domain"], "card_value")

    def test_historical_lorehold_mutation_artifact_is_warn_not_unknown(self) -> None:
        payload = {
            "artifact_type": "lorehold_role_tag_repair_synthesis",
            "after_repair": {},
            "before_repair": {},
            "decision": {"status": "role_tag_repair_applied"},
            "deck_id": 607,
            "generated_at": "2026-07-04T00:00:00Z",
            "postgres_writes": False,
            "source_db_mutated": True,
            "status": "role_tag_repair_applied",
            "summary": {"changed_count": 3},
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lorehold_role_tag_repair_synthesis.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "lorehold_role_tag_repair_synthesis")
        self.assertEqual(classification.status, "warn")
        self.assertTrue(classification.canonical_summary["source_db_mutated"])

    def test_legacy_mana_vault_evidence_synthesis_is_recognized(self) -> None:
        payload = {
            "adds": ["Mana Vault"],
            "cuts": ["Arcane Signet"],
            "decision_rules": ["reject if candidate regresses natural gate"],
            "generated_at": "2026-07-04T00:00:00Z",
            "observations": [{"status": "negative_gate"}],
            "package_key": "mana_vault",
            "postgres_writes": False,
            "source_db_mutated": False,
            "summary": {"decision": "reject_current_pair"},
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lorehold_mana_vault_evidence_synthesis.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "lorehold_mana_vault_evidence_synthesis")
        self.assertEqual(classification.status, "pass")
        self.assertEqual(classification.canonical_summary["observation_count"], 1)

    def test_legacy_ramp_package_evaluation_is_recognized(self) -> None:
        payload = {
            "generated_at": "2026-07-04T00:00:00Z",
            "packages": [{"package_key": "basalt_monolith"}],
            "source_db": "knowledge.db",
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lorehold_ramp_package_evaluation_20260704.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(classification.artifact_kind, "lorehold_ramp_package_evaluation")
        self.assertEqual(classification.status, "pass")
        self.assertEqual(classification.canonical_summary["package_count"], 1)

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

    def test_topdeck_access_first_sidecar_contract_is_recognized(self) -> None:
        payload = {
            "artifact_type": "lorehold_topdeck_access_first_sidecar_shell_contract",
            "postgres_writes": False,
            "source_db_mutated": False,
            "deck_607_mutated": False,
            "summary": {
                "decision_status": (
                    "topdeck_access_first_sidecar_contract_written_no_matrix_rows_keep_607"
                ),
                "contract_key": "topdeck_access_first_sidecar_shell_contract",
                "candidate_deck_materialization_allowed_now": False,
            },
            "contract": {"contract_key": "topdeck_access_first_sidecar_shell_contract"},
            "decision": {"keep_607_as_protected_baseline": True},
            "source_evidence": {"input_health": {"missing_inputs": []}},
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "topdeck_contract.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(
            classification.artifact_kind,
            "lorehold_topdeck_access_first_sidecar_shell_contract",
        )
        self.assertEqual(classification.status, "pass")
        self.assertFalse(classification.canonical_summary["deck_607_mutated"])

    def test_named_same_lane_cut_frontier_is_recognized(self) -> None:
        payload = {
            "artifact_type": "lorehold_named_same_lane_cut_frontier",
            "postgres_writes": False,
            "source_db_mutated": False,
            "deck_607_mutated": False,
            "summary": {
                "decision_status": "named_same_lane_cut_frontier_closed_no_safe_cut_keep_607",
                "structure_matrix_contract_allowed_now": False,
            },
            "topdeck_frontier": [{"add_card": "Dragon's Rage Channeler"}],
            "mana_frontier": {"frontier_status": "mana_route_closed_by_exact_decisions"},
            "decision": {"keep_607_as_protected_baseline": True},
            "source_evidence": {"probe_evidence_summary": {}},
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "named_cut_frontier.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(
            classification.artifact_kind,
            "lorehold_named_same_lane_cut_frontier",
        )
        self.assertEqual(classification.status, "pass")
        self.assertFalse(classification.canonical_summary["deck_607_mutated"])

    def test_brain_seed_safe_cut_unlock_audit_is_recognized(self) -> None:
        payload = {
            "artifact_type": "lorehold_brain_seed_safe_cut_unlock_audit",
            "postgres_writes": False,
            "source_db_mutated": False,
            "deck_607_mutated": False,
            "summary": {
                "decision_status": (
                    "brain_seed_safe_cut_unlock_audit_closed_no_unlockable_cut_keep_607"
                ),
                "unlockable_now_count": 0,
            },
            "unlock_rows": [{"card_name": "Molecule Man"}],
            "external_deckbuilding_lessons": [{"source": "EDHREC Lorehold commander page"}],
            "source_summaries": {"safe_cut_gap": {}},
            "decision": {"keep_607_as_protected_baseline": True},
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "brain_cut_unlock.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(
            classification.artifact_kind,
            "lorehold_brain_seed_safe_cut_unlock_audit",
        )
        self.assertEqual(classification.status, "pass")
        self.assertFalse(classification.canonical_summary["deck_607_mutated"])

    def test_brain_cut_slot_trace_miner_is_recognized(self) -> None:
        payload = {
            "artifact_type": "lorehold_brain_cut_slot_trace_miner",
            "postgres_writes": False,
            "source_db_mutated": False,
            "deck_607_mutated": False,
            "summary": {
                "decision_status": "brain_cut_slot_trace_miner_found_floor_evidence_keep_607",
                "target_with_floor_trace_count": 1,
            },
            "target_floor_summaries": [{"card_name": "Molecule Man"}],
            "floor_trace_rows": [{"target_card": "Molecule Man"}],
            "source_evidence": {"brain_safe_cut_gap_summary": {}},
            "decision": {"keep_607_as_protected_baseline": True},
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "brain_cut_slot_trace.json"
            classification = audit.classify_payload(path, payload)

        self.assertEqual(
            classification.artifact_kind,
            "lorehold_brain_cut_slot_trace_miner",
        )
        self.assertEqual(classification.status, "pass")
        self.assertFalse(classification.canonical_summary["deck_607_mutated"])

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
