#!/usr/bin/env python3
"""Build read-only external reference packets for battle-rule review.

This helper does not mutate PostgreSQL, SQLite, deck lists, runtime code, or
reviewed rule files. It turns the current card-rule coherence queue into a
source-backed review packet so the next card package starts from external
engine evidence instead of from a blank manual read.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import sqlite3
import subprocess
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

import battle_rule_registry
import deck_card_battle_rule_coherence_audit as coherence
import xmage_local_rule_indexer
import xmage_to_manaloom_effect_hints


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_REPORT_DIR = SCRIPT_DIR.parent.parent / "master_optimizer_reports"
SCRYFALL_NAMED_URL = "https://api.scryfall.com/cards/named"
XMAGE_RAW_BASE = "https://raw.githubusercontent.com/magefree/mage/master/Mage.Sets/src/mage/cards"
FORGE_RAW_BASE = "https://raw.githubusercontent.com/Card-Forge/forge/master/forge-gui/res/cardsfolder"


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def slugify(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


def java_class_name(value: str) -> str:
    normalized = str(value or "").replace("'", "").replace("\u2019", "")
    words = re.findall(r"[A-Za-z0-9]+", normalized)
    return "".join(word[:1].upper() + word[1:] for word in words)


def first_face_name(card_name: str) -> str:
    return str(card_name or "").split("//", 1)[0].strip()


def xmage_class_candidates(card_name: str) -> list[str]:
    first = first_face_name(card_name)
    names = [first, card_name]
    if first.lower().startswith("the "):
        names.append(first[4:])
    candidates: list[str] = []
    for name in names:
        compact = java_class_name(name)
        if compact and compact not in candidates:
            candidates.append(compact)
    return candidates


def xmage_url_candidates(card_name: str) -> list[str]:
    urls: list[str] = []
    for class_name in xmage_class_candidates(card_name):
        bucket = class_name[:1].lower() if class_name else "_"
        urls.append(f"{XMAGE_RAW_BASE}/{bucket}/{class_name}.java")
    return urls


def forge_slug_candidates(card_name: str) -> list[str]:
    names = [card_name, first_face_name(card_name)]
    first = first_face_name(card_name)
    if first.lower().startswith("the "):
        names.append(first[4:])
    candidates: list[str] = []
    for name in names:
        slug = slugify(name)
        if slug and slug not in candidates:
            candidates.append(slug)
    return candidates


def forge_url_candidates(card_name: str) -> list[str]:
    urls: list[str] = []
    for slug in forge_slug_candidates(card_name):
        bucket = slug[:1]
        urls.append(f"{FORGE_RAW_BASE}/{bucket}/{slug}.txt")
        urls.append(f"{FORGE_RAW_BASE}/upcoming/{slug}.txt")
    return urls


def run_curl_json(url: str, *, timeout: int = 20) -> tuple[bool, Any, str]:
    ok, body, error = run_curl_text(url, timeout=timeout)
    if not ok:
        return False, None, error
    try:
        return True, json.loads(body), ""
    except json.JSONDecodeError as exc:
        return False, None, f"json_decode_error: {exc}"


def run_curl_text(url: str, *, timeout: int = 20) -> tuple[bool, str, str]:
    curl = shutil.which("curl") or "/usr/bin/curl"
    command = [
        curl,
        "-kfsSL",
        "--max-time",
        str(timeout),
        "-A",
        "ManaLoomRuleHarvester/1.0",
        url,
    ]
    try:
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout + 5,
        )
    except Exception as exc:
        return False, "", str(exc)
    if completed.returncode != 0:
        return False, "", completed.stderr.strip() or f"curl_exit={completed.returncode}"
    return True, completed.stdout, ""


def fetch_scryfall(card_name: str, *, offline: bool = False) -> dict[str, Any]:
    if offline:
        return {"status": "skipped_offline"}
    from urllib.parse import quote

    attempts = [
        ("exact", f"{SCRYFALL_NAMED_URL}?exact={quote(card_name)}"),
        ("fuzzy", f"{SCRYFALL_NAMED_URL}?fuzzy={quote(card_name)}"),
    ]
    errors: list[dict[str, str]] = []
    for mode, url in attempts:
        ok, payload, error = run_curl_json(url)
        if ok and isinstance(payload, dict) and payload.get("object") == "card":
            oracle_text = oracle_text_from_scryfall(payload)
            return {
                "status": "found",
                "mode": mode,
                "url": url,
                "name": payload.get("name"),
                "oracle_id": payload.get("oracle_id"),
                "scryfall_id": payload.get("id"),
                "type_line": payload.get("type_line"),
                "mana_cost": payload.get("mana_cost"),
                "layout": payload.get("layout"),
                "oracle_text": oracle_text,
                "oracle_hash_md5_raw": oracle_hash(oracle_text),
            }
        errors.append({"mode": mode, "url": url, "error": error or str(payload)[:200]})
    return {"status": "not_found", "errors": errors}


def oracle_text_from_scryfall(payload: dict[str, Any]) -> str:
    if isinstance(payload.get("oracle_text"), str):
        return payload["oracle_text"]
    faces = payload.get("card_faces")
    if isinstance(faces, list):
        parts = [
            str(face.get("oracle_text") or "").strip()
            for face in faces
            if isinstance(face, dict) and str(face.get("oracle_text") or "").strip()
        ]
        return "\n//\n".join(parts)
    return ""


def oracle_hash(oracle_text: str) -> str:
    return hashlib.md5(str(oracle_text or "").encode("utf-8")).hexdigest()


def first_found_text(urls: list[str], *, offline: bool = False) -> dict[str, Any]:
    if offline:
        return {"status": "skipped_offline", "attempted_urls": urls}
    errors: list[dict[str, str]] = []
    for url in urls:
        ok, text, error = run_curl_text(url)
        if ok and text.strip():
            return {
                "status": "found",
                "url": url,
                "text_excerpt": excerpt_text(text),
                "signals": implementation_signals(text),
            }
        errors.append({"url": url, "error": error})
    return {"status": "not_found", "attempted_urls": urls, "errors": errors[:5]}


def excerpt_text(text: str, *, max_lines: int = 35) -> str:
    lines = [line.rstrip() for line in str(text or "").splitlines()]
    useful = [
        line
        for line in lines
        if line.strip()
        and not line.strip().startswith("package ")
        and not line.strip().startswith("import ")
    ]
    return "\n".join(useful[:max_lines])


def implementation_signals(text: str) -> list[str]:
    lower = str(text or "").lower()
    signals: list[str] = []
    checks = [
        ("destroy_all", ["destroyall", "destroy all", "sacrificeall"]),
        ("sacrifice", ["sacrifice"]),
        ("cost_reduction", ["costreduction", "reducecost", "cost {1} less"]),
        ("counter", ["countertype", "putcounter", "counter"]),
        ("draw", ["drawcard", "draw |", "draw a card"]),
        ("mana", ["mana |", "manaability", "produced$"]),
        ("targeting", ["target", "choosecard", "targetpermanent"]),
        ("static_ability", ["staticability", "simplestaticability"]),
        ("gift", ["giftability", "gift was promised", "gift"]),
    ]
    for signal, needles in checks:
        if any(needle in lower for needle in needles):
            signals.append(signal)
    return signals


def load_report_from_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def load_report_from_sqlite(sqlite_db: Path, deck_id: int | None) -> dict[str, Any]:
    with sqlite3.connect(sqlite_db) as conn:
        conn.row_factory = sqlite3.Row
        return coherence.build_report(conn, deck_id=deck_id)


def actionable_cards(report: dict[str, Any], limit: int) -> list[dict[str, Any]]:
    cards = [
        card
        for card in report.get("cards", [])
        if card.get("severity") in {"critical", "high", "medium"}
    ]
    return cards[:limit]


def finding_codes(card: dict[str, Any]) -> set[str]:
    return {
        str(finding.get("code") or "")
        for finding in card.get("findings", [])
        if isinstance(finding, dict)
    }


def classify_gap(card: dict[str, Any], xmage: dict[str, Any], forge: dict[str, Any]) -> str:
    codes = finding_codes(card)
    external_found = xmage.get("status") == "found" or forge.get("status") == "found"
    if "missing_oracle_identity" in codes or "missing_oracle_text" in codes:
        return "identity_gap"
    if "generic_effect_without_model_scope" in codes:
        return "metadata_scope_gap"
    if "no_trusted_executable_rule" in codes or "review_only_or_needs_review_rule" in codes:
        return "review_promotion_gap_with_external_reference" if external_found else "manual_review_gap"
    if "no_active_battle_rule" in codes:
        return "rule_entry_or_runtime_gap_with_external_reference" if external_found else "rule_entry_or_runtime_gap"
    if "trusted_rule_without_oracle_hash" in codes:
        return "metadata_hash_gap"
    return "manual_review"


def local_xmage_reference(
    card_name: str,
    xmage_root: Path | None,
    class_index: dict[str, Path] | None = None,
) -> dict[str, Any]:
    if xmage_root is None:
        return {}
    return xmage_local_rule_indexer.build_index_for_card(
        card_name,
        xmage_root=xmage_root,
        class_index=class_index,
    )


def infer_effect_candidate(
    card: dict[str, Any],
    oracle_text: str,
    xmage: dict[str, Any],
    forge: dict[str, Any],
) -> dict[str, Any]:
    text = str(oracle_text or "").lower()
    effects = [str(effect) for effect in card.get("effects", []) if effect]
    signals = set(xmage.get("signals") or []) | set(forge.get("signals") or [])

    if xmage.get("status") == "found" and xmage.get("xmage_class_name"):
        hint = xmage_to_manaloom_effect_hints.build_effect_hints(xmage, oracle_text)
        primary = hint.get("primary_candidate", {}).get("effect_json", {})
        if primary.get("effect") != "external_reference_required_manual_model":
            candidate = dict(primary)
            candidate["xmage_hint_policy"] = "review_candidate_only"
            return candidate

    if "each player puts a vow counter" in text and "sacrifices the rest" in text:
        return {
            "effect": "vow_counter_each_player_sacrifice_rest",
            "battle_model_scope": "each_player_choose_creature_vow_counter_sacrifice_other_creatures_attack_restriction_v1",
        }
    if "gift" in text and "destroy all creatures" in text and "return a creature card" in text:
        return {
            "effect": "gift_destroy_all_creatures_return_own_destroyed_creature",
            "battle_model_scope": "gift_card_destroy_all_creatures_return_one_own_creature_destroyed_this_way_v1",
        }
    if "create two 4/4 white angel warrior creature tokens with flying" in text:
        return {
            "effect": "token_maker",
            "battle_model_scope": "mdfc_create_two_4_4_white_angel_warriors_non_angels_indestructible_until_next_turn_or_tapped_white_land_v1",
        }
    if "spells you cast cost" in text and "less to cast" in text:
        return {
            "effect": "static_cost_reduction",
            "battle_model_scope": "static_cost_reduction_for_matching_spells_v1",
            **xmage_to_manaloom_effect_hints.static_cost_reduction_fields_from_oracle(
                oracle_text
            ),
        }
    if "add {c}" in text and "draw a card" in text:
        return {
            "effect": "cantrip_mana_filter_artifact",
            "battle_model_scope": "artifact_tap_colorless_mana_or_pay_tap_sac_draw_one_v1",
        }
    if "choose from among the permanents" in text and "sacrifices all other nonland permanents" in text:
        return {
            "effect": "selective_nonland_sacrifice",
            "battle_model_scope": "controller_chooses_artifact_creature_enchantment_planeswalker_per_player_sacrifice_other_nonlands_v1",
        }
    if "board_wipe" in effects or "destroy_all" in signals:
        return {
            "effect": "board_wipe",
            "battle_model_scope": "external_reference_required_board_wipe_variant_v1",
        }
    if "cost_reduction" in signals:
        return {
            "effect": "static_cost_reduction",
            "battle_model_scope": "external_reference_required_static_cost_reduction_variant_v1",
            **xmage_to_manaloom_effect_hints.static_cost_reduction_fields_from_oracle(
                oracle_text
            ),
        }
    if "ramp_permanent" in effects or "mana" in signals:
        return {
            "effect": "ramp_permanent",
            "battle_model_scope": "external_reference_required_ramp_permanent_variant_v1",
        }
    if effects:
        return {
            "effect": effects[0],
            "battle_model_scope": f"external_reference_required_{slugify(effects[0])}_variant_v1",
        }
    return {
        "effect": "passive",
        "battle_model_scope": "external_reference_required_manual_model_v1",
    }


def deck_role_from_effect(effect_json: dict[str, Any]) -> dict[str, Any]:
    try:
        return battle_rule_registry.deck_role_from_effect(effect_json)
    except Exception:
        return {"category": "unknown", "effect": effect_json.get("effect", "unknown")}


def candidate_rule(card: dict[str, Any], effect_json: dict[str, Any], oracle_hash_value: str | None) -> dict[str, Any]:
    deck_role_json = deck_role_from_effect(effect_json)
    payload = {
        "card_name": card.get("card_name"),
        "effect_json": effect_json,
        "deck_role_json": deck_role_json,
        "source": "external_reference_candidate",
        "confidence": 0.0,
        "review_status": "needs_review",
        "execution_status": "review_only",
        "oracle_hash": oracle_hash_value,
        "notes": "Generated by external_card_rule_reference_harvester.py; review required before promotion.",
    }
    payload["logical_rule_key"] = battle_rule_registry.logical_rule_key(payload)
    return payload


Fetcher = Callable[[str, bool], dict[str, Any]]


def build_packet_for_card(
    card: dict[str, Any],
    *,
    offline: bool = False,
    scryfall_fetcher: Fetcher | None = None,
    xmage_root: Path | None = None,
    xmage_class_index: dict[str, Path] | None = None,
) -> dict[str, Any]:
    card_name = str(card.get("card_name") or "")
    scryfall = (scryfall_fetcher or (lambda name, off: fetch_scryfall(name, offline=off)))(card_name, offline)
    xmage_local = local_xmage_reference(card_name, xmage_root, class_index=xmage_class_index) if xmage_root else {}
    xmage = xmage_local if xmage_local else first_found_text(xmage_url_candidates(card_name), offline=offline)
    forge = first_found_text(forge_url_candidates(card_name), offline=offline)
    oracle_text = str(scryfall.get("oracle_text") or "")
    effect_json = infer_effect_candidate(card, oracle_text, xmage, forge)
    rule_candidate = candidate_rule(
        card,
        effect_json,
        str(scryfall.get("oracle_hash_md5_raw") or "") or None,
    )
    gap_bucket = classify_gap(card, xmage, forge)
    return {
        "card_name": card_name,
        "normalized_name": card.get("normalized_name"),
        "severity": card.get("severity"),
        "impact_tier": card.get("impact_tier"),
        "priority_score": card.get("priority_score"),
        "findings": card.get("findings", []),
        "existing_effects": card.get("effects", []),
        "local_rule_state": {
            "active_rule_count": card.get("active_rule_count"),
            "trusted_executable_rule_count": card.get("trusted_executable_rule_count"),
            "review_only_rule_count": card.get("review_only_rule_count"),
            "logical_rule_keys": card.get("logical_rule_keys", []),
            "oracle_cache_present": card.get("oracle_cache_present"),
            "oracle_text_present": card.get("oracle_text_present"),
            "type_line": card.get("type_line"),
        },
        "external_references": {
            "scryfall": scryfall,
            "xmage": xmage,
            "xmage_local": xmage_local or {"status": "not_requested"},
            "forge": forge,
        },
        "gap_bucket": gap_bucket,
        "candidate_rule": rule_candidate,
        "recommended_next_action": recommended_next_action(gap_bucket),
        "evidence_checklist": evidence_checklist(gap_bucket),
    }


def recommended_next_action(gap_bucket: str) -> str:
    mapping = {
        "identity_gap": "Resolve card identity/oracle text before modeling runtime behavior.",
        "metadata_scope_gap": "Add or restore battle_model_scope/oracle-specific metadata, then run focused tests.",
        "review_promotion_gap_with_external_reference": "Compare external implementation with local candidate, then promote only after focused test/replay evidence.",
        "manual_review_gap": "Manually inspect Oracle and current runtime; external references did not resolve the model.",
        "rule_entry_or_runtime_gap_with_external_reference": "Use external implementation to decide whether a rule entry is enough or runtime support is required.",
        "rule_entry_or_runtime_gap": "Create a candidate rule entry only after manual model review.",
        "metadata_hash_gap": "Restore oracle_hash from current Oracle text if the executable rule is otherwise trusted.",
    }
    return mapping.get(gap_bucket, "Manual review required before promotion.")


def evidence_checklist(gap_bucket: str) -> list[str]:
    checklist = [
        "Confirm current Oracle text and oracle_hash against PostgreSQL/Scryfall.",
        "Compare XMage/Forge/parser reference with ManaLoom compact effect model.",
        "Decide whether runtime code is required or existing executor already supports the effect.",
        "Prepare SQL as dry-run/precheck/postcheck/rollback before any apply.",
        "Add or update focused unit test for the selected effect model.",
        "Run focused replay/events and verify selected logical_rule_key.",
        "Rerun deck_card_battle_rule_coherence_audit for impacted decks.",
    ]
    if gap_bucket == "metadata_hash_gap":
        checklist.insert(1, "Verify no runtime semantic change is needed before metadata-only restore.")
    return checklist


def build_harvest_report(
    source_report: dict[str, Any],
    *,
    limit: int,
    offline: bool = False,
    xmage_root: Path | None = None,
) -> dict[str, Any]:
    xmage_class_index = xmage_local_rule_indexer.build_card_class_index(xmage_root) if xmage_root else None
    cards = [
        build_packet_for_card(
            card,
            offline=offline,
            xmage_root=xmage_root,
            xmage_class_index=xmage_class_index,
        )
        for card in actionable_cards(source_report, limit)
    ]
    return {
        "generated_at": utc_now(),
        "status": "ready_for_manual_review",
        "mutations_performed": [],
        "source_report": {
            "generated_at": source_report.get("generated_at"),
            "deck_id": source_report.get("deck_id"),
            "scope": source_report.get("scope"),
            "severity_counts": source_report.get("severity_counts"),
            "finding_counts": source_report.get("finding_counts"),
        },
        "external_sources": {
            "scryfall": SCRYFALL_NAMED_URL,
            "xmage": XMAGE_RAW_BASE,
            "xmage_local_root": str(xmage_root) if xmage_root else None,
            "forge": FORGE_RAW_BASE,
        },
        "cards": cards,
    }


def markdown_report(report: dict[str, Any]) -> str:
    lines = [
        "# External Card Rule Reference Harvest",
        "",
        f"Generated at: `{report['generated_at']}`",
        "",
        "This is a read-only reference packet. It does not mutate PostgreSQL, SQLite, decks, runtime code, or reviewed rules.",
        "",
        "## Source Audit",
        "",
        f"- Deck id: `{report['source_report'].get('deck_id')}`",
        f"- Severity counts: `{json.dumps(report['source_report'].get('severity_counts'), sort_keys=True)}`",
        f"- Finding counts: `{json.dumps(report['source_report'].get('finding_counts'), sort_keys=True)}`",
        "",
        "## Cards",
        "",
        "| Card | Severity | Impact | Gap bucket | Scryfall | XMage | Forge | Candidate effect |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for card in report.get("cards", []):
        refs = card.get("external_references", {})
        candidate = card.get("candidate_rule", {}).get("effect_json", {})
        lines.append(
            "| "
            + " | ".join(
                [
                    f"`{card.get('card_name')}`",
                    f"`{card.get('severity')}`",
                    f"`{card.get('impact_tier')}`",
                    f"`{card.get('gap_bucket')}`",
                    f"`{refs.get('scryfall', {}).get('status')}`",
                    f"`{refs.get('xmage', {}).get('status')}`",
                    f"`{refs.get('forge', {}).get('status')}`",
                    f"`{candidate.get('effect')}`",
                ]
            )
            + " |"
        )
    lines.extend(["", "## Review Packets", ""])
    for card in report.get("cards", []):
        lines.extend(
            [
                f"### {card.get('card_name')}",
                "",
                f"- Gap bucket: `{card.get('gap_bucket')}`",
                f"- Findings: `{', '.join(f.get('code', '') for f in card.get('findings', []))}`",
                f"- Recommended next action: {card.get('recommended_next_action')}",
                f"- Candidate logical rule key: `{card.get('candidate_rule', {}).get('logical_rule_key')}`",
                f"- Candidate oracle hash: `{card.get('candidate_rule', {}).get('oracle_hash')}`",
                f"- Candidate effect_json: `{json.dumps(card.get('candidate_rule', {}).get('effect_json'), sort_keys=True)}`",
                "",
                "External reference status:",
                "",
                f"- Scryfall: `{card.get('external_references', {}).get('scryfall', {}).get('status')}`",
                f"- XMage: `{card.get('external_references', {}).get('xmage', {}).get('status')}`",
                f"- Forge: `{card.get('external_references', {}).get('forge', {}).get('status')}`",
                "",
                "Evidence checklist:",
                "",
            ]
        )
        lines.extend(f"- {item}" for item in card.get("evidence_checklist", []))
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def write_report(report: dict[str, Any], output_json: Path, output_md: Path) -> None:
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    output_md.write_text(markdown_report(report), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sqlite-db", default=str(DEFAULT_DB))
    parser.add_argument("--deck-id", type=int, help="Build a fresh coherence audit for this deck id.")
    parser.add_argument("--from-report", help="Use an existing deck_card_battle_rule_coherence_audit JSON report.")
    parser.add_argument("--xmage-root", help="Prefer a local XMage checkout before remote XMage URL fallback.")
    parser.add_argument("--limit", type=int, default=5)
    parser.add_argument("--offline", action="store_true", help="Skip network fetches and emit local candidates only.")
    parser.add_argument("--output-json")
    parser.add_argument("--output-md")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.from_report:
        source_report = load_report_from_json(Path(args.from_report))
    else:
        source_report = load_report_from_sqlite(Path(args.sqlite_db), args.deck_id)
    xmage_root = Path(args.xmage_root) if args.xmage_root else None
    report = build_harvest_report(
        source_report,
        limit=args.limit,
        offline=args.offline,
        xmage_root=xmage_root,
    )
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    deck_part = f"_deck{source_report.get('deck_id')}" if source_report.get("deck_id") is not None else ""
    stem = f"external_card_rule_reference_harvest{deck_part}_{timestamp}"
    output_json = Path(args.output_json or DEFAULT_REPORT_DIR / f"{stem}.json")
    output_md = Path(args.output_md or DEFAULT_REPORT_DIR / f"{stem}.md")
    write_report(report, output_json, output_md)
    print(f"json_report={output_json}")
    print(f"md_report={output_md}")
    print(f"cards={len(report['cards'])}")
    print("mutations_performed=[]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
