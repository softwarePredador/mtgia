# Full Project Audit Master Report - 2026-05-15

## Verdict

Overall ManaLoom non-scanner full-stack audit status: **PASS_WITH_RISKS**.

The audited backend, app, state/cache, Commander/AI/deck-rules, and runtime test
tracks are documented and sanitized. Scanner/camera/OCR/MLKit are explicitly
**DEFERRED / NOT PROVEN** and were not touched as functional scope.

No secrets, tokens, JWTs, Sentry DSNs, database URLs, OpenAI keys, real emails,
sensitive payloads, Authorization headers, or full decklists are included here.

## Track status

| Track | Status | Output |
|---|---|---|
| Track A - Backend/Data Map | PASS_WITH_RISKS | `server/doc/FULL_BACKEND_DATA_FLOW_AUDIT_2026-05-15.md` |
| Track B - App Screens/Fields | PASS_WITH_RISKS | `app/doc/FULL_APP_SCREEN_FIELD_AUDIT_2026-05-15.md` |
| Track C - State/Realtime/Cache | PASS_WITH_RISKS | `server/doc/FULL_STATE_REALTIME_CACHE_AUDIT_2026-05-15.md` |
| Track D - Commander/AI/Deck Rules | PASS_WITH_RISKS | `server/doc/FULL_COMMANDER_AI_DECK_RULES_AUDIT_2026-05-15.md` |
| Track E - Runtime/Test Matrix | PASS_WITH_RISKS | `server/doc/FULL_PROJECT_VALIDATION_MATRIX_2026-05-15.md` |

## Bugs fixed

| Severity | Area | Fix | Tests / evidence |
|---|---|---|---|
| P0 | Commander deck mutation | `POST /decks/:id/cards` rejects adding the selected commander into the 99 by same `card_id`. | `server/test/decks_incremental_add_test.dart` |
| P1 | Commander validation | `DeckRulesService` rejects a non-commander row with the same normalized commander name, covering alternate printings. | `server/test/decks_incremental_add_test.dart`; focused Commander/rules tests |
| P1 | Color identity | `DeckRulesService` loads `mana_cost` and passes it to identity resolution, reducing false negatives when DB color arrays are incomplete. | `server/test/color_identity_test.dart` and focused rules tests |
| P1 | Import to existing Commander deck | `/import/to-deck replace_all=true` preserves an existing Commander/Brawl commander when the imported list has no commander. | `server/test/import_to_deck_flow_test.dart` |
| P1 | Import response semantics | `/import/to-deck.total_cards` now reports final persisted deck total, while `cards_imported` counts only submitted-list cards. | `server/test/import_to_deck_flow_test.dart`; app parser test |
| P1 | Auth/Profile stale state | Late auth/profile responses cannot persist credentials or repopulate user state after logout/account generation changes. | `app/test/features/auth/providers/auth_provider_log_sanitization_test.dart` |
| P1 | Messages stale state | Late conversation/message/unread responses are ignored after clear or active chat switch. | `app/test/features/messages/providers/message_provider_test.dart` |
| P1 | Notifications stale state | Late count/list/read responses are ignored after clear. | `app/test/features/notifications/models/notification_models_test.dart` |
| P1 | Trades stale state | Late list/detail/message responses are ignored after clear or active trade switch. | `app/test/features/trades/providers/trade_provider_test.dart` |

## Documentation updated

- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
  - documented `/users/me/plan`;
  - documented `/community/decks/following`;
  - corrected `/sets` query contract to `q`/`code`;
  - documented `/rules`;
  - clarified scanner as deferred for this non-scanner QA scope;
  - clarified `/import/to-deck` commander status fields and `total_cards`
    semantics.
- `docs/README.md`
  - added the full-stack non-scanner audit report set.
- `server/manual-de-instrucao.md`
  - recorded Tracks A-D and app screen/field audit decisions.
- New reports:
  - `server/doc/FULL_BACKEND_DATA_FLOW_AUDIT_2026-05-15.md`
  - `app/doc/FULL_APP_SCREEN_FIELD_AUDIT_2026-05-15.md`
  - `server/doc/FULL_STATE_REALTIME_CACHE_AUDIT_2026-05-15.md`
  - `server/doc/FULL_COMMANDER_AI_DECK_RULES_AUDIT_2026-05-15.md`
  - `server/doc/FULL_PROJECT_VALIDATION_MATRIX_2026-05-15.md`
  - `server/doc/FULL_PROJECT_AUDIT_MASTER_REPORT_2026-05-15.md`

## Remaining bugs / risks

| Severity | Risk | Probable files / next patch |
|---|---|---|
| P1 | `/community/decks/following` is implemented as a magic branch inside `[id].dart`. | Move to `server/routes/community/decks/following/index.dart`, keep compatibility if needed, add route contract test. |
| P1 | Some 500 handlers still risk returning raw exception text. | Harden selected routes, including `server/routes/decks/[id]/cards/index.dart`, to return sanitized client errors and log details server-side only. |
| P1 | Messages/notifications empty/error UI can mislead users when a failed fetch happens before data exists. | Add keyed error/empty states in `message_inbox_screen.dart`, `chat_screen.dart`, and `notification_screen.dart`. |
| P2 | UI state keys are incomplete across Card Search, Binder, Marketplace and Community. | Add stable loading/error/empty keys listed in `app/doc/FULL_APP_SCREEN_FIELD_AUDIT_2026-05-15.md` with widget tests. |
| P2 | `POST /ai/generate.bracket` hard power enforcement remains not proven. | Add generation scoring/validation proof if product wants bracket to be an enforced guarantee. |
| P2 | Optimize async was contract-probed, but preview/apply quality was not proven in Track E. | Run a dedicated optimize runtime/apply proof on a representative non-empty deck. |

## Commands and probes executed

Sanitized command set across the tracks:

```bash
git status --short --branch
git fetch origin master --prune
git pull --ff-only origin master
git diff --check
cd app && flutter analyze lib test integration_test --no-version-check
cd app && flutter test test --no-version-check
cd server && dart analyze bin lib routes test
cd server && dart test -r expanded
cd server && dart test test/color_identity_test.dart test/generated_deck_validation_service_test.dart test/import_list_service_test.dart test/import_parser_test.dart -r expanded
cd server && dart test test/commander_reference_deck_corpus_support_test.dart test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart test/ai_generate_performance_support_test.dart -r expanded
cd server && dart test test/mtg_rules_validation_test.dart test/optimization_validator_test.dart test/optimization_quality_gate_test.dart test/optimize_runtime_support_test.dart -r expanded
./scripts/quality_gate.sh quick
flutter test integration_test/collection_entrypoints_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=<PUBLIC_BACKEND> --dart-define=PUBLIC_API_BASE_URL=<PUBLIC_BACKEND> --reporter expanded --no-version-check
```

Public backend probes were sanitized and covered `/health`, `/health/ready`,
`/sets`, `/cards`, `/community/marketplace`, disposable auth, current user,
decks, binder, trades, messages, notifications, AI generate async, and AI
optimize async.

Final local validation after report consolidation:

```bash
cd app && dart format <changed app files>
cd server && dart format <changed server files>
cd app && flutter analyze lib test integration_test --no-version-check
cd app && flutter test <focused provider/support tests> --no-version-check
cd app && flutter test test --no-version-check
cd server && dart analyze bin lib routes test
cd server && dart test -r expanded
./scripts/quality_gate.sh quick
git diff --check
python3 <strict-secret-scan-added-and-removed-diff-lines>
```

Result: **PASS**. The strict secret scan reported no token/JWT/OpenAI key,
database URL, Sentry DSN or private-key value patterns in added/removed diff
lines.

## Accepted risks

- The public backend may contain disposable QA artifacts from safe probes; ids and
  payload details are not documented.
- AI optimize quality/apply was not proven in the Track E runtime matrix.
- Scanner/camera/OCR/MLKit remain deferred and are not a release gate for this
  non-scanner audit.
- Some lower-risk providers still rely on clearAllState without HTTP cancellation
  or global generation guards; no clear cross-account leak was proven there.

## Final status

**PASS_WITH_RISKS**. The audited non-scanner flows have no remaining P0 issue in
this report, and the clear bugs found during the audit were patched with tests.
