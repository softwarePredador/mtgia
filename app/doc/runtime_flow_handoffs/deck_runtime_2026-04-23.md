# Runtime Flow Handoff

## Target

- local backend -> register -> create Commander deck -> deck details -> optimize -> apply -> validate
- app smoke harness -> deck details -> optimize -> preview -> apply -> validate

## Runtime Owner

Agent: `ManaLoom Deck Runtime E2E`

## Fix Owner

Agent: `both`

## Status

Verdict: `Approved for backend runtime path / manual app tap proof blocked by CLI-only session`

## Runtime Environment

Date: `2026-04-23`

Device type: `macOS CLI + local Dart Frog backend + Flutter test harness`

Device id: `n/a`

Backend target: `http://127.0.0.1:8081`

Launch command: `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_support_test.dart test/core/api/api_client_request_id_test.dart`

Backend command: `cd server && PORT=8081 dart run .dart_frog/server.dart`

## Account Used

Identifier: `runtime.e2e.20260423@example.com`

How it was created: `POST /auth/register` during live backend validation.

## Navigation Path

- `POST /auth/register`
- `POST /auth/login`
- `GET /cards?name=Talrand, Sky Summoner&limit=1`
- `POST /decks` with commander-only seed
- `GET /decks/:id`
- `POST /ai/optimize`
- `GET /ai/optimize/jobs/:id`
- `POST /decks/:id/cards/bulk`
- `POST /decks/:id/validate`
- app proof used this round: `DeckDetailsScreen smoke -> optimize -> preview -> apply -> validate`

## Evidence

Fresh evidence captured this round: Yes

- Screenshots: none
- Flutter log: focused deck-flow suite passed in current session
- Backend log: local server on `:8081` returned `GET /health -> 200`; live Talrand flow returned `bulk 200`, `validate 200`, `final_total_cards 100`
- Additional artifacts:
  - `/Users/desenvolvimentomobile/.copilot/session-state/6fd06d45-43da-4f7b-8c91-0172939a9fce/files/commander_only_validation_2026-04-23/latest_summary.json`
  - `/Users/desenvolvimentomobile/.copilot/session-state/6fd06d45-43da-4f7b-8c91-0172939a9fce/files/commander_only_validation_2026-04-23/latest_summary.md`

## Observed Result

The live backend path passed for `Talrand, Sky Summoner`: account creation, login, commander-only deck creation, deck details fetch, optimize polling, bulk apply, and validate all succeeded against `http://127.0.0.1:8081`. The final deck reached `100` cards and the optimize response reported `Base de mana equilibrada`.

The fresh commander-only runner on the same backend stayed at `8 passed / 11 failed`, so the 2026-04-21 report is still materially current. The missing proof is a real tap-driven app run for `login/register -> create/generate deck -> details -> optimize -> apply -> validate`; this CLI session has device discovery but no UI automation for those taps, and the repo does not yet contain an integration test for that main deck journey.

Update 2026-04-27: `server/bin/mana_loom_deck_runtime_e2e.dart --apply` was executed against `TEST_API_BASE_URL=http://127.0.0.1:8081` and passed `19/19` Commander-only backend runtime cases. This proves the backend path `login/register -> create deck -> optimize -> bulk apply -> validate` for the current corpus. The remaining gap is still tap-driven app UI proof.

A small safe app-side fix was applied in this round: `applyOptimizationWithIds` now filters additions outside commander identity before saving, which reduces blast radius for cases like `Kozilek` when the backend returns an illegal suggestion.

## Stop Point

Stopped before manual app login/register on emulator/device. Backend live validation and app smoke validation completed; the remaining gap is a tap-driven app E2E for auth + deck creation.

## Findings

### Finding 1 - Manual app runtime proof gap

Severity: medium

Area: app runtime coverage

Problem: The main deck journey does not have a real integration test or CLI-driven tap automation for `login/register -> create/generate deck -> details -> optimize -> apply -> validate`.

Evidence: `flutter devices` listed usable targets, but the only app proof available in-session was widget/provider smoke; the live runtime proof came from direct HTTP against the backend.

Likely owner: `ManaLoom App Release Engineer`

Likely file/module: `app/integration_test/`, `app/test/features/decks/screens/deck_details_screen_smoke_test.dart`, auth/deck flow screens

Smallest next action: add one integration test on `macos` or `chrome` that logs in, creates one commander deck, opens details, runs optimize, applies, and validates.

### Finding 2 - Commander-only fail classification (report 2026-04-21)

| Commander | Reported fail | Fresh 2026-04-23 check | Likely owner | Likely file/module | Smallest next action |
| --- | --- | --- | --- | --- | --- |
| `Auntie Ool, Cursewretch` | mana base alert | worsened to `basic_count=41`, guaranteed basics used, black still short | `ManaLoom Server Integrations Engineer` | `server/lib/ai/optimize_complete_support.dart`, `server/routes/ai/optimize/index.dart` | cap basic overflow and force black-source floor before final payload |
| `Atraxa, Praetors' Voice` | mana base alert | still short on `U` | `ManaLoom Server Integrations Engineer` | `server/lib/ai/optimize_complete_support.dart`, `server/routes/ai/optimize/index.dart` | raise four-color source quotas before `post_analysis` is accepted |
| `Muldrotha, the Gravetide` | mana base alert | still short on `U/G` | `ManaLoom Server Integrations Engineer` | `server/lib/ai/optimize_complete_support.dart`, `server/routes/ai/optimize/index.dart` | tune Sultai source balancing in commander-only completion |
| `Isshin, Two Heavens as One` | mana base alert | still short on `W/R` | `ManaLoom Server Integrations Engineer` | `server/lib/ai/optimize_complete_support.dart`, `server/routes/ai/optimize/index.dart` | tune Mardu land mix and color-source floor |
| `Edgar Markov` | mana base alert | still short on `B` | `ManaLoom Server Integrations Engineer` | `server/lib/ai/optimize_complete_support.dart`, `server/routes/ai/optimize/index.dart` | increase black weighting in Mardu vampire completion |
| `Miirym, Sentinel Wyrm` | mana base alert | still short on `U/R` | `ManaLoom Server Integrations Engineer` | `server/lib/ai/optimize_complete_support.dart`, `server/routes/ai/optimize/index.dart` | tune Temur source allocation before final response |
| `Korvold, Fae-Cursed King` | mana base alert | still short on `B/G` | `ManaLoom Server Integrations Engineer` | `server/lib/ai/optimize_complete_support.dart`, `server/routes/ai/optimize/index.dart` | tighten Jund source allocation for commander-only seeds |
| `Kaalia of the Vast` | `POST /ai/optimize` returned `422` (`COMPLETE_QUALITY_PARTIAL`) | now completes, but still ends with mana-base warning on `W/B` | `both` | `server/lib/ai/optimize_complete_support.dart`, `server/routes/ai/optimize/index.dart`, `app/lib/features/decks/widgets/deck_optimize_flow_support.dart` | server: stabilize Kaalia completion quality; app: map `COMPLETE_QUALITY_PARTIAL` to explicit guided fallback instead of generic block |
| `Jodah, the Unifier` | mana base alert | still short on `W/U/G` | `ManaLoom Server Integrations Engineer` | `server/lib/ai/optimize_complete_support.dart`, `server/routes/ai/optimize/index.dart` | tighten 5c source targets and nonbasic prioritization |
| `Kozilek, the Great Distortion` | illegal additions caused bulk/validate failure | still failing; fresh run produced off-identity `Swan Song` and validate kept deck at `1` card | `both` | `server/routes/ai/optimize/index.dart`, `server/lib/ai/optimize_complete_support.dart`, `app/lib/features/decks/providers/deck_provider.dart`, `app/test/features/decks/providers/deck_provider_test.dart` | server: filter off-identity additions before response; app: defensive filter added this round, keep regression test green |
| `Sword Coast Sailor + Wilson, Refined Grizzly` | `POST /ai/optimize` returned `422` (`COMPLETE_QUALITY_PARTIAL`) | still `422` | `both` | `server/lib/ai/optimize_complete_support.dart`, `server/routes/ai/optimize/index.dart`, `app/lib/features/decks/widgets/deck_optimize_flow_support.dart` | server: improve partner/background completion quality or protected-rejection semantics; app: route this code to explicit rebuild/block UX |

## Commands Run

- `git --no-pager status --short --branch`
- `flutter --version`
- `flutter devices`
- `dart --version`
- `curl -sS http://127.0.0.1:8080/health`
- `curl -sS http://127.0.0.1:8081/health`
- `lsof -nP -iTCP:8080 -sTCP:LISTEN`
- `cd server && PORT=8081 dart run .dart_frog/server.dart`
- `curl -sS -i http://127.0.0.1:8081/health`
- `cd server && TEST_API_BASE_URL=http://127.0.0.1:8081 ... dart run bin/run_commander_only_optimization_validation.dart --apply`
- `python3` live backend flow for `register -> login -> create deck -> details -> optimize -> bulk -> validate`
- `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_support_test.dart test/core/api/api_client_request_id_test.dart`

## Validation Notes

- emulator validated: `no`
- physical device validated: `no`
- optimize reached: `yes`
- post-optimize result observed: `yes`
- focused app flow validated: `yes`
- `app/pubspec.lock` pre-existing local change was left untouched

## Reproduction Notes For Fix Agent

Shortest backend reproduction:

1. Start local backend on `:8081`.
2. Run `server/bin/mana_loom_deck_runtime_e2e.dart --dry-run` first, then use `--apply` against `TEST_API_BASE_URL=http://127.0.0.1:8081` only when real backend writes are intended.
3. Inspect `Kozilek`, `Sword Coast Sailor + Wilson`, and any mana-alert commanders in the fresh summary artifact.

Shortest app reproduction:

1. Run the focused app suite in `app/test/features/decks/providers/deck_provider_test.dart` and `app/test/features/decks/screens/deck_details_screen_smoke_test.dart`.
2. For live runtime, add a new integration test or perform a manual tap run on `macos`/`chrome` with `API_BASE_URL=http://127.0.0.1:8081`.
