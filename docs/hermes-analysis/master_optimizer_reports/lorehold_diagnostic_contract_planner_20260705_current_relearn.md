# Lorehold Diagnostic Contract Planner

- Generated at: `2026-07-05T03:20:12Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- External reconciliation: `docs/hermes-analysis/master_optimizer_reports/lorehold_external_evidence_reconciler_20260704_current.json`
- Shell synthesis: `docs/hermes-analysis/master_optimizer_reports/lorehold_external_shell_gate_synthesis_20260704_current.json`
- Hypothesis queue: `docs/hermes-analysis/master_optimizer_reports/lorehold_hypothesis_queue_from_value_model_20260705_current_relearn.json`
- Current champion: `deck_607`
- Diagnostics ranked: `8`
- Actionable learning items: `4`
- Ready deck changes: `0`
- Matched hypothesis rows: `5`
- Natural gate-ready from hypothesis queue: `0`
- Top diagnostic: `pressure_safe_spell_payoff_micro_shell`
- Recommended next action: `draft_pressure_safe_spell_payoff_diagnostic_contract_no_natural_gate`
- Readiness counts: `{"blocked_until_cut_safety_changes": 2, "defer": 1, "design_next": 2, "research_or_diagnostic_only": 2, "support_current_607_no_new_test": 1}`

## Card Value Framework

| Axis | Current 607 rule | Value test | Anti-pattern |
| --- | --- | --- | --- |
| lands_and_mana_base | Preserve the 34-land floor unless a full-shell matrix proves a new curve. | Color reliability, commander turn target, untapped sources, and spell-window support beat raw land power. | Cut lands or source quality to fit more famous spells before proving curve safety. |
| ramp_and_artifacts | Separate structural floor ramp from burst/high-power ramp. | Ramp must improve Lorehold timing without reducing miracle cadence or pressure survival. | Treat Mana Vault, Cloud Key, or another artifact as automatically better than Bender's Waterskin or Arcane Signet. |
| staples | A staple is a role-floor signal, not deck truth. | Global power must survive commander-specific role fit, cut safety, direct use, and equal gate evidence. | Force The One Ring or another game changer into 607 after tested cuts already lost. |
| synergy_and_combo | Synergy must support topdeck/miracle setup, rummage, spell-chain conversion, protection, or pressure repair. | A combo line is valuable only if the shell can access it, protect it, and still survive fast pressure. | Add Approach/Lapse, Breach, Aetherflux, or token payoffs without a protection/pressure contract. |
| cuts | No current seed-safe one-for-one cuts are available under the protected 607 contract. | Each add needs a same-lane cut or a declared separate shell contract before battle promotion. | Use Creative Technique, Bender's Waterskin, Molecule Man, or other protected anchors as generic cuts. |

## Ranked Diagnostics

| Rank | Diagnostic | Readiness | Score | Lane | Cards | Why |
| ---: | --- | --- | ---: | --- | --- | --- |
| 1 | `pressure_safe_spell_payoff_micro_shell` | `design_next` | 12 | `pressure_absorber` | Monastery Mentor, Young Pyromancer, Guttersnipe, Storm-Kiln Artist | Targets the known pressure/closing-window weakness without asking for a generic one-for-one cut. |
| 2 | `discard_reanimator_alt_intent_profile` | `design_next` | 11 | `graveyard_recursion` | Storm of Souls, Late to Dinner, Karmic Guide | This is likely a different Lorehold archetype, not an improvement to the protected 607 miracle shell. |
| 3 | `approach_lapse_permission_diagnostic` | `research_or_diagnostic_only` | 10 | `deterministic_finisher` | Lapse of Certainty | Approach is already a 607 finisher; Lapse tests whether protection of the second Approach is worth a future slot, but no seed-safe cut exists. |
| 4 | `declared_high_power_fast_mana_shell` | `research_or_diagnostic_only` | 8 | `early_plan` | Chrome Mox, Mana Vault, Grim Monolith, Mox Diamond, Lion's Eye Diamond, Lotus Petal | Fast mana is externally strong, but Mana Vault over Bender's Waterskin already lost, so this must be a declared high-power shell instead of a 607 one-card repair. |
| 5 | `external_topdeck_miracle_anchor_floor_diagnostic` | `support_current_607_no_new_test` | 6 | `topdeck_miracle_setup` | - | Multiple external sources independently reinforce the current 607 topdeck/miracle floor rather than replacing it. |
| 6 | `external_breach_wheel_aetherflux_conversion_shell_diagnostic` | `defer` | 2 | `spell_chain_conversion` | Underworld Breach, Wheel of Fortune, Aetherflux Reservoir, Birgi, God of Storytelling // Harnfel, Horn of Bounty | External data supports a compact high-power conversion shell, but prior broad shells failed and this needs a smaller named contract. |
| 7 | `external_brainstone_planetarium_topdeck_extension_diagnostic` | `blocked_until_cut_safety_changes` | -2 | `topdeck_miracle_setup` | Brainstone, Planetarium of Wan Shi Tong | External sources support these as topdeck tools, but the only named 607 cut is protected or previously rejected. |
| 8 | `external_one_ring_value_engine_diagnostic` | `blocked_until_cut_safety_changes` | -4 | `card_draw_selection` | The One Ring | The One Ring is legal and a game changer, but current internal battle proof rejects the tested 607 cuts. |

## Next Contract Requirements

### `pressure_safe_spell_payoff_micro_shell`

- Preserve the 607 mana, topdeck, miracle, protection, and pressure anchors.
- Add only a compact spell-payoff pressure package before expanding the shell.
- Require structure matrix alignment before any smoke battle.
- Promote only if equal gate ties or beats 607 and Winota does not regress.
- Require direct card events for the pressure package before card-level claims.
- Current hypothesis queue: matched `Storm-Kiln Artist`; natural gate allowed `false`.

### `discard_reanimator_alt_intent_profile`

- Create a separate intent profile before any deck generation.
- Do not compare as a 607 replacement until the archetype has its own matrix.
- Require recursion payoff telemetry, not only graveyard-card density.

### `approach_lapse_permission_diagnostic`

- Do not mutate deck 607.
- First verify runtime/card-rule support and card access traces.
- Treat forced-access results as learning only, not promotion.
- Name a seed-safe same-lane cut before natural battle confirmation.

### `declared_high_power_fast_mana_shell`

- Declare bracket/power target before card selection.
- Do not cut Bender's Waterskin as generic ramp.
- Preserve pressure-survival and miracle cadence targets.
- Require a full structure matrix and equal gate before promotion claims.
- Current hypothesis queue: matched `Mana Vault`; natural gate allowed `false`.

## External Refresh Sources

- `draftsim_approach_lapse_risk_refresh`: https://draftsim.com/lorehold-approach-combo/ - Approach lines are concrete but telegraphed; the second Approach must resolve, so protection/permission is part of the test contract.
- `edhrec_lorehold_combo_refresh`: https://edhrec.com/combos/lorehold-the-historian - Lorehold combo evidence clusters around Approach, spell-copy, Storm-Kiln, Birgi, Breach, token/damage payoff, and topdeck packages.
- `draftsim_lorehold_synergy_refresh`: https://draftsim.com/lorehold-the-historian-edh-deck/ - Lorehold synergy must either reward discard/rummage or set up miracle timing; generic value is lower priority.
- `cardkingdom_lorehold_identity_refresh`: https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/ - The commander identity is cost reduction, miracle timing, and rummage; candidate value must be measured against that identity.
- `gametyrant_lorehold_payoff_refresh`: https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech - Entreat, Approach, Apex, Dance, Hit the Mother Lode, and Insurrection are payoff signals, but each still needs topdeck setup and closing-window proof.
- `coolstuffinc_lorehold_shell_refresh`: https://www.coolstuffinc.com/a/stephenjohnson-04202026-lorehold-the-historian-commander - Lorehold can branch into spellslinger, combo, token, damage, or Voltron shells; those are separate contracts unless they preserve the protected 607 floor.

## Method Notes

- This planner is read-only and does not mutate PostgreSQL, SQLite, or deck rows.
- Priority score ranks learning value, not permission to change deck 607.
- Any natural battle gate still requires a named contract, structure matrix, equal opponent/seed window, and direct card-use evidence.
- Forced-access diagnostics remain learning-only unless later natural confirmation passes the Lorehold promotion gate.
- The current hypothesis queue contributes candidate/anchor context, but zero natural gate-ready rows means this planner can only authorize diagnostic design.
