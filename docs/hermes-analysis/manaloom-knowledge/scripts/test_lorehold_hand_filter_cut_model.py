import json
import sqlite3

import lorehold_hand_filter_cut_model as model


def test_default_baseline_deck_is_protected_607():
    assert model.DEFAULT_BASELINE_DECK_ID == 607


def test_default_miner_uses_current_runtime_queue():
    assert model.DEFAULT_MINER_REPORT.name == "lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json"


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
        (607, "Big Score", "ramp", '["ramp"]', "Instant", 4, 0),
        (607, "Esper Sentinel", "draw", '["draw"]', "Artifact Creature", 1, 0),
        (607, "Rise of the Eldrazi", "wincon", '["wincon"]', "Sorcery", 12, 0),
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


def miner_report_with_two_candidates():
    payload = miner_report()
    payload["pairing_hypotheses"].append(
        {
            "candidate": "Wheel of Fortune",
            "candidate_score": 92,
            "lane": "hand_filter",
            "status": "blocked_no_safe_cut_in_lane",
            "cut_options": payload["pairing_hypotheses"][0]["cut_options"],
        }
    )
    return payload


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
                        "Wheel of Fortune",
                        exposure=86,
                        direct=86,
                        role="draw_filter_value",
                        active_rules=1,
                        effects=["draw_cards"],
                        scopes=["multiplayer_discard_draw_v1"],
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


def prior_apex_reject_report():
    return (
        model.DEFAULT_PRIOR_PACKAGE_REPORTS[0],
        {
            "packages": [
                {
                    "package_key": "apex_hand_filter_cut_big_score",
                    "adds": ["Apex of Power"],
                    "cuts": ["Big Score"],
                    "gate_summary": {
                        "delta_pp": -100.0,
                        "baseline": {"wins": 3, "losses": 0, "stalls": 0},
                        "candidate": {"wins": 0, "losses": 3, "stalls": 0},
                    },
                }
            ]
        },
    )


def prior_reject_report(package_key, candidate, cut="Big Score"):
    return (
        model.DEFAULT_PRIOR_PACKAGE_REPORTS[0],
        {
            "packages": [
                {
                    "package_key": package_key,
                    "adds": [candidate],
                    "cuts": [cut],
                    "gate_summary": {
                        "delta_pp": -100.0,
                        "baseline": {"wins": 3, "losses": 0, "stalls": 0},
                        "candidate": {"wins": 0, "losses": 3, "stalls": 0},
                    },
                }
            ]
        },
    )


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


def test_hand_filter_model_skips_prior_exact_reject_and_recommends_next_pair():
    with memory_db() as conn:
        payload = model.build_model(
            conn=conn,
            miner_report=miner_report_with_two_candidates(),
            exposure_profiles=exposure_profiles(),
            prior_package_reports=[prior_apex_reject_report()],
        )

    assert payload["summary"]["prior_rejected_pair_count"] == 1
    assert payload["summary"]["preflight_benchmark_ready_count"] == 1
    assert payload["summary"]["recommended_next_action"] == "preflight_Wheel of Fortune_over_Big Score"

    by_pair = {
        (row["candidate"], row["cut"]): row
        for row in payload["pair_evaluations"]
    }
    assert by_pair[("Apex of Power", "Big Score")]["status"] == "blocked_prior_reject"
    assert "prior_exact_package_reject" in by_pair[("Apex of Power", "Big Score")]["blockers"]
    assert by_pair[("Wheel of Fortune", "Big Score")]["status"] == "preflight_benchmark_ready"


def test_hand_filter_model_blocks_cut_after_repeated_benchmark_rejects():
    with memory_db() as conn:
        payload = model.build_model(
            conn=conn,
            miner_report=miner_report_with_two_candidates(),
            exposure_profiles=exposure_profiles(),
            prior_package_reports=[
                prior_reject_report(
                    "valakut_hand_filter_cut_big_score",
                    "Valakut Awakening // Valakut Stoneforge",
                ),
                prior_reject_report("wheel_hand_filter_cut_big_score", "Wheel of Fortune"),
            ],
        )

    assert payload["summary"]["preflight_benchmark_ready_count"] == 0
    assert payload["summary"]["prior_rejected_cut_counts"] == {"big score": 2}
    assert payload["summary"]["recommended_next_action"] == (
        "do_not_gate_hand_filter_without_new_cut_or_runtime_evidence"
    )

    by_pair = {
        (row["candidate"], row["cut"]): row
        for row in payload["pair_evaluations"]
    }
    apex_big_score = by_pair[("Apex of Power", "Big Score")]
    assert apex_big_score["status"] == "blocked_cut_repeated_benchmark_reject"
    assert "cut_repeated_prior_rejects:2" in apex_big_score["blockers"]
    assert by_pair[("Wheel of Fortune", "Big Score")]["status"] == "blocked_prior_reject"
