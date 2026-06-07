#!/usr/bin/env python3
"""Create a product-facing handoff for a Hermes-approved swap.

Hermes local SQLite is a learning sandbox. This script creates the explicit
approval package required before copying an approved swap into any real app or
production-facing deck.
"""

from __future__ import annotations

import argparse
import json
import sqlite3

from master_optimizer_common import (
    connect,
    ensure_optimizer_tables,
    get_deck_summary,
    latest_baseline,
    utc_now,
    write_report,
)


def latest_applied_swap(conn: sqlite3.Connection, deck_id: int, applied_swap_id: int | None):
    if applied_swap_id:
        return conn.execute(
            "SELECT * FROM optimizer_applied_swaps WHERE deck_id=? AND id=?",
            (deck_id, applied_swap_id),
        ).fetchone()
    return conn.execute(
        """
        SELECT * FROM optimizer_applied_swaps
        WHERE deck_id=?
        ORDER BY id DESC
        LIMIT 1
        """,
        (deck_id,),
    ).fetchone()


def swap_confirmation(conn: sqlite3.Connection, card_added: str, card_removed: str):
    return conn.execute(
        """
        SELECT * FROM swap_benchmarks
        WHERE card_added=? AND card_removed=? AND phase='full_confirmation'
        ORDER BY id DESC
        LIMIT 1
        """,
        (card_added, card_removed),
    ).fetchone()


def render_report(deck_summary, baseline, applied, confirmation) -> tuple[str, dict[str, object]]:
    approval = {
        "status": "needs_product_owner_approval",
        "hermes_local_apply_done": True,
        "production_mutation_allowed": False,
        "required_checks": [
            "Confirm target product deck id and environment.",
            "Create product deck backup before mutation.",
            "Run product dry-run diff and verify 100-card Commander legality.",
            "Run app/API smoke test after mutation.",
            "Attach Hermes confirmation and post-apply baseline reports.",
            "Get explicit human approval before production-facing apply.",
        ],
    }
    confirmation_wr = confirmation["wr"] if confirmation else None
    confirmation_delta = confirmation["delta_pp"] if confirmation else None
    confirmation_record = (
        f"{confirmation['wins']}W/{confirmation['losses']}L/{confirmation['draws']}S"
        if confirmation
        else "missing"
    )
    lines = [
        "# Hermes Product Apply Handoff",
        "",
        f"- status: {approval['status']}",
        f"- deck_id: {deck_summary['deck_id']}",
        f"- current_hermes_hash: `{deck_summary['hash']}`",
        f"- current_cards: {deck_summary['cards']}",
        f"- current_lands: {deck_summary['lands']}",
        f"- current_avg_cmc: {deck_summary['avg_cmc']}",
        f"- latest_baseline_id: {baseline['id'] if baseline else 'missing'}",
        f"- applied_swap_id: {applied['id']}",
        f"- swap: `{applied['card_added']}` over `{applied['card_removed']}`",
        f"- hermes_before_hash: `{applied['before_hash']}`",
        f"- hermes_after_hash: `{applied['after_hash']}`",
        f"- hermes_rollback: `{applied['rollback_path']}`",
        f"- full_confirmation_wr: {confirmation_wr if confirmation_wr is not None else 'missing'}%",
        f"- full_confirmation_delta_pp: {confirmation_delta if confirmation_delta is not None else 'missing'}",
        f"- full_confirmation_record: {confirmation_record}",
        "",
        "## Product Gate",
        "",
        "- This handoff does not mutate production.",
        "- Product-facing mutation remains blocked until explicit approval.",
        "- The Hermes rollback file is not enough for production rollback; create a product backup first.",
        "",
        "## Required Checks",
        "",
    ]
    for item in approval["required_checks"]:
        lines.append(f"- [ ] {item}")
    lines.extend(
        [
            "",
            "## Apply Instruction After Approval",
            "",
            "Only after all checks are approved, copy this exact swap to the target product deck:",
            "",
            f"- add: `{applied['card_added']}`",
            f"- remove: `{applied['card_removed']}`",
            "",
            "Do not run generic optimizer auto-apply against product data.",
        ]
    )
    return "\n".join(lines) + "\n", approval


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--applied-swap-id", type=int)
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    with connect() as conn:
        ensure_optimizer_tables(conn)
        applied = latest_applied_swap(conn, args.deck_id, args.applied_swap_id)
        if not applied:
            raise SystemExit("No Hermes-local applied swap found for this deck.")
        deck_summary = get_deck_summary(conn, args.deck_id)
        baseline = latest_baseline(conn, args.deck_id)
        confirmation = swap_confirmation(conn, applied["card_added"], applied["card_removed"])
        markdown, approval = render_report(deck_summary, baseline, applied, confirmation)
        report_path = ""
        if args.report:
            report_path = str(write_report("master_optimizer_product_handoff", markdown))
        conn.execute(
            """
            INSERT INTO optimizer_product_handoffs
                (deck_id, applied_swap_id, status, report_path, approval_json, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                args.deck_id,
                applied["id"],
                approval["status"],
                report_path,
                json.dumps(approval, ensure_ascii=True, sort_keys=True),
                utc_now(),
            ),
        )
        conn.commit()

    print(markdown)
    if report_path:
        print(f"Report written: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
