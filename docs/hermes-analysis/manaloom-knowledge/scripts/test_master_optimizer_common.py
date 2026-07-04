import sqlite3

from master_optimizer_common import (
    parse_mana_cost_cmc,
    safe_cmc_from_card,
    sqlite_connection_has_table,
)


def test_parse_mana_cost_cmc_handles_common_symbols():
    assert parse_mana_cost_cmc("{5}{W}{W}") == 7
    assert parse_mana_cost_cmc("{2/R}") == 2
    assert parse_mana_cost_cmc("{R/W}") == 1
    assert parse_mana_cost_cmc("{X}{R}") == 1
    assert parse_mana_cost_cmc("") is None


def test_safe_cmc_from_card_uses_mana_cost_when_nonland_cmc_is_zero():
    assert (
        safe_cmc_from_card(
            {
                "name": "Restoration Seminar",
                "type_line": "Sorcery - Lesson",
                "mana_cost": "{5}{W}{W}",
                "cmc": 0,
            }
        )
        == 7
    )
    assert safe_cmc_from_card({"type_line": "Artifact", "mana_cost": "{0}", "cmc": 0}) == 0
    assert safe_cmc_from_card({"type_line": "Basic Land - Mountain", "cmc": None}) == 0


def test_sqlite_connection_has_table_is_safe_for_old_fixtures():
    conn = sqlite3.connect(":memory:")
    try:
        assert sqlite_connection_has_table(conn, "card_oracle_cache") is False
        conn.execute("CREATE TABLE card_oracle_cache (name TEXT)")
        assert sqlite_connection_has_table(conn, "card_oracle_cache") is True
    finally:
        conn.close()
