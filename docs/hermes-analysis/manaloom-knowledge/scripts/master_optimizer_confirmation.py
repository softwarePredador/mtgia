#!/usr/bin/env python3
"""Confirm promising slot-scan candidates with safe temporary swaps."""

from __future__ import annotations

import argparse
import json

from master_optimizer_common import (
    BattleRunTimeout,
    assert_current_deck_matches_baseline,
    battle_gate_report_lines,
    candidate_rows,
    connect,
    ensure_optimizer_tables,
    latest_baseline,
    quality_gate_candidate,
    require_battle_gate_for_optimizer,
    run_battle,
    temporary_swap,
    utc_now,
    write_report,
)


def confirmed_candidate_rows(
    conn,
    *,
    deck_id: int,
    baseline_id: int,
    baseline_hash: str,
    baseline_wr: float,
    limit: int,
    include_existing: bool,
    only_added: str,
):
    where = [
        "phase='confirmation'",
        "deck_id=?",
        "baseline_id=?",
        "baseline_hash=?",
    ]
    params: list[object] = [deck_id, baseline_id, baseline_hash]
    if not include_existing:
        where.append(
            """
            card_added NOT IN (
                SELECT card_added FROM swap_benchmarks
                WHERE phase='full_confirmation'
                  AND deck_id=?
                  AND baseline_id=?
                  AND baseline_hash=?
            )
            """
        )
        params.extend([deck_id, baseline_id, baseline_hash])
    if only_added:
        where.append("lower(card_added)=lower(?)")
        params.append(only_added)
    params.append(limit)
    return conn.execute(
        f"""
        SELECT
            add_tag AS category,
            card_added,
            card_removed,
            add_cmc,
            add_effect,
            wr,
            wins,
            losses,
            draws,
            games,
            delta_pp,
            phase,
            tested_at
        FROM swap_benchmarks
        WHERE {' AND '.join(where)}
        ORDER BY delta_pp DESC, wr DESC, id DESC
        LIMIT ?
        """,
        params,
    ).fetchall()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--candidate-limit", type=int, default=25)
    parser.add_argument("--run-limit", type=int, default=3)
    parser.add_argument("--games", type=int, default=10)
    parser.add_argument("--battle-timeout-seconds", type=int, default=1200)
    parser.add_argument("--opponent-limit", type=int, default=3)
    parser.add_argument("--opponent-seed", type=int, default=20260626)
    parser.add_argument("--simulation-seed", type=int, default=42)
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

    try:
        require_battle_gate_for_optimizer()
    except RuntimeError as exc:
        raise SystemExit(str(exc)) from exc

    tested = []
    blocked = []
    skipped = []

    with connect() as conn:
        ensure_optimizer_tables(conn)
        baseline = latest_baseline(conn, args.deck_id)
        if not baseline:
            raise SystemExit("No approved baseline found. Run master_optimizer_baseline.py first.")
        try:
            assert_current_deck_matches_baseline(conn, args.deck_id, baseline)
        except RuntimeError as exc:
            raise SystemExit(str(exc)) from exc

        baseline_wr = float(baseline["wr"])
        baseline_id = int(baseline["id"])
        baseline_hash = str(baseline["deck_hash"])
        if args.phase == "full_confirmation":
            candidates = confirmed_candidate_rows(
                conn,
                deck_id=args.deck_id,
                baseline_id=baseline_id,
                baseline_hash=baseline_hash,
                baseline_wr=baseline_wr,
                limit=args.candidate_limit,
                include_existing=args.include_existing,
                only_added=args.only_added,
            )
            if not candidates:
                candidates = candidate_rows(
                    conn,
                    args.candidate_limit,
                    baseline_wr,
                    deck_id=args.deck_id,
                    baseline_id=baseline_id,
                    baseline_hash=baseline_hash,
                    include_existing=args.include_existing,
                    only_added=args.only_added,
                )
        else:
            candidates = candidate_rows(
                conn,
                args.candidate_limit,
                baseline_wr,
                deck_id=args.deck_id,
                baseline_id=baseline_id,
                baseline_hash=baseline_hash,
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
                try:
                    result = run_battle(
                        args.games,
                        deck_id=args.deck_id,
                        timeout_seconds=max(1, int(args.battle_timeout_seconds)),
                        opponent_limit=max(1, int(args.opponent_limit)),
                        opponent_seed=int(args.opponent_seed),
                        simulation_seed=int(args.simulation_seed),
                    )
                except BattleRunTimeout as exc:
                    blocked.append(
                        {
                            "card_added": row["card_added"],
                            "card_removed": row["card_removed"],
                            "scan_wr": row["wr"],
                            "reasons": [f"battle_timeout_{exc.timeout_seconds}s"],
                        }
                    )
                    continue
                except RuntimeError as exc:
                    blocked.append(
                        {
                            "card_added": row["card_added"],
                            "card_removed": row["card_removed"],
                            "scan_wr": row["wr"],
                            "reasons": [f"battle_failed:{str(exc).strip() or type(exc).__name__}"],
                        }
                    )
                    continue

            delta = result.win_rate - baseline_wr
            conn.execute(
                """
                INSERT INTO swap_benchmarks
                    (deck_id, baseline_id, baseline_hash,
                     card_added, card_removed, add_cmc, add_effect, add_tag,
                     wr, wins, losses, draws, games, phase, delta_pp, applied,
                     tested_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)
                """,
                (
                    args.deck_id,
                    int(baseline["id"]),
                    str(baseline["deck_hash"]),
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
    ]
    lines.extend(battle_gate_report_lines())
    lines.extend([
        "## Tested",
        "",
        "| Add | Cut | Category | Scan WR | Confirm WR | Delta | Record | Warnings |",
        "| --- | --- | --- | ---: | ---: | ---: | --- | --- |",
    ])
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
