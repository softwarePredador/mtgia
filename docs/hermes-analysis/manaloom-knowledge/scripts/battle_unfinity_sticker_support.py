#!/usr/bin/env python3
"""Shared Unfinity ticket and sticker state for the compact battle runtime."""

from __future__ import annotations

import copy
import random
import re
from typing import Any, Iterable


STICKER_KINDS = {"name", "art", "ability", "power_toughness"}
VOWELS = set("aeiouy")


def _ability(text: str, cost: int, *, keywords: Iterable[str] = (), score: int = 4) -> dict[str, Any]:
    keyword_values = list(keywords)
    return {
        "kind": "ability",
        "text": text,
        "ticket_cost": cost,
        "keywords": keyword_values,
        "runtime_supported": bool(keyword_values),
        "score": score,
    }


def _pt(power: int, toughness: int, cost: int) -> dict[str, Any]:
    return {
        "kind": "power_toughness",
        "power": power,
        "toughness": toughness,
        "ticket_cost": cost,
        "score": power + toughness,
    }


def _sheet(
    name: str,
    name_stickers: Iterable[str],
    abilities: Iterable[dict[str, Any]],
    power_toughness: Iterable[dict[str, Any]],
) -> dict[str, Any]:
    return {
        "name": name,
        "name_stickers": [
            {"kind": "name", "text": value, "ticket_cost": 0}
            for value in name_stickers
        ],
        "art_stickers": [
            {"kind": "art", "text": f"{name} art {index}", "ticket_cost": 0}
            for index in range(1, 4)
        ],
        "ability_stickers": [copy.deepcopy(value) for value in abilities],
        "power_toughness_stickers": [copy.deepcopy(value) for value in power_toughness],
    }


# Constructed play requires at least ten unique sheets and randomly exposes
# three. This fixed legal baseline keeps battle seeds reproducible while callers
# may replace player.sticker_sheets with a deck-specific supplemental list.
DEFAULT_CONSTRUCTED_STICKER_SHEETS = (
    _sheet(
        "Ancestral Hot Dog Minotaur",
        ("Ancestral", "Hot Dog", "Minotaur"),
        (
            _ability("Afflict 2", 2, score=3),
            _ability("Flying", 3, keywords=("flying",), score=6),
        ),
        (_pt(1, 4, 2), _pt(8, 6, 5)),
    ),
    _sheet(
        "Carnival Elephant Meteor",
        ("Carnival", "Elephant", "Meteor"),
        (
            _ability("Sacrifice this permanent: Draw two cards.", 2, score=6),
            _ability("Whenever this creature attacks, proliferate.", 3, score=6),
        ),
        (_pt(4, 1, 2), _pt(8, 7, 5)),
    ),
    _sheet(
        "Contortionist Otter Storm",
        ("Contortionist", "Otter", "Storm"),
        (
            _ability("{T}: Target creature gains haste until end of turn.", 2, score=4),
            _ability(
                "Deathtouch, lifelink",
                4,
                keywords=("deathtouch", "lifelink"),
                score=8,
            ),
        ),
        (_pt(5, 1, 2), _pt(3, 5, 3)),
    ),
    _sheet(
        "Cool Fluffy Loxodon",
        ("Cool", "Fluffy", "Loxodon"),
        (
            _ability("When this permanent leaves the battlefield, draw a card.", 2, score=5),
            _ability("Creature entry makes this permanent 13/13 until end of turn.", 5, score=10),
        ),
        (_pt(4, 2, 2), _pt(5, 6, 4)),
    ),
    _sheet(
        "Cursed Firebreathing Yogurt",
        ("Cursed", "Firebreathing", "Yogurt"),
        (
            _ability("Prowess, prowess", 2, keywords=("prowess",), score=6),
            _ability("{2}, {T}: This permanent deals 2 damage to any target.", 5, score=7),
        ),
        (_pt(4, 2, 2), _pt(4, 8, 4)),
    ),
    _sheet(
        "Deep-Fried Plague Myr",
        ("Deep-Fried", "Plague", "Myr"),
        (
            _ability("Whenever this creature attacks, scry 1.", 2, score=4),
            _ability("When this permanent leaves, destroy an artifact or enchantment.", 3, score=6),
        ),
        (_pt(4, 5, 3), _pt(8, 4, 4)),
    ),
    _sheet(
        "Demonic Tourist Laser",
        ("Demonic", "Tourist", "Laser"),
        (
            _ability("Outlast {1}", 2, score=4),
            _ability("When this permanent dies, you get seven tickets.", 3, score=7),
        ),
        (_pt(1, 4, 2), _pt(9, 6, 5)),
    ),
    _sheet(
        "Eldrazi Guacamole Tightrope",
        ("Eldrazi", "Guacamole", "Tightrope"),
        (
            _ability("Haste", 2, keywords=("haste",), score=5),
            _ability("You may cast this card from your graveyard by paying 2 life.", 5, score=8),
        ),
        (_pt(1, 4, 2), _pt(5, 3, 3)),
    ),
    _sheet(
        "Elemental Time Flamingo",
        ("Elemental", "Time", "Flamingo"),
        (
            _ability("Exile this permanent: Cast a nonland card from your graveyard this turn.", 2, score=6),
            _ability("Whenever your creature dies, each opponent loses 1 life and you gain 1 life.", 4, score=8),
        ),
        (_pt(1, 5, 2), _pt(5, 4, 3)),
    ),
    _sheet(
        "Eternal Acrobat Toast",
        ("Eternal", "Acrobat", "Toast"),
        (
            _ability("Combat damage to a player blinks a creature you control.", 2, score=7),
            _ability("{T}: Untap another target permanent.", 3, score=5),
        ),
        (_pt(4, 4, 3), _pt(7, 8, 5)),
    ),
)


def unique_vowel_count(value: str) -> int:
    return len(VOWELS.intersection(str(value or "").lower()))


def letter_count(value: str, letter: str) -> int:
    return str(value or "").lower().count(str(letter or "").lower()[:1])


def _name_score(sticker: dict[str, Any], metric: str | None) -> tuple[int, int, str]:
    text = str(sticker.get("text") or "")
    metric = str(metric or "").strip().lower()
    if metric == "unique_vowels":
        primary = unique_vowel_count(text)
    elif metric.startswith("letter_"):
        primary = letter_count(text, metric.removeprefix("letter_"))
    elif metric == "length_at_least_8":
        primary = 100 + len(text) if len(text.replace(" ", "")) >= 8 else len(text)
    elif metric == "length_at_most_7":
        primary = 100 + len(text) if len(text.replace(" ", "")) <= 7 else 0
    else:
        primary = unique_vowel_count(text) * 10 + len(text)
    return primary, len(text), text


def ensure_sticker_state(player: Any, rng: random.Random | None = None) -> dict[str, Any]:
    if getattr(player, "_sticker_state_initialized", False):
        return {
            "sheet_count": len(getattr(player, "sticker_sheets", []) or []),
            "active_sheet_count": len(getattr(player, "active_sticker_sheets", []) or []),
        }
    sheets = list(getattr(player, "sticker_sheets", []) or DEFAULT_CONSTRUCTED_STICKER_SHEETS)
    if len(sheets) < 10:
        raise ValueError("constructed sticker runtime requires at least ten unique sheets")
    names = [str(sheet.get("name") or "") for sheet in sheets if isinstance(sheet, dict)]
    if len(names) != len(set(names)):
        raise ValueError("constructed sticker sheets must be unique")
    chooser = rng or random.Random(0)
    player.sticker_sheets = copy.deepcopy(sheets)
    player.active_sticker_sheets = copy.deepcopy(chooser.sample(sheets, 3))
    player.used_sticker_ids = set()
    player._sticker_state_initialized = True
    return {"sheet_count": len(sheets), "active_sheet_count": 3}


def available_stickers(player: Any, kind: str | None = None) -> list[dict[str, Any]]:
    ensure_sticker_state(player)
    requested = str(kind or "").strip().lower()
    values: list[dict[str, Any]] = []
    keys = {
        "name": ("name_stickers",),
        "art": ("art_stickers",),
        "ability": ("ability_stickers",),
        "power_toughness": ("power_toughness_stickers",),
        "any": ("name_stickers", "art_stickers", "ability_stickers", "power_toughness_stickers"),
        "": ("name_stickers", "art_stickers", "ability_stickers", "power_toughness_stickers"),
    }.get(requested, ())
    for sheet_index, sheet in enumerate(getattr(player, "active_sticker_sheets", []) or []):
        for key in keys:
            for sticker_index, sticker in enumerate(sheet.get(key) or []):
                candidate = copy.deepcopy(sticker)
                candidate["sheet_name"] = sheet.get("name")
                candidate["sticker_id"] = f"{sheet_index}:{key}:{sticker_index}"
                if candidate["sticker_id"] not in getattr(player, "used_sticker_ids", set()):
                    values.append(candidate)
    return values


def choose_sticker(
    player: Any,
    *,
    kind: str = "any",
    metric: str | None = None,
    max_ticket_cost: int | None = None,
    without_paying: bool = False,
) -> dict[str, Any] | None:
    tickets = max(0, int(getattr(player, "tickets", 0) or 0))
    affordable = []
    for sticker in available_stickers(player, kind):
        if sticker.get("kind") == "ability" and not sticker.get("runtime_supported"):
            continue
        cost = max(0, int(sticker.get("ticket_cost") or 0))
        if max_ticket_cost is not None and cost > int(max_ticket_cost):
            continue
        if not without_paying and cost > tickets:
            continue
        sticker_kind = str(sticker.get("kind") or "")
        if sticker_kind == "name":
            score = _name_score(sticker, metric)
        else:
            score = (int(sticker.get("score") or 1), -cost, str(sticker.get("text") or ""))
        affordable.append((score, sticker))
    if not affordable:
        return None
    affordable.sort(key=lambda row: row[0], reverse=True)
    return copy.deepcopy(affordable[0][1])


def stickers_on(card: Any, kind: str | None = None) -> list[dict[str, Any]]:
    if not isinstance(card, dict):
        return []
    values = [value for value in card.get("stickers") or [] if isinstance(value, dict)]
    requested = str(kind or "").strip().lower()
    if requested:
        values = [value for value in values if value.get("kind") == requested]
    return values


def is_stickered(card: Any) -> bool:
    return bool(stickers_on(card))


def _apply_sticker_characteristics(card: dict[str, Any], sticker: dict[str, Any]) -> None:
    kind = sticker.get("kind")
    if kind == "name":
        names = [str(value.get("text") or "") for value in stickers_on(card, "name")]
        card["stickered_name"] = " ".join([str(card.get("name") or ""), *names]).strip()
    elif kind == "ability":
        original = card.setdefault("_sticker_original_keyword_values", {})
        for keyword in sticker.get("keywords") or []:
            normalized = str(keyword).strip().lower().replace(" ", "_")
            original.setdefault(normalized, card.get(normalized))
            card[normalized] = True
    elif kind == "power_toughness":
        if "_sticker_original_power" not in card:
            card["_sticker_original_power"] = card.get("power")
            card["_sticker_original_toughness"] = card.get("toughness")
        card["power"] = int(sticker.get("power") or 0)
        card["toughness"] = int(sticker.get("toughness") or 0)
        card["sticker_base_power"] = card["power"]
        card["sticker_base_toughness"] = card["toughness"]


def place_sticker(
    player: Any,
    target: dict[str, Any],
    *,
    kind: str = "any",
    metric: str | None = None,
    max_ticket_cost: int | None = None,
    without_paying: bool = False,
) -> dict[str, Any] | None:
    if not isinstance(target, dict):
        return None
    sticker = choose_sticker(
        player,
        kind=kind,
        metric=metric,
        max_ticket_cost=max_ticket_cost,
        without_paying=without_paying,
    )
    if sticker is None:
        return None
    cost = max(0, int(sticker.get("ticket_cost") or 0))
    if not without_paying:
        player.tickets = max(0, int(getattr(player, "tickets", 0) or 0) - cost)
    player.used_sticker_ids.add(sticker["sticker_id"])
    target.setdefault("stickers", []).append(copy.deepcopy(sticker))
    target["stickered"] = True
    _apply_sticker_characteristics(target, sticker)
    return sticker


def clear_stickers_for_hidden_zone(card: Any) -> int:
    if not isinstance(card, dict):
        return 0
    count = len(stickers_on(card))
    if not count:
        return 0
    for keyword, original in (card.pop("_sticker_original_keyword_values", {}) or {}).items():
        if original is None:
            card.pop(keyword, None)
        else:
            card[keyword] = original
    if "_sticker_original_power" in card:
        original_power = card.pop("_sticker_original_power")
        original_toughness = card.pop("_sticker_original_toughness", None)
        if original_power is None:
            card.pop("power", None)
        else:
            card["power"] = original_power
        if original_toughness is None:
            card.pop("toughness", None)
        else:
            card["toughness"] = original_toughness
    for key in (
        "stickers",
        "stickered",
        "stickered_name",
        "sticker_base_power",
        "sticker_base_toughness",
    ):
        card.pop(key, None)
    return count


def name_sticker_metric(card: Any, metric: str) -> int:
    values = [str(sticker.get("text") or "") for sticker in stickers_on(card, "name")]
    if metric == "unique_vowels":
        return max((unique_vowel_count(value) for value in values), default=0)
    if str(metric).startswith("letter_"):
        letter = str(metric).removeprefix("letter_")
        return sum(letter_count(value, letter) for value in values)
    if metric == "length_at_least_8":
        return sum(len(value.replace(" ", "")) >= 8 for value in values)
    if metric == "length_at_most_7":
        return sum(len(value.replace(" ", "")) <= 7 for value in values)
    if metric == "count":
        return len(values)
    return 0


def power_toughness_sticker_totals(cards: Iterable[Any]) -> tuple[int, int]:
    power = 0
    toughness = 0
    for card in cards:
        for sticker in stickers_on(card, "power_toughness"):
            power += int(sticker.get("power") or 0)
            toughness += int(sticker.get("toughness") or 0)
    return power, toughness


def has_sticker_kind(card: Any, kind: str) -> bool:
    return bool(stickers_on(card, kind))


def strip_sticker_text(value: str) -> str:
    return re.sub(r"\s+", " ", str(value or "")).strip()
