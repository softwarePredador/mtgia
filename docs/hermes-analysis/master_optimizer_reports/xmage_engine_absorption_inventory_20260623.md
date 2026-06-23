# XMage Engine Absorption Inventory

- Generated at: `2026-06-23T18:41:56+00:00`
- Status: `ready`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- Mutations performed: `[]`

## Summary

- `card_implementation_files`: `31706`
- `core_engine_files`: `3688`
- `effect_files`: `802`
- `filter_files`: `207`
- `java_files_total`: `38739`
- `target_files`: `84`
- `test_files`: `2009`
- `watcher_files`: `87`

## Absorption Facets

### card_implementations

- Java files: `31706`
- Adoption: `keep_current_fast_path_and_batch_by_semantic_family`
- Why: Per-card implementation classes are the fastest exact reference for card behavior.
- ManaLoom use: Resolve card -> XMage class, extract effect/cost/target signals, then gate with ManaLoom tests and PG precheck.
- Sample classes: `AAT1, AAT1TriggeredAbility, AIMBot, AIMLabs, AIMScientists, AIMSynthoids, AJedisFervor, AJedisFervorEffect, AKillerAmongUs, AKillerAmongUsCost, AKillerAmongUsEffect, ALittleChat`

### effect_library

- Java files: `802`
- Adoption: `high_impact_immediate`
- Why: XMage's effect classes are reusable vocabulary for destroy, exile, copy, token, draw, prevention, replacement, and continuous effects.
- ManaLoom use: Build an effect-class taxonomy and map frequent classes to ManaLoom effect_json templates.
- Sample classes: `AbilitiesCostReductionControllerEffect, ActivateAbilitiesAnyTimeYouCouldCastInstantEffect, AdaptEffect, AddBasicLandTypeAllLandsEffect, AddCardColorAttachedEffect, AddCardSubTypeSourceEffect, AddCardSubTypeTargetEffect, AddCardSubtypeAllEffect, AddCardSubtypeAttachedEffect, AddCardSuperTypeAttachedEffect, AddCardTypeAttachedEffect, AddCardTypeSourceEffect`

### ability_timing

- Java files: `588`
- Adoption: `high_impact_immediate`
- Why: Ability classes encode static/triggered/activated/mana/timing semantics.
- ManaLoom use: Use ability classes to classify runtime executor families and focused test setup.
- Sample classes: `ActivateAbilityTriggeredAbility, ActivateAsSorceryActivatedAbility, ActivateAsSorceryManaAbility, ActivateIfConditionActivatedAbility, ActivateIfConditionManaAbility, ActivateOncePerGameActivatedAbility, ActivateOnlyByOpponentActivatedAbility, ActivatePlaneswalkerLoyaltyAbilityTriggeredAbility, ActivatedAbilityConditionalMana, ActivatedAbilityManaBuilder, ActivatedAbilityManaCondition, ActivatedManaAbilityImpl`

### costs_and_cost_adjusters

- Java files: `130`
- Adoption: `high_impact_immediate`
- Why: Cost reducers, alternate costs, additional costs, X costs, and payment restrictions are common high-severity blockers.
- ManaLoom use: Map XMage cost adjusters/effects to explicit ManaLoom cost contracts instead of one-off card patches.
- Sample classes: `AbilitiesCostReductionControllerEffect, ActivationManaAbilityStep, AlternateManaPaymentAbility, AlternativeCost, AlternativeCostImpl, AlternativeCostSourceAbility, AlternativeSourceCosts, AlternativeSourceCostsImpl, BeholdAndExileCost, BeholdCost, BlightCost, CastFromHandForFreeEffect`

### targets_filters_predicates

- Java files: `291`
- Adoption: `high_impact_immediate`
- Why: Target and filter classes encode legality and scope, which are frequent sources of false confidence.
- ManaLoom use: Generate target constraints, legality checks, and focused target revalidation tests.
- Sample classes: `AbilityPredicate, AbilitySourceAttachedPredicate, AbilityTypePredicate, AbilityZonePredicate, ActivatedOrTriggeredAbilityPredicate, ActivePlayerPredicate, AdventurePredicate, AndPredicate, AnotherCreatureOrAnArtifactPredicate, AnotherEnchantedPredicate, AnotherPredicate, AnotherTargetPredicate`

### dynamic_values_conditions

- Java files: `331`
- Adoption: `medium_high_impact`
- Why: Dynamic values and conditions explain variable damage, counts, controller choices, thresholds, and conditional modes.
- ManaLoom use: Attach conditional fields to effect_json and generate edge-case assertions.
- Sample classes: `APlayerHas13LifeCondition, AbilityResolutionCount, AdamantCondition, AddendumCondition, AdditiveDynamicValue, AfterBlockersAreDeclaredCondition, AfterCombatCondition, AfterUpkeepStepCondtion, AnyPlayerControlsCondition, ArtifactEnteredUnderYourControlCondition, ArtifactYouControlCount, AttachedAttackingCondition`

### watchers_replacement_prevention

- Java files: `239`
- Adoption: `high_impact_after_effect_taxonomy`
- Why: Watchers, replacement, prevention, and continuous rule-modifying effects are where many battle-runtime lineage gaps originate.
- ManaLoom use: Use as an event-contract and state-memory reference, especially for first spell, damage, draw, discard, replacement, and prevention.
- Sample classes: `AbilityResolvedWatcher, ActivateAbilitiesAnyTimeYouCouldCastInstantEffect, AddBasicLandTypeAllLandsEffect, AddCardColorAttachedEffect, AddCardSubTypeSourceEffect, AddCardSubTypeTargetEffect, AddCardSubtypeAllEffect, AddCardSubtypeAttachedEffect, AddCardSuperTypeAttachedEffect, AddCardTypeAttachedEffect, AddCardTypeSourceEffect, AddCardTypeTargetEffect`

### game_events_state

- Java files: `89`
- Adoption: `high_impact_for_battle_gate`
- Why: Game events and state application define what a replay/audit should be able to observe.
- ManaLoom use: Compare ManaLoom event contracts to XMage event taxonomy and close static event-contract gaps in batches.
- Sample classes: `AttachEvent, AttachedEvent, AttackerDeclaredEvent, BatchEvent, BlockerDeclaredEvent, CoinFlippedEvent, ConditionOnToken, CopiedStackObjectEvent, CopyStackObjectEvent, CounterRemovedEvent, CountersRemovedEvent, CreateTokenEvent`

### priority_stack_turn_engine

- Java files: `29`
- Adoption: `contract_reference_not_full_port`
- Why: Priority, phase/step order, stack resolution, passed-priority flags, and SBA loops define correctness of non-goldfish tests.
- ManaLoom use: Use as conformance spec for stack/priority tests; do not port the whole engine blindly.
- Sample classes: `ApprovingObjectResult, ApprovingObjectResultStatus, BeginCombatStep, BeginningPhase, CleanupStep, CombatDamageStep, CombatPhase, DeclareAttackersStep, DeclareBlockersStep, DrawStep, EndOfCombatStep, EndPhase`

### commander_legality

- Java files: `7`
- Adoption: `reference_cross_check`
- Why: XMage has Commander, partner, background, companion-style validator references and command-zone handling.
- ManaLoom use: Use as a cross-check for partner/background and command-zone metadata, not as PostgreSQL source of truth.
- Sample classes: `ChooseABackgroundValidator, CommanderValidator, DoctorsCompanionValidator, GameCommanderImpl, PartnerValidator, PartnerVariantValidator, PartnerWithValidator`

### test_scenario_corpus

- Java files: `2009`
- Adoption: `very_high_impact_for_scaling`
- Why: XMage tests contain a mature scenario grammar for addCard/castSpell/activateAbility/setChoice/waitStackResolved/check* assertions.
- ManaLoom use: Mine matching card tests and convert their scenario shape into focused ManaLoom replay/unit tests.
- Sample classes: `AKillerAmongUsTest, AatchikEmeraldRadianTest, AbaddonTheDespoilerTest, AbandonedSarcophagusTest, AbattoirGhoulTest, AbilityOwnershipTest, AbilityPickerTest, AbolethSpawnTest, AbstruseAppropriationTest, AbuelosAwakeningTest, AcademyManufactorTest, AcceleratedMutationTest`

### ai_heuristics

- Java files: `10`
- Adoption: `later_reference`
- Why: XMage AI can inform targeting/play-priority heuristics but is less directly portable than rules/tests.
- ManaLoom use: Reference after rules correctness improves; avoid blocking card-rule work on AI parity.
- Missing paths: `['Mage.Server.Plugins/Mage.Player.AI.MCTS', 'Mage.Server.Plugins/Mage.Player.AI.Minimax']`
- Sample classes: `ArtificialScoringSystem, Attackers, CombatEvaluator, ComputerPlayer, GameStateEvaluator2, MagicAbility, PermanentComparator, PermanentEvaluator, PickedCard, PlayerEvaluateScore, PossibleTargetsComparator, PossibleTargetsSelector`

## Engine Evidence

- `Mage/src/main/java/mage/game/Game.java`: lines `828`, classes `['Game']`
  - keyword hits: priority_stack=5, state_based_actions=1, effects_layers=6, events_watchers=3, replacement_prevention=4, target_legality=5, commander=45, test_dsl=19
- `Mage/src/main/java/mage/game/GameImpl.java`: lines `4270`, classes `['GameImpl']`
  - keyword hits: priority_stack=42, state_based_actions=18, effects_layers=41, events_watchers=82, replacement_prevention=15, target_legality=76, costs=1, commander=44, test_dsl=89
- `Mage/src/main/java/mage/game/GameState.java`: lines `1758`, classes `['GameState', 'ZoneChangeData']`
  - keyword hits: priority_stack=5, effects_layers=26, events_watchers=37, replacement_prevention=4, target_legality=33, commander=14, test_dsl=15
- `Mage/src/main/java/mage/game/GameCommanderImpl.java`: lines `292`, classes `['GameCommanderImpl']`
  - keyword hits: state_based_actions=3, events_watchers=15, replacement_prevention=2, target_legality=11, commander=95, test_dsl=17
- `Mage/src/main/java/mage/game/turn/Turn.java`: lines `404`, classes `['Turn']`
  - keyword hits: priority_stack=5, state_based_actions=1, events_watchers=1, test_dsl=9
- `Mage/src/main/java/mage/game/turn/Phase.java`: lines `281`, classes `['Phase']`
  - keyword hits: priority_stack=2, events_watchers=2, replacement_prevention=1, test_dsl=12
- `Mage/src/main/java/mage/game/turn/Step.java`: lines `97`, classes `['Step', 'StepPart']`
  - keyword hits: priority_stack=1, events_watchers=2, replacement_prevention=1
- `Mage/src/main/java/mage/game/stack/SpellStack.java`: lines `170`, classes `['SpellStack']`
  - keyword hits: priority_stack=17, events_watchers=3, replacement_prevention=1
- `Mage/src/main/java/mage/game/stack/Spell.java`: lines `1278`, classes `['Spell']`
  - keyword hits: priority_stack=13, state_based_actions=1, target_legality=35, costs=21, test_dsl=5
- `Mage/src/main/java/mage/game/stack/StackObject.java`: lines `51`, classes `['StackObject']`
  - keyword hits: priority_stack=5, target_legality=14
- `Mage/src/main/java/mage/players/Player.java`: lines `1281`, classes `['PayLifeCostRestriction', 'Player', 'SurveilResult']`
  - keyword hits: priority_stack=1, effects_layers=1, events_watchers=2, replacement_prevention=3, target_legality=24, costs=28, commander=7, test_dsl=10
- `Mage/src/main/java/mage/players/PlayerImpl.java`: lines `5750`, classes `['ApprovingObjectResult', 'ApprovingObjectResultStatus', 'PlayerImpl', 'RollDieResult']`
  - keyword hits: priority_stack=21, effects_layers=22, events_watchers=77, replacement_prevention=32, target_legality=175, costs=132, commander=22, test_dsl=36
- `Mage/src/main/java/mage/game/events/GameEvent.java`: lines `950`, classes `['EventType', 'GameEvent']`
  - keyword hits: replacement_prevention=1, target_legality=2, test_dsl=7
- `Mage/src/main/java/mage/watchers/Watcher.java`: lines `128`, classes `['Watcher']`
  - keyword hits: events_watchers=12, target_legality=1
- `Mage/src/main/java/mage/watchers/Watchers.java`: lines `54`, classes `['Watchers']`
  - keyword hits: events_watchers=15
- `Mage/src/main/java/mage/util/validation/CommanderValidator.java`: lines `21`, classes `['CommanderValidator']`
  - keyword hits: commander=15, test_dsl=4
- `Mage/src/main/java/mage/util/validation/PartnerValidator.java`: lines `16`, classes `['PartnerValidator']`
  - keyword hits: commander=8, test_dsl=1
- `Mage.Tests/src/test/java/org/mage/test/player/TestPlayer.java`: lines `4703`, classes `['TestPlayer']`
  - keyword hits: priority_stack=33, events_watchers=7, replacement_prevention=2, target_legality=363, costs=18, commander=15, test_dsl=213

## Effect And Rule Taxonomy

- `effects`: `{'Effect': 784, 'Effects': 2}`
- `abilities`: `{'Ability': 631}`
- `targets`: `{'Target': 3}`
- `filters`: `{'Filter': 1, 'Predicate': 140}`
- `watchers`: `{'Watcher': 86, 'Watchers': 1}`
- `costs`: `{'Cost': 88, 'Costs': 5, 'CostAdjuster': 4}`
- `dynamic_values`: `{'Value': 42}`
- `conditions`: `{'Condition': 213}`
- `effects` token counts: `{'Effect': 799}`
- `abilities` token counts: `{'Ability': 686}`
- `targets` token counts: `{'Target': 84}`
- `filters` token counts: `{'Filter': 68, 'Predicate': 141}`
- `watchers` token counts: `{'Watcher': 87}`
- `costs` token counts: `{'Cost': 107}`
- `dynamic_values` token counts: `{'Value': 43}`
- `conditions` token counts: `{'Condition': 214}`

### Effect Package Meanings

- `asthought`: cast/play permissions such as flash or alternate-zone casting
- `combat`: attack/block restrictions, evasion, combat taxes, and combat permissions
- `continuous`: continuous rules, type/color/control changes, replacement-like rule modifiers
- `cost`: cost increases, reductions, alternate or special cost handling
- `counter`: counter placement, removal, proliferation, and counter conditions
- `discard`: discard actions and discard-trigger helpers
- `enterAttribute`: as-enters choices and permanent entry attributes
- `replacement`: event replacement and prevention-style effects
- `ruleModifying`: can't/can/cast/play/search/target rule modifiers
- `search`: library search and tutor-style effects
- `turn`: extra turns, skip steps, end turn, and turn-modifying effects
- `mana`: mana-production effects
- `keyword`: keyword-specific effect helpers

## Event And Test Corpus

- Game event types: `311` from `Mage/src/main/java/mage/game/events/GameEvent.java`
- Event sample: `ACTIVATED_ABILITY, ACTIVATE_ABILITY, ADAPT, ADD_COUNTER, ADD_COUNTERS, ADD_MANA, AIRBENDED, ATTACH, ATTACHED, ATTACKER_DECLARED, AT_END_OF_TURN, BATCH_BLOCK_NONCOMBAT, BATCH_FIGHT, BECOMES_DAY_NIGHT, BECOMES_EXERTED, BECOMES_MONARCH, BECOMES_MONSTROUS, BECOMES_RENOWNED, BECOME_MONARCH, BECOME_PLOTTED, BECOME_SUSPECTED, BEGINNING, BEGINNING_PHASE, BEGINNING_PHASE_EXTRA, BEGINNING_PHASE_POST, BEGINNING_PHASE_POST_EXTRA, BEGINNING_PHASE_PRE, BEGINNING_PHASE_PRE_EXTRA, BEGIN_COMBAT_STEP, BEGIN_COMBAT_STEP_POST, BEGIN_COMBAT_STEP_PRE, BEGIN_TURN, BLOCKER_DECLARED, BUT, CAN_ADD_COUNTERS`
- Test command usage: `{'addCard': 24540, 'castSpell': 6719, 'execute': 6490, 'setChoice': 4122, 'activateAbility': 2042, 'waitStackResolved': 1402, 'checkPlayableAbility': 997, 'checkPermanentCount': 601, 'checkLife': 195, 'checkStackObject': 83}`

## Recommendations

- `P0` Do not port XMage wholesale. Keep XMage as reference corpus and mine stable contracts into ManaLoom runtime/tests.
- `P0` Promote effect-class taxonomy before more card-by-card work. Extend xmage_to_manaloom_effect_hints.py using the inventory's effect packages and suffix counts.
- `P0` Mine XMage tests into focused ManaLoom scenarios. Add a local test-miner that finds card-name tests and emits ManaLoom scenario candidates.
- `P1` Use priority/stack/turn classes as conformance reference. Create ManaLoom stack/priority contract tests for pass priority, response windows, stack copies, and SBA loops.
- `P1` Use GameEvent/Watcher taxonomy for event-contract coverage. Compare ManaLoom event_contract_static taxonomy against XMage GameEvent.EventType and watcher families.
- `P1` Use target/filter/predicate classes to harden effect_json target constraints. Map common Target*/Filter*/Predicate* classes to explicit target_scope and valid_zone fields.
- `P2` Use Commander validators as cross-check only. Keep a read-only commander legality audit and do not let XMage overwrite PG metadata.
- `P3` Defer XMage AI heuristic absorption. Reference AI packages only after runtime rule gates stabilize.
