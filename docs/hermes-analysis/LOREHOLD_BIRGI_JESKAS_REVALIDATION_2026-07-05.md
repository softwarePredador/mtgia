# Lorehold Birgi/Jeskas Revalidation - 2026-07-05

Status: `rejected_no_deck_mutation`

## Scope

The user authorized full validation and retesting. This pass reopened the
previously rejected Lorehold package:

- add: `Birgi, God of Storytelling // Harnfel, Horn of Bounty`
- cut: `Jeska's Will`
- protected baseline: Lorehold deck `607`
- mutation policy for this run: battle and candidate DB evidence only; do not
  promote or alter deck `607` unless the candidate passes aggregate and critical
  matchup gates.

## Preflight Findings

`birgi_spellchain_cut_jeskas_will` was initially blocked by prior evidence:

- report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_preserve_engine_gate_20260705_birgi_cut_jeskas_preflight.json`
- package status: `skipped_prior_evidence`
- decision: `not_run_prior_reject_blocked`

A broader 607-preserving package queue was also blocked before battle:

- report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_607_preserve_engine_package_preflight_20260705_candidate_queue.json`
- prior-reject blocked: `seething_song_cut_fellwar_stone`,
  `brass_bounty_cut_boros_signet`, `runaway_steamkin_cut_talisman`,
  `boros_charm_pressure_cut_avatar_wrath`,
  `pg245_twinflame_damage_payoff_cut_thor`,
  `perch_protection_cut_avatar_wrath`, `silence_cut_avatar_wrath`
- cut-safety blocked: `overmaster_protect_draw_cut_tibalts_trickery`,
  `ghostly_prison_pressure_cut_promise`,
  `guttersnipe_spell_payoff_cut_prismari`

Because the current authorization explicitly allowed retesting, the Birgi
package was rerun with `--ignore-prior-results`.

## Battle Evidence

### Broad Gate - Seed `2026070503`

- report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_preserve_engine_gate_20260705_current_reopen.json`
- decision: `promote_to_deeper_gate`
- baseline `607`: `6W/26L/0S`, win rate `18.75%`, average win turn `16.00`
- candidate: `14W/18L/0S`, win rate `43.75%`, average win turn `17.71`
- exposure: `candidate_added_cards_used`
- Birgi events: `25`
- Jeska's Will baseline cut-card events: `11`
- critical matchup regressions: none in this sample

### Broad Confirmation - Seed `2026070504`

- report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_preserve_engine_gate_20260705_confirm_seed2026070504.json`
- decision: `promote_to_deeper_gate`
- baseline `607`: `10W/22L/0S`, win rate `31.25%`, average win turn `14.40`
- candidate: `13W/19L/0S`, win rate `40.62%`, average win turn `15.31`
- exposure: `candidate_added_cards_used`
- Birgi events: `72`
- Jeska's Will baseline cut-card events: `21`
- critical matchup regressions: none in this sample

Combined before the pressure check, the package was positive:

- baseline `607`: `16W/48L`
- candidate: `27W/37L`
- net: candidate `+11` wins across `64` games

### Winota Pressure Check - Seed `2026070506`

- report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_preserve_engine_gate_20260705_winota_seed2026070506.json`
- battle detail:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_preserve_engine_gate_20260705_winota_seed2026070506_birgi_spellchain_cut_jeskas_will.json`
- package status: `gated`
- decision: `reject_regresses_critical_matchup`
- overall baseline `607`: `12W/20L/0S`, win rate `37.50%`, average win turn
  `15.08`
- overall candidate: `14W/18L/0S`, win rate `43.75%`, average win turn `16.00`
- exposure: `candidate_added_cards_used`
- Birgi events: `58`
- Jeska's Will baseline cut-card events: `16`

Critical matchup result:

- opponent: `Winota, Joiner of Forces #73 (real)`
- baseline `607`: `3W/5L/0S`, win rate `37.50%`, average win turn `10.33`
- candidate: `2W/6L/0S`, win rate `25.00%`, average win turn `16.50`
- regression: `Winota`

Winota is a veto gate for this package because it represents fast pressure. The
candidate did not fail from lack of exposure: Birgi was cast and triggered in
the sample. The failure is strategic: replacing Jeska's Will with Birgi improves
some spell-chain windows but makes the shell slower and weaker into the critical
pressure matchup.

## Decision

Do not promote `birgi_spellchain_cut_jeskas_will`.

Do not mutate deck `607`.

Deck `607` remains the protected Lorehold baseline after this pass. Birgi is a
real candidate card, but this exact cut is rejected. Any future Birgi hypothesis
must preserve Jeska's Will or compensate for the Winota/fast-pressure regression
with a same-lane cut and a pressure-safe battle gate.

## Learning Imported Into Deckbuilding Policy

- Aggregate improvement is not enough when a candidate loses a critical matchup.
- Card exposure matters: this package had Birgi usage, so the rejection is based
  on observed strategic regression, not on an untested card.
- Spell-mana engines can raise ceiling while lowering pressure resilience.
- Jeska's Will remains protected in the current 607 shell until a replacement
  preserves or improves fast-pressure performance.
- The next Lorehold search should focus on cut discovery, not automatic staple
  insertion.
