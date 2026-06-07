#!/usr/bin/env python3
"""Compare the two EDHREC snapshots."""
import json, os

DB_DIR = os.path.dirname(os.path.abspath(__file__))

# Load old snapshot
with open(os.path.join(DB_DIR, "_edhrec_snapshot_20260527_1943.json")) as f:
    old_data = json.load(f)

# Load new snapshot  
with open(os.path.join(DB_DIR, "_edhrec_raw_lorehold.json")) as f:
    new_data = json.load(f)

print("=== OLD SNAPSHOT (19:43) ===")
print(f"Top keys: {list(old_data.keys())[:10]}")

# Look for card data in old snapshot
if isinstance(old_data, dict):
    for key in old_data:
        val = old_data[key]
        if isinstance(val, list):
            if len(val) > 0 and isinstance(val[0], dict):
                if 'name' in val[0] or 'pct' in val[0] or 'inclusion' in val[0]:
                    print(f"\nFound card list at '{key}': {len(val)} items")
                    # Check for Rise
                    for c in val:
                        if 'rise' in c.get('name', '').lower():
                            print(f"  Rise of the Eldrazi: {c}")
                    break

# Check the __NEXT_DATA__ path in new data
if 'props' in new_data:
    print("\n=== NEW SNAPSHOT (20:27) ===")
    props = new_data['props']['pageProps']
    print(f"Keys: {list(props.keys())}")
    
# Also check raw taglinks from old
if 'taglinks' in old_data:
    print(f"\nTaglinks: {len(old_data['taglinks'])} items")
elif isinstance(old_data, list):
    print(f"Old data is list with {len(old_data)} items")
