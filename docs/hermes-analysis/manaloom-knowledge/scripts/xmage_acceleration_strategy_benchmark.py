#!/usr/bin/env python3
"""Benchmark XMage -> ManaLoom acceleration strategies against the real queue.

This is an operational benchmark, not a runtime simulator. It compares candidate
absorption strategies with measurable queue evidence:

- cards touched before first value;
- current queue cards covered or skipped;
- exact-scope cluster leverage;
- fragmentation risk;
- available XMage test references;
- dependency on PostgreSQL apply/sync gates.

The goal is to make the strategy decision repeatable and falsifiable as the
deck queue changes.
"""

from __future__ import annotations

import argparse
import json
import math
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DEFAULT_REPORT_DIR = Path(__file__).resolve().parent.parent.parent / "master_optimizer_reports"
DEFAULT_PROPOSAL_REPORT = (
    DEFAULT_REPORT_DIR / "xmage_current_replay_batch_pipeline_20260624_expanded_608_619_real_v5_proposals.json"
)
DEFAULT_EFFECTIVE_QUEUE_REPORT = (
    DEFAULT_REPORT_DIR / "xmage_effective_queue_20260624_expanded_608_619_real_v2.json"
)
DEFAULT_INVENTORY_REPORT = DEFAULT_REPORT_DIR / "xmage_engine_absorption_inventory_20260623.json"
DEFAULT_TEST_MINER_REPORT = DEFAULT_REPORT_DIR / "xmage_test_scenario_miner_targeted_damage_20260624.json"


PACKAGE_PREPARED_LANE = "package_already_prepared"
PACKAGE_READY_LANE = "package_ready_unprepared"
SPLIT_SCOPE_LANE = "split_scope_backlog"
RUNTIME_LANE = "runtime_family_backlog"
MANUAL_LANE = "manual_mapper_backlog"
BLOCKED_LANE = "blocked_missing_xmage_source"


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def safe_div(numerator: float, denominator: float) -> float:
    if denominator == 0:
        return 0.0
    return numerator / denominator


def clamp(value: float, low: float = 0.0, high: float = 100.0) -> float:
    return max(low, min(high, value))


def status_counts(proposals: list[dict[str, Any]]) -> Counter[str]:
    return Counter(str(item.get("proposal_status") or "") for item in proposals)


def scope_groups(proposals: list[dict[str, Any]]) -> dict[tuple[str, str, str], list[dict[str, Any]]]:
    groups: dict[tuple[str, str, str], list[dict[str, Any]]] = defaultdict(list)
    for proposal in proposals:
        key = (
            str(proposal.get("family_id") or ""),
            str(proposal.get("effect") or ""),
            str(proposal.get("battle_model_scope") or ""),
        )
        groups[key].append(proposal)
    return groups


def family_groups(proposals: list[dict[str, Any]]) -> dict[tuple[str, str], list[dict[str, Any]]]:
    groups: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for proposal in proposals:
        key = (
            str(proposal.get("family_id") or ""),
            str(proposal.get("effect") or ""),
        )
        groups[key].append(proposal)
    return groups


def proposals_by_status(proposals: list[dict[str, Any]], status: str) -> list[dict[str, Any]]:
    return [item for item in proposals if item.get("proposal_status") == status]


def top_scope(proposals: list[dict[str, Any]]) -> dict[str, Any] | None:
    groups = scope_groups(proposals)
    if not groups:
        return None
    key, cards = sorted(groups.items(), key=lambda item: (-len(item[1]), item[0]))[0]
    return {
        "family_id": key[0],
        "effect": key[1],
        "battle_model_scope": key[2],
        "count": len(cards),
        "cards": sorted(str(card.get("card_name") or "") for card in cards),
    }


def top_family_fragmentation(proposals: list[dict[str, Any]]) -> dict[str, Any] | None:
    groups = family_groups(proposals)
    if not groups:
        return None
    key, cards = sorted(groups.items(), key=lambda item: (-len(item[1]), item[0]))[0]
    scopes = Counter(str(card.get("battle_model_scope") or "") for card in cards)
    return {
        "family_id": key[0],
        "effect": key[1],
        "count": len(cards),
        "scope_count": len(scopes),
        "top_scopes": [{"battle_model_scope": scope, "count": count} for scope, count in scopes.most_common(8)],
        "cards": sorted(str(card.get("card_name") or "") for card in cards),
    }


def full_scope_count(proposals: list[dict[str, Any]]) -> int:
    return len(scope_groups(proposals))


def score_strategy(
    *,
    immediate_cards: int,
    work_units: float,
    confidence: float,
    reuse: float,
    risk: float,
    queue_size: int,
) -> dict[str, float]:
    cards_per_unit = safe_div(immediate_cards, work_units)
    immediate_ratio = safe_div(immediate_cards, queue_size)
    speed = clamp(math.log2(cards_per_unit + 1) * 18 + immediate_ratio * 35)
    score = clamp((speed * 0.38) + (confidence * 0.27) + (reuse * 0.25) - (risk * 0.20) + 10)
    return {
        "cards_per_work_unit": round(cards_per_unit, 3),
        "immediate_queue_ratio": round(immediate_ratio, 4),
        "speed_score": round(speed, 2),
        "confidence_score": round(confidence, 2),
        "reuse_score": round(reuse, 2),
        "risk_score": round(risk, 2),
        "decision_score": round(score, 2),
    }


def test_miner_summary(report: dict[str, Any] | None) -> dict[str, Any]:
    if not report:
        return {
            "requested_card_count": 0,
            "cards_with_test_reference": 0,
            "usable_scenario_candidate_count": 0,
            "reference_ratio": 0.0,
            "usable_ratio": 0.0,
        }
    summary = report.get("summary") or {}
    requested = int(summary.get("requested_card_count") or 0)
    referenced = int(summary.get("cards_with_test_reference") or 0)
    usable = int(summary.get("usable_scenario_candidate_count") or 0)
    return {
        "requested_card_count": requested,
        "cards_with_test_reference": referenced,
        "usable_scenario_candidate_count": usable,
        "reference_ratio": round(safe_div(referenced, requested), 4),
        "usable_ratio": round(safe_div(usable, requested), 4),
    }


def build_strategy_rows(
    *,
    proposals: list[dict[str, Any]],
    effective_queue: dict[str, Any],
    inventory: dict[str, Any],
    test_miner: dict[str, Any] | None,
) -> list[dict[str, Any]]:
    queue_size = len(proposals)
    proposal_counts = status_counts(proposals)
    lane_counts = ((effective_queue.get("effective_queue") or {}).get("lane_counts") or {})
    inventory_summary = inventory.get("summary") or {}

    pg_ready_total = int(proposal_counts.get("batch_pg_candidate_after_precheck") or 0)
    package_prepared = int(lane_counts.get(PACKAGE_PREPARED_LANE) or 0)
    package_ready_unprepared = int(lane_counts.get(PACKAGE_READY_LANE) or 0)
    split_proposals = proposals_by_status(proposals, "split_family_scope_review_required")
    runtime_proposals = proposals_by_status(proposals, "runtime_family_implementation_required")
    manual_proposals = proposals_by_status(proposals, "mapper_metadata_or_test_scenario_required")

    top_split = top_scope(split_proposals) or {}
    top_runtime_scope = top_scope(runtime_proposals) or {}
    top_runtime_family = top_family_fragmentation(runtime_proposals) or {}
    split_scope_total = full_scope_count(split_proposals)
    runtime_scope_total = full_scope_count(runtime_proposals)
    test_summary = test_miner_summary(test_miner)

    card_impl_files = int(inventory_summary.get("card_implementation_files") or 0)
    effect_files = int(inventory_summary.get("effect_files") or 0)
    test_files = int(inventory_summary.get("test_files") or 0)
    java_files_total = int(inventory_summary.get("java_files_total") or 0)

    rows: list[dict[str, Any]] = []

    def add(
        *,
        strategy_id: str,
        title: str,
        immediate_cards: int,
        work_units: float,
        confidence: float,
        reuse: float,
        risk: float,
        verdict: str,
        evidence: dict[str, Any],
        next_action: str,
    ) -> None:
        metrics = score_strategy(
            immediate_cards=immediate_cards,
            work_units=work_units,
            confidence=confidence,
            reuse=reuse,
            risk=risk,
            queue_size=queue_size,
        )
        rows.append(
            {
                "strategy_id": strategy_id,
                "title": title,
                "verdict": verdict,
                "immediate_cards": immediate_cards,
                "work_units": round(work_units, 3),
                "metrics": metrics,
                "evidence": evidence,
                "next_action": next_action,
            }
        )

    add(
        strategy_id="full_xmage_first",
        title="Analyze/port the whole XMage corpus before queue work",
        immediate_cards=queue_size,
        work_units=max(card_impl_files, 1),
        confidence=62,
        reuse=92,
        risk=88,
        verdict="reject_as_primary",
        evidence={
            "card_implementation_files": card_impl_files,
            "java_files_total": java_files_total,
            "current_queue_cards": queue_size,
            "work_multiplier_vs_current_queue": round(safe_div(card_impl_files, queue_size), 2),
            "source_basis": "local XMage inventory plus official XMage repository structure",
        },
        next_action="Use full inventory as reference only; do not block deck closure on global analysis.",
    )

    add(
        strategy_id="card_by_card_queue",
        title="Inspect each current proposal card independently",
        immediate_cards=queue_size,
        work_units=max(queue_size, 1),
        confidence=68,
        reuse=18,
        risk=55,
        verdict="reject_as_default",
        evidence={
            "current_queue_cards": queue_size,
            "proposal_status_counts": dict(proposal_counts),
            "reason": "Every card can eventually be handled, but each unit produces little reusable knowledge.",
        },
        next_action="Keep as fallback for exception cards only.",
    )

    add(
        strategy_id="package_manifest_first",
        title="Stop rebuilding prepared PG packages and apply them through gates",
        immediate_cards=package_prepared + package_ready_unprepared,
        work_units=max(len((effective_queue.get("effective_queue") or {}).get("prepared_packages") or []), 1),
        confidence=86,
        reuse=63,
        risk=32,
        verdict="use_immediately_with_pg_approval",
        evidence={
            "pg_ready_total": pg_ready_total,
            "package_already_prepared": package_prepared,
            "package_ready_unprepared": package_ready_unprepared,
            "prepared_package_count": len((effective_queue.get("effective_queue") or {}).get("prepared_packages") or []),
            "required_gate": "precheck, approved apply, postcheck, PG->Hermes sync, focused audit",
        },
        next_action="Do not remodel these cards; move them through the PostgreSQL governance gate when approved.",
    )

    add(
        strategy_id="exact_scope_cluster_first",
        title="Batch the largest exact split-scope clusters",
        immediate_cards=int(top_split.get("count") or 0),
        work_units=1,
        confidence=74,
        reuse=82,
        risk=42,
        verdict="use_as_next_modeling_lane",
        evidence={
            "split_scope_backlog": len(split_proposals),
            "split_scope_unique_scope_count": split_scope_total,
            "top_scope": top_split,
            "test_miner": test_summary,
        },
        next_action=(
            "Split the top scope into subpatterns before PG promotion; targeted_damage_variant_v1 is useful "
            "as a queue, not as one executable behavior."
        ),
    )

    runtime_fragmentation = int(top_runtime_family.get("scope_count") or 0)
    runtime_risk = 45 if runtime_fragmentation <= 2 else 70
    add(
        strategy_id="runtime_exact_scope_first",
        title="Open runtime only for homogeneous exact scopes",
        immediate_cards=int(top_runtime_scope.get("count") or 0),
        work_units=1,
        confidence=78,
        reuse=65,
        risk=runtime_risk,
        verdict="use_selectively",
        evidence={
            "runtime_backlog": len(runtime_proposals),
            "runtime_unique_scope_count": runtime_scope_total,
            "top_runtime_scope": top_runtime_scope,
            "largest_raw_runtime_family": top_runtime_family,
            "fragmentation_warning": (
                "largest raw runtime family is fragmented"
                if int(top_runtime_family.get("scope_count") or 0) > int(top_runtime_scope.get("count") or 0)
                else "none"
            ),
        },
        next_action="Start with damage_all/destroy_all scopes; defer token_maker until taxonomy support exists.",
    )

    add(
        strategy_id="test_miner_first",
        title="Mine XMage tests before writing local ManaLoom tests",
        immediate_cards=int(test_summary.get("cards_with_test_reference") or 0),
        work_units=max(int(test_summary.get("requested_card_count") or 1), 1),
        confidence=72,
        reuse=54,
        risk=47,
        verdict="use_as_evidence_gate_not_primary_queue",
        evidence={
            "xmage_test_files": test_files,
            "pilot_scope": "targeted_damage_variant_v1",
            "test_miner": test_summary,
            "interpretation": "test references are valuable, but sparse for the current top split-scope pilot",
        },
        next_action="Use test mining to design focused ManaLoom tests, not to decide the whole queue order alone.",
    )

    add(
        strategy_id="pattern_registry_first",
        title="Create a persistent pattern registry before broad manual mapping",
        immediate_cards=len(split_proposals) + len(runtime_proposals),
        work_units=max(effect_files + test_files, 1),
        confidence=70,
        reuse=96,
        risk=58,
        verdict="use_as_shadow_infrastructure",
        evidence={
            "effect_files": effect_files,
            "test_files": test_files,
            "candidate_cards_for_pattern_learning": len(split_proposals) + len(runtime_proposals),
            "manual_mapper_backlog": len(manual_proposals),
            "database_boundary": "registry may persist templates/observations, but executable rules remain gated in card_battle_rules",
        },
        next_action="Seed patterns incrementally from approved clusters; do not wait for a complete global registry.",
    )

    hybrid_cards = package_prepared + package_ready_unprepared + int(top_split.get("count") or 0) + int(
        top_runtime_scope.get("count") or 0
    )
    add(
        strategy_id="hybrid_effective_queue_pattern_registry",
        title="Hybrid: package gate, exact-scope clusters, test miner, and pattern registry",
        immediate_cards=hybrid_cards,
        work_units=4,
        confidence=84,
        reuse=90,
        risk=34,
        verdict="recommended",
        evidence={
            "package_cards_removed_from_modeling": package_prepared + package_ready_unprepared,
            "top_split_scope_cards": int(top_split.get("count") or 0),
            "top_runtime_scope_cards": int(top_runtime_scope.get("count") or 0),
            "test_miner": test_summary,
            "why": "Combines immediate duplicate-work removal with reusable pattern creation and runtime gates.",
        },
        next_action=(
            "Adopt as the project instruction: no broad card-by-card loop while package, exact-scope, or "
            "runtime-homogeneous lanes remain."
        ),
    )

    rows.sort(key=lambda row: (-row["metrics"]["decision_score"], row["strategy_id"]))
    return rows


def build_report(
    *,
    proposal_report: dict[str, Any],
    effective_queue_report: dict[str, Any],
    inventory_report: dict[str, Any],
    test_miner_report: dict[str, Any] | None,
    sources: dict[str, str],
) -> dict[str, Any]:
    proposals = list(proposal_report.get("proposals") or [])
    strategies = build_strategy_rows(
        proposals=proposals,
        effective_queue=effective_queue_report,
        inventory=inventory_report,
        test_miner=test_miner_report,
    )
    recommended = next((row for row in strategies if row["verdict"] == "recommended"), strategies[0] if strategies else {})
    return {
        "generated_at": utc_now(),
        "status": "ready",
        "mutations_performed": [],
        "sources": sources,
        "summary": {
            "proposal_count": len(proposals),
            "recommended_strategy_id": recommended.get("strategy_id"),
            "recommended_decision_score": (recommended.get("metrics") or {}).get("decision_score"),
            "strategy_count": len(strategies),
            "ranking": [
                {
                    "strategy_id": row["strategy_id"],
                    "verdict": row["verdict"],
                    "decision_score": row["metrics"]["decision_score"],
                    "cards_per_work_unit": row["metrics"]["cards_per_work_unit"],
                }
                for row in strategies
            ],
        },
        "strategies": strategies,
        "project_instruction_delta": [
            {
                "area": "queue_order",
                "instruction": "Use effective-lane ordering before any card-by-card work.",
                "proof": "Prepared package and exact-scope lanes close more cards per work unit than independent review.",
            },
            {
                "area": "pattern_registry",
                "instruction": "Persist patterns as reviewable templates/observations; promote execution only through card_battle_rules gates.",
                "proof": "Pattern registry has high reuse but unsafe if treated as executable without local tests.",
            },
            {
                "area": "runtime",
                "instruction": "Open runtime only for homogeneous exact scopes with focused tests.",
                "proof": "The largest raw runtime family can be fragmented and should not drive architecture by raw count.",
            },
            {
                "area": "validation",
                "instruction": "Every promoted rule needs package/apply/sync/audit evidence; Hermes remains cache/lab evidence.",
                "proof": "Project semantic layer and prior PG packages require source-of-truth separation.",
            },
        ],
    }


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# XMage Acceleration Strategy Benchmark",
        "",
        f"- Generated at: `{report.get('generated_at')}`",
        f"- Status: `{report.get('status')}`",
        f"- Mutations performed: `{report.get('mutations_performed')}`",
        "",
        "## Sources",
        "",
    ]
    for key, value in (report.get("sources") or {}).items():
        lines.append(f"- `{key}`: `{value}`")
    summary = report.get("summary") or {}
    lines.extend(
        [
            "",
            "## Summary",
            "",
            f"- Proposal count: `{summary.get('proposal_count')}`",
            f"- Strategy count: `{summary.get('strategy_count')}`",
            f"- Recommended strategy: `{summary.get('recommended_strategy_id')}`",
            f"- Recommended score: `{summary.get('recommended_decision_score')}`",
            "",
            "## Ranking",
            "",
            "| Rank | Strategy | Verdict | Score | Cards/unit |",
            "| --- | --- | --- | ---: | ---: |",
        ]
    )
    for index, row in enumerate(summary.get("ranking") or [], start=1):
        lines.append(
            f"| {index} | `{row.get('strategy_id')}` | `{row.get('verdict')}` | "
            f"{row.get('decision_score')} | {row.get('cards_per_work_unit')} |"
        )
    lines.extend(["", "## Strategy Evidence", ""])
    for row in report.get("strategies") or []:
        metrics = row.get("metrics") or {}
        lines.extend(
            [
                f"### {row.get('strategy_id')}",
                "",
                f"- Title: {row.get('title')}",
                f"- Verdict: `{row.get('verdict')}`",
                f"- Immediate cards: `{row.get('immediate_cards')}`",
                f"- Work units: `{row.get('work_units')}`",
                f"- Decision score: `{metrics.get('decision_score')}`",
                f"- Cards per work unit: `{metrics.get('cards_per_work_unit')}`",
                f"- Confidence/reuse/risk: `{metrics.get('confidence_score')}` / `{metrics.get('reuse_score')}` / `{metrics.get('risk_score')}`",
                f"- Next action: {row.get('next_action')}",
                "- Evidence:",
            ]
        )
        for key, value in (row.get("evidence") or {}).items():
            value_text = json.dumps(value, ensure_ascii=True, sort_keys=True) if isinstance(value, (dict, list)) else str(value)
            lines.append(f"  - `{key}`: {value_text}")
        lines.append("")
    lines.extend(["## Project Instruction Delta", ""])
    for item in report.get("project_instruction_delta") or []:
        lines.append(f"- `{item.get('area')}`: {item.get('instruction')} Proof: {item.get('proof')}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--proposal-report", type=Path, default=DEFAULT_PROPOSAL_REPORT)
    parser.add_argument("--effective-queue-report", type=Path, default=DEFAULT_EFFECTIVE_QUEUE_REPORT)
    parser.add_argument("--inventory-report", type=Path, default=DEFAULT_INVENTORY_REPORT)
    parser.add_argument("--test-miner-report", type=Path, default=DEFAULT_TEST_MINER_REPORT)
    parser.add_argument("--output-prefix", type=Path, required=True)
    return parser.parse_args()


def write_outputs(report: dict[str, Any], output_prefix: Path) -> None:
    output_prefix.parent.mkdir(parents=True, exist_ok=True)
    output_json = output_prefix.with_name(output_prefix.name + ".json")
    output_md = output_prefix.with_name(output_prefix.name + ".md")
    output_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    output_md.write_text(render_markdown(report), encoding="utf-8")


def main() -> int:
    args = parse_args()
    test_miner_report = load_json(args.test_miner_report) if args.test_miner_report.exists() else None
    report = build_report(
        proposal_report=load_json(args.proposal_report),
        effective_queue_report=load_json(args.effective_queue_report),
        inventory_report=load_json(args.inventory_report),
        test_miner_report=test_miner_report,
        sources={
            "proposal_report": str(args.proposal_report),
            "effective_queue_report": str(args.effective_queue_report),
            "inventory_report": str(args.inventory_report),
            "test_miner_report": str(args.test_miner_report) if args.test_miner_report.exists() else "",
        },
    )
    write_outputs(report, args.output_prefix)
    print(f"report_json={args.output_prefix.with_name(args.output_prefix.name + '.json')}")
    print(f"report_md={args.output_prefix.with_name(args.output_prefix.name + '.md')}")
    print(f"recommended={report['summary']['recommended_strategy_id']}")
    print(f"ranking={json.dumps(report['summary']['ranking'], sort_keys=True)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
