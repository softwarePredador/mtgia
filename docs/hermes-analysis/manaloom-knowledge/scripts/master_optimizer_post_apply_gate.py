#!/usr/bin/env python3
"""Validate the post-apply baseline and optionally rollback failed Hermes swaps."""

from __future__ import annotations

import argparse
import sqlite3
from pathlib import Path

from master_optimizer_common import connect, ensure_optimizer_tables, latest_baseline, write_report
from master_optimizer_rollback import rollback

ROLLBACK_EXIT = 20


def latest_applied(conn: sqlite3.Connection, deck_id: int):
    return conn.execute(
        """
        SELECT * FROM optimizer_applied_swaps
        WHERE deck_id=?
        ORDER BY id DESC
        LIMIT 1
        """,
        (deck_id,),
    ).fetchone()


def swap_row(conn: sqlite3.Connection, swap_benchmark_id: int):
    return conn.execute(
        "SELECT * FROM swap_benchmarks WHERE id=?",
        (swap_benchmark_id,),
    ).fetchone()


def baseline_by_id(conn: sqlite3.Connection, baseline_id: int):
    return conn.execute(
        "SELECT * FROM optimizer_baseline_runs WHERE id=?",
        (baseline_id,),
    ).fetchone()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument(
        "--min-post-delta",
        type=float,
        default=0.0,
        help="Minimum post-apply baseline delta required versus the pre-apply baseline.",
    )
    parser.add_argument("--rollback-on-fail", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    with connect() as conn:
        ensure_optimizer_tables(conn)
        applied = latest_applied(conn, args.deck_id)
        if not applied:
            raise SystemExit("No applied swap found for post-apply gate.")
        swap = swap_row(conn, int(applied["swap_benchmark_id"]))
        if not swap:
            raise SystemExit("Applied swap has no swap_benchmarks row.")
        before_baseline = baseline_by_id(conn, int(swap["baseline_id"]))
        if not before_baseline:
            raise SystemExit("Applied swap has no pre-apply baseline row.")
        post_baseline = latest_baseline(conn, args.deck_id)
        if not post_baseline:
            raise SystemExit("No post-apply baseline found.")
        if str(post_baseline["deck_hash"]) != str(applied["after_hash"]):
            raise SystemExit(
                "Latest baseline does not match applied after_hash. "
                "Run post-apply baseline before post-apply gate."
            )

        before_wr = float(before_baseline["wr"])
        post_wr = float(post_baseline["wr"])
        full_wr = float(swap["wr"])
        full_delta = float(swap["delta_pp"])
        post_delta = post_wr - before_wr
        should_rollback = post_delta < args.min_post_delta

    rolled_back = False
    rollback_reason = (
        f"post_apply_delta_below_threshold:{post_delta:+.1f}pp < {args.min_post_delta:+.1f}pp"
    )
    if should_rollback and args.rollback_on_fail:
        rollback(Path(str(applied["rollback_path"])), rollback_reason)
        rolled_back = True

    status = "rolled_back" if rolled_back else "failed_needs_review" if should_rollback else "approved"
    markdown = "\n".join(
        [
            "# Hermes Post-Apply Gate",
            "",
            f"- deck_id: {args.deck_id}",
            f"- applied_swap_id: {applied['id']}",
            f"- swap_benchmark_id: {applied['swap_benchmark_id']}",
            f"- swap: `{applied['card_added']}` over `{applied['card_removed']}`",
            f"- status: {status}",
            f"- pre_apply_baseline_id: {before_baseline['id']}",
            f"- pre_apply_wr: {before_wr:.1f}%",
            f"- full_confirmation_wr: {full_wr:.1f}%",
            f"- full_confirmation_delta: {full_delta:+.1f}pp",
            f"- post_apply_baseline_id: {post_baseline['id']}",
            f"- post_apply_wr: {post_wr:.1f}%",
            f"- post_apply_delta: {post_delta:+.1f}pp",
            f"- min_post_delta: {args.min_post_delta:+.1f}pp",
            f"- rollback_path: `{applied['rollback_path']}`",
            "",
            "No production database was mutated.",
        ]
    ) + "\n"
    print(markdown)
    if args.report:
        path = write_report("master_optimizer_post_apply_gate", markdown)
        print(f"Report written: {path}")
    return ROLLBACK_EXIT if rolled_back else 1 if should_rollback else 0


if __name__ == "__main__":
    raise SystemExit(main())
