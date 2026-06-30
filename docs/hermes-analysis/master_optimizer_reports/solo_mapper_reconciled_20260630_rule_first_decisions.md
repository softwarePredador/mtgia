# Solo Mapper Reconciled Rule-First Decisions

- Generated at: `2026-06-30T14:31:00Z`
- Branch: `codex/solo-consolidation-20260630`
- PostgreSQL writes: `false`
- Deck mutations: `false`

## Mapper Reconciliation

Applied manually, not by merging Agent 2 raw diff:

1. Added a reusable guardrail so generic `xmage_*_review_v1` scopes stay review-only and cannot become batch package candidates through stale metadata.
2. Added exact mapper scope only for `Deathbellow War Cry`, because local XMage has a compact deterministic pattern:
   `SearchLibraryPutInPlayEffect(new TargetCardWithDifferentNameInLibrary(0, 4, minotaurFilter))`.
3. Left `Blood Moon`, `Chandra's Ignition`, `Karn's Sylex`, `Karn, the Great Creator`, `Charmbreaker Devils`, `Naktamun Lorespinner // Wheel of Fortune`, and `Ancient Gold Dragon` out of mapper promotion because each still requires runtime split, package hash, or broader model work.

## Five Rule-First Cards

| Card | Decision | Reason | Next action |
| --- | --- | --- | --- |
| `Deathbellow War Cry` | closed at mapper level | XMage exact tutor-to-battlefield Minotaur pattern now maps to `up_to_four_different_name_minotaur_creatures_to_battlefield_v1`. | Get Oracle hash/precheck before any PG package; no deck benchmark until rule package is durable or explicitly accepted as review. |
| `Charmbreaker Devils` | deferred | XMage combines random upkeep recursion plus temporary pump on instant/sorcery casts. This needs a focused random-selection/upkeep/pump runtime model. | Defer unless variants make it a strategic priority. |
| `Naktamun Lorespinner // Wheel of Fortune` | deferred | XMage combines prepare condition with a Wheel of Fortune spell face; this is not just generic draw. | Defer until prepare/MDFC/wheel scope is modeled. |
| `Karn's Sylex` | deferred | XMage combines enters tapped, static pay-life/sacrifice restriction, and X-cost activated board wipe. | Defer unless Karn/Sylex package becomes strategically relevant. |
| `Karn, the Great Creator` | deferred | XMage combines artifact activation lock, loyalty animation, and wish/exile access. | Defer unless artifact-lock/wish package becomes strategically relevant. |

## Current Queue Effect

- Before mapper reconciliation: `8` remaining split-scope runtime gaps.
- After mapper reconciliation: `1` `batch_metadata_candidate_requires_pg_precheck`, `7` remaining split-scope runtime gaps.
- Correct proposal artifact: `solo_mapper_reconciled_20260630_effect_json_batch_proposals_from_queue`.
- The first attempted proposal run against the family sidecar was discarded because it used the wrong input shape and reported `manual_model_required`; it was not retained.

## Validation

| Command | Status | Result |
| --- | --- | --- |
| `python3 -m unittest test_xmage_to_manaloom_effect_hints.py` | pass | `273 tests OK` |
| `python3 -m unittest test_xmage_semantic_family_batch_pipeline.py test_xmage_batch_validity_audit.py test_xmage_batch_pg_package_builder.py` | pass | `258 tests OK` |
