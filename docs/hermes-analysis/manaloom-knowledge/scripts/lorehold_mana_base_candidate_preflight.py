#!/usr/bin/env python3
"""Preflight an isolated Lorehold 607 mana-base candidate before battle smoke.

The preflight consumes the candidate materializer report and compares the
protected source DB with the copied candidate DB. Passing this preflight only
allows a diagnostic smoke battle; it never allows promotion.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from master_optimizer_common import connect, deck_rows, get_deck_summary, normalize_name


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_MATERIALIZER_REPORT = (
    REPORT_DIR / "lorehold_mana_base_candidate_materializer_20260705_plateau_turbulent_current.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_mana_base_candidate_preflight_20260705_plateau_turbulent_current"
DEFAULT_DECK_ID = 607

PROTECTED_ANCHORS = (
    "Bender's Waterskin",
    "Creative Technique",
    "Land Tax",
    "Library of Leng",
    "Lorehold, the Historian",
    "Mizzix's Mastery",
    "Molecule Man",
    "Scroll Rack",
    "Sensei's Divining Top",
    "Storm Herd",
    "The Mind Stone",
    "The Scarlet Witch",
    "Victory Chimes",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def json_list(value: Any) -> list[Any]:
    if isinstance(value, list):
        return value
    try:
        decoded = json.loads(str(value or "[]"))
    except Exception:
        return []
    return decoded if isinstance(decoded, list) else []


def slug(value: str) -> str:
    return normalize_name(value).replace(" ", "_").replace("'", "")


def card_counter(rows: list[sqlite3.Row]) -> Counter[str]:
    counter: Counter[str] = Counter()
    for row in rows:
        counter[normalize_name(str(row["card_name"]))] += int(row["quantity"] or 1)
    return counter


def row_by_name(rows: list[sqlite3.Row]) -> dict[str, sqlite3.Row]:
    return {normalize_name(str(row["card_name"])): row for row in rows}


def card_diff(source_rows: list[sqlite3.Row], candidate_rows: list[sqlite3.Row]) -> dict[str, Any]:
    source = card_counter(source_rows)
    candidate = card_counter(candidate_rows)
    added = []
    removed = []
    for name in sorted(set(source) | set(candidate)):
        delta = candidate.get(name, 0) - source.get(name, 0)
        if delta > 0:
            added.append({"normalized_name": name, "quantity_delta": delta})
        elif delta < 0:
            removed.append({"normalized_name": name, "quantity_delta": -delta})
    return {"added": added, "removed": removed}


def functional_tag_counts(rows: list[sqlite3.Row], *, include_lands: bool) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        type_line = str(row["type_line"] or "")
        tag = str(row["functional_tag"] or "unknown")
        is_land = tag == "land" or "Land" in type_line
        if include_lands or not is_land:
            counts[tag] += int(row["quantity"] or 1)
    return dict(sorted(counts.items()))


def active_rule_count(row: sqlite3.Row | None) -> int:
    if row is None or "battle_rules_json" not in row.keys():
        return 0
    count = 0
    for rule in json_list(row["battle_rules_json"]):
        if not isinstance(rule, Mapping):
            continue
        status = str(rule.get("execution_status") or "")
        review = str(rule.get("review_status") or "")
        if status not in {"disabled", "review_only", ""} and review in {"verified", "active", "needs_review"}:
            count += 1
    return count


def anchor_status(source_rows: list[sqlite3.Row], candidate_rows: list[sqlite3.Row]) -> dict[str, Any]:
    source_by_name = row_by_name(source_rows)
    candidate_by_name = row_by_name(candidate_rows)
    anchors = []
    missing = []
    changed = []
    for name in PROTECTED_ANCHORS:
        key = normalize_name(name)
        source = source_by_name.get(key)
        candidate = candidate_by_name.get(key)
        if source is None or candidate is None:
            missing.append(name)
            anchors.append({"card_name": name, "status": "missing"})
            continue
        compared_fields = ("quantity", "functional_tag", "card_id", "type_line", "oracle_text")
        field_deltas = {
            field: {"source": source[field], "candidate": candidate[field]}
            for field in compared_fields
            if str(source[field] or "") != str(candidate[field] or "")
        }
        status = "unchanged" if not field_deltas else "changed"
        if field_deltas:
            changed.append(name)
        anchors.append({"card_name": name, "status": status, "field_deltas": field_deltas})
    return {
        "status": "pass" if not missing and not changed else "fail",
        "anchor_count": len(PROTECTED_ANCHORS),
        "missing": missing,
        "changed": changed,
        "anchors": anchors,
    }


def validate_preflight(
    *,
    source_db: Path,
    candidate_db: Path,
    deck_id: int,
    add: str,
    cut: str,
) -> dict[str, Any]:
    with connect(source_db) as source_conn, connect(candidate_db) as candidate_conn:
        source_rows = deck_rows(source_conn, deck_id)
        candidate_rows = deck_rows(candidate_conn, deck_id)
        source_summary = get_deck_summary(source_conn, deck_id)
        candidate_summary = get_deck_summary(candidate_conn, deck_id)

    source_by_name = row_by_name(source_rows)
    candidate_by_name = row_by_name(candidate_rows)
    add_key = normalize_name(add)
    cut_key = normalize_name(cut)
    add_row = candidate_by_name.get(add_key)
    cut_row = source_by_name.get(cut_key)
    diff = card_diff(source_rows, candidate_rows)
    anchors = anchor_status(source_rows, candidate_rows)
    nonland_source_tags = functional_tag_counts(source_rows, include_lands=False)
    nonland_candidate_tags = functional_tag_counts(candidate_rows, include_lands=False)

    added_names = {row["normalized_name"] for row in diff["added"]}
    removed_names = {row["normalized_name"] for row in diff["removed"]}
    add_is_land = bool(add_row and "Land" in str(add_row["type_line"] or ""))
    cut_is_land = bool(cut_row and "Land" in str(cut_row["type_line"] or ""))
    checks = {
        "source_total_cards_100": int(source_summary["cards"]) == 100,
        "candidate_total_cards_100": int(candidate_summary["cards"]) == 100,
        "source_land_quantity_34": int(source_summary["lands"]) == 34,
        "candidate_land_quantity_34": int(candidate_summary["lands"]) == 34,
        "single_add_single_cut": len(diff["added"]) == 1 and len(diff["removed"]) == 1,
        "expected_add_only": added_names == {add_key},
        "expected_cut_only": removed_names == {cut_key},
        "same_lane_land_swap": add_is_land and cut_is_land,
        "nonland_role_counts_unchanged": nonland_source_tags == nonland_candidate_tags,
        "protected_anchors_unchanged": anchors["status"] == "pass",
        "add_has_card_id": bool(add_row and str(add_row["card_id"] or "").strip()),
        "add_has_oracle_text": bool(add_row and str(add_row["oracle_text"] or "").strip()),
        "add_has_active_land_rule": active_rule_count(add_row) > 0,
        "candidate_hash_differs_from_source": source_summary["hash"] != candidate_summary["hash"],
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "checks": checks,
        "diff": diff,
        "source_deck_summary": source_summary,
        "candidate_deck_summary": candidate_summary,
        "nonland_role_counts": {
            "source": nonland_source_tags,
            "candidate": nonland_candidate_tags,
        },
        "protected_anchor_status": anchors,
        "added_card_runtime": {
            "card_name": add,
            "active_rule_count": active_rule_count(add_row),
            "card_id": add_row["card_id"] if add_row is not None else None,
            "type_line": add_row["type_line"] if add_row is not None else None,
        },
    }


def build_payload(
    *,
    materializer_report_path: Path = DEFAULT_MATERIALIZER_REPORT,
    out_prefix: Path = DEFAULT_OUT_PREFIX,
    deck_id: int = DEFAULT_DECK_ID,
) -> dict[str, Any]:
    materializer_report = read_json(materializer_report_path)
    source_db = REPO_ROOT / str(materializer_report["source_db"])
    candidate_db = REPO_ROOT / str(materializer_report["candidate_db"])
    summary = materializer_report.get("summary") or {}
    add = str(summary.get("add") or "")
    cut = str(summary.get("cut") or "")
    candidate_slug = f"{slug(add)}_{slug(cut)}"
    validation = validate_preflight(
        source_db=source_db,
        candidate_db=candidate_db,
        deck_id=deck_id,
        add=add,
        cut=cut,
    )
    pass_status = validation["status"] == "pass"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_mana_base_candidate_preflight",
        "status": "battle_smoke_preflight_ready" if pass_status else "battle_smoke_preflight_blocked",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": [rel(materializer_report_path)],
        "source_db": rel(source_db),
        "candidate_db": rel(candidate_db),
        "summary": {
            "deck_id": deck_id,
            "add": add,
            "cut": cut,
            "allow_smoke_battle_gate": pass_status,
            "allow_promotion_gate": False,
            "promotion_allowed": False,
            "keep_607_as_protected_baseline": True,
        },
        "preflight_validation": validation,
        "policy": {
            "allowed_gate": "diagnostic smoke battle only",
            "promotion_gate": "closed until same-opponent/seed confirmation, fast-pressure guard, and replay trace evidence pass",
            "card_level_claim": "a battle aggregate is not enough; added/cut land access must be inspected in telemetry or focused traces",
        },
        "recommended_battle_command": [
            f"MANALOOM_FOCUS_ACCESS_CARDS='{json.dumps([add, cut])}'",
            "python3",
            "docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_battle_gate.py",
            "--db",
            rel(source_db),
            "--deck-ids",
            str(deck_id),
            "--candidate-db",
            rel(candidate_db),
            "--candidate-key",
            f"candidate_607_{candidate_slug}_mana_base_v1",
            "--candidate-name",
            f"Lorehold 607 mana base: {add} over {cut}",
            "--candidate-archetype",
            "mana-base-diagnostic",
            "--candidate-deck-id",
            str(deck_id),
            "--fixed-opponent-deck-ids",
            str(deck_id),
            "--games",
            "1",
            "--opponent-limit",
            "1",
            "--opponent-seed",
            "20260705",
            "--simulation-seed",
            "20260705",
            "--game-timeout-seconds",
            "30",
            "--deck-process-timeout-seconds",
            "240",
            "--isolate-deck-process",
            "--stem",
            f"lorehold_mana_base_{candidate_slug}_smoke_20260705_current",
        ],
        "decision": {
            "current_best_baseline": "deck_607",
            "candidate": f"+{add} / -{cut}",
            "promotion_allowed": False,
            "next_action": (
                "run_diagnostic_smoke_battle"
                if pass_status
                else "fix_candidate_materialization_before_any_battle"
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    validation = payload["preflight_validation"]
    lines = [
        "# Lorehold Mana Base Candidate Preflight",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- candidate: `+{summary['add']} / -{summary['cut']}`",
        f"- allow_smoke_battle_gate: `{str(summary['allow_smoke_battle_gate']).lower()}`",
        f"- allow_promotion_gate: `{str(summary['allow_promotion_gate']).lower()}`",
        f"- keep_607_as_protected_baseline: `{str(summary['keep_607_as_protected_baseline']).lower()}`",
        "",
        "## Checks",
        "",
        "| Check | Pass |",
        "| --- | --- |",
    ]
    for key, value in validation["checks"].items():
        lines.append(f"| `{key}` | `{str(value).lower()}` |")
    lines.extend(
        [
            "",
            "## Deck Difference",
            "",
            f"- added: `{json.dumps(validation['diff']['added'], sort_keys=True)}`",
            f"- removed: `{json.dumps(validation['diff']['removed'], sort_keys=True)}`",
            "",
            "## Protected Anchors",
            "",
            f"- status: `{validation['protected_anchor_status']['status']}`",
            f"- missing: `{', '.join(validation['protected_anchor_status']['missing']) or '-'}`",
            f"- changed: `{', '.join(validation['protected_anchor_status']['changed']) or '-'}`",
            "",
            "## Added Card Runtime",
            "",
            f"- added_card_runtime: `{json.dumps(validation['added_card_runtime'], sort_keys=True)}`",
            "",
            "## Decision",
            "",
            f"- current_best_baseline: `{payload['decision']['current_best_baseline']}`",
            f"- candidate: `{payload['decision']['candidate']}`",
            f"- promotion_allowed: `{str(payload['decision']['promotion_allowed']).lower()}`",
            f"- next_action: `{payload['decision']['next_action']}`",
        ]
    )
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--materializer-report", type=Path, default=DEFAULT_MATERIALIZER_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    parser.add_argument("--deck-id", type=int, default=DEFAULT_DECK_ID)
    args = parser.parse_args()
    payload = build_payload(
        materializer_report_path=args.materializer_report,
        out_prefix=args.out_prefix,
        deck_id=args.deck_id,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": rel(json_path),
                "markdown": rel(md_path),
                "allow_smoke_battle_gate": payload["summary"]["allow_smoke_battle_gate"],
            },
            sort_keys=True,
        )
    )
    return 0 if payload["status"] == "battle_smoke_preflight_ready" else 1


if __name__ == "__main__":
    raise SystemExit(main())
