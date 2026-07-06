#!/usr/bin/env python3
"""Model add/cut pairs for externally backfilled exact artifact-engine seeds.

This gate follows the external exact artifact Oracle backfill and post-backfill
candidate reviewer. A ready add candidate is not enough to replace a used engine
card: the add must cover the cut card's exact same-lane requirements before any
source trace, candidate copy, battle, or promotion can open.
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

from global_commander_deck_contract_audit import REPO_ROOT, rel
from global_commander_engine_exact_replacement_or_new_cut_finder import exact_engine_signals
from master_optimizer_common import normalize_name


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_CANDIDATE_REVIEWER_REPORT = (
    REPORT_DIR / "global_commander_external_exact_artifact_engine_candidate_reviewer_20260706_current.json"
)
DEFAULT_FINDER_REPORT = (
    REPORT_DIR / "global_commander_engine_exact_replacement_or_new_cut_finder_20260706_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_external_exact_artifact_engine_add_cut_pair_model_20260706_current"
)
REQUIRED_EXACT_ENGINE_SIGNALS = ("artifact_spell_token_payoff", "artifact_type_conversion_engine")


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def artifact_rel(path: Path) -> str:
    candidate = path if path.is_absolute() else REPO_ROOT / path
    try:
        return rel(candidate)
    except ValueError:
        return str(path)


def resolve_repo_path(raw: object, *, default: Path) -> Path:
    value = str(raw or "").strip()
    if not value:
        return default
    path = Path(value)
    return path if path.is_absolute() else REPO_ROOT / path


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def local_oracle(conn: sqlite3.Connection, name: str) -> sqlite3.Row | None:
    return conn.execute(
        "SELECT name, type_line, oracle_text FROM card_oracle_cache "
        "WHERE normalized_name = ? OR lower(name) = lower(?) LIMIT 1",
        (normalize_name(name), name),
    ).fetchone()


def candidate_add_rows(candidate_reviewer_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in candidate_reviewer_payload.get("reviewed_candidate_rows") or []:
        if not isinstance(row, Mapping):
            continue
        if row.get("status") != "local_external_exact_engine_candidate_ready_for_add_cut_review":
            continue
        rows.append(
            {
                "card_name": str(row.get("card_name") or ""),
                "signals": sorted(str(signal) for signal in row.get("local_signals") or []),
                "exact_status": row.get("local_exact_status"),
            }
        )
    return [row for row in rows if row["card_name"]]


def replacement_required_cut_rows(
    finder_payload: Mapping[str, Any],
    conn: sqlite3.Connection,
) -> list[dict[str, Any]]:
    rows = []
    for row in finder_payload.get("new_engine_cut_rows") or []:
        if not isinstance(row, Mapping):
            continue
        name = str(row.get("card_name") or "")
        if normalize_name(name) != "biotransference":
            continue
        local = local_oracle(conn, name)
        if local is None:
            signals = []
        else:
            signals = exact_engine_signals(str(local["type_line"] or ""), str(local["oracle_text"] or ""))
        required = [signal for signal in REQUIRED_EXACT_ENGINE_SIGNALS if signal in signals]
        if not required:
            required = list(REQUIRED_EXACT_ENGINE_SIGNALS)
        rows.append(
            {
                "card_name": name,
                "policy_status": row.get("status"),
                "policy_bucket": row.get("policy_bucket"),
                "signals": sorted(signals),
                "required_replacement_signals": sorted(required),
            }
        )
    return rows


def build_pair_row(add: Mapping[str, Any], cut: Mapping[str, Any]) -> dict[str, Any]:
    add_signals = set(str(signal) for signal in add.get("signals") or [])
    required_signals = set(str(signal) for signal in cut.get("required_replacement_signals") or [])
    missing = sorted(required_signals - add_signals)
    blockers = []
    if missing:
        blockers.append("add_does_not_cover_cut_required_signals:" + ",".join(missing))
    if cut.get("policy_status") != "already_reviewed_engine_cut_not_new_source":
        blockers.append(f"cut_policy_not_replacement_required:{cut.get('policy_status')}")
    ready_for_source_trace = not blockers
    return {
        "add_card": add.get("card_name"),
        "cut_card": cut.get("card_name"),
        "status": (
            "add_cut_pair_ready_for_source_trace"
            if ready_for_source_trace
            else "add_cut_pair_blocked_by_same_lane_signal_gap"
        ),
        "add_signals": sorted(add_signals),
        "cut_required_signals": sorted(required_signals),
        "missing_signals": missing,
        "cut_policy_status": cut.get("policy_status"),
        "blockers": blockers,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "promotion_allowed": False,
    }


def build_report(
    *,
    candidate_reviewer_report: Path = DEFAULT_CANDIDATE_REVIEWER_REPORT,
    finder_report: Path = DEFAULT_FINDER_REPORT,
) -> dict[str, Any]:
    candidate_payload = load_json(candidate_reviewer_report)
    finder_payload = load_json(finder_report)
    source_db = resolve_repo_path(
        (candidate_payload.get("input_artifacts") or {}).get("source_db")
        or (finder_payload.get("input_artifacts") or {}).get("source_db"),
        default=SCRIPT_DIR / "knowledge.db",
    )
    with sqlite3.connect(source_db) as conn:
        conn.row_factory = sqlite3.Row
        add_rows = candidate_add_rows(candidate_payload)
        cut_rows = replacement_required_cut_rows(finder_payload, conn)
    pair_rows = [build_pair_row(add, cut) for cut in cut_rows for add in add_rows]
    ready_pairs = [row for row in pair_rows if row["status"] == "add_cut_pair_ready_for_source_trace"]
    blocker_counts = Counter(blocker for row in pair_rows for blocker in row.get("blockers") or [])
    if ready_pairs:
        status = "external_exact_artifact_engine_add_cut_pair_model_ready_for_source_trace"
        next_gate = "source_trace_exact_engine_replacement_before_candidate_copy"
    else:
        status = "external_exact_artifact_engine_add_cut_pair_model_blocks_candidate_copy"
        next_gate = "expand_exact_artifact_type_conversion_source_lane_or_keep_biotransference_protected"
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_exact_artifact_engine_add_cut_pair_model",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_rows_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "candidate_reviewer_report": artifact_rel(candidate_reviewer_report),
            "finder_report": artifact_rel(finder_report),
            "source_db": artifact_rel(source_db),
        },
        "summary": {
            "add_candidate_count": len(add_rows),
            "replacement_required_cut_count": len(cut_rows),
            "pair_count": len(pair_rows),
            "ready_for_source_trace_pair_count": len(ready_pairs),
            "blocker_counts": dict(sorted(blocker_counts.items())),
            "next_gate": next_gate,
        },
        "add_candidate_rows": add_rows,
        "replacement_required_cut_rows": cut_rows,
        "pair_rows": pair_rows,
        "policy": {
            "same_lane_boundary": "Replacing Biotransference requires artifact-spell payoff and artifact type-conversion coverage.",
            "candidate_copy_boundary": "Signal coverage can only route to source trace; candidate copy remains closed.",
            "battle_boundary": "No battle probe is valid until an add/cut pair survives same-lane source trace.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Exact Artifact Engine Add Cut Pair Model",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- add_candidate_count: `{summary['add_candidate_count']}`",
        f"- replacement_required_cut_count: `{summary['replacement_required_cut_count']}`",
        f"- pair_count: `{summary['pair_count']}`",
        f"- ready_for_source_trace_pair_count: `{summary['ready_for_source_trace_pair_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Pair Rows",
        "",
        "| Add | Cut | Status | Add Signals | Required Signals | Missing | Blockers |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for row in payload["pair_rows"]:
        lines.append(
            "| `{add}` | `{cut}` | `{status}` | `{add_signals}` | `{required}` | `{missing}` | {blockers} |".format(
                add=row.get("add_card"),
                cut=row.get("cut_card"),
                status=row.get("status"),
                add_signals=",".join(row.get("add_signals") or []),
                required=",".join(row.get("cut_required_signals") or []),
                missing=",".join(row.get("missing_signals") or []),
                blockers=", ".join(row.get("blockers") or []) or "-",
            )
        )
    if not payload["pair_rows"]:
        lines.append("| none |  |  |  |  |  |  |")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate-reviewer-report", type=Path, default=DEFAULT_CANDIDATE_REVIEWER_REPORT)
    parser.add_argument("--finder-report", type=Path, default=DEFAULT_FINDER_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        candidate_reviewer_report=args.candidate_reviewer_report,
        finder_report=args.finder_report,
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
