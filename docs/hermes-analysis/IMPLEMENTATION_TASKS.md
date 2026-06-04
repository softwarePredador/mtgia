# Implementation Tasks — MTG Knowledge ↔ Code Cross-Reference

> **Gerado:** 2026-06-04T17:30Z por ManaLoom Knowledge Synthesis (Cron)
> **Branch:** codex/hermes-analysis-docs
> **HEAD:** 03e09d30
> **Metodo:** Cruzamento do conhecimento MTG (Domain Skill v3.7, Gap 17, Scout #29, GAME_CHANGERS #5, Logic Coherence Audit, MANA_BASE_VALIDATION) com codigo Dart
> **Base de conhecimento:** Domain Skill Gaps 6/9/17 + Scout Exec#29 + Pipeline Audit v3.7 + Game Changer Research #5 + Logic Coherence Audit + Master commits 70e170f0..e8b610fc

---

### [P1] Optimize Pipeline: Adicionar verificacao de `discrepancies_found` no `run_log` antes de reutilizar analise em cache (Short-Circuit Staleness Detection)

**Conhecimento MTG:** O Domain Skill Gap 17 documenta que o mecanismo de short-circuit dos crons (responder [SILENT] quando o deck nao mudou) PERPETUA erros da ultima analise. Exemplo concreto: Validator v3.24 afirmou que Worldfire estava banida no Commander (FALSO — Scryfall confirma `commander=legal`). Como o deck nao mudou, o Validator retorna SILENT em TODAS as execucoes subsequentes (confirmado #64, 04/Jun). O erro de banlist fica permanentemente nos logs. NENHUM agente verifica "minha ultima analise estava correta?" antes do short-circuit. O Domain Skill recomenda: "Todo short-circuit deve incluir verificacao de `discrepancies_found > 0` no `run_log` da ultima execucao."

**Evidencia no codigo:**
- `server/lib/ai/optimization_validator.dart:28-86` — `OptimizationValidator.validate()` executa Monte Carlo + analise funcional + critic IA, mas NAO verifica se a ultima analise para este deck teve `discrepancies_found > 0`. Se o deck nao mudou e a analise anterior foi chamada externamente, o validator pode reutilizar resultados cacheados sem checar se havia erros.
- `rg "run_log" server/lib` → **ZERO resultados**. A tabela `run_log` existe no SQLite (`docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`) com campos `discrepancies_found`, `known_issues`, `execution_time`, `agent_name` — mas NENHUM arquivo Dart le essa tabela.
- `server/lib/ai/optimize_runtime_support.dart` — O pipeline de optimize (buildRoleTargetProfile, loadOptimizeFillerCandidateStubs) opera com dados cacheados do PG e nao verifica se a ultima analise do deck tinha discrepancias.

**Gap:** Quando o classificador foi corrigido (ramp tags 6→19) ou dados externos mudaram (banlist, EDHREC trends), o optimize pipeline continua usando analises antigas que podem conter erros factuais. O sistema nao tem codigo que diga: "a ultima analise deste deck tinha discrepancias — re-executar antes de recomendar swaps."

**Impacto:** `P1` — Swaps podem ser recomendados (ou bloqueados) baseados em analises com erros factuais. Exemplo: se a ultima analise dizia que uma carta estava banida (quando nao esta), o optimize pode evitar recomenda-la por meses, mesmo apos a correcao do banlist. O operador nao tem como saber que a analise esta stale.

**Risco:** P1 — Decisoes de swap baseadas em dados incorretos. Afeta diretamente a confiabilidade do pipeline de otimizacao.

**Acao recomendada:**
1. Criar `run_log_service.dart` com query que le o `run_log` do SQLite para um `deck_id` especifico
2. No `OptimizationValidator.validate()`, antes de executar Monte Carlo, consultar `run_log` para o deck:
   - Se `discrepancies_found > 0` na ultima execucao → pular short-circuit, forcar re-analise completa
   - Se `known_issues` contem erros nao resolvidos → flag como `stale_analysis: true`
3. Adicionar campo `staleAnalysis` ao `ValidationReport` para que o optimize pipeline possa decidir se confia ou nao nos resultados cacheados
4. No `buildRoleTargetProfile()`, verificar se os targets cacheados vieram de uma analise com discrepancias

**Validacao:**
```bash
cd server && dart analyze lib/ai/run_log_service.dart
cd server && dart analyze lib/ai/optimization_validator.dart
cd server && dart test test/ai/optimization_validator_test.dart
```

---

### [P1] `classifyOptimizationFunctionalRole`: Adicionar `functional_tags` persistidas como fonte primaria (unificar cadeia de prioridade com `FunctionalDeckSummary`)

**Conhecimento MTG:** O ManaLoom tem 3 classificadores diferentes no mesmo codebase: `inferFunctionalCardTags()` (multi-tag, 29 heuristicas, `functional_card_tags.dart:432-465`), `classifyOptimizationFunctionalRole()` (single-tag, quality gate, `optimization_functional_roles.dart:55-124`), e `inferFunctionalRole()` (single-tag, filler loader, `optimize_runtime_support.dart:2133-2179`). O Domain Skill Gap 6 documenta "duplo nulo" — 10%+ de cartas sao invisiveis a TODOS os classificadores simultaneamente. O Logic Coherence Audit (2026-05-29) identificou drift entre `functional_card_tags.dart` (que usa cadeia correta: `persisted functional_tags → semanticV2 → heuristic`) e `optimization_functional_roles.dart` (que usa apenas `semantic_tags_v2 → heuristic`, IGNORANDO `functional_tags` persistidas). A resolucao do classificador Python (v3.25) melhorou tags no SQLite (ramp 6→19), mas o codigo Dart ainda nao consulta esses dados persistidos.

**Evidencia no codigo:**
- `server/lib/ai/optimization_functional_roles.dart:55-58` — `classifyOptimizationFunctionalRole()` consulta APENAS `semantic_tags_v2` via `_classifySemanticV2FunctionalRole()`. Se `semantic_tags_v2` for null ou low-confidence, cai DIRETO para heuristicas de oracle text (linhas 63-124). NUNCA consulta `card['functional_tag']` (do SQLite `deck_cards`) nem `card['functional_tags']` (do PG `card_function_tags`).
- `server/lib/ai/functional_card_tags.dart:455-465` — `summarizeFunctionalTagsForDeck()` implementa a cadeia CORRETA: `persistedTags` (PG `card_function_tags`) → `semanticV2` → `inferredTags` (heuristicas). Esta cadeia produz resultados mais precisos porque `persistedTags` sao curadas/validadas.
- `server/lib/ai/optimize_runtime_support.dart:2133-2179` — `inferFunctionalRole()` (TERCEIRO classificador) usa APENAS heuristicas de oracle text. Cartas como Smothering Tithe (treasure ramp, classificada como `utility`), Aetherflux Reservoir (wincon via "pay 50 life", classificada como `engine`), e Sol Ring (classificado como `ramp` via `signet`/`talisman` substring check — na verdade e `sol ring`) sao mal classificadas.

**Gap:** `classifyOptimizationFunctionalRole` e usado pelo quality gate (`optimization_quality_gate.dart:52-53`) para decidir se um swap preserva o papel funcional. Se a carta removida e classificada como `utility` quando na verdade e `ramp`, o quality gate pode aprovar um swap que remove ramp — mesmo que `functional_tags` persistidas digam corretamente que a carta e `ramp`. O `FunctionalDeckSummary` (usado para analise/display) CLASSIFICA CORRETAMENTE a mesma carta, mas o quality gate usa um classificador DIFERENTE que erra.

**Impacto:** `P1` — O quality gate toma decisoes de swap baseadas em classificacao incorreta. Cartas essenciais podem ser marcadas como `utility` e sugeridas para remocao. O `FunctionalDeckSummary` mostra a classificacao correta (via cadeia de prioridade adequada), mas o gate usa outra — gerando inconsistencia visivel para o usuario ("deck summary diz ramp, mas optimize sugeriu cortar como filler").

**Risco:** P1 — Inconsistencia entre o que o sistema mostra ao usuario e o que o sistema usa para decidir. Swaps incorretos aprovados ou corretos bloqueados.

**Acao recomendada:**
1. `classifyOptimizationFunctionalRole()` deve aceitar parametro opcional `Map<String, dynamic>? cardData` com dados completos da carta (incluindo `functional_tag` e `functional_tags`)
2. Implementar cadeia de prioridade identica a `summarizeFunctionalTagsForDeck`:
   - 1º: `cardData['functional_tag']` (SQLite, single-tag) ou `cardData['functional_tags']` (PG, multi-tag)
   - 2º: `cardData['semantic_tags_v2']` (via `_classifySemanticV2FunctionalRole`)
   - 3º: Heuristicas de oracle text (fallback atual)
3. Atualizar callers (`optimization_quality_gate.dart:52-53`, `optimization_validator.dart`) para passar `cardData` completo
4. (Opcional, P2 futuro) Unificar `inferFunctionalRole()` com a mesma cadeia de prioridade

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimization_functional_roles.dart
cd server && dart analyze lib/ai/optimization_quality_gate.dart
cd server && dart test test/ai/optimization_quality_gate_test.dart
```

---

### [P2] `deck_learning_events`: Fechar o loop de aprendizado — Backend nunca le os eventos de aprendizado do PG

**Conhecimento MTG:** Os commits do master (70e170f0 "Harden Hermes learned deck sync" e anteriores) implementaram um pipeline de aprendizado: o App Flutter salva decks jogados → eventos sao escritos na tabela PG `deck_learning_events` → scripts Python (`auto_sync_learned_decks.py`, `auto_promote_learned_decks.py`) processam esses eventos e geram `learned_decks`. O modulo `deck_learning_event_support.dart` (novo no master) fornece `loadUsageHotCards()` e `buildUsageHotCardsPrompt()`. Porem, o backend Dart **nunca le `deck_learning_events` diretamente** — 0 referencias em `server/lib/`. O optimize pipeline nao sabe quais cartas o usuario realmente joga, quais tiveram bom desempenho, ou quais foram cortadas apos teste real.

**Evidencia no codigo:**
- `rg "deck_learning_event" server/lib` → **ZERO resultados**. A tabela `deck_learning_events` existe no PG (criada pelos scripts Python) mas nenhum arquivo Dart faz query nela.
- `server/lib/ai/deck_learning_event_support.dart` — Existe no master (commit 70e170f0) com funcoes `loadUsageHotCards()` e `buildUsageHotCardsPrompt()`, mas estas funcoes sao usadas apenas pelos scripts Python, nao pelo backend Dart.
- `server/lib/ai/optimize_runtime_support.dart` — O pipeline de optimize (`_scoreAggressiveCandidateQualityPair`, `loadOptimizeFillerCandidateStubs`) pontua candidatos baseado em `commander_card_synergy`, `card_role_scores`, e `meta_deck_count`. NENHUM uso de dados de aprendizado real do usuario.

**Gap:** O usuario joga com o deck, o App registra eventos de aprendizado, mas o optimize pipeline nunca usa esses dados para melhorar recomendacoes. Exemplo: se o usuario consistentemente corta uma carta que o optimize recomendou adicionar, o sistema nao aprende com isso — continua recomendando a mesma carta nos proximos ciclos. O loop de feedback usuario → sistema esta QUEBRADO no backend.

**Impacto:** `P2` — O optimize pipeline nao aprende com o uso real. Recomendacoes de swap nao melhoram com o tempo porque o sistema ignora o feedback do usuario. A funcionalidade de "learned decks" existe no master mas o backend nao a utiliza para otimizacao.

**Risco:** P2 — Melhoria de qualidade. O sistema funciona sem isso, mas perde a capacidade de aprender e se adaptar ao estilo do usuario.

**Acao recomendada:**
1. Criar `deck_learning_service.dart` que le `deck_learning_events` do PG para um `deck_id`
2. Extrair metricas: `cards_kept_after_test` (cartas que sobreviveram a testes reais), `cards_cut_after_test` (cartas removidas apos uso), `most_played_cards` (cartas mais usadas em partidas)
3. Integrar ao `AggressiveCandidateQualitySignal`:
   - Cartas `kept_after_test` → +10 bonus (validacao real)
   - Cartas `cut_after_test` → -20 penalty (feedback negativo real)
4. No optimize prompt, incluir secao "Your Recent Gameplay History" com dados de aprendizado

**Validacao:**
```bash
cd server && dart analyze lib/ai/deck_learning_service.dart
cd server && dart analyze lib/ai/optimize_runtime_support.dart
cd server && dart test test/ai/optimize_runtime_support_test.dart
```

---

### [P2] `card_deck_analysis`: Integrar scores de wincon (speed/resilience/stealth) do pipeline Python ao optimize quality gate

**Conhecimento MTG:** O pipeline Python (`scripts/analyze_deck_wincons.py` e relacionados) popuula a tabela PG `card_deck_analysis` com scores de wincon por carta: `speed_score` (quao rapida a wincon e), `resilience_score` (quao dificil de interromper), `stealth_score` (quao "invisivel" — nao obvia para oponentes). O Scout (Exec #38) usa esses scores para priorizar wincons: RAPIDAS (S>=6), IMBATIVEIS (R>=7), INVISIVEIS (ST>=7). O Domain Skill documenta que `card_deck_analysis` e "NOT yet read by backend". Isso e complementar a tarefa pendente sobre `card_deck_profiles` (que tem perfis por carta) — `card_deck_analysis` tem scores DE NIVEL ESTRATEGICO para o deck como um todo.

**Evidencia no codigo:**
- `rg "card_deck_analysis" server/lib` → **ZERO resultados**. A tabela existe no PG mas nenhum arquivo Dart faz query nela.
- `server/lib/ai/optimization_quality_gate.dart:34-101` — O quality gate filtra swaps baseado em role preservation, CMC delta, e structural recovery. NAO considera se a carta removida e uma wincon INVISIVEL (stealth alto) ou se a carta adicionada e uma wincon FRAGIL (resilience baixa).
- `server/lib/ai/optimization_validator.dart:28-86` — O validator executa Monte Carlo e analise funcional, mas nao avalia a QUALIDADE das wincons (speed/resilience/stealth).

**Gap:** O optimize pode recomendar cortar uma wincon com stealth_score=8 (INVISIVEL, como Guttersnipe — stealth_score=8 no DB) e substituir por uma wincon com resilience_score=2 (FRAGIL). O quality gate nao tem regras para prevenir isso porque nao le `card_deck_analysis`. Similarmente, o sistema nao prioriza adicionar wincons com resilience alta (IMBATIVEIS) quando o deck precisa de resiliencia.

**Impacto:** `P2` — Qualidade dos swaps reduzida. Wincons "invisiveis" (dificeis de prever) podem ser cortadas em favor de wincons "obvias" (faceis de interromper). O optimize perde a capacidade de balancear speed vs resilience vs stealth.

**Risco:** P2 — Melhoria de qualidade. O sistema funciona, mas as recomendacoes de swap sao menos informadas estrategicamente.

**Acao recomendada:**
1. Criar `card_deck_analysis_service.dart` com query que carrega `wincon_total_score`, `speed_score`, `resilience_score`, `stealth_score` para cada carta no deck
2. Integrar ao quality gate (`optimization_quality_gate.dart`):
   - Regra: nao cortar wincons com `stealth_score >= 7` (INVISIVEIS)
   - Regra: nao cortar wincons com `resilience_score >= 7` (IMBATIVEIS) a menos que substituida por wincon de resilience similar
   - Regra: priorizar adicoes com `speed_score >= 6` em decks aggro/combo
3. Adicionar campos `winconSpeed`, `winconResilience`, `winconStealth` ao `AggressiveCandidateQualitySignal` (ja existente em `optimize_runtime_support.dart:2433-2479`)

**Validacao:**
```bash
cd server && dart analyze lib/ai/card_deck_analysis_service.dart
cd server && dart analyze lib/ai/optimization_quality_gate.dart
cd server && dart test test/ai/optimization_quality_gate_test.dart
```

---

### [P2] `GoldfishSimulator`: Adicionar validacao de requisitos de cor (color requirements) na definicao de mao keepable

**Conhecimento MTG:** O Domain Skill Gap 9 documenta que o Mulligan Simulation NAO verifica requisitos de cor: "Mao com 3 Mountains + spells brancos e considerada 'jogavel' → ~3-8pp de superestimacao." O pipeline de mulligan (Execucoes #4-#15) define mao "jogavel" como "2-4 lands AND (ramp >= 1 OR lands >= 3)" mas essa definicao (usada pelos crons Python) tambem ignora cor. A tarefa pendente #8 (GoldfishSimulator: Tapped lands) e a tarefa #5 da sintese anterior (GoldfishSimulator: ramp em keepable) abordam keepable — mas NENHUMA tarefa cobre requisitos de cor. Este e o terceiro e ultimo componente para tornar o keepable realistico.

**Evidencia no codigo:**
- `server/lib/ai/goldfish_simulator.dart:131,156` — A definicao atual de keepable: `if (landsInHand >= 2 && landsInHand <= 5) keepableHands++`. Nao ha NENHUMA verificacao de se as lands na mao conseguem produzir as cores necessarias para conjurar as spells na mao.
- `server/lib/ai/goldfish_simulator.dart` — O simulador tem acesso ao `type_line` e `oracle_text` de cada carta (via `cardData`), mas nao extrai `color_identity` nem `mana_cost` para verificar viabilidade de cor.
- `server/lib/ai/optimization_validator.dart:37-40` — `_runMonteCarloComparison()` chama `GoldfishSimulator` e usa `consistencyScore` (que pesa `keepableRate` como 40%). Keepable inflado = consistencyScore inflado = quality gate aprova swaps que pioram a consistencia real.

**Gap:** O `GoldfishSimulator` superestima a taxa de keepable porque ignora color screw. Uma mao com 3 Mountains, 1 Path to Exile (W), 1 Swords to Plowshares (W), 1 Boros Charm (RW), e 1 Lorehold (RW) e considerada "keepable" (3 lands, 2-5 range) — mas na pratica e injogavel porque nenhuma land produz White. Isso infla o `consistencyScore` e mascara problemas de mana base nos swaps.

**Impacto:** `P2` — Swaps que pioram a mana base (ex: trocar 1 Plateau por 1 Mountain) nao sao detectados porque o keepable rate nao muda. O validator aprova swaps que criam color screw porque o `GoldfishSimulator` e cego a cores.

**Risco:** P2 — Melhoria de precisao. Complementar as tarefas pendentes #5 (ramp em keepable) e #8 (tapped lands). Juntas, as 3 correcoes transformam o keepable de "simplista" para "realista".

**Acao recomendada:**
1. Adicionar `_extractManaCost(card)` helper que extrai o custo de mana como lista de simbolos
2. Adicionar `_extractLandColors(card)` helper que extrai as cores produzidas por uma land (do `oracle_text`: "{T}: Add {R}" → produz Red)
3. Na funcao `_isKeepable()`, apos verificar lands e ramp, adicionar:
   - Extrair todas as spells nao-land da mao
   - Extrair todas as cores que as lands na mao podem produzir
   - Verificar se TODAS as spells tem pelo menos 1 fonte de cada cor necessaria
   - Se nao → nao e keepable (color screw)
4. Implementar como metodo separado `_hasColorScrew(hand)` para facilidade de teste

**Validacao:**
```bash
cd server && dart analyze lib/ai/goldfish_simulator.dart
cd server && dart test test/ai/goldfish_simulator_test.dart
```

---

## Resumo de Tasks Novas (2026-06-04 @ 03e09d30)

| # | Prioridade | Task | Origem |
|:-:|:----------|:-----|:-------|
| 1 | P1 | Short-Circuit Staleness Detection — `run_log.discrepancies_found` check no validator | Domain Skill Gap 17 (NOVO) |
| 2 | P1 | `classifyOptimizationFunctionalRole` — Unificar com `functional_tags` persistidas | Domain Skill Gap 6 + Logic Coherence Audit (generalizacao pendente #2) |
| 3 | P2 | `deck_learning_events` — Fechar loop de aprendizado no backend | Master commits 70e170f0 + 0 refs em server/lib (NOVO) |
| 4 | P2 | `card_deck_analysis` — Integrar wincon speed/resilience/stealth ao quality gate | Scout #38 + 0 refs em server/lib (NOVO) |
| 5 | P2 | `GoldfishSimulator` — Adicionar validacao de color requirements ao keepable | Domain Skill Gap 9 (NOVO, complementar a pendentes #5 e #8) |

## Tasks Anteriores (ainda pendentes das execucoes 2026-06-04 @ 22787279, @ d2ca5234, @ 498eb1a8)

| # | Prioridade | Task |
|:-:|:----------|:-----|
| 1 | P1 | Bracket Policy: Adicionar 7 categorias ao `BracketCategory` enum (29/53 GCs nao detectados) |
| 2 | P1 | `buildRoleTargetProfile`: Usar PG `commander_reference_profiles` + `theme_contextual_rules` |
| 3 | P1 | `ThemeContextualRulesService.validateDeck()`: Detectar archetype mismatch |
| 4 | P1 | Quality Gate: Integrar `theme_contextual_rules` nas decisoes de swap |
| 5 | P1 | Battle Simulator: Implementar regras Commander (stack, multiplayer, etc.) |
| 6 | P1 | Goldfish Simulator: Tapped lands (complementa Task #5 nova) |
| 7 | P1 | Optimize/Archetypes: Owner-scoped deck queries |
| 8 | P2 | `inferFunctionalRole()`: Consultar `card_function_tags` persistidas antes de heuristicas |
| 9 | P2 | `card_deck_profiles` (1299 perfis PG): Integrar ao backend — tabela nunca lida |
| 10 | P2 | `GoldfishSimulator`: Adicionar ramp/mana rocks na definicao de keepable |
| 11 | P2 | Candidate Quality: Adicionar `edhrec_inclusion_pct` como metrica |
| 12 | P2 | Candidate Quality: Adicionar `edhrec_trend_zscore` como fator de scoring |
| 13 | P2 | Deck Import: Re-classificar automaticamente cartas com `functional_tag='unknown'` |
| 14 | P2 | Activation Funnel: Sync `_allowedEvents` app-backend |

> **Nota:** Tasks #5 nova (color requirements), #6 pendente (tapped lands) e #10 pendente (ramp keepable) sao complementares — todas melhoram o `GoldfishSimulator`. Implementar juntas.
> **Nota:** Task #2 nova (classifier unification) generaliza a pendente #8 (`inferFunctionalRole`) e a pendente antiga sobre `classifyOptimizationFunctionalRole` — unificar os 3 classificadores em uma cadeia de prioridade unica.


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
