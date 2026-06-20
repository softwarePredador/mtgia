#!/usr/bin/env python3
"""Audit decision_trace decision types against explicit ownership contracts."""

from __future__ import annotations

import argparse
import ast
import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DEFAULT_ENGINE_SOURCE = SCRIPT_DIR / "battle_analyst_v9.py"
DEFAULT_LATEST_RUN = Path(
    "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/"
    "battle-strategy-audit/latest"
)

GENERIC_REQUIRED_FIELDS = {
    "available_options",
    "chosen_option",
    "confidence",
    "decision_id",
    "decision_type",
    "expected_benefit_score",
    "phase",
    "player",
    "rule_source",
    "rule_status",
    "score_components",
    "turn",
}

STRATEGY_REQUIRED_FIELDS = {
    "alternatives_considered",
    "heuristic_version",
    "resource_delta",
    "risk_flags",
    "strategic_principle",
}

CONTRACTS: dict[str, dict[str, Any]] = {
    "activated_sacrifice_damage": {
        "owner": "activated-sacrifice-damage-field-contract",
        "strategy_auditor": "generic_strategy_fields_only",
        "research_category": None,
        "specific_status": "accepted_field_contract_waiver",
        "waiver_reason": (
            "Deterministic activated damage outlet; strategy trust is bounded by "
            "target/damage/creature-options trace fields until a dedicated "
            "research category is justified."
        ),
        "required_score_keys": {"damage", "target", "creature_options"},
        "fixture_gate": "field_contract_required_before_observed_learning",
    },
    "attack_trigger_artifact_tutor": {
        "owner": "attack-trigger-artifact-tutor-field-contract",
        "strategy_auditor": "generic_strategy_fields_only",
        "research_category": None,
        "specific_status": "accepted_field_contract_waiver",
        "waiver_reason": (
            "Triggered artifact tutor is narrow and non-optional quality is "
            "captured by treasures/candidate-count plus chosen tutor option."
        ),
        "required_score_keys": {"treasures_created", "candidate_count"},
        "fixture_gate": "field_contract_required_before_observed_learning",
    },
    "board_wipe": {
        "owner": "battle_decision_strategy_auditor.py",
        "strategy_auditor": "generic_strategy_fields_plus_specialized_rules",
        "research_category": "board_wipe_wheel",
        "specific_status": "specific",
        "fixture_gate": "test_battle_decision_strategy_auditor.py",
    },
    "cast_spell": {
        "owner": "battle_decision_strategy_auditor.py",
        "strategy_auditor": "generic_strategy_fields_plus_specialized_rules",
        "research_category": "cast_spell",
        "specific_status": "specific",
        "fixture_gate": "test_battle_decision_strategy_auditor.py",
    },
    "combat_attack": {
        "owner": "battle_decision_research_review.py",
        "strategy_auditor": "generic_strategy_fields_only",
        "research_category": "combat_attack",
        "specific_status": "specific_via_research",
        "fixture_gate": "test_battle_decision_research_review.py",
    },
    "lorehold_upkeep_rummage": {
        "owner": "lorehold-upkeep-rummage-field-contract",
        "strategy_auditor": "generic_strategy_fields_only",
        "research_category": None,
        "specific_status": "accepted_field_contract_waiver",
        "waiver_reason": (
            "Lorehold upkeep rummage is commander-engine bookkeeping; the "
            "trace must expose discard destination and drawn card, while "
            "broader strategic quality remains covered by parent engine choices."
        ),
        "required_score_keys": {"discard_destination", "drawn_card"},
        "fixture_gate": "field_contract_required_before_observed_learning",
    },
    "mulligan_decision": {
        "owner": "battle_decision_strategy_auditor.py",
        "strategy_auditor": "generic_strategy_fields_plus_specialized_rules",
        "research_category": "mulligan",
        "specific_status": "specific",
        "fixture_gate": "test_battle_decision_strategy_auditor.py",
    },
    "pass_no_action": {
        "owner": "battle_decision_strategy_auditor.py",
        "strategy_auditor": "generic_strategy_fields_plus_specialized_rules",
        "research_category": "pass_no_action",
        "specific_status": "specific",
        "fixture_gate": "test_battle_decision_strategy_auditor.py",
    },
    "response": {
        "owner": "battle_decision_research_review.py",
        "strategy_auditor": "generic_strategy_fields_only",
        "research_category": "response",
        "specific_status": "specific_via_research",
        "fixture_gate": "test_battle_decision_research_review.py",
    },
    "saga_chapter_resolution": {
        "owner": "saga-chapter-resolution-field-contract",
        "strategy_auditor": "generic_strategy_fields_only",
        "research_category": None,
        "specific_status": "accepted_field_contract_waiver",
        "waiver_reason": (
            "Saga chapter resolution is deterministic trigger resolution; the "
            "specific contract is chapter, candidate count, and selected reason."
        ),
        "required_score_keys": {"chapter", "candidate_count", "selected_reason"},
        "fixture_gate": "field_contract_required_before_observed_learning",
    },
    "tutor": {
        "owner": "battle_decision_strategy_auditor.py",
        "strategy_auditor": "generic_strategy_fields_plus_specialized_rules",
        "research_category": "tutor",
        "specific_status": "specific",
        "fixture_gate": "test_battle_decision_strategy_auditor.py",
    },
    "utility_artifact_activation": {
        "owner": "utility-artifact-activation-field-contract",
        "strategy_auditor": "generic_strategy_fields_only",
        "research_category": None,
        "specific_status": "accepted_field_contract_waiver",
        "waiver_reason": (
            "Utility artifact activations are narrow deterministic resource "
            "conversions; each observed row must expose an activation-cost or "
            "activation-family score key before it can be used as trace evidence."
        ),
        "required_score_key_any_group": [
            {"activation_cost_generic"},
            {"activation_cost"},
            {"cards_exchanged"},
            {"peek_top_count"},
            {"found_land"},
            {"produced_mana"},
        ],
        "fixture_gate": "field_contract_required_before_observed_learning",
    },
    "utility_land_activation": {
        "owner": "utility-land-activation-field-contract",
        "strategy_auditor": "generic_strategy_fields_only",
        "research_category": None,
        "specific_status": "accepted_field_contract_waiver",
        "waiver_reason": (
            "Utility land activations are deterministic resource conversions; "
            "each row must expose an activation-family score key."
        ),
        "required_score_key_any_group": [
            {"chosen_unlock_reason"},
            {"chapter"},
            {"hand_low_bonus"},
            {"selected_reason"},
            {"artifact_count_after"},
            {"candidate_count"},
            {"artifact_threshold_bonus"},
        ],
        "fixture_gate": "field_contract_required_before_observed_learning",
    },
    "wheel": {
        "owner": "battle_decision_strategy_auditor.py",
        "strategy_auditor": "generic_strategy_fields_plus_specialized_rules",
        "research_category": "board_wipe_wheel",
        "specific_status": "specific",
        "fixture_gate": "test_battle_decision_strategy_auditor.py",
    },
    "worldfire_reset": {
        "owner": "battle_decision_strategy_auditor.py",
        "strategy_auditor": "generic_strategy_fields_plus_specialized_rules",
        "research_category": None,
        "specific_status": "specific",
        "fixture_gate": "test_battle_decision_strategy_auditor.py",
    },
}


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--engine-source", type=Path, default=DEFAULT_ENGINE_SOURCE)
    parser.add_argument("--input-dir", type=Path, default=DEFAULT_LATEST_RUN)
    parser.add_argument("--decision-trace", type=Path, action="append", default=[])
    parser.add_argument("--output", type=Path)
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--fail-on-gap", action="store_true")
    return parser.parse_args(argv)


def static_decision_types(engine_source: Path) -> set[str]:
    tree = ast.parse(engine_source.read_text(encoding="utf-8"))
    decision_types: set[str] = set()
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        func = node.func
        if not isinstance(func, ast.Name) or func.id != "emit_decision_trace":
            continue
        for keyword in node.keywords:
            if keyword.arg == "decision_type" and isinstance(keyword.value, ast.Constant):
                if isinstance(keyword.value.value, str):
                    decision_types.add(keyword.value.value)
    return decision_types


def decision_trace_paths(input_dir: Path, explicit_paths: list[Path]) -> list[Path]:
    if explicit_paths:
        return sorted(path for path in explicit_paths if path.exists())
    if input_dir.is_file():
        return [input_dir]
    if not input_dir.exists():
        return []
    direct = sorted(input_dir.glob("seed_*/replay.decision_trace.jsonl"))
    nested = sorted(input_dir.glob("*/seed_*/replay.decision_trace.jsonl"))
    return sorted({*direct, *nested})


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            text = line.strip()
            if not text:
                continue
            row = json.loads(text)
            row.setdefault("_source_path", str(path))
            row.setdefault("_source_line", line_number)
            rows.append(row)
    return rows


def has_specific_contract(decision_type: str) -> bool:
    contract = CONTRACTS.get(decision_type)
    return bool(contract and contract.get("specific_status") != "generic_only_gap")


def missing_contract_fields(decision: dict[str, Any], contract: dict[str, Any]) -> list[str]:
    missing: list[str] = []
    for field in sorted(GENERIC_REQUIRED_FIELDS | STRATEGY_REQUIRED_FIELDS):
        if field not in decision:
            missing.append(field)

    score = decision.get("score_components")
    if not isinstance(score, dict):
        return missing + ["score_components:object"]

    for key in sorted(contract.get("required_score_keys") or []):
        if key not in score:
            missing.append(f"score_components.{key}")

    any_groups = contract.get("required_score_key_any_group") or []
    if any_groups and not any(all(key in score for key in group) for group in any_groups):
        formatted = [
            "+".join(sorted(group))
            for group in any_groups
        ]
        missing.append("score_components:any_of(" + "|".join(formatted) + ")")

    return missing


def build_audit(
    *,
    input_dir: Path = DEFAULT_LATEST_RUN,
    decision_traces: list[Path] | None = None,
    engine_source: Path = DEFAULT_ENGINE_SOURCE,
) -> dict[str, Any]:
    static_types = static_decision_types(engine_source)
    paths = decision_trace_paths(input_dir, list(decision_traces or []))
    decisions: list[dict[str, Any]] = []
    for path in paths:
        decisions.extend(load_jsonl(path))

    counts: Counter[str] = Counter()
    score_keys_by_type: dict[str, Counter[str]] = defaultdict(Counter)
    examples: dict[str, dict[str, Any]] = {}
    findings: list[dict[str, Any]] = []

    for decision in decisions:
        decision_type = str(decision.get("decision_type") or "unknown")
        counts[decision_type] += 1
        score = decision.get("score_components") or {}
        if isinstance(score, dict):
            score_keys_by_type[decision_type].update(str(key) for key in score)
        examples.setdefault(
            decision_type,
            {
                "decision_id": decision.get("decision_id"),
                "player": decision.get("player"),
                "turn": decision.get("turn"),
                "phase": decision.get("phase"),
                "reason": decision.get("reason"),
                "source_path": decision.get("_source_path"),
                "source_line": decision.get("_source_line"),
            },
        )

        contract = CONTRACTS.get(decision_type)
        if not contract:
            findings.append(
                {
                    "severity": "medium",
                    "code": "decision_type_without_contract",
                    "decision_type": decision_type,
                    "decision_id": decision.get("decision_id"),
                    "detail": "Observed decision type has no taxonomy contract.",
                }
            )
            continue

        missing = missing_contract_fields(decision, contract)
        if missing:
            findings.append(
                {
                    "severity": "medium",
                    "code": "decision_contract_missing_fields",
                    "decision_type": decision_type,
                    "decision_id": decision.get("decision_id"),
                    "missing": missing,
                    "detail": "Observed decision is missing generic, strategy, or type-specific contract fields.",
                }
            )

    all_types = sorted(static_types | set(CONTRACTS) | set(counts))
    static_without_specific_contract = [
        decision_type for decision_type in sorted(static_types) if not has_specific_contract(decision_type)
    ]
    observed_without_specific_contract = [
        decision_type for decision_type in sorted(counts) if not has_specific_contract(decision_type)
    ]
    static_without_contract = [
        decision_type for decision_type in sorted(static_types) if decision_type not in CONTRACTS
    ]
    observed_without_contract = [
        decision_type for decision_type in sorted(counts) if decision_type not in CONTRACTS
    ]

    items = []
    for decision_type in all_types:
        contract = CONTRACTS.get(decision_type, {})
        items.append(
            {
                "decision_type": decision_type,
                "latest_count": int(counts.get(decision_type, 0)),
                "static_engine_type": decision_type in static_types,
                "observed": bool(counts.get(decision_type, 0)),
                "owner": contract.get("owner"),
                "strategy_auditor": contract.get("strategy_auditor"),
                "research_category": contract.get("research_category"),
                "specific_status": contract.get("specific_status") or "missing_contract",
                "waiver_reason": contract.get("waiver_reason"),
                "fixture_gate": contract.get("fixture_gate"),
                "score_keys_observed": sorted(score_keys_by_type[decision_type]),
                "example": examples.get(decision_type),
            }
        )

    status = (
        "decision_trace_taxonomy_ready"
        if not static_without_specific_contract
        and not observed_without_specific_contract
        and not findings
        else "review_required"
    )
    summary = {
        "generated_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "engine_source": str(engine_source),
        "input_dir": str(input_dir),
        "decision_trace_paths": [str(path) for path in paths],
        "status": status,
        "decision_trace_rows": len(decisions),
        "decision_trace_kinds_total": len(static_types),
        "decision_trace_kinds_observed": len(counts),
        "decision_trace_kinds_uncovered": len(static_types - set(counts)),
        "decision_trace_missing_required_fields": len(
            [finding for finding in findings if finding["code"] == "decision_contract_missing_fields"]
        ),
        "decision_trace_contract_findings": len(findings),
        "decision_trace_static_without_contract": len(static_without_contract),
        "decision_trace_observed_without_contract": len(observed_without_contract),
        "decision_trace_kinds_without_specific_contract": len(static_without_specific_contract),
        "decision_trace_observed_without_specific_contract": len(observed_without_specific_contract),
        "accepted_waivers": sorted(
            decision_type
            for decision_type, contract in CONTRACTS.items()
            if str(contract.get("specific_status") or "").startswith("accepted_")
        ),
        "observed_counts": dict(sorted(counts.items())),
        "static_uncovered_types": sorted(static_types - set(counts)),
        "static_without_contract_types": static_without_contract,
        "observed_without_contract_types": observed_without_contract,
        "static_without_specific_contract_types": static_without_specific_contract,
        "observed_without_specific_contract_types": observed_without_specific_contract,
    }
    return {
        "version": 1,
        "summary": summary,
        "items": items,
        "findings": findings,
    }


def render_markdown(audit: dict[str, Any]) -> str:
    summary = audit["summary"]
    lines = [
        "# Battle Decision Trace Taxonomy Audit",
        "",
        f"- Generated at UTC: `{summary['generated_at_utc']}`",
        f"- Status: `{summary['status']}`",
        f"- Engine source: `{summary['engine_source']}`",
        f"- Decision trace paths: `{json.dumps(summary['decision_trace_paths'])}`",
        f"- Decision rows: `{summary['decision_trace_rows']}`",
        f"- Static decision types: `{summary['decision_trace_kinds_total']}`",
        f"- Observed decision types: `{summary['decision_trace_kinds_observed']}`",
        f"- Uncovered static decision types: `{summary['decision_trace_kinds_uncovered']}`",
        f"- Contract findings: `{summary['decision_trace_contract_findings']}`",
        f"- Missing required fields: `{summary['decision_trace_missing_required_fields']}`",
        f"- Static without contract: `{summary['decision_trace_static_without_contract']}`",
        f"- Observed without contract: `{summary['decision_trace_observed_without_contract']}`",
        f"- Static without specific contract: `{summary['decision_trace_kinds_without_specific_contract']}`",
        f"- Observed without specific contract: `{summary['decision_trace_observed_without_specific_contract']}`",
        f"- Accepted waivers: `{json.dumps(summary['accepted_waivers'])}`",
        "",
        "## Ownership Matrix",
        "",
        "| Decision type | Latest count | Owner | Strategy auditor | Research category | Specific status | Fixture/gate | Score keys observed |",
        "| --- | ---: | --- | --- | --- | --- | --- | --- |",
    ]
    for item in audit["items"]:
        lines.append(
            "| `{decision_type}` | `{latest_count}` | `{owner}` | `{strategy_auditor}` | `{research_category}` | `{specific_status}` | `{fixture_gate}` | `{score_keys}` |".format(
                decision_type=item["decision_type"],
                latest_count=item["latest_count"],
                owner=item.get("owner") or "-",
                strategy_auditor=item.get("strategy_auditor") or "-",
                research_category=item.get("research_category") or "-",
                specific_status=item.get("specific_status") or "-",
                fixture_gate=item.get("fixture_gate") or "-",
                score_keys=", ".join(item.get("score_keys_observed") or []) or "-",
            )
        )

    waivers = [item for item in audit["items"] if item.get("waiver_reason")]
    if waivers:
        lines.extend(["", "## Accepted Waivers", ""])
        for item in waivers:
            lines.append(
                f"- `{item['decision_type']}`: {item['waiver_reason']}"
            )

    if audit["findings"]:
        lines.extend(["", "## Findings", ""])
        for finding in audit["findings"]:
            detail = finding.get("detail") or finding.get("code")
            missing = finding.get("missing")
            suffix = f" Missing: `{missing}`" if missing else ""
            lines.append(
                f"- `{finding['severity']}` `{finding['code']}` `{finding.get('decision_type')}`: {detail}.{suffix}"
            )
    else:
        lines.extend(["", "## Findings", "", "- No taxonomy contract findings."])

    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    audit = build_audit(
        input_dir=args.input_dir,
        decision_traces=args.decision_trace,
        engine_source=args.engine_source,
    )
    markdown = render_markdown(audit)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(markdown, encoding="utf-8")
        print(f"Markdown report: {args.output}")
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(audit, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        print(f"JSON report: {args.json_output}")
    if not args.output and not args.json_output:
        print(markdown)
    if args.fail_on_gap and audit["summary"]["status"] != "decision_trace_taxonomy_ready":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
