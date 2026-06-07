#!/usr/bin/env python3
"""Fetch EDHREC live data for Lorehold, the Historian."""
import urllib.request
import json, re, os

DB_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT = os.path.join(DB_DIR, "_edhrec_raw_lorehold.json")

req = urllib.request.Request(
    "https://edhrec.com/commanders/lorehold-the-historian",
    headers={
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    }
)
try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        html = resp.read().decode('utf-8', errors='replace')
except Exception as e:
    print(f"HTTP ERROR: {e}")
    exit(1)

match = re.search(r'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>', html, re.DOTALL)
if not match:
    print("__NEXT_DATA__ NOT FOUND")
    exit(1)

data = json.loads(match.group(1))
with open(OUTPUT, 'w') as f:
    json.dump(data, f, indent=2)

props = data.get('props', {}).get('pageProps', {})
print(f"Keys in pageProps: {list(props.keys())}")

# Find card data
for key in props:
    val = props[key]
    if isinstance(val, dict):
        print(f"  {key}: dict with {len(val)} keys - {list(val.keys())[:5]}")
    elif isinstance(val, list):
        print(f"  {key}: list with {len(val)} items")
    else:
        print(f"  {key}: {str(val)[:100]}")
