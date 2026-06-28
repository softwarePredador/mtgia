# Lorehold Mana Base Validator - 2026-06-27

- Generated at: `2026-06-28T01:06:18Z`
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
- Status counts: `{"blocked": 66, "mana_model_observed_no_auto_swap": 5, "manual_review_required": 11, "preflight_land_swap_ready": 2}`
- Ready swaps: `2`
- Recommended next action: `run_mana_base_validated_preflight`
- Recommended swap: `{"candidate": "Plateau", "cut": "Turbulent Steppe", "score": 24, "why": "preserves_R_source, preserves_W_source, improves_timing"}`

## Ready Swaps

| Score | Candidate | Cut | Deltas | Gained | Lost |
| ---: | --- | --- | --- | --- | --- |
| 24 | Plateau | Turbulent Steppe | `{"active_rule_delta": 0, "boros_source_delta": 0, "etb_score_delta": 2, "red_source_delta": 0, "white_source_delta": 0}` | - | - |
| 12 | Plateau | Sacred Foundry | `{"active_rule_delta": 0, "boros_source_delta": 0, "etb_score_delta": 1, "red_source_delta": 0, "white_source_delta": 0}` | - | spell_protection_life_cost |

## Manual Review Swaps

- `Plateau` over `Reliquary Tower`: score `43`, warnings `meaningful_utility_loss_requires_manual_package`.
- `Plateau` over `War Room`: score `43`, warnings `meaningful_utility_loss_requires_manual_package`.
- `Plateau` over `Elegant Parlor`: score `21`, warnings `meaningful_utility_loss_requires_manual_package`.
- `Plateau` over `Battlefield Forge`: score `14`, warnings `blocked_core_cut`.
- `Plateau` over `Glittering Massif`: score `6`, warnings `meaningful_utility_loss_requires_manual_package`.
- `Plateau` over `Eiganjo, Seat of the Empire`: score `3`, warnings `meaningful_utility_loss_requires_manual_package`.
- `Clifftop Retreat` over `Elegant Parlor`: score `-3`, warnings `meaningful_utility_loss_requires_manual_package`.
- `Plateau` over `Sunbaked Canyon`: score `-7`, warnings `meaningful_utility_loss_requires_manual_package`.
- `Clifftop Retreat` over `Glittering Massif`: score `-18`, warnings `meaningful_utility_loss_requires_manual_package`.
- `Boseiju, Who Shelters All` over `Reliquary Tower`: score `-46`, warnings `meaningful_utility_loss_requires_manual_package`.

## Blocked Samples

- `Plateau` over `Radiant Summit`: blockers `prior_negative_land_gate`.
- `Clifftop Retreat` over `Reliquary Tower`: blockers `would_reduce_mana_timing`.
- `Clifftop Retreat` over `War Room`: blockers `would_reduce_mana_timing`.
- `Plateau` over `Ancient Tomb`: blockers `would_cut_fast_colorless_acceleration`.
- `Plateau` over `Command Beacon`: blockers `would_cut_commander_recast_utility, would_cut_commander_recast`.
- `Plateau` over `Urza's Saga`: blockers `would_cut_saga_artifact_tutor`.
- `Clifftop Retreat` over `Sacred Foundry`: blockers `would_reduce_mana_timing`.
- `Plateau` over `Mountain // Mountain`: blockers `would_cut_basic_source_count`.
- `Plateau` over `Plains // Plains`: blockers `would_cut_basic_source_count`.
- `Clifftop Retreat` over `Battlefield Forge`: blockers `would_reduce_mana_timing`.

## Method Notes

- This validator is deterministic and read-only.
- It may override the generic land-core blocker only for strict mana-source upgrades.
- Fetch lands, Ancient Tomb acceleration, and Command Beacon commander utility remain protected cuts.
- Prior negative land gates are carried forward as blockers.
- Battle gates are reserved for packages whose advantage cannot be isolated by mana-source math.
