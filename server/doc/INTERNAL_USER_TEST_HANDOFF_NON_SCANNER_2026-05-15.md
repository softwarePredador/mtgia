# Internal User Test Handoff - Non-Scanner - 2026-05-15

## Verdict

**PASS_WITH_RISKS for internal user testing, non-scanner only.**

ManaLoom is ready for a controlled internal test with real users on the public
backend `https://evolution-cartinhas.8ktevp.easypanel.host`, while Commander
Reference expansion is paused. Scanner, camera, OCR and MLKit physical capture
remain **DEFERRED / NOT PROVEN** and are not part of this release scope.

Do not publish or persist secrets, tokens, JWTs, `SENTRY_DSN`, `DATABASE_URL`,
`OPENAI_API_KEY`, full QA e-mails, passwords, raw prompts or complete decklists.

## Release baseline

| Item | Status |
| --- | --- |
| Branch | `master`, synchronized with `origin/master` before this handoff |
| Public backend | `https://evolution-cartinhas.8ktevp.easypanel.host` |
| Public `/health` | HTTP 200, `status=healthy`, `environment=production` |
| Public `/health.git_sha` | `fca11424b72b667c2a48ac0fa5b4b0fd127238c6`, matched local `master` during the handoff probe |
| Scope | Non-scanner app/backend flows with disposable QA users |
| Scanner/camera/OCR | **DEFERRED / NOT PROVEN** |

## Commander Reference pause status

Commander Reference expansion is paused for the internal test window. The
internal release should validate the product surface already available to users,
not continue broad Commander Reference rollout.

Current promoted Commander Reference total: **24 commanders**.

| Group | Promoted commanders |
| --- | --- |
| Initial / mini-batch | Lorehold, Prosper, Aesi, Edgar, Dina, Zimone |
| Sprint 2 | Kinnan, Muldrotha, Yuriko, Winota, Atraxa |
| Sprint 3 A+B | Krenko, Light-Paws, Niv-Mizzet, Teysa, Meren, Korvold, Sythis, Urza |
| Sprint 3 C | Brago |
| Sprint 4 / latest unlock | Miirym, Feather, Ghave, Jodah |

Latest promoted state:

- `Miirym, Sentinel Wyrm`: backend public proof 5/5, scorecard 100, app runtime
  PASS_WITH_MINOR_HARNESS_FIX on iPhone 15 Simulator.
- `Feather, the Redeemed`: backend public proof 5/5 after timeout/invalid fix,
  scorecard 100, app runtime PASS on iPhone 15 Simulator.
- `Ghave, Guru of Spores`: backend public proof 5/5, scorecard 100.
- `Jodah, the Unifier`: backend public proof 5/5, scorecard 100.

Blocked or deferred:

| Commander | Status for this handoff |
| --- | --- |
| Purphoros, God of the Forge | App-runtime adjunct PASS, but not promoted; backend profile/card_stats/corpus gate still blocks promotion. |
| Veyran, Voice of Duality | Blocked; legal public proof existed, but active reference guidance/profile/card_stats/deterministic proof is missing. |
| Balan, Wandering Knight | Blocked; legal public proof existed, but active reference guidance/profile/card_stats/deterministic proof is missing. |
| Chulane, Teller of Tales | Deferred/backlog; not through the full DB-backed corpus/apply/public proof gate. |
| K'rrik, Son of Yawgmoth | Deferred/backlog; requires strict power-lane guardrails before any promotion attempt. |
| Giada, Font of Hope / Lathril, Blade of the Elves / Isshin, Two Heavens as One | Deferred backups. |

## Runtime proof already available

Recent non-scanner runtime evidence supports internal testing with known risks:

- iPhone 15 Simulator proved auth, Generate Commander, preview/save, Deck
  Details and validate for Miirym and Feather against the public backend.
- Earlier internal/staging evidence proved auth, cards/search, sets, deck
  create/import/generate/detail, optimize preview/apply/validate, binder,
  marketplace, trades, direct messages, notifications and Life Counter/Lotus
  against a real backend.
- Android physical runtime is usable with risks. Some Commander Reference
  app runs passed on `SM A135M`, but earlier runs required cellular-network
  workaround when Wi-Fi timed out on `/health`.

## Public backend smoke - non-mutating

Safe public probes performed or accepted for this handoff:

| Area | Probe | Result / expected shape |
| --- | --- | --- |
| Health | `GET /health` | HTTP 200; includes `status`, `service`, `environment`, `version`, `git_sha`, `checks`. |
| Cards | `GET /cards?limit=1` | HTTP 200; `{data,page,limit,total_returned}` with card metadata. |
| Sets | `GET /sets?limit=1` | HTTP 200; `{data,page,limit,total_returned}` with set metadata. |
| Public decks | `GET /community/decks?limit=1` | HTTP 200; `{data,page,limit,total}`; do not log complete decklists. |
| Marketplace | `GET /community/marketplace?limit=1` | HTTP 200; `{data,page,limit,total}` with nested card/owner data. |

JWT-required flows must be tested only with disposable QA users:

- `POST /auth/register`, `POST /auth/login`, `GET /auth/me`, `GET/PATCH /users/me`
- Deck CRUD, import, export, pricing, analysis and `/decks/:id/validate`
- `POST /ai/generate`, `/ai/generate/jobs/:id`
- `POST /ai/optimize`, `/ai/optimize/jobs/:id`
- Binder CRUD and stats
- Trades, trade messages and status transitions
- Direct messages/conversations
- Notifications list/count/read/read-all

## Tester setup

1. Use the internal build configured with
   `API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host` and
   `PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host`.
2. Create or receive disposable QA accounts outside this repository. In reports,
   redact them as `qa+...@<redacted>`.
3. Do not reuse personal accounts for trade/message tests.
4. Use throwaway decks and binder entries. If a bug needs card/deck examples,
   report only a short sanitized summary, not a full decklist.
5. Do not test scanner, camera or OCR in this cycle. If a scanner entry point is
   visible, record it as out-of-scope, not as a failed release blocker.

## What testers should report

Each report should include:

- Build/version and device/OS.
- Timestamp and public backend health status if visible.
- Flow area: Auth, Cards/Search, Sets, Decks, Generate AI, Optimize AI,
  Validate, Binder, Marketplace/Trades, Messages, Notifications or Life Counter.
- Steps to reproduce using sanitized data.
- Expected result and actual result.
- Screenshot or short video only if it does not expose e-mail, token, private
  messages, payment info or complete decklists.
- Network status if relevant, especially cellular vs Wi-Fi.
- Whether retry changed the result.

Bug classification:

| Severity | Meaning |
| --- | --- |
| P0 Blocker | App cannot launch/login, data loss, private data exposure, token/secret leak, or critical backend outage. |
| P1 Critical | Core non-scanner flow unusable for most testers: generate/save/validate broken, optimize blocks deck use, trades/messages cannot complete. |
| P2 Major | Important flow has workaround or intermittent failure: latency, no-op diagnostics confusion, push not delivered, marketplace/trade partial issue. |
| P3 Minor | Copy/layout/accessibility issue that does not block task completion. |
| Out of scope | Scanner/camera/OCR issues in this cycle. Mark **DEFERRED**, not release-blocking. |

## Accepted risks

| Risk | Internal-test decision |
| --- | --- |
| Scanner/camera/OCR | Deferred and not part of acceptance. If required, release becomes BLOCKED. |
| AI latency | Accepted with monitoring. Generate and optimize can be slow; async/progress UX is the user-facing mitigation. |
| Optimize safe no-op | Accepted. Quality-rejected or no-op results are valid when unsafe swaps are blocked, but copy must be clear to users. |
| Commander Reference expansion | Paused. Existing promoted commanders are monitored; new promotion work waits until after feedback triage. |
| Firebase/push | Android public-backend push has prior proof, but each internal build still needs environment-specific validation; Firebase Performance/iOS push remain watch items. |
| Android network variability | Accepted as risk; reports must identify Wi-Fi vs cellular. |
| `GET /decks/:id.commander_name` aggregate | Known instability; app/runtime validation should rely on `commander` entries and `/decks/:id/validate`. |

## Post-feedback next steps

1. Triage P0/P1 bugs first and keep Commander Reference expansion paused until
   non-scanner internal feedback is stable.
2. Re-run focused public backend health/readiness and the affected app runtime
   proof after any fix.
3. Validate push/Firebase per internal build before relying on notification
   delivery in tester instructions.
4. Decide separately when scanner/camera/OCR can leave **DEFERRED**; that requires
   fresh physical-device proof and is outside this handoff.

Final release status for this handoff: **PASS_WITH_RISKS**.
