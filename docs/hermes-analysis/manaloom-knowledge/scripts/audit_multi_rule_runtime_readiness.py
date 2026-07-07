#!/usr/bin/env python3
"""Audit active multi-rule battle cards against the current runtime behavior.

This script answers a narrow but important question:

"For cards that currently have more than one active `card_battle_rules` row,
how many are already safe to execute together, how many can only merge safe
annotations, and how many still require a dedicated executor/hook/state layer?"

It intentionally reuses the current battle runtime helpers instead of
re-implementing a parallel classification model.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
REGISTRY_PATH = SCRIPT_DIR / "battle_rule_registry.py"
DB_HELPER_PATH = SCRIPT_DIR / "db_helper.py"


def _load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


battle = _load_module("battle_multi_rule_audit_battle", BATTLE_PATH)
registry = _load_module("battle_multi_rule_audit_registry", REGISTRY_PATH)
db_helper = _load_module("battle_multi_rule_audit_db_helper", DB_HELPER_PATH)


def _counter_to_sorted_dict(counter: Counter[str]) -> dict[str, int]:
    return dict(sorted(counter.items(), key=lambda item: (-item[1], item[0])))


def _json_default(value: Any) -> Any:
    if isinstance(value, Decimal):
        if value == value.to_integral_value():
            return int(value)
        return float(value)
    raise TypeError(f"Object of type {value.__class__.__name__} is not JSON serializable")


def _gap_category_from_reason(reason: str) -> str:
    if reason == "activated_ability_requires_executor":
        return "activated_executor_gap"
    if reason == "trigger_requires_event_hook":
        return "trigger_hook_gap"
    if reason == "static_effect_requires_state_layer":
        return "state_layer_gap"
    if reason == "review_status_not_runtime_safe":
        return "review_status_gap"
    if reason == "execution_status_annotation_only":
        return "annotation_only_gap"
    if reason == "execution_status_review_only":
        return "review_only_gap"
    if reason == "execution_status_disabled":
        return "disabled_gap"
    if reason.startswith("blocked_by_"):
        return "guardrail_blocker_gap"
    if reason in {
        "multi_rule_requires_explicit_selector",
        "composable_but_not_opted_as_primary",
    }:
        return "explicit_selector_gap"
    return "other_runtime_gap"


def classify_multi_rule_card(card_name: str, rules: list[dict[str, Any]]) -> dict[str, Any]:
    display_name = next(
        (
            str(rule.get("card_name") or "").strip()
            for rule in rules
            if str(rule.get("card_name") or "").strip()
        ),
        card_name,
    )
    card = {"name": display_name, "type_line": "", "oracle_text": ""}

    composite_effect = battle._build_composite_battle_rule_effect(card, rules)
    safe_annotation_effect = None
    primary_effect = None
    selection_mode = "no_runtime_safe_primary"
    primary_rule = battle._select_primary_runtime_rule(rules)

    if composite_effect is not None:
        selection_mode = "composite_resolution"
        resolved = composite_effect
    else:
        safe_annotation_effect = battle._build_primary_effect_with_safe_secondary_annotations(
            card, rules
        )
        if safe_annotation_effect is not None:
            selection_mode = "single_selected_with_safe_annotations"
            resolved = safe_annotation_effect
        elif primary_rule is not None:
            primary_effect = battle.normalize_effect_by_oracle(
                card,
                battle._annotated_battle_rule_effect(primary_rule),
            )
            selection_mode = "single_selected"
            resolved = battle._annotate_runtime_rule_selection(
                primary_effect,
                rules,
                selection_mode=selection_mode,
            )
        else:
            resolved = {
                "_rule_blocked_alternatives": [
                    {
                        **battle._battle_rule_summary(rule),
                        "runtime_reason": battle._runtime_rule_skip_reason(rule),
                    }
                    for rule in rules
                    if rule
                ]
            }

    blocked = resolved.get("_rule_blocked_alternatives") or []
    blocked_reason_counts = Counter(
        str(entry.get("runtime_reason") or "unknown") for entry in blocked
    )
    effective_blocked_reason_counts = Counter(blocked_reason_counts)
    if selection_mode == "composite_resolution":
        effective_blocked_reason_counts.pop("composable_but_not_opted_as_primary", None)
    gap_categories = sorted(
        {
            _gap_category_from_reason(reason)
            for reason in effective_blocked_reason_counts
            if reason and reason != "unknown"
        }
    )
    merged = resolved.get("_rule_merged_alternatives") or []
    component_rules = resolved.get("_composite_rule_components") or []

    if selection_mode == "composite_resolution":
        overall_status = (
            "composite_resolution_ready"
            if not effective_blocked_reason_counts
            else "composite_resolution_partial"
        )
    elif selection_mode == "single_selected_with_safe_annotations":
        overall_status = (
            "safe_annotation_merge_ready"
            if not blocked
            else "safe_annotation_merge_partial"
        )
    elif selection_mode == "single_selected":
        overall_status = (
            "single_primary_only"
            if not blocked
            else "single_primary_with_blocked_alternatives"
        )
    else:
        overall_status = "no_runtime_safe_primary"

    return {
        "normalized_name": card_name,
        "display_name": display_name,
        "rule_count": len(rules),
        "selection_mode": selection_mode,
        "overall_status": overall_status,
        "primary_logical_rule_key": (
            str(primary_rule.get("logical_rule_key") or "") if primary_rule else None
        ),
        "primary_effect": (
            str((primary_effect or resolved).get("effect") or "")
            if selection_mode != "no_runtime_safe_primary"
            else None
        ),
        "safe_annotation_rule_count": len(merged),
        "composite_component_count": len(component_rules),
        "blocked_reason_counts": _counter_to_sorted_dict(blocked_reason_counts),
        "effective_blocked_reason_counts": _counter_to_sorted_dict(
            effective_blocked_reason_counts
        ),
        "gap_categories": gap_categories,
        "logical_rule_keys": [
            str(rule.get("logical_rule_key") or "")
            for rule in rules
            if rule
        ],
        "rule_summaries": [battle._battle_rule_summary(rule) for rule in rules if rule],
    }


def _load_active_rule_lists_from_pg() -> dict[str, list[dict[str, Any]]]:
    from psycopg2.extras import RealDictCursor

    with db_helper.connect() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                """
                SELECT normalized_name, logical_rule_key, card_name, effect_json, deck_role_json,
                       source, confidence, review_status, execution_status, rule_version, oracle_hash, notes
                FROM card_battle_rules
                WHERE review_status IN ('verified', 'needs_review', 'active')
                  AND COALESCE(execution_status, 'auto') != 'disabled'
                """
            )
            rows = cur.fetchall()

    rules: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        rule = {
            "normalized_name": row["normalized_name"],
            "logical_rule_key": row["logical_rule_key"],
            "card_name": row["card_name"],
            "effect_json": row["effect_json"] or {},
            "deck_role_json": row["deck_role_json"] or {},
            "source": row["source"],
            "confidence": row["confidence"],
            "review_status": row["review_status"],
            "execution_status": row["execution_status"],
            "rule_version": row["rule_version"],
            "oracle_hash": row["oracle_hash"],
            "notes": row["notes"],
        }
        rules.setdefault(row["normalized_name"], []).append(rule)

    for normalized_name, values in rules.items():
        values.sort(key=registry._rule_rank)
    return rules


def build_summary(
    db_path: Path | None = None,
    *,
    use_pg: bool = False,
) -> dict[str, Any]:
    if use_pg:
        rule_lists = _load_active_rule_lists_from_pg()
        source_ref = "postgres_runtime_env"
        source_kind = "postgres"
    else:
        assert db_path is not None
        with sqlite3.connect(db_path) as conn:
            registry.ensure_battle_card_rules(conn)
        rule_lists = registry.load_active_battle_card_rule_lists(db_path)
        source_ref = str(db_path)
        source_kind = "sqlite"
    multi_rule_cards = {
        card_name: rules
        for card_name, rules in rule_lists.items()
        if len(rules) > 1
    }

    details = [
        classify_multi_rule_card(card_name, rules)
        for card_name, rules in sorted(multi_rule_cards.items())
    ]

    overall_status_counts = Counter(entry["overall_status"] for entry in details)
    selection_mode_counts = Counter(entry["selection_mode"] for entry in details)
    gap_category_counts = Counter()
    blocked_reason_counts = Counter()
    for entry in details:
        gap_category_counts.update(entry["gap_categories"])
        blocked_reason_counts.update(entry["blocked_reason_counts"])

    example_cards_by_status: dict[str, list[str]] = {}
    for entry in details:
        bucket = entry["overall_status"]
        example_cards_by_status.setdefault(bucket, [])
        if len(example_cards_by_status[bucket]) < 12:
            example_cards_by_status[bucket].append(entry["display_name"])

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_kind": source_kind,
        "source_ref": source_ref,
        "total_active_rule_names": len(rule_lists),
        "multi_rule_card_count": len(details),
        "multi_rule_rule_count": sum(entry["rule_count"] for entry in details),
        "overall_status_counts": _counter_to_sorted_dict(overall_status_counts),
        "selection_mode_counts": _counter_to_sorted_dict(selection_mode_counts),
        "gap_category_counts": _counter_to_sorted_dict(gap_category_counts),
        "blocked_reason_counts": _counter_to_sorted_dict(blocked_reason_counts),
        "example_cards_by_status": example_cards_by_status,
        "details": details,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=str(registry.DEFAULT_DB))
    parser.add_argument("--pg", action="store_true")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    db_path = Path(args.db)
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    summary = build_summary(db_path, use_pg=args.pg)
    output_path.write_text(
        json.dumps(
            summary,
            indent=2,
            ensure_ascii=False,
            sort_keys=True,
            default=_json_default,
        )
        + "\n",
        encoding="utf-8",
    )
    print(
        json.dumps(
            {
                "event": "MULTI_RULE_RUNTIME_READINESS_AUDIT",
                "output": str(output_path),
                "multi_rule_card_count": summary["multi_rule_card_count"],
                "overall_status_counts": summary["overall_status_counts"],
                "gap_category_counts": summary["gap_category_counts"],
            },
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
