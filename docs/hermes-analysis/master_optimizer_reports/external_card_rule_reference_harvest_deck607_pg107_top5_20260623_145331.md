# External Card Rule Reference Harvest

Generated at: `2026-06-23T14:53:37+00:00`

This is a read-only reference packet. It does not mutate PostgreSQL, SQLite, decks, runtime code, or reviewed rules.

## Source Audit

- Deck id: `607`
- Severity counts: `{"high": 9, "medium": 4, "pass": 81}`
- Finding counts: `{"generic_effect_without_model_scope": 1, "no_active_battle_rule": 6, "no_trusted_executable_rule": 3, "review_only_or_needs_review_rule": 3, "trusted_rule_without_oracle_hash": 4}`

## Cards

| Card | Severity | Impact | Gap bucket | Scryfall | XMage | Forge | Candidate effect |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Promise of Loyalty` | `high` | `battle_critical` | `review_promotion_gap_with_external_reference` | `found` | `not_found` | `found` | `vow_counter_each_player_sacrifice_rest` |
| `Starfall Invocation` | `high` | `battle_critical` | `review_promotion_gap_with_external_reference` | `found` | `found` | `found` | `gift_destroy_all_creatures_return_own_destroyed_creature` |
| `Pearl Medallion` | `high` | `battle_support` | `review_promotion_gap_with_external_reference` | `found` | `found` | `found` | `ramp_permanent` |
| `Emeria's Call // Emeria, Shattered Skyclave` | `high` | `support_or_passive` | `rule_entry_or_runtime_gap_with_external_reference` | `found` | `found` | `not_found` | `ramp_permanent` |
| `Molecule Man` | `high` | `support_or_passive` | `rule_entry_or_runtime_gap_with_external_reference` | `found` | `not_found` | `found` | `passive` |

## Review Packets

### Promise of Loyalty

- Gap bucket: `review_promotion_gap_with_external_reference`
- Findings: `no_trusted_executable_rule, review_only_or_needs_review_rule`
- Recommended next action: Compare external implementation with local candidate, then promote only after focused test/replay evidence.
- Candidate logical rule key: `battle_rule_v1:e3b94411396c52ab0a06073c713ca311`
- Candidate oracle hash: `21dd715160fde6e50b8edc015ce83b0f`
- Candidate effect_json: `{"battle_model_scope": "each_player_choose_creature_vow_counter_sacrifice_other_creatures_attack_restriction_v1", "effect": "vow_counter_each_player_sacrifice_rest"}`

External reference status:

- Scryfall: `found`
- XMage: `not_found`
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
- Candidate logical rule key: `battle_rule_v1:ab6fc2c330ed49bd22c8673c4f73cfba`
- Candidate oracle hash: `3429884949eac8ffe09d86dc85bee1ae`
- Candidate effect_json: `{"battle_model_scope": "gift_card_destroy_all_creatures_return_one_own_creature_destroyed_this_way_v1", "effect": "gift_destroy_all_creatures_return_own_destroyed_creature"}`

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
- Candidate logical rule key: `battle_rule_v1:89c700f1430ffdfd1b0122e12ba363d0`
- Candidate oracle hash: `77f7f449ee56143d6b63814fecd37176`
- Candidate effect_json: `{"battle_model_scope": "static_cost_reduction_for_matching_spells_v1", "effect": "ramp_permanent"}`

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

### Emeria's Call // Emeria, Shattered Skyclave

- Gap bucket: `rule_entry_or_runtime_gap_with_external_reference`
- Findings: `no_active_battle_rule`
- Recommended next action: Use external implementation to decide whether a rule entry is enough or runtime support is required.
- Candidate logical rule key: `battle_rule_v1:cb1e6dfc098fb6c9efa7a91eeeace92e`
- Candidate oracle hash: `dc58cda92b87365d5d89339bf7116f44`
- Candidate effect_json: `{"battle_model_scope": "external_reference_required_ramp_permanent_variant_v1", "effect": "ramp_permanent"}`

External reference status:

- Scryfall: `found`
- XMage: `found`
- Forge: `not_found`

Evidence checklist:

- Confirm current Oracle text and oracle_hash against PostgreSQL/Scryfall.
- Compare XMage/Forge/parser reference with ManaLoom compact effect model.
- Decide whether runtime code is required or existing executor already supports the effect.
- Prepare SQL as dry-run/precheck/postcheck/rollback before any apply.
- Add or update focused unit test for the selected effect model.
- Run focused replay/events and verify selected logical_rule_key.
- Rerun deck_card_battle_rule_coherence_audit for impacted decks.

### Molecule Man

- Gap bucket: `rule_entry_or_runtime_gap_with_external_reference`
- Findings: `no_active_battle_rule`
- Recommended next action: Use external implementation to decide whether a rule entry is enough or runtime support is required.
- Candidate logical rule key: `battle_rule_v1:28c659fee7b5914766dd9e3f3252a4c3`
- Candidate oracle hash: `35e82bd52776c455745138b048ccc116`
- Candidate effect_json: `{"battle_model_scope": "external_reference_required_manual_model_v1", "effect": "passive"}`

External reference status:

- Scryfall: `found`
- XMage: `not_found`
- Forge: `found`

Evidence checklist:

- Confirm current Oracle text and oracle_hash against PostgreSQL/Scryfall.
- Compare XMage/Forge/parser reference with ManaLoom compact effect model.
- Decide whether runtime code is required or existing executor already supports the effect.
- Prepare SQL as dry-run/precheck/postcheck/rollback before any apply.
- Add or update focused unit test for the selected effect model.
- Run focused replay/events and verify selected logical_rule_key.
- Rerun deck_card_battle_rule_coherence_audit for impacted decks.
