#!/usr/bin/env python3
"""Turn-by-turn replay/decision audit for the optimizer loop.

The aggregate baseline still matters, but optimizer trust requires checking the
actual decisions that produced those numbers. This auditor can generate fresh
structured replays or consume a JSONL replay event file from
``battle_replay_v10_3.py``.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

from master_optimizer_common import REPORT_DIR, connect, ensure_optimizer_tables, latest_baseline, write_report


SCRIPT_DIR = Path(__file__).resolve().parent
REPLAY_GENERATOR = SCRIPT_DIR / "battle_replay_v10_3.py"
AUDIT_SCOPE = "turn_and_decision_trace_invariants"
CLEAN_STATUS = "turn_invariants_clean"
BLOCKED_STATUS = "blocked_turn_or_decision_invariants"
NOT_EVALUATED = "not_evaluated_by_replay_decision_auditor"

KNOWN_LAND_NAMES = {
    "plains",
    "island",
    "swamp",
    "mountain",
    "forest",
    "wastes",
    "high market",
    "tropical island",
    "tundra",
    "otawara, soaring city",
    "dryad arbor",
    "gaea's cradle",
    "havenwood battleground",
    "mishra's factory",
    "ancient tomb",
    "command tower",
    "exotic orchard",
    "field of the dead",
    "reliquary tower",
}


def writable_replay_dir(report: bool) -> Path:
    if not report:
        return Path(tempfile.mkdtemp(prefix="hermes_replay_audit_"))

    preferred = Path(os.environ.get("MANALOOM_REPLAY_DIR", REPORT_DIR / "replays"))
    fallback = (
        Path(os.environ.get("MANALOOM_MASTER_OPTIMIZER_ARTIFACT_DIR", "/opt/data/artifacts/hermes_master_optimizer"))
        / "replays"
    )
    for candidate in (preferred, fallback):
        try:
            candidate.mkdir(parents=True, exist_ok=True)
            probe = candidate / f".write_probe_{os.getpid()}"
            probe.write_text("ok", encoding="utf-8")
            probe.unlink(missing_ok=True)
            return candidate
        except OSError:
            continue
    raise RuntimeError(f"No writable replay output directory: {preferred} or {fallback}")


def load_events(path: Path, replay_id: str = "external") -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for index, line in enumerate(handle, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError as exc:
                raise RuntimeError(f"Invalid JSONL event at {path}:{index}: {exc}") from exc
            event.setdefault("replay_id", replay_id)
            events.append(event)
    return events


def load_decision_traces(path: Path, replay_id: str = "external") -> list[dict[str, Any]]:
    decisions: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for index, line in enumerate(handle, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                decision = json.loads(line)
            except json.JSONDecodeError as exc:
                raise RuntimeError(f"Invalid JSONL decision at {path}:{index}: {exc}") from exc
            decision.setdefault("replay_id", replay_id)
            decisions.append(decision)
    return decisions


def decision_trace_path_for_events(path: Path) -> Path:
    return path.with_suffix(".decision_trace.jsonl")


def generate_replay_events(seed: int, output_dir: Path) -> tuple[list[dict[str, Any]], list[dict[str, Any]], Path, Path, Path]:
    replay_txt = output_dir / f"battle_replay_seed_{seed}.txt"
    replay_jsonl = output_dir / f"battle_replay_seed_{seed}.jsonl"
    decision_jsonl = output_dir / f"battle_replay_seed_{seed}.decision_trace.jsonl"
    env = os.environ.copy()
    env.update(
        {
            "REPLAY_SEED": str(seed),
            "REPLAY_OUT": str(replay_txt),
            "REPLAY_EVENTS_OUT": str(replay_jsonl),
            "DECISION_TRACE_OUT": str(decision_jsonl),
        }
    )
    completed = subprocess.run(
        [sys.executable, str(REPLAY_GENERATOR)],
        cwd=str(SCRIPT_DIR),
        env=env,
        capture_output=True,
        text=True,
        timeout=300,
    )
    if completed.returncode != 0:
        output = (completed.stdout or "") + "\n" + (completed.stderr or "")
        raise RuntimeError(f"Replay generator failed for seed {seed}:\n{output[-2000:]}")
    return (
        load_events(replay_jsonl, replay_id=f"seed_{seed}"),
        load_decision_traces(decision_jsonl, replay_id=f"seed_{seed}") if decision_jsonl.exists() else [],
        replay_txt,
        replay_jsonl,
        decision_jsonl,
    )


def add_finding(
    findings: list[dict[str, Any]],
    severity: str,
    event: dict[str, Any],
    finding: str,
) -> None:
    findings.append(
        {
            "severity": severity,
            "replay_id": event.get("replay_id", "?"),
            "turn": event.get("turn", "?"),
            "player": event.get("player") or event.get("attacker") or "?",
            "event": event.get("event", "?"),
            "finding": finding,
        }
    )


def defender_life_gaps(event: dict[str, Any]) -> list[dict[str, Any]]:
    target = event.get("target")
    target_life = int(event.get("target_life_before") or 0)
    defenders = event.get("defenders") or []
    if not isinstance(defenders, list):
        return []
    return [
        defender
        for defender in defenders
        if defender.get("name") != target
        and int(defender.get("life") or 0) < target_life
    ]


def event_type_line(event: dict[str, Any]) -> str:
    return str(event.get("type_line") or "")


def event_is_land(event: dict[str, Any]) -> bool:
    type_line = event_type_line(event).lower()
    return event.get("effect") == "land" or "land" in type_line


def event_is_instant(event: dict[str, Any]) -> bool:
    return "instant" in event_type_line(event).lower()


def event_is_sorcery(event: dict[str, Any]) -> bool:
    return "sorcery" in event_type_line(event).lower()


def card_detail_keywords(detail: dict[str, Any]) -> set[str]:
    return {str(keyword) for keyword in detail.get("keywords") or []}


def card_detail_is_land(detail: dict[str, Any]) -> bool:
    name = str(detail.get("name") or "").strip().lower()
    type_line = str(detail.get("type_line") or "").lower()
    return "land" in type_line or name in KNOWN_LAND_NAMES


def card_detail_is_creature(detail: dict[str, Any]) -> bool:
    return "creature" in str(detail.get("type_line") or "").lower()


def audit_turn_events(events: list[dict[str, Any]]) -> list[dict[str, Any]]:
    findings: list[dict[str, Any]] = []
    latest_combat: dict[tuple[Any, Any, Any, Any], dict[str, Any]] = {}
    approach_resolved: dict[tuple[Any, str], int] = {}
    approach_won: set[tuple[Any, str]] = set()
    game_closed: dict[Any, bool] = {}
    land_plays: dict[tuple[Any, Any, Any], int] = {}

    for event in events:
        kind = event.get("event")
        replay_id = event.get("replay_id", "external")

        if game_closed.get(replay_id) and kind == "turn_start":
            add_finding(
                findings,
                "critical",
                event,
                "Game produced a new turn after a game_won event.",
            )

        if kind == "turn_end":
            hand = int(event.get("hand") or 0)
            discarded = int(event.get("discarded") or 0)
            if hand > 7:
                add_finding(findings, "critical", event, f"Cleanup ended with hand size {hand} > 7.")
            # Legitimate wheel/storm turns can discard double digits as long as
            # cleanup ends at seven. Keep this guard for runaway draw loops.
            if discarded >= 25:
                add_finding(
                    findings,
                    "medium",
                    event,
                    f"Cleanup discarded {discarded} cards; inspect draw/hand overflow sequencing.",
                )

        elif kind == "spell_cast":
            if event_is_land(event):
                add_finding(findings, "critical", event, "Land was cast as a spell.")

        elif kind == "land_played":
            if not event_is_land(event):
                add_finding(findings, "critical", event, "Non-land was played as a land.")
            key = (replay_id, event.get("turn"), event.get("player"))
            land_plays[key] = land_plays.get(key, 0) + 1
            if land_plays[key] > 1:
                add_finding(findings, "critical", event, "Player made more than one land play in a turn.")

        elif kind == "end_step_instant":
            type_line = event_type_line(event)
            if event_is_land(event):
                add_finding(findings, "critical", event, "Land was cast during an opponent end step.")
            elif (
                type_line
                and not event_is_instant(event)
                and event.get("instant_speed_reason") != "flash"
            ):
                add_finding(
                    findings,
                    "high",
                    event,
                    f"Non-instant card was cast during an opponent end step: {type_line}.",
                )

        elif kind == "miracle_cast":
            type_line = event_type_line(event)
            if event_is_land(event):
                add_finding(findings, "critical", event, "Land was cast via Miracle.")
            elif type_line and not (event_is_instant(event) or event_is_sorcery(event)):
                add_finding(
                    findings,
                    "critical",
                    event,
                    f"Miracle cast a non-instant/non-sorcery card: {type_line}.",
                )

        elif kind == "combat":
            attackers = int(event.get("attackers") or 0)
            total_power = int(event.get("total_power") or 0)
            target_life = int(event.get("target_life_before") or 0)
            target_reason = str(event.get("target_reason") or "")
            blockers = int(event.get("blockers") or 0)
            if attackers > 0 and total_power <= 0:
                add_finding(findings, "high", event, "Combat declared attackers with non-positive total power.")
            if total_power >= target_life > 0 and target_reason != "lethal":
                add_finding(
                    findings,
                    "high",
                    event,
                    f"Potential lethal attack ({total_power} power vs {target_life} life) was not tagged as lethal.",
                )
            if target_reason == "default_high_life":
                lower_life_defenders = defender_life_gaps(event)
                if lower_life_defenders:
                    names = ", ".join(
                        f"{d.get('name')}({d.get('life')})" for d in lower_life_defenders[:3]
                    )
                    add_finding(
                        findings,
                        "medium",
                        event,
                        f"Default targeting chose the highest-life player while lower-life defenders existed: {names}.",
                    )
            if blockers == 0 and target_life <= 0:
                add_finding(findings, "high", event, "Combat targeted an already-dead player.")
            for detail in event.get("attackers_detail") or []:
                if not isinstance(detail, dict):
                    continue
                keywords = card_detail_keywords(detail)
                if card_detail_is_land(detail) and not card_detail_is_creature(detail):
                    add_finding(
                        findings,
                        "critical",
                        event,
                        f"Non-creature land attacked as a creature: {detail.get('name', '?')}.",
                    )
                if detail.get("summoning_sick") and "haste" not in keywords:
                    add_finding(
                        findings,
                        "critical",
                        event,
                        f"Summoning-sick attacker without haste: {detail.get('name', '?')}.",
                    )
                if "tapped" in detail:
                    tapped = bool(detail.get("tapped"))
                    if "vigilance" in keywords and tapped:
                        add_finding(
                            findings,
                            "high",
                            event,
                            f"Vigilance attacker was tapped to attack: {detail.get('name', '?')}.",
                        )
                    if "vigilance" not in keywords and not tapped:
                        add_finding(
                            findings,
                            "high",
                            event,
                            f"Non-vigilance attacker was not tapped to attack: {detail.get('name', '?')}.",
                        )
            latest_combat[
                (replay_id, event.get("turn"), event.get("attacker"), event.get("target"))
            ] = event

        elif kind == "combat_result":
            key = (replay_id, event.get("turn"), event.get("attacker"), event.get("target"))
            combat = latest_combat.get(key)
            if combat:
                blockers = int(combat.get("blockers") or 0)
                attackers = int(combat.get("attackers") or 0)
                target_life = int(combat.get("target_life_before") or 0)
                total_power = int(combat.get("total_power") or 0)
                damage = int(event.get("damage_to_player") or 0)
                target_dead = bool(event.get("target_dead"))
                target_protected = bool(
                    event.get("target_life_cant_change")
                    or event.get("target_protection_from_everything")
                    or combat.get("target_life_cant_change")
                    or combat.get("target_protection_from_everything")
                )
                if attackers > 0 and blockers == 0 and damage == 0 and not target_protected:
                    add_finding(findings, "high", event, "Unblocked combat dealt 0 player damage.")
                if blockers == 0 and total_power >= target_life > 0 and not target_dead and not target_protected:
                    add_finding(
                        findings,
                        "high",
                        event,
                        "Unblocked lethal-looking combat did not kill the target.",
                    )

        elif kind == "spell_resolved" and event.get("effect") == "approach":
            key = (replay_id, str(event.get("player") or "?"))
            approach_resolved[key] = approach_resolved.get(key, 0) + 1

        elif kind == "game_won":
            game_closed[replay_id] = True
            if event.get("reason") == "approach":
                approach_won.add((replay_id, str(event.get("player") or "?")))

        elif kind == "tutor_resolved":
            if not event.get("found"):
                add_finding(findings, "medium", event, "Tutor resolved without finding a target.")

        elif kind == "removal_resolved":
            available_targets = int(event.get("available_targets") or 0)
            target_is_creature = event.get("target_is_creature")
            if target_is_creature is False:
                continue
            if event.get("target_effect") in {
                "commander",
                "combo",
                "draw_engine",
                "silence_opponents",
                "ramp_engine",
                "copy_spell",
                "ripple_engine",
                "hate_artifact",
            }:
                continue
            target_power = event.get("target_power")
            try:
                target_power_value = int(target_power)
            except (TypeError, ValueError):
                target_power_value = 0
            target_options = event.get("target_options") or []
            selected_score = event.get("target_score")
            better_target_available = None
            if isinstance(target_options, list) and selected_score is not None:
                better_target_available = any(
                    isinstance(option, dict)
                    and option.get("target") != event.get("target")
                    and (option.get("target_score") or []) > selected_score
                    for option in target_options
                )
            if better_target_available is False:
                continue
            if available_targets >= 3 and target_power_value <= 1:
                add_finding(
                    findings,
                    "low",
                    event,
                    "Removal hit a low-power target while multiple targets were available.",
                )

        elif kind == "board_wipe_resolved":
            destroyed = int(event.get("destroyed") or 0)
            protected = int(event.get("protected") or 0)
            unprotected_seen = event.get("unprotected_seen")
            if unprotected_seen is None:
                # Older replay events did not include board state before the wipe.
                # Do not block trust on missing context; new replays include it.
                unprotected_seen = 0
            unprotected_seen = int(unprotected_seen or 0)
            if destroyed == 0 and unprotected_seen > 0:
                add_finding(findings, "high", event, "Board wipe resolved without destroying creatures.")
            if protected > destroyed and destroyed > 0:
                add_finding(
                    findings,
                    "low",
                    event,
                    f"Board wipe left more protected creatures ({protected}) than destroyed ({destroyed}).",
                )

        elif kind == "extra_turn_cap_reached":
            add_finding(
                findings,
                "high",
                event,
                "Extra-turn loop hit the safety cap before all extra turns were consumed.",
            )

    for key, count in approach_resolved.items():
        if count >= 2 and key not in approach_won:
            findings.append(
                {
                    "severity": "critical",
                    "replay_id": key[0],
                    "turn": "?",
                    "player": key[1],
                    "event": "approach",
                    "finding": "Approach resolved at least twice without an approach game_won event.",
                }
            )

    return findings


def _option_identity(option: Any) -> str:
    if not isinstance(option, dict):
        return str(option)
    return str(option.get("card") or option.get("target") or option.get("action") or option)


def audit_decision_traces(decisions: list[dict[str, Any]]) -> list[dict[str, Any]]:
    findings: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    required = {
        "decision_id",
        "turn",
        "phase",
        "player",
        "decision_type",
        "available_options",
        "chosen_option",
        "score_components",
        "rule_source",
        "rule_status",
        "confidence",
        "expected_benefit_score",
    }
    for decision in decisions:
        event = {
            "event": f"decision:{decision.get('decision_type', '?')}",
            "replay_id": decision.get("replay_id", "external"),
            "turn": decision.get("turn", "?"),
            "player": decision.get("player", "?"),
        }
        decision_id = str(decision.get("decision_id") or "")
        missing = sorted(field for field in required if field not in decision)
        if missing:
            add_finding(findings, "high", event, f"Decision trace missing fields: {', '.join(missing)}.")
        if not decision_id:
            add_finding(findings, "high", event, "Decision trace has empty decision_id.")
        elif decision_id in seen_ids:
            add_finding(findings, "high", event, f"Duplicate decision_id: {decision_id}.")
        else:
            seen_ids.add(decision_id)

        options = decision.get("available_options")
        if not isinstance(options, list) or not options:
            add_finding(findings, "high", event, "Decision trace has no available_options.")
            options = []
        chosen = decision.get("chosen_option")
        chosen_key = _option_identity(chosen)
        option_keys = {_option_identity(option) for option in options}
        if chosen_key and chosen_key not in option_keys:
            add_finding(findings, "high", event, "Chosen option is not present in available_options.")
        scores = decision.get("score_components")
        if not isinstance(scores, dict) or not scores:
            add_finding(findings, "medium", event, "Decision trace has empty score_components.")
        if not decision.get("rule_source") or not decision.get("rule_status"):
            add_finding(findings, "medium", event, "Decision trace is missing rule source/status.")
        try:
            float(decision.get("expected_benefit_score", 0))
        except (TypeError, ValueError):
            add_finding(findings, "medium", event, "Decision expected_benefit_score is not numeric.")
        chosen_option_score = decision.get("chosen_option_score")
        available_option_scores = decision.get("available_option_scores")
        rejected_option_scores = decision.get("rejected_option_scores")
        best_rejected_option_score = decision.get("best_rejected_option_score")
        if isinstance(options, list) and len(options) > 1:
            if chosen_option_score is None:
                add_finding(findings, "medium", event, "Decision trace missing chosen_option_score for comparative choice.")
            if available_option_scores is None:
                add_finding(findings, "medium", event, "Decision trace missing available_option_scores for comparative choice.")
            if rejected_option_scores is None:
                add_finding(findings, "medium", event, "Decision trace missing rejected_option_scores for comparative choice.")
            scored_option_count = len(available_option_scores or [])
            chosen_option = decision.get("chosen_option") if isinstance(decision.get("chosen_option"), dict) else {}
            if scored_option_count >= 2 and chosen_option.get("action") != "pass" and best_rejected_option_score is None:
                add_finding(findings, "low", event, "Decision trace has multiple options but no best_rejected_option_score.")
            if scored_option_count >= 2 and not decision.get("expected_payoff_reason"):
                add_finding(findings, "low", event, "Decision trace is missing expected_payoff_reason.")
        if str(decision.get("rule_source") or "").lower() == "unknown":
            add_finding(findings, "low", event, "Decision used unknown rule source; keep as audit-only.")
        if str(decision.get("rule_status") or "").lower() == "needs_review":
            add_finding(findings, "low", event, "Decision used needs_review rule; keep as audit-only.")
    return findings


def aggregate_findings(matchups: list[dict[str, Any]]) -> list[dict[str, Any]]:
    findings: list[dict[str, Any]] = []
    for matchup in matchups:
        wr = float(matchup.get("wr") or 0)
        reasons = str(matchup.get("reasons") or "")
        opponent = str(matchup.get("opponent") or "?")
        stalls = int(matchup.get("stalls") or 0)
        avg_turn = float(matchup.get("avg_turn") or 0)
        event = {
            "event": "aggregate_baseline",
            "replay_id": "baseline",
            "turn": "-",
            "player": opponent,
        }
        if wr < 40:
            add_finding(
                findings,
                "high",
                event,
                f"Low matchup WR {wr:.1f}%; needs replay review before optimizer trusts cuts.",
            )
        if stalls > 0:
            add_finding(
                findings,
                "medium",
                event,
                f"{stalls} stalls; inspect missed wincon or game-end conditions.",
            )
        if avg_turn > 15:
            add_finding(
                findings,
                "medium",
                event,
                f"Slow average turn {avg_turn:.1f}; inspect sequencing and finisher timing.",
            )
        if not reasons:
            add_finding(
                findings,
                "medium",
                event,
                "Missing win/loss reason detail in aggregate output.",
            )
    return findings


def severity_counts(findings: list[dict[str, Any]]) -> dict[str, int]:
    counts = {"critical": 0, "high": 0, "medium": 0, "low": 0}
    for finding in findings:
        severity = str(finding.get("severity") or "low")
        counts[severity] = counts.get(severity, 0) + 1
    return counts


def audit_summary(
    *,
    turn_findings: list[dict[str, Any]],
    decision_findings: list[dict[str, Any]],
    event_count: int,
    decision_count: int,
) -> dict[str, Any]:
    counts = severity_counts(turn_findings + decision_findings)
    critical_or_high = counts.get("critical", 0) + counts.get("high", 0)
    return {
        "status": BLOCKED_STATUS if critical_or_high else CLEAN_STATUS,
        "status_scope": AUDIT_SCOPE,
        "structured_trace_usable": critical_or_high == 0,
        "human_replay_complete": NOT_EVALUATED,
        "rules_interaction_trusted": NOT_EVALUATED,
        "structured_events": event_count,
        "decision_traces": decision_count,
        "turn_findings": len(turn_findings),
        "decision_findings": len(decision_findings),
        "severity_counts": counts,
    }


def render_report(
    *,
    deck_id: int,
    baseline_id: int,
    baseline_findings: list[dict[str, Any]],
    turn_findings: list[dict[str, Any]],
    decision_findings: list[dict[str, Any]],
    event_count: int,
    decision_count: int,
    replay_files: list[tuple[Path, Path, Path | None]],
) -> str:
    summary = audit_summary(
        turn_findings=turn_findings,
        decision_findings=decision_findings,
        event_count=event_count,
        decision_count=decision_count,
    )
    counts = summary["severity_counts"]
    turn_counts = severity_counts(turn_findings)
    decision_counts = severity_counts(decision_findings)
    lines = [
        "# Hermes Replay Decision Audit",
        "",
        f"- deck_id: {deck_id}",
        f"- baseline_id: {baseline_id}",
        f"- status: {summary['status']}",
        f"- status_scope: {summary['status_scope']}",
        f"- structured_trace_usable: {summary['structured_trace_usable']}",
        f"- human_replay_complete: {summary['human_replay_complete']}",
        f"- rules_interaction_trusted: {summary['rules_interaction_trusted']}",
        f"- structured_events: {event_count}",
        f"- decision_traces: {decision_count}",
        f"- turn_findings: {len(turn_findings)}",
        f"- decision_findings: {len(decision_findings)}",
        f"- critical: {counts.get('critical', 0)}",
        f"- high: {counts.get('high', 0)}",
        f"- medium: {counts.get('medium', 0)}",
        f"- low: {counts.get('low', 0)}",
        "",
        "## Replay Files",
        "",
    ]
    if replay_files:
        for txt, jsonl, decision_jsonl in replay_files:
            lines.append(f"- text: `{txt}`")
            lines.append(f"- events: `{jsonl}`")
            if decision_jsonl:
                lines.append(f"- decision_trace: `{decision_jsonl}`")
    else:
        lines.append("- external events file was used.")

    lines.extend(
        [
            "",
            "## Turn-By-Turn Findings",
            "",
            "| Severity | Replay | Turn | Player | Event | Finding |",
            "| --- | --- | ---: | --- | --- | --- |",
        ]
    )
    if turn_findings:
        for finding in turn_findings:
            lines.append(
                "| {severity} | {replay_id} | {turn} | {player} | {event} | {finding} |".format(
                    **finding
                )
            )
    else:
        lines.append("| info | all | - | all | all | No turn-by-turn red flags found. |")

    lines.extend(
        [
            "",
            "## Decision Trace Findings",
            "",
            f"- critical/high: {decision_counts.get('critical', 0) + decision_counts.get('high', 0)}",
            f"- medium: {decision_counts.get('medium', 0)}",
            f"- low: {decision_counts.get('low', 0)}",
            "",
            "| Severity | Replay | Turn | Player | Event | Finding |",
            "| --- | --- | ---: | --- | --- | --- |",
        ]
    )
    if decision_findings:
        for finding in decision_findings:
            lines.append(
                "| {severity} | {replay_id} | {turn} | {player} | {event} | {finding} |".format(
                    **finding
                )
            )
    else:
        lines.append("| info | all | - | all | all | No decision-trace red flags found. |")

    lines.extend(
        [
            "",
            "## Aggregate Baseline Findings",
            "",
            "| Severity | Opponent | Finding |",
            "| --- | --- | --- |",
        ]
    )
    if baseline_findings:
        for finding in baseline_findings:
            lines.append(
                f"| {finding['severity']} | {finding['player']} | {finding['finding']} |"
            )
    else:
        lines.append("| info | all | No aggregate red flags found. |")

    lines.extend(
        [
            "",
            "## Gate Interpretation",
            "",
            "- `critical` or `high` turn findings block optimizer trust until battle logic is fixed.",
            "- `critical` or `high` decision findings block optimizer trust until trace quality is fixed.",
            "- This auditor only validates turn and decision-trace invariants; it does not prove human replay completeness or full rules-interaction trust.",
            "- `medium` findings require review before product-facing deck mutation.",
            "- `low` findings are polish/heuristic notes and do not block a Hermes-local experiment.",
            f"- Turn finding counts: {turn_counts}.",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--events", type=Path)
    parser.add_argument("--decision-trace", type=Path)
    parser.add_argument("--require-decision-trace", action="store_true")
    parser.add_argument("--skip-baseline", action="store_true", help="audit only replay/decision JSONL without optimizer DB")
    parser.add_argument("--generate", type=int, default=3, help="fresh replays to generate when --events is omitted")
    parser.add_argument("--seed-start", type=int, default=42)
    parser.add_argument("--report", action="store_true")
    parser.add_argument("--json-output", type=Path)
    args = parser.parse_args()

    if args.skip_baseline:
        baseline = {"id": 0}
        matchups = []
    else:
        with connect() as conn:
            ensure_optimizer_tables(conn)
            baseline = latest_baseline(conn, args.deck_id)
            if not baseline:
                raise SystemExit("No approved baseline found. Run baseline first.")
            payload = json.loads(baseline["result_json"])
            matchups = payload.get("matchups", [])

    replay_files: list[tuple[Path, Path, Path | None]] = []
    events: list[dict[str, Any]] = []
    decisions: list[dict[str, Any]] = []
    if args.events:
        events.extend(load_events(args.events))
        decision_path = args.decision_trace or decision_trace_path_for_events(args.events)
        if decision_path.exists():
            decisions.extend(load_decision_traces(decision_path))
        elif args.require_decision_trace:
            raise SystemExit(f"Decision trace file not found: {decision_path}")
    else:
        tmp_dir = writable_replay_dir(args.report)
        for seed in range(args.seed_start, args.seed_start + max(1, args.generate)):
            generated, generated_decisions, txt, jsonl, decision_jsonl = generate_replay_events(seed, tmp_dir)
            events.extend(generated)
            decisions.extend(generated_decisions)
            replay_files.append((txt, jsonl, decision_jsonl if decision_jsonl.exists() else None))
        if args.require_decision_trace and not decisions:
            raise SystemExit("Fresh replay generation did not produce decision traces.")

    turn_findings = audit_turn_events(events)
    decision_findings = audit_decision_traces(decisions)
    baseline_findings = aggregate_findings(matchups)
    markdown = render_report(
        deck_id=args.deck_id,
        baseline_id=baseline["id"],
        baseline_findings=baseline_findings,
        turn_findings=turn_findings,
        decision_findings=decision_findings,
        event_count=len(events),
        decision_count=len(decisions),
        replay_files=replay_files,
    )
    print(markdown)
    if args.report:
        path = write_report("master_optimizer_replay_audit", markdown)
        print(f"Report written: {path}")
    if args.json_output:
        summary = audit_summary(
            turn_findings=turn_findings,
            decision_findings=decision_findings,
            event_count=len(events),
            decision_count=len(decisions),
        )
        payload = {
            "summary": summary,
            "turn_findings": turn_findings,
            "decision_findings": decision_findings,
            "baseline_findings": baseline_findings,
            "replay_files": [
                {
                    "text": str(txt),
                    "events": str(jsonl),
                    "decision_trace": str(decision_jsonl) if decision_jsonl else None,
                }
                for txt, jsonl, decision_jsonl in replay_files
            ],
        }
        args.json_output.write_text(
            json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
