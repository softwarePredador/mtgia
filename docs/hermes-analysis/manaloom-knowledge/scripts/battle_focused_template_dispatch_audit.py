#!/usr/bin/env python3
"""Audit focused-template cards for dispatch and evidence readiness."""

from __future__ import annotations

import argparse
import importlib.util
import inspect
import json
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
SERVER_BIN = REPO_ROOT / "server/bin"
ACCEPTED_WAIVER_STATUSES = {
    "accepted",
    "accepted_waiver",
    "fixture_not_required",
    "not_required",
    "waived",
}


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--coverage-json", type=Path, required=True)
    parser.add_argument("--evidence-output-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--fail-on-not-ready", action="store_true")
    return parser.parse_args(argv)


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def support_template_names(focused_module: Any) -> list[str]:
    return sorted(
        name
        for name in dir(focused_module)
        if name.startswith("supports_") and name.endswith("_template")
    )


def dispatch_template_names(focused_module: Any) -> list[str]:
    source = inspect.getsource(focused_module.evaluate_draft)
    return sorted(set(re.findall(r"\b(supports_[a-zA-Z0-9_]+_template)\s*\(", source)))


def build_evidence_names(focused_module: Any) -> list[str]:
    return sorted(
        name
        for name in dir(focused_module)
        if name.startswith("build_") and name.endswith("_evidence")
    )


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug[:80] or "focused-card"


def make_draft(
    review_module: Any,
    focused_module: Any,
    backlog_module: Any,
    card: dict[str, Any],
):
    name = str(card.get("name") or "")
    oracle_text = str(card.get("oracle_sample") or card.get("oracle_text") or "")
    current_families = sorted(review_module.infer_effect_families_from_text(oracle_text))
    plan = backlog_module.BACKLOG_PLAN.get(name, {})
    reviewed_families = sorted(str(item) for item in plan.get("families", []))
    families = sorted(set(current_families) | set(reviewed_families))
    draft = focused_module.DraftRecord(
        run_id="focused_template_dispatch_audit",
        card_name=name,
        oracle_id=None,
        set_code="",
        draft_rule_key="focused_template_dispatch_audit",
        proposed_status="needs_review",
        confidence="low",
        roles=[],
        effect_families=families,
        risk_flags=[str(flag) for flag in card.get("flags") or []],
        draft={"oracle_text_excerpt": oracle_text},
    )
    return draft, current_families, reviewed_families, plan


def predicate_matches(focused_module: Any, draft: Any) -> list[str]:
    matches: list[str] = []
    for name in support_template_names(focused_module):
        func = getattr(focused_module, name)
        try:
            if func(draft):
                matches.append(name)
        except Exception:
            continue
    return matches


def waiver_status(plan: dict[str, Any]) -> str:
    return str(
        plan.get("focused_evidence_waiver_status")
        or plan.get("dispatch_waiver_status")
        or plan.get("waiver_status")
        or "none"
    )


def waiver_reason(plan: dict[str, Any]) -> str:
    return str(
        plan.get("focused_evidence_waiver_reason")
        or plan.get("dispatch_waiver_reason")
        or plan.get("waiver_reason")
        or ""
    )


def build_item(
    review_module: Any,
    focused_module: Any,
    backlog_module: Any,
    dispatch_names: set[str],
    evidence_output_dir: Path,
    card: dict[str, Any],
) -> dict[str, Any]:
    draft, current_families, reviewed_families, plan = make_draft(
        review_module,
        focused_module,
        backlog_module,
        card,
    )
    matches = predicate_matches(focused_module, draft)
    dispatchable = sorted(set(matches) & dispatch_names)
    nondispatched = sorted(set(matches) - dispatch_names)
    card_output_dir = evidence_output_dir / slugify(str(card.get("name") or ""))
    result = focused_module.evaluate_draft(draft, card_output_dir)
    status = str(getattr(result, "status", "unknown"))
    waiver = waiver_status(plan)
    accepted_waiver = waiver in ACCEPTED_WAIVER_STATUSES
    focused_evidence_ready = status == "evidence_ready"
    risk_flags: list[str] = []
    if not matches:
        risk_flags.append("missing_template_predicate_match")
    if matches and not dispatchable:
        risk_flags.append("missing_evidence_dispatch")
    if not focused_evidence_ready and not accepted_waiver:
        risk_flags.append("focused_evidence_not_ready")
    return {
        "name": str(card.get("name") or ""),
        "source": str(card.get("source") or ""),
        "effect": str(card.get("effect") or ""),
        "flags": [str(flag) for flag in card.get("flags") or []],
        "decks": [str(deck) for deck in card.get("decks") or []],
        "current_inferred_families": current_families,
        "reviewed_families": reviewed_families,
        "template_predicate_matches": matches,
        "dispatchable_template_matches": dispatchable,
        "nondispatched_template_matches": nondispatched,
        "template_predicate_match": bool(matches),
        "evidence_dispatch_ready": bool(dispatchable),
        "focused_evidence_ready": focused_evidence_ready,
        "evidence_runner_status": status,
        "evidence_runner_reason": str(getattr(result, "reason", "")),
        "evidence_artifacts": [str(path) for path in getattr(result, "artifacts", [])],
        "waiver_status": waiver,
        "waiver_reason": waiver_reason(plan),
        "accepted_waiver": accepted_waiver,
        "next_fixture": str(plan.get("next_fixture") or ""),
        "owner": str(plan.get("owner") or "unassigned"),
        "risk_flags": risk_flags,
    }


def build_audit_from_modules(
    coverage: dict[str, Any],
    review_module: Any,
    focused_module: Any,
    backlog_module: Any,
    evidence_output_dir: Path,
    coverage_json: Path | None = None,
) -> dict[str, Any]:
    supports = support_template_names(focused_module)
    dispatch = dispatch_template_names(focused_module)
    dispatch_set = set(dispatch)
    builders = build_evidence_names(focused_module)
    cards = sorted(
        coverage.get("focused_template_cards") or [],
        key=lambda row: str(row.get("name") or ""),
    )
    items = [
        build_item(
            review_module,
            focused_module,
            backlog_module,
            dispatch_set,
            evidence_output_dir,
            card,
        )
        for card in cards
    ]
    status_counts = Counter(item["evidence_runner_status"] for item in items)
    risk_counts = Counter(flag for item in items for flag in item["risk_flags"])
    unready_items = [
        item
        for item in items
        if not item["focused_evidence_ready"] and not item["accepted_waiver"]
    ]
    without_dispatch = [
        item["name"] for item in items if item["template_predicate_match"] and not item["evidence_dispatch_ready"]
    ]
    without_predicate = [item["name"] for item in items if not item["template_predicate_match"]]
    summary = {
        "generated_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "coverage_json": str(coverage_json) if coverage_json else None,
        "status": "focused_template_dispatch_ready" if not unready_items else "review_required",
        "focused_template_cards": len(items),
        "template_predicate_match": sum(1 for item in items if item["template_predicate_match"]),
        "without_template_predicate_match": len(without_predicate),
        "evidence_dispatch_ready": sum(1 for item in items if item["evidence_dispatch_ready"]),
        "without_evidence_dispatch": len(without_dispatch),
        "focused_evidence_ready": sum(1 for item in items if item["focused_evidence_ready"]),
        "focused_evidence_not_ready_unwaived": len(unready_items),
        "accepted_waivers": sum(1 for item in items if item["accepted_waiver"]),
        "evidence_runner_status_counts": dict(sorted(status_counts.items())),
        "risk_flag_counts": dict(sorted(risk_counts.items())),
        "supports_template_count": len(supports),
        "evaluate_dispatch_template_count": len(dispatch),
        "build_evidence_function_count": len(builders),
        "supports_not_dispatched": sorted(set(supports) - dispatch_set),
        "focused_template_cards_without_dispatch": without_dispatch,
        "focused_template_cards_without_predicate": without_predicate,
        "focused_template_cards_not_ready_unwaived": [item["name"] for item in unready_items],
    }
    return {"version": 1, "summary": summary, "items": items}


def build_audit(coverage_json: Path, evidence_output_dir: Path) -> dict[str, Any]:
    coverage = json.loads(coverage_json.read_text(encoding="utf-8"))
    review_module = load_module(
        "manaloom_battle_rule_review_queue_for_focused_dispatch_audit",
        SERVER_BIN / "manaloom_battle_rule_review_queue.py",
    )
    focused_module = load_module(
        "manaloom_battle_rule_focused_evidence_for_focused_dispatch_audit",
        SERVER_BIN / "manaloom_battle_rule_focused_evidence.py",
    )
    backlog_module = load_module(
        "battle_unknown_template_backlog_for_focused_dispatch_audit",
        SCRIPT_DIR / "battle_unknown_template_backlog_audit.py",
    )
    return build_audit_from_modules(
        coverage,
        review_module,
        focused_module,
        backlog_module,
        evidence_output_dir,
        coverage_json=coverage_json,
    )


def render_list(values: list[str]) -> str:
    return ", ".join(values) if values else "-"


def render_markdown(audit: dict[str, Any]) -> str:
    summary = audit["summary"]
    lines = [
        "# Battle Focused Template Dispatch Audit",
        "",
        f"- Generated at UTC: `{summary['generated_at_utc']}`",
        f"- Status: `{summary['status']}`",
        f"- Coverage JSON: `{summary['coverage_json']}`",
        f"- Focused template cards: `{summary['focused_template_cards']}`",
        f"- Template predicate match: `{summary['template_predicate_match']}`",
        f"- Without template predicate match: `{summary['without_template_predicate_match']}`",
        f"- Evidence dispatch ready: `{summary['evidence_dispatch_ready']}`",
        f"- Without evidence dispatch: `{summary['without_evidence_dispatch']}`",
        f"- Focused evidence ready: `{summary['focused_evidence_ready']}`",
        f"- Focused evidence not ready unwaived: `{summary['focused_evidence_not_ready_unwaived']}`",
        f"- Accepted waivers: `{summary['accepted_waivers']}`",
        f"- Evidence runner status counts: `{json.dumps(summary['evidence_runner_status_counts'], sort_keys=True)}`",
        f"- Supports template count: `{summary['supports_template_count']}`",
        f"- Evaluate dispatch template count: `{summary['evaluate_dispatch_template_count']}`",
        f"- Build evidence function count: `{summary['build_evidence_function_count']}`",
        "",
        "## Per-Card Dispatch",
        "",
        "| Card | Predicate match | Dispatch ready | Evidence status | Waiver | Next fixture | Risk flags |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for item in audit["items"]:
        lines.append(
            "| `{name}` | `{predicate}` | `{dispatch}` | `{status}` | `{waiver}` | `{fixture}` | `{risk}` |".format(
                name=item["name"],
                predicate=render_list(item["template_predicate_matches"]),
                dispatch=render_list(item["dispatchable_template_matches"]),
                status=item["evidence_runner_status"],
                waiver=item["waiver_status"],
                fixture=item["next_fixture"] or "-",
                risk=render_list(item["risk_flags"]),
            )
        )
    lines.extend(
        [
            "",
            "## Interpretation",
            "",
            "- `template_predicate_match` means a `supports_*_template` predicate matched the card family.",
            "- `evidence_dispatch_ready` means `evaluate_draft(...)` routes that predicate to a focused evidence builder.",
            "- `focused_evidence_ready` means the evidence builder produced passing focused artifacts.",
        ]
    )
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    audit = build_audit(args.coverage_json, args.evidence_output_dir)
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
    if args.fail_on_not_ready and audit["summary"]["status"] != "focused_template_dispatch_ready":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
