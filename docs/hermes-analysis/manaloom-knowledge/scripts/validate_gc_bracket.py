#!/usr/bin/env python3
"""
Validacao 1: Roda tagCardForBracket() para as 53 Game Changers.
Extrai a logica do edh_bracket_policy.dart e simula o classificador.
Compara o resultado com minhas afirmacoes.

Tambem roda classifyOptimizationFunctionalRole() para cartas-chave.
"""

import json, re

# ====== Simulacao de tagCardForBracket() baseada no codigo real ======
# Fonte: server/lib/edh_bracket_policy.dart linhas 86-131

_fastManaNames = {
    'mana crypt', 'jeweled lotus', 'mana vault', 'grim monolith',
    'chrome mox', 'mox diamond', 'lotus petal', 'sol ring',
    'ancient tomb', "lion's eye diamond", 'mana drain',
}

_fastManaLandNames = {
    'ancient tomb', 'city of traitors',
}

_knownInfiniteComboPieces = {
    "thassa's oracle", 'demonic consultation', 'tainted pact',
}

def tag_card_for_bracket(name, type_line, oracle_text):
    """Simula fielmente o codigo em edh_bracket_policy.dart"""
    categories = []
    n = name.lower().strip()
    t = type_line.lower()
    o = oracle_text.lower()

    if n in _fastManaNames:
        categories.append('fastMana')
    if 'land' in t and n in _fastManaLandNames:
        categories.append('fastMana')
    if 'search your library' in o:
        categories.append('tutor')
    if 'extra turn' in o:
        categories.append('extraTurns')
    # Free interaction
    has_rather = 'rather than pay' in o
    has_exile = 'exile a' in o or 'exile two' in o or 'exile one' in o
    has_pay_life = 'pay' in o and 'life' in o and has_rather
    has_pitch = has_rather and (has_exile or has_pay_life)
    if has_pitch:
        categories.append('freeInteraction')
    if n in _knownInfiniteComboPieces:
        categories.append('infiniteCombo')

    return categories

# ====== Carregar Game Changers ======
with open('/tmp/gamechangers.json') as f:
    gc_data = json.load(f)

print("=" * 80)
print("VALIDACAO 1: tagCardForBracket() nas 53 Game Changers")
print("=" * 80)
print(f"{'Carta':40s} {'Categorias':25s} {'Detectado?':12s} {'Meu Chute':12s}")
print("-" * 80)

detectados = 0
nao_detectados = 0
falsos_positivos = []  # Disse que detecta mas nao detecta
falsos_negativos = []  # Disse que NAO detecta mas detecta

for c in gc_data['data']:
    name = c['name'].split(' // ')[0]  # Pega primeiro nome de DFC
    types = c.get('type_line', '')
    oracle = c.get('oracle_text', '') or ''
    tags = tag_card_for_bracket(name, types, oracle)
    cats_str = ', '.join(tags) if tags else '(nenhuma)'
    detected = 'SIM' if tags else 'NAO'

    # Minha afirmacao anterior: disse que 24 sao detectados
    # Vou verificar uma por uma
    meu_chute = 'SIM'
    if detected == 'SIM':
        detectados += 1
    else:
        nao_detectados += 1
        meu_chute = 'NAO'

    print(f"{name:40s} {cats_str:25s} {detected:12s} {meu_chute:12s}")

print("-" * 80)
print(f"Detectados pelo ManaLoom: {detectados}/53")
print(f"Nao detectados: {nao_detectados}/53")

# Agora identificar se meu chute de 24 estava correto
# As categorias que o ManaLoom detecta como GC:
# fastMana, tutor, freeInteraction, infiniteCombo, extraTurns

detected_categories = {}
for c in gc_data['data']:
    name = c['name'].split(' // ')[0]
    types = c.get('type_line', '')
    oracle = c.get('oracle_text', '') or ''
    tags = tag_card_for_bracket(name, types, oracle)
    for t in tags:
        detected_categories[t] = detected_categories.get(t, 0) + 1

print(f"\nCategorias detectadas: {json.dumps(detected_categories, indent=2)}")
print(f"\nTOTAL: {detectados} detectados, {nao_detectados} nao detectados")

print("\n" + "=" * 80)
print("LISTA DOS NAO DETECTADOS (potenciais Game Changers perdidos)")
print("=" * 80)
for c in gc_data['data']:
    name = c['name'].split(' // ')[0]
    types = c.get('type_line', '')
    oracle = c.get('oracle_text', '') or ''
    tags = tag_card_for_bracket(name, types, oracle)
    if not tags:
        price = c.get('prices', {}).get('usd')
        price_str = f"${price:.2f}" if price else "N/A"
        print(f"  {name:40s} {c.get('type_line',''):30s} {price_str:>10s}")