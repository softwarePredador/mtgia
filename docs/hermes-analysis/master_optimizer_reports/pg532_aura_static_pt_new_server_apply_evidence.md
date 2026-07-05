# PG532 Aura Static P/T Apply Evidence

- Deploy ID: `PG532`
- Package: `pg532_aura_static_pt_new_server`
- Runtime scope: `xmage_aura_static_power_toughness_attachment_v1`
- Closed cards: `35`
- PostgreSQL table: `public.card_battle_rules`
- Database target: `143.198.230.247:5433/halder`

## PostgreSQL Apply

- Precheck: `35` target card rows, `0` existing matching rule rows, `0` shadow rows to deprecate.
- Apply: `upserted_rows=35`, `deprecated_shadow_rows=0`.
- Postcheck: `35/35` promoted rows present, verified, executable as `auto`, and carrying `oracle_hash`.

## Sync And Runtime Evidence

- PG -> SQLite sync: `pg_rows_loaded=35`, `sqlite_inserted_or_updated=35`.
- Canonical fallback snapshot export: `6181` rows.
- Package E2E: `status=pass`.
- Battle execution: `35` Aura scenarios, `49` replay events.
- Final exact-scope recheck: `proposal_count=0`, `safe_for_batch_pg_package_count=0`.

## Queue Impact

- Pre-cycle target identities: `25864`.
- Post-cycle target identities: `25829`.
- Reduction: `35`.
- Post-cycle XMage authoritative source count: `25515`.
- Post-cycle missing local XMage source exceptions: `314`.

## Safety Boundary

PG532 only promotes exact fixed Aura attachments whose local XMage source has
`AttachEffect + BoostEnchantedEffect` with simple `EnchantAbility` and
`SimpleStaticAbility`. Dynamic Aura boosts, count-based modifiers, auxiliary
ability packages, and source/Oracle mismatches remain blocked.
