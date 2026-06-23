# XMage Batch Validity Audit

Generated at: `2026-06-23T17:52:46+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"audited_card_count": 13, "exact_xmage_found_count": 11, "focused_test_scenario_ready_count": 11, "missing_xmage_class_count": 2, "ready_for_structured_pull_count": 11, "severity_counts": {"high": 9, "medium": 4}, "status_counts": {"blocked_missing_xmage_class": 2, "ready_for_structured_xmage_pull_review_required": 11}, "valid_xmage_source_count": 11}`

| Card | Severity | Status | XMage class | Mana | Types | Primary effect | Test scenarios |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Promise of Loyalty` | `high` | `ready_for_structured_xmage_pull_review_required` | `PromiseOfLoyalty` | `{4}{W} / expected {4}{W} / match True` | `SORCERY / expected SORCERY / match True` | `vow_counter_each_player_sacrifice_rest` | `3` |
| `Starfall Invocation` | `high` | `ready_for_structured_xmage_pull_review_required` | `StarfallInvocation` | `{3}{W}{W} / expected {3}{W}{W} / match True` | `SORCERY / expected SORCERY / match True` | `gift_destroy_all_creatures_return_own_destroyed_creature` | `2` |
| `Pearl Medallion` | `high` | `ready_for_structured_xmage_pull_review_required` | `PearlMedallion` | `{2} / expected {2} / match True` | `ARTIFACT / expected ARTIFACT / match True` | `static_cost_reduction` | `2` |
| `Emeria's Call // Emeria, Shattered Skyclave` | `high` | `ready_for_structured_xmage_pull_review_required` | `EmeriasCall` | `{4}{W}{W}{W} / expected None / match None` | `LAND,SORCERY / expected LAND,SORCERY / match True` | `token_maker` | `2` |
| `Molecule Man` | `high` | `blocked_missing_xmage_class` | `None` | `None / expected {6} / match None` | ` / expected CREATURE / match None` | `None` | `None` |
| `The Mind Stone` | `high` | `ready_for_structured_xmage_pull_review_required` | `TheMindStone` | `{1}{W} / expected {1}{W} / match True` | `ARTIFACT / expected ARTIFACT / match True` | `mana_rock_with_harnessed_blink` | `1` |
| `The Scarlet Witch` | `high` | `ready_for_structured_xmage_pull_review_required` | `TheScarletWitch` | `{2}{R} / expected {2}{R} / match True` | `CREATURE / expected CREATURE / match True` | `static_cost_reduction` | `2` |
| `Thor, God of Thunder` | `high` | `blocked_missing_xmage_class` | `None` | `None / expected {3}{R}{R} / match None` | ` / expected CREATURE / match None` | `None` | `None` |
| `Tragic Arrogance` | `high` | `ready_for_structured_xmage_pull_review_required` | `TragicArrogance` | `{3}{W}{W} / expected {3}{W}{W} / match True` | `SORCERY / expected SORCERY / match True` | `selective_nonland_sacrifice` | `2` |
| `Bender's Waterskin` | `medium` | `ready_for_structured_xmage_pull_review_required` | `BendersWaterskin` | `{3} / expected {3} / match True` | `ARTIFACT / expected ARTIFACT / match True` | `other_turn_untapping_any_color_mana_rock` | `1` |
| `Victory Chimes` | `medium` | `ready_for_structured_xmage_pull_review_required` | `VictoryChimes` | `{3} / expected {3} / match True` | `ARTIFACT / expected ARTIFACT / match True` | `other_turn_untapping_target_player_colorless_mana_rock` | `1` |
| `Monument to Endurance` | `medium` | `ready_for_structured_xmage_pull_review_required` | `MonumentToEndurance` | `{3} / expected {3} / match True` | `ARTIFACT / expected ARTIFACT / match True` | `discard_trigger_modal_draw_treasure_opponent_life_loss` | `1` |
| `Surge to Victory` | `medium` | `ready_for_structured_xmage_pull_review_required` | `SurgeToVictory` | `{4}{R}{R} / expected {4}{R}{R} / match True` | `SORCERY / expected SORCERY / match True` | `exile_instant_sorcery_boost_combat_damage_copy_cast` | `1` |

## Decisions

### Promise of Loyalty

- Status: `ready_for_structured_xmage_pull_review_required`
- Valid XMage source: `True`
- Ready for structured pull: `True`
- Reason: Exact XMage class, compatible metadata, a specific structured effect candidate, and focused test scenarios were found; still requires implemented ManaLoom tests/review before PG promotion.
- Coherence findings: `["no_trusted_executable_rule", "review_only_or_needs_review_rule"]`
- Focused test scenarios: `3`

### Starfall Invocation

- Status: `ready_for_structured_xmage_pull_review_required`
- Valid XMage source: `True`
- Ready for structured pull: `True`
- Reason: Exact XMage class, compatible metadata, a specific structured effect candidate, and focused test scenarios were found; still requires implemented ManaLoom tests/review before PG promotion.
- Coherence findings: `["no_trusted_executable_rule", "review_only_or_needs_review_rule"]`
- Focused test scenarios: `2`

### Pearl Medallion

- Status: `ready_for_structured_xmage_pull_review_required`
- Valid XMage source: `True`
- Ready for structured pull: `True`
- Reason: Exact XMage class, compatible metadata, a specific structured effect candidate, and focused test scenarios were found; still requires implemented ManaLoom tests/review before PG promotion.
- Coherence findings: `["no_trusted_executable_rule", "review_only_or_needs_review_rule"]`
- Focused test scenarios: `2`

### Emeria's Call // Emeria, Shattered Skyclave

- Status: `ready_for_structured_xmage_pull_review_required`
- Valid XMage source: `True`
- Ready for structured pull: `True`
- Reason: Exact XMage class, compatible metadata, a specific structured effect candidate, and focused test scenarios were found; still requires implemented ManaLoom tests/review before PG promotion.
- Coherence findings: `["no_active_battle_rule"]`
- Focused test scenarios: `2`

### Molecule Man

- Status: `blocked_missing_xmage_class`
- Valid XMage source: `False`
- Ready for structured pull: `False`
- Reason: No exact local XMage implementation class was resolved for this card name.
- Coherence findings: `["no_active_battle_rule"]`
- Focused test scenarios: `None`

### The Mind Stone

- Status: `ready_for_structured_xmage_pull_review_required`
- Valid XMage source: `True`
- Ready for structured pull: `True`
- Reason: Exact XMage class, compatible metadata, a specific structured effect candidate, and focused test scenarios were found; still requires implemented ManaLoom tests/review before PG promotion.
- Coherence findings: `["no_active_battle_rule"]`
- Focused test scenarios: `1`

### The Scarlet Witch

- Status: `ready_for_structured_xmage_pull_review_required`
- Valid XMage source: `True`
- Ready for structured pull: `True`
- Reason: Exact XMage class, compatible metadata, a specific structured effect candidate, and focused test scenarios were found; still requires implemented ManaLoom tests/review before PG promotion.
- Coherence findings: `["no_active_battle_rule"]`
- Focused test scenarios: `2`

### Thor, God of Thunder

- Status: `blocked_missing_xmage_class`
- Valid XMage source: `False`
- Ready for structured pull: `False`
- Reason: No exact local XMage implementation class was resolved for this card name.
- Coherence findings: `["no_active_battle_rule"]`
- Focused test scenarios: `None`

### Tragic Arrogance

- Status: `ready_for_structured_xmage_pull_review_required`
- Valid XMage source: `True`
- Ready for structured pull: `True`
- Reason: Exact XMage class, compatible metadata, a specific structured effect candidate, and focused test scenarios were found; still requires implemented ManaLoom tests/review before PG promotion.
- Coherence findings: `["no_active_battle_rule"]`
- Focused test scenarios: `2`

### Bender's Waterskin

- Status: `ready_for_structured_xmage_pull_review_required`
- Valid XMage source: `True`
- Ready for structured pull: `True`
- Reason: Exact XMage class, compatible metadata, a specific structured effect candidate, and focused test scenarios were found; still requires implemented ManaLoom tests/review before PG promotion.
- Coherence findings: `["generic_effect_without_model_scope", "trusted_rule_without_oracle_hash"]`
- Focused test scenarios: `1`

### Victory Chimes

- Status: `ready_for_structured_xmage_pull_review_required`
- Valid XMage source: `True`
- Ready for structured pull: `True`
- Reason: Exact XMage class, compatible metadata, a specific structured effect candidate, and focused test scenarios were found; still requires implemented ManaLoom tests/review before PG promotion.
- Coherence findings: `["trusted_rule_without_oracle_hash"]`
- Focused test scenarios: `1`

### Monument to Endurance

- Status: `ready_for_structured_xmage_pull_review_required`
- Valid XMage source: `True`
- Ready for structured pull: `True`
- Reason: Exact XMage class, compatible metadata, a specific structured effect candidate, and focused test scenarios were found; still requires implemented ManaLoom tests/review before PG promotion.
- Coherence findings: `["trusted_rule_without_oracle_hash"]`
- Focused test scenarios: `1`

### Surge to Victory

- Status: `ready_for_structured_xmage_pull_review_required`
- Valid XMage source: `True`
- Ready for structured pull: `True`
- Reason: Exact XMage class, compatible metadata, a specific structured effect candidate, and focused test scenarios were found; still requires implemented ManaLoom tests/review before PG promotion.
- Coherence findings: `["trusted_rule_without_oracle_hash"]`
- Focused test scenarios: `1`
