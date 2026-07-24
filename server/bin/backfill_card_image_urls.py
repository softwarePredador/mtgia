#!/usr/bin/env python3
"""Plan/apply a safe cards.image_url backfill from Scryfall default bulk data.

Dry-run is the default. Apply changes only image_url, preserves exact printing
identity or skips ambiguous legacy aliases, and requires the pinned PostgreSQL
wrapper plus both ManaLoom live/PostgreSQL approval tokens.
"""

from __future__ import annotations

import argparse
from collections.abc import Iterator
from dataclasses import dataclass
import json
import os
import ssl
import tempfile
import uuid
from pathlib import Path
from typing import Any
from urllib.parse import urlparse
from urllib.request import Request, urlopen

import psycopg2
import psycopg2.extras


BULK_METADATA_URL = "https://api.scryfall.com/bulk-data/default-cards"
APPROVAL_VALUE = "I_HAVE_EXPLICIT_APPROVAL"
LIVE_APPROVAL_ENV = "MANALOOM_CONFIRM_LIVE_MUTATIONS"
POSTGRES_APPROVAL_ENV = "MANALOOM_CONFIRM_POSTGRES_WRITES"
WRAPPER_MODE_ENV = "MANALOOM_PG_WRAPPER_MODE"
USER_AGENT = "ManaLoom/1.0 card-image-backfill"


@dataclass(frozen=True)
class CardImageIndex:
    by_printing: dict[str, str]
    by_oracle_set_collector: dict[tuple[str, str, str], frozenset[str]]
    by_oracle_set: dict[tuple[str, str], frozenset[str]]
    by_oracle: dict[str, frozenset[str]]


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Backfill direct card image URLs from Scryfall default bulk data."
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--apply", action="store_true")
    parser.add_argument("--bulk-json", type=Path)
    parser.add_argument("--limit", type=int)
    parser.add_argument("--batch-size", type=int, default=1000)
    args = parser.parse_args(argv)
    if args.limit is not None and args.limit <= 0:
        parser.error("--limit must be positive")
    if args.batch_size <= 0:
        parser.error("--batch-size must be positive")
    return args


def require_apply_approval(environment: dict[str, str]) -> None:
    missing = [
        name
        for name in (LIVE_APPROVAL_ENV, POSTGRES_APPROVAL_ENV)
        if environment.get(name) != APPROVAL_VALUE
    ]
    if missing:
        raise RuntimeError(
            "--apply blocked; set explicit approval for: " + ", ".join(missing)
        )
    if environment.get(WRAPPER_MODE_ENV) != "write-approved":
        raise RuntimeError(
            "--apply blocked; run through "
            "server/bin/with_new_server_pg.sh --write-approved"
        )


def normalized_uuid(value: Any) -> str | None:
    candidate = str(value or "").strip().lower()
    try:
        parsed = uuid.UUID(candidate)
    except (ValueError, AttributeError):
        return None
    normalized = str(parsed)
    return normalized if normalized == candidate else None


def direct_normal_image(card: dict[str, Any]) -> str | None:
    printing_id = normalized_uuid(card.get("id"))
    oracle_id = normalized_uuid(card.get("oracle_id"))
    if printing_id is None or oracle_id is None:
        return None

    candidates: list[Any] = []
    image_uris = card.get("image_uris")
    if isinstance(image_uris, dict):
        candidates.append(image_uris.get("normal"))
    faces = card.get("card_faces")
    if isinstance(faces, list):
        for face in faces:
            if isinstance(face, dict) and isinstance(face.get("image_uris"), dict):
                candidates.append(face["image_uris"].get("normal"))

    for raw in candidates:
        value = str(raw or "").strip()
        parsed = urlparse(value)
        if (
            parsed.scheme == "https"
            and parsed.hostname == "cards.scryfall.io"
            and parsed.path.startswith("/normal/")
            and parsed.path.lower().endswith(f"/{printing_id}.jpg")
        ):
            return value
    return None


def _normalized_text(value: Any) -> str | None:
    normalized = str(value or "").strip().lower()
    return normalized or None


def _freeze_candidates(
    candidates: dict[Any, set[str]],
) -> dict[Any, frozenset[str]]:
    return {key: frozenset(values) for key, values in candidates.items()}


def iter_bulk_cards(path: Path) -> Iterator[dict[str, Any]]:
    decoder = json.JSONDecoder()
    with path.open(encoding="utf-8") as source:
        buffer = ""
        offset = 0
        started = False
        reached_eof = False

        while True:
            if not reached_eof:
                chunk = source.read(1024 * 1024)
                reached_eof = not chunk
                buffer += chunk

            while True:
                while offset < len(buffer) and buffer[offset].isspace():
                    offset += 1
                if not started:
                    if offset >= len(buffer):
                        break
                    if buffer[offset] != "[":
                        raise RuntimeError(
                            "Scryfall default bulk JSON must be a top-level list."
                        )
                    started = True
                    offset += 1
                    continue

                while offset < len(buffer) and (
                    buffer[offset].isspace() or buffer[offset] == ","
                ):
                    offset += 1
                if offset >= len(buffer):
                    break
                if buffer[offset] == "]":
                    return

                try:
                    value, next_offset = decoder.raw_decode(buffer, offset)
                except json.JSONDecodeError:
                    if reached_eof:
                        raise RuntimeError(
                            "Scryfall default bulk JSON ended mid-object."
                        )
                    break
                offset = next_offset
                if isinstance(value, dict):
                    yield value

            if offset:
                buffer = buffer[offset:]
                offset = 0
            if reached_eof:
                raise RuntimeError(
                    "Scryfall default bulk JSON has no closing array."
                )


def load_card_image_index(path: Path) -> CardImageIndex:
    by_printing: dict[str, str] = {}
    by_oracle_set_collector: dict[tuple[str, str, str], set[str]] = {}
    by_oracle_set: dict[tuple[str, str], set[str]] = {}
    by_oracle: dict[str, set[str]] = {}
    for raw in iter_bulk_cards(path):
        printing_id = normalized_uuid(raw.get("id"))
        oracle_id = normalized_uuid(raw.get("oracle_id"))
        image_url = direct_normal_image(raw)
        if printing_id is None or image_url is None:
            continue
        by_printing[printing_id] = image_url
        if oracle_id is None:
            continue

        set_code = _normalized_text(raw.get("set"))
        collector_number = _normalized_text(raw.get("collector_number"))
        by_oracle.setdefault(oracle_id, set()).add(image_url)
        if set_code is not None:
            by_oracle_set.setdefault((oracle_id, set_code), set()).add(image_url)
            if collector_number is not None:
                by_oracle_set_collector.setdefault(
                    (oracle_id, set_code, collector_number),
                    set(),
                ).add(image_url)

    return CardImageIndex(
        by_printing=by_printing,
        by_oracle_set_collector=_freeze_candidates(
            by_oracle_set_collector
        ),
        by_oracle_set=_freeze_candidates(by_oracle_set),
        by_oracle=_freeze_candidates(by_oracle),
    )


def is_backfill_eligible(current_url: Any) -> bool:
    value = str(current_url or "").strip()
    if not value:
        return True
    repaired = value
    if repaired.startswith("ttps://"):
        repaired = "h" + repaired
    elif repaired.startswith("//"):
        repaired = "https:" + repaired
    elif repaired.startswith("api.scryfall.com/"):
        repaired = "https://" + repaired
    parsed = urlparse(repaired)
    return parsed.hostname == "api.scryfall.com"


def plan_updates(
    rows: list[tuple[Any, Any, Any, Any, Any, Any]],
    image_index: CardImageIndex,
    *,
    limit: int | None = None,
) -> tuple[list[tuple[str, Any, str]], dict[str, int]]:
    updates: list[tuple[str, Any, str]] = []
    stats = {
        "scanned": 0,
        "exact_printing": 0,
        "legacy_set_collector": 0,
        "legacy_set_unique": 0,
        "legacy_oracle_unique": 0,
        "legacy_ambiguous": 0,
        "missing_identity": 0,
        "missing_oracle_image": 0,
        "already_direct_or_external": 0,
    }
    for (
        card_id,
        scryfall_id_raw,
        oracle_id_raw,
        set_code_raw,
        collector_number_raw,
        current_url,
    ) in rows:
        stats["scanned"] += 1
        if not is_backfill_eligible(current_url):
            stats["already_direct_or_external"] += 1
            continue

        scryfall_id = normalized_uuid(scryfall_id_raw)
        oracle_id = normalized_uuid(oracle_id_raw)
        replacement: str | None = None
        resolution: str | None = None

        if (
            scryfall_id is not None
            and oracle_id is not None
            and scryfall_id != oracle_id
        ):
            replacement = image_index.by_printing.get(scryfall_id)
            resolution = "exact_printing"
        elif oracle_id is not None:
            set_code = _normalized_text(set_code_raw)
            collector_number = _normalized_text(collector_number_raw)
            candidate_groups: list[tuple[str, frozenset[str] | None]] = []
            if set_code is not None and collector_number is not None:
                candidate_groups.append(
                    (
                        "legacy_set_collector",
                        image_index.by_oracle_set_collector.get(
                            (oracle_id, set_code, collector_number)
                        ),
                    )
                )
            if set_code is not None:
                candidate_groups.append(
                    (
                        "legacy_set_unique",
                        image_index.by_oracle_set.get((oracle_id, set_code)),
                    )
                )
            candidate_groups.append(
                ("legacy_oracle_unique", image_index.by_oracle.get(oracle_id))
            )

            for candidate_resolution, candidates in candidate_groups:
                if not candidates:
                    continue
                if len(candidates) != 1:
                    resolution = "legacy_ambiguous"
                    break
                replacement = next(iter(candidates))
                resolution = candidate_resolution
                break
        else:
            resolution = "missing_identity"

        if replacement is None:
            if resolution == "legacy_ambiguous":
                stats["legacy_ambiguous"] += 1
            elif resolution == "missing_identity":
                stats["missing_identity"] += 1
            else:
                stats["missing_oracle_image"] += 1
            continue

        stats[resolution or "missing_oracle_image"] += 1
        updates.append((str(card_id), current_url, replacement))
        if limit is not None and len(updates) >= limit:
            break
    return updates, stats


def load_dotenv(path: Path) -> None:
    if not path.exists():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def connect():
    load_dotenv(Path(__file__).resolve().parents[1] / ".env")
    database_url = os.environ.get("DATABASE_URL")
    if database_url:
        return psycopg2.connect(database_url)
    required = ["DB_HOST", "DB_NAME", "DB_USER"]
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        raise RuntimeError("Missing DB config: " + ", ".join(missing))
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ.get("DB_PASS", ""),
    )


def trusted_ssl_context() -> ssl.SSLContext:
    try:
        import certifi
    except ImportError:
        return ssl.create_default_context()
    return ssl.create_default_context(cafile=certifi.where())


def configure_connection(conn, *, apply: bool) -> None:
    if not apply:
        conn.set_session(readonly=True, autocommit=False)


def download_default_bulk() -> Path:
    ssl_context = trusted_ssl_context()
    metadata_request = Request(
        BULK_METADATA_URL,
        headers={"Accept": "application/json", "User-Agent": USER_AGENT},
    )
    with urlopen(metadata_request, timeout=60, context=ssl_context) as response:
        metadata = json.load(response)
    download_uri = metadata.get("download_uri")
    if not isinstance(download_uri, str) or not download_uri.startswith("https://"):
        raise RuntimeError("Scryfall default bulk metadata has no safe download_uri.")

    target = tempfile.NamedTemporaryFile(
        prefix="manaloom_scryfall_default_",
        suffix=".json",
        delete=False,
    )
    target.close()
    bulk_request = Request(download_uri, headers={"User-Agent": USER_AGENT})
    with (
        urlopen(bulk_request, timeout=180, context=ssl_context) as response,
        open(target.name, "wb") as out,
    ):
        while chunk := response.read(1024 * 1024):
            out.write(chunk)
    return Path(target.name)


def fetch_card_rows(conn) -> list[tuple[Any, Any, Any, Any, Any, Any]]:
    with conn.cursor() as cursor:
        cursor.execute(
            "SELECT id::text, scryfall_id::text, oracle_id::text, "
            "set_code, collector_number, image_url "
            "FROM cards WHERE oracle_id IS NOT NULL ORDER BY id"
        )
        return list(cursor.fetchall())


def apply_updates(conn, updates: list[tuple[str, Any, str]], batch_size: int) -> int:
    applied = 0
    with conn.cursor() as cursor:
        for index in range(0, len(updates), batch_size):
            batch = updates[index : index + batch_size]
            psycopg2.extras.execute_values(
                cursor,
                """
                UPDATE cards AS c
                SET image_url = incoming.image_url
                FROM (VALUES %s) AS incoming(card_id, previous_url, image_url)
                WHERE c.id = incoming.card_id::uuid
                  AND c.image_url IS NOT DISTINCT FROM incoming.previous_url
                """,
                batch,
                template="(%s::text, %s::text, %s::text)",
                page_size=len(batch),
            )
            applied += max(cursor.rowcount, 0)
    return applied


def main(argv: list[str] | None = None) -> None:
    args = parse_args(argv)
    if args.apply:
        require_apply_approval(os.environ)

    downloaded_path: Path | None = None
    bulk_path = args.bulk_json
    if bulk_path is None:
        downloaded_path = download_default_bulk()
        bulk_path = downloaded_path

    conn = None
    try:
        image_index = load_card_image_index(bulk_path)
        conn = connect()
        configure_connection(conn, apply=args.apply)
        rows = fetch_card_rows(conn)
        updates, stats = plan_updates(rows, image_index, limit=args.limit)
        applied = 0
        if args.apply:
            applied = apply_updates(conn, updates, args.batch_size)
            conn.commit()
        else:
            conn.rollback()
        print(
            json.dumps(
                {
                    "mode": "apply" if args.apply else "dry-run",
                    "bulk_printing_images": len(image_index.by_printing),
                    **stats,
                    "candidates": len(updates),
                    "applied": applied,
                },
                sort_keys=True,
            )
        )
    except Exception:
        if conn is not None:
            conn.rollback()
        raise
    finally:
        if conn is not None:
            conn.close()
        if downloaded_path is not None:
            downloaded_path.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
