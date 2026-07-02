# ManaLoom Null Owner Deck Cleanup - 2026-07-01

## Scope

Approved action: remove PostgreSQL `decks` rows without owner. If one of the
target decks was deck `607`, link it to `rafaelhalder@gmail.com` instead of
deleting it.

No unrelated PostgreSQL write was performed.

## Precheck

- PostgreSQL target: `143.198.230.247:5433/halder`.
- Rafael user found: `18df0188-9f27-4e20-84fe-a9fa2c39951c`
  (`rafaelhalder@gmail.com`).
- Null-owner decks before apply: `13`.
- Null-owner deck matching `607` by id/name/description: `0`.
- Non-cascade dependent rows for the 13 target decks: `0`.
- Cascade dependent rows:
  - `deck_cards`: `1182`.
  - `deck_matchups`: `0`.
  - `deck_weakness_reports`: `0`.

Target rows:

| id | name |
| --- | --- |
| `917674eb-6a3d-58de-acce-5a2a3ac9e497` | PG REGISTERED Lorehold Variant 04 - Rafael Paste 2026-06-24 |
| `8aa57962-3a3e-5351-89fd-e4651456a3bd` | PG REGISTERED Lorehold Variant 05 - Rafael Paste 2026-06-24 |
| `0936dae3-32c4-5fb8-9c6f-d986670de794` | PG REGISTERED Lorehold Variant 06 - Rafael Paste 2026-06-24 |
| `231281c3-e6a2-579b-93fe-21ddfdd13bda` | PG REGISTERED Lorehold Variant 07 - Rafael Paste 2026-06-24 |
| `6df74eb3-c4a7-5398-bcf5-febb38d80d7a` | PG REGISTERED Lorehold Variant 08 - Rafael Paste 2026-06-24 |
| `b51c8f24-fa8b-50ee-8200-d78fe9908ffa` | PG REGISTERED Lorehold Variant 09 - Rafael Paste 2026-06-24 |
| `43c026ae-2d92-5049-90fc-1fdad4b04298` | PG REGISTERED Lorehold Variant 10 - Rafael Paste 2026-06-24 |
| `9df6ac2e-6620-5265-8008-1f57c8963d66` | PG REGISTERED Lorehold Variant 11 - Rafael Paste 2026-06-24 |
| `34508aae-e393-577a-97d8-6259353664af` | PG REGISTERED Kefka Variant 01 - Rafael Paste 2026-06-24 |
| `c77cb83c-dd28-5d66-a0d8-799079a848bb` | PG REGISTERED Valgavoth Variant 01 - Rafael Paste 2026-06-24 |
| `b629f227-b2b2-5e71-9854-99d345a8e01c` | PG REGISTERED Kaalia Variant 01 - Rafael Paste 2026-06-24 |
| `c2230827-7963-52e4-a6ba-298d7be3478a` | PG REGISTERED Sauron Variant 01 - Rafael Paste 2026-06-24 |
| `982cf6a6-c84a-5c3e-b9fc-e79127598b89` | PG REGISTERED Y'shtola Variant 01 - Rafael Paste 2026-06-24 |

## Apply Result

The cleanup ran inside one transaction.

- `607` rows updated to Rafael: `0`.
- Deleted null-owner decks: `13`.
- Transaction result: `COMMIT`.

## Postcheck

- Null-owner decks after apply: `0`.
- Remaining null-owner `607` rows: `0`.
- Deleted deck ids still present in `decks`: `0`.
- Deleted deck ids still present in `deck_cards`: `0`.
- Existing `607` deck linked to Rafael:
  - id: `8938b746-1a9e-46ce-b0d9-c2ec932ddddd`
  - name: `Lorehold 607 - Current Champion`
  - user: `rafaelhalder@gmail.com`

## Follow-up Validation

- `dart run bin/audit_data_model_links.dart --require-db`
  - `null_owner_deck_audit.status=none`
  - `null_user_decks=0`
  - `deck_cards_to_card_intelligence_snapshot.extra_rows=0`
  - `direct_deck_cards_to_card_battle_rules_fanout_potential.extra_rows=43850`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/pg_hermes_sqlite_contract_audit.py --out-prefix docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_after_null_owner_deck_cleanup`
  - status: `pass`
  - summary: `48 pass`, `1 warn`
  - remaining warning: `trusted_executable_rules_missing_oracle_hash=1418`
- SQLite mirror safety evaluation was executed only against
  `/tmp/manaloom_knowledge_oracle_hash_eval.db`.
  - `pg_rows_loaded=3652`
  - `sqlite_inserted_or_updated=4623`
  - audit on the copied DB still returned `48 pass`, `1 warn`
  - remaining copied-DB warning:
    `trusted_executable_rules_missing_oracle_hash=1418`
  - conclusion: do not apply this mirror to the real `knowledge.db` as a blind
    fix, because it changes thousands of local cache rows without closing the
    warning.
- `/sets` SQL plan check
  - `idx_cards_set_code_lower` exists.
  - `EXPLAIN ANALYZE` for the route's core query completed in about `109 ms`.
  - Prior multi-second first request is therefore more likely cold runtime,
    network/proxy, or endpoint instrumentation overhead than missing SQL index.
- `dart test test/experimental_deck_ai_authorization_source_test.dart`
  - result: `All tests passed`

## Remaining Items

1. `trusted_executable_rules_missing_oracle_hash=1418` remains a Hermes SQLite
   cache governance warning. It needs a dedicated sync/backfill package; it was
   not part of the approved deck-owner PostgreSQL mutation.
2. `/sets` first-request latency still needs runtime/proxy instrumentation. The
   database plan is indexed and measured at about `109 ms`, so do not spend the
   next pass on blind SQL/index changes unless a new `EXPLAIN` contradicts this.
3. iOS 26+ simulator plugin architecture warning remains a toolchain/plugin
   compatibility item.
