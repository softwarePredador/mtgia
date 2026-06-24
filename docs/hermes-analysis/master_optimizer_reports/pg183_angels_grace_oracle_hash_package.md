# PG183 Angel's Grace Oracle Hash

Purpose: restore `oracle_hash` provenance for the active `Angel's Grace`
`card_battle_rules` row after PG -> Hermes sync surfaced that the rule was
`verified/auto` but missing hash metadata.

- Card: `Angel's Grace`
- Rule: `battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227`
- Expected hash source: `md5(cards.oracle_text)`
- Expected hash: `627c4ce7adf5be44b93e2b850159e5d9`

Apply only after precheck confirms the row exists and the expected hash matches
the `cards` table.
