#!/usr/bin/env python3
"""
Validacao 2: classifica as cartas do Kinnan deck usando a logica
real do optimization_functional_roles.dart + functional_card_tags.dart
e compara com o que eu afirmei.
"""

import re

# ====== Simulacao de classifyOptimizationFunctionalRole() ======
# Baseado em server/lib/ai/optimization_functional_roles.dart

def looks_like_board_wipe(oracle):
    o = oracle.lower()
    own_only = 'all creatures you control' in o or 'each creature you control' in o
    combat_dmg = 'assigns combat damage' in o
    if own_only or combat_dmg:
        return False
    return ('destroy all' in o or 'exile all' in o or
            'all creatures get -' in o or 'all colored permanents' in o or
            'each player sacrifices all' in o or
            'each opponent sacrifices all' in o or
            'damage to each creature' in o or
            ('deals' in o and 'damage' in o and 'to each creature' in o))

def looks_like_ramp(oracle):
    o = oracle.lower().replace('search you library', 'search your library')
    if ('add {' in o or
            re.search(r'\badds?\b[^.\n]{0,96}\bmana of any(?:\s+one)?\b', o)):
        return True
    search_index = o.find('search your library')
    battlefield_index = o.find('onto the battlefield', search_index)
    next_paragraph = o.find('\n', search_index)
    if (search_index >= 0 and battlefield_index >= 0 and
            (next_paragraph < 0 or battlefield_index < next_paragraph) and
            ('land card' in o or 'basic land' in o)):
        return True
    return ('additional land this turn' in o or
            'additional land on each of your turns' in o or
            (('spells you cast cost' in o and 'less to cast' in o) or
             re.search(r'\bspells you cast\b[^.\n]{0,64}\bcost\b[^.\n]{0,32}\bless to cast\b', o)) or
            'put a land card from your hand onto the battlefield' in o or
            'create a treasure token' in o or 'create two treasure tokens' in o or
            'create three treasure tokens' in o or
            'creates a treasure token' in o or
            'spells you cast have convoke' in o or
            'create a birds of paradise token' in o or
            'has all activated abilities of all lands' in o or
            ('mana counter' in o and
             re.search(r'\b(?:can|may) spend mana of any color\b[^.\n]{0,48}\bequal to the number of mana counters\b', o)))

def classify_role(name, type_line, oracle_text):
    """Simula classifyOptimizationFunctionalRole() fielmente"""
    t = type_line.lower()
    o = oracle_text.lower()
    name = name.lower().strip()
    
    if 'land' in t:
        return 'land'
    
    if 'draw' in o or 'look at the top' in o or ('scry' in o and 'draw' in o):
        return 'draw'
    
    if ('destroy target' in o or 'exile target' in o or 'counter target' in o or
        ('return target' in o and 'to its owner' in o) or
        ('deals' in o and 'damage' in o and 
         ('target creature' in o or 'target planeswalker' in o or 'any target' in o))):
        return 'removal'
    
    if looks_like_ramp(o):
        return 'ramp'
    
    if looks_like_board_wipe(o):
        return 'board_wipe'
    
    if 'search your library' in o:
        return 'tutor'
    
    if 'protection' in o and ('you' in o or 'commander' in o or 'creature' in o):
        return 'protection'
    
    if 'extra turn' in o:
        return 'extra_turn'
    
    if 'sacrifice' in o and 'draw' in o:
        return 'draw'
    
    return 'other'

# Cards do deck Kinnan para testar
kinnan_cards = [
    ("Basalt Monolith", "Artifact", "{T}: Add {C}{C}{C}.", 3),
    ("Walking Ballista", "Artifact Creature — Construct", "Walking Ballista enters with X +1/+1 counters on it. {4}, Remove a +1/+1 counter from Walking Ballista: It deals 1 damage to any target.", 0),
    ("Thrasios, Triton Hero", "Legendary Creature — Merfolk Wizard", "{4}: Scry 1, then reveal the top card of your library. If it's a land card, put it onto the battlefield tapped. Otherwise, draw a card.", 2),
    ("Sol Ring", "Artifact", "{T}: Add {C}{C}.", 1),
    ("Chrome Mox", "Artifact", "Imprint — When this artifact enters, you may exile a nonartifact, nonland card from your hand. {T}: Add one mana of any of the exiled card's colors.", 0),
    ("Force of Will", "Instant", "You may pay 1 life and exile a blue card from your hand rather than pay this spell's mana cost. Counter target spell.", 5),
    ("Fierce Guardianship", "Instant", "If you control a commander, you may cast this spell without paying its mana cost. Counter target noncreature spell.", 3),
    ("Rhystic Study", "Enchantment", "Whenever an opponent casts a spell, you may draw a card unless that player pays {1}.", 3),
    ("The One Ring", "Legendary Artifact", "Indestructible. When The One Ring enters, if you cast it, you gain protection from everything until your next turn. At the beginning of your upkeep, you lose 1 life for each burden counter on The One Ring. {T}: Put a burden counter on The One Ring, then draw a card for each burden counter on The One Ring.", 4),
    ("Gaea's Cradle", "Legendary Land", "{T}: Add {G} for each creature you control.", 0),
    ("Birds of Paradise", "Creature — Bird", "Flying. {T}: Add one mana of any color.", 1),
    ("Endurance", "Creature — Elemental", "Flash. When Endurance enters, shuffle any number of target cards from graveyards into their owners' libraries. Evoke—Exile a green card from your hand.", 3),
    ("Chord of Calling", "Instant", "Convoke. Search your library for a creature card with mana value X or less, put it onto the battlefield, then shuffle.", 3),
]

print("=" * 80)
print("VALIDACAO 2: classifyOptimizationFunctionalRole() para cartas do Kinnan")
print("=" * 80)
print(f"{'Carta':35s} {'Tag Real':15s} {'Meu Chute':15s} {'Match?':8s}")
print("-" * 80)

# Minhas afirmacoes anteriores (do seed_kinnan.json)
my_claims = {
    "Basalt Monolith": "ramp",
    "Walking Ballista": "wincon",
    "Thrasios, Triton Hero": "engine",
    "Sol Ring": "ramp",
    "Chrome Mox": "ramp",
    "Force of Will": "removal",
    "Fierce Guardianship": "protection",
    "Rhystic Study": "draw",
    "The One Ring": "engine",
    "Gaea's Cradle": "land",
    "Birds of Paradise": "ramp",
    "Endurance": "protection",
    "Chord of Calling": "tutor",
}

matches = 0
mismatches = []

for name, type_line, oracle, cmc in kinnan_cards:
    real_tag = classify_role(name, type_line, oracle)
    my_tag = my_claims.get(name, "?")
    match = "OK" if real_tag == my_tag else "DIF"
    if real_tag == my_tag:
        matches += 1
    else:
        mismatches.append((name, real_tag, my_tag))
    print(f"{name:35s} {real_tag:15s} {my_tag:15s} {match:8s}")

print("-" * 80)
print(f"Acertos: {matches}/{len(kinnan_cards)}")

if mismatches:
    print(f"\nDISCREPANCIAS REAIS (nao hipoteticas):")
    print(f"{'Carta':35s} {'Tag Real':15s} {'Meu Chute':15s} {'Correcao':15s}")
    print("-" * 80)
    for name, real, my in mismatches:
        # Sugerir correcao
        corrections = {
            "Walking Ballista": "other (ou 'draw' se oracle trigger?) — sistema nao tem 'wincon'",
            "Thrasios, Triton Hero": "draw (scry+draw trigger ativado)",
            "Fierce Guardianship": "removal (counter target spell)",
            "The One Ring": "draw? or other?",
            "Gaea's Cradle": "land (correto, mas perde contexto de super-ramp)",
            "Endurance": "other (nem removal, nem protection — 'shuffle' nao e tag)",
        }
        corr = corrections.get(name, "—")
        print(f"{name:35s} {real:15s} {my:15s} {corr:15s}")

print("\n" + "=" * 80)
print("CONCLUSOES:")
print("=" * 80)

# Ler minhas discrepancias hipoteticas do seed
my_discrepancies = [
    ("Basalt Monolith", "ramp", "combo_piece", "Tag composta ausente"),
    ("Fierce Guardianship", "removal", "protection", "Classificado como removal"),
    ("Gaea's Cradle", "land", "ramp", "Perde contexto de qualidade"),
    ("Thrasios (no 99)", "engine", "wincon", "Outlet de mana infinita"),
    ("Force of Will", "removal", "protection", "Counter classificado como removal"),
]

print("\nMinhas 5 discrepancias hipoteticas vs Realidade:")
print(f"{'Carta':35s} {'Hipotese':20s} {'Real':20s} {'Veredito':15s}")
print("-" * 90)
for card, hyp, exp, desc in my_discrepancies:
    # Verificar qual a tag REAL
    real_tag = "?"
    for n, tl, o, cmc in kinnan_cards:
        if n.startswith(card.split(" ")[0]):
            real_tag = classify_role(n, tl, o)
            break
    if card == "Thrasios (no 99)":
        real_tag = classify_role("Thrasios, Triton Hero", 
            "Legendary Creature — Merfolk Wizard",
            "{4}: Scry 1, then reveal the top card of your library. If it's a land card, put it onto the battlefield tapped. Otherwise, draw a card.")
    
    verdict = "CONFIRMADA" if (hyp != real_tag) else "ERRADA"
    print(f"{card:35s} {hyp:20s} {real_tag:20s} {verdict:15s}")
