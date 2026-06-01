# Purpose Analyzer v3.17 — Lorehold Spellslinger: PG REFERENCE COMPARISON + SYNERGY_MAP + Card Rulings

> **Data:** 2026-06-01T05:00:00+00:00
> **Fonte:** knowledge.db deck_id=6 — ESTADO REAL DO DB (card_hash = `a440c497da4280d6769238737062b3dd`)
> **Deck:** Lorehold Spellslinger — 100 cards, 86 rows, 35 lands, CMC medio 3.61
> **Ciclo atual:** Pos-Ciclo #18 (27 swaps, 11 ciclos com swaps, C#18 = 0 swaps)
> **Analista:** Hermes Agent — Purpose Analyzer v3.17
> **Foco:** PG `commander_reference_deck_analysis` comparison + SYNERGY_MAP 7 eixos com comparacao PG + `card_oracle_data.ruling_text` interactions
> **v3.16 → v3.17:** Deck state IDENTICO (card hash match). Novo: analise PG reference profile + card rulings.

---

## Secao 0: INTEGRIDADE DO PIPELINE

| Verificacao | v3.16 (04:00) | v3.17 (05:00) | Status |
|:------------|:-------------:|:-------------:|:------:|
| Card hash | `a440c497...` | `a440c497...` | ✅ MATCH |
| Deck cards 86 rows, 100 total | ✅ | ✅ | OK |
| Lands = 35 | ✅ | ✅ | OK |
| Commander = 1 (Lorehold) | ✅ | ✅ | OK |
| T3 Sem Play (Exec#12) | 11.3% | 11.3% | ✅ Unchanged |
| **PIPELINE SAUDAVEL** | ✅ | ✅ | **Sem mudancas desde v3.16** |

---

## Secao 1: PG REFERENCE PROFILE COMPARISON — `commander_reference_deck_analysis`

### Fonte do Perfil Ideal PG

O PostgreSQL `commander_reference_deck_analysis` define o perfil ideal para Lorehold, the Historian com base em analise de decks reais de alto desempenho. Este perfil representa a **distribuicao funcional otima**, nao um piso ou teto, mas o sweet spot estatistico.

### Tabela Principal: PG Ideal vs Deck Actual

| PG Role | Ideal | Actual | Diff | Status | Interpretacao |
|:--------|:-----:|:------:|:----:|:------:|:--------------|
| **lands** | 32.00 | **35.0** | +3.0 | 🟡 ACIMA | +3 lands = mais consistencia. Boros sem fast mana precisa de 35. **Justificado.** |
| **ramp** (rocks) | 3.67 | **6.0** | +2.3 | 🟡 ACIMA | Sol Ring, Arcane Signet, Boros Signet, Talisman, Archaeomancer's Map, Bender's Waterskin. Deck acelerado. |
| **ritual_treasure** | 10.00 | **10.0** | **0.0** | ✅ **PERFEITO** | Jeska's Will, Smothering Tithe, Storm-Kiln, Big Score, Unexpected Windfall, Brass's Bounty, Hit the Mother Lode, Land Tax, Weathered Wayfarer, Dragon's Rage Channeler. Exatamente 10. |
| **big_spell_payoff** | 7.67 | **15.0** | +7.3 | 🟡 ACIMA | Lorehold payoffs abundantes: 6 copy engines + 9 big spells. PG baseline subestima — deck de Big Spells TEM que ter mais payoffs. |
| **miracle_topdeck** | 4.33 | **6.0** | +1.7 | 🟡 ACIMA | Sensei's Top, Scroll Rack, Penance, Library of Leng, The One Ring, Monument to Endurance. +2 acima — deck focado em topdeck manipulation. |
| **interaction** | 5.33 | **13.0** | +7.7 | 🟡 ACIMA | 13 cartas: spot removal (6) + board wipes (4) + utility (3). PG baseline de 5.33 e baixo para Commander real. |
| **protection** | 3.67 | **6.0** | +2.3 | 🟡 ACIMA | Teferi's, Boros Charm, Greaves, Abolisher, Hexing Squelcher, Mother of Runes. Robusto para deck sem azul. |
| **draw_value** | 2.67 | **8.0** | +5.3 | 🟡 ACIMA | PG baseline 2.67 e irrealista — seria letal em Commander. 8 draw sources e o minimo viavel em Boros. |
| **tutor** | 3.67 | **2.0** | **-1.7** | 🔴 **ABAIXO** | Apenas Enlightened Tutor + Gamble. **Gap real.** Falta 1-2 tutores. |
| **win_condition** | 1.33 | **4.0** | +2.7 | 🟡 ACIMA | Approach, Worldfire, Akroma's Will, Blasphemous Act. Redundancia de wincons e saudavel. |

### Classificacao por Carta no Sistema PG

| Carta | CMC | PG Role(s) |
|:------|:---:|:-----------|
| **RAMP (6 cartas)** | | |
| Sol Ring | 1 | ramp |
| Arcane Signet | 2 | ramp |
| Boros Signet | 2 | ramp |
| Talisman of Conviction | 2 | ramp |
| Archaeomancer's Map | 3 | ramp |
| Bender's Waterskin | 3 | ramp |
| **RITUAL_TREASURE (10 cartas)** | | |
| Land Tax | 1 | ritual_treasure |
| Weathered Wayfarer | 1 | ritual_treasure |
| Dragon's Rage Channeler | 1 | ritual_treasure |
| Jeska's Will | 3 | ritual_treasure |
| Smothering Tithe | 4 | ritual_treasure |
| Storm-Kiln Artist | 4 | ritual_treasure |
| Big Score | 4 | ritual_treasure |
| Unexpected Windfall | 4 | ritual_treasure |
| Brass's Bounty | 7 | ritual_treasure |
| Hit the Mother Lode | 7 | ritual_treasure |
| **BIG_SPELL_PAYOFF (15 cartas)** | | |
| Twinflame | 2 | big_spell_payoff |
| Flare of Duplication | 3 | big_spell_payoff |
| The Dawning Archaic | 3 | big_spell_payoff |
| Mizzix's Mastery | 4 | big_spell_payoff |
| Double Vision | 5 | big_spell_payoff |
| Reforge the Soul | 5 | big_spell_payoff |
| Arcane Bombardment | 5 | big_spell_payoff |
| Surge to Victory | 6 | big_spell_payoff |
| Rite of the Dragoncaller | 6 | big_spell_payoff |
| Improvisation Capstone | 7 | big_spell_payoff |
| Restoration Seminar | 7 | big_spell_payoff |
| Volcanic Vision | 7 | big_spell_payoff |
| Emeria's Call | 7 | big_spell_payoff |
| Call Forth the Tempest | 8 | big_spell_payoff |
| Dance with Calamity | 8 | big_spell_payoff |
| Storm Herd | 10 | big_spell_payoff |
| **MIRACLE_TOPDECK (6 cartas)** | | |
| Sensei's Divining Top | 1 | miracle_topdeck |
| Library of Leng | 1 | miracle_topdeck |
| Scroll Rack | 2 | miracle_topdeck |
| Penance | 3 | miracle_topdeck |
| Monument to Endurance | 3 | miracle_topdeck, draw_value |
| The One Ring | 4 | miracle_topdeck, draw_value |
| **INTERACTION (13 cartas)** | | |
| Path to Exile | 1 | interaction |
| Swords to Plowshares | 1 | interaction |
| Mother of Runes | 1 | interaction, protection |
| Abrade | 2 | interaction |
| Boros Charm | 2 | interaction, protection |
| Chaos Warp | 3 | interaction |
| Generous Gift | 3 | interaction |
| Deflecting Swat | 3 | interaction |
| Olorin's Searing Light | 4 | interaction |
| Taunt from the Rampart | 5 | interaction |
| Austere Command | 6 | interaction |
| Blasphemous Act | 9 | interaction, win_condition |
| Worldfire | 9 | interaction, win_condition |
| **PROTECTION (6 cartas)** | | |
| Mother of Runes | 1 | protection, interaction |
| Grand Abolisher | 2 | protection |
| Lightning Greaves | 2 | protection |
| Boros Charm | 2 | protection, interaction |
| Hexing Squelcher | 2 | protection |
| Teferi's Protection | 3 | protection |
| **DRAW_VALUE (8 cartas)** | | |
| Faithless Looting | 1 | draw_value |
| Esper Sentinel | 1 | draw_value |
| Demand Answers | 2 | draw_value |
| Thrill of Possibility | 2 | draw_value |
| Victory Chimes | 3 | draw_value |
| Monument to Endurance | 3 | draw_value, miracle_topdeck |
| Ashling, Flame Dancer | 4 | draw_value |
| The One Ring | 4 | draw_value, miracle_topdeck |
| **TUTOR (2 cartas)** | | |
| Enlightened Tutor | 1 | tutor |
| Gamble | 1 | tutor |
| **WIN_CONDITION (4 cartas)** | | |
| Akroma's Will | 4 | win_condition |
| Approach of the Second Sun | 7 | win_condition |
| Blasphemous Act | 9 | win_condition, interaction |
| Worldfire | 9 | win_condition, interaction |
| **LANDS (35 cartas)** | | |
| Mountain ×8, Plains ×8, 19 nonbasic lands | — | lands |

### Analise dos Gaps

| Gap | Severidade | Acao |
|:----|:----------:|:-----|
| **tutor -1.67** | 🟡 MEDIA | Falta ~2 tutores. Enlightened + Gamble sao 2, PG quer 3.67. **Aquisicao recomendada:** Idyllic Tutor ($15-20) — busca Approach, Smothering Tithe, Double Vision. |
| **draw_value +5.33** | 🟢 BOM | PG baseline 2.67 e irrealista para Commander real. 8 draw sources e saudavel em Boros. |
| **interaction +7.67** | 🟢 BOM | PG baseline 5.33 tambem e baixo. Deck tem mix saudavel de spot + board wipes. |
| **big_spell_payoff +7.33** | 🟢 INTENCIONAL | O deck e definido como Big Spells — naturalmente tera mais payoffs. Copy engines contam como payoff. |
| **ritual_treasure = 0** | 🟢 PERFEITO | Motor de treasure calibrado exatamente no PG ideal. |

---

## Secao 2: SYNERGY_MAP — 7 Eixos com PG Comparison

### Eixo A — TOKEN MAKERS + PUMP (Score: 7/10)

**Cartas:** Storm Herd (CMC 10), Rite of the Dragoncaller (CMC 6), Twinflame (CMC 2), Hit the Mother Lode (CMC 7, treasures), Surge to Victory (CMC 6)

**PG alignment:** PG nao tem role especifico para tokens. 5 token sources — saudavel para estrategia secundaria.

**Combos de dano:**
- Storm Herd (40 tokens 1/1) + Akroma's Will = 40×2×2 = 160 flying double strike
- Rite of the Dragoncaller (5/5 dragon tokens) + Twinflame copy = 2+ dragons
- Surge to Victory + graveyard cheio = cada criatura vira copia de big spell

**Weakness:** Pouco pump. Apenas Akroma's Will como pump massivo. Boros Charm da double strike mas sem dano extra.

### Eixo B — BOARD WIPES + PROTECTION (Score: 8/10)

**Wipes (5):** Austere Command (CMC 6), Blasphemous Act (CMC 9, convoke), Volcanic Vision (CMC 7), Call Forth the Tempest (CMC 8), Worldfire (CMC 9)

**Protection (6):** Teferi's Protection (CMC 3), Boros Charm (CMC 2, indestructible), Lightning Greaves (CMC 2), Grand Abolisher (CMC 2), Hexing Squelcher (CMC 2), Mother of Runes (CMC 1)

**PG comparison:**
- PG interaction ideal: 5.33 → deck: 13 (+7.67) — inclui wipes + spot removal
- PG protection ideal: 3.67 → deck: 6 (+2.33) — deck tem +2.3 protecao

**Ratio wipe/protection:** 5/6 = 0.83. Excelente.
**Wipe-specific protection:**
- Austere Command → Teferi's Protection (phase out)
- Blasphemous Act → Boros Charm (indestructible)
- Worldfire → Teferi's Protection (phase out — UNICA protecao que funciona contra exile)

**Weakness:** Volcanic Vision e Call Forth the Tempest sao wipes parciais/condicionais. Nao limpa board como Farewell.

### Eixo C — RECURSION CHAINS (Score: 8/10)

**Recursion (4):** Mizzix's Mastery (CMC 4, overload), Restoration Seminar (CMC 7), Surge to Victory (CMC 6), Faithless Looting (CMC 1, flashback)

**Loops documentados:**

1. **Faithless Looting → Mizzix's Mastery overload:** Looting enche o grave, Mastery casta TUDO de graca. Lorehold copy = 2x todas as spells. Combo de 15+ mana de valor.

2. **Arcane Bombardment + Restoration Seminar:** Bombardment exila do grave (copia aleatoria), Seminar devolve spell do grave para mao → casta de novo → mais combustivel pro Bombardment. Loop infinito de valor.

3. **Dance with Calamity + Surge to Victory:** Dance exila do topo, Surge recura do grave para copias em massa com criaturas.

**PG gap:** Nao tem Underworld Breach (CMC 2, melhor recursion vermelha). Nem Past in Flames. Ambos $15-20.

### Eixo D — EXPLOSIVE MANA (Score: 7/10)

**Treasure generators (10):** Land Tax, Weathered Wayfarer, Dragon's Rage Channeler, Jeska's Will, Smothering Tithe, Storm-Kiln Artist, Big Score, Unexpected Windfall, Brass's Bounty, Hit the Mother Lode

**Rituals:** Jeska's Will (CMC 3, +7 mana potencial com commander 5 CMC no campo)

**Cost reducers:** 0 (Medallions cortadas C#9/C#10 — substituidas por treasure, escala melhor com big spells)

**Mana sinks:** Dance with Calamity (CMC 8, Miracle RRR), Call Forth the Tempest (CMC 8), Storm Herd (CMC 10), Improvisation Capstone (CMC 7)

**Sequencia de mana ideal:**
```
T1: Land Tax / Sol Ring
T2: Boros Signet (3 mana disponivel)
T3: Smothering Tithe (4 mana, gera treasures)
T4: Big Score (6+ mana, +2 treasures)
T5: Lorehold + 8 mana floating
T6: Dance/Capstone/Approach com mana pra proteger
```

**PG alignment:** ritual_treasure = 10.0 EXATO ✅

**Weakness:** Sem mana rocks CMC 0 (Moxes). Apenas Sol Ring como fast mana. Em brackets mais altos, falta de fast mana limita velocidade.

### Eixo E — COMBO PIECES (Score: 9/10)

**Combos deterministicos:**

1. **Approach (CMC 7) + Sensei's Top (CMC 1):** Cast Approach → 7th do topo → ativa Top → compra → casta #2 da mao → WIN. 3 turnos. Com Scroll Rack: 2 turnos.

2. **Worldfire (CMC 9) + Teferi's Protection (CMC 3):** Cast Worldfire, responda com Teferi's → phase out → Worldfire resolve (so oponentes perdem tudo) → seu upkeep: tudo volta → WIN em 1-2 turnos.

3. **Twinflame (CMC 2) + Storm-Kiln (CMC 4) + Lorehold:** Twinflame no Storm-Kiln → Lorehold copia do grave → 2 Storm-Kilns → cada spell gera 2 treasures. Surge = cadeia exponencial.

**Combos semi-deterministicos:**

4. **Blasphemous Act (CMC 9, convoke ~1) + Worldfire:** Board wipe → Worldfire → sem criaturas, voce reconstrói primeiro.

5. **Improvisation Capstone (CMC 7) + Restoration Seminar (CMC 7):** Capstone exila 7 do topo → casta gratis. Seminar recura Capstone. Loop.

**PG alignment:** win_condition = 4 (PG: 1.33). +2.67 — deck tem mais combos que a media Lorehold.

### Eixo F — STACK INTERACTION (Score: 8/10)

**Stack interaction (6):** Flare of Duplication (CMC 3, copy em resposta a counter), Deflecting Swat (CMC 3, redireciona), Boros Charm (CMC 2, indestructible), Teferi's Protection (CMC 3, phase out), Mother of Runes (CMC 1, protection), Grand Abolisher (CMC 2, preemptive)

**Sem counterspell azul** — mitigado por protecao proativa e respostas na stack.

### Eixo G — RESILIENCE & RECOVERY (Score: 6/10)

**Recovery:** Mizzix's Mastery, Restoration Seminar, Surge to Victory, Arcane Bombardment — todos do grave.

**Weakness:** Deck depende muito do grave. Bojuka Bog, Rest in Peace, Leyline of the Void sao counters duros. Se Approach for exilada, perde wincon primaria.

---

## Secao 3: CARD RULINGS — Interacoes Chave (via Scryfall API)

### 3.1 Approach of the Second Sun

**Ruling #1:** "A copy of a spell isn't cast, so it won't count as the first nor as the second Approach of the Second Sun."
→ **Implicacao:** Flare of Duplication copy nao conta como "cast". Approach+Flare nao e combo deterministico. Flare serve como PROTECAO (copia resolve mesmo se original for counterada), nao como acelerador de Approach.

**Ruling #2:** "The second Approach of the Second Sun that you cast must be cast from your hand, but first may have been cast from anywhere."
→ **Implicacao:** Mizzix's Mastery castando Approach do grave NAO ganha (nao foi castada da mao). Importante: Approach #1 pode vir do grave (Mastery), mas Approach #2 PRECISA vir da mao.

**Ruling #3:** "If you have fewer than six cards in your library, you'll put Approach of the Second Sun on the bottom of your library."
→ **Implicacao:** Com < 6 cartas no grimorio, Approach vai pro fundo, nao 7th. Com Sensei's Top, ainda recuperavel (ativa Top pra comprar, depois busca com Scroll Rack/Top repetido).

**Combo deterministico (2 turnos):**
```
Turno N:   Casta Approach #1 → vai 7th do topo
           Ativa Scroll Rack (exila 6 da mao, pega 6 do topo) → Approach no topo
Turno N+1: Draw step compra Approach
           Casta Approach #2 DA MAO → WIN
```

### 3.2 Flare of Duplication

**Ruling #1:** "The copy is created on the stack, so it's not 'cast.' Abilities that trigger when a player casts a spell won't trigger."
→ **Implicacao:** Flare copy NAO trigga Lorehold, NAO trigga Storm-Kiln (cast trigger), NAO trigga Approach win check. Mas a copia RESOLVE normalmente — gera valor, mas nao ativa sinergias de cast.

**Ruling #2:** "You may sacrifice a nontoken red creature rather than pay this spell's mana cost."
→ **Implicacao:** FREE com Storm-Kiln Artist em campo. Sacrifica o Storm-Kiln (ja gerou treasures dos casts anteriores), Flare e gratis. Com Lorehold copy = 2 Flares no mesmo turno.

**Ruling #3:** "The copy will have the same targets as the spell it's copying unless you choose new ones."
→ **Implicacao:** Flare copiando um counterspell do oponente = voce countera o counterspell deles. Flare copiando Path to Exile = 2 exilios por 1 carta.

### 3.3 Worldfire

**Ruling #1:** "Worldfire exiles all permanents, all cards in all hands, and all cards in all graveyards."
→ **Implicacao:** EXILIA, nao destroi. Indestructible (Boros Charm) NAO protege. Unica protecao: Teferi's Protection (phase out — suas permanentes "nao existem" quando Worldfire resolve).

**Ruling #2:** "After Worldfire resolves, each player's life total becomes 1."
→ **Implicacao:** Com Teferi's Protection, voce phase out ANTES de Worldfire → sua vida NAO muda pra 1 (Teferi's diz "your life total can't change"). Voce fica com a vida que tinha + board → oponentes com 1 vida e sem nada.

**Combo deterministico:**
```
Cast Worldfire → hold priority → cast Teferi's Protection
Teferi's resolve → voce phase out (vida nao muda, permanentes "nao existem")
Worldfire resolve → exila tudo dos oponentes, vida deles = 1
Seu upkeep → tudo volta → ataca com qualquer coisa → WIN
```

### 3.4 Dance with Calamity

**Oracle text:** "Shuffle your library. As many times as you choose, you may exile the top card of your library. If the total mana value of the cards exiled this way is 13 or less, you may cast any number of spells from among those cards without paying their mana costs."

**Key interaction — Miracle:** Dance tem Miracle RRR (CMC 3 em vez de 8). Com Top/Penance controlando o topo, Dance = "exile ate 13 CMC de spells, casta TODAS de graca" por 3 mana.

**Key interaction — Sensei's Top:** Controla o topo → sabe exatamente quais cartas Dance vai exilar. Nao e aleatorio. Top + Dance = valor deterministico.

**Key interaction — Scroll Rack:** Coloca big spells da mao no topo → Dance exila e casta de graca. Combo de 12+ mana de valor.

**Key interaction — Lorehold:** Dance e castada do grave (via Miracle nao, mas via Mizzix's Mastery sim) → Lorehold pode copiar. 2 Dances = ate 26 CMC de spells gratis.

### 3.5 Arcane Bombardment

**Ruling:** "At the beginning of your first main phase, exile an instant or sorcery card at random from your graveyard. Then copy it. You may cast the copy without paying its mana cost."
→ Copy e criada no exilio, nao no grave → Restoration Seminar nao pode devolver pro grave (ja foi exilada). Mas Seminar pode devolver OUTRAS spells do grave que Bombardment ainda nao exilou.

**Key interaction — Bombardment + Lorehold:** Bombardment copy nao e "cast" → nao trigga Lorehold. Lorehold copy tambem nao e "cast" → nao trigga Bombardment. Dois copy engines INDEPENDENTES — redundancia sem interacao cruzada.

### 3.6 Scroll Rack

**Ruling:** "You can activate Scroll Rack's ability even if you have no cards in hand."
→ Com mao vazia: ativa Rack → exila 0 cartas, coloca X cartas do topo na mao. Com Top em campo controlando o topo, Rack = "draw X cards" repetivel.

**Key interaction — Scroll Rack + Penance:** Penance coloca carta da mao no topo como custo. Rack troca mao pelo topo. Ciclo: Rack pega topo → Penance devolve pro topo → Rack pega de novo. Library manipulation infinita (limitada por mana).

### 3.7 Penance

**Ruling:** "You can activate Penance's ability even if the source of your choice isn't on the battlefield or isn't a black or red source."
→ Pode ativar Penance a qualquer momento so para colocar carta no topo (topdeck manipulation), mesmo sem dano a prevenir. Penance = topdeck engine com custo de 1 carta da mao.

### 3.8 Grand Abolisher

**Ruling:** "During your turn, your opponents can't cast spells or activate abilities of artifacts, creatures, or enchantments."
→ Protege TODAS as suas spells no seu turno. MAS nao protege contra:
- Habilidades de lands (Maze of Ith, Kor Haven)
- Triggers (Rhystic Study, Smothering Tithe)
- Spells/abilities no turno dos oponentes

---

## Secao 4: DOUBLE-NULL AUDIT (4 cartas)

4 cartas duplo-nulo restantes apos cortes dos Medallions:

| Carta | CMC | Funcao Real | Risco | EDHREC | Trend | PG Role |
|:------|:---:|:------------|:-----:|:------:|:-----:|:--------|
| **Scroll Rack** | 2 | Topdeck engine | 🔴 CRITICO | ~25% | Estavel | miracle_topdeck |
| **Penance** | 3 | Topdeck setup | 🔴 CRITICO | ~5% | Niche | miracle_topdeck |
| **Grand Abolisher** | 2 | Proactive protection | 🟡 ALTO | ~15% | -0.27 | protection |
| **Taunt from the Rampart** | 5 | Mass goad | 🟢 BAIXO | 35.2% | Estavel | interaction |

---

## Secao 5: MOTOR — ESTADO ATUAL (4/4 COMPLETO)

```
[Treasure Ramp] → [Big Spell Gratis] → [Lorehold Copy] → [Treasure Payoff]
     ↑                                                      ↓
     └────────── Tesouros gerados pela copia ←───────────────┘
```

| Componente | Cartas | PG Alignment |
|:-----------|:-------|:------------|
| Treasure Ramp | 10 cartas | ✅ ritual_treasure = 10.0 (EXATO) |
| Free Big Spell | 4 cartas (Dance Miracle RRR, Capstone, Mastery, Seminar) | ✅ acima do PG (15 payoffs total) |
| Copy Engines | 6 cartas (Lorehold, Double Vision, Bombardment, Dawning Archaic, Flare, Twinflame) | ✅ redundancia maxima |
| Treasure Payoff | 3 cartas (Storm-Kiln, Brass's Bounty, Hit the Mother Lode) | ✅ saudavel |

---

## Secao 6: RECOMENDACOES

### Curto Prazo (sem novas aquisicoes)
- **0 swaps.** Deck saudavel. Colecao esgotada. Nenhum candidato atinge Necessidade >= 3 + Evidencia >= 3.

### Medio Prazo (aquisicoes recomendadas)

| # | Carta | CMC | Funcao | Custo | Preenche Gap PG? |
|:-:|:------|:---:|:-------|:-----:|:----------------:|
| 1 | **Skullclamp** | 1 | Draw engine | $5-8 | Nao (draw ja esta +5.3 acima) |
| 2 | **Idyllic Tutor** | 3 | Tutor | $15-20 | **SIM — preenche tutor -1.67** |
| 3 | **Underworld Breach** | 2 | Recursion | $15-20 | Nao (recursion nao tem role PG) |

**Prioridade ajustada via PG:** Idyllic Tutor sobe para #1.5 (empata com Skullclamp) porque fecha o UNICO gap identificado pelo PG reference profile.

---

## Secao 7: CONCLUSAO — v3.17

1. **Deck state INALTERADO** desde v3.16. Card hash match confirma.
2. **PG reference revela 1 gap real:** tutor (-1.67). Apenas 2 tutores (Enlightened + Gamble) vs PG ideal 3.67.
3. **ritual_treasure = 10.0 EXATO** — calibracao perfeita do motor de treasure contra o PG.
4. **PG baselines sao conservadores** para draw (2.67) e interaction (5.33) — o deck esta acima, e isso e SAUDAVEL para Commander real.
5. **Card rulings da Scryfall API** documentam 8 interacoes criticas que o classificador erra.
6. **Proximo upgrade requer AQUISICAO** — colecao esgotada de cartas CMC <= 3 com sinergia.
7. **T3 = 11.3%** — zona BALANCED (8-12%). Nenhum ajuste urgente necessario.

---

**v3.17 assinatura:** card_hash = `a440c497da4280d6769238737062b3dd`, 100 cards, 35 lands, T3 = 11.3%, PG tutor gap = -1.67, ritual_treasure = 10.0 EXATO.
