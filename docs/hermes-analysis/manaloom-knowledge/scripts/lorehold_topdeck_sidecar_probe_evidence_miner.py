#!/usr/bin/env python3
"""Mine exposure evidence for Lorehold sidecar cut probes.

The cut-model planner produces named review probes, not cuts. This read-only
miner checks whether those probes have existing exposure evidence, whether any
probe can become a matrix row, and whether a more specific mana-base model
already points to a better diagnostic route.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_CUT_MODEL_PLANNER = (
    REPORT_DIR / "lorehold_topdeck_sidecar_cut_model_planner_20260705_current.json"
)
DEFAULT_EXPOSURE_PROFILE = (
    REPORT_DIR / "lorehold_card_exposure_profile_20260704_role_tag_repair_deck607.json"
)
DEFAULT_MANA_BASE_MODEL = REPORT_DIR / "lorehold_mana_base_safe_cut_model_20260705_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_topdeck_sidecar_probe_evidence_miner_20260705_current"

LOW_EXPOSURE_UNIQUE_LIMIT = 3
LOW_EXPOSURE_DIRECT_LIMIT = 2


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


def normalize_name(value: Any) -> str:
    return " ".join(str(value or "").strip().lower().replace("’", "'").split())


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def exposure_lookup(exposure_profile: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        normalize_name(row.get("card_name")): dict(row)
        for row in as_list(exposure_profile.get("card_profiles"))
        if isinstance(row, Mapping) and row.get("card_name")
    }


def planner_probe_rows(planner: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for target in as_list(planner.get("cut_model_targets")):
        if not isinstance(target, Mapping):
            continue
        for probe in as_list(target.get("candidate_cut_probes")):
            if not isinstance(probe, Mapping):
                continue
            rows.append(
                {
                    "add_card": target.get("add_card") or probe.get("add_card") or "",
                    "target_tag": target.get("sidecar_tag") or probe.get("target_tag") or "",
                    "cut_card": probe.get("cut_card") or "",
                    "cut_value_tier": probe.get("cut_value_tier") or "",
                    "cut_value_score": as_int(probe.get("cut_value_score")),
                    "cut_policy": probe.get("cut_policy") or "",
                    "planner_blockers": as_list(probe.get("blockers")),
                    "planner_required_evidence": as_list(probe.get("required_evidence")),
                }
            )
    rows.sort(key=lambda row: (row["target_tag"], row["add_card"], row["cut_card"]))
    return rows


def classify_probe(
    *,
    probe: Mapping[str, Any],
    exposure: Mapping[str, Any],
    mana_ready_pairs: list[Mapping[str, Any]],
) -> tuple[str, list[str], str]:
    blockers = set(as_list(probe.get("planner_blockers")))
    cut_card = str(probe.get("cut_card") or "")
    target_tag = str(probe.get("target_tag") or "")
    unique = as_int(exposure.get("unique_exposure_count"))
    direct = as_int(exposure.get("direct_event_count"))
    role = str(exposure.get("inferred_role") or "")
    if not exposure:
        blockers.add("missing_current_exposure_profile_row")
        return "blocked_missing_exposure_evidence", sorted(blockers), (
            "profile target card before treating this probe as a cut"
        )
    if target_tag == "mana_base_safe_cut_model":
        blockers.add("use_dedicated_mana_base_model_before_generic_probe")
        if cut_card in {"Mountain // Mountain", "Plains // Plains"}:
            blockers.add("basic_land_floor_not_safe_from_probe")
        elif cut_card == "Ancient Tomb":
            blockers.add("fast_mana_utility_land_not_safe_from_probe")
        else:
            blockers.add("colored_source_floor_requires_pair_model")
        if any(str(pair.get("cut") or "") == cut_card for pair in mana_ready_pairs):
            blockers.add("dedicated_mana_model_has_this_cut")
            return "route_to_dedicated_mana_model_pair", sorted(blockers), (
                "use mana-base model pair report before sidecar matrix scoring"
            )
        return "blocked_generic_mana_probe_not_pair_safe", sorted(blockers), (
            "mine mana source equivalence or use dedicated ready pair instead"
        )
    low_exposure = unique <= LOW_EXPOSURE_UNIQUE_LIMIT and direct <= LOW_EXPOSURE_DIRECT_LIMIT
    if not low_exposure:
        blockers.add("probe_cut_has_material_exposure")
    if role in {"draw_filter_value", "recursion_engine", "ramp_engine", "tutor_access"}:
        blockers.add(f"probe_cut_role_not_low_impact:{role}")
    if low_exposure and role in {"unproven_or_unmodeled", "runtime_ready_unexposed"}:
        return "reviewable_low_exposure_probe_needs_floor_test", sorted(blockers), (
            "run focused floor-equivalence trace before matrix row"
        )
    return "blocked_exposed_topdeck_role_probe", sorted(blockers), (
        "do not turn this probe into a cut without proving redundant low-impact exposure"
    )


def exposure_brief(row: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "unique_exposure_count": as_int(row.get("unique_exposure_count")),
        "direct_event_count": as_int(row.get("direct_event_count")),
        "summary_metric_count": as_int(row.get("summary_metric_count")),
        "inferred_role": row.get("inferred_role") or "",
        "role_confidence": row.get("role_confidence") or "",
        "decision_status": as_dict(row.get("decision")).get("status") or "",
        "role_signals": as_list(row.get("role_signals")),
        "source_file_count": as_int(row.get("source_file_count")),
    }


def mana_ready_pairs(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [dict(row) for row in as_list(payload.get("top_model_ready_pairs")) if isinstance(row, Mapping)]
    rows.sort(key=lambda row: (-as_int(row.get("pair_score")), str(row.get("add") or ""), str(row.get("cut") or "")))
    return rows


def build_report(
    *,
    cut_model_planner: Mapping[str, Any],
    exposure_profile: Mapping[str, Any],
    mana_base_model: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    exposures = exposure_lookup(exposure_profile)
    ready_pairs = mana_ready_pairs(mana_base_model)
    probe_rows = []
    status_counts: Counter[str] = Counter()
    blocker_counts: Counter[str] = Counter()
    for probe in planner_probe_rows(cut_model_planner):
        exposure = exposures.get(normalize_name(probe.get("cut_card")), {})
        status, blockers, next_action = classify_probe(
            probe=probe,
            exposure=exposure,
            mana_ready_pairs=ready_pairs,
        )
        row = {
            **probe,
            "evidence_status": status,
            "matrix_candidate_row_eligible_now": False,
            "safe_cut_ready_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "exposure": exposure_brief(exposure),
            "blockers": blockers,
            "next_action": next_action,
        }
        probe_rows.append(row)
        status_counts[status] += 1
        blocker_counts.update(blockers)
    report_status = "topdeck_sidecar_probe_evidence_no_safe_cut_keep_607"
    if not probe_rows:
        report_status = "topdeck_sidecar_probe_evidence_inputs_missing_keep_607"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_topdeck_sidecar_probe_evidence_miner",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": report_status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": {
            "decision_status": report_status,
            "probe_row_count": len(probe_rows),
            "safe_cut_ready_count": 0,
            "matrix_candidate_row_eligible_count": 0,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "deck_action_allowed_now": False,
            "blocked_exposed_topdeck_role_probe_count": status_counts.get(
                "blocked_exposed_topdeck_role_probe", 0
            ),
            "blocked_generic_mana_probe_count": status_counts.get(
                "blocked_generic_mana_probe_not_pair_safe", 0
            ),
            "mana_model_ready_pair_count": len(ready_pairs),
            "status_counts": dict(sorted(status_counts.items())),
            "blocker_counts": dict(sorted(blocker_counts.items())),
            "recommended_next_action": (
                "use_dedicated_mana_model_ready_pairs_as_diagnostic_candidates_or_collect_topdeck_floor_traces"
                if ready_pairs
                else "collect_probe_floor_evidence_before_matrix_rows"
            ),
        },
        "probe_evidence_rows": probe_rows,
        "dedicated_mana_model_ready_pairs": ready_pairs[:10],
        "source_evidence": {
            "cut_model_planner_summary": summary(cut_model_planner),
            "exposure_profile_card_count": len(as_list(exposure_profile.get("card_profiles"))),
            "mana_base_model_summary": summary(mana_base_model),
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "safe_cut_ready_now": False,
            "matrix_candidate_rows_ready": False,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "Current probe cuts have real exposure or structural mana-floor risk. "
                "The only narrower advancement is the dedicated mana-base model's "
                "diagnostic Plateau pairs, still with battle and promotion closed."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_convert exposed topdeck probes into cuts",
                "route mana learning through dedicated Plateau pairs instead of generic basic-land probes",
                "require matrix, trace, and equal battle gates before any deck change",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = as_dict(payload.get("summary"))
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Topdeck Sidecar Probe Evidence Miner",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload['status']}`",
        f"- Probe rows: `{summary_row['probe_row_count']}`",
        f"- Safe-cut ready: `{summary_row['safe_cut_ready_count']}`",
        f"- Matrix candidate rows eligible: `{summary_row['matrix_candidate_row_eligible_count']}`",
        f"- Candidate deck materialization allowed now: `{str(summary_row['candidate_deck_materialization_allowed_now']).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary_row['natural_battle_gate_allowed_now']).lower()}`",
        f"- Mana model ready pairs: `{summary_row['mana_model_ready_pair_count']}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Status Summary", ""])
    lines.append(f"- status_counts: `{json.dumps(summary_row.get('status_counts') or {}, sort_keys=True)}`")
    lines.append(f"- blocker_counts: `{json.dumps(summary_row.get('blocker_counts') or {}, sort_keys=True)}`")
    lines.extend(["", "## Probe Evidence Rows", ""])
    lines.append("| Add | Probe cut | Status | Exposure | Role | Next action |")
    lines.append("| --- | --- | --- | ---: | --- | --- |")
    for row in as_list(payload.get("probe_evidence_rows")):
        exposure = as_dict(row.get("exposure"))
        lines.append(
            "| {add} | `{cut}` | `{status}` | {count} | `{role}` | `{next}` |".format(
                add=row.get("add_card") or "",
                cut=row.get("cut_card") or "",
                status=row.get("evidence_status") or "",
                count=exposure.get("unique_exposure_count") or 0,
                role=exposure.get("inferred_role") or "",
                next=row.get("next_action") or "",
            )
        )
    lines.extend(["", "## Dedicated Mana Model Ready Pairs", ""])
    ready_pairs = as_list(payload.get("dedicated_mana_model_ready_pairs"))
    if ready_pairs:
        lines.append("| Add | Cut | Score | Status | Reasons |")
        lines.append("| --- | --- | ---: | --- | --- |")
        for pair in ready_pairs:
            lines.append(
                "| `{add}` | `{cut}` | {score} | `{status}` | {reasons} |".format(
                    add=pair.get("add") or "",
                    cut=pair.get("cut") or "",
                    score=pair.get("pair_score") or 0,
                    status=pair.get("status") or "",
                    reasons=", ".join(as_list(pair.get("reasons"))),
                )
            )
    else:
        lines.append("- None.")
    lines.extend(["", "## Decision", ""])
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- safe_cut_ready_now: `{str(decision['safe_cut_ready_now']).lower()}`")
    lines.append(f"- matrix_candidate_rows_ready: `{str(decision['matrix_candidate_rows_ready']).lower()}`")
    lines.append(f"- candidate_deck_materialization_allowed_now: `{str(decision['candidate_deck_materialization_allowed_now']).lower()}`")
    lines.append(f"- forced_access_allowed_now: `{str(decision['forced_access_allowed_now']).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision['natural_battle_allowed_now']).lower()}`")
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
    parser.add_argument("--cut-model-planner", type=Path, default=DEFAULT_CUT_MODEL_PLANNER)
    parser.add_argument("--exposure-profile", type=Path, default=DEFAULT_EXPOSURE_PROFILE)
    parser.add_argument("--mana-base-model", type=Path, default=DEFAULT_MANA_BASE_MODEL)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "cut_model_planner": args.cut_model_planner,
        "exposure_profile": args.exposure_profile,
        "mana_base_model": args.mana_base_model,
    }
    payload = build_report(
        cut_model_planner=read_json(args.cut_model_planner),
        exposure_profile=read_json(args.exposure_profile),
        mana_base_model=read_json(args.mana_base_model),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
