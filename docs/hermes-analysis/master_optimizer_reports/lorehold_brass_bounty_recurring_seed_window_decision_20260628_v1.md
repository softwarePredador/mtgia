# Lorehold Brass's Bounty Recurring Seed Window Decision 2026-06-28

- recurring_seed_window: `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_recurring_seed_window_20260628_v1_run.md`
- previous_short_gate: `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_confirm_matrix_20260628_v1_run.md`
- previous_decision_note: `docs/hermes-analysis/master_optimizer_reports/lorehold_access_and_brass_decision_20260628_v1.md`
- package: `brass_bounty_cut_boros_signet`
- add: `Brass's Bounty`
- cut: `Boros Signet`
- postgres_writes: `false`
- source_db_mutated: `false`

## Decision

Reject `Brass's Bounty` over `Boros Signet` for the current Lorehold deck.

The wider recurring-seed gate supersedes the earlier short positive signal. The
short gate only justified a larger confirmation run; it did not justify a deck
promotion.

## Evidence

The recurring window used the current recurring battle-audit seed family:
`63261404` through `63261419`, all marked as strong seeds for this confirmation.

- Baseline: `14-34`, `29.17%`.
- Candidate: `12-36`, `25.00%`.
- Delta: `-4.17pp`.
- Aggregate decision: `reject_regresses_strong_seed`.
- Strong-seed regressions: `63261404`, `63261409`, `63261419`.
- Incomplete seeds: none.
- PostgreSQL writes: none.
- Source knowledge DB mutation: none.

Seed-level regressions:

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 63261404 | 1-2 | 0-3 | -33.33 | `reject_or_rework` |
| 63261409 | 1-2 | 0-3 | -33.33 | `reject_or_rework` |
| 63261419 | 2-1 | 1-2 | -33.34 | `reject_or_rework` |

## Interpretation

`Brass's Bounty` still matches the spellchain-mana hypothesis, but the current
deck cannot spend the slower treasure burst more profitably than it uses the
early two-mana fixing from `Boros Signet` across the recurring seed window.

This is especially relevant because the deck plan depends on reaching the
commander and miracle/topdeck setup consistently. The short gate found a weak
positive signal, but the broader window showed that the swap reduces total win
rate and damages multiple strong seeds.

## Queue Impact

Do not promote `Brass's Bounty` to PostgreSQL, the live deck, or the current
Lorehold candidate list as a `Boros Signet` replacement.

Keep `Boros Signet` in place unless a future package tests a different cut or a
larger mana-engine restructure with clear same-lane compensation.

Next optimizer work should focus on either:

1. a new safe same-lane cut model for access/topdeck cards, or
2. runtime/rule work for currently blocked access pieces such as `Hidden Retreat`
   only if they become strategically relevant to the active Lorehold variants.
