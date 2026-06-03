# Implementation Tasks — ManaLoom

> Gerado por sintese: cruzamento do conhecimento MTG do Hermes x codigo atual.
> Data: 2026-06-03T20:23:21+00:00 | Branch: origin/master | SHA: `fb91fdca` | Analysis branch: codex/hermes-analysis-docs
> Ultima sintese anterior: 2026-06-02T19:20:00+00:00 (SHA e754c0ec) | Novas tasks: P1-o, P2-m, P2-n, P2-o, P3-f

## Resumo de Status

| # | Prioridade | Titulo | Status |
|:--|:-----------|:-------|:-------|
| **P1-o** | **P1** | **Commander Learning: _roleSummary() le metadata estagnado do JSONB** | **NOVO** |
| **P2-m** | **P2** | **card_list ILIKE full-table scan em meta_decks (commander-reference)** | **NOVO** |
| **P2-n** | **P2** | **sync_log table tem zero consumidores Dart** | **NOVO** |
| **P2-o** | **P2** | **archetypeToTheme() fallback cria nomes de temas inexistentes no PG** | **NOVO** |
| **P3-f** | **P3** | **Commander Learning: sem trigger de reclassificacao pos-import** | **NOVO** |
| P1-a | P1 | BracketCategory enum nao detecta Game Changers | RESOLVIDO (ae886b11) |
| P1-b | P1 | card_deck_profiles nao consultado pelo optimize | RESOLVIDO (d8b7b26b) |
| P1-c | P1 | Weakness-analysis usa heuristicas legacy (sem adapter F1) | ATIVO |
| P1-d | P1 | Wincon detection fragil | ATIVO |
| P1-e | P1 | GoldfishSimulator nao calcula Sem Play T3 | RESOLVIDO (798317af) |
| P1-f | P1 | optimize_request_support nao carrega card_function_tags | RESOLVIDO (6af73d87) |
| P1-g | P1 | card_rulings (76.991 rulings) nao integrado ao validator | ATIVO |
| P1-h | P1 | Python classify_card() nao chama _looksLike* | ATIVO |
| P1-i | P1 | Dart single-tag _looksLike* mais estreitas que multi-tag | ATIVO |
| P1-j | P1 | Pipeline Integrity: validator sem hash verification | ATIVO |
| P1-k | P1 | resolveOptimizeArchetype duplicado com semantica divergente | ATIVO |
| P1-l | P1 | verifySwapIntegrity (163 linhas) com zero call-sites | ATIVO |
| P1-m | P1 | Bulk import bypassa classificadores | ATIVO |
| P1-n | P1 | Ritual/fast-mana misclassified | ATIVO |
| P2-a | P2 | _looksLikePayoff nao detecta payoffs de dano direto | RESOLVIDO (3fb17356) |
| P2-b | P2 | Tags ninja/stax_disruption com 0% de acuracia | ATIVO |
| P2-c | P2 | Write-only tables | ATIVO |
| P2-d | P2 | Double-null cards invisiveis ao classificador | ATIVO |
| P2-e | P2 | Synergy-axis ausente do quality gate | ATIVO |
| P2-f | P2 | fp/fn tracking nunca populado | ATIVO |
| P2-g | P2 | 77 cartas sem oracle text | ATIVO |
| P2-h | P2 | card_deck_analysis (wincon scores) — 0 refs no Dart | ATIVO |
| P2-i | P2 | Evolution Oracle swap scripts lack post-exec verification | ATIVO |
| P2-j | P2 | Basic land detection: 4 variantes incompatíveis | PARCIAL (shared basic_land_utils.dart em master) |
| P2-k | P2 | archetypeToTheme() cobre apenas 12 patterns | ATIVO |
| P2-l | P2 | GoldfishSimulator nao simula tapped lands | ATIVO |
| P3-a | P3 | CONTEXTO_PRODUTO_ATUAL.md desatualizado | RESOLVIDO (7ed5b863) |
| P3-b | P3 | Weakness-analysis wincon detection fragil | ATIVO |
| P3-c | P3 | manual-de-instrucao.md desatualizado | ATIVO |
| P3-d | P3 | THEMES.md 19 temas nao validados | ATIVO |
| P3-e | P3 | MDFC duplicate detection ausente | ATIVO |

---

### [P1] Commander Learning: _roleSummary() reads stale metadata from JSONB

**Conhecimento MTG:** O VALIDATOR_LOG v3.23 (2026-06-02) e a skill documentam o pitfall "decks Table Columns Can Be Stale vs deck_cards Tags". Metricas estruturais armazenadas em colunas podem divergir por dias das tags reais.

**Evidencia no codigo:**
- `server/routes/ai/commander-learning/index.dart:283-301` — `_roleSummary()` le `total_lands`, `ramp_count`, etc. do campo `metadata` JSONB importado. Esses valores sao computados UMA VEZ no momento do import (`bin/commander_learned_deck.dart`) e NUNCA recalculados.
- `server/routes/ai/commander-reference/index.dart:443-449` — mesmo padrao em `_buildCommanderLearningPayload()`.

**Gap:** Se o classificador atualizar tags de 'unknown' para 'ramp' apos o import, o `role_summary` continua mostrando os numeros antigos. O endpoint `/ai/commander-learning` expoe metricas potencialmente estagnadas.

**Impacto:** UI mostra metricas incorretas; decisoes de otimizacao baseadas em role_summary podem ser erradas.

**Risco:** P1 — dados estagnados expostos na API publica.

**Acao recomendada:**
1. Adicionar funcao `_recomputeRoleSummary(pool, cardList)` que consulta `card_function_tags`
2. Usar no endpoint em vez de confiar no metadata JSONB
3. Alternativa: endpoint `POST /ai/commander-learning/refresh` para recalcular

**Validacao:**
```bash
cd server
dart analyze routes/ai/commander-learning/index.dart
dart test test/commander_learned_deck_support_test.dart
```

---

### [P2] card_list ILIKE full-table scan on meta_decks in commander-reference

**Conhecimento MTG:** O endpoint `commander-reference` consulta `meta_decks` (650+ linhas, crescente) para construir perfis de referencia. A query usa `card_list ILIKE` em coluna TEXT/JSON sem indice.

**Evidencia no codigo:**
- `server/routes/ai/commander-reference/index.dart:96` (master):
  ```sql
  OR card_list ILIKE @commanderPattern  -- FULL TABLE SCAN
  ```
- `card_list` e TEXT/JSON — ILIKE nao pode usar indices B-tree.

**Gap:** Cada request faz scan sequencial em todas as linhas. Latencia cresce O(n) com o corpus.

**Impacto:** Performance degradation com crescimento de dados; pode exceder timeouts.

**Risco:** P2 — performance.

**Acao recomendada:**
1. Adicionar coluna `commander_search_text` com GIN trigram index
2. Ou extrair commander names para `TEXT[]` com GIN index
3. Quick win: garantir que LIMIT seja aplicado antes do ILIKE (subquery)

**Validacao:**
```bash
cd server
dart test test/commander_reference_route_test.dart
```

---

### [P2] sync_log table has zero Dart consumers

**Conhecimento MTG:** Saber QUANDO cada fonte de dados foi sincronizada e critico para diagnosticar dados estagnados (Scryfall, EDHREC, Commander Spellbook).

**Evidencia no codigo:**
- `server/database_setup.sql` — cria `sync_log` (source, status, records_synced, timestamps)
- `grep -rn "sync_log" server/lib/ server/routes/ --include="*.dart"` → **0 resultados**
- Scripts Python escrevem mas nenhum codigo Dart le

**Gap:** Tabela write-only sem visibilidade operacional. Falhas de sync sao invisiveis.

**Impacto:** Operadores nao sabem quando dados foram atualizados; sem alertas.

**Risco:** P2 — visibilidade operacional zero.

**Acao recomendada:**
1. Adicionar `GET /health/sync-status` ou integrar no `/health` existente
2. Alertar quando `completed_at > 24h` para sources criticos

**Validacao:**
```bash
cd server
dart test test/health_endpoint_test.dart
```

---

### [P2] archetypeToTheme() fallback silently creates theme names with zero PG rules

**Conhecimento MTG:** THEMES.md tem 42 temas; `theme_contextual_rules` PG tem 27 regras. O fallback `a.replaceAll(' ', '_')` cria nomes como `'artifact_combo'` que nao existem no PG → `getRulesForArchetype()` retorna `[]` → validacao tematica e silenciosamente DESLIGADA.

**Evidencia no codigo:**
- `server/lib/ai/theme_contextual_rules_service.dart:67`:
  ```dart
  return a.replaceAll(' ', '_');  // FALLBACK: nome invalido
  ```
- `validateDeck()` retorna `hasCriticalViolation: false` quando `rules.isEmpty` — sem warning.

**Gap:** Arquetipos nao mapeados passam na validacao sem NENHUMA verificacao tematica. Operador nao sabe que a validacao foi pulada.

**Impacto:** Validacao tematica silenciosamente ineficaz para arquetipos nao mapeados.

**Risco:** P2 — validacao silenciosamente desligada.

**Acao recomendada:**
1. Adicionar warning quando `rules.isEmpty`: `theme_fallback_used: true`
2. Mapear fallback para tema conhecido mais proximo (ex: `artifact_combo` → `artifacts`)
3. Logar `No theme rules found for archetype: X` no server

**Validacao:**
```bash
cd server
dart test test/theme_contextual_rules_service_test.dart
```

---

### [P3] Commander Learning: no post-import reclassification trigger

**Conhecimento MTG:** O VALIDATOR_LOG v3.23 descobriu que importacao em massa produz `functional_tag='unknown'` e zero `card_tags`. A skill documenta "Bulk Import Data Corruption — Classifier NEVER Ran".

**Evidencia no codigo:**
- `server/bin/commander_learned_deck.dart` — importa deck, nao chama classificador
- `_roleSummary()` le metadata do import — se tags estao erradas, metadata tambem
- Endpoint `/ai/commander-learning` nao tem `?refresh=true`

**Gap:** Deck importado com tags ruins permanece com metricas erradas indefinidamente.

**Impacto:** Dados de baixa qualidade persistem; sem mecanismo de correcao automatica.

**Risco:** P3 — qualidade pos-import sem correcao. (Limitado a decks aprendidos, nao ao pipeline principal.)

**Acao recomendada:**
1. Adicionar `?refresh=true` ao endpoint para re-classificar cartas
2. No `bin/commander_learned_deck.dart`, rodar classificador apos INSERT
3. Health check: warning se >10% das cartas com `functional_tag='unknown'`

**Validacao:**
```bash
cd server
dart run bin/commander_learned_deck.dart --input-json=test.json --apply
# Verificar: metadata.ramp_count > 0
```

---

## Tasks Ja Ativos (mantidos de sintese anterior)

## Tasks Ja Ativos (mantidos de sintese anterior)

### [P1] card_rulings (76.991 rulings) nao integrado ao validator — trocas sem validacao de regras

**Conhecimento MTG:** O VALIDATOR_LOG v3.20 (Purpose Analyzer) usa ativamente a tabela card_rulings do PostgreSQL para verificar interacoes entre cartas. Exemplos criticos encontrados: "Lorehold + Miracle: card com Miracle DEVE ser revelado antes de entrar na mao", "Dualcaster Mage: copia na stack NAO e conjurada", "Arcane Bombardment: se sair do campo, cartas exiladas PERMANECEM".

**Evidencia no codigo:**
- optimization_validator.dart:28-86 — validate() tem 3 camadas mas nenhuma consulta card_rulings
- optimization_quality_gate.dart:18-80 — filterUnsafeOptimizeSwapsByCardData() nao verifica interacoes de regras
- Nenhuma referencia a card_rulings em todo server/lib/ (0 resultados)
- Tabela existe no PostgreSQL com 76.991 rulings, mas e completamente write-only

**Gap:** O validator nao consegue detectar que uma troca proposta quebra interacoes documentadas nas rulings oficiais.

**Acao recomendada:**
1. Criar CardRulingsService que consulta card_rulings por nome de carta
2. Adicionar 4a camada _validateSwapRulings() no optimization_validator.dart
3. Foco inicial: verificar palavras-chave de interacao (cast vs copy, triggered vs activated)
4. Retornar warning (nao block) — a Critic IA decide com contexto

**Validacao:**
```bash
cd server
dart analyze lib/ai/optimization_validator.dart
dart test test/optimization_validator_test.dart
```

---

### [P2] Synergy-axis evaluation ausente do quality gate — so verifica rolePreserved

**Conhecimento MTG:** O SYNERGY_MAP (7 eixos) classifica cada carta. O quality gate verifica APENAS removedRole == addedRole — mas duas cartas podem ter o mesmo role e afetar eixos DIFERENTES.

**Evidencia no codigo:**
- optimization_quality_gate.dart:55-56 — rolePreserved = removedRole == addedRole
- Nao ha verificacao de eixo estrategico ou synergy group

**Acao recomendada:**
1. Adicionar funcao _classifySynergyAxis(String oracle) que retorna um dos 7 eixos
2. No quality gate, verificar se o swap remove a ultima carta de um eixo → WARNING
3. Nao precisa bloquear — adicionar droppedReasons com warning

**Validacao:**
```bash
cd server
dart analyze lib/ai/optimization_quality_gate.dart lib/ai/optimization_functional_roles.dart
dart test test/optimization_quality_gate_test.dart
```

---

### [P3] MDFC duplicate detection ausente do deck validation

**Conhecimento MTG:** O VALIDATOR_LOG v3.20 descobriu que o deck Lorehold tem DUAS linhas para a mesma carta MDFC: Valakut Awakening e Valakut Awakening // Valakut Stoneforge. O SUM(quantity)=100 conta a MESMA carta duas vezes.

**Evidencia no codigo:**
- optimization_validator.dart — verifica total cards, lands, singleton, mas NAO detecta MDFC duplicados
- deck_rules_service.dart — validacao sem MDFC awareness
- Nenhum arquivo em server/lib/ referencia MDFC ou double-faced

**Acao recomendada:**
1. Adicionar funcao _deduplicateMdfcCards() que detecta pares Name + Name // BackFace
2. Integrar no fluxo de importacao de deck (antes de INSERT) e no validator
3. Commit 798317af ja adicionou normalizePhysicalCardCopyName — estender para o deck validator

**Validacao:**
```bash
cd server
dart analyze lib/deck_rules_service.dart lib/ai/optimization_validator.dart
dart test test/deck_rules_service_test.dart
```

---

### [P1] ~~GoldfishSimulator nao calcula "Sem Play T3"~~ → RESOLVIDO (798317af)

**Commit:** 798317af — Harden deck rules and goldfish curve checks

**O que foi implementado:**
- Campo noPlayTurn3Rate adicionado ao GoldfishResult
- Teste novo: TC013b valida normalizePhysicalCardCopyName para MDFC/split
- Abordagem usa _canPlayOnTurn que verifica cores + custo

### [P1] Weakness-analysis usa heuristicas legacy — sem adapter F1

**Evidencia no codigo:**
- server/routes/ai/weakness-analysis/index.dart:114-170 — Conta ramp/draw/removal/wipes por oracle_text local
- server/routes/ai/weakness-analysis/index.dart:380-430 — Recomendacoes sao listas fixas de nomes

**Acao:** Refatorar para usar resolveCardFunctionalRoles() + queries em card_function_tags.

### [P1] Wincon detection fragil — battle_analyst + weakness-analysis

**Evidencia no codigo:**
- optimization_quality_gate.dart:346-353 — _criticalRolesForArchetype() NAO inclui wincon
- server/routes/ai/weakness-analysis/index.dart:400-420 — Patterns fixos

**Acao:** Adicionar wincon aos roles criticos; refatorar para usar adapter F1.

### [P2] Double-null cards invisiveis ao classificador — risco de swap auto

**Evidencia no codigo:**
- optimization_functional_roles.dart:55-125 — classifyOptimizationFunctionalRole() retorna artifact/enchantment/utility para Scroll Rack, Penance, etc.
- functional_card_tags.dart — Multi-tag classifier tambem falha

**Update 2026-06-01:** Commit 6af73d87 (P1-f) carrega card_function_tags nas queries SQL. TAG_ACCURACY_REPORT identificou 29 double-nulls (7.4% das nao-terreno). Verificar se as double-nulls restantes tem card_function_tags no PostgreSQL.

### [P2] Write-only tables — deck_matchups, deck_weakness_reports, ml_prompt_feedback

**Acao:** Adicionar SELECT para cache ou documentar como audit logs com retention policy.

### [P2] Tags ninja/stax_disruption com 0% de acuracia no SQLite

**Acao:** Investigar e corrigir heuristica de classificacao ou remover tags com 0% de precisao. Nota: TAG_ACCURACY_REPORT analisou 22 tags; ninja e stax_disruption nao estao entre elas — estas tags podem existir apenas no PostgreSQL card_function_tags.

### [P3] Weakness-analysis wincon detection fragil (oracle text)

**Acao:** Refatorar deteccao de wincon para usar adapter F1 + card_function_tags.

### [P3] manual-de-instrucao.md desatualizado

**Evidencia:** Nao menciona F1, F3, bracket expansion, card_deck_profiles, payoff expansion, singleton reset (d3cfaf3b), dead code cleanup (8cab6400, 23cfc061), semantic drift fix (6af73d87).

**Acao:** Atualizar com todos os commits desde a ultima atualizacao.

### [P3] THEMES.md 19 temas nao validados vs EDHREC

**Acao:** Validar temas prioritarios (Spellslinger, Reanimator, Graveyard) contra EDHREC live data.

---

## Tasks Resolvidos (referencia historica)

| Task | Commit | Data |
|:-----|:-------|:-----|
| BracketCategory enum (boardWipe, cardAdvantage, stax, protection, valueEngine) | ae886b11 | 2026-05-31 |
| card_deck_profiles integration | d8b7b26b | 2026-05-31 |
| _looksLikePayoff damage payoffs | 3fb17356 | 2026-05-31 |
| CONTEXTO_PRODUTO_ATUAL.md update | 7ed5b863 | 2026-05-31 |
| optimize_request_support semantic drift fix (card_function_tags) | **6af73d87** | 2026-05-31 |
| GoldfishSimulator noPlayTurn3Rate + MDFC copy normalization | **798317af** | 2026-06-01 |
| Resolve learning pipeline backlog (deck_advanced_analysis, simulate-matchup, combo detection) | **e754c0ec** | 2026-06-02 |
