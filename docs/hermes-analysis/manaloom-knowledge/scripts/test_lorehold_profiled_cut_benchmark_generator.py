import json
import sqlite3
from pathlib import Path

import lorehold_profiled_cut_benchmark_generator as generator


def build_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.executescript(
        """
        CREATE TABLE deck_cards (
          deck_id INTEGER,
          card_name TEXT,
          functional_tag TEXT,
          functional_tags_json TEXT,
          cmc REAL,
          type_line TEXT,
          oracle_text TEXT
        );
        CREATE TABLE battle_card_rules (
          card_name TEXT,
          normalized_name TEXT,
          execution_status TEXT,
          review_status TEXT,
          effect_json TEXT
        );
        """
    )
    current_rows = [
        (607, "Winds of Abandon", "removal", '["removal"]', 2, "Sorcery", "Exile target creature."),
        (607, "Stroke of Midnight", "removal", '["removal"]', 3, "Instant", "Destroy target nonland permanent."),
        (607, "Bender's Waterskin", "ramp", '["ramp"]', 3, "Artifact", "Mana rock."),
        (607, "Creative Technique", "draw", '["draw"]', 5, "Sorcery", "Reveal into a free spell."),
    ]
    variant_rows = [
        (608, "Lightning Bolt", "removal", '["removal"]', 1, "Instant", "Deal 3 damage to any target."),
        (609, "Erode", "removal", '["removal"]', 2, "Sorcery", "Destroy target creature or planeswalker."),
        (610, "Untimely Malfunction", "removal", '["removal"]', 2, "Instant", "Destroy target artifact."),
        (611, "Red Elemental Blast", "removal", '["removal"]', 1, "Instant", "Counter target blue spell or destroy target blue permanent."),
        (612, "Mana Vault", "ramp", '["ramp"]', 1, "Artifact", "Tap to add three colorless mana."),
        (612, "Bender's Waterskin", "ramp", '["ramp"]', 3, "Artifact", "Mana rock."),
        (612, "Chrome Mox", "ramp", '["ramp"]', 0, "Artifact", "Imprint. Tap: Add one mana of any of the exiled card's colors."),
        (613, "Storm-Kiln Artist", "ramp", '["ramp","creature"]', 4, "Creature — Dwarf Shaman", "Magecraft creates Treasure."),
        (614, "Galvanoth", "draw", '["draw"]', 5, "Creature — Beast", "May cast the top instant or sorcery without paying its mana cost."),
        (615, "Apex of Power", "draw", '["draw","payoff"]', 10, "Sorcery", "Exile seven cards and cast them this turn."),
        (615, "Stroke of Midnight", "removal", '["removal"]', 3, "Instant", "Destroy target nonland permanent."),
        (616, "Lion's Eye Diamond", "ramp", '["ramp"]', 0, "Artifact", "Discard your hand, Sacrifice this artifact: Add three mana of any one color. Activate only as an instant."),
        (616, "Treasonous Ogre", "ramp", '["ramp","creature"]', 4, "Creature — Ogre Shaman", "Dethrone\nPay 3 life: Add {R}."),
        (616, "Surly Badgersaur", "ramp", '["ramp","creature"]', 4, "Creature — Dinosaur", "Whenever you discard a land card, create a Treasure token."),
        (616, "Grinding Station", "ramp", '["ramp"]', 2, "Artifact", "Tap, sacrifice an artifact: target player mills three cards."),
        (616, "Thrumming Stone", "engine", '["engine","ripple_engine"]', 5, "Legendary Artifact", "Spells you cast have ripple 4."),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?)", current_rows + variant_rows)
    rules = [
        ("Winds of Abandon", "winds of abandon", "active", "active", {"effect": "remove_creature", "battle_model_scope": "exile_target_creature"}),
        ("Stroke of Midnight", "stroke of midnight", "active", "active", {"effect": "remove_permanent", "battle_model_scope": "destroy_target_nonland_permanent"}),
        ("Lightning Bolt", "lightning bolt", "active", "active", {"effect": "direct_damage", "battle_model_scope": "damage_any_target"}),
        ("Erode", "erode", "active", "active", {"effect": "remove_permanent", "battle_model_scope": "destroy_target_creature_planeswalker"}),
        ("Untimely Malfunction", "untimely malfunction", "active", "active", {"effect": "remove_permanent", "battle_model_scope": "destroy_target_artifact"}),
        ("Red Elemental Blast", "red elemental blast", "active", "active", {"effect": "modal_spell", "battle_model_scope": "counter_target_blue_spell_or_destroy_target_blue_permanent"}),
        ("Bender's Waterskin", "bender s waterskin", "auto", "verified", {"effect": "ramp_permanent", "battle_model_scope": "artifact_any_color_mana_rock_untaps_each_opponent_untap_step_v1", "mana_produced": 1}),
        ("Creative Technique", "creative technique", "auto", "verified", {"effect": "exile_top_nonland_free_cast", "battle_model_scope": "shuffle_reveal_top_nonland_exile_free_cast_with_demonstrate_v1"}),
        ("Mana Vault", "mana vault", "auto", "active", {"effect": "ramp_permanent", "battle_model_scope": "fast_mana_artifact_partial_v1", "mana_produced": 3}),
        ("Chrome Mox", "chrome mox", "auto", "active", {"effect": "ramp_permanent", "battle_model_scope": "fast_mana_artifact_partial_v1", "mana_produced": 1}),
        ("Storm-Kiln Artist", "storm kiln artist", "auto", "verified", {"effect": "creature", "battle_model_scope": "creature_body_artifact_power_magecraft_treasure_annotation_v1", "magecraft_treasure_status": "annotation_only"}),
        ("Galvanoth", "galvanoth", "auto", "verified", {"effect": "creature", "battle_model_scope": "controller_upkeep_look_top_instant_or_sorcery_may_cast_without_paying_mana_v1", "upkeep_may_cast_top_instant_or_sorcery_without_paying_mana": True}),
        ("Apex of Power", "apex of power", "auto", "active", {"effect": "passive", "battle_model_scope": "impulse_top_seven_plus_hand_cast_mana_annotation_v1", "impulse_top_seven_until_eot": True}),
        ("Lion's Eye Diamond", "lion s eye diamond", "auto", "verified", {"effect": "ramp_ritual", "mana_produced": 3, "produces": "WUBRGC"}),
        ("Treasonous Ogre", "treasonous ogre", "auto", "verified", {"effect": "creature", "is_mana_source": True, "mana_produced": 1, "produces": "R", "power": 2, "toughness": 3}),
        ("Surly Badgersaur", "surly badgersaur", "auto", "verified", {"effect": "creature", "battle_model_scope": "surly_badgersaur_discard_card_type_triggers_v1", "trigger": "controller_discard", "controller_discard_land_create_treasure": True}),
        ("Grinding Station", "grinding station", "auto", "verified", {"effect": "ramp_permanent", "mana_produced": 1}),
        ("Thrumming Stone", "thrumming stone", "auto", "verified", {"effect": "ripple_engine", "battle_model_scope": "static_spell_ripple_4_same_name_runtime_v1"}),
    ]
    conn.executemany(
        "INSERT INTO battle_card_rules VALUES (?, ?, ?, ?, ?)",
        [(name, normalized, execution, review, json.dumps(effect)) for name, normalized, execution, review, effect in rules],
    )
    return conn


def manual_review() -> dict:
    return {
        "cut_evidence_expansion": {
            "top_same_lane_candidates": [
                {
                    "card_name": "Winds of Abandon",
                    "status": "measured_cut_exposure_needs_same_lane_benchmark",
                    "recommended_action": "build_same_lane_benchmarks",
                    "cut_exposure": {"inferred_role": "spot_removal"},
                },
                {
                    "card_name": "Stroke of Midnight",
                    "status": "measured_cut_exposure_needs_same_lane_benchmark",
                    "recommended_action": "build_same_lane_benchmarks",
                    "cut_exposure": {"inferred_role": "spot_removal"},
                },
                {
                    "card_name": "Bender's Waterskin",
                    "status": "same_lane_only",
                    "recommended_action": "manual_same_lane_only",
                    "cut_exposure": {"inferred_role": "unmeasured"},
                },
                {
                    "card_name": "Creative Technique",
                    "status": "same_lane_only",
                    "recommended_action": "manual_same_lane_only",
                    "cut_exposure": {"inferred_role": "unmeasured"},
                },
            ]
        }
    }


def cut_safety() -> dict:
    return {
        "enabled": True,
        "cuts_by_name": {
            "Bender's Waterskin": {
                "card_name": "Bender's Waterskin",
                "status": "protected_until_same_function_replacement_wins",
                "current_lane": "early_mana",
                "effective_role": "ramp",
            },
            "Creative Technique": {
                "card_name": "Creative Technique",
                "status": "protected_until_same_function_replacement_wins",
                "current_lane": "finisher_or_big_spell",
                "effective_role": "big_spell_value",
            },
        },
    }


def test_generator_selects_same_lane_removal_package_and_manifest():
    with build_conn() as conn:
        payload = generator.build_report(
            conn=conn,
            manual_review=manual_review(),
            prior_results={"by_signature": {}},
            cut_safety=cut_safety(),
            db_path=Path("memory.db"),
            manual_review_path=Path("manual_review.json"),
            variant_deck_ids=[608, 609, 610, 611],
            max_per_cut=1,
        )

    assert payload["summary"]["selected_package_count"] > 0
    selected = payload["selected_pairs"]
    assert {row["cut"] for row in selected} <= {"Winds of Abandon", "Stroke of Midnight"}
    assert all(row["candidate_role"] == "spot_removal" for row in selected)
    assert all(row["cut_role"] == "spot_removal" for row in selected)
    assert all(row["candidate_rule"]["active_rule_count"] > 0 for row in selected)
    assert all(package["cut_safety_override_reason"] for package in payload["manifest"]["packages"])
    assert "Stroke of Midnight" not in {row["candidate"] for row in payload["top_pair_evaluations"]}
    assert "Red Elemental Blast" not in {row["candidate"] for row in selected}
    assert ("Lightning Bolt", "Stroke of Midnight") not in {
        (row["candidate"], row["cut"]) for row in selected
    }
    assert ("Untimely Malfunction", "Stroke of Midnight") not in {
        (row["candidate"], row["cut"]) for row in selected
    }
    red_blast_rows = [row for row in payload["top_pair_evaluations"] if row["candidate"] == "Red Elemental Blast"]
    assert any("candidate_narrow_color_hate" in row["blockers"] for row in red_blast_rows)


def test_generator_uses_cut_safety_roles_for_ramp_and_big_spell_packages():
    with build_conn() as conn:
        payload = generator.build_report(
            conn=conn,
            manual_review=manual_review(),
            prior_results={"by_signature": {}},
            cut_safety=cut_safety(),
            db_path=Path("memory.db"),
            manual_review_path=Path("manual_review.json"),
            variant_deck_ids=[612, 613, 614, 615, 616],
            max_per_cut=1,
        )

    selected = {(row["candidate"], row["cut"], row["candidate_role"], row["cut_role"]) for row in payload["selected_pairs"]}
    assert ("Mana Vault", "Bender's Waterskin", "ramp", "ramp") in selected
    assert ("Galvanoth", "Creative Technique", "big_spell_value", "big_spell_value") in selected
    assert "Bender's Waterskin" not in {row["candidate"] for row in payload["top_pair_evaluations"]}
    assert all(package["registry_protected_cut_override_reason"] for package in payload["manifest"]["packages"])
    package_by_cut = {
        package["cuts"][0]: package
        for package in payload["manifest"]["packages"]
    }
    assert package_by_cut["Creative Technique"]["allow_miracle_core_cuts"] is True
    assert "allow_miracle_core_cuts" not in package_by_cut["Bender's Waterskin"]
    chrome_rows = [row for row in payload["top_pair_evaluations"] if row["candidate"] == "Chrome Mox"]
    assert any("candidate_policy_blocked_no_premium_mox" in row["blockers"] for row in chrome_rows)
    storm_rows = [row for row in payload["top_pair_evaluations"] if row["candidate"] == "Storm-Kiln Artist"]
    assert any("candidate_runtime_annotation_only" in row["blockers"] or "candidate_role_mismatch:unknown" in row["blockers"] for row in storm_rows)
    grinding_rows = [row for row in payload["top_pair_evaluations"] if row["candidate"] == "Grinding Station"]
    assert any("candidate_scope_not_same_lane" in row["blockers"] for row in grinding_rows)
    thrumming_rows = [row for row in payload["top_pair_evaluations"] if row["candidate"] == "Thrumming Stone"]
    assert any("candidate_scope_not_same_lane" in row["blockers"] for row in thrumming_rows)


def test_generator_can_restrict_to_removal_lane_without_ramp_fallback():
    with build_conn() as conn:
        payload = generator.build_report(
            conn=conn,
            manual_review=manual_review(),
            prior_results={"by_signature": {}},
            cut_safety=cut_safety(),
            db_path=Path("memory.db"),
            manual_review_path=Path("manual_review.json"),
            variant_deck_ids=[608, 609, 610, 611, 612],
            max_per_cut=2,
            cut_roles=["spot_removal"],
        )

    assert payload["requested_cut_roles"] == ["spot_removal"]
    assert payload["summary"]["unfiltered_profiled_cut_count"] == 4
    assert payload["summary"]["profiled_cut_count"] == 2
    assert payload["summary"]["filtered_out_cut_count"] == 2
    assert payload["summary"]["selected_package_count"] > 0
    assert all(row["cut_role"] == "spot_removal" for row in payload["selected_pairs"])
    assert "Bender's Waterskin" not in {row["cut"] for row in payload["selected_pairs"]}
    assert any(
        row["card_name"] == "Bender's Waterskin"
        and row["reason"] == "filtered_out_by_requested_cut_role"
        for row in payload["blocked_cut_rows"]
    )


def test_generator_blocks_under_modeled_costs_and_conditional_ramp_payoffs():
    with build_conn() as conn:
        payload = generator.build_report(
            conn=conn,
            manual_review=manual_review(),
            prior_results={"by_signature": {}},
            cut_safety=cut_safety(),
            db_path=Path("memory.db"),
            manual_review_path=Path("manual_review.json"),
            variant_deck_ids=[616],
            max_per_cut=4,
        )

    rows_by_candidate = {
        row["candidate"]: row
        for row in payload["top_pair_evaluations"]
        if row["cut"] == "Bender's Waterskin"
    }
    assert "candidate_unmodeled_discard_hand_cost" in rows_by_candidate["Lion's Eye Diamond"]["blockers"]
    assert "candidate_unmodeled_life_payment_mana_cost" in rows_by_candidate["Treasonous Ogre"]["blockers"]
    assert (
        "candidate_conditional_discard_payoff_not_early_mana_replacement"
        in rows_by_candidate["Surly Badgersaur"]["blockers"]
    )
    assert payload["summary"]["blocker_counts"]["candidate_unmodeled_discard_hand_cost"] >= 1
    assert payload["summary"]["blocker_counts"]["candidate_unmodeled_life_payment_mana_cost"] >= 1


def test_generator_excludes_prior_exact_rejects():
    prior_results = {
        "by_signature": {
            "lightning-bolt-winds": [
                {
                    "decision": "reject_or_rework",
                    "adds": ["Lightning Bolt"],
                    "cuts": ["Winds of Abandon"],
                }
            ]
        }
    }
    with build_conn() as conn:
        payload = generator.build_report(
            conn=conn,
            manual_review=manual_review(),
            prior_results=prior_results,
            cut_safety=cut_safety(),
            db_path=Path("memory.db"),
            manual_review_path=Path("manual_review.json"),
            variant_deck_ids=[608],
        )

    assert not payload["selected_pairs"]
    blocked = [row for row in payload["top_pair_evaluations"] if row["candidate"] == "Lightning Bolt"]
    assert any("prior_exact_reject" in row["blockers"] for row in blocked)
