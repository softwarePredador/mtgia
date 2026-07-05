#!/usr/bin/env python3
"""Audit Lorehold topdeck forced-access hypotheses without mutating deck 607.

The current Lorehold queue has a small group of topdeck/miracle cards worth
learning from, but none can become a natural deck change until the safe-cut and
miracle-access floors pass. This report is intentionally a diagnostic contract:
it allows focused microbenchmarks while keeping the protected 607 baseline
unchanged.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_HYPOTHESIS_QUEUE = (
    REPORT_DIR / "lorehold_hypothesis_queue_from_value_model_20260705_current_relearn.json"
)
DEFAULT_PREFLIGHT = REPORT_DIR / "lorehold_miracle_access_first_preflight_20260704_current.json"
DEFAULT_TRACE_MINER = REPORT_DIR / "lorehold_miracle_trace_failure_miner_20260704_current.json"
DEFAULT_VALUE_PRIORITY = (
    REPORT_DIR / "lorehold_card_value_priority_synthesis_20260705_current_relearn.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_topdeck_forced_access_audit_20260705_current"

TARGET_CARDS = (
    "Penance",
    "Galvanoth",
    "Dragon's Rage Channeler",
    "Valakut Awakening // Valakut Stoneforge",
    "Wheel of Fortune",
)

PROTECTED_607_ANCHORS = (
    "Bender's Waterskin",
    "Creative Technique",
    "Land Tax",
    "Library of Leng",
    "Lorehold, the Historian",
    "Mizzix's Mastery",
    "Molecule Man",
    "Scroll Rack",
    "Sensei's Divining Top",
    "Storm Herd",
    "The Mind Stone",
    "The Scarlet Witch",
    "Urza's Saga",
    "Victory Chimes",
)

EXTERNAL_EVIDENCE = {
    "Penance": {
        "learning_priority_rank": 1,
        "source": "Card Kingdom Lorehold synergy review",
        "url": "https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/",
        "signal": "direct_hand_to_top_setup",
        "role": "turns cards in hand into known top-library cards for miracle windows",
        "strength": "direct_card_mechanic_support",
        "risk": "card disadvantage unless the top-card setup converts immediately",
    },
    "Galvanoth": {
        "learning_priority_rank": 2,
        "source": "EDHREC Lorehold commander page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "signal": "top_card_free_cast_engine",
        "role": "tests whether extra top-card spell casting improves conversion after setup",
        "strength": "commander_specific_public_usage_signal",
        "risk": "five-mana setup can be too slow if it does not protect miracle cadence",
        "edhrec_lorehold_inclusion_percent": 26.0,
        "edhrec_lorehold_synergy_percent": 26.0,
    },
    "Dragon's Rage Channeler": {
        "learning_priority_rank": 3,
        "source": "EDHREC Lorehold commander page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "signal": "noncreature_spell_surveillance",
        "role": "tests whether cheap surveil selection increases live first-draw setup",
        "strength": "commander_specific_public_usage_signal",
        "risk": "surveil is selection, not guaranteed topdeck placement for miracle",
        "edhrec_lorehold_inclusion_percent": 39.0,
        "edhrec_lorehold_synergy_percent": 37.0,
    },
    "Valakut Awakening // Valakut Stoneforge": {
        "learning_priority_rank": 4,
        "source": "Scryfall Oracle plus EDHREC topdeck shell context",
        "url": "https://scryfall.com/card/znr/174/valakut-awakening-valakut-stoneforge",
        "signal": "modal_hand_refresh",
        "role": "tests whether a modal land/filter card improves bad-hand recovery without land-floor loss",
        "strength": "mechanic_fit_requires_internal_trace",
        "risk": "can become a tap-land or hand churn that does not preserve topdeck anchors",
    },
    "Wheel of Fortune": {
        "learning_priority_rank": 5,
        "source": "Format staple signal plus Lorehold hand-filter lane",
        "url": "https://edhrec.com/top",
        "signal": "mass_redraw_high_variance",
        "role": "tests whether a full hand reset improves spell-chain conversion after topdeck setup",
        "strength": "format_staple_long_tail",
        "risk": "symmetrical refill can help opponents and reset a prepared top card",
    },
}

SOURCE_SNAPSHOT = [
    {
        "source": "EDHREC Lorehold commander page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "use": (
            "Current public Lorehold evidence tags the commander as Topdeck and Spellslinger "
            "and gives card-specific signals for Galvanoth and Dragon's Rage Channeler."
        ),
    },
    {
        "source": "EDHREC optimized Topdeck Lorehold page",
        "url": "https://edhrec.com/decks/lorehold-the-historian/optimized/topdeck",
        "use": "Used as shell context only; optimized public lists do not replace the 607 gate.",
    },
    {
        "source": "EDHREC Miracles Every Turn with Lorehold",
        "url": "https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander",
        "use": (
            "Imported lesson: opponent-upkeep rummage creates first-draw miracle windows, "
            "so top-library setup is a core engine floor."
        ),
    },
    {
        "source": "Card Kingdom Lorehold synergy review",
        "url": "https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/",
        "use": (
            "Imported lesson: Library of Leng, Penance, Sensei's Divining Top, Scroll Rack, "
            "Land Tax, Victory Chimes, and Bender's Waterskin are coherent with the plan."
        ),
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def normalize_name(value: Any) -> str:
    return " ".join(str(value or "").strip().lower().replace("’", "'").split())


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_dict(value: Any) -> dict[str, Any]:
    return dict(value) if isinstance(value, Mapping) else {}


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def hypothesis_rows(payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for raw in as_list(payload.get("hypotheses")):
        if not isinstance(raw, Mapping) or not raw.get("card_name"):
            continue
        rows[normalize_name(raw["card_name"])] = dict(raw)
    return rows


def same_lane_anchor_names(row: Mapping[str, Any]) -> list[str]:
    names: list[str] = []
    for raw in as_list(row.get("same_lane_current_607_anchors")):
        if isinstance(raw, Mapping) and raw.get("card_name"):
            names.append(str(raw["card_name"]))
    return names


def preflight_summary(preflight: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(preflight.get("summary"))


def strategic_floors(preflight: Mapping[str, Any]) -> dict[str, int]:
    floors = as_dict(preflight_summary(preflight).get("strategic_floors_from_607"))
    return {str(key): as_int(value) for key, value in floors.items()}


def anchor_floors(preflight: Mapping[str, Any]) -> dict[str, int]:
    floors = as_dict(preflight_summary(preflight).get("anchor_access_floors_from_607"))
    return {str(key): as_int(value) for key, value in floors.items()}


def diagnostic_ready(row: Mapping[str, Any], *, has_required_floors: bool) -> bool:
    return (
        has_required_floors
        and str(row.get("priority") or "").startswith("P1")
        and "forced_access_diagnostic" in str(row.get("allowed_next_test") or "")
        and str(row.get("readiness_status") or "") != "blocked_prior_reject"
    )


def natural_gate_ready(row: Mapping[str, Any]) -> bool:
    return str(row.get("readiness_status") or "") == "natural_gate_ready"


def candidate_blockers(
    row: Mapping[str, Any],
    *,
    has_required_floors: bool,
    preflight_gate_ready_count: int,
) -> list[str]:
    blockers: list[str] = []
    readiness = str(row.get("readiness_status") or "")
    if not row:
        return ["missing_hypothesis_row"]
    if not has_required_floors:
        blockers.append("missing_607_miracle_access_floors")
    if readiness != "natural_gate_ready":
        blockers.append("needs_named_same_lane_safe_cut_model")
        blockers.append("no_natural_gate_ready_row")
    if preflight_gate_ready_count <= 0:
        blockers.append("miracle_access_first_preflight_closed")
    if not same_lane_anchor_names(row):
        blockers.append("same_lane_607_anchor_context_missing")
    blockers.append("deck_607_protected_no_mutation")
    return sorted(set(blockers))


def build_candidate_row(
    card_name: str,
    hypothesis: Mapping[str, Any],
    *,
    has_required_floors: bool,
    preflight_gate_ready_count: int,
    strategic_floor_values: Mapping[str, int],
    anchor_floor_values: Mapping[str, int],
) -> dict[str, Any]:
    evidence = dict(EXTERNAL_EVIDENCE[card_name])
    anchors = same_lane_anchor_names(hypothesis)
    is_diagnostic_ready = diagnostic_ready(hypothesis, has_required_floors=has_required_floors)
    is_natural_gate_ready = natural_gate_ready(hypothesis)
    return {
        "card_name": card_name,
        "learning_priority_rank": as_int(evidence.get("learning_priority_rank")),
        "external_evidence": evidence,
        "hypothesis": {
            "present": bool(hypothesis),
            "priority": hypothesis.get("priority") or "",
            "readiness_status": hypothesis.get("readiness_status") or "",
            "allowed_next_test": hypothesis.get("allowed_next_test") or "",
            "lanes": as_list(hypothesis.get("hypothesis_lanes")),
            "variant_deck_count": as_int(hypothesis.get("variant_deck_count")),
            "variant_deck_ids": as_list(hypothesis.get("variant_deck_ids")),
            "runtime_ready": bool(hypothesis.get("runtime_ready")),
            "staple_tier": hypothesis.get("staple_tier") or "",
            "best_edhrec_rank": hypothesis.get("best_edhrec_rank"),
            "same_lane_current_607_anchors": anchors,
            "same_lane_cut_contract": hypothesis.get("same_lane_cut_contract") or "",
            "reason": hypothesis.get("reason") or "",
        },
        "diagnostic_allowed_now": is_diagnostic_ready,
        "natural_gate_allowed_now": False,
        "deck_action_allowed_now": False,
        "safe_cut_ready": is_natural_gate_ready,
        "blockers_before_deck_action": candidate_blockers(
            hypothesis,
            has_required_floors=has_required_floors,
            preflight_gate_ready_count=preflight_gate_ready_count,
        ),
        "required_trace_floors": {
            "strategic_floors_from_607": dict(strategic_floor_values),
            "anchor_access_floors_from_607": dict(anchor_floor_values),
        },
        "microbenchmark_contract": {
            "access_mode": "forced_access_diagnostic_only",
            "may_mutate_deck_607": False,
            "may_promote_deck": False,
            "must_log": [
                "candidate_card_drawn_or_accessed",
                "candidate_card_cast_or_activated",
                "miracle_cast",
                "topdeck_manipulation_activated",
                "lorehold_upkeep_rummage",
                "lorehold_cost_paid",
                "head_to_head_vs_607_same_seed",
                "fast_pressure_slice",
            ],
            "must_preserve_before_natural_gate": list(PROTECTED_607_ANCHORS),
        },
        "decision": (
            "forced_access_diagnostic_ready_only"
            if is_diagnostic_ready
            else "blocked_until_inputs_and_safe_cut_model_exist"
        ),
    }


def status_for(*, missing_inputs: Sequence[str], diagnostic_ready_count: int, candidate_count: int, natural_count: int) -> str:
    if missing_inputs:
        return "topdeck_forced_access_inputs_missing_keep_607"
    if candidate_count and diagnostic_ready_count == candidate_count and natural_count == 0:
        return "topdeck_forced_access_diagnostic_ready_no_natural_gate_keep_607"
    return "topdeck_forced_access_partial_keep_607"


def build_report(
    *,
    hypothesis_queue: Mapping[str, Any],
    preflight: Mapping[str, Any],
    trace_miner: Mapping[str, Any],
    value_priority: Mapping[str, Any],
    target_cards: Sequence[str] = TARGET_CARDS,
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    hypotheses = hypothesis_rows(hypothesis_queue)
    strategic_floor_values = strategic_floors(preflight)
    anchor_floor_values = anchor_floors(preflight)
    preflight_row = preflight_summary(preflight)
    preflight_gate_ready_count = as_int(preflight_row.get("gate_ready_now_count"))

    missing_inputs: list[str] = []
    if not strategic_floor_values:
        missing_inputs.append("preflight:strategic_floors_from_607")
    if not anchor_floor_values:
        missing_inputs.append("preflight:anchor_access_floors_from_607")

    rows: list[dict[str, Any]] = []
    has_required_floors = not missing_inputs
    for card_name in target_cards:
        key = normalize_name(card_name)
        row = hypotheses.get(key, {})
        if not row:
            missing_inputs.append(f"hypothesis:{card_name}")
        rows.append(
            build_candidate_row(
                card_name,
                row,
                has_required_floors=has_required_floors,
                preflight_gate_ready_count=preflight_gate_ready_count,
                strategic_floor_values=strategic_floor_values,
                anchor_floor_values=anchor_floor_values,
            )
        )

    rows.sort(key=lambda row: (as_int(row["learning_priority_rank"]), row["card_name"]))
    diagnostic_ready_count = sum(1 for row in rows if row["diagnostic_allowed_now"])
    natural_count = sum(1 for row in rows if row["safe_cut_ready"])
    safe_cut_ready_count = natural_count
    blocker_counts = Counter(
        blocker for row in rows for blocker in row["blockers_before_deck_action"]
    )

    summary = {
        "target_card_count": len(target_cards),
        "candidate_count": len(rows),
        "diagnostic_ready_count": diagnostic_ready_count,
        "safe_cut_ready_count": safe_cut_ready_count,
        "natural_gate_ready_count": natural_count,
        "preflight_gate_ready_now_count": preflight_gate_ready_count,
        "protected_anchor_count": len(PROTECTED_607_ANCHORS),
        "strategic_floor_count": len(strategic_floor_values),
        "anchor_access_floor_count": len(anchor_floor_values),
        "missing_inputs": sorted(set(missing_inputs)),
        "blocker_counts": dict(sorted(blocker_counts.items())),
        "hypothesis_queue_status": hypothesis_queue.get("status") or "",
        "preflight_status": preflight.get("status") or "",
        "trace_status": trace_miner.get("status") or "",
        "value_priority_status": value_priority.get("status") or "",
        "keep_607_as_protected_baseline": True,
        "deck_607_mutated": False,
        "postgres_writes": False,
        "source_db_mutated": False,
        "promotion_allowed": False,
        "deck_action_allowed_now": False,
        "natural_gate_allowed_now": False,
        "recommended_first_diagnostic": rows[0]["card_name"] if rows else "",
    }

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_topdeck_forced_access_audit",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status_for(
            missing_inputs=missing_inputs,
            diagnostic_ready_count=diagnostic_ready_count,
            candidate_count=len(rows),
            natural_count=natural_count,
        ),
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "source_snapshot": SOURCE_SNAPSHOT,
        "summary": summary,
        "protected_607_anchors": list(PROTECTED_607_ANCHORS),
        "required_before_any_natural_gate": [
            "name the exact current 607 cut slot and functional lane",
            "preserve or beat current 607 strategic floors for miracle/topdeck execution",
            "preserve or beat current 607 natural access to topdeck anchors",
            "show candidate card drawn/cast/activated in focused traces",
            "tie or beat 607 in the same opponent and seed window",
            "avoid fast-pressure regression before any deck mutation",
        ],
        "candidates": rows,
        "decision": {
            "current_best_baseline": "deck_607",
            "highest_learning_priority": rows[0]["card_name"] if rows else "",
            "allow_forced_access_microbenchmarks": bool(rows) and diagnostic_ready_count > 0 and not missing_inputs,
            "allow_natural_gate_now": False,
            "allow_deck_mutation_now": False,
            "promotion_allowed": False,
            "reason": (
                "The topdeck cards are good learning targets because they directly test Lorehold's "
                "miracle-access problem. They still have zero safe-cut/natural-gate proof, so the "
                "only permitted next step is forced-access diagnostics that cannot promote or mutate 607."
            ),
            "next_action": "build_forced_access_microbenchmarks_for_topdeck_candidates_without_deck_mutation",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = as_dict(payload.get("summary"))
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Topdeck Forced Access Audit",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- current_baseline: `{payload['current_baseline']}`",
        f"- target_card_count: `{summary['target_card_count']}`",
        f"- diagnostic_ready_count: `{summary['diagnostic_ready_count']}`",
        f"- natural_gate_ready_count: `{summary['natural_gate_ready_count']}`",
        f"- safe_cut_ready_count: `{summary['safe_cut_ready_count']}`",
        f"- preflight_gate_ready_now_count: `{summary['preflight_gate_ready_now_count']}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        f"- deck_action_allowed_now: `{str(summary['deck_action_allowed_now']).lower()}`",
        f"- recommended_first_diagnostic: `{summary['recommended_first_diagnostic']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")

    lines.extend(["", "## Source Snapshot", ""])
    for item in as_list(payload.get("source_snapshot")):
        if not isinstance(item, Mapping):
            continue
        lines.append(f"- {item.get('source')}: {item.get('url')}")
        lines.append(f"  - {item.get('use')}")

    lines.extend(["", "## Candidates", ""])
    lines.append(
        "| Rank | Card | Signal | Hypothesis status | Diagnostic | Natural gate | Blockers |"
    )
    lines.append("| ---: | --- | --- | --- | ---: | ---: | --- |")
    for row in as_list(payload.get("candidates")):
        evidence = as_dict(row.get("external_evidence"))
        hypothesis = as_dict(row.get("hypothesis"))
        blockers = ", ".join(as_list(row.get("blockers_before_deck_action")))
        lines.append(
            "| {rank} | `{card}` | `{signal}` | `{status}` | `{diag}` | `{natural}` | `{blockers}` |".format(
                rank=row.get("learning_priority_rank"),
                card=row.get("card_name"),
                signal=evidence.get("signal") or "",
                status=hypothesis.get("readiness_status") or "",
                diag=str(bool(row.get("diagnostic_allowed_now"))).lower(),
                natural=str(bool(row.get("natural_gate_allowed_now"))).lower(),
                blockers=blockers,
            )
        )

    lines.extend(["", "## Required Trace Floors", ""])
    lines.append(
        f"- strategic_floors_from_607: `{json.dumps(as_dict(summary).get('strategic_floor_count'), sort_keys=True)}` floors tracked"
    )
    for row in as_list(payload.get("candidates"))[:1]:
        floors = as_dict(row.get("required_trace_floors"))
        lines.append(
            f"- strategic details: `{json.dumps(as_dict(floors.get('strategic_floors_from_607')), sort_keys=True)}`"
        )
        lines.append(
            f"- anchor details: `{json.dumps(as_dict(floors.get('anchor_access_floors_from_607')), sort_keys=True)}`"
        )

    lines.extend(["", "## Required Before Any Natural Gate", ""])
    for requirement in as_list(payload.get("required_before_any_natural_gate")):
        lines.append(f"- {requirement}")

    lines.extend(["", "## Protected 607 Anchors", ""])
    lines.append(", ".join(f"`{name}`" for name in as_list(payload.get("protected_607_anchors"))))

    lines.extend(["", "## Decision", ""])
    lines.append(f"- current_best_baseline: `{decision['current_best_baseline']}`")
    lines.append(f"- highest_learning_priority: `{decision['highest_learning_priority']}`")
    lines.append(
        f"- allow_forced_access_microbenchmarks: `{str(decision['allow_forced_access_microbenchmarks']).lower()}`"
    )
    lines.append(f"- allow_natural_gate_now: `{str(decision['allow_natural_gate_now']).lower()}`")
    lines.append(f"- allow_deck_mutation_now: `{str(decision['allow_deck_mutation_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    lines.append(f"- next_action: `{decision['next_action']}`")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hypothesis-queue", type=Path, default=DEFAULT_HYPOTHESIS_QUEUE)
    parser.add_argument("--preflight", type=Path, default=DEFAULT_PREFLIGHT)
    parser.add_argument("--trace-miner", type=Path, default=DEFAULT_TRACE_MINER)
    parser.add_argument("--value-priority", type=Path, default=DEFAULT_VALUE_PRIORITY)
    parser.add_argument("--cards", default=",".join(TARGET_CARDS))
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    cards = [card.strip() for card in str(args.cards).split(",") if card.strip()]
    paths = {
        "hypothesis_queue": args.hypothesis_queue,
        "preflight": args.preflight,
        "trace_miner": args.trace_miner,
        "value_priority": args.value_priority,
    }
    payload = build_report(
        hypothesis_queue=read_json(args.hypothesis_queue),
        preflight=read_json(args.preflight),
        trace_miner=read_json(args.trace_miner),
        value_priority=read_json(args.value_priority),
        target_cards=cards,
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
