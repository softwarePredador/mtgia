#!/usr/bin/env python3
"""Freeze optimizer baseline from the official battle-strategy-audit summary."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from master_optimizer_common import (
    DEFAULT_BATTLE_GATE_SUMMARY,
    battle_gate_report_lines,
    connect,
    ensure_optimizer_tables,
    get_deck_summary,
    utc_now,
    write_report,
)


def gate_stats(summary: dict[str, object]) -> dict[str, object]:
    table_intent = dict(summary.get("mandatory_gate_statuses", {}).get("table_intent", {}))
    wins = summary.get("table_intent_target_wins", table_intent.get("target_wins"))
    losses = summary.get("table_intent_opponent_wins", table_intent.get("opponent_wins"))
    if wins is None or losses is None:
        raise ValueError("battle gate summary does not expose table_intent target/opponent wins")
    wins = int(wins)
    losses = int(losses)
    seeds_completed = summary.get("seeds_completed") or summary.get("seed_count")
    total_games = int(seeds_completed or (wins + losses))
    stalls = max(0, total_games - wins - losses)
    wr = (wins / total_games * 100.0) if total_games else 0.0
    return {
        "wins": wins,
        "losses": losses,
        "stalls": stalls,
        "total_games": total_games,
        "wr": wr,
    }


def render_report(
    deck_summary: dict[str, object],
    summary: dict[str, object],
    stats: dict[str, object],
    baseline_id: int,
    summary_path: Path,
) -> str:
    lines = [
        "# Hermes Master Optimizer Gate Baseline",
        "",
        f"- baseline_id: {baseline_id}",
        f"- deck_id: {deck_summary['deck_id']}",
        f"- deck_hash: `{deck_summary['hash']}`",
        f"- semantics_hash: `{deck_summary['semantics_hash']}`",
        f"- ruleset_hash: `{deck_summary['ruleset_hash']}`",
        f"- cards: {deck_summary['cards']}",
        f"- lands: {deck_summary['lands']}",
        f"- avg_cmc: {deck_summary['avg_cmc']}",
        f"- audit_summary: `{summary_path}`",
        f"- audit_run_dir: `{summary.get('run_dir') or summary_path.parent}`",
        f"- start_seed: {summary.get('start_seed') or '-'}",
        f"- total_games: {stats['total_games']}",
        f"- overall_wr: {float(stats['wr']):.1f}%",
        f"- record: {stats['wins']}W/{stats['losses']}L/{stats['stalls']}S",
        "",
    ]
    lines.extend(battle_gate_report_lines(summary))
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--summary", default=str(DEFAULT_BATTLE_GATE_SUMMARY))
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    summary_path = Path(args.summary)
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    summary["_summary_path"] = str(summary_path)
    stats = gate_stats(summary)

    with connect() as conn:
        ensure_optimizer_tables(conn)
        deck_summary = get_deck_summary(conn, args.deck_id)
        created_at = utc_now()
        payload = {
            "deck": deck_summary,
            "official_battle_strategy_summary": {
                "run_dir": str(summary.get("run_dir") or summary_path.parent),
                "summary_path": str(summary_path),
                "battle_replay_final_status": summary.get("battle_replay_final_status"),
                "mandatory_gate_divergences": summary.get("mandatory_gate_divergences") or [],
                "seeds_completed": stats["total_games"],
                "start_seed": summary.get("start_seed"),
                "table_intent_target_wins": stats["wins"],
                "table_intent_opponent_wins": stats["losses"],
            },
        }
        cur = conn.execute(
            """
            INSERT INTO optimizer_baseline_runs
                (deck_id, deck_hash, semantics_hash, ruleset_hash,
                 games_per_opponent, opponents, total_games, wr, wins, losses,
                 stalls, status, result_json, created_at, battle_version)
            VALUES (?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, 'approved', ?, ?,
                    'battle_strategy_audit_wrapper_v1')
            """,
            (
                args.deck_id,
                deck_summary["hash"],
                deck_summary["semantics_hash"],
                deck_summary["ruleset_hash"],
                stats["total_games"],
                stats["total_games"],
                stats["wr"],
                stats["wins"],
                stats["losses"],
                stats["stalls"],
                json.dumps(payload, ensure_ascii=True),
                created_at,
            ),
        )
        baseline_id = int(cur.lastrowid)
        conn.commit()

    markdown = render_report(deck_summary, summary, stats, baseline_id, summary_path)
    print(markdown)
    if args.report:
        path = write_report("master_optimizer_gate_baseline", markdown)
        print(f"Report written: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
