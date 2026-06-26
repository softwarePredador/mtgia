#!/usr/bin/env python3
"""Summarize the effective XMage absorption queue for the current proposal set.

This report is intentionally operational. It subtracts cards that already have
prepared PG package manifests in the report directory so the next action queue
shows what is really left to package or implement.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DEFAULT_REPORT_DIR = Path(__file__).resolve().parent.parent.parent / "master_optimizer_reports"

PACKAGE_PREPARED_LANE = "package_already_prepared"
PACKAGE_READY_LANE = "package_ready_unprepared"
RUNTIME_LANE = "runtime_family_backlog"
SPLIT_SCOPE_LANE = "split_scope_backlog"
MANUAL_LANE = "manual_mapper_backlog"
BLOCKED_LANE = "blocked_missing_xmage_source"

LANE_ORDER = [
    PACKAGE_PREPARED_LANE,
    PACKAGE_READY_LANE,
    SPLIT_SCOPE_LANE,
    RUNTIME_LANE,
    MANUAL_LANE,
    BLOCKED_LANE,
]

PACKAGE_READY_STATUSES = {
    "batch_pg_candidate_after_precheck",
    "partial_batch_pg_candidate_preserve_shadow_rows_after_precheck",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_markdown(path: Path, text: str) -> None:
    path.write_text(text.rstrip() + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--proposal-report", required=True)
    parser.add_argument("--report-dir", default=str(DEFAULT_REPORT_DIR))
    parser.add_argument("--output-prefix", required=True)
    return parser.parse_args()


def load_package_manifests(report_dir: Path) -> tuple[list[dict[str, Any]], dict[str, list[dict[str, Any]]]]:
    manifests: list[dict[str, Any]] = []
    package_index: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for path in sorted(report_dir.glob("pg*_manifest.json")):
        try:
            payload = load_json(path)
        except Exception:
            continue
        selected_card_names = payload.get("selected_card_names") or []
        if not selected_card_names:
            continue
        manifest = {
            "manifest_path": str(path),
            "deploy_id": payload.get("deploy_id"),
            "slug": payload.get("slug"),
            "status": payload.get("status"),
            "generated_at": payload.get("generated_at"),
            "selected_count": int(payload.get("selected_count") or len(selected_card_names)),
            "selected_card_names": list(selected_card_names),
            "family_counts": payload.get("family_counts") or {},
        }
        manifests.append(manifest)
        for card_name in selected_card_names:
            package_index[str(card_name)].append(manifest)
    manifests.sort(key=lambda item: (str(item.get("generated_at") or ""), str(item.get("deploy_id") or "")))
    return manifests, package_index


def effective_lane(proposal: dict[str, Any], package_index: dict[str, list[dict[str, Any]]]) -> str:
    proposal_status = str(proposal.get("proposal_status") or "")
    card_name = str(proposal.get("card_name") or "")
    if proposal_status in PACKAGE_READY_STATUSES:
        if card_name in package_index:
            return PACKAGE_PREPARED_LANE
        return PACKAGE_READY_LANE
    if proposal_status == "runtime_family_implementation_required":
        return RUNTIME_LANE
    if proposal_status == "split_family_scope_review_required":
        return SPLIT_SCOPE_LANE
    if proposal_status == "blocked_missing_xmage_source":
        return BLOCKED_LANE
    return MANUAL_LANE


def grouped_scope_rows(proposals: list[dict[str, Any]], *, limit: int = 15) -> list[dict[str, Any]]:
    bucket: dict[tuple[str, str, str], dict[str, Any]] = {}
    for proposal in proposals:
        key = (
            str(proposal.get("family_id") or ""),
            str(proposal.get("effect") or ""),
            str(proposal.get("battle_model_scope") or ""),
        )
        row = bucket.setdefault(
            key,
            {
                "family_id": key[0],
                "effect": key[1],
                "battle_model_scope": key[2],
                "count": 0,
                "cards": [],
            },
        )
        row["count"] += 1
        row["cards"].append(str(proposal.get("card_name") or ""))
    rows = list(bucket.values())
    rows.sort(key=lambda item: (-item["count"], item["family_id"], item["battle_model_scope"]))
    for row in rows:
        row["cards"] = sorted(row["cards"])
        row["sample_cards"] = row["cards"][:8]
    return rows[:limit]


def grouped_family_rows(proposals: list[dict[str, Any]], *, limit: int = 15) -> list[dict[str, Any]]:
    bucket: dict[tuple[str, str], dict[str, Any]] = {}
    for proposal in proposals:
        key = (
            str(proposal.get("family_id") or ""),
            str(proposal.get("effect") or ""),
        )
        row = bucket.setdefault(
            key,
            {
                "family_id": key[0],
                "effect": key[1],
                "count": 0,
                "scopes": Counter(),
                "cards": [],
            },
        )
        row["count"] += 1
        row["scopes"][str(proposal.get("battle_model_scope") or "")] += 1
        row["cards"].append(str(proposal.get("card_name") or ""))
    rows = list(bucket.values())
    rows.sort(key=lambda item: (-item["count"], item["family_id"], item["effect"]))
    normalized_rows: list[dict[str, Any]] = []
    for row in rows[:limit]:
        normalized_rows.append(
            {
                "family_id": row["family_id"],
                "effect": row["effect"],
                "count": row["count"],
                "scope_count": len(row["scopes"]),
                "top_scopes": [
                    {"battle_model_scope": scope, "count": count}
                    for scope, count in row["scopes"].most_common(5)
                ],
                "sample_cards": sorted(row["cards"])[:8],
            }
        )
    return normalized_rows


def summarize_prepared_packages(
    proposals: list[dict[str, Any]],
    package_index: dict[str, list[dict[str, Any]]],
) -> list[dict[str, Any]]:
    by_deploy: dict[str, dict[str, Any]] = {}
    for proposal in proposals:
        card_name = str(proposal.get("card_name") or "")
        for manifest in package_index.get(card_name, []):
            deploy_id = str(manifest.get("deploy_id") or manifest.get("slug") or "unknown")
            row = by_deploy.setdefault(
                deploy_id,
                {
                    "deploy_id": manifest.get("deploy_id"),
                    "slug": manifest.get("slug"),
                    "status": manifest.get("status"),
                    "generated_at": manifest.get("generated_at"),
                    "manifest_path": manifest.get("manifest_path"),
                    "family_counts": manifest.get("family_counts") or {},
                    "cards_in_current_queue": set(),
                },
            )
            row["cards_in_current_queue"].add(card_name)
    rows = list(by_deploy.values())
    rows.sort(key=lambda item: (str(item.get("generated_at") or ""), str(item.get("deploy_id") or "")))
    normalized_rows: list[dict[str, Any]] = []
    for row in rows:
        cards = sorted(row["cards_in_current_queue"])
        normalized_rows.append(
            {
                **{key: value for key, value in row.items() if key != "cards_in_current_queue"},
                "current_queue_count": len(cards),
                "cards_in_current_queue": cards,
            }
        )
    return normalized_rows


def lane_summary(
    proposals: list[dict[str, Any]],
    package_index: dict[str, list[dict[str, Any]]],
) -> dict[str, Any]:
    lanes: dict[str, list[dict[str, Any]]] = {lane: [] for lane in LANE_ORDER}
    for proposal in proposals:
        lanes[effective_lane(proposal, package_index)].append(proposal)

    summary: dict[str, Any] = {
        "lane_counts": {lane: len(lanes[lane]) for lane in LANE_ORDER},
        "lanes": {},
    }
    for lane in LANE_ORDER:
        lane_cards = lanes[lane]
        summary["lanes"][lane] = {
            "count": len(lane_cards),
            "family_rollups": grouped_family_rows(lane_cards),
            "scope_rollups": grouped_scope_rows(lane_cards),
            "sample_cards": sorted(str(card.get("card_name") or "") for card in lane_cards)[:12],
        }
    summary["prepared_packages"] = summarize_prepared_packages(lanes[PACKAGE_PREPARED_LANE], package_index)
    return summary


def build_recommendations(summary: dict[str, Any]) -> list[dict[str, Any]]:
    recommendations: list[dict[str, Any]] = []
    lane_counts = summary["lane_counts"]

    if lane_counts[PACKAGE_PREPARED_LANE] > 0:
        recommendations.append(
            {
                "priority": "P0",
                "action": "Stop rebuilding cards that already have PG package artifacts.",
                "reason": (
                    f"{lane_counts[PACKAGE_PREPARED_LANE]} current candidates are already covered by prepared "
                    "package manifests in the report directory."
                ),
            }
        )
    if lane_counts[PACKAGE_READY_LANE] > 0:
        top_pg = (summary["lanes"][PACKAGE_READY_LANE]["scope_rollups"] or [None])[0]
        recommendations.append(
            {
                "priority": "P0",
                "action": "Exhaust the unpackaged PG-ready residual before opening new runtime work.",
                "reason": (
                    f"{lane_counts[PACKAGE_READY_LANE]} cards are immediately packageable. "
                    f"Top exact cluster: {top_pg['battle_model_scope']} ({top_pg['count']})"
                    if top_pg
                    else f"{lane_counts[PACKAGE_READY_LANE]} cards are immediately packageable."
                ),
            }
        )
    if lane_counts[SPLIT_SCOPE_LANE] > 0:
        top_split = (summary["lanes"][SPLIT_SCOPE_LANE]["scope_rollups"] or [None])[0]
        recommendations.append(
            {
                "priority": "P1",
                "action": "After the PG-ready lane shrinks, batch the biggest split-scope cluster.",
                "reason": (
                    f"The partially supported backlog is {lane_counts[SPLIT_SCOPE_LANE]} cards. "
                    f"Top exact cluster: {top_split['battle_model_scope']} ({top_split['count']})"
                    if top_split
                    else f"The partially supported backlog is {lane_counts[SPLIT_SCOPE_LANE]} cards."
                ),
            }
        )
    if lane_counts[RUNTIME_LANE] > 0:
        top_runtime_scope = (summary["lanes"][RUNTIME_LANE]["scope_rollups"] or [None])[0]
        top_runtime_family = (summary["lanes"][RUNTIME_LANE]["family_rollups"] or [None])[0]
        fragmented_note = ""
        if (
            top_runtime_family
            and top_runtime_scope
            and int(top_runtime_family.get("count") or 0) > int(top_runtime_scope.get("count") or 0)
            and int(top_runtime_family.get("scope_count") or 0) > 1
        ):
            fragmented_note = (
                f" Largest raw family is {top_runtime_family['family_id']} "
                f"({top_runtime_family['count']} cards across {top_runtime_family['scope_count']} scopes), "
                "so it should wait for taxonomy/test-miner support instead of leading the queue."
            )
        recommendations.append(
            {
                "priority": "P1",
                "action": "Open new runtime only on the most reusable family remaining.",
                "reason": (
                    f"Runtime-only backlog is {lane_counts[RUNTIME_LANE]} cards. "
                    f"Top reusable exact scope cluster: {top_runtime_scope['battle_model_scope']} "
                    f"({top_runtime_scope['count']}).{fragmented_note}"
                    if top_runtime_scope
                    else f"Runtime-only backlog is {lane_counts[RUNTIME_LANE]} cards."
                ),
            }
        )
    if lane_counts[MANUAL_LANE] > 0:
        recommendations.append(
            {
                "priority": "P2",
                "action": "Keep the manual mapper lane last.",
                "reason": (
                    f"{lane_counts[MANUAL_LANE]} cards still need mapper/manual review; this lane should not drive executor architecture."
                ),
            }
        )
    if lane_counts[BLOCKED_LANE] > 0:
        recommendations.append(
            {
                "priority": "P2",
                "action": "Isolate missing-XMage cards as a separate exception lane.",
                "reason": f"{lane_counts[BLOCKED_LANE]} cards are blocked by missing local XMage source.",
            }
        )
    return recommendations


def build_report(
    proposal_report: dict[str, Any],
    *,
    report_dir: Path,
) -> dict[str, Any]:
    manifests, package_index = load_package_manifests(report_dir)
    proposals = list(proposal_report.get("proposals") or [])
    summary = lane_summary(proposals, package_index)
    return {
        "generated_at": utc_now(),
        "status": "ready",
        "mutations_performed": [],
        "proposal_report_path": proposal_report.get("_source_path"),
        "report_dir": str(report_dir),
        "proposal_summary": proposal_report.get("summary") or {},
        "package_manifest_count": len(manifests),
        "package_card_coverage_count": len(package_index),
        "effective_queue": summary,
        "recommendations": build_recommendations(summary),
    }


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# XMage Effective Queue Report",
        "",
        f"- Generated at: `{report.get('generated_at')}`",
        f"- Status: `{report.get('status')}`",
        f"- Proposal report: `{report.get('proposal_report_path')}`",
        f"- Package manifests scanned: `{report.get('package_manifest_count')}`",
        f"- Cards covered by package manifests: `{report.get('package_card_coverage_count')}`",
        "",
        "## Effective Lanes",
        "",
    ]
    lane_counts = (report.get("effective_queue") or {}).get("lane_counts") or {}
    for lane in LANE_ORDER:
        lines.append(f"- `{lane}`: `{lane_counts.get(lane, 0)}`")
    lines.extend(["", "## Recommendations", ""])
    for item in report.get("recommendations") or []:
        lines.append(f"- `{item.get('priority')}` {item.get('action')} Reason: {item.get('reason')}")
    prepared = (report.get("effective_queue") or {}).get("prepared_packages") or []
    if prepared:
        lines.extend(["", "## Prepared Packages Already Covering Current Queue", ""])
        for item in prepared:
            lines.append(
                f"- `{item.get('deploy_id')}` `{item.get('slug')}`: `{item.get('current_queue_count')}` cards"
            )
    lines.extend(["", "## Lane Details", ""])
    lanes = (report.get("effective_queue") or {}).get("lanes") or {}
    for lane in LANE_ORDER:
        lane_data = lanes.get(lane) or {}
        lines.extend([f"### {lane}", ""])
        lines.append(f"- Count: `{lane_data.get('count', 0)}`")
        rollups = lane_data.get("scope_rollups") or []
        if rollups:
            lines.append("- Top scope clusters:")
            for row in rollups[:8]:
                sample_cards = ", ".join(row.get("sample_cards") or [])
                lines.append(
                    f"  - `{row.get('family_id')}` / `{row.get('effect')}` / `{row.get('battle_model_scope')}`: "
                    f"`{row.get('count')}` cards ({sample_cards})"
                )
        else:
            lines.append("- Top scope clusters: `none`")
        lines.append("")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    proposal_report_path = Path(args.proposal_report)
    report_dir = Path(args.report_dir)
    output_prefix = Path(args.output_prefix)
    proposal_report = load_json(proposal_report_path)
    proposal_report["_source_path"] = str(proposal_report_path)
    report = build_report(proposal_report, report_dir=report_dir)
    write_json(output_prefix.with_name(output_prefix.name + ".json"), report)
    write_markdown(output_prefix.with_name(output_prefix.name + ".md"), render_markdown(report))
    print(f"report_json={output_prefix.with_name(output_prefix.name + '.json')}")
    print(f"report_md={output_prefix.with_name(output_prefix.name + '.md')}")
    print(f"lane_counts={json.dumps(report['effective_queue']['lane_counts'], sort_keys=True)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
