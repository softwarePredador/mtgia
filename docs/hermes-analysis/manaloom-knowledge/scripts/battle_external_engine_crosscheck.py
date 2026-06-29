#!/usr/bin/env python3
"""Registry for external MTG engine crosschecks beyond XMage.

This module does not execute third-party engines. It records where ManaLoom can
look for independent implementation evidence and how that evidence may be used.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class EngineReference:
    id: str
    name: str
    url: str
    role: str
    confidence_role: str
    adapter_status: str
    source_lookup_policy: str
    use_for: str
    do_not_use_for: str
    candidate_url_templates: tuple[str, ...]


ENGINE_REGISTRY: tuple[EngineReference, ...] = (
    EngineReference(
        id="forge",
        name="Forge",
        url="https://github.com/Card-Forge/forge",
        role="independent_rules_engine",
        confidence_role="primary_external_crosscheck_after_xmage",
        adapter_status="registry_ready_source_lookup_manual_or_api",
        source_lookup_policy="Search Forge card scripts/source for the card or semantic family, then compare behavior to official rules and ManaLoom tests.",
        use_for="Independent implementation comparison for card families missing, ambiguous, or contradicted in XMage.",
        do_not_use_for="Authoritative rules, direct promotion to PostgreSQL, or bypassing ManaLoom runtime fixtures.",
        candidate_url_templates=(
            "https://github.com/Card-Forge/forge/search?q={query}&type=code",
            "https://github.com/Card-Forge/forge/search?q={slug}&type=code",
        ),
    ),
    EngineReference(
        id="magarena",
        name="Magarena",
        url="https://github.com/magarena/magarena",
        role="independent_rules_engine",
        confidence_role="secondary_external_crosscheck",
        adapter_status="registry_ready_source_lookup_manual_or_api",
        source_lookup_policy="Use Magarena scripts/source as a secondary comparison when Forge/XMage are missing or disagree.",
        use_for="Secondary comparison for card scripting and AI-visible behavior.",
        do_not_use_for="Authoritative rules or direct runtime promotion.",
        candidate_url_templates=(
            "https://github.com/magarena/magarena/search?q={query}&type=code",
            "https://github.com/magarena/magarena/search?q={slug}&type=code",
        ),
    ),
    EngineReference(
        id="cockatrice",
        name="Cockatrice",
        url="https://github.com/Cockatrice/Cockatrice",
        role="manual_game_client_and_replay_surface",
        confidence_role="replay_protocol_reference_not_rules_engine",
        adapter_status="registry_ready_replay_reference_only",
        source_lookup_policy="Use Cockatrice for replay/client/game-state vocabulary, not automatic legality or effect resolution.",
        use_for="Manual replay and client state comparison.",
        do_not_use_for="Rules execution truth or card effect implementation.",
        candidate_url_templates=(
            "https://github.com/Cockatrice/Cockatrice/search?q={query}&type=code",
            "https://github.com/Cockatrice/Cockatrice/search?q={slug}&type=code",
        ),
    ),
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=True, indent=2, sort_keys=True)


def slugify_card_name(card_name: str) -> str:
    text = card_name.strip().lower()
    text = re.sub(r"//.*$", "", text).strip()
    text = re.sub(r"[^a-z0-9]+", "_", text)
    return text.strip("_")


def query_for_card(card_name: str) -> str:
    return card_name.strip().replace(" ", "+")


def candidate_links(card_name: str, engine: EngineReference) -> list[str]:
    query = query_for_card(card_name)
    slug = slugify_card_name(card_name)
    return [
        template.format(query=query, slug=slug)
        for template in engine.candidate_url_templates
    ]


def build_crosscheck_plan(card_names: list[str]) -> dict[str, Any]:
    cards = []
    for card_name in card_names:
        cards.append(
            {
                "card_name": card_name,
                "normalized_slug": slugify_card_name(card_name),
                "engine_candidates": [
                    {
                        "engine_id": engine.id,
                        "engine_name": engine.name,
                        "role": engine.role,
                        "confidence_role": engine.confidence_role,
                        "adapter_status": engine.adapter_status,
                        "candidate_links": candidate_links(card_name, engine),
                    }
                    for engine in ENGINE_REGISTRY
                ],
            }
        )

    return {
        "generated_at_utc": utc_now(),
        "postgres_writes": False,
        "registry_status": "external_engine_crosscheck_registry_ready",
        "engine_count": len(ENGINE_REGISTRY),
        "cards_requested": len(card_names),
        "engines": [asdict(engine) for engine in ENGINE_REGISTRY],
        "cards": cards,
        "promotion_policy": [
            "External engines provide comparison evidence only.",
            "Official Wizards rules plus Oracle/rulings remain the semantic authority.",
            "Any promoted ManaLoom rule still needs local runtime tests and, if PostgreSQL is touched, an explicit reviewed package.",
        ],
    }


def render_markdown(plan: dict[str, Any]) -> str:
    lines = [
        "# External Engine Crosscheck Registry",
        "",
        f"- Generated UTC: `{plan['generated_at_utc']}`",
        f"- PostgreSQL writes: `{plan['postgres_writes']}`",
        f"- Registry status: `{plan['registry_status']}`",
        f"- Engines: `{plan['engine_count']}`",
        f"- Cards requested: `{plan['cards_requested']}`",
        "",
        "## Engines",
        "",
        "| Engine | Role | Confidence role | Adapter status | Use | Do not use for |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for engine in plan["engines"]:
        lines.append(
            "| [{name}]({url}) | `{role}` | `{confidence_role}` | `{adapter_status}` | {use_for} | {do_not_use_for} |".format(
                **engine
            )
        )

    if plan["cards"]:
        lines.extend(["", "## Card Lookup Candidates", ""])
        for card in plan["cards"]:
            lines.append(f"### {card['card_name']}")
            lines.append("")
            for engine in card["engine_candidates"]:
                links = ", ".join(f"[{engine['engine_name']} search]({url})" for url in engine["candidate_links"])
                lines.append(f"- `{engine['engine_id']}`: {links}")

    lines.extend(["", "## Promotion Policy", ""])
    for policy in plan["promotion_policy"]:
        lines.append(f"- {policy}")
    return "\n".join(lines) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--card", action="append", default=[])
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--output", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    plan = build_crosscheck_plan(args.card)
    markdown = render_markdown(plan)

    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(stable_json(plan) + "\n", encoding="utf-8")
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(markdown, encoding="utf-8")
    if not args.output and not args.json_output:
        print(markdown)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
