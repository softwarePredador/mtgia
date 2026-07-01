#!/usr/bin/env python3
"""Split authoritative XMage queue rows into exact ManaLoom runtime scopes.

This is the bridge between "XMage source resolved" and "PostgreSQL executable
rule candidate". It deliberately accepts only narrow, runtime-backed spell
patterns. Broad review scopes stay blocked for a later subpattern mapper.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

from battle_rule_registry import deck_role_from_effect, logical_rule_key


REPORT_DIR = Path(__file__).resolve().parent.parent.parent / "master_optimizer_reports"

DRAW_UNIT = "draw_cards::xmage_draw_card_variant_review_v1"
DAMAGE_UNIT = "direct_damage::targeted_damage_variant_v1"
DESTROY_UNIT = "removal_destroy::targeted_destroy_variant_v1"
SUPPORTED_UNITS = {DRAW_UNIT, DAMAGE_UNIT, DESTROY_UNIT}

DRAW_SCOPE = "xmage_fixed_source_controller_draw_spell_v1"
DAMAGE_SCOPE = "xmage_fixed_damage_target_spell_v1"
DESTROY_SCOPE = "xmage_destroy_target_spell_v1"


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def normalize_name(value: str) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def md5_text(value: str) -> str:
    return hashlib.md5(str(value or "").encode("utf-8")).hexdigest()


def fetch_card_metadata_by_id() -> dict[str, dict[str, Any]]:
    from db_helper import connect

    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                  id::text AS card_id,
                  name,
                  COALESCE(type_line, '') AS type_line,
                  COALESCE(oracle_text, '') AS oracle_text,
                  COALESCE(mana_cost, '') AS mana_cost,
                  md5(COALESCE(oracle_text, '')) AS oracle_hash
                FROM cards
                """
            )
            columns = [desc[0] for desc in cur.description]
            return {str(row[0]): dict(zip(columns, row)) for row in cur.fetchall()}


def default_source_reader(row: dict[str, Any]) -> str:
    path = Path(str(row.get("xmage_path") or ""))
    if not path.is_file():
        return ""
    return path.read_text(encoding="utf-8", errors="replace")


def java_constructor_int(source: str, class_name: str, *, default: int | None = None) -> int | None:
    match = re.search(rf"\b{re.escape(class_name)}\s*\(\s*(\d+)\b", source)
    if match:
        return int(match.group(1))
    return default


def has_additional_cost(source: str) -> bool:
    return bool(re.search(r"\.addCost\s*\(", source or ""))


def is_spell(metadata: dict[str, Any]) -> bool:
    type_line = str(metadata.get("type_line") or "").lower()
    return "instant" in type_line or "sorcery" in type_line


def spell_flags(metadata: dict[str, Any]) -> dict[str, bool]:
    type_line = str(metadata.get("type_line") or "").lower()
    return {
        "instant": "instant" in type_line,
        "sorcery": "sorcery" in type_line,
    }


def effect_classes(row: dict[str, Any]) -> set[str]:
    return {str(value) for value in (row.get("xmage_effect_classes") or []) if str(value)}


def ability_kind(row: dict[str, Any]) -> str:
    return str((row.get("effect_json") or {}).get("ability_kind") or "")


def oracle_text(metadata: dict[str, Any]) -> str:
    return re.sub(r"\s+", " ", str(metadata.get("oracle_text") or "").strip()).lower()


def destroy_target_from_oracle(metadata: dict[str, Any]) -> tuple[str, str] | None:
    text = oracle_text(metadata)
    if "destroy target" not in text:
        return None
    if re.search(r"destroy target artifact or enchantment\b", text):
        return "remove_permanent", "artifact_or_enchantment"
    if re.search(r"destroy target artifact\b", text):
        return "remove_permanent", "artifact"
    if re.search(r"destroy target enchantment\b", text):
        return "remove_permanent", "enchantment"
    if re.search(r"destroy target nonland permanent\b", text):
        return "remove_permanent", "nonland_permanent"
    if re.search(r"destroy target creature, enchantment, or planeswalker\b", text):
        return "remove_permanent", "creature_enchantment_or_planeswalker"
    if re.search(r"destroy target creature or planeswalker\b", text):
        return "remove_permanent", "creature_or_planeswalker"
    if re.search(r"destroy target creature\b", text):
        return "remove_creature", "creature"
    if re.search(r"destroy target land\b", text):
        return "remove_permanent", "land"
    if re.search(r"destroy target permanent\b", text):
        return "remove_permanent", "permanent"
    return None


def damage_target_from_oracle(metadata: dict[str, Any]) -> str | None:
    text = oracle_text(metadata)
    if "any target" in text:
        return "any_target"
    if re.search(r"target opponent\b", text):
        return "opponent"
    if re.search(r"target player\b", text):
        return "player"
    if re.search(r"target creature or planeswalker\b", text):
        return "creature_or_planeswalker"
    if re.search(r"target creature\b", text):
        return "creature"
    return None


def target_constraints_for(target: str) -> dict[str, Any]:
    if target == "any_target":
        return {"scope": "any_target"}
    if target == "creature":
        return {"card_types": ["creature"]}
    if target == "creature_or_planeswalker":
        return {"card_types": ["creature", "planeswalker"]}
    if target == "player":
        return {"scope": "player"}
    if target == "opponent":
        return {"scope": "opponent"}
    if target in {"artifact", "enchantment", "land", "permanent", "nonland_permanent"}:
        return {"card_types": [target]}
    if target == "artifact_or_enchantment":
        return {"card_types": ["artifact", "enchantment"]}
    if target == "creature_enchantment_or_planeswalker":
        return {"card_types": ["creature", "enchantment", "planeswalker"]}
    return {"target": target}


def proposal_notes(row: dict[str, Any], scope: str) -> str:
    return (
        "XMage authoritative exact-scope split: local class "
        f"{row.get('xmage_class')} translated into ManaLoom runtime scope {scope}. "
        "This row is package-ready only because the source signature is a one-shot "
        "instant/sorcery spell with no additional cost and focused runtime coverage."
    )


def build_proposal(
    row: dict[str, Any],
    metadata: dict[str, Any],
    effect_json: dict[str, Any],
    *,
    family_id: str,
) -> dict[str, Any]:
    normalized_name = normalize_name(str(metadata.get("name") or row.get("normalized_name") or row.get("card_name") or ""))
    card_name = str(metadata.get("name") or row.get("card_name") or "")
    deck_role_json = deck_role_from_effect(effect_json)
    rule = {"effect_json": effect_json, "deck_role_json": deck_role_json}
    logical_key = logical_rule_key(rule)
    return {
        "card_id": str(row.get("card_id") or ""),
        "card_name": card_name,
        "normalized_name": normalized_name,
        "family_id": family_id,
        "effect": effect_json.get("effect"),
        "battle_model_scope": effect_json.get("battle_model_scope"),
        "promotion_lane": "batch_metadata_candidate_requires_pg_precheck",
        "proposal_status": "batch_pg_candidate_after_precheck",
        "safe_for_batch_pg_package": True,
        "shadow_handling": "deprecate_nonmatching_rows",
        "oracle_hash": str(metadata.get("oracle_hash") or md5_text(str(metadata.get("oracle_text") or ""))),
        "oracle_hash_source": "postgres.cards.oracle_text_md5",
        "logical_rule_key": logical_key,
        "effect_json": effect_json,
        "deck_role_json": deck_role_json,
        "review_status": "verified",
        "execution_status": "auto",
        "source": "curated",
        "confidence": 0.96,
        "notes": proposal_notes(row, str(effect_json.get("battle_model_scope") or "")),
        "xmage_class": row.get("xmage_class"),
        "xmage_path": row.get("xmage_path"),
        "adapter_work_unit": row.get("adapter_work_unit"),
    }


def split_row(
    row: dict[str, Any],
    metadata: dict[str, Any],
    *,
    source_text: str,
) -> tuple[dict[str, Any] | None, str]:
    unit = str(row.get("adapter_work_unit") or "")
    if unit not in SUPPORTED_UNITS:
        return None, "unsupported_adapter_work_unit"
    if not metadata:
        return None, "postgres_card_metadata_missing"
    if not is_spell(metadata):
        return None, "not_instant_or_sorcery_spell"
    if ability_kind(row) != "one_shot":
        return None, "not_one_shot_spell_ability"
    if has_additional_cost(source_text):
        return None, "additional_cost_detected"
    if not str(metadata.get("oracle_text") or "").strip():
        return None, "oracle_text_missing"

    flags = spell_flags(metadata)
    classes = effect_classes(row)

    if unit == DRAW_UNIT:
        if classes != {"DrawCardSourceControllerEffect"}:
            return None, "draw_effect_class_not_pure"
        count = java_constructor_int(source_text, "DrawCardSourceControllerEffect", default=1)
        if count is None or count <= 0:
            return None, "draw_count_missing"
        effect_json = {
            "effect": "draw_cards",
            "battle_model_scope": DRAW_SCOPE,
            "count": count,
            "xmage_effect_class": "DrawCardSourceControllerEffect",
            **flags,
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_fixed_draw_spell"), "selected_exact_scope"

    if unit == DAMAGE_UNIT:
        if classes != {"DamageTargetEffect"}:
            return None, "damage_effect_class_not_pure"
        amount = java_constructor_int(source_text, "DamageTargetEffect")
        if amount is None or amount <= 0:
            return None, "damage_amount_not_fixed"
        target = damage_target_from_oracle(metadata)
        if target is None:
            return None, "damage_target_not_supported"
        effect_json = {
            "effect": "direct_damage",
            "battle_model_scope": DAMAGE_SCOPE,
            "amount": amount,
            "damage": amount,
            "target": target,
            "target_constraints": target_constraints_for(target),
            "xmage_effect_class": "DamageTargetEffect",
            **flags,
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_fixed_damage_spell"), "selected_exact_scope"

    if unit == DESTROY_UNIT:
        if classes != {"DestroyTargetEffect"}:
            return None, "destroy_effect_class_not_pure"
        target = destroy_target_from_oracle(metadata)
        if target is None:
            return None, "destroy_target_not_supported"
        effect, target_type = target
        effect_json = {
            "effect": effect,
            "battle_model_scope": DESTROY_SCOPE,
            "target": target_type,
            "target_constraints": target_constraints_for(target_type),
            "destination": "graveyard",
            "xmage_effect_class": "DestroyTargetEffect",
            **flags,
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_destroy_target_spell"), "selected_exact_scope"

    return None, "unsupported_adapter_work_unit"


def build_exact_split_report(
    queue_payload: dict[str, Any],
    *,
    card_metadata_by_id: dict[str, dict[str, Any]],
    source_reader: Callable[[dict[str, Any]], str] = default_source_reader,
    max_cards: int = 0,
) -> dict[str, Any]:
    proposals: list[dict[str, Any]] = []
    blocked_reason_counts: Counter[str] = Counter()
    blocked_samples: dict[str, list[str]] = {}
    considered = 0

    for row in queue_payload.get("queue") or []:
        if str(row.get("translation_lane") or "") != "xmage_authoritative_adapter_required":
            continue
        if str(row.get("adapter_work_unit") or "") not in SUPPORTED_UNITS:
            continue
        considered += 1
        metadata = card_metadata_by_id.get(str(row.get("card_id") or ""), {})
        proposal, reason = split_row(row, metadata, source_text=source_reader(row))
        if proposal is None:
            blocked_reason_counts[reason] += 1
            blocked_samples.setdefault(reason, [])
            if len(blocked_samples[reason]) < 12:
                blocked_samples[reason].append(str(row.get("card_name") or ""))
            continue
        proposals.append(proposal)
        if max_cards > 0 and len(proposals) >= max_cards:
            break

    family_counts = Counter(str(proposal.get("family_id") or "") for proposal in proposals)
    scope_counts = Counter(str(proposal.get("battle_model_scope") or "") for proposal in proposals)
    unit_counts = Counter(str(proposal.get("adapter_work_unit") or "") for proposal in proposals)
    return {
        "generated_at": utc_now(),
        "status": "ready",
        "mutations_performed": [],
        "source": {
            "queue_generated_at": queue_payload.get("generated_at"),
            "queue_scope": (queue_payload.get("method") or {}).get("scope"),
            "input_queue_status": queue_payload.get("status"),
        },
        "method": {
            "xmage_is_authoritative_for_resolved_sources": True,
            "promotion_boundary": "exact runtime-backed one-shot spell scopes only",
            "supported_adapter_work_units": sorted(SUPPORTED_UNITS),
            "blocked_generic_review_scopes_from_pg": True,
            "max_cards": max_cards,
        },
        "summary": {
            "considered_supported_work_unit_rows": considered,
            "proposal_count": len(proposals),
            "safe_for_batch_pg_package_count": len(proposals),
            "proposal_status_counts": {"batch_pg_candidate_after_precheck": len(proposals)},
            "family_counts": dict(sorted(family_counts.items())),
            "scope_counts": dict(sorted(scope_counts.items())),
            "adapter_work_unit_counts": dict(sorted(unit_counts.items())),
            "blocked_reason_counts": dict(sorted(blocked_reason_counts.items())),
        },
        "blocked_samples": blocked_samples,
        "proposals": proposals,
    }


def markdown_report(report: dict[str, Any]) -> str:
    lines = [
        "# XMage Authoritative Exact Scope Split",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        "- Mutations performed: `[]`",
        "",
        "## Summary",
        "",
        f"`{json.dumps(report.get('summary'), sort_keys=True)}`",
        "",
        "## Selected Proposals",
        "",
        "| Card | Family | Scope | Effect | Logical rule key |",
        "| --- | --- | --- | --- | --- |",
    ]
    for proposal in report.get("proposals", [])[:300]:
        lines.append(
            "| "
            + " | ".join(
                [
                    f"`{proposal.get('card_name')}`",
                    f"`{proposal.get('family_id')}`",
                    f"`{proposal.get('battle_model_scope')}`",
                    f"`{proposal.get('effect')}`",
                    f"`{proposal.get('logical_rule_key')}`",
                ]
            )
            + " |"
        )
    if len(report.get("proposals", [])) > 300:
        lines.append(f"| ... | ... | ... | ... | `{len(report['proposals']) - 300} more` |")
    lines.extend(["", "## Blocked Samples", ""])
    for reason, samples in sorted((report.get("blocked_samples") or {}).items()):
        lines.append(f"- `{reason}`: `{json.dumps(samples, ensure_ascii=True)}`")
    return "\n".join(lines).rstrip() + "\n"


def write_report(report: dict[str, Any], output_prefix: Path) -> tuple[Path, Path]:
    output_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = Path(f"{output_prefix}.json")
    md_path = Path(f"{output_prefix}.md")
    json_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(markdown_report(report), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--queue", required=True, help="XMage authoritative queue JSON")
    parser.add_argument("--output-prefix", help="Output path prefix")
    parser.add_argument("--max-cards", type=int, default=0)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    queue_payload = load_json(Path(args.queue))
    report = build_exact_split_report(
        queue_payload,
        card_metadata_by_id=fetch_card_metadata_by_id(),
        max_cards=args.max_cards,
    )
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    output_prefix = Path(
        args.output_prefix
        or REPORT_DIR / f"xmage_authoritative_exact_scope_split_{timestamp}"
    )
    json_path, md_path = write_report(report, output_prefix)
    print(f"json_report={json_path}")
    print(f"md_report={md_path}")
    print(f"summary={json.dumps(report['summary'], sort_keys=True)}")
    print("mutations_performed=[]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
