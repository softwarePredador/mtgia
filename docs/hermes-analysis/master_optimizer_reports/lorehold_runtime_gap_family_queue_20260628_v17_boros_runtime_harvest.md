# External Card Rule Reference Harvest

Generated at: `2026-06-28T11:47:17+00:00`

This is a read-only reference packet. It does not mutate PostgreSQL, SQLite, decks, runtime code, or reviewed rules.

## Source Audit

- Deck id: `None`
- Severity counts: `null`
- Finding counts: `null`

## Cards

| Card | Severity | Impact | Gap bucket | Scryfall | XMage | Forge | Candidate effect |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Boros Reckoner` | `medium` | `None` | `manual_review` | `found` | `found` | `found` | `creature` |

## Review Packets

### Boros Reckoner

- Gap bucket: `manual_review`
- Findings: ``
- Recommended next action: Manual review required before promotion.
- Candidate logical rule key: `battle_rule_v1:0ffd0e6f650e7d9c23b37d6446a594a3`
- Candidate oracle hash: `8cb6c980428b2501343f3f38dc686efb`
- Candidate effect_json: `{"ability_kind": "triggered", "activated_gain_first_strike_until_eot": true, "battle_model_scope": "source_dealt_damage_reflect_to_any_target_v1", "damage_amount_source": "damage_dealt_to_source", "effect": "creature", "first_strike_activation_cost": "{R/W}", "power": 3, "source_damage_reflect_to_any_target": true, "target": "any_target", "target_constraints": {"scope": "any_target"}, "toughness": 3, "trigger": "source_dealt_damage", "trigger_effect": "damage_any_target", "xmage_hint_policy": "review_candidate_only"}`

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
