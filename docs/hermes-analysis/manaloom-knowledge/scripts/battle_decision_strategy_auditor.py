#!/usr/bin/env python3
"""Strategic decision auditor for Hermes battle replays.

This complements legal/forensic replay checks. A play can be legal while still
being a poor Commander decision, so this auditor focuses on traceability:
whether the replay explains why a mulligan, resource spend, combat or pass was
chosen and whether obvious strategic risks were recorded.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path
from typing import Any


REQUIRED_STRATEGY_FIELDS = {
    "strategic_principle",
    "heuristic_version",
    "resource_delta",
    "risk_flags",
    "alternatives_considered",
}

SEVERITY_ORDER = {
    "info": 1,
    "low": 2,
    "medium": 3,
    "high": 4,
}

HIGH_IMPACT_PAYOFF_EFFECTS = {
    "approach",
    "board_wipe",
    "copy_spell",
    "draw_engine",
    "finisher",
    "overload_recursion",
    "protection",
    "remove_creature",
    "remove_permanent",
    "silence_opponents",
    "steal_all_creatures",
    "token_maker",
    "wincon",
    "worldfire_reset",
}

RESOURCE_BENEFIT_REASONS = {
    "flexible_color_fixing",
    "high_value_land_target",
    "net_land_count_increase",
    "no_scarce_land_risk",
    "untapped_net_mana_upgrade",
}

SAME_TURN_UNLOCK_REASONS = {
    "same_turn_castable_spell",
    "same_turn_commander_cast",
    "same_turn_high_impact_spell",
}

BAD_FORCED_KEEP_RISK_FLAGS = {
    "expensive_dead_hand",
    "mana_screw",
    "no_early_game_plan",
    "too_few_lands",
}

LOW_CONFIDENCE_LEARNING_CODES = {
    "forced_keep_after_bad_mulligan",
}

GLOBAL_LEARNING_ELIGIBILITY_POLICY = (
    "requires_high_confidence_strategy_seed_and_all_mandatory_gates_pass"
)

WHEEL_SCOPES_WITH_MODELED_OPPONENT_DELTAS = {
    "multiplayer_discard_draw_v1",
    "wheel_of_misfortune_secret_number_compact_v1",
}


def load_jsonl(path: Path | None) -> list[dict[str, Any]]:
    if path is None or not path.exists():
        return []
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for index, line in enumerate(handle, start=1):
            text = line.strip()
            if not text:
                continue
            payload = json.loads(text)
            payload.setdefault("line", index)
            rows.append(payload)
    return rows


def finding(
    severity: str,
    code: str,
    detail: str,
    recommendation: str,
    *,
    decision_id: str | None = None,
    event_index: int | None = None,
) -> dict[str, Any]:
    return {
        "severity": severity,
        "code": code,
        "decision_id": decision_id,
        "event_index": event_index,
        "detail": detail,
        "recommendation": recommendation,
    }


def option_action(option: dict[str, Any] | None) -> str:
    option = option or {}
    return str(option.get("action") or option.get("card") or "")


def has_score(decision: dict[str, Any], key: str) -> bool:
    return key in (decision.get("score_components") or {})


def _float_or_none(value: Any) -> float | None:
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _forced_keep_bad_reasons(decision: dict[str, Any], chosen: dict[str, Any], risk_flags: set[str]) -> list[str]:
    score = decision.get("score_components") or {}
    resource_delta = decision.get("resource_delta") or {}
    reasons = sorted(BAD_FORCED_KEEP_RISK_FLAGS & risk_flags)
    reason = str(chosen.get("reason") or decision.get("reason") or score.get("reason") or "")
    if reason == "too_few_lands" and "too_few_lands" not in reasons:
        reasons.append("too_few_lands")
    lands = _float_or_none(
        chosen.get("lands")
        if chosen.get("lands") is not None
        else score.get("lands")
        if score.get("lands") is not None
        else resource_delta.get("lands")
    )
    if lands is not None and lands <= 1 and "too_few_lands" not in reasons:
        reasons.append("too_few_lands")
    score_values = [
        chosen.get("score"),
        decision.get("chosen_option_score"),
        decision.get("expected_benefit_score"),
        score.get("score"),
        score.get("keep_score"),
        score.get("hand_score"),
        score.get("total_score"),
    ]
    if any((value := _float_or_none(score_value)) is not None and value < 0 for score_value in score_values):
        reasons.append("negative_keep_score")
    return reasons


def audit_decision(decision: dict[str, Any]) -> list[dict[str, Any]]:
    decision_id = str(decision.get("decision_id") or "?")
    decision_type = str(decision.get("decision_type") or "unknown")
    chosen = decision.get("chosen_option") or {}
    risk_flags = set(decision.get("risk_flags") or [])
    score = decision.get("score_components") or {}
    resource_delta = decision.get("resource_delta") or {}
    findings: list[dict[str, Any]] = []

    missing = [
        field
        for field in sorted(REQUIRED_STRATEGY_FIELDS)
        if field not in decision
    ]
    if missing:
        findings.append(finding(
            "low",
            "missing_strategy_fields",
            f"Decision trace lacks strategy fields: {', '.join(missing)}.",
            "Emit complete decision_trace_v1 strategy metadata before trusting this replay for learning.",
            decision_id=decision_id,
        ))

    if decision_type == "mulligan_decision":
        action = option_action(chosen)
        forced = bool(chosen.get("forced_keep"))
        if action == "keep" and "no_early_game_plan" in risk_flags and not forced:
            findings.append(finding(
                "high",
                "mulligan_keep_without_early_plan",
                "Opening hand was kept even though the trace marks no early game plan.",
                "Mulligan policy must consider curve, ramp, draw/filter and payoff, not only land count.",
                decision_id=decision_id,
            ))
        bad_forced_keep_reasons = _forced_keep_bad_reasons(decision, chosen, risk_flags)
        if (
            action == "keep"
            and forced
            and (
                "forced_keep_after_mulligan_cap" in risk_flags
                or bad_forced_keep_reasons
            )
            and bad_forced_keep_reasons
        ):
            findings.append(finding(
                "medium",
                "forced_keep_after_bad_mulligan",
                "Mulligan cap forced a risky keep: "
                + ", ".join(sorted(set(bad_forced_keep_reasons)))
                + ".",
                "Track this replay separately; do not treat resulting WR as high-confidence deck quality.",
                decision_id=decision_id,
            ))
        if not decision.get("alternatives_considered"):
            findings.append(finding(
                "medium",
                "mulligan_without_hand_summary",
                "Mulligan decision does not include hand summary.",
                "Include lands, colors, early plays, ramp, draw/filter and expensive cards.",
                decision_id=decision_id,
            ))

    if decision_type == "cast_spell":
        chosen_effect = str(chosen.get("effect") or resource_delta.get("effect") or "")
        if chosen_effect == "ramp_ritual" or "one_shot_mana" in risk_flags:
            if (
                not has_score(decision, "unlocks_same_turn_action")
                or not resource_delta.get("unlock_card")
                or not (resource_delta.get("unlock_reason") or decision.get("expected_payoff_reason"))
            ):
                findings.append(finding(
                    "high",
                    "ramp_ritual_without_unlock_signal",
                    "One-shot mana was chosen without recording the immediate payoff card/reason it unlocks.",
                    "Spend Lotus Petal/ritual mana only when it unlocks a same-turn relevant action, protection or win attempt.",
                    decision_id=decision_id,
                ))
        if resource_delta.get("requires_discard_land") and "requires_land_discard" not in risk_flags:
            findings.append(finding(
                "low",
                "land_discard_missing_risk_flag",
                "Cast requires land discard but trace lacks the corresponding risk flag.",
                "Record land discard as a resource risk for Mox Diamond-style plays.",
                decision_id=decision_id,
            ))
        if (
            resource_delta.get("requires_discard_land")
            or resource_delta.get("requires_sacrifice_land")
        ) and ({"spending_last_land", "spending_unique_color_land"} & risk_flags):
            if not (
                resource_delta.get("strategic_benefit_reason")
                or resource_delta.get("unlock_card")
                or decision.get("expected_payoff_reason")
            ):
                findings.append(finding(
                    "medium",
                    "resource_risk_without_payoff_reason",
                    "Scarce-land ramp spend was recorded without explicit payoff or benefit reason.",
                    "Record the unlocked spell/commander or the strategic land benefit before treating this decision as learning-quality.",
                    decision_id=decision_id,
                ))

    if decision_type == "pass_no_action":
        if not decision.get("reason") and not score and not risk_flags:
            findings.append(finding(
                "medium",
                "pass_without_context",
                "Pass/no-action decision lacks reason, score and risk context.",
                "Record whether the player had no options, held instant-speed interaction, or rejected a low-value play.",
                decision_id=decision_id,
            ))

    if decision_type == "tutor":
        if not decision.get("available_options"):
            findings.append(finding(
                "medium",
                "tutor_without_candidates",
                "Tutor resolved without candidate options in the decision trace.",
                "Record legal candidates and selected target before using tutor decisions for learning.",
                decision_id=decision_id,
            ))
        if chosen.get("action") == "no_target":
            findings.append(finding(
                "medium",
                "tutor_no_target",
                "Tutor did not find a target.",
                "Treat this replay as low-confidence unless the no-target result is expected by the card text.",
                decision_id=decision_id,
            ))
        if not score.get("selected_reason"):
            findings.append(finding(
                "low",
                "tutor_without_selected_reason",
                "Tutor target lacks a selected_reason score component.",
                "Explain whether the target was mana, interaction, engine, setup or win condition.",
                decision_id=decision_id,
            ))

    if decision_type == "board_wipe":
        spell_already_resolving = decision.get("rejected_reason") == "spell_already_resolving"
        if spell_already_resolving:
            pass
        elif "wipe_without_timing_justification" in risk_flags:
            findings.append(finding(
                "medium",
                "board_wipe_without_timing_justification",
                "Board wipe resolved without lethal pressure, board disadvantage, asymmetry, or rebuild plan.",
                "Gate board wipes on being behind, preventing lethal, asymmetric, or backed by a clear post-wipe plan.",
                decision_id=decision_id,
            ))
        elif (
            "wipe_without_clear_asymmetry" in risk_flags
            and not score.get("rebuild_plan")
            and not score.get("behind_on_board")
        ):
            findings.append(finding(
                "medium",
                "board_wipe_without_clear_asymmetry",
                "Board wipe resolved without positive creature asymmetry or lethal-pressure reason.",
                "Use wipes when behind, preventing lethal, asymmetric, or backed by a clear post-wipe plan.",
                decision_id=decision_id,
            ))

    if decision_type == "worldfire_reset":
        if not score.get("known_follow_up_line") or "worldfire_without_known_win_line" in risk_flags:
            findings.append(finding(
                "medium",
                "worldfire_without_known_win_line",
                "Worldfire-style reset resolved without a recorded post-reset win line.",
                "Only trust Worldfire decisions when the trace proves an immediate post-reset line such as damage on resolution or another modeled deterministic closer.",
                decision_id=decision_id,
            ))

    if decision_type == "wheel":
        model_scope = str(score.get("model_scope") or "")
        timing_justified = bool(score.get("timing_justified"))
        wheel_payoffs = score.get("wheel_payoffs") or []
        if (
            "wheel_model_simplified" in risk_flags
            and model_scope not in WHEEL_SCOPES_WITH_MODELED_OPPONENT_DELTAS
        ):
            findings.append(finding(
                "medium",
                "wheel_model_simplified",
                "Wheel-like card is modeled as self-draw only.",
                "Do not trust wheel decisions for learning until opponent discard/draw and payoff denial are modeled.",
                decision_id=decision_id,
            ))
        if "opponent_refill_risk" in risk_flags and not timing_justified and not wheel_payoffs:
            findings.append(finding(
                "medium",
                "wheel_opponent_refill_risk",
                "Wheel may refill opponents without a recorded payoff.",
                "Wheel only when the player gains more, disrupts a known plan, or has a payoff such as Smothering Tithe/Notion Thief.",
                decision_id=decision_id,
            ))

    return findings


def immediate_payoff_after_resource_spend(
    events: list[dict[str, Any]],
    index: int,
    resource_event: dict[str, Any],
    *,
    window: int = 12,
) -> dict[str, Any] | None:
    """Return the next meaningful same-turn payoff after spending a scarce resource."""
    player = resource_event.get("player")
    turn = resource_event.get("turn")
    spent_card = resource_event.get("card")
    if not player or turn is None:
        return None
    for candidate in events[index : index + window]:
        if candidate.get("player") != player or candidate.get("turn") != turn:
            continue
        kind = candidate.get("event")
        if kind == "commander_cast":
            return {
                "event": kind,
                "card": candidate.get("card"),
                "reason": "same_turn_commander_cast",
            }
        if kind in {"spell_cast", "creature_cast", "miracle_cast", "end_step_instant"}:
            if candidate.get("card") == spent_card:
                continue
            effect = str(candidate.get("effect") or "unknown")
            if effect in HIGH_IMPACT_PAYOFF_EFFECTS:
                return {
                    "event": kind,
                    "card": candidate.get("card"),
                    "effect": effect,
                    "reason": "same_turn_high_impact_spell",
                }
    return None


def documented_resource_benefit(resource_event: dict[str, Any]) -> dict[str, Any] | None:
    reason = str(resource_event.get("strategic_benefit_reason") or "")
    if reason in RESOURCE_BENEFIT_REASONS:
        return {
            "event": resource_event.get("event"),
            "card": resource_event.get("card"),
            "reason": reason,
        }
    unlock_reason = str(resource_event.get("unlock_reason") or "")
    unlock_card = resource_event.get("unlock_card")
    if unlock_card and (
        unlock_reason in SAME_TURN_UNLOCK_REASONS
        or resource_event.get("unlocks_same_turn_action")
    ):
        return {
            "event": resource_event.get("event"),
            "card": unlock_card,
            "reason": unlock_reason or "documented_same_turn_unlock",
        }
    return None


def audit_events(events: list[dict[str, Any]]) -> list[dict[str, Any]]:
    findings: list[dict[str, Any]] = []
    for index, event in enumerate(events, start=1):
        if event.get("event") not in {"additional_cost_paid", "additional_cost_failed"}:
            continue
        cost = event.get("cost")
        if cost not in {"discard_land", "sacrifice_land"}:
            continue
        risk_flags = set(event.get("strategic_risk_flags") or [])
        if (
            event.get("event") == "additional_cost_failed"
            and "no_land_options" in risk_flags
        ):
            continue
        if not event.get("selection_reason") or not event.get("land_options"):
            severity = "medium" if event.get("event") == "additional_cost_paid" else "low"
            findings.append(finding(
                severity,
                "resource_cost_without_selection_context",
                f"{cost} event lacks land option/selection context.",
                "Record considered lands and selection reason before using this replay for strategy learning.",
                event_index=index,
            ))
        payoff = documented_resource_benefit(event) or immediate_payoff_after_resource_spend(events, index, event)
        if "spending_last_land" in risk_flags:
            if not payoff:
                findings.append(finding(
                    "high",
                    "spending_last_land",
                    f"{cost} consumed the player's last available land.",
                    "Only allow this with explicit same-turn payoff or emergency reason.",
                    event_index=index,
                ))
        if "spending_unique_color_land" in risk_flags:
            if not payoff:
                findings.append(finding(
                    "medium",
                    "spending_unique_color_land",
                    f"{cost} consumed a land that provides a unique color.",
                    "Prefer redundant/off-plan lands unless the payoff is explicitly worth color loss.",
                    event_index=index,
                ))
    return findings


def audit_strategy(
    events: list[dict[str, Any]],
    decisions: list[dict[str, Any]],
) -> dict[str, Any]:
    findings: list[dict[str, Any]] = []
    decision_types: Counter[str] = Counter()
    for decision in decisions:
        decision_types[str(decision.get("decision_type") or "unknown")] += 1
        findings.extend(audit_decision(decision))
    findings.extend(audit_events(events))

    low_confidence_findings = [
        item for item in findings if item["code"] in LOW_CONFIDENCE_LEARNING_CODES
    ]
    non_low_confidence_findings = [
        item for item in findings if item["code"] not in LOW_CONFIDENCE_LEARNING_CODES
    ]
    severity_counts: Counter[str] = Counter(f["severity"] for f in findings)
    code_counts: Counter[str] = Counter(f["code"] for f in findings)
    review_severity_counts: Counter[str] = Counter(
        f["severity"] for f in non_low_confidence_findings
    )
    highest = "info"
    for severity in severity_counts:
        if SEVERITY_ORDER.get(severity, 0) > SEVERITY_ORDER.get(highest, 0):
            highest = severity
    highest_review = "info"
    for severity in review_severity_counts:
        if SEVERITY_ORDER.get(severity, 0) > SEVERITY_ORDER.get(highest_review, 0):
            highest_review = severity
    if non_low_confidence_findings:
        verdict = "blocked" if highest_review in {"high"} else (
            "needs_review" if highest_review in {"medium"} else "usable_for_strategy_learning"
        )
    elif low_confidence_findings:
        verdict = "low_confidence_replay"
    else:
        verdict = "usable_for_strategy_learning"
    if low_confidence_findings and not non_low_confidence_findings:
        learning_confidence = "low_confidence_replay"
        high_confidence_learning_eligible = False
        high_confidence_learning_weight = 0.0
        learning_confidence_reason = "forced_keep_after_bad_mulligan"
    elif verdict == "usable_for_strategy_learning":
        learning_confidence = "high_confidence_replay"
        high_confidence_learning_eligible = True
        high_confidence_learning_weight = 1.0
        learning_confidence_reason = "no_strategy_findings"
    else:
        learning_confidence = "not_learning_eligible"
        high_confidence_learning_eligible = False
        high_confidence_learning_weight = 0.0
        learning_confidence_reason = "strategy_findings_require_review"
    return {
        "summary": {
            "events": len(events),
            "decisions": len(decisions),
            "findings": len(findings),
            "review_required_findings": len(non_low_confidence_findings),
            "low_confidence_learning_findings": len(low_confidence_findings),
            "verdict": verdict,
            "learning_confidence": learning_confidence,
            "learning_confidence_reason": learning_confidence_reason,
            "high_confidence_learning_eligible": high_confidence_learning_eligible,
            "high_confidence_learning_weight": high_confidence_learning_weight,
            "low_confidence_learning_codes": sorted({
                item["code"] for item in low_confidence_findings
            }),
            "highest_severity": highest if findings else "none",
            "severity_counts": dict(sorted(severity_counts.items())),
            "decision_types": dict(sorted(decision_types.items())),
            "code_counts": dict(sorted(code_counts.items())),
        },
        "findings": findings,
    }


def _dedup_reasons(reasons: list[Any]) -> list[str]:
    deduped: list[str] = []
    seen: set[str] = set()
    for reason in reasons:
        text = str(reason or "").strip()
        if not text or text in seen:
            continue
        seen.add(text)
        deduped.append(text)
    return deduped


def _positive_int(value: Any) -> int:
    try:
        parsed = int(value or 0)
    except (TypeError, ValueError):
        return 0
    return max(0, parsed)


def _append_count_reason(reasons: list[str], row: dict[str, Any], field: str, label: str) -> None:
    value = _positive_int(row.get(field))
    if value:
        reasons.append(f"{label}={value}")


def compute_global_learning_eligibility(
    seed_gate_rows: list[dict[str, Any]],
    *,
    final_status: str | None,
    mandatory_gate_divergences: list[str] | None = None,
) -> dict[str, Any]:
    """Return global learning eligibility after all mandatory gates are known."""
    eligible: list[str] = []
    not_eligible: list[str] = []
    reasons_by_seed: dict[str, list[str]] = {}
    divergences = [str(item) for item in (mandatory_gate_divergences or []) if item]
    run_blocks_learning = final_status != "trusted_for_strategy_learning"

    for row in seed_gate_rows:
        seed = str(row.get("seed") or row.get("seed_name") or "").strip()
        if not seed:
            continue
        reasons = [str(item) for item in (row.get("reasons") or []) if item]
        strategy_confidence = str(row.get("strategy_confidence") or "unknown")
        if strategy_confidence != "high_confidence_replay":
            reasons.append(f"strategy_audit:{strategy_confidence}")
        _append_count_reason(reasons, row, "action_findings", "action_critic_findings")
        _append_count_reason(
            reasons,
            row,
            "strategy_review_required_findings",
            "strategy_review_required_findings",
        )
        _append_count_reason(
            reasons,
            row,
            "decision_turn_findings",
            "replay_decision_turn_findings",
        )
        _append_count_reason(
            reasons,
            row,
            "decision_decision_findings",
            "replay_decision_findings",
        )
        _append_count_reason(reasons, row, "forensic_rule_findings", "forensic_rule_findings")
        _append_count_reason(reasons, row, "forensic_turn_findings", "forensic_turn_findings")
        if row.get("action_high_or_critical"):
            reasons.append("action_critic_high_or_critical")
        if row.get("strategy_blocked"):
            reasons.append("strategy_audit:blocked")
        if row.get("decision_high_or_critical"):
            reasons.append("replay_decision_audit_high_or_critical")
        if row.get("forensic_high_or_critical"):
            reasons.append("forensic_audit_high_or_critical")
        if run_blocks_learning:
            reasons.append(f"final_status:{final_status or 'unknown'}")
            for divergence in divergences:
                reasons.append(f"mandatory_gate:{divergence}")

        seed_reasons = _dedup_reasons(reasons)
        reasons_by_seed[seed] = seed_reasons
        if seed_reasons:
            not_eligible.append(seed)
        else:
            eligible.append(seed)

    return {
        "global_learning_eligibility_policy": GLOBAL_LEARNING_ELIGIBILITY_POLICY,
        "global_learning_eligible_seeds": eligible,
        "global_not_learning_eligible_seeds": not_eligible,
        "global_learning_eligibility_reasons": reasons_by_seed,
    }


def _common_value(values: list[Any]) -> Any:
    unique: list[Any] = []
    for value in values:
        if value not in unique:
            unique.append(value)
    if len(unique) == 1:
        return unique[0]
    return unique


def _source_row_id(source_ref: str) -> int | str | None:
    if not source_ref.startswith("learned_deck:"):
        return None
    suffix = source_ref.split(":", 1)[1]
    try:
        return int(suffix)
    except ValueError:
        return suffix or None


def summarize_learned_opponent_provenance(rows: list[dict[str, Any]]) -> dict[str, Any]:
    """Aggregate learned-deck opponent provenance rows for the audit summary."""
    grouped: dict[tuple[str, str, str, str], dict[str, Any]] = {}
    source_counts: Counter[str] = Counter()
    construction_missing = 0
    coherence_missing = 0

    for row in rows:
        source_kind = str(row.get("source_kind") or "")
        source_ref = str(row.get("source_ref") or "")
        if source_kind != "learned_decks" and not source_ref.startswith("learned_deck:"):
            continue
        source_system = str(row.get("source_system") or "unknown")
        source_url = str(row.get("source_url") or "")
        name = str(row.get("name") or source_ref or "unknown")
        key = (source_system, source_ref, source_url, name)
        item = grouped.setdefault(
            key,
            {
                "source_system": source_system,
                "source_ref": source_ref,
                "source_url": source_url or None,
                "source_row_id": _source_row_id(source_ref),
                "name": name,
                "commander": row.get("commander"),
                "deck_name": row.get("deck_name"),
                "appearances": 0,
                "seeds": [],
                "_source_card_counts": [],
                "_battle_card_counts": [],
                "_metrics_basis": [],
                "_cached_metadata_used": [],
                "_blocker_domains": [],
                "_construction_present": 0,
                "_coherence_present": 0,
                "metrics_sample": row.get("metrics") or {},
            },
        )
        item["appearances"] += 1
        seed = str(row.get("seed") or "").replace("seed_", "")
        if seed and seed not in item["seeds"]:
            item["seeds"].append(seed)
        item["_source_card_counts"].append(row.get("source_card_count"))
        item["_battle_card_counts"].append(row.get("battle_card_count"))
        item["_metrics_basis"].append(row.get("metrics_basis"))
        item["_cached_metadata_used"].append(row.get("cached_metadata_used_for_metrics"))
        item["_blocker_domains"].append(row.get("blocker_domain") or "none")
        if row.get("construction_report"):
            item["_construction_present"] += 1
        else:
            construction_missing += 1
        if row.get("deck_coherence_report"):
            item["_coherence_present"] += 1
        else:
            coherence_missing += 1
        source_counts.update([source_system])

    opponents: list[dict[str, Any]] = []
    for item in sorted(grouped.values(), key=lambda value: (str(value["source_system"]), str(value["source_ref"]), str(value["name"]))):
        appearances = int(item.pop("appearances"))
        construction_present = int(item.pop("_construction_present"))
        coherence_present = int(item.pop("_coherence_present"))
        source_card_counts = item.pop("_source_card_counts")
        battle_card_counts = item.pop("_battle_card_counts")
        metrics_basis = item.pop("_metrics_basis")
        cached_metadata = item.pop("_cached_metadata_used")
        blocker_domains = item.pop("_blocker_domains")
        item["appearances"] = appearances
        item["seeds"] = sorted(
            item["seeds"],
            key=lambda seed: (0, int(seed)) if str(seed).isdigit() else (1, str(seed)),
        )
        item["source_card_count"] = _common_value(source_card_counts)
        item["battle_card_count"] = _common_value(battle_card_counts)
        item["metrics_basis"] = _common_value(metrics_basis)
        item["cached_metadata_used_for_metrics"] = _common_value(cached_metadata)
        item["blocker_domain"] = _common_value(blocker_domains)
        item["construction_report_present"] = construction_present == appearances
        item["deck_coherence_report_present"] = coherence_present == appearances
        item["construction_status"] = (
            "present"
            if construction_present == appearances
            else "waived_not_emitted_by_replay_deck_provenance"
        )
        item["deck_coherence_status"] = (
            "present"
            if coherence_present == appearances
            else "waived_not_emitted_by_replay_deck_provenance"
        )
        item["source_url_status"] = "present" if item.get("source_url") else "missing_from_local_knowledge_db"
        if construction_present != appearances or coherence_present != appearances:
            item["waiver_reason"] = (
                "learned_deck_construction_and_coherence_reports_not_emitted_by_battle_replay_deck_provenance"
            )
        item["provenance_status"] = (
            "source_identity_and_shape_present_with_coherence_waiver"
            if item.get("waiver_reason")
            else "source_identity_shape_and_coherence_present"
        )
        opponents.append(item)

    appearance_count = sum(int(item["appearances"]) for item in opponents)
    provenance = {
        "status": (
            "learned_opponent_provenance_present"
            if opponents and construction_missing == 0 and coherence_missing == 0
            else "learned_opponent_provenance_present_with_shape_waiver"
            if opponents
            else "no_learned_opponents_observed"
        ),
        "learned_opponent_unique_count": len(opponents),
        "learned_opponent_appearance_count": appearance_count,
        "source_counts": dict(sorted(source_counts.items())),
        "construction_report_missing_count": construction_missing,
        "deck_coherence_report_missing_count": coherence_missing,
        "source_url_missing_count": sum(1 for item in opponents if not item.get("source_url")),
        "waiver_reason": (
            "learned_deck_construction_and_coherence_reports_not_emitted_by_battle_replay_deck_provenance"
            if construction_missing or coherence_missing
            else None
        ),
    }
    return {
        "learned_deck_opponents": opponents,
        "opponent_deck_provenance": provenance,
        "learned_opponent_source_counts": dict(sorted(source_counts.items())),
    }


def md(value: Any) -> str:
    return str(value if value is not None else "").replace("|", "\\|").replace("\n", " ")


def render_markdown(result: dict[str, Any]) -> str:
    summary = result["summary"]
    lines = [
        "# Battle Decision Strategy Auditor",
        "",
        "This report flags strategically weak or insufficiently explained decisions. It is not a judge-engine legality report.",
        "",
        "## Summary",
        "",
        f"- Verdict: `{summary['verdict']}`",
        f"- Learning confidence: `{summary['learning_confidence']}`",
        f"- High-confidence learning eligible: `{summary['high_confidence_learning_eligible']}`",
        f"- High-confidence learning weight: `{summary['high_confidence_learning_weight']}`",
        f"- Learning confidence reason: `{summary['learning_confidence_reason']}`",
        f"- Decisions: `{summary['decisions']}`",
        f"- Events: `{summary['events']}`",
        f"- Findings: `{summary['findings']}`",
        f"- Highest severity: `{summary['highest_severity']}`",
        f"- Severity counts: `{json.dumps(summary['severity_counts'], sort_keys=True)}`",
        f"- Decision types: `{json.dumps(summary['decision_types'], sort_keys=True)}`",
        "",
        "## Findings",
        "",
        "| Severity | Code | Decision/Event | Detail | Recommendation |",
        "|---|---|---|---|---|",
    ]
    for item in result["findings"]:
        ref = item.get("decision_id") or item.get("event_index") or "-"
        lines.append(
            f"| {md(item['severity'])} | {md(item['code'])} | {md(ref)} | {md(item['detail'])} | {md(item['recommendation'])} |"
        )
    if not result["findings"]:
        lines.append("| ok | none | - | No strategic findings emitted. | Continue sampling before trusting aggregate WR. |")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--events", type=Path, required=True)
    parser.add_argument("--decision-trace", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--json-output", type=Path)
    args = parser.parse_args()

    events = load_jsonl(args.events)
    decisions = load_jsonl(args.decision_trace)
    result = audit_strategy(events, decisions)

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(render_markdown(result), encoding="utf-8")
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(result, indent=2, sort_keys=True), encoding="utf-8")
    print("BATTLE_DECISION_STRATEGY_AUDIT", json.dumps(result["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
