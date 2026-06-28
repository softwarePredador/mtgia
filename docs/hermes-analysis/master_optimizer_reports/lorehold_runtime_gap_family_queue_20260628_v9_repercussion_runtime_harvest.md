# External Card Rule Reference Harvest

Generated at: `2026-06-28T10:54:27+00:00`

This is a read-only reference packet. It does not mutate PostgreSQL, SQLite, decks, runtime code, or reviewed rules.

## Source Audit

- Deck id: `6`
- Severity counts: `{"high": 3, "medium": 58}`
- Finding counts: `null`

## Cards

| Card | Severity | Impact | Gap bucket | Scryfall | XMage | Forge | Candidate effect |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Repercussion` | `medium` | `None` | `rule_entry_or_runtime_gap_with_external_reference` | `found` | `found` | `found` | `direct_damage` |

## Review Packets

### Repercussion

- Gap bucket: `rule_entry_or_runtime_gap_with_external_reference`
- Findings: `no_active_battle_rule`
- Recommended next action: Use external implementation to decide whether a rule entry is enough or runtime support is required.
- Candidate logical rule key: `battle_rule_v1:50b3ef47a4dbfea5726ec21f0d793b3e`
- Candidate oracle hash: `8e1ed4f8063ab89dd8906878a6232862`
- Candidate effect_json: `{"ability_kind": "triggered", "battle_model_scope": "creature_damage_controller_reflect_global_v1", "damage_amount_source": "damage_dealt_to_creature", "effect": "direct_damage", "global_creature_damage_reflect_to_controller": true, "trigger": "creature_dealt_damage", "trigger_effect": "damage_creature_controller", "xmage_hint_policy": "review_candidate_only"}`

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
