# PG758 Next-Cast X Trigger Evidence - 2026-07-11

Status: `applied_and_validated`

Database target: `127.0.0.1:15432/halder` through `./server/bin/with_new_server_pg.sh`.

## Scope

PG758 promotes one exact XMage-backed ManaLoom runtime family:

- Family: `xmage_mana_activation_next_cast_x_trigger_mana_source`
- Battle model scope: `xmage_simple_tap_mana_source_with_next_cast_x_trigger_v1`
- Card: `Brass Infiniscope`
- Logical rule key: `battle_rule_v1:d2482d830daad814b7bd75e8fbc4d0c6`
- Oracle hash: `dec2186f7cf6f51fd45bdb65220eef81`

XMage source:

- `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/b/BrassInfiniscope.java`
- Source behavior: `{T}` produces `{C}{C}`, registers `CastNextSpellDelayedTriggeredAbility`, filters `VariableManaCostPredicate`, draws 1, and gains `xValue / 2` life.

The residual mana-source candidates from the same probe remain partial/manual because their XMage behavior includes separate runtime families such as static cast locks, control-changing combat triggers, replacement effects, land animation, Formidable, counters/win conditions, token creation, or multi-mode triggers.

## Runtime And Tooling Changes

- `battle_analyst_v9.py`
  - Added `mana_activation_cast_trigger` pending trigger support.
  - Resolves the trigger on the next matching cast in the same turn.
  - Reuses the mana-spent trigger effect resolver for draw, life gain, and scry.
  - Deduplicates pending triggers per source object and turn to avoid double-counting when mana refresh is recomputed.
- `xmage_authoritative_exact_scope_split.py`
  - Added exact Oracle/XMage splitter for the Brass Infiniscope-style pattern.
- `xmage_batch_pg_package_builder.py`
  - Added manifest/E2E scenario generation for `mana_activation_cast_trigger`.
- `battle_package_end_to_end_validation.py`
  - Added a battle runner that activates the mana source, casts an X spell, and validates draw/life-gain effects.
- Tests
  - Splitter test for Brass Infiniscope.
  - Package-builder scenario test.
  - Runtime E2E runner test.
  - Runtime dedupe test for repeated mana refresh in the same turn.

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg758_next_cast_x_trigger_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg758_next_cast_x_trigger_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg758_next_cast_x_trigger_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg758_next_cast_x_trigger_new_server_rollback.sql`

Observed package result:

- Precheck target rows: `1`
- Existing rule rows before apply: `0`
- Apply upserted rows: `1`
- Deprecated shadow rows: `0`
- Postcheck promoted rule rows: `1`
- Postcheck promoted verified-auto rows: `1`
- Postcheck promoted oracle-hash rows: `1`

## PG758B Hash Backfill

PG758B restored missing `oracle_hash` on old trusted executable rules that drifted back into the audit lane after PG758.

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg758b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg758b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg758b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg758b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

Observed backfill result:

- Precheck missing trusted executable hashes: `55`
- Missing `card_id`: `0`
- Unmatched `card_id`: `0`
- Empty Oracle text: `0`
- Safe backfill rows: `55`
- Apply backfilled rows: `55`
- Postcheck missing trusted executable hashes: `0`
- Postcheck backup rows: `55`
- Postcheck updated rows with current Oracle hash: `55`

Source registry guardrail:

- `reviewed_battle_card_rules.json` now carries the restored `oracle_hash` values for reviewed rules that were missing them, so future syncs should not reintroduce the same audit failure.

## Sync And E2E

PostgreSQL to SQLite/Hermes sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg758b_trusted_rule_oracle_hash_backfill_new_server_sqlite_sync.json`
- Canonical snapshot rows exported: `7465`
- PostgreSQL rows loaded: `10073`
- SQLite inserted/updated: `9851`

PG758 E2E:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg758_next_cast_x_trigger_new_server_e2e.json`
- Status: `pass`
- Battle result:
  - Card: `Brass Infiniscope`
  - Cast card: `E2E X Spell`
  - X value: `2`
  - Trigger count: `1`
  - Draw count: `1`
  - Life gain: `1`
  - Available mana after cast: `0`

## Audits

- `pg_hermes_sqlite_contract_audit_20260711_post_pg758b_next_cast_x_trigger_new_server`: `pass`, `51/51`
- `xmage_strategy_consistency_audit_20260711_post_pg758b_next_cast_x_trigger_new_server`: `pass`, `26/26`
- PostgreSQL direct check: trusted executable rules missing `oracle_hash` = `0`

## Global Counters After PG758B

Readiness report:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg758b_next_cast_x_trigger_new_server.json`
- Status: `action_required`
- `battle_and_oracle_ready`: `6478`
- `snapshot_has_verified_rule`: `6503`
- `battle_family_mapper_required`: `27398`
- `generic_runtime_or_no_card_rule`: `359`
- `official_oracle_identity_unavailable`: `3`
- `digital_non_commander_rule_exception`: `3`

XMage authoritative queue:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg758b_next_cast_x_trigger_new_server_commander_legal.json`
- Status: `action_required`
- Target identities: `24475`
- XMage authoritative adapter required: `24162`
- XMage parser gap: `0`
- Missing XMage source exceptions: `313`
- Authoritative source coverage ratio: `0.9872`

Priority list check after PG758B:

- Unique listed cards: `24`
- Found cards: `24`
- Current-hash battle rule: `21`
- Functional classification: `24`
- Current-hash battle rule plus function: `21`
- Remaining strict gaps: `Command Tower`, `Sol Ring`, `Lorehold, the Historian`

## Verification Commands

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py

PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m pytest -q \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py -k "mana_activation or mana_spent" \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py -k "mana_activation or mana_spent" \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -k "mana_activation or mana_spent"

./server/bin/with_new_server_pg.sh python3 \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py \
  --manifest docs/hermes-analysis/master_optimizer_reports/pg758_next_cast_x_trigger_new_server_manifest.json \
  --output-json docs/hermes-analysis/master_optimizer_reports/pg758_next_cast_x_trigger_new_server_e2e.json \
  --output-md docs/hermes-analysis/master_optimizer_reports/pg758_next_cast_x_trigger_new_server_e2e.md
```

Observed verification:

- `py_compile`: pass
- Focused pytest: `10 passed, 1321 deselected`
- PG758 E2E: `pass`
