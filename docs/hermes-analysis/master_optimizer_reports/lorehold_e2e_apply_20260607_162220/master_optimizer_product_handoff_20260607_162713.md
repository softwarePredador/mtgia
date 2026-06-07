# Hermes Product Apply Handoff

- status: needs_product_owner_approval
- deck_id: 6
- current_hermes_hash: `12c55613ae4f7bcd4c934fae4253cfa75fcc4946352a18a61365835427e90c08`
- current_cards: 100
- current_lands: 33
- current_avg_cmc: 2.91
- latest_baseline_id: 4
- applied_swap_id: 1
- swap: `Wheel of Misfortune` over `Reforge the Soul`
- hermes_before_hash: `110ce10b8152085ec589ed09b15ab1e0c21a5656b60b366f59a34e369b2ff811`
- hermes_after_hash: `12c55613ae4f7bcd4c934fae4253cfa75fcc4946352a18a61365835427e90c08`
- hermes_rollback: `/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/master_optimizer_rollback_20260607T162657677855+0000.json`
- full_confirmation_wr: 88.0%
- full_confirmation_delta_pp: 2.700000000000003
- full_confirmation_record: 264W/7L/29S

## Product Gate

- This handoff does not mutate production.
- Product-facing mutation remains blocked until explicit approval.
- The Hermes rollback file is not enough for production rollback; create a product backup first.

## Required Checks

- [ ] Confirm target product deck id and environment.
- [ ] Create product deck backup before mutation.
- [ ] Run product dry-run diff and verify 100-card Commander legality.
- [ ] Run app/API smoke test after mutation.
- [ ] Attach Hermes confirmation and post-apply baseline reports.
- [ ] Get explicit human approval before production-facing apply.

## Apply Instruction After Approval

Only after all checks are approved, copy this exact swap to the target product deck:

- add: `Wheel of Misfortune`
- remove: `Reforge the Soul`

Do not run generic optimizer auto-apply against product data.
