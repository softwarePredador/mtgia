#!/usr/bin/env python3
"""Draft runtime contracts for the first post-identity Lorehold candidates.

This report uses the post-identity queue split plus local XMage sources to
decide what ManaLoom must implement before Brain in a Jar, Entreat the Angels,
or Haze of Rage can enter any 607 battle gate.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import external_engine_source_contract as engine_source_contract
from master_optimizer_common import resolve_default_knowledge_db


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_SPLIT_REPORT = REPORT_DIR / "lorehold_post_identity_queue_split_20260705_post_authorized_full_validation.json"
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_brain_entreat_haze_runtime_contract_20260705_post_authorized_full_validation"
)
DEFAULT_BATTLE_RUNTIME = SCRIPT_DIR / "battle_analyst_v9.py"
DEFAULT_HINTS = SCRIPT_DIR / "xmage_to_manaloom_effect_hints.py"

RUNTIME_CARDS = {
    "Brain in a Jar": {
        "implementation_priority": 2,
        "xmage_path": Path("Mage.Sets/src/mage/cards/b/BrainInAJar.java"),
        "strategic_value": (
            "High-upside topdeck/miracle access bridge, but only if charge-counter "
            "timing can cast exact-mana-value instants or sorceries from hand."
        ),
        "xmage_signals": [
            "AddCountersSourceEffect",
            "BrainInAJarCastEffect",
            "RemoveVariableCountersSourceCost",
            "ScryEffect",
            "ManaValuePredicate",
        ],
        "required_runtime_slices": [
            "activated_add_charge_counter_then_tap_cost",
            "select_hand_instant_or_sorcery_by_exact_mana_value",
            "cast_selected_spell_without_paying_mana_cost",
            "activated_remove_x_charge_counters_scry_x",
            "replay_charge_counter_and_free_cast_decision_fields",
        ],
        "manaloom_foundation": "generic_charge_counter_and_casting_primitives_exist_but_no_card_contract",
        "readiness": "blocked_requires_new_runtime_family",
    },
    "Entreat the Angels": {
        "implementation_priority": 1,
        "xmage_path": Path("Mage.Sets/src/mage/cards/e/EntreatTheAngels.java"),
        "strategic_value": (
            "Most directly aligned with the current Lorehold 607 thesis: miracle "
            "timing turns topdeck control into a closing board."
        ),
        "xmage_signals": [
            "CreateTokenEffect",
            "AngelToken",
            "GetXValue",
            "MiracleAbility",
        ],
        "required_runtime_slices": [
            "x_spell_cost_planning_for_normal_and_miracle_cast",
            "lorehold_first_draw_miracle_selection_for_x_spell",
            "create_x_4_4_flying_angel_tokens",
            "closing_window_pressure_scoring_for_token_board",
            "replay_x_value_miracle_cost_and_tokens_created",
        ],
        "manaloom_foundation": "miracle_and_token_primitives_exist_but_card_rule_missing",
        "readiness": "best_first_runtime_contract_candidate",
    },
    "Haze of Rage": {
        "implementation_priority": 3,
        "xmage_path": Path("Mage.Sets/src/mage/cards/h/HazeOfRage.java"),
        "strategic_value": (
            "Package-only payoff with Storm-Kiln Artist; it should teach combo "
            "pressure, not justify a standalone 607 inclusion."
        ),
        "xmage_signals": [
            "BuybackAbility",
            "BoostControlledEffect",
            "StormAbility",
        ],
        "required_runtime_slices": [
            "storm_copy_count_for_non_damage_boost_spell",
            "buyback_optional_additional_cost_and_return_to_hand",
            "global_creature_plus_power_until_end_of_turn_per_copy",
            "storm_kiln_artist_magecraft_treasure_on_cast_and_copy",
            "combo_loop_guard_and_cut_safety_preflight",
        ],
        "manaloom_foundation": "buyback_and_some_storm_primitives_exist_but_combo_effect_missing",
        "readiness": "blocked_complex_combo_runtime",
    },
}

STORM_KILN_PATH = Path("Mage.Sets/src/mage/cards/s/StormKilnArtist.java")


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def normalize_name(name: str) -> str:
    return " ".join(str(name or "").strip().lower().replace("’", "'").split())


def find_signals(text: str, signals: list[str]) -> dict[str, bool]:
    return {signal: signal in text for signal in signals}


def card_from_split(split_report: Mapping[str, Any], card_name: str) -> dict[str, Any]:
    wanted = normalize_name(card_name)
    for row in split_report.get("cards") or []:
        if isinstance(row, Mapping) and normalize_name(str(row.get("card_name") or "")) == wanted:
            return dict(row)
    return {}


def active_rule_rows(db_path: Path, names: list[str]) -> dict[str, list[dict[str, Any]]]:
    if not db_path.exists():
        return {}
    normalized = [normalize_name(name) for name in names]
    lowered = [name.lower() for name in names]
    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            (
                "SELECT normalized_name, card_name, logical_rule_key, effect_json, "
                "review_status, execution_status, source "
                "FROM battle_card_rules "
                f"WHERE normalized_name IN ({','.join('?' for _ in normalized)}) "
                f"OR lower(card_name) IN ({','.join('?' for _ in lowered)})"
            ),
            [*normalized, *lowered],
        ).fetchall()
    out: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        data = dict(row)
        try:
            effect_json = json.loads(data.get("effect_json") or "{}")
        except json.JSONDecodeError:
            effect_json = {}
        data["effect"] = effect_json.get("effect")
        data["battle_model_scope"] = effect_json.get("battle_model_scope")
        keys = {
            normalize_name(data.get("normalized_name") or ""),
            normalize_name(data.get("card_name") or ""),
        }
        for key in keys:
            if key:
                out.setdefault(key, []).append(data)
    return out


def runtime_foundations(battle_text: str, hints_text: str) -> dict[str, bool]:
    return {
        "buyback_runtime_enabled": "def buyback_runtime_enabled" in battle_text,
        "buyback_return_to_hand": "buyback_returned_to_hand" in battle_text,
        "storm_copy_event_foundation": "storm_copies" in battle_text,
        "miracle_casting_path": "miracle_cast" in battle_text,
        "creature_token_creation": "create_creature_token" in battle_text,
        "charge_counter_state": "charge_counters" in battle_text,
        "scry_surface": "scry" in battle_text.lower(),
        "xmage_miracle_hint": "MiracleAbility" in hints_text,
        "xmage_buyback_hint": "BuybackAbility" in hints_text,
        "xmage_storm_hint": "StormAbility" in hints_text,
    }


def contract_row(
    *,
    card_name: str,
    contract: Mapping[str, Any],
    split_report: Mapping[str, Any],
    rule_index: Mapping[str, list[dict[str, Any]]],
    foundations: Mapping[str, bool],
) -> dict[str, Any]:
    text = read_text(Path(contract["xmage_path"]))
    split = card_from_split(split_report, card_name)
    rules = list(rule_index.get(normalize_name(card_name)) or [])
    xmage_signal_hits = find_signals(text, list(contract["xmage_signals"]))
    missing_signals = [signal for signal, present in xmage_signal_hits.items() if not present]
    foundation_notes = []
    if card_name == "Entreat the Angels":
        foundation_notes = [
            "miracle_casting_path" if foundations.get("miracle_casting_path") else "missing_miracle_casting_path",
            "creature_token_creation" if foundations.get("creature_token_creation") else "missing_token_creation",
            "xmage_miracle_hint" if foundations.get("xmage_miracle_hint") else "missing_xmage_miracle_hint",
        ]
    elif card_name == "Brain in a Jar":
        foundation_notes = [
            "charge_counter_state" if foundations.get("charge_counter_state") else "missing_charge_counter_state",
            "scry_surface" if foundations.get("scry_surface") else "missing_scry_surface",
            "missing_exact_mana_value_free_cast_contract",
        ]
    elif card_name == "Haze of Rage":
        foundation_notes = [
            "buyback_runtime_enabled" if foundations.get("buyback_runtime_enabled") else "missing_buyback_runtime",
            "storm_copy_event_foundation" if foundations.get("storm_copy_event_foundation") else "missing_storm_copy_foundation",
            "missing_global_boost_storm_resolution",
            "storm_kiln_artist_magecraft_is_annotation_only",
        ]
    return {
        "card_name": card_name,
        "implementation_priority": int(contract["implementation_priority"]),
        "split_route_class": split.get("route_class"),
        "split_lane": split.get("lane"),
        "identity_source": split.get("identity_source"),
        "xmage_path": str(contract["xmage_path"]),
        "xmage_class_found": bool(text),
        "xmage_signal_hits": xmage_signal_hits,
        "xmage_missing_signals": missing_signals,
        "active_rule_rows": rules,
        "active_rule_count": len(rules),
        "strategic_value": contract["strategic_value"],
        "manaloom_foundation": contract["manaloom_foundation"],
        "foundation_notes": foundation_notes,
        "required_runtime_slices": list(contract["required_runtime_slices"]),
        "readiness": contract["readiness"],
        "battle_ready_now": False,
        "promotion_allowed_now": False,
    }


def storm_kiln_summary(
    rule_index: Mapping[str, list[dict[str, Any]]],
    *,
    xmage_path: Path = STORM_KILN_PATH,
) -> dict[str, Any]:
    text = read_text(xmage_path)
    rules = list(rule_index.get("storm-kiln artist") or rule_index.get("storm kiln artist") or [])
    scopes = [str(row.get("battle_model_scope") or "") for row in rules]
    return {
        "card_name": "Storm-Kiln Artist",
        "xmage_path": str(xmage_path),
        "xmage_class_found": bool(text),
        "xmage_signal_hits": find_signals(text, ["MagecraftAbility", "CreateTokenEffect", "TreasureToken", "ArtifactYouControlCount"]),
        "active_rule_count": len(rules),
        "rule_scopes": scopes,
        "annotation_only": any("annotation" in scope for scope in scopes),
        "contract_note": (
            "Storm-Kiln Artist exists locally, but the current rule scope is annotation-only; "
            "the Haze combo needs executable magecraft treasure on cast and copied spells."
        ),
    }


def build_payload(
    *,
    split_report: Mapping[str, Any],
    split_path: Path,
    db_path: Path,
    battle_runtime_path: Path,
    hints_path: Path,
    xmage_root: Path | None = None,
) -> dict[str, Any]:
    rule_index = active_rule_rows(db_path, [*RUNTIME_CARDS.keys(), "Storm-Kiln Artist"])
    foundations = runtime_foundations(read_text(battle_runtime_path), read_text(hints_path))
    runtime_cards = {
        card_name: {
            **contract,
            "xmage_path": (
                xmage_root / Path(contract["xmage_path"])
                if xmage_root is not None and not Path(contract["xmage_path"]).is_absolute()
                else Path(contract["xmage_path"])
            ),
        }
        for card_name, contract in RUNTIME_CARDS.items()
    }
    contracts = [
        contract_row(
            card_name=card_name,
            contract=contract,
            split_report=split_report,
            rule_index=rule_index,
            foundations=foundations,
        )
        for card_name, contract in runtime_cards.items()
    ]
    contracts.sort(key=lambda row: (row["implementation_priority"], row["card_name"]))
    best_first = contracts[0]["card_name"] if contracts else ""
    payload = {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_brain_entreat_haze_runtime_contract",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": {
            "post_identity_queue_split": rel(split_path),
        },
        "source_db": str(db_path),
        "xmage_root": str(xmage_root) if xmage_root is not None else "injected_test_sources",
        "status": "runtime_contracts_drafted_no_battle_ready_keep_607",
        "summary": {
            "current_baseline": "deck_607",
            "runtime_contract_count": len(contracts),
            "xmage_class_found_count": sum(1 for row in contracts if row["xmage_class_found"]),
            "cards_with_active_rule_count": sum(1 for row in contracts if row["active_rule_count"] > 0),
            "battle_ready_now_count": 0,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "best_first_runtime_contract": best_first,
            "recommended_next_action": "prepare_entreat_the_angels_runtime_contract_before_battle",
        },
        "runtime_foundations": foundations,
        "contracts": contracts,
        "storm_kiln_artist_dependency": storm_kiln_summary(
            rule_index,
            xmage_path=(xmage_root / STORM_KILN_PATH if xmage_root is not None else STORM_KILN_PATH),
        ),
        "decision": {
            "keep_607_as_protected_baseline": True,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "XMage confirms the three card implementations, but ManaLoom still lacks "
                "card-level runtime contracts and safe-cut evidence. Entreat is the best first "
                "runtime candidate because it reuses the Lorehold miracle thesis and token board pressure."
            ),
        },
    }
    return payload


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Brain/Entreat/Haze Runtime Contract",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Current baseline: `{summary['current_baseline']}`",
        f"- XMage root: `{payload['xmage_root']}`",
        f"- Source DB mutated: `{payload['source_db_mutated']}`",
        f"- Deck 607 mutated: `{payload['deck_607_mutated']}`",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "| --- | ---: |",
    ]
    for key in [
        "runtime_contract_count",
        "xmage_class_found_count",
        "cards_with_active_rule_count",
        "battle_ready_now_count",
    ]:
        lines.append(f"| `{key}` | `{summary[key]}` |")
    lines.append(f"| `best_first_runtime_contract` | `{summary['best_first_runtime_contract']}` |")
    lines.extend(
        [
            "",
            "## Contracts",
            "",
            "| Card | Readiness | XMage Signals | Active Rules | Required Runtime |",
            "| --- | --- | --- | ---: | --- |",
        ]
    )
    for row in payload["contracts"]:
        signals = ", ".join(signal for signal, present in row["xmage_signal_hits"].items() if present)
        runtime = "; ".join(row["required_runtime_slices"])
        lines.append(
            f"| {row['card_name']} | `{row['readiness']}` | {signals} | `{row['active_rule_count']}` | {runtime} |"
        )
    storm = payload["storm_kiln_artist_dependency"]
    lines.extend(
        [
            "",
            "## Storm-Kiln Dependency",
            "",
            f"- XMage class found: `{storm['xmage_class_found']}`",
            f"- Active rule count: `{storm['active_rule_count']}`",
            f"- Annotation only: `{storm['annotation_only']}`",
            f"- Note: {storm['contract_note']}",
            "",
            "## Decision",
            "",
            f"- Keep 607 as protected baseline: `{payload['decision']['keep_607_as_protected_baseline']}`",
            f"- Natural battle allowed now: `{payload['decision']['natural_battle_allowed_now']}`",
            f"- Promotion allowed: `{payload['decision']['promotion_allowed']}`",
            f"- Reason: {payload['decision']['reason']}",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--xmage-root", type=Path)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--split-report", type=Path, default=DEFAULT_SPLIT_REPORT)
    parser.add_argument("--battle-runtime", type=Path, default=DEFAULT_BATTLE_RUNTIME)
    parser.add_argument("--hints", type=Path, default=DEFAULT_HINTS)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    try:
        xmage_root = engine_source_contract.resolve_xmage_source_root(args.xmage_root)
    except ValueError as exc:
        raise SystemExit(str(exc)) from exc
    payload = build_payload(
        split_report=read_json(args.split_report),
        split_path=args.split_report,
        db_path=args.db,
        battle_runtime_path=args.battle_runtime,
        hints_path=args.hints,
        xmage_root=xmage_root,
    )
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "best_first_runtime_contract": payload["summary"]["best_first_runtime_contract"],
                "battle_ready_now_count": payload["summary"]["battle_ready_now_count"],
            },
            ensure_ascii=True,
        )
    )
    return 0 if payload["status"] == "runtime_contracts_drafted_no_battle_ready_keep_607" else 1


if __name__ == "__main__":
    raise SystemExit(main())
