#!/usr/bin/env python3
"""Build the next Lorehold deckbuilding hypothesis queue.

This artifact is a learning/triage layer, not a deck promotion layer. It turns
the current 607 value model into test lanes and blocks natural gates until a
candidate first satisfies the miracle-access preflight contract.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

FALLBACK_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
FALLBACK_CARD_VALUE_PRIORITY = REPORT_DIR / "lorehold_card_value_priority_synthesis_20260704_learning.json"
DEFAULT_PREFLIGHT = REPORT_DIR / "lorehold_miracle_access_first_preflight_20260704_current.json"
DEFAULT_TRACE_MINER = REPORT_DIR / "lorehold_miracle_trace_failure_miner_20260704_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_hypothesis_queue_from_value_model_20260705_current_relearn"

PRIOR_REJECT_BLOCKLIST = {
    "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
    "Cloud Key",
    "Electro, Assaulting Battery",
    "Enlightened Tutor",
    "Gamble",
    "Mana Vault",
    "Possibility Storm",
    "Storm-Kiln Artist",
    "The One Ring",
}

MANA_BASE_CARDS = {
    "Plateau",
    "Clifftop Retreat",
    "Rugged Prairie",
    "Sundown Pass",
    "Boseiju, Who Shelters All",
    "Cavern of Souls",
    "Boros Garrison",
}

PROTECTION_WINDOW_CARDS = {
    "Boros Charm",
    "Silence",
    "Grand Abolisher",
    "Perch Protection",
    "Deflecting Palm",
}

TOPDECK_SETUP_CARDS = {
    "Penance",
    "Galvanoth",
    "Valakut Awakening // Valakut Stoneforge",
    "Wheel of Fortune",
    "Dragon's Rage Channeler",
}

SPELL_CHAIN_CARDS = {
    "Apex of Power",
    "Brass's Bounty",
    "Dance with Calamity",
    "Goldspan Dragon",
    "Invoke Calamity",
    "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
    "Mana Vault",
    "Cloud Key",
    "Storm-Kiln Artist",
}

TUTOR_ACCESS_CARDS = {
    "Enlightened Tutor",
    "Gamble",
    "Goblin Engineer",
}

INTERACTION_PRESSURE_CARDS = {
    "Austere Command",
    "Chaos Warp",
    "Deflecting Palm",
}

COMBO_FINISHER_CARDS = {
    "Dualcaster Mage",
    "Longshot, Rebel Bowman",
    "Goliath Daydreamer",
    "Possibility Storm",
}

EXTERNAL_RESEARCH_REFRESH = [
    {
        "source": "Wizards Commander format",
        "url": "https://magic.wizards.com/en/formats/commander",
        "learning": (
            "Commander legality remains the first gate: 99-card main deck plus commander, singleton, "
            "color identity, multiplayer context, and power-bracket framing."
        ),
    },
    {
        "source": "Official Commander rules",
        "url": "https://mtgcommander.net/index.php/rules/",
        "learning": "The deck shape, singleton rule, and color identity restrictions are hard constraints before strategy scoring.",
    },
    {
        "source": "Scryfall Lorehold Oracle",
        "url": "https://scryfall.com/card/sos/201/lorehold-the-historian",
        "learning": (
            "Lorehold's strategic center is discounted miracle for instants/sorceries plus opponent-upkeep rummage, "
            "so topdeck control and first-draw timing are not optional lanes."
        ),
    },
    {
        "source": "EDHREC Lorehold optimized topdeck decks",
        "url": "https://edhrec.com/decks/lorehold-the-historian/optimized/topdeck",
        "learning": (
            "Current public signal tags Lorehold as Topdeck, Spellslinger, Combo, and Discard; these are evidence lanes, "
            "not automatic card swaps over protected 607 anchors."
        ),
    },
    {
        "source": "EDHREC Lorehold combos",
        "url": "https://edhrec.com/combos/lorehold-the-historian",
        "learning": (
            "Approach/Scroll Rack, Mizzix's Mastery, and Top/Birgi-style combo references support package hypotheses, "
            "but combo existence is not deck-balance or battle-gate proof."
        ),
    },
    {
        "source": "Card Kingdom Lorehold synergy review",
        "url": "https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/",
        "learning": (
            "Library of Leng, Penance, Sensei's Divining Top, Scroll Rack, Land Tax, Victory Chimes, and Bender's Waterskin "
            "are externally coherent with the miracle setup plan; internal gates still decide final cuts."
        ),
    },
    {
        "source": "CoolStuffInc Lorehold commander article",
        "url": "https://www.coolstuffinc.com/a/stephenjohnson-04202026-lorehold-the-historian-commander",
        "learning": (
            "Public Lorehold builds split into spellslinger, combo, token, burn, and Voltron directions; ManaLoom must classify these as shell contracts "
            "unless they preserve the current 607 miracle/topdeck/protection floor."
        ),
    },
    {
        "source": "GameTyrant Lorehold deck tech",
        "url": "https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech",
        "learning": (
            "Current Lorehold primer evidence still points at Entreat, Approach, Apex of Power, Dance with Calamity, Hit the Mother Lode, and Insurrection "
            "as payoff hypotheses that must be balanced against topdeck setup and closing-window proof."
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
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def newest_report(pattern: str, fallback: Path, *, report_dir: Path = REPORT_DIR) -> Path:
    matches = sorted(
        report_dir.glob(pattern),
        key=lambda path: (path.stat().st_mtime, path.name),
        reverse=True,
    )
    return matches[0] if matches else fallback


def default_value_model_report() -> Path:
    return newest_report("lorehold_deckbuilding_value_model_*.json", FALLBACK_VALUE_MODEL)


def default_card_value_priority_report() -> Path:
    return newest_report(
        "lorehold_card_value_priority_synthesis_*.json",
        FALLBACK_CARD_VALUE_PRIORITY,
    )


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def hypothesis_lanes(card: Mapping[str, Any]) -> list[str]:
    name = str(card.get("card_name") or "")
    tag = str(card.get("example_functional_tag") or "")
    type_line = str(card.get("type_line") or "")
    lanes: set[str] = set()
    if name in MANA_BASE_CARDS or tag == "land" or type_line.startswith("Land"):
        lanes.add("mana_base_review")
    if name in PROTECTION_WINDOW_CARDS or tag == "protection":
        lanes.add("protection_window")
    if name in TOPDECK_SETUP_CARDS:
        lanes.add("topdeck_miracle_setup")
    if name in SPELL_CHAIN_CARDS:
        lanes.add("spell_chain_conversion")
    if name in TUTOR_ACCESS_CARDS or tag == "tutor":
        lanes.add("tutors_access")
    if name in INTERACTION_PRESSURE_CARDS or tag in {"removal", "board_wipe"}:
        lanes.add("interaction_pressure")
    if name in COMBO_FINISHER_CARDS or tag == "wincon":
        lanes.add("combo_finishers")
    if not lanes:
        lanes.add("unclassified_variant_watchlist")
    return sorted(lanes)


def readiness_status(card: Mapping[str, Any], gate_ready_now_count: int) -> str:
    name = str(card.get("card_name") or "")
    status = str(card.get("candidate_status") or "")
    if name in PRIOR_REJECT_BLOCKLIST or status.startswith("prior_tested_reject"):
        return "blocked_prior_reject"
    if gate_ready_now_count > 0 and card.get("safe_cut_model") and card.get("anchor_access_preflight_pass"):
        return "natural_gate_ready"
    return "needs_safe_cut_model"


def priority_for(card: Mapping[str, Any], lanes: list[str], status: str) -> str:
    if status == "blocked_prior_reject":
        return "P3_learning_only"
    variant_count = as_int(card.get("variant_deck_count"))
    staple_tier = str(card.get("staple_tier") or "")
    runtime_ready = bool(card.get("runtime_ready"))
    if "mana_base_review" in lanes and variant_count >= 4:
        return "P1_safe_cut_model"
    if "topdeck_miracle_setup" in lanes or "protection_window" in lanes:
        if runtime_ready or staple_tier in {"global_top_100", "global_top_500"}:
            return "P1_forced_access_diagnostic"
    if variant_count >= 5:
        return "P1_forced_access_diagnostic"
    if runtime_ready:
        return "P2_forced_access_diagnostic"
    return "P3_watchlist"


def allowed_next_test(status: str, lanes: list[str]) -> str:
    if status == "blocked_prior_reject":
        return "do_not_retest_without_new_cut_or_new_trace_hypothesis"
    if "mana_base_review" in lanes:
        return "build_safe_cut_mana_source_model_before_any_battle_gate"
    if "topdeck_miracle_setup" in lanes or "spell_chain_conversion" in lanes:
        return "forced_access_diagnostic_only_until_miracle_access_floors_pass"
    if "protection_window" in lanes:
        return "forced_access_pressure_window_diagnostic_only_until_winota_floor_passes"
    return "safe_cut_model_required_before_natural_gate"


def current_priority_lanes(card_value_priority: Mapping[str, Any]) -> dict[str, list[dict[str, Any]]]:
    by_lane: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for raw in card_value_priority.get("current_card_priorities") or []:
        if not isinstance(raw, Mapping) or not raw.get("card_name"):
            continue
        row = {
            "card_name": raw.get("card_name"),
            "primary_value_lane": raw.get("primary_value_lane"),
            "priority_class": raw.get("priority_class"),
            "cut_policy": raw.get("cut_policy"),
            "value_priority_index": as_int(raw.get("value_priority_index")),
        }
        lanes = {str(raw.get("primary_value_lane") or "")}
        lanes.update(str(lane) for lane in (raw.get("value_lanes") or []))
        for lane in lanes:
            if lane:
                by_lane[lane].append(row)
    for lane_rows in by_lane.values():
        lane_rows.sort(key=lambda row: (-as_int(row.get("value_priority_index")), str(row.get("card_name"))))
    return by_lane


def candidate_to_current_lanes(hypothesis_lanes: list[str]) -> list[str]:
    lane_map = {
        "combo_finishers": ["payoffs_finishers", "topdeck_miracle_setup"],
        "interaction_pressure": ["interaction_removal", "board_wipes", "protection_resilience"],
        "mana_base_review": ["mana_base", "ramp"],
        "protection_window": ["protection_resilience", "interaction_removal"],
        "spell_chain_conversion": ["payoffs_finishers", "topdeck_miracle_setup", "ramp"],
        "topdeck_miracle_setup": ["topdeck_miracle_setup"],
        "tutors_access": ["tutors_access", "topdeck_miracle_setup"],
        "unclassified_variant_watchlist": [],
    }
    lanes: list[str] = []
    for lane in hypothesis_lanes:
        lanes.extend(lane_map.get(lane, []))
    return sorted(set(lanes))


def same_lane_anchors(
    hypothesis_lanes: list[str],
    priority_by_lane: Mapping[str, list[Mapping[str, Any]]],
    *,
    limit: int = 5,
) -> list[dict[str, Any]]:
    anchors: list[dict[str, Any]] = []
    seen: set[str] = set()
    for lane in candidate_to_current_lanes(hypothesis_lanes):
        for row in priority_by_lane.get(lane, []):
            name = str(row.get("card_name") or "")
            if not name or name in seen:
                continue
            priority = str(row.get("priority_class") or "")
            cut_policy = str(row.get("cut_policy") or "")
            if "protected" not in priority and "protected" not in cut_policy and "same_lane" not in cut_policy:
                continue
            seen.add(name)
            anchors.append(
                {
                    "card_name": name,
                    "primary_value_lane": row.get("primary_value_lane"),
                    "priority_class": priority,
                    "cut_policy": cut_policy,
                    "value_priority_index": as_int(row.get("value_priority_index")),
                }
            )
            if len(anchors) >= limit:
                return anchors
    return anchors


def classify_hypotheses(
    value_model: Mapping[str, Any],
    gate_ready_now_count: int,
    *,
    priority_by_lane: Mapping[str, list[Mapping[str, Any]]] | None = None,
) -> list[dict[str, Any]]:
    priority_by_lane = priority_by_lane or {}
    hypotheses = []
    for card in value_model.get("variant_watchlist") or []:
        if not isinstance(card, Mapping):
            continue
        lanes = hypothesis_lanes(card)
        status = readiness_status(card, gate_ready_now_count)
        anchors = same_lane_anchors(lanes, priority_by_lane)
        hypotheses.append(
            {
                "card_name": card.get("card_name"),
                "readiness_status": status,
                "hypothesis_lanes": lanes,
                "priority": priority_for(card, lanes, status),
                "allowed_next_test": allowed_next_test(status, lanes),
                "variant_deck_count": as_int(card.get("variant_deck_count")),
                "variant_deck_ids": card.get("variant_deck_ids") or [],
                "example_functional_tag": card.get("example_functional_tag"),
                "runtime_ready": bool(card.get("runtime_ready")),
                "staple_tier": card.get("staple_tier"),
                "best_edhrec_rank": card.get("best_edhrec_rank"),
                "reason": card.get("reason"),
                "same_lane_current_607_anchors": anchors,
                "same_lane_cut_contract": (
                    "named_current_607_slot_and_equal_gate_required"
                    if status != "blocked_prior_reject"
                    else "blocked_prior_reject_requires_material_new_hypothesis"
                ),
            }
        )
    hypotheses.sort(
        key=lambda row: (
            {"P1_safe_cut_model": 0, "P1_forced_access_diagnostic": 1, "P2_forced_access_diagnostic": 2}.get(
                str(row["priority"]),
                3,
            ),
            0 if row["readiness_status"] != "blocked_prior_reject" else 1,
            -as_int(row["variant_deck_count"]),
            str(row["card_name"]),
        )
    )
    return hypotheses


def summarize_by_status(hypotheses: list[Mapping[str, Any]]) -> dict[str, int]:
    counts = Counter(str(row.get("readiness_status")) for row in hypotheses)
    return dict(sorted(counts.items()))


def summarize_by_lane(hypotheses: list[Mapping[str, Any]]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in hypotheses:
        for lane in row.get("hypothesis_lanes") or []:
            counts[str(lane)] += 1
    return dict(sorted(counts.items()))


def lane_queue(hypotheses: list[Mapping[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in hypotheses:
        for lane in row.get("hypothesis_lanes") or []:
            grouped[str(lane)].append(
                {
                    "card_name": row.get("card_name"),
                    "readiness_status": row.get("readiness_status"),
                    "priority": row.get("priority"),
                    "allowed_next_test": row.get("allowed_next_test"),
                    "variant_deck_count": row.get("variant_deck_count"),
                    "same_lane_current_607_anchors": row.get("same_lane_current_607_anchors") or [],
                }
            )
    return {lane: rows for lane, rows in sorted(grouped.items())}


def build_payload(
    *,
    value_model_path: Path | None = None,
    card_value_priority_path: Path | None = None,
    preflight_path: Path = DEFAULT_PREFLIGHT,
    trace_path: Path = DEFAULT_TRACE_MINER,
) -> dict[str, Any]:
    value_model_path = value_model_path or default_value_model_report()
    card_value_priority_path = card_value_priority_path or default_card_value_priority_report()
    value_model = read_json(value_model_path)
    card_value_priority = read_json(card_value_priority_path)
    preflight = read_json(preflight_path)
    trace = read_json(trace_path)
    gate_ready_now_count = as_int((preflight.get("summary") or {}).get("gate_ready_now_count"))
    priority_by_lane = current_priority_lanes(card_value_priority)
    hypotheses = classify_hypotheses(
        value_model,
        gate_ready_now_count,
        priority_by_lane=priority_by_lane,
    )
    natural_gate_ready = [row for row in hypotheses if row["readiness_status"] == "natural_gate_ready"]
    blocked_prior = [row for row in hypotheses if row["readiness_status"] == "blocked_prior_reject"]
    card_value_summary = card_value_priority.get("summary") or {}

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_hypothesis_queue_from_value_model",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": [
            rel(value_model_path),
            rel(card_value_priority_path),
            rel(preflight_path),
            rel(trace_path),
        ],
        "external_research_refresh": EXTERNAL_RESEARCH_REFRESH,
        "status": "lorehold_hypothesis_queue_ready_no_natural_gate",
        "summary": {
            "protected_baseline": "deck_607",
            "hypothesis_count": len(hypotheses),
            "natural_gate_ready_count": len(natural_gate_ready),
            "gate_ready_now_count_from_preflight": gate_ready_now_count,
            "blocked_prior_reject_count": len(blocked_prior),
            "hypotheses_with_same_lane_anchor_count": sum(
                1 for row in hypotheses if row.get("same_lane_current_607_anchors")
            ),
            "status_counts": summarize_by_status(hypotheses),
            "lane_counts": summarize_by_lane(hypotheses),
            "card_value_priority_status": card_value_priority.get("status"),
            "card_value_ready_replacement_count": as_int(card_value_summary.get("ready_replacement_candidate_count")),
            "game_changer_metadata_rows_considered": as_int(
                card_value_summary.get("game_changer_metadata_rows_considered")
            ),
            "preflight_status": preflight.get("status"),
            "trace_status": trace.get("status"),
            "promotion_allowed": False,
            "allow_new_natural_gate_now": False,
            "keep_607_as_protected_baseline": True,
        },
        "queue_policy": {
            "natural_gate": "closed until miracle_access_first_shell_v1 floors pass before battle",
            "prior_rejects": "blocked unless a materially new cut model or trace hypothesis is declared",
            "safe_cuts": "required before any candidate can be called a real challenger",
            "current_607_slots": "every candidate must name the protected 607 slot and lane it challenges before a natural gate can run",
            "game_changer_metadata": "Game Changer or staple discovery creates explainable candidate pressure, not promotion readiness",
            "forced_access": "allowed only as learning diagnostic; it cannot promote a deck by itself",
            "lands": "review only through a mana-source model that preserves 34 lands and protected utility anchors",
        },
        "next_learning_actions": [
            {
                "id": "mana_base_safe_cut_model_v1",
                "purpose": "Compare Plateau, Clifftop Retreat, Rugged Prairie, Sundown Pass, Boseiju, Cavern, and Boros Garrison by source quality, ETB/timing risk, and protected utility-land displacement.",
                "promotion_boundary": "No battle gate until the land cut keeps 34 lands, color access, topdeck anchors, and fast-pressure utility intact.",
            },
            {
                "id": "topdeck_forced_access_diagnostic_v1",
                "purpose": "Exercise Penance, Galvanoth, Valakut Awakening, Wheel of Fortune, and Dragon's Rage Channeler to learn whether they increase first-draw/miracle access without suppressing 607 anchors.",
                "promotion_boundary": "Forced access can teach card value, but natural-gate eligibility still requires non-regressed anchor access floors.",
            },
            {
                "id": "spell_chain_conversion_trace_v2",
                "purpose": "Study Apex of Power, Brass's Bounty, Dance with Calamity, Goldspan Dragon, and Invoke Calamity as conversion cards only after miracle/topdeck trace improves.",
                "promotion_boundary": "Do not expand pressure or mana packages without positive miracle-cast and topdeck-activation traces.",
            },
            {
                "id": "protection_window_pressure_diagnostic_v1",
                "purpose": "Test Silence, Boros Charm, Grand Abolisher, Perch Protection, and Deflecting Palm as pressure-window hypotheses with explicit Winota-floor checks.",
                "promotion_boundary": "A card that improves generic protection still fails if it regresses fast-pressure matchup or protected miracle cadence.",
            },
        ],
        "hypotheses": hypotheses,
        "lane_queue": lane_queue(hypotheses),
        "decision": {
            "current_best_baseline": "deck_607",
            "natural_gate_ready_now": False,
            "promotion_allowed": False,
            "reason": (
                "The value model has useful hypotheses, but the latest preflight has zero gate-ready candidates. "
                "No card from the watchlist currently has both safe-cut proof and miracle-access floor proof."
            ),
            "next_action": "run safe-cut model and forced-access diagnostics as learning steps before any natural battle gate",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Hypothesis Queue From Value Model",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- protected_baseline: `{summary['protected_baseline']}`",
        f"- hypothesis_count: `{summary['hypothesis_count']}`",
        f"- natural_gate_ready_count: `{summary['natural_gate_ready_count']}`",
        f"- gate_ready_now_count_from_preflight: `{summary['gate_ready_now_count_from_preflight']}`",
        f"- card_value_priority_status: `{summary['card_value_priority_status']}`",
        f"- card_value_ready_replacement_count: `{summary['card_value_ready_replacement_count']}`",
        f"- game_changer_metadata_rows_considered: `{summary['game_changer_metadata_rows_considered']}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        f"- allow_new_natural_gate_now: `{str(summary['allow_new_natural_gate_now']).lower()}`",
        "",
        "## Queue Summary",
        "",
        f"- status_counts: `{json.dumps(summary['status_counts'], sort_keys=True)}`",
        f"- lane_counts: `{json.dumps(summary['lane_counts'], sort_keys=True)}`",
        f"- preflight_status: `{summary['preflight_status']}`",
        f"- trace_status: `{summary['trace_status']}`",
        "",
        "## Next Learning Actions",
        "",
    ]
    for action in payload["next_learning_actions"]:
        lines.append(f"### {action['id']}")
        lines.append(f"- purpose: {action['purpose']}")
        lines.append(f"- promotion_boundary: {action['promotion_boundary']}")
        lines.append("")

    lines.extend(["## Hypotheses", ""])
    lines.append("| Priority | Status | Lanes | Card | Next Test |")
    lines.append("| --- | --- | --- | --- | --- |")
    for row in payload["hypotheses"]:
        lanes = ", ".join(row.get("hypothesis_lanes") or [])
        anchors = ", ".join(
            str(anchor.get("card_name"))
            for anchor in (row.get("same_lane_current_607_anchors") or [])[:3]
        )
        next_test = row["allowed_next_test"]
        if anchors:
            next_test = f"{next_test}; named slot required near: {anchors}"
        lines.append(
            "| `{priority}` | `{status}` | `{lanes}` | `{card}` | `{next_test}` |".format(
                priority=row["priority"],
                status=row["readiness_status"],
                lanes=lanes,
                card=row["card_name"],
                next_test=next_test,
            )
        )

    lines.extend(["", "## Queue Policy", ""])
    for key, value in payload["queue_policy"].items():
        lines.append(f"- {key}: {value}")

    lines.extend(["", "## External Research Refresh", ""])
    for item in payload["external_research_refresh"]:
        lines.append(f"- {item['source']}: {item['url']}")
        lines.append(f"  - {item['learning']}")

    lines.extend(["", "## Decision", ""])
    lines.append(f"- current_best_baseline: `{payload['decision']['current_best_baseline']}`")
    lines.append(f"- natural_gate_ready_now: `{str(payload['decision']['natural_gate_ready_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(payload['decision']['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {payload['decision']['reason']}")
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
    parser.add_argument("--value-model", type=Path, default=None)
    parser.add_argument("--card-value-priority", type=Path, default=None)
    parser.add_argument("--preflight", type=Path, default=DEFAULT_PREFLIGHT)
    parser.add_argument("--trace", type=Path, default=DEFAULT_TRACE_MINER)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_payload(
        value_model_path=args.value_model,
        card_value_priority_path=args.card_value_priority,
        preflight_path=args.preflight,
        trace_path=args.trace,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "promotion_allowed": payload["summary"]["promotion_allowed"],
                "natural_gate_ready_count": payload["summary"]["natural_gate_ready_count"],
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
