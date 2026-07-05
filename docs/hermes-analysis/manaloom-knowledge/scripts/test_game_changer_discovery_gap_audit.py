import sqlite3
from pathlib import Path

import game_changer_discovery_gap_audit as audit


def make_conn(*, with_game_changers_table: bool = False) -> sqlite3.Connection:
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.executescript(
        """
        CREATE TABLE deck_cards (
            deck_id INTEGER,
            card_name TEXT,
            quantity INTEGER
        );
        CREATE TABLE card_oracle_cache (
            normalized_name TEXT PRIMARY KEY,
            name TEXT,
            mana_cost TEXT,
            color_identity_json TEXT,
            type_line TEXT,
            oracle_text TEXT,
            cmc REAL,
            scryfall_id TEXT,
            card_id TEXT
        );
        CREATE TABLE card_legalities (
            card_name TEXT,
            format TEXT,
            status TEXT
        );
        CREATE TABLE format_staples (
            card_name TEXT,
            format TEXT,
            archetype TEXT,
            category TEXT,
            color_identity TEXT,
            edhrec_rank INTEGER,
            is_banned INTEGER,
            scryfall_id TEXT
        );
        """
    )
    conn.executemany(
        "INSERT INTO deck_cards VALUES (607, ?, 1)",
        [("Sol Ring",), ("Mana Vault",)],
    )
    conn.executemany(
        "INSERT INTO card_oracle_cache VALUES (?, ?, ?, ?, ?, ?, ?, NULL, NULL)",
        [
            ("mana vault", "Mana Vault", "{1}", "[]", "Artifact", "{T}: Add mana.", 1),
            ("the one ring", "The One Ring", "{4}", "[]", "Legendary Artifact", "{T}: Draw.", 4),
        ],
    )
    conn.executemany(
        "INSERT INTO card_legalities VALUES (?, 'commander', 'legal')",
        [("Mana Vault",), ("The One Ring",), ("Missing Oracle",)],
    )
    conn.execute(
        "INSERT INTO format_staples VALUES ('Mana Vault', 'commander', 'ramp', '', '', 144, 0, NULL)"
    )
    if with_game_changers_table:
        conn.execute("CREATE TABLE game_changers (card_name TEXT)")
        conn.executemany(
            "INSERT INTO game_changers VALUES (?)",
            [("Mana Vault",), ("The One Ring",), ("Missing Oracle",)],
        )
    return conn


def write_inputs(tmp_path: Path) -> dict[str, Path]:
    policy = tmp_path / "edh_bracket_policy.dart"
    policy.write_text(
        "const officialGameChangerNamesForBracketPolicy = <String>{\n"
        "  'mana vault',\n"
        "  'the one ring',\n"
        "  'missing oracle',\n"
        "};\n",
        encoding="utf-8",
    )
    collection = tmp_path / "collection.csv"
    collection.write_text(
        "Card (EN),Quantidade\n"
        "The One Ring,1\n",
        encoding="utf-8",
    )
    return {"policy": policy, "collection": collection}


def test_game_changer_gap_audit_separates_staple_and_identity_gaps(tmp_path):
    paths = write_inputs(tmp_path)
    with make_conn() as conn:
        payload = audit.build_audit(
            conn=conn,
            db_path=Path("memory.db"),
            bracket_policy_path=paths["policy"],
            collection_path=paths["collection"],
            deck_id=607,
        )

    assert payload["status"] == "game_changer_discovery_gap_found_report_only"
    assert payload["summary"]["game_changers_in_policy"] == 3
    assert payload["summary"]["game_changers_table_present"] is False
    assert payload["summary"]["format_staples_present_count"] == 1
    assert payload["summary"]["format_staples_missing_count"] == 2
    assert payload["summary"]["oracle_missing_count"] == 1
    assert payload["summary"]["lorehold_legal_color_allowed_missing_format_staples_count"] == 1

    rows = {row["card_name"]: row for row in payload["rows"]}
    assert rows["mana vault"]["status"] == "discovery_ready_in_format_staples"
    assert rows["the one ring"]["status"] == "discovery_gap_missing_format_staples"
    assert rows["the one ring"]["collection_quantity"] == 1
    assert rows["missing oracle"]["status"] == "identity_gap_missing_oracle_cache"

    assert payload["decision"]["no_deck_promotion"] is True


def test_game_changers_table_status_detects_synced_table(tmp_path):
    paths = write_inputs(tmp_path)
    with make_conn(with_game_changers_table=True) as conn:
        payload = audit.build_audit(
            conn=conn,
            db_path=Path("memory.db"),
            bracket_policy_path=paths["policy"],
            collection_path=paths["collection"],
            deck_id=607,
        )

    assert payload["summary"]["game_changers_table_present"] is True
    assert payload["summary"]["game_changers_table_missing_count"] == 0


def test_markdown_lists_lorehold_relevant_missing_rows(tmp_path):
    paths = write_inputs(tmp_path)
    with make_conn() as conn:
        payload = audit.build_audit(
            conn=conn,
            db_path=Path("memory.db"),
            bracket_policy_path=paths["policy"],
            collection_path=paths["collection"],
            deck_id=607,
        )

    markdown = audit.render_markdown(payload)

    assert "Game Changer Discovery Gap Audit" in markdown
    assert "the one ring" in markdown
    assert "no_deck_promotion: `true`" in markdown
