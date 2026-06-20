#!/usr/bin/env python3
"""Dry-run planner for learned-deck partner/background identity metadata.

This script intentionally has no apply mode. It reads the current active
learned-deck audit model, finds combined commander identities already inferred
by the read-only auditor, and emits the exact metadata patch plus scoped SQL
that would need explicit PostgreSQL mutation approval.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from copy import deepcopy
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
AUDIT_PATH = SCRIPT_DIR / "learned_deck_coherence_audit.py"
SOURCE = "learned_deck_partner_identity_inference_2026_06_20"


def load_audit_module() -> Any:
    spec = importlib.util.spec_from_file_location(
        "learned_deck_coherence_audit",
        AUDIT_PATH,
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to load {AUDIT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


audit_module = load_audit_module()


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(",", ":"))


def sql_literal(value: Any) -> str:
    return "'" + stable_json(value).replace("'", "''") + "'::jsonb"


def should_plan_backfill(audit: Any) -> bool:
    model = audit.derived_metadata.get("commander_identity_model") or {}
    if not model.get("requires_first_class_persistence"):
        return False
    metadata_model = audit.metadata.get("commander_identity_model")
    return metadata_model != model


def planned_metadata_patch(audit: Any) -> dict[str, Any]:
    model = audit.derived_metadata["commander_identity_model"]
    return {
        "commander_identity_model": model,
        "combined_commander_color_identity": model.get("combined_color_identity"),
        "partner_identity_candidates": audit.derived_metadata.get(
            "partner_identity_candidates",
            [],
        ),
        "partner_identity_backfill": {
            "source": SOURCE,
            "mode": "dry_run_plan_only",
            "requires_explicit_postgresql_mutation_approval": True,
            "source_ref": audit.source_ref,
        },
    }


def merge_metadata(metadata: dict[str, Any], patch: dict[str, Any]) -> dict[str, Any]:
    merged = deepcopy(metadata)
    merged.update(deepcopy(patch))
    return merged


def source_ref_clause(source_ref: str) -> str:
    escaped = source_ref.replace("'", "''")
    return f"source_ref = '{escaped}'"


def update_sql(row_id: str, source_ref: str, new_metadata: dict[str, Any]) -> str:
    return (
        "UPDATE commander_learned_decks\n"
        f"SET metadata = {sql_literal(new_metadata)}\n"
        f"WHERE id = '{row_id}'::uuid AND {source_ref_clause(source_ref)};"
    )


def rollback_sql(row_id: str, source_ref: str, original_metadata: dict[str, Any]) -> str:
    return (
        "UPDATE commander_learned_decks\n"
        f"SET metadata = {sql_literal(original_metadata)}\n"
        f"WHERE id = '{row_id}'::uuid AND {source_ref_clause(source_ref)};"
    )


def build_plan(audits: list[Any]) -> dict[str, Any]:
    rows: list[dict[str, Any]] = []
    for learned_audit in audits:
        if not should_plan_backfill(learned_audit):
            continue
        patch = planned_metadata_patch(learned_audit)
        new_metadata = merge_metadata(learned_audit.metadata, patch)
        model = patch["commander_identity_model"]
        rows.append(
            {
                "row_id": learned_audit.row_id,
                "source_ref": learned_audit.source_ref,
                "source_system": learned_audit.source_system,
                "commander_name": learned_audit.commander_name,
                "deck_name": learned_audit.deck_name,
                "inference_source": model.get("source"),
                "status": model.get("status"),
                "base_color_identity": model.get("base_color_identity"),
                "combined_color_identity": model.get("combined_color_identity"),
                "identity_components": model.get("identity_components", []),
                "metadata_patch": patch,
                "previous_metadata_keys": sorted(learned_audit.metadata.keys()),
                "planned_sql": update_sql(
                    learned_audit.row_id,
                    learned_audit.source_ref,
                    new_metadata,
                ),
                "rollback_sql": rollback_sql(
                    learned_audit.row_id,
                    learned_audit.source_ref,
                    learned_audit.metadata,
                ),
            }
        )

    return {
        "status": "PASS",
        "mode": "dry_run",
        "db_mutations": False,
        "apply_supported": False,
        "apply_requires_explicit_approval": True,
        "source": SOURCE,
        "planned_row_count": len(rows),
        "planned_rows": rows,
        "rollback_scope": {
            "table": "commander_learned_decks",
            "column": "metadata",
            "row_ids": [row["row_id"] for row in rows],
        },
    }


def summarize_plan(payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "status": payload["status"],
        "mode": payload["mode"],
        "db_mutations": payload["db_mutations"],
        "apply_supported": payload["apply_supported"],
        "apply_requires_explicit_approval": payload[
            "apply_requires_explicit_approval"
        ],
        "source": payload["source"],
        "planned_row_count": payload["planned_row_count"],
        "planned_rows": [
            {
                "row_id": row["row_id"],
                "source_ref": row["source_ref"],
                "commander_name": row["commander_name"],
                "deck_name": row["deck_name"],
                "inference_source": row["inference_source"],
                "combined_color_identity": row["combined_color_identity"],
                "identity_components": row["identity_components"],
            }
            for row in payload["planned_rows"]
        ],
    }


def load_current_audits() -> list[Any]:
    conn = audit_module.connect_pg()
    try:
        conn.set_session(readonly=True, autocommit=False)
        lookup = audit_module.load_card_lookup(conn)
        return audit_module.load_active_learned_decks(conn, lookup)
    finally:
        try:
            conn.rollback()
        finally:
            conn.close()


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Plan learned-deck partner/background identity metadata backfill "
            "without mutating PostgreSQL."
        )
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Accepted for clarity; this script never mutates PostgreSQL.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Optional path for writing the dry-run JSON artifact.",
    )
    parser.add_argument(
        "--summary-only",
        action="store_true",
        help="Print a compact summary while still writing the full --output artifact.",
    )
    args = parser.parse_args()

    payload = build_plan(load_current_audits())
    text = json.dumps(payload, indent=2, sort_keys=True)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text + "\n")
    printed_payload = summarize_plan(payload) if args.summary_only else payload
    print(json.dumps(printed_payload, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
