# External Card Rule Reference Harvest

Generated at: `2026-06-23T15:39:34+00:00`

This is a read-only reference packet. It does not mutate PostgreSQL, SQLite, decks, runtime code, or reviewed rules.

## Source Audit

- Deck id: `607`
- Severity counts: `{"high": 9, "medium": 4, "pass": 81}`
- Finding counts: `{"generic_effect_without_model_scope": 1, "no_active_battle_rule": 6, "no_trusted_executable_rule": 3, "review_only_or_needs_review_rule": 3, "trusted_rule_without_oracle_hash": 4}`

## Cards

| Card | Severity | Impact | Gap bucket | Scryfall | XMage | Forge | Candidate effect |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Promise of Loyalty` | `high` | `battle_critical` | `review_promotion_gap_with_external_reference` | `skipped_offline` | `found` | `skipped_offline` | `vow_counter_each_player_sacrifice_rest` |
| `Starfall Invocation` | `high` | `battle_critical` | `review_promotion_gap_with_external_reference` | `skipped_offline` | `found` | `skipped_offline` | `gift_destroy_all_creatures_return_own_destroyed_creature` |
| `Pearl Medallion` | `high` | `battle_support` | `review_promotion_gap_with_external_reference` | `skipped_offline` | `found` | `skipped_offline` | `static_cost_reduction` |
| `Emeria's Call // Emeria, Shattered Skyclave` | `high` | `support_or_passive` | `rule_entry_or_runtime_gap_with_external_reference` | `skipped_offline` | `found` | `skipped_offline` | `token_maker` |
| `Molecule Man` | `high` | `support_or_passive` | `rule_entry_or_runtime_gap` | `skipped_offline` | `not_found` | `skipped_offline` | `passive` |
| `The Mind Stone` | `high` | `support_or_passive` | `rule_entry_or_runtime_gap_with_external_reference` | `skipped_offline` | `found` | `skipped_offline` | `mana_rock_with_harnessed_blink` |
| `The Scarlet Witch` | `high` | `support_or_passive` | `rule_entry_or_runtime_gap_with_external_reference` | `skipped_offline` | `found` | `skipped_offline` | `static_cost_reduction` |
| `Thor, God of Thunder` | `high` | `support_or_passive` | `rule_entry_or_runtime_gap` | `skipped_offline` | `not_found` | `skipped_offline` | `passive` |
| `Tragic Arrogance` | `high` | `support_or_passive` | `rule_entry_or_runtime_gap_with_external_reference` | `skipped_offline` | `found` | `skipped_offline` | `selective_nonland_sacrifice` |

## Review Packets

### Promise of Loyalty

- Gap bucket: `review_promotion_gap_with_external_reference`
- Findings: `no_trusted_executable_rule, review_only_or_needs_review_rule`
- Recommended next action: Compare external implementation with local candidate, then promote only after focused test/replay evidence.
- Candidate logical rule key: `battle_rule_v1:780736470bfbd01e4d3d453bf87d1e8d`
- Candidate oracle hash: `None`
- Candidate effect_json: `{"ability_kind": "one_shot", "battle_model_scope": "each_player_choose_creature_vow_counter_sacrifice_other_creatures_attack_restriction_v1", "effect": "vow_counter_each_player_sacrifice_rest", "xmage_hint_policy": "review_candidate_only"}`

External reference status:

- Scryfall: `skipped_offline`
- XMage: `found`
- Forge: `skipped_offline`

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
- Candidate oracle hash: `None`
- Candidate effect_json: `{"ability_kind": "one_shot", "battle_model_scope": "gift_card_destroy_all_creatures_return_one_own_creature_destroyed_this_way_v1", "effect": "gift_destroy_all_creatures_return_own_destroyed_creature", "xmage_hint_policy": "review_candidate_only"}`

External reference status:

- Scryfall: `skipped_offline`
- XMage: `found`
- Forge: `skipped_offline`

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
- Candidate logical rule key: `battle_rule_v1:0c9aeb512c5fe30d7381ab4fd2b09129`
- Candidate oracle hash: `None`
- Candidate effect_json: `{"ability_kind": "static", "battle_model_scope": "static_cost_reduction_for_matching_spells_v1", "effect": "static_cost_reduction", "xmage_hint_policy": "review_candidate_only"}`

External reference status:

- Scryfall: `skipped_offline`
- XMage: `found`
- Forge: `skipped_offline`

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
- Candidate logical rule key: `battle_rule_v1:638bd54b45699c1b5928346f331e9efa`
- Candidate oracle hash: `None`
- Candidate effect_json: `{"ability_kind": "one_shot", "battle_model_scope": "xmage_create_token_variant_emeriascall_v1", "effect": "token_maker", "xmage_hint_policy": "review_candidate_only"}`

External reference status:

- Scryfall: `skipped_offline`
- XMage: `found`
- Forge: `skipped_offline`

Evidence checklist:

- Confirm current Oracle text and oracle_hash against PostgreSQL/Scryfall.
- Compare XMage/Forge/parser reference with ManaLoom compact effect model.
- Decide whether runtime code is required or existing executor already supports the effect.
- Prepare SQL as dry-run/precheck/postcheck/rollback before any apply.
- Add or update focused unit test for the selected effect model.
- Run focused replay/events and verify selected logical_rule_key.
- Rerun deck_card_battle_rule_coherence_audit for impacted decks.

### Molecule Man

- Gap bucket: `rule_entry_or_runtime_gap`
- Findings: `no_active_battle_rule`
- Recommended next action: Create a candidate rule entry only after manual model review.
- Candidate logical rule key: `battle_rule_v1:28c659fee7b5914766dd9e3f3252a4c3`
- Candidate oracle hash: `None`
- Candidate effect_json: `{"battle_model_scope": "external_reference_required_manual_model_v1", "effect": "passive"}`

External reference status:

- Scryfall: `skipped_offline`
- XMage: `not_found`
- Forge: `skipped_offline`

Evidence checklist:

- Confirm current Oracle text and oracle_hash against PostgreSQL/Scryfall.
- Compare XMage/Forge/parser reference with ManaLoom compact effect model.
- Decide whether runtime code is required or existing executor already supports the effect.
- Prepare SQL as dry-run/precheck/postcheck/rollback before any apply.
- Add or update focused unit test for the selected effect model.
- Run focused replay/events and verify selected logical_rule_key.
- Rerun deck_card_battle_rule_coherence_audit for impacted decks.

### The Mind Stone

- Gap bucket: `rule_entry_or_runtime_gap_with_external_reference`
- Findings: `no_active_battle_rule`
- Recommended next action: Use external implementation to decide whether a rule entry is enough or runtime support is required.
- Candidate logical rule key: `battle_rule_v1:b0d564c8f255e00493dd2ed2dd46a785`
- Candidate oracle hash: `None`
- Candidate effect_json: `{"ability_kind": "activated", "battle_model_scope": "legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1", "effect": "mana_rock_with_harnessed_blink", "target_constraints": {"card_types": ["permanent"], "controller_scope": "source_controller"}, "xmage_hint_policy": "review_candidate_only"}`

External reference status:

- Scryfall: `skipped_offline`
- XMage: `found`
- Forge: `skipped_offline`

Evidence checklist:

- Confirm current Oracle text and oracle_hash against PostgreSQL/Scryfall.
- Compare XMage/Forge/parser reference with ManaLoom compact effect model.
- Decide whether runtime code is required or existing executor already supports the effect.
- Prepare SQL as dry-run/precheck/postcheck/rollback before any apply.
- Add or update focused unit test for the selected effect model.
- Run focused replay/events and verify selected logical_rule_key.
- Rerun deck_card_battle_rule_coherence_audit for impacted decks.

### The Scarlet Witch

- Gap bucket: `rule_entry_or_runtime_gap_with_external_reference`
- Findings: `no_active_battle_rule`
- Recommended next action: Use external implementation to decide whether a rule entry is enough or runtime support is required.
- Candidate logical rule key: `battle_rule_v1:ec562cf9428f8746e177a21b214a56c8`
- Candidate oracle hash: `None`
- Candidate effect_json: `{"ability_kind": "static", "battle_model_scope": "static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1", "effect": "static_cost_reduction", "xmage_hint_policy": "review_candidate_only"}`

External reference status:

- Scryfall: `skipped_offline`
- XMage: `found`
- Forge: `skipped_offline`

Evidence checklist:

- Confirm current Oracle text and oracle_hash against PostgreSQL/Scryfall.
- Compare XMage/Forge/parser reference with ManaLoom compact effect model.
- Decide whether runtime code is required or existing executor already supports the effect.
- Prepare SQL as dry-run/precheck/postcheck/rollback before any apply.
- Add or update focused unit test for the selected effect model.
- Run focused replay/events and verify selected logical_rule_key.
- Rerun deck_card_battle_rule_coherence_audit for impacted decks.

### Thor, God of Thunder

- Gap bucket: `rule_entry_or_runtime_gap`
- Findings: `no_active_battle_rule`
- Recommended next action: Create a candidate rule entry only after manual model review.
- Candidate logical rule key: `battle_rule_v1:28c659fee7b5914766dd9e3f3252a4c3`
- Candidate oracle hash: `None`
- Candidate effect_json: `{"battle_model_scope": "external_reference_required_manual_model_v1", "effect": "passive"}`

External reference status:

- Scryfall: `skipped_offline`
- XMage: `not_found`
- Forge: `skipped_offline`

Evidence checklist:

- Confirm current Oracle text and oracle_hash against PostgreSQL/Scryfall.
- Compare XMage/Forge/parser reference with ManaLoom compact effect model.
- Decide whether runtime code is required or existing executor already supports the effect.
- Prepare SQL as dry-run/precheck/postcheck/rollback before any apply.
- Add or update focused unit test for the selected effect model.
- Run focused replay/events and verify selected logical_rule_key.
- Rerun deck_card_battle_rule_coherence_audit for impacted decks.

### Tragic Arrogance

- Gap bucket: `rule_entry_or_runtime_gap_with_external_reference`
- Findings: `no_active_battle_rule`
- Recommended next action: Use external implementation to decide whether a rule entry is enough or runtime support is required.
- Candidate logical rule key: `battle_rule_v1:a2edc3b4c8eb1dfbe59a73e5ebfafdc3`
- Candidate oracle hash: `None`
- Candidate effect_json: `{"ability_kind": "one_shot", "battle_model_scope": "controller_chooses_artifact_creature_enchantment_planeswalker_per_player_sacrifice_other_nonlands_v1", "effect": "selective_nonland_sacrifice", "xmage_hint_policy": "review_candidate_only"}`

External reference status:

- Scryfall: `skipped_offline`
- XMage: `found`
- Forge: `skipped_offline`

Evidence checklist:

- Confirm current Oracle text and oracle_hash against PostgreSQL/Scryfall.
- Compare XMage/Forge/parser reference with ManaLoom compact effect model.
- Decide whether runtime code is required or existing executor already supports the effect.
- Prepare SQL as dry-run/precheck/postcheck/rollback before any apply.
- Add or update focused unit test for the selected effect model.
- Run focused replay/events and verify selected logical_rule_key.
- Rerun deck_card_battle_rule_coherence_audit for impacted decks.
