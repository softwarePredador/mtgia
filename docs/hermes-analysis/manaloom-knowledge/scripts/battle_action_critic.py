#!/usr/bin/env python3
"""Per-action critic for a single Hermes battle replay.

This is intentionally stricter and more verbose than aggregate win-rate reports.
It reads structured replay events plus optional decision traces and produces a
human-reviewable ledger: every gameplay action gets a verdict, evidence and any
finding that should be investigated before trusting the replay as training data.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict, deque
from pathlib import Path
from typing import Any


ACTION_EVENTS = {
    "additional_cost_failed",
    "commander_cast",
    "combat",
    "combat_result",
    "combat_step",
    "creature_cast",
    "end_step_instant",
    "game_won",
    "land_played",
    "miracle_cast",
    "multi_defender_attack",
    "player_eliminated",
    "recursion_resolved",
    "removal_resolved",
    "replacement_applied",
    "spell_cast",
    "spell_resolved",
    "trigger_put_on_stack",
    "trigger_resolved",
    "tutor_resolved",
    "turn_end",
    "turn_start",
}

TECHNICAL_EVENTS = {
    "cast_announced",
    "cast_illegal",
    "mana_refreshed",
    "priority_pass",
}

CARD_ACTION_EVENTS = {
    "commander_cast",
    "creature_cast",
    "end_step_instant",
    "land_played",
    "miracle_cast",
    "spell_cast",
    "spell_resolved",
}

DECISION_ACTION_EVENTS = {
    "commander_cast",
    "creature_cast",
    "combat",
    "combat_step",
    "end_step_instant",
    "miracle_cast",
    "spell_cast",
}

SEVERITY_ORDER = {
    "ok": 0,
    "info": 1,
    "low": 2,
    "medium": 3,
    "high": 4,
    "critical": 5,
}


def load_jsonl(path: Path, *, replay_id: str | None = None) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for index, line in enumerate(handle, start=1):
            text = line.strip()
            if not text:
                continue
            payload = json.loads(text)
            payload.setdefault("event_index", index)
            if replay_id:
                payload.setdefault("replay_id", replay_id)
            rows.append(payload)
    return rows


def md(value: Any) -> str:
    return str(value if value is not None else "").replace("|", "\\|").replace("\n", " ")


def event_label(event: dict[str, Any]) -> str:
    card = event.get("card")
    if card:
        return str(card)
    if event.get("target"):
        return f"target={event.get('target')}"
    if event.get("defender"):
        return f"defender={event.get('defender')}"
    if event.get("reason"):
        return str(event.get("reason"))
    return "-"


def event_player(event: dict[str, Any]) -> str:
    return str(
        event.get("player")
        or event.get("attacker")
        or event.get("defender")
        or event.get("controller")
        or event.get("active_player")
        or "?"
    )


def event_turn(event: dict[str, Any]) -> Any:
    return event.get("turn", "?")


def event_phase(event: dict[str, Any]) -> str:
    return str(event.get("phase") or "-")


def type_line(event: dict[str, Any]) -> str:
    return str(event.get("type_line") or "")


def is_land_event(event: dict[str, Any]) -> bool:
    return event.get("effect") == "land" or "land" in type_line(event).lower()


def is_card_spell_event(event: dict[str, Any]) -> bool:
    return event.get("event") in {
        "commander_cast",
        "creature_cast",
        "end_step_instant",
        "miracle_cast",
        "spell_cast",
    }


def action_finding(
    severity: str,
    code: str,
    detail: str,
    recommendation: str,
) -> dict[str, str]:
    return {
        "severity": severity,
        "code": code,
        "detail": detail,
        "recommendation": recommendation,
    }


def max_severity(findings: list[dict[str, str]]) -> str:
    if not findings:
        return "ok"
    return max(findings, key=lambda f: SEVERITY_ORDER.get(f["severity"], 0))["severity"]


def decision_key(decision: dict[str, Any]) -> tuple[Any, str, str]:
    chosen = decision.get("chosen_option") or {}
    card = str(chosen.get("card") or "")
    return (decision.get("turn", "?"), str(decision.get("player") or "?"), card)


def build_decision_index(decisions: list[dict[str, Any]]) -> dict[tuple[Any, str, str], deque[dict[str, Any]]]:
    index: dict[tuple[Any, str, str], deque[dict[str, Any]]] = defaultdict(deque)
    for decision in decisions:
        key = decision_key(decision)
        index[key].append(decision)
    return index


def criticize_actions(
    events: list[dict[str, Any]],
    decisions: list[dict[str, Any]] | None = None,
    *,
    include_technical: bool = False,
) -> dict[str, Any]:
    decisions = decisions or []
    decision_index = build_decision_index(decisions)
    cast_stack: dict[tuple[Any, str, str], list[dict[str, Any]]] = defaultdict(list)
    land_plays: Counter[tuple[Any, str, Any]] = Counter()
    alive_players: dict[Any, dict[str, bool]] = defaultdict(dict)
    game_won_seen: set[Any] = set()
    action_rows: list[dict[str, Any]] = []

    action_number = 0
    for event in events:
        kind = event.get("event")
        if kind in TECHNICAL_EVENTS and not include_technical:
            continue
        if kind not in ACTION_EVENTS and not include_technical:
            continue

        action_number += 1
        player = event_player(event)
        turn = event_turn(event)
        phase = event_phase(event)
        replay_id = event.get("replay_id", "external")
        findings: list[dict[str, str]] = []
        evidence: list[str] = []

        if turn == "?" and kind not in {"trigger_put_on_stack", "replacement_applied"}:
            findings.append(action_finding(
                "low",
                "missing_turn",
                "Action event has no turn field.",
                "Include turn in emitted event for full replay traceability.",
            ))

        if kind in CARD_ACTION_EVENTS:
            source = str(event.get("rule_source") or "missing")
            status = str(event.get("rule_review_status") or "missing")
            effect = str(event.get("effect") or "unknown")
            evidence.append(f"rule={source}/{status}")
            evidence.append(f"effect={effect}")
            if source == "missing" or status == "missing":
                findings.append(action_finding(
                    "low",
                    "missing_rule_metadata",
                    "Card action is missing rule source/review status.",
                    "Emit rule_source and rule_review_status for every card action.",
                ))
            elif status in {"needs_review", "unknown"}:
                findings.append(action_finding(
                    "low",
                    "review_rule_used",
                    f"Action used rule status {status}.",
                    "Keep this action audit-only until the card rule is verified.",
                ))

        if kind == "land_played":
            land_plays[(replay_id, player, turn)] += 1
            if not is_land_event(event):
                findings.append(action_finding(
                    "critical",
                    "nonland_played_as_land",
                    "Event land_played does not look like a land.",
                    "Fix card classification before trusting this replay.",
                ))
            if land_plays[(replay_id, player, turn)] > 1:
                findings.append(action_finding(
                    "high",
                    "multiple_land_plays",
                    "Player played more than one land in the same turn.",
                    "Only allow this with an explicit extra-land effect in the event metadata.",
                ))

        if kind in {"spell_cast", "creature_cast", "commander_cast", "miracle_cast", "end_step_instant"}:
            if is_land_event(event):
                findings.append(action_finding(
                    "critical",
                    "land_cast_as_spell",
                    "A land-like card was cast as a spell.",
                    "Fix land/spell classification before using this replay.",
                ))
            if kind != "commander_cast":
                cast_stack[(replay_id, player, str(event.get("card") or ""))].append(event)

        if kind == "spell_resolved":
            key = (replay_id, player, str(event.get("card") or ""))
            if cast_stack.get(key):
                cast_stack[key].pop()
            else:
                findings.append(action_finding(
                    "medium",
                    "resolve_without_cast",
                    "Spell resolved without a prior tracked cast in this replay.",
                    "Check stack emission order or add explicit synthetic-source metadata.",
                ))

        if kind == "combat_step":
            attackers = event.get("attackers")
            if attackers is not None and not attackers:
                findings.append(action_finding(
                    "low",
                    "empty_attack",
                    "Combat step has no attackers.",
                    "Prefer omitting combat_step or marking it as no_attack decision.",
                ))
            total_power = event.get("total_power")
            if total_power is not None and float(total_power or 0) < 0:
                findings.append(action_finding(
                    "critical",
                    "negative_combat_power",
                    "Combat total_power is negative.",
                    "Fix combat stat calculation.",
                ))
            evidence.append(f"target={event.get('target') or event.get('defender') or '-'}")
            evidence.append(f"power={event.get('total_power', event.get('power', '-'))}")

        if kind == "combat_result":
            damage = event.get("damage")
            if damage is not None and float(damage or 0) < 0:
                findings.append(action_finding(
                    "critical",
                    "negative_damage",
                    "Combat result has negative damage.",
                    "Fix damage assignment.",
                ))
            evidence.append(f"damage={damage if damage is not None else '-'}")
            evidence.append(f"target_life={event.get('target_life', '-')}")

        if kind == "turn_end":
            hand = int(event.get("hand") or 0)
            evidence.append(f"hand={hand}")
            evidence.append(f"board={event.get('board', '-')}")
            evidence.append(f"grave={event.get('graveyard', '-')}")
            if hand > 7:
                findings.append(action_finding(
                    "critical",
                    "cleanup_hand_size",
                    f"Turn ended with hand size {hand} > 7.",
                    "Fix cleanup discard or max hand size handling.",
                ))

        if kind == "player_eliminated":
            eliminated = str(event.get("player") or event.get("target") or "?")
            alive_players[replay_id][eliminated] = False
            evidence.append(f"reason={event.get('reason', '-')}")

        if kind == "turn_start":
            alive_players[replay_id].setdefault(player, True)
            evidence.append(f"life={event.get('life', '-')}")
            evidence.append(f"hand={event.get('hand', '-')}")

        if kind == "game_won":
            game_won_seen.add(replay_id)
            evidence.append(f"winner={player}")

        decision = None
        if kind in DECISION_ACTION_EVENTS and event.get("card"):
            key = (turn, player, str(event.get("card") or ""))
            if decision_index.get(key):
                decision = decision_index[key].popleft()
                evidence.append(f"decision={decision.get('decision_id')}")
                if not decision.get("score_components"):
                    findings.append(action_finding(
                        "low",
                        "empty_decision_score",
                        "Matching decision trace has empty score_components.",
                        "Populate score_components for auditability.",
                    ))
            elif kind in {"spell_cast", "creature_cast", "commander_cast"}:
                findings.append(action_finding(
                    "low",
                    "missing_decision_trace",
                    "Action has no matching decision trace.",
                    "Emit a decision trace for cast/combat choices.",
                ))

        action_rows.append({
            "action_id": f"action-{action_number:06d}",
            "event_index": event.get("event_index", action_number),
            "replay_id": replay_id,
            "turn": turn,
            "phase": phase,
            "player": player,
            "event": kind,
            "label": event_label(event),
            "verdict": max_severity(findings),
            "evidence": "; ".join(evidence) if evidence else "-",
            "findings": findings,
        })

    replay_ids = {row["replay_id"] for row in action_rows} or {"external"}
    for replay_id in replay_ids:
        players = alive_players.get(replay_id, {})
        alive_count = sum(1 for alive in players.values() if alive)
        if players and alive_count <= 1 and replay_id not in game_won_seen:
            action_number += 1
            survivor = next((player for player, alive in players.items() if alive), "?")
            action_rows.append({
                "action_id": f"action-{action_number:06d}",
                "event_index": "-",
                "replay_id": replay_id,
                "turn": "postgame",
                "phase": "-",
                "player": survivor,
                "event": "postgame_consistency",
                "label": "winner inference",
                "verdict": "medium",
                "evidence": f"alive_players={alive_count}; survivor={survivor}",
                "findings": [action_finding(
                    "medium",
                    "missing_game_won",
                    "Replay reached one surviving player but emitted no game_won event.",
                    "Emit game_won when multiplayer game closes by elimination.",
                )],
            })

    counts = Counter(row["verdict"] for row in action_rows)
    findings = [
        {
            **finding,
            "action_id": row["action_id"],
            "turn": row["turn"],
            "phase": row["phase"],
            "player": row["player"],
            "event": row["event"],
            "label": row["label"],
        }
        for row in action_rows
        for finding in row["findings"]
    ]
    return {
        "summary": {
            "total_actions": len(action_rows),
            "verdict_counts": dict(sorted(counts.items())),
            "findings": len(findings),
            "technical_events_included": include_technical,
        },
        "actions": action_rows,
        "findings": findings,
    }


def render_markdown(result: dict[str, Any]) -> str:
    summary = result["summary"]
    lines = [
        "# Battle Action Critic",
        "",
        "## Summary",
        "",
        f"- total_actions: {summary['total_actions']}",
        f"- findings: {summary['findings']}",
        f"- verdict_counts: `{json.dumps(summary['verdict_counts'], sort_keys=True)}`",
        f"- technical_events_included: {summary['technical_events_included']}",
        "",
        "## Findings",
        "",
    ]
    if result["findings"]:
        lines.extend([
            "| Severity | Action | Turn | Player | Event | Finding | Recommendation |",
            "| --- | --- | ---: | --- | --- | --- | --- |",
        ])
        for finding in result["findings"]:
            lines.append(
                "| {severity} | {action_id} | {turn} | {player} | {event} | {detail} | {recommendation} |".format(
                    severity=md(finding["severity"]),
                    action_id=md(finding["action_id"]),
                    turn=md(finding["turn"]),
                    player=md(finding["player"]),
                    event=md(finding["event"]),
                    detail=md(finding["detail"]),
                    recommendation=md(finding["recommendation"]),
                )
            )
    else:
        lines.append("- No action findings.")
    lines.extend([
        "",
        "## Action Ledger",
        "",
        "| Action | Line | Turn | Phase | Player | Event | Label | Verdict | Evidence |",
        "| --- | ---: | ---: | --- | --- | --- | --- | --- | --- |",
    ])
    for row in result["actions"]:
        lines.append(
            "| {action_id} | {event_index} | {turn} | {phase} | {player} | {event} | {label} | {verdict} | {evidence} |".format(
                action_id=md(row["action_id"]),
                event_index=md(row["event_index"]),
                turn=md(row["turn"]),
                phase=md(row["phase"]),
                player=md(row["player"]),
                event=md(row["event"]),
                label=md(row["label"]),
                verdict=md(row["verdict"]),
                evidence=md(row["evidence"]),
            )
        )
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Criticize every gameplay action in a Hermes battle replay.")
    parser.add_argument("--events", required=True, type=Path, help="Structured replay JSONL.")
    parser.add_argument("--decision-trace", type=Path, help="Decision trace JSONL.")
    parser.add_argument("--output", type=Path, help="Markdown report output.")
    parser.add_argument("--json-output", type=Path, help="Machine-readable JSON report output.")
    parser.add_argument("--include-technical", action="store_true", help="Include priority/mana/cast-announced events.")
    args = parser.parse_args()

    events = load_jsonl(args.events)
    decisions = load_jsonl(args.decision_trace) if args.decision_trace and args.decision_trace.exists() else []
    result = criticize_actions(events, decisions, include_technical=args.include_technical)
    markdown = render_markdown(result)

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(markdown, encoding="utf-8")
    else:
        print(markdown)
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(result, indent=2, sort_keys=True), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
