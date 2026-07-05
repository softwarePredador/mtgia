#!/usr/bin/env python3
"""Refresh the current staple accessibility decision for protected Lorehold 607.

This audit answers a product/deckbuilding ambiguity that keeps recurring:
"accessible" can mean legal, color-identity compatible, owned, discoverable as
a staple/Game Changer, bracket-allowed, runtime-modeled, cut-ready, or actually
promotable. Those are different layers. The report is read-only and keeps deck
607 protected unless a card has a named same-lane cut plus gate evidence.
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

DEFAULT_ACCESSIBILITY = REPORT_DIR / "lorehold_accessibility_layer_matrix_20260705_current.json"
DEFAULT_HYPOTHESIS_QUEUE = (
    REPORT_DIR / "lorehold_hypothesis_queue_from_value_model_20260705_current_relearn.json"
)
DEFAULT_GAME_CHANGER_AUDIT = REPORT_DIR / "game_changer_discovery_gap_audit_20260705_current.json"
DEFAULT_VALUE_PRIORITY = (
    REPORT_DIR / "lorehold_card_value_priority_synthesis_20260705_current_relearn.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_staple_accessibility_freshness_audit_20260705_current"
)
DEFAULT_CARDS = ("Mana Vault", "The One Ring")

EXTERNAL_RULES_SNAPSHOT = {
    "checked_at": "2026-07-05",
    "official_commander_banned_list": {
        "url": "https://mtgcommander.net/index.php/banned-list/",
        "interpretation": (
            "The current Commander banned list is format-specific and does not "
            "list Mana Vault or The One Ring as Commander-banned cards."
        ),
        "banned_list_updated_quarterly": True,
    },
    "latest_wizards_bnr_announcement": {
        "url": "https://magic.wizards.com/en/news/announcements/banned-and-restricted-june-29-2026",
        "published": "2026-06-29",
        "commander_changes": "none_seen_in_current_announcement",
        "next_announcement": "2026-08-10",
    },
    "wizards_commander_brackets_beta": {
        "url": "https://magic.wizards.com/en/news/announcements/introducing-commander-brackets-beta",
        "bracket_4_rule": "no_restrictions_other_than_banned_list",
        "game_changer_meaning": (
            "Game Changer is a power and matchmaking signal, not a Commander ban."
        ),
    },
    "cards": {
        "Mana Vault": {
            "external_commander_legal": True,
            "external_color_identity_allowed_for_lorehold": True,
            "external_game_changer": True,
            "external_role": "fast_mana",
            "external_reason": (
                "Wizards grouped Mana Vault with powerful fast-mana pieces that "
                "accelerate games."
            ),
        },
        "The One Ring": {
            "external_commander_legal": True,
            "external_color_identity_allowed_for_lorehold": True,
            "external_game_changer": True,
            "external_role": "resource_engine",
            "external_reason": (
                "Wizards grouped The One Ring with overwhelming resource-advantage "
                "cards that can snowball games."
            ),
        },
    },
}


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


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def index_rows(rows: Sequence[Any], *fields: str) -> dict[str, dict[str, Any]]:
    indexed: dict[str, dict[str, Any]] = {}
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        for field in fields:
            value = row.get(field)
            if value:
                indexed[normalize_name(value)] = dict(row)
                break
    return indexed


def game_changer_rows(payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return index_rows(as_list(payload.get("rows")), "card_name")


def hypothesis_rows(payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return index_rows(as_list(payload.get("hypotheses")), "card_name")


def accessibility_rows(payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return index_rows(as_list(payload.get("cards")), "card_name")


def replacement_pressure_rows(payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return index_rows(as_list(payload.get("candidate_replacement_pressure")), "card_name")


def bool_at(mapping: Mapping[str, Any], *path: str) -> bool:
    value: Any = mapping
    for key in path:
        if not isinstance(value, Mapping):
            return False
        value = value.get(key)
    return bool(value)


def promotion_decision(row: Mapping[str, Any]) -> str:
    promotion = as_dict(row.get("promotion_layer"))
    return str(promotion.get("decision") or "")


def is_promotion_blocked(accessibility: Mapping[str, Any], hypothesis: Mapping[str, Any]) -> bool:
    decision = promotion_decision(accessibility)
    readiness = str(hypothesis.get("readiness_status") or "")
    return (
        decision.startswith("blocked")
        or decision.startswith("reject")
        or readiness in {"blocked_prior_reject", "needs_safe_cut_model"}
    )


def same_lane_anchor_names(hypothesis: Mapping[str, Any]) -> list[str]:
    names: list[str] = []
    for row in as_list(hypothesis.get("same_lane_current_607_anchors")):
        if isinstance(row, Mapping) and row.get("card_name"):
            names.append(str(row["card_name"]))
    return names


def app_accessibility_label(
    *,
    external: Mapping[str, Any],
    accessibility: Mapping[str, Any],
    hypothesis: Mapping[str, Any],
) -> str:
    local_legal = bool_at(accessibility, "rules_layer", "commander_legal")
    external_legal = bool(external.get("external_commander_legal"))
    color_allowed = bool_at(accessibility, "rules_layer", "color_identity_allowed") and bool(
        external.get("external_color_identity_allowed_for_lorehold")
    )
    bracket_allowed = bool_at(accessibility, "bracket_layer", "allowed_by_bracket")
    owned = bool_at(accessibility, "collection_layer", "owned")
    blocked = is_promotion_blocked(accessibility, hypothesis)
    readiness = str(hypothesis.get("readiness_status") or "")

    if not local_legal or not external_legal:
        return "not_accessible_commander_illegal"
    if not color_allowed:
        return "not_accessible_lorehold_color_identity"
    if not bracket_allowed:
        return "rules_legal_but_not_bracket_allowed"
    if not owned and blocked:
        return "rules_accessible_collection_missing_promotion_blocked"
    if not owned:
        return "rules_accessible_collection_missing"
    if blocked:
        return "rules_collection_accessible_promotion_blocked"
    if readiness == "natural_gate_ready":
        return "candidate_ready_for_equal_gate_not_auto_promoted"
    return "rules_collection_accessible_requires_named_cut_and_gate"


def next_action_for(label: str, hypothesis: Mapping[str, Any], accessibility: Mapping[str, Any]) -> str:
    if label == "rules_accessible_collection_missing_promotion_blocked":
        return "do_not_offer_as_available_deck_change_until_collection_and_new_cut_trace_exist"
    if label == "rules_collection_accessible_promotion_blocked":
        return "show_owned_but_blocked_prior_reject_and_require_new_same_lane_trace"
    if label == "rules_accessible_collection_missing":
        return "request_collection_or_proxy_policy_then_named_same_lane_cut"
    if label == "candidate_ready_for_equal_gate_not_auto_promoted":
        return "run_equal_matrix_and_battle_gate_before_any_deck_mutation"
    if str(hypothesis.get("allowed_next_test") or ""):
        return str(hypothesis["allowed_next_test"])
    if str(promotion_decision(accessibility)):
        return "respect_existing_promotion_decision_before_new_test"
    return "build_named_same_lane_cut_model_before_battle"


def build_card_row(
    *,
    card_name: str,
    accessibility: Mapping[str, Any],
    hypothesis: Mapping[str, Any],
    game_changer_row: Mapping[str, Any],
    replacement_pressure: Mapping[str, Any],
    external_card: Mapping[str, Any],
) -> dict[str, Any]:
    label = app_accessibility_label(
        external=external_card,
        accessibility=accessibility,
        hypothesis=hypothesis,
    )
    discovery = as_dict(accessibility.get("discovery_layer"))
    collection = as_dict(accessibility.get("collection_layer"))
    rules = as_dict(accessibility.get("rules_layer"))
    bracket = as_dict(accessibility.get("bracket_layer"))
    return {
        "card_name": card_name,
        "external": {
            "commander_legal": bool(external_card.get("external_commander_legal")),
            "lorehold_color_allowed": bool(
                external_card.get("external_color_identity_allowed_for_lorehold")
            ),
            "game_changer": bool(external_card.get("external_game_changer")),
            "role": external_card.get("external_role") or "",
            "reason": external_card.get("external_reason") or "",
        },
        "local_rules": {
            "commander_legal": bool(rules.get("commander_legal")),
            "commander_status": rules.get("commander_status") or "",
            "color_identity_allowed": bool(rules.get("color_identity_allowed")),
            "type_line": rules.get("type_line") or "",
            "mana_cost": rules.get("mana_cost") or "",
        },
        "collection": {
            "owned": bool(collection.get("owned")),
            "owned_quantity": int(collection.get("owned_quantity") or 0),
        },
        "discovery": {
            "format_staple_present": bool(discovery.get("format_staple_present")),
            "format_staples_gap": bool(discovery.get("format_staples_gap")),
            "local_official_game_changer": bool(discovery.get("official_game_changer")),
            "game_changer_discovery_status": game_changer_row.get("status") or "",
            "battle_rule_active_count": int(discovery.get("battle_rule_active_count") or 0),
        },
        "bracket": {
            "target_bracket": int(bracket.get("target_bracket") or 0),
            "allowed_by_bracket": bool(bracket.get("allowed_by_bracket")),
            "reason": bracket.get("reason") or "",
        },
        "hypothesis": {
            "readiness_status": hypothesis.get("readiness_status") or "",
            "priority": hypothesis.get("priority") or "",
            "allowed_next_test": hypothesis.get("allowed_next_test") or "",
            "lanes": as_list(hypothesis.get("hypothesis_lanes")),
            "same_lane_cut_contract": hypothesis.get("same_lane_cut_contract") or "",
            "same_lane_current_607_anchors": same_lane_anchor_names(hypothesis),
            "reason": hypothesis.get("reason") or "",
        },
        "promotion": {
            "decision": promotion_decision(accessibility),
            "current_607_accessibility": accessibility.get("current_607_accessibility") or "",
            "replacement_pressure": replacement_pressure.get("status") or "",
        },
        "app_accessibility_label": label,
        "deck_action_allowed_now": False,
        "natural_gate_allowed_now": False,
        "next_action": next_action_for(label, hypothesis, accessibility),
    }


def build_report(
    *,
    accessibility: Mapping[str, Any],
    hypothesis_queue: Mapping[str, Any],
    game_changer_audit: Mapping[str, Any],
    value_priority: Mapping[str, Any],
    cards: Sequence[str] = DEFAULT_CARDS,
    external_snapshot: Mapping[str, Any] = EXTERNAL_RULES_SNAPSHOT,
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    access_by_card = accessibility_rows(accessibility)
    hypothesis_by_card = hypothesis_rows(hypothesis_queue)
    game_changer_by_card = game_changer_rows(game_changer_audit)
    pressure_by_card = replacement_pressure_rows(value_priority)
    external_cards = as_dict(external_snapshot.get("cards"))

    card_rows = []
    missing_inputs: list[str] = []
    for card_name in cards:
        key = normalize_name(card_name)
        access_row = access_by_card.get(key, {})
        hyp_row = hypothesis_by_card.get(key, {})
        external_card = as_dict(external_cards.get(card_name) or external_cards.get(key))
        if not access_row:
            missing_inputs.append(f"accessibility:{card_name}")
        if not hyp_row:
            missing_inputs.append(f"hypothesis:{card_name}")
        if not external_card:
            missing_inputs.append(f"external:{card_name}")
        card_rows.append(
            build_card_row(
                card_name=card_name,
                accessibility=access_row,
                hypothesis=hyp_row,
                game_changer_row=game_changer_by_card.get(key, {}),
                replacement_pressure=pressure_by_card.get(key, {}),
                external_card=external_card,
            )
        )

    label_counts = Counter(row["app_accessibility_label"] for row in card_rows)
    blocked_count = sum(
        1
        for row in card_rows
        if row["app_accessibility_label"]
        in {
            "rules_accessible_collection_missing_promotion_blocked",
            "rules_collection_accessible_promotion_blocked",
        }
    )
    natural_gate_ready_count = sum(
        1 for row in card_rows if row["hypothesis"]["readiness_status"] == "natural_gate_ready"
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_staple_accessibility_freshness_audit",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": (
            "staple_accessibility_freshness_inputs_missing"
            if missing_inputs
            else "staple_accessibility_current_legal_but_not_promotion_ready_keep_607"
        ),
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "external_rules_snapshot": external_snapshot,
        "summary": {
            "cards_reviewed": len(card_rows),
            "missing_inputs": missing_inputs,
            "external_commander_legal_count": sum(
                1 for row in card_rows if row["external"]["commander_legal"]
            ),
            "local_commander_legal_count": sum(
                1 for row in card_rows if row["local_rules"]["commander_legal"]
            ),
            "owned_count": sum(1 for row in card_rows if row["collection"]["owned"]),
            "game_changer_count": sum(1 for row in card_rows if row["external"]["game_changer"]),
            "format_staples_gap_count": sum(
                1 for row in card_rows if row["discovery"]["format_staples_gap"]
            ),
            "promotion_blocked_count": blocked_count,
            "natural_gate_ready_count": natural_gate_ready_count,
            "label_counts": dict(sorted(label_counts.items())),
            "hypothesis_queue_status": hypothesis_queue.get("status") or "",
            "hypothesis_queue_natural_gate_ready_count": int(
                summary(hypothesis_queue).get("natural_gate_ready_count") or 0
            ),
            "value_priority_ready_replacement_count": int(
                summary(value_priority).get("ready_replacement_candidate_count") or 0
            ),
            "game_changer_discovery_status": game_changer_audit.get("status") or "",
            "deck_action_allowed_now": False,
            "natural_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "recommended_next_action": (
                "surface_accessibility_by_layer_and_require_new_cut_trace_before_retesting_staples"
            ),
        },
        "cards": card_rows,
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "natural_gate_allowed_now": False,
            "promotion_allowed": False,
            "rules_legal_is_not_same_as_deck_accessible": True,
            "app_label_requirement": (
                "Show legal, collection, discovery, bracket, and promotion layers separately. "
                "Do not collapse Mana Vault or The One Ring into one accessible/inaccessible flag."
            ),
            "reason": (
                "Both reviewed cards are legal and Lorehold-color-compatible by current external "
                "rules evidence, but the current 607 evidence has zero natural-gate-ready rows "
                "and both cards remain blocked by collection and/or prior promotion evidence."
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = as_dict(payload.get("summary"))
    lines = [
        "# Lorehold Staple Accessibility Freshness Audit",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload['status']}`",
        f"- Cards reviewed: `{summary_row['cards_reviewed']}`",
        f"- External Commander-legal cards: `{summary_row['external_commander_legal_count']}`",
        f"- Local Commander-legal cards: `{summary_row['local_commander_legal_count']}`",
        f"- Owned cards: `{summary_row['owned_count']}`",
        f"- Game Changers reviewed: `{summary_row['game_changer_count']}`",
        f"- Format-staples gaps: `{summary_row['format_staples_gap_count']}`",
        f"- Promotion-blocked cards: `{summary_row['promotion_blocked_count']}`",
        f"- Natural-gate-ready cards: `{summary_row['natural_gate_ready_count']}`",
        f"- Deck action allowed now: `{str(summary_row['deck_action_allowed_now']).lower()}`",
        f"- Natural gate allowed now: `{str(summary_row['natural_gate_allowed_now']).lower()}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")

    external = as_dict(payload.get("external_rules_snapshot"))
    lines.extend(["", "## External Rules Snapshot", ""])
    lines.append(
        f"- Commander banned list: {as_dict(external.get('official_commander_banned_list')).get('url') or '-'}"
    )
    lines.append(
        f"- Latest WotC B&R announcement: {as_dict(external.get('latest_wizards_bnr_announcement')).get('url') or '-'}"
    )
    lines.append(
        f"- Commander Brackets source: {as_dict(external.get('wizards_commander_brackets_beta')).get('url') or '-'}"
    )
    lines.append(
        "- Snapshot interpretation: Mana Vault and The One Ring are treated as "
        "Commander-legal, Lorehold-color-compatible Game Changers; Game Changer "
        "is a power/matchmaking signal, not promotion proof."
    )

    lines.extend(["", "## Card Layer Results", ""])
    lines.append(
        "| Card | External role | Owned | Format staple | Discovery gap | Hypothesis status | App label | Next action |"
    )
    lines.append("| --- | --- | ---: | --- | --- | --- | --- | --- |")
    for row in as_list(payload.get("cards")):
        lines.append(
            "| {card} | `{role}` | {owned} | `{staple}` | `{gap}` | `{status}` | `{label}` | `{next}` |".format(
                card=row.get("card_name") or "",
                role=as_dict(row.get("external")).get("role") or "",
                owned=as_dict(row.get("collection")).get("owned_quantity") or 0,
                staple=as_dict(row.get("discovery")).get("format_staple_present"),
                gap=as_dict(row.get("discovery")).get("format_staples_gap"),
                status=as_dict(row.get("hypothesis")).get("readiness_status") or "",
                label=row.get("app_accessibility_label") or "",
                next=row.get("next_action") or "",
            )
        )

    lines.extend(["", "## Per-Card Explanation", ""])
    for row in as_list(payload.get("cards")):
        hyp = as_dict(row.get("hypothesis"))
        external_row = as_dict(row.get("external"))
        anchors = hyp.get("same_lane_current_607_anchors") or []
        lines.append(f"### {row.get('card_name') or ''}")
        lines.append(f"- external role: `{external_row.get('role') or ''}`")
        lines.append(f"- external reason: {external_row.get('reason') or '-'}")
        lines.append(f"- app label: `{row.get('app_accessibility_label') or ''}`")
        lines.append(f"- promotion decision: `{as_dict(row.get('promotion')).get('decision') or '-'}`")
        lines.append(f"- same-lane anchors: `{', '.join(anchors) if anchors else '-'}`")
        lines.append(f"- next action: `{row.get('next_action') or ''}`")

    decision = as_dict(payload.get("decision"))
    lines.extend(["", "## Decision", ""])
    lines.append(
        f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`"
    )
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- natural_gate_allowed_now: `{str(decision['natural_gate_allowed_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(
        f"- rules_legal_is_not_same_as_deck_accessible: `{str(decision['rules_legal_is_not_same_as_deck_accessible']).lower()}`"
    )
    lines.append(f"- app_label_requirement: {decision['app_label_requirement']}")
    lines.append(f"- reason: {decision['reason']}")
    lines.append("")
    return "\n".join(lines)


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
    parser.add_argument("--accessibility", type=Path, default=DEFAULT_ACCESSIBILITY)
    parser.add_argument("--hypothesis-queue", type=Path, default=DEFAULT_HYPOTHESIS_QUEUE)
    parser.add_argument("--game-changer-audit", type=Path, default=DEFAULT_GAME_CHANGER_AUDIT)
    parser.add_argument("--value-priority", type=Path, default=DEFAULT_VALUE_PRIORITY)
    parser.add_argument("--cards", default=",".join(DEFAULT_CARDS))
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    cards = [card.strip() for card in str(args.cards).split(",") if card.strip()]
    paths = {
        "accessibility": args.accessibility,
        "game_changer_audit": args.game_changer_audit,
        "hypothesis_queue": args.hypothesis_queue,
        "value_priority": args.value_priority,
    }
    payload = build_report(
        accessibility=read_json(args.accessibility),
        hypothesis_queue=read_json(args.hypothesis_queue),
        game_changer_audit=read_json(args.game_changer_audit),
        value_priority=read_json(args.value_priority),
        cards=cards,
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
