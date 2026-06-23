#!/usr/bin/env python3
"""Batch validity gate for using local XMage card sources as ManaLoom inputs.

The audit is read-only. It does not promote rules, mutate PostgreSQL, alter deck
lists, or trust XMage without ManaLoom tests/review. Its job is to separate
exact local XMage sources that are usable for structured pull from sources that
still need manual mapping or are missing from the local checkout.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DEFAULT_REPORT_DIR = Path(__file__).resolve().parent.parent.parent / "master_optimizer_reports"
SEVERITIES = {"critical", "high", "medium"}
KNOWN_CARD_TYPES = {
    "ARTIFACT",
    "BATTLE",
    "CREATURE",
    "ENCHANTMENT",
    "INSTANT",
    "LAND",
    "PLANESWALKER",
    "SORCERY",
}
MANUAL_EFFECT = "external_reference_required_manual_model"


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def normalize_name(value: str) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip()).lower()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def high_medium_cards(coherence_report: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        card
        for card in coherence_report.get("cards", [])
        if isinstance(card, dict) and card.get("severity") in SEVERITIES
    ]


def by_card_name(report: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        normalize_name(str(card.get("card_name") or "")): card
        for card in report.get("cards", [])
        if isinstance(card, dict) and card.get("card_name")
    }


def expected_types_from_type_line(type_line: str | None) -> list[str]:
    if not type_line:
        return []
    values: set[str] = set()
    for face in re.split(r"\s*//\s*", str(type_line)):
        before_subtypes = re.split(r"\s+[—-]\s+", face, maxsplit=1)[0]
        for token in re.findall(r"[A-Za-z]+", before_subtypes):
            upper = token.upper()
            if upper in KNOWN_CARD_TYPES:
                values.add(upper)
    return sorted(values)


def primary_effect(xmage_card: dict[str, Any]) -> dict[str, Any]:
    return (
        xmage_card.get("candidate_effect_hints", {})
        .get("primary_candidate", {})
        .get("effect_json", {})
        or {}
    )


def source_scryfall(external_card: dict[str, Any] | None) -> dict[str, Any]:
    if not external_card:
        return {}
    return external_card.get("external_references", {}).get("scryfall", {}) or {}


def type_match(expected_types: list[str], xmage_types: list[str]) -> bool | None:
    if not expected_types:
        return None
    return set(expected_types).issubset(set(xmage_types))


def mana_match(expected_mana_cost: str | None, xmage_mana_cost: str | None) -> bool | None:
    if expected_mana_cost in {None, ""}:
        return None
    return expected_mana_cost == xmage_mana_cost


def valid_test_scenarios(xmage_card: dict[str, Any]) -> list[dict[str, Any]]:
    scenarios = xmage_card.get("suggested_test_scenarios")
    if not isinstance(scenarios, list):
        return []
    valid: list[dict[str, Any]] = []
    for scenario in scenarios:
        if not isinstance(scenario, dict):
            continue
        if not scenario.get("id") or not scenario.get("title"):
            continue
        if not scenario.get("setup") or not scenario.get("actions") or not scenario.get("assertions"):
            continue
        valid.append(scenario)
    return valid


def classify_card(
    coherence_card: dict[str, Any],
    *,
    xmage_card: dict[str, Any] | None,
    external_card: dict[str, Any] | None,
) -> dict[str, Any]:
    name = str(coherence_card.get("card_name") or "")
    scryfall = source_scryfall(external_card)
    expected_type_line = scryfall.get("type_line") or coherence_card.get("type_line")
    expected_types = expected_types_from_type_line(expected_type_line)

    if not xmage_card or xmage_card.get("status") != "found":
        return {
            "card_name": name,
            "severity": coherence_card.get("severity"),
            "coherence_findings": [finding.get("code") for finding in coherence_card.get("findings", [])],
            "status": "blocked_missing_xmage_class",
            "valid_xmage_source": False,
            "ready_for_structured_pull": False,
            "reason": "No exact local XMage implementation class was resolved for this card name.",
            "candidate_class_names": (xmage_card or {}).get("candidate_class_names"),
            "nearby_xmage_class_candidates": (xmage_card or {}).get("nearby_xmage_class_candidates"),
            "expected": {
                "mana_cost": scryfall.get("mana_cost"),
                "type_line": expected_type_line,
                "types": expected_types,
            },
            "xmage": {"status": (xmage_card or {}).get("status", "not_found")},
        }

    metadata = xmage_card.get("constructor_metadata") or {}
    xmage_types = metadata.get("card_types") or []
    expected_mana = scryfall.get("mana_cost")
    found_mana = metadata.get("mana_cost")
    type_ok = type_match(expected_types, xmage_types)
    mana_ok = mana_match(expected_mana, found_mana)
    effect_json = primary_effect(xmage_card)
    effect = effect_json.get("effect")
    has_structured_effect = bool(effect and effect != MANUAL_EFFECT)
    metadata_ok = (type_ok is not False) and (mana_ok is not False)
    test_scenarios = valid_test_scenarios(xmage_card)
    has_test_scenarios = bool(test_scenarios)

    if not metadata_ok:
        status = "xmage_source_found_metadata_mismatch"
        valid_source = False
        ready = False
        reason = "Exact XMage class was found, but constructor metadata does not match Scryfall/deck metadata."
    elif not has_structured_effect:
        status = "xmage_source_valid_mapper_required"
        valid_source = True
        ready = False
        reason = "Exact XMage class and metadata are compatible, but the ManaLoom mapper still has no specific structured effect."
    elif not has_test_scenarios:
        status = "xmage_source_valid_test_scenarios_required"
        valid_source = True
        ready = False
        reason = "Exact XMage class, metadata, and effect are compatible, but no usable ManaLoom focused test scenario was attached."
    else:
        status = "ready_for_structured_xmage_pull_review_required"
        valid_source = True
        ready = True
        reason = "Exact XMage class, compatible metadata, a specific structured effect candidate, and focused test scenarios were found; still requires implemented ManaLoom tests/review before PG promotion."

    return {
        "card_name": name,
        "severity": coherence_card.get("severity"),
        "coherence_findings": [finding.get("code") for finding in coherence_card.get("findings", [])],
        "oracle_hash": coherence_card.get("oracle_hash"),
        "status": status,
        "valid_xmage_source": valid_source,
        "ready_for_structured_pull": ready,
        "reason": reason,
        "expected": {
            "mana_cost": expected_mana,
            "type_line": expected_type_line,
            "types": expected_types,
        },
        "xmage": {
            "status": xmage_card.get("status"),
            "class_name": xmage_card.get("xmage_class_name"),
            "path": xmage_card.get("xmage_path"),
            "resolution": xmage_card.get("resolution"),
            "mana_cost": found_mana,
            "types": xmage_types,
            "ability_classes": xmage_card.get("ability_classes") or [],
            "effect_classes": xmage_card.get("effect_classes") or [],
            "cost_classes": xmage_card.get("cost_classes") or [],
            "subtypes": metadata.get("subtypes") or [],
            "signals": xmage_card.get("signals") or [],
            "primary_effect": effect_json,
            "suggested_test_scenarios": test_scenarios,
        },
        "checks": {
            "type_match": type_ok,
            "mana_cost_match": mana_ok,
            "specific_effect_candidate": has_structured_effect,
            "focused_test_scenarios_present": has_test_scenarios,
            "focused_test_scenario_count": len(test_scenarios),
        },
    }


def build_audit(
    *,
    coherence_report: dict[str, Any],
    xmage_index: dict[str, Any],
    external_harvest: dict[str, Any] | None = None,
) -> dict[str, Any]:
    xmage_by_name = by_card_name(xmage_index)
    external_by_name = by_card_name(external_harvest or {"cards": []})
    cards = [
        classify_card(
            card,
            xmage_card=xmage_by_name.get(normalize_name(str(card.get("card_name") or ""))),
            external_card=external_by_name.get(normalize_name(str(card.get("card_name") or ""))),
        )
        for card in high_medium_cards(coherence_report)
    ]
    statuses = Counter(card["status"] for card in cards)
    severities = Counter(card["severity"] for card in cards)
    return {
        "generated_at": utc_now(),
        "status": "ready",
        "mutations_performed": [],
        "source": {
            "deck_id": coherence_report.get("deck_id"),
            "coherence_generated_at": coherence_report.get("generated_at"),
            "coherence_severity_counts": coherence_report.get("severity_counts"),
            "xmage_root": xmage_index.get("xmage_root"),
            "xmage_index_summary": xmage_index.get("summary"),
            "external_harvest_status": (external_harvest or {}).get("status"),
        },
        "summary": {
            "audited_card_count": len(cards),
            "severity_counts": dict(sorted(severities.items())),
            "status_counts": dict(sorted(statuses.items())),
            "exact_xmage_found_count": sum(1 for card in cards if card["xmage"].get("status") == "found"),
            "missing_xmage_class_count": statuses.get("blocked_missing_xmage_class", 0),
            "ready_for_structured_pull_count": sum(1 for card in cards if card["ready_for_structured_pull"]),
            "focused_test_scenario_ready_count": sum(
                1 for card in cards if (card.get("checks") or {}).get("focused_test_scenarios_present")
            ),
            "valid_xmage_source_count": sum(1 for card in cards if card["valid_xmage_source"]),
        },
        "cards": cards,
    }


def markdown_report(report: dict[str, Any]) -> str:
    lines = [
        "# XMage Batch Validity Audit",
        "",
        f"Generated at: `{report['generated_at']}`",
        "",
        "Read-only artifact. `mutations_performed=[]`.",
        "",
        f"- Summary: `{json.dumps(report.get('summary'), sort_keys=True)}`",
        "",
        "| Card | Severity | Status | XMage class | Mana | Types | Primary effect | Test scenarios |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for card in report.get("cards", []):
        xmage = card.get("xmage") or {}
        expected = card.get("expected") or {}
        checks = card.get("checks") or {}
        mana = f"{xmage.get('mana_cost')} / expected {expected.get('mana_cost')} / match {checks.get('mana_cost_match')}"
        types = f"{','.join(xmage.get('types') or [])} / expected {','.join(expected.get('types') or [])} / match {checks.get('type_match')}"
        primary_effect = (xmage.get("primary_effect") or {}).get("effect")
        test_count = checks.get("focused_test_scenario_count")
        lines.append(
            "| "
            + " | ".join(
                [
                    f"`{card.get('card_name')}`",
                    f"`{card.get('severity')}`",
                    f"`{card.get('status')}`",
                    f"`{xmage.get('class_name')}`",
                    f"`{mana}`",
                    f"`{types}`",
                    f"`{primary_effect}`",
                    f"`{test_count}`",
                ]
            )
            + " |"
        )
    lines.extend(["", "## Decisions", ""])
    for card in report.get("cards", []):
        lines.extend(
            [
                f"### {card.get('card_name')}",
                "",
                f"- Status: `{card.get('status')}`",
                f"- Valid XMage source: `{card.get('valid_xmage_source')}`",
                f"- Ready for structured pull: `{card.get('ready_for_structured_pull')}`",
                f"- Reason: {card.get('reason')}",
                f"- Coherence findings: `{json.dumps(card.get('coherence_findings'), sort_keys=True)}`",
                f"- Focused test scenarios: `{(card.get('checks') or {}).get('focused_test_scenario_count')}`",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def write_report(report: dict[str, Any], output_json: Path, output_md: Path) -> None:
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    output_md.write_text(markdown_report(report), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--coherence-report", required=True)
    parser.add_argument("--xmage-index", required=True)
    parser.add_argument("--external-harvest")
    parser.add_argument("--output-prefix")
    parser.add_argument("--output-json")
    parser.add_argument("--output-md")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    coherence_report = load_json(Path(args.coherence_report))
    xmage_index = load_json(Path(args.xmage_index))
    external_harvest = load_json(Path(args.external_harvest)) if args.external_harvest else None
    report = build_audit(
        coherence_report=coherence_report,
        xmage_index=xmage_index,
        external_harvest=external_harvest,
    )
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    if args.output_prefix:
        output_json = Path(f"{args.output_prefix}.json")
        output_md = Path(f"{args.output_prefix}.md")
    else:
        stem = f"xmage_batch_validity_audit_{timestamp}"
        output_json = Path(args.output_json or DEFAULT_REPORT_DIR / f"{stem}.json")
        output_md = Path(args.output_md or DEFAULT_REPORT_DIR / f"{stem}.md")
    if args.output_json:
        output_json = Path(args.output_json)
    if args.output_md:
        output_md = Path(args.output_md)
    write_report(report, output_json, output_md)
    print(f"json_report={output_json}")
    print(f"md_report={output_md}")
    print(f"summary={json.dumps(report['summary'], sort_keys=True)}")
    print("mutations_performed=[]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
