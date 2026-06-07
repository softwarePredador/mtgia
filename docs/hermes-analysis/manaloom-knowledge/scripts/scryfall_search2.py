#!/usr/bin/env python3
"""Fetch Lorehold synergy data from Scryfall API."""
import urllib.request, json, sys, os

save_dir = os.path.dirname(os.path.abspath(__file__))

# Simple direct query - all miracle cards
url = "https://api.scryfall.com/cards/search?q=o%3Amiracle&order=edhrec&unique=cards"
req = urllib.request.Request(url, headers={"User-Agent": "ManaLoom/1.0"})
with urllib.request.urlopen(req, timeout=15) as resp:
    data = json.loads(resp.read())

cards = data.get('data', [])
print(f"=== MIRACLE CARDS ({len(cards)} found) ===")
for c in cards[:10]:
    print(f"  {c['name']:40s} CMC {c.get('cmc', '?'):>3}  {c.get('mana_cost', '')[:20]:20s}  {c.get('set_name', '')}")

# Boros copy spells
url2 = "https://api.scryfall.com/cards/search?q=t%3Ainstant+copy+id%3Crw&order=edhrec&unique=cards"
req2 = urllib.request.Request(url2, headers={"User-Agent": "ManaLoom/1.0"})
with urllib.request.urlopen(req2, timeout=15) as resp2:
    data2 = json.loads(resp2.read())

cards2 = data2.get('data', [])
print(f"\n=== BOROS COPY SPELLS ({len(cards2)} found) ===")
for c in cards2[:10]:
    print(f"  {c['name']:40s} CMC {c.get('cmc', '?'):>3}  {c.get('mana_cost', '')[:20]:20s}  {c.get('set_name', '')}")
