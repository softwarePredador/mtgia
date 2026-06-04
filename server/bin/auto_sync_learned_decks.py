#!/usr/bin/env python3
"""Auto-sync: detecta decks aprendidos promovidos no Hermes SQLite e importa no PG.
Regras: Lorehold → PULA; qualquer outro → export JSON e dart --apply.
"""

import json, os, sqlite3, subprocess, sys
from datetime import datetime, timezone

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.environ.get(
    "MTGIA_HOME",
    "/opt/data/workspace/mtgia",
)
SYNC_PROJECT_DIR = os.environ.get(
    "MTGIA_SYNC_HOME",
    "/opt/data/workspace/mtgia-sync",
)
SQLITE_DB = os.environ.get(
    "HERMES_KNOWLEDGE_DB",
    os.path.join(PROJECT_DIR, "docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"),
)
EXPORT_SCRIPT = os.path.join(
    PROJECT_DIR, "docs/hermes-analysis/manaloom-knowledge/scripts/export_hermes_learned_deck.py",
)
ARTIFACT_DIR = os.path.join(SCRIPT_DIR, "../test/artifacts/hermes_auto_sync")
TRACKING_FILE = os.path.join(ARTIFACT_DIR, "synced_learned_ids.txt")
SERVER_DIR = os.path.join(SYNC_PROJECT_DIR, "server")
TIMESTAMP = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")

os.makedirs(ARTIFACT_DIR, exist_ok=True)
if not os.path.exists(TRACKING_FILE):
    open(TRACKING_FILE, "w").close()


def main():
    print("=== Auto-sync find_promoted ===")

    # Pull latest sync copy
    if os.path.isdir(SYNC_PROJECT_DIR):
        subprocess.run(
            ["git", "-C", SYNC_PROJECT_DIR, "pull", "--ff-only", "origin", "master"],
            capture_output=True, timeout=30,
        )

    db = sqlite3.connect(SQLITE_DB)
    rows = db.execute("""
        SELECT ld.id, ld.commander, ld.deck_name, ld.card_count, dp.promoted_at
        FROM learned_decks ld
        JOIN deck_promotions dp ON dp.learned_deck_id = ld.id
        ORDER BY dp.promoted_at DESC
    """).fetchall()
    db.close()

    if not rows:
        print("Nenhum deck promovido encontrado.")
        return 0

    synced_ids = set()
    with open(TRACKING_FILE) as f:
        for line in f:
            line = line.strip()
            if line.isdigit():
                synced_ids.add(int(line))

    synced, skipped, failed = 0, 0, 0

    for deck_id, commander, deck_name, card_count, promoted_at in rows:
        # Lorehold — freio manual de Mox
        if "lorehold" in commander.lower():
            if deck_id not in synced_ids:
                print(f'SKIP Lorehold (manual review): learned_id={deck_id} "{deck_name}"')
                synced_ids.add(deck_id)
            skipped += 1
            continue

        # Ja sincronizado
        if deck_id in synced_ids:
            synced += 1
            continue

        print(f'SYNC commander={commander} learned_id={deck_id} "{deck_name}"')
        json_path = os.path.join(ARTIFACT_DIR, f"auto_export_{deck_id}_{TIMESTAMP}.json")

        # Export
        exp = subprocess.run(
            [sys.executable, EXPORT_SCRIPT, "--db", SQLITE_DB,
             "--learned-id", str(deck_id), "--out", json_path],
            capture_output=True, text=True, timeout=30,
        )
        if exp.returncode != 0:
            print(f"  EXPORT_FAILED: {exp.stderr[-300:]}")
            failed += 1
            continue

        # Apply
        app = subprocess.run(
            ["dart", "run", "bin/commander_learned_deck.dart",
             f"--input-json={json_path}", "--apply",
             f"--artifact-dir={ARTIFACT_DIR}"],
            capture_output=True, text=True, timeout=60,
            cwd=SERVER_DIR,
        )
        if app.returncode != 0:
            print(f"  APPLY_FAILED: {app.stderr[-500:]}")
            failed += 1
            continue

        synced_ids.add(deck_id)
        synced += 1
        print("  OK")

    # Persiste tracking
    with open(TRACKING_FILE, "w") as f:
        for sid in sorted(synced_ids):
            f.write(f"{sid}\n")

    print(f"\nTOTALS synced={synced} skipped={skipped} failed={failed}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
