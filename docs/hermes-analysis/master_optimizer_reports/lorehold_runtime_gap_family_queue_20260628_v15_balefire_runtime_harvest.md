# External Card Rule Reference Harvest

Generated at: `2026-06-28T11:37:29+00:00`

This is a read-only reference packet. It does not mutate PostgreSQL, SQLite, decks, runtime code, or reviewed rules.

## Source Audit

- Deck id: `None`
- Severity counts: `null`
- Finding counts: `null`

## Cards

| Card | Severity | Impact | Gap bucket | Scryfall | XMage | Forge | Candidate effect |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Balefire Liege` | `medium` | `None` | `manual_review` | `found` | `found` | `found` | `creature` |

## Review Packets

### Balefire Liege

- Gap bucket: `manual_review`
- Findings: ``
- Recommended next action: Manual review required before promotion.
- Candidate logical rule key: `battle_rule_v1:3c8e1a9b545df1ed2a5672e7bf8a5451`
- Candidate oracle hash: `467dd11263f2854e2d9fc487a127ced6`
- Candidate effect_json: `{"ability_kind": "triggered", "battle_model_scope": "red_spell_damage_white_spell_lifegain_static_creature_boost_v1", "effect": "creature", "power": 2, "red_spell_trigger_damage": 3, "red_spell_trigger_damage_target": "player_or_planeswalker", "static_boost_other_red_creatures_you_control": {"power": 1, "toughness": 1}, "static_boost_other_white_creatures_you_control": {"power": 1, "toughness": 1}, "toughness": 4, "trigger": "spell_cast", "trigger_effect": "spell_color_damage_life", "white_spell_trigger_gain_life": 3, "xmage_hint_policy": "review_candidate_only"}`

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
