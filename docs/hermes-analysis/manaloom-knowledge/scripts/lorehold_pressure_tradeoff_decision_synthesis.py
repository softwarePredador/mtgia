#!/usr/bin/env python3
"""Synthesize the Lorehold 607 pressure-payoff tradeoff decision.

This read-only report consumes the pressure package resolver, diagnostic
candidate, strategy matrix, natural smoke gate, and focused forced-access
probes. Its job is to keep the learning usable without letting a structural
score or a forced-access probe become deck-promotion evidence.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_RESOLVER = REPORT_DIR / "lorehold_pressure_safe_cut_pool_resolver_20260704_current.json"
DEFAULT_CANDIDATE = REPORT_DIR / "lorehold_pressure_tradeoff_diagnostic_variant_20260704_current.json"
DEFAULT_MATRIX = REPORT_DIR / "lorehold_pressure_tradeoff_diagnostic_variant_matrix_20260704_current.json"
DEFAULT_SMOKE_GATE = REPORT_DIR / "lorehold_pressure_tradeoff_diagnostic_variant_battle_20260704_smoke.json"
DEFAULT_FORCED_MONASTERY = REPORT_DIR / "lorehold_pressure_tradeoff_diagnostic_variant_forced_monastery_20260704.json"
DEFAULT_FORCED_STORM_KILN = REPORT_DIR / "lorehold_pressure_tradeoff_diagnostic_variant_forced_storm_kiln_20260704.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_pressure_tradeoff_decision_synthesis_20260704_current"

PRESSURE_CARDS = (
    "Monastery Mentor",
    "Young Pyromancer",
    "Guttersnipe",
    "Storm-Kiln Artist",
)

STRATEGIC_KEYS = (
    "miracle_cast",
    "topdeck_manipulation_activated",
    "discard_to_top_replacement",
    "lorehold_spell_cast",
    "lorehold_upkeep_rummage",
    "static_cost_reduction_total",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def as_float(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except Exception:
        return default


def nested_objects(value: Any):
    if isinstance(value, Mapping):
        yield value
        for child in value.values():
            yield from nested_objects(child)
    elif isinstance(value, list):
        for child in value:
            yield from nested_objects(child)


def result_by_key(payload: Mapping[str, Any], deck_key: str) -> dict[str, Any]:
    for row in payload.get("results") or []:
        if isinstance(row, Mapping) and row.get("deck_key") == deck_key:
            return dict(row)
    return {}


def matrix_deck(payload: Mapping[str, Any], deck_key: str) -> dict[str, Any]:
    for row in payload.get("decks") or []:
        if isinstance(row, Mapping) and row.get("deck_key") == deck_key:
            return dict(row)
    return {}


def telemetry(row: Mapping[str, Any]) -> Mapping[str, Any]:
    value = row.get("telemetry")
    return value if isinstance(value, Mapping) else {}


def strategic_counts(row: Mapping[str, Any]) -> dict[str, int]:
    raw = telemetry(row).get("strategic_event_counts")
    if not isinstance(raw, Mapping):
        return {}
    return {str(key): as_int(value) for key, value in raw.items()}


def card_event_counts(row: Mapping[str, Any], card_name: str) -> dict[str, int]:
    raw = telemetry(row).get("card_event_counts")
    if not isinstance(raw, Mapping):
        return {}
    return {
        str(key): as_int(value)
        for key, value in raw.items()
        if card_name.lower() in str(key).lower()
    }


def focus_card(row: Mapping[str, Any], card_name: str) -> dict[str, Any]:
    raw = telemetry(row).get("focus_card_access_summary")
    if not isinstance(raw, Mapping):
        return {}
    value = raw.get(card_name)
    return dict(value) if isinstance(value, Mapping) else {}


def effect_count(payload: Mapping[str, Any], card_name: str, effect: str | None = None) -> int:
    count = 0
    for obj in nested_objects(payload):
        if str(obj.get("card") or "") != card_name:
            continue
        if effect and str(obj.get("effect") or "") != effect:
            continue
        count += 1
    return count


def treasure_like_count(payload: Mapping[str, Any], card_name: str) -> int:
    count = 0
    for obj in nested_objects(payload):
        if str(obj.get("card") or "") != card_name:
            continue
        text = " ".join(str(obj.get(key) or "") for key in ("event", "effect", "action"))
        if "treasure" in text.lower() or "magecraft" in text.lower():
            count += 1
    return count


def natural_card_rows(candidate_result: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for card_name in PRESSURE_CARDS:
        focus = focus_card(candidate_result, card_name)
        events = card_event_counts(candidate_result, card_name)
        trigger_count = sum(value for key, value in events.items() if key.startswith("trigger_resolved:"))
        cast_count = sum(value for key, value in events.items() if key.startswith("spell_cast:"))
        cost_count = sum(value for key, value in events.items() if key.startswith("cost_paid:"))
        accessed_games = as_int(focus.get("accessed_games"))
        near_access_games = as_int(focus.get("near_access_games"))
        if trigger_count:
            decision = "hypothesis_natural_trigger_signal_but_full_package_regressed_miracle"
        elif cast_count or cost_count:
            decision = "hypothesis_natural_cast_or_cost_signal_but_full_package_regressed_miracle"
        elif accessed_games or near_access_games:
            decision = "hypothesis_natural_access_only_needs_smaller_package_or_safe_cut"
        else:
            decision = "blocked_no_natural_card_use_in_pressure_smoke"
        rows.append(
            {
                "card_name": card_name,
                "lane": "pressure_payoff",
                "decision": decision,
                "natural_accessed_games": accessed_games,
                "natural_near_access_games": near_access_games,
                "natural_event_counts": events,
                "natural_trigger_count": trigger_count,
                "natural_cast_count": cast_count,
                "natural_cost_count": cost_count,
            }
        )
    return rows


def forced_probe_row(payload: Mapping[str, Any], card_name: str, *, effect: str | None = None) -> dict[str, Any]:
    row = result_by_key(payload, "deck_607")
    events = card_event_counts(row, card_name)
    return {
        "card_name": card_name,
        "forced_access_mode": payload.get("forced_access_mode") or row.get("forced_access_mode"),
        "record": {
            "wins": as_int(row.get("wins")),
            "losses": as_int(row.get("losses")),
            "stalls": as_int(row.get("stalls")),
            "win_rate": as_float(row.get("win_rate")),
        },
        "focus": focus_card(row, card_name),
        "card_event_counts": events,
        "effect_count": effect_count(payload, card_name, effect),
        "treasure_like_count": treasure_like_count(payload, card_name),
    }


def battle_record(row: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "wins": as_int(row.get("wins")),
        "losses": as_int(row.get("losses")),
        "stalls": as_int(row.get("stalls")),
        "win_rate": as_float(row.get("win_rate")),
        "avg_win_turn": as_float(row.get("avg_win_turn")),
    }


def strategic_delta(baseline: Mapping[str, Any], candidate: Mapping[str, Any]) -> dict[str, dict[str, int]]:
    base_counts = strategic_counts(baseline)
    candidate_counts = strategic_counts(candidate)
    return {
        key: {
            "baseline": as_int(base_counts.get(key)),
            "candidate": as_int(candidate_counts.get(key)),
            "delta": as_int(candidate_counts.get(key)) - as_int(base_counts.get(key)),
        }
        for key in STRATEGIC_KEYS
    }


def build_synthesis(
    *,
    resolver: Mapping[str, Any],
    candidate: Mapping[str, Any],
    matrix: Mapping[str, Any],
    smoke_gate: Mapping[str, Any],
    forced_monastery: Mapping[str, Any],
    forced_storm_kiln: Mapping[str, Any],
    source_paths: Mapping[str, Path],
) -> dict[str, Any]:
    candidate_key = str(candidate.get("candidate_key") or "candidate_607_pressure_payoff_diagnostic_tradeoff_v1")
    baseline_matrix = matrix_deck(matrix, "deck_607")
    candidate_matrix = matrix_deck(matrix, candidate_key)
    baseline_result = result_by_key(smoke_gate, "deck_607")
    candidate_result = result_by_key(smoke_gate, candidate_key)
    deltas = strategic_delta(baseline_result, candidate_result)
    candidate_score = as_float(candidate_matrix.get("strategy_score"))
    baseline_score = as_float(baseline_matrix.get("strategy_score"))
    resolver_summary = resolver.get("summary") if isinstance(resolver.get("summary"), Mapping) else {}
    gate_ready = bool(resolver_summary.get("gate_ready_plan_complete"))
    diagnostic_only = bool(candidate.get("diagnostic_only")) or not bool(candidate.get("promotion_eligible"))
    miracle_regressed = deltas["miracle_cast"]["delta"] < 0
    topdeck_regressed = deltas["topdeck_manipulation_activated"]["delta"] < 0
    wins_tied_or_better = as_int(candidate_result.get("wins")) >= as_int(baseline_result.get("wins"))
    promotion_allowed = False
    status = "pressure_tradeoff_diagnostic_only_keep_607"
    if gate_ready and not diagnostic_only and wins_tied_or_better and not miracle_regressed and not topdeck_regressed:
        status = "pressure_tradeoff_requires_confirmed_equal_gate_review"

    natural_rows = natural_card_rows(candidate_result)
    forced = {
        "Monastery Mentor": forced_probe_row(forced_monastery, "Monastery Mentor", effect="token_maker"),
        "Storm-Kiln Artist": forced_probe_row(forced_storm_kiln, "Storm-Kiln Artist"),
    }
    decision_reasons = []
    if not gate_ready:
        decision_reasons.append("No seed-safe cut plan exists for the full four-card package.")
    if diagnostic_only:
        decision_reasons.append("The generated candidate is diagnostic-only and explicitly promotion-ineligible.")
    if candidate_score > baseline_score:
        decision_reasons.append("The structure matrix ranks the candidate higher, but structure-only improvement is not promotion proof.")
    if wins_tied_or_better:
        decision_reasons.append("The smoke gate tied baseline wins, but smoke scope is not a confirmed equal-seed promotion gate.")
    if miracle_regressed or topdeck_regressed:
        decision_reasons.append("The candidate regressed Lorehold's miracle/topdeck execution, which is the protected 607 plan.")

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_pressure_tradeoff_decision_synthesis",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "status": status,
        "source_reports": {key: rel(path) for key, path in source_paths.items()},
        "candidate_key": candidate_key,
        "added": list(candidate.get("added") or resolver.get("primary_adds") or []),
        "removed": list(candidate.get("removed") or []),
        "resolver_summary": dict(resolver_summary),
        "structure": {
            "ranked_deck_keys": list(matrix.get("ranked_deck_keys") or []),
            "baseline_score": baseline_score,
            "candidate_score": candidate_score,
            "score_delta": round(candidate_score - baseline_score, 3),
            "candidate_intent": as_float((candidate.get("commander_intent_alignment") or {}).get("score")),
        },
        "natural_smoke_gate": {
            "baseline_record": battle_record(baseline_result),
            "candidate_record": battle_record(candidate_result),
            "wins_tied_or_better": wins_tied_or_better,
            "strategic_deltas": deltas,
            "miracle_regressed": miracle_regressed,
            "topdeck_regressed": topdeck_regressed,
        },
        "candidate_cards": natural_rows,
        "forced_probe_evidence": forced,
        "summary": {
            "gate_ready_cut_count": as_int(resolver_summary.get("gate_ready_cut_count")),
            "gate_ready_plan_complete": gate_ready,
            "diagnostic_only": diagnostic_only,
            "promotion_allowed": promotion_allowed,
            "natural_cards_with_trigger_signal": sum(1 for row in natural_rows if row["natural_trigger_count"] > 0),
            "natural_cards_with_cost_or_cast_signal": sum(
                1 for row in natural_rows if row["natural_cost_count"] > 0 or row["natural_cast_count"] > 0
            ),
            "forced_monastery_token_maker_count": as_int(forced["Monastery Mentor"].get("effect_count")),
            "forced_storm_kiln_treasure_like_count": as_int(forced["Storm-Kiln Artist"].get("treasure_like_count")),
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "promotion_allowed": promotion_allowed,
            "decision_reasons": decision_reasons,
            "next_actions": [
                "do_not_promote_or_apply_the_four_card_pressure_tradeoff",
                "do_not_rerun_the_full_package_until_a_seed_safe_cut_model_changes",
                "use the natural Guttersnipe/Young Pyromancer signal only as a smaller-package hypothesis",
                "treat Monastery Mentor and Storm-Kiln Artist forced probes as card-understanding evidence, not natural promotion proof",
                "preserve 607 miracle/topdeck cadence as a hard gate for future pressure packages",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    natural = payload["natural_smoke_gate"]
    lines = [
        "# Lorehold Pressure Tradeoff Decision Synthesis",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        "",
        "## Structure",
        "",
        f"- ranked deck keys: `{json.dumps(payload['structure']['ranked_deck_keys'])}`",
        f"- baseline score: `{payload['structure']['baseline_score']}`",
        f"- candidate score: `{payload['structure']['candidate_score']}`",
        f"- score delta: `{payload['structure']['score_delta']}`",
        "",
        "## Natural Smoke Gate",
        "",
        f"- baseline record: `{json.dumps(natural['baseline_record'], sort_keys=True)}`",
        f"- candidate record: `{json.dumps(natural['candidate_record'], sort_keys=True)}`",
        f"- miracle regressed: `{str(natural['miracle_regressed']).lower()}`",
        f"- topdeck regressed: `{str(natural['topdeck_regressed']).lower()}`",
        "",
        "| Metric | Baseline | Candidate | Delta |",
        "| --- | ---: | ---: | ---: |",
    ]
    for key, row in natural["strategic_deltas"].items():
        lines.append(f"| `{key}` | {row['baseline']} | {row['candidate']} | {row['delta']} |")
    lines.extend(["", "## Card Evidence", "", "| Card | Decision | Natural events | Accessed games |", "| --- | --- | ---: | ---: |"])
    for row in payload["candidate_cards"]:
        event_total = sum(as_int(value) for value in row.get("natural_event_counts", {}).values())
        lines.append(
            f"| {row['card_name']} | `{row['decision']}` | {event_total} | {row['natural_accessed_games']} |"
        )
    lines.extend(["", "## Forced Probes", ""])
    for card_name, row in payload["forced_probe_evidence"].items():
        lines.append(
            f"- `{card_name}`: focus `{json.dumps(row.get('focus') or {}, sort_keys=True)}`, "
            f"events `{json.dumps(row.get('card_event_counts') or {}, sort_keys=True)}`, "
            f"effect_count `{row.get('effect_count')}`, treasure_like_count `{row.get('treasure_like_count')}`."
        )
    lines.extend(["", "## Decision", ""])
    for reason in payload["decision"]["decision_reasons"]:
        lines.append(f"- {reason}")
    lines.append("- next_actions:")
    for action in payload["decision"]["next_actions"]:
        lines.append(f"  - {action}")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--resolver", type=Path, default=DEFAULT_RESOLVER)
    parser.add_argument("--candidate", type=Path, default=DEFAULT_CANDIDATE)
    parser.add_argument("--matrix", type=Path, default=DEFAULT_MATRIX)
    parser.add_argument("--smoke-gate", type=Path, default=DEFAULT_SMOKE_GATE)
    parser.add_argument("--forced-monastery", type=Path, default=DEFAULT_FORCED_MONASTERY)
    parser.add_argument("--forced-storm-kiln", type=Path, default=DEFAULT_FORCED_STORM_KILN)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    source_paths = {
        "resolver": args.resolver,
        "candidate": args.candidate,
        "matrix": args.matrix,
        "smoke_gate": args.smoke_gate,
        "forced_monastery": args.forced_monastery,
        "forced_storm_kiln": args.forced_storm_kiln,
    }
    payload = build_synthesis(
        resolver=read_json(args.resolver),
        candidate=read_json(args.candidate),
        matrix=read_json(args.matrix),
        smoke_gate=read_json(args.smoke_gate),
        forced_monastery=read_json(args.forced_monastery),
        forced_storm_kiln=read_json(args.forced_storm_kiln),
        source_paths=source_paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
