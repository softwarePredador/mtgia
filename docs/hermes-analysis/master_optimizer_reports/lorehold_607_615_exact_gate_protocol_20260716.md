# Lorehold 607 vs credible field — exact-runtime gate protocol

Protocol frozen on 2026-07-16 before observing any post-PG878 battle result.
The protected incumbent is deck `607`; deck `615` is the primary challenger.
Before any post-PG878 game was run, the full 12-deck structural screen also
identified `614` as the only secondary challenger worth retaining: it ranks
third structurally and owns a historical but underpowered 4/24 versus 3/24
signal. It is therefore included in the fresh cohort so that “best” covers the
remaining credible field, not only `615`.

## Why a new gate is required

The historical v2 gate used paired seeds `2026071601`–`2026071604`, but its
runtime did not fully execute Mana Vault, Harnfel, Underworld Breach, or the
card Flashback. Those seeds are retained only as an engineering-regression
cohort. They are not the primary decision sample because runtime work was
performed after their results were inspected.

## Frozen design

- Database: a post-sync Hermes SQLite snapshot, hashed before the first game.
- Runtime/gate: copied into an immutable snapshot and hashed before the first
  game.
- Decks: normalized deck IDs `607`, `614`, and `615`; construction and identity
  must pass and the normalized lists must be hashed. The regression cohort uses
  only `607` and `615`, while the fresh decision cohort uses all three as
  predeclared below.
- Opponents: the same 12 real opponent profiles selected with opponent seed
  `2026070502`.
- Games: 8 per opponent and deck in each batch, or 96 per deck/batch.
- Pairing: identical opponent, game index, and derived game seed for both
  decks; `PYTHONHASHSEED=0`.
- Isolation: one deck process per run, 15-second per-game timeout and
  1,800-second deck-process timeout.
- Access: natural draws only; no forced opening hand, library-top, tutor, or
  focus-card injection.
- Stalls/timeouts remain in the denominator. Any seed/opponent/index mismatch
  invalidates the batch.

## Cohorts

1. Regression cohort: simulation seeds `2026071601`–`2026071604`. This measures
   direction and telemetry drift versus v2 but cannot by itself replace `607`.
2. Primary fresh cohort: simulation seeds `2026071605`–`2026071608`, with
   decks `607`, `614`, and `615`. This is the predeclared decision sample: 384
   games per deck and 384 paired outcomes for each challenger versus `607`.
3. Independent opponent confirmation is run only if a challenger passes every primary
   criterion: opponent seed `2026071602`, simulation seeds `2026071611`–
   `2026071614`, with the same 4×96 design.

There is no adaptive sample-size extension. An inconclusive primary result
keeps the protected `607` baseline and is reported as inconclusive, not as
proof that the decks are equal.

## Promotion rule

Deck `614` or `615` may replace `607` only when its fresh paired comparison
satisfies all of the following, using unrounded values:

1. aggregate win-rate delta `challenger - 607` is positive;
2. the lower bound of the paired 95% Newcombe confidence interval is strictly
   above zero;
3. exact two-sided McNemar `p <= 0.05`;
4. the challenger wins or ties at least 3 of 4 fresh batches;
5. its combined win rate against the predeclared critical profiles is not
   below `607`, and its Winota result is not below `607`;
6. no pairing mismatch or invalid construction is present;
7. natural telemetry proves the exact promoted rule lineage and executable
   events for challenger-specific cards (`615`), while `614` must pass the
   same construction/coherence and replay-validity audits; and
8. the independent opponent confirmation also passes criteria 1–7.

If every challenger fails any criterion, `607` remains the best validated Lorehold deck. This
is an incumbent-protection decision rule; it does not claim absolute
population superiority unless the interval/test evidence also supports that
claim.

The critical profile set is frozen as every selected profile whose name
contains `Winota`, `Najeela`, `Kinnan`, `Sisay`, `Grist`, or `Lumra`. This is
the same six-family definition used by the historical v2 synthesis.

## Required exact telemetry

- Mana Vault: mana activation, optional upkeep untap decision/payment, and
  tapped draw-step damage.
- Birgi/Harnfel: Birgi spell-cast mana; Harnfel discard cost, activation,
  exiled cards, and cards actually played from exile.
- Underworld Breach: three-other-card additional cost, cast through escape,
  and beginning-of-end-step sacrifice.
- Flashback: legal target selection, temporary permission, normal-cost cast,
  expiration at end of turn, and exile after the flashback spell leaves the
  stack.

Every exact event must preserve card, logical rule key, Oracle hash,
`battle_model_scope`, and `oracle_runtime_scope` in a non-truncated provenance
aggregate. Missing natural exposure makes the challenger evidence
insufficient and retains `607`.

## Structural and hybrid guardrails

The post-sync structural matrix is descriptive, not a substitute for battle
evidence. A hybrid variant is eligible only if the current safe-cut audit
identifies a seed-safe, role-preserving cut. With zero gate-ready safe cuts,
no hybrid deck is created or promoted.
