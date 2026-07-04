import sqlite3
from pathlib import Path

import lorehold_restoration_seminar_need_audit as audit


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
            cmc REAL,
            is_commander INTEGER,
            oracle_text TEXT
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE card_oracle_cache (
            normalized_name TEXT,
            name TEXT,
            mana_cost TEXT,
            type_line TEXT,
            oracle_text TEXT,
            cmc REAL
        )
        """
    )
    rows = [
        (607, "Lorehold, the Historian", 1, "engine", '["engine"]', "Legendary Creature", 5, 1, ""),
        (607, "Sensei's Divining Top", 1, "draw", '["draw"]', "Artifact", 1, 0, ""),
        (607, "Arcane Signet", 1, "ramp", '["ramp"]', "Artifact", 2, 0, ""),
        (607, "Lightning Greaves", 1, "protection", '["protection"]', "Artifact - Equipment", 2, 0, ""),
        (607, "Tragic Arrogance", 1, "unknown", '["unknown"]', "Sorcery", 5, 0, ""),
        (607, "Command Tower", 1, "land", '["land"]', "Land", 0, 0, ""),
        (609, "Restoration Seminar", 1, "engine", '["engine","recursion"]', "Sorcery - Lesson", 7, 0, ""),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", rows)
    conn.execute(
        """
        INSERT INTO card_oracle_cache
        VALUES (
          'restoration seminar',
          'Restoration Seminar',
          '{5}{W}{W}',
          'Sorcery - Lesson',
          'Return target nonland permanent card from your graveyard to the battlefield.',
          0
        )
        """
    )
    return conn


def exposure_profiles():
    return [
        (
            Path("profile.json"),
            {
                "card_profiles": [
                    {
                        "card_name": "Restoration Seminar",
                        "unique_exposure_count": 2,
                        "direct_event_count": 0,
                        "inferred_role": "recursion_candidate",
                        "decision": {"status": "review_required"},
                        "role_signals": ["spell_or_permanent_recursion"],
                        "rule_summary": {
                            "active_rule_count": 1,
                            "effects": {"recursion": 1},
                            "battle_model_scopes": {
                                "nonland_permanent_graveyard_to_battlefield_paradigm_v1": 1
                            },
                        },
                    }
                ]
            },
        )
    ]


def test_target_model_excludes_lands_sorceries_and_commander():
    with memory_db() as conn:
        cards = audit.load_deck_cards(conn, 607)
    names = [card["name"] for card in cards if audit.is_nonland_permanent(card)]
    assert names == ["Arcane Signet", "Lightning Greaves", "Sensei's Divining Top"]

    top = audit.target_priority(
        next(card for card in cards if card["name"] == "Sensei's Divining Top"),
        graveyard_events=1,
    )
    assert top["target_priority_score"] > 50
    assert "topdeck_miracle_engine" in top["reasons"]
    assert "observed_graveyard_target" in top["reasons"]


def test_collect_graveyard_events_counts_only_current_targets():
    report = {
        "events": [
            {
                "event": "permanent_moved_from_battlefield",
                "data": {
                    "card": "Sensei's Divining Top",
                    "from_zone": "battlefield",
                    "to_zone": "graveyard",
                    "turn": 4,
                },
            },
            {
                "event": "permanent_moved_from_battlefield",
                "data": {
                    "card": "Command Tower",
                    "from_zone": "battlefield",
                    "to_zone": "graveyard",
                },
            },
        ]
    }
    result = audit.collect_graveyard_events(
        [(Path("trace.json"), report)],
        ["Sensei's Divining Top", "Lightning Greaves"],
    )
    assert result["counts"] == {"Sensei's Divining Top": 1}
    assert result["samples"][0]["card"] == "Sensei's Divining Top"


def test_build_audit_blocks_when_no_target_trace():
    with memory_db() as conn:
        payload = audit.build_audit(
            conn=conn,
            deck_id=607,
            db_path=Path("memory.db"),
            exposure_profiles=exposure_profiles(),
            trace_reports=[],
            recursion_model_report=Path("missing.json"),
        )
    assert payload["status"] == "blocked_no_current_target_graveyard_trace"
    assert payload["summary"]["nonland_permanent_target_count"] == 3
    assert payload["summary"]["target_graveyard_event_count"] == 0
    assert payload["restoration_seminar"]["cmc"] == 7
