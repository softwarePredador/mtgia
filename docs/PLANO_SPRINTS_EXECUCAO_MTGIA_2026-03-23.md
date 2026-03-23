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

Subfila tecnica atual da Sprint 1:

1. reduzir responsabilidade concentrada em `deck_provider.dart` e `deck_details_screen.dart`

Critério de saida:

- suite do core verde e estavel
- corpus recorrente de release funcionando
- smoke do app definido e repetivel
- sem regressao de contrato no optimize/rebuild

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
