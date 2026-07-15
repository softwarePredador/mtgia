#!/usr/bin/env python3
"""Review optimizer candidates before any confirmation run."""

from __future__ import annotations

import argparse
import json

from master_optimizer_common import (
    assert_current_deck_matches_baseline,
    battle_gate_report_lines,
    candidate_rows,
    connect,
    ensure_optimizer_tables,
    latest_baseline,
    quality_gate_candidate,
    require_battle_gate_for_optimizer,
    write_report,
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--limit", type=int, default=25)
    parser.add_argument("--phase", default="best-in-slot,phase1")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()
    phases = tuple(item.strip() for item in args.phase.split(",") if item.strip())

    try:
        require_battle_gate_for_optimizer()
    except RuntimeError as exc:
        raise SystemExit(str(exc)) from exc

    with connect() as conn:
        ensure_optimizer_tables(conn)
        baseline = latest_baseline(conn, args.deck_id)
        if not baseline:
            raise SystemExit("No approved baseline found. Run master_optimizer_baseline.py first.")
        try:
            assert_current_deck_matches_baseline(conn, args.deck_id, baseline)
        except RuntimeError as exc:
            raise SystemExit(str(exc)) from exc
        rows = candidate_rows(
            conn,
            args.limit,
            float(baseline["wr"]),
            deck_id=args.deck_id,
            baseline_id=int(baseline["id"]),
            baseline_hash=str(baseline["deck_hash"]),
            phases=phases,
        )
        reviews = []
        for row in rows:
            review = quality_gate_candidate(
                conn,
                args.deck_id,
                row["card_added"],
                row["card_removed"],
                "slot_benchmarks",
            )
            reviews.append((row, review))

    lines = [
        "# Hermes Master Optimizer Quality Gate",
        "",
        f"- deck_id: {args.deck_id}",
        f"- baseline_id: {baseline['id']}",
        f"- baseline_hash: `{baseline['deck_hash']}`",
        f"- baseline_semantics_hash: `{baseline['semantics_hash'] or 'legacy-missing'}`",
        f"- baseline_ruleset_hash: `{baseline['ruleset_hash'] or 'legacy-missing'}`",
        f"- baseline_wr: {float(baseline['wr']):.1f}%",
        f"- phases: `{','.join(phases)}`",
        f"- candidates_reviewed: {len(reviews)}",
        "",
    ]
    lines.extend(battle_gate_report_lines())
    lines.extend([
        "| Status | Category | Add | Cut | Scan WR | Reasons | Warnings |",
        "| --- | --- | --- | --- | ---: | --- | --- |",
    ])
    for row, review in reviews:
        lines.append(
            "| {status} | {category} | {add} | {cut} | {wr:.1f}% | {reasons} | {warnings} |".format(
                status=review["status"],
                category=row["category"],
                add=row["card_added"],
                cut=row["card_removed"],
                wr=float(row["wr"] or 0),
                reasons=", ".join(review["reasons"]) or "-",
                warnings=", ".join(review["warnings"]) or "-",
            )
        )
    markdown = "\n".join(lines) + "\n"
    print(markdown)
    if args.report:
        path = write_report("master_optimizer_quality_gate", markdown)
        print(f"Report written: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
