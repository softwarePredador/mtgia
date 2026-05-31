# Purpose Analyzer v3.9 — Lorehold Spellslinger: SYNERGY_MAP + Stack & Resilience

> **Data:** 2026-05-31T17:40:09Z
> **Fonte:** knowledge.db deck_id=6 (pos-Ciclo #9, 23 swaps aplicados)
> **Deck:** Lorehold Spellslinger — 100 cards, 86 rows, 35 lands
> **Analista:** Hermes Agent — Purpose Analyzer v3.9
> **Foco:** Classificacao estrategica completa + SYNERGY_MAP (7 eixos: A-G) + CORRECAO T3

---

## Secao 0: CORRECAO CRITICA — T3 Real vs T3 Reportado

### ⚠️ O "3.7% Sem Play T3" do v3.8 e do Evolution Oracle esta ERRADO.

| Fonte | T3 Reportado | Real (Execucao #10, N=1000, seed=42) | Erro |
|:------|:------------:|:-------------------------------------:|:----:|
| v3.8 Purpose Analyzer | 3.7% | **16.9%** | Free mulligan rate (0+7 lands), nao Sem Play T3 |
| Evolution Oracle Ciclos #7/#8/#9 | 3.7% | **~13-16%** | Usou T3 incorreto para escolher AGGRESSIVE |

**O valor 3.7% coincide EXATAMENTE com taxa de maos com 0 ou 7 lands (free mulligan).**
A definicao CORRETA de Sem Play T3 e: "nenhum nonland card com CMC <= min(lands, 3)".
Execucao #10 nao conseguiu reproduzir 3.7% com a definicao correta.

**Consequencia:** O Evolution Oracle escolheu AGGRESSIVE para Ciclos #7, #8, #9 com base
em T3=3.7%. O T3 real estava ~13-14% (pos-C#6), zona DEFENSIVE/BALANCED.
O net ΔCMC +4 aplicado nos ultimos 3 ciclos (+2+0+2) elevou T3 para 16.9%.

### 🔴 STATUS ATUAL: Sem Play T3 = 16.9% → DEFENSIVO obrigatorio para Ciclo #10.

---

## Secao 1: Visao Geral do Deck

### Metricas Recalculadas (pos-Ciclo #9)

| Metrica | Deck Real | Perfil EDHREC | Status |
|:--------|:---------:|:--------------|:-------|
| Lands | 35 | 36-38 | OK (-1, MDFCs compensam) |
| Ramp | 14 | 10-13 | +1 (treasure-heavy) |
| Draw (real) | 7 | 8-12 | -1 (estrutural Boros) |
| Removal | 6 | 4-6 | No range |
| Board Wipe | 5 | 3-5 | No limite |
| Protection | 3 | 3-4 | OK (mais anti-stack: Swat, Abolisher, Squelcher) |
| Recursion | 4 | 2-5 | No range |
| Wincon (dedicado) | 2 | 4-7 | +1 (Akroma's Will) — mas so 2 taggeados |
| Engine/Big Spell | 5 | 5-8 | Motor 4/4 + Copy 3/3 |
| Tutor | 2 | -- | Enlightened + Gamble |
| CMC medio | 3.86 | ~4.1 | OK |

### Deck Health (pos-Ciclo #9)

| Indicador | Valor | Interpretacao |
|:----------|:-----:|:--------------|
| Motor | 4/4 COMPLETO | Treasure → Free Big Spell → Copy → Payoff |
| Copy Engines | 3/3 COMPLETO | Double Vision + Arcane Bombardment + Lorehold |
| **Sem Play T3** | **16.9%** | **🔴 DEFENSIVE (>12%). Acima do limite em 4.9pp.** |
| Mulligan Rate | 49.3% | Estrutural (35 lands, 3 T1 ramp estrito) |
| Jogaveis | 46.3% | Boros com 35 lands |
| Ramp T1 (estrito) | 20.1% | Sol Ring + Land Tax + Wayfarer |
| Draw Real | 7 fontes | A 1 fonte do minimo do perfil |
| Protection (DB tag) | 3 | Mas Stack Interaction amplia (ver Eixo F) |

---

## Secao 2: CLASSIFICACAO ESTRATEGICA — TODAS as Cartas

Cada carta classificada por **Importancia Estrategica (1-5)** e **Funcao Real**
(corrigindo functional_tags incorretas do banco).

### Nivel 5: NAO SE JOGA SEM (Core Identity)

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 5 |
|:------|:---:|:------:|:------------|:------------------|
| **Lorehold, the Historian** | 5 | -- | commander, engine, copy | Copia instants/sorceries do grave + desconto de 1. Define o deck. |
| **Approach of the Second Sun** | 7 | 63.8% | wincon | Wincon primaria. Com topdeck manipulation, deterministico. Copiavel pelo Lorehold. |
| **Mizzix's Mastery** | 4 | 57.5% | recursion, wincon | Overload = conjura TODOS instants/sorceries do grave gratis. Com Double Vision + Bombardment, fecha jogos. |

### Nivel 4: CORE DA ESTRATEGIA (Define o plano de jogo)

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 4 |
|:------|:---:|:------:|:------------|:------------------|
| **Dance with Calamity** | 8 | 67.0% | engine, free_spell | Exila top 8, conjura spells gratis. Motor componente #2. |
| **Double Vision** | 5 | 46.6% | engine, copy | Primeira spell por turno copiada. Copy layer #1. |
| **Arcane Bombardment** | 5 | 42.5% | engine, copy, recursion | Exila e copia 1a spell a cada turno. Copy layer #2 + recursion passiva. |
| **Smothering Tithe** | 4 | 45.9% | ramp, treasure | 3+ treasures por turno em 4-player. Alimenta TODO o motor. |
| **Storm-Kiln Artist** | 4 | 55.4% | ramp, treasure, payoff | Cada spell cast/copiada = Treasure. Com Lorehold + Double Vision, 3-5 treasures/turno. |
| **Improvisation Capstone** | 7 | 49.0% | engine, free_spell | Exila top 7, conjura gratis. Rising star (+8.09). Motor componente #2. |
| **Scroll Rack** | 2 | 59.7% | topdeck, draw_virtual | Reordena topo, ativa Lorehold count. Double-null do classificador. Core engine. |
| **Penance** | 3 | 41.8% | topdeck, protection | Setup de topdeck + anti-removal. Miracle enabler. Double-null. Core engine. |

### Nivel 3: SUPORTE FORTE (Sinergia consistente, deck piora sem)

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 3 |
|:------|:---:|:------:|:------------|:------------------|
| **Sensei's Divining Top** | 1 | 66.9% | topdeck, draw | Manipula topo, ativa Lorehold. Com Approach = "conjura Approach, responde com Top, ganha". |
| **Akroma's Will** | 4 | ~20% | wincon, pump, protection | **NOVO Ciclo #9.** Flying + double strike + vigilance + lifelink + prot all colors + indestructible. Transforma QUALQUER token board em lethal. |
| **Insurrection** | 8 | 59.7% | wincon, theft | Rouba TODAS as criaturas, da haste. Game-ender autonomo. |
| **Surge to Victory** | 6 | 26.1% | wincon, recursion, pump | Copia spell com criaturas atacando. Com Approach no grave = ganha na hora. |
| **Boros Charm** | 2 | 52.8% | pump, protection | Double strike (pump) OU indestrutivel (protection). Versatil. Tag do DB "removal" esta ERRADO. |
| **The One Ring** | 4 | 56.1% | draw, protection | Draw massivo + fog. Game Changer. |
| **Teferi's Protection** | 3 | 52.4% | protection | Faseia tudo. Resposta a TUDO. Protecao definitiva. |
| **Jeska's Will** | 3 | 54.7% | ramp, ritual | Mana explosiva. 7+ mana em um turno. |
| **Chaos Warp** | 3 | 38.8% | removal | Remocao universal — shuffle (nao destroy/exile). Unica que lida com Theros gods, Darksteel, etc. |
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
| **Galvanoth** | 5 | 26.5% | engine, free_spell | Upkeep: revela e conjura spell gratis do topo. |
| **Rite of the Dragoncaller** | 6 | 40.4% | token, payoff | 5/5 Dragon a cada spell. |
| **Storm Herd** | 10 | 75.1% | token, wincon | X Pegasus = PVs. Game-ender. |
| **Archaeomancer's Map** | 3 | 29.3% | ramp | Land ramp condicional. |
| **Land Tax** | 1 | 55.7% | ramp | 3 lands/turno. Ramp consistente. |
| **Weathered Wayfarer** | 1 | 39.3% | ramp, tutor | Busca ANY land. |
| **Sol Ring** | 1 | 84.3% | ramp | Staple. Melhor rock do formato. |
| **Boros Signet** | 2 | 50.4% | ramp | Signet estavel. |
| **Arcane Signet** | 2 | 80.2% | ramp | Staple. |
| **Talisman of Conviction** | 2 | 62.1% | ramp | Ramp com dano opcional. |
| **Monument to Endurance** | 3 | 41.3% | engine, draw | Draw + loot + drain. Multi-funcao. Tag do DB "ramp" esta ERRADO. |
| **Library of Leng** | 1 | 77.8% | hand, graveyard | Sem limite de mao + descarte no topo. |
| **Valakut Awakening** | 3 | 35.7% | draw, hand_reset | MDFC. Hand reset + draw. |
| **Emeria's Call** | 7 | 43.4% | token, land | MDFC. Flexibilidade. |
| **Longshot, Rebel Bowman** | 4 | 27.3% | payoff | Bolt sempre que Lorehold ataca/bloqueia. |
| **Bender's Waterskin** | 3 | 22.8% | ramp | Rock ou tutora land. |
| **Fated Clash** | 5 | 15.6% | board_wipe | Bounce 1 por oponente + scry. |
| **Olorin's Searing Light** | 4 | 49.6% | removal, graveyard | Exila permanente + instant/sorcery do grave. |
| **Victory Chimes** | 3 | 53.6% | draw, engine | Untap a cada turno + draw. Multiplayer value. |
| **Wedding Ring** | 4 | ~25% | draw, ramp | Draw + lifegain. Boros precisa. |
| **The Dawning Archaic** | 3 | 24.0% | engine, copy, free_spell | Copia spells dos oponentes. Rising star (+5.31, 5+ ciclos). |
| **Restoration Seminar** | 7 | 37.8% | recursion, token | Retorna spell + cria Lesson. Rising star (+9.14). |

### Nivel 2: UTILIDADE SITUACIONAL

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 2 |
|:------|:---:|:------:|:------------|:------------------|
| **Deflecting Swat** | 3 | 42.0% | protection, stack | Redireciona spell/ability. Stack interaction crucial. Tag "big_spell" do DB ERRADO. |
| **Lightning Greaves** | 2 | 73.3% | protection | Shroud + haste. Protege Lorehold. |
| **Grand Abolisher** | 2 | 11.7% | protection, stack | Oponentes nao conjuram no seu turno. Double-null. Trend -0.27 (declinio). |
| **Hexing Squelcher** | 2 | ~10% | protection, stack | Oponentes nao ativam habilidades. Anti-combo. |
| **Taunt from the Rampart** | 5 | 35.2% | goad, control | Goad em todas as criaturas. Situacional mas util em multiplayer. Double-null. |

### Nivel 1: SUBSTITUIVEL (Candidato natural a corte)

| Carta | CMC | EDHREC | Funcao Real | Por que e Nivel 1 |
|:------|:---:|:------:|:------------|:------------------|
| **Ruby Medallion** | 2 | 42.3% | ramp, cost_reduction | Double-null. Desconto de 1 em ~40 spells vermelhos. Treasure supera cost reduction (ver Analise v3.7). Trend -0.37 (3+ ciclos em declinio). Pearl Medallion ja foi cortado (Ciclo #9). Ruby e o proximo. |

> **Nota:** Pearl Medallion foi cortado no Ciclo #9 (→ Akroma's Will). Ruby Medallion permanece
> como ultimo double-null com trend negativo persistente. Mas colecao esgotada de CMC 1-2.

### Lands — Classificacao

| Carta | Funcao Real | Nota |
|:------|:------------|:-----|
| Ancient Tomb | ramp | Sol land. Acelera T2 Lorehold. |
| Arid Mesa, Bloodstained Mire, Flooded Strand, Scalding Tarn, Windswept Heath | fetch, topdeck | 5 fetches. Alimentam Scroll Rack + Sensei's Top + Land Tax. |
| Boseiju, Who Shelters All | protection, removal | Channel — destroi artefato/encantamento nao-counteravel. |
| Cavern of Souls | protection | Lorehold nao-counteravel. |
| Clifftop Retreat, Inspiring Vantage, Sundown Pass | fixing | Boros fixing. |
| Command Tower, Exotic Orchard, Sacred Foundry, Dormant Volcano | fixing, ramp | Color fixing + Dormant Volcano = Sol land lenta. |
| Kor Haven | protection | Fog por criatura atacante. |
| Urza's Saga | tutor, token, ramp | Busca Sol Ring, Top, Library of Leng. Fabricate + Constructs. |
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

#### TOKEN MAKERS (tesouros — usados como mana)

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
| **Akroma's Will** | 4 | **Flying + double strike + vigilance + lifelink + prot all colors + indestructible** | **Transforma qualquer board em lethal** |
| Surge to Victory | 6 | Copia spell, criaturas dao dano = copia | Cada criatura = 1 copia |
| Insurrection | 8 | Rouba TODAS as criaturas, haste | Board dos oponentes |

#### PARES TOKEN + PUMP — Calculo de Dano (ATUALIZADO com Akroma's Will)

**Rite of the Dragoncaller + Boros Charm:**
- Estado tipico (T6+): 3 dragons 5/5 no campo
- Boros Charm double strike: 3 x (5 x 2) = 30 flying damage
- **Conclusao: Mata 1-2 jogadores.**

**Rite + Akroma's Will:**
- 3 dragons 5/5 → Akroma's Will: flying, double strike, vigilance, lifelink, prot all colors, INDESTRUCTIBLE
- Dano: 3 x (5 x 2) = 30 flying damage. Ganha 30 de vida. Criaturas sobrevivem ate a board wipes.
- **Conclusao: Mata 1 jogador + estabiliza vida + protege board para proximo turno.**

**Storm Herd + Boros Charm:**
- Com 40 PVs: 40 Pegasus 1/1 flying
- Boros Charm double strike: 40 x 2 = 80 flying damage
- **Conclusao: Mata a mesa INTEIRA.**

**Storm Herd + Akroma's Will:**
- 40 Pegasus 1/1 flying + Akroma's Will: double strike, prot all colors, indestructible
- Dano: 40 x 2 = 80 flying damage. Ganha 80 de vida. INDESTRUCTIVEL — nao morrem pra nada.
- **Conclusao: OVERKILL. Mata a mesa + sobrevive a qualquer resposta.**

**Rite + Surge to Victory:**
- Exila Approach com Surge. 3 dragons atacam → 3 copias de Approach.
- Approach + 3 copias = ganha na hora (2a copia ja resolve).
- **Conclusao: Ganha na HORA.**

**Akroma's Will + QUALQUER token board:**
- Mesmo com apenas 3-5 criaturas (Constructs do Urza's Saga, Dragons do Rite, Pegasus do Storm Herd), Akroma's Will transforma o board em letal.
- Flying → unblockable na maioria das mesas
- Prot all colors → nao podem ser bloqueadas
- Double strike → dano dobrado
- Indestructible → nao morrem em combate nem pra remocao
- **Conclusao: Akroma's Will e um game-ender com QUALQUER board de 3+ criaturas.**

#### ANALISE DO PLANO TOKEN+PUMP (atualizado pos-C#9)

| Forca | Fraqueza |
|:------|:---------|
| 2 pumps reais agora: Boros Charm + Akroma's Will ✅ | Akroma's Will CMC 4 — requer 4+ mana turno do ataque |
| Akroma's Will tambem e protecao (indestructible + prot all colors) | Rite of the Dragoncaller ainda lento (1 dragon/cast) |
| Storm Herd + Akroma's Will = overkill garantido | Storm Herd CMC 10 — precisa de muito mana |
| Insurrection e game-ender autonomo | Surge depende de Approach no grave para ser deterministico |
| Surge + Approach = ganha na hora (nao precisa de combate) | |

**Nota: 8/10. (ERA 6/10 no v3.8).** A adicao de Akroma's Will (Ciclo #9) fechou o gap
de "so 1 pump". Agora o deck tem 2 pumps reais + Insurrection como plano autonomo +
Surge to Victory como recursion/pump. O plano token+pump e CONSISTENTE e LETAL.

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
| **Akroma's Will** | 4 | **Indestrutivel + prot all colors** | **Wipes, remocao, combate — versatil** |

#### PARES WIPE + PROTECAO

**Austere Command + Teferi's Protection:** Custo 10 mana. Resultado: wipe unilateral.
**Blasphemous Act + Boros Charm:** Custo 3 mana total. Wipe unilateral mais barato do jogo.
**Volcanic Vision + Teferi's:** Wipe + retorna Mizzix's Mastery. Proximo turno: overload → ganha.
**Call Forth + Boros Charm:** Cascade pode revelar Approach. Fecha jogos.

#### RATIO WIPES / PROTECAO

| Contagem | Valor |
|:---------|:-----:|
| Board Wipes | 5 |
| Wipes que PRECISAM de protecao | 2 (Blasphemous Act, Fated Clash) |
| Protecoes anti-wipe | 4 (Boros Charm, Teferi's, Akroma's Will, Lightning Greaves parcial) |
| Wipes assimetricos (nao precisam de protecao) | 3 (Austere, Call Forth, Volcanic Vision) |

**RATIO REAL: 2 wipes perigosos / 4 protecoes = 2.0 protecoes por wipe.**
**CONCLUSÃO: 8/10. Mantido.** O deck tem protecao de sobra para seus wipes.
Akroma's Will adicionou +1 protecao multifuncional.

---

### C) RECURSION CHAINS — Como o deck reusa o cemiterio?

| Carta | CMC | O que faz | Copiavel? | Cadeia |
|:------|:---:|:----------|:----------|:-------|
| Mizzix's Mastery | 4 (overload 8) | Todos instants/sorceries do grave gratis | SIM | Faithless Looting → Mizzix's overload → tudo de volta |
| Arcane Bombardment | 5 | Exila e copia 1a spell/turno | SIM | Bombardment exila Faithless → copia a cada turno |
| Restoration Seminar | 7 | Retorna spell do grave + cria Lesson token | SIM | Seminar traz de volta qualquer spell |
| Surge to Victory | 6 | Exila spell, criaturas dao dano = copia | SIM | Surge + Approach no grave = ganha |
| Faithless Looting | 1 | Flashback — loota, preenche grave | SIM | Alimenta Mizzix's + Bombardment |
| Lorehold (commander) | 5 | Copia spell do grave com desconto | -- | Commander define o deck |

#### CADEIAS DOCUMENTADAS

**Cadeia 1 — Faithless → Mizzix's Overload:**
Turno 1-3: Faithless Looting + Thrill + Big Score → enche o grave com 5-12 spells.
Turno 5+: Mizzix's Mastery overload → TODAS de volta, conjuradas gratis.
Com Double Vision: copia Mizzix's → 2x overload → cada spell copiada tambem.
**Resultado: 10-20 spells gratis em um turno. Game over.**

**Cadeia 2 — Bombardment + Faithless Loop:**
Arcane Bombardment exila Faithless Looting. Todo turno: copia Faithless → draw 2, discard 2.
Com Lorehold: copia de Faithless → 2 draws + 2 discards + preenche grave para novas cartas.
**Resultado: Engine de draw passiva que se auto-alimenta.**

**Cadeia 3 — Bombardment + Restoration Seminar Loop:**
Bombardment exila Restoration Seminar. Todo turno: Seminar copiada → retorna spell + Lesson.
Se a spell retornada e instant/sorcery, pode ser copiada pelo Lorehold.
**Resultado: 1 spell gratis + token + spell copiada por turno.**

**Cadeia 4 — Surge + Approach:**
Surge to Victory exila Approach. 3+ criaturas atacam → 3+ copias de Approach.
2a copia de Approach resolve → ganha o jogo.
**Resultado: Ganha na hora. Nao precisa de combate.**

**Nota: 8/10. Mantido.**
4 cadeias de recursao documentadas. 2 delas (Surge+Approach, Mizzix's overload) sao deterministas.
As outras (Bombardment loops) geram valor passivo.

---

### D) MANA EXPLOSIVA — Como o deck gera mana explosiva?

#### GERADORES DE TESOURO

| Carta | CMC | Mana Gerada | Condicao |
|:------|:---:|:-----------:|:---------|
| Smothering Tithe | 4 | 3+/turno | Passivo (cada oponente compra) |
| Storm-Kiln Artist | 4 | 1/cast ou copia | Com Lorehold + Double Vision: 3-5/turno |
| Brass's Bounty | 7 | 7-10 treasures | Uma vez (lands em jogo) |
| Hit the Mother Lode | 7 | 7 treasures | Uma vez (fixo) |
| Big Score | 4 | 2 treasures | Instant |
| Unexpected Windfall | 4 | 2 treasures | Instant |

#### RITUAIS ONE-SHOT

| Carta | CMC | Mana Gerada |
|:------|:---:|:-----------:|
| Jeska's Will | 3 | 7+ (tipico em commander) |
| Sol Ring | 1 | +2 mana / turno |

#### COST REDUCTION (alternativa a treasure)

| Carta | CMC | Efeito |
|:------|:---:|:-------|
| Ruby Medallion | 2 | -1 em ~40 spells vermelhos |
| Lorehold | 5 | -1 na spell copiada |

#### DESTINO DA MANA EXPLOSIVA

| Destino | Custo | O que faz |
|:--------|:-----:|:----------|
| Mizzix's Mastery overload | 8 | Ganha o jogo |
| Storm Herd | 10 | 20-40 tokens flying |
| Call Forth the Tempest X=5 | 8+ | Dano massivo + cascade |
| Dance with Calamity X=8 | 8 | 8 cartas gratis |
| Improvisation Capstone | 7 | 7 cartas, 1 gratis |
| Approach of the Second Sun | 7 | 1a conjuracao |
| Brass's Bounty | 7 | Gera ainda MAIS mana |

**SEQUENCIA IDEAL DE MANA (T1-T6):**
```
T1: Land → Sol Ring → Signet (3 mana T2)
T2: Land → Smothering Tithe (3 treasures/turno)
T3: Land → Jeska's Will → 7+ mana → Double Vision
T4: Land → Storm-Kiln → Big Score (copiada) → 4 treasures + draw
T5: Land → Brass's Bounty → 10+ treasures
T6: Mizzix's Mastery overload OU Storm Herd X=40 → GANHA
```

**Nota: 7/10. Mantido.**
A geracao de mana e excelente para um deck Boros. O problema nao e gerar mana —
e ter cartas de CMC 1-2 para sobreviver ate gerar mana. T3=16.9% mostra que
o deck as vezes nao chega ao T4+ com vida suficiente.

---

### E) COMBO PIECES — Existe combo deterministico?

#### COMBOS DETERMINISTICOS (ganham na hora)

| Combo | Pecas | Custo | Confiabilidade |
|:------|:------|:-----:|:--------------:|
| **Approach + Topdeck** | Approach of the Second Sun + Sensei's Divining Top (ou Scroll Rack) | 8 mana total (7+1) | **9/10** — Conjura Approach, responde com Top: draw Approach, coloca no topo. Proximo turno: conjura de novo = ganha. |
| **Surge + Approach** | Surge to Victory + Approach no grave + 3+ criaturas | 6 mana Surge | **8/10** — 3+ copias de Approach. 2a resolve → ganha. |

#### COMBOS SEMI-DETERMINISTICOS (alta chance de ganhar)

| Combo | Pecas | Confiabilidade |
|:------|:------|:--------------:|
| **Mizzix's Overload + Double Vision** | Mizzix's Mastery + Double Vision em jogo + 5+ spells no grave | **9/10** — Overload copiado = 10+ spells gratis. |
| **Storm-Kiln + Double Vision** | Storm-Kiln + Double Vision + qualquer spell | **7/10** — Cada spell cast + copiada = 2 treasures. Ciclo infinito de mana com spells baratas. |
| **Bombardment + Seminar Loop** | Arcane Bombardment + Restoration Seminar + grave populado | **7/10** — 1 spell gratis + Lesson token por turno. Valor acumulativo. |

#### COMBOS FRAGEIS (dependem de topo/manutencao)

| Combo | Pecas | Confiabilidade |
|:------|:------|:--------------:|
| **Galvanoth + Top** | Galvanoth + Sensei's Top/Scroll Rack | **5/10** — Setup de topo para conjurar gratis na upkeep. Lento, morre pra remocao. |
| **Dance + Capstone** | Dance with Calamity (X=8) + Improvisation Capstone | **6/10** — 15 cartas exiladas, 8-10 spells gratis. Mas requer 15 mana total. |

#### QUASE-COMBOS (falta 1 peca)

| Combo Potencial | Temos | Falta | Impacto de Adicionar |
|:----------------|:------|:------|:---------------------|
| Underworld Breach + Brain Freeze | 0/2 | Ambos | NA — fora do plano do deck |
| Dualcaster Mage + Twinflame | 0/2 | Ambos | NA — combo dedicado, nao spellslinger |
| Kiki-Jiki + Restoration Angel | 0/2 | Ambos | NA — criatura combo |
| **Past in Flames** | Nao temos | Past in Flames (CMC 4) | **MEDIO** — Mizzix's ja faz isso. Redundancia seria bom mas nao essencial. |

**Nota: 8/10. Mantido.**
2 combos deterministicos que ganham na hora. O deck nao e combo-first, mas TEM combos.
Approach + Topdeck e o mais confiavel. Surge + Approach e o plano B recursivo.

---

### F) STACK INTERACTION — Como o deck interage na stack? 🆕

#### COUNTERSPELLS

**NENHUM.** O deck e Boros — nao tem counterspells. Isso e estrutural e esperado.

#### PROTECAO NA STACK

| Carta | CMC | O que faz | Responde a counterspell? | Responde a remocao? |
|:------|:---:|:----------|:------------------------:|:-------------------:|
| **Deflecting Swat** | 3 | Redireciona spell/ability alvo unico | ✅ SIM — redireciona o counterspell para Swat (fizzle) | ✅ SIM |
| **Teferi's Protection** | 3 | Faseia voce + permanentes | ✅ SIM — faseia em resposta, Approach nao e counterado (ja resolveu) | ✅ SIM |
| **Boros Charm** | 2 | Indestrutivel | ❌ Nao protege spells | ✅ SIM (criaturas) |
| **Grand Abolisher** | 2 | Oponentes nao conjuram no seu turno | ✅ SIM — preemptivo. Se em jogo, ninguem countera nada seu. | ✅ SIM |
| **Cavern of Souls** | 0 | Nomeia Dragon → Lorehold nao-counteravel | ✅ SIM — mas so para Lorehold | ❌ |

#### INSTANT-SPEED REMOCAO (responde a ameacas na stack)

| Carta | CMC | Alvo |
|:------|:---:|:-----|
| Path to Exile | 1 | Criatura |
| Swords to Plowshares | 1 | Criatura |
| Abrade | 2 | Criatura OU artefato |
| Chaos Warp | 3 | QUALQUER permanente |
| Generous Gift | 3 | QUALQUER permanente |
| Olorin's Searing Light | 4 | QUALQUER permanente (exila) |

#### COMO O DECK SOBREVIVE A UM COUNTERSPELL NO APPROACH?

**Cenario:** Voce conjura Approach of the Second Sun. Oponente responde com Counterspell.

| Resposta | Funciona? | Custo |
|:---------|:---------:|:-----:|
| Deflecting Swat → redireciona counterspell para Swat | ✅ SIM | 3 mana |
| Teferi's Protection em resposta → Approach ja esta na stack | ❌ NAO | Approach ainda e counterado |
| Grand Abolisher ja em jogo → counterspell nao pode ser conjurado | ✅ SIM | Preemptivo |
| Boros Charm → protege Approach? | ❌ NAO | So protege permanentes |
| Re-conjurar Approach do grave com Mizzix's Mastery | ✅ SIM | Overload 8 mana |
| Re-conjurar Approach com Restoration Seminar | ✅ SIM | 7 mana |
| Conjurar Approach com Arcane Bombardment (se exilada) | ✅ SIM | Copia gratis a cada turno |

**Conclusao: 6 respostas viaveis a um counterspell no Approach.**
Deflecting Swat e a resposta direta (3 mana). Grand Abolisher e a preemptiva.
Mizzix's, Seminar, e Bombardment sao os planos B/C de recursao.
**O deck NAO e vulneravel a um counterspell sozinho.**

#### COMO O DECK INTERAGE COM COMBOS DOS OPONENTES?

| Ameaca | Resposta | Confiabilidade |
|:-------|:---------|:--------------|
| Combo de habilidade ativada (Thrasios, Kinnan) | Hexing Squelcher | 7/10 — preemptivo |
| Combo de spell (Storm, Ad Nauseam) | Grand Abolisher (preemptivo) + Deflecting Swat | 5/10 — precisa estar em jogo/mao |
| Combo de ETB (Dockside, Dualcaster) | Path, Swords, Abrade, Chaos Warp, Generous Gift, Olorin's | 7/10 — instant-speed |
| Combo de encantamento/artefato | Boseiju, Chaos Warp, Generous Gift, Abrade | 8/10 — varias respostas |

**Stack Interaction Score: 6/10.**
Limitado por ser Boros (sem counterspells), mas compensa com Deflecting Swat,
Grand Abolisher, Hexing Squelcher, e 6 remocoes instantaneas.
Contra combo T2-T3 deterministico (cEDH), o deck e muito lento.
Contra combo T5+ (bracket 3), as respostas sao adequadas.

---

### G) GRAVEYARD HATE & RESILIENCE — Como o deck sobrevive a hate? 🆕

#### DEPENDENCIA DO CEMITERIO

O deck depende MODERADAMENTE do cemiterio. Avaliacao por carta:

| Carta | Dependencia | Se exilarem o grave, perde funcionalidade? |
|:------|:-----------:|:-------------------------------------------|
| Mizzix's Mastery | **ALTA** | ❌ SIM — totalmente inutilizada sem grave |
| Arcane Bombardment | **ALTA** | ❌ SIM — se exilarem as cartas exiladas por Bombardment |
| Surge to Victory | **ALTA** | ❌ SIM — precisa de Approach no grave |
| Lorehold (commander) | **ALTA** | ❌ SIM — sem spells no grave, commander faz nada |
| Restoration Seminar | **MEDIA** | ⚠️ Parcial — ainda cria Lesson token, mas perde recursao |
| Faithless Looting | **BAIXA** | ✅ Nao — flashback ainda funciona se nao exilar |
| Dragon's Rage Channeler | **BAIXA** | ⚠️ Parcial — surveil funciona, delirium enfraquece |
| Olorin's Searing Light | **BAIXA** | ✅ Nao — aind e removal |

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
- Approach of the Second Sun nao usa grave
- Insurrection nao usa grave
- Dance with Calamity e Improvisation Capstone nao usam grave
- Smothering Tithe, Jeska's Will, tesouros — nao usam grave

**Plano B sem cemiterio:**
1. Token army (Rite + Storm Herd)
2. Akroma's Will / Boros Charm pump
3. Approach hardcast (conjura 2x, 14 mana total)
4. Insurrection

**Respostas a Rest in Peace / Leyline of the Void:**

| Resposta | CMC | Eficacia |
|:---------|:---:|:--------:|
| Chaos Warp | 3 | ✅ Shuffle — remove permanente problemático sem destruir |
| Generous Gift | 3 | ✅ Destroi qualquer permanente |
| Boseiju, Who Shelters All | 2 (Channel) | ✅ Channel — nao e spell, nao pode ser counterada |
| Abrade | 2 | ❌ So artefatos (RiP e encantamento) |
| Olorin's Searing Light | 4 | ✅ Exila encantamento/artefato |

**Conclusao: 4 respostas para RiP/Leyline.**
Chaos Warp e a melhor (shuffle, nao counteravel com Boseiju backup).
Generous Gift e Olorin's sao versateis. Boseiju e Channel, nao pode ser counterada.

#### RESPOSTAS A ARTEFATOS/ENCANTAMENTOS PROBLEMATICOS

| Carta | CMC | Alvos |
|:------|:---:|:------|
| Chaos Warp | 3 | Qualquer permanente → shuffle |
| Generous Gift | 3 | Qualquer permanente → destroi |
| Boseiju | 2 | Artefato OU encantamento → destroi (Channel, nao-counteravel) |
| Abrade | 2 | Artefato → destroi OU criatura → 3 dano |
| Olorin's Searing Light | 4 | Qualquer permanente → exila |

**Nota: 5 respostas. Cobertura adequada para bracket 3.**
Nenhuma resposta em massa (tipo Austere Command para encantamentos/artefatos),
mas Chaos Warp + Generous Gift cobrem qualquer alvo problematico.

#### TEM BOUNCE PARA PERMANENTES PROBLEMATICOS?

| Carta | CMC | Efeito |
|:------|:---:|:-------|
| Fated Clash | 5 | Bounce 1 criatura POR OPONENTE + scry |
| -- | -- | **Nenhum bounce universal (tipo Cyclonic Rift)** |

**GAP: Sem bounce universal.** Fated Clash e bounce de criatura apenas.
O deck depende de remocao (Chaos Warp, Generous Gift) para lidar com permanentes problematicos.
Isso e aceitavel em Boros — Cyclonic Rift e azul.

**Graveyard Resilience Score: 5/10.**
O deck depende do cemiterio para 4/7 wincons (Mizzix's, Surge, Lorehold recursion, Bombardment).
Mas tem plano B viavel (tokens + Approach hardcast) e 4 respostas para hate de cemiterio.
A nota e 5/10 porque a DEPENDENCIA e real — um Rest in Peace forca o deck a mudar de plano
completamente. Em mesas com muito grave-hate, o deck perde ~40% do poder.

---

## Secao 4: DOUBLE-NULL AUDIT (pos-Ciclo #9)

### Cartas sem classificacao (functional_tag IS NULL AND 0 card_tags)

| Carta | CMC | EDHREC | Trend | Risco | Acao |
|:------|:---:|:------:|:-----:|:-----:|:-----|
| **Scroll Rack** | 2 | 59.7% | +0.15 | 🔴 NAO CORTAR | Core engine. Topdeck manipulation. Nivel 4. |
| **Penance** | 3 | 41.8% | +1.15 | 🔴 NAO CORTAR | Topdeck setup + anti-removal. Miracle enabler. Nivel 4. |
| **Ruby Medallion** | 2 | 42.3% | -0.37 | 🟡 MONITORAR | Declinio 3+ ciclos. Candidato a corte se colecao tiver CMC 1-2. Nivel 1. |
| **Taunt from the Rampart** | 5 | 35.2% | +0.10 | 🟢 MANTER | 35.2% EDHREC estavel. Goad util em multiplayer. Nivel 2. |
| **Grand Abolisher** | 2 | 11.7% | -0.27 | 🟡 MONITORAR | Protecao preemptiva. Declinio leve. Nivel 2. |

**Resumo: 5 double-nulls restantes (eram 10 no baseline).**
- 2 sao core engines (Scroll Rack, Penance) — NAO TOCAR
- 1 e declining leve (Grand Abolisher) — monitorar
- 1 e declining medio com EDHREC alto (Ruby Medallion) — proximo candidato a corte
- 1 e estavel com EDHREC medio (Taunt) — manter

### Double-nulls cortados desde baseline

| Carta | Ciclo | Motivo |
|:------|:-----:|:-------|
| Deflecting Palm | #2 | Substituido por Big Score |
| Orim's Chant | #3 | Substituido por Blasphemous Act |
| Victory Chimes (original) | #3 | Substituido por Generous Gift (depois re-entrou C#7) |
| Galadriel's Dismissal | #7 | 0% EDHREC. Substituido por Victory Chimes |
| Pearl Medallion | #9 | Declinio -0.46. Substituido por Akroma's Will |

---

## Secao 5: TREND ANALYSIS (pos-Ciclo #9)

### Cartas em Declinio no Deck (trend < -0.2)

| Carta | EDHREC | Trend | Ciclos em Declinio | Acao |
|:------|:------:|:-----:|:------------------:|:-----|
| Esper Sentinel | 32.5% | -0.54 | 6 | Monitorar — EDHREC ainda alto |
| Ruby Medallion | 42.3% | -0.37 | 3+ | Proximo corte (Nivel 1) |
| Grand Abolisher | 11.7% | -0.27 | 3+ | Monitorar — EDHREC baixo |
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

**Todas as rising stars do EDHREC ja estao no deck.** Nao ha cartas rising >20% fora do deck.

---

## Secao 6: ANALISE DE MATCHUPS (via BATTLE_LOG)

| Arquetype | Win Rate | Maior Fraqueza |
|:----------|:--------:|:---------------|
| Control | 56.0% | -- (Boros > Control com protecao anti-counter) |
| Midrange | 53.2% | -- (valor supera) |
| Aggro | 51.8% | -- (wipes + lifegain do One Ring) |
| **Combo** | **46.5%** | **Sem counterspell. Depende de remocao instantanea.** |

> **Nota:** BATTLE_LOG data e de pos-Ciclo #4 (Exec#8). Nao foi atualizada desde entao.
> O deck melhorou significativamente desde entao (+5 ciclos, Akroma's Will, Chaos Warp,
> Wedding Ring, Victory Chimes, Abrade). Win rates atuais provavelmente sao melhores.

---

## Secao 7: O PLANO DE JOGO — Turn by Turn

### T1 (Setup Inicial)
**Objetivo:** Ramp + topdeck setup
**Cartas ideais:** Sol Ring, Land Tax, Weathered Wayfarer, Sensei's Top, Library of Leng, Gamble, Enlightened Tutor, Esper Sentinel, Dragon's Rage Channeler
**Sequencia ideal:** Land Tax OU Wayfarer → T2 tera 3-4 lands

### T2 (Ramp Secundario)
**Objetivo:** Fixing + draw/loot
**Cartas ideais:** Arcane/Boros Signet, Talisman, Faithless Looting, Thrill of Possibility, Scroll Rack, Ruby Medallion
**Sequencia ideal:** Signet + Faithless → preenche grave, draw

### T3 (Protecao + Engine Setup)
**Objetivo:** Estabelecer protecao + preparar Lorehold
**Cartas ideais:** Lightning Greaves, Grand Abolisher, Hexing Squelcher, Smothering Tithe, Archaeomancer's Map, Jeska's Will, Monument to Endurance, Wedding Ring
**Sequencia ideal:** Greaves OU Tithe → T4 Lorehold seguro

⚠️ **Este e o turno PROBLEMATICO.** Com T3=16.9%, em ~17% dos jogos o deck nao tem NENHUM play T3.
Isso significa que 1 a cada 6 jogos, o deck passa T3 sem fazer nada.

### T4 (Lorehold + Valor)
**Objetivo:** Conjurar Lorehold + gerar valor imediato
**Cartas ideais:** Lorehold, Big Score, Unexpected Windfall, The One Ring, Storm-Kiln Artist, Akroma's Will (defensivo)
**Sequencia ideal:** Lorehold + Big Score (instant) → 2 treasures + draw + copy

### T5 (Motor Arrancado)
**Objetivo:** Copy engines + free spells
**Cartas ideais:** Double Vision, Arcane Bombardment, Dance with Calamity, Improvisation Capstone, Galvanoth
**Sequencia ideal:** Double Vision → Dance copiada → 16 cartas exiladas, conjura gratis

### T6+ (Fechar o Jogo)
**Objetivo:** Wincon
**Cartas ideais:** Approach, Insurrection, Mizzix's Mastery overload, Storm Herd + Akroma's Will, Surge + Approach
**8+ paths de vitoria.**

---

## Secao 8: GAPS E PROBLEMAS

### GAP #1: Sem Play T3 = 16.9% (DEFENSIVO obrigatorio) 🔴

| Metrica | Valor | Limite | Excesso |
|:--------|:-----:|:------:|:-------:|
| Sem Play T3 | 16.9% | 12% | +4.9pp |
| Ramp T1 (estrito) | 20.1% | -- | So 3 fontes |
| Jogaveis | 46.3% | -- | Estrutural |

**Causa raiz:** Apenas 3 fontes de ramp T1 estrito (Sol Ring, Land Tax, Weathered Wayfarer).
Com 35 lands, P(exatamente 2 lands) = 30.2%. Desses, ~67% nao tem ramp T1.
≈ 20% de TODAS as maos sao "2 lands sem ramp" — jogaveis mas sem play T3.

**Solucao viavel:** Adicionar mais fontes de CMC 0-1 que sejam acao (nao so ramp).
- Chrome Mox (CMC 0, requer aquisicao)
- Mana Vault (CMC 1, Game Changer, requer aquisicao)
- Skullclamp (CMC 1, draw, requer aquisicao)
- **Nada na colecao atual resolve este gap.**

### GAP #2: Ruby Medallion (Nivel 1, ultimo double-null com trend negativo) 🟡

| Metrica | Valor |
|:--------|:-----:|
| EDHREC | 42.3% |
| Trend | -0.37 (3+ ciclos em declinio) |
| Funcao | Cost reduction — afeta ~40 spells vermelhos |
| Problema | Treasure supera cost reduction em big-spell decks |

**Substituto ideal:** Chrome Mox, Mana Vault, Simian Spirit Guide, ou Skullclamp.
**Nenhum na colecao.**

### GAP #3: Colecao esgotada de CMC 1-2 🔴

Apos 23 swaps, a colecao de cartas CMC ≤ 3 com EDHREC > 15% que NAO estao no deck esta VAZIA.
Todos os upgrades restantes requerem AQUISICAO.

| Carta Desejada | CMC | Funcao | EDHREC | Custo Aprox |
|:---------------|:---:|:-------|:------:|:-----------:|
| Skullclamp | 1 | Draw engine | 45% | $5-8 |
| Mana Vault | 1 | Fast mana | Staple | $40-60 |
| Chrome Mox | 0 | Fast mana | Staple | $60-80 |
| Past in Flames | 4 | Recursion backup | 35% | $2-4 |
| Aurelia's Fury | 3 | Multi-target removal + silence | 10% | $1-2 |

### GAP #4: Draw real = 7 (1 abaixo do perfil minimo de 8) 🟡

Draw real = 7 fontes: Esper Sentinel, Thrill of Possibility, Dragon's Rage Channeler, The One Ring,
Valakut Awakening, Wedding Ring, Victory Chimes.
(Reforge the Soul e wheel, nao draw recorrente. Sensei's Top e virtual, nao +card advantage.)

**A 1 fonte do perfil minimo.** Aceitavel para Boros.

### GAP #5: Sem bounce universal 🟡

O deck nao tem Cyclonic Rift (azul) nem equivalente em Boros.
Depende de remocao pontual (Chaos Warp, Generous Gift) para permanentes problematicos.
Em mesas com muitos encantamentos/artefatos problematicos, pode ser insuficiente.

---

## Secao 9: ESTRATEGIA PARA CICLO #10

### Nivel de Estrategia: DEFENSIVO (T3 = 16.9% > 12%)

| Estrategia | T3 | Net ΔCMC | Prioridade |
|:-----------|:--:|:--------:|:-----------|
| DEFENSIVO | >12% | **-5 a -15** | Early-game cards (CMC ≤ 2) |

### Necessidade Estrategica (escala 0-5)

| Swap | Sai | Entra | ΔCMC | EDHREC | Necessidade | Bloqueio |
|:-----|:----|:------|:----:|:------:|:-----------:|:---------|
| Ruby Medallion → Skullclamp | Ruby Medallion (CMC 2) | Skullclamp (CMC 1) | -1 | 42→45% | 3 | **Nao na colecao** |
| Ruby Medallion → Chrome Mox | Ruby Medallion (CMC 2) | Chrome Mox (CMC 0) | -2 | 42→staple | 4 | **Nao na colecao** |
| Fated Clash → cheap interaction | Fated Clash (CMC 5) | -- | -3+ | -- | 2 | Nenhum candidato na colecao |
| Grand Abolisher → cheap draw | Grand Abolisher (CMC 2) | -- | ~0 | -- | 1 | Nenhum candidato na colecao |

### Decisao: 0 SWAPS para Ciclo #10

**Justificativa:** O deck esta saudavel. Motor 4/4, Copy 3/3, SYNERGY_MAP 7 eixos todos funcionais.
O unico gap real (T3=16.9%) e causado por falta de fast mana CMC 0-1, que NAO esta na colecao.
Ruby Medallion e o unico Nivel 1 cortavel, mas sem substituto viavel na colecao, cortar sem
substituir piora o deck (perde cost reduction sem ganhar nada).

**3 swaps possiveis (todos bloqueados por colecao):**
1. Ruby Medallion → Skullclamp (draw engine, ΔCMC -1, colecao: NAO)
2. Ruby Medallion → Chrome Mox (fast mana, ΔCMC -2, colecao: NAO)
3. Fated Clash → cheap interaction (ΔCMC -3+, colecao: NAO)

**Recomendacao de aquisicao (prioridade):**
1. **Skullclamp** ($5-8) — Draw engine que resolve GAP #3 e GAP #4
2. **Chrome Mox** ($60-80) — Fast mana que reduz T3
3. **Mana Vault** ($40-60) — Fast mana (GC, substitui Ruby)

---

## Secao 10: RESUMO EXECUTIVO

### Estado do Deck: SAUDAVEL (Pos-Ciclo #9, 23 swaps)

| Indicador | Status |
|:----------|:------:|
| Motor | 4/4 COMPLETO |
| Copy Engines | 3/3 COMPLETO |
| Token+Pump | 8/10 (ERA 6/10 — Akroma's Will fechou o gap!) |
| Wipes+Protection | 8/10 |
| Recursion | 8/10 |
| Mana Explosiva | 7/10 |
| Combo Pieces | 8/10 |
| Stack Interaction | 6/10 🆕 |
| Graveyard Resilience | 5/10 🆕 |
| **Sem Play T3** | **16.9% 🔴 DEFENSIVO** |
| Draw Real | 7 (perfil 8-12) |
| Double-nulls preocupantes | 1 (Ruby Medallion) |
| Declinios monitorados | 4 (Esper Sentinel pior) |

### Top 3 GAPS

1. **Sem Play T3 = 16.9%** → DEFENSIVO obrigatorio. So 3 fontes de ramp T1 estrito.
   Solucao requer aquisicao de fast mana (Chrome Mox, Mana Vault).

2. **Colecao esgotada** → Nenhum upgrade CMC ≤ 2 disponivel. Todos os proximos swaps
   requerem aquisicao de cartas. O deck atingiu maturidade maxima com a colecao atual.

3. **Ruby Medallion (Nivel 1)** → Ultimo double-null com trend negativo. Proximo a ser
   cortado quando houver substituto viavel.

### O que melhorou desde v3.8

1. **Akroma's Will (Ciclo #9):** Fechou o gap de "so 1 pump". Token+Pump subiu de 6/10 para 8/10.
2. **Pearl Medallion cortado:** Reduziu double-nulls de 6 para 5.
3. **Eixos F e G adicionados:** Stack Interaction (6/10) e Graveyard Resilience (5/10).
4. **Correcao do T3:** Identificado que 3.7% era free mulligan rate. T3 real = 16.9%.
5. **SYNERGY_MAP completo com 7 eixos:** Cobertura total do deck.

### Mudancas desde baseline (23 swaps em 9 ciclos)

| Ciclo | Swaps | Net ΔCMC | Estrategia | T3 Aprox |
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
| #10 | 0 | 0 | DEFENSIVO (sem colecao) | ~17% |

**Licao aprendida:** Ciclos #7/#8/#9 usaram T3=3.7% (errado) para escolher AGGRESSIVE.
O T3 real estava ~13-16%. O net ΔCMC +4 acumulado elevou T3 de ~13% para 16.9%.
**Nunca confiar no T3 do Evolution Oracle sem verificar MULLIGAN_LOG.md.**

---

*Relatorio gerado por Purpose Analyzer v3.9 em 2026-05-31T17:40:09Z*
*Analista: Hermes Agent — Agente 2 (Lorehold Purpose Analyzer)*
*Proxima execucao: v4.0 com BATTLE_LOG atualizado e possivel re-score pos-aquisicao*
