#!/usr/bin/env python3
"""Generate ManaLoom battle-rule proposals from a family-classified XMage batch.

The output is a review artifact and package-builder input. It never applies
PostgreSQL changes and it does not decide that XMage alone is product truth.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from battle_rule_registry import logical_rule_key
from xmage_semantic_family_classifier import build_family_report, load_json, normalize_name


DEFAULT_REPORT_DIR = Path(__file__).resolve().parent.parent.parent / "master_optimizer_reports"


DECK_ROLE_BY_FAMILY: dict[str, dict[str, Any]] = {
    "static_cost_reducer": {"category": "support", "effect": "static_cost_reduction", "subtype": "cost_reducer", "timing": "static"},
    "other_turn_mana_rock": {"category": "ramp", "effect": "ramp_permanent", "subtype": "mana_rock", "timing": "activated"},
    "modal_mana_rock": {"category": "ramp", "effect": "ramp_permanent", "subtype": "modal_mana_rock", "timing": "activated"},
    "token_maker": {"category": "board_development", "effect": "token_maker", "timing": "resolution_or_trigger"},
    "board_wipe_choice": {"category": "interaction", "effect": "board_control", "subtype": "wipe_or_sacrifice", "timing": "resolution"},
    "discard_modal_trigger": {"category": "value_engine", "effect": "discard_trigger_modal", "timing": "triggered"},
    "graveyard_spell_copy_cast": {"category": "combo_value", "effect": "graveyard_spell_copy_cast", "timing": "delayed_trigger"},
    "draw_engine": {"category": "draw", "effect": "draw_engine", "timing": "static_or_activated"},
    "passive": {"category": "support", "effect": "passive", "timing": "static"},
    "targeted_interaction": {"category": "interaction", "effect": "targeted_interaction", "timing": "resolution"},
    "manual_model": {"category": "manual_review", "effect": "external_reference_required_manual_model"},
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def external_by_name(external_harvest: dict[str, Any] | None) -> dict[str, dict[str, Any]]:
    if not external_harvest:
        return {}
    return {
        normalize_name(str(card.get("card_name") or "")): card
        for card in external_harvest.get("cards", [])
        if isinstance(card, dict) and card.get("card_name")
    }


def oracle_hash_for(card: dict[str, Any], external_card: dict[str, Any] | None) -> tuple[str | None, str]:
    if not external_card:
        local_hash = str(card.get("oracle_hash") or "").strip()
        if local_hash:
            return local_hash, "combined_coherence.oracle_hash"
        return None, "missing_external_harvest"
    candidate = external_card.get("candidate_rule") or {}
    if candidate.get("oracle_hash"):
        return str(candidate["oracle_hash"]), "candidate_rule.oracle_hash"
    scryfall = (external_card.get("external_references") or {}).get("scryfall") or {}
    if scryfall.get("oracle_hash_md5_raw"):
        return str(scryfall["oracle_hash_md5_raw"]), "scryfall.oracle_hash_md5_raw"
    return None, "missing_oracle_hash"


def external_effect_json(external_card: dict[str, Any] | None) -> dict[str, Any]:
    if not external_card:
        return {}
    effect_json = (external_card.get("candidate_rule") or {}).get("effect_json") or {}
    return dict(effect_json) if isinstance(effect_json, dict) else {}


def scryfall_mana_cost(external_card: dict[str, Any] | None) -> str:
    if not external_card:
        return ""
    scryfall = (external_card.get("external_references") or {}).get("scryfall") or {}
    return str(scryfall.get("mana_cost") or "")


def mana_value_from_mana_cost(mana_cost: str) -> float | None:
    total = 0.0
    for symbol in re.findall(r"\{([^}]+)\}", str(mana_cost or "")):
        clean = symbol.upper()
        if clean.isdigit():
            total += int(clean)
        elif clean in {"W", "U", "B", "R", "G", "C", "S"}:
            total += 1
        elif "/" in clean:
            total += 1
        elif clean in {"X", "Y", "Z"}:
            total += 0
    return total if mana_cost else None


def merged_effect_json(card: dict[str, Any], external_card: dict[str, Any] | None) -> dict[str, Any]:
    effect_json = external_effect_json(external_card)
    effect_json.update(dict(card.get("effect_json") or {}))
    effect_json.pop("xmage_hint_policy", None)
    if "cmc" not in effect_json:
        cmc = mana_value_from_mana_cost(scryfall_mana_cost(external_card))
        if cmc is not None:
            effect_json["cmc"] = cmc
    return effect_json


def runtime_effect_json(card: dict[str, Any], effect_json: dict[str, Any]) -> dict[str, Any]:
    family_id = str(card.get("family_id") or "")
    if family_id != "modal_mana_rock":
        return effect_json
    if str(effect_json.get("effect") or "") != "mana_rock_with_sacrifice_draw":
        return effect_json

    runtime_json: dict[str, Any] = {
        "effect": "ramp_permanent",
        "produces": str(effect_json.get("produces") or "C"),
        "mana_produced": int(effect_json.get("mana_produced") or 1),
        "activation_requires_tap": bool(effect_json.get("activation_requires_tap", True)),
        "activated_self_sacrifice_draw": True,
        "battle_model_scope": effect_json.get("battle_model_scope"),
    }
    if "cmc" in effect_json:
        runtime_json["cmc"] = effect_json["cmc"]
    if effect_json.get("activation_cost_generic") is not None:
        runtime_json["activation_cost_generic"] = int(effect_json["activation_cost_generic"])
    if int(effect_json.get("draw_on_self_sacrifice") or 1) > 1:
        runtime_json["draw_on_self_sacrifice"] = int(effect_json["draw_on_self_sacrifice"])
    if effect_json.get("activated_exile_target_player_graveyards"):
        runtime_json["activated_exile_target_player_graveyards"] = True
    return runtime_json


def deck_role_for(card: dict[str, Any]) -> dict[str, Any]:
    role = dict(DECK_ROLE_BY_FAMILY.get(str(card.get("family_id") or ""), DECK_ROLE_BY_FAMILY["manual_model"]))
    effect = card.get("effect")
    if effect:
        role.setdefault("effect", effect)
    return role


def notes_for(card: dict[str, Any]) -> str:
    return (
        "XMage batch proposal: exact local XMage class "
        f"{card.get('xmage_class')} mapped to family {card.get('family_id')}; "
        "requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use."
    )


def proposal_status(card: dict[str, Any], oracle_hash: str | None) -> str:
    if card.get("promotion_lane") != "batch_metadata_candidate_requires_pg_precheck":
        return str(card.get("promotion_lane"))
    if not oracle_hash:
        return "oracle_hash_required_before_batch_pg"
    return "batch_pg_candidate_after_precheck"


def build_proposal(card: dict[str, Any], external_card: dict[str, Any] | None) -> dict[str, Any]:
    effect_json = runtime_effect_json(card, merged_effect_json(card, external_card))
    deck_role_json = deck_role_for(card)
    oracle_hash, oracle_hash_source = oracle_hash_for(card, external_card)
    rule = {"effect_json": effect_json, "deck_role_json": deck_role_json}
    logical_key = logical_rule_key(rule)
    status = proposal_status(card, oracle_hash)
    return {
        "card_name": card.get("card_name"),
        "normalized_name": card.get("normalized_name"),
        "family_id": card.get("family_id"),
        "effect": card.get("effect"),
        "battle_model_scope": card.get("battle_model_scope"),
        "promotion_lane": card.get("promotion_lane"),
        "proposal_status": status,
        "safe_for_batch_pg_package": status == "batch_pg_candidate_after_precheck",
        "oracle_hash": oracle_hash,
        "oracle_hash_source": oracle_hash_source,
        "logical_rule_key": logical_key,
        "effect_json": effect_json,
        "deck_role_json": deck_role_json,
        "review_status": "verified" if status == "batch_pg_candidate_after_precheck" else "needs_review",
        "execution_status": "auto" if status == "batch_pg_candidate_after_precheck" else "review_only",
        "source": "curated" if status == "batch_pg_candidate_after_precheck" else "generated",
        "confidence": 0.94 if status == "batch_pg_candidate_after_precheck" else 0.70,
        "notes": notes_for(card),
        "xmage_class": card.get("xmage_class"),
        "xmage_path": card.get("xmage_path"),
        "focused_test_scenario_count": card.get("focused_test_scenario_count"),
    }


def build_generator_report(
    *,
    batch_audit: dict[str, Any],
    external_harvest: dict[str, Any] | None = None,
) -> dict[str, Any]:
    family_report = build_family_report(batch_audit)
    ext_by_name = external_by_name(external_harvest)
    proposals = [
        build_proposal(card, ext_by_name.get(normalize_name(str(card.get("card_name") or ""))))
        for card in family_report.get("cards", [])
    ]
    status_counts = Counter(proposal["proposal_status"] for proposal in proposals)
    family_counts = Counter(proposal["family_id"] for proposal in proposals)
    return {
        "generated_at": utc_now(),
        "status": "ready",
        "mutations_performed": [],
        "source": {
            "family_summary": family_report.get("summary"),
            "external_harvest_status": (external_harvest or {}).get("status"),
            "deck_id": (batch_audit.get("source") or {}).get("deck_id"),
        },
        "summary": {
            "proposal_count": len(proposals),
            "proposal_status_counts": dict(sorted(status_counts.items())),
            "family_counts": dict(sorted(family_counts.items())),
            "safe_for_batch_pg_package_count": sum(1 for proposal in proposals if proposal["safe_for_batch_pg_package"]),
            "runtime_family_required_count": status_counts.get("runtime_family_implementation_required", 0),
            "blocked_missing_xmage_source_count": status_counts.get("blocked_missing_xmage_source", 0),
        },
        "proposals": proposals,
    }


def markdown_report(report: dict[str, Any]) -> str:
    lines = [
        "# XMage Effect JSON Batch Proposals",
        "",
        f"Generated at: `{report['generated_at']}`",
        "",
        "Read-only artifact. `mutations_performed=[]`.",
        "",
        f"- Summary: `{json.dumps(report.get('summary'), sort_keys=True)}`",
        "",
        "| Card | Family | Status | Logical rule key | Oracle hash | Effect |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for proposal in report.get("proposals", []):
        lines.append(
            "| "
            + " | ".join(
                [
                    f"`{proposal.get('card_name')}`",
                    f"`{proposal.get('family_id')}`",
                    f"`{proposal.get('proposal_status')}`",
                    f"`{proposal.get('logical_rule_key')}`",
                    f"`{proposal.get('oracle_hash')}`",
                    f"`{proposal.get('effect')}`",
                ]
            )
            + " |"
        )
    return "\n".join(lines).rstrip() + "\n"


def write_report(report: dict[str, Any], output_json: Path, output_md: Path) -> None:
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    output_md.write_text(markdown_report(report), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xmage-batch-audit", required=True)
    parser.add_argument("--external-harvest")
    parser.add_argument("--output-prefix")
    parser.add_argument("--output-json")
    parser.add_argument("--output-md")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    batch_audit = load_json(Path(args.xmage_batch_audit))
    external_harvest = load_json(Path(args.external_harvest)) if args.external_harvest else None
    report = build_generator_report(batch_audit=batch_audit, external_harvest=external_harvest)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    if args.output_prefix:
        output_json = Path(f"{args.output_prefix}.json")
        output_md = Path(f"{args.output_prefix}.md")
    else:
        stem = f"xmage_effect_json_batch_proposals_{timestamp}"
        output_json = Path(args.output_json or DEFAULT_REPORT_DIR / f"{stem}.json")
        output_md = Path(args.output_md or DEFAULT_REPORT_DIR / f"{stem}.md")
    if args.output_json:
        output_json = Path(args.output_json)
    if args.output_md:
        output_md = Path(args.output_md)
    write_report(report, output_json, output_md)
    print(f"json_report={output_json}")
    print(f"md_report={output_md}")
    print(f"summary={json.dumps(report['summary'], sort_keys=True)}")
    print("mutations_performed=[]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
