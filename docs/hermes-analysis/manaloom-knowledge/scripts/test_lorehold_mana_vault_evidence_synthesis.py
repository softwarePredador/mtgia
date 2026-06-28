import json
import tempfile
import unittest
from pathlib import Path

import lorehold_mana_vault_evidence_synthesis as synth


def write_json(path: Path, payload: dict):
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def package_report(
    *,
    status: str = "gated",
    source_db_mutated: bool = False,
    forced_access_mode: str | None = "none",
    baseline_wins: int = 3,
    baseline_losses: int = 0,
    candidate_wins: int = 1,
    candidate_losses: int = 2,
    delta_pp: float = -66.67,
    with_gate: bool = True,
) -> dict:
    package = {
        "package_key": synth.PACKAGE_KEY,
        "family": "fast_mana",
        "adds": ["Mana Vault"],
        "cuts": ["Arcane Signet"],
        "status": status,
        "forced_access_mode": forced_access_mode,
        "exposure_summary": {
            "status": "candidate_added_cards_used",
            "candidate_added_cards": {
                "all_cards_used": True,
                "total_recorded_use_count": 4,
                "cards": [
                    {
                        "card_name": "Mana Vault",
                        "status": "used",
                        "recorded_use_count": 4,
                        "event_breakdown": {"cost_paid": 2},
                    }
                ],
            },
            "low_candidate_added_card_use": False,
        },
    }
    if with_gate:
        package["gate_summary"] = {
            "baseline": {
                "status": "pass",
                "games": baseline_wins + baseline_losses,
                "wins": baseline_wins,
                "losses": baseline_losses,
                "stalls": 0,
                "win_rate": round(100 * baseline_wins / max(1, baseline_wins + baseline_losses), 2),
                "telemetry": {
                    "strategic_event_counts": {
                        "lorehold_spell_cast": 20,
                        "miracle_cast": 4,
                    }
                },
            },
            "candidate": {
                "status": "pass",
                "games": candidate_wins + candidate_losses,
                "wins": candidate_wins,
                "losses": candidate_losses,
                "stalls": 0,
                "win_rate": round(100 * candidate_wins / max(1, candidate_wins + candidate_losses), 2),
                "telemetry": {
                    "strategic_event_counts": {
                        "lorehold_spell_cast": 10,
                        "miracle_cast": 1,
                    }
                },
            },
            "delta_pp": delta_pp,
        }
    return {
        "generated_at": "2026-06-28T00:00:00+00:00",
        "source_db_mutated": source_db_mutated,
        "games_per_opponent": 1,
        "opponent_limit": 3,
        "opponent_seed": 42,
        "simulation_seed": 42,
        "packages": [package],
    }


class LoreholdManaVaultEvidenceSynthesisTest(unittest.TestCase):
    def test_negative_natural_confirmation_rejects_current_pair(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            preflight = tmp / "lorehold_mana_vault_preflight.json"
            natural = tmp / "lorehold_mana_vault_natural_confirmation.json"
            write_json(preflight, package_report(status="preflight_ready", with_gate=False))
            write_json(natural, package_report(delta_pp=-66.67))

            payload = synth.build_synthesis([preflight, natural])

            self.assertEqual(payload["summary"]["decision"], "reject_current_pair")
            self.assertFalse(payload["summary"]["promotion_allowed"])
            self.assertEqual(payload["summary"]["natural_negative_count"], 1)
            self.assertEqual(payload["summary"]["latest_natural_delta_pp"], -66.67)
            self.assertEqual(payload["summary"]["strategic_delta_total"]["lorehold_spell_cast"], -10)
            self.assertIn("Mana Vault", payload["adds"])

    def test_positive_diagnostic_without_natural_confirmation_does_not_promote(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            diagnostic = tmp / "lorehold_mana_vault_exposure_gate.json"
            write_json(
                diagnostic,
                package_report(
                    forced_access_mode="opening_hand",
                    baseline_wins=1,
                    baseline_losses=2,
                    candidate_wins=3,
                    candidate_losses=0,
                    delta_pp=66.67,
                ),
            )

            payload = synth.build_synthesis([diagnostic])

            self.assertEqual(payload["summary"]["decision"], "diagnostic_positive_needs_natural_confirmation")
            self.assertFalse(payload["summary"]["promotion_allowed"])
            self.assertEqual(payload["summary"]["positive_gate_count"], 1)
            self.assertEqual(payload["summary"]["natural_gate_count"], 0)
            self.assertTrue(payload["summary"]["exposure_confirmed"])

    def test_markdown_contains_operational_decision(self):
        payload = {
            "generated_at": "2026-06-28T00:00:00+00:00",
            "package_key": synth.PACKAGE_KEY,
            "adds": ["Mana Vault"],
            "cuts": ["Arcane Signet"],
            "decision_rules": ["negative natural confirmations reject the exact add/cut pair"],
            "summary": {
                "decision": "reject_current_pair",
                "promotion_allowed": False,
                "next_action": "do_not_repeat_mana_vault_cut_arcane_signet_without_new_cut_or_failure_target",
                "sample_caveat": "small seed",
                "source_report_count": 1,
                "observation_count": 1,
                "performance_gate_count": 1,
                "natural_gate_count": 1,
                "positive_gate_count": 0,
                "negative_gate_count": 1,
                "latest_natural_source": "natural.json",
                "latest_natural_delta_pp": -66.67,
                "exposure_confirmed": True,
                "strategic_delta_total": {"miracle_cast": -3},
            },
            "observations": [],
        }

        markdown = synth.render_markdown(payload)

        self.assertIn("reject_current_pair", markdown)
        self.assertIn("do_not_repeat_mana_vault_cut_arcane_signet", markdown)


if __name__ == "__main__":
    unittest.main()
