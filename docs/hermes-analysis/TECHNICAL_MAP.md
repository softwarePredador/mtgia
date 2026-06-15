# Hermes Analysis: Technical Map

> Status atual: mapa tecnico app/backend.
> Util para orientacao de produto/codigo, mas nao substitui o contrato Hermes
> E2E nem reports frescos.

> Mapa tecnico detalhado do ManaLoom. Atualizado em 2026-06-07 19:00 UTC.

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
| Commander Ref | /ai/commander-reference | experimental | commander_reference_atraxa |
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
  **VERMELHO** por `server/bin/local_test_server.dart:3` importar
  `../.dart_frog/server.dart`, artefato ausente em clone limpo nesta branch.
  A resolucao historica em `origin/master@a830f9f3` nao esta refletida aqui.
- `flutter analyze --no-pub --no-fatal-infos` local em 2026-05-30: **BLOQUEADO/NAO CONCLUSIVO** porque `app/.dart_tool/package_config.json` nao existe neste checkout; o analyzer reportou pacotes ausentes antes de validar imports locais
- `flutter test`: VERDE historico; nao reexecutado integralmente nesta higiene semanal
- Corpus estavel de resolucao Commander: 19/19 passed
- Quality gate: `scripts/quality_gate.sh` (quick/full/resolution)
- Testes de integracao: opt-in via `RUN_INTEGRATION_TESTS=1`

## Achados do audit de estrutura (atualizado 2026-06-07)

- **P0 — Falso-positivo em massa no auditor estrutural**: **RESOLVIDO em 2026-05-28.** `STRUCTURE_AUDIT.md` reportava 178 imports "quebrados" por resolver imports relativos a partir do root errado. `docs/hermes-analysis/scripts/structure_auditor.py` agora usa `MTGIA_REPO_ROOT`/`Path.cwd()`, resolve relativos a partir do arquivo Dart origem e reconhece imports locais `package:server/...`, `package:manaloom/...` e alias historico `package:ai/...`. Nova execucao: `Imports quebrados: 0`.
- **P1/P2 — Imports quebrados e ciclo local fora do recorte do auditor base**:
  **REVALIDADO/ABERTO em 2026-06-07 11:00 UTC no checkout `2061f291`.** O
  auditor base cobre apenas `server/lib` e `server/routes` e reportou
  `Imports quebrados: 0`. O import historico de
  `server/routes/ai/commander-learning/index.dart:4` para
  `server/lib/ai/commander_learned_deck_support.dart` nao esta mais quebrado
  neste checkout porque o arquivo alvo existe. A triagem focada em 426 arquivos
  Dart de `app/lib`, `server/lib`, `server/routes` e `server/bin` encontrou
  somente 3 imports locais quebrados: `app/lib/features/decks/widgets/deck_analysis_tab.dart:5`
  resolvendo para `app/core/utils/mana_helper.dart`,
  `app/lib/features/home/life_counter_screen.dart:7` resolvendo para
  `app/core/theme/app_theme.dart`, e `server/bin/local_test_server.dart:3`
  resolvendo para `server/.dart_frog/server.dart`. `dart analyze
  bin/local_test_server.dart` confirma o erro backend. `flutter analyze
  --no-pub` focado no app foi nao conclusivo porque
  `app/.dart_tool/package_config.json` nao existe, mas a saida incluiu os dois
  `uri_does_not_exist` locais do app. A mesma varredura achou 1 SCC de 2
  arquivos entre `CommunityDeckDetailScreen` e `UserProfileScreen`, e nenhum
  ciclo local backend.
- **P1 — Gargalos do domínio de optimize permanecem acima do aceitável**:
  revalidado em 2026-06-11 no `master@321b0f24`. Os tamanhos atuais cairam para
  `server/lib/ai/optimize_runtime_support.dart` (~2386 linhas) e
  `server/routes/ai/optimize/index.dart` (~2498 linhas), ainda acima do ideal.
  O drift de `resolveOptimizeArchetype` foi fechado com
  `server/lib/ai/optimize_archetype_support.dart`; continuam candidatos a split
  os blocos de seleção de candidatos, fallback/recovery estrutural e
  orquestração remanescente da rota.
- **P1 — Coerencia app-facing de IA/deck revalidada no checkout local**:
  status 2026-06-11 parcial. O achado antigo de `POST /ai/optimize` sem
  owner-scope foi resolvido: `loadOptimizeDeckContext` exige `userId`,
  consulta `decks` por `id + user_id`, e o polling de jobs bloqueia jobs sem
  owner ou de outro usuario. Manter a auditoria de `/ai/archetypes` e demais
  endpoints experimentais separada quando o produto voltar a tocá-los. O
  caminho principal de deck analysis/optimize já carrega `functional_tags` e
  `semantic_tags_v2`; o risco restante fica em endpoints legacy/experimentais e
  activation telemetry, não no fluxo principal de optimize.
- **P1/P2 — Helpers duplicados com risco de drift**: revalidado novamente em
  2026-06-11. `resolveOptimizeArchetype` foi removido da lista de riscos por
  delegar para `optimize_archetype_support.dart`. Os roles estratégicos
  `wincon/combo_piece/engine/payoff/enabler` também deixaram de ter cópias
  privadas em `functional_card_tags.dart` e agora consultam
  `resolveCardFunctionalRoles`. Basic/snow basic lands agora usam
  `server/lib/basic_land_utils.dart` como fonte canônica; o wrapper público em
  `optimize_runtime_support.dart` e o alias `basicLandNames` em
  `commander_reference_deck_corpus_support.dart` existem apenas para preservar
  APIs internas. Ainda persistem duplicações relevantes em utilitarios de
  request/log e trust SQL/serializer em trades/marketplace.
- **P1 — Payoff functional tag fragil por precedencia**: resolvido em
  `origin/master@1463732a`. `_looksLikePayoff` agora usa branches explicitos e
  regex para custo reduzido; testes cobrem `Impact Tremors` como payoff e
  `The One Ring` como draw/protection sem payoff.
- **P1/P2 — Pipeline semantico de cartas parcialmente saneado**: revalidado em
  2026-06-11. Deck analysis e optimize agora carregam `functional_tags` +
  `semantic_tags_v2`, e o validator/quality gate usam precedencia
  `functional_tags` persistidos -> `semantic_tags_v2` -> heuristica. Em
  2026-06-12, `/decks/:id/recommendations` e `/ai/weakness-analysis` também
  passaram a carregar `card_function_tags`/`card_semantic_tags_v2` quando as
  tabelas existem e usam `resolveCardFunctionalRoles` para os contadores internos
  de ramp/draw/removal/wipes/protection, mantendo fallback textual. No mesmo
  ciclo, o fallback de `/decks/:id/recommendations` deixou de recomendar
  `Command Tower` como literal fixo, deixou de usar raridade como proxy de
  impacto e passou a buscar sugestões por tags/semântica/legalidade/identidade
  de cor via PostgreSQL. O risco restante ficou concentrado em heurísticas
  secundárias não estratégicas que ainda precisam contrato interno explícito
  antes de serem tratadas como produto principal.
- **P1 — Listas de nomes em runtime de cartas**: a auditoria de 2026-06-07 classificou como permitidos exemplos de UI/import, comentarios de contrato, aliases localizados, docs/corpus/artifacts/test fixtures e sugestoes de busca do life counter; como excecao intencional, a policy externa de EDH/bracket; e como seed allowed-with-caution, os profiles/seeds de Commander Reference. Permanecem como risco as listas inline que decidem tags, score, fillers, rebuild, mock runtime e prompt runtime por nomes especificos (`functional_card_tags.dart`, `candidate_quality_data_support.dart`, `optimize_runtime_support.dart`, `rebuild_guided_service.dart`, `/ai/optimize` quando `deckOptimizer == null`, `prompt.md` e `prompt_complete.md`). Em 2026-06-12, `/ai/weakness-analysis` deixou de retornar listas fixas de staples para fraquezas principais e `/decks/:id/recommendations` deixou de usar `Command Tower` literal e raridade como proxy; ambos passaram a buscar sugestões no banco por tags/semântica/legalidade, com fallback genérico sem nomes. `edh_bracket_policy.dart` e excecao intencional para regras externas de bracket/Game Changer, mas deve manter fonte/versionamento/teste dedicado.

- **P1/P2 — Classes app sem uso de runtime confirmado**: revalidado novamente em
  2026-06-07 03:00 UTC no checkout local `ee74c6a9`. `LifeCounterScreen` segue
  legado/test-only enquanto a rota ativa usa `LotusLifeCounterScreen`;
  `DeckCard` e `DeckProgressChip` nao tem uso runtime confirmado nas listagens;
  `LotusPresentationMode` nao e importado/chamado pelo Lotus; e
  `AuthVisualShell`, `AuthBrandHeader` e `AuthFormSurface` aparecem somente no
  proprio `auth_visual_shell.dart`. Controles positivos descartaram
  `LotusLifeCounterScreen` e `DeckProgressIndicator`. Uma varredura textual
  ampla de classes publicas foi usada apenas como triagem, mas DTOs/helpers
  vivos dentro do proprio arquivo nao foram reportados como codigo morto sem
  evidencia adicional.

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

Estado atual revalidado em 2026-06-07 05:30 UTC no checkout `84a97d75`: deck
analysis segue mais proximo do fluxo desejado porque usa `card_function_tags` e
`semantic_tags_v2`; o contexto de optimize, `additionsData`, validator e role
delta ainda nao threadam `card_function_tags` persistidos e reduzem v2 a um
role unico. Candidate quality tem uso parcial de `card_function_tags`, mas
tambem usa normalizacao propria, bonus por nome e listas de escopo high-power.
Weakness analysis e recommendations continuam fora de um service compartilhado,
mas carregam dados persistidos e usam `resolveCardFunctionalRoles` para
contadores internos. Em 2026-06-12, ambos os fallbacks deixaram de depender de
listas fixas de staples; recommendations também deixou de recomendar
`Command Tower` diretamente e removeu raridade como proxy de impacto. O mock de
`/ai/optimize` sem `deckOptimizer` ainda retorna staples por nome. Os prompts
runtime carregados por `otimizacao.dart` tambem contem exemplos fixos de cartas;
idealmente esses exemplos devem ser gerados por policy/dados versionados, nao
mantidos como texto solto.
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
  2026-06-07 07:00 UTC no checkout local `82bb454e` e atualizado em
  2026-06-11. `server/lib/sync_cards_utils.dart` deixou de ser test-only:
  `server/bin/sync_cards.dart` agora importa o utilitário e usa
  `parseSinceDays`, `getNewSetCodesSinceFromData` e `extractSetCardSyncRow`.
  Ainda seguem sem chamador runtime confirmado
  `getRequestTrace`/`tryGetRequestId`,
  `normalizedCommanderReferenceCandidate`,
  `buildLoreholdReferenceCardStatsFromProfile`,
  `extractMtgTop8FormatCodeFromSourceUrl`,
  `buildCandidateQualitySamplePoolSql`,
  `summarizeAggressiveOptimizeUtilitySamples`. `MLKnowledgeService.recordFeedback`
  deixou de ser achado nessa categoria em 2026-06-11 porque `/ai/optimize`
  passou a chamar `optimize_feedback.recordOptimizeMlFeedback(...)` dentro de
  `respondWithOptimizeTelemetry`. Novo achado app-side:
  `ApiClient.loadTokenFromDisk()` diz ser chamado 1x no boot, mas `rg`
  encontrou somente a definicao; o boot real le `auth_token` via
  `AuthProvider.initialize` e chama `ApiClient.setToken`. A API manual/custom
  metrics/debug de `PerformanceService` e conveniencias EDHREC/cache
  (`getTopByCategory`, `calculateFitScore`, `cleanupCache`, `isHighSynergy`,
  `EndpointCache.clearExpired`) seguem sem chamador confirmado. A parte
  automatica do `PerformanceService` (`init`, observer de tela e `traceAsync`
  em smoke) foi separada como controle positivo, nao como codigo morto.
- **P2/P3 — Tabelas PostgreSQL persistidas sem consumidor claro**: o achado
  de 2026-06-07 foi superseded pela validação de 2026-06-15. `deck_matchups`
  e `deck_weakness_reports` têm leitura runtime nas próprias rotas de
  matchup/weakness-analysis; o risco atual é produto/retroalimentação baixa,
  não ausência total de consumidor. `ml_prompt_feedback` agora tem writer
  runtime em `/ai/optimize`, schema em `database_setup.sql`/`verify_schema.dart`
  e contador operacional em `/ai/ml-status`; o risco restante é consumir esse
  histórico para seleção de prompt, não coletá-lo. `commander_reference_decks` e
  `commander_reference_deck_cards` persistem raw corpus sem `SELECT/JOIN`
  runtime confirmado, enquanto o produto le o agregado
  `commander_reference_deck_analysis`. A varredura focada de DDL versus
  operacoes SQL encontrou 53 tabelas criadas no recorte de codigo e somente
  `commander_reference_decks`, `deck_matchups` e `deck_weakness_reports` com
  write sem `SELECT/JOIN`; `commander_reference_deck_cards` foi mantida como
  achado manual por ser raw corpus apagado/reinserido sem leitura de produto
  confirmada. Nenhum novo candidato foi confirmado; `commander_reference_deck_analysis`
  e as tabelas de candidate quality/jobs/cache/telemetry foram separadas como
  controles positivos por terem leitores runtime, writes e/ou runners dedicados
  confirmados. `deck_learning_events` e `commander_card_usage` aparecem somente
  em docs historicos neste checkout, nao em `server/database_setup.sql` nem no
  codigo Dart runtime.
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
