# Lorehold 607 Post-Birgi Candidate Sweep - 2026-07-05

Status: `no_promotion_607_remains_baseline`

## Scope

After `birgi_spellchain_cut_jeskas_will` was rejected for Winota regression,
this pass tested the next available hypotheses under the same read-only rule:

- do not mutate protected deck `607`;
- use isolated candidate SQLite DBs or package-gate copies;
- require aggregate result, card exposure, and critical pressure matchup checks
  before any promotion;
- treat `Winota, Joiner of Forces` as a veto matchup when a package becomes
  slower or loses pressure resilience.

## Dragon's Rage Channeler Family

Existing 2026-07-05 research candidates had structural and first-pass aggregate
signals for `Dragon's Rage Channeler` as a topdeck/access card. The two best
available cuts were rechecked against the pressure seed `2026070506`, which
includes Winota.

### DRC over Hexing Squelcher

Earlier broad gate:

- report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260705_drc_hexing_squelcher_v1_gate24_partial.md`
- candidate: `34W/38L/0S`, win rate `47.22%`
- baseline `607`: `30W/42L/0S`, win rate `41.67%`
- warning: candidate was worse into fixed deck `607` in that sample
  (`9W/15L` vs baseline `11W/13L` against fixed `607`)

Pressure recheck:

- report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_607_drc_hexing_squelcher_v1_winota_gate_20260705_seed2026070506.json`
- baseline `607`: `14W/18L/0S`, win rate `43.75%`, average win turn `15.50`
- candidate: `8W/24L/0S`, win rate `25.00%`, average win turn `20.00`
- fixed `607` matchup: both `4W/4L`
- Winota matchup: baseline `2W/6L`; candidate `0W/8L`
- Dragon's Rage Channeler was used: `cost_paid` count `6`

Decision: reject. The broad signal did not survive the pressure sample.

### DRC over Call Forth the Tempest

Earlier broad gate:

- report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260705_drc_call_forth_the_tempest_v1_gate24.md`
- candidate: `32W/40L/0S`, win rate `44.44%`
- baseline `607`: `30W/42L/0S`, win rate `41.67%`

Pressure recheck:

- report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_607_drc_call_forth_v1_winota_gate_20260705_seed2026070506.json`
- baseline `607`: `14W/18L/0S`, win rate `43.75%`, average win turn `15.50`
- candidate: `7W/25L/0S`, win rate `21.88%`, average win turn `15.14`
- fixed `607` matchup: both `4W/4L`
- Scion matchup: baseline `2W/6L`; candidate `0W/8L`
- Winota matchup: baseline `2W/6L`; candidate `0W/8L`
- Dragon's Rage Channeler was used: `cost_paid` count `14`

Decision: reject. The card was exposed, but cutting a high-impact spell made
the shell collapse into the pressure/combo sample.

## Birgi Preserving Jeska's Will

Preflight:

- report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_preserve_jeska_alternates_preflight_20260705_preserve_jeska.json`

Results:

- `birgi_spellchain_cut_squelcher`: blocked by cut safety because
  `Hexing Squelcher` is registry-protected; exact prior result was
  `reject_or_rework`, delta `-3.70pp`.
- `birgi_spellchain_cut_waterskin`: blocked by cut safety because
  `Bender's Waterskin` is protected; prior evidence includes
  `tie_watch_strategy_regression` and registry result `3W/6L/0S`, Winota
  `1W/2L`, with reduced miracle/topdeck games.
- `birgi_seething_chain_cut_medallions`: blocked because `Pearl Medallion` and
  `Ruby Medallion` are `locked_do_not_cut`; exact prior result was
  `reject_or_rework`.

Decision: no Birgi-preserving-Jeska package is currently gate-ready. Birgi is a
real spell-chain card, but the available cuts either already failed or attack
protected infrastructure.

## Big Staples

Preflight:

- report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_big_staples_preflight_20260705_current.json`

Results:

- `one_ring_protection_draw_cut_squelcher`: blocked by `Hexing Squelcher`
  protection and exact prior rejection, delta `-14.82pp`.
- `mana_vault_fast_mana_cut_arcane_signet`: cut safety clear, but exact prior
  natural gates rejected it multiple times; the exposed candidate lost by
  `-66.67pp`, reduced `lorehold_cost_paid`, `lorehold_spell_cast`, and
  `miracle_cast`.
- `one_ring_burden_reset`: blocked by `Bender's Waterskin` cut safety, but
  lacked exact prior evidence, so it was tested read-only with cut-safety
  disabled for learning.

### One Ring over Bender's Waterskin

- wrapper report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_burden_reset_research_gate_20260705_no_cut_safety_winota.json`
- battle report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_burden_reset_research_gate_20260705_no_cut_safety_winota_one_ring_burden_reset.json`
- package status: `gated`
- decision: `reject_regresses_critical_matchup`
- baseline `607`: `12W/20L/0S`, win rate `37.50%`, average win turn `15.08`
- candidate: `12W/20L/0S`, win rate `37.50%`, average win turn `18.83`
- Winota baseline: `3W/5L`, average win turn `10.33`
- Winota candidate: `2W/6L`, average win turn `18.00`
- The One Ring exposure: `24` recorded use events
- Bender's Waterskin baseline exposure: `20` recorded use events

Decision: reject. The One Ring was used and raised some miracle/topdeck counts,
but it did not increase aggregate wins, slowed wins materially, and regressed
Winota.

## Current Learning

- `607` remains protected baseline.
- Aggregate-only gains are not enough. DRC and Birgi both produced encouraging
  windows, then failed the pressure recheck.
- `Jeska's Will`, `Bender's Waterskin`, `Hexing Squelcher`, and the medallions
  remain protected by current evidence.
- `Mana Vault` and `The One Ring` are legal/powerful cards, but the tested cuts
  do not improve this Lorehold shell.
- The next productive work is cut discovery or a multi-card package that
  explicitly preserves fast-pressure resilience, not forcing another famous
  staple into the 607 list.
