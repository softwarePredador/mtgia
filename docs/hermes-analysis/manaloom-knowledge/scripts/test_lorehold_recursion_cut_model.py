import sqlite3

import lorehold_recursion_cut_model as model


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
        (6, "Squee, Goblin Nabob", "wincon", '["wincon"]', "Legendary Creature", 3, 0),
        (6, "Farewell", "board_wipe", '["board_wipe","wipe"]', "Sorcery", 6, 0),
        (6, "Furygale Flocking", "wincon", '["wincon","token_maker"]', "Sorcery", 10, 0),
        (6, "Mizzix's Mastery", "wincon", '["wincon","overload_recursion"]', "Sorcery", 4, 0),
        (6, "Pinnacle Monk // Mystic Peak", "engine", '["engine","removal"]', "Creature", 5, 0),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?)", rows)
    return conn


def miner_report():
    cut_options = [
        {
            "card_name": "Squee, Goblin Nabob",
            "gate_readiness": "manual_cut_review_required",
            "status": "manual_review_needed",
            "lane": "graveyard_recursion",
        },
        {
            "card_name": "Farewell",
            "gate_readiness": "protected_same_lane_benchmark_required",
            "status": "requires_same_lane_gate",
            "lane": "graveyard_recursion",
        },
        {
            "card_name": "Furygale Flocking",
            "gate_readiness": "protected_same_lane_benchmark_required",
            "status": "requires_same_lane_gate",
            "lane": "graveyard_recursion",
        },
        {
            "card_name": "Mizzix's Mastery",
            "gate_readiness": "protected_same_lane_benchmark_required",
            "status": "requires_same_lane_gate",
            "lane": "graveyard_recursion",
        },
        {
            "card_name": "Pinnacle Monk // Mystic Peak",
            "gate_readiness": "protected_same_lane_benchmark_required",
            "status": "requires_same_lane_gate",
            "lane": "graveyard_recursion",
        },
    ]
    return {
        "pairing_hypotheses": [
            {
                "candidate": "Volcanic Vision",
                "candidate_score": 72,
                "lane": "graveyard_recursion",
                "status": "manual_cut_review_required",
                "cut_options": cut_options,
            },
            {
                "candidate": "Restoration Seminar",
                "candidate_score": 68,
                "lane": "graveyard_recursion",
                "status": "manual_cut_review_required",
                "cut_options": cut_options,
            },
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
        signals,
        scopes=None,
    ):
        return {
            "card_name": card_name,
            "unique_exposure_count": exposure,
            "direct_event_count": direct,
            "inferred_role": role,
            "decision": {"status": "review_required"},
            "role_signals": signals,
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
                        "Squee, Goblin Nabob",
                        exposure=6752,
                        direct=6568,
                        role="recursion_engine",
                        active_rules=1,
                        effects=["creature"],
                        signals=["graveyard_recursion", "paid_cast_exposure"],
                        scopes=["graveyard_upkeep_return_self_to_hand_v1"],
                    ),
                    profile(
                        "Volcanic Vision",
                        exposure=2,
                        direct=0,
                        role="recursion_candidate",
                        active_rules=2,
                        effects=["recursion"],
                        signals=["spell_or_permanent_recursion", "miracle_hit"],
                        scopes=["instant_sorcery_recursion_with_opponent_creature_damage_annotation_v1"],
                    ),
                    profile(
                        "Restoration Seminar",
                        exposure=2,
                        direct=0,
                        role="recursion_candidate",
                        active_rules=1,
                        effects=["recursion"],
                        signals=["spell_or_permanent_recursion", "paid_cast_exposure"],
                        scopes=["nonland_permanent_graveyard_to_battlefield_paradigm_v1"],
                    ),
                    profile(
                        "Farewell",
                        exposure=29,
                        direct=24,
                        role="board_wipe_pressure_reset",
                        active_rules=1,
                        effects=["board_wipe"],
                        signals=["pressure_reset_board_wipe", "miracle_hit"],
                        scopes=["modal_exile_wipe_creature_runtime_baseline_v1"],
                    ),
                    profile(
                        "Furygale Flocking",
                        exposure=22,
                        direct=2,
                        role="token_protection_rebuild",
                        active_rules=1,
                        effects=["token_maker"],
                        signals=["board_development_tokens", "miracle_hit"],
                        scopes=["per_opponent_two_3_3_flying_hasty_elemental_tokens_v1"],
                    ),
                    profile(
                        "Mizzix's Mastery",
                        exposure=196,
                        direct=112,
                        role="recursion_engine",
                        active_rules=1,
                        effects=["overload_recursion"],
                        signals=["paid_cast_exposure", "miracle_hit"],
                        scopes=["target_or_overload_graveyard_instant_sorcery_copy_cast_runtime_v1"],
                    ),
                    profile(
                        "Pinnacle Monk // Mystic Peak",
                        exposure=14,
                        direct=2,
                        role="recursion_engine",
                        active_rules=1,
                        effects=["creature", "recursion"],
                        signals=["graveyard_recursion", "spell_or_permanent_recursion"],
                        scopes=[
                            "front_creature_prowess_etb_return_instant_or_sorcery_graveyard_to_hand_back_land_annotation_v1"
                        ],
                    ),
                ]
            },
        )
    ]


def prior_volcanic_pinnacle_reject_report():
    return (
        model.DEFAULT_PRIOR_PACKAGE_REPORTS[0],
        {
            "packages": [
                {
                    "package_key": "volcanic_recursion_cut_pinnacle",
                    "adds": ["Volcanic Vision"],
                    "cuts": ["Pinnacle Monk // Mystic Peak"],
                    "gate_summary": {
                        "delta_pp": -100.0,
                        "baseline": {"wins": 3, "losses": 0, "stalls": 0},
                        "candidate": {"wins": 0, "losses": 3, "stalls": 0},
                    },
                }
            ]
        },
    )


def test_recursion_model_preserves_squee_and_selects_pinnacle_benchmark():
    with memory_db() as conn:
        payload = model.build_model(
            conn=conn,
            miner_report=miner_report(),
            exposure_profiles=exposure_profiles(),
        )

    assert payload["postgres_writes"] is False
    assert payload["summary"]["preflight_benchmark_ready_count"] == 2
    assert payload["summary"]["recommended_next_action"] == (
        "preflight_Volcanic Vision_over_Pinnacle Monk // Mystic Peak"
    )

    by_pair = {
        (row["candidate"], row["cut"]): row
        for row in payload["pair_evaluations"]
    }
    volcanic_pinnacle = by_pair[("Volcanic Vision", "Pinnacle Monk // Mystic Peak")]
    assert volcanic_pinnacle["status"] == "preflight_benchmark_ready"
    assert "candidate_low_natural_exposure" in volcanic_pinnacle["blockers"]

    squee_pair = by_pair[("Volcanic Vision", "Squee, Goblin Nabob")]
    assert squee_pair["status"] == "blocked_core_or_current_engine_cut"
    assert "cut_is_current_squee_recursion_engine" in squee_pair["blockers"]

    assert by_pair[("Volcanic Vision", "Farewell")]["status"] == "blocked_core_or_current_engine_cut"
    assert "cut_is_board_wipe" in by_pair[("Volcanic Vision", "Farewell")]["blockers"]
    assert by_pair[("Volcanic Vision", "Furygale Flocking")]["status"] == (
        "blocked_core_or_current_engine_cut"
    )
    assert "cut_has_wincon_tag" in by_pair[("Volcanic Vision", "Furygale Flocking")]["blockers"]
    assert by_pair[("Volcanic Vision", "Mizzix's Mastery")]["status"] == (
        "blocked_core_or_current_engine_cut"
    )
    assert "cut_high_exposure:196" in by_pair[("Volcanic Vision", "Mizzix's Mastery")]["blockers"]


def test_recursion_model_blocks_pinnacle_after_prior_reject():
    with memory_db() as conn:
        payload = model.build_model(
            conn=conn,
            miner_report=miner_report(),
            exposure_profiles=exposure_profiles(),
            prior_package_reports=[prior_volcanic_pinnacle_reject_report()],
        )

    assert payload["summary"]["preflight_benchmark_ready_count"] == 0
    assert payload["summary"]["prior_rejected_cut_counts"] == {
        "pinnacle monk mystic peak": 1
    }
    assert payload["summary"]["recommended_next_action"] == (
        "do_not_gate_recursion_without_non_squee_cut_or_multi_card_package"
    )

    by_pair = {
        (row["candidate"], row["cut"]): row
        for row in payload["pair_evaluations"]
    }
    assert by_pair[("Volcanic Vision", "Pinnacle Monk // Mystic Peak")]["status"] == (
        "blocked_prior_reject"
    )
    restoration_pinnacle = by_pair[("Restoration Seminar", "Pinnacle Monk // Mystic Peak")]
    assert restoration_pinnacle["status"] == "blocked_cut_prior_reject"
    assert "cut_prior_reject_count:1" in restoration_pinnacle["blockers"]
