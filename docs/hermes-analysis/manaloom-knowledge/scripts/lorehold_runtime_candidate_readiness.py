#!/usr/bin/env python3
"""Summarize Lorehold runtime candidates without conflating card and cut results.

This read-only report joins the current runtime-gap family queue, PostgreSQL
package manifests, precheck blockers, and hypothesis queue. It answers a narrow
planning question: which cards are runtime/package blocked, which package swaps
already failed because of the chosen cut, and what can be tested next without
repeating a known bad add/cut pair.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_RUNTIME_QUEUE = REPORT_DIR / "lorehold_runtime_gap_family_queue_20260628_v6_current_miner.json"
DEFAULT_ACCESS_MODEL = REPORT_DIR / "lorehold_access_cut_model_20260628_v2.json"
DEFAULT_HYPOTHESIS_QUEUE = REPORT_DIR / "lorehold_next_hypothesis_queue_20260628_v10_runtime_pg245.json"
DEFAULT_MANIFESTS = [
    REPORT_DIR / "pg245_lorehold_topdeck_damage_runtime_20260628_manifest.json",
    REPORT_DIR / "pg244_hidden_retreat_runtime_scope_20260628_v1_manifest.json",
]
DEFAULT_PRECHECK_BLOCKERS = [
    REPORT_DIR / "pg245_lorehold_topdeck_damage_runtime_20260628_precheck_blocked.json",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def read_existing(paths: Iterable[Path]) -> list[tuple[Path, dict[str, Any]]]:
    return [(path, read_json(path)) for path in paths if path.exists()]


def card_rows_from_runtime_queue(runtime_queue: dict[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for family in runtime_queue.get("family_queue") or []:
        for card in family.get("cards") or []:
            name = str(card.get("card_name") or "")
            if not name:
                continue
            rows[name] = {
                "card_name": name,
                "source": "runtime_gap_family_queue",
                "family_id": family.get("family_id"),
                "family_support_status": family.get("support_status"),
                "batch_strategy": family.get("batch_strategy"),
                "promotion_lane": card.get("promotion_lane"),
                "effect": card.get("effect"),
                "battle_model_scope": card.get("battle_model_scope"),
                "ready_for_structured_pull": bool(card.get("ready_for_structured_pull")),
                "candidate_lane": card.get("candidate_lane"),
                "candidate_score": int(card.get("candidate_score") or 0),
                "variant_decks": list(card.get("variant_decks") or []),
                "variant_deck_count": int(card.get("variant_deck_count") or 0),
                "xmage_class": card.get("xmage_class"),
            }
    return rows


def access_model_rows(access_model: dict[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for card in access_model.get("candidates") or []:
        name = str(card.get("card_name") or "")
        if not name:
            continue
        rules = card.get("rule_summary") or {}
        rows[name] = {
            "card_name": name,
            "source": "access_cut_model",
            "family_id": "access_density",
            "family_support_status": "access_model_candidate",
            "batch_strategy": "pg_apply_or_runtime_upgrade_before_gate",
            "promotion_lane": "access_density_candidate",
            "effect": "",
            "battle_model_scope": "",
            "ready_for_structured_pull": False,
            "candidate_lane": card.get("lane"),
            "candidate_score": int(card.get("score") or 0),
            "variant_decks": list((card.get("variant_usage") or {}).get("deck_ids") or []),
            "variant_deck_count": int((card.get("variant_usage") or {}).get("deck_count") or 0),
            "xmage_class": "",
            "access_targets": list(card.get("access_targets") or []),
            "runtime_blockers": list(card.get("blockers") or []),
            "active_rule_count": int(rules.get("active_rule_count") or 0),
            "review_only_rule_count": int(rules.get("review_only_rule_count") or 0),
        }
    return rows


def package_index(manifests: list[tuple[Path, dict[str, Any]]]) -> dict[str, list[dict[str, Any]]]:
    index: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for path, manifest in manifests:
        for card in manifest.get("selected_card_names") or []:
            index[str(card)].append(
                {
                    "deploy_id": manifest.get("deploy_id"),
                    "status": manifest.get("status"),
                    "manifest": str(path),
                    "apply_gate": manifest.get("apply_gate"),
                    "files": manifest.get("files") or {},
                    "family_counts": manifest.get("family_counts") or {},
                }
            )
    return dict(index)


def precheck_index(blockers: list[tuple[Path, dict[str, Any]]]) -> dict[str, list[dict[str, Any]]]:
    index: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for path, blocker in blockers:
        for card in blocker.get("selected_cards") or []:
            index[str(card)].append(
                {
                    "deploy_id": blocker.get("deploy_id"),
                    "status": blocker.get("status"),
                    "blocked_step": blocker.get("blocked_step"),
                    "sanitized_error": blocker.get("sanitized_error"),
                    "report": str(path),
                    "next_required_sequence": blocker.get("next_required_sequence") or [],
                }
            )
    return dict(index)


def hypothesis_rows(hypothesis_queue: dict[str, Any]) -> dict[str, list[dict[str, Any]]]:
    rows: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in hypothesis_queue.get("queue") or hypothesis_queue.get("hypotheses") or []:
        for card in row.get("adds") or []:
            rows[str(card)].append(
                {
                    "package_key": row.get("package_key"),
                    "status": row.get("status"),
                    "adds": row.get("adds") or [],
                    "cuts": row.get("cuts") or [],
                    "lane": row.get("lane"),
                    "prior_gate": row.get("prior_gate") or {},
                    "targets": row.get("targets") or [],
                    "runtime_package_readiness": (row.get("runtime_package_readiness") or {}).get(str(card), {}),
                    "cut_guardrails": row.get("cut_guardrails") or {},
                }
            )
    return dict(rows)


def card_readiness_status(
    *,
    card: dict[str, Any],
    packages: list[dict[str, Any]],
    blockers: list[dict[str, Any]],
    hypotheses: list[dict[str, Any]],
) -> tuple[str, str]:
    if blockers:
        return (
            "pg_precheck_blocked",
            "Rerun PostgreSQL precheck; do not apply package until every selected card has a matched card row.",
        )
    if packages:
        return (
            "pg_package_prepared_pending_apply_approval",
            "Apply only after explicit approval for the exact precheck/apply/postcheck command sequence, then sync PG to Hermes.",
        )
    if card.get("promotion_lane") == "split_family_scope_review_required":
        return (
            "split_scope_review_required",
            "Split the family scope and write focused runtime tests before creating a metadata package.",
        )
    if card.get("promotion_lane") == "mapper_metadata_or_test_scenario_required":
        return (
            "manual_mapper_required",
            "Add mapper metadata or a focused test scenario before treating the XMage source as executable.",
        )
    if card.get("runtime_blockers"):
        return (
            "runtime_model_blocked",
            "Resolve local runtime blockers before testing deck swaps.",
        )
    if hypotheses and all(str(row.get("status") or "").startswith("tested_negative") for row in hypotheses):
        return (
            "swap_negative_not_card_global_reject",
            "Do not repeat the same add/cut pair; only retest with a new seed-safe cut and preserved telemetry.",
        )
    return ("review_required", "Review current evidence before gate.")


def build_report(
    *,
    runtime_queue: dict[str, Any],
    access_model: dict[str, Any],
    hypothesis_queue: dict[str, Any],
    manifests: list[tuple[Path, dict[str, Any]]],
    precheck_blockers: list[tuple[Path, dict[str, Any]]],
    runtime_queue_path: Path = DEFAULT_RUNTIME_QUEUE,
    access_model_path: Path = DEFAULT_ACCESS_MODEL,
    hypothesis_queue_path: Path = DEFAULT_HYPOTHESIS_QUEUE,
) -> dict[str, Any]:
    cards = card_rows_from_runtime_queue(runtime_queue)
    for name, row in access_model_rows(access_model).items():
        cards.setdefault(name, row)

    packages_by_card = package_index(manifests)
    blockers_by_card = precheck_index(precheck_blockers)
    hypotheses_by_card = hypothesis_rows(hypothesis_queue)

    rows: list[dict[str, Any]] = []
    for name in sorted(cards):
        card = cards[name]
        packages = packages_by_card.get(name, [])
        blockers = blockers_by_card.get(name, [])
        hypotheses = hypotheses_by_card.get(name, [])
        status, next_action = card_readiness_status(
            card=card,
            packages=packages,
            blockers=blockers,
            hypotheses=hypotheses,
        )
        cut_specific_rejects = [
            row
            for row in hypotheses
            if str(row.get("status") or "").startswith("tested_negative")
        ]
        rows.append(
            {
                **card,
                "status": status,
                "next_action": next_action,
                "pg_packages": packages,
                "pg_precheck_blockers": blockers,
                "cut_specific_negative_count": len(cut_specific_rejects),
                "cut_specific_negatives": cut_specific_rejects,
                "card_global_reject": False,
            }
        )

    status_counts = Counter(row["status"] for row in rows)
    promotion_counts = Counter(row.get("promotion_lane") or "" for row in rows)
    priority_order = {
        "pg_precheck_blocked": 0,
        "pg_package_prepared_pending_apply_approval": 1,
        "split_scope_review_required": 2,
        "manual_mapper_required": 3,
        "runtime_model_blocked": 4,
        "swap_negative_not_card_global_reject": 5,
        "review_required": 6,
    }
    rows.sort(
        key=lambda row: (
            priority_order.get(row["status"], 99),
            -int(row.get("candidate_score") or 0),
            row["card_name"],
        )
    )
    return {
        "generated_at": utc_now(),
        "postgres_writes": False,
        "source_db_mutated": False,
        "runtime_queue": str(runtime_queue_path),
        "access_model": str(access_model_path),
        "hypothesis_queue": str(hypothesis_queue_path),
        "manifests": [str(path) for path, _payload in manifests],
        "precheck_blockers": [str(path) for path, _payload in precheck_blockers],
        "summary": {
            "card_count": len(rows),
            "status_counts": dict(sorted(status_counts.items())),
            "promotion_lane_counts": dict(sorted(promotion_counts.items())),
            "pg_precheck_blocked_count": status_counts.get("pg_precheck_blocked", 0),
            "pg_package_prepared_pending_apply_approval_count": status_counts.get(
                "pg_package_prepared_pending_apply_approval", 0
            ),
            "split_scope_review_required_count": status_counts.get("split_scope_review_required", 0),
            "manual_mapper_required_count": status_counts.get("manual_mapper_required", 0),
            "cut_specific_negative_count": sum(int(row.get("cut_specific_negative_count") or 0) for row in rows),
            "recommended_next_action": "rerun_pg245_precheck_then_sync_or_split_scope_runtime_families",
        },
        "cards": rows,
    }


def render_markdown(report: dict[str, Any]) -> str:
    summary = report["summary"]
    lines = [
        "# Lorehold Runtime Candidate Readiness - 2026-06-28",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Runtime queue: `{report['runtime_queue']}`",
        f"- Access model: `{report['access_model']}`",
        f"- Hypothesis queue: `{report['hypothesis_queue']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "",
        "## Summary",
        "",
        f"- Cards reviewed: `{summary['card_count']}`",
        f"- Status counts: `{json.dumps(summary['status_counts'], sort_keys=True)}`",
        f"- Promotion lanes: `{json.dumps(summary['promotion_lane_counts'], sort_keys=True)}`",
        f"- Cut-specific negatives: `{summary['cut_specific_negative_count']}`",
        f"- Recommended next action: `{summary['recommended_next_action']}`",
        "",
        "## Priority Cards",
        "",
        "| Rank | Card | Status | Family | Lane | Effect | Cut-specific negatives | Next action |",
        "| ---: | --- | --- | --- | --- | --- | ---: | --- |",
    ]
    for index, row in enumerate(report["cards"][:20], start=1):
        lines.append(
            "| {rank} | `{card}` | `{status}` | `{family}` | `{lane}` | `{effect}` | {negatives} | {action} |".format(
                rank=index,
                card=row["card_name"],
                status=row["status"],
                family=row.get("family_id") or "",
                lane=row.get("promotion_lane") or row.get("candidate_lane") or "",
                effect=row.get("effect") or "",
                negatives=int(row.get("cut_specific_negative_count") or 0),
                action=row["next_action"],
            )
        )
    lines.extend(["", "## Package Blockers", ""])
    for row in report["cards"]:
        if not row.get("pg_packages") and not row.get("pg_precheck_blockers") and not row.get("cut_specific_negatives"):
            continue
        lines.append(f"### {row['card_name']}")
        for package in row.get("pg_packages") or []:
            files = package.get("files") or {}
            lines.append(
                f"- PG package `{package.get('deploy_id')}` status `{package.get('status')}`; apply `{files.get('apply') or '-'}`"
            )
        for blocker in row.get("pg_precheck_blockers") or []:
            lines.append(
                f"- Precheck blocker `{blocker.get('status')}` at `{blocker.get('blocked_step')}`: {blocker.get('sanitized_error')}"
            )
        for negative in row.get("cut_specific_negatives") or []:
            prior = negative.get("prior_gate") or {}
            cuts = ", ".join(negative.get("cuts") or [])
            lines.append(
                f"- Negative swap `{negative.get('package_key')}` cut `{cuts}`: `{prior.get('decision') or negative.get('status')}`, delta `{prior.get('delta_pp')}` pp"
            )
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime-queue", type=Path, default=DEFAULT_RUNTIME_QUEUE)
    parser.add_argument("--access-model", type=Path, default=DEFAULT_ACCESS_MODEL)
    parser.add_argument("--hypothesis-queue", type=Path, default=DEFAULT_HYPOTHESIS_QUEUE)
    parser.add_argument("--manifest", type=Path, action="append")
    parser.add_argument("--precheck-blocker", type=Path, action="append")
    parser.add_argument("--stem", default="lorehold_runtime_candidate_readiness_20260628_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    manifests = read_existing(args.manifest or DEFAULT_MANIFESTS)
    blockers = read_existing(args.precheck_blocker or DEFAULT_PRECHECK_BLOCKERS)
    report = build_report(
        runtime_queue=read_json(args.runtime_queue),
        access_model=read_json(args.access_model),
        hypothesis_queue=read_json(args.hypothesis_queue),
        manifests=manifests,
        precheck_blockers=blockers,
        runtime_queue_path=args.runtime_queue,
        access_model_path=args.access_model,
        hypothesis_queue_path=args.hypothesis_queue,
    )
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(report, ensure_ascii=True, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(report), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(report["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
