# PG236 Authority of the Consuls Progress 2026-06-26

- slice: `Authority of the Consuls`
- deploy_id: `PG236`
- scope: close one Lorehold-facing `needs_rule_before_strategy` passive family with local XMage source, runtime support, PostgreSQL promotion, Hermes sync, and post-sync audit evidence

## What Changed

- Added exact XMage -> ManaLoom mapping for `AuthorityOfTheConsuls` in
  `xmage_to_manaloom_effect_hints.py`.
- Added exact-scope batch-safe classifier support for
  `opponent_creature_enter_tapped_gain_life_v1`.
- Extended `battle_analyst_v9.py` runtime to support:
  - `opponents_creatures_enter_tapped`
  - passive trigger `creature_enters_under_opponent_control -> gain_life`
  - token entry path honoring opponent enter-tapped statics and passive ETB triggers
- Added tests for mapper, classifier, creature-entry runtime, token-entry runtime,
  and regression coverage for existing `Blind Obedience`.

## Validation

- `python3 -m unittest test_xmage_to_manaloom_effect_hints.py` -> `229/229 OK`
- `python3 -m unittest test_xmage_semantic_family_batch_pipeline.py` -> `214/214 OK`
- targeted runtime tests passed:
  - `test_authority_of_the_consuls_taps_opponent_creatures_and_gains_life`
  - `test_authority_of_the_consuls_taps_opponent_tokens_and_gains_life`
  - `test_blind_obedience_taps_opponent_artifacts_and_creatures_on_entry`

## Pipeline Delta

Pre-apply artifacts:

- proposals:
  `xmage_current_replay_batch_pipeline_20260626_pg236_authority_runtime_v1_proposals.json`
- matrix:
  `lorehold_ideal_candidate_matrix_20260626_pg236_authority_runtime_v1.json`
- effective queue:
  `xmage_effective_queue_20260626_pg236_authority_runtime_v1.json`

Observed pre-apply state:

- `Authority of the Consuls` promoted to:
  - `effect=passive`
  - `battle_model_scope=opponent_creature_enter_tapped_gain_life_v1`
  - `proposal_status=batch_pg_candidate_after_precheck`
  - `safe_for_batch_pg_package=true`
- effective queue delta:
  - `package_ready_unprepared: 1`
- matrix delta:
  - `needs_rule_before_strategy: 73`
  - `rule_status_counts.package_ready: 1`

Post-apply artifacts:

- proposals:
  `xmage_current_replay_batch_pipeline_20260626_pg236_authority_postsync_v1_proposals.json`
- matrix:
  `lorehold_ideal_candidate_matrix_20260626_pg236_authority_postsync_v1.json`
- effective queue:
  `xmage_effective_queue_20260626_pg236_authority_postsync_v1.json`
- strategy audit:
  `xmage_strategy_consistency_audit_20260626_pg236_authority_postsync_v1.json`

Observed post-apply state:

- effective queue delta:
  - `package_ready_unprepared: 0`
- matrix delta:
  - `needs_rule_before_strategy: 73`
  - `battle_ready: 322`
  - `watchlist_candidate: 126`
- strategy audit:
  - `18/18 pass`

## PostgreSQL / Sync Evidence

- package manifest:
  `pg236_authority_of_the_consuls_exact_scope_manifest.json`
- precheck:
  - `target_card_rows=1`
  - `existing_rule_rows=2`
  - `expected_rule_rows_before=0`
  - `would_deprecate_shadow_rows=2`
- apply:
  - `deprecated_shadow_rows=2`
  - `upserted_rows=1`
- postcheck:
  - `promoted_rule_rows=1`
  - `promoted_verified_auto_rows=1`
  - `promoted_oracle_hash_rows=1`
  - `backup_rows=2`
- SQLite sync report:
  `battle_card_rules_sqlite_from_pg_pg236_authority_of_the_consuls_20260626.json`
  - `pg_rows_loaded=1`
  - `sqlite_inserted_or_updated=3`

## Recommendation For Next Slice

Current highest-ROI next slice is `Magus of the Wheel`:

- current matrix score: `7.5`
- deck_ids: `[616]`
- family hint: `draw_cards`
- reason:
  - battle runtime already has `wheel_like_draw` support
  - XMage source is local and structurally simple:
    `DrawCardAllEffect(7)` + `DiscardHandAllEffect` + activated mana/tap/sac costs
  - lower implementation risk than `Penance`, `Currency Converter`, or
    `Firesong and Sunspeaker`

Avoid picking the next slice by raw score alone:

- `Currency Converter` is higher score but pulls discard-trigger exile state plus
  dual activated modes and token branching.
- `Penance` spans prevention/topdeck manipulation and is wider than it first
  appears.
- `Firesong and Sunspeaker` sits in split-scope targeted-damage work and is not
  the fastest remaining Lorehold-facing close.
