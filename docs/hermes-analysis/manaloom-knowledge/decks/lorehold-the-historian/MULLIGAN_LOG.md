# Mulligan Log — Lorehold Spellslinger

## [2026-05-27 03:01:58 UTC] Execução #1 — Baseline (34 lands)

### Resultados

| Métrica | Valor | Status |
|---------|-------|--------|
| Mãos jogáveis (2-4 lands + play early) | 70.1% | ✅ |
| Precisam de mulligan (0-1 lands ou 2 sem ramp) | 23.9% | 🟡 |
| Ramp turno 1 (Sol Ring ou similar) | 13.6% | ✅ |
| Sem play até turno 3 | 3.3% | ✅ |

## [2026-05-27T13:14:33+00:00] Execução #2 — Pós-Evolution (35 lands)

| Métrica | Resultado | Leitura |
|:--------|:---------|:--------|
| Mãos jogáveis | 70.6% | 2-4 lands + pelo menos 1 spell CMC≤3 |
| Mulligan | 23.0% | 0-1 lands ou 6-7 lands |
| Ramp turno 1 | 18.4% | inclui ramp/ritual não-land CMC≤1 |
| Ramp turno 1-2 | 35.1% | ramp/ritual não-land CMC≤2 |
| Removal até turno 3 | 18.5% | removal/board_wipe CMC≤3 na mão |
| Sem play até T3 | 8.8% | sem spell castável CMC≤3 ou sem land |
| Lands médias na mão | 2.38 | distribuição normal para 35 lands |
| CMC médio das spells na mão | 3.80 | só não-terrenos |

## [2026-05-27T19:50:00+00:00] Execução #3 — Pós-Evolution confirmado

### Deck state: 35 lands, 64 nonlands, swaps aplicados (Furygale→Esper Sentinel, Jokulhaups→Gamble, Karoo→Plains)

| Métrica | Valor | Status |
|:--------|:-----|:-------|
| Mãos jogáveis | 73.2% | ✅ |
| Mulligan | 26.8% | 🔴 |
| Ramp turno 1 | 25.4% | ✅ |
| Sem play até T3 | 12.4% | 🟡 |

### Delta vs Execução #2

| Métrica | Antes | Agora | Δ |
|:--------|:-----|:-----|:-:|
| Jogáveis | 70.6% | 73.2% | +2.6pp |
| Mulligan | 23.0% | 26.8% | +3.8pp |
| Ramp T1 | 18.4% | 25.4% | +7.0pp |
| Sem play T3 | 8.8% | 12.4% | +3.6pp |

| ### Conclusão
|
|As trocas foram estatisticamente neutras para mulligan. Variação dentro do ruído (±3pp para N=1000). O ponto crítico real é "sem play T3" em 12.4% — deck precisa de mais spells baratas.|
|
|## [2026-05-27T21:54:00+00:00] Execução #4 — Pós-Evolution Ciclo #2
|
|### Deck state: 35 lands, 65 nonlands. Swaps: Deflecting Palm→Big Score, Hellkite Tyrant→Dance with Calamity, Mother of Runes→The One Ring
|
|| Métrica | Valor | Status |
||:--------|:-----|:-------|
|| Mãos jogáveis | 71.1% | ✅ |
|| Mulligan | 29.9% | 🔴 |
|| Ramp turno 1 | 24.8% | ✅ |
|| Sem play até T3 | 15.8% | 🔴 |
|
|### Delta vs Ciclo #1
|
|| Métrica | Pós-Evo #1 | Agora (Ciclo #2) | Δ |
||:--------|:---------:|:----------------:|:-:|
|| Jogáveis | 73.2% | 71.1% | -2.1pp |
|| Mulligan | 26.8% | 29.9% | +3.1pp |
|| Ramp T1 | 25.4% | 24.8% | -0.6pp (ruído) |
|| Sem play T3 | 12.4% | 15.8% | +3.4pp |
|
|### Conclusão
|
|Os swaps do Ciclo #2 tiveram um custo mensurável na consistência early-game. A troca de 3 cartas CMC 1-2 (Deflecting Palm, Mother of Runes) e CMC 6 (Hellkite) por 3 cartas CMC 4-4-8 (Big Score, TOR, Dance) elevou o perfil de CMC da mão inicial. O deck está mais forte no mid-late game (Dance com Miracle + Lorehold copy é devastador) mas mais vulnerável nos turnos 1-3. A tendência de piora em "sem play T3" (3.3% → 12.4% → 15.8%) precisa ser corrigida com interação CMC≤2 no próximo ciclo.|
||
|**Recomendação:** Adicionar Chaos Warp e/ou Generous Gift no Ciclo #3 para reduzir "sem play T3" de volta para <12%. Manter 35 lands.

## [2026-05-28T07:00:00+00:00] Execução #5 — Estabilidade Pós-Ciclo #2

### Status: Sem mudanças no deck desde Ciclo #2
Nenhuma evoluçōes nova aplicada. Evolution Oracle ainda não executou o Ciclo #3.
Simulação de confirmação: 1000 mãos, seed=42.

### Resultados

| Métrica | Valor | Status |
|:--------|:-----|:-------|
| Mãos jogáveis | 71.1% | ✅ |
| Mulligan | 29.8% | 🔴 |
| Ramp T1 | 27.2% | ✅ |
| Sem play T3 | 16.5% | 🔴 |

### Delta vs Execução #4

| Métrica | Exec#4 | Exec#5 | Δ |
|:--------|:------:|:------:|:-:|
| Jogáveis | 71.1% | 71.1% | +0.0pp |
| Mulligan | 29.9% | 29.8% | -0.1pp |
| Ramp T1 | 24.8% | 27.2% | +2.4pp |
| Sem play T3 | 15.8% | 16.5% | +0.7pp |

### Conclusão
Deck está ESTÁVEL. Todas as métricas dentro do ruído estatístico (±2.8pp). Nenhum swap novo para testar. Aguardando Evolution Oracle Ciclo #3 para aplicar interação CMC≤2 (Chaos Warp, Generous Gift) e reduzir "sem play T3" do nível crítico atual (~16%).

### O Que Essa Métrica Significa
**"Sem play T3" em 16.5%** significa que ~1 em cada 6 partidas abre sem nenhuma carta jogável nos 3 primeiros turnos. Para um deck Boros que depende de ativar triggers de legends/instants/sorceries, cada turno "morto" é um turno onde o comandante não gera valor. O deck precisa de mais cartas CMC≤2 que geram valor imediato (remoção, ramp, draw). O Ciclo #3 precisa resolver isso.|

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

### Comparação com Histórico (definição rigorosa)

| Métrica | Exec#6 (pós-C#2) | Exec#8 (pós-C#4) | Δ |
|:--------:|:----------------:|:----------------:|:-:|
| Jogáveis (rigoroso) | 49.8% | 49.5% | -0.3pp |
| Mulligan | 45.4% | 46.4% | +1.0pp |
| Ramp T1 estrito | 27.2% | 21.2% | -6.0pp |
| Sem play T3 | 16.5% | 12.0% | **-4.4pp ✅** |

### Análise

**O Ciclo #4 atingiu seu objetivo primário:** reduzir Sem Play T3 de 16.5% para 12.0% (-4.4pp). A estratégia DEFENSIVA com net ΔCMC = -15 funcionou.

A métrica de "jogáveis rigorosos" permanece ~49.5% — este é um **limite estrutural** de um deck com 35 lands e apenas 3 fontes de T1 ramp. P(2 lands) = 31%, dos quais ~79% não têm ramp T1 → ~24.5% de todas as mãos são "2 lands sem ramp" (mulligan pela definição rigorosa). Para melhorar: ramp T2 (Signets) ou +1-2 lands.

**Com T3 = 12.0%, o Ciclo #5 pode usar estratégia BALANCED** (net ΔCMC 0 a -2).

### O Que Essa Métrica Significa

**Sem Play T3 = 12.0%** significa que ~1 em cada 8 partidas abre sem nenhuma carta jogável nos 3 primeiros turnos. Melhorou de ~1 em 6 (pré-Ciclo #4). Para um deck Boros big-spells em bracket 3, 12% é aceitável — o deck compensa com poder explosivo no mid-late game (motor 4/4 completo).

**Jogáveis "rigorosos" = 49.5%** significa que cerca de metade das mãos iniciais precisam de mulligan pela definição estrita. Parece alto, mas lembrando: a definição rigorosa exige OU ramp T1 (só 3 cartas no deck) OU 3+ lands, para mãos com 2-4 lands. Mãos com 2 lands sem ramp (~24.5%) são marcadas como mulligan. Isso é intencional — sem ramp adicional, 2 lands em Boros é lento demais para competir.

**Próximo teste:** Após Ciclo #5 (BALANCED, com Dawning Archaic + Chaos Warp + Arcane Bombardment).

---

*Simulação: 1000 maos, seed=42, definicao rigorosa. IC95% = ±2.8pp.*

---
## Execução #9 — Pós-Ciclo #5 (2026-05-31T04:43:48Z)

### Resultados (seed=42, N=1000, definição rigorosa)

| Métrica | Pos-C#4 (Exec#8) | Pos-C#5 (Exec#9) | Δ |
|:--------:|:----------------:|:----------------:|:-:|
| Jogáveis | 47.9% | 48.0% | +0.1pp |
| Mulligan | 52.1% | 52.0% | -0.1pp |
| Ramp T1 | 20.9% | 21.2% | +0.3pp |
| Sem Play T3 | 13.0% | **15.3%** | **+2.3pp** |

Sem Play T3 ultrapassou 12% → Estratégia Ciclo #6: DEFENSIVA (net ΔCMC -5 a -10).
