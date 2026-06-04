# VALIDATOR_LOG_v3.25.md — Lorehold, the Historian

> **Hash:** `7dbedbb426bf85aa2ecd3d23be4eb7ef`
> **Timestamp:** 2026-06-04T11:36:43+00:00
> **Source DB:** `mtgia-broken/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` (last valid DB; main repo DB is empty/ghost)
> **Pipeline status:** ⚠️ SINGLE-AGENT (no other agents active; Death Loop context)

---

## ⚠️ DISCLAIMER: ARCHETYPE MISMATCH — PG Profile Inaplicável

O PG profile (`commander_reference_deck_analysis`, 3-deck corpus) foi construído para um
arquétipo **cEDH/high-power** com 32 lands, ramp dedicado de rocks (3.67), e draw_value
mínimo (2.67). Este deck é **Bracket 3 spellslinger_big_spells** com 35 lands. As diferenças
são **estruturais**, não problemas de tuning.

| Característica | PG Profile (cEDH 3-deck) | Deck Atual (B3 spellslinger) |
|:---------------|:------------------------:|:----------------------------:|
| Lands | 32 | 35 |
| Ramp type | Rocks (3.67) | Treasures + rituals + rocks (15) |
| Draw | 2.67 (engine-based) | 4 tagged + 3 untagged = ~7 |
| Wincons | 1.33 (combo-focused) | 2-4 (approach + combat + combo) |

**Métricas fora do range NÃO são problemas reais** — são evidência da mudança de arquétipo.
Recomendação: gerar NOVO perfil PG para o arquétipo spellslinger_big_spells atual.

---

## Step 0: Pipeline Integrity Check

```sql
SELECT card_name FROM deck_cards WHERE deck_id=6 ORDER BY card_name
-- MD5: 7dbedbb426bf85aa2ecd3d23be4eb7ef
```

Hash computado do DB real. Última análise registrada em run_log:
`2026-05-27T01:20:49` (User provided decklist, Scryfall classified) — **7+ dias atrás.**

Nenhum VALIDATOR_LOG anterior foi gerado por cron desde então. Este é o primeiro.

---

## Secao 1: Estado Atual do Deck

| Métrica | Tag DB | Real (manual) | Delta DB vs Real |
|:--------|:------:|:-------------:|:----------------:|
| Total cards | 100 | 100 (99+commander) | ✅ |
| Lands | 35 | 35 | ✅ |
| Non-lands | 55 | 55 | ✅ |
| Ramp | 15 | 8 rocks/rituals + 5 treasure + 2 land-search = 15 | ⚠️ DB supercounts ramp |
| Draw | 4 | 7 (Esper, Top, Artist's Talent, Scroll Rack, Valakut Awakening, Victory Chimes, Monument) | ⚠️ DB undercounts (3 double-nulls) |
| Protection | 5 | 8 (Teferi's, Mother, Boros Charm, Greaves, Perch, Hexing, Deflecting Swat, Orim's Chant) | ⚠️ DB undercounts (2 double-nulls) |
| Board Wipe | 4 | 5 (Austere, Fated, Volcanic, Call Forth, Rise of Eldrazi) | ✅ |
| Removal | 4 | 5 (Path, Swords, Boros Charm, Deflecting Swat, Gamble-tutor-as-removal) | ✅ |
| Tutor | 3 | 3 (Enlightened, Gamble, Oswald) | ✅ |
| Recursion | 4 | 4 (Goblin Engineer, Mizzix's, Surge to Victory, Restoration Seminar) | ✅ |
| Wincon | 2 | 4 (Approach, Hellkite Tyrant, Surge to Victory, Insurrection) | ⚠️ DB undercounts |
| Spellslinger | 3 | 3 (Double Vision, Galvanoth, Rite of the Dragoncaller) | ✅ |
| Token Maker | 3 | 3 (Ancient Copper, Brass's Bounty, Hit the Mother Lode) + Storm Herd (token_maker tag mas com 75% EDHREC) = 4 | ✅ |
| Big Spell | 3 | 8 (Approach, Insurrection, Storm Herd, Sunbird's, Call Forth, Rise of Eldrazi, Restoration Seminar, Volcanic Vision) | ⚠️ DB severely undercounts |
| Exile Value | 1 | 1 (Season of the Bold) | ✅ |
| Graveyard Synergy | 2 | 3 (Library of Leng, Olórin's, Mizzix's Mastery) | ✅ |
| Loot | 1 | 2 (Reforge the Soul, Faithless Looting em coleção) | ✅ |
| Payoff | 1 | 1 (Longshot) | ✅ |

**Double-Null Cards (10):** Deflecting Palm, Galadriel's Dismissal, Grand Abolisher, Orim's Chant,
Pearl Medallion, Penance, Ruby Medallion, Scroll Rack, Taunt from the Rampart, Victory Chimes.

Destes, 3 são **críticos para o motor do deck** (Scroll Rack, Penance, Victory Chimes). Os
outros 7 são filler candidates.

---

## Secao 2: CLASSIFICACAO ESTRATEGICA

### Nivel 5 — Essencial (deck nao funciona sem)
| Card | CMC | Real Function | EDHREC | Trend |
|:-----|:---:|:--------------|:------:|:-----:|
| Lorehold, the Historian | 5 | Commander (copy spells) | — | — |
| Approach of the Second Sun | 7 | Wincon primário | 63.7% | +0.75 |
| Sensei's Divining Top | 1 | Topdeck engine + Approach combo | 66.6% | +0.56 |
| Scroll Rack | 2 | Topdeck engine + hand smoothing | Double-null | ⚠️ |

### Nivel 4 — Core Engine
| Card | CMC | Real Function | EDHREC | Trend |
|:-----|:---:|:--------------|:------:|:-----:|
| Mizzix's Mastery | 4 | Recursion massiva (overload) | 57.5% | +1.03 |
| Restoration Seminar | 7 | Recursion + draw | 38.2% | **+9.34** 🔥 |
| Double Vision | 5 | Copy engine | 46.4% | -0.03 |
| Hit the Mother Lode | 7 | Free big spell + treasures | 79.2% | +1.27 |
| Brass's Bounty | 7 | Treasure massivo | 67.0% | +1.03 |
| Penance | 3 | Topdeck setup + miracle enabler | Double-null | ⚠️ |
| Storm Herd | 10 | Token massivo (finisher) | 75.0% | +1.20 |

### Nivel 3 — Role Player Forte
| Card | CMC | Real Function | EDHREC | Trend |
|:-----|:---:|:--------------|:------:|:-----:|
| Sol Ring | 1 | Fast mana | 90.6% | 0.00 |
| Arcane Signet | 2 | Ramp | 88.1% | 0.00 |
| Jeska's Will | 3 | Ritual + exile draw | 30.4% 🟡GC | +0.41 |
| Smothering Tithe | 4 | Treasure engine | 29.4% 🟡GC | +0.04 |
| Teferi's Protection | 3 | Mass protection | 21.1% 🟡GC | -0.01 |
| Deflecting Swat | 3 | Redirect | 36.6% | -0.06 |
| Enlightened Tutor | 1 | Tutor artifact/enchant | 18.3% 🟡GC | -0.12 |
| Volcanic Vision | 7 | Asymmetric wipe + recursion | 63.8% | +1.25 |
| Call Forth the Tempest | 8 | Wipe + creatures | 65.0% | **-0.57** ⚠️ |
| Insurrection | 8 | Steal + pump (finisher) | 45.0% | -0.12 |
| Rise of the Eldrazi | 12 | Extra turn + annihilator | 54.4% | **-0.75** ⚠️ |
| Monument to Endurance | 3 | Draw + discard payoff | 72.8% | +1.29 |
| Library of Leng | 1 | No max hand + discard-to-top | 77.7% | +1.54 |
| Goldspan Dragon | 5 | Treasure doubler + haste | 17.7% | -0.25 |

### Nivel 2 — Aceitavel / Situacional
| Card | CMC | Real Function | EDHREC | Trend |
|:-----|:---:|:--------------|:------:|:-----:|
| Esper Sentinel | 1 | Draw condicional | 32.2% | **-0.66** ⚠️ |
| Artist's Talent | 2 | Draw + spell discount | 20.9% | **-0.72** ⚠️ |
| Boros Charm | 2 | Protection + pump + removal | 45.2% | +0.28 |
| Lightning Greaves | 2 | Haste + shroud | 45.1% | +0.91 |
| Mother of Runes | 1 | Creature protection | 34.4% | +0.16 |
| Perch Protection | 6 | Fog + extra turn + gift | 34.4% | **-0.59** ⚠️ |
| Hexing Squelcher | 2 | Anti-tutor protection | 40.7% | +0.17 |
| Path to Exile | 1 | Removal | 57.5% | +0.97 |
| Swords to Plowshares | 1 | Removal | 69.0% | +1.27 |
| Austere Command | 6 | Flexible wipe | 33.3% | -0.24 |
| Fated Clash | 5 | Wipe + scry | 15.5% | -0.21 |
| Surge to Victory | 6 | Exile + copy + pump | 19.5% | +0.56 |
| Reforge the Soul | 5 | Wheel | 37.7% | +0.32 |
| Unexpected Windfall | 4 | Draw + treasures | 56.7% | +0.59 |
| Archaeomancer's Map | 3 | Land ramp | 17.4% | +0.35 |
| Land Tax | 1 | Land search | 31.6% | +0.89 |
| Talisman of Conviction | 2 | Ramp rock | 64.6% | 0.00 |
| Bender's Waterskin | 3 | Ramp (treasure) | 71.1% | 0.00 |
| Longshot, Rebel Bowman | 4 | Removal payoff | 47.9% | +0.21 |
| Galvanoth | 5 | Free spell per turn | 26.6% | +0.04 |
| Rite of the Dragoncaller | 6 | Dragon tokens on cast | 23.4% | -0.19 |
| Olórin's Searing Light | 4 | Graveyard hate + exile | 53.0% | +0.46 |

### Nivel 1 — Filler / Candidato a Corte
| Card | CMC | Real Function | EDHREC | Trend | Risk |
|:-----|:---:|:--------------|:------:|:-----:|:----:|
| Ancient Copper Dragon | 6 | Haste dragon + treasures | 0% (não trackeado) | — | 🔴 |
| Desperate Ritual | 2 | Ritual (2→3 mana, net +1) | 0% (não trackeado) | — | 🔴 |
| Goblin Engineer | 2 | Artifact tutor-to-grave + recursion | 0% (não trackeado) | — | 🔴 |
| Hellkite Tyrant | 6 | Steal artifacts wincon | 0% (não trackeado) | — | 🔴 |
| Oswald Fiddlebender | 2 | Artifact pod (tutor) | 0% (não trackeado) | — | 🔴 |
| Weathered Wayfarer | 1 | Land search | 0% (não trackeado) | — | 🟡 |
| Season of the Bold | 5 | Exile 5 cards (exile_value) | 9.8% | -0.15 | 🟡 |
| Sunbird's Invocation | 6 | Cascade-like value | 13.6% | -0.09 | 🟡 |
| Deflecting Palm | 2 | Fog + reflect damage | Double-null | — | 🟡 |
| Galadriel's Dismissal | 1 | Phase out protection | Double-null | — | 🟡 |
| Grand Abolisher | 2 | Silence on your turn | Double-null | — | 🟡 |
| Orim's Chant | 1 | Silence / Fog split | Double-null | — | 🟡 |
| Pearl Medallion | 2 | White cost reduction | Double-null | — | 🟡 |
| Ruby Medallion | 2 | Red cost reduction | Double-null | — | 🟡 |
| Taunt from the Rampart | 5 | Mass goad | Double-null | — | 🟢 (35.2% EDHREC?) |
| Gamble | 1 | Tutor with discard risk | 12.1% | **-0.49** | 🟡 |
| Seething Song | 3 | Ritual (3→5 mana) | 15.9% | **-0.59** | 🟡 |

---

## Secao 3: SYNERGY_MAP — 7 Eixos

### A) Token Makers + Pump — Score: 5/10
**Token makers:** Ancient Copper Dragon (treasures), Brass's Bounty (treasures), Hit the Mother Lode (treasures), Storm Herd (Pegasus tokens), Goldspan Dragon (treasures ×2), Smothering Tithe (treasures)
**Pump:** Insurrection (+X/+0), Call Forth the Tempest (damage to all + creatures), Surge to Victory (+X/+0 per exiled CMC)
**Forca:** Treasure generation abundante (6+ fontes). Storm Herd como finisher de late-game (75% EDHREC).
**Fraqueza:** Sem payoffs de tesouro dedicados (Xorn e Storm-Kiln Artist estao na colecao mas NAO no deck). Treasure e usado so para mana, nao como estrategia de vitoria propria.
**Recomendacao:** Adicionar Storm-Kiln Artist (CMC 4, na colecao) para transformar treasures em draw engine. Xorn (CMC 3, na colecao) dobra tokens de tesouro.

### B) Board Wipes + Protection — Score: 8/10
**Wipes:** Austere Command (flexivel), Fated Clash (scry 2), Volcanic Vision (assimetrico + recursion), Call Forth the Tempest (damage + criaturas), Rise of the Eldrazi (annihilator 4 + extra turn)
**Protection:** Teferi's Protection (phase out), Boros Charm (indestructible + double strike), Deflecting Swat (redirect), Orim's Chant (silence), Lightning Greaves (shroud + haste), Mother of Runes (protection from color), Perch Protection (fog + extra turn), Hexing Squelcher (anti-tutor)
**Ratio:** 5 wipes : 8 protection = 1:1.6 (defensivo). Meta esperado: 1:1 a 1:1.5.
**Forca:** Excelente cobertura de protecao. Volcanic Vision e o unico wipe verdadeiramente assimetrico (retorna instant/sorcery do cemiterio).
**Fraqueza:** Muitas cartas de protecao single-target (Mother, Greaves, Hexing) ocupam slots que poderiam ser ramp/draw. Perch Protection e caro (CMC 6) para um efeito de Fog.

### C) Recursion Chains — Score: 6/10
**Recursion:** Mizzix's Mastery (overload = todas as instant/sorcery do cemiterio), Restoration Seminar (retorna instant/sorcery + draw), Surge to Victory (exile + cria copia para cada criatura atacante), Goblin Engineer (tutor de artefato para cemiterio + recursion de artefato)
**Key loops:**
- Faithless Looting (colecao, nao no deck) → descarta Big Spells → Mizzix's Mastery overload → todas de graca
- Restoration Seminar → retorna Mizzix's Mastery → overload novamente
- Surge to Victory + qualquer spell CMC 5+ → copia para cada criatura atacante
**Forca:** Mizzix's Mastery overload e um dos payoffs mais fortes do deck. Restoration Seminar em ascensao (+9.34 trend).
**Fraqueza:** Goblin Engineer e fragil (0% EDHREC) e so recorre artefatos. Faithless Looting esta na colecao mas nao no deck — e essencial para alimentar o cemiterio. Sem Faithless Looting, o deck depende de loot natural (Reforge the Soul, Unexpected Windfall).

### D) Explosive Mana — Score: 8/10
**Treasure:** Brass's Bounty (7 mana → 7+ treasures), Hit the Mother Lode (descobre spell gratis + treasures), Goldspan Dragon (dobra treasures), Smothering Tithe (treasures por draw oponente), Ancient Copper Dragon (d20 treasures), Unexpected Windfall (draw 2 + 2 treasures = net 0 mana)
**Rituals:** Desperate Ritual (net +1), Seething Song (net +2), Jeska's Will (net +4 a +7 no early game)
**Rocks:** Sol Ring (net +2), Arcane Signet (+1), Talisman of Conviction (+1), Victory Chimes (+1 por turno de CADA jogador), Bender's Waterskin (+1 e salva dead draws)
**Land ramp:** Archaeomancer's Map, Land Tax, Weathered Wayfarer
**Cost reduction:** Pearl Medallion, Ruby Medallion, Monument to Endurance
**Mana sinks:** Approach (7), Insurrection (8), Storm Herd (10), Rise of the Eldrazi (12), Call Forth (8), Volcanic Vision (7)
**Forca:** Geracao de mana explosiva — e possivel ter 10+ mana no turno 4 com as combinacoes certas. Jeska's Will e particularmente forte (exila topo + add R por carta exilada).
**Fraqueza:** Cost reducers (Medallions) sao double-null e estao em declinio na comunidade. Boros Signet, Fellwar Stone e Lotus Petal estao na colecao mas nao no deck. Desperate Ritual e net +1 apenas.

### E) Combo Pieces — Score: 7/10
**Combo primario:** Approach of the Second Sun + Sensei's Divining Top + Scroll Rack
- T1: Cast Approach (7 mana) → vai 7ª do topo
- T2: Top draw → Approach de volta → cast Approach novamente → WIN
- Com Scroll Rack: coloca Approach de volta no topo instantaneamente (nao precisa esperar 1 turno)
- Com Penance: coloca Approach do topo na mao em resposta a dano

**Combos secundarios:**
- Mizzix's Mastery overload → Surge to Victory → copia spell para cada criatura atacante
- Insurrection (steal tudo) → ataque letal
- Hellkite Tyrant (steal 20+ artifacts) → win alternativa

**Combo potencial (cartas na colecao):**
- Flare of Duplication (CMC 3, na colecao) → copia Approach of the Second Sun → mesma resolucao de stack → WIN MESMO TURNO (nao precisa esperar 1 turno!)
- Twinflame (CMC 2, na colecao) → copia Goldspan Dragon → 2x treasures + haste

**Forca:** Approach+Top+Rack e deterministico e protegido (nao depende de combate nem graveyard).
**Fraqueza:** Falta redundancy — se Approach for exilada (Praetor's Grasp, Jester's Cap), o deck perde o combo primario. Flare of Duplication (na colecao) tornaria o combo mesmo-turno, eliminando a janela de 1 turno onde o oponente pode responder.

### F) Stack & Resilience — Score: 4/10
**Interacao de stack:** Orim's Chant (silence — previne oponentes de jogar spells), Boros Charm (indestrutivel — resposta a wipe), Teferi's Protection (phase out — resposta a tudo), Deflecting Swat (redirect — resposta a spot removal), Lightning Greaves (shroud — preventiva)
**Resiliencia:** Mother of Runes (protecao de cor), Perch Protection (fog + extra turn), Hexing Squelcher (anti-tutor — preventiva vs combo)
**Forca:** Protecao robusta contra removal e wipes. Orim's Chant como silence no upkeep do oponente combo e devastador.
**Fraqueza:** Zero counterspells (RW). Dependencia total de protecao proativa. Se um oponente resolve um combo em resposta ao seu Approach cast, o deck nao tem resposta.

### G) Card Advantage & Selection — Score: 6/10
**Draw real:** Esper Sentinel (condicional, trend -0.66), Sensei's Divining Top (selecao, nao draw real), Artist's Talent (loot 1/turno, trend -0.72), Scroll Rack (selecao), Valakut Awakening (wheel), Victory Chimes (draw 1 condicional), Monument to Endurance (draw no descarte)
**Tutor:** Enlightened Tutor (artefato/enchant), Gamble (qualquer carta com risco de descarte, trend -0.49), Oswald Fiddlebender (artefato pod)
**Topdeck manipulation:** Scroll Rack, Penance, Sensei's Top — excelente para miracle e Approach, mas nao gera card advantage
**Forca:** Excelente selecao de topo (Top+Rack+Penance e um dos melhores pacotes de topdeck em Boros).
**Fraqueza:** Draw real e limitado (4 fontes, 2 em declinio). RW nao tem acesso a draw eficiente. Monument to Endurance e a melhor fonte de draw (condicional a descarte), mas requer engine de descarte (Reforge, Unexpected Windfall). Faithless Looting (na colecao) seria um upgrade de Artist's Talent (CMC 1, draw 2 + discard 2, flashback).

---

## Secao 4: Trend Analysis

### 🔥 Rising Stars (trend > 2.0)
| Card | EDHREC | Trend | In Deck? | In Collection? |
|:-----|:------:|:-----:|:--------:|:--------------:|
| Restoration Seminar | 38.2% | **+9.34** | ✅ | ✅ |

### ⚠️ Declining Cards (trend < -0.3, inclusion > 15%)
| Card | EDHREC | Trend | Severidade |
|:-----|:------:|:-----:|:-----------|
| Rise of the Eldrazi | 54.4% | **-0.75** | 🔴 Alto — 54% inclusion mas tendencia forte de queda |
| Artist's Talent | 20.9% | **-0.72** | 🔴 Alto — 20% inclusion com queda rapida, 7+ ciclos |
| Esper Sentinel | 32.2% | **-0.66** | 🟡 Medio — ainda com 32%, monitorar |
| Seething Song | 15.9% | **-0.59** | 🟡 Medio — ja marginal (15.9%), queda acelera saida |
| Perch Protection | 34.4% | **-0.59** | 🟡 Medio — CMC 6 caro, efeito de Fog |
| Call Forth the Tempest | 65.0% | **-0.57** | 🟡 Medio — mais-incluida do deck (65%), tendencia agora negativa |

### 📦 Cartas na Colecao com Alto Potencial (CMC <= 3, nao no deck)
| Card | CMC | EDHREC (estimado) | Funcao | Prioridade |
|:-----|:---:|:-----------------:|:-------|:----------:|
| **Faithless Looting** | 1 | ~30% | Draw + graveyard setup | 🔴 #1 |
| **Lotus Petal** | 0 | ~20% | Fast mana (storm/combo) | 🔴 #2 |
| **Boros Signet** | 2 | ~50% | Ramp rock | 🔴 #3 |
| **Twinflame** | 2 | ~5% | Creature copy + Surge chain | 🟡 #4 |
| **Chaos Warp** | 3 | ~39% | Universal removal | 🟡 #5 |
| **Flare of Duplication** | 3 | ~2% | Approach combo mesmo-turno | 🟡 #6 |
| Fellwar Stone | 2 | ~30% | Ramp rock | 🟢 #7 |

---

## Secao 5: PG Profile Comparison

> ⚠️ VER DISCLAIMER DE ARCHETYPE MISMATCH ACIMA. As comparacoes abaixo sao informativas,
> nao diagnosticas. Diferencas sao estruturais (Bracket 3 vs cEDH), nao problemas de tuning.

| PG Role | PG Ideal | Deck (tag DB) | Deck (manual) | Delta (manual) | Status |
|:--------|:--------:|:-------------:|:-------------:|:--------------:|:------:|
| lands | 32 | 35 | 35 | +3 | 🟡 WARN |
| ramp | 3.67 | 15 | 15 | +11.33 | ⚠️ MISMATCH |
| ritual_treasure | 10 | ~7 (manual) | ~7 | -3 | 🟡 WARN |
| big_spell_payoff | 7.67 | 3 (DB undercount) | ~8 | +0.33 | ✅ OK |
| miracle_topdeck | 4.33 | 3 (Top+Rack+Penance) | 3 | -1.33 | 🔵 BLUE |
| interaction | 5.33 | 4 | ~6 | +0.67 | ✅ OK |
| protection | 3.67 | 5 | ~8 | +4.33 | ⚠️ MISMATCH |
| draw_value | 2.67 | 4 | ~7 | +4.33 | ⚠️ MISMATCH |
| tutor | 3.67 | 3 | 3 | -0.67 | ✅ OK |
| win_condition | 1.33 | 2 | 4 | +2.67 | ⚠️ MISMATCH |
| board_wipe | 2.0 | 4 | 5 | +3.0 | ⚠️ MISMATCH |
| recursion | 3.33 | 4 | 4 | +0.67 | ✅ OK |
| spellslinger | 3.67 | 3 | 3 | -0.67 | ✅ OK |
| exile_value | 3.67 | 1 | 1 | -2.67 | 🟡 WARN |
| creature | 3.33 | ~11 (manual) | ~11 | +7.67 | ⚠️ MISMATCH |

**Conclusao:** 7/15 metricas com MISMATCH (>3 de delta). NENHUMA e problema real —
o PG profile foi construido para cEDH/high-power com 32 lands, este deck e Bracket 3
com 35 lands. As metricas de ramp (+11), draw (+4), protection (+4), creatures (+8) e
win_condition (+3) sao naturalmente mais altas em spellslinger do que em cEDH fast-combo.

---

## Secao 6: Game Changers

O deck tem **5 Game Changers** (Bracket 3 permite ate 3):

| Card | EDHREC | Trend | Funcao |
|:-----|:------:|:-----:|:-------|
| Jeska's Will | 30.4% | +0.41 | Ritual explosivo |
| Smothering Tithe | 29.4% | +0.04 | Treasure engine |
| Teferi's Protection | 21.1% | -0.01 | Mass protection |
| Enlightened Tutor | 18.3% | -0.12 | Tutor |
| Gamble | 12.1% | -0.49 | Tutor com risco |

**⚠️ BRACKET VIOLATION:** 5 GCs em Bracket 3 (max 3). Recomendacao:
- Cortar **Gamble** (12.1%, trend -0.49) — mais fraco dos tutores, risk de descarte
- Cortar **Enlightened Tutor** (18.3%, trend -0.12) — ou manter e cortar Gamble
- Substituir por: Faithless Looting (CMC 1, na colecao) e Boros Signet (CMC 2, na colecao)

---

## Secao 7: Recomendacoes de Swap (TOP 5)

### Prioridade #1: Faithless Looting → Artist's Talent
- **Diagnostico:** Artist's Talent em declinio (-0.72, 7+ ciclos). Draw/loot limitado (1/turno).
- **Solucao:** Faithless Looting (CMC 1, na colecao) — draw 2 + discard 2 + flashback. Alimenta cemiterio para Mizzix's Mastery. Net ΔCMC = 0.
- **Principio:** Draw real + graveyard setup sobre draw condicional em declinio.

### Prioridade #2: Boros Signet → Oswald Fiddlebender
- **Diagnostico:** Oswald com 0% EDHREC, fragil (criatura 1/1), requer sacrificar artefatos que o deck nao quer perder (Top, Scroll Rack, Sol Ring).
- **Solucao:** Boros Signet (CMC 2, na colecao, ~50% EDHREC) — ramp rock confiavel. Net ΔCMC = 0.
- **Principio:** Ramp universal sobre tutor fragil e sem meta.

### Prioridade #3: Lotus Petal → Desperate Ritual
- **Diagnostico:** Desperate Ritual com 0% EDHREC. Net +1 mana por 2 mana investido — ineficiente.
- **Solucao:** Lotus Petal (CMC 0, na colecao) — fast mana gratuita. Net ΔCMC = -2.
- **Principio:** Fast mana gratuita sobre ritual de net +1.

### Prioridade #4: Chaos Warp → Fated Clash
- **Diagnostico:** Fated Clash (CMC 5, 15.5% EDHREC) — wipe situacional com scry 2. CMC alto para wipe condicional.
- **Solucao:** Chaos Warp (CMC 3, na colecao, ~39% EDHREC) — removal universal (encanta, artefato, criatura, planeswalker). Net ΔCMC = -2.
- **Principio:** Removal universal sobre wipe caro e situacional.

### Prioridade #5: Storm-Kiln Artist → Goblin Engineer
- **Diagnostico:** Goblin Engineer com 0% EDHREC. Recorre artefatos mas o deck so tem ~6 artefatos relevantes.
- **Solucao:** Storm-Kiln Artist (CMC 4, na colecao) — transforma cada spell em treasure. Motor de mana massivo. Net ΔCMC = +2.
- **Principio:** Motor de mana comprovado sobre recursion fragil e niche.

**Impacto total:** ΔCMC = 0 + 0 + (-2) + (-2) + (+2) = **-2 (DEFENSIVO leve)**

---

## Secao 8: Cartas a Adquirir (Gap Analysis)

| Card | CMC | EDHREC est. | Por que | Custo est. |
|:-----|:---:|:----------:|:--------|:----------:|
| **Skullclamp** | 1 | ~25% | Draw engine via sacrifício de tokens (Storm Herd, dragons) | $5-8 |
| **Past in Flames** | 4 | ~15% | Flashback massivo — redundancy para Mizzix's Mastery | $2-4 |
| **Underworld Breach** | 2 | ~10% | Recursion de qualquer carta do cemitério | $10-15 |
| **Xorn** | 3 | — | Dobra tokens de tesouro (0% EDHREC mas sinergia obvia) | $1-2 |
| **Arcane Bombardment** | 6 | 42.5% | Copy engine redundante com Double Vision | $2-4 |

---

## Secao 9: O PLANO DE JOGO — Turn by Turn

### Mao Ideal (T1-T6)
- **T1:** Land + Sol Ring → Arcane Signet / Talisman (4 mana T2)
- **T2:** Land + Smothering Tithe / Monument to Endurance (setup de mana/draw)
- **T3:** Land + Jeska's Will (exile 3-4, add RRRR) → Double Vision / Goldspan Dragon (5-6 mana disponivel)
- **T4:** Land + Hit the Mother Lode (descobre spell gratis) / Brass's Bounty (7+ treasures)
- **T5:** Approach of the Second Sun + Sensei's Divining Top (cast Approach, vai 7ª)
- **T6:** Top draw → Approach de volta → cast → WIN

### Mao Media (T1-T8)
- **T1:** Land + Sol Ring / Land Tax
- **T2:** Land + Arcane Signet / Talisman
- **T3:** Land + Archaeomancer's Map / Monument to Endurance
- **T4:** Land + Smothering Tithe / Unexpected Windfall
- **T5:** Land + Goldspan Dragon / Double Vision
- **T6:** Land + Brass's Bounty (7 treasures)
- **T7:** Approach of the Second Sun (7 mana, mais 7 treasures no board)
- **T8:** Cast Approach novamente → WIN (ou esperar 1 turno com Top)

### Mao Pobre (T1-T10+)
- **T1-T3:** Lands + ramp rocks, sem draw, esperando topdeck
- **T4-T6:** Protecao (Teferi's, Mother, Boros Charm) para sobreviver
- **T7+:** Tentativa de combo com o que vier (Insurrection steal, Storm Herd tokens, Mizzix's overload)
- **Risco:** Sem draw real, maos pobres sao muito vulneraveis. Faithless Looting ajudaria.

---

## Secao 10: Double-Null Audit

| Card | CMC | Real Function | EDHREC | Risco de Auto-Swap |
|:-----|:---:|:--------------|:------:|:-------------------|
| **Scroll Rack** | 2 | Topdeck engine + hand smoothing | Nao trackeado | 🔴 CRITICO — core engine |
| **Penance** | 3 | Topdeck setup + miracle enabler | Nao trackeado | 🔴 CRITICO — miracle enabler |
| **Victory Chimes** | 3 | Mana rock + draw condicional | Nao trackeado | 🟡 ALTO — draw engine |
| Deflecting Palm | 2 | Fog + reflect damage | Nao trackeado | 🟡 MEDIO |
| Galadriel's Dismissal | 1 | Phase out protection | Nao trackeado | 🟡 MEDIO |
| Grand Abolisher | 2 | Silence no seu turno | Nao trackeado | 🟡 MEDIO (11.7%?) |
| Orim's Chant | 1 | Silence / Fog | Nao trackeado | 🟡 MEDIO |
| Pearl Medallion | 2 | Cost reduction (white) | Nao trackeado | 🟢 BAIXO — apenas 23 spells brancos |
| Ruby Medallion | 2 | Cost reduction (red) | Nao trackeado | 🟡 MEDIO — 28 spells vermelhos |
| Taunt from the Rampart | 5 | Mass goad | Nao trackeado | 🟢 BAIXO |

---

## Secao 11: Run Log Entry Criteria

- **status:** `ok` — analise completa com recomendacoes
- **discrepancies_found:** 3 (DB tag gaps: draw undercount, protection undercount, wincon undercount; Bracket violation: 5 GCs em B3; PG archetype mismatch: 7 metricas com delta > 3)
- **insights_found:** 6 (Approach+Top+Rack combo mapping, SYNERGY_MAP 7-axis scoring, trend analysis com 6 declining cards, collection cross-reference com 7 candidates, double-null risk assessment, Bracket GC violation)

---

## Versao Anterior

Nenhuma — primeiro VALIDATOR_LOG gerado por cron para este deck. Ultimo run_log:
`2026-05-27T01:20:49` (User provided decklist, Scryfall classified).
