#!/usr/bin/env python3
"""
Validacao dos patches P0 propostos.
Mostra a classificacao ANTES (codigo atual) vs DEPOIS (codigo com patch).
"""

import re

# ==== LISTAS CURADAS (novas, adicionadas pelo patch) ====
_knownWinconNames = {
    'walking ballista', 'laboratory maniac', "thassa's oracle",
    'jace, wielder of mysteries', 'approach of the second sun',
    'craterhoof behemoth', 'torment of hailfire', 'exsanguinate',
    'aetherflux reservoir', 'finale of devastation',
}

_knownEngineNames = {
    "the one ring", 'thrasios, triton hero', 'kinnan, bonder prodigy',
    'seedborn muse', 'consecrated sphinx', 'necropotence',
    "bolas's citadel", 'mystic forge', 'future sight',
    "sensei's divining top", 'rhystic study', 'mystic remora', 'esper sentinel',
}

_knownProtectionNames = {
    'endurance',
    'giver of runes',
    'mother of runes',
    'selfless spirit',
    'dauntless bodyguard',
    'alley evader',
}

_knownComboPieceNames = {
    'basalt monolith', 'grim monolith', 'freed from the real',
    "pemmin's aura", 'dramatic reversal', 'isochron scepter',
    'underworld breach', "lion's eye diamond", 'demonic consultation',
    'tainted pact', 'hermit druid',
}

# ===== CODIGO ANTIGO (sem patch) =====
def classify_old(name, type_line, oracle):
    t = type_line.lower()
    o = oracle.lower()
    n = name.lower().strip()

    if 'land' in t: return 'land'
    if 'draw' in o or 'look at the top' in o or ('scry' in o and 'draw' in o): return 'draw'
    if ('destroy target' in o or 'exile target' in o or 'counter target' in o or
        ('return target' in o and 'to its owner' in o) or
        ('deals' in o and 'damage' in o and
         ('target creature' in o or 'target planeswalker' in o or 'any target' in o))):
        return 'removal'
    if ('destroy all' in o or 'exile all' in o or 'all creatures get -' in o or
        'each player sacrifices all' in o or 'damage to each creature' in o):
        return 'wipe'
    if ('add {' in o or 'mana of any' in o or 'create a treasure token' in o or
        'additional land this turn' in o or ('search your library' in o and ('land card' in o or 'basic land' in o))):
        return 'ramp'
    if 'search your library' in o and 'land' not in o: return 'tutor'
    if 'hexproof' in o or 'indestructible' in o or 'shroud' in o or 'ward' in o:
        return 'protection'
    if n in _knownProtectionNames:
        return 'protection'
    if 'creature' in t: return 'creature'
    if 'artifact' in t: return 'artifact'
    if 'enchantment' in t: return 'enchantment'
    if 'planeswalker' in t: return 'planeswalker'
    return 'utility'

# ===== CODIGO NOVO (com patch) =====
def classify_new(name, type_line, oracle):
    t = type_line.lower()
    o = oracle.lower()
    n = name.lower().strip()

    if 'land' in t: return 'land'

    # WINCON (novo, antes de removal)
    if 'you win the game' in o or n in _knownWinconNames:
        return 'wincon'

    # ENGINE (novo, antes de draw)
    if n in _knownEngineNames:
        return 'engine'

    # COMBO PIECE (novo)
    if n in _knownComboPieceNames:
        return 'combo_piece'

    if 'draw' in o or 'look at the top' in o or ('scry' in o and 'draw' in o):
        return 'draw'

    # REMOVAL (agora com excecao para counter-based wincons)
    if (('destroy target' in o or 'exile target' in o or 'counter target' in o or
         ('return target' in o and 'to its owner' in o) or
         ('deals' in o and 'damage' in o and
          ('target creature' in o or 'target planeswalker' in o or 'any target' in o))) and
        not ('remove a +1/+1 counter' in o or 'remove X +1/+1 counter' in o)):
        return 'removal'

    if ('destroy all' in o or 'exile all' in o or 'all creatures get -' in o or
        'each player sacrifices all' in o or 'damage to each creature' in o):
        return 'wipe'
    if ('add {' in o or 'mana of any' in o or 'create a treasure token' in o or
        'additional land this turn' in o or ('search your library' in o and ('land card' in o or 'basic land' in o))):
        return 'ramp'
    if 'search your library' in o and 'land' not in o: return 'tutor'
    if 'hexproof' in o or 'indestructible' in o or 'shroud' in o or 'ward' in o:
        return 'protection'
    if n in _knownProtectionNames:
        return 'protection'
    if 'creature' in t: return 'creature'
    if 'artifact' in t: return 'artifact'
    if 'enchantment' in t: return 'enchantment'
    if 'planeswalker' in t: return 'planeswalker'
    return 'utility'


# ===== CARTAS DE TESTE =====
test_cards = [
    # Do Kinnan deck
    ("Walking Ballista", "Artifact Creature — Construct",
     "{4}, Remove a +1/+1 counter from Walking Ballista: It deals 1 damage to any target.",
     "wincon"),
    ("Thrasios, Triton Hero", "Legendary Creature — Merfolk Wizard",
     "{4}: Scry 1, then reveal the top card of your library. If it's a land card, put it onto the battlefield tapped. Otherwise, draw a card.",
     "engine"),
    ("The One Ring", "Legendary Artifact",
     "Indestructible. When The One Ring enters, if you cast it, you gain protection from everything until your next turn. {T}: Put a burden counter, then draw a card for each burden counter.",
     "engine"),
    ("Basalt Monolith", "Artifact",
     "{T}: Add {C}{C}{C}.",
     "combo_piece"),
    ("Fierce Guardianship", "Instant",
     "If you control a commander, you may cast this spell without paying its mana cost. Counter target noncreature spell.",
     "removal"),
    ("Endurance", "Creature — Elemental",
     "Flash. When Endurance enters, shuffle any number of target cards from graveyards into their owners' libraries. Evoke—Exile a green card from your hand.",
     "protection"),
    # Additional edge cases
    ("Force of Will", "Instant",
     "You may pay 1 life and exile a blue card from your hand rather than pay this spell's mana cost. Counter target spell.",
     "removal"),
    ("Sol Ring", "Artifact", "{T}: Add {C}{C}.", "ramp"),
    ("Craterhoof Behemoth", "Creature — Beast",
     "Haste. When Craterhoof Behemoth enters, creatures you control gain +X/+X and trample until end of turn.",
     "wincon"),
    ("Underworld Breach", "Enchantment",
     "Each nonland card in your graveyard has escape. At the beginning of the end step, sacrifice this enchantment.",
     "combo_piece"),
]

expected_tags = {
    "Walking Ballista": "wincon",
    "Thrasios, Triton Hero": "engine",
    "The One Ring": "engine",
    "Basalt Monolith": "combo_piece",
    "Fierce Guardianship": "removal",
    "Endurance": "protection",
    "Force of Will": "removal",
    "Sol Ring": "ramp",
    "Craterhoof Behemoth": "wincon",
    "Underworld Breach": "combo_piece",
}

print("=" * 95)
print("VALIDACAO DOS PATCHES: ANTES vs DEPOIS")
print("=" * 95)
print(f"{'Carta':30s} {'Antes':12s} {'Depois':12s} {'Esperado':12s} {'Old?':6s} {'New?':6s}")
print("-" * 95)

old_correct = 0
new_correct = 0
total = len(test_cards)

for name, tl, oracle, expected in test_cards:
    old_tag = classify_old(name, tl, oracle)
    new_tag = classify_new(name, tl, oracle)
    exp = expected_tags[name]
    old_ok = "OK" if old_tag == exp else "ERR"
    new_ok = "OK" if new_tag == exp else "ERR"
    if old_tag == exp: old_correct += 1
    if new_tag == exp: new_correct += 1
    print(f"{name:30s} {old_tag:12s} {new_tag:12s} {exp:12s} {old_ok:6s} {new_ok:6s}")

print("-" * 95)
print(f"Precisao ANTES do patch: {old_correct}/{total} ({100*old_correct//total}%)")
print(f"Precisao DEPOIS do patch: {new_correct}/{total} ({100*new_correct//total}%)")
print(f"Melhoria: +{new_correct - old_correct} cartas classificadas corretamente")
print()

# Destaque das correcoes
print("=" * 95)
print("CORRECOES ESPECIFICAS:")
print("=" * 95)
for name, tl, oracle, expected in test_cards:
    old_tag = classify_old(name, tl, oracle)
    new_tag = classify_new(name, tl, oracle)
    if old_tag != new_tag:
        print(f"  {name:30s} {old_tag:12s} -> {new_tag:12s} (correto: {expected_tags[name]})")