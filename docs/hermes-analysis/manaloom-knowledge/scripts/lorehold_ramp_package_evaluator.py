#!/usr/bin/env python3
"""Evaluate Lorehold ramp package swaps independently from battle win rate."""

from __future__ import annotations

import argparse
import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from lorehold_synergy_package_gate import (
    DEFAULT_SOURCE_DB,
    PACKAGE_DEFINITIONS,
    REPORT_DIR,
)
from master_optimizer_common import normalize_name


LOREHOLD_COLOR_SYMBOLS = {"R", "W"}
RAMP_EFFECTS = {"ramp_permanent", "ramp_ritual", "ramp_engine", "land_ramp"}
REVIEW_RANK = {"verified": 0, "active": 1, "needs_review": 2}
EXECUTION_RANK = {"auto": 0, "manual": 1, "disabled": 2}


def parse_json(value: object, default: Any) -> Any:
    if value in (None, ""):
        return default
    try:
        return json.loads(str(value))
    except json.JSONDecodeError:
        return default


def connect(db_path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def load_oracle(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    row = conn.execute(
        "SELECT * FROM card_oracle_cache WHERE normalized_name=?",
        (normalize_name(card_name),),
    ).fetchone()
    if row is None:
        return {"name": card_name, "missing": True}
    return dict(row)


def load_best_rule(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    rows = conn.execute(
        """
        SELECT *
        FROM battle_card_rules
        WHERE normalized_name=?
        ORDER BY confidence DESC, logical_rule_key
        """,
        (normalize_name(card_name),),
    ).fetchall()
    if not rows:
        return {}

    def rank(row: sqlite3.Row) -> tuple[int, int, int, str]:
        return (
            EXECUTION_RANK.get(str(row["execution_status"]), 9),
            REVIEW_RANK.get(str(row["review_status"]), 9),
            0 if row["source"] == "curated" else 1,
            str(row["logical_rule_key"]),
        )

    best = sorted(rows, key=rank)[0]
    data = dict(best)
    data["effect_data"] = parse_json(best["effect_json"], {})
    data["role_data"] = parse_json(best["deck_role_json"], {})
    return data


def produced_symbols(effect_data: dict[str, Any]) -> set[str]:
    raw = str(effect_data.get("produces") or "").upper()
    if not raw:
        return set()
    return {symbol for symbol in raw if symbol in {"W", "U", "B", "R", "G", "C"}}


def numeric(value: object, default: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def tapped_draw_step_damage(effect_data: dict[str, Any]) -> float:
    """Read the exact draw-step field, with a transitional alias for older rules."""
    if "tapped_draw_step_damage" in effect_data:
        return numeric(effect_data.get("tapped_draw_step_damage"))
    return numeric(effect_data.get("tapped_upkeep_damage"))


def ramp_profile(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    oracle = load_oracle(conn, card_name)
    rule = load_best_rule(conn, card_name)
    effect_data = rule.get("effect_data") or {}
    role_data = rule.get("role_data") or {}
    effect = str(effect_data.get("effect") or role_data.get("effect") or "")
    cmc = numeric(oracle.get("cmc"), numeric(effect_data.get("cmc")))
    mana_produced = int(numeric(effect_data.get("mana_produced"), 0))
    symbols = produced_symbols(effect_data)
    lorehold_fixing = len((symbols - {"C"}) & LOREHOLD_COLOR_SYMBOLS)
    colorless_only = bool(symbols) and symbols <= {"C"}
    nonstandard_untap = bool(
        effect_data.get("does_not_untap_normally")
        or effect_data.get("does_not_untap_in_untap_step")
    )
    recurring_source = (
        effect == "ramp_permanent"
        and mana_produced > 0
        and not nonstandard_untap
        and not effect_data.get("activated_self_sacrifice_draw")
        and not effect_data.get("sacrifice_after_use")
    )
    same_turn_net_mana = None
    if effect in {"ramp_permanent", "ramp_ritual"} and mana_produced:
        same_turn_net_mana = mana_produced - cmc
    risk_flags: list[str] = []
    if colorless_only:
        risk_flags.append("colorless_only")
    if nonstandard_untap:
        risk_flags.append("nonstandard_untap")
    if numeric(effect_data.get("upkeep_optional_untap_cost_generic")) > 0:
        risk_flags.append("untap_tax")
    if tapped_draw_step_damage(effect_data) > 0:
        risk_flags.append("draw_step_damage")
    if effect not in RAMP_EFFECTS and role_data.get("category") != "ramp":
        risk_flags.append("not_primary_ramp_rule")
    return {
        "card_name": oracle.get("name") or card_name,
        "missing": bool(oracle.get("missing")),
        "cmc": cmc,
        "effect": effect or None,
        "battle_model_scope": effect_data.get("battle_model_scope"),
        "mana_produced": mana_produced,
        "produces": "".join(sorted(symbols)) or None,
        "lorehold_colored_fixing": lorehold_fixing,
        "colorless_only": colorless_only,
        "same_turn_net_mana": same_turn_net_mana,
        "fast_mana": bool(cmc <= 1 and mana_produced >= 2),
        "recurring_source": recurring_source,
        "nonstandard_untap": nonstandard_untap,
        "risk_flags": risk_flags,
        "rule_source": rule.get("source"),
        "rule_review_status": rule.get("review_status"),
        "rule_execution_status": rule.get("execution_status"),
    }


def side_summary(profiles: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "cards": [profile["card_name"] for profile in profiles],
        "mana_produced": sum(int(profile.get("mana_produced") or 0) for profile in profiles),
        "same_turn_net_mana": sum(
            numeric(profile.get("same_turn_net_mana"))
            for profile in profiles
            if profile.get("same_turn_net_mana") is not None
        ),
        "lorehold_colored_fixing": sum(
            int(profile.get("lorehold_colored_fixing") or 0) for profile in profiles
        ),
        "fast_mana_count": sum(1 for profile in profiles if profile.get("fast_mana")),
        "recurring_source_count": sum(1 for profile in profiles if profile.get("recurring_source")),
        "nonstandard_untap_count": sum(1 for profile in profiles if profile.get("nonstandard_untap")),
        "risk_flags": sorted({flag for profile in profiles for flag in profile.get("risk_flags", [])}),
    }


def classify_delta(adds: dict[str, Any], cuts: dict[str, Any]) -> str:
    net_delta = numeric(adds.get("same_turn_net_mana")) - numeric(cuts.get("same_turn_net_mana"))
    fixing_delta = int(adds.get("lorehold_colored_fixing") or 0) - int(
        cuts.get("lorehold_colored_fixing") or 0
    )
    recurring_delta = int(adds.get("recurring_source_count") or 0) - int(
        cuts.get("recurring_source_count") or 0
    )
    if net_delta > 0 and (fixing_delta < 0 or recurring_delta < 0):
        return "burst_vs_fixing_or_recurring_tradeoff"
    if net_delta > 0:
        return "ramp_burst_upgrade"
    if fixing_delta > 0 or recurring_delta > 0:
        return "fixing_or_recurring_upgrade"
    return "ramp_no_static_upgrade"


def evaluate_package(conn: sqlite3.Connection, package_key: str, definition: dict[str, Any]) -> dict[str, Any]:
    add_profiles = [ramp_profile(conn, name) for name in definition.get("adds", [])]
    cut_profiles = [ramp_profile(conn, name) for name in definition.get("cuts", [])]
    adds = side_summary(add_profiles)
    cuts = side_summary(cut_profiles)
    delta = {
        "mana_produced": adds["mana_produced"] - cuts["mana_produced"],
        "same_turn_net_mana": adds["same_turn_net_mana"] - cuts["same_turn_net_mana"],
        "lorehold_colored_fixing": adds["lorehold_colored_fixing"] - cuts["lorehold_colored_fixing"],
        "fast_mana_count": adds["fast_mana_count"] - cuts["fast_mana_count"],
        "recurring_source_count": adds["recurring_source_count"] - cuts["recurring_source_count"],
        "nonstandard_untap_count": adds["nonstandard_untap_count"] - cuts["nonstandard_untap_count"],
    }
    return {
        "package_key": package_key,
        "family": definition.get("family") or "misc",
        "hypothesis": definition.get("hypothesis"),
        "adds": add_profiles,
        "cuts": cut_profiles,
        "add_summary": adds,
        "cut_summary": cuts,
        "delta": delta,
        "ramp_static_classification": classify_delta(adds, cuts),
        "battle_interpretation_guardrail": (
            "A battle loss for this package rejects the exact add/cut signature, "
            "not the added ramp card globally."
        ),
    }


def render_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Lorehold Ramp Package Evaluation",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- source_db: `{payload['source_db']}`",
        "",
        "| Package | Adds | Cuts | Net Mana Delta | Fixing Delta | Recurring Delta | Classification |",
        "| --- | --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in payload["packages"]:
        lines.append(
            "| {package} | {adds} | {cuts} | {net:.2f} | {fixing} | {recurring} | {classification} |".format(
                package=row["package_key"],
                adds=", ".join(profile["card_name"] for profile in row["adds"]),
                cuts=", ".join(profile["card_name"] for profile in row["cuts"]),
                net=row["delta"]["same_turn_net_mana"],
                fixing=row["delta"]["lorehold_colored_fixing"],
                recurring=row["delta"]["recurring_source_count"],
                classification=row["ramp_static_classification"],
            )
        )
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-db", type=Path, default=DEFAULT_SOURCE_DB)
    parser.add_argument("--packages", required=True)
    parser.add_argument("--stem", default="lorehold_ramp_package_evaluation")
    parser.add_argument("--stamp", default=None)
    args = parser.parse_args()

    package_keys = [key.strip() for key in args.packages.split(",") if key.strip()]
    unknown = [key for key in package_keys if key not in PACKAGE_DEFINITIONS]
    if unknown:
        raise SystemExit(f"unknown package(s): {', '.join(unknown)}")
    source_db = args.source_db.resolve()
    stamp = args.stamp or datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    with connect(source_db) as conn:
        packages = [
            evaluate_package(conn, key, PACKAGE_DEFINITIONS[key])
            for key in package_keys
        ]
    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_db": str(source_db),
        "packages": packages,
    }
    report_json = REPORT_DIR / f"{args.stem}_{stamp}.json"
    report_md = REPORT_DIR / f"{args.stem}_{stamp}.md"
    report_json.write_text(json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    report_md.write_text(render_markdown(payload), encoding="utf-8")
    print(json.dumps({"json": str(report_json), "markdown": str(report_md)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
