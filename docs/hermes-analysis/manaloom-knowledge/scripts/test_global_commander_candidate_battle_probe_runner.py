#!/usr/bin/env python3
"""Tests for global Commander candidate battle probe runner."""

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

import global_commander_candidate_battle_probe_runner as runner


class GlobalCommanderCandidateBattleProbeRunnerTests(unittest.TestCase):
    def _strategy_report(self, root: Path) -> Path:
        strategy = root / "strategy.json"
        strategy.write_text(
            json.dumps(
                {
                    "status": "package_strategy_ready_for_battle_probe",
                    "summary": {
                        "deck_id": "612",
                        "commander": "Lorehold, the Historian",
                        "package_adds": ["Bant Panorama", "Pyromancer's Goggles"],
                        "package_cuts": ["Storm-Kiln Artist", "Jeska's Will"],
                        "next_gate": "run_equal_battle_probe_with_replay_exposure",
                    },
                    "input_artifacts": {
                        "base_db": str(root / "base.db"),
                        "candidate_db": str(root / "candidate.db"),
                    },
                }
            ),
            encoding="utf-8",
        )
        return strategy

    def _gate_payload(self, include_candidate: bool = True) -> dict[str, object]:
        results: list[dict[str, object]] = [
            {
                "deck_key": "deck_612",
                "games": 2,
                "wins": 1,
                "losses": 1,
                "stalls": 0,
                "win_rate": 50.0,
                "telemetry": {"event_counts": {"spell_cast": 4}},
            }
        ]
        if include_candidate:
            results.append(
                {
                    "deck_key": "candidate_profile_repair_package",
                    "games": 2,
                    "wins": 2,
                    "losses": 0,
                    "stalls": 0,
                    "win_rate": 100.0,
                    "telemetry": {"event_counts": {"spell_cast": 6}},
                }
            )
        return {
            "status": "ready",
            "games_per_opponent": 1,
            "opponent_kind": "fixed",
            "opponents": ["Fixed Lorehold deck 607", "Other"],
            "results": results,
        }

    def test_build_payload_writes_metric_files_and_replay_inputs(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        report_dir = root / "reports"
        gate_report = report_dir / "probe_gate.json"

        def fake_run(command: list[str], **kwargs: object) -> subprocess.CompletedProcess[str]:
            env = kwargs.get("env")
            if str(command[1]).endswith("lorehold_variant_battle_gate.py"):
                gate_report.parent.mkdir(parents=True, exist_ok=True)
                gate_report.write_text(json.dumps(self._gate_payload()), encoding="utf-8")
            if str(command[1]).endswith("battle_replay_v10_3.py"):
                assert isinstance(env, dict)
                Path(str(env["REPLAY_EVENTS_OUT"])).write_text(
                    json.dumps({"event": "spell_cast", "card": "Pyromancer's Goggles"}) + "\n",
                    encoding="utf-8",
                )
                Path(str(env["DECISION_TRACE_OUT"])).write_text(
                    json.dumps({"actual_outcome": "keep"}) + "\n",
                    encoding="utf-8",
                )
                Path(str(env["REPLAY_DECK_PROVENANCE_OUT"])).write_text(
                    json.dumps({"decks": [{"name": "Lorehold, the Historian"}]}),
                    encoding="utf-8",
                )
            return subprocess.CompletedProcess(command, 0, "ok", "")

        payload = runner.build_payload(
            strategy_report=self._strategy_report(root),
            out_prefix=report_dir / "probe_runner",
            replay_dir=report_dir / "replay",
            battle_gate=Path("lorehold_variant_battle_gate.py"),
            battle_replay=Path("battle_replay_v10_3.py"),
            battle_stem="probe_gate",
            candidate_key="candidate_profile_repair_package",
            games=1,
            opponent_limit=1,
            opponent_seed=1,
            fixed_opponent_deck_ids="607",
            simulation_seed=42,
            real_opponent_seed=1,
            replay_seed=42,
            game_timeout_seconds=1,
            deck_process_timeout_seconds=1,
            timeout=5,
            report_dir=report_dir,
            runner=fake_run,
        )

        self.assertEqual(payload["status"], "candidate_battle_probe_inputs_ready")
        self.assertTrue(payload["battle_probe_audit_ready"])
        self.assertFalse(payload["promotion_allowed"])
        self.assertTrue((report_dir / "probe_runner_base_metrics.json").exists())
        self.assertTrue((report_dir / "probe_runner_candidate_metrics.json").exists())
        candidate_metrics = json.loads((report_dir / "probe_runner_candidate_metrics.json").read_text())
        self.assertEqual(candidate_metrics["metadata"]["win_rate"], 100.0)
        self.assertEqual(candidate_metrics["metadata"]["opponents"], 2)
        self.assertTrue((report_dir / "replay" / "replay.events.jsonl").exists())

    def test_missing_candidate_result_blocks_audit_ready(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        report_dir = root / "reports"
        gate_report = report_dir / "probe_gate.json"

        def fake_run(command: list[str], **kwargs: object) -> subprocess.CompletedProcess[str]:
            env = kwargs.get("env")
            if str(command[1]).endswith("lorehold_variant_battle_gate.py"):
                gate_report.parent.mkdir(parents=True, exist_ok=True)
                gate_report.write_text(
                    json.dumps(self._gate_payload(include_candidate=False)),
                    encoding="utf-8",
                )
            if str(command[1]).endswith("battle_replay_v10_3.py"):
                assert isinstance(env, dict)
                Path(str(env["REPLAY_EVENTS_OUT"])).write_text("{}\n", encoding="utf-8")
                Path(str(env["DECISION_TRACE_OUT"])).write_text("{}\n", encoding="utf-8")
                Path(str(env["REPLAY_DECK_PROVENANCE_OUT"])).write_text("{}", encoding="utf-8")
            return subprocess.CompletedProcess(command, 0, "ok", "")

        payload = runner.build_payload(
            strategy_report=self._strategy_report(root),
            out_prefix=report_dir / "probe_runner",
            replay_dir=report_dir / "replay",
            battle_gate=Path("lorehold_variant_battle_gate.py"),
            battle_replay=Path("battle_replay_v10_3.py"),
            battle_stem="probe_gate",
            candidate_key="candidate_profile_repair_package",
            games=1,
            opponent_limit=1,
            opponent_seed=1,
            fixed_opponent_deck_ids=None,
            simulation_seed=42,
            real_opponent_seed=1,
            replay_seed=42,
            game_timeout_seconds=1,
            deck_process_timeout_seconds=1,
            timeout=5,
            report_dir=report_dir,
            runner=fake_run,
        )

        self.assertEqual(payload["status"], "candidate_battle_probe_inputs_blocked")
        self.assertFalse(payload["battle_probe_audit_ready"])
        self.assertIn("candidate_result_missing_from_battle_gate", payload["blocker_reasons"])


if __name__ == "__main__":
    unittest.main()
