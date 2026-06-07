#!/usr/bin/env python3
"""Apply an approved full-confirmation optimizer swap with rollback data."""

from __future__ import annotations

import argparse
import json

from master_optimizer_common import (
    REPORT_DIR,
    assert_current_deck_matches_baseline,
    card_metadata,
    connect,
    deck_hash,
    deck_rows,
    ensure_optimizer_tables,
    get_deck_summary,
    latest_baseline,
    quality_gate_candidate,
    utc_now,
    write_report,
)


def row_to_dict(row) -> dict[str, object]:
    return {key: row[key] for key in row.keys()}


def find_candidate(conn, deck_id: int, baseline, card_added: str, min_delta: float):
    params: list[object] = [
        deck_id,
        int(baseline["id"]),
        str(baseline["deck_hash"]),
        min_delta,
    ]
    extra = ""
    if card_added:
        extra = "AND lower(card_added)=lower(?)"
        params.append(card_added)
    return conn.execute(
        f"""
        SELECT * FROM swap_benchmarks
        WHERE phase='full_confirmation'
          AND deck_id=?
          AND baseline_id=?
          AND baseline_hash=?
          AND COALESCE(applied, 0)=0
          AND delta_pp >= ?
          {extra}
        ORDER BY delta_pp DESC, wr DESC, id DESC
        LIMIT 1
        """,
        params,
    ).fetchone()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--card-added", default="")
    parser.add_argument("--min-delta", type=float, default=0.5)
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    with connect() as conn:
        ensure_optimizer_tables(conn)
        baseline = latest_baseline(conn, args.deck_id)
        if not baseline:
            raise SystemExit("No approved baseline found. Run master_optimizer_baseline.py first.")
        try:
            assert_current_deck_matches_baseline(conn, args.deck_id, baseline)
        except RuntimeError as exc:
            raise SystemExit(str(exc)) from exc
        candidate = find_candidate(conn, args.deck_id, baseline, args.card_added, args.min_delta)
        if not candidate:
            raise SystemExit("No unapplied approved full_confirmation candidate found.")

        added = candidate["card_added"]
        removed = candidate["card_removed"]
        review = quality_gate_candidate(conn, args.deck_id, added, removed, "apply")
        if review["status"] != "passed":
            raise SystemExit(
                "Quality gate blocked apply: " + ", ".join(review["reasons"])
            )

        before_rows = [row_to_dict(row) for row in deck_rows(conn, args.deck_id)]
        before_hash = deck_hash(conn, args.deck_id)
        removed_rows = [
            row
            for row in before_rows
            if str(row["card_name"]).lower() == str(removed).lower()
        ]
        if not removed_rows:
            raise SystemExit(f"Removed card not found in deck: {removed}")
        if any(str(row["card_name"]).lower() == str(added).lower() for row in before_rows):
            raise SystemExit(f"Added card already present in deck: {added}")

        meta = card_metadata(conn, added)
        conn.execute(
            "DELETE FROM deck_cards WHERE deck_id=? AND lower(card_name)=lower(?)",
            (args.deck_id, removed),
        )
        conn.execute(
            """
            INSERT INTO deck_cards
                (deck_id, card_name, quantity, functional_tag, tag_confidence,
                 is_commander, is_partner, cmc, type_line, oracle_text)
            VALUES (?, ?, 1, ?, NULL, 0, 0, ?, ?, ?)
            """,
            (
                args.deck_id,
                added,
                candidate["add_tag"] or candidate["add_effect"] or "candidate",
                meta["cmc"] if meta else candidate["add_cmc"],
                meta["type_line"] if meta else None,
                meta["oracle_text"] if meta else None,
            ),
        )
        after_hash = deck_hash(conn, args.deck_id)
        after_summary = get_deck_summary(conn, args.deck_id)

        REPORT_DIR.mkdir(parents=True, exist_ok=True)
        rollback_path = REPORT_DIR / f"master_optimizer_rollback_{utc_now().replace(':', '').replace('-', '').replace('.', '')}.json"
        rollback_payload = {
            "deck_id": args.deck_id,
            "swap_benchmark_id": candidate["id"],
            "card_added": added,
            "card_removed": removed,
            "before_hash": before_hash,
            "after_hash": after_hash,
            "before_rows": before_rows,
            "created_at": utc_now(),
        }
        rollback_path.write_text(
            json.dumps(rollback_payload, indent=2, ensure_ascii=True) + "\n",
            encoding="utf-8",
        )

        conn.execute(
            "UPDATE swap_benchmarks SET applied=1 WHERE id=?",
            (candidate["id"],),
        )
        conn.execute(
            """
            INSERT INTO optimizer_applied_swaps
                (deck_id, swap_benchmark_id, card_added, card_removed,
                 before_hash, after_hash, rollback_path, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                args.deck_id,
                candidate["id"],
                added,
                removed,
                before_hash,
                after_hash,
                str(rollback_path),
                utc_now(),
            ),
        )
        conn.commit()

    markdown = "\n".join(
        [
            "# Hermes Master Optimizer Apply",
            "",
            f"- deck_id: {args.deck_id}",
            f"- swap_benchmark_id: {candidate['id']}",
            f"- applied: `{added}` over `{removed}`",
            f"- confirmation_wr: {float(candidate['wr']):.1f}%",
            f"- confirmation_delta: {float(candidate['delta_pp']):+.1f}pp",
            f"- before_hash: `{before_hash}`",
            f"- after_hash: `{after_hash}`",
            f"- rollback_path: `{rollback_path}`",
            f"- deck_cards_after: {after_summary['cards']}",
            f"- lands_after: {after_summary['lands']}",
            f"- avg_cmc_after: {after_summary['avg_cmc']}",
            "",
            "No production database was mutated. This applies only to the Hermes local SQLite knowledge deck.",
        ]
    ) + "\n"
    print(markdown)
    if args.report:
        path = write_report("master_optimizer_apply", markdown)
        print(f"Report written: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
