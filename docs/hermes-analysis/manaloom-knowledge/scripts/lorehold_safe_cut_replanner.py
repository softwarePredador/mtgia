#!/usr/bin/env python3
"""Build safe-cut follow-up package manifests from Lorehold evidence.

This helper is intentionally read-only. It looks for positive package evidence
blocked by protected cuts, then proposes alternate cuts that are present in the
current champion shell, explicitly marked as flexible by the cut-safety report,
and not already rejected at either the exact signature or cut-slot level.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping

import lorehold_synergy_package_gate as package_gate
from master_optimizer_common import normalize_name


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_LEDGER = REPORT_DIR / "lorehold_learning_evidence_ledger_20260628_v6.json"
DEFAULT_REGISTRY = REPORT_DIR / "lorehold_candidate_hypothesis_registry_20260626.json"
DEFAULT_CUT_SAFETY = REPORT_DIR / "lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json"
DEFAULT_SOURCE_DB = package_gate.DEFAULT_SOURCE_DB
DEFAULT_BASELINE_DECK_ID = 607

FAMILY_LANE_COMPATIBILITY = {
    "graveyard_recast": {"early_mana", "draw", "spell_velocity", "hand_filter"},
    "topdeck_freecast": {"early_mana", "draw", "topdeck_setup", "big_spell_value"},
    "topdeck_setup": {"early_mana", "draw", "topdeck_setup"},
    "pressure_absorber": {"protection", "removal", "pressure_reset"},
    "targeted_commander_protection": {"protection", "removal", "pressure_reset"},
    "spell_protection": {"protection", "removal", "pressure_reset"},
    "spellchain_mana": {"early_mana", "spell_velocity"},
    "fast_mana": {"early_mana"},
    "payoff_challenge": {"wincon", "big_spell_value", "pressure_reset"},
    "cost_reduce_copy": {"early_mana", "spell_velocity"},
    "spell_copy": {"early_mana", "draw", "spell_velocity"},
    "spell_copy_recursion": {"early_mana", "draw", "spell_velocity"},
}

NEVER_CUT_LANES = {"mana_base", "commander"}
SAFE_CUT_DECISIONS = {"engine_flex", "manual_review", "support_flex"}
EARLY_MANA_REPLACEMENT_FAMILIES = {"cost_reduce_copy", "fast_mana", "spellchain_mana"}
PROTECTION_LANES = {"protection", "pressure_absorber_or_protection"}
STRATEGY_LANE_MAP = {
    "commander_engine": "commander",
    "early_mana": "early_mana",
    "finisher_or_big_spell": "big_spell_value",
    "graveyard_recursion": "graveyard_recursion",
    "hand_filter": "hand_filter",
    "interaction": "removal",
    "mana_base": "mana_base",
    "pressure_absorber_or_protection": "protection",
    "selection": "selection",
    "spell_density": "spell_velocity",
    "topdeck_miracle_setup": "topdeck_setup",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def slug(value: object) -> str:
    return normalize_name(str(value or "")).replace(" ", "_").replace("/", "_").replace("'", "")


def load_cut_safety_rows(path: Path) -> dict[str, dict[str, Any]]:
    payload = read_json(path)
    manifest = payload.get("cut_safety_manifest") or {}
    rows: dict[str, dict[str, Any]] = {}
    for section in ("cuts", "untested_flex_pool"):
        for row in manifest.get(section) or []:
            if isinstance(row, dict) and row.get("card_name"):
                rows[normalize_name(row["card_name"])] = {**row, "source_section": section}
    return rows


def load_strategy_card_rows(path: Path) -> dict[str, dict[str, Any]]:
    payload = read_json(path)
    rows = {}
    for row in (payload.get("card_decision_manifest") or {}).get("cards") or []:
        if isinstance(row, dict) and row.get("card_name"):
            rows[normalize_name(row["card_name"])] = row
    return rows


def load_registry_protected(path: Path) -> set[str]:
    payload = read_json(path)
    return {
        normalize_name(str(card))
        for card in payload.get("protected_cards_until_same_function_replacement_wins") or []
        if str(card).strip()
    }


def protected_cut_names(cut_safety_rows: Mapping[str, Mapping[str, Any]], registry_protected: set[str]) -> set[str]:
    names = set(registry_protected)
    protected_statuses = package_gate.CUT_SAFETY_PROTECTED_STATUSES
    for key, row in cut_safety_rows.items():
        if row.get("status") in protected_statuses:
            names.add(key)
    return names


def infer_lane(row: Mapping[str, Any], cut_safety_rows: Mapping[str, Mapping[str, Any]]) -> str:
    key = normalize_name(str(row.get("card_name") or ""))
    safety = cut_safety_rows.get(key) or {}
    lane = safety.get("current_lane") or safety.get("package_lane")
    if lane:
        return STRATEGY_LANE_MAP.get(str(lane), str(lane))
    strategy_lane = row.get("strategy_package_lane")
    if strategy_lane:
        return STRATEGY_LANE_MAP.get(str(strategy_lane), str(strategy_lane))
    type_line = str(row.get("type_line") or "").lower()
    tag = normalize_name(str(row.get("functional_tag") or ""))
    cmc = float(row.get("cmc") or 0.0)
    if bool(row.get("is_commander")):
        return "commander"
    if "land" in type_line:
        return "mana_base"
    if "ramp" in tag or "treasure" in tag:
        return "early_mana" if cmc <= 4 else "spell_velocity"
    if "draw" in tag:
        return "draw"
    if "protection" in tag:
        return "protection"
    if "removal" in tag:
        return "removal"
    if "board wipe" in tag or "board_wipe" in tag or "wipe" in tag:
        return "pressure_reset"
    if "wincon" in tag or "token" in tag:
        return "wincon"
    if "sorcery" in type_line or "instant" in type_line:
        return "spell_velocity"
    return "misc"


def is_miracle_core_cut(row: Mapping[str, Any]) -> bool:
    type_line = str(row.get("type_line") or "")
    tag = normalize_name(str(row.get("functional_tag") or ""))
    cmc = float(row.get("cmc") or 0.0)
    oracle_text = str(row.get("oracle_text") or "").lower()
    strategy_role = normalize_name(str(row.get("strategy_effective_role") or ""))
    strategy_tags = {normalize_name(str(tag)) for tag in row.get("strategy_tags") or []}
    if tag in {"board wipe", "board_wipe", "wincon"}:
        return True
    if strategy_role in {"board wipe", "board_wipe", "wincon"}:
        return True
    if strategy_tags & {"board wipe", "board_wipe", "wincon"}:
        return True
    if ("Instant" in type_line or "Sorcery" in type_line) and cmc >= 4:
        return True
    if "instant or sorcery" in oracle_text and tag in {"draw", "engine", "wincon"}:
        return True
    return False


def cut_safety_decision(row: Mapping[str, Any]) -> str:
    return str(row.get("decision") or row.get("current_decision") or "").strip()


def deck_cut_pool(
    source_db: Path,
    deck_id: int,
    cut_safety_rows: Mapping[str, Mapping[str, Any]],
    strategy_card_rows: Mapping[str, Mapping[str, Any]],
) -> list[dict[str, Any]]:
    conn = sqlite3.connect(source_db)
    conn.row_factory = sqlite3.Row
    try:
        columns = {row[1] for row in conn.execute("PRAGMA table_info(deck_cards)")}
        oracle_expr = "oracle_text" if "oracle_text" in columns else "'' AS oracle_text"
        tags_expr = "functional_tags_json" if "functional_tags_json" in columns else "'[]' AS functional_tags_json"
        rows = conn.execute(
            f"""
            SELECT card_name, quantity, functional_tag, cmc, type_line, is_commander,
                   {oracle_expr}, {tags_expr}
            FROM deck_cards
            WHERE deck_id=?
            ORDER BY is_commander DESC, card_name
            """,
            (deck_id,),
        ).fetchall()
    finally:
        conn.close()
    pool = []
    for raw in rows:
        row = dict(raw)
        row["normalized_name"] = normalize_name(row["card_name"])
        strategy = strategy_card_rows.get(row["normalized_name"]) or {}
        row["strategy_decision"] = strategy.get("decision")
        row["strategy_package_lane"] = strategy.get("package_lane")
        row["strategy_effective_role"] = strategy.get("effective_role")
        row["strategy_tags"] = strategy.get("tags") or []
        row["lane"] = infer_lane(row, cut_safety_rows)
        pool.append(row)
    return pool


def source_db_has_cards(source_db: Path, names: Iterable[str]) -> dict[str, bool]:
    conn = sqlite3.connect(source_db)
    conn.row_factory = sqlite3.Row
    out: dict[str, bool] = {}
    try:
        for name in names:
            key = normalize_name(name)
            row = conn.execute(
                "SELECT 1 FROM card_oracle_cache WHERE normalized_name=? LIMIT 1",
                (key,),
            ).fetchone()
            out[key] = row is not None
    finally:
        conn.close()
    return out


def package_family(group: Mapping[str, Any]) -> str:
    families = group.get("families") or []
    if families:
        return str(families[0])
    return "misc"


def source_groups(ledger: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for group in ledger.get("package_groups") or []:
        if group.get("classification") != "preflight_blocked_protected_cut":
            continue
        if float(group.get("best_delta_pp") or 0.0) <= 0:
            continue
        if int(group.get("critical_regression_count") or 0) > 0:
            continue
        adds = [str(card) for card in group.get("latest_adds") or [] if str(card).strip()]
        cuts = [str(card) for card in group.get("latest_cuts") or [] if str(card).strip()]
        if not adds or not cuts:
            continue
        rows.append({**group, "family": package_family(group), "adds": adds, "cuts": cuts})
    rows.sort(
        key=lambda row: (
            -float(row.get("best_delta_pp") or 0.0),
            -int(row.get("critical_improvement_count") or 0),
            str(row.get("package_key") or ""),
        )
    )
    return rows


def prior_signature_blocked(
    *,
    adds: list[str],
    cuts: list[str],
    prior_results: Mapping[str, Any],
) -> dict[str, Any] | None:
    signature = package_gate.package_signature_key(adds, cuts)
    matches = (prior_results.get("by_signature") or {}).get(signature) or []
    for match in matches:
        if str(match.get("decision") or "") in package_gate.PRIOR_PACKAGE_BLOCKED_DECISIONS:
            return match
    return None


def cut_rejection_lookup(
    ledger: Mapping[str, Any],
    prior_results: Mapping[str, Any],
) -> dict[str, list[dict[str, Any]]]:
    rejected: dict[str, list[dict[str, Any]]] = {}
    for matches in (prior_results.get("by_signature") or {}).values():
        for match in matches:
            if str(match.get("decision") or "") not in package_gate.PRIOR_PACKAGE_BLOCKED_DECISIONS:
                continue
            for cut in match.get("cuts") or []:
                rejected.setdefault(normalize_name(str(cut)), []).append(
                    {
                        "package_key": match.get("package_key"),
                        "source_report": match.get("source_report"),
                        "decision": match.get("decision"),
                        "delta_pp": match.get("delta_pp"),
                    }
                )
    for group in ledger.get("package_groups") or []:
        if group.get("classification") != "latest_rejected":
            continue
        for cut in group.get("latest_cuts") or []:
            rejected.setdefault(normalize_name(str(cut)), []).append(
                {
                    "package_key": group.get("package_key"),
                    "source_report": group.get("latest_source_file"),
                    "decision": group.get("latest_decision"),
                    "delta_pp": group.get("latest_delta_pp"),
                }
            )
    return rejected


def build_prior_results(registry: Path, prior_reports: list[Path]) -> dict[str, Any]:
    prior = package_gate.load_prior_package_results(prior_reports)
    registry_prior = package_gate.load_registry_prior_results(registry)
    return package_gate.merge_registry_prior_results(prior, registry_prior)


def evaluate_followups(
    *,
    ledger: Mapping[str, Any],
    cut_pool: list[dict[str, Any]],
    source_db: Path,
    cut_safety_rows: Mapping[str, Mapping[str, Any]],
    protected_names: set[str],
    prior_results: Mapping[str, Any],
    cut_rejections: Mapping[str, list[dict[str, Any]]],
    max_per_source: int,
) -> list[dict[str, Any]]:
    add_names = sorted({card for group in source_groups(ledger) for card in group["adds"]})
    add_availability = source_db_has_cards(source_db, add_names)
    rows: list[dict[str, Any]] = []
    deck_names = {row["normalized_name"] for row in cut_pool}
    for group in source_groups(ledger):
        family = str(group["family"])
        compatible = FAMILY_LANE_COMPATIBILITY.get(family, set())
        source_cut_keys = {normalize_name(card) for card in group["cuts"]}
        generated_for_source = 0
        for cut in cut_pool:
            cut_key = cut["normalized_name"]
            blockers: list[str] = []
            if cut_key in source_cut_keys:
                blockers.append("same_as_blocked_source_cut")
            if cut_key in protected_names:
                blockers.append("protected_cut")
            if cut["lane"] in NEVER_CUT_LANES:
                blockers.append("never_cut_lane")
            if compatible and cut["lane"] not in compatible:
                blockers.append("incompatible_lane")
            missing_adds = [
                add
                for add in group["adds"]
                if not add_availability.get(normalize_name(add), False)
            ]
            if missing_adds:
                blockers.append("missing_add_oracle")
            already_present_adds = [
                add
                for add in group["adds"]
            if normalize_name(add) in deck_names
            ]
            if already_present_adds:
                blockers.append("add_already_in_deck")
            cut_safety = cut_safety_rows.get(cut_key)
            if not cut_safety:
                blockers.append("missing_cut_safety_row")
            else:
                decision = cut_safety_decision(cut_safety)
                if decision not in SAFE_CUT_DECISIONS:
                    blockers.append("cut_not_flex_decision")
            strategy_decision = str(cut.get("strategy_decision") or "").strip()
            if strategy_decision and strategy_decision not in SAFE_CUT_DECISIONS:
                blockers.append("cut_not_flex_decision")
            strategy_role = normalize_name(str(cut.get("strategy_effective_role") or ""))
            strategy_tags = {normalize_name(str(tag)) for tag in cut.get("strategy_tags") or []}
            if (
                cut["lane"] in PROTECTION_LANES
                or "protection" in normalize_name(str(cut.get("functional_tag") or ""))
                or strategy_role == "protection"
                or "protection" in strategy_tags
            ):
                blockers.append("cut_is_protection_shell")
            if is_miracle_core_cut(cut):
                blockers.append("cut_is_miracle_core_big_spell")
            if cut["lane"] == "early_mana" and family not in EARLY_MANA_REPLACEMENT_FAMILIES:
                blockers.append("cut_is_early_mana_floor_support")
            prior_block = prior_signature_blocked(
                adds=group["adds"],
                cuts=[str(cut["card_name"])],
                prior_results=prior_results,
            )
            if prior_block:
                blockers.append("prior_rejected_signature")
            rejected_cut_evidence = list(cut_rejections.get(cut_key) or [])
            if rejected_cut_evidence:
                blockers.append("prior_rejected_cut")
            blockers = sorted(set(blockers))
            status = "manifest_ready" if not blockers else "blocked"
            package_key = f"{slug(group['package_key'])}_safe_cut_{slug(cut['card_name'])}"
            row = {
                "package_key": package_key,
                "status": status,
                "source_package_key": group["package_key"],
                "source_best_delta_pp": group.get("best_delta_pp"),
                "source_critical_matchups": {
                    "improved": group.get("critical_improvement_count") or 0,
                    "regressed": group.get("critical_regression_count") or 0,
                    "tied": group.get("critical_tie_count") or 0,
                },
                "family": family,
                "adds": group["adds"],
                "cuts": [str(cut["card_name"])],
                "cut_lane": cut["lane"],
                "cut_functional_tag": cut.get("functional_tag"),
                "cut_safety": cut_safety,
                "hypothesis": (
                    f"{', '.join(group['adds'])} had positive signal in "
                    f"`{group['package_key']}`, but its tested cut is protected. "
                    f"This follow-up preserves protected cards and tests the same "
                    f"family over `{cut['card_name']}` ({cut['lane']})."
                ),
                "blockers": blockers,
                "prior_rejected_signature": prior_block,
                "prior_rejected_cut_evidence": rejected_cut_evidence[:5],
            }
            rows.append(row)
            if status == "manifest_ready":
                generated_for_source += 1
                if generated_for_source >= max_per_source:
                    break
    rows.sort(
        key=lambda row: (
            0 if row["status"] == "manifest_ready" else 1,
            -float(row.get("source_best_delta_pp") or 0.0),
            -int((row.get("source_critical_matchups") or {}).get("improved") or 0),
            str(row.get("package_key")),
        )
    )
    return rows


def build_report(
    *,
    ledger_path: Path,
    registry_path: Path,
    cut_safety_path: Path,
    source_db: Path,
    deck_id: int,
    prior_reports: list[Path],
    max_per_source: int,
    max_manifest_packages: int,
) -> dict[str, Any]:
    ledger = read_json(ledger_path)
    cut_safety_rows = load_cut_safety_rows(cut_safety_path)
    strategy_card_rows = load_strategy_card_rows(cut_safety_path)
    registry_protected = load_registry_protected(registry_path)
    protected_names = protected_cut_names(cut_safety_rows, registry_protected)
    cut_pool = deck_cut_pool(source_db, deck_id, cut_safety_rows, strategy_card_rows)
    prior_results = build_prior_results(registry_path, prior_reports)
    cut_rejections = cut_rejection_lookup(ledger, prior_results)
    followups = evaluate_followups(
        ledger=ledger,
        cut_pool=cut_pool,
        source_db=source_db,
        cut_safety_rows=cut_safety_rows,
        protected_names=protected_names,
        prior_results=prior_results,
        cut_rejections=cut_rejections,
        max_per_source=max_per_source,
    )
    ready = [row for row in followups if row["status"] == "manifest_ready"]
    blocked_counts = Counter(blocker for row in followups for blocker in row.get("blockers") or [])
    manifest_rows = ready[:max_manifest_packages]
    manifest = {
        "generated_at": utc_now(),
        "postgres_writes": False,
        "source_db_mutated": False,
        "purpose": "Safe-cut follow-up packages generated from ledger evidence.",
        "source_ledger": str(ledger_path),
        "packages": [
            {
                "package_key": row["package_key"],
                "family": row["family"],
                "hypothesis": row["hypothesis"],
                "adds": row["adds"],
                "cuts": row["cuts"],
                "allow_miracle_core_cuts": True,
            }
            for row in manifest_rows
        ],
    }
    return {
        "generated_at": utc_now(),
        "postgres_writes": False,
        "source_db_mutated": False,
        "ledger": str(ledger_path),
        "registry": str(registry_path),
        "cut_safety": str(cut_safety_path),
        "source_db": str(source_db),
        "deck_id": deck_id,
        "summary": {
            "source_group_count": len(source_groups(ledger)),
            "cut_pool_count": len(cut_pool),
            "followup_count": len(followups),
            "manifest_ready_count": len(ready),
            "manifest_package_count": len(manifest_rows),
            "blocked_reason_counts": dict(sorted(blocked_counts.items())),
        },
        "manifest": manifest,
        "manifest_ready_packages": manifest_rows,
        "followups": followups[:200],
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Safe-Cut Replanner",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- postgres_writes: `{payload['postgres_writes']}`",
        f"- source_db_mutated: `{payload['source_db_mutated']}`",
        f"- ledger: `{payload['ledger']}`",
        f"- source_group_count: `{summary['source_group_count']}`",
        f"- cut_pool_count: `{summary['cut_pool_count']}`",
        f"- manifest_ready_count: `{summary['manifest_ready_count']}`",
        f"- manifest_package_count: `{summary['manifest_package_count']}`",
        f"- blocked_reason_counts: `{json.dumps(summary['blocked_reason_counts'], sort_keys=True)}`",
        "",
        "## Interpretation",
        "",
    ]
    if int(summary["manifest_package_count"] or 0) == 0:
        lines.extend(
            [
                "- No follow-up package should be gated from this report.",
                "- Every alternate cut was blocked by cut-safety, structural role, lane compatibility, or prior rejected evidence.",
                "- Next action is to expand the cut-safety evidence or run a manual cut review before spending battle-gate time.",
                "",
            ]
        )
    else:
        lines.extend(
            [
                "- The manifest contains only cuts that passed explicit cut-safety, structural role, lane compatibility, and prior-evidence checks.",
                "",
            ]
        )
    lines.extend(
        [
        "## Manifest Ready Packages",
        "",
        ]
    )
    ready = payload.get("manifest_ready_packages") or []
    if not ready:
        lines.append("- None.")
    else:
        lines.extend(["| Package | Source | Adds | Cut | Source Best | Critical +/-/0 |", "| --- | --- | --- | --- | ---: | --- |"])
        for row in ready:
            critical = row.get("source_critical_matchups") or {}
            lines.append(
                "| {package} | `{source}` | {adds} | {cuts} | {best:+.2f} | {pos}/{neg}/{tie} |".format(
                    package=row["package_key"],
                    source=row["source_package_key"],
                    adds=", ".join(f"`{card}`" for card in row["adds"]),
                    cuts=", ".join(f"`{card}`" for card in row["cuts"]),
                    best=float(row.get("source_best_delta_pp") or 0.0),
                    pos=critical.get("improved") or 0,
                    neg=critical.get("regressed") or 0,
                    tie=critical.get("tied") or 0,
                )
            )
    lines.extend(["", "## Top Blocked Followups", ""])
    blocked = [row for row in payload.get("followups") or [] if row.get("status") != "manifest_ready"]
    if not blocked:
        lines.append("- None.")
    else:
        lines.extend(["| Package | Source | Cut | Blockers |", "| --- | --- | --- | --- |"])
        for row in blocked[:20]:
            lines.append(
                f"| {row['package_key']} | `{row['source_package_key']}` | "
                f"`{', '.join(row['cuts'])}` | `{', '.join(row.get('blockers') or [])}` |"
            )
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], stem: str) -> tuple[Path, Path, Path]:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{stem}.json"
    md_path = REPORT_DIR / f"{stem}.md"
    manifest_path = REPORT_DIR / f"{stem}_packages.json"
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    manifest_path.write_text(
        json.dumps(payload["manifest"], indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return json_path, md_path, manifest_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ledger", type=Path, default=DEFAULT_LEDGER)
    parser.add_argument("--registry", type=Path, default=DEFAULT_REGISTRY)
    parser.add_argument("--cut-safety", type=Path, default=DEFAULT_CUT_SAFETY)
    parser.add_argument("--source-db", type=Path, default=DEFAULT_SOURCE_DB)
    parser.add_argument("--deck-id", type=int, default=DEFAULT_BASELINE_DECK_ID)
    parser.add_argument("--prior-package-report", type=Path, action="append")
    parser.add_argument("--max-per-source", type=int, default=2)
    parser.add_argument("--max-manifest-packages", type=int, default=8)
    parser.add_argument("--stem", default="lorehold_safe_cut_replanner_20260628_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    prior_reports = [
        path.resolve()
        for path in (args.prior_package_report or list(package_gate.DEFAULT_PRIOR_PACKAGE_REPORTS))
    ]
    payload = build_report(
        ledger_path=args.ledger.resolve(),
        registry_path=args.registry.resolve(),
        cut_safety_path=args.cut_safety.resolve(),
        source_db=args.source_db.resolve(),
        deck_id=args.deck_id,
        prior_reports=prior_reports,
        max_per_source=args.max_per_source,
        max_manifest_packages=args.max_manifest_packages,
    )
    json_path, md_path, manifest_path = write_outputs(payload, args.stem)
    print(
        json.dumps(
            {
                "status": "ready",
                "json": str(json_path),
                "markdown": str(md_path),
                "manifest": str(manifest_path),
                "manifest_ready_count": payload["summary"]["manifest_ready_count"],
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
