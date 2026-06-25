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

from known_cards_fallback_snapshot import load_layered_known_cards
from master_optimizer_common import (
    DEFAULT_DB,
    PROTECTED_CARDS,
    SCRIPT_DIR,
    assert_current_deck_matches_baseline,
    battle_gate_cli_lines,
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
    "attack_limit": "protection",
    "attack_tax": "protection",
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

REAL_CATEGORY_PRIORITY = [
    "wincon",
    "wipe",
    "removal",
    "tutor",
    "protection",
    "ramp",
    "draw",
    "engine",
    "land",
]


CATEGORY_TERMS = {
    "draw": ("draw", "card", "wheel", "discard", "exile the top", "impulse"),
    "engine": ("copy", "cast", "instant", "sorcery", "graveyard", "trigger"),
    "land": ("add", "mana", "any color", "sacrifice", "search", "draw"),
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
    "land": 99.0,
}

BASICS = {"Plains", "Mountain", "Island", "Swamp", "Forest", "Wastes"}
EXTRA_PROTECTED = {
    "Aetherflux Reservoir",
    "Deflecting Swat",
    "Drannith Magistrate",
    "Dualcaster Mage",
    "Heat Shimmer",
    "Enlightened Tutor",
    "Esper Sentinel",
    "Flawless Maneuver",
    "Gamble",
    "Giver of Runes",
    "Imperial Recruiter",
    "Land Tax",
    "Lightning Greaves",
    "Mizzix's Mastery",
    "Molten Duplication",
    "Mother of Runes",
    "Orim's Chant",
    "Past in Flames",
    "Recruiter of the Guard",
    "Reiterate",
    "Smothering Tithe",
    "Dockside Extortionist",
    "Chrome Mox",
    "Mox Diamond",
    "Ranger-Captain of Eos",
    "Rise of the Eldrazi",
    "Sol Ring",
    "The One Ring",
    "Twinflame",
    "Wheel of Fortune",
    "Wheel of Misfortune",
    "Worldfire",
}

LAND_CUT_PRIORITY = {
    # Prefer replacing basics or lower-ceiling utility lands before touching
    # premium fixing, fetches, artifact lands, Ancient Tomb, or Urza's Saga.
    "Mountain // Mountain": 0,
    "Plains // Plains": 1,
    "Mountain": 2,
    "Plains": 3,
    "Hall of Heliod's Generosity": 10,
    "Inventors' Fair": 11,
    "War Room": 12,
    "Sunbillow Verge": 20,
    "Sundown Pass": 21,
    "Inspiring Vantage": 22,
}

PREMIUM_LANDS = {
    "Ancient Den",
    "Ancient Tomb",
    "Arid Mesa",
    "Battlefield Forge",
    "Bloodstained Mire",
    "City of Brass",
    "Command Tower",
    "Elegant Parlor",
    "Flooded Strand",
    "Gemstone Caverns",
    "Great Furnace",
    "Mana Confluence",
    "Marsh Flats",
    "Plateau",
    "Prismatic Vista",
    "Rugged Prairie",
    "Sacred Foundry",
    "Scalding Tarn",
    "Spectator Seating",
    "Sunbaked Canyon",
    "Urza's Saga",
    "Windswept Heath",
    "Wooded Foothills",
}

LAND_CANDIDATE_PRIORITY = {
    "Cavern of Souls": 30.0,
    "Eiganjo, Seat of the Empire": 26.0,
    "Sokenzan, Crucible of Defiance": 24.0,
    "Exotic Orchard": 23.0,
    "Forbidden Orchard": 21.0,
    "Command Beacon": 18.0,
    "Fabled Passage": 16.0,
    "Spire of Industry": 14.0,
    "Plaza of Heroes": 10.0,
    "Ash Barrens": 8.0,
}

LOW_CEILING_LAND_TERMS = (
    "enters the battlefield tapped",
    "enters tapped",
    "depletion counter",
    "charge counter",
)

LOW_VALUE_BOROS_LANDS = {
    # Legal in Commander due no color identity, but they cannot fetch the
    # Mountain/Plains dual package and should not outrank real RW fixing.
    "Misty Rainforest",
    "Polluted Delta",
    "Verdant Catacombs",
}


_REAL_ROLES_CACHE = {}


def parse_analysis_roles(raw) -> list[str]:
    if not raw:
        return []
    try:
        parsed = json.loads(raw)
        if isinstance(parsed, list):
            return [str(role).strip().lower() for role in parsed if str(role).strip()]
    except Exception:
        pass
    return [str(role).strip().lower() for role in str(raw).split(",") if role.strip()]


def name_variants(name: str) -> set[str]:
    variants = {normalize_name(name)}
    if "//" in str(name):
        for part in str(name).split("//"):
            normalized = normalize_name(part)
            if normalized:
                variants.add(normalized)
    return variants


def load_candidate_allowlist(
    matrix_path: str,
    lane: str = "priority_benchmark_candidate",
) -> set[str]:
    if not matrix_path:
        return set()
    path = Path(matrix_path)
    data = json.loads(path.read_text(encoding="utf-8"))
    rows = data.get("rows") or data.get("matrix_rows") or []
    allowed: set[str] = set()
    for row in rows:
        if str(row.get("recommendation_lane") or "") != lane:
            continue
        if str(row.get("rule_status") or "") != "battle_ready":
            continue
        card_name = str(row.get("card_name") or row.get("name") or "").strip()
        if not card_name:
            continue
        allowed.update(name_variants(card_name))
    return allowed


def choose_primary_category(categories: list[str]) -> str | None:
    present = set(categories)
    for category in REAL_CATEGORY_PRIORITY:
        if category in present:
            return category
    return categories[0] if categories else None


def load_known_cards() -> dict[str, dict[str, object]]:
    known_cards, _canonical_names, _generated_only_names = load_layered_known_cards()
    rule_lists = battle_rule_registry.load_active_battle_card_rule_lists(DEFAULT_DB)
    for rules in rule_lists.values():
        if not rules:
            continue
        rule = rules[0]
        name = str(rule.get("card_name") or "")
        effect = dict(rule.get("effect_json") or {})
        if not name or not effect:
            continue
        categories = [
            str(role.get("category"))
            for role in (dict(item.get("deck_role_json") or {}) for item in rules)
            if role.get("category")
        ]
        merged = dict(known_cards.get(name, {}))
        merged.update(effect)
        primary_category = choose_primary_category(categories)
        if primary_category:
            merged["deck_category"] = primary_category
        merged["battle_rules"] = [dict(item.get("effect_json") or {}) for item in rules]
        merged["battle_rule_categories"] = sorted(set(categories))
        merged["battle_rule_source"] = rule.get("source")
        merged["battle_rule_review_status"] = rule.get("review_status")
        merged["battle_rule_execution_status"] = rule.get("execution_status")
        known_cards[name] = merged
    return known_cards



def load_real_roles(conn, deck_id: int) -> dict[str, str]:
    roles = {}
    # 1. Try card_deck_analysis (detailed role analysis, most reliable)
    try:
        columns = {
            row[1]
            for row in conn.execute("PRAGMA table_info(card_deck_analysis)").fetchall()
        }
        if "role_in_deck" not in columns:
            columns = set()
        pg_roles_expr = "pg_roles" if "pg_roles" in columns else "NULL AS pg_roles"
        role_filter = (
            "((role_in_deck IS NOT NULL AND role_in_deck != '') OR pg_roles IS NOT NULL)"
            if "pg_roles" in columns
            else "(role_in_deck IS NOT NULL AND role_in_deck != '')"
        )
        rows = conn.execute(
            f"""
            SELECT LOWER(card_name) as name, LOWER(role_in_deck) as role, {pg_roles_expr}
            FROM card_deck_analysis
            WHERE deck_id = ?
              AND {role_filter}
            """,
            (deck_id,),
        ).fetchall()
        categories_by_name = defaultdict(list)
        for row in rows:
            name = str(row["name"] or "").strip()
            if not name:
                continue
            raw_roles = parse_analysis_roles(row["pg_roles"])
            role = str(row["role"] or "").strip().lower()
            if role:
                raw_roles.append(role)
            for raw_role in raw_roles:
                role = raw_role.strip().lower()
                mapped = REAL_ROLE_TO_CATEGORY.get(role)
                if mapped and mapped not in categories_by_name[name]:
                    categories_by_name[name].append(mapped)
        for name, categories in categories_by_name.items():
            primary = choose_primary_category(categories)
            if primary:
                roles[name] = primary
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
            categories: list[str] = []
            for tag in functional_tags_for_row(row):
                mapped = REAL_ROLE_TO_CATEGORY.get(tag)
                if mapped and mapped not in categories:
                    categories.append(mapped)
            primary = choose_primary_category(categories)
            if primary:
                roles[name] = primary
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

    if category == "land":
        score = 5.0
        score += LAND_CANDIDATE_PRIORITY.get(name, 0.0)
        if name in LOW_VALUE_BOROS_LANDS:
            score -= 20.0
        if "Land" in type_line:
            score += 2.0
        if any(term in oracle for term in LOW_CEILING_LAND_TERMS):
            score -= 3.0
        if "any color" in oracle or "one mana of any color" in oracle:
            score += 2.0
        if "search your library" in oracle:
            score += 1.5
        if "draw a card" in oracle:
            score += 1.0
        if "Artifact Land" in type_line:
            score += 1.0
        return score

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
        if category == "unknown" or not cards:
            continue
        if category == "land":
            cuttable = [
                (name, cmc)
                for name, cmc in cards
                if name not in protected and name not in PREMIUM_LANDS
            ]
            if not cuttable:
                cuttable = [(name, cmc) for name, cmc in cards if name not in protected]
            cuttable.sort(key=lambda item: (LAND_CUT_PRIORITY.get(item[0], 100), item[0]))
            targets[category] = cuttable[0][0]
            continue
        cuttable = [(name, cmc) for name, cmc in cards if name not in protected]
        if not cuttable:
            continue
        cuttable.sort(key=lambda item: (-item[1], item[0]))
        targets[category] = cuttable[0][0]
    return targets


def legal_candidates(
    conn,
    deck_id: int,
    known_cards,
    max_per_category: int,
    only_category: str,
    allowed_candidate_names: set[str] | None = None,
):
    allowed = deck_commander_identity(conn, deck_id)
    deck_names = {
        variant
        for row in deck_rows(conn, deck_id)
        for variant in name_variants(str(row["card_name"]))
    }
    by_category: dict[str, list[tuple[float, str, float, str, dict[str, object]]]] = defaultdict(list)
    stats = {
        "deck": 0,
        "basic": 0,
        "not_in_candidate_matrix": 0,
        "unknown_category": 0,
        "missing_meta": 0,
        "off_color": 0,
        "illegal": 0,
        "high_cmc": 0,
    }

    for name, entry in known_cards.items():
        variants = name_variants(name)
        if variants & deck_names:
            stats["deck"] += 1
            continue
        if name in BASICS:
            stats["basic"] += 1
            continue
        if allowed_candidate_names and not (variants & allowed_candidate_names):
            stats["not_in_candidate_matrix"] += 1
            continue
        effect = str(entry.get("effect") or "unknown")
        category = str(entry.get("deck_category") or EFFECT_TO_CATEGORY.get(effect, "unknown"))
        if category == "unknown":
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
    parser.add_argument("--candidate-matrix", default="")
    parser.add_argument("--candidate-lane", default="priority_benchmark_candidate")
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
        allowed_candidate_names = load_candidate_allowlist(args.candidate_matrix, args.candidate_lane)
        with connect() as conn:
            ensure_optimizer_tables(conn)
            baseline = latest_baseline(conn, args.deck_id)
            if not baseline:
                raise SystemExit("No approved baseline found. Run master_optimizer_baseline.py first.")
            assert_current_deck_matches_baseline(conn, args.deck_id, baseline)
            baseline_id = int(baseline["id"])
            baseline_hash = str(baseline["deck_hash"])
            baseline_semantics_hash = str(baseline["semantics_hash"] or "")
            baseline_ruleset_hash = str(baseline["ruleset_hash"] or "")
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
                allowed_candidate_names,
            )

            total = sum(len(items) for items in candidates.values())
            print("=" * 72)
            print("SAFE LOREHOLD SLOT SCAN")
            print(f"deck_id={args.deck_id}")
            print(f"baseline_id={baseline_id}")
            print(f"baseline_wr={baseline_wr:.1f}%")
            print(f"baseline_hash={baseline_hash}")
            print(f"baseline_semantics_hash={baseline_semantics_hash or 'legacy-missing'}")
            print(f"baseline_ruleset_hash={baseline_ruleset_hash or 'legacy-missing'}")
            if args.candidate_matrix:
                print(f"candidate_matrix={args.candidate_matrix}")
                print(f"candidate_lane={args.candidate_lane}")
                print(f"candidate_allowlist_size={len(allowed_candidate_names)}")
            for line in battle_gate_cli_lines():
                print(line)
            print(f"games_per_opponent={args.games}")
            print(f"max_per_category={args.max_per_category}")
            print(f"selected_candidates={total}")
            print(f"filter_stats={json.dumps(stats, sort_keys=True)}")
            print("\nCurrent deck composition:")
            for category, cards in sorted(deck_categories.items()):
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
                            (deck_id, baseline_id, baseline_hash,
                             baseline_semantics_hash, baseline_ruleset_hash,
                             category,
                             card_added, card_removed, add_cmc, add_effect, add_tag,
                             wr, wins, losses, draws, games, delta_pp, phase, tested_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                        (
                            args.deck_id,
                            baseline_id,
                            baseline_hash,
                            baseline_semantics_hash,
                            baseline_ruleset_hash,
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
