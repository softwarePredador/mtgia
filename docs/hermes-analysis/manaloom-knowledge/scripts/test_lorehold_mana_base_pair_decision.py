import json
from pathlib import Path

import lorehold_mana_base_pair_decision as decision


def write_json(path: Path, payload: dict) -> Path:
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def gate_payload(*, forced: str, baseline_wins: int, candidate_wins: int, add_access: int, cut_access: int) -> dict:
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
                    "strategic_games": {"miracle_cast": {"games": 2}},
                    "focus_card_access_summary": {
                        "Plateau": {"accessed_games": 0},
                        "Turbulent Steppe": {
                            "accessed_games": cut_access,
                            "opening_hand_games": cut_access if forced != "none" else 0,
                        },
                    },
                },
            },
            {
                "deck_key": "candidate_607_plateau_turbulent_steppe_mana_base_v1",
                "wins": candidate_wins,
                "losses": 3 - candidate_wins,
                "stalls": 0,
                "games": 3,
                "win_rate": round(candidate_wins / 3 * 100, 2),
                "telemetry": {
                    "strategic_games": {"miracle_cast": {"games": 1}},
                    "focus_card_access_summary": {
                        "Plateau": {
                            "accessed_games": add_access,
                            "opening_hand_games": add_access if forced != "none" else 0,
                        },
                        "Turbulent Steppe": {"accessed_games": 0},
                    },
                },
            },
        ],
    }


def test_pair_decision_rejects_when_forced_candidate_loses_despite_access(tmp_path: Path) -> None:
    preflight = write_json(
        tmp_path / "preflight.json",
        {
            "status": "battle_smoke_preflight_ready",
            "summary": {"add": "Plateau", "cut": "Turbulent Steppe"},
        },
    )
    natural = write_json(
        tmp_path / "natural.json",
        gate_payload(forced="none", baseline_wins=0, candidate_wins=0, add_access=1, cut_access=1),
    )
    forced = write_json(
        tmp_path / "forced.json",
        gate_payload(forced="opening_hand", baseline_wins=2, candidate_wins=1, add_access=3, cut_access=3),
    )

    payload = decision.build_payload(
        preflight_path=preflight,
        natural_gate_path=natural,
        forced_gate_path=forced,
    )

    assert payload["status"] == "reject_promotion_keep_607_current_baseline"
    assert payload["summary"]["candidate"] == "+Plateau / -Turbulent Steppe"
    assert payload["summary"]["natural_candidate_tied_or_beat_607"] is True
    assert payload["summary"]["forced_candidate_tied_or_beat_607"] is False
    assert payload["summary"]["forced_candidate_add_accessed_games"] == 3
    assert "forced_opening_hand_diagnostic_lost_to_607" in payload["summary"]["blockers"]


def test_pair_decision_write_outputs(tmp_path: Path) -> None:
    preflight = write_json(
        tmp_path / "preflight.json",
        {
            "status": "battle_smoke_preflight_ready",
            "summary": {"add": "Plateau", "cut": "Turbulent Steppe"},
        },
    )
    gate = write_json(
        tmp_path / "gate.json",
        gate_payload(forced="opening_hand", baseline_wins=2, candidate_wins=1, add_access=3, cut_access=3),
    )
    payload = decision.build_payload(preflight_path=preflight, natural_gate_path=gate, forced_gate_path=gate)
    json_path, md_path = decision.write_outputs(payload, tmp_path / "decision")

    assert json_path.exists()
    assert md_path.exists()
    assert "+Plateau / -Turbulent Steppe" in md_path.read_text(encoding="utf-8")
