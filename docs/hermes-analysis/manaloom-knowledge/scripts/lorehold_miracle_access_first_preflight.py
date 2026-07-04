#!/usr/bin/env python3
"""Build the next Lorehold miracle-access-first preflight contract.

This read-only preflight consumes the current miracle trace failure miner and
turns it into concrete entry criteria for any future Lorehold full-shell or
package gate. It does not generate a deck and it does not mutate deck_607.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_TRACE_MINER = REPORT_DIR / "lorehold_miracle_trace_failure_miner_20260704_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_miracle_access_first_preflight_20260704_current"

STRATEGIC_FLOOR_EVENTS = (
    "miracle_cast",
    "topdeck_manipulation_activated",
    "lorehold_spell_cast",
    "lorehold_cost_paid",
    "lorehold_upkeep_rummage",
)
ANCHOR_FLOOR_CARDS = (
    "Land Tax",
    "Library of Leng",
    "Lorehold, the Historian",
    "Scroll Rack",
    "Sensei's Divining Top",
    "The Mind Stone",
    "Urza's Saga",
)
PROTECTED_ANCHORS_NOT_NEGOTIABLE = (
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
    "Victory Chimes",
)
PRESSURE_KEYWORDS = ("pressure", "storm_kiln", "guttersnipe", "token")

EXTERNAL_RESEARCH_REFRESH = [
    {
        "source": "Wizards Commander format",
        "url": "https://magic.wizards.com/en/formats/commander",
        "preflight_use": "Legality, singleton, and color identity are prerequisite gates only.",
    },
    {
        "source": "EDHREC optimized Topdeck Lorehold page",
        "url": "https://edhrec.com/decks/lorehold-the-historian/optimized/topdeck",
        "preflight_use": "Current public Lorehold lists are tagged around Topdeck and Spellslinger, so the next shell must preserve that plan before adding pressure.",
    },
    {
        "source": "EDHREC Miracles Every Turn with Lorehold",
        "url": "https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander",
        "preflight_use": "Lorehold's opponent-upkeep rummage creates first-draw miracle windows; top-library setup is the engine floor.",
    },
    {
        "source": "EDHREC Boros Miracles on a Budget",
        "url": "https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget",
        "preflight_use": "Instant/sorcery density and non-dud first draws matter more than generic value-card insertion.",
    },
]


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


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def slug(value: str) -> str:
    return (
        value.lower()
        .replace("'", "")
        .replace(",", "")
        .replace("//", " ")
        .replace("-", " ")
        .replace(" ", "_")
    )


def source_candidates(trace_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [dict(item) for item in trace_payload.get("candidate_summaries") or [] if isinstance(item, Mapping)]


def derive_strategic_floors(candidates: Iterable[Mapping[str, Any]]) -> dict[str, int]:
    floors = {event: 0 for event in STRATEGIC_FLOOR_EVENTS}
    for candidate in candidates:
        baseline = candidate.get("baseline_strategic_counts") if isinstance(candidate, Mapping) else {}
        if not isinstance(baseline, Mapping):
            continue
        for event in STRATEGIC_FLOOR_EVENTS:
            floors[event] = max(floors[event], as_int(baseline.get(event)))
    return floors


def derive_anchor_access_floors(candidates: Iterable[Mapping[str, Any]]) -> dict[str, int]:
    floors = {card: 0 for card in ANCHOR_FLOOR_CARDS}
    for candidate in candidates:
        focus = candidate.get("focus_access_delta") if isinstance(candidate, Mapping) else {}
        if not isinstance(focus, Mapping):
            continue
        for card in ANCHOR_FLOOR_CARDS:
            payload = focus.get(card)
            if isinstance(payload, Mapping):
                floors[card] = max(floors[card], as_int(payload.get("baseline_accessed_games")))
    return floors


def head_to_head_pass(record: Mapping[str, Any]) -> bool:
    games = as_int(record.get("games"))
    if games == 0:
        return False
    return as_int(record.get("wins")) >= as_int(record.get("losses"))


def pressure_claims(candidate_key: str) -> bool:
    lowered = candidate_key.lower()
    return any(keyword in lowered for keyword in PRESSURE_KEYWORDS)


def assess_candidate(
    candidate: Mapping[str, Any],
    strategic_floors: Mapping[str, int],
    anchor_floors: Mapping[str, int],
) -> dict[str, Any]:
    candidate_key = str(candidate.get("candidate_key") or "")
    counts = candidate.get("strategic_counts") if isinstance(candidate.get("strategic_counts"), Mapping) else {}
    focus = candidate.get("focus_access_delta") if isinstance(candidate.get("focus_access_delta"), Mapping) else {}
    h2h = candidate.get("head_to_head_vs_607") if isinstance(candidate.get("head_to_head_vs_607"), Mapping) else {}
    fast_pressure = (
        candidate.get("fast_pressure_slice") if isinstance(candidate.get("fast_pressure_slice"), Mapping) else {}
    )
    blockers: list[str] = []
    warnings: list[str] = []
    strategic_delta_to_floor: dict[str, int] = {}
    anchor_delta_to_floor: dict[str, int] = {}

    for event, floor in strategic_floors.items():
        value = as_int(counts.get(event))
        strategic_delta_to_floor[event] = value - floor
        if value < floor:
            blockers.append(f"{event}_below_607_floor")

    for card, floor in anchor_floors.items():
        payload = focus.get(card) if isinstance(focus, Mapping) else {}
        candidate_access = as_int(payload.get("candidate_accessed_games")) if isinstance(payload, Mapping) else 0
        anchor_delta_to_floor[card] = candidate_access - floor
        if candidate_access < floor:
            blockers.append(f"{slug(card)}_access_below_607_floor")

    if as_int(candidate.get("topdeck_anchor_access_delta_total")) < 0:
        blockers.append("aggregate_topdeck_anchor_access_regressed")
    if not head_to_head_pass(h2h):
        blockers.append("head_to_head_vs_607_not_won_or_tied")
    if as_int(fast_pressure.get("games")) and as_int(fast_pressure.get("wins")) < as_int(fast_pressure.get("losses")):
        blockers.append("fast_pressure_slice_regressed")
    if pressure_claims(candidate_key) and as_int(candidate.get("pressure_conversion_event_total")) <= 0:
        blockers.append("pressure_conversion_not_proven")
    if pressure_claims(candidate_key) and as_int(candidate.get("pressure_card_event_total")) <= 0:
        blockers.append("pressure_card_use_not_observed")
    if "pressure_causality_unproven" in (candidate.get("failure_flags") or []):
        blockers.append("pressure_causality_unproven")
    if "miracle_trace_missing" in (candidate.get("failure_flags") or []):
        blockers.append("miracle_trace_missing")
    if "topdeck_activation_missing" in (candidate.get("failure_flags") or []):
        blockers.append("topdeck_activation_missing")

    if not pressure_claims(candidate_key):
        warnings.append("candidate_does_not_claim_pressure_repair")

    ready = not blockers
    return {
        "candidate_key": candidate_key,
        "source_gate": candidate.get("source_gate"),
        "candidate_record": candidate.get("candidate_record") or {},
        "head_to_head_vs_607": h2h,
        "fast_pressure_slice": fast_pressure,
        "strategic_delta_to_floor": strategic_delta_to_floor,
        "anchor_access_delta_to_floor": anchor_delta_to_floor,
        "ready_for_next_gate": ready,
        "preflight_status": "gate_ready" if ready else "blocked_before_next_gate",
        "blockers": sorted(set(blockers)),
        "warnings": sorted(set(warnings)),
    }


def build_payload(trace_payload: Mapping[str, Any], trace_path: Path) -> dict[str, Any]:
    candidates = source_candidates(trace_payload)
    strategic_floors = derive_strategic_floors(candidates)
    anchor_floors = derive_anchor_access_floors(candidates)
    assessments = [assess_candidate(candidate, strategic_floors, anchor_floors) for candidate in candidates]
    ready = [item for item in assessments if item["ready_for_next_gate"]]
    blockers = sorted({blocker for item in assessments for blocker in item["blockers"]})
    status = "no_current_candidate_passes_miracle_access_first_preflight"
    if ready:
        status = "candidate_ready_for_miracle_access_first_gate"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_miracle_access_first_preflight",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": [rel(trace_path)] + [str(item) for item in trace_payload.get("source_reports") or []],
        "external_research_refresh": EXTERNAL_RESEARCH_REFRESH,
        "status": status,
        "summary": {
            "candidate_count": len(assessments),
            "gate_ready_now_count": len(ready),
            "keep_607_as_protected_baseline": True,
            "promotion_allowed": False,
            "preflight_contract": "miracle_access_first_shell_v1",
            "strategic_floors_from_607": strategic_floors,
            "anchor_access_floors_from_607": anchor_floors,
            "blocking_reasons": blockers,
        },
        "contract": {
            "required_before_next_natural_gate": [
                "declare the repaired failure mode before building the shell",
                "retain protected anchors or provide same-lane replacement proof before battle",
                "meet or exceed the current 607 miracle/topdeck strategic floors in the same seed window",
                "meet or exceed current 607 natural access to topdeck anchors",
                "show pressure or mana conversion only after the miracle/topdeck floor is preserved",
                "tie or beat fixed deck_607 head-to-head and avoid fast-pressure regression",
            ],
            "protected_anchors_not_negotiable_without_proof": list(PROTECTED_ANCHORS_NOT_NEGOTIABLE),
            "why_this_exists": (
                "Recent shells looked coherent structurally but either lost the fixed-607 head-to-head, "
                "regressed topdeck anchor access, or failed to prove pressure causality. This preflight "
                "prevents another natural gate from repeating the same unproven premise."
            ),
        },
        "candidate_preflight_assessments": assessments,
        "decision": {
            "allow_new_natural_gate_now": bool(ready),
            "keep_607_as_protected_baseline": True,
            "next_action": (
                "build_candidate_against_miracle_access_first_shell_v1"
                if ready
                else "design_new_shell_or_package_that_first_satisfies_miracle_access_floors"
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Miracle Access First Preflight",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- preflight_contract: `{summary['preflight_contract']}`",
        f"- candidate_count: `{summary['candidate_count']}`",
        f"- gate_ready_now_count: `{summary['gate_ready_now_count']}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        f"- keep_607_as_protected_baseline: `{str(summary['keep_607_as_protected_baseline']).lower()}`",
        "",
        "## Floors From Current 607 Evidence",
        "",
        f"- strategic_floors_from_607: `{json.dumps(summary['strategic_floors_from_607'], sort_keys=True)}`",
        f"- anchor_access_floors_from_607: `{json.dumps(summary['anchor_access_floors_from_607'], sort_keys=True)}`",
        "",
        "## Candidate Preflight",
        "",
        "| Candidate | Status | Record | vs 607 | Blockers |",
        "| --- | --- | ---: | ---: | --- |",
    ]
    for item in payload.get("candidate_preflight_assessments") or []:
        record = item["candidate_record"]
        h2h = item["head_to_head_vs_607"]
        lines.append(
            "| {candidate} | `{status}` | `{wins}W/{losses}L/{stalls}S` | `{h_wins}W/{h_losses}L/{h_stalls}S` | `{blockers}` |".format(
                candidate=item["candidate_key"],
                status=item["preflight_status"],
                wins=as_int(record.get("wins")),
                losses=as_int(record.get("losses")),
                stalls=as_int(record.get("stalls")),
                h_wins=as_int(h2h.get("wins")),
                h_losses=as_int(h2h.get("losses")),
                h_stalls=as_int(h2h.get("stalls")),
                blockers=json.dumps(item["blockers"]),
            )
        )

    lines.extend(["", "## Required Before Next Natural Gate", ""])
    for requirement in payload["contract"]["required_before_next_natural_gate"]:
        lines.append(f"- {requirement}")

    lines.extend(["", "## External Research Refresh", ""])
    for item in payload.get("external_research_refresh") or []:
        lines.append(f"- {item['source']}: {item['url']}")
        lines.append(f"  - {item['preflight_use']}")

    lines.extend(["", "## Decision", ""])
    lines.append(f"- allow_new_natural_gate_now: `{str(payload['decision']['allow_new_natural_gate_now']).lower()}`")
    lines.append(f"- next_action: `{payload['decision']['next_action']}`")
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
    parser.add_argument("--trace-miner", type=Path, default=DEFAULT_TRACE_MINER)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_payload(read_json(args.trace_miner), args.trace_miner)
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "gate_ready_now_count": payload["summary"]["gate_ready_now_count"],
                "json": str(json_path),
                "markdown": str(md_path),
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
