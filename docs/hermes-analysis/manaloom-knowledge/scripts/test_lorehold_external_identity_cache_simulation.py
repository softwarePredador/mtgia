import sqlite3
from pathlib import Path

import lorehold_external_identity_cache_simulation as simulation


def test_queue_from_preflight_splits_combo_runtime():
    payload = {
        "queues": {
            "identity_import_required": [],
            "runtime_or_manual_review_required": ["Brain in a Jar", "Haze of Rage"],
            "shell_contract_required": ["Late to Dinner"],
            "cut_safety_contract_required": [],
        },
        "preflight_rows": [
            {
                "card_name": "Brain in a Jar",
                "route_types": ["topdeck_pressure_reference"],
                "verified_auto_rule_count": 0,
            },
            {
                "card_name": "Haze of Rage",
                "route_types": ["combo_package"],
                "verified_auto_rule_count": 0,
            },
        ],
    }

    queues = simulation.queue_from_preflight(payload)

    assert queues["combo_runtime_required"] == ["Haze of Rage"]
    assert queues["runtime_or_manual_review_required"] == ["Brain in a Jar", "Haze of Rage"]
    assert queues["shell_contract_required"] == ["Late to Dinner"]


def test_sqlite_json_lines_parses_multiple_json_arrays():
    rows = simulation.sqlite_json_lines(
        '[{"existing_cache_rows":0}]\n'
        '[{"name":"Brain"},\n'
        '{"name":"Entreat"}]\n'
    )

    assert rows[0][0]["existing_cache_rows"] == 0
    assert rows[1][0]["name"] == "Brain"
    assert rows[1][1]["name"] == "Entreat"


def test_simulate_applies_and_rolls_back_temp_copy(tmp_path: Path):
    source_db = tmp_path / "source.db"
    with sqlite3.connect(source_db) as conn:
        conn.executescript(
            """
            CREATE TABLE card_oracle_cache (
              normalized_name TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              mana_cost TEXT,
              colors_json TEXT,
              color_identity_json TEXT,
              type_line TEXT,
              oracle_text TEXT,
              cmc REAL,
              power TEXT,
              toughness TEXT,
              keywords_json TEXT,
              scryfall_id TEXT,
              source TEXT,
              updated_at TEXT,
              card_id TEXT
            );
            CREATE TABLE card_legalities (
              card_name TEXT NOT NULL,
              format TEXT NOT NULL,
              status TEXT NOT NULL,
              scryfall_id TEXT,
              PRIMARY KEY (card_name, format)
            );
            CREATE TABLE battle_card_rules (
              normalized_name TEXT,
              logical_rule_key TEXT,
              card_name TEXT,
              review_status TEXT,
              execution_status TEXT
            );
            INSERT INTO card_legalities (card_name, format, status)
            VALUES ('Brain in a Jar', 'commander', 'legal');
            """
        )
    precheck = tmp_path / "precheck.sql"
    apply = tmp_path / "apply.sql"
    postcheck = tmp_path / "postcheck.sql"
    rollback = tmp_path / "rollback.sql"
    precheck.write_text(
        "SELECT COUNT(*) AS existing_cache_rows FROM card_oracle_cache WHERE normalized_name IN ('brain in a jar');",
        encoding="utf-8",
    )
    apply.write_text(
        """
        INSERT INTO card_oracle_cache (
          normalized_name, name, mana_cost, colors_json, color_identity_json, type_line,
          oracle_text, cmc, power, toughness, keywords_json, scryfall_id, source, updated_at, card_id
        ) VALUES (
          'brain in a jar', 'Brain in a Jar', '{2}', '[]', '[]', 'Artifact',
          'text', 2, NULL, NULL, '[]', 'brain-scryfall',
          'lorehold_external_identity_resolution_queue_20260705_current',
          '2026-07-05T00:00:00Z', 'brain-scryfall'
        );
        """,
        encoding="utf-8",
    )
    postcheck.write_text(
        """
        SELECT COUNT(*) AS resolved_cache_rows FROM card_oracle_cache
        WHERE source = 'lorehold_external_identity_resolution_queue_20260705_current';
        SELECT normalized_name, name, 'legal' AS commander_status
        FROM card_oracle_cache;
        """,
        encoding="utf-8",
    )
    rollback.write_text(
        """
        DELETE FROM card_oracle_cache
        WHERE source = 'lorehold_external_identity_resolution_queue_20260705_current';
        SELECT COUNT(*) AS remaining_package_cache_rows FROM card_oracle_cache
        WHERE source = 'lorehold_external_identity_resolution_queue_20260705_current';
        """,
        encoding="utf-8",
    )
    package_report = {
        "summary": {"cache_insert_ready_count": 1},
        "sql_files": {
            "precheck": str(precheck),
            "apply": str(apply),
            "postcheck": str(postcheck),
            "rollback": str(rollback),
        },
    }
    scout_report = {
        "candidate_classifications": [
            {
                "card_name": "Brain in a Jar",
                "classification": "external_missing_from_local_deck_pool",
                "actionability": "requires_import_or_identity_resolution_before_deckbuilding_test",
                "route_types": ["topdeck_pressure_reference"],
                "source_keys": ["unit"],
            }
        ]
    }

    payload = simulation.simulate(
        source_db=source_db,
        scout_report=scout_report,
        scout_path=tmp_path / "scout.json",
        package_path=tmp_path / "package.json",
        package_report=package_report,
    )

    assert payload["status"] == "external_identity_cache_simulation_pass_keep_607"
    assert payload["summary"]["temp_precheck_existing_cache_rows"] == 0
    assert payload["summary"]["temp_postcheck_resolved_cache_rows"] == 1
    assert payload["summary"]["temp_rollback_remaining_direct_count"] == 0
    assert payload["summary"]["source_marker_rows_before"] == 0
    assert payload["summary"]["source_marker_rows_after"] == 0
    assert payload["summary"]["post_apply_identity_missing_count"] == 0
