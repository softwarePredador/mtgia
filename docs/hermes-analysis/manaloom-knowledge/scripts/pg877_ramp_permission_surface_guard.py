#!/usr/bin/env python3
"""Read-only PG877 guard for persisted Hermes deck/tag surfaces."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sqlite3
import unicodedata
from pathlib import Path
from typing import Any, Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_DB = Path(
    os.environ.get("MANALOOM_KNOWLEDGE_DB")
    or os.environ.get("HERMES_KNOWLEDGE_DB")
    or SCRIPT_DIR / "knowledge.db"
)
DEFAULT_MANIFEST = SCRIPT_DIR.parents[1] / (
    "PG877_RAMP_PERMISSION_FALSE_POSITIVE_MANIFEST_2026-07-16.json"
)
TARGET_ID_SHA = "b8e4fa337a747efadfd6cb1ab57ed5796e75de7387f3c85fd39cb3f4e742cc98"
DECK_SURFACE_SHA = "e859a54145ba15384a5be5607feece42a0a06fb4bddf55d6fa9880d0bc9c1058"
VARIANT_SURFACE_SHA = "95c8cb598cf179666428e9542558b6ff63f6b8a2cfca9d5d0713bd74d8d85a03"
PROTECTED_DECK_ID = 6
PROTECTED_DECK_HASH = "a83b580d42e20ef7fdf285e6498fb3972ce07b54fa6b7359abac8717476014b4"

DECK_FIELDS = (
    "deck_id",
    "card_id",
    "card_name",
    "quantity",
    "is_commander",
    "is_partner",
    "functional_tag",
    "functional_tags_json",
    "semantic_tags_v2_json",
)
VARIANT_FIELDS = (
    "deck_hash",
    "card_name",
    "input_name",
    "normalized_name",
    "quantity",
    "is_commander",
    "functional_tag",
    "functional_tags_json",
)


def _normalize_name(value: Any) -> str:
    normalized = unicodedata.normalize("NFKC", str(value or ""))
    normalized = normalized.replace("’", "'").casefold().split(" // ", 1)[0]
    return " ".join(normalized.split())


def _sha_lines(values: Iterable[str]) -> str:
    return hashlib.sha256("\n".join(sorted(values)).encode("utf-8")).hexdigest()


def _surface_hash(rows: list[sqlite3.Row], fields: tuple[str, ...]) -> str:
    return _sha_lines(
        "|".join("" if row[field] is None else str(row[field]) for field in fields)
        for row in rows
    )


def _contains_ramp_json(value: Any) -> bool:
    if value is None or value == "":
        return False
    parsed = json.loads(value) if isinstance(value, str) else value
    return _parsed_contains_ramp(parsed)


def _parsed_contains_ramp(parsed: Any) -> bool:
    if isinstance(parsed, str):
        return parsed.casefold() == "ramp"
    if isinstance(parsed, list):
        return any(_parsed_contains_ramp(item) for item in parsed)
    if isinstance(parsed, dict):
        return str(parsed.get("tag", "")).casefold() == "ramp" or any(
            _parsed_contains_ramp(item) for item in parsed.values()
        )
    return False


def _row_has_ramp(row: sqlite3.Row, *, semantic: bool) -> bool:
    if str(row["functional_tag"] or "").strip().casefold() == "ramp":
        return True
    if _contains_ramp_json(row["functional_tags_json"]):
        return True
    return semantic and _contains_ramp_json(row["semantic_tags_v2_json"])


def inspect_surfaces(sqlite_db: Path, manifest_path: Path) -> dict[str, Any]:
    errors: list[str] = []
    report: dict[str, Any] = {
        "status": "PG877_HERMES_SURFACE_GUARD_ABORT",
        "sqlite_db": str(sqlite_db.resolve()),
        "manifest": str(manifest_path.resolve()),
        "read_only": True,
        "errors": errors,
    }
    if not sqlite_db.is_file() or not manifest_path.is_file():
        errors.append("required_input_missing")
        return report

    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        targets = manifest["target_cards"]
        target_ids = {str(row["card_id"]).lower() for row in targets}
        target_names = {_normalize_name(row["card_name"]) for row in targets}
    except (KeyError, TypeError, json.JSONDecodeError) as exc:
        errors.append(f"manifest_invalid:{type(exc).__name__}")
        return report

    manifest_sha = _sha_lines(target_ids)
    report["manifest_scope"] = {
        "target_count": len(target_ids),
        "target_id_sha256": manifest_sha,
    }
    if len(target_ids) != 115 or manifest_sha != TARGET_ID_SHA:
        errors.append("manifest_scope_drift")

    conn = sqlite3.connect(f"file:{sqlite_db.resolve()}?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row
    try:
        conn.execute("PRAGMA query_only=ON")
        deck_rows = list(conn.execute(
            "SELECT deck_id, card_id, card_name, quantity, is_commander, "
            "is_partner, functional_tag, functional_tags_json, "
            "semantic_tags_v2_json FROM deck_cards"
        ))
        variant_rows = list(conn.execute(
            "SELECT deck_hash, card_name, input_name, normalized_name, quantity, "
            "is_commander, functional_tag, functional_tags_json "
            "FROM lorehold_variant_deck_cards"
        ))
        protected_rows = list(conn.execute(
            "SELECT card_name, deck_hash FROM deck_cards WHERE deck_id=?",
            (PROTECTED_DECK_ID,),
        ))
    except sqlite3.DatabaseError as exc:
        errors.append(f"sqlite_read_failed:{type(exc).__name__}")
        return report
    finally:
        conn.close()

    target_deck_rows = [
        row for row in deck_rows if _normalize_name(row["card_name"]) in target_names
    ]
    target_variant_rows = [
        row for row in variant_rows if _normalize_name(row["card_name"]) in target_names
    ]
    try:
        deck_ramp_rows = sum(
            _row_has_ramp(row, semantic=True) for row in target_deck_rows
        )
        variant_ramp_rows = sum(
            _row_has_ramp(row, semantic=False) for row in target_variant_rows
        )
    except json.JSONDecodeError:
        errors.append("surface_json_invalid")
        deck_ramp_rows = -1
        variant_ramp_rows = -1

    deck_sha = _surface_hash(target_deck_rows, DECK_FIELDS)
    variant_sha = _surface_hash(target_variant_rows, VARIANT_FIELDS)
    protected_hashes = sorted({str(row["deck_hash"] or "") for row in protected_rows})
    protected_target_rows = sum(
        _normalize_name(row["card_name"]) in target_names for row in protected_rows
    )
    report["hermes_deck_cards"] = {
        "row_count": len(target_deck_rows),
        "deck_count": len({row["deck_id"] for row in target_deck_rows}),
        "card_count": len({_normalize_name(row["card_name"]) for row in target_deck_rows}),
        "ramp_row_count": deck_ramp_rows,
        "surface_sha256": deck_sha,
    }
    report["lorehold_variant_deck_cards"] = {
        "row_count": len(target_variant_rows),
        "card_count": len({_normalize_name(row["card_name"]) for row in target_variant_rows}),
        "ramp_row_count": variant_ramp_rows,
        "surface_sha256": variant_sha,
    }
    report["protected_deck"] = {
        "deck_id": PROTECTED_DECK_ID,
        "row_count": len(protected_rows),
        "target_row_count": protected_target_rows,
        "stored_deck_hashes": protected_hashes,
    }

    if (len(target_deck_rows), len({row["deck_id"] for row in target_deck_rows})) != (12, 9):
        errors.append("hermes_deck_membership_drift")
    if len({_normalize_name(row["card_name"]) for row in target_deck_rows}) != 6:
        errors.append("hermes_deck_card_scope_drift")
    if deck_ramp_rows != 0 or deck_sha != DECK_SURFACE_SHA:
        errors.append("hermes_deck_tag_surface_drift")
    if len(target_variant_rows) != 1 or variant_ramp_rows != 0:
        errors.append("variant_membership_or_ramp_drift")
    if variant_sha != VARIANT_SURFACE_SHA:
        errors.append("variant_surface_drift")
    if len(protected_rows) != 94 or protected_target_rows != 0:
        errors.append("protected_deck_membership_drift")
    if protected_hashes != [PROTECTED_DECK_HASH]:
        errors.append("protected_deck_hash_drift")

    if not errors:
        report["status"] = "PG877_HERMES_SURFACE_GUARD_PASS"
    return report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    args = parser.parse_args()
    report = inspect_surfaces(args.db, args.manifest)
    print(json.dumps(report, ensure_ascii=False, sort_keys=True))
    return 0 if report["status"] == "PG877_HERMES_SURFACE_GUARD_PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
