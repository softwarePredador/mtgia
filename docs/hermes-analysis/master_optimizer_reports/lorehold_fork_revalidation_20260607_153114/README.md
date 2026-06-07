# Lorehold Fork Revalidation - 2026-06-07 15:31 UTC

## Verdict

`Fork` was not applied.

The rollback-aware apply script refused the swap because the revalidated full confirmation did not meet the minimum safe delta.

## Runtime

- Server: `ubuntu@3.16.217.179`
- Container: `d5fe57bf9de2`
- Deck id: `6`
- Flow log: `/opt/data/artifacts/hermes_master_optimizer/lorehold_apply_fork_revalidated_20260607_153114.log`
- Final status: `1`
- Reason: `No unapplied approved full_confirmation candidate found.`

## Current Baseline Before Fork

- Baseline id: `1`
- Deck hash: `110ce10b8152085ec589ed09b15ab1e0c21a5656b60b366f59a34e369b2ff811`
- Cards: `100`
- Lands: `33`
- Average CMC: `2.91`
- Games: `300`
- Win rate: `86.7%`
- Record: `260W/6L/34S`

## Fork Result

| Add | Cut | Full Confirm WR | Delta | Record | Apply |
| --- | --- | ---: | ---: | --- | --- |
| Fork | Past in Flames | 86.7% | +0.0pp | 260W/9L/31S | blocked |

`Fork` is safe/legal, but it was not better than the baseline in this fresh run.

## Better Current Candidates

Additional full confirmation found stronger options over the same cut target:

| Add | Cut | Full Confirm WR | Delta | Record | Verdict |
| --- | --- | ---: | ---: | --- | --- |
| Reversal of Fortune | Past in Flames | 90.7% | +4.0pp | 272W/4L/24S | best current candidate |
| Flare of Duplication | Past in Flames | 89.0% | +2.3pp | 267W/5L/28S | playable candidate |
| Underworld Breach | Past in Flames | 86.3% | -0.4pp | 259W/7L/34S | reject/retest |

## Deck State After Attempt

No apply happened:

- `Fork`: absent
- `Past in Flames`: present
- `Harness the Storm`: absent
- Deck hash unchanged: `110ce10b8152085ec589ed09b15ab1e0c21a5656b60b366f59a34e369b2ff811`

## Next Action

If the deck owner approves the better result, apply:

```bash
python3 master_optimizer_apply.py --deck-id 6 --card-added "Reversal of Fortune" --report
```

Then immediately rerun:

```bash
python3 master_optimizer_baseline.py --deck-id 6 --games 50 --report
python3 replay_decision_auditor.py --deck-id 6 --report
```
