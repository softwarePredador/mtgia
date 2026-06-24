#!/usr/bin/env python3
"""Build a shadow XMage pattern registry from ManaLoom batch proposals.

The registry produced here is an evidence artifact. It does not promote rules,
does not execute battle behavior, and does not mutate PostgreSQL or Hermes.
Patterns become executable only after focused ManaLoom tests and explicit
`card_battle_rules` promotion through the existing PostgreSQL gates.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import xmage_effective_queue_report as effective_queue_report


DEFAULT_REPORT_DIR = Path(__file__).resolve().parent.parent.parent / "master_optimizer_reports"
DEFAULT_PROPOSAL_REPORT = (
    DEFAULT_REPORT_DIR / "xmage_current_replay_batch_pipeline_20260624_expanded_608_619_real_v5_proposals.json"
)
DEFAULT_BENCHMARK_REPORT = (
    DEFAULT_REPORT_DIR / "xmage_acceleration_strategy_benchmark_20260624_expanded_608_619_real_v1.json"
)
DEFAULT_TEST_MINER_REPORT = DEFAULT_REPORT_DIR / "xmage_test_scenario_miner_targeted_damage_20260624.json"


PROMOTION_STATUS = "shadow_only"


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip() + "\n", encoding="utf-8")


def write_json(path: Path, payload: dict[str, Any]) -> None:
    write_text(path, json.dumps(payload, indent=2, sort_keys=True))


def slug(value: str) -> str:
    text = re.sub(r"[^a-z0-9]+", "_", str(value or "").lower()).strip("_")
    return text or "unknown"


def stable_hash(value: Any, *, length: int = 16) -> str:
    encoded = json.dumps(value, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()[:length]


def normalize_card_name(value: str) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip()).lower()


def normalized_constraints(effect_json: dict[str, Any]) -> dict[str, Any]:
    constraints = effect_json.get("target_constraints")
    return dict(constraints) if isinstance(constraints, dict) else {}


def subpattern_template_fields(effect_json: dict[str, Any]) -> dict[str, Any]:
    ignored = {"cmc"}
    fields: dict[str, Any] = {}
    for key, value in sorted(effect_json.items()):
        if key in ignored:
            continue
        if key in {"effect", "battle_model_scope", "ability_kind", "target_constraints"}:
            continue
        if isinstance(value, (str, int, float, bool, list, dict)) or value is None:
            fields[key] = value
    return fields


def subpattern_signature(proposal: dict[str, Any]) -> dict[str, Any]:
    effect_json = dict(proposal.get("effect_json") or {})
    signature = {
        "effect": str(effect_json.get("effect") or proposal.get("effect") or ""),
        "ability_kind": str(effect_json.get("ability_kind") or ""),
        "target_constraints": normalized_constraints(effect_json),
        "template_fields": subpattern_template_fields(effect_json),
    }
    return signature


def lane_by_card(
    proposals: list[dict[str, Any]],
    package_index: dict[str, list[dict[str, Any]]],
) -> dict[str, str]:
    lanes: dict[str, str] = {}
    for proposal in proposals:
        name = str(proposal.get("card_name") or "")
        lanes[name] = effective_queue_report.effective_lane(proposal, package_index)
    return lanes


def package_refs_for_card(card_name: str, package_index: dict[str, list[dict[str, Any]]]) -> list[dict[str, Any]]:
    refs = []
    for manifest in package_index.get(card_name, []):
        refs.append(
            {
                "deploy_id": manifest.get("deploy_id"),
                "slug": manifest.get("slug"),
                "status": manifest.get("status"),
                "manifest_path": manifest.get("manifest_path"),
            }
        )
    return refs


def pattern_key(proposal: dict[str, Any], lane: str) -> tuple[str, str, str, str]:
    return (
        lane,
        str(proposal.get("family_id") or "manual_model"),
        str(proposal.get("effect") or ""),
        str(proposal.get("battle_model_scope") or ""),
    )


def pattern_status(
    *,
    lane: str,
    card_count: int,
    subpattern_count: int,
    family_id: str,
    battle_model_scope: str,
) -> str:
    if lane == effective_queue_report.PACKAGE_PREPARED_LANE:
        return "governance_only_pending_pg_apply"
    if lane == effective_queue_report.PACKAGE_READY_LANE:
        return "ready_for_pg_package_generation"
    if lane == effective_queue_report.BLOCKED_LANE:
        return "blocked_missing_xmage_source"
    if lane == effective_queue_report.MANUAL_LANE:
        return "manual_model_observation_only"
    if lane == effective_queue_report.RUNTIME_LANE:
        if family_id == "token_maker" and card_count == 1:
            return "fragmented_runtime_observation_only"
        if card_count >= 2 and subpattern_count <= max(2, card_count):
            return "runtime_template_candidate_requires_executor_tests"
        return "runtime_observation_requires_taxonomy"
    if lane == effective_queue_report.SPLIT_SCOPE_LANE:
        if subpattern_count > 1 or battle_model_scope.endswith("_variant_v1"):
            return "requires_subpattern_split_before_promotion"
        return "candidate_template_requires_review_tests"
    return "observation_only"


def required_evidence_for_status(status: str) -> list[str]:
    mapping = {
        "governance_only_pending_pg_apply": [
            "approved exact PostgreSQL apply command",
            "precheck",
            "apply",
            "postcheck",
            "PG -> Hermes sync",
            "affected battle/deck audit",
        ],
        "ready_for_pg_package_generation": [
            "package precheck",
            "approved exact PostgreSQL apply command",
            "postcheck",
            "PG -> Hermes sync",
        ],
        "requires_subpattern_split_before_promotion": [
            "subpattern split",
            "focused ManaLoom tests per subpattern",
            "package generation only for exact supported subpatterns",
        ],
        "runtime_template_candidate_requires_executor_tests": [
            "runtime executor implementation",
            "focused runtime tests",
            "queue delta report",
        ],
        "fragmented_runtime_observation_only": [
            "taxonomy support",
            "test miner coverage",
            "do not open broad runtime by raw family count",
        ],
        "manual_model_observation_only": [
            "manual mapper review",
            "Oracle/source provenance",
            "focused test before promotion",
        ],
        "blocked_missing_xmage_source": [
            "non-XMage source harvest",
            "manual model",
            "focused test before promotion",
        ],
    }
    return mapping.get(status, ["review", "focused test", "promotion gate"])


def recommended_action_for_status(status: str) -> str:
    if status == "governance_only_pending_pg_apply":
        return "Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate."
    if status == "ready_for_pg_package_generation":
        return "Generate a PG package before any runtime work."
    if status == "requires_subpattern_split_before_promotion":
        return "Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion."
    if status == "runtime_template_candidate_requires_executor_tests":
        return "Implement only the exact homogeneous runtime scope with focused tests."
    if status == "fragmented_runtime_observation_only":
        return "Keep as registry evidence; wait for taxonomy/test-miner support before executor work."
    if status == "manual_model_observation_only":
        return "Keep after package, split-scope, and homogeneous-runtime lanes."
    if status == "blocked_missing_xmage_source":
        return "Isolate as exception lane; do not contaminate main XMage queue."
    return "Review before promotion."


def summarize_subpatterns(cards: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, dict[str, Any]] = {}
    for proposal in cards:
        signature = subpattern_signature(proposal)
        key = stable_hash(signature)
        row = grouped.setdefault(
            key,
            {
                "subpattern_key": key,
                "signature": signature,
                "count": 0,
                "cards": [],
                "proposal_status_counts": Counter(),
            },
        )
        row["count"] += 1
        row["cards"].append(str(proposal.get("card_name") or ""))
        row["proposal_status_counts"][str(proposal.get("proposal_status") or "")] += 1
    rows = list(grouped.values())
    rows.sort(key=lambda item: (-item["count"], item["subpattern_key"]))
    for row in rows:
        row["cards"] = sorted(row["cards"])
        row["proposal_status_counts"] = dict(sorted(row["proposal_status_counts"].items()))
    return rows


def test_miner_lookup(test_miner_report: dict[str, Any] | None) -> dict[str, dict[str, Any]]:
    if not test_miner_report:
        return {}
    cards = test_miner_report.get("cards")
    if isinstance(cards, dict):
        return {normalize_card_name(name): payload for name, payload in cards.items() if isinstance(payload, dict)}
    if isinstance(cards, list):
        return {
            normalize_card_name(str(card.get("card_name") or "")): card
            for card in cards
            if isinstance(card, dict) and card.get("card_name")
        }
    return {}


def build_pattern_rows(
    *,
    proposals: list[dict[str, Any]],
    report_dir: Path,
    test_miner_report: dict[str, Any] | None,
) -> tuple[list[dict[str, Any]], dict[str, int]]:
    _, package_index = effective_queue_report.load_package_manifests(report_dir)
    miner_by_name = test_miner_lookup(test_miner_report)
    grouped: dict[tuple[str, str, str, str], list[dict[str, Any]]] = defaultdict(list)
    lane_counts: Counter[str] = Counter()
    for proposal in proposals:
        lane = effective_queue_report.effective_lane(proposal, package_index)
        lane_counts[lane] += 1
        grouped[pattern_key(proposal, lane)].append(proposal)

    patterns: list[dict[str, Any]] = []
    for (lane, family_id, effect, battle_model_scope), cards in grouped.items():
        subpatterns = summarize_subpatterns(cards)
        status = pattern_status(
            lane=lane,
            card_count=len(cards),
            subpattern_count=len(subpatterns),
            family_id=family_id,
            battle_model_scope=battle_model_scope,
        )
        sorted_cards = sorted(str(card.get("card_name") or "") for card in cards)
        test_refs = [
            {
                "card_name": card_name,
                "status": (miner_by_name.get(normalize_card_name(card_name)) or {}).get("status"),
                "usable_scenario_candidates": (
                    miner_by_name.get(normalize_card_name(card_name)) or {}
                ).get("usable_scenario_candidates", 0),
            }
            for card_name in sorted_cards
            if normalize_card_name(card_name) in miner_by_name
        ]
        pattern_identity = {
            "lane": lane,
            "family_id": family_id,
            "effect": effect,
            "battle_model_scope": battle_model_scope,
        }
        patterns.append(
            {
                "pattern_id": "xmage_pattern:" + stable_hash(pattern_identity, length=20),
                "lane": lane,
                "family_id": family_id,
                "effect": effect,
                "battle_model_scope": battle_model_scope,
                "pattern_status": status,
                "promotion_status": PROMOTION_STATUS,
                "can_execute_in_battle": False,
                "can_auto_promote_to_card_battle_rules": False,
                "card_count": len(cards),
                "subpattern_count": len(subpatterns),
                "cards": sorted_cards,
                "sample_cards": sorted_cards[:10],
                "proposal_status_counts": dict(sorted(Counter(str(card.get("proposal_status") or "") for card in cards).items())),
                "ability_kind_counts": dict(
                    sorted(Counter(str((card.get("effect_json") or {}).get("ability_kind") or "") for card in cards).items())
                ),
                "xmage_classes": sorted(
                    str(card.get("xmage_class") or "") for card in cards if card.get("xmage_class")
                )[:20],
                "package_refs": [
                    ref
                    for card in sorted_cards
                    for ref in package_refs_for_card(card, package_index)
                ],
                "test_references": test_refs,
                "subpatterns": subpatterns,
                "required_evidence_before_promotion": required_evidence_for_status(status),
                "recommended_action": recommended_action_for_status(status),
            }
        )
    patterns.sort(
        key=lambda item: (
            effective_queue_report.LANE_ORDER.index(item["lane"])
            if item["lane"] in effective_queue_report.LANE_ORDER
            else 99,
            -int(item["card_count"]),
            item["family_id"],
            item["battle_model_scope"],
        )
    )
    return patterns, dict(sorted(lane_counts.items()))


def build_report(
    *,
    proposal_report: dict[str, Any],
    report_dir: Path = DEFAULT_REPORT_DIR,
    benchmark_report: dict[str, Any] | None = None,
    test_miner_report: dict[str, Any] | None = None,
) -> dict[str, Any]:
    proposals = list(proposal_report.get("proposals") or [])
    patterns, lane_counts = build_pattern_rows(
        proposals=proposals,
        report_dir=report_dir,
        test_miner_report=test_miner_report,
    )
    status_counts = Counter(pattern["pattern_status"] for pattern in patterns)
    card_counts_by_status: Counter[str] = Counter()
    for pattern in patterns:
        card_counts_by_status[pattern["pattern_status"]] += int(pattern["card_count"])
    benchmark_summary = (benchmark_report or {}).get("summary") or {}
    return {
        "generated_at": utc_now(),
        "status": "ready",
        "mutations_performed": [],
        "registry_contract": {
            "kind": "shadow_pattern_registry",
            "promotion_status": PROMOTION_STATUS,
            "postgresql_source_of_truth_table": "card_battle_rules",
            "consumer_boundary": "Patterns are advisory and must not be joined directly into deck-card consumers.",
        },
        "source": {
            "proposal_summary": proposal_report.get("summary") or {},
            "report_dir": str(report_dir),
            "recommended_strategy_id": benchmark_summary.get("recommended_strategy_id"),
            "recommended_decision_score": benchmark_summary.get("recommended_decision_score"),
            "test_miner_status": (test_miner_report or {}).get("status"),
        },
        "summary": {
            "proposal_count": len(proposals),
            "pattern_count": len(patterns),
            "lane_counts": lane_counts,
            "pattern_status_counts": dict(sorted(status_counts.items())),
            "card_counts_by_pattern_status": dict(sorted(card_counts_by_status.items())),
            "promotion_status": PROMOTION_STATUS,
            "executable_pattern_count": 0,
            "auto_promotable_pattern_count": 0,
        },
        "patterns": patterns,
    }


def schema_proposal_sql() -> str:
    return """-- Read-only proposal. Do not apply without explicit PostgreSQL approval.
-- Purpose: persist XMage-derived pattern observations separately from executable card_battle_rules.

CREATE TABLE IF NOT EXISTS public.xmage_pattern_registry (
  pattern_id TEXT PRIMARY KEY,
  lane TEXT NOT NULL,
  family_id TEXT NOT NULL,
  effect TEXT NOT NULL,
  battle_model_scope TEXT NOT NULL,
  pattern_status TEXT NOT NULL,
  promotion_status TEXT NOT NULL DEFAULT 'shadow_only',
  can_execute_in_battle BOOLEAN NOT NULL DEFAULT FALSE,
  can_auto_promote_to_card_battle_rules BOOLEAN NOT NULL DEFAULT FALSE,
  card_count INTEGER NOT NULL DEFAULT 0,
  subpattern_count INTEGER NOT NULL DEFAULT 0,
  evidence_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  template_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  source_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_xmage_pattern_registry_shadow_execution CHECK (
    promotion_status <> 'shadow_only'
    OR (
      can_execute_in_battle = FALSE
      AND can_auto_promote_to_card_battle_rules = FALSE
    )
  )
);

CREATE INDEX IF NOT EXISTS idx_xmage_pattern_registry_family_scope
ON public.xmage_pattern_registry (family_id, effect, battle_model_scope);

CREATE INDEX IF NOT EXISTS idx_xmage_pattern_registry_status
ON public.xmage_pattern_registry (pattern_status, promotion_status);

CREATE INDEX IF NOT EXISTS idx_xmage_pattern_registry_evidence
ON public.xmage_pattern_registry USING GIN (evidence_json);
"""


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# XMage Shadow Pattern Registry",
        "",
        f"- Generated at: `{report.get('generated_at')}`",
        f"- Status: `{report.get('status')}`",
        f"- Mutations performed: `{report.get('mutations_performed')}`",
        f"- Promotion status: `{(report.get('summary') or {}).get('promotion_status')}`",
        "",
        "## Summary",
        "",
    ]
    summary = report.get("summary") or {}
    for key in [
        "proposal_count",
        "pattern_count",
        "lane_counts",
        "pattern_status_counts",
        "card_counts_by_pattern_status",
        "executable_pattern_count",
        "auto_promotable_pattern_count",
    ]:
        lines.append(f"- `{key}`: `{json.dumps(summary.get(key), sort_keys=True)}`")
    lines.extend(
        [
            "",
            "## Boundary",
            "",
            "- Registry rows are advisory evidence only.",
            "- Executable battle behavior still belongs in reviewed/tested `card_battle_rules`.",
            "- Do not join registry rows directly into deck-card consumers.",
            "- PostgreSQL/Hermes writes remain approval-gated.",
            "",
            "## Patterns",
            "",
            "| Pattern | Lane | Status | Cards | Subpatterns | Action |",
            "| --- | --- | --- | ---: | ---: | --- |",
        ]
    )
    for pattern in report.get("patterns", []):
        lines.append(
            "| "
            + " | ".join(
                [
                    f"`{pattern.get('family_id')}/{pattern.get('effect')}/{pattern.get('battle_model_scope')}`",
                    f"`{pattern.get('lane')}`",
                    f"`{pattern.get('pattern_status')}`",
                    str(pattern.get("card_count")),
                    str(pattern.get("subpattern_count")),
                    str(pattern.get("recommended_action")).replace("|", "\\|"),
                ]
            )
            + " |"
        )
    lines.extend(["", "## Top Pattern Details", ""])
    for pattern in (report.get("patterns") or [])[:12]:
        lines.extend(
            [
                f"### {pattern.get('family_id')} / {pattern.get('effect')} / {pattern.get('battle_model_scope')}",
                "",
                f"- Pattern id: `{pattern.get('pattern_id')}`",
                f"- Lane: `{pattern.get('lane')}`",
                f"- Status: `{pattern.get('pattern_status')}`",
                f"- Cards: `{pattern.get('card_count')}` ({', '.join(pattern.get('sample_cards') or [])})",
                f"- Subpatterns: `{pattern.get('subpattern_count')}`",
                f"- Required evidence: `{json.dumps(pattern.get('required_evidence_before_promotion'), sort_keys=True)}`",
                "",
            ]
        )
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--proposal-report", type=Path, default=DEFAULT_PROPOSAL_REPORT)
    parser.add_argument("--report-dir", type=Path, default=DEFAULT_REPORT_DIR)
    parser.add_argument("--benchmark-report", type=Path, default=DEFAULT_BENCHMARK_REPORT)
    parser.add_argument("--test-miner-report", type=Path, default=DEFAULT_TEST_MINER_REPORT)
    parser.add_argument("--output-prefix", type=Path, required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    benchmark = load_json(args.benchmark_report) if args.benchmark_report.exists() else None
    test_miner = load_json(args.test_miner_report) if args.test_miner_report.exists() else None
    report = build_report(
        proposal_report=load_json(args.proposal_report),
        report_dir=args.report_dir,
        benchmark_report=benchmark,
        test_miner_report=test_miner,
    )
    output_json = args.output_prefix.with_name(args.output_prefix.name + ".json")
    output_md = args.output_prefix.with_name(args.output_prefix.name + ".md")
    output_sql = args.output_prefix.with_name(args.output_prefix.name + "_schema_proposal.sql")
    write_json(output_json, report)
    write_text(output_md, render_markdown(report))
    write_text(output_sql, schema_proposal_sql())
    print(f"report_json={output_json}")
    print(f"report_md={output_md}")
    print(f"schema_proposal_sql={output_sql}")
    print(f"summary={json.dumps(report['summary'], sort_keys=True)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
