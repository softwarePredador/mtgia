#!/usr/bin/env python3
"""Synthesize external Lorehold signals against from-scratch shell gates.

This is a read-only learning artifact. It answers a narrower question than the
external reconciler: when an external idea requires a full shell, did one of the
2026-07-03 Lorehold challengers already cover it, and did that shell pass the
607 promotion contract?
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_EXTERNAL_RECONCILIATION = (
    REPORT_DIR / "lorehold_external_evidence_reconciler_20260704_current.json"
)
DEFAULT_STEM = "lorehold_external_shell_gate_synthesis_20260704_current"
SHELL_PREFIX = "lorehold_from_scratch_challengers_20260703_current_"


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def shell_slug_from_matrix(path: Path) -> str:
    name = path.name
    if not name.startswith(SHELL_PREFIX) or not name.endswith("_matrix.json"):
        raise ValueError(f"not a current Lorehold shell matrix: {path}")
    return name[len(SHELL_PREFIX) : -len("_matrix.json")]


def parse_decklist(path: Path) -> set[str]:
    if not path.exists():
        return set()
    cards: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r"^\s*\d+\s+(.+?)\s*$", line)
        if match:
            cards.add(match.group(1))
    return cards


def result_counts(games: list[Mapping[str, Any]]) -> dict[str, int]:
    counts = Counter(str(game.get("result") or "unknown") for game in games)
    return {
        "win": counts.get("win", 0),
        "loss": counts.get("loss", 0),
        "stall": counts.get("stall", 0),
        "unknown": counts.get("unknown", 0),
        "total": len(games),
    }


def summarize_gate(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    data = read_json(path)
    rows: dict[str, dict[str, Any]] = {}
    for row in as_list(data.get("results")):
        deck_key = str(row.get("deck_key") or "")
        if not deck_key:
            continue
        games = [game for game in as_list(row.get("game_results")) if isinstance(game, Mapping)]
        winota_games = [
            game for game in games if "Winota" in str(game.get("opponent") or "")
        ]
        mirror_games = [
            game
            for game in games
            if "Fixed Lorehold deck 607" in str(game.get("opponent") or "")
        ]
        rows[deck_key] = {
            "deck_key": deck_key,
            "counts": result_counts(games),
            "winota_counts": result_counts(winota_games),
            "fixed_607_counts": result_counts(mirror_games),
            "avg_win_turn": row.get("avg_win_turn") or 0,
            "battle_rank": row.get("battle_rank"),
        }
    candidate_key = next((key for key in rows if key.startswith("challenger_")), "")
    baseline = rows.get("deck_607") or {}
    candidate = rows.get(candidate_key) if candidate_key else {}
    baseline_wins = ((baseline or {}).get("counts") or {}).get("win", 0)
    candidate_wins = ((candidate or {}).get("counts") or {}).get("win", 0)
    baseline_winota = ((baseline or {}).get("winota_counts") or {}).get("win", 0)
    candidate_winota = ((candidate or {}).get("winota_counts") or {}).get("win", 0)
    return {
        "path": rel(path),
        "status": data.get("status"),
        "opponents": data.get("opponents") or [],
        "games_per_opponent": data.get("games_per_opponent"),
        "simulation_seed": data.get("simulation_seed"),
        "opponent_seed": data.get("opponent_seed"),
        "candidate_key": candidate_key,
        "rows": rows,
        "candidate_minus_607_wins": candidate_wins - baseline_wins,
        "candidate_minus_607_winota_wins": candidate_winota - baseline_winota,
    }


def deck_row_by_key(matrix: Mapping[str, Any], deck_key: str) -> dict[str, Any]:
    for row in as_list(matrix.get("decks")):
        if isinstance(row, Mapping) and row.get("deck_key") == deck_key:
            return dict(row)
    return {}


def shell_decision(
    *,
    baseline_rank: int | None,
    candidate_rank: int | None,
    smoke_gate: Mapping[str, Any] | None,
    confirm_gate: Mapping[str, Any] | None,
) -> str:
    if confirm_gate:
        if confirm_gate.get("candidate_minus_607_wins", 0) < 0:
            return "reject_confirmed_lost_to_607"
        if confirm_gate.get("candidate_minus_607_winota_wins", 0) < 0:
            return "reject_confirmed_regressed_winota"
        return "requires_trace_review_after_confirm_positive"
    if baseline_rank is not None and candidate_rank is not None and candidate_rank > baseline_rank:
        return "not_promotable_structure_below_607"
    if smoke_gate and smoke_gate.get("candidate_minus_607_wins", 0) > 0:
        return "smoke_positive_requires_confirmation"
    return "not_promotable_without_confirmed_gate"


def load_shell_artifacts(report_dir: Path) -> list[dict[str, Any]]:
    shells: list[dict[str, Any]] = []
    for matrix_path in sorted(report_dir.glob(f"{SHELL_PREFIX}*_matrix.json")):
        shell_slug = shell_slug_from_matrix(matrix_path)
        matrix = read_json(matrix_path)
        ranked = [str(key) for key in as_list(matrix.get("ranked_deck_keys"))]
        candidate_key = next((key for key in ranked if key.startswith("challenger_")), "")
        baseline_rank = ranked.index("deck_607") + 1 if "deck_607" in ranked else None
        candidate_rank = ranked.index(candidate_key) + 1 if candidate_key in ranked else None
        decklist_path = report_dir / f"{SHELL_PREFIX}{shell_slug}.decklist.txt"
        smoke_path = report_dir / f"{SHELL_PREFIX}{shell_slug}_fixed607_gate.json"
        confirm_path = report_dir / f"{SHELL_PREFIX}{shell_slug}_confirm_seed42.json"
        smoke_gate = summarize_gate(smoke_path)
        confirm_gate = summarize_gate(confirm_path)
        candidate_row = deck_row_by_key(matrix, candidate_key)
        baseline_row = deck_row_by_key(matrix, "deck_607")
        cards = parse_decklist(decklist_path)
        shells.append(
            {
                "shell_slug": shell_slug,
                "candidate_key": candidate_key,
                "matrix": rel(matrix_path),
                "decklist": rel(decklist_path) if decklist_path.exists() else "",
                "card_count_from_decklist": len(cards),
                "cards": sorted(cards),
                "baseline_rank": baseline_rank,
                "candidate_rank": candidate_rank,
                "best_structural_deck": matrix.get("best_structural_deck"),
                "candidate_commander_intent_score": candidate_row.get(
                    "commander_intent_score"
                ),
                "candidate_strategy_score": candidate_row.get("strategy_score"),
                "candidate_role_counts": candidate_row.get("role_counts") or {},
                "candidate_strategy_package_counts": candidate_row.get(
                    "strategy_package_counts"
                )
                or {},
                "candidate_primary_risks": candidate_row.get("primary_risks") or [],
                "baseline_role_counts": baseline_row.get("role_counts") or {},
                "smoke_gate": smoke_gate,
                "confirm_gate": confirm_gate,
                "decision": shell_decision(
                    baseline_rank=baseline_rank,
                    candidate_rank=candidate_rank,
                    smoke_gate=smoke_gate,
                    confirm_gate=confirm_gate,
                ),
            }
        )
    return shells


def signal_cards_to_check(signal: Mapping[str, Any]) -> list[str]:
    missing = [str(card) for card in as_list(signal.get("missing_add_cards")) if card]
    if missing:
        return missing
    cards = []
    for row in as_list(signal.get("add_cards")):
        if isinstance(row, Mapping):
            name = str(row.get("card_name") or "")
            if name and not row.get("in_current_607"):
                cards.append(name)
        elif row:
            cards.append(str(row))
    return cards


def classify_signal_against_shells(
    signal: Mapping[str, Any], shells: list[Mapping[str, Any]]
) -> dict[str, Any]:
    cards_to_check = signal_cards_to_check(signal)
    coverages: list[dict[str, Any]] = []
    for shell in shells:
        shell_cards = set(shell.get("cards") or [])
        matched = sorted(card for card in cards_to_check if card in shell_cards)
        missing = sorted(card for card in cards_to_check if card not in shell_cards)
        if matched or not cards_to_check:
            coverages.append(
                {
                    "shell_slug": shell.get("shell_slug"),
                    "candidate_key": shell.get("candidate_key"),
                    "matched_cards": matched,
                    "missing_cards": missing,
                    "coverage_ratio": (
                        round(len(matched) / len(cards_to_check), 3)
                        if cards_to_check
                        else 1.0
                    ),
                    "shell_decision": shell.get("decision"),
                    "candidate_rank": shell.get("candidate_rank"),
                    "baseline_rank": shell.get("baseline_rank"),
                }
            )
    exact_coverages = [row for row in coverages if not row["missing_cards"]]
    rejected_exact = [
        row
        for row in exact_coverages
        if str(row.get("shell_decision") or "").startswith("reject_")
        or row.get("shell_decision") == "not_promotable_structure_below_607"
    ]
    original_status = str(signal.get("status") or "")
    contract_path = str(signal.get("contract_path") or "")
    if original_status == "already_represented_by_current_607":
        status = "supports_current_607"
        action = "keep_current_anchor"
    elif rejected_exact:
        status = "covered_by_existing_nonpromotable_shell"
        action = "do_not_repeat_full_shell_without_new_contract_change"
    elif exact_coverages:
        status = "covered_but_not_confirmed"
        action = "requires_equal_confirm_gate_before_any_promotion"
    elif contract_path == "full_shell":
        status = "partial_or_uncovered_full_shell"
        action = "define_smaller_named_shell_contract_before_battle"
    elif original_status == "blocked_by_cut_safety":
        status = "blocked_by_cut_safety"
        action = "do_not_gate_until_cut_safety_changes"
    elif original_status == "blocked_no_named_cut":
        status = "blocked_no_named_cut"
        action = "name_cut_or_model_as_diagnostic_only"
    else:
        status = original_status or "unclassified"
        action = str(signal.get("recommended_action") or "")
    return {
        "signal_key": signal.get("signal_key"),
        "package_key": signal.get("package_key"),
        "original_status": original_status,
        "synthesis_status": status,
        "recommended_action": action,
        "contract_path": contract_path,
        "lane": signal.get("lane"),
        "cards_checked": cards_to_check,
        "best_coverages": sorted(
            coverages,
            key=lambda row: (-row["coverage_ratio"], str(row["shell_slug"])),
        )[:6],
        "exact_coverage_count": len(exact_coverages),
        "rejected_exact_coverage_count": len(rejected_exact),
        "known_internal_decisions": signal.get("known_internal_decisions") or [],
    }


def build_report(
    *,
    external_reconciliation: Mapping[str, Any],
    external_reconciliation_path: Path,
    report_dir: Path,
) -> dict[str, Any]:
    shells = load_shell_artifacts(report_dir)
    signal_rows = [
        classify_signal_against_shells(signal, shells)
        for signal in as_list(external_reconciliation.get("signals"))
    ]
    shell_decisions = Counter(str(shell.get("decision") or "") for shell in shells)
    signal_statuses = Counter(str(row.get("synthesis_status") or "") for row in signal_rows)
    promotable_shells = [
        shell
        for shell in shells
        if shell.get("decision") == "requires_trace_review_after_confirm_positive"
    ]
    next_action = (
        "promote_no_shell_keep_607_and_define_smaller_diagnostics"
        if not promotable_shells
        else "inspect_positive_confirmed_shell_trace_before_promotion"
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_external_shell_gate_synthesis",
        "postgres_writes": False,
        "source_db_mutated": False,
        "external_reconciliation": rel(external_reconciliation_path),
        "summary": {
            "shell_count": len(shells),
            "promotable_shell_count": len(promotable_shells),
            "shell_decision_counts": dict(sorted(shell_decisions.items())),
            "external_signal_count": len(signal_rows),
            "signal_synthesis_status_counts": dict(sorted(signal_statuses.items())),
            "recommended_next_action": next_action,
            "current_champion": "deck_607",
        },
        "learning_model": [
            "Legality and external popularity are input lanes, not promotion proof.",
            "For Lorehold, card value is measured by role fit in miracle/topdeck timing, early mana floor, pressure survival, and conversion window.",
            "A staple only becomes a candidate when it has a named cut or a declared full-shell contract.",
            "A shell that ranks below 607 structurally or loses the equal gate remains learning evidence, not a deck replacement.",
            "Winota/fast-pressure regression is a hard guardrail even when aggregate wins improve.",
        ],
        "shells": [
            {key: value for key, value in shell.items() if key != "cards"}
            for shell in shells
        ],
        "signals": signal_rows,
        "sources": external_reconciliation.get("sources") or [],
        "method_notes": [
            "The script reads existing 2026-07-03 shell matrices, decklists, fixed-607 gates, and confirm gates when present.",
            "Smoke-only positives are not promotion proof.",
            "Exact card coverage means the shell contained every non-607 add card from the external signal; it does not prove that the shell executed that package well.",
            "This script does not mutate PostgreSQL, SQLite, deck rows, or generated decklists.",
        ],
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold External Shell Gate Synthesis",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        f"- External reconciliation: `{payload['external_reconciliation']}`",
        f"- Shells audited: `{summary['shell_count']}`",
        f"- Promotable shells: `{summary['promotable_shell_count']}`",
        f"- External signals: `{summary['external_signal_count']}`",
        f"- Recommended next action: `{summary['recommended_next_action']}`",
        f"- Shell decision counts: `{json.dumps(summary['shell_decision_counts'], sort_keys=True)}`",
        f"- Signal synthesis counts: `{json.dumps(summary['signal_synthesis_status_counts'], sort_keys=True)}`",
        "",
        "## Learning Model",
        "",
    ]
    for note in payload.get("learning_model") or []:
        lines.append(f"- {note}")
    lines.extend(
        [
            "",
            "## Shell Decisions",
            "",
            "| Shell | Candidate rank | Baseline rank | Lands | Ramp | Draw | Decision | Gate summary |",
            "| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |",
        ]
    )
    for shell in payload.get("shells") or []:
        roles = shell.get("candidate_role_counts") or {}
        gate = shell.get("confirm_gate") or shell.get("smoke_gate") or {}
        gate_label = "-"
        if gate:
            candidate_key = gate.get("candidate_key") or shell.get("candidate_key")
            rows = gate.get("rows") or {}
            baseline_counts = ((rows.get("deck_607") or {}).get("counts") or {})
            candidate_counts = ((rows.get(candidate_key) or {}).get("counts") or {})
            gate_label = (
                f"607 {baseline_counts.get('win', 0)}/{baseline_counts.get('total', 0)}; "
                f"candidate {candidate_counts.get('win', 0)}/{candidate_counts.get('total', 0)}"
            )
        lines.append(
            "| {shell} | {candidate_rank} | {baseline_rank} | {lands} | {ramp} | {draw} | `{decision}` | {gate} |".format(
                shell=shell.get("shell_slug") or "",
                candidate_rank=shell.get("candidate_rank") or "",
                baseline_rank=shell.get("baseline_rank") or "",
                lands=roles.get("land", ""),
                ramp=roles.get("ramp", ""),
                draw=roles.get("draw", ""),
                decision=shell.get("decision") or "",
                gate=gate_label,
            )
        )
    lines.extend(
        [
            "",
            "## External Signal Coverage",
            "",
            "| Signal | Synthesis status | Cards checked | Best shell coverage | Next action |",
            "| --- | --- | --- | --- | --- |",
        ]
    )
    for signal in payload.get("signals") or []:
        best = (signal.get("best_coverages") or [{}])[0]
        best_label = "-"
        if best:
            best_label = (
                f"{best.get('shell_slug')} "
                f"{len(best.get('matched_cards') or [])}/{len(signal.get('cards_checked') or [])}"
            )
        lines.append(
            "| {signal} | `{status}` | {cards} | {best} | `{action}` |".format(
                signal=signal.get("signal_key") or "",
                status=signal.get("synthesis_status") or "",
                cards=", ".join(signal.get("cards_checked") or []) or "-",
                best=best_label,
                action=signal.get("recommended_action") or "",
            )
        )
    lines.extend(["", "## Sources", ""])
    for source in payload.get("sources") or []:
        lines.append(
            f"- `{source.get('source_key')}`: {source.get('url')} "
            f"({source.get('source_type')})"
        )
    lines.extend(["", "## Method Notes", ""])
    for note in payload.get("method_notes") or []:
        lines.append(f"- {note}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--external-reconciliation",
        type=Path,
        default=DEFAULT_EXTERNAL_RECONCILIATION,
    )
    parser.add_argument("--report-dir", type=Path, default=REPORT_DIR)
    parser.add_argument("--stem", default=DEFAULT_STEM)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_report(
        external_reconciliation=read_json(args.external_reconciliation),
        external_reconciliation_path=args.external_reconciliation,
        report_dir=args.report_dir,
    )
    args.report_dir.mkdir(parents=True, exist_ok=True)
    json_path = args.report_dir / f"{args.stem}.json"
    md_path = args.report_dir / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
