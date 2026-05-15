# Full Project Validation Matrix - 2026-05-15

## Scope and verdict

Track E executed the feasible non-scanner validation matrix for ManaLoom on
`master` against the local repo and public backend
`https://evolution-cartinhas.8ktevp.easypanel.host`.

Overall status: **PASS_WITH_RISKS**.

Scanner/camera/OCR/MLKit: **DEFERRED / NOT PROVEN** and not used as functional
acceptance criteria.

No secrets, tokens, JWTs, Sentry DSNs, database URLs, OpenAI keys, real emails,
sensitive payloads, Authorization headers, or full decklists are included here.

## Automated validation matrix

| Area | Command / probe | Status | Sanitized result |
|---|---|---|---|
| Worktree baseline | `git status --short --branch` | PASS_WITH_RISKS | On `master`; audit docs/code changes from Tracks A-D were present and preserved. |
| Device discovery | `flutter devices`; `xcrun simctl list devices available` | PASS | iPhone 15 Simulator available and booted on iOS 17.4 runtime. |
| App analyze | `cd app && flutter analyze lib test integration_test --no-version-check` | PASS | No issues found. |
| Server analyze | `cd server && dart analyze bin lib routes test` | PASS | No issues found. |
| Server tests | `cd server && dart test -r expanded` | PASS | Exit code 0. |
| App tests | `cd app && flutter test test --no-version-check` | PASS_WITH_RISKS | First run returned exit 1 with oversized/truncated output; immediate compact rerun returned exit 0. No clear code issue was captured. |
| Public health | `GET /health` | PASS | HTTP 200, healthy production shape. |
| Public readiness | `GET /health/ready` | PASS | HTTP 200, ready shape. |
| Public sets | `GET /sets?limit=2&page=1` | PASS | HTTP 200, two rows, paginated shape. |
| Public cards | `GET /cards?name=sol ring&limit=2&page=1` | PASS | HTTP 200, two rows, paginated shape. |
| Public marketplace | `GET /community/marketplace?limit=1&page=1` | PASS | HTTP 200, one row, paginated shape. |
| Disposable auth | `POST /auth/register` generated QA account | PASS | HTTP 201; token received but not printed or saved in docs. |
| Current user | `GET /auth/me` | PASS | HTTP 200; user keys summarized only. |
| Decks list | `GET /decks` | PASS | HTTP 200; disposable account initially had no decks. |
| Binder | `GET /binder`, `GET /binder/stats` | PASS | HTTP 200; empty/list/stat shapes valid. |
| Trades | `GET /trades` | PASS | HTTP 200; empty list shape valid. |
| Messages | `GET /conversations`, `GET /conversations/unread-count` | PASS | HTTP 200; empty/count shapes valid. |
| Notifications | `GET /notifications/count`, `GET /notifications` | PASS | HTTP 200; empty/count shapes valid. |
| Deck create | `POST /decks` empty disposable Commander deck | PASS_WITH_RISKS | HTTP 200; deck id received but not printed. Empty QA artifact may remain in public backend. |
| AI generate async | `POST /ai/generate async=true` and job poll | PASS_WITH_RISKS | HTTP 202 accepted; job completed HTTP 200 with validation OK. Prompt output/decklist not printed. |
| AI optimize async | `POST /ai/optimize async=true` on empty disposable deck and job poll | PASS_WITH_RISKS | HTTP 202 accepted; job final status failed. This proves async acceptance/friendly failure path only, not optimize quality/apply. |
| iPhone 15 runtime smoke | `flutter test integration_test/collection_entrypoints_runtime_test.dart -d "iPhone 15" ...` | PASS | Collection hub rendered Binder, Marketplace, Trades and Colecoes tabs; marketplace/sets hit public backend; unauthenticated binder/trades returned expected 401 without crash. |
| Scanner/camera/OCR/MLKit | Not run | DEFERRED | Confirmed out of functional scope and untouched. |
| Final local rerun after consolidation | format, app/server analyze, focused tests, full app tests, full server tests | PASS | All commands completed with exit code 0 after the final doc/import parser updates. |
| Quick quality gate | `./scripts/quality_gate.sh quick` | PASS | Backend quick tests and frontend analyze passed. |
| Diff whitespace | `git diff --check` | PASS | No whitespace errors. |
| Strict secret scan | Added/removed diff-line scan for tokens, JWTs, OpenAI keys, DB URLs, Sentry DSNs and private keys | PASS | No strict secret-value patterns found; output recorded pattern counts only. |

## iPhone 15 smoke command

```bash
cd app
flutter test integration_test/collection_entrypoints_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --reporter expanded \
  --no-version-check
```

Result: **PASS**. Xcode emitted simulator architecture warnings involving native
camera/MLKit/Firebase-related pods, but the non-scanner smoke built and passed.

## Accepted risks

- Full app test had one unexplained failed attempt and then passed on immediate
  rerun.
- Optimize async was probed on an empty disposable deck; preview/apply quality
  was not proven in this Track E run.
- Public disposable QA artifacts may exist; this document records only sanitized
  status/counts.
- Scanner/camera/OCR/MLKit remain **DEFERRED / NOT PROVEN**.

## Final classification

**PASS_WITH_RISKS** for the validation matrix. No P0 validation blocker remains
for the audited non-scanner scope.
