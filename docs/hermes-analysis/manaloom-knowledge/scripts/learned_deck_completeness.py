#!/usr/bin/env python3
"""Shared guards for Hermes learned deck completeness.

Hermes stores decks from several sources. Some rows include the commander in
`card_list`, others store only the 99-card main deck and rely on the
`commander` column. Downstream analysis should not treat partial seeds as full
Commander decks.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from typing import Any


def normalize_card_name(name: str | None) -> str:
    text = str(name or "").strip().lower()
    text = text.replace("\u2018", "'").replace("\u2019", "'")
    return re.sub(r"\s+", " ", text)


@dataclass(frozen=True)
class LearnedDeckCard:
    name: str
    quantity: int


@dataclass(frozen=True)
class LearnedDeckCompleteness:
    parsed_quantity: int
    declared_quantity: int | None
    commander_quantity_in_list: int
    total_with_commander: int
    main_quantity: int

    def eligible_for_training(self, *, min_total: int = 90) -> bool:
        return self.total_with_commander >= min_total

    def is_full_commander_deck(self) -> bool:
        return (
            self.total_with_commander == 100
            and self.main_quantity == 99
            and self.commander_quantity_in_list in (0, 1)
        )


def parse_learned_card_list(raw: str | None) -> list[LearnedDeckCard]:
    if not raw:
        return []
    text = str(raw).strip()
    if not text:
        return []

    parsed_json = _try_json_list(text)
    if parsed_json is not None:
        return parsed_json

    cards: list[LearnedDeckCard] = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        line = re.sub(r"^[-*]\s+", "", line).strip()
        match = re.match(r"^(\d+)\s*x?\s+(.+)$", line, flags=re.I)
        if match:
            quantity = int(match.group(1))
            name = _clean_card_name(match.group(2))
        else:
            quantity = 1
            name = _clean_card_name(line)
        if name:
            cards.append(LearnedDeckCard(name=name, quantity=max(1, quantity)))
    return cards


def learned_deck_completeness(
    raw_card_list: str | None,
    *,
    commander: str | None,
    declared_quantity: int | None = None,
) -> LearnedDeckCompleteness:
    cards = parse_learned_card_list(raw_card_list)
    parsed_quantity = sum(card.quantity for card in cards)
    commander_key = normalize_card_name(commander)
    commander_quantity = 0
    if commander_key:
        commander_quantity = sum(
            card.quantity
            for card in cards
            if normalize_card_name(card.name) == commander_key
        )

    # If the list omits the commander but the commander column is present,
    # downstream materialization adds exactly one commander row.
    commander_supplied_by_column = 1 if commander_key and commander_quantity == 0 else 0
    total_with_commander = parsed_quantity + commander_supplied_by_column
    main_quantity = total_with_commander - 1 if commander_key else parsed_quantity

    return LearnedDeckCompleteness(
        parsed_quantity=parsed_quantity,
        declared_quantity=declared_quantity,
        commander_quantity_in_list=commander_quantity,
        total_with_commander=total_with_commander,
        main_quantity=main_quantity,
    )


def _try_json_list(text: str) -> list[LearnedDeckCard] | None:
    try:
        decoded = json.loads(text)
    except json.JSONDecodeError:
        return None
    if not isinstance(decoded, list):
        return []

    cards: list[LearnedDeckCard] = []
    for item in decoded:
        if isinstance(item, str):
            name = _clean_card_name(item)
            quantity = 1
        elif isinstance(item, dict):
            name = _clean_card_name(item.get("name") or item.get("card_name"))
            quantity = _int_value(item.get("quantity") or item.get("qty") or 1)
        else:
            continue
        if name:
            cards.append(LearnedDeckCard(name=name, quantity=max(1, quantity)))
    return cards


def _clean_card_name(value: Any) -> str:
    name = str(value or "").strip()
    name = re.sub(r"\s+\[[^\]]+\]$", "", name)
    name = re.sub(r"\s+\([A-Z0-9]{2,6}\)\s*\d*\s*$", "", name)
    name = re.sub(r"\s+#.*$", "", name)
    return re.sub(r"\s+", " ", name).strip()


def _int_value(value: Any) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 1
