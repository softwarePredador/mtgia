#!/usr/bin/env python3
"""Audit battle effect coverage for Lorehold and real opponent decks.

The battle simulator intentionally uses a mix of explicit rules and heuristics.
This audit makes that visible so real decks do not silently collapse into
generic creature/ramp/removal behavior.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import battle_rule_registry
from known_cards_fallback_snapshot import load_layered_known_cards


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
SERVER_BIN = REPO_ROOT / "server/bin"
DEFAULT_REPORT_DIR = SCRIPT_DIR.parents[1] / "master_optimizer_reports"
BATTLE_PATH = Path(os.environ.get("MANALOOM_BATTLE_SCRIPT", SCRIPT_DIR / "battle_analyst_v9.py"))
UNKNOWN_TEMPLATE_AUDIT_PATH = SCRIPT_DIR / "battle_unknown_template_backlog_audit.py"
FOCUSED_EVIDENCE_PATH = SERVER_BIN / "manaloom_battle_rule_focused_evidence.py"
REVIEW_QUEUE_PATH = SERVER_BIN / "manaloom_battle_rule_review_queue.py"


def load_battle_module(path: Path):
    spec = importlib.util.spec_from_file_location("battle_effect_coverage_battle", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battle = load_battle_module(BATTLE_PATH)
_focused_contract_modules: tuple[Any, Any, Any] | None = None

REMOVAL_EFFECTS = {
    "remove_creature",
    "remove_permanent",
    "remove_artifact_or_3dmg",
    "board_wipe",
    "damage_wipe",
}

LAND_UTILITY_PATTERNS = (
    "channel",
    "destroy target",
    "exile target",
    "return target",
    "create ",
    "draw ",
    "until end of turn",
    "whenever",
    "activated ability",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--sqlite-db", default=battle.DB)
    parser.add_argument("--opponent-limit", type=int, default=12)
    parser.add_argument("--seed", default="20260607")
    parser.add_argument("--report", action="store_true")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--fail-on-high-risk", action="store_true")
    return parser.parse_args()


def fallback_known_cards() -> set[str]:
    _fallback_cards, canonical_names, _generated_only_names = load_layered_known_cards()
    return canonical_names


def effect_source(
    card: dict[str, Any],
    canonical_names: set[str],
    rules: dict[str, dict[str, Any]],
    review_rules: dict[str, dict[str, Any]] | None = None,
) -> str:
    name = card.get("name", "")
    if "land" in str(card.get("type_line", "")).lower():
        return "type_land"
    normalized_name = battle_rule_registry.normalize_card_name(name)
    rule = rules.get(normalized_name)
    if rule:
        return f"battle_rule_{rule.get('source', 'unknown')}"
    review_rule = (review_rules or {}).get(normalized_name)
    if review_rule:
        review_status = str(review_rule.get("review_status") or "").lower()
        execution_status = str(review_rule.get("execution_status") or "").lower()
        if review_status == "needs_review":
            return f"battle_rule_needs_review_{review_rule.get('source', 'unknown')}"
        if execution_status == "review_only":
            return f"battle_rule_review_only_{review_rule.get('source', 'unknown')}"
        return f"battle_rule_non_runtime_{review_rule.get('source', 'unknown')}"
    if name in battle.HANDCRAFTED_KNOWN_CARDS:
        return "handcrafted"
    if name in canonical_names:
        return "known_cards_canonical_snapshot"
    if card.get("tag") in battle.TAG_EFFECTS:
        return "tag"
    effect = card.get("effect", "")
    if effect in {
        "ramp",
        "removal",
        "board_wipe",
        "wincon",
        "draw",
        "counter",
        "land",
        "creature",
    }:
        return "effect_map"
    if "creature" in str(card.get("type_line", "")).lower():
        return "type_creature"
    return "unknown"


def load_named_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def focused_contract_modules():
    global _focused_contract_modules
    if _focused_contract_modules is None:
        review_module = load_named_module(
            "manaloom_battle_rule_review_queue_for_effect_coverage",
            REVIEW_QUEUE_PATH,
        )
        focused_module = load_named_module(
            "manaloom_battle_rule_focused_evidence_for_effect_coverage",
            FOCUSED_EVIDENCE_PATH,
        )
        backlog_module = load_named_module(
            "battle_unknown_template_backlog_for_effect_coverage",
            UNKNOWN_TEMPLATE_AUDIT_PATH,
        )
        _focused_contract_modules = (review_module, focused_module, backlog_module)
    return _focused_contract_modules


def focused_template_matches(card: dict[str, Any]) -> list[str]:
    name = str(card.get("name") or "")
    text = str(card.get("oracle_text") or card.get("oracle_sample") or "")
    review_module, focused_module, backlog_module = focused_contract_modules()
    current_families = review_module.infer_effect_families_from_text(text)
    plan = backlog_module.BACKLOG_PLAN.get(name, {})
    reviewed_families = [str(item) for item in plan.get("families", [])]
    families = sorted(set(current_families) | set(reviewed_families))
    if not families:
        return []
    draft = focused_module.DraftRecord(
        run_id="effect_coverage_focused_template_contract",
        card_name=name,
        oracle_id=None,
        set_code="",
        draft_rule_key="effect_coverage_focused_template_contract",
        proposed_status="needs_review",
        confidence="low",
        roles=[],
        effect_families=families,
        risk_flags=[],
        draft={"oracle_text_excerpt": text},
    )
    matches: list[str] = []
    for support_name in sorted(dir(focused_module)):
        if not support_name.startswith("supports_") or not support_name.endswith("_template"):
            continue
        func = getattr(focused_module, support_name)
        try:
            if func(draft):
                matches.append(support_name)
        except Exception:
            continue
    return matches


def focused_template_effect_scopes(matches: list[str]) -> list[str]:
    scopes = []
    for match in matches:
        if not match.startswith("supports_") or not match.endswith("_template"):
            continue
        scopes.append(match.removeprefix("supports_").removesuffix("_template"))
    return sorted(set(scopes))


def rule_status_summary(
    runtime_safe_rules: dict[str, dict[str, Any]],
    active_or_review_rules: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    review_status_counts = Counter(
        str(rule.get("review_status") or "unknown").lower()
        for rule in active_or_review_rules.values()
    )
    execution_status_counts = Counter(
        str(rule.get("execution_status") or "auto").lower()
        for rule in active_or_review_rules.values()
    )
    runtime_safe_names = set(runtime_safe_rules)
    active_or_review_names = set(active_or_review_rules)
    non_runtime_safe_names = active_or_review_names - runtime_safe_names
    needs_review_names = {
        name
        for name, rule in active_or_review_rules.items()
        if str(rule.get("review_status") or "").lower() == "needs_review"
    }
    review_only_names = {
        name
        for name, rule in active_or_review_rules.items()
        if str(rule.get("execution_status") or "").lower() == "review_only"
    }
    annotation_only_names = {
        name
        for name, rule in active_or_review_rules.items()
        if str(rule.get("execution_status") or "").lower() == "annotation_only"
    }
    non_runtime_other_names = (
        non_runtime_safe_names
        - needs_review_names
        - review_only_names
        - annotation_only_names
    )
    return {
        "runtime_safe_rule_names": len(runtime_safe_names),
        "active_or_review_rule_names": len(active_or_review_names),
        "non_runtime_safe_rule_names": len(non_runtime_safe_names),
        "needs_review_rule_names": len(needs_review_names),
        "review_only_rule_names": len(review_only_names),
        "annotation_only_rule_names": len(annotation_only_names),
        "non_runtime_other_rule_names": len(non_runtime_other_names),
        "review_status_counts": dict(sorted(review_status_counts.items())),
        "execution_status_counts": dict(sorted(execution_status_counts.items())),
    }


def normalized_text(card: dict[str, Any]) -> str:
    return f"{card.get('type_line') or ''}\n{card.get('oracle_text') or ''}".lower()


def risk_flags(card: dict[str, Any], effect: str, source: str) -> list[str]:
    text = normalized_text(card)
    flags: list[str] = []
    is_land = "land" in str(card.get("type_line", "")).lower()
    if source == "unknown":
        flags.append("unknown_effect")
    if source in {
        "generated",
        "tag",
        "effect_map",
        "type_creature",
        "battle_rule_generated",
        "battle_rule_heuristic",
    }:
        flags.append("heuristic_effect")
    if source.startswith("battle_rule_review_only_"):
        flags.append("review_only_rule")
    if source.startswith("battle_rule_needs_review_"):
        flags.append("needs_review_rule")
    if source.startswith("battle_rule_non_runtime_"):
        flags.append("non_runtime_rule")
    if (
        re.search(r"\b(destroy|exile)\s+target\b", text)
        and effect not in REMOVAL_EFFECTS
        and not is_land
    ):
        flags.append("oracle_target_removal_mismatch")
    if "counter target" in text and effect != "counter":
        flags.append("oracle_counter_mismatch")
    if "can't be countered" in text and effect == "silence_opponents":
        flags.append("cant_be_countered_misread_as_silence")
    if re.search(r"opponents? can't cast", text) and effect != "silence_opponents":
        flags.append("oracle_silence_mismatch")
    if is_land and effect == "land" and any(pattern in text for pattern in LAND_UTILITY_PATTERNS):
        flags.append("land_utility_ability_not_modeled")
    if "until end of turn" in text and source not in {"handcrafted", "type_land"}:
        flags.append("temporary_effect_not_explicit")
    if "whenever" in text and source not in {"handcrafted", "type_land"}:
        flags.append("trigger_not_explicit")
    if "you may cast" in text and source not in {"handcrafted", "type_land"}:
        flags.append("cast_permission_not_explicit")
    if "copy target" in text and effect not in {"copy_spell", "redirect_removal"}:
        flags.append("copy_effect_mismatch")
    if is_land and effect not in {"land", "ramp_permanent"}:
        flags.append("land_effect_mismatch")
    return flags


def iter_deck_cards(deck_name: str, cards: list[dict[str, Any]]):
    for card in cards:
        if isinstance(card, dict) and card.get("name"):
            yield deck_name, card


def unknown_effect_status(card: dict[str, Any]) -> str:
    source = card.get("source") or "unknown"
    flags = set(card.get("flags") or [])
    if source == "focused_template_ready":
        return "focused_template_ready"
    if source == "unknown":
        return "source_unknown"
    if source.startswith("battle_rule_needs_review") or "needs_review_rule" in flags:
        return "needs_review"
    if source.startswith("battle_rule_review_only"):
        return "review_only"
    if source == "battle_rule_curated":
        return "waived_curated_unknown_effect"
    return "tracked_unknown_effect"


def unknown_effect_owner(status: str) -> str:
    return {
        "focused_template_ready": "battle-focused-template-contract",
        "needs_review": "battle-rule-review-queue",
        "review_only": "battle-rule-review-queue",
        "source_unknown": "battle-unknown-template-backlog",
        "waived_curated_unknown_effect": "battle-effect-contract",
    }.get(status, "battle-effect-contract")


def unknown_effect_card_entry(card: dict[str, Any]) -> dict[str, Any]:
    status = unknown_effect_status(card)
    return {
        "name": card.get("name"),
        "effect": card.get("effect") or "unknown",
        "source": card.get("source") or "unknown",
        "status": status,
        "owner": unknown_effect_owner(status),
        "flags": sorted(card.get("flags") or []),
        "decks": sorted(card.get("decks") or []),
        "focused_template_matches": sorted(card.get("focused_template_matches") or []),
        "focused_template_effect_scopes": sorted(
            card.get("focused_template_effect_scopes") or []
        ),
        "type_line": card.get("type_line", ""),
        "waiver_reason": (
            "curated_rule_with_unknown_effect_family_kept_visible_in_unknown_effect_denominator"
            if status == "waived_curated_unknown_effect"
            else None
        ),
    }


SOURCE_COLUMN_ORDER = [
    "battle_rule_curated",
    "battle_rule_needs_review_generated",
    "battle_rule_review_only_manual",
    "battle_rule_review_only_generated",
    "focused_template_ready",
    "handcrafted",
    "effect_map",
    "tag",
    "type_land",
    "type_creature",
    "unknown",
]


def source_column_label(source: str) -> str:
    return source.replace("_", " ").title()


def ordered_source_columns(audit: dict[str, Any]) -> list[str]:
    sources = set(audit.get("source_totals") or {})
    for totals in (audit.get("deck_totals") or {}).values():
        sources.update(
            key
            for key in totals
            if key not in {"cards", "flagged"} and (totals.get(key) or 0)
        )
    ordered = [source for source in SOURCE_COLUMN_ORDER if source in sources]
    ordered.extend(sorted(sources.difference(ordered)))
    return ordered


def build_audit(args: argparse.Namespace) -> dict[str, Any]:
    battle.DB = args.sqlite_db
    os.environ["MANALOOM_BATTLE_REAL_OPPONENT_LIMIT"] = str(args.opponent_limit)
    os.environ["MANALOOM_BATTLE_REAL_OPPONENT_SEED"] = str(args.seed)

    canonical_names = fallback_known_cards()
    runtime_safe_rules = battle_rule_registry.load_active_battle_card_rules(
        args.sqlite_db,
        runtime_safe_only=True,
    )
    review_rules = battle_rule_registry.load_active_battle_card_rules(args.sqlite_db)
    status_summary = rule_status_summary(runtime_safe_rules, review_rules)
    commander, lorehold_deck = battle.load_deck(args.deck_id)
    lorehold_cards = ([commander] if commander else []) + lorehold_deck
    opponents = battle.load_learned_opponents()

    rows = []
    for deck_name, card in iter_deck_cards("Lorehold target deck", lorehold_cards):
        rows.append((deck_name, card))
    for opponent in opponents:
        for deck_name, card in iter_deck_cards(opponent["name"], opponent["built_deck"]):
            rows.append((deck_name, card))

    by_name: dict[str, dict[str, Any]] = {}
    deck_totals = defaultdict(Counter)
    source_totals = Counter()
    effect_totals = Counter()
    flag_totals = Counter()

    for deck_name, card in rows:
        name = card.get("name", "?")
        effect = battle.get_card_effect(card).get("effect", "unknown")
        source = effect_source(
            card,
            canonical_names,
            runtime_safe_rules,
            review_rules,
        )
        focused_matches: list[str] = []
        focused_scopes: list[str] = []
        if source == "unknown":
            focused_matches = focused_template_matches(card)
            if focused_matches:
                source = "focused_template_ready"
                focused_scopes = focused_template_effect_scopes(focused_matches)
        flags = risk_flags(card, effect, source)
        source_totals[source] += 1
        effect_totals[effect] += 1
        for flag in flags:
            flag_totals[flag] += 1
        deck_totals[deck_name]["cards"] += 1
        deck_totals[deck_name][source] += 1
        if flags:
            deck_totals[deck_name]["flagged"] += 1

        current = by_name.setdefault(
            name,
            {
                "name": name,
                "effect": effect,
                "source": source,
                "decks": set(),
                "flags": set(),
                "focused_template_matches": set(),
                "focused_template_effect_scopes": set(),
                "type_line": card.get("type_line", ""),
                "oracle_sample": (card.get("oracle_text") or "")[:180],
            },
        )
        current["decks"].add(deck_name)
        current["flags"].update(flags)
        current["focused_template_matches"].update(focused_matches)
        current["focused_template_effect_scopes"].update(focused_scopes)

    cards = []
    for value in by_name.values():
        cards.append({
            **value,
            "decks": sorted(value["decks"]),
            "flags": sorted(value["flags"]),
            "focused_template_matches": sorted(value["focused_template_matches"]),
            "focused_template_effect_scopes": sorted(value["focused_template_effect_scopes"]),
        })
    cards.sort(key=lambda row: (-len(row["flags"]), row["source"], row["name"]))
    focused_template_cards = [
        card for card in cards if card["source"] == "focused_template_ready"
    ]
    focused_template_effect_scope_totals = Counter()
    for card in focused_template_cards:
        for scope in card["focused_template_effect_scopes"]:
            focused_template_effect_scope_totals[scope] += 1
    unknown_effect_cards = [
        unknown_effect_card_entry(card)
        for card in cards
        if (card.get("effect") or "unknown") == "unknown"
    ]
    unknown_effect_source_counts = Counter(
        card["source"] for card in unknown_effect_cards
    )
    unknown_effect_status_counts = Counter(
        card["status"] for card in unknown_effect_cards
    )

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "deck_id": args.deck_id,
        "sqlite_db": args.sqlite_db,
        "opponents_loaded": len(opponents),
        "total_card_instances": len(rows),
        "unique_cards": len(cards),
        **status_summary,
        "source_totals": dict(source_totals),
        "effect_totals": dict(effect_totals),
        "focused_template_effect_scope_totals": dict(focused_template_effect_scope_totals),
        "flag_totals": dict(flag_totals),
        "deck_totals": {deck: dict(counter) for deck, counter in deck_totals.items()},
        "flagged_cards": [card for card in cards if card["flags"]],
        "unknown_cards": [card for card in cards if card["source"] == "unknown"],
        "unknown_effect_cards": unknown_effect_cards,
        "unknown_effect_source_counts": dict(sorted(unknown_effect_source_counts.items())),
        "unknown_effect_status_counts": dict(sorted(unknown_effect_status_counts.items())),
        "focused_template_ready_unknown_effect_cards": [
            card
            for card in unknown_effect_cards
            if card["status"] == "focused_template_ready"
        ],
        "needs_review_unknown_effect_cards": [
            card
            for card in unknown_effect_cards
            if card["status"] == "needs_review"
        ],
        "focused_template_cards": focused_template_cards,
        "focused_template_unknown_effect_scope_cards": [
            {
                "name": card["name"],
                "effect": card["effect"],
                "focused_template_effect_scopes": card["focused_template_effect_scopes"],
            }
            for card in cards
            if card["source"] == "focused_template_ready" and card["effect"] == "unknown"
        ],
    }


def render_markdown(audit: dict[str, Any]) -> str:
    lines = [
        "# Battle Effect Coverage Audit",
        "",
        f"- generated_at: {audit['generated_at']}",
        f"- deck_id: {audit['deck_id']}",
        f"- opponents_loaded: {audit['opponents_loaded']}",
        f"- total_card_instances: {audit['total_card_instances']}",
        f"- unique_cards: {audit['unique_cards']}",
        f"- runtime_safe_rule_names: {audit.get('runtime_safe_rule_names', 0)}",
        f"- active_or_review_rule_names: {audit.get('active_or_review_rule_names', 0)}",
        f"- non_runtime_safe_rule_names: {audit.get('non_runtime_safe_rule_names', 0)}",
        f"- needs_review_rule_names: {audit.get('needs_review_rule_names', 0)}",
        f"- review_only_rule_names: {audit.get('review_only_rule_names', 0)}",
        f"- annotation_only_rule_names: {audit.get('annotation_only_rule_names', 0)}",
        f"- non_runtime_other_rule_names: {audit.get('non_runtime_other_rule_names', 0)}",
        f"- review_status_counts: {json.dumps(audit.get('review_status_counts', {}), sort_keys=True)}",
        f"- execution_status_counts: {json.dumps(audit.get('execution_status_counts', {}), sort_keys=True)}",
        "",
        "## Source Totals",
        "",
        "| Source | Count |",
        "| --- | ---: |",
    ]
    for source, count in sorted(audit["source_totals"].items()):
        lines.append(f"| {source} | {count} |")

    lines.extend([
        "",
        "## Risk Flags",
        "",
        "| Flag | Count |",
        "| --- | ---: |",
    ])
    for flag, count in sorted(audit["flag_totals"].items()):
        lines.append(f"| {flag} | {count} |")

    source_columns = ordered_source_columns(audit)
    source_header = " | ".join(source_column_label(source) for source in source_columns)
    source_align = " | ".join("---:" for _source in source_columns)
    lines.extend([
        "",
        "## Deck Coverage",
        "",
        f"| Deck | Cards | {source_header} | Flagged |",
        f"| --- | ---: | {source_align} | ---: |",
    ])
    for deck, totals in sorted(audit["deck_totals"].items()):
        source_values = " | ".join(str(totals.get(source, 0)) for source in source_columns)
        lines.append(
            "| {deck} | {cards} | {source_values} | {flagged} |".format(
                deck=deck.replace("|", "\\|"),
                cards=totals.get("cards", 0),
                source_values=source_values,
                flagged=totals.get("flagged", 0),
            )
        )

    lines.extend([
        "",
        "## Highest Risk Cards",
        "",
        "| Card | Effect | Source | Flags | Decks |",
        "| --- | --- | --- | --- | --- |",
    ])
    for card in audit["flagged_cards"][:80]:
        lines.append(
            "| {name} | {effect} | {source} | {flags} | {decks} |".format(
                name=card["name"].replace("|", "\\|"),
                effect=card["effect"],
                source=card["source"],
                flags=", ".join(card["flags"]),
                decks=", ".join(card["decks"][:4]).replace("|", "\\|"),
            )
        )

    if audit["unknown_cards"]:
        lines.extend([
            "",
            "## Source Unknown Cards",
            "",
            "| Card | Decks | Type |",
            "| --- | --- | --- |",
        ])
        for card in audit["unknown_cards"][:80]:
            lines.append(
                "| {name} | {decks} | {type_line} |".format(
                    name=card["name"].replace("|", "\\|"),
                    decks=", ".join(card["decks"][:4]).replace("|", "\\|"),
                    type_line=str(card.get("type_line") or "").replace("|", "\\|"),
                )
            )

    if audit.get("unknown_effect_cards"):
        lines.extend([
            "",
            "## Unknown Effect Denominator",
            "",
            f"- Unknown effect cards: `{len(audit['unknown_effect_cards'])}`",
            f"- Unknown effect source counts: `{json.dumps(audit.get('unknown_effect_source_counts') or {}, sort_keys=True)}`",
            f"- Unknown effect status counts: `{json.dumps(audit.get('unknown_effect_status_counts') or {}, sort_keys=True)}`",
            "",
            "| Card | Source | Status | Owner | Flags | Decks | Effect scopes |",
            "| --- | --- | --- | --- | --- | --- | --- |",
        ])
        for card in audit["unknown_effect_cards"][:80]:
            lines.append(
                "| {name} | {source} | {status} | {owner} | {flags} | {decks} | {scopes} |".format(
                    name=card["name"].replace("|", "\\|"),
                    source=card["source"],
                    status=card["status"],
                    owner=card["owner"],
                    flags=", ".join(card["flags"]).replace("|", "\\|"),
                    decks=", ".join(card["decks"][:4]).replace("|", "\\|"),
                    scopes=", ".join(card["focused_template_effect_scopes"]).replace("|", "\\|"),
                )
            )

    if audit["focused_template_cards"]:
        lines.extend([
            "",
        "## Focused Template Ready Cards",
        "",
            "| Card | Effect | Decks | Templates | Effect Scopes |",
            "| --- | --- | --- | --- | --- |",
        ])
        for card in audit["focused_template_cards"][:80]:
            lines.append(
                "| {name} | {effect} | {decks} | {templates} | {scopes} |".format(
                    name=card["name"].replace("|", "\\|"),
                    effect=card["effect"],
                    decks=", ".join(card["decks"][:4]).replace("|", "\\|"),
                    templates=", ".join(card["focused_template_matches"]).replace("|", "\\|"),
                    scopes=", ".join(card["focused_template_effect_scopes"]).replace("|", "\\|"),
                )
            )

    lines.append("")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    audit = build_audit(args)
    markdown = render_markdown(audit)
    print(markdown)

    if args.report:
        DEFAULT_REPORT_DIR.mkdir(parents=True, exist_ok=True)
        stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        md_path = DEFAULT_REPORT_DIR / f"battle_effect_coverage_audit_{stamp}.md"
        json_path = DEFAULT_REPORT_DIR / f"battle_effect_coverage_audit_{stamp}.json"
        md_path.write_text(markdown, encoding="utf-8")
        json_path.write_text(json.dumps(audit, ensure_ascii=True, indent=2), encoding="utf-8")
        print(f"Markdown report: {md_path}")
        print(f"JSON report: {json_path}")
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(markdown, encoding="utf-8")
        print(f"Markdown report: {args.output}")
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(audit, ensure_ascii=True, indent=2), encoding="utf-8")
        print(f"JSON report: {args.json_output}")

    high_risk = sum(
        count
        for flag, count in audit["flag_totals"].items()
        if flag not in {"heuristic_effect"}
    )
    if args.fail_on_high_risk and high_risk:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
