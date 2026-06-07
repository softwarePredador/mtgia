# Lorehold Reversal Revalidation - 2026-06-07 15:45 UTC

## Verdict

`Reversal of Fortune` was not applied.

The fresh revalidation did not reproduce the earlier positive result. The rollback-aware apply script correctly refused to mutate the deck.

## Runtime

- Server: `ubuntu@3.16.217.179`
- Container: `d5fe57bf9de2`
- Deck id: `6`
- Flow log: `/opt/data/artifacts/hermes_master_optimizer/lorehold_apply_reversal_validated_20260607_154522.log`
- Final status: `1`
- Reason: `No unapplied approved full_confirmation candidate found.`

## Baseline

- Baseline id: `2`
- Deck hash: `110ce10b8152085ec589ed09b15ab1e0c21a5656b60b366f59a34e369b2ff811`
- Cards: `100`
- Lands: `33`
- Average CMC: `2.91`
- Games: `300`
- Win rate: `86.7%`
- Record: `260W/11L/29S`

## Reversal Result

| Add | Cut | Scan WR | Full Confirm WR | Delta | Record | Apply |
| --- | --- | ---: | ---: | ---: | --- | --- |
| Reversal of Fortune | Past in Flames | 83.3% | 85.3% | -1.4pp | 256W/7L/37S | blocked |

## Other Rechecked Candidates

| Add | Cut | Full Confirm WR | Delta | Record | Verdict |
| --- | --- | ---: | ---: | --- | --- |
| Invoke Calamity | Past in Flames | 87.3% | +0.6pp | 262W/10L/28S | marginal |
| Restoration Seminar | Past in Flames | 87.3% | +0.6pp | 262W/6L/32S | marginal |
| Pyromancer Ascension | Past in Flames | 85.7% | -1.0pp | 257W/11L/32S | reject/retest |

## Deck State After Attempt

No apply happened:

- `Past in Flames`: present
- `Reversal of Fortune`: absent
- `Invoke Calamity`: absent
- `Restoration Seminar`: absent
- `Pyromancer Ascension`: absent
- Deck hash unchanged: `110ce10b8152085ec589ed09b15ab1e0c21a5656b60b366f59a34e369b2ff811`

## Next Action

Do not apply `Reversal of Fortune` from the current evidence.

If the team still wants to optimize the `Past in Flames` slot, run a larger confirmation batch for `Invoke Calamity` and `Restoration Seminar`, or widen the engine scan. The current gains are only `+0.6pp`, which is too thin for a confident mutation.
