#!/usr/bin/env python3
"""Auto-sync: detecta decks aprendidos promovidos no Hermes SQLite e importa no PG.
Default seguro: dry-run estrito. Use --apply ou HERMES_AUTO_SYNC_APPLY=1 para mutar PG.
Regras: Lorehold -> PULA; qualquer outro -> export JSON e importador Commander 100/99+1.
"""

import argparse, os, shutil, sqlite3, subprocess, sys
from pathlib import Path
from datetime import datetime, timezone

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
PROJECT_DIR = Path(os.environ.get("MTGIA_HOME", str(REPO_ROOT)))
SYNC_PROJECT_DIR = Path(os.environ.get("MTGIA_SYNC_HOME", str(PROJECT_DIR)))
DART_BIN = os.environ.get(
    "MANALOOM_DART_BIN",
    os.environ.get("DART_BIN", shutil.which("dart") or "dart"),
)
SQLITE_DB = os.environ.get(
    "HERMES_KNOWLEDGE_DB",
    str(PROJECT_DIR / "docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"),
)
EXPORT_SCRIPT_CANDIDATES = [
    os.environ.get("HERMES_EXPORT_SCRIPT"),
    str(PROJECT_DIR / "server/bin/export_hermes_learned_deck.py"),
    str(PROJECT_DIR / "docs/hermes-analysis/manaloom-knowledge/scripts/export_hermes_learned_deck.py"),
]
ARTIFACT_DIR = Path(os.environ.get(
    "HERMES_ARTIFACT_DIR",
    str(PROJECT_DIR / "server/test/artifacts/hermes_auto_sync"),
))
TRACKING_FILE = ARTIFACT_DIR / "synced_learned_ids.txt"
SERVER_DIR = Path(os.environ.get("MTGIA_SYNC_SERVER_DIR", str(SYNC_PROJECT_DIR / "server")))
TIMESTAMP = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
REQUIRED_CARD_COUNT = int(os.environ.get("HERMES_AUTO_SYNC_REQUIRED_CARD_COUNT", "100"))
ALLOW_RUNTIME_GIT_PULL = os.environ.get("MTGIA_SYNC_GIT_PULL", "0") == "1"

ENV_FILES = [
    os.environ.get("MTGIA_ENV_FILE"),
    str(SERVER_DIR / ".env"),
    os.environ.get("MANALOOM_POSTGRES_ENV"),
    "/opt/data/secrets/manaloom-postgres.env",
]


def _load_env():
    for env_file in ENV_FILES:
        if not env_file or not os.path.isfile(env_file):
            continue
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, _, value = line.partition("=")
                key = key.strip()
                value = value.strip().strip("\"'")
                if key and key not in os.environ:
                    os.environ[key] = value


_load_env()

def _export_script_path():
    for candidate in EXPORT_SCRIPT_CANDIDATES:
        if candidate and os.path.exists(candidate):
            return candidate
    raise FileNotFoundError("export_hermes_learned_deck.py nao encontrado")


def _table_exists(db, table_name):
    return (
        db.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
            (table_name,),
        ).fetchone()
        is not None
    )


def _column_exists(db, table_name, column_name):
    if not _table_exists(db, table_name):
        return False
    return any(
        row[1] == column_name
        for row in db.execute(f"PRAGMA table_info({table_name})")
    )


def _find_promoted_rows(db):
    if not _table_exists(db, "learned_decks") or not _table_exists(
        db,
        "deck_promotions",
    ):
        return []
    verified_filter = (
        "AND COALESCE(dp.migration_verified, 0) = 1"
        if _column_exists(db, "deck_promotions", "migration_verified")
        else ""
    )
    return db.execute(
        f"""
        SELECT ld.id, ld.commander, ld.deck_name, ld.card_count, dp.promoted_at
        FROM learned_decks ld
        JOIN deck_promotions dp ON dp.learned_deck_id = ld.id
        WHERE ld.card_count = ?
          AND ld.commander != ''
          {verified_filter}
        ORDER BY dp.promoted_at DESC
        """,
        (REQUIRED_CARD_COUNT,),
    ).fetchall()


def _count_invalid_promoted_rows(db):
    if not _table_exists(db, "learned_decks") or not _table_exists(
        db,
        "deck_promotions",
    ):
        return 0
    unverified_filter = (
        "OR COALESCE(dp.migration_verified, 0) != 1"
        if _column_exists(db, "deck_promotions", "migration_verified")
        else ""
    )
    return db.execute(
        f"""
        SELECT COUNT(*)
        FROM learned_decks ld
        JOIN deck_promotions dp ON dp.learned_deck_id = ld.id
        WHERE COALESCE(ld.card_count, 0) != ?
           OR ld.commander = ''
           {unverified_filter}
        """,
        (REQUIRED_CARD_COUNT,),
    ).fetchone()[0]


def _ensure_artifact_storage():
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    if not TRACKING_FILE.exists():
        TRACKING_FILE.write_text("")


def main(argv=None):
    parser = argparse.ArgumentParser(description="Auto-sync Hermes learned decks")
    parser.add_argument("--apply", action="store_true", help="Aplica no PG")
    args = parser.parse_args(argv)
    _ensure_artifact_storage()
    apply = args.apply or os.environ.get("HERMES_AUTO_SYNC_APPLY") == "1"
    export_script = _export_script_path()
    print("=== Auto-sync find_promoted ===")
    print(f"mode={'apply' if apply else 'dry_run'} export_script={export_script}")

    # Pull latest sync copy
    if ALLOW_RUNTIME_GIT_PULL and SYNC_PROJECT_DIR.is_dir():
        subprocess.run(
            ["git", "-C", str(SYNC_PROJECT_DIR), "pull", "--ff-only", "origin", "master"],
            capture_output=True, timeout=30,
        )

    db = sqlite3.connect(SQLITE_DB)
    rows = _find_promoted_rows(db)
    invalid_promoted = _count_invalid_promoted_rows(db)
    db.close()

    if invalid_promoted:
        print(
            "INVALID_PROMOTED_SKIPPED_BY_QUERY "
            f"count={invalid_promoted} required_card_count={REQUIRED_CARD_COUNT}"
        )

    if not rows:
        print("Nenhum deck promovido elegivel encontrado.")
        return 0

    synced_ids = set()
    with TRACKING_FILE.open() as f:
        for line in f:
            line = line.strip()
            if line.isdigit():
                synced_ids.add(int(line))

    applied, dry_run_ok, already_synced, skipped, invalid_skipped, failed = 0, 0, 0, 0, invalid_promoted, 0

    for deck_id, commander, deck_name, card_count, promoted_at in rows:
        # Lorehold — freio manual de Mox
        if "lorehold" in commander.lower():
            print(f'SKIP Lorehold (manual review): learned_id={deck_id} "{deck_name}"')
            skipped += 1
            continue

        # Ja sincronizado
        if deck_id in synced_ids:
            already_synced += 1
            continue

        print(f'SYNC commander={commander} learned_id={deck_id} "{deck_name}"')
        json_path = ARTIFACT_DIR / f"auto_export_{deck_id}_{TIMESTAMP}.json"

        # Export
        exp = subprocess.run(
            [sys.executable, export_script, "--db", SQLITE_DB,
             "--learned-id", str(deck_id), "--out", str(json_path)],
            capture_output=True, text=True, timeout=30,
        )
        if exp.returncode != 0:
            print(f"  EXPORT_FAILED: {exp.stderr[-300:]}")
            failed += 1
            continue

        mode_arg = "--apply" if apply else "--dry-run"
        app = subprocess.run(
            [DART_BIN, "run", "bin/commander_learned_deck.dart",
             f"--input-json={json_path}", mode_arg, "--strict",
             f"--artifact-dir={ARTIFACT_DIR}"],
            capture_output=True, text=True, timeout=60,
            cwd=str(SERVER_DIR),
        )
        if app.returncode != 0:
            app_error = (app.stderr or "") + "\n" + (app.stdout or "")
            if (
                "falhou no gate de importacao" in app_error
                or "deck Commander aprendido precisa" in app_error
                or "card_count declarado" in app_error
            ):
                print(f"  INVALID_SKIPPED: {app_error[-500:]}")
                invalid_skipped += 1
                continue
            print(f"  APPLY_FAILED: {app_error[-500:]}")
            failed += 1
            continue

        if apply:
            synced_ids.add(deck_id)
            applied += 1
            print("  APPLY_OK")
        else:
            dry_run_ok += 1
            print("  DRY_RUN_OK")

    # Persiste tracking
    with TRACKING_FILE.open("w") as f:
        for sid in sorted(synced_ids):
            f.write(f"{sid}\n")

    print(
        f"\nTOTALS applied={applied} dry_run_ok={dry_run_ok} "
        f"already_synced={already_synced} skipped={skipped} "
        f"invalid_skipped={invalid_skipped} failed={failed}"
    )
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
