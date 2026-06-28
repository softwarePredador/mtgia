# External Card Rule Reference Harvest

Generated at: `2026-06-28T11:08:06+00:00`

This is a read-only reference packet. It does not mutate PostgreSQL, SQLite, decks, runtime code, or reviewed rules.

## Source Audit

- Deck id: `6`
- Severity counts: `{"high": 3, "medium": 58}`
- Finding counts: `null`

## Cards

| Card | Severity | Impact | Gap bucket | Scryfall | XMage | Forge | Candidate effect |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Terror of the Peaks` | `medium` | `None` | `rule_entry_or_runtime_gap_with_external_reference` | `found` | `found` | `found` | `creature` |

## Review Packets

### Terror of the Peaks

- Gap bucket: `rule_entry_or_runtime_gap_with_external_reference`
- Findings: `no_active_battle_rule`
- Recommended next action: Use external implementation to decide whether a rule entry is enough or runtime support is required.
- Candidate logical rule key: `battle_rule_v1:42a41f7261bd5bcdbef7d8c2148fb406`
- Candidate oracle hash: `90c007ac59cdd400f58e89c47d81440e`
- Candidate effect_json: `{"ability_kind": "triggered", "battle_model_scope": "controlled_other_creature_enters_power_damage_any_target_v1", "effect": "creature", "flying": true, "opponent_spells_targeting_this_additional_life_cost": 3, "power": 5, "target": "any_target", "target_constraints": {"scope": "any_target"}, "toughness": 4, "trigger": "creature_you_control_enters", "trigger_another_creature_you_control_enters": true, "trigger_damage_amount_source": "entering_creature_power", "trigger_effect": "damage_any_target", "xmage_hint_policy": "review_candidate_only"}`

External reference status:

- Scryfall: `found`
- XMage: `found`
- Forge: `found`

Evidence checklist:

- Confirm current Oracle text and oracle_hash against PostgreSQL/Scryfall.
- Compare XMage/Forge/parser reference with ManaLoom compact effect model.
- Decide whether runtime code is required or existing executor already supports the effect.
- Prepare SQL as dry-run/precheck/postcheck/rollback before any apply.
- Add or update focused unit test for the selected effect model.
- Run focused replay/events and verify selected logical_rule_key.
- Rerun deck_card_battle_rule_coherence_audit for impacted decks.
