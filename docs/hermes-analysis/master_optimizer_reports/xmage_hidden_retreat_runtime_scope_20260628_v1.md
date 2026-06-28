# XMage Local Rule Index

Generated at: `2026-06-28T06:53:07+00:00`

Read-only artifact. `mutations_performed=[]`.

- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- Summary: `{"not_found_count": 0, "requested_card_count": 1, "resolved_count": 1, "xmage_class_index_size": 31747}`

| Card | Status | XMage class | Superclass | Signals | Primary hint |
| --- | --- | --- | --- | --- | --- |
| `Hidden Retreat` | `found` | `HiddenRetreat` | `CardImpl` | `targeting, activated_ability` | `damage_prevention_shield` |

## Card Evidence

### Hidden Retreat

- XMage path: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/h/HiddenRetreat.java`
- Class: `HiddenRetreat` extends `CardImpl`
- Ability classes: `["SimpleActivatedAbility"]`
- Effect classes: `["HiddenRetreatEffect"]`
- Target classes: `["TargetSpell"]`
- Filter classes: `[]`
- Condition classes: `[]`
- Primary candidate: `{"ability_kind": "activated", "activated_prevent_damage_from_target_spell": true, "activation_cost": "put_card_from_hand_on_top_of_library", "activation_cost_generic": 0, "activation_requires_put_card_from_hand_on_top_library": true, "battle_model_scope": "activated_put_card_from_hand_on_top_library_prevent_damage_from_target_instant_or_sorcery_spell_v1", "can_setup_lorehold_miracle_draw": true, "effect": "damage_prevention_shield", "prevent_damage_amount": 999, "prevent_damage_duration": "until_end_of_turn", "prevent_damage_from_target_spell": true, "prevent_damage_target_type": "instant_or_sorcery_spell", "spell_target_required": true, "target_spell_card_types": ["instant", "sorcery"]}`
- Confidence reason: XMage structure matches Hidden Retreat: a SimpleActivatedAbility with PutCardFromHandOnTopOfLibraryCost, TargetSpell filtered to instant or sorcery spells, and a prevention effect that blanks damage from that target spell this turn.

Suggested focused tests:

- `hidden_retreat_1`: focused behavior scenario for damage_prevention_shield
