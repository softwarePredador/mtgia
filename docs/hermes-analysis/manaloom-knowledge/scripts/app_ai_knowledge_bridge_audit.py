#!/usr/bin/env python3
"""Audit the bridge from learned ManaLoom knowledge to app/AI consumers.

This audit is intentionally static and read-only. It proves that knowledge
promoted from research, XMage, battle traces, Hermes, and PostgreSQL has an
active product path into backend AI routes, deterministic gates, and app-facing
sanitized diagnostics. It does not call OpenAI, mutate PostgreSQL, mutate
Hermes SQLite, run battles, or promote card rules.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DOCS_DIR = REPO_ROOT / "docs" / "hermes-analysis"
REPORT_DIR = DOCS_DIR / "master_optimizer_reports"

GENERATE_ROUTE = REPO_ROOT / "server" / "routes" / "ai" / "generate" / "index.dart"
OPTIMIZE_ROUTE = REPO_ROOT / "server" / "routes" / "ai" / "optimize" / "index.dart"
COMMANDER_CONTRACT = (
    REPO_ROOT / "server" / "lib" / "ai" / "commander_deckbuilding_contract_support.dart"
)
COMMANDER_LEARNING_SNAPSHOT = (
    REPO_ROOT / "server" / "lib" / "ai" / "commander_learning_snapshot_support.dart"
)
OPTIMIZE_REQUEST_SUPPORT = (
    REPO_ROOT / "server" / "lib" / "ai" / "optimize_request_support.dart"
)
OPTIMIZE_SWAP_CANDIDATE_SUPPORT = (
    REPO_ROOT / "server" / "lib" / "ai" / "optimize_swap_candidate_support.dart"
)
OPTIMIZE_RESPONSE_SUPPORT = (
    REPO_ROOT / "server" / "lib" / "ai" / "optimize_response_support.dart"
)
OPTIMIZATION_QUALITY_GATE = (
    REPO_ROOT / "server" / "lib" / "ai" / "optimization_quality_gate.dart"
)
APP_GENERATE_SCREEN = (
    REPO_ROOT / "app" / "lib" / "features" / "decks" / "screens" / "deck_generate_screen.dart"
)
APP_OPTIMIZE_FLOW_SUPPORT = (
    REPO_ROOT
    / "app"
    / "lib"
    / "features"
    / "decks"
    / "widgets"
    / "deck_optimize_flow_support.dart"
)
AI_PROMPT_EVAL_SUITE = (
    REPO_ROOT / "server" / "lib" / "ai" / "commander_ai_prompt_eval_suite.dart"
)
AI_PROMPT_EVAL_BIN = REPO_ROOT / "server" / "bin" / "commander_ai_prompt_eval.dart"
AI_PROMPT_EVAL_FIXTURE = (
    REPO_ROOT / "server" / "test" / "fixtures" / "commander_ai_prompt_eval_cases.json"
)
AI_PROMPT_EVAL_TEST = REPO_ROOT / "server" / "test" / "commander_ai_prompt_eval_suite_test.dart"
AI_PROMPT_EVAL_SCRIPT = REPO_ROOT / "scripts" / "manaloom_ai_prompt_eval.sh"
QUALITY_GATE = REPO_ROOT / "scripts" / "quality_gate.sh"
APP_AI_BRIDGE_DOC = DOCS_DIR / "APP_AI_KNOWLEDGE_BRIDGE_CONTRACT_2026-07-06.md"
XMAGE_FLOW = DOCS_DIR / "XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md"
DECKBUILDING_CONTRACT_DOC = DOCS_DIR / "COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"

ACTIVE_FILES = [
    GENERATE_ROUTE,
    OPTIMIZE_ROUTE,
    COMMANDER_CONTRACT,
    COMMANDER_LEARNING_SNAPSHOT,
    OPTIMIZE_REQUEST_SUPPORT,
    OPTIMIZE_SWAP_CANDIDATE_SUPPORT,
    OPTIMIZE_RESPONSE_SUPPORT,
    OPTIMIZATION_QUALITY_GATE,
    APP_GENERATE_SCREEN,
    APP_OPTIMIZE_FLOW_SUPPORT,
    AI_PROMPT_EVAL_SUITE,
    AI_PROMPT_EVAL_BIN,
    AI_PROMPT_EVAL_FIXTURE,
    AI_PROMPT_EVAL_TEST,
    AI_PROMPT_EVAL_SCRIPT,
    QUALITY_GATE,
    APP_AI_BRIDGE_DOC,
    XMAGE_FLOW,
    DECKBUILDING_CONTRACT_DOC,
]

GENERATE_ROUTE_REQUIRED = [
    "loadUsableCommanderReferenceProfile(",
    "loadUsableCommanderReferenceCardStats(",
    "loadCommanderReferenceDeckCorpusGuidance(",
    "loadUsageHotCards(",
    "loadActiveCommanderLearnedDeck(",
    "activeCommanderLearnedDeckCardNames(activeLearnedDeck)",
    "buildCommanderDeckbuildingContractDiagnostics(",
    "'deckbuilding_contract': deckbuildingContractDiagnostics",
    "'semantic_layer_v2': _buildSemanticLayerV2GenerateSummary(",
    "GeneratedDeckValidationService(",
]

COMMANDER_CONTRACT_REQUIRED = [
    "commanderDeckPlanningFlow",
    "commanderDeckPlanningLaneOrder",
    "commanderDeckOverviewRequiredFields",
    "source_hierarchy",
    "battle_gate_status",
    "buildCommanderDeckbuildingAppSummary",
    "commanderDeckbuildingAppSummaryVersion",
]

OPTIMIZE_CONSUMER_REQUIRED = {
    OPTIMIZE_REQUEST_SUPPORT: [
        "_hasTable(pool, 'card_intelligence_snapshot')",
        "JOIN card_intelligence_snapshot c ON c.card_id = dc.card_id",
        "card_semantic_tags_v2",
        "card_function_tags",
    ],
    OPTIMIZE_SWAP_CANDIDATE_SUPPORT: [
        "LEFT JOIN card_intelligence_snapshot cis ON cis.card_id = c.id",
        "ranked_before_quality_gate",
    ],
    OPTIMIZE_RESPONSE_SUPPORT: [
        "'semantic_layer_v2': semanticsDiagnostics",
        "response['semantic_layer_v2'] = semanticLayerV2",
    ],
    OPTIMIZATION_QUALITY_GATE: [
        "card_function_tags",
        "optimizationFunctionalRolesForCard(card, semanticOnly: true)",
        "_persistedFunctionalTagsForGate",
    ],
    OPTIMIZE_ROUTE: [
        "optimize_diagnostics",
        "withOptimizationSemanticV2EnforcementDiagnostics",
        "optimize_route_final_gate",
        "optimize_route_quality_rejection",
    ],
}

PROMPT_EVAL_REQUIRED = {
    AI_PROMPT_EVAL_SUITE: [
        "battle_evidence_allowed",
        "_containsUnsupportedBattleClaim",
        "blocked_pairs",
        "protected_cards",
        "role_delta_at_least",
        "budget_limit_respected",
        "collection_preference_respected",
    ],
    AI_PROMPT_EVAL_BIN: [
        "commander_ai_prompt_eval.dart",
        "--fixtures",
        "--response",
        "--minimum-score",
        "--out-prefix",
    ],
    AI_PROMPT_EVAL_SCRIPT: [
        "MANALOOM_AI_PROMPT_EVAL_OUT_PREFIX",
        "dart run bin/commander_ai_prompt_eval.dart",
    ],
    AI_PROMPT_EVAL_FIXTURE: [
        "kaalia_collection_budget_bracket3",
        "lorehold_protected_anchor_bracket2",
        "atraxa_budget_curve_no_cedh",
        "blocked_pairs",
        "candidate_response",
    ],
    AI_PROMPT_EVAL_TEST: [
        "passes all fixed product eval cases",
        "blocks exact add/cut pairs rejected by battle feedback",
        "fails responses without rich swap explanation",
    ],
    QUALITY_GATE: [
        "run_ai_prompt_eval",
        "ai-eval",
        "manaloom_ai_prompt_eval.sh",
    ],
}

APP_SANITIZATION_REQUIRED = {
    APP_GENERATE_SCREEN: [
        "sourceDisplayLabel",
        "Deck aprendido Hermes",
        "normalized.contains('hermes')",
        "normalized.contains('learned_deck')",
        "normalized.contains('commander_learning')",
        "normalized.contains('pg_commander')",
    ],
    APP_OPTIMIZE_FLOW_SUPPORT: [
        "AggressiveCandidateQualityDiagnostics",
        "friendlyRejectedBucketLabel",
        "quality_gate_rejected",
        "userFacingReasons",
    ],
}

LEARNING_SNAPSHOT_REQUIRED = [
    "CREATE OR REPLACE VIEW commander_learning_snapshot AS",
    "FROM commander_learned_decks",
    "FROM commander_card_usage",
    "FROM commander_card_synergy",
    "FROM card_identity_bridge",
    "'metadata_hidden', TRUE",
]

DOC_CONTRACT_REQUIRED = {
    XMAGE_FLOW: [
        "resolved local XMage source is final behavior truth",
        "candidate becomes executable ManaLoom battle truth",
        "matching runtime adapter exists",
        "server/bin/with_new_server_pg.sh",
    ],
    DECKBUILDING_CONTRACT_DOC: [
        "Research-Backed Deck Planning Flow",
        "Lane Order And Deck Overview Contract",
        "Global Commander Core Pivot",
        "keeps deck `607` as benchmark/regression only",
    ],
    APP_AI_BRIDGE_DOC: [
        "Status: `active_operating_contract`",
        "PostgreSQL/backend is the product truth surface",
        "Reports are evidence only",
        "./scripts/quality_gate.sh ai-bridge",
    ],
}

FORBIDDEN_APP_RAW_METADATA = [
    "Origem: HERMES learned_deck",
    "promoted_learned_deck_pg",
    "pg_commander_learned_decks",
    "learned_deck:",
]

FORBIDDEN_RUNTIME_REPORT_CONSUMPTION = [
    "master_optimizer_reports",
    "docs/hermes-analysis/master_optimizer_reports",
    "APP_AI_KNOWLEDGE_BRIDGE_CONTRACT_2026-07-06.md",
]


@dataclass
class Check:
    name: str
    status: str
    detail: str
    data: dict[str, Any] | None = None

    def as_dict(self) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "name": self.name,
            "status": self.status,
            "detail": self.detail,
        }
        if self.data is not None:
            payload["data"] = self.data
        return payload


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def compact_contract_source(value: str) -> str:
    return re.sub(r"\s+", "", value).replace(",)", ")")


def check_active_files_exist(files: Iterable[Path] = ACTIVE_FILES) -> Check:
    file_list = list(files)
    missing = [rel(path) for path in file_list if not path.exists()]
    if missing:
        return Check("active_files.exist", "fail", f"missing={json.dumps(missing)}")
    return Check("active_files.exist", "pass", f"count={len(file_list)}")


def check_contains(path: Path, snippets: Iterable[str], name: str) -> Check:
    if not path.exists():
        return Check(name, "fail", f"missing_file:{rel(path)}")
    text = read_text(path)
    compact_text = compact_contract_source(text)
    missing = [
        snippet
        for snippet in snippets
        if snippet not in text
        and compact_contract_source(snippet) not in compact_text
    ]
    if missing:
        return Check(
            name,
            "fail",
            "missing=" + json.dumps(missing, ensure_ascii=True),
            {"file": rel(path), "missing": missing},
        )
    return Check(name, "pass", rel(path))


def check_contains_map(mapping: dict[Path, list[str]], name_prefix: str) -> list[Check]:
    return [
        check_contains(path, snippets, f"{name_prefix}.{path.name}")
        for path, snippets in mapping.items()
    ]


def iter_source_files(roots: Iterable[Path], suffixes: tuple[str, ...]) -> list[Path]:
    files: list[Path] = []
    for root in roots:
        if not root.exists():
            continue
        if root.is_file() and root.suffix in suffixes:
            files.append(root)
            continue
        for suffix in suffixes:
            files.extend(root.rglob(f"*{suffix}"))
    return sorted(set(files))


def check_absent_in_files(
    files: Iterable[Path],
    snippets: Iterable[str],
    name: str,
) -> Check:
    hits: list[dict[str, Any]] = []
    for path in files:
        text = read_text(path)
        for snippet in snippets:
            start = text.find(snippet)
            if start < 0:
                continue
            hits.append(
                {
                    "file": rel(path),
                    "line": text.count("\n", 0, start) + 1,
                    "snippet": snippet,
                }
            )
    if hits:
        return Check(name, "fail", f"hits={len(hits)}", {"hits": hits})
    return Check(name, "pass", "no hits")


def app_files() -> list[Path]:
    return iter_source_files([REPO_ROOT / "app" / "lib"], (".dart",))


def runtime_consumer_files() -> list[Path]:
    return iter_source_files(
        [
            REPO_ROOT / "server" / "routes" / "ai",
            REPO_ROOT / "server" / "lib" / "ai",
            REPO_ROOT / "app" / "lib",
        ],
        (".dart",),
    )


def build_checks() -> list[Check]:
    return [
        check_active_files_exist(),
        check_contains(
            GENERATE_ROUTE,
            GENERATE_ROUTE_REQUIRED,
            "backend.generate_route_uses_promoted_knowledge_surfaces",
        ),
        check_contains(
            COMMANDER_CONTRACT,
            COMMANDER_CONTRACT_REQUIRED,
            "backend.commander_contract_exposes_app_safe_diagnostics",
        ),
        check_contains(
            COMMANDER_LEARNING_SNAPSHOT,
            LEARNING_SNAPSHOT_REQUIRED,
            "backend.commander_learning_snapshot_hides_raw_metadata",
        ),
        *check_contains_map(OPTIMIZE_CONSUMER_REQUIRED, "backend.optimize_consumer"),
        *check_contains_map(PROMPT_EVAL_REQUIRED, "quality.prompt_eval"),
        *check_contains_map(APP_SANITIZATION_REQUIRED, "app.sanitized_diagnostics"),
        *check_contains_map(DOC_CONTRACT_REQUIRED, "docs.bridge_contract"),
        check_absent_in_files(
            app_files(),
            FORBIDDEN_APP_RAW_METADATA,
            "app.no_raw_hermes_or_learned_metadata_strings",
        ),
        check_absent_in_files(
            runtime_consumer_files(),
            FORBIDDEN_RUNTIME_REPORT_CONSUMPTION,
            "runtime.no_report_md_as_product_truth",
        ),
    ]


def build_report() -> dict[str, Any]:
    checks = build_checks()
    status_counts: dict[str, int] = {}
    for check in checks:
        status_counts[check.status] = status_counts.get(check.status, 0) + 1
    status = "fail" if status_counts.get("fail", 0) else "pass"
    return {
        "generated_at": utc_now(),
        "status": status,
        "summary": {
            "check_count": len(checks),
            "status_counts": status_counts,
            "active_file_count": len(ACTIVE_FILES),
        },
        "checks": [check.as_dict() for check in checks],
        "mutations_performed": [],
    }


def write_markdown(report: dict[str, Any], path: Path) -> None:
    lines = [
        "# App AI Knowledge Bridge Audit",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        f"- Summary: `{json.dumps(report['summary'], sort_keys=True)}`",
        "",
        "| Check | Status | Detail |",
        "| --- | --- | --- |",
    ]
    for check in report["checks"]:
        detail = str(check.get("detail") or "").replace("|", "\\|")
        lines.append(f"| `{check['name']}` | `{check['status']}` | {detail} |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "app_ai_knowledge_bridge_audit_20260706",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_report()
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    write_markdown(report, md_path)
    print(
        json.dumps(
            {"status": report["status"], "json": str(json_path), "markdown": str(md_path)}
        )
    )
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
