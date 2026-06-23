# External Card Rule Reference Harvest

Generated at: `2026-06-23T17:05:59+00:00`

This is a read-only reference packet. It does not mutate PostgreSQL, SQLite, decks, runtime code, or reviewed rules.

## Source Audit

- Deck id: `607`
- Severity counts: `{"high": 9, "medium": 4, "pass": 81}`
- Finding counts: `{"generic_effect_without_model_scope": 1, "no_active_battle_rule": 6, "no_trusted_executable_rule": 3, "review_only_or_needs_review_rule": 3, "trusted_rule_without_oracle_hash": 4}`

## Cards

| Card | Severity | Impact | Gap bucket | Scryfall | XMage | Forge | Candidate effect |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Promise of Loyalty` | `high` | `battle_critical` | `review_promotion_gap_with_external_reference` | `found` | `found` | `found` | `vow_counter_each_player_sacrifice_rest` |
| `Starfall Invocation` | `high` | `battle_critical` | `review_promotion_gap_with_external_reference` | `found` | `found` | `found` | `gift_destroy_all_creatures_return_own_destroyed_creature` |
| `Pearl Medallion` | `high` | `battle_support` | `review_promotion_gap_with_external_reference` | `found` | `found` | `found` | `static_cost_reduction` |

## Review Packets

### Promise of Loyalty

- Gap bucket: `review_promotion_gap_with_external_reference`
- Findings: `no_trusted_executable_rule, review_only_or_needs_review_rule`
- Recommended next action: Compare external implementation with local candidate, then promote only after focused test/replay evidence.
- Candidate logical rule key: `battle_rule_v1:780736470bfbd01e4d3d453bf87d1e8d`
- Candidate oracle hash: `21dd715160fde6e50b8edc015ce83b0f`
- Candidate effect_json: `{"ability_kind": "one_shot", "battle_model_scope": "each_player_choose_creature_vow_counter_sacrifice_other_creatures_attack_restriction_v1", "effect": "vow_counter_each_player_sacrifice_rest", "xmage_hint_policy": "review_candidate_only"}`

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

### Starfall Invocation

- Gap bucket: `review_promotion_gap_with_external_reference`
- Findings: `no_trusted_executable_rule, review_only_or_needs_review_rule`
- Recommended next action: Compare external implementation with local candidate, then promote only after focused test/replay evidence.
- Candidate logical rule key: `battle_rule_v1:cde2ffa3dde331b202ac94e299ecae64`
- Candidate oracle hash: `3429884949eac8ffe09d86dc85bee1ae`
- Candidate effect_json: `{"ability_kind": "one_shot", "battle_model_scope": "gift_card_destroy_all_creatures_return_one_own_creature_destroyed_this_way_v1", "effect": "gift_destroy_all_creatures_return_own_destroyed_creature", "xmage_hint_policy": "review_candidate_only"}`

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

### Pearl Medallion

- Gap bucket: `review_promotion_gap_with_external_reference`
- Findings: `no_trusted_executable_rule, review_only_or_needs_review_rule`
- Recommended next action: Compare external implementation with local candidate, then promote only after focused test/replay evidence.
- Candidate logical rule key: `battle_rule_v1:56175cef9dc5575abfc28f68caf67042`
- Candidate oracle hash: `77f7f449ee56143d6b63814fecd37176`
- Candidate effect_json: `{"ability_kind": "static", "applies_to_controller": "source_controller", "applies_to_spell_colors": ["W"], "battle_model_scope": "static_cost_reduction_for_matching_spells_v1", "cost_reduction_applies_to": "spells_you_cast", "cost_reduction_generic": 1, "effect": "static_cost_reduction", "xmage_hint_policy": "review_candidate_only"}`

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
