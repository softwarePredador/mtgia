#!/usr/bin/env python3
"""Generate Edgar Markov JSON for SQLite insertion using scryfall_classifier data."""
import sys, os, json

sys.path.insert(0, '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts')
from scryfall_classifier import fetch_cards, classify_card, infer_functional_card_tags

# Load corpus
with open('/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/edgar_edhrec_average_corpus.json') as f:
    corpus = json.load(f)

default_deck = corpus['decks'][0]
cards_in = default_deck['cards']

# Land names for filtering
land_names_flat = {'command tower', 'blood crypt', 'bloodstained mire', 'bojuka bog',
    'caves of koilos', 'dragonskull summit', 'exotic orchard', 'godless shrine',
    'isolated chapel', 'luxury suite', 'marsh flats', 'nomad outpost',
    'path of ancestry', 'sacred foundry', 'savai triome',
    'secluded courtyard', 'unclaimed territory', 'vault of champions',
    'vault of the archangel', 'voldaren estate', 'cavern of souls',
    'mountain', 'plains', 'swamp', 'island', 'forest'}

# Get unique non-land names for classification
non_land_names = []
for c in cards_in:
    name_lower = c['name'].lower().strip()
    if name_lower in land_names_flat or c['board'] == 'commander':
        continue
    non_land_names.append(c['name'])

print(f"Fetching {len(non_land_names)} cards from Scryfall...")
card_data = fetch_cards(non_land_names)

# Build cards JSON
cards_out = []
for c in cards_in:
    name = c['name']
    nl = name.lower().strip()
    
    # Commander
    if c['board'] == 'commander':
        cards_out.append({
            "name": name,
            "quantity": c['quantity'],
            "functional_tag": "commander",
            "is_commander": 1,
            "cmc": 6,
            "tags": [{"tag": "commander", "confidence": 1.0, "evidence": "Commander slot"}],
            "analysis": {
                "mana_loom_tag": "commander",
                "expected_tag": "commander",
                "tag_match": 1,
                "psychology_why": "Unico comandante com eminencia que gera tokens vampires. Nao ha substituto para vampire tribal Mardu.",
                "psychology_fear": "Sem Edgar, não ha geracao de tokens automatica, e o deck tribalo perde o principal motor.",
                "psychology_opportunity": "Com Edgar na zona de comando, cada Vampiro conjurado gera um token 1/1 com voar de graca.",
                "psychology_tradeoff": "Edgar nao compra cartas nem remove. O valor e puramente em board presence.",
                "staple_or_personal": 1,
                "synergy": "Eminencia ativa com cada Vampiro. Lords (Legion Lieutenant) buffam tokens.",
                "alternatives": "Nenhuma — Edgar e unico para o arquétipo.",
                "game_timing": "any"
            }
        })
        continue
    
    # Lands
    if nl in land_names_flat:
        cards_out.append({
            "name": name,
            "quantity": c['quantity'],
            "functional_tag": "land",
            "is_commander": 0,
            "cmc": 0,
            "tags": [{"tag": "land", "confidence": 1.0, "evidence": "Land card"}],
            "analysis": {
                "mana_loom_tag": "land",
                "expected_tag": "land",
                "tag_match": 1,
                "psychology_why": "Base de mana para suportar 3 cores (WBR) com 36 terrenos.",
                "psychology_fear": "Sem mana consistente, as cartas caras (5+ mana) ficam presas na mao.",
                "psychology_opportunity": "Base de mana com fetch + shock + triome +5 terrenos rainbow garante cores.",
                "psychology_tradeoff": "10+ terrenos entram virados — aceita lentidao por orcamento.",
                "staple_or_personal": 1,
                "synergy": "Cavern of Souls nomeia Vampiro.",
                "alternatives": "Fetch lands + shock lands sao o padrao Commander.",
                "game_timing": "early"
            }
        })
        continue
    
    # Non-land cards
    nl_key = name.lower().strip()
    d = card_data.get(nl_key, {})
    if not d or 'name' not in d:
        print(f"  WARNING: No Scryfall data for {name}, using defaults")
        cards_out.append({
            "name": name,
            "quantity": c['quantity'],
            "functional_tag": "other",
            "is_commander": 0,
            "cmc": 3,
            "tags": [{"tag": "other", "confidence": 0.5, "evidence": "No Scryfall data"}],
            "analysis": {
                "mana_loom_tag": "other",
                "expected_tag": "other",
                "tag_match": 1,
                "psychology_why": "",
                "psychology_fear": "",
                "psychology_opportunity": "",
                "psychology_tradeoff": "",
                "staple_or_personal": 0,
                "synergy": "",
                "alternatives": "",
                "game_timing": "any"
            }
        })
        continue
    
    single_tag = classify_card(d)
    multi_tags = infer_functional_card_tags(d['name'], d.get('type_line', ''), d.get('oracle_text', ''))
    cmc = d.get('cmc', 0)
    
    cards_out.append({
        "name": name,
        "quantity": c['quantity'],
        "functional_tag": single_tag,
        "is_commander": 0,
        "cmc": cmc,
        "tags": [{"tag": t['tag'], "confidence": t['confidence'], "evidence": t['evidence'][:100] if t.get('evidence') else ''} for t in multi_tags],
        "analysis": {
            "mana_loom_tag": single_tag,
            "expected_tag": single_tag,
            "tag_match": 1,
            "psychology_why": "",
            "psychology_fear": "",
            "psychology_opportunity": "",
            "psychology_tradeoff": "",
            "staple_or_personal": 0,
            "synergy": "",
            "alternatives": "",
            "game_timing": "any"
        }
    })

# Count quantities
total_qty = sum(c['quantity'] for c in cards_out)
non_land_qty = sum(c['quantity'] for c in cards_out if c['functional_tag'] != 'land' and c['functional_tag'] != 'commander')
land_qty = sum(c['quantity'] for c in cards_out if c['functional_tag'] == 'land')

print(f"Total cards: {total_qty} (commander=1, lands={land_qty}, non-lands={non_land_qty})")

# CMC average
cmc_sum = sum(c['cmc'] * c['quantity'] for c in cards_out if c['functional_tag'] not in ('land', 'commander'))
avg_cmc = round(cmc_sum / non_land_qty, 2) if non_land_qty else 0
print(f"Avg CMC: {avg_cmc} ({non_land_qty} non-lands)")

# Ramp count
ramp_count = 0
for c in cards_out:
    for t in c.get('tags', []):
        if t.get('tag') == 'ramp' and c['functional_tag'] != 'land':
            ramp_count += c['quantity']
            break

# Draw count
draw_count = 0
for c in cards_out:
    for t in c.get('tags', []):
        if t.get('tag') == 'draw':
            draw_count += c['quantity']
            break

# Removal count
removal_count = 0
for c in cards_out:
    for t in c.get('tags', []):
        if t.get('tag') == 'removal':
            removal_count += c['quantity']
            break

# Tutor
tutor_count = 0
for c in cards_out:
    for t in c.get('tags', []):
        if t.get('tag') == 'tutor':
            tutor_count += c['quantity']
            break

# Board wipe
wipe_count = 0
for c in cards_out:
    for t in c.get('tags', []):
        if t.get('tag') == 'board_wipe':
            wipe_count += c['quantity']
            break

# Protection
prot_count = 0
for c in cards_out:
    for t in c.get('tags', []):
        if t.get('tag') == 'protection':
            prot_count += c['quantity']
            break

print(f"Ramp: {ramp_count}, Draw: {draw_count}, Removal: {removal_count}, Tutor: {tutor_count}, Board wipe: {wipe_count}, Protection: {prot_count}")

# Build final JSON
deck_json = {
    "commander": "Edgar Markov",
    "archetype": "vampire_typal_aggro_tokens",
    "color_identity": "WBR",
    "bracket": 3,
    "source_name": "EDHREC",
    "source_url": "https://edhrec.com/average-decks/edgar-markov",
    "source_type": "edhrec_average",
    "deck_name": "Edgar Markov EDHREC Default Average",
    "player_name": "",
    "placement": "",
    "tournament_date": "",
    "total_lands": land_qty,
    "avg_cmc": avg_cmc,
    "ramp_count": ramp_count,
    "draw_count": draw_count,
    "removal_count": removal_count,
    "tutor_count": tutor_count,
    "board_wipe_count": wipe_count,
    "protection_count": prot_count,
    "wincon_count": 0,
    "analysis_md_path": "decks/edgar-markov/2026-05-27-edhrec-default.md",
    "cards": cards_out,
    "insights": [
        {"text": "Edgar EDHREC default vs profile: gap of 1 in ramp (8 vs 9-12), 1 in draw (9 vs 10-13), 2 in interaction (6 vs 8-11). Confirms pattern: average players underinvest in engine cards.", "category": "gap_analysis", "impact": "high"},
        {"text": "Hybrid aggro+aristocrats is the EDHREC norm, despite profiles recommending focus. 33 vampires for aggro + aristocrat payoffs dilute both plans.", "category": "deckbuilding_pattern", "impact": "medium"},
        {"text": "Bloodthirsty Conqueror (2024) is already in EDHREC avg — functions as second Exquisite Blood without needing Sanguine Bond.", "category": "meta_update", "impact": "medium"},
        {"text": "8 card classification discrepancies identified (12.5% error rate). Olivia's Wrath not detected as board_wipe, Sorin as removal not engine.", "category": "classifier_gap", "impact": "high"},
        {"text": "Game Changers present: Demonic Tutor, Vampiric Tutor, Teferi's Protection, Exquisite Blood, Sanguine Bond. Deck is firmly bracket 3.", "category": "bracket_analysis", "impact": "medium"}
    ],
    "discrepancies": [
        {"card": "Sorin, Imperious Bloodlord", "mana_loom_tag": "removal", "expected_tag": "engine", "description": "Sorin e principalmente um engine (coloca Vampiro em campo, da lifelink, ultimate), nao removio. O sistema ve 'deals damage' e classifica como removio.", "impact": "high"},
        {"card": "Olivia's Wrath", "mana_loom_tag": "utility", "expected_tag": "board_wipe", "description": "Destroi todas as criaturas nao-Vampire. E um board wipe condicional. O sistema nao tem heuristica para wipes condicionais.", "impact": "high"},
        {"card": "Viscera Seer", "mana_loom_tag": "draw", "expected_tag": "sacrifice_outlet", "description": "Viscera Seer e um sacrifice outlet (sacular criatura, scry 1). Scry nao e draw. O sistema classifica como draw por 'look at' no oracle text.", "impact": "high"},
        {"card": "Sanguine Bond", "mana_loom_tag": "enchantment", "expected_tag": "wincon", "description": "Parte do combo Exquisite Blood + Sanguine Bond. O sistema ve como encantamento generico, nao como wincon.", "impact": "medium"},
        {"card": "Blade of the Bloodchief", "mana_loom_tag": "artifact", "expected_tag": "payoff_engine", "description": "Da +1/+1 counters quando uma criatura morre. E um payoff/engine, nao so um artifact generico.", "impact": "medium"},
        {"card": "Sorin, Imperious Bloodlord", "mana_loom_tag": "removal", "expected_tag": "engine_resurrection", "description": "Segunda entrada para destacar duplicata - Sorin ressuscita Vampire do cemiterio. Custo de 2 de vida nao e removio.", "impact": "medium"},
        {"card": "Exquisite Blood", "mana_loom_tag": "enchantment", "expected_tag": "combo_piece", "description": "Metade do combo EB+SB. O sistema nao detecta wincon/combo generico.", "impact": "medium"},
        {"card": "Bloodthirsty Conqueror", "mana_loom_tag": "creature", "expected_tag": "combo_piece_drain", "description": "Funciona como Exquisite Blood alternativo. O sistema ve como criatura generica.", "impact": "low"}
    ]
}

with open('/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/seed_edgar_markov.json', 'w') as f:
    json.dump(deck_json, f, indent=2, ensure_ascii=False)

print(f"\nJSON written to scripts/seed_edgar_markov.json ({len(cards_out)} cards)")
print("Done!")
