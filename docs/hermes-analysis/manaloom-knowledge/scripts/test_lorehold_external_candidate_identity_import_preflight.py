import sqlite3
from pathlib import Path

import lorehold_external_candidate_identity_import_preflight as preflight


def make_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
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
          scryfall_id TEXT,
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
          normalized_name TEXT NOT NULL,
          logical_rule_key TEXT NOT NULL,
          card_name TEXT NOT NULL,
          review_status TEXT NOT NULL,
          execution_status TEXT NOT NULL,
          PRIMARY KEY (normalized_name, logical_rule_key)
        );
        CREATE TABLE format_staples (
          card_name TEXT NOT NULL,
          format TEXT NOT NULL,
          archetype TEXT DEFAULT '',
          category TEXT DEFAULT '',
          edhrec_rank INTEGER,
          is_banned INTEGER DEFAULT 0,
          PRIMARY KEY (card_name, format, archetype, category)
        );
        """
    )
    conn.executemany(
        """
        INSERT INTO card_legalities (card_name, format, status)
        VALUES (?, 'commander', 'legal')
        """,
        [
            ("Brain in a Jar",),
            ("Burning Prophet",),
            ("Haze of Rage",),
            ("Karmic Guide",),
        ],
    )
    conn.executemany(
        """
        INSERT INTO card_oracle_cache (
          normalized_name, name, color_identity_json, type_line, oracle_text, cmc, card_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        [
            ("burning prophet", "Burning Prophet", '["R"]', "Creature - Human Wizard", "scry text", 2, "burning-id"),
            ("karmic guide", "Karmic Guide", '["W"]', "Creature - Angel Spirit", "reanimate text", 5, "karmic-id"),
        ],
    )
    conn.execute(
        """
        INSERT INTO battle_card_rules (
          normalized_name, logical_rule_key, card_name, review_status, execution_status
        ) VALUES ('karmic guide', 'karmic_guide_runtime_v1', 'Karmic Guide', 'verified', 'auto')
        """
    )
    return conn


def scout_report() -> dict:
    return {
        "candidate_classifications": [
            {
                "card_name": "Brain in a Jar",
                "classification": "external_missing_from_local_deck_pool",
                "actionability": "requires_import_or_identity_resolution_before_deckbuilding_test",
                "route_types": ["topdeck_pressure_reference"],
                "source_keys": ["gametyrant_miracle_topdeck_pressure"],
            },
            {
                "card_name": "Burning Prophet",
                "classification": "external_missing_from_local_deck_pool",
                "actionability": "requires_import_or_identity_resolution_before_deckbuilding_test",
                "route_types": ["topdeck_pressure_reference"],
                "source_keys": ["gametyrant_miracle_topdeck_pressure"],
            },
            {
                "card_name": "Haze of Rage",
                "classification": "external_missing_from_local_deck_pool",
                "actionability": "combo_package_research_only_requires_runtime_cut_and_battle_proof",
                "route_types": ["combo_package"],
                "source_keys": ["commander_spellbook_storm_kiln_haze"],
            },
            {
                "card_name": "Karmic Guide",
                "classification": "rule_known_external_not_in_lorehold_candidate_pool",
                "actionability": "archetype_fork_only_requires_full_shell_contract",
                "route_types": ["archetype_fork"],
                "source_keys": ["card_kingdom_reanimator_direction"],
            },
        ]
    }


def build_payload() -> dict:
    return preflight.build_payload(
        make_conn(),
        db_path=Path("/tmp/knowledge.db"),
        scout_report=scout_report(),
        scout_path=Path("/tmp/scout.json"),
    )


def test_preflight_blocks_gate_and_keeps_607():
    payload = build_payload()

    assert payload["status"] == "external_identity_preflight_blocks_gate_keep_607"
    assert payload["summary"]["material_candidate_count"] == 4
    assert payload["summary"]["promotion_allowed"] is False
    assert payload["decision"]["natural_battle_allowed_now"] is False


def test_identity_runtime_and_shell_queues_are_split():
    payload = build_payload()
    rows = {row["card_name"]: row for row in payload["preflight_rows"]}

    assert rows["Brain in a Jar"]["preflight_status"] == "identity_import_required"
    assert rows["Haze of Rage"]["preflight_status"] == "identity_import_required_before_combo_runtime"
    assert rows["Burning Prophet"]["preflight_status"] == "runtime_rule_or_manual_review_required"
    assert rows["Karmic Guide"]["preflight_status"] == "shell_contract_required_not_one_for_one_cut"
    assert payload["queues"]["identity_import_required"] == ["Brain in a Jar", "Haze of Rage"]
    assert payload["queues"]["runtime_or_manual_review_required"] == ["Burning Prophet"]
    assert payload["queues"]["shell_contract_required"] == ["Karmic Guide"]


def test_markdown_surfaces_preflight_rows_and_queues():
    markdown = preflight.render_markdown(build_payload())

    assert "Lorehold External Candidate Identity Import Preflight" in markdown
    assert "Preflight Rows" in markdown
    assert "Queues" in markdown
    assert "Burning Prophet" in markdown
