# PG182 Seething Song Oracle Hash

Purpose: restore `oracle_hash` provenance for the active `Seething Song`
`card_battle_rules` row after PG -> Hermes sync surfaced that the rule was
`verified/auto` but missing hash metadata.

- Card: `Seething Song`
- Rule: `battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7`
- Expected hash source: `md5(cards.oracle_text)`
- Expected hash: `ccd492289c6f1c14c8fb7a248d7bbf32`

Apply only after precheck confirms the row exists and the expected hash matches
the `cards` table.
