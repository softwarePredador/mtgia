#!/usr/bin/env python3
"""Audit source strategy for faster Oracle, battle-rule, and deckbuilding work.

The goal is not to make the internet part of CI. External research establishes
which source is useful for each ManaLoom need; this script then checks that the
repo has deterministic local entrypoints for the corresponding workflow.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_REPO_ROOT = SCRIPT_DIR.parents[3]


@dataclass(frozen=True)
class SourceCapability:
    id: str
    name: str
    url: str
    authority: str
    best_for: tuple[str, ...]
    not_for: tuple[str, ...]
    access_model: str
    cache_policy: str


@dataclass(frozen=True)
class ProjectNeed:
    id: str
    title: str
    required_sources: tuple[str, ...]
    supporting_sources: tuple[str, ...]
    required_local_paths: tuple[str, ...]
    required_keywords: tuple[tuple[str, ...], ...]
    implementation_rule: str
    acceleration_value: int
    risk_if_missing: str


SOURCE_CAPABILITIES: tuple[SourceCapability, ...] = (
    SourceCapability(
        id="scryfall_bulk_oracle",
        name="Scryfall bulk Oracle Cards and Rulings",
        url="https://api.scryfall.com/bulk-data",
        authority="card_metadata_high",
        best_for=("oracle_identity_faces", "oracle_text", "layout", "rulings"),
        not_for=("turn_rules", "battle_outcome", "commander_meta"),
        access_model="bulk_or_named_api",
        cache_policy="cache bulk snapshots; use named lookups only for focused gaps",
    ),
    SourceCapability(
        id="mtgjson_v5",
        name="MTGJSON v5",
        url="https://mtgjson.com/api/v5/",
        authority="card_metadata_aggregate",
        best_for=("bulk_cards", "legalities", "rulings", "identifiers"),
        not_for=("battle_execution_truth", "player_intent"),
        access_model="bulk_download",
        cache_policy="cache AtomicCards/AllPrintings; never fetch per-card in hot path",
    ),
    SourceCapability(
        id="wotc_comprehensive_rules",
        name="Wizards Comprehensive Rules",
        url="https://magic.wizards.com/en/rules",
        authority="official_rules",
        best_for=("turn_rules", "priority", "stack", "layers", "state_based_actions"),
        not_for=("card_popularity", "deck_strength", "observed_player_behavior"),
        access_model="versioned_rules_document",
        cache_policy="pin rules version in tests and update intentionally",
    ),
    SourceCapability(
        id="xmage_local_source",
        name="Local XMage source tree",
        url="file:///Users/desenvolvimentomobile/Downloads/mage-master",
        authority="implementation_reference_not_authority",
        best_for=("battle_family_mapping", "card_implementation_examples", "test_scenarios"),
        not_for=("official_rules_override", "direct_pg_promotion_without_tests"),
        access_model="local_java_source",
        cache_policy="index locally and map by semantic family",
    ),
    SourceCapability(
        id="forge_engine",
        name="Forge rules engine",
        url="https://github.com/Card-Forge/forge",
        authority="independent_engine_crosscheck",
        best_for=("battle_family_crosscheck", "implementation_disagreement_detection"),
        not_for=("official_rules_override", "deckbuilding_meta"),
        access_model="open_source",
        cache_policy="use as optional crosscheck when XMage is missing or ambiguous",
    ),
    SourceCapability(
        id="seventeenlands_public_data",
        name="17Lands public datasets",
        url="https://www.17lands.com/public_datasets",
        authority="observed_arena_limited_telemetry",
        best_for=("event_sequence_priors", "card_lifecycle_metrics", "draw_seen_cast_use_methodology"),
        not_for=("commander_meta", "oracle_text", "card_rules_authority"),
        access_model="public_datasets",
        cache_policy="cache snapshots; translate only general battle priors",
    ),
    SourceCapability(
        id="mtga_player_log",
        name="MTG Arena detailed Player.log",
        url="https://mtgarena-support.wizards.com/hc/en-us/articles/360000726823-Creating-Log-Files-on-PC-Mac-Steam",
        authority="local_user_telemetry",
        best_for=("local_replay_ingestion", "event_shape_reference", "turn_and_action_observation"),
        not_for=("public_bulk_corpus", "privacy_unsafe_raw_storage"),
        access_model="explicit_local_file",
        cache_policy="parse read-only and do not persist raw player identifiers",
    ),
    SourceCapability(
        id="commander_spellbook",
        name="Commander Spellbook bulk variants",
        url="https://json.commanderspellbook.com/variants.json",
        authority="combo_database",
        best_for=("combo_detection", "near_miss_combo_suggestions", "combo_piece_tags"),
        not_for=("non_combo_card_quality", "battle_rules_authority"),
        access_model="large_bulk_json",
        cache_policy="sync offline into card_combos; runtime reads PostgreSQL only",
    ),
    SourceCapability(
        id="edhrec_json",
        name="EDHREC JSON pages",
        url="https://json.edhrec.com/pages/commanders/lorehold-the-historian.json",
        authority="commander_deckbuilding_meta",
        best_for=("commander_roles", "average_deck_structure", "community_inclusion"),
        not_for=("oracle_rules", "battle_execution_truth"),
        access_model="public_json_pages",
        cache_policy="snapshot aggregate stats; never copy full decklists into prompts",
    ),
    SourceCapability(
        id="mtgtop8_edh_cedh",
        name="MTGTop8 EDH/cEDH event exports",
        url="https://www.mtgtop8.com/format?f=cEDH",
        authority="competitive_event_corpus",
        best_for=("competitive_reference_decks", "event_decklists", "meta_candidates"),
        not_for=("multiplayer_commander_default", "oracle_rules", "casual_role_targets"),
        access_model="public_event_pages",
        cache_policy="ingest through vetted meta_decks/candidate pipeline only",
    ),
    SourceCapability(
        id="edhtop16",
        name="EDHTop16 public tournament data",
        url="https://edhtop16.com/",
        authority="cedh_tournament_corpus",
        best_for=("cedh_reference_decks", "tournament_standings", "external_meta_candidates"),
        not_for=("casual_commander_default", "oracle_rules", "battle_execution_truth"),
        access_model="public_site_and_graphql",
        cache_policy="expand into external candidates, then promote only after validation",
    ),
    SourceCapability(
        id="cedh_decklist_database",
        name="cEDH Decklist Database",
        url="https://cedh-decklist-database.com/",
        authority="curated_cedh_reference",
        best_for=("cedh_archetype_reference", "known_shells", "power_lane_context"),
        not_for=("casual_commander_default", "card_rules", "raw_prompt_deck_copy"),
        access_model="public_curated_site",
        cache_policy="use for research/context until an approved importer exists",
    ),
    SourceCapability(
        id="archidekt_public_decks",
        name="Archidekt public deck pages",
        url="https://archidekt.com/",
        authority="community_deck_corpus_candidate",
        best_for=("community_reference_decks", "package_discovery", "human_deckbuilding_examples"),
        not_for=("oracle_rules", "battle_execution_truth", "unguarded_prompt_copy"),
        access_model="public_site",
        cache_policy="candidate only; sanitize and aggregate before persistence",
    ),
    SourceCapability(
        id="moxfield_public_decks",
        name="Moxfield public deck pages",
        url="https://www.moxfield.com/",
        authority="community_deck_corpus_candidate_blocked_in_probe",
        best_for=("community_reference_decks", "package_discovery", "human_deckbuilding_examples"),
        not_for=("oracle_rules", "battle_execution_truth", "unguarded_prompt_copy"),
        access_model="public_site_with_bot_protection",
        cache_policy="candidate only; current simple probe returned 403 so do not automate without approved access",
    ),
)


PROJECT_NEEDS: tuple[ProjectNeed, ...] = (
    ProjectNeed(
        id="oracle_identity_faces",
        title="Resolve Oracle identity, layout, and card faces in bulk",
        required_sources=("scryfall_bulk_oracle", "mtgjson_v5"),
        supporting_sources=(),
        required_local_paths=(
            "server/bin/backfill_card_identity_columns.dart",
            "server/bin/plan_oracle_text_backfill.py",
            "server/lib/card_identity_backfill_support.dart",
        ),
        required_keywords=(
            ("oracle_id", "layout", "card_faces_json"),
            ("cards/collection", "Scryfall Collection"),
            ("scryfall_lookup_attempts", "exact_front_face"),
        ),
        implementation_rule="Bulk identity first; named/fuzzy lookup only for focused unresolved gaps.",
        acceleration_value=100,
        risk_if_missing="MDFC/split/import-name gaps become manual card-by-card Oracle fixes.",
    ),
    ProjectNeed(
        id="oracle_rulings_hash",
        title="Keep rulings and Oracle hashes traceable before battle promotion",
        required_sources=("scryfall_bulk_oracle", "mtgjson_v5"),
        supporting_sources=("wotc_comprehensive_rules",),
        required_local_paths=(
            "server/bin/sync_rulings.dart",
            "docs/hermes-analysis/manaloom-knowledge/scripts/external_card_rule_reference_harvester.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py",
        ),
        required_keywords=(
            ("card_rulings", "comment_hash"),
            ("oracle_hash", "rule_version"),
        ),
        implementation_rule="Promote rules only when Oracle/ruling provenance is explicit.",
        acceleration_value=88,
        risk_if_missing="Generated or stale rules can look executable without trusted text provenance.",
    ),
    ProjectNeed(
        id="battle_runtime_family_mapping",
        title="Map card behavior by semantic family instead of one-off cards",
        required_sources=("wotc_comprehensive_rules", "xmage_local_source"),
        supporting_sources=("forge_engine", "scryfall_bulk_oracle"),
        required_local_paths=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/xmage_acceleration_strategy_benchmark.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py",
        ),
        required_keywords=(
            ("semantic", "family", "battle_model_scope"),
            ("package_ready", "runtime_family"),
        ),
        implementation_rule="Use XMage to propose families, then require ManaLoom focused runtime tests.",
        acceleration_value=95,
        risk_if_missing="The queue falls back to slow per-card manual implementation.",
    ),
    ProjectNeed(
        id="needs_review_execution_guard",
        title="Prevent uncertain generated rules from becoming hard battle behavior",
        required_sources=("wotc_comprehensive_rules",),
        supporting_sources=("xmage_local_source", "forge_engine"),
        required_local_paths=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_registry_runtime_safe.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py",
        ),
        required_keywords=(
            ("needs_review", "review_only"),
            ("runtime_safe", "execution_status"),
        ),
        implementation_rule="Review-only rules may explain; runtime-safe rules may execute.",
        acceleration_value=80,
        risk_if_missing="False positives contaminate battle learning and deck scoring.",
    ),
    ProjectNeed(
        id="observed_battle_log_learning",
        title="Learn sequence and card-lifecycle priors from real battle logs",
        required_sources=("seventeenlands_public_data",),
        supporting_sources=("mtga_player_log",),
        required_local_paths=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/seventeenlands_history_learning.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/seventeenlands_general_absorption_audit.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_mtga_player_log_parser.py",
        ),
        required_keywords=(
            ("card_lifecycle", "use_after_access_rate"),
            ("Player.log", "raw_log_lines_persisted"),
        ),
        implementation_rule="Use logs for priors and validation metrics, never as Oracle or Commander truth.",
        acceleration_value=72,
        risk_if_missing="Battle tests keep measuring games where candidate cards were never drawn or used.",
    ),
    ProjectNeed(
        id="deckbuilding_combo_and_meta",
        title="Separate combo truth from Commander popularity and role structure",
        required_sources=("commander_spellbook", "edhrec_json"),
        supporting_sources=("scryfall_bulk_oracle",),
        required_local_paths=(
            "server/lib/ai/commander_spellbook_service.dart",
            "server/bin/sync_combos.dart",
            "server/lib/ai/edhrec_service.dart",
            "server/bin/snapshot_edhrec.dart",
            "server/lib/ai/optimization_quality_gate.dart",
        ),
        required_keywords=(
            ("card_combos", "nearMisses"),
            ("json.edhrec.com", "average-deck"),
            ("combo_piece", "criticalRoles"),
        ),
        implementation_rule="Spellbook proves combo relations; EDHREC calibrates structure and inclusion.",
        acceleration_value=90,
        risk_if_missing="Deckbuilder either misses real combo packages or overfits popularity as rules.",
    ),
    ProjectNeed(
        id="reference_deck_corpus_sanitization",
        title="Use external decklists only through sanitized Commander reference corpora",
        required_sources=("edhrec_json",),
        supporting_sources=(
            "mtgtop8_edh_cedh",
            "edhtop16",
            "cedh_decklist_database",
            "archidekt_public_decks",
            "moxfield_public_decks",
        ),
        required_local_paths=(
            "server/lib/ai/commander_reference_deck_corpus_support.dart",
            "server/bin/commander_reference_deck_corpus.dart",
            "server/lib/meta/mtgtop8_meta_support.dart",
            "server/bin/expand_external_commander_meta_candidates.dart",
            "server/bin/import_external_commander_meta_candidates.dart",
        ),
        required_keywords=(
            ("commander_reference_decks", "commander_reference_deck_cards"),
            ("source_url", "accepted"),
            ("MTGTop8", "EDHTop16"),
        ),
        implementation_rule="External decklists become aggregate role/package evidence, never raw prompt truth.",
        acceleration_value=82,
        risk_if_missing="Deckbuilder learns from unvetted deck copies or misses proven external shells.",
    ),
    ProjectNeed(
        id="source_conflict_resolution",
        title="Route source conflicts to the correct authority",
        required_sources=("wotc_comprehensive_rules", "scryfall_bulk_oracle", "xmage_local_source"),
        supporting_sources=("forge_engine", "mtgjson_v5"),
        required_local_paths=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/mtg_battle_external_source_audit.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_external_engine_crosscheck.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py",
        ),
        required_keywords=(
            ("authoritative", "non-authoritative"),
            ("crosscheck", "promotion_policy"),
        ),
        implementation_rule="Official rules and Oracle win; engines generate candidates and tests.",
        acceleration_value=84,
        risk_if_missing="A simulator disagreement can be promoted as truth without evidence.",
    ),
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=DEFAULT_REPO_ROOT)
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--fail-on-required-gaps", action="store_true")
    return parser.parse_args()


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=True, indent=2, sort_keys=True)


def _path_exists(repo_root: Path, relative: str) -> bool:
    return (repo_root / relative).is_file()


def _read_text(repo_root: Path, relative_paths: tuple[str, ...]) -> str:
    chunks: list[str] = []
    for relative in relative_paths:
        path = repo_root / relative
        if not path.is_file():
            continue
        try:
            chunks.append(path.read_text(encoding="utf-8"))
        except UnicodeDecodeError:
            chunks.append(path.read_text(encoding="utf-8", errors="ignore"))
    return "\n".join(chunks).lower()


def audit_need(repo_root: Path, need: ProjectNeed) -> dict[str, Any]:
    existing_paths = [
        path for path in need.required_local_paths if _path_exists(repo_root, path)
    ]
    missing_paths = [
        path for path in need.required_local_paths if not _path_exists(repo_root, path)
    ]
    combined = _read_text(repo_root, need.required_local_paths)
    keyword_hits: list[dict[str, Any]] = []
    missing_keyword_groups: list[list[str]] = []
    for group in need.required_keywords:
        found = [keyword for keyword in group if keyword.lower() in combined]
        if found:
            keyword_hits.append({"accepted_any_of": list(group), "found": found})
        else:
            missing_keyword_groups.append(list(group))

    if not missing_paths and not missing_keyword_groups:
        status = "covered"
    elif existing_paths and len(missing_keyword_groups) < len(need.required_keywords):
        status = "partial"
    else:
        status = "gap"

    return {
        **asdict(need),
        "status": status,
        "existing_paths": existing_paths,
        "missing_paths": missing_paths,
        "keyword_hits": keyword_hits,
        "missing_keyword_groups": missing_keyword_groups,
    }


def source_scores_for_need(need: ProjectNeed) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    required = set(need.required_sources)
    supporting = set(need.supporting_sources)
    for source in SOURCE_CAPABILITIES:
        if source.id in required:
            score = 100
            role = "required"
        elif source.id in supporting:
            score = 65
            role = "supporting"
        else:
            overlap = set(source.best_for).intersection({
                need.id,
                "oracle_identity_faces" if "oracle" in need.id else "",
                "battle_family_mapping" if "battle" in need.id else "",
                "combo_detection" if "combo" in need.id else "",
            })
            score = 35 if overlap else 0
            role = "adjacent" if overlap else "not_applicable"
        if score:
            rows.append(
                {
                    "source_id": source.id,
                    "source_name": source.name,
                    "role": role,
                    "score": score,
                    "authority": source.authority,
                }
            )
    return sorted(rows, key=lambda row: (-row["score"], row["source_id"]))


def build_audit(repo_root: Path = DEFAULT_REPO_ROOT) -> dict[str, Any]:
    repo_root = repo_root.resolve()
    needs = [audit_need(repo_root, need) for need in PROJECT_NEEDS]
    status_counts: dict[str, int] = {}
    for need in needs:
        status_counts[need["status"]] = status_counts.get(need["status"], 0) + 1

    gaps = [need for need in needs if need["status"] == "gap"]
    partials = [need for need in needs if need["status"] == "partial"]
    queue = sorted(
        [
            {
                "need_id": need["id"],
                "title": need["title"],
                "status": need["status"],
                "acceleration_value": need["acceleration_value"],
                "implementation_rule": need["implementation_rule"],
                "risk_if_missing": need["risk_if_missing"],
                "best_sources": source_scores_for_need(
                    next(item for item in PROJECT_NEEDS if item.id == need["id"])
                )[:4],
                "missing_paths": need["missing_paths"],
                "missing_keyword_groups": need["missing_keyword_groups"],
            }
            for need in needs
            if need["status"] != "covered"
        ],
        key=lambda row: (-row["acceleration_value"], row["need_id"]),
    )

    return {
        "generated_at_utc": utc_now(),
        "repo_root": str(repo_root),
        "postgres_writes": False,
        "summary": {
            "source_count": len(SOURCE_CAPABILITIES),
            "need_count": len(PROJECT_NEEDS),
            "status_counts": dict(sorted(status_counts.items())),
            "gap_count": len(gaps),
            "partial_count": len(partials),
            "gate_status": "pass" if not gaps else "fail",
            "top_acceleration_values": [
                {"need_id": need.id, "acceleration_value": need.acceleration_value}
                for need in sorted(
                    PROJECT_NEEDS,
                    key=lambda item: (-item.acceleration_value, item.id),
                )[:5]
            ],
        },
        "source_capabilities": [asdict(source) for source in SOURCE_CAPABILITIES],
        "needs": needs,
        "implementation_queue": queue,
        "source_scores_by_need": {
            need.id: source_scores_for_need(need) for need in PROJECT_NEEDS
        },
    }


def render_markdown(report: dict[str, Any]) -> str:
    summary = report["summary"]
    lines = [
        "# Card Oracle, Battle, and Deckbuilding Acceleration Audit",
        "",
        f"- Generated UTC: `{report['generated_at_utc']}`",
        f"- PostgreSQL writes: `{report['postgres_writes']}`",
        f"- Sources mapped: `{summary['source_count']}`",
        f"- Project needs audited: `{summary['need_count']}`",
        f"- Gate status: `{summary['gate_status']}`",
        f"- Gaps: `{summary['gap_count']}`",
        f"- Partials: `{summary['partial_count']}`",
        "",
        "## Source Roles",
        "",
        "| Source | Authority | Best for | Not for | Cache policy |",
        "| --- | --- | --- | --- | --- |",
    ]
    for source in report["source_capabilities"]:
        lines.append(
            "| [{name}]({url}) | `{authority}` | {best_for} | {not_for} | {cache_policy} |".format(
                name=source["name"],
                url=source["url"],
                authority=source["authority"],
                best_for=", ".join(source["best_for"]),
                not_for=", ".join(source["not_for"]),
                cache_policy=source["cache_policy"],
            )
        )

    lines.extend(
        [
            "",
            "## Local Coverage",
            "",
            "| Need | Status | Acceleration | Existing paths | Missing paths | Missing keyword groups |",
            "| --- | --- | ---: | ---: | ---: | ---: |",
        ]
    )
    for need in report["needs"]:
        lines.append(
            "| `{id}` | `{status}` | `{acceleration_value}` | `{existing}` | `{missing}` | `{missing_keywords}` |".format(
                id=need["id"],
                status=need["status"],
                acceleration_value=need["acceleration_value"],
                existing=len(need["existing_paths"]),
                missing=len(need["missing_paths"]),
                missing_keywords=len(need["missing_keyword_groups"]),
            )
        )

    lines.extend(["", "## Queue", ""])
    if not report["implementation_queue"]:
        lines.append("All required acceleration surfaces are covered.")
    else:
        for item in report["implementation_queue"]:
            lines.append(
                "- `{need_id}` ({status}, value {value}): {rule}".format(
                    need_id=item["need_id"],
                    status=item["status"],
                    value=item["acceleration_value"],
                    rule=item["implementation_rule"],
                )
            )
            if item["missing_paths"]:
                lines.append(f"  - Missing paths: `{', '.join(item['missing_paths'])}`")
            if item["missing_keyword_groups"]:
                lines.append(
                    "  - Missing keyword groups: `{}`".format(
                        json.dumps(item["missing_keyword_groups"], ensure_ascii=True)
                    )
                )

    lines.extend(
        [
            "",
            "## Operating Rules",
            "",
            "- Scryfall/MTGJSON resolve Oracle identity, faces, legalities, and rulings.",
            "- Wizards rules define battle semantics; XMage and Forge only propose implementation candidates.",
            "- Commander Spellbook proves combo relations; EDHREC calibrates Commander structure and inclusion.",
            "- 17Lands and MTGA logs provide behavior priors, not Commander truth or Oracle rules.",
            "- PostgreSQL remains the source of truth; Hermes/runtime mirrors must not overwrite reviewed DB state.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    report = build_audit(args.repo_root)
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(stable_json(report) + "\n", encoding="utf-8")
    markdown = render_markdown(report)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(markdown, encoding="utf-8")
    else:
        print(markdown)
    if args.fail_on_required_gaps and report["summary"]["gate_status"] != "pass":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
