#!/usr/bin/env python3

from __future__ import annotations

import tempfile
import unittest
import sys
import gzip
import json
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import external_battle_async_runner as runner


def completed_result(card_name: str, *, engine: str = "xmage") -> dict:
    return {
        "status": "completed",
        "engine": engine,
        "winner": "deck_a",
        "turns": 7,
        "learning_contract": {
            "schema_version": runner.LEARNING_SCHEMA,
            "absence_proves_nonuse": False,
        },
        "events": [
            {"event_type": "waiting", "card_name": "False Positive"},
            {"event_type": "ability_activated", "source_card_name": card_name},
        ],
    }


class FakeClient:
    def __init__(self, posts, health=None):
        self.posts = list(posts)
        self.health = list(health or [])
        self.post_calls = []
        self.get_calls = []

    def post(self, url, payload, timeout):
        self.post_calls.append(url)
        return self.posts.pop(0)

    def get(self, url, timeout):
        self.get_calls.append(url)
        return self.health.pop(0)


def registry_for(job: dict, *, minimum=1) -> dict:
    return {
        "schema_version": runner.REGISTRY_SCHEMA,
        "minimum_completed_per_variant": minimum,
        "jobs": [job],
    }


class ExternalBattleAsyncRunnerTest(unittest.TestCase):
    def test_zero_turn_completed_payload_fails_closed(self):
        invalid_result = completed_result("Candidate")
        invalid_result.update(
            {
                "winner": None,
                "turns": 0,
                "events": [],
                "visual_snapshots": [],
                "game_log": [],
            }
        )
        client = FakeClient([runner.HttpResult(200, invalid_result)])
        job = {
            "job_id": "zero-turn-completion",
            "request": {"seed": 1, "deck_a": {}, "deck_b": {}},
            "focus_cards": ["Candidate"],
        }
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            state = runner.BattleQueueRunner(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=3,
                client=client,
            ).run()["jobs"]["zero-turn-completion"]

        self.assertEqual(state["status"], "failed")
        self.assertEqual(state["error"], "engine_result_missing_positive_turn_count")
        self.assertEqual(state["attempts"][0]["status"], "invalid_completed_result")
        self.assertFalse(state["evidence"]["completed"])
        self.assertFalse(state["evidence"]["positive_exposure_ready"])
        self.assertEqual(client.post_calls, ["http://xmage/simulate"])

    def test_mismatched_engine_and_embedded_error_fail_closed(self):
        cases = (
            (completed_result("Candidate", engine="forge"), "engine_result_mismatch"),
            (
                {**completed_result("Candidate"), "error": "engine_failed"},
                "engine_result_contains_error",
            ),
            (
                {**completed_result("Candidate"), "error": ""},
                "engine_result_contains_error",
            ),
        )
        for index, (invalid_result, expected_error) in enumerate(cases):
            with (
                self.subTest(expected_error=expected_error),
                tempfile.TemporaryDirectory() as temporary,
            ):
                client = FakeClient([runner.HttpResult(200, invalid_result)])
                job = {
                    "job_id": f"invalid-completion-{index}",
                    "request": {"seed": index + 1, "deck_a": {}, "deck_b": {}},
                    "focus_cards": ["Candidate"],
                }
                root = Path(temporary)
                state = runner.BattleQueueRunner(
                    registry=registry_for(job),
                    checkpoint_path=root / "checkpoint.json",
                    result_dir=root / "results",
                    xmage_url="http://xmage",
                    forge_url="http://forge",
                    request_timeout=5,
                    recovery_timeout=5,
                    max_attempts=3,
                    client=client,
                ).run()["jobs"][job["job_id"]]

            self.assertEqual(state["status"], "failed")
            self.assertEqual(state["error"], expected_error)
            self.assertFalse(state["evidence"]["completed"])
            self.assertFalse(state["evidence"]["positive_exposure_ready"])

    def test_positive_evidence_rejects_generic_named_events(self):
        evidence = runner.extract_positive_evidence(
            completed_result("Krenko, Mob Boss"),
            focus_cards=["Krenko, Mob Boss", "False Positive"],
        )
        by_name = {row["card_name"]: row for row in evidence["focus_cards"]}
        self.assertTrue(by_name["Krenko, Mob Boss"]["positive_exposure"])
        self.assertFalse(by_name["False Positive"]["positive_exposure"])
        self.assertFalse(evidence["all_focus_cards_exposed"])
        self.assertFalse(evidence["swap_superiority_proven"])
        self.assertFalse(evidence["promotion_allowed"])

    def test_natural_same_lane_evidence_matches_backend_contract_without_focus(self):
        result = completed_result("Aerialephant")
        result["events"] = [
            {"event_type": "spell_cast", "card": "Aerialephant"},
            {"event_type": "ability_resolved", "source": "Aerialephant"},
            {"event_type": "damage", "target_card": "Target Creature"},
        ]

        evidence = runner.extract_positive_evidence(
            result,
            expected_engine="xmage",
            same_lane=True,
            natural_sample=True,
        )

        self.assertTrue(evidence["positive_exposure_ready"])
        self.assertTrue(evidence["natural_same_lane_exposure"])
        self.assertEqual(evidence["learning_contract_schema"], runner.LEARNING_SCHEMA)
        self.assertEqual(
            evidence["exposed_card_names_normalized"],
            ["aerialephant", "target creature"],
        )
        self.assertFalse(evidence["comparison_input_ready"])
        self.assertFalse(evidence["promotion_allowed"])

    def test_forced_access_remains_diagnostic_only_in_positive_evidence(self):
        evidence = runner.extract_positive_evidence(
            completed_result("Candidate"),
            focus_cards=["Candidate"],
            same_lane=True,
            natural_sample=False,
        )

        self.assertTrue(evidence["positive_exposure_ready"])
        self.assertFalse(evidence["natural_same_lane_exposure"])
        self.assertFalse(evidence["comparison_input_ready"])

    def test_forge_is_used_only_for_structured_xmage_coverage_gap(self):
        client = FakeClient(
            [
                runner.HttpResult(422, {"error": "xmage_coverage_incomplete"}),
                runner.HttpResult(200, completed_result("Candidate", engine="forge")),
            ]
        )
        job = {
            "job_id": "forge-fallback",
            "request": {"seed": 1, "deck_a": {}, "deck_b": {}},
            "focus_cards": ["Candidate"],
        }
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            queue = runner.BattleQueueRunner(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=3,
                client=client,
                sleeper=lambda _seconds: None,
            )
            state = queue.run()["jobs"]["forge-fallback"]
            with gzip.open(state["result_path"], "rt", encoding="utf-8") as handle:
                self.assertEqual(json.load(handle)["status"], "completed")
        self.assertEqual(state["status"], "completed")
        self.assertEqual(state["engine"], "forge")
        self.assertEqual(client.post_calls, ["http://xmage/simulate", "http://forge/simulate"])

    def test_operational_xmage_failure_never_falls_back(self):
        client = FakeClient([runner.HttpResult(500, {"error": "engine_failed"})])
        job = {"job_id": "failure", "request": {"seed": 1}}
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            queue = runner.BattleQueueRunner(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=3,
                client=client,
            )
            state = queue.run()["jobs"]["failure"]
        self.assertEqual(state["status"], "failed")
        self.assertEqual(client.post_calls, ["http://xmage/simulate"])

    def test_xmage_timeout_requires_a_new_process_before_retry(self):
        client = FakeClient(
            [
                runner.HttpResult(
                    504,
                    {
                        "error": "simulation_timeout",
                        "restart_required": True,
                        "sidecar_process_id": "old",
                    },
                ),
                runner.HttpResult(200, completed_result("Candidate")),
            ],
            health=[
                runner.HttpResult(200, {"status": "ok", "catalog_ready": True, "sidecar_process_id": "old"}),
                runner.HttpResult(200, {"status": "ok", "catalog_ready": True, "sidecar_process_id": "new"}),
            ],
        )
        job = {"job_id": "timeout", "request": {"seed": 1}, "focus_cards": ["Candidate"]}
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            queue = runner.BattleQueueRunner(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=3,
                client=client,
                sleeper=lambda _seconds: None,
            )
            state = queue.run()["jobs"]["timeout"]
        self.assertEqual(state["status"], "completed")
        self.assertTrue(state["attempts"][0]["recovery_observed"])
        self.assertEqual(len(client.get_calls), 2)

    def test_xmage_timeout_without_restart_contract_is_not_retried(self):
        client = FakeClient(
            [runner.HttpResult(504, {"error": "simulation_timeout"})]
        )
        job = {"job_id": "unsafe-timeout", "request": {"seed": 1}}
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            state = runner.BattleQueueRunner(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=3,
                client=client,
            ).run()["jobs"]["unsafe-timeout"]

        self.assertEqual(state["status"], "timeout")
        self.assertEqual(state["error"], "xmage_timeout_restart_not_declared")
        self.assertEqual(client.post_calls, ["http://xmage/simulate"])
        self.assertEqual(client.get_calls, [])

    def test_completed_job_is_not_reexecuted_on_resume(self):
        client = FakeClient([runner.HttpResult(200, completed_result("Candidate"))])
        job = {"job_id": "resume", "request": {"seed": 1}, "focus_cards": ["Candidate"]}
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            kwargs = dict(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=2,
                client=client,
            )
            runner.BattleQueueRunner(**kwargs).run()
            runner.BattleQueueRunner(**kwargs).run()
        self.assertEqual(len(client.post_calls), 1)

    def test_terminal_failure_is_not_reexecuted_on_resume(self):
        client = FakeClient([runner.HttpResult(500, {"error": "engine_failed"})])
        job = {"job_id": "terminal-failure", "request": {"seed": 1}}
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            kwargs = dict(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=2,
                client=client,
            )
            runner.BattleQueueRunner(**kwargs).run()
            runner.BattleQueueRunner(**kwargs).run()
        self.assertEqual(len(client.post_calls), 1)

    def test_registry_rejects_duplicate_comparison_seed(self):
        jobs = [
            {
                "job_id": f"base-{index}",
                "comparison_id": "swap-1",
                "variant": "base",
                "request": {"seed": 7},
            }
            for index in (1, 2)
        ]
        with self.assertRaisesRegex(ValueError, "duplicate comparison sample"):
            runner.validate_registry(
                {"schema_version": runner.REGISTRY_SCHEMA, "jobs": jobs}
            )

    def test_comparison_gate_requires_equal_natural_exposed_samples(self):
        jobs = []
        states = {}
        for variant, focus in (("base", "Removed"), ("candidate", "Added")):
            for seed in (1, 2, 3):
                job_id = f"{variant}-{seed}"
                jobs.append(
                    {
                        "job_id": job_id,
                        "comparison_id": "swap-1",
                        "variant": variant,
                        "same_lane": True,
                        "forced_access": False,
                        "focus_cards": [focus],
                        "request": {"seed": seed},
                    }
                )
                states[job_id] = {
                    "status": "completed",
                    "evidence": {
                        "positive_exposure_ready": True,
                        "focus_cards": [
                            {"card_name": focus, "positive_exposure": True}
                        ]
                    },
                }
        registry = {
            "schema_version": runner.REGISTRY_SCHEMA,
            "minimum_completed_per_variant": 3,
            "jobs": jobs,
        }
        checkpoint = {"jobs": states}
        gate = runner.evaluate_comparisons(registry, checkpoint)["swap-1"]
        self.assertTrue(gate["comparison_input_ready"])
        self.assertFalse(gate["promotion_allowed"])
        self.assertFalse(gate["swap_superiority_proven"])

    def test_comparison_gate_rejects_completed_but_unexposed_seed(self):
        jobs = []
        states = {}
        for variant, focus in (("base", "Removed"), ("candidate", "Added")):
            for seed in (1, 2, 3):
                job_id = f"{variant}-{seed}"
                jobs.append(
                    {
                        "job_id": job_id,
                        "comparison_id": "swap-1",
                        "variant": variant,
                        "same_lane": True,
                        "forced_access": False,
                        "focus_cards": [focus],
                        "request": {"seed": seed},
                    }
                )
                states[job_id] = {
                    "status": "completed",
                    "evidence": {
                        "positive_exposure_ready": seed != 3,
                        "focus_cards": [
                            {
                                "card_name": focus,
                                "positive_exposure": seed != 3,
                            }
                        ],
                    },
                }
        gate = runner.evaluate_comparisons(
            {
                "schema_version": runner.REGISTRY_SCHEMA,
                "minimum_completed_per_variant": 3,
                "jobs": jobs,
            },
            {"jobs": states},
        )["swap-1"]
        self.assertFalse(gate["comparison_input_ready"])
        self.assertEqual(gate["base_exposure_eligible"], 2)
        self.assertFalse(gate["exposure_qualified_enough"])


if __name__ == "__main__":
    unittest.main()
