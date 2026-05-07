# Public Backend Contract QA - 2026-05-07

## Verdict

`PASS WITH RISKS`

Public app-facing backend contracts were validated against:

- Backend: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Branch: `master`
- Local/public git SHA: `478918369a4e943d40a449e1f4bdbeed57f3714e`
- Public `/health`: `status=healthy`, `environment=production`
- QA identity: discardable user created only for this battery; credentials, JWT,
  email address and raw sensitive payloads were not recorded.

Physical Scanner, camera, OCR and MLKit scanner flows were explicitly ignored.
Scanner-adjacent backend validation was limited to token-safe `/cards/resolve`
and `/cards/printings` calls.

## Scope and Method

- Consulted `server/doc/API_CONTRACTS_AND_DATA_MAP.md` before testing.
- Synchronized `master` with `origin/master` using fast-forward pull; no local
  conflicts blocked the run.
- Used sanitized QA data for register/login/profile, deck, binder and AI flows.
- Created discardable deck and binder records were deleted after validation.
- No secrets, JWTs, passwords, database URLs, Sentry DSNs, OpenAI keys or
  credentials are present in this report.

## Endpoint Results

| Area | Endpoint / flow | HTTP result | Latency | Contract result | Notes |
| --- | --- | ---: | ---: | --- | --- |
| Health | `GET /health` | 200 | 605 ms | PASS | Returned `status`, `service`, `timestamp`, `environment`, `version`, `git_sha`, `checks`. |
| Health | `GET /health/ready` | 200 | 618 ms | PASS | Returned readiness `checks`; no DB readiness failure. |
| Health | `GET /ready` | 200 | 623 ms | PASS WITH RISKS | Legacy/deprecated route still responds; `/health/ready` remains preferred. |
| Auth | `POST /auth/register` | 201 | 857 ms | PASS | Token was present but not recorded. |
| Auth | `POST /auth/login` | 200 | 817 ms | PASS | Token was present but not recorded. |
| Auth | `GET /auth/me` | 200 | 669 ms | PASS | Returned `user`. |
| Profile | `GET /users/me` | 200 | 614 ms | PASS | Returned `user`. |
| Profile | `PATCH /users/me` | 200 | 635 ms | PASS | Sanitized discardable profile fields accepted. |
| Sets | `GET /sets?limit=3&page=1` | 200 | 768 ms | PASS | Returned `data`, `page`, `limit`, `total_returned`. |
| Cards | `GET /cards?name=Sol%20Ring&limit=3&page=1` | 200 | 645 ms | PASS | Returned `data`, `page`, `limit`, `total_returned`; card id obtained for dependent flows. |
| Cards resolve | `POST /cards/resolve` (`Sol Ring`, normal) | 200 | 848 ms | PASS | Returned `source`, `name`, `total_returned`, `data`. |
| Cards resolve token-safe | `POST /cards/resolve` (`Phyrexian Horror`, `include_tokens=true`) | 200 | 617 ms | PASS | Token-safe backend-only validation; no physical Scanner/OCR. |
| Cards printings token-safe | `GET /cards/printings?name=Phyrexian%20Horror&limit=3&dedupe=false` | 200 | 614 ms | PASS | Returned `name`, `total_returned`, `data`. Current route does not echo `limit`; API map was updated. |
| Decks | `POST /decks` basic discardable deck | 200 | 622 ms | PASS | Returned deck id/name/format/meta fields. |
| Decks | `GET /decks/:id` basic deck | 200 | 628 ms | PASS | Returned deck detail fields. |
| Decks | `POST /decks/:id/validate` basic deck | 200 | 639 ms | PASS | Returned `ok`, `format`, `deck_id`; validation details are route/service-owned. |
| Decks | `GET /decks/:id/export` basic deck | 200 | 622 ms | PASS | Returned `deck_name`, `format`, `text`, `card_count`. |
| AI Generate | `POST /ai/generate` async start | 202 | 640 ms | PASS | Returned `job_id`, `status`, `poll_url`, `poll_interval_ms`, cache/timing keys. |
| AI Generate | `GET /ai/generate/jobs/:id` | 200 | 652 ms | PASS | Job completed and returned `result`; generated deck payload was usable for a deck create attempt. |
| Decks | `POST /decks` generated valid candidate | 200 | 760 ms | PASS | Generated Standard deck candidate was accepted by backend deck creation. |
| Decks | `GET /decks/:id` generated deck | 200 | 834 ms | PASS | Generated deck detail returned. |
| Decks | `POST /decks/:id/validate` generated deck | 200 | 635 ms | PASS | Backend validate route returned 200 for generated deck candidate. |
| AI Optimize | `POST /ai/optimize` async start | 202 | 648 ms | PASS WITH RISKS | Valid generated deck id was accepted and async polling URL returned. |
| AI Optimize | `GET /ai/optimize/jobs/:id` | 200 | 628-643 ms | PASS WITH RISKS | Polling contract worked, but the job reached a failed terminal state with an error payload instead of a completed optimization result. No 5xx or timeout occurred. Treat optimize quality/result as not proven in this battery. |
| Binder | `POST /binder` | 201 | 629 ms | PASS | Created discardable binder item. |
| Binder | `GET /binder?page=1&limit=5` | 200 | 647 ms | PASS | Returned `data`, `page`, `limit`, `total`. |
| Binder | `PUT /binder/:id` | 200 | 627 ms | PASS | Returned `message`, `id`. |
| Binder cleanup | `DELETE /binder/:id` | 204 | 622 ms | PASS | Discardable binder item deleted. |
| Marketplace | `GET /community/marketplace?page=1&limit=3` | 200 | 629 ms | PASS | Returned `data`, `page`, `limit`, `total`. |
| Trades | `GET /trades?page=1&limit=5` | 200 | 633 ms | PASS | Returned `data`, `page`, `limit`, `total`. |
| Trades | `PUT /trades/:id/status` | skipped | n/a | NOT PROVEN | Not safe without an existing owned trade in the discardable account. |
| Notifications | `GET /notifications?page=1&limit=5` | 200 | 616 ms | PASS | Returned `data`, `page`, `limit`, `total`. |
| Notifications | `GET /notifications/count` | 200 | 608 ms | PASS | Returned `unread`. |
| Notifications | `PUT /notifications/read-all` | 200 | 610 ms | PASS | Returned `marked_read`; safe/idempotent for discardable user. |
| Conversations | `GET /conversations?page=1&limit=5` | 200 | 641 ms | PASS | Returned `data`, `page`, `limit`, `total`. |
| Conversations | `GET /conversations/unread-count` | 200 | 618 ms | PASS | Returned `unread`. |
| Community | `GET /community/users` without `q` | 400 | 611 ms | PASS | Expected 400; `q` is required by contract. |
| Community | `GET /community/users?q=qa&page=1&limit=3` | 200 | 616 ms | PASS | Returned `data`, `page`, `limit`, `total`. |
| Market | `GET /market/movers?limit=3&min_price=0` | 200 | 4618 ms | PASS WITH RISKS | Returned movers shape; noticeably slower than the rest of the battery but no timeout. |
| Deck cleanup | `DELETE /decks/:id` | 204 | 610-612 ms | PASS | Two discardable decks deleted. |

## Expected vs Unexpected Errors

- Expected 4xx:
  - `GET /community/users` without `q` returned 400 by contract.
  - A preliminary misuse of `POST /cards/resolve` with `include_tokens=true` for
    non-token `Sol Ring` returned 404. Source-code evidence shows this is
    expected because token mode intentionally filters local exact search to token
    rows. Normal `Sol Ring` resolution without token mode passed.
- Unexpected 4xx: none in the final valid app-facing calls.
- 5xx: none observed.
- Timeouts: none observed.
- Slow calls: `/market/movers` took 4618 ms. Keep watching this route because it
  depends on price-history aggregation.

## Shape Divergences and API Map Updates

- `POST /cards/resolve` normal public/source shape is
  `{source, name, total_returned, data}`, with optional `resolution` only for
  controlled fuzzy/local matching. The previous API map over-emphasized a
  resolution object as the normal response.
- `GET /cards/printings` returns `{name, total_returned, data}` and does not echo
  `limit`.
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md` was updated for these proven card
  contract details.

## Risks and Pending Items

- Physical Scanner was ignored by design; this report does not prove camera,
  OCR, MLKit, frame quality, token recognition UX or scanner runtime behavior.
- AI Optimize async transport and job polling were proven, but the sampled job
  ended in a failed terminal state. Because AI optimize is experimental and can
  fail quality gates, this is `PASS WITH RISKS` rather than a clear backend bug.
  A future optimize-specific QA should capture a known-good seeded deck and
  assert completed-result quality separately.
- Trade status mutation remains `NOT PROVEN` in this battery because mutating a
  real trade was not safe with the discardable account.
- Market movers passed but had the highest latency in this run.

## Validation Commands

- Repository sync/status: `git status`, `git fetch origin master`,
  `git pull --ff-only origin master`.
- Endpoint/consumer evidence: attempted `rg`; local shell did not have `rg`
  installed, so targeted Python source searches and `find` over route/provider
  paths were used instead.
- Final docs gate: `git diff --check`.
- Final obvious secret scan over changed docs was run before commit.
