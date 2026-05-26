# Hermes Analysis: Technical Map

> Mapa tecnico detalhado do ManaLoom. Atualizado em 2026-05-26.

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
│   │   │   ├── optimize/         # Otimizacao de decks (LARGO ~2745 linhas)
│   │   │   ├── rebuild/          # Reconstrucao guiada
│   │   │   ├── explain/          # Explicacao de cartas
│   │   │   ├── archetypes/       # Opcoes de arquétipo
│   │   │   ├── simulate/         # Simulacao de partidas
│   │   │   ├── commander-reference/
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
│   │   └── ready/                # (deprecado em favor de /health/ready)
│   ├── lib/ai/                   # ~30 arquivos de logica de IA
│   │   ├── optimize_*.dart       # Modulos do otimizador (9 arquivos)
│   │   ├── candidate_quality_data_support.dart
│   │   ├── functional_card_tags.dart
│   │   ├── goldfish_simulator.dart
│   │   ├── optimization_validator.dart
│   │   ├── rebuild_guided_service.dart
│   │   ├── commander_reference_*.dart (6 arquivos)
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
| server/routes/ai/optimize/index.dart | 3495 | P1 — gargalo de manutencao maior que o digest anterior |
| server/lib/ai/optimize_runtime_support.dart | 4197 | P1 — logica densa, precisa de quebra modular |
| app/lib/features/home/life_counter_screen.dart | 6400 | P1 — tela/engine nativa grande; Lotus WebView tem skin separado |
| app/lib/features/home/lotus/lotus_visual_skin.dart | 1333 | P1 — CSS injetado no WebView, cresceu +423 linhas com overlays premium |
| app/lib/features/decks/screens/deck_details_screen.dart | 1705 | P1 — caindo, mas ainda grande |
| app/lib/features/community/screens/community_screen.dart | 1725 | P1 — 4 tabs + sub-tabs |
| app/lib/features/binder/screens/binder_screen.dart | 1628 | P1 — listas, editor, filtros |
| app/lib/features/decks/widgets/deck_analysis_tab.dart | 1632 | P1 — functional tags + graficos |
| app/lib/features/trades/screens/trade_detail_screen.dart | 1479 | P1 — timeline, chat, status, itens, trust |
| app/lib/features/decks/providers/deck_provider.dart | 1226 | P1/P2 — voltou a crescer; residual/orquestracao |
| server/manual-de-instrucao.md | ~17741 | N/A — documentacao |
| app/doc/APP_AUDIT_2026-04-29.md | ~2195 | N/A — auditoria |
| server/doc/API_CONTRACTS_AND_DATA_MAP.md | ~369 linhas / 100KB | N/A — contratos |

## Qualidade e validacao

- `flutter analyze --no-fatal-infos`: VERDE
- `flutter test`: VERDE (599 tests em 2026-05-26)
- `dart test`: VERDE (backend unitario)
- Corpus estavel de resolucao Commander: 19/19 passed
- Quality gate: `scripts/quality_gate.sh` (quick/full/resolution)
- Testes de integracao: opt-in via `RUN_INTEGRATION_TESTS=1`

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
