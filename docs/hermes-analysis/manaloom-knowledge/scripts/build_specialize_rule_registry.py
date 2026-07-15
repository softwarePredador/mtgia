#!/usr/bin/env python3
"""Build the HBG Specialize registry and reviewed derived-face rules."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sqlite3
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_REGISTRY = SCRIPT_DIR / "specialize_card_registry.json"
DEFAULT_RULES = SCRIPT_DIR / "reviewed_battle_card_rules.json"
COLOR_ORDER = ("W", "U", "B", "R", "G")
FAMILIES = {
    "alora": ("Alora, Rogue Companion", r"Alora, Cheerful .+"),
    "ambergris": ("Ambergris, Citadel Agent", r"Ambergris, Agent of .+"),
    "gale": ("Gale, Conduit of the Arcane", r"Gale, .+ Conduit"),
    "gut": ("Gut, Fanatical Priestess", r"Gut, .+ Fanatic"),
    "imoen": ("Imoen, Trickster Friend", r"Imoen, .+ Trickster"),
    "jaheira": ("Jaheira, Harper Emissary", r"Jaheira, .+ Harper"),
    "karlach": ("Karlach, Raging Tiefling", r"Karlach, Tiefling .+"),
    "klement": ("Klement, Novice Acolyte", r"Klement, .+ Acolyte"),
    "laezel": (
        "Lae'zel, Githyanki Warrior",
        r"Lae'zel, (?:.+ Warrior|Illithid Thrall)",
    ),
    "lukamina": ("Lukamina, Moon Druid", r"Lukamina, .+ Form"),
    "lulu": ("Lulu, Forgetful Hollyphant", r"Lulu, .+ Hollyphant"),
    "rasaad": ("Rasaad, Monk of Selûne", r"Rasaad, .+ Monk"),
    "sarevok": ("Sarevok the Usurper", r"Sarevok, .+ Usurper"),
    "shadowheart": ("Shadowheart, Sharran Cleric", r"Shadowheart, Cleric of .+"),
    "skanos": ("Skanos, Dragon Vassal", r"Skanos, .+ Dragon Vassal"),
    "vhal": ("Vhal, Eager Scholar", r"Vhal, Scholar of .+"),
    "viconia": ("Viconia, Nightsinger's Disciple", r"Viconia, Disciple of .+"),
    "wilson": ("Wilson, Bear Comrade", r"Wilson, .+ Bear"),
    "wyll": ("Wyll, Pact-Bound Duelist", r"Wyll of the .+ Pact"),
}
KEYWORD_FIELDS = {
    "deathtouch": "deathtouch",
    "double strike": "double_strike",
    "first strike": "first_strike",
    "flying": "flying",
    "haste": "haste",
    "lifelink": "lifelink",
    "menace": "menace",
    "reach": "reach",
    "trample": "trample",
    "vigilance": "vigilance",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sqlite-db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--registry", type=Path, default=DEFAULT_REGISTRY)
    parser.add_argument("--reviewed-rules", type=Path, default=DEFAULT_RULES)
    parser.add_argument("--check", action="store_true")
    return parser.parse_args()


def normalize_name(value: str) -> str:
    return " ".join(str(value or "").strip().lower().split())


def specialize_logical_rule_key(card_name: str) -> str:
    identity = f"specialize_card_runtime_v1:{normalize_name(card_name)}"
    return f"battle_rule_v1:{hashlib.md5(identity.encode('utf-8')).hexdigest()}"


def json_list(value: str | None) -> list[str]:
    try:
        decoded = json.loads(value or "[]")
    except json.JSONDecodeError:
        return []
    return [str(item) for item in decoded] if isinstance(decoded, list) else []


def load_cards(db_path: Path) -> dict[str, dict]:
    connection = sqlite3.connect(db_path)
    connection.row_factory = sqlite3.Row
    try:
        rows = connection.execute(
            """
            SELECT normalized_name, name, mana_cost, colors_json,
                   color_identity_json, type_line, oracle_text, cmc, power,
                   toughness, keywords_json, scryfall_id, card_id
            FROM card_oracle_cache
            """
        ).fetchall()
    finally:
        connection.close()
    cards = {}
    for row in rows:
        card = dict(row)
        card["colors"] = json_list(card.pop("colors_json"))
        card["color_identity"] = json_list(card.pop("color_identity_json"))
        card["keywords"] = json_list(card.pop("keywords_json"))
        cards[normalize_name(card["name"])] = card
    return cards


def activation_cost(oracle_text: str) -> str:
    match = re.search(r"Specialize\s+((?:\{[^}]+\})+)", oracle_text or "", re.IGNORECASE)
    if not match:
        raise ValueError(f"specialize activation cost not found in {oracle_text!r}")
    return match.group(1)


def chosen_color(base: dict, face: dict) -> str:
    base_colors = {str(color).upper() for color in base.get("colors") or []}
    face_colors = {str(color).upper() for color in face.get("colors") or []}
    additions = face_colors - base_colors
    if len(additions) == 1:
        return additions.pop()
    if len(base_colors) == 1 and face_colors == base_colors:
        return next(iter(base_colors))
    raise ValueError(
        f"cannot derive specialize color for {base['name']} -> {face['name']}: "
        f"base={sorted(base_colors)} face={sorted(face_colors)}"
    )


def runtime_conditions(family: str) -> dict:
    if family == "imoen":
        return {
            "specialize_cost_reduction_generic": 3,
            "specialize_cost_reduction_graveyard_instant_sorcery_min": 2,
        }
    if family == "karlach":
        return {"specialize_allowed_zones": ["battlefield", "graveyard"]}
    if family == "lukamina":
        return {"specialize_min_controlled_lands": 6}
    if family == "shadowheart":
        return {"specialize_any_player_life_at_most": 13}
    return {"specialize_allowed_zones": ["battlefield"]}


def keyword_fields(card: dict) -> dict:
    fields = {}
    oracle_lower = str(card.get("oracle_text") or "").lower()
    keyword_values = {str(value).lower().replace("_", " ") for value in card.get("keywords") or []}
    for keyword, field in KEYWORD_FIELDS.items():
        if keyword in keyword_values or re.search(rf"(?:^|[,\n])\s*{re.escape(keyword)}(?:\s*[,\n]|$)", oracle_lower):
            fields[field] = True
    ward_match = re.search(r"Ward\s+(\{[^\n]+\})", str(card.get("oracle_text") or ""), re.IGNORECASE)
    if ward_match:
        fields["ward_mana_cost"] = ward_match.group(1)
    card_name = re.escape(str(card.get("name") or "").lower())
    blocked_match = re.search(
        rf"^(?:{card_name}|this creature) can't be blocked(?P<restriction>[^.]*)(?:\.|$)",
        oracle_lower,
        re.MULTILINE,
    )
    if blocked_match:
        restriction = blocked_match.group("restriction") or ""
        power_match = re.search(r"by creatures with power (\d+) or less", restriction)
        if power_match:
            fields["cant_be_blocked_by_filters"] = [
                {
                    "kind": "power",
                    "operator": "lte",
                    "value": int(power_match.group(1)),
                }
            ]
        elif not restriction.strip():
            fields["unblockable"] = True
    if "must be blocked if able" in oracle_lower:
        fields["must_be_blocked_if_able"] = True
    if "hexproof from artifacts and enchantments" in oracle_lower:
        fields["hexproof_from_source_card_types"] = ["artifact", "enchantment"]
    return fields


def card_metadata(card: dict) -> dict:
    payload = {
        "mana_cost": card.get("mana_cost") or "",
        "cmc": float(card.get("cmc") or 0),
        "colors": list(card.get("colors") or []),
        "type_line": card.get("type_line") or "",
        "oracle_text": card.get("oracle_text") or "",
        "power": card.get("power"),
        "toughness": card.get("toughness"),
        "keywords": list(card.get("keywords") or []),
    }
    payload.update(keyword_fields(card))
    return payload


def base_runtime_fields(family: str) -> dict:
    if family == "vhal":
        return {
            "activated_draw_discard": True,
            "activated_draw_count": 1,
            "activated_discard_count": 1,
            "activation_requires_tap": True,
        }
    if family == "viconia":
        return {
            "activated_effect": "graveyard_exile",
            "graveyard_exile_target": "any_card",
            "graveyard_exile_target_count": 1,
            "graveyard_exile_destination": "exile",
            "graveyard_exile_activation_cost_generic": 1,
            "graveyard_exile_activation_cost_mana": "{1}",
        }
    if family == "laezel":
        return {"opponent_target_blink_until_leaves_battlefield": True}
    return {}


def build(cards: dict[str, dict]) -> tuple[dict, dict[str, dict]]:
    registry_families = {}
    specialize_rules = {}
    all_rows = list(cards.values())
    for family, (base_name, face_pattern) in FAMILIES.items():
        base = cards.get(normalize_name(base_name))
        if base is None:
            raise ValueError(f"missing base card metadata: {base_name}")
        base_oracle_text = str(base.get("oracle_text") or "")
        base_effect = {
            "ability_kind": "permanent",
            "effect": "creature",
            **card_metadata(base),
            **base_runtime_fields(family),
            "specialize_base_card": True,
            "specialize_family": family,
            "specialize_family_effect_status": "runtime_executor_v1",
            "battle_model_scope": "specialize_base_family_runtime_v1",
        }
        specialize_rules[base_name] = {
            "logical_rule_key": specialize_logical_rule_key(base_name),
            "effect_json": base_effect,
            "deck_role_json": {
                "category": "engine",
                "effect": "creature",
                "subtype": f"specialize_{family}_base",
            },
            "source": "curated",
            "confidence": 0.99,
            "review_status": "verified",
            "execution_status": "auto",
            "notes": (
                f"Oracle-reviewed HBG Specialize base card; shared runtime executes "
                f"family={family} before and after perpetual transformation."
            ),
            "oracle_hash": hashlib.md5(base_oracle_text.encode("utf-8")).hexdigest(),
        }
        faces = [
            card
            for card in all_rows
            if card.get("name") != base_name
            and re.fullmatch(face_pattern, str(card.get("name") or ""))
        ]
        face_by_color = {}
        for face in faces:
            color = chosen_color(base, face)
            if color in face_by_color:
                raise ValueError(f"duplicate {family} face for color {color}")
            face_by_color[color] = face["name"]
            effect = {
                "ability_kind": "permanent",
                "effect": "creature",
                **card_metadata(face),
                "specialize_derived_face": True,
                "specialize_family": family,
                "specialize_color": color,
                "specialize_base_name": base_name,
                "specialize_family_effect_status": "runtime_executor_v1",
                "battle_model_scope": "specialize_derived_face_family_runtime_v1",
            }
            oracle_text = str(face.get("oracle_text") or "")
            if "enters or specializes" in oracle_text.lower():
                effect["specialize_transition_on_enter"] = True
            specialize_rules[face["name"]] = {
                "logical_rule_key": specialize_logical_rule_key(face["name"]),
                "effect_json": effect,
                "deck_role_json": {
                    "category": "engine",
                    "effect": "creature",
                    "subtype": f"specialize_{family}_{color.lower()}_face",
                },
                "source": "curated",
                "confidence": 0.99,
                "review_status": "verified",
                "execution_status": "auto",
                "notes": (
                    f"Oracle-reviewed HBG Specialize derived face for {base_name}; "
                    f"the shared runtime executes family={family}, color={color}."
                ),
                "oracle_hash": hashlib.md5(oracle_text.encode("utf-8")).hexdigest(),
            }
        if set(face_by_color) != set(COLOR_ORDER):
            raise ValueError(
                f"{family} expected WUBRG faces, got {sorted(face_by_color)}: "
                f"{sorted(card['name'] for card in faces)}"
            )
        registry_families[family] = {
            "base_name": base_name,
            "base_color": (base.get("colors") or [None])[0],
            "activation_cost": activation_cost(str(base.get("oracle_text") or "")),
            "face_by_color": {color: face_by_color[color] for color in COLOR_ORDER},
            "face_metadata_by_color": {
                color: specialize_rules[face_by_color[color]]["effect_json"]
                for color in COLOR_ORDER
            },
            "base_oracle_hash": hashlib.md5(
                str(base.get("oracle_text") or "").encode("utf-8")
            ).hexdigest(),
            **runtime_conditions(family),
        }
    registry = {
        "schema_version": 1,
        "source": "PostgreSQL cards mirrored through Hermes card_oracle_cache",
        "mechanic_contract": (
            "Pay the Specialize activation cost and discard a card; one of that "
            "card's colors or basic land types selects the perpetual WUBRG face."
        ),
        "family_count": len(registry_families),
        "base_card_count": len(registry_families),
        "derived_face_count": len(specialize_rules) - len(registry_families),
        "rule_card_count": len(specialize_rules),
        "families": registry_families,
    }
    return registry, specialize_rules


def canonical_text(payload: dict) -> str:
    return json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n"


def main() -> int:
    args = parse_args()
    registry, specialize_rules = build(load_cards(args.sqlite_db))
    reviewed_rules = json.loads(args.reviewed_rules.read_text(encoding="utf-8"))
    stale_faces = [
        name
        for name, rule in reviewed_rules.items()
        if isinstance(rule, dict)
        and (
            (rule.get("effect_json") or {}).get("specialize_derived_face")
            or (rule.get("effect_json") or {}).get("specialize_base_card")
        )
        and name not in specialize_rules
    ]
    for name in stale_faces:
        reviewed_rules.pop(name, None)
    reviewed_rules.update(specialize_rules)

    registry_text = canonical_text(registry)
    rules_text = canonical_text(reviewed_rules)
    if args.check:
        current_registry = args.registry.read_text(encoding="utf-8") if args.registry.exists() else ""
        current_rules = args.reviewed_rules.read_text(encoding="utf-8")
        if current_registry != registry_text or current_rules != rules_text:
            raise SystemExit("Specialize registry or reviewed rules are out of date")
        print(
            f"PASS specialize registry families={registry['family_count']} "
            f"base_cards={registry['base_card_count']} "
            f"derived_faces={registry['derived_face_count']} "
            f"rules={registry['rule_card_count']}"
        )
        return 0

    args.registry.write_text(registry_text, encoding="utf-8")
    args.reviewed_rules.write_text(rules_text, encoding="utf-8")
    print(
        f"wrote {args.registry}: families={registry['family_count']} "
        f"base_cards={registry['base_card_count']} "
        f"derived_faces={registry['derived_face_count']} "
        f"rules={registry['rule_card_count']}"
    )
    print(f"updated {args.reviewed_rules}: total_rules={len(reviewed_rules)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
