#!/usr/bin/env python3
"""Validate versioned card-level evidence for a pinned XMage transition.

The default audit is deterministic, network-free and read-only. It validates
that every added or modified card implementation in the declared transition is
classified without treating catalog resolution as semantic proof.

``--require-deployable`` is intentionally stricter: it fails while any
product-scope card review or required PostgreSQL/runtime evidence is pending.
Exact quarantines and activation-blocked cards remain unavailable without
becoming an unrelated global-deployment blocker.
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
ACTIVATION_POLICY_SCHEMA_VERSION = (
    "manaloom_xmage_transition_activation_policy_v1_2026-07-30"
)
FUTURE_ACTIVATION_GATE_SCHEMA_VERSION = (
    "manaloom_future_card_activation_gate_v1_2026-07-28"
)
PRODUCT_SCOPE_FOCUSED_TEST_SCHEMA_VERSION = (
    "manaloom_xmage_product_scope_focused_test_evidence_v2_2026-07-30"
)
REVIEW_DERIVATIVE_LINK_SCHEMA_VERSION = (
    "manaloom_xmage_transition_review_derivative_links_v1_2026-07-30"
)
ACTIVE_SCOPE_MATRIX_SCHEMA_VERSION = (
    "manaloom_xmage_active_scope_semantic_matrix_v1_2026-07-30"
)
COMPACT_REVIEW_INDEX_SCHEMA_VERSION = (
    "manaloom_xmage_transition_compact_review_index_v1_2026-07-30"
)
NOMINAL_REVIEW_SCHEMA_VERSION = (
    "manaloom_xmage_transition_nominal_review_v2_2026-07-30"
)
NOMINAL_POLICY_SCHEMA_VERSION = (
    "manaloom_xmage_transition_nominal_review_policy_v2_2026-07-30"
)
CLEARANCE_DISPOSITION = "exact_non_executable_tokens_passed"
PRODUCT_FOCUSED_CLEARANCE_DISPOSITION = (
    "product_scope_focused_semantic_tests_passed"
)
ACTIVATION_BLOCKED_DISPOSITION = (
    "activation_blocked_pending_product_semantic_review"
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
    "external_runtime_quarantine_known_upstream_gap",
    "external_residual_upstream_unfinished",
    ACTIVATION_BLOCKED_DISPOSITION,
    CLEARANCE_DISPOSITION,
    PRODUCT_FOCUSED_CLEARANCE_DISPOSITION,
}
REVIEW_DISPOSITIONS = {
    "focused_upstream_test_passed_card_data_warning_review_required",
    "catalog_supported_semantic_review_required",
    "catalog_supported_nominal_test_passed_semantic_review_required",
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
    "postgresql_scope_reconciliation_v1_sha256",
    "product_scope_focused_test_evidence_v2_sha256",
    "sidecar_transition_coverage_surefire_sha256",
    "transition_activation_policy_v1_sha256",
    "transition_active_scope_semantic_matrix_v1_sha256",
    "transition_compact_review_index_v1_sha256",
    "transition_nominal_review_policy_v2_sha256",
    "transition_nominal_review_v2_sha256",
}
ACTIVATION_BLOCKED_SCOPE_STATUSES = {
    "future_deferred",
    "released_missing_from_postgresql",
}
EXPECTED_ACTIVATION_POLICY = {
    "catalog_absence_is_semantic_proof": False,
    "future_release_is_semantic_proof": False,
    "activation_requires_new_versioned_review": True,
    "user_facing_reason_must_be_engine_neutral": True,
}
EXPECTED_ACTIVATION_ENFORCERS = {
    "services/xmage-sidecar/src/main/resources/"
    "xmage-transition-activation-policy.json",
    "services/xmage-sidecar/src/main/java/com/manaloom/xmage/"
    "XmageCardQualificationPolicy.java",
    "services/xmage-sidecar/src/test/java/com/manaloom/xmage/"
    "XmageBattleServiceTest.java",
}
EXPECTED_NON_BLOCKING_QUARANTINES = {
    "external_runtime_quarantine_semantic_defect": {
        "Planetarium of Wan Shi Tong"
    },
    "external_runtime_quarantine_known_upstream_gap": {
        "Mandate of Peace"
    },
}
EXPECTED_FALCON_RUNTIME_BOUNDARY = {
    "classification": "generated_card_information_only",
    "behavioral_equivalence_obligation_id": (
        "falcons_wing_harness_behavioral_equivalence"
    ),
    "replay_card_projection_path": (
        "services/xmage-sidecar/src/main/java/com/manaloom/xmage/"
        "ReplayNormalizer.java"
    ),
    "replay_card_projection_method": "card(CardView)",
    "replay_projection_includes_rules_text": False,
    "replay_sanitizer_path": (
        "server/lib/battle/battle_replay_payload_sanitizer.dart"
    ),
    "battle_card_input_path": (
        "server/lib/battle/battle_preflight_service.dart"
    ),
    "battle_card_input_source": "postgresql_backend",
    "battle_card_input_includes_oracle_text": False,
    "product_oracle_text_contract_path": (
        "docs/hermes-analysis/DATA_FIELD_ALIAS_CONTRACT_2026-06-30.md"
    ),
    "upstream_fix_claimed": False,
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


def canonical_json_sha256(value: Any) -> str:
    encoded = json.dumps(
        value,
        ensure_ascii=True,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


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
        or canonical_json_sha256(rows) != postgres.get("rows_sha256")
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


def _activation_policy_shape_valid(
    policy: dict[str, Any],
    *,
    evidence_cards: list[dict[str, Any]],
    postgres: dict[str, Any],
    postgres_artifact_sha256: str,
    transition_id: str,
    from_pin: str,
    to_pin: str,
) -> bool:
    raw_policy_cards = policy.get("cards")
    transition_names = policy.get("transition_card_names")
    postgres_rows = postgres.get("card_results")
    if (
        not isinstance(raw_policy_cards, list)
        or not isinstance(transition_names, list)
        or not isinstance(postgres_rows, list)
        or not all(
            isinstance(name, str) and bool(name) for name in transition_names
        )
    ):
        return False
    policy_cards = [
        row for row in raw_policy_cards if isinstance(row, dict)
    ]
    postgres_objects = [
        row for row in postgres_rows if isinstance(row, dict)
    ]
    evidence_by_name = {
        str(row.get("card_name") or ""): row for row in evidence_cards
    }
    postgres_by_name = {
        str(row.get("card_name") or ""): row for row in postgres_objects
    }
    policy_by_name = {
        str(row.get("card_name") or ""): row for row in policy_cards
    }
    scope_counts = (
        postgres.get("scope_counts")
        if isinstance(postgres.get("scope_counts"), dict)
        else {}
    )
    expected_names = set(evidence_by_name)
    blocked_names = {
        name
        for name, row in postgres_by_name.items()
        if row.get("product_scope_status")
        in ACTIVATION_BLOCKED_SCOPE_STATUSES
    }
    activation_lane_names = {
        name
        for name, row in evidence_by_name.items()
        if row.get("disposition") == ACTIVATION_BLOCKED_DISPOSITION
    }
    postgres_reference = (
        policy.get("postgresql_reconciliation")
        if isinstance(policy.get("postgresql_reconciliation"), dict)
        else {}
    )
    if (
        len(evidence_by_name) != len(evidence_cards)
        or len(postgres_by_name) != len(postgres_objects)
        or len(policy_by_name) != len(policy_cards)
        or set(postgres_by_name) != expected_names
        or activation_lane_names != blocked_names
        or set(transition_names) != expected_names
        or len(transition_names) != len(set(transition_names))
        or set(policy_by_name) != blocked_names
        or policy.get("schema_version")
        != ACTIVATION_POLICY_SCHEMA_VERSION
        or policy.get("transition_id") != transition_id
        or policy.get("from_engine_commit") != from_pin
        or policy.get("engine_commit") != to_pin
        or policy.get("transition_card_count") != len(expected_names)
        or policy.get("blocked_card_count") != len(blocked_names)
        or policy.get("future_deferred_count")
        != scope_counts.get("future_deferred")
        or policy.get("released_missing_count")
        != scope_counts.get("released_missing_from_postgresql")
        or policy.get("policy") != EXPECTED_ACTIVATION_POLICY
        or postgres_reference.get("schema_version")
        != POSTGRES_SCHEMA_VERSION
        or postgres_reference.get("artifact_sha256")
        != postgres_artifact_sha256
        or postgres_reference.get("rows_sha256")
        != postgres.get("rows_sha256")
        or postgres_reference.get("transaction_read_only") is not True
        or postgres_reference.get("writes_performed") is not False
    ):
        return False

    for name, policy_row in policy_by_name.items():
        evidence_row = evidence_by_name[name]
        postgres_row = postgres_by_name[name]
        registrations = evidence_row.get("set_registrations")
        if not isinstance(registrations, list):
            return False
        release_dates = sorted(
            {
                str(row.get("release_date"))
                for row in registrations
                if isinstance(row, dict) and row.get("release_date")
            }
        )
        if (
            policy_row.get("class") != evidence_row.get("class")
            or evidence_row.get("runtime_catalog_status") != "unsupported"
            or policy_row.get("source_path")
            != evidence_row.get("source_path")
            or policy_row.get("product_scope_status")
            != postgres_row.get("product_scope_status")
            or policy_row.get("release_scope_as_of_2026_07_28")
            != evidence_row.get("release_scope_as_of_2026_07_28")
            or policy_row.get("declared_release_dates") != release_dates
            or policy_row.get("reason_code")
            != "battle_card_activation_review_required"
            or policy_row.get("release_condition")
            != (
                "repeat_product_identity_oracle_legality_and_semantic_review"
            )
        ):
            return False
    return True


def _presentation_maven_repositories_are_isolated(
    from_result: dict[str, Any],
    to_result: dict[str, Any],
) -> bool:
    from_repository = str(from_result.get("maven_repository") or "")
    to_repository = str(to_result.get("maven_repository") or "")
    return (
        bool(from_repository)
        and bool(to_repository)
        and from_repository != to_repository
        and Path(from_repository).name == "m2-from"
        and Path(to_repository).name == "m2-to"
    )


def _presentation_equivalence_artifact(
    focused_artifact: dict[str, Any],
    *,
    repo_root: Path,
    focused_artifact_path: str,
    from_pin: str,
    to_pin: str,
) -> tuple[dict[str, Any], bool]:
    artifact = (
        focused_artifact.get("presentation_equivalence")
        if isinstance(
            focused_artifact.get("presentation_equivalence"), dict
        )
        else {}
    )
    artifact_path_value = str(artifact.get("artifact_path") or "")
    artifact_path = _safe_repo_path(repo_root, artifact_path_value)
    patch_path_value = str(artifact.get("patch_path") or "")
    patch_path = _safe_repo_path(repo_root, patch_path_value)
    if (
        artifact_path is None
        or patch_path is None
        or artifact_path_value != focused_artifact_path
    ):
        return {}, False
    try:
        patch_sha256 = file_sha256(patch_path)
    except (OSError, ValueError, json.JSONDecodeError):
        return {}, False

    from_result = (
        artifact.get("from_pin_result")
        if isinstance(artifact.get("from_pin_result"), dict)
        else {}
    )
    to_result = (
        artifact.get("to_pin_result")
        if isinstance(artifact.get("to_pin_result"), dict)
        else {}
    )
    obligations = (
        artifact.get("obligations")
        if isinstance(artifact.get("obligations"), list)
        else []
    )
    validation = (
        artifact.get("validation")
        if isinstance(artifact.get("validation"), dict)
        else {}
    )

    def result_valid(
        result: dict[str, Any],
        pin: str,
        expected_maven_repository_name: str,
    ) -> bool:
        maven_repository = str(result.get("maven_repository") or "")
        return (
            result.get("pin") == pin
            and result.get("tests") == 12
            and result.get("failures") == 0
            and result.get("errors") == 0
            and result.get("skipped") == 0
            and isinstance(result.get("time_seconds"), (int, float))
            and not isinstance(result.get("time_seconds"), bool)
            and result.get("time_seconds") >= 0
            and result.get("status") == "pass"
            and str(result.get("java_version") or "").startswith("17.")
            and bool(result.get("surefire_report"))
            and SHA256_PATTERN.fullmatch(
                str(result.get("surefire_sha256") or "")
            )
            is not None
            and SHA256_PATTERN.fullmatch(
                str(result.get("mage_jar_sha256") or "")
            )
            is not None
            and SHA256_PATTERN.fullmatch(
                str(result.get("mage_sets_jar_sha256") or "")
            )
            is not None
            and bool(maven_repository)
            and Path(maven_repository).name
            == expected_maven_repository_name
        )

    obligation_rows = [
        row for row in obligations if isinstance(row, dict)
    ]
    obligation_ids = {
        str(row.get("obligation_id") or "") for row in obligation_rows
    }
    test_methods = {
        method
        for row in obligation_rows
        for method in (
            row.get("test_methods")
            if isinstance(row.get("test_methods"), list)
            else []
        )
        if isinstance(method, str) and method
    }
    valid = (
        artifact.get("test_class")
        == (
            "org.mage.test.cards.single."
            "XmageProductInScopePresentationEquivalenceTest"
        )
        and str(artifact.get("test_source") or "").startswith(
            "Mage.Tests/"
        )
        and SHA256_PATTERN.fullmatch(
            str(artifact.get("test_source_sha256") or "")
        )
        is not None
        and SHA_PATTERN.fullmatch(
            str(artifact.get("test_source_blob_sha1") or "")
        )
        is not None
        and patch_path_value
        == (
            "docs/qa/evidence/"
            "XMAGE_PRODUCT_SCOPE_PRESENTATION_EQUIVALENCE_TESTS_"
            "34d81ea_2c43ec8.patch"
        )
        and SHA256_PATTERN.fullmatch(
            str(artifact.get("patch_sha256") or "")
        )
        is not None
        and artifact.get("patch_sha256") == patch_sha256
        and artifact.get("obligations_path")
        == "presentation_equivalence.obligations"
        and result_valid(from_result, from_pin, "m2-from")
        and result_valid(to_result, to_pin, "m2-to")
        and _presentation_maven_repositories_are_isolated(
            from_result,
            to_result,
        )
        and len(obligation_rows) == len(obligations) == 11
        and len(obligation_ids) == 11
        and "" not in obligation_ids
        and len(test_methods) == 12
        and all(
            row.get("card_name")
            and row.get("source_path")
            and isinstance(row.get("test_methods"), list)
            and bool(row.get("test_methods"))
            and isinstance(row.get("affected_behavior"), list)
            and bool(row.get("affected_behavior"))
            and row.get("coverage_status")
            == "behavioral_equivalence_pass"
            and row.get("test_is_promotion_evidence") is True
            and row.get("residual_gap") is None
            for row in obligation_rows
        )
        and validation.get("same_test_source_sha256_on_both_pins")
        is True
        and validation.get("separate_maven_repositories_per_pin") is True
        and validation.get("same_java_major_version") == 17
        and validation.get("java_runtime_isolated") is True
        and validation.get("from_pin_status") == "pass"
        and validation.get("to_pin_status") == "pass"
        and validation.get("obligation_count") == 11
        and validation.get("test_method_count") == 12
        and validation.get("ward_cost_assertions")
        == [
            "Captain America, Wings of Freedom: ward {1}",
            "Falcon's Wing Harness: ward {1}",
            "Mikey & Don, Party Planners: ward {2}",
        ]
        and artifact.get("obligation_count") == 11
        and artifact.get("test_method_count") == 12
    )
    return artifact, valid


def _product_scope_focused_test_shape_valid(
    artifact: dict[str, Any],
    *,
    focused_artifact_path: str,
    evidence_cards: list[dict[str, Any]],
    postgres: dict[str, Any],
    postgres_artifact_path: str,
    postgres_artifact_sha256: str,
    repo_root: Path,
    from_pin: str,
    to_pin: str,
    expected_test_count: int | None,
    expected_direct_card_count: int | None,
    expected_patch_count: int | None,
    expected_execution_report_count: int | None,
) -> bool:
    transition = (
        artifact.get("transition")
        if isinstance(artifact.get("transition"), dict)
        else {}
    )
    product_scope = (
        artifact.get("product_scope")
        if isinstance(artifact.get("product_scope"), dict)
        else {}
    )
    combined = (
        artifact.get("combined_execution")
        if isinstance(artifact.get("combined_execution"), dict)
        else {}
    )
    conclusions = (
        artifact.get("conclusions")
        if isinstance(artifact.get("conclusions"), dict)
        else {}
    )
    safety = (
        artifact.get("safety")
        if isinstance(artifact.get("safety"), dict)
        else {}
    )
    focused_runs = artifact.get("focused_runs")
    direct_names = product_scope.get("direct_focused_test_cards")
    surefire_reports = combined.get("reports")
    postgres_rows = postgres.get("card_results")
    presentation_artifact, presentation_artifact_valid = (
        _presentation_equivalence_artifact(
            artifact,
            repo_root=repo_root,
            focused_artifact_path=focused_artifact_path,
            from_pin=from_pin,
            to_pin=to_pin,
        )
    )
    presentation_obligations = (
        [
            row
            for row in presentation_artifact.get("obligations", [])
            if isinstance(row, dict)
        ]
        if presentation_artifact_valid
        else []
    )
    presentation_card_names = {
        str(row.get("card_name") or "")
        for row in presentation_obligations
    }
    if (
        not isinstance(focused_runs, list)
        or not isinstance(direct_names, list)
        or not isinstance(surefire_reports, list)
        or not isinstance(postgres_rows, list)
        or not all(
            isinstance(name, str) and bool(name) for name in direct_names
        )
    ):
        return False
    runs = [row for row in focused_runs if isinstance(row, dict)]
    reports = [row for row in surefire_reports if isinstance(row, dict)]
    evidence_by_name = {
        str(row.get("card_name") or ""): row for row in evidence_cards
    }
    postgres_by_name = {
        str(row.get("card_name") or ""): row
        for row in postgres_rows
        if isinstance(row, dict)
    }
    direct_name_set = set(direct_names)
    quarantine_names_raw = product_scope.get(
        "external_runtime_gap_quarantine_cards"
    )
    exact_non_executable_names_raw = product_scope.get(
        "exact_non_executable_cards"
    )
    quarantine_name_set = (
        set(quarantine_names_raw)
        if isinstance(quarantine_names_raw, list)
        and all(isinstance(name, str) for name in quarantine_names_raw)
        else set()
    )
    exact_non_executable_name_set = (
        set(exact_non_executable_names_raw)
        if isinstance(exact_non_executable_names_raw, list)
        and all(
            isinstance(name, str)
            for name in exact_non_executable_names_raw
        )
        else set()
    )
    direct_product_name_set = direct_name_set - quarantine_name_set
    evidence_product_clearance_name_set = {
        name
        for name, row in evidence_by_name.items()
        if row.get("disposition")
        == PRODUCT_FOCUSED_CLEARANCE_DISPOSITION
    }
    postgres_product_name_set = {
        name
        for name, row in postgres_by_name.items()
        if row.get("product_scope_status") == "product_in_scope"
    }
    if (
        artifact.get("schema_version")
        != PRODUCT_SCOPE_FOCUSED_TEST_SCHEMA_VERSION
        or transition.get("from_pin") != from_pin
        or transition.get("to_pin") != to_pin
        or transition.get("repository") != "https://github.com/magefree/mage"
        or transition.get("exact_pin_checkout_required") is not True
        or product_scope.get("source_of_truth")
        != "postgresql_backend"
        or product_scope.get("reconciliation_path")
        != postgres_artifact_path
        or product_scope.get("reconciliation_sha256")
        != postgres_artifact_sha256
        or product_scope.get("product_in_scope_card_count")
        != postgres.get("scope_counts", {}).get("product_in_scope")
        or product_scope.get("direct_focused_test_card_count")
        != expected_direct_card_count
        or len(direct_names) != expected_direct_card_count
        or len(direct_names) != len(direct_name_set)
        or not direct_name_set <= set(evidence_by_name)
        or product_scope.get(
            "product_in_scope_direct_focused_test_card_count"
        )
        != 29
        or product_scope.get(
            "external_runtime_gap_quarantine_card_count"
        )
        != 2
        or quarantine_name_set
        != {"Mandate of Peace", "Planetarium of Wan Shi Tong"}
        or len(quarantine_names_raw or []) != len(quarantine_name_set)
        or product_scope.get("exact_non_executable_card_count") != 5
        or len(exact_non_executable_names_raw or [])
        != len(exact_non_executable_name_set)
        or len(exact_non_executable_name_set) != 5
        or evidence_product_clearance_name_set != direct_product_name_set
        or direct_product_name_set & exact_non_executable_name_set
        or direct_product_name_set | exact_non_executable_name_set
        != postgres_product_name_set
        or product_scope.get("catalog_resolution_used_as_semantic_proof")
        is not False
        or len(runs) != len(focused_runs)
        or len(runs) != expected_patch_count
        or len(reports) != len(surefire_reports)
        or len(reports) != expected_execution_report_count
        or combined.get("tests") != expected_test_count
        or combined.get("failures") != 0
        or combined.get("errors") != 0
        or combined.get("skipped") != 0
        or combined.get("status") != "pass"
        or combined.get("execution_report_count")
        != expected_execution_report_count
        or sum(_integer(row.get("tests")) or 0 for row in reports)
        != expected_test_count
        or any(
            (_integer(row.get("tests")) or 0) <= 0
            or row.get("failures") != 0
            or row.get("errors") != 0
            or row.get("skipped") != 0
            or SHA256_PATTERN.fullmatch(
                str(row.get("surefire_sha256") or "")
            )
            is None
            for row in reports
        )
        or conclusions.get(
            "planetarium_quarantine_confirmed_by_executable_assertion"
        )
        is not True
        or conclusions.get("planetarium_test_is_promotion_evidence")
        is not False
        or conclusions.get(
            "mandate_of_peace_quarantine_confirmed_by_executable_assertion"
        )
        is not True
        or conclusions.get("mandate_of_peace_test_is_promotion_evidence")
        is not False
        or conclusions.get(
            "presentation_equivalence_passed_on_both_pins"
        )
        is not True
        or conclusions.get("isolated_java17_matrix_passed") is not True
        or conclusions.get("all_68_tests_passed") is not True
        or conclusions.get("no_card_source_modified") is not True
        or not presentation_artifact_valid
        or safety.get("postgresql_writes") is not False
        or safety.get("hermes_sqlite_writes") is not False
        or safety.get("production_runtime_mutations") is not False
        or safety.get("upstream_card_source_mutations") is not False
    ):
        return False

    allowed_direct_statuses = {"product_in_scope"}
    run_card_names: set[str] = set()
    isolated_test_total = 0
    observed_obligations: list[dict[str, Any]] = []
    for run in runs:
        run_cards = run.get("cards")
        obligations = run.get("obligations")
        isolated = (
            run.get("isolated_execution")
            if isinstance(run.get("isolated_execution"), dict)
            else {}
        )
        is_presentation_run = (
            str(run.get("test_source") or "")
            == presentation_artifact.get("test_source")
        )
        patch_path_value = str(run.get("patch_path") or "")
        patch_path = _safe_repo_path(repo_root, patch_path_value)
        if (
            not isinstance(run_cards, list)
            or not isinstance(obligations, list)
            or not all(
                isinstance(name, str) and bool(name) for name in run_cards
            )
            or not str(run.get("test_source") or "").startswith(
                "Mage.Tests/"
            )
            or SHA256_PATTERN.fullmatch(
                str(run.get("test_source_sha256") or "")
            )
            is None
            or SHA_PATTERN.fullmatch(
                str(run.get("test_source_blob_sha1") or "")
            )
            is None
            or patch_path is None
            or SHA256_PATTERN.fullmatch(
                str(run.get("patch_sha256") or "")
            )
            is None
        ):
            return False
        try:
            patch_sha256 = file_sha256(patch_path)
            patch_text = patch_path.read_text(encoding="utf-8")
        except OSError:
            return False
        patch_headers = re.findall(
            r"^diff --git a/(\S+) b/(\S+)$",
            patch_text,
            flags=re.MULTILINE,
        )
        if (
            patch_sha256 != run.get("patch_sha256")
            or not patch_headers
            or any(
                not old_path.startswith("Mage.Tests/")
                or not new_path.startswith("Mage.Tests/")
                for old_path, new_path in patch_headers
            )
        ):
            return False
        if is_presentation_run:
            if (
                run.get("test_source_sha256")
                != presentation_artifact.get("test_source_sha256")
                or set(run_cards) != presentation_card_names
            ):
                return False
        else:
            isolated_tests = _integer(isolated.get("tests"))
            isolated_result = isolated.get(
                "result", isolated.get("status")
            )
            if (
                isolated_tests is None
                or isolated_tests <= 0
                or isolated.get("failures") != 0
                or isolated.get("errors") != 0
                or isolated.get("skipped") != 0
                or isolated_result != "pass"
                or SHA256_PATTERN.fullmatch(
                    str(isolated.get("surefire_sha256") or "")
                )
                is None
            ):
                return False
            isolated_test_total += isolated_tests
        run_card_names.update(run_cards)
        observed_obligations.extend(
            row for row in obligations if isinstance(row, dict)
        )
    observed_obligations.extend(presentation_obligations)
    presentation_from_tests = _integer(
        presentation_artifact.get("from_pin_result", {}).get("tests")
    )
    presentation_to_tests = _integer(
        presentation_artifact.get("to_pin_result", {}).get("tests")
    )
    if (
        presentation_from_tests is None
        or presentation_to_tests is None
        or isolated_test_total
        + presentation_from_tests
        + presentation_to_tests
        != expected_test_count
        or run_card_names != direct_name_set
    ):
        return False

    obligations_by_card: dict[str, list[dict[str, Any]]] = {}
    for obligation in observed_obligations:
        obligation_card = str(
            obligation.get("card_name", obligation.get("card")) or ""
        )
        if obligation_card:
            obligations_by_card.setdefault(obligation_card, []).append(
                obligation
            )
    for card_name in direct_product_name_set:
        card_obligations = obligations_by_card.get(card_name, [])
        if (
            evidence_by_name.get(card_name, {}).get("disposition")
            != PRODUCT_FOCUSED_CLEARANCE_DISPOSITION
            or not card_obligations
            or not any(
                obligation.get("result") == "PASS"
                or obligation.get("coverage_status")
                in {"focused_pass", "behavioral_equivalence_pass"}
                for obligation in card_obligations
            )
            or any(
                obligation.get("coverage_status")
                == "quarantine_confirmed"
                or obligation.get("test_is_promotion_evidence") is False
                for obligation in card_obligations
            )
        ):
            return False
    if any(
        evidence_by_name.get(card_name, {}).get("disposition")
        != CLEARANCE_DISPOSITION
        for card_name in exact_non_executable_name_set
    ):
        return False

    quarantine_dispositions = {
        "Planetarium of Wan Shi Tong": (
            "external_runtime_quarantine_semantic_defect"
        ),
        "Mandate of Peace": (
            "external_runtime_quarantine_known_upstream_gap"
        ),
    }
    for card_name in direct_name_set:
        postgres_status = postgres_by_name.get(card_name, {}).get(
            "product_scope_status"
        )
        if card_name in quarantine_dispositions:
            if (
                postgres_status != "external_runtime_gap"
                or evidence_by_name.get(card_name, {}).get("disposition")
                != quarantine_dispositions[card_name]
            ):
                return False
        elif postgres_status not in allowed_direct_statuses:
            return False

    partial_or_quarantine_names = {
        str(row.get("card_name", row.get("card")) or "")
        for row in observed_obligations
        if row.get("coverage_status")
        in {"partial_focused_pass", "quarantine_confirmed"}
    }
    if any(
        evidence_by_name.get(name, {}).get("disposition")
        in {
            CLEARANCE_DISPOSITION,
            PRODUCT_FOCUSED_CLEARANCE_DISPOSITION,
        }
        for name in partial_or_quarantine_names
    ):
        return False
    planetarium_obligation = next(
        (
            row
            for row in observed_obligations
            if row.get("card_name") == "Planetarium of Wan Shi Tong"
        ),
        {},
    )
    mandate_obligation = next(
        (
            row
            for row in observed_obligations
            if row.get("card_name") == "Mandate of Peace"
        ),
        {},
    )
    falcon_obligation = next(
        (
            row
            for row in observed_obligations
            if row.get("card_name") == "Falcon's Wing Harness"
        ),
        {},
    )
    return (
        planetarium_obligation.get("coverage_status")
        == "quarantine_confirmed"
        and bool(planetarium_obligation.get("residual_gap"))
        and planetarium_obligation.get("test_is_promotion_evidence")
        is False
        and mandate_obligation.get("obligation_id")
        == "mandate_of_peace_concurrent_stack_removal"
        and mandate_obligation.get("coverage_status")
        == "quarantine_confirmed"
        and mandate_obligation.get("residual_issue") == "#12911"
        and mandate_obligation.get("test_is_promotion_evidence") is False
        and mandate_obligation.get("observed_behavior")
        == (
            "copy_and_two_activated_abilities_removed_but_original_"
            "spell_resolves"
        )
        and mandate_obligation.get("test_methods")
        == [
            (
                "mandateOfPeaceQuarantineReproducesResidualOriginalSpell"
                "AfterConcurrentRemoval"
            )
        ]
        and falcon_obligation.get("obligation_id")
        == "falcons_wing_harness_behavioral_equivalence"
        and falcon_obligation.get("source_path")
        == "Mage.Sets/src/mage/cards/f/FalconsWingHarness.java"
        and falcon_obligation.get("test_methods")
        == ["falconsWingHarnessAttachesThenReequipsWithBoostAndFlying"]
        and falcon_obligation.get("affected_behavior")
        == [
            "etb_attach",
            "equip_cost_2U",
            "attachment_transfer",
            "boost_1_1",
            "flying",
            "ward_1",
        ]
        and falcon_obligation.get("coverage_status")
        == "behavioral_equivalence_pass"
        and falcon_obligation.get("test_is_promotion_evidence") is True
        and falcon_obligation.get("residual_gap") is None
    )


def _review_registry_entry(
    artifact: dict[str, Any],
    entry_id: str,
) -> dict[str, Any]:
    raw_registry = artifact.get("evidence_registry")
    if not isinstance(raw_registry, list):
        return {}
    registry = [row for row in raw_registry if isinstance(row, dict)]
    ids = [str(row.get("id") or "") for row in registry]
    if not all(ids) or len(ids) != len(set(ids)):
        return {}
    matches = [row for row in registry if row.get("id") == entry_id]
    return matches[0] if len(matches) == 1 else {}


def _review_status_for_disposition(disposition: str) -> str:
    if disposition in {
        CLEARANCE_DISPOSITION,
        PRODUCT_FOCUSED_CLEARANCE_DISPOSITION,
    }:
        return "cleared"
    if disposition == ACTIVATION_BLOCKED_DISPOSITION:
        return "blocked_activation"
    if disposition in EXPECTED_NON_BLOCKING_QUARANTINES:
        return "quarantined"
    return ""


def _transition_review_artifacts_shape_valid(
    matrix: dict[str, Any],
    index: dict[str, Any],
    *,
    evidence_cards: list[dict[str, Any]],
    postgres: dict[str, Any],
    qualification: dict[str, Any],
    primary_evidence_path: str,
    source_primary_snapshot_sha256: str,
    focused_artifact_path: str,
    focused_artifact_sha256: str,
    from_pin: str,
    to_pin: str,
) -> bool:
    postgres_rows = postgres.get("card_results")
    matrix_cards = matrix.get("cards")
    index_cards = index.get("cards")
    if (
        not isinstance(postgres_rows, list)
        or not isinstance(matrix_cards, list)
        or not isinstance(index_cards, list)
        or not all(isinstance(row, dict) for row in evidence_cards)
        or not all(isinstance(row, dict) for row in postgres_rows)
        or not all(isinstance(row, dict) for row in matrix_cards)
        or not all(isinstance(row, dict) for row in index_cards)
    ):
        return False

    primary_by_name = {
        str(row.get("card_name") or ""): row for row in evidence_cards
    }
    postgres_by_name = {
        str(row.get("card_name") or ""): row for row in postgres_rows
    }
    if (
        "" in primary_by_name
        or "" in postgres_by_name
        or len(primary_by_name) != len(evidence_cards)
        or len(postgres_by_name) != len(postgres_rows)
        or set(primary_by_name) != set(postgres_by_name)
    ):
        return False

    expected_rows: dict[str, tuple[str, str, str, str, str]] = {}
    for card_name, primary_row in primary_by_name.items():
        postgres_row = postgres_by_name[card_name]
        expected_status = _review_status_for_disposition(
            str(primary_row.get("disposition") or "")
        )
        lane = str(postgres_row.get("product_scope_status") or "")
        if not expected_status or lane not in POSTGRES_SCOPE_STATUSES:
            return False
        expected_rows[card_name] = (
            card_name,
            str(primary_row.get("class") or ""),
            str(primary_row.get("source_path") or ""),
            lane,
            expected_status,
        )
    if any(not value for row in expected_rows.values() for value in row):
        return False

    def observed_rows(
        rows: list[dict[str, Any]],
    ) -> tuple[set[tuple[str, str, str, str, str]], bool]:
        identities: set[tuple[str, str, str, str, str]] = set()
        valid = True
        for row in rows:
            card_name = str(row.get("card_name") or "")
            scope = row.get("scope")
            primary_row = primary_by_name.get(card_name, {})
            postgres_row = postgres_by_name.get(card_name, {})
            if not isinstance(scope, dict):
                return set(), False
            identity = (
                card_name,
                str(row.get("class_name") or ""),
                str(row.get("source_path") or ""),
                str(scope.get("lane") or ""),
                str(row.get("status") or ""),
            )
            disposition = str(primary_row.get("disposition") or "")
            clearance_basis = row.get("clearance_basis")
            expected_clearance_basis = {
                CLEARANCE_DISPOSITION: {
                    "exact_non_executable_tokens_v2",
                },
                PRODUCT_FOCUSED_CLEARANCE_DISPOSITION: {
                    "focused_runtime_added",
                    "focused_runtime_executable_transition",
                    "presentation_equivalence_both_pins",
                },
            }.get(disposition, {None})
            valid = (
                valid
                and card_name in expected_rows
                and identity == expected_rows.get(card_name)
                and scope.get("release_scope")
                == postgres_row.get("release_scope_as_of_2026_07_28")
                and scope.get("reconciliation_runtime_catalog_status")
                == postgres_row.get("runtime_catalog_status")
                and scope.get("effective_runtime_catalog_status")
                == primary_row.get("runtime_catalog_status")
                and clearance_basis in expected_clearance_basis
            )
            identities.add(identity)
        return identities, valid and len(identities) == len(rows)

    matrix_identity_set, matrix_rows_valid = observed_rows(matrix_cards)
    index_identity_set, index_rows_valid = observed_rows(index_cards)
    expected_index_set = set(expected_rows.values())
    expected_matrix_set = {
        row
        for row in expected_index_set
        if row[3] in {"product_in_scope", "external_runtime_gap"}
    }

    expected_dispositions = dict(
        sorted(
            Counter(
                str(row.get("disposition") or "")
                for row in evidence_cards
            ).items()
        )
    )
    expected_qualification = {
        "evidence_ref": "transition_audit_169",
        "status": qualification.get("status"),
        "deployment_allowed": qualification.get("deployment_allowed"),
        "blocking_reasons": qualification.get("blocking_reasons"),
        "disposition_counts": expected_dispositions,
    }
    expected_scope_counts = dict(
        sorted(
            Counter(
                str(row.get("product_scope_status") or "")
                for row in postgres_rows
            ).items()
        )
    )
    expected_matrix_status_summary = {
        "cleared": 34,
        "quarantined": 2,
        "blocked_activation": 0,
        "partial": 0,
        "gap": 0,
    }
    expected_index_status_summary = {
        "cleared": 34,
        "blocked_activation": 133,
        "quarantined": 2,
        "partial": 0,
        "gap": 0,
    }

    def transition_valid(artifact: dict[str, Any]) -> bool:
        value = artifact.get("transition")
        return (
            isinstance(value, dict)
            and value.get("repository") == "https://github.com/magefree/mage"
            and value.get("from_commit") == from_pin
            and value.get("to_commit") == to_pin
            and value.get("identity") == "34d81ea_2c43ec8"
        )

    def registry_valid(artifact: dict[str, Any]) -> bool:
        primary_entry = _review_registry_entry(
            artifact, "transition_audit_169"
        )
        focused_entry = _review_registry_entry(
            artifact, "focused_product_scope_tests"
        )
        return (
            primary_entry.get("path") == primary_evidence_path
            and primary_entry.get("sha256")
            == source_primary_snapshot_sha256
            and focused_entry.get("path") == focused_artifact_path
            and focused_entry.get("sha256") == focused_artifact_sha256
        )

    matrix_validation = matrix.get("validation")
    index_validation = index.get("validation")
    matrix_valid = (
        matrix.get("schema_version") == ACTIVE_SCOPE_MATRIX_SCHEMA_VERSION
        and matrix.get("status") == "pass"
        and transition_valid(matrix)
        and matrix.get("scope")
        == {
            "matrix_card_count": 36,
            "product_in_scope_card_count": 34,
            "external_runtime_gap_quarantine_card_count": 2,
            "direct_focused_product_card_count": 29,
            "exact_non_executable_product_card_count": 5,
        }
        and matrix.get("status_summary") == expected_matrix_status_summary
        and matrix.get("transition_audit_qualification")
        == expected_qualification
        and matrix_rows_valid
        and matrix_identity_set == expected_matrix_set
        and registry_valid(matrix)
        and isinstance(matrix_validation, dict)
        and matrix_validation.get("status_vocabulary")
        == ["cleared", "quarantined"]
        and matrix_validation.get("forbidden_status_count") == 0
        and all(
            matrix_validation.get(key) is True
            for key in {
                "matrix_card_count_matches",
                "product_partition_is_exact",
                "direct_focused_plus_exact_non_executable_equals_34",
                "evidence_sha256_verified",
                "primary_dispositions_match",
            }
        )
    )
    index_coverage = index.get("coverage")
    index_valid = (
        index.get("schema_version") == COMPACT_REVIEW_INDEX_SCHEMA_VERSION
        and index.get("status") == "pass"
        and transition_valid(index)
        and index.get("scope_counts") == expected_scope_counts
        and index.get("status_summary") == expected_index_status_summary
        and index.get("transition_audit_qualification")
        == expected_qualification
        and isinstance(index_coverage, dict)
        and index_coverage.get("transition_card_count") == len(evidence_cards)
        and index_coverage.get("postgresql_reconciled_card_count")
        == len(postgres_rows)
        and index_coverage.get("review_union_card_count")
        == len(evidence_cards)
        and index_coverage.get("identity_cross_check_failure_count") == 0
        and index_rows_valid
        and index_identity_set == expected_index_set
        and registry_valid(index)
        and isinstance(index_validation, dict)
        and index_validation.get("status_vocabulary")
        == ["cleared", "blocked_activation", "quarantined"]
        and index_validation.get("forbidden_status_count") == 0
        and all(
            index_validation.get(key) is True
            for key in {
                "card_count_matches",
                "postgresql_identity_set_matches",
                "semantic_review_union_matches",
                "status_counts_match",
                "blocked_policy_identity_set_matches",
                "no_review_only_card_promoted",
                "evidence_sha256_verified",
                "primary_dispositions_match",
            }
        )
    )
    return matrix_valid and index_valid


def _falcon_runtime_boundary_valid(
    finding: dict[str, Any],
    *,
    focused_artifact: dict[str, Any],
    focused_artifact_path: str,
    repo_root: Path,
) -> bool:
    boundary = (
        finding.get("runtime_boundary")
        if isinstance(finding.get("runtime_boundary"), dict)
        else {}
    )
    if boundary != EXPECTED_FALCON_RUNTIME_BOUNDARY:
        return False

    transition = (
        focused_artifact.get("transition")
        if isinstance(focused_artifact.get("transition"), dict)
        else {}
    )
    presentation_artifact, presentation_valid = (
        _presentation_equivalence_artifact(
            focused_artifact,
            repo_root=repo_root,
            focused_artifact_path=focused_artifact_path,
            from_pin=str(transition.get("from_pin") or ""),
            to_pin=str(transition.get("to_pin") or ""),
        )
    )
    if not presentation_valid:
        return False
    obligations = [
        obligation
        for obligation in (
            presentation_artifact.get("obligations")
            if isinstance(presentation_artifact.get("obligations"), list)
            else []
        )
        if isinstance(obligation, dict)
    ]
    falcon_obligations = [
        obligation
        for obligation in obligations
        if obligation.get("obligation_id")
        == "falcons_wing_harness_behavioral_equivalence"
    ]
    if len(falcon_obligations) != 1:
        return False
    obligation = falcon_obligations[0]
    if (
        obligation.get("card_name") != "Falcon's Wing Harness"
        or obligation.get("source_path")
        != "Mage.Sets/src/mage/cards/f/FalconsWingHarness.java"
        or obligation.get("test_methods")
        != ["falconsWingHarnessAttachesThenReequipsWithBoostAndFlying"]
        or obligation.get("affected_behavior")
        != [
            "etb_attach",
            "equip_cost_2U",
            "attachment_transfer",
            "boost_1_1",
            "flying",
            "ward_1",
        ]
        or obligation.get("coverage_status")
        != "behavioral_equivalence_pass"
        or obligation.get("test_is_promotion_evidence") is not True
        or obligation.get("residual_gap") is not None
    ):
        return False

    source_paths = {
        key: _safe_repo_path(repo_root, str(boundary.get(key) or ""))
        for key in {
            "replay_card_projection_path",
            "replay_sanitizer_path",
            "battle_card_input_path",
            "product_oracle_text_contract_path",
        }
    }
    if any(path is None for path in source_paths.values()):
        return False
    try:
        replay_source = source_paths[
            "replay_card_projection_path"
        ].read_text(encoding="utf-8")
        sanitizer_source = source_paths["replay_sanitizer_path"].read_text(
            encoding="utf-8"
        )
        battle_input_source = source_paths["battle_card_input_path"].read_text(
            encoding="utf-8"
        )
        oracle_contract = source_paths[
            "product_oracle_text_contract_path"
        ].read_text(encoding="utf-8")
    except OSError:
        return False

    replay_start = replay_source.find(
        "private static Map<String, Object> card(CardView card)"
    )
    replay_end = replay_source.find(
        "private static List<Map<String, Object>> counters(",
        replay_start,
    )
    battle_start = battle_input_source.find(
        "Future<BattlePreflightDeck?> _loadDeck("
    )
    battle_end = battle_input_source.find(
        "Future<int> _availableOpponentCount(",
        battle_start,
    )
    if min(replay_start, replay_end, battle_start, battle_end) < 0:
        return False
    replay_card_method = replay_source[replay_start:replay_end]
    battle_card_input_method = battle_input_source[battle_start:battle_end]
    expected_projection_fields = {
        'result.put("id"',
        'result.put("name"',
        'result.put("set_code"',
        'result.put("card_number"',
        'result.put("is_ability"',
        'result.put("object_type"',
        'result.put("source_card_id"',
        'result.put("source_card_name"',
        'result.put("tapped"',
        'result.put("damage"',
        'result.put("controller_name"',
        'result.put("counters"',
    }
    expected_battle_input_fields = {
        "c.name",
        "c.set_code",
        "c.collector_number",
        "'name': row[6]",
        "'set_code': row[7]",
        "'collector_number': row[8]",
        "'quantity': row[9]",
        "'is_commander': row[10]",
    }
    return (
        all(token in replay_card_method for token in expected_projection_fields)
        and "oracle" not in replay_card_method.lower()
        and "rules_text" not in replay_card_method.lower()
        and all(
            token in battle_card_input_method
            for token in expected_battle_input_fields
        )
        and "oracle_text" not in battle_card_input_method.lower()
        and "sanitizeBattleReplayForStorage" in sanitizer_source
        and "'oracle_text'" in sanitizer_source
        and "| Oracle text | `oracle_text` from PostgreSQL/"
        in oracle_contract
    )


def _card_data_diagnostics_shape_valid(
    diagnostics: dict[str, Any],
    *,
    evidence_cards: list[dict[str, Any]],
    postgres: dict[str, Any],
    focused_artifact: dict[str, Any],
    focused_artifact_path: str,
    focused_artifact_valid: bool,
    repo_root: Path,
) -> bool:
    raw_findings = diagnostics.get("actionable_findings")
    postgres_rows = postgres.get("card_results")
    if (
        not isinstance(raw_findings, list)
        or not isinstance(postgres_rows, list)
        or not focused_artifact_valid
    ):
        return False
    findings = [row for row in raw_findings if isinstance(row, dict)]
    evidence_by_name = {
        str(row.get("card_name") or ""): row for row in evidence_cards
    }
    postgres_by_name = {
        str(row.get("card_name") or ""): row
        for row in postgres_rows
        if isinstance(row, dict)
    }
    findings_by_name = {
        str(row.get("card_name") or ""): row for row in findings
    }
    if (
        diagnostics.get("status") != "pass"
        or diagnostics.get("cataloged_classes_checked") != 168
        or diagnostics.get("good_face_count") != 154
        or diagnostics.get("wrong_face_count") != 16
        or diagnostics.get("missing_reference_face_count") != 3
        or len(findings) != len(raw_findings)
        or len(findings_by_name) != len(findings)
        or set(findings_by_name) != EXPECTED_ACTIONABLE_CARD_FINDINGS
        or diagnostics.get("activation_blocked_finding_count") != 7
        or diagnostics.get("quarantined_finding_count") != 1
        or diagnostics.get("non_runtime_presentation_finding_count") != 1
        or diagnostics.get("deployment_blocking_finding_count") != 0
    ):
        return False

    falcon = findings_by_name["Falcon's Wing Harness"]
    planetarium = findings_by_name["Planetarium of Wan Shi Tong"]
    if (
        falcon.get("severity") != "visible_rules_text"
        or falcon.get("status") != "non_runtime_presentation_finding"
        or not falcon.get("evidence")
        or postgres_by_name.get("Falcon's Wing Harness", {}).get(
            "product_scope_status"
        )
        != "product_in_scope"
        or not _falcon_runtime_boundary_valid(
            falcon,
            focused_artifact=focused_artifact,
            focused_artifact_path=focused_artifact_path,
            repo_root=repo_root,
        )
        or planetarium.get("severity") != "mechanical"
        or planetarium.get("status") != "quarantined"
        or not planetarium.get("evidence")
        or postgres_by_name.get("Planetarium of Wan Shi Tong", {}).get(
            "product_scope_status"
        )
        != "external_runtime_gap"
        or evidence_by_name.get("Planetarium of Wan Shi Tong", {}).get(
            "disposition"
        )
        != "external_runtime_quarantine_semantic_defect"
    ):
        return False

    for card_name in (
        EXPECTED_ACTIONABLE_CARD_FINDINGS
        - {"Falcon's Wing Harness", "Planetarium of Wan Shi Tong"}
    ):
        finding = findings_by_name[card_name]
        if (
            finding.get("severity") != "visible_rules_text"
            or finding.get("status") != "activation_blocked"
            or not finding.get("evidence")
            or postgres_by_name.get(card_name, {}).get(
                "product_scope_status"
            )
            not in ACTIVATION_BLOCKED_SCOPE_STATUSES
            or evidence_by_name.get(card_name, {}).get("disposition")
            != ACTIVATION_BLOCKED_DISPOSITION
        ):
            return False
    return True


def _exact_clearances_from_policy(
    policy: dict[str, Any],
) -> tuple[dict[str, dict[str, Any]], bool]:
    raw_rules = policy.get("automatic_transition_clearance_rules")
    if not isinstance(raw_rules, list) or not raw_rules:
        return {}, False
    rules = [row for row in raw_rules if isinstance(row, dict)]
    expected: dict[str, dict[str, Any]] = {}
    rule_ids: set[str] = set()
    valid = len(rules) == len(raw_rules)
    for rule in rules:
        card_name = str(rule.get("card_name") or "")
        rule_id = str(rule.get("id") or "")
        direct_tests = rule.get("required_direct_test_references")
        test_count = _integer(rule.get("required_focused_test_case_count"))
        rule_valid = (
            bool(card_name)
            and bool(rule_id)
            and card_name not in expected
            and rule_id not in rule_ids
            and rule.get("change_kind") == "modified"
            and rule.get("required_change_scope")
            == "presentation_or_metadata"
            and rule.get("diff_hash_mode")
            == "git_diff_no_ext_diff_no_textconv_unified0_full_index"
            and SHA256_PATTERN.fullmatch(
                str(rule.get("canonical_diff_sha256") or "")
            )
            is not None
            and SHA_PATTERN.fullmatch(
                str(rule.get("from_blob_oid_sha1") or "")
            )
            is not None
            and SHA_PATTERN.fullmatch(
                str(rule.get("to_blob_oid_sha1") or "")
            )
            is not None
            and SHA256_PATTERN.fullmatch(
                str(rule.get("from_source_sha256") or "")
            )
            is not None
            and SHA256_PATTERN.fullmatch(
                str(rule.get("to_source_sha256") or "")
            )
            is not None
            and SHA256_PATTERN.fullmatch(
                str(rule.get("normalized_token_sha256") or "")
            )
            is not None
            and isinstance(direct_tests, list)
            and all(isinstance(reference, str) for reference in direct_tests)
            and test_count is not None
            and test_count >= 0
            and rule.get("require_no_source_warning_markers") is True
            and rule.get("require_no_card_data_actionable_finding") is True
            and isinstance(
                rule.get("allowed_presentation_literal_changes"),
                list,
            )
            and bool(rule.get("allowed_presentation_literal_changes"))
            and isinstance(rule.get("allowed_import_delta"), dict)
            and isinstance(rule.get("allow_import_reordering"), bool)
        )
        valid = valid and rule_valid
        if not rule_valid:
            continue
        rule_ids.add(rule_id)
        expected[card_name] = {
            "rule_id": rule_id,
            "class": str(rule.get("class") or ""),
            "source_path": str(rule.get("source_path") or ""),
            "source_scope": str(rule.get("required_change_scope") or ""),
            "canonical_diff_sha256": rule["canonical_diff_sha256"],
            "from_blob_oid_sha1": rule["from_blob_oid_sha1"],
            "to_blob_oid_sha1": rule["to_blob_oid_sha1"],
            "from_source_sha256": rule["from_source_sha256"],
            "to_source_sha256": rule["to_source_sha256"],
            "normalized_token_sha256": rule["normalized_token_sha256"],
            "direct_test_references": direct_tests,
            "required_test_case_count": test_count,
        }
    return expected, valid and len(expected) == len(rules)


def _validate_transition_nominal_review(
    evidence: dict[str, Any],
    expected: dict[str, Any],
    checks: list[dict[str, Any]],
    *,
    repo_root: Path,
    transition_id: str,
    from_pin: str,
    to_pin: str,
    input_digests: dict[str, Any],
    nominal_policy: dict[str, Any],
    nominal_policy_sha256: str,
) -> dict[str, dict[str, Any]]:
    pointer = (
        evidence.get("transition_nominal_review")
        if isinstance(evidence.get("transition_nominal_review"), dict)
        else {}
    )
    artifact_path_value = str(pointer.get("artifact_path") or "")
    artifact_path = _safe_repo_path(repo_root, artifact_path_value)
    artifact: dict[str, Any] = {}
    artifact_sha256 = ""
    load_error = ""
    if artifact_path is None:
        load_error = "artifact_path_invalid"
    else:
        try:
            artifact = load_json(artifact_path)
            artifact_sha256 = file_sha256(artifact_path)
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            load_error = type(exc).__name__

    transition = (
        artifact.get("transition")
        if isinstance(artifact.get("transition"), dict)
        else {}
    )
    summary = (
        artifact.get("summary")
        if isinstance(artifact.get("summary"), dict)
        else {}
    )
    safety = (
        artifact.get("safety")
        if isinstance(artifact.get("safety"), dict)
        else {}
    )
    raw_clearance_cards = artifact.get("exact_clearance_cards")
    clearance_cards = (
        raw_clearance_cards if isinstance(raw_clearance_cards, list) else []
    )
    raw_rule_results = artifact.get("clearance_rule_results")
    rule_results = (
        [row for row in raw_rule_results if isinstance(row, dict)]
        if isinstance(raw_rule_results, list)
        else []
    )
    expected_clearances, policy_rules_valid = (
        _exact_clearances_from_policy(nominal_policy)
    )
    expected_clearance_cards = set(expected_clearances)
    observed_clearance_cards = {
        str(card_name) for card_name in clearance_cards if card_name
    }
    rules_by_card = {
        str(row.get("card_name") or ""): row for row in rule_results
    }
    raw_nominal_cards = artifact.get("existing_nominal_cards")
    nominal_cards = (
        [row for row in raw_nominal_cards if isinstance(row, dict)]
        if isinstance(raw_nominal_cards, list)
        else []
    )
    nominal_by_card = {
        str(row.get("card_name") or ""): row for row in nominal_cards
    }
    raw_without_nominal = artifact.get(
        "exact_clearance_cards_without_direct_nominal_reference"
    )
    without_nominal = (
        [str(value) for value in raw_without_nominal if value]
        if isinstance(raw_without_nominal, list)
        else []
    )
    expected_without_nominal = {
        card_name
        for card_name, rule in expected_clearances.items()
        if not rule["direct_test_references"]
    }
    exact_rules_valid = (
        policy_rules_valid
        and len(rule_results) == len(raw_rule_results or [])
        == len(expected_clearances)
        and set(rules_by_card) == expected_clearance_cards
        and len(without_nominal) == len(set(without_nominal))
        and set(without_nominal) == expected_without_nominal
    )
    if exact_rules_valid:
        for card_name, rule_expected in expected_clearances.items():
            row = rules_by_card[card_name]
            nominal_row = nominal_by_card.get(card_name, {})
            rule_valid = (
                row.get("status") == "pass"
                and row.get("failures") == []
                and row.get("rule_id") == rule_expected["rule_id"]
                and row.get("source_path") == rule_expected["source_path"]
                and row.get("source_scope") == rule_expected["source_scope"]
                and row.get("diff_hash_mode")
                == "git_diff_no_ext_diff_no_textconv_unified0_full_index"
                and row.get("canonical_diff_sha256")
                == rule_expected["canonical_diff_sha256"]
                and row.get("from_blob_oid_sha1")
                == rule_expected["from_blob_oid_sha1"]
                and row.get("to_blob_oid_sha1")
                == rule_expected["to_blob_oid_sha1"]
                and row.get("from_source_sha256")
                == rule_expected["from_source_sha256"]
                and row.get("to_source_sha256")
                == rule_expected["to_source_sha256"]
                and row.get("normalized_token_sha256")
                == rule_expected["normalized_token_sha256"]
                and row.get("non_executable_tokens_equivalent") is True
                and sorted(
                    row.get("required_direct_test_references") or []
                )
                == sorted(rule_expected["direct_test_references"])
                and row.get("required_test_case_count")
                == rule_expected["required_test_case_count"]
            )
            if rule_expected["direct_test_references"]:
                rule_valid = rule_valid and (
                    nominal_row.get("class") == rule_expected["class"]
                    and nominal_row.get("source_path")
                    == rule_expected["source_path"]
                    and nominal_row.get("source_scope")
                    == rule_expected["source_scope"]
                    and nominal_row.get("canonical_diff_sha256")
                    == rule_expected["canonical_diff_sha256"]
                    and nominal_row.get("clearance_rule_id")
                    == rule_expected["rule_id"]
                    and nominal_row.get("lane")
                    == "exact_non_executable_tokens_clearance"
                    and sorted(
                        nominal_row.get("direct_test_references") or []
                    )
                    == sorted(rule_expected["direct_test_references"])
                    and nominal_row.get("focused_test_case_count")
                    == rule_expected["required_test_case_count"]
                )
            else:
                rule_valid = rule_valid and card_name not in nominal_by_card
            exact_rules_valid = exact_rules_valid and rule_valid

    expected_clearance_count = _integer(
        expected.get("exact_transition_clearance_card_count")
    )
    expected_review_before = _integer(
        expected.get("review_required_before_exact_clearance")
    )
    expected_review_after = _integer(
        expected.get("review_required_after_exact_clearance")
    )
    declared_digest = str(pointer.get("artifact_sha256") or "")
    input_digest = str(
        input_digests.get("transition_nominal_review_v2_sha256") or ""
    )
    policy_input_digest = str(
        input_digests.get("transition_nominal_review_policy_v2_sha256") or ""
    )
    valid = (
        not load_error
        and artifact.get("schema_version") == NOMINAL_REVIEW_SCHEMA_VERSION
        and artifact.get("status") == "pass"
        and artifact.get("failures") == []
        and transition.get("id") == transition_id
        and transition.get("from_pin") == from_pin
        and transition.get("to_pin") == to_pin
        and summary.get("changed_card_count")
        == expected.get("changed_card_implementations")
        and summary.get("existing_nominal_reference_card_count")
        == expected.get("direct_test_reference_card_count")
        and len(nominal_cards) == len(raw_nominal_cards or [])
        == expected.get("direct_test_reference_card_count")
        and len(nominal_by_card) == len(nominal_cards)
        and expected_clearance_count == len(expected_clearance_cards)
        and summary.get("exact_clearance_card_count")
        == expected_clearance_count
        and summary.get("review_required_before_exact_clearance")
        == expected_review_before
        and summary.get("review_required_after_exact_clearance")
        == expected_review_after
        and observed_clearance_cards == expected_clearance_cards
        and len(clearance_cards) == len(observed_clearance_cards)
        and exact_rules_valid
        and safety.get("read_only") is True
        and safety.get("network_used") is False
        and safety.get("source_mutations") is False
        and safety.get("postgres_writes") is False
        and safety.get("catalog_resolution_used_as_semantic_proof") is False
        and safety.get("canonical_diff_hash_mode")
        == "git_diff_no_ext_diff_no_textconv_unified0_full_index"
        and safety.get("full_blob_oids_required") is True
        and safety.get("source_sha256_required") is True
        and safety.get("unlisted_token_changes_allowed") is False
        and pointer.get("schema_version") == NOMINAL_REVIEW_SCHEMA_VERSION
        and pointer.get("policy_schema_version")
        == NOMINAL_POLICY_SCHEMA_VERSION
        and pointer.get("policy_sha256") == nominal_policy_sha256
        and nominal_policy_sha256 == policy_input_digest
        and pointer.get("exact_clearance_cards")
        == sorted(expected_clearance_cards)
        and pointer.get("review_required_before") == expected_review_before
        and pointer.get("review_required_after") == expected_review_after
        and pointer.get("catalog_resolution_used_as_semantic_proof") is False
        and SHA256_PATTERN.fullmatch(declared_digest) is not None
        and artifact_sha256 == declared_digest == input_digest
    )
    _check(
        checks,
        "transition_nominal_review_evidence",
        valid,
        "Exact nominal clearance must be backed by the pinned, read-only transition artifact.",
        details={
            "artifact_path": artifact_path_value,
            "artifact_sha256": artifact_sha256,
            "declared_sha256": declared_digest,
            "input_digest": input_digest,
            "policy_sha256": nominal_policy_sha256,
            "policy_input_digest": policy_input_digest,
            "load_error": load_error,
            "clearance_cards": sorted(observed_clearance_cards),
        },
    )
    if not valid:
        return {}
    return {
        card_name: dict(expected_clearances[card_name])
        for card_name in sorted(expected_clearance_cards)
    }


def _activation_underlying_disposition_valid(
    row: dict[str, Any],
    *,
    actionable_card_names: set[str],
    exact_clearance_rules: dict[str, dict[str, Any]],
) -> bool:
    disposition = row.get("underlying_transition_disposition")
    catalog_status = row.get("catalog_status_before_activation")
    kind = row.get("change_kind")
    card_name = str(row.get("card_name") or "")
    card_class = str(row.get("class") or "")
    direct_tests = row.get("direct_test_references")
    focused_cases = _integer(row.get("focused_test_case_count"))
    if (
        not isinstance(direct_tests, list)
        or focused_cases is None
        or focused_cases < 0
        or catalog_status not in {"supported", "unsupported"}
    ):
        return False
    valid = False
    if disposition == "focused_upstream_test_passed":
        valid = (
            kind == "added"
            and catalog_status == "supported"
            and bool(direct_tests)
            and focused_cases > 0
        )
    elif (
        disposition
        == "focused_upstream_test_passed_card_data_warning_review_required"
    ):
        valid = (
            kind == "added"
            and catalog_status == "supported"
            and bool(direct_tests)
            and focused_cases > 0
            and isinstance(row.get("card_data_warnings"), list)
            and bool(row.get("card_data_warnings"))
        )
    elif disposition == "catalog_supported_semantic_review_required":
        valid = (
            kind == "added"
            and catalog_status == "supported"
            and not direct_tests
            and focused_cases == 0
        )
    elif (
        disposition
        == "catalog_supported_nominal_test_passed_semantic_review_required"
    ):
        valid = (
            kind == "modified"
            and catalog_status == "supported"
            and bool(direct_tests)
            and focused_cases > 0
        )
    elif disposition == "catalog_supported_regression_only_review_required":
        valid = (
            kind == "modified"
            and catalog_status == "supported"
            and not direct_tests
            and focused_cases == 0
        )
    elif disposition == "external_residual_upstream_unfinished":
        residual = row.get("external_residual")
        valid = (
            kind == "added"
            and catalog_status == "unsupported"
            and isinstance(residual, dict)
            and residual.get("reason")
            == "removed_from_xmage_catalog_as_unfinished"
            and residual.get("forge_exact_match_count") == 0
        )
    elif disposition == CLEARANCE_DISPOSITION:
        clearance_expected = exact_clearance_rules.get(card_name, {})
        source_warning_markers = row.get("source_warning_markers")
        valid = (
            kind == "modified"
            and all(
                isinstance(reference, str) for reference in direct_tests
            )
            and sorted(direct_tests)
            == sorted(clearance_expected.get("direct_test_references", []))
            and focused_cases
            == clearance_expected.get("required_test_case_count")
            and card_class == clearance_expected.get("class")
            and row.get("source_path")
            == clearance_expected.get("source_path")
            and isinstance(source_warning_markers, list)
            and not source_warning_markers
            and card_name not in actionable_card_names
            and row.get("transition_review_rule_id")
            == clearance_expected.get("rule_id")
            and card_name in exact_clearance_rules
        )
    if (
        disposition != CLEARANCE_DISPOSITION
        and row.get("transition_review_rule_id") is not None
    ):
        return False
    return valid


def _validate_card_rows(
    evidence: dict[str, Any],
    expected: dict[str, Any],
    checks: list[dict[str, Any]],
    *,
    exact_clearance_rules: dict[str, dict[str, Any]],
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
    actionable_card_names = {
        str(row.get("card_name") or "")
        for row in actionable_findings
        if isinstance(row, dict) and row.get("card_name")
    }

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
        card_name = str(row.get("card_name") or "")
        clearance_expected = exact_clearance_rules.get(card_name, {})
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
        elif disposition == PRODUCT_FOCUSED_CLEARANCE_DISPOSITION:
            valid = (
                valid
                and kind in {"added", "modified"}
                and catalog_status == "supported"
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
        elif disposition == CLEARANCE_DISPOSITION:
            source_warning_markers = row.get("source_warning_markers")
            valid = (
                valid
                and kind == "modified"
                and catalog_status in {"supported", "unsupported"}
                and all(isinstance(reference, str) for reference in direct_tests)
                and sorted(direct_tests)
                == sorted(clearance_expected.get("direct_test_references", []))
                and focused_cases
                == clearance_expected.get("required_test_case_count")
                and card_class == clearance_expected.get("class")
                and row.get("source_path")
                == clearance_expected.get("source_path")
                and isinstance(source_warning_markers, list)
                and not source_warning_markers
                and card_name not in actionable_card_names
                and row.get("transition_review_rule_id")
                == clearance_expected.get("rule_id")
                and card_name in exact_clearance_rules
            )
        elif disposition == "catalog_supported_regression_only_review_required":
            valid = (
                valid
                and kind == "modified"
                and catalog_status == "supported"
                and not direct_tests
                and focused_cases == 0
            )
        elif disposition == ACTIVATION_BLOCKED_DISPOSITION:
            valid = (
                valid
                and catalog_status == "unsupported"
                and _activation_underlying_disposition_valid(
                    row,
                    actionable_card_names=actionable_card_names,
                    exact_clearance_rules=exact_clearance_rules,
                )
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
                and card_name
                in EXPECTED_NON_BLOCKING_QUARANTINES[
                    "external_runtime_quarantine_semantic_defect"
                ]
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
        elif (
            disposition
            == "external_runtime_quarantine_known_upstream_gap"
        ):
            residual = row.get("external_residual")
            source_warning_markers = row.get("source_warning_markers")
            valid = (
                valid
                and kind == "modified"
                and catalog_status == "unsupported"
                and card_name
                in EXPECTED_NON_BLOCKING_QUARANTINES[
                    "external_runtime_quarantine_known_upstream_gap"
                ]
                and not direct_tests
                and focused_cases == 0
                and isinstance(source_warning_markers, list)
                and any(
                    isinstance(marker, dict)
                    and "#12911" in str(marker.get("marker") or "")
                    for marker in source_warning_markers
                )
                and isinstance(residual, dict)
                and residual.get("reason")
                == "pinned_xmage_known_upstream_gap_quarantined"
                and residual.get("reason_code")
                == "xmage_upstream_copy_lki_gap"
                and residual.get("qualification_engine_commit")
                == evidence.get("to_pin")
                and residual.get("upstream_issue")
                == "magefree/mage#12911"
                and residual.get("upstream_issue_status") == "OPEN"
                and residual.get("release_condition")
                == "blocked_until_copy_lki_fix_and_focused_qualification"
                and residual.get("policy_path")
                == (
                    "services/xmage-sidecar/src/main/java/com/manaloom/xmage/"
                    "XmageCardQualificationPolicy.java"
                )
            )
        else:
            valid = False
        if (
            disposition
            not in {CLEARANCE_DISPOSITION, ACTIVATION_BLOCKED_DISPOSITION}
            and row.get("transition_review_rule_id") is not None
        ):
            valid = False
        if not valid:
            malformed.append(card_class)

    observed_non_blocking_quarantines = {
        disposition: {
            str(row.get("card_name") or "")
            for row in rows
            if row.get("disposition") == disposition
        }
        for disposition in EXPECTED_NON_BLOCKING_QUARANTINES
    }

    _check(
        checks,
        "card_disposition_evidence",
        not malformed
        and observed_non_blocking_quarantines
        == EXPECTED_NON_BLOCKING_QUARANTINES,
        "Each disposition must carry the evidence required by its exact meaning.",
        details={
            "malformed_classes": malformed,
            "non_blocking_quarantines": {
                key: sorted(value)
                for key, value in observed_non_blocking_quarantines.items()
            },
        },
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
        and len(executable_set) == len(executable_classes or []) == 28
        and len(comment_only_set) == len(comment_only_classes or []) == 2
        and not (executable_set & comment_only_set)
        and executable_set | comment_only_set <= modified_class_set
        and "MjolnirHammerOfThor" in executable_set
        and "SwordsmanSharpScoundrel" in executable_set
        and "MetallicMimic" in presentation_set
        and comment_only_set == {"KrarkTheThumbless", "MandateOfPeace"}
        and len(presentation_set) == 52
        and modified_scope.get("presentation_or_metadata_count") == 52
        and scope_counts
        == {
            "comment_only": 2,
            "executable_or_mixed": 28,
            "presentation_or_metadata": 52,
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

    nominal_policy_path_value = str(
        transition.get("nominal_review_policy_path") or ""
    )
    nominal_policy_path = _safe_repo_path(
        repo_root,
        nominal_policy_path_value,
    )
    nominal_policy: dict[str, Any] = {}
    nominal_policy_sha256 = ""
    nominal_policy_load_error = ""
    if nominal_policy_path is None:
        nominal_policy_load_error = "policy_path_invalid"
    else:
        try:
            nominal_policy = load_json(nominal_policy_path)
            nominal_policy_sha256 = file_sha256(nominal_policy_path)
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            nominal_policy_load_error = type(exc).__name__
    nominal_policy_contract_valid = (
        not nominal_policy_load_error
        and nominal_policy.get("schema_version")
        == NOMINAL_POLICY_SCHEMA_VERSION
        and nominal_policy.get("transition_id") == transition_id
        and nominal_policy.get("from_pin") == from_pin
        and nominal_policy.get("to_pin") == to_pin
        and nominal_policy.get("catalog_resolution_is_semantic_proof")
        is False
        and nominal_policy.get("canonical_diff_hash_mode")
        == "git_diff_no_ext_diff_no_textconv_unified0_full_index"
        and nominal_policy.get("requires_full_blob_oids") is True
        and nominal_policy.get("requires_source_sha256") is True
        and nominal_policy.get("unlisted_token_changes_allowed") is False
        and nominal_policy.get("filter_predicate_normalization_allowed")
        is False
        and nominal_policy.get(
            "automatic_clearance_does_not_activate_runtime_card"
        )
        is True
        and SHA256_PATTERN.fullmatch(
            str(transition.get("nominal_review_policy_sha256") or "")
        )
        is not None
        and nominal_policy_sha256
        == transition.get("nominal_review_policy_sha256")
    )
    _check(
        checks,
        "transition_nominal_review_policy",
        nominal_policy_contract_valid,
        "The exact non-executable transition policy must be versioned and digest-pinned.",
        details={
            "policy_path": nominal_policy_path_value,
            "policy_sha256": nominal_policy_sha256,
            "declared_sha256": transition.get(
                "nominal_review_policy_sha256"
            ),
            "load_error": nominal_policy_load_error,
        },
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
    exact_clearance_rules = _validate_transition_nominal_review(
        evidence,
        expected,
        checks,
        repo_root=repo_root,
        transition_id=transition_id,
        from_pin=from_pin,
        to_pin=to_pin,
        input_digests=input_digests,
        nominal_policy=nominal_policy if nominal_policy_contract_valid else {},
        nominal_policy_sha256=(
            nominal_policy_sha256 if nominal_policy_contract_valid else ""
        ),
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

    card_summary = _validate_card_rows(
        evidence,
        expected,
        checks,
        exact_clearance_rules=exact_clearance_rules,
    )
    expected_card_names = set(card_summary.pop("card_names"))
    _check(
        checks,
        "deployment_blocking_review_count",
        card_summary["review_required_count"]
        == expected.get("deployment_blocking_review_required_card_count"),
        "Deployment-blocking reviews must exclude only explicitly quarantined non-promotional cards.",
        details={
            "observed": card_summary["review_required_count"],
            "expected": expected.get(
                "deployment_blocking_review_required_card_count"
            ),
        },
    )
    evidence_cards = [
        row
        for row in (
            evidence.get("cards")
            if isinstance(evidence.get("cards"), list)
            else []
        )
        if isinstance(row, dict)
    ]

    postgres_pointer = (
        evidence.get("postgresql_scope_reconciliation")
        if isinstance(evidence.get("postgresql_scope_reconciliation"), dict)
        else {}
    )
    postgres_status = postgres_pointer.get("status")
    postgres_path_value = str(postgres_pointer.get("artifact_path") or "")
    postgres_path = _safe_repo_path(repo_root, postgres_path_value)
    postgres_artifact: dict[str, Any] = {}
    postgres_artifact_sha256 = ""
    postgres_load_error = ""
    if postgres_status == "pass":
        if postgres_path is None:
            postgres_load_error = "artifact_path_invalid"
        else:
            try:
                postgres_artifact = load_json(postgres_path)
                postgres_artifact_sha256 = file_sha256(postgres_path)
            except (OSError, ValueError, json.JSONDecodeError) as exc:
                postgres_load_error = type(exc).__name__
    postgres_pointer_fields = {
        "schema_version",
        "status",
        "canonical_wrapper",
        "transaction_mode",
        "transaction_read_only",
        "writes_performed",
        "queries_executed",
        "requested_card_count",
        "reconciled_card_count",
        "ambiguity_count",
        "scope_counts",
        "rows_sha256",
    }
    postgres_pointer_matches_artifact = all(
        postgres_pointer.get(key) == postgres_artifact.get(key)
        for key in postgres_pointer_fields
    )
    postgres_pass_shape_valid = (
        postgres_status == "pass"
        and not postgres_load_error
        and _postgres_pass_shape_valid(
            postgres_artifact,
            expected_card_names=expected_card_names,
        )
        and postgres_pointer_matches_artifact
        and SHA256_PATTERN.fullmatch(
            str(postgres_pointer.get("artifact_sha256") or "")
        )
        is not None
        and postgres_artifact_sha256
        == postgres_pointer.get("artifact_sha256")
        == input_digests.get(
            "postgresql_scope_reconciliation_v1_sha256"
        )
    )
    postgres_blocked_shape_valid = (
        postgres_status == "blocked"
        and postgres_pointer.get("reason")
        == "missing_approved_ssh_host_key_sha256"
        and postgres_pointer.get("queries_executed") == 0
        and postgres_pointer.get("writes_performed") is False
        and not postgres_path_value
    )
    postgres_shape_valid = (
        postgres_pass_shape_valid or postgres_blocked_shape_valid
    )
    _check(
        checks,
        "postgresql_reconciliation_evidence",
        postgres_shape_valid,
        "PostgreSQL reconciliation must be an exact digest-pinned read-only artifact or record the exact safe preflight block.",
        details={
            "artifact_path": postgres_path_value,
            "artifact_sha256": postgres_artifact_sha256,
            "declared_sha256": postgres_pointer.get("artifact_sha256"),
            "load_error": postgres_load_error,
        },
    )

    future_gate = (
        evidence.get("future_release_activation_gate")
        if isinstance(evidence.get("future_release_activation_gate"), dict)
        else {}
    )
    future_only_count = card_summary["release_scopes"].get("future_only", 0)
    future_gate_status = future_gate.get("status")
    activation_path_value = str(future_gate.get("resource_path") or "")
    activation_path = _safe_repo_path(repo_root, activation_path_value)
    activation_policy: dict[str, Any] = {}
    activation_policy_sha256 = ""
    activation_load_error = ""
    if future_gate_status == "pass":
        if activation_path is None:
            activation_load_error = "resource_path_invalid"
        else:
            try:
                activation_policy = load_json(activation_path)
                activation_policy_sha256 = file_sha256(activation_path)
            except (OSError, ValueError, json.JSONDecodeError) as exc:
                activation_load_error = type(exc).__name__
    activation_policy_valid = (
        postgres_pass_shape_valid
        and not activation_load_error
        and SHA256_PATTERN.fullmatch(
            str(future_gate.get("resource_sha256") or "")
        )
        is not None
        and activation_policy_sha256
        == future_gate.get("resource_sha256")
        == input_digests.get("transition_activation_policy_v1_sha256")
        and _activation_policy_shape_valid(
            activation_policy,
            evidence_cards=evidence_cards,
            postgres=postgres_artifact,
            postgres_artifact_sha256=postgres_artifact_sha256,
            transition_id=transition_id,
            from_pin=from_pin,
            to_pin=to_pin,
        )
    )
    postgres_scope_counts = (
        postgres_artifact.get("scope_counts")
        if isinstance(postgres_artifact.get("scope_counts"), dict)
        else {}
    )
    future_gate_pass_shape_valid = (
        future_gate_status == "pass"
        and future_gate.get("schema_version")
        == FUTURE_ACTIVATION_GATE_SCHEMA_VERSION
        and future_gate.get("engine_commit") == to_pin
        and future_gate.get("transition_card_count")
        == expected.get("changed_card_implementations")
        and future_gate.get("blocked_card_count")
        == expected.get("activation_policy_blocked_card_count")
        == (
            postgres_scope_counts.get("future_deferred", 0)
            + postgres_scope_counts.get(
                "released_missing_from_postgresql", 0
            )
        )
        and future_gate.get("future_only_card_count")
        == future_only_count
        == postgres_scope_counts.get("future_deferred")
        == expected.get("postgresql_future_deferred")
        and future_gate.get("released_missing_card_count")
        == postgres_scope_counts.get("released_missing_from_postgresql")
        == expected.get("postgresql_released_missing")
        and isinstance(future_gate.get("enforced_by"), list)
        and all(
            isinstance(value, str)
            for value in future_gate.get("enforced_by")
        )
        and set(future_gate.get("enforced_by"))
        == EXPECTED_ACTIVATION_ENFORCERS
        and future_gate.get("tests")
        == expected.get("qualified_policy_test_count")
        and future_gate.get("result") == "pass"
        and future_gate.get("user_facing_reason_must_be_engine_neutral")
        is True
        and activation_policy_valid
    )
    future_gate_missing_shape_valid = (
        future_gate_status == "missing"
        and future_gate.get("reason")
        == "no_versioned_product_release_activation_gate_evidence"
        and future_gate.get("future_only_card_count") == future_only_count
        and not activation_path_value
    )
    future_gate_shape_valid = (
        future_gate_pass_shape_valid or future_gate_missing_shape_valid
    )
    _check(
        checks,
        "future_release_activation_gate",
        future_gate_shape_valid,
        "Future-only and PostgreSQL-absent cards require an exact digest-pinned fail-closed activation policy or an explicit safe block.",
        details={
            "resource_path": activation_path_value,
            "resource_sha256": activation_policy_sha256,
            "declared_sha256": future_gate.get("resource_sha256"),
            "load_error": activation_load_error,
        },
    )

    focused_test_pointer = (
        evidence.get("product_scope_focused_test_evidence")
        if isinstance(
            evidence.get("product_scope_focused_test_evidence"), dict
        )
        else {}
    )
    focused_test_path_value = str(
        focused_test_pointer.get("artifact_path") or ""
    )
    focused_test_path = _safe_repo_path(
        repo_root, focused_test_path_value
    )
    focused_test_artifact: dict[str, Any] = {}
    focused_test_artifact_sha256 = ""
    focused_test_load_error = ""
    if focused_test_path is None:
        focused_test_load_error = "artifact_path_invalid"
    else:
        try:
            focused_test_artifact = load_json(focused_test_path)
            focused_test_artifact_sha256 = file_sha256(
                focused_test_path
            )
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            focused_test_load_error = type(exc).__name__
    focused_test_shape_valid = (
        postgres_pass_shape_valid
        and not focused_test_load_error
        and focused_test_pointer.get("schema_version")
        == PRODUCT_SCOPE_FOCUSED_TEST_SCHEMA_VERSION
        and SHA256_PATTERN.fullmatch(
            str(focused_test_pointer.get("artifact_sha256") or "")
        )
        is not None
        and focused_test_artifact_sha256
        == focused_test_pointer.get("artifact_sha256")
        == input_digests.get(
            "product_scope_focused_test_evidence_v2_sha256"
        )
        and focused_test_pointer.get("combined_test_count")
        == expected.get("product_scope_focused_test_count")
        and focused_test_pointer.get("direct_card_count")
        == expected.get("product_scope_direct_focused_card_count")
        and focused_test_pointer.get("execution_report_count")
        == expected.get("product_scope_focused_execution_report_count")
        and focused_test_pointer.get(
            "partial_tests_are_complete_clearance"
        )
        is False
        and focused_test_pointer.get(
            "planetarium_test_is_promotion_evidence"
        )
        is False
        and focused_test_pointer.get(
            "mandate_of_peace_test_is_promotion_evidence"
        )
        is False
        and focused_test_pointer.get("upstream_card_source_modified")
        is False
        and _product_scope_focused_test_shape_valid(
            focused_test_artifact,
            focused_artifact_path=focused_test_path_value,
            evidence_cards=evidence_cards,
            postgres=postgres_artifact,
            postgres_artifact_path=postgres_path_value,
            postgres_artifact_sha256=postgres_artifact_sha256,
            repo_root=repo_root,
            from_pin=from_pin,
            to_pin=to_pin,
            expected_test_count=_integer(
                expected.get("product_scope_focused_test_count")
            ),
            expected_direct_card_count=_integer(
                expected.get(
                    "product_scope_direct_focused_card_count"
                )
            ),
            expected_patch_count=_integer(
                expected.get("product_scope_focused_patch_count")
            ),
            expected_execution_report_count=_integer(
                expected.get(
                    "product_scope_focused_execution_report_count"
                )
            ),
        )
    )
    _check(
        checks,
        "product_scope_focused_test_evidence",
        focused_test_shape_valid,
        "Product-scope focused tests must be versioned, digest-pinned and preserve partial-test and quarantine boundaries.",
        details={
            "artifact_path": focused_test_path_value,
            "artifact_sha256": focused_test_artifact_sha256,
            "declared_sha256": focused_test_pointer.get(
                "artifact_sha256"
            ),
            "load_error": focused_test_load_error,
        },
    )

    contract_review_links = (
        transition.get("review_artifacts")
        if isinstance(transition.get("review_artifacts"), dict)
        else {}
    )
    evidence_review_links = (
        evidence.get("transition_review_derivatives")
        if isinstance(evidence.get("transition_review_derivatives"), dict)
        else {}
    )
    matrix_pointer = (
        evidence_review_links.get("active_scope_semantic_matrix")
        if isinstance(
            evidence_review_links.get("active_scope_semantic_matrix"), dict
        )
        else {}
    )
    index_pointer = (
        evidence_review_links.get("transition_compact_review_index")
        if isinstance(
            evidence_review_links.get("transition_compact_review_index"),
            dict,
        )
        else {}
    )
    matrix_path_value = str(matrix_pointer.get("artifact_path") or "")
    index_path_value = str(index_pointer.get("artifact_path") or "")
    matrix_path = _safe_repo_path(repo_root, matrix_path_value)
    index_path = _safe_repo_path(repo_root, index_path_value)
    matrix_artifact: dict[str, Any] = {}
    index_artifact: dict[str, Any] = {}
    matrix_sha256 = ""
    index_sha256 = ""
    review_artifact_load_errors: list[str] = []
    for artifact_id, artifact_path in (
        ("active_scope_semantic_matrix", matrix_path),
        ("transition_compact_review_index", index_path),
    ):
        if artifact_path is None:
            review_artifact_load_errors.append(
                f"{artifact_id}:artifact_path_invalid"
            )
            continue
        try:
            loaded = load_json(artifact_path)
            loaded_sha256 = file_sha256(artifact_path)
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            review_artifact_load_errors.append(
                f"{artifact_id}:{type(exc).__name__}"
            )
            continue
        if artifact_id == "active_scope_semantic_matrix":
            matrix_artifact = loaded
            matrix_sha256 = loaded_sha256
        else:
            index_artifact = loaded
            index_sha256 = loaded_sha256

    review_qualification = (
        evidence.get("qualification")
        if isinstance(evidence.get("qualification"), dict)
        else {}
    )
    source_primary_snapshot_sha256 = str(
        evidence_review_links.get("source_primary_snapshot_sha256") or ""
    )
    review_links_valid = (
        not review_artifact_load_errors
        and evidence_review_links == contract_review_links
        and evidence_review_links.get("schema_version")
        == REVIEW_DERIVATIVE_LINK_SCHEMA_VERSION
        and SHA256_PATTERN.fullmatch(source_primary_snapshot_sha256)
        is not None
        and evidence_review_links.get("focused_test_evidence_sha256")
        == focused_test_artifact_sha256
        == focused_test_pointer.get("artifact_sha256")
        and matrix_pointer.get("schema_version")
        == ACTIVE_SCOPE_MATRIX_SCHEMA_VERSION
        and matrix_pointer.get("card_count") == 36
        and matrix_sha256
        == matrix_pointer.get("artifact_sha256")
        == input_digests.get(
            "transition_active_scope_semantic_matrix_v1_sha256"
        )
        and index_pointer.get("schema_version")
        == COMPACT_REVIEW_INDEX_SCHEMA_VERSION
        and index_pointer.get("card_count") == 169
        and index_sha256
        == index_pointer.get("artifact_sha256")
        == input_digests.get(
            "transition_compact_review_index_v1_sha256"
        )
    )
    review_artifacts_valid = (
        review_links_valid
        and postgres_pass_shape_valid
        and focused_test_shape_valid
        and _transition_review_artifacts_shape_valid(
            matrix_artifact,
            index_artifact,
            evidence_cards=evidence_cards,
            postgres=postgres_artifact,
            qualification=review_qualification,
            primary_evidence_path=str(
                transition.get("evidence_path") or ""
            ),
            source_primary_snapshot_sha256=(
                source_primary_snapshot_sha256
            ),
            focused_artifact_path=focused_test_path_value,
            focused_artifact_sha256=focused_test_artifact_sha256,
            from_pin=from_pin,
            to_pin=to_pin,
        )
    )
    _check(
        checks,
        "transition_review_artifacts",
        review_artifacts_valid,
        "The 36-card semantic matrix and 169-card review index must remain digest-pinned and match exact primary identities and statuses.",
        details={
            "matrix_path": matrix_path_value,
            "matrix_sha256": matrix_sha256,
            "index_path": index_path_value,
            "index_sha256": index_sha256,
            "load_errors": review_artifact_load_errors,
        },
    )

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
        and '"Mandate of Peace"' in policy_source
        and '"xmage_upstream_copy_lki_gap"' in policy_source
        and '"magefree/mage#12911"' in policy_source
        and "requireEngineCommit" in policy_source,
        "The pin-scoped card qualification policy source must match the transition evidence.",
    )
    runtime_supported = _integer(runtime.get("supported"))
    runtime_unsupported = _integer(runtime.get("unsupported"))
    activation_restricted = _integer(
        runtime.get("activation_restricted")
    )
    external_gap_restricted = _integer(
        runtime.get("external_runtime_gap_restricted")
    )
    runtime_total = _integer(runtime.get("total"))
    runtime_activation_shape_valid = (
        postgres_pass_shape_valid
        and future_gate_pass_shape_valid
        and runtime.get("engine_commit") == to_pin
        and runtime.get("catalog_ready") is True
        and runtime.get("total")
        == expected.get("changed_card_implementations")
        and runtime.get("catalog_resolved_before_qualification")
        == expected.get("runtime_catalog_resolved_before_qualification")
        and runtime.get("catalog_unresolved_before_qualification")
        == expected.get("runtime_catalog_unresolved_before_qualification")
        and runtime_supported
        == expected.get("runtime_after_activation_supported")
        == postgres_scope_counts.get("product_in_scope")
        == expected.get("postgresql_product_in_scope")
        and runtime_unsupported
        == expected.get("runtime_after_activation_unsupported")
        and activation_restricted
        == expected.get("runtime_activation_restricted")
        == future_gate.get("blocked_card_count")
        and external_gap_restricted
        == expected.get("runtime_external_gap_restricted")
        == postgres_scope_counts.get("external_runtime_gap")
        == expected.get("postgresql_external_runtime_gap")
        and runtime_unsupported is not None
        and activation_restricted is not None
        and external_gap_restricted is not None
        and runtime_unsupported
        == activation_restricted + external_gap_restricted
        and runtime_supported is not None
        and runtime_total is not None
        and runtime_supported + runtime_unsupported == runtime_total
        and runtime.get("activation_policy_resource_path")
        == activation_path_value
        and runtime.get("activation_policy_resource_sha256")
        == activation_policy_sha256
        and runtime.get("unsupported_names_embedded") is False
        and runtime.get("qualification_policy_engine_commit") == to_pin
        and runtime.get("qualification_policy_path")
        == (
            "services/xmage-sidecar/src/main/java/com/manaloom/xmage/"
            "XmageCardQualificationPolicy.java"
        )
        and policy_test.get("tests")
        == expected.get("qualified_policy_test_count")
        and policy_test.get("failures") == 0
        and policy_test.get("errors") == 0
        and policy_test.get("skipped") == 0
        and SHA256_PATTERN.fullmatch(
            str(policy_test.get("surefire_sha256") or "")
        )
        is not None
        and policy_test.get("surefire_sha256")
        == input_digests.get(
            "sidecar_transition_coverage_surefire_sha256"
        )
        and runtime.get("catalog_resolution_is_semantic_proof") is False
    )
    _check(
        checks,
        "runtime_catalog_proof",
        runtime_activation_shape_valid,
        "Runtime coverage must exactly apply PostgreSQL scope and the activation policy without claiming semantic proof.",
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
    diagnostics_shape_valid = _card_data_diagnostics_shape_valid(
        diagnostics,
        evidence_cards=evidence_cards,
        postgres=postgres_artifact,
        focused_artifact=focused_test_artifact,
        focused_artifact_path=focused_test_path_value,
        focused_artifact_valid=focused_test_shape_valid,
        repo_root=repo_root,
    )
    _check(
        checks,
        "card_data_diagnostics",
        diagnostics_shape_valid
        and len(actionable_findings)
        == expected.get("card_data_actionable_finding_count"),
        "Detailed card-data findings must be activation-blocked, exactly quarantined, or proven outside the runtime presentation boundary.",
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

    qualification = (
        evidence.get("qualification")
        if isinstance(evidence.get("qualification"), dict)
        else {}
    )
    proof_ready = (
        card_summary["review_required_count"] == 0
        and diagnostics_shape_valid
        and postgres_status == "pass"
        and postgres_shape_valid
        and (future_only_count == 0 or future_gate_status == "pass")
        and future_gate_shape_valid
        and runtime_activation_shape_valid
        and focused_test_shape_valid
        and review_artifacts_valid
    )
    computed_deployable = proof_ready
    required_blocking_reasons: set[str] = set()
    if card_summary["review_required_count"] > 0:
        required_blocking_reasons.add(
            "changed_card_semantic_reviews_or_residuals_pending"
        )
    if not diagnostics_shape_valid:
        required_blocking_reasons.add("card_data_diagnostics_not_passed")
    if postgres_status != "pass" or not postgres_shape_valid:
        required_blocking_reasons.add(
            "postgresql_product_scope_reconciliation_not_passed"
        )
    if future_only_count > 0 and future_gate_status != "pass":
        required_blocking_reasons.add(
            "future_only_card_activation_gate_not_passed"
        )
    if not runtime_activation_shape_valid:
        required_blocking_reasons.add(
            "runtime_activation_scope_inconsistent"
        )
    if not focused_test_shape_valid:
        required_blocking_reasons.add(
            "product_scope_focused_test_evidence_invalid"
        )
    if not review_artifacts_valid:
        required_blocking_reasons.add(
            "transition_review_artifacts_invalid"
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
        and required_blocking_reasons == blocking_reason_set
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
