#!/usr/bin/env python3
"""Synthesize whether Lorehold 607 remains the current best baseline.

This read-only report exists after the governed artifact audit. It scans the
current Lorehold evidence surface for any still-active promotion, deck
materialization, natural-gate, or matrix-ready signal. Historical positive
signals are allowed only when a later corrective artifact explicitly overrides
them.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_ARTIFACT_AUDIT = (
    REPORT_DIR / "lorehold_artifact_contract_audit_20260705_governed_learning_artifacts_current.json"
)
DEFAULT_STRATEGY_MATRIX = (
    REPORT_DIR / "lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.json"
)
DEFAULT_CUT_METHODOLOGY_REAUDIT = REPORT_DIR / "lorehold_cut_methodology_reaudit_20260629.json"
DEFAULT_SIDECAR_CUT_PLANNER = (
    REPORT_DIR / "lorehold_topdeck_sidecar_cut_model_planner_20260705_current.json"
)
DEFAULT_GAP_FLOOR_TRACE_MINER = (
    REPORT_DIR / "lorehold_gap_floor_trace_miner_20260705_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_current_best_baseline_synthesis_20260705_current"
)

POSITIVE_SIGNAL_PATHS = {
    ("decision", "ready_for_real_deck_change"),
    ("decision", "promotion_allowed"),
    ("decision", "promotion_allowed_now"),
    ("decision", "candidate_deck_materialization_allowed_now"),
    ("decision", "natural_battle_allowed_now"),
    ("decision", "natural_gate_allowed_now"),
    ("summary", "ready_for_real_deck_change"),
    ("summary", "promotion_allowed_now"),
    ("summary", "candidate_deck_materialization_allowed_now"),
    ("summary", "natural_battle_gate_allowed_now"),
    ("summary", "natural_gate_allowed_now"),
    ("summary", "matrix_candidate_row_eligible_count"),
    ("summary", "safe_cut_ready_count"),
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def as_dict(value: Any) -> dict[str, Any]:
    return dict(value) if isinstance(value, Mapping) else {}


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def get_path(payload: Mapping[str, Any], path: Iterable[str]) -> Any:
    current: Any = payload
    for key in path:
        if not isinstance(current, Mapping):
            return None
        current = current.get(key)
    return current


def positive_value(value: Any) -> bool:
    return value is True or (isinstance(value, (int, float)) and not isinstance(value, bool) and value > 0)


def matrix_summary(strategy_matrix: Mapping[str, Any]) -> dict[str, Any]:
    ranked = [str(key) for key in as_list(strategy_matrix.get("ranked_deck_keys"))]
    rank_by_key = {key: index + 1 for index, key in enumerate(ranked)}
    decks = [row for row in as_list(strategy_matrix.get("decks")) if isinstance(row, Mapping)]
    deck_by_key = {str(row.get("deck_key") or ""): dict(row) for row in decks}
    return {
        "ranked_deck_keys": ranked,
        "protected_baseline_key": "deck_607",
        "protected_baseline_rank": rank_by_key.get("deck_607"),
        "live_challenger_ranks": {
            key: rank_by_key.get(key)
            for key in ("deck_614", "deck_615")
        },
        "protected_baseline_score": as_dict(deck_by_key.get("deck_607")).get("strategy_score"),
        "top_deck_key": ranked[0] if ranked else None,
        "top_deck_is_607": bool(ranked and ranked[0] == "deck_607"),
    }


def cut_methodology_override(cut_methodology: Mapping[str, Any]) -> dict[str, Any]:
    decision = as_dict(cut_methodology.get("decision"))
    return {
        "ready_for_real_deck_change": bool(decision.get("ready_for_real_deck_change")),
        "current_candidate_status": decision.get("current_candidate_status"),
        "summary": decision.get("summary"),
        "blocked_pairs": as_list(decision.get("blocked_pairs")),
        "confirmation_pairs": as_list(decision.get("confirmation_pairs")),
        "overrides_v615_mana_engine_positive": (
            decision.get("current_candidate_status") == "battle_cleared_with_cut_methodology_caveat"
            and decision.get("ready_for_real_deck_change") is False
        ),
    }


def scan_positive_signals(
    *,
    report_dir: Path,
    cut_methodology: Mapping[str, Any],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    override = cut_methodology_override(cut_methodology)
    current: list[dict[str, Any]] = []
    overridden: list[dict[str, Any]] = []
    for path in sorted(report_dir.glob("lorehold*.json")):
        payload = read_json(path)
        if not payload:
            continue
        positive_fields = {
            ".".join(signal_path): get_path(payload, signal_path)
            for signal_path in sorted(POSITIVE_SIGNAL_PATHS)
            if positive_value(get_path(payload, signal_path))
        }
        if not positive_fields:
            continue
        row = {
            "path": rel(path),
            "artifact_type": payload.get("artifact_type") or "",
            "status": payload.get("status") or "",
            "positive_fields": positive_fields,
        }
        if (
            path.name == "lorehold_ideal_candidate_decision_audit_20260629_v615_mana_engine_v1.json"
            and override["overrides_v615_mana_engine_positive"]
        ):
            row["override_reason"] = (
                "cut_methodology_reaudit_20260629 sets ready_for_real_deck_change=false "
                "and marks the candidate battle-cleared only with methodology caveat"
            )
            overridden.append(row)
        else:
            current.append(row)
    return current, overridden


def build_report(
    *,
    artifact_audit: Mapping[str, Any],
    strategy_matrix: Mapping[str, Any],
    cut_methodology: Mapping[str, Any],
    sidecar_cut_planner: Mapping[str, Any],
    gap_floor_trace_miner: Mapping[str, Any],
    paths: Mapping[str, Path],
    report_dir: Path = REPORT_DIR,
) -> dict[str, Any]:
    artifact_summary = as_dict(artifact_audit.get("summary"))
    gate = as_dict(artifact_audit.get("continuation_gate"))
    planner_summary = as_dict(sidecar_cut_planner.get("summary"))
    floor_summary = as_dict(gap_floor_trace_miner.get("summary"))
    matrix = matrix_summary(strategy_matrix)
    cut_override = cut_methodology_override(cut_methodology)
    current_positive, overridden_positive = scan_positive_signals(
        report_dir=report_dir,
        cut_methodology=cut_methodology,
    )
    validation_errors: list[str] = []
    if gate.get("artifact_contract_status") != "pass":
        validation_errors.append("artifact contract is not pass")
    if as_int(artifact_summary.get("unknown_or_invalid_count")) != 0:
        validation_errors.append("artifact audit still has unknown or invalid artifacts")
    if not matrix["top_deck_is_607"]:
        validation_errors.append("strategy matrix does not rank deck_607 first")
    if current_positive:
        validation_errors.append("current positive promotion/materialization signals remain")
    if as_int(planner_summary.get("matrix_candidate_row_eligible_count")) != 0:
        validation_errors.append("sidecar planner has matrix-eligible rows")
    if planner_summary.get("candidate_deck_materialization_allowed_now") is True:
        validation_errors.append("sidecar planner allows candidate deck materialization")
    if planner_summary.get("promotion_allowed_now") is True:
        validation_errors.append("sidecar planner allows promotion")

    status = (
        "current_best_baseline_synthesis_keep_607"
        if not validation_errors
        else "current_best_baseline_synthesis_blocked_review_required"
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_current_best_baseline_synthesis",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": {
            "decision_status": status,
            "artifact_count": as_int(artifact_summary.get("artifact_count")),
            "unknown_or_invalid_count": as_int(artifact_summary.get("unknown_or_invalid_count")),
            "artifact_contract_status": gate.get("artifact_contract_status"),
            "artifact_contract_equal_battle_gate_allowed": bool(gate.get("can_run_equal_battle_gate")),
            "ready_for_real_deck_change_from_artifact_gate": bool(gate.get("ready_for_real_deck_change")),
            "protected_baseline_rank": matrix["protected_baseline_rank"],
            "top_deck_is_607": matrix["top_deck_is_607"],
            "current_positive_signal_count": len(current_positive),
            "overridden_historical_positive_signal_count": len(overridden_positive),
            "sidecar_matrix_candidate_row_eligible_count": as_int(
                planner_summary.get("matrix_candidate_row_eligible_count")
            ),
            "sidecar_safe_cut_ready_count": as_int(planner_summary.get("safe_cut_ready_count")),
            "sidecar_candidate_deck_materialization_allowed_now": bool(
                planner_summary.get("candidate_deck_materialization_allowed_now")
            ),
            "sidecar_promotion_allowed_now": bool(planner_summary.get("promotion_allowed_now")),
            "floor_trace_cut_blocker_count": as_int(
                planner_summary.get("floor_trace_cut_blocker_count")
                or floor_summary.get("target_with_floor_trace_count")
            ),
            "validation_error_count": len(validation_errors),
            "recommended_next_action": (
                "define_new_shell_contract_or_new_cut_evidence_before_any_battle_gate"
                if not validation_errors
                else "review_current_positive_signals_before_any_deck_action"
            ),
        },
        "matrix_summary": matrix,
        "cut_methodology_override": cut_override,
        "current_positive_signals": current_positive,
        "overridden_historical_positive_signals": overridden_positive,
        "decision": {
            "keep_607_as_current_best_baseline": not validation_errors,
            "deck_action_allowed": False,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_ready_now": False,
            "promotion_allowed": False,
            "reason": (
                "The governed artifact surface is classified, deck_607 ranks first "
                "structurally, current sidecar/cut routes have zero eligible rows, "
                "and the only positive promotion signal is historical and overridden."
            )
            if not validation_errors
            else "One or more current positive signals or contract failures require review.",
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_run_battle_without_a_materializable_candidate_contract",
                "preserve floor-trace-blocked cards until same-lane replacement preserves floor",
                "open new work only through new shell contract or new cut evidence",
            ],
        },
        "validation": {
            "status": "pass" if not validation_errors else "fail",
            "errors": validation_errors,
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = as_dict(payload.get("summary"))
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Current Best Baseline Synthesis",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload['status']}`",
        f"- Artifact contract: `{summary.get('artifact_contract_status')}`",
        f"- Unknown or invalid artifacts: `{summary.get('unknown_or_invalid_count')}`",
        f"- Strategy top deck is 607: `{str(summary.get('top_deck_is_607')).lower()}`",
        f"- Current positive signal count: `{summary.get('current_positive_signal_count')}`",
        f"- Overridden historical positive signal count: `{summary.get('overridden_historical_positive_signal_count')}`",
        f"- Sidecar matrix-eligible rows: `{summary.get('sidecar_matrix_candidate_row_eligible_count')}`",
        f"- Sidecar safe-cut ready count: `{summary.get('sidecar_safe_cut_ready_count')}`",
        f"- Floor trace cut blockers: `{summary.get('floor_trace_cut_blocker_count')}`",
        f"- Recommended next action: `{summary.get('recommended_next_action')}`",
        "",
        "## Decision",
        "",
        f"- keep_607_as_current_best_baseline: `{str(decision.get('keep_607_as_current_best_baseline')).lower()}`",
        f"- deck_action_allowed: `{str(decision.get('deck_action_allowed')).lower()}`",
        f"- candidate_deck_materialization_allowed_now: `{str(decision.get('candidate_deck_materialization_allowed_now')).lower()}`",
        f"- natural_battle_gate_ready_now: `{str(decision.get('natural_battle_gate_ready_now')).lower()}`",
        f"- promotion_allowed: `{str(decision.get('promotion_allowed')).lower()}`",
        f"- reason: {decision.get('reason')}",
        "",
        "## Historical Positive Signals Overridden",
        "",
    ]
    overridden = as_list(payload.get("overridden_historical_positive_signals"))
    if overridden:
        for row in overridden:
            lines.append(f"- `{row.get('path')}`: {row.get('override_reason')}")
    else:
        lines.append("- none")
    lines.extend(["", "## Current Positive Signals", ""])
    current = as_list(payload.get("current_positive_signals"))
    if current:
        for row in current:
            lines.append(f"- `{row.get('path')}`: `{json.dumps(row.get('positive_fields') or {}, sort_keys=True)}`")
    else:
        lines.append("- none")
    lines.extend(["", "## Source Reports", ""])
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Validation", ""])
    validation = as_dict(payload.get("validation"))
    if validation.get("errors"):
        for error in as_list(validation.get("errors")):
            lines.append(f"- ERROR: {error}")
    else:
        lines.append("- PASS: current evidence supports keeping 607 as the protected baseline.")
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
    parser.add_argument("--artifact-audit", type=Path, default=DEFAULT_ARTIFACT_AUDIT)
    parser.add_argument("--strategy-matrix", type=Path, default=DEFAULT_STRATEGY_MATRIX)
    parser.add_argument("--cut-methodology-reaudit", type=Path, default=DEFAULT_CUT_METHODOLOGY_REAUDIT)
    parser.add_argument("--sidecar-cut-planner", type=Path, default=DEFAULT_SIDECAR_CUT_PLANNER)
    parser.add_argument("--gap-floor-trace-miner", type=Path, default=DEFAULT_GAP_FLOOR_TRACE_MINER)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "artifact_audit": args.artifact_audit,
        "cut_methodology_reaudit": args.cut_methodology_reaudit,
        "gap_floor_trace_miner": args.gap_floor_trace_miner,
        "sidecar_cut_planner": args.sidecar_cut_planner,
        "strategy_matrix": args.strategy_matrix,
    }
    payload = build_report(
        artifact_audit=read_json(args.artifact_audit),
        strategy_matrix=read_json(args.strategy_matrix),
        cut_methodology=read_json(args.cut_methodology_reaudit),
        sidecar_cut_planner=read_json(args.sidecar_cut_planner),
        gap_floor_trace_miner=read_json(args.gap_floor_trace_miner),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 1 if payload["validation"]["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
