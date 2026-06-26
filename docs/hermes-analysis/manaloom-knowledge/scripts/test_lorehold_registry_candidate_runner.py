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


if __name__ == "__main__":
    unittest.main()
