#!/usr/bin/env python3
"""Read-only XMage engine inventory for ManaLoom absorption planning.

This scanner does not execute XMage, mutate PostgreSQL, mutate SQLite, or
promote card rules. It inventories the local XMage checkout so ManaLoom can
decide which source areas should be absorbed as rule/test contracts.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import external_engine_source_contract as engine_source_contract

DEFAULT_XMAGE_ROOT: Path | None = None
DEFAULT_REPORT_DIR = Path(__file__).resolve().parent.parent.parent / "master_optimizer_reports"
REPO_ROOT = Path(__file__).resolve().parents[4]
CANONICAL_XMAGE_PIN_FILE = REPO_ROOT / "services/xmage-sidecar/XMAGE_COMMIT"
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")


FACETS: dict[str, dict[str, Any]] = {
    "card_implementations": {
        "paths": ["Mage.Sets/src/mage/cards"],
        "why": "Per-card implementation classes are the fastest exact reference for card behavior.",
        "manaloom_use": "Reconcile against the pinned runtime catalog; externally covered cards execute in XMage, while source extraction diagnoses only focused tests or the explicit external residual.",
        "adoption": "diagnostic_after_pinned_catalog_reconciliation",
    },
    "effect_library": {
        "paths": ["Mage/src/main/java/mage/abilities/effects"],
        "why": "XMage's effect classes are reusable vocabulary for destroy, exile, copy, token, draw, prevention, replacement, and continuous effects.",
        "manaloom_use": "Use the taxonomy for replay conformance, focused residual tests, and native work only after XMage plus Forge coverage fails.",
        "adoption": "diagnostic_for_external_residual",
    },
    "ability_timing": {
        "paths": [
            "Mage/src/main/java/mage/abilities/common",
            "Mage/src/main/java/mage/abilities/triggers",
            "Mage/src/main/java/mage/abilities/keyword",
            "Mage/src/main/java/mage/abilities/mana",
        ],
        "why": "Ability classes encode static/triggered/activated/mana/timing semantics.",
        "manaloom_use": "Use ability classes to classify focused conformance scenarios without creating native rows for externally covered cards.",
        "adoption": "diagnostic_for_external_residual",
    },
    "costs_and_cost_adjusters": {
        "paths": [
            "Mage/src/main/java/mage/abilities/costs",
            "Mage/src/main/java/mage/abilities/effects/common/cost",
        ],
        "why": "Cost reducers, alternate costs, additional costs, X costs, and payment restrictions are common high-severity blockers.",
        "manaloom_use": "Use cost classes as focused conformance references and for the explicit native residual only.",
        "adoption": "diagnostic_for_external_residual",
    },
    "targets_filters_predicates": {
        "paths": [
            "Mage/src/main/java/mage/target",
            "Mage/src/main/java/mage/filter",
        ],
        "why": "Target and filter classes encode legality and scope, which are frequent sources of false confidence.",
        "manaloom_use": "Generate focused target-legality assertions; do not mirror target classes into PostgreSQL for catalog-covered cards.",
        "adoption": "diagnostic_for_external_residual",
    },
    "dynamic_values_conditions": {
        "paths": [
            "Mage/src/main/java/mage/abilities/dynamicvalue",
            "Mage/src/main/java/mage/abilities/condition",
        ],
        "why": "Dynamic values and conditions explain variable damage, counts, controller choices, thresholds, and conditional modes.",
        "manaloom_use": "Attach conditional fields to effect_json and generate edge-case assertions.",
        "adoption": "diagnostic_for_external_residual",
    },
    "watchers_replacement_prevention": {
        "paths": [
            "Mage/src/main/java/mage/watchers",
            "Mage/src/main/java/mage/abilities/effects/common/replacement",
            "Mage/src/main/java/mage/abilities/effects/common/continuous",
        ],
        "why": "Watchers, replacement, prevention, and continuous rule-modifying effects are where many battle-runtime lineage gaps originate.",
        "manaloom_use": "Use as an event-contract and state-memory reference, especially for first spell, damage, draw, discard, replacement, and prevention.",
        "adoption": "replay_and_residual_conformance_reference",
    },
    "game_events_state": {
        "paths": [
            "Mage/src/main/java/mage/game/events",
            "Mage/src/main/java/mage/game/GameState.java",
            "Mage/src/main/java/mage/game/GameImpl.java",
        ],
        "why": "Game events and state application define what a replay/audit should be able to observe.",
        "manaloom_use": "Compare normalized replay events to XMage observables while keeping hidden and unattributed actions unknown.",
        "adoption": "replay_conformance_reference",
    },
    "priority_stack_turn_engine": {
        "paths": [
            "Mage/src/main/java/mage/game/turn",
            "Mage/src/main/java/mage/game/stack",
            "Mage/src/main/java/mage/game/GameImpl.java",
            "Mage/src/main/java/mage/players/PlayerImpl.java",
        ],
        "why": "Priority, phase/step order, stack resolution, passed-priority flags, and SBA loops define correctness of non-goldfish tests.",
        "manaloom_use": "Execute these semantics in the pinned sidecar and use source only as a conformance reference.",
        "adoption": "external_runtime_and_conformance_reference",
    },
    "commander_legality": {
        "paths": [
            "Mage/src/main/java/mage/util/validation",
            "Mage/src/main/java/mage/game/GameCommanderImpl.java",
        ],
        "why": "XMage has Commander, partner, background, companion-style validator references and command-zone handling.",
        "manaloom_use": "Use as a cross-check for partner/background and command-zone metadata, not as PostgreSQL source of truth.",
        "adoption": "reference_cross_check",
    },
    "test_scenario_corpus": {
        "paths": ["Mage.Tests/src/test/java"],
        "why": "XMage tests contain a mature scenario grammar for addCard/castSpell/activateAbility/setChoice/waitStackResolved/check* assertions.",
        "manaloom_use": "Mine matching tests for focused residual/conformance scenarios and future pin qualification, not wholesale native promotion.",
        "adoption": "focused_residual_and_pin_qualification",
    },
    "ai_heuristics": {
        "paths": [
            "Mage.Server.Plugins/Mage.Player.AI",
            "Mage.Server.Plugins/Mage.Player.AI.MCTS",
            "Mage.Server.Plugins/Mage.Player.AI.Minimax",
        ],
        "why": "XMage AI can inform targeting/play-priority heuristics but is less directly portable than rules/tests.",
        "manaloom_use": "The engine AI may select runtime actions, but opaque/debug logs cannot become product learning without a stable censored trace contract.",
        "adoption": "runtime_action_policy_only_no_learning_without_trace",
    },
}


CORE_FILES = [
    "Mage/src/main/java/mage/game/Game.java",
    "Mage/src/main/java/mage/game/GameImpl.java",
    "Mage/src/main/java/mage/game/GameState.java",
    "Mage/src/main/java/mage/game/GameCommanderImpl.java",
    "Mage/src/main/java/mage/game/turn/Turn.java",
    "Mage/src/main/java/mage/game/turn/Phase.java",
    "Mage/src/main/java/mage/game/turn/Step.java",
    "Mage/src/main/java/mage/game/stack/SpellStack.java",
    "Mage/src/main/java/mage/game/stack/Spell.java",
    "Mage/src/main/java/mage/game/stack/StackObject.java",
    "Mage/src/main/java/mage/players/Player.java",
    "Mage/src/main/java/mage/players/PlayerImpl.java",
    "Mage/src/main/java/mage/game/events/GameEvent.java",
    "Mage/src/main/java/mage/watchers/Watcher.java",
    "Mage/src/main/java/mage/watchers/Watchers.java",
    "Mage/src/main/java/mage/util/validation/CommanderValidator.java",
    "Mage/src/main/java/mage/util/validation/PartnerValidator.java",
    "Mage.Tests/src/test/java/org/mage/test/player/TestPlayer.java",
]


KEYWORD_CATEGORIES: dict[str, list[str]] = {
    "priority_stack": ["priority(", "getStack()", "passedUntilStackResolved", "waitStackResolved", "StackObject"],
    "state_based_actions": ["checkStateBasedActions", "checkStateAndTriggered", "state-based"],
    "effects_layers": ["applyEffects", "Layer", "ContinuousEffect"],
    "events_watchers": ["GameEvent.EventType", "watchers.watch", "replaceEvent", "Watcher"],
    "replacement_prevention": ["ReplacementEffect", "PreventionEffect", "replaceEvent", "PREVENT_DAMAGE"],
    "target_legality": ["Target", "Filter", "canTarget", "canChoose", "addTarget"],
    "costs": ["CostAdjuster", "ManaCost", "AlternativeCost", "AdditionalCost", "costs"],
    "commander": ["commander", "Commander", "Partner", "Background", "command zone"],
    "test_dsl": ["addCard", "castSpell", "activateAbility", "setChoice", "check", "assert"],
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def canonical_xmage_pin() -> str:
    try:
        pin = CANONICAL_XMAGE_PIN_FILE.read_text(encoding="utf-8").strip()
    except OSError as exc:
        raise RuntimeError("cannot read canonical XMage pin") from exc
    if not SHA_PATTERN.fullmatch(pin):
        raise RuntimeError("canonical XMage pin is not a lowercase 40-character SHA")
    return pin


def validate_source_pin(xmage_root: Path, expected_commit: str) -> dict[str, Any]:
    try:
        completed = subprocess.run(
            ["git", "-C", str(xmage_root), "rev-parse", "HEAD"],
            check=False,
            capture_output=True,
            text=True,
            timeout=15,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        return {
            "status": "fail",
            "expected_commit": expected_commit,
            "observed_commit": None,
            "error": f"git_revision_check_failed:{exc.__class__.__name__}",
        }
    observed = completed.stdout.strip() if completed.returncode == 0 else ""
    return {
        "status": "pass" if observed == expected_commit else "fail",
        "expected_commit": expected_commit,
        "observed_commit": observed or None,
        "error": None if observed == expected_commit else "source_root_is_not_at_runtime_pin",
    }


def rel(path: Path, root: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()


def iter_java(root: Path) -> list[Path]:
    if not root.exists():
        return []
    return sorted(path for path in root.rglob("*.java") if path.is_file())


def files_under(xmage_root: Path, relative_path: str) -> list[Path]:
    path = xmage_root / relative_path
    if path.is_file():
        return [path]
    return iter_java(path)


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def class_names(source: str) -> list[str]:
    names = re.findall(r"\b(?:class|interface|enum)\s+([A-Z][A-Za-z0-9_]*)", source)
    return sorted(set(names))


def method_names(source: str) -> list[str]:
    names = re.findall(
        r"\b(?:public|protected|private)\s+(?:static\s+)?(?:final\s+)?[A-Za-z0-9_<>\[\], ?]+\s+([a-z][A-Za-z0-9_]*)\s*\(",
        source,
    )
    return sorted(set(names))


def suffix_class_counter(paths: list[Path], suffixes: list[str]) -> Counter[str]:
    counter: Counter[str] = Counter()
    for path in paths:
        for name in class_names(read_text(path)):
            for suffix in suffixes:
                if name.endswith(suffix):
                    counter[suffix] += 1
                    break
    return counter


def token_class_counter(paths: list[Path], tokens: list[str]) -> Counter[str]:
    counter: Counter[str] = Counter()
    for path in paths:
        for name in class_names(read_text(path)):
            for token in tokens:
                if token in name:
                    counter[token] += 1
                    break
    return counter


def class_catalog(paths: list[Path], root: Path, *, limit: int | None = None) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for path in paths:
        for name in class_names(read_text(path)):
            rows.append(
                {
                    "class_name": name,
                    "path": rel(path, root),
                    "package": rel(path.parent, root),
                }
            )
    rows.sort(key=lambda row: (row["package"], row["class_name"]))
    return rows if limit is None else rows[:limit]


def top_package_counts(paths: list[Path], root: Path, *, depth: int = 5, limit: int = 24) -> list[dict[str, Any]]:
    counter: Counter[str] = Counter()
    for path in paths:
        parts = rel(path.parent, root).split("/")
        key = "/".join(parts[:depth])
        counter[key] += 1
    return [{"package": key, "java_files": count} for key, count in counter.most_common(limit)]


def facet_inventory(xmage_root: Path) -> dict[str, Any]:
    facets: dict[str, Any] = {}
    for name, config in FACETS.items():
        paths: list[Path] = []
        missing: list[str] = []
        for relative_path in config["paths"]:
            absolute = xmage_root / relative_path
            found = files_under(xmage_root, relative_path)
            if not absolute.exists():
                missing.append(relative_path)
            paths.extend(found)
        classes: list[str] = []
        for path in paths[:2500]:
            classes.extend(class_names(read_text(path)))
        facets[name] = {
            "paths": config["paths"],
            "missing_paths": missing,
            "java_files": len(paths),
            "class_count_sampled": len(set(classes)),
            "sample_classes": sorted(set(classes))[:40],
            "top_packages": top_package_counts(paths, xmage_root, depth=6, limit=12),
            "why": config["why"],
            "manaloom_use": config["manaloom_use"],
            "adoption": config["adoption"],
        }
    return facets


def path_count(xmage_root: Path, relative_path: str) -> int:
    return len(files_under(xmage_root, relative_path))


def core_file_inventory(xmage_root: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for relative_path in CORE_FILES:
        path = xmage_root / relative_path
        source = read_text(path)
        keyword_hits = {
            name: sum(source.count(keyword) for keyword in keywords)
            for name, keywords in KEYWORD_CATEGORIES.items()
        }
        rows.append(
            {
                "path": relative_path,
                "exists": path.exists(),
                "line_count": len(source.splitlines()) if source else 0,
                "classes": class_names(source)[:12],
                "methods": method_names(source)[:35],
                "keyword_hits": {key: value for key, value in keyword_hits.items() if value},
            }
        )
    return rows


def keyword_evidence(xmage_root: Path, all_java: list[Path]) -> dict[str, Any]:
    categories: dict[str, Any] = {}
    for name, keywords in KEYWORD_CATEGORIES.items():
        matches: list[dict[str, Any]] = []
        total_hits = 0
        for path in all_java:
            source = read_text(path)
            count = sum(source.count(keyword) for keyword in keywords)
            if count:
                total_hits += count
                matches.append({"path": rel(path, xmage_root), "hits": count})
        matches.sort(key=lambda row: (-row["hits"], row["path"]))
        categories[name] = {"total_hits": total_hits, "top_files": matches[:24]}
    return categories


def effect_taxonomy(xmage_root: Path) -> dict[str, Any]:
    effect_paths = files_under(xmage_root, "Mage/src/main/java/mage/abilities/effects")
    ability_paths = files_under(xmage_root, "Mage/src/main/java/mage/abilities")
    target_paths = files_under(xmage_root, "Mage/src/main/java/mage/target")
    filter_paths = files_under(xmage_root, "Mage/src/main/java/mage/filter")
    watcher_paths = files_under(xmage_root, "Mage/src/main/java/mage/watchers")
    cost_paths = files_under(xmage_root, "Mage/src/main/java/mage/abilities/costs")
    dynamic_paths = files_under(xmage_root, "Mage/src/main/java/mage/abilities/dynamicvalue")
    condition_paths = files_under(xmage_root, "Mage/src/main/java/mage/abilities/condition")
    return {
        "suffix_counts": {
            "effects": dict(suffix_class_counter(effect_paths, ["Effect", "Effects"])),
            "abilities": dict(suffix_class_counter(ability_paths, ["Ability"])),
            "targets": dict(suffix_class_counter(target_paths, ["Target"])),
            "filters": dict(suffix_class_counter(filter_paths, ["Filter", "Predicate"])),
            "watchers": dict(suffix_class_counter(watcher_paths, ["Watcher", "Watchers"])),
            "costs": dict(suffix_class_counter(cost_paths, ["Cost", "Costs", "CostAdjuster"])),
            "dynamic_values": dict(suffix_class_counter(dynamic_paths, ["Value", "DynamicValue"])),
            "conditions": dict(suffix_class_counter(condition_paths, ["Condition"])),
        },
        "token_counts": {
            "effects": dict(token_class_counter(effect_paths, ["Effect"])),
            "abilities": dict(token_class_counter(ability_paths, ["Ability"])),
            "targets": dict(token_class_counter(target_paths, ["Target"])),
            "filters": dict(token_class_counter(filter_paths, ["Filter", "Predicate"])),
            "watchers": dict(token_class_counter(watcher_paths, ["Watcher"])),
            "costs": dict(token_class_counter(cost_paths, ["Cost", "CostAdjuster"])),
            "dynamic_values": dict(token_class_counter(dynamic_paths, ["Value"])),
            "conditions": dict(token_class_counter(condition_paths, ["Condition"])),
        },
        "effect_package_explanations": {
            "asthought": "cast/play permissions such as flash or alternate-zone casting",
            "combat": "attack/block restrictions, evasion, combat taxes, and combat permissions",
            "continuous": "continuous rules, type/color/control changes, replacement-like rule modifiers",
            "cost": "cost increases, reductions, alternate or special cost handling",
            "counter": "counter placement, removal, proliferation, and counter conditions",
            "discard": "discard actions and discard-trigger helpers",
            "enterAttribute": "as-enters choices and permanent entry attributes",
            "replacement": "event replacement and prevention-style effects",
            "ruleModifying": "can't/can/cast/play/search/target rule modifiers",
            "search": "library search and tutor-style effects",
            "turn": "extra turns, skip steps, end turn, and turn-modifying effects",
            "mana": "mana-production effects",
            "keyword": "keyword-specific effect helpers",
        },
        "effect_packages": top_package_counts(effect_paths, xmage_root, depth=8, limit=30),
        "target_packages": top_package_counts(target_paths, xmage_root, depth=8, limit=16),
        "filter_packages": top_package_counts(filter_paths, xmage_root, depth=8, limit=16),
        "watcher_packages": top_package_counts(watcher_paths, xmage_root, depth=8, limit=16),
        "cost_packages": top_package_counts(cost_paths, xmage_root, depth=8, limit=16),
        "dynamic_value_packages": top_package_counts(dynamic_paths, xmage_root, depth=8, limit=16),
        "condition_packages": top_package_counts(condition_paths, xmage_root, depth=8, limit=16),
        "effect_class_catalog": class_catalog(effect_paths, xmage_root),
        "target_class_catalog": class_catalog(target_paths, xmage_root),
        "filter_class_catalog": class_catalog(filter_paths, xmage_root),
        "watcher_class_catalog": class_catalog(watcher_paths, xmage_root),
        "cost_class_catalog": class_catalog(cost_paths, xmage_root),
        "dynamic_value_class_catalog": class_catalog(dynamic_paths, xmage_root),
        "condition_class_catalog": class_catalog(condition_paths, xmage_root),
    }


def extract_game_event_types(xmage_root: Path) -> dict[str, Any]:
    path = xmage_root / "Mage/src/main/java/mage/game/events/GameEvent.java"
    source = read_text(path)
    match = re.search(r"enum\s+EventType\s*\{(?P<body>.*?)\}", source, flags=re.DOTALL)
    body = match.group("body") if match else ""
    names = sorted(set(re.findall(r"\b([A-Z][A-Z0-9_]+)\b", body)))
    return {
        "path": rel(path, xmage_root),
        "event_type_count": len(names),
        "event_type_sample": names[:80],
        "has_damage_events": any("DAMAGE" in name or "DAMAGED" in name for name in names),
        "has_zone_change_events": any("ZONE" in name for name in names),
        "has_stack_events": any("STACK" in name or "CAST" in name or "COUNTER" in name for name in names),
    }


def test_corpus_inventory(xmage_root: Path) -> dict[str, Any]:
    test_paths = files_under(xmage_root, "Mage.Tests/src/test/java")
    command_counter: Counter[str] = Counter()
    matching_files: Counter[str] = Counter()
    commands = [
        "addCard",
        "castSpell",
        "activateAbility",
        "setChoice",
        "waitStackResolved",
        "checkPermanentCount",
        "checkLife",
        "checkStackObject",
        "checkPlayableAbility",
        "execute",
    ]
    for path in test_paths:
        source = read_text(path)
        for command in commands:
            count = source.count(command)
            if count:
                command_counter[command] += count
                matching_files[command] += 1
    return {
        "java_test_files": len(test_paths),
        "test_command_usage": dict(command_counter.most_common()),
        "test_command_file_counts": dict(matching_files.most_common()),
        "representative_files": [
            "Mage.Tests/src/test/java/org/mage/test/player/TestPlayer.java",
            "Mage.Tests/src/test/java/org/mage/test/testapi/WaitStackResolvedApiTest.java",
            "Mage.Tests/src/test/java/org/mage/test/cards/abilities/oneshot/counterspell/ForceOfWillTest.java",
            "Mage.Tests/src/test/java/org/mage/test/turnmod/ExtraTurnsTest.java",
            "Mage.Tests/src/test/java/org/mage/test/cards/watchers/WatchersFromDelayedTriggeredAbilitiesTest.java",
        ],
    }


def recommendations() -> list[dict[str, str]]:
    return [
        {
            "priority": "P0",
            "item": "Execute catalog-covered cards in the pinned XMage sidecar.",
            "reason": "The external engine already owns complete stack, priority, state-based, replacement and card behavior for its exact catalog.",
            "next_action": "Keep coverage and runtime provenance fail-closed; do not create native PostgreSQL rules for externally covered cards.",
        },
        {
            "priority": "P0",
            "item": "Require exact source/runtime pin identity.",
            "reason": "An unversioned source tree can disagree with the jars that execute product battles.",
            "next_action": "Reject source inventories whose Git revision differs from services/xmage-sidecar/XMAGE_COMMIT.",
        },
        {
            "priority": "P0",
            "item": "Use effect and ability taxonomies only for diagnosis and explicit residual work.",
            "reason": "Broad taxonomy extraction is useful, but it does not justify duplicating externally executable rules.",
            "next_action": "Route only proven XMage plus Forge coverage gaps to native family implementation.",
        },
        {
            "priority": "P1",
            "item": "Mine XMage tests into focused conformance scenarios.",
            "reason": "The test corpus encodes setup, action and assertion flows for stack, choices, costs, replacement and timing.",
            "next_action": "Use matching scenarios for residual adapters and future pin qualification, without treating them as PostgreSQL promotion evidence by themselves.",
        },
        {
            "priority": "P1",
            "item": "Use GameEvent/Watcher taxonomy for event-contract coverage.",
            "reason": "Product learning depends on observable, source-attributed events rather than an aggregate game result.",
            "next_action": "Compare normalized replay events against XMage observables and keep hidden or unattributed actions unknown.",
        },
        {
            "priority": "P2",
            "item": "Use Commander validators as cross-check only.",
            "reason": "PostgreSQL remains source of truth, but XMage validator coverage is useful to catch partner/background drift.",
            "next_action": "Keep a read-only commander legality audit and do not let XMage overwrite PG metadata.",
        },
        {
            "priority": "P3",
            "item": "Do not learn from opaque XMage AI debug logs.",
            "reason": "The current sidecar exposes no stable, censored, source-attributed decision trace and debug output can include hidden information.",
            "next_action": "Keep strategy_or_swap_proof false unless a structured trace contract is implemented and tested.",
        },
    ]


def build_inventory(
    xmage_root: Path,
    *,
    expected_commit: str | None = None,
) -> dict[str, Any]:
    all_java = iter_java(xmage_root)
    source_pin = (
        validate_source_pin(xmage_root, expected_commit)
        if expected_commit is not None
        else {
            "status": "not_requested",
            "expected_commit": None,
            "observed_commit": None,
            "error": None,
        }
    )
    return {
        "generated_at": utc_now(),
        "status": "ready" if source_pin["status"] != "fail" else "blocked_unpinned_source",
        "mutations_performed": [],
        "xmage_root": str(xmage_root),
        "source_pin": source_pin,
        "summary": {
            "java_files_total": len(all_java),
            "card_implementation_files": path_count(xmage_root, "Mage.Sets/src/mage/cards"),
            "core_engine_files": path_count(xmage_root, "Mage/src/main/java/mage"),
            "effect_files": path_count(xmage_root, "Mage/src/main/java/mage/abilities/effects"),
            "target_files": path_count(xmage_root, "Mage/src/main/java/mage/target"),
            "filter_files": path_count(xmage_root, "Mage/src/main/java/mage/filter"),
            "watcher_files": path_count(xmage_root, "Mage/src/main/java/mage/watchers"),
            "test_files": path_count(xmage_root, "Mage.Tests/src/test/java"),
        },
        "facets": facet_inventory(xmage_root),
        "core_files": core_file_inventory(xmage_root),
        "keyword_evidence": keyword_evidence(xmage_root, all_java),
        "effect_taxonomy": effect_taxonomy(xmage_root),
        "game_event_taxonomy": extract_game_event_types(xmage_root),
        "test_corpus": test_corpus_inventory(xmage_root),
        "recommendations": recommendations(),
    }


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# XMage Engine Absorption Inventory",
        "",
        f"- Generated at: `{report.get('generated_at')}`",
        f"- Status: `{report.get('status')}`",
        f"- XMage root: `{report.get('xmage_root')}`",
        f"- Source pin: `{report.get('source_pin')}`",
        f"- Mutations performed: `{report.get('mutations_performed')}`",
        "",
        "## Summary",
        "",
    ]
    for key, value in sorted((report.get("summary") or {}).items()):
        lines.append(f"- `{key}`: `{value}`")
    lines.extend(["", "## Absorption Facets", ""])
    for name, facet in (report.get("facets") or {}).items():
        lines.extend(
            [
                f"### {name}",
                "",
                f"- Java files: `{facet.get('java_files')}`",
                f"- Adoption: `{facet.get('adoption')}`",
                f"- Why: {facet.get('why')}",
                f"- ManaLoom use: {facet.get('manaloom_use')}",
            ]
        )
        if facet.get("missing_paths"):
            lines.append(f"- Missing paths: `{facet.get('missing_paths')}`")
        sample = ", ".join((facet.get("sample_classes") or [])[:12])
        if sample:
            lines.append(f"- Sample classes: `{sample}`")
        lines.append("")
    lines.extend(["## Engine Evidence", ""])
    for row in report.get("core_files", []):
        if not row.get("exists"):
            continue
        hits = ", ".join(f"{key}={value}" for key, value in (row.get("keyword_hits") or {}).items())
        lines.append(f"- `{row.get('path')}`: lines `{row.get('line_count')}`, classes `{row.get('classes')}`")
        if hits:
            lines.append(f"  - keyword hits: {hits}")
    lines.extend(["", "## Effect And Rule Taxonomy", ""])
    suffix_counts = (report.get("effect_taxonomy") or {}).get("suffix_counts") or {}
    for group, counts in suffix_counts.items():
        lines.append(f"- `{group}`: `{counts}`")
    token_counts = (report.get("effect_taxonomy") or {}).get("token_counts") or {}
    for group, counts in token_counts.items():
        lines.append(f"- `{group}` token counts: `{counts}`")
    lines.append("")
    lines.append("### Effect Package Meanings")
    lines.append("")
    for package, meaning in ((report.get("effect_taxonomy") or {}).get("effect_package_explanations") or {}).items():
        lines.append(f"- `{package}`: {meaning}")
    event_taxonomy = report.get("game_event_taxonomy") or {}
    lines.extend(
        [
            "",
            "## Event And Test Corpus",
            "",
            f"- Game event types: `{event_taxonomy.get('event_type_count')}` from `{event_taxonomy.get('path')}`",
            f"- Event sample: `{', '.join((event_taxonomy.get('event_type_sample') or [])[:35])}`",
            f"- Test command usage: `{(report.get('test_corpus') or {}).get('test_command_usage')}`",
            "",
            "## Recommendations",
            "",
        ]
    )
    for row in report.get("recommendations", []):
        lines.append(f"- `{row.get('priority')}` {row.get('item')} {row.get('next_action')}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(report: dict[str, Any], *, output_json: Path, output_md: Path) -> None:
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    output_md.write_text(render_markdown(report), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xmage-root", type=Path, default=DEFAULT_XMAGE_ROOT)
    parser.add_argument("--output-json", type=Path)
    parser.add_argument("--output-md", type=Path)
    parser.add_argument(
        "--allow-unpinned-source",
        action="store_true",
        help="Diagnostic research only; omits runtime pin validation.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        xmage_root = engine_source_contract.resolve_xmage_source_root(
            args.xmage_root,
            allow_unpinned=args.allow_unpinned_source,
        )
    except ValueError as exc:
        raise SystemExit(str(exc)) from exc
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    output_json = args.output_json or DEFAULT_REPORT_DIR / f"xmage_engine_absorption_inventory_{timestamp}.json"
    output_md = args.output_md or output_json.with_suffix(".md")
    expected_commit = None if args.allow_unpinned_source else canonical_xmage_pin()
    report = build_inventory(xmage_root, expected_commit=expected_commit)
    write_outputs(report, output_json=output_json, output_md=output_md)
    print(f"wrote_json={output_json}")
    print(f"wrote_md={output_md}")
    print(f"java_files_total={report['summary']['java_files_total']}")
    print(f"test_files={report['summary']['test_files']}")
    return 0 if report["status"] == "ready" else 1


if __name__ == "__main__":
    raise SystemExit(main())
