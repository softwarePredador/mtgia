# Evolution Log — Lorehold

## [2026-05-27 03:05:39 UTC] Ciclo #1

### Primeiro ciclo completo do pipeline
- Scout: 4 rodadas em 2h, SCOUT_LOG.md
- Validator: 2 rodadas em 2h, VALIDATOR_LOG.md
- Mulligan: 1 rodada, MULLIGAN_LOG.md
- Evolution: 1a execucao

### Sintese dos Aprendizados

**SCOUT (3 decks EDHREC):**
- 4 staples 100% ausentes: Esper Sentinel, Dance with Calamity, Gamble, Hit the Mother Lode
- 30 cartas com 0% presenca externa — cortaveis
- Lands de referencia: fetch, dual, bond land

**VALIDATOR (metricas vs EDHREC):**
- 6 metricas 🟡 fora do range
- Lands 34 (min 36), Ramp 17 (max 13), Protection 7 (max 5), Wincons 3 (min 4)
- Draw=8 ✅, Recursion=5 ✅

**MULLIGAN (1000 simulacoes):**
- 70.1% jogaveis ✅
- 23.9% mulligan 🟡 (precisa +1-2 lands)
- 13.6% ramp T1 ✅, 3.3% sem play T3 ✅

### Mudancas Aplicadas (max 3)

1. **SAI:** Furygale Flocking → **ENTRA:** Esper Sentinel (draw)
   Justificativa: Furygale Flocking com 0% presenca externa. Esper Sentinel e staple 100% SCOUT.

1. **SAI:** Jokulhaups → **ENTRA:** Gamble (tutor)
   Justificativa: Jokulhaups com 0% presenca externa. Gamble e staple 100% SCOUT.

1. **SAI:** Karoo → **ENTRA:** Plains (land)
   Justificativa: Karoo com 0% presenca externa. Plains e staple 100% SCOUT.

### Contagem final: 100 cartas (confirmado)
Status: ✅ 100 cartas


### Impacto Esperado
- Lands: 34 → 35
- Draw: 8 → 9
- Board wipes: 6 → 5 (agora max 5 ✅)
- Tutor: 4 → 5
- Mulligan: esperado cair de 23.9% para ~20%

### Licoes Aprendidas
1. **Furygale Flocking (CMC 10):** CMC muito alto mesmo para big spells. Corte imediato.
2. **Jokulhaups (destroi lands):** Muito punitivo. Decks reais preferem Austere Command.
3. **Esper Sentinel (draw 1-drop):** Staple universal. Deveria ser auto-include em qualquer deck com branco.
4. **Gamble (tutor):** Tutor vermelho essencial para consistencia.

### Resultado Mulligan Pós-Swap (Ciclo #1) — 2026-05-27T19:50:00

| Métrica | Antes (34 lands) | Agora (35 lands) | Δ |
|:--------|:----------------:|:----------------:|:-:|
| Jogáveis | 70.1% | 73.2% | +3.1pp |
| Mulligan | 23.9% | 26.8% | +2.9pp |
| Ramp T1 | 13.6% | 25.4% | +11.8pp ✅ |
| Sem play T3 | 3.3% | 12.4% | +9.1pp 🟡 |

**Análise:** Swaps foram neutros no mulligan (variação dentro do ruído ±3pp). Ramp T1 disparou com Esper Sentinel e Gamble. O calcanhar de Aquiles é "sem play T3" — deck precisa de mais interação CMC≤2.

### Proximo Ciclo
- Adicionar Dance with Calamity e Hit the Mother Lode (sinergia Lorehold)
- Cortar Obliterate, Volcanic Vision, ou Call Forth the Tempest (redundância CMC 7+)
- **Prioridade:** Adicionar 1-2 interações CMC≤2 (Generous Gift, Chaos Warp) para reduzir sem_play_t3
