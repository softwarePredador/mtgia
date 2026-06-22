# Lorehold Deck 6 PG-020 Failure Analysis

- status: ready
- source run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_022700/summary.json`
- deck source in replay: `sqlite_deck_cards:deck_id:6`, synced from PostgreSQL
  deck `528c877f-f829-4207-95e6-73981776c323`
- current canonical swap: `Windborn Muse` over `Guttersnipe`

Result:

- Baseline before swap: `2/64 = 3.125%`
- Post-PG-020 result: `4/64 = 6.25%`
- Status: `trusted_for_strategy_learning`
- Mandatory divergences: `[]`
- Forensic rule findings: `0`
- Tests: `18/18`

What improved:

- `Windborn Muse` produced a real measured improvement over `Guttersnipe` on
  the same 64-seed window.
- The improvement survived permanent Hermes apply, PostgreSQL promotion,
  PG -> Hermes sync, and post-sync 64-seed replay.

What still fails:

- Lorehold still loses `60/64`.
- Opponent combat pressure remains concentrated on Lorehold:
  `912` events toward Lorehold versus `12` toward other players.
- Strategy audit reports `15` low-confidence
  `forced_keep_after_bad_mulligan` findings.
- The deck casts defensive cards in the sample, but the package is not enough
  to survive table focus:
  `Crawlspace=18`, `Windborn Muse=12`, `Ghostly Prison=10`,
  `Teferi's Protection=5` observed casts in the 64-seed post-apply analysis.

One battle log proving the pattern:

- Seed `63212310`:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_020729/seed_63212310/replay.txt`
- Lorehold cast commander on turn 3, attacked and became table focus.
- Opponents repeatedly attacked Lorehold from turn 3 onward.
- Lorehold reached turn 10 at `Life=1`, `Hand=0`; Kraum attacked for lethal and
  Lorehold died at `Life=-1`.

Next hypothesis:

- Test stronger early-survival and keep-stability swaps, one at a time.
- Prioritize cuts from low-impact payoff/value slots over core protection,
  draw, ramp, or commander combo pieces.
