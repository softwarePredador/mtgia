#!/usr/bin/env python3
"""BT-CAT-01: refresh do catálogo de referência sob o contrato catalog_reference_apply_v1.

Aqui não há rede nem banco: o HTTP passa por um opener roteirizado e o banco por
um falso que registra cada instrução. A prova em PostgreSQL (duas execuções,
delta zero, tabelas de usuário intactas) está em
sync_catalog_reference_db_live_test.py.
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import importlib.util
import io
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from datetime import date, datetime, timezone
from decimal import Decimal
from email.message import Message
from pathlib import Path
from urllib.error import HTTPError, URLError


def _load_module():
    root = Path(__file__).resolve().parents[1]
    path = root / "bin" / "sync_catalog_reference_from_scryfall.py"
    spec = importlib.util.spec_from_file_location(
        "sync_catalog_reference_from_scryfall", path
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


job = _load_module()
FIXTURES = Path(__file__).resolve().parent / "fixtures"
FIXTURE = FIXTURES / "scryfall_default_cards_sample.json"
# Os mesmos 9 objetos da lista acima, no formato atual da Scryfall: JSON Lines
# com gzip, um card por linha.
FIXTURE_JSONL_GZ = FIXTURES / "scryfall_default_cards_sample.jsonl.gz"
# Metadados no formato de 2026-09-23 (jsonl_download_uri e compressed_size, sem
# download_uri, size, content_type e content_encoding). object, id, type,
# updated_at, jsonl_download_uri e compressed_size são os valores relatados pela
# coordenação; uri, name e description são ilustrativos.
METADATA_2026_09_23 = json.loads(
    (FIXTURES / "scryfall_bulk_metadata_default_cards_2026-09-23.json").read_text(
        encoding="utf-8"
    )
)
SOURCE_UPDATED_AT = "2026-09-22T09:00:00+00:00"

O_SOL = "5c8e7c9e-1111-4a1a-8a1a-000000000001"
O_BOLT = "5c8e7c9e-1111-4a1a-8a1a-000000000002"
O_DRAKE = "5c8e7c9e-1111-4a1a-8a1a-000000000003"
O_ADEPT = "5c8e7c9e-1111-4a1a-8a1a-000000000004"
O_GLEEMAX = "5c8e7c9e-1111-4a1a-8a1a-000000000006"
P_SOL_CMM = "5c8e7c9e-2222-4b2b-9b2b-000000000001"
P_SOL_BRT = "5c8e7c9e-2222-4b2b-9b2b-000000000002"
P_BOLT = "5c8e7c9e-2222-4b2b-9b2b-000000000003"
P_DRAKE = "5c8e7c9e-2222-4b2b-9b2b-000000000004"
P_ADEPT = "5c8e7c9e-2222-4b2b-9b2b-000000000006"
P_GLEEMAX = "5c8e7c9e-2222-4b2b-9b2b-000000000008"

# Formato antigo (lista JSON): continua aceito quando só ele vier.
METADATA = {
    "object": "bulk_data",
    "id": "e2ef41e3-5778-4bc2-af3f-78eca4dd9c23",
    "type": "default_cards",
    "updated_at": "2026-09-22T09:04:31.371+00:00",
    "download_uri": "https://data.scryfall.io/default-cards/default-cards-20260922090431.json",
    "size": 512 * 1024 * 1024,
    "content_type": "application/json",
    "content_encoding": "gzip",
}

USER_TABLES = (
    "users",
    "decks",
    "deck_cards",
    "user_binder_items",
    "trade_items",
    "post_game_notes",
    "conversations",
)


class FakeResponse:
    def __init__(self, body: bytes, *, status: int = 200, headers: dict | None = None):
        self._stream = io.BytesIO(body)
        self.status = status
        self.headers = headers or {}
        self.closed = False

    def read(self, size: int = -1) -> bytes:
        return self._stream.read(size)

    def getcode(self) -> int:
        return self.status

    def close(self) -> None:
        self.closed = True

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()
        return False


def http_error(code: int, *, retry_after: str | None = None) -> HTTPError:
    headers = Message()
    if retry_after is not None:
        headers["Retry-After"] = retry_after
    return HTTPError("https://api.scryfall.com/x", code, f"status {code}", headers, None)


class ScriptedOpener:
    def __init__(self, steps):
        self.steps = list(steps)
        self.requests = []

    def __call__(self, request, timeout):
        self.requests.append(request)
        if not self.steps:
            raise AssertionError(f"requisição inesperada: {request.full_url}")
        step = self.steps.pop(0)
        if isinstance(step, BaseException):
            raise step
        return step


def make_ctx(opener=None, **budget):
    sleeps: list[float] = []
    ctx = job.RunContext(
        budget=job.Budget(**budget),
        opener=opener or ScriptedOpener([]),
        sleep=sleeps.append,
        clock=lambda: 0.0,
        now=lambda: datetime(2026, 9, 23, 10, 0, tzinfo=timezone.utc),
    )
    ctx.start()
    return ctx, sleeps


def metadata_response(payload=None) -> FakeResponse:
    return FakeResponse(json.dumps(payload or METADATA).encode("utf-8"))


class HttpMatrixTest(unittest.TestCase):
    def test_200_reads_the_bulk_metadata_with_brewtact_headers(self) -> None:
        opener = ScriptedOpener([metadata_response()])
        ctx, sleeps = make_ctx(opener)

        source = job.fetch_bulk_metadata(ctx)

        self.assertEqual(source.download_uri, METADATA["download_uri"])
        self.assertEqual(source.updated_at, "2026-09-22T09:04:31.371000+00:00")
        self.assertEqual(ctx.upstream_requests, 1)
        self.assertEqual(sleeps, [])
        request = opener.requests[0]
        self.assertEqual(request.full_url, job.BULK_METADATA_URL)
        self.assertTrue(request.get_header("User-agent").startswith("BrewTact/1.0"))
        self.assertEqual(request.get_header("Accept"), "application/json")

    def test_404_fails_at_once_without_retry(self) -> None:
        opener = ScriptedOpener([http_error(404)])
        ctx, sleeps = make_ctx(opener)

        with self.assertRaises(job.UpstreamError) as raised:
            job.fetch_bulk_metadata(ctx)

        self.assertEqual(raised.exception.kind, "upstream_not_found")
        self.assertEqual(raised.exception.status, 404)
        self.assertEqual(len(opener.requests), 1)
        self.assertEqual(sleeps, [])

    def test_429_waits_for_retry_after_and_retries(self) -> None:
        opener = ScriptedOpener([http_error(429, retry_after="7"), metadata_response()])
        ctx, sleeps = make_ctx(opener)

        job.fetch_bulk_metadata(ctx)

        self.assertEqual(len(opener.requests), 2)
        self.assertEqual(sleeps, [7.0])

    def test_retry_after_is_capped(self) -> None:
        opener = ScriptedOpener([http_error(429, retry_after="3600"), metadata_response()])
        ctx, sleeps = make_ctx(opener)

        job.fetch_bulk_metadata(ctx)

        self.assertEqual(sleeps, [60.0])

    def test_5xx_retries_with_backoff_until_exhausted(self) -> None:
        opener = ScriptedOpener([http_error(503), http_error(502), http_error(500)])
        ctx, sleeps = make_ctx(opener)

        with self.assertRaises(job.UpstreamError) as raised:
            job.fetch_bulk_metadata(ctx)

        self.assertEqual(raised.exception.kind, "upstream_retries_exhausted")
        self.assertEqual(raised.exception.status, 500)
        self.assertEqual(len(opener.requests), 3)
        self.assertEqual(sleeps, [2.0, 4.0])

    def test_timeout_retries_and_then_succeeds(self) -> None:
        opener = ScriptedOpener([TimeoutError("timed out"), metadata_response()])
        ctx, sleeps = make_ctx(opener)

        job.fetch_bulk_metadata(ctx)

        self.assertEqual(len(opener.requests), 2)
        self.assertEqual(sleeps, [2.0])

    def test_connection_errors_exhaust_the_attempts(self) -> None:
        opener = ScriptedOpener([URLError(ConnectionRefusedError("recusada"))] * 3)
        ctx, _ = make_ctx(opener)

        with self.assertRaises(job.UpstreamError) as raised:
            job.fetch_bulk_metadata(ctx)

        self.assertEqual(raised.exception.kind, "upstream_retries_exhausted")
        self.assertEqual(len(opener.requests), 3)

    def test_other_4xx_is_not_retried(self) -> None:
        opener = ScriptedOpener([http_error(403)])
        ctx, _ = make_ctx(opener)

        with self.assertRaises(job.UpstreamError) as raised:
            job.fetch_bulk_metadata(ctx)

        self.assertEqual(raised.exception.kind, "upstream_http_status")
        self.assertEqual(len(opener.requests), 1)

    def test_request_budget_caps_the_total_number_of_calls(self) -> None:
        opener = ScriptedOpener([http_error(503), http_error(503), http_error(503)])
        ctx, _ = make_ctx(opener, max_upstream_requests=2)

        with self.assertRaises(job.BudgetExceeded) as raised:
            job.fetch_bulk_metadata(ctx)

        self.assertEqual(raised.exception.kind, "budget_exceeded:upstream_requests")
        self.assertEqual(len(opener.requests), 2)

    def test_download_host_outside_scryfall_bulk_is_refused(self) -> None:
        payload = {**METADATA, "download_uri": "https://evil.example/default-cards.json"}
        ctx, _ = make_ctx(ScriptedOpener([metadata_response(payload)]))

        with self.assertRaises(job.RefreshError) as raised:
            job.fetch_bulk_metadata(ctx)

        self.assertEqual(raised.exception.kind, "unexpected_download_host")

    def test_wrong_bulk_type_is_refused(self) -> None:
        payload = {**METADATA, "type": "all_cards"}
        ctx, _ = make_ctx(ScriptedOpener([metadata_response(payload)]))

        with self.assertRaises(job.RefreshError) as raised:
            job.fetch_bulk_metadata(ctx)

        self.assertEqual(raised.exception.kind, "invalid_metadata")

    def test_declared_size_over_budget_stops_before_download(self) -> None:
        ctx, _ = make_ctx(ScriptedOpener([metadata_response()]), max_download_bytes=1024)

        with self.assertRaises(job.BudgetExceeded) as raised:
            job.fetch_bulk_metadata(ctx)

        self.assertEqual(raised.exception.kind, "budget_exceeded:download_bytes")


class DownloadTest(unittest.TestCase):
    def source(self) -> "job.BulkSource":
        return job.BulkSource(
            kind="scryfall_bulk",
            updated_at="2026-09-22T09:04:31.371000+00:00",
            download_uri=METADATA["download_uri"],
        )

    def test_gzip_body_is_decompressed_and_hashed(self) -> None:
        body = FIXTURE.read_bytes()
        response = FakeResponse(gzip.compress(body), headers={"Content-Encoding": "gzip"})
        opener = ScriptedOpener([response])
        ctx, _ = make_ctx(opener)
        with tempfile.TemporaryDirectory() as tmp:
            downloaded = job.download_bulk(ctx, self.source(), Path(tmp))
            self.assertEqual(downloaded.path.read_bytes(), body)
        self.assertEqual(downloaded.bytes, len(body))
        self.assertEqual(downloaded.sha256, hashlib.sha256(body).hexdigest())
        self.assertLess(downloaded.compressed_bytes, len(body))
        self.assertEqual(opener.requests[0].get_header("Accept-encoding"), "gzip")

    def test_decompressed_size_over_budget_removes_the_file(self) -> None:
        body = FIXTURE.read_bytes()
        response = FakeResponse(gzip.compress(body), headers={"Content-Encoding": "gzip"})
        ctx, _ = make_ctx(ScriptedOpener([response]), max_download_bytes=100)
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(job.BudgetExceeded) as raised:
                job.download_bulk(ctx, self.source(), Path(tmp))
            self.assertEqual(list(Path(tmp).iterdir()), [])
        self.assertEqual(raised.exception.kind, "budget_exceeded:download_bytes")

    def test_truncated_gzip_fails(self) -> None:
        compressed = gzip.compress(FIXTURE.read_bytes())
        response = FakeResponse(compressed[: len(compressed) // 2], headers={"Content-Encoding": "gzip"})
        ctx, _ = make_ctx(ScriptedOpener([response]))
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(job.UpstreamError) as raised:
                job.download_bulk(ctx, self.source(), Path(tmp))
            self.assertEqual(list(Path(tmp).iterdir()), [])
        self.assertEqual(raised.exception.kind, "upstream_download_truncated")


def fixture_snapshot(**state) -> "job.CatalogSnapshot":
    return job.CatalogSnapshot(
        scryfall_ids={O_SOL, P_BOLT},
        oracle_ids={O_SOL, O_BOLT},
        alias_rows=1,
        set_codes={"lea", "2xm"},
        state=state or {job.STATE_CARDS_LAST_SYNC_AT: "2026-06-06T12:00:00"},
    )


def fixture_plan(snapshot=None, **budget):
    ctx, _ = make_ctx(**budget)
    snapshot = snapshot or fixture_snapshot()
    cutoff = job.new_set_cutoff(snapshot.state, ctx.budget.new_set_margin_days)
    return job.plan_refresh(
        job.iter_bulk_objects(FIXTURE),
        snapshot,
        price_updated_at=job.parse_timestamp(SOURCE_UPDATED_AT),
        cutoff=cutoff,
        ctx=ctx,
    )


def row_by_id(rows, scryfall_id):
    for row in rows:
        if row[0] == scryfall_id:
            return dict(zip(job.CARD_COLUMN_NAMES, row))
    raise AssertionError(f"{scryfall_id} ausente")


class BulkMetadataFormatTest(unittest.TestCase):
    """Bulk de 2026-09-23: JSONL com gzip; a lista JSON fica como alternativa."""

    def parse(self, payload, **budget):
        return job.parse_bulk_metadata(payload, job.Budget(**budget))

    def test_real_2026_09_23_metadata_selects_the_jsonl(self) -> None:
        opener = ScriptedOpener([metadata_response(METADATA_2026_09_23)])
        ctx, _ = make_ctx(opener)

        source = job.fetch_bulk_metadata(ctx)

        for gone in ("download_uri", "size", "content_type", "content_encoding"):
            self.assertNotIn(gone, METADATA_2026_09_23)
        self.assertEqual(source.format, job.BULK_FORMAT_JSONL)
        self.assertEqual(
            source.download_uri,
            "https://data.scryfall.io/default-cards/"
            "default-cards-20260923090535.jsonl.gz",
        )
        self.assertEqual(source.declared_compressed_size, 78591937)
        self.assertIsNone(source.declared_size)
        self.assertEqual(source.updated_at, "2026-09-23T09:05:35.986000+00:00")
        self.assertEqual(source.bulk_id, "e2ef41e3-5778-4bc2-af3f-78eca4dd9c23")
        self.assertEqual(ctx.upstream_requests, 1)

    def test_jsonl_is_preferred_when_both_uris_come(self) -> None:
        payload = {
            **METADATA_2026_09_23,
            "download_uri": METADATA["download_uri"],
            "size": 1024,
        }

        source = self.parse(payload)

        self.assertEqual(source.format, job.BULK_FORMAT_JSONL)
        self.assertEqual(source.download_uri, METADATA_2026_09_23["jsonl_download_uri"])

    def test_legacy_list_is_used_when_only_download_uri_comes(self) -> None:
        source = self.parse(METADATA)

        self.assertEqual(source.format, job.BULK_FORMAT_JSON_ARRAY)
        self.assertEqual(source.download_uri, METADATA["download_uri"])
        self.assertEqual(source.declared_size, 512 * 1024 * 1024)
        self.assertIsNone(source.declared_compressed_size)

    def test_missing_both_uris_has_its_own_error(self) -> None:
        payload = {
            key: value
            for key, value in METADATA_2026_09_23.items()
            if key != "jsonl_download_uri"
        }

        with self.assertRaises(job.RefreshError) as raised:
            self.parse(payload)

        self.assertEqual(raised.exception.kind, "bulk_download_uri_missing")
        self.assertIn("jsonl_download_uri", str(raised.exception))
        self.assertIn("download_uri", str(raised.exception))

    def test_blank_uris_count_as_missing(self) -> None:
        payload = {**METADATA_2026_09_23, "jsonl_download_uri": "  ", "download_uri": ""}

        with self.assertRaises(job.RefreshError) as raised:
            self.parse(payload)

        self.assertEqual(raised.exception.kind, "bulk_download_uri_missing")

    def test_forbidden_host_in_jsonl_uri_is_refused_without_fallback(self) -> None:
        payload = {
            **METADATA_2026_09_23,
            "jsonl_download_uri": "https://evil.example/default-cards.jsonl.gz",
            "download_uri": METADATA["download_uri"],
        }

        with self.assertRaises(job.RefreshError) as raised:
            self.parse(payload)

        self.assertEqual(raised.exception.kind, "unexpected_download_host")
        self.assertIn("jsonl_download_uri", str(raised.exception))

    def test_plain_http_jsonl_uri_is_refused(self) -> None:
        payload = {
            **METADATA_2026_09_23,
            "jsonl_download_uri": "http://data.scryfall.io/default-cards/x.jsonl.gz",
        }

        with self.assertRaises(job.RefreshError) as raised:
            self.parse(payload)

        self.assertEqual(raised.exception.kind, "unexpected_download_host")

    def test_compressed_size_over_budget_stops_before_download(self) -> None:
        with self.assertRaises(job.BudgetExceeded) as raised:
            self.parse(METADATA_2026_09_23, max_compressed_bytes=78591936)

        self.assertEqual(raised.exception.kind, "budget_exceeded:compressed_bytes")
        self.assertEqual(
            self.parse(METADATA_2026_09_23).declared_compressed_size, 78591937
        )

    def test_local_file_format_follows_the_name(self) -> None:
        jsonl = job.BULK_FORMAT_JSONL
        array = job.BULK_FORMAT_JSON_ARRAY
        self.assertEqual(job.bulk_format_for_name("x/default-cards.jsonl.gz"), jsonl)
        self.assertEqual(job.bulk_format_for_name("x/DEFAULT.JSONL"), jsonl)
        self.assertEqual(job.bulk_format_for_name("x/default-cards.json"), array)
        self.assertEqual(job.bulk_format_for_name("x/default-cards.json.gz"), array)


class JsonlDownloadAndParseTest(unittest.TestCase):
    """O `.jsonl.gz` é descompactado pelo conteúdo e lido linha a linha."""

    PLAIN = gzip.decompress(FIXTURE_JSONL_GZ.read_bytes())

    def source(self) -> "job.BulkSource":
        return job.BulkSource(
            kind="scryfall_bulk",
            updated_at="2026-09-23T09:05:35.986000+00:00",
            download_uri=METADATA_2026_09_23["jsonl_download_uri"],
            format=job.BULK_FORMAT_JSONL,
            declared_compressed_size=78591937,
        )

    def download(self, body: bytes, headers=None, **budget):
        opener = ScriptedOpener([FakeResponse(body, headers=headers or {})])
        ctx, _ = make_ctx(opener, **budget)
        return opener, ctx

    def test_jsonl_gz_without_content_encoding_is_decompressed_by_content(self) -> None:
        body = FIXTURE_JSONL_GZ.read_bytes()
        opener, ctx = self.download(body, {"Content-Type": "application/gzip"})

        with tempfile.TemporaryDirectory() as tmp:
            downloaded = job.download_bulk(ctx, self.source(), Path(tmp))
            content = downloaded.path.read_bytes()
            values = list(job.iter_bulk_objects(downloaded.path, job.BULK_FORMAT_JSONL))

        self.assertEqual(content, self.PLAIN)
        self.assertTrue(downloaded.gzip)
        self.assertEqual(downloaded.compressed_bytes, len(body))
        self.assertEqual(downloaded.bytes, len(self.PLAIN))
        self.assertEqual(downloaded.sha256, hashlib.sha256(self.PLAIN).hexdigest())
        self.assertEqual(values, json.loads(FIXTURE.read_text(encoding="utf-8")))
        self.assertEqual(
            opener.requests[0].full_url, METADATA_2026_09_23["jsonl_download_uri"]
        )

    def test_plain_body_is_kept_as_is(self) -> None:
        _, ctx = self.download(self.PLAIN)

        with tempfile.TemporaryDirectory() as tmp:
            downloaded = job.download_bulk(ctx, self.source(), Path(tmp))
            content = downloaded.path.read_bytes()

        self.assertEqual(content, self.PLAIN)
        self.assertFalse(downloaded.gzip)

    def test_multi_member_gzip_is_read_whole(self) -> None:
        half = len(self.PLAIN) // 2
        body = gzip.compress(self.PLAIN[:half]) + gzip.compress(self.PLAIN[half:])
        _, ctx = self.download(body)

        with tempfile.TemporaryDirectory() as tmp:
            downloaded = job.download_bulk(ctx, self.source(), Path(tmp))
            content = downloaded.path.read_bytes()

        self.assertEqual(content, self.PLAIN)

    def test_decompressed_jsonl_over_budget_removes_the_file(self) -> None:
        _, ctx = self.download(FIXTURE_JSONL_GZ.read_bytes(), max_download_bytes=1000)

        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(job.BudgetExceeded) as raised:
                job.download_bulk(ctx, self.source(), Path(tmp))
            self.assertEqual(list(Path(tmp).iterdir()), [])

        self.assertEqual(raised.exception.kind, "budget_exceeded:download_bytes")

    def test_compressed_jsonl_over_budget_stops_the_download(self) -> None:
        _, ctx = self.download(FIXTURE_JSONL_GZ.read_bytes(), max_compressed_bytes=100)

        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(job.BudgetExceeded) as raised:
                job.download_bulk(ctx, self.source(), Path(tmp))
            self.assertEqual(list(Path(tmp).iterdir()), [])

        self.assertEqual(raised.exception.kind, "budget_exceeded:compressed_bytes")

    def test_jsonl_parser_rejects_a_malformed_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bulk.jsonl"
            path.write_text('{"object": "card"}\n{quebrado\n', encoding="utf-8")
            with self.assertRaises(job.RefreshError) as raised:
                list(job.iter_bulk_objects(path, job.BULK_FORMAT_JSONL))

        self.assertEqual(raised.exception.kind, "invalid_bulk")
        self.assertIn("linha 2", str(raised.exception))

    def test_jsonl_parser_skips_blank_lines_and_rejects_an_empty_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bulk.jsonl"
            path.write_text('\n{"a": 1}\r\n\n', encoding="utf-8")
            self.assertEqual(
                list(job.iter_bulk_objects(path, job.BULK_FORMAT_JSONL)), [{"a": 1}]
            )
            path.write_text("\n\n", encoding="utf-8")
            with self.assertRaises(job.RefreshError) as raised:
                list(job.iter_bulk_objects(path, job.BULK_FORMAT_JSONL))

        self.assertEqual(raised.exception.kind, "invalid_bulk")

    def test_jsonl_plan_is_identical_to_the_json_list_plan(self) -> None:
        snapshot = fixture_snapshot()
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bulk.jsonl"
            path.write_bytes(self.PLAIN)
            ctx, _ = make_ctx()
            jsonl_plan = job.plan_refresh(
                job.iter_bulk_objects(path, job.BULK_FORMAT_JSONL),
                snapshot,
                price_updated_at=job.parse_timestamp(SOURCE_UPDATED_AT),
                cutoff=job.new_set_cutoff(snapshot.state, ctx.budget.new_set_margin_days),
                ctx=ctx,
            )
        array_plan = fixture_plan(fixture_snapshot())

        self.assertEqual(jsonl_plan.counts, array_plan.counts)
        self.assertEqual(jsonl_plan.updates, array_plan.updates)
        self.assertEqual(jsonl_plan.inserts, array_plan.inserts)
        self.assertEqual(jsonl_plan.legalities, array_plan.legalities)
        self.assertEqual(jsonl_plan.sets, array_plan.sets)


class ParseAndPlanTest(unittest.TestCase):
    def test_stream_parser_yields_every_array_element(self) -> None:
        values = list(job.iter_bulk_objects(FIXTURE))
        self.assertEqual(len(values), 9)
        self.assertEqual(values[0]["id"], P_SOL_CMM)

    def test_stream_parser_rejects_an_unclosed_array(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "broken.json"
            path.write_text('[{"id": "x"},', encoding="utf-8")
            with self.assertRaises(job.RefreshError) as raised:
                list(job.iter_bulk_objects(path))
        self.assertEqual(raised.exception.kind, "invalid_bulk")

    def test_stream_parser_rejects_a_non_list(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "object.json"
            path.write_text('{"object": "list"}', encoding="utf-8")
            with self.assertRaises(job.RefreshError):
                list(job.iter_bulk_objects(path))

    def test_normalize_printing_keeps_printing_identity_and_guards_values(self) -> None:
        raw = {value["id"]: value for value in job.iter_bulk_objects(FIXTURE) if "id" in value}

        adept = job.normalize_printing(raw[P_ADEPT])
        self.assertEqual(adept.oracle_id, O_ADEPT)
        self.assertEqual(adept.set_code, "BRT")
        self.assertIsNone(adept.oracle_text)
        self.assertIsNone(adept.mana_cost)
        self.assertIn("/normal/front/5/c/" + P_ADEPT, adept.image_url)
        self.assertEqual(json.loads(adept.card_faces_json)[1]["name"], "BrewTact Test Ascendant")
        self.assertTrue(adept.foil)
        self.assertTrue(adept.insertable)

        drake = job.normalize_printing(raw[P_DRAKE])
        # The payload image belongs to another printing: never trusted.
        self.assertEqual(
            drake.image_url,
            f"https://cards.scryfall.io/normal/front/5/c/{P_DRAKE}.jpg",
        )
        self.assertIsNone(drake.price_usd)
        self.assertEqual(drake.price_usd_foil, Decimal("0.75"))
        self.assertFalse(drake.foil)

        bolt = job.normalize_printing(raw[P_BOLT])
        self.assertEqual(bolt.price_usd, Decimal("1.50"))
        self.assertEqual(
            dict(bolt.legalities),
            {"commander": "legal", "modern": "legal", "pauper": "legal", "standard": "not_legal"},
        )

        gleemax = job.normalize_printing(raw[P_GLEEMAX])
        self.assertIsNone(gleemax.cmc)
        self.assertTrue(gleemax.is_reserved)

        self.assertFalse(job.normalize_printing(raw["5c8e7c9e-2222-4b2b-9b2b-000000000005"]).insertable)
        self.assertFalse(job.normalize_printing(raw["5c8e7c9e-2222-4b2b-9b2b-000000000007"]).insertable)
        self.assertIsNone(job.normalize_printing({"object": "card", "name": "Sem id"}))
        self.assertIsNone(job.normalize_printing({"object": "card", "id": O_SOL, "name": "  "}))

    def test_plan_classifies_every_printing_of_the_fixture(self) -> None:
        plan = fixture_plan()

        self.assertEqual(
            dict(plan.counts),
            {
                "bulk_objects": 9,
                "refresh_candidates": 1,
                "insert_new_card": 3,
                "insert_recent_set_printing": 1,
                "skipped_older_printing_phase2": 1,
                "skipped_not_a_paper_game_card": 2,
                "skipped_invalid_object": 1,
            },
        )
        self.assertEqual([row[0] for row in plan.updates], [P_BOLT])
        self.assertEqual(
            sorted(row[0] for row in plan.inserts),
            sorted([P_SOL_BRT, P_DRAKE, P_ADEPT, P_GLEEMAX]),
        )
        self.assertEqual(
            set(plan.legalities),
            {O_SOL, O_BOLT, O_DRAKE, O_ADEPT, O_GLEEMAX},
        )
        self.assertEqual(sorted(plan.sets), ["BRT", "UNF"])
        self.assertEqual(plan.sets["BRT"], ("BRT", "BrewTact Test Set", date(2026, 7, 15), "commander"))

    def test_plan_rows_carry_prices_with_the_source_timestamp(self) -> None:
        plan = fixture_plan()
        bolt = row_by_id(plan.updates, P_BOLT)
        self.assertEqual(bolt["price_usd"], Decimal("1.50"))
        self.assertEqual(bolt["price"], Decimal("1.50"))
        self.assertEqual(bolt["price_usd_foil"], Decimal("3.00"))
        self.assertEqual(bolt["price_source"], "scryfall")
        self.assertEqual(bolt["price_updated_at"], job.parse_timestamp(SOURCE_UPDATED_AT))
        self.assertIs(bolt["is_reserved"], False)
        inserted = row_by_id(plan.inserts, P_SOL_BRT)
        self.assertIs(inserted["is_reserved"], False)
        self.assertEqual(inserted["set_code"], "BRT")

    def test_without_checkpoint_older_cards_do_not_gain_printings(self) -> None:
        snapshot = fixture_snapshot()
        snapshot.state = {}
        plan = fixture_plan(snapshot)

        self.assertNotIn(P_SOL_BRT, [row[0] for row in plan.inserts])
        self.assertEqual(plan.counts["skipped_older_printing_phase2"], 2)

    def test_new_card_budget_stops_the_plan(self) -> None:
        with self.assertRaises(job.BudgetExceeded) as raised:
            fixture_plan(max_new_cards=2)
        self.assertEqual(raised.exception.kind, "budget_exceeded:new_cards")

    def test_runtime_budget_stops_the_plan(self) -> None:
        ticks = iter([0.0, 5000.0])
        ctx = job.RunContext(budget=job.Budget(max_runtime_seconds=10), clock=lambda: next(ticks, 5000.0))
        ctx.start()
        with self.assertRaises(job.BudgetExceeded) as raised:
            job.plan_refresh(
                job.iter_bulk_objects(FIXTURE),
                fixture_snapshot(),
                price_updated_at=job.parse_timestamp(SOURCE_UPDATED_AT),
                cutoff=None,
                ctx=ctx,
            )
        self.assertEqual(raised.exception.kind, "budget_exceeded:runtime")


# O SQL do job é escrito em maiúsculas; a busca diferencia caixa para não
# confundir prosa (docstrings, mensagens) com instrução.
WRITE_KEYWORDS = re.compile(
    r"\b(INSERT\s+INTO|UPDATE|DELETE\s+FROM|TRUNCATE|DROP|ALTER|CREATE|MERGE\s+INTO|COPY|GRANT|REVOKE)\b\s*(\w+)?"
)


def written_tables(sql: str) -> list[tuple[str, str]]:
    found = []
    for match in WRITE_KEYWORDS.finditer(sql):
        verb = " ".join(match.group(1).upper().split())
        target = (match.group(2) or "").lower()
        if verb == "UPDATE" and target == "set":
            # `ON CONFLICT ... DO UPDATE SET` updates the INSERT target.
            continue
        found.append((verb, target))
    return found


class ApplyContractTest(unittest.TestCase):
    def test_every_write_statement_targets_only_reference_or_audit_tables(self) -> None:
        for sql in job.WRITE_STATEMENTS:
            writes = written_tables(sql)
            self.assertTrue(writes, sql)
            for verb, target in writes:
                self.assertIn(verb, {"INSERT INTO", "UPDATE"}, sql)
                self.assertIn(target, job.WRITABLE_TABLES, sql)

    def test_source_has_no_delete_ddl_or_user_table(self) -> None:
        source = (Path(job.__file__)).read_text(encoding="utf-8")
        code = "\n".join(
            line for line in source.splitlines() if not line.lstrip().startswith("#")
        )
        for verb, target in written_tables(code):
            if verb in {"INSERT INTO", "UPDATE"}:
                if target in {"", "set"}:
                    continue
                self.assertIn(target, job.WRITABLE_TABLES, (verb, target))
            else:
                self.fail(f"{verb} {target} não pertence ao contrato")
        for table in USER_TABLES:
            self.assertNotRegex(code, rf"\b{table}\b")

    def test_contract_names_the_reference_and_audit_tables(self) -> None:
        self.assertEqual(job.APPLY_CONTRACT, "catalog_reference_apply_v1")
        self.assertEqual(
            job.WRITABLE_TABLES,
            frozenset({"cards", "sets", "card_legalities", "sync_log", "sync_state"}),
        )

    def test_updates_only_touch_rows_that_change(self) -> None:
        self.assertIn(") IS DISTINCT FROM (", job.UPDATE_CARDS_SQL)
        self.assertIn(
            "WHERE card_legalities.status IS DISTINCT FROM EXCLUDED.status",
            job.UPSERT_LEGALITIES_SQL,
        )
        self.assertIn("ON CONFLICT (scryfall_id) DO NOTHING", job.INSERT_CARDS_SQL)
        self.assertIn("WHERE NOT EXISTS", job.INSERT_SETS_SQL)


class FakeCursor:
    def __init__(self, db: "FakeDatabase"):
        self.db = db
        self._rows: list[tuple] = []

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False

    def execute(self, sql, params=None):
        self.db.statements.append((sql, params))
        text = " ".join(sql.split())
        if text.startswith("SELECT table_name, column_name FROM information_schema.columns"):
            self._rows = list(self.db.columns)
        elif text.startswith("SELECT key, value FROM sync_state"):
            self._rows = sorted(self.db.state.items())
        elif text.startswith("SELECT scryfall_id::text, oracle_id::text FROM cards"):
            self._rows = [(O_SOL, O_SOL), (P_BOLT, O_BOLT)]
        elif text.startswith("SELECT LOWER(code) FROM sets"):
            self._rows = [("lea",), ("2xm",)]
        elif text.startswith("SELECT pg_try_advisory_xact_lock"):
            self._rows = [(self.db.lock_available,)]
        else:
            self._rows = []

    def fetchall(self):
        return list(self._rows)

    def fetchone(self):
        return self._rows[0] if self._rows else None


class FakeDatabase:
    def __init__(self, state=None, lock_available=True):
        # O schema real, capturado antes de qualquer teste mexer no contrato.
        self.columns = [
            (table, column)
            for table, columns in job.REQUIRED_COLUMNS.items()
            for column in columns
        ]
        self.state = dict(
            state
            if state is not None
            else {job.STATE_CARDS_LAST_SYNC_AT: "2026-06-06T12:00:00"}
        )
        self.lock_available = lock_available
        self.statements: list[tuple[str, object]] = []
        self.values_calls: list[tuple[str, list]] = []
        self.commits = 0
        self.rollbacks = 0
        self.readonly = False
        self.closed = False

    # connection protocol
    def cursor(self):
        return FakeCursor(self)

    def commit(self):
        self.commits += 1

    def rollback(self):
        self.rollbacks += 1

    def close(self):
        self.closed = True

    def set_session(self, readonly=False, **_):
        self.readonly = readonly

    def writes(self) -> list[str]:
        sqls = [sql for sql, _ in self.values_calls]
        sqls += [sql for sql, _ in self.statements if written_tables(sql)]
        return sqls


class RunModesTest(unittest.TestCase):
    def setUp(self) -> None:
        self.db = FakeDatabase()
        self.connects = 0
        self._original_values = job._execute_values
        self._original_values_no_fetch = job._execute_values_no_fetch

        def fake_values(cur, sql, rows, template, page_size):
            self.db.values_calls.append((sql, list(rows)))
            if sql is job.UPSERT_LEGALITIES_SQL:
                return [(True,) for _ in rows]
            return [(row[0],) for row in rows]

        def fake_values_no_fetch(cur, sql, rows, template, page_size):
            self.db.values_calls.append((sql, list(rows)))
            for key, value in rows:
                self.db.state[key] = value

        job._execute_values = fake_values
        job._execute_values_no_fetch = fake_values_no_fetch

    def tearDown(self) -> None:
        job._execute_values = self._original_values
        job._execute_values_no_fetch = self._original_values_no_fetch

    def connect(self, environment):
        self.connects += 1
        return self.db

    def args(self, *extra: str) -> argparse.Namespace:
        with tempfile.TemporaryDirectory() as tmp:
            env_file = str(Path(tmp) / "missing.env")
        return job.parse_args(["--env-file", env_file, *extra])

    def run_job(self, argv, *, environment=None, opener=None):
        ctx, sleeps = make_ctx(opener or ScriptedOpener([]))
        code, receipt = job.run(
            self.args(*argv),
            environment=environment or {},
            ctx=ctx,
            connect_fn=self.connect,
        )
        return code, receipt, ctx

    def test_scheduled_run_without_activation_calls_nothing_and_writes_nothing(self) -> None:
        self.db.state[job.STATE_CARDS_LAST_SYNC_AT] = "2026-09-20T10:00:00Z"
        opener = ScriptedOpener([])
        code, receipt, ctx = self.run_job([], opener=opener)

        self.assertEqual(code, 0)
        self.assertEqual(receipt["status"], "contract_inactive")
        self.assertEqual(opener.requests, [])
        self.assertEqual(ctx.upstream_requests, 0)
        self.assertEqual(self.db.writes(), [])
        self.assertFalse(receipt["database_writes"])

    def test_scheduled_run_after_deactivation_stays_inactive(self) -> None:
        self.db.state[job.STATE_ACTIVE_CONTRACT] = job.INACTIVE_MARKER
        code, receipt, _ = self.run_job([])
        self.assertEqual(receipt["status"], "contract_inactive")
        self.assertEqual(self.db.writes(), [])

    def test_supervised_modes_require_explicit_approval(self) -> None:
        for mode in ("activate", "deactivate"):
            code, receipt, _ = self.run_job(["--mode", mode])
            self.assertEqual(code, 2)
            self.assertEqual(receipt["status"], "refused")
            self.assertEqual(receipt["error"]["kind"], "approval_missing")
        self.assertEqual(self.connects, 0)

    def test_scheduled_same_source_is_a_recorded_noop_without_download(self) -> None:
        self.db.state.update(
            {
                job.STATE_ACTIVE_CONTRACT: job.APPLY_CONTRACT,
                job.STATE_SOURCE_UPDATED_AT: "2026-09-22T09:04:31.371000+00:00",
            }
        )
        opener = ScriptedOpener([metadata_response()])
        code, receipt, ctx = self.run_job([], opener=opener)

        self.assertEqual(code, 0)
        self.assertEqual(receipt["status"], "noop_same_source")
        self.assertEqual(ctx.upstream_requests, 1)
        targets = {target for sql in self.db.writes() for _, target in written_tables(sql)}
        self.assertEqual(targets, {"sync_state", "sync_log"})

    def test_dry_run_is_read_only(self) -> None:
        code, receipt, _ = self.run_job(
            ["--mode", "dry-run", "--bulk-json", str(FIXTURE), "--source-updated-at", SOURCE_UPDATED_AT]
        )

        self.assertEqual(code, 0)
        self.assertEqual(receipt["status"], "dry_run")
        self.assertTrue(self.db.readonly)
        self.assertEqual(self.db.writes(), [])
        self.assertEqual(self.db.commits, 0)
        self.assertEqual(receipt["counts"]["planned"]["cards_insert_candidates"], 4)

    def test_activation_applies_the_plan_and_records_the_contract(self) -> None:
        code, receipt, ctx = self.run_job(
            ["--mode", "activate", "--bulk-json", str(FIXTURE), "--source-updated-at", SOURCE_UPDATED_AT],
            environment={job.WRITE_APPROVAL_ENV: job.WRITE_APPROVAL_VALUE},
        )

        self.assertEqual(code, 0, receipt)
        self.assertEqual(receipt["status"], "activated")
        self.assertEqual(ctx.upstream_requests, 0)
        self.assertEqual(self.db.state[job.STATE_ACTIVE_CONTRACT], job.APPLY_CONTRACT)
        self.assertEqual(self.db.state[job.STATE_SOURCE_UPDATED_AT], "2026-09-22T09:00:00+00:00")
        self.assertIn(job.STATE_CARDS_LAST_SYNC_AT, self.db.state)
        self.assertEqual(self.db.commits, 1)
        counts = receipt["counts"]
        self.assertEqual(counts["cards"]["inserted"], 4)
        self.assertEqual(counts["cards"]["updated"], 1)
        self.assertEqual(counts["sets"]["inserted"], 2)
        self.assertEqual(counts["card_legalities"]["oracle_ids"], 5)
        self.assertEqual(counts["catalog_before"]["alias_rows_prices_not_refreshed"], 1)
        targets = {target for sql in self.db.writes() for _, target in written_tables(sql)}
        self.assertLessEqual(targets, set(job.WRITABLE_TABLES))
        self.assertTrue(any("pg_try_advisory_xact_lock" in sql for sql, _ in self.db.statements))
        sync_types = [params[0] for sql, params in self.db.statements if sql is job.INSERT_SYNC_LOG_SQL]
        self.assertEqual(
            sync_types,
            [job.SYNC_LOG_CARDS, job.SYNC_LOG_SETS, job.SYNC_LOG_LEGALITIES],
        )

    def test_busy_lock_fails_without_writing_the_plan(self) -> None:
        self.db.lock_available = False
        code, receipt, _ = self.run_job(
            ["--mode", "activate", "--bulk-json", str(FIXTURE), "--source-updated-at", SOURCE_UPDATED_AT],
            environment={job.WRITE_APPROVAL_ENV: job.WRITE_APPROVAL_VALUE},
        )
        self.assertEqual(code, 1)
        self.assertEqual(receipt["error"]["kind"], "locked")
        self.assertEqual([sql for sql, _ in self.db.values_calls], [])

    def test_upstream_failure_is_logged_and_nothing_is_applied(self) -> None:
        self.db.state[job.STATE_ACTIVE_CONTRACT] = job.APPLY_CONTRACT
        opener = ScriptedOpener([http_error(503), http_error(503), http_error(503)])
        code, receipt, _ = self.run_job([], opener=opener)

        self.assertEqual(code, 1)
        self.assertEqual(receipt["status"], "failed")
        self.assertEqual(receipt["error"]["kind"], "upstream_retries_exhausted")
        self.assertTrue(receipt["failure_logged"])
        logged = [params for sql, params in self.db.statements if sql is job.INSERT_SYNC_LOG_SQL]
        self.assertEqual(len(logged), 1)
        self.assertEqual(logged[0][0], job.SYNC_LOG_RUN)
        self.assertEqual(logged[0][3], "failed")
        self.assertEqual(self.db.values_calls, [])

    def test_deactivation_records_the_pause(self) -> None:
        self.db.state[job.STATE_ACTIVE_CONTRACT] = job.APPLY_CONTRACT
        code, receipt, _ = self.run_job(
            ["--mode", "deactivate"],
            environment={job.WRITE_APPROVAL_ENV: job.WRITE_APPROVAL_VALUE},
        )
        self.assertEqual(code, 0)
        self.assertEqual(receipt["status"], "deactivated")
        self.assertEqual(self.db.state[job.STATE_ACTIVE_CONTRACT], job.INACTIVE_MARKER)

    def test_missing_schema_is_refused_without_ddl(self) -> None:
        original = job.REQUIRED_COLUMNS
        job.REQUIRED_COLUMNS = {**original, "cards": original["cards"] + ("column_that_does_not_exist",)}
        try:
            code, receipt, _ = self.run_job(
                ["--mode", "dry-run", "--bulk-json", str(FIXTURE), "--source-updated-at", SOURCE_UPDATED_AT]
            )
        finally:
            job.REQUIRED_COLUMNS = original
        self.assertEqual(code, 2)
        self.assertEqual(receipt["error"]["kind"], "schema_mismatch")

    def test_receipt_file_carries_contract_source_budget_and_counts(self) -> None:
        code, receipt, _ = self.run_job(
            ["--mode", "activate", "--bulk-json", str(FIXTURE), "--source-updated-at", SOURCE_UPDATED_AT],
            environment={job.WRITE_APPROVAL_ENV: job.WRITE_APPROVAL_VALUE},
        )
        with tempfile.TemporaryDirectory() as tmp:
            path = job.write_receipt(receipt, Path(tmp))
            saved = json.loads(path.read_text(encoding="utf-8"))
            latest = json.loads((Path(tmp) / "latest_receipt.json").read_text(encoding="utf-8"))
        self.assertEqual(saved, latest)
        for key in (
            "receipt_version",
            "job",
            "apply_contract",
            "run_id",
            "mode",
            "status",
            "started_at",
            "finished_at",
            "writable_tables",
            "source",
            "upstream_requests",
            "budget",
            "counts",
            "database_writes",
            "freshness",
            "alerts",
            "error",
        ):
            self.assertIn(key, saved)
        self.assertEqual(saved["source"]["sha256"], hashlib.sha256(FIXTURE.read_bytes()).hexdigest())
        self.assertEqual(saved["apply_contract"], job.APPLY_CONTRACT)


    # BT-CAT-03 (D-36): o alerta sai em qualquer modo, sem gravar nada; só o
    # agendado muda o exit.
    def test_stale_catalog_alerts_while_the_contract_is_inactive(self) -> None:
        opener = ScriptedOpener([])
        code, receipt, _ = self.run_job([], opener=opener)

        self.assertEqual(code, job.FRESHNESS_ALERT_EXIT_CODE)
        self.assertEqual(receipt["status"], "contract_inactive")
        self.assertEqual(receipt["alerts"], [job.FRESHNESS_ALERT])
        self.assertTrue(receipt["freshness"]["stale"])
        self.assertEqual(opener.requests, [])
        self.assertEqual(self.db.writes(), [])

    def test_fresh_catalog_does_not_alert(self) -> None:
        self.db.state[job.STATE_CARDS_LAST_SYNC_AT] = "2026-09-20T10:00:00Z"
        code, receipt, _ = self.run_job([])

        self.assertEqual(code, 0)
        self.assertEqual(receipt["alerts"], [])
        self.assertFalse(receipt["freshness"]["stale"])

    def test_applied_run_is_measured_by_the_new_source(self) -> None:
        code, receipt, _ = self.run_job(
            ["--mode", "activate", "--bulk-json", str(FIXTURE), "--source-updated-at", SOURCE_UPDATED_AT],
            environment={job.WRITE_APPROVAL_ENV: job.WRITE_APPROVAL_VALUE},
        )

        self.assertEqual(code, 0, receipt)
        self.assertEqual(receipt["freshness"]["updated_at"], SOURCE_UPDATED_AT)
        self.assertFalse(receipt["freshness"]["stale"])
        self.assertEqual(receipt["alerts"], [])

    def test_manual_modes_report_the_alert_without_changing_the_exit_code(self) -> None:
        code, receipt, _ = self.run_job(
            ["--mode", "dry-run", "--bulk-json", str(FIXTURE), "--source-updated-at", SOURCE_UPDATED_AT]
        )

        self.assertEqual(code, 0)
        self.assertEqual(receipt["alerts"], [job.FRESHNESS_ALERT])


    def test_activation_from_the_jsonl_gz_file(self) -> None:
        code, receipt, ctx = self.run_job(
            [
                "--mode",
                "activate",
                "--bulk-json",
                str(FIXTURE_JSONL_GZ),
                "--source-updated-at",
                SOURCE_UPDATED_AT,
            ],
            environment={job.WRITE_APPROVAL_ENV: job.WRITE_APPROVAL_VALUE},
        )

        self.assertEqual(code, 0, receipt)
        self.assertEqual(receipt["status"], "activated")
        self.assertEqual(receipt["source"]["format"], job.BULK_FORMAT_JSONL)
        self.assertTrue(receipt["source"]["gzip"])
        self.assertEqual(
            receipt["source"]["sha256"],
            hashlib.sha256(gzip.decompress(FIXTURE_JSONL_GZ.read_bytes())).hexdigest(),
        )
        self.assertEqual(ctx.upstream_requests, 0)
        counts = receipt["counts"]
        self.assertEqual(counts["cards"]["inserted"], 4)
        self.assertEqual(counts["cards"]["updated"], 1)
        self.assertEqual(counts["sets"]["inserted"], 2)
        self.assertEqual(counts["card_legalities"]["oracle_ids"], 5)

    def test_scheduled_run_downloads_the_jsonl_of_the_current_metadata(self) -> None:
        self.db.state[job.STATE_ACTIVE_CONTRACT] = job.APPLY_CONTRACT
        opener = ScriptedOpener(
            [
                metadata_response(METADATA_2026_09_23),
                FakeResponse(FIXTURE_JSONL_GZ.read_bytes()),
            ]
        )

        with tempfile.TemporaryDirectory() as tmp:
            code, receipt, ctx = self.run_job(["--work-dir", tmp], opener=opener)
            leftovers = list(Path(tmp).iterdir())

        self.assertEqual(code, 0, receipt)
        self.assertEqual(receipt["status"], "applied")
        self.assertEqual(receipt["source"]["format"], job.BULK_FORMAT_JSONL)
        self.assertEqual(receipt["source"]["declared_compressed_size"], 78591937)
        self.assertEqual(ctx.upstream_requests, 2)
        self.assertEqual(
            [request.full_url for request in opener.requests],
            [job.BULK_METADATA_URL, METADATA_2026_09_23["jsonl_download_uri"]],
        )
        self.assertEqual(receipt["counts"]["cards"]["inserted"], 4)
        self.assertEqual(leftovers, [])

    def test_dry_run_with_the_production_metadata_of_2026_09_23(self) -> None:
        # Reproduz o dry-run de produção de 2026-09-23 14:53:41Z, que falhava com
        # unexpected_download_host antes do suporte ao JSONL.
        opener = ScriptedOpener(
            [
                metadata_response(METADATA_2026_09_23),
                FakeResponse(FIXTURE_JSONL_GZ.read_bytes()),
            ]
        )

        with tempfile.TemporaryDirectory() as tmp:
            code, receipt, _ = self.run_job(
                ["--mode", "dry-run", "--work-dir", tmp], opener=opener
            )

        self.assertEqual(code, 0, receipt)
        self.assertEqual(receipt["status"], "dry_run")
        self.assertIsNone(receipt["error"])
        self.assertFalse(receipt["database_writes"])
        self.assertEqual(self.db.writes(), [])
        self.assertEqual(receipt["counts"]["planned"]["cards_insert_candidates"], 4)

    def test_metadata_without_any_uri_fails_with_its_own_error(self) -> None:
        self.db.state[job.STATE_ACTIVE_CONTRACT] = job.APPLY_CONTRACT
        payload = {
            key: value
            for key, value in METADATA_2026_09_23.items()
            if key != "jsonl_download_uri"
        }
        opener = ScriptedOpener([metadata_response(payload)])

        code, receipt, ctx = self.run_job([], opener=opener)

        self.assertEqual(code, 1)
        self.assertEqual(receipt["status"], "failed")
        self.assertEqual(receipt["error"]["kind"], "bulk_download_uri_missing")
        self.assertEqual(ctx.upstream_requests, 1)
        self.assertEqual(self.db.values_calls, [])
        self.assertTrue(receipt["failure_logged"])


class FreshnessTest(unittest.TestCase):
    """BT-CAT-03 (D-36): catálogo com mais de 7 dias dispara alerta."""

    NOW = datetime(2026, 9, 23, 10, 0, tzinfo=timezone.utc)

    def test_seven_days_is_the_limit(self) -> None:
        at_limit = job.catalog_freshness(
            {job.STATE_CARDS_LAST_SYNC_AT: "2026-09-16T10:00:00Z"}, self.NOW
        )
        over = job.catalog_freshness(
            {job.STATE_CARDS_LAST_SYNC_AT: "2026-09-16T09:59:00Z"}, self.NOW
        )
        self.assertEqual(at_limit["age_days"], 7.0)
        self.assertFalse(at_limit["stale"])
        self.assertTrue(over["stale"])
        self.assertEqual(over["max_age_days"], 7)

    def test_source_date_wins_over_the_last_sync(self) -> None:
        freshness = job.catalog_freshness(
            {
                job.STATE_SOURCE_UPDATED_AT: "2026-09-22T09:00:00+00:00",
                job.STATE_CARDS_LAST_SYNC_AT: "2026-06-06T12:00:00",
            },
            self.NOW,
        )
        self.assertEqual(freshness["updated_at"], "2026-09-22T09:00:00+00:00")
        self.assertFalse(freshness["stale"])

    def test_naive_timestamp_of_the_old_dart_sync_is_read_as_utc(self) -> None:
        freshness = job.catalog_freshness(
            {job.STATE_CARDS_LAST_SYNC_AT: "2026-06-06T12:00:00"}, self.NOW
        )
        self.assertEqual(freshness["updated_at"], "2026-06-06T12:00:00+00:00")
        self.assertTrue(freshness["stale"])
        self.assertGreater(freshness["age_days"], 100)

    def test_unknown_age_is_stale(self) -> None:
        freshness = job.catalog_freshness({}, self.NOW)
        self.assertIsNone(freshness["updated_at"])
        self.assertTrue(freshness["stale"])


class WrapperTest(unittest.TestCase):
    """O invólucro roda o job na própria imagem de ops, sem docker exec nem dart run."""

    WRAPPER = Path(__file__).resolve().parents[1] / "bin" / "cron_sync_cards.sh"
    REPO_ROOT = Path(__file__).resolve().parents[2]

    def fake_python(self, tmp: Path, *, has_psycopg2: bool) -> tuple[Path, Path]:
        argv_log = tmp / "argv.txt"
        fake = tmp / "fake_python"
        fake.write_text(
            "#!/bin/sh\n"
            'if [ "$1" = "-c" ]; then exit ' + ("0" if has_psycopg2 else "1") + "; fi\n"
            f'printf "%s\\n" "$@" > "{argv_log}"\n',
            encoding="utf-8",
        )
        fake.chmod(0o755)
        return fake, argv_log

    def run_wrapper(self, fake: Path, *args: str) -> subprocess.CompletedProcess:
        environment = {
            **os.environ,
            "PYTHON_BIN": str(fake),
            "MTGIA_HOME": str(self.REPO_ROOT),
            "MANALOOM_CATALOG_REFERENCE_OUTPUT_DIR": "/data/manaloom-ops/artifacts/catalog_reference_refresh",
        }
        return subprocess.run(
            ["bash", str(self.WRAPPER), *args],
            env=environment,
            capture_output=True,
            text=True,
            check=False,
        )

    def test_wrapper_execs_the_python_job_with_the_daemon_arguments(self) -> None:
        source = self.WRAPPER.read_text(encoding="utf-8")
        code = "\n".join(
            line for line in source.splitlines() if not line.lstrip().startswith("#")
        )
        self.assertNotIn("docker", code)
        self.assertNotIn("dart run", code)
        self.assertTrue(os.access(self.WRAPPER, os.X_OK))
        with tempfile.TemporaryDirectory() as tmp:
            fake, argv_log = self.fake_python(Path(tmp), has_psycopg2=True)
            completed = self.run_wrapper(fake, "--mode", "scheduled")
            self.assertEqual(completed.returncode, 0, completed.stderr)
            argv = argv_log.read_text(encoding="utf-8").splitlines()
        self.assertEqual(
            argv,
            [
                "server/bin/sync_catalog_reference_from_scryfall.py",
                "--output-dir",
                "/data/manaloom-ops/artifacts/catalog_reference_refresh",
                "--mode",
                "scheduled",
            ],
        )

    def test_wrapper_refuses_a_runtime_without_psycopg2(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            fake, argv_log = self.fake_python(Path(tmp), has_psycopg2=False)
            completed = self.run_wrapper(fake, "--mode", "scheduled")
            self.assertFalse(argv_log.exists())
        self.assertEqual(completed.returncode, 2)
        self.assertIn("imagem de ops", completed.stderr)


if __name__ == "__main__":
    unittest.main()
