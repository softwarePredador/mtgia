# Lorehold Runtime Candidate Readiness - 2026-06-30

- Generated at: `2026-06-30T18:26:20Z`
- Runtime queue: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg282_final_eight.json`
- Access model: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_access_cut_model_20260630_post_pg276_lane_core_blocked.json`
- Hypothesis queue: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_next_hypothesis_queue_20260628_v10_runtime_pg245.json`
- Active rule source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Cards reviewed: `5`
- Status counts: `{"pg_package_applied_synced": 2, "review_required": 3}`
- Promotion lanes: `{"access_density_candidate": 5}`
- Cut-specific negatives: `0`
- Recommended next action: `split_scope_runtime_families_or_continue_cut_modeling`

## Priority Cards

| Rank | Card | Status | Family | Lane | Effect | Cut-specific negatives | Next action |
| ---: | --- | --- | --- | --- | --- | ---: | --- |
| 1 | `Brainstone` | `pg_package_applied_synced` | `access_density` | `access_density_candidate` | `` | 0 | Use the synced verified rule and rebuild the queue before any deck gate; do not rerun this package. |
| 2 | `Hidden Retreat` | `pg_package_applied_synced` | `access_density` | `access_density_candidate` | `` | 0 | Use the synced verified rule and rebuild the queue before any deck gate; do not rerun this package. |
| 3 | `Enlightened Tutor` | `review_required` | `access_density` | `access_density_candidate` | `` | 0 | Review current evidence before gate. |
| 4 | `Gamble` | `review_required` | `access_density` | `access_density_candidate` | `` | 0 | Review current evidence before gate. |
| 5 | `Penance` | `review_required` | `access_density` | `access_density_candidate` | `` | 0 | Review current evidence before gate. |

## Package Evidence And Blockers

### Brainstone
- Applied/synced package `pg272_brainstone_executable_topdeck_20260630` status `applied_synced`; apply `docs/hermes-analysis/master_optimizer_reports/pg272_brainstone_executable_topdeck_20260630_apply.sql`

### Hidden Retreat
- Applied/synced package `pg271` status `applied_synced`; apply `docs/hermes-analysis/master_optimizer_reports/pg271_hidden_retreat_damage_prevention_20260630_apply.sql`
