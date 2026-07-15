#!/usr/bin/env python3
"""Freeze the current Lorehold deck baseline with a real battle run."""

from __future__ import annotations

import argparse
import json

from master_optimizer_common import (
    battle_gate_report_lines,
    connect,
    ensure_optimizer_tables,
    get_deck_summary,
    require_battle_gate_for_optimizer,
    run_battle,
    utc_now,
    write_report,
)


def render_report(deck_summary: dict[str, object], result, baseline_id: int) -> str:
    lines = [
        "# Hermes Master Optimizer Baseline",
        "",
        f"- baseline_id: {baseline_id}",
        f"- deck_id: {deck_summary['deck_id']}",
        f"- deck_hash: `{deck_summary['hash']}`",
        f"- semantics_hash: `{deck_summary['semantics_hash']}`",
        f"- ruleset_hash: `{deck_summary['ruleset_hash']}`",
        f"- cards: {deck_summary['cards']}",
        f"- lands: {deck_summary['lands']}",
        f"- avg_cmc: {deck_summary['avg_cmc']}",
        f"- games_per_opponent: {result.games_per_opponent}",
        f"- opponents: {result.opponents}",
        f"- total_games: {result.total_games}",
        f"- overall_wr: {result.win_rate:.1f}%",
        f"- record: {result.wins}W/{result.losses}L/{result.stalls}S",
        "",
    ]
    lines.extend(battle_gate_report_lines())
    lines.extend([
        "## Matchups",
        "",
        "| Opponent | WR | W | L | S | Avg Turn | Reasons |",
        "| --- | ---: | ---: | ---: | ---: | ---: | --- |",
    ])
    for matchup in result.matchups:
        lines.append(
            "| {opponent} | {wr:.1f}% | {wins} | {losses} | {stalls} | "
            "{avg_turn:.1f} | {reasons} |".format(**matchup)
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--games", type=int, default=50)
    parser.add_argument("--opponent-limit", type=int, default=3)
    parser.add_argument("--opponent-seed", type=int, default=20260626)
    parser.add_argument("--simulation-seed", type=int, default=42)
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    try:
        require_battle_gate_for_optimizer()
    except RuntimeError as exc:
        raise SystemExit(str(exc)) from exc

    with connect() as conn:
        ensure_optimizer_tables(conn)
        deck_summary = get_deck_summary(conn, args.deck_id)
        result = run_battle(
            args.games,
            deck_id=args.deck_id,
            opponent_limit=max(1, int(args.opponent_limit)),
            opponent_seed=int(args.opponent_seed),
            simulation_seed=int(args.simulation_seed),
        )
        created_at = utc_now()
        payload = {
            "deck": deck_summary,
            "matchups": result.matchups,
            "stdout_tail": result.stdout[-4000:],
        }
        cur = conn.execute(
            """
            INSERT INTO optimizer_baseline_runs
                (deck_id, deck_hash, semantics_hash, ruleset_hash,
                 games_per_opponent, opponents, total_games, wr, wins, losses,
                 stalls, status, result_json, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'approved', ?, ?)
            """,
            (
                args.deck_id,
                deck_summary["hash"],
                deck_summary["semantics_hash"],
                deck_summary["ruleset_hash"],
                result.games_per_opponent,
                result.opponents,
                result.total_games,
                result.win_rate,
                result.wins,
                result.losses,
                result.stalls,
                json.dumps(payload, ensure_ascii=True),
                created_at,
            ),
        )
        baseline_id = int(cur.lastrowid)
        conn.commit()

    markdown = render_report(deck_summary, result, baseline_id)
    print(markdown)
    if args.report:
        path = write_report("master_optimizer_baseline", markdown)
        print(f"Report written: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
