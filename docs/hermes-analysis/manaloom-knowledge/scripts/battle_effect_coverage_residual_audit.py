#!/usr/bin/env python3
"""Audit residual effect coverage flags against explicit waiver policies."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


WAIVER_POLICIES: dict[str, dict[str, Any]] = {
    "cast_permission_not_explicit": {
        "status": "accepted_residual_contract",
        "owner": "battle-effect-contract",
        "reason": (
            "Cast-permission text is tracked as a static oracle-text risk. It is "
            "non-blocking when the card has a non-unknown source and replay "
            "action/decision gates remain clean."
        ),
    },
    "copy_effect_mismatch": {
        "status": "accepted_residual_contract",
        "owner": "battle-effect-contract",
        "reason": (
            "Copy-effect mismatch is a static string heuristic. It remains a "
            "named residual contract while event/action gates validate observed "
            "copy behavior."
        ),
    },
    "heuristic_effect": {
        "status": "accepted_residual_contract",
        "owner": "battle-heuristic-fallback",
        "reason": (
            "Effect-map and tag fallbacks are allowed as non-card-specific "
            "denominators after unknowns are removed; they must not be cited as "
            "card-specific learning evidence."
        ),
        "allowed_sources": {"effect_map", "tag"},
    },
    "land_utility_ability_not_modeled": {
        "status": "accepted_residual_contract",
        "owner": "battle-land-utility-contract",
        "reason": (
            "Utility land text is tracked separately from nonland battle effects; "
            "unmodeled land abilities remain visible but are not unknown card "
            "templates."
        ),
        "allowed_sources": {"type_land"},
    },
    "needs_review_rule": {
        "status": "accepted_residual_contract",
        "owner": "battle-rule-review-queue",
        "reason": (
            "Needs-review generated rules are visible in the review denominator "
            "but are not runtime-safe rules for battle learning."
        ),
        "allowed_source_prefixes": ("battle_rule_needs_review_",),
    },
    "oracle_silence_mismatch": {
        "status": "accepted_residual_contract",
        "owner": "battle-effect-contract",
        "reason": (
            "Silence mismatch is a static string heuristic over known non-unknown "
            "sources. It stays visible for review without blocking the replay "
            "when action/strategy gates are clean."
        ),
    },
    "oracle_target_removal_mismatch": {
        "status": "accepted_residual_contract",
        "owner": "battle-effect-contract",
        "reason": (
            "Target-removal mismatch is a static string heuristic over known "
            "non-unknown sources. It stays visible for review without blocking "
            "the replay when action/forensic gates are clean."
        ),
    },
    "temporary_effect_not_explicit": {
        "status": "accepted_residual_contract",
        "owner": "battle-effect-contract",
        "reason": (
            "Temporary-duration text is tracked as a residual contract until "
            "dedicated duration fixtures exist; observed replay gates still own "
            "actual event/decision validity."
        ),
    },
    "trigger_not_explicit": {
        "status": "accepted_residual_contract",
        "owner": "battle-effect-contract",
        "reason": (
            "Trigger text is tracked as a residual contract until dedicated "
            "trigger fixtures exist; observed trigger events are still checked "
            "by action/event gates."
        ),
    },
}

BLOCKING_FLAGS = {"unknown_effect"}


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--coverage-json", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--fail-on-unaccepted", action="store_true")
    return parser.parse_args(argv)


def policy_accepts_card(policy: dict[str, Any], card: dict[str, Any]) -> bool:
    source = str(card.get("source") or "")
    if source == "unknown":
        return False
    allowed_sources = set(policy.get("allowed_sources") or [])
    if allowed_sources and source not in allowed_sources:
        return False
    prefixes = tuple(policy.get("allowed_source_prefixes") or ())
    if prefixes and not source.startswith(prefixes):
        return False
    return True


def build_audit(coverage_json: Path) -> dict[str, Any]:
    coverage = json.loads(coverage_json.read_text(encoding="utf-8"))
    flag_totals = Counter(coverage.get("flag_totals") or {})
    cards = coverage.get("flagged_cards") or []

    items: list[dict[str, Any]] = []
    unaccepted: list[dict[str, Any]] = []
    accepted_flag_totals: Counter[str] = Counter()
    accepted_owner_totals: Counter[str] = Counter()
    accepted_status_totals: Counter[str] = Counter()
    card_flag_rows = 0

    for card in sorted(cards, key=lambda row: str(row.get("name") or "")):
        for flag in sorted(card.get("flags") or []):
            card_flag_rows += 1
            policy = WAIVER_POLICIES.get(flag)
            accepted = False
            reason = "No waiver policy for residual flag."
            owner = "unassigned"
            status = "unaccepted_residual_flag"
            if flag in BLOCKING_FLAGS:
                reason = "Blocking flag must be fixed, not waived."
            elif policy and policy_accepts_card(policy, card):
                accepted = True
                reason = str(policy.get("reason") or "")
                owner = str(policy.get("owner") or "unassigned")
                status = str(policy.get("status") or "accepted_residual_contract")
            elif policy:
                reason = "Residual waiver policy does not accept this card source."
                owner = str(policy.get("owner") or "unassigned")

            row = {
                "card": card.get("name"),
                "flag": flag,
                "effect": card.get("effect"),
                "source": card.get("source"),
                "decks": card.get("decks") or [],
                "status": status,
                "owner": owner,
                "accepted": accepted,
                "reason": reason,
            }
            items.append(row)
            if accepted:
                accepted_flag_totals[flag] += 1
                accepted_owner_totals[owner] += 1
                accepted_status_totals[status] += 1
            else:
                unaccepted.append(row)

    raw_unaccepted_flags = [
        flag for flag in sorted(flag_totals) if flag in BLOCKING_FLAGS or flag not in WAIVER_POLICIES
    ]
    status = (
        "effect_coverage_residual_accepted"
        if not unaccepted and not raw_unaccepted_flags
        else "review_required"
    )
    summary = {
        "generated_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "coverage_json": str(coverage_json),
        "status": status,
        "flag_totals": dict(sorted(flag_totals.items())),
        "raw_flag_total": int(sum(flag_totals.values())),
        "unique_flagged_cards": len(cards),
        "card_flag_rows": card_flag_rows,
        "accepted_card_flag_rows": len(items) - len(unaccepted),
        "unaccepted_card_flag_rows": len(unaccepted),
        "accepted_flag_totals": dict(sorted(accepted_flag_totals.items())),
        "accepted_owner_totals": dict(sorted(accepted_owner_totals.items())),
        "accepted_status_totals": dict(sorted(accepted_status_totals.items())),
        "raw_unaccepted_flags": raw_unaccepted_flags,
        "unaccepted_cards": sorted({str(item.get("card")) for item in unaccepted}),
        "unknown_cards": [card.get("name") for card in coverage.get("unknown_cards") or []],
        "focused_template_cards": [
            card.get("name") for card in coverage.get("focused_template_cards") or []
        ],
    }
    return {
        "version": 1,
        "summary": summary,
        "items": items,
        "unaccepted": unaccepted,
    }


def render_markdown(audit: dict[str, Any]) -> str:
    summary = audit["summary"]
    lines = [
        "# Battle Effect Coverage Residual Audit",
        "",
        f"- Generated at UTC: `{summary['generated_at_utc']}`",
        f"- Status: `{summary['status']}`",
        f"- Coverage JSON: `{summary['coverage_json']}`",
        f"- Raw flag total: `{summary['raw_flag_total']}`",
        f"- Unique flagged cards: `{summary['unique_flagged_cards']}`",
        f"- Card-flag rows: `{summary['card_flag_rows']}`",
        f"- Accepted card-flag rows: `{summary['accepted_card_flag_rows']}`",
        f"- Unaccepted card-flag rows: `{summary['unaccepted_card_flag_rows']}`",
        f"- Raw unaccepted flags: `{json.dumps(summary['raw_unaccepted_flags'])}`",
        f"- Unknown cards: `{json.dumps(summary['unknown_cards'])}`",
        f"- Focused template cards: `{len(summary['focused_template_cards'])}`",
        f"- Accepted owner totals: `{json.dumps(summary['accepted_owner_totals'], sort_keys=True)}`",
        "",
        "## Residual Flag Policies",
        "",
        "| Flag | Raw instances | Accepted card rows | Owner/status |",
        "| --- | ---: | ---: | --- |",
    ]
    for flag, count in sorted(summary["flag_totals"].items()):
        policy = WAIVER_POLICIES.get(flag, {})
        owner = policy.get("owner") or "unaccepted"
        status = policy.get("status") or "unaccepted"
        lines.append(
            f"| `{flag}` | `{count}` | `{summary['accepted_flag_totals'].get(flag, 0)}` | `{owner}/{status}` |"
        )

    if audit["unaccepted"]:
        lines.extend(["", "## Unaccepted Residuals", ""])
        for item in audit["unaccepted"][:80]:
            lines.append(
                f"- `{item['flag']}` `{item['card']}` `{item['source']}`: {item['reason']}"
            )
    else:
        lines.extend(["", "## Unaccepted Residuals", "", "- None."])

    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    audit = build_audit(args.coverage_json)
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
    if args.fail_on_unaccepted and audit["summary"]["status"] != "effect_coverage_residual_accepted":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
