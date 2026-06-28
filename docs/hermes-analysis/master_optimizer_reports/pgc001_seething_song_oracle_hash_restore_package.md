# PGC001 Seething Song Oracle Hash Restore

Purpose: restore `oracle_hash` provenance for the active `Seething Song`
`card_battle_rules` row after a legacy PG-prefixed automation sync drifted the
field back to null.

- Namespace: `PGC`, reserved for this agent's card oracle/rule packages.
- Recent PG artifacts checked first: `PG246`, `PG247`, `PG248`.
- Card: `Seething Song`
- Rule: `battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7`
- Oracle text in PostgreSQL: `Add {R}{R}{R}{R}{R}.`
- Expected hash source: `md5(cards.oracle_text)`
- Expected hash: `ccd492289c6f1c14c8fb7a248d7bbf32`
- Runtime scope preserved: `single_shot_red_ritual_v1`
- Behavior change: none

Files:

- Precheck: `pgc001_seething_song_oracle_hash_restore_precheck.sql`
- Apply: `pgc001_seething_song_oracle_hash_restore_apply.sql`
- Postcheck: `pgc001_seething_song_oracle_hash_restore_postcheck.sql`
- Rollback: `pgc001_seething_song_oracle_hash_restore_rollback.sql`

Apply only if precheck reports exactly one target row, one safe target row, and
one missing hash row.
