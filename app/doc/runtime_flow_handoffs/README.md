# Runtime Flow Handoffs

This folder is for live end-to-end runtime proof of the ManaLoom deck journey.

It is not the same as visual QA.

The purpose here is:

1. run the app on emulator or physical device
2. create or log into a real account
3. create a commander deck through the current UI
4. open deck details
5. trigger optimize
6. capture screenshots and logs
7. document where the flow passes or breaks
8. hand off the exact scope to the fix agents

## Primary owner

- QA/runtime owner: `ManaLoom Deck Runtime E2E`
- iPhone 15 Simulator owner: `Mobile Runtime Device QA`

## iPhone 15 Simulator runbook

Use this runbook for the primary simulator proof:

- `app/doc/runtime_flow_handoffs/IPHONE15_SIMULATOR_RUNTIME_RUNBOOK.md`

The iPhone 15 Simulator proof is not complete unless the handoff includes the simulator id from `flutter devices` or `xcrun simctl list devices available`, backend URL `http://127.0.0.1:8081`, backend health proof, exact Flutter command, and logs/artifacts.

Latest iPhone 15 Simulator attempt:

- `app/doc/runtime_flow_handoffs/deck_runtime_iphone15_simulator_2026-04-27.md`

## Physical M2006 fallback runbook

Use this only when explicit physical Android proof is requested:

- `app/doc/runtime_flow_handoffs/M2006_DEVICE_RUNTIME_RUNBOOK.md`

## Safe backend runner

The repository now has a safe CLI entrypoint for the backend Commander runtime:

```bash
cd server
dart run bin/mana_loom_deck_runtime_e2e.dart --dry-run
```

`--dry-run` is the default and does not authenticate, create decks, call optimize, apply cards, or validate decks.

Use explicit apply only when real backend writes are intended:

```bash
cd server
PORT=8081 dart run .dart_frog/server.dart
TEST_API_BASE_URL=http://127.0.0.1:8081 dart run bin/mana_loom_deck_runtime_e2e.dart --apply
```

The runner verifies `GET /health` and `POST /auth/login` before writes. If the URL points to a static server or wrong port, it stops before `login/register`.

## Typical fix owners

- app/runtime/navigation/auth/UI issue:
  - `ManaLoom App Release Engineer`
- backend/contract/optimize issue:
  - `ManaLoom Server Integrations Engineer`
- mixed issue:
  - `both`

## Fresh evidence rule

Each runtime handoff must be based on a fresh execution in the current session.

Old screenshots and old logs are historical comparison only.

## Suggested file naming

- `deck_runtime_emulator_YYYY-MM-DD.md`
- `deck_runtime_device_YYYY-MM-DD.md`
- `deck_runtime_auth_blocker_YYYY-MM-DD.md`
- `deck_runtime_optimize_blocker_YYYY-MM-DD.md`

## Proof folders

Use fresh proof folders such as:

- `app/doc/runtime_flow_proofs_YYYY-MM-DD_emulator`
- `app/doc/runtime_flow_proofs_YYYY-MM-DD_device`

## Verdict values

Use one of:

- `Approved for this runtime path`
- `Blocked in auth`
- `Blocked in deck creation`
- `Blocked in deck details`
- `Blocked in optimize`
- `Blocked in post-optimize apply/validate`
- `Blocked by backend connectivity`
- `Blocked by physical-device backend reachability`
