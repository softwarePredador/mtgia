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
