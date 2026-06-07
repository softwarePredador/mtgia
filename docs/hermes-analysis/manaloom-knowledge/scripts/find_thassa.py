#!/usr/bin/env python3
"""Find Thassa's Oracle in raw artifact data."""
import json
import re

with open('/opt/data/workspace/mtgia/server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_2026-04-27.json') as f:
    content = f.read()

# Search for Thassa in raw content
idx = content.find('Thassa')
if idx >= 0:
    print(f"Found 'Thassa' at position {idx}")
    snippet = content[max(0, idx-80):idx+250]
    print(f"Context: {snippet}")
else:
    print("'Thassa' not found directly")
    # Try with encoding
    for term in ['Thassa', 'THASSA', 'thassa']:
        idx = content.find(term)
        if idx >= 0:
            print(f"Found '{term}' at {idx}")
            print(content[max(0, idx-80):idx+200])
            break
    else:
        # Check the actual write from the search_files result earlier
        print("Checking from search_files result...")
        print("File was reported to contain 'Thassa's Oracle' at line 41")
        lines = content.split('\n')
        for i in range(38, 50):
            print(f"Line {i+1}: {lines[i][:200]}")