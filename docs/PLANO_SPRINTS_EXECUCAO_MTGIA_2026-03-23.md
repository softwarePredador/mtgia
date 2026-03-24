# Plano de Sprints de Execucao - MTGIA

> Ordem oficial recomendada de execucao.
> Este documento detalha a fila de sprints a partir do contexto atual, sem substituir a precedencia de `CONTEXTO_PRODUTO_ATUAL.md`.

## Objetivo

Organizar a execucao em sprints claras, na ordem correta, para:

- fechar o core de decks com confiabilidade de release
- depois elevar observabilidade e operacao
- so entao ampliar escala, assincro e superficies secundarias

## Regra de leitura

Antes de usar este plano:

1. ler `docs/CONTEXTO_PRODUTO_ATUAL.md`
2. ler `docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md`
3. usar este arquivo como ordem de execucao

## Ordem oficial de sprints

### Sprint 1 - Core de Otimizacao Blindado

Objetivo:

- levar o fluxo `generate -> analyze -> optimize -> apply -> validate` ao maior nivel possivel de confiabilidade

Escopo:

- `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/routes/ai/optimize/index.dart`
- `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/lib/ai/**`
- `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/routes/ai/rebuild/**`
- `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app/lib/features/decks/**`
- corpus, testes e smokes do fluxo core

Tasks:

1. modularizar `server/routes/ai/optimize/index.dart`
2. transformar o corpus estavel em gate recorrente de release
3. adicionar casos dirigidos para:
   - `optimized_directly`
   - `partner/background`
   - five-color
   - colorless
4. criar smoke do app para `deck details -> optimize -> apply -> validate`
5. endurecer contratos de erro, warning e sucesso da otimizacao
6. reduzir pontos gigantes no app ligados ao core:
   - `deck_details_screen.dart`
   - `deck_provider.dart`

Estado atual documentado em `2026-03-23`:

- `DONE`: task 1, no recorte atual de modularizacao necessario para tirar o miolo pesado da rota
- `DONE`: task 2, com gate recorrente em `scripts/quality_gate_resolution_corpus.sh`
- `DONE`: task 3
- `DONE`: tasks 4 e 5
- `IN_PROGRESS`: task 6

Atualizacao da rodada atual:

- task 1 avancou com extracao de:
  - role target profile
  - slot needs
  - deterministic slot fillers
  - meta/broad/emergency/identity-safe/preferred fillers
  - synergy replacements
  - replacement scoring
  - logging/persistencia de `optimization_analysis_logs`
- deck virtual helpers, addition entries, repair plan, analisador de arquétipo, detecção de tema e avaliação de estado do deck
- `index.dart` caiu para `2745` linhas sem quebra de contrato local de testes
- `optimize_state_support.dart` foi criado para absorver a camada de análise/estado do deck
- `optimize_complete_support.dart` foi criado para absorver seed do commander, complete async, rebalanceamento e fallback de preenchimento
- o assembly final do `complete` também saiu da rota para o suporte dedicado
- `optimize_request_support.dart` foi criado para absorver fetch do deck, parsing de cartas e análise inicial
- os builders deterministas principais de removals/swaps tambem sairam da rota
- o `GoldfishSimulator` ficou determinístico por deck/simulação para eliminar flakiness residual da Sprint 1
- suites locais de optimize ligadas a parser/pipeline/validator seguem verdes
- o corpus estavel agora tem gate recorrente proprio:
  - `scripts/quality_gate_resolution_corpus.sh`
  - wrapper em `scripts/quality_gate.sh resolution`
  - checagem explicita do resumo final (`failed=0`, `unresolved=0`, `passed=total`)
- `bootstrap_resolution_corpus_decks.dart` passou a aceitar seeds pareados com `A + B`
- `Jodah, the Unifier` foi confirmado como caso five-color viavel e hoje fecha em `safe_no_change` no probe isolado
- `Jodah, the Unifier`, `Kozilek, the Great Distortion` e `Wilson, Refined Grizzly + Sword Coast Sailor` foram promovidos ao corpus estavel
- o runner oficial de resolucao passou a aceitar `1` ou `2` comandantes legais, fechando o caso `background`
- o corpus estavel passou de `16` para `19` decks
- o falso positivo de identidade de cor por reminder text inline foi corrigido (`Blind Obedience` em `Sythis`)
- o gate recorrente do corpus foi revalidado com sucesso no backend recompilado: `19/19 passed`, `0 failed`, `0 unresolved`
- o app ganhou smoke funcional do fluxo `deck details -> optimize -> apply -> validate` na suíte do provider
- o contrato final de `optimize/rebuild` foi congelado em documento próprio
- a revisão residual do `onRequest` concluiu que o backend saiu da zona de bloqueio dominante da Sprint 1; o próximo gargalo real passou a ser o app core
- a task 6 foi iniciada com a extração de helpers puros para `deck_provider_support.dart`
- task 6 avancou com a extracao do contrato de IA, snapshots de debug e do builder de payload de aplicacao para `deck_provider_support.dart`
- `deck_details_screen.dart` iniciou recorte da semantica de loading/motivos do optimize para `deck_optimize_ui_support.dart`
- `deck_details_screen.dart` passou a mover tambem componentes compartilhados de UI para `deck_ui_components.dart`, reduzindo dependencias locais do arquivo gigante
- `deck_details_screen.dart` extraiu tambem widgets do fluxo de optimize para `deck_optimize_sheet_widgets.dart` e parsing/apresentacao do resultado para `deck_optimize_flow_support.dart`
- o arquivo `deck_details_screen.dart` caiu para `3587` linhas sem regressao no smoke do provider nem nos testes dos novos suportes
- `deck_optimize_flow_support.dart` agora cobre tambem o plano puro de rebuild e o plano puro de aplicacao, com teste direto no app para bulk/ids/fallback
- `deck_details_screen.dart` passou a mover tambem as secoes da sheet de optimize para `deck_optimize_sections.dart`, reduzindo o arquivo para `3423` linhas
- `deck_details_screen.dart` agora delega o corpo principal da sheet de optimize para `OptimizationSheetBody`, chegando a `3378` linhas
- `deck_optimize_flow_support.dart` ganhou executor puro do plano de aplicacao e teste dedicado de dispatch, reduzindo mais o peso do handler de optimize na tela
- `deck_details_screen.dart` moveu os loading dialogs do fluxo de optimize/rebuild/apply para `deck_optimize_dialogs.dart`
- `deck_optimize_flow_support.dart` ganhou executor puro do rebuild guiado e dispatch do erro de IA por tipo de outcome, com cobertura dedicada
- `deck_optimize_dialogs.dart` passou a abrir tambem o preview de confirmacao do optimize
- `deck_details_screen.dart` caiu para `3297` linhas sem regressao funcional no smoke do provider nem nos testes dos novos suportes
- `deck_optimize_flow_support.dart` passou a encapsular tambem o request de optimize com mapeamento de progresso e montagem de `preview/applyPlan`
- `deck_details_screen.dart` caiu para `3289` linhas, mantendo o fluxo verde e reduzindo mais a responsabilidade inline do handler principal
- `deck_optimize_flow_support.dart` passou a encapsular tambem o caminho confirmado de aplicacao (`apply + updateDeckStrategy`), com cobertura dedicada
- `deck_details_screen.dart` caiu para `3285` linhas, mantendo a malha verde e reduzindo mais a responsabilidade inline do fluxo de optimize
- `deck_optimize_dialogs.dart` passou a encapsular tambem os feedbacks do fluxo de optimize (`sem mudancas`, `debug copiado`, `sucesso`, `erro`)
- `deck_details_screen.dart` caiu para `3269` linhas, reduzindo mais os efeitos de UI repetidos inline
- `deck_optimize_dialogs.dart` passou a encapsular tambem feedbacks do rebuild guiado e o boilerplate de loading do optimize/apply
- `deck_details_screen.dart` caiu para `3242` linhas, mantendo os testes verdes e reduzindo mais o boilerplate inline do fluxo
- `deck_optimize_flow_support.dart` passou a encapsular tambem a orquestracao do rebuild guiado com callbacks para `preview`, `draft pronto`, `erro de IA` e `erro generico`
- `deck_details_screen.dart` caiu para `3237` linhas, reduzindo mais a coordenacao manual inline do fluxo de rebuild
- `deck_optimize_dialogs.dart` passou a encapsular tambem o `SnackBar` generico do fluxo de IA e o dialogo de falha do rebuild
- `deck_details_screen.dart` caiu para `3230` linhas, mantendo a malha verde e reduzindo mais feedbacks inline do fluxo
- `deck_provider_support.dart` passou a cobrir tambem resolucao paralela por nome, snapshots estruturais e a aplicacao pura de remocoes/adicoes com identidade do comandante, com teste dedicado
- `deck_provider.dart` passou a delegar tambem carregamento do deck, resolucao de nomes e salvamento/validacao do `applyOptimization`, reduzindo o arquivo para `1560` linhas
- `deck_optimize_flow_support.dart` passou a encapsular tambem a orquestracao composta do optimize (`request -> preview -> apply -> success/error`), reduzindo `deck_details_screen.dart` para `3207` linhas com cobertura dedicada
- `deck_optimize_flow_support.dart` passou a encapsular tambem o fluxo composto de `needs_repair/rebuild`, reduzindo `deck_details_screen.dart` para `3180` linhas com cobertura dedicada de rebuild e roteamento de falha
- widgets auxiliares de `deck_details_screen.dart` (`pricing row`, `mana/oracle`, `color identity pips`) foram extraidos para `deck_details_aux_widgets.dart`, reduzindo o arquivo para `2910` linhas
- os fluxos de explicação de carta e picker de edição foram extraídos para `deck_details_dialogs.dart`, reduzindo `deck_details_screen.dart` para `2726` linhas com cobertura dedicada em `deck_details_dialogs_test.dart`
- o diálogo de edição de carta foi extraído para `deck_card_edit_dialog.dart`, reduzindo `deck_details_screen.dart` para `2532` linhas com cobertura dedicada em `deck_card_edit_dialog_test.dart`
- a aba `Visão Geral` foi extraída para `deck_details_overview_tab.dart`, reduzindo `deck_details_screen.dart` para `2108` linhas com cobertura dedicada em `deck_details_overview_tab_test.dart`
- o diálogo completo de detalhes da carta foi extraído para `deck_details_dialogs.dart`, reduzindo `deck_details_screen.dart` para `1970` linhas e ampliando `deck_details_dialogs_test.dart` para cobrir `explicar`, `trocar edição` e `ver detalhes`
- handlers auxiliares de `toggle public`, `share`, `export`, `validate`, `auto-validate` e `pricing` foram extraídos para `deck_details_actions.dart`, com cobertura dedicada em `deck_details_actions_test.dart`
- o diálogo de importar lista do deck foi extraído para `deck_import_list_dialog.dart`, com cobertura dedicada em `deck_import_list_dialog_test.dart`
- o menu flutuante de adicionar cartas foi extraído para `deck_add_cards_menu.dart`
- `deck_details_screen.dart` caiu para `1550` linhas sem regressão na suíte focada do app core
- `deck_provider_support.dart` passou a encapsular tambem builders/parsers de importação e social (`importDeckFromList`, `validateImportList`, `importListToDeck`, `togglePublic`, `exportDeckAsText`, `copyPublicDeck`), reduzindo `deck_provider.dart` para `1502` linhas com cobertura dedicada em `deck_provider_support_test.dart`
- a bottom sheet de optimize foi corrigida para scroll único em `deck_optimize_sections.dart`, eliminando overflow real de viewport baixo
- a suíte do app ganhou smoke/widget real em `deck_details_screen_smoke_test.dart`, cobrindo `optimize -> preview -> apply -> validate` e `needs_repair -> rebuild_guided -> abrir draft`
- a `DeckDetailsScreen` também passou a ter cobertura de estados `loading`, `unauthorized`, `retry/error` e `empty`, fortalecendo a blindagem de UI real da Sprint 1
- o update de descricao, a confirmacao de remocao e a sheet de pricing foram extraídos do `deck_details_screen.dart`, reduzindo o arquivo para `1445` linhas e ampliando a cobertura dedicada de actions/dialogs
- `deck_provider_support.dart` passou a encapsular tambem `extractApiError`, `normalizeCreateDeckCards`, `generateDeckFromPrompt`, `searchFirstCardByName`, `resolveOptimizationAdditions` e `resolveOptimizationRemovals`
- `deck_provider_support.dart` passou a encapsular tambem parsing/cache/listagem de decks (`readFreshDeckDetailsFromCache`, `storeDeckDetailsInCache`, `syncDeckColorIdentityToList`, `applyCachedColorIdentitiesToDeckList`, `decksMissingColorIdentity`, `parseDeckDetailsResponse`, `parseDeckListResponse`)
- `deck_provider.dart` caiu para `1233` linhas e `deck_provider_support.dart` subiu para `883` linhas, mantendo a malha verde do provider e o smoke da `DeckDetailsScreen`
- `deck_provider_support_test.dart` foi ampliado para cobrir cache fresco, identidade de cor em lista, parse de respostas de detalhes/lista, normalizacao de criacao, geracao por prompt e resolucao de cartas por nome
- `deck_provider_support.dart` passou a encapsular tambem `parseAddCardResponse`, `incrementDeckCardCount`, `parseDeckAiAnalysisResponse`, `applyAiAnalysisToSelectedDeck` e `applyAiAnalysisToDeckList`
- `deck_provider.dart` caiu para `1207` linhas, delegando tambem mutacao incremental de contagem local e atualizacao de analise de IA
- `deck_provider_test.dart` ganhou cobertura direta para `addCardToDeck` e `refreshAiAnalysis`
- `deck_provider_support.dart` passou a encapsular tambem os parsers simples de I/O do deck (`parseOptimizationOptionsResponse`, `parseDeckValidationResponse`, `parseDeckPricingResponse`, `ensureSuccessfulDeckMutationResponse`)
- `deck_provider.dart` caiu para `1168` linhas, reduzindo boilerplate repetido em `fetchOptimizationOptions`, `updateDeckDescription`, `updateDeckStrategy`, `validateDeck`, `replaceCardEdition` e `fetchDeckPricing`
- `deck_provider_support_test.dart` ganhou cobertura desses parsers simples, e a suíte focada do provider continuou verde com a smoke da `DeckDetailsScreen`
- o caminho final de persistencia do optimize foi unificado em `_persistDeckCardsPayload`, removendo duplicacao entre `_saveOptimizedCards` e `applyOptimizationWithIds`
- `deck_provider.dart` caiu para `1167` linhas mantendo `flutter analyze` e a suíte focada do app core verdes
- `deck_provider_support.dart` passou a encapsular tambem `NamedOptimizationApplyResult` e `buildNamedOptimizationApplyResult`, tirando do provider o miolo puro de remocao/adicao/checagem de mudança no `applyOptimization`
- `deck_provider.dart` caiu para `1144` linhas e `deck_provider_support.dart` subiu para `1098` linhas mantendo `flutter analyze` e a suíte focada do app core verdes
- `deck_provider_support_test.dart` ganhou cobertura direta do miolo puro de `applyOptimization`, verificando remoção, adição e skip por identidade de cor

Subfila tecnica atual da Sprint 1:

1. continuar quebrando `deck_provider.dart` e `deck_details_screen.dart` em suporte de fluxo, contrato e apresentacao
2. focar agora no que ainda resta concentrado em `deck_provider.dart`, principalmente:
   - reduzir o boilerplate restante do bloco de optimize/aplicacao ainda local
   - limpeza final de I/O e atualizacao de estado compartilhado / mutacoes restantes
3. depois fechar o que faltar de smoke/widget das telas core adjacentes

Critério de saida:

- suite do core verde e estavel
- corpus recorrente de release funcionando
- smoke do app definido e repetivel
- sem regressao de contrato no optimize/rebuild

Observacao de execucao em `2026-03-24`:

- uma fatia minima da Sprint 2 foi antecipada para plugar `Sentry` e `x-request-id`
- isso nao substitui o fechamento da task 6 no app core; apenas evita que a frente operacional continue zerada

### Sprint 2 - Observabilidade e Operacao Base

Objetivo:

- criar base operacional comparavel ao que foi validado no `carMatch`, mas adaptada ao `mtgia`

Escopo:

- backend observability
- app observability
- readiness
- envs operacionais
- runbook de deploy/operacao

Tasks:

1. adicionar `Sentry` no backend Dart
2. adicionar `Sentry` no app Flutter
3. propagar `x-request-id` ponta a ponta
4. diferenciar `GET /health` de `GET /ready`
5. formalizar `server/.env.example` com chaves operacionais
6. criar runbook de EasyPanel do `mtgia`
7. criar smoke de ingestao/observabilidade

Estado parcial em `2026-03-24`:

- `IN_PROGRESS`: tasks 1, 2 e 3 em recorte minimo funcional
- `DONE` no recorte inicial:
  - `Sentry` backend ligado no middleware global
  - `Sentry` app ligado no bootstrap Flutter
  - `x-request-id` propagado em `ApiClient` e no backend
  - `GET /ready` publicado como alias operacional explícito
  - `server/.env.example` atualizado com chaves minimas de observabilidade e placeholders operacionais
  - setup documentado em `docs/SENTRY_SETUP_MTGIA_2026-03-24.md`
  - smoke real do backend validado por `event_id` via `./scripts/validate_sentry_backend_ingestion.sh`
  - runbook EasyPanel formalizado em `docs/EASYPANEL_RUNBOOK_MTGIA_2026-03-24.md`
- `PENDENTE`:
  - validacao de ingestao real do app
  - smoke operacional de observabilidade
  - validacao do smoke mobile em device/toolchain que conclua o build

Estado do app core em `2026-03-24`:

- `deck_details_screen.dart` reduzido para `1445` linhas com smoke/widget tests reais
- `deck_provider.dart` reduzido para `1095` linhas
- `deck_provider_support.dart` absorvendo requests simples de I/O, importação, social/export e helpers puros com cobertura dedicada
- malha focada do app core segue verde após o recorte:
  - `deck_provider_support_test.dart`
  - `deck_provider_test.dart`
  - `deck_details_screen_smoke_test.dart`
  - `api_client_request_id_test.dart`

Critério de saida:

- backend e app reportando erros para ambiente central
- `requestId` correlacionando app, backend e erro
- `GET /ready` com checks reais
- documentacao operacional pronta

### Sprint 3 - Performance e Escala Base

Objetivo:

- endurecer a camada de capacidade para o fluxo core sem ainda abrir uma frente pesada de jobs

Escopo:

- endpoints quentes
- cache
- rate limit
- dashboard de capacidade
- carga

Tasks:

1. promover `server/bin/load_test_core_flow.dart` a suite operacional oficial
2. definir thresholds minimos por endpoint core
3. revisar cache curto dos endpoints quentes
4. preparar migracao de cache in-memory para Redis em multi-instancia
5. revisar calibracao de `rate_limit_middleware.dart`
6. ampliar dashboard operacional com sinais de capacidade

Critério de saida:

- thresholds documentados
- carga repetivel
- leitura minima de p95/p99 por endpoint core
- plano de cache multi-instancia definido

### Sprint 4 - Assincrono e Worker do Core de IA

Objetivo:

- tirar do request principal o que for pesado demais no fluxo de IA

Escopo:

- optimize async
- rebuild guiado pesado
- explain/generate mais caros
- refresh de referencia de commander

Tasks:

1. decidir tecnologia de fila/worker compativel com Dart e com a infra real
2. introduzir worker dedicado
3. adicionar heartbeat do worker
4. plugar o worker ao `GET /ready`
5. mover o primeiro bloco pesado para execucao assincrona
6. manter fallback seguro para rollout parcial

Critério de saida:

- primeiro caso real de IA pesada fora do request principal
- readiness cobrindo worker
- rollback/fallback seguro documentado

### Sprint 5 - App Core De Decks Com Cobertura Forte

Objetivo:

- subir a confianca do app no mesmo nivel do backend para a jornada principal

Escopo:

- telas do fluxo de decks
- providers do core
- smoke/widget coverage

Tasks:

1. quebrar responsabilidades em:
   - `deck_details_screen.dart`
   - `deck_provider.dart`
2. ampliar smoke/widget tests do fluxo principal
3. revisar loading, erro, vazio e sucesso das telas core
4. endurecer UX de optimize/rebuild/apply
5. reforcar explicabilidade e feedback de deck

Critério de saida:

- melhor cobertura das telas core
- menos responsabilidade concentrada
- UX do fluxo principal consistente

### Sprint 6 - Tema, Consistencia Visual e Sistema de Design

Objetivo:

- melhorar a arquitetura visual sem perder a identidade MTG

Escopo:

- tema
- tokens
- backgrounds por contexto
- limpeza de hardcodes restantes

Tasks:

1. aplicar o plano de absorcao do tema do `carMatch` sem copiar a estetica
2. separar:
   - colors
   - gradients
   - typography
   - theme
3. criar backgrounds reutilizaveis por contexto
4. limpar hardcodes visuais restantes

Critério de saida:

- design system mais modular
- identidade visual preservada
- menor deriva de cor/layout

### Sprint 7 - Superficies Secundarias e Retencao

Objetivo:

- retomar superficies de apoio sem competir com o core

Escopo:

- binder
- collection
- trades
- messages
- community
- scanner
- social

Tasks:

1. conectar deck ao binder
2. melhorar matching de `have/want`
3. revisar scanner e permissoes reais
4. revisar mensagens/trades/community
5. completar instrumentacao de uso real

Critério de saida:

- superficies secundarias sem derrubar a confianca do carro-chefe

## Priorizacao resumida

### Ordem dura

1. Sprint 1
2. Sprint 2
3. Sprint 3
4. Sprint 4
5. Sprint 5
6. Sprint 6
7. Sprint 7

### Regra executiva

- nenhuma sprint secundaria deve furar a fila enquanto a sprint atual ainda tiver risco estrutural aberto

## Dependencias entre sprints

- Sprint 2 depende da Sprint 1 suficientemente estabilizada
- Sprint 3 depende da Sprint 2 para observabilidade minima
- Sprint 4 depende da Sprint 2 e da Sprint 3
- Sprint 5 ainda pode andar parcialmente junto da Sprint 1, mas so no fluxo core
- Sprint 6 e Sprint 7 devem ficar depois do endurecimento tecnico principal

## Proximo passo imediato

O proximo passo dominante continua sendo:

1. seguir na modularizacao de `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/routes/ai/optimize/index.dart`

Depois disso, manter a fila oficial desta forma:

2. gate recorrente do corpus
3. casos dirigidos restantes
4. smoke do app do fluxo core

Esses quatro itens juntos ainda pertencem a Sprint 1.
