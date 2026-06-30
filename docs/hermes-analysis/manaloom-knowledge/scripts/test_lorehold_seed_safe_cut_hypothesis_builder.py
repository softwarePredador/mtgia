import json
import sqlite3
import tempfile
from pathlib import Path

import lorehold_seed_safe_cut_hypothesis_builder as builder


def write_json(path: Path, payload: dict):
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def build_source_db(path: Path):
    conn = sqlite3.connect(path)
    conn.execute(
        """
        CREATE TABLE deck_cards (
            deck_id INTEGER,
            card_name TEXT,
            quantity INTEGER,
            functional_tag TEXT,
            functional_tags_json TEXT,
            cmc REAL,
            type_line TEXT,
            is_commander INTEGER,
            oracle_text TEXT
        )
        """
    )
    rows = [
        (607, "Lorehold, the Historian", 1, "engine", "[]", 5, "Legendary Creature", 1, ""),
        (607, "Arcane Signet", 1, "ramp", "[\"ramp\"]", 2, "Artifact", 0, "Add one mana."),
        (607, "Creative Technique", 1, "wincon", "[\"wincon\"]", 5, "Sorcery", 0, ""),
        (607, "Quiet Study", 1, "draw", "[\"draw\"]", 2, "Enchantment", 0, ""),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", rows)
    conn.commit()
    conn.close()


def empty_replanner():
    return {"followups": []}


def exposure_profile():
    return {
        "card_profiles": [
            {
                "card_name": "Arcane Signet",
                "unique_exposure_count": 176,
                "direct_event_count": 114,
                "inferred_role": "ramp_engine",
            },
            {
                "card_name": "Creative Technique",
                "unique_exposure_count": 12,
                "direct_event_count": 2,
                "inferred_role": "big_spell_value",
            },
            {
                "card_name": "Quiet Study",
                "unique_exposure_count": 3,
                "direct_event_count": 0,
                "inferred_role": "draw_filter_value",
            },
        ]
    }


def test_seed_safe_builder_finds_explicit_low_exposure_flex_slot():
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        source_db = tmp / "knowledge.db"
        manual = tmp / "manual.json"
        strategy = tmp / "strategy.json"
        exposure = tmp / "exposure.json"
        replanner = tmp / "replanner.json"
        build_source_db(source_db)
        write_json(
            manual,
            {
                "cut_evidence_expansion": {
                    "rows": [
                        {"card_name": "Arcane Signet", "status": "blocked_by_prior_rejection"},
                        {"card_name": "Creative Technique", "status": "same_lane_only"},
                        {"card_name": "Quiet Study", "status": "seed_safe_candidate"},
                    ]
                }
            },
        )
        write_json(
            strategy,
            {
                "cut_safety_manifest": {
                    "cuts": [],
                    "untested_flex_pool": [
                        {
                            "card_name": "Quiet Study",
                            "decision": "support_flex",
                            "status": "core_support",
                            "package_lane": "draw",
                        },
                        {
                            "card_name": "Arcane Signet",
                            "decision": "support_flex",
                            "status": "core_support",
                            "package_lane": "early_mana",
                        },
                    ],
                }
            },
        )
        write_json(exposure, exposure_profile())
        write_json(replanner, empty_replanner())

        payload = builder.build_report(
            source_db=source_db,
            deck_id=607,
            manual_review_path=manual,
            strategy_audit_path=strategy,
            exposure_profile_path=exposure,
            safe_cut_replanner_path=replanner,
        )

    assert payload["postgres_writes"] is False
    assert payload["source_db_mutated"] is False
    assert payload["summary"]["seed_safe_cut_ready_count"] == 1
    assert payload["summary"]["ready_cut_cards"] == ["Quiet Study"]
    assert payload["manifest"]["cut_slots"][0]["cut_card"] == "Quiet Study"
    by_card = {row["card_name"]: row for row in payload["cut_slots"]}
    assert by_card["Arcane Signet"]["status"] == "blocked"
    assert "early_mana_floor_support" in by_card["Arcane Signet"]["blockers"]
    assert by_card["Creative Technique"]["status"] == "same_lane_only_not_seed_safe"


def test_seed_safe_builder_reports_zero_when_only_protected_or_same_lane_slots_exist():
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        source_db = tmp / "knowledge.db"
        manual = tmp / "manual.json"
        strategy = tmp / "strategy.json"
        exposure = tmp / "exposure.json"
        replanner = tmp / "replanner.json"
        build_source_db(source_db)
        write_json(
            manual,
            {
                "cut_evidence_expansion": {
                    "rows": [
                        {"card_name": "Arcane Signet", "status": "blocked_by_prior_rejection"},
                        {"card_name": "Creative Technique", "status": "same_lane_only"},
                        {"card_name": "Quiet Study", "status": "structural_dependency"},
                    ]
                }
            },
        )
        write_json(
            strategy,
            {
                "cut_safety_manifest": {
                    "cuts": [],
                    "untested_flex_pool": [
                        {
                            "card_name": "Quiet Study",
                            "decision": "support_flex",
                            "status": "core_support",
                            "package_lane": "draw",
                        }
                    ],
                }
            },
        )
        write_json(exposure, exposure_profile())
        write_json(replanner, {"followups": [{"cuts": ["Quiet Study"], "blockers": ["prior_rejected_cut"]}]})

        payload = builder.build_report(
            source_db=source_db,
            deck_id=607,
            manual_review_path=manual,
            strategy_audit_path=strategy,
            exposure_profile_path=exposure,
            safe_cut_replanner_path=replanner,
        )

    assert payload["summary"]["seed_safe_cut_ready_count"] == 0
    assert payload["summary"]["recommended_next_action"] == (
        "expand_cut_safety_model_or_multi_card_shell_before_gate"
    )
    assert payload["manifest"]["cut_slots"] == []
    by_card = {row["card_name"]: row for row in payload["cut_slots"]}
    assert "structural_dependency" in by_card["Quiet Study"]["blockers"]
    assert "prior_rejected_cut" in by_card["Quiet Study"]["blockers"]
