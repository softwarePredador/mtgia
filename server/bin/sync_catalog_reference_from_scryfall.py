#!/usr/bin/env python3
"""Atualiza o catálogo de referência a partir do bulk `default_cards` da Scryfall.

BT-CAT-01, decisões D-33 e D-34 do dono (2026-09-22).

Contrato de apply `catalog_reference_apply_v1`:
- grava só dado de referência (`cards`, `sets`, `card_legalities`, com os
  preços que moram em `cards`) e as linhas de auditoria em `sync_log` e
  `sync_state`. Nenhuma tabela de usuário, nenhum DDL, nenhum DELETE: o SQL
  abaixo só nomeia essas tabelas;
- toda escrita é upsert protegido por IS DISTINCT FROM, numa única transação
  sob advisory lock; uma segunda execução sobre a mesma fonte não muda nada;
- toda execução deixa receipt: um arquivo JSON, o mesmo JSON no stdout e uma
  linha em `sync_log` sempre que a execução chega ao banco com o contrato ativo.

Modos:
- `scheduled` (o daemon de ops): só aplica depois que uma execução
  supervisionada ativou o contrato em `sync_state`. Inativo, sai sem chamar a
  Scryfall e sem escrever no banco. Fonte já aplicada vira no-op que só
  registra a conferência.
- `activate` (supervisionado, exige MANALOOM_CONFIRM_POSTGRES_WRITES): aplica e
  registra a ativação na mesma transação. É a primeira execução real.
- `deactivate` (supervisionado): registra a pausa; o agendado para de aplicar.
- `dry-run`: transação só de leitura; conta o que faria e não grava nada.

Budget por execução: no máximo `--max-upstream-requests` requisições HTTP (uma
de metadados e um download, com retentativas limitadas), tamanho de download,
tempo de execução e número de cartas novas limitados. Estourar qualquer limite
desfaz a transação.

Fase 1 da D-35: as linhas que já estão no catálogo são atualizadas (as de
impressão exata em todos os campos e no preço; as linhas-alias Oracle só nas
legalidades), e entram as cartas novas e as impressões dos sets lançados desde
o último sync. Impressões antigas de cartas que já estão no catálogo são
contadas e puladas: levar a base ao grão de impressão e migrar as linhas-alias
Oracle é a fase 2.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import re
import socket
import ssl
import sys
import tempfile
import time
import uuid
import zlib
from collections import Counter
from dataclasses import asdict, dataclass, field
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any, Callable, Iterable, Iterator
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request, urlopen


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
DEFAULT_OUTPUT_DIR = (
    REPO_ROOT / "server/test/artifacts/catalog_reference_refresh_local"
)

JOB_NAME = "manaloom_catalog_reference_refresh"
APPLY_CONTRACT = "catalog_reference_apply_v1"
RECEIPT_VERSION = 1
BULK_METADATA_URL = "https://api.scryfall.com/bulk-data/default-cards"
BULK_TYPE = "default_cards"
BULK_DOWNLOAD_HOSTS = frozenset({"data.scryfall.io"})
USER_AGENT = "BrewTact/1.0 (catalog-reference-refresh)"
WRITE_APPROVAL_ENV = "MANALOOM_CONFIRM_POSTGRES_WRITES"
WRITE_APPROVAL_VALUE = "I_HAVE_EXPLICIT_APPROVAL"
RECEIPT_MARKER = "MANALOOM_CATALOG_REFERENCE_REFRESH"

# As únicas tabelas que o job pode gravar. O teste de contrato lê cada
# instrução SQL que o job envia e falha com qualquer outro alvo.
REFERENCE_TABLES = ("cards", "sets", "card_legalities")
AUDIT_TABLES = ("sync_log", "sync_state")
WRITABLE_TABLES = frozenset(REFERENCE_TABLES + AUDIT_TABLES)

MODES = ("scheduled", "activate", "deactivate", "dry-run")
INACTIVE_MARKER = "inactive"

STATE_ACTIVE_CONTRACT = "catalog_reference_apply_contract"
STATE_SOURCE_UPDATED_AT = "catalog_reference_source_updated_at"
STATE_SOURCE_SHA256 = "catalog_reference_source_sha256"
STATE_LAST_RUN_ID = "catalog_reference_last_run_id"
STATE_LAST_CHECKED_AT = "catalog_reference_last_checked_at"
STATE_CARDS_LAST_SYNC_AT = "cards_last_sync_at"
STATE_LEGALITIES_LAST_SYNC_AT = "card_legalities_last_sync_at"
STATE_PRICES_LAST_SYNC_AT = "prices_last_sync_at"
STATE_KEYS = (
    STATE_ACTIVE_CONTRACT,
    STATE_SOURCE_UPDATED_AT,
    STATE_SOURCE_SHA256,
    STATE_LAST_RUN_ID,
    STATE_LAST_CHECKED_AT,
    STATE_CARDS_LAST_SYNC_AT,
    STATE_LEGALITIES_LAST_SYNC_AT,
    STATE_PRICES_LAST_SYNC_AT,
)

SYNC_LOG_RUN = "catalog_reference"
SYNC_LOG_CARDS = "catalog_reference:cards"
SYNC_LOG_SETS = "catalog_reference:sets"
SYNC_LOG_LEGALITIES = "catalog_reference:card_legalities"
SYNC_LOG_CONTRACT = "catalog_reference:contract"

# Impressões que não são carta de jogo nunca entram no catálogo.
NON_GAME_LAYOUTS = frozenset({"token", "double_faced_token", "emblem", "art_series"})
LEGALITY_STATUSES = frozenset({"legal", "not_legal", "banned", "restricted"})
MAX_PRICE = Decimal("99999999.99")
UUID_PATTERN = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
)

# (coluna, tipo SQL, política de atualização). `fill` mantém o valor gravado e
# só preenche NULL; `present` usa o valor da fonte quando ela tem um;
# `source` sempre usa o valor da fonte (preços, mesmo ausentes); `cdn_image`
# usa a imagem direta do CDN daquela impressão.
CARD_COLUMNS: tuple[tuple[str, str, str], ...] = (
    ("scryfall_id", "uuid", "key"),
    ("oracle_id", "uuid", "fill"),
    ("name", "text", "fill"),
    ("mana_cost", "text", "present"),
    ("type_line", "text", "present"),
    ("oracle_text", "text", "present"),
    ("colors", "text[]", "present"),
    ("color_identity", "text[]", "present"),
    ("keywords", "text[]", "present"),
    ("power", "text", "present"),
    ("toughness", "text", "present"),
    ("cmc", "numeric", "present"),
    ("layout", "text", "present"),
    ("card_faces_json", "jsonb", "present"),
    ("image_url", "text", "cdn_image"),
    ("set_code", "text", "fill"),
    ("rarity", "text", "present"),
    ("collector_number", "text", "fill"),
    ("foil", "boolean", "present"),
    ("is_reserved", "boolean", "present"),
    ("price_usd", "numeric", "source"),
    ("price_usd_foil", "numeric", "source"),
    ("price", "numeric", "source"),
    ("price_source", "text", "source"),
    ("price_updated_at", "timestamptz", "source"),
)
CARD_COLUMN_NAMES = tuple(column for column, _, _ in CARD_COLUMNS)

REQUIRED_COLUMNS: dict[str, tuple[str, ...]] = {
    "cards": ("id",) + CARD_COLUMN_NAMES,
    "sets": ("code", "name", "release_date", "type", "updated_at"),
    "card_legalities": ("card_id", "format", "status"),
    "sync_state": ("key", "value", "updated_at"),
    "sync_log": (
        "sync_type",
        "format",
        "records_updated",
        "records_inserted",
        "records_deleted",
        "status",
        "error_message",
        "started_at",
        "finished_at",
    ),
}


# ─── Erros ───────────────────────────────────────────────────────────────────


class RefreshError(RuntimeError):
    """Execução que para. `kind` vai para o receipt."""

    exit_code = 1

    def __init__(self, kind: str, message: str) -> None:
        super().__init__(message)
        self.kind = kind


class ContractRefusal(RefreshError):
    """O pedido está fora do contrato de apply; nada foi tentado."""

    exit_code = 2


class BudgetExceeded(RefreshError):
    def __init__(self, limit: str, message: str) -> None:
        super().__init__(f"budget_exceeded:{limit}", message)


class UpstreamError(RefreshError):
    def __init__(self, kind: str, message: str, *, status: int | None = None) -> None:
        super().__init__(f"upstream_{kind}", message)
        self.status = status


# ─── Budget e contexto da execução ───────────────────────────────────────────


@dataclass(frozen=True)
class Budget:
    max_upstream_requests: int = 6
    max_download_bytes: int = 1536 * 1024 * 1024
    max_compressed_bytes: int = 512 * 1024 * 1024
    max_new_cards: int = 20000
    max_runtime_seconds: int = 3600
    timeout_seconds: float = 60.0
    max_attempts: int = 3
    max_retry_after_seconds: float = 60.0
    statement_timeout_seconds: int = 900
    new_set_margin_days: int = 7
    batch_size: int = 1000

    def to_json(self) -> dict[str, Any]:
        return asdict(self)


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _default_opener(request: Request, timeout: float) -> Any:
    return urlopen(request, timeout=timeout, context=_ssl_context())


def _ssl_context() -> ssl.SSLContext:
    try:
        import certifi  # type: ignore

        return ssl.create_default_context(cafile=certifi.where())
    except Exception:
        return ssl.create_default_context()


@dataclass
class RunContext:
    budget: Budget
    opener: Callable[[Request, float], Any] = _default_opener
    sleep: Callable[[float], None] = time.sleep
    clock: Callable[[], float] = time.monotonic
    now: Callable[[], datetime] = utc_now
    upstream_requests: int = 0
    upstream_log: list[dict[str, Any]] = field(default_factory=list)
    started: float = field(default=0.0)

    def start(self) -> None:
        self.started = self.clock()

    def check_runtime(self) -> None:
        if self.clock() - self.started > self.budget.max_runtime_seconds:
            raise BudgetExceeded(
                "runtime",
                f"execução passou de {self.budget.max_runtime_seconds} s",
            )


# ─── HTTP com a matriz 200/404/429/5xx/timeout ───────────────────────────────


def _retry_delay(headers: Any, attempt: int, budget: Budget) -> float:
    raw = None
    if headers is not None:
        try:
            raw = headers.get("Retry-After")
        except Exception:
            raw = None
    if raw is not None:
        try:
            return max(0.0, min(float(raw), budget.max_retry_after_seconds))
        except (TypeError, ValueError):
            pass
    return float(min(2 * attempt, 10))


def http_get(
    ctx: RunContext,
    url: str,
    *,
    accept: str,
    accept_encoding: str | None = None,
) -> Any:
    """Abre `url` e devolve a resposta de um 200.

    404 falha na hora; 429 e 5xx tentam de novo, respeitando o Retry-After até
    o teto; timeout e erro de conexão tentam de novo; qualquer outro status
    falha. Cada tentativa conta no budget de requisições externas.
    """
    last_error: UpstreamError | None = None
    for attempt in range(1, ctx.budget.max_attempts + 1):
        ctx.check_runtime()
        if ctx.upstream_requests >= ctx.budget.max_upstream_requests:
            raise BudgetExceeded(
                "upstream_requests",
                f"limite de {ctx.budget.max_upstream_requests} requisições atingido",
            )
        ctx.upstream_requests += 1
        headers = {"User-Agent": USER_AGENT, "Accept": accept}
        if accept_encoding:
            headers["Accept-Encoding"] = accept_encoding
        request = Request(url, headers=headers)
        entry: dict[str, Any] = {"url": url, "attempt": attempt}
        ctx.upstream_log.append(entry)
        retry_after_headers = None
        try:
            response = ctx.opener(request, ctx.budget.timeout_seconds)
        except HTTPError as exc:
            entry["status"] = exc.code
            if exc.code == 404:
                raise UpstreamError(
                    "not_found", f"{url} respondeu 404", status=404
                ) from exc
            if exc.code == 429 or exc.code >= 500:
                last_error = UpstreamError(
                    "retries_exhausted",
                    f"{url} respondeu {exc.code} em {attempt} tentativa(s)",
                    status=exc.code,
                )
                retry_after_headers = exc.headers
            else:
                raise UpstreamError(
                    "http_status", f"{url} respondeu {exc.code}", status=exc.code
                ) from exc
        except (TimeoutError, socket.timeout) as exc:
            entry["status"] = "timeout"
            last_error = UpstreamError(
                "retries_exhausted",
                f"{url}: tempo esgotado em {attempt} tentativa(s) ({exc})",
            )
        except URLError as exc:
            entry["status"] = "connection_error"
            last_error = UpstreamError(
                "retries_exhausted",
                f"{url}: falha de conexão em {attempt} tentativa(s) ({exc.reason})",
            )
        else:
            status = getattr(response, "status", None)
            if status is None:
                status = response.getcode()
            entry["status"] = status
            if status == 200:
                return response
            response.close()
            raise UpstreamError(
                "http_status", f"{url} respondeu {status}", status=status
            )
        if attempt < ctx.budget.max_attempts:
            ctx.sleep(_retry_delay(retry_after_headers, attempt, ctx.budget))
    assert last_error is not None
    raise last_error


# ─── Metadados e download do bulk ────────────────────────────────────────────


@dataclass(frozen=True)
class BulkSource:
    kind: str
    updated_at: str
    bulk_id: str | None = None
    download_uri: str | None = None
    declared_size: int | None = None

    def to_json(self) -> dict[str, Any]:
        return asdict(self)


def parse_timestamp(value: Any) -> datetime:
    text = str(value or "").strip()
    if not text:
        raise ValueError("timestamp vazio")
    parsed = datetime.fromisoformat(text.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def parse_bulk_metadata(payload: Any, budget: Budget) -> BulkSource:
    if not isinstance(payload, dict):
        raise RefreshError("invalid_metadata", "metadados do bulk não são um objeto")
    if payload.get("object") != "bulk_data" or payload.get("type") != BULK_TYPE:
        raise RefreshError(
            "invalid_metadata",
            f"metadados não são do bulk {BULK_TYPE}: "
            f"object={payload.get('object')!r} type={payload.get('type')!r}",
        )
    download_uri = str(payload.get("download_uri") or "").strip()
    parsed = urlparse(download_uri)
    if parsed.scheme != "https" or parsed.hostname not in BULK_DOWNLOAD_HOSTS:
        raise RefreshError(
            "unexpected_download_host",
            f"download_uri fora de {sorted(BULK_DOWNLOAD_HOSTS)}: {download_uri!r}",
        )
    try:
        updated_at = parse_timestamp(payload.get("updated_at"))
    except ValueError as exc:
        raise RefreshError("invalid_metadata", f"updated_at inválido: {exc}") from exc
    size = payload.get("size")
    declared_size = size if isinstance(size, int) and size >= 0 else None
    if declared_size is not None and declared_size > budget.max_download_bytes:
        raise BudgetExceeded(
            "download_bytes",
            f"o bulk declara {declared_size} bytes, acima de {budget.max_download_bytes}",
        )
    return BulkSource(
        kind="scryfall_bulk",
        updated_at=updated_at.isoformat(),
        bulk_id=str(payload.get("id") or "") or None,
        download_uri=download_uri,
        declared_size=declared_size,
    )


def fetch_bulk_metadata(ctx: RunContext) -> BulkSource:
    response = http_get(ctx, BULK_METADATA_URL, accept="application/json")
    with response:
        raw = response.read(1024 * 1024 + 1)
    if len(raw) > 1024 * 1024:
        raise RefreshError("invalid_metadata", "metadados do bulk maiores que 1 MiB")
    try:
        payload = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise RefreshError("invalid_metadata", f"metadados ilegíveis: {exc}") from exc
    return parse_bulk_metadata(payload, ctx.budget)


@dataclass(frozen=True)
class DownloadedBulk:
    path: Path
    compressed_bytes: int
    bytes: int
    sha256: str


def download_bulk(ctx: RunContext, source: BulkSource, work_dir: Path) -> DownloadedBulk:
    assert source.download_uri is not None
    response = http_get(
        ctx,
        source.download_uri,
        accept="application/json",
        accept_encoding="gzip",
    )
    encoding = ""
    try:
        encoding = str(response.headers.get("Content-Encoding") or "").lower()
    except Exception:
        encoding = ""
    decompressor = zlib.decompressobj(16 + zlib.MAX_WBITS) if encoding == "gzip" else None
    digest = hashlib.sha256()
    work_dir.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(
        prefix="catalog_reference_default_cards_", suffix=".json", dir=work_dir
    )
    path = Path(name)
    compressed = 0
    written = 0

    def emit(data: bytes, out: Any) -> None:
        nonlocal written
        if not data:
            return
        written += len(data)
        if written > ctx.budget.max_download_bytes:
            raise BudgetExceeded(
                "download_bytes",
                f"download passou de {ctx.budget.max_download_bytes} bytes",
            )
        digest.update(data)
        out.write(data)

    try:
        with os.fdopen(fd, "wb") as out, response:
            while True:
                ctx.check_runtime()
                try:
                    chunk = response.read(64 * 1024)
                except (TimeoutError, socket.timeout, OSError) as exc:
                    raise UpstreamError(
                        "download_interrupted", f"download interrompido: {exc}"
                    ) from exc
                if not chunk:
                    break
                compressed += len(chunk)
                if compressed > ctx.budget.max_compressed_bytes:
                    raise BudgetExceeded(
                        "compressed_bytes",
                        f"download passou de {ctx.budget.max_compressed_bytes} bytes",
                    )
                if decompressor is None:
                    emit(chunk, out)
                else:
                    try:
                        emit(decompressor.decompress(chunk), out)
                    except zlib.error as exc:
                        raise UpstreamError(
                            "download_corrupt", f"gzip inválido: {exc}"
                        ) from exc
            if decompressor is not None:
                emit(decompressor.flush(), out)
                if not decompressor.eof:
                    raise UpstreamError("download_truncated", "gzip terminou no meio")
    except BaseException:
        path.unlink(missing_ok=True)
        raise
    return DownloadedBulk(path=path, compressed_bytes=compressed, bytes=written, sha256=digest.hexdigest())


def sha256_file(path: Path) -> tuple[int, str]:
    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as source:
        while chunk := source.read(1024 * 1024):
            size += len(chunk)
            digest.update(chunk)
    return size, digest.hexdigest()


# ─── Leitura em fluxo da lista do bulk ───────────────────────────────────────


def iter_bulk_objects(path: Path) -> Iterator[Any]:
    """Entrega cada elemento da lista JSON sem carregar o arquivo inteiro."""
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
                        raise RefreshError(
                            "invalid_bulk", "o bulk precisa ser uma lista JSON"
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
                        raise RefreshError(
                            "invalid_bulk", "o bulk terminou no meio de um objeto"
                        )
                    break
                offset = next_offset
                yield value
            if offset:
                buffer = buffer[offset:]
                offset = 0
            if reached_eof:
                if not started:
                    raise RefreshError("invalid_bulk", "o bulk está vazio")
                raise RefreshError("invalid_bulk", "o bulk não fecha a lista")


# ─── Normalização de uma impressão ───────────────────────────────────────────


def normalized_uuid(value: Any) -> str | None:
    candidate = str(value or "").strip().lower()
    if not UUID_PATTERN.fullmatch(candidate):
        return None
    try:
        return str(uuid.UUID(candidate))
    except ValueError:
        return None


def _text(value: Any) -> str | None:
    return value if isinstance(value, str) else None


def _text_list(value: Any) -> list[str] | None:
    if not isinstance(value, list):
        return None
    return [item for item in value if isinstance(item, str)]


def parse_price(value: Any) -> Decimal | None:
    if value is None:
        return None
    try:
        price = Decimal(str(value))
    except (InvalidOperation, ValueError):
        return None
    if not price.is_finite() or price < 0 or price > MAX_PRICE:
        return None
    return price.quantize(Decimal("0.01"))


def parse_cmc(value: Any) -> Decimal | None:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    number = float(value)
    if not math.isfinite(number) or number < 0 or number >= 1000:
        return None
    return Decimal(str(value)).quantize(Decimal("0.1"))


def printing_image_url(raw: dict[str, Any], printing_id: str) -> str:
    """Imagem direta do CDN desta impressão; nunca derivada de um oracle_id."""
    candidates: list[Any] = []
    image_uris = raw.get("image_uris")
    if isinstance(image_uris, dict):
        candidates.append(image_uris.get("normal"))
    faces = raw.get("card_faces")
    if isinstance(faces, list):
        for face in faces:
            if isinstance(face, dict) and isinstance(face.get("image_uris"), dict):
                candidates.append(face["image_uris"].get("normal"))
    for candidate in candidates:
        value = str(candidate or "").strip()
        parsed = urlparse(value)
        if (
            parsed.scheme == "https"
            and parsed.hostname == "cards.scryfall.io"
            and parsed.path.startswith("/normal/")
            and parsed.path.lower().endswith(f"/{printing_id}.jpg")
        ):
            return value
    return (
        "https://cards.scryfall.io/normal/front/"
        f"{printing_id[0]}/{printing_id[1]}/{printing_id}.jpg"
    )


@dataclass(frozen=True)
class BulkPrinting:
    scryfall_id: str
    oracle_id: str | None
    name: str
    mana_cost: str | None
    type_line: str | None
    oracle_text: str | None
    colors: list[str] | None
    color_identity: list[str] | None
    keywords: list[str] | None
    power: str | None
    toughness: str | None
    cmc: Decimal | None
    layout: str | None
    card_faces_json: str | None
    image_url: str
    set_code: str | None
    set_name: str | None
    set_type: str | None
    released_at: date | None
    rarity: str | None
    collector_number: str | None
    foil: bool | None
    is_reserved: bool | None
    price_usd: Decimal | None
    price_usd_foil: Decimal | None
    legalities: tuple[tuple[str, str], ...]
    insertable: bool

    def card_row(self, *, price_updated_at: datetime, for_insert: bool) -> tuple[Any, ...]:
        is_reserved = self.is_reserved
        if for_insert and is_reserved is None:
            is_reserved = False
        return (
            self.scryfall_id,
            self.oracle_id,
            self.name,
            self.mana_cost,
            self.type_line,
            self.oracle_text,
            self.colors,
            self.color_identity,
            self.keywords,
            self.power,
            self.toughness,
            self.cmc,
            self.layout,
            self.card_faces_json,
            self.image_url,
            self.set_code,
            self.rarity,
            self.collector_number,
            self.foil,
            is_reserved,
            self.price_usd,
            self.price_usd_foil,
            self.price_usd,
            "scryfall",
            price_updated_at,
        )


def normalize_printing(raw: Any) -> BulkPrinting | None:
    if not isinstance(raw, dict) or raw.get("object") not in (None, "card"):
        return None
    scryfall_id = normalized_uuid(raw.get("id"))
    name = _text(raw.get("name"))
    if scryfall_id is None or not name or not name.strip():
        return None
    oracle_id = normalized_uuid(raw.get("oracle_id"))
    faces = raw.get("card_faces")
    if oracle_id is None and isinstance(faces, list):
        for face in faces:
            if isinstance(face, dict):
                oracle_id = normalized_uuid(face.get("oracle_id"))
                if oracle_id:
                    break
    finishes = raw.get("finishes")
    if isinstance(finishes, list):
        foil: bool | None = "foil" in finishes
    else:
        foil = raw.get("foil") if isinstance(raw.get("foil"), bool) else None
    legalities_raw = raw.get("legalities")
    legalities: list[tuple[str, str]] = []
    if isinstance(legalities_raw, dict):
        for fmt, status in legalities_raw.items():
            if not isinstance(fmt, str) or not isinstance(status, str):
                continue
            status = status.strip().lower()
            fmt = fmt.strip().lower()
            if fmt and status in LEGALITY_STATUSES:
                legalities.append((sys.intern(fmt), sys.intern(status)))
    released_at: date | None = None
    if isinstance(raw.get("released_at"), str):
        try:
            released_at = date.fromisoformat(raw["released_at"])
        except ValueError:
            released_at = None
    set_code = (_text(raw.get("set")) or "").strip().upper() or None
    games = raw.get("games") if isinstance(raw.get("games"), list) else []
    layout = _text(raw.get("layout"))
    prices = raw.get("prices") if isinstance(raw.get("prices"), dict) else {}
    insertable = (
        oracle_id is not None
        and "paper" in games
        and raw.get("digital") is not True
        and raw.get("oversized") is not True
        and (layout or "") not in NON_GAME_LAYOUTS
    )
    return BulkPrinting(
        scryfall_id=scryfall_id,
        oracle_id=oracle_id,
        name=name.strip(),
        mana_cost=_text(raw.get("mana_cost")),
        type_line=_text(raw.get("type_line")),
        oracle_text=_text(raw.get("oracle_text")),
        colors=_text_list(raw.get("colors")),
        color_identity=_text_list(raw.get("color_identity")),
        keywords=_text_list(raw.get("keywords")),
        power=_text(raw.get("power")),
        toughness=_text(raw.get("toughness")),
        cmc=parse_cmc(raw.get("cmc")),
        layout=layout,
        card_faces_json=(
            json.dumps(faces, ensure_ascii=False, sort_keys=True)
            if isinstance(faces, list) and faces
            else None
        ),
        image_url=printing_image_url(raw, scryfall_id),
        set_code=set_code,
        set_name=_text(raw.get("set_name")),
        set_type=_text(raw.get("set_type")),
        released_at=released_at,
        rarity=(_text(raw.get("rarity")) or "").strip().lower() or None,
        collector_number=_text(raw.get("collector_number")),
        foil=foil,
        is_reserved=raw.get("reserved") if isinstance(raw.get("reserved"), bool) else None,
        price_usd=parse_price(prices.get("usd")),
        price_usd_foil=parse_price(prices.get("usd_foil")),
        legalities=tuple(sorted(legalities)),
        insertable=insertable,
    )


# ─── Retrato do catálogo e o plano ───────────────────────────────────────────


@dataclass
class CatalogSnapshot:
    scryfall_ids: set[str]
    oracle_ids: set[str]
    alias_rows: int
    set_codes: set[str]
    state: dict[str, str]


def new_set_cutoff(state: dict[str, str], margin_days: int) -> date | None:
    raw = state.get(STATE_CARDS_LAST_SYNC_AT)
    if not raw:
        return None
    try:
        checkpoint = parse_timestamp(raw)
    except ValueError:
        return None
    return checkpoint.date() - timedelta(days=margin_days)


@dataclass
class RefreshPlan:
    updates: list[tuple[Any, ...]] = field(default_factory=list)
    inserts: list[tuple[Any, ...]] = field(default_factory=list)
    legalities: dict[str, tuple[tuple[str, str], ...]] = field(default_factory=dict)
    sets: dict[str, tuple[str, str, date | None, str | None]] = field(default_factory=dict)
    counts: Counter = field(default_factory=Counter)


def plan_refresh(
    raw_objects: Iterable[Any],
    snapshot: CatalogSnapshot,
    *,
    price_updated_at: datetime,
    cutoff: date | None,
    ctx: RunContext,
) -> RefreshPlan:
    plan = RefreshPlan()
    counts = plan.counts
    legalities_seen: dict[str, tuple[tuple[str, str], ...]] = {}
    inserted_oracle_ids: set[str] = set()
    for index, raw in enumerate(raw_objects):
        if index % 5000 == 0:
            ctx.check_runtime()
        counts["bulk_objects"] += 1
        printing = normalize_printing(raw)
        if printing is None:
            counts["skipped_invalid_object"] += 1
            continue
        if printing.oracle_id and printing.legalities:
            legalities_seen.setdefault(printing.oracle_id, printing.legalities)
        if printing.scryfall_id in snapshot.scryfall_ids:
            plan.updates.append(
                printing.card_row(price_updated_at=price_updated_at, for_insert=False)
            )
            counts["refresh_candidates"] += 1
            _note_set(plan, printing)
            continue
        if not printing.insertable:
            counts[
                "skipped_missing_oracle_id"
                if printing.oracle_id is None
                else "skipped_not_a_paper_game_card"
            ] += 1
            continue
        assert printing.oracle_id is not None
        if printing.oracle_id not in snapshot.oracle_ids:
            reason = "insert_new_card"
        elif (
            cutoff is not None
            and printing.released_at is not None
            and printing.released_at >= cutoff
        ):
            reason = "insert_recent_set_printing"
        else:
            counts["skipped_older_printing_phase2"] += 1
            continue
        plan.inserts.append(
            printing.card_row(price_updated_at=price_updated_at, for_insert=True)
        )
        inserted_oracle_ids.add(printing.oracle_id)
        counts[reason] += 1
        _note_set(plan, printing)
        if len(plan.inserts) > ctx.budget.max_new_cards:
            raise BudgetExceeded(
                "new_cards",
                f"mais de {ctx.budget.max_new_cards} cartas novas numa execução",
            )
    for oracle_id, legalities in legalities_seen.items():
        if oracle_id in snapshot.oracle_ids or oracle_id in inserted_oracle_ids:
            plan.legalities[oracle_id] = legalities
    plan.sets = {
        code: row
        for code, row in plan.sets.items()
        if code.lower() not in snapshot.set_codes
    }
    return plan


def _note_set(plan: RefreshPlan, printing: BulkPrinting) -> None:
    code = printing.set_code
    if not code:
        return
    current = plan.sets.get(code)
    release = printing.released_at
    if current is None:
        plan.sets[code] = (code, printing.set_name or code, release, printing.set_type)
        return
    if release is not None and (current[2] is None or release < current[2]):
        plan.sets[code] = (current[0], current[1], release, current[3])


# ─── SQL (as únicas instruções que gravam) ───────────────────────────────────


def _card_template() -> str:
    return "(" + ", ".join(f"%s::{sql_type}" for _, sql_type, _ in CARD_COLUMNS) + ")"


def _merge_expression(column: str, policy: str) -> str:
    if policy == "fill":
        return f"COALESCE(c.{column}, v.{column})"
    if policy == "present":
        return f"COALESCE(v.{column}, c.{column})"
    if policy == "source":
        return f"v.{column}"
    if policy == "cdn_image":
        return (
            "CASE WHEN v.image_url LIKE 'https://cards.scryfall.io/%%' "
            "THEN v.image_url ELSE COALESCE(c.image_url, v.image_url) END"
        )
    raise ValueError(policy)


_UPDATABLE = tuple(
    (column, _merge_expression(column, policy))
    for column, _, policy in CARD_COLUMNS
    if policy != "key"
)

UPDATE_CARDS_SQL = (
    "UPDATE cards AS c SET "
    + ", ".join(f"{column} = {expression}" for column, expression in _UPDATABLE)
    + " FROM (VALUES %s) AS v("
    + ", ".join(CARD_COLUMN_NAMES)
    + ") WHERE c.scryfall_id = v.scryfall_id AND ("
    + ", ".join(f"c.{column}" for column, _ in _UPDATABLE)
    + ") IS DISTINCT FROM ("
    + ", ".join(expression for _, expression in _UPDATABLE)
    + ") RETURNING c.id::text"
)

INSERT_CARDS_SQL = (
    "INSERT INTO cards ("
    + ", ".join(CARD_COLUMN_NAMES)
    + ") VALUES %s ON CONFLICT (scryfall_id) DO NOTHING RETURNING id::text"
)

INSERT_SETS_SQL = (
    "INSERT INTO sets (code, name, release_date, type, updated_at) "
    "SELECT v.code, v.name, v.release_date, v.type, CURRENT_TIMESTAMP "
    "FROM (VALUES %s) AS v(code, name, release_date, type) "
    "WHERE NOT EXISTS (SELECT 1 FROM sets s WHERE LOWER(s.code) = LOWER(v.code)) "
    "ON CONFLICT (code) DO NOTHING RETURNING code"
)
SETS_TEMPLATE = "(%s::text, %s::text, %s::date, %s::text)"

UPSERT_LEGALITIES_SQL = (
    "INSERT INTO card_legalities (card_id, format, status) "
    "SELECT c.id, v.format, v.status "
    "FROM (VALUES %s) AS v(oracle_id, format, status) "
    "JOIN cards c ON c.oracle_id = v.oracle_id "
    "ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status "
    "WHERE card_legalities.status IS DISTINCT FROM EXCLUDED.status "
    "RETURNING (xmax = 0) AS inserted"
)
LEGALITIES_TEMPLATE = "(%s::uuid, %s::text, %s::text)"

UPSERT_STATE_SQL = (
    "INSERT INTO sync_state (key, value, updated_at) VALUES %s "
    "ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, "
    "updated_at = EXCLUDED.updated_at"
)
STATE_TEMPLATE = "(%s::text, %s::text, CURRENT_TIMESTAMP)"

INSERT_SYNC_LOG_SQL = (
    "INSERT INTO sync_log (sync_type, format, records_inserted, records_updated, "
    "records_deleted, status, error_message, started_at, finished_at) "
    "VALUES (%s, NULL, %s, %s, 0, %s, %s, %s, %s)"
)

WRITE_STATEMENTS = (
    UPDATE_CARDS_SQL,
    INSERT_CARDS_SQL,
    INSERT_SETS_SQL,
    UPSERT_LEGALITIES_SQL,
    UPSERT_STATE_SQL,
    INSERT_SYNC_LOG_SQL,
)


def _execute_values(cur: Any, sql: str, rows: list[tuple[Any, ...]], template: str, page_size: int) -> list[tuple[Any, ...]]:
    from psycopg2.extras import execute_values  # type: ignore

    return execute_values(cur, sql, rows, template=template, page_size=page_size, fetch=True)


def _chunks(rows: list[Any], size: int) -> Iterator[list[Any]]:
    for index in range(0, len(rows), size):
        yield rows[index : index + size]


def apply_plan(cur: Any, plan: RefreshPlan, ctx: RunContext) -> dict[str, dict[str, int]]:
    batch = ctx.budget.batch_size
    sets_inserted = 0
    set_rows = sorted(plan.sets.values(), key=lambda row: row[0])
    for chunk in _chunks(set_rows, batch):
        ctx.check_runtime()
        sets_inserted += len(_execute_values(cur, INSERT_SETS_SQL, chunk, SETS_TEMPLATE, batch))

    template = _card_template()
    cards_updated = 0
    for chunk in _chunks(plan.updates, batch):
        ctx.check_runtime()
        cards_updated += len(_execute_values(cur, UPDATE_CARDS_SQL, chunk, template, batch))
    cards_inserted = 0
    for chunk in _chunks(plan.inserts, batch):
        ctx.check_runtime()
        cards_inserted += len(_execute_values(cur, INSERT_CARDS_SQL, chunk, template, batch))

    legality_rows = [
        (oracle_id, fmt, status)
        for oracle_id in sorted(plan.legalities)
        for fmt, status in plan.legalities[oracle_id]
    ]
    legalities_inserted = 0
    legalities_updated = 0
    legality_page = max(batch * 10, 1)
    for chunk in _chunks(legality_rows, legality_page):
        ctx.check_runtime()
        for (inserted,) in _execute_values(cur, UPSERT_LEGALITIES_SQL, chunk, LEGALITIES_TEMPLATE, legality_page):
            if inserted:
                legalities_inserted += 1
            else:
                legalities_updated += 1

    return {
        "cards": {
            "refresh_candidates": len(plan.updates),
            "updated": cards_updated,
            "unchanged": len(plan.updates) - cards_updated,
            "insert_candidates": len(plan.inserts),
            "inserted": cards_inserted,
        },
        "sets": {"insert_candidates": len(set_rows), "inserted": sets_inserted},
        "card_legalities": {
            "oracle_ids": len(plan.legalities),
            "rows_sent": len(legality_rows),
            "inserted": legalities_inserted,
            "updated": legalities_updated,
        },
    }


def write_state(cur: Any, values: dict[str, str], batch: int) -> None:
    rows = sorted(values.items())
    _execute_values_no_fetch(cur, UPSERT_STATE_SQL, rows, STATE_TEMPLATE, batch)


def _execute_values_no_fetch(cur: Any, sql: str, rows: list[tuple[Any, ...]], template: str, page_size: int) -> None:
    from psycopg2.extras import execute_values  # type: ignore

    execute_values(cur, sql, rows, template=template, page_size=page_size)


def insert_sync_log(
    cur: Any,
    *,
    sync_type: str,
    inserted: int,
    updated: int,
    status: str,
    error_message: str | None,
    started_at: datetime,
    finished_at: datetime,
) -> None:
    cur.execute(
        INSERT_SYNC_LOG_SQL,
        (sync_type, inserted, updated, status, error_message, started_at, finished_at),
    )


# ─── Acesso ao banco (leitura) ───────────────────────────────────────────────


def load_env_file(path: Path, environment: dict[str, str]) -> None:
    if not path.exists():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        environment.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def connect(environment: dict[str, str]) -> Any:
    import psycopg2  # type: ignore

    common = {"connect_timeout": 10, "application_name": JOB_NAME}
    database_url = environment.get("DATABASE_URL")
    if database_url:
        return psycopg2.connect(database_url, **common)
    required = ["DB_HOST", "DB_NAME", "DB_USER"]
    missing = [name for name in required if not environment.get(name)]
    if missing:
        raise ContractRefusal(
            "database_config_missing", "configuração ausente: " + ", ".join(missing)
        )
    return psycopg2.connect(
        host=environment["DB_HOST"],
        port=environment.get("DB_PORT", "5432"),
        dbname=environment["DB_NAME"],
        user=environment["DB_USER"],
        password=environment.get("DB_PASS", ""),
        **common,
    )


def preflight(cur: Any) -> None:
    cur.execute(
        "SELECT table_name, column_name FROM information_schema.columns "
        "WHERE table_schema = 'public' AND table_name = ANY(%s)",
        (sorted(REQUIRED_COLUMNS),),
    )
    present: dict[str, set[str]] = {}
    for table, column in cur.fetchall():
        present.setdefault(table, set()).add(column)
    missing = [
        f"{table}.{column}"
        for table, columns in sorted(REQUIRED_COLUMNS.items())
        for column in columns
        if column not in present.get(table, set())
    ]
    if missing:
        raise ContractRefusal(
            "schema_mismatch",
            "o job não cria schema; faltam: " + ", ".join(missing),
        )


def read_state(cur: Any) -> dict[str, str]:
    cur.execute(
        "SELECT key, value FROM sync_state WHERE key = ANY(%s)", (list(STATE_KEYS),)
    )
    return {str(key): str(value) for key, value in cur.fetchall() if value is not None}


def load_snapshot(cur: Any, state: dict[str, str]) -> CatalogSnapshot:
    cur.execute("SELECT scryfall_id::text, oracle_id::text FROM cards")
    scryfall_ids: set[str] = set()
    oracle_ids: set[str] = set()
    alias_rows = 0
    for scryfall_id, oracle_id in cur.fetchall():
        if scryfall_id:
            scryfall_ids.add(str(scryfall_id))
        if oracle_id:
            oracle_ids.add(str(oracle_id))
        if scryfall_id and oracle_id and scryfall_id == oracle_id:
            alias_rows += 1
    cur.execute("SELECT LOWER(code) FROM sets")
    set_codes = {str(row[0]) for row in cur.fetchall() if row[0]}
    return CatalogSnapshot(
        scryfall_ids=scryfall_ids,
        oracle_ids=oracle_ids,
        alias_rows=alias_rows,
        set_codes=set_codes,
        state=state,
    )


# ─── A execução ──────────────────────────────────────────────────────────────


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    defaults = Budget()
    parser = argparse.ArgumentParser(
        description=(
            "Atualiza o catálogo de referência (cartas, sets, legalidades, preços) "
            "a partir do bulk default_cards da Scryfall, sob o contrato "
            f"{APPLY_CONTRACT}."
        )
    )
    parser.add_argument("--mode", choices=MODES, default="scheduled")
    parser.add_argument("--bulk-json", type=Path, help="bulk local; não chama a rede")
    parser.add_argument("--source-updated-at", help="updated_at do bulk local (ISO 8601)")
    parser.add_argument("--force", action="store_true", help="reaplica a mesma fonte")
    parser.add_argument("--output-dir", default=os.environ.get("MANALOOM_CATALOG_REFERENCE_OUTPUT_DIR"))
    parser.add_argument(
        "--env-file",
        default=os.environ.get("MTGIA_ENV_FILE", str(REPO_ROOT / "server/.env")),
    )
    parser.add_argument("--work-dir", type=Path)
    parser.add_argument("--max-upstream-requests", type=int, default=defaults.max_upstream_requests)
    parser.add_argument("--max-download-bytes", type=int, default=defaults.max_download_bytes)
    parser.add_argument("--max-compressed-bytes", type=int, default=defaults.max_compressed_bytes)
    parser.add_argument("--max-new-cards", type=int, default=defaults.max_new_cards)
    parser.add_argument("--max-runtime-seconds", type=int, default=defaults.max_runtime_seconds)
    parser.add_argument("--timeout-seconds", type=float, default=defaults.timeout_seconds)
    parser.add_argument("--max-attempts", type=int, default=defaults.max_attempts)
    parser.add_argument("--statement-timeout-seconds", type=int, default=defaults.statement_timeout_seconds)
    parser.add_argument("--new-set-margin-days", type=int, default=defaults.new_set_margin_days)
    parser.add_argument("--batch-size", type=int, default=defaults.batch_size)
    args = parser.parse_args(argv)
    positives = (
        "max_upstream_requests",
        "max_download_bytes",
        "max_compressed_bytes",
        "max_runtime_seconds",
        "max_attempts",
        "statement_timeout_seconds",
        "batch_size",
    )
    for name in positives:
        if getattr(args, name) <= 0:
            parser.error(f"--{name.replace('_', '-')} precisa ser positivo")
    if args.max_new_cards < 0 or args.new_set_margin_days < 0 or args.timeout_seconds <= 0:
        parser.error("limites negativos não são aceitos")
    if args.bulk_json is not None and not args.source_updated_at:
        parser.error("--bulk-json exige --source-updated-at")
    return args


def budget_from_args(args: argparse.Namespace) -> Budget:
    return Budget(
        max_upstream_requests=args.max_upstream_requests,
        max_download_bytes=args.max_download_bytes,
        max_compressed_bytes=args.max_compressed_bytes,
        max_new_cards=args.max_new_cards,
        max_runtime_seconds=args.max_runtime_seconds,
        timeout_seconds=args.timeout_seconds,
        max_attempts=args.max_attempts,
        statement_timeout_seconds=args.statement_timeout_seconds,
        new_set_margin_days=args.new_set_margin_days,
        batch_size=args.batch_size,
    )


def _iso(value: datetime) -> str:
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def run(
    args: argparse.Namespace,
    *,
    environment: dict[str, str] | None = None,
    ctx: RunContext | None = None,
    connect_fn: Callable[[dict[str, str]], Any] = connect,
) -> tuple[int, dict[str, Any]]:
    environment = dict(os.environ if environment is None else environment)
    ctx = ctx or RunContext(budget=budget_from_args(args))
    ctx.start()
    started_at = ctx.now()
    run_id = f"catalog_reference_{started_at:%Y%m%dT%H%M%SZ}_{os.getpid()}"
    receipt: dict[str, Any] = {
        "receipt_version": RECEIPT_VERSION,
        "job": JOB_NAME,
        "apply_contract": APPLY_CONTRACT,
        "run_id": run_id,
        "mode": args.mode,
        "status": "started",
        "started_at": _iso(started_at),
        "finished_at": None,
        "git_sha": environment.get("GIT_SHA"),
        "writable_tables": sorted(WRITABLE_TABLES),
        "source": None,
        "upstream_requests": 0,
        "upstream_log": ctx.upstream_log,
        "budget": ctx.budget.to_json(),
        "counts": {},
        "database_writes": False,
        "error": None,
    }
    exit_code = 0
    conn = None
    downloaded: DownloadedBulk | None = None
    try:
        if args.mode in ("activate", "deactivate") and (
            environment.get(WRITE_APPROVAL_ENV) != WRITE_APPROVAL_VALUE
        ):
            raise ContractRefusal(
                "approval_missing",
                f"--mode {args.mode} é supervisionado: exporte "
                f"{WRITE_APPROVAL_ENV}={WRITE_APPROVAL_VALUE}",
            )
        load_env_file(Path(args.env_file), environment)
        conn = connect_fn(environment)
        with conn.cursor() as cur:
            preflight(cur)
            state = read_state(cur)
        conn.rollback()

        if args.mode == "deactivate":
            with conn.cursor() as cur:
                write_state(cur, {STATE_ACTIVE_CONTRACT: INACTIVE_MARKER}, ctx.budget.batch_size)
                insert_sync_log(
                    cur,
                    sync_type=SYNC_LOG_CONTRACT,
                    inserted=0,
                    updated=0,
                    status="deactivated",
                    error_message=None,
                    started_at=started_at,
                    finished_at=ctx.now(),
                )
            conn.commit()
            receipt["database_writes"] = True
            receipt["status"] = "deactivated"
            return exit_code, receipt

        if args.mode == "scheduled" and state.get(STATE_ACTIVE_CONTRACT) != APPLY_CONTRACT:
            receipt["status"] = "contract_inactive"
            receipt["counts"] = {"active_contract": state.get(STATE_ACTIVE_CONTRACT)}
            return exit_code, receipt

        if args.bulk_json is not None:
            try:
                updated_at = parse_timestamp(args.source_updated_at)
            except ValueError as exc:
                raise ContractRefusal("invalid_source", f"--source-updated-at inválido: {exc}") from exc
            source = BulkSource(kind="local_file", updated_at=updated_at.isoformat())
        else:
            source = fetch_bulk_metadata(ctx)
        receipt["source"] = source.to_json()

        if (
            args.mode == "scheduled"
            and not args.force
            and state.get(STATE_SOURCE_UPDATED_AT) == source.updated_at
        ):
            with conn.cursor() as cur:
                write_state(cur, {STATE_LAST_CHECKED_AT: _iso(ctx.now())}, ctx.budget.batch_size)
                insert_sync_log(
                    cur,
                    sync_type=SYNC_LOG_RUN,
                    inserted=0,
                    updated=0,
                    status="skipped",
                    error_message="noop_same_source",
                    started_at=started_at,
                    finished_at=ctx.now(),
                )
            conn.commit()
            receipt["database_writes"] = True
            receipt["status"] = "noop_same_source"
            return exit_code, receipt

        if args.bulk_json is not None:
            bulk_path = Path(args.bulk_json)
            size, digest = sha256_file(bulk_path)
            receipt["source"].update({"bytes": size, "sha256": digest, "path": str(bulk_path)})
            source_sha256 = digest
        else:
            work_dir = args.work_dir or Path(tempfile.gettempdir())
            downloaded = download_bulk(ctx, source, work_dir)
            bulk_path = downloaded.path
            receipt["source"].update(
                {
                    "compressed_bytes": downloaded.compressed_bytes,
                    "bytes": downloaded.bytes,
                    "sha256": downloaded.sha256,
                }
            )
            source_sha256 = downloaded.sha256
        receipt["upstream_requests"] = ctx.upstream_requests

        price_updated_at = parse_timestamp(source.updated_at)
        if args.mode == "dry-run":
            conn.set_session(readonly=True)
        with conn.cursor() as cur:
            cur.execute("SET LOCAL lock_timeout = '30s'")
            cur.execute(
                "SELECT set_config('statement_timeout', %s, true)",
                (f"{ctx.budget.statement_timeout_seconds}s",),
            )
            if args.mode != "dry-run":
                cur.execute(
                    "SELECT pg_try_advisory_xact_lock(hashtext(%s))", (JOB_NAME,)
                )
                if not cur.fetchone()[0]:
                    raise RefreshError("locked", "outra execução segura a trava do job")
            snapshot = load_snapshot(cur, read_state(cur))
            cutoff = new_set_cutoff(snapshot.state, ctx.budget.new_set_margin_days)
            plan = plan_refresh(
                iter_bulk_objects(bulk_path),
                snapshot,
                price_updated_at=price_updated_at,
                cutoff=cutoff,
                ctx=ctx,
            )
            counts: dict[str, Any] = {
                "bulk": dict(sorted(plan.counts.items())),
                "catalog_before": {
                    "rows": len(snapshot.scryfall_ids),
                    "oracle_ids": len(snapshot.oracle_ids),
                    "alias_rows_prices_not_refreshed": snapshot.alias_rows,
                    "sets": len(snapshot.set_codes),
                },
                "new_set_cutoff": cutoff.isoformat() if cutoff else None,
            }
            if args.mode == "dry-run":
                counts["planned"] = {
                    "cards_refresh_candidates": len(plan.updates),
                    "cards_insert_candidates": len(plan.inserts),
                    "sets_insert_candidates": len(plan.sets),
                    "legalities_oracle_ids": len(plan.legalities),
                }
                receipt["counts"] = counts
                receipt["status"] = "dry_run"
                conn.rollback()
                return exit_code, receipt

            applied = apply_plan(cur, plan, ctx)
            counts.update(applied)
            finished_at = ctx.now()
            finished = _iso(finished_at)
            state_values = {
                STATE_CARDS_LAST_SYNC_AT: finished,
                STATE_LEGALITIES_LAST_SYNC_AT: finished,
                STATE_PRICES_LAST_SYNC_AT: finished,
                STATE_SOURCE_UPDATED_AT: source.updated_at,
                STATE_SOURCE_SHA256: source_sha256,
                STATE_LAST_RUN_ID: run_id,
                STATE_LAST_CHECKED_AT: finished,
            }
            if args.mode == "activate":
                state_values[STATE_ACTIVE_CONTRACT] = APPLY_CONTRACT
            write_state(cur, state_values, ctx.budget.batch_size)
            for sync_type, inserted, updated in (
                (SYNC_LOG_CARDS, applied["cards"]["inserted"], applied["cards"]["updated"]),
                (SYNC_LOG_SETS, applied["sets"]["inserted"], 0),
                (
                    SYNC_LOG_LEGALITIES,
                    applied["card_legalities"]["inserted"],
                    applied["card_legalities"]["updated"],
                ),
            ):
                insert_sync_log(
                    cur,
                    sync_type=sync_type,
                    inserted=inserted,
                    updated=updated,
                    status="success",
                    error_message=None,
                    started_at=started_at,
                    finished_at=finished_at,
                )
        conn.commit()
        receipt["database_writes"] = True
        receipt["counts"] = counts
        receipt["status"] = "applied" if args.mode != "activate" else "activated"
        return exit_code, receipt
    except RefreshError as exc:
        refused = isinstance(exc, ContractRefusal)
        exit_code = exc.exit_code
        receipt["status"] = "refused" if refused else "failed"
        receipt["error"] = {"kind": exc.kind, "message": str(exc)}
        _record_failure(
            conn,
            receipt,
            started_at,
            ctx,
            write_row=not refused and args.mode != "dry-run",
        )
        return exit_code, receipt
    except Exception as exc:  # inesperado: ainda assim deixa o receipt
        exit_code = 1
        receipt["status"] = "failed"
        receipt["error"] = {"kind": type(exc).__name__, "message": str(exc)}
        _record_failure(
            conn, receipt, started_at, ctx, write_row=args.mode != "dry-run"
        )
        return exit_code, receipt
    finally:
        receipt["upstream_requests"] = ctx.upstream_requests
        receipt["finished_at"] = _iso(ctx.now())
        if downloaded is not None:
            downloaded.path.unlink(missing_ok=True)
        if conn is not None:
            try:
                conn.close()
            except Exception:
                pass


def _record_failure(
    conn: Any,
    receipt: dict[str, Any],
    started_at: datetime,
    ctx: RunContext,
    *,
    write_row: bool,
) -> None:
    """Desfaz a transação e, se a execução podia gravar, registra a falha.

    A falha do próprio registro não é engolida: vai para o receipt.
    """
    if conn is None:
        return
    try:
        conn.rollback()
    except Exception as exc:
        receipt["failure_log_error"] = f"rollback: {exc}"
        return
    if not write_row:
        return
    try:
        conn.set_session(readonly=False)
        with conn.cursor() as cur:
            insert_sync_log(
                cur,
                sync_type=SYNC_LOG_RUN,
                inserted=0,
                updated=0,
                status="failed",
                error_message=f"{receipt['error']['kind']}: {receipt['error']['message']}"[:1000],
                started_at=started_at,
                finished_at=ctx.now(),
            )
        conn.commit()
        receipt["failure_logged"] = True
    except Exception as exc:
        receipt["failure_log_error"] = str(exc)
        try:
            conn.rollback()
        except Exception:
            pass


def write_receipt(receipt: dict[str, Any], output_dir: Path) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    run_dir = output_dir / receipt["run_id"]
    run_dir.mkdir(parents=True, exist_ok=True)
    text = json.dumps(receipt, indent=2, sort_keys=True, default=str) + "\n"
    path = run_dir / "receipt.json"
    path.write_text(text, encoding="utf-8")
    (output_dir / "latest_receipt.json").write_text(text, encoding="utf-8")
    return path


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    exit_code, receipt = run(args)
    output_dir = Path(args.output_dir) if args.output_dir else DEFAULT_OUTPUT_DIR
    try:
        path = write_receipt(receipt, output_dir)
        receipt_path = str(path)
    except OSError as exc:
        print(f"{RECEIPT_MARKER}_RECEIPT_WRITE_FAILED {exc}", file=sys.stderr)
        receipt_path = None
        exit_code = exit_code or 1
    print(f"{RECEIPT_MARKER} " + json.dumps({**receipt, "receipt_path": receipt_path}, sort_keys=True, default=str))
    if receipt.get("error"):
        print(
            f"{RECEIPT_MARKER}_FAILED error: {receipt['error']['kind']}: "
            f"{receipt['error']['message']}",
            file=sys.stderr,
        )
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
