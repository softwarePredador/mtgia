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
    ]
    variant_rows = [
        (608, "Lightning Bolt", "removal", '["removal"]', 1, "Instant", "Deal 3 damage to any target."),
        (609, "Erode", "removal", '["removal"]', 2, "Sorcery", "Destroy target creature or planeswalker."),
        (610, "Untimely Malfunction", "removal", '["removal"]', 2, "Instant", "Destroy target artifact."),
        (611, "Red Elemental Blast", "removal", '["removal"]', 1, "Instant", "Counter target blue spell or destroy target blue permanent."),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?)", current_rows + variant_rows)
    rules = [
        ("Winds of Abandon", "winds of abandon", "active", "active", {"effect": "remove_creature", "battle_model_scope": "exile_target_creature"}),
        ("Stroke of Midnight", "stroke of midnight", "active", "active", {"effect": "remove_permanent", "battle_model_scope": "destroy_target_nonland_permanent"}),
        ("Lightning Bolt", "lightning bolt", "active", "active", {"effect": "direct_damage", "battle_model_scope": "damage_any_target"}),
        ("Erode", "erode", "active", "active", {"effect": "remove_permanent", "battle_model_scope": "destroy_target_creature_planeswalker"}),
        ("Untimely Malfunction", "untimely malfunction", "active", "active", {"effect": "remove_permanent", "battle_model_scope": "destroy_target_artifact"}),
        ("Red Elemental Blast", "red elemental blast", "active", "active", {"effect": "modal_spell", "battle_model_scope": "counter_target_blue_spell_or_destroy_target_blue_permanent"}),
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
                    "cut_exposure": {"inferred_role": "ramp"},
                },
            ]
        }
    }


def test_generator_selects_same_lane_removal_package_and_manifest():
    with build_conn() as conn:
        payload = generator.build_report(
            conn=conn,
            manual_review=manual_review(),
            prior_results={"by_signature": {}},
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


def test_generator_blocks_unsupported_profiled_cuts():
    with build_conn() as conn:
        payload = generator.build_report(
            conn=conn,
            manual_review=manual_review(),
            prior_results={"by_signature": {}},
            db_path=Path("memory.db"),
            manual_review_path=Path("manual_review.json"),
            variant_deck_ids=[608, 609, 610],
        )

    blocked = {row["card_name"]: row for row in payload["blocked_cut_rows"]}
    assert "Bender's Waterskin" in blocked
    assert blocked["Bender's Waterskin"]["cut_exposure"]["inferred_role"] == "ramp"
    assert all(package["cuts"] != ["Bender's Waterskin"] for package in payload["manifest"]["packages"])


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
            db_path=Path("memory.db"),
            manual_review_path=Path("manual_review.json"),
            variant_deck_ids=[608],
        )

    assert not payload["selected_pairs"]
    blocked = [row for row in payload["top_pair_evaluations"] if row["candidate"] == "Lightning Bolt"]
    assert any("prior_exact_reject" in row["blockers"] for row in blocked)
