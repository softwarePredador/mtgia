# PG511 Simple Dynamic Damage Counts Apply Evidence

- Generated/applied at: `2026-07-05`
- Deploy id: `PG511`
- Package slug: `xmage_pg511_simple_dynamic_damage_counts_new_server`
- Runtime family: `xmage_dynamic_count_damage_spell_v1`
- Promoted cards: `Runeflare Trap`, `Storm Seeker`, `Sudden Impact`, `Thunder Salvo`

## Scope

PG511 promotes only direct damage spells whose dynamic damage amount is backed
by a local XMage source class and a matching ManaLoom runtime count source:

- `target_hand_count`: damage equals the target player's current hand size.
- `other_spells_cast_this_turn`: damage equals a base amount plus spells cast
  this turn excluding the resolving spell.

Composite count rows remain blocked. `Focus Fire`, `Hobbit's Sting`,
`Slash of Light`, and `Road Rage` need a separate composed-count contract.
`Kaleidoscorch` remains blocked because it depends on colors of mana spent to
cast the spell.

## Source Evidence

- `RuneflareTrap.java`: `DamageTargetEffect(new TargetPlayerCardsInHandCount())`
  with `TargetPlayer`.
- `StormSeeker.java`: `DamageTargetEffect(CardsInTargetHandCount.instance)`
  with `TargetPlayer`.
- `SuddenImpact.java`: `DamageTargetEffect(CardsInTargetHandCount.instance)`
  with `TargetPlayer`.
- `ThunderSalvo.java`: `DamageTargetEffect(new IntPlusDynamicValue(2,
  ThunderSalvoValue.instance))` with `TargetCreaturePermanent`.

## PostgreSQL Evidence

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg511_simple_dynamic_damage_counts_new_server_precheck.out`
  found one Oracle-hash-matched target card row for each card and no existing
  matching rule rows.
- Apply:
  `deprecated_shadow_rows=0`, `upserted_rows=4`, `COMMIT`.
- Postcheck:
  every promoted card has `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

## Hermes/SQLite Sync

- Sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg511_simple_dynamic_damage_counts_new_server.json`
- `selected_card_count=4`
- `pg_rows_loaded=4`
- `sqlite_inserted_or_updated=4`
- `canonical_snapshot_rows_exported=6009`

## Runtime Validation

- Focused tests:
  `test_dynamic_count_damage_spells_map_to_runtime`,
  `test_dynamic_target_hand_count_damage_uses_target_player_hand_size`, and
  `test_dynamic_other_spells_cast_damage_excludes_current_spell` passed.
- Full focused suite:
  `python3 -m unittest test_xmage_authoritative_exact_scope_split test_xmage_exact_scope_runtime`
  ran `817` tests and passed.
- Runtime lookup confirmed the four names resolve to
  `xmage_dynamic_count_damage_spell_v1` with the expected
  `damage_amount_source`, target, and base amount.
- Runtime lookup output:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg511_simple_dynamic_damage_counts_new_server_runtime_get_card_effect.out`

## Alignment Audits

- XMage strategy consistency: `26/26` pass.
- Operational surface alignment: `pass`.
- Legacy contamination audit: `pass`.
- PG/Hermes/SQLite contract audit with PostgreSQL env loaded: `51/51` pass.

## Queue Delta

Pre-apply queue:

- `target_identity_count=26012`
- `xmage_authoritative_source_count=25698`
- `xmage_authoritative_adapter_required_count=25698`
- candidate exact split: `proposal_count=4`,
  `safe_for_batch_pg_package_count=4`

Post-apply queue:

- `target_identity_count=26008`
- `xmage_authoritative_source_count=25694`
- `xmage_authoritative_adapter_required_count=25694`
- final exact split: `proposal_count=0`,
  `safe_for_batch_pg_package_count=0`

Global readiness after PG511:

- `battle_and_oracle_ready=4942`
- `battle_family_mapper_required=28931`
- `snapshot_has_any_rule=6012`
- `snapshot_has_verified_rule=4764`
