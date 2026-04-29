# App Backend Contract Audit - 2026-04-29

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
| P1 | Social/trades/messages full contracts | Rotas existem e error contract cobre parte, mas runtime end-to-end nao foi fresco | Risco funcional antes de release social/trades |
| P2 | Observability live | Sentry/Firebase presentes, mas DSN/config real nao provados nesta auditoria | Falta visibilidade de producao/staging |

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

### P1

1. Manter a separacao `dart test` offline vs `dart test -P live` em novos testes server.
2. Criar contract smoke app-provider endpoints vs `server/routes` para detectar rotas ausentes.
3. Criar runtime backend fixtures para messages/trades/notifications com dois usuarios.

### P2

1. Expor health/readiness com DB dependency opcional para runtime QA.
2. Adicionar metricas por endpoint: duration, status, request-id e user-id anonimo.
3. Documentar contratos de social/trades/messages em OpenAPI ou tabela gerada.

## Menores proximas acoes

1. Adicionar fixtures live dedicadas para social/trading/messages sem depender de dados manuais.
2. Adicionar uma prova iPhone 15 para cada dominio social/trading ainda `not proven`.
