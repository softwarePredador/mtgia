"""DB helper using psycopg2 directly (no psql subprocess needed)."""
import os
import psycopg2

DB_PARAMS = {
    'host': '143.198.230.247',
    'port': '5433',
    'dbname': 'halder',
    'user': 'postgres',
    'password': 'c2abeef5e66f21b0ce86'
}


def run_sql(sql, fetch=False):
    """Execute SQL via psycopg2.

    - For INSERT/UPDATE/DELETE: returns rowcount as str (e.g. "1")
    - For SELECT with fetch=True: returns the first column of the first row
    - Returns "" on error (ignores duplicate/already-exists errors)
    """
    sql_stripped = sql.strip()
    is_select = sql_stripped.upper().startswith("SELECT")
    try:
        conn = psycopg2.connect(
            host=DB_PARAMS['host'],
            port=DB_PARAMS['port'],
            dbname=DB_PARAMS['dbname'],
            user=DB_PARAMS['user'],
            password=DB_PARAMS['password']
        )
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
