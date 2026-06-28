# Lorehold Mana Base Validator - 2026-06-27

- Generated at: `2026-06-28T01:08:38Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- Miner report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_gap_miner_20260627_v3_post_austere_tradeoff.json`
- Deck ID: `6`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Candidates: `3`
- Deck lands: `34` total, `28` unique
- Source counts: `{"always_or_conditionally_tapped": 4, "colorless_sources": 7, "lands": 34, "red_sources": 21, "white_sources": 22}`
- Evaluations: `84`
- Status counts: `{"blocked": 78, "mana_model_observed_no_auto_swap": 2, "manual_review_required": 4}`
- Ready swaps: `0`
- Recommended next action: `batch_xmage_runtime_rule_gaps`
- Recommended swap: `{}`

## Ready Swaps

| Score | Candidate | Cut | Deltas | Gained | Lost |
| ---: | --- | --- | --- | --- | --- |
|  | none | none |  |  |  |

## Manual Review Swaps

- `Clifftop Retreat` over `Elegant Parlor`: score `-3`, warnings `meaningful_utility_loss_requires_manual_package`.
- `Clifftop Retreat` over `Glittering Massif`: score `-18`, warnings `meaningful_utility_loss_requires_manual_package`.
- `Boseiju, Who Shelters All` over `Reliquary Tower`: score `-46`, warnings `meaningful_utility_loss_requires_manual_package`.
- `Boseiju, Who Shelters All` over `War Room`: score `-46`, warnings `meaningful_utility_loss_requires_manual_package`.

## Blocked Samples

- `Plateau` over `Reliquary Tower`: blockers `candidate_has_multiple_prior_negative_land_gates`.
- `Plateau` over `War Room`: blockers `candidate_has_multiple_prior_negative_land_gates`.
- `Plateau` over `Radiant Summit`: blockers `prior_negative_land_gate`.
- `Plateau` over `Turbulent Steppe`: blockers `prior_negative_land_gate`.
- `Plateau` over `Elegant Parlor`: blockers `candidate_has_multiple_prior_negative_land_gates`.
- `Plateau` over `Battlefield Forge`: blockers `candidate_has_multiple_prior_negative_land_gates`.
- `Plateau` over `Sacred Foundry`: blockers `candidate_has_multiple_prior_negative_land_gates`.
- `Clifftop Retreat` over `Reliquary Tower`: blockers `would_reduce_mana_timing`.
- `Clifftop Retreat` over `War Room`: blockers `would_reduce_mana_timing`.
- `Plateau` over `Ancient Tomb`: blockers `candidate_has_multiple_prior_negative_land_gates, would_cut_fast_colorless_acceleration`.

## Method Notes

- This validator is deterministic and read-only.
- It may override the generic land-core blocker only for strict mana-source upgrades.
- Fetch lands, Ancient Tomb acceleration, and Command Beacon commander utility remain protected cuts.
- Prior negative land gates are carried forward as blockers.
- Battle gates are reserved for packages whose advantage cannot be isolated by mana-source math.
