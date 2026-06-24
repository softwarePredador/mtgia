# XMage Acceleration Strategy Decision

## Decision

Use `hybrid_effective_queue_pattern_registry` as the default XMage -> ManaLoom
absorption strategy.

This means:

1. package manifests remove cards from modeling work;
2. PostgreSQL packages move only through explicit precheck/apply/postcheck/sync
   gates;
3. split-scope clusters drive the next modeling work;
4. runtime changes are opened only for homogeneous exact scopes;
5. pattern registry work runs in shadow with evidence, then promotes only
   through reviewed/tested `card_battle_rules`.

Implemented support:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_pattern_registry_builder.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_pattern_registry_builder.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py`
- Pipeline output suffixes: `_pattern_registry.json`, `_pattern_registry.md`.
- Standalone SQL contract proposal: `_schema_proposal.sql`.
- Pipeline manifests expose `aggregate_scope.effective_deck_ids` so forced
  decks such as `608` through `619` are visible in persisted evidence, not only
  in stdout.

## Proof

Benchmark artifact:

- `docs/hermes-analysis/master_optimizer_reports/xmage_acceleration_strategy_benchmark_20260624_expanded_608_619_real_v1.md`

Current real queue:

- proposals: `504`;
- package already prepared: `54`;
- package ready unprepared: `0`;
- split-scope backlog: `68`;
- runtime backlog: `24`;
- manual mapper backlog: `356`;
- missing XMage source: `2`.

Benchmark ranking:

| Rank | Strategy | Verdict | Score | Cards/unit |
| --- | --- | --- | ---: | ---: |
| 1 | `hybrid_effective_queue_pattern_registry` | `recommended` | 80.1 | 19.25 |
| 2 | `exact_scope_cluster_first` | `use_as_next_modeling_lane` | 73.14 | 21.0 |
| 3 | `package_manifest_first` | `use_immediately_with_pg_approval` | 59.05 | 3.6 |
| 4 | `full_xmage_first` | `reject_as_primary` | 45.6 | 0.016 |
| 5 | `runtime_exact_scope_first` | `use_selectively` | 44.2 | 2.0 |
| 6 | `pattern_registry_first` | `use_as_shadow_infrastructure` | 44.05 | 0.033 |
| 7 | `card_by_card_queue` | `reject_as_default` | 42.0 | 1.0 |
| 8 | `test_miner_first` | `use_as_evidence_gate_not_primary_queue` | 36.56 | 0.333 |

## Why not full XMage first

Full XMage-first analysis is useful as reference, but not as the primary queue
strategy.

Measured evidence:

- local XMage card implementation files: `31706`;
- local XMage Java files total: `38739`;
- current ManaLoom queue proposals: `504`;
- work multiplier versus current queue: `62.91`;
- current queue cards per work unit: `0.016`.

This path has high long-term reuse but delays the active deck queue too much.

## Why not card-by-card

Card-by-card queue review can finish individual cards, but it does not compound.

Measured evidence:

- proposals: `504`;
- cards per work unit: `1.0`;
- manual mapper backlog: `356`.

This remains valid only as an exception-lane fallback.

## Pattern registry boundary

The user's proposed registry idea is correct, but it must not become an
ungated executor.

Acceptable registry content:

- XMage effect observations;
- extracted ability/cost/target/filter signals;
- battle template candidates;
- confidence and test evidence;
- source file and class provenance;
- promotion status.

Not acceptable:

- treating registry rows as executable battle truth before focused ManaLoom
  tests;
- joining registry/template rows directly into deck-card consumers without
  one-row-per-card aggregation;
- letting Hermes cache overwrite PostgreSQL truth.

Promotion path:

1. XMage observation;
2. template candidate;
3. local focused test;
4. PostgreSQL package;
5. post-apply validation;
6. PG -> Hermes sync;
7. affected battle/deck audit.

Current implementation guarantee:

- generated pattern rows use `promotion_status=shadow_only`;
- `can_execute_in_battle=false`;
- `can_auto_promote_to_card_battle_rules=false`;
- schema proposal includes a check preventing `shadow_only` rows from becoming
  executable/autopromotable.
- strategy consistency audit validates docs, benchmark, registry, schema,
  effective queue, pipeline manifest scope, and no materialization apply in the
  read-only evidence run.

## Next required implementation lane

Start with `targeted_damage_variant_v1`, but split it before promotion.

Evidence:

- cards in current top split-scope cluster: `21`;
- XMage test references found: `7/21`;
- directly usable scenario candidates: `2/21`.

Therefore `targeted_damage_variant_v1` is a useful queue label, not a single
runtime behavior. The next step is to split it into concrete subpatterns such as
spell-target damage, triggered damage, damage redirection/reflection, event
punisher damage, and damage-plus-life/draw/counter variants.

## Required project instruction

Every future XMage absorption cycle must regenerate:

1. effective queue report;
2. acceleration strategy benchmark;
3. shadow pattern registry;
4. focused test evidence for promoted runtime/pattern changes.

If a proposed cycle does not reduce package work, one split-scope cluster, one
homogeneous runtime scope, or duplicate rebuild work, it is not an acceleration
cycle.
