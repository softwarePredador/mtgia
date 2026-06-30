import json
import sqlite3

import lorehold_failure_targeted_synergy_hypotheses as synth


def test_defaults_use_current_learning_queue_and_planner():
    assert synth.DEFAULT_HYPOTHESIS_QUEUE.name == "lorehold_next_hypothesis_queue_20260630_after_profiled_gate.json"
    assert synth.DEFAULT_NEXT_ACTION_PLANNER.name == "lorehold_next_action_planner_20260630_after_profiled_gate.json"


def memory_db():
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.execute(
        """
        CREATE TABLE battle_card_rules (
            card_name TEXT,
            normalized_name TEXT,
            logical_rule_key TEXT,
            review_status TEXT,
            execution_status TEXT,
            effect_json TEXT
        )
        """
    )
    rows = [
        (
            "Urza's Saga",
            "urza s saga",
            "battle_rule_v1:urza_partial",
            "active",
            "auto",
            {
                "battle_model_scope": "saga_land_token_then_tutor_partial_v1",
                "effect": "land",
            },
        ),
        (
            "Urza's Saga",
            "urza s saga",
            "battle_rule_v1:urza_cmc0",
            "verified",
            "auto",
            {
                "effect": "land",
                "saga_artifact_tutor_cmc_max": 0,
                "saga_construct_token": True,
            },
        ),
        (
            "Library of Leng",
            "library of leng",
            "battle_rule_v1:library",
            "active",
            "auto",
            {
                "battle_model_scope": "discard_replacement_to_top_v1",
                "effect": "passive",
            },
        ),
        (
            "Sensei's Divining Top",
            "sensei s divining top",
            "battle_rule_v1:top",
            "active",
            "auto",
            {
                "battle_model_scope": "senseis_top_reorder_draw_lorehold_first_draw_miracle_v1",
                "effect": "topdeck_manipulation",
            },
        ),
        (
            "Scroll Rack",
            "scroll rack",
            "battle_rule_v1:rack",
            "active",
            "auto",
            {
                "battle_model_scope": "scroll_rack_upkeep_single_exchange_v1",
                "effect": "topdeck_manipulation",
            },
        ),
        (
            "Squee, Goblin Nabob",
            "squee goblin nabob",
            "battle_rule_v1:squee",
            "verified",
            "auto",
            {
                "battle_model_scope": "graveyard_upkeep_return_self_to_hand_v1",
                "effect": "creature",
            },
        ),
        (
            "The Mind Stone",
            "the mind stone",
            "battle_rule_v1:mind",
            "verified",
            "auto",
            {
                "battle_model_scope": "legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1",
                "effect": "ramp_permanent",
                "harnessed_end_step_blink": True,
            },
        ),
        (
            "Land Tax",
            "land tax",
            "battle_rule_v1:land_tax",
            "active",
            "auto",
            {
                "battle_model_scope": "land_tax_upkeep_opponent_more_lands_basic_land_tutor_to_hand_v1",
                "effect": "land_tax",
            },
        ),
    ]
    for name, normalized, key, review, execution, effect in rows:
        conn.execute(
            """
            INSERT INTO battle_card_rules
                (card_name, normalized_name, logical_rule_key, review_status, execution_status, effect_json)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (name, normalized, key, review, execution, json.dumps(effect)),
        )
    return conn


def strategy_audit():
    def seed(seed_id, wins, losses, rates, counts=None):
        return {
            "seed": seed_id,
            "wins": wins,
            "losses": losses,
            "stalls": 0,
            "games": wins + losses,
            "win_rate": round((wins / (wins + losses)) * 100, 2) if wins + losses else 0,
            "source": f"/tmp/seed_{seed_id}.json",
            "strategic_games": {
                key: {"games": int(value * (wins + losses)), "rate": value}
                for key, value in rates.items()
            },
            "strategic_events": counts or {},
        }

    return {
        "current_champion_key": "candidate_607_squee_hashseed0_isolated_cached_timeout_v3",
        "commander_intent": "Use topdeck setup and Lorehold miracle discount.",
        "deck_summaries": {
            "607": {
                "cards": [
                    {"card_name": "Urza's Saga"},
                    {"card_name": "Library of Leng"},
                    {"card_name": "Sensei's Divining Top"},
                    {"card_name": "Scroll Rack"},
                    {"card_name": "The Mind Stone"},
                    {"card_name": "Land Tax"},
                ]
            }
        },
        "strategy_dependency_map": {
            "current_benchmark": {
                "champion": {
                    "record": "24-66-0",
                    "strategic_events": {
                        "lorehold_rummage_discards_squee": 0,
                        "squee_to_graveyard": 16,
                        "squee_upkeep_return": 12,
                    },
                },
                "seed_42_champion": seed(
                    42,
                    8,
                    1,
                    {
                        "topdeck_manipulation_activated": 0.5556,
                        "miracle_cast": 0.8889,
                        "squee_to_graveyard": 0.4444,
                        "squee_upkeep_return": 0.2222,
                        "lorehold_upkeep_rummage": 0.7778,
                    },
                ),
                "seed_7_champion": seed(
                    7,
                    0,
                    9,
                    {
                        "topdeck_manipulation_activated": 0.1111,
                        "miracle_cast": 0.4444,
                        "squee_to_graveyard": 0.0,
                        "squee_upkeep_return": 0.0,
                        "lorehold_upkeep_rummage": 1.0,
                    },
                ),
                "seed_20260625_champion": seed(
                    20260625,
                    0,
                    9,
                    {
                        "topdeck_manipulation_activated": 0.1111,
                        "miracle_cast": 0.2222,
                        "squee_to_graveyard": 0.0,
                        "squee_upkeep_return": 0.0,
                        "lorehold_upkeep_rummage": 0.8889,
                    },
                ),
            }
        },
    }


def exhausted_queue():
    return {
        "summary": {
            "gate_ready_count": 0,
            "tested_negative_count": 13,
            "status_counts": {"tested_negative_do_not_promote": 13},
        }
    }


def planner_payload():
    return {
        "action_queue": [
            {
                "action_key": "build_failure_targeted_synergy_hypotheses",
                "candidate_cards": list(synth.DEFAULT_FOCUS_CARDS),
            }
        ]
    }


def test_weak_seed_findings_distinguish_access_and_conversion_failures():
    seeds = synth.seed_profile(strategy_audit())
    findings = {row["seed"]: row for row in synth.weak_seed_findings(seeds)}

    assert findings[7]["finding_type"] == "missing_or_low_engine_access"
    assert findings[7]["squee_missing"] is True
    assert findings[20260625]["finding_type"] == "engine_seen_but_conversion_failed"
    assert findings[20260625]["miracle_ratio_vs_seed42"] < 0.3


def test_rule_lookup_flags_urzas_saga_scope_and_mind_stone_trace():
    with memory_db() as conn:
        rules = synth.rule_lookup(conn, synth.DEFAULT_FOCUS_CARDS)

    assert rules["Urza's Saga"]["active_rule_count"] == 2
    assert "saga_rule_scope_partial" in rules["Urza's Saga"]["runtime_notes"]
    assert "saga_tutor_cmc_max_below_top_or_library" in rules["Urza's Saga"]["runtime_notes"]
    assert "blink_value_requires_target_trace" in rules["The Mind Stone"]["runtime_notes"]


def test_build_report_outputs_trace_hypotheses_when_queue_is_exhausted():
    with memory_db() as conn:
        report = synth.build_report(
            strategy_audit=strategy_audit(),
            hypothesis_queue=exhausted_queue(),
            planner_payload=planner_payload(),
            conn=conn,
        )

    assert report["postgres_writes"] is False
    assert report["source_db_mutated"] is False
    assert report["summary"]["recommended_next_action"] == "run_failure_targeted_trace_audit"
    keys = {row["hypothesis_key"] for row in report["hypotheses"]}
    assert "trace_seed7_engine_access_sequence" in keys
    assert "trace_seed20260625_conversion_window" in keys
    assert "audit_urzas_saga_artifact_tutor_scope" in keys
    assert "audit_squee_graveyard_entry_route" in keys
    squee_profile = next(row for row in report["engine_profiles"] if row["card_name"] == "Squee, Goblin Nabob")
    assert squee_profile["presence"]["in_current_champion_by_inference"] is True
