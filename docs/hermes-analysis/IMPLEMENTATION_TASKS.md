# Implementation Tasks — MTG Knowledge ↔ Code Cross-Reference

> **Gerado:** 2026-06-04T11:00Z por ManaLoom Knowledge Synthesis (Cron)
> **Branch:** codex/hermes-analysis-docs
> **HEAD:** 22787279
> **Metodo:** Cruzamento do conhecimento MTG (Validator v3.25, Scout #38, CRON_STATUS, GAME_CHANGERS, Domain Skill) com codigo Dart
> **Base de conhecimento:** Purpose Analyzer v3.25 + Scout Exec#38 + Pipeline Audit v3.6 + Domain Skill Gaps 4/12/15/17

---

### [P1] `buildRoleTargetProfile`: Substituir hardcoded archetype targets por PG `commander_reference_profiles` + `theme_contextual_rules`

**Conhecimento MTG:** O pipeline Hermes (Purpose Analyzer v3.25) documenta que decks podem mudar de arquetipo (ex: spellslinger -> cEDH fast-mana-combo). O PG tem 48+ `commander_reference_profiles` com `role_targets` (min/max por role como lands 33-35, ramp 8-12, draw 6-10, etc.) e 27 `theme_contextual_rules` com faixas por funcao por tema. O Domain Skill (Gap 4) documenta que o validator deve usar ranges especificos por tema, nao genericos.

**Evidencia no codigo:** `server/lib/ai/optimize_runtime_support.dart:763-793` — `buildRoleTargetProfile(String targetArchetype)` usa apenas 3 arquetipos hardcoded (aggro, control, combo) com valores estaticos (`ramp: 10, draw: 10, removal: 8, interaction: 6, engine: 8, wincon: 4, utility: 8`). A funcao nunca consulta PG `commander_reference_profiles` nem `theme_contextual_rules`. O `optimize_runtime_support.dart:3820-3846` ja tem `loadCommanderReferenceProfileFromCache()` que carrega `profile_json` do PG — mas `buildRoleTargetProfile()` NAO a chama.

**Gap:** O optimize pipeline usa targets genericos que nao refletem o comandante especifico nem o tema do deck. Um deck cEDH Lorehold (ramp=19, draw=9, wincon=10) e avaliado contra targets de "combo generico" (ramp=11, draw=12, wincon=5) em vez dos ranges do perfil PG especifico. O filler loader (`loadOptimizeFillerCandidateStubs`, linha 2775-2848) usa `buildRoleTargetProfile` para calcular `surplus` (line 2831) — targets errados produzem recomendacoes de corte erradas.

**Impacto:** `P1` — O optimize recomenda cortes baseados em targets incorretos. No caso Lorehold cEDH, targets genericos de "combo" dizem ramp=11 (deck tem 19 surplus=8), sugerindo cortar 8 fontes de ramp que sao ESSENCIAIS para o funcionamento cEDH. Os targets do perfil PG especifico evitariam esse falso positivo.

**Acao recomendada:**
1. `buildRoleTargetProfile()` deve aceitar `commanderName` como parametro
2. Chamar `loadCommanderReferenceProfileFromCache()` para carregar `role_targets` do perfil PG
3. Fallback para `theme_contextual_rules` (ja carregadas via `ThemeContextualRulesService`) se perfil nao existir
4. Manter os valores hardcoded APENAS como ultimo fallback
5. Atualizar `buildSlotNeedsForDeck()` (line 795) para passar `commanderName`

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimize_runtime_support.dart
cd server && dart test test/ai/optimize_runtime_support_test.dart
```

---

### [P1] `ThemeContextualRulesService.validateDeck()`: Adicionar deteccao de archetype mismatch antes da validacao

**Conhecimento MTG:** O Purpose Analyzer v3.25 documenta que quando um deck e reconstruido para um arquetipo diferente (spellslinger -> cEDH fast-mana-combo), TODAS as metricas ficam fora do range do perfil PG original. Reportar 10/10 CRITs e enganoso — o problema nao e o deck, e o mismatch de arquetipo. O Domain Skill (Gap 4) recomenda: "Validator deve detectar mudanca de arquetipo (comparar `decks.archetype` contra os temas do perfil PG) e reportar como `ARCHETYPE MISMATCH` ao inves de CRITs individuais."

**Evidencia no codigo:** `server/lib/ai/optimization_validator.dart:52-64` — `ThemeContextualRulesService.validateDeck()` e chamado sem verificacao previa de compatibilidade de arquetipo. `server/lib/ai/theme_contextual_rules_service.dart:50-108` — O servico carrega regras por `theme` mas nao compara o `theme` do deck contra o `theme` esperado pelo perfil PG. O `loadCommanderReferenceProfileFromCache()` em `optimize_runtime_support.dart:3820` carrega `profile_json` que contem `themes` — mas ninguem compara esses temas com o `archetype` atual do deck.

**Gap:** Quando o deck Lorehold foi reconstruido de spellslinger para cEDH combo, `themeService?.validateDeck(archetype: archetype, ...)` recebeu `archetype='fast-mana-copy-combo-big-spells-no-premium-mox'` mas validou contra regras do tema `spellslinger` (porque o perfil PG e spellslinger). O sistema nao tem codigo que diga: "este deck nao e mais spellslinger, o perfil nao se aplica."

**Impacto:** `P1` — O validator produz CRITs em massa que enterram problemas reais. No caso v3.25, 10/10 metricas mostraram CRIT. O operador nao consegue distinguir "deck quebrado" de "deck de arquetipo diferente". Isso desperdica atencao e reduz confianca no validator.

**Acao recomendada:**
1. `ThemeContextualRulesService.validateDeck()` deve aceitar `profileThemes` como parametro opcional
2. Antes de validar, comparar `deckArchetype` contra `profileThemes`: se overlap < 50%, retornar `ThemeValidationResult(theme: 'mismatch', hasCriticalViolation: false)` com flag `archetypeMismatch: true`
3. No `optimization_validator.dart`, se `themeValidation.archetypeMismatch == true`, reportar como `ARCHETYPE MISMATCH` em vez de CRITs individuais
4. Adicionar campo `archetypeMismatch` ao `ThemeValidationResult`

**Validacao:**
```bash
cd server && dart analyze lib/ai/theme_contextual_rules_service.dart
cd server && dart analyze lib/ai/optimization_validator.dart
cd server && dart test test/ai/optimization_validator_test.dart
```

---

### [P2] `inferFunctionalRole()` (3o classificador): Consultar `card_function_tags` persistidas antes de heuristicas

**Conhecimento MTG:** O ManaLoom tem 3 classificadores diferentes no mesmo codebase: `inferFunctionalCardTags()` (multi-tag, 29 heuristicas), `classifyOptimizationFunctionalRole()` (single-tag, quality gate), e `inferFunctionalRole()` (single-tag, filler loader). O Domain Skill (Gap 6) documenta que o classificador tem "duplo nulo" — 10%+ de cartas invisiveis a ambos os classificadores. A resolucao do classificador (v3.25) melhorou tags no DB (ramp 6->19), mas o codigo Dart ainda nao consulta esses dados persistidos. O Logic Coherence Audit (2026-05-29) identificou drift entre `functional_card_tags.dart` e `optimization_functional_roles.dart` (P1 pendente).

**Evidencia no codigo:** `server/lib/ai/optimize_runtime_support.dart:2133-2200` — `inferFunctionalRole()` e um TERCEIRO classificador, separado dos outros dois. Ele usa APENAS heuristicas de oracle text (ramp via `add {`, draw via `draw a card`, removal via `destroy target`, interaction via `counter target`, wincon via `you win the game`). NENHUMA consulta a `card_function_tags` (PG) ou `card_tags` (SQLite). NENHUM uso de `semantic_tags_v2`.

**Gap:** `inferFunctionalRole()` e chamado pelo filler loader (`loadOptimizeFillerCandidateStubs`, linha 2802-2807) para classificar TODAS as cartas do deck durante a deteccao de fillers. Cards como Smothering Tithe (treasure ramp) sao classificados como `utility` porque nao contem `add {` nem `draw a card` — caem no fallback da linha 2199. Cards como Aetherflux Reservoir (wincon, "pay 50 life") nao sao detectados como wincon porque nao contem "you win the game".

**Impacto:** `P2` — O filler loader identifica cards para remocao baseado em classificacao incorreta. Cards classificados como `utility` quando sao na verdade `ramp` ou `wincon` podem ser erroneamente sugeridos para corte pelo optimize.

**Acao recomendada:**
1. `inferFunctionalRole()` deve aceitar parametro opcional `Map<String, dynamic>? cardData` com dados completos da carta
2. Primeiro verificar `cardData['functional_tag']` (do SQLite `deck_cards`) — se disponivel, usar como fonte primaria
3. Segundo, verificar `cardData['semantic_tags_v2']` (como `classifyOptimizationFunctionalRole` ja faz)
4. Terceiro, cair para heuristicas de oracle text (fallback atual)
5. Alternativa: unificar os 3 classificadores em uma unica funcao `classifyCardRole()` com prioridade explicita

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimize_runtime_support.dart
cd server && dart test test/ai/optimize_runtime_support_test.dart
```

---

### [P2] `card_deck_profiles` (PG, 1299 perfis): Integrar ao backend — tabela nunca lida

**Conhecimento MTG:** O pipeline Python importa analises de deck para a tabela PG `card_deck_profiles` (1299 perfis de carta por deck, com campos: `card_name`, `role_in_deck`, `importance_level`, `wincon_total_score`, `speed_score`, `resilience_score`, `stealth_score`). O Scout (#38) usa esses scores para priorizar wincons (RAPIDAS S>=6, IMBATIVEIS R>=7, INVISIVEIS ST>=7). O Domain Skill documenta que `card_deck_profiles` "NOT yet read by backend".

**Evidencia no codigo:** `rg "card_deck_profile" server/lib` -> **ZERO resultados**. A tabela existe no PG com 1299 linhas, e populada pelo script Python `scripts/import_card_profiles.py`, mas NENHUM arquivo Dart faz query nela. O `AggressiveCandidateQualitySignal` (optimize_runtime_support.dart:2433-2479) tem campos `roleScore`, `synergyScore`, `functionConfidence` — mas todos sao populados de outras fontes (card_role_scores, commander_card_synergy), nao de `card_deck_profiles`.

**Gap:** 1299 perfis de carta analisados pelo pipeline Python (com scores de wincon, engine, importancia estrategica) estao disponiveis no PG mas sao completamente ignorados pelo backend Dart. O optimize pipeline nao sabe, por exemplo, que Guttersnipe tem `wincon_total_score=19, stealth_score=8` (INVISIVEL) ou que Mizzix's Mastery tem `resilience_score=7` (IMBATIVEL).

**Impacto:** `P2` — O optimize pipeline perde a capacidade de distinguir wincons "invisiveis" (stealth alto) de wincons "frageis" (resilience baixa). O quality gate nao pode aplicar regras como "nao cortar INVISIVEIS (ST>=7)" ou "priorizar IMBATIVEIS (R>=7)".

**Acao recomendada:**
1. Criar `card_deck_profiles_service.dart` com query que carrega perfis por `deck_id`
2. Integrar ao `AggressiveCandidateQualitySignal` como campos opcionais: `winconSpeed`, `winconResilience`, `winconStealth`
3. No `_scoreAggressiveCandidateQualityPair()` (line 2501), adicionar bonus: `stealth >= 7` -> +15, `resilience >= 7` -> +15
4. No quality gate, adicionar regra: nao cortar cartas com `importance_level >= 4`

**Validacao:**
```bash
cd server && dart analyze lib/ai/card_deck_profiles_service.dart
cd server && dart test test/ai/candidate_quality_test.dart
```

---

### [P2] `GoldfishSimulator`: Adicionar verificacao de ramp/mana rocks na definicao de keepable

**Conhecimento MTG:** O pipeline de simulacao de mulligan (Execucoes #4-#15) define mao "jogavel" como: **"2-4 lands AND (ramp >= 1 OR lands >= 3)"**. Esta definicao rigorosa reconhece que maos com 2 lands e SEM ramp sao efetivamente nao-jogaveis (~22% das maos em um deck de 35 lands). A diferenca entre a definicao permissiva (2-5 lands, sem ramp) e a rigorosa e de ~20pp na taxa de keepable, afetando diretamente as recomendacoes de swap. O Domain Skill documenta a metodologia completa.

**Evidencia no codigo:** `server/lib/ai/goldfish_simulator.dart:131,156` — A definicao atual e puramente baseada em lands: `if (landsInHand >= 2 && landsInHand <= 5) keepableHands++`. Nao ha NENHUMA verificacao de ramp, mana rocks, ou aceleracao. `server/lib/ai/goldfish_simulator.dart:340-354` — `_playLandIfPossible()` nao rastreia se a terra entra tapped.

**Gap:** O `GoldfishSimulator` superestima a taxa de keepable em ~20pp (2-5 lands = ~71% vs rigoroso = ~50%). O `consistencyScore` (line 32-39) pesa `keepableRate` como 40% do score total — keepable errado produz consistencyScore errado. O quality gate (`optimization_quality_gate.dart:412-415`) usa `monteCarlo.consistencyScore` para aprovar/rejeitar swaps.

**Impacto:** `P2` — Swaps que pioram a consistencia real podem ser aprovados porque o consistencyScore esta inflado. Exemplo: trocar um mana rock CMC 2 por uma carta CMC 4 sem ramp. O GoldfishSimulator atual diria que a mao ainda e "keepable" (2-5 lands), mas na definicao rigorosa a mao com 2 lands e sem ramp NAO e keepable — e remover o mana rock torna essa situacao mais provavel.

**Acao recomendada:**
1. Adicionar `_isManaSource()` helper que verifica se uma carta produz mana (ramp, rock, ritual)
2. Alterar keepable para: `landsInHand >= 2 && landsInHand <= 4 && (rampCount >= 1 || landsInHand >= 3)`
3. `rampCount` = contar cartas na mao que sao fontes de mana (via `_isManaSource()`)
4. Manter flood em `landsInHand >= 6` e screw em `landsInHand <= 1`

**Validacao:**
```bash
cd server && dart analyze lib/ai/goldfish_simulator.dart
cd server && dart test test/ai/goldfish_simulator_test.dart
```

---

## Resumo de Tasks Novas (2026-06-04 @ 22787279)

| # | Prioridade | Task | Origem |
|:-:|:----------|:-----|:-------|
| 1 | P1 | `buildRoleTargetProfile`: Usar PG `commander_reference_profiles` + `theme_contextual_rules` em vez de hardcoded | Validator v3.25 (archetype mismatch) |
| 2 | P1 | `ThemeContextualRulesService.validateDeck()`: Detectar archetype mismatch antes da validacao | Validator v3.25 + Domain Skill Gap 4 |
| 3 | P2 | `inferFunctionalRole()`: Consultar `card_function_tags` persistidas antes de heuristicas | Domain Skill Gap 6 + Logic Coherence Audit |
| 4 | P2 | `card_deck_profiles` (1299 perfis PG): Integrar ao backend (tabela nunca lida) | Scout #38 + Domain Skill |
| 5 | P2 | `GoldfishSimulator`: Adicionar ramp/mana rocks na definicao de keepable | Pipeline Mulligan (Execucoes #4-#15) + Domain Skill Gap 9 |

## Tasks Anteriores (ainda pendentes das execucoes 2026-06-04 @ d2ca5234 e @ 498eb1a8)

| # | Prioridade | Task |
|:-:|:----------|:-----|
| 1 | P1 | Bracket Policy: Adicionar 7 categorias ao `BracketCategory` enum (29/53 GCs nao detectados) |
| 2 | P1 | `classifyOptimizationFunctionalRole`: Usar `functional_tags` persistidas como fonte primaria |
| 3 | P1 | Quality Gate: Integrar `theme_contextual_rules` nas decisoes de swap |
| 4 | P2 | Candidate Quality: Adicionar `edhrec_inclusion_pct` como metrica |
| 5 | P2 | Candidate Quality: Adicionar `edhrec_trend_zscore` como fator de scoring |
| 6 | P2 | Deck Import: Re-classificar automaticamente cartas com `functional_tag='unknown'` |
| 7 | P1 | Battle Simulator: Implementar regras Commander (stack, multiplayer, etc.) |
| 8 | P1 | Goldfish Simulator: Tapped lands (complementa Task #5 nova) |
| 9 | P1 | Optimize/Archetypes: Owner-scoped deck queries |
| 10 | P2 | Activation Funnel: Sync `_allowedEvents` app-backend |

> **Nota:** Tasks #5 nova (keepable com ramp) e #8 pendente (tapped lands) sao complementares — ambas melhoram o `GoldfishSimulator`. Implementar juntas.
> **Nota:** Tasks #4 nova (card_deck_profiles) e #4/#5 pendentes (edhrec_inclusion_pct + trend_zscore) sao complementares — todas populam e leem `card_deck_profiles` com dados do EDHREC.
