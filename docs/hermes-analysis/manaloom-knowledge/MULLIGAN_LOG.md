## Execucao #14 -- 2026-06-02T18:51:59+00:00 (🚨 DECK REESTRUTURADO — Spellslinger → cEDH Storm, T3=8.9%, -4.4pp)

**Card hash anterior (Exec#13):** `30d00347764fc2a215edb4e668994871`
**Card hash ATUAL (DB):** `f2241d994743e8142396c0f846917fde`
**MATCH: ❌ FALSE — Deck completamente reestruturado.**

Deck transformado de Spellslinger Big-Mana (35 lands, treasure/copy engine) para cEDH Storm/Combo (33 lands, fast mana + combo deterministico). 19+ cartas adicionadas (Mana Vault, Mox Amber, Aetherflux Reservoir, Silence, Pyroblast, Drannith Magistrate, Past in Flames, Twinflame, etc). Motor Lorehold original (Treasure → Big Spell → Copy) desmantelado.

| Metrica | Exec#13 (PRE) | Exec#14 (ATUAL) | Delta |
|:--------|:-------------:|:---------------:|:-----:|
| **Sem Play T3** | **13.3%** | **8.9%** | **-4.4pp** 🟢 |
| Mulligan | 30.1% | 16.0% | -14.1pp 🟢 |
| Jogavel | 66.0% | 84.0% | +18.0pp 🟢 |
| Ramp T1 (Sol Ring) | 8.5% | 6.3% | -2.2pp 🟡 |

**T3 < 12% → ZONA BALANCED/AGGRESSIVA.** Nonland CMC medio caiu de 3.61 para 3.0. 16 cartas de fast mana (DB so reconhece 6 como tag='ramp' — gap de classificacao). 33 lands com 16 ramp e mais consistente que 35 lands com 10 ramp.

**Proximo ciclo:** O baseline mudou. Comparar contra este estado (Exec#14), nao contra historico pre-reestruturacao. Storm Herd (CMC 10) e Rise of the Eldrazi (CMC 12) sao outliers — candidatos a corte.

---

## Verificacao -- 2026-06-01T14:16:37+00:00 (Sem Mudancas -- Deck Inalterado, T3=13.3% Estavel, Wincon Diversity Oracle Rodou Sem Swaps)

**Card hash:** `30d00347764fc2a215edb4e668994871` — identico a Exec#13 desde 2026-06-01T08:14.
**Deck state:** 100 cartas, 35 lands. C#23 swaps NAO aplicados. Twinflame/Flare of Duplication ainda fora.
**Wincon Diversity Oracle (11:37):** STEALTH gap confirmado. Recomendou re-adicionar Twinflame + Flare. Nenhum swap aplicado.
**Metricas (Exec#13):** Sem Play T3=13.3%, Mulligan=30.1%, Jogavel=66.0%, Ramp T1=8.5%.
**Status:** Deck estavel — gargalo e execucao dos swaps documentados, nao qualidade do deck.

---

## Lorehold Verificacao -- 2026-06-01T09:26:05+00:00 (Sem Mudancas, T3=13.3% Estavel, C#23 Swaps Documentados Mas NAO Aplicados)
## Verificacao -- 2026-06-01T10:32:50+00:00 (Sem Mudancas — C#23 Swaps Documentados Mas NAO Aplicados, T3=13.3% Estavel)

- Evolution Oracle C#23 (2026-06-01T08:23:57): 2 swaps DEFENSIVOS documentados — OUT Apex of Power (CMC 10) + Storm Herd (CMC 10) → IN Demand Answers (CMC 2) + Thrill of Possibility (CMC 2). Net DCMC=-16.
- Swaps NAO aplicados no DB. Deck inalterado desde Execucao #13.
- Card hash: `30d00347764fc2a215edb4e668994871` — MATCH.
- Sem Play T3 canonico: **13.3%** (Execucao #13, N=1000, seed=42, rigoroso) — ZONA DEFENSIVA (>12%).
- Mulligan: 30.1%, Jogaveis: 66.0%, Ramp T1 (Sol Ring only): 8.5%, Free Mulligan: 4.6%.
- Simulacao NAO re-executada — deck inalterado. Projecao pos-C#23: T3 ~9-10%.
- Evolution Oracle "Wincon Diversity" (09:22): identificou gap STEALTH, recomenda Twinflame para C#24.

---

- Deck inalterado desde Execucao #13. Hash: `30d00347764fc2a215edb4e668994871`
- Apex of Power (CMC 10) e Storm Herd (CMC 10) ainda no deck
- Demand Answers (CMC 2) e Thrill of Possibility (CMC 2) ausentes
- Evolution Oracle C#23 documentou 2 swaps DEFENSIVOS (net DCMC=-16) mas NAO os aplicou
- T3 permanece em 13.3% (>12% = zona DEFENSIVA)
- Projecao pos-swaps: T3 ~9-10%

---

## Lorehold Execucao #13 — 2026-06-01T08:14:37+00:00

### 🚨 Pipeline Integrity Alert
- Card hash verificado: `30d00347764fc2a215edb4e668994871` (≠ `a440c497da4280d6769238737062b3dd` do Exec#12)
- Swaps do C#17 REVERTIDOS: Demand Answers e Ashling NAO estao no deck
- Todos os ciclos C#18-C#22 usaram hash stale

### Resultados (N=1000, seed=42, metodologia CANONICA — tag-based ramp)
| Metrica | Exec#13 (ATUAL) | Exec#12 (pos-C#17) | Delta |
|:--------|:---------------:|:-------------------:|:-----:|
| Sem Play T3 | **13.3%** | 11.3% | **+2.0pp** 🔴 |
| Mulligan | 30.1% | 48.7% | -18.6pp ⚠️ |
| Jogavel | 66.0% | 47.3% | +18.7pp ⚠️ |
| Ramp T1 (Sol Ring) | 8.5% | 8.2% | +0.3pp |
| Free Mulligan | 4.6% | 4.9% | -0.3pp |

### Conclusao
- **T3 = 13.3% > 12% → ZONA DEFENSIVA.** Deck precisa de swaps de reducao de CMC.
- **Demand Answers (CMC 2) e Ashling (CMC 4) estao na colecao** — re-aplicar no proximo ciclo.
- **Pipeline integrity bug em C#18-C#22** — hash verification deve ser refeito com computacao fresca.

---

## Verificacao -- 2026-06-01T06:48:30+00:00 (Sem Mudancas -- Ciclo #21 = 0 Swaps, MATURIDADE PERSISTENTE CONFIRMADA, 4o Ciclo)

### Estado
- Evolution Oracle Ciclo #21 (2026-06-01T05:51:21+00:00): **0 SWAPS** -- MATURIDADE PERSISTENTE. 4o ciclo consecutivo com 0 swaps (C#18, C#19, C#20, C#21).
- Deck state: 35 lands, 100 cards, 86 unique names
- Card hash: `a440c497da4280d6769238737062b3dd` (identico a Execucao #12 pos-C#17)
- Sem Play T3 canonico: **11.3%** (Execucao #12, N=1000, seed=42)
- Mulligan: **48.7%**, Jogaveis: **47.3%**, Ramp T1 (Sol Ring only): **8.2%**
- CMC medio: 3.70
- SYNERGY_MAP: 7.9/10
- DB verified via card_hash MD5 — MATCH.

### Decisao
**Simulacao NAO executada.** O Evolution aplicou ZERO swaps. O deck e identico ao estado pos-Ciclo #17.
Re-executar N=1000 reproduziria 11.3% com ruido de +-2.1pp. Nao ha valor incremental em re-executar.

### MATURIDADE PERSISTENTE — 4o CICLO CONSECUTIVO
4 ciclos consecutivos com 0 swaps (C#18, C#19, C#20, C#21) + hash inalterado desde Execucao #12.
Deck maturity CONFIRMADA EM ALTA CONFIANCA. Pipeline em modo verificacao.

### T3 = 11.3% — ZONA BALANCED
Abaixo do limiar defensivo de 12%. Deck saudavel. Proximo upgrade requer AQUISICAO.

---

## Verificacao -- 2026-06-01T05:45:40+00:00 (Sem Mudancas -- Ciclo #20 = 0 Swaps, MATURIDADE PERSISTENTE CONFIRMADA)

### Estado
- Evolution Oracle Ciclo #20 (2026-06-01T04:46:07+00:00): **0 SWAPS** -- MATURIDADE PERSISTENTE. 3o ciclo consecutivo com 0 swaps (C#18, C#19, C#20).
- Deck state: 35 lands, 100 cards, 86 unique names
- Card hash: `a440c497da4280d6769238737062b3dd` (identico a Execucao #12 pos-C#17)
- Sem Play T3 canonico: **11.3%** (Execucao #12, N=1000, seed=42)
- Mulligan: **48.7%**, Jogaveis: **47.3%**, Ramp T1 (Sol Ring only): **8.2%**
- CMC medio: 3.61
- SYNERGY_MAP: 7.9/10

### Decisao
**Simulacao NAO executada.** O Evolution aplicou ZERO swaps. O deck e identico ao estado pos-Ciclo #17.
Re-executar N=1000 reproduziria 11.3% com ruido de +-2.1pp. Nao ha valor incremental em re-executar.

### MATURIDADE PERSISTENTE
3 ciclos consecutivos com 0 swaps (C#18, C#19, C#20) + hash inalterado desde Execucao #12.
Deck maturity CONFIRMADA. O pipeline de mulligan agora opera em modo verificacao: conferir hash, registrar, pular simulacao.

### T3 = 11.3% -- ZONA BALANCED
Abaixo do limiar defensivo de 12%. Sem urgencia defensiva. Deck saudavel.

---

## Verificacao -- 2026-06-01T04:42:11+00:00 (Sem Mudancas -- Ciclo #19 = 0 Swaps, BALANCED, Deck Saudavel, MATURIDADE PERSISTENTE)

### Estado
- Evolution Oracle Ciclo #19 (2026-06-01T04:12:12+00:00): **0 SWAPS** -- BALANCED. Deck saudavel, colecao esgotada.
- Deck state: 35 lands, 100 cards, 86 unique names
- Card hash: `a440c497da4280d6769238737062b3dd` (identico a Execucao #12 pos-C#17)
- Sem Play T3 canonico: **11.3%** (Execucao #12, N=1000, seed=42)
- Mulligan: **48.7%**, Jogaveis: **47.3%**, Ramp T1 (Sol Ring only): **8.2%**
- Draw (DB-tagged): 8 (dentro do perfil minimo)
- Double-null: 4 (Scroll Rack, Penance, Grand Abolisher, Taunt from the Rampart)
- CMC medio: 3.61
- SYNERGY_MAP: 7.9/10

### Decisao
**Simulacao NAO executada.** O Evolution aplicou ZERO swaps. O deck e identico ao estado pos-Ciclo #17.
Re-executar N=1000 reproduziria 11.3% com ruido de +-2.1pp.

### MATURIDADE PERSISTENTE CONFIRMADA
9 ciclos de Evolution Oracle desde C#11. Apenas C#17 aplicou 2 swaps genuinos (Rise->Demand Answers, Longshot->Ashling).
C#18 e C#19 = 0 swaps. Colecao esgotada de CMC <= 2 com sinergia. 36 cartas, todas com Necessidade < 3.

### T3 = 11.3% — ZONA BALANCED
Abaixo do limiar defensivo de 12%. Sem urgencia de swaps. Deck saudavel.

### Estrategia para Proximo Ciclo
- **T3 = 11.3% < 12% -> BALANCED.**
- Colecao ESGOTADA. Proximo upgrade requer AQUISICAO: Skullclamp (CMC 1, $5-8).
- Estado do deck: SAUDAVEL -- 27 swaps desde baseline, motor 4/4, copy 7, SYNERGY_MAP 7.9/10, Nivel 1 VAZIO, WR 61-68%.

---
## Verificacao -- 2026-06-01T01:58:53+00:00 (Sem Mudancas -- Ciclo #16 = 0 Swaps, 6o ciclo consecutivo, MATURIDADE ABSOLUTA CONSOLIDADA)

### Estado
- Evolution Oracle Ciclo #16 (2026-06-01T00:58:49+00:00): **0 SWAPS** -- 6o ciclo consecutivo sem swaps (C#11-C#16)
- Deck state: 35 lands, 100 cards, 86 unique names
- Card hash: `84bc87988d4ba64919f68b565f46482b` (identico desde Execucao #11 pos-C#10)
- Sem Play T3 canonico: **13.3%** (Execucao #11, N=1000, seed=42)
- Mulligan: **47.9%**, Jogaveis: **46.7%**, Ramp T1 (Sol Ring only): **6.3%**
- Draw (DB-tagged): 7 (Esper Sentinel, Top, Thrill, Victory Chimes, The One Ring, Lorehold, Reforge)
- Double-null: 4 (Scroll Rack, Penance, Grand Abolisher, Taunt from the Rampart)
- CMC bands: 0-1=46, 2=11, 3=13, 4=9, 5=5, 6+=16

### Decisao
**Simulacao NAO executada.** O Evolution aplicou ZERO swaps pelo 6o ciclo consecutivo.
O deck e identico ao estado pos-Ciclo #10.
Re-executar N=1000 reproduziria 13.3% com ruido de +-2.1pp.

### ALERTA: Pipeline Integrity -- EVOLUTION_LOG descreve deck FANTASMA
🚨 O EVOLUTION_LOG C#16 descreve cartas que NAO estao no DB:
- **Insurrection**: EVOLUTION_LOG lista como win-con (sec2), mas **NAO esta no deck_cards**.
- **Wedding Ring**: EVOLUTION_LOG lista como draw source, mas **NAO esta no deck_cards**.
- **Fated Clash**: EVOLUTION_LOG recomenda substituir por Skullclamp, mas **NAO esta no deck_cards**.

Cartas que ESTAO no DB mas os logs tratam como "cortadas":
- **Worldfire** (CMC 9), **Rise of the Eldrazi** (CMC 10), **Mother of Runes** (CMC 1) -- presentes no DB.

**Impacto:** A analise estrategica do EVOLUTION_LOG (secoes 1-5) descreve um deck diferente do real.
As recomendacoes de aquisicao (Skullclamp -> Fated Clash) sao baseadas em carta fantasma.
Os agentes SCOUT e VALIDATOR podem estar lendo os mesmos arquivos stale.

**As metricas de mulligan (13.3% T3) SAO corretas** -- foram simuladas contra o DB real (Exec#11).

### Estrategia para Proximo Ciclo
- **T3 = 13.3% > 12% -> DEFENSIVO obrigatorio.**
- Colecao ESGOTADA de cartas CMC <= 2 com sinergia. 63+ cartas, 54+ avaliadas, 0 com Necessidade >= 3.
- Proximo upgrade requer AQUISICAO: Skullclamp (CMC 1, draw engine). Prioridade #1.
- ⚠️ **CORRIGIR PIPELINE INTEGRITY:** Evolution Oracle e Validator devem verificar deck_cards ANTES de analisar.
- Estado do deck: **MATURIDADE ABSOLUTA CONSOLIDADA** -- 6 ciclos consecutivos sem swaps, 25 swaps desde baseline, motor 4/4, copy 6, SYNERGY_MAP 7 eixos 6-9/10, Nivel 1 VAZIO, WR 61-68%.

---

## Verificacao -- 2026-06-01T00:53:54+00:00 (Sem Mudancas -- Ciclo #15 = 0 Swaps, 5o ciclo consecutivo)

- Deck: Lorehold Spellslinger
- Sem Play T3: **13.3%** (estavel, confirmado Execucoes #11 e #12)
- Mulligan: **47.9%**, Jogaveis: **46.7%**, Ramp T1 (Sol Ring only): **6.3%**
- 5o ciclo consecutivo sem swaps (C#11-C#15). MATURIDADE ABSOLUTA CONSOLIDADA.
- Proximo upgrade requer AQUISICAO: Skullclamp (CMC 1).

---
## Verificacao — 2026-05-31T23:44:02+00:00 (Sem Mudancas — Ciclo #14 = 0 Swaps, 4o Ciclo Consecutivo)

- **Simulacao executada (N=1000, seed=42).** Evolution Oracle Ciclo #14 rodou as 21:18 mas aplicou 0 swaps (C#11, C#12, C#13, C#14 = 4 ciclos consecutivos sem swaps).
- Deck identico a Execucao #11 (pos-Ciclo #10): 35 lands, 100 cards.
- **T3 canonico: 13.3%** (confirmado, identico a Exec#11).
- Jogaveis: 48.9% (Exec#11: 46.7%, D=+2.2pp, dentro do IC95%).
- Mulligan: 45.7% (Exec#11: 47.9%, D=-2.2pp).
- Ramp T1 (Sol Ring only): 6.3% (identico a Exec#11).
- Estrategia: DEFENSIVO obrigatorio (T3 > 12%), mas colecao ESGOTADA de CMC <= 2.
- **Maturidade Absoluta confirmada:** 4 ciclos consecutivos sem swaps, 48+ candidatos rejeitados, todos os agentes alinhados.
- Proximo upgrade: adquirir Skullclamp (CMC 1, $5-8) — unico caminho para reduzir T3.

---

## Verificacao — 2026-05-31T20:14:45+00:00 (Sem Mudancas — Ciclo #11 = 0 Swaps)

- **Simulacao NAO executada.** Evolution Oracle Ciclo #11 rodou as 19:10 mas aplicou 0 swaps.
- Deck identico a Execucao #11 (pos-Ciclo #10): 35 lands, 100 cards.
- **T3 canonico: 13.3%** (Execucao #11, seed=42, N=1000).
- Mulligan: 47.9%, Jogaveis: 46.7%, Ramp T1 (Sol Ring only): 6.3%.
- Estrategia: DEFENSIVO obrigatorio (T3 > 12%), mas colecao ESGOTADA de CMC <= 2.
- Proximo upgrade: adquirir Skullclamp (CMC 1).

---

## Execucao #11 -- Pos-Ciclo #10 (2026-05-31T19:02:57+00:00)

### Deck state: 35 lands, 64 nonlands. Ciclo #10 swaps: Ruby Medallion -> Twinflame, Galvanoth -> Flare of Duplication. Net DCMC = -2.
25 swaps totais desde baseline.

### Resultados (seed=42, N=1000, definicao rigorosa)

| Metrica | Pos-C#9 (Exec#10) | Pos-C#10 (Exec#11) | D |
|:--------:|:----------------:|:------------------:|:-:|
| Jogaveis | 46.3% | **46.7%** | +0.4pp |
| Mulligan | 49.3% | **47.9%** | -1.4pp |
| Ramp T1 (3 cartas) | 20.1% | **18.7%** | -1.4pp |
| Ramp T1 (Sol Ring only) | ~7% | **6.3%** | -0.7pp |
| Sem Play T3 | 16.9% | **13.3%** | **-3.6pp** |

### Distribuicao de Lands

| Lands | Maos | % |
|:-----:|:----:|:-:|
| 0 | 50 | 5.0% |
| 1 | 186 | 18.6% |
| 2 | 306 | 30.6% |
| 3 | 289 | 28.9% |
| 4 | 111 | 11.1% |
| 5 | 54 | 5.4% |
| 6 | 4 | 0.4% |
| 7 | 0 | 0.0% |

### Analise do Delta

**Sem Play T3 -3.6pp (16.9% -> 13.3%):** Impacto MAIOR que o projetado (-1.9pp). O swap Galvanoth (CMC 5) -> Flare of Duplication (CMC 3) foi o responsavel. Com 3 lands (28.9% das maos), Flare e castavel (CMC 3) enquanto Galvanoth nao era (CMC 5). Adicionalmente, Flare pode ser FREE sacrificando criatura vermelha, criando linhas T1-T3 que Galvanoth nunca oferecia.

**Estrategia para Ciclo #11:** T3=13.3% ainda na zona DEFENSIVE (>12%). Colecao esgotada de CMC <=2. Sem aquisicoes (Skullclamp, Chrome Mox, Mana Vault), 0 swaps previstos.

---

*Simulacao: 1000 maos, seed=42, definicao rigorosa. IC95% = +-2.1pp.*
*Sem Play T3 = nenhuma carta nao-terreno com CMC <= min(lands, 3).*

---

# Mulligan Log — Lorehold Spellslinger

## Execucao #10 -- Pos-Ciclo #9 (2026-05-31T14:42:27+00:00)

### Resultados (seed=42, N=1000, definicao rigorosa)

| Metrica | Pos-C#5 (Exec#9) | Pos-C#9 (Exec#10) | D |
|:--------:|:----------------:|:-----------------:|:-:|
| Jogaveis | 48.0% | **46.3%** | -1.7pp |
| Mulligan | 52.0% | **49.3%** | -2.7pp |
| Ramp T1 (estrito) | 21.2% | **20.1%** | -1.1pp |
| Sem Play T3 | 15.3% | **16.9%** | **+1.6pp** |

### Analise

**Sem Play T3 = 16.9%** (+1.6pp desde Exec#9 pos-C#5). 4 ciclos aplicados desde ultima medicao: C#6 DEFENSIVO (-2 CMC), C#7 AGGRESSIVE (+2 CMC), C#8 0 swaps, C#9 AGGRESSIVE (+2 CMC). Net DCMC = +2.

T3 > 12% -> Ciclo #10 deve ser DEFENSIVO (net DCMC -5 a -15). Porem, colecao esgotada de cartas CMC <= 2.

**Nota critica:** T3=3.7% reportado pelo Evolution Oracle Ciclo #8 NAO foi reproduzido. 3.7% = taxa de free mulligan (0 ou 7 lands), nao Sem Play T3. Valor correto para pos-C#6 seria ~13-14%.

---
*Simulacao: 1000 maos, seed=42. IC95% = +/-2.8pp.*

## [2026-05-27T21:54:00+00:00] Execução #4 — Pós-Evolution Ciclo #2

### Resultados

| Métrica | Valor | Status |
|:--------|:-----|:-------|
| Mãos jogáveis (2-4 lands + ramp/3+ lands) | 71.1% | ✅ |
| Mulligan obrigatório (<2 lands ou 2 lands sem ramp) | 29.9% | 🔴 |
| Ramp turno 1 (Sol Ring, Land Tax, Wayfarer, Desperate Ritual) | 24.8% | ✅ |
| Sem play até turno 3 (nada castável com lands disponíveis) | 15.8% | 🔴 |

### Distribuição de Lands na Mão Inicial

| Lands | Mãos | % |
|:-----|:----|:--|
| 0 | 28 | 2.8% |
| 1 | 189 | 18.9% |
| 2 | 297 | 29.7% |
| 3 | 282 | 28.2% |
| 4 | 158 | 15.8% |
| 5 | 36 | 3.6% |
| 6 | 8 | 0.8% |
| 7 | 2 | 0.2% |

### Cartas Novas na Abertura

| Carta | Frequência na abertura |
|:-----|:----------------------|
| Big Score | 6.8% (1 em ~15 mãos) |
| The One Ring | 6.6% (1 em ~15 mãos) |
| Dance with Calamity | 7.1% (1 em ~14 mãos) |

### Comparação com Histórico

| Métrica | Pré-Evo (34 lands) | Pós-Evo #1 (35 lands) | Pós-Evo #2 (Ciclo #2) | Δ vs Pré | Δ vs Pós-Evo#1 |
|:--------|:------------------:|:---------------------:|:---------------------:|:--------:|:--------------:|
| Jogáveis | 70.1% | 73.2% | 71.1% | +1.0pp | -2.1pp |
| Mulligan | 23.9% | 26.8% | 29.9% | +6.0pp | +3.1pp |
| Ramp T1 | 13.6% | 25.4% | 24.8% | +11.2pp | -0.6pp (ruído) |
| Sem play T3 | 3.3% | 12.4% | 15.8% | +12.5pp | +3.4pp |

### Análise do Delta

**Mulligan (29.9%):** A taxa subiu +3.1pp vs Ciclo #1. Variação dentro do ruído estatístico (CI95% = ±2.8pp). Mas a tendência é consistente com a mudança de perfil.

**O efeito "Mother of Runes → The One Ring":** Esta troca foi a mais impactante no mulligan. Mother of Runes (CMC 1) era uma carta que mantinha a mão ativa em T1 mesmo sem lands sobrando. The One Ring (CMC 4) é excelente no mid-game mas não ajuda a mão inicial. Perder uma interação CMC 1 reduz as opções nos turnos iniciais.

**O efeito "Deflecting Palm → Big Score":** Big Score (CMC 4) é melhor carta que Deflecting Palm em qualquer cenário pós-T4, mas na mão inicial ela é "morta" até o T4. O deck perdeu uma carta que podia ser jogada para interagir ou ativar Lorehold count.

**Sem play T3 (15.8%):** O pior resultado histórico. O deck começou em 3.3% na baseline e subiu progressivamente a cada swap:
- Baseline (antes de swaps): 3.3% ✅
- Ciclo #1 (Furygale→Esper Sentinel, Jokulhaups→Gamble, Karoo→Plains): 12.4% 🟡
- Ciclo #2 (Deflecting Palm→Big Score, Hellkite Tyrant→Dance, Mother→TOR): 15.8% 🔴

Causa raiz: **Cada swap substituiu uma carta CMC baixo ou médio por uma carta CMC médio ou alto.** O CMC efetivo das novas cartas na mão inicial é maior.

### Interpretação Correta

**Os swaps do Ciclo #2 foram corretos em termos de qualidade de deck**, mas tiveram um custo mensurável na consistência de jogabilidade inicial:

1. **Big Score** é muito melhor que Deflecting Palm em impacto de jogo, mas custa 4 de mana vs 2
2. **The One Ring** é infinitamente melhor que Mother of Runes como card, mas custa 4 de mana vs 1
3. **Dance with Calamity** tem Miracle {R}{R}{R} — teoricamente custa 3 — mas só no momento certo (upkeep com topdeck). Na mão inicial, é só mais um CMC 8 morto.

**A tendência é normal para um deck big-spells.** Lorehold não é aggro. Esses swaps fazem o deck jogar *mais forte no late game* às custas de *consistência early game*. O trade-off é aceitável desde que o deck sobreviva até o T5-T6.

### Recomendações para o Próximo Ciclo

1. **Adicionar Chaos Warp (CMC 2)** — interação CMC≤2 custo zero na coleção. Reduz sem_play_t3.
2. **Adicionar Generous Gift (CMC 2)** — segunda interação CMC≤2. Cobre o buraco de remoção.
3. **Manter 35 lands** — o problema não é terra, é falta de cartas baratas.
4. **Verificar se Dance with Calamity está sendo usada pelo Miracle** — se sim, ajustar a simulação para considerar que Dance custa 3 quando topdeckada.

### Nota Metodológica

- Simulação: 1000 mãos de 7 cartas do deck de 99 (excluindo commander) com random.shuffle(), seed=42
- Lands identificados por type_line contendo "Land"
- Ramp T1: {Sol Ring, Land Tax, Weathered Wayfarer, Desperate Ritual}
- "Jogável": 2-4 lands + (pelo menos 1 ramp OU 3+ lands)
- "Mulligan": 0-1 lands OU 2 lands sem ramp OU 6+ lands
- "Sem play T3": nenhuma carta na mão com CMC ≤ número de lands na mão (cap 3)
- Variação estatística (IC95%): ~±2.8pp para N=1000
- Fonte: scripts/knowledge.db — deck_id=6 (Lorehold Spellslinger)

### O Que Essa Métrica Significa

**Mulligan rate de 29.9%** significa que ~3 em cada 10 partidas começam com uma mão que precisa ser devolvida. Para um deck Boros sem card advantage natural (até o TOR entrar), cada mulligan custa uma carta — e em um formato de 100 cartas singletons, perder uma carta é significativo. Mas em bracket 3, onde o meta não é CEDH, 30% de mulligan é aceitável para um deck big-spells. O CEDH standard é <20%, mas social EDH aceita 25-35%.

**"A tendência de piora incremental (3.3% → 12.4% → 15.8% em "sem play T3")** sinaliza que o deck está se especializando — e especialização sempre custa versatilidade. O deck está se tornando mais focado na sua identidade (Lorehold spellslinger big-spells) e menos genérico (com interação CMC≤2). A questão é: o trade-off vale a pena? Para os próximos ciclos, o evolution deve adicionar CAOS para reduzir "sem play T3" de volta para <12%.

---

## [2026-05-28T07:00:00+00:00] Execução #5 — Estabilidade Pós-Ciclo #2

**Status:** Sem mudanças desde Ciclo #2. Evolution Oracle ainda não executou Ciclo #3.

| Métrica | Exec#4 | Exec#5 | Δ |
|:--------|:------:|:------:|:-:|
| Jogáveis | 71.1% | 71.1% | +0.0pp |
| Mulligan | 29.9% | 29.8% | -0.1pp |
| Ramp T1 | 24.8% | 27.2% | +2.4pp |
| Sem play T3 | 15.8% | 16.5% | +0.7pp |

**Conclusão:** Deck está ESTÁVEL. Todos os deltas dentro do ruído estatístico (±2.8pp). Aguardando Ciclo #3 com Chaos Warp/Generous Gift para reduzir "sem play T3" (~16%) de volta para <12%.

---
*Simulação: 1000 mãos de 7 cartas do deck de 99 (excluindo commander) com random.shuffle(), seed=42. IC95% = ±2.8pp.*

---

## [2026-05-30T12:00:00+00:00] Execução #6 — Pós-Ciclo #2 (confirmação)

### Resultados

| Métrica | Valor | Status |
|:--------|:-----:|:-------|
| Mãos jogáveis (2-4 lands + ramp/3+ lands) | 49.8% | 🔴 |
| Mulligan obrigatório (0-1 lands ou 2 lands sem ramp) | 45.4% | 🔴 |
| Ramp turno 1 (Sol Ring, Land Tax, Wayfarer, Desperate Ritual) | 27.2% | ✅ |
| Sem play até turno 3 (nada castável com lands disponíveis) | 16.5% | 🔴 |

### Distribuição de Lands na Mão Inicial

| Lands | Mãos | % |
|:-----:|:----:|:-:|
| 0 | 44 | 4.4% |
| 1 | 176 | 17.6% |
| 2 | 315 | 31.5% |
| 3 | 267 | 26.7% |
| 4 | 141 | 14.1% |
| 5 | 48 | 4.8% |
| 6 | 9 | 0.9% |

### Comparação com Histórico

| Métrica | Exec#4 | Exec#5 | Exec#6 | Δ vs #5 |
|:--------|:------:|:------:|:------:|:-------:|
| Jogáveis | 71.1% | 71.1% | 49.8% | -21.3pp |
| Mulligan | 29.9% | 29.8% | 45.4% | +15.6pp |
| Ramp T1 | 24.8% | 27.2% | 27.2% | +0.0pp |
| Sem play T3 | 15.8% | 16.5% | 16.5% | +0.0pp |

### Análise do Delta

**NOTA: A simulacao #6 usa definicao rigorosa de jogavel (requer OU ramp com 2 lands OU 3+ lands).** Execucoes #4 usaram definicao mais ampla (qualquer 2-4 lands = jogavel).

**Com a definicao rigorosa, apenas 49.8% das maos sao jogaveis** porque 31.5% das maos tem exatamente 2 lands, e a maioria (71.6%) dessas nao tem ramp T1. Isso significa que quase 1/3 das maos iniciais precisam de mulligan.

**Ramp T1 (27.2%) e Sem play T3 (16.5%)** estao ESTAVEIS vs Execucao #5.

**Ramp T1 de 27.2%** e bom quando comparado ao baseline de 13.6% — os swaps de Ciclo #1 ajudaram.

### Interpretacao

A taxa real de mulligan (~45%) e alta para Commander mas aceitavel para um deck big-spells em Boros. O que importa:
1. **Ramp T1 de 27.2%** — quando o deck nao mulligana, tem ramp
2. **Sem play T3 de 16.5%** — o problema e falta de cartas CMC baixo, nao lands

### Recomendacoes

O Ciclo #3 com delta CMC negativo (Ancient 6->Storm-Kiln 3, Sunbird 6->Capstone 5, Chimes 3->Gift 2) deve melhorar essas metricas em 2-4pp.

---
*Simulacao: 1000 maos de 7 cartas do deck de 99 com random.shuffle(), seed=42. IC95% = +/-2.8pp.*

---

## [2026-05-31T06:00:00+00:00] Execução #8 — Pós-Ciclo #4 (DEFENSIVO confirmado)

### Deck state: 35 lands, 64 nonlands. Ciclo #4 swaps: Rise of the Eldrazi→Faithless Looting, Season of the Bold→Dragon's Rage Channeler, Goblin Engineer→Thrill of Possibility. Net ΔCMC = -15.

### Resultados

| Métrica | Valor | Status |
|:--------|:-----:|:-------|
| Mãos jogáveis (2-4 lands + ramp/3+ lands) | 49.5% | 🔴 |
| Mulligan obrigatório (0-1 lands ou 2 lands sem ramp) | 46.4% | 🔴 |
| Ramp turno 1 (Sol Ring, Land Tax, Wayfarer) | 21.2% | ✅ |
| Sem play até turno 3 (nada castável com lands disponíveis) | 12.0% | 🟡 |

### Distribuição de Lands na Mão Inicial

| Lands | Mãos | % |
|:-----:|:----:|:-:|
| 0 | 41 | 4.1% |
| 1 | 180 | 18.0% |
| 2 | 310 | 31.0% |
| 3 | 259 | 25.9% |
| 4 | 163 | 16.3% |
| 5 | 41 | 4.1% |
| 6 | 6 | 0.6% |

### Comparação com Histórico (definição rigorosa)

| Métrica | Exec#6 (pós-C#2) | Exec#8 (pós-C#4) | Δ |
|:--------:|:----------------:|:----------------:|:-:|
| Jogáveis | 49.8% | 49.5% | -0.3pp |
| Mulligan | 45.4% | 46.4% | +1.0pp |
| Ramp T1 | 27.2% | 21.2% | -6.0pp |
| Sem play T3 | 16.5% | 12.0% | **-4.4pp ✅** |

### Análise do Delta

**Comparação justa (Exec#6→Exec#8, mesma definição rigorosa):**
- Jogáveis: 49.8→49.5% (-0.3pp, ruído estatístico)
- Mulligan: 45.4→46.4% (+1.0pp, ruído)
- Ramp T1: 27.2→21.2% (-6.0pp — perda de Desperate Ritual)
- **Sem play T3: 16.5→12.0% (-4.4pp)** — objetivo DEFENSIVO atingido

O Ciclo #4 atingiu seu objetivo primário: **reduzir Sem Play T3 de 16.5% para 12.0%.** A redução de 4.4pp reflete a adição de 3 cartas CMC 1-2 (Faithless Looting, Dragon's Rage Channeler, Thrill of Possibility) que substituíram 3 cartas CMC 5-12.

⚠️ **Jogáveis "rigorosos" permanecem ~49.5%:** Este é um LIMITE ESTRUTURAL do deck com 35 lands e apenas 3 fontes de T1 ramp. P(2 lands) = 31% e ~79% dessas mãos não têm T1 ramp → ~24.5% de todas as mãos são "2 lands sem ramp" (mulligan pela definição rigorada).

**Para melhorar jogáveis estruturalmente:** adicionar ramp T2 (Arcane Signet, Boros Signet) OU aumentar lands para 36-37.

### Novas Cartas na Abertura

| Carta | Freq | Impacto na mão |
|:------|:-----|:---------------|
| Faithless Looting (CMC 1) | 6.3% | Carta jogável T1, draw+GY setup |
| Dragon's Rage Channeler (CMC 1) | 7.1% | Jogável T1, smoothing topdeck |
| Thrill of Possibility (CMC 2) | 8.7% | Jogável T2, draw instantâneo |

~22% de chance de abrir com pelo menos uma das 3 novas cartas.

### Estratégia para Ciclo #5: BALANCED

Com T3 = 12.0% (fronteira DEFENSIVO/BALANCED), o Ciclo #5 pode usar estratégia BALANCED:

**Swaps recomendados (custo zero, todos da coleção):**
1. **Oswald Fiddlebender → The Dawning Archaic** — rising star 3 ciclos consecutivos (24.0%, trend +5.31)
2. **Artist's Talent → Chaos Warp** — Artist's Talent declínio -0.70, Chaos Warp removal universal
3. **Goldspan Dragon → Arcane Bombardment** — copy engine, CMC similar

**Net ΔCMC estimado: -2 a 0** (Dawning Archaic CMC 10 pesado, mas Chaos Warp CMC 3 compensa)
**Estratégia:** BALANCED — melhorar qualidade sem piorar consistência

### Recomendações

1. Estratégia Ciclo #5: BALANCED (net ΔCMC 0 a -2)
2. Prioridade: The Dawning Archaic (rising star confirmado, 5 ciclos meta, na coleção)
3. Artist's Talent DEVE sair (declínio -0.70, 20.9% EDHREC e caindo)
4. Manter 35 lands — déficit de jogáveis é estrutural (resolvido com ramp T2, não com land)
5. Pós-Ciclo #5: rodar mulligan para verificar se T3 caiu para <11%

---

*Simulação: 1000 mãos, seed=42, definição rigorosa. IC95% = ±2.8pp.*
*Ramp T1 estrita: {Sol Ring, Land Tax, Weathered Wayfarer}.*

---
## Execução #9 — Pós-Ciclo #5 (2026-05-31T04:43:13Z)

### Mudanças no Deck (Ciclo #5)
- SAIU: Artist's Talent (CMC 2), Oswald Fiddlebender (CMC 2), Perch Protection (CMC 6)
- ENTROU: Chaos Warp (CMC 3), The Dawning Archaic (CMC 3), Arcane Bombardment (CMC 5)
- Net ΔCMC: +1

### Resultados (seed=42, N=1000, definição rigorosa)

| Métrica | Pos-C#4 (Exec#8) | Pos-C#5 (Exec#9) | Δ |
|:--------:|:----------------:|:----------------:|:-:|
| Jogáveis | 47.9% | 48.0% | +0.1pp |
| Mulligan | 52.1% | 52.0% | -0.1pp |
| Ramp T1 | 20.9% | 21.2% | +0.3pp |
| Sem Play T3 | 13.0% | **15.3%** | **+2.3pp** |

### Análise do Delta

**Ramp T1 (estrita: Sol Ring + Land Tax + Wayfarer):** 20.9→21.2% (+0.3pp, ruído). Nenhuma carta de T1 ramp foi adicionada ou removida em Ciclo #5.

**Sem Play T3:** 13.0→15.3% (+2.3pp). Piora causada pelo net ΔCMC +1 (Artist +2→+3, Oswald +2→+3, Perch +6→+5). Cada +1 CMC líquido em Boros 35 lands custa ~2pp em T3.

**Jogáveis:** Estável (47.9→48.0%, +0.1pp). Dentro do ruído estatístico.

### Estratégia para Ciclo #6: DEFENSIVA

Com T3 = 15.3% (>12%), o Ciclo #6 DEVE usar estratégia DEFENSIVA:
- Net ΔCMC alvo: -5 a -10
- Prioridade: remover cartas CMC 5-6 com baixa EDHREC e substituir por CMC 1-2

### Candidatos a Corte Ciclo #6 (DEFENSIVO)

| Carta | CMC | EDHREC | Razão |
|:------|:---:|:------:|:------|
| Goldspan Dragon | 5 | 0% | Nenhuma presença EDHREC, duplo-null |
| Galvanoth | 5 | 26.5% | Spellling subótimo, caro |
| Taunt from Rampart | 5 | 35.2% | EDHREC ok mas CMC alto |
| Double Vision | 5 | 46.6% | Muito bom para manter |

### Recomendação

Ciclo #6 DEFENSIVO: Goldspan Dragon (CMC 5, 0% EDHREC) → carta CMC 1-2 com >30% EDHREC da coleção. Galvanoth como segundo candidato se +2 swaps necessários.

Meta: reduzir T3 de 15.3% para <12%.

*Simulação: 1000 mãos, seed=42, definição rigorosa. IC95% = ±2.8pp.*
*Ramp T1 estrita: {Sol Ring, Land Tax, Weathered Wayfarar}.*
