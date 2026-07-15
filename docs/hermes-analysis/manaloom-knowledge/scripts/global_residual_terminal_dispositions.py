#!/usr/bin/env python3
"""Assign auditable terminal dispositions to non-actionable battle residuals."""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ALLOWED_SCOPES = {
    "auxiliary_game_object",
    "nonstandard_or_playtest_ruleset",
    "physical_or_external_interaction",
    "scenario_or_challenge_deck_ruleset",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--residual", type=Path, required=True)
    parser.add_argument("--out-prefix", type=Path, required=True)
    return parser.parse_args()


def _auxiliary_reason(row: dict[str, Any]) -> tuple[str, str]:
    type_line = str(row.get("type_line") or "").casefold()
    if "stickers" in type_line:
        return "supplemental_sticker_sheet", "dedicated_sticker_sheet_catalog"
    if "attraction" in type_line:
        return "supplemental_attraction_deck_object", "dedicated_attraction_deck_runtime"
    if "dungeon" in type_line:
        return "supplemental_dungeon_object", "dedicated_dungeon_runtime"
    if "plane" in type_line or "phenomenon" in type_line:
        return "supplemental_planar_deck_object", "dedicated_planechase_runtime"
    if "scheme" in type_line:
        return "supplemental_scheme_deck_object", "dedicated_archenemy_runtime"
    if "vanguard" in type_line:
        return "supplemental_vanguard_object", "dedicated_vanguard_runtime"
    if "emblem" in type_line:
        return "derived_emblem_object", "created_by_supported_source_effect"
    if "token" in type_line or str(row.get("layout") or "").casefold() == "token":
        return "derived_token_object", "created_by_supported_source_effect"
    return "supplemental_non_deck_game_object", "dedicated_supplemental_object_runtime"


def disposition_for(row: dict[str, Any]) -> dict[str, Any]:
    scope = str(row.get("residual_execution_scope") or "")
    if scope == "auxiliary_game_object":
        reason_code, next_gate = _auxiliary_reason(row)
        disposition = "excluded_from_normal_deck_card_execution"
    elif scope == "nonstandard_or_playtest_ruleset":
        reason_code = "nonstandard_funny_acorn_or_playtest_product"
        next_gate = "opt_in_nonstandard_ruleset_with_dedicated_engine"
        disposition = "excluded_from_standard_and_commander_execution"
    elif scope == "physical_or_external_interaction":
        reason_code = "requires_physical_person_product_or_external_input"
        next_gate = "non_digital_interaction_contract"
        disposition = "excluded_from_deterministic_digital_battle"
    elif scope == "scenario_or_challenge_deck_ruleset":
        reason_code = "scenario_challenge_or_hero_deck_object"
        next_gate = "dedicated_scenario_engine"
        disposition = "excluded_from_normal_two_deck_battle"
    else:
        raise ValueError(
            f"actionable or unknown residual cannot receive terminal exclusion: "
            f"{row.get('name')!r} scope={scope!r}"
        )
    return {
        "key": row.get("key"),
        "card_id": row.get("card_id"),
        "oracle_id": row.get("oracle_id"),
        "name": row.get("name"),
        "execution_scope": scope,
        "disposition": disposition,
        "reason_code": reason_code,
        "terminal": True,
        "promotion_allowed": False,
        "next_gate": next_gate,
        "source_evidence": {
            "set_code": row.get("set_code"),
            "set_type": row.get("set_type"),
            "layout": row.get("layout"),
            "type_line": row.get("type_line"),
            "commander_legality": row.get("commander_legality"),
            "oracle_text_present": bool(str(row.get("oracle_text") or "").strip()),
        },
    }


def build(payload: dict[str, Any], input_bytes: bytes) -> dict[str, Any]:
    rows = payload.get("residual")
    if not isinstance(rows, list):
        raise ValueError("residual payload must contain a residual array")
    dispositions = [disposition_for(row) for row in rows if isinstance(row, dict)]
    if len(dispositions) != len(rows):
        raise ValueError("every residual row must be an object and receive one disposition")
    keys = [str(row.get("key") or "") for row in dispositions]
    if not all(keys) or len(keys) != len(set(keys)):
        raise ValueError("terminal disposition keys must be present and unique")
    scope_counts = Counter(row["execution_scope"] for row in dispositions)
    reason_counts = Counter(row["reason_code"] for row in dispositions)
    identity_keys = {
        str(row.get("oracle_id") or row.get("card_id") or row.get("key"))
        for row in dispositions
    }
    summary = {
        "input_residual_rows": len(rows),
        "input_residual_identities": len(identity_keys),
        "terminal_dispositions": len(dispositions),
        "actionable_residual": 0,
        "unknown_dispositions": 0,
        "promotion_allowed": 0,
        "scope_counts": dict(sorted(scope_counts.items())),
        "reason_counts": dict(sorted(reason_counts.items())),
    }
    if set(scope_counts) - ALLOWED_SCOPES:
        raise ValueError(f"unexpected terminal scopes: {sorted(set(scope_counts) - ALLOWED_SCOPES)}")
    return {
        "schema_version": "global_residual_terminal_dispositions_v1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "status": "pass",
        "input_schema_version": payload.get("schema_version"),
        "input_sha256": hashlib.sha256(input_bytes).hexdigest(),
        "contract": {
            "normal_battle_actionable_scope_must_be_zero": True,
            "one_terminal_disposition_per_residual_row": True,
            "exclusions_never_create_executable_card_rules": True,
            "promotion_requires_the_named_next_gate": True,
        },
        "summary": summary,
        "dispositions": dispositions,
    }


def markdown(payload: dict[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Residual Terminal Dispositions",
        "",
        f"Status: `{payload['status']}`.",
        "",
        f"Input SHA-256: `{payload['input_sha256']}`.",
        "",
        "| Gate | Count |",
        "| --- | ---: |",
        f"| Residual rows | {summary['input_residual_rows']} |",
        f"| Residual identities | {summary['input_residual_identities']} |",
        f"| Terminal dispositions | {summary['terminal_dispositions']} |",
        f"| Actionable residual | {summary['actionable_residual']} |",
        f"| Unknown dispositions | {summary['unknown_dispositions']} |",
        f"| Promotion allowed | {summary['promotion_allowed']} |",
        "",
        "| Execution scope | Rows |",
        "| --- | ---: |",
    ]
    lines.extend(
        f"| `{scope}` | {count} |"
        for scope, count in summary["scope_counts"].items()
    )
    lines.extend(
        [
            "",
            "Every row retains its identity, product evidence, reason code, and explicit",
            "next gate in the JSON ledger. These exclusions do not create PostgreSQL",
            "battle rules and cannot be promoted by coverage alone.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    input_bytes = args.residual.read_bytes()
    payload = json.loads(input_bytes)
    output = build(payload, input_bytes)
    json_path = args.out_prefix.with_suffix(".json")
    markdown_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(
        json.dumps(output, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    markdown_path.write_text(markdown(output), encoding="utf-8")
    print(json.dumps({"status": "pass", "summary": output["summary"]}, ensure_ascii=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
