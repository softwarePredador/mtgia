# XMage -> ManaLoom Definitive Flow - 2026-06-29

Status: `current_operating_standard`.

This document supersedes the operational parts of:

- `XMAGE_ABSORPTION_IMPLEMENTATION_PLAN_2026-06-23.md`
- `XMAGE_ABSORPTION_WORKFLOW_V2_2026-06-24.md`
- `XMAGE_ACCELERATION_STRATEGY_DECISION_2026-06-24.md`

Those files remain historical evidence. This file defines the current flow to
use for card-rule acceleration.

Execution contract:

- `BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md` freezes how to follow
  this flow day to day.
- If the contract checkpoint passes, do not revalidate the full strategy again;
  rebuild the queue and continue family/subpattern work.

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

The definitive rule: broad XMage extraction may create review candidates and family lanes, but it must not create executable battle truth or PostgreSQL promotion by itself.

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

Latest Lorehold and opponent replay-scope artifacts:

- before family-mapper wave:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_134228_current_lorehold_6_607_616_manifest.md`
- after family-mapper wave:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_135909_post_adagia_family_mapper_lorehold_6_607_616_manifest.md`
- runtime surface gate:
  `docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_manifest_20260629_post_adagia_mapper.md`
- external source gate:
  `docs/hermes-analysis/master_optimizer_reports/mtg_battle_external_source_audit_20260629_post_adagia_mapper.md`

Current active scope:

- artifact deck IDs: `[6]`
- learned opponent deck IDs:
  `[25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116]`
- forced Lorehold deck IDs:
  `[6, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616]`
- effective deck IDs:
  `[6, 25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616]`
- actionable XMage-sourced validity rows: `239`
- combined severity counts:
  `{"critical": 1, "high": 207, "medium": 49, "pass": 534}`

Before the 2026-06-29 family-mapper wave:

- structured XMage pull review candidates: `135/239`
- manual mapper backlog: `104/239`
- family counts included:
  `ramp_permanent=49`, `tutor=16`, `free_cast=11`,
  `targeted_interaction=10`, `passive=5`, `manual_model=104`

After the 2026-06-29 family-mapper wave:

- structured XMage pull review candidates: `158/239`
- manual mapper backlog: `81/239`
- net manual backlog reduction: `23` cards
- family counts now include:
  `ramp_permanent=49`, `targeted_interaction=24`, `tutor=14`,
  `free_cast=11`, `passive=11`, `ramp_ritual=4`,
  `life_total_change=2`, `copy_creature_token=1`,
  `copy_spell_engine=1`, `token_maker=1`, `manual_model=81`
- proposal status counts:
  `batch_pg_candidate_after_precheck=8`,
  `split_family_scope_review_required=148`,
  `runtime_family_implementation_required=1`,
  `mapper_metadata_or_test_scenario_required=81`
- PostgreSQL writes in this wave: `0`

Post-contract checkpoint wave:

- contract checkpoint:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260629_143113_contract_checkpoint.md`
- current queue after conservative red utility-land split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_143734_post_red_land_mana_split_manifest.md`
- PG249 package prepared read-only for seven exact runtime-backed cards:
  `Verge Rangers`, `Firesong and Sunspeaker`, `Goliath Daydreamer`,
  `Boros Reckoner`, `Terror of the Peaks`, `Balefire Liege`, `Repercussion`.
- PG249 was not applied. Precheck found one target card row for each selected
  card and the package remains blocked until explicit apply approval.
- `Adagia, Windswept Bastion` stayed out of PG249 because the proposal still
  requires the `station_level_gate` runtime component.
- `Purphoros, God of the Forge` stayed out of PG249 because it is in the
  partial preserve-shadow lane.

Conservative ramp split evidence:

- `Cori Mountain Monastery`, `Fire Nation Palace`,
  `Shinka, the Bloodsoaked Keep`, and `Spinerock Knoll` now split the exact
  red mana mode from the rest of the card using
  `land_tap_one_red_mana_nonmana_ability_pending_v1`.
- This is intentionally not a full-card promotion. Each card has non-mana
  behavior that still requires a separate exact scope before PostgreSQL truth.
- Pattern status counts after the split are:
  `governance_only_pending_pg_apply=7`,
  `ready_for_pg_package_generation=2`,
  `requires_subpattern_split_before_promotion=21`,
  `fragmented_runtime_observation_only=1`.
- The lower ready count is correct: seven cards moved into a prepared PG
  package, and one land subpattern became stricter because generic land-mana
  grouping would have hidden unresolved non-mana abilities.

Post-apply E2E wave:

- PG249 was applied on 2026-06-29 for:
  `Verge Rangers`, `Firesong and Sunspeaker`, `Goliath Daydreamer`,
  `Boros Reckoner`, `Terror of the Peaks`, `Balefire Liege`, `Repercussion`.
- PG249 apply result: `deprecated_shadow_rows=6`, `upserted_rows=7`; postcheck
  showed all seven selected cards with one promoted verified/auto row and
  matching Oracle hash.
- PG249 sync result:
  `pg_rows_loaded=13`, `sqlite_inserted_or_updated=13`; the row count includes
  seven active curated rules plus six deprecated disabled shadow rows.
- Runtime probing found a real model issue: the PG249 `Repercussion` row was
  immediate `direct_damage`, but the card must be a passive enchantment trigger
  so it can enter the battlefield and react to later creature damage.
- PG250 corrected only `Repercussion`: the `direct_damage` row was disabled and
  `battle_rule_v1:d1a0c5cc0035945ec8bfd795da52d017` was promoted as
  `passive` with `creature_damage_controller_reflect_global_v1`.
- The battle runtime now prefers synced `curated` SQLite/PG rules over
  temporary manual runtime waivers, while preserving waivers as fallback for
  missing or stale non-curated rows.
- Final runtime probe:
  `docs/hermes-analysis/master_optimizer_reports/pg249_pg250_runtime_ready_exact_family_batch_20260629_145521_get_card_effect_probe.json`
- Queue after PG249/PG250 apply/sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_145746_post_pg249_pg250_apply_sync_manifest.md`
- PG249/PG250 combined severity counts:
  `{"critical": 1, "high": 200, "medium": 49, "pass": 541}`
- PG249/PG250 actionable XMage-sourced validity rows:
  `ready_for_structured_xmage_pull_review_required=151`,
  `xmage_source_valid_mapper_required=81`.
- PG249/PG250 proposal status counts:
  `batch_pg_candidate_after_precheck=1`,
  `partial_batch_pg_candidate_preserve_shadow_rows_after_precheck=1`,
  `runtime_family_implementation_required=1`,
  `split_family_scope_review_required=148`,
  `mapper_metadata_or_test_scenario_required=81`.
- At that point, the remaining immediate lanes were:
  `Adagia, Windswept Bastion` pending `station_level_gate`,
  `Purphoros, God of the Forge` in preserve-shadow partial lane, and
  `Hazel's Brewmaster` as a runtime-family exception.

This was historical PG249/PG250 state. It is superseded by the subsequent
PG251+ runtime/promotion wave below.

Additional exact runtime/mapping correction:

- `Adagia, Windswept Bastion` was reclassified from generic `token_maker` to
  `copy_creature_token` with scope
  `station_12_copy_artifact_or_enchantment_you_control_legendary_token_v1`.
- Runtime now carries `token_legendary` through copy-token creation and replay
  events.
- Remaining `runtime_family_implementation_required` item is
  `Hazel's Brewmaster`, because XMage shows Food token creation plus static
  ability sharing from creature cards exiled with Hazel. That is not safe to
  collapse into generic token creation.

Subsequent runtime/promotion wave:

- PG251 was applied and synced for `Adagia, Windswept Bastion`,
  `Hazel's Brewmaster`, and `Purphoros, God of the Forge`.
- PG252 promoted sixteen manual runtime-waiver rules into reviewed PostgreSQL
  truth.
- PG253 promoted nine existing focused runtime rules into PostgreSQL.
- PG254 promoted fourteen blink/static/legacy runtime rules and corrected the
  forensic tests to accept synced curated PostgreSQL rules.
- PG255 promoted `Ashnod's Altar`, `Chrome Mox`, and `Mox Diamond` fast-mana
  runtime rules.
- PG256 promoted `Treasonous Ogre` with life-payment red mana runtime support.
- PG257 promoted `Phyrexian Censor` with non-Phyrexian spell-limit and
  enter-tapped static runtime support.
- Queue after PG257:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_162756_post_pg257_phyrexian_censor_static_runtime_manifest.md`
- PG257 combined severity counts:
  `{"critical": 1, "high": 114, "medium": 57, "pass": 619}`
- PG257 actionable unresolved rows in the validity/family/proposal reports:
  `154`.
- PG257 unresolved routing:
  `ready_for_structured_xmage_pull_review_required=91`,
  `xmage_source_valid_mapper_required=63`,
  `runtime_family_required_count=0`.
- PG257 family counts include:
  `manual_model=63`, `ramp_permanent=16`, `tutor=13`,
  `targeted_interaction=12`, `recursion=11`, `free_cast=9`,
  `targeted_protection=8`, `passive=5`, `draw_engine=4`,
  `topdeck_play=3`, `board_wipe_choice=3`, `ramp_ritual=2`.

PG262 exact ritual runtime checkpoint (historical):

- PG262 was applied and synced for `Mana Geyser` and `Burnt Offering`.
- `Mana Geyser` now uses exact scope
  `add_red_for_each_tapped_land_opponents_control_v1`, counting tapped lands
  controlled by opponents instead of a fixed heuristic amount.
- `Burnt Offering` now uses exact scope
  `sacrifice_creature_add_black_or_red_equal_sacrificed_mana_value_v1`,
  using the sacrificed creature mana value instead of a fixed heuristic amount.
- PG262 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg262_exact_ritual_runtime_20260629_package.md`.
- Queue after PG262:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1746_post_pg262_exact_ritual_runtime_manifest.md`.
- PG262 combined severity counts:
  `{"critical": 1, "high": 108, "medium": 45, "pass": 637}`.
- PG262 unresolved routing:
  `ready_for_structured_xmage_pull_review_required=73`,
  `xmage_source_valid_mapper_required=63`,
  `runtime_family_required_count=0`.
- PG262 family counts include:
  `manual_model=63`, `targeted_interaction=12`, `recursion=11`, `tutor=10`,
  `free_cast=9`, `targeted_protection=8`, `ramp_permanent=6`, `passive=5`,
  `draw_engine=4`, `topdeck_play=3`, `board_wipe_choice=3`,
  `copy_spell_engine=1`, `life_total_change=1`.

PG263/PG264 Lorehold runtime-gap checkpoint:

- PG263 was applied and synced for eight Lorehold/opponent runtime-gap cards:
  `Goliath Daydreamer`, `Twinflame Tyrant`, `Verge Rangers`,
  `Boros Reckoner`, `Terror of the Peaks`, `Balefire Liege`,
  `Firesong and Sunspeaker`, and `Repercussion`.
- PG263 apply result: backup rows `17`, deprecated shadow rows `12`,
  upserted rows `8`; E2E validation proved PostgreSQL `8/8`, SQLite `8/8`,
  canonical snapshot `8/8`, and runtime `get_card_effect` `8/8`.
- The E2E validator and package builder now require snapshot/runtime checks
  derived from `expected_rules`, preventing a false-green package with
  `validated_cards=0`.
- The runtime-gap queue now filters cards that already have a synced
  `verified/auto` exact rule in SQLite. This corrected the stale queue from
  `61` raw blocked rows to `27` real pending rows after PG263.
- PG264 implemented and applied the exact Gisela static-damage scope
  `opponent_or_opponent_permanent_damage_doubled_self_damage_halved_v1`,
  using local XMage classes
  `GiselaBladeOfGoldnightDoubleDamageEffect` and
  `GiselaBladeOfGoldnightPreventionEffect`.
- PG264 apply result: backup rows `2`, deprecated shadow rows `2`, upserted
  rows `1`; E2E validation proved PostgreSQL `1/1`, SQLite `1/1`, canonical
  snapshot `1/1`, and runtime `get_card_effect` `1/1`.
- Current queue after PG264:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg264_gisela.md`.
- Current proposal report after PG264:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg264_gisela_proposals.md`.
- Current unresolved Lorehold runtime-gap queue: `26` cards,
  `mapper_metadata_or_test_scenario_required=13`,
  `split_family_scope_review_required=13`,
  `safe_for_batch_pg_package_count=0`.

PG267/PG268 runtime-rule checkpoint:

- PG265 was applied and synced for `Lens of Clarity` with exact visibility-only
  topdeck scope `look_top_library_any_time_and_opponent_face_down_creatures_v1`.
- PG266 was applied and synced for `Eight-and-a-Half-Tails` with exact
  activated protection scope
  `creature_body_target_permanent_protection_from_white_make_source_white_activation_runtime_v1`.
- PG267 was applied and synced for `Neheb, the Eternal` with exact postcombat
  mana scope `postcombat_main_add_red_for_opponents_life_lost_this_turn_v1`.
- PG268 was applied and synced for `Cloud Key` with exact chosen-card-type
  cost-reduction scope `chosen_card_type_cost_reduction_v1`.
- PG267 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg267_neheb_postcombat_mana_20260630_package.md`.
- PG268 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg268_cloud_key_chosen_type_cost_reduction_20260630_package.md`.
- Current queue after PG268:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_081500_post_pg268_cloud_key_manifest.md`.
- Current combined severity counts:
  `{"high": 104, "medium": 42, "pass": 645}`.
- Current unresolved routing:
  `ready_for_structured_xmage_pull_review_required=70`,
  `xmage_source_valid_mapper_required=61`,
  `runtime_family_required_count=0`.
- Current family counts include:
  `manual_model=61`, `targeted_interaction=12`, `recursion=11`, `tutor=10`,
  `free_cast=9`, `targeted_protection=7`, `ramp_permanent=5`, `passive=5`,
  `draw_engine=4`, `topdeck_play=2`, `board_wipe_choice=3`,
  `copy_spell_engine=1`, `life_total_change=1`.
- Current Lorehold runtime-gap queue:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg268_cloud_key.md`;
  blocked runtime gaps are `22`, with
  `mapper_metadata_or_test_scenario_required=12` and
  `split_family_scope_review_required=10`.

`Adagia, Windswept Bastion` is no longer blocked on
`station_level_gate`: the exact scope
`station_12_copy_artifact_or_enchantment_you_control_legendary_token_v1`
now carries `station_level_required=12`, activation cost `{3}{W}`, tap
requirement, controlled artifact/enchantment targets, and legendary token
creation through focused runtime tests and PostgreSQL sync.

Runtime/source revalidation after the mapper wave:

- runtime surface manifest: `147` related Python files, `0` unclassified
  files.
- external source audit: gate `pass`, required gaps `0`, required partials
  `0`, optional gaps `0`.

The main blocker is therefore still not missing XMage source. The blocker is
exact ManaLoom mapper/runtime coverage by family and subpattern. Generic
`xmage_*_review_v1` scopes are useful queue reducers, but they remain
review-only until exact scope, focused tests, PostgreSQL package approval, and
PG -> Hermes sync.

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
2. Split and test `ramp_permanent` because it currently has `49` cards and is
   turn-timing critical.
3. Split and test `targeted_interaction` because it now has `24` cards after
   blink, redirect, multi-damage, and target-untap routing.
4. Split and test `tutor` because it has `14` cards and strongly affects
   combo/deck search behavior.
5. Split and test `free_cast` because it has `11` cards and high runtime risk.
6. Split and test `passive`, `recursion`, `targeted_protection`,
   `ramp_ritual`, and `life_total_change` in that order unless a replay/deck
   priority makes one urgent.
7. Treat the remaining `token_maker` runtime item as an exact Hazel's
   Brewmaster exception, not as permission to implement a generic token-maker
   executor.
8. Work the remaining `manual_model` backlog by adding mapper patterns, not by
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
  --include-deck-id 6 \
  --include-deck-id 607 \
  --include-deck-id 608 \
  --include-deck-id 609 \
  --include-deck-id 610 \
  --include-deck-id 611 \
  --include-deck-id 612 \
  --include-deck-id 613 \
  --include-deck-id 614 \
  --include-deck-id 615 \
  --include-deck-id 616 \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_$(date -u +%Y%m%d_%H%M%S)_current
```

Then use the manifest/family/proposal/pattern reports to select the next exact
scope. Do not select work by intuition when the queue reports disagree.
