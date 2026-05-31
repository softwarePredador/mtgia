# Purpose Analyzer v3.8 — Lorehold Spellslinger: SYNERGY_MAP

> **Data:** 2026-05-31T13:00:00Z
> **Fonte:** knowledge.db deck_id=6 (pos-Ciclo #8, 22 swaps aplicados)
> **Deck:** Lorehold Spellslinger — 100 cards, 86 rows, 35 lands
> **Analista:** Hermes Agent — Purpose Analyzer v3.8
> **Foco:** Classificacao estrategica completa + SYNERGY_MAP (5 eixos)

---

## Secao 1: Visao Geral do Deck

### Metricas Recalculadas (pos-Ciclo #8)

| Metrica | Deck Real | Perfil EDHREC | Status |
|:--------|:---------:|:--------------|:-------|
| Lands | 35 | 36-38 | OK (-1, MDFCs contam) |
| Ramp | 14 | 10-13 | +1 (treasure-heavy) |
| Draw (real) | 7 | 8-12 | -1 (melhorou +2 desde v3.7) |
| Removal | 6 | 4-6 | No range |
| Board Wipe | 5 | 3-5 | No limite |
| Protection | 6 | 3-4 | Acima (seguro) |
| Recursion | 4 | 2-5 | No range |
| Wincon (dedicado) | 1 | 4-7 | Muito abaixo (TAG, nao deck) |
| Engine/Big Spell | 12 | 5-8 | Acima (motor 4/4 + copy 3/3) |
| Tutor | 1 | -- | Baixo (so Gamble) |
| CMC medio | ~3.8 | ~4.1 | OK |

### Deck Health (pos-Ciclo #8)

| Indicador | Valor | Interpretacao |
|:----------|:-----:|:--------------|
| Motor | 4/4 COMPLETO | Treasure Ramp -> Big Spell Free -> Copy -> Payoff |
| Copy Engines | 3/3 COMPLETO | Double Vision + Arcane Bombardment + Lorehold |
| Sem Play T3 | 3.7% | EXCELENTE (<< 8%) |
| Mulligan Rate | 41.5% | Estrutural (35 lands, 3 T1 ramp) |
| Jogaveis | 48.4% | Boros com 35 lands |
| Ramp T1 | 19.7% | Limite do formato |
| Draw Real | 7 fontes | A 1 fonte do minimo do perfil |

---

## Secao 2: CLASSIFICACAO ESTRATEGICA — TODAS as Cartas

Cada carta classificada por **Importancia Estrategica (1-5)** e **Funcao Real**
(corrigindo functional_tags incorretas do banco).

### Nivel 5: NAO SE JOGA SEM (Core Identity)

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 5 |
|:------|:---:|:------:|:------------|:------------------|
| **Lorehold, the Historian** | 5 | -- | engine, draw | Commander. Copia instants/sorceries do grave + da desconto de 1. Define o deck. |
| **Approach of the Second Sun** | 7 | 63.8% | wincon | Wincon primaria. Com topdeck manipulation, deterministico. Copiavel pelo Lorehold. |
| **Mizzix's Mastery** | 4 | 57.5% | recursion, wincon | Overload = conjura TODOS instants/sorceries do grave gratis. Com Double Vision + Bombardment, fecha jogos. |

### Nivel 4: CORE DA ESTRATEGIA (Define o plano de jogo)

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 4 |
|:------|:---:|:------:|:------------|:------------------|
| **Dance with Calamity** | 8 | 67.0% | engine, free_spell | Exila top 8, conjura spells gratis. Motor componente #2. |
| **Double Vision** | 5 | 46.6% | engine, copy | Primeira spell por turno copiada. Copy layer #1. |
| **Arcane Bombardment** | 5 | 42.5% | engine, copy, recursion | Exila e copia 1a spell a cada turno. Copy layer #2 + recursion passiva. |
| **Smothering Tithe** | 4 | 45.9% | ramp, treasure | 3+ treasures por turno em 4-player. Alimenta TODO o motor. |
| **Storm-Kiln Artist** | 4 | 55.4% | ramp, treasure, payoff | Cada spell cast/copiada = Treasure. Com Lorehold + Double Vision, 3-5 treasures/turno. Fecha o motor. |
| **Improvisation Capstone** | 7 | 49.0% | engine, free_spell | Exila top 7, conjura gratis. Rising star (+8.09). Motor componente #2. |
| **Scroll Rack** | 2 | 59.7% | topdeck, draw_virtual | Reordena topo, ativa Lorehold count. Double-null do classificador. Core engine. |
| **Penance** | 3 | 41.8% | topdeck, protection | Setup de topdeck + anti-removal. Miracle enabler. Double-null do classificador. |

### Nivel 3: SUPORTE FORTE (Sinergia consistente, deck piora sem)

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 3 |
|:------|:---:|:------:|:------------|:------------------|
| **Sensei's Divining Top** | 1 | 66.9% | draw, topdeck | Draw + topdeck contínuo. Com fetch, valor recorrente. |
| **Faithless Looting** | 1 | 29.7% | draw, loot, graveyard | Draw 2 discard 2 + flashback. Preenche grave para Mizzix's. |
| **Jeska's Will** | 3 | 41.9% | ramp, ritual, draw | RRR + exile top 3. Em 4-player: ~5R + 3 cartas. Copiado: 10R + 6 cartas. |
| **Teferi's Protection** | 3 | 21.2% | protection | Faseia TUDO. Responde a qualquer wipe, combo, ou ataque. Salva jogos. |
| **Boros Charm** | 2 | 45.5% | protection, pump | Indestrutivel (protege de wipes) OU double strike (fecha jogos). Versatil. |
| **The One Ring** | 4 | 8.5% | draw, protection | Draw engine + protecao 1 turno. Game Changer. |
| **Insurrection** | 8 | 45.3% | wincon, steal | Rouba TODAS as criaturas com haste. Game-ender em meta creature-heavy. |
| **Surge to Victory** | 6 | 63.5% | recursion, wincon | Exila spell do grave, criaturas causam dano = copia. Com Approach: auto-win. |
| **Volcanic Vision** | 7 | 63.9% | board_wipe, recursion | Dano = CMC revelada + retorna spell a mao. Wipe assimetrico + valor. |
| **Hit the Mother Lode** | 7 | 79.4% | ramp, treasure, token | Discover 10 + 7 treasures. 79.4% — carta mais inclusiva do deck. |
| **Brass's Bounty** | 7 | 63.2% | ramp, treasure | X treasures por land. ~7-10 em media, 14-20 copiado. |
| **Call Forth the Tempest** | 8 | 65.5% | board_wipe, cascade | Dano massivo + cascade. Pode cascade em Approach. |
| **Wedding Ring** | 4 | -- | draw | Draw simetrico. Em 4-player, draw passivo toda rodada. |
| **Victory Chimes** | 3 | 53.6% | draw | Draw em artifact ETB. 15+ artifacts no deck = draw consistente. |
| **Restoration Seminar** | 7 | 37.8% | recursion, token | Retorna instant/sorcery do grave + cria token. Rising star (+9.14). |
| **The Dawning Archaic** | 3 | 24.0% | engine, free_spell | Conjura copia de spell do oponente. Rising star confirmada (+5.31). |

### Nivel 2: UTILIDADE SITUACIONAL (Bom ter, mas substituivel se necessario)

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 2 |
|:------|:---:|:------:|:------------|:------------------|
| **Austere Command** | 6 | 69.6% | board_wipe | Wipe modular — pode escolher nao destruir criaturas. Versatil. |
| **Blasphemous Act** | 9 | 64.0% | board_wipe | Custo reduzido por criatura. Tipicamente R. Excelente. |
| **Deflecting Swat** | 3 | 36.8% | protection | Redireciona spell/ability. Responde a counterspell. |
| **Lightning Greaves** | 2 | 45.3% | protection | Shroud + haste. Protege Lorehold. |
| **Grand Abolisher** | 2 | 11.7% | protection | Oponentes nao conjuram no seu turno. Double-null. |
| **Hexing Squelcher** | 2 | 40.9% | protection | Oponentes nao ativam habilidades. |
| **Chaos Warp** | 3 | 38.8% | removal | Removal universal — unica que lida com qualquer permanente. |
| **Swords to Plowshares** | 1 | 56.1% | removal | Premium removal. |
| **Path to Exile** | 1 | 51.6% | removal | Premium removal. |
| **Generous Gift** | 3 | 44.9% | removal | Destroi qualquer permanente. |
| **Abrade** | 2 | 47.5% | removal | Removal versatil — criatura ou artefato. |
| **Enlightened Tutor** | 1 | 49.4% | tutor | Busca artefato ou encantamento. Busca Top, Greaves, One Ring, etc. |
| **Gamble** | 1 | 44.3% | tutor | Tutor universal com risco de descarte. |
| **Esper Sentinel** | 1 | 32.5% | draw | Draw condicional. 5o ciclo em declinio (-0.54). |
| **Thrill of Possibility** | 2 | 13.9% | draw, loot | Draw 2 discard 1, instant. Preenche grave. |
| **Dragon's Rage Channeler** | 1 | 41.7% | graveyard, selection | Surveil + selection. Preenche grave para delirium. |
| **Big Score** | 4 | 55.8% | ramp, treasure, loot | Discard 1, draw 2, 2 treasures. Instant. |
| **Unexpected Windfall** | 4 | 18.6% | ramp, treasure, loot | Discard 1, draw 2, 2 treasures. Instant. |
| **Reforge the Soul** | 5 | 44.0% | draw, wheel | Wheel — draw 7. Reset de mao. |
| **Galvanoth** | 5 | 26.5% | engine, free_spell | Upkeep: revela e conjura spell gratis do topo. |
| **Rite of the Dragoncaller** | 6 | 40.4% | token, payoff | 5/5 Dragon a cada spell. Bom payoff para spellslinger. |
| **Storm Herd** | 10 | 75.1% | token, wincon | X Pegasus = PVs. Com 40 PVs, 40 tokens. Game-ender. |
| **Archaeomancer's Map** | 3 | 29.3% | ramp | Land ramp condicional. Boros precisa. |
| **Land Tax** | 1 | 55.7% | ramp | 3 lands/ turno. Ramp consistente. |
| **Weathered Wayfarer** | 1 | 39.3% | ramp, tutor | Busca ANY land, incluindo Ancient Tomb, Boseiju, Urza's Saga. |
| **Sol Ring** | 1 | 84.3% | ramp | Staple. Melhor rock do formato. |
| **Boros Signet** | 2 | 50.4% | ramp | Signet estavel. |
| **Arcane Signet** | 2 | 80.2% | ramp | Staple. |
| **Talisman of Conviction** | 2 | 62.1% | ramp | Ramp com dano opcional. |
| **Monument to Endurance** | 3 | 41.3% | engine, draw | Draw + loot + drain. Multi-funcao. Double-null parcial. |
| **Library of Leng** | 1 | 77.8% | hand, graveyard | Sem limite de mao + descarte no topo. Com Faithless = topdeck setup. |
| **Valakut Awakening** | 3 | 35.7% | draw, hand_reset | MDFC. Hand reset + draw. Pode ser land. |
| **Emeria's Call** | 7 | 43.4% | token, land | MDFC. Angel tokens OU land. Flexibilidade. |
| **Longshot, Rebel Bowman** | 4 | 27.3% | payoff | Commander payoff — bolt sempre que Lorehold ataca/bloqueia. |
| **Bender's Waterskin** | 3 | 22.8% | ramp | Rock ou tutora land. Flexivel. |
| **Fated Clash** | 5 | 15.6% | board_wipe | Bounce 1 por oponente + scry. Wipe mais fraco. |
| **Olorin's Searing Light** | 4 | 49.6% | removal, graveyard | Exila permanente + instant/sorcery do grave. Versatil. |

### Nivel 1: SUBSTITUIVEL (Candidato natural a corte)

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 1 |
|:------|:---:|:------:|:------------|:------------------|
| **Pearl Medallion** | 2 | 25.2% | ramp, cost_reduction | Double-null. Desconto de 1 em 23 spells brancos. Trend -0.46 (5o ciclo em declinio). Marginal. |
| **Ruby Medallion** | 2 | 42.3% | ramp, cost_reduction | Double-null. Desconto de 1 em ~40 spells vermelhos. Melhor que Pearl, mas tesouro supera cost reduction. Trend -0.37. |
| **Taunt from the Rampart** | 5 | 35.2% | goad, control | Double-null. Goad em todas as criaturas. 35.2% EDHREC — nao e fraco, mas e situacional. |

### Lands — Classificacao

| Carta | Funcao Real | Nota |
|:------|:------------|:-----|
| Ancient Tomb | ramp | Sol land. Acelera T2 Lorehold. |
| Arid Mesa, Bloodstained Mire, Flooded Strand, Scalding Tarn, Windswept Heath | fetch, ramp | 5 fetches. Alimentam Scroll Rack + Sensei's Top + Land Tax. |
| Boseiju, Who Shelters All | protection, removal | Channel — destrói artefato/encantamento nao-counteravel. |
| Cavern of Souls | protection | Nomeia Dragon — Lorehold nao-counteravel. |
| Clifftop Retreat, Inspiring Vantage, Sundown Pass | fixing | Boros fixing. |
| Command Tower, Exotic Orchard, Sacred Foundry, Dormant Volcano | fixing, ramp | Color fixing + Dormant Volcano = Sol land lenta. |
| Kor Haven | protection | Fog por criatura atacante. |
| Urza's Saga | tutor, token, ramp | Busca Sol Ring, Top, Library of Leng. Cria Constructs. Massivamente sobrecarregada. |
| 8x Mountain, 8x Plains | basic | Basics — Land Tax + Wayfarer targets. |

---

## Secao 3: SYNERGY_MAP — O Coracao do Deck

### A) TOKEN MAKERS + PUMP — Como o deck transforma tokens em vitoria?

#### TOKEN MAKERS (criaturas)

| Carta | CMC | O que cria | Quantidade | Condicao |
|:------|:---:|:-----------|:----------:|:---------|
| Rite of the Dragoncaller | 6 | Dragon 5/5 flying | 1/cast | Cada instant/sorcery = 1 dragon |
| Storm Herd | 10 | Pegasus 1/1 flying | X = PVs | Com 40 PVs = 40 tokens |
| Emeria's Call (MDFC) | 7 | Angel 4/4 flying | 2 | Cria 2 angels |
| Longshot, Rebel Bowman | 4 | -- | 0 | Nao cria token, mas payoff de commander |

#### TOKEN MAKERS (tesouros — usados para mana, nao combate)

| Carta | CMC | O que cria | Quantidade |
|:------|:---:|:-----------|:----------:|
| Smothering Tithe | 4 | Treasure | 3+/turno (passivo) |
| Storm-Kiln Artist | 4 | Treasure | 1/cast ou copia |
| Big Score | 4 | Treasure | 2 |
| Unexpected Windfall | 4 | Treasure | 2 |
| Brass's Bounty | 7 | Treasure | X = lands (~7-10) |
| Hit the Mother Lode | 7 | Treasure | 7 |

#### PUMP / DANO EM MASSA

| Carta | CMC | Efeito | Escala |
|:------|:---:|:-------|:-------|
| Boros Charm | 2 | Double strike para TODAS as criaturas | Multiplica dano por 2 |
| Surge to Victory | 6 | Exila spell do grave, criaturas dao dano = copia da spell | Cada criatura = 1 copia |
| Insurrection | 8 | Rouba TODAS as criaturas, da haste | Todo o board dos oponentes |
| Call Forth the Tempest | 8 | Dano a cada criatura + cascade | Limpa + valor |

#### PARES TOKEN + PUMP — Calculo de Dano

**Rite of the Dragoncaller + Boros Charm:**
- Estado tipico (T6+): 3 dragons 5/5 no campo
- Boros Charm double strike: 3 x (5 x 2) = 30 flying damage
- Com 5 dragons: 50 flying damage
- **Conclusao: Mata 1-2 jogadores.**

**Storm Herd + Boros Charm:**
- Com 40 PVs: 40 Pegasus 1/1 flying
- Boros Charm double strike: 40 x 2 = 80 flying damage
- **Conclusao: Mata a mesa INTEIRA.**

**Rite + Surge to Victory:**
- Exila Approach of the Second Sun com Surge
- 3+ dragons causam dano = 3+ copias de Approach (contam pro clock das 7 cartas)
- **Conclusao: Ganha na HORA.**

**Insurrection:**
- Rouba 20+ criaturas com haste. Com Boros Charm double strike: dano letal.
- **Conclusao: Game-ender autonomo.**

#### ANALISE DO PLANO TOKEN+PUMP

| Forca | Fraqueza |
|:------|:---------|
| Multiplos token makers em CMCs diferentes | So 1 pump real (Boros Charm) |
| Storm Herd + Boros Charm = dano letal | Surge to Victory depende de ter Approach no grave |
| Dragons 5/5 sao ameacas reais, nao so tokens | Sem lords ou anthem effects |
| Insurrection e game-ender autonomo | Rite of the Dragoncaller pode ser lento (1 dragon/cast) |

**Nota: 6/10.** O plano funciona mas depende de Boros Charm como unico pump.
Surge to Victory compensa como segundo pump/recursion. Insurrection e plano C autonomo.
**GAP: Falta 1 pump adicional** — algo como Akroma's Will, Fury Storm, ou Repeated Reverberation.

---

### B) BOARD WIPES + PROTECTION — Wipes assimetricos?

#### BOARD WIPES (5)

| Carta | CMC | Efeito | Custo Real |
|:------|:---:|:-------|:-----------|
| Blasphemous Act | 9 | Destroi TODAS as criaturas | Tipicamente R (desconto por criatura) |
| Austere Command | 6 | Destroi 2 de: artifacts, enchantments, creatures | Modular — pode pular criaturas |
| Call Forth the Tempest | 8 | Dano = 2X a cada criatura + cascade | Dano massivo + valor |
| Volcanic Vision | 7 | Dano = CMC revelada a cada criatura + retorna spell | Wipe + recursao |
| Fated Clash | 5 | Bounce 1 criatura por oponente + scry | Wipe suave, nao destroi |

#### PROTECAO (6)

| Carta | CMC | Efeito | Contra o que protege |
|:------|:---:|:-------|:---------------------|
| Boros Charm | 2 | Indestrutivel para seus permanentes | Board wipes, remocao em massa |
| Teferi's Protection | 3 | Faseia voce e seus permanentes | TUDO — wipes, combo, ataque |
| Lightning Greaves | 2 | Shroud + haste para criatura equipada | Remocao direcionada, edicts |
| Deflecting Swat | 3 | Redireciona spell/ability alvo unico | Counterspell, remocao direcionada |
| Grand Abolisher | 2 | Oponentes nao conjuram no seu turno | Counterspell, instant-speed interaction |
| Hexing Squelcher | 2 | Oponentes nao ativam habilidades | Activated abilities (combos) |

#### PARES WIPE + PROTECAO

**Austere Command + Teferi's Protection:**
- Teferi's: faseia tudo seu (EOT volta)
- Austere: escolhe "destroy all creatures AND all enchantments"
- Resultado: SUAS criaturas e encantamentos voltam ilesos. Oponentes perdem tudo.
- **Custo: 10 mana total (3 + 7 com desconto do Lorehold). Executavel T5-T6.**

**Blasphemous Act + Boros Charm:**
- Boros Charm: seus permanentes indestrutiveis
- Blasphemous Act: custa R, destroi TODAS as criaturas
- Resultado: Wipe unilateral por 3 mana total (R + RW).
- **Custo: 3 mana. Executavel T3-T4.**

**Volcanic Vision + Teferi's Protection:**
- Teferi's: faseia
- Volcanic Vision: dano = CMC revelada + retorna Mizzix's Mastery a mao
- Resultado: Wipe + recursao da melhor spell. Proximo turno: Mizzix's overload.
- **Sequencia de 2 turnos que fecha jogos.**

**Call Forth the Tempest + Boros Charm:**
- Boros Charm: indestrutivel
- Call Forth: dano massivo (X=5 → 10 dano a cada criatura) + cascade
- Cascade pode revelar Approach, Dance, ou outro wipe.
- **Custo: 10 mana. Alto, mas fecha jogos.**

#### RATIO WIPES / PROTECAO

| Contagem | Valor |
|:---------|:-----:|
| Board Wipes | 5 |
| Protecoes (que funcionam com wipes) | 3 (Boros Charm, Teferi's, Lightning Greaves) |
| Protecoes (anti-target/interaction) | 3 (Deflecting Swat, Grand Abolisher, Hexing Squelcher) |
| **Wipes que sao seguros SEM protecao** | 3 (Austere pode pular criaturas, Call Forth e assimetrico, Volcanic Vision e assimetrico) |
| **Wipes que PRECISAM de protecao** | 2 (Blasphemous Act, Fated Clash) |

**RATIO REAL: 2 wipes perigosos / 3 protecoes que funcionam com wipes = 1.5 protecoes por wipe perigoso.**

**CONCLUSÃO: 8/10. Excelente.** O deck tem protecao suficiente para todos os wipes.
Alem disso, 3 dos 5 wipes sao assimetricos ou modulares (Austere, Call Forth, Volcanic Vision).
**Sem risco de auto-destruicao.**

---

### C) RECURSION CHAINS — Como o deck reusa o cemiterio?

#### PECAS DE RECURSAO

| Carta | CMC | O que faz | Alvos | Copiavel? |
|:------|:---:|:----------|:------|:----------|
| Mizzix's Mastery | 4 (overload 7R) | Exila todos instants/sorceries do grave, conjura gratis | TODOS | SIM — Double Vision + Lorehold |
| Arcane Bombardment | 5 | Exila 1a spell/turno, copia aleatoria a cada spell | 1 por turno | Lento mas continuo |
| Restoration Seminar | 7 | Retorna instant/sorcery do grave + cria token | 1 alvo | SIM |
| Surge to Victory | 6 | Exila spell do grave, criaturas copiam ao causar dano | 1 alvo | Copias via criaturas |
| Faithless Looting | 1 | Flashback 2R — draw 2, discard 2 | Si mesmo | Preenche grave |
| Volcanic Vision | 7 | Retorna instant/sorcery a mao | 1 alvo | Dano + recursao |

#### CADEIAS DE RECURSAO

**Cadeia #1: Faithless Looting -> Mizzix's Mastery Overload (COMBO PRINCIPAL)**
```
T1-T3: Faithless Looting, Thrill of Possibility, Big Score
       Preenchem grave com 5-8 instants/sorceries
T4-T5: Mizzix's Mastery overload (7R)
       Conjura TODAS as spells do grave GRATIS
       Com Double Vision: cada spell e copiada 1x extra
       Com Arcane Bombardment: cada spell e copiada 2x extra
       Com Lorehold: cada spell do grave e copiada 3x extra
Resultado tipico: 5 spells x 3 copias = 15 spells conjuradas
       Storm-Kiln gera 15 treasures (1 por cast/copia)
       Abordagem fecha o jogo
```

**Cadeia #2: Arcane Bombardment + Restoration Seminar (LOOP DE VALOR)**
```
T5: Arcane Bombardment no campo
T6: Conjura Faithless Looting (exilada pelo Bombardment, copiada)
    Bombardment exila Faithless do grave
T7: Restoration Seminar retorna Faithless a mao
    Conjura Faithless de novo -> Bombardment copia de novo
Ciclo: 1 draw + 2 descartes + copia a cada 2 turnos
Com 30+ spells no deck: valor consistente
```

**Cadeia #3: Surge to Victory + Approach of the Second Sun (AUTO-WIN)**
```
Pre-condicao: Approach no cemiterio, 3+ criaturas no campo
T6: Surge to Victory exila Approach
    Criaturas causam dano -> cada uma "conjura" copia de Approach
    Com 3 criaturas = 3 copias de Approach (contam como "conjuradas")
    Proxima conjuracao real de Approach ganha o jogo
    Se 7+ criaturas = 7 copias = ganha na HORA (7a copia auto-win)
```

**Cadeia #4: Volcanic Vision + Mizzix's Mastery (RECURSAO EM 2 TURNOS)**
```
T6: Volcanic Vision — dano em massa + retorna Mizzix's Mastery do grave a mao
T7: Mizzix's Mastery overload — conjura TODAS spells do grave
    Com o grave repopulado apos o wipe: valor maximo
```

#### ANALISE DA RECURSAO

| Forca | Fraqueza |
|:------|:---------|
| 4 camadas de recursao (Mastery, Bombardment, Seminar, Surge) | Nenhuma e instant-speed |
| Mastery overload e game-ender confirmado | Depende de grave populado |
| Bombardment gera valor passivo todo turno | Bombardment e lento (1/turno) |
| Surge+Approach = auto-win deterministico | Surge precisa de criaturas |
| Restoration Seminar fecha loop com Bombardment | Seminar e cara (CMC 7) |

**Nota: 8/10.** Excelente redundancia. O deck tem 4 caminhos de recursao, 2 deles
game-ending (Mastery overload, Surge+Approach). Unico gap: sem recursao instant-speed
(ex: Past in Flames seria redundante mas util).

---

### D) MANA EXPLOSIVA — Como o deck gera mana explosiva?

#### GERADORES DE TESOURO

| Carta | CMC | Quantidade | Tipo | Copiavel? |
|:------|:---:|:----------:|:-----|:----------|
| Smothering Tithe | 4 | 3+/turno | Passivo — cada draw oponente | SIM — copia do Tithe = mais treasures |
| Storm-Kiln Artist | 4 | 1/cast ou copia | Ativo — cada spell | SIM — cada copia gera treasure |
| Big Score | 4 | 2 | Instant — one-shot | SIM — 4 treasures quando copiado |
| Unexpected Windfall | 4 | 2 | Instant — one-shot | SIM — 4 treasures copiado |
| Brass's Bounty | 7 | X = lands (~7-10) | Sorcery — one-shot | SIM — 14-20 treasures copiado! |
| Hit the Mother Lode | 7 | 7 | Sorcery — one-shot | SIM — 14 treasures copiado! |

#### RITUAL

| Carta | CMC | Mana Gerada | Condicao |
|:------|:---:|:------------|:---------|
| Jeska's Will | 3 | RRR + exile 3 top | Em 4-player: ~5R + 3 cartas |

#### RAMP ESTATICO

| Carta | CMC | Tipo |
|:------|:---:|:-----|
| Sol Ring | 1 | Rock (+2) |
| Arcane Signet, Boros Signet, Talisman of Conviction | 2 | Rock (+1) |
| Ruby Medallion, Pearl Medallion | 2 | Cost reduction (-1) |
| Land Tax | 1 | 3 lands/mao |
| Weathered Wayfarer | 1 | Busca ANY land |
| Archaeomancer's Map | 3 | Conditional land ramp |
| Bender's Waterskin | 3 | Rock flexivel |
| Ancient Tomb | 0 | Sol land (+2) |
| Dormant Volcano | 0 | Sol land (entra tapped) |

#### O DESTINO DA MANA — Para que serve tanta mana?

| Destino | CMC | O que faz com mana abundante |
|:--------|:---:|:----------------------------|
| Mizzix's Mastery overload | 7R | Game-ender |
| Storm Herd | 10 | 40+ tokens |
| Brass's Bounty + Capstone | 7 + 3 (activate) | 10+ treasures → Capstone exila top 7 → conjura spells gratis → gera MAIS treasures (motor) |
| Approach of the Second Sun + topdeck | 7 + 1 (Top) | Conjura Approach, topdeck pro topo, draw imediato |
| Dance with Calamity | 8 | Exila top 8, conjura gratis = mana "virtual" ilimitada |
| Call Forth the Tempest | 8 | Dano massivo + cascade em Approach |

#### SEQUENCIA DE MANA EXPLOSIVA

**Sequencia Ideal (T4-T5):**
```
T1: Sol Ring -> Arcane Signet
T2: Land Tax + Weathered Wayfarer -> busca Ancient Tomb
T3: Smothering Tithe (4 mana de 2 lands + Sol Ring + Signet)
T4: Tith gera 3+ treasures + Lorehold cast (5 mana)
T5: Brass's Bounty copiado = 14-20 treasures (28-35 mana total disponivel)
    -> Storm Herd X=40 (10 mana dos treasures)
    -> Boros Charm double strike (2 mana)
    -> 80 flying damage. GAME.
```

**Sequencia Media (T6-T7):**
```
T1-T3: Land drops, Signet/Talisman, Scroll Rack
T4: Big Score gera 2 treasures
T5: Arcane Bombardment + Storm-Kiln
T6: Hit the Mother Lode copiado = 14 treasures + discover 10
    -> Mizzix's Mastery overload (7R, pago com treasures)
    -> TODAS spells do grave conjuradas gratis
```

#### ANALISE DA MANA

| Forca | Fraqueza |
|:------|:---------|
| 6 geradores de tesouro (redundancia) | Depende de Smothering Tithe/Storm-Kiln sobreviverem |
| Cost reduction stack: Lorehold (-1) + Medallions (-1) | Medallions sao double-null, trend negativo |
| Brass's Bounty copiado = 20 treasures | Precisa de setup (Bounty + copy engine) |
| 5 fetches + Scroll Rack + Sensei's Top = mana efficiency | Sem fast mana alem de Sol Ring e Ancient Tomb |
| Jeska's Will = ritual explosivo em 4-player | Sem Crypt, Vault, ou Mox |

**Nota: 7/10.** O deck gera mana explosiva mas precisa de 1-2 turnos de setup.
O motor Treasure -> Big Spell -> Copy -> Payoff e consistente a partir do T4-T5.
**GAP: Sem fast mana (Mana Crypt, Mana Vault, Chrome Mox).** Depende de tutores
para achar Sol Ring/Ancient Tomb. Sem aceleracao T0-T1 alem do Sol Ring.

---

### E) COMBO PIECES — Existe combo deterministico?

#### COMBO #1: Approach + Topdeck Manipulation (DETERMINISTICO)

**Pecas necessarias:**
- Approach of the Second Sun (no deck)
- Scroll Rack OU Sensei's Divining Top OU Valakut Awakening OU Penance (todos no deck)
- 14 mana total (7 + 7 para segunda conjuracao, mas topdeck reduz para 8-9)

**Sequencia:**
```
1. Conjura Approach (7 mana). Vai 7o do topo.
2. Ativa Scroll Rack (1 mana): reordena topo, poe Approach 2o.
3. Draw phase: compra Approach.
4. Mesmo turno ou proximo: conjura Approach de novo (7 mana).
   Game win.
```

**Aceleracao com Lorehold:**
```
1. Lorehold copia Approach (5 mana). Copia conta como "conjurada".
2. Conjura Approach real (7 mana). Como a copia ja foi "conjurada",
   o Approach real ve o clock em 1. Proxima copia ganha.
3. Com Double Vision: 3 copias de Approach no mesmo turno.
```

**Confiabilidade: 9/10.** Com Scroll Rack + Sensei's Top + Penance + Valakut Awakening,
o deck tem 4 pecas de topdeck manipulation. So falta mana.

#### COMBO #2: Surge to Victory + Approach (AUTO-WIN DETERMINISTICO)

**Pecas necessarias:**
- Approach no cemiterio
- Surge to Victory na mao
- 3+ criaturas no campo (qualquer criatura)

**Sequencia:**
```
1. Surge to Victory (6 mana): exila Approach.
2. Ataque com 3+ criaturas. Cada uma que causa dano = conjura copia de Approach.
3. 3 copias = 3 "conjuracoes" de Approach. Clock em 3.
4. Proximo turno: conjura Approach real (clock 4). Nao ganha ainda.
   OU: com 7+ criaturas = 7 copias = GANHA NA HORA.
```

**Confiabilidade: 7/10.** Precisa de Approach no grave + Surge na mao + criaturas.
Mas com Rite of the Dragoncaller e Storm Herd, ter criaturas e provavel.

#### COMBO #3: Storm-Kiln Artist + Copy Engine (MANA INFINITA VIRTUAL)

**Pecas necessarias:**
- Storm-Kiln Artist no campo
- Lorehold no campo (commander)
- Double Vision OU Arcane Bombardment no campo
- Qualquer instant/sorcery de CMC baixo (Faithless, Thrill, Abrade)

**Sequencia:**
```
1. Conjura Faithless Looting (1 mana): Storm-Kiln gera Treasure #1.
2. Lorehold copia Faithless (gratis): Storm-Kiln gera Treasure #2.
3. Double Vision copia Faithless (gratis): Storm-Kiln gera Treasure #3.
4. Arcane Bombardment copia Faithless (gratis): Storm-Kiln gera Treasure #4.
Resultado: 1 mana investido, 4 treasures gerados, +8 cartas vistas (4x draw 2).
Lucro liquido: +3 mana por ciclo.
```

**Confiabilidade: 8/10.** Nao e infinito deterministico, mas gera mana suficiente
para conjurar qualquer spell do deck. Com 3 copias + Storm-Kiln, cada spell de
CMC 1-2 gera lucro de mana.

#### COMBO #4: Galvanoth + Scroll Rack + Top (SPELL GRATIS TODO TURNO)

**Pecas necessarias:**
- Galvanoth no campo
- Scroll Rack OU Sensei's Top

**Sequencia:**
```
1. Upkeep: Galvanoth revela topo.
2. Resposta: ativa Scroll Rack, poe Approach/Dance/Capstone no topo.
3. Galvanoth conjura a spell revelada GRATIS.
4. Todo turno: big spell gratis.
```

**Confiabilidade: 5/10.** Galvanoth e criatura 5/5 sem protecao. Dificil sobreviver
em mesa com 3 oponentes. Mas quando funciona, e devastador.

#### COMBO #5: Brass's Bounty + Improvisation Capstone (MOTOR AUTO-SUSTENTAVEL)

**Pecas necessarias:**
- Brass's Bounty na mao
- Improvisation Capstone no campo
- Lorehold no campo

**Sequencia:**
```
1. Conjura Brass's Bounty (7 mana): gera ~10 treasures.
2. Lorehold copia Bounty: gera +10 treasures. Total: 20 treasures.
3. Ativa Improvisation Capstone (3 mana, sacrifica 3 treasures):
   Exila top 7, conjura spas gratis.
4. Com 17 treasures restantes: repete 5x.
5. Exila 35 cartas do topo, conjura ~10-15 spells gratis.
6. Entre elas: Approach, Insurrection, Storm Herd.
```

**Confiabilidade: 8/10.** Motor auto-sustentavel. Nao e infinito deterministico,
mas gera valor suficiente para fechar qualquer jogo.

#### GAPS DE COMBO

| Gap | Peca Faltante | Impacto |
|:----|:--------------|:--------|
| Underworld Breach | Nao pode (identidade Boros) | Breach + LED = combo deterministico. Fora de cor. |
| Past in Flames | Vermelho, CMC 4 | Recursao redundante. Nao essencial. |
| Lion's Eye Diamond | Incolor, cara ($) | Fast mana + grave. Fora de cor (discard hand). |
| Defesa de combo | Sem counterspell | Boros nao tem counters. Depende de remocao. |

**Conclusao combo: 8/10.** O deck tem 5 combos/semi-combos, 2 deterministicos
(Approach+Topdeck, Surge+Approach). O motor Treasure->Copy e virtualmente infinito.
Nao ha combo que ganhe T2-T3 (Boros nao tem fast mana suficiente), mas ha multiplos
caminhos para fechar jogos T5-T7 consistentemente.

---

## Secao 4: DOUBLE-NULL — Cartas Invisiveis ao Classificador

6 cartas permanecem double-null (pos-Ciclo #8):

| Carta | CMC | EDHREC | Trend | Risco de Corte | Funcao Real | Verdict |
|:------|:---:|:------:|:-----:|:---------------|:------------|:--------|
| **Scroll Rack** | 2 | 59.7% | +0.48 | CRITICO | topdeck, engine | **NUNCA CORTAR** — Core da estrategia |
| **Penance** | 3 | 41.8% | +1.15 | CRITICO | topdeck, protection | **NUNCA CORTAR** — Miracle enabler |
| **Grand Abolisher** | 2 | 11.7% | -0.27 | Alto | protection | **MANTER** — Unica protecao anti-counterspell em Boros |
| **Ruby Medallion** | 2 | 42.3% | -0.37 | Medio | ramp, cost_reduction | **MONITORAR** — 42% EDHREC mas trend negativo |
| **Pearl Medallion** | 2 | 25.2% | -0.46 | Medio-Alto | ramp, cost_reduction | **CANDIDATO A CORTE** — 25% e caindo ha 5 ciclos |
| **Taunt from the Rampart** | 5 | 35.2% | +0.18 | Baixo | goad, control | **MANTER** — 35% EDHREC, funcao unica de goad em massa |

---

## Secao 5: DECLINIOS E RISING STARS

### Declinios Persistentes (monitorar)

| Carta | EDHREC | Trend | Ciclos em Declinio | Acao |
|:------|:------:|:-----:|:------------------:|:-----|
| Esper Sentinel | 32.5% | -0.54 | 6 | Monitorar — draw condicional em declinio |
| Pearl Medallion | 25.2% | -0.46 | 5+ | Cortar quando houver substituto |
| Ruby Medallion | 42.3% | -0.37 | 3 | Monitorar — cost reduction vs treasure |
| The One Ring | 8.5% | -0.32 | 4 | Manter — Game Changer, draw + protecao |
| Call Forth the Tempest | 65.5% | -0.30 | 2 | Manter — alta EDHREC apesar do trend |

### Rising Stars (ja incluidas)

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
| Control | 56.0% | -- (Boros > Control com protecao anti-counter) |
| Midrange | 53.2% | -- (valor supera) |
| Aggro | 51.8% | -- (wipes + lifegain do One Ring) |
| **Combo** | **46.5%** | **Sem counterspell. Depende de remocao instantanea.** |

**Contra combo:** A unica defesa e remocao (Path, Swords, Abrade, Chaos Warp, Generous Gift)
+ Deflecting Swat. Nao ha counterspell em Boros. Grand Abolisher + Hexing Squelcher ajudam
contra combo que depende de ativar habilidades ou conjurar no seu turno, mas combo
deterministico T2-T3 e imbatível para este deck.

---

## Secao 7: O PLANO DE JOGO — Turn by Turn

### T1 (Setup Inicial)
**Objetivo:** Ramp + topdeck setup
**Cartas ideais:** Sol Ring, Land Tax, Weathered Wayfarer, Sensei's Top, Library of Leng, Gamble, Enlightened Tutor
**Sequencia ideal:** T1 Land Tax OU Wayfarer OU Sol Ring → Signet → acelera 2 turnos

### T2 (Ramp Secundario)
**Objetivo:** Fixing + draw/loot
**Cartas ideais:** Arcane Signet, Boros Signet, Talisman, Thrill of Possibility, Faithless Looting, Scroll Rack
**Sequencia ideal:** Signet/Talisman + Faithless/Thrill → preenche grave

### T3 (Protecao + Engine Setup)
**Objetivo:** Estabelecer protecao + preparar Lorehold
**Cartas ideais:** Lightning Greaves, Grand Abolisher, Hexing Squelcher, Teferi's Protection, Smothering Tithe, Archaeomancer's Map, Jeska's Will
**Sequencia ideal:** Greaves OU Abolisher OU Tithe → T4 Lorehold seguro

### T4 (Lorehold + Valor)
**Objetivo:** Conjurar Lorehold + gerar valor imediato
**Cartas ideais:** Lorehold (commander), Big Score, Unexpected Windfall, The One Ring, Monument to Endurance, Storm-Kiln Artist
**Sequencia ideal:** Lorehold + Big Score (instant no oponente) → 2 treasures + draw + copy = 4 treasures + 2 draws

### T5 (Motor Arrancado)
**Objetivo:** Copy engines + free spells
**Cartas ideais:** Double Vision, Arcane Bombardment, Dance with Calamity, Improvisation Capstone
**Sequencia ideal:** Double Vision → Dance with Calamity copiada → 16 cartas exiladas, conjura gratis

### T6+ (Fechar o Jogo)
**Objetivo:** Wincon
**Cartas ideais:** Approach, Insurrection, Mizzix's Mastery overload, Storm Herd + Boros Charm, Surge to Victory + Approach
**7+ paths de vitoria.**

---

## Secao 8: RESUMO EXECUTIVO

### Estado do Deck: SAUDAVEL (Pos-Ciclo #8, 22 swaps)

| Indicador | Status |
|:----------|:------:|
| Motor | 4/4 COMPLETO |
| Copy Engines | 3/3 COMPLETO |
| Sem Play T3 | 3.7% EXCELENTE |
| Draw Real | 7 (+2 desde v3.7!) |
| Wipes/Protecao | 5/6 BALANCEADO |
| Recursao | 4 camadas |
| Combos deterministicos | 2 (Approach+Topdeck, Surge+Approach) |
| Double-nulls preocupantes | 1 (Pearl Medallion) |
| Declinios monitorados | 5 (Esper Sentinel pior) |

### Top 3 GAPS

1. **Pearl Medallion (Nivel 1, double-null, trend -0.46):** Candidato natural a corte.
   Mas colecao esgotada de CMC 1-2 com EDHREC >20% que nao estejam no deck.
   Substituto ideal: Skullclamp (CMC 1, draw), Mana Vault (CMC 1, ramp), ou Chrome Mox (CMC 0, ramp).
   **Recomendacao: adquirir antes de cortar.**

2. **Falta 1 pump adicional:** So Boros Charm + Surge to Victory como pump/amplificador de dano.
   Akroma's Will (CMC 4, EDHREC 15-25%) seria excelente. Fury Storm (CMC 4) tambem.
   Ambos requerem aquisicao.

3. **Fast mana insuficiente:** So Sol Ring + Ancient Tomb como aceleração T0-T1.
   Sem Mana Crypt, Mana Vault, Chrome Mox, ou Mox Diamond.
   **Isso e esperado para bracket 3 (Game Changer limitado).**

### Recomendacoes para Ciclo #9

Com T3 = 3.7% (<< 8%), estrategia **AGGRESSIVE** liberada.
Net ΔCMC pode ser +1 a +2.

| Prioridade | Sai | Entra | EDHREC | ΔCMC | Justificativa |
|:-----------|:----|:------|:------:|:----:|:--------------|
| 1 | Pearl Medallion (CMC 2) | Skullclamp (CMC 1) | 35%+ | -1 | Draw engine → preenche gap de draw |
| 2 | Ruby Medallion (CMC 2) | Mana Vault (CMC 1) | staple | -1 | Fast mana → acelera T2 Lorehold |

**Se aquisicoes nao disponiveis: 0 swaps. Deck ja esta saudavel.**
Nao forcar swaps com cartas que nao melhoram o deck.

---

## Secao 9: NOVIDADES v3.8

### O que mudou desde v3.7:

1. **SYNERGY_MAP completo (5 eixos):** Primeira analise que mapeia TODAS as sinergias
   do deck em 5 eixos (Tokens+Pump, Wipes+Protection, Recursion, Mana Explosiva, Combo Pieces).

2. **Classificacao Estrategica (1-5):** Toda carta classificada por importancia real,
   corrigindo functional_tags incorretas. Total: 86 cartas classificadas (incluindo lands).

3. **Draw real = 7 (confirmado):** Subiu de 5 (v3.7) para 7 apos Ciclos #6/#7/#8
   (Wedding Ring + Victory Chimes adicionados). A 1 fonte do minimo do perfil.

4. **Calculo de dano token+pump:** Primeira analise numerica de quantos tokens,
   quanto dano, e se e letal. Storm Herd + Boros Charm = 80 flying damage (mata a mesa).

5. **Cadeias de recursao documentadas:** 4 cadeias distintas, da mais simples
   (Faithless → Mastery) ate a mais complexa (Bombardment + Seminar loop).

6. **5 combos mapeados:** 2 deterministicos (Approach+Topdeck, Surge+Approach),
   2 semi-deterministicos (Storm-Kiln+Copy, Brass+Capstone), 1 fragil (Galvanoth+Top).

7. **Pearl Medallion confirmado como corte prioritario:** Unico double-null com
   EDHREC < 30% E trend < -0.4 persistente. Mas colecao esgotada — requer aquisicao.

8. **Estado do deck: SAUDAVEL.** Apos 22 swaps em 8 ciclos, o deck atingiu maturidade.
   Todos os sistemas completos. Proximos upgrades requerem aquisicao de cartas.

---

*Relatorio gerado por Purpose Analyzer v3.8 em 2026-05-31T13:00:00Z*
*Analista: Hermes Agent — Agente 2 (Lorehold Purpose Analyzer)*
