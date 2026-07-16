#!/usr/bin/env python3
"""Sync canonical battle/deckbuilding rules into Hermes SQLite.

This does not infer new rules from scratch. It takes the currently available
generated rules plus any explicitly injected runtime waivers, stores them in
`battle_card_rules`, and makes their source and review state explicit for
battle/optimizer consumers.

For production/Hermes crons, prefer `sync_battle_card_rules_pg.py`: Postgres
stores the reviewable source of truth and this SQLite table acts as the fast
local cache used by simulations.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import sqlite3
from collections import defaultdict
from contextlib import closing
from pathlib import Path

import battle_rule_registry
from battle_rule_registry import (
    DEFAULT_DB,
    ensure_battle_card_rules,
    upsert_battle_card_rule,
)
from known_cards_fallback_snapshot import (
    build_snapshot_payload,
    load_snapshot_file,
    merge_runtime_annotations_from_existing_snapshot,
    write_snapshot_payload,
)
from reviewed_battle_card_rules import (
    DEFAULT_REVIEWED_RULES_PATH,
    load_reviewed_rule_rows,
)


SCRIPT_DIR = Path(__file__).resolve().parent
GENERATED_PATH = SCRIPT_DIR / "known_cards_generated.json"
BATTLE_PATH = Path(os.environ.get("MANALOOM_BATTLE_SCRIPT", SCRIPT_DIR / "battle_analyst_v9.py"))


def load_battle_module(path: Path):
    spec = importlib.util.spec_from_file_location("sync_battle_rules_battle", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battle = load_battle_module(BATTLE_PATH)
DEFAULT_RUNTIME_WAIVERS = frozenset(getattr(battle, "MANUAL_RULE_RUNTIME_WAIVERS", set()))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sqlite-db", default=str(DEFAULT_DB))
    parser.add_argument("--skip-generated", action="store_true")
    parser.add_argument(
        "--reviewed-rules-json",
        default=str(DEFAULT_REVIEWED_RULES_PATH),
    )
    parser.add_argument("--apply", action="store_true")
    parser.add_argument(
        "--export-canonical-fallback-json",
        default=str(SCRIPT_DIR / "known_cards_canonical_snapshot.json"),
    )
    parser.add_argument("--report")
    return parser.parse_args()


def load_generated_rules() -> dict[str, dict]:
    if not GENERATED_PATH.exists():
        return {}
    try:
        decoded = json.loads(GENERATED_PATH.read_text(encoding="utf-8"))
    except Exception:
        return {}
    return decoded if isinstance(decoded, dict) else {}


def _trusted_runtime_effect_shape_is_authoritative(row: dict, effect: dict) -> bool:
    """Return true when Oracle normalization must not rewrite the rule shape."""
    source = str(row.get("source") or "").lower()
    review_status = str(row.get("review_status") or "").lower()
    execution_status = str(row.get("execution_status") or "auto").lower()
    if source not in {"manual", "curated"}:
        return False
    if review_status not in {"verified", "active"}:
        return False
    if execution_status not in {"auto", "executable"}:
        return False

    scope = str(
        effect.get("battle_model_scope")
        or effect.get("oracle_runtime_scope")
        or ""
    )
    if scope and scope != "canonical_snapshot_rule_not_runtime_safe":
        return True
    if effect.get("_composite_rule_components"):
        return True
    if effect.get("xmage_effect_class") or effect.get("xmage_effect_classes"):
        return True
    return False


def _oracle_normalized_rows(sqlite_db: str | Path | None, rows: list[dict]) -> list[dict]:
    """Keep persisted rule cache aligned with runtime oracle normalization.

    The active battle engine normalizes broad generated rules with
    oracle metadata before the spell resolves. If the cache is written without
    the same pass, the forensic audit sees false mismatches like lands stored as
    ramp engines. This mirrors runtime behavior at sync time.
    """
    if not sqlite_db:
        return rows
    db_path = Path(sqlite_db)
    if not db_path.exists():
        return rows

    try:
        with closing(sqlite3.connect(db_path)) as conn:
            conn.row_factory = sqlite3.Row
            oracle_cache = battle.load_card_oracle_cache(
                conn,
                [str(row.get("card_name") or "") for row in rows],
            )
    except Exception:
        return rows

    normalized_rows: list[dict] = []
    for row in rows:
        if row.get("source") == "manual":
            normalized_rows.append(dict(row))
            continue
        card_name = str(row.get("card_name") or "")
        effect_before = dict(row.get("effect_json") or {})
        if _trusted_runtime_effect_shape_is_authoritative(row, effect_before):
            normalized_rows.append(dict(row))
            continue
        card = battle.merge_oracle_metadata({"name": card_name}, oracle_cache)
        effect_after = battle.normalize_effect_by_oracle(card, effect_before)
        review_status = str(row.get("review_status") or "").lower()
        execution_status = str(row.get("execution_status") or "auto").lower()
        trusted_runtime = (
            review_status in {"verified", "active"}
            and execution_status in {"auto", "executable"}
        )
        target_before = str(effect_before.get("target") or "")
        if (
            trusted_runtime
            and effect_before.get("effect") == "remove_permanent"
            and effect_after.get("effect") == "remove_creature"
            and "_or_" in target_before
        ):
            for key in ("effect", "target", "battle_model_scope"):
                if key in effect_before:
                    effect_after[key] = effect_before[key]
        next_row = dict(row)
        next_row["effect_json"] = effect_after
        if effect_after != effect_before:
            next_row["notes"] = (
                f"{next_row.get('notes') or ''} "
                "Oracle-normalized to match battle runtime."
            ).strip()
            next_row["_oracle_normalized"] = True
        normalized_rows.append(next_row)
    return normalized_rows


def build_rows(
    include_generated: bool,
    *,
    sqlite_db: str | Path | None = None,
    reviewed_rules_path: str | Path = DEFAULT_REVIEWED_RULES_PATH,
) -> list[dict]:
    rows: list[dict] = []
    # After the 2026-06-16 canonicalization cleanup, active handwritten rules
    # should normally be empty. This loop remains only for explicit temporary
    # runtime waivers injected by tests or incident response.
    runtime_waivers = set(getattr(battle, "MANUAL_RULE_RUNTIME_WAIVERS", set()))
    # Historical runtime waivers remain inspectable in battle_analyst_v9.py, but
    # sync should only write waivers that were explicitly injected for this run.
    if runtime_waivers == DEFAULT_RUNTIME_WAIVERS:
        runtime_waivers = set()
    for name in sorted(runtime_waivers):
        effect = dict(getattr(battle, "HANDCRAFTED_KNOWN_CARD_RULES", {}).get(name) or {})
        if not effect:
            continue
        rows.append(
            {
                "card_name": name,
                "effect_json": effect,
                "source": "manual",
                "confidence": 1.0,
                "review_status": "verified",
                "notes": "Seeded from MANUAL_RULE_RUNTIME_WAIVERS.",
            }
        )
    rows.extend(load_reviewed_rule_rows(reviewed_rules_path))

    if include_generated:
        for name, effect in sorted(load_generated_rules().items()):
            if name in battle.HANDCRAFTED_KNOWN_CARDS:
                continue
            if not isinstance(effect, dict):
                continue
            rows.append(
                {
                    "card_name": name,
                    "effect_json": dict(effect),
                    "source": "generated",
                    "confidence": 0.55,
                    "review_status": "needs_review",
                    "notes": "Seeded from known_cards_generated.json; audit before trusting.",
                }
            )
    return _oracle_normalized_rows(sqlite_db, rows)


def cleanup_obsolete_manual_rows(conn: sqlite3.Connection) -> int:
    """Purge stale persisted manual overrides before reseeding current waivers.

    `source='manual'` is reserved for explicit `MANUAL_RULE_RUNTIME_WAIVERS`
    injected into the active runtime. Historical handcrafted/manual rows should
    not continue shadowing curated/generated rules in the long-lived SQLite
    cache once the runtime inventory has been canonicalized.
    """
    ensure_battle_card_rules(conn)
    deleted = conn.execute(
        """
        DELETE FROM battle_card_rules
        WHERE source = 'manual'
        """
    ).rowcount
    battle_rule_registry._invalidate_rule_caches_for_connection(conn)
    return int(deleted or 0)


def cleanup_stale_reviewed_rows(
    conn: sqlite3.Connection,
    reviewed_rows: list[dict],
) -> int:
    """Drop stale curated reviewed rows superseded by the current reviewed file.

    When a reviewed rule changes its logical shape, the old `(normalized_name,
    logical_rule_key)` row can survive beside the new one because both are
    `curated/active`. That leaves the canonical snapshot free to pick the wrong
    sibling by lexical tie-break. Reviewed rows should therefore be treated as a
    replace-set per card name.
    """
    ensure_battle_card_rules(conn)
    allowed_by_name: dict[str, set[str]] = defaultdict(set)
    for row in reviewed_rows:
        if str(row.get("source") or "") != "curated":
            continue
        card_name = str(row.get("card_name") or "").strip()
        effect_json = dict(row.get("effect_json") or {})
        if not card_name or not effect_json:
            continue
        normalized = battle_rule_registry.normalize_card_name(card_name)
        allowed_key = str(row.get("logical_rule_key") or "") or (
            battle_rule_registry.logical_rule_key(
                {
                    "effect_json": effect_json,
                    "deck_role_json": row.get("deck_role_json"),
                }
            )
        )
        allowed_by_name[normalized].add(allowed_key)

    deleted = 0
    for normalized_name, allowed_keys in allowed_by_name.items():
        placeholders = ",".join("?" for _ in allowed_keys)
        query = f"""
            DELETE FROM battle_card_rules
            WHERE normalized_name = ?
              AND source = 'curated'
              AND logical_rule_key NOT IN ({placeholders})
        """
        deleted += conn.execute(query, (normalized_name, *sorted(allowed_keys))).rowcount or 0

    battle_rule_registry._invalidate_rule_caches_for_connection(conn)
    return int(deleted or 0)


def load_active_snapshot_rows(sqlite_db: str | Path) -> list[dict]:
    """Load SQLite rules with the metadata required by canonical snapshots."""
    with closing(sqlite3.connect(sqlite_db)) as conn:
        conn.row_factory = sqlite3.Row
        ensure_battle_card_rules(conn)
        active_rows = []
        for row in conn.execute(
            """
            SELECT
                card_name,
                logical_rule_key,
                effect_json,
                source,
                confidence,
                review_status,
                execution_status,
                rule_version,
                oracle_hash,
                updated_at,
                last_seen_at
            FROM battle_card_rules
            """
        ):
            active_rows.append(
                {
                    "card_name": row["card_name"],
                    "logical_rule_key": row["logical_rule_key"],
                    "effect_json": json.loads(row["effect_json"]),
                    "source": row["source"],
                    "confidence": row["confidence"],
                    "review_status": row["review_status"],
                    "execution_status": row["execution_status"],
                    "rule_version": row["rule_version"],
                    "oracle_hash": row["oracle_hash"],
                    "updated_at": row["updated_at"],
                    "last_seen_at": row["last_seen_at"],
                }
            )
    return active_rows


def apply_rows_to_sqlite_cache(sqlite_db: str | Path, rows: list[dict]) -> dict[str, int]:
    """Apply reviewed/generated rows to SQLite without dropping rule identity metadata."""
    report = {
        "inserted_or_updated": 0,
        "skipped_lower_priority": 0,
        "deleted_stale_manual_rows": 0,
        "deleted_stale_reviewed_rows": 0,
    }
    with closing(sqlite3.connect(sqlite_db)) as conn:
        ensure_battle_card_rules(conn)
        report["deleted_stale_manual_rows"] = cleanup_obsolete_manual_rows(conn)
        report["deleted_stale_reviewed_rows"] = cleanup_stale_reviewed_rows(conn, rows)
        for row in rows:
            changed = upsert_battle_card_rule(
                conn,
                row["card_name"],
                row["effect_json"],
                source=row["source"],
                confidence=row["confidence"],
                review_status=row["review_status"],
                execution_status=row.get("execution_status") or "auto",
                deck_role_json=row.get("deck_role_json"),
                notes=row["notes"],
                oracle_hash=row.get("oracle_hash"),
            )
            if changed:
                report["inserted_or_updated"] += 1
            else:
                report["skipped_lower_priority"] += 1
        conn.commit()
    return report


def main() -> int:
    args = parse_args()
    rows = build_rows(
        include_generated=not args.skip_generated,
        sqlite_db=args.sqlite_db,
        reviewed_rules_path=args.reviewed_rules_json,
    )
    report = {
        "sqlite_db": args.sqlite_db,
        "apply": bool(args.apply),
        "export_canonical_fallback_json": args.export_canonical_fallback_json,
        "reviewed_rules_json": args.reviewed_rules_json,
        "input_rows": len(rows),
        "manual_rows": sum(1 for row in rows if row["source"] == "manual"),
        "curated_rows": sum(1 for row in rows if row["source"] == "curated"),
        "generated_rows": sum(1 for row in rows if row["source"] == "generated"),
        "oracle_normalized_rows": sum(1 for row in rows if row.get("_oracle_normalized")),
        "inserted_or_updated": 0,
        "skipped_lower_priority": 0,
        "deleted_stale_manual_rows": 0,
        "deleted_stale_reviewed_rows": 0,
        "canonical_snapshot_rows_exported": 0,
    }

    if args.apply:
        apply_report = apply_rows_to_sqlite_cache(args.sqlite_db, rows)
        report.update(apply_report)

        active_rows = load_active_snapshot_rows(args.sqlite_db)
        payload = build_snapshot_payload(active_rows)
        payload = merge_runtime_annotations_from_existing_snapshot(
            payload,
            load_snapshot_file(args.export_canonical_fallback_json),
        )
        write_snapshot_payload(args.export_canonical_fallback_json, payload)
        report["canonical_snapshot_rows_exported"] = len(payload)

    output = json.dumps(report, ensure_ascii=True, indent=2, sort_keys=True)
    print(output)
    if args.report:
        Path(args.report).write_text(output + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
