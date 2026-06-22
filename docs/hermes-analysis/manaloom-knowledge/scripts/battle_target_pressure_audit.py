#!/usr/bin/env python3
"""Audit whether battle replay pressure is centered on the evaluated deck."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def _event_kind(event: dict[str, Any]) -> str:
    return str(event.get("event") or event.get("kind") or "")


def load_events(path: Path) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        events.append(json.loads(line))
    return events


def _has_evaluation_pressure_metadata(event: dict[str, Any]) -> bool:
    reason = str(event.get("target_reason") or "")
    pressure_reasons = {
        "evaluation_target_pressure",
        "lethal",
    }
    return bool(
        event.get("evaluation_target_active") is True
        and (reason in pressure_reasons or reason.startswith("table_intent_"))
    )


def _is_accepted_non_target_attack(event: dict[str, Any], table_intent_mode: bool) -> bool:
    reason = str(event.get("target_reason") or "")
    if table_intent_mode and reason.startswith("table_intent_"):
        return True
    if table_intent_mode and reason == "lethal":
        return True
    return False


def audit_events(events: list[dict[str, Any]], target_player: str) -> dict[str, Any]:
    table_intent_mode = any(
        _event_kind(event) == "combat" and event.get("table_intent_enabled") is True
        for event in events
    )
    summary: dict[str, Any] = {
        "status": "pass",
        "target_player": target_player,
        "table_intent_mode_detected": table_intent_mode,
        "events_total": len(events),
        "combat_total": 0,
        "opponent_combat_total": 0,
        "opponent_combat_to_target": 0,
        "opponent_combat_to_other": 0,
        "opponent_combat_to_other_table_intent_accepted": 0,
        "opponent_multi_defender_attack": 0,
        "opponent_multi_defender_attack_table_intent_accepted": 0,
        "opponent_combat_missing_pressure_reason": 0,
        "post_target_elimination_opponent_combat_ignored": 0,
        "target_player_eliminated": False,
        "target_player_combat_total": 0,
        "findings": 0,
        "violations": [],
    }

    target_alive = True
    for event in events:
        kind = _event_kind(event)
        if kind == "player_eliminated" and event.get("player") == target_player:
            target_alive = False
            summary["target_player_eliminated"] = True
            continue
        if kind == "combat":
            summary["combat_total"] += 1
            attacker = str(event.get("attacker") or "")
            defender = str(event.get("target") or "")
            if attacker == target_player:
                summary["target_player_combat_total"] += 1
                continue
            if not target_alive:
                summary["post_target_elimination_opponent_combat_ignored"] += 1
                continue
            summary["opponent_combat_total"] += 1
            if defender == target_player:
                summary["opponent_combat_to_target"] += 1
                if not _has_evaluation_pressure_metadata(event):
                    summary["opponent_combat_missing_pressure_reason"] += 1
                    summary["violations"].append(
                        {
                            "event": kind,
                            "turn": event.get("turn"),
                            "attacker": attacker,
                            "target": defender,
                            "target_reason": event.get("target_reason"),
                            "evaluation_target_active": event.get(
                                "evaluation_target_active"
                            ),
                            "finding": "opponent_attack_to_target_missing_evaluation_pressure_metadata",
                        }
                    )
            else:
                summary["opponent_combat_to_other"] += 1
                if _is_accepted_non_target_attack(event, table_intent_mode):
                    summary["opponent_combat_to_other_table_intent_accepted"] += 1
                    continue
                summary["violations"].append(
                    {
                        "event": kind,
                        "turn": event.get("turn"),
                        "attacker": attacker,
                        "target": defender,
                        "target_reason": event.get("target_reason"),
                        "finding": "opponent_attacked_non_target_player",
                    }
                )
        elif (
            kind == "multi_defender_attack"
            and event.get("attacker") != target_player
            and target_alive
        ):
            summary["opponent_multi_defender_attack"] += 1
            if table_intent_mode:
                summary["opponent_multi_defender_attack_table_intent_accepted"] += 1
                continue
            summary["violations"].append(
                {
                    "event": kind,
                    "turn": event.get("turn"),
                    "attacker": event.get("attacker"),
                    "groups": event.get("groups"),
                    "finding": "opponent_split_attack_while_target_deck_evaluation_is_active",
                }
            )

    summary["findings"] = len(summary["violations"])
    if summary["findings"]:
        summary["status"] = "blocked"
    return summary


def write_markdown(path: Path, summary: dict[str, Any], events_path: Path) -> None:
    lines = [
        "# Battle Target Pressure Audit",
        "",
        f"- events: `{events_path}`",
        f"- status: `{summary['status']}`",
        f"- target_player: `{summary['target_player']}`",
        f"- combat_total: `{summary['combat_total']}`",
        f"- opponent_combat_total: `{summary['opponent_combat_total']}`",
        f"- opponent_combat_to_target: `{summary['opponent_combat_to_target']}`",
        f"- opponent_combat_to_other: `{summary['opponent_combat_to_other']}`",
        f"- opponent_multi_defender_attack: `{summary['opponent_multi_defender_attack']}`",
        f"- opponent_combat_missing_pressure_reason: `{summary['opponent_combat_missing_pressure_reason']}`",
        f"- findings: `{summary['findings']}`",
        "",
        "## Findings",
        "",
    ]
    if not summary["violations"]:
        lines.append("- No target-pressure violations found.")
    else:
        for finding in summary["violations"][:50]:
            lines.append(
                "- turn={turn} event={event} attacker={attacker} target={target} finding={finding}".format(
                    turn=finding.get("turn"),
                    event=finding.get("event"),
                    attacker=finding.get("attacker"),
                    target=finding.get("target"),
                    finding=finding.get("finding"),
                )
            )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check that opponent combat pressures the evaluated deck player."
    )
    parser.add_argument("--events", required=True, type=Path)
    parser.add_argument("--target", default="Lorehold")
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--fail-on-violation", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    summary = audit_events(load_events(args.events), args.target)
    result = {"summary": summary}
    text = json.dumps(result, indent=2, sort_keys=True)
    print(text)
    if args.json_output:
        args.json_output.write_text(text + "\n", encoding="utf-8")
    if args.output:
        write_markdown(args.output, summary, args.events)
    if args.fail_on_violation and summary["status"] != "pass":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
