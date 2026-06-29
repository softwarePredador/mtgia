# XMage Acceleration E2E - 2026-06-29

Read-only E2E evidence for accelerating XMage/Oracle -> ManaLoom card-rule adaptation.
No PostgreSQL, SQLite/Hermes, deck, or runtime battle mutation was performed by this validation.

## External Source Check

- Scryfall bulk API: `https://api.scryfall.com/bulk-data`
  - Confirmed live on 2026-06-29.
  - Useful for Oracle identity, current Oracle text, rulings, legalities, layouts, and bulk hash inputs.
  - Not a battle/runtime implementation source.
- MTGJSON v5 API docs: `https://mtgjson.com/api/v5/`
  - Confirmed HTTP 200 on 2026-06-29.
  - Useful as an alternate normalized card/ruling/legalities bulk source.
  - Not a battle/runtime implementation source.
- XMage repository: `https://github.com/magefree/mage`
  - Confirmed live via GitHub API on 2026-06-29.
  - Primary rules-engine source for local implementation extraction.
- Forge repository: `https://github.com/Card-Forge/forge`
  - Confirmed live via GitHub API on 2026-06-29.
  - Secondary rules-engine/reference source to use for cross-checks when XMage mapping is ambiguous.

## Local Baseline

- Local XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- Current E2E scope: deck IDs `[6, 25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116]`
- Combined current scope: `541` cards
- Actionable audited cards: `139`
- Exact local XMage source found: `139/139`
- Focused scenario generated: `139/139`

This proves the main blocker was not missing XMage source. The blocker was mapper coverage from XMage Java signals into ManaLoom semantic/runtime families.

## Before Generic Mapper Layer

Artifacts:

- `xmage_current_replay_batch_pipeline_20260629_e2e_acceleration_manifest.json`
- `xmage_current_replay_batch_pipeline_20260629_e2e_acceleration_families.json`
- `xmage_current_replay_batch_pipeline_20260629_e2e_acceleration_proposals.json`

Result:

- Ready for structured XMage pull: `5/139`
- Mapper-required manual backlog: `134/139`
- Families detected: `5`
- Safe batch PG candidates: `0`
- Proposal status counts:
  - `mapper_metadata_or_test_scenario_required`: `134`
  - `runtime_family_implementation_required`: `1`
  - `split_family_scope_review_required`: `4`

## Implemented Change

File changed:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`

Added a conservative generic signal layer that routes clear XMage Java evidence into reviewable ManaLoom families:

- land/artifact/creature mana sources -> `ramp_permanent`
- library search -> `tutor`
- draw signals/static text -> `draw_cards` or `draw_engine`
- alternate-zone/free-cast permissions -> `free_cast` or `topdeck_play`
- mass removal/sacrifice -> `board_wipe`
- land untap -> `untap_land_engine`
- static tax/restriction -> `passive`
- targeted protection/ability grant -> `targeted_protection`
- graveyard return -> `recursion`

The layer still leaves unrecognized cards as `external_reference_required_manual_model`.
It does not mark a card executable by itself, and it does not write PostgreSQL.

## After Generic Mapper Layer

Artifacts:

- `xmage_current_replay_batch_pipeline_20260629_e2e_acceleration_after_generic_mapper_manifest.json`
- `xmage_current_replay_batch_pipeline_20260629_e2e_acceleration_after_generic_mapper_families.json`
- `xmage_current_replay_batch_pipeline_20260629_e2e_acceleration_after_generic_mapper_proposals.json`
- `xmage_current_replay_batch_pipeline_20260629_e2e_acceleration_after_generic_mapper_pattern_registry.json`

Result:

- Ready for structured XMage pull: `76/139`
- Mapper-required manual backlog: `63/139`
- Manual mapper reduction: `134 -> 63` (`71` cards moved out of pure manual review)
- Families detected: `5 -> 15`
- Safe batch PG candidates after precheck lane: `0 -> 0`
- Proposal status counts:
  - `mapper_metadata_or_test_scenario_required`: `63`
  - `runtime_family_implementation_required`: `1`
  - `split_family_scope_review_required`: `75`

The first E2E after adding generic mapping briefly exposed 7 generic `_review_v1`
scopes as batch PG candidates through already-supported family defaults. The
classifier was tightened so every generic XMage review scope is split/review
only until it has an exact family mapper and focused runtime proof.

Family spread after the change:

- `ramp_permanent`: `29`
- `tutor`: `12`
- `free_cast`: `6`
- `recursion`: `6`
- `targeted_protection`: `6`
- `passive`: `5`
- `board_wipe_choice`: `2`
- `draw_engine`: `2`
- `targeted_interaction`: `2`
- `untap_land_engine`: `2`
- plus existing smaller families: `mill_spell`, `modal_spell`, `token_maker`, `topdeck_play`

## Throughput Evidence

Artifact:

- `battle_card_adjustment_throughput_benchmark_20260629_live_e2e_acceleration.json`

Live benchmark with 12 cards:

- Scryfall collection/bulk lookup: `0.10335` seconds/card, `12/12` success
- Local Scryfall bulk-cache lookup: `0.000013` seconds/card, `12/12` success
- Named fallback calls: `0.958311` seconds/card, `3/3` success
- Local source gate audit: `0.001669` seconds/card, `8/8` success

Conclusion: Oracle identity/text can be made effectively negligible with a local bulk cache. Runtime mapping remains the real work, and the path that scales is not manual card-by-card review; it is broad XMage signal extraction into ManaLoom families plus focused runtime tests per family.

## Decision

Use this operating model going forward:

1. Scryfall/MTGJSON bulk first for identity, Oracle text, legalities, rulings, layout, and hash validation.
2. Local XMage first for battle-rule implementation signals.
3. Generic XMage mapper layer for high-volume family routing.
4. Family-specific mapper/runtime tests before PostgreSQL promotion.
5. Forge only as a second implementation reference for ambiguous or high-risk families.
6. PostgreSQL promotion only after precheck/apply/postcheck/rollback package and runtime proof.

This removes the main bottleneck proven by the E2E: exact XMage source exists for the current scoped queue, but the mapper was not extracting enough reusable structure.
