#!/usr/bin/env python3
"""Fetch Lorehold synergy data from Scryfall API."""
import urllib.request, json, sys, urllib.parse

def search(q):
    url = f"https://api.scryfall.com/cards/search?q={urllib.parse.quote(q)}&order=edhrec&unique=cards"
    req = urllib.request.Request(url, headers={"User-Agent": "ManaLoom/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read())
        cards = data.get('data', [])
        print(f"  Found {len(cards)} cards (top 5):")
        for c in cards[:5]:
            print(f"  - {c['name']:40s} CMC {c.get('cmc', '?'):>3}  {c.get('set_name', '')}")
    except Exception as e:
        print(f"  ERROR: {e}")

# Search 1: Miracle cards
print("=== Miracle cards (any color) ===")
search("o:miracle t:instant or t:sorcery")

# Search 2: Topdeck manipulation  
print("\n=== Topdeck manipulation (Boros ID) ===")
search("o:'top of your library' id<=rw")

# Search 3: Copy spells in Boros
print("\n=== Copy spells in Boros ===")
search("o:'copy target' id<=rw t:instant or t:sorcery")

# Search 4: Spell payoffs in Boros
print("\n=== Spell payoffs in Boros ===")
search("o:'whenever you cast' id<=rw t:creature")
