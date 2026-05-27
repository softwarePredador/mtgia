# Plano de Correções — IA do ManaLoom (v2)

## Resumo dos Problemas Identificados

### 1. Classificador funcional (single-tag) — prioridade errada
**Arquivo:** `server/lib/ai/optimization_functional_roles.dart`
**Função:** `classifyOptimizationFunctionalRole()`
**Ordem atual:** draw > removal > wipe > ramp > tutor > protection
**Problema:**
- Smothering Tithe → draw (deveria ser ramp — "create a Treasure" é mais relevante que "draw a card")
- Boros Charm → removal (perde protection — "indestructible" é tão relevante quanto "destroy target artifact")
- Unexpected Windfall → draw (perde ramp — "create two Treasures" ignorado)

**Ordem correta:** land > wipe > protection > removal > ramp > draw > tutor

### 2. Multi-tag existe no Dart mas não é usado pela otimização
**Arquivo:** `server/lib/ai/functional_card_tags.dart`
**Função:** `inferFunctionalCardTags()` (já existe e funciona)
**Problema:** A pipeline de otimização (`otimizacao.dart`, `optimize_runtime_support.dart`) usa o single-tag `classifyOptimizationFunctionalRole()` em vez do multi-tag.
**Impacto:** Walking Ballista = removal (não wincon), Fierce Guardianship = só removal (não protection), The One Ring = draw (não engine)

### 3. Game Changers — detecção incompleta
**Arquivo:** `server/lib/edh_bracket_policy.dart`
**Problema:** 21/53 GCs detectados. Faltam 32, incluindo Rhystic Study, The One Ring, Cyclonic Rift, Smothering Tithe.
**Solução:** Adicionar `BracketCategory.gameChanger` com lista curada das 53 cartas oficiais.

### 4. EDHREC inclusion rate não usado na otimização
**Arquivo:** `server/lib/ai/optimize_runtime_support.dart`
**Problema:** Otimizador usa `meta_deck_count` (EDHTop16 torneios) mas não `edhrec_inclusion_pct` (EDHREC comunidade).
**Solução:** Adicionar campo `edhrec_inclusion_pct` no `CandidateQualityData`.

## Ordem de Implementação

1. Fix #1: Prioridade do classificador single-tag (baixo risco, alto impacto)
2. Fix #2: Adicionar heurísticas wincon/engine/combo_piece ao single-tag (médio risco, alto impacto)
3. Fix #3: Lista curada de Game Changers no bracket policy (baixo risco, médio impacto)
4. Fix #4: EDHREC inclusion na otimização (médio risco, médio impacto)

## Validação

Cada fix: `dart test` completo + `dart analyze` antes de commit.
