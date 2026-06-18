# Hermes Analysis: Technical Map

> Status atual: mapa tecnico app/backend.
> Util para orientacao de produto/codigo, mas nao substitui o contrato Hermes
> E2E nem reports frescos.

> Mapa tecnico detalhado do ManaLoom. Atualizado em 2026-06-17 11:00 UTC.

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
│   │   │   ├── optimize/         # Otimizacao de decks (LARGO ~3497 linhas)
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
| server/routes/ai/optimize/index.dart | 3497 | P1 — gargalo de manutencao maior que o digest anterior |
| server/lib/ai/optimize_runtime_support.dart | 4197 | P1 — logica densa, precisa de quebra modular |
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

## Achados do audit de estrutura (atualizado 2026-06-18)

- **P0 — Falso-positivo em massa no auditor estrutural**: **RESOLVIDO em 2026-05-28.** `STRUCTURE_AUDIT.md` reportava 178 imports "quebrados" por resolver imports relativos a partir do root errado. `docs/hermes-analysis/scripts/structure_auditor.py` agora usa `MTGIA_REPO_ROOT`/`Path.cwd()`, resolve relativos a partir do arquivo Dart origem e reconhece imports locais `package:server/...`, `package:manaloom/...` e alias historico `package:ai/...`. Nova execucao: `Imports quebrados: 0`.
- **P1/P2 — Imports quebrados e ciclos locais fora do recorte do auditor base**:
  **REVALIDADO/ABERTO em 2026-06-17 11:00 UTC no checkout `a96bffd6`.** O
  auditor base cobre apenas `server/lib` e `server/routes` e reportou
  `Imports quebrados: 0`. Desde a rodada anterior deste foco (`ea37f3cf..HEAD`),
  nao houve delta de produto em `app/lib`, `server/lib`, `server/routes`,
  `server/bin`, testes app/server, database setup, API contract, contexto de
  produto ou manual. A triagem focada de 409 arquivos Dart em `app/lib`, `server/lib`,
  `server/routes` e `server/bin` encontrou 1082 diretivas locais resolvidas,
  0 imports/exports/parts locais quebrados e 2 SCCs. `dart analyze` focado para
  `optimize_runtime_support.dart`/`optimize_filler_loader_support.dart` e
  `flutter analyze --no-pub --no-fatal-infos` focado para os dois arquivos
  `life_counter_*_engine.dart` retornaram `No issues found!`. Claims anteriores
  contra `deck_analysis_tab.dart`, `life_counter_screen.dart`,
  `server/bin/local_test_server.dart`, `server/routes/ai/commander-learning` e o
  ciclo `CommunityDeckDetailScreen`/`UserProfileScreen` seguem stale. Permanecem
  abertos os mesmos 2 SCCs atuais: `life_counter_tabletop_engine.dart` ↔
  `life_counter_turn_tracker_engine.dart`, e `optimize_runtime_support.dart` ↔
  `optimize_filler_loader_support.dart`.
- **P1 — Gargalos do domínio de optimize permanecem acima do aceitável**: `server/lib/ai/optimize_runtime_support.dart` (4197 linhas) e `server/routes/ai/optimize/index.dart` (3497 linhas) seguem concentrando regra de negócio. A duplicacao direta anterior entre rota e support para helpers como `matchesFunctionalNeed` e `scoreOptimizeReplacementCandidate` foi revalidada em 2026-05-28 como wrappers finos que delegam para `optimize_support`, mas ainda ha drift similar em `resolveOptimizeArchetype` entre `optimize_runtime_support.dart` e `deck_state_analysis.dart`.
- **P1/P2 — Coerencia app-facing `app/lib` ↔ `server/routes` ↔ `server/lib`**:
  revalidado novamente em 2026-06-17 23:00 UTC no checkout local `831c6ac8`.
  O auditor textual executou com sucesso (`205` arquivos backend, `115`
  problemas textuais, `0` imports quebrados), mas nao cobre `app/lib`; a
  evidencia veio de `rg`, `nl -ba`, leitura direta e `dart analyze` focado nas
  tres rotas/backend files relacionados (`No issues found`). Desde a rodada
  anterior do mesmo foco (`5ce943fa..HEAD`), o delta de produto/testes/API
  contract/manual no recorte app/backend e nulo. Os
  achados antigos de ownership em `POST /ai/optimize`, `POST /ai/archetypes` e
  polling de jobs async seguem stale: optimize exige usuario, passa `userId`
  para o loader owner-scoped, jobs rejeitam owner vazio/diferente e archetypes
  busca deck por `id + user_id`. Permanecem abertos os mesmos tres gaps de
  coerencia app/server: `deck_rebuild_created` e emitido/testado no app, mas
  rejeitado pela allow-list de `/users/me/activation-events`; o endpoint
  app-facing `GET /ai/commander-learning` existe, e consumido pela tela de
  geracao e usa `commander_learned_decks`, mas nao esta documentado em
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md`; e a consulta automatica de learned
  decks herda `aiPlanLimitMiddleware` + `aiRateLimit` apesar de ser leitura
  local de PostgreSQL, sem chamada LLM/externa no handler.
- **P1/P2 — Helpers duplicados com risco de drift**: revalidado novamente em 2026-06-17 19:00 UTC no checkout local `e47adcd5`. O auditor textual executou com sucesso (`205` arquivos backend, `115` problemas textuais, `0` imports quebrados), mas a lista de duplicacao segue ruidosa por regex e nao foi usada como evidencia direta; a mutacao mecanica do bloco gerado foi removida. Desde a rodada anterior de duplicacao (`5ce943fa..HEAD`), nao houve delta de codigo de produto no recorte auditado; permanecem os clusters ja abertos em IA (`DeckArchetypeAnalyzer`/`DeckArchetypeAnalyzerCore`, `assessDeckOptimizationState`/`assessDeckOptimizationStateCore`, `resolveOptimizeArchetype` e fallbacks `_looksLikeComboPiece`, `_looksLikeEngine`, `_looksLikePayoff`, `_looksLikeEnabler`, `_looksLikeWincon`), trust SQL/serializer em trades/marketplace, request/log social repetido, politicas divergentes de `condition` e helpers de CMC/tipo. Novo achado P2 no recorte de duplicacao: `server/lib/sync_cards_utils.dart` contem helpers extraidos/testados, mas `server/bin/sync_cards.dart` ainda usa copias privadas/inline para janela incremental, parsing de set e legalidades. O achado P2 script-level dos exporters Hermes de learned deck segue aberto; `server/bin/export_hermes_learned_deck.py` e `docs/hermes-analysis/manaloom-knowledge/scripts/export_hermes_learned_deck.py` continuam bifurcados em completude, contagem, schema fallback e metadata multi-role. A claim antiga de `_isBasicLandName` duplicado segue stale; `buildOptimizeCacheKey`/`buildOptimizeDeckSignature` e wrappers de `server/routes/ai/optimize/index.dart` continuam apenas delegando para support.
- **P1 — Payoff functional tag fragil por precedencia**: resolvido em
  `origin/master@1463732a`. `_looksLikePayoff` agora usa branches explicitos e
  regex para custo reduzido; testes cobrem `Impact Tremors` como payoff e
  `The One Ring` como draw/protection sem payoff.
- **P1/P2 — Pipeline semantico de cartas parcialmente saneado**: revalidado em
  2026-06-17 05:30 UTC no checkout local `6d25e447` (sem delta de produto desde
  `e458c074`). Deck analysis,
  `loadOptimizeDeckContext`, addition data do quality gate, validator e quality
  gate ja carregam ou preservam `functional_tags`, `semantic_tags_v2` e
  multi-role quando essas fontes chegam ao fluxo. A ordem principal e
  `functional_tags -> semantic_tags_v2 -> heuristica`. Os riscos restantes sao
  mais estreitos: `inferFunctionalRole` ainda reduz roles para o contrato legado
  de optimize, `removals_detailed.functionalRole` nao recebe as tags ja
  presentes em `allCardData`, `findSynergyReplacements` monta o pool inicial sem
  tags/role scores, prompts runtime ainda contem exemplos nomeados,
  `/ai/weakness-analysis` usa o adapter em modo heuristico porque a query nao
  carrega `card_function_tags`/`semantic_tags_v2`, e
  `/decks/:id/recommendations` segue fora da camada semantica compartilhada.
  Rebuild guiado ainda pontua ramp/utility lands por nomes especificos, e a rota
  `decks/:id/analysis` mantem lista local de basic lands apesar do helper
  compartilhado.
- **P1 — Listas de nomes em runtime de cartas**: revalidado em 2026-06-17
  05:30 UTC no checkout local `6d25e447`. A claim antiga de ausencia de policy
  versionada esta stale: `commander_fallback_policy.dart` existe, expoe versao e
  centraliza parte relevante dos fallbacks. Continuam como risco as decisoes por
  nome em fallbacks de `functional_card_tags.dart`,
  `optimization_functional_roles.dart`, `candidate_quality_data_support.dart` e
  seu job foundation, `optimize_runtime_support.dart`, `prompt.md`,
  `prompt_complete.md`, `deck_advanced_analysis.dart`,
  `meta_deck_commander_shell_support.dart`, rebuild guiado,
  `/decks/:id/recommendations` e `/ai/weakness-analysis`. Permanecem permitidos
  exemplos de UI/import,
  docs/corpus/artifacts/test fixtures, aliases localizados, sugestoes de busca
  do life counter, mock dev de optimize sem API key, seeds/profiles de Commander
  Reference, `commander_fallback_policy.dart` como policy versionada/testada e a
  excecao intencional de `edh_bracket_policy.dart` para regras externas de
  bracket/Game Changer. Basic lands sao excecao de regra de deckbuilding quando
  passam por `basic_land_utils.dart`; listas inline fora dele seguem gap estreito.

- **P1/P2 — Classes app sem uso de runtime confirmado**: revalidado novamente em
  2026-06-18 03:00 UTC no checkout local `94f73400`. O auditor textual executou
  com sucesso (`205` arquivos backend, `196` classes, `0` imports quebrados),
  mas continua limitado a `server/lib` e `server/routes`; a evidencia app veio
  de `rg`, leitura direta e triagem do delta. Desde a rodada anterior de
  classes (`2edcc757..HEAD`), nao houve delta de codigo de produto, testes,
  contrato API, contexto de produto ou manual no recorte app/backend.
  `LifeCounterScreen` continua legado/test-only enquanto a rota ativa usa
  `LotusLifeCounterScreen`; `DeckCard` e `DeckProgressChip` continuam sem uso
  runtime confirmado nas listagens; e `LotusPresentationMode` nao e
  importado/chamado pelo Lotus. Nao surgiram novos achados confiaveis nesta
  rotacao.

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

Estado atual revalidado em 2026-06-18 05:30 UTC no checkout local `abfe1497`
(sem delta de produto desde `6d25e447`/`e458c074` no recorte `server/lib`,
`server/routes` e `app/lib`): deck analysis,
`loadOptimizeDeckContext`, addition data do quality gate,
validator e os dados de entrada do quality gate carregam ou preservam `card_function_tags` e
`semantic_tags_v2`. O adapter compartilhado
`resolveCardFunctionalRoles` aplica precedencia
`functional_tags -> semantic_tags_v2 -> heuristica`, e os paths principais ja
preservam multi-role onde o contrato usa `optimizationFunctionalRolesForCard`.

Gaps restantes: classificadores heuristics ainda tem excecoes por nome como
fallback; `candidate_quality_data_support.dart` herda parte dessas excecoes e
ainda aplica bonuses/escopo por listas de `commander_fallback_policy.dart`; o
job `candidate_quality_data_foundation.dart` gera tags/scores a partir desses
helpers heuristicos; `findSynergyReplacements` monta o pool inicial sem carregar
`card_function_tags`, `semantic_tags_v2` ou role scores; `inferFunctionalRole`
mantem colapso legado de role multi-tag para uma role primaria usada por partes
do optimize; `removals_detailed.functionalRole` chama esse helper sem fornecer
as fontes persistidas ja presentes em `allCardData`; `prompt.md` e
`prompt_complete.md` sao system prompts de runtime e ainda contem exemplos de
cartas nomeadas; `/ai/weakness-analysis`
nao carrega `card_function_tags`, `semantic_tags_v2` nem `card_role_scores` e
ainda devolve sugestoes por nomes fixos; `deck_advanced_analysis.dart`, chamado
por weakness-analysis, tambem opera sem fontes persistidas; `/decks/:id/recommendations`
usa buckets por texto, recomenda `Command Tower` diretamente quando faltam
terrenos e usa raridade como proxy de impacto. Gap estreito novo da revalidacao:
`_functionalRolesForGate` no quality gate usa `semantic_tags_v2` isolado quando
ele existe e so le `functional_tags` persistidos quando semantic v2 esta vazio,
o que pode mascarar multi-tags persistidas em roles criticos. A camada de meta Commander
tambem deriva `strategy_archetype` por listas de nomes em
`meta_deck_commander_shell_support.dart`; tratar como policy/corpus versionado
ou substituir por tags/scores semanticos antes de usar esse dado como sinal de
produto. `rebuild_guided_service.dart` tambem classifica ramp por
`signet`/`sol ring`/`talisman` e prioriza/penaliza utility lands por nome; mover
isso para roles/tags ou policy versionada. Basic lands sao excecao legitima de
regra de deckbuilding, mas `server/routes/decks/[id]/analysis/index.dart` ainda
tem lista inline e deve usar `basic_land_utils.dart`. `edh_bracket_policy.dart`
segue excecao intencional por regra externa e Game Changer, nao um modelo geral
de utilidade de carta.
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
- **P1/P2 — Funcoes publicas sem chamador runtime confirmado**: revalidado
  novamente em 2026-06-17 07:00 UTC no checkout local `caeade55`. Desde a
  rodada focada anterior (`ae65f536..HEAD`), nao houve delta de produto em
  `app/lib`, `server/lib`, `server/routes`, `server/bin`, testes app/server,
  database setup, API contract, contexto de produto ou manual. O auditor
  textual executou com sucesso (`205` arquivos backend, `115` problemas
  textuais, `0` imports quebrados), mas continua sem grafo de chamadas; a
  evidencia veio de buscas exatas por simbolo. Permanecem abertos os achados de
  maior impacto: `server/lib/sync_cards_utils.dart` test-only neste branch
  enquanto `server/bin/sync_cards.dart` mantem helpers privados/inline;
  `swap_integrity` e emitido, mas `verifySwapIntegrity` nao e chamado no apply
  app/backend; e a extracao de `optimize_response_support.dart` continua
  parcial (`buildOptimizeResponse` e o top-level
  `respondWithOptimizeTelemetry` fora do fluxo real). Seguem tambem wrappers app
  sem chamador (`BinderProvider.applyFilters`,
  `CommunityProvider.clearFilters`, `DeckProvider.clearAllCache`) e
  conveniencias sem wiring em request trace, `ApiClient.loadTokenFromDisk`,
  performance manual/debug, EDHREC/cache, metodos parciais de archetype
  counters, push, ML feedback, read-side de `AiLogService`, wrapper Lorehold de
  Commander Reference e sample helper de aggressive optimize. `isLikelyLandCard`
  continua vivo via `safeCmcForOptimization`; `MLKnowledgeService`,
  `AiLogService`, `EndpointCache`, push e archetype counters tem caminhos vivos
  parciais, so alguns metodos publicos seguem sem consumidor. O achado menor de
  `normalize_commander` foi estreitado: a copia de
  `docs/hermes-analysis/manaloom-knowledge/scripts/export_hermes_learned_deck.py`
  continua sem chamada, mas `server/bin/export_hermes_learned_deck.py` chama sua
  propria versao e nao deve ser citado como funcao morta.
- **P2/P3 — Tabelas PostgreSQL persistidas sem consumidor claro**: revalidado
  em 2026-06-17 15:00 UTC no checkout local `c33e15ba`. Desde a ultima rodada
  focada (`41e681a0..HEAD`), nao houve delta de codigo de produto, setup DB,
  testes, API contract, contexto, manual ou scripts Hermes no recorte usado para
  classificar tabelas. Nao houve novo achado P1/P2 app-facing. As claims antigas
  contra `deck_matchups` e `deck_weakness_reports` continuam stale: ambas tem
  leitura runtime e campos retornados no payload das rotas experimentais
  (`stored_matchup` em `/ai/simulate-matchup` e `history` em
  `/ai/weakness-analysis`). `deck_learning_events`, `commander_card_usage`,
  `commander_learned_decks` e `card_battle_rules` seguem como controles
  positivos por terem writers/readers em rotas, jobs ou scripts operacionais.
  Permanecem como riscos P3: `commander_reference_decks` e
  `commander_reference_deck_cards` persistem raw corpus sem `SELECT/JOIN`
  direto confirmado, enquanto o produto le o agregado
  `commander_reference_deck_analysis`; e `ml_prompt_feedback` tem insert helper
  sem chamador, leitura apenas `COUNT(*)` em `/ai/ml-status` e nenhum DDL local
  encontrado neste checkout. `server/doc/API_CONTRACTS_AND_DATA_MAP.md` e
  `server/manual-de-instrucao.md` ainda contem texto stale sobre
  `deck_matchups`/`deck_weakness_reports`, mas ficaram fora do escopo de escrita
  desta rotina.
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
