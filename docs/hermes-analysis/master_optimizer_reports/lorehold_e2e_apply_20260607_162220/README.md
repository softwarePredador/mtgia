# Lorehold E2E Apply Proof — 2026-06-07 16:22 UTC

## Status

- E2E status: `ok`
- Hermes local apply: `done`
- Production/app mutation: `not done`
- Product handoff: `needs_product_owner_approval`

## Flow Executed

1. PostgreSQL metadata sync into Hermes SQLite.
2. Preflight.
3. Fresh baseline.
4. Safe slot scan with current `baseline_id`/`baseline_hash`.
5. Quality gate.
6. Confirmation.
7. Full confirmation.
8. Replay decision audit.
9. Manual-review handoff.
10. Hermes-local apply with rollback.
11. Post-apply baseline.
12. Post-apply replay audit.
13. Product handoff.

## Key Evidence

- Pre-apply baseline: `85.3%` WR, `256W/10L/34S`, 300 games.
- Pre-apply hash: `110ce10b8152085ec589ed09b15ab1e0c21a5656b60b366f59a34e369b2ff811`.
- Applied swap: `Wheel of Misfortune` over `Reforge the Soul`.
- Full confirmation for applied swap: `88.0%` WR, `+2.7pp`, `264W/7L/29S`, 300 games.
- Post-apply hash: `12c55613ae4f7bcd4c934fae4253cfa75fcc4946352a18a61365835427e90c08`.
- Post-apply baseline: `89.3%` WR, `268W/6L/26S`, 300 games.
- Post-apply replay audit: `turn_by_turn_clean`, 1303 structured events, 0 turn findings.

## Manual Review Decision

`Cloudshift` had the strongest full-confirmation delta (`+3.7pp`) but it cut
`Generous Gift`, reducing already-low interaction/removal and creating a role
mismatch risk. It was not applied.

`Wheel of Misfortune` was selected because it replaces `Reforge the Soul` in the
same draw/wheel role and reproduced a positive full-confirmation delta.

## Reports

- `card_oracle_cache_sync_e2e_20260607_162220.json`
- `master_optimizer_end_to_end_20260607_162220.log`
- `master_optimizer_preflight_20260607_162222.md`
- `master_optimizer_baseline_20260607_162224.md`
- `master_optimizer_quality_gate_20260607_162336.md`
- `master_optimizer_confirmation_20260607_162338.md`
- `master_optimizer_confirmation_20260607_162346.md`
- `master_optimizer_replay_audit_20260607_162346.md`
- `master_optimizer_handoff_20260607_162346.md`
- `master_optimizer_apply_20260607_162657.md`
- `master_optimizer_baseline_20260607_162713.md`
- `master_optimizer_replay_audit_20260607_162713.md`
- `master_optimizer_product_handoff_20260607_162713.md`

## Rollback

Rollback exists on Hermes server only:

`/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/master_optimizer_rollback_20260607T162657677855+0000.json`

The rollback JSON was intentionally not copied into the repo because it contains
the full decklist state.

## Next Gate

Do not copy this swap to product/app data until the product handoff checklist is
approved:

- confirm target product deck id and environment;
- create product deck backup;
- run product dry-run diff and Commander legality;
- run app/API smoke test;
- attach Hermes reports;
- get explicit human approval.
