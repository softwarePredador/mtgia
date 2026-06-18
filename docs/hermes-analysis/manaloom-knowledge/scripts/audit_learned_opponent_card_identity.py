#!/usr/bin/env python3
"""Report-only audit for stable IDs in learned opponent cardlists.

Battle replays can only emit `card_id`/semantic provenance when a card came
from a trusted snapshot. This script measures whether real learned-opponent
decklists can be resolved against PostgreSQL `cards` without writing anything.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
import unicodedata
from collections import Counter
from pathlib import Path
from typing import Any

from battle_rule_registry import DEFAULT_DB, normalize_card_name
from db_helper import connect, sanitized_database_target


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sqlite-db", default=str(DEFAULT_DB))
    parser.add_argument("--candidate-limit", type=int, default=96)
    parser.add_argument("--deck-limit", type=int, default=12)
    parser.add_argument("--min-cards", type=int, default=80)
    parser.add_argument("--report")
    return parser.parse_args()


def decode_card_list(value: Any) -> list[dict[str, Any]]:
    if not value:
        return []
    text = str(value)
    try:
        decoded = json.loads(text)
    except Exception:
        decoded = None
    if isinstance(decoded, list):
        return [
            item if isinstance(item, dict) else {"name": str(item)}
            for item in decoded
            if item
        ]

    cards: list[dict[str, Any]] = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if (
            not line
            or line.startswith("#")
            or line.lower() in ("deck", "commander", "sideboard", "maybeboard")
        ):
            continue
        line = re.sub(r"^(sb:|sideboard:)\s*", "", line, flags=re.I).strip()
        match = re.match(r"^(\d+)\s*x?\s+(.+)$", line, flags=re.I)
        if not match:
            continue
        quantity = max(1, min(30, int(match.group(1))))
        name = re.sub(r"\s+\([^)]*\)\s*\d*\s*$", "", match.group(2)).strip()
        if name:
            cards.append({"name": name, "quantity": quantity})
    return cards


def quantity(value: Any) -> int:
    try:
        return max(1, min(30, int(value)))
    except (TypeError, ValueError):
        return 1


def accentless_name_key(name: str) -> str:
    """Normalize accents/punctuation for report-only name diagnostics.

    This is intentionally not a persistence identity. It helps classify cases
    like `Lim-Dul's Vault` vs `Lim-Dûl's Vault` without choosing an arbitrary
    printing or mutating PostgreSQL/Hermes data.
    """

    decomposed = unicodedata.normalize("NFKD", str(name or ""))
    ascii_text = "".join(ch for ch in decomposed if not unicodedata.combining(ch))
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9]+", " ", ascii_text.lower())).strip()


def _longest_lookup_token(key: str) -> str | None:
    tokens = [token for token in re.findall(r"[a-z0-9]+", key.lower()) if len(token) >= 4]
    if not tokens:
        return None
    return max(tokens, key=len)


def _candidate_card_id(candidate: tuple[Any, ...]) -> str:
    return str(candidate[0])


def _candidate_oracle_id(candidate: tuple[Any, ...]) -> str | None:
    if len(candidate) < 3:
        return None
    value = str(candidate[2] or "").strip()
    return value or None


def _candidate_value(candidate: tuple[Any, ...], index: int) -> str | None:
    if len(candidate) <= index:
        return None
    value = str(candidate[index] or "").strip()
    return value or None


def _canonical_printing_candidate(
    candidates: list[tuple[Any, ...]],
) -> tuple[str | None, str | None]:
    """Report a canonical printing candidate only with a unique evidence winner."""

    scored: list[tuple[int, str, str]] = []
    for candidate in candidates:
        card_id = _candidate_card_id(candidate)
        oracle_id = _candidate_oracle_id(candidate)
        scryfall_id = _candidate_value(candidate, 3)
        set_code = _candidate_value(candidate, 4)
        collector_number = _candidate_value(candidate, 5)
        image_url = _candidate_value(candidate, 6) or ""
        layout = (_candidate_value(candidate, 7) or "").lower()
        rarity = _candidate_value(candidate, 8)

        score = 0
        reasons: list[str] = []
        if scryfall_id and oracle_id and scryfall_id != oracle_id:
            score += 4
            reasons.append("printing_id")
        if image_url.startswith("https://cards.scryfall.io/"):
            score += 3
            reasons.append("direct_scryfall_image")
        if layout and layout not in {"token", "art_series"}:
            score += 2
            reasons.append(f"layout:{layout}")
        if collector_number:
            score += 1
            reasons.append("collector_number")
        if set_code:
            score += 1
            reasons.append("set_code")
        if rarity:
            score += 1
            reasons.append("rarity")
        if score > 0 and reasons:
            scored.append((score, ",".join(reasons), card_id))

    if not scored:
        return None, None

    scored.sort(reverse=True)
    best_score, best_reason, best_card_id = scored[0]
    second_score = scored[1][0] if len(scored) > 1 else -1
    if best_score <= second_score:
        return None, None
    return best_card_id, f"unique_highest_score:{best_score}:{best_reason}"


def _classify_candidate_groups(
    *,
    exact: list[tuple[Any, ...]],
    front: list[tuple[Any, ...]],
    accent: list[tuple[Any, ...]],
) -> tuple[str, str | None, str, int, str | None, str | None, str | None]:
    """Return classification plus optional report-only canonical printing.

    A single PG row resolves to a concrete `card_id`. Multiple printings sharing
    one `oracle_id` resolve only to semantic identity; the audit must not choose
    an arbitrary printing for learned opponents.
    """

    groups = (
        ("exact", exact),
        ("front", front),
        ("accent_normalized", accent),
    )
    for kind, candidates in groups:
        if len(candidates) == 1:
            return (
                "resolved",
                _candidate_card_id(candidates[0]),
                kind,
                1,
                _candidate_oracle_id(candidates[0]),
                None,
                None,
            )
        if len(candidates) > 1:
            oracle_ids = {
                oracle_id
                for oracle_id in (
                    _candidate_oracle_id(candidate) for candidate in candidates
                )
                if oracle_id
            }
            if len(oracle_ids) == 1 and all(
                _candidate_oracle_id(candidate) for candidate in candidates
            ):
                canonical_card_id, canonical_reason = _canonical_printing_candidate(
                    candidates
                )
                return (
                    "oracle_resolved",
                    None,
                    f"multiple_printings_same_oracle_{kind}",
                    len(candidates),
                    next(iter(oracle_ids)),
                    canonical_card_id,
                    canonical_reason,
                )
            return (
                "ambiguous",
                None,
                f"multiple_printings_{kind}",
                len(candidates),
                None,
                None,
                None,
            )
    return "unresolved", None, "no_match", 0, None, None, None


def pg_has_oracle_id_column(cur: Any) -> bool:
    cur.execute(
        """
        SELECT EXISTS (
          SELECT 1
          FROM information_schema.columns
          WHERE table_schema = 'public'
            AND table_name = 'cards'
            AND column_name = 'oracle_id'
        )
        """
    )
    row = cur.fetchone()
    return bool(row and row[0])


def load_learned_rows(
    sqlite_db: str | Path,
    *,
    candidate_limit: int,
    deck_limit: int,
    min_cards: int,
) -> list[dict[str, Any]]:
    conn = sqlite3.connect(sqlite_db)
    conn.row_factory = sqlite3.Row
    try:
        rows = conn.execute(
            """
            SELECT id, commander, source, archetype, card_count, card_list
            FROM learned_decks
            WHERE COALESCE(commander, '') != ''
              AND commander NOT LIKE '%Lorehold%'
              AND COALESCE(card_list, '') != ''
              AND length(card_list) >= 500
              AND COALESCE(card_count, 0) >= ?
            ORDER BY
              CASE WHEN source = 'pg_meta_decks' THEN 0 ELSE 1 END,
              COALESCE(card_count, 0) DESC,
              id DESC
            LIMIT ?
            """,
            (min_cards, candidate_limit),
        ).fetchall()
    finally:
        conn.close()

    decks: list[dict[str, Any]] = []
    for row in rows:
        cards = decode_card_list(row["card_list"])
        expanded_count = sum(quantity(card.get("quantity")) for card in cards)
        if expanded_count < min_cards:
            continue
        decks.append(
            {
                "id": row["id"],
                "commander": row["commander"],
                "source": row["source"],
                "archetype": row["archetype"],
                "card_count": row["card_count"],
                "cards": cards,
                "expanded_count": expanded_count,
            }
        )
        if len(decks) >= deck_limit:
            break
    return decks


def resolve_names(
    names: set[str],
) -> tuple[
    dict[str, str],
    dict[str, int],
    dict[str, str],
    dict[str, str],
    dict[str, str],
    dict[str, str],
    dict[str, str],
    dict[str, str],
    bool,
]:
    normalized_names = sorted({normalize_card_name(name) for name in names if name})
    if not normalized_names:
        return {}, {}, {}, {}, {}, {}, {}, {}, False
    resolved: dict[str, str] = {}
    oracle_resolved: dict[str, str] = {}
    ambiguous: dict[str, int] = {}
    resolved_kind: dict[str, str] = {}
    oracle_resolved_kind: dict[str, str] = {}
    oracle_canonical_card_id: dict[str, str] = {}
    oracle_canonical_reason: dict[str, str] = {}
    ambiguous_kind: dict[str, str] = {}
    oracle_id_column_present = False
    with connect() as conn:
        with conn.cursor() as cur:
            oracle_id_column_present = pg_has_oracle_id_column(cur)
            oracle_select_sql = (
                "oracle_id::text" if oracle_id_column_present else "NULL::text"
            )
            for index in range(0, len(normalized_names), 500):
                chunk = normalized_names[index : index + 500]
                cur.execute(
                    f"""
                    SELECT
                      id::text,
                      name,
                      {oracle_select_sql},
                      scryfall_id::text,
                      set_code,
                      collector_number,
                      image_url,
                      layout,
                      rarity
                    FROM cards
                    WHERE lower(name) = ANY(%s)
                       OR lower(split_part(name, ' // ', 1)) = ANY(%s)
                    """,
                    (chunk, chunk),
                )
                candidates_by_key: dict[str, list[tuple[Any, ...]]] = {
                    key: [] for key in chunk
                }
                for row in cur.fetchall():
                    (
                        card_id,
                        card_name,
                        oracle_id,
                        scryfall_id,
                        set_code,
                        collector_number,
                        image_url,
                        layout,
                        rarity,
                    ) = row
                    exact_key = normalize_card_name(card_name)
                    front_key = normalize_card_name(str(card_name).split(" // ", 1)[0])
                    candidate = (
                        card_id,
                        card_name,
                        oracle_id,
                        scryfall_id,
                        set_code,
                        collector_number,
                        image_url,
                        layout,
                        rarity,
                    )
                    if exact_key in candidates_by_key:
                        candidates_by_key[exact_key].append((*candidate, True))
                    if front_key in candidates_by_key and front_key != exact_key:
                        candidates_by_key[front_key].append((*candidate, False))
                unresolved_for_accent: list[str] = []
                for key, candidates in candidates_by_key.items():
                    exact = [candidate[:-1] for candidate in candidates if candidate[-1]]
                    front = [
                        candidate[:-1] for candidate in candidates if not candidate[-1]
                    ]
                    (
                        status,
                        card_id,
                        kind,
                        count,
                        oracle_id,
                        canonical_card_id,
                        canonical_reason,
                    ) = _classify_candidate_groups(
                        exact=exact,
                        front=front,
                        accent=[],
                    )
                    if status == "resolved" and card_id:
                        resolved[key] = card_id
                        resolved_kind[key] = kind
                    elif status == "oracle_resolved" and oracle_id:
                        oracle_resolved[key] = oracle_id
                        oracle_resolved_kind[key] = kind
                        if canonical_card_id and canonical_reason:
                            oracle_canonical_card_id[key] = canonical_card_id
                            oracle_canonical_reason[key] = canonical_reason
                    elif status == "ambiguous":
                        ambiguous[key] = count
                        ambiguous_kind[key] = kind
                    else:
                        unresolved_for_accent.append(key)

                for key in unresolved_for_accent:
                    token = _longest_lookup_token(key)
                    if not token:
                        continue
                    cur.execute(
                        f"""
                        SELECT
                          id::text,
                          name,
                          {oracle_select_sql},
                          scryfall_id::text,
                          set_code,
                          collector_number,
                          image_url,
                          layout,
                          rarity
                        FROM cards
                        WHERE lower(name) LIKE %s
                           OR lower(split_part(name, ' // ', 1)) LIKE %s
                        LIMIT 250
                        """,
                        (f"%{token}%", f"%{token}%"),
                    )
                    key_accentless = accentless_name_key(key)
                    accent_candidates: list[tuple[Any, ...]] = []
                    for row in cur.fetchall():
                        (
                            card_id,
                            card_name,
                            oracle_id,
                            scryfall_id,
                            set_code,
                            collector_number,
                            image_url,
                            layout,
                            rarity,
                        ) = row
                        exact_key = accentless_name_key(card_name)
                        front_key = accentless_name_key(
                            str(card_name).split(" // ", 1)[0]
                        )
                        if key_accentless in (exact_key, front_key):
                            accent_candidates.append(
                                (
                                    card_id,
                                    card_name,
                                    oracle_id,
                                    scryfall_id,
                                    set_code,
                                    collector_number,
                                    image_url,
                                    layout,
                                    rarity,
                                )
                            )
                    (
                        status,
                        card_id,
                        kind,
                        count,
                        oracle_id,
                        canonical_card_id,
                        canonical_reason,
                    ) = _classify_candidate_groups(
                        exact=[],
                        front=[],
                        accent=accent_candidates,
                    )
                    if status == "resolved" and card_id:
                        resolved[key] = card_id
                        resolved_kind[key] = kind
                    elif status == "oracle_resolved" and oracle_id:
                        oracle_resolved[key] = oracle_id
                        oracle_resolved_kind[key] = kind
                        if canonical_card_id and canonical_reason:
                            oracle_canonical_card_id[key] = canonical_card_id
                            oracle_canonical_reason[key] = canonical_reason
                    elif status == "ambiguous":
                        ambiguous[key] = count
                        ambiguous_kind[key] = kind
    return (
        resolved,
        ambiguous,
        resolved_kind,
        ambiguous_kind,
        oracle_resolved,
        oracle_resolved_kind,
        oracle_canonical_card_id,
        oracle_canonical_reason,
        oracle_id_column_present,
    )


def audit(decks: list[dict[str, Any]]) -> dict[str, Any]:
    unique_names = {
        str(card.get("name") or "").strip()
        for deck in decks
        for card in deck["cards"]
        if str(card.get("name") or "").strip()
    }
    (
        resolved,
        ambiguous,
        resolved_kind,
        ambiguous_kind,
        oracle_resolved,
        oracle_resolved_kind,
        oracle_canonical_card_id,
        oracle_canonical_reason,
        oracle_id_column_present,
    ) = resolve_names(unique_names)
    unresolved_names: Counter[str] = Counter()
    ambiguous_names: Counter[str] = Counter()
    resolved_kind_instances: Counter[str] = Counter()
    ambiguous_kind_instances: Counter[str] = Counter()
    oracle_resolved_kind_instances: Counter[str] = Counter()
    canonical_printing_reason_instances: Counter[str] = Counter()
    totals = {
        "decks_seen": len(decks),
        "card_instances": 0,
        "resolved_instances": 0,
        "oracle_resolved_instances": 0,
        "unresolved_instances": 0,
        "ambiguous_instances": 0,
    }
    deck_summaries: list[dict[str, Any]] = []
    for deck in decks:
        deck_total = 0
        deck_resolved = 0
        deck_oracle_resolved = 0
        deck_unresolved = 0
        deck_ambiguous = 0
        for card in deck["cards"]:
            name = str(card.get("name") or "").strip()
            if not name:
                continue
            qty = quantity(card.get("quantity"))
            key = normalize_card_name(name)
            deck_total += qty
            if key in resolved:
                deck_resolved += qty
                resolved_kind_instances[resolved_kind.get(key, "unknown")] += qty
            elif key in oracle_resolved:
                deck_oracle_resolved += qty
                oracle_resolved_kind_instances[
                    oracle_resolved_kind.get(key, "unknown")
                ] += qty
                if key in oracle_canonical_card_id:
                    canonical_printing_reason_instances[
                        oracle_canonical_reason.get(key, "unknown")
                    ] += qty
            elif key in ambiguous:
                deck_ambiguous += qty
                ambiguous_kind_instances[ambiguous_kind.get(key, "unknown")] += qty
                ambiguous_names[name] += qty
            else:
                deck_unresolved += qty
                unresolved_names[name] += qty
        totals["card_instances"] += deck_total
        totals["resolved_instances"] += deck_resolved
        totals["oracle_resolved_instances"] += deck_oracle_resolved
        totals["unresolved_instances"] += deck_unresolved
        totals["ambiguous_instances"] += deck_ambiguous
        deck_summaries.append(
            {
                "learned_deck_id": deck["id"],
                "commander": deck["commander"],
                "source": deck["source"],
                "card_instances": deck_total,
                "resolved_instances": deck_resolved,
                "oracle_resolved_instances": deck_oracle_resolved,
                "unresolved_instances": deck_unresolved,
                "ambiguous_instances": deck_ambiguous,
            }
        )

    coverage = (
        totals["resolved_instances"] / totals["card_instances"]
        if totals["card_instances"]
        else 0.0
    )
    semantic_coverage = (
        (totals["resolved_instances"] + totals["oracle_resolved_instances"])
        / totals["card_instances"]
        if totals["card_instances"]
        else 0.0
    )
    return {
        "database_target": sanitized_database_target(),
        "decks_seen": totals["decks_seen"],
        "card_instances": totals["card_instances"],
        "resolved_instances": totals["resolved_instances"],
        "oracle_resolved_instances": totals["oracle_resolved_instances"],
        "unresolved_instances": totals["unresolved_instances"],
        "ambiguous_instances": totals["ambiguous_instances"],
        "resolved_kind_instances": dict(sorted(resolved_kind_instances.items())),
        "oracle_resolved_kind_instances": dict(
            sorted(oracle_resolved_kind_instances.items())
        ),
        "ambiguous_kind_instances": dict(sorted(ambiguous_kind_instances.items())),
        "resolution_coverage": round(coverage, 6),
        "semantic_identity_coverage": round(semantic_coverage, 6),
        "unique_names": len(unique_names),
        "resolved_unique_names": len(resolved),
        "oracle_resolved_unique_names": len(oracle_resolved),
        "canonical_printing_candidate_instances": sum(
            canonical_printing_reason_instances.values()
        ),
        "canonical_printing_candidate_unique_names": len(oracle_canonical_card_id),
        "canonical_printing_reason_instances": dict(
            sorted(canonical_printing_reason_instances.items())
        ),
        "ambiguous_unique_names": len(ambiguous),
        "resolver_schema_version": "learned_opponent_identity_audit_v4_report_only",
        "oracle_id_column_present": oracle_id_column_present,
        "candidate_identity_policy": (
            "Exact card_id is trusted only when one PG cards row matches. "
            "Multiple printings sharing one oracle_id count as semantic identity "
            "coverage but remain unsafe for card_id persistence until a canonical "
            "printing policy exists. If cards.oracle_id is absent, same-oracle "
            "resolution is unavailable and multiple printings remain ambiguous. "
            "Accent-normalized matches are diagnostic."
        ),
        "canonical_printing_policy": (
            "Report-only. A card_id candidate is emitted only when one printing "
            "has a unique highest evidence score from explicit fields such as "
            "printing scryfall_id, direct Scryfall image, layout, collector "
            "number, set code and rarity. Ties remain semantic-only."
        ),
        "persist_recommendation": (
            "do_not_apply_without_canonical_oracle_or_printing_policy"
        ),
        "unresolved_top": unresolved_names.most_common(20),
        "ambiguous_top": ambiguous_names.most_common(20),
        "decks": deck_summaries,
        "apply": False,
    }


def main() -> int:
    args = parse_args()
    decks = load_learned_rows(
        args.sqlite_db,
        candidate_limit=args.candidate_limit,
        deck_limit=args.deck_limit,
        min_cards=args.min_cards,
    )
    summary = audit(decks)
    payload = json.dumps(summary, ensure_ascii=True, indent=2, sort_keys=True) + "\n"
    if args.report:
        Path(args.report).parent.mkdir(parents=True, exist_ok=True)
        Path(args.report).write_text(payload, encoding="utf-8")
    print(
        "LEARNED_OPPONENT_CARD_IDENTITY_AUDIT "
        + json.dumps(summary, ensure_ascii=True, sort_keys=True)
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
