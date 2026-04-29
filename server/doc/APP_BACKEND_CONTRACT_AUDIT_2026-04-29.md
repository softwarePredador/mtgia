# App Backend Contract Audit - 2026-04-29

## Resumo executivo

Auditoria dos contratos backend consumidos pelo app ManaLoom em `2026-04-29`, cruzando providers/telas do app com `server/routes`, validacao automatizada e runtime iPhone 15 com backend real em `http://127.0.0.1:8082`.

O contrato core app/backend esta coerente para auth, decks, cards, sets, import, optimize, validate, binder, community, trades, conversations e notifications. As variantes incrementais de deck cards existem no backend (`bulk`, `set`, `replace`) e retornam `401` quando chamadas sem token, confirmando roteamento e middleware.

Risco provado: `GET /market/movers?limit=5&min_price=1.0` nao retornou dentro do timeout do app (15s) e tambem nao retornou em probe `curl` apos 60s. Isso afeta Home/Market/Community, mas o app capturou o erro sem quebrar o runtime de deck.

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
| `cd server && dart analyze lib routes bin test` | Passou, sem issues | Green |
| `cd server && dart test` | Falhou por testes live sem backend em `localhost:8080` | Ambiente/test infra |
| `curl http://127.0.0.1:8082/health` | Healthy | Green |
| `POST /decks/not-a-uuid/cards*` sem token | `401` para `/cards`, `/cards/bulk`, `/cards/set`, `/cards/replace` | Middleware/roteamento existem |
| `curl /market/movers?limit=5&min_price=1.0` | Sem resposta em >60s, processo encerrado manualmente | Falha de performance/hang |

Falha de `dart test` ampla:

- `test/ai_archetypes_flow_test.dart`: `Connection refused`, tentativa em `http://localhost:8080/auth/login`.
- `test/decks_crud_test.dart`: o proprio setup imprime que o servidor precisa estar rodando em `http://localhost:8080`.
- Leitura: a suite mistura testes unitarios e testes live. Para CI/auditoria, separar tags ou comandos por `unit`, `contract-live`, `db-live`.

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
| P0/P1 | `GET /market/movers?limit=5&min_price=1.0` | Timeout no app apos 15s; `curl` isolado pendurado >60s | Home/Market/Community podem carregar lento e gerar erro silencioso/degradado |
| P1 | Test infra live em `localhost:8080` | `dart test` falha sem servidor live | CI/auditoria ampla fica vermelha por ambiente ausente |
| P1 | Social/trades/messages full contracts | Rotas existem e error contract cobre parte, mas runtime end-to-end nao foi fresco | Risco funcional antes de release social/trades |
| P2 | Observability live | Sentry/Firebase presentes, mas DSN/config real nao provados nesta auditoria | Falta visibilidade de producao/staging |

## Hipoteses tecnicas para `/market/movers`

Sem alterar codigo nesta rodada, a leitura operacional e:

1. query possivelmente varre `cards`/precos sem indice seletivo por `price_usd`/`price_updated_at`;
2. pode haver join/agregacao sem limite aplicado cedo;
3. falta cache/materializacao para movers, que e dado derivado de mercado;
4. endpoint leve usa o mesmo timeout de 15s do app, gerando erro perceptivel mesmo sem derrubar fluxo.

## Backlog backend priorizado

### P0

1. Medir `EXPLAIN ANALYZE` de `/market/movers?limit=5&min_price=1.0` no banco real.
2. Adicionar indice/camada materializada/cache para movers.
3. Definir budget: p95 < 1s para `limit<=10`; timeout server-side defensivo com resposta 503/empty degradada se exceder.

### P1

1. Separar testes server por tags/comandos:
   - unit/offline;
   - route/error contract local;
   - live backend `TEST_API_BASE_URL`;
   - DB write/apply.
2. Parametrizar testes live para `TEST_API_BASE_URL`, evitando `localhost:8080` hardcoded.
3. Criar contract smoke app-provider endpoints vs `server/routes` para detectar rotas ausentes.
4. Criar runtime backend fixtures para messages/trades/notifications com dois usuarios.

### P2

1. Expor health/readiness com DB dependency opcional para runtime QA.
2. Adicionar metricas por endpoint: duration, status, request-id e user-id anonimo.
3. Documentar contratos de social/trades/messages em OpenAPI ou tabela gerada.

## Menores proximas acoes

1. Corrigir `/market/movers` antes de qualquer release que exiba Home/Market/Community como caminho principal.
2. Criar `dart test` padrao que rode sem backend externo e mover live tests para comando explicito.
3. Adicionar uma prova iPhone 15 para cada dominio social/trading ainda `not proven`.

