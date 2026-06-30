#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from types import SimpleNamespace
from typing import Any

import deck_card_battle_rule_coherence_audit as coherence
import materialize_learned_deck_to_deck_cards as materializer
import xmage_batch_validity_audit as validity_audit
import xmage_effect_json_batch_generator as proposal_generator
import xmage_local_rule_indexer as local_indexer
import xmage_pattern_registry_builder as pattern_registry_builder
import xmage_semantic_family_classifier as family_classifier
from master_optimizer_common import resolve_default_knowledge_db


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_REPORT_DIR = SCRIPT_DIR.parent.parent / "master_optimizer_reports"
DEFAULT_BATTLE_ARTIFACT_DIR = Path(
    "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest"
)
DEFAULT_XMAGE_ROOT = Path("/Users/desenvolvimentomobile/Downloads/mage-master")


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def compact_timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")


def parse_source_ref(value: str) -> tuple[str, int] | None:
    text = str(value or "").strip()
    if ":" not in text:
        return None
    kind, raw_id = text.split(":", 1)
    kind = kind.strip()
    raw_id = raw_id.strip()
    if kind not in {"deck_id", "learned_deck"} or not raw_id.isdigit():
        return None
    return kind, int(raw_id)


def deck_targets_from_latest_artifact(artifact_dir: Path) -> dict[str, Any]:
    seeds = sorted(artifact_dir.glob("seed_*/deck_provenance.json"))
    if not seeds:
        raise SystemExit(f"no deck_provenance.json found under {artifact_dir}")

    deck_ids: set[int] = set()
    learned_deck_ids: set[int] = set()
    source_names: dict[str, str] = {}
    seed_map: dict[str, list[str]] = {}

    for path in seeds:
        payload = json.loads(path.read_text(encoding="utf-8"))
        seed_name = path.parent.name
        refs: list[str] = []
        for deck in payload.get("decks", []):
            if not isinstance(deck, dict):
                continue
            source_ref = str(deck.get("source_ref") or "").strip()
            parsed = parse_source_ref(source_ref)
            if not parsed:
                continue
            refs.append(source_ref)
            source_names[source_ref] = str(deck.get("name") or source_ref)
            kind, source_id = parsed
            if kind == "deck_id":
                deck_ids.add(source_id)
            else:
                learned_deck_ids.add(source_id)
        seed_map[seed_name] = sorted(set(refs))

    return {
        "artifact_dir": str(artifact_dir.resolve()),
        "generated_at": utc_now(),
        "deck_ids": sorted(deck_ids),
        "learned_deck_ids": sorted(learned_deck_ids),
        "source_names": dict(sorted(source_names.items())),
        "seed_map": seed_map,
    }


def aggregate_scope(deck_targets: dict[str, Any], include_deck_ids: list[int]) -> dict[str, Any]:
    artifact_deck_ids = sorted(set(int(deck_id) for deck_id in deck_targets.get("deck_ids", [])))
    learned_deck_ids = sorted(set(int(deck_id) for deck_id in deck_targets.get("learned_deck_ids", [])))
    forced_deck_ids = sorted(set(int(deck_id) for deck_id in include_deck_ids))
    effective_deck_ids = sorted(set(artifact_deck_ids) | set(learned_deck_ids) | set(forced_deck_ids))
    return {
        "artifact_deck_ids": artifact_deck_ids,
        "learned_deck_ids": learned_deck_ids,
        "forced_include_deck_ids": forced_deck_ids,
        "effective_deck_ids": effective_deck_ids,
    }


def merge_usage_maps(
    usage_maps: list[dict[str, coherence.DeckCardUsage]],
) -> dict[str, coherence.DeckCardUsage]:
    merged: dict[str, coherence.DeckCardUsage] = {}
    for usage_map in usage_maps:
        for normalized, usage in usage_map.items():
            existing = merged.get(normalized)
            if existing is None:
                merged[normalized] = coherence.DeckCardUsage(
                    normalized_name=usage.normalized_name,
                    display_name=usage.display_name,
                    deck_ids=list(usage.deck_ids),
                    total_quantity=int(usage.total_quantity),
                    deck_count=int(usage.deck_count),
                    commander_count=int(usage.commander_count),
                    type_lines=list(usage.type_lines),
                    oracle_texts=list(usage.oracle_texts),
                    battle_rules_json_count=int(usage.battle_rules_json_count),
                )
                continue
            merged[normalized] = coherence.DeckCardUsage(
                normalized_name=existing.normalized_name,
                display_name=existing.display_name or usage.display_name,
                deck_ids=sorted(set(existing.deck_ids) | set(usage.deck_ids)),
                total_quantity=int(existing.total_quantity) + int(usage.total_quantity),
                deck_count=0,
                commander_count=int(existing.commander_count) + int(usage.commander_count),
                type_lines=sorted(set(existing.type_lines) | set(usage.type_lines)),
                oracle_texts=sorted(set(existing.oracle_texts) | set(usage.oracle_texts)),
                battle_rules_json_count=int(existing.battle_rules_json_count)
                + int(usage.battle_rules_json_count),
            )

    for normalized, usage in list(merged.items()):
        merged[normalized] = coherence.DeckCardUsage(
            normalized_name=usage.normalized_name,
            display_name=usage.display_name,
            deck_ids=sorted(set(usage.deck_ids)),
            total_quantity=usage.total_quantity,
            deck_count=len(set(usage.deck_ids)),
            commander_count=usage.commander_count,
            type_lines=usage.type_lines,
            oracle_texts=usage.oracle_texts,
            battle_rules_json_count=usage.battle_rules_json_count,
        )
    return merged


def combined_coherence_report(
    conn: sqlite3.Connection,
    *,
    deck_ids: list[int],
    source_targets: dict[str, Any],
) -> dict[str, Any]:
    usage_maps = [coherence.load_deck_card_usage(conn, deck_id=deck_id) for deck_id in deck_ids]
    usage = merge_usage_maps(usage_maps)
    oracle_cache = coherence.load_oracle_cache(conn)
    rules = coherence.load_battle_rules(conn)
    cards = [
        coherence.classify_card(card, oracle_cache.get(normalized), rules.get(normalized, []))
        for normalized, card in usage.items()
    ]
    cards.sort(
        key=lambda card: (
            coherence.SEVERITY_ORDER[card["severity"]],
            int(card["impact_rank"]),
            -int(card["priority_score"]),
            str(card["card_name"]).lower(),
        )
    )
    severity_counts = Counter(card["severity"] for card in cards)
    finding_counts = Counter(
        finding["code"]
        for card in cards
        for finding in card["findings"]
        if finding["code"] != "coherent_for_current_gate"
    )
    return {
        "generated_at": utc_now(),
        "source": "sqlite_hermes_knowledge_db",
        "scope": "distinct_cards_referenced_by_current_lorehold_and_latest_replay_opponents",
        "deck_id": None,
        "source_deck_ids": deck_ids,
        "source_targets": source_targets,
        "total_cards": len(cards),
        "severity_counts": dict(sorted(severity_counts.items())),
        "finding_counts": dict(finding_counts.most_common()),
        "cards": cards,
    }


def actionable_card_names(report: dict[str, Any]) -> list[str]:
    return [
        str(card.get("card_name") or "").strip()
        for card in report.get("cards", [])
        if isinstance(card, dict) and card.get("severity") in {"critical", "high", "medium"}
    ]


def materialize_latest_learned_decks(
    *,
    sqlite_db: Path,
    learned_deck_ids: list[int],
    apply: bool,
) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    for learned_deck_id in learned_deck_ids:
        args = SimpleNamespace(
            sqlite_db=str(sqlite_db),
            learned_deck_id=int(learned_deck_id),
            target_deck_id=None,
            min_cards=100,
            fill_basic="Mountain",
            allow_fill_basic=False,
            apply=apply,
        )
        results.append(materializer.materialize(args))
    return results


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_markdown(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def markdown_manifest(manifest: dict[str, Any]) -> str:
    lines = [
        "# XMage Current Replay Batch Pipeline",
        "",
        f"Generated at: `{manifest['generated_at']}`",
        "",
        f"- Artifact dir: `{manifest['battle_artifact_dir']}`",
        f"- XMage root: `{manifest['xmage_root']}`",
        f"- SQLite DB: `{manifest['sqlite_db']}`",
        f"- Artifact deck ids: `{json.dumps(manifest['aggregate_scope']['artifact_deck_ids'])}`",
        f"- Learned deck ids: `{json.dumps(manifest['aggregate_scope']['learned_deck_ids'])}`",
        f"- Forced include deck ids: `{json.dumps(manifest['aggregate_scope']['forced_include_deck_ids'])}`",
        f"- Effective deck ids: `{json.dumps(manifest['aggregate_scope']['effective_deck_ids'])}`",
        f"- Combined severity counts: `{json.dumps(manifest['combined_coherence']['severity_counts'], sort_keys=True)}`",
        f"- Validity status counts: `{json.dumps(manifest['validity_audit']['summary']['status_counts'], sort_keys=True)}`",
        f"- Family counts: `{json.dumps(manifest['family_report']['summary']['family_counts'], sort_keys=True)}`",
        f"- Proposal status counts: `{json.dumps(manifest['proposal_report']['summary']['proposal_status_counts'], sort_keys=True)}`",
        f"- Pattern status counts: `{json.dumps(manifest['pattern_registry']['summary']['pattern_status_counts'], sort_keys=True)}`",
        f"- Pattern promotion status: `{manifest['pattern_registry']['summary']['promotion_status']}`",
        "",
        "## Materialized Learned Decks",
        "",
        "| learned_deck_id | target_deck_id | deck_name | rows | quantity | oracle_rows |",
        "| --- | ---: | --- | ---: | ---: | ---: |",
    ]
    for row in manifest.get("materialization", []):
        lines.append(
            f"| {row['learned_deck_id']} | {row['target_deck_id']} | `{row['deck_name']}` | "
            f"{row['rows']} | {row['quantity']} | {row['oracle_rows']} |"
        )
    lines.extend(["", "## Output Files", ""])
    for key, value in manifest.get("files", {}).items():
        lines.append(f"- `{key}`: `{value}`")
    return "\n".join(lines).rstrip() + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sqlite-db", default=str(DEFAULT_DB))
    parser.add_argument("--battle-artifact-dir", default=str(DEFAULT_BATTLE_ARTIFACT_DIR))
    parser.add_argument("--xmage-root", default=str(DEFAULT_XMAGE_ROOT))
    parser.add_argument(
        "--include-deck-id",
        type=int,
        action="append",
        default=[6],
        help="Additional deck_ids to force into the aggregate scope.",
    )
    parser.add_argument(
        "--external-harvest",
        help="Optional external card reference harvest JSON used for oracle_hash and metadata enrichment.",
    )
    parser.add_argument(
        "--skip-materialize",
        action="store_true",
        help="Do not apply learned_deck -> deck_cards materialization before auditing.",
    )
    parser.add_argument("--output-prefix")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    sqlite_db = Path(args.sqlite_db)
    artifact_dir = Path(args.battle_artifact_dir)
    xmage_root = Path(args.xmage_root)
    external_harvest = family_classifier.load_json(Path(args.external_harvest)) if args.external_harvest else None
    timestamp = compact_timestamp()
    output_prefix = Path(
        args.output_prefix
        or DEFAULT_REPORT_DIR / f"xmage_current_replay_batch_pipeline_{timestamp}"
    )

    deck_targets = deck_targets_from_latest_artifact(artifact_dir)
    include_deck_ids = sorted(set(int(deck_id) for deck_id in args.include_deck_id))
    scope = aggregate_scope(deck_targets, include_deck_ids)
    deck_ids = scope["effective_deck_ids"]

    materialization = materialize_latest_learned_decks(
        sqlite_db=sqlite_db,
        learned_deck_ids=deck_targets["learned_deck_ids"],
        apply=not args.skip_materialize,
    )

    with sqlite3.connect(sqlite_db) as conn:
        conn.row_factory = sqlite3.Row
        combined = combined_coherence_report(
            conn,
            deck_ids=deck_ids,
            source_targets=deck_targets,
        )

    index_report = local_indexer.build_index_report(
        actionable_card_names(combined),
        xmage_root=xmage_root,
        source={
            "kind": "current_replay_combined_coherence_report",
            "deck_ids": deck_ids,
            "battle_artifact_dir": str(artifact_dir.resolve()),
            "severity_counts": combined["severity_counts"],
        },
    )
    validity_report = validity_audit.build_audit(
        coherence_report=combined,
        xmage_index=index_report,
        external_harvest=external_harvest,
    )
    family_report = family_classifier.build_family_report(validity_report)
    proposal_report = proposal_generator.build_generator_report(
        batch_audit=validity_report,
        external_harvest=external_harvest,
    )
    pattern_registry_report = pattern_registry_builder.build_report(
        proposal_report=proposal_report,
        report_dir=DEFAULT_REPORT_DIR,
    )

    files = {
        "manifest_json": str(output_prefix.with_name(output_prefix.name + "_manifest.json")),
        "manifest_md": str(output_prefix.with_name(output_prefix.name + "_manifest.md")),
        "combined_coherence_json": str(output_prefix.with_name(output_prefix.name + "_combined_coherence.json")),
        "combined_coherence_md": str(output_prefix.with_name(output_prefix.name + "_combined_coherence.md")),
        "xmage_index_json": str(output_prefix.with_name(output_prefix.name + "_xmage_index.json")),
        "xmage_index_md": str(output_prefix.with_name(output_prefix.name + "_xmage_index.md")),
        "validity_json": str(output_prefix.with_name(output_prefix.name + "_validity.json")),
        "validity_md": str(output_prefix.with_name(output_prefix.name + "_validity.md")),
        "families_json": str(output_prefix.with_name(output_prefix.name + "_families.json")),
        "families_md": str(output_prefix.with_name(output_prefix.name + "_families.md")),
        "proposals_json": str(output_prefix.with_name(output_prefix.name + "_proposals.json")),
        "proposals_md": str(output_prefix.with_name(output_prefix.name + "_proposals.md")),
        "pattern_registry_json": str(output_prefix.with_name(output_prefix.name + "_pattern_registry.json")),
        "pattern_registry_md": str(output_prefix.with_name(output_prefix.name + "_pattern_registry.md")),
    }

    write_json(Path(files["combined_coherence_json"]), combined)
    write_markdown(Path(files["combined_coherence_md"]), coherence.markdown_report(combined, 120))
    local_indexer.write_report(index_report, Path(files["xmage_index_json"]), Path(files["xmage_index_md"]))
    validity_audit.write_report(validity_report, Path(files["validity_json"]), Path(files["validity_md"]))
    family_classifier.write_report(family_report, Path(files["families_json"]), Path(files["families_md"]))
    proposal_generator.write_report(proposal_report, Path(files["proposals_json"]), Path(files["proposals_md"]))
    write_json(Path(files["pattern_registry_json"]), pattern_registry_report)
    write_markdown(Path(files["pattern_registry_md"]), pattern_registry_builder.render_markdown(pattern_registry_report))

    manifest = {
        "generated_at": utc_now(),
        "battle_artifact_dir": str(artifact_dir.resolve()),
        "sqlite_db": str(sqlite_db),
        "xmage_root": str(xmage_root.resolve()),
        "deck_targets": deck_targets,
        "aggregate_scope": scope,
        "materialization": materialization,
        "combined_coherence": {
            "total_cards": combined["total_cards"],
            "severity_counts": combined["severity_counts"],
        },
        "validity_audit": {
            "summary": validity_report["summary"],
        },
        "family_report": {
            "summary": family_report["summary"],
        },
        "proposal_report": {
            "summary": proposal_report["summary"],
        },
        "pattern_registry": {
            "summary": pattern_registry_report["summary"],
            "registry_contract": pattern_registry_report["registry_contract"],
        },
        "files": files,
    }
    write_json(Path(files["manifest_json"]), manifest)
    write_markdown(Path(files["manifest_md"]), markdown_manifest(manifest))

    print(f"manifest_json={files['manifest_json']}")
    print(f"combined_coherence_json={files['combined_coherence_json']}")
    print(f"xmage_index_json={files['xmage_index_json']}")
    print(f"validity_json={files['validity_json']}")
    print(f"families_json={files['families_json']}")
    print(f"proposals_json={files['proposals_json']}")
    print(f"pattern_registry_json={files['pattern_registry_json']}")
    print(f"deck_ids={json.dumps(deck_ids)}")
    print(f"severity_counts={json.dumps(combined['severity_counts'], sort_keys=True)}")
    print(f"validity_status_counts={json.dumps(validity_report['summary']['status_counts'], sort_keys=True)}")
    print(f"family_counts={json.dumps(family_report['summary']['family_counts'], sort_keys=True)}")
    print(f"proposal_status_counts={json.dumps(proposal_report['summary']['proposal_status_counts'], sort_keys=True)}")
    print(f"pattern_status_counts={json.dumps(pattern_registry_report['summary']['pattern_status_counts'], sort_keys=True)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
