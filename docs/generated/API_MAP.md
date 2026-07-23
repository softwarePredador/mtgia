# ManaLoom — mapa estrutural de API

> Gerado das convenções de `server/routes` e dos métodos encontrados no código. Shapes detalhados continuam em `server/doc/API_CONTRACTS_AND_DATA_MAP.md`.

| Path | Métodos | Handler | Middleware | Prova |
|---|---|---|---|---|
| `/` | `GET` | `server/routes/index.dart` | 1 | `source` |
| `/ai/archetypes` | `POST` | `server/routes/ai/archetypes/index.dart` | 2 | `source` |
| `/ai/commander-learning` | `GET` | `server/routes/ai/commander-learning/index.dart` | 2 | `source` |
| `/ai/commander-reference` | `GET` | `server/routes/ai/commander-reference/index.dart` | 2 | `source` |
| `/ai/explain` | `POST` | `server/routes/ai/explain/index.dart` | 2 | `source` |
| `/ai/generate` | `POST` | `server/routes/ai/generate/index.dart` | 2 | `source` |
| `/ai/generate/jobs/{id}` | `DELETE, GET` | `server/routes/ai/generate/jobs/[id].dart` | 2 | `source` |
| `/ai/ml-status` | `GET` | `server/routes/ai/ml-status/index.dart` | 2 | `source` |
| `/ai/optimize` | `POST` | `server/routes/ai/optimize/index.dart` | 2 | `source` |
| `/ai/optimize/jobs/{id}` | `DELETE, GET` | `server/routes/ai/optimize/jobs/[id].dart` | 2 | `source` |
| `/ai/optimize/telemetry` | `GET` | `server/routes/ai/optimize/telemetry/index.dart` | 2 | `source` |
| `/ai/rebuild` | `POST` | `server/routes/ai/rebuild/index.dart` | 2 | `source` |
| `/ai/simulate` | `POST` | `server/routes/ai/simulate/index.dart` | 2 | `source` |
| `/ai/simulate-matchup` | `POST` | `server/routes/ai/simulate-matchup/index.dart` | 2 | `source` |
| `/ai/weakness-analysis` | `POST` | `server/routes/ai/weakness-analysis/index.dart` | 2 | `source` |
| `/auth/change-password` | `POST` | `server/routes/auth/change-password.dart` | 2 | `source` |
| `/auth/forgot-password` | `POST` | `server/routes/auth/forgot-password.dart` | 2 | `source` |
| `/auth/login` | `POST` | `server/routes/auth/login.dart` | 2 | `source` |
| `/auth/me` | `GET` | `server/routes/auth/me.dart` | 2 | `source` |
| `/auth/register` | `POST` | `server/routes/auth/register.dart` | 2 | `source` |
| `/auth/resend-verification` | `POST` | `server/routes/auth/resend-verification.dart` | 2 | `source` |
| `/auth/reset-password` | `POST` | `server/routes/auth/reset-password.dart` | 2 | `source` |
| `/auth/revoke-sessions` | `POST` | `server/routes/auth/revoke-sessions.dart` | 2 | `source` |
| `/auth/verify-email` | `POST` | `server/routes/auth/verify-email.dart` | 2 | `source` |
| `/billing/webhook` | `POST` | `server/routes/billing/webhook/index.dart` | 1 | `source` |
| `/binder` | `GET, POST` | `server/routes/binder/index.dart` | 2 | `source` |
| `/binder/{id}` | `DELETE, GET, PUT` | `server/routes/binder/[id]/index.dart` | 2 | `source` |
| `/cards` | `GET` | `server/routes/cards/index.dart` | 1 | `source` |
| `/cards/printings` | `GET` | `server/routes/cards/printings/index.dart` | 1 | `source` |
| `/cards/resolve` | `POST` | `server/routes/cards/resolve/index.dart` | 1 | `source` |
| `/cards/resolve/batch` | `POST` | `server/routes/cards/resolve/batch/index.dart` | 1 | `source` |
| `/cards/{id}/rulings` | `GET` | `server/routes/cards/[id]/rulings/index.dart` | 1 | `source` |
| `/community/binders/{userId}` | `GET` | `server/routes/community/binders/[userId].dart` | 2 | `source` |
| `/community/decks` | `GET` | `server/routes/community/decks/index.dart` | 2 | `source` |
| `/community/decks/{id}` | `GET, POST` | `server/routes/community/decks/[id]/index.dart` | 2 | `source` |
| `/community/decks/{id}/comments` | `GET, POST` | `server/routes/community/decks/[id]/comments/index.dart` | 2 | `source` |
| `/community/decks/{id}/reports` | `POST` | `server/routes/community/decks/[id]/reports/index.dart` | 2 | `source` |
| `/community/marketplace` | `GET` | `server/routes/community/marketplace/index.dart` | 2 | `source` |
| `/community/trade-matches` | `GET` | `server/routes/community/trade-matches/index.dart` | 2 | `source` |
| `/community/users` | `GET` | `server/routes/community/users/index.dart` | 2 | `source` |
| `/community/users/{id}` | `GET` | `server/routes/community/users/[id].dart` | 2 | `source` |
| `/conversations` | `GET, POST` | `server/routes/conversations/index.dart` | 2 | `source` |
| `/conversations/unread-count` | `GET` | `server/routes/conversations/unread-count.dart` | 2 | `source` |
| `/conversations/{id}/messages` | `GET, POST` | `server/routes/conversations/[id]/messages.dart` | 2 | `source` |
| `/conversations/{id}/read` | `PUT` | `server/routes/conversations/[id]/read.dart` | 2 | `source` |
| `/decks` | `GET, POST` | `server/routes/decks/index.dart` | 2 | `source` |
| `/decks/{id}` | `DELETE, GET, PUT` | `server/routes/decks/[id]/index.dart` | 2 | `source` |
| `/decks/{id}/ai-analysis` | `POST` | `server/routes/decks/[id]/ai-analysis/index.dart` | 3 | `source` |
| `/decks/{id}/analysis` | `GET` | `server/routes/decks/[id]/analysis/index.dart` | 2 | `source` |
| `/decks/{id}/battle-replays` | `GET` | `server/routes/decks/[id]/battle-replays/index.dart` | 2 | `source` |
| `/decks/{id}/battle-replays/{replayId}` | `GET` | `server/routes/decks/[id]/battle-replays/[replayId]/index.dart` | 2 | `source` |
| `/decks/{id}/cards` | `POST` | `server/routes/decks/[id]/cards/index.dart` | 2 | `source` |
| `/decks/{id}/cards/bulk` | `POST` | `server/routes/decks/[id]/cards/bulk/index.dart` | 2 | `source` |
| `/decks/{id}/cards/replace` | `POST` | `server/routes/decks/[id]/cards/replace/index.dart` | 2 | `source` |
| `/decks/{id}/cards/set` | `POST` | `server/routes/decks/[id]/cards/set/index.dart` | 2 | `source` |
| `/decks/{id}/export` | `GET` | `server/routes/decks/[id]/export/index.dart` | 2 | `source` |
| `/decks/{id}/optimizations/{eventId}/rollback` | `POST` | `server/routes/decks/[id]/optimizations/[eventId]/rollback/index.dart` | 2 | `source` |
| `/decks/{id}/post-game-notes` | `GET, POST` | `server/routes/decks/[id]/post-game-notes/index.dart` | 2 | `source` |
| `/decks/{id}/post-game-notes/{noteId}` | `DELETE` | `server/routes/decks/[id]/post-game-notes/[noteId].dart` | 2 | `source` |
| `/decks/{id}/post-game-timeline` | `GET` | `server/routes/decks/[id]/post-game-timeline/index.dart` | 2 | `source` |
| `/decks/{id}/pricing` | `POST` | `server/routes/decks/[id]/pricing/index.dart` | 2 | `source` |
| `/decks/{id}/recommendations` | `POST` | `server/routes/decks/[id]/recommendations/index.dart` | 3 | `source` |
| `/decks/{id}/reports` | `POST` | `server/routes/decks/[id]/reports/index.dart` | 2 | `source` |
| `/decks/{id}/simulate` | `GET` | `server/routes/decks/[id]/simulate/index.dart` | 2 | `source` |
| `/decks/{id}/validate` | `POST` | `server/routes/decks/[id]/validate/index.dart` | 2 | `source` |
| `/health` | `GET` | `server/routes/health/index.dart` | 2 | `source` |
| `/health/ai-history` | `GET` | `server/routes/health/ai-history/index.dart` | 2 | `source` |
| `/health/commercial` | `GET` | `server/routes/health/commercial/index.dart` | 2 | `source` |
| `/health/dashboard` | `GET` | `server/routes/health/dashboard/index.dart` | 2 | `source` |
| `/health/live` | `GET` | `server/routes/health/live/index.dart` | 2 | `source_plus_manual_override` |
| `/health/metrics` | `GET` | `server/routes/health/metrics/index.dart` | 2 | `source` |
| `/health/ready` | `GET` | `server/routes/health/ready/index.dart` | 2 | `source` |
| `/import` | `POST` | `server/routes/import/index.dart` | 2 | `source` |
| `/import/to-deck` | `POST` | `server/routes/import/to-deck/index.dart` | 2 | `source` |
| `/import/validate` | `POST` | `server/routes/import/validate/index.dart` | 2 | `source` |
| `/market/card/{cardId}` | `GET` | `server/routes/market/card/[cardId].dart` | 1 | `source` |
| `/market/movers` | `GET` | `server/routes/market/movers/index.dart` | 1 | `source` |
| `/notifications` | `GET` | `server/routes/notifications/index.dart` | 2 | `source` |
| `/notifications/count` | `GET` | `server/routes/notifications/count.dart` | 2 | `source` |
| `/notifications/read-all` | `PUT` | `server/routes/notifications/read-all.dart` | 2 | `source` |
| `/notifications/{id}/read` | `PUT` | `server/routes/notifications/[id]/read.dart` | 2 | `source` |
| `/ready` | `GET` | `server/routes/ready/index.dart` | 1 | `source_plus_manual_override` |
| `/reports/{id}` | `GET` | `server/routes/reports/[id].dart` | 1 | `source` |
| `/rules` | `GET` | `server/routes/rules/index.dart` | 1 | `source` |
| `/sets` | `GET` | `server/routes/sets/index.dart` | 1 | `source` |
| `/trades` | `GET, POST` | `server/routes/trades/index.dart` | 2 | `source` |
| `/trades/{id}` | `GET` | `server/routes/trades/[id]/index.dart` | 2 | `source` |
| `/trades/{id}/messages` | `GET, POST` | `server/routes/trades/[id]/messages.dart` | 2 | `source` |
| `/trades/{id}/respond` | `PUT` | `server/routes/trades/[id]/respond.dart` | 2 | `source` |
| `/trades/{id}/status` | `PUT` | `server/routes/trades/[id]/status.dart` | 2 | `source` |
| `/users/me` | `DELETE, GET, PATCH` | `server/routes/users/me/index.dart` | 2 | `source` |
| `/users/me/activation-events` | `GET, POST` | `server/routes/users/me/activation-events/index.dart` | 2 | `source` |
| `/users/me/export` | `GET` | `server/routes/users/me/export/index.dart` | 2 | `source` |
| `/users/me/fcm-token` | `DELETE, PUT` | `server/routes/users/me/fcm-token/index.dart` | 2 | `source` |
| `/users/me/plan` | `GET` | `server/routes/users/me/plan/index.dart` | 2 | `source` |
| `/users/me/plan/checkout` | `POST` | `server/routes/users/me/plan/checkout/index.dart` | 2 | `source` |
| `/users/{id}/follow` | `DELETE, GET, POST` | `server/routes/users/[id]/follow/index.dart` | 2 | `source` |
| `/users/{id}/followers` | `GET` | `server/routes/users/[id]/followers/index.dart` | 2 | `source` |
| `/users/{id}/following` | `GET` | `server/routes/users/[id]/following/index.dart` | 2 | `source` |

Contrato OpenAPI estrutural: `docs/generated/openapi.generated.json`.
