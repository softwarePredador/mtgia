#!/usr/bin/env python3
"""Aggregate replay/decision audit for the optimizer loop.

This first version audits real battle metrics already persisted by the baseline
runner. It is deliberately honest when turn-by-turn replay data is unavailable.
"""

from __future__ import annotations

import argparse
import json

from master_optimizer_common import connect, ensure_optimizer_tables, latest_baseline, write_report


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
        payload = json.loads(baseline["result_json"])
        matchups = payload.get("matchups", [])

    findings = []
    for matchup in matchups:
        wr = float(matchup.get("wr") or 0)
        reasons = str(matchup.get("reasons") or "")
        opponent = str(matchup.get("opponent") or "?")
        stalls = int(matchup.get("stalls") or 0)
        avg_turn = float(matchup.get("avg_turn") or 0)
        if wr < 40:
            findings.append(
                {
                    "severity": "high",
                    "opponent": opponent,
                    "finding": f"Low matchup WR {wr:.1f}%; needs replay review before optimizer trusts cuts.",
                }
            )
        if stalls > 0:
            findings.append(
                {
                    "severity": "medium",
                    "opponent": opponent,
                    "finding": f"{stalls} stalls; inspect for missed wincon or game-end condition.",
                }
            )
        if avg_turn > 15:
            findings.append(
                {
                    "severity": "medium",
                    "opponent": opponent,
                    "finding": f"Slow average win turn {avg_turn:.1f}; inspect sequencing and finisher timing.",
                }
            )
        if not reasons:
            findings.append(
                {
                    "severity": "medium",
                    "opponent": opponent,
                    "finding": "Missing win/loss reason detail; replay log needs richer structured events.",
                }
            )

    status = "needs_replay_detail" if findings else "aggregate_clean"
    lines = [
        "# Hermes Replay Decision Audit",
        "",
        f"- deck_id: {args.deck_id}",
        f"- baseline_id: {baseline['id']}",
        f"- status: {status}",
        f"- findings: {len(findings)}",
        "",
        "## Findings",
        "",
        "| Severity | Opponent | Finding |",
        "| --- | --- | --- |",
    ]
    for finding in findings:
        lines.append(
            f"| {finding['severity']} | {finding['opponent']} | {finding['finding']} |"
        )
    if not findings:
        lines.append("| info | all | No aggregate red flags found. |")

    lines.extend(
        [
            "",
            "## Limitation",
            "",
            "This audit uses aggregate battle output. The next hardening step is a "
            "turn-by-turn structured replay logger that records attacks, blocks, "
            "spell timing, tutor targets and counter/removal decisions.",
        ]
    )
    markdown = "\n".join(lines) + "\n"
    print(markdown)
    if args.report:
        path = write_report("master_optimizer_replay_audit", markdown)
        print(f"Report written: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
