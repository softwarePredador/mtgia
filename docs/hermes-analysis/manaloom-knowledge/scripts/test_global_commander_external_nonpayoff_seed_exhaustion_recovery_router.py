#!/usr/bin/env python3
"""Tests for external nonpayoff seed exhaustion recovery routing."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_external_nonpayoff_seed_exhaustion_recovery_router as router


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def miner_payload(*, role_status: str = router.EXHAUSTED_ROLE) -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "fresh_seeded_same_lane_cut_source_count": 0,
            "blocked_recycled_seeded_cut_source_count": 31,
        },
        "role_diagnostics": [
            {
                "target_cut_role": "mana_acceleration",
                "status": role_status,
                "seed_count": 1 if role_status != router.UNSEEDED_ROLE else 0,
                "scanned_same_lane_source_count": 10,
                "fresh_same_lane_cut_source_count": 0,
                "blocked_recycled_cut_source_count": 10,
            }
        ],
    }


def reviewer_payload(review_status: str) -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "miner_source_seed_rows": [
            {
                "target_cut_role": "mana_acceleration",
                "card_name": "Seed Card",
                "miner_source_seed_allowed": True,
            }
        ],
        "review_rows": [
            {
                "target_cut_role": "mana_acceleration",
                "card_name": "Arcane Signet",
                "review_status": review_status,
            }
        ],
    }


def force_payload() -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "selected_db_absent_count": 10,
        }
    }


class GlobalCommanderExternalNonpayoffSeedExhaustionRecoveryRouterTests(unittest.TestCase):
    def test_current_deck_candidate_routes_to_negative_review(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        payload = router.build_report(
            seeded_miner_current_db_report=write_json(root, "miner.json", miner_payload()),
            source_candidate_reviewer_report=write_json(root, "reviewer.json", reviewer_payload(router.CURRENT_DECK_REVIEW)),
            force_access_report=write_json(root, "force.json", force_payload()),
        )

        self.assertEqual(
            payload["status"],
            "external_nonpayoff_seed_exhaustion_recovery_routes_to_current_deck_negative_review",
        )
        self.assertEqual(payload["summary"]["current_deck_negative_review_candidate_count"], 1)
        self.assertEqual(payload["recovery_actions"][0]["action"], "collect_current_deck_negative_review_for_external_nonpayoff_candidates")
        self.assertFalse(payload["candidate_copy_allowed_now"])

    def test_identity_gap_routes_to_identity_resolution_when_no_current_deck_candidate(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        payload = router.build_report(
            seeded_miner_current_db_report=write_json(root, "miner.json", miner_payload()),
            source_candidate_reviewer_report=write_json(root, "reviewer.json", reviewer_payload(router.IDENTITY_REVIEW)),
            force_access_report=write_json(root, "force.json", force_payload()),
        )

        self.assertEqual(payload["status"], "external_nonpayoff_seed_exhaustion_recovery_needs_identity_resolution")
        self.assertEqual(payload["summary"]["identity_resolution_required_count"], 1)
        self.assertEqual(payload["summary"]["next_gate"], "resolve_external_nonpayoff_candidate_identity_before_more_seed_review")
        self.assertFalse(payload["card_level_cut_permission_now"])

    def test_unseeded_role_routes_to_external_source_expansion(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)

        payload = router.build_report(
            seeded_miner_current_db_report=write_json(root, "miner.json", miner_payload(role_status=router.UNSEEDED_ROLE)),
            source_candidate_reviewer_report=write_json(root, "reviewer.json", {"summary": {}, "review_rows": []}),
            force_access_report=write_json(root, "force.json", force_payload()),
        )

        self.assertEqual(payload["status"], "external_nonpayoff_seed_exhaustion_recovery_routes_to_source_expansion")
        self.assertEqual(payload["summary"]["unseeded_role_count"], 1)
        self.assertIn("expand_external_nonpayoff_source_candidate_pool", [row["action"] for row in payload["recovery_actions"]])
        self.assertFalse(payload["battle_gate_allowed_now"])


if __name__ == "__main__":
    unittest.main()
