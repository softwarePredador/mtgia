import json
import sqlite3
from pathlib import Path

import lorehold_manual_cut_review as review


def test_default_safe_cut_replanner_uses_post_pg276_lane_corrected_report():
    assert (
        review.DEFAULT_SAFE_CUT_REPLANNER.name
        == "lorehold_safe_cut_replanner_20260630_post_pg276_squee_access_density_lane_corrected.json"
    )


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
            source TEXT,
            effect_json TEXT
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE deck_cards (
            deck_id INTEGER,
            card_name TEXT,
            quantity INTEGER,
            functional_tag TEXT,
            cmc REAL,
            type_line TEXT,
            functional_tags_json TEXT
        )
        """
    )
    for name, effect, scope in [
        ("Squee, Goblin Nabob", "creature", "graveyard_upkeep_return_self_to_hand_v1"),
        ("Volcanic Vision", "recursion", "instant_sorcery_recursion_with_opponent_creature_damage_annotation_v1"),
        ("Emeria's Call // Emeria, Shattered Skyclave", "token_maker", "create_two_4_4_flying_angel_warrior_tokens_non_angel_indestructible_until_next_turn_v1"),
        ("Austere Command", "board_wipe", "austere_command_choose_two_destroy_modes_v1"),
        ("Gamble", "tutor", "any_card_to_hand_then_random_discard_v1"),
        ("Enlightened Tutor", "tutor", "artifact_enchantment_tutor_to_library_top_v1"),
        ("Manual Flex", "draw", "manual_flex_draw_probe_v1"),
    ]:
        conn.execute(
            "INSERT INTO battle_card_rules VALUES (?, ?, ?, ?, ?, ?)",
            (
                name,
                name.lower(),
                "auto",
                "verified",
                "curated",
                json.dumps({"effect": effect, "battle_model_scope": scope}),
            ),
        )
        conn.execute(
            "INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?)",
            (6, name, 1, "engine", 3.0, "Sorcery", '["engine"]'),
        )
    conn.execute(
        "INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?)",
        (607, "Manual Flex", 1, "draw", 2.0, "Enchantment", '["draw"]'),
    )
    return conn


def strategy_audit():
    return {
        "card_decision_manifest": {
            "cards": [
                {
                    "card_name": "Squee, Goblin Nabob",
                    "decision": "probation_engine",
                    "decision_reason": "returns proved but not a self-sufficient loop",
                    "effective_role": "recursion_engine",
                    "package_lane": "graveyard_recursion",
                    "status": "materialized_rule_in_equal_gate_candidate",
                    "rule_materialized_in_equal_gate_candidate": True,
                },
                {
                    "card_name": "Emeria's Call // Emeria, Shattered Skyclave",
                    "decision": "modeled_pending_durable_sync",
                    "decision_reason": "role still unclear",
                    "effective_role": "unknown",
                    "package_lane": "pressure_absorber_or_protection",
                    "status": "materialization_gap_ready_rule",
                    "rule_materialized_in_equal_gate_candidate": False,
                },
                {
                    "card_name": "Manual Flex",
                    "decision": "manual_review",
                    "decision_reason": "weakly classified flex slot",
                    "effective_role": "draw",
                    "package_lane": "contextual",
                    "status": "manual_role_review",
                    "rule_materialized_in_equal_gate_candidate": False,
                },
            ]
        },
        "cut_safety_manifest": {"cuts": []},
        "strategy_dependency_map": {
            "package_learning": {
                "post_squee": {
                    "hard_reject_sample": [
                        {
                            "package_key": "gamble_access_cut_thor",
                            "adds": ["Gamble"],
                            "cuts": ["Thor, God of Thunder"],
                            "decision": "reject_or_rework",
                            "delta_pp": -55.56,
                            "strong_seed_delta_pp": -55.56,
                        },
                        {
                            "package_key": "enlightened_engine_access_cut_thor",
                            "adds": ["Enlightened Tutor"],
                            "cuts": ["Thor, God of Thunder"],
                            "decision": "reject_or_rework",
                            "delta_pp": -44.45,
                            "strong_seed_delta_pp": -44.45,
                        },
                    ],
                    "probation_or_watch": [
                        {
                            "package_key": "gamble_approach_access_cut_creative",
                            "adds": ["Gamble"],
                            "cuts": ["Creative Technique"],
                            "decision": "probation_deeper_gate_only",
                            "delta_pp": 3.70,
                            "strong_seed_delta_pp": -44.45,
                        }
                    ],
                }
            }
        },
    }


def safe_cut_report():
    return {
        "summary": {
            "manifest_ready_count": 0,
            "followup_count": 2,
        },
        "followups": [
            {
                "source_package_key": "past_in_flames_recast",
                "cuts": ["Manual Flex"],
                "blockers": ["missing_cut_safety_row"],
            },
            {
                "source_package_key": "gods_willing_commander_shield_cut_promise",
                "cuts": ["Squee, Goblin Nabob"],
                "blockers": ["cut_not_flex_decision", "missing_cut_safety_row"],
            },
        ],
    }


def cut_model():
    return {
        "pairing_hypotheses": [
            {
                "candidate": "Volcanic Vision",
                "status": "manual_cut_review_required",
                "lane": "graveyard_recursion",
                "cut_options": [
                    {
                        "card_name": "Squee, Goblin Nabob",
                        "signature": "add:volcanic vision|cut:squee goblin nabob",
                    }
                ],
            },
            {
                "candidate": "Austere Command",
                "status": "manual_cut_review_required",
                "lane": "pressure_absorber_or_protection",
                "cut_options": [
                    {
                        "card_name": "Emeria's Call // Emeria, Shattered Skyclave",
                        "signature": "add:austere command|cut:emeria s call emeria shattered skyclave",
                    }
                ],
            },
            {
                "candidate": "Gamble",
                "status": "needs_lane_model_before_gate",
                "lane": "contextual",
                "cut_options": [],
            },
            {
                "candidate": "Enlightened Tutor",
                "status": "needs_lane_model_before_gate",
                "lane": "contextual",
                "cut_options": [],
            },
        ]
    }


def exposure_profile():
    return {
        "card_profiles": [
            {
                "card_name": "Emeria's Call // Emeria, Shattered Skyclave",
                "unique_exposure_count": 193,
                "direct_event_count": 181,
                "summary_metric_count": 3,
                "role_signals": ["board_development_tokens", "protection_window"],
                "inferred_role": "token_protection_rebuild",
                "role_confidence": "direct_event_and_rule",
                "decision": {
                    "status": "not_safe_as_blind_cut",
                    "next_action": "test_austere_only_as_explicit_wipe_over_rebuild_tradeoff",
                },
            }
        ]
    }


def high_cut_exposure_profile():
    return {
        "card_profiles": [
            {
                "card_name": "Manual Flex",
                "unique_exposure_count": 144,
                "direct_event_count": 80,
                "summary_metric_count": 64,
                "role_signals": ["paid_cast_exposure", "draw_filter_value"],
                "inferred_role": "draw_filter_value",
                "role_confidence": "direct_event_or_rule",
                "decision": {
                    "status": "not_safe_as_blind_cut",
                    "next_action": "require_same_lane_benchmark",
                },
            }
        ]
    }


def test_manual_cut_review_blocks_squee_and_holds_emeria_for_role_review():
    with memory_db() as conn:
        payload = review.build_review(
            strategy_audit=strategy_audit(),
            cut_model=cut_model(),
            conn=conn,
        )

    manual = {(row["candidate"], row["cut"]): row for row in payload["manual_cut_reviews"]}
    assert manual[("Volcanic Vision", "Squee, Goblin Nabob")][
        "decision"
    ] == "do_not_cut_current_champion_engine"
    assert manual[("Volcanic Vision", "Squee, Goblin Nabob")]["gate_action"] == "blocked"
    assert manual[("Austere Command", "Emeria's Call // Emeria, Shattered Skyclave")][
        "decision"
    ] == "manual_review_role_gap_before_gate"
    assert payload["summary"]["automatic_gate_ready_count"] == 0


def test_manual_cut_review_uses_exposure_profile_for_emeria_tradeoff():
    with memory_db() as conn:
        payload = review.build_review(
            strategy_audit=strategy_audit(),
            cut_model=cut_model(),
            exposure_profile=exposure_profile(),
            conn=conn,
        )

    manual = {(row["candidate"], row["cut"]): row for row in payload["manual_cut_reviews"]}
    emeria = manual[("Austere Command", "Emeria's Call // Emeria, Shattered Skyclave")]
    assert emeria["decision"] == "manual_tradeoff_not_blind_cut"
    assert emeria["gate_action"] == "manual_tradeoff_gate_only"
    assert emeria["cut_exposure"]["inferred_role"] == "token_protection_rebuild"
    assert "193" in "; ".join(emeria["reasons"])


def test_tutor_contextual_candidates_keep_prior_seed_regression_visible():
    with memory_db() as conn:
        payload = review.build_review(
            strategy_audit=strategy_audit(),
            cut_model=cut_model(),
            conn=conn,
        )

    contextual = {row["candidate"]: row for row in payload["contextual_lane_reviews"]}
    assert contextual["Gamble"]["decision"] == "tutor_lane_probation_needs_seed_safe_cut"
    assert len(contextual["Gamble"]["prior_evidence"]) == 2
    assert "Creative Technique" in contextual["Gamble"]["recommended_cut_search"]
    assert contextual["Enlightened Tutor"]["decision"] == "tutor_lane_probation_needs_seed_safe_cut"


def test_manual_cut_review_safe_next_action_is_dynamic_after_tradeoff_removed():
    model = cut_model()
    model["pairing_hypotheses"] = [
        row
        for row in model["pairing_hypotheses"]
        if row.get("candidate") != "Austere Command"
    ]
    with memory_db() as conn:
        payload = review.build_review(
            strategy_audit=strategy_audit(),
            cut_model=model,
            exposure_profile=exposure_profile(),
            conn=conn,
        )

    safe_next_action = payload["summary"]["safe_next_action"]
    assert "Austere" not in safe_next_action
    assert "seed-safe tutor cut" in safe_next_action


def test_manual_cut_review_builds_cut_evidence_expansion_from_safe_cut_report():
    with memory_db() as conn:
        payload = review.build_review(
            strategy_audit=strategy_audit(),
            cut_model=cut_model(),
            safe_cut_report=safe_cut_report(),
            conn=conn,
        )

    expansion = payload["cut_evidence_expansion"]
    rows = {row["card_name"]: row for row in expansion["rows"]}
    assert rows["Manual Flex"]["status"] == "cut_exposure_candidate"
    assert rows["Manual Flex"]["recommended_action"] == "model_cut_exposure"
    assert rows["Manual Flex"]["lorehold_variant_presence"]["deck_count"] == 1
    assert rows["Manual Flex"]["safe_cut_replanner_evidence"]["blocker_counts"] == {
        "missing_cut_safety_row": 1
    }
    assert payload["summary"]["cut_evidence_expansion"]["model_cut_exposure_count"] >= 1


def test_manual_cut_review_blocks_high_exposure_cut_slots():
    with memory_db() as conn:
        payload = review.build_review(
            strategy_audit=strategy_audit(),
            cut_model=cut_model(),
            exposure_profile=high_cut_exposure_profile(),
            safe_cut_report=safe_cut_report(),
            conn=conn,
        )

    expansion = payload["cut_evidence_expansion"]
    rows = {row["card_name"]: row for row in expansion["rows"]}
    assert rows["Manual Flex"]["status"] == "measured_high_cut_exposure"
    assert rows["Manual Flex"]["recommended_action"] == "blocked"
    assert rows["Manual Flex"]["cut_exposure"]["unique_exposure_count"] == 144
    assert rows["Manual Flex"] in expansion["top_protected_exposure_slots"]


def test_manual_cut_review_prefers_highest_exposure_profile_for_cut_slots():
    low_profile = {
        "card_profiles": [
            {
                "card_name": "Manual Flex",
                "unique_exposure_count": 4,
                "inferred_role": "low_signal",
                "decision": {"status": "low"},
            }
        ]
    }
    with memory_db() as conn:
        payload = review.build_review(
            strategy_audit=strategy_audit(),
            cut_model=cut_model(),
            exposure_profiles=[
                (Path("old_profile.json"), low_profile),
                (Path("new_profile.json"), high_cut_exposure_profile()),
            ],
            safe_cut_report=safe_cut_report(),
            conn=conn,
        )

    row = {
        row["card_name"]: row
        for row in payload["cut_evidence_expansion"]["rows"]
    }["Manual Flex"]
    assert row["cut_exposure"]["unique_exposure_count"] == 144
    assert row["cut_exposure"]["exposure_profile"] == "new_profile.json"
