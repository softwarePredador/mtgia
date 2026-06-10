import os
from pathlib import Path
from urllib.parse import quote, urlparse

import psycopg2

"""DB helper using psycopg2 directly (no psql subprocess needed).

Connection details must come from DATABASE_URL, DB_* or PG* variables in the
runtime environment. A local .env is loaded as a convenience for developer
machines, but secrets must never be hardcoded or printed in Hermes artifacts.
"""

DB_PARAMS = {}
_DOTENV_LOADED = False


def _dotenv_candidates() -> list[Path]:
    script_path = Path(__file__).resolve()
    candidates: list[Path] = []
    for base in [Path.cwd(), *Path.cwd().parents, script_path.parent, *script_path.parents]:
        env_path = base / ".env"
        if env_path not in candidates:
            candidates.append(env_path)
    return candidates


def load_dotenv_once() -> None:
    """Load the nearest .env without overriding real runtime env values."""
    global _DOTENV_LOADED
    if _DOTENV_LOADED:
        return
    _DOTENV_LOADED = True

    for env_path in _dotenv_candidates():
        if not env_path.is_file():
            continue
        for raw_line in env_path.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = value
        return


def get_database_url():
    load_dotenv_once()

    database_url = os.environ.get("DATABASE_URL")
    if database_url:
        return database_url

    host = os.environ.get("DB_HOST") or os.environ.get("PGHOST")
    port = os.environ.get("DB_PORT") or os.environ.get("PGPORT") or "5432"
    db_name = os.environ.get("DB_NAME") or os.environ.get("PGDATABASE")
    user = os.environ.get("DB_USER") or os.environ.get("PGUSER")
    password = os.environ.get("DB_PASS") or os.environ.get("PGPASSWORD")

    required = {
        "DB_HOST/PGHOST": host,
        "DB_NAME/PGDATABASE": db_name,
        "DB_USER/PGUSER": user,
        "DB_PASS/PGPASSWORD": password,
    }
    missing = [name for name, value in required.items() if not value]
    if missing:
        raise RuntimeError(
            "DATABASE_URL is not set and DB_*/PG* config is incomplete: "
            + ", ".join(missing)
        )

    dbname_safe = quote(str(db_name), safe="")
    user_safe = quote(str(user), safe="")
    password_safe = quote(str(password), safe="")
    return f"postgres://{user_safe}:{password_safe}@{host}:{port}/{dbname_safe}"


def sanitized_database_target():
    database_url = get_database_url()
    parsed = urlparse(database_url)
    return f"{parsed.hostname}:{parsed.port or 5432}/{parsed.path.lstrip('/')}"


def connect():
    return psycopg2.connect(get_database_url())


def run_sql(sql, fetch=False):
    """Execute SQL via psycopg2.

    - For INSERT/UPDATE/DELETE: returns rowcount as str (e.g. "1")
    - For SELECT with fetch=True: returns the first column of the first row
    - Returns "" on error (ignores duplicate/already-exists errors)
    """
    sql_stripped = sql.strip()
    is_select = sql_stripped.upper().startswith("SELECT")
    try:
        conn = connect()
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
