#!/usr/bin/env python3
"""Integrate tested mana-base decisions back into the Lorehold learning queue.

The safe-cut model ranks structural mana-base hypotheses. This integrator adds
the next learning layer: exact tested swaps that failed battle gates are removed
from the active materialization queue, while untested same-card hypotheses stay
explicitly diagnostic rather than inferred as good or bad.
"""

from __future__ import annotations

import argparse
import json
import re
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_SAFE_CUT_MODEL = REPORT_DIR / "lorehold_mana_base_safe_cut_model_20260705_current.json"
DEFAULT_DECISION_REPORTS = (
    REPORT_DIR / "lorehold_mana_base_plateau_radiant_decision_20260705_current.json",
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_mana_base_decision_integrator_20260705_after_plateau_radiant_current"

REJECT_STATUSES = {
    "reject_promotion_keep_607_current_baseline",
    "rejected",
    "reject",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def normalize_name(name: object) -> str:
    return " ".join(str(name or "").lower().replace("\u2019", "'").split())


def parse_candidate_pair(value: object) -> tuple[str, str] | None:
    text = str(value or "").strip()
    match = re.search(r"\+(.+?)\s*/\s*-(.+)$", text)
    if not match:
        return None
    return match.group(1).strip(), match.group(2).strip()


def decision_pair(payload: Mapping[str, Any]) -> tuple[str, str] | None:
    summary = payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {}
    decision = payload.get("decision") if isinstance(payload.get("decision"), Mapping) else {}
    for source in (
        summary.get("candidate"),
        decision.get("candidate"),
        f"+{summary.get('add')} / -{summary.get('cut')}" if summary.get("add") and summary.get("cut") else "",
    ):
        parsed = parse_candidate_pair(source)
        if parsed:
            return parsed
    return None


def load_decisions(paths: list[Path]) -> list[dict[str, Any]]:
    decisions: list[dict[str, Any]] = []
    for path in paths:
        if not path.exists():
            decisions.append(
                {
                    "path": rel(path),
                    "status": "missing_decision_report",
                    "add": None,
                    "cut": None,
                    "promotion_allowed": False,
                    "summary": {},
                }
            )
            continue
        payload = read_json(path)
        pair = decision_pair(payload)
        summary = payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {}
        decisions.append(
            {
                "path": rel(path),
                "status": str(payload.get("status") or ""),
                "add": pair[0] if pair else None,
                "cut": pair[1] if pair else None,
                "promotion_allowed": bool(summary.get("promotion_allowed")),
                "full_confirmation_allowed_now": bool(summary.get("full_confirmation_allowed_now")),
                "blockers": list(summary.get("blockers") or []),
                "summary": dict(summary),
            }
        )
    return decisions


def decision_lookup(decisions: list[dict[str, Any]]) -> dict[tuple[str, str], dict[str, Any]]:
    out: dict[tuple[str, str], dict[str, Any]] = {}
    for row in decisions:
        add = row.get("add")
        cut = row.get("cut")
        if not add or not cut:
            continue
        out[(normalize_name(add), normalize_name(cut))] = row
    return out


def current_land_oracle_by_name(safe_model: Mapping[str, Any]) -> dict[str, str]:
    return {
        normalize_name(row.get("card_name")): str(row.get("oracle_text") or "")
        for row in safe_model.get("current_lands") or []
        if isinstance(row, Mapping)
    }


def annotate_pairs(safe_model: Mapping[str, Any], decisions: list[dict[str, Any]]) -> list[dict[str, Any]]:
    lookup = decision_lookup(decisions)
    oracle_by_name = current_land_oracle_by_name(safe_model)
    annotated: list[dict[str, Any]] = []
    for raw in safe_model.get("top_model_ready_pairs") or []:
        if not isinstance(raw, Mapping):
            continue
        row = dict(raw)
        key = (normalize_name(row.get("add")), normalize_name(row.get("cut")))
        decision = lookup.get(key)
        if decision:
            row["learning_status"] = "blocked_exact_tested_decision"
            row["decision_status"] = decision.get("status")
            row["decision_report"] = decision.get("path")
            row["decision_blockers"] = decision.get("blockers") or []
            row["next_action"] = "do_not_retest_exact_pair_without_new_mana_trace_evidence"
        else:
            same_add_rejections = [
                item
                for item in decisions
                if item.get("add") and normalize_name(item.get("add")) == key[0] and item.get("status") in REJECT_STATUSES
            ]
            row["learning_status"] = "eligible_for_materialization_after_prior_decision_filter"
            row["decision_status"] = None
            row["decision_report"] = None
            row["decision_blockers"] = []
            row["same_added_card_prior_rejects"] = [
                {
                    "cut": item.get("cut"),
                    "status": item.get("status"),
                    "report": item.get("path"),
                    "blockers": item.get("blockers") or [],
                }
                for item in same_add_rejections
            ]
            row["cut_oracle_text"] = oracle_by_name.get(key[1], "")
            row["next_action"] = (
                "materialize_only_if_cut_condition_is_materially_different_from_rejected_pair"
                if same_add_rejections
                else "materialize_as_next_diagnostic_candidate"
            )
        annotated.append(row)
    return annotated


def build_payload(
    *,
    safe_cut_model_path: Path = DEFAULT_SAFE_CUT_MODEL,
    decision_report_paths: list[Path] | None = None,
) -> dict[str, Any]:
    safe_model = read_json(safe_cut_model_path)
    decision_paths = decision_report_paths or list(DEFAULT_DECISION_REPORTS)
    decisions = load_decisions(decision_paths)
    annotated_pairs = annotate_pairs(safe_model, decisions)
    rejected_pairs = [
        row for row in annotated_pairs if row.get("learning_status") == "blocked_exact_tested_decision"
    ]
    eligible_pairs = [
        row
        for row in annotated_pairs
        if row.get("learning_status") == "eligible_for_materialization_after_prior_decision_filter"
    ]
    best_next_pair = eligible_pairs[0] if eligible_pairs else None
    status = (
        "mana_base_next_diagnostic_pair_available"
        if best_next_pair
        else "mana_base_model_ready_queue_exhausted_by_decisions"
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_mana_base_decision_integrator",
        "status": status,
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": [rel(safe_cut_model_path), *[rel(path) for path in decision_paths]],
        "summary": {
            "safe_model_ready_pair_count": len(safe_model.get("top_model_ready_pairs") or []),
            "loaded_decision_count": len(decisions),
            "exact_rejected_pair_count": len(rejected_pairs),
            "eligible_model_ready_pair_count": len(eligible_pairs),
            "promotion_allowed": False,
            "allow_natural_gate_now": False,
            "keep_607_as_protected_baseline": True,
        },
        "decisions_loaded": decisions,
        "annotated_model_ready_pairs": annotated_pairs,
        "best_next_pair": best_next_pair,
        "decision": {
            "current_best_baseline": "deck_607",
            "promotion_allowed": False,
            "reason": (
                "Tested mana-base pairs must be fed back into the safe-cut model. "
                "An exact rejected pair is blocked, but a different land with a different ETB condition "
                "is not inferred as accepted or rejected until it gets its own materialization and gate."
            ),
            "next_action": (
                "materialize_best_next_mana_base_pair_as_diagnostic"
                if best_next_pair
                else "leave_mana_base_queue_closed_until_new_evidence"
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Mana Base Decision Integrator",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- safe_model_ready_pair_count: `{summary['safe_model_ready_pair_count']}`",
        f"- exact_rejected_pair_count: `{summary['exact_rejected_pair_count']}`",
        f"- eligible_model_ready_pair_count: `{summary['eligible_model_ready_pair_count']}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        f"- allow_natural_gate_now: `{str(summary['allow_natural_gate_now']).lower()}`",
        "",
        "## Annotated Model-Ready Pairs",
        "",
        "| Status | Score | Add | Cut | Decision | Next Action |",
        "| --- | ---: | --- | --- | --- | --- |",
    ]
    for row in payload.get("annotated_model_ready_pairs") or []:
        lines.append(
            "| `{status}` | `{score}` | `{add}` | `{cut}` | `{decision}` | `{next_action}` |".format(
                status=row.get("learning_status"),
                score=row.get("pair_score"),
                add=row.get("add"),
                cut=row.get("cut"),
                decision=row.get("decision_status") or "-",
                next_action=row.get("next_action"),
            )
        )
    best = payload.get("best_next_pair")
    lines.extend(["", "## Best Next Pair", ""])
    if isinstance(best, Mapping):
        lines.append(f"- pair: `+{best.get('add')} / -{best.get('cut')}`")
        lines.append(f"- next_action: `{best.get('next_action')}`")
        if best.get("same_added_card_prior_rejects"):
            lines.append(
                f"- same_added_card_prior_rejects: `{json.dumps(best.get('same_added_card_prior_rejects'), sort_keys=True)}`"
            )
        if best.get("cut_oracle_text"):
            lines.append(f"- cut_oracle_text: `{best.get('cut_oracle_text')}`")
    else:
        lines.append("- none")
    lines.extend(["", "## Decision", ""])
    lines.append(f"- current_best_baseline: `{payload['decision']['current_best_baseline']}`")
    lines.append(f"- promotion_allowed: `{str(payload['decision']['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {payload['decision']['reason']}")
    lines.append(f"- next_action: `{payload['decision']['next_action']}`")
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
    parser.add_argument("--safe-cut-model", type=Path, default=DEFAULT_SAFE_CUT_MODEL)
    parser.add_argument("--decision-report", type=Path, action="append")
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_payload(
        safe_cut_model_path=args.safe_cut_model,
        decision_report_paths=args.decision_report,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "eligible_model_ready_pair_count": payload["summary"]["eligible_model_ready_pair_count"],
                "promotion_allowed": payload["summary"]["promotion_allowed"],
                "json": rel(json_path),
                "markdown": rel(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
