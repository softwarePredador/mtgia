#!/usr/bin/env python3
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import xmage_effective_queue_report as queue_report


class XMageEffectiveQueueReportTests(unittest.TestCase):
    def test_effective_lane_moves_packaged_pg_candidates_out_of_rebuild_queue(self) -> None:
        proposal_report = {
            "summary": {"proposal_status_counts": {"batch_pg_candidate_after_precheck": 2}},
            "proposals": [
                {
                    "card_name": "Packaged Card",
                    "proposal_status": "batch_pg_candidate_after_precheck",
                    "family_id": "draw_engine",
                    "effect": "draw_engine",
                    "battle_model_scope": "draw_scope_v1",
                },
                {
                    "card_name": "Fresh Card",
                    "proposal_status": "batch_pg_candidate_after_precheck",
                    "family_id": "draw_engine",
                    "effect": "draw_engine",
                    "battle_model_scope": "draw_scope_v1",
                },
                {
                    "card_name": "Partial Card",
                    "proposal_status": "partial_batch_pg_candidate_preserve_shadow_rows_after_precheck",
                    "family_id": "burn_engine",
                    "effect": "damage_each_opponent",
                    "battle_model_scope": "controlled_creature_enters_damage_each_opponent_v1",
                },
                {
                    "card_name": "Runtime Card",
                    "proposal_status": "runtime_family_implementation_required",
                    "family_id": "token_maker",
                    "effect": "token_maker",
                    "battle_model_scope": "token_scope_v1",
                },
                {
                    "card_name": "Split Card",
                    "proposal_status": "split_family_scope_review_required",
                    "family_id": "targeted_interaction",
                    "effect": "direct_damage",
                    "battle_model_scope": "damage_scope_v1",
                },
                {
                    "card_name": "Manual Card",
                    "proposal_status": "mapper_metadata_or_test_scenario_required",
                    "family_id": "manual_model",
                    "effect": "external_reference_required_manual_model",
                    "battle_model_scope": "manual_scope_v1",
                },
                {
                    "card_name": "Missing Card",
                    "proposal_status": "blocked_missing_xmage_source",
                    "family_id": "manual_model",
                    "effect": "external_reference_required_manual_model",
                    "battle_model_scope": "manual_scope_v1",
                },
            ],
        }
        with tempfile.TemporaryDirectory() as tmp_dir:
            report_dir = Path(tmp_dir)
            manifest_path = report_dir / "pg999_test_manifest.json"
            manifest_path.write_text(
                json.dumps(
                    {
                        "deploy_id": "PG999",
                        "slug": "test_package",
                        "status": "prepared_read_only_pending_apply_approval",
                        "generated_at": "2026-06-24T14:00:00+00:00",
                        "selected_card_names": ["Packaged Card"],
                        "selected_count": 1,
                        "family_counts": {"draw_engine": 1},
                    }
                ),
                encoding="utf-8",
            )
            report = queue_report.build_report(proposal_report, report_dir=report_dir)

        lane_counts = report["effective_queue"]["lane_counts"]
        self.assertEqual(lane_counts[queue_report.PACKAGE_PREPARED_LANE], 1)
        self.assertEqual(lane_counts[queue_report.PACKAGE_READY_LANE], 2)
        self.assertEqual(lane_counts[queue_report.RUNTIME_LANE], 1)
        self.assertEqual(lane_counts[queue_report.SPLIT_SCOPE_LANE], 1)
        self.assertEqual(lane_counts[queue_report.MANUAL_LANE], 1)
        self.assertEqual(lane_counts[queue_report.BLOCKED_LANE], 1)

        prepared_packages = report["effective_queue"]["prepared_packages"]
        self.assertEqual(prepared_packages[0]["deploy_id"], "PG999")
        self.assertEqual(prepared_packages[0]["cards_in_current_queue"], ["Packaged Card"])

    def test_scope_rollups_group_same_family_effect_scope(self) -> None:
        proposal_report = {
            "summary": {},
            "proposals": [
                {
                    "card_name": "Card A",
                    "proposal_status": "split_family_scope_review_required",
                    "family_id": "targeted_interaction",
                    "effect": "direct_damage",
                    "battle_model_scope": "damage_scope_v1",
                },
                {
                    "card_name": "Card B",
                    "proposal_status": "split_family_scope_review_required",
                    "family_id": "targeted_interaction",
                    "effect": "direct_damage",
                    "battle_model_scope": "damage_scope_v1",
                },
                {
                    "card_name": "Card C",
                    "proposal_status": "split_family_scope_review_required",
                    "family_id": "targeted_interaction",
                    "effect": "draw_cards",
                    "battle_model_scope": "draw_scope_v1",
                },
            ],
        }
        with tempfile.TemporaryDirectory() as tmp_dir:
            report = queue_report.build_report(proposal_report, report_dir=Path(tmp_dir))

        rollups = report["effective_queue"]["lanes"][queue_report.SPLIT_SCOPE_LANE]["scope_rollups"]
        self.assertEqual(rollups[0]["battle_model_scope"], "damage_scope_v1")
        self.assertEqual(rollups[0]["count"], 2)
        self.assertEqual(rollups[0]["sample_cards"], ["Card A", "Card B"])


if __name__ == "__main__":
    unittest.main()
