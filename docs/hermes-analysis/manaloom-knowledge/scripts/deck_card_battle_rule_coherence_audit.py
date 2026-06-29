#!/usr/bin/env python3
"""Audit deck card battle-rule coherence before battle/deck generation.

The audit is intentionally conservative: it does not promote rules or mutate
PostgreSQL/SQLite. It inventories cards that appear in `deck_cards`, compares
their oracle/cache data with `battle_card_rules`, and writes a prioritized queue
for card-by-card review.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sqlite3
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_REPORT_DIR = SCRIPT_DIR.parent.parent / "master_optimizer_reports"

TRUSTED_REVIEW_STATUSES = {"verified", "active"}
EXECUTABLE_STATUSES = {"auto", "executable"}
NON_EXECUTABLE_STATUSES = {"review_only", "disabled"}

BASIC_LAND_NAMES = {"plains", "island", "swamp", "mountain", "forest", "wastes"}

HIGH_RISK_GENERIC_EFFECTS = {
    "approach",
    "board_wipe",
    "cannot_lose_turn",
    "copy_spell",
    "counter",
    "damage_wipe",
    "damage_wipe_treasure",
    "draw_cards",
    "draw_engine",
    "extra_turn",
    "exile_artifact_enchantment_creature_convoke_wipe",
    "fated_clash_protect_then_destroy",
    "finisher",
    "gift_hexproof_indestructible",
    "graveyard_flashback_grant",
    "indestructible",
    "phase_out",
    "protect_creature",
    "recursion",
    "redirect_removal",
    "remove_artifact_or_3dmg",
    "remove_creature",
    "remove_permanent",
    "silence_opponents",
    "silence_spell",
    "steal_all_creatures",
    "token_maker",
    "topdeck_manipulation",
    "tutor",
    "wheel",
    "worldfire_reset",
}

GENERIC_EFFECTS_THAT_REQUIRE_SCOPE = HIGH_RISK_GENERIC_EFFECTS | {
    "equipment_static_attachment",
    "land_recursion",
    "land_ramp",
    "loot",
    "overload_recursion",
    "ramp_engine",
    "ramp_permanent",
    "ramp_ritual",
    "redistribute_life_totals",
    "treasure_maker",
}

IGNORED_DISABLED_REVIEW_STATUSES = {"deprecated", "rejected"}
LAND_ONLY_EFFECTS = {"land", "unknown"}

SEVERITY_ORDER = {
    "critical": 0,
    "high": 1,
    "medium": 2,
    "low": 3,
    "pass": 4,
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def normalize_name(name: str) -> str:
    return re.sub(r"\s+", " ", str(name or "").strip().lower())


def safe_json_loads(raw: str | None, default: Any) -> Any:
    if raw is None or raw == "":
        return default
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return default


def table_exists(conn: sqlite3.Connection, table: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        (table,),
    ).fetchone()
    return bool(row)


@dataclass
class DeckCardUsage:
    normalized_name: str
    display_name: str
    deck_ids: list[int]
    total_quantity: int
    deck_count: int
    commander_count: int
    type_lines: list[str]
    oracle_texts: list[str]
    battle_rules_json_count: int


def load_deck_card_usage(
    conn: sqlite3.Connection,
    deck_id: int | None = None,
) -> dict[str, DeckCardUsage]:
    where_clause = ""
    params: tuple[Any, ...] = ()
    if deck_id is not None:
        where_clause = "WHERE deck_id = ?"
        params = (deck_id,)
    rows = conn.execute(
        f"""
        SELECT
            lower(trim(card_name)) AS normalized_name,
            MIN(card_name) AS display_name,
            GROUP_CONCAT(DISTINCT deck_id) AS deck_ids_csv,
            SUM(COALESCE(quantity, 1)) AS total_quantity,
            COUNT(DISTINCT deck_id) AS deck_count,
            SUM(CASE WHEN COALESCE(is_commander, 0) = 1 THEN 1 ELSE 0 END) AS commander_count,
            GROUP_CONCAT(DISTINCT COALESCE(type_line, '')) AS type_lines_csv,
            GROUP_CONCAT(DISTINCT COALESCE(oracle_text, '')) AS oracle_texts_csv,
            SUM(
                CASE
                    WHEN COALESCE(battle_rules_json, '[]') NOT IN ('', '[]') THEN 1
                    ELSE 0
                END
            ) AS battle_rules_json_count
        FROM deck_cards
        {where_clause}
        GROUP BY lower(trim(card_name))
        ORDER BY lower(trim(card_name))
        """,
        params,
    ).fetchall()
    usage: dict[str, DeckCardUsage] = {}
    for row in rows:
        deck_ids = [
            int(value)
            for value in str(row["deck_ids_csv"] or "").split(",")
            if value.strip().isdigit()
        ]
        type_lines = [
            value
            for value in str(row["type_lines_csv"] or "").split(",")
            if value.strip()
        ]
        oracle_texts = [
            value
            for value in str(row["oracle_texts_csv"] or "").split(",")
            if value.strip()
        ]
        normalized = normalize_name(row["normalized_name"])
        usage[normalized] = DeckCardUsage(
            normalized_name=normalized,
            display_name=str(row["display_name"] or ""),
            deck_ids=sorted(set(deck_ids)),
            total_quantity=int(row["total_quantity"] or 0),
            deck_count=int(row["deck_count"] or 0),
            commander_count=int(row["commander_count"] or 0),
            type_lines=sorted(set(type_lines)),
            oracle_texts=sorted(set(oracle_texts)),
            battle_rules_json_count=int(row["battle_rules_json_count"] or 0),
        )
    return usage


def load_oracle_cache(conn: sqlite3.Connection) -> dict[str, dict[str, Any]]:
    if not table_exists(conn, "card_oracle_cache"):
        return {}
    rows = conn.execute(
        """
        SELECT normalized_name, name, type_line, oracle_text, cmc, mana_cost,
               color_identity_json, keywords_json, scryfall_id
        FROM card_oracle_cache
        """
    ).fetchall()
    cache: dict[str, dict[str, Any]] = {}
    for row in rows:
        payload = dict(row)
        normalized = normalize_name(row["normalized_name"])
        cache[normalized] = payload
        front_face = normalize_name(str(row["name"] or "").split(" // ", 1)[0])
        cache.setdefault(front_face, payload)
    return cache


def load_battle_rules(conn: sqlite3.Connection) -> dict[str, list[dict[str, Any]]]:
    if not table_exists(conn, "battle_card_rules"):
        return {}
    rows = conn.execute(
        """
        SELECT normalized_name, logical_rule_key, card_name, effect_json,
               deck_role_json, source, confidence, review_status,
               execution_status, oracle_hash, notes
        FROM battle_card_rules
        ORDER BY normalized_name, logical_rule_key
        """
    ).fetchall()
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        payload = dict(row)
        payload["effect_json"] = safe_json_loads(row["effect_json"], {})
        payload["deck_role_json"] = safe_json_loads(row["deck_role_json"], {})
        normalized = normalize_name(row["normalized_name"])
        grouped[normalized].append(payload)
        front_face = normalize_name(str(row["card_name"] or "").split(" // ", 1)[0])
        if front_face != normalized:
            grouped[front_face].append(payload)
    return grouped


def is_land_like(usage: DeckCardUsage, oracle: dict[str, Any] | None) -> bool:
    type_lines = list(usage.type_lines)
    if oracle and oracle.get("type_line"):
        type_lines.append(str(oracle["type_line"]))
    if usage.normalized_name in BASIC_LAND_NAMES:
        return True
    return any("land" in line.lower() for line in type_lines)


def has_oracle_text(usage: DeckCardUsage, oracle: dict[str, Any] | None) -> bool:
    if oracle and str(oracle.get("oracle_text") or "").strip():
        return True
    return any(text.strip() for text in usage.oracle_texts)


def oracle_hash_md5(oracle_text: str | None) -> str | None:
    text = str(oracle_text or "").strip()
    if not text:
        return None
    return hashlib.md5(text.encode("utf-8")).hexdigest()


def active_rules(rules: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [
        rule
        for rule in rules
        if str(rule.get("review_status") or "") not in IGNORED_DISABLED_REVIEW_STATUSES
        and str(rule.get("execution_status") or "") not in {"disabled"}
    ]


def trusted_executable_rules(rules: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [
        rule
        for rule in rules
        if str(rule.get("review_status") or "") in TRUSTED_REVIEW_STATUSES
        and str(rule.get("execution_status") or "") in EXECUTABLE_STATUSES
    ]


def rule_effect(rule: dict[str, Any]) -> str:
    return str((rule.get("effect_json") or {}).get("effect") or "")


def rule_effects(rules: list[dict[str, Any]]) -> set[str]:
    return {rule_effect(rule) or "unknown" for rule in rules}


def is_land_only_rule_backlog(land_like: bool, rules: list[dict[str, Any]]) -> bool:
    if not land_like or not rules:
        return False
    return rule_effects(rules).issubset(LAND_ONLY_EFFECTS)


def rule_has_model_scope(rule: dict[str, Any]) -> bool:
    effect_json = rule.get("effect_json") or {}
    return bool(
        effect_json.get("battle_model_scope")
        or effect_json.get("ability_kind")
        or effect_json.get("runtime_executor")
        or effect_json.get("oracle_specific_model")
        or effect_json.get("modeled_oracle_clause")
    )


def impact_tier(land_like: bool, effects: set[str]) -> str:
    if effects & HIGH_RISK_GENERIC_EFFECTS:
        return "battle_critical"
    if effects & GENERIC_EFFECTS_THAT_REQUIRE_SCOPE:
        return "battle_support"
    if land_like:
        return "land_or_mana_base"
    if "unknown" in effects:
        return "unknown_effect"
    return "support_or_passive"


IMPACT_TIER_ORDER = {
    "battle_critical": 0,
    "battle_support": 1,
    "support_or_passive": 2,
    "unknown_effect": 3,
    "land_or_mana_base": 4,
}


def classify_card(
    usage: DeckCardUsage,
    oracle: dict[str, Any] | None,
    rules: list[dict[str, Any]],
) -> dict[str, Any]:
    active = active_rules(rules)
    trusted = trusted_executable_rules(rules)
    land_like = is_land_like(usage, oracle)
    land_only_backlog = is_land_only_rule_backlog(land_like, active)
    oracle_present = has_oracle_text(usage, oracle)
    findings: list[dict[str, str]] = []

    if not oracle and not usage.oracle_texts and not usage.type_lines:
        findings.append(
            {
                "severity": "critical",
                "code": "missing_oracle_identity",
                "detail": "No card_oracle_cache row and no deck_cards oracle/type data.",
            }
        )
    elif not oracle_present and not land_like:
        findings.append(
            {
                "severity": "high",
                "code": "missing_oracle_text",
                "detail": "Non-land deck card lacks oracle text for rule review.",
            }
        )

    if not active:
        severity = "medium" if land_like else "high"
        findings.append(
            {
                "severity": severity,
                "code": "no_active_battle_rule",
                "detail": "No active battle_card_rules row for a deck card.",
            }
        )

    if active and not trusted:
        severity = "medium" if land_only_backlog else "high"
        findings.append(
            {
                "severity": severity,
                "code": "no_trusted_executable_rule",
                "detail": "Rules exist, but none are verified/active and executable.",
            }
        )

    review_only = [
        rule
        for rule in active
        if str(rule.get("review_status") or "") == "needs_review"
        or str(rule.get("execution_status") or "") in NON_EXECUTABLE_STATUSES
    ]
    if review_only:
        severity = "pass" if trusted else ("medium" if land_only_backlog else "high")
        code = (
            "shadow_rule_preserved_for_history"
            if trusted
            else "review_only_or_needs_review_rule"
        )
        detail = (
            f"{len(review_only)} review-only/shadow rows are preserved but ignored because trusted executable rule exists."
            if trusted
            else f"{len(review_only)} active rows are needs_review/review_only/disabled."
        )
        findings.append(
            {
                "severity": severity,
                "code": code,
                "detail": detail,
            }
        )

    generic_trusted = [
        rule
        for rule in trusted
        if rule_effect(rule) in GENERIC_EFFECTS_THAT_REQUIRE_SCOPE
        and not rule_has_model_scope(rule)
    ]
    if generic_trusted:
        severity = (
            "high"
            if any(rule_effect(rule) in HIGH_RISK_GENERIC_EFFECTS for rule in generic_trusted)
            else "medium"
        )
        findings.append(
            {
                "severity": severity,
                "code": "generic_effect_without_model_scope",
                "detail": "Trusted rule uses broad effect without battle_model_scope/oracle-specific marker: "
                + ", ".join(sorted({rule_effect(rule) for rule in generic_trusted})),
            }
        )

    missing_oracle_hash = [
        rule
        for rule in trusted
        if not str(rule.get("oracle_hash") or "").strip()
    ]
    if missing_oracle_hash and not land_like:
        findings.append(
            {
                "severity": "medium",
                "code": "trusted_rule_without_oracle_hash",
                "detail": f"{len(missing_oracle_hash)} trusted executable rows lack oracle_hash.",
            }
        )

    generated_trusted = [
        rule
        for rule in trusted
        if str(rule.get("source") or "") == "generated"
    ]
    if generated_trusted:
        findings.append(
            {
                "severity": "medium",
                "code": "generated_rule_trusted_for_deck_card",
                "detail": "Generated executable row is trusted for a deck card; requires manual confirmation.",
            }
        )

    if not findings:
        findings.append(
            {
                "severity": "pass",
                "code": "coherent_for_current_gate",
                "detail": "Oracle/cache and trusted executable battle rule are present.",
            }
        )

    worst = min(
        (finding["severity"] for finding in findings),
        key=lambda severity: SEVERITY_ORDER[severity],
    )
    effects_set = rule_effects(active)
    effects = sorted(effects_set)
    impact = impact_tier(land_like, effects_set)
    return {
        "card_name": usage.display_name,
        "normalized_name": usage.normalized_name,
        "severity": worst,
        "impact_tier": impact,
        "impact_rank": IMPACT_TIER_ORDER[impact],
        "priority_score": priority_score(worst, usage),
        "deck_count": usage.deck_count,
        "deck_ids": usage.deck_ids[:25],
        "deck_ids_truncated": len(usage.deck_ids) > 25,
        "total_quantity": usage.total_quantity,
        "commander_count": usage.commander_count,
        "land_like": land_like,
        "oracle_cache_present": bool(oracle),
        "oracle_text_present": oracle_present,
        "oracle_hash": oracle_hash_md5((oracle or {}).get("oracle_text")),
        "type_line": str((oracle or {}).get("type_line") or (usage.type_lines[0] if usage.type_lines else "")),
        "active_rule_count": len(active),
        "trusted_executable_rule_count": len(trusted),
        "review_only_rule_count": len(review_only),
        "effects": effects,
        "logical_rule_keys": [str(rule.get("logical_rule_key") or "") for rule in active],
        "findings": sorted(findings, key=lambda item: SEVERITY_ORDER[item["severity"]]),
    }


def priority_score(severity: str, usage: DeckCardUsage) -> int:
    base = {
        "critical": 10000,
        "high": 7000,
        "medium": 4000,
        "low": 1000,
        "pass": 0,
    }[severity]
    return base + min(usage.deck_count * 50, 2000) + min(usage.total_quantity, 500)


def build_report(conn: sqlite3.Connection, deck_id: int | None = None) -> dict[str, Any]:
    conn.row_factory = sqlite3.Row
    usage = load_deck_card_usage(conn, deck_id=deck_id)
    oracle_cache = load_oracle_cache(conn)
    rules = load_battle_rules(conn)
    cards = [
        classify_card(card, oracle_cache.get(normalized), rules.get(normalized, []))
        for normalized, card in usage.items()
    ]
    cards.sort(
        key=lambda card: (
            SEVERITY_ORDER[card["severity"]],
            int(card["impact_rank"]),
            -int(card["priority_score"]),
            str(card["card_name"]).lower(),
        )
    )
    severity_counts = Counter(card["severity"] for card in cards)
    finding_counts = Counter(
        finding["code"]
        for card in cards
        for finding in card["findings"]
        if finding["code"] != "coherent_for_current_gate"
    )
    return {
        "generated_at": utc_now(),
        "source": "sqlite_hermes_knowledge_db",
        "scope": "distinct_cards_referenced_by_deck_cards"
        if deck_id is None
        else "distinct_cards_referenced_by_deck_cards_filtered_by_deck_id",
        "deck_id": deck_id,
        "total_cards": len(cards),
        "severity_counts": dict(sorted(severity_counts.items())),
        "finding_counts": dict(finding_counts.most_common()),
        "cards": cards,
    }


def markdown_report(report: dict[str, Any], limit: int) -> str:
    lines = [
        "# Deck Card Battle Rule Coherence Audit",
        "",
        f"Generated at: `{report['generated_at']}`",
        "",
        "Scope: distinct cards referenced by Hermes `deck_cards`."
        if report.get("deck_id") is None
        else f"Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id={report['deck_id']}`.",
        "",
        "This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.",
        "",
        "## Summary",
        "",
        f"- Total deck cards: `{report['total_cards']}`",
    ]
    for severity in ["critical", "high", "medium", "low", "pass"]:
        lines.append(
            f"- {severity}: `{report.get('severity_counts', {}).get(severity, 0)}`"
        )
    lines.extend(["", "## Finding Counts", ""])
    if report.get("finding_counts"):
        for code, count in report["finding_counts"].items():
            lines.append(f"- `{code}`: `{count}`")
    else:
        lines.append("- none")

    actionable = [
        card for card in report["cards"] if card["severity"] != "pass"
    ][:limit]
    lines.extend(
        [
            "",
            f"## Top {len(actionable)} Actionable Cards",
            "",
            "| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |",
            "| --- | --- | ---: | --- | ---: | ---: | --- | --- |",
        ]
    )
    for card in actionable:
        findings = ", ".join(f"`{item['code']}`" for item in card["findings"] if item["severity"] != "pass")
        effects = ", ".join(f"`{effect}`" for effect in card["effects"]) or "-"
        lines.append(
            f"| `{card['severity']}` | `{card['impact_tier']}` | {card['priority_score']} | `{card['card_name']}` | "
            f"{card['deck_count']} | {card['total_quantity']} | {findings} | {effects} |"
        )

    lines.extend(
        [
            "",
            "## Required Card-By-Card Gate",
            "",
            "A card can move out of the queue only when all applicable evidence exists:",
            "",
            "- oracle/type identity is present or an explicit no-text exception is documented;",
            "- broad generated/heuristic behavior is replaced by a reviewed battle model;",
            "- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;",
            "- complex effects include `battle_model_scope` or equivalent oracle-specific marker;",
            "- focused unit tests prove the modeled behavior and relevant negative cases;",
            "- replay/events prove the selected `logical_rule_key` in a real or focused battle;",
            "- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.",
        ]
    )
    return "\n".join(lines) + "\n"


def write_report(report: dict[str, Any], output_json: Path, output_md: Path, limit: int) -> None:
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    output_md.write_text(markdown_report(report, limit), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sqlite-db", default=str(DEFAULT_DB))
    parser.add_argument("--output-json")
    parser.add_argument("--output-md")
    parser.add_argument("--limit", type=int, default=80)
    parser.add_argument(
        "--deck-id",
        type=int,
        help="Filter the audit to distinct cards referenced by one Hermes deck_cards.deck_id.",
    )
    parser.add_argument(
        "--fail-on",
        choices=["none", "critical", "high", "medium"],
        default="none",
        help="Exit non-zero when report contains findings at or above this severity.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    sqlite_db = Path(args.sqlite_db)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    report_stem = "deck_card_battle_rule_coherence_audit"
    if args.deck_id is not None:
        report_stem += f"_deck{args.deck_id}"
    output_json = Path(args.output_json or DEFAULT_REPORT_DIR / f"{report_stem}_{timestamp}.json")
    output_md = Path(args.output_md or DEFAULT_REPORT_DIR / f"{report_stem}_{timestamp}.md")
    with sqlite3.connect(sqlite_db) as conn:
        conn.row_factory = sqlite3.Row
        report = build_report(conn, deck_id=args.deck_id)
    write_report(report, output_json, output_md, args.limit)
    print(f"json_report={output_json}")
    print(f"md_report={output_md}")
    if args.deck_id is not None:
        print(f"deck_id={args.deck_id}")
    print(f"total_cards={report['total_cards']}")
    print(f"severity_counts={json.dumps(report['severity_counts'], sort_keys=True)}")
    if args.fail_on != "none":
        threshold = SEVERITY_ORDER[args.fail_on]
        blocked = sum(
            count
            for severity, count in report["severity_counts"].items()
            if SEVERITY_ORDER[severity] <= threshold
        )
        if blocked:
            print(f"blocked_findings={blocked}")
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
