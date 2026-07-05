# Global Commander Contextual Usage Trace Generator

- generated_at: `2026-07-05T21:35:08.557208+00:00`
- status: `contextual_usage_trace_generated_all_current_usage_review_required`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- seed_start: `42`
- seed_count: `8`
- generated_replay_count: `8`
- usage_event_card_count: `3`
- exposure_event_card_count: `2`
- decision_trace_card_count: `3`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_replay_performed: `true`
- battle_gate_performed: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `review_generated_usage_trace_before_value_safe_reclassification`

## Aggregate Card Trace

| Card | Usage Events | Exposure Events | Decision Traces | Event Types |
| --- | ---: | ---: | ---: | --- |
| `Professional Face-Breaker` | 6 | 12 | 14 | `{"additional_cost_paid": 1, "cast_announced": 2, "combat": 3, "combat_step": 3, "cost_paid": 2, "creature_cast": 2, "multi_defender_attack": 3, "permanent_moved_from_battlefield": 2, "turn_end": 8, "turn_start": 4}` |
| `Diabolic Intent` | 5 | 0 | 1 | `{"additional_cost_paid": 1, "cast_announced": 1, "cost_paid": 1, "permanent_moved_from_battlefield": 1, "priority_pass": 6, "spell_cast": 1, "spell_resolved": 1, "tutor_resolved": 1}` |
| `Ornithopter of Paradise` | 12 | 26 | 15 | `{"additional_cost_paid": 1, "cast_announced": 4, "cost_paid": 4, "creature_cast": 4, "land_played": 5, "mana_refreshed": 17, "permanent_moved_from_battlefield": 3, "turn_end": 21, "turn_start": 5, "utility_land_activated": 1}` |

## Seed Reports

- seed `42`: `replay_generated`, events `818`, decisions `121`, provenance `deck_id:619`.
- seed `43`: `replay_generated`, events `832`, decisions `138`, provenance `deck_id:619`.
- seed `44`: `replay_generated`, events `1003`, decisions `139`, provenance `deck_id:619`.
- seed `45`: `replay_generated`, events `727`, decisions `114`, provenance `deck_id:619`.
- seed `46`: `replay_generated`, events `1074`, decisions `136`, provenance `deck_id:619`.
- seed `47`: `replay_generated`, events `795`, decisions `134`, provenance `deck_id:619`.
- seed `48`: `replay_generated`, events `661`, decisions `99`, provenance `deck_id:619`.
- seed `49`: `replay_generated`, events `1061`, decisions `147`, provenance `deck_id:619`.

## Blockers

- none

## Policy

- trace_generation_boundary: Structured replay generation is evidence collection only, not a promotion battle gate.
- usage_boundary: A card needs current-scope usage events or stronger focused trace before value-safe reclassification.
- mutation_boundary: The selected SQLite DB is read as source; this script must not mutate deck_cards or PostgreSQL.
