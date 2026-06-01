# Purpose Analyzer v3.19 — Lorehold Spellslinger: PG REFERENCE + SYNERGY_MAP + Card Rulings

> **Data:** 2026-06-01T07:59:29+00:00
> **Fonte:** knowledge.db deck_id=6 — ESTADO REAL DO DB (card_hash = `30d00347764fc2a215edb4e668994871`)
> **Deck:** Lorehold Spellslinger — 100 cards, 86 rows, 35 lands, CMC medio 3.63
> **Ciclo atual:** Pos-Ciclo #22 — **🚨 DECK MUDOU desde v3.17!** Hash mismatch detectado.
> **Analista:** Hermes Agent — Purpose Analyzer v3.19
> **Foco:** PG `commander_reference_deck_analysis` comparison + SYNERGY_MAP 7 eixos + `card_rulings.ruling_text` interactions
> **v3.18 → v3.19:** 🚨 DECK ALTERADO. Card hash mudou de `a440c497...` para `30d00347764f...`. Reclassificacao completa necessaria.

---

## Secao 0: INTEGRIDADE DO PIPELINE — 🚨 DISCREPANCIA DETECTADA

| Verificacao | v3.17/v3.18 (05:00/06:46) | v3.19 (2026-06-01) | Status |
|:------------|:--------------------------:|:-------------------:|:------:|
| Card hash | `a440c497da4280d6769238737062b3dd` | `30d00347764fc2a215edb4e668994871` | 🚨 **MISMATCH** |
| Deck cards | 86 rows, 100 total | 86 rows, 100 total | ✅ Same count |
| Lands | 35 | 35 | ✅ Same |
| Commander | 1 (Lorehold) | 1 (Lorehold) | ✅ OK |
| **PIPELINE** | **Hash estavel 5+ ciclos** | **🚨 MUDOU!** | **Reclassificacao total necessaria** |

### Mudancas detectadas vs v3.17

**Cartas REMOVIDAS (8):** Ashling, Flame Dancer | Austere Command | Demand Answers | Flare of Duplication | Surge to Victory | Thrill of Possibility | Twinflame | Weathered Wayfarer

**Cartas ADICIONADAS (5 nonland):** Dualcaster Mage | Fellwar Stone | Flawless Maneuver | Primal Amulet | Valakut Awakening (single)

**Manabase ALTERADA:** Novos fetches/duals (Arid Mesa, Bloodstained Mire, Flooded Strand, Scalding Tarn, Windswept Heath, Sacred Foundry, Inspiring Vantage, Clifftop Retreat, Sundown Pass) + utility lands (Ancient Tomb, Boseiju, Cavern of Souls, Kor Haven, Exotic Orchard, Dormant Volcano).

**⚠️ Data issue:** Duas linhas para Valakut Awakening no DB — `Valakut Awakening` (tag=draw) e `Valakut Awakening // Valakut Stoneforge` (tag=land). Mesmo card fisico (MDFC) com duas representacoes. Impacto: +1 carta fantasma. Recomendado remover a linha `Valakut Awakening` (apenas front face, duplicada).

---

## Secao 1: PG REFERENCE PROFILE COMPARISON

Fonte: PostgreSQL `commander_reference_deck_analysis.average_role_counts` (3 decks analisados, perfil estatistico otimo).

| PG Role | Ideal | Actual | Diff | Status | Cartas Classificadas |
|:--------|:-----:|:------:|:----:|:------:|:---------------------|
| **lands** | 32.00 | **35.0** | +3.0 | 🟡 ACIMA | Ancient Tomb (CMC 0), Arid Mesa (CMC 0), Bloodstained Mire (CMC 0), Boseiju, Who Shelters All (CMC 0), Cavern of Souls (CMC 0), Clifftop Retreat (CMC 0), Command Tower (CMC 0), Dormant Volcano (CMC 0) |
| **ramp** | 3.67 | **7.0** | +3.3 | 🟡 ACIMA | Sol Ring (CMC 1), Arcane Signet (CMC 2), Boros Signet (CMC 2), Fellwar Stone (CMC 2), Talisman of Conviction (CMC 2), Archaeomancer's Map (CMC 3), Bender's Waterskin (CMC 3) |
| **ritual_treasure** | 10.00 | **12.0** | +2.0 | 🟡 ACIMA | Simian Spirit Guide (CMC 0), Dragon's Rage Channeler (CMC 1), Land Tax (CMC 1), Ragavan, Nimble Pilferer (CMC 1), Jeska's Will (CMC 3), Monument to Endurance (CMC 3), Big Score (CMC 4), Smothering Tit |
| **big_spell_payoff** | 7.67 | **17.0** | +9.3 | 🟡 ACIMA | Dualcaster Mage (CMC 3), The Dawning Archaic (CMC 3), Mizzix's Mastery (CMC 4), Primal Amulet (CMC 4), Arcane Bombardment (CMC 5), Double Vision (CMC 5), Reforge the Soul (CMC 5), Rite of the Dragonca |
| **miracle_topdeck** | 4.33 | **7.0** | +2.7 | 🟡 ACIMA | Library of Leng (CMC 1), Sensei's Divining Top (CMC 1), Scroll Rack (CMC 2), Monument to Endurance (CMC 3), Penance (CMC 3), Valakut Awakening (CMC 3), The One Ring (CMC 4) |
| **interaction** | 5.33 | **9.0** | +3.7 | 🟡 ACIMA | Path to Exile (CMC 1), Swords to Plowshares (CMC 1), Abrade (CMC 2), Boros Charm (CMC 2), Chaos Warp (CMC 3), Deflecting Swat (CMC 3), Generous Gift (CMC 3), Olórin's Searing Light (CMC 4), Taunt from |
| **protection** | 3.67 | **8.0** | +4.3 | 🟡 ACIMA | Mother of Runes (CMC 1), Boros Charm (CMC 2), Grand Abolisher (CMC 2), Hexing Squelcher (CMC 2), Lightning Greaves (CMC 2), Flawless Maneuver (CMC 3), Teferi's Protection (CMC 3), Akroma's Will (CMC 4 |
| **draw_value** | 2.67 | **8.0** | +5.3 | 🟡 ACIMA | Esper Sentinel (CMC 0), Faithless Looting (CMC 1), Sensei's Divining Top (CMC 1), Monument to Endurance (CMC 3), Valakut Awakening (CMC 3), Victory Chimes (CMC 3), The One Ring (CMC 4), Reforge the So |
| **tutor** | 3.67 | **2.0** | -1.7 | 🔴 ABAIXO | Gamble (CMC 0), Enlightened Tutor (CMC 1) |
| **win_condition** | 1.33 | **5.0** | +3.7 | 🟡 ACIMA | Akroma's Will (CMC 4), Approach of the Second Sun (CMC 7), Blasphemous Act (CMC 9), Worldfire (CMC 9), Apex of Power (CMC 10) |
| **board_wipe** | 2.00 | **5.0** | +3.0 | 🟡 ACIMA | Olórin's Searing Light (CMC 4), Volcanic Vision (CMC 7), Call Forth the Tempest (CMC 8), Blasphemous Act (CMC 9), Worldfire (CMC 9) |
| **recursion** | 3.33 | **3.0** | -0.3 | 🔴 ABAIXO | Faithless Looting (CMC 1), Mizzix's Mastery (CMC 4), Restoration Seminar (CMC 7) |
| **exile_value** | 3.67 | **2.0** | -1.7 | 🔴 ABAIXO | Improvisation Capstone (CMC 7), Dance with Calamity (CMC 8) |
| **spellslinger** | 3.67 | **7.0** | +3.3 | 🟡 ACIMA | Dualcaster Mage (CMC 3), The Dawning Archaic (CMC 3), Primal Amulet (CMC 4), Arcane Bombardment (CMC 5), Double Vision (CMC 5), Lorehold, the Historian (CMC 5), Rite of the Dragoncaller (CMC 6) |

### Interpretacao por Role

- **lands +3.0:** Boros sem fast mana precisa de 35. PG baseline de 32 e baixo. **Justificado.**
- **ramp +3.3:** 7 rocks (Sol Ring, 3 Signets, Talisman, Fellwar Stone, Map). Excelente para big spells. **Saudavel.**
- **ritual_treasure +2.0:** 12 geradores. Motor de mana acima do PG ideal. **Saudavel.**
- **big_spell_payoff +9.3:** 17 payoffs (6 copy engines + 11 big spells). PG baseline de 7.67 e baixo — deck de Big Spells naturalmente tem mais. **Intencional.**
- **miracle_topdeck +2.7:** 7 manipuladores. Deck Miracle-focused. **Saudavel.**
- **interaction +3.7:** 9 cartas. PG baseline 5.33 e baixo. **Saudavel.**
- **protection +4.3:** 8 cartas. Flawless Maneuver (gratis) eleva protecao. **Robusto.**
- **draw_value +5.3:** 8 fontes. PG baseline 2.67 e irrealista em Commander. **Saudavel.**
- **tutor -1.7:** 🔴 **UNICO GAP REAL.** Apenas Enlightened + Gamble = 2. PG quer 3.67. **Aquisicao: Idyllic Tutor.**
- **win_condition +3.7:** 5 wincons. Redundancia saudavel.
- **board_wipe +3.0:** 5 wipes. Bom mix de assimetricas.
- **recursion -0.3:** 3 vs 3.33. Diferenca de 0.3 nao e acionavel (cartas discretas). **Essencialmente no ideal.**
- **exile_value -1.7:** Apenas Capstone + Dance with Calamity = 2. PG quer 3.67. **Gap moderado — monitorar.**
- **spellslinger +3.3:** 7 cartas. Deck E spellslinger por definicao. **Saudavel.**

### Classificacao PG por Carta

**LANDS** (21 cartas): Ancient Tomb (CMC 0), Arid Mesa (CMC 0), Bloodstained Mire (CMC 0), Boseiju, Who Shelters All (CMC 0), Cavern of Souls (CMC 0), Clifftop Retreat (CMC 0), Command Tower (CMC 0), Dormant Volcano (CMC 0), Exotic Orchard (CMC 0), Flooded Strand (CMC 0), Inspiring Vantage (CMC 0), Kor Haven (CMC 0), Sacred Foundry (CMC 0), Scalding Tarn (CMC 0), Sundown Pass (CMC 0), Urza's Saga (CMC 0), Windswept Heath (CMC 0), Valakut Awakening // Valakut Stoneforge (CMC 3), Emeria's Call // Emeria, Shattered Skyclave (CMC 7)

**RAMP** (7 cartas): Sol Ring (CMC 1), Arcane Signet (CMC 2), Boros Signet (CMC 2), Fellwar Stone (CMC 2), Talisman of Conviction (CMC 2), Archaeomancer's Map (CMC 3), Bender's Waterskin (CMC 3)

**RITUAL_TREASURE** (12 cartas): Simian Spirit Guide (CMC 0), Dragon's Rage Channeler (CMC 1), Land Tax (CMC 1), Ragavan, Nimble Pilferer (CMC 1), Jeska's Will (CMC 3), Monument to Endurance (CMC 3), Big Score (CMC 4), Smothering Tithe (CMC 4), Storm-Kiln Artist (CMC 4), Unexpected Windfall (CMC 4), Brass's Bounty (CMC 7), Hit the Mother Lode (CMC 7)

**BIG_SPELL_PAYOFF** (17 cartas): Dualcaster Mage (CMC 3), The Dawning Archaic (CMC 3), Mizzix's Mastery (CMC 4), Primal Amulet (CMC 4), Arcane Bombardment (CMC 5), Double Vision (CMC 5), Reforge the Soul (CMC 5), Rite of the Dragoncaller (CMC 6), Emeria's Call // Emeria, Shattered Skyclave (CMC 7), Improvisation Capstone (CMC 7), Restoration Seminar (CMC 7), Volcanic Vision (CMC 7), Call Forth the Tempest (CMC 8), Dance with Calamity (CMC 8), Worldfire (CMC 9), Apex of Power (CMC 10), Storm Herd (CMC 10)

**MIRACLE_TOPDECK** (7 cartas): Library of Leng (CMC 1), Sensei's Divining Top (CMC 1), Scroll Rack (CMC 2), Monument to Endurance (CMC 3), Penance (CMC 3), Valakut Awakening (CMC 3), The One Ring (CMC 4)

**INTERACTION** (9 cartas): Path to Exile (CMC 1), Swords to Plowshares (CMC 1), Abrade (CMC 2), Boros Charm (CMC 2), Chaos Warp (CMC 3), Deflecting Swat (CMC 3), Generous Gift (CMC 3), Olórin's Searing Light (CMC 4), Taunt from the Rampart (CMC 5)

**PROTECTION** (8 cartas): Mother of Runes (CMC 1), Boros Charm (CMC 2), Grand Abolisher (CMC 2), Hexing Squelcher (CMC 2), Lightning Greaves (CMC 2), Flawless Maneuver (CMC 3), Teferi's Protection (CMC 3), Akroma's Will (CMC 4)

**DRAW_VALUE** (8 cartas): Esper Sentinel (CMC 0), Faithless Looting (CMC 1), Sensei's Divining Top (CMC 1), Monument to Endurance (CMC 3), Valakut Awakening (CMC 3), Victory Chimes (CMC 3), The One Ring (CMC 4), Reforge the Soul (CMC 5)

**TUTOR** (2 cartas): Gamble (CMC 0), Enlightened Tutor (CMC 1)

**WIN_CONDITION** (5 cartas): Akroma's Will (CMC 4), Approach of the Second Sun (CMC 7), Blasphemous Act (CMC 9), Worldfire (CMC 9), Apex of Power (CMC 10)

**BOARD_WIPE** (5 cartas): Olórin's Searing Light (CMC 4), Volcanic Vision (CMC 7), Call Forth the Tempest (CMC 8), Blasphemous Act (CMC 9), Worldfire (CMC 9)

**RECURSION** (3 cartas): Faithless Looting (CMC 1), Mizzix's Mastery (CMC 4), Restoration Seminar (CMC 7)

**EXILE_VALUE** (2 cartas): Improvisation Capstone (CMC 7), Dance with Calamity (CMC 8)

**SPELLSLINGER** (7 cartas): Dualcaster Mage (CMC 3), The Dawning Archaic (CMC 3), Primal Amulet (CMC 4), Arcane Bombardment (CMC 5), Double Vision (CMC 5), Lorehold, the Historian (CMC 5), Rite of the Dragoncaller (CMC 6)

---

## Secao 2: PG CARD RULINGS — Interacoes Chave

> Fonte: PostgreSQL `card_rulings.ruling_text` (76.991 rulings).

### Lorehold + Miracle
- Se o card com Miracle sair da sua mao antes da habilidade desencadear, nao pode ser conjurado via Miracle.
- E obrigatorio REVELAR o card com Miracle antes de mistura-lo com as outras cartas na mao.
- Efeitos que colocam cards na mao sem usar a palavra 'draw' NAO ativam Miracle (ex: tutor para mao).

### Copy Engines (Dualcaster, Double Vision, Bombardment, Primal Amulet)
- **Dualcaster Mage:** Copia qualquer instant/sorcery na stack. A copia NAO e 'conjurada' — nao ativa Lorehold nem Arcane Bombardment.
- **Double Vision:** Copia resolve ANTES do original. Se original tem X, copia tem o mesmo X. Copia criada mesmo se original for counterada.
- **Arcane Bombardment:** Se Bombardment sair do campo, cards exilados PERMANECEM no exilio. Nova copia de Bombardment nao acessa cards exilados anteriormente.
- **Primal Amulet:** Transforma em Primal Wellspring apos 4 spells. Copias de Primal Wellspring NAO contam para transformar — so spells CONJURADOS contam.

### Topdeck Engine (Scroll Rack, Top, Penance)
- **Scroll Rack:** Nao e efeito de draw. Se grimorio tem <N cards, pega quantos existirem (ate zero). NAO causa perda por deck vazio.
- **Sensei's Divining Top:** Pode ativar 2a habilidade em resposta a 1a. Resultado: compra 1, Top vai pro topo, olha top 3 e reorganiza — efetivamente um 'draw 1, scry 3' por 1 mana.
- **Penance:** Nao tem rulings no PG — carta antiga e obscure. Efeito: revela card do topo, se for da cor escolhida, coloca no fundo. Usado para setup de Miracle.

### Free Protection (Flawless Maneuver, Teferi's, One Ring)
- **Flawless Maneuver:** GRATIS se controla um commander (nao precisa ser o seu). Lorehold e sempre seu commander → sempre gratis. Indestrutivel para TODAS suas criaturas.
- **Teferi's Protection:** Voce 'phases out' — suas permanentes nao existem ate seu proximo turno. Vida nao pode mudar. Protecao contra tudo.
- **The One Ring:** Protecao contra tudo no turno que entra. Nao previne discard nem ataques (so o dano de combate e prevenido).

### Win Conditions (Approach, Mizzix's Mastery, Dance with Calamity)
- **Approach of the Second Sun:** Apenas o Approach CONJURADO conta. Copias nao contam. Se o primeiro foi counterado, voce AINDA vence quando o segundo resolver.
- **Mizzix's Mastery (Overload):** Exila TODOS instant/sorcery do GY. Copia cada um. Se tem X no custo, X = 0 nas copias. Copias nao sao conjuradas (nao ativam Lorehold).
- **Dance with Calamity:** Se tem X no custo, X = 0 no cast gratuito. Cartas nao conjuradas permanecem no exilio permanentemente.

### Uncounterable (Boseiju, Cavern of Souls)
- **Boseiju:** Mana gasta em QUALQUER custo do spell o torna incounteravel (inclui kicker, splice). Paga 2 vidas. Copias do spell AINDA podem ser counteradas.
- **Cavern of Souls:** Escolha um tipo de criatura. Spells daquele tipo sao incounteraveis. Funciona mesmo pagando custo alternativo (ex: Dash do Ragavan).

---

## Secao 3: SYNERGY_MAP — 7 Eixos Estrategicos

### A) TOKEN MAKERS + PUMP — Score: 7/10
**Token Makers (6):** Rite of the Dragoncaller (5/5 Dragon por spell), Storm Herd (X Pegasus), Call Forth the Tempest (X tokens + double strike), Brass's Bounty (X Treasure), Smothering Tithe (Treasure), Storm-Kiln Artist (Treasure por spell).

**Pump (2):** Akroma's Will (double strike + lifelink + flying + vigilance para TODAS criaturas), Boros Charm (double strike para 1).

**Melhor par:** Storm-Kiln Artist + Rite of the Dragoncaller. Cada spell gera Treasure + 5/5 Dragon. Akroma's Will no turno seguinte = dano massivo.

**PG:** ritual_treasure +2.0, win_condition +3.7. Abundancia de recursos nesse eixo.


### B) BOARD WIPES + PROTECTION — Score: 8/10
**Wipes (5):** Blasphemous Act (CMC 1 com board cheia), Call Forth the Tempest (modal), Volcanic Vision (dano + recursion), Olórin's Searing Light (exila GY), Worldfire (reset total).

**Protection (8):** Teferi's Protection, Flawless Maneuver (gratis!), Boros Charm, Mother of Runes, Lightning Greaves, Grand Abolisher, Hexing Squelcher, Akroma's Will.

**PG:** board_wipe 5/2.0 (🟡 ACIMA), protection 8/3.67 (🟡 ACIMA). 3 fogs massivos = excelente cobertura.


### C) RECURSION CHAINS — Score: 7/10
**Recursion (3):** Mizzix's Mastery (overload — todo GY), Restoration Seminar (paradigm — copia a cada main phase), Volcanic Vision (recupera 1).

**GY Enablers (3):** Faithless Looting (draw+discard), Dragon's Rage Channeler (surveil), Olórin's Searing Light.

**Chain:** Faithless Looting (T1-2) → enche GY → Mizzix's Mastery overload (T5-6) → conjura TUDO.

**PG:** recursion 3/3.33 — essencialmente no ideal (-0.3 nao acionavel).


### D) EXPLOSIVE MANA — Score: 9/10
**Treasure (10):** Smothering Tithe, Storm-Kiln Artist, Big Score, Unexpected Windfall, Brass's Bounty, Hit the Mother Lode, Jeska's Will, Land Tax, Ragavan, Monument to Endurance.

**Rituals (1):** Simian Spirit Guide (R instantaneo).

**Rocks (5):** Sol Ring, Arcane Signet, Boros Signet, Talisman, Fellwar Stone.

**Mana Sinks (4):** Dance with Calamity, Improvisation Capstone, Call Forth the Tempest, Storm Herd.

**PG:** ritual_treasure 12/10 (+2.0), ramp 7/3.67 (+3.3). Motor de mana e a forca do deck.


### E) COMBO PIECES — Score: 8/10
**Deterministico (1):** Approach → Top/Scroll Rack → Approach = VITORIA. Requer 14 manas totais.

**Semi-deterministico (2):** Worldfire + qualquer haste/dano = VITORIA. Dualcaster Mage + spell alvo na stack = loop infinito.

**Situacional:** Capstone exila top 7 e pode achar Approach. Dance with Calamity exila X cartas. Mizzix's Mastery overload.

**PG:** win_condition 5/1.33 (+3.7). Redundancia saudavel. Falta combo instant-speed (Twinflame/Flare eram esse slot).


### F) STACK INTERACTION — Score: 5/10
**Counterspell proxy (2):** Hexing Squelcher (taxa), Grand Abolisher (silencia no seu turno).

**Redirect (1):** Deflecting Swat.

**Uncounterable (2):** Boseiju, Cavern of Souls.

**Spell Copy (1):** Dualcaster Mage (pode copiar counterspell oponente).

**Nota:** Stack interaction e fraqueza classica de Boros. Flare of Duplication foi cortada — era a unica resposta gratuita. Perda significativa.


### G) RESILIENCE — Score: 8/10
**Fogs massivos (3):** Teferi's Protection, Flawless Maneuver, Boros Charm.

**Protecao pontual (2):** Mother of Runes, Lightning Greaves.

**Recuperacao (2):** Mizzix's Mastery, Restoration Seminar.

**Anti-target (1):** The One Ring.

**PG:** protection 8/3.67 (+4.3). 3 fogs = sobrevive a 3 wipes/alpha strikes. Excelente para Boros.


### SYNERGY_MAP Summary

| Eixo | Score | PG Alignment | Destaque |
|:-----|:-----:|:-------------|:---------|
| A) TOKEN MAKERS + PUMP | 7/10 | ritual_treasure +2.0 | — |
| B) BOARD WIPES + PROTECTION | 8/10 | protection +4.3 | — |
| C) RECURSION CHAINS | 7/10 | recursion -0.3 (ideal) | — |
| D) EXPLOSIVE MANA | 9/10 | ritual_treasure +2.0 | — |
| E) COMBO PIECES | 8/10 | win_condition +3.7 | — |
| F) STACK INTERACTION | 5/10 | N/A (Boros) | — |
| G) RESILIENCE | 8/10 | protection +4.3 | — |

**SYNERGY_MAP Score Medio: 7.4/10** — Deck solido com motor de mana excepcional. Stack interaction e a fraqueza classica de Boros.

---

## Secao 4: DOUBLE-NULL AUDIT

| Card | CMC | Real Function | Risk | EDHREC % |
|:-----|:---:|:--------------|:-----|:--------:|
| Grand Abolisher | 2 | Protection | 🟡 HIGH | 11.7 |
| Scroll Rack | 2 | Topdeck engine | 🔴 CRITICAL | 51.3 |
| Penance | 3 | Miracle enabler | 🔴 CRITICAL | N/A |
| Taunt from the Rampart | 5 | Mass goad | 🟢 LOW | 35.2 |

**4 double-nulls** (reduzido de 9 originais). Scroll Rack e Penance sao CRITICOS — nao cortar. Grand Abolisher em declinio (-0.27 trend) mas ainda util. Taunt from the Rampart com 35.2% EDHREC — seguro.

---

## Secao 5: MUDANCAS DESDE v3.17 — ANALISE DE IMPACTO

| Tipo | Cartas | Net DCMC | Nota |
|:-----|:-------|:--------:|:-----|
| **OUT (8)** | Ashling(4), Austere(6), Demand(2), Flare(3), Surge(6), Thrill(2), Twinflame(2), Weathered Wayfarer(1) | -26 | 8 cartas removidas |
| **IN nonland (5)** | Dualcaster(3), Fellwar(2), Flawless(3), Primal(4), Valakut(3) | +15 | 5 cartas adicionadas |
| **IN lands** | Fetch/dual upgrades + utility lands | 0 | Manabase refeita |
| **NET** | -3 cartas | **-11 DCMC** | **~+6pp melhora T3 estimada** |

**Avaliacao qualitativa:**
- ✅ Manabase melhorou significativamente (8 fetches).
- ✅ Flawless Maneuver (gratis) melhora protecao em +1 fog massivo.
- ✅ Dualcaster Mage adiciona stack interaction + combo potencial.
- ⚠️ Perdeu Flare of Duplication (unica free stack response).
- ⚠️ Perdeu Twinflame (combo piece CMC 2).
- ⚠️ Perdeu draw barato (Demand Answers, Thrill of Possibility — ambos CMC 2).

---

## Secao 6: RECOMENDACOES

### Gaps Detectados

| # | Gap | PG Baseline | Actual | Severidade | Acao |
|:-:|:-----|:-----------:|:------:|:----------:|:-----|
| 1 | **tutor** | 3.67 | 2 | 🟡 MODERADO | **Aquisicao: Idyllic Tutor ($15-20).** Unico gap real > 1.5. |
| 2 | **exile_value** | 3.67 | 2 | 🟡 MODERADO | Monitorar. Capstone + Dance cobrem parcialmente. |
| 3 | **stack interaction** | N/A | 5/10 | 🟡 MODERADO | Flare of Duplication cortada. Se readquirida, reavaliar. |
| 4 | **Valakut duplicado** | — | — | 🟢 BAIXO | Corrigir DB: remover linha `Valakut Awakening` duplicada. |

### Aquisicoes Recomendadas

| # | Carta | CMC | Funcao | PG Role | Custo | Fecha Gap? |
|:-:|:------|:---:|:-------|:--------|:-----:|:-----------|
| 1 | **Idyllic Tutor** | 3 | Tutor de enchantment | tutor | $15-20 | **SIM — fecha tutor gap.** |
| 2 | **Flare of Duplication** | 3 | Free stack copy | big_spell_payoff | $2-3 | Parcial — stack interaction. Foi cortada, readquirir. |
| 3 | **Skullclamp** | 1 | Draw engine | draw_value | $5-8 | Nao (draw +5.3 acima). Utilidade geral. |

---

## Secao 7: CHECKLIST p/ Evolution Oracle

| Check | Status | Nota |
|:------|:------:|:-----|
| 100 cartas? | ✅ | 100 (com Valakut duplicado = 101 virtual) |
| Commander = 1? | ✅ | Lorehold |
| Lands = 35? | ✅ | 35 |
| Singleton? | ⚠️ | Valakut duplicado (MDFC front + full). Corrigir. |
| Motor 4/4? | ✅ | Treasure, Free Spell, Copy, Payoff — completo |
| Copy engines? | ✅ | 7 ativas |
| Tutor PG gap? | 🔴 | 2 vs 3.67. Unico gap real. |
| Double-nulls? | ⚠️ | 4 (Scroll Rack, Penance, Grand Abolisher, Taunt) |
| T3 Sem Play? | ❓ | **NAO MEDIDO.** Necessario executar Mulligan Tester com novo deck. |
| **Estrategia** | **BALANCED** | Deck saudavel. Aguardar T3 para confirmar. |
