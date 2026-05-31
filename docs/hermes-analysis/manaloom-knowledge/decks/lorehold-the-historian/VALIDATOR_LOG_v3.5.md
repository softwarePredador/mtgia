# Análise do Deck Lorehold — 2026-05-31 (v3.5, Purpose Analyzer — Post-Ciclo #4 Deep Analysis)

> **Versão**: v3.5 (superset de v3.4 — incorpora dados EDHREC live 7802 decks + simulação pós-Ciclo #4)
> **Data**: 2026-05-31
> **Deck state**: Pós-Ciclo #4, 100 cartas, deck_id=6
> **Métrica "sem play T3"**: 13.8% (BALANCED — melhorou de 16.4%)

---

## Seção 0: O Estado Atual do Deck (Pós-Ciclo #4)

O EVOLONG_LOG documenta 9 swaps aplicados no total (Ciclo #1 → Ciclo #4):

**Ciclo #1 (2026-05-27):**
- SAI: Furygale Flocking → ENTRA: Esper Sentinel (draw)
- SAI: Jokulhaups → ENTRA: Gamble (tutor)
- SAI: Karoo → ENTRA: Plains (land)

**Ciclo #2 (2026-05-27):**
- SAI: Deflecting Palm → ENTRA: Big Score (ramp+draw)
- SAI: Hellkite Tyrant → ENTRA: Dance with Calamity (big spell)
- SAI: Mother of Runes → ENTRA: The One Ring (draw engine)

**Ciclo #3 (2026-05-30):**
- SAI: Ancient Copper Dragon (0%) → ENTRA: Storm-Kiln Artist (55.4%) ✅ Motor completo
- SAI: Desperate Ritual (0%) → ENTRA: Boros Signet (50.3%) ✅ Ramp consistente
- SAI: Sunbird's Invocation (13.6%) → ENTRA: Improvisation Capstone (48.9%) ✅ Big spell superior
- SAI: Victory Chimes (53.7%) → ENTRA: Generous Gift (32.5%) ✅ Removal universal
- SAI: Orim's Chant (0%) → ENTRA: Blasphemous Act (40.4%) ✅ Board wipe eficiente

**Ciclo #4 (2026-05-30) — DEFENSIVO:**
- SAI: Risk of the Eldrazi... → ENTRA: Faithless Looting (29.7%) ✅ Draw + GY fill
- SAI: ... → ENTRA: Dragon's Rage Channeler (39.5%) ✅ Draw + graveyard synergy  
- SAI: ... → ENTRA: Thrill of Possibility (13.9%) ✅ Draw + instant
- Net ΔCMC = -15 (estratégia defensiva para reduzir Sem Play T3 de 16.4%)

**Métricas do DB (pós-Ciclo #4):**
| Métrica | DB | Real (single-tag) | Perfil EDHREC | Status |
|:--------|:--:|:-----------------:|:-------------:|:------:|
| Lands | 35 | 35 | 36-38 | 🟡 -1 |
| Ramp | 16 | 16 | 10-13 | 🟡 +3 (tesouro) |
| Draw | 6 | ~6 (real) | 8-12 | 🔴 Crítico (faltam 2-6) |
| Proteção | 4 | 4 | 3-4 (support) | ✅ |
| Removal | 4 | 4 | 4-6 | ✅ inferior |
| Board wipe | 5 | 5 | 3-5 | ✅ |
| Recursion | 4 | 4 | 3-5 | ✅ |
| Big spells | ~24 | ~24 | 10-16 + 5-8 payoff | ✅ Motor completo |
| Wincon | 1 | 1 | 3-5 | 🔴 Precisa de mais |

---

## Seção 1: Mulligan Simulation — Pós-Ciclo #4 (canônico seed=42, N=1000)

| Métrica | Pós-Ciclo #3 (Exec#7) | Pós-Ciclo #4 | Δ | Status |
|:--------|:---------------------:|:------------:|:-:|:------:|
| Sem Play T3 | 16.4% | **13.8%** | **-2.6pp** | 🟡 Melhorou |
| Jogáveis (rigoroso) | 65.7% | **67.5%** | **+1.8pp** | ✅ |
| Mulligatorio | 29.9% | **27.7%** | **-2.2pp** | ✅ Melhorou |
| Ramp T1 (estrita) | 19.7% | **21.2%** | **+1.5pp** | ✅ Estável |

**Ciclo #4 foi bem-sucedido**: Sem Play T3 caiu de 16.4% para 13.8% (-2.6pp), dentro do esperado para a estratégia defensiva com ΔCMC = -15. O deck ganhou 3 fontes de draw (Faithless Looting, DRC, Thrill of Possibility) sem perder capacidade early-game.

**Análise:** 13.8% Sem Play T3 está na zona BALANCED (8-12% seria ideal, mas 13.8% é marginalmente acima). O Ciclo #5 deve seguir estratégia BALANCED — trocas com ΔCMC neutro, focando em qualidade e meta-alignment sem piorar a curva.

---

## Seção 2: O Motor de Lorehold — 4/4 COMPLETO ✅

```
[Tesouro Ramp] → [Big Spell Grátis] → [Lorehold Copy] → [Treasure Payoff]
     ✅ 3/3              ✅ 3 engines        ✅ Automático        ✅ Storm-Kiln
```

**Todos os 4 componentes estão COMPLETOS desde Ciclo #3.** O motor funciona:

| Componente | Carta | Presente? | EDHREC |
|:-----------|:------|:---------:|:------:|
| Treasure Ramp | Big Score | ✅ | 67.3% |
| Treasure Ramp | Brass's Bounty | ✅ | 67.2% |
| Treasure Ramp | Hit the Mother Lode | ✅ | 79.4% |
| Treasure Payoff | Storm-Kiln Artist | ✅ | 55.4% |
| Treasure Payoff | Jeska's Will | ✅ | 30.5% |
| Free Big Spell | Dance with Calamity | ✅ | 50.3% |
| Free Big Spell | Improvisation Capstone | ✅ | 49.0% |
| Free Big Spell | Approach of the Second Sun | ✅ | 63.8% |
| Topdeck | Scroll Rack + Penance | ✅ | 59.7%/41.8% |
| Topdeck | Sensei's Divining Top | ✅ | 66.9% |
| Topdeck | Library of Leng | ✅ | 77.8% |
| Draw | The One Ring | ✅ (B3 GC疑) | 8.5% |
| Copy Engine | Double Vision | ✅ | 46.6% |
| Copy Engine | Galvanoth | ✅ | 26.5% |
| Recursion | Mizzix's Mastery | ✅ | 57.5% |
| Recursion | Restoration Seminar | ✅ | 37.8% |

**Status: MOTOR 4/4 COMPLETO. Deck building pode focar agora em OTIMIZAÇÃO, não em completar o motor.**

---

## Seção 3: A Crise de Draw — Levemente Melhorada

### Fontes de Draw Real (pós-Ciclo #4):

1. **Lorehold, the Historian** — loot no combat por turno. Comandante (5.0 CMC)
2. **The One Ring** — draw crescente: 1, 2, 3... Game Changer. 8.5% EDHREC. Trend -0.32 ⚠️
3. **Esper Sentinel** — draw condicional (oponente paga 1 ou compra). 32.5% EDHREC. Trend -0.54 ⚠️
4. **Sensei's Divining Top** — pseudo-draw por 1 mana + virar. 66.9% EDHREC. Trend +0.56 ✅
5. **Faithless Looting** — draw 2, descarta 2. GY fill. 29.7% EDHREC. Trend +0.44 ✅
6. **Dragon's Rage Channeler** — draw ao cast spells do GY. 39.5% EDHREC. Trend +0.46 ✅
7. **Thrill of Possibility** — draw 2, descarta 1 (instant). 13.9% EDHREC. Trend +0.01
8. **Artist's Talent** — draw com descarte. Nível 3 ativação lenta. 21.1% EDHREC. Trend -0.70 🔴
9. **Reforge the Soul** — loot 5 (Miracle disponível). 37.9% EDHREC. Trend +0.34 ✅

**Draw líquido: 6-7 fontes (DB: 6).** Perfil EDHREC: 8-12. **Falta: 1-5 draw sources.**

### Falsos Positivos Multi-tag:
- **Land Tax** → draw(0.84) — NÃO é draw, é land tutor. 31.5% EDHREC. Trend +0.80 ✅
- **Monument to Endurance** → draw(0.84) — draw condicional. 72.9% EDHREC. Trend +1.28 ✅
- **Weathered Wayfarer** → draw(0.84) — tutor de terrenos. Não ranqueado no EDHREC
- **Unexpected Windfall** → draw(0.84) — loot 2 (líquido +1). 56.9% EDHREC. Trend +0.65 ✅

---

## Seção 4: O Grafo de Criaturas — 11 no Deck

### 🔴 Criaturas Problemáticas (4/11)

| Criatura | Função | Problema | EDHREC | Trend |
|:---------|:-------|:---------|:------:|:-----:|
| **Oswald Fiddlebender** | Tutor artifact | Sacrifica artefato para tutor. Não há artefatos sacrificáveis para payoff | 0% | N/A |
| **Goldspan Dragon** | Ramp(token maker) | CMC 5 para criar treasures. Storm-Kiln já faz isso melhor | 17.8% | -0.23 |
| **Longshot, Rebel Bowman** | Payoff | Não copia spells, não gera mana. Função nula em spellslinger | 48.0% | +0.40 |
| **Hexing Squelcher** | Proteção | Ward 2 vs counter. Lorehold precisa mais de gas que proteção | 40.9% | +0.35 |

### 🟢 Criaturas que Contribuem (7/11)

| Criatura | Por que fica | EDHREC | Trend |
|:---------|:-------------|:------:|:-----:|
| **Storm-Kiln Artist** | Treasure payoff — motor completo | 55.4% | +0.76 |
| **Lorehold, the Historian** | Comandante — loot + copy | N/A | N/A |
| **Galvanoth** ✅| Free spell do topo — spellslinger engine | 26.5% | +0.05 |
| **Weathered Wayfarer** | Land tutor — ramp early-game | Não EDHREC | N/A |
| **Esper Sentinel** | Draw condicional — melhor 1-drop branco | 32.5% | -0.54 |
| **Dragon's Rage Channeler** | Draw + GY synergy — spellslinger fuel | 39.5% | +0.46 |
| **Grand Abolisher** | Proteção preventiva — ninguém joga no seu turno | 11.7% | -0.27 |

---

## Seção 5: Cross-Referência Completa Deck vs EDHREC (7802 decks)

### 9 Cartas do Deck NÃO Estão no EDHREC

| Carta | CMC | Função | Risk |
|:------|:---:|:-------|:-----|
| **Oswald Fiddlebender** | 2 | Tutor | 🔴 Cortar — 0% |
| **Lorehold, the Historian** | 5 | Comandante | 🟢 Comandante (não se conta) |
| **Galadriel's Dismissal** | 1 | Protação | 🟡 Caso a caso |
| **Weathered Wayfarer** | 1 | Ramp | 🟡 Land tutor, útil |
| **Cavern of Souls** | 0 (land) | Land | 🟢 Utility land |
| **Dormant Volcano** | 0 (land) | Land | 🟡 Utility land |
| **Kor Haven** | 0 (land) | Land | 🟡 Utility land |
| **Valakut Awakening** | 3 (MDFC) | Land/spell | 🟢 Utility MDFC |
| **Emeria's Call** | 7 (MDFC) | Land/spell | 🟡 Caso a caso (43.4% como spell) |

### 📦 Top Collection Cards NOT in Deck (High EDHREC, in collection)

| Carta | EDHREC | Trend | Função | Coleção? |
|:------|:------:|:------|:-------|:--------:|
| **The Dawning Archaic** | 24.0% | **+5.31** | Rising star CMC 3 | ✅ qty=1 |
| **Chaos Warp** | 38.8% | +0.46 | Removal universal | ✅ qty=1 |
| **Arcane Bombardment** | 42.5% | +0.09 | Copy engine | ✅ qty=1 |
| **Soulfire Eruption** | 42.5% | +0.33 | Big spell dano | ✅ qty=1 |
| **Apex of Power** | 55.0% | +0.11 | Big spell explosivo | ✅ qty=1 |
| **Trouble in Pairs** | ~10% | N/A | Draw multiplayer | ✅ qty=1 |
| **Birgi, God of Storytelling** | ~15% | N/A | Draw/Hammers | ✅ qty=1 |
| **Promise of Loyalty** | 24.5% | +0.87 | Protection + draw | ✅ qty=1 |
| **Giver of Runes** | 19.5% | -0.30 | Protection 1-drop | ✅ qty=1 |
| **Seize the Spoils** | 16.6% | +1.23 | Treasure + loot | ✅ qty=1 |

---

## Seção 6: Análise de Tendências (EDHREC 7802 decks — 2026-05-31)

### 🔴 Declínio Confirmado no Deck (trend_zscore < -0.3)

| Carta | EDHREC | Trend | Severidade | Ação |
|:------|:------:|:------|:-----------|:-----|
| **Artist's Talent** | 21.1% | **-0.70** | 🔴 Grave | Cortar Ciclo #5 |
| **Esper Sentinel** | 32.5% | -0.54 | 🟡 Moderado | Manter (ainda staple, declínio lento) |
| **Gamble** | 12.2% | -0.50 | 🟡 Moderado | Monitorar |
| **Seething Song** | 16.0% | -0.49 | 🟡 Moderado | Manter (ramp CMC 3 necessário) |
| **Pearl Medallion** | 25.2% | -0.46 | 🟡 Moderado | Manter (apenas 23 brancas) |
| **Perch Protection** | 34.5% | -0.43 | 🟡 Moderado | Monitorar — CMC 6, caro |
| **Ruby Medallion** | 42.3% | -0.37 | 🟢 Leve | Manter (40+ spells vermelhas, importante!) |

⭐ **Mudança crítica vs v3.4:** Artist's TalentTrend -0.70 (era -0.71, declínio confirmado e estável). ESTA É A CARTA MAIS PROBLEMÁTICA COM MAIOR DECLÍNIO.

### Ascensão no Meta (trend_zscore > 2.0, base > 15%)

| Carta | EDHREC | Trend | Prioridade | No Deck? |
|:------|:------:|:------|:-----------|:---------|
| **Restoration Seminar** | 37.8% | **+9.14** | 🔴 Máxima | ✅ JÁ NO DECK |
| **Improvisation Capstone** | 49.0% | **+8.09** | 🔴 Máxima | ✅ JÁ NO DECK |
| **The Dawning Archaic** | 24.0% | **+5.31** | 🟡 Alta | ❌ FAZENDO FALTA |
| **Big Score** | 67.3% | +1.51 | 🟢 Manter | ✅ JÁ NO DECK |
| **Library of Leng** | 77.8% | +1.43 | 🟢 Manter | ✅ JÁ NO DECK |
| **Penance** | 41.8% | **+1.15** | 🟢 Manter | ✅ JÁ NO DECK |
| **Mizzix's Mastery** | 57.5% | +1.08 | 🟢 Manter | ✅ JÁ NO DECK |
| **Lightning Greaves** | 45.3% | +0.86 | 🟢 Manter | ✅ JÁ NO DECK |
| **Swords to Plowshares** | 69.0% | +1.22 | 🟢 Manter | ✅ JÁ NO DECK |

---

## Seção 7: O Que o Meta Faz Diferente (Análise 7802 Decks)

### A Grande Aliança Emergente: Copy Engines

O meta Lorehold está convergindo em **copy engines** como nunca antes:
- **Improvisation Capstone**: 49.0% (+8.09 trend) — explosão mais recente
- **Double Vision**: 46.6% (estável)
- **Galvanoth**: 26.5% (estável)
- **Arcane Bombardment** (42.5% — NÃO ESTÁ NO DECK, na coleção)

### Tesouro como Motor Primário

Tesouro ramp é a #1 estratégia:
- **Hit the Mother Lode**: 79.4% ✅ no deck
- **Big Score**: 67.3% ✅ no deck
- **Brass's Bounty**: 67.2% ✅ no deck
- **Storm-Kiln Artist**: 55.4% ✅ no deck (Ciclo #3)

### O que o deck NÃO tem que o meta tem:

| Carta | EDHREC | Função | Na Coleção? |
|:------|:------:|:-------|:-----------:|
| **The Dawning Archaic** | 24.0% | Rising star CMC 3 | ✅ qty=1 |
| **Chaos Warp** | 38.8% | Removal permanentes | ✅ qty=1 |
| **Arcane Bombardment** | 42.5% | Copy engine | ✅ qty=1 |
| **Lightning Greaves** | 45.3% | Protection | ✅ qty=1 |
| **Trouble in Pairs** | 10% | Draw multiplayer | ✅ qty=1 |

---

## Seção 8: As 7 Cartas Fantasmas — Status Atual (Pós-Ciclo #4)

As 7 double-null cards permanecem (Galadriel's Dismissal adicionada por Ciclo #4 — era double-null, agora no deck com tag ausente):

| Carta | Função Real | Risco de Auto-Swap | Decisão |
|:------|:------------|:-------------------|:--------|
| **Scroll Rack** | Engine do deck | 🔴 NUNCA cortar | Manter |
| **Penance** | Topdeck engine | 🔴 NUNCA cortar | Manter |
| **Grand Abolisher** | Proteção preventiva | 🟡 Alto | Manter |
| **Ruby Medallion** | Cost reduction (40+ red spells) | 🟡 Médio | Manter |
| **Pearl Medallion** | Cost reduction (23 white spells) | 🟡 Médio | Manter |
| **Taunt from the Rampart** | Goad mass | 🟢 Baixo — 35.2% EDHREC | Manter |
| **Galadriel's Dismissal** | Phase out creatures | 🟢 Baixo — CMC 1 situational | Manter |

**Nota:** Galadriel's Dismissal entrou no Ciclo #4 como duplo-nulo. Recomendação: manter como utility barata CMC 1.

---

## Seção 9: Análise das Wincons

O deck tem wincons fortíssimas:
- **Approach of the Second Sun** (63.8%) — CMC 7, fácil de copiar com Lorehold
- **Insurrection** (45.3%) — CMC 8, game-ending em multiplayer
- **Storm Herd** (75.1%) — CMC 10, tokens voando
- **Blasphemous Act** (40.4%) — Board wipe como "wincon" em board dead

**O problema:** Só 1 wincon "oficial" no DB (Approach de CMC=7). O deck tem ~5 wincons real, mas o DB conta apenas 1. Isso é uma limitação do single-tag classifier.

**Gap real:** O deck não tem wincons rápidas (CMC ≤ 4). Todas são CMC 7+. Isso contra-intuitivamente **ajuda** no problema do "sem play T3" porque não polui os slots CMC baixo.

---

## Seção 10: Plano de Ação — Ciclo #5 (BALANCED)

**Situação atual:** Sem Play T3 = 13.8% (zona BALANCED, marginalmente acima de 12%)
**Estratégia:** BALANCED — trocas com ΔCMC neutro, EDHREC alignment, resolver problemas restantes

### Troca 1: Artist's Talent (21.1%, trend -0.70) → Chaos Warp (38.8%, trend +0.46)
**Diagnóstico:** Artist's Talent está em declínio severo. A ativação nível 3 é muito lenta para Lorehold. CMC 2 mas raramente full value nos primeiros 6 turnos.
**Solução:** Chaos Warp é a melhor remoção universal de Commander. 38.8% EDHREC. Resolve QUALQUER permanente. CMC 3. Trend +0.46.
**CMC:** 2 → 3. **ΔCMC = +1** (aceitável em BALANCED)
**Da coleção:** ✅ qty=1

### Troca 2: Oswald Fiddlebender (0%) → The Dawning Archaic (24.0%, trend +5.31)
**Diagnóstico:** Oswald é tutor de artifact que não exploda, 0% EDHREC. Em 4 ciclos de análise, nunca teve razão para estar no deck. CMC 2, função nula.
**Solução:** The Dawning Archaic é a 2ª carta subindo MAIS rápido em todo Lorehold (trend +5.31). 24.0% EDHREC. CMC 3. Rising star com base >15% = sinal real, não ruído.
**CMC:** 2 → 3. **ΔCMC = +1** (aceitável em BALANCED)
**Da coleção:** ✅ qty=1
**⚠️** The Dawning Archaic base 24.0% > 15% E trend 5.31 > 5.0 = SINAL CONFIRMADO. Prioridade alta.

### Troca 3: Perch Protection (34.5%, trend -0.43) → Arcane Bombardment (42.5%, trend +0.09)
**Diagnóstico:** Perch Protection CMC 6, trend -0.43. Instants de proteção CMR são situacionais. O deck já tem 4 slots de proteção.
**Solução:** Arcane Bombardment é copy engine + dano crescente. 42.5% EDHREC. Com Lorehold = cada spell copiada = escala exponencialmente. Na coleção.
**CMC:** 6 → 2. **ΔCMC = -4.** MELHORIA — compensa os +1 do Ciclo #5.
**Da coleção:** ✅ qty=1

### Resultado Esperado Ciclo #5

| Métrica | Pós-Ciclo #4 | Pós-Ciclo #5 (est.) | Δ | Perfil |
|:--------|:------------:|:-------------------:|:-:|:------:|
| Lands | 35 | 35 | — | 36-38 🟡 |
| Ramp | 16 | 16 | — | 10-13 ✅ |
| Draw real | 6 | 6 | — | 8-12 🔴 |
| Removal | 4 | 5 | +1 | 4-6 ✅ |
| Board wipe | 5 | 5 | — | 3-5 ✅ |
| Big spells | ~24 | ~24 | — | ✅ |
| Copy engines | 2 | 3 | +1 | ✅ |

**Net ΔCMC: -2** (Dawning +1, Chaos +1, Bombardment -4 = -2). Sem Play T3 estimado: 12-13% (dentro do BALANCED).

**Meta-alignment estimado: ~82%.**

---

## Seção 11: Análise de matchup — Contexto Battle_LOG

O Battle_LOG (2026-05-31T00:38Z) mostra matchups reais vs 6 arquétipos:

| Matchup | Win Rate | Status |
|:--------|:--------:|:-------|
| vs Aggro (Krenko/Goblins) | 52.5% | ✅ Equilibrado |
| vs Control (Atraxa Superfriends) | 56.0% | ✅ Favorável |
| vs Combo (Kinnan cEDH) | 46.5% | 🟡 Equilibrado (precise de mais interaction) |
| vs Midrange (Korvold Value) | 52.5% | ✅ Equilibrado |
| vs Spellslinger (Niv-Mizzet) | 52.5% | ✅ Equilibrado |
| vs Stax (Winota Hatebears) | 52.5% | ✅ Equilibrado |
| **Average** | **52.1%** | ✅ **Saudável** |

**Análise:** Com 52.1% win rate médio, o deck está em excelente posição. Os matchups que perde (Combo -46.5%) melhorariam com Chaos Warp (remove combo pieces) e Arcane Bombardment (escala contra value engines). As trocas do Ciclo #5 são favoráveis neste contexto.

---

## Seção 12: A Pergunta Final — O Deck Está Bom Agora?

**O deck está COMPETITIVO e FUNCIONAL.** Ciclos #1-4 foram bem-sucedidos:

| Ciclo | Foco | Resultado |
|:------|:----|:----------|
| **#1** | Quality cuts (3 swaps) | 73.2% jogáveis, 12.4% sem play T3 |
| **#2** | Synergy (Dance, TOR, Big Score) | Motor 4/4 — mas T3 subiu para 16.5% |
| **#3** | Motor completion (Storm-Kiln, Capstone) | Motor 4/4 completo, EDHREC → 78% |
| **#4** | Defensive (T3 reduction, draw) | T3: 16.4%→13.8%, draw: 5→6 fontes |

**O que falta:**
1. **1-2 draw sources** (meta: 8-12, deck: 6) — mas Ciclo #5 com Bombardment + Dawning Archaic ajuda
2. **Removal diversity** — Chaos Warp resolve permanentes que removal atual não resolve (encantamentos, planeswalkers)
3. **Meta-alignment final** — 82% estimado pós-Ciclo #5, objetivo 85%

**O deck é competitivo B3.** Na coleta, as cartas para Ciclo #5 estão disponíveis. Não precisa comprar nada.

## Seção 13: Resumo Executivo para Evolution Oracle

**Top 3 swaps para Ciclo #5 (custo $0, all from collection):**

| # | Remove | % | Add | % | Impacto | ΔCMC |
|:-:|:-------|:-:|:------|:-:|:--------|:----:|
| 1 | **Artist's Talent** | 21.1% (▼-0.70) | **Chaos Warp** | 38.8% (▲+0.46) | 🔴 Removal universal | +1 |
| 2 | **Oswald Fiddlebender** | 0% | **The Dawning Archaic** | 24.0% (▲+5.31) | 🟡 Rising star, meta alignment | +1 |
| 3 | **Perch Protection** | 34.5% (▼-0.43) | **Arcane Bombardment** | 42.5% (▲+0.09) | 🟡 Copy engine + dano escalar | -4 |

**Net ΔCMC: -2.** Sem Play T3 estimado pós-Ciclo #5: **12-13%** (BALANCED).

**Se bracket 3 puro:** Swap adicional: The One Ring (8.5%, trend -0.32) → Trouble in Pairs
**Ciclo #5 estratégia: BALANCED.**

---

*Sempre cruze execução com simulação de mulligan ANTES de aplicar swaps. Dados EDHREC 7802 decks, captura 2026-05-31T06:00Z. Mulligan: seed=42, N=1000, definição rigorosa. 10 trocas aplicadas (Ciclos #1-4), 3 recomendadas para Ciclo #5.*
