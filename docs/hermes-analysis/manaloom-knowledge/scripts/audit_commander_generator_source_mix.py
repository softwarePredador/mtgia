#!/usr/bin/env python3
"""Classify deterministic commander deck source-mix provenance.

Reads the output of `server/bin/commander_generate_provenance_audit.dart` and
extracts actionable buckets for cards that still touch `deterministic_fallback`.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


FALLBACK = "deterministic_fallback"
PROFILE = "profile_expected_packages"
STATS = "reference_card_stats"
CORPUS = "reference_corpus_packages"
LEARNED = "active_learned_deck"
USAGE = "usage_hot_cards"


def _sorted_card_names(cards: list[dict]) -> list[str]:
    return sorted(
        [
            str(card.get("card_name") or "").strip()
            for card in cards
            if str(card.get("card_name") or "").strip()
        ]
    )


def build_summary(payload: dict) -> dict:
    deterministic = payload.get("deterministic_deck") or {}
    diagnostics = deterministic.get("runtime_build_diagnostics") or {}
    cards = deterministic.get("cards") or []

    fallback_touched = []
    fallback_only = []
    learned_plus_fallback_only = []
    fallback_without_profile_or_stats = []
    fallback_profile_stats_only = []
    fallback_profile_stats_no_empirical_support = []

    for entry in cards:
        card_name = str(entry.get("card_name") or "").strip()
        if not card_name:
            continue
        sources = list(entry.get("sources") or [])
        source_set = set(sources)
        if FALLBACK not in source_set:
            continue
        fallback_touched.append(entry)

        if source_set == {FALLBACK}:
            fallback_only.append(entry)

        if source_set == {FALLBACK, LEARNED}:
            learned_plus_fallback_only.append(entry)

        if PROFILE not in source_set and STATS not in source_set:
            fallback_without_profile_or_stats.append(entry)

        if source_set == {FALLBACK, PROFILE, STATS}:
            fallback_profile_stats_only.append(entry)

        if (
            FALLBACK in source_set
            and PROFILE in source_set
            and STATS in source_set
            and LEARNED not in source_set
            and CORPUS not in source_set
            and USAGE not in source_set
        ):
            fallback_profile_stats_no_empirical_support.append(entry)

    total_cards = len([entry for entry in cards if entry.get("card_name")])
    non_fallback_supported = total_cards - len(fallback_touched)
    all_fallback_have_non_fallback_source = all(
        len(set(entry.get("sources") or [])) > 1
        for entry in fallback_touched
    )

    priorities = []
    if fallback_only:
        priorities.append(
            {
                "priority": "P0",
                "code": "fallback_only_slots",
                "count": len(fallback_only),
                "action": "Promote or justify cards that still exist only via deterministic fallback.",
                "cards": _sorted_card_names(fallback_only),
            }
        )
    if learned_plus_fallback_only:
        priorities.append(
            {
                "priority": "P1",
                "code": "learned_plus_fallback_only",
                "count": len(learned_plus_fallback_only),
                "action": "Corroborate learned-only slots with corpus/usage/profile or keep them explicitly fallback-backed.",
                "cards": _sorted_card_names(learned_plus_fallback_only),
            }
        )
    if fallback_without_profile_or_stats:
        priorities.append(
            {
                "priority": "P1",
                "code": "fallback_without_profile_or_stats",
                "count": len(fallback_without_profile_or_stats),
                "action": "Backfill profile/stats support for fallback-touched cards that are not justified by canonical profile/stats.",
                "cards": _sorted_card_names(fallback_without_profile_or_stats),
            }
        )
    if fallback_profile_stats_no_empirical_support:
        priorities.append(
            {
                "priority": "P2",
                "code": "fallback_profile_stats_no_empirical_support",
                "count": len(fallback_profile_stats_no_empirical_support),
                "action": "Review cards that still rely on fallback + profile/stats only, without learned/corpus/usage corroboration.",
                "cards": _sorted_card_names(fallback_profile_stats_no_empirical_support),
            }
        )

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "commander_name": payload.get("commander_name"),
        "artifact_dir": payload.get("artifact_dir"),
        "deterministic_deck_built": deterministic.get("built"),
        "main_count": deterministic.get("main_count"),
        "distinct_card_count": deterministic.get("distinct_card_count"),
        "runtime_source_mix_counts": diagnostics.get("source_mix_counts"),
        "runtime_source_usage_counts": diagnostics.get("source_usage_counts"),
        "built_in_fallback_used_count": diagnostics.get("built_in_fallback_used_count"),
        "built_in_fallback_only_count": diagnostics.get("built_in_fallback_only_count"),
        "total_card_entries": total_cards,
        "fallback_touched_count": len(fallback_touched),
        "non_fallback_supported_count": non_fallback_supported,
        "all_fallback_have_non_fallback_source": all_fallback_have_non_fallback_source,
        "fallback_only_count": len(fallback_only),
        "fallback_only_cards": _sorted_card_names(fallback_only),
        "learned_plus_fallback_only_count": len(learned_plus_fallback_only),
        "learned_plus_fallback_only_cards": _sorted_card_names(learned_plus_fallback_only),
        "fallback_without_profile_or_stats_count": len(
            fallback_without_profile_or_stats
        ),
        "fallback_without_profile_or_stats_cards": _sorted_card_names(
            fallback_without_profile_or_stats
        ),
        "fallback_profile_stats_only_count": len(fallback_profile_stats_only),
        "fallback_profile_stats_only_cards": _sorted_card_names(
            fallback_profile_stats_only
        ),
        "fallback_profile_stats_no_empirical_support_count": len(
            fallback_profile_stats_no_empirical_support
        ),
        "fallback_profile_stats_no_empirical_support_cards": _sorted_card_names(
            fallback_profile_stats_no_empirical_support
        ),
        "priorities": priorities,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--summary", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    summary_path = Path(args.summary)
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    payload = json.loads(summary_path.read_text(encoding="utf-8"))
    summary = build_summary(payload)
    output_path.write_text(
        json.dumps(summary, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        json.dumps(
            {
                "event": "COMMANDER_GENERATOR_SOURCE_MIX_AUDIT",
                "output": str(output_path),
                "commander_name": summary["commander_name"],
                "fallback_touched_count": summary["fallback_touched_count"],
                "fallback_only_count": summary["fallback_only_count"],
                "learned_plus_fallback_only_count": summary[
                    "learned_plus_fallback_only_count"
                ],
                "fallback_without_profile_or_stats_count": summary[
                    "fallback_without_profile_or_stats_count"
                ],
                "fallback_profile_stats_no_empirical_support_count": summary[
                    "fallback_profile_stats_no_empirical_support_count"
                ],
            },
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
