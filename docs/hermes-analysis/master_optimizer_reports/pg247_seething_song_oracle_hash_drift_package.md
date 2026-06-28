# PG247 Seething Song Oracle Hash Drift

Purpose: restore `oracle_hash` provenance for the active `Seething Song`
`card_battle_rules` row after the current deck `6` PG -> Hermes audit found the
trusted executable rule missing hash metadata again.

- Card: `Seething Song`
- Rule: `battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7`
- Oracle text in PostgreSQL: `Add {R}{R}{R}{R}{R}.`
- Expected hash source: `md5(cards.oracle_text)`
- Expected hash: `ccd492289c6f1c14c8fb7a248d7bbf32`
- Runtime scope preserved: `single_shot_red_ritual_v1`
- Behavior change: none

Files:

- Precheck: `pg247_seething_song_oracle_hash_drift_precheck.sql`
- Apply: `pg247_seething_song_oracle_hash_drift_apply.sql`
- Postcheck: `pg247_seething_song_oracle_hash_drift_postcheck.sql`
- Rollback: `pg247_seething_song_oracle_hash_drift_rollback.sql`

Apply only if precheck reports exactly one target row and one safe target row.
