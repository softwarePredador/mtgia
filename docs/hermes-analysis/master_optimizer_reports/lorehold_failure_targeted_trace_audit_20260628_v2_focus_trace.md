# Lorehold Failure-Targeted Trace Audit - 2026-06-28

- Generated at: `2026-06-28T03:00:02Z`
- Candidate key: `candidate_607_squee_hashseed0_isolated_cached_timeout_v3`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Recommended next action: `review_focus_trace_payload_then_define_next_runtime_or_package_test`
- Focus cards: `8`
- Primary seed records: `3`
- Seed source reports: `6`
- Hypotheses: `4`
- Trace statuses: `{"runtime_trace_payload_available_review_model_scope": 1, "trace_evidence_supports_sequencing_gap": 1, "trace_partial_missing_payload": 2}`
- Primary trace levels: `{"per_game_event_counts": 3}`

## Seed Records

| Seed | Trace Level | W | L | S | WR | Miracle | Topdeck | Lorehold Rummage | Squee GY | Squee Return | Squee Trace Games | Source |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 7 | `per_game_event_counts` | 0 | 9 | 0 | 0.00% | 4 | 2 | 27 | 0 | 0 | 0 | `docs/hermes-analysis/master_optimizer_reports/lorehold_focus_trace_diag_seed7_20260628_v1.json` |
| 42 | `per_game_event_counts` | 7 | 2 | 0 | 77.78% | 32 | 30 | 39 | 7 | 5 | 5 | `docs/hermes-analysis/master_optimizer_reports/lorehold_focus_trace_diag_seed42_candidate_only_20260628_v1.json` |
| 20260625 | `per_game_event_counts` | 0 | 9 | 0 | 0.00% | 4 | 3 | 38 | 0 | 0 | 0 | `docs/hermes-analysis/master_optimizer_reports/lorehold_focus_trace_diag_seed20260625_20260628_v1.json` |

## Focus Card Evidence

### Seed 7

- `Urza's Saga`: level=`focus_card_trace_available`, metrics=`-`, events=`saga_chapter_progressed=4, saga_chapter_resolved=2, saga_sacrificed_by_sba=2, tutor_resolved=7`, games_with=`saga_chapter_progressed=2, saga_chapter_resolved=2, saga_sacrificed_by_sba=2, tutor_resolved=6`, trace=`-`, focus_trace=`saga_chapter_progressed=4, saga_chapter_resolved=2, saga_sacrificed_by_sba=2`, focus_fields=`candidate_count, candidate_names, card, chapter, found, legal_target_count, legal_target_names, player, selected_reason, target_type, turn`
- `Library of Leng`: level=`focus_card_trace_available`, metrics=`-`, events=`replacement_applied=9`, games_with=`replacement_applied=4`, trace=`-`, focus_trace=`saga_chapter_resolved=2`, focus_fields=`candidate_count, candidate_names, card, chapter, found, legal_target_count, legal_target_names, player, selected_reason, target_type, turn`
- `Sensei's Divining Top`: level=`focus_card_trace_available`, metrics=`-`, events=`topdeck_manipulation_activated=2`, games_with=`topdeck_manipulation_activated=1`, trace=`-`, focus_trace=`cost_paid=1, saga_chapter_resolved=2`, focus_fields=`candidate_count, candidate_names, card, chapter, effect, found, legal_target_count, legal_target_names, phase, player, rule_logical_key, rule_oracle_hash, rule_review_status, selected_reason, target_type, turn`
- `Scroll Rack`: level=`focus_card_trace_available`, metrics=`topdeck:Scroll Rack=2`, events=`topdeck_manipulation_activated=2`, games_with=`topdeck_manipulation_activated=1`, trace=`-`, focus_trace=`cost_paid=1, topdeck_manipulation_activated=2, trigger_resolved=1`, focus_fields=`activation_kind, card, effect, hand_gained, hand_to_top, phase, player, rule_logical_key, rule_oracle_hash, rule_review_status, top_after, top_before, trigger, turn`
- `Squee, Goblin Nabob`: level=`not_observed`, metrics=`-`, events=`-`, games_with=`-`, trace=`-`, focus_trace=`-`, focus_fields=`-`
- `The Mind Stone`: level=`focus_card_trace_available`, metrics=`-`, events=`-`, games_with=`-`, trace=`-`, focus_trace=`cost_paid=1`, focus_fields=`card, effect, phase, player, rule_logical_key, rule_oracle_hash, rule_review_status, turn`
- `Land Tax`: level=`focus_card_trace_available`, metrics=`-`, events=`land_tax_trigger_resolved=1, land_tax_trigger_skipped=3`, games_with=`land_tax_trigger_resolved=1, land_tax_trigger_skipped=1`, trace=`-`, focus_trace=`cost_paid=1, land_tax_trigger_resolved=1, land_tax_trigger_skipped=3`, focus_fields=`card, condition, condition_met, effect, found, found_cards, found_count, max_opponent_land_count, opponent_land_counts, phase, player, player_land_count, rule_logical_key, rule_oracle_hash, rule_review_status, target_type, trigger, turn`
- `Lorehold, the Historian`: level=`focus_card_trace_available`, metrics=`cost_paid:Lorehold, the Historian=10`, events=`-`, games_with=`-`, trace=`-`, focus_trace=`cost_paid=13, lorehold_upkeep_rummage=27, replacement_applied=2`, focus_fields=`card, discard_destination, discarded, drawn, effect, phase, player, reason, replacement_used, rule_logical_key, rule_oracle_hash, rule_review_status, source, target_type, turn`

### Seed 42

- `Urza's Saga`: level=`focus_card_trace_available`, metrics=`-`, events=`saga_chapter_progressed=7, saga_chapter_resolved=3, saga_sacrificed_by_sba=3, tutor_resolved=10`, games_with=`saga_chapter_progressed=4, saga_chapter_resolved=3, saga_sacrificed_by_sba=3, tutor_resolved=7`, trace=`-`, focus_trace=`saga_chapter_progressed=7, saga_chapter_resolved=3, saga_sacrificed_by_sba=3, trigger_resolved=1`, focus_fields=`candidate_count, candidate_names, card, chapter, discarded, discarded_to_graveyard, drawn, effect, found, legal_target_count, legal_target_names, phase, player, rule_logical_key, rule_oracle_hash, rule_review_status, selected_reason, target_type, trigger, turn`
- `Library of Leng`: level=`focus_card_trace_available`, metrics=`-`, events=`replacement_applied=48`, games_with=`replacement_applied=6`, trace=`-`, focus_trace=`cost_paid=3, lorehold_upkeep_rummage=14, saga_chapter_resolved=2`, focus_fields=`candidate_count, candidate_names, card, chapter, discard_destination, discarded, drawn, effect, found, legal_target_count, legal_target_names, phase, player, reason, replacement_used, rule_logical_key, rule_oracle_hash, rule_review_status, selected_reason, target_type, turn`
- `Sensei's Divining Top`: level=`focus_card_trace_available`, metrics=`topdeck:Sensei's Divining Top=17, cost_paid:Sensei's Divining Top=5`, events=`topdeck_manipulation_activated=30`, games_with=`topdeck_manipulation_activated=5`, trace=`-`, focus_trace=`cost_paid=5, lorehold_upkeep_rummage=1, saga_chapter_resolved=2, topdeck_manipulation_activated=17, trigger_resolved=2, trigger_skipped=3`, focus_fields=`activation_kind, candidate_count, candidate_names, card, chapter, discard_destination, discarded, discarded_to_graveyard, drawn, effect, found, legal_target_count, legal_target_names, phase, player, reason, replacement_used, rule_logical_key, rule_oracle_hash, rule_review_status, selected_reason, target_type, top_after, top_before, trigger, turn`
- `Scroll Rack`: level=`focus_card_trace_available`, metrics=`topdeck:Scroll Rack=13`, events=`topdeck_manipulation_activated=30`, games_with=`topdeck_manipulation_activated=5`, trace=`topdeck_manipulation_activated=2`, focus_trace=`cost_paid=3, topdeck_manipulation_activated=13, trigger_resolved=1, trigger_skipped=1`, focus_fields=`activation_kind, card, discarded, discarded_to_top, drawn, effect, hand_gained, hand_to_top, phase, player, reason, rule_logical_key, rule_oracle_hash, rule_review_status, top_after, top_before, trigger, turn`
- `Squee, Goblin Nabob`: level=`focus_card_trace_available`, metrics=`cost_paid:Squee, Goblin Nabob=10`, events=`graveyard_upkeep_return_self_to_hand=5, squee_return_after_known_graveyard_entry=5, squee_to_graveyard=7, squee_upkeep_return=5`, games_with=`graveyard_upkeep_return_self_to_hand=2, squee_return_after_known_graveyard_entry=2, squee_to_graveyard=4, squee_upkeep_return=2`, trace=`airbend_creature_cast_from_exile=1, cast_announced=10, cost_paid=10, creature_cast=9, permanent_moved_from_battlefield=6, trigger_resolved=5`, focus_trace=`cost_paid=10, replacement_applied=7, topdeck_manipulation_activated=2, trigger_resolved=5`, focus_fields=`activation_kind, card, effect, hand_gained, hand_to_top, phase, player, reason, rule_logical_key, rule_oracle_hash, rule_review_status, source, top_after, top_before, trigger, turn`
- `The Mind Stone`: level=`focus_card_trace_available`, metrics=`-`, events=`utility_artifact_activated=2`, games_with=`utility_artifact_activated=2`, trace=`-`, focus_trace=`cost_paid=4, lorehold_upkeep_rummage=1, topdeck_manipulation_activated=1, trigger_resolved=6, trigger_skipped=1, utility_artifact_activated=1`, focus_fields=`activation_kind, blink_target, blink_target_score, blinked, card, discard_destination, discarded, drawn, effect, phase, player, reason, replacement_used, returned, rule_logical_key, rule_oracle_hash, rule_review_status, top_after, top_before, trigger, turn`
- `Land Tax`: level=`focus_card_trace_available`, metrics=`cost_paid:Land Tax=5`, events=`land_tax_trigger_resolved=2, land_tax_trigger_skipped=49`, games_with=`land_tax_trigger_resolved=1, land_tax_trigger_skipped=5`, trace=`-`, focus_trace=`cost_paid=6, land_tax_trigger_resolved=2, land_tax_trigger_skipped=49, trigger_resolved=2`, focus_fields=`card, condition, condition_met, discarded, discarded_to_graveyard, drawn, effect, found, found_cards, found_count, max_opponent_land_count, opponent_land_counts, phase, player, player_land_count, rule_logical_key, rule_oracle_hash, rule_review_status, target_type, trigger, turn`
- `Lorehold, the Historian`: level=`focus_card_trace_available`, metrics=`cost_paid:Lorehold, the Historian=14`, events=`-`, games_with=`-`, trace=`-`, focus_trace=`cost_paid=16, lorehold_upkeep_rummage=39, replacement_applied=13`, focus_fields=`card, discard_destination, discarded, drawn, effect, phase, player, reason, replacement_used, rule_logical_key, rule_oracle_hash, rule_review_status, source, target_type, turn`

### Seed 20260625

- `Urza's Saga`: level=`focus_card_trace_available`, metrics=`-`, events=`saga_chapter_progressed=4, saga_chapter_resolved=2, saga_sacrificed_by_sba=2, tutor_resolved=9`, games_with=`saga_chapter_progressed=2, saga_chapter_resolved=2, saga_sacrificed_by_sba=2, tutor_resolved=6`, trace=`-`, focus_trace=`lorehold_upkeep_rummage=1, saga_chapter_progressed=4, saga_chapter_resolved=2, saga_sacrificed_by_sba=2`, focus_fields=`candidate_count, candidate_names, card, chapter, discard_destination, discarded, drawn, found, legal_target_count, legal_target_names, player, reason, replacement_used, rule_review_status, selected_reason, target_type, turn`
- `Library of Leng`: level=`focus_card_trace_available`, metrics=`cost_paid:Library of Leng=4`, events=`replacement_applied=19`, games_with=`replacement_applied=7`, trace=`-`, focus_trace=`cost_paid=4, lorehold_upkeep_rummage=16, saga_chapter_resolved=2`, focus_fields=`candidate_count, candidate_names, card, chapter, discard_destination, discarded, drawn, effect, found, legal_target_count, legal_target_names, phase, player, reason, replacement_used, rule_logical_key, rule_oracle_hash, rule_review_status, selected_reason, target_type, turn`
- `Sensei's Divining Top`: level=`focus_card_trace_available`, metrics=`-`, events=`topdeck_manipulation_activated=3`, games_with=`topdeck_manipulation_activated=1`, trace=`-`, focus_trace=`cost_paid=4, saga_chapter_resolved=2, trigger_resolved=2`, focus_fields=`candidate_count, candidate_names, card, chapter, effect, found, legal_target_count, legal_target_names, phase, player, rule_logical_key, rule_oracle_hash, rule_review_status, selected_reason, target_type, trigger, turn`
- `Scroll Rack`: level=`focus_card_trace_available`, metrics=`topdeck:Scroll Rack=3`, events=`topdeck_manipulation_activated=3`, games_with=`topdeck_manipulation_activated=1`, trace=`-`, focus_trace=`cost_paid=2, topdeck_manipulation_activated=3`, focus_fields=`activation_kind, card, effect, hand_gained, hand_to_top, phase, player, rule_logical_key, rule_oracle_hash, rule_review_status, top_after, top_before, turn`
- `Squee, Goblin Nabob`: level=`not_observed`, metrics=`-`, events=`-`, games_with=`-`, trace=`-`, focus_trace=`-`, focus_fields=`-`
- `The Mind Stone`: level=`focus_card_trace_available`, metrics=`-`, events=`-`, games_with=`-`, trace=`-`, focus_trace=`cost_paid=2, trigger_resolved=1`, focus_fields=`card, effect, phase, player, rule_logical_key, rule_oracle_hash, rule_review_status, trigger, turn`
- `Land Tax`: level=`not_observed`, metrics=`-`, events=`-`, games_with=`-`, trace=`-`, focus_trace=`-`, focus_fields=`-`
- `Lorehold, the Historian`: level=`focus_card_trace_available`, metrics=`cost_paid:Lorehold, the Historian=13`, events=`-`, games_with=`-`, trace=`-`, focus_trace=`cost_paid=22, lorehold_upkeep_rummage=38, replacement_applied=7, trigger_resolved=1`, focus_fields=`card, discard_destination, discarded, drawn, effect, phase, player, reason, replacement_used, rule_logical_key, rule_oracle_hash, rule_review_status, source, target_type, trigger, turn`

## Hypothesis Assessments

### trace_seed7_engine_access_sequence

- Trace status: `trace_partial_missing_payload`
- Source status: `trace_audit_required`
- Target failure: seed 7 missing or low engine access
- Target seeds: `7`
- Focus cards: Urza's Saga, Library of Leng, Sensei's Divining Top, Scroll Rack, Squee, Goblin Nabob
- Limitation: per-game event counts available for seeds: 7
- Limitation: not observed in current artifact: Squee, Goblin Nabob@seed7
- Limitation: missing required payload fields: opening/early-turn hand or battlefield presence; card-specific topdeck activation source per game; Squee hand to graveyard route
- Next action: rerun targeted diagnostic gate with per-turn hand/battlefield/card-source payload

### trace_seed20260625_conversion_window

- Trace status: `trace_partial_missing_payload`
- Source status: `trace_audit_required`
- Target failure: engine appears but fails to convert
- Target seeds: `20260625`
- Focus cards: Library of Leng, Sensei's Divining Top, Scroll Rack, The Mind Stone, Land Tax
- Limitation: per-game event counts available for seeds: 20260625
- Limitation: not observed in current artifact: Land Tax@seed20260625
- Limitation: missing required payload fields: discard-to-top target identity; The Mind Stone blink target identity; Land Tax trigger payload and resulting hand quality
- Next action: rerun targeted diagnostic gate with per-turn hand/battlefield/card-source payload

### audit_urzas_saga_artifact_tutor_scope

- Trace status: `runtime_trace_payload_available_review_model_scope`
- Source status: `runtime_utilization_audit_required`
- Target failure: existing engine may be under-modeled
- Target seeds: `7, 20260625, 42`
- Focus cards: Urza's Saga, Sensei's Divining Top, Library of Leng
- Limitation: per-game event counts available for seeds: 7, 20260625, 42
- Limitation: Saga focus trace includes target_type, candidate_names, legal_target_names, and selected_reason
- Next action: review Saga target scope against trace payload before changing cards

### audit_squee_graveyard_entry_route

- Trace status: `trace_evidence_supports_sequencing_gap`
- Source status: `trace_audit_required`
- Target failure: Squee value exists but not through Lorehold discard
- Target seeds: `7, 20260625, 42`
- Focus cards: Squee, Goblin Nabob, Library of Leng, Lorehold, the Historian
- Limitation: per-game event counts available for seeds: 7, 20260625, 42
- Limitation: not observed in current artifact: Squee, Goblin Nabob@seed7, Squee, Goblin Nabob@seed20260625
- Next action: add sequencing/runtime probe for Squee graveyard entry before testing another card swap

## Guardrails

- Do not count aggregate event presence as proof of the intended card sequence.
- Do not test another blind swap until weak seeds have per-game focus-card payload.
- Treat Urza's Saga target choice and The Mind Stone blink target as runtime trace requirements.
- Keep seed 42 as the regression anchor for miracle/topdeck conversion.
