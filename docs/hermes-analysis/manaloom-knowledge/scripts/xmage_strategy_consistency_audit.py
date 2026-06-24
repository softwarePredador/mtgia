#!/usr/bin/env python3
"""Audit whether the repo is aligned with the chosen XMage acceleration strategy.

This script checks the project instructions and generated artifacts for the
hybrid strategy:

- effective queue before card-by-card work;
- shadow pattern registry present and non-executable;
- pipeline emits pattern registry artifacts;
- benchmark still recommends the hybrid strategy;
- docs point humans/agents to the same flow.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[4]
DEFAULT_REPORT_DIR = REPO_ROOT / "docs/hermes-analysis/master_optimizer_reports"
DEFAULT_BENCHMARK = DEFAULT_REPORT_DIR / "xmage_acceleration_strategy_benchmark_20260624_expanded_608_619_real_v1.json"
DEFAULT_PATTERN_REGISTRY = DEFAULT_REPORT_DIR / "xmage_pattern_registry_20260624_expanded_608_619_real_v1.json"
DEFAULT_PATTERN_SCHEMA = DEFAULT_REPORT_DIR / "xmage_pattern_registry_20260624_expanded_608_619_real_v1_schema_proposal.sql"
DEFAULT_EFFECTIVE_QUEUE = DEFAULT_REPORT_DIR / "xmage_effective_queue_20260624_expanded_608_619_real_v2.json"
DEFAULT_PIPELINE_MANIFEST = (
    DEFAULT_REPORT_DIR / "xmage_current_replay_batch_pipeline_20260624_expanded_608_619_real_v7_manifest.json"
)
DEFAULT_EXPECTED_EFFECTIVE_DECK_IDS = list(range(608, 620))


@dataclass
class Check:
    name: str
    status: str
    detail: str

    def as_dict(self) -> dict[str, str]:
        return {"name": self.name, "status": self.status, "detail": self.detail}


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def ok(name: str, detail: str) -> Check:
    return Check(name=name, status="pass", detail=detail)


def fail(name: str, detail: str) -> Check:
    return Check(name=name, status="fail", detail=detail)


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def contains_all(path: Path, needles: list[str]) -> Check:
    text = read_text(path)
    missing = [needle for needle in needles if needle not in text]
    if missing:
        return fail(display_path(path), f"missing={missing}")
    return ok(display_path(path), f"contains={needles}")


def audit_pipeline() -> list[Check]:
    path = REPO_ROOT / "docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py"
    return [
        contains_all(
            path,
            [
                "import xmage_pattern_registry_builder as pattern_registry_builder",
                "pattern_registry_builder.build_report",
                "_pattern_registry.json",
                "pattern_status_counts",
            ],
        )
    ]


def audit_docs() -> list[Check]:
    return [
        contains_all(
            REPO_ROOT / "docs/hermes-analysis/README.md",
            [
                "XMAGE_ACCELERATION_STRATEGY_DECISION_2026-06-24.md",
                "hybrid_effective_queue_pattern_registry",
                "pattern registry shadow-only",
            ],
        ),
        contains_all(
            REPO_ROOT / "docs/hermes-analysis/XMAGE_ABSORPTION_WORKFLOW_V2_2026-06-24.md",
            [
                "xmage_pattern_registry_builder.py",
                "promotion_status=shadow_only",
                "Regenerate the acceleration strategy benchmark",
                "Build the shadow pattern registry",
            ],
        ),
        contains_all(
            REPO_ROOT / "docs/hermes-analysis/XMAGE_ACCELERATION_STRATEGY_DECISION_2026-06-24.md",
            [
                "xmage_pattern_registry_builder.py",
                "can_execute_in_battle=false",
                "shadow pattern registry",
                "hybrid_effective_queue_pattern_registry",
            ],
        ),
    ]


def audit_benchmark(path: Path) -> list[Check]:
    report = load_json(path)
    summary = report.get("summary") or {}
    ranking = summary.get("ranking") or []
    first = ranking[0] if ranking else {}
    checks = []
    if summary.get("recommended_strategy_id") == "hybrid_effective_queue_pattern_registry":
        checks.append(ok("benchmark.recommended_strategy", "hybrid_effective_queue_pattern_registry"))
    else:
        checks.append(fail("benchmark.recommended_strategy", str(summary.get("recommended_strategy_id"))))
    if first.get("strategy_id") == "hybrid_effective_queue_pattern_registry":
        checks.append(ok("benchmark.ranking_first", json.dumps(first, sort_keys=True)))
    else:
        checks.append(fail("benchmark.ranking_first", json.dumps(first, sort_keys=True)))
    return checks


def audit_pattern_registry(path: Path) -> list[Check]:
    report = load_json(path)
    summary = report.get("summary") or {}
    checks = []
    if summary.get("promotion_status") == "shadow_only":
        checks.append(ok("pattern_registry.promotion_status", "shadow_only"))
    else:
        checks.append(fail("pattern_registry.promotion_status", str(summary.get("promotion_status"))))
    if int(summary.get("executable_pattern_count") or 0) == 0:
        checks.append(ok("pattern_registry.executable_pattern_count", "0"))
    else:
        checks.append(fail("pattern_registry.executable_pattern_count", str(summary.get("executable_pattern_count"))))
    if int(summary.get("auto_promotable_pattern_count") or 0) == 0:
        checks.append(ok("pattern_registry.auto_promotable_pattern_count", "0"))
    else:
        checks.append(
            fail("pattern_registry.auto_promotable_pattern_count", str(summary.get("auto_promotable_pattern_count")))
        )
    unsafe = [
        pattern.get("pattern_id")
        for pattern in report.get("patterns", [])
        if pattern.get("can_execute_in_battle") or pattern.get("can_auto_promote_to_card_battle_rules")
    ]
    if not unsafe:
        checks.append(ok("pattern_registry.unsafe_pattern_flags", "none"))
    else:
        checks.append(fail("pattern_registry.unsafe_pattern_flags", json.dumps(unsafe, sort_keys=True)))
    return checks


def audit_schema(path: Path) -> list[Check]:
    return [
        contains_all(
            path,
            [
                "CREATE TABLE IF NOT EXISTS public.xmage_pattern_registry",
                "promotion_status <> 'shadow_only'",
                "can_execute_in_battle = FALSE",
                "can_auto_promote_to_card_battle_rules = FALSE",
            ],
        )
    ]


def audit_effective_queue(path: Path) -> list[Check]:
    report = load_json(path)
    counts = ((report.get("effective_queue") or {}).get("lane_counts") or {})
    checks = []
    if int(counts.get("package_ready_unprepared") or 0) == 0:
        checks.append(ok("effective_queue.package_ready_unprepared", "0"))
    else:
        checks.append(fail("effective_queue.package_ready_unprepared", str(counts.get("package_ready_unprepared"))))
    if int(counts.get("package_already_prepared") or 0) > 0:
        checks.append(ok("effective_queue.package_already_prepared", str(counts.get("package_already_prepared"))))
    else:
        checks.append(fail("effective_queue.package_already_prepared", "missing prepared package lane"))
    return checks


def audit_pipeline_manifest(path: Path, expected_effective_deck_ids: list[int]) -> list[Check]:
    report = load_json(path)
    scope = report.get("aggregate_scope") or {}
    checks = []
    effective_deck_ids = set(int(deck_id) for deck_id in scope.get("effective_deck_ids", []))
    missing = sorted(set(int(deck_id) for deck_id in expected_effective_deck_ids) - effective_deck_ids)
    if not missing:
        checks.append(ok("pipeline_manifest.expected_effective_deck_ids", json.dumps(sorted(effective_deck_ids))))
    else:
        checks.append(fail("pipeline_manifest.expected_effective_deck_ids", f"missing={missing}"))

    forced_deck_ids = set(int(deck_id) for deck_id in scope.get("forced_include_deck_ids", []))
    missing_forced = sorted(set(int(deck_id) for deck_id in expected_effective_deck_ids) - forced_deck_ids)
    if not missing_forced:
        checks.append(ok("pipeline_manifest.forced_include_deck_ids", json.dumps(sorted(forced_deck_ids))))
    else:
        checks.append(fail("pipeline_manifest.forced_include_deck_ids", f"missing={missing_forced}"))

    materialized = [
        row.get("learned_deck_id")
        for row in report.get("materialization", [])
        if isinstance(row, dict) and bool(row.get("apply"))
    ]
    if not materialized:
        checks.append(ok("pipeline_manifest.materialization_apply", "none"))
    else:
        checks.append(fail("pipeline_manifest.materialization_apply", json.dumps(materialized, sort_keys=True)))
    return checks


def build_report(args: argparse.Namespace) -> dict[str, Any]:
    checks: list[Check] = []
    checks.extend(audit_pipeline())
    checks.extend(audit_docs())
    checks.extend(audit_benchmark(Path(args.benchmark_report)))
    checks.extend(audit_pattern_registry(Path(args.pattern_registry_report)))
    checks.extend(audit_schema(Path(args.pattern_schema_sql)))
    checks.extend(audit_effective_queue(Path(args.effective_queue_report)))
    checks.extend(audit_pipeline_manifest(Path(args.pipeline_manifest), args.expected_effective_deck_id))
    status_counts: dict[str, int] = {}
    for check in checks:
        status_counts[check.status] = status_counts.get(check.status, 0) + 1
    return {
        "status": "pass" if status_counts.get("fail", 0) == 0 else "fail",
        "mutations_performed": [],
        "summary": {
            "check_count": len(checks),
            "status_counts": status_counts,
        },
        "checks": [check.as_dict() for check in checks],
    }


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# XMage Strategy Consistency Audit",
        "",
        f"- Status: `{report.get('status')}`",
        f"- Mutations performed: `{report.get('mutations_performed')}`",
        f"- Summary: `{json.dumps(report.get('summary'), sort_keys=True)}`",
        "",
        "| Check | Status | Detail |",
        "| --- | --- | --- |",
    ]
    for check in report.get("checks", []):
        detail = str(check.get("detail") or "").replace("|", "\\|")
        lines.append(f"| `{check.get('name')}` | `{check.get('status')}` | {detail} |")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--benchmark-report", default=str(DEFAULT_BENCHMARK))
    parser.add_argument("--pattern-registry-report", default=str(DEFAULT_PATTERN_REGISTRY))
    parser.add_argument("--pattern-schema-sql", default=str(DEFAULT_PATTERN_SCHEMA))
    parser.add_argument("--effective-queue-report", default=str(DEFAULT_EFFECTIVE_QUEUE))
    parser.add_argument("--pipeline-manifest", default=str(DEFAULT_PIPELINE_MANIFEST))
    parser.add_argument(
        "--expected-effective-deck-id",
        type=int,
        action="append",
        default=DEFAULT_EXPECTED_EFFECTIVE_DECK_IDS,
    )
    parser.add_argument("--output-prefix", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_report(args)
    output_prefix = Path(args.output_prefix)
    output_json = output_prefix.with_name(output_prefix.name + ".json")
    output_md = output_prefix.with_name(output_prefix.name + ".md")
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    output_md.write_text(render_markdown(report) + "\n", encoding="utf-8")
    print(f"report_json={output_json}")
    print(f"report_md={output_md}")
    print(f"status={report['status']}")
    print(f"summary={json.dumps(report['summary'], sort_keys=True)}")
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
