# Lorehold Deck 6 PG-022 Silent Arbiter Validation

Generated: 2026-06-21 04:47 UTC

## Applied Changes

- PG-021 corrected global attack-rule scope for `Silent Arbiter`,
  `Magus of the Moat`, and `Ensnaring Bridge`.
- PG-022 swapped `Silent Arbiter` into the PostgreSQL Lorehold runtime deck over
  `Monument to Endurance`.
- PostgreSQL deck `528c877f-f829-4207-95e6-73981776c323` was synced into
  Hermes SQLite deck `6`.

## Canonical Deck State After Sync

- `Silent Arbiter=1`
- `Monument to Endurance=0`
- `Windborn Muse=1`
- `Guttersnipe=0`
- Deck size: `100/100`
- Sync report:
  `docs/hermes-analysis/master_optimizer_reports/sync_pg_target_deck_to_hermes_pg022_silent_arbiter_20260621_044155.json`

## Battle Evidence

| State | Artifact | Wins | Status | Pressure to Lorehold |
| --- | --- | ---: | --- | ---: |
| Baseline PG-020 with corrected PG-021 rules | `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_041725/summary.json` | `4/64` | `trusted_for_strategy_learning` | `912` |
| Candidate Silent Arbiter over Monument | `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_032623/summary.json` | `8/64` | `trusted_for_strategy_learning` | `1103` |
| PG-022 post-sync smoke | `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044419/summary.json` | `3/16` | `trusted_for_strategy_learning` | `274` |
| PG-022 post-sync full | `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044758/summary.json` | `8/64` | `trusted_for_strategy_learning` | `1103` |

## Seed Delta Versus Baseline

- New wins: `63212318`, `63212320`, `63212343`, `63212357`,
  `63212358`, `63212360`.
- Lost baseline wins: `63212316`, `63212344`.
- Shared wins: `63212323`, `63212339`.
- Net delta: `+4` Lorehold wins over 64 seeds.

## Interpretation

PG-022 is a real improvement in the current battle harness:

- Winrate moved from `4/64 = 6.25%` to `8/64 = 12.5%`.
- Gates are clean after PostgreSQL apply and PG -> Hermes sync.
- Pressure total increased, but average final turn also increased
  (`8.81` baseline to `10.11` Silent candidate), and pressure per turn stayed
  close (`1.62` baseline to `1.70` Silent candidate).

This does not make Lorehold solved. The remaining repeated blocker is
consistency: the full post-sync run still reports
`forced_keep_after_bad_mulligan=15`.
