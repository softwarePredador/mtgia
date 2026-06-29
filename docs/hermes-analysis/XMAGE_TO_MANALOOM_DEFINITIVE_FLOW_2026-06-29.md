# XMage -> ManaLoom Definitive Flow - 2026-06-29

Status: `current_operating_standard`.

This document supersedes the operational parts of:

- `XMAGE_ABSORPTION_IMPLEMENTATION_PLAN_2026-06-23.md`
- `XMAGE_ABSORPTION_WORKFLOW_V2_2026-06-24.md`
- `XMAGE_ACCELERATION_STRATEGY_DECISION_2026-06-24.md`

Those files remain historical evidence. This file defines the current flow to
use for card-rule acceleration.

## Decision

Use a staged source-and-gate pipeline:

1. Scryfall/MTGJSON bulk for card identity, Oracle text, layout, legality,
   rulings, and hash inputs.
2. Local XMage as the primary open rules-engine reference.
3. Forge as a secondary implementation cross-check for ambiguous or high-risk
   scopes.
4. XMage signal extraction into reviewable ManaLoom families.
5. Exact-scope mapper and focused runtime tests per family/subpattern.
6. PostgreSQL package only after exact scope, tests, and precheck evidence.
7. PostgreSQL -> Hermes/SQLite sync and replay/audit validation after apply.

The definitive rule: broad XMage extraction may create review candidates and
family lanes, but it must not create executable battle truth or PostgreSQL
promotion by itself.

## Why This Is The Best Current Flow

The alternatives were rechecked on 2026-06-29.

### Direct Full XMage Port

Rejected as primary.

Reason:

- XMage is Java and tied to its own game engine, stack, priority, target,
  watcher, replacement, cost, and event model.
- ManaLoom needs `effect_json`, `battle_model_scope`, runtime support, tests,
  PostgreSQL lineage, and Hermes sync.
- Porting all XMage first touches tens of thousands of files before reducing the
  active ManaLoom queue.

Use it only as reference corpus and extractor input.

### Card-By-Card Manual Review

Rejected as default.

Reason:

- It closes individual cards but does not compound.
- It repeats the same parser/runtime reasoning for cards in the same semantic
  family.

Use it only for exception cards after higher-leverage lanes are exhausted.

### Oracle-Only Scryfall/MTGJSON Flow

Rejected for battle behavior.

Reason:

- Scryfall and MTGJSON are excellent for card data, identity, rulings,
  legalities, and bulk update speed.
- They do not contain executable rules-engine behavior.

Use them as the identity/hash/data gate, not as battle runtime source.

### 17Lands/Logs/Reddit/Meta-First Flow

Rejected for rule adaptation.

Reason:

- These sources can inform strategy, usage, and deckbuilding heuristics.
- They do not prove card rules or battle execution correctness.

Use them downstream for strategy/deckbuilding, not for card-rule promotion.

### Forge-First Flow

Rejected as primary, accepted as cross-check.

Reason:

- Forge is another Java rules engine, useful for disagreement analysis.
- Using Forge as the main input doubles parser/modeling work while the current
  blocker is already proven inside XMage -> ManaLoom mapping.

Use it only when XMage signal extraction is ambiguous or a high-risk family
needs a second engine reference.

## Current Evidence

Latest E2E artifact:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_e2e_acceleration_after_generic_mapper_manifest.json`

Current active scope:

- deck IDs: `[6, 25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116]`
- total combined cards: `541`
- actionable audited cards: `139`
- exact local XMage source found: `139/139`
- focused scenario generated: `139/139`

Before the generic XMage mapper layer:

- structured pull candidates: `5/139`
- manual mapper backlog: `134/139`
- detected families: `5`

After the generic XMage mapper layer:

- structured pull candidates: `76/139`
- manual mapper backlog: `63/139`
- detected families: `15`
- PostgreSQL batch candidates from generic review scopes: `0`

The main blocker is therefore not missing XMage source. The blocker is exact
ManaLoom mapper/runtime coverage by family.

## Source Roles

| Source | Role | May Promote Rules? |
| --- | --- | --- |
| PostgreSQL `card_battle_rules` | Product source of truth | Yes, after approved package |
| Hermes SQLite | Runtime/cache/audit mirror | No |
| Scryfall bulk | Oracle identity/text/rulings/layout/hash | No |
| MTGJSON bulk | Secondary normalized card/ruling/legalities data | No |
| XMage local source | Primary rules-engine reference and signal source | No, only candidates |
| Forge source | Secondary engine cross-check | No, only candidates |
| 17Lands/logs/meta/community | Strategy/deckbuilding evidence | No |
| Pattern registry | Shadow batching/test planning | No |

## Definitive Flow

### Gate 0 - Scope Selection

Input:

- latest battle/replay artifact scope;
- forced deck IDs such as Lorehold deck 6 and relevant learned opponent decks;
- any explicit user-specified decks.

Output:

- `aggregate_scope.effective_deck_ids`
- combined deck-card coherence report

Rules:

- Replay/deck evidence prioritizes work.
- Replay/deck evidence does not define rule truth.

### Gate 1 - Oracle/Data Normalization

Input:

- Scryfall bulk cache;
- MTGJSON/rulings when useful;
- PostgreSQL card identity surfaces.

Output:

- stable card identity;
- Oracle hash;
- layout/faces;
- type/mana/color data;
- rulings references.

Rules:

- Bulk/local cache is the default for scale.
- Named/live API fallback is only for misses.
- A card without identity/hash can be analyzed but cannot be promoted as trusted
  battle behavior unless it has an explicit no-text/no-hash exception.

### Gate 2 - XMage/Forge Source Resolution

Input:

- normalized card names;
- local XMage root `/Users/desenvolvimentomobile/Downloads/mage-master`;
- optional Forge reference for cross-check.

Output:

- local XMage class path;
- constructor metadata;
- ability/effect/target/filter/cost/condition/watcher signals;
- raw excerpt;
- focused scenario draft.

Rules:

- Missing XMage source is an exception lane, not the main queue.
- Forge is used only when XMage is ambiguous or a high-risk family needs a
  second implementation reference.

### Gate 3 - Family Routing

Input:

- XMage extracted signals;
- Oracle text/hash;
- existing ManaLoom family definitions.

Output lanes:

- `batch_metadata_candidate_requires_pg_precheck`
- `split_family_scope_review_required`
- `runtime_family_implementation_required`
- `mapper_metadata_or_test_scenario_required`
- `blocked_missing_xmage_source`

Rules:

- Generic scopes such as `xmage_*_review_v1` are review/split only.
- Generic scopes must never become batch PG candidates.
- Pattern registry rows are `shadow_only`.
- No registry row can execute in battle.

### Gate 4 - Exact Scope Split

Input:

- largest family/scope clusters from the current queue.

Output:

- exact `battle_model_scope`;
- exact `effect_json` schema;
- positive and negative focused test cases;
- runtime support assessment.

Rules:

- Work largest reusable exact-scope clusters first.
- A large family with many fragmented scopes does not lead the queue until it
  is split.
- Do not implement runtime for a broad family label if the cards inside require
  different behavior.

### Gate 5 - Runtime Implementation

Input:

- exact scope;
- focused test scenarios;
- current `battle_analyst`/runtime capabilities.

Output:

- runtime implementation or proof that existing runtime already supports it;
- focused tests;
- event/provenance assertions for selected logical rule key.

Rules:

- Runtime changes must include tests.
- Tests must exercise the card behavior, not only loading metadata.
- If a candidate card is not drawn/used in battle, battle aggregate alone is not
  proof for that card.

### Gate 6 - PostgreSQL Package

Input:

- exact scoped rule;
- Oracle hash;
- runtime/focused test proof;
- stale shadow-row plan.

Output:

- package doc;
- precheck SQL/output;
- apply SQL/output;
- rollback SQL;
- postcheck SQL/output.

Rules:

- PostgreSQL remains the durable source of truth.
- No PostgreSQL write without explicit approval or approved package workflow.
- Generated/review-only shadows must be disabled or preserved deliberately so
  they do not shadow reviewed rules.

### Gate 7 - Sync And Audit

Input:

- applied PostgreSQL package.

Output:

- PG -> SQLite/Hermes sync report;
- canonical snapshot refresh;
- `get_card_effect`/runtime lookup proof;
- affected deck coherence audit;
- replay/focused battle validation when battle-relevant.

Rules:

- Hermes is cache/runtime evidence, not truth.
- PostgreSQL wins on conflict.
- Global PG/SQLite count differences are routing signals; per-card path must be
  verified directly.

### Gate 8 - Queue Rebuild

Input:

- post-sync current state.

Output:

- fresh effective queue;
- family counts;
- pattern registry;
- next lane recommendation.

Rules:

- Every package/runtime wave must shrink one real queue dimension:
  package-ready, split-scope, runtime-family, manual-mapper, or missing-source.
- If no queue dimension shrinks, the cycle was not an acceleration cycle.

## Current Priority Order

Use this order until a fresh E2E queue changes it:

1. Close any exact package-ready lane only if it is non-generic and has focused
   runtime/test proof.
2. Split and test `ramp_permanent` because it currently has `29` cards and is
   turn-timing critical.
3. Split and test `tutor` because it has `12` cards and strongly affects
   combo/deck search behavior.
4. Split and test `free_cast` because it has `6` cards and high runtime risk.
5. Split and test `recursion`, `targeted_protection`, and `passive` in that
   order unless a replay/deck priority makes one urgent.
6. Work the remaining `manual_model` backlog by adding mapper patterns, not by
   reviewing one card at a time.

## Required Artifacts Per Cycle

Every cycle must produce or refresh:

- current replay/deck scope manifest;
- combined coherence report;
- XMage index;
- validity audit;
- semantic family report;
- proposal report;
- shadow pattern registry;
- focused tests/runtime output for any executable change;
- PostgreSQL package evidence when a durable rule is promoted;
- PG -> Hermes sync report after apply;
- post-sync deck/replay audit.

## Stop Conditions

A card is considered closed for battle/deckbuilding only when all are true:

1. identity and Oracle hash are known or explicitly excepted;
2. exact local source/reference is recorded or exception lane is documented;
3. `effect_json` has exact scope, not only generic family;
4. focused positive and negative tests pass;
5. runtime either supports the behavior or the behavior is deliberately
   annotation-only;
6. PostgreSQL row is reviewed/trusted when executable behavior is durable;
7. Hermes/SQLite was synced from PostgreSQL after apply;
8. affected deck/replay audit no longer reports the card as unresolved.

## Non-Negotiable Safety Rules

- Do not promote from `xmage_*_review_v1`.
- Do not execute pattern registry rows.
- Do not let Hermes overwrite PostgreSQL.
- Do not join raw multi-row `card_battle_rules`, `card_function_tags`, or
  `card_semantic_tags_v2` directly into deck-card consumers without
  aggregation.
- Do not count a battle swap/test as evidence for a card unless that card was
  drawn/used or the focused test explicitly exercised it.
- Do not start full-XMage parsing work that does not reduce the active queue.

## Practical Next Command

The next productive command should rebuild the current queue after any new
runtime/package wave, then pick the highest queue-reducing exact scope:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --skip-materialize \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_$(date -u +%Y%m%d_%H%M%S)_current
```

Then use the manifest/family/proposal/pattern reports to select the next exact
scope. Do not select work by intuition when the queue reports disagree.
