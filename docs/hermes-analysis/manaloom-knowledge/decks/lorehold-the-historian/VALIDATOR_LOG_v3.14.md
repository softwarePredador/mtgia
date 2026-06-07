# Purpose Analyzer v3.14 — Lorehold Spellslinger: REDESCOBERTA — Deck Divergiu do Pipeline

> **Data:** 2026-06-01T02:10:00+00:00
> **Fonte:** knowledge.db deck_id=6 — ESTADO REAL DO DB (nao o que EVOLUTION_LOG descreve)
> **Deck:** Lorehold Spellslinger — 100 cards, 86 rows, 35 lands, CMC medio ~3.75
> **Analista:** Hermes Agent — Purpose Analyzer v3.14
> **Foco:** ⚠️ DISCREPANCIA CRITICA — DB tem cartas diferentes das que EVOLUTION_LOG e VALIDATOR_LOG v3.12 descrevem

---

## Secao 0: ALERTA — DISCREPANCIA ENTRE DB E ANALISES

### O que o EVOLUTION_LOG (C#14, C#15, C#16) diz que o deck tem:

O Evolution Oracle e o VALIDATOR_LOG v3.12 descrevem um deck com **Insurrection** (CMC 8, wincon), **Wedding Ring** (CMC 4, draw), e **Fated Clash** (CMC 5, board wipe).

### O que o DB REALMENTE contem:

Estas cartas **NAO ESTAO** em `deck_cards WHERE deck_id=6`:

| Carta | EDHREC | Funcao | Status no DB |
|:------|:------:|:-------|:------------|
| Insurrection | 59.7% | wincon, theft | ❌ AUSENTE |
| Wedding Ring | ~25% | draw, lifegain | ❌ AUSENTE |
| Fated Clash | 15.6% | board wipe (bounce) | ❌ AUSENTE |

Em vez disso, o DB contem **3 cartas que NENHUMA analise previa documenta**:

| Carta | CMC | EDHREC | Funcao | Status no DB |
|:------|:---:|:------:|:-------|:------------|
| **Worldfire** | 9 | 20.5% | wincon (exile everything, life=1) | ✅ PRESENTE |
| **Rise of the Eldrazi** | 10 | <5% | wincon (extra turn + annihilator) | ✅ PRESENTE |
| **Mother of Runes** | 1 | ~46% | protection (tap: prot from color) | ✅ PRESENTE |

### Impacto das Mudancas

| Metrica | Pre-Mudanca (v3.12) | Pos-Mudanca (DB real) | Delta |
|:--------|:--------------------:|:---------------------:|:-----:|
| Board Wipes | 5 | **4** | **-1** (Fated Clash removido) |
| Draw (real) | 7 | **6** | **-1** (Wedding Ring removido) |
| Protection total | 5 | **6** | **+1** (Mother of Runes) |
| Wincon dedicado | 6 | **7** | **+1** (Worldfire + Rise, -Insurrection) |
| Net CMC medio | ~3.71 | ~3.75 | **+0.04** |
| Wipes + Protection ratio | 5+5=10 | 4+6=10 | Inalterado |
| Colecao | Esgotada | **PODE TER MUDADO** | Verificar user_collection |

### ⚠️ Como isso aconteceu?

O Evolution Oracle C#14, C#15, e C#16 reportaram **0 swaps**, mas o deck claramente mudou. Possiveis causas:
1. **Usuario fez swaps manuais** fora do pipeline (mais provavel — Mother of Runes e Worldfire sao staples conhecidos que um jogador compraria)
2. **Evolution Oracle leu VALIDATOR_LOG stale** e nunca verificou o DB real
3. **Swaps foram aplicados por outro agente** sem registro adequado

**Regra para o futuro:** Todo agente que analisa o deck deve verificar `deck_cards WHERE deck_id=6` no inicio, NAO confiar no EVOLUTION_LOG ou VALIDATOR_LOG anterior. O DB e a fonte da verdade.

### Net DCMC: +3 (PIORA T3 levemente)

| OUT (CMC) | IN (CMC) | Delta |
|:----------|:--------|:-----:|
| Insurrection (8) | Worldfire (9) | +1 |
| Wedding Ring (4) | Mother of Runes (1) | **-3** |
| Fated Clash (5) | Rise of the Eldrazi (10) | +5 |
| **Total DCMC** | | **+3** |

**Efeito no T3:** Mother of Runes (CMC 1) ajuda T3, Worldfire e Rise sao irrelevantes para T3. Wedding Ring (CMC 4) removido — nao afetava T3. Fated Clash (CMC 5) removido — nao afetava T3. **T3 provavelmente inalterado ou levemente melhor (Mother of Runes CMC 1 e uma play T1 valida).**

---

## Secao 1: Visao Geral do Deck (DB REAL — 2026-06-01)

### Metricas Recalculadas do DB

| Metrica | Deck Real | Perfil EDHREC | Status |
|:--------|:---------:|:--------------|:-------|
| Lands | 35 | 36-38 | OK (-1, MDFCs compensam) |
| Ramp (real) | 14 | 10-13 | +1 (treasure-heavy) |
| Draw (real) | 6 | 8-12 | **-2 (PIOROU vs v3.12)** |
| Removal | 6 | 4-6 | No limite |
| Board Wipe | **4** | 3-5 | **-1 vs v3.12** (OK, dentro do range) |
| Protection (total) | **6** | 3-4 | **+2 vs v3.12** (+1 Mother, +2 stack: Swat, Squelcher; +1 proativa: Grand Abolisher) |
| Recursion | 5 | 2-5 | No limite |
| Wincon (dedicado) | 2 DB | Funcionalmente 7+ paths | Ver Secao 3 |
| Engine/Copy/Big Spell | 9+ | 4-6 | Motor 4/4 + Copy 6 |
| Tutor | 2 | 1-3 | OK |
| CMC medio | ~3.75 | ~4.1 | OK |

### Deck Health (DB REAL)

| Indicador | Valor | Interpretacao |
|:----------|:-----:|:--------------|
| Motor | 4/4 COMPLETO | Treasure → Free Big Spell → Copy → Payoff |
| Copy Engines | **7 ativas** | Lorehold + Double Vision + Bombardment + Dawning Archaic + Flare + Twinflame + **Rise of the Eldrazi extra turn copy** |
| **Sem Play T3** | **~13-14% (estimado)** | DEFENSIVE (>12%). Nao re-simulado pos-mudancas. |
| Mulligan Rate | ~48% estimado | Estrutural (35 lands, 3 T1 ramp estrito) |
| Ramp T1 (Sol Ring only) | ~6.3% | Canonico |
| Draw Real | **6** fontes | **2 abaixo do perfil minimo (8)** |
| Protection (total) | 6 fontes | +1 (Mother of Runes, CMC 1, excelente) |
| Double-null | 4 | 2 core (Scroll Rack, Penance), 2 situational (Taunt, Grand Abolisher) |
| Board Wipes | 4 | 1 a menos que v3.12 (Fated Clash removido) |

### ⚠️ Draw Real: 6 fontes (piorou)

Draw real = 6: Esper Sentinel, Thrill of Possibility, The One Ring, Valakut Awakening, Victory Chimes, Reforge the Soul (wheel).

Wedding Ring removido → draw caiu de 7 para 6. **2 abaixo do perfil minimo de 8.** Este e o gap mais urgente.

**Nota:** Topdeck manipulation (Top, Scroll Rack, Penance) e virtual draw. Monument to Endurance e loot (nao net draw). Contagem conservadora.

---

## Secao 2: CLASSIFICACAO ESTRATEGICA — TODAS as Cartas (DB REAL)

### Nivel 5: NAO SE JOGA SEM (Core Identity)

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 5 |
|:------|:---:|:------:|:------------|:------------------|
| **Lorehold, the Historian** | 5 | -- | commander, engine, copy | Copia instants/sorceries do grave + desconto de 1. Define o deck. |
| **Approach of the Second Sun** | 7 | 63.8% | wincon | Wincon primaria. Com Flare: vitoria no MESMO turno. Com topdeck, deterministico. |
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
| **Akroma's Will** | 4 | ~20% | wincon, pump, protection | Flying + double strike + vigilance + lifelink + prot all colors + indestructible. |
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
| **Monument to Endurance** | 3 | 41.3% | engine, draw, loot | Draw + loot + drain. Tag do DB "ramp" esta ERRADO — e engine. |
| **Library of Leng** | 1 | 77.8% | hand, graveyard | Sem limite de mao + descarte no topo. |
| **Valakut Awakening** | 3 | 35.7% | draw, hand_reset | MDFC. Hand reset + draw. |
| **Emeria's Call** | 7 | 43.4% | token, land | MDFC. Flexibilidade. |
| **Longshot, Rebel Bowman** | 4 | 27.3% | payoff | Bolt sempre que Lorehold ataca/bloqueia. |
| **Bender's Waterskin** | 3 | 22.8% | ramp | Rock ou tutora land. |
| **Olorin's Searing Light** | 4 | 49.6% | removal, graveyard | Exila permanente + instant/sorcery do grave. |
| **Victory Chimes** | 3 | 53.6% | draw, engine | Untap a cada turno + draw. Multiplayer value. |
| **The Dawning Archaic** | 3 | 24.0% | engine, copy, free_spell | Copia spells dos oponentes. Rising star (+5.31, 5+ ciclos). |
| **Restoration Seminar** | 7 | 37.8% | recursion, token | Retorna spell + cria Lesson. Rising star (+9.14). |
| **Twinflame** | 2 | -- | copy, creature | Cria copia de criatura com haste. Com Surge+Akroma: dano exponencial. |

### Nivel 3 — NOVAS adicoes (pos-v3.12)

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 3 |
|:------|:---:|:------:|:------------|:------------------|
| **Mother of Runes** | 1 | ~46% | protection | {T}: protecao de cor. Protege Lorehold de remocao. CMC 1 excelente para T1-T3. **MELHOR adicao das 3.** |
| **Worldfire** | 9 | 20.5% | wincon | Exila TODOS permanentes, maos, cemiterios. Vida = 1. Com qualquer token/burn de 1 dano = vitoria. **Game-ender de ultimo recurso.** |
| **Rise of the Eldrazi** | 10 | <5% | wincon, extra_turn | Turno extra + copy de spell. Sinergia com copy engines. **CMC 10 — extremamente caro.** |

### Nivel 2: UTILIDADE SITUACIONAL

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 2 |
|:------|:---:|:------:|:------------|:------------------|
| **Deflecting Swat** | 3 | 42.0% | protection, stack | Redireciona spell/ability. Stack interaction crucial. Tag "big_spell" do DB ERRADO. |
| **Lightning Greaves** | 2 | 73.3% | protection | Shroud + haste. Protege Lorehold. |
| **Grand Abolisher** | 2 | 11.7% | protection, stack | Oponentes nao conjuram no seu turno. Double-null. Trend -0.27. UNICA protecao proativa anti-counterspell. |
| **Hexing Squelcher** | 2 | ~10% | protection, stack | Oponentes nao ativam habilidades. Anti-combo. |
| **Taunt from the Rampart** | 5 | 35.2% | goad, control | Goad em todas as criaturas. Double-null. Util em multiplayer. |

### Nivel 1: SUBSTITUIVEL (Candidato a corte)

**Candidatos potenciais (novos em relacao ao v3.12 que tinha Nivel 1 VAZIO):**

| Carta | CMC | EDHREC | Por que poderia ser Nivel 1 |
|:------|:---:|:------:|:------------|
| **Rise of the Eldrazi** | 10 | <5% | CMC 10, sinergia minima com spellslinger. Extra turn e bom mas a 10 mana e irrealista. Mais lento que todas as outras wincons. |
| **Worldfire** | 9 | 20.5% | Wincon situacional. Exila seus proprios recursos (grave, board). Anti-sinergico com Mizzix/Bombardment. |
| **Mother of Runes** | 1 | ~46% | **NAO e Nivel 1.** Excelente adicao. Protege Lorehold. CMC 1. |

⚠️ **Rise of the Eldrazi (CMC 10) e o candidato mais proximo de Nivel 1.** Extra turn e copy sao bons, mas a 10 mana, Dance with Calamity (CMC 8, 67% EDHREC) ou Improvisation Capstone (CMC 7, 49% EDHREC) geram MAIS valor por MENOS mana. Rise compete diretamente com essas engines e perde.

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
| Urza's Saga | tutor, token, ramp | Busca Sol Ring, Top, Library. |
| 8x Mountain, 8x Plains | basic | Land Tax + Wayfarer targets. |

---

## Secao 3: SYNERGY_MAP — 7 Eixos (A-G) — RECALCULADO do DB REAL

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
| **Twinflame** | 2 | Copia criatura com haste | Dobra criaturas para Surge |
| **Worldfire** | 9 | Exila tudo, vida = 1 | **NOVO**: Com qualquer token de 1/1 ou burn = vitoria |

#### PARES TOKEN + PUMP — Calculo de Dano

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

**Worldfire + Qualquer Token/Burn (NOVO PATH):**
- Float 9 mana, cast Worldfire. Tudo exilado, vida = 1.
- Com qualquer token 1/1 (Urza's Saga construct, Lesson, Dragon) OU burn (Abrade, Olorin)
- Resolve Worldfire → stack tem dano/token → vitoria
- **Conclusao: 9 mana + qualquer fonte de 1 dano = vitoria. Caminho alternativo.**

**Twinflame + Surge to Victory + Akroma's Will (CHAIN EXPONENCIAL):**
- T1: Twinflame copia Lorehold (ou Dragon do Rite) → 2 criaturas com haste
- T2: Surge to Victory exila Approach do grave → 2+ criaturas atacam → 2+ copias de Approach
- T3: Akroma's Will buffa TODAS → flying + double strike + lifelink + indestructible
- **Conclusao: Ganha na HORA com 2+ copias de Approach, tudo indestrutivel.**

**Flare de Duplication + Approach (VITORIA NO MESMO TURNO):**
- T1: Cast Approach of the Second Sun (7 mana)
- T2: Sacrifice criatura vermelha (Dragon's Rage Channeler, Storm-Kiln token, Mother of Runes, etc.)
- T3: Flare de Duplication FREE → copia Approach → 2o cast na stack
- **Conclusao: VITORIA IMEDIATA. Sem esperar 1 turno. Total: 7 mana + qualquer criatura vermelha.**

#### ANALISE DO PLANO TOKEN+PUMP

| Forca | Fraqueza |
|:------|:---------|
| 2 pumps reais: Boros Charm + Akroma's Will | Akroma's Will CMC 4 |
| Twinflame dobra criaturas para Surge chain | Rite lento (1 dragon/cast) |
| Flare + Approach = vitoria sem combate | Storm Herd CMC 10 |
| Worldfire = novo path alternativo | Worldfire exila seus recursos (grave) |
| 3+ paths de vitoria sem combate (Approach, Flare+Approach, Surge+Approach) | Rise of the Eldrazi (CMC 10) compete com estas opcoes |

**Nota: 8/10.** Worldfire adiciona path alternativo mas e situacional.

---

### B) BOARD WIPES + PROTECTION — Wipes assimetricos?

#### BOARD WIPES (4 — era 5 no v3.12, Fated Clash removido)

| Carta | CMC | Efeito | Custo Real |
|:------|:---:|:-------|:-----------|
| Blasphemous Act | 9 | Destroi TODAS as criaturas | Tipicamente R |
| Austere Command | 6 | Destroi 2 de 4 tipos (modular) | Pode pular criaturas |
| Call Forth the Tempest | 8 | Dano = 2X a cada criatura + cascade | Dano massivo + valor |
| Volcanic Vision | 7 | Dano = CMC a cada criatura + retorna spell | Wipe + recursao |

#### PROTECAO (contra wipes: 5; stack: ver Eixo F)

| Carta | CMC | Efeito | Contra o que protege |
|:------|:---:|:-------|:---------------------|
| Boros Charm | 2 | Indestrutivel | Wipes, remocao em massa |
| Teferi's Protection | 3 | Faseia voce e seus permanentes | TUDO |
| Lightning Greaves | 2 | Shroud + haste | Remocao direcionada |
| **Akroma's Will** | 4 | Indestrutivel + prot all colors | Wipes, remocao, combate |
| **Mother of Runes** | 1 | {T}: prot de cor | Remocao direcionada — **NOVO, CMC 1, excelente** |

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

**Worldfire + Boros Charm (NOVO):**
- Float mana → Boros Charm indestrutivel → Worldfire. Seus permanentes sobrevivem.
- Oponentes perdem tudo e ficam com 1 de vida.
- **Custo: 9 + 2 = 11 mana. Mas se tiver token/dragon, e lethal imediato.**

#### RATIO WIPES / PROTECAO
- **4 wipes / 5 protecoes contra wipes = 0.8:1 (MELHOROU vs 1.25:1 do v3.12)**
- Com Fated Clash removido, a qualidade media dos wipes AUMENTOU (Fated era o pior wipe)
- Mother of Runes (CMC 1) adiciona protecao pontual pre-T3
- **Balanco EXCELENTE. Zero risco de auto-destruicao.**

**Nota: 9/10.** (Era 8/10 no v3.12. Melhorou com -1 wipe fraco + +1 protecao premium.)

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
4. **Com Twinflame:** +1 criatura = +1 copia. Com Rite (3 dragons) + Twinflame = 4 copias.
5. **Resultado: Vitoria deterministica com 3+ criaturas e Approach no grave.**

**Chain 4: Restoration Seminar → Spell de Volta → Token (T7+)**
1. T7+: Restoration Seminar → retorna instant/sorcery do grave
2. Cria token 3/2 Lesson. Token pode ser sacrificado para Flare.
3. **Resultado: Recursao + token que alimenta Flare.**

⚠️ **Nova ameaca: Worldfire exila SEU cemiterio tambem.** Se usar Worldfire, perde TUDO no grave — Mizzix, Bombardment, Surge, Lorehold ficam inutilizados. Worldfire e um "botao de reset" que sacrifica seu proprio motor de recursao. So use quando for ganhar na hora (com dano na stack) ou quando o jogo ja estiver perdido.

**Nota: 8/10.** As chains sao fortes, mas Worldfire e anti-sinergico com elas.

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
| **Worldfire** | **9** | **Reset global + lethal setup (NOVO)** |
| Mizzix's Mastery overload | 4 | Todos spells do grave gratis |
| Dance with Calamity | 8 | Exila 8, conjura gratis |
| Call Forth the Tempest | 8+X | Dano + dragoes + cascade |
| Improvisation Capstone | 7 | Exila 7, conjura gratis |
| Brass's Bounty | 7 | Converte lands em tesouros → mais mana |
| **Rise of the Eldrazi** | **10** | **Extra turn + copy (NOVO, CMC mais alto)** |

#### SEQUENCIA IDEAL DE MANA (T1-T6)

| Turno | Mana | Play |
|:-----:|:----:|:-----|
| T1 | 1-3 | Land Tax / Sol Ring / Top / **Mother of Runes** |
| T2 | 2-5 | Signet + Faithless / Scroll Rack / **Mother protege** |
| T3 | 3-7 | Tithe / Jeska's Will / Monument / Greaves |
| T4 | 4-10 | Lorehold + Big Score / Windfall / One Ring |
| T5 | 5-15 | Double Vision + Dance / Bombardment |
| T6+ | 8-20+ | Storm Herd, Approach+Flare, **Worldfire**, Mizzix |

**Nota: 7/10.** O deck gera mana explosiva. Mother of Runes adiciona early game sem custo de mana alto. Worldfire e Rise adicionam sinks caros.

---

### E) COMBO PIECES — Existe combo deterministico?

#### COMBOS DETERMINISTICOS

**Combo 1: Approach + Topdeck Manipulation (2 cartas, deterministico)**
- Pecas: Approach + Sensei's Top OU Scroll Rack OU Penance
- Setup: Cast Approach → com trigger na stack, ativar Top (draw Approach) ou Scroll Rack (colocar Approach no topo)
- Resultado: Proximo turno, cast Approach de novo = vitoria.
- Confiabilidade: 10/10. Com Enlightened Tutor e Gamble, altamente tutoravel.

**Combo 2: Approach + Flare de Duplication (2 cartas, deterministico, MESMO TURNO)**
- Pecas: Approach + Flare + qualquer criatura vermelha (Mother of Runes, Dragon's Rage Channeler, Storm-Kiln token)
- Setup: Cast Approach. Sacrifica criatura vermelha. Flare FREE → copia Approach.
- Resultado: 2 casts de Approach no MESMO TURNO = vitoria IMEDIATA.
- Confiabilidade: 9/10. **Mother of Runes pode ser sacrificada para Flare — sinergia adicional.**

**Combo 3: Surge to Victory + Approach (2 cartas, deterministico se 3+ criaturas)**
- Pecas: Approach no grave + Surge + 3+ criaturas atacando
- Resultado: 3+ copias de Approach → vitoria garantida
- Confiabilidade: 8/10.

**Combo 4: Mizzix's Mastery overload (1 carta, semi-deterministico)**
- Pecas: Mizzix's + 8-15 instants/sorceries no grave
- Resultado: Conjura todos gratis.
- Confiabilidade: 7/10.

**Combo 5: Worldfire + Dano na Stack (2 cartas, deterministico, NOVO)**
- Pecas: Worldfire + qualquer fonte de 1 dano (Abrade, Olorin, Lightning Greaves equipado em criatura, token atacando)
- Setup: Float mana → cast fonte de dano (alvo: qualquer oponente) → em resposta, cast Worldfire
- Stack resolve: Worldfire exila tudo, vida = 1 → dano resolve → oponente morre
- Confiabilidade: 7/10. 9 mana total. Nao depende de Approach.
- ⚠️ ***Importante:** Ordem e crucial. O dano deve estar NA STACK (cast antes do Worldfire). Se o dano for de criatura atacando, Worldfire no combate depois dos blockers declarados — mas Worldfire e sorcery, entao precisa ser na main phase. Use burn spell (Abrade, Olorin, Valakut Awakening dano zero mas e instant) + Worldfire.*

#### SEMI-COMBOS

**Twinflame + Surge + Akroma's Will (3 cartas, exponencial):**
- Pecas: Twinflame + Surge + Akroma's Will + criatura + Approach no grave
- Resultado: Twinflame dobra criatura → Surge copia Approach com N+1 criaturas → Akroma buffa todas
- Confiabilidade: 6/10.

**Dance with Calamity + Scroll Rack (2 cartas, semi-deterministico):**
- Pecas: Dance + Scroll Rack
- Setup: Scroll Rack coloca 8 spells baratas no topo → Dance exila e conjura todas gratis
- Resultado: 8 spells gratis em um turno
- Confiabilidade: 7/10.

**Nota: 9/10.** 5 caminhos deterministicos para vitoria (eram 4 no v3.12). Worldfire adiciona um quinto path que nao depende de Approach, reduzindo a vulnerabilidade a counterspell. Mas o custo de mana (9) e alto e o setup na stack e complexo.

---

### F) STACK INTERACTION — Como o deck interage na stack?

#### COUNTERSPELLS
**NENHUM.** Estrutural de Boros. Flare de Duplication pode COPIAR counterspell do oponente contra ele mesmo — uso situacional.

#### PROTECAO NA STACK

| Carta | CMC | Efeito | Instant? |
|:------|:---:|:-------|:--------:|
| Deflecting Swat | 3 | Redireciona spell/ability | Instant |
| Hexing Squelcher | 2 | Oponentes nao ativam habilidades | Static (criatura) |
| Grand Abolisher | 2 | Oponentes nao conjuram no seu turno | Static (criatura) |
| Flare de Duplication | 3 | Copia spell alvo (pode copiar counterspell) | Instant |
| Teferi's Protection | 3 | Faseia voce e seus permanentes | Instant |
| Boros Charm | 2 | Indestrutivel (protege de remocao) | Instant |
| **Mother of Runes** | **1** | **{T}: protecao de cor — protege criatura de remocao** | **Activated ability (NOVO)** |

#### INSTANT-SPEED REMOVAL

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
3. **Grand Abolisher** — Se no campo, oponentes nao podem conjurar spells no seu turno.
4. **Deflecting Swat** — Redireciona o counterspell para outra spell.
5. **Flare de Duplication** — Copia o Approach na stack em resposta ao counterspell.
6. **Mother of Runes** — Nao ajuda contra counterspell (protege criaturas, nao spells).

**Nota: 7/10.** 5 camadas de protecao anti-counterspell. Mother of Runes nao ajuda diretamente contra counterspell, mas protege Lorehold e Storm-Kiln de remocao pontual, mantendo o motor online.

---

### G) GRAVEYARD HATE & RESILIENCE — Como o deck sobrevive a hate?

#### DEPENDENCIA DO CEMITERIO

| Carta | Dependencia | Se exilarem o grave, perde funcionalidade? |
|:------|:-----------:|:-------------------------------------------|
| Mizzix's Mastery | **ALTA** | SIM — totalmente inutilizada sem grave |
| Arcane Bombardment | **ALTA** | SIM — se exilarem as cartas ja exiladas por Bombardment |
| Surge to Victory | **ALTA** | SIM — precisa de Approach/sorcery no grave |
| Lorehold (commander) | **ALTA** | SIM — sem spells no grave, commander faz nada |
| Restoration Seminar | **MEDIA** | Parcial — ainda cria Lesson token, mas perde recursao |
| Faithless Looting | **BAIXA** | Nao — flashback ainda funciona se nao exilar |
| Dragon's Rage Channeler | **BAIXA** | Parcial — surveil funciona, delirium enfraquece |
| Olorin's Searing Light | **BAIXA** | Nao — ainda e removal |

#### SE UM OPONENTE JOGAR REST IN PEACE, O DECK PERDE?

**Impacto: ALTO.** Rest in Peace anula Mizzix's Mastery, Arcane Bombardment, Surge to Victory, Lorehold, Restoration Seminar.

**Mas o deck NAO FICA INUTILIZADO:**
- Token makers (Rite, Storm Herd, Emeria's Call) nao usam grave
- Pumps (Boros Charm, Akroma's Will) nao usam grave
- Approach + Flare de Duplication nao usam grave
- **Worldfire nao usa grave (NOVO)**
- Dance with Calamity e Improvisation Capstone nao usam grave
- Smothering Tithe, Jeska's Will, tesouros — nao usam grave
- Twinflame — nao usa grave
- **Mother of Runes — nao usa grave (NOVO)**

**Plano B sem cemiterio (FORTALECIDO vs v3.12):**
1. Token army (Rite + Storm Herd)
2. Akroma's Will / Boros Charm pump
3. Approach + Flare = vitoria no mesmo turno
4. **Worldfire + dano na stack (NOVO — nao depende de grave)**
5. Mother of Runes protege Lorehold/bombas de remocao

**Respostas a Rest in Peace / Leyline of the Void:**

| Resposta | CMC | Eficacia |
|:---------|:---:|:--------:|
| Chaos Warp | 3 | Shuffle — remove permanente problematico |
| Generous Gift | 3 | Destroi qualquer permanente |
| Boseiju, Who Shelters All | 2 (Channel) | Channel — nao e spell |
| Abrade | 2 | So artefatos (RiP e encantamento) |
| Olorin's Searing Light | 4 | Exila encantamento/artefato |

**Conclusao: 4 respostas para RiP/Leyline.**
Plano B sem cemiterio agora inclui Worldfire — um reset global que ganha sem Approach e sem grave.

**Graveyard Resilience Score: 7/10.** (Era 6/10 no v3.12. Melhorou porque Worldfire e Mother of Runes nao dependem de grave.)

---

## Secao 4: DOUBLE-NULL AUDIT (DB REAL)

### Cartas sem classificacao (functional_tag IS NULL AND 0 card_tags)

| Carta | CMC | EDHREC | Trend | Risco | Acao |
|:------|:---:|:------:|:-----:|:-----:|:-----|
| **Scroll Rack** | 2 | 59.7% | +0.15 | NAO CORTAR | Core engine. Topdeck manipulation. Nivel 4. |
| **Penance** | 3 | 41.8% | +1.15 | NAO CORTAR | Topdeck setup + anti-removal. Miracle enabler. Nivel 4. |
| **Taunt from the Rampart** | 5 | 35.2% | +0.10 | MANTER | 35.2% EDHREC estavel. Goad util em multiplayer. Nivel 2. |
| **Grand Abolisher** | 2 | 11.7% | -0.27 | MONITORAR | UNICA protecao proativa anti-counterspell. Nivel 2. |

**Resumo: 4 double-nulls (nao mudou).** Classificador continua cego para estas cartas. Nenhuma e cortavel.

---

## Secao 5: TREND ANALYSIS

### Cartas em Declinio no Deck (trend < -0.2)

| Carta | EDHREC | Trend | Ciclos em Declinio | Acao |
|:------|:------:|:-----:|:------------------:|:-----|
| Esper Sentinel | 32.5% | -0.54 | 6 | Monitorar — EDHREC ainda alto |
| Grand Abolisher | 11.7% | -0.27 | 3+ | MANTER — unica protecao proativa anti-counterspell |
| Call Forth the Tempest | 65.5% | -0.30 | 2 | Manter — alta EDHREC |

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

## Secao 6: GAPS E PROBLEMAS (DB REAL)

### GAP #1: Draw Real = 6 (2 abaixo do perfil minimo de 8) — CRITICO

**Draw real (conservador) = 6:** Esper Sentinel, Thrill of Possibility, The One Ring, Valakut Awakening, Victory Chimes, Reforge the Soul.

**Wedding Ring removido** → perdeu 1 fonte de draw. Draw caiu de 7 para 6.

**Draw expandido (incluindo topdeck manipulation) = 9-10:** + Top, Scroll Rack, Penance.
Com Wheel (Reforge the Soul) e virtual draw, o deck nao fica sem gas. Mas o minimo do perfil e 8, e o deck tem 6 fontes reais de draw.

**Solucao viavel:** Skullclamp ($5-8). Prioridade #1 de aquisicao.

### GAP #2: Sem Play T3 ~13-14% (DEFENSIVE) — NAO RE-SIMULADO

Mudancas desde a ultima simulacao (Exec#11, pos-C#10):
- OUT: Insurrection (CMC 8), Wedding Ring (CMC 4), Fated Clash (CMC 5)
- IN: Worldfire (CMC 9), Rise of the Eldrazi (CMC 10), Mother of Runes (CMC 1)
- Net DCMC: +3

**Efeito estimado no T3:**
- Mother of Runes (CMC 1) e uma play T1/T2 valida → ajuda T3
- Worldfire/Rise sao irrelevantes para T3 (CMC ≥ 9)
- Wedding Ring (CMC 4) removido → irrelevante para T3
- Fated Clash (CMC 5) removido → irrelevante para T3
- Insurrection (CMC 8) removido → irrelevante para T3
- **T3 estimado: ~13-14% (provavelmente inalterado ou levemente melhor)**

**NECESSARIO RE-SIMULAR com Mulligan Tester.**

### GAP #3: Rise of the Eldrazi (CMC 10, <5% EDHREC) — Candidato a Corte

Rise e a carta mais cara do deck (CMC 10). Competindo com:
- Dance with Calamity (CMC 8, 67% EDHREC) — exila 8, conjura gratis
- Improvisation Capstone (CMC 7, 49% EDHREC) — exila 7, conjura gratis
- Storm Herd (CMC 10, 75.1% EDHREC) — game-ender direto

**Rise of the Eldrazi nao gera valor imediato.** Extra turn e bom, mas a 10 mana, Dance/Improvisation geram mais spells por menos mana. Rise e um "win-more" — se voce tem 10 mana, ja deveria ter ganho com Approach+Flare (7 mana).

**EDHREC <5% em Lorehold** — a comunidade NAO joga esta carta no deck. E um sinal forte de que nao pertence.

**Recomendacao:** Corte para Skullclamp (CMC 1, draw engine) ou fonte de draw CMC 1-2.

### GAP #4: Worldfire (CMC 9, 20.5% EDHREC) — Situacional, Anti-sinergico com Recursao

Worldfire e um game-ender de ultimo recurso:
- **PRO:** Ganha jogos que estao perdidos. Reset global.
- **PRO:** Com dano na stack, e deterministico (9 mana + burn).
- **CONTRA:** Exila SEU cemiterio — anula Mizzix, Bombardment, Surge, Lorehold.
- **CONTRA:** CMC 9 — compete com Storm Herd (CMC 10, gera tokens massivos sem perder recursos).
- **CONTRA:** Se o oponente tiver 1 criatura com haste, voce perde (vida = 1).

**Worldfire e uma "silver bullet" situacional.** Nao e uma carta que voce quer ver em toda mao. E um plano C/D, nao um plano A.

**Recomendacao:** Manter por enquanto (adiciona diversidade de wincon), mas considerar corte futuro para fonte de draw ou fast mana.

### GAP #5: Colecao — Possivel Mudanca

A colecao pode ter mudado desde a ultima verificacao (se o usuario adquiriu cartas para fazer estes swaps). Verificar `user_collection` para novas adicoes.

### GAP #6: 4 Board Wipes (era 5) — Ainda OK

Com Fated Clash removido, o deck tem 4 wipes. A qualidade media dos wipes MELHOROU (Fated era o pior — bounce 1 por oponente, CMC 5). Os 4 restantes sao premium: Blasphemous Act, Austere Command, Call Forth the Tempest, Volcanic Vision.

**Range do perfil: 3-5.** Dentro do range. OK.

### GAP #7: MULLIGAN precisa ser re-executado

A simulacao atual (Exec#11) e de um estado de deck que nao existe mais. O deck tem 3 cartas diferentes. Mulligan deve ser re-executado com N=1000, seed=42.

---

## Secao 7: O PLANO DE JOGO — Turn by Turn (ATUALIZADO com DB REAL)

### T1 (Setup Inicial)
**Objetivo:** Ramp + topdeck setup + protecao
**Cartas ideais:** Sol Ring, Land Tax, Weathered Wayfarer, Sensei's Top, Library of Leng, Gamble, Enlightened Tutor, Esper Sentinel, Dragon's Rage Channeler, **Mother of Runes**

### T2 (Ramp Secundario + Draw/Loot)
**Objetivo:** Fixing + draw/loot + protecao
**Cartas ideais:** Arcane/Boros Signet, Talisman, Faithless Looting, Thrill of Possibility, Scroll Rack, Twinflame, Lightning Greaves, Grand Abolisher, Hexing Squelcher

### T3 (Protecao + Engine Setup)
**Objetivo:** Estabelecer protecao + preparar Lorehold
**Cartas ideais:** Greaves, Grand Abolisher, Hexing Squelcher, Smothering Tithe, Archaeomancer's Map, Jeska's Will, Monument to Endurance, Flare de Duplication, **Mother of Runes ativa protecao**

### T4 (Lorehold + Valor)
**Objetivo:** Conjurar Lorehold + gerar valor imediato
**Cartas ideais:** Lorehold, Big Score, Unexpected Windfall, The One Ring, Storm-Kiln Artist, Akroma's Will (defensivo)

### T5 (Motor Arrancado)
**Objetivo:** Copy engines + free spells
**Cartas ideais:** Double Vision, Arcane Bombardment, Dance with Calamity, Improvisation Capstone, The Dawning Archaic

### T6+ (Fechar o Jogo)
**Objetivo:** Wincon — 5+ paths deterministicos
**Cartas ideais:**
- Plano A: Approach + Flare (7 mana + criatura = vitoria NO MESMO TURNO)
- Plano B: Approach + Top/Scroll Rack (deterministico, 2 turnos)
- Plano C: Storm Herd + Akroma's Will/Boros Charm
- Plano D: Mizzix's Mastery overload
- Plano E: Surge + Approach + Twinflame
- **Plano F: Worldfire + dano na stack (NOVO)**
- **Plano G: Rise of the Eldrazi extra turn + copy chain**

---

## Secao 8: ESTRATEGIA PARA PROXIMO CICLO

### Situacao Atual (DB REAL)

| Indicador | Valor | Interpretacao |
|:----------|:-----:|:--------------|
| T3 | ~13-14% (estimado) | DEFENSIVE (>12%) |
| Nivel 1 | 1-2 candidatos (Rise, Worldfire) | Nao esta mais VAZIO |
| Draw | 6 | **2 abaixo do perfil** |
| Colecao | Desconhecida | Pode ter novas adicoes |
| Candidatos CMC ≤ 2 | Verificar | User pode ter adquirido cartas |

### ⚠️ ALERTA: Diversas Premissas do Pipeline Quebraram

1. **EVOLUTION_LOG e VALIDATOR_LOG descrevem um deck que nao existe mais.** Qualquer agente que ler estas analises sem verificar o DB tomara decisoes baseadas em dados incorretos.

2. **MULLIGAN_LOG esta stale.** A simulacao Exec#11 e de um estado de deck com Insurrection/Wedding/Fated.

3. **BATTLE_LOG pode estar stale.** Depende se as simulacoes usam o deck real ou o cache.

4. **O pipeline precisa de um "sanity check" no inicio de cada agente:** `SELECT COUNT(*), SUM(quantity) FROM deck_cards WHERE deck_id=6` + hash do estado para detectar divergencias.

### Recomendacoes Imediatas

1. **RE-SIMULAR MULLIGAN** — O estado do deck mudou. Executar com N=1000, seed=42, definicao rigorosa.

2. **RE-VERIFICAR COLECAO** — `user_collection` pode ter novas cartas (as que entraram no deck).

3. **AVALIAR Rise of the Eldrazi** — Principal candidato a corte. CMC 10, <5% EDHREC, compete com Dance/Improvisation.

4. **AVALIAR Worldfire** — Situacional, anti-sinergico com recursao. Mas e wincon alternativa.

5. **PRIORIDADE #1: Resolver GAP de Draw.** 6 fontes e 2 abaixo do perfil. Skullclamp (aquisicao, $5-8) resolveria.

### Projecao de Swaps (Cenario COM aquisicao de Skullclamp)

| Swap | DCMC | Justificativa |
|:-----|:----:|:--------------|
| Rise of the Eldrazi (CMC 10) → Skullclamp (CMC 1) | **-9** | Resolve draw (6→7) + reduz T3 dramaticamente. Rise e a carta mais cara e de menor impacto. |
| Worldfire (CMC 9) → Fonte de draw CMC 1-2 | **-7 a -8** | Opcional. Se houver segunda fonte de draw na colecao. |

**T3 projetado pos-swap:** ~13-14% → **~8-10%** (BALANCED). Ganho massivo de early-game.

### Projecao (Cenario SEM aquisicao)

**0 swaps.** Rise of the Eldrazi e Worldfire sao mantidos. Draw permanece em 6. T3 ~13-14%.

---

## Secao 9: RESUMO EXECUTIVO

### Estado do Deck: BOM (com gaps novos introduzidos pelas mudancas)

| Indicador | Status |
|:----------|:------:|
| Motor | 4/4 COMPLETO |
| Copy Engines | 7 ativas (inclui Rise extra turn) |
| Token+Pump | 8/10 |
| **Wipes+Protection** | **9/10 (MELHOROU +1 vs v3.12)** |
| Recursion | 8/10 |
| Mana Explosiva | 7/10 |
| Combo Pieces | **9/10 (5 paths, +1 Worldfire)** |
| Stack Interaction | 7/10 |
| **Graveyard Resilience** | **7/10 (MELHOROU +1 vs v3.12)** |
| **Sem Play T3** | **~13-14% (NAO RE-SIMULADO)** |
| **Draw Real** | **6 (PIOROU -1 vs v3.12)** |
| Double-nulls restantes | 4 (0 cortaveis) |
| Nivel 1 | **1-2 candidatos (Rise, Worldfire)** |
| Board Wipes | **4 (PIOROU -1 vs v3.12, mas qualidade subiu)** |

### Top 3 GAPS (ATUALIZADO)

1. **Draw Real = 6 (vs 8-12 perfil) — CRITICO.** Wedding Ring removido. 2 fontes abaixo do minimo. Skullclamp e a solucao ($5-8, aquisicao).

2. **Rise of the Eldrazi (CMC 10) — Candidato a corte.** <5% EDHREC, compete com Dance/Improvisation que geram MAIS valor por MENOS mana. Principal Nivel 1 do deck.

3. **MULLIGAN precisa ser re-executado.** Deck state divergiu do que as simulacoes cobrem. Executar com N=1000, seed=42.

### Destaques do v3.14

1. **🔴 DISCREPANCIA CRITICA DESCOBERTA.** EVOLUTION_LOG e VALIDATOR_LOG v3.12 descrevem um deck com Insurrection, Wedding Ring, Fated Clash — mas o DB tem Worldfire, Rise of the Eldrazi, Mother of Runes. **3 cartas diferentes.** O pipeline de agentes estava operando com dados stale.

2. **Mother of Runes (CMC 1) e EXCELENTE.** A melhor das 3 adicoes. Protege Lorehold por 1 mana. Melhora early-game. Sinergia com Flare (pode ser sacrificada).

3. **Worldfire (CMC 9) e SITUACIONAL.** Adiciona quinto path deterministico de vitoria (com dano na stack). Mas exila seu cemiterio — anti-sinergico com Mizzix/Bombardment.

4. **Rise of the Eldrazi (CMC 10) e QUESTIONAVEL.** CMC mais alto do deck, <5% EDHREC. Competindo com Dance (CMC 8, 67%), Improvisation (CMC 7, 49%). Principal candidato a corte.

5. **Draw PIOROU (7→6).** Wedding Ring removido. Gap de draw agora e 2 cartas abaixo do perfil.

6. **Protection MELHOROU (5→6).** Mother of Runes CMC 1 + Fated Clash removido. Ratio wipes/protecao: 0.8:1 (excelente).

7. **Sistema de deteccao de divergencia necessario.** Nenhum agente detectou que o deck mudou. Pipeline precisa de sanity check no inicio de cada execucao.

### Mudancas Documentadas desde baseline (28 swaps em 10+ ciclos com swaps)

| Ciclo | Swaps | Net DCMC | Estrategia | T3 Aprox |
|:-----:|:-----:|:--------:|:----------|:---------|
| #1-#10 | 25 | — | Misto | 13.3% (Exec#11) |
| #11-#16 | 0 (Evolution Oracle) | 0 | (0 swaps) | — |
| **Nao documentado** | **3** | **+3** | **Desconhecida** | **~13-14% (estimado)** |

**Total: 28 swaps desde baseline.** 25 via Evolution Oracle + 3 nao documentados.

---

*Relatorio gerado por Purpose Analyzer v3.14 em 2026-06-01T02:10:00+00:00*
*Analista: Hermes Agent — Agente 2 (Lorehold Purpose Analyzer)*
*Fonte: knowledge.db deck_id=6 — ESTADO REAL (nao EVOLUTION_LOG)*
*Proximo passo: Re-simular MULLIGAN com deck atual. Verificar user_collection. Avaliar Rise of the Eldrazi como candidato a corte. Prioridade #1: resolver GAP de draw (Skullclamp).*
