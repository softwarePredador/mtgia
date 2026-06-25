# Lorehold Ideal Deck Workflow

Status: current canonical workflow for Lorehold deck improvement.

## Decision

Do not try to pick the ideal Lorehold deck directly from XMage, raw WR, or the
old hardcoded builder.

Use a two-stage flow:

1. Close rule confidence for every card that touches Lorehold.
2. Benchmark only the rule-ready candidates through the safe master optimizer
   flow.

XMage is the rules/reference corpus. It tells ManaLoom how a card can be
modeled and tested. It is not the strategic deck oracle by itself.

## Active Tooling

Primary matrix generator:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_ideal_deck_candidate_matrix.py \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260624_v1
```

Current generated evidence:

- initial matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260624_v1.json`
- current post-PG191 Lorehold-focused matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260624_pg191_invoke_calamity_postsync_lorehold_v1.json`
- current post-PG191 strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260624_pg191_invoke_calamity_postsync_v1.json`
- current post-PG191 effective queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260624_pg191_invoke_calamity_postsync_v1.json`

The script reads:

- active Lorehold deck `6`;
- prior Lorehold variants `606` and `607`;
- new Lorehold variants `608` through `616`;
- expanded opponent/non-Lorehold comparison decks `58`, `74`, `105`, and
  `617` through `619`;
- current XMage proposal report
  `xmage_current_replay_batch_pipeline_20260624_pg191_invoke_calamity_postsync_v1_proposals.json`;
- Hermes SQLite battle-rule cache for rule readiness.

It does not mutate deck rows, SQLite, or PostgreSQL.

## Current Matrix Result

Initial matrix generated on 2026-06-24:

- total Lorehold-touching cards in matrix: `395`;
- `core_keep`: `87`;
- `priority_benchmark_candidate`: `35`;
- `watchlist_candidate`: `88`;
- `needs_rule_before_strategy`: `127`;
- `active_low_confidence_review`: `13`;
- `low_priority`: `43`;
- `policy_blocked`: `2`.

Rule-readiness split:

- `battle_ready`: `268`;
- `mapper_manual`: `88`;
- `split_scope`: `26`;
- `runtime_needed`: `11`;
- `no_rule_signal`: `2`.

Post-PG185 matrix generated on 2026-06-24 after closing `Fury Storm`:

- total Lorehold-touching cards in matrix: `395`;
- `core_keep`: `87`;
- `priority_benchmark_candidate`: `36`;
- `watchlist_candidate`: `88`;
- `needs_rule_before_strategy`: `126`;
- `active_low_confidence_review`: `13`;
- `low_priority`: `43`;
- `policy_blocked`: `2`.

Post-PG185 rule-readiness split:

- `battle_ready`: `269`;
- `mapper_manual`: `88`;
- `split_scope`: `25`;
- `runtime_needed`: `11`;
- `blocked_missing_xmage_source`: `2`.

PG185 closure evidence:

- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/pg185_fury_storm_copy_spell_package.md`;
- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg185_fury_storm_20260624.json`;
- affected deck audit:
  `docs/hermes-analysis/master_optimizer_reports/deck612_battle_rule_coherence_pg185_postsync_20260624.json`;
- final pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_manifest.json`;
- strategy consistency:
  `18/18` pass.

Post-PG186 expanded matrix generated on 2026-06-24 after closing
`Lightning Helix` and including decks `6`, `58`, `74`, `105`, and `606` through
`619`:

- total scoped cards in matrix: `709`;
- `core_keep`: `91`;
- `priority_benchmark_candidate`: `65`;
- `watchlist_candidate`: `180`;
- `needs_rule_before_strategy`: `252`;
- `active_low_confidence_review`: `9`;
- `low_priority`: `109`;
- `policy_blocked`: `3`.

Post-PG186 rule-readiness split:

- `battle_ready`: `457`;
- `mapper_manual`: `163`;
- `split_scope`: `61`;
- `runtime_needed`: `21`;
- `blocked_missing_xmage_source`: `4`;
- `no_rule_signal`: `3`.

PG186 closure evidence:

- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/pg186_lightning_helix_damage_lifegain_package.md`;
- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg186_lightning_helix_20260624.json`;
- affected deck audit:
  `docs/hermes-analysis/master_optimizer_reports/deck616_battle_rule_coherence_pg186_postsync_20260624.json`;
- final pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg186_lightning_helix_postsync_v2_manifest.json`;
- strategy consistency:
  `18/18` pass.

Post-PG187 expanded matrix generated on 2026-06-24 after closing
`Caldera Pyremaw`:

- total scoped cards in matrix: `709`;
- `core_keep`: `91`;
- `priority_benchmark_candidate`: `65`;
- `watchlist_candidate`: `181`;
- `needs_rule_before_strategy`: `251`;
- `active_low_confidence_review`: `9`;
- `low_priority`: `109`;
- `policy_blocked`: `3`.

Post-PG187 rule-readiness split:

- `battle_ready`: `458`;
- `mapper_manual`: `163`;
- `split_scope`: `60`;
- `runtime_needed`: `21`;
- `blocked_missing_xmage_source`: `4`;
- `no_rule_signal`: `3`.

PG187 closure evidence:

- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/pg187_caldera_pyremaw_spellcast_damage_package.md`;
- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg187_caldera_pyremaw_20260624.json`;
- affected deck audit:
  `docs/hermes-analysis/master_optimizer_reports/deck614_battle_rule_coherence_pg187_postsync_20260624.json`;
- final pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg187_caldera_pyremaw_postsync_v1_manifest.json`;
- strategy consistency:
  `18/18` pass.

Post-PG188 Lorehold-focused matrix generated on 2026-06-24 after closing
`Pyromancer Ascension` for deck `608`:

- total Lorehold scoped cards in matrix: `395`;
- `core_keep`: `87`;
- `priority_benchmark_candidate`: `37`;
- `watchlist_candidate`: `90`;
- `needs_rule_before_strategy`: `123`;
- `active_low_confidence_review`: `13`;
- `low_priority`: `43`;
- `policy_blocked`: `2`.

Post-PG188 rule-readiness split:

- `battle_ready`: `272`;
- `mapper_manual`: `88`;
- `split_scope`: `22`;
- `runtime_needed`: `11`;
- `blocked_missing_xmage_source`: `2`.

PG188 closure evidence:

- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/pg188_pyromancer_ascension_quest_copy_package.md`;
- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg188_pyromancer_ascension_20260624.json`;
- affected deck audit:
  `docs/hermes-analysis/master_optimizer_reports/deck608_battle_rule_coherence_pg188_postsync_20260624.json`;
- final pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg188_pyromancer_ascension_postsync_v1_manifest.json`;
- strategy consistency:
  `18/18` pass.

Post-PG189 Lorehold-focused matrix generated on 2026-06-24 after closing
`Profound Journey` for deck `611`:

- total Lorehold scoped cards in matrix: `395`;
- `core_keep`: `87`;
- `priority_benchmark_candidate`: `37`;
- `watchlist_candidate`: `91`;
- `needs_rule_before_strategy`: `122`;
- `active_low_confidence_review`: `13`;
- `low_priority`: `43`;
- `policy_blocked`: `2`.

Post-PG189 rule-readiness split:

- `battle_ready`: `273`;
- `mapper_manual`: `88`;
- `split_scope`: `21`;
- `runtime_needed`: `11`;
- `blocked_missing_xmage_source`: `2`.

PG189 closure evidence:

- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/pg189_profound_journey_rebound_recursion_package.md`;
- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg189_profound_journey_20260624.json`;
- affected deck audit:
  `docs/hermes-analysis/master_optimizer_reports/deck611_battle_rule_coherence_pg189_postsync_20260624.json`;
- final pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg189_profound_journey_postsync_v1_manifest.json`;
- strategy consistency:
  `18/18` pass.

Post-PG190 Lorehold-focused matrix generated on 2026-06-24 after closing
`Cool but Rude` for decks `608` and `613`:

- total Lorehold scoped cards in matrix: `395`;
- `core_keep`: `87`;
- `priority_benchmark_candidate`: `38`;
- `watchlist_candidate`: `91`;
- `needs_rule_before_strategy`: `121`;
- `active_low_confidence_review`: `13`;
- `low_priority`: `43`;
- `policy_blocked`: `2`.

Post-PG190 rule-readiness split:

- `battle_ready`: `274`;
- `mapper_manual`: `88`;
- `split_scope`: `20`;
- `runtime_needed`: `11`;
- `blocked_missing_xmage_source`: `2`.

PG190 closure evidence:

- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/pg190_cool_but_rude_class_rummage_package.md`;
- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg190_cool_but_rude_20260624.json`;
- affected deck audits:
  `docs/hermes-analysis/master_optimizer_reports/deck608_battle_rule_coherence_pg190_cool_but_rude_postsync_v1.json`
  and
  `docs/hermes-analysis/master_optimizer_reports/deck613_battle_rule_coherence_pg190_cool_but_rude_postsync_v1.json`;
- final pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg190_cool_but_rude_postsync_v1_manifest.json`;
- strategy consistency:
  `18/18` pass.

Post-PG191 Lorehold-focused matrix generated on 2026-06-24 after closing
`Invoke Calamity` for decks `609`, `614`, `615`, and `616`:

- total Lorehold scoped cards in matrix: `395`;
- `core_keep`: `87`;
- `priority_benchmark_candidate`: `39`;
- `watchlist_candidate`: `91`;
- `needs_rule_before_strategy`: `120`;
- `active_low_confidence_review`: `13`;
- `low_priority`: `43`;
- `policy_blocked`: `2`.

Post-PG191 rule-readiness split:

- `battle_ready`: `275`;
- `mapper_manual`: `87`;
- `split_scope`: `20`;
- `runtime_needed`: `11`;
- `blocked_missing_xmage_source`: `2`.

PG191 closure evidence:

- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/pg191_invoke_calamity_free_cast_package.md`;
- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg191_invoke_calamity_20260624.json`;
- affected deck audits:
  `docs/hermes-analysis/master_optimizer_reports/deck609_battle_rule_coherence_pg191_invoke_calamity_postsync_v1.json`,
  `docs/hermes-analysis/master_optimizer_reports/deck614_battle_rule_coherence_pg191_invoke_calamity_postsync_v1.json`,
  `docs/hermes-analysis/master_optimizer_reports/deck615_battle_rule_coherence_pg191_invoke_calamity_postsync_v1.json`, and
  `docs/hermes-analysis/master_optimizer_reports/deck616_battle_rule_coherence_pg191_invoke_calamity_postsync_v1.json`;
- final pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg191_invoke_calamity_postsync_v1_manifest.json`;
- strategy consistency:
  `18/18` pass.

Operational interpretation:

- The `120` `needs_rule_before_strategy` cards in the Lorehold-focused scope must not
  drive deck swaps yet. They first need mapper/runtime/split-scope closure.
- The `39` `priority_benchmark_candidate` cards are the first practical swap
  candidates after baseline hash guard and battle gate review.
- `Chrome Mox` and `Mox Opal` are policy-blocked for the current no-premium-Mox
  Lorehold lane even if they have rule evidence.

## Current Rule-First Priority

The first deck-improvement work is not a swap. It is closing the highest-impact
Lorehold card rules from the matrix.

Start with:

- runtime-needed cards with the highest Lorehold impact, beginning with
  `Perch Protection` and `Sand Scout`;
- split-scope cards that are strategically relevant, such as
  `Sun Titan`, `Glint-Horn Buccaneer`,
  `Taii Wakeen, Perfect Shot`, `Primal Amulet // Primal Wellspring`,
  `Starfield Shepherd`, `Erode`, `Kederekt Parasite`, and `Rakdos Charm`;
- runtime-needed token or damage families only when the exact scope is
  reusable and has focused test coverage;
- manual mapper cards last unless they are blocking a top Lorehold role gap.

`Fury Storm` is the first completed proof of the flow:

1. XMage local source matched exact stack-copy signature.
2. The hint/classifier promoted only the safe exact scope.
3. PG185 precheck/apply/postcheck promoted one verified auto rule.
4. PG -> Hermes sync inserted/updated one local battle rule.
5. Matrix moved the card to `battle_ready` and
   `priority_benchmark_candidate`.

`Lightning Helix` is the second completed proof and the first direct-damage
lifegain subpattern:

1. XMage local source matched `DamageTargetEffect(3)` +
   `GainLifeEffect(3)` + `TargetAnyTarget`.
2. The hint/classifier promoted only the exact
   `damage_any_target_and_gain_life_v1` scope.
3. Battle runtime now executes `direct_damage` with explicit controller
   `gain_life` and replay provenance.
4. PG186 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated `remove_creature` shadows.
5. PG -> Hermes sync made deck `616` report `Lightning Helix` as `pass`.

`Caldera Pyremaw` is the third completed proof and the first creature
spell-cast trigger that combines source counters with source-power damage:

1. XMage local source matched `SpellCastControllerTriggeredAbility` +
   `AddCountersSourceEffect` + `DamageTargetEffect` + `TargetOpponent`.
2. The validity/classifier pipeline now preserves `target_classes`, so exact
   target structure can drive batch-safe decisions.
3. Battle runtime resolves `instant_sorcery_cast` by adding the +1/+1 counter
   first, then dealing damage equal to the post-counter source power.
4. PG187 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated `finisher` shadows.
5. PG -> Hermes sync made deck `614` report `Caldera Pyremaw` as `pass`, and
   the matrix moved it to `battle_ready` / `watchlist_candidate`.

`Pyromancer Ascension` is the fourth completed proof and the first quest-counter
copy engine:

1. XMage local source matched the paired
   `PyromancerAscensionQuestTriggeredAbility` +
   `PyromancerAscensionCopyTriggeredAbility` structure.
2. The mapper/classifier promoted only the exact
   `pyromancer_ascension_quest_counter_copy_spell_v1` scope.
3. Battle runtime now adds quest counters for same-name graveyard spells and
   copies only when the Ascension already had two counters before that cast.
4. PG188 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated review-only shadows.
5. PG -> Hermes sync made deck `608` report `Pyromancer Ascension` as `pass`,
   and the Lorehold-focused matrix moved it to `battle_ready`.

`Profound Journey` is the fifth completed proof and the first rebound recursion
spell:

1. XMage local source matched `ReturnFromGraveyardToBattlefieldTargetEffect` +
   `TargetCardInYourGraveyard(FilterPermanentCard)` + `ReboundAbility`.
2. The mapper/classifier promoted only the exact
   `return_target_permanent_from_graveyard_to_battlefield_rebound_v1` scope.
3. Battle runtime now exiles first-resolution rebound spells, casts them from
   exile at the next upkeep for zero mana, and sends the second resolution to
   the graveyard.
4. PG189 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated review-only shadows.
5. PG -> Hermes sync made deck `611` report `Profound Journey` as `pass`, and
   the Lorehold-focused matrix moved it to `battle_ready` / `watchlist_candidate`.

`Cool but Rude` is the sixth completed proof and the first Class-level runtime
scope:

1. XMage local source matched `AttacksWithCreaturesTriggeredAbility` +
   `DoIfCostPaid(DiscardCardCost)` + paired `ClassLevelAbility` levels.
2. The mapper/classifier promoted only the exact
   `cool_but_rude_class_attack_rummage_level_damage_tutor_v1` scope.
3. Battle runtime now supports this Class pattern through attack rummage,
   level-2 controller-discard damage to each opponent, and level-3 tutor plus
   random discard.
4. PG190 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated review-only shadows.
5. PG -> Hermes sync made decks `608` and `613` report `Cool but Rude` as
   `pass`, and the Lorehold-focused matrix moved it to `battle_ready` /
   `priority_benchmark_candidate`.

`Perch Protection` and `Sand Scout` are the seventh completed proof and the
first mixed token-family batch that closed two different runtime shapes in one
PG package:

1. XMage local sources matched `PerchProtection` and `SandScout` directly from
   `/Users/desenvolvimentomobile/Downloads/mage-master`.
2. `Perch Protection` is modeled as a composed spell: token creation plus
   gift-gated phase-out/life-lock/protection, reusing the existing
   `phase_out` runtime instead of creating a one-off executor.
3. `Sand Scout` is modeled as a creature, not a token spell: ETB Desert ramp is
   guarded by `opponent_controls_more_lands`, and the land-card graveyard token
   trigger stays on the permanent with a once-per-turn limit.
4. PG192 precheck/apply/postcheck promoted two verified auto rules and
   deprecated two stale `Perch Protection` shadows.
5. PG -> Hermes sync made `Perch Protection` pass in decks `609`, `610`,
   `611`, `613`, `614`, and `615`; `Sand Scout` passes in deck `609`.
6. The expanded post-sync pipeline moved from `high=322/pass=333` before PG192
   to `high=320/pass=335` after PG192.
7. The follow-up battle closure added real stack-targeted `removal_exile`
   support, derived rejected-option scores for decision traces, accepted
   compact forensic runtime normalizations, and produced final gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_230939/summary.json`
   with `battle_replay_final_status=trusted_for_strategy_learning`,
   `mandatory_gate_divergences=[]`, tests `18/18` pass,
   `forensic_rule_findings=0`, and `decision_audit_decision_findings=0`.

`Sun Titan` is the eighth completed proof and the first exact creature
ETB-or-attack recursion scope:

1. XMage local source matched `EntersBattlefieldOrAttacksSourceTriggeredAbility`
   + `ReturnFromGraveyardToBattlefieldTargetEffect` +
   `TargetCardInYourGraveyard(FilterPermanentCard)` with mana value `< 4`.
2. The mapper/classifier promoted only the exact
   `sun_titan_etb_attack_return_permanent_mv_lte_3_v1` scope.
3. Battle runtime now supports permanent-triggered graveyard recursion on ETB
   and attack with a mana-value ceiling, resolving attack recursion only for
   declared attackers.
4. PG193 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated shadows.
5. PG -> Hermes sync made deck `611` report `Sun Titan` as `pass`, and the
   Lorehold-focused matrix moved it to `battle_ready` / `watchlist_candidate`.
6. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_233222/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `mandatory_gate_divergences=[]`, `forensic_rule_findings=0`, and
   `decision_audit_decision_findings=0`.

`Glint-Horn Buccaneer` is the ninth completed proof and the first attack-only
activated discard-draw creature scope:

1. XMage local source matched `GlintHornBuccaneer` directly through
   `HasteAbility`, `DamagePlayersEffect(1, TargetController.OPPONENT)`,
   `GameEvent.EventType.DISCARDED_CARD`, `ActivateIfConditionActivatedAbility`,
   `SourceAttackingCondition`, and `DiscardCardCost`.
2. The mapper/classifier promoted only the exact
   `glint_horn_buccaneer_discard_damage_attack_loot_v1` scope.
3. Battle runtime now supports declared-attacker discard-draw activations:
   pay `{1}{R}`, discard through the shared discard trigger path, damage each
   opponent from the controller-discard trigger, then draw.
4. PG194 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated shadows.
5. PG -> Hermes sync made deck `613` report `Glint-Horn Buccaneer` as `pass`;
   the matrix moved it to `battle_ready` / `watchlist_candidate` for decks
   `613` and `617`.
6. The first gate attempt exposed an event-contract regression from newly named
   activation events; the runtime was corrected to emit existing canonical
   `activated_ability` / `activated_ability_skipped` events with
   `activation_kind=attacking_discard_draw`.
7. Final full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_235850/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `mandatory_gate_divergences=[]`, `event_contract_static_status=event_contract_static_ready`,
   `forensic_rule_findings=0`, and `decision_audit_decision_findings=0`.

`Young Pyromancer` is the tenth completed proof and the first exact
instant/sorcery Elemental token trigger promoted from the current Lorehold
matrix:

1. XMage local source matched `YoungPyromancer` directly through
   `SpellCastControllerTriggeredAbility`, `CreateTokenEffect`,
   `RedElementalToken`, and
   `StaticFilters.FILTER_SPELL_AN_INSTANT_OR_SORCERY`.
2. The mapper/classifier promoted only the exact
   `instant_sorcery_cast_create_1_1_red_elemental_v1` scope.
3. Battle runtime already supported this family through the
   `instant_sorcery_cast` permanent trigger path; PG195 adds focused proof
   that the executor creates one 1/1 red Elemental token and emits
   `trigger_resolved`.
4. PG195 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated shadows.
5. PG -> Hermes sync made decks `612` and `616` report `Young Pyromancer` as
   `pass`; the matrix moved it to `battle_ready` / `watchlist_candidate`.
6. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_001857/summary.json`
  reports `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `event_contract_static_status=event_contract_static_ready`,
  `forensic_rule_findings=0`, and `decision_audit_decision_findings=0`.

`Squee, Goblin Nabob` is the eleventh completed proof and the first exact
graveyard-upkeep self-return scope promoted from the current Lorehold matrix:

1. XMage local source matched `SqueeGoblinNabob` directly through
   `BeginningOfUpkeepTriggeredAbility(Zone.GRAVEYARD, TargetController.YOU,
   ReturnSourceFromGraveyardToHandEffect, optional=true)`.
2. The mapper/classifier promoted only the exact
   `graveyard_upkeep_return_self_to_hand_v1` scope.
3. Battle runtime now processes beginning-of-upkeep graveyard self-return,
   moves the source from graveyard to hand, and emits `trigger_resolved` with
   rule provenance.
4. PG196 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated shadows.
5. PG -> Hermes sync made decks `609` and `610` report
   `Squee, Goblin Nabob` as `pass`; the matrix moved it to `battle_ready` /
   `watchlist_candidate`.
6. The final full gate also closed a runtime-contract gap found in the same
   replay set: `Teferi, Time Raveler` now resolves as a planeswalker permanent,
   and `planeswalker` / `planeswalker_resolved` are known to the forensic and
   event-contract layers.
7. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_010820/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `mandatory_gate_divergences=[]`, `event_contract_static_status=event_contract_static_ready`,
   `forensic_rule_findings=0`, and `decision_audit_decision_findings=0`.

`Goldspan Dragon` is the twelfth completed proof and the first exact
attack-or-spell-target Treasure trigger plus Treasure double-mana scope promoted
from the current Lorehold matrix:

1. XMage local source matched `GoldspanDragon` directly through
   `OrTriggeredAbility`, `AttacksTriggeredAbility`,
   `BecomesTargetSourceTriggeredAbility`, `CreateTokenEffect(new
   TreasureToken())`, and `GainAbilityControlledEffect` granting
   `AddManaOfAnyColorEffect(2)` to controlled Treasures.
2. The mapper/classifier promoted only the exact
   `goldspan_dragon_attack_or_target_treasure_double_mana_v1` scope.
3. Battle runtime now creates one Treasure when Goldspan attacks, creates one
   Treasure when it becomes the target of a spell, treats controlled Treasures
   as two-mana sources while Goldspan is on the battlefield, and emits
   `trigger_resolved` with rule provenance.
4. PG197 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated shadows.
5. PG -> Hermes sync made decks `608`, `611`, `614`, and `615` report
   `Goldspan Dragon` as `pass`; the matrix moved it to `battle_ready` /
   `priority_benchmark_candidate`.
6. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_013633/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `mandatory_gate_divergences=[]`, `event_contract_static_status=event_contract_static_ready`,
   `forensic_rule_findings=0`, and `decision_audit_decision_findings=0`.

`Surly Badgersaur` is the thirteenth completed proof and the first exact
discarded-card-type trigger scope promoted from the current Lorehold matrix:

1. XMage local source matched `SurlyBadgersaur` directly through
   `DiscardCardControllerTriggeredAbility` variants using creature, land, and
   noncreature/nonland discarded-card filters.
2. The mapper/classifier promoted only the exact
   `surly_badgersaur_discard_card_type_triggers_v1` scope.
3. Battle runtime now adds a +1/+1 counter when the controller discards a
   creature card, creates one Treasure when the controller discards a land card,
   and resolves an optional fight against a beneficial opponent creature when
   the controller discards a noncreature, nonland card.
4. PG198 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated shadows.
5. PG -> Hermes sync made decks `608` and `617` report
   `Surly Badgersaur` as `pass`; the matrix moved it to `battle_ready` /
   `priority_benchmark_candidate`.
6. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_015839/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `mandatory_gate_divergences=[]`, `event_contract_static_status=event_contract_static_ready`,
   `forensic_rule_findings=0`, and `decision_audit_decision_findings=0`.

## Current Benchmark Candidate Lane

After rules are ready, the first battle-benchmark candidates are the top
rule-ready matrix rows, not every possible card.

Current top candidates include:

- `Library of Leng`;
- `Restoration Seminar`;
- `Reforge the Soul`;
- `Increasing Vengeance`;
- `Flare of Duplication`;
- `Volcanic Vision`;
- `Big Score`;
- `Flashback`;
- `Improvisation Capstone`;
- `Pinnacle Monk // Mystic Peak`;
- `Fury Storm`;
- `Return the Favor`;
- `Monument to Endurance`;
- `Dawn's Truce`;
- `Arcane Bombardment`;
- `Creative Technique`.

These are candidate rows only. They still require baseline hash guard,
category-safe cut target, temporary battle benchmark, quality gate,
confirmation, handoff, and explicit apply approval.

## Historical Tools Removed From Active Path

The following are retained only as history/compatibility and must not guide new
Lorehold deck decisions:

- `build_optimized_deck.py`
  - now exits as `historical_disabled`;
  - reason: hardcoded collection/priority heuristic without rule readiness,
    baseline hashes, or battle evidence gates.
- `universal_optimizer.py`
  - now blocks execution unless explicitly overridden with
    `MANALOOM_ALLOW_LEGACY_UNIVERSAL_OPTIMIZER=1` or `--allow-legacy`;
  - reason: legacy quick/full auto-apply path is not authorized for current
    handoff.

Use `lorehold_ideal_deck_candidate_matrix.py` plus the safe master optimizer
pipeline instead.

## Required Gates Before Any Deck Change

Any actual deck change must pass:

1. current PostgreSQL/backend source-of-truth check when the claim depends on
   promoted data;
2. Hermes SQLite freshness check for the local battle cache;
3. approved baseline hash guard;
4. candidate matrix row in `priority_benchmark_candidate` or explicitly
   documented override;
5. temporary `slot_optimizer.py` benchmark;
6. `master_optimizer_quality_gate.py`;
7. confirmation/handoff artifact;
8. explicit apply approval;
9. post-apply battle gate and strategy-coherence review.

No matrix row is an automatic swap.
