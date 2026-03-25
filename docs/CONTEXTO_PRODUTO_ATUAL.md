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
- `docs/SPRINT_LIFE_COUNTER_TABLETOP_2026-03-25.md`
- `docs/SPRINT_LIFE_COUNTER_BENCHMARK_CLONE_2026-03-25.md`
- `README.md`
- `ROADMAP.md`
- `CHECKLIST_GO_LIVE_FINAL.md`
- `RELATORIO_VALIDACAO_2026-03-16.md`
- `server/manual-de-instrucao.md`

## Proximo passo oficial

Enquanto este documento nao mudar, a proxima task dominante do projeto e:

1. fechar o residual final de orquestracao no `deck_provider.dart`, sem reabrir escopo em `deck_details_screen.dart`
2. retomar o bloqueio operacional remanescente da Sprint 2:
   - validar ingestao real do app no `Sentry`
   - confirmar correlacao ponta a ponta de `x-request-id` com request real do app
   - revisar o `CHECKLIST_GO_LIVE_FINAL.md` com base no que ja esta efetivamente entregue

Sequencia imediata ja definida:

3. so depois promover carga basica/thresholds do fluxo core
4. so depois retomar frentes fora do deck builder

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
- `deck_provider_support.dart` passou a encapsular tambem `createDeckRequest`, `removeCardFromDeckRequest`, `setDeckCardQuantityRequest` e o parse padronizado de mutacoes simples de deck
- `deck_provider_support.dart` passou a encapsular tambem o enrichment assíncrono de `color_identity` para decks ainda sem cor carregada
- `deck_provider.dart` caiu para `1074` linhas, deixando `createDeck`, `removeCardFromDeck`, `updateDeckCardEntry` e parte do enrichment de cor mais próximos de orquestração e mantendo a suite focada do app core verde
- `deck_provider_support.dart` passou a encapsular tambem o request/parser completo de `optimizeDeck`, incluindo respostas `200`, `202` e `422`
- `deck_provider.dart` caiu para `1035` linhas, deixando o provider mais focado em orquestração e polling, sem carregar mais o parse inline do `POST /ai/optimize`
- `deck_provider_support.dart` passou a encapsular tambem o request/parser completo de `rebuildDeck` e a persistência pós-apply com validação (`persistDeckCardsPayloadWithValidation`)
- `deck_provider.dart` caiu para `1011` linhas, deixando o provider mais perto de orquestração pura no fluxo de IA e persistência final de deck
- `deck_provider_support.dart` passou a encapsular tambem o polling de jobs assíncronos do optimize (`pollOptimizeJobRequest`)
- `deck_provider.dart` caiu para `987` linhas, saindo da faixa de mil linhas e deixando o provider concentrado quase só em orquestração, estado e mutações residuais
- `deck_provider_support.dart` passou a encapsular tambem `addCardsBulkRequest`, reduzindo mais um wrapper de mutação simples
- `deck_provider.dart` caiu para `976` linhas, consolidando o recorte estrutural do app core e deixando o restante do arquivo em estado residual
- `deck_provider.dart` caiu para `966` linhas, deixando o provider abaixo da faixa crítica e mais próximo de orquestração pura
- `deck_provider.dart` caiu para `908` linhas, com o miolo nomeado de `applyOptimization` extraído para `buildNamedOptimizationPayload`
- `deck_provider.dart` caiu para `899` linhas, consolidando helpers privados de refresh/carga (`_refreshDeckDetailsAfterMutation`, `_ensureDeckLoadedForMutation`) e removendo a duplicacao residual entre mutacoes simples e `applyOptimizationWithIds`
- `deck_provider_support.dart` passou a encapsular tambem a mutacao pura de delete (`applyDeckDeletionToState`) e wrappers seguros de resultado (`runConnectionSafeMapRequest`, `buildExportConnectionFailureResult`)
- `deck_provider_support.dart` passou a encapsular tambem a hidratação da lista e do enrichment de `color_identity` (`buildDeckListHydrationResult`, `applyDeckColorIdentityEnrichment`)
- `deck_provider_test.dart` ganhou cobertura direta para `copyPublicDeck`, e `deck_provider_support_test.dart` ganhou cobertura dedicada para o recorte de delete e falhas de conexão
- `deck_provider_support_test.dart` agora também cobre diretamente o helper `buildNamedOptimizationPayload`
- `deck_provider_support_test.dart` agora também cobre diretamente a hidratação da lista e a aplicação de enrichment de `color_identity`
- a malha focada do app core foi revalidada em conjunto (`deck_provider_support_test`, `deck_provider_test`, `deck_details_screen_smoke_test`, `api_client_request_id_test`) e seguiu verde depois do recorte final do provider
- a `DeckDetailsOverviewTab` agora trata deck recém-criado vazio como estado de onboarding, não de erro: sem chip `Inválido`, sem diagnóstico/painéis vermelhos e sem descrição/estratégia antes da primeira base de cartas
- a `DeckDetailsScreen` deixou de disparar `pricing` e `validate` automáticos quando `totalCards == 0`, evitando ruído visual e requests desnecessários no deck vazio
- a suíte do app ganhou cobertura dedicada para esse estado em `deck_details_overview_tab_test.dart` e `deck_details_screen_smoke_test.dart`
- a `DeckImportScreen` perdeu o hero em gradiente concorrente e passou a usar onboarding mais neutro, com fontes suportadas em pills discretos e contador de lista menos agressivo
- o erro inline da importação foi suavizado: continua semântico, mas agora em superfície elevada com texto primário/secundário, sem bloco vermelho dominante antes de qualquer revisão manual
- `deck_import_screen_test.dart` passou a cobrir o estado inicial mais calmo e o erro inline revisado
- a `HomeScreen` perdeu a competição de seis acentos simultâneos no primeiro viewport: o CTA principal continua dominante, enquanto a grade de ações rápidas foi neutralizada para usar poucos tons e o empty state virou apoio, não um segundo hero
- `home_screen_test.dart` passou a cobrir a nova pilha de CTA e o empty state neutro da home
- `login_screen.dart`, `register_screen.dart` e `splash_screen.dart` foram suavizadas para manter o branding com menos glow/camadas simultâneas, concentrando o peso visual no CTA principal e não mais em logo+título+card ao mesmo tempo
- `auth_screens_test.dart` passou a cobrir o shell visual novo de login e registro
- `scanned_card_preview.dart` passou a usar badges mais neutras e um estado de `CardNotFoundWidget` menos agressivo, reduzindo a concorrência entre confiança, condição, foil e erro
- `scanned_card_preview_test.dart` passou a cobrir o preview principal e o estado de carta não encontrada
- `deck_card.dart` agora usa a arte do comandante como assinatura visual sutil na lista de decks, com overlay escuro controlado e linha secundária `Comandante: ...`, sem quebrar a leitura nem o teste de overflow
- `deck_card_test.dart` foi adicionado para cobrir explicitamente esse estado com comandante, e `deck_card_overflow_test.dart` continuou verde com o novo fundo
- a aba `Cartas` de `deck_details_screen.dart` agora inclui uma seção `Comandante` no topo quando o deck possui commander, em vez de renderizar apenas `mainBoard`
- `deck_details_screen_smoke_test.dart` passou a cobrir explicitamente a presença do comandante na tab `Cartas`
- `deck_details_overview_tab.dart` ganhou hero com painel translúcido de leitura sobre a arte do comandante, resumo rápido (`cartas • bracket • arquétipo`) e ações rápidas (`Abrir cartas`, `Abrir análise`, `Otimizar`)
- os textos secundários da `Visão Geral` ficaram menos apagados e a tela passou a ficar mais acionável sem perder o background do comandante
- `deck_details_overview_tab_test.dart` foi ampliado para cobrir as ações rápidas e o resumo do hero
- `deck_analysis_tab.dart` foi reorganizada para leitura executiva: barra de ação clara (`Gerar/Atualizar análise`), seção de sinergia em card próprio, insights de fortes/fracos em blocos separados e matemática (`Curva de mana` / `Distribuição de cores`) em seções mais legíveis
- `deck_analysis_tab_test.dart` foi adicionado para cobrir os estados `Leitura pronta` e `Leitura pendente`
- primeiro corte formal da `Wave 1` da sprint de produto/UX foi executado em `deck_details_overview_tab.dart`: o chip `Inválido/Válido` saiu do hero e foi movido para o `DeckProgressIndicator`, reduzindo concorrência visual no primeiro viewport
- `deck_progress_indicator.dart` agora aceita badge semântico opcional, permitindo manter informação de validação sem poluir o topo do hero
- segundo corte formal da `Wave 1` reorganizou a ordem da `Visão Geral` em `deck_details_overview_tab.dart`: `Estratégia` e `Descrição` subiram para antes de `Diagnóstico`, `Mão inicial` e `Pricing`, deixando a tela mais editorial e orientada a decisão
- `deck_details_overview_tab_test.dart` passou a validar hierarquia visual mínima entre `Selecionar comandante`, `Estratégia` e `Descrição`, para evitar regressão da composição do primeiro scroll
- terceiro corte formal da `Wave 1` rebaixou o `Pricing` para o fim da `Visão Geral` em `deck_details_overview_tab.dart`, tratando custo como informação complementar e não mais como bloco do primeiro scroll
- `deck_details_overview_tab_test.dart` passou a garantir também que `Custo` fique abaixo de `Descrição`, protegendo essa hierarquia de produto contra regressão
- quarto corte formal da `Wave 1` subiu o bloco `Comandante` para junto de `Estratégia` em `deck_details_overview_tab.dart`, deixando identidade concreta e plano do deck lado a lado na leitura principal
- `deck_details_overview_tab_test.dart` passou a validar a ordem entre `Estratégia`, `Comandante` e `Descrição` em decks com comandante
- quinto corte formal da `Wave 1` removeu as ações redundantes `Abrir cartas` e `Abrir análise` do topo da `Visão Geral`; a tela agora usa o `TabBar` como navegação e mantém só `Otimizar deck` como CTA dominante
- `deck_details_overview_tab_test.dart` passou a validar a ausência desses CTAs redundantes e a presença do CTA único `Otimizar deck`
- sexto corte formal da `Wave 1` refinou o acabamento visual da `Visão Geral`: hero com tipografia mais forte e thumb menos invasiva, CTA `Otimizar deck` mais leve, `DeckProgressIndicator` menos técnico e bloco `Comandante` com melhor proporção visual
- sétimo corte formal da `Wave 1` alinhou `Estratégia` e `Descrição` à mesma família visual em `deck_details_overview_tab.dart`, com superfícies consistentes e subtítulos que explicam melhor a utilidade de cada seção
- oitavo corte formal da `Wave 1` redesenhou `deck_diagnostic_panel.dart` para uma leitura mais executiva: cabeçalho responsivo, selo-resumo, cards de métrica menos técnicos e insights em superfícies coerentes com a `Visão Geral`
- primeiro corte formal da revisão da `deck_details_screen.dart` fora da `Visão Geral` entrou na tab `Cartas`: títulos de seção com badge de contagem, tiles de carta com menos ruído, quantidade/set/condição como metadados secundários e estado `Inválida` integrado ao card
- `deck_details_screen_smoke_test.dart` foi alinhado ao novo cabeçalho da seção `Comandante` e continuou verde com a smoke completa da tela
- segundo corte formal da revisão da `deck_details_screen.dart` na tab `Cartas` removeu o bloco introdutório redundante e passou a diferenciar o comandante no próprio tile, com assinatura visual sutil (borda/fundo/ícone), reduzindo camadas desnecessárias sem perder semântica
- terceiro corte formal da revisão da `deck_details_screen.dart` na tab `Cartas` simplificou os cabeçalhos de seção para linhas editoriais sem caixa, reforçando o tom minimalista e deixando mais peso visual nas cartas do que nos contêineres
- primeiro corte formal da revisão de `deck_analysis_tab.dart` suavizou a sensação de dashboard: barra de ação mais integrada, `SectionCard`s menos pesados, insights menos gritados e score de sinergia sem aparência de `card dentro de card`
- segundo corte formal da revisão de `deck_analysis_tab.dart` consolidou `Curva de mana` e `Distribuição de cores` em uma única seção `Base de mana`, reduzindo competição entre painéis de mesmo nível e deixando a leitura mais editorial
- terceiro corte formal da revisão de `deck_analysis_tab.dart` reduziu o peso visual da legenda da distribuição de cores, deixando o gráfico como protagonista e a legenda como apoio discreto
- primeiro corte formal da revisão de `community_screen.dart` reduziu saturação visual fora do core de decks: filtros mais contidos, chips de formato e score menos berrantes, links/avatares/metadados mais neutros nos cards da comunidade
- segundo corte formal da revisão de `community_screen.dart` suavizou a aba `Cotações`: tabs menos douradas, badge de contagem mais neutra e variação de preço concentrada no selo de mudança, em vez de tingir múltiplos pontos do card ao mesmo tempo
- primeiro corte formal da revisão de `life_counter_screen.dart` reduziu saturação no hub central e nos badges auxiliares, para que o foco volte aos totais de vida e não ao ornamento cromático da mesa
- primeira entrega funcional prioritária do `life_counter_screen.dart` entrou em `Ferramentas de Mesa`: `Roll-off` por jogador, com um `D20` por player, destaque visual para o maior resultado, detecção de empate e definição automática do `1º jogador` quando houver vencedor único
- `life_counter_screen_test.dart` foi ampliado para cobrir o fluxo do `Roll-off`, garantindo a renderização de um resultado por jogador dentro da sheet de ferramentas
- o hub expandido `Mesa Commander` agora concentra mais utilidades de uso recorrente: `D20`, `Moeda` e `1º jogador` passaram a existir direto no hub, e o último resultado da mesa é exibido ali mesmo
- `life_counter_screen_test.dart` também passou a cobrir o uso direto do `D20` no hub, reforçando a direção de produto de usar o máximo possível sem abrir a sheet de `Tools`
- o núcleo da vida em cada `PlayerPanel` agora abre um mini hub oculto contextual do jogador: toque no número revela atalhos locais (`D20` individual e `Morto/Reviver`) sem abrir modal
- `life_counter_screen_test.dart` passou a cobrir também esse gesto no bloco da vida, garantindo que os atalhos do jogador apareçam e que `Morto` zere a vida imediatamente
- o `D20` individual do `PlayerPanel` agora deixa um rastro visual útil de mesa: cada jogador mantém no próprio card um badge com o último resultado (`D20 N`), em vez de depender apenas do texto do evento global
- `life_counter_screen_test.dart` também passou a validar esse badge no card do jogador após o uso do atalho local
- a comparação inicial com o app benchmark analisado em `dddddd/` foi consolidada em `docs/SPRINT_LIFE_COUNTER_TABLETOP_2026-03-25.md`, mas essa leitura foi superada na mesma data
- a direcao ativa do `life counter` agora esta formalizada em `docs/SPRINT_LIFE_COUNTER_BENCHMARK_CLONE_2026-03-25.md`: o objetivo deixou de ser "superar sem copiar" e passou a ser `clonar o benchmark o mais fielmente possivel e so depois customizar`
- a pasta `dddddd/` passou a ser tratada como benchmark ampliado, com `10` capturas usadas como fonte de verdade para layout, hierarquia, hub central, rail inferior, overlays e estados especiais
- a mesma sprint do clone passou a incorporar tambem motion/feedback de evento; foi decidido explicitamente nao abrir uma sprint separada de animacao para o `life counter`
- veredito operacional atual da frente: a nossa logica de jogo ja e suficiente para sustentar o clone; o gargalo agora e de shell visual/interacional da mesa, nao de regra de negocio
- a `Wave 1` do clone do `life counter` ja foi iniciada: a mesa perdeu o gradiente/backdrop autoral, adotou base `black-first`, quadrantes mais `full-bleed`, paleta do benchmark e um primeiro corte de hub central mais proximo da referencia
- a mesma frente ja recebeu o segundo corte estrutural: o hub central virou menu radial/petal, `PLAYERS` ganhou entrada dedicada e a barra inferior de mesa (`DICE`, `HISTORY`, `CARD SEARCH`) entrou na shell principal
- a mesma frente recebeu o terceiro corte estrutural: `SETTINGS` e `TABLE TOOLS` deixaram de abrir como `sheet` generica e passaram a usar overlays centrados na propria mesa, na mesma familia visual do clone; `HISTORY` e `CARD SEARCH` foram alinhados a essa shell
- `PLAYERS` tambem foi trazido para a mesma familia de overlay clone, removendo a ultima divergencia grande entre os overlays centrais da mesa e deixando `DICE`/`SET LIFE` como os proximos gaps dessa frente
- `DICE` e `SET LIFE` deixaram de ser gaps abertos nesta rodada: o rail agora abre um overlay dedicado `DICE`, e o toque no numero central do jogador abre um keypad `SET LIFE`; os atalhos locais do jogador foram preservados como gesto secundario (`long press`) no life core
- pendencia residual formal da frente: o `life counter` ja esta muito melhor em shell e interacao, mas ainda nao atingiu o benchmark em motion e presenca de evento; isso agora faz parte da mesma sprint ativa
- a `Wave 9` da mesma sprint foi iniciada nesta rodada: o `PlayerPanel` ganhou transicao animada de estado e o `High Roll` passou a ter takeover mais presente no proprio painel, com glow/rampa visual acima do estado anterior puramente funcional
- o segundo corte da `Wave 9` tambem ja entrou: os overlays centrais da mesa agora usam o mesmo motion compartilhado (`fade + scale + slide`), reforcando a sensacao de surgir da mesa em vez de trocar de tela
- a `Wave 5` tambem saiu do estado conceitual e entrou no codigo: `KO'D!`, `COMMANDER DOWN.` e poison lethal (`TOXIC OUT.`) agora usam takeover real de painel em vez de badge lateral
- o recorte novo do clone empurrou tambem `High Roll` e `D20` para takeover real do painel: o numero deixou de viver como badge e passou a dominar o quadrante do jogador como estado temporario de mesa, com fundo comemorativo para vencedor e supressao dos badges/controles secundarios durante o evento
- o `SET LIFE` tambem foi trazido mais para o benchmark: deixou de usar frame/modal em caixa e agora abre como keypad flutuante sobre a mesa, com numero branco grande, botoes circulares e acao `CANCEL / SET LIFE` no rodape
- o `SETTINGS` tambem deixou de parecer configuracao genérica: `PLAYERS` saiu para overlay proprio, os presets de vida foram separados em `MULTI-PLAYER` e `TWO-PLAYER`, e entraram as secoes cruas `GAME MODES` / `GAMEPLAY` no mesmo tom da captura de referencia
- o frame compartilhado dos overlays de mesa tambem foi simplificado nesta rodada: menos caixa central com borda e mais conteudo flutuando sobre a mesa, aproximando `DICE`, `HISTORY`, `CARD SEARCH`, `PLAYERS` e `SETTINGS` do comportamento visual cru do benchmark
- o `DICE` tambem foi endurecido na mesma direcao: saiu do grid de botoes com cara de utilitario de app e foi para lista vertical crua, com borda branca, `HIGH ROLL` no mesmo peso estrutural e ultimo evento sem card ornamental
- a malha focada da frente foi revalidada apos esse primeiro recorte de shell:
  - `flutter analyze lib/features/home/life_counter_screen.dart test/features/home/life_counter_screen_test.dart`
  - `flutter test test/features/home/life_counter_screen_test.dart`
  - ambos verdes em `2026-03-25`
- primeira entrega oficial da Fase 1 da sprint de mesa foi concluída: `poison inline` entrou no mini hub do núcleo da vida, com `Poison +` e `Poison -` sem depender da sheet de contadores
- `life_counter_screen_test.dart` passou a cobrir também o ajuste inline de poison e a renderização do badge local de veneno no card do jogador
- segunda entrega oficial da Fase 1 da sprint de mesa foi concluída: `commander tax inline` entrou no mesmo mini hub do núcleo da vida, com `Tax +` e `Tax -` sem depender da sheet
- `life_counter_screen_test.dart` passou a cobrir também o badge local `Tax +N` após uso do atalho inline
- terceira entrega oficial da Fase 1 da sprint de mesa foi concluída: `Morto/Reviver` ganhou estado visual forte no card do jogador, com overlay explícito `MORTO` e desaturação parcial do painel
- `life_counter_screen_test.dart` passou a validar também a presença do estado visual `MORTO` após o atalho local zerar a vida
- a Fase 2 da sprint de mesa foi iniciada e já entrou no estado útil de `High Roll`: o `Mesa Commander` agora tem CTA explícito de `High Roll`, a rolagem distribui um `HIGH N` por jogador no próprio card e o vencedor/empate recebe status visual local
- quando o `High Roll` termina com vencedor único, o `1º jogador` é derivado automaticamente do resultado e o evento fica resumido também no hub central
- `life_counter_screen_test.dart` passou a cobrir o `High Roll` direto do hub e a presença dos badges/resultados locais por jogador
- a Fase 2 foi concluída nesta rodada: quando houver empate no `High Roll`, o hub e a sheet passam a oferecer `Desempatar`, rerrolando apenas os jogadores empatados e mantendo o fluxo claramente legível no próprio card e na `Tools` sheet
- o resumo local da sheet também diferencia `High Roll` inicial de `Desempate do High Roll`, e a suíte do `life_counter` ganhou teste determinístico para esse tie-break
- a Fase 3 foi iniciada: `commander damage` agora pode ser aberto direto do mini hub do núcleo da vida via atalho `Cmd dmg`, sem depender de navegar pela sheet completa de contadores
- esse fluxo novo abre uma sheet rápida e dedicada por jogador, focada só em dano por fonte, e o badge total de `commander damage` no card reage imediatamente às alterações
- `Sentry` backend foi ligado em `server/lib/observability.dart` e no middleware global, com propagação de `x-request-id` via `server/lib/request_trace.dart`
- `Sentry` app foi ligado em `app/lib/core/observability/app_observability.dart`, com captura global de erros, observer de rota e `x-request-id` em `app/lib/core/api/api_client.dart`
- `server/.env.example` foi atualizado com as chaves mínimas de observabilidade e o setup ficou registrado em `docs/SENTRY_SETUP_MTGIA_2026-03-24.md`
- o smoke real do backend foi promovido para `./scripts/validate_sentry_backend_ingestion.sh`, confirmando ingestão real por `event_id` no Sentry
- o smoke real do backend foi revalidado novamente nesta rodada, com novo `event_id` confirmado (`70168f941de24cf4923eb87bb6d38a5d`)
- `server/.env.example` passou a formalizar também os placeholders operacionais de EasyPanel e Sentry (`SENTRY_AUTH_TOKEN`, slugs de projeto e `EASYPANEL_*`)
- o runbook operacional de deploy foi formalizado em `docs/EASYPANEL_RUNBOOK_MTGIA_2026-03-24.md`
- o ambiente publicado respondeu `200` em `GET /health` e `GET /ready` em `2026-03-24`, com `x-request-id` gerado pelo backend e eco de um `x-request-id` manual no response (`manual-req-20260324`)
- o smoke operacional repetível de readiness/request-id foi formalizado em `scripts/validate_request_id_ready.sh`, com fallback explícito de `API_BASE_URL`/`PUBLIC_API_BASE_URL`/`EASYPANEL_DOMAIN`
- o smoke publicado de readiness/request-id foi validado com sucesso nesta rodada (`READY_VALIDATION_OK=1`), confirmando `200` em `/health`, `/health/ready` e `/ready` com eco do mesmo `x-request-id`
- a validação real de ingestão do app segue pendente; o smoke mobile e o script já existem, mas as tentativas em macOS local e no emulador Android (`emulator-5554`) ficaram presas no ciclo nativo de compilação e não devolveram `event_id`
- o retry desta rodada em `macos` também ficou preso por mais de `60s` na fase de build nativo, apenas emitindo warnings do SDK Swift do `Sentry`, sem chegar ao teste nem gerar `event_id`
- `validate_sentry_mobile_local.sh` agora fecha com timeout configurável (`MOBILE_SENTRY_BUILD_TIMEOUT_SECONDS`, default `120`) e marca explicitamente `SENTRY_MOBILE_TOOLCHAIN_BLOCKED=1` quando o bloqueio for de toolchain/build
- a classificação foi revalidada nesta rodada: em `macos`, com timeout reduzido para `20s`, o smoke encerrou com `exit 124` e `SENTRY_MOBILE_TOOLCHAIN_BLOCKED=1`, confirmando que a pendência atual é de execução/toolchain e não de integração de código
- o smoke Android avançou um passo: a falha de Kotlin incompatível foi corrigida ao atualizar `app/android/settings.gradle.kts` para `org.jetbrains.kotlin.android` `2.2.0`
- mesmo assim, o retry real em `emulator-5554` não concluiu dentro de `240s`/`300s`, então a pendência do app segue operacional, agora concentrada em tempo/execução do target mobile e não mais em quebra imediata de build por versão de Kotlin
- no iOS, o bloqueio inicial de CocoaPods foi resolvido nesta rodada:
  - `cocoapods 1.12.1` instalado em escopo de usuário
  - `pod install` executado com sucesso em `app/ios`
  - workaround de `DT_TOOLCHAIN_DIR -> TOOLCHAIN_DIR` aplicado no `Podfile`
- o `flutter run` em `Rafa` já compilou e instalou o app; o novo bloqueio desse trilho passou a ser `service protocol connection reset by peer` no attach do Flutter sobre o device wireless, não mais erro de CocoaPods/build de pods
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
   - apenas limpeza residual de estado compartilhado (`fetchMissingColorIdentities`, `fetchDecks/fetchDeckDetails` e mutacoes finas)
3. ao fechar esse recorte do app core, retomar os bloqueadores operacionais restantes da Sprint 2:
   - validar ingestao real do app no Sentry
   - fechar a correlacao ponta a ponta de `x-request-id` entre app e backend publicado
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

## Aditivo - Estado Atual Em 2026-03-25

Estado consolidado:

- o core de `optimize/rebuild` ja saiu da zona critica
- o corpus recorrente segue como gate estavel
- `deck_details_screen.dart` ficou em `1445` linhas e perdeu os blocos mais pesados de UI/efeitos
- `deck_provider.dart` ficou em `899` linhas e entrou em fase residual
- `deck_provider_support.dart` deixou de ser um arquivo unico de quase `1900` linhas e virou barrel com suporte por dominio:
  - `deck_provider_support_common.dart`
  - `deck_provider_support_fetch.dart`
  - `deck_provider_support_mutation.dart`
  - `deck_provider_support_ai.dart`
  - `deck_provider_support_import.dart`
  - `deck_provider_support_generation.dart`

Validacao mais recente:

- `flutter analyze` verde para provider/support/tests focados
- `flutter test` verde para:
  - `test/features/decks/providers/deck_provider_support_test.dart`
  - `test/features/decks/providers/deck_provider_test.dart`
  - `test/features/decks/screens/deck_details_screen_smoke_test.dart`
  - `test/core/api/api_client_request_id_test.dart`

Leitura executiva:

- o gargalo principal deixou de ser o app core estrutural
- a pendencia dominante voltou a ser operacional:
  - validacao real do `Sentry` mobile
  - correlacao final ponta a ponta de observabilidade em alvo mobile real

Auditoria visual complementar:

- a auditoria completa de ruído visual e uso de cores foi consolidada em `docs/AUDITORIA_RUIDO_VISUAL_CORES_2026-03-25.md`
- a auditoria foi promovida a sprint formal em `docs/SPRINT_AUDITORIA_PRODUTO_UX_2026-03-25.md`, com waves, checklist por tela e critérios explícitos de aceite visual, de produto e técnico
- conclusao principal: a paleta base é boa, mas algumas telas ainda gastam cor demais
- o primeiro alvo recomendado de limpeza visual continua sendo o core de deck, especialmente o estado vazio/inicial de `deck_details`
- regra oficial nova: tela deve ser aceita como composição de produto em viewport real, não apenas como soma de componentes corretos em isolamento
