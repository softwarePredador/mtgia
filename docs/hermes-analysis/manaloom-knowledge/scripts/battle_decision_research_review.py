#!/usr/bin/env python3
"""Aggregate replay decisions against researched Commander strategy principles.

The source matrix is intentionally embedded and conservative. Official sources
define legality; strategy/community sources only calibrate what the auditor
should ask the replay to justify.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


SOURCE_MATRIX: dict[str, dict[str, Any]] = {
    "mulligan": {
        "decision_types": {"mulligan_decision"},
        "finding_codes": {"mulligan_keep_without_early_plan", "forced_keep_after_bad_mulligan"},
        "official_sources": [
            "https://magic.wizards.com/en/news/announcements/london-mulligan-2019-06-03",
        ],
        "strategy_sources": [
            "https://draftsim.com/mtg-mulligan-rules/",
            "https://www.reddit.com/r/EDH/comments/row17n/commanders_that_play_well_at_instant_speed/",
        ],
        "expected_trace": "lands, colors, early plays, cheap ramp, draw/filter, high-cost dead cards and bottomed cards",
        "current_guardrail": "Do not keep only because land count is acceptable.",
    },
    "fast_mana_one_shot": {
        "decision_types": {"cast_spell"},
        "finding_codes": {"ramp_ritual_without_unlock_signal"},
        "official_sources": [
            "https://scryfall.com/card/tmp/294/lotus-petal",
        ],
        "strategy_sources": [
            "https://www.mtgsalvation.com/forums/the-game/commander-edh/815542-run-more-interaction-run-more-fast-mana-or-the",
        ],
        "expected_trace": "whether the one-shot mana unlocks a same-turn relevant spell, protection, interaction or win attempt",
        "current_guardrail": "Lotus Petal/ritual mana must not be spent just because it is available.",
    },
    "mox_land_discard": {
        "decision_types": {"cast_spell"},
        "finding_codes": {"spending_last_land", "spending_unique_color_land", "land_discard_missing_risk_flag"},
        "finding_detail_contains": {"discard_land"},
        "official_sources": [
            "https://scryfall.com/card/sth/138/mox-diamond",
        ],
        "strategy_sources": [
            "https://www.mtgsalvation.com/forums/magic-fundamentals/magic-rulings/magic-rulings-archives/289402-mox-diamond-question",
        ],
        "expected_trace": "land options, discarded land, unique colors, last-land risk and immediate payoff",
        "current_guardrail": "Mox Diamond can be legal but remains suspicious if it discards the last/unique land without immediate payoff.",
    },
    "sacrifice_land": {
        "decision_types": {"cast_spell"},
        "finding_codes": {
            "resource_cost_without_selection_context",
            "spending_last_land",
            "spending_unique_color_land",
        },
        "finding_detail_contains": {"sacrifice_land"},
        "official_sources": [
            "https://magic.wizards.com/en/rules",
        ],
        "strategy_sources": [
            "https://www.mtgsalvation.com/forums/the-game/commander-edh/203106-threat-assessment-a-guide",
        ],
        "expected_trace": "land options, sacrificed land, target searched, mana screw risk and counter risk",
        "current_guardrail": "Land sacrifice must explain the net benefit, not only that the cost was payable.",
    },
    "cast_spell": {
        "decision_types": {"cast_spell"},
        "finding_codes": {"missing_strategy_fields"},
        "official_sources": [
            "https://magic.wizards.com/en/rules",
        ],
        "strategy_sources": [
            "https://blog.cardkingdom.com/threat-assessment-in-commander/",
        ],
        "expected_trace": "role, mana before, available alternatives, chosen payoff and rejected reason",
        "current_guardrail": "Casting should support curve, plan, threat response or material advantage.",
    },
    "response": {
        "decision_types": {"response"},
        "finding_codes": set(),
        "official_sources": [
            "https://magic.wizards.com/en/rules",
        ],
        "strategy_sources": [
            "https://blog.cardkingdom.com/threat-assessment-in-commander/",
            "https://www.mtgsalvation.com/forums/the-game/commander-edh/203106-threat-assessment-a-guide",
        ],
        "expected_trace": "threat score, stack object, response options, why the response is worth spending",
        "current_guardrail": "Interaction should prioritize win attempts, engines, board wipes, lethal and commander-critical threats.",
    },
    "combat_attack": {
        "decision_types": {"combat_attack"},
        "finding_codes": set(),
        "official_sources": [
            "https://magic.wizards.com/en/formats/commander",
        ],
        "strategy_sources": [
            "https://www.reddit.com/r/EDH/comments/186dv0v/how_do_you_decide_who_to_attack/",
            "https://www.mtgsalvation.com/forums/the-game/commander-edh/203106-threat-assessment-a-guide",
        ],
        "expected_trace": "target reason, total power, lethal, commander damage, crackback and multi-defender context",
        "current_guardrail": "Attack target must not be arbitrary; multiplayer threat assessment matters.",
    },
    "pass_no_action": {
        "decision_types": {"pass_no_action"},
        "finding_codes": {"pass_without_context"},
        "official_sources": [
            "https://magic.wizards.com/en/rules",
        ],
        "strategy_sources": [
            "https://www.reddit.com/r/EDH/comments/row17n/commanders_that_play_well_at_instant_speed/",
        ],
        "expected_trace": "no legal/profitable options, holding interaction, preserving resource or political reason",
        "current_guardrail": "A pass must be explainable when playable options exist.",
    },
    "tutor": {
        "decision_types": {"tutor"},
        "finding_codes": {"tutor_without_candidates", "tutor_no_target", "tutor_without_selected_reason"},
        "official_sources": [
            "https://magic.wizards.com/en/rules",
        ],
        "strategy_sources": [
            "https://www.coolstuffinc.com/a/brucerichard-04062020-do-tutors-make-commander-games-better",
            "https://draftsim.com/mtg-tutors/",
        ],
        "expected_trace": "target selected by state: mana, answer, engine, wincon, protection or setup",
        "current_guardrail": "Tutor target must be justified by mana, interaction, engine, wincon, protection or setup context.",
    },
    "board_wipe_wheel": {
        "decision_types": {"board_wipe", "wheel"},
        "finding_codes": {
            "board_wipe_without_clear_asymmetry",
            "board_wipe_without_timing_justification",
            "wheel_model_simplified",
            "wheel_opponent_refill_risk",
        },
        "official_sources": [
            "https://magic.wizards.com/en/rules",
            "https://scryfall.com/card/3ed/185/wheel-of-fortune",
        ],
        "strategy_sources": [
            "https://www.playedh.com/articles/board-wipes-top10",
            "https://blog.cardkingdom.com/how-to-pick-a-board-wipe-commander/",
        ],
        "expected_trace": "behind/ahead status, asymmetry, lethal prevention, hand quality and post-wipe/wheel follow-up",
        "current_guardrail": "Wipe/wheel timing must be state-based before it teaches optimization.",
    },
}


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        text = line.strip()
        if text:
            rows.append(json.loads(text))
    return rows


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def seed_dirs(input_dir: Path) -> list[Path]:
    direct = sorted(path for path in input_dir.glob("seed_*") if path.is_dir())
    if direct:
        return direct
    return sorted(path for path in input_dir.glob("*/seed_*") if path.is_dir())


def classify_status(
    *,
    observed_decisions: int,
    finding_count: int,
    high_or_medium: int,
    tracked_gap: bool,
) -> str:
    if high_or_medium:
        return "blocked_or_needs_review"
    if finding_count:
        return "minor_findings"
    if tracked_gap and not observed_decisions:
        return "tracked_gap_not_observed"
    if tracked_gap:
        return "tracked_gap_partial"
    if observed_decisions:
        return "coherent_in_sample"
    return "not_observed"


def finding_sample(
    *,
    seed: str,
    item: dict[str, Any],
    decision: dict[str, Any] | None,
) -> dict[str, Any]:
    decision = decision or {}
    return {
        "seed": seed,
        "decision_id": item.get("decision_id"),
        "decision_type": decision.get("decision_type"),
        "code": str(item.get("code") or "unknown"),
        "severity": str(item.get("severity") or "unknown"),
        "detail": str(item.get("detail") or ""),
        "recommendation": item.get("recommendation"),
        "chosen_option": decision.get("chosen_option"),
        "reason": decision.get("reason"),
        "risk_flags": decision.get("risk_flags"),
        "player": decision.get("player"),
        "turn": decision.get("turn"),
        "phase": decision.get("phase"),
        "actual_outcome": decision.get("actual_outcome"),
    }


def aggregate(input_dir: Path) -> dict[str, Any]:
    decision_counts: Counter[str] = Counter()
    finding_counts: Counter[str] = Counter()
    strategy_learning_confidence_counts: Counter[str] = Counter()
    severity_by_code: dict[str, Counter[str]] = defaultdict(Counter)
    finding_items: list[dict[str, Any]] = []
    examples: dict[str, dict[str, Any]] = {}
    strategy_low_confidence_seeds: list[str] = []
    strategy_high_confidence_learning_seeds: list[str] = []
    strategy_not_learning_eligible_seeds: list[str] = []
    seeds = seed_dirs(input_dir)

    for seed_dir in seeds:
        decisions = load_jsonl(seed_dir / "replay.decision_trace.jsonl")
        decisions_by_id = {
            str(decision.get("decision_id")): decision
            for decision in decisions
            if decision.get("decision_id") is not None
        }
        for decision in decisions:
            decision_type = str(decision.get("decision_type") or "unknown")
            decision_counts[decision_type] += 1
            examples.setdefault(decision_type, {
                "seed": seed_dir.name,
                "decision_id": decision.get("decision_id"),
                "player": decision.get("player"),
                "turn": decision.get("turn"),
                "phase": decision.get("phase"),
                "reason": decision.get("reason"),
                "chosen_option": decision.get("chosen_option"),
                "risk_flags": decision.get("risk_flags"),
            })
        strategy = load_json(seed_dir / "strategy_audit.json")
        strategy_summary = strategy.get("summary") or {}
        confidence = str(strategy_summary.get("learning_confidence") or "unknown")
        strategy_learning_confidence_counts[confidence] += 1
        seed_name = seed_dir.name.replace("seed_", "")
        if confidence == "low_confidence_replay":
            strategy_low_confidence_seeds.append(seed_name)
        elif confidence == "high_confidence_replay":
            strategy_high_confidence_learning_seeds.append(seed_name)
        elif confidence == "not_learning_eligible":
            strategy_not_learning_eligible_seeds.append(seed_name)
        for item in strategy.get("findings", []):
            code = str(item.get("code") or "unknown")
            severity = str(item.get("severity") or "unknown")
            decision_id = item.get("decision_id")
            decision = decisions_by_id.get(str(decision_id)) if decision_id is not None else None
            finding_counts[code] += 1
            severity_by_code[code][severity] += 1
            finding_items.append(finding_sample(seed=seed_name, item=item, decision=decision))

    categories = {}
    for category, metadata in SOURCE_MATRIX.items():
        observed = sum(decision_counts.get(t, 0) for t in metadata["decision_types"])
        codes = set(metadata["finding_codes"])
        detail_filters = set(metadata.get("finding_detail_contains") or [])
        category_items = [
            item
            for item in finding_items
            if item["code"] in codes
            and (
                not detail_filters
                or any(fragment in item["detail"] for fragment in detail_filters)
            )
        ]
        category_findings = len(category_items)
        high_or_medium = 0
        for item in category_items:
            if item["severity"] in {"high", "medium"}:
                high_or_medium += 1
        tracked_gap = bool(metadata.get("tracked_gap"))
        categories[category] = {
            "status": classify_status(
                observed_decisions=observed,
                finding_count=category_findings,
                high_or_medium=high_or_medium,
                tracked_gap=tracked_gap,
            ),
            "observed_decisions": observed,
            "finding_count": category_findings,
            "finding_codes": {
                code: sum(1 for item in category_items if item["code"] == code)
                for code in sorted(codes)
                if any(item["code"] == code for item in category_items)
            },
            "finding_samples": category_items[:20],
            "official_sources": metadata["official_sources"],
            "strategy_sources": metadata["strategy_sources"],
            "expected_trace": metadata["expected_trace"],
            "current_guardrail": metadata["current_guardrail"],
        }

    return {
        "input_dir": str(input_dir),
        "seeds": len(seeds),
        "decision_counts": dict(sorted(decision_counts.items())),
        "finding_counts": dict(sorted(finding_counts.items())),
        "strategy_learning_confidence_counts": dict(sorted(strategy_learning_confidence_counts.items())),
        "strategy_high_confidence_learning_seeds": strategy_high_confidence_learning_seeds,
        "strategy_low_confidence_seeds": strategy_low_confidence_seeds,
        "strategy_not_learning_eligible_seeds": strategy_not_learning_eligible_seeds,
        "categories": categories,
        "examples": examples,
    }


def md(value: Any) -> str:
    return str(value if value is not None else "").replace("|", "\\|").replace("\n", " ")


def render_markdown(result: dict[str, Any]) -> str:
    lines = [
        "# Battle Decision Research Review",
        "",
        "This report aggregates replay decisions against researched Commander strategy principles.",
        "Official sources define legality. Strategy/community sources only calibrate what the replay must justify.",
        "",
        "## Summary",
        "",
        f"- Input: `{result['input_dir']}`",
        f"- Seeds: `{result['seeds']}`",
        f"- Decision counts: `{json.dumps(result['decision_counts'], sort_keys=True)}`",
        f"- Finding counts: `{json.dumps(result['finding_counts'], sort_keys=True)}`",
        f"- Strategy learning confidence counts: `{json.dumps(result.get('strategy_learning_confidence_counts', {}), sort_keys=True)}`",
        f"- Strategy high-confidence learning seeds: `{result.get('strategy_high_confidence_learning_seeds', [])}`",
        f"- Strategy low-confidence seeds: `{result.get('strategy_low_confidence_seeds', [])}`",
        f"- Strategy not-learning-eligible seeds: `{result.get('strategy_not_learning_eligible_seeds', [])}`",
        "",
        "## Category Matrix",
        "",
        "| Category | Status | Decisions | Findings | Expected Trace | Guardrail |",
        "|---|---|---:|---:|---|---|",
    ]
    for category, data in result["categories"].items():
        lines.append(
            f"| {md(category)} | {md(data['status'])} | {data['observed_decisions']} | {data['finding_count']} | {md(data['expected_trace'])} | {md(data['current_guardrail'])} |"
        )
    lines.extend([
        "",
        "## Source Matrix",
        "",
    ])
    for category, data in result["categories"].items():
        lines.append(f"### {category}")
        lines.append("")
        lines.append("Official:")
        for source in data["official_sources"]:
            lines.append(f"- {source}")
        lines.append("")
        lines.append("Strategic/community:")
        for source in data["strategy_sources"]:
            lines.append(f"- {source}")
        lines.append("")
        if data["finding_codes"]:
            lines.append(f"Findings: `{json.dumps(data['finding_codes'], sort_keys=True)}`")
            lines.append("")
            lines.append("| Seed | Decision | Code | Severity | Chosen option | Reason | Risk flags | Detail |")
            lines.append("|---|---|---|---|---|---|---|---|")
            for sample in data.get("finding_samples", [])[:20]:
                lines.append(
                    "| {seed} | {decision_id} | {code} | {severity} | {chosen_option} | {reason} | {risk_flags} | {detail} |".format(
                        seed=md(sample.get("seed")),
                        decision_id=md(sample.get("decision_id")),
                        code=md(sample.get("code")),
                        severity=md(sample.get("severity")),
                        chosen_option=md(json.dumps(sample.get("chosen_option"), sort_keys=True)),
                        reason=md(sample.get("reason")),
                        risk_flags=md(json.dumps(sample.get("risk_flags"), sort_keys=True)),
                        detail=md(sample.get("detail")),
                    )
                )
            lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--json-output", type=Path)
    args = parser.parse_args()

    result = aggregate(args.input_dir)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(render_markdown(result), encoding="utf-8")
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(result, indent=2, sort_keys=True), encoding="utf-8")
    print("BATTLE_DECISION_RESEARCH_REVIEW", json.dumps({
        "seeds": result["seeds"],
        "decision_counts": result["decision_counts"],
        "finding_counts": result["finding_counts"],
        "strategy_learning_confidence_counts": result["strategy_learning_confidence_counts"],
        "strategy_high_confidence_learning_seeds": result["strategy_high_confidence_learning_seeds"],
        "strategy_low_confidence_seeds": result["strategy_low_confidence_seeds"],
        "statuses": {k: v["status"] for k, v in result["categories"].items()},
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
