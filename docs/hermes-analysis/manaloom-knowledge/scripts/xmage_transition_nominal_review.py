#!/usr/bin/env python3
"""Build a fail-closed nominal-review plan for an exact XMage pin transition.

The planner is read-only and network-free. It combines exact Git blobs, exact
diff hashes, the versioned transition rows and existing upstream nominal-test
evidence. Catalog resolution is never accepted as semantic proof.

An automatic transition clearance is intentionally narrower than general
semantic approval. It is allowed only by an explicit card-specific policy whose
full blob OIDs, source hashes, canonical full-index diff, normalized source
tokens, tests (when declared) and warning boundaries all match.
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
SCHEMA_VERSION = "manaloom_xmage_transition_nominal_review_v2_2026-07-30"
POLICY_SCHEMA_VERSION = (
    "manaloom_xmage_transition_nominal_review_policy_v2_2026-07-30"
)
CLEARANCE_DISPOSITION = "exact_non_executable_tokens_passed"
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
BlobLookup = Callable[[str, str], str | None]


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


IMPORT_PATTERN = re.compile(r"(?m)^[ \t]*import[ \t]+[^;\n]+;[ \t]*(?:\n|$)")


def extract_java_imports(source: str) -> list[str]:
    return [
        match.group(0).strip()
        for match in IMPORT_PATTERN.finditer(strip_java_comments(source))
    ]


def _remove_counter_items(
    values: list[str],
    removals: Counter[str],
) -> list[str]:
    remaining = removals.copy()
    result: list[str] = []
    for value in values:
        if remaining[value] > 0:
            remaining[value] -= 1
        else:
            result.append(value)
    return result


def sources_match_after_exact_non_executable_changes(
    old_source: str,
    new_source: str,
    *,
    literal_changes: list[dict[str, Any]],
    allowed_import_delta: dict[str, Any],
    allow_import_reordering: bool,
) -> tuple[bool, list[str], str | None]:
    old_normalized = strip_java_comments(old_source)
    new_normalized = strip_java_comments(new_source)
    failures: list[str] = []
    old_imports = extract_java_imports(old_source)
    new_imports = extract_java_imports(new_source)
    observed_removed = Counter(old_imports) - Counter(new_imports)
    observed_added = Counter(new_imports) - Counter(old_imports)

    if not isinstance(allowed_import_delta, dict):
        failures.append("allowed_import_delta_not_object")
        allowed_removed: list[str] = []
        allowed_added: list[str] = []
    else:
        raw_removed = allowed_import_delta.get("removed")
        raw_added = allowed_import_delta.get("added")
        allowed_removed = raw_removed if isinstance(raw_removed, list) else []
        allowed_added = raw_added if isinstance(raw_added, list) else []
        if (
            not isinstance(raw_removed, list)
            or not isinstance(raw_added, list)
            or not all(isinstance(value, str) for value in allowed_removed)
            or not all(isinstance(value, str) for value in allowed_added)
        ):
            failures.append("allowed_import_delta_invalid")

    if observed_removed != Counter(allowed_removed):
        failures.append("removed_imports_mismatch")
    if observed_added != Counter(allowed_added):
        failures.append("added_imports_mismatch")

    common_old = _remove_counter_items(old_imports, observed_removed)
    common_new = _remove_counter_items(new_imports, observed_added)
    observed_reordering = common_old != common_new
    if not isinstance(allow_import_reordering, bool):
        failures.append("allow_import_reordering_not_boolean")
    elif allow_import_reordering != observed_reordering:
        failures.append("import_reordering_policy_mismatch")

    old_normalized = IMPORT_PATTERN.sub("", old_normalized)
    new_normalized = IMPORT_PATTERN.sub("", new_normalized)
    if not isinstance(literal_changes, list) or not literal_changes:
        failures.append("presentation_literal_policy_missing")
        literal_changes = []
    for index, raw_change in enumerate(literal_changes):
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
    old_tokens = re.sub(r"\s+", "", old_normalized)
    new_tokens = re.sub(r"\s+", "", new_normalized)
    equivalent = not failures and old_tokens == new_tokens
    if not equivalent and not failures:
        failures.append("non_executable_tokens_changed")
    normalized_sha256 = (
        sha256_bytes(old_tokens.encode("utf-8")) if equivalent else None
    )
    return equivalent, failures, normalized_sha256


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
        return "exact_non_executable_tokens_clearance"
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
    blob_lookup: BlobLookup,
) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    transition_id = str(evidence.get("transition_id") or "")
    from_pin = str(evidence.get("from_pin") or "")
    to_pin = str(evidence.get("to_pin") or "")
    policy_identity_valid = not (
        policy.get("schema_version") != POLICY_SCHEMA_VERSION
        or policy.get("transition_id") != transition_id
        or policy.get("from_pin") != from_pin
        or policy.get("to_pin") != to_pin
        or policy.get("catalog_resolution_is_semantic_proof") is not False
        or policy.get("canonical_diff_hash_mode")
        != "git_diff_no_ext_diff_no_textconv_unified0_full_index"
        or policy.get("requires_full_blob_oids") is not True
        or policy.get("requires_source_sha256") is not True
        or policy.get("unlisted_token_changes_allowed") is not False
        or policy.get("filter_predicate_normalization_allowed") is not False
        or policy.get("string_literal_changes_require_explicit_map") is not True
        or policy.get("import_changes_require_exact_delta") is not True
        or policy.get("automatic_clearance_does_not_activate_runtime_card")
        is not True
        or not SHA_PATTERN.fullmatch(from_pin)
        or not SHA_PATTERN.fullmatch(to_pin)
    )
    if not policy_identity_valid:
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
    rule_ids = [str(row.get("id") or "") for row in rules]
    rule_card_names = [str(row.get("card_name") or "") for row in rules]
    if (
        not rule_ids
        or any(not value for value in rule_ids + rule_card_names)
        or len(rule_ids) != len(set(rule_ids))
        or len(rule_card_names) != len(set(rule_card_names))
    ):
        failures.append(
            {
                "id": "policy_rule_identity",
                "message": "Clearance rule ids and card names must be non-empty and unique.",
            }
        )

    clearance_by_name: dict[str, str] = {}
    rule_results: list[dict[str, Any]] = []
    for rule in rules:
        rule_id = str(rule.get("id") or "")
        card_name = str(rule.get("card_name") or "")
        row = by_name.get(card_name)
        rule_failures: list[str] = []
        if not policy_identity_valid:
            rule_failures.append("policy_identity_invalid")
        if not rule_id or row is None:
            rule_failures.append("card_or_rule_missing")
            row = {}
        card_class = str(row.get("class") or "")
        source_path = str(row.get("source_path") or "")
        old_source = source_lookup(from_pin, source_path) if source_path else None
        new_source = source_lookup(to_pin, source_path) if source_path else None
        old_blob_oid = (
            blob_lookup(from_pin, source_path) if source_path else None
        )
        new_blob_oid = (
            blob_lookup(to_pin, source_path) if source_path else None
        )
        raw_diff = (
            diff_lookup(from_pin, to_pin, source_path) if source_path else b""
        )
        diff_sha256 = sha256_bytes(raw_diff)
        old_source_sha256 = (
            sha256_bytes(old_source.encode("utf-8"))
            if old_source is not None
            else None
        )
        new_source_sha256 = (
            sha256_bytes(new_source.encode("utf-8"))
            if new_source is not None
            else None
        )
        required_tests = rule.get("required_direct_test_references")
        source_scope = _scope_for_class(evidence, card_class)
        literal_changes = rule.get("allowed_presentation_literal_changes")
        tokens_equivalent = False
        normalized_token_sha256: str | None = None
        token_failures: list[str] = []
        if old_source is None or new_source is None:
            rule_failures.append("git_blob_missing")
        else:
            (
                tokens_equivalent,
                token_failures,
                normalized_token_sha256,
            ) = sources_match_after_exact_non_executable_changes(
                old_source,
                new_source,
                literal_changes=literal_changes,
                allowed_import_delta=rule.get("allowed_import_delta"),
                allow_import_reordering=rule.get(
                    "allow_import_reordering"
                ),
            )
            rule_failures.extend(token_failures)
        if rule.get("class") != card_class:
            rule_failures.append("class_mismatch")
        if rule.get("source_path") != source_path:
            rule_failures.append("source_path_mismatch")
        if rule.get("change_kind") != row.get("change_kind"):
            rule_failures.append("change_kind_mismatch")
        if rule.get("required_change_scope") != source_scope:
            rule_failures.append("change_scope_mismatch")
        if (
            rule.get("diff_hash_mode")
            != "git_diff_no_ext_diff_no_textconv_unified0_full_index"
        ):
            rule_failures.append("canonical_diff_hash_mode_mismatch")
        if (
            not SHA256_PATTERN.fullmatch(
                str(rule.get("canonical_diff_sha256") or "")
            )
            or rule.get("canonical_diff_sha256") != diff_sha256
        ):
            rule_failures.append("canonical_diff_sha256_mismatch")
        if (
            not SHA_PATTERN.fullmatch(str(rule.get("from_blob_oid_sha1") or ""))
            or rule.get("from_blob_oid_sha1") != old_blob_oid
        ):
            rule_failures.append("from_blob_oid_mismatch")
        if (
            not SHA_PATTERN.fullmatch(str(rule.get("to_blob_oid_sha1") or ""))
            or rule.get("to_blob_oid_sha1") != new_blob_oid
        ):
            rule_failures.append("to_blob_oid_mismatch")
        if (
            not SHA256_PATTERN.fullmatch(
                str(rule.get("from_source_sha256") or "")
            )
            or rule.get("from_source_sha256") != old_source_sha256
        ):
            rule_failures.append("from_source_sha256_mismatch")
        if (
            not SHA256_PATTERN.fullmatch(
                str(rule.get("to_source_sha256") or "")
            )
            or rule.get("to_source_sha256") != new_source_sha256
        ):
            rule_failures.append("to_source_sha256_mismatch")
        if (
            not SHA256_PATTERN.fullmatch(
                str(rule.get("normalized_token_sha256") or "")
            )
            or rule.get("normalized_token_sha256")
            != normalized_token_sha256
        ):
            rule_failures.append("normalized_token_sha256_mismatch")
        if (
            not isinstance(required_tests, list)
            or not all(isinstance(reference, str) for reference in required_tests)
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
        if row.get("runtime_catalog_status") not in {
            "supported",
            "unsupported",
        }:
            rule_failures.append("runtime_catalog_status_invalid")
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
                "from_blob_oid_sha1": old_blob_oid,
                "to_blob_oid_sha1": new_blob_oid,
                "from_source_sha256": old_source_sha256,
                "to_source_sha256": new_source_sha256,
                "canonical_diff_sha256": diff_sha256,
                "diff_hash_mode": (
                    "git_diff_no_ext_diff_no_textconv_unified0_full_index"
                ),
                "normalized_token_sha256": normalized_token_sha256,
                "non_executable_tokens_equivalent": tokens_equivalent,
                "required_direct_test_references": required_tests,
                "required_test_case_count": row.get("focused_test_case_count"),
                "runtime_catalog_status": row.get("runtime_catalog_status"),
                "runtime_activation_promoted": False,
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
    exact_clearance_without_nominal_reference: list[str] = []
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
                    "canonical_diff_sha256": diff_sha256,
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
            if clearance_rule_id:
                exact_clearance_without_nominal_reference.append(card_name)
            elif row.get("change_kind") == "added":
                group = "added"
                no_reference_groups.setdefault(group, []).append(card_name)
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
            "canonical_diff_hash_mode": (
                "git_diff_no_ext_diff_no_textconv_unified0_full_index"
            ),
            "full_blob_oids_required": True,
            "source_sha256_required": True,
            "unlisted_token_changes_allowed": False,
            "automatic_clearance_does_not_activate_runtime_card": True,
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
        "exact_clearance_cards_without_direct_nominal_reference": sorted(
            exact_clearance_without_nominal_reference,
            key=str.casefold,
        ),
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
                "card_name": "Swordsman, Sharp Scoundrel",
                "action": "Keep the card executable/review-required and add controller-boundary scenarios: an equipped creature you control must trigger once, while an opponent's equipped attacker must not trigger."
            },
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
            "- Exact non-executable clearances: "
            f"`{summary.get('exact_clearance_card_count')}`"
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
        "- Exact semantic clearance activates a runtime card: `false`",
        "",
        "## Exact non-executable clearances",
        "",
    ]
    without_nominal = set(
        report.get("exact_clearance_cards_without_direct_nominal_reference")
        or []
    )
    for card_name in report.get("exact_clearance_cards") or []:
        basis = (
            "exact token proof; no direct nominal reference"
            if card_name in without_nominal
            else "exact token proof plus pinned nominal references"
        )
        lines.append(f"- `{card_name}`: {basis}")
    lines.extend(
        [
            "",
            "## Existing nominal reference cards",
            "",
        ]
    )
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
                "--full-index",
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


def _git_blob_oid_lookup(root: Path) -> BlobLookup:
    def lookup(commit: str, source_path: str) -> str | None:
        result = subprocess.run(
            [
                "git",
                "-C",
                str(root),
                "rev-parse",
                "--verify",
                f"{commit}:{source_path}",
            ],
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        if result.returncode != 0:
            return None
        oid = result.stdout.strip()
        return oid if SHA_PATTERN.fullmatch(oid) else None

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
            blob_lookup=_git_blob_oid_lookup(xmage_root),
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
