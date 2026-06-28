import json
import sqlite3

import lorehold_hand_filter_cut_model as model


def memory_db():
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.execute(
        """
        CREATE TABLE deck_cards (
            deck_id INTEGER,
            card_name TEXT,
            functional_tag TEXT,
            functional_tags_json TEXT,
            type_line TEXT,
            cmc REAL,
            is_commander INTEGER
        )
        """
    )
    rows = [
        (6, "Big Score", "ramp", '["ramp"]', "Instant", 4, 0),
        (6, "Esper Sentinel", "draw", '["draw"]', "Artifact Creature", 1, 0),
        (6, "Rise of the Eldrazi", "wincon", '["wincon"]', "Sorcery", 12, 0),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?)", rows)
    return conn


def miner_report():
    cut_options = [
        {
            "card_name": "Big Score",
            "gate_readiness": "protected_same_lane_benchmark_required",
            "status": "requires_same_lane_gate",
            "lane": "hand_filter",
        },
        {
            "card_name": "Esper Sentinel",
            "gate_readiness": "protected_same_lane_benchmark_required",
            "status": "requires_same_lane_gate",
            "lane": "hand_filter",
        },
        {
            "card_name": "Rise of the Eldrazi",
            "gate_readiness": "protected_same_lane_benchmark_required",
            "status": "requires_same_lane_gate",
            "lane": "hand_filter",
        },
    ]
    return {
        "pairing_hypotheses": [
            {
                "candidate": "Apex of Power",
                "candidate_score": 92,
                "lane": "hand_filter",
                "status": "blocked_no_safe_cut_in_lane",
                "cut_options": cut_options,
            }
        ]
    }


def exposure_profiles():
    def profile(
        card_name,
        *,
        exposure,
        direct,
        role,
        active_rules,
        effects,
        scopes=None,
    ):
        return {
            "card_name": card_name,
            "unique_exposure_count": exposure,
            "direct_event_count": direct,
            "inferred_role": role,
            "decision": {"status": "review_required"},
            "role_signals": [],
            "rule_summary": {
                "active_rule_count": active_rules,
                "effects": {effect: 1 for effect in effects},
                "battle_model_scopes": {scope: 1 for scope in (scopes or [])},
            },
        }

    return [
        (
            model.DEFAULT_EXPOSURE_PROFILES[0],
            {
                "card_profiles": [
                    profile(
                        "Apex of Power",
                        exposure=0,
                        direct=0,
                        role="draw_filter_value",
                        active_rules=2,
                        effects=["draw_cards", "passive"],
                        scopes=["impulse_top_seven_plus_hand_cast_mana_annotation_v1"],
                    ),
                    profile(
                        "Big Score",
                        exposure=34,
                        direct=10,
                        role="runtime_ready_unexposed",
                        active_rules=1,
                        effects=["treasure_maker"],
                        scopes=["discard_draw_two_create_two_treasures_v1"],
                    ),
                    profile(
                        "Esper Sentinel",
                        exposure=612,
                        direct=412,
                        role="draw_filter_value",
                        active_rules=1,
                        effects=["draw_engine"],
                        scopes=["first_opponent_noncreature_spell_power_tax_draw_v1"],
                    ),
                    profile(
                        "Rise of the Eldrazi",
                        exposure=206,
                        direct=178,
                        role="tutor_target",
                        active_rules=1,
                        effects=["composite_resolution"],
                        scopes=["uncounterable_destroy_target_permanent_target_player_draw_four_extra_turn_exile_v1"],
                    ),
                ]
            },
        )
    ]


def test_hand_filter_model_selects_apex_big_score_benchmark_and_blocks_core_cuts():
    with memory_db() as conn:
        payload = model.build_model(
            conn=conn,
            miner_report=miner_report(),
            exposure_profiles=exposure_profiles(),
        )

    assert payload["postgres_writes"] is False
    assert payload["summary"]["preflight_benchmark_ready_count"] == 1
    assert payload["summary"]["recommended_next_action"] == "preflight_Apex of Power_over_Big Score"

    by_pair = {
        (row["candidate"], row["cut"]): row
        for row in payload["pair_evaluations"]
    }
    apex_big_score = by_pair[("Apex of Power", "Big Score")]
    assert apex_big_score["status"] == "preflight_benchmark_ready"
    assert "candidate_zero_natural_exposure" in apex_big_score["blockers"]
    assert "cut_removes_ramp_or_treasure_role" in apex_big_score["blockers"]

    assert by_pair[("Apex of Power", "Esper Sentinel")]["status"] == "blocked_cut_core_or_high_exposure"
    assert "cut_high_exposure:612" in by_pair[("Apex of Power", "Esper Sentinel")]["blockers"]
    assert by_pair[("Apex of Power", "Rise of the Eldrazi")]["status"] == "blocked_cut_core_or_high_exposure"
    assert "cut_is_wincon" in by_pair[("Apex of Power", "Rise of the Eldrazi")]["blockers"]
