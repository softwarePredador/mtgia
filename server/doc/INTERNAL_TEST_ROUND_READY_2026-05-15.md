# ManaLoom Internal Test Round Ready - Non-Scanner - 2026-05-15

## Verdict

**PASS_WITH_RISKS - ready to distribute to internal testers in the non-scanner scope.**

The round is not blocked for controlled internal testing on the public backend
`https://evolution-cartinhas.8ktevp.easypanel.host`, using iPhone 15 Simulator as
the primary runtime proof. Scanner, camera, OCR, MLKit physical capture, physical
devices and real push delivery remain **DEFERRED / NOT PROVEN** and are not
acceptance items for this cycle.

Do not publish secrets, tokens, JWTs, `SENTRY_DSN`, `DATABASE_URL`,
`OPENAI_API_KEY`, full QA e-mails, passwords, raw prompts or complete decklists.

## Baseline

| Item | Status |
| --- | --- |
| Branch | `master`, synchronized with `origin/master` before the round |
| Working tree before edits | Clean |
| Public backend | `https://evolution-cartinhas.8ktevp.easypanel.host` |
| Public `/health` | PASS, HTTP 200, `status=healthy`, `environment=production` |
| Public backend git SHA | `5e7105cadb2016f4728096c6ce0ce08cfa1d0f82` |
| Runtime target | iPhone 15 Simulator |
| Physical device | Not used |
| Scanner/camera/OCR | **DEFERRED / NOT PROVEN** |

Docs reviewed for this decision:

- `docs/qa/MANALOOM_INTERNAL_TEST_CHECKLIST_2026-05-15.md`
- `server/doc/INTERNAL_USER_TEST_HANDOFF_NON_SCANNER_2026-05-15.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `server/manual-de-instrucao.md`

## Release-readiness checks

| Check | Result |
| --- | --- |
| `flutter analyze lib test integration_test --no-version-check` | PASS, no issues found |
| `flutter test test --no-version-check` | PASS, 560 tests |
| Public `GET /health` | PASS |
| Public `GET /cards?limit=1` | PASS, expected paginated shape |
| Public `GET /sets?limit=1` | PASS, expected paginated shape |
| Public `POST /auth/register` with disposable QA user | PASS, token received but not logged |
| Public `POST /ai/generate` async | PASS, HTTP 202 then completed |
| Generate async summary | 1 commander, 46 cards in summarized result, validation OK |
| App label/icon config | PASS: Android `android:label=\"ManaLoom\"`, iOS `CFBundleDisplayName=ManaLoom`, pubspec package `manaloom` |
| Scanner scope marker | PASS: scanner/camera/OCR explicitly deferred in checklist/handoff/audit |

The generate probe was intentionally sanitized: no JWT, full QA e-mail, password,
raw prompt response, complete decklist or deck id is persisted in this document.

## iPhone 15 Simulator runtime

Runtime proof was executed on `iPhone 15`
`F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, runtime
`com.apple.CoreSimulator.SimRuntime.iOS-17-4`, against the public backend.

| Area | Status | Evidence summary |
| --- | --- | --- |
| iPhone 15 Simulator availability | PASS | Simulator was booted and used. |
| Backend public health from runtime round | PASS | `/health` returned HTTP 200 healthy. |
| Auth/register | PASS partial | Register/login were proven through app harnesses with disposable QA users. |
| Search cards | PASS | Card search and detail opened without crash. |
| Sets/search catalog | PASS | Set search/detail and empty/list states were validated. |
| Collection entrypoints | PASS | Binder, Marketplace, Trades and Sets tabs rendered/navigated without crash. |
| Deck generate async/save/detail/validate | PASS | Async job accepted, preview loaded, deck saved, details opened and validation succeeded. |
| Optimize | PARTIAL / NOT PROVEN apply | Friendly `OPTIMIZE_NEEDS_REPAIR` / `rebuild_guided` path was shown; preview/apply swaps were not proven. |
| Binder editor | PASS partial | Add/edit/delete passed before the broader trade harness blocked later. |
| Marketplace/trade lifecycle | FAIL partial | Marketplace/proposal/accept advanced, but trade message persistence failed. |
| Direct messages | NOT PROVEN | Public backend rate limit returned 429 during the second login scenario. |
| Notifications | PARTIAL | Trade notification types were observed before the later blocked portion. |
| Life Counter / Lotus | PASS | Canonical 2-player session loaded/restored on simulator. |
| Scanner/camera/OCR | DEFERRED | Out of scope; no scanner harness was executed. |
| Push/physical device | DEFERRED | Out of scope for this simulator-only round. |

## Accepted risks for tester distribution

| Risk | Decision |
| --- | --- |
| Trade chat persistence | Accepted for controlled internal testing, but testers must flag trade-message issues as P1/P2 depending on reproducibility. The runtime saw message UI feedback, while `GET /trades/:id/messages` returned total 0. |
| Public backend auth rate limit | Accepted with tester pacing. Direct-message proof was blocked by 429 after repeated QA login attempts, not by an app crash. |
| Optimize apply | Accepted as limited coverage. Safe no-op/rebuild guidance is acceptable, but apply preview remains NOT PROVEN in this round. |
| AI latency | Accepted. Async/progress UX is the mitigation; slow jobs should be reported with timestamp and sanitized flow notes. |
| Scanner/camera/OCR | Deferred. Any scanner report is out of scope and must not block this non-scanner release. |
| Push delivery and physical devices | Deferred. Simulator-only proof does not claim APNs/FCM or physical-device readiness. |
| Public QA data created | Accepted. Disposable users/decks/binder/trade artifacts may exist on the public backend; no secrets or full decklists are documented. |

## Suggested internal build/run commands

For simulator-based internal QA:

```bash
cd app
flutter run -d "iPhone 15" \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host
```

For a simulator debug build artifact:

```bash
cd app
flutter build ios --debug --simulator \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host
```

Before cutting any signed/TestFlight-style build, inject observability secrets only
through the approved secret store and do not commit them:

```bash
cd app
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host
```

## Tester checklist

1. Use only disposable QA accounts and redact them as `qa+...@<redacted>`.
2. Confirm public `/health` is healthy before starting a session.
3. Cover auth, profile, cards/search, sets, decks, Generate AI, Validate, Binder,
   Marketplace/Trades, Messages, Notifications and Life Counter.
4. Do not test scanner, camera, OCR, MLKit physical capture, physical devices or
   real push as release acceptance in this cycle.
5. Do not include secrets, tokens, full e-mails, passwords, raw prompts, complete
   decklists or private messages in reports/screenshots.
6. Treat trade-message persistence, direct-message 429s and optimize apply gaps as
   known risks; still report fresh reproductions with sanitized steps.
7. Classify launch/login crash, backend outage, data loss or private data exposure
   as P0; classify core non-scanner flow failures as P1; scanner issues are out of
   scope for this round.

Final distribution status: **ready for controlled internal testers with risks**.
