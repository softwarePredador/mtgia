# Battle latest spell resolution provenance recheck 2026-06-19

Scope: recheck `BV-066` against the current `latest` battle audit artifact,
the active resolution emitter, action critic, static event contract and focused
tests.

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

## Runtime result

`BV-066` is no longer reproduced as a missing-field problem in the latest
runtime artifact.

Observed `spell_resolved` count: `310`.

Missing-field scan:

```json
{
  "total": 310,
  "missing": {
    "phase": 0,
    "priority_window": 0,
    "stack_object": 0,
    "stack_depth": 0,
    "source_zone": 0,
    "from_zone": 0,
    "to_zone": 0,
    "destination": 0,
    "zone_after": 0,
    "resolved_from_stack": 0,
    "result": 0,
    "cast_pipeline": 0,
    "locked_cost": 0
  }
}
```

Resolution mode split:

```text
231 true  stack_resolution          601.2_minimal
 51 true  stack_resolution          miracle_601.2_minimal
 21 false end_step_direct_resolution direct_resolution
  7 false response_direct_resolution direct_resolution
```

Targeted removal resolution also looks corrected for real targeted removal:

```text
remove_creature and remove_permanent spell_resolved rows have target metadata.
redirect_removal rows do not; that is tracked separately as BV-076.
```

## Source evidence

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py:5002-5029`:
  stack resolution attaches stack context before calling
  `apply_effect_immediate(...)`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py:12132-12146`:
  `apply_effect_immediate(...)` emits `spell_resolved` from
  `spell_resolution_context_fields(...)`, declared-target fields and rule
  fields.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py:628-651`:
  the action critic flags `spell_resolved_without_resolution_provenance` when
  required resolution fields are missing.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py:248-296`:
  the focused stack test asserts phase, priority window, stack depth/object,
  source/from/to/destination/zone_after, cast pipeline, resolved_from_stack,
  result and locked cost for one stack-resolved spell.

## Remaining contract gap

The static event contract is still too shallow for `spell_resolved`.

`event_contract_static.json` has:

```json
{
  "event": "spell_resolved",
  "classification": "action_audited",
  "expected_consumer": "battle_action_critic.py",
  "minimum_fields": ["event", "turn"],
  "observed_count": 310,
  "fixture_or_waiver": "observed_in_latest"
}
```

The current data and action critic cover the latest run, but the static
contract by itself would not fail if `spell_resolved` lost `phase`,
`priority_window`, `stack_object`, `stack_depth`, zone fields, `cast_pipeline`,
`locked_cost` or `result`.

The action critic also accepts a positive fixture without `priority_window` and
without `locked_cost`, while the stack test does require them for one
stack-resolution path. This means the runtime currently emits those fields, but
the guardrail is split across different tests and not encoded as a per-event
contract.

## Tests run

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
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py
5 tests passed
```

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
PASS test_spell_resolved_includes_stack_and_zone_provenance
PASS test_casting_context_locks_cost_before_payment
PASS test_casting_context_emits_cost_paid_event
PASS test_casting_context_locks_x_alternative_and_additional_costs
PASS test_casting_context_replay_exposes_modes_targets_and_x_value
PASS test_casting_context_rejects_illegal_timing_without_payment
PASS test_targeted_removal_declares_target_at_cast_time
PASS test_declared_removal_target_is_revalidated_not_reselected
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

## Operational reading

- The old runtime evidence for `BV-066` is stale for latest `20260619_204826`.
- Current `spell_resolved` rows have the provenance fields needed to audit
  phase, stack, source/destination, result, cost context and cast pipeline.
- Keep `BV-066` open only as a narrower contract-depth gap until
  `event_contract_static` or action critic/test coverage requires the same
  resolution field set that the latest artifact currently emits.
- `redirect_removal` missing target mutation is not a generic
  `spell_resolved` provenance problem anymore; it is tracked separately as
  `BV-076`.

Recommended close condition for `BV-066`: `spell_resolved` has a typed/static
event contract or action-critic fixture that requires phase, priority window,
stack object/depth, source/from/to/destination/zone_after, resolved_from_stack,
result, cast pipeline and locked cost where applicable, with explicit waivers
for direct-resolution paths.
