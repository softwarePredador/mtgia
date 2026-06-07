#!/usr/bin/env python3
"""Confirm promising slot-scan candidates with safe temporary swaps."""

from __future__ import annotations

import argparse
import json

from master_optimizer_common import (
    candidate_rows,
    connect,
    ensure_optimizer_tables,
    latest_baseline,
    quality_gate_candidate,
    run_battle,
    temporary_swap,
    utc_now,
    write_report,
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--candidate-limit", type=int, default=25)
    parser.add_argument("--run-limit", type=int, default=3)
    parser.add_argument("--games", type=int, default=10)
    parser.add_argument("--min-scan-delta", type=float, default=-2.0)
    parser.add_argument(
        "--phase",
        choices=("confirmation", "full_confirmation"),
        default="confirmation",
    )
    parser.add_argument(
        "--include-existing",
        action="store_true",
        help="Allow retesting candidates already present in swap_benchmarks.",
    )
    parser.add_argument(
        "--only-added",
        default="",
        help="Restrict confirmation to a single added card name.",
    )
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    tested = []
    blocked = []
    skipped = []

    with connect() as conn:
        ensure_optimizer_tables(conn)
        baseline = latest_baseline(conn, args.deck_id)
        if not baseline:
            raise SystemExit("No approved baseline found. Run master_optimizer_baseline.py first.")

        baseline_wr = float(baseline["wr"])
        candidates = candidate_rows(
            conn,
            args.candidate_limit,
            baseline_wr,
            include_existing=args.include_existing,
            only_added=args.only_added,
        )

        for row in candidates:
            scan_delta = float(row["wr"] or 0) - baseline_wr
            if scan_delta < args.min_scan_delta:
                skipped.append(
                    {
                        "card_added": row["card_added"],
                        "card_removed": row["card_removed"],
                        "scan_wr": row["wr"],
                        "reason": f"scan_delta_below_threshold:{scan_delta:.1f}",
                    }
                )
                continue

            review = quality_gate_candidate(
                conn,
                args.deck_id,
                row["card_added"],
                row["card_removed"],
                args.phase,
            )
            if review["status"] != "passed":
                blocked.append(
                    {
                        "card_added": row["card_added"],
                        "card_removed": row["card_removed"],
                        "scan_wr": row["wr"],
                        "reasons": review["reasons"],
                    }
                )
                continue

            with temporary_swap(
                conn,
                args.deck_id,
                row["card_added"],
                row["card_removed"],
                row["category"],
            ):
                result = run_battle(args.games)

            delta = result.win_rate - baseline_wr
            conn.execute(
                """
                INSERT INTO swap_benchmarks
                    (card_added, card_removed, add_cmc, add_effect, add_tag,
                     wr, wins, losses, draws, games, phase, delta_pp, applied,
                     tested_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)
                """,
                (
                    row["card_added"],
                    row["card_removed"],
                    row["add_cmc"],
                    row["add_effect"],
                    row["category"],
                    result.win_rate,
                    result.wins,
                    result.losses,
                    result.stalls,
                    result.total_games,
                    args.phase,
                    delta,
                    utc_now(),
                ),
            )
            conn.commit()
            tested.append(
                {
                    "card_added": row["card_added"],
                    "card_removed": row["card_removed"],
                    "category": row["category"],
                    "scan_wr": row["wr"],
                    "confirm_wr": result.win_rate,
                    "delta": delta,
                    "record": f"{result.wins}W/{result.losses}L/{result.stalls}S",
                    "warnings": review["warnings"],
                }
            )
            if len(tested) >= args.run_limit:
                break

    lines = [
        "# Hermes Master Optimizer Confirmation",
        "",
        f"- deck_id: {args.deck_id}",
        f"- baseline_id: {baseline['id']}",
        f"- baseline_wr: {baseline_wr:.1f}%",
        f"- phase: {args.phase}",
        f"- games_per_opponent: {args.games}",
        f"- tested: {len(tested)}",
        f"- blocked: {len(blocked)}",
        f"- skipped: {len(skipped)}",
        "",
        "## Tested",
        "",
        "| Add | Cut | Category | Scan WR | Confirm WR | Delta | Record | Warnings |",
        "| --- | --- | --- | ---: | ---: | ---: | --- | --- |",
    ]
    for item in tested:
        warnings = ", ".join(item["warnings"]) or "-"
        lines.append(
            f"| {item['card_added']} | {item['card_removed']} | {item['category']} | "
            f"{float(item['scan_wr']):.1f}% | {float(item['confirm_wr']):.1f}% | "
            f"{float(item['delta']):+.1f}pp | {item['record']} | {warnings} |"
        )

    lines.extend(["", "## Blocked", "", "| Add | Cut | Scan WR | Reasons |", "| --- | --- | ---: | --- |"])
    for item in blocked[:25]:
        reasons = ", ".join(item["reasons"])
        lines.append(
            f"| {item['card_added']} | {item['card_removed']} | "
            f"{float(item['scan_wr']):.1f}% | {reasons} |"
        )

    lines.extend(["", "## Skipped", "", "| Add | Cut | Scan WR | Reason |", "| --- | --- | ---: | --- |"])
    for item in skipped[:25]:
        lines.append(
            "| {card_added} | {card_removed} | {scan_wr:.1f}% | {reason} |".format(**item)
        )

    markdown = "\n".join(lines) + "\n"
    print(markdown)
    if args.report:
        path = write_report("master_optimizer_confirmation", markdown)
        print(f"Report written: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
