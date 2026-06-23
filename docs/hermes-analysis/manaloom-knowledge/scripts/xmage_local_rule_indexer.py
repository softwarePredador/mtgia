#!/usr/bin/env python3
"""Read-only local XMage card implementation indexer for ManaLoom review.

The indexer extracts structural evidence from a local XMage checkout. It emits
JSON/Markdown review artifacts only; it never mutates PostgreSQL, SQLite, decks,
runtime code, or reviewed battle rules.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import xmage_reference_test_scenario_builder as scenario_builder
import xmage_to_manaloom_effect_hints as effect_hints


DEFAULT_REPORT_DIR = Path(__file__).resolve().parent.parent.parent / "master_optimizer_reports"


@dataclass(frozen=True)
class ResolvedSource:
    class_name: str
    path: Path
    resolution: str


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def first_face_name(card_name: str) -> str:
    return str(card_name or "").split("//", 1)[0].strip()


def java_class_name(value: str) -> str:
    normalized = str(value or "").replace("'", "").replace("\u2019", "")
    words = re.findall(r"[A-Za-z0-9]+", normalized)
    return "".join(word[:1].upper() + word[1:] for word in words)


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


def cards_source_root(xmage_root: Path) -> Path:
    return xmage_root / "Mage.Sets" / "src" / "mage" / "cards"


def direct_card_path(xmage_root: Path, class_name: str) -> Path:
    bucket = class_name[:1].lower() if class_name else "_"
    return cards_source_root(xmage_root) / bucket / f"{class_name}.java"


def build_card_class_index(xmage_root: Path) -> dict[str, Path]:
    root = cards_source_root(xmage_root)
    if not root.exists():
        return {}
    return {path.stem: path for path in root.glob("*/*.java")}


def resolve_card_source(
    xmage_root: Path,
    card_name: str,
    class_index: dict[str, Path] | None = None,
) -> ResolvedSource | None:
    for class_name in xmage_class_candidates(card_name):
        direct = direct_card_path(xmage_root, class_name)
        if direct.exists():
            return ResolvedSource(class_name=class_name, path=direct, resolution="direct_bucket_candidate")
    if class_index is None:
        class_index = build_card_class_index(xmage_root)
    for class_name in xmage_class_candidates(card_name):
        indexed = class_index.get(class_name)
        if indexed and indexed.exists():
            return ResolvedSource(class_name=class_name, path=indexed, resolution="class_index_candidate")
    return None


def nearby_class_candidates(card_name: str, class_index: dict[str, Path] | None, *, limit: int = 12) -> list[dict[str, str]]:
    if not class_index:
        return []
    tokens = [
        token.lower()
        for token in re.findall(r"[A-Za-z0-9]+", first_face_name(card_name))
        if len(token) >= 4 and token.lower() not in {"the", "and", "with", "from"}
    ]
    if not tokens:
        return []
    scored: list[tuple[int, str, Path]] = []
    primary_token = tokens[0] if tokens else ""
    for class_name, path in class_index.items():
        class_tokens = {token.lower() for token in re.findall(r"[A-Z]?[a-z]+|[A-Z]+(?![a-z])|[0-9]+", class_name)}
        score = sum(1 for token in tokens if token in class_tokens)
        if primary_token and primary_token in class_tokens:
            score += 3
        if score:
            scored.append((score, class_name, path))
    scored.sort(key=lambda item: (-item[0], item[1]))
    return [
        {"class_name": class_name, "path": str(path), "match_score": str(score)}
        for score, class_name, path in scored[:limit]
    ]


def _unique_sorted(values: list[str]) -> list[str]:
    return sorted({value for value in values if value})


def _class_names_by_suffix(source: str, suffix_pattern: str) -> list[str]:
    return _unique_sorted(re.findall(rf"\b([A-Z][A-Za-z0-9_]*(?:{suffix_pattern}))\b", source))


def _prefixed_class_names(source: str, prefix: str) -> list[str]:
    return _unique_sorted(re.findall(rf"\b({prefix}[A-Z][A-Za-z0-9_]*)\b", source))


def _imports(source: str) -> list[str]:
    return _unique_sorted(re.findall(r"^\s*import\s+([^;]+);", source, flags=re.MULTILINE))


def _class_declarations(source: str) -> list[dict[str, str]]:
    declarations: list[dict[str, str]] = []
    pattern = re.compile(r"\b(?:public|private|protected|static|final|\s)*class\s+([A-Z][A-Za-z0-9_]*)\s+extends\s+([A-Z][A-Za-z0-9_]*)")
    for match in pattern.finditer(source):
        declarations.append({"class_name": match.group(1), "extends": match.group(2)})
    return declarations


def _main_class_info(source: str) -> tuple[str | None, str | None]:
    declarations = _class_declarations(source)
    if not declarations:
        return None, None
    return declarations[0]["class_name"], declarations[0]["extends"]


def _super_constructor_excerpt(source: str) -> str | None:
    match = re.search(r"\bsuper\s*\((.*?)\)\s*;", source, flags=re.DOTALL)
    if not match:
        return None
    return " ".join(match.group(0).split())


def _string_literals(value: str) -> list[str]:
    return re.findall(r'"((?:[^"\\]|\\.)*)"', value)


def _looks_like_mana_cost_literal(value: str) -> bool:
    if value == "":
        return True
    return bool(re.fullmatch(r"(?:\{[^}]+\})+", value))


def _constructor_metadata(source: str, *, card_name: str | None = None) -> dict[str, Any]:
    super_call = _super_constructor_excerpt(source) or ""
    literals = _string_literals(super_call)
    mana_cost_literals = [literal for literal in literals if _looks_like_mana_cost_literal(literal)]
    named_literals = [literal for literal in literals if literal and not _looks_like_mana_cost_literal(literal)]
    nonempty_mana_costs = [literal for literal in mana_cost_literals if literal]
    primary_name = first_face_name(card_name) if card_name else None
    return {
        "super_call": super_call or None,
        "constructor_string_literals": literals,
        "constructor_mana_cost_literals": mana_cost_literals,
        "constructor_named_literals": named_literals,
        "xmage_card_name": primary_name or (named_literals[0] if named_literals else None),
        "mana_cost": nonempty_mana_costs[0] if nonempty_mana_costs else None,
        "front_mana_cost": nonempty_mana_costs[0] if nonempty_mana_costs else None,
        "back_face_name": named_literals[0] if named_literals else None,
        "back_mana_cost": mana_cost_literals[-1] if len(mana_cost_literals) > 1 else None,
        "rarity": _first_dot_token(source, "Rarity"),
        "card_types": _constructor_dot_tokens(source, "CardType"),
        "subtypes": _unique_sorted(_constructor_dot_tokens(source, "SubType") + _explicit_subtype_tokens(source)),
    }


def _dot_tokens(source: str, owner: str) -> list[str]:
    return _unique_sorted(re.findall(rf"\b{owner}\.([A-Z0-9_]+)", source))


def _constructor_dot_tokens(source: str, owner: str) -> list[str]:
    super_call = _super_constructor_excerpt(source) or ""
    return _dot_tokens(super_call, owner)


def _explicit_subtype_tokens(source: str) -> list[str]:
    return _unique_sorted(
        re.findall(
            r"\b(?:this|this\.getLeftHalfCard\(\)|this\.getRightHalfCard\(\))\.subtype\.add\(SubType\.([A-Z0-9_]+)\)",
            source,
        )
    )


def _first_dot_token(source: str, owner: str) -> str | None:
    tokens = _dot_tokens(source, owner)
    return tokens[0] if tokens else None


def excerpt_text(text: str, *, max_lines: int = 42) -> str:
    lines = [line.rstrip() for line in str(text or "").splitlines()]
    useful = [
        line
        for line in lines
        if line.strip()
        and not line.strip().startswith("package ")
        and not line.strip().startswith("import ")
        and not line.strip().startswith("//")
    ]
    return "\n".join(useful[:max_lines])


def implementation_signals(entry: dict[str, Any]) -> list[str]:
    effects = set(entry.get("effect_classes") or [])
    abilities = set(entry.get("ability_classes") or [])
    conditions = set(entry.get("condition_classes") or [])
    counters = set(entry.get("counter_types") or [])
    signals: list[str] = []
    checks = [
        ("destroy_all", bool(effects & {"DestroyAllEffect", "SacrificeAllEffect", "DamageAllEffect"})),
        ("targeting", bool(entry.get("target_classes"))),
        ("cost_reduction", "SpellsCostReductionControllerEffect" in effects or "SpellCostReductionSourceEffect" in effects),
        ("token", "CreateTokenEffect" in effects or "CreateTokenCopyTargetEffect" in effects),
        ("draw", any("DrawCard" in effect for effect in effects)),
        ("mana", any("Mana" in ability for ability in abilities)),
        ("counter", bool(counters) or any("Counter" in effect for effect in effects)),
        ("condition", bool(conditions)),
        ("gift", "GiftWasPromisedCondition" in conditions or "GiftAbility" in abilities),
        ("static_ability", any("StaticAbility" in ability for ability in abilities)),
        ("triggered_ability", any("TriggeredAbility" in ability for ability in abilities)),
        ("activated_ability", any("ActivatedAbility" in ability for ability in abilities)),
    ]
    for name, present in checks:
        if present:
            signals.append(name)
    return signals


def parse_java_card_source(
    source: str,
    *,
    card_name: str | None = None,
    class_name: str | None = None,
    path: Path | None = None,
) -> dict[str, Any]:
    main_class, superclass = _main_class_info(source)
    entry: dict[str, Any] = {
        "card_name": card_name,
        "status": "found",
        "xmage_class_name": class_name or main_class,
        "xmage_path": str(path) if path else None,
        "xmage_package": _first_package(source),
        "card_superclass": superclass,
        "imports": _imports(source),
        "ability_classes": _class_names_by_suffix(source, r"Ability|Abilities|Keyword"),
        "effect_classes": _class_names_by_suffix(source, r"Effect|Effects"),
        "target_classes": _prefixed_class_names(source, "Target"),
        "filter_classes": _prefixed_class_names(source, "Filter"),
        "condition_classes": _class_names_by_suffix(source, r"Condition"),
        "cost_classes": _class_names_by_suffix(source, r"Cost|Costs"),
        "dynamic_value_classes": _class_names_by_suffix(source, r"Value|Count"),
        "counter_types": _dot_tokens(source, "CounterType"),
        "zones": _dot_tokens(source, "Zone"),
        "constructor_metadata": _constructor_metadata(source, card_name=card_name),
        "class_declarations": _class_declarations(source),
        "raw_excerpt": excerpt_text(source),
    }
    entry["custom_inner_classes"] = [
        declaration
        for declaration in entry["class_declarations"]
        if declaration.get("class_name") != entry.get("xmage_class_name")
    ]
    entry["signals"] = implementation_signals(entry)
    hint = effect_hints.build_effect_hints(entry)
    entry["candidate_effect_hints"] = hint
    entry["suggested_test_scenarios"] = scenario_builder.build_suggested_test_scenarios(entry, hint)
    return entry


def _first_package(source: str) -> str | None:
    match = re.search(r"^\s*package\s+([^;]+);", source, flags=re.MULTILINE)
    return match.group(1) if match else None


def build_index_for_card(
    card_name: str,
    *,
    xmage_root: Path,
    class_index: dict[str, Path] | None = None,
) -> dict[str, Any]:
    resolved = resolve_card_source(xmage_root, card_name, class_index=class_index)
    if not resolved:
        return {
            "card_name": card_name,
            "status": "not_found",
            "candidate_class_names": xmage_class_candidates(card_name),
            "nearby_xmage_class_candidates": nearby_class_candidates(card_name, class_index),
            "mutations_performed": [],
        }
    source = resolved.path.read_text(encoding="utf-8", errors="replace")
    entry = parse_java_card_source(
        source,
        card_name=card_name,
        class_name=resolved.class_name,
        path=resolved.path,
    )
    entry["resolution"] = resolved.resolution
    entry["candidate_class_names"] = xmage_class_candidates(card_name)
    entry["mutations_performed"] = []
    return entry


def load_card_names(args: argparse.Namespace) -> tuple[list[str], dict[str, Any]]:
    source: dict[str, Any] = {}
    names: list[str] = []
    if args.cards:
        for value in args.cards:
            names.extend(part.strip() for part in value.split(",") if part.strip())
        source["kind"] = "cards_arg"
    if args.cards_file:
        path = Path(args.cards_file)
        file_names = [
            line.strip()
            for line in path.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.strip().startswith("#")
        ]
        names.extend(file_names)
        source["cards_file"] = str(path)
    if args.coherence_report:
        path = Path(args.coherence_report)
        payload = json.loads(path.read_text(encoding="utf-8"))
        source["coherence_report"] = str(path)
        source["deck_id"] = payload.get("deck_id")
        source["severity_counts"] = payload.get("severity_counts")
        for card in payload.get("cards", []):
            if not isinstance(card, dict):
                continue
            if card.get("severity") not in {"critical", "high", "medium"}:
                continue
            card_name = str(card.get("card_name") or "").strip()
            if card_name:
                names.append(card_name)
    deduped: list[str] = []
    for name in names:
        if name not in deduped:
            deduped.append(name)
    if args.limit and args.limit > 0:
        deduped = deduped[: args.limit]
    return deduped, source


def build_index_report(card_names: list[str], *, xmage_root: Path, source: dict[str, Any] | None = None) -> dict[str, Any]:
    class_index = build_card_class_index(xmage_root)
    cards = [
        build_index_for_card(card_name, xmage_root=xmage_root, class_index=class_index)
        for card_name in card_names
    ]
    resolved_count = sum(1 for card in cards if card.get("status") == "found")
    return {
        "generated_at": utc_now(),
        "status": "ready",
        "mutations_performed": [],
        "xmage_root": str(xmage_root),
        "source": source or {},
        "summary": {
            "requested_card_count": len(card_names),
            "resolved_count": resolved_count,
            "not_found_count": len(cards) - resolved_count,
            "xmage_class_index_size": len(class_index),
        },
        "cards": cards,
    }


def markdown_report(report: dict[str, Any]) -> str:
    lines = [
        "# XMage Local Rule Index",
        "",
        f"Generated at: `{report['generated_at']}`",
        "",
        "Read-only artifact. `mutations_performed=[]`.",
        "",
        f"- XMage root: `{report.get('xmage_root')}`",
        f"- Summary: `{json.dumps(report.get('summary'), sort_keys=True)}`",
        "",
        "| Card | Status | XMage class | Superclass | Signals | Primary hint |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for card in report.get("cards", []):
        primary = (
            card.get("candidate_effect_hints", {})
            .get("primary_candidate", {})
            .get("effect_json", {})
            .get("effect")
        )
        lines.append(
            "| "
            + " | ".join(
                [
                    f"`{card.get('card_name')}`",
                    f"`{card.get('status')}`",
                    f"`{card.get('xmage_class_name')}`",
                    f"`{card.get('card_superclass')}`",
                    f"`{', '.join(card.get('signals') or [])}`",
                    f"`{primary}`",
                ]
            )
            + " |"
        )
    lines.extend(["", "## Card Evidence", ""])
    for card in report.get("cards", []):
        lines.extend([f"### {card.get('card_name')}", ""])
        if card.get("status") != "found":
            lines.extend(
                [
                    f"- Status: `{card.get('status')}`",
                    f"- Candidate class names: `{json.dumps(card.get('candidate_class_names'), sort_keys=True)}`",
                    "",
                ]
            )
            continue
        primary = card.get("candidate_effect_hints", {}).get("primary_candidate", {})
        lines.extend(
            [
                f"- XMage path: `{card.get('xmage_path')}`",
                f"- Class: `{card.get('xmage_class_name')}` extends `{card.get('card_superclass')}`",
                f"- Ability classes: `{json.dumps(card.get('ability_classes'), sort_keys=True)}`",
                f"- Effect classes: `{json.dumps(card.get('effect_classes'), sort_keys=True)}`",
                f"- Target classes: `{json.dumps(card.get('target_classes'), sort_keys=True)}`",
                f"- Filter classes: `{json.dumps(card.get('filter_classes'), sort_keys=True)}`",
                f"- Condition classes: `{json.dumps(card.get('condition_classes'), sort_keys=True)}`",
                f"- Primary candidate: `{json.dumps(primary.get('effect_json'), sort_keys=True)}`",
                f"- Confidence reason: {primary.get('confidence_reason')}",
                "",
                "Suggested focused tests:",
                "",
            ]
        )
        for scenario in card.get("suggested_test_scenarios", []):
            lines.append(f"- `{scenario.get('id')}`: {scenario.get('title')}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def write_report(report: dict[str, Any], output_json: Path, output_md: Path) -> None:
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    output_md.write_text(markdown_report(report), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xmage-root", required=True)
    parser.add_argument("--cards", action="append", help="Comma-separated card names. Can be provided multiple times.")
    parser.add_argument("--cards-file")
    parser.add_argument("--coherence-report")
    parser.add_argument("--limit", type=int, default=20)
    parser.add_argument("--output-prefix")
    parser.add_argument("--output-json")
    parser.add_argument("--output-md")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    xmage_root = Path(args.xmage_root)
    card_names, source = load_card_names(args)
    report = build_index_report(card_names, xmage_root=xmage_root, source=source)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    if args.output_prefix:
        output_json = Path(f"{args.output_prefix}.json")
        output_md = Path(f"{args.output_prefix}.md")
    else:
        stem = f"xmage_local_rule_index_{timestamp}"
        output_json = Path(args.output_json or DEFAULT_REPORT_DIR / f"{stem}.json")
        output_md = Path(args.output_md or DEFAULT_REPORT_DIR / f"{stem}.md")
    if args.output_json:
        output_json = Path(args.output_json)
    if args.output_md:
        output_md = Path(args.output_md)
    write_report(report, output_json, output_md)
    print(f"json_report={output_json}")
    print(f"md_report={output_md}")
    print(f"cards={len(report['cards'])}")
    print(f"resolved={report['summary']['resolved_count']}")
    print("mutations_performed=[]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
