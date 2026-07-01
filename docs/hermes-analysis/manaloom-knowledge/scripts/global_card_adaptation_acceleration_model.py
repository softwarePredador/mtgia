#!/usr/bin/env python3
"""Acceleration model for adapting all ManaLoom cards.

This is a read-only planning layer. It proves why the all-card backlog must be
worked by identity/template/family instead of by card row, and it identifies the
template-first lanes that should be implemented before manual card work.

Registered deck usage is kept as an internal QA seed only. Those rows are not a
market-demand proxy, because the current registered deck corpus is operator-led
and incomplete relative to what future users may import or build.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_card_oracle_battle_readiness as readiness


REPORT_DIR = readiness.REPORT_DIR
DEFAULT_XMAGE_ROOT = readiness.DEFAULT_XMAGE_ROOT
CONTRACT = readiness.XMAGE_FLOW


TEMPLATE_DEFINITIONS: tuple[dict[str, Any], ...] = (
    {
        "template": "vanilla_or_no_rules_creature",
        "families": {"generic_vanilla_or_keyword_creature"},
        "patterns": (),
        "runtime_unit": "generic creature body/keyword handling; no card-specific battle rule",
        "confidence": "safe_generic",
    },
    {
        "template": "counter_target_spell",
        "families": {"counterspell_or_stack_interaction"},
        "patterns": (r"\bcounter target (?:spell|instant|sorcery|activated ability|triggered ability)\b",),
        "runtime_unit": "single target stack counter resolver",
        "confidence": "template_candidate",
    },
    {
        "template": "destroy_target_permanent",
        "families": {"targeted_removal"},
        "patterns": (r"\bdestroy target (?:creature|artifact|enchantment|permanent|planeswalker|nonland permanent)\b",),
        "runtime_unit": "targeted permanent destruction by target type",
        "confidence": "template_candidate",
    },
    {
        "template": "exile_target_permanent",
        "families": {"targeted_removal"},
        "patterns": (r"\bexile target (?:creature|artifact|enchantment|permanent|planeswalker|nonland permanent)\b",),
        "runtime_unit": "targeted exile by target type",
        "confidence": "template_candidate",
    },
    {
        "template": "direct_damage_fixed_amount",
        "families": {"damage_or_life_total_change"},
        "patterns": (r"\bdeals? (?:x|one|two|three|four|five|\d+) damage to (?:any target|target creature|target player|each opponent)\b",),
        "runtime_unit": "fixed/direct damage resolver with target selector",
        "confidence": "template_candidate",
    },
    {
        "template": "life_gain_or_loss_fixed_amount",
        "families": {"damage_or_life_total_change"},
        "patterns": (r"\b(?:you gain|target player gains|each opponent loses|target opponent loses) (?:x|one|two|three|four|five|\d+) life\b",),
        "runtime_unit": "life total delta resolver",
        "confidence": "template_candidate",
    },
    {
        "template": "draw_fixed_cards",
        "families": {"draw_selection_topdeck"},
        "patterns": (r"\b(?:draw|draws) (?:a card|one card|two cards|three cards|\d+ cards)\b",),
        "runtime_unit": "card draw resolver",
        "confidence": "template_candidate",
    },
    {
        "template": "scry_or_surveil_fixed",
        "families": {"draw_selection_topdeck"},
        "patterns": (r"\b(?:scry|surveil) (?:one|two|three|four|\d+)\b",),
        "runtime_unit": "topdeck selection/reorder resolver",
        "confidence": "template_candidate",
    },
    {
        "template": "create_fixed_tokens",
        "families": {"token_creation"},
        "patterns": (r"\bcreate (?:a|one|two|three|four|five|\d+) .{0,80}? token",),
        "runtime_unit": "fixed token creation with parsed token body",
        "confidence": "template_candidate",
    },
    {
        "template": "create_treasure_tokens",
        "families": {"token_creation", "mana_generation_or_ritual"},
        "patterns": (r"\bcreate (?:a|one|two|three|four|five|\d+) treasure tokens?\b",),
        "runtime_unit": "Treasure token creation and later sacrifice-for-mana",
        "confidence": "template_candidate",
    },
    {
        "template": "add_mana_static_or_activated",
        "families": {"mana_generation_or_ritual"},
        "patterns": (r"\badd (?:\{[wubrgc0-9/]+\}|one mana|two mana|three mana|x mana)",),
        "runtime_unit": "mana-source production from activated/ritual text",
        "confidence": "template_candidate",
    },
    {
        "template": "search_library_basic_land",
        "families": {"tutor_search_library"},
        "patterns": (r"\bsearch your library for (?:a|up to \w+)? ?(?:basic )?land card",),
        "runtime_unit": "land tutor/search and zone movement",
        "confidence": "template_candidate",
    },
    {
        "template": "search_library_card_to_hand",
        "families": {"tutor_search_library"},
        "patterns": (r"\bsearch your library for (?:a|an|up to \w+)? ?(?:card|artifact card|creature card|enchantment card|instant card|sorcery card)",),
        "runtime_unit": "typed tutor/search to hand/top/battlefield after exact destination split",
        "confidence": "split_required_candidate",
    },
    {
        "template": "return_target_from_graveyard",
        "families": {"graveyard_recursion", "recursion_or_bounce"},
        "patterns": (r"\breturn target .{0,80}? from your graveyard to (?:your hand|the battlefield)\b",),
        "runtime_unit": "graveyard target return by destination",
        "confidence": "template_candidate",
    },
    {
        "template": "protection_hexproof_indestructible_until_eot",
        "families": {"protection_prevention"},
        "patterns": (r"\b(?:gains?|gain) (?:hexproof|indestructible|protection from .{1,40}) until end of turn\b",),
        "runtime_unit": "temporary protection shield",
        "confidence": "template_candidate",
    },
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def normalize_space(value: str) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def unique_count(cards: list[dict[str, Any]], field: str) -> int:
    return len({str(card.get(field) or "") for card in cards if str(card.get(field) or "")})


def has_external_popularity(card: dict[str, Any]) -> bool:
    return bool((card.get("external_popularity") or {}).get("present"))


def fetch_external_popularity_index() -> dict[str, dict[str, Any]]:
    """Load global popularity signals that are not derived from saved decks."""
    from db_helper import connect

    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT EXISTS (
                  SELECT 1
                  FROM information_schema.tables
                  WHERE table_schema = 'public'
                    AND table_name = 'format_staples'
                )
                """
            )
            if not bool(cur.fetchone()[0]):
                return {}
            cur.execute(
                """
                SELECT
                  lower(regexp_replace(btrim(card_name), '\\s+', ' ', 'g')) AS normalized_name,
                  count(*)::int AS signal_rows,
                  count(*) FILTER (WHERE lower(COALESCE(format, '')) = 'commander')::int AS commander_signal_rows,
                  min(edhrec_rank) FILTER (WHERE edhrec_rank IS NOT NULL AND edhrec_rank > 0)::int AS best_edhrec_rank
                FROM format_staples
                WHERE card_name IS NOT NULL
                  AND btrim(card_name) <> ''
                  AND COALESCE(is_banned, false) IS FALSE
                GROUP BY 1
                """
            )
            columns = [desc[0] for desc in cur.description]
            rows = [dict(zip(columns, raw)) for raw in cur.fetchall()]
    return {
        row["normalized_name"]: {
            "present": True,
            "signal_rows": int(row["signal_rows"] or 0),
            "commander_signal_rows": int(row["commander_signal_rows"] or 0),
            "best_edhrec_rank": row["best_edhrec_rank"],
        }
        for row in rows
        if row.get("normalized_name")
    }


def attach_external_popularity(cards: list[dict[str, Any]], index: dict[str, dict[str, Any]]) -> None:
    for card in cards:
        card["external_popularity"] = index.get(
            card.get("normalized_name") or "",
            {
                "present": False,
                "signal_rows": 0,
                "commander_signal_rows": 0,
                "best_edhrec_rank": None,
            },
        )


def matches_any(patterns: tuple[str, ...], oracle_text: str) -> bool:
    text = normalize_space(oracle_text)
    return any(re.search(pattern, text) for pattern in patterns)


def template_for_card(card: dict[str, Any]) -> dict[str, Any] | None:
    family = str(card.get("family") or "")
    oracle_text = str(card.get("oracle_text_analysis") or "")
    for definition in TEMPLATE_DEFINITIONS:
        if family not in definition["families"]:
            continue
        patterns = definition["patterns"]
        if not patterns or matches_any(patterns, oracle_text):
            return definition
    return None


def lane_cards(cards: list[dict[str, Any]], lane: str) -> list[dict[str, Any]]:
    return [card for card in cards if lane in (card.get("lanes") or [])]


def aggregate_template_rows(cards: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_template: dict[str, dict[str, Any]] = {}
    for card in cards:
        definition = template_for_card(card)
        if not definition:
            continue
        row = by_template.setdefault(
            definition["template"],
            {
                "template": definition["template"],
                "runtime_unit": definition["runtime_unit"],
                "confidence": definition["confidence"],
                "row_count": 0,
                "commander_legal_rows": 0,
                "external_popularity_rows": 0,
                "registered_deck_qa_rows": 0,
                "ready_product_qa_rows": 0,
                "normalized_names": set(),
                "oracle_ids": set(),
                "families": Counter(),
                "sample_cards": [],
            },
        )
        row["row_count"] += 1
        if str(card.get("commander_legality_status") or "") in {"legal", "restricted"}:
            row["commander_legal_rows"] += 1
        if has_external_popularity(card):
            row["external_popularity_rows"] += 1
        if int(card.get("deck_count") or 0) > 0:
            row["registered_deck_qa_rows"] += 1
        if int(card.get("ready_product_deck_count") or 0) > 0:
            row["ready_product_qa_rows"] += 1
        if card.get("normalized_name"):
            row["normalized_names"].add(card["normalized_name"])
        if card.get("oracle_id"):
            row["oracle_ids"].add(card["oracle_id"])
        row["families"][card.get("family") or ""] += 1
        if len(row["sample_cards"]) < 12:
            row["sample_cards"].append(card["name"])

    rows: list[dict[str, Any]] = []
    for row in by_template.values():
        rows.append(
            {
                "template": row["template"],
                "runtime_unit": row["runtime_unit"],
                "confidence": row["confidence"],
                "row_count": row["row_count"],
                "unique_names": len(row["normalized_names"]),
                "unique_oracle_ids": len(row["oracle_ids"]),
                "commander_legal_rows": row["commander_legal_rows"],
                "external_popularity_rows": row["external_popularity_rows"],
                "registered_deck_qa_rows": row["registered_deck_qa_rows"],
                "ready_product_qa_rows": row["ready_product_qa_rows"],
                "families": dict(row["families"].most_common()),
                "sample_cards": row["sample_cards"],
            }
        )
    return sorted(
        rows,
        key=lambda item: (
            -item["commander_legal_rows"],
            -item["external_popularity_rows"],
            -item["row_count"],
            item["template"],
        ),
    )


def summarize(cards: list[dict[str, Any]]) -> dict[str, Any]:
    battle_gap = lane_cards(cards, "battle_family_mapper_required")
    commander_legal = [card for card in cards if str(card.get("commander_legality_status") or "") in {"legal", "restricted"}]
    current_registered_decks = [card for card in cards if int(card.get("deck_count") or 0) > 0]
    ready_product_qa = [card for card in cards if int(card.get("ready_product_deck_count") or 0) > 0]
    registered_deck_qa_gap = [card for card in battle_gap if int(card.get("deck_count") or 0) > 0]
    ready_product_qa_gap = [card for card in battle_gap if int(card.get("ready_product_deck_count") or 0) > 0]
    commander_legal_gap = [
        card for card in battle_gap if str(card.get("commander_legality_status") or "") in {"legal", "restricted"}
    ]
    external_popularity_cards = [card for card in cards if has_external_popularity(card)]
    external_popularity_gap = [card for card in battle_gap if has_external_popularity(card)]
    template_rows = aggregate_template_rows(battle_gap)
    template_matched_names = {
        card["normalized_name"]
        for card in battle_gap
        if card.get("normalized_name") and template_for_card(card)
    }
    template_matched_commander_legal_names = {
        card["normalized_name"]
        for card in commander_legal_gap
        if card.get("normalized_name") and template_for_card(card)
    }
    template_matched_external_names = {
        card["normalized_name"]
        for card in external_popularity_gap
        if card.get("normalized_name") and template_for_card(card)
    }
    template_matched_registered_deck_qa_names = {
        card["normalized_name"]
        for card in registered_deck_qa_gap
        if card.get("normalized_name") and template_for_card(card)
    }
    family_counts = Counter(card.get("family") or "" for card in battle_gap)
    unmatched_by_family = Counter(
        card.get("family") or ""
        for card in battle_gap
        if not template_for_card(card)
    )
    top_templates = template_rows[:20]
    return {
        "all_cards": {
            "row_count": len(cards),
            "unique_names": unique_count(cards, "normalized_name"),
            "unique_oracle_ids": unique_count(cards, "oracle_id"),
        },
        "commander_legal": {
            "row_count": len(commander_legal),
            "unique_names": unique_count(commander_legal, "normalized_name"),
            "unique_oracle_ids": unique_count(commander_legal, "oracle_id"),
        },
        "external_popularity_signal": {
            "row_count": len(external_popularity_cards),
            "unique_names": unique_count(external_popularity_cards, "normalized_name"),
            "unique_oracle_ids": unique_count(external_popularity_cards, "oracle_id"),
        },
        "current_registered_deck_qa_seed": {
            "row_count": len(current_registered_decks),
            "unique_names": unique_count(current_registered_decks, "normalized_name"),
            "unique_oracle_ids": unique_count(current_registered_decks, "oracle_id"),
        },
        "ready_product_qa_seed": {
            "row_count": len(ready_product_qa),
            "unique_names": unique_count(ready_product_qa, "normalized_name"),
            "unique_oracle_ids": unique_count(ready_product_qa, "oracle_id"),
        },
        "battle_gap": {
            "row_count": len(battle_gap),
            "unique_names": unique_count(battle_gap, "normalized_name"),
            "unique_oracle_ids": unique_count(battle_gap, "oracle_id"),
            "commander_legal_rows": len(commander_legal_gap),
            "commander_legal_unique_names": unique_count(commander_legal_gap, "normalized_name"),
            "external_popularity_rows": len(external_popularity_gap),
            "external_popularity_unique_names": unique_count(external_popularity_gap, "normalized_name"),
            "registered_deck_qa_rows": len(registered_deck_qa_gap),
            "registered_deck_qa_unique_names": unique_count(registered_deck_qa_gap, "normalized_name"),
            "ready_product_qa_rows": len(ready_product_qa_gap),
            "ready_product_qa_unique_names": unique_count(ready_product_qa_gap, "normalized_name"),
        },
        "template_first": {
            "template_count": len(template_rows),
            "matched_rows": sum(row["row_count"] for row in template_rows),
            "matched_unique_names": len(template_matched_names),
            "matched_commander_legal_unique_names": len(template_matched_commander_legal_names),
            "commander_legal_gap_coverage_ratio": round(
                len(template_matched_commander_legal_names) / max(unique_count(commander_legal_gap, "normalized_name"), 1),
                4,
            ),
            "matched_external_popularity_unique_names": len(template_matched_external_names),
            "external_popularity_gap_coverage_ratio": round(
                len(template_matched_external_names) / max(unique_count(external_popularity_gap, "normalized_name"), 1),
                4,
            ),
            "matched_registered_deck_qa_unique_names": len(template_matched_registered_deck_qa_names),
            "registered_deck_qa_gap_coverage_ratio": round(
                len(template_matched_registered_deck_qa_names)
                / max(unique_count(registered_deck_qa_gap, "normalized_name"), 1),
                4,
            ),
            "top_templates": top_templates,
        },
        "family_counts": dict(family_counts.most_common()),
        "unmatched_by_family": dict(unmatched_by_family.most_common(20)),
        "work_unit_comparison": work_unit_comparison(
            battle_gap=battle_gap,
            commander_legal_gap=commander_legal_gap,
            external_popularity_gap=external_popularity_gap,
            registered_deck_qa_gap=registered_deck_qa_gap,
            ready_product_qa_gap=ready_product_qa_gap,
            template_rows=template_rows,
            unmatched_by_family=unmatched_by_family,
        ),
    }


def work_unit_comparison(
    *,
    battle_gap: list[dict[str, Any]],
    commander_legal_gap: list[dict[str, Any]],
    external_popularity_gap: list[dict[str, Any]],
    registered_deck_qa_gap: list[dict[str, Any]],
    ready_product_qa_gap: list[dict[str, Any]],
    template_rows: list[dict[str, Any]],
    unmatched_by_family: Counter[str],
) -> dict[str, Any]:
    row_units = len(battle_gap)
    identity_units = unique_count(battle_gap, "normalized_name")
    commander_legal_units = unique_count(commander_legal_gap, "normalized_name")
    external_popularity_units = unique_count(external_popularity_gap, "normalized_name")
    registered_deck_qa_units = unique_count(registered_deck_qa_gap, "normalized_name")
    ready_product_qa_units = unique_count(ready_product_qa_gap, "normalized_name")
    template_units = len(template_rows) + len([family for family, count in unmatched_by_family.items() if count > 0])
    return {
        "card_row_units_if_done_one_by_one": row_units,
        "identity_units_if_done_by_normalized_name": identity_units,
        "commander_legal_identity_units": commander_legal_units,
        "external_popularity_identity_units": external_popularity_units,
        "registered_deck_qa_identity_units": registered_deck_qa_units,
        "ready_product_qa_identity_units": ready_product_qa_units,
        "template_plus_residual_family_units": template_units,
        "row_to_commander_legal_identity_compression": round(row_units / max(commander_legal_units, 1), 2),
        "row_to_template_family_compression": round(row_units / max(template_units, 1), 2),
        "recommended_execution_order": [
            "Do not adapt 34331 card rows one by one.",
            "First close hash/data-only and true oracle alias gaps.",
            "Then implement top template resolvers by global Commander-legal breadth.",
            "Use external popularity/staple signals as secondary ordering when available.",
            "Use current registered decks only as QA smoke seeds, not as demand priority.",
            "Then split residual high-volume families with XMage source evidence.",
            "Only after template/family coverage is green should card-specific exceptions be scheduled.",
        ],
    }


def build_payload(*, xmage_root: Path, xmage_limit: int) -> dict[str, Any]:
    deck_scope = readiness.fetch_deck_scope()
    rows = readiness.fetch_all_card_rows(deck_scope)
    cards = readiness.build_card_inventory(rows, xmage_root=xmage_root, xmage_limit=xmage_limit)
    popularity_index = fetch_external_popularity_index()
    attach_external_popularity(cards, popularity_index)
    return {
        "generated_at": utc_now(),
        "status": "action_required",
        "contract": readiness.rel(CONTRACT),
        "method": {
            "read_only": True,
            "base_scope": "all PostgreSQL cards rows",
            "current_registered_decks": "internal QA seed only; not a user-demand proxy",
            "external_popularity_signal": "format_staples/EDHREC-rank style signals when present; secondary to global Commander-legal breadth",
            "unit_of_work": "identity/template/family before card-specific exception",
            "xmage_root": str(xmage_root),
            "xmage_source_check_limit": xmage_limit,
            "external_popularity_unique_names": len(popularity_index),
        },
        "summary": summarize(cards),
    }


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    summary = payload["summary"]
    work = summary["work_unit_comparison"]
    lines = [
        "# Global Card Adaptation Acceleration Model",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Contract: `{payload['contract']}`",
        "",
        "## Core Finding",
        "",
        "The all-card adaptation cannot be managed as one PostgreSQL row per card.",
        "The correct unit is identity/template/family, ordered by global Commander-legal breadth.",
        "Current registered deck usage is an internal QA seed only, not a demand signal.",
        "",
        "## Scope Compression",
        "",
        "| Scope | Rows | Unique Names | Unique Oracle IDs |",
        "| --- | ---: | ---: | ---: |",
    ]
    for key in (
        "all_cards",
        "commander_legal",
        "external_popularity_signal",
        "current_registered_deck_qa_seed",
        "ready_product_qa_seed",
    ):
        row = summary[key]
        lines.append(
            f"| `{key}` | {row['row_count']} | {row['unique_names']} | {row['unique_oracle_ids']} |"
        )
    gap = summary["battle_gap"]
    lines.extend(
        [
            "",
            "## Battle Gap Compression",
            "",
            "| Metric | Value |",
            "| --- | ---: |",
        ]
    )
    for key, value in gap.items():
        lines.append(f"| `{key}` | {value} |")

    lines.extend(
        [
            "",
            "## Work Unit Comparison",
            "",
            "| Model | Units |",
            "| --- | ---: |",
            f"| Card row one-by-one | {work['card_row_units_if_done_one_by_one']} |",
            f"| Normalized name identity | {work['identity_units_if_done_by_normalized_name']} |",
            f"| Commander-legal identity scope | {work['commander_legal_identity_units']} |",
            f"| External popularity identity signal | {work['external_popularity_identity_units']} |",
            f"| Current registered-deck QA seed | {work['registered_deck_qa_identity_units']} |",
            f"| Ready-product QA seed | {work['ready_product_qa_identity_units']} |",
            f"| Template + residual family first | {work['template_plus_residual_family_units']} |",
            f"| Row-to-Commander-legal compression | {work['row_to_commander_legal_identity_compression']}x |",
            f"| Row-to-template/family compression | {work['row_to_template_family_compression']}x |",
        ]
    )

    template = summary["template_first"]
    lines.extend(
        [
            "",
            "## Template-First Coverage",
            "",
            f"- Template count: `{template['template_count']}`",
            f"- Matched rows: `{template['matched_rows']}`",
            f"- Matched unique names: `{template['matched_unique_names']}`",
            f"- Matched Commander-legal unique names: `{template['matched_commander_legal_unique_names']}`",
            f"- Commander-legal gap coverage ratio: `{template['commander_legal_gap_coverage_ratio']}`",
            f"- Matched external-popularity unique names: `{template['matched_external_popularity_unique_names']}`",
            f"- External-popularity gap coverage ratio: `{template['external_popularity_gap_coverage_ratio']}`",
            f"- Matched registered-deck QA unique names: `{template['matched_registered_deck_qa_unique_names']}`",
            f"- Registered-deck QA gap coverage ratio: `{template['registered_deck_qa_gap_coverage_ratio']}`",
            "",
            "| Template | Rows | Names | Commander Legal Rows | External Popularity Rows | Registered Deck QA Rows | Ready Product QA Rows | Confidence | Runtime Unit | Samples |",
            "| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- | --- |",
        ]
    )
    for row in template["top_templates"]:
        samples = ", ".join(f"`{name}`" for name in row["sample_cards"][:6])
        lines.append(
            "| `{template}` | {rows} | {names} | {commander} | {external} | {registered} | {ready} | `{confidence}` | {runtime} | {samples} |".format(
                template=row["template"],
                rows=row["row_count"],
                names=row["unique_names"],
                commander=row["commander_legal_rows"],
                external=row["external_popularity_rows"],
                registered=row["registered_deck_qa_rows"],
                ready=row["ready_product_qa_rows"],
                confidence=row["confidence"],
                runtime=row["runtime_unit"],
                samples=samples,
            )
        )

    lines.extend(
        [
            "",
            "## Residual Families After Templates",
            "",
            "| Family | Rows |",
            "| --- | ---: |",
        ]
    )
    for family, count in summary["unmatched_by_family"].items():
        lines.append(f"| `{family}` | {count} |")

    lines.extend(["", "## Required Execution Order", ""])
    for item in work["recommended_execution_order"]:
        lines.append(f"- {item}")
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--xmage-root", type=Path, default=DEFAULT_XMAGE_ROOT)
    parser.add_argument("--xmage-limit", type=int, default=0)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "global_card_adaptation_acceleration_model_20260701",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_payload(xmage_root=args.xmage_root, xmage_limit=args.xmage_limit)
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    write_markdown(payload, md_path)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
