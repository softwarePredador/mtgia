# Lorehold Focus-Access Package Design 2026-06-28

- planner: `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260628_v13_brass_rejection_integrated.md`
- trace_audit: `docs/hermes-analysis/master_optimizer_reports/lorehold_failure_targeted_trace_audit_20260628_v3_focus_access.md`
- saga_scope_audit: `docs/hermes-analysis/master_optimizer_reports/lorehold_urzas_saga_tutor_scope_audit_20260628_v1.md`
- brass_decision: `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_recurring_seed_window_decision_20260628_v1.md`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_swap_applied: `false`

## Decision

Do not run a new battle gate yet.

The current planner reports `gate_ready_now=0`. The next action is not another
blind add/cut swap; it is a focus-access package design that preserves the
current successful engine and targets the two failing seed classes.

## Evidence

The updated planner now loads `8` rejected prior packages, including
`brass_bounty_cut_boros_signet`. This prevents the queue from reintroducing
`Brass's Bounty` over `Boros Signet` after the 16-seed recurring window rejected
that swap.

Current focus-access trace:

| Seed | Record | Read |
| ---: | --- | --- |
| 7 | 0-9 | Missing early engine: `Library of Leng`, `Sensei's Divining Top`, and `Squee, Goblin Nabob` stayed in library early; `Sensei's Divining Top` had min library position `27`. |
| 42 | 7-2 | Anchor success: high topdeck/miracle conversion, Squee graveyard/return events, and strong engine access. |
| 20260625 | 0-9 | Engine pieces can appear, but conversion fails under pressure; `Library of Leng` and `Scroll Rack` show access, while `Squee` and `Land Tax` stay inaccessible. |

The Saga-specific audit closes the obvious runtime suspicion: current
`Urza's Saga` priority can select `Sensei's Divining Top` with
`selected_reason=find_lorehold_topdeck_miracle_engine`. That means the next
package should not be "fix Saga" or "add another generic engine card" unless a
new trace contradicts this current-state check.

## Protected Current Engine

Keep these protected while designing the next hypothesis:

- `Urza's Saga`
- `Library of Leng`
- `Sensei's Divining Top`
- `Scroll Rack`
- `Squee, Goblin Nabob`
- `The Mind Stone`
- `Land Tax`
- `Boros Signet`

Do not use any of them as cuts for the next package without a same-lane model
that specifically proves the replacement preserves seed-42 topdeck/miracle
conversion.

## Next Package Contract

A valid next package must satisfy all of these before battle:

1. It targets one named failure mode: seed-7 missing engine access or
   seed-20260625 conversion under pressure.
2. It avoids exact prior-negative swaps, including `Brass's Bounty` over
   `Boros Signet`, tutor-over-`Land Tax`, hand-filter-over-`Big Score`, and the
   prior Plateau land swaps.
3. It preserves the protected Top/Library/Rack/Saga/Squee engine.
4. It has active local runtime rules or is routed to XMage/runtime work before
   any win-rate claim.
5. It keeps seed 42 as the regression anchor: topdeck activations and miracle
   casts must not collapse in the first controlled gate.

## Next Implementation Step

Build a failure-targeted package generator from the focus-access trace instead
of adding one card manually. The generator should output only packages that:

- carry a `target_failure_mode`;
- list `protected_cards_avoided`;
- include `prior_negative_exact_match=false`;
- include `runtime_status=active_or_materialized`;
- include `seed_42_anchor_requirement`.

If the generator cannot find a package, the next concrete work is runtime/trace
instrumentation for the focus cards, not a deck swap.
