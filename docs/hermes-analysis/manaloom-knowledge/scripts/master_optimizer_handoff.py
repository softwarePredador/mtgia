#!/usr/bin/env python3
"""Generate the final safe optimizer handoff report."""

from __future__ import annotations

import argparse
import json

from master_optimizer_common import (
    assert_current_deck_matches_baseline,
    connect,
    ensure_optimizer_tables,
    latest_baseline,
    utc_now,
    write_report,
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    with connect() as conn:
        ensure_optimizer_tables(conn)
        baseline = latest_baseline(conn, args.deck_id)
        if not baseline:
            raise SystemExit("No approved baseline found. Run baseline first.")
        try:
            assert_current_deck_matches_baseline(conn, args.deck_id, baseline)
        except RuntimeError as exc:
            raise SystemExit(str(exc)) from exc
        confirmations = conn.execute(
            """
            SELECT * FROM swap_benchmarks
            WHERE phase IN ('confirmation', 'full_confirmation')
              AND deck_id=?
              AND baseline_id=?
              AND baseline_hash=?
            ORDER BY tested_at DESC, id DESC
            LIMIT 20
            """,
            (args.deck_id, int(baseline["id"]), str(baseline["deck_hash"])),
        ).fetchall()
        approved = [
            row
            for row in confirmations
            if row["phase"] == "full_confirmation" and float(row["delta_pp"] or 0) >= 0.5
        ]
        blocked = conn.execute(
            """
            SELECT * FROM optimizer_quality_reviews
            WHERE deck_id=? AND status='blocked'
            ORDER BY id DESC
            LIMIT 20
            """,
            (args.deck_id,),
        ).fetchall()

    status = "approved_swaps_ready_for_manual_apply" if approved else "no_safe_swap_approved"
    lines = [
        "# Hermes Master Optimizer Handoff",
        "",
        f"- deck_id: {args.deck_id}",
        f"- baseline_id: {baseline['id']}",
        f"- baseline_wr: {float(baseline['wr']):.1f}%",
        f"- baseline_record: {baseline['wins']}W/{baseline['losses']}L/{baseline['stalls']}S",
        f"- status: {status}",
        "",
        "## Confirmed Candidates",
        "",
        "| Verdict | Phase | Add | Cut | Confirm WR | Delta | Record |",
        "| --- | --- | --- | --- | ---: | ---: | --- |",
    ]
    for row in confirmations:
        delta = float(row["delta_pp"] or 0)
        if row["phase"] == "full_confirmation" and delta >= 0.5:
            verdict = "approve_manual_review"
        elif row["phase"] == "confirmation" and delta >= 0.5:
            verdict = "candidate_needs_full_confirmation"
        else:
            verdict = "reject_or_retest"
        lines.append(
            f"| {verdict} | {row['phase']} | {row['card_added']} | {row['card_removed']} | "
            f"{float(row['wr']):.1f}% | {delta:+.1f}pp | "
            f"{row['wins']}W/{row['losses']}L/{row['draws']}S |"
        )
    if not confirmations:
        lines.append("| none | - | - | - | - | - | No confirmation rows yet. |")

    lines.extend(
        [
            "",
            "## Quality Blocks",
            "",
            "| Add | Cut | Reasons |",
            "| --- | --- | --- |",
        ]
    )
    for row in blocked:
        reasons = ", ".join(json.loads(row["reasons_json"] or "[]")) or "-"
        lines.append(f"| {row['card_added']} | {row['card_removed']} | {reasons} |")
    if not blocked:
        lines.append("| - | - | No blocked candidates in latest review window. |")

    lines.extend(
        [
            "",
            "## Next Action",
            "",
        ]
    )
    if approved:
        lines.append(
            "Manual review can inspect the approved rows, then apply with a dedicated "
            "rollback-aware apply script. No automatic apply happened in this run."
        )
    else:
        lines.append(
            "No swap is currently safe to apply. Keep the current deck, improve cut-target "
            "selection, expand legal Boros candidates, or run a deeper confirmation pass."
        )

    markdown = "\n".join(lines) + "\n"
    print(markdown)
    report_path = ""
    if args.report:
        path = write_report("master_optimizer_handoff", markdown)
        report_path = str(path)
        print(f"Report written: {path}")

    with connect() as conn:
        ensure_optimizer_tables(conn)
        conn.execute(
            """
            INSERT INTO optimizer_handoffs
                (deck_id, baseline_id, status, report_path, summary_json, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                args.deck_id,
                int(baseline["id"]),
                status,
                report_path,
                json.dumps({"approved_count": len(approved), "confirmed_count": len(confirmations)}),
                utc_now(),
            ),
        )
        conn.commit()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
