# Battle Table Intent And Opponent Effectiveness Audit - 2026-06-20

## Scope

Rafael challenged the current Lorehold battle interpretation:

- In real Commander, if Lorehold attacks, removes a permanent, casts a known
  win setup, or becomes visibly ahead, it can become the nemesis/focus of the
  attacked player or of the table.
- A fixed target-pressure mode proves Lorehold is not goldfishing, but it is
  not the same as a real political threat-assessment model.
- The audit also needs to answer whether opponent cards are actually doing
  anything in the simulation.

This is an evidence audit. No PostgreSQL write, deck swap, cleanup, stage,
commit, push, or runtime change was executed by this audit.

## External Rules Baseline

Official rules source checked:

- Wizards rules page:
  `https://magic.wizards.com/en/rules`
- Current Comprehensive Rules TXT linked there:
  `https://media.wizards.com/2026/downloads/MagicCompRules%2020260417.txt`

Rules reading:

- Comprehensive Rules are the official corner-case reference and are meant to
  be consulted for specific rules questions.
- In multiplayer/combat, the active player chooses which player, planeswalker,
  or battle each chosen creature attacks when multiple players can be attacked
  (`508.1b`).
- A defending player chooses blockers only for creatures attacking that player,
  a planeswalker they control, or a battle they protect (`509.1a`, `802.4a`).

Operational interpretation:

- The rules define legal attackers/blockers.
- They do not define human political intention.
- The battle engine needs a separate AI layer for threat, retaliation,
  self-preservation, and table politics.

## Current Code Reading

Relevant code:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  - `threat_score(...)` scores spell-stack danger, including Approach,
    board wipes, extra turns, tutors, draw engines, protection, and silence.
  - `declare_attackers_step(...)` currently chooses targets by fixed
    evaluation target first, then lethal, known Approach caster, strategy,
    threat level, board power, and life.
  - `assign_attackers_to_defenders(...)` allows multi-defender attacks, but
    disables split attacks when target-pressure is active against Lorehold.
  - `declare_blockers_step(...)` is legal-rule-aware: only the attacked player
    blocks, flying/reach are respected, multiple blockers can gang-block, and
    nonlethal sacrifice blocks are often avoided.

Current limitation:

- `target_pressure` is a stress-test target mode, not a real Commander
  political model.
- It currently makes Lorehold the focus even before Lorehold has earned the
  table's hostility.
- It does not model per-player grievance: if Lorehold attacks Player A, Player A
  should remember that more strongly than Players B/C.
- It does not model table-wide archenemy escalation: repeated wins, Approach,
  huge board, high mana, cards in hand, protection, or stax should raise a
  shared threat score.
- It does not model revenge decay or negotiated opportunism. This matters
  because a real player may still kill a low-life third player if that is the
  best route to survive.

## Latest Full-Run Evidence

Latest artifact:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_185748/summary.json`

Summary:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `mandatory_gates_required_for_final_status` includes `target_pressure`
- `target_pressure_statuses={"pass":16}`
- `target_pressure_findings=0`
- `target_pressure_opponent_combat_total=117`
- `target_pressure_opponent_combat_to_target=117`
- `target_pressure_opponent_combat_to_other=0`
- `test_results_status_counts={"pass":17}`

Important reading:

- The latest run proves that the current pressure gate is clean.
- It does not prove that political threat assessment is realistic.
- It does not prove that opponent deck execution is complete enough to treat
  Lorehold win rate as final deck-quality truth.

## Opponent Effectiveness Counts

Measured across the same 16 latest seeds:

| Metric | Lorehold | Opponents | Reading |
| --- | ---: | ---: | --- |
| `spell_cast` | 263 | 106 | Opponents do cast real spells, but much less than Lorehold. |
| `spell_resolved` | 234 | 33 | Opponent resolved spell volume is low. |
| `creature_cast` | n/a in this table | 51 | Opponents do put creatures into play. |
| `commander_cast` | n/a | 8 | Opponent commanders resolve rarely. |
| `land_played` | 122 | 281 | Opponents play lands normally. |
| `combat` | 146 | 117 | Opponents attack frequently under target pressure. |
| `trigger_resolved` | 77 | 44 | Opponent triggers exist, mostly Esper Sentinel. |
| `removal_resolved` | 15 | 3 | Opponent removal interaction is too low. |
| `spell_countered` | n/a | 7 total events | Opponents do counter important spells. |
| `game_won` | 11 | 5 | Opponents won 5/16 seeds in this latest run. |

Concrete opponent interaction observed:

- `Mental Misstep` countered Lorehold `Silence`.
- `An Offer You Can't Refuse` countered Lorehold `Silence`.
- `Flusterstorm` countered Lorehold `The One Ring`.
- `Pact of Negation` countered Lorehold `Twinflame`.
- `Flusterstorm` countered Lorehold `Mizzix's Mastery`.
- `Flusterstorm` countered Lorehold `Blasphemous Act`.
- `Chain of Vapor` bounced Lorehold mana rocks.
- `Swords to Plowshares` removed a Lorehold token.
- `Vexing Bauble` resolved as opponent hate artifact.

Top opponent resolved cards:

- `Noxious Revival`: 6
- `Imperial Seal`: 3
- `Esper Sentinel`: 3
- `Deafening Silence`: 2
- `Chain of Vapor`: 2
- singletons included `Orim's Chant`, `Agatha's Soul Cauldron`,
  `Green Sun's Zenith`, `Vampiric Tutor`, `Swords to Plowshares`,
  `Mystical Tutor`, `Vexing Bauble`, and `Demonic Consultation`.

## Red Flags

### TI-001 - Target pressure is not table politics

Status: open.

Evidence:

- `target_pressure_opponent_combat_to_target=117`
- `target_pressure_opponent_combat_to_other=0`

This is good as a stress-test gate, but it is too rigid as a realism model.

Real model needed:

- self-preservation first: lethal, near-lethal, combo, known alternate win;
- per-player nemesis memory: who attacked/damaged/removed/countered me;
- table threat: board power, mana, cards, Approach count, protection, stax,
  draw engines, tutor chains;
- strategic role: aggro should still pressure life, control should police
  combo/stax, combo should protect its own window;
- decay: old aggression should matter less over turns unless repeated.

### TI-002 - Opponent cards function, but not enough of each deck is live

Status: open.

Evidence:

- Opponents cast `106` noncreature spells, cast `51` creatures, resolved `33`
  spells, and won `5/16` seeds.
- However, opponent `cast_illegal` total was `648`.
- Top repeated illegal cast attempts:
  - `Kinnan, Bonder Prodigy`: 129
  - `Thrasios, Triton Hero`: 107
  - `Tayam, Luminous Enigma`: 95
  - `Etali, Primal Conqueror`: 38
  - `Rograkh, Son of Rohgahh`: 37

Interpretation:

- It is false to say opponent cards do nothing.
- It is also false to say everything is functioning at full Commander-table
  realism.
- The high illegal-cast volume means opponent decks may be spending many turns
  trying impossible commander lines instead of selecting legal alternative
  plays.

### TI-003 - Defensive blocking volume looks too low

Status: open.

Evidence:

- Total blockers declared against opponent attacks: 8.
- Total blockers declared against Lorehold attacks: 8.
- Across `263` combat events, only `16` total blockers were declared.

Interpretation:

- Some of this can be real because of flying, tapped creatures, low creature
  density, and suicide-block avoidance.
- But the blocker volume is low enough that it needs a focused defensive intent
  audit before Lorehold WR can be called final.

### TI-004 - Latest WR is useful but not final deck-quality truth

Status: open.

Evidence:

- Latest target-pressure full run is gate-clean.
- Manual pressure smoke dropped Lorehold from older `100.0%` / `91.7%`
  snapshots to `83.3% (10W/2L/0S)`.
- Latest 16-seed event audit showed Lorehold won `11/16`, opponents won `5/16`.

Interpretation:

- The earlier high WR was plausibly inflated by insufficient pressure and/or
  weak opponent execution.
- The target-pressure correction improved the test.
- The next realism gap is not another deck swap; it is opponent/table-intent
  modeling and opponent legal-action efficiency.

## Required Next Correction

Implement a `table_intent` layer before treating Lorehold as final-best:

1. Add per-player hostility memory:
   - damage received from attacker;
   - permanent removed by attacker;
   - spell countered by attacker;
   - attacked me last N turns;
   - killed another player or reached near-lethal board state.
2. Add table threat score:
   - board power;
   - untapped mana and artifact mana;
   - cards in hand;
   - known Approach/alternate-win count;
   - protection/stax/silence;
   - recent tutor/draw-engine chain.
3. Replace fixed target selection in normal battle mode with weighted scoring:
   - lethal and self-preservation override everything;
   - personal nemesis score biases the attacked player to retaliate;
   - table archenemy score biases all players toward the leader;
   - low-life opportunism remains valid only when it does not ignore an
     imminent winner.
4. Keep `target_pressure` as a stress-test gate, but label it as stress mode,
   not as full realism mode.
5. Add an opponent effectiveness auditor:
   - illegal cast attempts per seed/player/card;
   - resolved nonland actions per opponent turn;
   - blocks available vs blocks chosen;
   - interaction held vs used against high-threat Lorehold actions.

## Current Answer To Rafael's Question

Are opponent cards doing anything?

- Yes. There are real casts, counters, removal, triggers, tutors, creatures,
  attacks, and 5 opponent wins in the latest 16-seed run.

Is everything really functioning?

- No. Current evidence shows partial function, not full realism.
- The biggest current blockers are high illegal commander attempts, low
  opponent resolved-spell volume, low blocker volume, and lack of a real
  per-player threat/nemesis model.

How should Lorehold be evaluated next?

- Do not use raw WR alone.
- Use latest gate-clean target-pressure evidence as a minimum.
- Then add table-intent and opponent-effectiveness gates before accepting a
  deck as truly best.
