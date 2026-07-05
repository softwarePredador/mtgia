#!/usr/bin/env python3
"""Score a Commander candidate package against commander-specific strategy.

This is a review-only gate between an isolated package-chain audit and any
battle probe. It compares the original deck to the final candidate copy,
checks commander-profile targets, and surfaces package cut risks. It does not
run battles, mutate SQLite/PostgreSQL, or promote decks.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_core_role_audit as core_roles
from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_PACKAGE_CHAIN_REPORT = (
    REPORT_DIR / "global_commander_candidate_package_chain_audit_20260705_kaalia_removal_floor_step5.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_candidate_package_strategy_matrix_20260705_kaalia_removal_floor_step5"
)

KAALIA_PROFILE = {
    "commander": "Kaalia of the Vast",
    "source": "server/lib/ai/commander_reference_profile_support.dart",
    "version": "kaalia_of_the_vast_reference_profile_v1_2026-07-05",
    "role_targets": {
        "lands": {"min": 35, "max": 37, "hard_floor": True},
        "mana_acceleration": {"min": 10, "max": 14, "hard_floor": True},
        "haste_protection_silence": {"min": 8, "max": 12, "hard_floor": True},
        "angels_demons_dragons_payoffs": {"min": 22, "max": 30, "hard_floor": True},
        "spot_interaction": {"min": 8, "max": 12, "hard_floor": True},
        "board_wipes_resets": {"min": 2, "max": 4, "hard_floor": True},
        "card_draw_selection": {"min": 7, "max": 11, "hard_floor": True},
        "tutors_access": {"min": 4, "max": 8, "hard_floor": False},
        "reanimation_plan_b": {"min": 3, "max": 6, "hard_floor": True},
        "dedicated_win_conditions": {"min": 3, "max": 6, "hard_floor": True},
    },
    "expected_packages": {
        "commander_attack_enablers": [
            "Lightning Greaves",
            "Swiftfoot Boots",
            "Hall of the Bandit Lord",
            "Arena of Glory",
            "Grand Abolisher",
            "Silence",
            "Ranger-Captain of Eos",
            "Teferi's Protection",
            "Boros Charm",
            "Akroma's Will",
            "Deflecting Swat",
            "Flawless Maneuver",
        ],
        "angels_demons_dragons_payoffs": [
            "Master of Cruelties",
            "Avacyn, Angel of Hope",
            "Balefire Dragon",
            "Ancient Copper Dragon",
            "Rune-Scarred Demon",
            "Razaketh, the Foulblooded",
            "Aurelia, the Warleader",
            "Bloodthirster",
            "Hoarding Broodlord",
            "Angel of Serenity",
            "Angel of the Ruins",
        ],
        "interaction_and_resets": [
            "Swords to Plowshares",
            "Path to Exile",
            "Feed the Swarm",
            "Anguished Unmaking",
            "Despark",
            "Terminate",
            "Bedevil",
            "Vindicate",
            "Damn",
            "Farewell",
            "Ruinous Ultimatum",
        ],
        "mana_ramp_foundation": [
            "Sol Ring",
            "Arcane Signet",
            "Fellwar Stone",
            "Boros Signet",
            "Orzhov Signet",
            "Rakdos Signet",
            "Talisman of Conviction",
            "Talisman of Hierarchy",
            "Talisman of Indulgence",
            "Ancient Tomb",
            "Sword of the Animist",
        ],
        "card_flow_and_access": [
            "Demonic Tutor",
            "Vampiric Tutor",
            "Enlightened Tutor",
            "Rune-Scarred Demon",
            "Necropotence",
            "Night's Whisper",
            "Esper Sentinel",
        ],
        "reanimation_plan_b": [
            "Reanimate",
            "Animate Dead",
            "Necromancy",
            "Living Death",
            "Karmic Guide",
            "Sneak Attack",
            "Incarnation Technique",
        ],
    },
}

PROFILE_BY_COMMANDER = {
    normalize_name(KAALIA_PROFILE["commander"]): KAALIA_PROFILE,
}

ROLE_ORDER = list(KAALIA_PROFILE["role_targets"].keys())


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def card_text(row: Mapping[str, Any]) -> str:
    return f"{row.get('type_line') or ''}\n{row.get('oracle_text') or ''}".lower()


def has_any(text: str, patterns: tuple[str, ...]) -> bool:
    return any(pattern in text for pattern in patterns)


def deck_rows(db_path: Path, deck_id: str) -> list[dict[str, Any]]:
    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            """
            SELECT card_name, COALESCE(quantity, 1) AS quantity,
                   functional_tag, functional_tags_json, type_line, oracle_text,
                   COALESCE(is_commander, 0) AS is_commander
            FROM deck_cards
            WHERE deck_id=?
            ORDER BY card_name
            """,
            (deck_id,),
        ).fetchall()
    return [dict(row) for row in rows]


def is_land(row: Mapping[str, Any]) -> bool:
    return "land" in str(row.get("type_line") or "").lower()


def is_add_payoff(row: Mapping[str, Any]) -> bool:
    type_line = str(row.get("type_line") or "").lower()
    return "creature" in type_line and any(kind in type_line for kind in ("angel", "demon", "dragon"))


def is_spot_interaction(row: Mapping[str, Any], roles: set[str]) -> bool:
    text = card_text(row)
    target_patterns = (
        "destroy target",
        "exile target",
        "counter target",
        "return target",
        "damage to any target",
        "target creature gets -",
        "target nonland permanent",
        "target artifact",
        "target enchantment",
    )
    if (
        ("board_wipe" in roles or has_any(text, ("destroy all", "exile all", "destroy each", "exile each", "each creature")))
        and not has_any(text, target_patterns)
    ):
        return False
    return "removal" in roles and has_any(text, target_patterns)


def is_mana_acceleration(row: Mapping[str, Any], roles: set[str]) -> bool:
    text = card_text(row)
    if is_land(row):
        return False
    return "ramp" in roles or has_any(
        text,
        (
            "treasure token",
            "create a treasure",
            "add one mana",
            "add two mana",
            "{t}: add",
            "costs less to cast",
            "search your library for up to two basic",
            "put a land card from your hand onto the battlefield",
        ),
    )


def is_haste_protection(row: Mapping[str, Any], roles: set[str]) -> bool:
    text = card_text(row)
    return "protection" in roles or has_any(
        text,
        (
            "haste",
            "hexproof",
            "shroud",
            "indestructible",
            "protection from",
            "opponents can't cast",
            "can't cast spells",
            "prevent all damage",
            "phase out",
            "change the target",
        ),
    )


def is_card_flow(row: Mapping[str, Any], roles: set[str]) -> bool:
    return "draw" in roles


def is_tutor_access(row: Mapping[str, Any], roles: set[str]) -> bool:
    text = card_text(row)
    return "search your library" in text or "search their library for a card" in text


def is_reanimation(row: Mapping[str, Any], roles: set[str]) -> bool:
    text = card_text(row)
    return "recursion" in roles and has_any(
        text,
        (
            "from your graveyard",
            "from a graveyard",
            "return target creature card",
            "return enchanted creature card",
            "return that card to the battlefield",
            "put all creature cards from all graveyards onto the battlefield",
            "reanimate",
        ),
    )


def is_wincon(row: Mapping[str, Any], roles: set[str]) -> bool:
    return "wincon" in roles


def profile_roles_for_card(row: Mapping[str, Any]) -> set[str]:
    roles, _source = core_roles.card_roles(row)
    profile_roles: set[str] = set()
    if is_land(row):
        profile_roles.add("lands")
    if is_mana_acceleration(row, roles):
        profile_roles.add("mana_acceleration")
    if is_haste_protection(row, roles):
        profile_roles.add("haste_protection_silence")
    if is_add_payoff(row):
        profile_roles.add("angels_demons_dragons_payoffs")
    if is_spot_interaction(row, roles):
        profile_roles.add("spot_interaction")
    if "board_wipe" in roles:
        profile_roles.add("board_wipes_resets")
    if is_card_flow(row, roles):
        profile_roles.add("card_draw_selection")
    if is_tutor_access(row, roles):
        profile_roles.add("tutors_access")
    if is_reanimation(row, roles):
        profile_roles.add("reanimation_plan_b")
    if is_wincon(row, roles):
        profile_roles.add("dedicated_win_conditions")
    return profile_roles


def profile_role_counts(rows: list[dict[str, Any]]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        quantity = int(row.get("quantity") or 1)
        for role in profile_roles_for_card(row):
            counts[role] += quantity
    return {role: int(counts.get(role) or 0) for role in ROLE_ORDER}


def target_status(count: int, target: Mapping[str, Any]) -> str:
    if count < int(target["min"]):
        return "below_target"
    if count > int(target["max"]):
        return "above_target_review"
    return "in_range"


def target_evaluations(
    *,
    profile: Mapping[str, Any],
    base_counts: Mapping[str, int],
    candidate_counts: Mapping[str, int],
) -> list[dict[str, Any]]:
    rows = []
    for role, target in profile["role_targets"].items():
        base_count = int(base_counts.get(role) or 0)
        candidate_count = int(candidate_counts.get(role) or 0)
        rows.append(
            {
                "role": role,
                "base_count": base_count,
                "candidate_count": candidate_count,
                "delta": candidate_count - base_count,
                "min": int(target["min"]),
                "max": int(target["max"]),
                "hard_floor": bool(target.get("hard_floor")),
                "base_status": target_status(base_count, target),
                "candidate_status": target_status(candidate_count, target),
            }
        )
    return rows


def card_by_name(rows: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    return {normalize_name(str(row.get("card_name") or "")): row for row in rows}


def package_presence(rows: list[dict[str, Any]], profile: Mapping[str, Any]) -> dict[str, Any]:
    names = set(card_by_name(rows))
    result = {}
    for package_name, cards in profile["expected_packages"].items():
        expected = [str(card) for card in cards]
        present = [card for card in expected if normalize_name(card) in names]
        missing = [card for card in expected if normalize_name(card) not in names]
        result[package_name] = {
            "expected_count": len(expected),
            "present_count": len(present),
            "present_cards": present,
            "missing_cards": missing,
        }
    return result


def is_attack_window_card(row: Mapping[str, Any]) -> bool:
    text = card_text(row)
    return has_any(
        text,
        (
            "additional combat phase",
            "untap all attacking creatures",
            "double strike",
            "beginning of combat",
            "attach any number of auras and equipment",
            "equipped creature",
            "creatures you control have haste",
            "can't be blocked",
        ),
    )


def cut_risk(row: Mapping[str, Any]) -> list[str]:
    roles, _source = core_roles.card_roles(row)
    risks: list[str] = []
    if is_add_payoff(row):
        risks.append("angel_demon_dragon_payoff_cut")
    if is_attack_window_card(row):
        risks.append("attack_window_or_extra_combat_cut")
    if is_mana_acceleration(row, roles):
        risks.append("mana_acceleration_cut")
    if is_haste_protection(row, roles):
        risks.append("haste_or_protection_cut")
    if is_tutor_access(row, roles):
        risks.append("tutor_access_cut")
    if is_card_flow(row, roles):
        risks.append("card_flow_cut")
    return risks


def package_delta_rows(
    *,
    package_summary: Mapping[str, Any],
    base_rows: list[dict[str, Any]],
    candidate_rows: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    base_by_name = card_by_name(base_rows)
    candidate_by_name = card_by_name(candidate_rows)
    adds = [str(card) for card in package_summary.get("package_adds", [])]
    cuts = [str(card) for card in package_summary.get("package_cuts", [])]
    rows = []
    for card in adds:
        row = candidate_by_name.get(normalize_name(card), {})
        rows.append(
            {
                "action": "add",
                "card": card,
                "present": bool(row),
                "profile_roles": sorted(profile_roles_for_card(row)) if row else [],
                "risk_flags": [],
            }
        )
    for card in cuts:
        row = base_by_name.get(normalize_name(card), {})
        rows.append(
            {
                "action": "cut",
                "card": card,
                "present": bool(row),
                "profile_roles": sorted(profile_roles_for_card(row)) if row else [],
                "risk_flags": cut_risk(row) if row else ["cut_card_missing_from_base"],
            }
        )
    return rows


def strategy_blockers(
    *,
    package_chain: Mapping[str, Any],
    target_rows: list[dict[str, Any]],
    delta_rows: list[dict[str, Any]],
) -> list[str]:
    blockers: list[str] = []
    summary = package_chain.get("summary") or {}
    if not summary.get("materializer_chain_pass"):
        blockers.append("package_chain_not_clean")
    if not summary.get("core_floor_repaired"):
        blockers.append("package_core_floor_not_repaired")
    for row in target_rows:
        if row["hard_floor"] and row["candidate_status"] == "below_target":
            blockers.append(f"profile_{row['role']}_below_target")
    attack_cuts = [
        row for row in delta_rows if row["action"] == "cut" and "attack_window_or_extra_combat_cut" in row["risk_flags"]
    ]
    attack_adds = [
        row
        for row in delta_rows
        if row["action"] == "add"
        and (
            "haste_protection_silence" in row["profile_roles"]
            or "angels_demons_dragons_payoffs" in row["profile_roles"]
        )
    ]
    if attack_cuts and not attack_adds:
        blockers.append("attack_window_cut_without_replacement")
    return blockers


def build_report(
    *,
    package_chain_report: Path,
    base_db: Path,
    candidate_db: Path | None = None,
) -> dict[str, Any]:
    package_chain = load_json(package_chain_report)
    summary = package_chain.get("summary") or {}
    deck_id = str(summary.get("deck_id") or "")
    commander = str(summary.get("commander") or "")
    profile = PROFILE_BY_COMMANDER.get(normalize_name(commander))
    if candidate_db is None:
        candidate_db = REPO_ROOT / str(summary.get("final_candidate_db") or "")
    base_rows = deck_rows(base_db, deck_id)
    candidate_rows = deck_rows(candidate_db, deck_id)
    if profile is None:
        blockers = ["commander_profile_not_available"]
        target_rows: list[dict[str, Any]] = []
        base_counts: dict[str, int] = {}
        candidate_counts: dict[str, int] = {}
        base_packages: dict[str, Any] = {}
        candidate_packages: dict[str, Any] = {}
        delta_rows = package_delta_rows(package_summary=summary, base_rows=base_rows, candidate_rows=candidate_rows)
    else:
        base_counts = profile_role_counts(base_rows)
        candidate_counts = profile_role_counts(candidate_rows)
        target_rows = target_evaluations(profile=profile, base_counts=base_counts, candidate_counts=candidate_counts)
        base_packages = package_presence(base_rows, profile)
        candidate_packages = package_presence(candidate_rows, profile)
        delta_rows = package_delta_rows(package_summary=summary, base_rows=base_rows, candidate_rows=candidate_rows)
        blockers = strategy_blockers(
            package_chain=package_chain,
            target_rows=target_rows,
            delta_rows=delta_rows,
        )
    battle_allowed = not blockers
    return {
        "generated_at": utc_now(),
        "status": "package_strategy_ready_for_battle_probe" if battle_allowed else "package_strategy_blocks_battle",
        "artifact_type": "global_commander_candidate_package_strategy_matrix",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": battle_allowed,
        "input_artifacts": {
            "package_chain_report": rel(package_chain_report),
            "base_db": rel(base_db),
            "candidate_db": rel(candidate_db),
        },
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "profile_version": (profile or {}).get("version"),
            "profile_source": (profile or {}).get("source"),
            "target_count": len(target_rows),
            "blocker_count": len(blockers),
            "package_adds": list(summary.get("package_adds") or []),
            "package_cuts": list(summary.get("package_cuts") or []),
            "next_gate": (
                "run_equal_battle_probe_with_replay_exposure"
                if battle_allowed
                else "repair_commander_profile_blockers_before_battle"
            ),
        },
        "blocker_reasons": blockers,
        "target_evaluations": target_rows,
        "base_profile_role_counts": base_counts,
        "candidate_profile_role_counts": candidate_counts,
        "base_expected_package_presence": base_packages,
        "candidate_expected_package_presence": candidate_packages,
        "package_delta": delta_rows,
        "policy": {
            "profile_gate": "Commander-specific role targets and package risks are checked after generic core floors.",
            "battle_boundary": "Only a strategy-ready package can open an equal battle probe; this matrix never promotes a deck.",
            "cut_boundary": "Interaction upgrades cannot hide cuts that weaken the commander's attack window or source-lane plan.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Candidate Package Strategy Matrix",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- profile_version: `{summary['profile_version']}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- blocker_count: `{summary['blocker_count']}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Target Evaluation",
        "",
        "| Role | Base | Candidate | Delta | Target | Candidate Status |",
        "| --- | ---: | ---: | ---: | --- | --- |",
    ]
    for row in payload["target_evaluations"]:
        lines.append(
            f"| `{row['role']}` | {row['base_count']} | {row['candidate_count']} | {row['delta']} | `{row['min']}-{row['max']}` | `{row['candidate_status']}` |"
        )
    lines.extend(["", "## Package Delta", "", "| Action | Card | Profile Roles | Risk Flags |", "| --- | --- | --- | --- |"])
    for row in payload["package_delta"]:
        lines.append(
            f"| `{row['action']}` | `{row['card']}` | `{', '.join(row['profile_roles']) or '-'}` | `{', '.join(row['risk_flags']) or '-'}` |"
        )
    lines.extend(["", "## Blockers", ""])
    if payload["blocker_reasons"]:
        for blocker in payload["blocker_reasons"]:
            lines.append(f"- `{blocker}`")
    else:
        lines.append("- none")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package-chain-report", type=Path, default=DEFAULT_PACKAGE_CHAIN_REPORT)
    parser.add_argument("--base-db", type=Path, default=DEFAULT_SQLITE_DB)
    parser.add_argument("--candidate-db", type=Path)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        package_chain_report=args.package_chain_report,
        base_db=args.base_db,
        candidate_db=args.candidate_db,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "summary": payload["summary"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
