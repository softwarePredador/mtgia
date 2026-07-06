# PG546 Controlled-Subtype Token Apply Evidence

- Deploy ID: `pg546_controlled_subtype_tokens_new_server`
- Scope: XMage-authoritative creature-token spells whose token count is `PermanentsOnBattlefieldCount(FilterControlledPermanent + SubType.ELF)`.
- Runtime scope: `xmage_controlled_subtype_create_creature_tokens_spell_v1`
- PostgreSQL target: `143.198.230.247:5433/halder`

## PostgreSQL

- Precheck: 2 target rows, all `target_card_rows=1`, no SQL errors.
- Existing expected rows found: 0.
- Shadow cleanup: 0 rows deprecated.
- Apply: `COMMIT`, 2 rows upserted, 0 shadow rows deprecated.
- Postcheck: 2 promoted rows, all `promoted_verified_auto_rows=1`, all `promoted_oracle_hash_rows=1`.
- Backup table rows: 0.

## Promoted Cards

- `Elven Ambush`
- `Elvish Promenade`

## XMage Source

- `Elven Ambush`: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/e/ElvenAmbush.java`
- `Elvish Promenade`: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/e/ElvishPromenade.java`
- Shared XMage behavior: `CreateTokenEffect(new ElfWarriorToken(), elfCount)` where `elfCount` is `new PermanentsOnBattlefieldCount(filter)` and `filter` is `FilterControlledPermanent` with `SubType.ELF`.

## Mapper / Runtime

- Added exact parser support for `PermanentsOnBattlefieldCount(FilterControlledPermanent)` with exactly one `SubType.*.getPredicate()` filter.
- Added effect fields `token_count_source=controlled_permanents_with_subtype` and `token_count_subtype=Elf`.
- Added battle runtime support to count permanents controlled by the active player with the required subtype.
- Added E2E scenario seeding for controlled subtype permanents so the package validates dynamic counts, not just static metadata.

## Hermes / SQLite

- Sync command: `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review`
- PG rows loaded: 8,845
- SQLite rows inserted or updated: 8,609
- Canonical snapshot rows exported: 6,350

## Runtime E2E

- Validator: `battle_package_end_to_end_validation.py`
- Manifest: `pg546_controlled_subtype_tokens_new_server_package_manifest.json`
- Status: `pass`
- Stages passed: PostgreSQL source of truth, SQLite/Hermes cache, canonical snapshot fallback, runtime lookup, battle execution.
- Battle scenarios: 2
- Battle events: 4
- Runtime evidence: each promoted spell was resolved with 3 controlled Elf permanents and created 3 `Elf Warrior Token` permanents.

## Test Coverage

- `python3 -m py_compile` passed for mapper, package builder, E2E validator, and battle runtime.
- XMage exact-scope split unittest passed: 599 tests, 0 failures.
- Package builder and E2E pytest suite passed: 45 tests, 0 failures.

## Contract Audits

- `xmage_strategy_consistency_audit_20260706_post_pg546_controlled_subtype_tokens_new_server_final`: pass, 26 checks.
- `pg_hermes_sqlite_contract_audit_20260706_post_pg546_controlled_subtype_tokens_new_server_with_pg`: pass, 51 checks.
- `operational_surface_alignment_audit_20260706_post_pg546_controlled_subtype_tokens_new_server_final`: pass.
- `legacy_contamination_audit_20260706_post_pg546_controlled_subtype_tokens_new_server_final`: pass.
- `global_card_oracle_battle_readiness_20260706_post_pg546_controlled_subtype_tokens_new_server_final`: action_required because the global all-card backlog remains open.

## Remaining Global Queue

- Commander-legal target identities still requiring adaptation: 25,646.
- XMage authoritative sources remaining: 25,332.
- Missing local XMage source exceptions: 314.
- Parser gaps: 0.
- Adapter work units remaining: 11,366.
- Post-apply exact split safe candidates: 0.
- All-card readiness: 34,331 known cards; 5,304 `battle_and_oracle_ready`; 28,569 still require battle-family mapper work.
- Token-creation battle gap family count: 3,539.

## Cleanup

- Raw queue JSON dumps for the pre-apply candidate source and post-apply global queue are not durable evidence because they are large intermediate files. Their `.md` summaries preserve the required metrics and routing signal.
