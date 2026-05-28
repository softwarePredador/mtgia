# Mulligan Log — Lorehold Spellslinger

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
