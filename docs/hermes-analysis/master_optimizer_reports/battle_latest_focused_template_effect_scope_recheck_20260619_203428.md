# Battle Latest Focused Template Effect Scope Recheck - 2026-06-19 20:34Z

## Scope

Recheck the current `latest` trusted battle-strategy audit for the focused
template/action-template question:

- Whether the focused template dispatch gate is now ready.
- Whether that readiness is equivalent to "all battle action effects have
  stable effect labels".
- Whether the primary summary still needs a visible denominator for
  `effect=unknown`.

This is a read-only documentation audit. No PostgreSQL, swaps, code edits, or
commits were performed.

## Sources

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage_residual.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/unknown_template_backlog.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/focused_template_dispatch_artifacts/*/focused_artifacts/focused_template_dispatch_audit/replay_events.jsonl`
- `server/bin/manaloom_battle_rule_focused_evidence.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py`

## Current Latest

- Latest realpath:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855`
- `timestamp_utc=2026-06-19T20:38:55Z`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `action_findings=0`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`

## Focused Template Gate

The focused dispatch gate is ready for the current focused backlog:

- `focused_template_dispatch_status=focused_template_dispatch_ready`
- `focused_template_cards=29`
- `focused_template_predicate_match=29`
- `focused_template_without_predicate_match=0`
- `focused_template_supports_template_count=47`
- `focused_template_evaluate_dispatch_template_count=47`
- `focused_template_build_evidence_function_count=47`
- `focused_template_evidence_ready=29`
- `focused_template_evidence_not_ready_unwaived=0`
- `focused_template_evidence_runner_status_counts={"evidence_ready":29}`
- `focused_template_dispatch.summary.supports_not_dispatched=[]`
- `focused_template_dispatch.summary.focused_template_cards_without_dispatch=[]`
- `focused_template_dispatch.summary.focused_template_cards_not_ready_unwaived=[]`
- `focused_template_dispatch.summary.accepted_waivers=0`

Operational reading: the current focused backlog has predicate, dispatch,
builder, and focused evidence artifacts for all `29` cards.

## Effect Label Denominator

The focused gate does not mean every focused card has a stable non-unknown
effect label in `effect_coverage.json`.

Current `effect_coverage.json` still reports:

- `effect_coverage_unknowns=0` in the top-level summary.
- `unknown_template_backlog_cards=0` in the top-level summary.
- `effect_coverage.effect_totals.unknown=41`.
- `unknown_cards=[]`.
- `focused_template_cards=29`.
- `28/29` focused-template cards still have `effect=unknown`.
- Only `Banishing Knack` has a non-unknown focused-template effect label in
  `effect_coverage.json`: `remove_permanent`.

Examples of focused-template cards still carrying `effect=unknown` in
`effect_coverage.json`:

| Card | Focused template match | Evidence runner reason | Next fixture |
| --- | --- | --- | --- |
| `Ashnod's Transmogrant` | `supports_counter_type_change_template` | `counter_type_change_contract_supported` | `counter_and_artifact_type_change_replay` |
| `Candelabra of Tawnos` | `supports_utility_artifact_untap_x_lands_template` | `utility_artifact_untap_x_lands_contract_supported` | `x_land_untap_activated_ability_replay` |
| `Clown Car` | `supports_x_vehicle_counters_token_template` | `x_vehicle_counters_token_contract_supported` | `x_cost_vehicle_counters_and_token_replay` |
| `Codex Shredder` | `supports_mill_graveyard_return_template` | `mill_graveyard_return_contract_supported` | `mill_then_graveyard_return_activated_ability_replay` |
| `Copy Artifact` | `supports_copy_artifact_as_enters_template` | `copy_artifact_as_enters_contract_supported` | `copy_artifact_as_enters_replay` |
| `Flash Photography` | `supports_copy_permanent_flash_or_flashback_template` | `copy_permanent_flash_or_flashback_contract_supported` | `copy_permanent_flash_timing_and_flashback_replay` |
| `Heroes' Hangout` | `supports_impulse_topdeck_or_library_zone_template` | `impulse_topdeck_or_library_zone_contract_supported` | `modal_impulse_play_until_next_turn_replay` |
| `Hidden Strings` | `supports_tap_untap_cipher_trigger_template` | `tap_untap_cipher_trigger_contract_supported` | `tap_untap_cipher_trigger_replay` |
| `Kindle the Inner Flame` | `supports_copy_token_delayed_sacrifice_template` | `copy_token_delayed_sacrifice_contract_supported` | `copy_token_delayed_sacrifice_flashback_replay` |
| `Tyvar, Jubilant Brawler` | `supports_planeswalker_static_activated_graveyard_template` | `planeswalker_static_activated_graveyard_contract_supported` | `planeswalker_static_haste_and_graveyard_activation_replay` |

## Evidence Artifacts

The focused evidence artifacts do contain specific semantic scopes. For the
same cards above, the generated `replay_events.jsonl` records concrete effects
such as:

- `counter_type_change`
- `utility_artifact_untap_x_lands`
- `x_vehicle_counters_token`
- `mill_graveyard_return`
- `copy_artifact_as_enters`
- `copy_permanent_flash_or_flashback`
- `impulse_topdeck_or_library_zone`
- `tap_untap_cipher_trigger`
- `copy_token_delayed_sacrifice`
- `planeswalker_static_activated_graveyard`

Each inspected artifact includes either a `focused_template_assertion` event
with `passed=true`, or equivalent focused fields for the concrete template
scope.

Operational reading: the focused evidence layer knows the semantic template
scope, but `effect_coverage.json` still preserves `effect=unknown` for most of
those cards. This is a reconciliation/denominator problem, not evidence that
the current focused builder queue is unready.

## Residual Coverage

The residual gate is accepted, but still represents open surface that should
not be confused with complete runtime modeling:

- `effect_coverage_residual_status=effect_coverage_residual_accepted`
- `accepted_card_flag_rows=290`
- `unaccepted_card_flag_rows=0`
- `raw_unaccepted_flags=[]`
- `accepted_flag_totals.heuristic_effect=87`
- `accepted_flag_totals.needs_review_rule=29`
- `accepted_flag_totals.trigger_not_explicit=63`
- `accepted_flag_totals.cast_permission_not_explicit=35`
- `accepted_owner_totals.battle-heuristic-fallback=87`
- `accepted_owner_totals.battle-rule-review-queue=29`
- `accepted_owner_totals.battle-effect-contract=153`
- `accepted_owner_totals.battle-land-utility-contract=21`

## Finding Update

No new BV was opened. This recheck updates `BV-068`.

The latest trusted run proves:

1. Focused template dispatch is ready for the current focused backlog.
2. `unknown_template_backlog_cards=0` only proves there are no current
   `source=unknown` backlog cards.
3. `effect_coverage.effect_totals.unknown=41` and `28/29` focused-template
   cards with `effect=unknown` prove the effect-label denominator is still open.
4. Future handoffs must not say "all action card templates/effects are fully
   modeled" unless they explicitly separate focused dispatch readiness from
   effect-label coverage and residual waivers.

## Suggested Adjustment

- Publish `effect_totals_unknown` and `focused_template_ready_unknown_effect_cards`
  directly in `summary.json`.
- Reconcile the focused artifact `fixture_scope` or `effect` back into
  `effect_coverage.json`, or expose a separate field such as
  `focused_template_effect_scope`.
- Keep `unknown_template_backlog_cards` limited to source-unknown backlog, but
  label it clearly as source-based rather than effect-label based.
- Add a regression that fails when:
  - `unknown_template_backlog_cards=0`
  - `focused_template_dispatch_status=focused_template_dispatch_ready`
  - and `effect_coverage.effect_totals.unknown>0`
  - unless the summary lists the remaining effect-unknown cards and owners.

## Validation Commands Run

- Parsed current latest `summary.json`.
- Parsed current `focused_template_dispatch.json` summary and item rows.
- Parsed current `unknown_template_backlog.json` summary.
- Parsed current `effect_coverage.json` source/effect totals and focused cards.
- Parsed current `effect_coverage_residual.json` summary.
- Inspected focused replay artifacts under
  `focused_template_dispatch_artifacts/*/replay_events.jsonl`.
- Inspected static template/evidence surface in
  `server/bin/manaloom_battle_rule_focused_evidence.py` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_focused_template_dispatch_audit.py` - PASS, `5 tests passed`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS, `Ran 5 tests ... OK`.
