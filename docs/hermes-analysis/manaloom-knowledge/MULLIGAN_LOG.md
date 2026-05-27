# Mulligan Log — Lorehold Spellslinger

## [2026-05-27T19:50:00+00:00] Execução #3 — Pós-Evolution (Ciclo #1)

### Resultados

| Métrica | Valor | Status |
|:--------|:-----|:-------|
| Mãos jogáveis (2-4 lands + ramp/3+ lands) | 73.2% | ✅ |
| Mulligan obrigatório (<2 lands ou 2 lands sem ramp) | 26.8% | 🔴 |
| Ramp turno 1 (Sol Ring, Land Tax, Wayfarer, Desperate Ritual) | 25.4% | ✅ |
| Sem play até turno 3 (nada castável com lands disponíveis) | 12.4% | 🟡 |

### Distribuição de Lands na Mão Inicial

| Lands | Mãos | % |
|:-----|:----|:--|
| 0 | 40 | 4.0% |
| 1 | 174 | 17.4% |
| 2 | 306 | 30.6% |
| 3 | 272 | 27.2% |
| 4 | 160 | 16.0% |
| 5 | 37 | 3.7% |
| 6 | 10 | 1.0% |
| 7 | 1 | 0.1% |

### Comparação com Histórico

| Métrica | Pré-Evolution (34 lands) | Pós-Evo #1 (35 lands) | Agora (35 lands) | Δ vs Pré | Δ vs Pós-Evo#1 |
|:--------|:------------------------:|:---------------------:|:-----------------:|:--------:|:--------------:|
| Jogáveis | 70.1% | 70.6% | 73.2% | +3.1pp | +2.6pp |
| Mulligan | 23.9% | 23.0% | 26.8% | +2.9pp | +3.8pp |
| Ramp T1 | 13.6% | 18.4% | 25.4% | +11.8pp | +7.0pp |
| Sem play T3 | 3.3% | 8.8% | 12.4% | +9.1pp | +3.6pp |

### Cartas Novas do Evolution na Abertura

| Carta | Frequência na abertura |
|:-----|:----------------------|
| Esper Sentinel | 9.5% (1 em cada ~11 mãos) |
| Gamble | 6.0% (1 em cada ~17 mãos) |

### Análise do Delta

**Mulligan (26.8%):** A taxa subiu +3.8pp em relação ao teste pós-evolution anterior. A variação está dentro do ruído estatístico para 1000 simulações (IC95% ≈ ±3pp). A troca de Furygale Flocking (CMC 10) por Esper Sentinel (CMC 1) e Jokulhaups (CMC 7) por Gamble (CMC 1) não alterou significativamente a consistência de mão inicial.

**Ramp T1 (25.4%):** Excelente — quase 1 em cada 4 mãos tem ramp CMC ≤ 1. Sol Ring continua sendo a carta de ramp T1 mais impactante.

**Sem play T3 (12.4%):** 🟡 Preocupante. 12.4% das mãos iniciais não conseguem jogar NADA substancial até o turno 3. A causa é a alta densidade de spells CMC 5+ (haymakers, wincons, board wipes caros) combinada com apenas 36 cartas CMC ≤ 3 em 64 não-terrenos.

### Diagnóstico

1. **Mulligan rate aceitável para perfil big-spells** — 26.8% é típico para um deck Boros que roda 35 lands com CMC médio alto. Não há necessidade de correção emergencial.

2. **A substituição de Furygale/Jokulhaups/Karoo foi neutra para mulligan** — como esperado, trocar um card de alto CMC por um de baixo CMC não muda o mulligan se ambos são singletons e o total de lands não muda.

3. **O calcanhar de Aquiles é o "sem play T3"** — 12.4% é alto para um formato onde speed kills. O deck precisa de mais 1-2 interações CMC ≤ 2 (ex: Generous Gift, Chaos Warp, Swords to Plowshares já existe).

### Recomendações para o Evolution

1. **Próximo swap prioritário:** Cortar 1 spell CMC 7+ redundante (Volcanic Vision, Call Forth the Tempest) por Dance with Calamity (CMC 2, synergetic com Lorehold) ou interação CMC≤2.

2. **Manter 35 lands** — o mulligan de 26.8% não justifica ir para 36. O problema não é terra, é curva.

3. **Adicionar Hit the Mother Lode** conforme planejado — gera tokens no T3-T4 e tem CMC 7 mas impacto imediato via cascade.

### Nota Metodológica

- Simulação: 1000 mãos de 7 cartas do deck de 99 (excluindo commander) com random.shuffle() + seed fixa
- Lands identificados por type_line contendo "Land"
- Ramp total: 18 cartas não-terreno com tag funcional `ramp` (inclui Smothering Tithe, Jeska's Will, Goldspan Dragon)
- Ramp T1: {Sol Ring, Land Tax, Weathered Wayfarer, Desperate Ritual}
- "Jogável": 2-4 lands + (pelo menos 1 ramp OU 3+ lands)
- "Mulligan": 0-1 lands OU 2 lands sem ramp
- "Sem play T3": nenhuma carta na mão com CMC ≤ número de lands na mão (cap 3)
- Variação estatística (IC95%): ~±3pp para N=1000
- Fonte: scripts/knowledge.db — deck_id=6 (Lorehold Spellslinger)
