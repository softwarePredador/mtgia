#!/usr/bin/env python3
"""Tests for global Commander candidate package chain audit."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_candidate_package_chain_audit as audit


def materializer_payload(add: str, cut: str, *, source_clean: bool = True) -> dict[str, object]:
    return {
        "status": "candidate_materialized_structure_ready_next_gate_closed",
        "candidate_db": f"candidate_{add}.db",
        "summary": {
            "deck_id": 619,
            "commander": "Kaalia of the Vast",
            "role": "removal",
            "add": add,
            "cut": cut,
            "source_unchanged": source_clean,
            "source_matches_pair_report": source_clean,
            "source_candidate_hash_differs": True,
            "allow_next_strategy_matrix": True,
            "allow_battle_gate_now": False,
            "promotion_allowed": False,
        },
    }


def stage_materializer_payload() -> dict[str, object]:
    payload = materializer_payload("Arena of Glory", "Archaeomancer's Map")
    payload["candidate_db"] = "stage1_candidate.db"
    payload["summary"]["role"] = "value_safe_stage"
    payload["model_pairs"] = [
        {
            "add": "Arena of Glory",
            "cut": "Archaeomancer's Map",
            "role": "commander_attack_window",
        },
        {
            "add": "Despark",
            "cut": "Smuggler's Share",
            "role": "spot_interaction",
        },
    ]
    return payload


def core_payload(*, repaired: bool) -> dict[str, object]:
    missing = [] if repaired else [{"role": "removal", "missing": 1}]
    return {
        "decks": [
            {
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
                "core_status": "core_review_ready" if repaired else "core_role_gap",
                "role_bands": [
                    {"role": "removal", "count": 6 if repaired else 5, "status": "in_range" if repaired else "below_floor"},
                    {"role": "land", "count": 34, "status": "in_range"},
                ],
                "core_repair_plan": {"missing_role_slots": missing},
            }
        ]
    }


def strategy_payload() -> dict[str, object]:
    return {
        "commanders": [
            {
                "commander": "Kaalia of the Vast",
                "status": "ready_for_strategy_matrix",
                "next_gate": "run_commander_specific_strategy_matrix_before_battle_gate",
            }
        ]
    }


class GlobalCommanderCandidatePackageChainAuditTests(unittest.TestCase):
    def _write(self, root: Path, name: str, payload: dict[str, object]) -> Path:
        path = root / name
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_clean_chain_with_repaired_core_passes_but_keeps_battle_closed(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        materializers = [
            self._write(root, "step1.json", materializer_payload("Path to Exile", "Old Engine")),
            self._write(root, "step2.json", materializer_payload("Feed the Swarm", "Old Tutor")),
        ]
        core = self._write(root, "core.json", core_payload(repaired=True))
        strategy = self._write(root, "strategy.json", strategy_payload())

        report = audit.build_report(
            materializer_reports=materializers,
            final_core_report=core,
            final_strategy_report=strategy,
        )

        self.assertEqual(report["status"], "pass")
        self.assertTrue(report["summary"]["materializer_chain_pass"])
        self.assertTrue(report["summary"]["core_floor_repaired"])
        self.assertFalse(report["battle_gate_allowed_now"])
        self.assertFalse(report["promotion_allowed"])
        self.assertIn("package_battle_probe_not_run", report["blocker_reasons"])

    def test_unrepaired_core_blocks_package_chain(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        materializers = [
            self._write(root, "step1.json", materializer_payload("Path to Exile", "Old Engine")),
        ]
        core = self._write(root, "core.json", core_payload(repaired=False))
        strategy = self._write(root, "strategy.json", strategy_payload())

        report = audit.build_report(
            materializer_reports=materializers,
            final_core_report=core,
            final_strategy_report=strategy,
        )

        self.assertEqual(report["status"], "blocked")
        self.assertFalse(report["summary"]["core_floor_repaired"])
        self.assertIn("final_core_floor_not_repaired", report["blocker_reasons"])

    def test_stage_materializer_expands_model_pairs_as_package_swaps(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        materializers = [
            self._write(root, "stage1.json", stage_materializer_payload()),
        ]
        core = self._write(root, "core.json", core_payload(repaired=True))
        strategy = self._write(root, "strategy.json", strategy_payload())

        report = audit.build_report(
            materializer_reports=materializers,
            final_core_report=core,
            final_strategy_report=strategy,
        )

        self.assertEqual(report["status"], "pass")
        self.assertEqual(report["summary"]["swap_count"], 2)
        self.assertEqual(report["summary"]["package_adds"], ["Arena of Glory", "Despark"])
        self.assertEqual(report["summary"]["package_cuts"], ["Archaeomancer's Map", "Smuggler's Share"])
        self.assertEqual(report["summary"]["final_candidate_db"], "stage1_candidate.db")


if __name__ == "__main__":
    unittest.main()
