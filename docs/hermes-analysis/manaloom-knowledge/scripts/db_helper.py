"""DB helper using psycopg2 directly (no psql subprocess needed).

A conexão só vem de configuração explícita:

- ``DATABASE_URL`` no ambiente; ou
- ``DB_HOST``/``DB_NAME``/``DB_USER`` (ou os ``PG*`` equivalentes) no ambiente,
  com a senha em ``DB_PASS``/``PGPASSWORD`` quando o banco pede; ou
- um arquivo nomeado em ``MANALOOM_POSTGRES_ENV`` (o mesmo nome que o
  ``server/bin/master_optimizer_preflight.sh`` já usa).

Nenhum ``.env`` é procurado subindo diretórios. Antes, sem configuração no
ambiente, o helper carregava o ``.env`` mais próximo do diretório corrente ou
do próprio script; rodando de um worktree, isso achava o ``server/.env`` do
checkout principal, que pode apontar para o banco de produção.

Host fora do loopback (127.0.0.0/8, ``::1`` ou ``localhost``) exige a
confirmação explícita do projeto: ``MANALOOM_CONFIRM_POSTGRES_READS`` ou
``MANALOOM_CONFIRM_POSTGRES_WRITES`` igual a ``I_HAVE_EXPLICIT_APPROVAL``. Uma
escrita por ``run_sql`` num host assim exige a de escrita. O daemon de ops dá
a de leitura aos jobs dele, porque o banco configurado no serviço é o dele.

Sem configuração, ou sem a confirmação, o helper falha fechado com uma
mensagem que não mostra a URL, o host nem a senha.
"""

from __future__ import annotations

import ipaddress
import os
from pathlib import Path
from urllib.parse import parse_qs, quote, unquote, urlparse

import psycopg2

DB_PARAMS = {}

APPROVAL_PHRASE = "I_HAVE_EXPLICIT_APPROVAL"
READ_APPROVAL_ENV = "MANALOOM_CONFIRM_POSTGRES_READS"
WRITE_APPROVAL_ENV = "MANALOOM_CONFIRM_POSTGRES_WRITES"
ENV_FILE_ENV = "MANALOOM_POSTGRES_ENV"


class DatabaseConfigError(RuntimeError):
    """Configuração ausente ou não autorizada. A mensagem nunca traz a URL."""


def _read_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        if key:
            values[key] = value.strip().strip('"').strip("'")
    return values


def _url_from_values(values: dict[str, str]) -> str | None:
    database_url = values.get("DATABASE_URL")
    if database_url:
        return database_url
    host = values.get("DB_HOST") or values.get("PGHOST")
    port = values.get("DB_PORT") or values.get("PGPORT") or "5432"
    db_name = values.get("DB_NAME") or values.get("PGDATABASE")
    user = values.get("DB_USER") or values.get("PGUSER")
    password = values.get("DB_PASS") or values.get("PGPASSWORD") or ""
    if not all([host, db_name, user]):
        return None
    return _database_url_from_parts(
        host=host,
        port=port,
        db_name=db_name,
        user=user,
        password=password,
    )


def _explicit_database_url() -> tuple[str, str]:
    """A URL e a origem dela. Só configuração explícita conta."""
    environment = {key: value for key, value in os.environ.items() if value}
    url = _url_from_values(environment)
    if url:
        source = "DATABASE_URL" if environment.get("DATABASE_URL") else "DB_*/PG*"
        return url, source

    named_file = os.environ.get(ENV_FILE_ENV, "").strip()
    if named_file:
        path = Path(named_file).expanduser()
        if not path.is_file():
            raise DatabaseConfigError(
                f"{ENV_FILE_ENV} aponta para um arquivo que não existe. "
                "Nenhum outro arquivo é procurado."
            )
        # O ambiente vence o arquivo, chave por chave, como antes.
        merged = {**_read_env_file(path), **environment}
        url = _url_from_values(merged)
        if url:
            return url, ENV_FILE_ENV
        raise DatabaseConfigError(
            f"O arquivo de {ENV_FILE_ENV} não tem DATABASE_URL nem "
            "DB_HOST/DB_NAME/DB_USER completos."
        )

    raise DatabaseConfigError(
        "PostgreSQL não configurado. Defina DATABASE_URL, ou DB_HOST, DB_NAME e "
        f"DB_USER (com DB_PASS quando o banco pede), ou {ENV_FILE_ENV} com o "
        "caminho de um arquivo. Nenhum .env é procurado nos diretórios acima."
    )


def is_loopback_host(host: str | None) -> bool:
    """Loopback de verdade: um literal IP de loopback ou o nome ``localhost``."""
    value = (host or "").strip().strip("[]").lower()
    if not value:
        return False
    if value == "localhost":
        return True
    try:
        return ipaddress.ip_address(value).is_loopback
    except ValueError:
        return False


def _split_hosts(raw: str) -> list[str]:
    return [item.strip() for item in raw.split(",")]


def _netloc_hosts(netloc: str) -> list[str]:
    hosts: list[str] = []
    for item in _split_hosts(netloc.rsplit("@", 1)[-1]):
        if item.startswith("["):
            end = item.find("]")
            hosts.append(item[1:end] if end > 0 else item)
        else:
            hosts.append(unquote(item.split(":", 1)[0]))
    return hosts


def connection_hosts(database_url: str) -> list[str] | None:
    """Hosts que o libpq pode usar com esta URL, ou ``None`` quando não dá
    para saber (serviço nomeado, URL sem host, esquema estranho).

    Conta o que o libpq aplica por cima do host da URL: ``host`` e ``hostaddr``
    na consulta da URL, e ``PGHOSTADDR`` do ambiente.
    """
    parsed = urlparse(database_url)
    if parsed.scheme not in ("postgres", "postgresql"):
        return None
    query = parse_qs(parsed.query, keep_blank_values=True)
    if "service" in query or os.environ.get("PGSERVICE"):
        return None
    hosts = _netloc_hosts(parsed.netloc)
    for key in ("host", "hostaddr"):
        for value in query.get(key, []):
            hosts.extend(_split_hosts(value))
    env_hostaddr = os.environ.get("PGHOSTADDR", "").strip()
    if env_hostaddr:
        hosts.extend(_split_hosts(env_hostaddr))
    if not hosts or any(not host for host in hosts):
        return None
    return hosts


def targets_loopback_only(database_url: str) -> bool:
    hosts = connection_hosts(database_url)
    return bool(hosts) and all(is_loopback_host(host) for host in hosts)


def _has_approval(access: str) -> bool:
    writes = os.environ.get(WRITE_APPROVAL_ENV) == APPROVAL_PHRASE
    if access == "write":
        return writes
    return writes or os.environ.get(READ_APPROVAL_ENV) == APPROVAL_PHRASE


def get_database_url(*, access: str = "read") -> str:
    """A URL explícita, conferida contra o loopback e a confirmação.

    ``access`` é ``"read"`` ou ``"write"``. Fora do loopback, leitura aceita a
    confirmação de leitura ou de escrita; escrita exige a de escrita.
    """
    if access not in ("read", "write"):
        raise ValueError("access deve ser 'read' ou 'write'")
    database_url, source = _explicit_database_url()
    if targets_loopback_only(database_url) or _has_approval(access):
        return database_url
    if access == "write":
        needed = f"{WRITE_APPROVAL_ENV}={APPROVAL_PHRASE}"
    else:
        needed = (
            f"{READ_APPROVAL_ENV}={APPROVAL_PHRASE} "
            f"(ou {WRITE_APPROVAL_ENV}={APPROVAL_PHRASE})"
        )
    raise DatabaseConfigError(
        f"O PostgreSQL configurado em {source} não é só loopback. Para "
        f"{'escrever' if access == 'write' else 'ler'} nele, defina {needed} "
        "só depois da aprovação desta execução. A URL, o host e a senha não "
        "são mostrados."
    )


def _database_url_from_parts(*, host, port, db_name, user, password):
    dbname_safe = quote(str(db_name), safe="")
    user_safe = quote(str(user), safe="")
    if password:
        password_safe = quote(str(password), safe="")
        credentials = f"{user_safe}:{password_safe}"
    else:
        credentials = user_safe
    return f"postgres://{credentials}@{host}:{port}/{dbname_safe}"


def sanitized_database_target():
    database_url = get_database_url()
    parsed = urlparse(database_url)
    return f"{parsed.hostname}:{parsed.port or 5432}/{parsed.path.lstrip('/')}"


def connect(*, access: str = "read"):
    return psycopg2.connect(get_database_url(access=access))


def _is_read_only_sql(sql: str) -> bool:
    stripped = sql.strip().rstrip(";").strip()
    return stripped.upper().startswith("SELECT") and ";" not in stripped


def run_sql(sql, fetch=False):
    """Execute SQL via psycopg2.

    - For INSERT/UPDATE/DELETE: returns rowcount as str (e.g. "1")
    - For SELECT with fetch=True: returns the first column of the first row
    - Returns "" on a database error (ignores duplicate/already-exists errors)

    A configuração é conferida antes do ``try``: sem ela, ou sem a confirmação,
    a exceção sobe em vez de virar um "" silencioso.
    """
    is_select = _is_read_only_sql(sql)
    database_url = get_database_url(access="read" if is_select else "write")
    try:
        conn = psycopg2.connect(database_url)
        conn.autocommit = True
        cur = conn.cursor()
        cur.execute(sql)
        if is_select:
            row = cur.fetchone()
            result = str(row[0]) if row else "0"
        else:
            rowcount = cur.rowcount if cur.rowcount is not None else 0
            result = str(rowcount)
        cur.close()
        conn.close()
        return result
    except Exception as e:
        err = str(e)[:200]
        if 'already exists' in err or 'duplicate' in err:
            return "0"
        print(f"  ERR: {err}")
        return ""
