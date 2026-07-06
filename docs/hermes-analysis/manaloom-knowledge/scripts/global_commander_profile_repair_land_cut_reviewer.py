#!/usr/bin/env python3
"""Review land-floor nonland cuts after profile-repair pair reordering.

This read-only gate consumes the profile-repair cut-pair reorder report plus
the commander profile strategy matrix. It projects the whole repair package,
then decides whether land-floor pairs can open an isolated candidate copy. It
does not copy or mutate a deck, run battles, or promote anything.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_REORDER_REPORT = (
    REPORT_DIR / "global_commander_profile_repair_cut_pair_reorderer_20260706_lorehold_land_floor_package_profile.json"
)
DEFAULT_STRATEGY_REPORT = (
    REPORT_DIR / "global_commander_candidate_package_strategy_matrix_20260706_land_floor_deck612_package_lorehold_profile.json"
)
DEFAULT_CANDIDATE_MODEL_REPORT = (
    REPORT_DIR / "global_commander_profile_repair_candidate_model_20260706_lorehold_land_floor_package_profile.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_profile_repair_land_cut_reviewer_20260706_lorehold_land_floor_package_profile"
)

LAND_AXIS = "lands"
PROTECTED_ANCHOR_AXIS = "protected_profile_anchor"
RISK_ROLES = {
    "mana_acceleration",
    "mana_rocks_treasure_ramp",
    "spell_payoffs_copy_engines",
    "draw_rummage_opponent_turn_draw",
    "topdeck_miracle_setup",
}


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


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def as_float(value: object) -> float:
    try:
        return float(value or 0)
    except Exception:
        return 0.0


def roles(row: Mapping[str, Any], key: str) -> list[str]:
    return [str(role) for role in row.get(key) or [] if str(role or "").strip()]


def normalize_name(name: object) -> str:
    return " ".join(str(name or "").strip().lower().split())


def candidate_cut_metadata(candidate_payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows = {}
    for row in candidate_payload.get("global_cut_review_pool") or []:
        if not isinstance(row, Mapping):
            continue
        name = str(row.get("card_name") or "")
        if name:
            rows[normalize_name(name)] = dict(row)
    return rows


def protected_anchor_names(strategy_payload: Mapping[str, Any]) -> set[str]:
    names: set[str] = set()
    prefix = "protected_profile_anchor_cut:"
    for reason in strategy_payload.get("blocker_reasons") or []:
        text = str(reason)
        if text.startswith(prefix):
            names.add(normalize_name(text.removeprefix(prefix)))
    return names


def target_lookup(strategy_payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    targets = {}
    for row in strategy_payload.get("target_evaluations") or []:
        if not isinstance(row, Mapping):
            continue
        role = str(row.get("role") or "")
        if not role:
            continue
        targets[role] = {
            "min": as_int(row.get("min")),
            "max": as_int(row.get("max")),
            "hard_floor": bool(row.get("hard_floor")),
            "base_count": as_int(row.get("base_count")),
            "candidate_count": as_int(row.get("candidate_count")),
        }
    return targets


def projected_counts(
    strategy_payload: Mapping[str, Any],
    pairs: list[Mapping[str, Any]],
) -> dict[str, int]:
    counts = {
        str(role): as_int(count)
        for role, count in (strategy_payload.get("candidate_profile_role_counts") or {}).items()
    }
    for pair in pairs:
        for role in roles(pair, "add_profile_roles"):
            counts[role] = counts.get(role, 0) + 1
        for role in roles(pair, "cut_profile_roles"):
            counts[role] = counts.get(role, 0) - 1
    return dict(sorted(counts.items()))


def target_results(counts: Mapping[str, int], targets: Mapping[str, Mapping[str, Any]]) -> list[dict[str, Any]]:
    rows = []
    for role, target in sorted(targets.items()):
        projected = as_int(counts.get(role))
        minimum = as_int(target.get("min"))
        maximum = as_int(target.get("max"))
        status = "in_range"
        blockers: list[str] = []
        if minimum and projected < minimum:
            status = "below_target"
            if target.get("hard_floor"):
                blockers.append(f"projected_role_below_hard_floor:{role}")
        elif maximum and projected > maximum:
            status = "above_target_review"
        rows.append(
            {
                "role": role,
                "candidate_count": as_int(target.get("candidate_count")),
                "projected_count": projected,
                "min": minimum,
                "max": maximum,
                "status": status,
                "blockers": blockers,
            }
        )
    return rows


def package_membership(strategy_payload: Mapping[str, Any]) -> dict[str, list[str]]:
    membership: dict[str, list[str]] = {}
    for package_name, package in (strategy_payload.get("candidate_expected_package_presence") or {}).items():
        if not isinstance(package, Mapping):
            continue
        for key in ("present_cards", "missing_cards"):
            for card in package.get(key) or []:
                membership.setdefault(normalize_name(card), []).append(str(package_name))
    return membership


def package_impacts(strategy_payload: Mapping[str, Any], pairs: list[Mapping[str, Any]]) -> list[dict[str, Any]]:
    package_rows = strategy_payload.get("candidate_expected_package_presence") or {}
    rows = []
    adds = {normalize_name(pair.get("add")) for pair in pairs}
    cuts = {normalize_name(pair.get("cut")) for pair in pairs}
    for package_name, package in sorted(package_rows.items()):
        if not isinstance(package, Mapping):
            continue
        present = {normalize_name(card) for card in package.get("present_cards") or []}
        missing = {normalize_name(card) for card in package.get("missing_cards") or []}
        removed = present & cuts
        restored = missing & adds
        projected = as_int(package.get("present_count")) - len(removed) + len(restored)
        rows.append(
            {
                "package": package_name,
                "present_count": as_int(package.get("present_count")),
                "expected_count": as_int(package.get("expected_count")),
                "removed_present_cards": sorted(removed),
                "restored_missing_cards": sorted(restored),
                "projected_present_count": projected,
                "status": "package_presence_preserved_or_improved"
                if projected >= as_int(package.get("present_count"))
                else "package_presence_reduced",
            }
        )
    return rows


def primary_materialization_role(pair: Mapping[str, Any]) -> str:
    axis = str(pair.get("add_axis") or "")
    if axis == LAND_AXIS:
        return "land"
    add_roles = roles(pair, "add_profile_roles")
    return add_roles[0] if add_roles else axis


def materialization_pairs(summary: Mapping[str, Any], pairs: list[Mapping[str, Any]]) -> list[dict[str, Any]]:
    rows = []
    for pair in pairs:
        rows.append(
            {
                "deck_id": str(summary.get("deck_id") or ""),
                "commander": summary.get("commander"),
                "role": primary_materialization_role(pair),
                "add": pair.get("add"),
                "cut": pair.get("cut"),
                "pair": dict(pair),
                "candidate": {
                    "card_name": pair.get("add"),
                    "role": primary_materialization_role(pair),
                    "profile_roles": roles(pair, "add_profile_roles"),
                    "source": "profile_repair_land_cut_reviewer",
                },
                "cut_candidate": {
                    "card_name": pair.get("cut"),
                    "role": primary_materialization_role(pair),
                    "profile_roles": roles(pair, "cut_profile_roles"),
                },
                "source_pool_status": "profile_repair_land_cut_review_ready_for_candidate_copy",
            }
        )
    return rows


def land_pair_reviews(
    *,
    pairs: list[Mapping[str, Any]],
    counts: Mapping[str, int],
    targets: Mapping[str, Mapping[str, Any]],
    cut_metadata: Mapping[str, Mapping[str, Any]],
    protected_names: set[str],
    package_member: Mapping[str, list[str]],
) -> list[dict[str, Any]]:
    reviews = []
    all_add_roles = Counter(role for pair in pairs for role in roles(pair, "add_profile_roles"))
    for pair in pairs:
        if str(pair.get("add_axis") or "") != LAND_AXIS:
            continue
        cut = str(pair.get("cut") or "")
        cut_key = normalize_name(cut)
        metadata = cut_metadata.get(cut_key, {})
        cut_roles = roles(pair, "cut_profile_roles")
        blockers: list[str] = []
        warnings: list[str] = []
        reasons = ["land_floor_nonland_cut_reviewed_against_projected_package"]
        if not cut:
            blockers.append("land_floor_pair_missing_cut")
        if cut_key in protected_names:
            blockers.append(f"land_floor_cut_is_protected_anchor:{cut}")
        for role in cut_roles:
            target = targets.get(role)
            if not target:
                continue
            projected = as_int(counts.get(role))
            if target.get("hard_floor") and projected < as_int(target.get("min")):
                blockers.append(f"projected_role_below_hard_floor:{role}")
        risk_overlap = sorted(set(cut_roles) & RISK_ROLES)
        if risk_overlap:
            warnings.append("land_cut_removes_high_function_nonland_roles:" + ",".join(risk_overlap))
        package_hits = package_member.get(cut_key, [])
        if package_hits:
            package_replaced = any(all_add_roles.get(role, 0) > 0 for role in cut_roles)
            if package_replaced:
                reasons.append("package_level_role_replacement_exists")
            else:
                blockers.append("expected_package_cut_without_package_replacement:" + ",".join(package_hits))
        if as_float(metadata.get("cmc")) <= 3 and "mana_rocks_treasure_ramp" in cut_roles:
            warnings.append("low_curve_ramp_cut_requires_strategy_matrix_and_replay_after_copy")
        reviews.append(
            {
                "add": pair.get("add"),
                "cut": cut,
                "status": "land_floor_cut_role_loss_review_ready_for_candidate_copy"
                if not blockers
                else "land_floor_cut_role_loss_review_blocks_candidate_copy",
                "cut_cmc": metadata.get("cmc"),
                "cut_core_roles": metadata.get("core_roles") or [],
                "cut_profile_roles": cut_roles,
                "projected_cut_role_counts": {
                    role: as_int(counts.get(role))
                    for role in cut_roles
                    if role in targets
                },
                "reasons": reasons,
                "warnings": sorted(set(warnings)),
                "blockers": sorted(set(blockers)),
            }
        )
    return reviews


def build_report(
    *,
    cut_pair_reorder_report: Path,
    strategy_matrix_report: Path,
    candidate_model_report: Path,
) -> dict[str, Any]:
    reorder_payload = load_json(cut_pair_reorder_report)
    strategy_payload = load_json(strategy_matrix_report)
    candidate_payload = load_json(candidate_model_report)
    summary = reorder_payload.get("summary") or {}
    pairs = [dict(row) for row in reorder_payload.get("reordered_pairs") or [] if isinstance(row, Mapping)]
    targets = target_lookup(strategy_payload)
    counts = projected_counts(strategy_payload, pairs)
    target_rows = target_results(counts, targets)
    package_rows = package_impacts(strategy_payload, pairs)
    land_reviews = land_pair_reviews(
        pairs=pairs,
        counts=counts,
        targets=targets,
        cut_metadata=candidate_cut_metadata(candidate_payload),
        protected_names=protected_anchor_names(strategy_payload),
        package_member=package_membership(strategy_payload),
    )
    blockers = []
    if reorder_payload.get("status") != "profile_repair_cut_pair_reorder_ready_for_land_curve_review":
        blockers.append("cut_pair_reorder_not_ready_for_land_curve_review")
    for row in target_rows:
        blockers.extend(row.get("blockers") or [])
    for row in land_reviews:
        blockers.extend(row.get("blockers") or [])
    hard_floor_blockers = [blocker for blocker in blockers if blocker.startswith("projected_role_below_hard_floor:")]
    status = (
        "profile_repair_land_cut_review_ready_for_candidate_copy"
        if land_reviews and not blockers
        else "profile_repair_land_cut_review_blocks_candidate_copy"
    )
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_profile_repair_land_cut_reviewer",
        "source_db": str((strategy_payload.get("input_artifacts") or {}).get("candidate_db") or ""),
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "battle_replay_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": status == "profile_repair_land_cut_review_ready_for_candidate_copy",
        "input_artifacts": {
            "cut_pair_reorder_report": rel(cut_pair_reorder_report),
            "strategy_matrix_report": rel(strategy_matrix_report),
            "candidate_model_report": rel(candidate_model_report),
        },
        "summary": {
            "deck_id": str(summary.get("deck_id") or ""),
            "commander": str(summary.get("commander") or ""),
            "pair_count": len(pairs),
            "land_pair_review_count": len(land_reviews),
            "ready_land_pair_count": sum(1 for row in land_reviews if not row.get("blockers")),
            "hard_floor_blocker_count": len(hard_floor_blockers),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": (
                "materialize_profile_repair_candidate_copy"
                if status == "profile_repair_land_cut_review_ready_for_candidate_copy"
                else "expand_land_floor_cut_source_before_candidate_copy"
            ),
        },
        "land_pair_reviews": land_reviews,
        "materialization_pairs": materialization_pairs(summary, pairs),
        "projected_role_counts": counts,
        "target_results": target_rows,
        "package_impacts": package_rows,
        "candidate_copy_blockers": sorted(set(blockers)),
        "policy": {
            "land_cut_review_boundary": "This gate evaluates role loss only; it does not copy or mutate a deck.",
            "profile_package_boundary": "Projected counts use the whole reordered repair package, not isolated land pairs.",
            "battle_boundary": "Candidate copy can open for structure and strategy rerun only; battle and promotion remain closed.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Profile Repair Land Cut Reviewer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- pair_count: `{summary['pair_count']}`",
        f"- land_pair_review_count: `{summary['land_pair_review_count']}`",
        f"- ready_land_pair_count: `{summary['ready_land_pair_count']}`",
        f"- hard_floor_blocker_count: `{summary['hard_floor_blocker_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- candidate_copy_blocker_count: `{summary['candidate_copy_blocker_count']}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Land Pair Reviews",
        "",
        "| Add | Cut | Status | Projected Cut Roles | Warnings | Blockers |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for row in payload["land_pair_reviews"]:
        projected = ", ".join(f"{role}={count}" for role, count in row["projected_cut_role_counts"].items()) or "-"
        lines.append(
            f"| `{row['add']}` | `{row['cut']}` | `{row['status']}` | `{projected}` | `{', '.join(row.get('warnings') or []) or '-'}` | `{', '.join(row.get('blockers') or []) or '-'}` |"
        )
    lines.extend(["", "## Target Results", ""])
    lines.append("| Role | Candidate | Projected | Min | Max | Status | Blockers |")
    lines.append("| --- | ---: | ---: | ---: | ---: | --- | --- |")
    for row in payload["target_results"]:
        lines.append(
            f"| `{row['role']}` | `{row['candidate_count']}` | `{row['projected_count']}` | `{row['min']}` | `{row['max']}` | `{row['status']}` | `{', '.join(row.get('blockers') or []) or '-'}` |"
        )
    lines.extend(["", "## Candidate-Copy Blockers", ""])
    if payload["candidate_copy_blockers"]:
        for blocker in payload["candidate_copy_blockers"]:
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
    parser.add_argument("--cut-pair-reorder-report", type=Path, default=DEFAULT_REORDER_REPORT)
    parser.add_argument("--strategy-matrix-report", type=Path, default=DEFAULT_STRATEGY_REPORT)
    parser.add_argument("--candidate-model-report", type=Path, default=DEFAULT_CANDIDATE_MODEL_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        cut_pair_reorder_report=args.cut_pair_reorder_report,
        strategy_matrix_report=args.strategy_matrix_report,
        candidate_model_report=args.candidate_model_report,
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
