# Full Backend/Data Flow Audit - 2026-05-15

## Scope and verdict

Track A audited app-facing backend/data contracts for the ManaLoom full-stack
non-scanner round on `master`. Scanner/camera/OCR/MLKit were intentionally not
functionally tested and remain **DEFERRED / NOT PROVEN** for this audit.

Overall status: **PASS_WITH_RISKS**.

Reasons:

- Source coverage for the main app-facing routes in `server/routes` is strong and
  mostly matches `server/doc/API_CONTRACTS_AND_DATA_MAP.md`.
- Public backend probes against
  `https://evolution-cartinhas.8ktevp.easypanel.host` passed for sanitized
  health/cards/sets/rules checks.
- Documentation drift exists for a small set of live or potential app-facing
  endpoints and for the sets query parameter naming.
- No P0 backend bug was proven from source. The clearest bug candidate is a route
  organization/compatibility risk around `/community/decks/following`.

No runtime app/backend code was changed in this track.

## Required docs read

- `docs/README.md`
- `server/doc/DOCS_ARTIFACT_RETENTION_AUDIT_2026-05-15.md`
- `server/doc/FULL_FLOW_STATE_AND_DOC_AUDIT_2026-05-15.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `app/doc/UI_TEST_SURFACE_MAP.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `server/manual-de-instrucao.md`

## Endpoint and data-source matrix

| Module | Status | App-facing endpoints / handlers | Main app consumers found | Main tables / columns and data sources | Drift / risks |
|---|---|---|---|---|---|
| Auth/Profile | PASS_WITH_RISKS | `/auth/login`, `/auth/register`, `/auth/me`, `/users/me`, `/users/me/fcm-token`, `/users/me/activation-events`, `/users/me/plan` | `auth_provider.dart`; notification bootstrap/logout for FCM not fully re-proven | `users` profile/auth columns; `activation_funnel_events`; `user_plans.plan_name/status`; `ai_logs.input_tokens/output_tokens/created_at` via `PlanService` | `/users/me/plan` is implemented but absent from API map; no current mobile consumer found in this audit. |
| Cards/Search | PASS | `/cards`, `/cards/printings`, `/cards/resolve`, `/cards/resolve/batch` | `card_provider.dart`, `deck_provider_support_generation.dart`, scanner support service only as backend resolver client | `cards`, `sets`, `card_legalities`; backend-only Scryfall/MTGJSON sync/cache | Scanner-facing code exists, but scanner/OCR behavior is DEFERRED here. Mobile still uses backend, not external MTG APIs. |
| Sets/Coleções | PASS_WITH_RISKS | `/sets` | `sets_catalog_screen.dart`, `set_cards_screen.dart` | `sets.code/name/release_date/type/block/is_online_only/is_foreign_only`, `cards.set_code`; `EndpointCache` | API map documents `search`; live handler/app use `q` and optional `code`. |
| Rules | PASS_WITH_RISKS | `/rules` | No current app feature consumer found; server error-contract tests cover method behavior | `rules.id/title/description/category`; optional `sync_state` metadata | Public route exists and returns list or `{meta,data}` but is absent from API map. |
| Social/Community | PASS_WITH_RISKS | `/community/users`, `/community/users/:id`, `/users/:id/follow*`, `/community/decks`, `/community/decks/:id`, `/community/decks/following` | `social_provider.dart`, `community_provider.dart` | `users`, `user_follows`, `decks`, `deck_cards`, `cards`; notification side effects for follows | `/community/decks/following` is a magic branch inside `[id].dart` and is not separately documented in API map. |
| Binder/Marketplace | PASS | `/binder`, `/binder/:id`, `/binder/stats` via `id == stats`, `/community/binders/:userId`, `/community/marketplace` | `binder_provider.dart` | `user_binder_items`, `cards`, `decks`, `deck_cards`, `users`, `price_history`, trade history for trust | Shape in API map matches current source at summary level. Trust and price insights remain optional/sparse. |
| Trades | PASS | `/trades`, `/trades/:id`, `/trades/:id/respond`, `/trades/:id/status`, `/trades/:id/messages` | `trade_provider.dart`, trade detail/inbox screens, realtime coordinator | `trade_offers`, `trade_items`, `trade_messages`, `trade_status_history`, `user_binder_items`, `users`, `notifications` | API map correctly distinguishes list vs detail `value_summary`. |
| Conversations/Messages | PASS | `/conversations`, `/conversations/:id/messages`, `/conversations/:id/read`, `/conversations/unread-count` | `message_provider.dart`, inbox/chat screens, realtime coordinator | `conversations`, `direct_messages`, `users`, `notifications` for send side effects | Dedicated unread endpoint is documented and consumed. |
| Notifications | PASS | `/notifications`, `/notifications/count`, `/notifications/:id/read`, `/notifications/read-all` | `notification_provider.dart`, shell badges, realtime coordinator | `notifications` | Unknown notification types must remain tolerated. |
| Decks/Import/Validation | PASS | `/decks`, `/decks/:id`, card mutation subroutes, `/decks/:id/validate`, pricing/export/analysis/ai-analysis/recommendations/simulate, `/import*` | deck providers and screens | `decks`, `deck_cards`, `cards`, `card_legalities`, `meta_decks`; backend rules/pricing/analysis calculations | Legacy `GET /decks` raw array remains documented. Experimental analysis/simulation fields remain optional. |
| Generate/Optimize/Validate AI | PASS_WITH_RISKS | `/ai/generate`, `/ai/generate/jobs/:id`, `/ai/optimize`, `/ai/optimize/jobs/:id`, `/ai/rebuild`, `/ai/archetypes`, `/ai/explain`, simulations, weakness, commander-reference, telemetry/ml-status | deck AI/generation providers, `card_provider.dart` explain | `ai_generate_jobs`, `ai_optimize_cache`, telemetry/log tables, `cards`, `decks`, `deck_cards`, `card_meta_insights`, `meta_decks`, Commander Reference tables; OpenAI/backend-only external data | Contracts are intentionally experimental; `/ai/explain` caches generated text in `cards.ai_description` without visible prompt/model version metadata. |
| Meta Deck Intelligence | PASS_WITH_RISKS | Mainly consumed through AI/deck analysis routes and `/ai/commander-reference` | Direct mobile consumer not proven; generation/optimize backend support | `meta_decks`, `card_meta_insights`, Commander Reference profile/stats/corpus tables | Backend owns external refresh and calculations. Direct mobile dependency not proven. |
| Market | PASS | `/market/movers`, `/market/card/:cardId` | `market_provider.dart` for movers; direct card route consumer not proven | `price_history`, `cards` | Sparse history can return empty/nullable values. |
| Health/Ready | PASS | `/health`, `/health/ready`, `/health/live`, `/health/metrics`, `/health/dashboard`, `/ready` | runtime checks/scripts, not normal product UI | process state; DB readiness; `cards`; operational metric tables | `/health/metrics` and dashboard are internal; `/ready` remains deprecated/internal in API map. |

## Documentation drift found

1. **`/users/me/plan` implemented but not mapped**
   - Evidence: `server/routes/users/me/plan/index.dart`,
     `server/lib/plan_service.dart`.
   - Shape: `GET` authenticated route returns `plan.{plan_name,status,
     ai_monthly_limit,ai_requests_used,ai_requests_remaining,estimated_cost_usd}`
     and `upgrade_offer.pro`.
   - Status recommendation: `experimental` until a mobile consumer and tests are
     proven.

2. **`/community/decks/following` implemented as a magic path in `[id].dart`**
   - Evidence: `server/routes/community/decks/[id].dart`, lines handling
     `id == 'following'`; app consumer in `social_provider.dart`.
   - Shape: `GET` auth route with `page/limit`, returns
     `{data,page,limit,total}` public deck summaries.
   - API map currently mentions following feed only indirectly.

3. **`/sets` query docs use stale naming**
   - Evidence: `server/routes/sets/index.dart` parses `q` and `code`;
     `sets_catalog_screen.dart` sends `q`; `set_cards_screen.dart` sends `code`.
   - API map currently lists `search`, with exact fields marked not fully proven.

4. **`/rules` exists but is absent from API map**
   - Evidence: `server/routes/rules/index.dart`.
   - Shape: `GET /rules?q=&limit=&meta=` returns a raw list, or `{meta,data}`
     when `meta` is truthy. No mobile consumer was proven in this audit.

5. **Scanner status wording conflict across docs**
   - API map documents scanner support as stable through backend card routes.
     For the 2026-05-15 non-scanner audit, functional scanner/camera/OCR/MLKit
     remains **DEFERRED / NOT PROVEN**. This is scope, not a backend contract
     failure for `/cards` routes.

## Clear bug candidates

| Severity | Candidate | File / evidence | Repro from source | Patch recommendation |
|---|---|---|---|---|
| P0 | None proven | N/A | No source-backed P0 found without executing mutating flows. | N/A |
| P1 | Magic-route collision and maintainability risk for following feed | `server/routes/community/decks/[id].dart` handles `id == 'following'`; `social_provider.dart` calls `/community/decks/following` | A real public deck with id `following`, or future route refactor, would be ambiguous because collection feed is routed through a detail parameter file. | Move feed to `server/routes/community/decks/following/index.dart`; keep compatibility redirect/branch if needed; add server contract test and update API map. |
| P2 | Plan endpoint contract is undocumented | `server/routes/users/me/plan/index.dart`, `server/lib/plan_service.dart` | Endpoint returns plan/offer data from hardcoded limits and DB usage aggregation, but API map has no row/status/tests. | Document as experimental/internal, add a lightweight route test if app will consume it, and centralize upgrade-offer copy/limits if billing is introduced. |
| P2 | Sets API map drift | `server/routes/sets/index.dart`; `sets_catalog_screen.dart`; `set_cards_screen.dart` | App sends `q`/`code`; API map says `search`. A future agent could implement against the wrong param. | Update API map to `GET /sets?page=&limit=&q=&code=` and keep `search` only if backward-compatible alias is added. |
| P2 | Rules route not classified | `server/routes/rules/index.dart`; `server/test/error_contract_test.dart` | Public route returns data from `rules`/`sync_state` but is not in the contract map. | Add API map row as `internal` or `experimental` unless a product UI consumes it. |
| P2 | `/ai/explain` cache lacks visible prompt/model versioning | `server/routes/ai/explain/index.dart` reads/writes `cards.ai_description` | Once `ai_description` exists, prompt/model changes do not visibly invalidate old explanations. | If explanation quality changes matter, add cache metadata/version or an invalidation path; keep response fields optional. |

## Public backend sanitized probes

All probes avoided auth headers, JWTs, sensitive payloads, emails and decklists.

| Probe | Result |
|---|---|
| `GET /health` | PASS: HTTP 200, `status=healthy`, production environment, sanitized body keys present. |
| `GET /health/ready` | PASS: HTTP 200, `status=ready`, production environment, sanitized body keys present. |
| `GET /sets?limit=1&page=1` | PASS: HTTP 200, `{data,page,limit,total_returned}`, one row returned. |
| `GET /cards?name=sol%20ring&limit=1&page=1` | PASS: HTTP 200, `{data,page,limit,total_returned}`, one row returned. |
| `GET /rules?limit=1` | PASS: HTTP 200, raw list with one row. |

## Commands run

`rg` was requested for endpoint/consumer validation, but `rg` was not available
in this shell (`command not found`). Equivalent sanitized `find`, `grep`,
`python3`, `curl`/`urllib` and `git` commands were used instead.

```bash
git --no-pager status --short --branch
find server/routes -type f -name '*.dart' | sort | sed 's#^#- #' | head -300
grep -RInE "<endpoint-patterns>" app/lib/features app/lib/core app/integration_test server/test server/routes server/lib --include='*.dart' | head -400
grep -RInE "users/me/plan|community/decks/following|/rules|conversations/unread-count|/sets|/cards/resolve/batch|/ai/explain|/ai/archetypes|/ai/ml-status|optimize/telemetry|weakness-analysis" app/lib/features app/lib/core app/integration_test server/test --include='*.dart' | head -220
python3 <route-inventory-vs-api-map-script>
python3 <sanitized-public-probes>
```

Validation after writing this document:

```bash
git diff --check
python3 <sanitized-doc-secret-scan>
```

## Validation status

- PASS: required docs were read before conclusions.
- PASS_WITH_RISKS: endpoint inventory and consumer searches completed with
  `grep`/`find` because `rg` was unavailable.
- PASS: public backend non-mutating probes returned expected sanitized statuses.
- PASS: no runtime app/backend code was changed.
- BLOCKED/DEFERRED: scanner/camera/OCR/MLKit functional validation remains out of
  scope for this non-scanner track.
