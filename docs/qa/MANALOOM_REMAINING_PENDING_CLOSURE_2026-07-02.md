# ManaLoom Remaining Pending Closure - 2026-07-02

## Scope

Closed or validated the remaining items after the null-owner deck cleanup:

- Hermes SQLite `oracle_hash` warning for trusted battle rules.
- `/sets` latency visibility and response contract.
- iOS 26+ simulator warning and runtime validation.

## Hermes SQLite oracle_hash

Implemented `backfill_battle_rule_oracle_hashes.py` for the local Hermes SQLite
cache only. It targets trusted executable rows in `battle_card_rules` with:

- `source = curated`
- `review_status in (verified, active)`
- `execution_status = auto`
- missing `oracle_hash`

The hash is calculated from the normalized Oracle text in `card_oracle_cache`.

Evidence:

- Dry run candidates: 1,418
- Applied rows: 1,418
- Re-run after concurrent card-rule changes: 16 additional rows applied
- Missing Oracle text skips: 0
- Follow-up contract audit: 49 checks, 49 pass
- Remaining trusted executable rules missing `oracle_hash`: 0

Generated audit:

- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_after_oracle_hash_backfill.md`

## `/sets` latency

Instrumented the `/sets` endpoint without changing the JSON body contract.

New headers:

- `Server-Timing`
- `X-ManaLoom-Sets-Cache`
- `X-ManaLoom-Sets-Total-Ms`
- `X-ManaLoom-Sets-Query-Ms` on cache misses

Runtime evidence from local generated Dart Frog server on port `8092`:

- First request: HTTP 200, body returned 50 sets, `cache=miss`, backend total 765 ms, DB 757 ms.
- Second request: HTTP 200, body returned 50 sets, `cache=hit`, curl total about 4 ms.

This closes the blind spot: if `/sets` is slow again, the response now separates
database time from cache and total endpoint time.

## iOS 26+ simulator

Validated with Flutter 3.41.6 on iOS 26.4 simulator `iPhone 17 Pro`.

Result:

- `flutter build ios --simulator --debug` succeeds in the current buildable configuration.
- `flutter run -d 700B7484-7FEA-472A-A6DF-2DC9F894468B --debug --no-pub` launched the app.
- App reached `/login`.
- Auth initialized as unauthenticated.
- API client used the public server: `https://evolution-cartinhas.8ktevp.easypanel.host`.

Residual warning:

- Flutter warns that simulator targets do not support `arm64`.
- Removing the `arm64` simulator exclusion was tested and failed at link time:
  `MLImage.framework/MLImage[arm64][2](GMLImage.o) built for iOS`.
- The current `arm64 i386` simulator exclusion remains necessary while the
  Google MLKit/MLImage dependency ships that incompatible slice.

Conclusion: this is not fixable safely by local build settings alone. The
durable fix is to replace or upgrade the MLKit scanner dependency to a version
whose iOS framework supports Apple Silicon simulator arm64, then remove the
simulator `arm64` exclusion and rebuild.

## Validation

- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_backfill_battle_rule_oracle_hashes.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/pg_hermes_sqlite_contract_audit.py --out-prefix docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_after_oracle_hash_backfill`
- `dart test test/sets_route_test.dart`
- `dart analyze`
- `flutter build ios --simulator --debug`
- `flutter run -d 700B7484-7FEA-472A-A6DF-2DC9F894468B --debug --no-pub`

## Remaining Follow-up

Only one item remains outside safe local patch scope:

- Upgrade or replace the Google MLKit text recognition stack so iOS simulator
  builds can use arm64 without the `MLImage.framework` device-slice link error.
