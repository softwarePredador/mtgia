#!/usr/bin/env python3
"""Review Lorehold manual cuts before spending battle-gate time.

This is a read-only analysis helper. It explains why a promising variant card
still is not automatically testable when the only available cut is an engine,
locked role, or strategically unresolved slot in the current Lorehold champion.
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


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_STRATEGY_AUDIT = REPORT_DIR / "lorehold_strategy_learning_audit_20260627_v3.json"
DEFAULT_CUT_MODEL = REPORT_DIR / "lorehold_variant_gap_miner_20260627_v2_cut_model.json"
DEFAULT_DB = (
    REPORT_DIR
    / "lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob"
    / "knowledge_candidate.db"
)

ACTIVE_EXECUTION_STATUSES = {"active", "verified", "auto", "reviewed"}
ACTIVE_REVIEW_STATUSES = {"verified", "active", "needs_review", "reviewed"}

EXTERNAL_RESEARCH_SOURCES = [
    {
        "title": "EDHREC - Miracles Every Turn With Lorehold, the Historian",
        "url": "https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander",
        "finding": (
            "Lorehold's core loop is first-draw miracle timing, opponent-upkeep rummage, "
            "topdeck manipulation, Library of Leng, and high-impact instant/sorcery hits."
        ),
    },
    {
        "title": "EDHREC - Lorehold, the Historian: Boros Miracles on a Budget",
        "url": "https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget",
        "finding": (
            "The deck needs a high instant/sorcery density so miracle draws do not become dead "
            "non-spell hits."
        ),
    },
    {
        "title": "Card Kingdom - 10 Crazy Synergy Cards for Lorehold, the Historian",
        "url": "https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/",
        "finding": (
            "Community deck tech highlights Library of Leng and reanimation/discard routes as "
            "real Lorehold subpackages."
        ),
    },
    {
        "title": "Reddit r/EDHBrews - Commander Deck Tech: Lorehold, the Historian",
        "url": "https://www.reddit.com/r/EDHBrews/comments/1ssny05/commander_deck_tech_lorehold_the_historian/",
        "finding": (
            "Community discussion reinforces discard, topdeck control, suspend/miracle, and "
            "reanimation as plausible lanes, but not as promotion evidence by itself."
        ),
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def card_decision_lookup(strategy_audit: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        normalize_key(row.get("card_name")): row
        for row in (strategy_audit.get("card_decision_manifest") or {}).get("cards") or []
        if row.get("card_name")
    }


def cut_safety_lookup(strategy_audit: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        normalize_key(row.get("card_name")): row
        for row in (strategy_audit.get("cut_safety_manifest") or {}).get("cuts") or []
        if row.get("card_name")
    }


def package_learning_rows(strategy_audit: dict[str, Any], candidate_name: str) -> list[dict[str, Any]]:
    learning = (strategy_audit.get("strategy_dependency_map") or {}).get("package_learning") or {}
    post_squee = learning.get("post_squee") or {}
    rows = []
    for section in ("hard_reject_sample", "probation_or_watch"):
        for row in post_squee.get(section) or []:
            if normalize_key(candidate_name) in {normalize_key(card) for card in row.get("adds") or []}:
                rows.append({**row, "source_section": section})
    rows.sort(
        key=lambda row: (
            row.get("source_section") != "probation_or_watch",
            float(row.get("strong_seed_delta_pp") or 0),
            row.get("package_key") or "",
        )
    )
    return rows


def load_rule_summaries(conn: sqlite3.Connection, names: Iterable[str]) -> dict[str, dict[str, Any]]:
    wanted = {normalize_key(name): str(name) for name in names if name}
    summaries: dict[str, dict[str, Any]] = {
        key: {
            "card_name": name,
            "active_rule_count": 0,
            "rule_count": 0,
            "execution_statuses": Counter(),
            "review_statuses": Counter(),
            "sources": Counter(),
            "effects": Counter(),
            "battle_model_scopes": Counter(),
        }
        for key, name in wanted.items()
    }
    if not wanted:
        return {}
    rows = conn.execute(
        """
        SELECT card_name, normalized_name, execution_status, review_status, source, effect_json
        FROM battle_card_rules
        ORDER BY card_name, execution_status, review_status
        """
    ).fetchall()
    for row in rows:
        forms = {normalize_key(row["card_name"]), normalize_key(row["normalized_name"])}
        key = next((form for form in forms if form in wanted), "")
        if not key:
            continue
        summary = summaries[key]
        execution_status = str(row["execution_status"] or "")
        review_status = str(row["review_status"] or "")
        summary["rule_count"] += 1
        summary["execution_statuses"][execution_status] += 1
        summary["review_statuses"][review_status] += 1
        if row["source"]:
            summary["sources"][str(row["source"])] += 1
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
    return {key: finalize_counter_dicts(value) for key, value in summaries.items()}


def load_deck_presence(conn: sqlite3.Connection, names: Iterable[str]) -> dict[str, list[dict[str, Any]]]:
    wanted = {normalize_key(name): str(name) for name in names if name}
    presence: dict[str, list[dict[str, Any]]] = {key: [] for key in wanted}
    if not wanted:
        return {}
    rows = conn.execute(
        """
        SELECT deck_id, card_name, quantity, functional_tag, cmc, type_line, functional_tags_json
        FROM deck_cards
        ORDER BY deck_id, card_name
        """
    ).fetchall()
    for row in rows:
        key = normalize_key(row["card_name"])
        if key not in wanted:
            continue
        presence[key].append(
            {
                "deck_id": int(row["deck_id"]),
                "card_name": row["card_name"],
                "quantity": int(row["quantity"] or 1),
                "functional_tag": row["functional_tag"],
                "cmc": row["cmc"],
                "type_line": row["type_line"],
                "functional_tags_json": row["functional_tags_json"],
            }
        )
    return presence


def finalize_counter_dicts(value: dict[str, Any]) -> dict[str, Any]:
    finalized = dict(value)
    for key in ("execution_statuses", "review_statuses", "sources", "effects", "battle_model_scopes"):
        finalized[key] = dict(sorted((value.get(key) or {}).items()))
    return finalized


def classify_manual_pair(
    *,
    candidate: str,
    cut: str,
    candidate_rule: dict[str, Any],
    cut_rule: dict[str, Any],
    cut_decision: dict[str, Any],
    cut_safety: dict[str, Any],
) -> tuple[str, str, list[str]]:
    cut_key = normalize_key(cut)
    reasons: list[str] = []
    if cut_key == normalize_key("Squee, Goblin Nabob"):
        if cut_decision.get("decision") == "probation_engine":
            reasons.append("Squee is the current champion's probation recursion engine.")
        if cut_decision.get("rule_materialized_in_equal_gate_candidate"):
            reasons.append("Squee's graveyard return is already materialized in the equal-gate candidate.")
        reasons.append("Variant recursion cards must prove a non-Squee cut or a multi-card recursion package.")
        return "do_not_cut_current_champion_engine", "blocked", reasons
    if cut_key == normalize_key("Emeria's Call // Emeria, Shattered Skyclave"):
        if cut_decision.get("status") == "materialization_gap_ready_rule":
            reasons.append("Emeria has a ready local rule but still needs durable role sync.")
        if not cut_decision.get("effective_role") or cut_decision.get("effective_role") == "unknown":
            reasons.append("Emeria's strategic role is still unknown, so cutting it hides whether the deck needs board/protection density.")
        reasons.append("Austere-style board wipes can be tested only after Emeria exposure/role is measured or a safer cut is found.")
        return "manual_review_role_gap_before_gate", "manual_review", reasons
    if cut_safety.get("status") == "locked_do_not_cut":
        reasons.append("Cut is locked by prior strong-seed regression.")
        return "blocked_locked_cut", "blocked", reasons
    if int(cut_rule.get("active_rule_count") or 0) <= 0:
        reasons.append("Cut has no active local battle rule, so its current contribution is not measurable.")
        return "manual_review_missing_cut_rule", "manual_review", reasons
    if int(candidate_rule.get("active_rule_count") or 0) <= 0:
        reasons.append("Candidate has no active local battle rule.")
        return "blocked_candidate_runtime_gap", "blocked", reasons
    reasons.append("Candidate and cut are runtime-ready, but the lane role is not safe enough for automatic gate.")
    return "manual_cut_review_required", "manual_review", reasons


def classify_contextual_candidate(
    *,
    candidate: str,
    rule: dict[str, Any],
    evidence_rows: list[dict[str, Any]],
) -> tuple[str, str, list[str]]:
    reasons: list[str] = []
    if int(rule.get("active_rule_count") or 0) <= 0:
        return "blocked_candidate_runtime_gap", "blocked", ["Candidate has no active local battle rule."]
    if not evidence_rows:
        return (
            "needs_lane_model_before_gate",
            "manual_review",
            ["Candidate is runtime-ready but has no safe cut model in the current champion lane map."],
        )
    positive = [
        row for row in evidence_rows
        if float(row.get("delta_pp") or 0) > 0 and row.get("decision") != "reject_or_rework"
    ]
    strong_seed_regressions = [
        row for row in evidence_rows
        if float(row.get("strong_seed_delta_pp") or 0) < 0
    ]
    if positive:
        reasons.append("Aggregate upside exists in at least one prior gate.")
    if strong_seed_regressions:
        worst = min(float(row.get("strong_seed_delta_pp") or 0) for row in strong_seed_regressions)
        reasons.append(f"Prior evidence regressed the protected strong seed by {worst:+.2f} pp.")
    if strong_seed_regressions:
        return "tutor_lane_probation_needs_seed_safe_cut", "manual_review", reasons
    return "needs_specific_cut_before_gate", "manual_review", reasons or [
        "Runtime is ready, but no same-lane safe cut is proven."
    ]


def build_review(
    *,
    strategy_audit: dict[str, Any],
    cut_model: dict[str, Any],
    conn: sqlite3.Connection,
    strategy_path: Path = DEFAULT_STRATEGY_AUDIT,
    cut_model_path: Path = DEFAULT_CUT_MODEL,
    db_path: Path = DEFAULT_DB,
) -> dict[str, Any]:
    card_decisions = card_decision_lookup(strategy_audit)
    cut_safety = cut_safety_lookup(strategy_audit)
    manual_pairings = [
        row
        for row in cut_model.get("pairing_hypotheses") or []
        if row.get("status") == "manual_cut_review_required"
    ]
    contextual_pairings = [
        row
        for row in cut_model.get("pairing_hypotheses") or []
        if row.get("status") == "needs_lane_model_before_gate"
    ]
    relevant_names = {
        row.get("candidate")
        for row in manual_pairings + contextual_pairings
        if row.get("candidate")
    }
    for row in manual_pairings:
        for cut in row.get("cut_options") or []:
            if cut.get("card_name"):
                relevant_names.add(cut["card_name"])
    rule_summaries = load_rule_summaries(conn, sorted(relevant_names))
    deck_presence = load_deck_presence(conn, sorted(relevant_names))

    manual_reviews = []
    for pairing in manual_pairings:
        candidate = str(pairing.get("candidate") or "")
        cut_options = pairing.get("cut_options") or []
        if not cut_options:
            continue
        cut = str(cut_options[0].get("card_name") or "")
        candidate_key = normalize_key(candidate)
        cut_key = normalize_key(cut)
        decision, gate_action, reasons = classify_manual_pair(
            candidate=candidate,
            cut=cut,
            candidate_rule=rule_summaries.get(candidate_key, {}),
            cut_rule=rule_summaries.get(cut_key, {}),
            cut_decision=card_decisions.get(cut_key, {}),
            cut_safety=cut_safety.get(cut_key, {}),
        )
        manual_reviews.append(
            {
                "candidate": candidate,
                "cut": cut,
                "lane": pairing.get("lane") or cut_options[0].get("lane"),
                "decision": decision,
                "gate_action": gate_action,
                "reasons": reasons,
                "candidate_rule": rule_summaries.get(candidate_key, {}),
                "cut_rule": rule_summaries.get(cut_key, {}),
                "cut_decision": {
                    key: value
                    for key, value in (card_decisions.get(cut_key) or {}).items()
                    if key
                    in {
                        "decision",
                        "decision_reason",
                        "effective_role",
                        "package_lane",
                        "status",
                        "rule_materialized_in_equal_gate_candidate",
                    }
                },
                "cut_deck_presence": deck_presence.get(cut_key, []),
                "candidate_deck_presence": deck_presence.get(candidate_key, []),
                "pairing_signature": cut_options[0].get("signature"),
            }
        )

    contextual_reviews = []
    for pairing in contextual_pairings:
        candidate = str(pairing.get("candidate") or "")
        candidate_key = normalize_key(candidate)
        evidence = package_learning_rows(strategy_audit, candidate)
        decision, gate_action, reasons = classify_contextual_candidate(
            candidate=candidate,
            rule=rule_summaries.get(candidate_key, {}),
            evidence_rows=evidence,
        )
        contextual_reviews.append(
            {
                "candidate": candidate,
                "lane": pairing.get("lane") or "contextual",
                "decision": decision,
                "gate_action": gate_action,
                "reasons": reasons,
                "candidate_rule": rule_summaries.get(candidate_key, {}),
                "candidate_deck_presence": deck_presence.get(candidate_key, []),
                "prior_evidence": evidence,
                "recommended_cut_search": recommended_cut_search(candidate, evidence),
            }
        )

    status_counts = Counter(row["decision"] for row in manual_reviews + contextual_reviews)
    return {
        "generated_at": utc_now(),
        "strategy_audit": str(strategy_path),
        "cut_model": str(cut_model_path),
        "source_db": str(db_path),
        "postgres_writes": False,
        "source_db_mutated": False,
        "external_research_sources": EXTERNAL_RESEARCH_SOURCES,
        "summary": {
            "manual_cut_review_count": len(manual_reviews),
            "contextual_lane_review_count": len(contextual_reviews),
            "decision_counts": dict(sorted(status_counts.items())),
            "automatic_gate_ready_count": 0,
            "safe_next_action": (
                "Do not spend a gate on Squee/Emeria cuts yet; find a non-engine cut or run a "
                "targeted exposure gate that measures the unresolved role first."
            ),
        },
        "manual_cut_reviews": manual_reviews,
        "contextual_lane_reviews": contextual_reviews,
        "next_actions": [
            {
                "priority": 1,
                "action": "preserve_squee_while_testing_recursion_variants",
                "reason": "Squee is an observed champion/probation recursion engine; Volcanic Vision and Restoration Seminar need another cut or multi-card package.",
            },
            {
                "priority": 2,
                "action": "measure_emeria_role_before_austere_command_cut",
                "reason": "Emeria has rule coverage but unknown strategic role; Austere Command cannot prove improvement if it deletes an unmeasured board/protection slot.",
            },
            {
                "priority": 3,
                "action": "rebuild_tutor_tests_around_seed_safe_cuts",
                "reason": "Gamble and Enlightened Tutor are runtime-ready, but prior tests over Thor/Creative regressed the protected seed.",
            },
        ],
    }


def recommended_cut_search(candidate: str, evidence: list[dict[str, Any]]) -> str:
    if normalize_key(candidate) == normalize_key("Gamble"):
        return (
            "Keep Gamble on probation only if the cut does not touch Thor and does not repeat "
            "Creative Technique without a seed-42 protection explanation."
        )
    if normalize_key(candidate) == normalize_key("Enlightened Tutor"):
        return (
            "Search artifact/enchantment access cuts separately; do not use Thor as the tutor-access cut."
        )
    if evidence:
        return "Use the prior package evidence to define a narrower same-lane cut."
    return "Define lane and same-lane cut before any battle gate."


def render_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Lorehold Manual Cut Review - 2026-06-27",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Strategy audit: `{payload['strategy_audit']}`",
        f"- Cut model: `{payload['cut_model']}`",
        f"- Source DB: `{payload['source_db']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "",
        "## Summary",
        "",
        f"- Manual cut reviews: `{payload['summary']['manual_cut_review_count']}`",
        f"- Contextual lane reviews: `{payload['summary']['contextual_lane_review_count']}`",
        f"- Decision counts: `{json.dumps(payload['summary']['decision_counts'], sort_keys=True)}`",
        f"- Automatic gate-ready count: `{payload['summary']['automatic_gate_ready_count']}`",
        f"- Safe next action: {payload['summary']['safe_next_action']}",
        "",
        "## External Research Used As Heuristic Context",
        "",
    ]
    for source in payload["external_research_sources"]:
        lines.append(f"- [{source['title']}]({source['url']}): {source['finding']}")
    lines.extend(
        [
            "",
            "## Manual Cut Reviews",
            "",
            "| Candidate | Proposed Cut | Decision | Action | Main Reasons |",
            "| --- | --- | --- | --- | --- |",
        ]
    )
    for row in payload["manual_cut_reviews"]:
        lines.append(
            "| {candidate} | {cut} | `{decision}` | `{action}` | {reasons} |".format(
                candidate=row["candidate"],
                cut=row["cut"],
                decision=row["decision"],
                action=row["gate_action"],
                reasons="; ".join(row["reasons"]),
            )
        )
    lines.extend(
        [
            "",
            "## Contextual Lane Reviews",
            "",
            "| Candidate | Decision | Action | Prior Evidence | Cut Search |",
            "| --- | --- | --- | --- | --- |",
        ]
    )
    for row in payload["contextual_lane_reviews"]:
        evidence_bits = []
        for evidence in row.get("prior_evidence") or []:
            evidence_bits.append(
                "{key}: {delta:+.2f} pp / strong seed {seed:+.2f} pp".format(
                    key=evidence.get("package_key"),
                    delta=float(evidence.get("delta_pp") or 0),
                    seed=float(evidence.get("strong_seed_delta_pp") or 0),
                )
            )
        lines.append(
            "| {candidate} | `{decision}` | `{action}` | {evidence} | {cut_search} |".format(
                candidate=row["candidate"],
                decision=row["decision"],
                action=row["gate_action"],
                evidence="; ".join(evidence_bits) or "none",
                cut_search=row["recommended_cut_search"],
            )
        )
    lines.extend(["", "## Next Actions", ""])
    for row in payload["next_actions"]:
        lines.append(f"- P{row['priority']} `{row['action']}`: {row['reason']}")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--strategy-audit", type=Path, default=DEFAULT_STRATEGY_AUDIT)
    parser.add_argument("--cut-model", type=Path, default=DEFAULT_CUT_MODEL)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--stem", default="lorehold_manual_cut_review_20260627_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    strategy_audit = read_json(args.strategy_audit)
    cut_model = read_json(args.cut_model)
    with connect(args.db) as conn:
        payload = build_review(
            strategy_audit=strategy_audit,
            cut_model=cut_model,
            conn=conn,
            strategy_path=args.strategy_audit,
            cut_model_path=args.cut_model,
            db_path=args.db,
        )
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload) + "\n", encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
