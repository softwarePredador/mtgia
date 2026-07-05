#!/usr/bin/env python3
"""Draft the exact Brain in a Jar runtime-family contract.

Brain in a Jar is blocked for Lorehold deck work because it needs a combined
activated runtime family: add a charge counter, then cast one instant/sorcery
from hand with mana value equal to the new charge-counter count, plus a second
activation that removes X charge counters to scry X. This report validates the
XMage source and writes the exact ManaLoom effect-json contract without
creating PostgreSQL rows, running battle, or mutating deck 607.
"""

from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
XMAGE_ROOT = Path("/Users/desenvolvimentomobile/Downloads/mage-master")

DEFAULT_XMAGE_SOURCE = XMAGE_ROOT / "Mage.Sets/src/mage/cards/b/BrainInAJar.java"
DEFAULT_BATTLE_RUNTIME = SCRIPT_DIR / "battle_analyst_v9.py"
DEFAULT_ROUTE_PLANNER = REPORT_DIR / "lorehold_miracle_next_route_planner_20260705_current.json"
DEFAULT_PREFLIGHT = REPORT_DIR / "lorehold_brain_in_a_jar_runtime_cut_preflight_20260705_current.json"
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_brain_in_a_jar_exact_runtime_contract_20260705_current"
)

SCOPE = "xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1"


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def as_dict(value: Any) -> dict[str, Any]:
    return dict(value) if isinstance(value, Mapping) else {}


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def signal_present(text: str, pattern: str) -> bool:
    return re.search(pattern, text, flags=re.MULTILINE | re.DOTALL) is not None


def xmage_contract_signals(source_text: str) -> dict[str, bool]:
    return {
        "class_found": "class BrainInAJar" in source_text,
        "artifact_cost_two": "new CardType[]{CardType.ARTIFACT}, \"{2}\"" in source_text,
        "first_activation_generic_one": "new GenericManaCost(1)" in source_text,
        "first_activation_tap_cost": "ability.addCost(new TapSourceCost())" in source_text,
        "adds_charge_counter": "AddCountersSourceEffect(CounterType.CHARGE.createInstance())" in source_text,
        "brain_cast_effect": "new BrainInAJarCastEffect()" in source_text,
        "uses_current_charge_count": "getCount(CounterType.CHARGE)" in source_text,
        "filters_instant_or_sorcery": "new FilterInstantOrSorceryCard()" in source_text,
        "exact_mana_value_predicate": "ManaValuePredicate(ComparisonType.EQUAL_TO, counters)" in source_text,
        "casts_from_hand_for_free": "CardUtil.castSpellWithAttributesForFree" in source_text
        and "controller.getHand()" in source_text,
        "second_activation_generic_three": "new GenericManaCost(3)" in source_text,
        "remove_variable_charge_counters": "RemoveVariableCountersSourceCost(CounterType.CHARGE)" in source_text,
        "scry_uses_x_value": "new ScryEffect(GetXValue.instance)" in source_text,
    }


def battle_runtime_surfaces(runtime_text: str) -> dict[str, bool]:
    lowered = runtime_text.lower()
    return {
        "activated_add_counters_executor": "activated_add_counters" in runtime_text
        and "resolve_add_counters_source_effect" in runtime_text,
        "free_cast_without_paying_mana_primitive": "cast_without_paying_mana" in runtime_text
        and "zero_mana_cost_snapshot" in runtime_text,
        "free_cast_from_hand_primitive": "invoke_calamity_free_cast_candidates" in runtime_text
        and '"hand"' in runtime_text,
        "scry_library_primitive": "def scry_library_for_controller" in runtime_text,
        "charge_counter_state_surface": "charge_counters" in runtime_text,
        "brain_exact_scope_adapter": SCOPE in runtime_text or "brain_in_a_jar" in lowered,
        "exact_mana_value_hand_free_cast_adapter": "exact_mana_value" in lowered
        and "free_cast" in lowered
        and "hand" in lowered
        and "charge_counter" in lowered,
        "remove_x_charge_counters_scry_adapter": "remove_variable" in lowered
        and "charge" in lowered
        and "scry" in lowered,
    }


def build_effect_json() -> dict[str, Any]:
    return {
        "effect": "topdeck_manipulation",
        "battle_model_scope": SCOPE,
        "ability_kind": "activated",
        "source_card": "Brain in a Jar",
        "activation_requires_tap": True,
        "activation_cost_mana": "{1}",
        "activation_cost_generic": 1,
        "activated_add_counters": True,
        "activated_add_counters_target": "self",
        "activated_add_counters_counter_type": "charge",
        "activated_add_counters_count": 1,
        "brain_in_a_jar_free_cast": True,
        "free_cast_from_zone": "hand",
        "free_cast_card_types": ["instant", "sorcery"],
        "free_cast_mana_value_match": "source_charge_counters_after_add",
        "free_cast_exactly_one_card": True,
        "cast_without_paying_mana_cost": True,
        "secondary_activation_requires_tap": True,
        "secondary_activation_cost_mana": "{3}",
        "secondary_activation_cost_generic": 3,
        "secondary_activation_remove_counter_type": "charge",
        "secondary_activation_remove_x_counters": True,
        "secondary_activation_scry_count_source": "removed_charge_counters",
        "replay_required_fields": [
            "activation_kind",
            "charge_counters_before",
            "charge_counters_after",
            "eligible_spell_names",
            "selected_spell",
            "selected_spell_mana_value",
            "cast_without_paying_mana_cost",
            "removed_charge_counters",
            "scry_count",
            "scry_looked_at",
            "scry_kept_on_top",
            "scry_bottomed",
            "scry_top_after",
        ],
        "xmage_effect_classes": [
            "AddCountersSourceEffect",
            "BrainInAJarCastEffect",
            "ScryEffect",
        ],
        "xmage_cost_classes": [
            "GenericManaCost",
            "TapSourceCost",
            "RemoveVariableCountersSourceCost",
        ],
    }


def test_vectors() -> list[dict[str, Any]]:
    return [
        {
            "name": "first_activation_casts_exact_mana_value_one",
            "starting_brain_charge_counters": 0,
            "activation": "{1}, tap",
            "hand": [
                {"name": "Shock", "type_line": "Instant", "mana_value": 1},
                {"name": "Divination", "type_line": "Sorcery", "mana_value": 3},
                {"name": "Sol Ring", "type_line": "Artifact", "mana_value": 1},
            ],
            "expected": {
                "charge_counters_after": 1,
                "eligible_spell_names": ["Shock"],
                "selected_spell": "Shock",
                "cast_without_paying_mana_cost": True,
                "artifact_with_matching_mana_value_is_not_eligible": True,
            },
        },
        {
            "name": "second_activation_casts_exact_mana_value_two_or_declines",
            "starting_brain_charge_counters": 1,
            "activation": "{1}, tap",
            "hand": [
                {"name": "Lightning Helix", "type_line": "Instant", "mana_value": 2},
                {"name": "Reforge the Soul", "type_line": "Sorcery", "mana_value": 5},
            ],
            "expected": {
                "charge_counters_after": 2,
                "eligible_spell_names": ["Lightning Helix"],
                "selected_spell": "Lightning Helix",
                "cast_without_paying_mana_cost": True,
            },
        },
        {
            "name": "remove_x_charge_counters_scry_x",
            "starting_brain_charge_counters": 3,
            "activation": "{3}, tap, remove X charge counters",
            "remove_x": 2,
            "library_top": ["Low Priority Land", "High Priority Spell", "Medium Priority Spell"],
            "expected": {
                "charge_counters_after": 1,
                "scry_count": 2,
                "scry_reorders_or_bottoms_low_priority_cards": True,
            },
        },
    ]


def decision_status(signals: Mapping[str, bool], surfaces: Mapping[str, bool]) -> tuple[str, str]:
    if not signals or not signals.get("class_found"):
        return (
            "brain_exact_runtime_contract_blocked_missing_xmage_source",
            "restore_or_locate_brain_in_a_jar_xmage_source",
        )
    missing = [name for name, present in signals.items() if not present]
    if missing:
        return (
            "brain_exact_runtime_contract_blocked_incomplete_xmage_signal",
            "resolve_xmage_signal_gap_before_runtime_adapter",
        )
    if not surfaces.get("brain_exact_scope_adapter"):
        return (
            "brain_exact_runtime_contract_drafted_adapter_missing_keep_607",
            "implement_brain_in_a_jar_runtime_adapter_no_deck_action",
        )
    return (
        "brain_exact_runtime_contract_adapter_detected_preflight_required_keep_607",
        "rerun_brain_runtime_cut_preflight_before_any_deck_action",
    )


def build_report(
    *,
    xmage_source_text: str,
    battle_runtime_text: str,
    route_planner: Mapping[str, Any],
    preflight: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    signals = xmage_contract_signals(xmage_source_text)
    surfaces = battle_runtime_surfaces(battle_runtime_text)
    status, next_action = decision_status(signals, surfaces)
    missing_signals = [name for name, present in signals.items() if not present]
    effect_json = build_effect_json()
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_brain_in_a_jar_exact_runtime_contract",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in paths.items()},
        "summary": {
            "decision_status": status,
            "route_planner_selected_brain": summary(route_planner).get("selected_card") == "Brain in a Jar",
            "prior_preflight_status": preflight.get("status") or summary(preflight).get("decision_status") or "",
            "xmage_signal_count": len(signals),
            "xmage_missing_signal_count": len(missing_signals),
            "battle_runtime_surface_count": sum(1 for present in surfaces.values() if present),
            "brain_exact_scope_adapter_present": bool(surfaces.get("brain_exact_scope_adapter")),
            "contract_drafted": status != "brain_exact_runtime_contract_blocked_missing_xmage_source",
            "effect_json_scope": effect_json["battle_model_scope"],
            "test_vector_count": len(test_vectors()),
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "postgres_writes_allowed_now": False,
            "deck_action_allowed_now": False,
            "recommended_next_action": next_action,
        },
        "xmage_signals": signals,
        "missing_xmage_signals": missing_signals,
        "battle_runtime_surfaces": surfaces,
        "effect_json_contract": effect_json,
        "focused_runtime_test_vectors": test_vectors(),
        "source_evidence": {
            "external_confirmation": {
                "scryfall": "https://scryfall.com/card/soi/252/brain-in-a-jar",
                "gatherer": "https://gatherer.wizards.com/SOI/en-us/252/brain-in-a-jar",
                "interpretation": (
                    "Brain's first ability counts charge counters after adding one, "
                    "then may cast one matching instant or sorcery from hand for free; "
                    "the second activation removes X charge counters to scry X."
                ),
            },
            "route_planner_summary": summary(route_planner),
            "prior_preflight_summary": summary(preflight),
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "postgres_writes_allowed": False,
            "runtime_adapter_required_before_pg_package": not bool(surfaces.get("brain_exact_scope_adapter")),
            "preflight_required_after_adapter": True,
            "safe_cut_still_required": True,
            "reason": (
                "The exact Brain runtime contract is now explicit, but the current battle runtime "
                "does not expose the Brain-specific adapter. Deck 607 therefore remains protected "
                "and Brain cannot enter candidate scoring, PostgreSQL packaging, or battle."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_generate_brain_pg_package_until_adapter_and_focused_tests_exist",
                "implement_brain_in_a_jar_runtime_adapter_no_deck_action",
                "rerun_brain_runtime_cut_preflight_after_adapter",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = payload["summary"]
    lines = [
        "# Lorehold Brain in a Jar Exact Runtime Contract",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Decision status: `{summary_row['decision_status']}`",
        f"- Contract drafted: `{str(summary_row['contract_drafted']).lower()}`",
        f"- XMage signals: `{summary_row['xmage_signal_count']}`",
        f"- Missing XMage signals: `{summary_row['xmage_missing_signal_count']}`",
        f"- Runtime surfaces detected: `{summary_row['battle_runtime_surface_count']}`",
        f"- Brain exact adapter present: `{str(summary_row['brain_exact_scope_adapter_present']).lower()}`",
        f"- Effect scope: `{summary_row['effect_json_scope']}`",
        f"- Focused test vectors: `{summary_row['test_vector_count']}`",
        f"- Natural battle gate allowed now: `{str(summary_row['natural_battle_gate_allowed_now']).lower()}`",
        f"- PostgreSQL writes allowed now: `{str(summary_row['postgres_writes_allowed_now']).lower()}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Effect JSON Contract", ""])
    effect_json = as_dict(payload.get("effect_json_contract"))
    lines.append(f"- scope: `{effect_json.get('battle_model_scope')}`")
    lines.append(f"- first activation: `{effect_json.get('activation_cost_mana')}, tap -> add charge counter then free-cast exact mana value from hand`")
    lines.append(f"- free cast types: `{', '.join(effect_json.get('free_cast_card_types') or [])}`")
    lines.append(f"- mana value match: `{effect_json.get('free_cast_mana_value_match')}`")
    lines.append(f"- second activation: `{effect_json.get('secondary_activation_cost_mana')}, tap, remove X charge counters -> scry X`")
    lines.extend(["", "## Runtime Surface Check", ""])
    for key, value in sorted(as_dict(payload.get("battle_runtime_surfaces")).items()):
        lines.append(f"- `{key}`: `{str(bool(value)).lower()}`")
    lines.extend(["", "## Focused Test Vectors", ""])
    for vector in payload.get("focused_runtime_test_vectors") or []:
        lines.append(f"- `{vector['name']}`")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision['natural_battle_allowed_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- postgres_writes_allowed: `{str(decision['postgres_writes_allowed']).lower()}`")
    lines.append(f"- runtime_adapter_required_before_pg_package: `{str(decision['runtime_adapter_required_before_pg_package']).lower()}`")
    lines.append(f"- safe_cut_still_required: `{str(decision['safe_cut_still_required']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    lines.append("- next_actions:")
    for action in decision["next_actions"]:
        lines.append(f"  - {action}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xmage-source", type=Path, default=DEFAULT_XMAGE_SOURCE)
    parser.add_argument("--battle-runtime", type=Path, default=DEFAULT_BATTLE_RUNTIME)
    parser.add_argument("--route-planner", type=Path, default=DEFAULT_ROUTE_PLANNER)
    parser.add_argument("--preflight", type=Path, default=DEFAULT_PREFLIGHT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "xmage_source": args.xmage_source,
        "battle_runtime": args.battle_runtime,
        "route_planner": args.route_planner,
        "preflight": args.preflight,
    }
    payload = build_report(
        xmage_source_text=read_text(args.xmage_source),
        battle_runtime_text=read_text(args.battle_runtime),
        route_planner=read_json(args.route_planner),
        preflight=read_json(args.preflight),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
