# Global Commander External Exact Artifact Oracle Backfill

- generated_at: `2026-07-06T04:53:55.657850+00:00`
- status: `external_exact_artifact_oracle_backfill_applied_review_rerun_required`
- candidate_backfill_count: `5`
- backfill_ready_count: `0`
- backfill_applied_count: `5`
- source_db_mutated: `true`
- deck_rows_mutated: `false`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `rerun_external_exact_artifact_engine_candidate_reviewer_after_backfill`

## Backfill Rows

| Card | Status | Exact Status | Signals | Color | Applied | Blockers |
| --- | --- | --- | --- | --- | --- | --- |
| `Digsite Engineer` | `backfill_applied` | `exact_artifact_spell_payoff_candidate` | `artifact_spell_token_payoff` | `W` | `true` | - |
| `Golem Foundry` | `backfill_applied` | `exact_artifact_spell_payoff_candidate` | `artifact_spell_token_payoff` | `` | `true` | - |
| `Myrsmith` | `backfill_applied` | `exact_artifact_spell_payoff_candidate` | `artifact_spell_token_payoff` | `W` | `true` | - |
| `Poetic Ingenuity` | `backfill_applied` | `exact_artifact_spell_payoff_candidate` | `artifact_spell_token_payoff` | `R` | `true` | - |
| `Ravenous Robots` | `backfill_applied` | `exact_artifact_spell_payoff_candidate` | `artifact_spell_token_payoff` | `R` | `true` | - |

## Policy

- scope: Only missing local Oracle rows for reviewed external exact engine seeds are eligible.
- deck_boundary: No deck_cards rows are inserted, updated, or deleted.
- product_boundary: This is a Hermes SQLite cache backfill, not PostgreSQL product truth.
