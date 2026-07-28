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
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DEFAULT_CONTRACT = (
    REPO_ROOT / "docs/hermes-analysis/EXTERNAL_ENGINE_PIN_TRANSITION_CONTRACT.json"
)
AUDIT_SCHEMA_VERSION = "manaloom_xmage_pin_transition_audit_v1_2026-07-28"
CONTRACT_SCHEMA_VERSION = "manaloom_xmage_pin_transition_contract_v1_2026-07-28"
EVIDENCE_SCHEMA_VERSION = "manaloom_xmage_pin_transition_evidence_v1_2026-07-28"
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")

ALLOWED_DISPOSITIONS = {
    "focused_upstream_test_passed",
    "catalog_supported_semantic_review_required",
    "catalog_supported_regression_only_review_required",
    "external_residual_upstream_unfinished",
}
REVIEW_DISPOSITIONS = {
    "catalog_supported_semantic_review_required",
    "catalog_supported_regression_only_review_required",
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
    "deploy_requires_qualification_status": "pass",
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
        "Per-card runtime catalog classifications must match the transition proof.",
        details={"observed": dict(sorted(catalog_statuses.items()))},
    )

    malformed: list[str] = []
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
        if disposition == "focused_upstream_test_passed":
            valid = (
                valid
                and kind == "added"
                and catalog_status == "supported"
                and bool(direct_tests)
                and focused_cases > 0
            )
        elif disposition == "catalog_supported_semantic_review_required":
            valid = (
                valid
                and kind == "added"
                and catalog_status == "supported"
                and not direct_tests
                and focused_cases == 0
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
    return {
        "row_count": len(rows),
        "change_kinds": dict(sorted(kinds.items())),
        "dispositions": dict(sorted(dispositions.items())),
        "runtime_catalog_statuses": dict(sorted(catalog_statuses.items())),
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

    runtime = (
        evidence.get("runtime_catalog")
        if isinstance(evidence.get("runtime_catalog"), dict)
        else {}
    )
    _check(
        checks,
        "runtime_catalog_proof",
        runtime.get("engine_commit") == to_pin
        and runtime.get("catalog_ready") is True
        and runtime.get("total") == expected.get("changed_card_implementations")
        and runtime.get("supported") == expected.get("runtime_catalog_supported")
        and runtime.get("unsupported") == expected.get("runtime_catalog_unsupported")
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
        postgres_status == "pass"
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

    qualification = (
        evidence.get("qualification")
        if isinstance(evidence.get("qualification"), dict)
        else {}
    )
    computed_deployable = (
        card_summary["review_required_count"] == 0
        and postgres_status == "pass"
        and runtime.get("unsupported") == 0
        and qualification.get("status") == "pass"
    )
    _check(
        checks,
        "qualification_consistency",
        qualification.get("status") in {"pass", "review_required"}
        and qualification.get("deployment_allowed") is computed_deployable
        and (
            computed_deployable
            or bool(qualification.get("blocking_reasons"))
        ),
        "Deployment permission must be derived from card review, residual and PostgreSQL evidence.",
        details={
            "computed_deployable": computed_deployable,
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
