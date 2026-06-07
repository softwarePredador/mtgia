# Lorehold Stale Target Audit - 2026-06-07

## Context

These files were pulled from Hermes after a report claimed a new Lorehold baseline:

- `baseline_freeze.json`
- `phase2_confirmation.json`
- `quality_gate.md`
- `handoff_report.md`
- `slot_scan_results.json`

The handoff reported:

- baseline `86.0%` WR, `258W/10L/32S`;
- 100 cards, 32 lands, 19 ramp, 4 removal/wipe, average CMC `2.84`;
- seven confirmed swaps;
- no swaps applied because some cut targets were described as stale.

## Real SQLite State Observed

Read-only probe against the live Hermes SQLite in container `d5fe57bf9de2`:

```text
deck_id: 6
cards: 100
lands: 33
avg_cmc: 2.913
deck_hash: 110ce10b8152085ec589ed09b15ab1e0c21a5656b60b366f59a34e369b2ff811
Mana Geyser: present
Blasphemous Act: present
Storm-Kiln Artist: present
Sticky Fingers: absent
Decree of Pain: absent
Academy Manufactor: absent
Assassin's Trophy: absent
Adrix and Nev, Twincasters // Adrix and Nev, Twincasters: absent
Damning Verdict: absent
```

Important: the report and the real deck state do not fully agree. The current deck still has `Mana Geyser` and `Blasphemous Act`, so stale-target claims must be resolved by deck hash and a fresh baseline, not by trusting a text report.

## Critical Quality Findings

The pulled handoff is diagnostic only and is not safe for apply:

- `Decree of Pain` is outside Lorehold RW color identity.
- `Assassin's Trophy` is outside Lorehold RW color identity.
- `Adrix and Nev, Twincasters` is outside Lorehold RW color identity.
- The reported deck had only 4 removal/wipe cards.
- The reported deck had 14 Game Changers and bracket 4 pressure.
- The report references `replay-v4.py`, which is not the versioned replay audit path.

## Hardening Applied

The master optimizer scripts now guard against this class of failure:

- `swap_benchmarks` is created by `ensure_optimizer_tables()`.
- `candidate_rows()` accepts current `slot_benchmarks` phases `best-in-slot` and `phase1`.
- `quality_gate`, `confirmation`, `handoff`, and `apply` require the current deck hash to match the latest approved baseline hash.
- `temporary_swap()` hard-fails when the cut target is missing or the add target is already present.
- `master_optimizer_apply.py` refuses to apply unless the current deck still matches the approved baseline.

## Smoke Test Evidence

Executed inside Hermes container against a temporary SQLite copy only:

```text
baseline: 83.3% WR, 5W/0L/1S, 6 games
quality gate: reviewed 3 candidates
confirmation: tested 1 candidate, blocked 1 off-color candidate
mutation test: deleted Mana Geyser from temp DB
handoff result: blocked because current deck hash did not match latest approved baseline
status: GUARDRAIL_SMOKE_OK
```

This proves the new guardrail catches stale deck state before handoff/apply.

## Verdict

Do not apply the pulled `86.0%` report as-is. It is useful as an incident report, but the next valid optimizer run must be:

1. re-freeze the exact current deck;
2. run slot scan from that hash;
3. run quality gate;
4. run confirmation;
5. generate handoff;
6. only then consider apply with rollback.
