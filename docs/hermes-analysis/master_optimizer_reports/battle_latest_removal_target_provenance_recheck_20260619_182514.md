# Battle latest removal target provenance recheck 2026-06-19

Scope: recheck `BV-065` against the current `latest` battle audit artifact and
separate targeted removal from the `redirect_removal` approximation found during
the same audit pass.

Guardrails:

- PostgreSQL was not modified.
- No swaps were applied.
- No code was changed.
- No commit was created.
- Only artifacts, logs and documentation were inspected or written.

## Latest artifact

- Latest path:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826`
- Primary summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `timestamp_utc=2026-06-19T20:48:26Z`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `seeds_requested=16`
- `seeds_completed=16`
- `mandatory_gate_divergences=[]`
- `action_findings=0`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`
- `seeds_with_high_or_critical_forensic_findings=[]`

No high/critical action finding or strategy blocker was present in the latest
summary.

## BV-065 result

`BV-065` is no longer reproduced by the current latest artifact.

For targeted removal effects `remove_creature` and `remove_permanent`:

- `37/37` cast-like events have declared target metadata.
- All `37/37` have `targeting_pipeline=targeting_formal_minimal`.
- `21/21` matching `spell_resolved` targeted removal events preserve the target
  observed on the matching cast-like event.
- `22/22` `removal_resolved` events have `target`, `target_legal=true` and
  `targeting_pipeline=targeting_formal_minimal`.
- The 16 per-seed `action_critic.json` files have `total_findings=0`.

The old `P1` action-critic blocker for
`targeted_removal_without_declared_target` should be treated as closed by
current evidence.

## Targeted removal counts

Cast-like targeted removals:

```text
9 cast_announced remove_creature true targeting_formal_minimal
6 cast_announced remove_permanent true targeting_formal_minimal
3 end_step_instant remove_creature true targeting_formal_minimal
2 miracle_cast remove_creature true targeting_formal_minimal
2 miracle_cast remove_permanent true targeting_formal_minimal
9 spell_cast remove_creature true targeting_formal_minimal
6 spell_cast remove_permanent true targeting_formal_minimal
```

Resolution target preservation:

```text
21 spell_resolved targeted removal events matched a cast-like event.
21/21 preserved the same target.
```

Resolution metadata:

```text
22 removal_resolved true true targeting_formal_minimal
```

Action critic:

```json
{
  "files": 16,
  "total_findings": 0,
  "codes": {}
}
```

## Source and test evidence

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py:4366-4403`:
  `prepare_declared_removal_targets(...)` declares targeted removal targets
  before cast metadata is emitted.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py:4470-4573`:
  `resolve_declared_single_removal(...)` revalidates the declared target and
  emits `removal_resolved`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py:8816-8841`:
  miracle casts call `prepare_declared_removal_targets(...)` and propagate
  target fields into the miracle cast context.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py:614-625`:
  the critic raises `targeted_removal_without_declared_target` for targeted
  removals missing target metadata.
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py:147-190`:
  the critic has fixtures for missing and accepted targeted-removal targets.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_targeting_tests.py:170-264`:
  tests cover target declaration at cast time and revalidation without
  reselection.

Tests run:

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py
PASS test_critic_flags_action_level_findings
PASS test_critic_renders_markdown_ledger
PASS test_critic_flags_counter_spell_without_stack_target
PASS test_critic_accepts_counter_with_target_stack_object_and_result
PASS test_critic_flags_trigger_without_auditable_stack_metadata
PASS test_critic_accepts_trigger_with_source_trigger_and_stack_order
PASS test_critic_flags_replacement_without_causal_metadata
PASS test_critic_accepts_replacement_with_causal_metadata
PASS test_critic_accepts_life_replacement_with_affected_player_metadata
PASS test_critic_flags_life_replacement_without_original_final_metadata
PASS test_critic_reports_event_contract_denominators
```

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
PASS test_removal_replay_includes_formal_targeting_metadata
PASS test_multi_target_removal_partially_resolves_legal_targets
PASS test_targeted_removal_declares_target_at_cast_time
PASS test_declared_removal_target_is_revalidated_not_reselected
PASS test_ward_counters_targeted_removal_when_unpaid
PASS test_ward_paid_allows_targeted_removal_to_resolve
```

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py
PASS test_renderer_writes_land_cost_cast_illegal_and_board_details
PASS test_renderer_differentiates_spell_ability_trigger_and_counter
PASS test_renderer_uses_real_trigger_put_on_stack_fields
PASS test_renderer_explains_noncombat_damage_life_change
PASS test_deck_metrics_are_derived_from_resolved_cards
PASS test_provenance_line_names_source_metrics_and_blocker_domain
```

## New finding: redirect removal

The same latest artifact still exposes a separate `redirect_removal` gap.

`Deflecting Swat` appears in `12` related events across `5` seeds:

- cast-like events: `5`
- `spell_resolved` events: `5`
- cost event: `1`
- all cast/resolution rows have no `target`, no spell/ability target, no
  `old_target`, and no `new_target`.

Event evidence:

```text
seed 63202024 turn 9 miracle_cast Deflecting Swat target=null old_target=null new_target=null
seed 63202024 turn 9 spell_resolved Deflecting Swat target=null old_target=null new_target=null
seed 63202026 turn 7 end_step_instant Deflecting Swat target=null old_target=null new_target=null
seed 63202026 turn 7 spell_resolved Deflecting Swat target=null old_target=null new_target=null
seed 63202027 turn 6 end_step_instant Deflecting Swat target=null old_target=null new_target=null
seed 63202027 turn 6 spell_resolved Deflecting Swat target=null old_target=null new_target=null
seed 63202032 turn 6 cast_announced Deflecting Swat targets=[] old_target=null new_target=null
seed 63202032 turn 6 spell_cast Deflecting Swat targets=[] old_target=null new_target=null
seed 63202032 turn 6 spell_resolved Deflecting Swat target=null old_target=null new_target=null
seed 63202037 turn 9 miracle_cast Deflecting Swat target=null old_target=null new_target=null
seed 63202037 turn 9 spell_resolved Deflecting Swat target=null old_target=null new_target=null
```

Source evidence:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py:13113-13116`:
  `redirect_removal` grants creatures indestructible and sets
  `player.indestructible=True`, then finishes the spell. It does not model a
  redirection target, a spell/ability object, old target, new target, or whether
  a legal redirect opportunity exists.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py:614-625`:
  the targeted-removal critic does not cover `redirect_removal`, so this gap
  passes action critic with zero findings.

Operational reading:

- `BV-065` should be closed for `remove_creature`/`remove_permanent`.
- A new issue should remain open for `redirect_removal`: the current behavior is
  closer to a protection/indestructible approximation than actual Deflecting
  Swat-style target redirection.
- The human replay also shows only `CAST/RESOLVE SPELL Deflecting Swat
  [redirect_removal]`, without the spell/ability being redirected or the target
  mutation.

Recommended new register item:

- `BV-076`: `redirect_removal` target/change provenance and behavior.
