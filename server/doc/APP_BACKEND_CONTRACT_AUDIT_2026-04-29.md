# App Backend Contract Audit - 2026-04-29

## Atualizacao - Profile e Community Social runtime - 2026-04-30

Backend real em `http://127.0.0.1:8082`, iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, runtime `com.apple.CoreSimulator.SimRuntime.iOS-17-4`. Contratos JSON/status codes/autenticacao/permissoes preservados para Profile e Community Social.

### Contratos auditados e resultado

| Endpoint | Status |
| --- | --- |
| `GET/PATCH /users/me` | `PASS`; `GET` agora inclui `location_state`, `location_city`, `trade_notes`, alinhando o reload do Profile com os campos suportados pelo app |
| `GET /community/users/:id` | `PASS`; perfil publico, contadores e estado `is_following` mantidos |
| `GET /community/users` | `PASS`; busca por username/display name com query codificada pelo provider |
| `POST/DELETE /users/:id/follow` | `PASS`; follow/unfollow preservam `401/404` e resposta social existente |
| `GET /users/:id/followers` | `PASS`; paginacao e erro classificados no provider |
| `GET /users/:id/following` | `PASS`; paginacao e erro classificados no provider |
| `GET /community/decks` | `PASS`; lista publica preservada e contrato validado no provider |
| `GET /community/decks/following` | `PASS`; feed de seguidos preservado |
| `GET /community/decks/:id` | `PASS`; detalhe publico preservado |

### Observabilidade e tratamento de erro

- Middleware raiz passou a classificar `/users` e `/community` em `[http_observability]` para slow request e 4xx/5xx, com Sentry/log sanitizados.
- Rotas tocadas usam `captureRouteException` em 5xx, sem logar token/email/body sensivel.
- `PATCH /users/me` registra `invalid_payload` sanitizado para JSON invalido, URL de avatar invalida, UF invalida, campos grandes e ausencia de campos.
- Providers de Profile/Community/Social registram eventos sanitizados para 4xx/5xx, timeout/excecao e erro de contrato; nenhum evento inclui token, email completo ou payload sensivel.

### Validacao

| Comando | Resultado |
| --- | --- |
| `cd server && dart analyze routes/users routes/community lib test && dart test -r expanded` | `PASS` |
| `cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live -r expanded` | `PASS` |
| `cd app && flutter analyze lib/features/profile lib/features/community lib/features/auth integration_test --no-version-check && flutter test test/features/profile test/features/community test/features/auth --no-version-check` | `PASS` |
| `cd app && flutter test integration_test/profile_community_runtime_test.dart -d "iPhone 15" ...` | `PASS`: `00:57 +1: All tests passed!` |

Runtime final observou `GET/PATCH /users/me`, `GET /community/users`, `GET /community/users/:id`, follow/unfollow, followers, `GET /community/decks`, `GET /community/decks/following` e `GET /community/decks/:id` retornando `200`. Os 4xx obrigatorios (`401`, `403`, `404`) ficam cobertos pelos testes de provider/live e classificados; nao houve 5xx/timeout no runtime final.

Pendencia backend: latencia de escrita social `POST /users/:id/follow` ficou em `~2841ms` e deve ser candidata a P1 se entrar no criterio de performance; leituras de perfil publico ficam em `~1.7s` por DB remoto. Sem DDL/migration runtime nova.

## Atualizacao - P1 performance PUT /trades/:id/respond - 2026-04-30

Backend real em `http://127.0.0.1:8082`, iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, runtime `com.apple.CoreSimulator.SimRuntime.iOS-17-4`. Contrato JSON/status codes/autenticacao/permissoes preservados para `PUT /trades/:id/respond`.

### Baseline vs depois

Medicao com probe HTTP real e 5 amostras por action contra `TEST_API_BASE_URL=http://127.0.0.1:8082`.

| Endpoint/action | Baseline p50 | Baseline p95 | Baseline p99 | Depois p50 | Depois p95 | Depois p99 | Melhora p95 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `PUT /trades/:id/respond` `accept` | `3099ms` | `3902ms` | `3902ms` | `565ms` | `1394ms` | `1394ms` | `64.3%` |
| `PUT /trades/:id/respond` `decline` | `3018ms` | `3028ms` | `3028ms` | `564ms` | `591ms` | `591ms` | `80.5%` |

### Hipoteses tecnicas investigadas

| Area | Achado |
| --- | --- |
| DB remoto | Latencia por round-trip continuou dominante e estavel; uma query extra custava ~560ms-1200ms no caminho observado. |
| Round-trips transacionais | Confirmado: a rota fazia `UPDATE`, `INSERT history`, busca de nome do responder e `INSERT notifications`/FCM antes de responder. |
| Ownership/receiver | Mantido receiver-only dentro do CTE com `FOR UPDATE`; sem permissao continua `403`. |
| Lock/status transition | `status = pending` e double respond/not pending sao validados no mesmo statement atomico; double respond continua `400` e nao altera estado aceito/recusado. |
| Status history | Preservado no mesmo statement do update, com `old_status='pending'`, novo status e `changed_by`. |
| Notificacoes | `trade_accepted`/`trade_declined` preservadas e deferidas via `NotificationService.createFromActorDeferred`, com log `slow_deferred`/Sentry sanitizado fora do caminho critico. |
| Indices/N+1 | Nenhum DDL novo; acesso por `trade_offers.id` usa PK e a melhoria veio de reduzir viagens e side effects sincronos, nao de indice novo. |
| DDL/runtime work | Nenhum DDL ou migration runtime adicionados. |

### Mudancas de implementacao

- `PUT /trades/:id/respond`: um unico statement CTE faz lock, validacao `not_found`/`forbidden`/`not_pending`, update de `trade_offers` e insert em `trade_status_history`.
- Notificacao de resposta mudou de `NotificationService.create` sincrono para `NotificationService.createFromActorDeferred`, mantendo titulo com nome do responder, tipo `trade_accepted`/`trade_declined`, `reference_id` e logs/Sentry sanitizados.
- Observabilidade de payload invalido adicionada para action invalida: `[social_write] invalid_payload endpoint=PUT /trades/:id/respond`.
- `server/test/social_trading_live_test.dart` agora cobre teto live de regressao (`PUT /trades/:id/respond < 2000ms`), response shape, accept, decline, action invalida `400`, sem token `401`, inexistente `404`, receiver-only `403`, double respond `400` sem corromper estado e notificacoes essenciais.

### Validacao

| Comando | Resultado |
| --- | --- |
| `dart analyze routes/trades routes/notifications lib test && dart test -r expanded` | PASS: `No issues found!`, `00:08 +555: All tests passed!` |
| `TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live -r expanded` | PASS: `02:48 +166 ~3: All tests passed!` |
| `flutter analyze ... && flutter test ...` | PASS app focado |
| `flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" ...` | PASS: `01:39 +2: All tests passed!` |

Runtime UI real confirmou `PUT /trades/:id/respond 200 (590ms)`, `POST /trades 201 (1742ms)` e `PUT /trades/:id/status 200 (602ms, 608ms, 593ms)`.

Pendencia backend: leituras de detalhe/mensagens sociais ainda aparecem em ~1.1s-1.7s no runtime por DB remoto. FCM real segue `not_proven` no simulador.

## Atualizacao - fechamento performance Social Trading P1 - 2026-04-30

Backend real em `http://127.0.0.1:8082`, iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, runtime `com.apple.CoreSimulator.SimRuntime.iOS-17-4`. Contrato JSON/status codes/autenticacao/permissoes preservados para `POST /trades` e `PUT /trades/:id/status`.

### Baseline vs depois

Medição com `OBS_SAMPLE_COUNT=5 TEST_API_BASE_URL=http://127.0.0.1:8082 dart run bin/qa/social_trading_observability_probe.dart`.

| Endpoint | Baseline p50 | Baseline p95 | Baseline p99 | Depois p50 | Depois p95 | Depois p99 | Melhora p95/p99 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `POST /trades` | `3976ms` | `3991ms` | `3991ms` | `1788ms` | `1818ms` | `1818ms` | `54.4%` |
| `PUT /trades/:id/status` | `2782ms` | `2787ms` | `2787ms` | `600ms` | `621ms` | `621ms` | `77.7%` |

### Hipoteses tecnicas investigadas

| Area | Achado |
| --- | --- |
| DB remoto | Latencia por round-trip dominante e muito estavel; cada query adicional custava ~600ms-1200ms no caminho observado. |
| Round-trips transacionais | Confirmado: `POST /trades` fazia validacoes separadas e inserts seriais; `PUT /status` fazia `SELECT FOR UPDATE`, `UPDATE` e `INSERT history` separados. |
| Queries ownership | Mantidas, mas reunidas em validacao batch com contagem por owner/disponibilidade. |
| Status history | Preservado, agora inserido no mesmo statement/CTE do update de status. |
| Notificacoes | Permanecem essenciais e deferidas via `NotificationService.createFromActorDeferred`, com timeout/log/Sentry. Logs `slow_deferred` seguem fora do caminho critico. |
| Locks | `PUT /status` manteve lock atomico via CTE com `FOR UPDATE`, reduzindo tempo de lock e janela transacional. |
| Indices | Indices sociais existentes continuam adequados; a melhoria veio de reduzir viagens ao DB, nao de DDL nova. |
| N+1 | Removido do insert de `trade_items`: JSONB recordset insere todos os itens de offering/requesting em batch. |
| DDL/runtime work | Nenhum DDL novo no caminho critico; nenhuma migration runtime adicionada. |

### Mudancas de implementacao

- `POST /trades`: parse/validacao de itens antes do DB, query batch para receiver/ownership/disponibilidade e CTE unica para `trade_offers`, `trade_items` e `trade_status_history`.
- `PUT /trades/:id/status`: um unico statement com lock, validacao de permissao/transicao, update e history.
- Observabilidade sanitizada mantida para `slow_request`, `client_error`, `invalid_payload`, `impossible_state` e excecoes via middleware/Sentry/logs sem token/email/payload sensivel.
- `server/test/social_trading_live_test.dart` agora verifica teto live de regressao (`POST /trades < 3500ms`, `PUT /status < 2000ms`) e notificacao `trade_shipped`.

### Validacao

| Comando | Resultado |
| --- | --- |
| `dart analyze routes/trades routes/notifications lib test && dart test -r expanded` | PASS: `No issues found!`, `00:05 +555: All tests passed!` |
| `TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live -r expanded` | Primeira rodada: falha nao-social em `ai_generate_create_optimize_flow_test.dart` por 422 nos prompts; rerun imediato PASS: `02:52 +165 ~3: All tests passed!` |
| `flutter analyze ... && flutter test ...` | PASS app focado |
| `flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" ...` | PASS: `01:43 +2: All tests passed!` |

Runtime UI real confirmou `POST /trades 201 (1826ms)` e `PUT /trades/:id/status 200 (636ms, 647ms, 635ms)`.

Pendencia backend: `PUT /trades/:id/respond` ainda ficou lento no runtime (`~3203ms`) e deve receber a mesma consolidacao de round-trips em sprint posterior. FCM real segue `not_proven` no simulador.

## Atualizacao - staging observability Social Trading - 2026-04-30

Validacao executada com backend real em `http://127.0.0.1:8082`, Sentry staging carregado via `.env` local e service account Firebase local presente sem expor segredos. Contrato JSON/status codes preservados.

Resultados:

- `dart run bin/sentry_smoke.dart`: PASS, `SENTRY_SMOKE_EVENT_ID=fa3497bfe71248f99d0217b3ba964816`, `smoke_id:mtgia-smoke-19dde2fade1`.
- `OBS_SAMPLE_COUNT=5 TEST_API_BASE_URL=http://127.0.0.1:8082 dart run bin/qa/social_trading_observability_probe.dart`: PASS.
- Logs backend provaram `[http_observability] classification=slow_request`, `client_error`, `[social_write] invalid_payload` e `[social_notification] slow_deferred`.
- FCM backend carregou `firebase-service-account.json`, mas entrega real nao foi comprovada porque o iPhone 15 Simulator nao gerou APNS/FCM token.

Metricas medidas:

| Endpoint | p50 | p95 | p99 | Status |
| --- | ---: | ---: | ---: | --- |
| `GET /community/marketplace` | `611ms` | `1485ms` | `1485ms` | `200` |
| `POST /trades` | `3979ms` | `4258ms` | `4258ms` | `201` |
| `PUT /trades/:id/status` | `2783ms` | `3299ms` | `3299ms` | `200` |
| `GET /trades` | `630ms` | `1484ms` | `1484ms` | `200` |
| `GET /trades/:id` | `1300ms` | `1346ms` | `1346ms` | `200` |
| `POST /trades/:id/messages` | `1227ms` | `1400ms` | `1400ms` | `201` |
| `POST /conversations/:id/messages` | `1195ms` | `1341ms` | `1341ms` | `201` |

Classificacoes obrigatorias:

| Caso | Evidencia |
| --- | --- |
| Slow request | `POST /trades`, `PUT /trades/:id/status`, mensagens e detalhes geraram `slow_request` |
| 4xx esperado | `GET /trades/00000000-0000-0000-0000-000000000000` retornou `404` e `client_error` |
| Payload invalido | `payment_method=wire` retornou `400` e `[social_write] invalid_payload` |
| Timeout | Probe cliente gerou `OBS_EVENT client_timeout status=triggered timeout_us=1` |
| Erro de contrato | Probe validou keys obrigatorias; `contract_error status=not_triggered` |
| 5xx/excecao controlada | Nao houve harness seguro novo para forcar 5xx sem alterar contrato; cobertura existente permanece via middleware/captureRouteException e Sentry smoke controlado |

Validacao final:

- `dart analyze routes/trades routes/market routes/binder routes/conversations routes/notifications lib test`: sem issues.
- `dart test -r expanded`: `555` testes passaram.
- `TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live -r expanded`: passou.

## Resumo executivo

Auditoria dos contratos backend consumidos pelo app ManaLoom em `2026-04-29`, cruzando providers/telas do app com `server/routes`, validacao automatizada e runtime iPhone 15 com backend real em `http://127.0.0.1:8082`.

O contrato core app/backend esta coerente para auth, decks, cards, sets, import, optimize, validate, binder, community, trades, conversations e notifications. As variantes incrementais de deck cards existem no backend (`bulk`, `set`, `replace`) e retornam `401` quando chamadas sem token, confirmando roteamento e middleware.

Risco provado na auditoria original: `GET /market/movers?limit=5&min_price=1.0` nao retornou dentro do timeout do app (15s) e tambem nao retornou em probe `curl` apos 60s. Isso afetava Home/Market/Community, mas o app capturou o erro sem quebrar o runtime de deck.

Atualizacao pos-correcao em 2026-04-29: o endpoint foi otimizado no backend sem alterar o app nem o contrato JSON atual. O probe frio contra backend real em `8082` retornou `200` em `1.918091s`; o hit quente com cache process-local retornou em `0.005164s`.

## Correcao aplicada em `/market/movers`

### Diagnostico real

- Base real: `price_history` com `2.414.220` linhas, `79` datas e `30.569` cartas por snapshot recente.
- Evidencia original: probe HTTP pendurado por `>60s`.
- Profiling DB antes da correcao:
  - agregacao ampla em `price_history` levou `11.783s`;
  - plano com estatisticas ruins estimava `1` linha para uma data que tinha `30.569` linhas;
  - variante de join/order sem materializacao e limite cedo atingiu `statement_timeout` de `20s`.
- Causa: combinacao de estatisticas defasadas, plano ruim para join/order por variacao, busca de data de comparacao com `EXISTS` sobre multiplas datas e ausencia de cache server-side.

### Mudanca tecnica

- A rota passou a comparar diretamente as duas datas mais recentes, conforme contrato documentado (`date` vs `previous_date`).
- As queries de gainers/losers materializam primeiro os snapshots de hoje/anterior, calculam/ordenam a variacao, aplicam `LIMIT @limit` e so depois fazem `JOIN cards`.
- `COUNT(DISTINCT card_id)` foi substituido por `COUNT(*)` no snapshot da data, preservando semantica porque `price_history` possui `UNIQUE(card_id, price_date)`.
- Adicionado cache process-local com TTL de 5 minutos e fallback stale em timeout.
- Adicionado timeout defensivo server-side de 4s com resposta degradada que preserva `date`, `previous_date`, `gainers`, `losers` e `total_tracked`.
- Criada migration nao destrutiva `bin/migrate_market_movers_performance.dart` com indice `idx_price_history_date_card_price` e `ANALYZE price_history`.

### Validacao pos-correcao

| Comando/prova | Resultado |
| --- | --- |
| `EXPLAIN ANALYZE` resumo datas/total | `10.919ms` |
| `EXPLAIN ANALYZE` gainers | `64.989ms` |
| `EXPLAIN ANALYZE` losers | `53.328ms` |
| `curl -sS -o /tmp/market_movers_probe.json -w "http_code=%{http_code} time_total=%{time_total}\n" "http://127.0.0.1:8082/market/movers?limit=5&min_price=1.0"` | `http_code=200 time_total=1.918091` |
| Segundo probe HTTP com cache | `http_code=200 time_total=0.005164` |
| Payload | `{"date":"2026-04-29","previous_date":"2026-04-28","gainers":[],"losers":[],"total_tracked":30569}` |

## Rotas existentes relevantes

| Area | Rotas server | Consumidores app |
| --- | --- | --- |
| Health | `/health`, `/health/live`, `/health/ready`, `/ready`, `/health/metrics`, `/health/dashboard` | QA/runtime, readiness |
| Auth | `/auth/login`, `/auth/register`, `/auth/me` | `AuthProvider` |
| Users/Profile/FCM | `/users/me`, `/users/me/fcm-token`, `/users/me/activation-events`, `/users/me/plan`, `/users/:id/follow`, `/followers`, `/following` | `AuthProvider`, `PushNotificationService`, `ActivationFunnelService`, `SocialProvider` |
| Cards | `/cards`, `/cards/printings`, `/cards/resolve`, `/cards/resolve/batch` | `CardProvider`, `ScannerCardSearchService`, deck generation/import |
| Sets | `/sets` | `SetsCatalogScreen`, `SetCardsScreen` |
| Decks | `/decks`, `/decks/:id`, `/decks/:id/cards`, `/cards/bulk`, `/cards/set`, `/cards/replace`, `/validate`, `/pricing`, `/export`, `/analysis`, `/ai-analysis`, `/recommendations`, `/simulate` | `DeckProvider` support modules |
| Import | `/import`, `/import/validate`, `/import/to-deck` | `DeckProviderSupportImport` |
| AI | `/ai/generate`, `/ai/optimize`, `/ai/optimize/jobs/:id`, `/ai/archetypes`, `/ai/rebuild`, `/ai/explain`, `/ai/optimize/telemetry`, `/ai/ml-status`, `/ai/simulate`, `/ai/simulate-matchup`, `/ai/weakness-analysis`, `/ai/commander-reference` | `DeckProvider`, `CardProvider`, QA scripts |
| Binder | `/binder`, `/binder/:id`, `/binder/stats` | `BinderProvider` |
| Community | `/community/decks`, `/community/decks/:id`, `/community/decks/following`, `/community/users`, `/community/users/:id`, `/community/binders/:userId`, `/community/marketplace` | `CommunityProvider`, `SocialProvider`, `BinderProvider` |
| Market | `/market/movers`, `/market/card/:cardId` | `MarketProvider`, market/community/home cards |
| Trades | `/trades`, `/trades/:id`, `/trades/:id/respond`, `/trades/:id/status`, `/trades/:id/messages` | `TradeProvider` |
| Conversations | `/conversations`, `/conversations/:id/messages`, `/conversations/:id/read`, `/conversations/unread-count` | `MessageProvider` |
| Notifications | `/notifications`, `/notifications/count`, `/notifications/read-all`, `/notifications/:id/read` | `NotificationProvider`, shell app bar |
| Rules | `/rules` | Future/reference |

## App provider -> endpoint map

| Provider/Service | Endpoints usados |
| --- | --- |
| `AuthProvider` | `POST /auth/login`, `POST /auth/register`, `GET /auth/me`, `GET /users/me`, `PATCH /users/me` |
| `CardProvider` | `GET /cards?name=...`, `POST /ai/explain`, `GET /cards/printings` |
| `DeckProviderSupportFetch` | `GET /decks`, `GET /decks/:id`, `DELETE /decks/:id`, `POST /decks/:id/ai-analysis` |
| `DeckProviderSupportGeneration` | `POST /ai/generate`, `POST /cards/resolve/batch`, `GET /cards?name=...` |
| `DeckProviderSupportImport` | `POST /import`, `POST /import/validate`, `POST /import/to-deck`, `PUT /decks/:id`, `GET /decks/:id/export`, `POST /community/decks/:id` |
| `DeckProviderSupportAi` | `POST /ai/optimize`, `GET /ai/optimize/jobs/:id`, `POST /ai/rebuild` |
| `DeckProviderSupportMutation` | `POST /decks`, `POST /decks/:id/cards`, `POST /decks/:id/cards/bulk`, `POST /decks/:id/cards/set`, `POST /decks/:id/cards/replace`, `PUT /decks/:id`, `POST /ai/archetypes`, `POST /decks/:id/validate`, `POST /decks/:id/pricing` |
| `BinderProvider` | `GET/POST /binder`, `GET /binder/stats`, `PUT/DELETE /binder/:id`, `GET /community/binders/:userId`, `GET /community/marketplace` |
| `TradeProvider` | `GET/POST /trades`, `GET /trades/:id`, `PUT /trades/:id/respond`, `PUT /trades/:id/status`, `GET/POST /trades/:id/messages` |
| `MessageProvider` | `GET /conversations/unread-count`, `GET/POST /conversations`, `GET/POST /conversations/:id/messages`, `PUT /conversations/:id/read` |
| `NotificationProvider` | `GET /notifications/count`, `GET /notifications`, `PUT /notifications/:id/read`, `PUT /notifications/read-all` |
| `SocialProvider` | `GET /community/users`, `GET /community/users/:id`, `POST/DELETE /users/:id/follow`, `GET /users/:id/followers`, `GET /users/:id/following`, `GET /community/decks/following` |
| `CommunityProvider` | `GET /community/decks`, `GET /community/decks/:id` |
| `MarketProvider` | `GET /market/movers?limit=...&min_price=...` |
| `ScannerCardSearchService` | `GET /cards`, `GET /cards/printings`, `POST /cards/resolve` |
| `PushNotificationService` | `PUT /users/me/fcm-token`, `DELETE /users/me/fcm-token` |
| `ActivationFunnelService` | `POST /users/me/activation-events` |

## Validacao automatizada

| Comando | Resultado | Classificacao |
| --- | --- | --- |
| `cd server && dart analyze test bin lib routes` | Passou, sem issues | Green |
| `cd server && dart test` | Passou com `554` testes offline/unitarios | Green |
| `TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live` | Passou com `162` testes live e `3` skips declarados | Green live-backend |
| `curl http://127.0.0.1:8082/health` | Healthy | Green |
| `POST /decks/not-a-uuid/cards*` sem token | `401` para `/cards`, `/cards/bulk`, `/cards/set`, `/cards/replace` | Middleware/roteamento existem |
| `curl /market/movers?limit=5&min_price=1.0` | Auditoria original: sem resposta em >60s; pos-correcao: `200` em `1.918091s` frio e `0.005164s` quente | Corrigido |

Separacao de testes aplicada em 2026-04-29:

- `server/dart_test.yaml` define `paths` offline para `dart test`.
- O preset `live` carrega os testes HTTP marcados com `@Tags(['live', ...])`.
- Tags usadas: `live`, `live_backend`, `live_db_write`, `live_external`.
- Testes live usam `TEST_API_BASE_URL` e fallback local `http://127.0.0.1:8082`, sem `localhost:8080` hardcoded para backend real.
- `RUN_INTEGRATION_TESTS=1` deixou de ser requisito; `RUN_INTEGRATION_TESTS=0` permanece como opt-out explicito para invocacao manual.

## Contratos provados no iPhone 15

| Fluxo | Contratos exercitados |
| --- | --- |
| Sets catalog | `GET /sets`, `GET /cards?set=...` |
| Search cards/sets | `GET /cards?name=...`, `GET /sets`, `GET /cards?set=...` |
| Collection entrypoints | Auth shell + telas de Binder/Marketplace/Trades/Colecoes; alguns endpoints podem retornar 401 esperado se sem dados/autenticacao especifica |
| Deck runtime Commander | Auth/register, deck create/import/details, cards resolve/search, optimize/job/apply/validate, pricing/analysis auxiliares conforme harness |

## Bugs e riscos backend

| Severidade | Contrato | Evidencia | Impacto |
| --- | --- | --- | --- |
| P0/P1 | `GET /market/movers?limit=5&min_price=1.0` | Corrigido em 2026-04-29: `200` em `1.918091s` frio e `0.005164s` quente | Risco imediato removido; manter observabilidade de p95/p99 |
| P1 | Test infra live em `localhost:8080` | Corrigido em 2026-04-29 com `dart_test.yaml`, tags live e preset `live` | Risco removido; manter inventario em `server/test/README.md` atualizado |
| P1/P2 | Social Trading read latency | Escritas principais foram reduzidas; leituras de detalhe/mensagens ainda aparecem em ~`1.1s-1.7s` por DB remoto | Monitorar p95/p99 e promover a P1 se houver impacto perceptivel na UX |
| P2 | FCM delivery live | Sentry staging foi provado no app/backend; FCM real ficou `not_proven` no iPhone 15 Simulator por ausência de APNS token | Falta prova de entrega push em device/config staging |

## Hipoteses tecnicas para `/market/movers`

Hipoteses da auditoria original, confirmadas/refinadas na correcao:

1. havia plano ruim por estatisticas defasadas e join/order sem limite materializado cedo;
2. faltava cache/materializacao process-local para dado derivado de mercado;
3. faltava timeout server-side defensivo menor que o timeout do app;
4. indice cobrindo `(price_date DESC, card_id) INCLUDE (price_usd)` foi adicionado para sustentar as leituras por snapshot.

## Backlog backend priorizado

### P0

1. Manter dashboard/metricas de p95/p99 para `/market/movers` em producao.
2. Manter dashboard de saude dos testes server separados:
   - `dart test` unit/offline;
   - `TEST_API_BASE_URL=... dart test -P live` para live backend/DB write.

## Atualizacao - contratos Binder/Marketplace/Trades runtime - 2026-04-29 17:10 -0300

Prova fresca no iPhone 15 Simulator com backend real em `http://127.0.0.1:8082`:

- Handoff: `app/doc/runtime_flow_handoffs/binder_marketplace_trade_iphone15_2026-04-29.md`.
- Teste: `app/integration_test/binder_marketplace_trade_runtime_test.dart`.
- Log PASS: `app/doc/runtime_flow_proofs_2026-04-29_iphone15_simulator_binder_marketplace_trade/binder_marketplace_trade_runtime_after_sprint_pass.log`.
- Device: `iPhone 15`, id `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, runtime `com.apple.CoreSimulator.SimRuntime.iOS-17-4`.

Contratos exercitados com dados reais `qa_bmt_*`:

| Area | Endpoints provados | Resultado |
| --- | --- | --- |
| Auth | `POST /auth/register`, `POST /auth/login` | Seller e buyer criados/logados |
| Cards | `GET /cards/printings`, `GET /cards?name=...` | `Command Tower` no editor; `Sol Ring` no marketplace |
| Binder | `GET/POST/PUT/DELETE /binder`, `GET /binder/stats` | CRUD autenticado real via UI; `DELETE /binder/:id` retorna `204` |
| Marketplace | `GET /community/marketplace` | Listagem sem filtro e busca com item seller visivel para buyer |
| Trades | `POST /trades`, `GET /trades`, `GET /trades/:id`, `PUT /trades/:id/respond`, `PUT /trades/:id/status` | Trade `80366433-a69c-4f1e-90d0-03c923c76f5b` chegou a `completed`; buyer provou `Confirmar Entrega` e `Finalizar` via UI |
| Trade messages | `GET/POST /trades/:id/messages` | Mensagem criada via chat visual e lida ao reabrir detalhe |
| Notifications | `GET /notifications`, `GET /notifications/count`, `PUT /notifications/:id/read`, `PUT /notifications/read-all` | Tipos `trade_offer_received`, `trade_accepted`, `trade_message`, `trade_shipped`, `trade_completed` observados; read/read-all provados |
| Conversations | `GET/POST /conversations`, `GET/POST /conversations/:id/messages`, `PUT /conversations/:id/read` | Runtime separado de direct messages provou conversa, envio visual e read receipt |

Impactos app/backend corrigidos: o app esperava `200` no delete de binder, mas o backend corretamente respondia `204 No Content`; o chat de trade mutava lista em memoria e nao reconstruia a UI; polling de direct messages podia sobrepor chamadas lentas; o botao `Ler todas` dependia apenas de `unreadCount` e nao da lista carregada.

Risco de performance observado no runtime PASS final:

- `GET /community/marketplace?page=1&limit=20`: `664ms`;
- `GET /trades?page=1&limit=20`: `608ms-633ms`;
- `GET /trades/:id`: ~`1202ms-1253ms`;
- `POST /trades`: `5165ms`;
- `PUT /trades/:id/respond`: `3205ms`;
- `PUT /trades/:id/status`: `3941ms-3995ms`;
- `POST /trades/:id/messages`: `2403ms`;
- `POST /conversations/:id/messages`: `3047ms`.

Sentry/logs: rotas `binder`, `community/marketplace`, `trades`, `conversations` e `notifications` capturam excecoes com `captureRouteException` e `Log.e` com contexto tecnico sanitizado. O app registra slow-request breadcrumbs e 4xx/5xx reportaveis no `ApiClient` sem payload sensivel.

Backlog adicional P1: reduzir latencia residual de escritas em social trading/direct messages e manter p95/p99 por endpoint antes de release amplo.

## Atualizacao - sprint final Social Trading performance/observability - 2026-04-29 17:37 -0300

Escopo executado nos endpoints lentos documentados: `POST /trades`, `PUT /trades/:id/status`, `POST /trades/:id/messages` e `POST /conversations/:id/messages`.

### Baseline antes da alteracao

Medição contra backend real `http://127.0.0.1:8082`, payloads sanitizados, marker `qa_perf_bb17c499a1`:

| Endpoint | Frio | Quente | Status |
| --- | ---: | ---: | --- |
| `POST /trades` | `5324.62ms` | `6167.93ms` | `201` |
| `PUT /trades/:id/status` | `4061.75ms` | `4060.68ms` | `200` |
| `POST /trades/:id/messages` | `2440.10ms` | `2443.68ms` | `201` |
| `POST /conversations/:id/messages` | `3058.88ms` | `3043.00ms` | `201` |

Erro classificado antes da correcao: `delivery_method=mail` em `PUT /trades/:id/status` era payload invalido para o schema (`CHECK` aceita `correios`, `motoboy`, `pessoalmente`, `outro`) e caia como `500`. A rota agora valida antes do DB e retorna `400`.

### Resultado depois

Medição final com marker `qa_perf_final_f3357696e1`:

| Endpoint | Frio | Quente | Melhora |
| --- | ---: | ---: | ---: |
| `POST /trades` | `4123.00ms` | `4941.76ms` | `22.6%` / `19.9%` |
| `PUT /trades/:id/status` | `2844.34ms` | `2845.01ms` | `30.0%` / `29.9%` |
| `POST /trades/:id/messages` | `1222.30ms` | `1228.63ms` | `49.9%` / `49.7%` |
| `POST /conversations/:id/messages` | `1238.07ms` | `1233.96ms` | `59.5%` / `59.4%` |

Runtime iPhone 15 com app real confirmou:

- `POST /trades`: `3978ms` (`201`);
- `PUT /trades/:id/status`: `2811ms`, `2786ms`, `2876ms` (`200`);
- `POST /trades/:id/messages`: `1233ms` (`201`);
- `POST /conversations/:id/messages`: `1219ms` (`201`).

### Mudancas de contrato/implementacao

- Contrato JSON preservado para sucesso e erros esperados.
- `NotificationService.createFromActorDeferred` tira criacao de notificacao/FCM do caminho critico com timeout de 10s, logs `slow_deferred`/`deferred_failed` e `captureObservedException` sem payload sensivel.
- `POST /conversations/:id/messages` usa CTE para inserir mensagem e atualizar `last_message_at` em um round-trip.
- `POST /trades` valida `payment_method`; `PUT /trades/:id/status` valida `delivery_method`, evitando 5xx por constraint previsivel.
- Middleware raiz registra/captura 4xx/5xx e slow request com endpoint, duracao, request id, user id tecnico e ids seguros; Sentry e deferido para nao adicionar latencia.

### Cobertura

- Novo teste: `server/test/social_trading_live_test.dart`, incluido em `dart_test.yaml` preset `live`.
- Cobertura live: usuarios reais, binder item real, `POST /trades`, `PUT /respond`, `PUT /status`, `POST /trades/:id/messages`, `POST /conversations/:id/messages`, `400` esperado de `payment_method`/`delivery_method` e notificacoes `trade_offer_received`/`direct_message`.
- Logs provados: `[http_observability] classification=slow_request`, `[http_observability] classification=client_error`, `[social_write] invalid_payload`, `[social_notification] slow_deferred`.
- Sentry/FCM externo: FCM real segue `not proven` no simulador/config local; codigo de captura/log estruturado foi validado por analyze/testes/live runtime.

### P1

1. Manter a separacao `dart test` offline vs `dart test -P live` em novos testes server.
2. Criar contract smoke app-provider endpoints vs `server/routes` para detectar rotas ausentes.
3. Criar runtime backend fixtures reaproveitaveis para social/trading/messages com dois usuarios.

### P2

1. Expor health/readiness com DB dependency opcional para runtime QA.
2. Adicionar metricas por endpoint: duration, status, request-id e user-id anonimo.
3. Documentar contratos de social/trades/messages em OpenAPI ou tabela gerada.

## Menores proximas acoes

1. Adicionar fixtures live dedicadas para social/trading/messages sem depender de dados manuais.
2. Provar FCM real em device/config staging; nao foi coberto pelo simulador sem Firebase inicializado.
