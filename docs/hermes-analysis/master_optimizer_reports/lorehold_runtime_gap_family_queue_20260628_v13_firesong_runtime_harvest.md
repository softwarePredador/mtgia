# External Card Rule Reference Harvest

Generated at: `2026-06-28T11:24:40+00:00`

This is a read-only reference packet. It does not mutate PostgreSQL, SQLite, decks, runtime code, or reviewed rules.

## Source Audit

- Deck id: `None`
- Severity counts: `null`
- Finding counts: `null`

## Cards

| Card | Severity | Impact | Gap bucket | Scryfall | XMage | Forge | Candidate effect |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Firesong and Sunspeaker` | `medium` | `None` | `manual_review` | `found` | `found` | `found` | `creature` |

## Review Packets

### Firesong and Sunspeaker

- Gap bucket: `manual_review`
- Findings: ``
- Recommended next action: Manual review required before promotion.
- Candidate logical rule key: `battle_rule_v1:204d2128e5466cf895339e3ff4fc0e26`
- Candidate oracle hash: `834cfb8f0f869e7e9b4bc5342ad63046`
- Candidate effect_json: `{"ability_kind": "triggered", "battle_model_scope": "red_instant_sorcery_lifelink_white_lifegain_damage_v1", "effect": "creature", "instant_sorcery_lifelink_colors": ["R"], "instant_sorcery_spells_you_control_have_lifelink": true, "power": 4, "target": "any_target", "target_constraints": {"scope": "any_target"}, "toughness": 6, "trigger": "white_instant_sorcery_lifegain", "trigger_effect": "damage_any_target", "white_instant_sorcery_lifegain_trigger_damage": 3, "xmage_hint_policy": "review_candidate_only"}`

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
