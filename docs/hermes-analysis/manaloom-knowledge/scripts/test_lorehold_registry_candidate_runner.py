import unittest

import lorehold_registry_candidate_runner as runner


class LoreholdRegistryCandidateRunnerTest(unittest.TestCase):
    def test_queue_entries_sort_by_priority(self):
        registry = {
            "untested_queue": [
                {"key": "candidate_607_low_v1", "priority": "P3"},
                {"key": "candidate_607_high_v1", "priority": "P1"},
            ]
        }

        keys = [entry["key"] for entry in runner.queue_entries(registry)]

        self.assertEqual(keys, ["candidate_607_high_v1", "candidate_607_low_v1"])

    def test_classify_blocks_tbd_swap_even_when_key_has_candidate_shape(self):
        entry = {
            "key": "candidate_607_reprieve_v1",
            "priority": "P1",
            "swap_or_scope": "+Reprieve; same-function protection/counter slot TBD",
        }

        classification = runner.classify_entry(entry)

        self.assertEqual(classification["status"], "blocked_tbd_swap")
        self.assertEqual(classification["reason"], "registry entry still has TBD same-function cut")

    def test_plan_name_maps_registered_candidate_key(self):
        self.assertEqual(
            runner.plan_name_for_candidate_key("candidate_607_birgi_v1"),
            "birgi_v1",
        )

    def test_added_cards_for_plan_reads_research_plan(self):
        self.assertEqual(
            runner.added_cards_for_plan("birgi_v1"),
            ["Birgi, God of Storytelling // Harnfel, Horn of Bounty"],
        )

    def test_extract_child_status_from_noisy_stdout(self):
        payload = runner.extract_child_status(
            "running candidate\n"
            '{\n  "status": "ready",\n  "json": "/tmp/gate.json"\n}\n'
        )

        self.assertEqual(payload["status"], "ready")
        self.assertEqual(payload["json"], "/tmp/gate.json")

    def test_command_payloads_include_focus_and_battle_prior(self):
        commands = runner.command_payloads(
            plan="birgi_v1",
            python="python3",
            source_db=runner.DEFAULT_SOURCE_DB,
            battle_prior_json=runner.DEFAULT_BATTLE_PRIOR_JSON,
            battle_prior_player_slots=2,
            candidate_cards=runner.added_cards_for_plan("birgi_v1"),
            games=1,
            opponent_limit=1,
            opponent_seed=7,
            simulation_seed=11,
            game_timeout_seconds=3.0,
            force_focus_access="opening_hand",
            stem="unit",
        )

        self.assertEqual(commands["candidate_key"], "candidate_607_birgi_v1")
        self.assertEqual(commands["candidate_deck_id"], 607)
        self.assertIn("Birgi, God of Storytelling", commands["focus_access_env"])
        self.assertEqual(
            commands["gate_command"][commands["gate_command"].index("--candidate-deck-id") + 1],
            "607",
        )
        self.assertIn("opening_hand", commands["gate_command"])
        self.assertIn("--gate-report-json", commands["battle_prior_command"])
        self.assertIn("--candidate-card", commands["battle_prior_command"])

    def test_battle_prior_unobserved_candidate_blocks_scoring(self):
        prior_gate = {
            "candidate_observations": {
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty": {
                    "evidence_level": "library_only",
                    "observed": False,
                }
            },
            "candidate_unobserved_cards": [
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty"
            ],
            "status": "inconclusive_candidate_unobserved",
        }

        decision = runner.classify_battle_prior_summary(prior_gate)

        self.assertEqual(decision["status"], "needs_more_evidence_candidate_unobserved")
        self.assertEqual(
            decision["next_action"],
            "rerun_with_forced_focus_access_or_larger_natural_sample_until_candidate_accessed",
        )
        self.assertIn("Birgi, God of Storytelling", decision["reason"])

    def test_battle_prior_accessed_but_unused_candidate_blocks_scoring(self):
        prior_gate = {
            "candidate_scoreability": {
                "candidate_accessed_not_used_cards": [
                    "Birgi, God of Storytelling // Harnfel, Horn of Bounty"
                ],
                "candidate_near_access_only_cards": [],
                "status": "candidate_not_used",
            },
            "candidate_unused_cards": [
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty"
            ],
            "status": "inconclusive_candidate_not_used",
        }

        decision = runner.classify_battle_prior_summary(prior_gate)

        self.assertEqual(decision["status"], "needs_more_evidence_candidate_not_used")
        self.assertEqual(
            decision["next_action"],
            "rerun_with_forced_focus_access_and_usage_or_inspect_play_heuristic",
        )
        self.assertIn("no direct use was observed", decision["reason"])

    def test_aggregate_status_treats_evidence_gap_as_not_ready(self):
        self.assertEqual(
            runner.aggregate_report_status(["needs_more_evidence_candidate_unobserved"]),
            "needs_more_evidence",
        )
        self.assertEqual(
            runner.aggregate_report_status(["needs_more_evidence_candidate_not_used"]),
            "needs_more_evidence",
        )
        self.assertEqual(
            runner.aggregate_report_status(["executed_battle_prior_passed"]),
            "ready",
        )


if __name__ == "__main__":
    unittest.main()
