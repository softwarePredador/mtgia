# Hermes Analysis: Commit Digest

> Acompanhamento continuo dos commits do ManaLoom.
> Atualizado em 2026-06-04T00:23Z (Incremento: Learned Deck Scripts + Visual Proof - d693b9fb).

## Estado atual

- Branch observada: `master`
- HEAD anterior: `fb91fdca` (Add Lorehold learned deck runtime proof).
- HEAD atual: **`d693b9fb`** (Capture Lorehold learned deck visual proof).
- Branch de analise: `codex/hermes-analysis-docs`
- Backend publicado: `https://evolution-cartinhas.8ktevp.easypanel.host`
- SHA publicado confirmado em producao: **`d693b9fb`** (`/health` retornou HTTP 200 em 2026-06-04T00:23Z — producao operacional).
- Local `master`: 46 commits atrasado (`3f7d784f`) — precisa de `git pull origin master`



## Novos commits nesta rodada (2026-06-04)


### `d693b9fb` — Capture Lorehold learned deck visual proof (HEAD)

- **1 arquivo**, **+25/-1 linhas**
- **Tipo: CODE/TEST** — Adiciona capturas visuais ao teste de runtime do Lorehold learned deck:
  1. 4 chamadas de `captureVisualProof` em pontos-chave do fluxo (no commander, learned button visivel, hermes preview, saved deck details).
  2. Scroll e garantia de visibilidade antes de cada captura.
- **Avaliacao Hermes**: Teste de integracao ampliado com prova visual. Sem mudanca de logica. Baixo risco.
- **Verificacao**: Health endpoint confirma `git_sha: d693b9fb` em producao.

### `5fc16e7d` — Add Hermes learned deck export/sync scripts, extract shared backend helpers, add save widget test

- **8 arquivos**, **+628/-313 linhas**
- **Tipo: CODE/REFACTOR** — Refatoracao e novos scripts de operacao:
  1. `server/lib/ai/commander_reference_helpers.dart` (NOVO, 151 linhas) — Extrai helpers compartilhados (`jsonObject`, `intValue`, `summarizeLegalities`, `loadCardMetadataByName`, `canonicalValidationCards`, etc.) que estavam duplicados entre `commander-learning/index.dart` e `commander-reference/index.dart`.
  2. `server/routes/ai/commander-learning/index.dart` (-168 linhas) — Remove helpers privados, usa `commander_reference_helpers.dart`.
  3. `server/routes/ai/commander-reference/index.dart` (-165 linhas) — Mesma refatoracao, remove tambem `_summarizeCommanderLegalities` e `_intValue`/`_jsonObject` privados.
  4. `server/bin/export_hermes_learned_deck.py` (NOVO, 223 linhas) — Script Python para exportar learned decks do banco.
  5. `server/bin/sync_hermes_learned_deck.sh` (NOVO, 78 linhas) — Script shell para sincronizar learned decks.
  6. `app/test/features/decks/screens/deck_flow_entry_screens_test.dart` (+121 linhas) — Novo teste widget `DeckGenerateScreen save learned deck POSTs 99 main + 1 commander`. Refatora testes existentes com wrappers `wrapSimple`/`wrapWithRouter`.
- **Avaliacao Hermes**: Refatoracao limpa — reduziu ~333 linhas duplicadas extraindo shared helpers. Nenhum risco de regressao detectado. `dart analyze lib/` — No issues found. `dart test` — 599/599 PASS. `flutter analyze --no-pub --no-fatal-infos` — No issues found.
- **Risco**: Scripts Python/Shell (`export_hermes_learned_deck.py`, `sync_hermes_learned_deck.sh`) sao novos e nao tem testes dedicados. Operam contra o banco de producao com queries de leitura — risco operacional baixo, mas devem ser monitorados na primeira execucao.

### `fb91fdca` — Add Lorehold learned deck runtime proof

- **14 arquivos**, **+2676/-5 linhas**
- **Tipo: CODE/FEATURE** — Infraestrutura completa de Commander Learned Decks:
  1. Nova tabela `commander_learned_decks` (database_setup.sql) - UUID PK, unique(source_system, source_ref), is_active flag.
  2. Nova rota dedicada `GET /ai/commander-learning` (461 linhas) - lista decks ativos ou busca por comandante. Fallback gracioso quando tabela nao existe.
  3. Rota `/ai/commander-reference` expandida para 684 linhas - integra promocao de learned deck com fallback deterministico.
  4. `commander_learned_deck_support.dart` (358 linhas) - parsing, upsert, PG queries.
  5. `bin/commander_learned_deck.dart` (140 linhas) - CLI de import com dry-run/apply modes.
  6. App-side +307 linhas: novo botao "Usar deck aprendido do comandante" com preview, helper text e loading state.
  7. Integration test: `commander_learned_deck_runtime_test.dart` (230 linhas).
- **Avaliacao Hermes**: Feature completa, 619/619 server tests PASS + 3 novos. `dart analyze lib/` - No issues found.
  Sem flag de feature — sempre ativo. Comportamento silencioso em falha de rede (catch silencioso).
- **Verificacao**: Health endpoint confirma `git_sha: fb91fdca` em producao.

### `5c7111f2` — Refine commander learning deck UX

- **Tipo: CODE/FEATURE** — Refinamentos de UX no fluxo de deck aprendido:
  1. Botao com helper text contextual, progress panel compartilhado, Learned Deck Preview com chips.
  2. Scroll-to-result apos carregamento (`Scrollable.ensureVisible`).
  3. Tratamento de erro via `FriendlyErrorMapper` padrao do app.
- **Avaliacao Hermes**: UX refinamentos solidos. Sem regressao.

### `213a4e22` — Document commander learning endpoint validation

- **Tipo: DOCS** — 3 novos docs: COMMANDER_LEARNING_API.md, EXECUTION_TRACKER.md, NEXT_STEPS.md.

### `a763f15b` — Add commander learning endpoint

- **Tipo: CODE/FEATURE** — Rota `GET /ai/commander-learning` com fallback gracioso (tabela inexistente retorna vazio).

### `06bb644e` — Add commander learned deck import routine

- **Tipo: CODE/FEATURE** — CLI `bin/commander_learned_deck.dart` importa decks Hermes para PG.

### `9daff606` — Add learned commander deck shortcut

- **Tipo: CODE/FEATURE** — Atalho de UI na tela de geracao de deck.

### `052f0fd4` — Document commander learning rollout steps

- **Tipo: DOCS** — Documento de rollout steps.

### `4cf90e57` — Expose promoted commander learning decks

- **Tipo: CODE/FEATURE** — Commander-reference prioriza deck promovido sobre fallback deterministico.

---

### `e754c0ec` — Resolve learning pipeline backlog (HEAD)

- **9 arquivos**, **+316/-45 linhas**
- **Tipo: CODE/FEATURE** — Resolve backlog do pipeline de aprendizado:
  1. Nova rota `POST /ai/simulate-matchup` (505 linhas) — simula matchup entre dois decks com ArchetypeCountersService. Body: `my_deck_id`, `opponent_deck_id`, `simulations`. Retorna `my_deck`, `opponent_deck`, `simulation`, `analysis`, `recommendations`, `win_rate`, `stats`.
  2. Weakness-analysis integra análises avançadas F3 (diversidade de wincon, removal-to-threat ratio, qualidade de draw, viabilidade pós-wipe) via `deck_advanced_analysis.dart`.
  3. Weakness-analysis integra detecção de combos reais (Commander Spellbook) — combos completos + near-miss opportunities.
  4. Sync_combos agora materializa `combo_piece` em `card_function_tags` com fonte `commander_spellbook_combo_v1` e confiança 0.960.
  5. Ajustes em `optimize_runtime_support.dart`, `optimize_filler_loader_support.dart`, `candidate_quality_data_support.dart`, `functional_card_tags.dart`.
- **Avaliação Hermes**: Cobertura de testes sólida (619/619 Dart tests com JWT_SECRET). `verifySwapIntegrity` definido mas nunca chamado — ver task P1 abaixo. Warnings de Flutter analyze são pré-existentes em arquivos de teste. 45 falhas em Flutter tests são network-dependent (backend não disponível no container) — padrão conhecido.
- **Verificação**: `dart analyze lib/` — No issues found. `dart test` com JWT_SECRET — 619/619 PASS. Health endpoint confirma `git_sha: e754c0ec` em produção.

### `92c72325` — Document learning cron schedule

- **6 arquivos**, **+316 linhas**
- **Tipo: DOCS/OPS** — Documentação e scripts de cron para o pipeline de aprendizado:
  1. `MANALOOM_CRONS_E_PENDENCIAS.md` (126 linhas) — documento único com crons do aprendizado e backlog de pendências de lógica.
  2. Scripts de cron: `cron_snapshot_edhrec.sh`, `cron_snapshot_price_history.sh`, `cron_sync_combos.sh`, `cron_sync_rulings.sh`, `cron_sync_staples.sh`.
  3. Crontab recomendado consolidado com ordenação intencional (preços → snapshot preço → EDHREC).
- **Avaliação Hermes**: Sem risco de regressão. Scripts de cron seguem padrão existente (`*.sh` wrappers). Documento classifica corretamente crons manuais vs automatizados.

### `8b93d8f8` — Add data intelligence pipelines for deck analysis

- **17 arquivos**, **+2419/-31 linhas**
- **Tipo: CODE/FEATURE** — Infraestrutura de data intelligence para análise de decks:
  1. **Commander Spellbook Service** (`commander_spellbook_service.dart`, 222 linhas) — busca combos conhecidos do Commander Spellbook (bulk JSON), detecta combos completos e near-misses no deck.
  2. **Deck Advanced Analysis** (`deck_advanced_analysis.dart`, 606 linhas) — 4 análises avançadas: (a) win-condition diversity (speed/resilience/stealth axes), (b) removal-to-threat ratio, (c) draw tag completeness (repeatable vs burst vs cantrip vs conditional), (d) post-resolution viability (recuperação pós board wipe).
  3. **EDHREC Trend Service** (`edhrec_trend_service.dart`, 208 linhas) — série temporal de inclusion rate para detecção de tendências rising/falling/stable.
  4. **Optimize Swap Integrity** (`optimize_swap_integrity.dart`, 163 linhas) — SHA-256 hash canônico dos swaps (remove/add) vinculado ao deck_signature. Gerado no optimize, anexado ao response body.
  5. Novas rotas: `GET /cards/:id/rulings` (88 linhas), `POST /decks/:id/recommendations` (44 linhas).
  6. Scripts de sync: `sync_combos.dart` (337 linhas), `sync_rulings.dart` (198 linhas), `snapshot_edhrec.dart` (149 linhas).
  7. Migrations v015-v017: tabelas `card_combos`, `combo_cards`, `card_rulings`, `edhrec_card_snapshots`.
  8. Quality gate agora prefere functional_tags persistidos sobre re-derivação heurística (P1.a resolvido).
- **Avaliação Hermes**: Adições significativas e bem estruturadas. `verifySwapIntegrity` definido mas sem call-sites — integridade de swaps é unilateral (hash gerado, nunca verificado). Ver task P1 abaixo. Novas rotas não documentadas em API_CONTRACTS_AND_DATA_MAP.md. Sem testes para o módulo de swap integrity.
- **Verificação**: `dart analyze lib/` — No issues found. 619/619 Dart tests passam com JWT_SECRET. Novas migrations incluem `down` reversível.

---

## Novos commits nesta rodada (2026-06-01)

### `592443e0` — Fix production route helper startup (hotfix)

- **3 arquivos**, **+16/-17 linhas**
- **Tipo: CODE/HOTFIX** — Move helpers de `routes/ai/optimize/` para `lib/ai/` para corrigir startup de produção
- Arquivos: `optimize_route_internal.dart`, `optimize_response_support.dart` → `lib/ai/`
- **Avaliação Hermes**: Sem risco de regressão. Nenhum outro arquivo importava dos paths antigos. Export contract preservado via `index.dart`. Docs canônicos referenciam por nome (sem path), sem drift. Nenhum teste afetado.
- **Verificação**: `git grep` nos paths antigos → zero referências externas. Imports internos atualizados corretamente.

### `d470bfe0` — Harden strategic functional role heuristics (atual HEAD)
- **2 arquivos** (`optimization_functional_roles.dart`, `optimization_quality_gate_test.dart`)
- **Tipo: CODE/FEATURE** — Hardening das heuristicas de classificacao de papeis funcionais estrategicos:
  1. **Name-aware heuristics**: `_looksLikeWincon`, `_looksLikeComboPiece`, `_looksLikePayoff`, `_looksLikeEnabler` agora recebem `name` como parametro adicional, permitindo hardchecks por nome (Thassa's Oracle, Blood Artist, Isochron Scepter, Dramatic Reversal, Lightning Greaves, Swiftfoot Boots).
  2. **Nova funcao `_looksLikeSelfMillSetup`**: detecta self-mill (mill, surveil, dredge) excluindo mill ofensivo (target opponent/player).
  3. **`_looksLikePayoff` reescrito**: regex para exclusao de cost reduction, distingue draw-scaling de payoff, detecta padroes "for each", inclui triggers de creature dies/enters/cast.
  4. **`_looksLikeEnabler` expandido**: greaves/boots, cost reduction com sintaxe de chaves, extra land, haste enablers, sacrifice outlets, library search (nao-land).
  5. **`_looksLikeWincon` expandido**: "each opponent loses", "damage equal to"+"opponent", "double your life total".
  6. **`_looksLikeComboPiece` expandido**: "copy target activated or triggered ability", "infinite".
- **Impacto:** Classificacao de papeis mais precisa para cartas de borda (Blood Artist→payoff, Isochron Scepter→combo_piece, Lightning Greaves→protection). Reduz falsos positivos em cost-reduction texts.
- **Validacao:** `dart analyze` — No issues found. `dart test` 599/599 PASS. Novo teste parametrizado `keeps strategic heuristic roles aligned with multi-tag classifier` com 6 amostras.
- **Risco de contrato:** Nenhum — mudancas internas as heuristicas; APIs publicas mantem a mesma assinatura. Adicao do parametro `name` nas funcoes privadas sem impacto externo.

### `6af73d87` — P1: fix semantic drift — optimize_request_support now loads card_function_tags in SQL queries
- **2 arquivos** (`optimization_functional_roles.dart`, `optimize_request_support.dart`)
- **Tipo: CODE/FIX** — Corrige drift semantico: o pipeline de optimize nao carregava `card_function_tags` nas queries SQL, causando divergencia entre a analise de deck (que carrega) e o optimize (que nao carregava). `classifyOptimizationFunctionalRole` agora recebe `functionalTags` via adapter F1, resolvendo a discrepancia.
- **Impacto:** Cartas double-null (Scroll Rack, Penance) agora tem seus functional_tags persistidos consultados pelo optimize, reduzindo classificacoes incorretas.

### `798317af` — Harden deck rules and goldfish curve checks (atual HEAD)
- **5 arquivos** (`goldfish_simulator.dart`, `deck_rules_service.dart`, `goldfish_simulator_test.dart`, `optimization_quality_gate_test.dart`, `optimization_rules_test.dart`)
- **Tipo: CODE/FEATURE** — Duas melhorias de hardening:
  1. **Goldfish Simulator**: Adiciona `noPlayTurn3Rate` — mede a taxa de maos sem jogada ate o turno 3. Nova recomendacao quando >12% sugere ramp/compra/interacao barata. Campo `no_play_turn_3` adicionado ao JSON de saida.
  2. **Deck Rules Service**: Adiciona `normalizePhysicalCardCopyName()` — normaliza nomes MDFC/split (`"Face A // Face B"` → `"face a"`) para que cartas da mesma carta fisica compartilhem a mesma chave no limite de copias. Nova classe `_CopyCounter` substitui `Map<String, Map>`.
- **Impacto:** Resolve P1-e (GoldfishSimulator sem noPlayT3). Endurece validacao de limite de copias para MDFC — nomes split agora contam como a mesma carta fisica.
- **Validacao:** `dart test` 82/82 PASS (15 goldfish + 15 quality_gate + 38 optimization_rules + 14 goldfish_simulator). Novo teste TC013b para `normalizePhysicalCardCopyName`. Teste `reports no-play turn 3 risk` para metrica nova.
- **Risco de contrato:** `no_play_turn_3` e aditivo no JSON — nao quebra consumidores existentes. `normalizePhysicalCardCopyName` e funcao publica exportada mas sem chamadores externos conhecidos.

### `23cfc061` — Dead code round 2: remove E2E scripts, QA dir, Python scorecard; archive 9 historical .md files
- **18 arquivos**, **4.172 linhas removidas**
- **Tipo: CODE/HIGIENE** — Remove scripts de E2E optimization, diretorio QA, Python scorecard. Arquiva 9 relatorios historicos em `archive_docs/root/`. Segunda rodada de limpeza apos o cleanup inicial (8cab6400).

---

## Novos commits nesta rodada (2026-05-31)
### `d3cfaf3b` — Architecture: add resetForTesting/clear/reset to all singletons (atual HEAD)
- **18 arquivos** (9 serviços × 2 arquivos cada: source + test)
- **Tipo: CODE/TEST-INFRA** — Adiciona métodos `resetForTesting()`, `clear()`, `reset()` a 9 singletons: ApiClient, PerformanceService, PushNotificationService, EdhrecService, OptimizeJobStore, RateLimiter, AuthService, Database, AiGenerateJobStore
- **Impacto:** Permite isolamento de estado entre testes, eliminando shared state que causava falhas intermitentes

### `a6b60d59` — Test: fix 2/3 flutter failures — golden baseline, shared state
- **Tipo: CODE/FIX** — Corrige golden test baseline e adiciona SharedPreferences.clear() no setUp/tearDown

### `0e4ffd0e` — Test: add setUp/tearDown to deck_provider_support and life_counter tests
- **Tipo: CODE/FIX** — Reduz shared state entre testes Flutter

### `d3d924da` — Test: update home_hero_sma135m golden baseline
- **Tipo: CODE/FIX** — Atualiza baseline golden para refletir rendering atual

### `8cab6400` — Dead code cleanup: remove 64 one-shot scripts + ~30 test artifact directories
- **828 arquivos**, **~1.2M linhas removidas**
- **Tipo: CODE/HIGIENE** — Remove scripts únicos (migrations/backfill/demo/debug/python), logs, .bak, e diretórios de test artifacts não referenciados. Mantém apenas sistema de migração ativo e artifacts referenciados por testes
- **Segurança:** Apenas remoção — sem mudança de lógica de negócio; artifacts em uso preservados

### `2880a94c` — Fix: restore test artifact referenced by external_commander_meta_candidate_support_test
- **Tipo: CODE/FIX** — Restaura artefato de teste que foi removido incorretamente no cleanup anterior

---

## Novos commits anteriores (2026-05-30 a 2026-05-31)

### `21768cca` — Layout: add tablet viewport test (820px) to deck_card_overflow_test (2026-05-30, atual HEAD)
- **1 arquivo**, **+16 linhas**
- **Tipo: TEST/LAYOUT** — Teste de viewport tablet (820px) para deck_card_overflow_test

### `8ef05d99` — Layout: add overflow test for TradeDetailScreen
### `df889a38` — Layout: add overflow test for BinderTabContent
### `e113215f` — Layout: add overflow test for LotusLifeCounterScreen
- **Tipo: TEST/LAYOUT** — Suite de testes de overflow/responsividade para telas core (320px, 375px, 280px + text scaler)

### `49b6b1e1` — docs: comprehensive layout test map
- **1 arquivo**, **+134 linhas**
- **Tipo: DOC** — Mapeamento completo de testes de layout: overflow, golden, responsive, WebView DOM

### `7ed5b863` — P3: Update CONTEXTO_PRODUTO_ATUAL.md
- **1 arquivo**, **+51 linhas**
- **Tipo: DOC** — Reflete extrações F0-F3, bracket expansion, card_deck_profiles, status Hermes

### `3fb17356` — P2: Expand _looksLikePayoff to detect direct damage payoffs
- **1 arquivo**, **+4 linhas**
- **Tipo: CODE/FEATURE** — ETB/cast triggers (Impact Tremors, Guttersnipe, Purphoros) agora detectados como payoff

### `d8b7b26b` — P1: Integrate card_deck_profiles into filterUnsafeOptimizeSwapsByCardData
- **1 arquivo**, **+23 linhas**
- **Tipo: CODE/FEATURE** — Protege cartas core da remoção, permite swaps de filler cards

### `ae886b11` — P1: Expand BracketCategory enum with 5 new categories
- **1 arquivo**, **+122 linhas**
- **Tipo: CODE/FEATURE** — boardWipe, cardAdvantage, stax, protection, valueEngine. Agora detecta 53/53 Game Changers

### `516e79cc` — Cleanup: remove duplicate response builders from index.dart
- **1 arquivo**, **-86 linhas**
- **Tipo: CODE/HIGIENE** — Remove 88 linhas duplicadas (já em optimize_response_support.dart)

### `0aa939eb` — Fix P2: add wipe to _criticalRolesForArchetype for all archetypes
- **2 arquivos**, **+8 linhas**
- **Tipo: CODE/FIX** — Alinha _looksLikeOffThemeRoleSwap, validação estrita para Commander imports

### `2320310c` — F3d: Extract optimize_route_internal.dart (430 lines) from optimize/index.dart
- **2 arquivos**, **+584 linhas**
- **Tipo: CODE/MODULARIZATION** — optimize/index.dart: 3589→3162 linhas

### `e201d4b0` — Docs: list all truthy values for SEMANTIC_LAYER_V2_EXPANDED_CRITICAL_ROLES flag
- **Tipo: DOC** — Documentação de valores truthy aceitos

### `e84f3457` — F3: Extract optimize_filler_loader_support.dart (~1300 lines)
- **4 arquivos**, **+1342 linhas**
- **Tipo: CODE/MODULARIZATION** — optimize_runtime_support.dart: 4028→2718 linhas

### `8b4ed523` — Fix: resolve merge test failures
- **2 arquivos**, **+13 linhas**
- **Tipo: CODE/FIX** — curated name priority em _selectPrimaryRole + testes atualizados

### `797d6518` — Merge master: resolve conflicts in optimization_functional_roles and tests
- **6 arquivos**, **+71 linhas**
- **Tipo: CODE/MERGE**

### `9230ae93` — Add Hermes operating protocol
- **1 arquivo**, **+84 linhas**
- **Tipo: DOC** — Protocolo operacional Hermes

### `45431b41` — Fix semantic optimize route contract analysis
- **Tipo: CODE/FIX**

### `0f583310` — F3: Plan for breaking optimize gargalhos into submodules
- **2 arquivos**, **+223 linhas**
- **Tipo: DOC/PLAN** — Plano de modularização do domínio optimize

### `a751fa5c` — F2: Add migration to remove unused write-only tables
- **1 arquivo**, **+16 linhas**
- **Tipo: CODE/DB** — Migração para remover tabelas write-only não utilizadas

### `eb051a80` — F1: Card Roles adapter — unify functional role resolution
- **1 arquivo**, **+363 linhas**
- **Tipo: CODE/REFACTOR** — Unifica resolução de roles funcionais

### `2ad9a55a` — F0: Semantic V2 expanded critical roles behind flag
- **3 arquivos**, **+70 linhas**
- **Tipo: CODE/FEATURE** — Base do feature flag para expanded critical roles

---

## Novos commits anteriores (2026-05-29)

### `3f7d784f` — Guard expanded semantic roles behind flag (2026-05-29, atual)
- **7 arquivos**, código + doc + testes.
- **Tipo: CODE/FEATURE-FLAG** — Introduz `resolveSemanticV2ExpandedCriticalRoles()` e propaga `expandedCriticalRoles` em todo o pipeline de enforcement. Default seguro: expanded roles ficam review-only. Flag `SEMANTIC_LAYER_V2_EXPANDED_CRITICAL_ROLES` (valores: `1/true/yes/on/expanded`) ativa bloqueio.
- **Validação:** `dart analyze lib/ai/optimization_functional_roles.dart lib/ai/functional_card_tags.dart lib/edh_bracket_policy.dart routes/ai/optimize/index.dart` — sem erros. `dart test` 599/599 PASS.
- **Status Hermes:** P1 encontrada — doc no `API_CONTRACTS_AND_DATA_MAP.md` não lista todos os valores truthy aceitos. P1 encontrada — `classifyOptimizationFunctionalRole` não consulta `functional_tags` persistidas.

### `c3531df7` — Cover semantic v2 low confidence fallback (2026-05-29)
- **1 arquivo**, teste.
- **Tipo: QA/GUARDRAIL** — adiciona teste provando que `semantic_tags_v2` com baixa confiança e role incorreta e ignorado, caindo para heuristica de `oracle_text`.
- **Validação:** `dart analyze bin lib routes test`, `dart test` em `server/` com 613 testes, `dart test test/optimization_quality_gate_test.dart -r expanded`, `git diff --check`, scan simples de secrets, smoke Hermes pos-push.
- **Status Hermes:** reclassifica o achado P2 de fallback como comportamento ja implementado e agora coberto por teste.

### `a466adb6` — Harden deck simulation card ownership
- **2 arquivos**, rota + source guard.
- **Tipo: CODE/SECURITY** — `GET /decks/:id/simulate` agora reforca owner-scope tambem na query de `deck_cards`, via `JOIN decks d ON d.id = dc.deck_id` e `AND d.user_id = CAST(@userId AS uuid)`.
- **Validação:** `dart analyze bin lib routes test`, `dart test` em `server/` com 612 testes, `dart test test/experimental_deck_ai_authorization_source_test.dart -r expanded`, `git diff --check`, scan simples de secrets, smoke Hermes pos-push.
- **Status Hermes:** fecha a recomendacao P2 de defense-in-depth em `simulate/index.dart`.

### `1463732a` — Clarify payoff functional tag rules
- **2 arquivos**, codigo + testes.
- **Tipo: CODE/QA** — Refatora `_looksLikePayoff` para branches explicitos, removendo a fragilidade de precedencia apontada no `LOGIC_COHERENCE_REPORT_2026-05-29.md`.
- **Validação:** `dart analyze bin lib routes test`, `dart test` em `server/` com 612 testes, `dart test test/functional_card_tags_test.dart -r expanded`, `git diff --check`, scan simples de secrets, smoke Hermes pos-push.
- **Status Hermes:** fecha o achado P1 de payoff; `Impact Tremors` segue como payoff e `The One Ring` fica `draw+protection`, nao `payoff`.

### `dafffc1b` — Remove unused backend helper APIs
- **4 arquivos**, codigo + testes.
- **Tipo: CODE/HIGIENE** — Remove helpers publicos sem chamador runtime: `tryGetRequestId`, `normalizedCommanderReferenceCandidate`, `buildCandidateQualitySamplePoolSql` e `extractMtgTop8FormatCodeFromSourceUrl`.
- **Validação:** `dart analyze bin lib routes test`, `dart test` em `server/` com 612 testes, testes focados de request trace, Commander Reference, MTGTop8 e candidate quality, `git diff --check`, scan simples de secrets, smoke Hermes pos-push.
- **Status Hermes:** reduz a pendencia de "helpers publicos sem chamador"; `PerformanceService` permanece como API publica intencional de observabilidade mobile, nao como item para remocao automatica.

### `a830f9f3` — Make local test server wrapper analyzable
- **1 arquivo**, wrapper operacional.
- **Tipo: CODE/INFRA** — `server/bin/local_test_server.dart` deixou de importar `.dart_frog/server.dart` estaticamente e passou a executar o artefato gerado como processo filho.
- **Validação:** `dart analyze bin/local_test_server.dart`, smoke local em `PORT=18082`, shutdown por `SIGTERM`, backend analyze/test completo.

### `4913a733` — Expose optimize bracket diagnostics
- **1 arquivo**, **+XX linhas** (route diagnostics)
- **Tipo: CODE** — Expondo bracket policy diagnostics no response body

### `1aa4da71` — Enforce bracket state in optimize fillers
- **loadBroadCommanderNonLandFillers**: `currentDeckCards` passado em 3 chamadas que antes usavam `const []` — bracket policy agora via estado real do deck durante construção.

### `a018ee17` — Fix optimize authorization and chat error states
- **Auth**: `/ai/optimize` agora verifica `userId != null` antes de processar; `verifyOptimizeDeckAccess` chamado ANTES de `OptimizeJobStore.create`.
- **Chat**: `chat_screen.dart` — erro de send agora preserva texto no controller + mostra SnackBar.

### `cf225841` — Preserve semantic v2 multi-tags in optimize
- **functional_card_tags.dart**: `FunctionalDeckSummary` source priority mudou de `persisted_then_heuristic` para `functional_tags_then_semantic_v2_then_heuristic`.
- **`_looksLikePayoff`**: correção parcial — adicionado filtro `!oracle.contains('costs {')` e `!oracle.contains('costs {1} less')` mas com precedência de operadores frágil (ver P1 no LOGIC_COHERENCE_REPORT).

### `aa3ee1ba` — Centralize basic land detection
- **basic_land_utils.dart** (novo): 4 funções (`normalizeBasicLandName`, `isBasicLandName`, `isBasicLandTypeLine`, `isBasicLandCard`). Migrado em 6 arquivos.

### `00437690` — Centralize commander fallback policy
- **commander_fallback_policy.dart** (novo, 237 linhas): 8 constantes + 1 função `commanderFoundationNamesFor()`.
- `candidate_quality_data_support.dart` e `optimize_runtime_support.dart` migrados.

### `81335e26` — Use semantic v2 in functional deck summary
- `summarizeFunctionalTagsForDeck`: prioridade agora é persisted > semantic_v2 > heuristic (antes: persisted > heuristic).

### `65f30387` — Scope archetype deck access by owner
- `/ai/archetypes` route: `AND user_id = CAST(@user_id AS uuid)` adicionado no SQL.

### `25416ec2` — Document semantic v2 optimize scorecard
- Scorecard runner atualizado com fixture `optimize_scorecard_disabled_public_cf225841.json` (393 linhas).

### `2396956e` — Wire sync cards utilities into pipeline
- **sync_cards_utils.dart** (novo) + **sync_cards.dart** refatorado (-181 linhas).

### `5c327b76` — Centralize candidate quality name policies
- `candidate_quality_data_support.dart` migra para `commander_fallback_policy.dart`.

### `e9940672` — Document ready alias contract
- Documentação apenas.

### `2999c346` — Harden experimental deck AI ownership
- Preparação para ownership enforcement em rotas experimentais.

### `640f4ab4` — Fix community navigation cycle
- `community_deck_detail_screen.dart`: `Navigator.push` → `context.push('/community/user/...')` via go_router.
- `user_profile_screen.dart`: mesmo pattern para CommunityDeckDetailScreen.

---

### `771c9318` — Harden semantic scorecard runner (2026-05-27T18:40Z)
- **3 arquivos**, **+359/-17 linhas** (script Python + relatório + fixture JSON)
- **Tipo: CODE/INFRA** — Robustecimento do runner de scorecard semântico

Commits anteriores mantidos como referência abaixo.
- **5 arquivos**, **+362/-5 linhas** (código + script + testes)
- Autor: softwarePredador (Co-authored-by: Copilot)
- Data: 2026-05-27 15:08 BRT
- **Tipo: CODE** — Melhora o gate de qualidade de otimização para cartas com múltiplas tags funcionais
  - `optimization_quality_gate.dart`: Adiciona `_functionalRolesForGate()` que resolve múltiplas funções por carta via `inferFunctionalCardTags()` + `_gateRoleForFunctionalTag()`. Troca comparação single-role por interseção de sets de roles (`removedRoles.intersection(addedRoles).isNotEmpty`). Mensagens de droppedReasons agora mostram funções completas (`draw+ramp` vs `utility`).
  - `semantic_layer_v2_optimize_scorecard.py`: Adiciona `log_progress()` para debug de timeout global, deadline-based early exit, structured progress events no stderr, elapsed_ms no summary.
  - `optimization_quality_gate_test.dart`: +2 testes novos (preserves critical ramp on multi-tag cards, blocks loss of secondary protection on multi-function swaps).
  - `RELATORIO_OPTIMIZE_MULTITAG_GATE_2026-05-27.md`: Relatório de implementação.
  - `optimize_scorecard_progress_smoke_timeout30.json`: Smoke test fixture.
- **Validação:** `dart test optimization_quality_gate_test.dart` = 13/13 PASS. `dart test` completo = 585 pass / 18 fail (18 pre-existing em auth_service_test.dart, não relacionado).

Commits anteriores mantidos como referência:

### `7329fbbd` — docs: add Hermes semantic validation request
- **1 arquivo**, **+170 linhas** (documentacao)
- Autor: softwarePredador
- Data: 2026-05-26 14:46 BRT
- **Tipo: DOC**

### `f57bb8d3` — Fix semantic role classification fallbacks
- **4 arquivos**, **+142/-6 linhas** (codigo)
- Co-authored-by: Copilot
- Data: 2026-05-26 14:27 BRT
- **Tipo: CODE**

### `91885194` — Polish secondary shell headers (rodada anterior)
- **5 arquivos**, **+52/-54 linhas**
- Co-authored-by: Copilot
- Data: 2026-05-26 10:08 BRT

### `ca0c8d52` — Polish Lotus life counter overlays (rodada anterior)
- **4 arquivos**, **+531/-2 linhas**
- Co-authored-by: Copilot (mesmo autor de softwarePredador)
- Data: 2026-05-25 16:39 BRT

### `3eebd0f6` — Refresh ManaLoom visual system (rodada anterior)
- **63 arquivos**, **+3839/-2093 linhas** — commit massivo
- Co-authored-by: Copilot

## Analise detalhada do commit 3eebd0f6

### Tema e Design System
- `app/lib/core/theme/app_theme.dart` (+225 linhas)
- Novos tokens: `fontMicro` (8px) e `fontTiny` (9px) — escala vai de 8 a 32
- AppBar reformulado: fundo `backgroundAbyss` (antes surfaceSlate), iconTheme com `textSecondary`/22px, titleTextStyle Fraunces
- Novo `FilledButtonThemeData` com brass500 + padding padrao
- OutlinedButton agora usa `brass400` em vez de `frost400`
- Novos arquivos de teste do tema: `app_theme_button_tokens_test.dart`, `app_theme_widget_tokens_test.dart`, `app_theme_token_usage_test.dart`

### Auth (novo shared widget)
- `AuthVisualShell` (225 linhas) — componente compartilhado para telas de auth
- Login screen: -373 linhas (refatorada para usar AuthVisualShell)
- Register screen: -527 linhas (mesma refatoracao)
- Splash screen: ajuste menor

### Home
- Home screen: 435 linhas alteradas
- Novo golden test para hero visual (`home_hero_sma135m.png` baseline)
- Home hero golden: 69KB PNG
- Hero art nova: `home_hero_banner.png` (252KB)
- Logo: `app_logo.png` (1.7MB)

### Community
- Community screen: 871 linhas alteradas (+504/-367) — grande refatoracao visual

### Profile
- Profile screen: 602 linhas alteradas (+388/-214)

### Card Search
- Card search: 240 linhas alteradas (+147/-93)

### Messages/Notifications
- Message inbox: 208 linhas alteradas
- Chat screen: 12 linhas
- Notification screen: 16 linhas

### Testes adicionados
- `home_screen_test.dart`: golden test para hero visual + asserts de novos CTAs
- `app_theme_button_tokens_test.dart`, `app_theme_widget_tokens_test.dart`, `app_theme_token_usage_test.dart`

### Agente UX Design Auditor
- `manaloom-ux-design-auditor.agent.md`: reescrita completa (+767/-207)
- Agente agora tem modelo `gpt-5.5`
- Descricao expandida para "Elite UX/UI auditor for ManaLoom mobile"
- Diretrizes premium de produto: atmosferico, premium, cinematografico, game-native

### Documentacao
- `app/test/README.md`: instrucao para golden test do hero
- Runtime handoff: `manaloom_meus_decks_visual_system_iphone15_2026-05-22.md` (146 linhas)
- Layout uniformity audit: `manaloom_layout_uniformity_audit_iphone15_2026-05-22.md` (158 linhas)

### Assets novos
- `app/assets/branding/app_logo.png` (1.7MB)
- `app/assets/branding/home_hero_banner.png` (252KB)
- `nrelogo.png`, `nrelogos.png`, `slasharat.png` na raiz (arquivos fonte)

## Analise do commit 9a2bb38b — Lotus

- `lotus_visual_skin.dart`: skin CSS injetada no WebView do life counter
- Acabamento premium: cada um dos 4 jogadores agora tem cor de acento propria
  - J1: gold/warm (`#d89a2f`)
  - J2: blue (`#78a8ff`)
  - J3: purple (`#9a7cff`)
  - J4: green (`#4ed691`)
- Player cards com gradientes radiais + box-shadows + blend modes
- Saturação reduzida (0.62 vs 0.84) para aparencia mais cinematica e premium
- Cada player card tem glow, accent-soft e accent-faint como variaveis CSS
- Validacao adicional local em 2026-05-25 confirmou tela principal, radial menu,
  history, settings e card search em iPhone Simulator; ajustes de harness/skin
  posteriores a este HEAD ainda devem ser commitados antes de virarem baseline canonica.

## Analise do commit ca0c8d52 — Lotus Overlays Polish

Este commit expandiu `lotus_visual_skin.dart` em +423 linhas na epoca do commit,
com CSS premium para tres overlays do Lotus WebView. Na higiene semanal de
2026-05-27, o arquivo completo em `origin/master` soma 1991 linhas por incluir
tambem commits anteriores da skin Lotus:

- **Settings overlay** (`Configurações`): posicionamento fixed full-viewport,
  safe-area-aware, fundo gradiente radial + linear, lista de itens com cards
  arredondados (20px), glassmorphism com `linear-gradient(180deg, rgba(13,22,42,0.8), rgba(6,11,24,0.72))`, bordoas sutis e sombra profunda.
- **Life history overlay**: timeline com tipografia `manaloom-display-font`,
  identidade visual consistente.
- **Card search overlay**: titulo `Buscar carta` posicionado, resultados com
  `card-name` estilizado, estrutura de pesquisa integrada ao tema premium.

Tres arquivos de smoke test foram atualizados/criados:
- `life_counter_lotus_card_search_visual_smoke_test.dart` (+59 linhas)
- `life_counter_lotus_settings_visual_smoke_test.dart` (+23 linhas)
- `life_counter_lotus_visual_overlays_smoke_test.dart` (+28 linhas, novo)

**Nao alterado**: backend, contratos API, core de decks, IA, ou outras
superficies do app. O arquivo `lotus_visual_skin.dart` continua sendo CSS
injetado no WebView, fora do sistema de tema Flutter.

**Status dos overlays**: settings, history e card search agora tem skin
premium, mas ainda precisam de prova viva lado a lado com `dddddd/` (baseline
pre-skin) para cada overlay antes de considerar a task de perfeicao fechada.

## Analise do commit 91885194 — Polish secondary shell headers

Este commit padroniza os AppBars de quatro telas secundarias, unificando
as seguintes propriedades em todas elas:

- **toolbarHeight: 54** (antes era 52 na Collection, inexistente nas demais)
- **centerTitle: true** (antes centralizacao era inconsistente)
- **titleTextStyle**: `titleMedium.w700` + `displayFontFamily` + `fontLg + 1`
- **surfaceTintColor: transparent**

### Impacto no design system

1. **Community screen** (`community_screen.dart`):
   - fontWeight: w800 → w700 (resolve o risco P1 documentado em OPEN_RISKS.md)
   - toolbarHeight adicionado (era ausente)
   - centerTitle adicionado

2. **Profile screen** (`profile_screen.dart`):
   - fontWeight: w800 → w700 (mesma correcao)
   - toolbarHeight e centerTitle adicionados

3. **Collection screen** (`collection_screen.dart`):
   - toolbarHeight: 52 → 54
   - **IconButton para `/collection/sets` removido** — o entry point direto para o catalogo de colecoes via AppBar foi eliminado. O acesso permanece via TabBar (aba "Colecoes"). Risco de usabilidade: usuarios que usavam o icone grid_view_rounded para navegacao rapida perdem esse atalho.
   - centerTitle adicionado
   - `go_router` import removido (redundante apos remocao do push)

4. **Market screen** (`market_screen.dart`):
   - **Tracker de cartas monitoradas removido do AppBar**: o badge com `provider.moversData!.totalTracked` nao aparece mais no header. O dado `moversData` continua disponivel no corpo da tela (loading/error states e listagem). Perda de visibilidade do total de cartas monitoradas sem navegacao extra.
   - Removeu padding, centralizou titulo e padronizou estilo

5. **Test file** (`collection_entrypoints_runtime_test.dart`):
   - Migrou de `find.widgetWithText(Tab, 'Marketplace')` para `find.byKey(Key('collection-tab-market'))`
   - Mesmo padrao para Trades, Colecoes e Fichario
   - Torna os testes mais resilientes a mudancas de texto e consistentes com UI_TEST_SURFACE_MAP.md

### Arquivos alterados

| Arquivo | Tipo | Mudanca |
|---------|------|---------|
| `app/lib/features/collection/screens/collection_screen.dart` | UI | AppBar padrao, remocao do atalho sets |
| `app/lib/features/community/screens/community_screen.dart` | UI | w800→w700, centerTitle |
| `app/lib/features/market/screens/market_screen.dart` | UI | AppBar padrao, remocao movers counter |
| `app/lib/features/profile/profile_screen.dart` | UI | w800→w700, centerTitle |
| `app/integration_test/collection_entrypoints_runtime_test.dart` | Test | Keys estaveis em vez de texto |

### Validacoes Linux (Hermes container)

- **dart test**: 599/599 passed (era 589 na rodada anterior)
- **flutter analyze**: No issues found

**Nao alterado**: backend (0 arquivos), contratos API, core de decks, IA, rotas.

## Analise do commit f57bb8d3 — Fix semantic role classification fallbacks

Este commit aplica o patch de fallbacks deterministicos para classificacao de roles
funcionais que foi planejado, validado e simulado em `PATCH_PLAN.md`.

### Mudancas em `optimization_functional_roles.dart`

- **Novas listas curadas**:
  - `_knownWinconNames` (11 cartas: Walking Ballista, Laboratory Maniac, Thassa's Oracle, etc.)
  - `_knownEngineNames` (14 cartas: The One Ring, Rhystic Study, Seedborn Muse, etc.)
  - `_knownComboPieceNames` (11 cartas: Basalt Monolith, Dramatic Reversal, Underworld Breach, etc.)
  - `_knownProtectionNames` (7 cartas: Fierce Guardianship, Deflecting Swat, Heroic Intervention, etc.)
- **Ordem de avaliacao**: listas curadas sao avaliadas ANTES dos fallbacks de oracle text
  (`draw`, `removal`, `ramp`), corrigindo:
  - Walking Ballista: `removal` → `wincon`
  - The One Ring: `draw` → `engine`
  - Basalt Monolith: `ramp` → `combo_piece`
  - Fierce Guardianship: `protection` (agora detectado por nome, nao por regra global de counters)
  - Endurance: `other` → `protection`
- **Nao altera**: `semantic_tags_v2` continue em shadow mode; nenhum enforcement novo

### Mudancas em `edh_bracket_policy.dart`

- Adiciona `hasFreeCast` (oracle contem `without paying`) ao lado da heuristica `hasPitch`
- Fierce Guardianship, Deflecting Swat e Deadly Rollick agora sao detectados como
  `freeInteraction` — antes so `rather than pay` era detectado
- Sem mudanca na logica de contagem de bracket ou categorias existentes

### Testes novos

- `test/optimization_quality_gate_test.dart`: teste parametrizado para os 5 exemplos curados
  (Walking Ballista→wincon, The One Ring→engine, Basalt Monolith→combo_piece,
  Fierce Guardianship→protection, Endurance→protection)
- `test/optimize_runtime_support_test.dart`: teste especifico para Fierce Guardianship
  como `freeInteraction` no bracket system

### Diferenca entre PATCH_PLAN.md e implementacao real

- A lista `_knownWinconNames` no plano inclui `'test of talents'` (12 cartas);
  a implementacao real tem 11 cartas (sem test of talents). A versao real e a
  conservadora e correta — test of talents nao e wincon consistente.
- O plano sugeria uma exclusao de `remove a +1/+1 counter` no bloco de removal;
  a versao real e mais simples: so adiciona verificacao por nome antes do bloco
  de oracle text, sem modificar o bloco de removal. Isso e mais seguro.

### Validacoes Linux (Hermes container)

- **dart test**: 599/599 passed (revalidado em 2026-05-27)
- **flutter analyze --no-pub --no-fatal-infos**: No issues found (revalidado em 2026-05-27)
- **dart analyze** dos 4 arquivos alterados: PASS historico
- **Backend publicado**: `7329fbbd` contem `f57bb8d3` por ancestralidade Git

**Nao alterado**: contratos API, core de decks (app), rotas, visual system, deploy.

## Analise do commit 7329fbbd — docs: add Hermes semantic validation request

- Adiciona `docs/qa/HERMES_VALIDATION_REQUEST_SEMANTIC_FALLBACKS_2026-05-26.md`
- Documento formalizando 10 perguntas que o Hermes deve responder sobre o patch
- Nao altera codigo, rotas, contratos ou UI

### Projeto entrou oficialmente na Onda 6: Premium Visual System
O commit `3eebd0f6` estabelece um **design system premium completo**:
- Tema global refatorado (AppBar, buttons, font scale)
- Componentes visuais compartilhados (AuthVisualShell)
- Golden tests para hero
- Agente UX auditor dedicado com gpt-5.5
- Runtime proofs visuais

### Implicacoes
1. **Design system agora tem testes dedicados** — 3 novos arquivos de teste de tokens
2. **Home hero tem golden test** — baseline visual protegida contra regressao
3. **Auth screens refatoradas** — +225 linhas de componente compartilhado, ~900 linhas removidas das telas
4. **Life counter Lotus atingiu acabamento premium** — CSS skin com identidade por jogador + overlays settings/history/card search premium
5. **Projeto esta usando Copilot como co-author** — commits assinados por Copilot
6. **Agente UX auditor elevado para gpt-5.5** — ambicao de qualidade visual de produto premium

### O que NAO mudou
- Backend: **alterado** — `optimization_functional_roles.dart` e `edh_bracket_policy.dart` receberam o patch
- IA/Rotas: rota de optimize nao foi alterada; a classificacao de roles foi endurecida internamente
- Contratos app/backend: inalterados
- Core de decks: inalterado (nenhuma tela de decks foi tocada)
- Scrum/prioridades Sprint 1/2: mesmas pendencias abertas
- Visual system: inalterado (apenas UM commit de doc, um de IA classificacao)

## Ondas de commit atualizadas (HEAD~80)

| Onda | Periodo | Commits | Tema |
|------|---------|---------|------|
| 6 | 2026-05-25/26 | 4 | **Premium Visual System** — tema global, AuthVisualShell, golden tests, Lotus skin + overlays premium, secondary shell headers unificados, agente UX auditor |
| **7** | **2026-05-26** | **2** | **AI Classification Hardening** — fallbacks deterministicos para roles funcionais (wincon, engine, combo_piece, protection), bracket free-cast detection, doc de validacao semantica |
| 1 | 2026-05-21/25 | 12 | UX Polishing — home, splash, icon, premium UX, card/deck screens |
| 2 | Abril-Maio | ~30 | Semantic Layer v2 |
| 3 | Maio | ~15 | Functional Tags + Localized Import |
| 4 | Abril-Maio | ~50 | Commander Reference |
| 5 | Marco | ~5 | Observabilidade + Infra |

## Direcao do projeto

1. **Premium Visual System** — design system, golden tests, componentes compartilhados, audiencia UX
2. **AI Classification Hardening (ATIVO nesta rodada)** — fallbacks deterministicos para accurate role classification; proximo passo e reavaliar enforcement do Semantic Layer v2
3. **Convergencia para o core** — decks, otimizacao, geracao, analise
4. **Qualidade de IA** — semantic tags, functional tags, Commander Reference
5. **Observabilidade** — Sentry, x-request-id
6. **Produto global** — icon, splash, onboarding

## O que esta fora dos commits recentes / nao consolidado neste digest

- Scanner/OCR — DEFERRED
- Community expansion — manutencao apenas
- Trades/Binder — manutencao apenas
- Carga/thresholds — nao iniciado
- Sentry mobile — pendente
- CHECKLIST_GO_LIVE — desatualizado
- Ajustes locais nao commitados no workspace principal nao contam como `master`
  ate virarem commit/push; este digest observa o `origin/master`.

## Higiene semanal 2026-05-27

- `origin/master` permanece em `7329fbbd`; `git log 7329fbbd..origin/master` vazio.
- `/health.git_sha` confirmou `7329fbbdd0d5ea3e88de50d3c8235e76852380f4`.
- `dart test` no backend: 599/599 passed.
- `flutter analyze --no-pub --no-fatal-infos` no app: No issues found.
- Reconciliacao documental feita sem criar novos riscos de produto: alguns itens de UI foram ajustados para refletir cobertura existente (Profile/Trade/Marketplace) e tamanhos reais (`lotus_visual_skin.dart` agora 1991 linhas em `origin/master`).

## Como atualizar este digest

```bash
cd /opt/data/workspace/mtgia
git fetch --all --prune
BASE_PREVIO=$(git rev-parse origin/codex/hermes-analysis-docs)
# Para ver o que mudou na master desde a ultima analise:
git log --oneline --decorate --stat $BASE_PREVIO..origin/master
```
<!-- commit nonce: 1 -->

### `6fa76bac` — P1-c+d: refactor weakness-analysis to use F1 adapter + add wincon to _criticalRolesForArchetype (2026-05-31)
- **2 arquivos**, **+34/-101 linhas**
- **Tipo: REFACTOR/P1** — weakness-analysis substitui ~80 linhas de heuristicas oracle_text por resolveCardFunctionalRoles()
- _criticalRolesForArchetype agora inclui 'wincon' para todos os arquetipos

### `84553ef8` — P2-c + P3-c: document write-only tables + manual-de-instrucao update (2026-05-31)
- **1 arquivo**, **+34 linhas**
- **Tipo: DOC/MANUAL** — Deck_matchups, deck_weakness_reports, ml_prompt_feedback documentados como audit logs
- manual-de-instrucao.md atualizado com status F1/F3/bracket/weakness-analysis