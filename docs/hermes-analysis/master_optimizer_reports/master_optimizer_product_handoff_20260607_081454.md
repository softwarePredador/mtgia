# Hermes Product Apply Handoff

- status: needs_product_owner_approval
- deck_id: 6
- current_hermes_hash: `4af984e0cea47c781321a9fe4e99f579d02f70dd2a5f8c980c94463abd5563ee`
- current_cards: 100
- current_lands: 35
- current_avg_cmc: 2.5
- latest_baseline_id: 3
- applied_swap_id: 1
- swap: `Sticky Fingers` over `Storm-Kiln Artist`
- hermes_before_hash: `a5adcf8e0bb65cb293ff375320ff41b3c3a6162e60498effdc1be1b0d6f8a84e`
- hermes_after_hash: `4af984e0cea47c781321a9fe4e99f579d02f70dd2a5f8c980c94463abd5563ee`
- hermes_rollback: `/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/master_optimizer_rollback_20260607T041841557329+0000.json`
- full_confirmation_wr: 55.8%
- full_confirmation_delta_pp: 10.799999999999997
- full_confirmation_record: 67W/53L/0S

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

- add: `Sticky Fingers`
- remove: `Storm-Kiln Artist`

Do not run generic optimizer auto-apply against product data.
