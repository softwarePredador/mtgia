#!/usr/bin/env python3
"""Safe Lorehold slot scan.

This script proposes and tests isolated swaps only for the current approved
baseline. It does not edit the battle engine directly and it refuses stale
deck state before scanning.
"""

from __future__ import annotations

import argparse
import json
import os
import tempfile
from collections import defaultdict
from pathlib import Path

from master_optimizer_common import (
    DEFAULT_DB,
    PROTECTED_CARDS,
    SCRIPT_DIR,
    assert_current_deck_matches_baseline,
    card_metadata,
    commander_legality,
    connect,
    deck_commander_identity,
    deck_rows,
    ensure_optimizer_tables,
    functional_tags_for_row,
    json_list,
    latest_baseline,
    normalize_name,
    quality_gate_candidate,
    run_battle,
    temporary_swap,
    utc_now,
)
import battle_rule_registry

KC_JSON = SCRIPT_DIR / "known_cards_generated.json"
LOCK_FILE = Path(
    os.environ.get("MANALOOM_SLOT_SCAN_LOCK", str(Path(tempfile.gettempdir()) / "optimizer_v3.lock"))
)

EFFECT_TO_CATEGORY = {
    "ramp_permanent": "ramp",
    "ramp_ritual": "ramp",
    "ramp_engine": "ramp",
    "silence_opponents": "protection",
    "indestructible": "protection",
    "phase_out": "protection",
    "counter": "protection",
    "draw_cards": "draw",
    "draw_engine": "draw",
    "topdeck_manipulation": "draw",
    "tutor": "tutor",
    "finisher": "wincon",
    "approach": "wincon",
    "token_maker": "wincon",
    "overload_recursion": "wincon",
    "steal_all_creatures": "wincon",
    "pump_all": "wincon",
    "extra_turn": "wincon",
    "board_wipe": "wipe",
    "remove_creature": "removal",
    "remove_permanent": "removal",
    "remove_artifact_or_3dmg": "removal",
    "copy_spell": "engine",
    "recursion": "engine",
    "ripple_engine": "engine",
}
# Roles reais do card_deck_analysis → categorias do optimizer
# Prioridade maxima: evita swaps entre categorias diferentes
REAL_ROLE_TO_CATEGORY = {
    "wincon": "wincon",
    "finisher": "wincon",
    "combo": "wincon",
    "removal": "removal",
    "spot_removal": "removal",
    "ramp": "ramp",
    "ritual": "ramp",
    "mana_rock": "ramp",
    "draw": "draw",
    "card_advantage": "draw",
    "tutor": "tutor",
    "board_wipe": "wipe",
    "wipe": "wipe",
    "protection": "protection",
    "stax": "protection",
    "counter": "protection",
    "recursion": "engine",
    "graveyard": "engine",
    "engine": "engine",
    "value_engine": "engine",
    "copy": "engine",
    "land": "land",
}


CATEGORY_TERMS = {
    "draw": ("draw", "card", "wheel", "discard", "exile the top", "impulse"),
    "engine": ("copy", "cast", "instant", "sorcery", "graveyard", "trigger"),
    "protection": ("prevent", "indestructible", "hexproof", "protection", "phase", "counter"),
    "ramp": ("treasure", "mana", "cost", "ritual", "artifact", "add "),
    "removal": ("destroy", "exile", "damage", "target", "permanent"),
    "tutor": ("search", "library", "reveal", "put into your hand"),
    "wincon": ("win the game", "damage", "token", "copy", "cast", "approach"),
    "wipe": ("destroy all", "exile all", "each creature", "all creatures", "board"),
}

MAX_CMC_BY_CATEGORY = {
    "draw": 6.0,
    "engine": 6.0,
    "protection": 5.0,
    "ramp": 6.0,
    "removal": 5.0,
    "tutor": 5.0,
    "wincon": 8.0,
    "wipe": 9.0,
}

BASICS = {"Plains", "Mountain", "Island", "Swamp", "Forest", "Wastes"}
EXTRA_PROTECTED = {
    "Deflecting Swat",
    "Esper Sentinel",
    "Smothering Tithe",
    "Dockside Extortionist",
    "Chrome Mox",
    "Mox Diamond",
    "Sol Ring",
}


_REAL_ROLES_CACHE = {}

def load_known_cards() -> dict[str, dict[str, object]]:
    if KC_JSON.exists():
        with KC_JSON.open("r", encoding="utf-8") as fh:
            known_cards = json.load(fh)
    else:
        known_cards = {}
    rules = battle_rule_registry.load_active_battle_card_rules(DEFAULT_DB)
    for rule in rules.values():
        name = str(rule.get("card_name") or "")
        effect = dict(rule.get("effect_json") or {})
        if not name or not effect:
            continue
        role = dict(rule.get("deck_role_json") or {})
        merged = dict(known_cards.get(name, {}))
        merged.update(effect)
        if role.get("category"):
            merged["deck_category"] = role["category"]
        merged["battle_rule_source"] = rule.get("source")
        merged["battle_rule_review_status"] = rule.get("review_status")
        known_cards[name] = merged
    return known_cards



def load_real_roles(conn, deck_id: int) -> dict[str, str]:
    roles = {}
    # 1. Try card_deck_analysis (detailed role analysis, most reliable)
    try:
        rows = conn.execute(
            "SELECT LOWER(card_name) as name, LOWER(role_in_deck) as role FROM card_deck_analysis WHERE deck_id = ? AND role_in_deck IS NOT NULL AND role_in_deck != ''",
            (deck_id,),
        ).fetchall()
        for row in rows:
            name = str(row["name"] or "").strip()
            role = str(row["role"] or "").strip().lower()
            if name and role:
                mapped = REAL_ROLE_TO_CATEGORY.get(role)
                if mapped:
                    roles[name] = mapped
    except Exception:
        pass

    # 2. Fallback: deck_cards functional tags. Prefer the multi-tag snapshot
    # when present, and never overwrite the detailed card_deck_analysis role.
    try:
        rows = conn.execute(
            "SELECT * FROM deck_cards WHERE deck_id = ?",
            (deck_id,),
        ).fetchall()
        for row in rows:
            name = normalize_name(row["card_name"])
            if not name or name in roles:
                continue
            for tag in functional_tags_for_row(row):
                mapped = REAL_ROLE_TO_CATEGORY.get(tag)
                if mapped:
                    roles[name] = mapped
                    break
    except Exception:
        pass

    return roles


def category_for_card(name: str, row, known_cards: dict[str, dict[str, object]]) -> str:
    type_line = str(row["type_line"] or "")
    if "Land" in type_line:
        return "land"
    entry = known_cards.get(name, {})
    # Prioridade 1: role real do card_deck_analysis (evita swap wincon <-> removal)
    real_role = _REAL_ROLES_CACHE.get(normalize_name(name), "")
    if real_role:
        return real_role
    if entry.get("deck_category"):
        return str(entry["deck_category"])
    effect = str(entry.get("effect") or "")
    if effect in EFFECT_TO_CATEGORY:
        return EFFECT_TO_CATEGORY[effect]
    tag_map = {
        "ramp": "ramp",
        "draw": "draw",
        "tutor": "tutor",
        "removal": "removal",
        "board_wipe": "wipe",
        "wincon": "wincon",
        "combo": "wincon",
        "protection": "protection",
        "stax": "protection",
        "engine": "engine",
        "land": "land",
    }
    for tag in functional_tags_for_row(row):
        if tag in tag_map:
            return tag_map[tag]
    return "unknown"


def candidate_score(name: str, entry: dict[str, object], meta, category: str) -> float:
    type_line = str(meta["type_line"] or "")
    oracle = str(meta["oracle_text"] or "").lower()
    cmc = float(meta["cmc"] if meta["cmc"] is not None else entry.get("cmc", 3) or 3)
    score = max(0.0, 8.0 - cmc)
    score += float(entry.get("count", 0) or 0) * 0.1

    if "Instant" in type_line or "Sorcery" in type_line:
        score += 2.0
    if "Artifact" in type_line and category == "ramp":
        score += 1.5
    if "Creature" in type_line and category not in {"wincon", "engine", "draw"}:
        score -= 1.0
    if category == "wipe" and cmc <= 6:
        score += 2.0
    if category == "wincon" and cmc >= 9:
        score -= 3.0

    for term in CATEGORY_TERMS.get(category, ()):
        if term in oracle:
            score += 1.0

    # Lorehold specifically rewards spells that can be copied, recurred, or cast
    # cheaply around the commander plan.
    for term in ("instant", "sorcery", "copy", "cast", "graveyard", "treasure"):
        if term in oracle:
            score += 0.5
    return score


def build_deck_categories(rows, known_cards):
    categories: dict[str, list[tuple[str, float]]] = defaultdict(list)
    for row in rows:
        if row["is_commander"]:
            continue
        name = str(row["card_name"])
        category = category_for_card(name, row, known_cards)
        cmc = float(row["cmc"] or 0)
        categories[category].append((name, cmc))
    return categories


def choose_swap_targets(deck_categories: dict[str, list[tuple[str, float]]]) -> dict[str, str]:
    protected = set(PROTECTED_CARDS) | EXTRA_PROTECTED
    targets: dict[str, str] = {}
    for category, cards in deck_categories.items():
        if category in {"land", "unknown"} or not cards:
            continue
        cuttable = [(name, cmc) for name, cmc in cards if name not in protected]
        if not cuttable:
            continue
        cuttable.sort(key=lambda item: (-item[1], item[0]))
        targets[category] = cuttable[0][0]
    return targets


def legal_candidates(conn, deck_id: int, known_cards, max_per_category: int, only_category: str):
    allowed = deck_commander_identity(conn, deck_id)
    deck_names = {normalize_name(row["card_name"]) for row in deck_rows(conn, deck_id)}
    by_category: dict[str, list[tuple[float, str, float, str, dict[str, object]]]] = defaultdict(list)
    stats = {"deck": 0, "basic": 0, "unknown_category": 0, "missing_meta": 0, "off_color": 0, "illegal": 0, "high_cmc": 0}

    for name, entry in known_cards.items():
        if normalize_name(name) in deck_names:
            stats["deck"] += 1
            continue
        if name in BASICS:
            stats["basic"] += 1
            continue
        effect = str(entry.get("effect") or "unknown")
        category = str(entry.get("deck_category") or EFFECT_TO_CATEGORY.get(effect, "unknown"))
        if category == "unknown" or category == "land":
            stats["unknown_category"] += 1
            continue
        if only_category and category != only_category:
            continue
        meta = card_metadata(conn, name)
        if not meta:
            stats["missing_meta"] += 1
            continue
        identity = set(json_list(meta["color_identity_json"]))
        if not identity.issubset(allowed):
            stats["off_color"] += 1
            continue
        legality = commander_legality(conn, name)
        if legality != "legal":
            stats["illegal"] += 1
            continue
        cmc = float(meta["cmc"] if meta["cmc"] is not None else entry.get("cmc", 3) or 3)
        if cmc > MAX_CMC_BY_CATEGORY.get(category, 8.0):
            stats["high_cmc"] += 1
            continue
        score = candidate_score(name, entry, meta, category)
        by_category[category].append((score, name, cmc, effect, entry))

    selected: dict[str, list[tuple[str, float, str, dict[str, object]]]] = {}
    for category, rows in by_category.items():
        rows.sort(key=lambda item: (-item[0], item[2], item[1]))
        selected[category] = [
            (name, cmc, effect, entry)
            for _, name, cmc, effect, entry in rows[:max_per_category]
        ]
    return selected, stats


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--deck-id", type=int, default=int(os.environ.get("MANALOOM_OPTIMIZER_DECK_ID", "6")))
    parser.add_argument("--games", type=int, default=int(os.environ.get("MANALOOM_SLOT_GAMES", "10")))
    parser.add_argument("--max-per-category", type=int, default=int(os.environ.get("MANALOOM_SLOT_MAX_PER_CATEGORY", "15")))
    parser.add_argument("--category", default="")
    parser.add_argument("--phase", default="phase1")
    parser.add_argument("--reset-current-baseline", action="store_true")
    args = parser.parse_args()

    if LOCK_FILE.exists():
        age = int(__import__("time").time() - LOCK_FILE.stat().st_mtime)
        if age < 43200:
            print(f"slot_scan=locked age_seconds={age}")
            return 0
        LOCK_FILE.unlink()
    LOCK_FILE.write_text(str(os.getpid()), encoding="utf-8")

    try:
        known_cards = load_known_cards()
        with connect() as conn:
            ensure_optimizer_tables(conn)
            baseline = latest_baseline(conn, args.deck_id)
            if not baseline:
                raise SystemExit("No approved baseline found. Run master_optimizer_baseline.py first.")
            assert_current_deck_matches_baseline(conn, args.deck_id, baseline)
            baseline_id = int(baseline["id"])
            baseline_hash = str(baseline["deck_hash"])
            baseline_wr = float(baseline["wr"])

            if args.reset_current_baseline:
                conn.execute(
                    """
                    DELETE FROM slot_benchmarks
                    WHERE deck_id=? AND baseline_id=? AND baseline_hash=? AND phase=?
                    """,
                    (args.deck_id, baseline_id, baseline_hash, args.phase),
                )
                conn.commit()

            rows = deck_rows(conn, args.deck_id)
            global _REAL_ROLES_CACHE
            _REAL_ROLES_CACHE = load_real_roles(conn, args.deck_id)
            deck_categories = build_deck_categories(rows, known_cards)
            targets = choose_swap_targets(deck_categories)
            candidates, stats = legal_candidates(
                conn,
                args.deck_id,
                known_cards,
                args.max_per_category,
                args.category,
            )

            total = sum(len(items) for items in candidates.values())
            print("=" * 72)
            print("SAFE LOREHOLD SLOT SCAN")
            print(f"deck_id={args.deck_id}")
            print(f"baseline_id={baseline_id}")
            print(f"baseline_wr={baseline_wr:.1f}%")
            print(f"baseline_hash={baseline_hash}")
            print(f"games_per_opponent={args.games}")
            print(f"max_per_category={args.max_per_category}")
            print(f"selected_candidates={total}")
            print(f"filter_stats={json.dumps(stats, sort_keys=True)}")
            print("\nCurrent deck composition:")
            for category, cards in sorted(deck_categories.items()):
                if category == "land":
                    continue
                avg = sum(cmc for _, cmc in cards) / max(1, len(cards))
                print(f"  {category:<12s} x{len(cards):<2d} avg_cmc={avg:.1f}")
            print("\nSwap targets:")
            for category, target in sorted(targets.items()):
                print(f"  {category:<12s} -> {target}")

            already_tested = {
                (row["card_added"], row["card_removed"])
                for row in conn.execute(
                    """
                    SELECT card_added, card_removed FROM slot_benchmarks
                    WHERE deck_id=? AND baseline_id=? AND baseline_hash=? AND phase=?
                    """,
                    (args.deck_id, baseline_id, baseline_hash, args.phase),
                )
            }

            tested = 0
            blocked = 0
            skipped = 0
            for category, items in sorted(candidates.items()):
                target = targets.get(category)
                if not target:
                    print(f"\n[{category}] skipped: no swap target")
                    skipped += len(items)
                    continue
                print(f"\n[{category}] {len(items)} selected candidates (cut target: {target})")
                for name, cmc, effect, _entry in items:
                    if (name, target) in already_tested:
                        print(f"  ={name:<36s} already tested")
                        skipped += 1
                        continue
                    review = quality_gate_candidate(conn, args.deck_id, name, target, "slot_scan")
                    if review["status"] != "passed":
                        print(f"  !{name:<36s} blocked: {', '.join(review['reasons'])}")
                        blocked += 1
                        continue
                    with temporary_swap(conn, args.deck_id, name, target, category):
                        result = run_battle(args.games)
                    delta = result.win_rate - baseline_wr
                    conn.execute(
                        """
                        INSERT INTO slot_benchmarks
                            (deck_id, baseline_id, baseline_hash, category,
                             card_added, card_removed, add_cmc, add_effect, add_tag,
                             wr, wins, losses, draws, games, delta_pp, phase, tested_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                        (
                            args.deck_id,
                            baseline_id,
                            baseline_hash,
                            category,
                            name,
                            target,
                            cmc,
                            effect,
                            category,
                            result.win_rate,
                            result.wins,
                            result.losses,
                            result.stalls,
                            result.total_games,
                            delta,
                            args.phase,
                            utc_now(),
                        ),
                    )
                    conn.commit()
                    tested += 1
                    marker = "UP" if delta > 0.5 else "DOWN" if delta < -0.5 else "FLAT"
                    print(
                        f"  +{name:<36s} WR={result.win_rate:>5.1f}% "
                        f"{marker} {delta:+.1f}pp "
                        f"record={result.wins}W/{result.losses}L/{result.stalls}S"
                    )

            print("\n" + "=" * 72)
            print("SLOT SCAN SUMMARY")
            print(f"tested={tested}")
            print(f"blocked={blocked}")
            print(f"skipped={skipped}")
            for category in sorted(candidates):
                rows = conn.execute(
                    """
                    SELECT card_added, card_removed, wr, delta_pp FROM slot_benchmarks
                    WHERE deck_id=? AND baseline_id=? AND baseline_hash=? AND phase=? AND category=?
                    ORDER BY wr DESC, delta_pp DESC
                    LIMIT 5
                    """,
                    (args.deck_id, baseline_id, baseline_hash, args.phase, category),
                ).fetchall()
                if not rows:
                    continue
                print(f"\n[{category}] top candidates")
                for idx, row in enumerate(rows, start=1):
                    print(
                        f"  {idx}. +{row['card_added']} "
                        f"(cut {row['card_removed']}) "
                        f"WR={float(row['wr']):.1f}% {float(row['delta_pp']):+.1f}pp"
                    )
            print("\nslot_scan=ok")
            return 0
    finally:
        try:
            LOCK_FILE.unlink()
        except FileNotFoundError:
            pass


if __name__ == "__main__":
    raise SystemExit(main())
