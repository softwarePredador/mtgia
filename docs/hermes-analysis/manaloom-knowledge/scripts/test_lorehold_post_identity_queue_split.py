import sqlite3
from pathlib import Path

import lorehold_post_identity_queue_split as split


def make_db(path: Path) -> None:
    with sqlite3.connect(path) as conn:
        conn.executescript(
            """
            CREATE TABLE card_oracle_cache (
              normalized_name TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              mana_cost TEXT,
              color_identity_json TEXT,
              type_line TEXT,
              oracle_text TEXT,
              cmc REAL,
              scryfall_id TEXT,
              source TEXT
            );
            CREATE TABLE card_legalities (
              card_name TEXT NOT NULL,
              format TEXT NOT NULL,
              status TEXT NOT NULL
            );
            CREATE TABLE battle_card_rules (
              normalized_name TEXT,
              card_name TEXT,
              review_status TEXT,
              execution_status TEXT
            );
            CREATE TABLE deck_cards (
              deck_id INTEGER NOT NULL,
              card_name TEXT NOT NULL
            );
            INSERT INTO card_oracle_cache
              (normalized_name, name, mana_cost, color_identity_json, type_line, oracle_text, cmc, scryfall_id, source)
            VALUES
              ('karmic guide', 'Karmic Guide', '{3}{W}{W}', '["W"]', 'Creature', 'text', 5, 'karmic-id', 'unit');
            INSERT INTO card_legalities VALUES
              ('Brain in a Jar', 'commander', 'legal'),
              ('Haze of Rage', 'commander', 'legal'),
              ('Karmic Guide', 'commander', 'legal');
            INSERT INTO battle_card_rules VALUES
              ('karmic guide', 'Karmic Guide', 'verified', 'auto');
            """
        )


def test_queue_membership_preserves_multi_queue_combo():
    membership = split.queue_membership(
        {
            "runtime_or_manual_review_required": ["Haze of Rage"],
            "combo_runtime_required": ["Haze of Rage"],
        }
    )

    assert membership["haze of rage"] == [
        "runtime_or_manual_review_required",
        "combo_runtime_required",
    ]


def test_build_payload_routes_identity_combo_and_shell(tmp_path: Path):
    db_path = tmp_path / "knowledge.db"
    make_db(db_path)
    simulation = {
        "post_apply_queues": {
            "runtime_or_manual_review_required": ["Brain in a Jar", "Haze of Rage"],
            "combo_runtime_required": ["Haze of Rage"],
            "shell_contract_required": ["Karmic Guide"],
            "identity_import_required": [],
            "cut_safety_contract_required": [],
        },
        "postcheck_rows": [
            {
                "normalized_name": "brain in a jar",
                "name": "Brain in a Jar",
                "commander_status": "legal",
            },
            {
                "normalized_name": "haze of rage",
                "name": "Haze of Rage",
                "commander_status": "legal",
            },
        ],
    }
    scout_report = {
        "candidate_classifications": [
            {
                "card_name": "Brain in a Jar",
                "route_types": ["topdeck_pressure_reference"],
                "source_keys": ["unit_topdeck"],
            },
            {
                "card_name": "Haze of Rage",
                "route_types": ["combo_package"],
                "source_keys": ["unit_combo"],
            },
            {
                "card_name": "Karmic Guide",
                "route_types": ["archetype_fork"],
                "source_keys": ["unit_reanimator"],
                "verified_auto_rule_count": 1,
            },
        ]
    }

    payload = split.build_payload(
        simulation=simulation,
        simulation_path=tmp_path / "simulation.json",
        scout_report=scout_report,
        scout_path=tmp_path / "scout.json",
        db_path=db_path,
        deck_id=607,
    )

    rows = {row["card_name"]: row for row in payload["cards"]}
    assert payload["status"] == "post_identity_queue_split_no_battle_ready_keep_607"
    assert payload["summary"]["queue_card_count"] == 3
    assert payload["summary"]["battle_ready_now_count"] == 0
    assert rows["Brain in a Jar"]["identity_source"] == "temporary_simulation"
    assert rows["Brain in a Jar"]["route_class"] == "runtime_or_manual_review"
    assert rows["Haze of Rage"]["route_class"] == "combo_runtime_contract"
    assert "combo_runtime_required" in rows["Haze of Rage"]["blockers"]
    assert rows["Karmic Guide"]["identity_source"] == "source_db"
    assert rows["Karmic Guide"]["verified_auto_rule_count"] == 1
    assert rows["Karmic Guide"]["shell_family"] == "white_reanimator_shell"
    assert rows["Karmic Guide"]["battle_ready_now"] is False
    assert any(contract["contract_key"] == "white_reanimator_shell" for contract in payload["contracts"])
