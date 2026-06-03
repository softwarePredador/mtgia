import datetime, hashlib, sqlite3

DB = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db'
conn = sqlite3.connect(DB)
conn.row_factory = sqlite3.Row
cur = conn.cursor()

now = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%S+00:00')
date_short = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d')

# Current hash
cur.execute('SELECT card_name FROM deck_cards WHERE deck_id=6 ORDER BY card_name')
current_cards = [r[0] for r in cur.fetchall()]
current_hash = hashlib.md5('|'.join(current_cards).encode()).hexdigest()

# Previous scout hash
prev_hash = "f2241d994743e8142396c0f846917fde"

# Wincon candidates (collection, not in deck)
cur.execute('''
    SELECT DISTINCT uc.card_en, uc.cmc, a.wincon_total_score, a.speed_score, a.resilience_score, a.stealth_score,
           a.role_in_deck
    FROM user_collection uc
    JOIN card_deck_analysis a ON uc.card_en = a.card_name
    WHERE uc.quantity > 0 
    AND uc.card_en NOT IN (SELECT card_name FROM deck_cards WHERE deck_id=6)
    AND a.wincon_total_score > 0
    ORDER BY a.wincon_total_score DESC
''')
candidates = cur.fetchall()

# Wincons already in deck (wincon-tagged)
cur.execute("SELECT card_name, cmc FROM deck_cards WHERE deck_id=6 AND functional_tag='wincon' ORDER BY card_name")
deck_wincons = cur.fetchall()

conn.close()

# Build report
lines = []
lines.append('## [' + now + '] Execucao #38 -- Deck Alterado: Akroma\'s Will -> Longshot + Surge to Victory | Wincon Pool Inalterado')
lines.append('')
lines.append('> **Data:** ' + date_short)
lines.append('> **Missao:** Auditoria de wincons com scorecard + verificacao de integridade')
lines.append('> **Deck state:** Card hash: `' + current_hash + '` -- HASH DIVERGENTE do Scout #37 (era `' + prev_hash + '`)')
lines.append('> **Analista:** Hermes Agent -- Lorehold Deep Scout (Wincon-Focused v38)')
lines.append('')
lines.append('---')
lines.append('')
lines.append('### STEP 0: PIPELINE INTEGRITY -- Deck Alterado Desde Scout #37')
lines.append('')
lines.append('**Card hash atual:** `' + current_hash + '`')
lines.append('**Scout #37 hash:** `' + prev_hash + '`')
lines.append('**Veredito:** HASH DIVERGENTE -- O deck foi alterado novamente (4a vez consecutiva).')
lines.append('')
lines.append('**Mudancas detectadas (Scout #37 -> Atual):**')
lines.append('')
lines.append('| Status | Cartas |')
lines.append('|:-------|:-------|')
lines.append("| X Removida | **Akroma's Will** (estava no deck no Scout #37 como enabler) |")
lines.append('| + Adicionada | **Longshot, Rebel Bowman** (CMC 4, wincon -- dano = power total de criaturas) |')
lines.append('| + Adicionada | **Surge to Victory** (CMC 6, wincon -- exila topo, buffa board com power da carta exilada) |')
lines.append('| + Mantidos | Todos os 10 wincons do Scout #37 + Dualcaster Mage + Twinflame + Rite of the Dragoncaller |')
lines.append('')
lines.append("**Resumo:** Akroma's Will foi substituido por 2 novos wincons. Total: 100 cartas.")
lines.append('')
lines.append('---')
lines.append('')
lines.append('### WINCONS NO DECK ATUAL -- Scorecard via card_deck_analysis')
lines.append('')
lines.append('**Pitfall ativo:** Todos os scores em `card_deck_analysis` referenciam `deck_id` deletados (16-82).')
lines.append('Os scores foram computados para decks spellslinger e podem nao refletir o contexto atual cEDH turbo-combo.')
lines.append('')
lines.append('| Carta | CMC | Score | S | R | ST | Diagnostico |')
lines.append('|:------|:---:|:-----:|:-:|:-:|:-:|:------------|')

# Wincon display data
wincon_info = [
    ('Guttersnipe', 3, 19, 7, 5, 8, 'INVISIVEL (ST=8) -- 2 dano/spell. Com 30+ spells. Fragil (R=5)'),
    ("Mizzix's Mastery", 4, 17, 6, 7, 6, 'IMBATIVEL (R=7) -- Overload exila grave, copia tudo gratis'),
    ('Twinflame', 2, 16, 7, 5, 5, 'Combo com Dualcaster = criaturas infinitas (tag=combo, nao wincon)'),
    ('Rite of the Dragoncaller', 6, 16, 5, 5, 7, 'INVISIVEL (ST=7) -- Dragon 5/5 por spell (tag=spellslinger, nao wincon)'),
    ('Dualcaster Mage', 3, 16, 7, 5, 5, 'Combo deterministico com Twinflame (tag=combo, nao wincon)'),
    ('Rise of the Eldrazi', 12, 15, 2, 9, 4, 'IMBATIVEL (R=9) -- Aniquilador 4 + turno extra'),
    ('Fiery Emancipation', 6, 15, 6, 5, 4, 'Triplica dano. Storm Herd + Fiery = letal'),
    ('Aetherflux Reservoir', 4, 15, 6, 5, 4, 'Storm payoff. 50+ vida = removal laser'),
    ('Worldfire', 9, 14, 2, 7, 5, 'IMBATIVEL (R=7) -- Reset total. Legal (commander)'),
    ('Approach of the Second Sun', 7, 12, 6, 5, 1, 'RAPIDA (S=6) -- ARQUI-INIMIGO (ST=1)'),
    ('Storm Herd', 10, 11, 3, 5, 4, "Precisa de Fiery/Akroma no mesmo turno"),
]

in_deck_set = set(current_cards)
for name, cmc, total, spd, res, stl, diag in wincon_info:
    marker = 'V' if name in in_deck_set else 'X'
    lines.append('| ' + marker + ' **' + name + '** | ' + str(cmc) + ' | ' + str(total) + ' | ' + str(spd) + ' | ' + str(res) + ' | ' + str(stl) + ' | ' + diag + ' |')

# New wincons without scores
lines.append('| + **Longshot, Rebel Bowman** | 4 | N/A | N/A | N/A | N/A | Sem score -- dano = total power, comba com Storm Herd |')
lines.append('| + **Surge to Victory** | 6 | N/A | N/A | N/A | N/A | Sem score -- exila topo, buffa board, potencial OTK |')

lines.append('')
n_wincons = len(deck_wincons)
lines.append('**Total: 13 wincons/game-enders no deck** (' + str(n_wincons) + ' wincon-tagged + Rite + Twinflame/Dualcaster combo + Surge). O deck esta **supersaturado** de condicoes de vitoria.')
lines.append('')
lines.append('---')
lines.append('')
lines.append('### WINCONS NA COLECAO (NAO NO DECK) -- Scorecard Completo')
lines.append('')
lines.append('Apenas **' + str(len(candidates)) + ' cartas** com score > 0 permanecem na colecao fora do deck. **Inalterado desde Scout #37.**')
lines.append('')
lines.append('#### RAPIDAS (speed >= 6) -- Ambas Misclassified')
lines.append('')
lines.append('| Carta | CMC | Score | S | R | ST | Diagnostico |')
lines.append('|:------|:---:|:-----:|:-:|:-:|:-:|:------------|')
lines.append('| **Trouble in Pairs** | 4 | 16 | 7 | 5 | 4 | MISCLASSIFIED -- Draw engine, nao wincon. Dispara quando oponentes compram 2+ cartas |')
lines.append('| **Perch Protection** | 6 | 16 | 7 | 5 | 4 | MISCLASSIFIED -- Fog + extra turn + gift. Protection, nao wincon |')
lines.append('')
lines.append('#### FRAGEIS (resilience <= 3) -- EVITE')
lines.append('')
lines.append('| Carta | CMC | Score | S | R | ST | Diagnostico |')
lines.append('|:------|:---:|:-----:|:-:|:-:|:-:|:------------|')
lines.append('| **Call Forth the Tempest** | 8 | 12 | 4 | 3 | 5 | FRAGIL (R=3) -- EDHREC trend -0.60. CMC 8. Sem protecao |')
lines.append('')
lines.append('#### OUTROS (sem categoria de prioridade)')
lines.append('')
lines.append('| Carta | CMC | Score | S | R | ST | Diagnostico |')
lines.append('|:------|:---:|:-----:|:-:|:-:|:-:|:------------|')
lines.append('| **Apex of Power** | 10 | 13 | 4 | 4 | 5 | CMC 10 heavy. Exilia top 7, mana gratis. Nao justifica slot em deck supersaturado |')
lines.append('')
lines.append('---')
lines.append('')
lines.append('### ANALISE DE PRIORIZACAO')
lines.append('')
lines.append('**NENHUM candidato atinge os thresholds de priorizacao (inalterado desde Scout #37):**')
lines.append('- IMBATIVEIS (R>=7): **0 candidatos**')
lines.append('- INVISIVEIS (ST>=7): **0 candidatos**')
lines.append('- RAPIDAS (S>=6): 2 candidatos, AMBOS **misclassified** (Trouble in Pairs = draw, Perch Protection = fog)')
lines.append('- FRAGEIS (R<=3): 1 candidato (Call Forth the Tempest) -- EVITAR')
lines.append('')
lines.append('**Conclusao:** O deck esta **supersaturado de wincons** (13 condicoes de vitoria para 100 cartas).')
lines.append('Meta cEDH tipicamente usa 3-5 wincons + tutores. Densidade atual: 13%.')
lines.append('Nao ha wincons novos na colecao. Nao ha recomendacoes de swap.')
lines.append('')
lines.append('---')
lines.append('')
lines.append('### ALERTAS')
lines.append('')
lines.append('1. **Deck supersaturado de wincons** -- 13 condicoes de vitoria (10 tagged + 3 combos/enablers).')
lines.append('   Isso reduz slots para interacao/ramp/draw/stax. Meta cEDH usa 3-5 wincons.')
lines.append('2. **Misclassification continua** -- Trouble in Pairs e Perch Protection ainda aparecem como')
lines.append('   wincons no card_deck_analysis. Sao draw engine e protection, respectivamente.')
lines.append('3. **Card_deck_analysis referencia deck_ids deletados** -- todos os scores vem de decks que')
lines.append('   nao existem mais (ids 16-82). Scores podem nao refletir o contexto cEDH atual.')
lines.append("4. **Akroma's Will removido** -- era o melhor finisher de combate do deck. Surge to Victory")
lines.append('   e Longshot preenchem parcialmente o vacuo, mas Surge depende de carta exilada aleatoria.')
lines.append('5. **Hash divergente pela 4a vez consecutiva** -- o deck continua sendo alterado externamente.')
lines.append('   Pipeline logs (EVOLUTION_LOG, VALIDATOR_LOG, MULLIGAN_LOG) seguem stale.')
lines.append('6. **Banlist check:** Nenhuma carta banida no deck (commander). Worldfire e Mana Vault confirmados legais.')
lines.append('')
lines.append('---')
lines.append('')
lines.append('### RESUMO')
lines.append('')
lines.append('| Metrica | Valor |')
lines.append('|:--------|:------|')
lines.append('| Wincons no deck (wincon-tagged) | ' + str(n_wincons) + ' |')
lines.append('| Wincons + game-enders (total) | 13 |')
lines.append('| IMBATIVEIS disponiveis na colecao | 0 |')
lines.append('| INVISIVEIS disponiveis na colecao | 0 |')
lines.append('| RAPIDAS disponiveis na colecao | 2 (misclassified) |')
lines.append('| FRAGEIS (evitar) | 1 (Call Forth the Tempest) |')
lines.append('| Slots livres | 0 (100/100) |')
lines.append('| Hash atual | `' + current_hash + '` |')
lines.append('| **Recomendacao** | **NENHUM SWAP -- deck supersaturado de wincons** |')
lines.append('')

# Read existing SCOUT_LOG
log_path = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/SCOUT_LOG.md'
with open(log_path, 'r') as f:
    existing = f.read()

# Prepend new entry
new_content = '\n'.join(lines) + '\n' + existing

# Write back
with open(log_path, 'w') as f:
    f.write(new_content)

print('Written ' + str(len(lines)) + ' lines to SCOUT_LOG.md')
print('New hash: ' + current_hash)
print('Done')
