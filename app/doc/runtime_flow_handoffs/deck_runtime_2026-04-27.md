# Runtime Flow Handoff

## Target

- widget runtime harness -> register -> generate Commander deck -> save -> deck details -> optimize -> preview -> apply -> validate

## Runtime Owner

Agent: `ManaLoom Deck Runtime E2E`

## Fix Owner

Agent: `ManaLoom App Release Engineer`

## Status

Verdict: `Approved for widget runtime path / live emulator-device taps not proven`

## Runtime Environment

Date: `2026-04-27`

Device type: `Flutter widget test harness via GoRouter`

Device id: `n/a`

Backend target: `mocked ApiClient`

Launch command: `cd app && flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart`

## Scope Proven This Round

### UI real

- `RegisterScreen`
- `DeckListScreen`
- `DeckGenerateScreen`
- `DeckDetailsScreen`
- `GoRouter` auth redirect into `/decks`
- real widget interactions for:
  - register form submit
  - empty deck list CTA
  - generate prompt submit
  - save generated deck
  - open deck details
  - open optimize sheet
  - preview suggestions
  - apply changes

### Mocked / controlled

- `ApiClient` responses for:
  - `POST /auth/register`
  - `POST /ai/generate`
  - `POST /cards/resolve/batch`
  - `POST /decks`
  - `GET /decks`
  - `GET /decks/:id`
  - `POST /decks/:id/pricing`
  - `POST /ai/archetypes`
  - `POST /ai/optimize`
  - `PUT /decks/:id`
  - `POST /decks/:id/validate`

### Not proven

- live backend connectivity from app runtime
- iPhone 15 Simulator taps
- shell/home tab navigation before entering `/decks`

iPhone 15 Simulator follow-up is now owned by `Mobile Runtime Device QA` using:

- `app/doc/runtime_flow_handoffs/IPHONE15_SIMULATOR_RUNTIME_RUNBOOK.md`
- target output: `app/doc/runtime_flow_handoffs/deck_runtime_iphone15_simulator_YYYY-MM-DD.md`

## Navigation Path

- `/register`
- `/decks`
- `/decks/generate`
- `/decks`
- `/decks/:id`
- optimize sheet -> preview -> apply

## Evidence

Fresh evidence captured this round: `yes`

- focused Flutter suite result: `67 passed / 0 failed`
- new runtime widget proof:
  - file: `app/test/features/decks/screens/deck_runtime_widget_flow_test.dart`
  - flow: `register -> generate -> save -> details -> optimize -> apply -> validate`
  - result: `passed`
- existing supporting proofs re-run and still green:
  - `app/test/features/decks/screens/deck_details_screen_smoke_test.dart`
  - `app/test/features/decks/providers/deck_provider_test.dart`
  - `app/test/features/decks/providers/deck_provider_support_test.dart`
  - `app/test/features/decks/widgets/deck_optimize_flow_support_test.dart`

## Observed Result

The app now has a reusable widget runtime harness covering the ManaLoom Commander journey through real screens instead of direct HTTP only. In the fresh run, the harness registered a user, reached the empty deck state, opened the generator, saved a Commander deck, opened deck details, requested optimize suggestions, previewed the result, applied the change set, and hit deck validation successfully.

This closes the previous gap for app-side flow proof at widget level. The remaining runtime gap is integration execution against a live backend on iPhone 15 Simulator; that is still `not proven`.

## Commands Run

- `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart`
- `cd app && dart format test/features/decks/screens/deck_runtime_widget_flow_test.dart`
- `cd app && flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart`
- `cd app && flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart`

## Smallest Next Actions

1. Add one `integration_test/` or device-runner variant that swaps the mocked `ApiClient` for `API_BASE_URL=http://127.0.0.1:8081`.
2. Reuse the same route harness and assertions, but capture screenshot/log artifacts for emulator or physical-device proof.
