import json
import sqlite3
from pathlib import Path

import lorehold_role_tag_repair_synthesis as synth


def make_conn(*, omit_rule_for: str | None = None) -> sqlite3.Connection:
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.executescript(
        """
        CREATE TABLE deck_cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER,
            card_name TEXT,
            quantity INTEGER,
            functional_tag TEXT,
            functional_tags_json TEXT,
            card_id TEXT,
            type_line TEXT,
            oracle_text TEXT,
            cmc REAL,
            is_commander INTEGER
        );
        CREATE TABLE card_oracle_cache (
            normalized_name TEXT PRIMARY KEY,
            name TEXT,
            mana_cost TEXT,
            type_line TEXT,
            oracle_text TEXT,
            color_identity_json TEXT,
            cmc REAL,
            card_id TEXT
        );
        CREATE TABLE battle_card_rules (
            normalized_name TEXT,
            logical_rule_key TEXT,
            card_name TEXT,
            effect_json TEXT,
            deck_role_json TEXT,
            source TEXT,
            confidence REAL,
            review_status TEXT,
            execution_status TEXT,
            notes TEXT
        );
        """
    )
    rows = [
        ("Deflecting Swat", "draw", ["draw", "protection", "redirect_removal"], "Instant", "You may choose new targets for target spell or ability.", "redirect control_commander", "protection", "redirect_removal"),
        ("Emeria's Call // Emeria, Shattered Skyclave", "unknown", ["unknown"], "Sorcery", "Create two 4/4 white Angel Warrior tokens. Non-Angel creatures you control gain indestructible.", "token_maker indestructible", "board_development", "token_maker"),
        ("Promise of Loyalty", "draw", ["draw"], "Sorcery", "Each player puts a vow counter on a creature and sacrifices the rest.", "sacrifice vow", "interaction", "vow_counter_each_player_sacrifice_rest"),
        ("Redirect Lightning", "draw", ["draw"], "Instant", "Change the target of target spell or ability with a single target.", "redirect single_target", "protection", "redirect_removal"),
        ("Tragic Arrogance", "unknown", ["unknown"], "Sorcery", "Each player sacrifices all other nonland permanents.", "sacrifice nonland", "interaction", "selective_nonland_sacrifice"),
    ]
    for idx, (name, primary, tags, type_line, oracle_text, rule_tokens, category, effect) in enumerate(rows, start=1):
        card_id = f"card-{idx}"
        conn.execute(
            """
            INSERT INTO deck_cards
              (deck_id, card_name, quantity, functional_tag, functional_tags_json,
               card_id, type_line, oracle_text, cmc, is_commander)
            VALUES (607, ?, 1, ?, ?, ?, ?, ?, 3, 0)
            """,
            (name, primary, json.dumps(tags), card_id, type_line, oracle_text),
        )
        conn.execute(
            """
            INSERT INTO card_oracle_cache
              (normalized_name, name, mana_cost, type_line, oracle_text,
               color_identity_json, cmc, card_id)
            VALUES (?, ?, '', ?, ?, '[]', 3, ?)
            """,
            (synth.normalize_name(name), name, type_line, oracle_text, card_id),
        )
        if name != omit_rule_for:
            conn.execute(
                """
                INSERT INTO battle_card_rules
                  (normalized_name, logical_rule_key, card_name, effect_json,
                   deck_role_json, source, confidence, review_status,
                   execution_status, notes)
                VALUES (?, ?, ?, ?, ?, 'curated', 0.9, 'verified', 'auto', ?)
                """,
                (
                    synth.normalize_name(name),
                    f"rule-{idx}",
                    name,
                    json.dumps({"effect": effect, "battle_model_scope": rule_tokens}),
                    json.dumps({"category": category, "effect": effect}),
                    rule_tokens,
                ),
            )
    return conn


def build_payload(*, apply_sqlite: bool = False, omit_rule_for: str | None = None) -> dict:
    with make_conn(omit_rule_for=omit_rule_for) as conn:
        return synth.build_synthesis(
            conn=conn,
            db_path=Path("memory.db"),
            deck_id=607,
            apply_sqlite=apply_sqlite,
        )


def test_repair_synthesis_is_ready_with_exact_updates():
    payload = build_payload()

    assert payload["status"] == "role_tag_repair_ready"
    assert payload["summary"]["eligible_update_count_before"] == 5
    assert payload["summary"]["blocker_count_before"] == 0
    deflecting = {row["card_name"]: row for row in payload["before_repair"]}["Deflecting Swat"]
    assert deflecting["current_primary"] == "draw"
    assert deflecting["recommended_primary"] == "protection"
    assert deflecting["recommended_tags"] == ["protection", "redirect_removal"]
    assert "functional_tag = 'draw'" in payload["sql"]["rollback_sqlite"]


def test_apply_sqlite_updates_rows_and_clears_remaining_updates():
    with make_conn() as conn:
        payload = synth.build_synthesis(
            conn=conn,
            db_path=Path("memory.db"),
            deck_id=607,
            apply_sqlite=True,
        )
        rows = conn.execute(
            """
            SELECT card_name, functional_tag, functional_tags_json
            FROM deck_cards
            ORDER BY card_name
            """
        ).fetchall()

    assert payload["status"] == "role_tag_repair_applied"
    assert payload["summary"]["updated_count"] == 5
    assert payload["summary"]["remaining_update_count"] == 0
    by_name = {row["card_name"]: row for row in rows}
    assert by_name["Tragic Arrogance"]["functional_tag"] == "board_wipe"
    assert json.loads(by_name["Redirect Lightning"]["functional_tags_json"]) == [
        "protection",
        "redirect_removal",
        "interaction",
    ]


def test_missing_active_rule_blocks_repair():
    payload = build_payload(omit_rule_for="Tragic Arrogance")

    assert payload["status"] == "role_tag_repair_blocked"
    blocked = {row["card_name"]: row for row in payload["before_repair"]}["Tragic Arrogance"]
    assert "missing_active_battle_rule" in blocked["blockers"]


def test_markdown_surfaces_apply_and_rollback_sql():
    payload = build_payload()
    markdown = synth.render_markdown(payload)

    assert "Lorehold Role/Tag Repair Synthesis" in markdown
    assert "Deflecting Swat" in markdown
    assert "## Apply SQL" in markdown
    assert "## Rollback SQL" in markdown
