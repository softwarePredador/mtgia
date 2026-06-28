import json
import sqlite3

import lorehold_access_cut_model as model


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
            functional_tags_json TEXT,
            type_line TEXT,
            oracle_text TEXT,
            cmc REAL,
            is_commander INTEGER
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE battle_card_rules (
            card_name TEXT,
            normalized_name TEXT,
            review_status TEXT,
            execution_status TEXT,
            effect_json TEXT
        )
        """
    )
    conn.executemany(
        "INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [
            (6, "Lorehold, the Historian", 1, "engine", '["engine"]', "Legendary Creature", "", 4, 1),
            (6, "Sensei's Divining Top", 1, "draw", '["draw"]', "Artifact", "", 1, 0),
            (6, "Promise of Loyalty", 1, "draw", '["draw"]', "Sorcery", "", 5, 0),
            (6, "Low Exposure Topdeck Flex", 1, "draw", '["draw"]', "Artifact", "", 1, 0),
            (6, "Boros Signet", 1, "ramp", '["ramp"]', "Artifact", "", 2, 0),
            (609, "Penance", 1, "draw", '["draw"]', "Enchantment", "", 3, 0),
            (609, "Hidden Retreat", 1, "draw", '["draw"]', "Enchantment", "", 3, 0),
            (611, "Brainstone", 1, "draw", '["draw"]', "Artifact", "", 1, 0),
            (613, "Brainstone", 1, "draw", '["draw"]', "Artifact", "", 1, 0),
        ],
    )
    conn.executemany(
        "INSERT INTO battle_card_rules VALUES (?, ?, ?, ?, ?)",
        [
            (
                "Brainstone",
                "brainstone",
                "verified",
                "auto",
                '{"effect":"topdeck_manipulation","battle_model_scope":"topdeck_setup_v1"}',
            ),
            (
                "Penance",
                "penance",
                "verified",
                "auto",
                '{"effect":"damage_prevention_shield","battle_model_scope":"hand_to_top_v1"}',
            ),
            (
                "Hidden Retreat",
                "hidden retreat",
                "needs_review",
                "review_only",
                '{"effect":"topdeck_manipulation"}',
            ),
        ],
    )
    return conn


def strategy_report():
    return {
        "cut_safety_manifest": {
            "summary": {},
            "cuts": [
                {
                    "card_name": "Sensei's Divining Top",
                    "status": "locked_do_not_cut",
                    "current_lane": "topdeck_setup",
                    "effective_role": "draw",
                }
            ],
            "untested_flex_pool": [
                {
                    "card_name": "Boros Signet",
                    "status": "core_support",
                    "package_lane": "early_mana",
                    "effective_role": "ramp",
                }
            ],
        }
    }


def seed_matrix_report():
    return {
        "packages": [
            {
                "package_key": "penance_runtime_topdeck_cut_promise",
                "adds": ["Penance"],
                "cuts": ["Promise of Loyalty"],
                "status": "matrix_run",
                "aggregate": {
                    "decision": "reject_regresses_strong_seed",
                    "baseline_record": "4-5",
                    "candidate_record": "2-7",
                    "delta_pp_total": -22.22,
                    "strong_seed_regressions": [42],
                },
            },
            {
                "package_key": "other_bad_promise_cut",
                "adds": ["Other"],
                "cuts": ["Promise of Loyalty"],
                "status": "matrix_run",
                "aggregate": {
                    "decision": "reject_or_rework",
                    "baseline_record": "4-5",
                    "candidate_record": "1-8",
                    "delta_pp_total": -33.33,
                    "strong_seed_regressions": [],
                },
            },
        ]
    }


def squee_probe_report():
    return {
        "summary": {
            "status": "squee_route_modeled_but_access_gap_remains",
            "next_action": "target_access_density_not_squee_sequencing",
            "modeled_when_accessed": True,
            "weak_material_missing_squee_seeds": ["7", "20260625"],
            "seed42_anchor_record": {"wins": 3, "losses": 0, "stalls": 0},
        }
    }


def test_hidden_retreat_is_blocked_until_runtime_is_executable():
    with memory_db() as conn:
        payload = model.build_model(
            conn=conn,
            strategy_report=strategy_report(),
            seed_matrix_report=seed_matrix_report(),
            candidates=["Hidden Retreat"],
        )

    hidden = payload["candidates"][0]
    assert hidden["status"] == "blocked"
    assert "candidate_runtime_review_only" in hidden["blockers"]
    assert payload["summary"]["preflight_access_candidate_ready_count"] == 0


def test_hidden_retreat_runtime_proposal_overlay_makes_candidate_model_ready(tmp_path):
    proposals = tmp_path / "hidden_retreat_proposals.json"
    proposals.write_text(
        json.dumps(
            {
                "proposals": [
                    {
                        "card_name": "Hidden Retreat",
                        "review_status": "verified",
                        "execution_status": "auto",
                        "effect_json": {
                            "effect": "damage_prevention_shield",
                            "battle_model_scope": (
                                "activated_put_card_from_hand_on_top_library_"
                                "prevent_damage_from_target_instant_or_sorcery_spell_v1"
                            ),
                        },
                    }
                ]
            }
        ),
        encoding="utf-8",
    )

    with memory_db() as conn:
        payload = model.build_model(
            conn=conn,
            strategy_report=strategy_report(),
            seed_matrix_report=seed_matrix_report(),
            candidates=["Hidden Retreat"],
            runtime_package_proposal_reports=[proposals],
        )

    hidden = payload["candidates"][0]
    assert hidden["status"] == "ready"
    assert hidden["rule_summary"]["active_rule_count"] == 1
    assert hidden["rule_summary"]["runtime_package_proposal_reports"] == [str(proposals)]
    assert payload["summary"]["runtime_package_overlay_card_count"] == 1
    assert payload["summary"]["hidden_retreat_runtime_model_status"] == (
        "runtime_proposal_overlay_active"
    )


def test_access_model_blocks_exact_and_repeated_rejected_cuts():
    with memory_db() as conn:
        payload = model.build_model(
            conn=conn,
            strategy_report=strategy_report(),
            seed_matrix_report=seed_matrix_report(),
            candidates=["Penance", "Brainstone"],
        )

    pairs = {
        (row["candidate"], row["cut"]): row
        for row in payload["pair_evaluations"]
    }
    penance_promise = pairs[("Penance", "Promise of Loyalty")]
    assert penance_promise["status"] == "blocked_cut_or_prior_evidence"
    assert "prior_exact_seed_matrix_reject" in penance_promise["blockers"]
    assert "cut_repeated_seed_matrix_rejects:2" in penance_promise["blockers"]

    brainstone_top = pairs[("Brainstone", "Sensei's Divining Top")]
    assert brainstone_top["status"] == "blocked_cut_or_prior_evidence"
    assert "cut_locked_do_not_cut" in brainstone_top["blockers"]


def test_access_model_can_surface_same_lane_preflight_candidate():
    with memory_db() as conn:
        payload = model.build_model(
            conn=conn,
            strategy_report=strategy_report(),
            seed_matrix_report=seed_matrix_report(),
            candidates=["Brainstone"],
        )

    ready = {
        (row["candidate"], row["cut"]): row
        for row in payload["preflight_access_candidates"]
    }
    assert ("Brainstone", "Low Exposure Topdeck Flex") in ready
    assert ready[("Brainstone", "Low Exposure Topdeck Flex")]["status"] == (
        "preflight_access_candidate_ready"
    )


def test_access_model_records_squee_access_density_context():
    with memory_db() as conn:
        payload = model.build_model(
            conn=conn,
            strategy_report=strategy_report(),
            seed_matrix_report=seed_matrix_report(),
            squee_probe_report=squee_probe_report(),
            candidates=["Enlightened Tutor", "Gamble"],
        )

    assert payload["summary"]["access_density_status"] == "squee_route_modeled_access_density_needed"
    assert payload["summary"]["squee_probe_status"] == "squee_route_modeled_but_access_gap_remains"
    assert payload["summary"]["weak_access_seeds"] == ["7", "20260625"]
    assert "Squee, Goblin Nabob" in payload["summary"]["target_access_cards"]
    by_card = {row["card_name"]: row for row in payload["candidates"]}
    assert "Squee, Goblin Nabob" not in by_card["Enlightened Tutor"]["access_targets"]
    assert "Squee, Goblin Nabob" in by_card["Gamble"]["access_targets"]
