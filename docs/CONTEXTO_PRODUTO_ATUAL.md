# Contexto Produto Atual

> Fonte de verdade operacional para os proximos pedidos do `mtgia`.
> Sempre consultar este arquivo antes de ampliar escopo, mudar fluxo core ou reorganizar prioridades.
> Se alguma decisao estrutural mudar, este documento deve ser atualizado primeiro.

## Regra de precedencia documental

Este arquivo prevalece sobre:

- roadmaps antigos do app
- trackers locais de frentes secundarias
- handoffs congelados antes de `2026-03-23`

Esses documentos continuam como apoio e historico, mas nao devem redefinir a prioridade operacional sem que este arquivo seja atualizado primeiro.

## Resumo Executivo

- produto ativo: `app/` + `server/`
- proposta central: gerar, importar, validar, analisar e otimizar decks de Magic com confiabilidade real
- carro chefe do produto: fluxo `criar/importar -> analisar -> otimizar -> aplicar -> validar`
- prioridade operacional atual: blindar o fluxo core de decks sem deixar telas adjacentes derrubarem a percepcao de confianca
- prioridade operacional imediata: Sprint 1 totalmente dedicada a deixar a otimizacao de decks no maior nivel possivel de confiabilidade antes de qualquer outra frente
- superficie auditada nesta rodada: `25` telas Flutter em `app/lib/features/**/screens`
- status tecnico local em `2026-03-23`:
- `app/flutter analyze`: verde
- `app/flutter test`: verde
- `server/dart test`: verde

## Documentos Que Abrem Contexto Rapido

- `docs/README.md`
- `docs/AUDITORIA_UX_LOGICA_PERFORMANCE_2026-03-23.md`
- `docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md`
- `README.md`
- `ROADMAP.md`
- `CHECKLIST_GO_LIVE_FINAL.md`
- `RELATORIO_VALIDACAO_2026-03-16.md`
- `server/manual-de-instrucao.md`

## Proximo passo oficial

Enquanto este documento nao mudar, a proxima task dominante do projeto e:

1. continuar reduzindo responsabilidade concentrada em `deck_provider.dart` e `deck_details_screen.dart`, priorizando extracao de semantica/fluxo reutilizavel antes de mexer na navegacao
2. subir smoke/widget tests reais da UI do fluxo `deck details -> optimize -> preview -> apply -> validate` e `needs_repair -> rebuild_guided -> abrir draft`

Sequencia imediata ja definida:

3. so depois retomar frentes fora do deck builder

Excecao documentada em `2026-03-24`:

- a primeira fenda da Sprint 2 foi antecipada para plugar `Sentry` e `x-request-id`, usando como referencia operacional o `carMatch`
- isso foi feito sem reabrir escopo de produto e sem interromper a fila do app core

Progresso atual documentado da Sprint 1:

- `server/routes/ai/optimize/index.dart`: reduzido para `2745` linhas
- `server/lib/ai/optimize_runtime_support.dart`: consolidado em `2842` linhas
- `server/lib/ai/optimize_analysis_support.dart`: novo modulo com `294` linhas
- `server/lib/ai/optimize_deck_support.dart`: novo modulo com `179` linhas
- `server/lib/ai/optimize_state_support.dart`: novo modulo com `981` linhas
- `server/lib/ai/optimize_complete_support.dart`: novo modulo com `772` linhas
- `server/lib/ai/optimize_complete_support.dart`: expandido para `1080` linhas
- `server/lib/ai/optimize_request_support.dart`: novo modulo com `245` linhas
- gate recorrente do corpus estavel criado em `scripts/quality_gate_resolution_corpus.sh`
- wrapper geral adicionado em `scripts/quality_gate.sh resolution`
- `server/bin/bootstrap_resolution_corpus_decks.dart` agora aceita seeds pareados via `A + B`
- casos dirigidos estabilizados e promovidos ao corpus estavel:
  - `Jodah, the Unifier` -> `safe_no_change`
  - `Kozilek, the Great Distortion` -> `rebuild_guided`
  - `Wilson, Refined Grizzly + Sword Coast Sailor` -> `safe_no_change`
- o runner de resolucao agora aceita `1` ou `2` comandantes legais, cobrindo `partner/background`
- a inferencia de identidade de cor passou a ignorar simbolos de mana presentes apenas em reminder text inline, evitando falso positivo em cartas como `Blind Obedience`
- gate recorrente do corpus estavel revalidado com o build novo do backend: `19/19 passed`, `0 failed`, `0 unresolved`
- smoke funcional do app para `deck details -> optimize -> apply -> validate` adicionado na suite do provider
- contrato funcional do fluxo `optimize -> rebuild -> validate` consolidado em documento proprio
- revisao residual do `onRequest` concluida: a rota ainda e grande (`2721` linhas), mas o miolo critico ja esta modularizado e deixou de ser bloqueio dominante da Sprint 1
- task 6 iniciada com extracao dos helpers puros de payload/identidade do comandante para `app/lib/features/decks/providers/deck_provider_support.dart`
- task 6 avancou com extracao do contrato de IA, snapshots de debug e montagem do payload de aplicacao para `app/lib/features/decks/providers/deck_provider_support.dart`
- `deck_details_screen.dart` iniciou o recorte da camada de semantica do optimize para `app/lib/features/decks/widgets/deck_optimize_ui_support.dart`
- `deck_details_screen.dart` tambem iniciou a extracao dos componentes compartilhados de UI de deck para `app/lib/features/decks/widgets/deck_ui_components.dart`
- `deck_details_screen.dart` perdeu o preview/dialogs/cards do fluxo de optimize para `deck_optimize_sheet_widgets.dart` e o parsing/apresentacao do resultado para `deck_optimize_flow_support.dart`
- `deck_details_screen.dart` caiu para `3587` linhas na rodada atual, deixando de concentrar toda a camada visual do fluxo de optimize
- `deck_optimize_flow_support.dart` passou a concentrar tambem a decisao pura de rebuild guiado e o plano de aplicacao (`bulk`, `ids` ou `fallback por nomes`), com teste dedicado no app
- `deck_details_screen.dart` extraiu tambem as secoes da sheet de optimize para `deck_optimize_sections.dart`, reduzindo o arquivo para `3423` linhas
- `deck_details_screen.dart` passou a delegar o corpo principal da sheet de optimize para `OptimizationSheetBody`, reduzindo o arquivo para `3378` linhas
- `deck_optimize_flow_support.dart` passou a executar tambem o plano de aplicacao via callbacks (`bulk`, `ids`, `fallback por nomes`), mantendo a tela fora da decisao de dispatch e ampliando a malha de testes do app
- `deck_details_screen.dart` moveu os loading dialogs do fluxo de optimize/rebuild/apply para `app/lib/features/decks/widgets/deck_optimize_dialogs.dart`
- `deck_optimize_flow_support.dart` passou a executar tambem o rebuild guiado via request/outcome puro e o dispatch do erro de IA (`needs_repair`, `near_peak`, `no_safe_upgrade_found`, `generic`), com testes dedicados
- `deck_optimize_dialogs.dart` passou a encapsular tambem a abertura do preview de confirmacao do optimize
- `deck_details_screen.dart` caiu para `3297` linhas, mantendo o fluxo principal intacto e reduzindo mais a camada de efeito inline
- `deck_optimize_flow_support.dart` passou a centralizar tambem o pedido de optimize com traducao de progresso e normalizacao de `preview/applyPlan`
- `deck_details_screen.dart` caiu para `3289` linhas, deixando menos logica inline no handler de optimize
- `deck_optimize_flow_support.dart` passou a executar tambem o caminho confirmado de `apply + updateDeckStrategy`, com teste dedicado
- `deck_details_screen.dart` caiu para `3285` linhas, reduzindo mais o handler principal sem mudar o contrato do fluxo
- `deck_optimize_dialogs.dart` passou a centralizar tambem os feedbacks de optimize (`sem mudancas`, `debug copiado`, `sucesso`, `erro de aplicacao`)
- `deck_details_screen.dart` caiu para `3269` linhas, com menos efeitos de UI repetidos inline no fluxo principal
- `deck_optimize_dialogs.dart` passou a centralizar tambem feedbacks do rebuild guiado e o boilerplate de loading do optimize/apply
- `deck_details_screen.dart` caiu para `3242` linhas, mantendo a malha verde e deixando menos boilerplate de UI no fluxo
- `deck_optimize_flow_support.dart` passou a encapsular tambem a orquestracao do rebuild guiado via callbacks de `preview`, `draft pronto`, `erro de IA` e `erro generico`
- `deck_details_screen.dart` caiu para `3237` linhas, reduzindo mais a coordenacao manual do fluxo de rebuild
- `deck_optimize_dialogs.dart` passou a centralizar tambem o ultimo `SnackBar` generico do fluxo de IA e o dialogo de falha especifico do rebuild
- `deck_details_screen.dart` caiu para `3230` linhas, com menos feedbacks e erros inline no fluxo de optimize/rebuild
- `deck_provider_support.dart` passou a encapsular tambem a resolucao paralela por nome, snapshots estruturais e a aplicacao pura de remocoes/adicoes com identidade do comandante, com cobertura dedicada em `deck_provider_support_test.dart`
- `deck_provider.dart` passou a delegar tambem carregamento do deck, resolucao de nomes e salvamento/validacao final do `applyOptimization`, reduzindo o arquivo para `1560` linhas sem regressao no smoke do app core
- `deck_optimize_flow_support.dart` passou a orquestrar tambem o fluxo composto de optimize (`request -> preview -> apply -> success/error`), e `deck_details_screen.dart` caiu para `3207` linhas com teste dedicado para esse caminho
- `deck_optimize_flow_support.dart` passou a encapsular tambem o fluxo composto de `needs_repair/rebuild`, e `deck_details_screen.dart` caiu para `3180` linhas com cobertura dedicada para rebuild e roteamento de falha
- widgets auxiliares de deck details (`pricing row`, `mana/oracle`, `color identity pips`) foram movidos para `app/lib/features/decks/widgets/deck_details_aux_widgets.dart`, reduzindo `deck_details_screen.dart` para `2910` linhas
- os diálogos/fluxos de explicação de carta e picker de edição saíram para `app/lib/features/decks/widgets/deck_details_dialogs.dart`, reduzindo `deck_details_screen.dart` para `2726` linhas e adicionando cobertura dedicada em `deck_details_dialogs_test.dart`
- o diálogo de edição de carta saiu para `app/lib/features/decks/widgets/deck_card_edit_dialog.dart`, reduzindo `deck_details_screen.dart` para `2532` linhas e adicionando cobertura dedicada em `deck_card_edit_dialog_test.dart`
- a aba `Visão Geral` saiu para `app/lib/features/decks/widgets/deck_details_overview_tab.dart`, reduzindo `deck_details_screen.dart` para `2108` linhas e adicionando cobertura dedicada em `deck_details_overview_tab_test.dart`
- o diálogo completo de detalhes da carta foi movido para `app/lib/features/decks/widgets/deck_details_dialogs.dart`, reduzindo `deck_details_screen.dart` para `1970` linhas e ampliando `deck_details_dialogs_test.dart` com cobertura das ações `explicar`, `trocar edição` e `ver detalhes`
- handlers auxiliares de `toggle public`, `share`, `export`, `validate`, `auto-validate` e `pricing load` saíram para `app/lib/features/decks/widgets/deck_details_actions.dart`, com cobertura dedicada em `deck_details_actions_test.dart`
- o diálogo grande de importação de lista saiu para `app/lib/features/decks/widgets/deck_import_list_dialog.dart`, com cobertura dedicada em `deck_import_list_dialog_test.dart`
- o menu flutuante de adicionar cartas saiu para `app/lib/features/decks/widgets/deck_add_cards_menu.dart`
- `deck_details_screen.dart` caiu para `1550` linhas mantendo a malha verde do app core
- `deck_provider_support.dart` passou a encapsular tambem builders/parsers de importacao e social (`importDeckFromList`, `validateImportList`, `importListToDeck`, `togglePublic`, `exportDeckAsText`, `copyPublicDeck`), reduzindo `deck_provider.dart` para `1502` linhas com cobertura dedicada em `deck_provider_support_test.dart`
- a `OptimizationSheetBody` passou de `Column + Expanded` para `ListView` com scroll unico, eliminando overflow real da bottom sheet em viewport baixa
- a UI do fluxo core agora tem smoke/widget tests dedicados em `app/test/features/decks/screens/deck_details_screen_smoke_test.dart`, cobrindo:
  - `deck details -> optimize -> preview -> apply -> validate`
  - `needs_repair -> rebuild_guided -> abrir draft`
- a `DeckDetailsScreen` agora tem cobertura real de estados `loading`, `unauthorized`, `retry/error` e `empty`, usando providers de teste e fake API sem depender apenas do smoke feliz
- o update de descricao, a confirmacao de remocao e a sheet de pricing saíram do `deck_details_screen.dart` para helpers/dialogs dedicados, reduzindo a tela para `1445` linhas com cobertura ampliada em `deck_details_actions_test.dart` e `deck_details_dialogs_test.dart`
- `deck_provider_support.dart` passou a encapsular tambem `extractApiError`, `normalizeCreateDeckCards`, `generateDeckFromPrompt`, `searchFirstCardByName`, `resolveOptimizationAdditions` e `resolveOptimizationRemovals`
- `deck_provider_support.dart` passou a encapsular tambem parsing/cache/listagem de decks (`readFreshDeckDetailsFromCache`, `storeDeckDetailsInCache`, `syncDeckColorIdentityToList`, `applyCachedColorIdentitiesToDeckList`, `decksMissingColorIdentity`, `parseDeckDetailsResponse`, `parseDeckListResponse`)
- `deck_provider.dart` caiu para `1233` linhas e `deck_provider_support.dart` subiu para `883` linhas, mantendo a malha verde do provider e o smoke da `DeckDetailsScreen`
- `deck_provider_support_test.dart` foi ampliado para cobrir cache fresco, helpers de identidade de cor, parse de respostas de detalhes/lista, normalizacao de criacao, geracao por prompt e resolucao de cartas por nome
- `deck_provider_support.dart` passou a encapsular tambem `parseAddCardResponse`, `incrementDeckCardCount`, `parseDeckAiAnalysisResponse`, `applyAiAnalysisToSelectedDeck` e `applyAiAnalysisToDeckList`
- `deck_provider.dart` caiu para `1207` linhas, delegando tambem mutacao incremental de contagem local e atualizacao de analise de IA
- `deck_provider_test.dart` ganhou cobertura direta para `addCardToDeck` e `refreshAiAnalysis`, mantendo a smoke da `DeckDetailsScreen` verde
- `deck_provider_support.dart` passou a encapsular tambem os parsers simples de I/O do deck (`parseOptimizationOptionsResponse`, `parseDeckValidationResponse`, `parseDeckPricingResponse`, `ensureSuccessfulDeckMutationResponse`)
- `deck_provider.dart` caiu para `1168` linhas, reduzindo boilerplate repetido em `fetchOptimizationOptions`, `updateDeckDescription`, `updateDeckStrategy`, `validateDeck`, `replaceCardEdition` e `fetchDeckPricing`
- `deck_provider_support_test.dart` ganhou cobertura desses parsers simples, e a suíte focada do provider continuou verde junto com a smoke da `DeckDetailsScreen`
- o caminho de persistencia final do optimize foi unificado em `_persistDeckCardsPayload`, removendo duplicacao entre `_saveOptimizedCards` e `applyOptimizationWithIds`
- `deck_provider.dart` caiu para `1167` linhas mantendo `flutter analyze` e a suíte focada do app core verdes
- `deck_provider_support.dart` passou a encapsular tambem `NamedOptimizationApplyResult` e `buildNamedOptimizationApplyResult`, tirando do provider o miolo puro de remocao/adicao/checagem de mudança no `applyOptimization`
- `deck_provider.dart` caiu para `1144` linhas e `deck_provider_support.dart` subiu para `1098` linhas mantendo `flutter analyze` e a suíte focada do app core verdes
- `deck_provider_support_test.dart` ganhou cobertura direta do miolo puro de `applyOptimization`, verificando remoção, adição e skip por identidade de cor
- `deck_provider_support.dart` passou a encapsular tambem as requests simples de I/O do core:
  - `addCardToDeckRequest`
  - `fetchOptimizationOptionsRequest`
  - `validateDeckRequest`
  - `fetchDeckPricingRequest`
  - `refreshAiAnalysisRequest`
  - `updateDeckDescriptionRequest`
  - `updateDeckStrategyRequest`
  - `replaceCardEditionRequest`
  - `importDeckFromListRequest`
  - `validateImportListRequest`
  - `importListToDeckRequest`
  - `togglePublicRequest`
  - `exportDeckAsTextRequest`
  - `copyPublicDeckRequest`
- `deck_provider.dart` caiu para `1095` linhas e ficou mais próximo de orquestração pura, enquanto `deck_provider_support_test.dart` ganhou cobertura direta desses request helpers
- `Sentry` backend foi ligado em `server/lib/observability.dart` e no middleware global, com propagação de `x-request-id` via `server/lib/request_trace.dart`
- `Sentry` app foi ligado em `app/lib/core/observability/app_observability.dart`, com captura global de erros, observer de rota e `x-request-id` em `app/lib/core/api/api_client.dart`
- `server/.env.example` foi atualizado com as chaves mínimas de observabilidade e o setup ficou registrado em `docs/SENTRY_SETUP_MTGIA_2026-03-24.md`
- o smoke real do backend foi promovido para `./scripts/validate_sentry_backend_ingestion.sh`, confirmando ingestão real por `event_id` no Sentry
- `server/.env.example` passou a formalizar também os placeholders operacionais de EasyPanel e Sentry (`SENTRY_AUTH_TOKEN`, slugs de projeto e `EASYPANEL_*`)
- o runbook operacional de deploy foi formalizado em `docs/EASYPANEL_RUNBOOK_MTGIA_2026-03-24.md`
- a validação real de ingestão do app segue pendente; o smoke mobile e o script já existem, mas o build macOS local ainda ficou preso no ciclo nativo e não devolveu `event_id`
- `GET /ready` foi publicado em `server/routes/ready/index.dart`, compartilhando os checks reais de readiness já usados em `/health/ready`
- blocos ja extraidos:
  - payload parser e normalizacao
  - deterministic-first response/cache/fallback
  - inferencia funcional e heuristicas
  - commander profile cache/fallbacks
  - identidade de cor, basicos e recovery estrutural
  - slot fillers deterministas, broad/meta fillers, synergy replacement e scoring
  - removal candidates e swap candidates do caminho deterministico
  - logging/persistencia de analysis outcome
  - montagem de deck virtual, addition entries e repair plan
  - analisador de arquétipo, detecção de tema e avaliação de estado do deck
  - preparação de referências do commander, loop de complete async, rebalanceamento e fallback de preenchimento
  - assembly final do `complete`, incluindo agregação por nome, `post_analysis` e payload final do job
  - carregamento de deck, parsing de cartas, identidade de cor, análise inicial, tema e estado do deck
- cuidado de compatibilidade mantido: helpers exercitados por testes continuam acessiveis via wrappers leves na biblioteca da rota

## Pendencias abertas da Sprint 1

Fila oficial restante da Sprint 1, na ordem:

1. reduzir responsabilidade concentrada nos pontos gigantes restantes do app core:
   - `app/lib/features/decks/screens/deck_details_screen.dart`
   - `app/lib/features/decks/providers/deck_provider.dart`
2. focar agora no que ainda resta concentrado em `deck_provider.dart`, principalmente:
   - reduzir o boilerplate restante do bloco de optimize/aplicacao ainda local
   - limpeza final de estado compartilhado / mutacoes restantes (`deleteDeck`, persistencia pos-optimize e fetch/update de deck ainda concentrados)
3. ao fechar esse recorte do app core, retomar os bloqueadores operacionais restantes da Sprint 2:
   - validar ingestao real do app no Sentry
   - confirmar `/ready` no ambiente publicado
   - revisar o checklist de go-live

Regra pratica:

- nenhuma melhoria visual ou operacional fora do core deve furar essa fila
- toda entrega desta fila deve atualizar este arquivo e `docs/PLANO_SPRINTS_EXECUCAO_MTGIA_2026-03-23.md`

## Regra Rapida De Decisao

Se um pedido novo nao disser o contrario:

1. assumir que o escopo principal e o fluxo de decks
2. tratar `geracao`, `analise`, `otimizacao`, `importacao` e `validacao` como trilha critica do produto
3. nao deixar features adjacentes (`community`, `trades`, `binder`, `messages`, `scanner`) degradarem a confianca do fluxo core
4. toda tela do fluxo core precisa preservar contexto do usuario, especialmente `formato`, `deckId`, feedback de erro e estado de carregamento
5. toda melhoria de UX precisa ser acompanhada de validacao tecnica minimamente repetivel

## Ultima Atualizacao

- data: 2026-03-24
- status: ativo
- prioridade atual: consolidar confiabilidade do core de decks e mapear riscos de usabilidade/performance das telas
- regra funcional nova: o formato escolhido no onboarding precisa chegar intacto nas telas de geracao e importacao
- regra executiva nova: nenhuma frente secundaria deve competir com a frente de otimizacao de decks enquanto o carro chefe do produto nao atingir nivel de confianca de release
- regra de UX nova: a home nao pode mostrar estado vazio definitivo antes de buscar os decks reais do usuario
- regra tecnica nova de confiabilidade: testes de integracao do backend devem ser opt-in por ambiente (`RUN_INTEGRATION_TESTS=1`) e nao podem falhar a suite local por ausencia de servidor
- regra tecnica nova de consistencia: simulacoes do `OptimizationValidator` devem ser deterministicas para reduzir flakiness de score e aumentar confianca do CI
- regra documental nova: toda decisao sobre a frente de otimizacao deve consultar `docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md` antes de ampliar escopo ou declarar confianca de release
- regra de resiliencia local: rotas de IA que ja possuem fallback seguro devem tolerar `OPENAI_API_KEY` invalida em `dev/staging`, sem mascarar erro em `prod`
- regra nova do corpus operacional: o corpus estavel de resolucao Commander foi ampliado para `19` decks validados, incluindo cobertura dirigida de five-color, colorless e `background`
- regra nova de cobertura dirigida: o bootstrap do corpus passou a aceitar pares de comandantes com `A + B`, e o runner passou a validar `1` ou `2` comandantes legais conforme o deck fonte
- regra nova de identidade de cor: reminder text inline nao pode mais inflar identidade de cor; o caso de `Blind Obedience` em `Sythis` passou a validar corretamente
- regra nova de seed confiavel: o bootstrap do corpus nao pode mais completar 100 cartas inflando terrenos quando faltarem spells; nesses casos ele deve falhar com `montagem insuficiente`
- regra nova de identidade de cor: quando `cards.color_identity` vier vazio/incompleto, a validacao deve inferir identidade pelo `oracle_text` para nao aceitar duals/lands fora da identidade real por lacuna de banco
- excecao documentada do corpus: `Yuriko, the Tiger's Shadow` ficou fora do corpus estavel apos a rodada de 2026-03-23 por nao conseguir gerar seed saudavel com o material atual de referencia

## Estrutura Oficial Do Produto

### 1. Core Deck Builder

- `app/lib/features/decks/`
- `server/routes/decks/`
- `server/routes/ai/generate`
- `server/routes/ai/optimize`
- `server/routes/ai/rebuild`

Esse bloco define valor direto de produto e deve continuar sendo a frente dominante.

### 2. Superficies De Apoio

- `cards`
- `collection`
- `binder`
- `market`
- `scanner`
- `community`
- `social`
- `messages`
- `notifications`
- `trades`
- `profile`
- `life_counter`

Essas areas aumentam utilidade e retencao, mas nao podem consumir a prioridade do fluxo core enquanto ainda houver risco de confianca em decks.

## Mapa De Risco Atual

### P0 Resolvido Nesta Rodada

- onboarding perdia o `format` escolhido ao entrar em `deck_generate_screen` e `deck_import_screen`
- home podia sugerir "nenhum deck criado" antes do primeiro fetch real
- `server/dart test` falhava localmente por suites de integracao disparando autenticacao sem servidor ativo
- score do `OptimizationValidator` tinha oscilacao estatistica desnecessaria por RNG nao deterministico no mulligan report

### P1 Aberto

- `app/lib/features/decks/screens/deck_details_screen.dart` continua muito grande e concentra logica critica demais em uma unica tela
- `app/lib/features/decks/providers/deck_provider.dart` ainda carrega responsabilidade excessiva para criacao, importacao, analise, otimizacao e manutencao de cache
- `server/routes/ai/optimize/index.dart` segue muito acima do tamanho ideal e representa gargalo de manutencao
- cobertura automatizada do app ainda esta abaixo do ideal para as `25` telas; a maior parte da protecao continua em widgets especificos e no backend
- validacao manual em device real ainda e necessaria para `scanner`, permissao de camera, push notifications e compartilhamento

## Norte De Qualidade

Para considerar o produto confiavel:

1. o usuario precisa conseguir sair do onboarding e chegar no primeiro deck otimizado sem perda de contexto
2. o backend precisa continuar respondendo com contratos previsiveis e suites verdes
3. telas do fluxo core precisam ter estados claros de loading, erro, vazio e sucesso
4. resultados de IA precisam ser explicaveis, aplicaveis e validaveis
5. qualquer regressao no core precisa ser detectada por teste ou por checklist operacional explicito

## Sprint Operacional Atual

### Objetivo

Fechar o ciclo de confiabilidade do deck builder principal e transformar a auditoria desta rodada em base oficial de trabalho.

### Ordem De Execucao

1. proteger onboarding, home e entrada no fluxo core
2. dedicar a Sprint 1 inteira a qualidade da otimizacao de decks
3. endurecer a confiabilidade dos testes locais e da validacao estatistica
4. mapear e corrigir gargalos logicos da pipeline `generate -> analyze -> optimize -> apply -> validate`
5. somente depois retomar UX lateral, social, scanner e superfices secundarias

### Entregas Fechadas Nesta Rodada

- `main.dart` agora propaga `format` para `DeckGenerateScreen` e `DeckImportScreen`
- `DeckGenerateScreen` e `DeckImportScreen` agora respeitam `initialFormat`
- `HomeScreen` passou a buscar decks ao abrir e mostra carregamento antes do estado vazio
- novo teste de widget garante que o formato vindo do onboarding chega nas telas de entrada do fluxo
- suites de integracao do backend agora respeitam melhor o modo local sem servidor
- `OptimizationValidator` passou a usar seed estavel para reduzir flakiness nos scores
- `GoldfishSimulator` passou a usar seed estavel por deck/simulacao, removendo oscilacao residual da suíte do validator
- auditoria formal da malha de testes da otimizacao foi consolidada em documento proprio com distincoes entre regra, simulacao e HTTP real

### Definicao Oficial Da Sprint 1

Objetivo unico:

- elevar a otimizacao de decks ao maior nivel possivel de confiabilidade pratica

Escopo permitido:

- `server/routes/ai/optimize`
- `server/lib/ai/**`
- `server/routes/decks/**/analysis`
- `server/routes/decks/**/validate`
- `app/lib/features/decks/**`
- testes e artefatos diretamente ligados ao fluxo de otimizacao

Escopo bloqueado ate segunda ordem:

- expansao de `community`
- evolucao de `trades`
- melhorias cosmeticas fora do fluxo core
- novas features de `binder`, `market`, `messages` ou `scanner` que nao protejam o deck builder

Critério de saida da Sprint 1:

1. suite estatica e automatizada verde e estavel
2. corpus de decks de referencia cobrindo casos reais e extremos
3. quality gates objetivos para piora de consistencia, legalidade, role preservation e identidade de cor
4. contrato claro de erro, warning e sucesso da otimizacao
5. smoke manual guiado comprovando jornada completa no app

## Como Devemos Trabalhar A Partir De Agora

Antes de implementar qualquer pedido novo, confirmar internamente:

1. isso melhora ou protege o fluxo principal de decks?
2. existe alguma tela do core perdendo contexto do usuario?
3. a mudanca precisa de teste automatico ou checklist manual?
4. ha algum arquivo gigante demais para receber mais responsabilidade?
5. a documentacao ativa continua coerente com o estado real do sistema?

## Aditivo - Estado Atual Da Otimizacao Em 2026-03-23

Revalidacao operacional concluida:

- `server/test/ai_optimize_flow_test.dart`: verde contra backend local real
- `server/test/ai_generate_create_optimize_flow_test.dart`: verde contra backend local real
- `server/run_optimize_validation.ps1`: verde, consolidando bootstrap local + suites deterministicas + suites HTTP criticas

Achados de logica fechados:

- a otimizacao agora usa inferencia de identidade por `oracle_text` tambem dentro da propria rota, e nao so na camada de regra
- `{C}` deixou de ser tratado como cor de identidade de Commander
- isso removeu falso negativo em cartas colorless validas e reduziu risco de candidato off-color passar por base incompleta

Decisao sobre comandantes:

- o corpus estavel atual com `16` decks e suficiente para a fase atual
- nao ha necessidade de adicionar mais comandantes apenas por quantidade
- a proxima expansao, quando vier, deve ser dirigida por cobertura de comportamento e nao por volume

As tasks acima continuam sendo a fila oficial do core.
