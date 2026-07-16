#!/usr/bin/env python3
"""Reconcile local XMage source candidates with live executable catalogs."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCHEMA_VERSION = "xmage_source_catalog_reconciliation_v1"


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _card_id(row: Mapping[str, Any]) -> str:
    return str(row.get("card_id") or "").strip()


def _is_local_source_candidate(row: Mapping[str, Any]) -> bool:
    status = row.get("source_resolution_status")
    if status is not None:
        return status == "local_source_candidate"
    return row.get("source_truth_status") == "xmage_authoritative"


def build_reconciliation(
    queue_payload: Mapping[str, Any],
    coverage_payload: Mapping[str, Any],
) -> dict[str, Any]:
    if coverage_payload.get("schema_version") != "external_card_coverage_closure_v1":
        raise ValueError("coverage report schema is not supported")
    source_rows = [
        row
        for row in queue_payload.get("queue") or []
        if isinstance(row, Mapping)
        and _is_local_source_candidate(row)
    ]
    source_card_ids = [_card_id(row) for row in source_rows]
    if any(not card_id for card_id in source_card_ids):
        raise ValueError("every local source candidate requires card_id")
    if len(set(source_card_ids)) != len(source_card_ids):
        raise ValueError("local source candidate card_id values must be unique")
    coverage_rows = [
        row
        for row in coverage_payload.get("ledger") or []
        if isinstance(row, Mapping) and _card_id(row)
    ]
    coverage_card_ids = [_card_id(row) for row in coverage_rows]
    if len(set(coverage_card_ids)) != len(coverage_card_ids):
        raise ValueError("coverage card_id values must be unique")
    coverage_by_card_id = {
        _card_id(row): row
        for row in coverage_rows
    }
    rows: list[dict[str, Any]] = []
    missing_from_coverage: list[str] = []
    for source in source_rows:
        card_id = _card_id(source)
        coverage = coverage_by_card_id.get(card_id)
        if coverage is None:
            missing_from_coverage.append(card_id or str(source.get("card_name") or ""))
            continue
        lane = str(coverage.get("lane") or "unresolved")
        if lane == "xmage_exact":
            status = "xmage_catalog_confirmed"
        elif lane == "forge_exact":
            status = "forge_catalog_fallback"
        elif lane == "native_verified":
            status = "native_verified_fallback"
        else:
            status = "local_source_candidate_not_executable"
        rows.append(
            {
                "card_id": card_id,
                "oracle_id": source.get("oracle_id"),
                "card_name": source.get("card_name"),
                "status": status,
                "coverage_lane": lane,
                "engine_name_candidate": coverage.get("engine_name_candidate"),
                "residual_family": coverage.get("residual_family"),
                "residual_semantic_family": coverage.get(
                    "residual_semantic_family"
                ),
                "residual_execution_scope": coverage.get(
                    "residual_execution_scope"
                ),
                "xmage_class": source.get("xmage_class"),
                "xmage_path": source.get("xmage_path"),
                "xmage_resolution": source.get("xmage_resolution"),
                "operationally_covered": status
                in {
                    "xmage_catalog_confirmed",
                    "forge_catalog_fallback",
                    "native_verified_fallback",
                },
            }
        )
    status_counts = Counter(row["status"] for row in rows)
    executable = sum(1 for row in rows if row["operationally_covered"])
    valid = not missing_from_coverage and len(rows) == len(source_rows)
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at": utc_now(),
        "status": "pass" if valid else "fail",
        "method": {
            "local_java_path_is_candidate_evidence_only": True,
            "runtime_catalog_confirmation_required": True,
            "forge_is_secondary_for_structured_xmage_gaps": True,
            "read_only": True,
        },
        "summary": {
            "local_source_candidates": len(source_rows),
            "reconciled_rows": len(rows),
            "operationally_covered": executable,
            "residual": len(rows) - executable,
            "coverage_ratio": round(executable / max(len(rows), 1), 6),
            "status_counts": dict(sorted(status_counts.items())),
            "missing_from_coverage": missing_from_coverage,
        },
        "rows": rows,
    }


def write_markdown(payload: Mapping[str, Any], path: Path) -> None:
    summary = payload["summary"]
    lines = [
        "# XMage Source/Catalog Reconciliation",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        "",
        "| Metric | Value |",
        "| --- | ---: |",
        f"| Local source candidates | {summary['local_source_candidates']} |",
        f"| Operationally covered | {summary['operationally_covered']} |",
        f"| Residual | {summary['residual']} |",
        f"| Coverage ratio | {summary['coverage_ratio']:.4%} |",
        "",
        "## Statuses",
        "",
        "| Status | Cards |",
        "| --- | ---: |",
    ]
    for status, count in summary["status_counts"].items():
        lines.append(f"| `{status}` | {count} |")
    residual = [row for row in payload["rows"] if not row["operationally_covered"]]
    lines.extend(["", "## Residual source candidates", ""])
    if residual:
        lines.extend(
            [
                "| Card | Candidate class | Execution scope | Resolution |",
                "| --- | --- | --- | --- |",
            ]
        )
        for row in residual:
            lines.append(
                f"| `{row['card_name']}` | `{row.get('xmage_class') or ''}` | "
                f"`{row.get('residual_execution_scope') or ''}` | "
                f"`{row.get('xmage_resolution') or ''}` |"
            )
    else:
        lines.append("No residual source candidates.")
    lines.extend(
        [
            "",
            "A Java path with a similar class name is not executable truth until the pinned",
            "runtime catalog resolves the exact card identity.",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def load_object(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"expected JSON object: {path}")
    return payload


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--queue", type=Path, required=True)
    parser.add_argument("--coverage", type=Path, required=True)
    parser.add_argument("--out-prefix", type=Path, required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_reconciliation(load_object(args.queue), load_object(args.coverage))
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")
    write_markdown(payload, md_path)
    print(json.dumps({"status": payload["status"], "summary": payload["summary"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if payload["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
