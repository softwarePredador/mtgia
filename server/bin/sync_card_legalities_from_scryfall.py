#!/usr/bin/env python3
"""Sync missing card legalities for existing cards via Scryfall Collection API.

This is intentionally narrow:
- reads existing PostgreSQL `cards` rows;
- fetches legalities by `oracle_id`;
- upserts only `card_legalities`;
- defaults to dry-run.

It does not create cards, alter decks, or promote Hermes findings.
"""

from __future__ import annotations

import argparse
import json
import os
import ssl
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

import psycopg2
import psycopg2.extras


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
DEFAULT_OUTPUT_DIR = REPO_ROOT / "server/test/artifacts/sync_card_legalities_from_scryfall_local"
SCRYFALL_COLLECTION_URL = "https://api.scryfall.com/cards/collection"
SCRYFALL_MAX_BATCH_SIZE = 75
DEFAULT_USER_AGENT = "ManaLoomLegalitiesSync/1.0"


@dataclass(frozen=True)
class Candidate:
    card_id: str
    oracle_id: str
    name: str
    set_code: str


@dataclass(frozen=True)
class CollectionPayload:
    legalities_by_oracle_id: dict[str, dict[str, str]]
    not_found: list[str]


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def load_env_file(path: Path) -> None:
    if not path.exists():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def db_connect(env_file: Path):
    load_env_file(env_file)
    database_url = os.environ.get("DATABASE_URL")
    if database_url:
        return psycopg2.connect(database_url)
    required = ["DB_HOST", "DB_NAME", "DB_USER", "DB_PASS"]
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        raise RuntimeError("Missing DB config: " + ", ".join(missing))
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASS"],
    )


def normalize_sets(raw_sets: str | Iterable[str]) -> list[str]:
    if isinstance(raw_sets, str):
        values = raw_sets.split(",")
    else:
        values = raw_sets
    return sorted({str(item).strip().lower() for item in values if str(item).strip()})


def chunked(values: list[Any], batch_size: int) -> list[list[Any]]:
    if batch_size < 1:
        batch_size = 1
    if batch_size > SCRYFALL_MAX_BATCH_SIZE:
        batch_size = SCRYFALL_MAX_BATCH_SIZE
    return [values[index : index + batch_size] for index in range(0, len(values), batch_size)]


def build_collection_body(oracle_ids: Iterable[str]) -> bytes:
    identifiers = [
        {"oracle_id": oracle_id.strip()}
        for oracle_id in oracle_ids
        if oracle_id and oracle_id.strip()
    ]
    return json.dumps({"identifiers": identifiers}, sort_keys=True).encode("utf-8")


def parse_collection_response(decoded: dict[str, Any], requested_oracle_ids: Iterable[str]) -> CollectionPayload:
    requested = {value for value in requested_oracle_ids if value}
    legalities_by_oracle_id: dict[str, dict[str, str]] = {}
    for item in decoded.get("data") or []:
        if not isinstance(item, dict):
            continue
        oracle_id = str(item.get("oracle_id") or "").strip()
        legalities = item.get("legalities")
        if not oracle_id or not isinstance(legalities, dict):
            continue
        legalities_by_oracle_id[oracle_id] = {
            str(fmt): str(status).lower()
            for fmt, status in legalities.items()
            if fmt and status is not None
        }
    explicit_not_found = {
        str(item.get("oracle_id") or item.get("id") or "").strip()
        for item in decoded.get("not_found") or []
        if isinstance(item, dict)
    }
    implicit_not_found = requested.difference(legalities_by_oracle_id)
    not_found = sorted({value for value in explicit_not_found.union(implicit_not_found) if value})
    return CollectionPayload(
        legalities_by_oracle_id=legalities_by_oracle_id,
        not_found=not_found,
    )


def ssl_context() -> ssl.SSLContext:
    try:
        import certifi  # type: ignore

        return ssl.create_default_context(cafile=certifi.where())
    except Exception:
        return ssl.create_default_context()


def fetch_collection(
    oracle_ids: list[str],
    *,
    timeout_seconds: int,
    max_retries: int,
    user_agent: str,
) -> CollectionPayload:
    body = build_collection_body(oracle_ids)
    last_error: Exception | None = None
    for attempt in range(1, max_retries + 1):
        request = urllib.request.Request(
            SCRYFALL_COLLECTION_URL,
            data=body,
            headers={
                "Accept": "application/json",
                "Content-Type": "application/json",
                "User-Agent": user_agent,
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(
                request,
                timeout=timeout_seconds,
                context=ssl_context(),
            ) as response:
                decoded = json.loads(response.read().decode("utf-8"))
                if not isinstance(decoded, dict):
                    raise RuntimeError("Scryfall collection response is not an object")
                return parse_collection_response(decoded, oracle_ids)
        except urllib.error.HTTPError as exc:
            last_error = exc
            retryable = exc.code == 429 or exc.code >= 500
            if not retryable or attempt == max_retries:
                raise
        except Exception as exc:
            last_error = exc
            if attempt == max_retries:
                raise
        time.sleep(min(2.0 * attempt, 10.0))
    raise RuntimeError(f"Scryfall collection failed: {last_error}")


def load_candidates(
    conn,
    *,
    sets: list[str],
    limit: int | None,
    missing_commander_only: bool,
) -> list[Candidate]:
    where = ["COALESCE(c.oracle_id, c.scryfall_id) IS NOT NULL"]
    params: list[Any] = []
    if sets:
        where.append("LOWER(c.set_code) = ANY(%s)")
        params.append(sets)
    if missing_commander_only:
        where.append("cl.card_id IS NULL")
    limit_sql = ""
    if limit is not None:
        limit_sql = "LIMIT %s"
        params.append(limit)
    query = f"""
        SELECT
          c.id::text AS card_id,
          COALESCE(c.oracle_id, c.scryfall_id)::text AS oracle_id,
          c.name,
          COALESCE(c.set_code, '') AS set_code
        FROM cards c
        LEFT JOIN card_legalities cl
          ON cl.card_id = c.id AND cl.format = 'commander'
        WHERE {' AND '.join(where)}
        ORDER BY LOWER(c.set_code), c.name, c.id
        {limit_sql}
    """
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute(query, params)
        rows = cur.fetchall()
    return [
        Candidate(
            card_id=str(row["card_id"]),
            oracle_id=str(row["oracle_id"]),
            name=str(row["name"]),
            set_code=str(row["set_code"] or ""),
        )
        for row in rows
    ]


def rows_for_upsert(
    candidates: list[Candidate],
    legalities_by_oracle_id: dict[str, dict[str, str]],
) -> list[tuple[str, str, str]]:
    rows: list[tuple[str, str, str]] = []
    for candidate in candidates:
        legalities = legalities_by_oracle_id.get(candidate.oracle_id)
        if not legalities:
            continue
        for fmt, status in legalities.items():
            rows.append((candidate.card_id, fmt, status))
    # Dedupe by card/format while keeping last deterministic sorted status.
    deduped = {
        (card_id, fmt): (card_id, fmt, status)
        for card_id, fmt, status in rows
        if card_id and fmt and status
    }
    return sorted(deduped.values(), key=lambda row: (row[0], row[1]))


def upsert_legalities(conn, rows: list[tuple[str, str, str]], *, apply: bool) -> int:
    if not rows or not apply:
        return 0
    with conn.cursor() as cur:
        psycopg2.extras.execute_values(
            cur,
            """
            INSERT INTO card_legalities (card_id, format, status)
            VALUES %s
            ON CONFLICT (card_id, format) DO UPDATE SET
              status = EXCLUDED.status
            """,
            rows,
            template="(%s::uuid, %s::text, %s::text)",
            page_size=1000,
        )
    conn.commit()
    return len(rows)


def write_artifacts(output_dir: Path, summary: dict[str, Any]) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    run_id = summary["run_id"]
    run_dir = output_dir / run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    text = json.dumps(summary, indent=2, sort_keys=True) + "\n"
    (run_dir / "summary.json").write_text(text, encoding="utf-8")
    (output_dir / "latest_summary.json").write_text(text, encoding="utf-8")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sync missing legalities for existing cards using Scryfall oracle_id collection lookup."
    )
    parser.add_argument("--sets", default=os.environ.get("MANALOOM_SYNC_LEGALITIES_SETS", "msh,msc,mar"))
    parser.add_argument("--limit", type=int)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--include-existing", action="store_true")
    parser.add_argument("--batch-size", type=int, default=SCRYFALL_MAX_BATCH_SIZE)
    parser.add_argument("--delay-ms", type=int, default=100)
    parser.add_argument("--timeout-seconds", type=int, default=30)
    parser.add_argument("--max-retries", type=int, default=3)
    parser.add_argument("--output-dir", default=os.environ.get("MANALOOM_SYNC_LEGALITIES_OUTPUT_DIR"))
    parser.add_argument("--env-file", default=os.environ.get("MTGIA_ENV_FILE", str(REPO_ROOT / "server/.env")))
    return parser.parse_args(argv)


def run(args: argparse.Namespace) -> dict[str, Any]:
    sets = normalize_sets(args.sets)
    output_dir = Path(args.output_dir or DEFAULT_OUTPUT_DIR)
    if output_dir.name != "sync_card_legalities_from_scryfall":
        output_dir = output_dir / "sync_card_legalities_from_scryfall"
    generated_at = utc_now().isoformat(timespec="seconds")
    run_id = "sync_card_legalities_from_scryfall_" + utc_now().strftime("%Y%m%d_%H%M%S")

    conn = db_connect(Path(args.env_file))
    try:
        candidates = load_candidates(
            conn,
            sets=sets,
            limit=args.limit,
            missing_commander_only=not args.include_existing,
        )
        legalities_by_oracle_id: dict[str, dict[str, str]] = {}
        not_found: set[str] = set()
        unique_oracle_ids = sorted({candidate.oracle_id for candidate in candidates})
        batches = chunked(unique_oracle_ids, args.batch_size)
        for index, batch in enumerate(batches):
            payload = fetch_collection(
                batch,
                timeout_seconds=args.timeout_seconds,
                max_retries=args.max_retries,
                user_agent=DEFAULT_USER_AGENT,
            )
            legalities_by_oracle_id.update(payload.legalities_by_oracle_id)
            not_found.update(payload.not_found)
            if args.delay_ms > 0 and index < len(batches) - 1:
                time.sleep(args.delay_ms / 1000.0)
        rows = rows_for_upsert(candidates, legalities_by_oracle_id)
        upserted = upsert_legalities(conn, rows, apply=args.apply)
    finally:
        conn.close()

    commander_statuses: dict[str, int] = {}
    for candidate in candidates:
        status = legalities_by_oracle_id.get(candidate.oracle_id, {}).get("commander")
        if status:
            commander_statuses[status] = commander_statuses.get(status, 0) + 1

    summary = {
        "run_id": run_id,
        "generated_at": generated_at,
        "apply": bool(args.apply),
        "sets": sets,
        "candidate_cards": len(candidates),
        "oracle_ids_requested": len(unique_oracle_ids),
        "oracle_ids_found": len(legalities_by_oracle_id),
        "oracle_ids_not_found": len(not_found),
        "legality_rows_ready": len(rows),
        "legality_rows_upserted": upserted,
        "commander_statuses": commander_statuses,
        "not_found_sample": sorted(not_found)[:20],
        "notes": [
            "upserts_card_legalities_only",
            "does_not_mutate_cards_or_decks",
            "postgres_backend_remains_source_of_truth",
            "uses_scryfall_collection_by_oracle_id",
        ],
    }
    write_artifacts(output_dir, summary)
    print("MANALOOM_SYNC_CARD_LEGALITIES " + json.dumps(summary, sort_keys=True))
    return summary


def main(argv: list[str] | None = None) -> int:
    try:
        run(parse_args(argv))
    except Exception as exc:
        print(f"MANALOOM_SYNC_CARD_LEGALITIES_FAILED {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
