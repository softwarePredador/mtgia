#!/usr/bin/env python3
"""Write the Lorehold topdeck-access-first sidecar shell contract.

This read-only artifact converts the current post-safe-cut route, sidecar
queue, non-anchor cut model, miracle contract, value model, and trace collector
into a concrete learning contract. It does not materialize a deck, mutate deck
607, write PostgreSQL/SQLite, run forced access, or open a natural battle gate.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_POST_SAFE_CUT_ROUTE = (
    REPORT_DIR / "lorehold_topdeck_post_safe_cut_route_20260705_current.json"
)
DEFAULT_SIDECAR_QUEUE = (
    REPORT_DIR / "lorehold_topdeck_sidecar_candidate_queue_20260705_current.json"
)
DEFAULT_NONANCHOR_CUT_MODEL = (
    REPORT_DIR / "lorehold_topdeck_nonanchor_cut_model_miner_20260705_current.json"
)
DEFAULT_MIRACLE_SHELL_CONTRACT = (
    REPORT_DIR / "lorehold_miracle_access_first_shell_contract_20260705_current_relearn.json"
)
DEFAULT_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
DEFAULT_TRACE_EVIDENCE = (
    REPORT_DIR / "lorehold_topdeck_floor_trace_evidence_collector_20260705_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_topdeck_access_first_sidecar_shell_contract_20260705_current"
)

TARGET_ROUTE = "topdeck_access_first_sidecar_shell"
TARGET_CONTRACT = "topdeck_access_first_sidecar_shell_contract"

EXTERNAL_RESEARCH_REFRESH = [
    {
        "source": "Wizards Commander format",
        "url": "https://magic.wizards.com/en/formats/commander",
        "contract_use": (
            "Use official Commander deck shape, singleton, and color identity as "
            "legality gates only; they do not prove a deckbuilding upgrade."
        ),
    },
    {
        "source": "Scryfall Lorehold, the Historian",
        "url": "https://scryfall.com/card/sos/201/lorehold-the-historian",
        "contract_use": (
            "Lorehold's miracle grant and opponent-upkeep rummage make top-library "
            "control and opponent-turn mana first-class deckbuilding lanes."
        ),
    },
    {
        "source": "EDHREC Lorehold optimized topdeck average deck",
        "url": "https://edhrec.com/average-decks/lorehold-the-historian/topdeck",
        "contract_use": (
            "Public topdeck lists are discovery evidence for cards such as "
            "Dragon's Rage Channeler; local cut, trace, and battle gates still win."
        ),
    },
    {
        "source": "EDHREC Miracles Every Turn with Lorehold",
        "url": (
            "https://edhrec.com/articles/"
            "miracles-every-turn-with-lorehold-the-historian-in-commander"
        ),
        "contract_use": (
            "Use the article only to reinforce the miracle/topdeck floor; it is not "
            "a ManaLoom promotion result."
        ),
    },
    {
        "source": "Card Kingdom Lorehold synergy article",
        "url": (
            "https://blog.cardkingdom.com/"
            "10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/"
        ),
        "contract_use": (
            "Use synergy suggestions as hypotheses. They still need named cuts and "
            "607-preserving trace proof before execution."
        ),
    },
]

PROTECTED_TOPDECK_ANCHORS = [
    "Lorehold, the Historian",
    "Sensei's Divining Top",
    "Scroll Rack",
    "Library of Leng",
    "Land Tax",
    "Bender's Waterskin",
    "Victory Chimes",
    "Approach of the Second Sun",
    "Mizzix's Mastery",
    "Molecule Man",
    "The Mind Stone",
    "The Scarlet Witch",
]

SIDECAR_VALUE_LANES = [
    "topdeck_miracle_setup",
    "hand_to_library_control",
    "opponent_turn_mana",
    "spell_volume_conversion",
    "same_lane_nonanchor_cut",
    "nonanchor_cut_model_proof",
    "fast_pressure_survival",
]

CONTRACT_REQUIREMENTS = [
    "copy_or_lab_candidate_only; never mutate deck_607",
    "do_not_materialize_a_100_card_list_until_a_named_add_cut_pair_exists",
    "preserve Commander 99-plus-1, singleton, and color identity gates",
    "preserve the current 607 land and ramp floor unless a mana model beats it",
    "preserve topdeck, miracle, upkeep-rummage, spell-volume, and cost-reduction floors",
    "preserve Sensei's Divining Top, Scroll Rack, Library of Leng, and Land Tax access",
    "preserve Bender's Waterskin and Victory Chimes unless same-lane proof beats 607",
    "declare each add, cut, protected anchor, lane, floor risk, and expected metric lift",
    "require direct drawn/cast/activated trace for added cards before natural battle",
    "block forced access unless it has a temporary safe cut manifest",
    "never treat forced-access success as promotion evidence",
    "run equal battle gates only after structure matrix and trace floors pass",
    "include a Winota or fast-pressure slice before any promotion claim",
]

BLOCKED_STAPLE_POLICY = [
    {
        "card": "Mana Vault",
        "lane": "early_mana_and_spell_chain_conversion",
        "current_policy": "learning_only_not_607_change",
        "reason": (
            "Fast mana is valuable, but current evidence has no same-lane cut that "
            "preserves the 607 opponent-turn mana and miracle cadence floors."
        ),
    },
    {
        "card": "The One Ring",
        "lane": "draw_and_resource_density",
        "current_policy": "learning_only_not_607_change",
        "reason": (
            "Generic draw is valuable, but prior 607 retests did not beat the "
            "protected shell and no current cut model repairs the floor risk."
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


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def input_health(payloads: Mapping[str, Mapping[str, Any]]) -> dict[str, Any]:
    missing = [key for key, payload in payloads.items() if not payload]
    return {
        "missing_inputs": missing,
        "all_required_inputs_present": not missing,
    }


def topdeck_rows(queue_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [
        dict(row)
        for row in as_list(queue_payload.get("candidate_queue"))
        if isinstance(row, Mapping) and row.get("sidecar_tag") == "topdeck_access_sidecar_primary"
    ]
    rows.sort(key=lambda row: str(row.get("add_card") or ""))
    return rows


def blocked_topdeck_targets(rows: list[Mapping[str, Any]]) -> list[dict[str, Any]]:
    return [
        {
            "add_card": row.get("add_card") or "",
            "model_status": row.get("nonanchor_model_status") or "",
            "same_lane_slot_count": as_int(row.get("nonanchor_same_lane_slot_count")),
            "seed_safe_nonanchor_count": as_int(row.get("nonanchor_seed_safe_count")),
            "reviewable_nonanchor_gap_count": as_int(row.get("nonanchor_reviewable_gap_count")),
            "blockers": as_list(row.get("blockers")),
        }
        for row in rows
    ]


def blocker_counts(rows: list[Mapping[str, Any]]) -> dict[str, int]:
    return dict(
        sorted(
            Counter(
                blocker for row in rows for blocker in as_list(row.get("blockers"))
            ).items()
        )
    )


def mana_foundation(value_model: Mapping[str, Any]) -> dict[str, Any]:
    value_summary = summary(value_model)
    foundation = as_dict(value_summary.get("mana_foundation"))
    if not foundation:
        return {
            "land_quantity": as_int(value_summary.get("value_model_land_quantity")),
            "ramp_quantity": as_int(value_summary.get("value_model_ramp_quantity")),
        }
    return foundation


def structure_contract_allowed(
    *,
    missing_inputs: list[str],
    route_summary: Mapping[str, Any],
    queue_summary: Mapping[str, Any],
) -> bool:
    if missing_inputs:
        return False
    if route_summary.get("selected_route") != TARGET_ROUTE:
        return False
    return as_int(queue_summary.get("matrix_candidate_row_eligible_count")) > 0


def decision_status(
    *,
    missing_inputs: list[str],
    route_summary: Mapping[str, Any],
    queue_summary: Mapping[str, Any],
) -> tuple[str, str]:
    if missing_inputs:
        return (
            "topdeck_access_first_sidecar_contract_inputs_missing_keep_607",
            "rerun_missing_source_reports_before_sidecar_contract",
        )
    if route_summary.get("selected_route") != TARGET_ROUTE:
        return (
            "topdeck_access_first_sidecar_contract_blocked_wrong_route_keep_607",
            "rerun_post_safe_cut_route_before_sidecar_contract",
        )
    if as_int(queue_summary.get("matrix_candidate_row_eligible_count")) > 0:
        return (
            "topdeck_access_first_sidecar_contract_ready_for_structure_contract_no_deck",
            "write_structure_matrix_contract_for_eligible_sidecar_rows_no_battle",
        )
    return (
        "topdeck_access_first_sidecar_contract_written_no_matrix_rows_keep_607",
        "build_named_same_lane_cut_models_for_topdeck_and_mana_rows_before_structure_matrix",
    )


def build_report(
    *,
    post_safe_cut_route: Mapping[str, Any],
    sidecar_queue: Mapping[str, Any],
    nonanchor_cut_model: Mapping[str, Any],
    miracle_shell_contract: Mapping[str, Any],
    value_model: Mapping[str, Any],
    trace_evidence: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    payloads = {
        "post_safe_cut_route": post_safe_cut_route,
        "sidecar_queue": sidecar_queue,
        "nonanchor_cut_model": nonanchor_cut_model,
        "miracle_shell_contract": miracle_shell_contract,
        "value_model": value_model,
        "trace_evidence": trace_evidence,
    }
    health = input_health(payloads)
    route_summary = summary(post_safe_cut_route)
    queue_summary = summary(sidecar_queue)
    nonanchor_summary = summary(nonanchor_cut_model)
    miracle_summary = summary(miracle_shell_contract)
    trace_summary = summary(trace_evidence)
    rows = [] if health["missing_inputs"] else topdeck_rows(sidecar_queue)
    status, next_action = decision_status(
        missing_inputs=as_list(health.get("missing_inputs")),
        route_summary=route_summary,
        queue_summary=queue_summary,
    )
    matrix_contract_allowed = structure_contract_allowed(
        missing_inputs=as_list(health.get("missing_inputs")),
        route_summary=route_summary,
        queue_summary=queue_summary,
    )
    foundation = mana_foundation(value_model)
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_topdeck_access_first_sidecar_shell_contract",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "external_research_refresh": EXTERNAL_RESEARCH_REFRESH,
        "summary": {
            "decision_status": status,
            "contract_key": TARGET_CONTRACT,
            "shell_key": TARGET_ROUTE,
            "contract_written": not bool(health["missing_inputs"])
            and route_summary.get("selected_route") == TARGET_ROUTE,
            "selected_route": route_summary.get("selected_route") or "",
            "sidecar_shell_contract_required": bool(
                route_summary.get("sidecar_shell_contract_required")
            ),
            "queue_row_count": as_int(queue_summary.get("queue_row_count")),
            "matrix_candidate_row_eligible_count": as_int(
                queue_summary.get("matrix_candidate_row_eligible_count")
            ),
            "topdeck_target_row_count": len(rows),
            "nonanchor_primary_target": nonanchor_summary.get("primary_target") or "",
            "nonanchor_primary_target_status": nonanchor_summary.get(
                "primary_target_model_status"
            )
            or "",
            "nonanchor_seed_safe_count": as_int(nonanchor_summary.get("seed_safe_nonanchor_count")),
            "nonanchor_reviewable_gap_count": as_int(
                nonanchor_summary.get("reviewable_nonanchor_gap_count")
            ),
            "trace_collection_allowed_count": as_int(
                trace_summary.get("trace_collection_allowed_count")
            ),
            "microbenchmark_runnable_count": as_int(
                trace_summary.get("microbenchmark_runnable_count")
            ),
            "land_quantity_floor": as_int(foundation.get("land_quantity")),
            "ramp_quantity_floor": as_int(foundation.get("ramp_quantity")),
            "mana_sources_land_plus_ramp_floor": as_int(
                foundation.get("mana_sources_land_plus_ramp")
            ),
            "structure_matrix_contract_allowed_now": matrix_contract_allowed,
            "structure_matrix_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "deck_action_allowed_now": False,
            "missing_inputs": as_list(health.get("missing_inputs")),
            "recommended_next_action": next_action,
        },
        "contract": {
            "contract_key": TARGET_CONTRACT,
            "shell_key": TARGET_ROUTE,
            "shell_type": "sidecar_shell_before_structure_matrix",
            "strategic_goal": (
                "Learn whether a topdeck-access-first Lorehold shell can beat the "
                "607 baseline without cutting protected miracle, mana, topdeck, or "
                "fast-pressure floors."
            ),
            "value_lanes_to_model": SIDECAR_VALUE_LANES,
            "protected_anchors": sorted(
                set(
                    PROTECTED_TOPDECK_ANCHORS
                    + as_list(as_dict(miracle_shell_contract.get("contract")).get("protected_anchors"))
                )
            ),
            "mana_foundation_floor": foundation,
            "contract_requirements": CONTRACT_REQUIREMENTS,
            "blocked_staple_policy": BLOCKED_STAPLE_POLICY,
            "topdeck_targets": blocked_topdeck_targets(rows),
            "topdeck_target_blocker_counts": blocker_counts(rows),
            "promotion_gate_requirements": [
                "same_seed_same_opponent_matrix_against_current_deck_607",
                "candidate_ties_or_beats_607_aggregate",
                "Winota_fast_pressure_slice_ties_or_improves",
                "direct_drawn_cast_used_trace_for_added_cards_and_anchors",
                "closing_window_trace_shows_topdeck_miracle_plan_executed",
            ],
        },
        "source_evidence": {
            "post_safe_cut_route_summary": route_summary,
            "sidecar_queue_summary": queue_summary,
            "nonanchor_cut_model_summary": nonanchor_summary,
            "miracle_shell_contract_summary": miracle_summary,
            "value_model_summary": summary(value_model),
            "trace_evidence_summary": trace_summary,
            "input_health": health,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "structure_matrix_contract_allowed_now": matrix_contract_allowed,
            "structure_matrix_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "The sidecar contract can be written, but current rows have zero "
                "matrix-eligible add/cut pairs and zero non-anchor safe cuts, so "
                "learning must continue at the cut-model layer."
            )
            if not matrix_contract_allowed
            else (
                "At least one sidecar row is ready for a structure-matrix contract, "
                "but deck materialization, battle, and promotion remain closed."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_write_postgresql_or_sqlite",
                "do_not_materialize_a_sidecar_deck_from_blocked_rows",
                "mine_named_same_lane_cuts_for_topdeck_targets",
                "treat Mana Vault and The One Ring as learning-only until lane, cut, trace, and battle proof exist",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = as_dict(payload.get("summary"))
    contract = as_dict(payload.get("contract"))
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Topdeck Access First Sidecar Shell Contract",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload['status']}`",
        f"- Contract key: `{summary_row.get('contract_key')}`",
        f"- Shell key: `{summary_row.get('shell_key')}`",
        f"- Selected route: `{summary_row.get('selected_route')}`",
        f"- Queue rows: `{summary_row.get('queue_row_count')}`",
        f"- Matrix candidate rows eligible: `{summary_row.get('matrix_candidate_row_eligible_count')}`",
        f"- Topdeck target rows: `{summary_row.get('topdeck_target_row_count')}`",
        f"- Non-anchor primary target: `{summary_row.get('nonanchor_primary_target')}`",
        f"- Non-anchor primary target status: `{summary_row.get('nonanchor_primary_target_status')}`",
        f"- Non-anchor seed-safe count: `{summary_row.get('nonanchor_seed_safe_count')}`",
        f"- Non-anchor reviewable gaps: `{summary_row.get('nonanchor_reviewable_gap_count')}`",
        f"- 607 land floor: `{summary_row.get('land_quantity_floor')}`",
        f"- 607 ramp floor: `{summary_row.get('ramp_quantity_floor')}`",
        f"- Structure matrix contract allowed now: `{str(summary_row.get('structure_matrix_contract_allowed_now')).lower()}`",
        f"- Candidate deck materialization allowed now: `{str(summary_row.get('candidate_deck_materialization_allowed_now')).lower()}`",
        f"- Forced access allowed now: `{str(summary_row.get('forced_access_allowed_now')).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary_row.get('natural_battle_gate_allowed_now')).lower()}`",
        f"- Promotion allowed now: `{str(summary_row.get('promotion_allowed_now')).lower()}`",
        f"- Recommended next action: `{summary_row.get('recommended_next_action')}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## External Research Refresh", ""])
    for item in as_list(payload.get("external_research_refresh")):
        lines.append(f"- {item['source']}: {item['url']}")
        lines.append(f"  - {item['contract_use']}")
    lines.extend(["", "## Value Lanes", ""])
    for item in as_list(contract.get("value_lanes_to_model")):
        lines.append(f"- `{item}`")
    lines.extend(["", "## Protected Anchors", ""])
    for item in as_list(contract.get("protected_anchors")):
        lines.append(f"- `{item}`")
    lines.extend(["", "## Mana Foundation Floor", ""])
    lines.append(
        f"`{json.dumps(contract.get('mana_foundation_floor') or {}, sort_keys=True)}`"
    )
    lines.extend(["", "## Blocked Staples", ""])
    for item in as_list(contract.get("blocked_staple_policy")):
        lines.append(
            f"- `{item.get('card')}` in `{item.get('lane')}`: "
            f"`{item.get('current_policy')}`. {item.get('reason')}"
        )
    lines.extend(["", "## Topdeck Targets", ""])
    lines.append("| Card | Model status | Same-lane slots | Seed-safe | Reviewable gaps | Blockers |")
    lines.append("| --- | --- | ---: | ---: | ---: | --- |")
    for row in as_list(contract.get("topdeck_targets")):
        lines.append(
            "| {card} | `{status}` | `{slots}` | `{seed}` | `{gaps}` | `{blockers}` |".format(
                card=row.get("add_card") or "",
                status=row.get("model_status") or "",
                slots=row.get("same_lane_slot_count") or 0,
                seed=row.get("seed_safe_nonanchor_count") or 0,
                gaps=row.get("reviewable_nonanchor_gap_count") or 0,
                blockers=", ".join(as_list(row.get("blockers"))),
            )
        )
    lines.extend(["", "## Contract Requirements", ""])
    for item in as_list(contract.get("contract_requirements")):
        lines.append(f"- {item}")
    lines.extend(["", "## Promotion Gate Requirements", ""])
    for item in as_list(contract.get("promotion_gate_requirements")):
        lines.append(f"- `{item}`")
    lines.extend(["", "## Decision", ""])
    lines.append(
        f"- keep_607_as_protected_baseline: `{str(decision.get('keep_607_as_protected_baseline')).lower()}`"
    )
    lines.append(f"- deck_action_allowed: `{str(decision.get('deck_action_allowed')).lower()}`")
    lines.append(
        "- structure_matrix_contract_allowed_now: "
        f"`{str(decision.get('structure_matrix_contract_allowed_now')).lower()}`"
    )
    lines.append(
        "- candidate_deck_materialization_allowed_now: "
        f"`{str(decision.get('candidate_deck_materialization_allowed_now')).lower()}`"
    )
    lines.append(f"- forced_access_allowed_now: `{str(decision.get('forced_access_allowed_now')).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision.get('natural_battle_allowed_now')).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision.get('promotion_allowed')).lower()}`")
    lines.append(f"- reason: {decision.get('reason')}")
    lines.append("- next_actions:")
    for action in as_list(decision.get("next_actions")):
        lines.append(f"  - {action}")
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
    parser.add_argument("--post-safe-cut-route", type=Path, default=DEFAULT_POST_SAFE_CUT_ROUTE)
    parser.add_argument("--sidecar-queue", type=Path, default=DEFAULT_SIDECAR_QUEUE)
    parser.add_argument("--nonanchor-cut-model", type=Path, default=DEFAULT_NONANCHOR_CUT_MODEL)
    parser.add_argument("--miracle-shell-contract", type=Path, default=DEFAULT_MIRACLE_SHELL_CONTRACT)
    parser.add_argument("--value-model", type=Path, default=DEFAULT_VALUE_MODEL)
    parser.add_argument("--trace-evidence", type=Path, default=DEFAULT_TRACE_EVIDENCE)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "post_safe_cut_route": args.post_safe_cut_route,
        "sidecar_queue": args.sidecar_queue,
        "nonanchor_cut_model": args.nonanchor_cut_model,
        "miracle_shell_contract": args.miracle_shell_contract,
        "value_model": args.value_model,
        "trace_evidence": args.trace_evidence,
    }
    payload = build_report(
        post_safe_cut_route=read_json(args.post_safe_cut_route),
        sidecar_queue=read_json(args.sidecar_queue),
        nonanchor_cut_model=read_json(args.nonanchor_cut_model),
        miracle_shell_contract=read_json(args.miracle_shell_contract),
        value_model=read_json(args.value_model),
        trace_evidence=read_json(args.trace_evidence),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
