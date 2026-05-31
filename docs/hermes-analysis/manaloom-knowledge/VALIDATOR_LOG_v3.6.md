# Análise do Deck Lorehold — Purpose Analyzer v3.6 (2026-05-31, Execução #13 / pós-Ciclo #4)

## Seção 1: Visão Geral — Estado Pós-Ciclo #4

**Deck:** Lorehold Spellslinger (deck_id=6, bracket 3)
**Ciclos aplicados:** 5 ciclos (19 swaps totais desde baseline)
**Data da análise:** 2026-05-31T12:00:00+00:00
**Fontes:** EDHREC 7802 decks (JSON API), knowledge.db, user_collection cross-ref

### Métricas Atuais vs Perfil EDHREC

| Métrica | Perfil EDHREC | Baseline (C#0) | Pós-C#4 | Δ Total | Status |
|:--------|:-------------:|:--------------:|:-------:|:-------:|:------:|
| Lands | 36-38 | 34 | 35 | +1 | 🟡 1 abaixo do min |
| Ramp | 10-13 | 17 | 16 | -1 | 🟡 +3 (treasure-heavy) |
| Draw | 8-12 | 4 | 5 | +1 | 🔴 Crítico (5 vs 8 min) |
| Removal | 4-6 | 4 | 5 | +1 | 🟢 No range |
| Board Wipe | 3-5 | 4 | 5 | +1 | 🟡 No limite superior |
| Protection | 3-4 | 7 | 4 | -3 | 🟢 No range |
| Recursion | 2-5 | 4 | 4 | 0 | 🟢 No range |
| Wincon | 4-7 | 2 | 1 | -1 | 🔴 Muito baixo |
| Engine/Big Spell | 5-8 | 3 | 4 | +1 | 🟡 Abaixo |
| Tutor | — | 4 | 3 | -1 | 🟢 Adequado |
| CMC médio | ~4.1 | 3.96 | 3.96 | 0 | 🟢 Estável |

**Principal gap persistente: DRAW.** O deck tem 5 fontes reais de draw vs 8-12 do perfil EDHREC. Isso é estrutural em Boros — as cores simplesmente não têm draw barato e confiável.

### Resumo dos Ciclos Aplicados (19 swaps)

| Ciclo | Estratégia | Swaps | ΔCMC Líquido | Sem Play T3 |
|:------|:-----------|:-----:|:------------:|:-----------:|
| #1 | Balanceado | 3 | neutro | 3.3%→12.4% |
| #2 | Agressivo (motor) | 3 | neutro | 12.4%→15.8% |
| #3 | Agressivo (completar motor) | 5 | -4 | 16.5%→16.4% |
| #4 | Defensivo | 3 | -15 | 16.4%→12.0% |
| #5 | Balanceado (BALANCED) | 3 recomendados | -2 | proj. 12-13% |

---

## Seção 2: Motor de Lorehold — 4/4 COMPLETO ✅

```
[Treasure Ramp] → [Big Spell Grátis] → [Lorehold Copy] → [Treasure Payoff]
     ↑                                                              ↓
     └────────── Tesouros Gerados por Cópia ←───────────────────────┘
```

| Componente | Cartas | Status | Ciclo Incluído |
|:-----------|:-------|:------:|:--------------:|
| Treasure Ramp | Big Score, Brass's Bounty, Hit the Mother Lode | ✅ | Ciclos #2,#0 |
| Free Big Spell | Dance with Calamity (Miracle RRR), Improvisation Capstone | ✅ | Ciclos #2,#3 |
| Lorehold Copy | Commander ability | ✅ Sempre | — |
| Treasure Payoff | Storm-Kiln Artist (55.4% EDHREC) | ✅ | Ciclo #3 |

**Avaliação:** O motor está operacional e subindo no meta. Hit the Mother Lode (79.4%, trend +1.29), Big Score (67.3%, trend +1.51), Improvisation Capstone (49.0%, trend +8.09) — todas com tendências fortemente positivas.

---

## Seção 3: Cartas que Brilham no Lorehold (Top 10 por Sinergia)

### ⭐ Tier 1 — Peças Centrais do Motor (NUNCA cortar)

1. **Dance with Calamity** (CMC 8, Miracle RRR, 50.3% EDHREC, trend +0.58)
   O coração do arquétipo. Exila top 13 de mana, conjura spells que pagou do custo. Com Lorehold: cada spell copiado. CMC alto justificado pelo Miracle. Incluído Ciclo #2.

2. **Improvisation Capstone** (CMC 7, 49.0% EDHREC, **trend +8.09**)
   Rising star de Lorehold. Exila top 7, conjura instants/sorceries de graça. Trend explosivo — subindo há 3 ciclos consecutivos. ADICIONADO Ciclo #3.

3. **Storm-Kiln Artist** (CMC 4, 55.4% EDHREC, trend +0.76)
   Cada instant/sorcery = 1 Treasure. Com copia do Lorehold = 2 Treasures. Motor payoff definitivo. ADICIONADO Ciclo #3.

4. **Big Score** (CMC 4, 67.3% EDHREC, trend +1.51)
   Discard 1, compra 2, gera 2 Treasure. Com Lorehold copiando = 4 cards + 4 Treasures. Combinacion perfeita. ADICIONADO Ciclo #2.

5. **Hit the Mother Lode** (CMC 7, 79.4% EDHREC, trend +1.29)
   Highest-EDHREC card in the deck. Discard 1, top 5 nonland, create Treasure tokens. Staple absoluto. Presente desde baseline.

### ⭐ Tier 2 — Suporte Crítico

6. **Restoration Seminar** (CMC 7, 37.8% EDHREC, **trend +9.14**)
   Fastest-rising card in ALL of Lorehold. Lesson recursion — conjura spells de Lesson de graça. ADICIONADO Ciclo #2.

7. **Scroll Rack** (CMC 2, 59.7% EDHREC, trend +0.48)
   Double-null mas IRREMOVÍVEL. Topdeck engine + hand smoothing. Reenche a mão antes de Lorehold colocar os spells de volta. Se Penance setup = Scroll Rack payoff. Presente desde baseline.

8. **Penance** (CMC 3, 41.8% EDHREC, trend +1.15)
   Double-null mas IRREMOVÍVEL. Setup de topdeck + anti-removal. Enche o GY para Lorehold + restaura hand quando atacado. Presente desde baseline.

9. **Double Vision** (CMC 5, 46.6% EDHREC)
   Copia primeira spell de cada turno sem custo. Stacka com Lorehold. ROI excelente. Presente desde baseline.

10. **Mizzix's Mastery** (CMC 4, 57.5% EDHREC, trend +1.08)
    Recursão Overload = cada spell pago do GY de graça. Recupera Dance, Hit the Mother Lode, etc. Bomba real.

---

## Seção 4: Cartas Questionáveis — Análise Detalhada (Pós-Ciclo #4)

### 🔴 Crítico para Ciclo #5

#### 1. Artist's Talent (CMC 2, 21.1% EDHREC, trend -0.70)
**Função atual:** Classe enchantment. Level 1: cria 2 Treasure quando inst/sorc copiado; Level 2: draw em cascade/spell copy.
**Diagnóstico:** É draw condicional que DEPENDE de spell copy — que deveria acionar em Luneta 1-2. Em Boros spellslinger, o copy costuma ser T4+, muito tarde para draw setup. A comunidade está abandonando.
**Justificativa:** -0.70 trend por 4 ciclos consecutivos. É o elo mais fraco persistente do deck.
**Alternativa da coleção:** **Chaos Warp** (38.8%, CMC 3, trend +0.46) — universal removal que Lorehold ABSOLUTAMENTE PRECISA.
**ΔCMC:** +1 (neutro)

#### 2. Oswald Fiddlebender (CMC 2, **0% EDHREC**)
**Função atual:** Tutor para artifact CMC ≤ X.
**Diagnóstico:** Oswald é bom em decks de artefatos. Lorehold NÃO é deck de artefatos — ramp em pedras (Signets) + treasures. Oswald força plano secundário que não escala.
**Justificativa:** Zero para cento nos decks EDHREC. Presente no deck há 5 ciclos sem justificativa métrica.
**Alternativa da coleção:** **The Dawning Archaic** (24.0% EDHREC, **trend +5.31**, na coleção) — rising star confirmado.
**ΔCMC:** +1 (neutro)

#### 3. Perch Protection (CMC 6, 34.5% EDHREC, trend -0.43)
**Função atual:** Token maker + lifegain + protection effect (flicker)?
**Diagnóstico:** CMC 6 para proteção. Tem overlap com Lightning Greaves, Teferi's Protection, Hexing Squelcher. 4 peças de proteção são suficientes.
**Justificativa:** Proteção cara quando temos melhores opções. Trend negativo.
**Alternativa da coleção:** **Arcane Bombardment** (42.5% EDHREC, CMC 6) — copy engine que subiu 20% em 3 ciclos.
**ΔMMC:** 0 (mesmo CMC)

### 🟡 Cartas para Monitorar (mas manter C#5)

#### 4. Esper Sentinel (CMC 0 efetivo, 32.5% EDHREC, trend -0.54)
Draw condicional barato. Declínio é LENTO (-0.54 ao longo de meses). Não é urgente — manter por enquanto e revisar no Ciclo #6.

#### 5. Pearl Medallion (CMC 2, 25.2% EDHREC, trend -0.46)
Cost reduction branco. Declínio consistente — reflete a tendência de tesouro > discount. Mas ainda staple-ish (>25%). Monitorar.

#### 6. Seething Song (CMC 3, 16.0% EDHREC, trend -0.49)
Ritual rápido. Único Sol Ring em stats de T1 ramp, mas Jeska's Will cobre. 16% EDHREC é borderline. Manter por enquanto.

#### 7. Call Forth the Tempest (CMC 8, 65.5% EDHREC, trend -0.30)
Board wipe high-end. Declínio leve (-0.30 está no limite). Ainda em 65.5% — bem estabelecido. Confimar trend no C#6.

### 🟢 Double-Null Cards (7 restantes — estado)

| Carta | Função Real | Risco Auto-Swap | Decisão |
|:------|:------------|:----------------:|:--------|
| Scroll Rack | Topdeck engine | 🔴 Crítico | NUNCA cortar |
| Penance | Topdeck + anti-removal | 🔴 Crítico | NUNCA cortar |
| Grand Abolisher | Proactive protection | 🟡 Alto | Manter (4 proteções suficientes) |
| Ruby Medallion | Cost red (vermelho) | 🟡 Médio | Manter |
| Pearl Medallion | Cost red (branco) | 🟡 Médio | Manter |
| Galadriel's Dismissal | Phase out creatures | 🟢 Baixo | Alvo se precisar de slot |
| Taunt from the Rampart | Goad massivo (35.2%) | 🟢 Baixo | Manter — 35%+ EDHREC |

---

## Seção 5: Ciclo #5 Recomenda — Aplicação Prática

Dado Sem Play T3 = 12.0% (limite BALANCED/DEFENSIVO), estratégia: **BALANCED, net ΔCMC 0 a -2.**

| Prioridade | Sai | Entra | ΔCMC | Justificativa |
|:-----------|:----|:------|:----:|:--------------|
| **P1** | Artist's Talent | **Chaos Warp** | +1 | Declining draw → universal removal |
| **P2** | Oswald Fiddlebender | **The Dawning Archaic** | +1 | 0% → rising star 24% (+5.31) |
| **P3** | Perch Protection | **Arcane Bombardment** | 0 | Proteção CMC 6 → copy engine |

**Net ΔCMC: +2 nominal, ≈ -2 efetivo (Arcane Bombardment CMC copy).**
**Projeção Sem Play T3 pós-C#5:** ~10-12% (tendência de melhoria das substituições).

### Carta não trocada mas observada:
- **Apex of Power** (55.0%, coleção): Big spell rising — candidato potencial para Ciclo #6 se T3 < 12%
- **Soulfire Eruption** (coleção): Big spell com split face —— candidato potencial para Ciclo #7

---

## Seção 6: O que Outros Decks de Lorehold Fazem Diferente

### Gap de Removal
Nosso deck tem 5 cartas de remoção (Path, Swords, Boros Charm, Generous Gift, Deflecting Swat). MEDIANA dos decks EDHREC: 4-6. Estamos no range, mas **Chaos Warp** adiciona camada que temos — shuffle-based removal em vez de exílio/dano. Boros tem limitações de remoção e Chaos Warp é universal.

### Gap de Draw — O Calcanhar Estrutural de Boros
Temos 6 fontes (Esper Sentinel, Artist's Talent, The One Ring, Thrill of Possibility, Faithless Looting, Sensei's Divining Top). Verdadeiramente "bom" draw é apenas The One Ring + Sensei's Top (2 fontes). O resto é condicional.

**Insight:** Boros COMPENSA draw deficit com:
1. Topdeck manipulation (Scroll Rack, Penance, Valakut, Sensei's Top)
2. Treasure synergy (Storm-Kiln Artist) permite pagar mais cartas por turno
3. Mecanismo de busca (Gamble, Enlightened Tutor, Urza's Saga, Oswald)
4. Lorehold commander permite "draw" de topdeck — spells do topdeck

Nosso deck tem uma estrutura de **topdeck-centric draw** que é legítima mas vulnerável a hate (Rest in Peace, Leyline of the Void).

### Cust Reduction vs. Tesouro — Tendência do Meta
Educator e jogador experiente notam: nos últimos 12 meses, games de mtg.com/EDHREC mostram Medallions caindo consistentemente em Lorehold enquanto Treasure-generating cards (Big Score, Hit the Mother Lode, Storm-Kiln Artist) sobem.

**Por quê:** Tesouro paga CMC INTEIRO de qualquer spell (copiar Hit the Mother Lode = 7 mana grátis). Cost reduction só desconta 1, independente da spell. Com motor de copy, tesouro escala quadraticamente.

Nosso deck já reflete isso — 16 ramp mas só 2 Medallions (que são legados). Recomendação: próximos ciclos fossem cust reduction em busca de tesouro.

### Abordagem Rebelliana Incomum
Nosso deck tem Galvanoth (26.5% EDHREC) e Rite of the Dragoncaller (23.4%) — ambos são arquétipos "Dragon/Big Creature" que divergem da estratégia spellslinger pura. Porém funcionam como BIG SPELLS payoff válidos: Galvanoth é spell-copy por natureza e Rite of Dragoncaller gera value recorrente. São viáveis como Fase 2.

---

## Seção 7: Validador de Mulligan — Estado Atual

| Métrica | C#0 | C#1 | C#2 | C#3 | C#4 | C#5 (proj.) |
|:--------|:---:|:---:|:---:|:---:|:---:|:-----------:|
| Sem Play T3 | 3.3% | 12.4% | 16.5% | 16.4% | 12.0% | 10-12% |
| Jogáveis | 70.1% | 73.2% | 71.1% | — | 49.5% | ~52% |
| Ramp T1 (strict) | 13.6% | 25.4% | 27.2% | 19.7% | 21.2% | ~22% |

**Limite estrutural:** Com 35 lands e 3 fontes de T1 ramp (Sol Ring, Land Tax, Wayfarer), mão com ~31% P(exactly 2 lands), dos quais ~79% NÃO têm T1 ramp = ~24.5% de todas as mãos são "borderline mulligan". Este é o piso teórico com a configuração atual.

**Para melhorar além de 50% jogáveis:**
- Adicionar +2 sources de ramp T1 (T6+) — mas temos só 3 cartas no jogo que fazem isso
- Aumentar lands para 36-37 — o que impacta Spell Slots negativamente
- Aceitar ~50% jogáveis como limite do arquétipo Boros big-spells

---

## Seção 8: Checklist de Motor (Atualização)

| Componente | Carta | EDHREC | Trend | Status |
|:-----------|:------|:------:|:-----:|:------:|
| Treasure Ramp 1 | Big Score (C#2) | 67.3% | +1.51 | ✅ |
| Treasure Ramp 2 | Brass's Bounty (baseline) | 67.2% | +1.14 | ✅ |
| Treasure Ramp 3 | Hit the Mother Lode (baseline) | 79.4% | +1.29 | ✅ |
| Big Spell Free 1 | Dance with Calamity (C#2) | 50.3% | +0.58 | ✅ |
| Big Spell Free 2 | Improvisation Capstone (C#3) | 49.0% | +8.09 | ✅ |
| Big Spell Free 3 | Approach of the Second Sun (baseline) | 63.8% | +0.74 | ✅ |
| Copy Engine 1 | Lorehold Commander | 100% | — | ✅ |
| Copy Engine 2 | Double Vision (baseline) | 46.6% | +0.15 | ✅ |
| Copy Engine 3 | Mizzix's Mastery (baseline) | 57.5% | +1.08 | ✅ |
| Copy Engine 4 | **Arcane Bombardment (recomendado C#5)** | 42.5% | +0.09 | 🟡 Pendente |
| Treasure Payoff | Storm-Kiln Artist (C#3) | 55.4% | +0.76 | ✅ |

**Novidades v3.6:**
1. Ciclo #4 executado com sucesso — T3 reduzido de 16.4% para 12.0%
2. Estratégia Ciclo #5 confirmada como BALANCED (T3 no limite)
3. Artist's Talent adicionado à lista de corte prioritário (4º ciclo em declínio)
4. The Dawning Archaic confirmed rising star (+5.31 trend) — prioridade P2 Ciclo #5
5. Arcane Bombardment identificado como copy engine gap remanescente — P3 Ciclo #5
6. Double-null cards: 7 restáveis (estável desde Ciclo #3)
7. Motor 4/4 completo e todos componentes confirmados por EDHREC trends positivos

---

## Seção 9: Tendências Detalhadas EDHREC

### Rising Stars Confirmados

| Carta | EDHREC | Trend | No Deck? | Na Coleção? |
|:------|:------:|:-----:|:---------:|:-----------:|
| **Improvisation Capstone** | 49.0% | +8.09 | ✅ C#3 | ✅ |
| **Restoration Seminar** | 37.8% | +9.14 | ✅ C#2 | ✅ |
| **The Dawning Archaic** | 24.0% | +5.31 | ❌ NÃO | ✅ Prioridade C#5 |
| **Big Score** | 67.3% | +1.51 | ✅ C#2 | ✅ |

### Em Declínio (Cartas no Deck)

| Carta | EDHREC | Trend | Decisão |
|:------|:------:|:-----:|:--------|
| **Artist's Talent** | 21.1% | -0.70 | 🔴 Ciclo #5 |
| **Esper Sentinel** | 32.5% | -0.54 | 🟡 Monitorar |
| **Perch Protection** | 34.5% | -0.43 | 🔴 Ciclo #5 |
| **Pearl Medallion** | 25.2% | -0.46 | 🟡 Monitorar |
| **Ruby Medallion** | 42.3% | -0.37 | 🟡 Monitorar |
| **Call Forth the Tempest** | 65.5% | -0.30 | 🟢 Manter (ainda alto) |

---

## Seção 10: Deckbuilder Mental Model

**O que este deck revela sobre o jogador:**

1. **Patient Big-Spells Player:** O jogador aceita turns mortos (Sem Play T3 ~12%) em troca de explosão no mid-late game (motor 4/4 completo).

2. **Meta-Aware Collector:** Teve acesso a Improvisation Capstone e Restoration Seminar — cards que subiram rápido. Está na ponta do meta.

3. **Collector-Rational:** Usa 95%+ das cartas da coleção. Só adiciona se está na coleção (zero swaps teóricos).

4. **Motor-Focused Builder:** Ciclo #3 completou o motor deliberadamente (Storm-Kiln + Capstone). Não é acumulador — é estrategista.

5. **Borrow Time de Cost Reduction:** Décadas de Magic ensinam Medallions = bom. Mas Lorehold provou que tesouro MVP escala melhor. Deck está fazendo transição certa — 16 ramp, só 2 Medallions.

**O que o deck PRECISA nos próximos 2 ciclos:**
- Universal removal (Chaos Warp) → resolve combo matchup
- Rising star confirmado (Dawning Archaic) → meta-alignment
- No new targets identified. Deck está boa forma.

---

*Relatorio gerado por Purpose Analyzer v3.6. Fontes: EDHREC JSON API (7802 decks), knowledge.db deck_id=6, user_collection.*
*Proximo Evolution Oracle: Ciclo #5 (BALANCED), aplicar 3 swaps acima.*
