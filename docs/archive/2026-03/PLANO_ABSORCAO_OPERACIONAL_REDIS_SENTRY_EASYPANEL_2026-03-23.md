# Plano de Absorcao Operacional - Redis, Sentry, EasyPanel e Performance

> Documento complementar.
> Nao muda a prioridade atual do core de decks.
> Serve para capturar o que o projeto `carMatch` ja validou operacionalmente e o que faz sentido absorver no `mtgia` quando esta frente entrar na fila.

## Objetivo

Mapear, com base no `carMatch`, quais blocos operacionais ja estao maduros em:

- Redis
- Sentry
- EasyPanel
- filas/worker
- readiness
- rate limit
- performance/load test

e traduzir isso para uma sequencia aplicavel ao `mtgia`, sem copiar cegamente stack, segredos ou contratos de outro produto.

## Fontes usadas no `carMatch`

Documentos principais lidos:

- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/docs/CONTEXTO_PRODUTO_ATUAL.md`
- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/docs/MAPA_TECNOLOGIAS_E_ESCALA_2026-03-22.md`
- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/docs/PLANO_ESCALA_1000_USUARIOS_2026-03-22.md`
- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/docs/OBSERVABILIDADE_FASE_1_SENTRY_2026-03-22.md`
- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/docs/SENTRY_SETUP_OPERACIONAL_2026-03-22.md`
- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/docs/REVISAO_SENTRY_BACKEND_2026-03-23.md`
- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/docs/EASYPANEL_DEPLOY.md`
- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/docs/EASYPANEL_API_RUNBOOK_2026-03-22.md`
- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/docs/ARQUITETURA_FILAS_PROCESSAMENTO_2026-03-22.md`

Arquivos de configuracao consultados apenas para mapa de chaves, sem expor valores:

- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/backend/.env`
- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/backend/.env.example`

## O que o `carMatch` ja provou em operacao

### 1. Sentry operacional de verdade

No `carMatch`, a observabilidade nao ficou so no codigo:

- backend e mobile estao integrados ao Sentry
- os projetos reais no Sentry existem e foram validados
- houve release publicada
- existiu smoke automatizado de ingestao
- existiu rotina de triagem e resolucao de issues
- o backend passou a carregar `requestId` e logs estruturados

Leitura pratica:

- o valor nao esta so em "instalar pacote"
- o valor esta em fechar o ciclo:
  - inicializar
  - subir env real
  - validar ingestao
  - correlacionar com logs
  - resolver ruido operacional

### 2. Redis como peca operacional, nao so cache opcional

No `carMatch`, Redis sustenta:

- cache e presenca
- adapter de Socket.IO
- BullMQ
- heartbeat de worker
- readiness real

Leitura pratica:

- Redis deixou de ser "melhoria futura" e virou dependencia operacional do ambiente publicado

### 3. Worker dedicado e fila duravel

No `carMatch`, BullMQ + Redis foi colocado com:

- fila `photo-moderation`
- worker separado da API web
- retry com backoff
- `jobId` idempotente
- fallback inline quando a fila nao esta habilitada
- `GET /ready` verificando heartbeat do worker

Leitura pratica:

- esse desenho e forte porque introduz robustez sem quebrar rollout parcial

### 4. EasyPanel tratado como plataforma operavel

No `carMatch`, EasyPanel nao ficou como "painel manual":

- envs criticos foram explicitados
- deploy e worker tiveram runbook
- existe operacao por API `tRPC`
- a ordem de rollout foi documentada
- o readiness passou a ser smoke oficial do ambiente

Leitura pratica:

- a maturidade veio do runbook repetivel, nao do painel em si

### 5. Escala/performance com criterio minimo

No `carMatch`, a camada operacional foi complementada por:

- rate limit em rotas sensiveis
- `k6` versionado
- readiness real
- checklist de thresholds e smoke publicado

Leitura pratica:

- isso da uma base objetiva para operar antes de qualquer crescimento

## O que o `mtgia` ja tem hoje

### Ja existe

- `GET /health` basico em `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/routes/health/index.dart`
- dashboard operacional simples em `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/routes/health/dashboard/index.dart`
- telemetry do fallback de optimize em `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/routes/ai/optimize/telemetry/index.dart`
- cache em memoria para endpoints publicos em `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/lib/endpoint_cache.dart`
- rate limit local e distribuido por Postgres em:
  - `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/lib/rate_limit_middleware.dart`
  - `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/lib/distributed_rate_limiter.dart`
- performance no app via Firebase Performance em:
  - `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app/lib/core/services/performance_service.dart`
  - `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app/lib/core/api/api_client.dart`
- capacidade documentada em `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/doc/CAPACITY_PLAN_10K_MAU.md`

### Ainda nao existe

- Sentry no backend
- Sentry no app
- correlacao por `x-request-id` ponta a ponta
- readiness real com DB + Redis + worker + dependencias
- Redis operacional no backend
- fila/worker dedicada
- runbook de EasyPanel para o `mtgia`
- envs operacionais para Sentry/Redis/worker em `server/.env.example`
- smoke operacional publicado comparavel ao `carMatch`

## Delta real entre os projetos

### Observabilidade

`carMatch`:

- Sentry backend + mobile
- logs estruturados
- request correlation
- runbook de triagem

`mtgia`:

- telemetry de produto e performance local
- sem camada centralizada de erro

Conclusao:

- o `mtgia` tem sinais de performance e produto
- mas ainda nao tem observabilidade operacional de erro

### Redis e multi-instancia

`carMatch`:

- Redis e parte estrutural do runtime

`mtgia`:

- rate limit distribuido usa Postgres
- cache ainda e in-memory
- plano de capacidade ja reconhece que cache deve migrar para Redis em multi-instancia

Conclusao:

- o `mtgia` ainda esta em modelo single-instance friendly
- o proximo degrau de operacao passa por Redis

### Worker / jobs

`carMatch`:

- worker dedicado
- heartbeat
- readiness conectado a fila

`mtgia`:

- jobs importantes ainda estao no processo web ou em scripts
- nao existe camada operacional de worker

Conclusao:

- para o core atual, isso ainda nao e bloqueio imediato
- mas vai virar gargalo quando optimize/rebuild pesado precisar sair do request principal

### EasyPanel

`carMatch`:

- envs claros
- worker separado
- deploy via painel e via API
- runbook repetivel

`mtgia`:

- Dockerfile pronto para EasyPanel
- URL publicada ja existe em testes
- nenhuma documentacao madura de operacao remota

Conclusao:

- o `mtgia` esta deployavel
- ainda nao esta operavel no mesmo nivel

## O que deve ser absorvido

### Absorver quase igual

1. Runbook operacional
- envs criticos
- ordem de deploy
- smoke pos-deploy
- criterio de rollback

2. Sentry como rotina
- backend
- app
- release por deploy
- validacao de ingestao
- triagem versionada

3. Readiness real
- nao ficar so em `GET /health`
- expor readiness com checks reais

4. Worker heartbeat
- quando existir fila
- usado dentro do readiness

5. Checklist de hardening do ambiente
- flags de dev/mock desligadas em prod
- envs explicitadas

### Absorver com adaptacao

1. Redis
- no `mtgia`, o primeiro uso deve ser:
  - cache multi-instancia de endpoints quentes
  - rate limit distribuido
  - eventual fila de jobs
- nao precisa copiar o desenho de socket/presenca do `carMatch`

2. Filas
- o primeiro candidato natural no `mtgia` nao e foto/moderacao
- e sim trabalho pesado do fluxo de IA:
  - optimize async
  - rebuild guiado
  - explain/generate com custo alto
  - refresh de `commander_reference_profiles`

3. Load test
- o `mtgia` ja tem base em `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/bin/load_test_core_flow.dart`
- o passo correto e endurecer isso como suite operacional, nao importar `k6` so por copiar

4. Performance app
- o app ja tem Firebase Performance
- antes de adicionar mais stack aqui, vale integrar melhor os traces do fluxo core

### Nao absorver cegamente

1. BullMQ por si so
- o `mtgia` e Dart no backend, nao Node
- a decisao aqui provavelmente vai ser outra tecnologia de fila se for sair de Postgres/in-memory

2. API `tRPC` do EasyPanel
- usar o runbook conceitual, nao assumir que a automacao pronta do `carMatch` serve igual

3. As chaves reais do outro projeto
- usar apenas como referencia de classes de variaveis
- criar DSNs e configuracoes proprias do `mtgia`

## Mapa de chaves operacionais observado

### Chaves relevantes do `carMatch`

No `.env` real/local do outro projeto, as chaves observadas para esta frente foram:

- `REDIS_HOST`
- `REDIS_PORT`
- `REDIS_PASSWORD`
- `SENTRY_AUTH_TOKEN`
- `SENTRY_ORG_SLUG`
- `SENTRY_TEAM_SLUG`
- `SENTRY_BACKEND_PROJECT_SLUG`
- `SENTRY_MOBILE_PROJECT_SLUG`
- `SENTRY_DSN`
- `SENTRY_MOBILE_DSN`
- `SENTRY_ENVIRONMENT`
- `SENTRY_RELEASE`
- `SENTRY_TRACES_SAMPLE_RATE`
- `SENTRY_ENABLE_LOGS`
- `EASYPANEL_BASE_URL`
- `EASYPANEL_USER_EMAIL`
- `EASYPANEL_API_TOKEN`
- `EASYPANEL_AUTH_HEADER`
- `EASYPANEL_AUTH_SCHEME`
- `EASYPANEL_TRPC_PROJECTS_LIST`

No `.env.example` do `carMatch`, tambem apareceram:

- `BULLMQ_ENABLED`
- `BULLMQ_PREFIX`
- `BULLMQ_PHOTO_MODERATION_CONCURRENCY`
- `WORKER_HEARTBEAT_INTERVAL_MS`
- `WORKER_HEARTBEAT_TTL_SECONDS`
- limites de rate limit por rota

### Chaves atuais do `mtgia`

Hoje, no `mtgia`, o `.env.example` relevante para esta frente esta muito mais enxuto:

- `OPENAI_*`
- `RATE_LIMIT_DISTRIBUTED`

Leitura:

- falta formalizar a camada operacional
- ainda nao existe contrato minimo de env para observabilidade, Redis e deploy publicado

## Sequencia recomendada para o `mtgia`

Esta frente **nao vence** a prioridade atual de modularizar e endurecer o core de decks.

Quando entrar na fila, a ordem recomendada e:

### Fase 1 - Observabilidade minima

1. backend:
- adicionar Sentry no servidor Dart
- capturar `5xx`, `unhandledRejection` equivalente e excecoes de rota
- propagar `requestId`

2. app:
- adicionar Sentry Flutter
- manter Firebase Performance como complemento, nao substituto

3. correlacao:
- enviar `x-request-id` do app
- devolver `x-request-id` no backend
- logar isso no servidor

4. documentacao:
- runbook de setup
- rotina de triagem

### Fase 2 - Readiness e operacao remota

1. criar `GET /ready`
- DB
- capacidade de pool
- tabela critica disponivel
- opcionalmente cache/Redis quando existir

2. criar runbook de EasyPanel do `mtgia`
- envs minimas
- porta
- smoke pos-deploy
- rollback

3. endurecer `server/.env.example`
- sem segredos
- com placeholders reais de operacao

### Fase 3 - Redis

1. introduzir Redis como opcional
2. mover cache em memoria para Redis em ambiente multi-instancia
3. decidir se rate limit distribuido continua em Postgres ou migra

### Fase 4 - Jobs/worker

1. selecionar tecnologia compativel com Dart/infra atual
2. tirar trabalho pesado de IA do request principal quando necessario
3. adicionar heartbeat e readiness do worker

### Fase 5 - Carga e thresholds operacionais

1. promover `server/bin/load_test_core_flow.dart` a suite oficial
2. documentar thresholds
3. rodar carga em staging/publicado

## Ordem recomendada em relacao ao roadmap atual

Enquanto o contexto oficial continuar em:

- modularizar `server/routes/ai/optimize/index.dart`
- gate recorrente de release
- ampliar casos dirigidos do corpus
- smoke do app `deck details -> optimize -> apply -> validate`

esta frente deve ficar como **paralela documentada**, nao como prioridade dominante.

Ou seja:

1. primeiro fechar o endurecimento do core de decks
2. depois entrar em observabilidade e readiness
3. so depois Redis/fila

## Critério de sucesso quando esta frente entrar

Para considerar a absorcao bem feita, o `mtgia` deve terminar com:

1. `GET /health` e `GET /ready` distintos
2. Sentry backend e app operacionais com release/versionamento
3. `x-request-id` ponta a ponta
4. env example formalizado para operacao
5. runbook de EasyPanel do `mtgia`
6. pelo menos um smoke de observabilidade e um smoke de deploy
7. plano claro de migracao de cache in-memory para Redis em multi-instancia

## Decisao final desta rodada

O `carMatch` ja validou um pacote operacional maduro que **vale absorver conceitualmente**.

A traducao correta para o `mtgia` e:

- copiar o metodo
- copiar a disciplina documental
- copiar o ciclo de validacao
- **nao** copiar segredos
- **nao** copiar stack Node-especifica cegamente
- **nao** desviar a prioridade atual do core de decks
