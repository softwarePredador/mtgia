#!/usr/bin/env python3
"""Measure Lorehold pressure-absorber package usage and ablation impact.

This harness imports battle_analyst_v9 and runs the same simulation path used by
the CLI, but keeps all changes in memory. PostgreSQL, the source SQLite DB, and
candidate artifacts are not mutated.
"""

from __future__ import annotations

import argparse
import copy
import json
import math
import os
import random
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import battle_analyst_v9 as battle
from master_optimizer_common import REPORT_DIR, normalize_name, resolve_default_knowledge_db

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_DB = resolve_default_knowledge_db()

TARGET_CARDS = [
    "Crawlspace",
    "Ghostly Prison",
    "Magus of the Moat",
    "Silent Arbiter",
    "Sphere of Safety",
    "Windborn Muse",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def card_key(card: Any) -> str:
    if isinstance(card, dict):
        return normalize_name(card.get("name") or card.get("card_name") or "")
    return normalize_name(str(card or ""))


def card_name(card: Any) -> str:
    if isinstance(card, dict):
        return str(card.get("name") or card.get("card_name") or "")
    return str(card or "")


def probability_at_least_one(deck_size: int, copies: int, cards_seen: int) -> float:
    if copies <= 0 or cards_seen <= 0:
        return 0.0
    if cards_seen > deck_size:
        cards_seen = deck_size
    if deck_size - copies < cards_seen:
        return 1.0
    return 1.0 - math.comb(deck_size - copies, cards_seen) / math.comb(deck_size, cards_seen)


class ScenarioTelemetry:
    def __init__(self, target_names: list[str]):
        self.target_names = target_names
        self.target_keys = {normalize_name(name): name for name in target_names}
        self.current_game = ""
        self.games: set[str] = set()
        self.card_stats: dict[str, dict[str, Any]] = {
            name: {
                "opening_seen_games": set(),
                "drawn_games": set(),
                "draw_count": 0,
                "cast_announced_games": set(),
                "cost_paid_games": set(),
                "cost_paid_count": 0,
            }
            for name in target_names
        }
        self.package_restriction_events = 0
        self.package_attackers_before = 0
        self.package_attackers_after = 0
        self.package_attackers_restricted = 0
        self.package_tax_paid = 0
        self.package_restriction_source_counts: Counter[str] = Counter()

    def begin_game(self, game_id: str) -> None:
        self.current_game = game_id
        self.games.add(game_id)

    def _card_stat(self, card: Any) -> dict[str, Any] | None:
        key = card_key(card)
        name = self.target_keys.get(key)
        if not name:
            return None
        return self.card_stats[name]

    def record_opening_hand(self, player: Any) -> None:
        if getattr(player, "name", "") != "Lorehold":
            return
        for card in getattr(player, "hand", []) or []:
            stat = self._card_stat(card)
            if stat is not None:
                stat["opening_seen_games"].add(self.current_game)

    def record_drawn_cards(self, player: Any, drawn: list[Any]) -> None:
        if getattr(player, "name", "") != "Lorehold":
            return
        if battle.CURRENT_REPLAY_TURN is None:
            return
        for card in drawn or []:
            stat = self._card_stat(card)
            if stat is not None:
                stat["drawn_games"].add(self.current_game)
                stat["draw_count"] += 1

    def record_event(self, event: str, data: dict[str, Any]) -> None:
        if event in {"cast_announced", "cost_paid"} and data.get("player") == "Lorehold":
            stat = self._card_stat(data.get("card"))
            if stat is not None:
                if event == "cast_announced":
                    stat["cast_announced_games"].add(self.current_game)
                elif event == "cost_paid":
                    stat["cost_paid_games"].add(self.current_game)
                    stat["cost_paid_count"] += 1
        if event == "combat_step" and data.get("target") == "Lorehold":
            for detail in data.get("attack_restrictions") or []:
                restricted = int(detail.get("attackers_restricted") or 0)
                if restricted <= 0:
                    continue
                source_names = list(detail.get("attack_restriction_sources") or [])
                if not source_names:
                    source_names = [
                        source.get("card", "?")
                        for source in detail.get("attack_tax_sources") or []
                        if isinstance(source, dict) and source.get("card")
                    ]
                target_sources = [
                    source
                    for source in source_names
                    if normalize_name(source) in self.target_keys
                ]
                if not target_sources:
                    continue
                self.package_restriction_events += 1
                self.package_attackers_before += int(detail.get("attackers_before") or 0)
                self.package_attackers_after += int(detail.get("attackers_after") or 0)
                self.package_attackers_restricted += restricted
                self.package_tax_paid += int(detail.get("tax_paid") or 0)
                self.package_restriction_source_counts.update(target_sources)

    def as_json(self) -> dict[str, Any]:
        games = max(1, len(self.games))
        card_rows = {}
        for name, stat in self.card_stats.items():
            seen_games = set(stat["opening_seen_games"]) | set(stat["drawn_games"])
            card_rows[name] = {
                "opening_seen_games": len(stat["opening_seen_games"]),
                "drawn_games": len(stat["drawn_games"]),
                "seen_games": len(seen_games),
                "seen_rate": round(len(seen_games) / games, 4),
                "draw_count": int(stat["draw_count"]),
                "cast_announced_games": len(stat["cast_announced_games"]),
                "cost_paid_games": len(stat["cost_paid_games"]),
                "cost_paid_count": int(stat["cost_paid_count"]),
                "cast_rate_when_seen": round(
                    len(stat["cost_paid_games"]) / max(1, len(seen_games)),
                    4,
                ),
            }
        return {
            "games": len(self.games),
            "cards": card_rows,
            "package_restrictions": {
                "events": self.package_restriction_events,
                "attackers_before": self.package_attackers_before,
                "attackers_after": self.package_attackers_after,
                "attackers_restricted": self.package_attackers_restricted,
                "tax_paid": self.package_tax_paid,
                "source_event_counts": dict(self.package_restriction_source_counts),
            },
        }


def blank_card(card: dict[str, Any], target_name: str) -> dict[str, Any]:
    blank = copy.deepcopy(card)
    blank["name"] = f"Blank Slot ({target_name})"
    blank["tag"] = "unknown"
    blank["functional_tags"] = []
    blank["effect"] = "unknown"
    blank["oracle_text"] = ""
    blank["type_line"] = "Blank"
    blank["power"] = 0
    blank["toughness"] = 0
    return blank


def build_deck_without_target(deck: list[dict[str, Any]], target_name: str) -> list[dict[str, Any]]:
    target_key = normalize_name(target_name)
    built = []
    replaced = False
    for card in deck:
        if not replaced and card_key(card) == target_key:
            built.append(blank_card(card, target_name))
            replaced = True
        else:
            built.append(copy.deepcopy(card))
    if not replaced:
        raise ValueError(f"target not found in deck: {target_name}")
    return built


def run_scenario(
    *,
    label: str,
    commander: dict[str, Any],
    deck: list[dict[str, Any]],
    opponent_sources: list[dict[str, Any]],
    games_per_opponent: int,
    seed: int,
    target_cards: list[str],
) -> dict[str, Any]:
    telemetry = ScenarioTelemetry(target_cards)
    rng = random.Random(seed)
    wins = losses = stalls = 0
    win_turns = []
    win_reasons: Counter[str] = Counter()
    opponent_rows = []

    for profile in opponent_sources:
        profile_wins = profile_losses = profile_stalls = 0
        profile_win_turns = []
        profile_win_reasons: Counter[str] = Counter()
        for game_index in range(games_per_opponent):
            game_id = f"{label}:{profile.get('name', '?')}:{game_index}"
            telemetry.begin_game(game_id)
            battle.CURRENT_REPLAY_TURN = None
            others = [item for item in opponent_sources if item is not profile]
            picked = [profile] + rng.sample(others, min(2, len(others)))
            result, turns, reason = battle.simulate_game_v8(
                copy.deepcopy(commander),
                copy.deepcopy(deck),
                copy.deepcopy(picked),
                rng,
                game_index,
            )
            if result == "win":
                wins += 1
                profile_wins += 1
                win_turns.append(turns)
                profile_win_turns.append(turns)
                win_reasons[reason] += 1
                profile_win_reasons[reason] += 1
            elif result == "loss":
                losses += 1
                profile_losses += 1
            else:
                stalls += 1
                profile_stalls += 1
        total_profile_games = max(1, games_per_opponent)
        opponent_rows.append(
            {
                "opponent": profile.get("name", "?"),
                "wins": profile_wins,
                "losses": profile_losses,
                "stalls": profile_stalls,
                "win_rate": round(profile_wins / total_profile_games * 100, 2),
                "avg_win_turn": round(
                    sum(profile_win_turns) / len(profile_win_turns),
                    2,
                )
                if profile_win_turns
                else 0,
                "win_reasons": dict(profile_win_reasons),
            }
        )

    total_games = games_per_opponent * len(opponent_sources)
    return {
        "label": label,
        "games": total_games,
        "wins": wins,
        "losses": losses,
        "stalls": stalls,
        "win_rate": round(wins / max(1, total_games) * 100, 2),
        "avg_win_turn": round(sum(win_turns) / len(win_turns), 2) if win_turns else 0,
        "win_reasons": dict(win_reasons),
        "opponents": opponent_rows,
        "telemetry": telemetry.as_json(),
    }


def patch_battle_hooks(telemetry_ref: dict[str, ScenarioTelemetry | None]):
    original_draw = battle.Player.draw
    original_play_mulligan = battle.play_mulligan

    def patched_draw(self, n=1, rng=None):
        drawn = original_draw(self, n, rng)
        telemetry = telemetry_ref.get("telemetry")
        if telemetry is not None and not telemetry_ref.get("in_mulligan"):
            telemetry.record_drawn_cards(self, drawn)
        return drawn

    def patched_play_mulligan(player, rng):
        telemetry_ref["in_mulligan"] = True
        try:
            result = original_play_mulligan(player, rng)
        finally:
            telemetry_ref["in_mulligan"] = False
        telemetry = telemetry_ref.get("telemetry")
        if telemetry is not None:
            telemetry.record_opening_hand(player)
        return result

    def event_handler(event, data):
        telemetry = telemetry_ref.get("telemetry")
        if telemetry is not None:
            telemetry.record_event(event, data or {})

    battle.Player.draw = patched_draw
    battle.play_mulligan = patched_play_mulligan
    battle.REPLAY_EVENT_HANDLER = event_handler
    return original_draw, original_play_mulligan


def restore_battle_hooks(original_draw, original_play_mulligan) -> None:
    battle.Player.draw = original_draw
    battle.play_mulligan = original_play_mulligan
    battle.REPLAY_EVENT_HANDLER = None


def run_scenario_with_hooks(**kwargs) -> dict[str, Any]:
    target_cards = kwargs["target_cards"]
    telemetry_ref: dict[str, ScenarioTelemetry | None] = {"telemetry": None}
    original_draw, original_play_mulligan = patch_battle_hooks(telemetry_ref)
    try:
        # run_scenario creates the telemetry object internally, so patch the class
        # construction path by wrapping only this call.
        original_cls = ScenarioTelemetry

        class BoundTelemetry(ScenarioTelemetry):
            def __init__(self, target_names):
                super().__init__(target_names)
                telemetry_ref["telemetry"] = self

        globals()["ScenarioTelemetry"] = BoundTelemetry
        try:
            return run_scenario(**kwargs)
        finally:
            globals()["ScenarioTelemetry"] = original_cls
            telemetry_ref["telemetry"] = None
    finally:
        restore_battle_hooks(original_draw, original_play_mulligan)


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# Lorehold Pressure Absorber Ablation Telemetry",
        "",
        f"- generated_at: `{report['generated_at']}`",
        f"- source_db: `{report['source_db']}`",
        f"- games_per_opponent: `{report['games_per_opponent']}`",
        f"- opponent_seed: `{report['opponent_seed']}`",
        f"- simulation_seed: `{report['simulation_seed']}`",
        f"- opponents: `{len(report['opponents'])}`",
        f"- available_target_cards: `{', '.join(report.get('available_target_cards') or []) or '-'}`",
        f"- absent_target_cards: `{', '.join(report.get('absent_target_cards') or []) or '-'}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Probability Baseline",
        "",
        "| Cards seen | One specific card | Any of 6-card package |",
        "| ---: | ---: | ---: |",
    ]
    for row in report["probability_baseline"]:
        lines.append(
            f"| {row['cards_seen']} | {row['one_specific_card_pct']:.2f}% | "
            f"{row['any_package_card_pct']:.2f}% |"
        )

    lines.extend(
        [
            "",
            "## Scenario Results",
            "",
            "| Scenario | Games | W | L | S | WR | Avg win turn | Package restricted attackers | Restriction events | Restriction sources |",
            "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |",
        ]
    )
    for scenario in report["scenarios"]:
        restrictions = scenario["telemetry"]["package_restrictions"]
        source_counts = restrictions.get("source_event_counts") or {}
        source_summary = ", ".join(
            f"{source}={count}" for source, count in sorted(source_counts.items())
        )
        lines.append(
            f"| {scenario['label']} | {scenario['games']} | {scenario['wins']} | "
            f"{scenario['losses']} | {scenario['stalls']} | {scenario['win_rate']:.2f}% | "
            f"{scenario['avg_win_turn']:.2f} | {restrictions['attackers_restricted']} | "
            f"{restrictions['events']} | {source_summary} |"
        )

    baseline = report["scenarios"][0]
    lines.extend(
        [
            "",
            "## Baseline Card Telemetry",
            "",
            "| Card | Seen games | Seen rate | Opening seen | In-game drawn | Cast paid games | Casts paid | Cast when seen |",
            "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for name, row in baseline["telemetry"]["cards"].items():
        lines.append(
            f"| {name} | {row['seen_games']} | {row['seen_rate'] * 100:.2f}% | "
            f"{row['opening_seen_games']} | {row['drawn_games']} | "
            f"{row['cost_paid_games']} | {row['cost_paid_count']} | "
            f"{row['cast_rate_when_seen'] * 100:.2f}% |"
        )

    lines.extend(["", "## Opponent Detail", ""])
    for scenario in report["scenarios"]:
        lines.extend(
            [
                f"### {scenario['label']}",
                "",
                "| Opponent | W | L | S | WR | Avg win turn | Reasons |",
                "| --- | ---: | ---: | ---: | ---: | ---: | --- |",
            ]
        )
        for opponent in scenario["opponents"]:
            reasons = ", ".join(
                f"{key}={value}" for key, value in opponent["win_reasons"].items()
            )
            lines.append(
                f"| {opponent['opponent']} | {opponent['wins']} | {opponent['losses']} | "
                f"{opponent['stalls']} | {opponent['win_rate']:.2f}% | "
                f"{opponent['avg_win_turn']:.2f} | {reasons} |"
            )
        lines.append("")

    lines.extend(
        [
            "## Method Notes",
            "",
            "- `baseline_v7` uses the generated isolated candidate DB.",
            "- Ablations keep deck size constant by replacing the target card with a blank in-memory slot.",
            "- This measures slot utility versus a dead card, not the best possible replacement card.",
            "- Draw telemetry counts final opening hand plus in-game draws by the Lorehold player.",
            "- Cast telemetry uses `cost_paid`, so illegal/uncastable announcements are not counted as real casts.",
            "- Package attack utility uses combat restriction events against Lorehold and requires a package card source when the runtime exposes `attack_restriction_sources`.",
            "",
        ]
    )
    return "\n".join(lines)


def write_report(report: dict[str, Any], stem: str) -> tuple[Path, Path]:
    json_path = REPORT_DIR / f"{stem}.json"
    md_path = REPORT_DIR / f"{stem}.md"
    json_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(report), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=str(DEFAULT_DB))
    parser.add_argument("--games", type=int, default=2)
    parser.add_argument("--opponent-limit", type=int, default=3)
    parser.add_argument("--opponent-seed", type=int, default=20260626)
    parser.add_argument("--simulation-seed", type=int, default=42)
    parser.add_argument(
        "--stem",
        default="lorehold_pressure_absorber_ablation_20260626_v1",
    )
    parser.add_argument(
        "--scenario",
        action="append",
        help=(
            "Optional scenario label to run. Can be repeated. "
            "Use baseline_v7 or without_<normalized card name>."
        ),
    )
    args = parser.parse_args()

    os.environ["MANALOOM_KNOWLEDGE_DB"] = str(args.db)
    os.environ["MANALOOM_BATTLE_REAL_OPPONENT_LIMIT"] = str(args.opponent_limit)
    os.environ["MANALOOM_BATTLE_REAL_OPPONENT_SEED"] = str(args.opponent_seed)
    os.environ.setdefault("MANALOOM_BATTLE_EVALUATION_TARGET_PLAYER", "Lorehold")
    os.environ.setdefault("MANALOOM_BATTLE_EVALUATION_MODE", "target_pressure")
    battle.DB = str(args.db)

    commander, deck, construction = battle.load_deck_with_construction_report()
    if not construction["is_valid"]:
        raise RuntimeError(f"invalid source deck: {construction['issues']}")
    opponents = battle.load_learned_opponents()
    if len(opponents) < 3:
        raise RuntimeError("expected at least 3 learned opponents")

    scenarios = [("baseline_v7", deck)]
    available_target_cards = []
    absent_target_cards = []
    for name in TARGET_CARDS:
        try:
            scenarios.append(
                (
                    f"without_{normalize_name(name).replace(' ', '_')}",
                    build_deck_without_target(deck, name),
                )
            )
            available_target_cards.append(name)
        except ValueError:
            absent_target_cards.append(name)
    requested = set(args.scenario or [])
    if requested:
        scenarios = [scenario for scenario in scenarios if scenario[0] in requested]
        missing = sorted(requested - {scenario[0] for scenario in scenarios})
        if missing:
            raise ValueError(f"unknown scenario(s): {missing}")

    scenario_reports = []
    for label, scenario_deck in scenarios:
        print(f"running {label} games={args.games} opponents={len(opponents)}", flush=True)
        scenario_reports.append(
            run_scenario_with_hooks(
                label=label,
                commander=commander,
                deck=scenario_deck,
                opponent_sources=opponents,
                games_per_opponent=args.games,
                seed=args.simulation_seed,
                target_cards=TARGET_CARDS,
            )
        )
        partial_report = {
            "generated_at": utc_now(),
            "source_db": str(Path(args.db).resolve()),
            "games_per_opponent": args.games,
            "opponent_limit": args.opponent_limit,
            "opponent_seed": args.opponent_seed,
            "simulation_seed": args.simulation_seed,
            "target_cards": TARGET_CARDS,
            "available_target_cards": available_target_cards,
            "absent_target_cards": absent_target_cards,
            "opponents": [opponent.get("name", "?") for opponent in opponents],
            "probability_baseline": [],
            "scenarios": list(scenario_reports),
            "postgres_writes": False,
            "source_db_mutated": False,
            "partial": True,
        }
        write_report(partial_report, f"{args.stem}_partial")

    probability_rows = []
    for cards_seen in (7, 10, 12, 15, 20, 25):
        probability_rows.append(
            {
                "cards_seen": cards_seen,
                "one_specific_card_pct": probability_at_least_one(99, 1, cards_seen) * 100,
                "any_package_card_pct": probability_at_least_one(99, len(TARGET_CARDS), cards_seen) * 100,
            }
        )

    report = {
        "generated_at": utc_now(),
        "source_db": str(Path(args.db).resolve()),
        "games_per_opponent": args.games,
        "opponent_limit": args.opponent_limit,
        "opponent_seed": args.opponent_seed,
        "simulation_seed": args.simulation_seed,
        "target_cards": TARGET_CARDS,
        "available_target_cards": available_target_cards,
        "absent_target_cards": absent_target_cards,
        "opponents": [opponent.get("name", "?") for opponent in opponents],
        "probability_baseline": probability_rows,
        "scenarios": scenario_reports,
        "postgres_writes": False,
        "source_db_mutated": False,
    }

    json_path, md_path = write_report(report, args.stem)
    print(json.dumps({"json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
