import sqlite3
from pathlib import Path

import lorehold_current_champion_snapshot as snapshot


def make_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.execute(
        """
        CREATE TABLE deck_cards (
            deck_id INTEGER,
            card_name TEXT NOT NULL,
            quantity INTEGER DEFAULT 1,
            functional_tag TEXT,
            is_commander INTEGER DEFAULT 0,
            cmc REAL,
            type_line TEXT,
            card_id TEXT,
            deck_hash TEXT,
            semantics_hash TEXT,
            ruleset_hash TEXT
        )
        """
    )
    cards = [
        ("Lorehold, the Historian", 1, "engine", 1, "Legendary Creature"),
        ("Sensei's Divining Top", 1, "draw", 0, "Artifact"),
        ("Scroll Rack", 1, "draw", 0, "Artifact"),
        ("Approach of the Second Sun", 1, "wincon", 0, "Sorcery"),
        ("Victory Chimes", 1, "ramp", 0, "Artifact"),
        ("Mizzix's Mastery", 1, "recursion", 0, "Sorcery"),
        ("Bender's Waterskin", 1, "ramp", 0, "Artifact"),
        ("Jeska's Will", 1, "ramp", 0, "Sorcery"),
        ("Library of Leng", 1, "engine", 0, "Artifact"),
        ("Mountain", 46, "mana_base", 0, "Basic Land"),
        ("Plains", 45, "mana_base", 0, "Basic Land"),
    ]
    conn.executemany(
        """
        INSERT INTO deck_cards (
            deck_id, card_name, quantity, functional_tag, is_commander, cmc,
            type_line, card_id, deck_hash, semantics_hash, ruleset_hash
        )
        VALUES (607, ?, ?, ?, ?, 1, ?, NULL, 'deck-hash', 'sem-hash', 'rule-hash')
        """,
        cards,
    )
    return conn


def test_current_champion_snapshot_keeps_607_when_micro_model_has_no_safe_cuts():
    conn = make_conn()
    micro_model = {
        "summary": {
            "ready_micro_package_count": 0,
            "seed_safe_cut_ready_count": 0,
        },
        "protected_anchor_evidence": {
            "top_anchor_card_deficits": [
                {"event": "topdeck_manipulation_activated:Sensei's Divining Top"},
                {"event": "spell_resolved:Approach of the Second Sun"},
            ]
        },
    }
    planner = {
        "summary": {
            "recommended_next_action": (
                "freeze_607_current_champion_snapshot_until_new_cut_evidence"
            )
        }
    }

    payload = snapshot.build_snapshot(
        conn=conn,
        deck_id=607,
        db_path=Path("/tmp/knowledge.db"),
        micro_package_model=micro_model,
        planner_report=planner,
        micro_package_model_path=Path("/tmp/micro.json"),
        planner_report_path=Path("/tmp/planner.json"),
    )

    assert payload["postgres_writes"] is False
    assert payload["source_db_mutated"] is False
    assert payload["status"] == "current_champion_snapshot"
    assert payload["summary"]["total_cards"] == 100
    assert payload["summary"]["commander_count"] == 1
    assert payload["summary"]["missing_protected_anchor_count"] == 0
    assert payload["summary"]["planner_recommended_next_action"] == (
        "freeze_607_current_champion_snapshot_until_new_cut_evidence"
    )
    assert payload["champion_decision"]["decision"] == "keep_607_as_current_champion"
    assert payload["hash_summary"]["deck_hashes"] == ["deck-hash"]
