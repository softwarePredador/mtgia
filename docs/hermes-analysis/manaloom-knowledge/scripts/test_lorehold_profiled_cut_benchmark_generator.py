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
        (6, "Winds of Abandon", "removal", '["removal"]', 2, "Sorcery", "Exile target creature."),
        (6, "Stroke of Midnight", "removal", '["removal"]', 3, "Instant", "Destroy target nonland permanent."),
        (6, "Bender's Waterskin", "ramp", '["ramp"]', 3, "Artifact", "Mana rock."),
        (6, "Creative Technique", "draw", '["draw"]', 5, "Sorcery", "Reveal into a free spell."),
    ]
    variant_rows = [
        (608, "Lightning Bolt", "removal", '["removal"]', 1, "Instant", "Deal 3 damage to any target."),
        (609, "Erode", "removal", '["removal"]', 2, "Sorcery", "Destroy target creature or planeswalker."),
        (610, "Untimely Malfunction", "removal", '["removal"]', 2, "Instant", "Destroy target artifact."),
        (611, "Red Elemental Blast", "removal", '["removal"]', 1, "Instant", "Counter target blue spell or destroy target blue permanent."),
        (612, "Mana Vault", "ramp", '["ramp"]', 1, "Artifact", "Tap to add three colorless mana."),
        (613, "Storm-Kiln Artist", "ramp", '["ramp","creature"]', 4, "Creature — Dwarf Shaman", "Magecraft creates Treasure."),
        (614, "Galvanoth", "draw", '["draw"]', 5, "Creature — Beast", "May cast the top instant or sorcery without paying its mana cost."),
        (615, "Apex of Power", "draw", '["draw","payoff"]', 10, "Sorcery", "Exile seven cards and cast them this turn."),
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
        ("Storm-Kiln Artist", "storm kiln artist", "auto", "verified", {"effect": "creature", "battle_model_scope": "creature_body_artifact_power_magecraft_treasure_annotation_v1", "magecraft_treasure_status": "annotation_only"}),
        ("Galvanoth", "galvanoth", "auto", "verified", {"effect": "creature", "battle_model_scope": "controller_upkeep_look_top_instant_or_sorcery_may_cast_without_paying_mana_v1", "upkeep_may_cast_top_instant_or_sorcery_without_paying_mana": True}),
        ("Apex of Power", "apex of power", "auto", "active", {"effect": "passive", "battle_model_scope": "impulse_top_seven_plus_hand_cast_mana_annotation_v1", "impulse_top_seven_until_eot": True}),
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
    assert all(package["registry_protected_cut_override_reason"] for package in payload["manifest"]["packages"])
    package_by_cut = {
        package["cuts"][0]: package
        for package in payload["manifest"]["packages"]
    }
    assert package_by_cut["Creative Technique"]["allow_miracle_core_cuts"] is True
    assert "allow_miracle_core_cuts" not in package_by_cut["Bender's Waterskin"]
    storm_rows = [row for row in payload["top_pair_evaluations"] if row["candidate"] == "Storm-Kiln Artist"]
    assert any("candidate_runtime_annotation_only" in row["blockers"] or "candidate_role_mismatch:unknown" in row["blockers"] for row in storm_rows)
    grinding_rows = [row for row in payload["top_pair_evaluations"] if row["candidate"] == "Grinding Station"]
    assert any("candidate_scope_not_same_lane" in row["blockers"] for row in grinding_rows)
    thrumming_rows = [row for row in payload["top_pair_evaluations"] if row["candidate"] == "Thrumming Stone"]
    assert any("candidate_scope_not_same_lane" in row["blockers"] for row in thrumming_rows)


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
