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

### Proximo Ciclo
- Adicionar Dance with Calamity e Hit the Mother Lode (sinergia Lorehold)
- Cortar Obliterate ou Season of the Bold
- Verificar se mulligan melhorou com +1 land
