# Lorehold Access And Brass Decision 2026-06-28

- access_cut_model: `docs/hermes-analysis/master_optimizer_reports/lorehold_access_cut_model_20260628_v1.md`
- brass_confirm_matrix: `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_confirm_matrix_20260628_v1_run.md`
- seed_matrix_basis: `docs/hermes-analysis/master_optimizer_reports/lorehold_seed_matrix_all_20260628_v1_run.md`
- postgres_writes: `false`
- source_db_mutated: `false`
- superseded_by: `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_recurring_seed_window_decision_20260628_v1.md`

## Supersession Note

The `Brass's Bounty` recommendation below is superseded by the later recurring
seed window gate. The later gate tested seeds `63261404` through `63261419` and
rejected `Brass's Bounty` over `Boros Signet`: baseline `14-34`, candidate
`12-36`, `-4.17pp`, decision `reject_regresses_strong_seed`.

Keep this file as the evidence chain for why the larger gate was run, not as a
current deck-promotion recommendation.

## Access/Topdeck Decision

Do not run a new access/topdeck swap yet.

The access cut model evaluated `470` candidate/cut pairs across `Brainstone`,
`Penance`, `Enlightened Tutor`, `Gamble`, and `Hidden Retreat`.

- `0` pairs are preflight-ready.
- `340` pairs are blocked by cut-safety, prior evidence, repeated seed-matrix
  rejects, protected engine cards, protection shell cards, lands, or
  miracle-core big spells.
- `94` pairs are blocked because `Hidden Retreat` has no executable local
  runtime rule yet.
- `36` pairs remain manual review only, mostly cross-lane cuts such as access
  cards over removal/draw-value slots.

Current access candidates:

- `Brainstone`: executable, but its active scope still carries an `unexecuted`
  warning and no safe cut exists.
- `Penance`: executable and appears in Lorehold variants `609`, `611`, `613`,
  and `614`, but the tested `Promise of Loyalty` cut regressed the matrix.
- `Enlightened Tutor`: executable and appears in variants `608`, `611`, `612`,
  `613`, `614`, and `615`, but current safe cuts are cross-lane only.
- `Gamble`: executable and appears in variants `609`, `612`, `613`, `614`, and
  `615`, but current safe cuts are cross-lane only.
- `Hidden Retreat`: blocked because local rules are `review_only`, not
  executable.

## Brass's Bounty Decision

Promote `Brass's Bounty` over `Boros Signet` to a deeper confirmation gate, but
do not apply it to the deck yet.

Evidence:

- Original matrix: `4-5` candidate versus `4-5` baseline, no seed-42
  regression.
- Confirm matrix with `3` games per opponent over seeds `7`, `20260625`, and
  `42`: candidate `6-21` versus baseline `5-22`, `+3.70pp`.
- Seed `42` was preserved: candidate `5-4` versus baseline `5-4`.
- Seed `20260625` improved from baseline `0-9` to candidate `1-8`.
- Seed `7` remained unresolved at `0-9` versus `0-9`.

This is a small positive signal, not a final deck change. The next gate should
use a wider seed set or more opponents before any PostgreSQL/deck promotion.

## Next Action

1. Do not apply access/topdeck swaps until a new safe same-lane cut exists or
   `Hidden Retreat`/Brainstone runtime quality is improved.
2. Run a wider `Brass's Bounty` confirmation gate.
3. If the wider gate preserves the strong seed and improves weak seeds, prepare
   a deck-promotion package for explicit review before PostgreSQL write.
