#!/usr/bin/env python3
"""Audit runtime fallback drift between generated known-cards JSON and canonical SQLite rules.

Purpose:
- measure how far `known_cards_generated.json` is from the reviewed
  `battle_card_rules` cache that the runtime prefers;
- optionally export a canonical fallback snapshot that mirrors the current
  runtime precedence without changing the active runtime automatically.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import sqlite3
from collections import Counter
from pathlib import Path
from typing import Any

from battle_rule_registry import DEFAULT_DB, logical_rule_key, normalize_card_name
from known_cards_fallback_snapshot import build_snapshot_payload


SCRIPT_DIR = Path(__file__).resolve().parent
GENERATED_PATH = Path(
    os.environ.get("MANALOOM_KNOWN_CARDS_OUT", SCRIPT_DIR / "known_cards_generated.json")
)
BATTLE_PATH = Path(
    os.environ.get("MANALOOM_BATTLE_SCRIPT", SCRIPT_DIR / "battle_analyst_v9.py")
)


def load_battle_module(path: Path):
    spec = importlib.util.spec_from_file_location("audit_known_cards_runtime_fallback_battle", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battle = load_battle_module(BATTLE_PATH)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sqlite-db", default=str(DEFAULT_DB))
    parser.add_argument("--generated-json", default=str(GENERATED_PATH))
    parser.add_argument("--report")
    parser.add_argument("--export-canonical-json")
    parser.add_argument("--sample-limit", type=int, default=12)
    return parser.parse_args()


def load_generated_rules(path: str | Path) -> dict[str, dict[str, Any]]:
    payload = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        return {}
    return {
        str(name): dict(effect)
        for name, effect in payload.items()
        if isinstance(name, str) and isinstance(effect, dict)
    }


def load_sqlite_rules(sqlite_db: str | Path) -> list[dict[str, Any]]:
    conn = sqlite3.connect(str(sqlite_db))
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    cur.execute(
        """
        SELECT normalized_name, card_name, effect_json, source, confidence,
               review_status, rule_version, oracle_hash
        FROM battle_card_rules
        ORDER BY normalized_name
        """
    )
    rows = []
    for row in cur.fetchall():
        effect_json = row["effect_json"]
        if isinstance(effect_json, str):
            effect_json = json.loads(effect_json)
        if not isinstance(effect_json, dict):
            effect_json = {}
        rule_row = {
            "normalized_name": str(row["normalized_name"]),
            "card_name": str(row["card_name"]),
            "effect_json": effect_json,
            "source": str(row["source"]),
            "confidence": float(row["confidence"] or 0.0),
            "review_status": str(row["review_status"]),
            "rule_version": int(row["rule_version"] or 0),
            "oracle_hash": row["oracle_hash"],
        }
        rule_row["logical_rule_key"] = logical_rule_key(rule_row)
        rows.append(rule_row)
    conn.close()
    return rows


def build_oracle_cache(sqlite_db: str | Path, card_names: list[str]) -> dict[str, dict[str, Any]]:
    conn = sqlite3.connect(str(sqlite_db))
    conn.row_factory = sqlite3.Row
    try:
        return battle.load_card_oracle_cache(conn, card_names)
    finally:
        conn.close()


def runtime_normalize_effect(
    card_name: str,
    effect_json: dict[str, Any],
    oracle_cache: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    merged_card = battle.merge_oracle_metadata({"name": card_name}, oracle_cache)
    return battle.normalize_effect_by_oracle(merged_card, dict(effect_json or {}))


def strip_private_rule_metadata(effect_json: dict[str, Any]) -> dict[str, Any]:
    return {
        key: value
        for key, value in dict(effect_json or {}).items()
        if not str(key).startswith("_")
    }


def build_canonical_snapshot(
    sqlite_rows: list[dict[str, Any]],
    generated_rules: dict[str, dict[str, Any]],
    oracle_cache: dict[str, dict[str, Any]],
) -> dict[str, dict[str, Any]]:
    snapshot_rows: list[dict[str, Any]] = []
    seen_names: set[str] = set()

    for row in sqlite_rows:
        snapshot_rows.append(
            {
                "card_name": row["card_name"],
                "effect_json": strip_private_rule_metadata(
                    runtime_normalize_effect(
                        row["card_name"],
                        row["effect_json"],
                        oracle_cache,
                    )
                ),
                "source": row["source"],
                "review_status": row["review_status"],
                "confidence": row.get("confidence", 0.0),
                "rule_version": row.get("rule_version"),
                "logical_rule_key": row.get("logical_rule_key"),
                "oracle_hash": row.get("oracle_hash"),
            }
        )
        seen_names.add(row["normalized_name"])

    for card_name, effect_json in generated_rules.items():
        normalized_name = normalize_card_name(card_name)
        if normalized_name in seen_names:
            continue
        snapshot_rows.append(
            {
                "card_name": card_name,
                "effect_json": strip_private_rule_metadata(
                    runtime_normalize_effect(card_name, effect_json, oracle_cache)
                ),
                "source": "known_cards_generated",
                "review_status": "needs_review",
                "confidence": 0.55,
                "rule_version": None,
                "logical_rule_key": None,
                "oracle_hash": None,
            }
        )

    return build_snapshot_payload(snapshot_rows)


def build_summary(
    sqlite_rows: list[dict[str, Any]],
    generated_rules: dict[str, dict[str, Any]],
    oracle_cache: dict[str, dict[str, Any]],
    *,
    sample_limit: int,
) -> dict[str, Any]:
    sqlite_by_name = {row["normalized_name"]: row for row in sqlite_rows}
    generated_by_name = {
        normalize_card_name(card_name): {"card_name": card_name, "effect_json": effect_json}
        for card_name, effect_json in generated_rules.items()
    }

    overlap = sorted(set(sqlite_by_name) & set(generated_by_name))
    generated_only = sorted(set(generated_by_name) - set(sqlite_by_name))
    sqlite_only = sorted(set(sqlite_by_name) - set(generated_by_name))

    source_review_counts = Counter(
        (row["source"], row["review_status"]) for row in sqlite_rows
    )
    raw_exact = 0
    raw_different = 0
    runtime_exact = 0
    runtime_effect_same_but_structural = 0
    runtime_effect_different = 0
    runtime_effect_different_by_source: Counter[str] = Counter()
    samples_runtime_effect_different: list[dict[str, Any]] = []
    samples_runtime_structural_only: list[dict[str, Any]] = []

    for normalized_name in overlap:
        sqlite_row = sqlite_by_name[normalized_name]
        generated_row = generated_by_name[normalized_name]
        sqlite_raw = dict(sqlite_row["effect_json"])
        generated_raw = dict(generated_row["effect_json"])

        if sqlite_raw == generated_raw:
            raw_exact += 1
        else:
            raw_different += 1

        sqlite_runtime = strip_private_rule_metadata(
            runtime_normalize_effect(
                sqlite_row["card_name"],
                sqlite_raw,
                oracle_cache,
            )
        )
        generated_runtime = strip_private_rule_metadata(
            runtime_normalize_effect(
                generated_row["card_name"],
                generated_raw,
                oracle_cache,
            )
        )

        if sqlite_runtime == generated_runtime:
            runtime_exact += 1
            continue

        if sqlite_runtime.get("effect") == generated_runtime.get("effect"):
            runtime_effect_same_but_structural += 1
            if len(samples_runtime_structural_only) < sample_limit:
                samples_runtime_structural_only.append(
                    {
                        "card_name": sqlite_row["card_name"],
                        "source": sqlite_row["source"],
                        "effect": sqlite_runtime.get("effect"),
                    }
                )
            continue

        runtime_effect_different += 1
        runtime_effect_different_by_source[sqlite_row["source"]] += 1
        if len(samples_runtime_effect_different) < sample_limit:
            samples_runtime_effect_different.append(
                {
                    "card_name": sqlite_row["card_name"],
                    "source": sqlite_row["source"],
                    "review_status": sqlite_row["review_status"],
                    "generated_effect": generated_runtime.get("effect"),
                    "canonical_effect": sqlite_runtime.get("effect"),
                }
            )

    return {
        "sqlite_rule_rows": len(sqlite_rows),
        "generated_rule_rows": len(generated_rules),
        "source_review_counts": [
            {
                "source": source,
                "review_status": review_status,
                "count": count,
            }
            for (source, review_status), count in sorted(source_review_counts.items())
        ],
        "overlap_names": len(overlap),
        "generated_only_names": len(generated_only),
        "sqlite_only_names": len(sqlite_only),
        "generated_only_sample": generated_only[:sample_limit],
        "sqlite_only_sample": [sqlite_by_name[name]["card_name"] for name in sqlite_only[:sample_limit]],
        "raw_exact_matches": raw_exact,
        "raw_different_matches": raw_different,
        "runtime_exact_matches": runtime_exact,
        "runtime_effect_same_but_structural": runtime_effect_same_but_structural,
        "runtime_effect_different": runtime_effect_different,
        "runtime_effect_different_by_source": dict(sorted(runtime_effect_different_by_source.items())),
        "runtime_effect_different_samples": samples_runtime_effect_different,
        "runtime_structural_only_samples": samples_runtime_structural_only,
    }


def main() -> int:
    args = parse_args()
    generated_rules = load_generated_rules(args.generated_json)
    sqlite_rows = load_sqlite_rules(args.sqlite_db)
    oracle_cache = build_oracle_cache(
        args.sqlite_db,
        sorted(
            {
                row["card_name"] for row in sqlite_rows
            }
            | {
                card_name for card_name in generated_rules
            }
        ),
    )
    canonical_snapshot = build_canonical_snapshot(sqlite_rows, generated_rules, oracle_cache)
    summary = build_summary(
        sqlite_rows,
        generated_rules,
        oracle_cache,
        sample_limit=max(1, int(args.sample_limit)),
    )
    summary["generated_json"] = str(Path(args.generated_json))
    summary["sqlite_db"] = str(Path(args.sqlite_db))
    summary["canonical_snapshot_rows"] = len(canonical_snapshot)

    output = json.dumps(summary, ensure_ascii=True, indent=2, sort_keys=True)
    print(output)

    if args.report:
        Path(args.report).write_text(output + "\n", encoding="utf-8")
    if args.export_canonical_json:
        Path(args.export_canonical_json).write_text(
            json.dumps(canonical_snapshot, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
