#!/usr/bin/env python3
"""Summarize ManaLoom battle/deckbuilder logs into actionable learning gaps.

The audit is read-only. It treats Hermes reports as evidence, not product truth,
and converts scattered gate/coherence/17Lands/XMage artifacts into a compact
queue of issues that can drive the next runtime or deckbuilder fixes.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_STEM = "manaloom_log_learning_audit_20260628"
SUPPORTED_SUFFIXES = {".json", ".jsonl", ".out", ".md", ".txt"}
SEVERITY_RANK = {"critical": 0, "high": 1, "medium": 2, "low": 3}
STATUS_SEVERITY = {
    "fail": "critical",
    "failed": "critical",
    "runtime_error": "critical",
    "postgres_unreachable_pg_isready_no_response": "critical",
    "postgres_precheck_blocked_connection_closed": "critical",
    "blocked": "high",
    "needs_more_evidence": "high",
    "inconclusive_candidate_unobserved": "high",
    "warning": "medium",
    "battle_prior_warning": "medium",
}
TEXT_PATTERNS = (
    ("critical", "runtime_traceback", re.compile(r"traceback|runtime_error", re.I)),
    ("critical", "test_failure", re.compile(r"\bFAILED\b|\bFAILURES?\b|AssertionError")),
    ("high", "timeout", re.compile(r"timed out|timeouterror|timeout waiting|isolated_timeout", re.I)),
    ("high", "blocked", re.compile(r"\bblocked\b|needs_more_evidence|inconclusive", re.I)),
    ("medium", "warning", re.compile(r"\bwarning\b|mismatch|anomal", re.I)),
)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=True, indent=2, sort_keys=True)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def load_json_lenient(path: Path) -> tuple[dict[str, Any] | None, str | None]:
    text = read_text(path).strip()
    if not text:
        return None, "empty_json"
    try:
        payload = json.loads(text)
        return (payload if isinstance(payload, dict) else None), None
    except json.JSONDecodeError as first_error:
        decoder = json.JSONDecoder()
        try:
            payload, end = decoder.raw_decode(text)
        except json.JSONDecodeError:
            return None, str(first_error)
        if isinstance(payload, dict):
            extra = text[end:].strip()
            warning = "extra_json_after_first_object" if extra else None
            return payload, warning
        return None, str(first_error)


def numeric(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except Exception:
        return default


def integer(value: Any, default: int = 0) -> int:
    try:
        return int(float(value))
    except Exception:
        return default


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def iter_report_files(
    reports_dir: Path,
    *,
    max_files: int | None,
    include_patterns: list[str],
) -> list[Path]:
    paths = [
        path
        for path in reports_dir.rglob("*")
        if path.is_file() and path.suffix.lower() in SUPPORTED_SUFFIXES
    ]
    if include_patterns:
        lowered = [item.lower() for item in include_patterns]
        paths = [
            path
            for path in paths
            if any(pattern in path.name.lower() or pattern in str(path).lower() for pattern in lowered)
        ]
    paths.sort(key=lambda path: (path.stat().st_mtime, str(path)), reverse=True)
    return paths[:max_files] if max_files else paths


def add_issue(
    issues: list[dict[str, Any]],
    *,
    severity: str,
    category: str,
    issue_type: str,
    path: Path,
    detail: str,
    evidence: Mapping[str, Any] | None = None,
    next_action: str,
) -> None:
    issues.append(
        {
            "category": category,
            "detail": detail,
            "evidence": dict(evidence or {}),
            "issue_type": issue_type,
            "next_action": next_action,
            "severity": severity,
            "source_file": path.name,
            "source_mtime": path.stat().st_mtime,
            "source_path": rel(path),
        }
    )


def status_issue_category(status: str) -> tuple[str, str]:
    normalized = status.lower()
    if "inconclusive" in normalized or "needs_more_evidence" in normalized:
        return "evidence_gap", "rerun_with_candidate_observation_or_min_used_sample"
    if "postgres" in normalized:
        return "postgres_sync_gap", "resolve_pg_connectivity_or_apply_state_before_claiming_sync"
    if "warning" in normalized or "prior" in normalized:
        return "battle_rhythm_gap", "inspect_rhythm_flags_before_using_gate_for_deckbuilder"
    if "blocked" in normalized:
        return "blocked_workflow", "resolve_blocker_or_remove_from_active_queue"
    return "runtime_or_test_failure", "inspect_failure_and_add_focused_regression_test"


def analyze_top_level_status(path: Path, payload: Mapping[str, Any], issues: list[dict[str, Any]]) -> None:
    status = str(payload.get("status") or "").strip()
    if not status:
        return
    severity = STATUS_SEVERITY.get(status.lower())
    if not severity:
        return
    category, next_action = status_issue_category(status)
    add_issue(
        issues,
        severity=severity,
        category=category,
        issue_type="top_level_status",
        path=path,
        detail=f"report status is {status}",
        evidence={"status": status},
        next_action=next_action,
    )


def analyze_battle_prior(path: Path, payload: Mapping[str, Any], issues: list[dict[str, Any]]) -> None:
    if not (payload.get("comparison") and payload.get("observed_summary")):
        return
    observed = payload.get("observed_summary") or {}
    comparison = payload.get("comparison") or {}
    candidates = observed.get("candidate_observations") or {}
    if isinstance(candidates, Mapping):
        for card, row in candidates.items():
            if not isinstance(row, Mapping):
                continue
            if row.get("observed") is False:
                add_issue(
                    issues,
                    severity="high",
                    category="evidence_gap",
                    issue_type="candidate_unobserved",
                    path=path,
                    detail=f"candidate card was not observed: {card}",
                    evidence={
                        "card": card,
                        "evidence_level": row.get("evidence_level"),
                        "trace_count": row.get("trace_count"),
                    },
                    next_action="do_not_score_swap_until_forced_or_natural_access_sample_exists",
                )
    flags = comparison.get("flags") or []
    if isinstance(flags, list) and flags:
        non_candidate_flags = [
            flag
            for flag in flags
            if isinstance(flag, Mapping) and flag.get("metric") != "candidate_observation"
        ]
        if non_candidate_flags:
            add_issue(
                issues,
                severity="medium",
                category="battle_rhythm_gap",
                issue_type="prior_rhythm_flags",
                path=path,
                detail=f"battle prior emitted {len(non_candidate_flags)} rhythm flags",
                evidence={"sample_flags": non_candidate_flags[:5]},
                next_action="calibrate_or_quarantine_gate_metrics_before_treating_winrate_as_strategy_signal",
            )


def analyze_gate_results(path: Path, payload: Mapping[str, Any], issues: list[dict[str, Any]]) -> None:
    results = payload.get("results") or []
    if not isinstance(results, list):
        return
    for row in results:
        if not isinstance(row, Mapping):
            continue
        deck_key = str(row.get("deck_key") or row.get("key") or "unknown")
        status = str(row.get("status") or "")
        if status and status not in {"pass", "ready"} and not status.startswith("executed_"):
            severity = STATUS_SEVERITY.get(status.lower(), "medium")
            add_issue(
                issues,
                severity=severity,
                category="runtime_or_test_failure",
                issue_type="gate_row_status",
                path=path,
                detail=f"{deck_key} row status is {status}",
                evidence={"deck_key": deck_key, "status": status, "error": row.get("error")},
                next_action="inspect_gate_row_error_and_add_or_fix_runtime_test",
            )
        stalls = integer(row.get("stalls"))
        if stalls:
            add_issue(
                issues,
                severity="medium",
                category="battle_runtime_quality",
                issue_type="stalled_games",
                path=path,
                detail=f"{deck_key} has {stalls} stalled games",
                evidence={"deck_key": deck_key, "stalls": stalls, "games": row.get("games")},
                next_action="rerun_with_checkpoint_trace_and_fix_loop_or_decision_dead_end",
            )
        telemetry = row.get("telemetry") or {}
        if not isinstance(telemetry, Mapping):
            continue
        anomalies = telemetry.get("squee_anomalies") or []
        if anomalies:
            add_issue(
                issues,
                severity="high",
                category="runtime_rule_gap",
                issue_type="squee_graveyard_anomaly",
                path=path,
                detail=f"{deck_key} has {len(anomalies)} Squee graveyard anomalies",
                evidence={"deck_key": deck_key, "sample": anomalies[:3]},
                next_action="fix_squee_zone_accounting_before_using_recursion_results",
            )
        focus_summary = telemetry.get("focus_card_access_summary") or {}
        if isinstance(focus_summary, Mapping):
            for card, focus in focus_summary.items():
                if not isinstance(focus, Mapping):
                    continue
                if integer(focus.get("trace_count")) and not any(
                    integer(focus.get(key))
                    for key in ("accessed_games", "near_access_games", "drawn_games", "opening_hand_games")
                ):
                    add_issue(
                        issues,
                        severity="medium",
                        category="evidence_gap",
                        issue_type="focus_card_library_only",
                        path=path,
                        detail=f"focus card traced but not accessed: {card}",
                        evidence={
                            "deck_key": deck_key,
                            "card": card,
                            "trace_count": focus.get("trace_count"),
                            "library_only_games": focus.get("library_only_games"),
                        },
                        next_action="rerun_targeted_gate_with_forced_focus_access_or_larger_sample",
                    )


def analyze_coherence(path: Path, payload: Mapping[str, Any], issues: list[dict[str, Any]]) -> None:
    severity_counts = payload.get("severity_counts") or {}
    finding_counts = payload.get("finding_counts") or {}
    if isinstance(severity_counts, Mapping):
        critical = integer(severity_counts.get("critical"))
        high = integer(severity_counts.get("high"))
        if critical or high:
            add_issue(
                issues,
                severity="high" if not critical else "critical",
                category="runtime_rule_gap",
                issue_type="coherence_critical_high_findings",
                path=path,
                detail=f"coherence audit has critical={critical}, high={high}",
                evidence={
                    "deck_id": payload.get("deck_id"),
                    "finding_counts": dict(finding_counts) if isinstance(finding_counts, Mapping) else {},
                    "severity_counts": dict(severity_counts),
                },
                next_action="prioritize_cards_with_no_active_or_no_trusted_rules_in_current_deck_scope",
            )


def find_numeric_field(payload: Any, target_key: str) -> int:
    if isinstance(payload, Mapping):
        value = payload.get(target_key)
        if value is not None:
            return integer(value)
        return sum(find_numeric_field(value, target_key) for value in payload.values())
    if isinstance(payload, list):
        return sum(find_numeric_field(value, target_key) for value in payload)
    return 0


def analyze_xmage_pipeline(path: Path, payload: Mapping[str, Any], issues: list[dict[str, Any]]) -> None:
    name = path.name.lower()
    if "xmage" not in name and "runtime_gap_family_queue" not in name:
        return
    blocked_missing = find_numeric_field(payload, "blocked_missing_xmage_source_count")
    missing_class = find_numeric_field(payload, "missing_xmage_class_count")
    manual_or_blocked = find_numeric_field(payload, "manual_or_blocked_count")
    if blocked_missing or missing_class:
        add_issue(
            issues,
            severity="high",
            category="xmage_mapping_gap",
            issue_type="missing_xmage_source_or_class",
            path=path,
            detail=f"XMage mapping blockers: missing_source={blocked_missing}, missing_class={missing_class}",
            evidence={"blocked_missing_xmage_source_count": blocked_missing, "missing_xmage_class_count": missing_class},
            next_action="isolate_cards_without_local_xmage_source_and_keep_them_out_of_auto_mapper_batch",
        )
    if manual_or_blocked:
        add_issue(
            issues,
            severity="medium",
            category="xmage_mapping_gap",
            issue_type="manual_or_blocked_rules",
            path=path,
            detail=f"XMage pipeline still has {manual_or_blocked} manual or blocked rows",
            evidence={"manual_or_blocked_count": manual_or_blocked},
            next_action="group_manual_rows_by_effect_family_and_create_mapper_or_runtime_family_test",
        )


def extract_test_names(text: str) -> list[str]:
    names: list[str] = []
    for pattern in (r"\bPASS\s+(test_[A-Za-z0-9_]+)", r"\bin\s+(test_[A-Za-z0-9_]+)\b"):
        for match in re.finditer(pattern, text):
            name = match.group(1)
            if name not in names:
                names.append(name)
    return names


def passed_tests_from_text(path: Path, text: str) -> dict[str, dict[str, Any]]:
    passed: dict[str, dict[str, Any]] = {}
    for match in re.finditer(r"\bPASS\s+(test_[A-Za-z0-9_]+)", text):
        name = match.group(1)
        passed[name] = {"source_mtime": path.stat().st_mtime, "source_path": rel(path)}
    return passed


def collect_passed_tests(files: list[Path]) -> dict[str, dict[str, Any]]:
    passed: dict[str, dict[str, Any]] = {}
    for path in files:
        if path.suffix.lower() not in {".out", ".txt", ".md"}:
            continue
        try:
            found = passed_tests_from_text(path, read_text(path)[:200000])
        except Exception:
            continue
        for name, payload in found.items():
            if name not in passed or payload["source_mtime"] > passed[name]["source_mtime"]:
                passed[name] = payload
    return passed


def analyze_text(path: Path, text: str, issues: list[dict[str, Any]]) -> None:
    snippets_by_type: dict[str, list[str]] = defaultdict(list)
    test_names = extract_test_names(text)
    for line in text.splitlines():
        compact = line.strip()
        if not compact:
            continue
        for severity, issue_type, pattern in TEXT_PATTERNS:
            if pattern.search(compact) and len(snippets_by_type[issue_type]) < 3:
                snippets_by_type[issue_type].append(compact[:300])
    for severity, issue_type, _ in TEXT_PATTERNS:
        snippets = snippets_by_type.get(issue_type) or []
        if not snippets:
            continue
        category = "runtime_or_test_failure"
        if issue_type in {"blocked", "timeout"}:
            category = "blocked_workflow" if issue_type == "blocked" else "battle_runtime_quality"
        add_issue(
            issues,
            severity=severity,
            category=category,
            issue_type=f"text_{issue_type}",
            path=path,
            detail=f"text log contains {issue_type}",
            evidence={"snippets": snippets, "test_names": test_names},
            next_action="inspect_text_log_and_convert_recurring_pattern_to_structured_gate_field",
        )


def filter_superseded_issues(
    issues: list[dict[str, Any]],
    passed_tests: Mapping[str, Mapping[str, Any]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    active: list[dict[str, Any]] = []
    superseded: list[dict[str, Any]] = []
    for issue in issues:
        if issue.get("issue_type") not in {"text_runtime_traceback", "text_test_failure"}:
            active.append(issue)
            continue
        names = (issue.get("evidence") or {}).get("test_names") or []
        later_passes = [
            {"test_name": name, **dict(passed_tests[name])}
            for name in names
            if name in passed_tests and numeric(passed_tests[name].get("source_mtime")) > numeric(issue.get("source_mtime"))
        ]
        if later_passes:
            copy = dict(issue)
            copy["superseded_by"] = later_passes
            superseded.append(copy)
        else:
            active.append(issue)
    return active, superseded


def analyze_path(path: Path) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    issues: list[dict[str, Any]] = []
    meta = {"parse_warning": None, "status": None}
    if path.suffix.lower() == ".json":
        payload, warning = load_json_lenient(path)
        meta["parse_warning"] = warning
        if not payload:
            if warning:
                add_issue(
                    issues,
                    severity="medium",
                    category="log_quality_gap",
                    issue_type="json_parse_error",
                    path=path,
                    detail=f"could not parse JSON: {warning}",
                    evidence={},
                    next_action="repair_or_exclude_malformed_artifact_from_learning_corpus",
                )
            return issues, meta
        meta["status"] = payload.get("status")
        analyze_top_level_status(path, payload, issues)
        analyze_battle_prior(path, payload, issues)
        analyze_gate_results(path, payload, issues)
        analyze_coherence(path, payload, issues)
        analyze_xmage_pipeline(path, payload, issues)
        if warning:
            add_issue(
                issues,
                severity="low",
                category="log_quality_gap",
                issue_type="json_extra_data",
                path=path,
                detail=f"JSON parsed with warning: {warning}",
                evidence={},
                next_action="normalize_artifact_writer_to_emit_single_json_document",
            )
        return issues, meta
    if path.suffix.lower() == ".jsonl":
        text = read_text(path)
        analyze_text(path, text[:200000], issues)
        return issues, meta
    text = read_text(path)
    analyze_text(path, text[:200000], issues)
    return issues, meta


def issue_signature(issue: Mapping[str, Any]) -> tuple[str, str, str, str]:
    detail = str(issue.get("detail") or "")
    detail = re.sub(r"\d+", "#", detail)
    evidence = issue.get("evidence") or {}
    card = str(evidence.get("card") or "")
    deck_key = str(evidence.get("deck_key") or "")
    return (
        str(issue.get("category")),
        str(issue.get("issue_type")),
        card or deck_key or detail,
        str(issue.get("next_action")),
    )


def aggregate_issues(issues: list[dict[str, Any]], *, max_examples: int = 5) -> list[dict[str, Any]]:
    grouped: dict[tuple[str, str, str, str], dict[str, Any]] = {}
    for issue in issues:
        sig = issue_signature(issue)
        row = grouped.setdefault(
            sig,
            {
                "category": issue["category"],
                "count": 0,
                "examples": [],
                "issue_type": issue["issue_type"],
                "next_action": issue["next_action"],
                "severity": issue["severity"],
            },
        )
        row["count"] += 1
        if SEVERITY_RANK[issue["severity"]] < SEVERITY_RANK[row["severity"]]:
            row["severity"] = issue["severity"]
        if len(row["examples"]) < max_examples:
            row["examples"].append(
                {
                    "detail": issue["detail"],
                    "evidence": issue.get("evidence") or {},
                    "source_path": issue["source_path"],
                }
            )
    return sorted(
        grouped.values(),
        key=lambda row: (SEVERITY_RANK[row["severity"]], -row["count"], row["category"], row["issue_type"]),
    )


def build_audit(
    reports_dir: Path,
    *,
    max_files: int | None,
    include_patterns: list[str],
) -> dict[str, Any]:
    files = iter_report_files(reports_dir, max_files=max_files, include_patterns=include_patterns)
    raw_issues: list[dict[str, Any]] = []
    parse_warnings: Counter[str] = Counter()
    status_counts: Counter[str] = Counter()
    suffix_counts: Counter[str] = Counter()
    passed_tests = collect_passed_tests(files)
    for path in files:
        suffix_counts[path.suffix.lower()] += 1
        issues, meta = analyze_path(path)
        raw_issues.extend(issues)
        if meta.get("parse_warning"):
            parse_warnings[str(meta["parse_warning"])] += 1
        if meta.get("status"):
            status_counts[str(meta["status"])] += 1
    active_issues, superseded_issues = filter_superseded_issues(raw_issues, passed_tests)
    aggregated = aggregate_issues(active_issues)
    severity_counts = Counter(issue["severity"] for issue in active_issues)
    category_counts = Counter(issue["category"] for issue in active_issues)
    return {
        "action_queue": aggregated[:80],
        "category_counts": dict(sorted(category_counts.items())),
        "files_scanned": len(files),
        "generated_at": utc_now(),
        "include_patterns": include_patterns,
        "issue_count": len(active_issues),
        "parse_warnings": dict(parse_warnings),
        "postgres_writes": False,
        "reports_dir": str(reports_dir),
        "severity_counts": dict(sorted(severity_counts.items())),
        "source_db_mutated": False,
        "status_counts": dict(status_counts.most_common()),
        "superseded_issue_count": len(superseded_issues),
        "superseded_issue_samples": superseded_issues[:20],
        "suffix_counts": dict(sorted(suffix_counts.items())),
    }


def render_markdown(report: Mapping[str, Any]) -> str:
    lines = [
        "# ManaLoom Log Learning Audit",
        "",
        f"- generated_at: `{report['generated_at']}`",
        f"- reports_dir: `{report['reports_dir']}`",
        f"- files_scanned: `{report['files_scanned']}`",
        f"- issue_count: `{report['issue_count']}`",
        f"- superseded_issue_count: `{report.get('superseded_issue_count', 0)}`",
        f"- postgres_writes: `{report['postgres_writes']}`",
        f"- source_db_mutated: `{report['source_db_mutated']}`",
        "",
        "## Severity Counts",
        "",
    ]
    for key, value in report.get("severity_counts", {}).items():
        lines.append(f"- {key}: `{value}`")
    lines.extend(["", "## Category Counts", ""])
    for key, value in report.get("category_counts", {}).items():
        lines.append(f"- {key}: `{value}`")
    lines.extend(["", "## Action Queue", ""])
    for idx, issue in enumerate(report.get("action_queue") or [], 1):
        lines.append(
            f"{idx}. `{issue['severity']}` `{issue['category']}` `{issue['issue_type']}` "
            f"count={issue['count']} next=`{issue['next_action']}`"
        )
        for example in issue.get("examples", [])[:2]:
            lines.append(f"   - {example['detail']} [{example['source_path']}]")
    lines.append("")
    return "\n".join(lines)


def write_report(report: Mapping[str, Any], stem: str) -> tuple[Path, Path]:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{stem}.json"
    md_path = REPORT_DIR / f"{stem}.md"
    json_path.write_text(stable_json(report) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(report), encoding="utf-8")
    return json_path, md_path


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reports-dir", type=Path, default=REPORT_DIR)
    parser.add_argument("--max-files", type=int, default=0)
    parser.add_argument("--include-pattern", action="append", default=[])
    parser.add_argument("--stem", default=DEFAULT_STEM)
    parser.add_argument("--no-write", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    report = build_audit(
        args.reports_dir,
        max_files=args.max_files or None,
        include_patterns=list(args.include_pattern or []),
    )
    if args.no_write:
        print(stable_json(report))
    else:
        json_path, md_path = write_report(report, args.stem)
        print(stable_json({"status": "ready", "json": str(json_path), "markdown": str(md_path)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
