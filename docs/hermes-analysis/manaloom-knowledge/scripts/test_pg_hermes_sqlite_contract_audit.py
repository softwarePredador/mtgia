#!/usr/bin/env python3
from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path

import pg_hermes_sqlite_contract_audit as audit


def create_contract_table(conn: sqlite3.Connection, table: str) -> None:
    columns = sorted(audit.SQLITE_REQUIRED_COLUMNS[table])
    ddl = ", ".join(f"{column} TEXT" for column in columns)
    conn.execute(f"CREATE TABLE {table} ({ddl})")


def insert_contract_row(
    conn: sqlite3.Connection,
    table: str,
    **overrides: str,
) -> None:
    values = {
        column: "value"
        for column in audit.SQLITE_REQUIRED_COLUMNS[table]
    }
    for column in ("effect_json", "deck_role_json"):
        if column in values:
            values[column] = "{}"
    for column in (
        "colors_json",
        "color_identity_json",
        "keywords_json",
        "functional_tags_json",
        "semantic_tags_v2_json",
        "battle_rules_json",
        "card_list",
    ):
        if column in values:
            values[column] = "[]"
    defaults = {
        "card_id": "11111111-1111-1111-1111-111111111111",
        "card_name": "Worldfire",
        "deck_id": "6",
        "execution_status": "auto",
        "format": "commander",
        "is_commander": "0",
        "is_partner": "0",
        "logical_rule_key": "battle_rule_v1:test",
        "normalized_name": "worldfire",
        "quantity": "1",
        "review_status": "verified",
        "source": "postgres_cards" if table == "card_oracle_cache" else "curated",
        "status": "legal",
    }
    for column, value in defaults.items():
        if column in values:
            values[column] = value
    values.update(overrides)
    columns = sorted(values)
    placeholders = ",".join("?" for _ in columns)
    conn.execute(
        f"INSERT INTO {table} ({','.join(columns)}) VALUES ({placeholders})",
        [values[column] for column in columns],
    )


class PgHermesSqliteContractAuditTests(unittest.TestCase):
    def test_complete_sqlite_contract_passes_without_pg(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            conn = sqlite3.connect(db_path)
            try:
                for table in audit.SQLITE_REQUIRED_COLUMNS:
                    create_contract_table(conn, table)
                    insert_contract_row(conn, table)
                insert_contract_row(
                    conn,
                    "card_legalities",
                    card_name="Mana Crypt",
                    status="banned",
                )
                conn.commit()
            finally:
                conn.close()

            report = audit.build_report(db_path, skip_pg=True)

        failures = [check for check in report["checks"] if check["status"] == "fail"]
        self.assertEqual(failures, [])
        self.assertEqual(report["status"], "pass")

    def test_missing_sqlite_column_fails_contract(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            conn = sqlite3.connect(db_path)
            try:
                for table in audit.SQLITE_REQUIRED_COLUMNS:
                    create_contract_table(conn, table)
                    insert_contract_row(conn, table)
                conn.execute("DROP TABLE card_oracle_cache")
                conn.execute(
                    """
                    CREATE TABLE card_oracle_cache (
                      normalized_name TEXT,
                      name TEXT,
                      source TEXT,
                      updated_at TEXT
                    )
                    """
                )
                conn.execute(
                    """
                    INSERT INTO card_oracle_cache
                    (normalized_name, name, source, updated_at)
                    VALUES ('sol ring', 'Sol Ring', 'postgres_cards', 'now')
                    """
                )
                conn.commit()
            finally:
                conn.close()

            report = audit.build_report(db_path, skip_pg=True)

        failed_names = {check["name"] for check in report["checks"] if check["status"] == "fail"}
        self.assertIn("sqlite_schema.card_oracle_cache", failed_names)
        self.assertEqual(report["status"], "fail")

    def test_deck_card_id_drift_from_oracle_cache_fails_contract(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            conn = sqlite3.connect(db_path)
            try:
                for table in audit.SQLITE_REQUIRED_COLUMNS:
                    create_contract_table(conn, table)
                    insert_contract_row(conn, table)
                conn.execute("DELETE FROM deck_cards")
                conn.execute("DELETE FROM card_oracle_cache")
                insert_contract_row(
                    conn,
                    "deck_cards",
                    deck_id="607",
                    card_name="Sol Ring",
                    card_id="",
                )
                insert_contract_row(
                    conn,
                    "card_oracle_cache",
                    normalized_name="sol ring",
                    name="Sol Ring",
                    card_id="11111111-1111-1111-1111-111111111111",
                    source="postgres_cards",
                )
                insert_contract_row(
                    conn,
                    "card_legalities",
                    card_name="Mana Crypt",
                    status="banned",
                )
                conn.commit()
            finally:
                conn.close()

            report = audit.build_report(db_path, skip_pg=True)

        checks = {check["name"]: check for check in report["checks"]}
        drift = checks["sqlite_integrity.deck_cards_card_id_cache_drift"]
        self.assertEqual(drift["status"], "fail")
        self.assertEqual(
            drift["detail"],
            "deck_cards_rows_with_card_id_drift=1",
        )
        self.assertEqual(report["status"], "fail")

    def test_name_alias_with_matching_card_id_passes_contract(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            conn = sqlite3.connect(db_path)
            try:
                for table in audit.SQLITE_REQUIRED_COLUMNS:
                    create_contract_table(conn, table)
                    insert_contract_row(conn, table)
                conn.execute("DELETE FROM deck_cards")
                conn.execute("DELETE FROM card_oracle_cache")
                insert_contract_row(
                    conn,
                    "deck_cards",
                    deck_id="607",
                    card_name="Birgi, God of Storytelling",
                    card_id="22222222-2222-2222-2222-222222222222",
                )
                insert_contract_row(
                    conn,
                    "card_oracle_cache",
                    normalized_name="birgi, god of storytelling",
                    name="Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                    card_id="22222222-2222-2222-2222-222222222222",
                    source="postgres_cards",
                )
                insert_contract_row(
                    conn,
                    "card_legalities",
                    card_name="Mana Crypt",
                    status="banned",
                )
                conn.commit()
            finally:
                conn.close()

            report = audit.build_report(db_path, skip_pg=True)

        failures = [check for check in report["checks"] if check["status"] == "fail"]
        checks = {check["name"]: check for check in report["checks"]}
        self.assertEqual(failures, [])
        self.assertEqual(
            checks["sqlite_integrity.deck_cards_name_aliases_canonicalized_by_card_id"]["detail"],
            "name_alias_rows_with_matching_card_id=1",
        )
        self.assertEqual(report["status"], "pass")


if __name__ == "__main__":
    unittest.main()
