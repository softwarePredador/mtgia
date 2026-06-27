import json
import sqlite3

import lorehold_card_exposure_profiler as profiler


def memory_db():
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.execute(
        """
        CREATE TABLE battle_card_rules (
            card_name TEXT,
            normalized_name TEXT,
            execution_status TEXT,
            review_status TEXT,
            effect_json TEXT
        )
        """
    )
    rows = [
        (
            "Emeria's Call // Emeria, Shattered Skyclave",
            "emeria's call // emeria, shattered skyclave",
            "auto",
            "verified",
            {
                "effect": "token_maker",
                "battle_model_scope": "create_two_4_4_flying_angel_warrior_tokens_non_angel_indestructible_until_next_turn_v1",
            },
        ),
        (
            "Austere Command",
            "austere command",
            "auto",
            "active",
            {"effect": "board_wipe", "battle_model_scope": "austere_command_choose_two_destroy_modes_v1"},
        ),
        (
            "Squee, Goblin Nabob",
            "squee, goblin nabob",
            "auto",
            "verified",
            {
                "effect": "graveyard_upkeep_return_self_to_hand",
                "battle_model_scope": "graveyard_upkeep_return_self_to_hand_v1",
            },
        ),
        (
            "Gamble",
            "gamble",
            "auto",
            "verified",
            {"effect": "tutor", "battle_model_scope": "any_card_to_hand_then_random_discard_v1"},
        ),
    ]
    conn.executemany(
        "INSERT INTO battle_card_rules VALUES (?, ?, ?, ?, ?)",
        [(name, normalized, execution, review, json.dumps(effect)) for name, normalized, execution, review, effect in rows],
    )
    return conn


def test_exposure_profiler_infers_emeria_and_squee_roles(tmp_path):
    evidence = tmp_path / "lorehold_gate.json"
    evidence.write_text(
        json.dumps(
            {
                "results": [
                    {
                        "telemetry": {
                            "top_cards": [
                                {"key": "cost_paid:Squee, Goblin Nabob", "count": 3},
                                {"key": "miracle:Emeria's Call // Emeria, Shattered Skyclave", "count": 1},
                            ],
                            "squee_game_traces": {
                                "deck_6:Opponent:0": [
                                    {
                                        "event": "protection_resolved",
                                        "data": {
                                            "card": "Emeria's Call // Emeria, Shattered Skyclave",
                                            "player": "Lorehold",
                                            "turn": 8,
                                        },
                                    },
                                    {
                                        "event": "tokens_created",
                                        "data": {
                                            "card": "Emeria's Call // Emeria, Shattered Skyclave",
                                            "effect": "token_maker",
                                            "player": "Lorehold",
                                            "turn": 8,
                                        },
                                    },
                                    {
                                        "event": "trigger_resolved",
                                        "data": {
                                            "card": "Squee, Goblin Nabob",
                                            "effect": "graveyard_upkeep_return_self_to_hand",
                                            "player": "Lorehold",
                                            "turn": 9,
                                        },
                                    },
                                ]
                            },
                        }
                    }
                ]
            }
        ),
        encoding="utf-8",
    )

    with memory_db() as conn:
        payload = profiler.build_profile(
            evidence_paths=[evidence],
            card_names=[
                "Emeria's Call // Emeria, Shattered Skyclave",
                "Squee, Goblin Nabob",
            ],
            conn=conn,
        )

    by_card = {row["card_name"]: row for row in payload["card_profiles"]}
    emeria = by_card["Emeria's Call // Emeria, Shattered Skyclave"]
    assert emeria["inferred_role"] == "token_protection_rebuild"
    assert emeria["decision"]["status"] == "not_safe_as_blind_cut"
    assert "board_development_tokens" in emeria["role_signals"]
    assert "protection_window" in emeria["role_signals"]

    squee = by_card["Squee, Goblin Nabob"]
    assert squee["decision"]["status"] == "protect_current_engine"
    assert squee["metric_counts"]["cost_paid:Squee, Goblin Nabob"] == 3


def test_exposure_profiler_reads_jsonl_and_keeps_rule_only_candidates(tmp_path):
    evidence = tmp_path / "austere.jsonl"
    evidence.write_text(
        "\n".join(
            [
                json.dumps(
                    {
                        "event": "board_wipe_resolved",
                        "card": "Austere Command",
                        "effect": "board_wipe",
                        "player": "Lorehold",
                        "turn": 7,
                    }
                ),
                json.dumps(
                    {
                        "event": "tutor_resolved",
                        "card": "Gamble",
                        "found": "Approach of the Second Sun",
                        "player": "Lorehold",
                        "turn": 5,
                    }
                ),
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    with memory_db() as conn:
        payload = profiler.build_profile(
            evidence_paths=[evidence],
            card_names=["Austere Command", "Gamble", "Restoration Seminar"],
            conn=conn,
        )

    by_card = {row["card_name"]: row for row in payload["card_profiles"]}
    assert by_card["Austere Command"]["inferred_role"] == "board_wipe_pressure_reset"
    assert by_card["Austere Command"]["decision"]["status"] == "candidate_role_known"
    assert by_card["Gamble"]["inferred_role"] == "tutor_access"
    assert by_card["Gamble"]["decision"]["status"] == "runtime_ready_cut_sensitive"
    assert by_card["Restoration Seminar"]["inferred_role"] == "unproven_or_unmodeled"
    assert by_card["Restoration Seminar"]["decision"]["status"] == "needs_non_squee_cut"
