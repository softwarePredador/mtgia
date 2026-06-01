"""DB helper using psycopg2 directly (no psql subprocess needed).

Connection details must come from DATABASE_URL in the runtime environment.
Do not hardcode or print credentials in Hermes artifacts.
"""
import os
import psycopg2
from urllib.parse import quote, urlparse

DB_PARAMS = {}


def get_database_url():
    database_url = os.environ.get("DATABASE_URL")
    if database_url:
        return database_url

    required = ["DB_HOST", "DB_NAME", "DB_USER", "DB_PASS"]
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        raise RuntimeError(
            "DATABASE_URL is not set and DB_* config is incomplete: "
            + ", ".join(missing)
        )

    host = os.environ["DB_HOST"]
    port = os.environ.get("DB_PORT", "5432")
    dbname = quote(os.environ["DB_NAME"], safe="")
    user = quote(os.environ["DB_USER"], safe="")
    password = quote(os.environ["DB_PASS"], safe="")
    return f"postgres://{user}:{password}@{host}:{port}/{dbname}"


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
