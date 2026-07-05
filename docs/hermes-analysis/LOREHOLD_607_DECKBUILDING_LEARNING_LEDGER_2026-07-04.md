# Lorehold 607 Deckbuilding Learning Ledger - 2026-07-04

Status: `active_learning_checkpoint`

This ledger records the current deckbuilding lesson for protected Lorehold deck
`607`. It is not a deck promotion, not a PostgreSQL write plan, and not a
replacement list.

## External Evidence Checked

- Wizards Commander format page: Commander is a 99 + 1 singleton format built
  around commander color identity, with colorless cards allowed when legal.
  Source: https://magic.wizards.com/en/formats/commander
- Scryfall API on 2026-07-04:
  - `Lorehold, the Historian`: Commander legal, color identity `R,W`.
  - `Mana Vault`: Commander legal, colorless, `game_changer=true`.
  - `The One Ring`: Commander legal, colorless, `game_changer=true`.
  - `Smothering Tithe`: Commander legal, white, `game_changer=true`.
- EDHREC Lorehold upgraded/discard page on 2026-07-04:
  `Library of Leng`, `Storm Herd`, `Monument to Endurance`, `Big Score`,
  `Approach of the Second Sun`, `Mizzix's Mastery`, `Sensei's Divining Top`,
  and `Scroll Rack` remain high commander-context signals.
  `The One Ring` appears as a game changer but only at low current Lorehold
  inclusion on that page.
  Source: https://edhrec.com/commanders/lorehold-the-historian/upgraded/discard
- EDHREC Lorehold miracle article and Draftsim/Card Kingdom guides agree with
  the main strategic read: the deck is not generic Boros ramp-goodstuff. It
  needs topdeck setup, miracle timing, repeated opponent-upkeep looting, big
  instant/sorcery conversion, and specific finishers such as `Approach of the
  Second Sun`.

## Internal Evidence Generated

Fresh read-only reports generated after the 2026-07-04 role/tag repair:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_closing_window_trace_miner_20260704_role_tag_repair.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_trace_targeted_micro_package_model_20260704_role_tag_repair.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_trace_cut_evidence_expander_20260704_role_tag_repair.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260704_role_tag_repair_learning.md`

Important current outputs:

- Closing-window miner: `13` direct comparisons where `607` won and rejected
  challengers lost. All `13` challenger losses died before the `607` closing
  window. Average `607` turn advantage was `10.15`.
- Dominant strategic deficits in rejected challengers:
  `lorehold_cost_paid=153`, `lorehold_spell_cast=134`, `miracle_cast=71`,
  `lorehold_upkeep_rummage=63`, `topdeck_manipulation_activated=41`, and
  `static_cost_reduction_total=37`.
- Dominant protected anchor deficits: `Sensei's Divining Top`, `Scroll Rack`,
  `Approach of the Second Sun`, `Victory Chimes`, `Mizzix's Mastery`,
  `Bender's Waterskin`, and `Jeska's Will`.
- Seed-safe cut synthesis: `94` deck rows evaluated, `0` seed-safe cuts,
  `92` hard-blocked slots, and `2` same-lane hard-blocked slots.
- The same-lane hard-blocked slots are `Creative Technique` and
  `Bender's Waterskin`; neither is a generic cut under the current contract.
- Trace-targeted micro-package model: `3` trace hypotheses evaluated,
  `0` ready micro-packages because `seed_safe_cut_ready_count=0`.
- Planner top action:
  `no_cut_slot_to_expand_under_current_607_contract`.

## Current Learning

`Mana Vault` and `The One Ring` are accessible to Lorehold by legality and color
identity. They are not accessible to the current `607` champion as automatic
deck changes because the current contract requires a safe cut and equal battle
proof.

Prior controlled tests already exercised both cards:

- `Mana Vault` is a real fast-mana card, but the repaired one-card swap over
  `Bender's Waterskin` lost the confirmed gate and did not replace the
  miracle-timing/ramp lane cleanly.
- `The One Ring` is a real protection/draw engine, but the tested draw/value
  cuts lost to `607`; the card was accessed and used, so the rejection was not
  caused by invisible sampling.

The practical rule for ManaLoom deckbuilding is:

1. A card can be legal, powerful, popular, and even a `game_changer`, and still
   fail this deck.
2. For Lorehold, value must be measured by whether the card preserves or
   improves the miracle/topdeck/rummage/spell-volume closing window.
3. A new card must either replace the same lane with proof or be part of a
   declared package that protects the `607` anchors.
4. Forced-access evidence can teach card value, but it cannot promote a deck
   without natural confirmation and critical-matchup safety.

## What Not To Do Next

- Do not run more one-for-one swap gates against `607` from the exhausted queue.
- Do not cut `Bender's Waterskin` or `Creative Technique` as generic flex.
- Do not treat `Mana Vault`, `The One Ring`, or another game changer as an
  automatic upgrade.
- Do not promote a from-scratch shell from structure, popularity, or forced
  access alone.

## Valid Next Learning Paths

1. External-card-evidence path: find a newly supported card or public package
   that changes a specific cut-safety row, then rerun the safe-cut model before
   any battle gate.
2. Full-shell path: declare a separate archetype contract that keeps the `607`
   topdeck/miracle/protection floor and explicitly repairs pressure conversion.
3. Runtime-change path: if a battle adapter changes materially, rerun the
   exposure and gate evidence for affected cards before drawing deckbuilding
   conclusions.
4. Product-model path: expose `game_changer`, commander inclusion rate,
   commander-context role, same-lane cut status, and battle proof separately in
   the app. Do not collapse them into one "best card" score.

## Mana-Base Learning - 2026-07-05

`Plateau` is Commander legal for Lorehold and is structurally attractive because
it is an untapped `Mountain Plains`. That still was not enough to replace a land
in protected `607` without battle proof.

Two exact mana-base hypotheses were materialized only in copied Hermes DBs and
then rejected:

- `+Plateau / -Radiant Summit`: preflight passed, but natural smoke and forced
  opening-hand diagnostics both lost to `607`.
- `+Plateau / -Turbulent Steppe`: preflight passed, natural smoke was
  inconclusive at `0/1` for both lists, and forced opening-hand diagnostics
  lost `1/3` versus protected `607` at `2/3`.

The important deckbuilding lesson is that a cleaner untapped dual can be a real
structural upgrade and still fail the active Lorehold shell if it does not
improve the actual battle window. The current mana-base model-ready queue is
closed until new material evidence changes the safe-cut pool or proposes a
different land package, not another exact retest of these pairs.

## Post-Mana-Base Route - 2026-07-05

After closing the simple mana-base queue, the current router says the next
valid learning route is `build_pressure_safe_cut_expansion_model`.

Current facts:

- mana-base eligible pairs: `0`;
- natural gate-ready watchlist cards: `0`;
- pressure package gate-ready count: `0`;
- seed-safe cut-ready count: `0`;
- promotable external shell count: `0`.

External evidence continues to support Lorehold as a spellslinger/topdeck/
miracle commander, with pressure/treasure signals such as `Storm-Kiln Artist`,
but that does not create a deck change by itself. The active blocker is cut
safety: before testing more pressure, Treasure, or combo packages, ManaLoom must
find a named cut plan that preserves the protected `607` miracle/topdeck floor.

Do not run another natural battle gate from the current watchlist until a
candidate has safe-cut proof and miracle-access preflight.

Current conclusion: protected deck `607` remains the Lorehold champion under
the active contract. The learning task stays open because a better deck may
exist, but it has not been proven by the current evidence.

## Pressure Safe-Cut Expansion Model - 2026-07-05

The next learning artifact is:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_safe_cut_expansion_model_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_safe_cut_expansion_model_20260705_current.json`

It converts the external deckbuilding lesson into an executable local policy:
legal identity, public popularity, game-changer status, and raw card power are
only inputs. A card becomes actionable only after it improves a specific
Lorehold lane, has a named safe cut, and survives battle/replay validation.

Current result:

- status: `pressure_cut_expansion_no_seed_safe_cut_keep_607`;
- seed-safe cuts: `0`;
- same-lane-only diagnostic cuts: `2`;
- hard-blocked cuts: `92`;
- gate-ready pressure packages: `0`;
- natural battle allowed now: `false`;
- promotion allowed: `false`.

Current pressure routes:

- `Monastery Mentor`, `Young Pyromancer`, `Guttersnipe`, and
  `Storm-Kiln Artist` remain the primary four-card pressure package, but it is
  blocked because it needs four named safe cuts and currently has zero.
- `Guttersnipe` plus `Young Pyromancer` remains the smallest natural-trigger
  pressure hypothesis, but it is also blocked because it needs two safe cuts.
- `Storm-Kiln Artist` plus `Haze of Rage` is a valid combo research lane, not a
  promotion lane, until runtime, cut-safety, and battle evidence exist.

Current cut-learning targets:

- `Creative Technique`: same-lane diagnostic only; not a generic flex cut.
- `Bender's Waterskin`: same-lane diagnostic only; not a generic fast-mana cut.
- `Generous Gift`, `Esper Sentinel`, `Path to Exile`,
  `Swords to Plowshares`, `Monument to Endurance`, `Sensei's Divining Top`,
  and `Smothering Tithe` remain blocked by high exposure or protected role
  evidence.

Staple/artifact/land lesson:

- `Mana Vault` is legal and powerful, but remains blocked as an automatic
  include because the prior one-card `Bender's Waterskin` replacement lost.
- `The One Ring` is legal and powerful, but remains blocked as an automatic
  include because tested draw/value cuts lost to protected `607`.
- `Storm-Kiln Artist` is contextual pressure/treasure research, not a generic
  mana-rock replacement.
- `Plateau` is a structurally clean land, but both simple copied-DB swaps were
  rejected, so simple land swaps are not the next learning route.

Current conclusion remains unchanged: protected deck `607` is still the
Lorehold champion. The persistent learning task continues through cut-cost
discovery and diagnostic-only same-lane microbenchmarks, not natural battles.
