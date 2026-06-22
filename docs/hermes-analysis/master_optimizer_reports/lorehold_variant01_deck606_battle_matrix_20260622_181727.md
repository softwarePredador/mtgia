# Lorehold Variant 01 Deck 606 Battle Matrix - 2026-06-22 18:17 UTC

## Scope

This report covers the Lorehold list pasted by Rafael on 2026-06-22, staged as
`Lorehold Variant 01 - Rafael Paste 2026-06-22` and materialized into isolated
Hermes battle deck id `606`.

No official deck `6` swap was applied in this step.

## Intake And Materialization Evidence

- Input deck file:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_input_20260622_142629_deck01.txt`.
- Final staging report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260622_175032.json`.
- Final staging markdown:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260622_175032.md`.
- Deck hash:
  `cde4088aeef9659a963a0725a03c6589f0df1850d07b0f322c12165c88e02752`.
- Materialized target:
  `deck_cards.deck_id=606`.
- Materialization backup id:
  `variant_target_606_20260622T175032Z_07f6e77d53f7`.

Direct SQLite evidence from
`docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`:

- `deck_cards` for deck `606`: `81` rows, `100` total quantity, `1`
  commander, `99` main.
- `lorehold_variant_decks`: `valid|100|99|1|0|0|cde4088aeef9659a`.
- `lorehold_variant_deck_cards`: `81` rows, `81` executable-rule rows,
  `81` oracle-matched rows, `0` warning rows.

## Battle Harness Changes Used By This Run

- `MANALOOM_BATTLE_TARGET_DECK_ID=606` is now supported by
  `battle_replay_v10_3.py`, so candidate decks can be tested without replacing
  official deck `6`.
- `replay.txt` includes current hand cards in turn summaries and final player
  summaries.
- The action critic and replay decision auditor now accept hand sizes above
  seven when a no-maximum-hand-size permanent is visible, such as
  `Library of Leng`, `Reliquary Tower`, or `Thought Vessel`.
- Forensic/event coverage was expanded for the Variant 01 modeled effects:
  `equipment_static_attachment`, `damage_wipe_treasure`, and
  `redistribute_life_totals`.
- Land-tutor artifact decision traces now record rejected alternatives and
  score gaps when multiple targets exist.

## Test Evidence

Passed:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py`
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_replay_decision_auditor_scope.py`
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py`
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_stager.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_variant_stager.py`
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_variant_stager.py`
  passed with `Ran 3 tests`.

## Trusted Battle Matrix

Command:

```bash
MANALOOM_BATTLE_TARGET_DECK_ID=606 \
MANALOOM_BATTLE_STRATEGY_RUN_PROFILE=lorehold_variant01_deck606_16_seed_trusted_final \
MANALOOM_BATTLE_STRATEGY_INVOCATION_KIND=codex_variant01_deck606_16_seed_trusted_final \
/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh \
  --seeds 16 \
  --start-seed 64270200
```

Artifact:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_181727/summary.json`.

Summary:

- `battle_replay_final_status=trusted_for_strategy_learning`.
- `mandatory_gate_divergences=[]`.
- `seeds_completed=16`.
- `test_results_status_counts={"pass":18}`.
- `target_pressure_statuses={"pass":16}`.
- `target_pressure_findings=0`.
- `table_intent_statuses={"pass":16}`.
- `table_intent_findings=0`.
- `action_findings=0`.
- `forensic_severity_counts={}`.
- `decision_audit_severity_counts={"critical":0,"high":0,"low":0,"medium":0}`.
- `lorehold_deck_source_ref=deck_id:606`.
- `lorehold_deck_lands=39`.
- `lorehold_deck_avg_cmc_nonlands=3.333`.

Result:

- Lorehold wins: `1/16` = `6.25%`.
- Opponent wins: `15/16` = `93.75%`.

Winner list:

- `seed_64270200`: Kinnan, Bonder Prodigy #104.
- `seed_64270201`: Kraum, Ludevic's Opus #83.
- `seed_64270202`: Tayam, Luminous Enigma #25.
- `seed_64270203`: Kinnan, Bonder Prodigy #84.
- `seed_64270204`: Dargo, the Shipwrecker #74.
- `seed_64270205`: Tayam, Luminous Enigma #25.
- `seed_64270206`: Rograkh, Son of Rohgahh #62.
- `seed_64270207`: Tayam, Luminous Enigma #25.
- `seed_64270208`: Lorehold.
- `seed_64270209`: Rograkh, Son of Rohgahh #62.
- `seed_64270210`: Rograkh, Son of Rohgahh #62.
- `seed_64270211`: The Emperor of Palamecia #42.
- `seed_64270212`: Tayam, Luminous Enigma #25.
- `seed_64270213`: Dargo, the Shipwrecker #74.
- `seed_64270214`: Thrasios, Triton Hero #58.
- `seed_64270215`: Thrasios, Triton Hero #54.

## Replay Proof

Replay:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_181727/seed_64270208/replay.txt`.

Deck provenance:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_181727/seed_64270208/deck_provenance.json`.

Provenance confirms:

- `source_ref=deck_id:606`.
- `target_deck_id=606`.
- `source_kind=sqlite_deck_cards`.
- `construction_report.is_valid=true`.
- `total_quantity=100`, `main_quantity=99`, `commander_count=1`.
- `off_color_cards=[]`.
- `singleton_violations=[]`.

Replay excerpt reading:

- Turn 10: Lorehold plays `Reliquary Tower`, casts `Sol Ring` and
  `Boros Signet`, then attacks Kinnan for lethal `25` combat damage.
- Turn 11: Lorehold casts `Mithril Coat` and `Restoration Seminar`, then
  attacks Thrasios for lethal `25` combat damage.
- Final: `Winner: Lorehold (elimination)`.
- Final Lorehold hand:
  `HandCards=[Wheel of Fortune, Increasing Vengeance, Tibalt's Trickery, Flare of Duplication]`.

## Strategic Reading

This candidate should not replace the official PG026 deck state.

Reason:

- Official PG026 baseline won `6/16` in
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_170304/summary.json`.
- Variant 01 won `1/16` under a clean trusted matrix.
- The lower result is strategic, not a known gate artifact: target pressure,
  table intent, action critic, forensic audit, decision audit, and harness tests
  were clean.

Current inference, based on replay and matrix evidence:

- Variant 01 has many powerful high-impact effects, but it loses too often
  before converting those cards into stable protection or a win line.
- It can win when it assembles a wide board and survives long enough to attack,
  but that plan is not reliable under table pressure.
- It is a useful rejected candidate for learning, not a promotion candidate.

## Next Workflow For Future Decklists

Use the same candidate path for every new Lorehold list:

1. Save the pasted list as a deck input text file.
2. Run `lorehold_variant_stager.py --fail-on-invalid` to validate exact
   quantity, commander shape, oracle resolution, color identity, singleton
   rules, and executable battle-rule coverage.
3. Materialize each valid candidate into an isolated deck id such as `606`,
   `607`, `608`, not official deck `6`.
4. Run the trusted battle matrix with
   `MANALOOM_BATTLE_TARGET_DECK_ID=<candidate_deck_id>`.
5. Compare against the current official baseline before any PostgreSQL deck
   swap is considered.

Promotion rule:

- Do not deploy a candidate deck to PostgreSQL unless it beats the official
  baseline in a trusted matrix and its relevant replay evidence explains why.
