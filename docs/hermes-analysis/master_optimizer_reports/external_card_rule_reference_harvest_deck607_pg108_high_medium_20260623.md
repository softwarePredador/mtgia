# External Card Rule Reference Harvest

Generated at: `2026-06-23T17:16:19+00:00`

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
| `Emeria's Call // Emeria, Shattered Skyclave` | `high` | `support_or_passive` | `rule_entry_or_runtime_gap_with_external_reference` | `found` | `found` | `not_found` | `token_maker` |
| `Molecule Man` | `high` | `support_or_passive` | `rule_entry_or_runtime_gap_with_external_reference` | `found` | `not_found` | `found` | `passive` |
| `The Mind Stone` | `high` | `support_or_passive` | `rule_entry_or_runtime_gap_with_external_reference` | `found` | `found` | `found` | `mana_rock_with_harnessed_blink` |
| `The Scarlet Witch` | `high` | `support_or_passive` | `rule_entry_or_runtime_gap_with_external_reference` | `found` | `found` | `found` | `static_cost_reduction` |
| `Thor, God of Thunder` | `high` | `support_or_passive` | `rule_entry_or_runtime_gap_with_external_reference` | `found` | `not_found` | `found` | `passive` |
| `Tragic Arrogance` | `high` | `support_or_passive` | `rule_entry_or_runtime_gap_with_external_reference` | `found` | `found` | `found` | `selective_nonland_sacrifice` |
| `Bender's Waterskin` | `medium` | `battle_support` | `metadata_scope_gap` | `found` | `found` | `not_found` | `ramp_permanent` |
| `Victory Chimes` | `medium` | `battle_support` | `metadata_hash_gap` | `found` | `found` | `found` | `ramp_permanent` |
| `Monument to Endurance` | `medium` | `support_or_passive` | `metadata_hash_gap` | `found` | `found` | `found` | `token_maker` |
| `Surge to Victory` | `medium` | `support_or_passive` | `metadata_hash_gap` | `found` | `found` | `found` | `pump_all` |

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

### Emeria's Call // Emeria, Shattered Skyclave

- Gap bucket: `rule_entry_or_runtime_gap_with_external_reference`
- Findings: `no_active_battle_rule`
- Recommended next action: Use external implementation to decide whether a rule entry is enough or runtime support is required.
- Candidate logical rule key: `battle_rule_v1:638bd54b45699c1b5928346f331e9efa`
- Candidate oracle hash: `dc58cda92b87365d5d89339bf7116f44`
- Candidate effect_json: `{"ability_kind": "one_shot", "battle_model_scope": "xmage_create_token_variant_emeriascall_v1", "effect": "token_maker", "xmage_hint_policy": "review_candidate_only"}`

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

### The Mind Stone

- Gap bucket: `rule_entry_or_runtime_gap_with_external_reference`
- Findings: `no_active_battle_rule`
- Recommended next action: Use external implementation to decide whether a rule entry is enough or runtime support is required.
- Candidate logical rule key: `battle_rule_v1:b0d564c8f255e00493dd2ed2dd46a785`
- Candidate oracle hash: `17bda9d167ae2799376387d03be5681f`
- Candidate effect_json: `{"ability_kind": "activated", "battle_model_scope": "legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1", "effect": "mana_rock_with_harnessed_blink", "target_constraints": {"card_types": ["permanent"], "controller_scope": "source_controller"}, "xmage_hint_policy": "review_candidate_only"}`

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

### The Scarlet Witch

- Gap bucket: `rule_entry_or_runtime_gap_with_external_reference`
- Findings: `no_active_battle_rule`
- Recommended next action: Use external implementation to decide whether a rule entry is enough or runtime support is required.
- Candidate logical rule key: `battle_rule_v1:5cde9245d28bb10b635e63d18beb946c`
- Candidate oracle hash: `6129fda2f5ae1f8edad5a2f2e77d05c2`
- Candidate effect_json: `{"ability_kind": "static", "battle_model_scope": "static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1", "effect": "static_cost_reduction", "xmage_hint_policy": "review_candidate_only"}`

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

### Thor, God of Thunder

- Gap bucket: `rule_entry_or_runtime_gap_with_external_reference`
- Findings: `no_active_battle_rule`
- Recommended next action: Use external implementation to decide whether a rule entry is enough or runtime support is required.
- Candidate logical rule key: `battle_rule_v1:28c659fee7b5914766dd9e3f3252a4c3`
- Candidate oracle hash: `0f2238f2ce8e4f2c0bbc2d5cea55f4d7`
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

### Tragic Arrogance

- Gap bucket: `rule_entry_or_runtime_gap_with_external_reference`
- Findings: `no_active_battle_rule`
- Recommended next action: Use external implementation to decide whether a rule entry is enough or runtime support is required.
- Candidate logical rule key: `battle_rule_v1:a2edc3b4c8eb1dfbe59a73e5ebfafdc3`
- Candidate oracle hash: `efdf5d051aaa7f94b12c4dccbbfd7d3d`
- Candidate effect_json: `{"ability_kind": "one_shot", "battle_model_scope": "controller_chooses_artifact_creature_enchantment_planeswalker_per_player_sacrifice_other_nonlands_v1", "effect": "selective_nonland_sacrifice", "xmage_hint_policy": "review_candidate_only"}`

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

### Bender's Waterskin

- Gap bucket: `metadata_scope_gap`
- Findings: `generic_effect_without_model_scope, trusted_rule_without_oracle_hash`
- Recommended next action: Add or restore battle_model_scope/oracle-specific metadata, then run focused tests.
- Candidate logical rule key: `battle_rule_v1:cb1e6dfc098fb6c9efa7a91eeeace92e`
- Candidate oracle hash: `1bd371e1f09ed8b48837c3fc5cd2a2ff`
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

### Victory Chimes

- Gap bucket: `metadata_hash_gap`
- Findings: `trusted_rule_without_oracle_hash`
- Recommended next action: Restore oracle_hash from current Oracle text if the executable rule is otherwise trusted.
- Candidate logical rule key: `battle_rule_v1:cb1e6dfc098fb6c9efa7a91eeeace92e`
- Candidate oracle hash: `8ca84e1f2e9f3efd1fe740d16d216105`
- Candidate effect_json: `{"battle_model_scope": "external_reference_required_ramp_permanent_variant_v1", "effect": "ramp_permanent"}`

External reference status:

- Scryfall: `found`
- XMage: `found`
- Forge: `found`

Evidence checklist:

- Confirm current Oracle text and oracle_hash against PostgreSQL/Scryfall.
- Verify no runtime semantic change is needed before metadata-only restore.
- Compare XMage/Forge/parser reference with ManaLoom compact effect model.
- Decide whether runtime code is required or existing executor already supports the effect.
- Prepare SQL as dry-run/precheck/postcheck/rollback before any apply.
- Add or update focused unit test for the selected effect model.
- Run focused replay/events and verify selected logical_rule_key.
- Rerun deck_card_battle_rule_coherence_audit for impacted decks.

### Monument to Endurance

- Gap bucket: `metadata_hash_gap`
- Findings: `trusted_rule_without_oracle_hash`
- Recommended next action: Restore oracle_hash from current Oracle text if the executable rule is otherwise trusted.
- Candidate logical rule key: `battle_rule_v1:201e6c7e3067699cde7a3c5975bea2cc`
- Candidate oracle hash: `a60dc736f7e86e15001c8c7e59ff23c4`
- Candidate effect_json: `{"ability_kind": "triggered", "battle_model_scope": "xmage_create_token_variant_monumenttoendurance_v1", "effect": "token_maker", "xmage_hint_policy": "review_candidate_only"}`

External reference status:

- Scryfall: `found`
- XMage: `found`
- Forge: `found`

Evidence checklist:

- Confirm current Oracle text and oracle_hash against PostgreSQL/Scryfall.
- Verify no runtime semantic change is needed before metadata-only restore.
- Compare XMage/Forge/parser reference with ManaLoom compact effect model.
- Decide whether runtime code is required or existing executor already supports the effect.
- Prepare SQL as dry-run/precheck/postcheck/rollback before any apply.
- Add or update focused unit test for the selected effect model.
- Run focused replay/events and verify selected logical_rule_key.
- Rerun deck_card_battle_rule_coherence_audit for impacted decks.

### Surge to Victory

- Gap bucket: `metadata_hash_gap`
- Findings: `trusted_rule_without_oracle_hash`
- Recommended next action: Restore oracle_hash from current Oracle text if the executable rule is otherwise trusted.
- Candidate logical rule key: `battle_rule_v1:7a40298d748a03bc6f20a89072d006fd`
- Candidate oracle hash: `5381f78ff0798b9afad371e0fa495831`
- Candidate effect_json: `{"battle_model_scope": "external_reference_required_pump_all_variant_v1", "effect": "pump_all"}`

External reference status:

- Scryfall: `found`
- XMage: `found`
- Forge: `found`

Evidence checklist:

- Confirm current Oracle text and oracle_hash against PostgreSQL/Scryfall.
- Verify no runtime semantic change is needed before metadata-only restore.
- Compare XMage/Forge/parser reference with ManaLoom compact effect model.
- Decide whether runtime code is required or existing executor already supports the effect.
- Prepare SQL as dry-run/precheck/postcheck/rollback before any apply.
- Add or update focused unit test for the selected effect model.
- Run focused replay/events and verify selected logical_rule_key.
- Rerun deck_card_battle_rule_coherence_audit for impacted decks.
