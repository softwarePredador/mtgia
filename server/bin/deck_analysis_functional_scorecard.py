#!/usr/bin/env python3
"""Deck Analysis functional-tags scorecard over sanitized commander corpora.

Creates temporary public-backend decks from the versioned Commander Reference
corpora and inspects `/decks/:id/analysis` without saving auth tokens, QA
identities, deck ids, decklists, card ids, card names, or raw responses.
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import time
from typing import Any

from semantic_layer_v2_optimize_scorecard import (
    DEFAULT_BASE_URL,
    DEFAULT_CORPORA,
    auth,
    create_temp_deck,
    load_corpus,
    request,
    validate_deck,
)

PRIMARY_TAGS = ("ramp", "draw", "removal", "board_wipe", "protection")
PRIMARY_COMPOSITION_KEYS = {
    "ramp": "ramp",
    "draw": "draw",
    "removal": "removal",
    "board_wipe": "board_wipes",
    "protection": "protection",
}
DETAIL_METADATA_KEYS = (
    "reason",
    "evidence",
    "speed",
    "mana_efficiency",
    "card_advantage_type",
    "interaction_scope",
    "protection_type",
    "recursion_type",
)


def _as_dict(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def _as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def _safe_int(value: Any) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def _bounded_detail_metrics(raw_details: Any) -> dict[str, int]:
    details = [detail for detail in _as_list(raw_details) if isinstance(detail, dict)]
    metrics = {
        "sample_detail_count": len(details),
        "details_with_name": 0,
        "details_with_tag": 0,
        "details_with_confidence": 0,
        "details_with_semantic_schema": 0,
        "details_with_metadata": 0,
    }
    for detail in details:
        if str(detail.get("name") or "").strip():
            metrics["details_with_name"] += 1
        if str(detail.get("tag") or "").strip():
            metrics["details_with_tag"] += 1
        if detail.get("confidence") is not None:
            metrics["details_with_confidence"] += 1
        if str(detail.get("semantic_schema_version") or "").strip():
            metrics["details_with_semantic_schema"] += 1
        if any(str(detail.get(key) or "").strip() for key in DETAIL_METADATA_KEYS):
            metrics["details_with_metadata"] += 1
    return metrics


def _analyze_payload(payload: dict[str, Any]) -> dict[str, Any]:
    stats = _as_dict(payload.get("stats"))
    composition = _as_dict(stats.get("composition"))
    functional = _as_dict(payload.get("functional_tags"))
    counts = _as_dict(functional.get("counts"))
    samples = _as_dict(functional.get("samples"))
    details = _as_dict(functional.get("sample_details"))
    coverage = _as_dict(functional.get("coverage"))
    source = _as_dict(functional.get("source"))

    primary: dict[str, Any] = {}
    blockers: list[str] = []
    warnings: list[str] = []
    for tag in PRIMARY_TAGS:
        count = _safe_int(counts.get(tag))
        sample_count = len(_as_list(samples.get(tag)))
        detail_metrics = _bounded_detail_metrics(details.get(tag))
        composition_count = _safe_int(
            composition.get(PRIMARY_COMPOSITION_KEYS[tag])
        )
        composition_matches = count == composition_count
        if not composition_matches:
            blockers.append("composition_count_mismatch:" + tag)
        if count > 0 and sample_count == 0:
            blockers.append("missing_samples:" + tag)
        if count > 0 and detail_metrics["sample_detail_count"] == 0:
            blockers.append("missing_sample_details:" + tag)
        if detail_metrics["sample_detail_count"] > 0 and (
            detail_metrics["details_with_name"] < detail_metrics["sample_detail_count"]
            or detail_metrics["details_with_tag"] < detail_metrics["sample_detail_count"]
        ):
            blockers.append("incomplete_sample_detail_identity:" + tag)
        if count > 0 and detail_metrics["details_with_metadata"] == 0:
            warnings.append("sample_details_without_explanation_metadata:" + tag)
        primary[tag] = {
            "count": count,
            "composition_count": composition_count,
            "composition_matches": composition_matches,
            "sample_count": sample_count,
            **detail_metrics,
        }

    card_copies = _safe_int(coverage.get("card_copies"))
    tagged_copies = _safe_int(coverage.get("tagged_copies"))
    coverage_ratio = round((tagged_copies / card_copies), 4) if card_copies else 0
    if not str(functional.get("schema_version") or "").strip():
        blockers.append("missing_functional_schema_version")
    if not str(functional.get("semantic_schema_version") or "").strip():
        blockers.append("missing_semantic_schema_version")
    if not coverage:
        blockers.append("missing_coverage")
    if not source:
        blockers.append("missing_source")
    if card_copies and coverage_ratio < 0.45:
        warnings.append("tagged_copy_coverage_below_45pct")
    if _safe_int(source.get("heuristic_copies")) > _safe_int(
        source.get("persisted_copies")
    ):
        warnings.append("heuristic_copies_exceed_persisted_copies")

    return {
        "analysis_shape_ok": not blockers,
        "schema_version": functional.get("schema_version"),
        "semantic_schema_version": functional.get("semantic_schema_version"),
        "coverage": {
            "card_rows": _safe_int(coverage.get("card_rows")),
            "card_copies": card_copies,
            "tagged_rows": _safe_int(coverage.get("tagged_rows")),
            "tagged_copies": tagged_copies,
            "other_rows": _safe_int(coverage.get("other_rows")),
            "other_copies": _safe_int(coverage.get("other_copies")),
            "tagged_copy_ratio": coverage_ratio,
        },
        "source": {
            "priority": source.get("priority"),
            "persisted_rows": _safe_int(source.get("persisted_rows")),
            "persisted_copies": _safe_int(source.get("persisted_copies")),
            "heuristic_rows": _safe_int(source.get("heuristic_rows")),
            "heuristic_copies": _safe_int(source.get("heuristic_copies")),
        },
        "primary_tags": primary,
        "blockers": sorted(set(blockers)),
        "warnings": sorted(set(warnings)),
    }


def analyze_deck(base_url: str, token: str, deck_id: str) -> dict[str, Any]:
    status, data, _ = request(
        base_url,
        "GET",
        f"/decks/{deck_id}/analysis",
        token=token,
        timeout=90,
        retries=2,
    )
    result = {
        "analysis_status": status,
        "analysis_shape_ok": False,
        "blockers": [],
        "warnings": [],
    }
    if status != 200 or not isinstance(data, dict):
        result["blockers"] = ["analysis_http_not_200"]
        return result
    return result | _analyze_payload(data)


def run(args: argparse.Namespace) -> dict[str, Any]:
    base_url = args.base_url.rstrip("/")
    status, health, _ = request(base_url, "GET", "/health", timeout=30)
    if status != 200:
        raise RuntimeError(("health", status, health))
    if args.expected_sha and health.get("git_sha") != args.expected_sha:
        raise RuntimeError(("unexpected_sha", health.get("git_sha"), args.expected_sha))

    token = auth(base_url)
    card_cache: dict[str, str | None] = {}
    server_root = pathlib.Path(args.server_root).resolve()
    corpora = DEFAULT_CORPORA[: args.limit]
    summary: dict[str, Any] = {
        "status": "PASS_WITH_RISKS",
        "date": time.strftime("%Y-%m-%d"),
        "scope": "deck_analysis_functional_scorecard",
        "backend_url": base_url,
        "backend_git_sha": health.get("git_sha"),
        "cases": [],
        "redactions": {
            "auth_token": "not_saved",
            "qa_email": "not_saved",
            "deck_ids": "redacted",
            "decklists": "not_saved",
            "card_ids": "not_saved",
            "card_names": "not_saved",
            "raw_payloads": "not_saved",
        },
    }

    for slug, rel_path, archetype in corpora:
        deck_meta, cards = load_corpus(server_root, rel_path)
        case: dict[str, Any] = {
            "commander_slug": slug,
            "source": "versioned_commander_reference_corpus",
            "theme": deck_meta.get("theme") or archetype,
            "card_entry_count": len(cards),
            "quantity_total": sum(_safe_int(card.get("quantity") or 1) for card in cards),
        }
        deck_id, create_meta = create_temp_deck(base_url, token, cards, card_cache)
        case.update(create_meta)
        if deck_id:
            try:
                case.update(validate_deck(base_url, token, deck_id))
                if case.get("validation_ok"):
                    case.update(analyze_deck(base_url, token, deck_id))
            finally:
                request(
                    base_url,
                    "DELETE",
                    "/decks/" + deck_id,
                    token=token,
                    timeout=45,
                    retries=0,
                )
        summary["cases"].append(case)

    eligible = [
        case
        for case in summary["cases"]
        if case.get("create_status") != "skipped"
        and case.get("validation_ok")
        and _safe_int(case.get("unresolved_count")) == 0
        and _safe_int(case.get("off_identity")) == 0
        and _safe_int(case.get("commander_qty")) == 1
        and _safe_int(case.get("main_qty")) == 99
    ]
    analyzed = [case for case in eligible if case.get("analysis_status") == 200]
    blockers = [
        blocker
        for case in analyzed
        for blocker in case.get("blockers", [])
        if isinstance(blocker, str)
    ]
    warnings = [
        warning
        for case in analyzed
        for warning in case.get("warnings", [])
        if isinstance(warning, str)
    ]
    skipped_or_invalid = len(summary["cases"]) - len(eligible)
    blocked = skipped_or_invalid > 0 or len(analyzed) < len(eligible) or bool(blockers)
    summary["scorecard"] = {
        "cases_attempted": len(summary["cases"]),
        "eligible_cases": len(eligible),
        "analysis_http_200_cases": len(analyzed),
        "analysis_shape_ok_cases": len(
            [case for case in analyzed if case.get("analysis_shape_ok")]
        ),
        "skipped_or_invalid_cases": skipped_or_invalid,
        "blocker_count": len(blockers),
        "warning_count": len(warnings),
        "blocker_codes": sorted(set(blockers)),
        "warning_codes": sorted(set(warnings)),
        "decision": "fix_analysis_payload_before_release" if blocked else "analysis_payload_ready_for_real_deck_qa",
    }
    summary["status"] = "BLOCKED" if blocked else "PASS_WITH_RISKS"
    return summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--base-url",
        default=os.environ.get("DECK_ANALYSIS_SCORECARD_BASE_URL", DEFAULT_BASE_URL),
    )
    parser.add_argument(
        "--expected-sha",
        default=os.environ.get("DECK_ANALYSIS_SCORECARD_EXPECTED_SHA"),
    )
    parser.add_argument(
        "--server-root",
        default=str(pathlib.Path(__file__).resolve().parents[1]),
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=int(os.environ.get("DECK_ANALYSIS_SCORECARD_LIMIT", "10")),
    )
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    summary = run(args)
    output = pathlib.Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(summary, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
    )
    print(
        "DECK_ANALYSIS_FUNCTIONAL_SCORECARD "
        + json.dumps(
            {"output": str(output), "scorecard": summary["scorecard"]},
            sort_keys=True,
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
