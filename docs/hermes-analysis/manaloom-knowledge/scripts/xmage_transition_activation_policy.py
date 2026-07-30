#!/usr/bin/env python3
"""Build the fail-closed Battle activation policy for a pinned transition.

Cards absent from current PostgreSQL product scope must not become silently
executable if a later catalog import exposes them. This builder binds the
deferment to the exact engine pin and the read-only PostgreSQL reconciliation.
It does not claim that a deferred card is semantically correct.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DEFAULT_EVIDENCE = (
    REPO_ROOT / "docs/qa/evidence/XMAGE_PIN_TRANSITION_34d81ea_2c43ec8.json"
)
DEFAULT_POSTGRES = (
    REPO_ROOT
    / "docs/qa/evidence/"
    "XMAGE_POSTGRESQL_SCOPE_RECONCILIATION_34d81ea_2c43ec8_2026-07-30.json"
)
SCHEMA_VERSION = (
    "manaloom_xmage_transition_activation_policy_v1_2026-07-30"
)
POSTGRES_SCHEMA_VERSION = (
    "manaloom_xmage_postgresql_scope_reconciliation_v1_2026-07-28"
)
DEFERRED_STATUSES = {
    "future_deferred",
    "released_missing_from_postgresql",
}
ACTIVATION_BLOCKED_DISPOSITION = (
    "activation_blocked_pending_product_semantic_review"
)
GIT_SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")


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


def build_policy(
    evidence: Mapping[str, Any],
    postgres: Mapping[str, Any],
    *,
    postgres_artifact_sha256: str,
) -> dict[str, Any]:
    raw_cards = evidence.get("cards")
    raw_results = postgres.get("card_results")
    if not isinstance(raw_cards, list) or not isinstance(raw_results, list):
        raise ValueError("transition cards and PostgreSQL results must be lists")
    cards = [row for row in raw_cards if isinstance(row, Mapping)]
    results = [row for row in raw_results if isinstance(row, Mapping)]
    if len(cards) != len(raw_cards) or len(results) != len(raw_results):
        raise ValueError("all transition and PostgreSQL rows must be objects")

    evidence_by_name = {
        str(row.get("card_name") or ""): row
        for row in cards
        if row.get("card_name")
    }
    postgres_by_name = {
        str(row.get("card_name") or ""): row
        for row in results
        if row.get("card_name")
    }
    if (
        len(evidence_by_name) != len(cards)
        or len(postgres_by_name) != len(results)
        or set(evidence_by_name) != set(postgres_by_name)
    ):
        raise ValueError("transition and PostgreSQL identities must match exactly")
    if (
        postgres.get("schema_version") != POSTGRES_SCHEMA_VERSION
        or postgres.get("status") != "pass"
        or postgres.get("transaction_read_only") is not True
        or postgres.get("writes_performed") is not False
        or postgres.get("ambiguity_count") != 0
        or postgres.get("reconciled_card_count") != len(cards)
        or SHA256_PATTERN.fullmatch(str(postgres.get("rows_sha256") or ""))
        is None
        or SHA256_PATTERN.fullmatch(postgres_artifact_sha256) is None
    ):
        raise ValueError("PostgreSQL reconciliation is not a valid read-only pass")

    blocked_cards: list[dict[str, Any]] = []
    for card_name in sorted(evidence_by_name, key=str.casefold):
        evidence_row = evidence_by_name[card_name]
        postgres_row = postgres_by_name[card_name]
        scope_status = str(postgres_row.get("product_scope_status") or "")
        if scope_status not in DEFERRED_STATUSES:
            continue
        registrations = evidence_row.get("set_registrations")
        release_dates = sorted(
            {
                str(row.get("release_date"))
                for row in registrations or []
                if isinstance(row, Mapping) and row.get("release_date")
            }
        )
        blocked_cards.append(
            {
                "card_name": card_name,
                "class": str(evidence_row.get("class") or ""),
                "source_path": str(evidence_row.get("source_path") or ""),
                "product_scope_status": scope_status,
                "release_scope_as_of_2026_07_28": str(
                    evidence_row.get("release_scope_as_of_2026_07_28") or ""
                ),
                "declared_release_dates": release_dates,
                "reason_code": "battle_card_activation_review_required",
                "release_condition": (
                    "repeat_product_identity_oracle_legality_and_semantic_review"
                ),
            }
        )

    counts = Counter(
        str(row["product_scope_status"]) for row in blocked_cards
    )
    if (
        len(cards) != 169
        or counts != Counter(
            {
                "future_deferred": 45,
                "released_missing_from_postgresql": 88,
            }
        )
    ):
        raise ValueError(
            "deferred scope must remain the exact reviewed 45 future + 88 absent"
        )
    generated_at_utc = str(postgres.get("generated_at_utc") or "")
    if not generated_at_utc:
        raise ValueError("PostgreSQL reconciliation timestamp is required")
    transition_id = str(evidence.get("transition_id") or "")
    from_pin = str(evidence.get("from_pin") or "")
    to_pin = str(evidence.get("to_pin") or "")
    if (
        not transition_id
        or GIT_SHA_PATTERN.fullmatch(from_pin) is None
        or GIT_SHA_PATTERN.fullmatch(to_pin) is None
    ):
        raise ValueError("transition identity and exact engine pins are required")
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at_utc": generated_at_utc,
        "transition_id": transition_id,
        "from_engine_commit": from_pin,
        "engine_commit": to_pin,
        "postgresql_reconciliation": {
            "schema_version": postgres.get("schema_version"),
            "artifact_sha256": postgres_artifact_sha256,
            "rows_sha256": postgres.get("rows_sha256"),
            "transaction_read_only": True,
            "writes_performed": False,
        },
        "policy": {
            "catalog_absence_is_semantic_proof": False,
            "future_release_is_semantic_proof": False,
            "activation_requires_new_versioned_review": True,
            "user_facing_reason_must_be_engine_neutral": True,
        },
        "blocked_card_count": len(blocked_cards),
        "transition_card_count": len(evidence_by_name),
        "transition_card_names": sorted(
            evidence_by_name,
            key=str.casefold,
        ),
        "future_deferred_count": counts["future_deferred"],
        "released_missing_count": counts[
            "released_missing_from_postgresql"
        ],
        "cards": blocked_cards,
    }


def apply_activation_dispositions(
    evidence: Mapping[str, Any],
    postgres: Mapping[str, Any],
    policy: Mapping[str, Any],
) -> dict[str, Any]:
    raw_cards = evidence.get("cards")
    raw_results = postgres.get("card_results")
    raw_policy_cards = policy.get("cards")
    if (
        not isinstance(raw_cards, list)
        or not isinstance(raw_results, list)
        or not isinstance(raw_policy_cards, list)
    ):
        raise ValueError("evidence, PostgreSQL and policy cards are required")
    cards = [row for row in raw_cards if isinstance(row, Mapping)]
    results = [row for row in raw_results if isinstance(row, Mapping)]
    policy_cards = [
        row for row in raw_policy_cards if isinstance(row, Mapping)
    ]
    if (
        len(cards) != len(raw_cards)
        or len(results) != len(raw_results)
        or len(policy_cards) != len(raw_policy_cards)
    ):
        raise ValueError("all activation inputs must contain object rows")
    result_by_name = {
        str(row.get("card_name") or ""): row for row in results
    }
    blocked_names = {
        str(row.get("card_name") or "") for row in policy_cards
    }
    evidence_names = {
        str(row.get("card_name") or "") for row in cards
    }
    expected_blocked_names = {
        name
        for name, row in result_by_name.items()
        if row.get("product_scope_status") in DEFERRED_STATUSES
    }
    if (
        len(result_by_name) != len(results)
        or len(blocked_names) != len(policy_cards)
        or len(evidence_names) != len(cards)
        or set(result_by_name) != evidence_names
        or blocked_names != expected_blocked_names
        or policy.get("blocked_card_count") != len(blocked_names)
    ):
        raise ValueError(
            "activation disposition identities must match policy and PostgreSQL"
        )

    transformed = copy.deepcopy(dict(evidence))
    transformed_cards = transformed.get("cards")
    assert isinstance(transformed_cards, list)
    for row in transformed_cards:
        if not isinstance(row, dict):
            raise ValueError("transformed evidence card must be an object")
        card_name = str(row.get("card_name") or "")
        if card_name not in blocked_names:
            if row.get("disposition") == ACTIVATION_BLOCKED_DISPOSITION:
                raise ValueError(
                    "non-blocked card cannot use activation disposition"
                )
            continue
        if row.get("disposition") == ACTIVATION_BLOCKED_DISPOSITION:
            if (
                not row.get("underlying_transition_disposition")
                or row.get("catalog_status_before_activation")
                not in {"supported", "unsupported"}
            ):
                raise ValueError(
                    "existing activation disposition is missing provenance"
                )
        else:
            if (
                not row.get("disposition")
                or row.get("runtime_catalog_status")
                not in {"supported", "unsupported"}
            ):
                raise ValueError(
                    "activation-blocked card is missing prior provenance"
                )
            row["underlying_transition_disposition"] = row.get(
                "disposition"
            )
            row["catalog_status_before_activation"] = row.get(
                "runtime_catalog_status"
            )
        row["disposition"] = ACTIVATION_BLOCKED_DISPOSITION
        row["runtime_catalog_status"] = "unsupported"

    disposition_counts = Counter(
        str(row.get("disposition") or "") for row in transformed_cards
    )
    runtime_counts = Counter(
        str(row.get("runtime_catalog_status") or "")
        for row in transformed_cards
    )
    summary = transformed.get("card_summary")
    if not isinstance(summary, dict):
        raise ValueError("card_summary is required")
    summary["dispositions"] = dict(sorted(disposition_counts.items()))
    summary["runtime_catalog_statuses"] = dict(sorted(runtime_counts.items()))
    return transformed


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence", type=Path, default=DEFAULT_EVIDENCE)
    parser.add_argument("--postgres", type=Path, default=DEFAULT_POSTGRES)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--output-evidence", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        evidence = load_json(args.evidence)
        postgres = load_json(args.postgres)
        report = build_policy(
            evidence,
            postgres,
            postgres_artifact_sha256=file_sha256(args.postgres),
        )
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            json.dumps(report, indent=2, ensure_ascii=True, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        if args.output_evidence is not None:
            transformed_evidence = apply_activation_dispositions(
                evidence,
                postgres,
                report,
            )
            args.output_evidence.parent.mkdir(parents=True, exist_ok=True)
            args.output_evidence.write_text(
                json.dumps(
                    transformed_evidence,
                    indent=2,
                    ensure_ascii=True,
                    sort_keys=False,
                )
                + "\n",
                encoding="utf-8",
            )
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"xmage_transition_activation_policy_error={exc}")
        return 2
    print("status=pass")
    print(f"blocked_cards={report['blocked_card_count']}")
    print(f"future_deferred={report['future_deferred_count']}")
    print(f"released_missing={report['released_missing_count']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
