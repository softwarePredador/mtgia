import json
from pathlib import Path

import lorehold_mana_base_plateau_radiant_decision as decision


def write_json(path: Path, payload: dict) -> Path:
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def gate_payload(*, forced: str, baseline_wins: int, candidate_wins: int, candidate_plateau_access: int) -> dict:
    return {
        "forced_access_mode": forced,
        "games_per_opponent": 3,
        "opponents": ["Fixed Lorehold deck 607"],
        "results": [
            {
                "deck_key": "deck_607",
                "wins": baseline_wins,
                "losses": 3 - baseline_wins,
                "stalls": 0,
                "games": 3,
                "win_rate": round(baseline_wins / 3 * 100, 2),
                "telemetry": {
                    "strategic_games": {
                        "miracle_cast": {"games": 2},
                        "topdeck_manipulation_activated": {"games": 1},
                    },
                    "focus_card_access_summary": {
                        "Radiant Summit": {
                            "accessed_games": 3 if forced != "none" else 1,
                            "opening_hand_games": 3 if forced != "none" else 1,
                        },
                        "Plateau": {"accessed_games": 0},
                    },
                },
            },
            {
                "deck_key": "candidate_607_plateau_radiant_mana_base_v1",
                "wins": candidate_wins,
                "losses": 3 - candidate_wins,
                "stalls": 0,
                "games": 3,
                "win_rate": round(candidate_wins / 3 * 100, 2),
                "telemetry": {
                    "strategic_games": {
                        "miracle_cast": {"games": 1},
                        "topdeck_manipulation_activated": {"games": 1},
                    },
                    "focus_card_access_summary": {
                        "Plateau": {
                            "accessed_games": candidate_plateau_access,
                            "opening_hand_games": candidate_plateau_access if forced != "none" else 0,
                        },
                        "Radiant Summit": {"accessed_games": 0},
                    },
                },
            },
        ],
    }


def test_decision_rejects_promotion_when_candidate_loses_smoke_and_forced(tmp_path: Path) -> None:
    preflight = write_json(
        tmp_path / "preflight.json",
        {"status": "battle_smoke_preflight_ready", "summary": {"add": "Plateau", "cut": "Radiant Summit"}},
    )
    natural = write_json(
        tmp_path / "natural.json",
        gate_payload(forced="none", baseline_wins=2, candidate_wins=1, candidate_plateau_access=0),
    )
    forced = write_json(
        tmp_path / "forced.json",
        gate_payload(forced="opening_hand", baseline_wins=2, candidate_wins=1, candidate_plateau_access=3),
    )

    payload = decision.build_payload(
        preflight_path=preflight,
        natural_gate_path=natural,
        forced_gate_path=forced,
    )

    assert payload["status"] == "reject_promotion_keep_607_current_baseline"
    assert payload["summary"]["promotion_allowed"] is False
    assert payload["summary"]["full_confirmation_allowed_now"] is False
    assert "natural_smoke_lost_to_607" in payload["summary"]["blockers"]
    assert "forced_opening_hand_diagnostic_lost_to_607" in payload["summary"]["blockers"]


def test_write_outputs_creates_decision_pair(tmp_path: Path) -> None:
    preflight = write_json(
        tmp_path / "preflight.json",
        {"status": "battle_smoke_preflight_ready", "summary": {}},
    )
    natural = write_json(
        tmp_path / "natural.json",
        gate_payload(forced="none", baseline_wins=2, candidate_wins=1, candidate_plateau_access=0),
    )
    forced = write_json(
        tmp_path / "forced.json",
        gate_payload(forced="opening_hand", baseline_wins=2, candidate_wins=1, candidate_plateau_access=3),
    )
    payload = decision.build_payload(preflight_path=preflight, natural_gate_path=natural, forced_gate_path=forced)
    json_path, md_path = decision.write_outputs(payload, tmp_path / "decision")

    assert json_path.exists()
    assert md_path.exists()
    assert "Plateau/Radiant" in md_path.read_text(encoding="utf-8")
