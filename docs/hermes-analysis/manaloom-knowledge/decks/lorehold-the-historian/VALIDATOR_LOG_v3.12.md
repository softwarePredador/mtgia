# Purpose Analyzer v3.12 -- Lorehold Spellslinger: MATURIDADE PERSISTENTE (C#12+C#13 = 0 Swaps)

> **Data:** 2026-05-31T21:11:43+00:00
> **Fonte:** knowledge.db deck_id=6 (pos-Ciclo #13, 0 swaps em C#12 e C#13)
> **Deck:** Lorehold Spellslinger -- 100 cards, 86 rows, 35 lands, CMC medio 3.71
> **Analista:** Hermes Agent -- Purpose Analyzer v3.12
> **Foco:** Pos-Ciclo #13 -- 3o ciclo consecutivo sem swaps (C#11, C#12, C#13). Maturidade persistente confirmada.

---

## Secao 0: O QUE MUDOU DO v3.11 PARA v3.12

### 3 Ciclos Consecutivos sem Swaps (C#11, C#12, C#13)

O Evolution Oracle aplicou **ZERO swaps** em 3 ciclos consecutivos desde o ultimo swap em Ciclo #10 (Flare de Duplication + Twinflame). O deck esta identico ao estado pos-Ciclo #10.

| Ciclo | Data | Swaps | Motivo |
|:-----:|:-----|:-----:|:-------|
| C#11 | 2026-05-31T19:10 | 0 | 38 candidatos avaliados, nenhum atinge Nec>=3 + Evid>=3 |
| C#12 | 2026-05-31T20:30 | 0 | Maturidade confirmada. Colecao esgotada. |
| C#13 | 2026-05-31T20:58 | 0 | Maturidade persistente. 7 novos candidatos SCOUT #22, todos rejeitados. |

### Novos Candidatos SCOUT Rejeitados

**SCOUT #21 (Execucao #21, 2026-05-31T20:12):** 3 candidatos synergy-first:
- Flashback (CMC 1, score 10/15): Otimo mas ja cortado C#3. Nao voltar atras.
- Spiteful Banditry (CMC 2, score 10/15): Wipe lento, nao acelera T1-T3.
- Tablet of Discovery (CMC 3, score 9/15): CMC 3, piora T3.

**SCOUT #22 (Execucao #22, 2026-05-31T20:51):** 7 candidatos synergy-first:
- Invoke Calamity (CMC 5, score 10/15): CMC alto. Rejeitado.
- Seize the Spoils (CMC 3, score 10/15): Sidegrade para Thrill. Nao melhora gaps.
- Loran's Escape (CMC 1, score 9/15): Protecao pontual. 6a protecao e overkill.
- Cool but Rude (CMC 4, score 8/15): CMC 4. Sidegrade.
- Naktamun Lorespinner // Wheel of Fortune (CMC 2, score 8/15): Interessante, mas nao resolve T3.
- Creative Technique (CMC 5, score 8/15): CMC alto. Demonstracao ja existe com Dance/Improvisation.
- Promise of Loyalty (CMC 5, score 8/15): Wipe com vantagem, mas 5 wipes ja e suficiente.

**Conclusao dos 3 ciclos:** 48+ candidatos avaliados (38 + 3 + 7). NENHUM atinge o criterio Necessidade >= 3 + Evidencia >= 3. O deck esta NO OTIMO com a colecao atual.

### Confianca na Maturidade do Deck

Apos 3 ciclos consecutivos de validacao sem encontrar swaps viaveis, podemos afirmar com CONFIANCA ALTA que:
1. O deck atingiu maturidade maxima com a colecao atual
2. Nao ha filler -- todas as cartas tem funcao justificavel
3. A unica via de melhoria e AQUISICAO de cartas
4. O deck e FUNCIONAL e COMPETITIVO neste estado

### Mudancas Chave (v3.11 -> v3.12)

1. **C#12 + C#13: 0 swaps confirmados.** A maturidade ja identificada no v3.11 persiste.
2. **SCOUT #21 e #22 propuseram 10 novos candidatos.** Todos rejeitados pelo framework Necessidade/Evidencia.
3. **48+ candidatos avaliados desde C#11.** Confirmacao estatistica de que a colecao esta esgotada.
4. **SEM mudancas no deck.** SYNERGY_MAP scores identicos ao v3.11/v3.10.
5. **Confianca ALTA na maturidade.** 3 ciclos sem swaps = validacao multipla.

### Nada mudou no deck -- por que v3.12?

O proposito do v3.12 e **documentar a persistencia da maturidade** e **validar os candidatos SCOUT #21/#22**.
A secao SYNERGY_MAP (A-G) e reproduzida do v3.11 para manter a analise auto-contida.
O foco do v3.12 esta nas secoes 0 (mudancas), 8 (gaps atualizados), e 9 (estrategia Ciclo #14).

---

## Secao 1: Visao Geral do Deck

### Metricas Recalculadas (pos-Ciclo #13, sem mudancas, identicas ao v3.11)

| Metrica | Deck Real | Perfil EDHREC | Status |
|:--------|:---------:|:--------------|:-------|
| Lands | 35 | 36-38 | OK (-1, MDFCs compensam) |
| Ramp (functional_tag) | 14 | 10-13 | +1 (treasure-heavy) |
| Draw (real) | 7 | 8-12 | -1 (estrutural Boros) |
| Removal | 6 | 4-6 | No limite |
| Board Wipe | 5 | 3-5 | No limite |
| Protection (DB tag) | 3 | 3-4 | OK (+2 stack: Swat, Squelcher; +1 proativa: Grand Abolisher) |
| Recursion | 4 | 2-5 | No range |
| Wincon (dedicado) | 2 | 4-7 | Funcionalmente 8+ paths (ver Secao 3) |
| Engine/Big Spell | 9 | 5-8 | Motor 4/4 + Copy 6 + engines |
| Tutor | 2 | -- | Enlightened + Gamble |
| CMC medio | 3.71 | ~4.1 | OK |

### Deck Health (pos-Ciclo #13, T3 CONFIRMADO)

| Indicador | Valor | Interpretacao |
|:----------|:-----:|:--------------|
| Motor | 4/4 COMPLETO | Treasure -> Free Big Spell -> Copy -> Payoff |
| Copy Engines | 6 ativas | Lorehold + Double Vision + Bombardment + Dawning Archaic + Flare + Twinflame |
| **Sem Play T3** | **13.3%** | **🟡 DEFENSIVE (>12%). CONFIRMADO Exec#11.** |
| Mulligan Rate | 47.9% | Estrutural (35 lands, 3 T1 ramp estrito) |
| Ramp T1 (Sol Ring only) | 6.3% | Canonico |
| Draw Real | 7 fontes | A 1 fonte do minimo do perfil |
| Protection (total) | 6 fontes | 3 DB-tagged + 3 stack (Swat, Squelcher, Abolisher) |
| Double-null | 4 | 2 core (Scroll Rack, Penance), 2 situational (Taunt, Grand Abolisher) |

---

## Secao 2: CLASSIFICACAO ESTRATEGICA -- TODAS as Cartas

(Identica ao v3.11 -- deck nao mudou.)

### Nivel 5: NAO SE JOGA SEM (Core Identity)

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 5 |
|:------|:---:|:------:|:------------|:------------------|
| **Lorehold, the Historian** | 5 | -- | commander, engine, copy | Copia instants/sorceries do grave + desconto de 1. Define o deck. |
| **Approach of the Second Sun** | 7 | 63.8% | wincon | Wincon primaria. Com Flare de Duplication: vitoria no MESMO turno. Com topdeck, deterministico. |
| **Mizzix's Mastery** | 4 | 57.5% | recursion, wincon | Overload = conjura TODOS instants/sorceries do grave gratis. Game-ender. |

### Nivel 4: CORE DA ESTRATEGIA (Define o plano de jogo)

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 4 |
|:------|:---:|:------:|:------------|:------------------|
| **Dance with Calamity** | 8 | 67.0% | engine, free_spell | Exila top 8, conjura spells gratis. Motor componente #2. |
| **Double Vision** | 5 | 46.6% | engine, copy | Primeira spell por turno copiada. Copy layer #1. |
| **Arcane Bombardment** | 5 | 42.5% | engine, copy, recursion | Exila e copia 1a spell a cada turno. Copy layer #2 + recursion passiva. |
| **Smothering Tithe** | 4 | 45.9% | ramp, treasure | 3+ treasures por turno em 4-player. Alimenta TODO o motor. |
| **Storm-Kiln Artist** | 4 | 55.4% | ramp, treasure, payoff | Cada spell cast/copiada = Treasure. Com 6 copy layers, 4-7 treasures/turno. |
| **Improvisation Capstone** | 7 | 49.0% | engine, free_spell | Exila top 7, conjura gratis. Rising star (+8.09). Motor componente #2. |
| **Scroll Rack** | 2 | 59.7% | topdeck, draw_virtual | Reordena topo. Double-null. Core engine. Setup de Approach + Dance. |
| **Penance** | 3 | 41.8% | topdeck, protection | Setup de topdeck + anti-removal. Miracle enabler. Double-null. Core engine. |
| **Flare of Duplication** | 3 | -- | copy, combo | Copia instant/sorcery. FREE sacrificando criatura vermelha. Com Approach = vitoria no mesmo turno. |

### Nivel 3: SUPORTE FORTE (Sinergia consistente, deck piora sem)

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 3 |
|:------|:---:|:------:|:------------|:------------------|
| **Sensei's Divining Top** | 1 | 66.9% | topdeck, draw | Manipula topo. Com Approach = "cast Approach, respond com Top, ganha". |
| **Akroma's Will** | 4 | ~20% | wincon, pump, protection | Flying + double strike + vigilance + lifelink + prot all colors + indestructible. Transforma QUALQUER token board em lethal. |
| **Insurrection** | 8 | 59.7% | wincon, theft | Rouba TODAS as criaturas, da haste. Game-ender autonomo. |
| **Surge to Victory** | 6 | 26.1% | wincon, recursion, pump | Copia spell com criaturas atacando. Com Twinflame: dobra criaturas. Com Approach: ganha. |
| **Boros Charm** | 2 | 52.8% | pump, protection | Double strike OU indestrutivel. Versatil. Tag do DB "removal" esta ERRADO. |
| **The One Ring** | 4 | 56.1% | draw, protection | Draw massivo + fog. Game Changer. |
| **Teferi's Protection** | 3 | 52.4% | protection | Faseia tudo. Resposta a TUDO. |
| **Jeska's Will** | 3 | 54.7% | ramp, ritual | Mana explosiva. 7+ mana em um turno. |
| **Chaos Warp** | 3 | 38.8% | removal | Remocao universal -- shuffle. Unica que lida com indestrutivel. |
| **Swords to Plowshares** | 1 | 56.1% | removal | Premium removal. |
| **Path to Exile** | 1 | 51.6% | removal | Premium removal. |
| **Generous Gift** | 3 | 44.9% | removal | Destroi qualquer permanente. |
| **Abrade** | 2 | 47.5% | removal | Remocao versatil -- criatura ou artefato. |
| **Enlightened Tutor** | 1 | 49.4% | tutor | Busca artefato ou encantamento. |
| **Gamble** | 1 | 44.3% | tutor | Tutor universal com risco de descarte. |
| **Esper Sentinel** | 1 | 32.5% | draw | Draw condicional. 6o ciclo em declinio (-0.54). Monitorar. |
| **Thrill of Possibility** | 2 | 13.9% | draw, loot | Draw 2 discard 1, instant. Preenche grave. |
| **Dragon's Rage Channeler** | 1 | 41.7% | graveyard, selection | Surveil + selection. Preenche grave. |
| **Big Score** | 4 | 55.8% | ramp, treasure, loot | 2 treasures + draw 2 + discard 1. Instant. Motor componente #1. |
| **Unexpected Windfall** | 4 | 18.6% | ramp, treasure, loot | Versao menor de Big Score. |
| **Reforge the Soul** | 5 | 44.0% | draw, wheel | Wheel -- draw 7. Reset de mao. |
| **Rite of the Dragoncaller** | 6 | 40.4% | token, payoff | 5/5 Dragon a cada spell. |
| **Storm Herd** | 10 | 75.1% | token, wincon | X Pegasus = PVs. Game-ender. |
| **Archaeomancer's Map** | 3 | 29.3% | ramp | Land ramp condicional. |
| **Land Tax** | 1 | 55.7% | ramp | 3 lands/turno. Ramp consistente. |
| **Weathered Wayfarer** | 1 | 39.3% | ramp, tutor | Busca ANY land. |
| **Sol Ring** | 1 | 84.3% | ramp | Staple. |
| **Boros Signet** | 2 | 50.4% | ramp | Signet estavel. |
| **Arcane Signet** | 2 | 80.2% | ramp | Staple. |
| **Talisman of Conviction** | 2 | 62.1% | ramp | Ramp com dano opcional. |
| **Monument to Endurance** | 3 | 41.3% | engine, draw | Draw + loot + drain. Tag do DB "ramp" esta ERRADO -- e engine. |
| **Library of Leng** | 1 | 77.8% | hand, graveyard | Sem limite de mao + descarte no topo. |
| **Valakut Awakening** | 3 | 35.7% | draw, hand_reset | MDFC. Hand reset + draw. |
| **Emeria's Call** | 7 | 43.4% | token, land | MDFC. Flexibilidade. |
| **Longshot, Rebel Bowman** | 4 | 27.3% | payoff | Bolt sempre que Lorehold ataca/bloqueia. |
| **Bender's Waterskin** | 3 | 22.8% | ramp | Rock ou tutora land. |
| **Fated Clash** | 5 | 15.6% | board_wipe | Bounce 1 por oponente + scry. |
| **Olorin's Searing Light** | 4 | 49.6% | removal, graveyard | Exila permanente + instant/sorcery do grave. |
| **Victory Chimes** | 3 | 53.6% | draw, engine | Untap a cada turno + draw. Multiplayer value. |
| **Wedding Ring** | 4 | ~25% | draw, ramp | Draw + lifegain. |
| **The Dawning Archaic** | 3 | 24.0% | engine, copy, free_spell | Copia spells dos oponentes. Rising star (+5.31, 5+ ciclos). |
| **Restoration Seminar** | 7 | 37.8% | recursion, token | Retorna spell + cria Lesson. Rising star (+9.14). |
| **Twinflame** | 2 | -- | copy, creature | Cria copia de criatura com haste. Com Surge+Akroma: dano exponencial. |

### Nivel 2: UTILIDADE SITUACIONAL

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 2 |
|:------|:---:|:------:|:------------|:------------------|
| **Deflecting Swat** | 3 | 42.0% | protection, stack | Redireciona spell/ability. Stack interaction crucial. Tag "big_spell" do DB ERRADO. |
| **Lightning Greaves** | 2 | 73.3% | protection | Shroud + haste. Protege Lorehold. |
| **Grand Abolisher** | 2 | 11.7% | protection, stack | Oponentes nao conjuram no seu turno. Double-null. Trend -0.27 (declinio). UNICA protecao proativa anti-counterspell. |
| **Hexing Squelcher** | 2 | ~10% | protection, stack | Oponentes nao ativam habilidades. Anti-combo. |
| **Taunt from the Rampart** | 5 | 35.2% | goad, control | Goad em todas as criaturas. Double-null. Util em multiplayer. |

### Nivel 1: SUBSTITUIVEL (Candidato a corte)

**VAZIO.** Todas as cartas tem funcao justificavel. Ruby Medallion (unico Nivel 1 do v3.9) foi removido no Ciclo #10.

A carta mais proxima de Nivel 1: Fated Clash (15.6% EDHREC, bounce-only). Mas cumpre funcao de board wipe e nao ha substituto viavel na colecao.

### Lands -- Classificacao

| Carta | Funcao Real | Nota |
|:------|:------------|:-----|
| Ancient Tomb | ramp | Sol land. |
| Arid Mesa, Bloodstained Mire, Flooded Strand, Scalding Tarn, Windswept Heath | fetch, topdeck | 5 fetches. Alimentam Scroll Rack + Top + Land Tax. |
| Boseiju, Who Shelters All | protection, removal | Channel -- destroi artefato/encantamento nao-counteravel. |
| Cavern of Souls | protection | Lorehold nao-counteravel. |
| Clifftop Retreat, Inspiring Vantage, Sundown Pass | fixing | Boros fixing. |
| Command Tower, Exotic Orchard, Sacred Foundry, Dormant Volcano | fixing, ramp | Color fixing. |
| Kor Haven | protection | Fog por criatura atacante. |
| Urza's Saga | tutor, token, ramp | Busca Sol Ring, Top, Library. Constructs. |
| 8x Mountain, 8x Plains | basic | Land Tax + Wayfarer targets. |

---

## Secao 3: SYNERGY_MAP -- 7 Eixos (A-G)

(Reproduzido do v3.11 com scores mantidos -- deck nao mudou.)

### A) TOKEN MAKERS + PUMP -- Como o deck transforma tokens em vitoria?

#### TOKEN MAKERS (criaturas para combate)

| Carta | CMC | O que cria | Quantidade | Condicao |
|:------|:---:|:-----------|:----------:|:---------|
| Rite of the Dragoncaller | 6 | Dragon 5/5 flying | 1/cast | Cada instant/sorcery = 1 dragon |
| Storm Herd | 10 | Pegasus 1/1 flying | X = PVs | Com 40 PVs = 40 tokens |
| Emeria's Call (MDFC) | 7 | Angel 4/4 flying | 2 | Cria 2 angels |
| Restoration Seminar | 7 | Lesson token | 1 | Recursao + token |
| Urza's Saga | 0 | Construct | 1-2 | Chapter III |

#### TOKEN MAKERS (tesouros -- usados como mana)

| Carta | CMC | O que cria | Quantidade |
|:------|:---:|:-----------|:----------:|
| Smothering Tithe | 4 | Treasure | 3+/turno (passivo) |
| Storm-Kiln Artist | 4 | Treasure | 1/cast ou copia (4-7/turno com copy layers) |
| Big Score | 4 | Treasure | 2 |
| Unexpected Windfall | 4 | Treasure | 2 |
| Brass's Bounty | 7 | Treasure | X = lands (~7-10) |
| Hit the Mother Lode | 7 | Treasure | 7 |

#### PUMP / DANO EM MASSA

| Carta | CMC | Efeito | Escala |
|:------|:---:|:-------|:-------|
| Boros Charm | 2 | Double strike para TODAS as criaturas | Multiplica dano por 2 |
| **Akroma's Will** | 4 | Flying + double strike + vigilance + lifelink + prot all colors + indestructible | Transforma qualquer board em lethal |
| Surge to Victory | 6 | Copia spell, criaturas dao dano = copia | Cada criatura = 1 copia |
| Insurrection | 8 | Rouba TODAS as criaturas, haste | Board dos oponentes |
| **Twinflame** | 2 | Copia criatura com haste | Dobra criaturas para Surge |

#### PARES TOKEN + PUMP -- Calculo de Dano

**Rite of the Dragoncaller + Boros Charm:**
- Estado tipico (T6+): 3 dragons 5/5 no campo
- Boros Charm double strike: 3 x (5 x 2) = 30 flying damage
- **Conclusao: Mata 1-2 jogadores.**

**Rite + Akroma's Will:**
- 3 dragons 5/5 -> Akroma's Will: flying, double strike, vigilance, lifelink, prot all colors, INDESTRUCTIBLE
- Dano: 3 x (5 x 2) = 30 flying. Ganha 30 de vida.
- **Conclusao: Mata 1 jogador + estabiliza vida + protege board.**

**Storm Herd + Boros Charm:**
- Com 40 PVs: 40 Pegasus 1/1 flying
- Boros Charm double strike: 40 x 2 = 80 flying damage
- **Conclusao: Mata a mesa INTEIRA.**

**Storm Herd + Akroma's Will:**
- 40 Pegasus + Akroma: double strike, prot all colors, indestructible
- Dano: 40 x 2 = 80 flying. Ganha 80 de vida. INDESTRUCTIVEL.
- **Conclusao: OVERKILL.**

**Twinflame + Surge to Victory + Akroma's Will (CHAIN EXPONENCIAL):**
- T1: Twinflame copia Lorehold (ou Dragon do Rite) -> 2 criaturas com haste
- T2: Surge to Victory exila Approach do grave -> 2+ criaturas atacam -> 2+ copias de Approach
- T3: Akroma's Will buffa TODAS -> flying + double strike + lifelink + indestructible
- **Conclusao: Ganha na HORA com 2+ copias de Approach, tudo indestrutivel.**

**Flare of Duplication + Approach (VITORIA NO MESMO TURNO):**
- T1: Cast Approach of the Second Sun (7 mana)
- T2: Sacrifice criatura vermelha (Dragon's Rage Channeler, Storm-Kiln token, etc.)
- T3: Flare of Duplication FREE -> copia Approach -> 2o cast na stack
- **Conclusao: VITORIA IMEDIATA. Sem esperar 1 turno. Total: 7 mana + qualquer criatura vermelha.**

#### ANALISE DO PLANO TOKEN+PUMP

| Forca | Fraqueza |
|:------|:---------|
| 2 pumps reais: Boros Charm + Akroma's Will | Akroma's Will CMC 4 |
| Twinflame dobra criaturas para Surge chain | Rite lento (1 dragon/cast) |
| Flare + Approach = vitoria sem combate | Storm Herd CMC 10 |
| Insurrection game-ender autonomo | Surge depende de Approach no grave |
| 3+ paths de vitoria sem combate (Approach, Flare+Approach, Surge+Approach) | |

**Nota: 8/10.**

---

### B) BOARD WIPES + PROTECTION -- Wipes assimetricos?

#### BOARD WIPES (5)

| Carta | CMC | Efeito | Custo Real |
|:------|:---:|:-------|:-----------|
| Blasphemous Act | 9 | Destroi TODAS as criaturas | Tipicamente R |
| Austere Command | 6 | Destroi 2 de 4 tipos (modular) | Pode pular criaturas |
| Call Forth the Tempest | 8 | Dano = 2X a cada criatura + cascade | Dano massivo + valor |
| Volcanic Vision | 7 | Dano = CMC a cada criatura + retorna spell | Wipe + recursao |
| Fated Clash | 5 | Bounce 1 por oponente + scry | Wipe suave |

#### PROTECAO (contra wipes: 4; stack: ver Eixo F)

| Carta | CMC | Efeito | Contra o que protege |
|:------|:---:|:-------|:---------------------|
| Boros Charm | 2 | Indestrutivel | Wipes, remocao em massa |
| Teferi's Protection | 3 | Faseia voce e seus permanentes | TUDO |
| Lightning Greaves | 2 | Shroud + haste | Remocao direcionada |
| **Akroma's Will** | 4 | Indestrutivel + prot all colors | Wipes, remocao, combate |

#### PARES WIPE + PROTECAO

**Austere Command + Teferi's Protection:**
- Teferi's -> faseia tudo. Na volta, Austere -> so oponentes tem criaturas.
- **Protecao: Faseia (Teferi's). Austere e MODULAR -- pode escolher nao destruir artefatos/enchantments.**

**Blasphemous Act + Boros Charm (indestrutivel):**
- Blasphemous Act -> Boros Charm indestrutivel -> suas criaturas sobrevivem, oponentes nao.
- **Protecao: Boros Charm. Custo total: R + RW = 3 mana!**

**Call Forth the Tempest + Akroma's Will:**
- Call Forth -> dano massivo + cascade. Akroma's Will -> indestrutivel + prot all colors.
- Suas criaturas sobrevivem ao dano e ficam buffadas para o contra-ataque.

#### RATIO WIPES / PROTECAO
- **5 wipes / 4 protecoes contra wipes = 1.25:1**
- Wipes assimetricos/mitigaveis: Austere (modular), Call Forth (dano, Akroma+bombas sobrevivem)
- Wipes perigosos sem protecao: Blasphemous Act (se sem Boros Charm/Akroma)
- **Balanco adequado.** Sem risco de auto-destruicao.

**Nota: 8/10.**

---

### C) RECURSION CHAINS -- Como o deck reusa o cemiterio?

#### RECURSION PIECES

| Carta | CMC | Tipo | O que faz |
|:------|:---:|:-----|:----------|
| Mizzix's Mastery | 4 | Overload | Conjura TODOS instants/sorceries do grave gratis |
| Arcane Bombardment | 5 | Passiva | A cada turno, exile 1 instant/sorcery do grave -> copia gratis |
| Faithless Looting | 1 | Flashback | Flashback por 2R -> +1 loot |
| Surge to Victory | 6 | Ativa | Exile sorcery do grave, copia com criaturas atacando |
| Restoration Seminar | 7 | Ativa | Retorna instant/sorcery do grave + cria Lesson token |
| Volcanic Vision | 7 | Wipe+Recursao | Dano = CMC a todas as criaturas + retorna instant/sorcery |

#### CHAINS DOCUMENTADAS

**Chain 1: Faithless -> Grave Setup -> Mizzix's Overload (T4-T6)**
1. T1-T3: Faithless Looting, Thrill of Possibility, Dragon's Rage Channeler enchem o grave
2. T4-T6: Mizzix's Mastery overload -> 5-10+ spells gratis em um turno
3. Com Double Vision: primeira spell copiada -> 2x valor
4. Com Arcane Bombardment: cartas ja exiladas por Bombardment + cartas novas do grave
5. **Resultado: Turno explosivo que geralmente fecha o jogo.**

**Chain 2: Bombardment -> Acumulo Passivo -> Copy em Cadeia (T5+)**
1. T5+: Arcane Bombardment entra
2. Cada turno: exile 1 spell do grave, copia gratis
3. Se tiver Double Vision + Dawning Archaic: 3 copias da mesma spell
4. Cada copia ativa Storm-Kiln Artist = 3 treasures
5. **Resultado: Valor exponencial turno a turno.**

**Chain 3: Surge + Approach = Vitoria Garantida (T6+)**
1. Approach no cemiterio (cast anterior ou Faithless discard)
2. Surge to Victory: exile Approach, TODAS as criaturas atacantes dao copia
3. Com 3+ criaturas atacando: 3 copias de Approach -> vitoria garantida
4. **Com Twinflame:** +1 criatura = +1 copia. Com Rite (3 dragons) + Twinflame = 4 copias.
5. **Resultado: Vitoria deterministica com 3+ criaturas e Approach no grave.**

**Chain 4: Restoration Seminar -> Spell de Volta -> Token (T7+)**
1. T7+: Restoration Seminar -> retorna instant/sorcery do grave
2. Cria token 3/2 Lesson. Esse token pode ser sacrificado para Flare de Duplication.
3. **Resultado: Recursao + token que alimenta Flare.**

**Nota: 8/10.**

---

### D) MANA EXPLOSIVA -- Como o deck gera mana explosiva?

#### GERADORES DE TESOURO

| Carta | CMC | Tesouros/Turno | Condicao |
|:------|:---:|:-------------:|:---------|
| Smothering Tithe | 4 | 3+ | Passivo em 4-player |
| Storm-Kiln Artist | 4 | 4-7 | Cada spell cast/copiada |
| Big Score | 4 | 2 | Instant, one-shot |
| Unexpected Windfall | 4 | 2 | Instant, one-shot |
| Brass's Bounty | 7 | 7-10 | One-shot, escala com lands |
| Hit the Mother Lode | 7 | 7 | One-shot |

#### RITUAIS E RAMP ONE-SHOT

| Carta | CMC | Mana Gerada | Condicao |
|:------|:---:|:-----------:|:---------|
| Jeska's Will | 3 | 4-7 | Com commander |
| Sol Ring | 1 | 2 | Permanente |
| Ancient Tomb | 0 | 2 | Land |

#### MANA SINKS -- Para que serve tanta mana?

| Alvo | Custo | O que faz |
|:-----|:-----:|:----------|
| Storm Herd | 10 | X = PVs -> 20-40 Pegasus |
| Approach + Flare | 7 | Vitoria no mesmo turno |
| Insurrection | 8 | Rouba board |
| Mizzix's Mastery overload | 4 | Todos spells do grave gratis |
| Dance with Calamity | 8 | Exila 8, conjura gratis |
| Call Forth the Tempest | 8+X | Dano + dragoes + cascade |
| Improvisation Capstone | 7 | Exila 7, conjura gratis |
| Brass's Bounty | 7 | Converte lands em tesouros -> mais mana |

#### SEQUENCIA IDEAL DE MANA (T1-T6)

| Turno | Mana | Play |
|:-----:|:----:|:-----|
| T1 | 1-3 | Land Tax / Sol Ring / Top |
| T2 | 2-5 | Signet + Faithless / Scroll Rack |
| T3 | 3-7 | Tithe / Jeska's Will / Monument / Greaves |
| T4 | 4-10 | Lorehold + Big Score / Windfall / One Ring |
| T5 | 5-15 | Double Vision + Dance / Bombardment |
| T6+ | 8-20+ | Storm Herd, Approach+Flare, Insurrection, Mizzix |

**Nota: 7/10.** O deck gera mana explosiva mas depende de Tithe/Storm-Kiln para escalar.
Sem fast mana (Mana Vault, Chrome Mox), o early game e a fraqueza.
Tesouros sobrevivem a wipes -- vantagem estrutural.

---

### E) COMBO PIECES -- Existe combo deterministico?

#### COMBOS DETERMINISTICOS

**Combo 1: Approach + Topdeck Manipulation (2 cartas, deterministico)**
- Pecas: Approach + Sensei's Top OU Scroll Rack OU Penance
- Setup: Cast Approach -> com trigger na stack, ativar Top (draw Approach) ou Scroll Rack (colocar Approach no topo)
- Resultado: Proximo turno, cast Approach de novo = vitoria.
- Confiabilidade: 10/10. Com Enlightened Tutor e Gamble, altamente tutoravel.

**Combo 2: Approach + Flare of Duplication (2 cartas, deterministico, MESMO TURNO)**
- Pecas: Approach + Flare + qualquer criatura vermelha nao-ficha
- Setup: Cast Approach. Sacrifica criatura vermelha. Flare FREE -> copia Approach.
- Resultado: 2 casts de Approach no MESMO TURNO = vitoria IMEDIATA.
- Confiabilidade: 9/10.

**Combo 3: Surge to Victory + Approach (2 cartas, deterministico se 3+ criaturas)**
- Pecas: Approach no grave + Surge + 3+ criaturas atacando
- Resultado: 3+ copias de Approach -> vitoria garantida
- Confiabilidade: 8/10.

**Combo 4: Mizzix's Mastery overload (1 carta, semi-deterministico)**
- Pecas: Mizzix's + 8-15 instants/sorceries no grave
- Resultado: Conjura todos gratis. Com metade dos spells sendo removal/draw/wipe, gera valor massivo.
- Confiabilidade: 7/10.

#### SEMI-COMBOS

**Twinflame + Surge + Akroma's Will (3 cartas, exponencial):**
- Pecas: Twinflame + Surge + Akroma's Will + criatura + Approach no grave
- Resultado: Twinflame dobra criatura -> Surge copia Approach com N+1 criaturas -> Akroma buffa todas
- Confiabilidade: 6/10.

**Dance with Calamity + Scroll Rack (2 cartas, semi-deterministico):**
- Pecas: Dance + Scroll Rack
- Setup: Scroll Rack coloca 8 spells baratas no topo -> Dance exila e conjura todas gratis
- Resultado: 8 spells gratis em um turno
- Confiabilidade: 7/10.

**Nota: 9/10.** 4 caminhos deterministicos para vitoria. Approach+Flare e o mais confiavel (2 cartas, mesmo turno, nao precisa de board).

---

### F) STACK INTERACTION -- Como o deck interage na stack?

#### COUNTERSPELLS
**NENHUM.** Estrutural de Boros. Flare of Duplication pode COPIAR counterspell do oponente contra ele mesmo -- uso situacional.

#### PROTECAO NA STACK

| Carta | CMC | Efeito | Instant? |
|:------|:---:|:-------|:--------:|
| Deflecting Swat | 3 | Redireciona spell/ability | Instant |
| Hexing Squelcher | 2 | Oponentes nao ativam habilidades | Static (criatura) |
| Grand Abolisher | 2 | Oponentes nao conjuram no seu turno | Static (criatura) |
| Flare of Duplication | 3 | Copia spell alvo (pode copiar counterspell) | Instant |
| Teferi's Protection | 3 | Faseia voce e seus permanentes | Instant |
| Boros Charm | 2 | Indestrutivel (protege de remocao) | Instant |

#### INSTANT-SPEED REMOVAL

| Carta | CMC | Alvo |
|:------|:---:|:-----|
| Path to Exile | 1 | Criatura -> exila |
| Swords to Plowshares | 1 | Criatura -> exila |
| Abrade | 2 | Criatura (3 dano) ou artefato -> destroi |
| Chaos Warp | 3 | Permanente -> shuffle |
| Generous Gift | 3 | Permanente -> destroi |
| Olorin's Searing Light | 4 | Permanente -> exila |

#### COMO SOBREVIVE A UM COUNTERSPELL NO APPROACH?

1. **Boseiju, Who Shelters All** -- Channel: Approach se torna nao-counteravel. Custo: 2 mana + Boseiju.
2. **Cavern of Souls** -- Nomeie Dragon: Lorehold nao-counteravel. (Nao ajuda Approach -- e sorcery, nao Dragon.)
3. **Grand Abolisher** -- Se no campo, oponentes nao podem conjurar spells no seu turno.
4. **Deflecting Swat** -- Redireciona o counterspell para outra spell (ou para Swat mesmo, fizzla).
5. **Flare of Duplication** -- Se o oponente der counterspell no Approach, Flare copia o Approach na stack em resposta. A copia resolve ANTES do counterspell.

**Nota: 7/10.** Boseiju + Grand Abolisher + Deflecting Swat + Flare = 4 camadas de protecao anti-counterspell.
Hexing Squelcher cobre habilidades (Thassa's Oracle, Kiki-Jiki).

---

### G) GRAVEYARD HATE & RESILIENCE -- Como o deck sobrevive a hate?

#### DEPENDENCIA DO CEMITERIO

| Carta | Dependencia | Se exilarem o grave, perde funcionalidade? |
|:------|:-----------:|:-------------------------------------------|
| Mizzix's Mastery | **ALTA** | SIM -- totalmente inutilizada sem grave |
| Arcane Bombardment | **ALTA** | SIM -- se exilarem as cartas ja exiladas por Bombardment |
| Surge to Victory | **ALTA** | SIM -- precisa de Approach/sorcery no grave |
| Lorehold (commander) | **ALTA** | SIM -- sem spells no grave, commander faz nada |
| Restoration Seminar | **MEDIA** | Parcial -- ainda cria Lesson token, mas perde recursao |
| Faithless Looting | **BAIXA** | Nao -- flashback ainda funciona se nao exilar |
| Dragon's Rage Channeler | **BAIXA** | Parcial -- surveil funciona, delirium enfraquece |
| Olorin's Searing Light | **BAIXA** | Nao -- ainda e removal |

#### SE UM OPONENTE JOGAR REST IN PEACE, O DECK PERDE?

**Impacto: ALTO.** Rest in Peace anula Mizzix's Mastery, Arcane Bombardment, Surge to Victory, Lorehold, Restoration Seminar.

**Mas o deck NAO FICA INUTILIZADO:**
- Token makers (Rite, Storm Herd, Emeria's Call) nao usam grave
- Pumps (Boros Charm, Akroma's Will) nao usam grave
- Approach + Flare de Duplication nao usam grave
- Insurrection nao usa grave
- Dance with Calamity e Improvisation Capstone nao usam grave
- Smothering Tithe, Jeska's Will, tesouros -- nao usam grave
- Twinflame -- nao usa grave

**Plano B sem cemiterio:**
1. Token army (Rite + Storm Herd)
2. Akroma's Will / Boros Charm pump
3. Approach + Flare = vitoria no mesmo turno
4. Insurrection

**Respostas a Rest in Peace / Leyline of the Void:**

| Resposta | CMC | Eficacia |
|:---------|:---:|:--------:|
| Chaos Warp | 3 | Shuffle -- remove permanente problematico sem destruir |
| Generous Gift | 3 | Destroi qualquer permanente |
| Boseiju, Who Shelters All | 2 (Channel) | Channel -- nao e spell, nao pode ser counterada |
| Abrade | 2 | So artefatos (RiP e encantamento) |
| Olorin's Searing Light | 4 | Exila encantamento/artefato |

**Conclusao: 4 respostas para RiP/Leyline.**
Com Flare de Duplication, o plano B (Approach+Flare) ganha sem cemiterio E sem combate.

**Graveyard Resilience Score: 6/10.** Ainda ha dependencia alta (Mizzix's, Bombardment, Surge, Lorehold), mas o plano B e mais forte.

---

## Secao 4: DOUBLE-NULL AUDIT (pos-Ciclo #13)

### Cartas sem classificacao (functional_tag IS NULL AND 0 card_tags)

| Carta | CMC | EDHREC | Trend | Risco | Acao |
|:------|:---:|:------:|:-----:|:-----:|:-----|
| **Scroll Rack** | 2 | 59.7% | +0.15 | NAO CORTAR | Core engine. Topdeck manipulation. Nivel 4. |
| **Penance** | 3 | 41.8% | +1.15 | NAO CORTAR | Topdeck setup + anti-removal. Miracle enabler. Nivel 4. |
| **Taunt from the Rampart** | 5 | 35.2% | +0.10 | MANTER | 35.2% EDHREC estavel. Goad util em multiplayer. Nivel 2. |
| **Grand Abolisher** | 2 | 11.7% | -0.27 | MONITORAR | UNICA protecao proativa anti-counterspell. Nivel 2. |

**Resumo: 4 double-nulls (eram 10 no baseline).**
- 2 sao core engines (Scroll Rack, Penance) -- NAO TOCAR
- 1 e declining leve com funcao unica (Grand Abolisher) -- MANTER
- 1 e estavel com EDHREC medio (Taunt) -- MANTER

### Double-nulls cortados desde baseline

| Carta | Ciclo | Motivo |
|:------|:-----:|:-------|
| Deflecting Palm | #2 | Substituido por Big Score |
| Orim's Chant | #3 | Substituido por Blasphemous Act |
| Victory Chimes (original) | #3 | Substituido por Generous Gift (depois re-entrou C#7) |
| Galadriel's Dismissal | #7 | 0% EDHREC. Substituido por Victory Chimes |
| Pearl Medallion | #9 | Declinio -0.46. Substituido por Akroma's Will |
| Ruby Medallion | #10 | Declinio -0.37. Substituido por Twinflame |

---

## Secao 5: TREND ANALYSIS (inalterado desde v3.10)

### Cartas em Declinio no Deck (trend < -0.2)

| Carta | EDHREC | Trend | Ciclos em Declinio | Acao |
|:------|:------:|:-----:|:------------------:|:-----|
| Esper Sentinel | 32.5% | -0.54 | 6 | Monitorar -- EDHREC ainda alto |
| Grand Abolisher | 11.7% | -0.27 | 3+ | MANTER -- unica protecao proativa anti-counterspell |
| Call Forth the Tempest | 65.5% | -0.30 | 2 | Manter -- alta EDHREC |
| Fated Clash | 15.6% | -0.19 | 3+ | Monitorar -- no limiar |

### Rising Stars (ja no deck)

| Carta | EDHREC | Trend | Ciclos em Alta |
|:------|:------:|:-----:|:--------------:|
| Restoration Seminar | 37.8% | +9.14 | 5+ |
| Improvisation Capstone | 49.0% | +8.09 | 5+ |
| The Dawning Archaic | 24.0% | +5.31 | 5+ |
| Storm-Kiln Artist | 55.4% | +0.76 | 4 |
| Penance | 41.8% | +1.15 | 3 |
| Hit the Mother Lode | 79.4% | +1.29 | 3 |
| Chaos Warp | 38.8% | +0.46 | 2 |

---

## Secao 6: ANALISE DE MATCHUPS (via BATTLE_LOG Exec#8)

| Arquetype | Win Rate | Maior Fraqueza |
|:----------|:--------:|:---------------|
| Control | 56.0% | -- (Boros > Control com Boseiju + Cavern + Grand Abolisher + Flare) |
| Midrange | 53.2% | -- (valor supera) |
| Aggro | 51.8% | -- (wipes + lifegain do One Ring) |
| **Combo** | **46.5%** | **Sem counterspell. Depende de remocao instantanea + Hexing Squelcher.** |

> **Nota:** BATTLE_LOG data e de pos-Ciclo #4 (Exec#8). O deck melhorou significativamente (+9 ciclos desde entao: Akroma's Will, Flare, Twinflame, Chaos Warp, Wedding Ring, Victory Chimes, Abrade). Win rates atuais provavelmente sao melhores, especialmente contra Control (Flare anti-counterspell) e Combo (Hexing Squelcher + Flare copia spells do oponente).

---

## Secao 7: O PLANO DE JOGO -- Turn by Turn (T3 CONFIRMADO 13.3%)

### T1 (Setup Inicial)
**Objetivo:** Ramp + topdeck setup
**Cartas ideais:** Sol Ring, Land Tax, Weathered Wayfarer, Sensei's Top, Library of Leng, Gamble, Enlightened Tutor, Esper Sentinel, Dragon's Rage Channeler

### T2 (Ramp Secundario + Draw/Loot)
**Objetivo:** Fixing + draw/loot + protecao
**Cartas ideais:** Arcane/Boros Signet, Talisman, Faithless Looting, Thrill of Possibility, Scroll Rack, Twinflame, Lightning Greaves, Grand Abolisher, Hexing Squelcher

### T3 (Protecao + Engine Setup)
**Objetivo:** Estabelecer protecao + preparar Lorehold
**Cartas ideais:** Greaves, Grand Abolisher, Hexing Squelcher, Smothering Tithe, Archaeomancer's Map, Jeska's Will, Monument to Endurance, Wedding Ring, Flare of Duplication

**T3 = 13.3% CONFIRMADO (Exec#11, N=1000, seed=42).** Melhoria de -3.6pp vs pos-C#9.
Aproximadamente 1 a cada 7.5 jogos o deck nao tem play T3.

Em maos com 3 lands (28.9%), o Flare de Duplication (CMC 3) e castavel -- transformou maos que antes eram "sem play" com Galvanoth (CMC 5) em maos jogaveis. Este swap foi o responsavel pela melhoria de -3.6pp.

### T4 (Lorehold + Valor)
**Objetivo:** Conjurar Lorehold + gerar valor imediato
**Cartas ideais:** Lorehold, Big Score, Unexpected Windfall, The One Ring, Storm-Kiln Artist, Akroma's Will (defensivo)

### T5 (Motor Arrancado)
**Objetivo:** Copy engines + free spells
**Cartas ideais:** Double Vision, Arcane Bombardment, Dance with Calamity, Improvisation Capstone, The Dawning Archaic

### T6+ (Fechar o Jogo)
**Objetivo:** Wincon
**Cartas ideais:** Approach + Flare (7 mana + criatura vermelha = vitoria NO MESMO TURNO), Insurrection + Boros Charm/Akroma's Will, Storm Herd + Akroma's Will, Mizzix's Mastery overload, Surge + Approach + Twinflame

**8+ paths de vitoria FUNCIONAIS e DIVERSOS.**

---

## Secao 8: GAPS E PROBLEMAS (ATUALIZADO para Ciclo #13)

### GAP #1: Sem Play T3 = 13.3% (DEFENSIVO) -- CONFIRMADO

| Metrica | Pos-C#9 (Exec#10) | Pos-C#10 (Exec#11) | Delta | Limite |
|:--------|:-----------------:|:------------------:|:-----:|:------:|
| Sem Play T3 | 16.9% | **13.3%** | **-3.6pp** | 12% |
| Ramp T1 (Sol Ring only) | ~7% | **6.3%** | -0.7pp | -- |
| Jogaveis | 46.3% | **46.7%** | +0.4pp | -- |

**Causa raiz:** Apenas 3 fontes de ramp T1 estrito (Sol Ring, Land Tax, Weathered Wayfarer -- sendo que Land Tax e Wayfarer buscam lands para a mao, nao aceleram mana T1).
**Limite estrutural de jogaveis: ~47%.** Com 35 lands e 3 fontes de T1 ramp, mesmo com DCMC otimizado, o teto de jogaveis e ~47%. Para ultrapassar, precisa de fast mana CMC 0-1 (Chrome Mox, Mana Vault).
**Solucao viavel:** Apenas via AQUISICAO. Nenhuma carta na colecao reduz T3.

Impacto real do DCMC documentado:
- DCMC=-2 (Ciclo #10): -3.6pp T3 (quase o DOBRO do projetado -1.9pp)
- DCMC=-15 (Ciclo #4): -4.4pp T3 (16.5% -> 12.0%)
- Relacao empirica: ~1.5-2.0pp T3 por -1 DCMC efetivo (CMC removido)

### GAP #2: Draw real = 7 (1 abaixo do perfil minimo de 8)

Draw real = 7 fontes: Esper Sentinel, Thrill of Possibility, Dragon's Rage Channeler, The One Ring, Valakut Awakening, Wedding Ring, Victory Chimes.
Skullclamp (aquisicao, $5-8) resolveria -- transforma tokens em draw 2.

### GAP #3: Colecao esgotada de CMC <= 2

Apos 25 swaps, a colecao de cartas CMC <= 3 com EDHREC > 15% que NAO estao no deck esta VAZIA.
48+ candidatos avaliados entre C#11, C#12, C#13 -- NENHUM atinge Necessidade >= 3 + Evidencia >= 3.

| Carta Desejada | CMC | Funcao | EDHREC | Custo Aprox |
|:---------------|:---:|:-------|:------:|:-----------:|
| Skullclamp | 1 | Draw engine | 45% | $5-8 |
| Mana Vault | 1 | Fast mana | Staple | $40-60 |
| Chrome Mox | 0 | Fast mana | Staple | $60-80 |
| Underworld Breach | 2 | Recursion massiva | 35% | $15-20 |

### GAP #4: Fated Clash (15.6% EDHREC) -- no limiar

Fated Clash e o board wipe mais fraco do deck (bounce 1 por oponente, CMC 5).
Com EDHREC 15.6% e trend -0.19, esta no limiar de corte. Mas sem substituto viavel na colecao.

### GAP #5: Sem bounce universal

Cyclonic Rift e azul. O deck depende de remocao pontual. Em mesas com muitos encantamentos/artefatos problematicos, a remocao pontual pode ser insuficiente.

---

## Secao 9: ESTRATEGIA PARA CICLO #14

### Situacao Atual

| Indicador | Valor | Interpretacao |
|:----------|:-----:|:--------------|
| T3 | 13.3% | DEFENSIVE (>12%) |
| Nivel 1 | VAZIO | Sem cartas cortaveis |
| Colecao | ESGOTADA | 48+ candidatos rejeitados em 3 ciclos |
| Candidatos CMC <= 2 | 0 | Nenhum com Nec >= 3 |
| Confianca na Maturidade | ALTA | 3 ciclos consecutivos sem swaps |

### Estrategia: MANTER ESTADO ATUAL ate AQUISICAO

**Cenario A (Skullclamp adquirido):**
- Swap: Fated Clash (CMC 5) -> Skullclamp (CMC 1)
- Net DCMC = -4
- T3 projetado: 13.3% -> ~10-11% (BALANCED)
- Draw: 7 -> 8 (atinge perfil minimo)
- **Prioridade ABSOLUTA: menor custo ($5-8), maior impacto por dolar.**

**Cenario B (sem aquisicoes):**
- 0 swaps. Mesmo estado.
- T3 estavel em 13.3%.
- Deck permanece saudavel sem mudancas.
- **Este e o cenario mais provavel para C#14.**

**Cenario C (Chrome Mox ou Mana Vault adquirido):**
- Fast mana CMC 0-1 mudaria o teto estrutural de jogaveis (~47% -> ~55%)
- Custo: $40-80. Impacto T3: -3 a -5pp.

### Projecao do T3 por cenario

| Cenario | Swap | Net DCMC | T3 Projetado | Estrategia Resultante |
|:--------|:-----|:--------:|:------------:|:---------------------|
| A: Skullclamp | Fated Clash -> Skullclamp | -4 | ~10-11% | BALANCED |
| B: Sem aquisicao | 0 swaps | 0 | 13.3% | DEFENSIVE (estavel) |
| C: Chrome Mox | +Chrome Mox, -CMC 3-4 | -3 a -4 | ~10-11% | BALANCED |
| D: Mana Vault | +Mana Vault, -CMC 3-4 | -3 a -4 | ~10-11% | BALANCED |

### Recomendacao para o Evolution Oracle (Ciclo #14)

1. **0 SWAPS** a menos que Skullclamp/Chrome Mox/Mana Vault seja adquirido.
2. **NAO forcar swaps de sidegrade** -- 48+ candidatos ja foram rejeitados. Nao ha mais o que avaliar.
3. **Se SCOUT encontrar novos candidatos** (Exec #23+), avaliar pelo framework Necessidade/Evidencia com corte Nec>=3 + Evid>=3.
4. **Documentar a persistencia da maturidade** no EVOLUTION_LOG.
5. **Recomendar a aquisicao de Skullclamp** como proximo passo.

---

## Secao 10: RESUMO EXECUTIVO

### Estado do Deck: EXCELENTE (Pos-Ciclo #13, 25 swaps, MATURIDADE PERSISTENTE -- 3 ciclos consecutivos sem swaps)

| Indicador | Status |
|:----------|:------:|
| Motor | 4/4 COMPLETO |
| Copy Engines | 6 ativas |
| Token+Pump | 8/10 |
| Wipes+Protection | 8/10 |
| Recursion | 8/10 |
| Mana Explosiva | 7/10 |
| Combo Pieces | **9/10** |
| Stack Interaction | **7/10** |
| Graveyard Resilience | **6/10** |
| **Sem Play T3** | **13.3% CONFIRMADO** |
| Draw Real | 7 (perfil 8-12) |
| Double-nulls restantes | 4 (0 cortaveis) |
| Nivel 1 | **VAZIO** |
| Colecao | **ESGOTADA (48+ candidatos rejeitados em 3 ciclos)** |
| Confianca na Maturidade | **ALTA (C#11=C#12=C#13=0 swaps)** |

### Top 3 GAPS

1. **Sem Play T3 = 13.3% (DEFENSIVE)** -> So 3 fontes de ramp T1 estrito. Limite estrutural de ~47% jogaveis. Solucao requer aquisicao de fast mana (Chrome Mox, Mana Vault) ou draw engine (Skullclamp).

2. **Colecao esgotada** -> Nenhum upgrade CMC <= 2 disponivel. 48+ candidatos avaliados em 3 ciclos consecutivos (C#11, C#12, C#13). O deck atingiu maturidade maxima com a colecao atual. **25 swaps em 13 ciclos (10 ciclos com swaps, 3 ciclos consecutivos sem).**

3. **Draw = 7 (vs 8-12 perfil)** -> -1 do minimo. Skullclamp ($5-8) resolveria. Prioridade #1 de aquisicao.

### Destaques do v3.12

1. **MATURIDADE PERSISTENTE CONFIRMADA.** 3 ciclos consecutivos (C#11, C#12, C#13) sem swaps. 48+ candidatos avaliados e rejeitados pelo framework Necessidade/Evidencia.

2. **SCOUT #21 e #22 propuseram 10 novos candidatos synergy-first.** Todos rejeitados com justificativa documentada. O framework Necessidade/Evidencia continua sendo o gatekeeper correto.

3. **Confianca ALTA na maturidade.** A validacao multipla (3 ciclos, 48+ candidatos) fornece confianca estatistica de que a colecao esta realmente esgotada para este deck.

4. **Deck permanece FUNCIONAL e COMPETITIVO.** Motor 4/4. Copy 6. 8+ paths de vitoria. 7 eixos de sinergia pontuando 6-9/10. Nivel 1 vazio. Double-nulls seguros. Nao ha filler.

5. **O unico caminho para melhoria e AQUISICAO de cartas.** Skullclamp ($5-8) e a prioridade #1 -- menor custo, maior impacto (resolve draw + T3 simultaneamente).

### Mudancas desde baseline (25 swaps em 13 ciclos)

| Ciclo | Swaps | Net DCMC | Estrategia | T3 Aprox |
|:-----:|:-----:|:--------:|:----------|:---------|
| #1 | 3 | ~+3 | AGGRESSIVE | 12.4% |
| #2 | 3 | ~+4 | AGGRESSIVE | 16.5% |
| #3 | 5 | ~-4 | DEFENSIVO | 16.4% |
| #4 | 3 | -15 | DEFENSIVO | 12.0% |
| #5 | 3 | +1 | BALANCED | 15.3% |
| #6 | 2 | -2 | DEFENSIVO | ~13-14% |
| #7 | 1 | +2 | AGGRESSIVE* | ~14-15% |
| #8 | 0 | 0 | (0 swaps) | ~14-15% |
| #9 | 1 | +2 | AGGRESSIVE* | 16.9% |
| #10 | 2 | -2 | DEFENSIVO | **13.3%** |
| #11 | 0 | 0 | (0 swaps) | **13.3%** |
| #12 | 0 | 0 | (0 swaps) | **13.3%** |
| #13 | 0 | 0 | (0 swaps) | **13.3%** |

*Ciclos #7/#8/#9 usaram T3=3.7% (free mulligan rate) em vez do Sem Play T3 correto.

### Licao do v3.12: Maturidade e um Estado, Nao um Evento

A maturidade do deck nao foi um evento pontual -- foi um processo de 13 ciclos:
- Ciclos #1-#10: 25 swaps, otimizacao agressiva, correcao de gaps
- Ciclos #11-#13: 0 swaps, 48+ candidatos rejeitados, validacao multipla

A validacao multipla (3 ciclos consecutivos) confirma que:
1. O framework Necessidade/Evidencia e robusto -- nao ha falsos negativos
2. A colecao esta genuinamente esgotada -- nao e um vies de analise
3. O deck e estavel -- 13.3% T3 e consistente, motor 4/4 e estavel

O proximo passo nao e mais analise -- e ACAO (aquisicao de cartas).

---

*Relatorio gerado por Purpose Analyzer v3.12 em 2026-05-31T21:11:43+00:00*
*Analista: Hermes Agent -- Agente 2 (Lorehold Purpose Analyzer)*
*Proximo passo: Aguardar aquisicao de Skullclamp. Se adquirido, Ciclo #14: Fated Clash -> Skullclamp (DEFENSIVO, DCMC=-4, T3 projetado ~10%). Senao, 0 swaps pela 4a vez consecutiva.*
