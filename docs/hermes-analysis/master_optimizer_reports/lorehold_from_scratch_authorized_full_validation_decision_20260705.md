# Lorehold From-Scratch Authorized Full Validation Decision - 2026-07-05

Status: `keep_607_protected_baseline`.

This report records the explicit operator-authorized laboratory run for
from-scratch Lorehold challengers. It does not mutate deck `607`, does not write
PostgreSQL, and does not treat laboratory materialization as promotion.

## Scope

- Source DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Protected baseline: deck `607`
- Candidate policy: isolated SQLite copies under
  `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260705_authorized_full_validation/`
- Candidate shell count: `10`
- Structure matrices run: `10/10`
- Smoke battle gates run: `10/10`
- Confirmation gates run: `3/3` for the best smoke signals
- Battle opponent setup: deck `607` as baseline, deck `607` as fixed opponent,
  plus `7` real opponent decks from the current valid-candidate pool
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Smoke Gate Summary

| Candidate | Matrix rank | Candidate score | 607 score | Candidate record | 607 record | Delta | Winota candidate | Winota 607 | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `spell_volume_access_depressure` | 1/2 | 141.721 | 139.038 | 4-3-1 | 4-4-0 | +0 | 0-1 | 1-0 | confirm only, not promote |
| `access_density_control` | 4/1 | 129.148 | 139.038 | 4-4-0 | 4-4-0 | +0 | 0-1 | 1-0 | confirm only, not promote |
| `spell_pressure_mana_conversion_deoverfill` | 1/2 | 142.003 | 139.038 | 3-5-0 | 4-4-0 | -1 | 0-1 | 1-0 | reject |
| `spell_pressure_mana_conversion` | 2/1 | 136.381 | 139.038 | 2-6-0 | 4-4-0 | -2 | 1-0 | 1-0 | reject |
| `miracle_topdeck_control` | 4/1 | 131.286 | 139.038 | 2-6-0 | 4-4-0 | -2 | 0-1 | 1-0 | reject |
| `spell_pressure_topdeck` | 2/1 | 135.803 | 139.038 | 1-7-0 | 4-4-0 | -3 | 0-1 | 1-0 | reject |
| `recursion_discard_pressure_repair` | 4/1 | 131.020 | 139.038 | 1-7-0 | 4-4-0 | -3 | 0-1 | 1-0 | reject |
| `spellchain_big_sorcery` | 4/1 | 130.875 | 139.038 | 1-7-0 | 4-4-0 | -3 | 0-1 | 1-0 | reject |
| `recursion_discard_engine` | 4/1 | 129.727 | 139.038 | 1-7-0 | 4-4-0 | -3 | 1-0 | 1-0 | reject |
| `miracle_pressure_conversion` | 2/1 | 138.514 | 139.038 | 0-8-0 | 4-4-0 | -4 | 0-1 | 1-0 | reject |

Interpretation: smoke gates found two total-win ties and no aggregate winner.
Both tied shells regressed the critical Winota pressure check.

## Confirmation Gate Summary

| Candidate | Candidate record | 607 record | Delta | Candidate vs 607 fixed | Candidate vs Winota | 607 vs Winota | Topdeck candidate/607 | Miracle candidate/607 | Spell cast candidate/607 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `spell_pressure_mana_conversion_deoverfill` | 5-19-0 | 10-14-0 | -5 | 1-2 | 0-3 | 1-2 | 54/51 | 36/63 | 527/603 |
| `spell_volume_access_depressure` | 5-19-0 | 10-14-0 | -5 | 1-2 | 0-3 | 1-2 | 47/51 | 52/63 | 592/603 |
| `access_density_control` | 4-20-0 | 10-14-0 | -6 | 2-1 | 0-3 | 1-2 | 62/51 | 33/63 | 541/603 |

Interpretation: every confirmed challenger lost clearly to protected `607`.
Every confirmed challenger also went `0-3` against Winota while baseline `607`
kept a positive pressure signal at `1-2`. Even where candidates increased
topdeck activations, they converted fewer miracle casts and fewer spell casts
than baseline `607`.

## Decision

Deck `607` remains the protected Lorehold baseline and current best shell.

No from-scratch 2026-07-05 challenger is eligible for promotion, deck mutation,
or replacement of `607`. The best structural signals are useful as learning
data, but the battle gate says they lose conversion and pressure resilience.

## Learning

- Higher structural score alone is not enough. The two rank-1 challengers failed
  confirmation after smoke review.
- Topdeck activity volume alone is not enough. `access_density_control` reached
  `62` topdeck activations versus `51` on `607`, but fell to `4/24` wins and
  `33` miracle casts versus `63` on `607`.
- The current `607` shell still converts miracle and spell-chain turns better
  under pressure than the newly generated shells.
- Future work should not make another whole-shell promotion attempt until it has
  a safer non-anchor cut model or a new commander-plan contract that preserves
  Winota/fast-pressure resilience.

## Evidence Files

- Builder summary:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260705_authorized_full_validation.json`
- Smoke summary:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_authorized_full_validation_summary_20260705.json`
- Confirmation summary:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_authorized_full_validation_confirm_summary_20260705.json`
- Battle runner summary:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260705_authorized_full_validation_battle_runner_summary.json`
- Confirmation runner summary:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_authorized_full_validation_confirm_runner_20260705.json`
