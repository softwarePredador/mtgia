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

### Conclusão

As trocas foram estatisticamente neutras para mulligan. Variação dentro do ruído (±3pp para N=1000). O ponto crítico real é "sem play T3" em 12.4% — deck precisa de mais spells baratas.
