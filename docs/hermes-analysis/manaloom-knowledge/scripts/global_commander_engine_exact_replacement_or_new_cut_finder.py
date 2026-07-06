#!/usr/bin/env python3
"""Find exact engine replacements or new engine cuts before candidate copy.

This read-only gate follows
``global_commander_engine_cut_trace_replacement_reviewer``. It searches the
local Oracle/legality cache for exact Biotransference-style artifact-spell or
type-conversion engines and rechecks whether the engine policy left any other
unblocked engine cut. It does not copy decks, run battles, mutate databases, or
promote packages.
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
from master_optimizer_common import normalize_name


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_REVIEWER_REPORT = (
    REPORT_DIR / "global_commander_engine_cut_trace_replacement_reviewer_20260706_current.json"
)
DEFAULT_ENGINE_POLICY_REPORT = (
    REPORT_DIR / "global_commander_engine_axis_nonland_cut_policy_model_20260706_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_engine_exact_replacement_or_new_cut_finder_20260706_current"
)
COMMANDER_IDENTITY = {"B", "R", "W"}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def artifact_rel(path: Path) -> str:
    candidate = path if path.is_absolute() else REPO_ROOT / path
    try:
        return rel(candidate)
    except ValueError:
        return str(path)


def resolve_path(value: object, *, default: Path) -> Path:
    raw = str(value or "").strip()
    if not raw:
        return default
    path = Path(raw)
    return path if path.is_absolute() else REPO_ROOT / path


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def parse_color_identity(value: object) -> set[str]:
    raw = str(value or "").strip()
    if not raw:
        return set()
    if raw.startswith("["):
        try:
            loaded = json.loads(raw)
            return {str(item).strip().upper() for item in loaded if str(item).strip()}
        except json.JSONDecodeError:
            return set()
    return {part.strip().upper() for part in raw.replace("/", ",").split(",") if part.strip()}


def color_identity_allowed(value: object, commander_identity: set[str] = COMMANDER_IDENTITY) -> bool:
    return parse_color_identity(value).issubset(commander_identity)


def source_db(engine_policy_payload: Mapping[str, Any]) -> Path:
    return resolve_path(engine_policy_payload.get("source_db"), default=SCRIPT_DIR / "knowledge.db")


def primary_pool(engine_policy_payload: Mapping[str, Any]) -> Mapping[str, Any]:
    for row in engine_policy_payload.get("pool_policy_rows") or []:
        if isinstance(row, Mapping):
            return row
    return {}


def exact_engine_signals(type_line: str, oracle_text: str) -> list[str]:
    text = normalize_name(f"{type_line} {oracle_text}")
    signals = []
    if "whenever you cast an artifact spell" in text or "whenever you cast one or more artifact spells" in text:
        if "create" in text and ("token" in text or "treasure" in text):
            signals.append("artifact_spell_token_payoff")
        if "draw" in text:
            signals.append("artifact_spell_draw_payoff")
        if "cost" in text and "less" in text:
            signals.append("artifact_spell_cost_reducer")
    if "artifact spells you cast cost" in text:
        signals.append("artifact_spell_cost_reducer")
    if (
        "creatures you control are artifacts" in text
        or "creature spells you control are artifacts" in text
        or ("creature cards you own" in text and "are artifacts" in text)
    ):
        signals.append("artifact_type_conversion_engine")
    return sorted(set(signals))


def exact_replacement_status(signals: list[str]) -> str:
    if "artifact_type_conversion_engine" in signals:
        return "exact_type_conversion_engine_candidate"
    if "artifact_spell_token_payoff" in signals or "artifact_spell_draw_payoff" in signals:
        return "exact_artifact_spell_payoff_candidate"
    if "artifact_spell_cost_reducer" in signals:
        return "artifact_spell_support_not_biotransference_replacement"
    return "not_exact_engine_replacement"


def load_lookup_sets(db_path: Path, deck_id: str) -> tuple[set[str], dict[str, str], dict[str, int]]:
    deck_names: set[str] = set()
    legalities: dict[str, str] = {}
    ranks: dict[str, int] = {}
    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        for row in conn.execute("SELECT card_name FROM deck_cards WHERE deck_id = ?", (deck_id,)):
            deck_names.add(normalize_name(str(row["card_name"] or "")))
        for row in conn.execute("SELECT card_name, status FROM card_legalities WHERE lower(format) = 'commander'"):
            key = normalize_name(str(row["card_name"] or ""))
            if key and key not in legalities:
                legalities[key] = str(row["status"] or "")
        for row in conn.execute(
            "SELECT card_name, min(coalesce(edhrec_rank, 999999)) AS rank FROM format_staples "
            "WHERE lower(format) LIKE '%commander%' GROUP BY card_name"
        ):
            key = normalize_name(str(row["card_name"] or ""))
            if key:
                ranks[key] = int(row["rank"] or 999999)
    return deck_names, legalities, ranks


def replacement_rows(db_path: Path, deck_id: str, *, limit: int = 25) -> list[dict[str, Any]]:
    deck_names, legalities, ranks = load_lookup_sets(db_path, deck_id)
    rows: list[dict[str, Any]] = []
    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        for row in conn.execute(
            "SELECT name, color_identity_json, type_line, oracle_text, scryfall_id "
            "FROM card_oracle_cache WHERE oracle_text IS NOT NULL"
        ):
            name = str(row["name"] or "")
            key = normalize_name(name)
            signals = exact_engine_signals(str(row["type_line"] or ""), str(row["oracle_text"] or ""))
            status = exact_replacement_status(signals)
            if status == "not_exact_engine_replacement":
                continue
            legality = legalities.get(key, "missing_commander_legality")
            in_deck = key in deck_names
            color_allowed = color_identity_allowed(row["color_identity_json"])
            blockers = []
            if legality != "legal":
                blockers.append(f"commander_legality:{legality}")
            if not color_allowed:
                blockers.append("outside_commander_color_identity")
            if in_deck:
                blockers.append("already_in_current_deck")
            if status == "artifact_spell_support_not_biotransference_replacement":
                blockers.append("support_only_no_token_or_draw_payoff")
            ready = not blockers and status in {
                "exact_type_conversion_engine_candidate",
                "exact_artifact_spell_payoff_candidate",
            }
            rows.append(
                {
                    "card_name": name,
                    "status": "exact_replacement_candidate_ready_for_source_trace" if ready else status,
                    "raw_exact_status": status,
                    "signals": signals,
                    "color_identity": sorted(parse_color_identity(row["color_identity_json"])),
                    "commander_legality": legality,
                    "already_in_current_deck": in_deck,
                    "edhrec_rank": ranks.get(key),
                    "blockers": blockers,
                    "type_line": row["type_line"],
                    "oracle_excerpt": " ".join(str(row["oracle_text"] or "").split())[:300],
                    "candidate_copy_allowed": False,
                    "battle_gate_allowed": False,
                    "mutation_allowed": False,
                }
            )
    rows.sort(
        key=lambda row: (
            0 if row["status"] == "exact_replacement_candidate_ready_for_source_trace" else 1,
            row.get("edhrec_rank") or 999999,
            str(row.get("card_name") or ""),
        )
    )
    return rows[: max(1, limit)]


def new_engine_cut_rows(engine_policy_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    pool = primary_pool(engine_policy_payload)
    rows = []
    for row in pool.get("policy_cut_rows") or []:
        if not isinstance(row, Mapping):
            continue
        roles = as_list(row.get("roles"))
        if "engine" not in roles:
            continue
        card = str(row.get("card_name") or "")
        ready = bool(row.get("cut_pressure_ready"))
        status = str(row.get("policy_status") or "")
        if ready:
            next_status = "already_reviewed_engine_cut_not_new_source"
        elif status == "engine_axis_policy_blocks_cut_until_source_lane_review":
            next_status = "new_engine_cut_blocked_by_commander_plan_signal"
        else:
            next_status = "new_engine_cut_not_available"
        rows.append(
            {
                "card_name": card,
                "status": next_status,
                "policy_status": status,
                "policy_bucket": row.get("policy_bucket"),
                "roles": roles,
                "commander_plan_signals": as_list(row.get("commander_plan_signals")),
                "policy_blockers": as_list(row.get("policy_blockers")),
                "cut_pressure_ready": ready,
                "candidate_copy_allowed": False,
                "battle_gate_allowed": False,
                "mutation_allowed": False,
            }
        )
    rows.sort(key=lambda row: (0 if row["status"].startswith("already_reviewed") else 1, str(row["card_name"])))
    return rows


def build_report(
    *,
    reviewer_report: Path,
    engine_policy_report: Path,
    replacement_limit: int = 25,
) -> dict[str, Any]:
    reviewer_payload = load_json(reviewer_report)
    engine_payload = load_json(engine_policy_report)
    pool = primary_pool(engine_payload)
    deck_id = str(pool.get("deck_id") or "")
    commander = str(pool.get("commander") or "")
    db_path = source_db(engine_payload)
    replacement = replacement_rows(db_path, deck_id, limit=max(1, replacement_limit))
    cuts = new_engine_cut_rows(engine_payload)
    ready_replacements = [
        row for row in replacement if row["status"] == "exact_replacement_candidate_ready_for_source_trace"
    ]
    new_cut_ready = [
        row
        for row in cuts
        if row["status"] not in {
            "already_reviewed_engine_cut_not_new_source",
            "new_engine_cut_blocked_by_commander_plan_signal",
            "new_engine_cut_not_available",
        }
    ]
    status_counts = Counter(row["status"] for row in replacement)
    cut_counts = Counter(row["status"] for row in cuts)
    blockers = []
    if not ready_replacements:
        blockers.append("no_local_exact_replacement_ready_for_source_trace")
    if not new_cut_ready:
        blockers.append("no_new_unblocked_engine_cut_source")
    blockers.append("candidate_copy_closed_after_exact_replacement_or_new_cut_finder")
    if ready_replacements:
        status = "engine_exact_replacement_found_needs_source_trace"
        next_gate = "source_trace_exact_engine_replacement_before_candidate_copy"
    else:
        status = "engine_exact_replacement_or_new_cut_not_found_locally"
        next_gate = "expand_external_exact_artifact_engine_source_lanes_or_global_axis"
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_engine_exact_replacement_or_new_cut_finder",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "reviewer_report": artifact_rel(reviewer_report),
            "engine_policy_report": artifact_rel(engine_policy_report),
            "source_db": artifact_rel(db_path),
            "reviewer_status": reviewer_payload.get("status"),
        },
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "replacement_candidate_scanned_count": len(replacement),
            "exact_replacement_ready_count": len(ready_replacements),
            "replacement_status_counts": dict(sorted(status_counts.items())),
            "engine_cut_row_count": len(cuts),
            "new_unblocked_engine_cut_count": len(new_cut_ready),
            "engine_cut_status_counts": dict(sorted(cut_counts.items())),
            "candidate_copy_blocker_count": len(blockers),
            "local_oracle_cache_boundary": "card_oracle_cache_rows_only",
            "next_gate": next_gate,
        },
        "replacement_candidate_rows": replacement,
        "new_engine_cut_rows": cuts,
        "candidate_copy_blockers": blockers,
        "policy": {
            "exact_replacement_boundary": "Biotransference replacement requires artifact-spell payoff or artifact type-conversion, not generic artifact adjacency.",
            "new_cut_boundary": "Protected commander-plan engines are not new cut sources without source-lane evidence.",
            "cache_boundary": "This report searches local Hermes card_oracle_cache and commander legality cache only; external source expansion is a separate gate.",
            "mutation_boundary": "This finder reads SQLite and report artifacts only.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Engine Exact Replacement Or New Cut Finder",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- replacement_candidate_scanned_count: `{summary['replacement_candidate_scanned_count']}`",
        f"- exact_replacement_ready_count: `{summary['exact_replacement_ready_count']}`",
        f"- engine_cut_row_count: `{summary['engine_cut_row_count']}`",
        f"- new_unblocked_engine_cut_count: `{summary['new_unblocked_engine_cut_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Replacement Candidates",
        "",
        "| Card | Status | Signals | Color | Legality | Blockers |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for row in payload["replacement_candidate_rows"]:
        lines.append(
            "| `{card}` | `{status}` | `{signals}` | `{color}` | `{legality}` | {blockers} |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                signals=",".join(row.get("signals") or []),
                color=",".join(row.get("color_identity") or []),
                legality=row.get("commander_legality"),
                blockers=", ".join(row.get("blockers") or []) or "-",
            )
        )
    if not payload["replacement_candidate_rows"]:
        lines.append("| none |  |  |  |  |  |")
    lines.extend(["", "## New Engine Cut Rows", ""])
    lines.extend(["| Card | Status | Policy Bucket | Signals | Blockers |", "| --- | --- | --- | --- | --- |"])
    for row in payload["new_engine_cut_rows"]:
        lines.append(
            "| `{card}` | `{status}` | `{bucket}` | `{signals}` | {blockers} |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                bucket=row.get("policy_bucket"),
                signals=",".join(row.get("commander_plan_signals") or []),
                blockers=", ".join(row.get("policy_blockers") or []) or "-",
            )
        )
    if not payload["new_engine_cut_rows"]:
        lines.append("| none |  |  |  |  |")
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
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
    parser.add_argument("--reviewer-report", type=Path, default=DEFAULT_REVIEWER_REPORT)
    parser.add_argument("--engine-policy-report", type=Path, default=DEFAULT_ENGINE_POLICY_REPORT)
    parser.add_argument("--replacement-limit", type=int, default=25)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        reviewer_report=args.reviewer_report,
        engine_policy_report=args.engine_policy_report,
        replacement_limit=max(1, args.replacement_limit),
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
