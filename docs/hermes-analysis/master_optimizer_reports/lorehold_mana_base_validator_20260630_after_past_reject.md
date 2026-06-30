# Lorehold Mana Base Validator - 2026-06-27

- Generated at: `2026-06-30T04:19:03Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Miner report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_gap_miner_20260627_v3_post_austere_tradeoff.json`
- Deck ID: `6`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Candidates: `3`
- Deck lands: `33` total, `33` unique
- Source counts: `{"always_or_conditionally_tapped": 4, "colorless_sources": 8, "lands": 33, "red_sources": 23, "white_sources": 23}`
- Evaluations: `97`
- Status counts: `{"blocked": 89, "mana_model_observed_no_auto_swap": 6, "manual_review_required": 2}`
- Ready swaps: `0`
- Recommended next action: `batch_xmage_runtime_rule_gaps`
- Recommended swap: `{}`

## Ready Swaps

| Score | Candidate | Cut | Deltas | Gained | Lost |
| ---: | --- | --- | --- | --- | --- |
|  | none | none |  |  |  |

## Manual Review Swaps

- `Clifftop Retreat` over `Elegant Parlor`: score `-3`, warnings `meaningful_utility_loss_requires_manual_package`.
- `Boseiju, Who Shelters All` over `War Room`: score `-46`, warnings `meaningful_utility_loss_requires_manual_package`.

## Blocked Samples

- `Plateau` over `City of Brass`: blockers `candidate_has_multiple_prior_negative_land_gates`.
- `Plateau` over `Gemstone Caverns`: blockers `candidate_has_multiple_prior_negative_land_gates`.
- `Plateau` over `Inventors' Fair`: blockers `candidate_has_multiple_prior_negative_land_gates`.
- `Plateau` over `Mana Confluence`: blockers `candidate_has_multiple_prior_negative_land_gates`.
- `Plateau` over `War Room`: blockers `candidate_has_multiple_prior_negative_land_gates`.
- `Plateau` over `Ancient Den`: blockers `candidate_has_multiple_prior_negative_land_gates`.
- `Plateau` over `Great Furnace`: blockers `candidate_has_multiple_prior_negative_land_gates`.
- `Plateau` over `Hall of Heliod's Generosity`: blockers `candidate_has_multiple_prior_negative_land_gates`.
- `Plateau` over `Needleverge Pathway // Pillarverge Pathway`: blockers `candidate_has_multiple_prior_negative_land_gates`.
- `Clifftop Retreat` over `City of Brass`: blockers `would_reduce_mana_timing`.

## Method Notes

- This validator is deterministic and read-only.
- It may override the generic land-core blocker only for strict mana-source upgrades.
- Fetch lands, Ancient Tomb acceleration, and Command Beacon commander utility remain protected cuts.
- Prior negative land gates are carried forward as blockers.
- Battle gates are reserved for packages whose advantage cannot be isolated by mana-source math.
