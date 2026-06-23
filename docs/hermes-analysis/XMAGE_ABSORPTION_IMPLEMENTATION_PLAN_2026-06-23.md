# XMage Absorption Implementation Plan - 2026-06-23

Status: `implemented_read_only_validated`.

Scope:

- Local XMage source: `/Users/desenvolvimentomobile/Downloads/mage-master`.
- ManaLoom repo: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`.
- This plan does not authorize PostgreSQL writes, deck swaps, or automatic rule
  promotion.
- PostgreSQL/backend remains the product source of truth. XMage is a local
  reference corpus for rule modeling, tests, and review packets.

## Implementation Evidence - 2026-06-23

Implemented files:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_local_rule_indexer.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_reference_test_scenario_builder.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_commander_legality_reference_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_validity_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/external_card_rule_reference_harvester.py`

Focused tests added or updated:

- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_local_rule_indexer.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_reference_test_scenario_builder.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_commander_legality_reference_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_validity_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_external_card_rule_reference_harvester.py`

Validated commands:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_local_rule_indexer.py`
  -> latest `Ran 7 tests OK`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
  -> latest `Ran 7 tests OK`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_reference_test_scenario_builder.py`
  -> latest `Ran 3 tests OK`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_commander_legality_reference_audit.py`
  -> `Ran 2 tests OK`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_validity_audit.py`
  -> latest `Ran 6 tests OK`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_external_card_rule_reference_harvester.py`
  -> `Ran 6 tests OK`.
- `python3 -m py_compile ...` for all changed/new Python modules -> exit `0`.

Live read-only artifacts:

- `docs/hermes-analysis/master_optimizer_reports/xmage_local_rule_index_deck607_pg107_high_20260623.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_local_rule_index_deck607_pg107_high_20260623.md`
- `docs/hermes-analysis/master_optimizer_reports/external_card_rule_reference_harvest_deck607_pg107_xmage_local_20260623.json`
- `docs/hermes-analysis/master_optimizer_reports/external_card_rule_reference_harvest_deck607_pg107_xmage_local_20260623.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_commander_legality_reference_audit_20260623.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_commander_legality_reference_audit_20260623.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_local_rule_index_deck607_pg108_high_medium_batch_validity_20260623.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_local_rule_index_deck607_pg108_high_medium_batch_validity_20260623.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_batch_validity_audit_deck607_pg108_high_medium_20260623.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_batch_validity_audit_deck607_pg108_high_medium_20260623.md`

Live deck `607` XMage-local result:

- Initial requested high queue cards: `9`; full current high/medium gate:
  `13` (`high=9`, `medium=4`).
- Exact local XMage card implementations resolved: initial `7`, full gate
  `11/13`.
- Ready for structured XMage pull with ManaLoom review/tests still required:
  `11/13`.
- Ready cards with generated focused test scenarios: `11/13`.
- Not exact-matched: `Molecule Man`, `Thor, God of Thunder`.
- XMage card class index size: `31706`.
- `mutations_performed=[]`.

Resolved hints:

- `Promise of Loyalty` ->
  `each_player_choose_creature_vow_counter_sacrifice_other_creatures_attack_restriction_v1`.
- `Starfall Invocation` ->
  `gift_card_destroy_all_creatures_return_one_own_creature_destroyed_this_way_v1`.
- `Pearl Medallion` -> `static_cost_reduction_for_matching_spells_v1`.
- `Emeria's Call // Emeria, Shattered Skyclave` ->
  `xmage_create_token_variant_emeriascall_v1`.
- `The Mind Stone` ->
  `legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1`.
- `The Scarlet Witch` ->
  `static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1`.
- `Tragic Arrogance` ->
  `controller_chooses_artifact_creature_enchantment_planeswalker_per_player_sacrifice_other_nonlands_v1`.
- `Bender's Waterskin` ->
  `artifact_untaps_each_other_player_untap_step_tap_any_color_v1`.
- `Victory Chimes` ->
  `artifact_untaps_each_other_player_untap_step_tap_target_player_add_colorless_v1`.
- `Monument to Endurance` ->
  `discard_trigger_choose_unchosen_mode_draw_or_treasure_or_each_opponent_loses_3_v1`.
- `Surge to Victory` ->
  `exile_target_instant_sorcery_boost_team_and_combat_damage_copy_cast_free_v1`.

Commander reference audit:

- XMage Commander reference files found: `9/9`.
- This is reference-only and does not replace ManaLoom legality logic.
- PostgreSQL writes, deck swaps, and rule promotion remain outside this
  implementation.

## Local XMage Inventory

Observed local source inventory:

- `38,739` Java files.
- `31,706` card implementation classes under `Mage.Sets/src/mage/cards`.
- `802` core effect classes under `Mage/src/main/java/mage/abilities/effects`.
- `84` target classes under `Mage/src/main/java/mage/target`.
- `207` filter classes under `Mage/src/main/java/mage/filter`.
- `2,009` Java test files under `Mage.Tests`.

Useful XMage module groups:

- `Mage.Sets`: per-card Java implementations.
- `Mage/src/main/java/mage/abilities`: effects, costs, conditions, dynamic
  values, triggers, replacement effects, static abilities, keywords, and mana
  abilities.
- `Mage/src/main/java/mage/target`: target shape and target legality.
- `Mage/src/main/java/mage/filter`: object filters and predicates.
- `Mage/src/main/java/mage/util/validation`: Commander partner/background and
  deck validator helpers.
- `Mage/src/main/java/mage/game/GameCommanderImpl.java`: command-zone effects,
  commander tax, replacement and commander damage watcher wiring.
- `Mage.Tests`: reusable test scenario grammar: `addCard`, `castSpell`,
  `setChoice`, `check*`, `assert*`, and `execute`.

## What We Will Absorb

### 1. Local Card Implementation Index

Implement a read-only local indexer that resolves each ManaLoom card to a local
XMage class path and extracts structured signals.

Planned output fields:

- `card_name`
- `xmage_class_name`
- `xmage_path`
- `card_superclass`: `CardImpl`, `ModalDoubleFacedCard`, `SplitCard`,
  `AdventureCard`, etc.
- `mana_cost`, `card_types`, and visible constructor metadata when parseable.
- `imports`
- `ability_classes`
- `effect_classes`
- `target_classes`
- `filter_classes`
- `condition_classes`
- `counter_types`
- `zones`
- `custom_inner_classes`
- `raw_excerpt`

ManaLoom use:

- Improve `external_card_rule_reference_harvester.py`.
- Build review packets without internet.
- Detect whether a high finding is a real runtime gap, a metadata/scope gap,
  or a known unsupported mechanic.

### 2. XMage -> ManaLoom Effect Translation Hints

Implement a conservative translator that maps XMage classes to candidate
ManaLoom `effect_json` hints. The translator must mark all output as
`review_candidate`, never `verified`.

Initial translation families:

- `DestroyTargetEffect`, `DestroyAllEffect`, `DamageAllEffect`,
  `ExileTargetEffect`, `ReturnToHandTargetEffect`,
  `ReturnFromGraveyardToBattlefieldTargetEffect`.
- `CreateTokenEffect`, `CreateTokenCopyTargetEffect`.
- `DrawCardSourceControllerEffect`, `DrawCardTargetEffect`,
  `DrawDiscardControllerEffect`, `ScryEffect`.
- `SpellsCostReductionControllerEffect`,
  `SpellCostReductionSourceEffect`.
- `AddCountersTargetEffect`, `AddCountersAllEffect`,
  `CounterTargetEffect`.
- `SimpleStaticAbility`, `SimpleActivatedAbility`,
  `EntersBattlefieldTriggeredAbility`, `SpellCast*TriggeredAbility`,
  `BeginningOf*TriggeredAbility`, `Dies*TriggeredAbility`.

ManaLoom use:

- Suggest `effect`, `target`, `ability_kind`, `battle_model_scope`,
  `timing`, `duration`, `source_zone`, `destination_zone`, and
  `runtime_executor_required`.
- Reduce manual classification time for high/medium cards.
- Keep promotion gated by Oracle/Scryfall text, focused tests, replay, and
  PostgreSQL postcheck.

### 3. Target And Filter Semantics

Absorb target/filter shape, not Java behavior.

Examples:

- `TargetControlledCreaturePermanent` -> own creature target.
- `TargetOpponentsCreaturePermanent` -> opponent creature target.
- `TargetCardInYourGraveyard` -> graveyard card target owned/controlled by
  source controller.
- `TargetSpell`, `TargetStackObject` -> stack interaction, response-window
  only.
- `FilterPermanent`, `FilterCreaturePermanent`, color/subtype/card-type
  predicates -> ManaLoom target constraints.

ManaLoom use:

- Extend `effect_json` with structured target constraints.
- Generate focused tests that assert target declaration and target
  revalidation, not only final effect.

### 4. Conditions, Costs, Watchers, And Replacement Effects

Absorb conditional structure:

- `GiftWasPromisedCondition`, `KickedCostCondition`,
  `SourceHasCounterCondition`, `OpponentControlsMoreCondition`,
  `CardsInControllerGraveyardCondition`.
- Additional costs, sacrifice/discard costs, alternative costs, timing gates,
  and cost reducers.
- Replacement/delayed/watchers patterns for effects that cannot be modeled as
  simple one-shot spells.

ManaLoom use:

- Mark when a card needs runtime support instead of a passive rule row.
- Separate `static`, `triggered`, `activated`, `replacement`, and `one_shot`
  in `effect_json`.
- Prevent false positives where a cost reducer is mislabeled as mana ramp.

### 5. Test Scenario Grammar

Absorb the testing approach from XMage `Mage.Tests`, not the Java test runner.

Useful concepts:

- Deterministic battlefield/hand/graveyard/library setup.
- Explicit choices and targets.
- Phase-step cast scheduling.
- Assertions for zone counts, counters, life, stack, battlefield, command zone,
  and target legality.

ManaLoom use:

- Generate ManaLoom focused test skeletons for card-rule packages.
- Add a review-packet section: `suggested_test_scenarios`.
- Use this to make every promoted card prove behavior by scenario, not only by
  JSON field shape.

### 6. Commander, Partner, Background, Companion, And Command Zone Rules

Absorb validator logic as a reference checklist:

- `AbstractCommander`: 100-card/101-with-companion sizing, singleton, banned,
  partner pair, color identity, sideboard commander/companion split.
- `PartnerValidator`, `PartnerWithValidator`,
  `ChooseABackgroundValidator`, `DoctorsCompanionValidator`.
- `GameCommanderImpl`, `CommanderReplacementEffect`,
  `CommanderCostModification`, and `CommanderInfoWatcher`.

ManaLoom use:

- Build an audit-only comparison for ManaLoom deck legality and learned-deck
  partner/background metadata.
- Validate edge cases: partner, partner-with, choose-a-background, doctor's
  companion, The Prismatic Piper color choice, commander tax, command-zone
  replacement, and commander damage.
- Do not replace ManaLoom legality with XMage; use it as a source-backed
  checklist and regression test generator.

### 7. Local Deck 607 Card Queue

Use XMage local references for the current deck `607` residual high queue.

Initial local coverage:

- `Promise of Loyalty`: local XMage class exists. Model cue:
  each player chooses a creature they control, those get vow counters, the rest
  are sacrificed, chosen creatures cannot attack the source controller or their
  planeswalkers while they have vow counters.
- `Starfall Invocation`: local XMage class exists. Model cue:
  gift card condition, destroy all creatures, if gift promised return a
  creature card owned by the controller that was put into graveyard this way.
- `Pearl Medallion`: local XMage class exists. Model cue:
  static cost reduction for white spells; not mana ramp.
- `Emeria's Call // Emeria, Shattered Skyclave`: local XMage class exists.
  Model cue: modal double-faced card; front creates two 4/4 white Angel Warrior
  tokens with flying and makes non-Angel creatures indestructible until next
  turn; back is a land mode with life payment/tapped behavior.
- `The Mind Stone`: local XMage class exists. Model cue: mana rock plus
  activated sacrifice draw; likely composite support/ramp/card-flow.
- `The Scarlet Witch`: local XMage class exists. Model cue: cost modification
  pattern; needs specific local class review before rule package.
- `Thor, God of Thunder`: local search found Thor classes, but exact ManaLoom
  card name must be resolved to the correct XMage class before modeling.
- `Tragic Arrogance`: local XMage class exists. Model cue: selected permanents
  per type/controller remain, rest sacrificed; high-risk because controller
  choice and type grouping matter.
- `Molecule Man`: no exact local XMage class found in the first pass; keep
  Forge/Scryfall/manual review path.

## What We Will Not Absorb

- Do not embed XMage as a runtime dependency.
- Do not run Java XMage inside the ManaLoom simulator.
- Do not copy Java card classes wholesale into Python/Dart.
- Do not let XMage override Oracle/Scryfall text.
- Do not use XMage as a Commander deckbuilding quality/meta source.
- Do not auto-promote `generated/needs_review` rules from XMage hits.
- Do not write PostgreSQL from the harvester/indexer.

## Implementation Sequence

### Phase A - Read-Only Local XMage Indexer

Files to add:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_local_rule_indexer.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_local_rule_indexer.py`

Capabilities:

- Accept `--xmage-root /Users/desenvolvimentomobile/Downloads/mage-master`.
- Accept `--cards-file`, `--cards`, `--deck-id`, or a coherence audit JSON.
- Resolve Java class candidates by first face, no apostrophe, no punctuation,
  and class-name CamelCase.
- Extract imports, class/superclass, effect classes, target classes, filters,
  conditions, zones, counters, ability classes, and inner effect classes.
- Emit JSON/MD only.

Evidence:

- Unit tests with fixture Java snippets.
- Live deck `607` top high queue index artifact.
- `mutations_performed=[]`.

### Phase B - Upgrade External Harvester

Files to modify:

- `external_card_rule_reference_harvester.py`
- `test_external_card_rule_reference_harvester.py`

Changes:

- Prefer local XMage index when `--xmage-root` exists.
- Keep network fallback optional.
- Add `xmage_local` block with structural signals.
- Add `suggested_test_scenarios`.
- Keep all candidate rules marked `external_reference_candidate`.

Evidence:

- Harvester tests.
- Live deck `607` artifact using local XMage.

### Phase C - Candidate Effect Translator

Files to add or extend:

- `xmage_to_manaloom_effect_hints.py`
- tests for effect/target/condition mapping.

Output:

- `candidate_effect_json`
- `confidence_reason`
- `requires_runtime_executor`
- `requires_manual_review`
- `suggested_battle_model_scope`
- `suggested_tests`

Important:

- This translator is a reviewer assistant, not a promoter.
- It may downgrade candidate confidence if Oracle text and XMage structure
  disagree.

### Phase D - Focused Test Skeleton Generator

Files to add:

- `xmage_reference_test_scenario_builder.py`
- tests with fixture XMage snippets.

Output:

- Markdown test plan.
- Optional Python test skeleton snippet for `battle_card_specific_tests.py`.

Use:

- Create scenario drafts for `Promise of Loyalty`, `Starfall Invocation`,
  `Pearl Medallion`, `Emeria's Call`, and `Tragic Arrogance`.

### Phase E - Deck 607 Package Work

Order:

1. `Pearl Medallion` first if we want a lower-risk proof of the XMage-local
   pipeline: classify as cost reducer/static support, not mana ramp.
2. `Promise of Loyalty`: new runtime behavior likely required for vow counter,
   each-player choice, sacrifice-rest, and attack restriction.
3. `Starfall Invocation`: new runtime behavior likely required for gift and
   destroyed-this-way graveyard return.
4. `Emeria's Call`: MDFC/token/indestructible-until-next-turn handling.
5. `Tragic Arrogance`: high-risk selective sacrifice by permanent type.
6. `The Mind Stone`, `The Scarlet Witch`, `Thor` after exact class resolution.
7. `Molecule Man` stays manual/Forge/Scryfall unless a local XMage equivalent
   is found.

Each package must include:

- Oracle/Scryfall text and hash.
- XMage local index evidence.
- Candidate `effect_json`.
- Focused runtime test or explicit reason no runtime executor is needed.
- Dry-run SQL package if PostgreSQL needs a rule update.
- Precheck/apply/rollback/postcheck only when approved for PostgreSQL write.
- PG -> SQLite/canonical sync if applied.
- Deck-card coherence audit after sync.
- Register update.

### Phase F - Commander Legality/Partner Audit

Files to add:

- `xmage_commander_legality_reference_audit.py`
- tests with fixture commander metadata.

Purpose:

- Compare ManaLoom learned-deck/deck validation logic against XMage's
  commander checklist for partner/background/companion and command-zone edge
  cases.
- Emit read-only findings only.

Do not:

- Replace product legality with XMage.
- Mutate learned decks or PostgreSQL from this audit.

## Gates Before Any Promotion

A card is not closed until all relevant gates pass:

- Oracle/Scryfall current text confirmed.
- Existing PostgreSQL row state known.
- XMage local reference captured when available.
- ManaLoom effect model reviewed.
- Focused test scenario generated from the XMage/Oracle reference.
- Focused unit test/replay proves behavior.
- `deck_card_battle_rule_coherence_audit` drops the real finding.
- PostgreSQL writes use precheck/apply/rollback/postcheck and explicit
  approval.
- Registers updated with artifact paths and counts.

## Immediate Next Command Set

Suggested next read-only implementation slice:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_local_rule_indexer.py \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --coherence-report docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_pg107_post_20260623_143808.json \
  --limit 9 \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_local_rule_index_deck607_pg107_high_20260623
```

Then run:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_local_rule_indexer.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_external_card_rule_reference_harvester.py
```

## Expected Benefit

- Faster card-rule review because target/effect/condition structure is pulled
  from existing implementations instead of rediscovered manually.
- Fewer wrong effect categories, especially cost reducers versus ramp,
  one-shot versus static, and target shape.
- Better focused tests because XMage tests and implementation structure expose
  the expected zones, choices, counters, and final state.
- Cleaner PostgreSQL packages because each candidate rule has an external
  reference packet before apply.

## Risks

- XMage can be stale or wrong. Oracle/Scryfall remains authoritative.
- Static/trigger/replacement effects can look simple in class names but require
  real runtime support.
- Java parsing by regex is enough for review packets, not for proof of
  correctness. The gate remains ManaLoom tests/replay.
- Some Universes Beyond cards may have naming mismatches. Class resolution must
  preserve exact source path and confidence.

## Phase G - Semantic Family Batch Pipeline Implemented - 2026-06-23

Status: `implemented_read_only_artifact_pipeline`.

New scripts:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_effect_json_batch_generator.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`

Purpose:

- Stop treating the backlog as thousands of independent card tasks.
- Turn card-level XMage evidence into family-level work units.
- Generate reviewed `effect_json`/`deck_role_json`/`logical_rule_key`
  proposals in batch.
- Build approval-gated SQL package previews from safe proposals without
  executing SQL.

Deck 607 high/medium run:

- Family classification artifact:
  `docs/hermes-analysis/master_optimizer_reports/xmage_semantic_family_classification_deck607_20260623_152813.json`
  and `.md`.
- Effect proposal artifact:
  `docs/hermes-analysis/master_optimizer_reports/xmage_effect_json_batch_proposals_deck607_20260623_152951.json`
  and `.md`.
- Static-cost batch-builder preview:
  `docs/hermes-analysis/master_optimizer_reports/xmage_batch_pg_preview_static_cost_reducer_deck607_20260623_152951_manifest.json`
  and package/sql files with the same prefix.

Result:

- `13` cards classified into `8` semantic families.
- `4` cards are batch metadata candidates after PG precheck:
  `Pearl Medallion`, `The Scarlet Witch`, `Bender's Waterskin`,
  `Victory Chimes`.
- `7` cards require runtime-family implementation before metadata batching:
  `Promise of Loyalty`, `Starfall Invocation`,
  `Emeria's Call // Emeria, Shattered Skyclave`, `The Mind Stone`,
  `Tragic Arrogance`, `Monument to Endurance`, `Surge to Victory`.
- `2` cards remain blocked by missing exact XMage source:
  `Molecule Man`, `Thor, God of Thunder`.

Important correction:

- The batch proposal generator now merges external/Scryfall evidence with
  XMage-local hints and derives `cmc` from mana cost, so generated logical keys
  match reviewed packages. Confirmed examples:
  `Pearl Medallion` -> `battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2`;
  `The Scarlet Witch` -> `battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc`.

Boundary:

- The static-cost preview package is proof of family batching only. It must not
  be applied over PG108/PG110 unless those individual packages are explicitly
  abandoned/replaced and the operator approves the exact command.
- No PostgreSQL write, deck swap, commit, push, stash, revert, LaunchAgent
  change, or artifact deletion was executed by this phase.

## Phase H - Engine Absorption Inventory - 2026-06-23

Status: `implemented_read_only_engine_inventory`.

Purpose:

- Revalidate the whole local XMage checkout, not only exact per-card classes.
- Identify which XMage layers can accelerate ManaLoom safely.
- Separate useful rule/test contracts from a risky whole-engine port.

New scripts:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_engine_absorption_inventory.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_engine_absorption_inventory.py`

Artifacts:

- `docs/hermes-analysis/master_optimizer_reports/xmage_engine_absorption_inventory_20260623.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_engine_absorption_inventory_20260623.md`

External sanity check:

- The official `magefree/mage` repository describes XMage as a full-rules
  engine with more than `31,000` unique cards. The local checkout remains the
  source analyzed by this phase; the web check only confirms that the project
  is an appropriate active reference corpus.

Inventory result:

- XMage Java files scanned: `38,739`.
- Card implementation files: `31,706`.
- Core engine files under `Mage/src/main/java/mage`: `3,688`.
- Effect files: `802`.
- Target files: `84`.
- Filter files: `207`.
- Watcher files: `87`.
- XMage test files: `2,009`.
- `GameEvent.EventType` values indexed: `311`.
- Full JSON catalogs now include effect, target, filter, watcher, cost,
  dynamic value, and condition classes.

Reusable class-family evidence:

- Effect token count: `799`.
- Ability token count: `686`.
- Target token count: `84`.
- Filter/predicate token count: `68` filters and `141` predicates.
- Watcher token count: `87`.
- Cost token count: `107`.
- Dynamic value token count: `43`.
- Condition token count: `214`.

XMage test-corpus evidence:

- `addCard`: `24,540` usages.
- `castSpell`: `6,719` usages.
- `execute`: `6,490` usages.
- `setChoice`: `4,122` usages.
- `activateAbility`: `2,042` usages.
- `waitStackResolved`: `1,402` usages.
- `checkPlayableAbility`: `997` usages.
- `checkPermanentCount`: `601` usages.
- `checkStackObject`: `83` usages.

Operational conclusion:

- Do not port XMage wholesale into ManaLoom now. That would couple a Java rules
  engine into the Python/Hermes/PostgreSQL battle flow and slow the current
  deck-gate work.
- Do use XMage as a local rule/test corpus:
  1. exact card class -> effect/cost/target signal;
  2. effect-class taxonomy -> batch `effect_json` templates;
  3. XMage test corpus -> focused ManaLoom scenario candidates;
  4. priority/stack/turn files -> conformance tests for response windows,
     stack copies, pass priority, and state-based action loops;
  5. `GameEvent` + watchers -> event-contract coverage;
  6. `Target`/`Filter`/`Predicate` -> explicit target legality constraints;
  7. Commander validators -> read-only partner/background cross-check.

Validation:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_engine_absorption_inventory.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_engine_absorption_inventory.py`:
  exit `0`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_engine_absorption_inventory.py`:
  `Ran 3 tests OK`.
- Real XMage inventory command:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_engine_absorption_inventory.py --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master --output-json docs/hermes-analysis/master_optimizer_reports/xmage_engine_absorption_inventory_20260623.json --output-md docs/hermes-analysis/master_optimizer_reports/xmage_engine_absorption_inventory_20260623.md`.

Next implementation order:

1. Build an XMage test-miner that finds exact card-name tests and emits
   ManaLoom focused scenario candidates.
2. Extend the XMage effect mapper from the full effect/cost/target/filter
   catalogs, starting with deck `607` runtime families.
3. Add stack/priority contract tests only where battle gates need them; do not
   chase full XMage parity before closing concrete card-rule families.

## Phase I - XMage Test Scenario Miner - 2026-06-23

Status: `implemented_read_only_test_miner`.

New scripts:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_test_scenario_miner.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_test_scenario_miner.py`

Artifacts:

- `docs/hermes-analysis/master_optimizer_reports/xmage_test_scenario_miner_deck607_board_wipe_choice_20260623.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_test_scenario_miner_deck607_board_wipe_choice_20260623.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_test_scenario_miner_deck607_high_medium_20260623.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_test_scenario_miner_deck607_high_medium_20260623.md`

Validation:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_test_scenario_miner.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_test_scenario_miner.py`:
  exit `0`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_test_scenario_miner.py`:
  `Ran 3 tests OK`.

Deck `607` board-wipe-choice test mining:

- Cards scanned: `Promise of Loyalty`, `Starfall Invocation`,
  `Tragic Arrogance`.
- XMage test files scanned: `2,009`.
- Exact test references found: `0/3`.
- Usable scenario candidates: `0`.

Deck `607` full high/medium test mining:

- Cards scanned: `13`.
- XMage test files scanned: `2,009`.
- Exact test references found: `2/13`.
- Usable scenario candidates: `1`.
- `Emeria's Call // Emeria, Shattered Skyclave` has a usable reference in
  `Mage.Tests/src/test/java/org/mage/test/cards/cost/modaldoublefaced/ModalDoubleFacedCardsTest.java`
  method `test_PlayFromNonHand_GraveyardByFlashback`.
- `Pearl Medallion` appears in
  `Mage.Tests/src/test/java/org/mage/test/cards/abilities/keywords/DisturbTest.java`
  method `test_ConditionalCostModifications`, but the mined shape has no
  assertion commands, so it is not a direct ManaLoom focused-test candidate.

Operational conclusion:

- XMage test mining is useful but not sufficient for the current deck `607`
  high/medium queue.
- The primary accelerator remains exact XMage class + effect/cost/target
  taxonomy + generated ManaLoom focused tests.
- For `board_wipe_choice`, ManaLoom should generate new focused tests from
  Oracle/XMage class structure because the local XMage test corpus has no exact
  tests for those three cards.
