#!/usr/bin/env python3
"""Route Lorehold learning after sidecar probe and mana routes closed.

This read-only report consolidates the current frontier after the topdeck
sidecar probe miner, candidate queue, mana-base integrator, and from-scratch
shell synthesis. It is not a deck generator and it never opens a battle gate.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_PROBE_EVIDENCE = (
    REPORT_DIR / "lorehold_topdeck_sidecar_probe_evidence_miner_20260705_current.json"
)
DEFAULT_CANDIDATE_QUEUE = (
    REPORT_DIR / "lorehold_topdeck_sidecar_candidate_queue_20260705_current.json"
)
DEFAULT_HYPOTHESIS_QUEUE = (
    REPORT_DIR / "lorehold_hypothesis_queue_from_value_model_20260705_current_relearn.json"
)
DEFAULT_SHELL_FAILURE = (
    REPORT_DIR / "lorehold_from_scratch_shell_failure_synthesis_20260705_current_relearn.json"
)
DEFAULT_POST_SAFE_CUT_ROUTE = (
    REPORT_DIR / "lorehold_topdeck_post_safe_cut_route_20260705_current.json"
)
DEFAULT_MANA_DECISION_INTEGRATOR = (
    REPORT_DIR / "lorehold_mana_base_decision_integrator_20260705_after_plateau_turbulent_current.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_learning_frontier_after_probe_closure_20260705_current"


REQUIRED_INPUT_KEYS = [
    "probe_evidence",
    "candidate_queue",
    "hypothesis_queue",
    "shell_failure_synthesis",
    "post_safe_cut_route",
    "mana_decision_integrator",
]

FLOOR_TRACE_TARGET_ORDER = [
    "Penance",
    "Galvanoth",
    "Dragon's Rage Channeler",
    "Valakut Awakening // Valakut Stoneforge",
    "Wheel of Fortune",
]

EXTERNAL_LEARNING_REFRESH = [
    {
        "source": "Scryfall Lorehold, the Historian",
        "url": "https://scryfall.com/card/sos/201/lorehold-the-historian",
        "learning_use": "Oracle and ruling source for the commander's miracle/topdeck timing.",
        "guardrail": "Oracle/ruling data validates behavior, not a replacement decklist.",
    },
    {
        "source": "EDHREC Lorehold commander pages",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "learning_use": "Public topdeck, spellslinger, discard, and combo lanes for candidate discovery.",
        "guardrail": "Commander adoption is source evidence, not same-lane cut proof.",
    },
    {
        "source": "Commander Spellbook Storm-Kiln Artist + Haze of Rage",
        "url": "https://commanderspellbook.com/combo/3940-5195/",
        "learning_use": "Combo package discovery for future Storm-Kiln pressure/conversion research.",
        "guardrail": "Combo existence does not bypass runtime, cut, matrix, or battle gates.",
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


def missing_inputs(payloads: Mapping[str, Mapping[str, Any]]) -> list[str]:
    return [key for key in REQUIRED_INPUT_KEYS if not payloads.get(key)]


def candidate_names_for_sidecar_tag(
    candidate_queue: Mapping[str, Any], sidecar_tag: str, limit: int = 8
) -> list[str]:
    names: list[str] = []
    for row in as_list(candidate_queue.get("candidate_queue")):
        if not isinstance(row, Mapping):
            continue
        if row.get("sidecar_tag") != sidecar_tag:
            continue
        add_card = str(row.get("add_card") or "")
        if add_card and add_card not in names:
            names.append(add_card)
    return names[:limit]


def topdeck_floor_trace_targets(candidate_queue: Mapping[str, Any]) -> list[str]:
    names = candidate_names_for_sidecar_tag(candidate_queue, "topdeck_access_sidecar_primary")
    ordered = [name for name in FLOOR_TRACE_TARGET_ORDER if name in names]
    ordered.extend(name for name in names if name not in ordered)
    return ordered[:8]


def route_frontiers(
    *,
    probe_summary: Mapping[str, Any],
    queue_summary: Mapping[str, Any],
    hypothesis_summary: Mapping[str, Any],
    shell_summary: Mapping[str, Any],
    post_safe_summary: Mapping[str, Any],
    mana_summary: Mapping[str, Any],
    floor_trace_targets: list[str],
    pressure_targets: list[str],
    spell_chain_targets: list[str],
) -> list[dict[str, Any]]:
    mana_eligible = as_int(mana_summary.get("eligible_model_ready_pair_count")) or as_int(
        probe_summary.get("mana_model_eligible_pair_count")
    )
    matrix_rows = as_int(queue_summary.get("matrix_candidate_row_eligible_count")) or as_int(
        probe_summary.get("matrix_candidate_row_eligible_count")
    )
    natural_ready = as_int(hypothesis_summary.get("natural_gate_ready_count"))
    seed_safe = as_int(queue_summary.get("safe_cut_seed_ready_count")) or as_int(
        probe_summary.get("safe_cut_ready_count")
    )
    force_ready = bool(post_safe_summary.get("forced_access_runnable_count"))
    shell_can_battle = bool(shell_summary.get("can_run_next_battle_gate"))
    shell_promotable = as_int(shell_summary.get("promotable_shell_signal_count"))

    return [
        {
            "frontier_key": "mana_base_pair_frontier",
            "status": "preflight_available" if mana_eligible else "closed_by_exact_pair_decisions",
            "allowed_now": bool(mana_eligible),
            "deck_action_allowed_now": False,
            "natural_battle_allowed_now": False,
            "reason": (
                "A mana-base pair is eligible after prior-decision filtering."
                if mana_eligible
                else "The dedicated mana-base integrator has zero eligible pairs after exact Plateau decisions."
            ),
            "evidence": {
                "eligible_model_ready_pair_count": mana_eligible,
                "exact_rejected_pair_count": as_int(mana_summary.get("exact_rejected_pair_count"))
                or as_int(probe_summary.get("mana_model_exact_rejected_pair_count")),
            },
        },
        {
            "frontier_key": "topdeck_sidecar_matrix_rows",
            "status": "matrix_review_available" if matrix_rows else "closed_no_matrix_rows",
            "allowed_now": bool(matrix_rows),
            "deck_action_allowed_now": False,
            "natural_battle_allowed_now": False,
            "reason": (
                "At least one sidecar row can move to structure review."
                if matrix_rows
                else "The sidecar queue has no row eligible for matrix scoring or materialization."
            ),
            "evidence": {
                "matrix_candidate_row_eligible_count": matrix_rows,
                "queue_row_count": as_int(queue_summary.get("queue_row_count")),
            },
        },
        {
            "frontier_key": "one_for_one_safe_cut_frontier",
            "status": "preflight_available" if seed_safe else "closed_zero_seed_safe_cuts",
            "allowed_now": bool(seed_safe),
            "deck_action_allowed_now": False,
            "natural_battle_allowed_now": False,
            "reason": (
                "A seed-safe cut exists and should be moved to package preflight."
                if seed_safe
                else "The current 607 one-for-one frontier has zero seed-safe cuts."
            ),
            "evidence": {
                "safe_cut_seed_ready_count": seed_safe,
                "safe_cut_reviewable_count": as_int(queue_summary.get("safe_cut_reviewable_count")),
            },
        },
        {
            "frontier_key": "natural_gate_watchlist",
            "status": "blocked_no_current_natural_gate",
            "allowed_now": bool(natural_ready),
            "deck_action_allowed_now": False,
            "natural_battle_allowed_now": bool(natural_ready),
            "reason": (
                "A hypothesis queue reports a natural gate-ready package."
                if natural_ready
                else "The hypothesis queue reports zero current natural-gate-ready packages."
            ),
            "evidence": {
                "natural_gate_ready_count": natural_ready,
                "status_counts": hypothesis_summary.get("status_counts") or {},
            },
        },
        {
            "frontier_key": "forced_access_diagnostic_frontier",
            "status": "blocked_without_safe_cut" if force_ready else "closed_no_runnable_forced_access",
            "allowed_now": False,
            "deck_action_allowed_now": False,
            "natural_battle_allowed_now": False,
            "reason": (
                "Forced access cannot run as a deck-change proof without a cut and trace contract."
                if force_ready
                else "The post-safe-cut route has no runnable forced-access command now."
            ),
            "evidence": {
                "forced_access_runnable_count": as_int(post_safe_summary.get("forced_access_runnable_count")),
                "sidecar_shell_contract_required": bool(
                    post_safe_summary.get("sidecar_shell_contract_required")
                ),
            },
        },
        {
            "frontier_key": "from_scratch_shell_frontier",
            "status": "blocked_prior_shell_failures",
            "allowed_now": bool(shell_can_battle and shell_promotable),
            "deck_action_allowed_now": False,
            "natural_battle_allowed_now": False,
            "reason": (
                "Prior from-scratch shells are rejected or non-promotable; a new shell needs a declared trace target."
            ),
            "evidence": {
                "can_run_next_battle_gate": shell_can_battle,
                "promotable_shell_signal_count": shell_promotable,
                "best_natural_delta_wins": shell_summary.get("best_natural_delta_wins"),
                "best_forced_delta_wins": shell_summary.get("best_forced_delta_wins"),
            },
        },
        {
            "frontier_key": "generic_staple_frontier",
            "status": "closed_until_same_lane_cut_and_trace_proof",
            "allowed_now": False,
            "deck_action_allowed_now": False,
            "natural_battle_allowed_now": False,
            "reason": "Mana Vault and The One Ring remain hypotheses, not accessible deck changes for 607.",
            "evidence": {
                "required_proof": [
                    "same-lane nonanchor cut",
                    "candidate card drawn/cast/used trace",
                    "no miracle/topdeck floor regression",
                    "same-opponent same-seed gate ties or beats 607",
                ],
            },
        },
        {
            "frontier_key": "topdeck_floor_trace_target_contract",
            "status": "learning_only_next",
            "allowed_now": bool(floor_trace_targets),
            "deck_action_allowed_now": False,
            "natural_battle_allowed_now": False,
            "reason": (
                "The next valid learning step is to define trace-floor targets for topdeck cards before any matrix row."
            ),
            "evidence": {
                "target_cards": floor_trace_targets,
                "pressure_followups_after_floor": pressure_targets,
                "spell_chain_followups_after_floor": spell_chain_targets,
            },
        },
    ]


def select_next_route(
    frontiers: list[Mapping[str, Any]], missing: list[str]
) -> tuple[str | None, str, str]:
    if missing:
        return (
            "repair_missing_inputs_before_learning_route",
            "learning_frontier_inputs_missing_keep_607",
            "rerun_missing_source_reports_before_deck_action",
        )
    for key, status, action in [
        (
            "mana_base_pair_frontier",
            "learning_frontier_mana_preflight_available_keep_607",
            "run_mana_base_candidate_preflight_without_mutating_607",
        ),
        (
            "topdeck_sidecar_matrix_rows",
            "learning_frontier_matrix_review_available_keep_607",
            "review_matrix_candidate_rows_before_any_materialization",
        ),
        (
            "one_for_one_safe_cut_frontier",
            "learning_frontier_safe_cut_preflight_available_keep_607",
            "build_package_manifest_from_seed_safe_cut",
        ),
        (
            "natural_gate_watchlist",
            "learning_frontier_natural_gate_watchlist_keep_607",
            "preflight_natural_gate_candidate_before_battle",
        ),
    ]:
        row = next((item for item in frontiers if item.get("frontier_key") == key), {})
        if row.get("allowed_now"):
            return (str(row.get("frontier_key")), status, action)
    learning_row = next(
        (item for item in frontiers if item.get("frontier_key") == "topdeck_floor_trace_target_contract"),
        {},
    )
    if learning_row.get("allowed_now"):
        return (
            "topdeck_floor_trace_target_contract",
            "learning_frontier_closed_execution_routes_keep_607",
            "write_topdeck_floor_trace_target_contract_before_any_matrix_row",
        )
    return (
        None,
        "learning_frontier_no_allowed_route_keep_607",
        "collect_new_external_or_trace_evidence_before_deck_action",
    )


def build_report(
    *,
    probe_evidence: Mapping[str, Any],
    candidate_queue: Mapping[str, Any],
    hypothesis_queue: Mapping[str, Any],
    shell_failure_synthesis: Mapping[str, Any],
    post_safe_cut_route: Mapping[str, Any],
    mana_decision_integrator: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    payloads = {
        "probe_evidence": probe_evidence,
        "candidate_queue": candidate_queue,
        "hypothesis_queue": hypothesis_queue,
        "shell_failure_synthesis": shell_failure_synthesis,
        "post_safe_cut_route": post_safe_cut_route,
        "mana_decision_integrator": mana_decision_integrator,
    }
    missing = missing_inputs(payloads)
    probe_summary = summary(probe_evidence)
    queue_summary = summary(candidate_queue)
    hypothesis_summary = summary(hypothesis_queue)
    shell_summary = summary(shell_failure_synthesis)
    post_safe_summary = summary(post_safe_cut_route)
    mana_summary = summary(mana_decision_integrator)
    floor_targets = topdeck_floor_trace_targets(candidate_queue)
    pressure_targets = candidate_names_for_sidecar_tag(candidate_queue, "pressure_window_after_topdeck_floor")
    spell_targets = candidate_names_for_sidecar_tag(candidate_queue, "spell_chain_after_miracle_floor")
    frontiers = route_frontiers(
        probe_summary=probe_summary,
        queue_summary=queue_summary,
        hypothesis_summary=hypothesis_summary,
        shell_summary=shell_summary,
        post_safe_summary=post_safe_summary,
        mana_summary=mana_summary,
        floor_trace_targets=floor_targets,
        pressure_targets=pressure_targets,
        spell_chain_targets=spell_targets,
    )
    selected_route, status, next_action = select_next_route(frontiers, missing)
    execution_ready_keys = [
        str(row.get("frontier_key"))
        for row in frontiers
        if row.get("allowed_now") and row.get("deck_action_allowed_now")
    ]
    natural_ready_keys = [
        str(row.get("frontier_key"))
        for row in frontiers
        if row.get("natural_battle_allowed_now")
    ]
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_learning_frontier_after_probe_closure",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "external_learning_refresh": EXTERNAL_LEARNING_REFRESH,
        "summary": {
            "decision_status": status,
            "selected_next_route": selected_route,
            "recommended_next_action": next_action,
            "recommended_next_artifact": (
                "lorehold_topdeck_floor_trace_target_contract"
                if selected_route == "topdeck_floor_trace_target_contract"
                else selected_route
            ),
            "missing_inputs": missing,
            "deck_607_protected": True,
            "deck_action_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "structure_matrix_scoring_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_gate_allowed_now": bool(natural_ready_keys),
            "promotion_allowed_now": False,
            "execution_ready_route_count": len(execution_ready_keys),
            "natural_ready_route_count": len(natural_ready_keys),
            "probe_row_count": as_int(probe_summary.get("probe_row_count")),
            "queue_row_count": as_int(queue_summary.get("queue_row_count")),
            "matrix_candidate_row_eligible_count": as_int(
                queue_summary.get("matrix_candidate_row_eligible_count")
            )
            or as_int(probe_summary.get("matrix_candidate_row_eligible_count")),
            "safe_cut_ready_count": as_int(probe_summary.get("safe_cut_ready_count"))
            or as_int(queue_summary.get("safe_cut_seed_ready_count")),
            "mana_eligible_pair_count": as_int(mana_summary.get("eligible_model_ready_pair_count"))
            or as_int(probe_summary.get("mana_model_eligible_pair_count")),
            "hypothesis_natural_gate_ready_count": as_int(
                hypothesis_summary.get("natural_gate_ready_count")
            ),
            "from_scratch_can_run_next_battle_gate": bool(
                shell_summary.get("can_run_next_battle_gate")
            ),
            "topdeck_floor_trace_target_count": len(floor_targets),
            "pressure_followup_target_count": len(pressure_targets),
            "spell_chain_followup_target_count": len(spell_targets),
        },
        "learning_frontiers": frontiers,
        "source_evidence": {
            "probe_evidence_summary": probe_summary,
            "candidate_queue_summary": queue_summary,
            "hypothesis_queue_summary": hypothesis_summary,
            "shell_failure_summary": shell_summary,
            "post_safe_cut_route_summary": post_safe_summary,
            "mana_decision_integrator_summary": mana_summary,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "allow_deck_mutation_now": False,
            "allow_candidate_materialization_now": False,
            "allow_structure_matrix_now": False,
            "allow_forced_access_now": False,
            "allow_natural_battle_gate_now": bool(natural_ready_keys),
            "promotion_allowed": False,
            "selected_next_route": selected_route,
            "reason": (
                "Current execution frontiers are closed: no safe cut, no matrix row, "
                "no eligible mana pair, no runnable natural gate, and no promotable "
                "from-scratch shell. The next valid work is learning-only trace "
                "targeting before any deck action."
                if not missing
                else "At least one required source report is missing."
            ),
            "blocked_actions": [
                "do_not_mutate_deck_607",
                "do_not_write_postgresql_or_sqlite",
                "do_not_materialize_sidecar_deck_from_watchlist_only",
                "do_not_retest_exact_plateau_pairs_without_new_mana_evidence",
                "do_not_promote_mana_vault_or_the_one_ring_without_same_lane_trace_proof",
            ],
            "next_actions": [
                next_action,
                "define floor trace metrics for the selected topdeck target cards",
                "route pressure and spell-chain followups only after the topdeck floor is preserved",
                "refresh external sources as candidate discovery only, not promotion proof",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = as_dict(payload.get("summary"))
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Learning Frontier After Probe Closure",
        "",
        f"- Generated at: `{payload.get('generated_at')}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload.get('status')}`",
        f"- Selected next route: `{summary_row.get('selected_next_route')}`",
        f"- Recommended next action: `{summary_row.get('recommended_next_action')}`",
        f"- Candidate materialization allowed: `{str(summary_row.get('candidate_deck_materialization_allowed_now')).lower()}`",
        f"- Natural battle gate allowed: `{str(summary_row.get('natural_battle_gate_allowed_now')).lower()}`",
        f"- Promotion allowed: `{str(summary_row.get('promotion_allowed_now')).lower()}`",
        f"- Probe rows: `{summary_row.get('probe_row_count')}`",
        f"- Queue rows: `{summary_row.get('queue_row_count')}`",
        f"- Matrix-eligible rows: `{summary_row.get('matrix_candidate_row_eligible_count')}`",
        f"- Safe-cut ready: `{summary_row.get('safe_cut_ready_count')}`",
        f"- Mana eligible pairs: `{summary_row.get('mana_eligible_pair_count')}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Learning Frontiers", ""])
    lines.extend(
        [
            "| Frontier | Status | Allowed | Natural Battle | Reason |",
            "| --- | --- | --- | --- | --- |",
        ]
    )
    for row in as_list(payload.get("learning_frontiers")):
        if not isinstance(row, Mapping):
            continue
        lines.append(
            "| `{frontier}` | `{status}` | `{allowed}` | `{battle}` | {reason} |".format(
                frontier=row.get("frontier_key"),
                status=row.get("status"),
                allowed=str(bool(row.get("allowed_now"))).lower(),
                battle=str(bool(row.get("natural_battle_allowed_now"))).lower(),
                reason=row.get("reason"),
            )
        )
    lines.extend(["", "## External Learning Refresh", ""])
    for item in as_list(payload.get("external_learning_refresh")):
        if not isinstance(item, Mapping):
            continue
        lines.append(f"- `{item.get('source')}`: {item.get('url')}")
        lines.append(f"  - learning_use: {item.get('learning_use')}")
        lines.append(f"  - guardrail: {item.get('guardrail')}")
    lines.extend(["", "## Decision", ""])
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision.get('keep_607_as_protected_baseline')).lower()}`")
    lines.append(f"- allow_deck_mutation_now: `{str(decision.get('allow_deck_mutation_now')).lower()}`")
    lines.append(f"- allow_candidate_materialization_now: `{str(decision.get('allow_candidate_materialization_now')).lower()}`")
    lines.append(f"- allow_structure_matrix_now: `{str(decision.get('allow_structure_matrix_now')).lower()}`")
    lines.append(f"- allow_forced_access_now: `{str(decision.get('allow_forced_access_now')).lower()}`")
    lines.append(f"- allow_natural_battle_gate_now: `{str(decision.get('allow_natural_battle_gate_now')).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision.get('promotion_allowed')).lower()}`")
    lines.append(f"- reason: {decision.get('reason')}")
    lines.append("- blocked_actions:")
    for action in as_list(decision.get("blocked_actions")):
        lines.append(f"  - `{action}`")
    lines.append("- next_actions:")
    for action in as_list(decision.get("next_actions")):
        lines.append(f"  - `{action}`")
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
    parser.add_argument("--probe-evidence", type=Path, default=DEFAULT_PROBE_EVIDENCE)
    parser.add_argument("--candidate-queue", type=Path, default=DEFAULT_CANDIDATE_QUEUE)
    parser.add_argument("--hypothesis-queue", type=Path, default=DEFAULT_HYPOTHESIS_QUEUE)
    parser.add_argument("--shell-failure-synthesis", type=Path, default=DEFAULT_SHELL_FAILURE)
    parser.add_argument("--post-safe-cut-route", type=Path, default=DEFAULT_POST_SAFE_CUT_ROUTE)
    parser.add_argument("--mana-decision-integrator", type=Path, default=DEFAULT_MANA_DECISION_INTEGRATOR)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "probe_evidence": args.probe_evidence,
        "candidate_queue": args.candidate_queue,
        "hypothesis_queue": args.hypothesis_queue,
        "shell_failure_synthesis": args.shell_failure_synthesis,
        "post_safe_cut_route": args.post_safe_cut_route,
        "mana_decision_integrator": args.mana_decision_integrator,
    }
    payload = build_report(
        probe_evidence=read_json(args.probe_evidence),
        candidate_queue=read_json(args.candidate_queue),
        hypothesis_queue=read_json(args.hypothesis_queue),
        shell_failure_synthesis=read_json(args.shell_failure_synthesis),
        post_safe_cut_route=read_json(args.post_safe_cut_route),
        mana_decision_integrator=read_json(args.mana_decision_integrator),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "selected_next_route": payload["summary"]["selected_next_route"],
                "json": rel(json_path),
                "markdown": rel(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
