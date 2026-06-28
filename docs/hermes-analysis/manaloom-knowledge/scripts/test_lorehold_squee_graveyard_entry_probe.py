import json
from pathlib import Path

import lorehold_squee_graveyard_entry_probe as probe


def trace_audit():
    def seed_record(seed, wins, losses, *, reached=False, material_events=0):
        events = {
            "lorehold_upkeep_rummage": 9,
            "squee_to_graveyard": material_events,
            "squee_upkeep_return": material_events,
        }
        return {
            "seed": seed,
            "wins": wins,
            "losses": losses,
            "stalls": 0,
            "win_rate": 100.0 * wins / max(1, wins + losses),
            "trace_data_level": "per_game_event_counts",
            "aggregate_event_counts": events,
            "card_observations": [
                {
                    "card_name": "Squee, Goblin Nabob",
                    "evidence_level": "focus_access_trace_available",
                    "focus_access": {
                        "opening_zones": {"library": 3},
                        "early_zones": {"library": 9} if not reached else {"hand": 3, "library": 6},
                        "first_hand_or_battlefield": (
                            {"turn": 1, "phase": "after_draw_step", "zone": "hand"} if reached else None
                        ),
                        "min_library_position": 4,
                    },
                    "squee_trace_matches": {},
                }
            ],
        }

    return {
        "primary_seed_records": {
            "7": seed_record(7, 0, 3),
            "20260625": seed_record(20260625, 0, 3),
            "42": seed_record(42, 3, 0, reached=True),
        }
    }


def runtime_gate(seed, wins, losses, events):
    return {
        "simulation_seed": seed,
        "status": "ready",
        "python_hash_seed": "0",
        "opponent_seed": 20260626,
        "games_per_opponent": 1,
        "deck_process_isolation": False,
        "game_timeout_seconds": 20,
        "results": [
            {
                "deck_key": "deck_6",
                "wins": wins,
                "losses": losses,
                "stalls": 0,
                "win_rate": 100.0 * wins / max(1, wins + losses),
                "telemetry": {"strategic_event_counts": events},
            }
        ],
    }


def write_gate(tmp_path, seed, wins, losses, events):
    path = tmp_path / f"gate_seed{seed}.json"
    path.write_text(json.dumps(runtime_gate(seed, wins, losses, events)), encoding="utf-8")
    return path


def test_probe_classifies_squee_as_modeled_but_access_gap_remains(tmp_path):
    gates = [
        write_gate(tmp_path, 7, 0, 3, {"squee_to_graveyard": 1, "squee_upkeep_return": 1}),
        write_gate(tmp_path, 20260625, 1, 2, {"lorehold_upkeep_rummage": 4}),
        write_gate(
            tmp_path,
            42,
            3,
            0,
            {
                "lorehold_spell_rummage_discards_squee": 2,
                "squee_to_graveyard": 3,
                "squee_upkeep_return": 2,
                "miracle_cast": 13,
            },
        ),
    ]

    report = probe.build_report(
        trace_audit=trace_audit(),
        runtime_gate_paths=[Path(path) for path in gates],
    )

    assert report["postgres_writes"] is False
    assert report["source_db_mutated"] is False
    assert report["summary"]["status"] == "squee_route_modeled_but_access_gap_remains"
    assert report["summary"]["next_action"] == "target_access_density_not_squee_sequencing"
    assert report["decision"]["do_not_create_squee_sequencing_swap"] is True
    assert report["trace_seed_rows"]["7"]["squee_reached_hand_or_battlefield"] is False
    assert report["runtime_gate_rows"]["42"]["squee_discard_count"] == 2


def test_probe_stays_incomplete_without_seed42_discard_return_loop(tmp_path):
    gates = [
        write_gate(tmp_path, 7, 0, 3, {}),
        write_gate(tmp_path, 20260625, 0, 3, {}),
        write_gate(tmp_path, 42, 3, 0, {"squee_to_graveyard": 1}),
    ]

    report = probe.build_report(
        trace_audit=trace_audit(),
        runtime_gate_paths=[Path(path) for path in gates],
    )

    assert report["summary"]["status"] == "squee_route_probe_incomplete"
    assert report["summary"]["next_action"] == "add_or_rerun_squee_graveyard_entry_probe"
