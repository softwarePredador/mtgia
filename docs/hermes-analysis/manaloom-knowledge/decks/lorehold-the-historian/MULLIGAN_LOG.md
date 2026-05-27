# Mulligan Log — Lorehold

## [2026-05-27 03:01:58 UTC] Execucao #1

### Simulacao: 1000 maos de 7 cartas (deck de 99 sem commander)

### Resultados

| Metrica | Valor | Status |
|---------|-------|--------|
| Maos jogaveis (2-4 lands + play early) | 70.1% | ✅ |
| Precisam de mulligan (<2 ou >5 lands) | 23.9% | 🟡 |
| Tem ramp T1 (Sol Ring ou similar) | 13.6% | ✅ |
| Sem jogada ate turno 3 | 3.3% | ✅ |

### Distribuicao de Lands na Mao Inicial (7 cartas)
  0 lands:   47 (  4.7%) ████
  1 lands:  186 ( 18.6%) ██████████████████
  2 lands:  307 ( 30.7%) ██████████████████████████████
  3 lands:  275 ( 27.5%) ███████████████████████████
  4 lands:  147 ( 14.7%) ██████████████
  5 lands:   32 (  3.2%) ███
  6 lands:    6 (  0.6%) 
  7 lands:    0 (  0.0%) 


### Analise
- 🟡 ALERTA: 23.9% mulligan rate — aceitável mas poderia ser melhor com +1-2 lands.

## 2026-05-27T13:14:33+00:00 — Mulligan Analyst

**Status:** ✅ OK
**Deck analisado:** Lorehold Spellslinger (`deck_id=6`) — commander: Lorehold, the Historian
**Fonte dos dados:** SQLite `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`; main deck exclui `is_commander=1`.
**Integridade:** 99/99 cartas no main deck; commander_qty=1; registros `deck_cards`=86; quantidade total SQL=100.

### Resultado da simulação — 1000 mãos de 7 cartas

| Métrica | Resultado | Leitura |
|:--|--:|:--|
| Mãos jogáveis | 70.6% | 2-4 lands + pelo menos 1 spell CMC≤3 |
| Mãos que precisam mulligan | 23.0% | 0-1 lands ou 6-7 lands; threshold crítico >30% |
| Ramp turno 1 | 18.4% | inclui ramp/ritual não-land CMC≤1; Sol Ring/Land Tax/Wayfarer |
| Ramp turno 1-2 | 35.1% | ramp/ritual não-land CMC≤2 |
| Removal até turno 3 | 18.5% | removal/board_wipe CMC≤3 na mão inicial |
| Mãos que não fazem nada até T3 | 8.8% | sem spell castável CMC≤3 ou sem land |
| Lands médias na mão | 2.38 | distribuição abaixo |
| CMC médio da mão inicial | 2.60 | inclui lands como CMC 0 |
| CMC médio das spells na mão | 3.80 | só não-terrenos |
| Média de mulligans até mão jogável | 0.46 | aproximação por redraws frescos de 7, cap 6 |

### Distribuição de lands nas mãos

| Lands | Mãos | % |
|--:|--:|--:|
| 0 | 49 | 4.9% |
| 1 | 175 | 17.5% |
| 2 | 338 | 33.8% |
| 3 | 270 | 27.0% |
| 4 | 123 | 12.3% |
| 5 | 39 | 3.9% |
| 6 | 6 | 0.6% |
| 7 | 0 | 0.0% |

### Cartas reais que sustentam as métricas

- **Ramp T1 detectado (3 cartas únicas):** Land Tax, Sol Ring, Weathered Wayfarer.
- **Ramp T1-2 detectado (6 cartas únicas):** Arcane Signet, Desperate Ritual, Land Tax, Sol Ring, Talisman of Conviction, Weathered Wayfarer.
- **Removal CMC≤3 detectado (3 cartas únicas):** Boros Charm, Path to Exile, Swords to Plowshares.
- **Spells CMC≤3 por tag primária:** NULL=9, big_spell=1, draw=3, graveyard_synergy=1, protection=4, ramp=12, recursion=1, removal=3, tutor=3.

### Diagnóstico

- ✅ **Mulligan rate dentro do limite:** 23.0% ≤ 30%. A base de lands simulada (34 lands no DB, incluindo MDFCs como land) não aciona alerta crítico de mulligan.
- ✅ **Ação até T3 suficiente:** 8.8% ≤ 20%. O deck raramente passa os três primeiros turnos sem spell castável.
- 🟡 **Ponto fraco operacional:** removal CMC≤3 aparece em apenas 18.5% das mãos. Para um plano Boros big-spells/miracle, isso significa que muitas mãos dependem de sobreviver sem interação barata até setup de topo/ramp.
- 🟡 **Curva percebida alta:** CMC médio das spells na mão = 3.80; isso reflete a presença real de haymakers CMC 6-12. A simulação ainda considera a mão jogável se houver uma spell barata, mas a mão pode ficar pesada no jogo real se o ramp não aparecer.

### Recomendação prática

1. Não há necessidade de correção emergencial de lands pelo mulligan, mas o deck continua abaixo do profile Lorehold de 36-38 lands; considerar +1/+2 lands se testes reais mostrarem mana screw.
2. Prioridade P2: adicionar/remanejar 2 slots para interação CMC≤2 ou ramp CMC≤2; corte preferencial em spells CMC 7+ redundantes.
3. Próxima execução: comparar estes resultados com qualquer alteração no `deck_id` mais recente para medir delta de mulligan e ação até T3.

### Nota metodológica

- Simulação usa apenas dados reais do `knowledge.db`; não inventa tags. Ramp exclui lands mesmo quando `card_tags` contém `ramp`, seguindo a regra do projeto de não contar fetch/lands como ramp funcional.
- `castável até T3` é uma aproximação por CMC≤3 com pelo menos uma land; não simula cores, tapped lands, commander, draws dos turnos 1-3, London mulligan bottoming, nem custos alternativos/miracle.
