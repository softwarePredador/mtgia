#!/usr/bin/env python3
"""Copy the /tmp copy back to the original location using Python's file I/O"""
src = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
tmp = "/tmp/knowledge_copy.db"

# Read the temp copy
with open(tmp, "rb") as f:
    data = f.read()

# Write to the original location
with open(src, "wb") as f:
    f.write(data)

print(f"Written {len(data)} bytes to {src}")

# Verify
import sqlite3
conn = sqlite3.connect(src)
row = conn.execute("SELECT card_name, why_game_changer IS NOT NULL as has_why FROM game_changers WHERE card_name LIKE ?", ("%Thassa%",)).fetchone()
print(f"Verified: {row[0]} | has_why={row[1]}")
conn.close()