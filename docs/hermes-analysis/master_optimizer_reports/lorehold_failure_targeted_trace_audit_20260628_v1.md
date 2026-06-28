# Lorehold Failure-Targeted Trace Audit - 2026-06-28

- Generated at: `2026-06-28T02:44:27Z`
- Candidate key: `candidate_607_squee_hashseed0_isolated_cached_timeout_v3`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Recommended next action: `extend_focus_card_trace_payload_then_rerun_seed_diagnostics`
- Focus cards: `8`
- Primary seed records: `3`
- Seed source reports: `6`
- Hypotheses: `4`
- Trace statuses: `{"runtime_trace_partial_missing_tutor_payload": 1, "trace_evidence_supports_sequencing_gap": 1, "trace_partial_missing_payload": 2}`
- Primary trace levels: `{"per_game_event_counts": 3}`

## Seed Records

| Seed | Trace Level | W | L | S | WR | Miracle | Topdeck | Lorehold Rummage | Squee GY | Squee Return | Squee Trace Games | Source |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 7 | `per_game_event_counts` | 0 | 9 | 0 | 0.00% | 4 | 2 | 27 | 0 | 0 | 0 | `docs/hermes-analysis/master_optimizer_reports/lorehold_squee_hashseed0_isolated_cached_timeout_diag_seed7_20260627_v1.json` |
| 42 | `per_game_event_counts` | 8 | 1 | 0 | 88.89% | 33 | 30 | 41 | 7 | 5 | 5 | `docs/hermes-analysis/master_optimizer_reports/lorehold_squee_hashseed0_isolated_cached_timeout_diag_seed42_20260627_v1.json` |
| 20260625 | `per_game_event_counts` | 0 | 9 | 0 | 0.00% | 4 | 3 | 38 | 0 | 0 | 0 | `docs/hermes-analysis/master_optimizer_reports/lorehold_squee_hashseed0_isolated_cached_timeout_diag_seed20260625_20260627_v1.json` |

## Focus Card Evidence

### Seed 7

- `Urza's Saga`: level=`per_game_event_counts_indirect`, metrics=`-`, events=`saga_chapter_progressed=4, saga_chapter_resolved=2, saga_sacrificed_by_sba=2, tutor_resolved=7`, games_with=`saga_chapter_progressed=2, saga_chapter_resolved=2, saga_sacrificed_by_sba=2, tutor_resolved=6`, trace=`-`
- `Library of Leng`: level=`per_game_event_counts_indirect`, metrics=`-`, events=`replacement_applied=9`, games_with=`replacement_applied=4`, trace=`-`
- `Sensei's Divining Top`: level=`per_game_event_counts_indirect`, metrics=`-`, events=`topdeck_manipulation_activated=2`, games_with=`topdeck_manipulation_activated=1`, trace=`-`
- `Scroll Rack`: level=`per_game_event_counts_indirect`, metrics=`topdeck:Scroll Rack=2`, events=`topdeck_manipulation_activated=2`, games_with=`topdeck_manipulation_activated=1`, trace=`-`
- `Squee, Goblin Nabob`: level=`not_observed`, metrics=`-`, events=`-`, games_with=`-`, trace=`-`
- `The Mind Stone`: level=`not_observed`, metrics=`-`, events=`-`, games_with=`-`, trace=`-`
- `Land Tax`: level=`per_game_event_counts_indirect`, metrics=`-`, events=`land_tax_trigger_resolved=1, land_tax_trigger_skipped=3`, games_with=`land_tax_trigger_resolved=1, land_tax_trigger_skipped=1`, trace=`-`
- `Lorehold, the Historian`: level=`aggregate_card_metric_plus_per_game_family_counts`, metrics=`cost_paid:Lorehold, the Historian=10`, events=`-`, games_with=`-`, trace=`-`

### Seed 42

- `Urza's Saga`: level=`per_game_event_counts_indirect`, metrics=`-`, events=`saga_chapter_progressed=7, saga_chapter_resolved=3, saga_sacrificed_by_sba=3, tutor_resolved=10`, games_with=`saga_chapter_progressed=4, saga_chapter_resolved=3, saga_sacrificed_by_sba=3, tutor_resolved=7`, trace=`-`
- `Library of Leng`: level=`per_game_event_counts_indirect`, metrics=`-`, events=`replacement_applied=50`, games_with=`replacement_applied=7`, trace=`-`
- `Sensei's Divining Top`: level=`per_game_event_counts_indirect`, metrics=`topdeck:Sensei's Divining Top=17, cost_paid:Sensei's Divining Top=5`, events=`topdeck_manipulation_activated=30`, games_with=`topdeck_manipulation_activated=5`, trace=`-`
- `Scroll Rack`: level=`partial_game_trace_available`, metrics=`topdeck:Scroll Rack=13`, events=`topdeck_manipulation_activated=30`, games_with=`topdeck_manipulation_activated=5`, trace=`topdeck_manipulation_activated=2`
- `Squee, Goblin Nabob`: level=`partial_game_trace_available`, metrics=`cost_paid:Squee, Goblin Nabob=10, graveyard_return:Squee, Goblin Nabob=5`, events=`graveyard_upkeep_return_self_to_hand=5, squee_return_after_known_graveyard_entry=5, squee_to_graveyard=7, squee_upkeep_return=5`, games_with=`graveyard_upkeep_return_self_to_hand=2, squee_return_after_known_graveyard_entry=2, squee_to_graveyard=4, squee_upkeep_return=2`, trace=`airbend_creature_cast_from_exile=1, cast_announced=10, cost_paid=10, creature_cast=9, permanent_moved_from_battlefield=6, trigger_resolved=5`
- `The Mind Stone`: level=`per_game_event_counts_indirect`, metrics=`-`, events=`utility_artifact_activated=4`, games_with=`utility_artifact_activated=3`, trace=`-`
- `Land Tax`: level=`per_game_event_counts_indirect`, metrics=`-`, events=`land_tax_trigger_resolved=2, land_tax_trigger_skipped=47`, games_with=`land_tax_trigger_resolved=1, land_tax_trigger_skipped=4`, trace=`-`
- `Lorehold, the Historian`: level=`aggregate_card_metric_plus_per_game_family_counts`, metrics=`cost_paid:Lorehold, the Historian=15`, events=`-`, games_with=`-`, trace=`-`

### Seed 20260625

- `Urza's Saga`: level=`per_game_event_counts_indirect`, metrics=`-`, events=`saga_chapter_progressed=4, saga_chapter_resolved=2, saga_sacrificed_by_sba=2, tutor_resolved=9`, games_with=`saga_chapter_progressed=2, saga_chapter_resolved=2, saga_sacrificed_by_sba=2, tutor_resolved=6`, trace=`-`
- `Library of Leng`: level=`per_game_event_counts_indirect`, metrics=`cost_paid:Library of Leng=4`, events=`replacement_applied=19`, games_with=`replacement_applied=7`, trace=`-`
- `Sensei's Divining Top`: level=`per_game_event_counts_indirect`, metrics=`cost_paid:Sensei's Divining Top=2`, events=`topdeck_manipulation_activated=3`, games_with=`topdeck_manipulation_activated=1`, trace=`-`
- `Scroll Rack`: level=`per_game_event_counts_indirect`, metrics=`topdeck:Scroll Rack=3`, events=`topdeck_manipulation_activated=3`, games_with=`topdeck_manipulation_activated=1`, trace=`-`
- `Squee, Goblin Nabob`: level=`not_observed`, metrics=`-`, events=`-`, games_with=`-`, trace=`-`
- `The Mind Stone`: level=`aggregate_card_metric_plus_per_game_family_counts`, metrics=`cost_paid:The Mind Stone=2`, events=`-`, games_with=`-`, trace=`-`
- `Land Tax`: level=`not_observed`, metrics=`-`, events=`-`, games_with=`-`, trace=`-`
- `Lorehold, the Historian`: level=`aggregate_card_metric_plus_per_game_family_counts`, metrics=`cost_paid:Lorehold, the Historian=13`, events=`-`, games_with=`-`, trace=`-`

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

- Trace status: `runtime_trace_partial_missing_tutor_payload`
- Source status: `runtime_utilization_audit_required`
- Target failure: existing engine may be under-modeled
- Target seeds: `7, 20260625, 42`
- Focus cards: Urza's Saga, Sensei's Divining Top, Library of Leng
- Limitation: per-game event counts available for seeds: 7, 20260625, 42
- Limitation: missing required payload fields: Saga chapter payload; artifact tutor target identity; whether Top or Library are legal/reachable Saga targets
- Next action: extend Urza's Saga trace payload with chapter, tutor target, and legal target set

### audit_squee_graveyard_entry_route

- Trace status: `trace_evidence_supports_sequencing_gap`
- Source status: `trace_audit_required`
- Target failure: Squee value exists but not through Lorehold discard
- Target seeds: `7, 20260625, 42`
- Focus cards: Squee, Goblin Nabob, Library of Leng, Lorehold, the Historian
- Limitation: per-game event counts available for seeds: 7, 20260625, 42
- Limitation: not observed in current artifact: Squee, Goblin Nabob@seed7, Squee, Goblin Nabob@seed20260625
- Limitation: missing required payload fields: Squee zone move reason; whether Lorehold rummage discards Squee; whether Library replacement conflicts with graveyard entry
- Next action: add sequencing/runtime probe for Squee graveyard entry before testing another card swap

## Guardrails

- Do not count aggregate event presence as proof of the intended card sequence.
- Do not test another blind swap until weak seeds have per-game focus-card payload.
- Treat Urza's Saga target choice and The Mind Stone blink target as runtime trace requirements.
- Keep seed 42 as the regression anchor for miracle/topdeck conversion.
