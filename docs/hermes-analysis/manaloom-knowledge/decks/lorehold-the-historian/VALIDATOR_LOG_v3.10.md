# Purpose Analyzer v3.10 — Lorehold Spellslinger: SYNERGY_MAP + Stack & Resilience

> **Data:** 2026-05-31T18:55:38+00:00
> **Fonte:** knowledge.db deck_id=6 (pos-Ciclo #10, 25 swaps aplicados)
> **Deck:** Lorehold Spellslinger — 100 cards, 86 rows, 35 lands, CMC medio 3.71
> **Analista:** Hermes Agent — Purpose Analyzer v3.10
> **Foco:** Pos-Ciclo #10 — Flare de Duplication + Twinflame adicionados. Copy layers 6. Novo combo Approach+Flare.

---

## Secao 0: O QUE MUDOU DO v3.9 PARA v3.10

### Ciclo #10 aplicado (2026-05-31T17:51Z) — 2 SWAPS DEFENSIVOS

| Saiu | Entrou | DCMC | EDHREC | Funcao |
|:-----|:-------|:----:|:------:|:-------|
| Ruby Medallion (CMC 2) | **Twinflame** (CMC 2) | 0 | 42.3% → nova | Cost reduction → creature copy |
| Galvanoth (CMC 5) | **Flare of Duplication** (CMC 3) | -2 | 26.5% → nova | Free spell frágil → instant copy |

**Net DCMC = -2 (DEFENSIVO light). T3 estimado: 16.9% → ~15%.**
**Swaps totais desde baseline: 25** (C#1:3, C#2:3, C#3:5, C#4:3, C#5:3, C#6:2, C#7:1, C#8:0, C#9:1, C#10:2)

### Mudancas Chave

1. **Copy layers: 4 → 6** (+Flare of Duplication como copy instant, +Twinflame como creature copy)
2. **Novo combo deterministico: Approach + Flare = vitoria no MESMO turno.** Com 7 mana: cast Approach → sacrifique criatura vermelha → Flare gratis → copia Approach. Dois casts = win imediato, sem esperar 1 turno.
3. **Twinflame + Surge to Victory + Akroma's Will = chain de dano exponencial.** Twinflame cria copia de criatura com haste → Surge copia spell com TODAS as criaturas (incluindo a copia) → Akroma's Will buffa todas.
4. **Ruby Medallion removido** — ultimo double-null com trend negativo. Double-nulls: 5 → 4.
5. **Nivel 1 vazio** — Ruby era o unico Nivel 1. Agora nao ha cartas claramente cortaveis.
6. **CMC medio: 3.86 → 3.71** (-0.15). Galvanoth CMC 5 removido, cartas CMC 2-3 adicionadas.
7. **Mulligan pendente** (Execucao #11 nao executada). T3 projetado ~15%.

---

## Secao 1: Visao Geral do Deck

### Metricas Recalculadas (pos-Ciclo #10)

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
| CMC medio | 3.71 | ~4.1 | OK (-0.15 vs pos-C#9) |

### Deck Health (pos-Ciclo #10)

| Indicador | Valor | Interpretacao |
|:----------|:-----:|:--------------|
| Motor | 4/4 COMPLETO | Treasure → Free Big Spell → Copy → Payoff |
| Copy Engines | 6 ativas | Lorehold + Double Vision + Bombardment + Dawning Archaic + Flare + Twinflame |
| **Sem Play T3** | **~15% (est.)** | **🟡 DEFENSIVE (>12%). Pendente mulligan Execucao #11.** |
| Mulligan Rate | ~48% (est.) | Estrutural (35 lands, 3 T1 ramp estrito) |
| Ramp T1 (estrito) | ~20% | Sol Ring + Land Tax + Wayfarer |
| Draw Real | 7 fontes | A 1 fonte do minimo do perfil |
| Protection (total) | 6 fontes | 3 DB-tagged + 3 stack (Swat, Squelcher, Abolisher) |
| Double-null | 4 | 2 core (Scroll Rack, Penance), 2 situational (Taunt, Grand Abolisher) |

---

## Secao 2: CLASSIFICACAO ESTRATEGICA — TODAS as Cartas

Cada carta classificada por **Importancia Estrategica (1-5)** e **Funcao Real**
(corrigindo functional_tags incorretas do banco).

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
| **Flare of Duplication** 🆕 | 3 | -- | copy, combo | Copia instant/sorcery. FREE sacrificando criatura vermelha. Com Approach = vitoria no mesmo turno. Com qualquer big spell = valor explosivo. |

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
| **Chaos Warp** | 3 | 38.8% | removal | Remocao universal — shuffle. Unica que lida com indestrutivel. |
| **Swords to Plowshares** | 1 | 56.1% | removal | Premium removal. |
| **Path to Exile** | 1 | 51.6% | removal | Premium removal. |
| **Generous Gift** | 3 | 44.9% | removal | Destroi qualquer permanente. |
| **Abrade** | 2 | 47.5% | removal | Remocao versatil — criatura ou artefato. |
| **Enlightened Tutor** | 1 | 49.4% | tutor | Busca artefato ou encantamento. |
| **Gamble** | 1 | 44.3% | tutor | Tutor universal com risco de descarte. |
| **Esper Sentinel** | 1 | 32.5% | draw | Draw condicional. 6o ciclo em declinio (-0.54). Monitorar. |
| **Thrill of Possibility** | 2 | 13.9% | draw, loot | Draw 2 discard 1, instant. Preenche grave. |
| **Dragon's Rage Channeler** | 1 | 41.7% | graveyard, selection | Surveil + selection. Preenche grave. |
| **Big Score** | 4 | 55.8% | ramp, treasure, loot | 2 treasures + draw 2 + discard 1. Instant. Motor componente #1. |
| **Unexpected Windfall** | 4 | 18.6% | ramp, treasure, loot | Versao menor de Big Score. |
| **Reforge the Soul** | 5 | 44.0% | draw, wheel | Wheel — draw 7. Reset de mao. |
| **Rite of the Dragoncaller** | 6 | 40.4% | token, payoff | 5/5 Dragon a cada spell. |
| **Storm Herd** | 10 | 75.1% | token, wincon | X Pegasus = PVs. Game-ender. |
| **Archaeomancer's Map** | 3 | 29.3% | ramp | Land ramp condicional. |
| **Land Tax** | 1 | 55.7% | ramp | 3 lands/turno. Ramp consistente. |
| **Weathered Wayfarer** | 1 | 39.3% | ramp, tutor | Busca ANY land. |
| **Sol Ring** | 1 | 84.3% | ramp | Staple. |
| **Boros Signet** | 2 | 50.4% | ramp | Signet estavel. |
| **Arcane Signet** | 2 | 80.2% | ramp | Staple. |
| **Talisman of Conviction** | 2 | 62.1% | ramp | Ramp com dano opcional. |
| **Monument to Endurance** | 3 | 41.3% | engine, draw | Draw + loot + drain. Tag do DB "ramp" esta ERRADO — e engine. |
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
| **Twinflame** 🆕 | 2 | -- | copy, creature | Cria copia de criatura com haste. Com Surge+Akroma: dano exponencial. |

### Nivel 2: UTILIDADE SITUACIONAL

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 2 |
|:------|:---:|:------:|:------------|:------------------|
| **Deflecting Swat** | 3 | 42.0% | protection, stack | Redireciona spell/ability. Stack interaction crucial. Tag "big_spell" do DB ERRADO. |
| **Lightning Greaves** | 2 | 73.3% | protection | Shroud + haste. Protege Lorehold. |
| **Grand Abolisher** | 2 | 11.7% | protection, stack | Oponentes nao conjuram no seu turno. Double-null. Trend -0.27 (declinio). UNICA protecao proativa anti-counterspell. |
| **Hexing Squelcher** | 2 | ~10% | protection, stack | Oponentes nao ativam habilidades. Anti-combo. |
| **Taunt from the Rampart** | 5 | 35.2% | goad, control | Goad em todas as criaturas. Double-null. Util em multiplayer. |

### Nivel 1: SUBSTITUIVEL (Candidato a corte)

**🔴 NENHUMA CARTA no Nivel 1.** Ruby Medallion (unico Nivel 1 do v3.9) foi removido no Ciclo #10.
O deck atingiu um estado onde TODAS as cartas tem funcao justificavel. Nao ha filler claro.

A carta mais proxima de Nivel 1 seria Fated Clash (15.6% EDHREC, bounce-only), mas ainda cumpre
funcao de board wipe e nao ha substituto viavel na colecao.

### Lands — Classificacao

| Carta | Funcao Real | Nota |
|:------|:------------|:-----|
| Ancient Tomb | ramp | Sol land. |
| Arid Mesa, Bloodstained Mire, Flooded Strand, Scalding Tarn, Windswept Heath | fetch, topdeck | 5 fetches. Alimentam Scroll Rack + Top + Land Tax. |
| Boseiju, Who Shelters All | protection, removal | Channel — destroi artefato/encantamento nao-counteravel. |
| Cavern of Souls | protection | Lorehold nao-counteravel. |
| Clifftop Retreat, Inspiring Vantage, Sundown Pass | fixing | Boros fixing. |
| Command Tower, Exotic Orchard, Sacred Foundry, Dormant Volcano | fixing, ramp | Color fixing. |
| Kor Haven | protection | Fog por criatura atacante. |
| Urza's Saga | tutor, token, ramp | Busca Sol Ring, Top, Library. Constructs. |
| 8x Mountain, 8x Plains | basic | Land Tax + Wayfarer targets. |

---

## Secao 3: SYNERGY_MAP — 7 Eixos (A-G)

### A) TOKEN MAKERS + PUMP — Como o deck transforma tokens em vitoria?

#### TOKEN MAKERS (criaturas para combate)

| Carta | CMC | O que cria | Quantidade | Condicao |
|:------|:---:|:-----------|:----------:|:---------|
| Rite of the Dragoncaller | 6 | Dragon 5/5 flying | 1/cast | Cada instant/sorcery = 1 dragon |
| Storm Herd | 10 | Pegasus 1/1 flying | X = PVs | Com 40 PVs = 40 tokens |
| Emeria's Call (MDFC) | 7 | Angel 4/4 flying | 2 | Cria 2 angels |
| Restoration Seminar | 7 | Lesson token | 1 | Recursao + token |
| Urza's Saga | 0 | Construct | 1-2 | Chapter III |

#### TOKEN MAKERS (tesouros — usados como mana)

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
| **Twinflame** 🆕 | 2 | Copia criatura com haste | Dobra criaturas para Surge |

#### PARES TOKEN + PUMP — Calculo de Dano (ATUALIZADO com Twinflame)

**Rite of the Dragoncaller + Boros Charm:**
- Estado tipico (T6+): 3 dragons 5/5 no campo
- Boros Charm double strike: 3 x (5 x 2) = 30 flying damage
- **Conclusao: Mata 1-2 jogadores.**

**Rite + Akroma's Will:**
- 3 dragons 5/5 → Akroma's Will: flying, double strike, vigilance, lifelink, prot all colors, INDESTRUCTIBLE
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

**Twinflame + Surge to Victory + Akroma's Will 🆕 (CHAIN EXPONENCIAL):**
- T1: Twinflame copia Lorehold (ou Dragon do Rite) → 2 criaturas com haste
- T2: Surge to Victory exila Approach do grave → 2+ criaturas atacam → 2+ copias de Approach
- T3: Akroma's Will buffa TODAS → flying + double strike + lifelink + indestructible
- **Conclusao: Ganha na HORA com 2+ copias de Approach, tudo indestrutivel.**

**Rite + Twinflame + Surge:**
- 3 dragons + Twinflame → 4 criaturas atacando
- Surge copia Approach → 4 copias + 1 Approach original → 5 casts
- **Conclusao: OVERKILL. Vitoria garantida mesmo com counterspell (so precisa 2 resolverem).**

**Flare of Duplication + Approach 🆕 (VITORIA NO MESMO TURNO):**
- T1: Cast Approach of the Second Sun (7 mana)
- T2: Sacrifice criatura vermelha (Dragon's Rage Channeler, Storm-Kiln token, etc.)
- T3: Flare of Duplication FREE → copia Approach → 2o cast na stack
- **Conclusao: VITORIA IMEDIATA. Sem esperar 1 turno. Total: 7 mana + qualquer criatura vermelha.**

#### ANALISE DO PLANO TOKEN+PUMP (atualizado pos-C#10)

| Forca | Fraqueza |
|:------|:---------|
| 2 pumps reais: Boros Charm + Akroma's Will ✅ | Akroma's Will CMC 4 |
| Twinflame dobra criaturas para Surge chain ✅ | Rite lento (1 dragon/cast) |
| Flare + Approach = vitoria sem combate ✅ | Storm Herd CMC 10 |
| Insurrection game-ender autonomo | Surge depende de Approach no grave |
| 3+ paths de vitoria sem combate (Approach, Flare+Approach, Surge+Approach) | |

**Nota: 8/10 (mesmo do v3.9).** Nao mudou porque os pumps sao os mesmos,
mas os PATHS de vitoria se expandiram: Flare+Approach dispensa combate,
Twinflame+Surge dobra o numero de copias de Approach.

---

### B) BOARD WIPES + PROTECTION — Wipes assimetricos?

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
- Teferi's → faseia tudo. Na volta, Austere → so oponentes tem criaturas.
- **Protecao: Faseia (Teferi's). Austere e MODULAR — pode escolher nao destruir artefatos/enchantments.**

**Blasphemous Act + Boros Charm (indestrutivel):**
- Blasphemous Act → Boros Charm indestrutivel → suas criaturas sobrevivem, oponentes nao.
- **Protecao: Boros Charm. Custo total: R + RW = 3 mana!**

**Call Forth the Tempest + Akroma's Will:**
- Call Forth → dano massivo + cascade. Akroma's Will → indestrutivel + prot all colors.
- Suas criaturas sobrevivem ao dano e ficam buffadas para o contra-ataque.

#### RATIO WIPES / PROTECAO
- **5 wipes / 4 protecoes contra wipes = 1.25:1**
- Wipes assimetricos/mitigaveis: Austere (modular), Call Forth (dano, Akroma+bombas sobrevivem)
- Wipes perigosos sem protecao: Blasphemous Act (se sem Boros Charm/Akroma)
- **Balanco adequado.** Sem risco de auto-destruicao.

**Nota: 8/10 (inalterado desde v3.9).**

---

### C) RECURSION CHAINS — Como o deck reusa o cemiterio?

#### RECURSION PIECES

| Carta | CMC | Tipo | O que faz |
|:------|:---:|:-----|:----------|
| Mizzix's Mastery | 4 | Overload | Conjura TODOS instants/sorceries do grave gratis |
| Arcane Bombardment | 5 | Passiva | A cada turno, exile 1 instant/sorcery do grave → copia gratis |
| Faithless Looting | 1 | Flashback | Flashback por 2R → +1 loot |
| Surge to Victory | 6 | Ativa | Exile sorcery do grave, copia com criaturas atacando |
| Restoration Seminar | 7 | Ativa | Retorna instant/sorcery do grave + cria Lesson token |
| Volcanic Vision | 7 | Wipe+Recursao | Dano = CMC a todas as criaturas + retorna instant/sorcery |

#### CHAINS DOCUMENTADAS

**Chain 1: Faithless → Grave Setup → Mizzix's Overload (T4-T6)**
1. T1-T3: Faithless Looting, Thrill of Possibility, Dragon's Rage Channeler enchem o grave
2. T4-T6: Mizzix's Mastery overload → 5-10+ spells gratis em um turno
3. Com Double Vision: primeira spell copiada → 2x valor
4. Com Arcane Bombardment: cartas ja exiladas por Bombardment + cartas novas do grave
5. **Resultado: Turno explosivo que geralmente fecha o jogo.**

**Chain 2: Bombardment → Acumulo Passivo → Copy em Cadeia (T5+)**
1. T5+: Arcane Bombardment entra
2. Cada turno: exile 1 spell do grave, copia gratis
3. Se tiver Double Vision + Dawning Archaic: 3 copias da mesma spell
4. Cada copia ativa Storm-Kiln Artist = 3 treasures
5. **Resultado: Valor exponencial turno a turno.**

**Chain 3: Surge + Approach = Vitoria Garantida (T6+)**
1. Approach no cemiterio (cast anterior ou Faithless discard)
2. Surge to Victory: exile Approach, TODAS as criaturas atacantes dao copia
3. Com 3+ criaturas atacando: 3 copias de Approach → vitoria garantida
4. **Com Twinflame 🆕:** +1 criatura = +1 copia. Com Rite (3 dragons) + Twinflame = 4 copias.
5. **Resultado: Vitoria deterministica com 3+ criaturas e Approach no grave.**

**Chain 4: Restoration Seminar → Spell de Volta → Token (T7+)**
1. T7+: Restoration Seminar → retorna instant/sorcery do grave
2. Cria token 3/2 Lesson. Esse token pode ser sacrificado para Flare of Duplication.
3. **Resultado: Recursao + token que alimenta Flare.**

**Nota: 8/10 (inalterado).** As chains sao diversas e redundantes.
Mizzix's + Bombardment + Surge sao 3 paths independentes de recursao.
Restoration Seminar e backup. Faithless Looting e enabler early.

---

### D) MANA EXPLOSIVA — Como o deck gera mana explosiva?

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

#### MANA SINKS — Para que serve tanta mana?

| Alvo | Custo | O que faz |
|:-----|:-----:|:----------|
| Storm Herd | 10 | X = PVs → 20-40 Pegasus |
| Approach + Flare | 7 | Vitoria no mesmo turno |
| Insurrection | 8 | Rouba board |
| Mizzix's Mastery overload | 4 | Todos spells do grave gratis |
| Dance with Calamity | 8 | Exila 8, conjura gratis |
| Call Forth the Tempest | 8+X | Dano + dragoes + cascade |
| Improvisation Capstone | 7 | Exila 7, conjura gratis |
| Brass's Bounty | 7 | Converte lands em tesouros → mais mana |

#### SEQUENCIA IDEAL DE MANA (T1-T6)

| Turno | Mana | Play |
|:-----:|:----:|:-----|
| T1 | 1-3 | Land Tax / Sol Ring / Top |
| T2 | 2-5 | Signet + Faithless / Scroll Rack |
| T3 | 3-7 | Tithe / Jeska's Will / Monument / Greaves |
| T4 | 4-10 | Lorehold + Big Score / Windfall / One Ring |
| T5 | 5-15 | Double Vision + Dance / Bombardment |
| T6+ | 8-20+ | Storm Herd, Approach+Flare, Insurrection, Mizzix |

**Nota: 7/10 (inalterado).** O deck gera mana explosiva mas depende de Tithe/Storm-Kiln
para escalar. Sem fast mana (Mana Vault, Chrome Mox), o early game e a fraqueza.
Tesouros sobrevivem a wipes — vantagem estrutural.

---

### E) COMBO PIECES — Existe combo deterministico?

#### COMBOS DETERMINISTICOS

**Combo 1: Approach + Topdeck Manipulation (2 cartas, deterministico)**
- Pecas: Approach + Sensei's Top OU Scroll Rack OU Penance
- Setup: Cast Approach → com trigger na stack, ativar Top (draw Approach) ou Scroll Rack (colocar Approach no topo)
- Resultado: Proximo turno, cast Approach de novo = vitoria.
- Confiabilidade: 10/10. Com Enlightened Tutor e Gamble, altamente tutoravel.

**Combo 2: Approach + Flare of Duplication 🆕 (2 cartas, deterministico, MESMO TURNO)**
- Pecas: Approach + Flare + qualquer criatura vermelha nao-ficha
- Setup: Cast Approach. Sacrifica criatura vermelha. Flare FREE → copia Approach.
- Resultado: 2 casts de Approach no MESMO TURNO = vitoria IMEDIATA.
- Confiabilidade: 9/10. Requer criatura vermelha (Dragon's Rage Channeler, Storm-Kiln, Lorehold, dragon do Rite). Com 6+ criaturas vermelhas no deck, alta probabilidade.
- **Este e o upgrade MAIS SIGNIFICATIVO do Ciclo #10.** Reduz Approach clock de "2 turnos" para "1 turno, 7 mana, qualquer criatura vermelha."

**Combo 3: Surge to Victory + Approach (2 cartas, deterministico se 3+ criaturas)**
- Pecas: Approach no grave + Surge + 3+ criaturas atacando
- Resultado: 3+ copias de Approach → vitoria garantida
- Confiabilidade: 8/10. Requer setup de board + Approach no grave.

**Combo 4: Mizzix's Mastery overload (1 carta, semi-deterministico)**
- Pecas: Mizzix's + 8-15 instants/sorceries no grave
- Resultado: Conjura todos gratis. Com metade dos spells sendo removal/draw/wipe, gera valor massivo.
- Confiabilidade: 7/10. Nao ganha deterministicamente, mas gera vantagem insuperavel.

#### SEMI-COMBOS

**Twinflame + Surge + Akroma's Will 🆕 (3 cartas, exponencial):**
- Pecas: Twinflame + Surge + Akroma's Will + criatura + Approach no grave
- Resultado: Twinflame dobra criatura → Surge copia Approach com N+1 criaturas → Akroma buffa todas
- Confiabilidade: 6/10. 3 cartas + setup de board. Mas se montar, e OVERKILL.

**Dance with Calamity + Scroll Rack (2 cartas, semi-deterministico):**
- Pecas: Dance + Scroll Rack
- Setup: Scroll Rack coloca 8 spells baratas no topo → Dance exila e conjura todas gratis
- Resultado: 8 spells gratis em um turno
- Confiabilidade: 7/10. Scroll Rack e double-null (dificil de tutoriar sem Enlightened).

**Nota: 9/10 (ERA 8/10 no v3.9).** +1 pelo combo Approach+Flare que e MAIS CONFIABLE
que Surge+Approach (2 cartas vs 2 cartas + board) e ganha NO MESMO TURNO (vs proximo turno).
O deck agora tem 4 caminhos deterministicos para vitoria (vs 3 no v3.9).

---

### F) STACK INTERACTION — Como o deck interage na stack?

#### COUNTERSPELLS
**NENHUM.** Estrutural de Boros. Flare of Duplication pode COPIAR counterspell do oponente
contra ele mesmo — uso situacional.

#### PROTECAO NA STACK

| Carta | CMC | Efeito | Instant? |
|:------|:---:|:-------|:--------:|
| Deflecting Swat | 3 | Redireciona spell/ability | ✅ Instant |
| Hexing Squelcher | 2 | Oponentes nao ativam habilidades | Static (criatura) |
| Grand Abolisher | 2 | Oponentes nao conjuram no seu turno | Static (criatura) |
| Flare of Duplication 🆕 | 3 | Copia spell alvo (pode copiar counterspell) | ✅ Instant |
| Teferi's Protection | 3 | Faseia voce e seus permanentes | ✅ Instant |
| Boros Charm | 2 | Indestrutivel (protege de remocao) | ✅ Instant |

#### INSTANT-SPEED REMOVAL (Stack Interaction Indireta)

| Carta | CMC | Alvo |
|:------|:---:|:-----|
| Path to Exile | 1 | Criatura → exila |
| Swords to Plowshares | 1 | Criatura → exila |
| Abrade | 2 | Criatura (3 dano) ou artefato → destroi |
| Chaos Warp | 3 | Permanente → shuffle |
| Generous Gift | 3 | Permanente → destroi |
| Olorin's Searing Light | 4 | Permanente → exila |

#### COMO SOBREVIVE A UM COUNTERSPELL NO APPROACH?

1. **Boseiju, Who Shelters All** — Channel: Approach se torna nao-counteravel. Custo: 2 mana + Boseiju.
2. **Cavern of Souls** — Nomeie Dragon: Lorehold nao-counteravel. (Nao ajuda Approach — e sorcery, nao Dragon.)
3. **Grand Abolisher** — Se no campo, oponentes nao podem conjurar spells no seu turno. Counterspell = spell = bloqueado.
4. **Deflecting Swat** — Redireciona o counterspell para outra spell (ou para Swat mesmo, fizzla).
5. **Flare of Duplication** 🆕 — Se o oponente der counterspell no Approach, Flare copia o Approach na stack em resposta. A copia resolve ANTES do counterspell.

**Nota: 7/10 (ERA 6/10 no v3.9).** +1 pelo Flare de Duplication como resposta a counterspell.
Boseiju + Grand Abolisher + Deflecting Swat + Flare = 4 camadas de protecao anti-counterspell.
Hexing Squelcher cobre habilidades (Thassa's Oracle, Kiki-Jiki).

---

### G) GRAVEYARD HATE & RESILIENCE — Como o deck sobrevive a hate?

#### DEPENDENCIA DO CEMITERIO

| Carta | Dependencia | Se exilarem o grave, perde funcionalidade? |
|:------|:-----------:|:-------------------------------------------|
| Mizzix's Mastery | **ALTA** | ❌ SIM — totalmente inutilizada sem grave |
| Arcane Bombardment | **ALTA** | ❌ SIM — se exilarem as cartas ja exiladas por Bombardment |
| Surge to Victory | **ALTA** | ❌ SIM — precisa de Approach/sorcery no grave |
| Lorehold (commander) | **ALTA** | ❌ SIM — sem spells no grave, commander faz nada |
| Restoration Seminar | **MEDIA** | ⚠️ Parcial — ainda cria Lesson token, mas perde recursao |
| Faithless Looting | **BAIXA** | ✅ Nao — flashback ainda funciona se nao exilar |
| Dragon's Rage Channeler | **BAIXA** | ⚠️ Parcial — surveil funciona, delirium enfraquece |
| Olorin's Searing Light | **BAIXA** | ✅ Nao — ainda e removal |

#### SE UM OPONENTE JOGAR REST IN PEACE, O DECK PERDE?

**Impacto: ALTO.** Rest in Peace anula:
- Mizzix's Mastery (overload = zero spells)
- Arcane Bombardment (nao tem o que exilar do grave)
- Surge to Victory (sem Approach no grave)
- Lorehold (sem spells no grave para copiar)
- Restoration Seminar (sem spell para retornar)

**Mas o deck NAO FICA INUTILIZADO:**
- Token makers (Rite, Storm Herd, Emeria's Call) nao usam grave
- Pumps (Boros Charm, Akroma's Will) nao usam grave
- Approach of the Second Sun + Flare de Duplication nao usam grave
- Insurrection nao usa grave
- Dance with Calamity e Improvisation Capstone nao usam grave
- Smothering Tithe, Jeska's Will, tesouros — nao usam grave
- Twinflame — nao usa grave (copia criatura em jogo, nao no cemiterio)

**Plano B sem cemiterio:**
1. Token army (Rite + Storm Herd)
2. Akroma's Will / Boros Charm pump
3. Approach + Flare = vitoria no mesmo turno
4. Insurrection
5. Twinflame + Surge? Nao — Surge depende do grave. Mas Twinflame + Akroma's Will ainda funciona.

**Respostas a Rest in Peace / Leyline of the Void:**

| Resposta | CMC | Eficacia |
|:---------|:---:|:--------:|
| Chaos Warp | 3 | ✅ Shuffle — remove permanente problematico sem destruir |
| Generous Gift | 3 | ✅ Destroi qualquer permanente |
| Boseiju, Who Shelters All | 2 (Channel) | ✅ Channel — nao e spell, nao pode ser counterada |
| Abrade | 2 | ❌ So artefatos (RiP e encantamento) |
| Olorin's Searing Light | 4 | ✅ Exila encantamento/artefato |

**Conclusao: 4 respostas para RiP/Leyline.**
Com Flare de Duplication, o plano B (Approach+Flare) ganha sem cemiterio E sem combate.
Isso torna o deck MENOS dependente do cemiterio que no v3.9.

**Graveyard Resilience Score: 6/10 (ERA 5/10 no v3.9).**
+1 pelo combo Approach+Flare que e um plano B deterministico sem cemiterio.
Ainda ha dependencia alta (Mizzix's, Bombardment, Surge, Lorehold), mas o plano B
e mais forte e mais rapido.

---

## Secao 4: DOUBLE-NULL AUDIT (pos-Ciclo #10)

### Cartas sem classificacao (functional_tag IS NULL AND 0 card_tags)

| Carta | CMC | EDHREC | Trend | Risco | Acao |
|:------|:---:|:------:|:-----:|:-----:|:-----|
| **Scroll Rack** | 2 | 59.7% | +0.15 | 🔴 NAO CORTAR | Core engine. Topdeck manipulation. Nivel 4. |
| **Penance** | 3 | 41.8% | +1.15 | 🔴 NAO CORTAR | Topdeck setup + anti-removal. Miracle enabler. Nivel 4. |
| **Taunt from the Rampart** | 5 | 35.2% | +0.10 | 🟢 MANTER | 35.2% EDHREC estavel. Goad util em multiplayer. Nivel 2. |
| **Grand Abolisher** | 2 | 11.7% | -0.27 | 🟡 MONITORAR | UNICA protecao proativa anti-counterspell. Nivel 2. Declinio leve. |

**Resumo: 4 double-nulls (eram 10 no baseline, 5 no v3.9, Ruby Medallion removido C#10).**
- 2 sao core engines (Scroll Rack, Penance) — NAO TOCAR
- 1 e declining leve com funcao unica (Grand Abolisher) — MANTER como protecao anti-counterspell
- 1 e estavel com EDHREC medio (Taunt) — MANTER

**Nao ha double-nulls cortaveis no momento.**

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

## Secao 5: TREND ANALYSIS (pos-Ciclo #10)

### Cartas em Declinio no Deck (trend < -0.2)

| Carta | EDHREC | Trend | Ciclos em Declinio | Acao |
|:------|:------:|:-----:|:------------------:|:-----|
| Esper Sentinel | 32.5% | -0.54 | 6 | Monitorar — EDHREC ainda alto |
| Grand Abolisher | 11.7% | -0.27 | 3+ | MANTER — unica protecao proativa anti-counterspell |
| Call Forth the Tempest | 65.5% | -0.30 | 2 | Manter — alta EDHREC |
| Fated Clash | 15.6% | -0.19 | 3+ | Monitorar — no limiar |

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

**Todas as rising stars do EDHREC ja estao no deck.**

---

## Secao 6: ANALISE DE MATCHUPS (via BATTLE_LOG)

| Arquetype | Win Rate | Maior Fraqueza |
|:----------|:--------:|:---------------|
| Control | 56.0% | -- (Boros > Control com Boseiju + Cavern + Grand Abolisher + Flare) |
| Midrange | 53.2% | -- (valor supera) |
| Aggro | 51.8% | -- (wipes + lifegain do One Ring) |
| **Combo** | **46.5%** | **Sem counterspell. Depende de remocao instantanea + Hexing Squelcher.** |

> **Nota:** BATTLE_LOG data e de pos-Ciclo #4 (Exec#8). Nao foi atualizada desde entao.
> O deck melhorou significativamente (+6 ciclos, Akroma's Will, Flare, Twinflame, Chaos Warp,
> Wedding Ring, Victory Chimes, Abrade). Win rates atuais provavelmente sao melhores.
> **Especialmente contra Control:** Flare de Duplication como resposta a counterspell + Grand Abolisher
> mantido = matchup contra Control deve ser ainda mais favoravel.

---

## Secao 7: O PLANO DE JOGO — Turn by Turn (Atualizado pos-C#10)

### T1 (Setup Inicial)
**Objetivo:** Ramp + topdeck setup
**Cartas ideais:** Sol Ring, Land Tax, Weathered Wayfarer, Sensei's Top, Library of Leng, Gamble, Enlightened Tutor, Esper Sentinel, Dragon's Rage Channeler
**Sequencia ideal:** Land Tax OU Wayfarer → T2 tera 3-4 lands

### T2 (Ramp Secundario + Draw/Loot)
**Objetivo:** Fixing + draw/loot + protecao
**Cartas ideais:** Arcane/Boros Signet, Talisman, Faithless Looting, Thrill of Possibility, Scroll Rack, Twinflame (copia Dragon's Rage Channeler para double surveil), Lightning Greaves, Grand Abolisher, Hexing Squelcher
**Sequencia ideal:** Signet + Faithless → preenche grave, draw

### T3 (Protecao + Engine Setup)
**Objetivo:** Estabelecer protecao + preparar Lorehold
**Cartas ideais:** Greaves, Grand Abolisher, Hexing Squelcher, Smothering Tithe, Archaeomancer's Map, Jeska's Will, Monument to Endurance, Wedding Ring, Flare of Duplication (copia Faithless/Jeska's)
**Sequencia ideal:** Greaves OU Tithe → T4 Lorehold seguro

⚠️ **Este e o turno PROBLEMATICO.** Com T3 estimado ~15%, aproximadamente 1 a cada 6-7 jogos
o deck nao tem play T3. O net DCMC=-2 do C#10 deve reduzir T3 em ~1.5-2pp (de 16.9% → ~15%).
**Mulligan Execucao #11 pendente para confirmar.**

### T4 (Lorehold + Valor)
**Objetivo:** Conjurar Lorehold + gerar valor imediato
**Cartas ideais:** Lorehold, Big Score, Unexpected Windfall, The One Ring, Storm-Kiln Artist, Akroma's Will (defensivo)
**Sequencia ideal:** Lorehold + Big Score (instant) → 2 treasures + draw + copy

### T5 (Motor Arrancado)
**Objetivo:** Copy engines + free spells
**Cartas ideais:** Double Vision, Arcane Bombardment, Dance with Calamity, Improvisation Capstone, The Dawning Archaic
**Sequencia ideal:** Double Vision → Dance copiada → 16 cartas exiladas, conjura gratis

### T6+ (Fechar o Jogo — AGORA COM MAIS PATHS)
**Objetivo:** Wincon
**Cartas ideais:** 
- **Approach + Flare** (7 mana + criatura vermelha = vitoria NO MESMO TURNO) 🆕
- Insurrection + Boros Charm/Akroma's Will
- Storm Herd + Akroma's Will (overkill)
- Mizzix's Mastery overload
- Surge + Approach + Twinflame (copia exponencial) 🆕
- Arcane Bombardment chain + Double Vision (3-4 spells gratis/turno)
- **8+ paths de vitoria (eram 8 no v3.9, agora com Flare+Approach e Twinflame+Surge sao PATHS DISTINTOS).**

---

## Secao 8: GAPS E PROBLEMAS

### GAP #1: Sem Play T3 estimado ~15% (DEFENSIVO) 🔴

| Metrica | Pos-C#9 | Pos-C#10 (est.) | Limite |
|:--------|:-------:|:---------------:|:------:|
| Sem Play T3 | 16.9% | ~15% | 12% |
| Ramp T1 (estrito) | 20.1% | ~20% | -- |
| Jogaveis | 46.3% | ~48% | -- |

**Causa raiz:** Apenas 3 fontes de ramp T1 estrito.
**Melhora esperada do C#10:** DCMC=-2 → T3: 16.9% → ~15% (-1.5 a -2pp).
**Solucao viavel:** Adicionar fast mana CMC 0-1 (Chrome Mox, Mana Vault) — requer AQUISICAO.
**Confirmacao:** Executar Mulligan Execucao #11 com N=1000, seed=42.

### GAP #2: Draw real = 7 (1 abaixo do perfil minimo de 8) 🟡

Draw real = 7 fontes: Esper Sentinel, Thrill of Possibility, Dragon's Rage Channeler, The One Ring,
Valakut Awakening, Wedding Ring, Victory Chimes.
(Reforge the Soul e wheel. Sensei's Top e virtual. Flare de Duplication nao e draw.)

**A 1 fonte do perfil minimo.** Aceitavel para Boros.
Skullclamp (aquisicao) resolveria — transforma tokens em draw 2.

### GAP #3: Colecao esgotada de CMC 1-2 🔴

Apos 25 swaps, a colecao de cartas CMC ≤ 3 com EDHREC > 15% que NAO estao no deck esta VAZIA.
Todos os upgrades restantes requerem AQUISICAO.

| Carta Desejada | CMC | Funcao | EDHREC | Custo Aprox |
|:---------------|:---:|:-------|:------:|:-----------:|
| Skullclamp | 1 | Draw engine | 45% | $5-8 |
| Mana Vault | 1 | Fast mana | Staple | $40-60 |
| Chrome Mox | 0 | Fast mana | Staple | $60-80 |
| Underworld Breach | 2 | Recursion massiva | 35% | $15-20 |
| Enlightened Tutor (ja no deck) | 1 | Tutor | 49% | -- |

### GAP #4: Fated Clash (15.6% EDHREC) — no limiar 🟡

Fated Clash e o board wipe mais fraco do deck (bounce 1 por oponente, CMC 5).
Com EDHREC 15.6% e trend -0.19, esta no limiar de corte. Mas sem substituto viavel
na colecao (CMC ≤ 3 com funcao similar), manter e a melhor opcao.

### GAP #5: Sem bounce universal 🟡

Cyclonic Rift e azul. O deck depende de remocao pontual (Chaos Warp, Generous Gift).
Em mesas com muitos encantamentos/artefatos problematicos, pode ser insuficiente.

---

## Secao 9: ESTRATEGIA PARA CICLO #11

### Nivel de Estrategia: DEFENSIVO ou 0-SWAPS (aguardando Mulligan Execucao #11)

| Cenario | T3 | Estrategia | Acao |
|:--------|:--:|:-----------|:-----|
| Exec#11: T3 < 12% | ~10-11% | BALANCED | 0-2 swaps. Mas colecao vazia de CMC 1-2. |
| Exec#11: T3 12-15% | ~12-15% | DEFENSIVO | Alvo DCMC=-5 a -10. Mas colecao esgotada. 0 swaps. |
| Exec#11: T3 > 15% | ~15%+ | DEFENSIVO | 0 swaps. Documentar que bottleneck e colecao. |
| Exec#11: T3 ~15% (mais provavel) | ~15% | DEFENSIVO | 0 swaps — colecao esgotada. Priorizar aquisicoes. |

### Necessidade Estrategica (escala 0-5)

| Swap | Sai | Entra | DCMC | Necessidade | Bloqueio |
|:-----|:----|:------|:----:|:-----------:|:---------|
| Esper Sentinel → Skullclamp | Esper Sentinel (CMC 1) | Skullclamp (CMC 1) | 0 | 3 | **Nao na colecao** |
| Fated Clash → cheap interaction | Fated Clash (CMC 5) | -- | -3+ | 2 | Nenhum candidato na colecao |
| Grand Abolisher → cheap draw | Grand Abolisher (CMC 2) | -- | ~0 | 1 | Nenhum candidato; Abolisher e protecao unica |

### Decisao: 0 SWAPS para Ciclo #11

**Justificativa:** O deck esta no melhor estado desde o baseline. Motor 4/4, Copy 6,
SYNERGY_MAP 7 eixos todos funcionais (scores 6-9/10). Nivel 1 vazio — nao ha filler.
O unico gap real (T3 elevado) e causado por falta de fast mana CMC 0-1, que NAO esta na colecao.
Forcar swaps sem colecao piora o deck.

**Recomendacao de aquisicao (prioridade):**
1. **Skullclamp** ($5-8) — Draw engine que resolve GAP #2. Prioridade #1: menor custo, maior impacto/dolar.
2. **Chrome Mox** ($60-80) — Fast mana T0. Reduz T3 em ~2pp sozinho.
3. **Mana Vault** ($40-60) — Fast mana T1. Reduz T3 em ~1.5pp.
4. **Underworld Breach** ($15-20) — Recursao massiva backup. Sinergia com o motor.

---

## Secao 10: RESUMO EXECUTIVO

### Estado do Deck: EXCELENTE (Pos-Ciclo #10, 25 swaps)

| Indicador | Status |
|:----------|:------:|
| Motor | 4/4 COMPLETO |
| Copy Engines | 6 ativas (Lorehold + Double Vision + Bombardment + Dawning Archaic + Flare + Twinflame) |
| Token+Pump | 8/10 |
| Wipes+Protection | 8/10 |
| Recursion | 8/10 |
| Mana Explosiva | 7/10 |
| Combo Pieces | **9/10** (+1: Approach+Flare combo) |
| Stack Interaction | **7/10** (+1: Flare anti-counterspell) |
| Graveyard Resilience | **6/10** (+1: plano B Approach+Flare) |
| **Sem Play T3** | **~15% 🟡 (est.)** |
| Draw Real | 7 (perfil 8-12) |
| Double-nulls restantes | 4 (0 cortaveis) |
| Nivel 1 | **VAZIO** — sem filler |
| Declinios monitorados | 4 (Esper Sentinel pior) |

### Top 3 GAPS

1. **Sem Play T3 ~15%** → DEFENSIVO. So 3 fontes de ramp T1 estrito.
   Solucao requer aquisicao de fast mana (Chrome Mox, Mana Vault).
   Executar Mulligan Execucao #11 para confirmar impacto do DCMC=-2.

2. **Colecao esgotada** → Nenhum upgrade CMC ≤ 2 disponivel. O deck atingiu
   maturidade maxima com a colecao atual. Todos os proximos upgrades requerem AQUISICAO.
   25 swaps aplicados desde baseline.

3. **Draw = 7 (vs 8-12 perfil)** → -1 do minimo. Skullclamp ($5-8) resolveria.
   Prioridade #1 de aquisicao: menor custo, maior impacto.

### O que melhorou do v3.9 para v3.10

1. **Flare of Duplication (Ciclo #10):** Combo Approach+Flare = vitoria no mesmo turno.
   Combo Pieces subiu de 8/10 para 9/10. Stack Interaction subiu de 6/10 para 7/10.
   Graveyard Resilience subiu de 5/10 para 6/10 (plano B mais forte).

2. **Twinflame (Ciclo #10):** Creature copy que expande Surge chain. Copy layers: 4→6.
   Dano exponencial com Surge+Akroma's Will.

3. **Ruby Medallion removido:** Nivel 1 agora VAZIO. Double-nulls: 5→4.
   Nao ha cartas claramente cortaveis no deck.

4. **CMC medio: 3.86 → 3.71 (-0.15).** Galvanoth (CMC 5) trocado por Flare (CMC 3).
   Net DCMC=-2 — DEFENSIVO light. T3 projetado ~15% (de 16.9%).

5. **Galvanoth removido:** Criatura 3/3 fragil que raramente ativava. Efeito duplicado
   por Dance+Capstone. Substituido por Flare que e instant + gratis + combo.

### Mudancas desde baseline (25 swaps em 10 ciclos)

| Ciclo | Swaps | Net DCMC | Estrategia | T3 Aprox |
|:-----:|:-----:|:--------:|:----------|:---------|
| #1 | 3 | ~+3 | AGGRESSIVE | 12% |
| #2 | 3 | ~+4 | AGGRESSIVE | 16% |
| #3 | 5 | ~-4 | DEFENSIVO | 16.4% |
| #4 | 3 | -15 | DEFENSIVO | 12.0% |
| #5 | 3 | +1 | BALANCED | 15.3% |
| #6 | 2 | -2 | DEFENSIVO | ~13-14% |
| #7 | 1 | +2 | AGGRESSIVE (erro T3!) | ~15% |
| #8 | 0 | 0 | (0 swaps) | ~15% |
| #9 | 1 | +2 | AGGRESSIVE (erro T3!) | 16.9% |
| #10 | 2 | -2 | DEFENSIVO | ~15% (est.) |

**Licao aprendida:** Ciclos #7/#8/#9 usaram T3=3.7% (errado) para escolher AGGRESSIVE.
O T3 real estava ~13-16%. O net DCMC +4 acumulado elevou T3 de ~13% para 16.9%.
Ciclo #10 foi o PRIMEIRO com T3 correto e estrategia DEFENSIVO.
**Nunca confiar no T3 do Evolution Oracle sem verificar MULLIGAN_LOG.md.**

### Licao do Ciclo #10

**Flare de Duplication + Approach e a descoberta mais impactante do deck ate agora.**
Transformou a wincon primaria de "vitoria em 2 turnos" para "vitoria em 1 turno com 7 mana".
Combinado com Grand Abolisher mantido (protecao anti-counterspell) e Boseiju (uncounterable),
o Approach agora e virtualmente imune a interacao — e fecha o jogo no mesmo turno.

**O deck Lorehold esta PROXIMO DO OTIMO** com a colecao atual. 25 swaps em 10 ciclos.
Nao ha filler. Nao ha double-nulls cortaveis. Nao ha Nivel 1. Os 7 eixos de sinergia
todos pontuam entre 6-9/10. O unico gap real e falta de fast mana, que requer aquisicao.

**Proximo passo: Executar Mulligan Execucao #11 para confirmar T3 pos-C#10.**

---

*Relatorio gerado por Purpose Analyzer v3.10 em 2026-05-31T18:55:38+00:00*
*Analista: Hermes Agent — Agente 2 (Lorehold Purpose Analyzer)*
*Proxima execucao: v3.11 apos Mulligan Execucao #11 + possivel re-score com dados frescos de BATTLE_LOG*
