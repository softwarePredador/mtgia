# Battle latest template completeness denominator recheck 2026-06-19

Scope: recheck whether the current battle artifacts prove that all card action
templates/effects are complete. This is read-only and documentation-only.

Guardrails:

- PostgreSQL was not modified.
- No swaps were applied.
- No code was changed.
- No commit was created.
- Only artifacts, logs, tests and documentation were inspected or written.

## Latest artifact

- Latest path:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539`
- Primary summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `timestamp_utc=2026-06-19T21:45:39Z`
- `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["action_critic=review_required","forensic_audit=review_required"]`
- `action_findings=1`
- `forensic_rule_findings=2`
- `forensic_lineage_status=incomplete`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`
- `seeds_with_high_or_critical_forensic_findings=[]`

No high/critical action finding or strategy blocker is present, but this run is
not globally trusted for learning because mandatory gates require review.

## Denominator summary

Current headline fields:

```text
focused_template_dispatch_status=focused_template_dispatch_ready
focused_template_cards=29
focused_template_evidence_ready=29
focused_template_cards_not_ready_unwaived=[]
focused_template_supports_template_count=47
focused_template_build_evidence_function_count=47
focused_template_evaluate_dispatch_template_count=47
unknown_template_backlog_cards=0
effect_coverage_unknowns=0
effect_coverage_effect_totals_unknown=41
focused_template_ready_unknown_effect_count=28
focused_template_ready_known_effect_count=1
effect_coverage_residual_status=effect_coverage_residual_accepted
effect_coverage_residual_card_flag_rows=290
effect_coverage_residual_unique_flagged_cards=237
effect_coverage_residual_raw_flag_total=536
effect_coverage_residual_unaccepted_card_flag_rows=0
```

Operational meaning:

- The focused template dispatch queue is ready for the current focused backlog.
- The unknown-template backlog is empty because no source-unknown card lacks
  reviewed family/template/plan coverage.
- This does not prove that all card action templates/effects are fully created
  or that every focused card has a stable effect label.
- The effect denominator still contains `41` `unknown` effect instances, and
  `28/29` focused-template-ready cards still have `effect=unknown`.
- Residual coverage is fully accepted by current policy, but it still includes
  heuristic fallback, trigger/cast-permission/duration residuals, needs-review
  rules and utility-land limitations.

## Focused template cards with unknown effect labels

The following focused-template-ready cards still have `effect=unknown` in
`effect_coverage.json`, even though each has evidence artifacts and a reviewed
template family:

```text
Ashnod's Transmogrant        counter_manipulation_and_type_change
Candelabra of Tawnos        utility_artifact_untap_x_lands
Clown Car                   x_cost_counters_vehicle_token
Codex Shredder              mill_and_graveyard_return
Copy Artifact               copy_artifact_static_as_enters
Cryptic Coat                manifest_cloak_equipment
Cursed Windbreaker          manifest_cloak_equipment
Dissection Tools            manifest_cloak_equipment
Firestorm                   additional_cost_discard_multi_target_damage
Flash Photography           copy_permanent_with_flash_or_flashback
God-Pharaoh's Statue        static_tax_and_opponent_life_loss
Heroes' Hangout             impulse_topdeck_or_library_zone
Hidden Strings              tap_untap_cipher_trigger
Kindle the Inner Flame      copy_token_with_delayed_sacrifice, graveyard_recast_replacement
Liquimetal Coating          type_change_continuous_effect
Mine Collapse               alternative_cost_sacrifice_mountain_damage
Nevermore                   static_named_card_cast_restriction
Opera Love Song             impulse_topdeck_or_library_zone
Out of Time                 phase_out_mass_removal_counters
Power Artifact              cost_reduction_static_aura
Reality Acid                vanishing_sacrifice_trigger_removal
Scroll of Fate              manifest_from_hand_activated_ability
Stoke the Flames            convoke_damage
Submerge                    alternative_cost_library_bounce
Sudden Shock                split_second_damage
Thorn of Amethyst           static_noncreature_tax
Tragic Arrogance            modal_mass_sacrifice_selection
Tyvar, Jubilant Brawler     planeswalker_static_and_activated_graveyard_ability
```

`Banishing Knack` is the focused-template-ready card with a known effect:
`remove_permanent`.

## Residual coverage

`effect_coverage_residual.json` reports all residual rows as accepted by current
policy, not eliminated:

```text
accepted_card_flag_rows=290
unique_flagged_cards=237
raw_flag_total=536
unaccepted_card_flag_rows=0
```

Accepted owner totals:

```text
battle-effect-contract      153
battle-heuristic-fallback    87
battle-land-utility-contract 21
battle-rule-review-queue     29
```

Accepted flag totals:

```text
cast_permission_not_explicit      35
copy_effect_mismatch               1
heuristic_effect                  87
land_utility_ability_not_modeled  21
needs_review_rule                 29
oracle_silence_mismatch            4
oracle_target_removal_mismatch    12
temporary_effect_not_explicit     38
trigger_not_explicit              63
```

This means `effect_coverage_residual_accepted` is a policy state, not full
runtime completeness. It is useful as a tracked denominator, but it must not be
cited as proof that every card behavior is card-specific and fully modeled.

## Source evidence

- `effect_coverage.md` states `total_card_instances=1288`,
  `unique_cards=556`, source totals including `focused_template_ready=33`, and
  `effect_totals.unknown=41`.
- `focused_template_dispatch.md` states `29/29` focused cards are evidence
  ready, with `47/47` support/build/dispatch functions covered.
- `unknown_template_backlog.md` states `unknown_cards=0` but also explicitly
  says `backlog_manifest_ready` does not mean runtime support is complete.
- `battle_effect_coverage_audit.py` still publishes
  `focused_template_unknown_effect_scope_cards` when focused-template cards have
  `effect=unknown`.
- `battle_focused_template_dispatch_audit.py` marks readiness based on predicate
  match, evidence dispatch and focused evidence, not on effect label
  reconciliation.
- `battle_effect_coverage_residual_audit.py` blocks raw `unknown_effect`, but
  accepts configured residual contracts such as heuristic fallback, trigger
  gaps and needs-review rules.

## Tests run

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_focused_template_dispatch_audit.py
5 tests passed
```

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py
PASS test_known_unknown_cards_have_reviewed_families_and_plans
PASS test_current_backlog_representatives_have_focused_template_matches
PASS test_unplanned_unknown_card_is_reported
```

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_residual_audit.py
3 tests passed
```

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py
Ran 6 tests
OK
```

The tests confirm current contracts are green, but the contracts are narrower
than "all card action templates/effects are complete".

## Operational reading

- `BV-059` remains open: residual coverage is accepted, not eliminated.
- `BV-068` remains open: `effect_totals.unknown=41` and `28/29`
  focused-template-ready cards still carry `effect=unknown`.
- The correct answer to "are all card action templates created?" is:
  "the current focused backlog has dispatch/evidence coverage, but total battle
  action/effect completeness is not proven."
- Closure requires either `effect_totals.unknown=0`, or an explicit denominator
  and waiver contract that lists every unknown effect card with owner, status,
  reason and learning impact.
