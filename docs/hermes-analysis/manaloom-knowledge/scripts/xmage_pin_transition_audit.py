#!/usr/bin/env python3
"""Validate versioned card-level evidence for a pinned XMage transition.

The default audit is deterministic, network-free and read-only. It validates
that every added or modified card implementation in the declared transition is
classified without treating catalog resolution as semantic proof.

``--require-deployable`` is intentionally stricter: it fails while any
card-level review, external residual, or PostgreSQL scope reconciliation is
pending.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from collections import Counter
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DEFAULT_CONTRACT = (
    REPO_ROOT / "docs/hermes-analysis/EXTERNAL_ENGINE_PIN_TRANSITION_CONTRACT.json"
)
AUDIT_SCHEMA_VERSION = "manaloom_xmage_pin_transition_audit_v2_2026-07-28"
CONTRACT_SCHEMA_VERSION = "manaloom_xmage_pin_transition_contract_v2_2026-07-28"
EVIDENCE_SCHEMA_VERSION = "manaloom_xmage_pin_transition_evidence_v2_2026-07-28"
POSTGRES_SCHEMA_VERSION = (
    "manaloom_xmage_postgresql_scope_reconciliation_v1_2026-07-28"
)
SCOPE_AS_OF = date(2026, 7, 28)
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")

ALLOWED_DISPOSITIONS = {
    "focused_upstream_test_passed",
    "focused_upstream_test_passed_card_data_warning_review_required",
    "catalog_supported_semantic_review_required",
    "catalog_supported_nominal_test_passed_semantic_review_required",
    "catalog_supported_regression_only_review_required",
    "external_runtime_quarantine_semantic_defect",
    "external_residual_upstream_unfinished",
}
REVIEW_DISPOSITIONS = {
    "focused_upstream_test_passed_card_data_warning_review_required",
    "catalog_supported_semantic_review_required",
    "catalog_supported_nominal_test_passed_semantic_review_required",
    "catalog_supported_regression_only_review_required",
    "external_runtime_quarantine_semantic_defect",
    "external_residual_upstream_unfinished",
}
EXPECTED_POLICY = {
    "canonical_pin_file": "services/xmage-sidecar/XMAGE_COMMIT",
    "product_source_of_truth": "postgresql_backend",
    "weekly_upstream_delta_is_discovery_only": True,
    "require_exact_git_diff_for_pin_transition": True,
    "require_every_changed_card_classified": True,
    "runtime_catalog_resolution_is_semantic_proof": False,
    "canonical_snapshot_regression_is_new_card_delta_proof": False,
    "require_postgresql_read_only_scope_reconciliation_before_deploy": True,
    "future_only_scope_deferment_requires_activation_gate": True,
    "deploy_requires_qualification_status": "pass",
}

POSTGRES_SCOPE_STATUSES = {
    "product_in_scope",
    "released_missing_from_postgresql",
    "future_deferred",
    "external_runtime_gap",
}
EXPECTED_ACTIONABLE_CARD_FINDINGS = {
    "Ajani Resolute",
    "Consider the Prime Directive",
    "Crimson Cowl, Master of Evil",
    "Falcon's Wing Harness",
    "Hire a Crew",
    "My Precious",
    "Planetarium of Wan Shi Tong",
    "Sky Cycle",
    "Sting, Bilbo's Sword",
}
EXPECTED_INPUT_ARTIFACT_DIGEST_KEYS = {
    "added_87_coverage_request_sha256",
    "added_87_coverage_response_sha256",
    "all_169_test_scenario_miner_v2_sha256",
    "card_data_detailed_comparison_xml_sha256",
    "card_data_warning_inventory_sha256",
    "changed_169_coverage_exchange_sha256",
    "corrected_added_87_test_scenario_miner_sha256",
    "exact_delta_report_sha256",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"JSON root must be an object: {path}")
    return payload


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _safe_repo_path(repo_root: Path, relative_path: str) -> Path | None:
    if not relative_path or Path(relative_path).is_absolute():
        return None
    candidate = (repo_root / relative_path).resolve()
    try:
        candidate.relative_to(repo_root.resolve())
    except ValueError:
        return None
    return candidate


def _check(
    checks: list[dict[str, Any]],
    check_id: str,
    condition: bool,
    message: str,
    *,
    details: dict[str, Any] | None = None,
) -> None:
    checks.append(
        {
            "id": check_id,
            "status": "pass" if condition else "fail",
            "message": message,
            **({"details": details} if details else {}),
        }
    )


def _integer(value: Any) -> int | None:
    return value if isinstance(value, int) and not isinstance(value, bool) else None


def _release_scope_for(registrations: list[dict[str, Any]]) -> str | None:
    release_dates: list[date] = []
    try:
        for registration in registrations:
            raw_date = registration.get("release_date")
            if not isinstance(raw_date, str):
                return None
            release_dates.append(date.fromisoformat(raw_date))
    except ValueError:
        return None
    if not release_dates:
        return None
    return (
        "future_only"
        if all(release_date > SCOPE_AS_OF for release_date in release_dates)
        else "has_current_or_prior_registration"
    )


def _postgres_pass_shape_valid(
    postgres: dict[str, Any],
    *,
    expected_card_names: set[str],
) -> bool:
    rows = postgres.get("card_results")
    scope_counts = postgres.get("scope_counts")
    if not isinstance(rows, list) or not isinstance(scope_counts, dict):
        return False
    object_rows = [row for row in rows if isinstance(row, dict)]
    row_names = [str(row.get("card_name") or "") for row in object_rows]
    normalized_counts = {
        str(key): _integer(value) for key, value in scope_counts.items()
    }
    if (
        postgres.get("schema_version") != POSTGRES_SCHEMA_VERSION
        or postgres.get("canonical_wrapper") != "server/bin/with_new_server_pg.sh"
        or postgres.get("transaction_mode") != "read_only"
        or postgres.get("transaction_read_only") is not True
        or postgres.get("writes_performed") is not False
        or (_integer(postgres.get("queries_executed")) or 0) <= 0
        or postgres.get("requested_card_count") != len(expected_card_names)
        or postgres.get("reconciled_card_count") != len(expected_card_names)
        or postgres.get("ambiguity_count") != 0
        or not SHA256_PATTERN.fullmatch(str(postgres.get("rows_sha256") or ""))
        or len(object_rows) != len(rows)
        or not object_rows
        or set(row_names) != expected_card_names
        or len(row_names) != len(set(row_names))
        or set(normalized_counts) != POSTGRES_SCOPE_STATUSES
        or any(value is None or value < 0 for value in normalized_counts.values())
        or sum(normalized_counts.values()) != len(expected_card_names)
    ):
        return False

    observed_statuses: Counter[str] = Counter()
    for row in object_rows:
        scope_status = str(row.get("product_scope_status") or "")
        match_count = _integer(row.get("postgresql_match_count"))
        if (
            scope_status not in POSTGRES_SCOPE_STATUSES
            or match_count is None
            or match_count < 0
        ):
            return False
        if scope_status in {"product_in_scope", "external_runtime_gap"}:
            if match_count <= 0:
                return False
        elif match_count != 0:
            return False
        observed_statuses[scope_status] += 1

    return dict(sorted(observed_statuses.items())) == dict(
        sorted(normalized_counts.items())
    )


def _validate_card_rows(
    evidence: dict[str, Any],
    expected: dict[str, Any],
    checks: list[dict[str, Any]],
) -> dict[str, Any]:
    raw_cards = evidence.get("cards")
    cards = raw_cards if isinstance(raw_cards, list) else []
    rows = [row for row in cards if isinstance(row, dict)]
    classes = [str(row.get("class") or "") for row in rows]
    paths = [str(row.get("source_path") or "") for row in rows]
    names = [str(row.get("card_name") or "") for row in rows]
    kinds = Counter(str(row.get("change_kind") or "") for row in rows)
    dispositions = Counter(str(row.get("disposition") or "") for row in rows)
    catalog_statuses = Counter(
        str(row.get("runtime_catalog_status") or "") for row in rows
    )
    release_scopes = Counter(
        str(row.get("release_scope_as_of_2026_07_28") or "") for row in rows
    )
    direct_test_reference_counts = Counter(
        str(row.get("change_kind") or "")
        for row in rows
        if isinstance(row.get("direct_test_references"), list)
        and bool(row.get("direct_test_references"))
    )

    _check(
        checks,
        "card_rows_complete",
        len(rows) == len(cards) == expected.get("changed_card_implementations"),
        "Every changed card implementation must have one object row.",
        details={"observed": len(rows), "expected": expected.get("changed_card_implementations")},
    )
    _check(
        checks,
        "card_identity_unique",
        all(classes)
        and all(paths)
        and all(names)
        and len(classes) == len(set(classes))
        and len(paths) == len(set(paths)),
        "Card classes and source paths must be non-empty and unique.",
    )
    _check(
        checks,
        "card_change_counts",
        kinds
        == Counter(
            {
                "added": expected.get("added_card_implementations"),
                "modified": expected.get("modified_card_implementations"),
            }
        ),
        "Added and modified card counts must match the exact Git delta.",
        details={"observed": dict(sorted(kinds.items()))},
    )
    _check(
        checks,
        "card_dispositions_known",
        set(dispositions) <= ALLOWED_DISPOSITIONS
        and "" not in dispositions
        and sum(dispositions.values()) == len(rows),
        "Every changed card must use one explicit transition disposition.",
        details={"observed": dict(sorted(dispositions.items()))},
    )
    _check(
        checks,
        "runtime_catalog_counts",
        catalog_statuses
        == Counter(
            {
                "supported": expected.get("runtime_catalog_supported"),
                "unsupported": expected.get("runtime_catalog_unsupported"),
            }
        ),
        "Per-card qualified runtime support classifications must match the transition proof.",
        details={"observed": dict(sorted(catalog_statuses.items()))},
    )

    malformed: list[str] = []
    invalid_release_scopes: list[str] = []
    for row in rows:
        card_class = str(row.get("class") or "unknown")
        kind = row.get("change_kind")
        disposition = row.get("disposition")
        catalog_status = row.get("runtime_catalog_status")
        registrations = row.get("set_registrations")
        direct_tests = row.get("direct_test_references")
        focused_cases = _integer(row.get("focused_test_case_count"))
        valid = (
            kind in {"added", "modified"}
            and isinstance(registrations, list)
            and bool(registrations)
            and all(
                isinstance(registration, dict)
                and registration.get("card_name")
                and registration.get("set_code")
                and registration.get("release_date")
                for registration in registrations
            )
            and isinstance(direct_tests, list)
            and focused_cases is not None
            and focused_cases >= 0
        )
        if (
            not isinstance(registrations, list)
            or _release_scope_for(registrations)
            != row.get("release_scope_as_of_2026_07_28")
        ):
            invalid_release_scopes.append(card_class)
        if disposition == "focused_upstream_test_passed":
            valid = (
                valid
                and kind == "added"
                and catalog_status == "supported"
                and bool(direct_tests)
                and focused_cases > 0
            )
        elif (
            disposition
            == "focused_upstream_test_passed_card_data_warning_review_required"
        ):
            valid = (
                valid
                and kind == "added"
                and catalog_status == "supported"
                and bool(direct_tests)
                and focused_cases > 0
                and isinstance(row.get("card_data_warnings"), list)
                and bool(row.get("card_data_warnings"))
            )
        elif disposition == "catalog_supported_semantic_review_required":
            valid = (
                valid
                and kind == "added"
                and catalog_status == "supported"
                and not direct_tests
                and focused_cases == 0
            )
        elif (
            disposition
            == "catalog_supported_nominal_test_passed_semantic_review_required"
        ):
            valid = (
                valid
                and kind == "modified"
                and catalog_status == "supported"
                and bool(direct_tests)
                and focused_cases > 0
            )
        elif disposition == "catalog_supported_regression_only_review_required":
            valid = (
                valid
                and kind == "modified"
                and catalog_status == "supported"
                and not direct_tests
                and focused_cases == 0
            )
        elif disposition == "external_residual_upstream_unfinished":
            residual = row.get("external_residual")
            valid = (
                valid
                and kind == "added"
                and catalog_status == "unsupported"
                and isinstance(residual, dict)
                and residual.get("reason") == "removed_from_xmage_catalog_as_unfinished"
                and residual.get("forge_exact_match_count") == 0
            )
        elif disposition == "external_runtime_quarantine_semantic_defect":
            residual = row.get("external_residual")
            valid = (
                valid
                and kind == "modified"
                and catalog_status == "unsupported"
                and isinstance(residual, dict)
                and residual.get("reason")
                == "pinned_xmage_semantic_defect_quarantined"
                and residual.get("reason_code")
                == "xmage_pin_semantic_defect"
                and residual.get("qualification_engine_commit")
                == evidence.get("to_pin")
                and residual.get("policy_path")
                == (
                    "services/xmage-sidecar/src/main/java/com/manaloom/xmage/"
                    "XmageCardQualificationPolicy.java"
                )
            )
        else:
            valid = False
        if not valid:
            malformed.append(card_class)

    _check(
        checks,
        "card_disposition_evidence",
        not malformed,
        "Each disposition must carry the evidence required by its exact meaning.",
        details={"malformed_classes": malformed},
    )
    _check(
        checks,
        "card_release_scope_evidence",
        not invalid_release_scopes
        and set(release_scopes)
        <= {"future_only", "has_current_or_prior_registration"}
        and sum(release_scopes.values()) == len(rows),
        "Every release scope must be derived from the declared set release dates.",
        details={"invalid_classes": invalid_release_scopes},
    )

    modified_scope = (
        evidence.get("modified_change_scope")
        if isinstance(evidence.get("modified_change_scope"), dict)
        else {}
    )
    executable_classes = modified_scope.get("executable_or_mixed_classes")
    comment_only_classes = modified_scope.get("comment_only_classes")
    scope_counts = modified_scope.get("counts")
    executable_set = (
        set(executable_classes) if isinstance(executable_classes, list) else set()
    )
    comment_only_set = (
        set(comment_only_classes)
        if isinstance(comment_only_classes, list)
        else set()
    )
    modified_class_set = {
        str(row.get("class") or "")
        for row in rows
        if row.get("change_kind") == "modified"
    }
    presentation_set = modified_class_set - executable_set - comment_only_set
    _check(
        checks,
        "modified_change_scope",
        modified_scope.get("classification_method")
        == "exact_git_hunk_manual_review"
        and isinstance(scope_counts, dict)
        and len(executable_set) == len(executable_classes or []) == 26
        and len(comment_only_set) == len(comment_only_classes or []) == 2
        and not (executable_set & comment_only_set)
        and executable_set | comment_only_set <= modified_class_set
        and len(presentation_set) == 54
        and modified_scope.get("presentation_or_metadata_count") == 54
        and scope_counts
        == {
            "comment_only": 2,
            "executable_or_mixed": 26,
            "presentation_or_metadata": 54,
            "total_modified": 82,
        },
        "All modified cards must be classified by executable, presentation/metadata or comment-only source change.",
    )

    summary = evidence.get("card_summary")
    summary = summary if isinstance(summary, dict) else {}
    _check(
        checks,
        "card_summary_matches_rows",
        summary.get("total_changed") == len(rows)
        and summary.get("change_kinds") == dict(sorted(kinds.items()))
        and summary.get("dispositions") == dict(sorted(dispositions.items()))
        and summary.get("runtime_catalog_statuses")
        == dict(sorted(catalog_statuses.items())),
        "The card summary must be derived exactly from the versioned rows.",
    )
    _check(
        checks,
        "card_scope_summary_matches_rows",
        summary.get("release_scopes") == dict(sorted(release_scopes.items()))
        and summary.get("changed_with_direct_nominal_test_reference")
        == sum(direct_test_reference_counts.values())
        and summary.get("added_with_direct_nominal_test_reference")
        == direct_test_reference_counts.get("added", 0)
        and summary.get("modified_with_direct_nominal_test_reference")
        == direct_test_reference_counts.get("modified", 0),
        "Release-scope and direct-test summary counts must be derived from card rows.",
    )
    return {
        "row_count": len(rows),
        "card_names": sorted(names),
        "change_kinds": dict(sorted(kinds.items())),
        "dispositions": dict(sorted(dispositions.items())),
        "runtime_catalog_statuses": dict(sorted(catalog_statuses.items())),
        "release_scopes": dict(sorted(release_scopes.items())),
        "review_required_count": sum(
            count for value, count in dispositions.items() if value in REVIEW_DISPOSITIONS
        ),
    }


def build_report(
    contract: dict[str, Any],
    evidence: dict[str, Any],
    *,
    repo_root: Path = REPO_ROOT,
    evidence_sha256: str,
    require_deployable: bool = False,
) -> dict[str, Any]:
    repo_root = repo_root.resolve()
    checks: list[dict[str, Any]] = []
    transition = (
        contract.get("active_transition")
        if isinstance(contract.get("active_transition"), dict)
        else {}
    )
    expected = (
        transition.get("expected")
        if isinstance(transition.get("expected"), dict)
        else {}
    )

    _check(
        checks,
        "contract_schema",
        contract.get("schema_version") == CONTRACT_SCHEMA_VERSION,
        f"Transition contract schema must be {CONTRACT_SCHEMA_VERSION}.",
    )
    _check(
        checks,
        "transition_policy",
        contract.get("policy") == EXPECTED_POLICY,
        "Pin transition policy must preserve source-of-truth and proof boundaries.",
        details={"observed": contract.get("policy")},
    )

    from_pin = str(transition.get("from_pin") or "")
    to_pin = str(transition.get("to_pin") or "")
    transition_id = str(transition.get("id") or "")
    _check(
        checks,
        "transition_identity",
        bool(transition_id)
        and bool(SHA_PATTERN.fullmatch(from_pin))
        and bool(SHA_PATTERN.fullmatch(to_pin))
        and from_pin != to_pin,
        "Active transition must identify two distinct exact Git SHAs.",
    )
    canonical_pin_path = _safe_repo_path(
        repo_root, EXPECTED_POLICY["canonical_pin_file"]
    )
    try:
        canonical_pin = (
            canonical_pin_path.read_text(encoding="utf-8").strip()
            if canonical_pin_path
            else ""
        )
    except OSError:
        canonical_pin = ""
    _check(
        checks,
        "canonical_pin_matches_transition",
        canonical_pin == to_pin,
        "The active evidence must qualify the canonical XMage pin.",
        details={"canonical_pin": canonical_pin, "transition_to_pin": to_pin},
    )
    _check(
        checks,
        "evidence_digest",
        SHA256_PATTERN.fullmatch(str(transition.get("evidence_sha256") or ""))
        is not None
        and evidence_sha256 == transition.get("evidence_sha256"),
        "The versioned transition evidence digest must match the contract.",
        details={
            "expected": transition.get("evidence_sha256"),
            "observed": evidence_sha256,
        },
    )
    _check(
        checks,
        "evidence_identity",
        evidence.get("schema_version") == EVIDENCE_SCHEMA_VERSION
        and evidence.get("transition_id") == transition_id
        and evidence.get("from_pin") == from_pin
        and evidence.get("to_pin") == to_pin,
        "Evidence schema, transition id and pins must match the active contract.",
    )

    input_digests = (
        evidence.get("input_artifact_digests")
        if isinstance(evidence.get("input_artifact_digests"), dict)
        else {}
    )
    _check(
        checks,
        "input_artifact_digests",
        set(input_digests) == EXPECTED_INPUT_ARTIFACT_DIGEST_KEYS
        and all(
            SHA256_PATTERN.fullmatch(str(value or "")) is not None
            for value in input_digests.values()
        ),
        "Every transition input artifact must have one explicit SHA-256 digest.",
    )

    source_delta = (
        evidence.get("source_delta")
        if isinstance(evidence.get("source_delta"), dict)
        else {}
    )
    exact_expected = {
        "commit_count": expected.get("commit_count"),
        "changed_path_count": expected.get("changed_path_count"),
        "changed_card_implementations": expected.get("changed_card_implementations"),
        "added_card_implementations": expected.get("added_card_implementations"),
        "modified_card_implementations": expected.get("modified_card_implementations"),
    }
    _check(
        checks,
        "exact_git_delta",
        source_delta.get("audit_mode") == "read_only_local_git_object_diff"
        and source_delta.get("old_is_ancestor") is True
        and source_delta.get("github_compare_file_limit_used") is False
        and all(source_delta.get(key) == value for key, value in exact_expected.items())
        and SHA256_PATTERN.fullmatch(
            str(source_delta.get("name_status_sha256") or "")
        )
        is not None
        and SHA256_PATTERN.fullmatch(str(source_delta.get("raw_diff_sha256") or ""))
        is not None,
        "The pin transition must use the complete local Git object diff, not the capped compare list.",
        details={"observed": source_delta, "expected": exact_expected},
    )

    card_summary = _validate_card_rows(evidence, expected, checks)
    expected_card_names = set(card_summary.pop("card_names"))

    runtime = (
        evidence.get("runtime_catalog")
        if isinstance(evidence.get("runtime_catalog"), dict)
        else {}
    )
    policy_test = (
        runtime.get("qualification_policy_test")
        if isinstance(runtime.get("qualification_policy_test"), dict)
        else {}
    )
    policy_path_value = str(runtime.get("qualification_policy_path") or "")
    policy_source_path = _safe_repo_path(repo_root, policy_path_value)
    try:
        policy_source = (
            policy_source_path.read_text(encoding="utf-8")
            if policy_source_path
            else ""
        )
    except OSError:
        policy_source = ""
    _check(
        checks,
        "runtime_card_qualification_policy_source",
        to_pin in policy_source
        and '"Planetarium of Wan Shi Tong"' in policy_source
        and '"xmage_pin_semantic_defect"' in policy_source
        and '"Prudent Fateseer"' in policy_source
        and '"xmage_upstream_mechanic_unfinished"' in policy_source
        and "requireEngineCommit" in policy_source,
        "The pin-scoped card qualification policy source must match the transition evidence.",
    )
    _check(
        checks,
        "runtime_catalog_proof",
        runtime.get("engine_commit") == to_pin
        and runtime.get("catalog_ready") is True
        and runtime.get("total") == expected.get("changed_card_implementations")
        and runtime.get("catalog_resolved_before_qualification")
        == expected.get("runtime_catalog_resolved_before_qualification")
        and runtime.get("catalog_unresolved_before_qualification")
        == expected.get("runtime_catalog_unresolved_before_qualification")
        and runtime.get("supported") == expected.get("runtime_catalog_supported")
        and runtime.get("unsupported") == expected.get("runtime_catalog_unsupported")
        and runtime.get("qualification_policy_engine_commit") == to_pin
        and runtime.get("qualification_policy_path")
        == (
            "services/xmage-sidecar/src/main/java/com/manaloom/xmage/"
            "XmageCardQualificationPolicy.java"
        )
        and runtime.get("unsupported_card_names")
        == ["Planetarium of Wan Shi Tong", "Prudent Fateseer"]
        and policy_test.get("tests") == expected.get("qualified_policy_test_count")
        and policy_test.get("failures") == 0
        and policy_test.get("errors") == 0
        and policy_test.get("skipped") == 0
        and runtime.get("catalog_resolution_is_semantic_proof") is False,
        "Runtime coverage must reconcile all changed cards without claiming semantic proof.",
    )

    tests = (
        evidence.get("upstream_focused_tests")
        if isinstance(evidence.get("upstream_focused_tests"), dict)
        else {}
    )
    suites = tests.get("suites") if isinstance(tests.get("suites"), list) else []
    suite_total = sum(
        int(row.get("tests", 0)) for row in suites if isinstance(row, dict)
    )
    _check(
        checks,
        "upstream_focused_test_run",
        tests.get("result") == "pass"
        and tests.get("tests") == expected.get("upstream_focused_test_count")
        and suite_total == tests.get("tests")
        and all(
            isinstance(row, dict)
            and row.get("failures") == 0
            and row.get("errors") == 0
            and row.get("skipped") == 0
            for row in suites
        ),
        "The exact changed-scenario XMage test suite must be recorded without failures.",
    )

    nominal_tests = (
        evidence.get("transition_card_nominal_tests")
        if isinstance(evidence.get("transition_card_nominal_tests"), dict)
        else {}
    )
    nominal_suites = (
        nominal_tests.get("suites")
        if isinstance(nominal_tests.get("suites"), list)
        else []
    )
    nominal_suite_total = sum(
        int(row.get("tests", 0))
        for row in nominal_suites
        if isinstance(row, dict)
    )
    focused_case_total = sum(
        int(row.get("focused_test_case_count", 0))
        for row in evidence.get("cards", [])
        if isinstance(row, dict)
    )
    expected_changed_card_count = _integer(
        expected.get("changed_card_implementations")
    )
    expected_direct_reference_count = _integer(
        expected.get("direct_test_reference_card_count")
    )
    _check(
        checks,
        "transition_card_nominal_test_inventory",
        nominal_tests.get("miner_schema_version")
        == "manaloom_xmage_test_scenario_miner_v2_2026-07-28"
        and expected_changed_card_count is not None
        and expected_direct_reference_count is not None
        and nominal_tests.get("requested_card_count")
        == expected_changed_card_count
        and nominal_tests.get("cards_with_exact_test_reference")
        == expected_direct_reference_count
        and nominal_tests.get("cards_without_exact_test_reference")
        == expected_changed_card_count - expected_direct_reference_count
        and nominal_tests.get("usable_scenario_candidate_count")
        == focused_case_total
        and nominal_tests.get("xmage_test_files_scanned") == 2017
        and nominal_tests.get("short_split_face_terms_rejected") is True
        and nominal_tests.get("result") == "pass"
        and nominal_tests.get("tests")
        == expected.get("transition_nominal_test_count")
        and nominal_suite_total == nominal_tests.get("tests")
        and all(
            isinstance(row, dict)
            and row.get("failures") == 0
            and row.get("errors") == 0
            and row.get("skipped") == 0
            for row in nominal_suites
        ),
        "The all-card exact-reference inventory and selected upstream tests must reconcile.",
    )

    verifier = (
        evidence.get("upstream_card_data_verifier")
        if isinstance(evidence.get("upstream_card_data_verifier"), dict)
        else {}
    )
    requested_set_codes = verifier.get("requested_set_codes")
    _check(
        checks,
        "upstream_card_data_verifier",
        verifier.get("engine_commit") == to_pin
        and verifier.get("result") == "pass"
        and verifier.get("test_class") == "mage.verify.VerifyCardDataTest"
        and verifier.get("test_method") == "test_verifyCards"
        and verifier.get("tests") == 1
        and verifier.get("failures") == 0
        and verifier.get("errors") == 0
        and verifier.get("skipped") == 0
        and isinstance(requested_set_codes, list)
        and requested_set_codes
        and len(requested_set_codes) == len(set(requested_set_codes))
        and verifier.get("is_gameplay_semantic_proof") is False,
        "The official XMage card-data verifier must pass without being promoted to gameplay proof.",
    )

    diagnostics = (
        evidence.get("card_data_diagnostics")
        if isinstance(evidence.get("card_data_diagnostics"), dict)
        else {}
    )
    actionable_findings = (
        diagnostics.get("actionable_findings")
        if isinstance(diagnostics.get("actionable_findings"), list)
        else []
    )
    actionable_rows = [
        row for row in actionable_findings if isinstance(row, dict)
    ]
    actionable_names = {
        str(row.get("card_name") or "") for row in actionable_rows
    }
    planetarium_finding = next(
        (
            row
            for row in actionable_rows
            if row.get("card_name") == "Planetarium of Wan Shi Tong"
        ),
        {},
    )
    _check(
        checks,
        "card_data_diagnostics",
        diagnostics.get("status") in {"pass", "review_required"}
        and diagnostics.get("cataloged_classes_checked") == 168
        and diagnostics.get("good_face_count") == 154
        and diagnostics.get("wrong_face_count") == 16
        and diagnostics.get("missing_reference_face_count") == 3
        and len(actionable_rows) == len(actionable_findings)
        == expected.get("card_data_actionable_finding_count")
        and actionable_names == EXPECTED_ACTIONABLE_CARD_FINDINGS
        and actionable_names <= expected_card_names
        and len(actionable_names) == len(actionable_rows)
        and all(
            row.get("severity") in {"mechanical", "visible_rules_text"}
            and row.get("status") in {"quarantined", "upstream_fix_required"}
            and row.get("evidence")
            for row in actionable_rows
        )
        and planetarium_finding.get("severity") == "mechanical"
        and planetarium_finding.get("status") == "quarantined",
        "Detailed card-data findings must preserve every actionable warning and the mechanical quarantine.",
    )

    snapshot = (
        evidence.get("canonical_snapshot_regression")
        if isinstance(evidence.get("canonical_snapshot_regression"), dict)
        else {}
    )
    _check(
        checks,
        "canonical_snapshot_boundary",
        snapshot.get("snapshot_name_count") == 8073
        and snapshot.get("added_exact_name_matches") == 0
        and snapshot.get("is_new_card_delta_proof") is False,
        "The prior canonical snapshot must remain classified as regression-only evidence.",
    )

    postgres = (
        evidence.get("postgresql_scope_reconciliation")
        if isinstance(evidence.get("postgresql_scope_reconciliation"), dict)
        else {}
    )
    postgres_status = postgres.get("status")
    postgres_shape_valid = (
        (
            postgres_status == "pass"
            and _postgres_pass_shape_valid(
                postgres,
                expected_card_names=expected_card_names,
            )
        )
        or (
            postgres_status == "blocked"
            and postgres.get("reason")
            == "missing_approved_ssh_host_key_sha256"
            and postgres.get("queries_executed") == 0
            and postgres.get("writes_performed") is False
        )
    )
    _check(
        checks,
        "postgresql_reconciliation_evidence",
        postgres_shape_valid,
        "PostgreSQL reconciliation must pass or record the exact safe preflight block.",
    )

    future_gate = (
        evidence.get("future_release_activation_gate")
        if isinstance(evidence.get("future_release_activation_gate"), dict)
        else {}
    )
    future_only_count = card_summary["release_scopes"].get("future_only", 0)
    future_gate_status = future_gate.get("status")
    future_gate_shape_valid = (
        (
            future_gate_status == "pass"
            and future_gate.get("schema_version")
            == "manaloom_future_card_activation_gate_v1_2026-07-28"
            and future_gate.get("future_only_card_count") == future_only_count
            and isinstance(future_gate.get("enforced_by"), list)
            and bool(future_gate.get("enforced_by"))
            and (_integer(future_gate.get("tests")) or 0) > 0
            and future_gate.get("result") == "pass"
        )
        or (
            future_gate_status == "missing"
            and future_gate.get("reason")
            == "no_versioned_product_release_activation_gate_evidence"
            and future_gate.get("future_only_card_count") == future_only_count
        )
    )
    _check(
        checks,
        "future_release_activation_gate",
        future_gate_shape_valid,
        "Future-only scope requires a versioned release-activation gate or an explicit safe block.",
    )

    qualification = (
        evidence.get("qualification")
        if isinstance(evidence.get("qualification"), dict)
        else {}
    )
    proof_ready = (
        card_summary["review_required_count"] == 0
        and diagnostics.get("status") == "pass"
        and postgres_status == "pass"
        and postgres_shape_valid
        and (future_only_count == 0 or future_gate_status == "pass")
        and future_gate_shape_valid
        and runtime.get("unsupported") == 0
    )
    computed_deployable = proof_ready
    required_blocking_reasons: set[str] = set()
    if card_summary["review_required_count"] > 0:
        required_blocking_reasons.add(
            "changed_card_semantic_reviews_or_residuals_pending"
        )
    if diagnostics.get("status") != "pass":
        required_blocking_reasons.add("card_data_diagnostics_not_passed")
    if postgres_status != "pass" or not postgres_shape_valid:
        required_blocking_reasons.add(
            "postgresql_product_scope_reconciliation_not_passed"
        )
    if future_only_count > 0 and future_gate_status != "pass":
        required_blocking_reasons.add(
            "future_only_card_activation_gate_not_passed"
        )
    if runtime.get("unsupported") != 0:
        required_blocking_reasons.add(
            "external_runtime_unsupported_cards_present"
        )
    declared_blocking_reasons = qualification.get("blocking_reasons")
    blocking_reason_set = (
        set(declared_blocking_reasons)
        if isinstance(declared_blocking_reasons, list)
        and all(isinstance(value, str) for value in declared_blocking_reasons)
        else set()
    )
    _check(
        checks,
        "qualification_consistency",
        qualification.get("status")
        == ("pass" if proof_ready else "review_required")
        and qualification.get("deployment_allowed") is computed_deployable
        and required_blocking_reasons <= blocking_reason_set
        and (not computed_deployable or not blocking_reason_set),
        "Deployment permission must be derived from card review, residual and PostgreSQL evidence.",
        details={
            "computed_deployable": computed_deployable,
            "required_blocking_reasons": sorted(required_blocking_reasons),
            "declared": qualification,
        },
    )
    if require_deployable:
        _check(
            checks,
            "deployment_qualification",
            computed_deployable,
            "XMage deployment is blocked until the transition qualification is pass.",
            details={
                "qualification_status": qualification.get("status"),
                "review_required_count": card_summary["review_required_count"],
                "postgresql_reconciliation_status": postgres_status,
                "future_release_activation_gate_status": future_gate_status,
                "runtime_unsupported": runtime.get("unsupported"),
            },
        )

    failures = [row for row in checks if row["status"] == "fail"]
    return {
        "schema_version": AUDIT_SCHEMA_VERSION,
        "generated_at_utc": utc_now(),
        "status": "pass" if not failures else "fail",
        "qualification_status": qualification.get("status"),
        "deployment_allowed": computed_deployable,
        "strict_deployment_check_requested": require_deployable,
        "safety": {
            "read_only": True,
            "network_used": False,
            "postgres_queries": 0,
            "postgres_writes": False,
            "sqlite_writes": False,
            "source_mutations": False,
        },
        "transition": {
            "id": transition_id,
            "from_pin": from_pin,
            "to_pin": to_pin,
            "evidence_sha256": evidence_sha256,
        },
        "card_summary": card_summary,
        "checks": checks,
        "failures": failures,
    }


def render_markdown(report: dict[str, Any]) -> str:
    summary = report.get("card_summary") or {}
    lines = [
        "# XMage Pin Transition Audit",
        "",
        f"- Generated UTC: `{report.get('generated_at_utc')}`",
        f"- Audit status: `{report.get('status')}`",
        f"- Qualification: `{report.get('qualification_status')}`",
        f"- Deployment allowed: `{report.get('deployment_allowed')}`",
        f"- Changed cards classified: `{summary.get('row_count')}`",
        f"- Reviews/residuals pending: `{summary.get('review_required_count')}`",
        "",
        "## Dispositions",
        "",
    ]
    for disposition, count in (summary.get("dispositions") or {}).items():
        lines.append(f"- `{disposition}`: `{count}`")
    if report.get("failures"):
        lines.extend(["", "## Failures", ""])
        for failure in report["failures"]:
            lines.append(f"- `{failure.get('id')}`: {failure.get('message')}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(report: dict[str, Any], output_prefix: Path) -> None:
    output_prefix.parent.mkdir(parents=True, exist_ok=True)
    output_prefix.with_suffix(".json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    output_prefix.with_suffix(".md").write_text(
        render_markdown(report),
        encoding="utf-8",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--repo-root", type=Path, default=REPO_ROOT)
    parser.add_argument("--evidence", type=Path)
    parser.add_argument("--output-prefix", type=Path)
    parser.add_argument("--require-deployable", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        contract = load_json(args.contract)
        transition = contract.get("active_transition")
        if not isinstance(transition, dict):
            raise ValueError("active_transition must be an object")
        if args.evidence:
            evidence_path = args.evidence.resolve()
        else:
            evidence_path = _safe_repo_path(
                args.repo_root.resolve(), str(transition.get("evidence_path") or "")
            )
            if evidence_path is None:
                raise ValueError("evidence_path must resolve inside the repository")
        evidence = load_json(evidence_path)
        digest = file_sha256(evidence_path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"xmage_pin_transition_contract_error={exc}")
        return 2

    report = build_report(
        contract,
        evidence,
        repo_root=args.repo_root,
        evidence_sha256=digest,
        require_deployable=args.require_deployable,
    )
    if args.output_prefix:
        write_outputs(report, args.output_prefix)
        print(f"json_output={args.output_prefix.with_suffix('.json')}")
        print(f"markdown_output={args.output_prefix.with_suffix('.md')}")
    print(f"status={report['status']}")
    print(f"qualification_status={report['qualification_status']}")
    print(f"deployment_allowed={str(report['deployment_allowed']).lower()}")
    print(
        "cards_classified="
        f"{report['card_summary']['row_count']}"
    )
    print(
        "reviews_or_residuals_pending="
        f"{report['card_summary']['review_required_count']}"
    )
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
