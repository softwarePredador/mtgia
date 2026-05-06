# User QA Battery - 2026-05-06

## Verdict

`PASS WITH SCANNER QUALITY RISK`.

The public backend was tested with the user-provided QA account. Credentials,
JWT, prompts and raw payloads were not recorded.

## Scope

- Backend: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Backend commit after fix: `f1465b2`
- User: redacted QA account
- Device runtime also attached: physical iPhone `Rafa`
  (`00008130-001C152922BA001C`)

## Important fixes during the battery

The first public API pass found an actual production bug in async AI Generate:

- `POST /ai/generate async=true` returned `202`.
- `GET /ai/generate/jobs/:id` failed with
  `Generate async recebeu resposta invalida do executor interno.`
- Root cause: async self-call used `http://<public-host>/ai/generate` behind a
  HTTPS reverse proxy, so the internal executor could receive redirect/HTML
  instead of JSON.

Fix shipped:

- `server/lib/ai_generate_internal_url_support.dart`
- `server/routes/ai/generate/index.dart`
- `server/test/ai_generate_internal_url_support_test.dart`

Post-deploy proof:

- `/health` reported commit `f1465b2`.
- Async generate accepted `202`.
- Poll completed with `result_status_code=200`.
- Result contained `generated_deck` and `validation`.

## Final public API battery

| Area | Endpoint / flow | Result | Notes |
| --- | --- | --- | --- |
| Health | `GET /health` | PASS | `200`, production healthy |
| Auth | `POST /auth/login` | PASS | `200`, token present, token not recorded |
| Auth | `GET /auth/me` | PASS | `200` |
| Profile | `GET /users/me` | PASS | `200` |
| Sets | `GET /sets` | PASS | `200`, 3 rows preview |
| Cards | `GET /cards?set=ECC` | PASS | `200`, 3 rows preview |
| Scanner backend | `POST /cards/resolve` for `Phyrexian Horror` | PASS | token rows returned, no `Phyrexian Scissor/Censor` |
| Marketplace | `GET /community/marketplace` | PASS | `200`, 3 rows preview |
| Trades | `GET /trades` | PASS | `200`, empty for this QA user |
| Notifications | `GET /notifications` | PASS | `200`, empty for this QA user |
| Conversations | `GET /conversations` | PASS | `200`, empty for this QA user |
| Community search | `GET /community/users?q=qa` | PASS | `200`, `q` is required by contract |
| AI Generate | `POST /ai/generate async=true` | PASS | `202` accepted |
| AI Generate polling | `GET /ai/generate/jobs/:id` | PASS | completed on first final poll with generated deck + validation |

Summary: `15/15` final checks passed after the async generate fix.

## Physical scanner observation

The physical scanner path is now partially proven:

- app booted on physical iPhone;
- register/login completed against public backend;
- scanner opened camera;
- MLKit/TensorFlow Lite initialized;
- live OCR stream emitted candidates;
- backend printings lookup ran against public backend.

Residual risk:

- OCR confirmed `Turtle-Duck` after reading substantial off-card text such as
  order/shipping labels.
- This is a scanner confirmation/ROI quality risk, not a backend card-resolution
  issue.

Recommended next scanner patch:

- reject candidate confirmation when non-card/order/address words dominate OCR;
- require stronger title-zone evidence before backend lookup;
- show a user-facing "move card into frame" retry state instead of confirming a
  backend-valid but weakly evidenced candidate.

## Notes

- `GET /community/users` without `q` returned `400` by design. The valid app
  call is `GET /community/users?q=<query>`.
- Local Python certificate store failed strict TLS verification; system `curl`
  and the app both validated the public host successfully.
- No secrets, JWT, database URL, OpenAI key, Sentry DSN or raw OCR image/payload
  was stored in this report.
