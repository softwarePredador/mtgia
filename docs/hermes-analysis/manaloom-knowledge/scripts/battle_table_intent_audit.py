#!/usr/bin/env python3
"""Audit Commander table-intent and opponent effectiveness in battle replays."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


INTERACTION_EVENTS = {
    "spell_countered",
    "instant_removal",
    "removal_resolved",
    "board_wipe_resolved",
    "hate_artifact_resolved",
    "game_win_prevented",
}
INTERACTION_TRIGGERS = {
    "opponent_spell",
    "opponent_draw",
    "landfall_damage_each_opponent",
}


def load_events(path: Path) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    with path.open() as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            events.append(json.loads(line))
    return events


def audit_events(
    events: list[dict[str, Any]],
    *,
    target_player: str = "Lorehold",
    require_table_intent: bool = False,
) -> dict[str, Any]:
    summary: dict[str, Any] = {
        "status": "pass",
        "events_total": len(events),
        "combat_total": 0,
        "table_intent_combat_total": 0,
        "table_intent_missing_scores": 0,
        "opponent_spell_cast": 0,
        "opponent_spell_resolved": 0,
        "opponent_creature_cast": 0,
        "opponent_commander_cast": 0,
        "opponent_cast_illegal": 0,
        "opponent_interaction_events": 0,
        "opponent_trigger_interaction_events": 0,
        "opponent_blockers_total": 0,
        "target_blockers_total": 0,
        "opponent_wins": 0,
        "target_wins": 0,
        "findings": [],
    }

    for event in events:
        event_type = event.get("event")
        player = event.get("player")
        is_target_player = player == target_player
        is_opponent_player = bool(player) and not is_target_player

        if event_type == "combat":
            summary["combat_total"] += 1
            if event.get("table_intent_enabled"):
                summary["table_intent_combat_total"] += 1
                if not event.get("table_intent_scores"):
                    summary["table_intent_missing_scores"] += 1
            if event.get("target") == target_player:
                summary["target_blockers_total"] += int(event.get("blockers") or 0)
            elif event.get("target"):
                summary["opponent_blockers_total"] += int(event.get("blockers") or 0)

        if is_opponent_player and event_type == "spell_cast":
            summary["opponent_spell_cast"] += 1
        elif is_opponent_player and event_type == "spell_resolved":
            summary["opponent_spell_resolved"] += 1
        elif is_opponent_player and event_type == "creature_cast":
            summary["opponent_creature_cast"] += 1
        elif is_opponent_player and event_type == "commander_cast":
            summary["opponent_commander_cast"] += 1
        elif is_opponent_player and event_type == "cast_illegal":
            summary["opponent_cast_illegal"] += 1

        if is_opponent_player and event_type in INTERACTION_EVENTS:
            summary["opponent_interaction_events"] += 1
        if (
            is_opponent_player
            and event_type == "trigger_resolved"
            and event.get("trigger") in INTERACTION_TRIGGERS
        ):
            summary["opponent_interaction_events"] += 1
            summary["opponent_trigger_interaction_events"] += 1

        if event_type == "game_won":
            if player == target_player:
                summary["target_wins"] += 1
            elif player:
                summary["opponent_wins"] += 1

    findings: list[dict[str, Any]] = summary["findings"]
    if require_table_intent and summary["combat_total"] and not summary["table_intent_combat_total"]:
        findings.append({
            "severity": "high",
            "code": "table_intent_missing",
            "message": "Combat events did not include table-intent evidence.",
        })
    if summary["table_intent_missing_scores"]:
        findings.append({
            "severity": "high",
            "code": "table_intent_scores_missing",
            "message": "Some table-intent combat events were missing target score details.",
            "count": summary["table_intent_missing_scores"],
        })

    legal_opponent_actions = (
        summary["opponent_spell_cast"]
        + summary["opponent_creature_cast"]
        + summary["opponent_commander_cast"]
    )
    if legal_opponent_actions and summary["opponent_cast_illegal"] > legal_opponent_actions * 2:
        findings.append({
            "severity": "medium",
            "code": "opponent_illegal_cast_pressure_high",
            "message": "Opponent illegal cast attempts are more than 2x legal cast actions.",
            "illegal": summary["opponent_cast_illegal"],
            "legal": legal_opponent_actions,
        })
    if summary["opponent_spell_resolved"] + summary["opponent_creature_cast"] == 0:
        findings.append({
            "severity": "medium",
            "code": "opponent_effectiveness_absent",
            "message": "No opponent spell resolutions or creature casts were observed.",
        })
    opponent_agency = (
        legal_opponent_actions
        + summary["opponent_spell_resolved"]
        + summary["opponent_wins"]
        + summary["opponent_blockers_total"]
    )
    if summary["opponent_interaction_events"] == 0 and opponent_agency == 0:
        findings.append({
            "severity": "medium",
            "code": "opponent_interaction_absent",
            "message": "No opponent stack/removal/hate interaction or agency events were observed.",
        })

    if any(finding["severity"] == "high" for finding in findings):
        summary["status"] = "blocked"
    elif findings:
        summary["status"] = "review_required"
    return summary


def render_markdown(summary: dict[str, Any], *, source: str, target_player: str) -> str:
    lines = [
        "# Battle Table Intent Audit",
        "",
        f"- source: `{source}`",
        f"- target_player: `{target_player}`",
        f"- status: `{summary['status']}`",
        f"- events_total: `{summary['events_total']}`",
        f"- combat_total: `{summary['combat_total']}`",
        f"- table_intent_combat_total: `{summary['table_intent_combat_total']}`",
        f"- table_intent_missing_scores: `{summary['table_intent_missing_scores']}`",
        f"- opponent_spell_cast: `{summary['opponent_spell_cast']}`",
        f"- opponent_spell_resolved: `{summary['opponent_spell_resolved']}`",
        f"- opponent_creature_cast: `{summary['opponent_creature_cast']}`",
        f"- opponent_commander_cast: `{summary['opponent_commander_cast']}`",
        f"- opponent_cast_illegal: `{summary['opponent_cast_illegal']}`",
        f"- opponent_interaction_events: `{summary['opponent_interaction_events']}`",
        f"- opponent_trigger_interaction_events: `{summary['opponent_trigger_interaction_events']}`",
        f"- opponent_blockers_total: `{summary['opponent_blockers_total']}`",
        f"- target_blockers_total: `{summary['target_blockers_total']}`",
        f"- opponent_wins: `{summary['opponent_wins']}`",
        f"- target_wins: `{summary['target_wins']}`",
        "",
        "## Findings",
    ]
    if not summary["findings"]:
        lines.append("- none")
    else:
        for finding in summary["findings"]:
            lines.append(
                f"- `{finding['severity']}` `{finding['code']}`: {finding['message']}"
            )
    lines.append("")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--events", required=True, type=Path)
    parser.add_argument("--target", default="Lorehold")
    parser.add_argument("--require-table-intent", action="store_true")
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--fail-on-blocked", action="store_true")
    args = parser.parse_args(argv)

    events = load_events(args.events)
    summary = audit_events(
        events,
        target_player=args.target,
        require_table_intent=args.require_table_intent,
    )
    payload = {
        "source": str(args.events),
        "target_player": args.target,
        "summary": summary,
    }
    if args.json_output:
        args.json_output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    markdown = render_markdown(summary, source=str(args.events), target_player=args.target)
    if args.output:
        args.output.write_text(markdown)
    else:
        print(markdown)
    if args.fail_on_blocked and summary["status"] == "blocked":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
