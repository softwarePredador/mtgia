#!/usr/bin/env python3
"""Reconcile external Lorehold deckbuilding evidence with current 607 gates.

This is a read-only learning layer. It does not propose a deck mutation by
itself; it classifies whether an external signal can reopen the current
protected deck-607 contract, needs a separate full-shell contract, or is already
represented by the champion.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_EXTERNAL_CORPUS = (
    REPO_ROOT / "docs" / "hermes-analysis" / "LOREHOLD_EXTERNAL_EVIDENCE_CORPUS_2026-07-04.json"
)
DEFAULT_CHAMPION_SNAPSHOT = (
    REPORT_DIR / "lorehold_current_champion_snapshot_20260704_learning_refresh.json"
)
DEFAULT_TRACE_CUT_EVIDENCE = (
    REPORT_DIR / "lorehold_trace_cut_evidence_expander_20260704_role_tag_repair.json"
)
DEFAULT_PLANNER = (
    REPORT_DIR / "lorehold_next_action_planner_20260704_role_tag_repair_learning.json"
)
DEFAULT_STEM = "lorehold_external_evidence_reconciler_20260704_current"


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def card_names_from_champion(champion_snapshot: Mapping[str, Any]) -> set[str]:
    return {
        str(card.get("name") or "")
        for card in as_list(champion_snapshot.get("cards"))
        if card.get("name")
    }


def cut_slots_by_card(trace_cut_evidence: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for row in as_list(trace_cut_evidence.get("all_cut_slots")):
        name = str(row.get("card_name") or "")
        if name:
            rows[name] = dict(row)
    return rows


def prior_key_sets(planner: Mapping[str, Any]) -> dict[str, set[str]]:
    summary = planner.get("summary") or {}
    rejected = {
        str(key)
        for key in as_list(summary.get("prior_rejected_package_keys"))
        if key
    }
    inconclusive = {
        str(key)
        for key in as_list(summary.get("prior_inconclusive_low_exposure_keys"))
        if key
    }
    return {
        "rejected": rejected,
        "rejected_slugs": {slug(key) for key in rejected},
        "inconclusive": inconclusive,
        "inconclusive_slugs": {slug(key) for key in inconclusive},
    }


def matching_prior_keys(signal: Mapping[str, Any], prior_sets: Mapping[str, set[str]]) -> dict[str, list[str]]:
    candidate_keys = [
        str(signal.get("package_key") or ""),
        *[str(item) for item in as_list(signal.get("known_internal_package_keys"))],
    ]
    candidate_keys = [key for key in candidate_keys if key]
    candidate_slugs = {slug(key) for key in candidate_keys}
    rejected = sorted(
        key
        for key in prior_sets["rejected"]
        if key in candidate_keys or slug(key) in candidate_slugs
    )
    inconclusive = sorted(
        key
        for key in prior_sets["inconclusive"]
        if key in candidate_keys or slug(key) in candidate_slugs
    )
    return {"rejected": rejected, "inconclusive": inconclusive}


def classify_signal(
    signal: Mapping[str, Any],
    *,
    champion_cards: set[str],
    cut_slots: Mapping[str, Mapping[str, Any]],
    prior_sets: Mapping[str, set[str]],
) -> dict[str, Any]:
    add_cards = [str(card) for card in as_list(signal.get("add_cards")) if card]
    cut_cards = [str(card) for card in as_list(signal.get("proposed_cut_cards")) if card]
    add_status = [
        {"card_name": card, "in_current_607": card in champion_cards}
        for card in add_cards
    ]
    missing_add_cards = [row["card_name"] for row in add_status if not row["in_current_607"]]
    cut_status = []
    for card in cut_cards:
        slot = dict(cut_slots.get(card) or {})
        cut_status.append(
            {
                "card_name": card,
                "in_current_607": card in champion_cards,
                "actionability": slot.get("actionability") or "",
                "lane": slot.get("lane") or "",
                "status": slot.get("status") or "",
                "all_blockers": slot.get("all_blockers") or [],
                "recommended_action": slot.get("recommended_action") or "",
            }
        )
    prior_matches = matching_prior_keys(signal, prior_sets)
    blockers: list[str] = []
    contract_path = str(signal.get("contract_path") or "")
    signal_type = str(signal.get("signal_type") or "")

    if signal_type == "format_context":
        status = "context_only"
        recommended = "use_as_legality_or_power_context_only"
    elif add_cards and not missing_add_cards:
        status = "already_represented_by_current_607"
        recommended = "treat_as_external_support_for_existing_607_anchor"
    elif contract_path == "full_shell":
        status = "requires_separate_full_shell_contract"
        blockers.append("not_a_current_one_for_one_cut")
        recommended = "declare_full_shell_contract_before_battle"
    elif not cut_cards:
        status = "blocked_no_named_cut"
        blockers.append("no_named_cut_card")
        recommended = "find_seed_safe_cut_or_model_as_diagnostic_only"
    elif any(not row["in_current_607"] for row in cut_status):
        status = "blocked_cut_not_in_current_607"
        blockers.append("proposed_cut_not_in_current_607")
        recommended = "repair_cut_mapping_before_any_gate"
    elif any(row["actionability"] != "seed_safe_ready" for row in cut_status):
        status = "blocked_by_cut_safety"
        blockers.append("proposed_cut_not_seed_safe")
        recommended = "do_not_gate_until_cut_safety_changes"
    else:
        status = "preflight_ready_external_candidate"
        recommended = "build_named_package_manifest_then_battle_gate"

    if prior_matches["rejected"]:
        blockers.append("prior_internal_reject")
    if prior_matches["inconclusive"]:
        blockers.append("prior_internal_inconclusive_low_exposure")
    if status == "preflight_ready_external_candidate" and blockers:
        status = "blocked_by_prior_internal_evidence"
        recommended = "do_not_promote_without_new_material_evidence"

    return {
        "signal_key": signal.get("signal_key"),
        "package_key": signal.get("package_key"),
        "status": status,
        "recommended_action": recommended,
        "contract_path": contract_path,
        "lane": signal.get("lane"),
        "external_strength": signal.get("external_strength"),
        "evidence_summary": signal.get("evidence_summary"),
        "source_keys": signal.get("source_keys") or [],
        "add_cards": add_status,
        "missing_add_cards": missing_add_cards,
        "proposed_cut_cards": cut_status,
        "prior_internal_matches": prior_matches,
        "known_internal_decisions": signal.get("known_internal_decisions") or [],
        "blockers": sorted(set(blockers)),
        "notes": signal.get("notes") or [],
    }


def build_report(
    *,
    external_corpus: Mapping[str, Any],
    champion_snapshot: Mapping[str, Any],
    trace_cut_evidence: Mapping[str, Any],
    planner: Mapping[str, Any],
    external_corpus_path: Path,
    champion_snapshot_path: Path,
    trace_cut_evidence_path: Path,
    planner_path: Path,
) -> dict[str, Any]:
    champion_cards = card_names_from_champion(champion_snapshot)
    cut_slots = cut_slots_by_card(trace_cut_evidence)
    prior_sets = prior_key_sets(planner)
    signals = [
        classify_signal(
            signal,
            champion_cards=champion_cards,
            cut_slots=cut_slots,
            prior_sets=prior_sets,
        )
        for signal in as_list(external_corpus.get("signals"))
    ]
    status_counts = Counter(str(signal.get("status") or "") for signal in signals)
    blocker_counts = Counter(
        blocker for signal in signals for blocker in as_list(signal.get("blockers"))
    )
    ready = [signal for signal in signals if signal["status"] == "preflight_ready_external_candidate"]
    next_queue = [
        signal
        for signal in signals
        if signal["status"]
        in {
            "blocked_no_named_cut",
            "requires_separate_full_shell_contract",
            "blocked_by_cut_safety",
        }
    ]
    if ready:
        recommended = "build_named_package_manifest_then_battle_gate"
    elif next_queue:
        recommended = "continue_external_research_but_keep_607_protected"
    else:
        recommended = "keep_607_and_monitor_external_evidence"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_external_evidence_reconciliation",
        "postgres_writes": False,
        "source_db_mutated": False,
        "external_corpus": rel(external_corpus_path),
        "champion_snapshot": rel(champion_snapshot_path),
        "trace_cut_evidence": rel(trace_cut_evidence_path),
        "planner": rel(planner_path),
        "sources": external_corpus.get("sources") or [],
        "signals": signals,
        "next_learning_queue": next_queue,
        "summary": {
            "external_signal_count": len(signals),
            "status_counts": dict(sorted(status_counts.items())),
            "blocker_counts": dict(sorted(blocker_counts.items())),
            "direct_deck_change_ready_count": len(ready),
            "next_learning_queue_count": len(next_queue),
            "current_607_card_count": len(champion_cards),
            "current_cut_slot_count": len(cut_slots),
            "planner_recommended_next_action": (
                (planner.get("summary") or {}).get("recommended_next_action") or ""
            ),
            "trace_cut_recommended_next_action": (
                (trace_cut_evidence.get("summary") or {}).get("recommended_next_action") or ""
            ),
            "recommended_next_action": recommended,
        },
        "method_notes": [
            "External popularity is source evidence, not a deck promotion.",
            "A signal can become a deck-change candidate only with a named add/cut package and seed-safe cut.",
            "Full-shell signals require a separate shell contract and cannot reuse the exhausted one-for-one gate.",
            "This script is read-only and does not mutate PostgreSQL, SQLite, or deck contents.",
        ],
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold External Evidence Reconciliation",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        f"- External corpus: `{payload['external_corpus']}`",
        f"- Champion snapshot: `{payload['champion_snapshot']}`",
        f"- Trace cut evidence: `{payload['trace_cut_evidence']}`",
        f"- Planner: `{payload['planner']}`",
        f"- External signals: `{summary['external_signal_count']}`",
        f"- Direct deck-change ready: `{summary['direct_deck_change_ready_count']}`",
        f"- Next learning queue: `{summary['next_learning_queue_count']}`",
        f"- Recommended next action: `{summary['recommended_next_action']}`",
        f"- Status counts: `{json.dumps(summary['status_counts'], sort_keys=True)}`",
        f"- Blocker counts: `{json.dumps(summary['blocker_counts'], sort_keys=True)}`",
        "",
        "## Signals",
        "",
        "| Signal | Status | Lane | Add cards missing from 607 | Proposed cuts | Next action |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for signal in payload.get("signals") or []:
        missing = ", ".join(signal.get("missing_add_cards") or []) or "-"
        cuts = ", ".join(
            row.get("card_name") or "" for row in signal.get("proposed_cut_cards") or []
        ) or "-"
        lines.append(
            "| {signal} | `{status}` | `{lane}` | {missing} | {cuts} | `{action}` |".format(
                signal=signal.get("signal_key") or "",
                status=signal.get("status") or "",
                lane=signal.get("lane") or "",
                missing=missing,
                cuts=cuts,
                action=signal.get("recommended_action") or "",
            )
        )
    lines.extend(["", "## Next Learning Queue", ""])
    queue = payload.get("next_learning_queue") or []
    if not queue:
        lines.append("- None.")
    else:
        for signal in queue:
            lines.append(
                f"- `{signal.get('signal_key')}` status `{signal.get('status')}`: "
                f"{signal.get('recommended_action')}."
            )
    lines.extend(["", "## Sources", ""])
    for source in payload.get("sources") or []:
        lines.append(
            f"- `{source.get('source_key')}`: {source.get('url')} "
            f"({source.get('source_type')})"
        )
    lines.extend(["", "## Method Notes", ""])
    for note in payload.get("method_notes") or []:
        lines.append(f"- {note}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--external-corpus", type=Path, default=DEFAULT_EXTERNAL_CORPUS)
    parser.add_argument("--champion-snapshot", type=Path, default=DEFAULT_CHAMPION_SNAPSHOT)
    parser.add_argument("--trace-cut-evidence", type=Path, default=DEFAULT_TRACE_CUT_EVIDENCE)
    parser.add_argument("--planner", type=Path, default=DEFAULT_PLANNER)
    parser.add_argument("--stem", default=DEFAULT_STEM)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_report(
        external_corpus=read_json(args.external_corpus),
        champion_snapshot=read_json(args.champion_snapshot),
        trace_cut_evidence=read_json(args.trace_cut_evidence),
        planner=read_json(args.planner),
        external_corpus_path=args.external_corpus,
        champion_snapshot_path=args.champion_snapshot,
        trace_cut_evidence_path=args.trace_cut_evidence,
        planner_path=args.planner,
    )
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
