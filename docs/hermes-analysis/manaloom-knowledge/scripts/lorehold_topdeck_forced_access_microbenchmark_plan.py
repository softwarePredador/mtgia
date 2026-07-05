#!/usr/bin/env python3
"""Plan topdeck forced-access microbenchmarks without running unsafe gates.

This consumes the topdeck forced-access audit and the latest prior-aware
package preflight. The goal is to avoid a common false positive: forcing a card
that is not actually present in a copied candidate deck, or rerunning an exact
add/cut pair that already failed. The output is a read-only execution contract,
not a battle result and not a deck mutation.
"""

from __future__ import annotations

import argparse
import json
import shlex
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_FORCED_ACCESS_AUDIT = (
    REPORT_DIR / "lorehold_topdeck_forced_access_audit_20260705_current.json"
)
DEFAULT_PACKAGE_PREFLIGHT = (
    REPORT_DIR / "lorehold_607_unprotected_staple_relearn_preflight_20260704_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_topdeck_forced_access_microbenchmark_plan_20260705_current"
)

TARGET_CARDS = (
    "Penance",
    "Galvanoth",
    "Dragon's Rage Channeler",
    "Valakut Awakening // Valakut Stoneforge",
    "Wheel of Fortune",
)

CARD_SPECIFIC_TRACE_SIGNALS = {
    "Penance": [
        "candidate_card_cast_or_resolved",
        "hand_to_topdeck_activation",
        "miracle_cast_after_hand_to_top_setup",
    ],
    "Galvanoth": [
        "candidate_card_cast_or_resolved",
        "top_card_spell_cast_attempt",
        "free_or_discounted_spell_conversion",
    ],
    "Dragon's Rage Channeler": [
        "candidate_card_cast_or_resolved",
        "noncreature_spell_trigger_seen",
        "surveil_or_selection_changed_topdeck_outcome",
    ],
    "Valakut Awakening // Valakut Stoneforge": [
        "candidate_card_cast_or_modal_land_choice",
        "hand_refresh_resolved",
        "topdeck_anchor_access_after_hand_refresh",
    ],
    "Wheel of Fortune": [
        "candidate_card_cast_or_resolved",
        "mass_redraw_resolved",
        "opponent_refill_risk_observed",
    ],
}

PRIMARY_FORCED_MODE = {
    "Penance": "opening_hand",
    "Galvanoth": "opening_hand",
    "Dragon's Rage Channeler": "opening_hand",
    "Valakut Awakening // Valakut Stoneforge": "opening_hand",
    "Wheel of Fortune": "opening_hand",
}


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


def as_dict(value: Any) -> dict[str, Any]:
    return dict(value) if isinstance(value, Mapping) else {}


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def normalize_name(value: Any) -> str:
    return " ".join(str(value or "").strip().lower().replace("’", "'").split())


def audit_candidates(payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for raw in as_list(payload.get("candidates")):
        if isinstance(raw, Mapping) and raw.get("card_name"):
            rows[normalize_name(raw["card_name"])] = dict(raw)
    return rows


def packages_by_add(payload: Mapping[str, Any]) -> dict[str, list[dict[str, Any]]]:
    indexed: dict[str, list[dict[str, Any]]] = {}
    for raw in as_list(payload.get("packages")):
        if not isinstance(raw, Mapping):
            continue
        row = dict(raw)
        for card_name in as_list(row.get("adds")):
            indexed.setdefault(normalize_name(card_name), []).append(row)
    return indexed


def package_prior_rejected(package: Mapping[str, Any]) -> bool:
    decision = str(package.get("decision") or "")
    prior = as_dict(package.get("prior_evidence"))
    prior_status = str(prior.get("status") or "")
    if "prior_reject" in decision or prior_status == "blocked_prior_reject":
        return True
    for match in as_list(prior.get("matches")):
        if isinstance(match, Mapping) and str(match.get("decision") or "") in {
            "reject_or_rework",
            "tie_watch_strategy_regression",
        }:
            return True
    return False


def package_cut_safety_blocked(package: Mapping[str, Any]) -> bool:
    cut_safety = as_dict(package.get("cut_safety"))
    status = str(cut_safety.get("status") or "")
    if status.startswith("blocked"):
        return True
    if "cut_safety" in str(package.get("decision") or ""):
        return True
    return False


def compact_package(package: Mapping[str, Any]) -> dict[str, Any]:
    prior = as_dict(package.get("prior_evidence"))
    cut_safety = as_dict(package.get("cut_safety"))
    first_match = next((row for row in as_list(prior.get("matches")) if isinstance(row, Mapping)), {})
    return {
        "package_key": package.get("package_key") or "",
        "family": package.get("family") or "",
        "adds": as_list(package.get("adds")),
        "cuts": as_list(package.get("cuts")),
        "status": package.get("status") or "",
        "decision": package.get("decision") or "",
        "prior_evidence_status": prior.get("status") or "",
        "cut_safety_status": cut_safety.get("status") or "",
        "prior_delta_pp": first_match.get("delta_pp") if isinstance(first_match, Mapping) else None,
        "prior_forced_access_mode": (
            first_match.get("forced_access_mode") if isinstance(first_match, Mapping) else None
        )
        or "none",
        "prior_source_report": (
            rel(Path(str(first_match.get("source_report"))))
            if isinstance(first_match, Mapping) and first_match.get("source_report")
            else ""
        ),
    }


def classify_package_set(packages: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
    prior_reject_count = sum(1 for package in packages if package_prior_rejected(package))
    cut_blocked_count = sum(1 for package in packages if package_cut_safety_blocked(package))
    if not packages:
        return {
            "status": "blocked_no_declared_package",
            "blockers": ["missing_add_cut_package_definition"],
            "runnable_now": False,
        }
    blockers: list[str] = []
    if prior_reject_count:
        blockers.append("prior_exact_or_strategy_reject")
    if cut_blocked_count:
        blockers.append("cut_safety_blocked")
    if prior_reject_count and cut_blocked_count:
        status = "blocked_prior_reject_and_cut_safety"
    elif prior_reject_count:
        status = "blocked_prior_reject_new_cut_required"
    elif cut_blocked_count:
        status = "blocked_cut_safety_new_cut_required"
    else:
        status = "package_shape_available_requires_manifest_and_dry_run"
        blockers.append("package_manifest_required_before_execution")
    return {
        "status": status,
        "blockers": sorted(set(blockers)),
        "runnable_now": False,
        "prior_reject_count": prior_reject_count,
        "cut_safety_blocked_count": cut_blocked_count,
    }


def command_template(
    *,
    package_key: str,
    card_name: str,
    forced_mode: str,
    stem: str,
    games: int,
    opponent_limit: int,
    opponent_seed: int,
    simulation_seed: int,
) -> dict[str, Any]:
    command = [
        "python3",
        str(SCRIPT_DIR / "lorehold_synergy_package_gate.py"),
        "--packages",
        package_key or "<package_key_required>",
        "--games",
        str(max(1, games)),
        "--opponent-limit",
        str(max(1, opponent_limit)),
        "--opponent-seed",
        str(opponent_seed),
        "--simulation-seed",
        str(simulation_seed),
        "--stem",
        stem,
        "--package-file",
        "<package_manifest_with_safe_cut_required>",
        "--forced-access-mode",
        forced_mode,
    ]
    env = {
        "MANALOOM_FOCUS_ACCESS_CARDS": json.dumps([card_name], ensure_ascii=True),
        "MANALOOM_FORCE_FOCUS_ACCESS_MODE": forced_mode,
    }
    return {
        "runnable_now": False,
        "reason": "requires package manifest with a declared safe temporary cut before execution",
        "environment": env,
        "command": command,
        "command_text": " ".join(shlex.quote(part) for part in command),
    }


def microbenchmark_row(
    *,
    card_name: str,
    audit_row: Mapping[str, Any],
    packages: Sequence[Mapping[str, Any]],
    stem: str,
    games: int,
    opponent_limit: int,
    opponent_seed: int,
    simulation_seed: int,
) -> dict[str, Any]:
    compact_packages = [compact_package(package) for package in packages]
    package_status = classify_package_set(packages)
    forced_mode = PRIMARY_FORCED_MODE.get(card_name, "opening_hand")
    package_key = compact_packages[0]["package_key"] if compact_packages else ""
    design_allowed = bool(audit_row.get("diagnostic_allowed_now"))
    return {
        "card_name": card_name,
        "learning_priority_rank": audit_row.get("learning_priority_rank"),
        "design_allowed_now": design_allowed,
        "primary_forced_access_mode": forced_mode,
        "secondary_forced_access_modes": [
            {
                "mode": "library_top",
                "status": "not_primary_for_enabler_card",
                "reason": (
                    "These candidates are enablers or hand filters. Forcing them to the library top "
                    "mostly tests draw visibility, not whether the card improves the engine."
                ),
            }
        ],
        "package_execution_status": package_status["status"],
        "runnable_now": False,
        "natural_promotion_allowed": False,
        "deck_607_mutated": False,
        "blockers": sorted(
            set(as_list(package_status.get("blockers")) + as_list(audit_row.get("blockers_before_deck_action")))
        ),
        "prior_package_count": len(compact_packages),
        "prior_reject_count": int(package_status.get("prior_reject_count") or 0),
        "cut_safety_blocked_count": int(package_status.get("cut_safety_blocked_count") or 0),
        "existing_packages": compact_packages,
        "required_trace_signals": [
            "forced_focus_access_applied",
            "candidate_card_drawn_or_accessed",
            "candidate_card_cast_or_activated",
            "miracle_cast",
            "topdeck_manipulation_activated",
            "lorehold_upkeep_rummage",
            "lorehold_cost_paid",
            "same_seed_head_to_head_vs_607",
        ]
        + CARD_SPECIFIC_TRACE_SIGNALS.get(card_name, []),
        "command_template": command_template(
            package_key=package_key,
            card_name=card_name,
            forced_mode=forced_mode,
            stem=stem,
            games=games,
            opponent_limit=opponent_limit,
            opponent_seed=opponent_seed,
            simulation_seed=simulation_seed,
        ),
        "next_action": next_action_for(card_name, package_status["status"]),
    }


def next_action_for(card_name: str, status: str) -> str:
    if status == "blocked_no_declared_package":
        return "create_declared_lab_package_with_named_temp_cut_before_forced_access"
    if status == "blocked_cut_safety_new_cut_required":
        return "find_nonprotected_same_lane_cut_before_forced_access"
    if status == "blocked_prior_reject_new_cut_required":
        return "do_not_retest_prior_pair; declare_new_cut_and_failure_hypothesis"
    if status == "blocked_prior_reject_and_cut_safety":
        return "do_not_reuse_blocked_cut; create_new_same_lane_cut_model_before_diagnostic"
    if card_name in {"Valakut Awakening // Valakut Stoneforge", "Wheel of Fortune"}:
        return "only_retest_if_new_hand_filter_cut_explains_prior_miracle_collapse"
    return "prepare_package_manifest_then_run_opening_hand_forced_access_dry_run"


def status_for(rows: Sequence[Mapping[str, Any]], missing_inputs: Sequence[str]) -> str:
    if missing_inputs:
        return "topdeck_microbenchmark_plan_inputs_missing_keep_607"
    if rows and not any(row.get("runnable_now") for row in rows):
        return "topdeck_microbenchmark_plan_ready_but_no_executable_package_keep_607"
    return "topdeck_microbenchmark_plan_partial_keep_607"


def build_report(
    *,
    forced_access_audit: Mapping[str, Any],
    package_preflight: Mapping[str, Any],
    paths: Mapping[str, Path],
    target_cards: Sequence[str] = TARGET_CARDS,
    stem: str = "lorehold_topdeck_forced_access_microbenchmark_20260705_current",
    games: int = 3,
    opponent_limit: int = 8,
    opponent_seed: int = 20260629,
    simulation_seed: int = 20260705,
) -> dict[str, Any]:
    audit_by_card = audit_candidates(forced_access_audit)
    packages = packages_by_add(package_preflight)
    rows: list[dict[str, Any]] = []
    missing_inputs: list[str] = []
    for card_name in target_cards:
        audit_row = audit_by_card.get(normalize_name(card_name), {})
        if not audit_row:
            missing_inputs.append(f"forced_access_audit:{card_name}")
        rows.append(
            microbenchmark_row(
                card_name=card_name,
                audit_row=audit_row,
                packages=packages.get(normalize_name(card_name), []),
                stem=stem,
                games=games,
                opponent_limit=opponent_limit,
                opponent_seed=opponent_seed,
                simulation_seed=simulation_seed,
            )
        )
    rows.sort(key=lambda row: (int(row.get("learning_priority_rank") or 999), str(row.get("card_name") or "")))
    package_status_counts = Counter(str(row.get("package_execution_status") or "") for row in rows)
    blocker_counts = Counter(blocker for row in rows for blocker in as_list(row.get("blockers")))
    summary = {
        "target_card_count": len(target_cards),
        "microbenchmark_design_count": sum(1 for row in rows if row.get("design_allowed_now")),
        "runnable_now_count": sum(1 for row in rows if row.get("runnable_now")),
        "natural_promotion_allowed_count": sum(1 for row in rows if row.get("natural_promotion_allowed")),
        "opening_hand_mode_count": sum(1 for row in rows if row.get("primary_forced_access_mode") == "opening_hand"),
        "package_status_counts": dict(sorted(package_status_counts.items())),
        "blocker_counts": dict(sorted(blocker_counts.items())),
        "missing_inputs": sorted(set(missing_inputs)),
        "keep_607_as_protected_baseline": True,
        "deck_607_mutated": False,
        "postgres_writes": False,
        "source_db_mutated": False,
        "recommended_next_action": "mine_new_safe_cut_models_before_running_topdeck_forced_access",
    }
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_topdeck_forced_access_microbenchmark_plan",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status_for(rows, missing_inputs),
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": summary,
        "forced_access_runtime_contract": {
            "supported_modes": ["opening_hand", "library_top"],
            "primary_mode_for_current_targets": "opening_hand",
            "why_opening_hand": (
                "The five current targets are enablers or hand filters. The diagnostic must prove "
                "whether early access to the card changes miracle/topdeck execution, not merely that "
                "the card can be drawn."
            ),
            "promotion_boundary": (
                "A forced-access result can show card visibility and use, but cannot promote a deck "
                "or mutate 607 without a later natural gate."
            ),
        },
        "microbenchmarks": rows,
        "decision": {
            "allow_execution_now": any(row.get("runnable_now") for row in rows),
            "allow_deck_mutation_now": False,
            "allow_natural_gate_now": False,
            "promotion_allowed": False,
            "reason": (
                "All five topdeck targets are valid learning designs, but current package evidence "
                "is blocked by prior rejects, protected cuts, or missing safe-cut manifests. "
                "The next work is cut-model mining before running forced-access battle commands."
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = as_dict(payload.get("summary"))
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Topdeck Forced Access Microbenchmark Plan",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- target_card_count: `{summary['target_card_count']}`",
        f"- microbenchmark_design_count: `{summary['microbenchmark_design_count']}`",
        f"- runnable_now_count: `{summary['runnable_now_count']}`",
        f"- natural_promotion_allowed_count: `{summary['natural_promotion_allowed_count']}`",
        f"- recommended_next_action: `{summary['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")

    contract = as_dict(payload.get("forced_access_runtime_contract"))
    lines.extend(["", "## Runtime Contract", ""])
    lines.append(f"- supported_modes: `{', '.join(as_list(contract.get('supported_modes')))}`")
    lines.append(f"- primary_mode_for_current_targets: `{contract.get('primary_mode_for_current_targets')}`")
    lines.append(f"- why_opening_hand: {contract.get('why_opening_hand')}")
    lines.append(f"- promotion_boundary: {contract.get('promotion_boundary')}")

    lines.extend(["", "## Microbenchmarks", ""])
    lines.append("| Card | Mode | Package status | Runnable | Prior packages | Blockers | Next action |")
    lines.append("| --- | --- | --- | ---: | ---: | --- | --- |")
    for row in as_list(payload.get("microbenchmarks")):
        blockers = ", ".join(as_list(row.get("blockers"))[:5])
        lines.append(
            "| {card} | `{mode}` | `{status}` | `{runnable}` | {count} | `{blockers}` | `{next}` |".format(
                card=row.get("card_name") or "",
                mode=row.get("primary_forced_access_mode") or "",
                status=row.get("package_execution_status") or "",
                runnable=str(bool(row.get("runnable_now"))).lower(),
                count=row.get("prior_package_count") or 0,
                blockers=blockers,
                next=row.get("next_action") or "",
            )
        )

    lines.extend(["", "## Command Templates", ""])
    for row in as_list(payload.get("microbenchmarks")):
        template = as_dict(row.get("command_template"))
        lines.append(f"### {row.get('card_name')}")
        lines.append(f"- runnable_now: `{str(bool(template.get('runnable_now'))).lower()}`")
        lines.append(f"- reason: {template.get('reason')}")
        lines.append("```bash")
        env = as_dict(template.get("environment"))
        env_prefix = " ".join(f"{key}={shlex.quote(str(value))}" for key, value in sorted(env.items()))
        lines.append(f"{env_prefix} {template.get('command_text') or ''}".strip())
        lines.append("```")

    lines.extend(["", "## Decision", ""])
    lines.append(f"- allow_execution_now: `{str(decision['allow_execution_now']).lower()}`")
    lines.append(f"- allow_deck_mutation_now: `{str(decision['allow_deck_mutation_now']).lower()}`")
    lines.append(f"- allow_natural_gate_now: `{str(decision['allow_natural_gate_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    return "\n".join(lines).rstrip() + "\n"


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
    parser.add_argument("--forced-access-audit", type=Path, default=DEFAULT_FORCED_ACCESS_AUDIT)
    parser.add_argument("--package-preflight", type=Path, default=DEFAULT_PACKAGE_PREFLIGHT)
    parser.add_argument("--cards", default=",".join(TARGET_CARDS))
    parser.add_argument("--stem", default="lorehold_topdeck_forced_access_microbenchmark_20260705_current")
    parser.add_argument("--games", type=int, default=3)
    parser.add_argument("--opponent-limit", type=int, default=8)
    parser.add_argument("--opponent-seed", type=int, default=20260629)
    parser.add_argument("--simulation-seed", type=int, default=20260705)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    cards = [card.strip() for card in str(args.cards).split(",") if card.strip()]
    paths = {
        "forced_access_audit": args.forced_access_audit,
        "package_preflight": args.package_preflight,
    }
    payload = build_report(
        forced_access_audit=read_json(args.forced_access_audit),
        package_preflight=read_json(args.package_preflight),
        paths=paths,
        target_cards=cards,
        stem=args.stem,
        games=args.games,
        opponent_limit=args.opponent_limit,
        opponent_seed=args.opponent_seed,
        simulation_seed=args.simulation_seed,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
