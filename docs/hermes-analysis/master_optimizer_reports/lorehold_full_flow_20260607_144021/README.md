# Lorehold Full Optimizer Flow - 2026-06-07 14:40 UTC

## Verdict

The Hermes optimizer flow ran end-to-end on the real Hermes container and completed successfully.

No swap was applied automatically.

## Runtime

- Server: `ubuntu@3.16.217.179`
- Container: `d5fe57bf9de2`
- Deck id: `6`
- Flow log: `/opt/data/artifacts/hermes_master_optimizer/lorehold_full_flow_20260607_144021.log`
- Final status: `0`
- Finished at: `2026-06-07T14:41:56Z`

## Baseline

- Baseline id: `3`
- Deck hash: `110ce10b8152085ec589ed09b15ab1e0c21a5656b60b366f59a34e369b2ff811`
- Cards: `100`
- Lands: `33`
- Average CMC: `2.91`
- Games: `300`
- Win rate: `87.0%`
- Record: `261W/10L/29S`

## Slot Scan

The legacy scan was stopped because it tested off-color and stale candidates. The replacement safe scan:

- required the current deck hash to match the latest approved baseline;
- filtered `851` off-color candidates;
- filtered candidates without explicit Commander legality;
- tested `120` legal candidates;
- restored the deck after every isolated swap;
- kept the deck hash unchanged after the run.

## Confirmation

Short confirmation tested 5 candidates at 25 games per matchup.

Full confirmation retested the same 5 candidates at 50 games per matchup.

Approved for manual review:

| Add | Cut | Full Confirm WR | Delta | Record |
| --- | --- | ---: | ---: | --- |
| Fork | Past in Flames | 88.0% | +1.0pp | 264W/6L/30S |
| Harness the Storm | Past in Flames | 88.0% | +1.0pp | 264W/8L/28S |

Important: both approved candidates cut `Past in Flames`, so only one of them can be applied without another baseline/confirmation cycle.

Rejected or not enough gain:

| Add | Cut | Full Confirm WR | Delta |
| --- | --- | ---: | ---: |
| Expedition Map | Imperial Recruiter | 87.3% | +0.3pp |
| Lotus Bloom | Mana Geyser | 84.7% | -2.3pp |
| Astral Cornucopia | Mana Geyser | 84.3% | -2.7pp |

## Replay Audit

Initial replay audit found false-positive board wipe findings because the event did not report whether creatures existed before the wipe.

Fix applied:

- `battle_analyst_v8.py` now emits `creatures_seen` and `unprotected_seen` on `board_wipe_resolved`.
- `replay_decision_auditor.py` only blocks a board wipe when unprotected creatures existed and zero were destroyed.

Fresh replay audit after the fix:

- Status: `turn_by_turn_clean`
- Structured events: `1334`
- Turn findings: `0`
- Critical: `0`
- High: `0`
- Medium: `0`
- Low: `0`

## Next Action

Manual review should choose between `Fork` and `Harness the Storm`.

If one is selected, apply only with:

```bash
python3 master_optimizer_apply.py --deck-id 6 --card-added "Fork" --report
```

or:

```bash
python3 master_optimizer_apply.py --deck-id 6 --card-added "Harness the Storm" --report
```

After apply, immediately rerun:

```bash
python3 master_optimizer_baseline.py --deck-id 6 --games 50 --report
python3 replay_decision_auditor.py --deck-id 6 --report
```
