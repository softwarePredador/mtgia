# Global Commander Contextual Stage Cut Evidence Collector

- generated_at: `2026-07-05T21:21:08.046445+00:00`
- status: `contextual_stage_cut_evidence_collected_no_value_safe_reclassification`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- stage_only_plan_status: `stage_only_cut_evidence_plan_ready`
- contextual_row_count: `3`
- reclassification_ready_count: `0`
- missing_usage_or_trace_count: `3`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `collect_usage_or_trace_evidence_for_contextual_stage_cuts`

## Contextual Evidence Rows

| Cut | Roles | Staple Rank | Status | Missing Evidence |
| --- | --- | ---: | --- | --- |
| `Professional Face-Breaker` | `mana_acceleration` | 223 | `contextual_stage_cut_needs_usage_or_trace_evidence` | `usage_or_same_lane_or_replay_proof, format_staple_replacement_risk_review` |
| `Diabolic Intent` | `tutors_access` | 265 | `contextual_stage_cut_needs_usage_or_trace_evidence` | `usage_or_same_lane_or_replay_proof, format_staple_replacement_risk_review` |
| `Ornithopter of Paradise` | `mana_acceleration` | 227 | `contextual_stage_cut_needs_usage_or_trace_evidence` | `usage_or_same_lane_or_replay_proof, format_staple_replacement_risk_review` |

## Blockers

- `contextual_stage_cuts_missing_usage_same_lane_or_replay_proof`

## Current Card Context

- `Professional Face-Breaker`: `Creature — Human Warrior`, cmc `3.0`, oracle `Menace Whenever one or more creatures you control deal combat damage to a player, create a Treasure token. Sacrifice a Treasure: Exile the top card of your library. You may play that card this turn.`
- `Diabolic Intent`: `Sorcery`, cmc `2.0`, oracle `As an additional cost to cast this spell, sacrifice a creature. Search your library for a card, put that card into your hand, then shuffle.`
- `Ornithopter of Paradise`: `Artifact Creature — Thopter`, cmc `2.0`, oracle `Flying {T}: Add one mana of any color.`

## Policy

- collector_boundary: This collector records evidence state; it does not reclassify any cut.
- contextual_staple_boundary: A contextual staple needs usage, same-lane replacement, or replay evidence before value-safe review.
- battle_boundary: Battle remains closed until candidate-copy, strategy-matrix, and replay gates pass.
