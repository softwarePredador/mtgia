#!/usr/bin/env python3
"""Tests for the learned-deck partner identity dry-run planner."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_PATH = REPO_ROOT / "server/bin/plan_learned_deck_partner_identity_backfill.py"


def load_module():
    spec = importlib.util.spec_from_file_location(
        "plan_learned_deck_partner_identity_backfill",
        SCRIPT_PATH,
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to load {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


planner = load_module()


class PartnerIdentityBackfillPlannerTest(unittest.TestCase):
    def learned_deck(self, source_ref: str, metadata: dict, model: dict):
        return planner.audit_module.LearnedDeckAudit(
            commander_name="K-9, Mark I",
            deck_name="K-9, Mark I + The Fourteenth Doctor",
            source_system="hermes",
            source_ref=source_ref,
            row_id="00000000-0000-0000-0000-000000000116",
            card_count_declared=100,
            metadata=metadata,
            parsed_cards=[],
            resolved_cards=[],
            derived_metadata={
                "partner_identity_candidates": [
                    {
                        "name": "The Fourteenth Doctor",
                        "color_identity": ["G", "R", "U", "W"],
                        "reason": "deck_name_commander_component",
                    }
                ],
                "commander_identity_model": model,
            },
        )

    def test_build_plan_emits_dry_run_metadata_patch_and_scoped_sql(self) -> None:
        model = {
            "status": "combined_identity_inferred",
            "source": "deck_name_commander_component",
            "requires_first_class_persistence": True,
            "primary_commander_name": "K-9, Mark I",
            "declared_deck_name": "K-9, Mark I + The Fourteenth Doctor",
            "base_color_identity": ["U"],
            "combined_color_identity": ["G", "R", "U", "W"],
            "identity_components": [
                {
                    "name": "The Fourteenth Doctor",
                    "color_identity": ["G", "R", "U", "W"],
                    "source": "deck_name_commander_component",
                }
            ],
        }

        plan = planner.build_plan(
            [self.learned_deck("learned_deck:116", {"total_lands": 0}, model)]
        )

        self.assertEqual(plan["status"], "PASS")
        self.assertEqual(plan["mode"], "dry_run")
        self.assertFalse(plan["db_mutations"])
        self.assertFalse(plan["apply_supported"])
        self.assertTrue(plan["apply_requires_explicit_approval"])
        self.assertEqual(plan["planned_row_count"], 1)
        row = plan["planned_rows"][0]
        self.assertEqual(row["source_ref"], "learned_deck:116")
        self.assertEqual(row["inference_source"], "deck_name_commander_component")
        self.assertEqual(row["combined_color_identity"], ["G", "R", "U", "W"])
        self.assertEqual(
            row["metadata_patch"]["partner_identity_backfill"]["source"],
            planner.SOURCE,
        )
        self.assertIn("UPDATE commander_learned_decks", row["planned_sql"])
        self.assertIn(
            "WHERE id = '00000000-0000-0000-0000-000000000116'::uuid "
            "AND source_ref = 'learned_deck:116';",
            row["planned_sql"],
        )
        self.assertIn('"total_lands":0', row["rollback_sql"])
        self.assertIn("source_ref = 'learned_deck:116'", row["rollback_sql"])

    def test_build_plan_skips_single_identity_and_already_persisted_model(self) -> None:
        single_model = {
            "status": "single_commander_identity",
            "requires_first_class_persistence": False,
        }
        combined_model = {
            "status": "combined_identity_inferred",
            "source": "partner_text",
            "requires_first_class_persistence": True,
            "combined_color_identity": ["B", "U"],
            "identity_components": [],
        }

        plan = planner.build_plan(
            [
                self.learned_deck("learned_deck:1", {}, single_model),
                self.learned_deck(
                    "learned_deck:2",
                    {"commander_identity_model": combined_model},
                    combined_model,
                ),
            ]
        )

        self.assertEqual(plan["planned_row_count"], 0)
        self.assertEqual(plan["planned_rows"], [])


if __name__ == "__main__":
    unittest.main()
