#!/usr/bin/env python3
"""Build a fail-closed nominal-review plan for an exact XMage pin transition.

The planner is read-only and network-free. It combines exact Git blobs, exact
diff hashes, the versioned transition rows and existing upstream nominal-test
evidence. Catalog resolution is never accepted as semantic proof.

An automatic transition clearance is intentionally narrower than general
semantic approval. It is allowed only by an explicit card-specific policy whose
exact diff hash, source shape, nominal tests and warning boundaries all match.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

import external_engine_source_contract as engine_source_contract


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DEFAULT_EVIDENCE = (
    REPO_ROOT / "docs/qa/evidence/XMAGE_PIN_TRANSITION_34d81ea_2c43ec8.json"
)
DEFAULT_POLICY = (
    REPO_ROOT
    / "docs/hermes-analysis/XMAGE_PIN_TRANSITION_NOMINAL_REVIEW_POLICY.json"
)
SCHEMA_VERSION = "manaloom_xmage_transition_nominal_review_v1_2026-07-29"
POLICY_SCHEMA_VERSION = (
    "manaloom_xmage_transition_nominal_review_policy_v1_2026-07-29"
)
CLEARANCE_DISPOSITION = "presentation_hunk_nominal_tests_passed"
REVIEW_DISPOSITIONS = {
    "focused_upstream_test_passed_card_data_warning_review_required",
    "catalog_supported_semantic_review_required",
    "catalog_supported_nominal_test_passed_semantic_review_required",
    "catalog_supported_regression_only_review_required",
    "external_runtime_quarantine_semantic_defect",
    "external_residual_upstream_unfinished",
}
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")

SourceLookup = Callable[[str, str], str | None]
DiffLookup = Callable[[str, str, str], bytes]


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"JSON root must be an object: {path}")
    return payload


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def strip_java_comments(source: str) -> str:
    """Remove Java comments while preserving strings, chars and newlines."""

    output: list[str] = []
    index = 0
    state = "code"
    while index < len(source):
        char = source[index]
        following = source[index + 1] if index + 1 < len(source) else ""
        if state == "code":
            if char == "/" and following == "/":
                state = "line_comment"
                index += 2
                continue
            if char == "/" and following == "*":
                state = "block_comment"
                index += 2
                continue
            if char == '"':
                state = "string"
            elif char == "'":
                state = "char"
            output.append(char)
            index += 1
            continue
        if state == "line_comment":
            if char == "\n":
                output.append(char)
                state = "code"
            index += 1
            continue
        if state == "block_comment":
            if char == "*" and following == "/":
                state = "code"
                index += 2
            else:
                if char == "\n":
                    output.append(char)
                index += 1
            continue
        output.append(char)
        if char == "\\" and index + 1 < len(source):
            output.append(source[index + 1])
            index += 2
            continue
        if (state == "string" and char == '"') or (
            state == "char" and char == "'"
        ):
            state = "code"
        index += 1
    return "".join(output)


def compact_java_tokens(source: str) -> str:
    return re.sub(r"\s+", "", strip_java_comments(source))


def sources_match_after_allowed_presentation_changes(
    old_source: str,
    new_source: str,
    changes: list[dict[str, Any]],
) -> tuple[bool, list[str]]:
    old_normalized = strip_java_comments(old_source)
    new_normalized = strip_java_comments(new_source)
    failures: list[str] = []
    for index, raw_change in enumerate(changes):
        if not isinstance(raw_change, dict):
            failures.append(f"literal_change_{index}_not_object")
            continue
        old_literal = raw_change.get("old")
        new_literal = raw_change.get("new")
        occurrences = raw_change.get("occurrences")
        if (
            not isinstance(old_literal, str)
            or not isinstance(new_literal, str)
            or not isinstance(occurrences, int)
            or isinstance(occurrences, bool)
            or occurrences < 1
        ):
            failures.append(f"literal_change_{index}_invalid")
            continue
        if old_normalized.count(old_literal) != occurrences:
            failures.append(f"literal_change_{index}_old_occurrences")
            continue
        if new_normalized.count(new_literal) != occurrences:
            failures.append(f"literal_change_{index}_new_occurrences")
            continue
        marker = f'"__MANALOOM_PRESENTATION_LITERAL_{index}__"'
        old_normalized = old_normalized.replace(old_literal, marker)
        new_normalized = new_normalized.replace(new_literal, marker)
    equivalent = (
        not failures
        and re.sub(r"\s+", "", old_normalized)
        == re.sub(r"\s+", "", new_normalized)
    )
    if not equivalent and not failures:
        failures.append("non_presentation_tokens_changed")
    return equivalent, failures


def _scope_for_class(evidence: dict[str, Any], card_class: str) -> str:
    scope = evidence.get("modified_change_scope")
    if not isinstance(scope, dict):
        return "unknown"
    executable = scope.get("executable_or_mixed_classes")
    comments = scope.get("comment_only_classes")
    if isinstance(executable, list) and card_class in executable:
        return "executable_or_mixed"
    if isinstance(comments, list) and card_class in comments:
        return "comment_only"
    return "presentation_or_metadata"


def _actionable_card_names(evidence: dict[str, Any]) -> set[str]:
    diagnostics = evidence.get("card_data_diagnostics")
    if not isinstance(diagnostics, dict):
        return set()
    findings = diagnostics.get("actionable_findings")
    if not isinstance(findings, list):
        return set()
    return {
        str(row.get("card_name") or "")
        for row in findings
        if isinstance(row, dict) and row.get("card_name")
    }


def _card_lane(
    row: dict[str, Any],
    *,
    source_scope: str,
    comment_only_proven: bool,
    actionable_card_names: set[str],
    clearance_rule_id: str | None,
) -> str:
    disposition = str(row.get("disposition") or "")
    has_tests = bool(row.get("direct_test_references"))
    has_warnings = bool(row.get("source_warning_markers"))
    has_card_data_finding = row.get("card_name") in actionable_card_names
    if clearance_rule_id:
        return "exact_presentation_hunk_and_nominal_tests_clearance"
    if disposition == "focused_upstream_test_passed":
        return "added_nominal_test_already_passed"
    if disposition == "focused_upstream_test_passed_card_data_warning_review_required":
        return "added_nominal_test_card_data_warning"
    if comment_only_proven and has_warnings:
        return "no_executable_card_delta_known_upstream_risk"
    if comment_only_proven:
        return "no_executable_card_delta"
    if has_tests and source_scope == "executable_or_mixed":
        return "nominal_tests_do_not_cover_executable_hunk"
    if has_tests and has_card_data_finding:
        return "nominal_tests_card_data_warning"
    if has_tests:
        return "nominal_tests_present_review_required"
    if row.get("change_kind") == "added":
        return "added_without_exact_nominal_test"
    if source_scope == "executable_or_mixed":
        return "modified_executable_without_exact_nominal_test"
    return "modified_presentation_or_metadata_without_exact_nominal_test"


def build_report(
    evidence: dict[str, Any],
    policy: dict[str, Any],
    *,
    source_lookup: SourceLookup,
    diff_lookup: DiffLookup,
) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    transition_id = str(evidence.get("transition_id") or "")
    from_pin = str(evidence.get("from_pin") or "")
    to_pin = str(evidence.get("to_pin") or "")
    if (
        policy.get("schema_version") != POLICY_SCHEMA_VERSION
        or policy.get("transition_id") != transition_id
        or policy.get("from_pin") != from_pin
        or policy.get("to_pin") != to_pin
        or policy.get("catalog_resolution_is_semantic_proof") is not False
        or not SHA_PATTERN.fullmatch(from_pin)
        or not SHA_PATTERN.fullmatch(to_pin)
    ):
        failures.append(
            {
                "id": "policy_identity",
                "message": "Policy schema, pins or semantic boundary diverge.",
            }
        )

    raw_cards = evidence.get("cards")
    cards = [row for row in raw_cards or [] if isinstance(row, dict)]
    by_name = {str(row.get("card_name") or ""): row for row in cards}
    actionable_names = _actionable_card_names(evidence)
    raw_rules = policy.get("automatic_transition_clearance_rules")
    rules = [row for row in raw_rules or [] if isinstance(row, dict)]
    if len(rules) != len(raw_rules or []):
        failures.append(
            {
                "id": "policy_rule_shape",
                "message": "Every clearance rule must be an object.",
            }
        )

    clearance_by_name: dict[str, str] = {}
    rule_results: list[dict[str, Any]] = []
    for rule in rules:
        rule_id = str(rule.get("id") or "")
        card_name = str(rule.get("card_name") or "")
        row = by_name.get(card_name)
        rule_failures: list[str] = []
        if not rule_id or row is None:
            rule_failures.append("card_or_rule_missing")
            row = {}
        card_class = str(row.get("class") or "")
        source_path = str(row.get("source_path") or "")
        old_source = source_lookup(from_pin, source_path) if source_path else None
        new_source = source_lookup(to_pin, source_path) if source_path else None
        raw_diff = (
            diff_lookup(from_pin, to_pin, source_path) if source_path else b""
        )
        diff_sha256 = sha256_bytes(raw_diff)
        required_tests = rule.get("required_direct_test_references")
        source_scope = _scope_for_class(evidence, card_class)
        literal_changes = rule.get("allowed_presentation_literal_changes")
        literal_equivalent = False
        literal_failures: list[str] = []
        if old_source is None or new_source is None:
            rule_failures.append("git_blob_missing")
        elif isinstance(literal_changes, list) and literal_changes:
            literal_equivalent, literal_failures = (
                sources_match_after_allowed_presentation_changes(
                    old_source,
                    new_source,
                    literal_changes,
                )
            )
            rule_failures.extend(literal_failures)
        else:
            rule_failures.append("presentation_literal_policy_missing")
        if rule.get("class") != card_class:
            rule_failures.append("class_mismatch")
        if rule.get("source_path") != source_path:
            rule_failures.append("source_path_mismatch")
        if rule.get("change_kind") != row.get("change_kind"):
            rule_failures.append("change_kind_mismatch")
        if rule.get("required_change_scope") != source_scope:
            rule_failures.append("change_scope_mismatch")
        if (
            not SHA256_PATTERN.fullmatch(str(rule.get("exact_diff_sha256") or ""))
            or rule.get("exact_diff_sha256") != diff_sha256
        ):
            rule_failures.append("exact_diff_sha256_mismatch")
        if (
            not isinstance(required_tests, list)
            or sorted(required_tests)
            != sorted(row.get("direct_test_references") or [])
        ):
            rule_failures.append("direct_test_references_mismatch")
        if rule.get("required_focused_test_case_count") != row.get(
            "focused_test_case_count"
        ):
            rule_failures.append("focused_test_case_count_mismatch")
        if (
            rule.get("require_no_source_warning_markers") is not True
            or row.get("source_warning_markers")
        ):
            rule_failures.append("source_warning_marker_present")
        if (
            rule.get("require_no_card_data_actionable_finding") is not True
            or card_name in actionable_names
        ):
            rule_failures.append("card_data_actionable_finding_present")
        if row.get("runtime_catalog_status") != "supported":
            rule_failures.append("runtime_not_supported")
        if rule_failures:
            failures.append(
                {
                    "id": f"clearance_rule:{rule_id or 'unknown'}",
                    "message": "Exact transition clearance rule did not match.",
                    "details": {"failures": sorted(set(rule_failures))},
                }
            )
        else:
            clearance_by_name[card_name] = rule_id
        rule_results.append(
            {
                "rule_id": rule_id,
                "card_name": card_name,
                "source_path": source_path,
                "source_scope": source_scope,
                "diff_sha256": diff_sha256,
                "presentation_tokens_equivalent": literal_equivalent,
                "required_test_case_count": row.get("focused_test_case_count"),
                "status": "pass" if not rule_failures else "fail",
                "failures": sorted(set(rule_failures)),
            }
        )

    nominal_rows: list[dict[str, Any]] = []
    lane_counts: Counter[str] = Counter()
    no_reference_groups: dict[str, list[str]] = {
        "added": [],
        "modified_executable_or_mixed": [],
        "modified_presentation_or_metadata": [],
        "modified_comment_only": [],
    }
    for row in cards:
        card_name = str(row.get("card_name") or "")
        card_class = str(row.get("class") or "")
        source_path = str(row.get("source_path") or "")
        source_scope = (
            _scope_for_class(evidence, card_class)
            if row.get("change_kind") == "modified"
            else "added"
        )
        comment_only_proven = False
        diff_sha256: str | None = None
        if row.get("change_kind") == "modified":
            old_source = source_lookup(from_pin, source_path)
            new_source = source_lookup(to_pin, source_path)
            raw_diff = diff_lookup(from_pin, to_pin, source_path)
            diff_sha256 = sha256_bytes(raw_diff)
            comment_only_proven = (
                old_source is not None
                and new_source is not None
                and compact_java_tokens(old_source)
                == compact_java_tokens(new_source)
            )
        clearance_rule_id = clearance_by_name.get(card_name)
        lane = _card_lane(
            row,
            source_scope=source_scope,
            comment_only_proven=comment_only_proven,
            actionable_card_names=actionable_names,
            clearance_rule_id=clearance_rule_id,
        )
        lane_counts[lane] += 1
        direct_tests = row.get("direct_test_references")
        if direct_tests:
            nominal_rows.append(
                {
                    "card_name": card_name,
                    "class": card_class,
                    "change_kind": row.get("change_kind"),
                    "source_path": source_path,
                    "source_scope": source_scope,
                    "comment_only_proven": comment_only_proven,
                    "diff_sha256": diff_sha256,
                    "direct_test_references": direct_tests,
                    "focused_test_case_count": row.get(
                        "focused_test_case_count"
                    ),
                    "source_warning_markers": row.get("source_warning_markers"),
                    "card_data_actionable_finding": (
                        card_name in actionable_names
                    ),
                    "clearance_rule_id": clearance_rule_id,
                    "lane": lane,
                }
            )
        else:
            if row.get("change_kind") == "added":
                group = "added"
            else:
                group = f"modified_{source_scope}"
            no_reference_groups.setdefault(group, []).append(card_name)

    disposition_counts = Counter(
        str(row.get("disposition") or "") for row in cards
    )
    current_review_count = sum(
        count
        for disposition, count in disposition_counts.items()
        if disposition in REVIEW_DISPOSITIONS
    )
    already_cleared_count = disposition_counts.get(CLEARANCE_DISPOSITION, 0)
    baseline_review_count = current_review_count + already_cleared_count
    projected_review_count = baseline_review_count - len(clearance_by_name)
    if already_cleared_count and already_cleared_count != len(clearance_by_name):
        failures.append(
            {
                "id": "clearance_disposition_alignment",
                "message": "Evidence clearance rows must match exact policy proofs.",
            }
        )

    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at_utc": utc_now(),
        "status": "pass" if not failures else "fail",
        "transition": {
            "id": transition_id,
            "from_pin": from_pin,
            "to_pin": to_pin,
        },
        "safety": {
            "read_only": True,
            "network_used": False,
            "source_mutations": False,
            "postgres_queries": 0,
            "postgres_writes": False,
            "catalog_resolution_used_as_semantic_proof": False,
        },
        "summary": {
            "changed_card_count": len(cards),
            "existing_nominal_reference_card_count": len(nominal_rows),
            "exact_clearance_card_count": len(clearance_by_name),
            "review_required_before_exact_clearance": baseline_review_count,
            "review_required_after_exact_clearance": projected_review_count,
            "lane_counts": dict(sorted(lane_counts.items())),
        },
        "exact_clearance_cards": sorted(clearance_by_name),
        "clearance_rule_results": rule_results,
        "existing_nominal_cards": sorted(
            nominal_rows,
            key=lambda row: str(row.get("card_name") or "").casefold(),
        ),
        "without_exact_nominal_reference": {
            key: sorted(values, key=str.casefold)
            for key, values in sorted(no_reference_groups.items())
        },
        "next_actions": [
            {
                "priority": 1,
                "card_name": "Mjolnir, Hammer of Thor",
                "action": "Add and pass a transition-specific Channel timing scenario; the existing tests cover equip and damage doubling, not the changed TimingRule.INSTANT hunk."
            },
            {
                "priority": 1,
                "card_name": "Krark, the Thumbless",
                "action": "Exercise the copy/LKI branch referenced by upstream issue 12911 or quarantine the card; the existing nominal test does not close that TODO."
            },
            {
                "priority": 1,
                "card_name": "Mandate of Peace",
                "action": "Add a copy/LKI stack-removal scenario for upstream issue 12911 or quarantine the card."
            },
            {
                "priority": 2,
                "scope": "added_without_exact_nominal_test",
                "action": "Prioritize released/current product-scope cards, then add focused positive and negative scenarios. Catalog support alone remains non-promoting."
            },
            {
                "priority": 2,
                "scope": "modified_executable_without_exact_nominal_test",
                "action": "Review exact executable hunks and add one hunk-specific scenario per card before changing its disposition."
            }
        ],
        "failures": failures,
    }


def render_markdown(report: dict[str, Any]) -> str:
    summary = report.get("summary") or {}
    lines = [
        "# XMage transition nominal review",
        "",
        f"- Status: `{report.get('status')}`",
        f"- Changed cards: `{summary.get('changed_card_count')}`",
        (
            "- Exact nominal references: "
            f"`{summary.get('existing_nominal_reference_card_count')}`"
        ),
        (
            "- Reviews before exact clearance: "
            f"`{summary.get('review_required_before_exact_clearance')}`"
        ),
        (
            "- Reviews after exact clearance: "
            f"`{summary.get('review_required_after_exact_clearance')}`"
        ),
        "- Catalog resolution used as semantic proof: `false`",
        "",
        "## Existing nominal cards",
        "",
    ]
    for row in report.get("existing_nominal_cards") or []:
        lines.append(
            f"- `{row.get('card_name')}`: `{row.get('lane')}` "
            f"({row.get('focused_test_case_count')} scenarios)"
        )
    lines.extend(["", "## Next actions", ""])
    for row in report.get("next_actions") or []:
        target = row.get("card_name") or row.get("scope")
        lines.append(
            f"- P{row.get('priority')} `{target}`: {row.get('action')}"
        )
    if report.get("failures"):
        lines.extend(["", "## Failures", ""])
        for row in report["failures"]:
            lines.append(f"- `{row.get('id')}`: {row.get('message')}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(
    report: dict[str, Any],
    *,
    output_json: Path,
    output_md: Path | None,
) -> None:
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    if output_md:
        output_md.parent.mkdir(parents=True, exist_ok=True)
        output_md.write_text(render_markdown(report), encoding="utf-8")


def _git_source_lookup(root: Path) -> SourceLookup:
    def lookup(commit: str, source_path: str) -> str | None:
        result = subprocess.run(
            ["git", "-C", str(root), "show", f"{commit}:{source_path}"],
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        return result.stdout if result.returncode == 0 else None

    return lookup


def _git_diff_lookup(root: Path) -> DiffLookup:
    def lookup(from_pin: str, to_pin: str, source_path: str) -> bytes:
        result = subprocess.run(
            [
                "git",
                "-C",
                str(root),
                "diff",
                "--no-ext-diff",
                "--no-textconv",
                "--unified=0",
                from_pin,
                to_pin,
                "--",
                source_path,
            ],
            check=False,
            capture_output=True,
        )
        if result.returncode != 0:
            raise ValueError(f"Unable to diff {source_path}")
        return result.stdout

    return lookup


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xmage-root", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, default=DEFAULT_EVIDENCE)
    parser.add_argument("--policy", type=Path, default=DEFAULT_POLICY)
    parser.add_argument("--output-json", type=Path, required=True)
    parser.add_argument("--output-md", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        xmage_root = engine_source_contract.resolve_xmage_source_root(
            args.xmage_root
        )
        evidence = load_json(args.evidence)
        policy = load_json(args.policy)
        report = build_report(
            evidence,
            policy,
            source_lookup=_git_source_lookup(xmage_root),
            diff_lookup=_git_diff_lookup(xmage_root),
        )
        write_outputs(
            report,
            output_json=args.output_json,
            output_md=args.output_md,
        )
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"xmage_transition_nominal_review_error={exc}")
        return 2
    print(f"status={report['status']}")
    print(
        "existing_nominal_reference_cards="
        f"{report['summary']['existing_nominal_reference_card_count']}"
    )
    print(
        "exact_clearance_cards="
        f"{report['summary']['exact_clearance_card_count']}"
    )
    print(
        "reviews_after_exact_clearance="
        f"{report['summary']['review_required_after_exact_clearance']}"
    )
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
