#!/usr/bin/env python3
"""Route the next Lorehold learning step after zero current topdeck safe cuts.

The safe-cut miner closed one-for-one swaps for the current topdeck targets.
This read-only router decides whether the next step is a safe-cut package gate,
a forced-access diagnostic, or a copied sidecar shell contract. It never mutates
deck 607, writes PostgreSQL/SQLite, or opens a natural battle gate.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_SAFE_CUT_MINER = REPORT_DIR / "lorehold_topdeck_safe_cut_miner_20260705_current.json"
DEFAULT_MICROBENCHMARK_PLAN = (
    REPORT_DIR / "lorehold_topdeck_forced_access_microbenchmark_plan_20260705_current.json"
)
DEFAULT_MIRACLE_SHELL_CONTRACT = (
    REPORT_DIR / "lorehold_miracle_access_first_shell_contract_20260705_current_relearn.json"
)
DEFAULT_SHELL_FAILURE = (
    REPORT_DIR / "lorehold_from_scratch_shell_failure_synthesis_20260705_current_relearn.json"
)
DEFAULT_CLOSING_ROUTER = (
    REPORT_DIR / "lorehold_closing_window_next_shell_target_router_20260705_current_relearn.json"
)
DEFAULT_HYPOTHESIS_QUEUE = (
    REPORT_DIR / "lorehold_hypothesis_queue_from_value_model_20260705_current_relearn.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_topdeck_post_safe_cut_route_20260705_current"

EXTERNAL_RESEARCH_SNAPSHOT = [
    {
        "source": "Wizards Commander format",
        "url": "https://magic.wizards.com/en/formats/commander",
        "observed_2026_07_05": {
            "deck_shape": "99 cards plus 1 commander",
            "singleton": True,
            "color_identity_required": True,
        },
        "model_use": (
            "Use as legality gate for any sidecar or candidate. Legality never "
            "overrides runtime trace, cut safety, or same-seed battle evidence."
        ),
    },
    {
        "source": "EDHREC Lorehold commander page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "observed_2026_07_05": {
            "rank": 256,
            "deck_count": 9029,
            "theme_tags": {
                "Topdeck": 485,
                "Spellslinger": 468,
                "Discard": 130,
                "Burn": 119,
            },
            "high_synergy_anchors": {
                "Library of Leng": {"inclusion_pct": 77, "synergy_pct": 75},
                "Sensei's Divining Top": {"inclusion_pct": 66, "synergy_pct": 61},
                "Approach of the Second Sun": {"inclusion_pct": 63, "synergy_pct": 61},
                "Scroll Rack": {"inclusion_pct": 58, "synergy_pct": 56},
            },
            "global_staple_signals": {
                "The One Ring": {"inclusion_pct": 8.4, "synergy_pct": 2},
                "Mana Vault": {"inclusion_pct": 5.6, "synergy_pct": 2},
            },
            "current_target_signals": {
                "Dragon's Rage Channeler": {"inclusion_pct": 39, "synergy_pct": 37},
                "Galvanoth": {"inclusion_pct": 26, "synergy_pct": 26},
            },
        },
        "model_use": (
            "Use public adoption as lane discovery. Lorehold-specific topdeck "
            "anchors outrank generic staples unless runtime proof says otherwise."
        ),
    },
    {
        "source": "EDHREC optimized topdeck Lorehold page",
        "url": "https://edhrec.com/decks/lorehold-the-historian/optimized/topdeck",
        "observed_2026_07_05": {
            "deck_count": 42,
            "theme_tags": {
                "Spellslinger": 43,
                "Topdeck": 42,
                "Combo": 12,
                "Discard": 12,
            },
        },
        "model_use": (
            "Optimized topdeck lists confirm the learning route, but the sample is "
            "small and cannot promote a ManaLoom deck without local battle gates."
        ),
    },
]

SIDECAR_SHELL_REQUIREMENTS = [
    "copy_or_lab_candidate_only; never mutate deck_607",
    "declare shell hypothesis before any 100-card materialization",
    "preserve Commander 99-plus-1, singleton, and color identity gates",
    "state adds, same-lane cuts, and protected anchors before decklist output",
    "preserve Sensei's Divining Top, Scroll Rack, Library of Leng, and Land Tax access floors",
    "preserve Bender's Waterskin and Victory Chimes unless same-lane proof beats 607",
    "preserve miracle_cast, topdeck_manipulation_activated, upkeep_rummage, and spell_volume floors",
    "show direct drawn/cast/activated trace for each added card",
    "block generic-staple upgrades until same-lane cut proof exists",
    "run forced-access only as diagnostic; never as promotion evidence",
    "run natural equal battle gate only after structure matrix and trace floors pass",
    "compare against current deck_607 on same seed and opponent matrix",
    "include Winota or fast-pressure slice before promotion",
]

BLOCKED_ROUTES = [
    {
        "route_key": "one_for_one_swap_now",
        "status": "blocked_without_seed_safe_cut",
        "reason": "The safe-cut miner found zero seed-safe cuts for the topdeck target set.",
    },
    {
        "route_key": "natural_battle_gate_now",
        "status": "blocked_before_structure_matrix",
        "reason": "A natural gate would test an undeclared structure, not a controlled deckbuilding hypothesis.",
    },
    {
        "route_key": "broad_from_scratch_rewrite",
        "status": "blocked_by_prior_shell_failures",
        "reason": "Prior broad shells did not create promotable evidence against protected 607.",
    },
    {
        "route_key": "generic_staple_upgrade",
        "status": "blocked_without_lane_and_cut_proof",
        "reason": "Mana Vault and The One Ring are hypotheses, not replacements, until they have a lane, a cut, and trace proof.",
    },
]


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


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def input_health(payloads: Mapping[str, Mapping[str, Any]]) -> dict[str, Any]:
    required = [
        "safe_cut_miner",
        "microbenchmark_plan",
        "miracle_shell_contract",
        "shell_failure_synthesis",
        "closing_window_router",
        "hypothesis_queue",
    ]
    missing = [key for key in required if not payloads.get(key)]
    return {
        "missing_inputs": missing,
        "all_required_inputs_present": not missing,
    }


def route_for_counts(
    *,
    missing_inputs: list[str],
    seed_safe_count: int,
    reviewable_count: int,
    forced_runnable_count: int,
    contract_allowed: bool,
) -> dict[str, Any]:
    if missing_inputs:
        return {
            "status": "topdeck_post_safe_cut_route_inputs_missing_keep_607",
            "selected_route": "repair_inputs_before_learning_route",
            "sidecar_shell_contract_required": False,
            "recommended_next_action": "rerun_missing_source_reports_before_deck_action",
            "reason": "Required source reports are missing, so no deckbuilding route can be trusted.",
        }
    if seed_safe_count or reviewable_count:
        return {
            "status": "topdeck_post_safe_cut_route_return_to_safe_cut_package_gate_keep_607",
            "selected_route": "safe_cut_package_gate",
            "sidecar_shell_contract_required": False,
            "recommended_next_action": "build_lab_package_manifest_from_safe_cut_then_forced_access_dry_run",
            "reason": "A same-lane cut signal exists, so the next controlled step is a package manifest, not a broad shell.",
        }
    if forced_runnable_count:
        return {
            "status": "topdeck_post_safe_cut_route_forced_access_diagnostic_only_keep_607",
            "selected_route": "forced_access_diagnostic_only_requires_cut_proof",
            "sidecar_shell_contract_required": False,
            "recommended_next_action": "attach_safe_cut_proof_before_treating_forced_access_as_executable",
            "reason": "Forced-access readiness without a safe cut is diagnostic metadata only and cannot promote a deck.",
        }
    if not contract_allowed:
        return {
            "status": "topdeck_post_safe_cut_route_shell_contract_missing_keep_607",
            "selected_route": "miracle_access_first_contract_repair",
            "sidecar_shell_contract_required": False,
            "recommended_next_action": "rerun_miracle_access_first_shell_contract",
            "reason": "The miracle/topdeck shell contract is not ready enough to route a sidecar shell.",
        }
    return {
        "status": "topdeck_post_safe_cut_route_sidecar_shell_required_keep_607",
        "selected_route": "topdeck_access_first_sidecar_shell",
        "sidecar_shell_contract_required": True,
        "recommended_next_action": "write_or_refresh_topdeck_access_first_sidecar_shell_contract_before_materialization",
        "reason": "Zero safe cuts and zero runnable forced-access commands leave a copied sidecar shell contract as the next learning step.",
    }


def build_report(
    *,
    safe_cut_miner: Mapping[str, Any],
    microbenchmark_plan: Mapping[str, Any],
    miracle_shell_contract: Mapping[str, Any],
    shell_failure_synthesis: Mapping[str, Any],
    closing_window_router: Mapping[str, Any],
    hypothesis_queue: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    payloads = {
        "safe_cut_miner": safe_cut_miner,
        "microbenchmark_plan": microbenchmark_plan,
        "miracle_shell_contract": miracle_shell_contract,
        "shell_failure_synthesis": shell_failure_synthesis,
        "closing_window_router": closing_window_router,
        "hypothesis_queue": hypothesis_queue,
    }
    health = input_health(payloads)
    safe_summary = summary(safe_cut_miner)
    micro_summary = summary(microbenchmark_plan)
    miracle_summary = summary(miracle_shell_contract)
    shell_summary = summary(shell_failure_synthesis)
    router_summary = summary(closing_window_router)
    queue_summary = summary(hypothesis_queue)
    seed_safe_count = as_int(safe_summary.get("seed_safe_cut_candidate_count"))
    reviewable_count = as_int(safe_summary.get("reviewable_same_lane_gap_count"))
    forced_runnable_count = as_int(micro_summary.get("runnable_now_count"))
    route = route_for_counts(
        missing_inputs=as_list(health.get("missing_inputs")),
        seed_safe_count=seed_safe_count,
        reviewable_count=reviewable_count,
        forced_runnable_count=forced_runnable_count,
        contract_allowed=bool(miracle_summary.get("structure_matrix_contract_allowed_now")),
    )
    allow_forced_access = (
        route["selected_route"] == "safe_cut_package_gate"
        and seed_safe_count > 0
        and forced_runnable_count > 0
    )
    summary_row = {
        "decision_status": route["status"],
        "selected_route": route["selected_route"],
        "one_for_one_cut_ready_count": seed_safe_count,
        "reviewable_same_lane_gap_count": reviewable_count,
        "forced_access_runnable_count": forced_runnable_count,
        "sidecar_shell_contract_required": bool(route["sidecar_shell_contract_required"]),
        "structure_matrix_contract_allowed_now": bool(
            miracle_summary.get("structure_matrix_contract_allowed_now")
        ),
        "structure_matrix_allowed_now": bool(miracle_summary.get("structure_matrix_allowed_now")),
        "natural_battle_gate_allowed_now": False,
        "promotion_allowed_now": False,
        "deck_action_allowed_now": False,
        "deck_607_protected": True,
        "deck_607_mutated": False,
        "from_scratch_can_run_next_battle_gate": bool(shell_summary.get("can_run_next_battle_gate")),
        "from_scratch_promotable_shell_signal_count": as_int(
            shell_summary.get("promotable_shell_signal_count")
        ),
        "closing_router_selected_status": router_summary.get("selected_status") or "",
        "hypothesis_queue_natural_gate_ready_count": as_int(queue_summary.get("natural_gate_ready_count")),
        "hypothesis_queue_gate_ready_now_count": as_int(
            queue_summary.get("gate_ready_now_count_from_preflight")
        ),
        "external_research_signal_count": len(EXTERNAL_RESEARCH_SNAPSHOT),
        "missing_inputs": as_list(health.get("missing_inputs")),
        "recommended_next_action": route["recommended_next_action"],
    }
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_topdeck_post_safe_cut_route",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": route["status"],
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "external_research_snapshot": EXTERNAL_RESEARCH_SNAPSHOT,
        "summary": summary_row,
        "route": {
            "selected_route": route["selected_route"],
            "reason": route["reason"],
            "recommended_next_action": route["recommended_next_action"],
            "blocked_routes": BLOCKED_ROUTES,
            "sidecar_shell_contract": {
                "shell_key": "topdeck_access_first_sidecar_shell",
                "materialization_allowed_now": False,
                "battle_allowed_now": False,
                "promotion_allowed_now": False,
                "purpose": (
                    "Create a copied, non-promotional lab candidate only after a "
                    "structure matrix declares how topdeck, miracle, mana, and "
                    "cut floors are preserved."
                ),
                "requirements_before_materialization": SIDECAR_SHELL_REQUIREMENTS,
                "value_lanes_to_model": [
                    "topdeck_miracle_setup",
                    "hand_to_library_control",
                    "opponent_turn_mana",
                    "spell_volume_conversion",
                    "same_lane_nonanchor_cut",
                    "fast_pressure_survival",
                ],
            },
            "global_staple_policy": {
                "Mana Vault": {
                    "current_access_status": "not_accessible_for_607_change_now",
                    "reason": (
                        "Legal Commander staple, but current 607 evidence has no "
                        "safe cut and EDHREC Lorehold synergy is low compared with "
                        "topdeck anchors."
                    ),
                    "required_proof": [
                        "early_mana_lane_gap",
                        "same_lane_nonanchor_cut",
                        "no_topdeck_floor_regression",
                        "same_seed_equal_gate_beats_607",
                    ],
                },
                "The One Ring": {
                    "current_access_status": "not_accessible_for_607_change_now",
                    "reason": (
                        "Legal colorless draw engine, but it is generic resource "
                        "density until the shell proves it improves Lorehold's "
                        "miracle/topdeck floor without slowing the commander plan."
                    ),
                    "required_proof": [
                        "draw_lane_gap",
                        "same_lane_nonanchor_cut",
                        "candidate_drawn_cast_used_trace",
                        "no_fast_pressure_regression",
                    ],
                },
            },
        },
        "source_evidence": {
            "safe_cut_summary": safe_summary,
            "microbenchmark_summary": micro_summary,
            "miracle_shell_contract_summary": miracle_summary,
            "shell_failure_summary": shell_summary,
            "closing_window_router_summary": router_summary,
            "hypothesis_queue_summary": queue_summary,
            "input_health": health,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "allow_deck_mutation_now": False,
            "allow_forced_access_execution_now": allow_forced_access,
            "allow_structure_matrix_now": bool(miracle_summary.get("structure_matrix_allowed_now")),
            "allow_natural_gate_now": False,
            "promotion_allowed": False,
            "reason": route["reason"],
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_write_postgresql_or_sqlite",
                route["recommended_next_action"],
                "keep global staples as hypotheses until lane, cut, trace, and battle proof exist",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = as_dict(payload.get("summary"))
    route = as_dict(payload.get("route"))
    decision = as_dict(payload.get("decision"))
    sidecar = as_dict(route.get("sidecar_shell_contract"))
    lines = [
        "# Lorehold Topdeck Post Safe-Cut Route",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload['status']}`",
        f"- Selected route: `{summary_row['selected_route']}`",
        f"- One-for-one cut ready count: `{summary_row['one_for_one_cut_ready_count']}`",
        f"- Reviewable same-lane gaps: `{summary_row['reviewable_same_lane_gap_count']}`",
        f"- Forced-access runnable count: `{summary_row['forced_access_runnable_count']}`",
        f"- Sidecar shell contract required: `{str(summary_row['sidecar_shell_contract_required']).lower()}`",
        f"- Natural battle gate allowed: `{str(summary_row['natural_battle_gate_allowed_now']).lower()}`",
        f"- Promotion allowed: `{str(summary_row['promotion_allowed_now']).lower()}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## External Research Snapshot", ""])
    for item in as_list(payload.get("external_research_snapshot")):
        lines.append(f"- {item['source']}: {item['url']}")
        lines.append(f"  - model_use: {item['model_use']}")
    lines.extend(["", "## Selected Route", ""])
    lines.append(f"- selected_route: `{route.get('selected_route')}`")
    lines.append(f"- reason: {route.get('reason')}")
    lines.append(f"- recommended_next_action: `{route.get('recommended_next_action')}`")
    lines.extend(["", "## Sidecar Shell Contract Requirements", ""])
    lines.append(f"- shell_key: `{sidecar.get('shell_key')}`")
    lines.append(f"- materialization_allowed_now: `{str(bool(sidecar.get('materialization_allowed_now'))).lower()}`")
    lines.append(f"- battle_allowed_now: `{str(bool(sidecar.get('battle_allowed_now'))).lower()}`")
    for item in as_list(sidecar.get("requirements_before_materialization")):
        lines.append(f"- {item}")
    lines.extend(["", "## Global Staple Policy", ""])
    for card_name, policy in sorted(as_dict(route.get("global_staple_policy")).items()):
        policy_row = as_dict(policy)
        lines.append(f"### {card_name}")
        lines.append(f"- current_access_status: `{policy_row.get('current_access_status')}`")
        lines.append(f"- reason: {policy_row.get('reason')}")
        lines.append("- required_proof:")
        for proof in as_list(policy_row.get("required_proof")):
            lines.append(f"  - `{proof}`")
    lines.extend(["", "## Blocked Routes", ""])
    for item in as_list(route.get("blocked_routes")):
        lines.append(f"- `{item.get('route_key')}` -> `{item.get('status')}`: {item.get('reason')}")
    lines.extend(["", "## Decision", ""])
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- allow_deck_mutation_now: `{str(decision['allow_deck_mutation_now']).lower()}`")
    lines.append(f"- allow_forced_access_execution_now: `{str(decision['allow_forced_access_execution_now']).lower()}`")
    lines.append(f"- allow_natural_gate_now: `{str(decision['allow_natural_gate_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    lines.append("- next_actions:")
    for action in as_list(decision.get("next_actions")):
        lines.append(f"  - {action}")
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
    parser.add_argument("--safe-cut-miner", type=Path, default=DEFAULT_SAFE_CUT_MINER)
    parser.add_argument("--microbenchmark-plan", type=Path, default=DEFAULT_MICROBENCHMARK_PLAN)
    parser.add_argument("--miracle-shell-contract", type=Path, default=DEFAULT_MIRACLE_SHELL_CONTRACT)
    parser.add_argument("--shell-failure-synthesis", type=Path, default=DEFAULT_SHELL_FAILURE)
    parser.add_argument("--closing-window-router", type=Path, default=DEFAULT_CLOSING_ROUTER)
    parser.add_argument("--hypothesis-queue", type=Path, default=DEFAULT_HYPOTHESIS_QUEUE)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "safe_cut_miner": args.safe_cut_miner,
        "microbenchmark_plan": args.microbenchmark_plan,
        "miracle_shell_contract": args.miracle_shell_contract,
        "shell_failure_synthesis": args.shell_failure_synthesis,
        "closing_window_router": args.closing_window_router,
        "hypothesis_queue": args.hypothesis_queue,
    }
    payload = build_report(
        safe_cut_miner=read_json(args.safe_cut_miner),
        microbenchmark_plan=read_json(args.microbenchmark_plan),
        miracle_shell_contract=read_json(args.miracle_shell_contract),
        shell_failure_synthesis=read_json(args.shell_failure_synthesis),
        closing_window_router=read_json(args.closing_window_router),
        hypothesis_queue=read_json(args.hypothesis_queue),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
