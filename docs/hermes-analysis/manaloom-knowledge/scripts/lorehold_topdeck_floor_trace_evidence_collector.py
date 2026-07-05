#!/usr/bin/env python3
"""Collect current Lorehold topdeck floor-trace evidence.

This read-only collector consolidates the current target contract, forced-access
audit, microbenchmark plan, and safe-cut miner for the five topdeck cards. It
does not run a battle, force card access, materialize a sidecar deck, mutate
deck 607, or write PostgreSQL/SQLite.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_TRACE_CONTRACT = (
    REPORT_DIR / "lorehold_topdeck_floor_trace_target_contract_20260705_current.json"
)
DEFAULT_FORCED_ACCESS_AUDIT = REPORT_DIR / "lorehold_topdeck_forced_access_audit_20260705_current.json"
DEFAULT_MICROBENCHMARK_PLAN = (
    REPORT_DIR / "lorehold_topdeck_forced_access_microbenchmark_plan_20260705_current.json"
)
DEFAULT_SAFE_CUT_MINER = REPORT_DIR / "lorehold_topdeck_safe_cut_miner_20260705_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_topdeck_floor_trace_evidence_collector_20260705_current"


TARGET_ORDER = [
    "Penance",
    "Galvanoth",
    "Dragon's Rage Channeler",
    "Valakut Awakening // Valakut Stoneforge",
    "Wheel of Fortune",
]

EXTERNAL_SOURCE_TOUCHPOINTS = [
    {
        "source": "Scryfall",
        "url": "https://scryfall.com/",
        "use": "Oracle, legality, color identity, and rules text normalization before runtime or matrix work.",
    },
    {
        "source": "EDHREC Lorehold pages",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "use": "Commander-specific discovery signal for topdeck and spellslinger candidates, not cut proof.",
    },
    {
        "source": "Card Kingdom Lorehold synergy review",
        "url": "https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/",
        "use": "External support for Penance as a hand-to-library setup card, still below local cut and trace proof.",
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


def as_float(value: Any) -> float | None:
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def by_card(rows: list[Any], key: str = "card_name") -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        card = str(row.get(key) or row.get("add_card") or "")
        if card:
            out[card] = dict(row)
    return out


def target_contract_rows(trace_contract: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    contract = as_dict(trace_contract.get("contract"))
    return by_card(as_list(contract.get("target_cards")), key="add_card")


def forced_access_rows(forced_access_audit: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return by_card(as_list(forced_access_audit.get("candidates")), key="card_name")


def microbenchmark_rows(microbenchmark_plan: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return by_card(as_list(microbenchmark_plan.get("microbenchmarks")), key="card_name")


def safe_cut_rows(safe_cut_miner: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return by_card(as_list(safe_cut_miner.get("target_cut_assessments")), key="card_name")


def compact_existing_packages(row: Mapping[str, Any]) -> list[dict[str, Any]]:
    packages: list[dict[str, Any]] = []
    for package in as_list(row.get("existing_packages")):
        if not isinstance(package, Mapping):
            continue
        packages.append(
            {
                "package_key": package.get("package_key") or "",
                "cuts": as_list(package.get("cuts")),
                "prior_delta_pp": as_float(package.get("prior_delta_pp")),
                "prior_evidence_status": package.get("prior_evidence_status") or "",
                "cut_safety_status": package.get("cut_safety_status") or "",
                "status": package.get("status") or "",
            }
        )
    return packages


def compact_attempted_cuts(row: Mapping[str, Any]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for cut in as_list(row.get("attempted_package_cuts")):
        if not isinstance(cut, Mapping):
            continue
        out.append(
            {
                "cut": cut.get("cut") or "",
                "package_key": cut.get("package_key") or "",
                "package_decision": cut.get("package_decision") or "",
                "prior_delta_pp": as_float(cut.get("prior_delta_pp")),
                "prior_evidence_status": cut.get("prior_evidence_status") or "",
                "cut_safety_status": cut.get("cut_safety_status") or "",
            }
        )
    return out


def classify_target(
    *,
    contract_row: Mapping[str, Any],
    forced_row: Mapping[str, Any],
    micro_row: Mapping[str, Any],
    safe_row: Mapping[str, Any],
) -> tuple[str, str, list[str]]:
    blockers = set(as_list(contract_row.get("blocked_before_matrix")))
    blockers.update(as_list(forced_row.get("blockers_before_deck_action")))
    blockers.update(as_list(micro_row.get("blockers")))
    package_status = str(micro_row.get("package_execution_status") or "")
    safe_cut_status = str(safe_row.get("safe_cut_status") or "")
    prior_reject_count = as_int(micro_row.get("prior_reject_count"))
    seed_safe_count = as_int(safe_row.get("seed_safe_same_lane_count"))
    runnable_now = bool(micro_row.get("runnable_now"))
    if seed_safe_count > 0 and runnable_now:
        return (
            "trace_floor_candidate_ready_for_preflight_review",
            "build_package_manifest_then_run forced-access diagnostic only",
            sorted(blockers),
        )
    if prior_reject_count > 0 and safe_cut_status == "no_current_safe_cut_for_target":
        return (
            "prior_reject_requires_new_same_lane_cut_model",
            "mine_new_nonanchor_same_lane_cut_before_any_trace_execution",
            sorted(blockers),
        )
    if "cut_safety_blocked" in package_status or safe_cut_status == "no_current_safe_cut_for_target":
        return (
            "trace_design_ready_but_cut_safety_blocked",
            "collect non-execution trace requirements and search for safe cut evidence",
            sorted(blockers),
        )
    return (
        "trace_evidence_incomplete_keep_607",
        "repair evidence inputs before any deck action",
        sorted(blockers),
    )


def build_target_evidence_rows(
    *,
    trace_contract: Mapping[str, Any],
    forced_access_audit: Mapping[str, Any],
    microbenchmark_plan: Mapping[str, Any],
    safe_cut_miner: Mapping[str, Any],
) -> list[dict[str, Any]]:
    contract_rows = target_contract_rows(trace_contract)
    forced_rows = forced_access_rows(forced_access_audit)
    micro_rows = microbenchmark_rows(microbenchmark_plan)
    safe_rows = safe_cut_rows(safe_cut_miner)
    cards = [
        card
        for card in TARGET_ORDER
        if card in contract_rows or card in forced_rows or card in micro_rows or card in safe_rows
    ]
    rows: list[dict[str, Any]] = []
    for card in cards:
        contract_row = contract_rows.get(card, {})
        forced_row = forced_rows.get(card, {})
        micro_row = micro_rows.get(card, {})
        safe_row = safe_rows.get(card, {})
        status, next_action, blockers = classify_target(
            contract_row=contract_row,
            forced_row=forced_row,
            micro_row=micro_row,
            safe_row=safe_row,
        )
        external = as_dict(forced_row.get("external_evidence"))
        hypothesis = as_dict(forced_row.get("hypothesis"))
        row = {
            "card_name": card,
            "trace_evidence_status": status,
            "next_action": next_action,
            "learning_priority_rank": as_int(forced_row.get("learning_priority_rank"))
            or TARGET_ORDER.index(card) + 1,
            "trace_collection_allowed_now": bool(contract_row.get("trace_collection_allowed_now"))
            or bool(forced_row.get("diagnostic_allowed_now")),
            "forced_access_allowed_now": False,
            "structure_matrix_allowed_now": False,
            "candidate_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "safe_cut_status": safe_row.get("safe_cut_status") or "",
            "package_execution_status": micro_row.get("package_execution_status") or "",
            "prior_package_count": as_int(micro_row.get("prior_package_count")),
            "prior_reject_count": as_int(micro_row.get("prior_reject_count")),
            "attempted_package_cut_count": as_int(safe_row.get("attempted_package_cut_count")),
            "seed_safe_same_lane_count": as_int(safe_row.get("seed_safe_same_lane_count")),
            "reviewable_same_lane_gap_count": as_int(safe_row.get("reviewable_same_lane_gap_count")),
            "microbenchmark_runnable_now": bool(micro_row.get("runnable_now")),
            "primary_forced_access_mode": micro_row.get("primary_forced_access_mode") or "",
            "required_trace_signals": as_list(micro_row.get("required_trace_signals"))
            or as_list(contract_row.get("trace_requirements")),
            "baseline_floor_metrics": as_list(contract_row.get("baseline_floor_metrics")),
            "external_evidence": {
                "source": external.get("source") or "",
                "url": external.get("url") or "",
                "signal": external.get("signal") or "",
                "role": external.get("role") or "",
                "risk": external.get("risk") or "",
                "variant_deck_count": as_int(hypothesis.get("variant_deck_count")),
                "variant_deck_ids": as_list(hypothesis.get("variant_deck_ids")),
                "runtime_ready": bool(hypothesis.get("runtime_ready")),
                "staple_tier": hypothesis.get("staple_tier") or "",
            },
            "existing_packages": compact_existing_packages(micro_row),
            "attempted_package_cuts": compact_attempted_cuts(safe_row),
            "blockers": blockers,
        }
        rows.append(row)
    return rows


def missing_inputs(payloads: Mapping[str, Mapping[str, Any]]) -> list[str]:
    return [key for key, payload in payloads.items() if not payload]


def build_report(
    *,
    trace_contract: Mapping[str, Any],
    forced_access_audit: Mapping[str, Any],
    microbenchmark_plan: Mapping[str, Any],
    safe_cut_miner: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    payloads = {
        "trace_contract": trace_contract,
        "forced_access_audit": forced_access_audit,
        "microbenchmark_plan": microbenchmark_plan,
        "safe_cut_miner": safe_cut_miner,
    }
    missing = missing_inputs(payloads)
    target_rows = [] if missing else build_target_evidence_rows(
        trace_contract=trace_contract,
        forced_access_audit=forced_access_audit,
        microbenchmark_plan=microbenchmark_plan,
        safe_cut_miner=safe_cut_miner,
    )
    status_counts = Counter(str(row.get("trace_evidence_status") or "") for row in target_rows)
    prior_reject_targets = [
        row["card_name"]
        for row in target_rows
        if as_int(row.get("prior_reject_count")) > 0
    ]
    cut_safety_blocked_targets = [
        row["card_name"]
        for row in target_rows
        if row.get("safe_cut_status") == "no_current_safe_cut_for_target"
    ]
    if missing:
        status = "topdeck_floor_trace_evidence_inputs_missing_keep_607"
        next_action = "rerun_missing_trace_evidence_inputs"
    elif not target_rows:
        status = "topdeck_floor_trace_evidence_no_targets_keep_607"
        next_action = "refresh_topdeck_floor_trace_target_contract"
    else:
        status = "topdeck_floor_trace_evidence_collected_no_execution_keep_607"
        next_action = "mine_new_nonanchor_same_lane_cut_models_before_any_trace_execution"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_topdeck_floor_trace_evidence_collector",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "external_source_touchpoints": EXTERNAL_SOURCE_TOUCHPOINTS,
        "summary": {
            "decision_status": status,
            "missing_inputs": missing,
            "target_card_count": len(target_rows),
            "trace_collection_allowed_count": sum(
                1 for row in target_rows if row.get("trace_collection_allowed_now")
            ),
            "forced_access_allowed_now": False,
            "structure_matrix_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "microbenchmark_runnable_count": sum(
                1 for row in target_rows if row.get("microbenchmark_runnable_now")
            ),
            "seed_safe_same_lane_count": sum(as_int(row.get("seed_safe_same_lane_count")) for row in target_rows),
            "prior_reject_target_count": len(prior_reject_targets),
            "cut_safety_blocked_target_count": len(cut_safety_blocked_targets),
            "status_counts": dict(sorted(status_counts.items())),
            "prior_reject_targets": prior_reject_targets,
            "cut_safety_blocked_targets": cut_safety_blocked_targets,
            "recommended_next_action": next_action,
        },
        "target_evidence_rows": target_rows,
        "source_evidence": {
            "trace_contract_summary": summary(trace_contract),
            "forced_access_audit_summary": summary(forced_access_audit),
            "microbenchmark_plan_summary": summary(microbenchmark_plan),
            "safe_cut_miner_summary": summary(safe_cut_miner),
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "allow_deck_mutation_now": False,
            "allow_candidate_materialization_now": False,
            "allow_forced_access_now": False,
            "allow_structure_matrix_now": False,
            "allow_natural_battle_gate_now": False,
            "promotion_allowed": False,
            "reason": (
                "Current topdeck targets have trace designs and external/source support, "
                "but every target remains blocked from execution by prior rejects, cut safety, "
                "or the absence of a named same-lane nonanchor cut."
            ),
            "next_actions": [
                next_action,
                "do_not_run_forced_access_until_a_safe_cut_model_exists",
                "do_not_convert target trace rows into matrix rows",
                "keep Mana Vault and The One Ring blocked until same-lane trace proof exists",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = summary(payload)
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Topdeck Floor Trace Evidence Collector",
        "",
        f"- Generated at: `{payload.get('generated_at')}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload.get('status')}`",
        f"- Target card count: `{summary_row.get('target_card_count')}`",
        f"- Trace collection allowed count: `{summary_row.get('trace_collection_allowed_count')}`",
        f"- Microbenchmark runnable count: `{summary_row.get('microbenchmark_runnable_count')}`",
        f"- Seed-safe same-lane count: `{summary_row.get('seed_safe_same_lane_count')}`",
        f"- Prior-reject target count: `{summary_row.get('prior_reject_target_count')}`",
        f"- Cut-safety blocked target count: `{summary_row.get('cut_safety_blocked_target_count')}`",
        f"- Forced access allowed now: `{str(summary_row.get('forced_access_allowed_now')).lower()}`",
        f"- Structure matrix allowed now: `{str(summary_row.get('structure_matrix_allowed_now')).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary_row.get('natural_battle_gate_allowed_now')).lower()}`",
        f"- Promotion allowed now: `{str(summary_row.get('promotion_allowed_now')).lower()}`",
        f"- Recommended next action: `{summary_row.get('recommended_next_action')}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Target Evidence", ""])
    lines.extend(
        [
            "| Rank | Card | Status | Prior Rejects | Safe Cut | Runnable | Next Action |",
            "| ---: | --- | --- | ---: | --- | --- | --- |",
        ]
    )
    for row in as_list(payload.get("target_evidence_rows")):
        if not isinstance(row, Mapping):
            continue
        lines.append(
            "| {rank} | `{card}` | `{status}` | {rejects} | `{safe}` | `{runnable}` | {next_action} |".format(
                rank=row.get("learning_priority_rank"),
                card=row.get("card_name"),
                status=row.get("trace_evidence_status"),
                rejects=row.get("prior_reject_count"),
                safe=row.get("safe_cut_status"),
                runnable=str(bool(row.get("microbenchmark_runnable_now"))).lower(),
                next_action=row.get("next_action"),
            )
        )
    lines.extend(["", "## External Source Touchpoints", ""])
    for row in as_list(payload.get("external_source_touchpoints")):
        if isinstance(row, Mapping):
            lines.append(f"- `{row.get('source')}`: {row.get('url')} - {row.get('use')}")
    lines.extend(["", "## Decision", ""])
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision.get('keep_607_as_protected_baseline')).lower()}`")
    lines.append(f"- allow_deck_mutation_now: `{str(decision.get('allow_deck_mutation_now')).lower()}`")
    lines.append(f"- allow_candidate_materialization_now: `{str(decision.get('allow_candidate_materialization_now')).lower()}`")
    lines.append(f"- allow_forced_access_now: `{str(decision.get('allow_forced_access_now')).lower()}`")
    lines.append(f"- allow_structure_matrix_now: `{str(decision.get('allow_structure_matrix_now')).lower()}`")
    lines.append(f"- allow_natural_battle_gate_now: `{str(decision.get('allow_natural_battle_gate_now')).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision.get('promotion_allowed')).lower()}`")
    lines.append(f"- reason: {decision.get('reason')}")
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
    parser.add_argument("--trace-contract", type=Path, default=DEFAULT_TRACE_CONTRACT)
    parser.add_argument("--forced-access-audit", type=Path, default=DEFAULT_FORCED_ACCESS_AUDIT)
    parser.add_argument("--microbenchmark-plan", type=Path, default=DEFAULT_MICROBENCHMARK_PLAN)
    parser.add_argument("--safe-cut-miner", type=Path, default=DEFAULT_SAFE_CUT_MINER)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "trace_contract": args.trace_contract,
        "forced_access_audit": args.forced_access_audit,
        "microbenchmark_plan": args.microbenchmark_plan,
        "safe_cut_miner": args.safe_cut_miner,
    }
    payload = build_report(
        trace_contract=read_json(args.trace_contract),
        forced_access_audit=read_json(args.forced_access_audit),
        microbenchmark_plan=read_json(args.microbenchmark_plan),
        safe_cut_miner=read_json(args.safe_cut_miner),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "target_card_count": payload["summary"]["target_card_count"],
                "json": rel(json_path),
                "markdown": rel(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
