#!/usr/bin/env python3
"""Deterministic ManaLoom mana-base validator for Hermes cron migration."""

from __future__ import annotations

import argparse
import glob
import json
import os
import re
import sqlite3
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def _resolve_repo_root() -> Path:
    if os.environ.get("MANALOOM_REPO"):
        return Path(os.environ["MANALOOM_REPO"]).resolve()
    return Path(__file__).resolve().parents[2]


REPO_ROOT = _resolve_repo_root()
DATA_ROOT = Path(os.environ.get("MANALOOM_OPS_DATA_DIR", "/data/manaloom-ops")).resolve()
DEFAULT_DB = (
    REPO_ROOT / "docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
)
DEFAULT_ARTIFACTS = REPO_ROOT / "server/test/artifacts"
DEFAULT_REPORT = (
    DATA_ROOT / "artifacts/hermes_mana_base_validator/latest_mana_base_validation_report.md"
)

ROLE_TO_TAG = {
    "lands": "lands",
    "ramp": "ramp",
    "ramp_fixing": "ramp",
    "ramp_extra_lands": "ramp",
    "ramp_treasure": "ramp",
    "ramp_rocks": "ramp",
    "ramp_any": "ramp",
    "mana_dorks": "ramp",
    "mana_creatures": "ramp",
    "nonland_mana_sources": "ramp",
    "rituals": "ramp",
    "artifact_mana": "ramp",
    "treasure_generation": "ramp",
    "draw": "draw",
    "supplemental_draw": "draw",
    "draw_value": "draw",
    "card_advantage": "draw",
    "removal": "removal",
    "interaction": "removal",
    "interaction_counter": "removal",
    "tutor": "tutor",
    "tutors": "tutor",
    "board_wipe": "board_wipe",
    "wipe": "board_wipe",
    "board_wipes_bounce": "board_wipe",
    "protection": "protection",
    "interaction_protection": "protection",
    "graveyard_protection": "protection",
    "stax_disruption": "protection",
    "wincon": "wincon",
    "finishers": "wincon",
    "combo_finishers": "wincon",
    "storm_combo": "wincon",
    "recursion": "recursion",
    "recursion_value": "recursion",
    "land_recursion_bounce": "recursion",
    "engine": "engine",
    "big_spell": "engine",
    "counter_payoffs": "engine",
    "proliferate_engines": "engine",
    "planeswalkers_superfriends": "engine",
    "landfall_payoffs": "engine",
    "payoffs_outlets": "engine",
    "sacrifice_fodder": "engine",
    "sacrifice_outlets": "engine",
    "aristocrat_payoffs": "engine",
    "self_mill": "engine",
    "exile_casting": "engine",
    "treasure_payoffs": "engine",
    "nonhuman_enablers": "engine",
    "human_hits": "engine",
    "combat_payoffs": "engine",
    "evasive_enablers": "engine",
    "ninjas": "engine",
    "topdeck_manipulation": "engine",
    "high_mv_reveals": "engine",
    "cheap_creature_density": "engine",
    "bounce_loop_pieces": "engine",
    "infinite_mana_pieces": "engine",
}

DISPLAY_NAMES = {
    "lands": "Lands",
    "ramp": "Ramp",
    "draw": "Draw",
    "removal": "Removal",
    "tutor": "Tutor",
    "board_wipe": "Board wipe",
    "protection": "Protection",
    "wincon": "Wincon",
    "recursion": "Recursion",
    "engine": "Engine",
}


@dataclass(frozen=True)
class RoleCheck:
    role: str
    tag: str
    value: int
    minimum: int | None
    maximum: int | None
    status: str
    diff: int


@dataclass(frozen=True)
class DeckValidation:
    deck_id: int
    deck_name: str
    commander: str
    total_cards: int
    status: str
    profile_loaded: bool
    lands: int
    ramp: int
    draw: int
    unknown: int
    avg_cmc: float | None
    role_checks: tuple[RoleCheck, ...]
    notes: tuple[str, ...]


def slug(name: str) -> str:
    value = name.lower().replace("'", "").replace(",", " ").replace("-", " ")
    return re.sub(r"[^a-z0-9]+", "_", value).strip("_")


def _range_status(value: int, minimum: int | None, maximum: int | None) -> tuple[str, int]:
    if minimum is None or maximum is None:
        return "NA", 0
    if value < minimum:
        diff = minimum - value
    elif value > maximum:
        diff = value - maximum
    else:
        return "OK", 0
    if diff == 1:
        return "BLUE", diff
    if diff <= 3:
        return "WARN", diff
    return "CRIT", diff


def find_profile(artifacts_dir: Path, commander: str) -> Path | None:
    pattern = str(
        artifacts_dir
        / "commander_reference_profile_*"
        / "profiles"
        / f"{slug(commander)}.json"
    )
    matches = sorted(glob.glob(pattern))
    return Path(matches[0]) if matches else None


def load_profile(artifacts_dir: Path, commander: str) -> dict[str, Any] | None:
    path = find_profile(artifacts_dir, commander)
    if not path:
        return None
    return json.loads(path.read_text())


def _table_exists(conn: sqlite3.Connection, table: str) -> bool:
    return (
        conn.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
            (table,),
        ).fetchone()
        is not None
    )


def _table_columns(conn: sqlite3.Connection, table: str) -> set[str]:
    return {str(row[1]) for row in conn.execute(f"PRAGMA table_info({table})").fetchall()}


def validate(conn: sqlite3.Connection, artifacts_dir: Path) -> list[DeckValidation]:
    if not all(_table_exists(conn, name) for name in ("decks", "deck_cards")):
        raise RuntimeError("knowledge.db missing required decks/deck_cards tables")
    conn.row_factory = sqlite3.Row
    deck_columns = _table_columns(conn, "decks")
    if "commander_id" in deck_columns and _table_exists(conn, "commanders"):
        commander_select = "c.name AS commander"
        commander_join = "JOIN commanders c ON c.id = d.commander_id"
    else:
        commander_select = """
               COALESCE(
                 (
                   SELECT dc2.card_name
                   FROM deck_cards dc2
                   WHERE dc2.deck_id = d.id AND COALESCE(dc2.is_commander, 0) = 1
                   ORDER BY dc2.id
                   LIMIT 1
                 ),
                 d.deck_name
               ) AS commander
        """
        commander_join = ""
    rows = conn.execute(
        f"""
        SELECT d.id, d.deck_name, d.archetype,
               {commander_select},
               COALESCE(SUM(dc.quantity), 0) AS total_cards,
               COALESCE(SUM(CASE WHEN dc.functional_tag='land' THEN dc.quantity ELSE 0 END), 0) AS lands,
               COALESCE(SUM(CASE WHEN dc.functional_tag='ramp' THEN dc.quantity ELSE 0 END), 0) AS ramp,
               COALESCE(SUM(CASE WHEN dc.functional_tag='draw' THEN dc.quantity ELSE 0 END), 0) AS draw,
               COALESCE(SUM(CASE WHEN dc.functional_tag='removal' THEN dc.quantity ELSE 0 END), 0) AS removal,
               COALESCE(SUM(CASE WHEN dc.functional_tag='tutor' THEN dc.quantity ELSE 0 END), 0) AS tutor,
               COALESCE(SUM(CASE WHEN dc.functional_tag='board_wipe' THEN dc.quantity ELSE 0 END), 0) AS board_wipe,
               COALESCE(SUM(CASE WHEN dc.functional_tag='protection' THEN dc.quantity ELSE 0 END), 0) AS protection,
               COALESCE(SUM(CASE WHEN dc.functional_tag='recursion' THEN dc.quantity ELSE 0 END), 0) AS recursion,
               COALESCE(SUM(CASE WHEN dc.functional_tag='wincon' THEN dc.quantity ELSE 0 END), 0) AS wincon,
               COALESCE(SUM(CASE WHEN dc.functional_tag='engine' THEN dc.quantity ELSE 0 END), 0) AS engine,
               COALESCE(SUM(CASE WHEN dc.functional_tag IS NULL OR dc.functional_tag='unknown' THEN dc.quantity ELSE 0 END), 0) AS unknown,
               ROUND(AVG(dc.cmc), 2) AS avg_cmc
        FROM decks d
        {commander_join}
        LEFT JOIN deck_cards dc ON dc.deck_id = d.id
        GROUP BY d.id
        ORDER BY d.id
        """
    ).fetchall()

    results: list[DeckValidation] = []
    for row in rows:
        commander = str(row["commander"])
        total_cards = int(row["total_cards"] or 0)
        tag_counts = {
            "lands": int(row["lands"] or 0),
            "ramp": int(row["ramp"] or 0),
            "draw": int(row["draw"] or 0),
            "removal": int(row["removal"] or 0),
            "tutor": int(row["tutor"] or 0),
            "board_wipe": int(row["board_wipe"] or 0),
            "protection": int(row["protection"] or 0),
            "recursion": int(row["recursion"] or 0),
            "wincon": int(row["wincon"] or 0),
            "engine": int(row["engine"] or 0),
        }
        unknown = int(row["unknown"] or 0)
        notes: list[str] = []
        checks: list[RoleCheck] = []
        profile = load_profile(artifacts_dir, commander)

        if total_cards > 100:
            status = "OVERFULL"
            notes.append(f"{total_cards} cards stored; Commander learned decks should cap at 100.")
        elif total_cards < 50:
            status = "INCOMPLETE"
            notes.append(f"Only {total_cards} cards stored; seed/partial deck, not actionable.")
        elif not profile:
            status = "NO_PROFILE"
            notes.append("No local EDHREC commander profile found.")
        else:
            role_targets = profile.get("role_targets", {})
            for role, target in role_targets.items():
                tag = ROLE_TO_TAG.get(role)
                if not tag:
                    continue
                value = tag_counts.get(tag, 0)
                minimum = target.get("min")
                maximum = target.get("max")
                role_status, diff = _range_status(value, minimum, maximum)
                checks.append(
                    RoleCheck(
                        role=role,
                        tag=tag,
                        value=value,
                        minimum=minimum,
                        maximum=maximum,
                        status=role_status,
                        diff=diff,
                    )
                )
            statuses = [check.status for check in checks]
            if "CRIT" in statuses:
                status = "CRIT"
            elif "WARN" in statuses:
                status = "WARN"
            elif "BLUE" in statuses:
                status = "BLUE"
            else:
                status = "OK"

        if unknown:
            notes.append(f"{unknown} cards have unknown/null functional tag.")

        results.append(
            DeckValidation(
                deck_id=int(row["id"]),
                deck_name=str(row["deck_name"]),
                commander=commander,
                total_cards=total_cards,
                status=status,
                profile_loaded=profile is not None,
                lands=tag_counts["lands"],
                ramp=tag_counts["ramp"],
                draw=tag_counts["draw"],
                unknown=unknown,
                avg_cmc=float(row["avg_cmc"]) if row["avg_cmc"] is not None else None,
                role_checks=tuple(checks),
                notes=tuple(notes),
            )
        )
    return results


def _format_cmc(value: float | None) -> str:
    return "-" if value is None else f"{value:.2f}".rstrip("0").rstrip(".")


def build_report(results: list[DeckValidation]) -> str:
    counts: dict[str, int] = {}
    for result in results:
        counts[result.status] = counts.get(result.status, 0) + 1
    lines = [
        "# Mana Base Validation Report",
        "",
        f"Generated: {datetime.now(timezone.utc).isoformat()}",
        "",
        "## Summary",
        "",
        f"- decks_analyzed: {len(results)}",
        f"- status_counts: {json.dumps(counts, sort_keys=True)}",
        "",
        "## Decks",
        "",
        "| Status | Deck | Commander | Cards | Lands | Ramp | Draw | Avg CMC | Notes |",
        "|---|---|---|---:|---:|---:|---:|---:|---|",
    ]
    for result in results:
        notes = "<br>".join(result.notes) if result.notes else "-"
        lines.append(
            "| {status} | {deck} | {commander} | {cards} | {lands} | {ramp} | {draw} | {cmc} | {notes} |".format(
                status=result.status,
                deck=result.deck_name.replace("|", "\\|"),
                commander=result.commander.replace("|", "\\|"),
                cards=result.total_cards,
                lands=result.lands,
                ramp=result.ramp,
                draw=result.draw,
                cmc=_format_cmc(result.avg_cmc),
                notes=notes.replace("|", "\\|"),
            )
        )

    flagged = [
        r
        for r in results
        if r.status in {"CRIT", "WARN", "OVERFULL", "INCOMPLETE", "NO_PROFILE"}
    ]
    lines.extend(["", "## Required Attention", ""])
    if not flagged:
        lines.append("- None.")
    for result in flagged:
        top_checks = [
            c
            for c in result.role_checks
            if c.status in {"CRIT", "WARN", "BLUE"} and c.tag in {"lands", "ramp", "draw", "removal", "wincon", "protection"}
        ][:5]
        check_text = "; ".join(
            f"{DISPLAY_NAMES.get(c.tag, c.tag)}={c.value} vs [{c.minimum}-{c.maximum}] {c.status}"
            for c in top_checks
        )
        if not check_text:
            check_text = "; ".join(result.notes) if result.notes else result.status
        lines.append(f"- {result.status} `{result.commander}` / `{result.deck_name}`: {check_text}")
    return "\n".join(lines) + "\n"


def write_report(path: Path, report: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(report)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", default=os.environ.get("HERMES_KNOWLEDGE_DB", str(DEFAULT_DB)))
    parser.add_argument("--artifacts-dir", default=os.environ.get("HERMES_PROFILE_ARTIFACTS_DIR", str(DEFAULT_ARTIFACTS)))
    parser.add_argument("--output", default=os.environ.get("HERMES_MANA_BASE_REPORT", str(DEFAULT_REPORT)))
    parser.add_argument("--stdout-only", action="store_true")
    args = parser.parse_args(argv)

    with sqlite3.connect(args.db) as conn:
        results = validate(conn, Path(args.artifacts_dir))
    report = build_report(results)
    if not args.stdout_only:
        write_report(Path(args.output), report)
    print(report, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
