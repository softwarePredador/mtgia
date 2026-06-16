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
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import battle_rule_registry
from known_cards_fallback_snapshot import load_layered_known_cards


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_REPORT_DIR = SCRIPT_DIR.parents[1] / "master_optimizer_reports"
BATTLE_PATH = Path(os.environ.get("MANALOOM_BATTLE_SCRIPT", SCRIPT_DIR / "battle_analyst_v9.py"))


def load_battle_module(path: Path):
    spec = importlib.util.spec_from_file_location("battle_effect_coverage_battle", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battle = load_battle_module(BATTLE_PATH)

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
    parser.add_argument("--fail-on-high-risk", action="store_true")
    return parser.parse_args()


def fallback_known_cards() -> tuple[dict[str, Any], set[str], set[str]]:
    return load_layered_known_cards()


def effect_source(
    card: dict[str, Any],
    fallback_cards: dict[str, Any],
    canonical_names: set[str],
    generated_only_names: set[str],
    rules: dict[str, dict[str, Any]],
) -> str:
    name = card.get("name", "")
    if "land" in str(card.get("type_line", "")).lower():
        return "type_land"
    rule = rules.get(battle_rule_registry.normalize_card_name(name))
    if rule:
        return f"battle_rule_{rule.get('source', 'unknown')}"
    if name in battle.HANDCRAFTED_KNOWN_CARDS:
        return "handcrafted"
    if name in canonical_names:
        return "known_cards_canonical_snapshot"
    if name in generated_only_names or name in fallback_cards:
        return "generated"
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


def build_audit(args: argparse.Namespace) -> dict[str, Any]:
    battle.DB = args.sqlite_db
    os.environ["MANALOOM_BATTLE_REAL_OPPONENT_LIMIT"] = str(args.opponent_limit)
    os.environ["MANALOOM_BATTLE_REAL_OPPONENT_SEED"] = str(args.seed)

    fallback_cards, canonical_names, generated_only_names = fallback_known_cards()
    rules = battle_rule_registry.load_active_battle_card_rules(args.sqlite_db)
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
            fallback_cards,
            canonical_names,
            generated_only_names,
            rules,
        )
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
                "type_line": card.get("type_line", ""),
                "oracle_sample": (card.get("oracle_text") or "")[:180],
            },
        )
        current["decks"].add(deck_name)
        current["flags"].update(flags)

    cards = []
    for value in by_name.values():
        cards.append({
            **value,
            "decks": sorted(value["decks"]),
            "flags": sorted(value["flags"]),
        })
    cards.sort(key=lambda row: (-len(row["flags"]), row["source"], row["name"]))

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "deck_id": args.deck_id,
        "sqlite_db": args.sqlite_db,
        "opponents_loaded": len(opponents),
        "total_card_instances": len(rows),
        "unique_cards": len(cards),
        "source_totals": dict(source_totals),
        "effect_totals": dict(effect_totals),
        "flag_totals": dict(flag_totals),
        "deck_totals": {deck: dict(counter) for deck, counter in deck_totals.items()},
        "flagged_cards": [card for card in cards if card["flags"]],
        "unknown_cards": [card for card in cards if card["source"] == "unknown"],
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

    lines.extend([
        "",
        "## Deck Coverage",
        "",
        "| Deck | Cards | Battle Manual | Battle Generated | Handcrafted | Generated | Tag | Effect Map | Type Land | Type Creature | Unknown | Flagged |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ])
    for deck, totals in sorted(audit["deck_totals"].items()):
        lines.append(
            "| {deck} | {cards} | {battle_rule_manual} | {battle_rule_generated} | "
            "{handcrafted} | {generated} | {tag} | {effect_map} | {type_land} | "
            "{type_creature} | {unknown} | {flagged} |".format(
                deck=deck,
                cards=totals.get("cards", 0),
                battle_rule_manual=totals.get("battle_rule_manual", 0),
                battle_rule_generated=totals.get("battle_rule_generated", 0),
                handcrafted=totals.get("handcrafted", 0),
                generated=totals.get("generated", 0),
                tag=totals.get("tag", 0),
                effect_map=totals.get("effect_map", 0),
                type_land=totals.get("type_land", 0),
                type_creature=totals.get("type_creature", 0),
                unknown=totals.get("unknown", 0),
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
            "## Unknown Cards",
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
