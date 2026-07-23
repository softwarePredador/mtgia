#!/usr/bin/env python3
"""Build the read-only XMage source-candidate and residual-priority queue.

A resolvable local XMage Java implementation is source evidence, not executable
coverage. The pinned runtime catalog must confirm the exact identity first.
Catalog-covered cards execute externally; native adapter work starts only for
the explicit residual after pinned XMage and Forge coverage fail. Historical
``translation_lane`` and ``adapter_work_unit`` fields are retained solely for
compatibility with the native-family analysis archive.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping

from battle_rule_registry import logical_rule_key

import global_card_oracle_battle_readiness as readiness
import external_engine_source_contract as engine_source_contract
import xmage_local_rule_indexer as xmage_indexer


REPORT_DIR = readiness.REPORT_DIR
DEFAULT_XMAGE_ROOT = readiness.DEFAULT_XMAGE_ROOT
CONTRACT = readiness.XMAGE_FLOW

DEFAULT_SCOPE = "commander_legal_battle_gap"
SCOPES = {DEFAULT_SCOPE, "all_battle_gap"}
CARD_SPECIFIC_TOKEN_VARIANT_PREFIX = "xmage_create_token_variant_"
PRIORITY_SCHEMA = "battle_rule_priority_v1"
TRUSTED_ENGINE_CONTRACTS = (
    "canonical_rules_execution",
    "canonical_rules_execution_secondary",
    "native_reviewed_rules_execution",
)
OWNER_INTENT_POLICY = {
    "preserve_user_skeleton": True,
    "allow_auto_fill": False,
    "allow_auto_delete": False,
    "allow_deck_mutation": False,
}
OPERATIONAL_LANE_ROUTING = {
    "pinned_xmage_catalog_confirmation_required": (
        "external_engine_coverage",
        "confirm_exact_pinned_xmage_catalog_then_count_external_coverage",
    ),
    "forge_then_native_residual_review": (
        "external_rules_residual_review",
        "reconcile_pinned_forge_then_open_native_work_only_if_unresolved",
    ),
}
OPERATIONAL_RESIDUAL_PRIORITY_WEIGHT = {
    "pinned_xmage_catalog_confirmation_required": 10,
    "forge_then_native_residual_review": 30,
}


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
    if effect == "token_maker" and scope.startswith(CARD_SPECIFIC_TOKEN_VARIANT_PREFIX):
        return f"token_maker::{xmage_signature_work_unit(parsed_entry)}"
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


def operational_coverage_lane(*, resolved: xmage_indexer.ResolvedSource | None) -> str:
    if resolved:
        return "pinned_xmage_catalog_confirmation_required"
    return "forge_then_native_residual_review"


def compact_queue_row(
    card: dict[str, Any],
    *,
    resolved: xmage_indexer.ResolvedSource | None,
    parsed_entry: dict[str, Any] | None,
) -> dict[str, Any]:
    effect_json = primary_effect_json(parsed_entry)
    lane = translation_lane(resolved=resolved, parsed_entry=parsed_entry)
    operational_lane = operational_coverage_lane(resolved=resolved)
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
        "runtime_requirement": card.get("runtime_requirement"),
        "ready_product_deck_count": int(card.get("ready_product_deck_count") or 0),
        "registered_deck_count": int(card.get("deck_count") or 0),
        "registered_total_quantity": int(card.get("total_quantity") or 0),
        "commander_slot_count": int(card.get("commander_slot_count") or 0),
        "source_truth_status": "xmage_local_source_candidate" if resolved else "xmage_local_source_missing",
        "source_resolution_status": "local_source_candidate" if resolved else "local_source_missing",
        "runtime_catalog_confirmation_required": bool(resolved),
        "runtime_coverage_status": "unconfirmed",
        "operational_coverage_lane": operational_lane,
        "native_adapter_required": False,
        "native_adapter_decision": "defer_until_xmage_and_forge_residual_is_proven",
        "legacy_analysis_fields": ["translation_lane", "adapter_work_unit"],
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


def fetch_typed_battle_usage() -> tuple[dict[str, int], str]:
    """Read canonical, typed natural card exposure counts from PostgreSQL."""

    from db_helper import connect

    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT EXISTS (
                  SELECT 1
                  FROM information_schema.tables
                  WHERE table_schema = 'public'
                    AND table_name = 'battle_simulations'
                )
                """
            )
            if not bool(cur.fetchone()[0]):
                return {}, "postgresql_battle_simulations_missing"
            cur.execute(
                """
                WITH evidence_rows AS (
                  SELECT
                    bs.id,
                    bs.game_log -> 'battle_learning_evidence' AS evidence
                  FROM battle_simulations bs
                  WHERE bs.simulation_type = 'battle'
                    AND jsonb_typeof(bs.game_log) = 'object'
                    AND COALESCE(
                      bs.game_log ->> 'engine_contract',
                      bs.metrics ->> 'engine_contract',
                      ''
                    ) = ANY(%s)
                ), typed_natural_evidence AS (
                  SELECT id, evidence
                  FROM evidence_rows
                  WHERE evidence ->> 'schema_version' = 'battle_positive_evidence_v1'
                    AND evidence ->> 'natural_sample' = 'true'
                    AND evidence ->> 'positive_exposure_ready' = 'true'
                    AND evidence ->> 'positive_evidence_basis' = 'typed_event'
                    AND COALESCE(evidence ->> 'typed_positive_event_count', '') ~ '^[0-9]+$'
                    AND (evidence ->> 'typed_positive_event_count')::int > 0
                ), exposed_names AS (
                  SELECT
                    evidence_row.id,
                    lower(btrim(exposed.value)) AS normalized_name
                  FROM typed_natural_evidence evidence_row
                  CROSS JOIN LATERAL jsonb_array_elements_text(
                    CASE
                      WHEN jsonb_typeof(
                        evidence_row.evidence -> 'exposed_card_names_normalized'
                      ) = 'array'
                      THEN evidence_row.evidence -> 'exposed_card_names_normalized'
                      ELSE '[]'::jsonb
                    END
                  ) AS exposed(value)
                  WHERE btrim(exposed.value) <> ''
                )
                SELECT normalized_name, count(DISTINCT id)::int AS battle_count
                FROM exposed_names
                GROUP BY normalized_name
                """,
                (list(TRUSTED_ENGINE_CONTRACTS),),
            )
            return (
                {str(name): int(count) for name, count in cur.fetchall()},
                "postgresql_typed_natural_positive_battle_evidence",
            )


def prioritize_queue_rows(
    queue: list[dict[str, Any]],
    *,
    battle_usage_by_name: Mapping[str, int] | None = None,
) -> list[dict[str, Any]]:
    usage = {
        readiness.normalize_name(name): max(int(count), 0)
        for name, count in (battle_usage_by_name or {}).items()
    }
    work_unit_counts = Counter(row["adapter_work_unit"] for row in queue)
    prioritized: list[dict[str, Any]] = []
    for source_row in queue:
        row = dict(source_row)
        normalized_name = readiness.normalize_name(row.get("normalized_name") or row.get("card_name"))
        product_decks = max(int(row.get("ready_product_deck_count") or 0), 0)
        typed_battles = usage.get(normalized_name, 0)
        commander_slots = max(int(row.get("commander_slot_count") or 0), 0)
        work_unit_card_count = work_unit_counts[row["adapter_work_unit"]]
        lane = str(row.get("operational_coverage_lane") or "")

        product_score = min(product_decks * 20, 40)
        usage_score = min(typed_battles * 10, 30)
        impact_score = min(work_unit_card_count * 2, 20) + min(commander_slots * 10, 10)
        residual_score = OPERATIONAL_RESIDUAL_PRIORITY_WEIGHT.get(lane, 0)
        priority_score = product_score + usage_score + impact_score + residual_score
        if product_decks > 0 or typed_battles > 0:
            priority_band = "P0"
        elif priority_score >= 40:
            priority_band = "P1"
        else:
            priority_band = "P2"
        owner, next_gate = OPERATIONAL_LANE_ROUTING.get(
            lane,
            ("battle_rules_triage", "review_unknown_operational_coverage_lane"),
        )
        row.update(
            {
                "priority_schema": PRIORITY_SCHEMA,
                "priority_band": priority_band,
                "priority_score": priority_score,
                "priority_components": {
                    "product": {
                        "ready_product_deck_count": product_decks,
                        "score": product_score,
                    },
                    "real_usage": {
                        "typed_natural_positive_battle_count": typed_battles,
                        "score": usage_score,
                    },
                    "impact": {
                        "adapter_work_unit_card_count": work_unit_card_count,
                        "commander_slot_count": commander_slots,
                        "score": impact_score,
                    },
                    "residual": {
                        "operational_coverage_lane": lane,
                        "score": residual_score,
                    },
                },
                "owner": owner,
                "next_gate": next_gate,
                "owner_intent_policy": dict(OWNER_INTENT_POLICY),
                "postgresql_is_product_truth": True,
                "promotion_allowed": False,
            }
        )
        prioritized.append(row)
    return sorted(
        prioritized,
        key=lambda row: (
            -int(row["priority_score"]),
            str(row.get("normalized_name") or ""),
            str(row.get("card_id") or ""),
        ),
    )


def build_queue(
    cards: list[dict[str, Any]],
    *,
    xmage_root: Path,
    scope: str = DEFAULT_SCOPE,
    limit: int = 0,
    battle_usage_by_name: Mapping[str, int] | None = None,
    battle_usage_source_status: str = "not_loaded",
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
    queue = prioritize_queue_rows(
        queue,
        battle_usage_by_name=battle_usage_by_name,
    )
    return {
        "generated_at": utc_now(),
        "status": "action_required",
        "contract": readiness.rel(CONTRACT),
        "method": {
            "read_only": True,
            "scope": scope,
            "unit_of_work": "oracle identity / normalized identity",
            "xmage_root": str(xmage_root),
            "local_xmage_source_is_runtime_coverage": False,
            "local_source_resolution_requires_runtime_catalog_confirmation": True,
            "manaLoom_work": "confirm external runtime coverage first; open native family work only for proven external residual",
            "legacy_native_analysis_fields_retained": ["translation_lane", "adapter_work_unit"],
            "limit": limit,
            "xmage_class_index_size": len(class_index),
            "priority_schema": PRIORITY_SCHEMA,
            "priority_inputs": ["product", "real_usage", "impact", "residual"],
            "real_usage_source": battle_usage_source_status,
            "registered_deck_count_is_diagnostic_only": True,
            "postgresql_is_product_truth": True,
            "owner_intent_policy": dict(OWNER_INTENT_POLICY),
        },
        "summary": summarize_queue(queue, total_target_count=len(target_cards)),
        "queue": queue,
    }


def summarize_queue(queue: list[dict[str, Any]], *, total_target_count: int) -> dict[str, Any]:
    lane_counts = Counter(row["translation_lane"] for row in queue)
    operational_lane_counts = Counter(row["operational_coverage_lane"] for row in queue)
    source_counts = Counter(row["source_truth_status"] for row in queue)
    work_unit_counts = Counter(row["adapter_work_unit"] for row in queue)
    effect_counts = Counter((row.get("effect_json") or {}).get("effect") or "unparsed" for row in queue)
    scope_counts = Counter((row.get("effect_json") or {}).get("battle_model_scope") or "unparsed" for row in queue)
    oracle_family_counts = Counter(row.get("oracle_family") or "unknown" for row in queue)
    priority_band_counts = Counter(row.get("priority_band") or "unprioritized" for row in queue)
    owner_counts = Counter(row.get("owner") or "unowned" for row in queue)
    next_gate_counts = Counter(row.get("next_gate") or "missing" for row in queue)
    signal_counts: Counter[str] = Counter()
    for row in queue:
        signal_counts.update(row.get("xmage_signals") or [])
    authoritative_count = source_counts.get("xmage_local_source_candidate", 0)
    parser_gap_count = lane_counts.get("xmage_authoritative_parser_gap", 0)
    missing_count = lane_counts.get("xmage_missing_source_exception", 0)
    return {
        "target_identity_count": total_target_count,
        "xmage_local_source_candidate_count": authoritative_count,
        "xmage_missing_source_exception_count": missing_count,
        "xmage_authoritative_parser_gap_count": parser_gap_count,
        "xmage_authoritative_adapter_required_count": lane_counts.get("xmage_authoritative_adapter_required", 0),
        "manual_semantic_decision_units_remaining": missing_count + parser_gap_count,
        "local_source_candidate_ratio": round(authoritative_count / max(total_target_count, 1), 4),
        "adapter_work_unit_count": len(work_unit_counts),
        "operational_coverage_lane_counts": dict(sorted(operational_lane_counts.items())),
        "translation_lane_counts": dict(sorted(lane_counts.items())),
        "source_truth_status_counts": dict(sorted(source_counts.items())),
        "top_adapter_work_units": dict(work_unit_counts.most_common(30)),
        "top_effects": dict(effect_counts.most_common(30)),
        "top_battle_model_scopes": dict(scope_counts.most_common(30)),
        "top_oracle_families": dict(oracle_family_counts.most_common(30)),
        "top_xmage_signals": dict(signal_counts.most_common(30)),
        "priority_band_counts": dict(sorted(priority_band_counts.items())),
        "owner_counts": dict(sorted(owner_counts.items())),
        "next_gate_counts": dict(sorted(next_gate_counts.items())),
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
    battle_usage, battle_usage_source_status = fetch_typed_battle_usage()
    return build_queue(
        cards,
        xmage_root=xmage_root,
        scope=scope,
        limit=limit,
        battle_usage_by_name=battle_usage,
        battle_usage_source_status=battle_usage_source_status,
    )


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
        "A local XMage Java class is source evidence, not executable runtime coverage.",
        "Use `xmage_source_catalog_reconciliation.py` to confirm the exact identity in the pinned runtime catalog.",
        "Catalog-confirmed XMage/Forge cards execute externally and do not require a native PostgreSQL rule.",
        "Open native family work only for the explicit residual after both external coverage lanes fail.",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "| --- | ---: |",
    ]
    for key in (
        "target_identity_count",
        "xmage_local_source_candidate_count",
        "xmage_missing_source_exception_count",
        "xmage_authoritative_parser_gap_count",
        "xmage_authoritative_adapter_required_count",
        "manual_semantic_decision_units_remaining",
        "local_source_candidate_ratio",
        "adapter_work_unit_count",
    ):
        lines.append(f"| `{key}` | {summary[key]} |")

    lines.extend(["", "## Operational Coverage Lanes", "", "| Lane | Count |", "| --- | ---: |"])
    for lane, count in summary["operational_coverage_lane_counts"].items():
        lines.append(f"| `{lane}` | {count} |")

    lines.extend(["", "## Historical Native-analysis Lanes", "", "| Lane | Count |", "| --- | ---: |"])
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
            "- `pinned_xmage_catalog_confirmation_required`: reconcile the exact pinned runtime identity before counting coverage.",
            "- `forge_then_native_residual_review`: test pinned Forge; open native work only if the card remains unresolved.",
            "- `translation_lane` and `adapter_work_unit` are compatibility fields for historical native-family analysis, not current execution instructions.",
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
    try:
        xmage_root = engine_source_contract.resolve_xmage_source_root(args.xmage_root)
    except ValueError as exc:
        raise SystemExit(str(exc)) from exc
    payload = build_payload(xmage_root=xmage_root, scope=args.scope, limit=args.limit)
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    write_markdown(payload, md_path)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path), "summary": payload["summary"]}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
