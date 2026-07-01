#!/usr/bin/env python3
"""Build the authoritative XMage -> ManaLoom adaptation queue.

This read-only queue implements the current acceleration decision: when a card
has a resolvable local XMage Java implementation, XMage is treated as the final
behavior source for that card. The remaining work is adapter/runtime translation
inside ManaLoom, not card-by-card semantic decision making.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from battle_rule_registry import logical_rule_key

import global_card_oracle_battle_readiness as readiness
import xmage_local_rule_indexer as xmage_indexer


REPORT_DIR = readiness.REPORT_DIR
DEFAULT_XMAGE_ROOT = readiness.DEFAULT_XMAGE_ROOT
CONTRACT = readiness.XMAGE_FLOW

DEFAULT_SCOPE = "commander_legal_battle_gap"
SCOPES = {DEFAULT_SCOPE, "all_battle_gap"}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def is_commander_legal(card: dict[str, Any]) -> bool:
    return str(card.get("commander_legality_status") or "") in {"legal", "restricted"}


def in_scope(card: dict[str, Any], scope: str) -> bool:
    if "battle_family_mapper_required" not in (card.get("lanes") or []):
        return False
    if scope == "all_battle_gap":
        return True
    if scope == DEFAULT_SCOPE:
        return is_commander_legal(card)
    raise ValueError(f"Unsupported scope: {scope}")


def identity_key(card: dict[str, Any]) -> str:
    return str(card.get("oracle_id") or card.get("normalized_name") or card.get("name") or "")


def unique_identity_cards(cards: list[dict[str, Any]], scope: str) -> list[dict[str, Any]]:
    selected: dict[str, dict[str, Any]] = {}
    for card in cards:
        if not in_scope(card, scope):
            continue
        key = identity_key(card)
        if not key:
            continue
        current = selected.get(key)
        if current is None:
            selected[key] = card
            continue
        # Prefer the printing/card row that is Commander legal and has Oracle data.
        current_score = int(is_commander_legal(current)) + int(bool(current.get("oracle_text_analysis")))
        card_score = int(is_commander_legal(card)) + int(bool(card.get("oracle_text_analysis")))
        if card_score > current_score:
            selected[key] = card
    return sorted(selected.values(), key=lambda row: (str(row.get("normalized_name") or ""), str(row.get("card_id") or "")))


def primary_candidate(parsed_entry: dict[str, Any] | None) -> dict[str, Any]:
    if not parsed_entry:
        return {}
    candidate = (parsed_entry.get("candidate_effect_hints") or {}).get("primary_candidate") or {}
    return candidate if isinstance(candidate, dict) else {}


def primary_effect_json(parsed_entry: dict[str, Any] | None) -> dict[str, Any]:
    effect_json = primary_candidate(parsed_entry).get("effect_json") or {}
    return effect_json if isinstance(effect_json, dict) else {}


def adapter_work_unit(effect_json: dict[str, Any], parsed_entry: dict[str, Any] | None) -> str:
    effect = str(effect_json.get("effect") or "")
    scope = str(effect_json.get("battle_model_scope") or "")
    if effect == "external_reference_required_manual_model" or scope == "xmage_reference_requires_manual_model_review_v1":
        return xmage_signature_work_unit(parsed_entry)
    if effect or scope:
        return f"{effect or 'unknown_effect'}::{scope or 'unknown_scope'}"
    signals = ",".join(parsed_entry.get("signals") or []) if parsed_entry else ""
    superclass = str((parsed_entry or {}).get("card_superclass") or "unknown_superclass")
    return f"parser_gap::{superclass}::{signals or 'no_signal'}"


def xmage_signature_work_unit(parsed_entry: dict[str, Any] | None) -> str:
    if not parsed_entry:
        return "parser_gap::unknown_superclass::no_signal"
    effects = ",".join((parsed_entry.get("effect_classes") or [])[:6]) or "no_effect_class"
    abilities = ",".join((parsed_entry.get("ability_classes") or [])[:6]) or "no_ability_class"
    targets = ",".join((parsed_entry.get("target_classes") or [])[:4]) or "no_target_class"
    conditions = ",".join((parsed_entry.get("condition_classes") or [])[:4]) or "no_condition_class"
    signals = ",".join((parsed_entry.get("signals") or [])[:6]) or "no_signal"
    return f"xmage_signature::{effects}::{abilities}::{targets}::{conditions}::{signals}"


def translation_lane(
    *,
    resolved: xmage_indexer.ResolvedSource | None,
    parsed_entry: dict[str, Any] | None,
) -> str:
    if not resolved:
        return "xmage_missing_source_exception"
    effect_json = primary_effect_json(parsed_entry)
    if not effect_json.get("effect") and not effect_json.get("battle_model_scope"):
        return "xmage_authoritative_parser_gap"
    return "xmage_authoritative_adapter_required"


def compact_queue_row(
    card: dict[str, Any],
    *,
    resolved: xmage_indexer.ResolvedSource | None,
    parsed_entry: dict[str, Any] | None,
) -> dict[str, Any]:
    effect_json = primary_effect_json(parsed_entry)
    lane = translation_lane(resolved=resolved, parsed_entry=parsed_entry)
    rule = {"effect_json": effect_json, "deck_role_json": {}}
    logical_key = logical_rule_key(rule) if effect_json else None
    candidate = primary_candidate(parsed_entry)
    return {
        "card_id": card.get("card_id"),
        "card_name": card.get("name"),
        "normalized_name": card.get("normalized_name"),
        "oracle_id": card.get("oracle_id"),
        "commander_legality_status": card.get("commander_legality_status"),
        "oracle_family": card.get("family"),
        "source_truth_status": "xmage_authoritative" if resolved else "xmage_source_missing",
        "translation_lane": lane,
        "adapter_work_unit": adapter_work_unit(effect_json, parsed_entry),
        "logical_rule_key": logical_key,
        "effect_json": effect_json,
        "primary_candidate_status": candidate.get("status"),
        "primary_candidate_confidence_reason": candidate.get("confidence_reason"),
        "xmage_class": resolved.class_name if resolved else None,
        "xmage_path": str(resolved.path) if resolved else None,
        "xmage_resolution": resolved.resolution if resolved else None,
        "xmage_superclass": (parsed_entry or {}).get("card_superclass"),
        "xmage_signals": (parsed_entry or {}).get("signals") or [],
        "xmage_effect_classes": (parsed_entry or {}).get("effect_classes") or [],
        "xmage_ability_classes": (parsed_entry or {}).get("ability_classes") or [],
    }


def build_queue(
    cards: list[dict[str, Any]],
    *,
    xmage_root: Path,
    scope: str = DEFAULT_SCOPE,
    limit: int = 0,
) -> dict[str, Any]:
    if scope not in SCOPES:
        raise ValueError(f"Unsupported scope: {scope}")
    target_cards = unique_identity_cards(cards, scope)
    if limit > 0:
        target_cards = target_cards[:limit]
    class_index = xmage_indexer.build_card_class_index(xmage_root)
    queue: list[dict[str, Any]] = []
    for card in target_cards:
        resolved = xmage_indexer.resolve_card_source(xmage_root, str(card.get("name") or ""), class_index=class_index)
        parsed_entry: dict[str, Any] | None = None
        if resolved:
            source = resolved.path.read_text(encoding="utf-8", errors="replace")
            parsed_entry = xmage_indexer.parse_java_card_source(
                source,
                card_name=str(card.get("name") or ""),
                class_name=resolved.class_name,
                path=resolved.path,
            )
        queue.append(compact_queue_row(card, resolved=resolved, parsed_entry=parsed_entry))
    return {
        "generated_at": utc_now(),
        "status": "action_required",
        "contract": readiness.rel(CONTRACT),
        "method": {
            "read_only": True,
            "scope": scope,
            "unit_of_work": "oracle identity / normalized identity",
            "xmage_root": str(xmage_root),
            "xmage_is_authoritative_for_resolved_sources": True,
            "manaLoom_work": "adapter/runtime translation; not card-by-card semantic rule approval",
            "limit": limit,
            "xmage_class_index_size": len(class_index),
        },
        "summary": summarize_queue(queue, total_target_count=len(target_cards)),
        "queue": queue,
    }


def summarize_queue(queue: list[dict[str, Any]], *, total_target_count: int) -> dict[str, Any]:
    lane_counts = Counter(row["translation_lane"] for row in queue)
    source_counts = Counter(row["source_truth_status"] for row in queue)
    work_unit_counts = Counter(row["adapter_work_unit"] for row in queue)
    effect_counts = Counter((row.get("effect_json") or {}).get("effect") or "unparsed" for row in queue)
    scope_counts = Counter((row.get("effect_json") or {}).get("battle_model_scope") or "unparsed" for row in queue)
    oracle_family_counts = Counter(row.get("oracle_family") or "unknown" for row in queue)
    signal_counts: Counter[str] = Counter()
    for row in queue:
        signal_counts.update(row.get("xmage_signals") or [])
    authoritative_count = source_counts.get("xmage_authoritative", 0)
    parser_gap_count = lane_counts.get("xmage_authoritative_parser_gap", 0)
    missing_count = lane_counts.get("xmage_missing_source_exception", 0)
    return {
        "target_identity_count": total_target_count,
        "xmage_authoritative_source_count": authoritative_count,
        "xmage_missing_source_exception_count": missing_count,
        "xmage_authoritative_parser_gap_count": parser_gap_count,
        "xmage_authoritative_adapter_required_count": lane_counts.get("xmage_authoritative_adapter_required", 0),
        "manual_semantic_decision_units_remaining": missing_count + parser_gap_count,
        "authoritative_source_coverage_ratio": round(authoritative_count / max(total_target_count, 1), 4),
        "adapter_work_unit_count": len(work_unit_counts),
        "translation_lane_counts": dict(sorted(lane_counts.items())),
        "source_truth_status_counts": dict(sorted(source_counts.items())),
        "top_adapter_work_units": dict(work_unit_counts.most_common(30)),
        "top_effects": dict(effect_counts.most_common(30)),
        "top_battle_model_scopes": dict(scope_counts.most_common(30)),
        "top_oracle_families": dict(oracle_family_counts.most_common(30)),
        "top_xmage_signals": dict(signal_counts.most_common(30)),
        "samples": {
            "adapter_required": sample_cards(queue, "xmage_authoritative_adapter_required"),
            "parser_gap": sample_cards(queue, "xmage_authoritative_parser_gap"),
            "missing_source": sample_cards(queue, "xmage_missing_source_exception"),
        },
    }


def sample_cards(queue: list[dict[str, Any]], lane: str, *, limit: int = 20) -> list[str]:
    return [str(row.get("card_name") or "") for row in queue if row.get("translation_lane") == lane][:limit]


def build_payload(*, xmage_root: Path, scope: str, limit: int) -> dict[str, Any]:
    deck_scope = readiness.fetch_deck_scope()
    rows = readiness.fetch_all_card_rows(deck_scope)
    cards = readiness.build_card_inventory(rows, xmage_root=xmage_root, xmage_limit=0)
    return build_queue(cards, xmage_root=xmage_root, scope=scope, limit=limit)


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    summary = payload["summary"]
    lines = [
        "# XMage Authoritative Adaptation Queue",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Contract: `{payload['contract']}`",
        f"- Scope: `{payload['method']['scope']}`",
        f"- XMage root: `{payload['method']['xmage_root']}`",
        "",
        "## Decision",
        "",
        "For every target card with a resolvable local XMage class, XMage is the authoritative behavior source.",
        "ManaLoom work is now adapter/runtime translation by family or effect signature, not card-by-card semantic approval.",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "| --- | ---: |",
    ]
    for key in (
        "target_identity_count",
        "xmage_authoritative_source_count",
        "xmage_missing_source_exception_count",
        "xmage_authoritative_parser_gap_count",
        "xmage_authoritative_adapter_required_count",
        "manual_semantic_decision_units_remaining",
        "authoritative_source_coverage_ratio",
        "adapter_work_unit_count",
    ):
        lines.append(f"| `{key}` | {summary[key]} |")

    lines.extend(["", "## Translation Lanes", "", "| Lane | Count |", "| --- | ---: |"])
    for lane, count in summary["translation_lane_counts"].items():
        lines.append(f"| `{lane}` | {count} |")

    lines.extend(["", "## Top Adapter Work Units", "", "| Work Unit | Cards |", "| --- | ---: |"])
    for unit, count in summary["top_adapter_work_units"].items():
        lines.append(f"| `{unit}` | {count} |")

    lines.extend(["", "## Top Effects", "", "| Effect | Cards |", "| --- | ---: |"])
    for effect, count in summary["top_effects"].items():
        lines.append(f"| `{effect}` | {count} |")

    lines.extend(["", "## Top XMage Signals", "", "| Signal | Cards |", "| --- | ---: |"])
    for signal, count in summary["top_xmage_signals"].items():
        lines.append(f"| `{signal}` | {count} |")

    lines.extend(["", "## Samples", ""])
    for lane, cards in summary["samples"].items():
        lines.append(f"### {lane}")
        lines.append("")
        for card in cards:
            lines.append(f"- `{card}`")
        lines.append("")

    lines.extend(
        [
            "## Operational Meaning",
            "",
            "- `xmage_authoritative_adapter_required`: source truth exists; build/route a ManaLoom adapter for the work unit.",
            "- `xmage_authoritative_parser_gap`: source truth exists; improve XMage parser/hints before adapter generation.",
            "- `xmage_missing_source_exception`: local XMage does not resolve the card; this is the residual manual/external-source queue.",
            "- This report is read-only and does not mutate PostgreSQL or Hermes.",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--xmage-root", type=Path, default=DEFAULT_XMAGE_ROOT)
    parser.add_argument("--scope", choices=sorted(SCOPES), default=DEFAULT_SCOPE)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "xmage_authoritative_adaptation_queue_20260701_commander_gap",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_payload(xmage_root=args.xmage_root, scope=args.scope, limit=args.limit)
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    write_markdown(payload, md_path)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path), "summary": payload["summary"]}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
