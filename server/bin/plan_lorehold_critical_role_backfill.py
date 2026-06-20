#!/usr/bin/env python3
"""Plan or apply focused Lorehold critical role/semantic/synergy rows."""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import psycopg2
from psycopg2.extras import RealDictCursor


REPO_ROOT = Path(__file__).resolve().parents[2]
SERVER_ROOT = REPO_ROOT / "server"
SOURCE = "lorehold_critical_gap_manual_2026_06_20"
COMMANDER_NAME = "Lorehold, the Historian"
COMMANDER_NORMALIZED = "lorehold, the historian"


@dataclass(frozen=True)
class CriticalCardPlan:
    name: str
    function_tags: tuple[str, ...]
    semantic_tags: tuple[dict[str, Any], ...]
    synergy_role: str
    synergy_score: int
    explanation_reason: str
    speed: str = "setup"
    mana_efficiency: str = "unknown"
    card_advantage_type: str = "none"
    interaction_scope: str = "none"
    combo_piece: bool = False
    wincon: bool = False
    engine: bool = False
    payoff: bool = False
    enabler: bool = True
    protection_type: str = "none"
    recursion_type: str = "none"
    role_confidence: float = 0.86


CRITICAL_CARDS = (
    CriticalCardPlan(
        name="Orim's Chant",
        function_tags=("protection", "stax"),
        semantic_tags=(
            {"tag": "protection", "evidence": "prevents_opponent_spells", "confidence": 0.9},
            {"tag": "stax", "evidence": "silence_effect", "confidence": 0.84},
        ),
        synergy_role="protection",
        synergy_score=92,
        speed="instant",
        mana_efficiency="efficient",
        interaction_scope="stack",
        protection_type="silence",
        explanation_reason="Lorehold critical protection piece: protects setup and combo turns by preventing opponent spells.",
        role_confidence=0.9,
    ),
    CriticalCardPlan(
        name="Ruby Medallion",
        function_tags=("ramp", "spellslinger", "artifact_synergy"),
        semantic_tags=(
            {"tag": "ramp", "evidence": "red_spell_cost_reduction", "confidence": 0.88},
            {"tag": "spellslinger", "evidence": "instant_sorcery_cost_reduction", "confidence": 0.82},
        ),
        synergy_role="ramp",
        synergy_score=88,
        mana_efficiency="efficient",
        explanation_reason="Lorehold critical mana acceleration: reduces red spell costs for explosive big-spell turns.",
        role_confidence=0.88,
    ),
    CriticalCardPlan(
        name="Scroll Rack",
        function_tags=("draw", "engine", "enabler", "artifact_synergy"),
        semantic_tags=(
            {"tag": "draw", "evidence": "hand_topdeck_exchange", "confidence": 0.84},
            {"tag": "engine", "evidence": "repeatable_topdeck_setup", "confidence": 0.86},
            {"tag": "enabler", "evidence": "miracle_setup", "confidence": 0.9},
        ),
        synergy_role="draw",
        synergy_score=90,
        card_advantage_type="selection",
        engine=True,
        explanation_reason="Lorehold critical topdeck engine: sets up miracle and hand-to-library sequencing.",
        role_confidence=0.9,
    ),
    CriticalCardPlan(
        name="Victory Chimes",
        function_tags=("ramp", "artifact_synergy"),
        semantic_tags=(
            {"tag": "ramp", "evidence": "mana_on_each_player_turn", "confidence": 0.86},
            {"tag": "artifact_synergy", "evidence": "mana_artifact", "confidence": 0.74},
        ),
        synergy_role="ramp",
        synergy_score=84,
        mana_efficiency="efficient",
        explanation_reason="Lorehold critical mana support: provides recurring mana across the table cycle.",
        role_confidence=0.86,
    ),
    CriticalCardPlan(
        name="Lorehold, the Historian",
        function_tags=(),
        semantic_tags=(),
        synergy_role="engine",
        synergy_score=96,
        explanation_reason="Commander synergy row: Lorehold is the deck engine and commander identity anchor.",
        engine=True,
        enabler=True,
        role_confidence=0.95,
    ),
)


def load_env_file(path: Path) -> None:
    if not path.exists():
        return
    for line in path.read_text().splitlines():
        text = line.strip()
        if not text or text.startswith("#") or "=" not in text:
            continue
        key, value = text.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def connect_pg() -> psycopg2.extensions.connection:
    load_env_file(SERVER_ROOT / ".env")
    required = ("DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASS")
    missing = [key for key in required if not os.environ.get(key)]
    if missing:
        raise SystemExit(f"Missing DB env vars: {', '.join(missing)}")
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ["DB_PORT"],
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASS"],
    )


def resolve_cards(conn: psycopg2.extensions.connection) -> list[dict[str, Any]]:
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            WITH wanted(input_name, normalized_lookup_name) AS (
              SELECT *
              FROM jsonb_to_recordset(%s::jsonb) AS x(
                input_name text,
                normalized_lookup_name text
              )
            ), resolved AS (
              SELECT
                w.input_name,
                cib.card_id,
                cib.canonical_name,
                cib.oracle_id,
                cib.type_line,
                cib.oracle_text,
                row_number() OVER (
                  PARTITION BY w.input_name
                  ORDER BY
                    CASE
                      WHEN cib.normalized_lookup_name = w.normalized_lookup_name THEN 0
                      WHEN cib.normalized_canonical_name = w.normalized_lookup_name THEN 1
                      ELSE 2
                    END,
                    coalesce(cib.match_priority, 999),
                    cib.card_id
                ) AS rn
              FROM wanted w
              LEFT JOIN card_identity_bridge cib
                ON cib.normalized_lookup_name = w.normalized_lookup_name
                OR cib.normalized_canonical_name = w.normalized_lookup_name
            )
            SELECT
              input_name,
              card_id::text,
              canonical_name,
              oracle_id::text,
              type_line,
              (oracle_text IS NOT NULL AND length(trim(oracle_text)) > 0)
                AS oracle_text_present
            FROM resolved
            WHERE rn = 1
            ORDER BY input_name
            """,
            [
                json.dumps(
                    [
                        {
                            "input_name": card.name,
                            "normalized_lookup_name": card.name.strip().lower(),
                        }
                        for card in CRITICAL_CARDS
                    ]
                )
            ],
        )
        rows = [dict(row) for row in cur.fetchall()]
    missing = [row["input_name"] for row in rows if not row.get("card_id")]
    if missing:
        raise SystemExit(f"Unresolved critical cards: {', '.join(missing)}")
    return rows


def build_plan(resolved_cards: list[dict[str, Any]]) -> dict[str, Any]:
    by_name = {row["input_name"]: row for row in resolved_cards}
    function_rows: list[dict[str, Any]] = []
    semantic_rows: list[dict[str, Any]] = []
    synergy_rows: list[dict[str, Any]] = []

    for card in CRITICAL_CARDS:
        resolved = by_name[card.name]
        for tag in card.function_tags:
            function_rows.append(
                {
                    "card_id": resolved["card_id"],
                    "card_name": resolved["canonical_name"],
                    "tag": tag,
                    "confidence": card.role_confidence,
                    "source": SOURCE,
                    "evidence": card.explanation_reason,
                }
            )
        if card.semantic_tags:
            semantic_rows.append(
                {
                    "card_id": resolved["card_id"],
                    "card_name": resolved["canonical_name"],
                    "schema_version": "lorehold_critical_gap_v1",
                    "speed": card.speed,
                    "mana_efficiency": card.mana_efficiency,
                    "card_advantage_type": card.card_advantage_type,
                    "interaction_scope": card.interaction_scope,
                    "combo_piece": card.combo_piece,
                    "wincon": card.wincon,
                    "engine": card.engine,
                    "payoff": card.payoff,
                    "enabler": card.enabler,
                    "protection_type": card.protection_type,
                    "recursion_type": card.recursion_type,
                    "role_confidence": card.role_confidence,
                    "explanation_reason": card.explanation_reason,
                    "tags": list(card.semantic_tags),
                    "source": SOURCE,
                }
            )
        synergy_rows.append(
            {
                "commander_name_normalized": COMMANDER_NORMALIZED,
                "commander_name": COMMANDER_NAME,
                "card_id": resolved["card_id"],
                "card_name": resolved["canonical_name"],
                "role": card.synergy_role,
                "score": card.synergy_score,
                "source": SOURCE,
                "evidence_count": 1,
                "evidence": card.explanation_reason,
            }
        )

    return {
        "function_tag_rows": function_rows,
        "semantic_v2_rows": semantic_rows,
        "commander_synergy_rows": synergy_rows,
    }


def current_counts(
    conn: psycopg2.extensions.connection,
    card_ids: list[str],
) -> dict[str, Any]:
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            WITH wanted(card_id) AS (
              SELECT unnest(%s::uuid[])
            )
            SELECT
              (SELECT count(*)::int FROM card_function_tags cft
               JOIN wanted w ON w.card_id = cft.card_id
               WHERE cft.source = %s) AS existing_function_tag_rows,
              (SELECT count(*)::int FROM card_semantic_tags_v2 cstv2
               JOIN wanted w ON w.card_id = cstv2.card_id
               WHERE cstv2.source = %s) AS existing_semantic_v2_rows,
              (SELECT count(*)::int FROM commander_card_synergy ccs
               JOIN wanted w ON w.card_id = ccs.card_id
               WHERE ccs.source = %s
                 AND ccs.commander_name_normalized = %s)
                 AS existing_commander_synergy_rows
            """,
            (card_ids, SOURCE, SOURCE, SOURCE, COMMANDER_NORMALIZED),
        )
        return dict(cur.fetchone())


def rollback_sql(card_ids: list[str]) -> str:
    ids = ", ".join(f"'{card_id}'::uuid" for card_id in card_ids)
    return "\n".join(
        [
            "BEGIN;",
            f"DELETE FROM card_function_tags WHERE source = '{SOURCE}' AND card_id IN ({ids});",
            f"DELETE FROM card_semantic_tags_v2 WHERE source = '{SOURCE}' AND card_id IN ({ids});",
            "DELETE FROM commander_card_synergy "
            f"WHERE source = '{SOURCE}' "
            f"AND commander_name_normalized = '{COMMANDER_NORMALIZED}' "
            f"AND card_id IN ({ids});",
            "COMMIT;",
        ]
    )


def apply_plan(
    conn: psycopg2.extensions.connection,
    plan: dict[str, list[dict[str, Any]]],
) -> dict[str, int]:
    with conn.cursor() as cur:
        cur.execute("BEGIN")
        cur.execute(
            """
            WITH input AS (
              SELECT *
              FROM jsonb_to_recordset(%s::jsonb) AS x(
                card_id text,
                card_name text,
                tag text,
                confidence numeric,
                source text,
                evidence text
              )
            )
            INSERT INTO card_function_tags (
              card_id, card_name, tag, confidence, source, evidence, updated_at
            )
            SELECT
              card_id::uuid, card_name, tag, confidence, source, evidence,
              CURRENT_TIMESTAMP
            FROM input
            ON CONFLICT (card_id, tag, source) DO UPDATE SET
              card_name = EXCLUDED.card_name,
              confidence = EXCLUDED.confidence,
              evidence = EXCLUDED.evidence,
              updated_at = CURRENT_TIMESTAMP
            """,
            [json.dumps(plan["function_tag_rows"])],
        )
        function_count = cur.rowcount

        cur.execute(
            """
            WITH input AS (
              SELECT *
              FROM jsonb_to_recordset(%s::jsonb) AS x(
                card_id text,
                card_name text,
                schema_version text,
                speed text,
                mana_efficiency text,
                card_advantage_type text,
                interaction_scope text,
                combo_piece boolean,
                wincon boolean,
                engine boolean,
                payoff boolean,
                enabler boolean,
                protection_type text,
                recursion_type text,
                role_confidence numeric,
                explanation_reason text,
                tags jsonb,
                source text
              )
            )
            INSERT INTO card_semantic_tags_v2 (
              card_id, card_name, schema_version, speed, mana_efficiency,
              card_advantage_type, interaction_scope, combo_piece, wincon,
              engine, payoff, enabler, protection_type, recursion_type,
              role_confidence, explanation_reason, tags, source, updated_at
            )
            SELECT
              card_id::uuid, card_name, schema_version, speed, mana_efficiency,
              card_advantage_type, interaction_scope, combo_piece, wincon,
              engine, payoff, enabler, protection_type, recursion_type,
              role_confidence, explanation_reason, tags, source,
              CURRENT_TIMESTAMP
            FROM input
            ON CONFLICT (card_id, source) DO UPDATE SET
              card_name = EXCLUDED.card_name,
              schema_version = EXCLUDED.schema_version,
              speed = EXCLUDED.speed,
              mana_efficiency = EXCLUDED.mana_efficiency,
              card_advantage_type = EXCLUDED.card_advantage_type,
              interaction_scope = EXCLUDED.interaction_scope,
              combo_piece = EXCLUDED.combo_piece,
              wincon = EXCLUDED.wincon,
              engine = EXCLUDED.engine,
              payoff = EXCLUDED.payoff,
              enabler = EXCLUDED.enabler,
              protection_type = EXCLUDED.protection_type,
              recursion_type = EXCLUDED.recursion_type,
              role_confidence = EXCLUDED.role_confidence,
              explanation_reason = EXCLUDED.explanation_reason,
              tags = EXCLUDED.tags,
              updated_at = CURRENT_TIMESTAMP
            """,
            [json.dumps(plan["semantic_v2_rows"])],
        )
        semantic_count = cur.rowcount

        cur.execute(
            """
            WITH input AS (
              SELECT *
              FROM jsonb_to_recordset(%s::jsonb) AS x(
                commander_name_normalized text,
                commander_name text,
                card_id text,
                card_name text,
                role text,
                score int,
                source text,
                evidence_count int,
                evidence text
              )
            )
            INSERT INTO commander_card_synergy (
              commander_name_normalized, commander_name, card_id, card_name,
              role, score, source, evidence_count, evidence, updated_at
            )
            SELECT
              commander_name_normalized, commander_name, card_id::uuid,
              card_name, role, score, source, evidence_count, evidence,
              CURRENT_TIMESTAMP
            FROM input
            ON CONFLICT (commander_name_normalized, card_id, role, source)
            DO UPDATE SET
              commander_name = EXCLUDED.commander_name,
              card_name = EXCLUDED.card_name,
              score = EXCLUDED.score,
              evidence_count = EXCLUDED.evidence_count,
              evidence = EXCLUDED.evidence,
              updated_at = CURRENT_TIMESTAMP
            """,
            [json.dumps(plan["commander_synergy_rows"])],
        )
        synergy_count = cur.rowcount
        conn.commit()
    return {
        "function_tag_rows": function_count,
        "semantic_v2_rows": semantic_count,
        "commander_synergy_rows": synergy_count,
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Plan focused Lorehold critical role/semantic/synergy rows."
    )
    parser.add_argument("--dry-run", action="store_true", help="Do not mutate DB.")
    parser.add_argument("--apply", action="store_true", help="Persist planned rows.")
    args = parser.parse_args()
    if args.apply and args.dry_run:
        raise SystemExit("Use only one mode: --dry-run or --apply.")

    apply = args.apply
    conn = connect_pg()
    try:
        resolved_cards = resolve_cards(conn)
        plan = build_plan(resolved_cards)
        card_ids = [row["card_id"] for row in resolved_cards]
        counts_before = current_counts(conn, card_ids)
        applied_counts = (
            apply_plan(conn, plan)
            if apply
            else {
                "function_tag_rows": 0,
                "semantic_v2_rows": 0,
                "commander_synergy_rows": 0,
            }
        )
        counts_after = current_counts(conn, card_ids)
        payload = {
            "status": "PASS",
            "mode": "apply" if apply else "dry_run",
            "db_mutations": apply,
            "source": SOURCE,
            "commander_name": COMMANDER_NAME,
            "resolved_cards": resolved_cards,
            "counts_before": counts_before,
            "planned_counts": {
                key: len(value) for key, value in plan.items()
            },
            "applied_counts": applied_counts,
            "counts_after": counts_after,
            "planned_rows": plan,
            "apply_command": (
                "cd server && python3 bin/plan_lorehold_critical_role_backfill.py --apply"
            ),
            "rollback_sql": rollback_sql(card_ids),
        }
        print(json.dumps(payload, indent=2, sort_keys=True))
    finally:
        conn.close()


if __name__ == "__main__":
    main()
