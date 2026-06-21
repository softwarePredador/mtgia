# Hermes Analysis: Technical Map

> Status atual: mapa tecnico app/backend.
> Util para orientacao de produto/codigo, mas nao substitui o contrato Hermes
> E2E nem reports frescos.

> Mapa tecnico detalhado do ManaLoom. Atualizado em 2026-06-21 03:00 UTC.

## Estrutura do repositorio

```
mtgia/
├── app/                          # Flutter mobile app (SDK ^3.7.2)
│   ├── lib/features/
│   │   ├── auth/                 # Login, registro, profile
│   │   ├── decks/                # CORE — providers, screens, widgets
│   │   ├── home/                 # Home screen + life counter
│   │   ├── cards/                # Busca, detalhes, sets
│   │   ├── binder/               # Colecao pessoal
│   │   ├── market/               # Precificacao
│   │   ├── community/            # Decks publicos
│   │   ├── social/               # Seguir usuarios
│   │   ├── trades/               # Trocas
│   │   ├── messages/             # Mensagens diretas
│   │   ├── notifications/        # Notificacoes
│   │   ├── collection/           # Colecoes/catalogos
│   │   ├── scanner/              # Camera/OCR (DEFERRED)
│   │   └── profile/              # Perfil do usuario
│   ├── test/
│   ├── integration_test/         # Runtime harnesses
│   └── pubspec.yaml
│
├── server/                       # Dart Frog API
│   ├── routes/
│   │   ├── auth/*                # Login, registro, me
│   │   ├── decks/*               # CRUD, cards, validate, pricing, export
│   │   ├── ai/
│   │   │   ├── generate/         # Geracao de decks por IA
│   │   │   ├── optimize/         # Otimizacao de decks (LARGO ~2498 linhas)
│   │   │   ├── rebuild/          # Reconstrucao guiada
│   │   │   ├── explain/          # Explicacao de cartas
│   │   │   ├── archetypes/       # Opcoes de arquétipo
│   │   │   ├── simulate/         # Simulacao de partidas
│   │   │   ├── commander-learning/       # Decks aprendidos pelo Hermes (NOVO)
│   │   ├── commander-reference/
│   │   │   └── ml-status/
│   │   ├── import/*              # Importacao de listas
│   │   ├── cards/*               # Busca, resolucao, printings
│   │   ├── sets/                 # Catalogos
│   │   ├── binder/*              # CRUD da colecao
│   │   ├── market/*              # Movimentacao de precos
│   │   ├── community/*           # Decks/binders publicos, marketplace
│   │   ├── trades/*              # Ofertas, status, chat
│   │   ├── conversations/*       # Mensagens diretas
│   │   ├── notifications/*       # Lista, count, read
│   │   ├── health/*              # Health, ready, live, metrics
│   │   └── ready/                # alias operacional de /health/ready
│   ├── lib/ai/                   # ~30 arquivos de logica de IA
│   │   ├── optimize_*.dart       # Modulos do otimizador (9 arquivos)
│   │   ├── candidate_quality_data_support.dart
│   │   ├── functional_card_tags.dart
│   │   ├── goldfish_simulator.dart
│   │   ├── optimization_validator.dart
│   │   ├── rebuild_guided_service.dart
│   │   ├── commander_reference_*.dart (7 arquivos, incluindo commander_reference_helpers.dart)
│   │   ├── deck_learning_event_support.dart   # Loop de aprendizado App→Hermes (NOVO)
│   │   ├── commander_learned_deck_support.dart # Modelo/validacao de learned decks (NOVO)
│   │   └── ...
│   └── pubspec.yaml
│
├── server/lib/edh_bracket_policy.dart  # Politica deterministica de brackets EDH 1-4 (NOVO)
│
├── scripts/                      # Automacoes locais
│   ├── quality_gate.sh           # quick / full / resolution
│   ├── quality_gate_resolution_corpus.sh
│   ├── validate_sentry_backend_ingestion.sh
│   ├── validate_sentry_mobile_local.sh
│   └── validate_request_id_ready.sh
│
├── docs/                         # Documentacao ativa
│   ├── CONTEXTO_PRODUTO_ATUAL.md # Fonte de verdade
│   ├── README.md                 # Indice documental
│   ├── hermes-analysis/          # Este diretorio
│   └── qa/                       # Evidencias de QA
│
├── archive_docs/                 # Historico
├── .github/                      # CI (PowerShell gates)
├── .vscode/
└── CHECKLIST_GO_LIVE_FINAL.md
```

## Rotas da API (18 dominios)

| Modulo | Rotas principais | Status | Testes |
|--------|-----------------|--------|--------|
| Auth | login, register, me, users/me | stable | auth_flow_integration, auth_service |
| Social | community/users, community/decks, follow | stable | profile_community_runtime |
| Cards | /cards, /cards/resolve, /cards/printings, /cards/resolve/batch | stable | cards_route, card_resolution_support |
| Sets | /sets | stable | sets_catalog_runtime |
| Decks | CRUD, cards, validate, pricing, export, analysis | stable | decks_crud, decks_incremental_add, deck_validation |
| Import | /import, /import/validate, /import/to-deck | stable | import_parser, import_to_deck_flow |
| AI Generate | /ai/generate, /ai/generate/jobs/:id | experimental | ai_generate_create_optimize_flow |
| AI Optimize | /ai/optimize, /ai/optimize/jobs/:id | experimental | ai_optimize_flow |
| AI Rebuild | /ai/rebuild | experimental | (coberto por optimize flow) |
| AI Archetypes | /ai/archetypes | experimental | ai_archetypes_flow |
| AI Explain | /ai/explain | experimental | (sem teste nomeado) |
| AI Simulate | /ai/simulate, /ai/simulate-matchup | experimental | e2e_ml_tests |
| Commander Ref | /ai/commander-reference, /ai/commander-learning | experimental | commander_reference_atraxa, commander_learned_deck_support, deck_flow_entry_screens |
| Binder | CRUD, stats | stable | binder_dashboard_runtime |
| Market | /market/movers, /market/card/:id | stable | market_movers |
| Trades | CRUD, respond, status, messages | stable | social_trading_live |
| Conversations | CRUD, messages, read, unread-count | stable | (provider realtime tests) |
| Notifications | list, count, read, read-all | stable | social_trading_live (asserts type/reference_id) |
| Health | /health, /health/ready, /health/live, /health/metrics | internal/stable | health_readiness_support |

## Arquivos de maior tamanho (gargalos de manutencao)

| Arquivo | Linhas | Risco |
|---------|--------|-------|
| server/routes/ai/optimize/index.dart | 2498 | P1 — gargalo de manutencao ainda relevante |
| server/lib/ai/optimize_runtime_support.dart | 2374 | P1 — logica densa, precisa de continuidade no split modular |
| app/lib/features/home/life_counter_screen.dart | 6400 | P1 — tela/engine nativa grande; Lotus WebView tem skin separado |
| app/lib/features/home/lotus/lotus_visual_skin.dart | 1991 | P1 — CSS injetado no WebView; superficie visual propria Lotus com overlays/provas |
| app/lib/features/decks/screens/deck_details_screen.dart | 1705 | P1 — caindo, mas ainda grande |
| app/lib/features/community/screens/community_screen.dart | 1729 | P1 — 4 tabs + sub-tabs |
| app/lib/features/binder/screens/binder_screen.dart | 1628 | P1 — listas, editor, filtros |
| app/lib/features/decks/widgets/deck_analysis_tab.dart | 1632 | P1 — functional tags + graficos |
| app/lib/features/trades/screens/trade_detail_screen.dart | 1479 | P1 — timeline, chat, status, itens, trust |
| app/lib/features/decks/providers/deck_provider.dart | 1226 | P1/P2 — voltou a crescer; residual/orquestracao |
| server/manual-de-instrucao.md | 17741 | N/A — documentacao |
| app/doc/APP_AUDIT_2026-04-29.md | 2222 | N/A — auditoria |
| server/doc/API_CONTRACTS_AND_DATA_MAP.md | 369 | N/A — contratos |

## Qualidade e validacao

- `flutter analyze --no-pub --no-fatal-infos`: VERDE, No issues found (2026-06-04)
- `dart test`: VERDE, 599 tests PASS (backend, 2026-06-04)
- `dart analyze lib/`: No issues found (2026-06-04)
- `dart analyze bin/local_test_server.dart`: No issues found (2026-06-11);
  o wrapper nao importa mais `../.dart_frog/server.dart` estaticamente.
- `flutter analyze --no-pub --no-fatal-infos` app-side permanece dependente de
  `app/.dart_tool/package_config.json`, ausente neste checkout; a varredura
  local de imports de 2026-06-15 11:00 UTC encontrou 0 imports/exports/parts
  locais quebrados em `app/lib`, `server/lib`, `server/routes` e `server/bin`.
- `flutter test`: VERDE historico; nao reexecutado integralmente nesta higiene semanal
- Corpus estavel de resolucao Commander: 19/19 passed
- Quality gate: `scripts/quality_gate.sh` (quick/full/resolution)
- Testes de integracao: opt-in via `RUN_INTEGRATION_TESTS=1`

## Achados do audit de estrutura (atualizado 2026-06-21)

- **P0 — Falso-positivo em massa no auditor estrutural**: **RESOLVIDO em 2026-05-28.** `STRUCTURE_AUDIT.md` reportava 178 imports "quebrados" por resolver imports relativos a partir do root errado. `docs/hermes-analysis/scripts/structure_auditor.py` agora usa `MTGIA_REPO_ROOT`/`Path.cwd()`, resolve relativos a partir do arquivo Dart origem e reconhece imports locais `package:server/...`, `package:manaloom/...` e alias historico `package:ai/...`. Nova execucao: `Imports quebrados: 0`.
- **P1/P2 — Imports quebrados e ciclos locais fora do recorte do auditor base**:
  **REVALIDADO em 2026-06-20 11:00 UTC no checkout `2e69bb4c`.** O auditor base
  cobre apenas `server/lib` e `server/routes` e reportou `Imports quebrados: 0`.
  A triagem ampliada em 429 arquivos Dart de `app/lib`, `server/lib`,
  `server/routes` e `server/bin` resolveu 1155 diretivas locais e encontrou 0
  imports/exports/parts locais quebrados; o controle incluindo
  `app/test`, `app/integration_test` e `server/test` tambem encontrou 0
  diretivas locais quebradas em 2595 checadas. A checagem estreita de 33 scripts
  Python em `server/bin` encontrou 0 imports locais quebrados e 0 SCCs. Claims
  antigas contra `deck_analysis_tab.dart`, `life_counter_screen.dart`,
  `local_test_server.dart`, `commander-learning/index.dart` e o ciclo
  Community/Social estao stale. O ciclo backend antigo entre
  `optimize_runtime_support.dart` e `optimize_filler_loader_support.dart` foi
  fechado por modulos neutros; o unico SCC atual e
  `life_counter_tabletop_engine.dart` <->
  `life_counter_turn_tracker_engine.dart`, com analyzer focado verde.
- **P1 — Gargalos do domínio de optimize permanecem acima do aceitável**:
  revalidado em 2026-06-11 no `master@321b0f24`. Os tamanhos atuais cairam para
  `server/lib/ai/optimize_runtime_support.dart` (~2386 linhas) e
  `server/routes/ai/optimize/index.dart` (~2498 linhas), ainda acima do ideal.
  O drift de `resolveOptimizeArchetype` foi fechado com
  `server/lib/ai/optimize_archetype_support.dart`; continuam candidatos a split
  os blocos de seleção de candidatos, fallback/recovery estrutural e
  orquestração remanescente da rota.
- **P1/P2 — Coerencia app-facing de IA/deck revalidada no checkout local**:
  status 2026-06-20 23:00 UTC no checkout `7857d7ef`. Nao houve delta de
  produto/contrato em `app/lib`, `server/lib`, `server/routes` ou
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md` desde a ultima rodada deste foco.
  Ownership em `POST /ai/optimize`, `/ai/archetypes`, jobs async, activation
  telemetry e `/ai/commander-learning` permanecem saneados. O runtime de
  `swap_integrity` esta coerente entre backend e app: a rota de optimize emite o
  payload e o app valida hash/`deck_signature` antes de aplicar swaps por ID.
  Residual P2: `server/doc/API_CONTRACTS_AND_DATA_MAP.md` ainda nao documenta
  `swap_integrity`/`deck_signature` como campo opcional/aditivo de
  `/ai/optimize`. Testes/analyze backend focados verdes; testes app focados
  seguem bloqueados localmente sem `app/.dart_tool/package_config.json`.
- **P1/P2 — Helpers duplicados com risco de drift**: revalidado novamente em
  2026-06-20 19:00 UTC no checkout `b372e3ce`. Nao houve delta de produto desde
  a ultima rodada focada de duplicacao; somente docs de Hermes mudaram.
  `resolveOptimizeArchetype` segue canonico em
  `optimize_archetype_support.dart`; roles estrategicos em
  `functional_card_tags.dart` usam `resolveCardFunctionalRoles`; basic/snow
  basic lands seguem centralizados em `server/lib/basic_land_utils.dart`;
  `sync_cards.dart` ja consome `sync_cards_utils.dart`; e
  `server/bin/export_hermes_learned_deck.py` segue wrapper da implementacao
  canonica em docs. Permanecem duplicacoes relevantes em analise de estado
  rebuild/optimize (`deck_state_analysis.dart` vs `optimize_state_support.dart`),
  fallback/scoring funcional do optimize, request/log social, trust
  SQL/serializer em trades/marketplace, condition, CMC/tipo e runtime path
  resolution de alguns crons/scripts Hermes.
- **P1 — Payoff functional tag fragil por precedencia**: resolvido em
  `origin/master@1463732a`. `_looksLikePayoff` agora usa branches explicitos e
  regex para custo reduzido; testes cobrem `Impact Tremors` como payoff e
  `The One Ring` como draw/protection sem payoff.
- **P1/P2 — Pipeline semantico de cartas parcialmente saneado**: revalidado em
  2026-06-21 no checkout `7a9255cd`. Deck analysis, optimize context,
  additionsData, validator e quality gate carregam/preservam
  `functional_tags` + `semantic_tags_v2` com precedencia
  `functional_tags` persistidos -> `semantic_tags_v2` -> heuristica. A claim de
  que o quality gate mascarava multi-tags persistidas quando semantic v2 existia
  ficou stale: `_functionalRolesForGate` agora soma persisted + semantic roles.
  `/decks/:id/recommendations` e `/ai/weakness-analysis` tambem carregam snapshot
  ou fallbacks agregados e buscam sugestoes por tags/semantica/legalidade/
  identidade de cor. O risco restante fica nos pontos que ainda usam role escalar
  legado ou pool inicial sem tags: `removals_detailed`, need/replacement ranking
  inicial, rebuild guiado, prompts runtime, candidate-quality foundation, copias
  locais de basic lands em analysis/app apply e analises/corpus auxiliares.
- **P1 — Listas de nomes em runtime de cartas**: a auditoria de 2026-06-21
  manteve como permitidos exemplos de UI/import, comentarios de contrato, aliases
  localizados, docs/corpus/artifacts/test fixtures, sugestoes de busca do life
  counter e o mock dev de `/ai/optimize` marcado como `is_mock=true`. Como
  excecoes intencionais ficam `commander_fallback_policy.dart` (policy
  versionada de fallback/complete/filler) e `edh_bracket_policy.dart` (regra
  externa de bracket/Game Changer). Permanecem como risco as listas/branches por
  nome que decidem tags, roles, score, rebuild, payload/ranking ou prompt runtime
  por cartas especificas em `functional_card_tags.dart`,
  `optimization_functional_roles.dart`, `candidate_quality_data_support.dart`,
  `optimize_functional_role_support.dart`, `optimize_swap_candidate_support.dart`,
  `rebuild_guided_service.dart`, `prompt.md`, `prompt_complete.md`, copias locais
  de basic lands em analysis/app apply e analises/corpus auxiliares. Qualquer
  excecao real deve migrar para policy/tabela versionada com fonte, escopo e
  teste.

- **P1/P2 — Classes app sem uso de runtime confirmado**: revalidado novamente em
  2026-06-21 03:00 UTC no checkout local `aeb667b2`. O auditor textual executou
  com sucesso (`221` arquivos backend, `205` classes, `0` imports quebrados),
  mas continua limitado a `server/lib` e `server/routes`; a evidencia app veio
  de `rg` e leitura direta. Desde a ultima rodada de classes
  (`6244d33b..HEAD`), nao houve delta em `app/lib`, `app/test`,
  `app/integration_test`, `server/lib`, `server/routes`, `server/bin`,
  `server/test` nem `server/doc/API_CONTRACTS_AND_DATA_MAP.md`; somente docs
  Hermes mudaram. Nao surgiu novo achado confiavel. `LifeCounterScreen`
  continua legado/test-only enquanto a rota ativa usa `LotusLifeCounterScreen`;
  `DeckCard` e `DeckProgressChip` continuam sem uso runtime confirmado nas
  listagens; e `LotusPresentationMode` nao e importado/chamado pelo Lotus.

## Pipeline semantico de cartas

Fluxo desejado para qualquer decisao de utilidade no core de decks:

1. Preferir dados persistidos e versionados: `card_function_tags`,
   `card_semantic_tags_v2`, `card_role_scores`, Commander Reference/meta e
   rejection penalties.
2. Usar fallback por `oracle_text`, `type_line`, `mana_cost`, `cmc`, legalidade,
   identidade de cor, bracket e budget quando o dado persistido nao existir ou
   estiver abaixo do limiar de confianca.
3. Manter excecoes por nome somente como policy versionada ou seed/corpus
   declarado, nunca como lista inline espalhada por classificadores, gates e
   rotas.

Estado atual revalidado em 2026-06-21 05:30 UTC no checkout `7a9255cd`: deck
analysis, optimize context, additionsData, validator, role delta e quality gate
threadam `functional_tags` e `semantic_tags_v2` no caminho principal. Weakness
analysis e recommendations continuam fora de um service unico, mas carregam
snapshot/tags semanticas e usam `resolveCardFunctionalRoles` para contadores
internos; seus fallbacks buscam candidatos por tags/semantica/legalidade/
identidade em vez de listas fixas de staples. Candidate quality tem uso parcial
de `card_function_tags`, mas parte da propria foundation ainda nasce de
heuristicas por nome e de listas de escopo high-power/premium. O mock de
`/ai/optimize` sem `deckOptimizer` ainda retorna staples por nome, mas marcado
como `is_mock=true`. Os prompts runtime carregados por `otimizacao.dart` ainda
contem exemplos fixos de cartas; idealmente esses exemplos devem ser gerados por
policy/dados versionados, nao mantidos como texto solto. O delta app revisado em
2026-06-21 nao reabriu nome hardcoded nao-basic, mas mostrou fallback local de
basic lands em apply mutation; basic land e excecao intencional, porem a fonte
deve convergir para o server/helper compartilhado.
- **P2 — Fallback de semantic v2 baixa confianca**: revalidado e coberto em
  `origin/master@c3531df7`. Tags semantic v2 abaixo de 0.65 sao ignoradas e a
  classificacao cai para heuristica por `oracle_text`/`type_line`.
- **P2 — Fillers de optimize/complete com bracket state**: resolvido em
  `origin/master@1aa4da71`. Os loaders de fillers passam a aplicar policy de
  bracket com `currentDeckCards`/`state.virtualDeck`, e o fallback sem bracket
  fica restrito a `bracket == null`. `optimize_runtime_support_test` guarda
  contra regressao para `currentDeckCards: const []` e complete sem estado
  virtual.
- **P3 — Diagnostics de bracket em sucesso parcial do optimize**: resolvido em
  `origin/master@4913a733`. Quando sugestões sao filtradas por bracket mas ainda
  restam swaps validos, a resposta pode incluir
  `optimize_diagnostics.bracket_policy` com contagem/lista sanitizada e mantém
  `warnings.blocked_by_bracket` por compatibilidade.
- **P1/P2 — Funcoes publicas sem chamador runtime confirmado**: revalidado em
  2026-06-21 07:14 UTC no checkout local `6410d456`. Desde a rodada focada
  anterior (`6244d33b`), somente docs Hermes mudaram no recorte `app/lib`,
  `app/test`, `app/integration_test`, `server/lib`, `server/routes`,
  `server/bin`, `server/test` e `server/doc/API_CONTRACTS_AND_DATA_MAP.md`;
  nao surgiu novo achado confiavel. A claim ampla de `sync_cards_utils.dart`
  test-only segue stale: o CLI operacional importa o utilitario e chama
  `parseSinceDays`, `getNewSetCodesSinceFromData` e `extractSetCardSyncRow`;
  restam P3 test-only `extractCardRow`, `extractSetCardRow`,
  `extractOracleIds` e `extractLegalities`. `swap_integrity` continua com
  validacao app e bloqueio de deck stale antes do apply por IDs; o achado vivo
  e mais estreito: `server/lib/ai/optimize_swap_integrity.dart` ainda exporta
  `verifySwapIntegrity` sem chamador backend. Permanecem sem chamador confirmado
  `buildOptimizeResponse`, o top-level `respondWithOptimizeTelemetry`,
  `getRequestTrace`, `ApiClient.loadTokenFromDisk`,
  `BinderProvider.applyFilters`, `CommunityProvider.clearFilters`,
  `DeckProvider.clearAllCache`, APIs manuais de `PerformanceService`,
  `EndpointCache.clearExpired`, conveniencias EDHREC, read-side de
  `AiLogService`, alguns metodos de `ArchetypeCountersService`,
  `PushNotificationService.sendToMultipleTokens`,
  `buildLoreholdReferenceCardStatsFromProfile`,
  `summarizeAggressiveOptimizeUtilitySamples`, `normalize_commander` na copia
  Hermes docs e helpers script-level `classify_loss_v2` /
  `compute_loss_tags_from_replays`. Funcoes historicas
  `MLKnowledgeService.recordFeedback`, `hasSuspiciousNonLandCmc`,
  `normalizedCommanderReferenceCandidate`, `extractMtgTop8FormatCodeFromSourceUrl`
  e `buildCandidateQualitySamplePoolSql` nao foram reabertas; os tres ultimos
  nem aparecem mais no checkout atual.
- **P2/P3 — Tabelas PostgreSQL persistidas sem consumidor claro**: revalidado
  novamente em 2026-06-21 15:00 UTC no checkout `4f538e41`. Desde a rodada
  focada anterior (`956f630e`), nao houve delta de produto no recorte
  `app/lib`, `server/lib`, `server/routes`, `server/bin`, `server/test`,
  `server/database_setup.sql` ou `server/doc/API_CONTRACTS_AND_DATA_MAP.md`;
  somente docs Hermes mudaram. `deck_matchups` e `deck_weakness_reports` seguem
  fora da claim write-only: ambas têm `INSERT` e `SELECT` runtime nas próprias
  rotas de matchup/weakness-analysis. `ml_prompt_feedback` tem writer runtime em
  `/ai/optimize`, schema em `database_setup.sql`/`verify_schema.dart` e contador
  em `/ai/ml-status`; o risco restante é consumir seu payload para seleção/score
  de prompt, não coletá-lo. `commander_reference_decks` e
  `commander_reference_deck_cards` continuam raw corpus P3 sem `SELECT/JOIN`
  direto confirmado, enquanto o produto lê o agregado
  `commander_reference_deck_analysis`. `deck_learning_events`,
  `commander_card_usage`, `commander_card_synergy`,
  `commander_learning_snapshot` e `commander_learned_decks` possuem
  leitores/escritores ou consumidores operacionais confirmados e não entraram
  como achados.
- Plano documentado em `docs/hermes-analysis/PLANO_CORRECAO.md`.

## Observabilidade

- Sentry backend: VALIDADO com ingestao real (event_id confirmado)
- Sentry mobile: PENDENTE (SENTRY_MOBILE_TOOLCHAIN_BLOCKED=1)
- x-request-id: Backend gera e propaga, correlacao mobile pendente
- Sentry DSN e config em server/.env.example e app/

## Navegacao e Layout (auditado 2026-05-25)

### GoRouter
- ShellRoute com MainScaffold (5 tabs bottom nav) envolvendo 10+ rotas
- Telas sem bottom nav: Splash, Login, Register, LifeCounter, Onboarding
- `/messages/:id` e `/notifications` ficam dentro do shell (sem tab propria)

### Bottom Navigation (5 tabs)
| Indice | Rotulo | Rotas cobertas |
|--------|--------|----------------|
| 0 | Inicio | /home |
| 1 | Decks | /decks, /decks/generate, /decks/import, /decks/:id + search/scan |
| 2 | Colecao | /collection (4 tabs internas), /market, /trades |
| 3 | Comunidade | /community, search-users, user/:userId |
| 4 | Perfil | /profile |

### TabBars aninhados
- CollectionScreen: 4 tabs (Fichario, Market, Trades, Colecoes)
- TradeInboxTabContent: 3 sub-tabs (Recebidas, Enviadas, Finalizadas)
- BinderTabContent: 2 sub-tabs (Tenho, Quero)
- CommunityScreen: 4 tabs (Explorar, Seguindo, Usuarios, Cotacoes) + sub-tabs
- DeckDetailsScreen: 3 tabs (Visao Geral, Cartas, Analise)

### Consistencia do tema
- Zero `Color(0x...)` hardcoded nas telas do fluxo core permanece como objetivo,
  mas `life_counter_screen.dart` ainda tem varias cores hardcoded no Flutter nativo.
- O Lotus WebView usa `lotus_visual_skin.dart` como camada visual propria, fora do
  tema Flutter, e precisa de prova viva de overlays para ser considerado PASS.
- AppBar segue tema Onda 6 — community_screen w800 corrigido para w700 (commit 91885194)
- TabBars usam brass400 como indicador — deck_details_screen usa o tema direto; collection/binder/trade_inbox/community fazem override redundante com valores identicos ao tema
- MainScaffold NavigationBar usa NavigationBarThemeData com indicatorColor brass500 alpha 0.15
