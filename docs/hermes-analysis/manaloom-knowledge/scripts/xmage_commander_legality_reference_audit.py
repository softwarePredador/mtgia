#!/usr/bin/env python3
"""Read-only XMage Commander legality reference audit for ManaLoom.

This compares the presence of key XMage Commander validator source files with a
small ManaLoom metadata checklist. It is a reference audit only and does not
replace product legality logic or mutate data.
"""

from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DEFAULT_REPORT_DIR = Path(__file__).resolve().parent.parent.parent / "master_optimizer_reports"

REFERENCE_FILES = {
    "abstract_commander_deck_validation": "Mage.Server.Plugins/Mage.Deck.Constructed/src/mage/deck/AbstractCommander.java",
    "partner": "Mage/src/main/java/mage/util/validation/PartnerValidator.java",
    "partner_with": "Mage/src/main/java/mage/util/validation/PartnerWithValidator.java",
    "choose_a_background": "Mage/src/main/java/mage/util/validation/ChooseABackgroundValidator.java",
    "doctors_companion": "Mage/src/main/java/mage/util/validation/DoctorsCompanionValidator.java",
    "commander_game": "Mage/src/main/java/mage/game/GameCommanderImpl.java",
    "commander_replacement": "Mage/src/main/java/mage/abilities/effects/common/continuous/CommanderReplacementEffect.java",
    "commander_tax": "Mage/src/main/java/mage/abilities/effects/common/cost/CommanderCostModification.java",
    "commander_damage": "Mage/src/main/java/mage/watchers/common/CommanderInfoWatcher.java",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def inspect_reference_file(xmage_root: Path, key: str, relative: str) -> dict[str, Any]:
    path = xmage_root / relative
    if not path.exists():
        return {"key": key, "status": "missing", "relative_path": relative}
    source = path.read_text(encoding="utf-8", errors="replace")
    return {
        "key": key,
        "status": "found",
        "relative_path": relative,
        "path": str(path),
        "class_names": sorted(set(re.findall(r"\bclass\s+([A-Z][A-Za-z0-9_]*)", source))),
        "method_names": sorted(set(re.findall(r"\b(?:public|protected|private)\s+[A-Za-z0-9_<>, ?]+\s+([a-z][A-Za-z0-9_]*)\s*\(", source)))[:40],
        "signals": commander_reference_signals(source),
    }


def commander_reference_signals(source: str) -> list[str]:
    lower = source.lower()
    checks = [
        ("singleton", "singleton" in lower),
        ("color_identity", "color" in lower and "identity" in lower),
        ("partner", "partner" in lower),
        ("background", "background" in lower),
        ("companion", "companion" in lower),
        ("command_zone", "command" in lower and "zone" in lower),
        ("commander_tax", "cost" in lower and "commander" in lower),
        ("commander_damage", "damage" in lower and "commander" in lower),
    ]
    return [name for name, present in checks if present]


def inspect_xmage_commander_reference(xmage_root: Path) -> dict[str, Any]:
    references = [
        inspect_reference_file(xmage_root, key, relative)
        for key, relative in REFERENCE_FILES.items()
    ]
    return {
        "xmage_root": str(xmage_root),
        "reference_count": len(references),
        "found_count": sum(1 for item in references if item.get("status") == "found"),
        "missing_count": sum(1 for item in references if item.get("status") != "found"),
        "references": references,
    }


def load_metadata_rows(path: Path | None) -> list[dict[str, Any]]:
    if path is None:
        return []
    payload = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(payload, list):
        return [row for row in payload if isinstance(row, dict)]
    if isinstance(payload, dict) and isinstance(payload.get("rows"), list):
        return [row for row in payload["rows"] if isinstance(row, dict)]
    if isinstance(payload, dict):
        return [payload]
    return []


def classify_metadata_row(row: dict[str, Any]) -> dict[str, Any]:
    metadata = row.get("metadata") if isinstance(row.get("metadata"), dict) else row
    identity_model = metadata.get("commander_identity_model") if isinstance(metadata, dict) else None
    if not isinstance(identity_model, dict):
        return {
            "status": "metadata_missing_commander_identity_model",
            "requires_followup": True,
            "reason": "No commander_identity_model object found in metadata.",
        }
    modeled_keys = {
        key
        for key in identity_model
        if key in {"partner", "partner_with", "background", "companion", "doctors_companion", "identity_type", "requires_first_class_persistence"}
    }
    return {
        "status": "metadata_has_commander_identity_model",
        "requires_followup": False,
        "modeled_keys": sorted(modeled_keys),
        "requires_first_class_persistence": bool(identity_model.get("requires_first_class_persistence")),
    }


def build_reference_audit(xmage_root: Path, metadata_rows: list[dict[str, Any]] | None = None) -> dict[str, Any]:
    xmage = inspect_xmage_commander_reference(xmage_root)
    metadata_results = [classify_metadata_row(row) for row in (metadata_rows or [])]
    return {
        "generated_at": utc_now(),
        "status": "ready",
        "mutations_performed": [],
        "xmage_reference": xmage,
        "metadata_rows_checked": len(metadata_results),
        "metadata_results": metadata_results,
        "policy": "reference_audit_only_no_product_legality_replacement_no_postgresql_write",
    }


def markdown_report(report: dict[str, Any]) -> str:
    xmage = report.get("xmage_reference", {})
    lines = [
        "# XMage Commander Legality Reference Audit",
        "",
        f"Generated at: `{report['generated_at']}`",
        "",
        "Read-only artifact. `mutations_performed=[]`.",
        "",
        f"- XMage root: `{xmage.get('xmage_root')}`",
        f"- References found: `{xmage.get('found_count')}/{xmage.get('reference_count')}`",
        f"- Metadata rows checked: `{report.get('metadata_rows_checked')}`",
        "",
        "| Reference | Status | Signals | Path |",
        "| --- | --- | --- | --- |",
    ]
    for item in xmage.get("references", []):
        lines.append(
            "| "
            + " | ".join(
                [
                    f"`{item.get('key')}`",
                    f"`{item.get('status')}`",
                    f"`{', '.join(item.get('signals') or [])}`",
                    f"`{item.get('relative_path')}`",
                ]
            )
            + " |"
        )
    if report.get("metadata_results"):
        lines.extend(["", "## Metadata Checklist", ""])
        for idx, item in enumerate(report.get("metadata_results", []), start=1):
            lines.append(f"- Row {idx}: `{json.dumps(item, sort_keys=True)}`")
    return "\n".join(lines).rstrip() + "\n"


def write_report(report: dict[str, Any], output_json: Path, output_md: Path) -> None:
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    output_md.write_text(markdown_report(report), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xmage-root", required=True)
    parser.add_argument("--metadata-json", help="Optional JSON row/list to run through the metadata checklist.")
    parser.add_argument("--output-json")
    parser.add_argument("--output-md")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    metadata_rows = load_metadata_rows(Path(args.metadata_json)) if args.metadata_json else []
    report = build_reference_audit(Path(args.xmage_root), metadata_rows)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    output_json = Path(args.output_json or DEFAULT_REPORT_DIR / f"xmage_commander_legality_reference_audit_{timestamp}.json")
    output_md = Path(args.output_md or DEFAULT_REPORT_DIR / f"xmage_commander_legality_reference_audit_{timestamp}.md")
    write_report(report, output_json, output_md)
    print(f"json_report={output_json}")
    print(f"md_report={output_md}")
    print(f"references_found={report['xmage_reference']['found_count']}")
    print("mutations_performed=[]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
