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

`Taii Wakeen, Perfect Shot` is the fourteenth completed proof and the first
exact noncombat-damage modifier plus damage-equals-toughness draw trigger scope
promoted from the current Lorehold matrix:

1. XMage local source matched `TaiiWakeenPerfectShot` directly through
   `TaiiWakeenPerfectShotTriggeredAbility`,
   `DrawCardSourceControllerEffect`, `TaiiWakeenPerfectShotEffect`,
   `SimpleActivatedAbility`, and `TapSourceCost`.
2. The mapper/classifier promoted only the exact
   `taii_wakeen_noncombat_damage_equal_toughness_draw_plus_x_v1` scope.
3. Battle runtime now stores Taii's `{X}, {T}` noncombat damage modifier until
   cleanup, applies it to sources the controller controls, and draws a card
   when the modified or unmodified noncombat damage dealt to a creature equals
   that creature's toughness.
4. PG199 precheck/apply/postcheck promoted one verified auto rule with no
   stale generated shadows to deprecate.
5. PG -> Hermes sync made deck `612` report `Taii Wakeen, Perfect Shot` as
   `pass`; the matrix moved it to `battle_ready` /
   `priority_benchmark_candidate`.
6. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_023640/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `mandatory_gate_divergences=[]`, `event_contract_static_status=event_contract_static_ready`,
   `forensic_rule_findings=0`, and `decision_audit_decision_findings=0`.

`Trouble in Pairs` is the fifteenth completed proof and the first exact
opponent-second-action draw engine plus opponent-extra-turn skip scope promoted
from the current Lorehold/opponent matrix:

1. XMage local source matched `TroubleInPairs` directly through
   `SkipExtraTurnsAbility(true)`, `TroubleInPairsTriggeredAbility`,
   `CardsDrawnThisTurnWatcher`, `CastSpellLastTurnWatcher`, and
   `DrawCardSourceControllerEffect`.
2. The mapper/classifier promoted only the exact
   `opponent_second_draw_second_spell_two_attackers_draw_v1` scope.
3. Battle runtime now draws for the controller when an opponent draws their
   second card in a turn, casts their second spell in a turn, or attacks the
   controller with two or more creatures, and it skips opponent extra turns
   while the enchantment is controlled.
4. PG200 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated shadows.
5. PG -> Hermes sync made decks `614` and `619` report `Trouble in Pairs` as
   `pass`; the matrix moved it to `battle_ready` /
   `priority_benchmark_candidate`.
6. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_030625/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `mandatory_gate_divergences=[]`, `event_contract_static_status=event_contract_static_ready`,
   `forensic_rule_findings=0`, and `decision_audit_decision_findings=0`.

`Deflecting Palm` is the sixteenth completed proof and the first exact
chosen-source damage prevention plus reflection scope promoted from the current
Lorehold/opponent matrix:

1. XMage local source matched `DeflectingPalm` directly through
   `PreventNextDamageFromChosenSourceEffect`,
   `DeflectingPalmPreventionApplier`, and `objectController.damage`.
2. The mapper/classifier promoted only the exact
   `prevent_next_damage_from_chosen_source_to_you_reflect_to_controller_v1`
   scope.
3. Battle runtime now chooses the largest/lethal incoming combat damage source,
   creates a source-specific prevention shield, prevents only that source's next
   damage to the controller, and reflects the prevented damage to that source's
   controller.
4. PG201 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated shadows.
5. PG -> Hermes sync made decks `614`, `615`, and `616` report
   `Deflecting Palm` as `pass`; the matrix moved it to `battle_ready` /
   `priority_benchmark_candidate` with score `54.0`.
6. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_034603/summary.json`
  reports `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `event_contract_static_status=event_contract_static_ready`,
  `forensic_rule_findings=0`, and `decision_audit_decision_findings=0`.

`Redress Fate` is the seventeenth completed proof and the first exact
all-matching artifact/enchantment recursion scope promoted from the current
Lorehold/opponent matrix:

1. XMage local source matched `RedressFate` directly through
   `ReturnFromYourGraveyardToBattlefieldAllEffect`,
   `FilterArtifactOrEnchantmentCard`, and `MiracleAbility("{3}{W}")`.
2. The mapper/classifier promoted only the exact
   `return_all_artifact_enchantment_cards_from_graveyard_to_battlefield_miracle_v1`
   scope, and the generator now emits a `recursion` deck role instead of
   falling back to manual-review metadata.
3. Battle runtime now supports `return_all_matching` for recursion and routes
   battlefield returns through shared permanent-entry preparation.
4. PG202 precheck/apply/postcheck promoted one verified auto rule and
   deprecated no shadow rows.
5. PG -> Hermes sync made deck `610` report `Redress Fate` as `pass`; the
   matrix moved it to `battle_ready` / `priority_benchmark_candidate` with
   score `50.0`.
6. Later structured matrix analysis corrected the earlier deck-block reading:
   PG202 still had `106` Lorehold-touching `needs_rule_before_strategy` rows
   across decks `608` through `616` when using each row's structured
   `deck_ids` field.
7. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_042201/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `mandatory_gate_divergences=[]`, `event_contract_static_status=event_contract_static_ready`,
   `forensic_rule_findings=0`, and `decision_audit_decision_findings=0`.

`Brilliant Restoration` and `Wake the Past` are the eighteenth completed proof
group and finish the next deck-610 all-matching recursion pair from the current
Lorehold/opponent matrix:

1. XMage local sources matched `BrilliantRestoration` through
   `ReturnFromYourGraveyardToBattlefieldAllEffect` plus
   `FilterArtifactOrEnchantmentCard`, and `WakeThePast` through its custom
   all-artifact graveyard return effect plus haste-until-end-of-turn grant.
2. The mapper/classifier promoted only the exact
   `return_all_artifact_enchantment_cards_from_graveyard_to_battlefield_v1`
   and
   `return_all_artifact_cards_from_graveyard_to_battlefield_haste_eot_v1`
   scopes.
3. Battle runtime now applies `grants_haste_until_eot` for recursion returns,
   and combat legality now blocks summoning-sick attackers without haste before
   strategy scoring or attack-limit filtering.
4. PG203 precheck/apply/postcheck promoted two verified auto rules and
   deprecated four stale generated shadows.
5. PG -> Hermes sync made deck `610` report both cards as `pass`; the matrix
   moved both to `battle_ready` / `priority_benchmark_candidate` with score
   `48.5`.
6. The PG203 matrix now reports `213` total `needs_rule_before_strategy` rows
   and `104` Lorehold-touching rows across decks `608` through `616`:
   `82` mapper manual, `16` split-scope, and `6` runtime-needed. This is the
   current Lorehold-first queue before broad benchmark/deck swaps.
7. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_045925/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `battle_replay_final_status_reason=all_mandatory_gates_pass`,
   `decision_audit_statuses={"turn_invariants_clean":16}`,
   `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
   `action_findings=0`, `event_contract_static_status=event_contract_static_ready`,
   `runtime_surface_manifest_status=runtime_surface_manifest_ready`, and
   `effect_coverage_residual_status=effect_coverage_residual_accepted`.

`Gods Willing` and `Sejiri Shelter // Sejiri Glacier` are the nineteenth
completed proof group and close the first targeted protection-from-chosen-color
family from the current Lorehold/opponent matrix:

1. XMage local sources matched `GodsWilling` and `SejiriShelter` through
   `GainProtectionFromColorTargetEffect(Duration.EndOfTurn)` plus
   `TargetControlledCreaturePermanent`; `Sejiri Shelter // Sejiri Glacier` is
   handled as an instant/land MDFC instead of a simple instant-only card.
2. The mapper/classifier promoted only the exact
   `target_creature_you_control_protection_from_chosen_color_until_eot_v1`
   scope, and the generator emits protection-role metadata for
   `grant_protection_from_chosen_color`.
3. Battle runtime now grants temporary `protection_from` to the best controlled
   creature target until cleanup and emits `targeted_protection_granted`.
4. The event contract classifies `targeted_protection_granted` as a
   `strategy_signal`.
5. PG204 precheck/apply/postcheck promoted two verified auto rules and
   deprecated four stale generated shadows.
6. PG -> Hermes sync made both cards report as `battle_ready`; the matrix moved
   them out of `needs_rule_before_strategy` and into `watchlist_candidate`.
7. The PG204 matrix now reports `211` total `needs_rule_before_strategy` rows
   and `102` Lorehold-touching rows across decks `608` through `616`:
   `80` mapper manual, `16` split-scope, and `6` runtime-needed. This is the
   current Lorehold-first queue before broad benchmark/deck swaps.
8. The validation gate exposed one unrelated but real runtime weakness:
   `Reiterate` could copy an opponent `Green Sun's Zenith` even when the copy
   controller had no legal library target. Stack-copy handling now preserves
   copied X values and skips tutor copies without controller-side payoff.
9. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_055132/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `battle_replay_final_status_reason=all_mandatory_gates_pass`,
   `mandatory_gate_divergences=[]`,
   `decision_audit_statuses={"turn_invariants_clean":16}`,
   `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
   `action_findings=0`, `event_contract_static_status=event_contract_static_ready`,
   and `test_results_status_counts={"pass":18}`.

`Clever Concealment` is the twentieth completed proof group and closes the
first targeted nonland-permanent phase-out protection family from the current
Lorehold/opponent matrix:

1. XMage local source `CleverConcealment` matched
   `PhaseOutTargetEffect`, `TargetPermanent`, `FilterControlledPermanent`, and
   the nonland controlled permanent filter.
2. The mapper/classifier now promotes the exact
   `target_nonland_permanents_you_control_phase_out_v1` scope as
   `phase_out_protection`, instead of leaving it as manual-model work.
3. No new broad battle executor was needed: the existing `phase_out` runtime
   already supports land inclusion/exclusion. The new focused regression proves
   `Clever Concealment` phases controlled nonland permanents and leaves lands
   on battlefield.
4. PG205 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated shadows.
5. PG -> Hermes sync made `Clever Concealment` report as `battle_ready`; the
   matrix moved it out of `needs_rule_before_strategy` and into
   `watchlist_candidate` with score `44.0`.
6. The PG205 matrix now reports `210` total `needs_rule_before_strategy` rows
   and `101` Lorehold-touching rows across decks `608` through `616`:
   `79` mapper manual, `16` split-scope, and `6` runtime-needed. This remains
   the current Lorehold-first queue before broad benchmark/deck swaps.
7. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_061534/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `battle_replay_final_status_reason=all_mandatory_gates_pass`,
   `mandatory_gate_divergences=[]`,
   `decision_audit_statuses={"turn_invariants_clean":16}`,
   `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
   `event_contract_static_status=event_contract_static_ready`, and
   `test_results_status_counts={"pass":18}`.

`Boltwave` is the twenty-first completed proof group and closes the first
one-shot `DamagePlayersEffect(... TargetController.OPPONENT)` spell family from
the current Lorehold/opponent matrix:

1. XMage local source `Boltwave` matched a one-shot `DamagePlayersEffect(3,
   TargetController.OPPONENT)` on a sorcery spell.
2. The mapper/classifier now promotes the exact
   `spell_damage_each_opponent_v1` scope as `opponent_damage_spell`, instead
   of mixing it with permanent ETB/cast/discard trigger variants.
3. Battle runtime now has a small `damage_each_opponent` executor that applies
   noncombat damage modifiers, damages each live opponent, emits
   `damage_each_opponent_resolved`, and finishes the resolved spell through the
   standard zone path.
4. The event contract classifies `damage_each_opponent_resolved` as a
   `strategy_signal`.
5. PG206 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated shadows.
6. PG -> Hermes sync made `Boltwave` report as `battle_ready`; the matrix moved
   it out of `needs_rule_before_strategy`.
7. The PG206 matrix now reports `209` total `needs_rule_before_strategy` rows:
   `136` mapper manual, `53` split-scope, `16` runtime-needed, and `4`
   blocked missing XMage source. The Lorehold deck block across decks `608`
   through `616` now has `100` remaining rows: `78` mapper manual, `16`
   split-scope, and `6` runtime-needed. This remains the current
   Lorehold-first queue before broad benchmark/deck swaps.
8. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_064531/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `battle_replay_final_status_reason=all_mandatory_gates_pass`,
   `mandatory_gate_divergences=[]`,
   `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
   `event_contract_static_status=event_contract_static_ready`, and
   `test_results_status_counts={"pass":18}`.

`Agate Instigator`, `Impact Tremors`, and `Molten Gatekeeper` are the
twenty-second completed proof group and close the simple controlled-creature
ETB damage engine from the current Lorehold/opponent matrix:

1. XMage local sources matched
   `EntersBattlefieldControlledTriggeredAbility` plus `DamagePlayersEffect`
   targeting `TargetController.OPPONENT`.
2. The mapper/classifier now promotes the exact
   `controlled_creature_enters_damage_each_opponent_v1` scope as
   `controlled_creature_etb_damage_engine`, while leaving mixed cards such as
   `Purphoros, God of the Forge` and `Warleader's Call` in split-scope review.
3. Battle runtime now resolves `creature_you_control_enters` triggers from
   existing permanents and token creation paths, emits `trigger_resolved`, and
   preserves the `another creature` exclusion for the source entering itself.
4. PG207 precheck/apply/postcheck promoted three verified auto rules and
   deprecated six stale generated shadows.
5. PG -> Hermes sync made those three cards report as `battle_ready`; the
   matrix moved them out of `needs_rule_before_strategy`.
6. The PG207 matrix now reports `206` total `needs_rule_before_strategy` rows
   and `374` `battle_ready` rows. The effective queue now has
   `333` mapper backlog, `74` split-scope backlog, `20` runtime-family
   backlog, and `4` blocked missing XMage source rows, with no unprepared
   package-ready rows.
7. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_071326/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `battle_replay_final_status_reason=all_mandatory_gates_pass`,
   `mandatory_gate_divergences=[]`,
   `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
   `event_contract_static_status=event_contract_static_ready`, and
   `test_results_status_counts={"pass":18}`.

`Armageddon` is the twenty-third completed proof group and closes the exact
`DestroyAllEffect(StaticFilters.FILTER_LANDS)` family:

1. XMage local source matched a pure `DestroyAllEffect` over
   `StaticFilters.FILTER_LANDS`.
2. The mapper/classifier now promotes the exact `destroy_all_lands_v1` scope
   as `board_wipe`, while leaving mixed cards such as `Ultima` in runtime
   review because `EndTurnEffect` still needs a real executor.
3. Battle runtime now lets `board_wipe` target typed permanent groups via
   `destroy_card_types`, defaulting old rules to creature-only, and emits rule
   metadata on `board_wipe_resolved` for audit traceability.
4. PG208 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated shadows.
5. PG -> Hermes sync made `Armageddon` report as `battle_ready`; the matrix
   moved it out of `needs_rule_before_strategy`.
6. The PG208 matrix now reports `205` total `needs_rule_before_strategy` rows
   and `375` `battle_ready` rows. The effective queue now has
   `333` mapper backlog, `74` split-scope backlog, `19` runtime-family
   backlog, and `4` blocked missing XMage source rows, with no unprepared
   package-ready rows.
7. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_073349/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `battle_replay_final_status_reason=all_mandatory_gates_pass`,
   `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
   `event_contract_static_status=event_contract_static_ready`, and
   `test_results_status_counts={"pass":18}`.

`Monastery Mentor` is the twenty-fourth completed proof group and closes the
exact noncreature-spell token trigger for the current Lorehold/opponent matrix:

1. XMage local source matched `SpellCastControllerTriggeredAbility` with
   `CreateTokenEffect(MonasteryMentorToken)` and
   `StaticFilters.FILTER_SPELL_A_NON_CREATURE`.
2. The mapper/classifier now promotes
   `noncreature_spell_cast_create_1_1_white_monk_prowess_v1` as
   `token_maker`, while leaving adjacent token-maker cards such as
   `Blaze Commando` and, at that checkpoint, `Utvara Hellkite` in runtime
   review because they need damage-by-spell and Dragon-attack hooks.
3. Battle runtime now resolves generic `spell_cast`/`noncreature_spell_cast`
   token makers and preserves token keywords such as `prowess`.
4. PG209 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated shadows.
5. PG -> Hermes sync made `Monastery Mentor` report as `battle_ready`; the
   matrix moved it out of `needs_rule_before_strategy`.
6. The PG209 matrix now reports `204` total `needs_rule_before_strategy` rows
   and `376` `battle_ready` rows. The effective queue now has
   `333` mapper backlog, `74` split-scope backlog, `18` runtime-family
   backlog, and `4` blocked missing XMage source rows, with no unprepared
   package-ready rows.
7. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_075241/summary.json`
   reports `battle_replay_final_status=trusted_for_strategy_learning`,
   `battle_replay_final_status_reason=all_mandatory_gates_pass`,
   `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
   `event_contract_static_status=event_contract_static_ready`, and
   `test_results_status_counts={"pass":18}`.

`Utvara Hellkite` is the twenty-fifth completed proof group and closes the
exact Dragon-controlled attack token trigger for the current Lorehold/opponent
matrix:

1. XMage local source matched `AttacksCreatureYouControlTriggeredAbility` with
   `CreateTokenEffect(UtvaraHellkiteDragonToken)` and a controlled Dragon
   subtype filter.
2. The mapper/classifier now promotes
   `dragon_you_control_attacks_create_6_6_red_flying_dragon_v1` as
   `token_maker`, while leaving `Blaze Commando` in runtime review because it
   needs the separate damage-by-spell trigger hook.
3. Battle runtime now resolves controlled attack token triggers by subtype,
   so each declared Dragon attacker creates one 6/6 red flying Dragon token
   without allowing newly created tokens to retrigger in the same declaration.
4. PG210 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated shadows.
5. PG -> Hermes sync made `Utvara Hellkite` report as `battle_ready`; the
   matrix moved it out of `needs_rule_before_strategy`.
6. The PG210 matrix now reports `96` total Lorehold-scoped
   `needs_rule_before_strategy` rows and `299` `battle_ready` rows. The
   Lorehold runtime-needed block across decks `608` through `616` is now `3`
   rows. The effective queue still has `333` mapper backlog, `74`
   split-scope backlog, `17` runtime-family backlog, and `4` blocked missing
   XMage source rows, with no unprepared package-ready rows.
7. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_081415/summary.json`
   reports `seeds_completed=16/16`, `test_results_status_counts={"pass":18}`,
   `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
   `event_contract_static_status=event_contract_static_ready`, and
   `mandatory_gate_divergences=["strategy_audit=review_required"]`. The final
  status remains `review_required` only because the strategy audit found one
  review-required and one low-confidence strategy item, not because of
  runtime, event-contract, decision-trace, forensic, target-pressure, or
  table-intent failures.

`Blaze Commando` is the twenty-sixth completed proof group and closes the
exact instant/sorcery spell damage token trigger for the current
Lorehold/opponent matrix:

1. XMage local source matched `SpellControlledDealsDamageTriggeredAbility`
   with `CreateTokenEffect(new SoldierHasteToken(), 2)` and an instant/sorcery
   spell filter.
2. The mapper/classifier now promotes
   `instant_sorcery_spell_damage_create_two_1_1_red_white_soldier_haste_v1`
   as `token_maker`, while leaving `Ultima` and `Soul Immolation` in runtime
   review because they need separate board-wipe/end-turn and variable-X
   damage modeling.
3. Battle runtime now resolves
   `instant_sorcery_spell_you_control_deals_damage` token engines after
   successful instant/sorcery `damage_each_opponent` events, creating two
   1/1 red and white Soldier tokens with haste for Blaze Commando.
4. PG211 precheck/apply/postcheck promoted one verified auto rule and did not
   need to deprecate stale shadow rows.
5. PG -> Hermes sync made `Blaze Commando` report as `battle_ready`; the
   matrix moved it out of `needs_rule_before_strategy`.
6. The PG211 matrix now reports `95` total Lorehold-scoped
   `needs_rule_before_strategy` rows and `300` `battle_ready` rows. The
   Lorehold runtime-needed block across decks `608` through `616` is now `2`
   rows: `Ultima` and `Soul Immolation`. The effective queue still has `333`
   mapper backlog, `74` split-scope backlog, `16` runtime-family backlog, and
   `4` blocked missing XMage source rows, with no unprepared package-ready
   rows.
7. Gate repair notes: the PG211 gate surfaced two runtime/audit blockers that
   were not Blaze-specific but blocked complete validation. `ward_cost` now
   normalizes textual generic costs such as `"2"` instead of crashing replays,
   and forensic support now recognizes the already implemented Insidious Roots
   effect `create_plant_token_plus_counters`.
8. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_084446/summary.json`
   reports `seeds_completed=16/16`, `test_results_status_counts={"pass":18}`,
   `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
   `forensic_audit.status=pass`, `target_pressure.status=pass`,
   `table_intent.status=pass`, `effect_coverage.status=pass`, and
   `mandatory_gate_divergences=["event_contract_static=review_required"]`.
   The final status remains `review_required` only because the static event
   contract still has one review-required fixture waiver, not because of
   runtime, decision-trace, forensic, target-pressure, table-intent, or effect
   coverage failures.

## PG212 Runtime Checkpoint - Ultima

`Ultima` is the twenty-seventh completed proof group. It closes the exact
XMage pattern `DestroyAllEffect(artifacts or creatures) + EndTurnEffect` for
the Lorehold/new-deck matrix without broadening the mapper to every
end-the-turn card.

What changed:

1. XMage mapper now recognizes `Ultima` only when the class has
   `DestroyAllEffect`, `EndTurnEffect`, sorcery type, and the artifact/creature
   permanent filter.
2. ManaLoom effect scope is
   `destroy_all_artifacts_and_creatures_end_turn_v1` with
   `destroy_card_types=["artifact","creature"]`, `destination=graveyard`, and
   `end_the_turn=true`.
3. Battle runtime now emits `end_turn_effect_resolved` and stops later
   priority/phase actions when a resolving effect requests current-turn end.
4. PG212 precheck/apply/postcheck promoted one verified auto rule for
   `Ultima`, backed up/deprecated two stale shadow rows, and did not mutate
   decks.
5. PG -> Hermes sync made `Ultima` report as `battle_ready`; the local cache
   spot-check resolves `effect=board_wipe`,
   `battle_model_scope=destroy_all_artifacts_and_creatures_end_turn_v1`,
   `end_the_turn=1`, and `destroy_card_types=["artifact","creature"]`.
6. The PG212 expanded matrix for decks `6,606-619` reports `580` rows,
   `battle_ready=379`, `runtime_needed=11`, and only one remaining
   `board_wipe_choice` runtime card: `Soul Immolation`.
7. Effective queue
   `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260625_pg212_ultima_postsync_v1.json`
   reports no package-ready unprepared rows; remaining operational lanes are
   `manual_mapper_backlog=333`, `split_scope_backlog=74`,
   `runtime_family_backlog=15`, and `blocked_missing_xmage_source=4`.
8. Strategy consistency audit
   `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260625_pg212_ultima_postsync_v1.json`
   passed `18/18`.
9. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_090245/summary.json`
   reports `seeds_completed=16/16`, `test_results_status_counts={"pass":18}`,
   `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
   `forensic_lineage_status=complete`,
   `target_pressure_statuses={"pass":16}`,
   `table_intent_statuses={"pass":16}`,
   `effect_coverage_residual_status=effect_coverage_residual_accepted`,
   `runtime_surface_manifest_status=runtime_surface_manifest_ready`, and
   `mandatory_gate_divergences=["event_contract_static=review_required"]`.

## PG213 Runtime Checkpoint - Soul Immolation

`Soul Immolation` is the twenty-eighth completed proof group. It closes the
remaining `board_wipe_choice` runtime-needed row from the PG212 expanded
matrix by modeling the XMage variable Blight cost and the X-damage sweep over
opponents and their creatures.

What changed:

1. XMage mapper now recognizes `SoulImmolation` only when the class has
   `BlightCost`, `DamagePlayersEffect`, `DamageAllEffect`, sorcery type, and
   the controlled-creature toughness cap.
2. ManaLoom effect scope is
   `blight_x_damage_each_opponent_and_opponent_creatures_v1` with
   `requires_blight_x=true`,
   `x_value_source=blight_greatest_toughness_controlled_creature`, and
   `damage_amount_source=x_value`.
3. Battle runtime now chooses X from live board context, pays `blight_x` by
   applying -1/-1 counters to a controlled creature, and resolves X damage to
   each live opponent and each creature they control.
4. PG213 precheck/apply/postcheck promoted one verified auto rule for
   `Soul Immolation`; there were no stale shadow rows to deprecate.
5. PG -> Hermes sync made `Soul Immolation` report as `battle_ready`; the local
   cache spot-check resolves
   `effect=damage_each_opponent_and_opponent_creatures`,
   `battle_model_scope=blight_x_damage_each_opponent_and_opponent_creatures_v1`,
   `review_status=verified`, and `execution_status=auto`.
6. The PG213 expanded matrix for decks `6,606-619` reports `580` rows,
   `battle_ready=380`, `runtime_needed=10`, `mapper_manual=131`,
   `split_scope=55`, and `blocked_missing_xmage_source=4`.
7. Effective queue
   `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260625_pg213_soul_immolation_postsync_v1.json`
   reports no package-ready unprepared rows; remaining operational lanes are
   `manual_mapper_backlog=333`, `split_scope_backlog=74`,
   `runtime_family_backlog=14`, and `blocked_missing_xmage_source=4`.
8. Strategy consistency audit
   `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260625_pg213_soul_immolation_postsync_v1.json`
   passed `18/18`.
9. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_093405/summary.json`
   reports `seeds_completed=16/16`, `test_results_status_counts={"pass":18}`,
   `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
   `forensic_lineage_status=complete`,
   `target_pressure_statuses={"pass":16}`,
   `table_intent_statuses={"pass":16}`,
   `effect_coverage_residual_status=effect_coverage_residual_accepted`,
   `runtime_surface_manifest_status=runtime_surface_manifest_ready`, and
   `mandatory_gate_divergences=["event_contract_static=review_required"]`.

Next operational order:

1. Handle the token-maker runtime family surfaced by newly included decks
   `617/619`.
2. Reduce exact mapper/split-scope backlog only after the token-maker runtime
   lane is no longer the top blocker for Lorehold/opponent coverage.
3. Only after those runtime lanes shrink, resume benchmark candidates with the
   baseline/hash/slot-optimizer gate.

## PG214 Runtime Checkpoint - Discard Card-Type Token/Mana/Draw

PG214 handles the first high-leverage token-maker subfamily from decks
`617/619`: discard-card-type triggers that create a Zombie token, add black
mana, or draw a card.

What changed:

1. XMage sources:
   `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/b/BoneMiser.java`
   and
   `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/w/WasteNot.java`.
2. Runtime scopes:
   `controller_discards_card_type_token_mana_draw_v1` for `Bone Miser` and
   `opponent_discards_card_type_token_mana_draw_v1` for `Waste Not`.
3. The battle runtime now resolves each discarded card by type:
   creature creates the configured Zombie token, land adds configured black
   mana, and noncreature/nonland draws the configured number of cards.
4. PG214 precheck/apply/postcheck promoted one verified auto rule for each
   card, deprecated four old shadow rows, and kept rollback SQL in
   `docs/hermes-analysis/master_optimizer_reports/pg214_discard_token_mana_draw_rollback.sql`.
5. PG -> Hermes sync report
   `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg214_discard_token_mana_draw_20260625.json`
   selected `2` cards, loaded `6` PG rows, upserted `6` SQLite rows, and
   exported `3244` canonical snapshot rows.
6. The PG214 expanded matrix for decks `6,606-619` reports `580` rows,
   `battle_ready=382`, `runtime_needed=8`, `mapper_manual=131`,
   `split_scope=55`, and `blocked_missing_xmage_source=4`.
7. Effective queue
   `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260625_pg214_discard_token_mana_draw_postsync_v1.json`
   reports no package-ready unprepared rows; remaining operational lanes are
   `manual_mapper_backlog=333`, `split_scope_backlog=74`,
   `runtime_family_backlog=12`, and `blocked_missing_xmage_source=4`.
8. Strategy consistency audit
   `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260625_pg214_discard_token_mana_draw_postsync_v1.json`
   passed `18/18`.
9. Full gate
   `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_095546/summary.json`
   reports `seeds_completed=16/16`, `test_results_status_counts={"pass":18}`,
   `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
   `target_pressure_statuses={"pass":16}`,
   `table_intent_statuses={"pass":16}`,
   `effect_coverage_residual_status=effect_coverage_residual_accepted`,
   `runtime_surface_manifest_status=runtime_surface_manifest_ready`, and
   `mandatory_gate_divergences=["event_contract_static=review_required"]`.

Next operational order:

1. Continue the remaining `token_maker` runtime rows in score order:
   `Fable of the Mirror-Breaker // Reflection of Kiki-Jiki`,
   `Black Market Connections`, `Smuggler's Share`, `Davros, Dalek Creator`,
   `Green Goblin, Nemesis`, `Aclazotz, Deepest Betrayal // Temple of the Dead`,
   `The Locust God`, and `Biotransference`.
2. Treat copy-token/Saga/watchers as separate subfamilies; do not force them
   into the discard-card-type runtime added by PG214.
3. Resume benchmark candidates only after the remaining runtime rows are closed
   or explicitly waived by matrix evidence.

## PG215 Runtime Checkpoint - Discard Nonland Counter / Land Bat Token

PG215 closes the next discard-trigger subfamily without manual per-card
modeling: `Green Goblin, Nemesis` and
`Aclazotz, Deepest Betrayal // Temple of the Dead`.

What changed:

1. XMage sources:
   `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/g/GreenGoblinNemesis.java`
   and
   `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/a/AclazotzDeepestBetrayal.java`.
2. Runtime scopes:
   `controller_discards_nonland_counter_land_treasure_v1` for
   `Green Goblin, Nemesis` and
   `opponent_discards_land_create_bat_token_v1` for
   `Aclazotz, Deepest Betrayal // Temple of the Dead`.
3. The battle runtime now resolves the Green Goblin branch as:
   controller discard nonland -> +1/+1 counter on a controlled Goblin;
   controller discard land -> tapped Treasure.
4. The battle runtime now resolves the Aclazotz branch as:
   opponent discard land -> create a 1/1 black Bat creature token with flying.
5. PG215 precheck/apply/postcheck promoted one verified auto rule for each
   card, had no shadow rows to deprecate, and kept rollback SQL in
   `docs/hermes-analysis/master_optimizer_reports/pg215_discard_counter_bat_rollback.sql`.
6. PG -> Hermes sync report
   `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg215_discard_counter_bat_20260625.json`
   selected `2` cards, loaded `2` PG rows, upserted `2` SQLite rows, and
   exported `3246` canonical snapshot rows.
7. The PG215 expanded matrix for decks `6,606-619` reports `580` rows,
   `battle_ready=384`, `runtime_needed=6`, `mapper_manual=131`,
   `split_scope=55`, and `blocked_missing_xmage_source=4`.
8. Effective queue
   `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260625_pg215_discard_counter_bat_postsync_v1.json`
   reports no package-ready unprepared rows; remaining operational lanes are
   `manual_mapper_backlog=333`, `split_scope_backlog=74`,
   `runtime_family_backlog=10`, and `blocked_missing_xmage_source=4`.
9. Strategy consistency audit
   `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260625_pg215_discard_counter_bat_postsync_v1.json`
   passed `18/18`.
10. Full gate
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_102105/summary.json`
    reports `seeds_completed=16/16`, `test_results_status_counts={"pass":18}`,
    `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
    `target_pressure_statuses={"pass":16}`,
    `table_intent_statuses={"pass":16}`,
    `effect_coverage_residual_status=effect_coverage_residual_accepted`,
    `runtime_surface_manifest_status=runtime_surface_manifest_ready`, and
    `mandatory_gate_divergences=["event_contract_static=review_required"]`.

Next operational order:

1. Continue the remaining runtime rows in score order:
   `Fable of the Mirror-Breaker // Reflection of Kiki-Jiki`,
   `Black Market Connections`, `Smuggler's Share`, `Davros, Dalek Creator`,
   `The Locust God`, and `Biotransference`.
2. Prefer batching compatible watcher engines next:
   `Black Market Connections`, `Smuggler's Share`, and `Davros, Dalek Creator`
   share beginning/end-step style state checks more than the Saga/copy-token
   case does.
3. Keep `Fable of the Mirror-Breaker // Reflection of Kiki-Jiki` first in
   strategy score, but treat it as a separate Saga/transform/copy-token
   implementation lane.
4. Resume benchmark candidates only after the remaining runtime rows are closed
   or explicitly waived by matrix evidence.

## PG216 Runtime Checkpoint - Phase Watchers / End-Step Engines

PG216 closes the compatible phase-watcher subfamily in one runtime/mapper/PG
batch: `Black Market Connections`, `Smuggler's Share`, and
`Davros, Dalek Creator`.

What changed:

1. XMage sources:
   `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/b/BlackMarketConnections.java`,
   `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/s/SmugglersShare.java`,
   and
   `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/d/DavrosDalekCreator.java`.
2. Runtime scopes:
   `precombat_main_choose_modes_treasure_draw_shapeshifter_life_loss_v1`,
   `each_end_step_opponent_extra_draw_landfall_draw_treasure_v1`, and
   `controller_end_step_opponent_lost_life_dalek_villainous_choice_v1`.
3. The battle runtime now tracks per-turn life loss after actual life changes
   and damage resolution, then resets cards-drawn, lands-played, and life-lost
   counters at turn boundaries.
4. The battle runtime now resolves Black Market's precombat-main modal modes:
   Treasure, card draw, Shapeshifter token, and life payment, guarded by a
   conservative life floor.
5. The battle runtime now resolves Smuggler's Share at each end step from the
   observed opponent extra-draw and extra-land counters.
6. The battle runtime now resolves Davros at controller end step from opponent
   life-loss counters, creates a Dalek token, and models villainous choice as
   discard when possible or controller draw otherwise.
7. PG216 precheck/apply/postcheck promoted one verified auto rule for each
   card, deprecated four older Black Market/Smuggler shadow rows, and kept
   rollback SQL in
   `docs/hermes-analysis/master_optimizer_reports/pg216_phase_watchers_rollback.sql`.
8. PG -> Hermes sync report
   `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg216_phase_watchers_20260625.json`
   selected `3` cards, loaded `7` PG rows, upserted `7` SQLite rows, and
   exported `3247` canonical snapshot rows.
9. The PG216 expanded matrix for decks `6,606-619` reports `580` rows,
   `battle_ready=387`, `runtime_needed=3`, `mapper_manual=131`,
   `split_scope=55`, and `blocked_missing_xmage_source=4`.
10. Effective queue
    `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260625_pg216_phase_watchers_postsync_v1.json`
    reports no package-ready unprepared rows; remaining operational lanes are
    `manual_mapper_backlog=333`, `split_scope_backlog=74`,
    `runtime_family_backlog=7`, and `blocked_missing_xmage_source=4`.
11. Strategy consistency audit
    `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260625_pg216_phase_watchers_postsync_v1.json`
    passed `18/18`.
12. Full gate
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_105025/summary.json`
    reports `seeds_completed=16/16`, `test_results_status_counts={"pass":18}`,
    `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
    `action_verdict_counts={"ok":6435}`,
    `target_pressure_statuses={"pass":16}`,
    `table_intent_statuses={"pass":16}`,
    `effect_coverage_unknowns=0`,
    `effect_coverage_residual_status=effect_coverage_residual_accepted`,
    `runtime_surface_manifest_status=runtime_surface_manifest_ready`, and
    `mandatory_gate_divergences=["event_contract_static=review_required"]`.

Next operational order:

1. Continue the remaining runtime rows in separated implementation lanes:
   `Fable of the Mirror-Breaker // Reflection of Kiki-Jiki`,
   `The Locust God`, and `Biotransference`.
2. Treat `Fable of the Mirror-Breaker // Reflection of Kiki-Jiki` as a
   Saga/transform/copy-token lane. It should not be merged into the generic
   end-step watcher engine.
3. Treat `The Locust God` as a draw-trigger token lane.
4. Treat `Biotransference` as a static type-modification plus creature-spell
   token lane.
5. Resume benchmark candidates only after these runtime rows are closed or
   explicitly waived by matrix evidence.

## PG217 Runtime Checkpoint - Saga / Draw Token / Artifact Static

PG217 closes the remaining current Lorehold runtime lane in one verified
runtime/mapper/PG batch: `Fable of the Mirror-Breaker // Reflection of
Kiki-Jiki`, `The Locust God`, and `Biotransference`.

What changed:

1. XMage sources:
   `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/f/FableOfTheMirrorBreaker.java`,
   `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/t/TheLocustGod.java`,
   and
   `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/b/Biotransference.java`.
2. Runtime scopes:
   `saga_goblin_rummage_transform_reflection_copy_v1`,
   `controller_draw_create_1_1_flying_haste_insect_token_loot_death_return_v1`,
   and
   `controlled_creatures_are_artifacts_artifact_spell_life_loss_necron_token_v1`.
3. The battle runtime now models Saga chapter state, immediate chapter-one
   resolution for Saga casts, post-draw chapter advancement, chapter-two
   rummage, and final chapter transform metadata.
4. Reflection-style activated copy abilities now pay activation cost, tap the
   source, exclude legendary targets, create a hasty token copy, and use the
   existing end-step cleanup surface for temporary copies.
5. Controller draw triggers can create tokens; `The Locust God` uses this to
   produce flying haste Insect tokens.
6. Artifact-spell triggers can see static artifact typing from
   `Biotransference`, apply controller life loss, and create Necron Warrior
   tokens.
7. PG217 precheck/apply/postcheck promoted one verified auto rule for each
   card, deprecated four older Fable/Locust shadow rows, and kept rollback SQL
   in
   `docs/hermes-analysis/master_optimizer_reports/pg217_saga_draw_artifact_rollback.sql`.
8. PG -> Hermes sync report
   `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg217_saga_draw_artifact_20260625.json`
   selected `3` cards, loaded `7` PG rows, upserted `7` SQLite rows, and
   exported `3248` canonical snapshot rows.
9. The PG217 expanded matrix for decks `6,606-619` reports `580` rows,
   `battle_ready=390`, `mapper_manual=131`, `split_scope=55`, and
   `blocked_missing_xmage_source=4`. It has no `runtime_needed` rows.
10. Effective queue
    `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260625_pg217_saga_draw_artifact_postsync_v1.json`
    reports no package-ready unprepared rows; remaining global operational
    lanes are `manual_mapper_backlog=333`, `split_scope_backlog=74`,
    `runtime_family_backlog=4`, and `blocked_missing_xmage_source=4`.
11. Strategy consistency audit
    `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260625_pg217_saga_draw_artifact_postsync_v1.json`
    passed `18/18`.
12. Full gate
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_111525/summary.json`
    reports `turn_invariants_clean=16`,
    `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`,
    `action_verdict_counts={"ok":7420}`,
    `target_pressure_statuses={"pass":16}`,
    `table_intent_statuses={"pass":16}`,
    `effect_coverage_residual_status=effect_coverage_residual_accepted`,
    `effect_coverage_residual_unaccepted_card_flag_rows=0`,
    `decision_trace_contract_findings=0`,
    `decision_trace_missing_required_fields=0`, and
    `mandatory_gate_divergences=["event_contract_static=review_required"]`.
    The three PG217 cards did not appear in this 16-seed sample; the
    card-specific proof is from the battle harness tests.

Next operational order:

1. Treat the current Lorehold runtime lane as closed: do not add more runtime
   work before benchmarking unless the regenerated matrix reintroduces
   `runtime_needed`.
2. Start with `priority_benchmark_candidate` rows only, using baseline hash
   guard, category-safe cut target, temporary slot optimizer benchmark,
   quality gate, confirmation/handoff artifact, and explicit apply approval.
3. Current top benchmark candidates are `Library of Leng`,
   `Restoration Seminar`, `Reforge the Soul`, `Increasing Vengeance`,
   `Flare of Duplication`, `Monument to Endurance`, `Volcanic Vision`,
   `Big Score`, `Flashback`, `Improvisation Capstone`,
   `Pinnacle Monk // Mystic Peak`, `Pyromancer Ascension`, `Fury Storm`,
   `Return the Favor`, `Hexing Squelcher`, `Invoke Calamity`,
   `Dawn's Truce`, `Tibalt's Trickery`, `Arcane Bombardment`, and
   `Creative Technique`.
4. Keep the global non-Lorehold `runtime_family_backlog=4` separate from the
   Lorehold benchmark lane.

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

## PG217 First Priority Benchmark Checkpoint

The first post-runtime benchmark used the PG217 matrix as an allowlist and did
not apply any deck change.

What changed in tooling:

1. `slot_optimizer.py` now accepts `--candidate-matrix` and
   `--candidate-lane`, then filters candidates to `battle_ready` rows in the
   requested recommendation lane.
2. `master_optimizer_gate_baseline.py` can freeze a baseline from the official
   `battle-strategy-audit` summary, preserving deck, semantic, and ruleset
   hash guards without relying on the slower local baseline runner.
3. `master_optimizer_quality_gate.py` now accepts `--phase`, so isolated
   benchmark phases such as `pg217_priority_matrix_v1` can be reviewed without
   mixing historical rows.

Evidence:

1. Baseline report:
   `docs/hermes-analysis/master_optimizer_reports/master_optimizer_gate_baseline_20260625_114942.md`.
2. Benchmark report:
   `docs/hermes-analysis/master_optimizer_reports/pg217_priority_benchmark_flashback_engine_20260625.md`.
3. Quality gate report:
   `docs/hermes-analysis/master_optimizer_reports/master_optimizer_quality_gate_20260625_115439.md`.
4. Baseline id `9` is tied to deck hash
   `8f719f40b096e17644e1e9308c8f1be9ea2a6c122344d61967cad9fedd358d9f`,
   semantics hash
   `b942018cbf4c67c5011a2d6465832ace4cda6aca67b6020695fb2b9bfb247418`,
   and ruleset hash
   `2f6276b7d7ddb3060a1e6a54119a3658ba95db23b83b8eaa33c20b6ec3427b9f`.
5. `Flashback` replacing `Reverberate` was tested as an `engine` slot:
   baseline `12.5%`, benchmark `8.3%`, delta `-4.2pp`.
6. The quality gate structurally passed the row, but the benchmark result is
   below baseline; therefore no confirmation, handoff, deck apply, or
   PostgreSQL write is authorized from this row.
7. Post-benchmark hash check confirmed the temporary swap restored the deck to
   the baseline hash above.

Next operational order:

1. Continue small, matrix-filtered benchmark batches by category or candidate.
2. Reject any row below baseline before confirmation.
3. Only rows with positive benchmark delta should enter confirmation/full
   confirmation, then handoff, then explicit apply approval.

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
