#!/usr/bin/env python3
"""Audit static and observed replay event types against event contracts."""

from __future__ import annotations

import argparse
import ast
import importlib.util
import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_ENGINE_SOURCE = SCRIPT_DIR / "battle_analyst_v9.py"
DEFAULT_ENGINE_SOURCES = [
    DEFAULT_ENGINE_SOURCE,
    SCRIPT_DIR / "battle_sba_support.py",
    SCRIPT_DIR / "battle_replacement_support.py",
]
DEFAULT_LATEST_RUN = Path(
    "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/"
    "battle-strategy-audit/latest"
)
ACTION_CRITIC_PATH = SCRIPT_DIR / "battle_action_critic.py"

EXPECTED_CONSUMER_BY_CLASS = {
    "action_audited": "battle_action_critic.py",
    "technical": "structured_replay_ledger",
    "strategy_signal": "decision_strategy_or_replay_context",
    "renderer_only": "battle_replay_v10_3.py",
    "ignored_with_reason": "skip_guardrail_or_state_cleanup",
    "forensic_card_event": "battle_forensic_audit.py",
    "unclassified": None,
}

MINIMUM_FIELDS_BY_CLASS = {
    "action_audited": {"event", "turn"},
    "technical": {"event"},
    "strategy_signal": {"event", "turn"},
    "renderer_only": {"event"},
    "ignored_with_reason": {"event"},
    "forensic_card_event": {"event", "turn"},
    "unclassified": {"event"},
}

MINIMUM_FIELDS_BY_EVENT = {
    "spell_resolved": {
        "event",
        "turn",
        "phase",
        "priority_window",
        "stack_object",
        "stack_depth",
        "source_zone",
        "from_zone",
        "to_zone",
        "destination",
        "zone_after",
        "resolved_from_stack",
        "result",
        "cast_pipeline",
        "locked_cost",
    },
}

STATIC_FIXTURE_WAIVER_REASON_BY_CLASS = {
    "action_audited": (
        "accepted_action_branch_static_contract_until_natural_or_targeted_regression"
    ),
    "technical": "accepted_technical_ledger_event_no_forced_replay_required",
    "strategy_signal": "accepted_strategy_context_signal_static_contract",
    "renderer_only": "accepted_renderer_only_event_no_guardrail_consumer",
    "ignored_with_reason": "accepted_explicitly_ignored_event_contract",
    "forensic_card_event": "accepted_forensic_card_event_static_contract_until_observed",
}


def load_action_critic():
    spec = importlib.util.spec_from_file_location(
        "battle_action_critic_for_event_contract_static_audit",
        ACTION_CRITIC_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


ACTION_CRITIC = load_action_critic()


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--engine-source", type=Path, action="append", default=None)
    parser.add_argument("--input-dir", type=Path, default=DEFAULT_LATEST_RUN)
    parser.add_argument("--events", type=Path, action="append", default=[])
    parser.add_argument("--output", type=Path)
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--fail-on-unclassified", action="store_true")
    return parser.parse_args(argv)


def normalize_engine_sources(
    engine_source: Path | list[Path] | tuple[Path, ...] | None,
) -> list[Path]:
    if engine_source is None:
        return list(DEFAULT_ENGINE_SOURCES)
    if isinstance(engine_source, Path):
        return [engine_source]
    return [Path(path) for path in engine_source]


def static_event_emitters(
    engine_source: Path | list[Path] | tuple[Path, ...] | None,
) -> dict[str, list[dict[str, int | str]]]:
    emitters: dict[str, list[dict[str, int | str]]] = defaultdict(list)
    for source in normalize_engine_sources(engine_source):
        tree = ast.parse(source.read_text(encoding="utf-8"))
        for node in ast.walk(tree):
            if not isinstance(node, ast.Call):
                continue
            func = node.func
            if not isinstance(func, ast.Name) or func.id not in {"emit_replay_event", "emitter"}:
                continue
            if not node.args:
                continue
            first = node.args[0]
            if isinstance(first, ast.Constant) and isinstance(first.value, str):
                emitters[first.value].append(
                    {
                        "path": str(source),
                        "line": int(getattr(node, "lineno", 0) or 0),
                    }
                )
    return {event: rows for event, rows in sorted(emitters.items())}


def event_paths(input_dir: Path, explicit_paths: list[Path]) -> list[Path]:
    if explicit_paths:
        return sorted(path for path in explicit_paths if path.exists())
    if input_dir.is_file():
        return [input_dir]
    if not input_dir.exists():
        return []
    direct = sorted(input_dir.glob("seed_*/replay.events.jsonl"))
    nested = sorted(input_dir.glob("*/seed_*/replay.events.jsonl"))
    return sorted({*direct, *nested})


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            text = line.strip()
            if not text:
                continue
            row = json.loads(text)
            row.setdefault("_source_path", str(path))
            row.setdefault("_source_line", line_number)
            rows.append(row)
    return rows


def classification_for(event_type: str) -> tuple[str, str]:
    return ACTION_CRITIC.classify_event_contract(event_type)


def minimum_fields_for_event(event_type: str, classification: str) -> set[str]:
    return MINIMUM_FIELDS_BY_EVENT.get(
        event_type,
        MINIMUM_FIELDS_BY_CLASS.get(classification, {"event"}),
    )


def missing_fields(event: dict[str, Any], classification: str) -> list[str]:
    event_type = str(event.get("event") or "missing")
    required = minimum_fields_for_event(event_type, classification)
    return sorted(field for field in required if field not in event)


def fixture_or_waiver(
    *,
    observed_count: int,
    classification: str,
) -> tuple[str, str]:
    reason = STATIC_FIXTURE_WAIVER_REASON_BY_CLASS.get(classification)
    if reason and observed_count:
        return "observed_in_latest", ""
    if reason:
        return "static_contract_accepted_waiver", reason
    return (
        "static_contract_waiver_until_forced_fixture",
        "unclassified_or_missing_accepted_fixture_waiver",
    )


def build_audit(
    *,
    input_dir: Path = DEFAULT_LATEST_RUN,
    events: list[Path] | None = None,
    engine_source: Path | list[Path] | tuple[Path, ...] | None = None,
) -> dict[str, Any]:
    engine_sources = normalize_engine_sources(engine_source)
    static_emitters = static_event_emitters(engine_source)
    paths = event_paths(input_dir, list(events or []))
    observed_rows: list[dict[str, Any]] = []
    for path in paths:
        observed_rows.extend(load_jsonl(path))

    observed_counts = Counter(str(row.get("event") or "missing") for row in observed_rows)
    static_types = set(static_emitters)
    observed_types = set(observed_counts)
    all_types = sorted(static_types | observed_types)

    static_class_counts: Counter[str] = Counter()
    observed_class_counts: Counter[str] = Counter()
    observed_event_class_counts: Counter[str] = Counter()
    fixture_or_waiver_counts: Counter[str] = Counter()
    fixture_accepted_waiver_reasons: Counter[str] = Counter()
    field_findings: list[dict[str, Any]] = []

    for row in observed_rows:
        event_type = str(row.get("event") or "missing")
        classification, _reason = classification_for(event_type)
        observed_event_class_counts[classification] += 1
        missing = missing_fields(row, classification)
        if missing:
            field_findings.append(
                {
                    "severity": "medium",
                    "code": "observed_event_missing_minimum_fields",
                    "event": event_type,
                    "missing": missing,
                    "source_path": row.get("_source_path"),
                    "source_line": row.get("_source_line"),
                }
            )

    items: list[dict[str, Any]] = []
    for event_type in all_types:
        classification, reason = classification_for(event_type)
        observed_count = int(observed_counts.get(event_type, 0))
        fixture_status, fixture_reason = fixture_or_waiver(
            observed_count=observed_count,
            classification=classification,
        )
        fixture_or_waiver_counts[fixture_status] += 1
        if fixture_status == "static_contract_accepted_waiver":
            fixture_accepted_waiver_reasons[fixture_reason] += 1
        if event_type in static_types:
            static_class_counts[classification] += 1
        if event_type in observed_types:
            observed_class_counts[classification] += 1
        items.append(
            {
                "event": event_type,
                "static": event_type in static_types,
                "emitters": static_emitters.get(event_type, []),
                "emit_lines": [entry["line"] for entry in static_emitters.get(event_type, [])],
                "observed_count": observed_count,
                "classification": classification,
                "classification_reason": reason,
                "minimum_fields": sorted(minimum_fields_for_event(event_type, classification)),
                "expected_consumer": EXPECTED_CONSUMER_BY_CLASS.get(classification),
                "fixture_or_waiver": fixture_status,
                "fixture_waiver_reason": fixture_reason,
            }
        )

    static_unclassified = [
        item["event"]
        for item in items
        if item["static"] and item["classification"] == "unclassified"
    ]
    observed_unclassified = [
        item["event"]
        for item in items
        if item["observed_count"] and item["classification"] == "unclassified"
    ]
    status = (
        "event_contract_static_ready"
        if not static_unclassified and not observed_unclassified and not field_findings
        else "review_required"
    )
    summary = {
        "generated_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "status": status,
        "engine_source": str(engine_sources[0]) if engine_sources else "",
        "static_engine_sources": [str(source) for source in engine_sources],
        "input_dir": str(input_dir),
        "event_paths": [str(path) for path in paths],
        "events_observed_total": sum(observed_counts.values()),
        "observed_event_types_total": len(observed_types),
        "static_event_types_total": len(static_types),
        "all_event_types_total": len(all_types),
        "observed_unclassified_total": len(observed_unclassified),
        "static_unclassified_total": len(static_unclassified),
        "observed_missing_required_fields": len(field_findings),
        "observed_not_static_literal": sorted(observed_types - static_types),
        "static_not_observed": sorted(static_types - observed_types),
        "fixture_or_waiver_counts": dict(sorted(fixture_or_waiver_counts.items())),
        "static_fixture_accepted_waiver_total": int(
            fixture_or_waiver_counts.get("static_contract_accepted_waiver", 0)
        ),
        "static_contract_waiver_until_forced_fixture": int(
            fixture_or_waiver_counts.get("static_contract_waiver_until_forced_fixture", 0)
        ),
        "static_fixture_accepted_waiver_reasons": dict(
            sorted(fixture_accepted_waiver_reasons.items())
        ),
        "static_fixture_unaccepted_types": [
            item["event"]
            for item in items
            if item["fixture_or_waiver"] == "static_contract_waiver_until_forced_fixture"
        ],
        "static_class_counts": dict(sorted(static_class_counts.items())),
        "observed_type_class_counts": dict(sorted(observed_class_counts.items())),
        "observed_event_class_counts": dict(sorted(observed_event_class_counts.items())),
        "observed_counts": dict(sorted(observed_counts.items())),
        "observed_unclassified_types": observed_unclassified,
        "static_unclassified_types": static_unclassified,
    }
    return {
        "version": 1,
        "summary": summary,
        "items": items,
        "field_findings": field_findings,
    }


def render_markdown(audit: dict[str, Any]) -> str:
    summary = audit["summary"]
    lines = [
        "# Battle Event Contract Static Audit",
        "",
        f"- Generated at UTC: `{summary['generated_at_utc']}`",
        f"- Status: `{summary['status']}`",
        f"- Engine source: `{summary['engine_source']}`",
        f"- Static engine sources: `{json.dumps(summary.get('static_engine_sources', []))}`",
        f"- Event paths: `{json.dumps(summary['event_paths'])}`",
        f"- Observed events: `{summary['events_observed_total']}`",
        f"- Observed event types: `{summary['observed_event_types_total']}`",
        f"- Static event types: `{summary['static_event_types_total']}`",
        f"- Static unclassified total: `{summary['static_unclassified_total']}`",
        f"- Observed unclassified total: `{summary['observed_unclassified_total']}`",
        f"- Observed missing required fields: `{summary['observed_missing_required_fields']}`",
        f"- Fixture/waiver counts: `{json.dumps(summary['fixture_or_waiver_counts'], sort_keys=True)}`",
        f"- Static fixture accepted waiver total: `{summary['static_fixture_accepted_waiver_total']}`",
        f"- Static contract waiver until forced fixture: `{summary['static_contract_waiver_until_forced_fixture']}`",
        f"- Static fixture accepted waiver reasons: `{json.dumps(summary['static_fixture_accepted_waiver_reasons'], sort_keys=True)}`",
        f"- Static fixture unaccepted types: `{json.dumps(summary['static_fixture_unaccepted_types'])}`",
        f"- Static class counts: `{json.dumps(summary['static_class_counts'], sort_keys=True)}`",
        f"- Observed type class counts: `{json.dumps(summary['observed_type_class_counts'], sort_keys=True)}`",
        f"- Observed event class counts: `{json.dumps(summary['observed_event_class_counts'], sort_keys=True)}`",
        f"- Observed not static literal: `{json.dumps(summary['observed_not_static_literal'])}`",
        "",
        "## Event Contract Matrix",
        "",
        "| Event | Static | Observed | Class | Consumer | Minimum fields | Fixture/waiver | Reason |",
        "| --- | --- | ---: | --- | --- | --- | --- | --- |",
    ]
    for item in audit["items"]:
        lines.append(
            "| `{event}` | `{static}` | `{observed}` | `{classification}` | `{consumer}` | `{fields}` | `{fixture}` | `{reason}` |".format(
                event=item["event"],
                static="yes" if item["static"] else "no",
                observed=item["observed_count"],
                classification=item["classification"],
                consumer=item.get("expected_consumer") or "-",
                fields=", ".join(item.get("minimum_fields") or []),
                fixture=item.get("fixture_or_waiver"),
                reason=item.get("fixture_waiver_reason") or "-",
            )
        )

    if audit["field_findings"]:
        lines.extend(["", "## Field Findings", ""])
        for finding in audit["field_findings"]:
            lines.append(
                f"- `{finding['severity']}` `{finding['event']}` missing `{finding['missing']}` at `{finding.get('source_path')}:{finding.get('source_line')}`"
            )
    else:
        lines.extend(["", "## Field Findings", "", "- No observed event field findings."])

    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    audit = build_audit(
        input_dir=args.input_dir,
        events=args.events,
        engine_source=args.engine_source,
    )
    markdown = render_markdown(audit)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(markdown, encoding="utf-8")
        print(f"Markdown report: {args.output}")
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(audit, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        print(f"JSON report: {args.json_output}")
    if not args.output and not args.json_output:
        print(markdown)
    if args.fail_on_unclassified and audit["summary"]["status"] != "event_contract_static_ready":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
