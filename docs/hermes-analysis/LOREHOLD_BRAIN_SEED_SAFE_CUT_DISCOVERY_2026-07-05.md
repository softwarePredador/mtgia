# Lorehold Brain Seed-Safe Cut Discovery - 2026-07-05

Status: `learning_only_keep_607`.

This handoff records the current Brain in a Jar deckbuilding route after the
PG509 cleanup and artifact-pruning commits. It intentionally lives outside
`master_optimizer_reports` because that directory is now treated as mostly
ignored/generated evidence.

## Current Decision

- Protected baseline: `deck_607`.
- Selected learning card: `Brain in a Jar`.
- Selected lane: `topdeck_miracle_access`.
- Brain active rule count: `1`.
- Brain PostgreSQL rule active confirmed now: `true`.
- Named seed-safe cut count: `0`.
- Brain unlockable cut count: `0`.
- Candidate row scoreable count: `0`.
- Matrix scoring allowed now: `false`.
- Candidate deck materialization allowed now: `false`.
- Natural battle gate allowed now: `false`.
- Promotion allowed now: `false`.

Conclusion: Brain in a Jar is now a valid runtime/deckbuilding learning target,
but it is not a deck change. Deck `607` remains the current Lorehold champion
until a named same-lane seed-safe cut exists, the candidate row can be scored,
and a later equal battle gate ties or beats `607`.

## Authoritative Current Inputs

- `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_next_route_planner_20260705_post_authorized_full_validation.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_safe_cut_gap_audit_20260705_post_authorized_full_validation.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_seed_safe_cut_unlock_audit_20260705_post_authorized_full_validation.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_cut_slot_trace_miner_20260705_current_summary.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_current_best_baseline_synthesis_20260705_current.json`

Use the `post_authorized_full_validation` Brain artifacts over the stale
`current` Brain artifacts when the question is whether Brain's rule is active.
The stale `current` runtime path still shows `brain_active_rule_count=0`; the
post-authorized path confirms `brain_active_rule_count=1`.

## Slot Queue

| Current 607 slot | Class | Exposure | Floor traces | Positive deltas | Current action |
| --- | --- | ---: | ---: | ---: | --- |
| `Molecule Man` | `diagnostic_only_prior_reject_requires_new_trace` | 102 | 31 | 30 | Mine new trace evidence before reopening this prior-rejected cut. |
| `Land Tax` | `diagnostic_only_prior_reject_requires_new_trace` | 3449 | 146 | 120 | Mine new trace evidence before reopening this prior-rejected cut. |
| `Library of Leng` | `protected_topdeck_anchor_requires_role_preservation` | 855 | 118 | 86 | Prove replacement preserves topdeck/miracle anchor role before matrix. |
| `Scroll Rack` | `protected_topdeck_anchor_requires_role_preservation` | 2957 | 188 | 177 | Prove replacement preserves topdeck/miracle anchor role before matrix. |
| `Sensei's Divining Top` | `protected_topdeck_anchor_requires_role_preservation` | 3816 | 145 | 133 | Prove replacement preserves topdeck/miracle anchor role before matrix. |
| `The Scarlet Witch` | `protected_floor_requires_floor_replacement_trace` | 362 | 165 | 146 | Collect floor-replacement trace before matrix. |
| `The Mind Stone` | `protected_floor_requires_floor_replacement_trace` | 2312 | 181 | 155 | Collect floor-replacement trace before matrix. |
| `Urza's Saga` | `locked_no_unlock_current_607_contract` | 2656 | 71 | 59 | Do not use as Brain cut under current 607 contract. |
| `Lorehold, the Historian` | `locked_no_unlock_current_607_contract` | 5768 | 390 | 222 | Do not use as Brain cut under current 607 contract. |

## Learning Implication

The next useful work is not another battle and not a deck mutation. It is a
seed-safe cut discovery pass:

1. Keep Brain in a Jar as the current topdeck/miracle access learning card.
2. Keep `deck_607` unchanged.
3. Do not reopen `Molecule Man` or `Land Tax` from low exposure alone; both need
   new same-lane trace evidence reversing prior rejection.
4. Do not cut the topdeck anchors unless a replacement preserves the observed
   topdeck/miracle role.
5. Do not cut structural floor cards unless the replacement preserves mana/curve
   floor evidence.
6. Only after a named seed-safe cut exists, rerun the candidate row queue and
   miracle-access structure matrix. Battle comes after matrix, not before it.

## Explicit Non-Actions

- Do not mutate PostgreSQL from this handoff.
- Do not mutate `deck_607`.
- Do not materialize a Brain candidate deck.
- Do not run forced access.
- Do not run a natural battle gate.
- Do not promote Brain in a Jar, Mana Vault, The One Ring, or any other staple
  into `deck_607` from popularity or runtime readiness alone.
