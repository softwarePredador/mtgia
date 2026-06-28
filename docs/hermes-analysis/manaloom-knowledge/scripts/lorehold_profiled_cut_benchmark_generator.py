#!/usr/bin/env python3
"""Generate same-lane benchmark packages for profiled Lorehold cut slots.

This helper is read-only. It consumes the manual cut review that already
profiled current champion cut slots, mines Lorehold variant decks for active
same-lane replacement candidates, and writes a package manifest that can be
passed to ``lorehold_synergy_package_gate.py --package-file``.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

import lorehold_synergy_package_gate as package_gate


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = (
    REPORT_DIR
    / "lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob"
    / "knowledge_candidate.db"
)
DEFAULT_MANUAL_REVIEW = (
    REPORT_DIR / "lorehold_manual_cut_review_20260628_v2_cut_exposure_profiled.json"
)
DEFAULT_VARIANT_DECK_IDS = tuple(range(608, 617))
ACTIVE_EXECUTION_STATUSES = {"active", "auto", "reviewed", "verified"}
ACTIVE_REVIEW_STATUSES = {"active", "needs_review", "reviewed", "verified"}
PROFILED_CUT_STATUSES = {
    "measured_cut_exposure_needs_same_lane_benchmark",
    "same_lane_only",
}
SUPPORTED_CUT_ROLES = {"spot_removal"}
COLOR_HATE_PATTERNS = tuple(
    f"{prefix} {color}"
    for prefix in ("target", "destroy target", "counter target")
    for color in ("white", "blue", "black", "red", "green")
)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def slug(value: object) -> str:
    return normalize_key(value).replace(" ", "_")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def json_list(value: object) -> list[Any]:
    if isinstance(value, list):
        return value
    if value in (None, ""):
        return []
    try:
        decoded = json.loads(str(value))
    except Exception:
        return []
    return decoded if isinstance(decoded, list) else []


def card_signature(cards: Iterable[str]) -> tuple[str, ...]:
    return tuple(sorted(normalize_key(card) for card in cards if normalize_key(card)))


def package_key(candidate: str, cut: str) -> str:
    return f"{slug(candidate)}_interaction_benchmark_cut_{slug(cut)}"


def rule_scope_tokens(rule: dict[str, Any]) -> set[str]:
    effect_text = " ".join((rule.get("effects") or {}).keys()).lower()
    scope_text = " ".join((rule.get("battle_model_scopes") or {}).keys()).lower()
    text = f"{effect_text} {scope_text}"
    tokens: set[str] = set()
    for token in (
        "artifact",
        "creature",
        "enchantment",
        "planeswalker",
        "damage",
        "destroy",
        "exile",
    ):
        if token in text:
            tokens.add(token)
    for token in ("land", "permanent"):
        if token in scope_text:
            tokens.add(token)
    return tokens


def removal_role_from_rule(rule: dict[str, Any]) -> str:
    effects = set((rule.get("effects") or {}).keys())
    scopes = set((rule.get("battle_model_scopes") or {}).keys())
    text = " ".join(sorted(effects | scopes)).lower()
    if (
        any(effect.startswith("remove") or "removal" in effect for effect in effects)
        or "destroy_target" in text
        or "exile_target" in text
        or "damage_any_target" in text
        or "targeted_damage" in text
    ):
        return "spot_removal"
    return "unknown"


def load_rule_summaries(conn: sqlite3.Connection, names: Iterable[str]) -> dict[str, dict[str, Any]]:
    wanted = {normalize_key(name): str(name) for name in names if str(name).strip()}
    out: dict[str, dict[str, Any]] = {
        key: {
            "card_name": name,
            "rule_count": 0,
            "active_rule_count": 0,
            "effects": Counter(),
            "battle_model_scopes": Counter(),
            "execution_statuses": Counter(),
            "review_statuses": Counter(),
        }
        for key, name in wanted.items()
    }
    if not out:
        return out
    rows = conn.execute(
        """
        SELECT card_name, normalized_name, execution_status, review_status, effect_json
        FROM battle_card_rules
        ORDER BY card_name
        """
    ).fetchall()
    for row in rows:
        forms = {normalize_key(row["card_name"]), normalize_key(row["normalized_name"])}
        key = next((item for item in forms if item in wanted), "")
        if not key:
            continue
        summary = out[key]
        execution_status = str(row["execution_status"] or "")
        review_status = str(row["review_status"] or "")
        summary["rule_count"] += 1
        summary["execution_statuses"][execution_status] += 1
        summary["review_statuses"][review_status] += 1
        if execution_status in ACTIVE_EXECUTION_STATUSES and review_status in ACTIVE_REVIEW_STATUSES:
            summary["active_rule_count"] += 1
        try:
            effect_json = json.loads(row["effect_json"] or "{}")
        except Exception:
            effect_json = {}
        if isinstance(effect_json, dict):
            if effect_json.get("effect"):
                summary["effects"][str(effect_json["effect"])] += 1
            if effect_json.get("battle_model_scope"):
                summary["battle_model_scopes"][str(effect_json["battle_model_scope"])] += 1
    finalized: dict[str, dict[str, Any]] = {}
    for key, value in out.items():
        finalized[key] = {
            **value,
            "effects": dict(sorted(value["effects"].items())),
            "battle_model_scopes": dict(sorted(value["battle_model_scopes"].items())),
            "execution_statuses": dict(sorted(value["execution_statuses"].items())),
            "review_statuses": dict(sorted(value["review_statuses"].items())),
        }
    return finalized


def current_deck_names(conn: sqlite3.Connection, deck_id: int) -> set[str]:
    return {
        normalize_key(row["card_name"])
        for row in conn.execute("SELECT card_name FROM deck_cards WHERE deck_id=?", (deck_id,))
    }


def current_deck_metadata(conn: sqlite3.Connection, deck_id: int) -> dict[str, dict[str, Any]]:
    rows = conn.execute(
        """
        SELECT card_name, functional_tag, functional_tags_json, cmc, type_line, oracle_text
        FROM deck_cards
        WHERE deck_id=?
        ORDER BY card_name
        """,
        (deck_id,),
    ).fetchall()
    return {
        normalize_key(row["card_name"]): {
            "card_name": row["card_name"],
            "functional_tag": row["functional_tag"],
            "functional_tags": json_list(row["functional_tags_json"]),
            "cmc": float(row["cmc"] or 0),
            "type_line": row["type_line"],
            "oracle_text": row["oracle_text"],
        }
        for row in rows
    }


def load_variant_candidates(
    conn: sqlite3.Connection,
    *,
    current_names: set[str],
    variant_deck_ids: Iterable[int],
) -> dict[str, dict[str, Any]]:
    deck_ids = list(variant_deck_ids)
    placeholders = ",".join("?" for _ in deck_ids)
    rows = conn.execute(
        f"""
        SELECT card_name, deck_id, functional_tag, functional_tags_json, cmc, type_line, oracle_text
        FROM deck_cards
        WHERE deck_id IN ({placeholders})
        ORDER BY card_name, deck_id
        """,
        deck_ids,
    ).fetchall()
    candidates: dict[str, dict[str, Any]] = {}
    for row in rows:
        key = normalize_key(row["card_name"])
        if key in current_names:
            continue
        entry = candidates.setdefault(
            key,
            {
                "card_name": row["card_name"],
                "deck_ids": set(),
                "functional_tag": row["functional_tag"],
                "functional_tags": json_list(row["functional_tags_json"]),
                "cmc": float(row["cmc"] or 0),
                "type_line": row["type_line"],
                "oracle_text": row["oracle_text"],
            },
        )
        entry["deck_ids"].add(int(row["deck_id"]))
    finalized = {}
    for key, value in candidates.items():
        deck_ids = sorted(value["deck_ids"])
        finalized[key] = {
            **value,
            "deck_ids": deck_ids,
            "deck_count": len(deck_ids),
        }
    return finalized


def profiled_cut_rows(manual_review: dict[str, Any]) -> list[dict[str, Any]]:
    rows = []
    expansion = manual_review.get("cut_evidence_expansion") or {}
    for row in expansion.get("top_same_lane_candidates") or []:
        if row.get("status") not in PROFILED_CUT_STATUSES:
            continue
        rows.append(row)
    return rows


def exact_prior_rejects(prior_results: dict[str, Any]) -> set[tuple[str, str]]:
    rejected = set()
    for rows in (prior_results.get("by_signature") or {}).values():
        for row in rows:
            if row.get("decision") not in package_gate.PRIOR_PACKAGE_BLOCKED_DECISIONS:
                continue
            adds = card_signature(row.get("adds") or [])
            cuts = card_signature(row.get("cuts") or [])
            if len(adds) == 1 and len(cuts) == 1:
                rejected.add((adds[0], cuts[0]))
    return rejected


def candidate_role(candidate: dict[str, Any], rule: dict[str, Any]) -> str:
    if str(candidate.get("functional_tag") or "") == "removal":
        return "spot_removal"
    if "removal" in {str(tag) for tag in candidate.get("functional_tags") or []}:
        return "spot_removal"
    return removal_role_from_rule(rule)


def compatible_removal_scope(cut_rule: dict[str, Any], candidate_rule: dict[str, Any]) -> bool:
    cut_tokens = rule_scope_tokens(cut_rule)
    candidate_tokens = rule_scope_tokens(candidate_rule)
    if not cut_tokens or not candidate_tokens:
        return False
    if "permanent" in cut_tokens:
        return "permanent" in candidate_tokens
    if "creature" in cut_tokens and candidate_tokens & {"creature", "damage"}:
        return True
    return bool(cut_tokens & candidate_tokens & {"artifact", "creature", "enchantment", "planeswalker"})


def is_narrow_color_hate(candidate: dict[str, Any], candidate_rule: dict[str, Any]) -> bool:
    text = " ".join(
        [
            str(candidate.get("oracle_text") or ""),
            " ".join((candidate_rule.get("effects") or {}).keys()),
            " ".join((candidate_rule.get("battle_model_scopes") or {}).keys()),
        ]
    ).lower()
    return any(pattern in text for pattern in COLOR_HATE_PATTERNS)


def score_candidate(
    *,
    cut: dict[str, Any],
    cut_rule: dict[str, Any],
    candidate: dict[str, Any],
    candidate_rule: dict[str, Any],
    prior_rejects: set[tuple[str, str]],
) -> dict[str, Any]:
    cut_name = str(cut.get("card_name") or "")
    candidate_name = str(candidate.get("card_name") or "")
    cut_role = (cut.get("cut_exposure") or {}).get("inferred_role") or "unmeasured"
    role = candidate_role(candidate, candidate_rule)
    blockers: list[str] = []
    score = 0
    if cut_role not in SUPPORTED_CUT_ROLES:
        blockers.append(f"unsupported_cut_role:{cut_role}")
    if role != cut_role:
        blockers.append(f"candidate_role_mismatch:{role}")
    else:
        score += 35
    if int(candidate_rule.get("active_rule_count") or 0) <= 0:
        blockers.append("candidate_missing_active_rule")
    else:
        score += 25
    if not compatible_removal_scope(cut_rule, candidate_rule):
        blockers.append("candidate_scope_not_same_lane")
    else:
        score += 20
    if (normalize_key(candidate_name), normalize_key(cut_name)) in prior_rejects:
        blockers.append("prior_exact_reject")
    if cut_role == "spot_removal" and is_narrow_color_hate(candidate, candidate_rule):
        blockers.append("candidate_narrow_color_hate")
    deck_count = int(candidate.get("deck_count") or 0)
    score += min(24, deck_count * 8)
    cut_cmc = float((cut.get("cut_metadata") or {}).get("cmc") or 0)
    candidate_cmc = float(candidate.get("cmc") or 0)
    if candidate_cmc and cut_cmc:
        if candidate_cmc <= cut_cmc:
            score += 8
        elif candidate_cmc > cut_cmc + 2:
            blockers.append("candidate_much_higher_cmc")
            score -= 10
    if "Instant" in str(candidate.get("type_line") or "") or "Sorcery" in str(candidate.get("type_line") or ""):
        score += 5
    status = "preflight_ready" if not blockers else "blocked"
    return {
        "package_key": package_key(candidate_name, cut_name),
        "status": status,
        "score": score,
        "candidate": candidate_name,
        "cut": cut_name,
        "candidate_role": role,
        "cut_role": cut_role,
        "candidate_metadata": candidate,
        "cut_metadata": cut.get("cut_metadata") or {},
        "candidate_rule": candidate_rule,
        "cut_rule": cut_rule,
        "blockers": blockers,
    }


def build_manifest_package(row: dict[str, Any], source_review: Path) -> dict[str, Any]:
    return {
        "package_key": row["package_key"],
        "family": "interaction_removal_benchmark",
        "hypothesis": (
            f"{row['candidate']} is an active-rule Lorehold variant interaction card. "
            f"This benchmarks it as a same-lane replacement for measured moderate-exposure "
            f"{row['cut']} before any deck promotion; high-exposure interaction slots remain protected."
        ),
        "adds": [row["candidate"]],
        "cuts": [row["cut"]],
        "cut_safety_override_reason": (
            "same-lane interaction benchmark required by "
            f"{source_review.name}; cut has measured exposure and is not a blind flex slot"
        ),
    }


def build_report(
    *,
    conn: sqlite3.Connection,
    manual_review: dict[str, Any],
    prior_results: dict[str, Any],
    db_path: Path = DEFAULT_DB,
    manual_review_path: Path = DEFAULT_MANUAL_REVIEW,
    deck_id: int = 6,
    variant_deck_ids: Iterable[int] = DEFAULT_VARIANT_DECK_IDS,
    max_per_cut: int = 2,
) -> dict[str, Any]:
    current_metadata = current_deck_metadata(conn, deck_id)
    current_names = set(current_metadata)
    cuts = profiled_cut_rows(manual_review)
    cut_names = [str(row.get("card_name") or "") for row in cuts]
    variant_candidates = load_variant_candidates(
        conn,
        current_names=current_names,
        variant_deck_ids=variant_deck_ids,
    )
    rules = load_rule_summaries(
        conn,
        list(cut_names) + [row["card_name"] for row in variant_candidates.values()],
    )
    prior_rejects = exact_prior_rejects(prior_results)
    pair_rows = []
    for cut in cuts:
        cut_name = str(cut.get("card_name") or "")
        cut_key = normalize_key(cut_name)
        cut_with_metadata = {
            **cut,
            "cut_metadata": current_metadata.get(
                cut_key,
                {
                    "card_name": cut_name,
                    "cmc": 0.0,
                    "type_line": "",
                    "functional_tag": "",
                    "functional_tags": [],
                    "oracle_text": "",
                },
            ),
        }
        cut_rule = rules.get(cut_key) or {}
        for candidate in variant_candidates.values():
            pair_rows.append(
                score_candidate(
                    cut=cut_with_metadata,
                    cut_rule=cut_rule,
                    candidate=candidate,
                    candidate_rule=rules.get(normalize_key(candidate["card_name"])) or {},
                    prior_rejects=prior_rejects,
                )
            )
    pair_rows.sort(
        key=lambda row: (
            row["status"] != "preflight_ready",
            row["cut"],
            -int(row["score"] or 0),
            row["candidate"],
        )
    )
    ready_by_cut: dict[str, list[dict[str, Any]]] = {}
    for row in pair_rows:
        if row["status"] == "preflight_ready":
            ready_by_cut.setdefault(row["cut"], []).append(row)
    selected = [
        row
        for cut_name in sorted(ready_by_cut)
        for row in ready_by_cut[cut_name][:max(1, max_per_cut)]
    ]
    packages = [build_manifest_package(row, manual_review_path) for row in selected]
    status_counts = Counter(row["status"] for row in pair_rows)
    blocked_cut_rows = [
        {
            "card_name": row.get("card_name"),
            "status": row.get("status"),
            "recommended_action": row.get("recommended_action"),
            "cut_exposure": row.get("cut_exposure") or {},
            "reason": "no supported generator for this cut role yet",
        }
        for row in cuts
        if (row.get("cut_exposure") or {}).get("inferred_role") not in SUPPORTED_CUT_ROLES
    ]
    return {
        "generated_at": utc_now(),
        "source_db": str(db_path),
        "manual_review": str(manual_review_path),
        "variant_deck_ids": list(variant_deck_ids),
        "postgres_writes": False,
        "source_db_mutated": False,
        "summary": {
            "profiled_cut_count": len(cuts),
            "supported_cut_count": len(cuts) - len(blocked_cut_rows),
            "candidate_pool_count": len(variant_candidates),
            "pair_evaluation_count": len(pair_rows),
            "preflight_ready_pair_count": len([row for row in pair_rows if row["status"] == "preflight_ready"]),
            "selected_package_count": len(packages),
            "status_counts": dict(sorted(status_counts.items())),
            "recommended_next_action": (
                "run_profiled_cut_benchmark_preflight"
                if packages
                else "no_profiled_cut_benchmark_package_ready"
            ),
        },
        "blocked_cut_rows": blocked_cut_rows,
        "selected_pairs": selected,
        "top_pair_evaluations": pair_rows[:40],
        "manifest": {
            "generated_at": utc_now(),
            "source": "lorehold_profiled_cut_benchmark_generator",
            "manual_review": str(manual_review_path),
            "postgres_writes": False,
            "source_db_mutated": False,
            "packages": packages,
        },
    }


def render_markdown(payload: dict[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Profiled Cut Benchmark Generator - 2026-06-28",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Source DB: `{payload['source_db']}`",
        f"- Manual review: `{payload['manual_review']}`",
        f"- Variant deck IDs: `{', '.join(str(deck_id) for deck_id in payload['variant_deck_ids'])}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "",
        "## Summary",
        "",
        f"- Recommended next action: `{summary['recommended_next_action']}`",
        f"- Profiled cuts: `{summary['profiled_cut_count']}`",
        f"- Supported cuts: `{summary['supported_cut_count']}`",
        f"- Candidate pool: `{summary['candidate_pool_count']}`",
        f"- Pair evaluations: `{summary['pair_evaluation_count']}`",
        f"- Preflight-ready pairs: `{summary['preflight_ready_pair_count']}`",
        f"- Selected packages: `{summary['selected_package_count']}`",
        f"- Status counts: `{json.dumps(summary['status_counts'], sort_keys=True)}`",
        "",
        "## Selected Packages",
        "",
    ]
    if not payload["selected_pairs"]:
        lines.append("- none")
    else:
        lines.extend(
            [
                "| Package | Add | Cut | Score | Candidate Role | Cut Role |",
                "| --- | --- | --- | ---: | --- | --- |",
            ]
        )
        for row in payload["selected_pairs"]:
            lines.append(
                "| {package} | {candidate} | {cut} | {score} | `{candidate_role}` | `{cut_role}` |".format(
                    package=row["package_key"],
                    candidate=row["candidate"],
                    cut=row["cut"],
                    score=int(row["score"] or 0),
                    candidate_role=row["candidate_role"],
                    cut_role=row["cut_role"],
                )
            )
    if payload["blocked_cut_rows"]:
        lines.extend(["", "## Blocked Cuts", ""])
        for row in payload["blocked_cut_rows"]:
            lines.append(
                f"- `{row['card_name']}`: {row['reason']} "
                f"(role `{row.get('cut_exposure', {}).get('inferred_role', 'unmeasured')}`)"
            )
    lines.extend(["", "## Top Pair Evaluations", ""])
    lines.extend(
        [
            "| Candidate | Cut | Status | Score | Blockers |",
            "| --- | --- | --- | ---: | --- |",
        ]
    )
    for row in payload["top_pair_evaluations"][:20]:
        lines.append(
            "| {candidate} | {cut} | `{status}` | {score} | {blockers} |".format(
                candidate=row["candidate"],
                cut=row["cut"],
                status=row["status"],
                score=int(row["score"] or 0),
                blockers=", ".join(row["blockers"]) or "-",
            )
        )
    return "\n".join(lines) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--manual-review", type=Path, default=DEFAULT_MANUAL_REVIEW)
    parser.add_argument("--prior-package-report", type=Path, action="append")
    parser.add_argument("--max-per-cut", type=int, default=2)
    parser.add_argument("--stem", default="lorehold_profiled_cut_benchmark_generator_20260628_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    manual_review = read_json(args.manual_review)
    prior_paths = [
        path.resolve()
        for path in (args.prior_package_report or list(package_gate.DEFAULT_PRIOR_PACKAGE_REPORTS))
    ]
    prior_results = package_gate.load_prior_package_results(prior_paths)
    registry_results = package_gate.load_registry_prior_results(package_gate.DEFAULT_REGISTRY.resolve())
    prior_results = package_gate.merge_registry_prior_results(prior_results, registry_results)
    with connect(args.db) as conn:
        payload = build_report(
            conn=conn,
            manual_review=manual_review,
            prior_results=prior_results,
            db_path=args.db,
            manual_review_path=args.manual_review,
            max_per_cut=args.max_per_cut,
        )
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    manifest_path = REPORT_DIR / f"{args.stem}_package_manifest.json"
    payload["manifest_path"] = str(manifest_path)
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    manifest_path.write_text(
        json.dumps(payload["manifest"], ensure_ascii=True, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(f"wrote {manifest_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
