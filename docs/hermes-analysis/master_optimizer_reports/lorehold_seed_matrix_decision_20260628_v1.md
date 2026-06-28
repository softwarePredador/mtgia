# Lorehold Seed Matrix Decision 2026-06-28

- source_db: `docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- aggregate_report: `docs/hermes-analysis/master_optimizer_reports/lorehold_seed_matrix_all_20260628_v1_run.md`
- runner: `docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_seed_matrix.py`
- seeds: `7, 20260625, 42`
- strong_seed_guard: `42`
- games_per_opponent: `1`
- opponent_limit: `3`
- postgres_writes: `false`
- source_db_mutated: `false`

## Decision

Do not promote a deck swap from this matrix.

The matrix executed every package that passed cut-safety and prior-evidence
preflight. Result counts:

- `25` packages ran through the seed matrix.
- `37` packages were skipped by cut-safety.
- `8` packages were skipped because prior exact evidence already rejected them.
- `0` packages qualified for promotion.
- `1` package tied without strong-seed regression: `brass_bounty_cut_boros_signet`.
- `23` packages regressed the strong seed and are rejected for now.
- `1` package lost aggregate without strong-seed regression: `pg245_twinflame_damage_payoff_cut_thor`.

## Key Findings

- `Penance` over `Promise of Loyalty` is not promotable. It improved some
  Squee/topdeck signals in seed `20260625`, but the aggregate record dropped to
  `2-7` versus baseline `4-5` and it regressed seed `42`.
- `Birgi` is still not proven for this shell. The safe-cut attempt over
  `Jeska's Will` fell to `0-9`; the earlier cuts over `Hexing Squelcher` or
  `Bender's Waterskin` remain blocked by cut-safety.
- `Lapse of Certainty` over `Tibalt's Trickery` improved aggregate record to
  `5-4`, but still regressed the strong seed. It cannot be promoted without a
  better same-lane protection model.
- `Brass's Bounty` over `Boros Signet` is the only non-regressing tie. It
  finished `4-5` against the same `4-5` baseline and preserved seed `42`, so it
  is a watch-list candidate for a larger confirm gate, not a deck change.
- The current blocker is not a lack of ideas; it is cut safety. The cards that
  would improve access or spell velocity often need cuts from protected engine,
  ramp, protection, or finisher slots.

## Next Action

The next effective step is not to swap the deck. It is to generate a new
same-lane cut model for the access problem:

1. Preserve the known engine: `Squee, Goblin Nabob`, `Sensei's Divining Top`,
   `Scroll Rack`, `Library of Leng`, `Urza's Saga`, `Land Tax`, medallions,
   `Bender's Waterskin`, `Hexing Squelcher`, and the seed-42 protection shell.
2. Find cuts that are not already locked by the cut-safety manifest and that
   share the role being tested.
3. Only then re-run access packages such as `Brainstone`, `Penance`,
   `Enlightened Tutor`, `Gamble`, or `Hidden Retreat`.
4. Treat `Hidden Retreat` as runtime-blocked until its rule is upgraded from
   `review_only` to executable `auto`.
