# Implementation Tasks — MTG Knowledge ↔ Code Cross-Reference

> **Gerado:** 2026-06-15  
> **Cron:** manaloom-knowledge-synthesis  
> **Método:** Cross-referência do conhecimento MTG (skills + logs + SQLite) contra código Dart vivo  
> **Skills carregados:** manaloom-mtg-strategy (v1.1.0), manaloom-mtg-domain (v2.18.0)  
> **Base de conhecimento:** SCOUT_LOG, VALIDATOR_LOG, MANA_BASE_VALIDATION_REPORT, GAME_CHANGERS.md, THEMES.md, GAMECHANGER_RESEARCH_REPORT.md, LOGIC_COHERENCE_REPORT, STRUCTURE_AUDIT.md, SQLite knowledge.db (15 tabelas)  
> **Branch:** codex/hermes-analysis-docs  
> **Novas tasks nesta execução:** 5 (1×P0, 3×P1, 1×P2)

---

## [P0] Underworld Breach ausente de `_knownInfiniteComboPieces`

**Conhecimento MTG:** Underworld Breach é um Game Changer (53 GCs do produto) e peça de combo infinito critical no cEDH (LED + Breach + Brain Freeze = win). É uma das cartas mais impactantes do formato competitivo.

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:405` — Underworld Breach em `officialGameChangerNamesForBracketPolicy` → recebe `gameChanger`.
- `server/lib/edh_bracket_policy.dart:347-351` — `_knownInfiniteComboPieces` só tem `thassa's oracle`, `demonic consultation`, `tainted pact`. **Underworld Breach AUSENTE**.
- `server/lib/edh_bracket_policy.dart:162-164` — `tagCardForBracket()` usa `_knownInfiniteComboPieces.contains(n)` para `infiniteCombo`. Breach nunca recebe esta tag.

**Gap:** Underworld Breach é detectado como GC mas não como peça de combo infinito. Orçamento `infiniteCombo` não o contabiliza.

**Impacto:** Bracket 3 (infiniteCombo=2): deck com Breach + Oracle + Consultation conta como 1 combo piece (Oracle) em vez de 2. GAMECHANGER_RESEARCH_REPORT.md Lacuna 3 confirma: `det=1` mascara cegueira do sistema.

**Risco:** P0 — Bracket sub-notifica densidade de combo.

**Ação recomendada:** Adicionar `'underworld breach'` a `_knownInfiniteComboPieces`. Considerar `'bolas\'s citadel'`.

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart
```

---

## [P1] Goldfish simulator trata terrenos tapped como untapped

**Conhecimento MTG:** Muitas non-basic lands entram tapped (Temples, bounce lands, check lands). VALIDATOR_LOG v3.23: deck Lorehold com 2/33 basics. Tapped = mana atrasada 1 turno. Domínio §13 Gap 9 confirma: T3 reportado é melhor que o real.

**Evidência no código:**
- `server/lib/ai/goldfish_simulator.dart:258-261` — `_isLand()` só checa typeLine.
- `server/lib/ai/goldfish_simulator.dart:352-367` — `_playLandIfPossible()` sempre incrementa `landsPlayed`, sem verificar `enters tapped` no oracle text.
- `server/lib/ai/goldfish_simulator.dart:328-349` — `_canPlayOnTurn()` assume todas as terras untapped.
- `server/lib/ai/optimization_validator.dart:98-114` — Monte Carlo usa GoldfishSimulator, propagando o erro.

**Gap:** Nenhum terreno é "tapped on entry". `turn1PlayRate`, `noPlayTurn3Rate` incorretos.

**Impacto:** Otimizador aceita swaps que pioram tempo de mana. Relatórios superestimam consistência.

**Risco:** P1 — Superestimação sistemática da performance early-game.

**Ação recomendada:** Adicionar verificação de oracle text em `_playLandIfPossible()`: se oracle contém `enters the battlefield tapped` ou `enters tapped`, não incrementar `landsPlayed` neste turno.

**Validação:**
```bash
cd server && dart test test/goldfish_simulator_test.dart && dart analyze lib/ai/goldfish_simulator.dart
```

---

## [P1] `classifyOptimizationFunctionalRole()` ignora functional_tags persistidas

**Conhecimento MTG:** Prioridade documentada: persisted tags → semantic_v2 → heuristic. Pipeline precisa de classificação consistente.

**Evidência no código:**
- `server/lib/ai/functional_card_tags.dart:455-465` — `summarizeFunctionalTagsForDeck()` prioriza `persistedTags` corretamente.
- `server/lib/ai/optimization_functional_roles.dart:55-85` — `classifyOptimizationFunctionalRole()` usa `_classifySemanticV2FunctionalRole()` como fonte principal, **ignorando `functional_tags` persistidas**.
- `server/lib/ai/optimization_functional_roles.dart:37-91` — `CardRoles.resolveCardFunctionalRoles()` existe como adapter unificado mas `classifyOptimizationFunctionalRole()` não o usa.

**Gap:** Adapter `CardRoles` existe mas não é usado pelo classificador principal do optimize.

**Impacto:** Mesma carta pode ter `draw` em deck analysis e `utility` no quality gate. LOGIC_COHERENCE_REPORT flagrou como P1.

**Risco:** P1 — Drift de classificação entre estágios do pipeline.

**Ação recomendada:** Modificar `classifyOptimizationFunctionalRole()` para usar `CardRoles.resolveCardFunctionalRoles()` internamente, passando `functionalTags` primeiro.

**Validação:**
```bash
cd server && dart test test/optimization_validator_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart
```

---

## [P1] `CandidateQualityData` sem taxa de inclusão EDHREC

**Conhecimento MTG:** % de inclusão EDHREC é sinal critical. Sol Ring 90.5%, Arcane Signet 88.1%. Metodologia SKILL.md §2.2 exige avaliar inclusão antes de swap.

**Evidência no código:**
- `server/lib/ai/candidate_quality_data_support.dart` — Schemas para `card_function_tags`, `card_role_scores`, `commander_card_synergy`. Sem `edhrecInclusionPct`.
- `server/lib/ai/commander_fallback_policy.dart` — Só usa `meta_deck_count` (EDHTop16 torneios).
- `server/lib/ai/optimize_filler_loader_support.dart` — Sem ponderação EDHREC.
- Busca por `edhrec_inclusion` em server/lib: **0 resultados**.
- Domínio §13 Gap 1: "CandidateQualityData não tem edhrec_inclusion_pct."

**Gap:** Sistema cego para o sinal mais usado pela comunidade Commander.

**Impacto:** Não distingue staple 40%+ de nicho 0%. Swap pode cortar staple em favor de lixo.

**Risco:** P1 — Decisões de otimização sem referência de popularidade/prova social.

**Ação recomendada:**
1. Adicionar `edhrecInclusionPct` a `CandidateQualityData`.
2. Popular de `card_meta_insights` (PG) ou `edhrec_rank` no cache.
3. Ponderar score: `role_match * 0.6 + edhrec_pct * 0.4`.

**Validação:**
```bash
cd server && dart test test/optimization_validator_test.dart
```

---

## [P2] `_knownValueEngineNames` muito restrito (5 nomes)

**Conhecimento MTG:** Value engines geram vantagem recorrente. GCs como Consecrated Sphinx, Field of the Dead, Smothering Tithe e The One Ring são value engines clássicas.

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:541-547` — Só 5 nomes: seedborn muse, tergrid, bolas's citadel, sensei's divining top, aetherflux reservoir.
- Consecrated Sphinx (line 363), Field of the Dead (line 370), Smothering Tithe (line 398), The One Ring (line 403): no GC list, NOT in value engines.
- `_looksLikeGameChangerCardAdvantage()` detecta alguns como `cardAdvantage` — categoria separada.
- GAMECHANGER_RESEARCH_REPORT.md Lacuna 2: Field of the Dead com falso positivo `fastMana` quando deveria ser `valueEngine`.

**Gap:** 4 GCs value engine não recebem categoria `valueEngine`. Orçamento `valueEngine` sub-notificado.

**Impacto:** Bracket 3 (valueEngine=6): Sphinx + Field + Ring sem consumir budget value engine. Só `gameChanger` (limite 3).

**Risco:** P2 — Imprecisão semântica. Mitigado por detecção `gameChanger`, mas categoria funcional perdida.

**Ação recomendada:**
```dart
const _knownValueEngineNames = <String>{
  'seedborn muse', 'tergrid, god of fright', 'bolas\'s citadel',
  'sensei\'s divining top', 'aetherflux reservoir',
  'consecrated sphinx', 'field of the dead', 'smothering tithe', 'the one ring',
};
```

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart
```

---

## Summary

| # | Prio | Título | Arquivo(s) | Risco |
|:-:|:----:|:-------|:-----------|:------|
| 1 | **P0** | Underworld Breach ausente de `_knownInfiniteComboPieces` | `edh_bracket_policy.dart:347-351,405` | 🔴 Quebra |
| 2 | **P1** | Goldfish trata tapped lands como untapped | `goldfish_simulator.dart:258-261,352-367` | 🟡 Incoerência |
| 3 | **P1** | classifyOptimizationFunctionalRole ignora persisted tags | `optimization_functional_roles.dart:55-85` | 🟡 Incoerência |
| 4 | **P1** | CandidateQualityData sem EDHREC inclusion | `candidate_quality_data_support.dart` | 🟡 Incoerência |
| 5 | **P2** | _knownValueEngineNames muito restrito (5→9) | `edh_bracket_policy.dart:541-547` | 🟢 Melhoria |

## Validação dos Dados

- **SQLite knowledge.db:** 15 tabelas (sem game_changers, sem tag_accuracy — conf. schema documentado)
- **card_oracle_cache GCs:** 28/31 amostrados (90.3%)
- **card_oracle_cache oracle_text vazio:** 4 cartas (Birds of Paradise DFC, Dwarven Trader, Memnite, Phyrexian Walker)
- **Deck 6 (Lorehold) tags:** ramp=41, draw=16, removal=7, protection=6, board_wipe=2, wincon=2 — perfil cEDH
