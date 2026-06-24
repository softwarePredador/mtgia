# XMage Absorption Workflow V2

## Objective

Reduce the current XMage -> ManaLoom absorption cycle time by changing the
method:

- replay/deck evidence defines priority;
- XMage effect/test structure defines the model;
- PostgreSQL package generation happens in batches;
- battle runtime changes are opened only when the queue proves they are the
  best next move.

This replaces the slower loop where the same cards keep being rediscovered and
re-explained by deck/replay context.

## What this workflow is not

- Do not port XMage wholesale.
- Do not use replay appearance as the main modeling method.
- Do not open manual card-by-card review while package-ready or reusable
  family-level work still exists.
- Do not let fragmented high-volume families lead the queue just because they
  are large in raw count.

## Evidence base

Current local XMage inventory already shows the right direction:

- `31706` card implementation files;
- `802` effect files;
- `84` target files;
- `207` filter files;
- `87` watcher files;
- `2009` test files.

The inventory recommendation is clear:

1. keep XMage as a reference corpus, not a direct engine port;
2. promote effect-class taxonomy before more card-by-card work;
3. mine XMage tests into focused ManaLoom scenarios;
4. use priority/stack/event taxonomy as conformance reference;
5. use target/filter classes to harden `effect_json` constraints.

Reference artifacts:

- `docs/hermes-analysis/master_optimizer_reports/xmage_engine_absorption_inventory_20260623.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260624_expanded_608_619_real_v2.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_acceleration_strategy_benchmark_20260624_expanded_608_619_real_v1.md`

## Strategy benchmark decision

The acceleration strategy must be chosen from measured queue evidence, not from
raw intuition. Current benchmark result:

- recommended strategy: `hybrid_effective_queue_pattern_registry`;
- decision score: `80.1`;
- immediate cards: `77`;
- cards per work unit: `19.25`.

Rejected as primary paths:

- `full_xmage_first`: touches `31706` card implementation files before first
  queue closure, with `0.016` current queue cards per work unit;
- `card_by_card_queue`: handles the queue eventually, but only `1.0` card per
  work unit and low reuse;
- `pattern_registry_first`: high long-term reuse, but too much upfront work if
  it blocks the active deck queue;
- `test_miner_first`: useful as an evidence gate, but sparse in the current
  targeted-damage pilot.

Adopted path:

1. remove prepared packages from the modeling queue;
2. apply packages only through PostgreSQL governance gates;
3. reduce the largest exact split-scope clusters;
4. open runtime only for homogeneous exact scopes with focused tests;
5. persist patterns as reviewable registry/templates in parallel, never as
   executable truth without local tests and `card_battle_rules` promotion.

Implemented registry artifact:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_pattern_registry_builder.py`
- output suffix from the pipeline: `_pattern_registry.json` and
  `_pattern_registry.md`
- standalone schema proposal suffix: `_schema_proposal.sql`

Registry rows are always `promotion_status=shadow_only` in this lane. They may
guide batching, subpattern splitting, test generation, and package planning; they
must not execute in battle and must not be consumed by deck-card queries until a
separate PostgreSQL migration/package is explicitly approved.

Implemented pipeline manifest contract:

- `aggregate_scope.artifact_deck_ids` records decks found in replay provenance;
- `aggregate_scope.learned_deck_ids` records replay learned-deck opponents;
- `aggregate_scope.forced_include_deck_ids` records manually included deck ids
  such as Lorehold variants `608` through `616`;
- `aggregate_scope.effective_deck_ids` is the authoritative scope used by the
  coherence/index/validity/family/proposal/registry reports.

## Operating model

### Lane 0: package already prepared

If a current proposal card is already covered by a `pg*_manifest.json`, it is
no longer a modeling task. It is an operational/package governance task.

Rule:

- never rebuild a package for these cards unless the existing package is proven
  wrong or obsolete.

### Lane 1: package ready, not yet prepared

If a proposal is already in `batch_pg_candidate_after_precheck` and is not
covered by an existing package manifest, package it immediately.

Rule:

- no new runtime work while this lane is non-empty, unless there is an explicit
  blocking reason.

### Lane 2: split-scope backlog

These cards are partially supported. The right move is not "review one card",
but "batch the largest exact scope cluster".

Rule:

- pick the biggest exact `battle_model_scope` cluster first;
- turn that cluster into exact mappings/tests/package;
- then rerun the effective queue.

### Lane 3: runtime family backlog

These cards need new executor support. The right move is not the biggest raw
family, but the most reusable exact-scope cluster.

Rule:

- prefer homogeneous exact-scope groups over fragmented families;
- do not start a fragmented `20 cards / 20 scopes` family before taxonomy/test
  miner support exists;
- every new runtime scope must land with focused runtime tests.

### Lane 4: manual mapper backlog

This lane stays last. It should not define architecture.

Rule:

- only enter this lane after higher-leverage lanes shrink.

### Lane 5: missing XMage source

Keep this isolated as an exception lane.

Rule:

- do not let missing-local-source cards contaminate the main throughput queue.

## Hard rules for every cycle

1. Regenerate the effective queue after each meaningful package/runtime wave.
2. Regenerate the acceleration strategy benchmark when the queue materially
   changes or a new strategy is proposed.
3. Use XMage taxonomy/tests before opening a new executor family.
4. New runtime work must come with:
   - exact `battle_model_scope`;
   - focused test coverage;
   - report delta showing queue reduction.
5. Replay/deck artifacts prioritize the queue, but do not define the ontology.
6. PostgreSQL remains the source of truth for promoted battle rules; Hermes is
   sync/cache evidence only.
7. Pattern registries and XMage observations are advisory until promoted through
   reviewed/tested `card_battle_rules`.

## Current effective queue

Current queue from
`xmage_current_replay_batch_pipeline_20260624_mapper_runtime_batch_v2_proposals.json`
after applying PG184 and syncing the selected rules PG -> Hermes:

- `package_already_prepared=2`
- `package_ready_unprepared=0`
- `split_scope_backlog=81`
- `runtime_family_backlog=24`
- `manual_mapper_backlog=337`
- `blocked_missing_xmage_source=2`

## Current execution order

1. The original prepared package lane was closed for this scope. PG166-PG181 applied
   `54` rule upserts, deprecated `80` stale shadow rows, and PG -> Hermes sync
   refreshed `5356` SQLite rows from `5500` PG rows.
2. PG182 and PG183 were targeted provenance repairs discovered by runtime
   validation after sync:
   - PG182 restored `Seething Song` `oracle_hash`;
   - PG183 restored `Angel's Grace` `oracle_hash`;
   - the latest PG -> Hermes sync refreshed `5328` SQLite rows from `5500`
     PG rows and exported `3243` canonical snapshot rows.
3. The latest strategy consistency audit
   `xmage_strategy_consistency_audit_20260624_pg166_183_postsync_real_v1_default.json`
   passed `17/17`.
4. Battle audit
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_154831`
   completed `16/16` seeds and `18/18` internal tests, but the final replay
   status remains `blocked` by mandatory review gates:
   `decision_trace_taxonomy`, `event_contract_static`, `forensic_audit`,
   `replay_decision_audit`, and `strategy_audit`.
5. PG184 then closed the mapper/runtime batch package-ready lane for
   `Brain Freeze` and `Cabal Ritual`:
   - before PG184: `package_ready_unprepared=2`,
     `manual_mapper_backlog=337`;
   - after PG184: `package_ready_unprepared=0`,
     `package_already_prepared=2`;
   - focused runtime/audit evidence:
     `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_193554`.
6. For deckbuilding, use
   `LOREHOLD_IDEAL_DECK_WORKFLOW_2026-06-24.md` and
   `lorehold_ideal_deck_candidate_matrix.py` before proposing any Lorehold
   swap. Current matrix result: `395` Lorehold-touching cards, `127`
   rule-first cards, `35` priority benchmark candidates.
7. Hit the largest split-scope clusters in order:
   - `targeted_damage_variant_v1` (`21`)
   - `source_controller_draw_variant_v1` (`17`)
   - `source_add_counters_variant_v1` (`11`)
   - `targeted_destroy_variant_v1` (`10`)
8. For `targeted_damage_variant_v1`, split into subpatterns before promotion.
   The XMage test miner found references for `7/21` cards and only `2/21`
   directly usable scenario candidates, so this is a high-value cluster but not
   one executable behavior.
9. Only then open new runtime on the most reusable exact-scope groups:
   - `damage_all_variant_v1` (`2`)
   - `destroy_all_permanents_or_creatures_variant_v1` (`2`)
10. Do not let `token_maker` lead runtime work yet:
   - it is `20` cards across `20` scopes;
   - first it needs taxonomy/test-miner support, not direct executor work.

## Practical commands

Rebuild the effective queue:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_effective_queue_report.py \
  --proposal-report docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_mapper_runtime_batch_v2_proposals.json \
  --report-dir docs/hermes-analysis/master_optimizer_reports \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260624_mapper_runtime_batch_v3_post_pg184
```

Use XMage inventory as the global direction layer:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_engine_absorption_inventory.py \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --output-json docs/hermes-analysis/master_optimizer_reports/xmage_engine_absorption_inventory_20260624.json \
  --output-md docs/hermes-analysis/master_optimizer_reports/xmage_engine_absorption_inventory_20260624.md
```

Compare acceleration strategies:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_acceleration_strategy_benchmark.py \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_acceleration_strategy_benchmark_20260624_expanded_608_619_real_v1
```

Build the shadow pattern registry:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_pattern_registry_builder.py \
  --proposal-report docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_mapper_runtime_batch_v2_proposals.json \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_pattern_registry_20260624_mapper_runtime_batch_v2
```

Build the Lorehold ideal-deck candidate matrix:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_ideal_deck_candidate_matrix.py \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260624_v1
```

Run the integrated current-scope pipeline without materializing Hermes data:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py \
  --skip-materialize \
  --include-deck-id 608 --include-deck-id 609 --include-deck-id 610 \
  --include-deck-id 611 --include-deck-id 612 --include-deck-id 613 \
  --include-deck-id 614 --include-deck-id 615 --include-deck-id 616 \
  --include-deck-id 617 --include-deck-id 618 --include-deck-id 619 \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8
```

Validate strategy/project consistency:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py \
  --pattern-registry-report docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_pattern_registry.json \
  --pipeline-manifest docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg166_181_postsync_real_v8_manifest.json \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260624_pg166_181_postsync_real_v5
```

## Definition of a good next cycle

A cycle is good only if it does at least one of these:

- reduces `package_ready_unprepared`;
- reduces one large split-scope cluster;
- lands one reusable runtime scope with tests;
- reduces duplicate rebuild work to zero for already-prepared packages.

If none of those moved, the cycle likely added work without improving throughput.
