import json
import sqlite3

import lorehold_tutor_cut_model as model


def test_defaults_use_current_runtime_package_inputs():
    assert model.DEFAULT_STRATEGY_AUDIT.name == "lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json"
    assert model.DEFAULT_MINER_REPORT.name == "lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json"
    assert model.DEFAULT_BASELINE_DECK_ID == 607


def memory_db():
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.execute(
        """
        CREATE TABLE deck_cards (
            deck_id INTEGER,
            card_name TEXT,
            quantity INTEGER,
            functional_tag TEXT,
            cmc REAL,
            type_line TEXT,
            functional_tags_json TEXT,
            is_commander INTEGER
        )
        """
    )
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
    conn.executemany(
        "INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        [
            (607, "Lorehold, the Historian", 1, "engine", 5, "Legendary Creature", '["engine"]', 1),
            (607, "Land Tax", 1, "tutor", 1, "Enchantment", '["tutor"]', 0),
            (607, "Sol Ring", 1, "ramp", 1, "Artifact", '["ramp"]', 0),
            (607, "Thor, God of Thunder", 1, "removal", 5, "Legendary Creature", '["removal"]', 0),
            (607, "Creative Technique", 1, "draw", 5, "Sorcery", '["draw"]', 0),
            (607, "The Mind Stone", 1, "ramp", 2, "Artifact", '["ramp"]', 0),
        ],
    )
    conn.executemany(
        "INSERT INTO battle_card_rules VALUES (?, ?, ?, ?, ?)",
        [
            (
                "Gamble",
                "gamble",
                "auto",
                "verified",
                json.dumps({"effect": "tutor", "battle_model_scope": "any_card_to_hand"}),
            ),
            (
                "Enlightened Tutor",
                "enlightened tutor",
                "auto",
                "active",
                json.dumps({"effect": "tutor", "battle_model_scope": "artifact_enchantment_to_top"}),
            ),
        ],
    )
    return conn


def strategy_audit():
    return {
        "strategy_dependency_map": {
            "cut_guardrails": {
                "locked_or_protected": [
                    {
                        "card_name": "Thor, God of Thunder",
                        "status": "locked_do_not_cut",
                    }
                ],
                "risky_same_lane_only": [
                    {
                        "card_name": "Creative Technique",
                        "status": "risky_cut_only_same_lane",
                    }
                ],
            },
            "package_learning": {
                "post_squee": {
                    "hard_reject_sample": [
                        {
                            "package_key": "gamble_access_cut_thor",
                            "family": "tutor_access",
                            "adds": ["Gamble"],
                            "cuts": ["Thor, God of Thunder"],
                            "decision": "reject_or_rework",
                            "delta_pp": -55.56,
                            "strong_seed_delta_pp": -55.56,
                        }
                    ],
                    "probation_or_watch": [
                        {
                            "package_key": "gamble_approach_access_cut_creative",
                            "family": "tutor_access",
                            "adds": ["Gamble"],
                            "cuts": ["Creative Technique"],
                            "decision": "probation_deeper_gate_only",
                            "delta_pp": 3.70,
                            "strong_seed_delta_pp": -44.45,
                        }
                    ],
                }
            },
        }
    }


def miner_report():
    return {
        "cut_inventory": [
            {
                "card_name": "Lorehold, the Historian",
                "status": "blocked_core_cut",
                "lane": "commander_engine",
            },
            {
                "card_name": "Land Tax",
                "status": "requires_same_lane_gate",
                "lane": "selection",
                "effective_role": "tutor",
                "decision": "core_support",
            },
            {
                "card_name": "Sol Ring",
                "status": "untested_flex_candidate",
                "lane": "early_mana",
                "effective_role": "ramp",
            },
            {
                "card_name": "Thor, God of Thunder",
                "status": "blocked_locked_cut",
                "lane": "graveyard_recursion",
            },
            {
                "card_name": "Creative Technique",
                "status": "risky_same_lane_only",
                "lane": "finisher_or_big_spell",
            },
            {
                "card_name": "The Mind Stone",
                "status": "manual_review_needed",
                "lane": "early_mana",
            },
        ]
    }


def exposure_profiles():
    return [
        (
            model.DEFAULT_EXPOSURE_PROFILES[0],
            {
                "card_profiles": [
                    {
                        "card_name": "Gamble",
                        "unique_exposure_count": 228,
                        "inferred_role": "tutor_access",
                        "decision": {"status": "runtime_ready_cut_sensitive"},
                    },
                    {
                        "card_name": "Enlightened Tutor",
                        "unique_exposure_count": 202,
                        "inferred_role": "tutor_access",
                        "decision": {"status": "runtime_ready_cut_sensitive"},
                    },
                    {
                        "card_name": "Land Tax",
                        "unique_exposure_count": 296,
                        "inferred_role": "tutor_access",
                        "decision": {"status": "review_required"},
                    },
                ]
            },
        )
    ]


def test_tutor_cut_model_blocks_prior_bad_cuts_and_requires_benchmark():
    with memory_db() as conn:
        payload = model.build_model(
            conn=conn,
            strategy_audit=strategy_audit(),
            miner_report=miner_report(),
            exposure_profiles=exposure_profiles(),
        )

    assert payload["postgres_writes"] is False
    assert payload["summary"]["direct_gate_ready_count"] == 0
    assert payload["summary"]["recommended_next_action"].startswith("do_not_gate_direct_tutor_swap")

    by_pair = {
        (row["candidate"], row["cut"]): row
        for row in payload["cut_pair_evaluations"]
    }
    assert by_pair[("Gamble", "Thor, God of Thunder")]["status"] == "blocked"
    assert "prior_strong_seed_regression:Thor, God of Thunder" in by_pair[
        ("Gamble", "Thor, God of Thunder")
    ]["blockers"]
    assert by_pair[("Gamble", "Creative Technique")]["status"] == "blocked"
    assert by_pair[("Gamble", "Sol Ring")]["status"] == "blocked_ramp_floor_mismatch"
    assert by_pair[("Gamble", "Land Tax")]["status"] == "protected_benchmark_required"
    assert by_pair[("Gamble", "Land Tax")]["cut_exposure"]["profiled"] is True
    assert by_pair[("Gamble", "Land Tax")]["cut_exposure"]["unique_exposure_count"] == 296
    assert by_pair[("Gamble", "The Mind Stone")]["cut_exposure"]["profiled"] is False

    candidates = {row["card_name"]: row for row in payload["candidates"]}
    assert candidates["Gamble"]["active_rule_count"] == 1
    assert len(candidates["Gamble"]["prior_tutor_evidence"]) == 2
