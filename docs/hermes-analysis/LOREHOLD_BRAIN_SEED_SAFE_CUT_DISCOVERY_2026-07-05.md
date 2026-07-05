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

## Authorized Continuation Refresh

Generated on 2026-07-05 under prefix
`20260705_goal_continue_brain_seed_mining`.

Additional learning that is now current:

- Brain cut-slot trace miner scanned `1152` gate reports and `229`
  game-result reports. It found floor trace for all `9` current Brain cut
  slots, `1905` same-slot `607` win/candidate-loss traces, and `1504`
  positive target-delta traces. This protects the current slots; it does not
  unlock a cut.
- Brain unlock audit still closed with `safe_cut_count=0`,
  `unlockable_now_count=0`, `candidate_deck_materialization_allowed_now=false`,
  `natural_battle_gate_allowed_now=false`, and `promotion_allowed_now=false`.
- External material scout found `24` external candidates: `10` local Lorehold
  variants not in `607`, `7` rule-known external cards not in the local
  candidate pool, and `7` missing from the local deck pool. Gate-ready count
  remained `0`.
- Scryfall identity resolution found `6/6` missing identities as Commander
  legal and Lorehold color-identity compatible: `Brain in a Jar`,
  `Entreat the Angels`, `Haze of Rage`, `Late to Dinner`,
  `Miraculous Recovery`, and `Strata Scythe`.
- SQLite identity cache package was simulated on a temporary DB, applied to the
  local `knowledge.db`, and postchecked with `resolved_cache_rows=6`. The
  applied source marker is
  `lorehold_external_identity_resolution_queue_20260705_goal_continue_brain_seed_mining`.
  PostgreSQL and `deck_607` were not mutated.
- Post-cache identity preflight now has `oracle_identity_missing_count=0`, but
  still has `runtime_or_manual_review_required_count=4`,
  `shell_contract_required_count=9`, and `gate_ready_now_count=0`.
- Post-identity queue split has `queue_card_count=14`,
  `verified_auto_rule_ready_count=2`, and `battle_ready_now_count=0`.
- Brain/Entreat/Haze runtime contract found XMage classes for all `3` cards.
  Only Brain currently has an active ManaLoom rule. `Entreat the Angels` is the
  best first runtime contract candidate because it directly extends the
  Lorehold miracle/token-pressure thesis.
- Miracle access candidate row queue remains blocked:
  `source_candidate_count=5`, `scoreable_candidate_row_count=0`,
  `named_seed_safe_cut_count=0`, matrix scoring `false`, deck materialization
  `false`, natural battle `false`, and promotion `false`.
- Miracle next route planner still selects `Brain in a Jar` with learning score
  `114`, state `brain_rule_active_no_seed_safe_cut`, and next action
  `mine_named_brain_same_lane_seed_safe_cut_no_deck_action`.

Implementation cleanup from this refresh:

- `lorehold_external_identity_cache_apply_package.py` and
  `lorehold_external_identity_cache_simulation.py` now derive the cache
  `source_marker` from the actual identity-resolution report instead of using
  a hardcoded `20260705_current` marker. This prevents future lineage drift
  when a non-current report prefix is applied.

Validation evidence from this refresh:

- `python3 -m pytest` for all Lorehold/Commander/global Commander tests:
  `821 passed`, `1 skipped`.
- XMage exact-scope/runtime tests: `817 passed`.
- `pg_hermes_sqlite_contract_audit.py` with local server env:
  `51/51 pass`.
- `deckbuilding_contract_surface_audit.py`: `pass`.
- `lorehold_artifact_contract_audit.py`: `pass`.
- `operational_surface_alignment_audit.py`: `pass`.
- `legacy_contamination_audit.py`: `pass`.
- `xmage_strategy_consistency_audit.py`: `26/26 pass`.

Current decision after authorized validation: authorization is broad enough to
apply local cache and run tests, but the evidence still does not justify a deck
mutation. Keep `607` protected. The next real work is runtime implementation
or focused evidence for `Entreat the Angels` and continued named same-lane
safe-cut mining for Brain.

## PG472 Entreat Runtime Apply Refresh

Generated on 2026-07-05 under prefix `20260705_goal_continue_pg472_applied`.

What changed:

- Applied PostgreSQL package
  `docs/hermes-analysis/master_optimizer_reports/pg472_lorehold_entreat_x_token_rule_20260705_current_apply.sql`
  after precheck confirmed `target_card_rows=1`, `existing_rule_rows=0`, and
  `expected_rule_rows_before=0`.
- PostgreSQL postcheck confirmed `package_rule_rows=1`, `auto_rows=1`, and
  `oracle_hash_rows=1` for `Entreat the Angels`.
- Synced `Entreat the Angels` from PostgreSQL to local SQLite
  `knowledge.db`; local `battle_card_rules` now has one
  `verified`/`auto` rule with scope
  `xmage_x_create_creature_tokens_spell_v1` and native miracle cost
  `{X}{W}{W}`.
- Updated the Entreat runtime preflight auditor so it distinguishes:
  runtime primitive ready, active card rule ready, and still-blocked deck
  action. Current status:
  `entreat_x_token_runtime_and_rule_ready_cut_still_blocked_keep_607`.
- Updated the Entreat same-lane cut scout so an active local rule removes the
  stale "apply PG" blocker. Current status:
  `entreat_same_lane_cut_scout_blocked_no_safe_cut_keep_607`.

Current Entreat facts:

- `runtime_primitive_ready=true`.
- `entreat_active_rule_count=1`.
- `entreat_active_rule_ready=true`.
- Post-identity queue has `verified_auto_rule_ready_count=3`.
- Entreat row now has only `named_safe_cut_missing` as its direct route
  blocker.
- Same-lane Entreat scout reviewed `10` miracle/finisher cut candidates.
  `safe_cut_count=0`; all `10` are blocked under the current protected-`607`
  contract.
- Candidate row queue still has `scoreable_candidate_row_count=0` and
  `named_seed_safe_cut_count=0`.
- Miracle next route planner still selects `Brain in a Jar`, with state
  `brain_rule_active_no_seed_safe_cut`, learning score `114`, and next action
  `mine_named_brain_same_lane_seed_safe_cut_no_deck_action`.

Validation evidence from this refresh:

- Lorehold/Commander/global Commander tests: `823 passed`, `1 skipped`.
- XMage exact-scope/runtime tests: `819 passed`.
- `pg_hermes_sqlite_contract_audit.py` with local server env:
  `51/51 pass`.
- `deckbuilding_contract_surface_audit.py`: `pass`.
- `lorehold_artifact_contract_audit.py`: `pass`.
- `operational_surface_alignment_audit.py`: `pass`.
- `legacy_contamination_audit.py`: `pass`.
- `xmage_strategy_consistency_audit.py`: `26/26 pass`.

Decision after PG472: Entreat is now executable enough for focused ManaLoom
runtime evidence, but it is not a deck edit. Do not materialize or battle an
Entreat candidate until a named same-lane safe cut exists and the matrix clears.
The practical next work remains safe-cut mining: Brain first per planner, with
Entreat cut mining available as a parallel miracle-finisher lane.

## Total Authorization Revalidation Refresh

Generated on 2026-07-05 under prefix `20260705_total_authorization_*`.

Current runtime/card-rule state:

- `Brain in a Jar` is confirmed active in PostgreSQL and SQLite as
  `verified`/`auto`, scope
  `xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1`, oracle hash
  `41468898bf6400763de517269fdeb456`.
- PostgreSQL postcheck for the Brain package confirmed
  `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`,
  `promoted_oracle_hash_rows=1`, and `promoted_scope_rows=1`.
- `Entreat the Angels` remains confirmed active in SQLite as
  `verified`/`auto`, scope `xmage_x_create_creature_tokens_spell_v1`, oracle
  hash `30f38db3fe030a6002c9a8120d216ec8`.
- The fresh miracle next route planner sees both active rules:
  `brain_active_rule_count=1`, `entreat_active_rule_count=1`. It still selects
  `Brain in a Jar` because `brain_safe_cut_count=0`,
  `entreat_safe_cut_count=0`, `named_seed_safe_cut_count=0`, and
  `candidate_queue_scoreable_row_count=0`.

Fresh cut evidence:

- Seed-safe cut hypothesis:
  `seed_safe_cut_ready_count=0`, `same_lane_only_count=2`, and blocked slots
  `94/94`.
- Brain cut-slot trace miner scanned `1179` gate reports and `229` game-result
  reports. It found `1905` same-slot traces and `1504` positive target-delta
  traces across all `9` Brain cut-slot candidates, so those slots are floor
  evidence, not free cuts.
- Brain unlock audit closed with `unlockable_now_count=0`,
  `targeted_floor_trace_missing_slot_count=0`, and
  `matrix_scoring_allowed_now=false`.
- Entreat same-lane cut scout reviewed `10` miracle/finisher candidates;
  all `10` are blocked as current-`607` hard stops.
- Trace cut evidence expander found `seed_safe_ready_count=0`,
  `reviewable_evidence_gap_count=0`, `same_lane_hard_blocked_count=2`, and
  `hard_blocked_count=92`.
- Topdeck safe-cut miner and topdeck new-cut scout both kept `607` closed:
  `seed_safe_cut_candidate_count=0`, `internal_candidate_count=0`.
- Engine-preserving Guttersnipe + Storm-Kiln cut miner reviewed all `94` slots
  and classified all as `closed_hard_stop_current_607`.

Fresh battle and simulator evidence:

- Structural matrix still ranks `deck_607` first:
  `ranked_deck_keys[0]=deck_607`, with `deck_615` second and `deck_614` third.
- Full registered Lorehold battle window:
  `lorehold_variant_battle_gate_20260705_total_authorization_revalidate`.
  It ran `12` Lorehold decks, `2` games per opponent, `4` real opponents,
  isolated deck processes, no candidate materialization, and no DB mutation.
  In this short window, `deck_609` and `deck_613` each went `4W/4L`; `deck_607`
  went `2W/6L`.
- Focused confirmation:
  `lorehold_variant_battle_gate_20260705_total_authorization_focused_607_609_613_615`.
  It ran `deck_607`, `deck_609`, `deck_613`, and `deck_615`, `4` games per
  opponent, same `4` real opponents, isolated deck processes, no candidate
  materialization, and no DB mutation.
- Focused result: `deck_615` went `10W/6L` (`62.50%`), `deck_613` went
  `7W/9L` (`43.75%`), `deck_607` went `6W/10L` (`37.50%`), and `deck_609`
  went `3W/13L` (`18.75%`).
- Larger 607-vs-615 confirmation:
  `lorehold_variant_battle_gate_20260705_total_authorization_focused_607_vs_615_g8`.
  It ran `8` games per opponent, the same `4` real opponents, isolated deck
  processes, no forced access, no candidate materialization, and no DB
  mutation. `deck_615` went `14W/18L` (`43.75%`, avg win turn `15.29`);
  `deck_607` went `11W/21L` (`34.38%`, avg win turn `18.73`).
- In the larger window, `615` produced more miracle casts (`86` vs `62`) and
  more discard-to-top replacements (`39` vs `17`), while `607` produced more
  static cost-reduction volume (`99` vs `1`) and more Lorehold spell casts
  (`324` vs `292`). This points to a shell-level question, not a one-card
  Brain/Entreat cut question.
- `deck_615` and `deck_607` are both valid Commander lists with `100` total
  cards and `1` commander. `deck_615` differs from `607` by `47` added cards
  and `57` removed singleton rows, so this is a shell-vs-shell challenger, not
  a safe one-card swap.
- Notable `615` additions over `607` include `Mana Vault`, `The One Ring`,
  `Birgi, God of Storytelling // Harnfel, Horn of Bounty`, `Guttersnipe`,
  `Underworld Breach`, `Reiterate`, `Galvanoth`, `Enlightened Tutor`,
  `Boros Charm`, `Brass's Bounty`, `Apex of Power`, and `Twinflame Tyrant`.
- Notable `607` cards absent from `615` include `Scroll Rack`,
  `The Mind Stone`, `Creative Technique`, `Bender's Waterskin`,
  `Molecule Man`, `Ruby Medallion`, `Pearl Medallion`, `Flawless Maneuver`,
  `Dawn's Truce`, `Stroke of Midnight`, `Winds of Abandon`, and several fetch
  or fixing lands.

Decision after total authorization refresh:

- Authorization is broad enough for runtime validation, PostgreSQL checks,
  simulator windows, and future deck action when the evidence gate clears.
- The current one-card Brain/Entreat path still cannot mutate `607`: no named
  same-lane seed-safe cut exists, no matrix row is scoreable, and no candidate
  deck is materializable from those card hypotheses.
- The statement "607 is unquestionably best" is no longer supported by fresh
  simulator evidence. `607` remains the protected structural baseline, but
  `615` is now the strongest live battle challenger and has survived one
  larger confirmation window.
- Next practical work: inspect `615`'s high-impact additions as package groups,
  run a wider/opponent-rotated 607-vs-615 shell gate, and only then decide
  whether to promote a full-shell replacement, create a 615-derived learned
  candidate, or preserve 607 while continuing safe-cut mining.
