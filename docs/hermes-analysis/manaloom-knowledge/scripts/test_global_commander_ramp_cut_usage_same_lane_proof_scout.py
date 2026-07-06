#!/usr/bin/env python3
"""Tests for ramp cut usage and same-lane proof scout."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_ramp_cut_usage_same_lane_proof_scout as scout


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def ramp_policy_payload() -> dict[str, object]:
    return {
        "pool_policy_rows": [
            {
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
                "role": "removal",
                "policy_cut_rows": [
                    {
                        "card_name": "Arcane Signet",
                        "cut_pressure_ready": True,
                        "roles": ["ramp"],
                        "matching_excess_roles": ["ramp"],
                        "policy_bucket": "ramp_only_excess_cut_pressure",
                    },
                    {
                        "card_name": "Basalt Monolith",
                        "cut_pressure_ready": True,
                        "roles": ["ramp"],
                        "matching_excess_roles": ["ramp"],
                        "policy_bucket": "ramp_only_excess_cut_pressure",
                    },
                ],
                "pair_rows": [
                    {"add": "Feed the Swarm", "cut": "Arcane Signet"},
                    {"add": "Feed the Swarm", "cut": "Basalt Monolith"},
                ],
            }
        ]
    }


class GlobalCommanderRampCutUsageSameLaneProofScoutTests(unittest.TestCase):
    def test_usage_observed_and_no_same_lane_blocks_candidate_copy(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            policy = write_json(root, "ramp_policy.json", ramp_policy_payload())
            write_json(
                root,
                "global_commander_cut_source_hypothesis_trace_collector_kaalia.json",
                {
                    "artifact_type": "global_commander_cut_source_hypothesis_trace_collector",
                    "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
                    "review_rows": [
                        {
                            "cut_card": "Arcane Signet",
                            "status": "hypothesis_used_by_target_trace_blocks_value_safe",
                            "usage_event_count": 1,
                            "exposure_event_count": 8,
                            "decision_trace_count": 12,
                            "first_usage_event": {"event": "spell_cast"},
                        }
                    ],
                },
            )

            report = scout.build_report(ramp_policy_report=policy, scan_roots=[root])

        self.assertEqual(report["status"], "ramp_cut_usage_same_lane_proof_blocks_candidate_copy")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["usage_blocked_cut_count"], 1)
        self.assertEqual(report["summary"]["missing_trace_cut_count"], 1)
        self.assertEqual(report["summary"]["explicit_same_lane_route_count"], 0)
        self.assertEqual(report["summary"]["pair_ready_count"], 0)
        blockers = report["candidate_copy_blockers"]
        self.assertIn("usage_observed_blocks_ramp_cuts:Arcane Signet", blockers)
        self.assertIn("missing_current_scope_usage_trace_for_ramp_cuts:Basalt Monolith", blockers)
        self.assertIn("no_explicit_same_lane_replacement_route_for_ramp_cut_pairs", blockers)

    def test_same_lane_route_requires_matching_candidate_role(self) -> None:
        pair = {"add": "Ramp Replacement", "cut": "Ramp Cut", "role": "ramp"}
        cut = {"roles": ["ramp", "engine"]}

        self.assertEqual(scout.base_scout.explicit_same_lane_roles(pair=pair, cut=cut, pool_role="removal"), ["ramp"])
        self.assertEqual(
            scout.base_scout.explicit_same_lane_roles(
                pair={"add": "Removal", "cut": "Ramp Cut"},
                cut=cut,
                pool_role="removal",
            ),
            [],
        )


if __name__ == "__main__":
    unittest.main()
