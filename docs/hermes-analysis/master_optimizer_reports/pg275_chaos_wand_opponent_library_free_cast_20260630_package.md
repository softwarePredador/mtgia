# PG275 Chaos Wand Opponent Library Free-Cast Runtime Package

Status: `applied_synced`.

This package promotes `Chaos Wand` to an exact curated runtime rule backed by
local XMage source and a focused ManaLoom runtime test.

- Generated at: `2026-06-30T10:32:39+00:00`
- Selected cards: `["Chaos Wand"]`
- Local XMage source:
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/c/ChaosWand.java`
- Exact scope:
  `pay_four_tap_target_opponent_exile_until_instant_sorcery_may_cast_free_bottom_rest_v1`
- Logical rule key:
  `battle_rule_v1:cb5acba44191c9c6711c017b4c3590d0`
- Oracle hash:
  `7b77d47629eb006df4e9754fee988c51`
- Focused runtime test:
  `battle_card_specific_tests.py --filter test_pg275_chaos_wand_exiles_opponent_library_until_free_cast_hit`

Files:

- precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg275_chaos_wand_opponent_library_free_cast_20260630_precheck.sql`
- apply:
  `docs/hermes-analysis/master_optimizer_reports/pg275_chaos_wand_opponent_library_free_cast_20260630_apply.sql`
- rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg275_chaos_wand_opponent_library_free_cast_20260630_rollback.sql`
- postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg275_chaos_wand_opponent_library_free_cast_20260630_postcheck.sql`
- manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg275_chaos_wand_opponent_library_free_cast_20260630_manifest.json`
- sync:
  `docs/hermes-analysis/master_optimizer_reports/pg275_chaos_wand_opponent_library_free_cast_20260630_sync.json`

Apply result:

- Precheck: `target_card_rows=1`, `existing_rule_rows=0`,
  `would_deprecate_shadow_rows=0`.
- Apply: `backup_rows=0`, `deprecated_shadow_rows=0`, `upserted_rows=1`.
- Postcheck: promoted rule/hash `1/1`, active `verified/auto` row `1`.
- Scope check: exact scope/cost/target present in PostgreSQL.
- Sync: `pg_rows_loaded=1`, `sqlite_inserted_or_updated=1`,
  canonical snapshot rows `3286`.
- Runtime lookup: `get_card_effect("Chaos Wand")` returns curated
  `verified/auto` rule with activation cost `4`, tap requirement, target
  `opponent`, and the exact PG275 scope.
