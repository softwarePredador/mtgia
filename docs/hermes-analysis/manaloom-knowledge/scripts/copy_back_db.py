#!/usr/bin/env python3
"""Legacy helper for manually restoring a temporary SQLite copy.

This is blocked by default because current flows must sync PostgreSQL -> Hermes
instead of copying over the runtime cache by absolute path.
"""
import os
import sqlite3
import sys

from master_optimizer_common import resolve_default_knowledge_db

if os.environ.get("MANALOOM_ALLOW_LEGACY_COPY_BACK_DB") != "1":
    print(
        "copy_back_db.py is a legacy manual recovery helper. "
        "Set MANALOOM_ALLOW_LEGACY_COPY_BACK_DB=1 only for an intentional local restore.",
        file=sys.stderr,
    )
    raise SystemExit(2)

src = str(resolve_default_knowledge_db())
tmp = "/tmp/knowledge_copy.db"

# Read the temp copy
with open(tmp, "rb") as f:
    data = f.read()

# Write to the original location
with open(src, "wb") as f:
    f.write(data)

print(f"Written {len(data)} bytes to {src}")

# Verify
conn = sqlite3.connect(src)
row = conn.execute("SELECT card_name, why_game_changer IS NOT NULL as has_why FROM game_changers WHERE card_name LIKE ?", ("%Thassa%",)).fetchone()
print(f"Verified: {row[0]} | has_why={row[1]}")
conn.close()
