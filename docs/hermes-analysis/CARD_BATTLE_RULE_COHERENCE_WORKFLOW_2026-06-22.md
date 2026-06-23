# Card Battle Rule Coherence Workflow - 2026-06-22

## Purpose

Make every card used by deck generation and battle simulation pass the same
care level applied to PG025 `The One Ring` / `Orim's Chant`.

This workflow exists because a card can look "covered" while still carrying a
generic or wrong model such as `draw_engine`, `ramp_permanent`, `copy_spell`,
`board_wipe`, `silence_spell`, or a lingering `needs_review` shadow row.

## Source Boundary

- PostgreSQL `card_battle_rules` remains the product source of truth.
- Hermes SQLite `battle_card_rules` / `deck_cards` is the local audit/runtime
  surface.
- No card should be promoted just because it appears in replay or has a broad
  functional tag.
- `needs_review` and `review_only` rows are audit evidence, not trusted battle
  behavior.

## Audit Tool

Script:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --limit 200
```

Latest baseline report from this setup:

- JSON:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_184733.json`
- Markdown:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_184733.md`

Initial result:

- Distinct deck cards audited: `145`.
- `high=97`.
- `medium=40`.
- `pass=8`.

Top finding families:

- `review_only_or_needs_review_rule`: `133`.
- `trusted_rule_without_oracle_hash`: `99`.
- `generic_effect_without_model_scope`: `43`.

This does not mean all actionable cards are broken at runtime. It means they
are not yet clean enough to be considered One Ring-level trusted for deck
generation and battle learning.

The 18:47 UTC review adjusted the queue shape: land-only `needs_review` /
`review_only` rows now remain actionable but move to `medium` and
`impact_tier=land_or_mana_base`, so battle-critical effects such as wipe,
protection, tutor, draw, copy, counter, silence, recursion, and wincon are
worked first.

## Required Card Gate

A deck card is not coherent until all applicable checks are true:

1. Oracle/type identity is present, or an explicit no-text exception is
   documented.
2. The active rule uses the correct `card_battle_rules` row by
   `logical_rule_key`.
3. Broad generated/heuristic behavior is replaced or disabled when it can shadow
   the reviewed rule.
4. Complex effects include `battle_model_scope` or equivalent oracle-specific
   marker.
5. Trusted rows have `source`, `review_status`, `execution_status`,
   `oracle_hash`, and stable `logical_rule_key`.
6. The behavior has focused unit tests for positive and negative cases.
7. Replay/events prove the selected `logical_rule_key` in a real or focused
   battle when the behavior is battle-relevant.
8. PostgreSQL precheck/apply/postcheck/rollback package exists before any
   durable data change.
9. SQLite/Hermes sync from PostgreSQL is run and reported after apply.
10. Living docs/registers are updated with evidence and remaining risk.

## Priority Order

Process the queue in this order:

1. `critical` cards first, if any.
2. `high` cards with `impact_tier=battle_critical`, especially cards that
   appear in multiple decks or are commanders.
3. `high` cards with effects that directly change battle outcomes:
   protection, counter, silence, board wipe, copy spell, tutor, wheel, draw
   engine, extra turn, recursion, wincon, attack tax/limit, removal.
4. `high` cards with `impact_tier=battle_support`, especially mana acceleration
   that changes turn timing.
5. `medium` findings such as trusted rows missing oracle hash.
6. Lands with only generic land modeling after higher-risk spells are clean.

## One Ring Standard

PG025 is the model to copy:

- It identified the old broad rule as wrong/incomplete.
- It created exact rules for each behavior.
- It disabled legacy shadow rows.
- It validated PostgreSQL precheck/apply/postcheck/rollback.
- It synced SQLite/Hermes from PostgreSQL.
- It proved runtime resolution by `logical_rule_key`.
- It added unit tests.
- It proved behavior in replay/events.
- It separated card correctness from deck win rate.

## Persistent Goal Command

Use this exact goal for the next long-running execution:

```text
Trabalhe em modo persistente, por múltiplos turnos/dias se necessário. Seu objetivo é deixar coerentes, carta por carta, todas as cartas cadastradas em decks para battle e criação de decks, usando o padrão de cuidado aplicado ao PG025 The One Ring / Orim's Chant.

Antes de agir, leia o estado real do repo, rode git status, respeite mudanças não feitas por você, não faça commit/push sem concluir e validar um checkpoint coerente, e não faça promoção cega. PostgreSQL é a fonte de verdade; Hermes SQLite é cache/lab/runtime. Toda alteração durável de regra de carta deve ter pacote PostgreSQL com precheck, apply, postcheck e rollback, sync SQLite/Hermes a partir do PG, testes, replay/eventos quando aplicável e atualização dos registros vivos.

Leia obrigatoriamente:
- docs/CONTEXTO_PRODUTO_ATUAL.md
- docs/hermes-analysis/PROJECT_MEMORY.md
- docs/hermes-analysis/CARD_BATTLE_RULE_COHERENCE_WORKFLOW_2026-06-22.md
- docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md
- docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md
- docs/hermes-analysis/POSTGRES_DEPLOY_REGISTER_2026-06-20.md
- docs/hermes-analysis/LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md

Comece validando a fonte de dados: confirme que o snapshot SQLite/Hermes usado pelo auditor foi sincronizado a partir do PostgreSQL mais recente, ou gere novo sync antes de concluir qualquer carta. Em caso de divergência, PostgreSQL vence. Depois rode:
python3 docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --limit 200

Use o relatório gerado como fila de trabalho. Para cada carta, em prioridade critical > high/battle_critical > high/battle_support > medium:
1. Leia oracle/type/faces e regras já existentes em card_battle_rules/SQLite/Hermes.
2. Compare a regra atual com a intenção real da carta; marque qualquer inferência como inferência.
3. Se houver regra genérica, needs_review/review_only, shadow row ou ausência de battle_model_scope, corrija com regra específica e teste focado.
4. Se exigir mudança durável, gere pacote PG com precheck/apply/postcheck/rollback, aplique no PostgreSQL somente quando o pacote estiver validado, e rode sync SQLite/Hermes do PG.
5. Rode testes unitários focados e o conjunto relevante de battle/replay.
6. Quando a carta afetar combate, proteção, draw, tutor, copy, wipe, counter, silence, wincon ou mana decisiva, gere replay/eventos provando a logical_rule_key usada.
7. Atualize BATTLE_VALIDATION_REGISTER, BATTLE_REPLAY_GATE_MATRIX, POSTGRES_DEPLOY_REGISTER e o relatório de coerência da rodada.
8. Reexecute deck_card_battle_rule_coherence_audit.py e só considere a carta fechada quando ela sair da fila ou tiver exceção documentada com evidência.

Não deixe correção apenas em código se a regra pertence ao banco. Não use functional tag como substituto de regra executável. Não resolva fanout apagando regras válidas. Preserve múltiplos efeitos quando a carta tiver múltiplas funções. Ao final de cada ciclo entregue: cartas fechadas, cartas ainda abertas, pacotes PG aplicados, testes rodados, replays usados como prova, registros atualizados, status do worktree e próximo lote recomendado.
```

## Cycle Result - PG028 Austere Command - 2026-06-22 19:10 UTC

Input/source check:

- The first SQLite/Hermes snapshot check found global divergence from
  PostgreSQL, so PostgreSQL won.
- `knowledge.db` was backed up, then refreshed from PostgreSQL with
  `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review`
  before trusting the queue.

Closed card:

- `Austere Command`.
- Closure rule:
  `battle_rule_v1:5f19a608b87445bcc5c7ebb7ad96eb64`.
- Oracle hash:
  `bce631c9a75d6856dd8c0d7de442b47f`.
- Model scope:
  `austere_command_choose_two_destroy_modes_v1`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_battle_rule_pg028_precheck_20260622_190701.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_battle_rule_pg028_apply_20260622_190701.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_battle_rule_pg028_postcheck_20260622_190701.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_battle_rule_pg028_rollback_20260622_190701.sql`.

Tests and event proof:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_pg028_focused_replay_summary_20260622_190701.md`.

Output audit:

- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_190930.json`
  and `.md`.
- Result after PG028: `high=96`, `medium=39`, `pass=10`.
- `Austere Command` moved to `pass`.

Next recommended card:

- `Blasphemous Act`.

## Cycle Result - PG029 Blasphemous Act - 2026-06-22 19:29 UTC

Input/source check:

- The cycle started by refreshing `knowledge.db` from PostgreSQL with
  `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review`.
- Sync evidence: `pg_rows_loaded=5270`, `sqlite_inserted_or_updated=5237`.
- The required auditor then generated
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_191754.json`
  and `.md`, with `Blasphemous Act` first in the queue.

Closed card:

- `Blasphemous Act`.
- Closure rule:
  `battle_rule_v1:56271789d639ef390213dbc90059e4d2`.
- Oracle hash:
  `826022a579db4551b45ad35e4cfab973`.
- Model scope:
  `blasphemous_act_damage_13_each_creature_v1`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_battle_rule_pg029_precheck_20260622_192517.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_battle_rule_pg029_apply_20260622_192517.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_battle_rule_pg029_postcheck_20260622_192517.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_battle_rule_pg029_rollback_20260622_192517.sql`.

Tests and event proof:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_pg029_focused_replay_summary_20260622_192517.md`.

Output audit:

- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_192856.json`
  and `.md`.
- Result after PG029: `high=95`, `medium=39`, `pass=11`.
- `Blasphemous Act` moved to `pass`.

Known caveat:

- The oracle cost reduction is stored in the rule as `annotation_only`
  metadata. This cycle implemented and proved the damage-wipe resolution; it
  did not add dynamic generic cost reduction to the casting/payment planner.

Next recommended card:

- `Boros Charm`.

## Cycle Result - PG030 Boros Charm - 2026-06-22 19:42 UTC

Input/source check:

- The cycle started with `git status --short --branch`; the worktree already
  had PG028/PG029 changes and untracked audit artifacts, all preserved.
- `knowledge.db` was refreshed from PostgreSQL before the required auditor:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_coherence_goal_cycle3_20260622_193408.json`.
- Sync evidence: `pg_rows_loaded=5271`, `sqlite_inserted_or_updated=5238`.
- The required auditor then generated
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_193423.json`
  and `.md`, with `Boros Charm` first in the queue.

Closed card:

- `Boros Charm`.
- Closure rule:
  `battle_rule_v1:32605a838d7a519f44eaa0899d2c40bf`.
- Oracle hash:
  `98a7be829075118b499a7c283a23501f`.
- Model scope:
  `boros_charm_choose_one_damage_indestructible_double_strike_v1`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_battle_rule_pg030_precheck_20260622_193818.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_battle_rule_pg030_apply_20260622_193818.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_battle_rule_pg030_postcheck_20260622_193818.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_battle_rule_pg030_rollback_20260622_193818.sql`.

Runtime/test changes:

- `modal_boros_charm` now models the oracle-specific indestructible mode as
  all permanents controlled by the player until EOT, not only creatures.
- `modal_boros_charm` now models the double-strike mode as exactly one target
  creature until EOT, not all creatures.
- `modal_boros_charm_resolved` events now include selected mode, affected
  permanents, logical rule key, and oracle hash.

Tests and event proof:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_pg030_focused_events_20260622_193818.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_pg030_focused_replay_summary_20260622_193818.md`.

Output audit:

- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_194227.json`
  and `.md`.
- Result after PG030: `high=94`, `medium=39`, `pass=12`.
- `Boros Charm` moved to `pass`.

Known caveat:

- The 4 damage player/planeswalker mode is stored in the rule as
  `annotation_only` metadata. This cycle proved the protection and combat
  modes; it did not add direct modal damage target selection.

Next recommended card:

- `Deflecting Swat`.

## Cycle Result - PG031 Deflecting Swat - 2026-06-22 19:56 UTC

Input/source check:

- The cycle started with `git status --short --branch`; the worktree already
  had PG028-PG030 changes and untracked audit artifacts, all preserved.
- `knowledge.db` was refreshed from PostgreSQL before the required auditor:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_coherence_goal_cycle4_20260622_194558.json`.
- Sync evidence: `pg_rows_loaded=5272`, `sqlite_inserted_or_updated=5239`.
- The required auditor then generated
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_194612.json`
  and `.md`, with `Deflecting Swat` first in the queue.

Closed card:

- `Deflecting Swat`.
- Closure rule:
  `battle_rule_v1:bac48343654a53205d790a8268bd2631`.
- Oracle hash:
  `a34c89817f87f32bedfb3d66a5bdc672`.
- Model scope:
  `deflecting_swat_control_commander_free_redirect_target_spell_or_ability_v1`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_battle_rule_pg031_precheck_20260622_195126.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_battle_rule_pg031_apply_20260622_195126.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_battle_rule_pg031_postcheck_20260622_195126.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_battle_rule_pg031_rollback_20260622_195126.sql`.

Runtime/test changes:

- `redirect_removal` can now use an oracle-specific alternative cost of `{0}`
  when the controller controls a commander.
- Redirect target selection now prefers legal targets not controlled by the
  redirecting player, avoiding self-harm when an opponent target is legal.
- `damage_wipe` is now scored as a board-wipe threat, so protection responses
  such as Boros Charm trigger correctly against Blasphemous Act PG029.

Tests and event proof:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_pg031_focused_events_20260622_195126.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_pg031_focused_replay_summary_20260622_195126.md`.

Output audit:

- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_195607.json`
  and `.md`.
- Result after PG031: `high=93`, `medium=39`, `pass=13`.
- `Deflecting Swat` moved to `pass`.

Known caveat:

- The PG031 rule stores the full oracle target class as
  `target_spell_or_ability`, but the current runtime proof covers
  `single_target_targeted_removal_spell`; activated/triggered ability target
  redirection remains `annotation_only` metadata.

Next recommended card:

- `Flawless Maneuver`.

## Cycle Result - PG032 Flawless Maneuver - 2026-06-22 20:10 UTC

Input/source check:

- The cycle started with `git status --short --branch`; the worktree already
  had PG028-PG031 changes and untracked audit artifacts, all preserved.
- `knowledge.db` was refreshed from PostgreSQL before the required auditor:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_coherence_goal_cycle5_20260622_200215.json`.
- Sync evidence: `pg_rows_loaded=5273`, `sqlite_inserted_or_updated=5240`.
- The required auditor then generated
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_200233.json`
  and `.md`, with `Flawless Maneuver` first in the queue.

Closed card:

- `Flawless Maneuver`.
- Closure rule:
  `battle_rule_v1:73622071c1ad89267708f914a0729bf2`.
- Oracle hash:
  `fa955216fa827bf75c5b79dcbdb4b97e`.
- Model scope:
  `flawless_maneuver_control_commander_free_creatures_indestructible_until_eot_v1`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_battle_rule_pg032_precheck_20260622_200215.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_battle_rule_pg032_apply_20260622_200215.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_battle_rule_pg032_postcheck_20260622_200215.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_battle_rule_pg032_rollback_20260622_200215.sql`.

Runtime/test changes:

- Stack-protection responses now use `card_cost_for_effect(...)`, so
  oracle-specific alternative costs such as commander-controlled `{0}` are
  honored for protection spells.
- `indestructible` protection resolution now emits `protection_resolved`
  events with affected creatures and rule provenance.

Tests and event proof:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_events_20260622_200215.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_replay_summary_20260622_200215.md`.

Output audit:

- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_201035.json`
  and `.md`.
- Result after PG032: `high=92`, `medium=39`, `pass=14`.
- `Flawless Maneuver` moved to `pass`.

Known caveat:

- This proof covers the oracle protection mode under a board-wipe response. It
  does not claim broader Magic rules equivalence beyond creatures you control
  gaining indestructible until end of turn.

Carry-forward caveat from PG029:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## Cycle Result - PG033 Land Tax - 2026-06-22 20:25 UTC

Input/source check:

- The cycle started with `git status --short --branch`; the worktree already
  had PG028-PG032 changes and untracked audit artifacts, all preserved.
- `knowledge.db` was refreshed from PostgreSQL before the required auditor:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_coherence_goal_cycle6_20260622_201417.json`.
- Sync evidence: `pg_rows_loaded=5274`, `sqlite_inserted_or_updated=5241`.
- The required auditor then generated
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_201436.json`
  and `.md`, with `Land Tax` first in the queue.

Closed card:

- `Land Tax`.
- Closure rule:
  `battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef`.
- Oracle hash:
  `83b074e38da3e6c4eb6ec3e7568c914b`.
- Model scope:
  `land_tax_upkeep_opponent_more_lands_basic_land_tutor_to_hand_v1`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_battle_rule_pg033_precheck_20260622_201417.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_battle_rule_pg033_apply_20260622_201417.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_battle_rule_pg033_postcheck_20260622_201417.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_battle_rule_pg033_rollback_20260622_201417.sql`.

Runtime/test changes:

- Added `land_tax` as an executable permanent/card-flow effect.
- Beginning-of-upkeep processing now checks whether any live opponent controls
  more lands than the controller, then moves up to three basic land cards from
  library to hand.
- Replay events and decision traces include the PG033 logical rule key and
  oracle hash.

Tests and event proof:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_pg033_focused_events_20260622_201417.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/land_tax_pg033_focused_decision_trace_20260622_201417.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/land_tax_pg033_focused_replay_summary_20260622_201417.md`.

Output audit:

- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_202458.json`
  and `.md`.
- Result after PG033: `high=91`, `medium=39`, `pass=15`.
- `Land Tax` moved to `pass`.

Known caveat:

- Reveal and shuffle are represented as structured replay metadata in the
  focused deterministic proof; the simulator does not randomize library order
  after the Land Tax search.

Carry-forward caveat from PG029:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

Next recommended card:

- `Lightning Greaves`.

## Cycle Result - PG034 Lightning Greaves - 2026-06-22 20:36 UTC

Input/source check:

- The cycle started with `git status --short --branch`; the worktree already
  had PG028-PG033 changes and untracked audit artifacts, all preserved.
- `knowledge.db` was refreshed from PostgreSQL before the required auditor:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_coherence_goal_cycle7_20260622_202908.json`.
- Sync evidence: `pg_rows_loaded=5275`, `sqlite_inserted_or_updated=5242`.
- The required auditor then generated
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_202922.json`
  and `.md`, with `Lightning Greaves` first in the queue.

Closed card:

- `Lightning Greaves`.
- Closure rule:
  `battle_rule_v1:5ea7f2a8349a93ea46e05b60ee8cdaac`.
- Oracle hash:
  `4a4c71d3cc58637cf00a3d7fe2331353`.
- Model scope:
  `lightning_greaves_auto_attach_haste_shroud_equip_0_v1`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_battle_rule_pg034_precheck_20260622_202908.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_battle_rule_pg034_apply_20260622_202908.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_battle_rule_pg034_postcheck_20260622_202908.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_battle_rule_pg034_rollback_20260622_202908.sql`.

Runtime/cache/test changes:

- Consolidated Lightning Greaves to one PostgreSQL active rule with oracle hash
  and disabled two curated duplicates plus the generated `indestructible`
  shadow row.
- Updated `reviewed_battle_card_rules.json` for the same rule key because the
  first PG034 SQLite sync exposed stale local reviewed-runtime filtering that
  otherwise hid the new active PG row from Hermes.
- `equipment_attached` and `equipment_unattached` events now include rule
  provenance from `replay_rule_fields(...)`.
- The existing focused test now asserts the PG034 rule key, oracle hash,
  haste/shroud grants, and absence of indestructible.

Tests and event proof:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py docs/hermes-analysis/manaloom-knowledge/scripts/reviewed_battle_card_rules.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_pg034_focused_events_20260622_202908.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_pg034_focused_replay_summary_20260622_202908.md`.

Output audit:

- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_203604.json`
  and `.md`.
- Result after PG034: `high=90`, `medium=39`, `pass=16`.
- `Lightning Greaves` moved to `pass`.

Known caveat:

- The runtime model remains the existing battle approximation:
  `auto_attach_best_creature_on_resolution`. It proves haste/shroud and rejects
  the old `indestructible` shadow, but it does not model full Magic Equipment
  attach/retarget timing.

Carry-forward caveat from PG029:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

Next recommended card:

- `Lorehold, the Historian`.

## Cycle Result - PG035 Lorehold, the Historian - 2026-06-22 20:52 UTC

Input/source check:

- The cycle started with `git status --short --branch`; the worktree already
  had PG028-PG034 changes and untracked audit artifacts, all preserved.
- `knowledge.db` was refreshed from PostgreSQL before the required auditor:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_coherence_goal_cycle8_20260622_204147.json`.
- Sync evidence: `pg_rows_loaded=5276`, `sqlite_inserted_or_updated=5242`.
- The required auditor then generated
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_204200.json`
  and `.md`, with `Lorehold, the Historian` first in the queue.

Closed card:

- `Lorehold, the Historian`.
- Closure rule:
  `battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4`.
- Oracle hash:
  `f1b6d4f38a533e56f0efb5a3f1547214`.
- Model scope:
  `lorehold_opponent_upkeep_miracle_v1`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_battle_rule_pg035_precheck_20260622_204549.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_battle_rule_pg035_apply_20260622_204549.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_battle_rule_pg035_postcheck_20260622_204549.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_battle_rule_pg035_rollback_20260622_204549.sql`.

Runtime/cache/test changes:

- Promoted Lorehold to one oracle-specific PostgreSQL active rule with
  `cmc=5.0`, `flying=true`, `haste=true`, miracle `{2}` and opponent-upkeep
  rummage metadata.
- Disabled the old `commander` legacy row, the old `cmc=4.0` passive row, and
  the generated `draw_engine` shadow row as `deprecated`/`disabled`.
- Updated `reviewed_battle_card_rules.json` for the new PG035 payload so the
  local reviewed-runtime filter keeps the new PostgreSQL rule in Hermes.
- `lorehold_upkeep_rummage` and `lorehold_upkeep_rummage_skipped` replay
  events now include Lorehold rule provenance from `replay_rule_fields(...)`.
- Added a focused test proving the PG035 logical rule key and oracle hash on
  the upkeep rummage event.

Tests and event proof:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py docs/hermes-analysis/manaloom-knowledge/scripts/reviewed_battle_card_rules.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed, including
  `test_lorehold_upkeep_rummage_emits_pg035_rule_provenance`.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_pg035_focused_events_20260622_204549.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_pg035_focused_decision_trace_20260622_204549.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_pg035_focused_replay_summary_20260622_204549.md`.

Output audit:

- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_205233.json`
  and `.md`.
- Result after PG035: `high=89`, `medium=39`, `pass=17`.
- `Lorehold, the Historian` moved to `pass`.

Known caveat:

- The runtime model remains the documented battle approximation:
  opponent-upkeep discard-then-draw and first-draw miracle windows are modeled,
  but full Magic policy edges around all miracle/replacement/timing choices are
  not claimed.

Carry-forward caveat from PG029:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

Next recommended card:

- `Past in Flames`.

## Cycle Result - PG036 Past in Flames - 2026-06-22 21:11 UTC

Input/source check:

- The cycle resumed with `git status --short --branch`; the worktree already
  had PG028-PG035 changes and untracked audit artifacts, all preserved.
- Initial PostgreSQL sync attempt timed out, then a direct `select now()` check
  on `143.198.230.247:5433/halder` passed and the retry sync succeeded.
- `knowledge.db` was refreshed from PostgreSQL before the required auditor:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_coherence_goal_cycle9_retry_20260622_205904.json`.
- Sync evidence: `pg_rows_loaded=5277`, `sqlite_inserted_or_updated=5242`,
  `canonical_snapshot_rows_exported=3201`.
- The required auditor then generated
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_205918.json`
  and `.md`, with `Past in Flames` first in the queue.

Closed card:

- `Past in Flames`.
- Closure rule:
  `battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be`.
- Oracle hash:
  `12f293d8d746fbc4e5ba80828919dec5`.
- Model scope:
  `past_in_flames_graveyard_instants_sorceries_flashback_until_eot_v1`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_battle_rule_pg036_precheck_20260622_210425.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_battle_rule_pg036_apply_20260622_210425.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_battle_rule_pg036_postcheck_20260622_210425.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_battle_rule_pg036_rollback_20260622_210425.sql`.

Runtime/cache/test changes:

- Promoted Past in Flames to one oracle-specific PostgreSQL active rule that
  grants temporary flashback to instant/sorcery cards in the controller
  graveyard until end of turn, with flashback cost equal to each card's
  `mana_cost`.
- Disabled the old curated generic `recursion` row and generated
  `needs_review`/`review_only` `recursion` shadow row as
  `deprecated`/`disabled`.
- Added `graveyard_flashback_grant` runtime executor and categorized it as an
  engine/high-impact battle effect.
- Extended cleanup to restore temporary graveyard card fields and added
  `flashback_granted_by`/`flashback_granted_rule_key` provenance to
  `flashback_cast`.
- Synced Hermes SQLite from PostgreSQL after apply:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg036_past_in_flames_20260622_210425.json`.
- Direct SQLite/runtime check selected active PG036:
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=12f293d8d746fbc4e5ba80828919dec5`.
- Added focused test
  `test_past_in_flames_grants_flashback_with_pg036_rule_provenance`.

Tests and event proof:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed, including
  `test_past_in_flames_grants_flashback_with_pg036_rule_provenance`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`
  passed (`Ran 5 tests`).
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_pg036_focused_events_20260622_210425.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_pg036_focused_replay_summary_20260622_210425.md`.

Output audit:

- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_211117.json`
  and `.md`.
- Result after PG036: `high=88`, `medium=39`, `pass=18`.
- `Past in Flames` moved to `pass` with one active trusted executable
  `graveyard_flashback_grant` rule.

Known caveat:

- The runtime model is the current battle approximation for Past in Flames:
  temporary flashback grant and cast provenance are modeled; full priority and
  timing policy for every possible flashback spell is not claimed. The base
  exile-on-resolution flashback path remains covered by
  `test_flashback_cast_from_graveyard_exiles_after_resolution`.

Carry-forward caveat from PG029:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

Next recommended card:

- `Path to Exile`.

## PG037 Path to Exile Closure - 2026-06-22 21:25 UTC

Closed card:

- `Path to Exile`.
- Closure rule:
  `battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd`.
- Oracle hash:
  `861c960a37be744e45f13200349e2532`.
- Model scope:
  `path_to_exile_creature_exile_basic_land_compensation_annotation_v1`.

Rule/runtime changes:

- Promoted one PostgreSQL active executable rule with
  `destination=exile`, `exile_target=true`, and oracle hash coverage.
- Marked the target-controller basic-land rider as
  `basic_land_compensation_status=annotation_only`; no dynamic
  search/shuffle/ramp executor is claimed.
- Disabled three stale/shadow rows as `deprecated`/`disabled`: the old active
  curated row without `oracle_hash`, the old generic verified row, and the
  generated `needs_review`/`review_only` row.
- Added `removal_destination()` runtime fallback so `exile_target=true` also
  resolves to exile when a stale rule lacks explicit `destination`.
- Added removal replay provenance fields for `removal_resolved` events.
- Added focused unit test
  `test_path_to_exile_exiles_creature_with_pg037_rule_provenance`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/path_to_exile_battle_rule_pg037_precheck_20260622_212057.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/path_to_exile_battle_rule_pg037_apply_20260622_212057.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/path_to_exile_battle_rule_pg037_postcheck_20260622_212057.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/path_to_exile_battle_rule_pg037_rollback_20260622_212057.sql`.

Evidence:

- PG precheck: `card_rows=1`, `distinct_oracle_ids=1`,
  `expected_oracle_hash_rows=1`, `exact_executable_rule_rows=0`,
  `legacy_enabled_removal_rows=3`,
  `trusted_executable_without_oracle_hash_rows=2`.
- PG apply: backup table
  `manaloom_deploy_audit.pg037_path_to_exile_battle_rule_20260622_212057`
  captured `3` rows; apply inserted `1` active rule and updated `3` old rows.
- PG postcheck: `exact_executable_rule_rows=1`,
  `legacy_enabled_removal_rows=0`,
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg037_path_to_exile_20260622_212057.json`.
- Direct runtime check selected PG037 with
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=861c960a37be744e45f13200349e2532`.
- Tests passed:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/path_to_exile_pg037_focused_events_20260622_212057.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/path_to_exile_pg037_focused_replay_summary_20260622_212057.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_212554.json`
  and `.md`.

Auditor result:

- `Path to Exile` moved to `pass`.
- Post-cycle counts: `high=87`, `medium=39`, `pass=19`.
- Next queue head: `Reverberate`.

Carry-forward caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG038 Reverberate Closure - 2026-06-22 21:43 UTC

Closed card:

- `Reverberate`.
- Closure rule:
  `battle_rule_v1:0269136edf067f696c8576740b720e14`.
- Oracle hash:
  `cbae05dee4261e3ed5412fd5f3591c17`.
- Model scope:
  `reverberate_copy_stack_instant_or_sorcery_new_targets_annotation_v1`.

Rule/runtime changes:

- Promoted one PostgreSQL active executable rule for
  `copy_spell` targeting `instant_or_sorcery_on_stack`.
- Disabled the stale curated row without `oracle_hash` and the generated
  `needs_review`/`review_only` shadow row as `deprecated`/`disabled`.
- Added runtime response handling so `Reverberate` can be cast in response to
  an instant or sorcery on the stack, create a non-cast copy, and resolve the
  copy through the normal stack path.
- Added copy zone handling: copied spells cease to exist after resolving or
  being countered instead of entering a graveyard.
- Retained `may_choose_new_targets` as metadata with
  `choose_new_targets_status=annotation_only`; no dynamic retarget executor is
  claimed.
- Added focused unit test
  `test_reverberate_copies_stack_spell_with_pg038_rule_provenance`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/reverberate_battle_rule_pg038_precheck_20260622_213615.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/reverberate_battle_rule_pg038_apply_20260622_213615.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/reverberate_battle_rule_pg038_postcheck_20260622_213615.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/reverberate_battle_rule_pg038_rollback_20260622_213615.sql`.

Evidence:

- PG precheck: `card_rows=1`, `distinct_oracle_ids=1`,
  `expected_oracle_hash_rows=1`, `exact_executable_rule_rows=0`,
  `legacy_enabled_copy_rows=2`,
  `trusted_executable_without_oracle_hash_rows=1`.
- PG apply: backup table
  `manaloom_deploy_audit.pg038_reverberate_battle_rule_20260622_213615`
  captured `2` rows; apply inserted `1` active rule and updated `2` old rows.
- PG postcheck: `exact_executable_rule_rows=1`,
  `legacy_enabled_copy_rows=0`,
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg038_reverberate_20260622_213615.json`.
- Direct runtime check selected PG038 with
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=cbae05dee4261e3ed5412fd5f3591c17`.
- Tests passed:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_support.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/reverberate_pg038_focused_events_20260622_213615.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/reverberate_pg038_focused_replay_summary_20260622_213615.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_215028.json`
  and `.md`.

Auditor result:

- `Reverberate` moved to `pass`.
- Post-cycle counts: `high=86`, `medium=39`, `pass=20`.
- Next queue head: `Sensei's Divining Top`.

Carry-forward caveats:

- `Reverberate` target retargeting remains `annotation_only`; PG038 proves
  stack copy creation/resolution, not dynamic target reassignment.
- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG039 Sensei's Divining Top Closure - 2026-06-22 22:01 UTC

Closed card:

- `Sensei's Divining Top`.
- Closure rule:
  `battle_rule_v1:70c8478871f352b46cee1af296117951`.
- Oracle hash:
  `f2c5ac0f52963cd710470adc25cc6d7c`.
- Model scope:
  `senseis_top_reorder_draw_lorehold_first_draw_miracle_v1`.

Rule/runtime changes:

- Promoted one PostgreSQL active executable rule for `topdeck_manipulation`
  with `{1}` top-three peek/reorder and restricted draw-put-self-on-top
  metadata.
- Disabled the stale curated rows without `oracle_hash` and the generated
  `needs_review`/`review_only` `draw_cards` shadow row as
  `deprecated`/`disabled`.
- Retained generic activated draw policy as
  `generic_draw_activation_status=annotation_only`; the executable runtime is
  limited to Lorehold first-draw planning and the current miracle window.
- Added rule provenance to `topdeck_manipulation_activated` events emitted by
  the Lorehold topdeck-artifact executor.
- Updated the reviewed runtime cache so SQLite/Hermes selects the active
  PostgreSQL logical rule key instead of the old fallback row.
- Strengthened focused unit coverage in
  `test_senseis_top_sets_up_lorehold_approach_second_cast`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/senseis_divining_top_battle_rule_pg039_precheck_20260622_215306.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/senseis_divining_top_battle_rule_pg039_apply_20260622_215306.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/senseis_divining_top_battle_rule_pg039_postcheck_20260622_215306.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/senseis_divining_top_battle_rule_pg039_rollback_20260622_215306.sql`.

Evidence:

- PG precheck: `card_rows=1`, `distinct_oracle_ids=1`,
  `expected_oracle_hash_rows=1`, `exact_executable_rule_rows=0`,
  `legacy_enabled_topdeck_rows=3`,
  `trusted_executable_without_oracle_hash_rows=2`.
- PG apply: backup table
  `manaloom_deploy_audit.pg039_senseis_top_battle_rule_20260622_215306`
  captured `3` rows; apply inserted `1` active rule and updated `3` old rows.
- PG postcheck: `exact_executable_rule_rows=1`,
  `legacy_enabled_topdeck_rows=0`,
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg039_senseis_divining_top_retry_20260622_215306.json`.
- Direct runtime check selected PG039 with
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=f2c5ac0f52963cd710470adc25cc6d7c`.
- Tests passed:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_support.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/senseis_top_pg039_focused_events_20260622_215306.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/senseis_top_pg039_focused_decision_trace_20260622_215306.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/senseis_top_pg039_focused_replay_summary_20260622_215306.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_220322.json`
  and `.md`.

Auditor result:

- `Sensei's Divining Top` moved to `pass`.
- Post-cycle counts: `high=85`, `medium=39`, `pass=21`.
- Next queue head: `Swords to Plowshares`.

Carry-forward caveats:

- `Sensei's Divining Top` generic activated draw remains `annotation_only`;
  PG039 proves the top-three reorder executor and the restricted first-draw
  miracle draw-put-self-on-top line.
- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG040 Swords to Plowshares Closure - 2026-06-22 22:22 UTC

Closed card:

- `Swords to Plowshares`.
- Closure rule:
  `battle_rule_v1:379008f3f03f94258292123453e3041c`.
- Oracle hash:
  `702f566e95dd477f5cf5a551e41e9df8`.
- Model scope:
  `swords_to_plowshares_creature_exile_life_equal_power_v1`.

Rule/runtime changes:

- Promoted one PostgreSQL active executable rule for `remove_creature` with
  `destination=exile`, `exile_target=true`, and target-controller life gain
  equal to target power.
- Disabled the stale curated generic executable row without `oracle_hash` and
  the generated `needs_review`/`review_only` shadow row as
  `deprecated`/`disabled`.
- Added runtime support for
  `target_controller_life_gain_equal_target_power` in targeted removal
  resolution.
- Added replay fields `life_gain_requested`, `life_gained`,
  `life_gain_status`, and
  `target_controller_life_gain_equal_target_power` to Swords removal events.
- Added focused unit coverage in
  `test_swords_to_plowshares_exiles_creature_and_gains_power_life_with_pg040_rule_provenance`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_battle_rule_pg040_precheck_20260622_221254.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_battle_rule_pg040_apply_20260622_221254.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_battle_rule_pg040_postcheck_20260622_221254.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_battle_rule_pg040_rollback_20260622_221254.sql`.

Evidence:

- PG precheck: `card_rows=1`, `distinct_oracle_ids=1`,
  `expected_oracle_hash_rows=1`, `exact_executable_rule_rows=0`,
  `legacy_enabled_removal_rows=2`,
  `trusted_executable_without_oracle_hash_rows=1`.
- PG apply: backup table
  `manaloom_deploy_audit.pg040_swords_to_plowshares_battle_rule_20260622_221254`
  captured `2` rows; apply inserted `1` active rule and updated `2` old rows.
- PG postcheck: `exact_executable_rule_rows=1`,
  `legacy_enabled_removal_rows=0`,
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg040_swords_to_plowshares_20260622_221254.json`.
- Direct runtime check selected PG040 with
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=702f566e95dd477f5cf5a551e41e9df8`.
- Tests passed:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_support.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_pg040_focused_events_20260622_221254.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_pg040_focused_replay_summary_20260622_221254.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_222210.json`
  and `.md`.

Auditor result:

- `Swords to Plowshares` moved to `pass`.
- Post-cycle counts: `high=84`, `medium=39`, `pass=22`.
- Next queue head: `Teferi's Protection`.

Carry-forward caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG041 Teferi's Protection Closure - 2026-06-22 22:41 UTC

Closed card:

- `Teferi's Protection`.
- Closure rule:
  `battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a`.
- Oracle hash:
  `bdc0faecf4420dc6162c7e72e98cc0eb`.
- Model scope:
  `teferis_protection_life_lock_protection_all_permanents_phase_out_self_exile_v1`.

Rule/runtime changes:

- Promoted one PostgreSQL active executable rule for `phase_out` with
  `life_total_cant_change=true`, `protection_from_everything=true`,
  `phase_out_all_permanents_you_control=true`,
  `phase_out_includes_lands=true`, and `exiles_self=true`.
- Disabled the stale curated generic executable row without `oracle_hash` and
  the generated `needs_review`/`review_only` shadow row as
  `deprecated`/`disabled`.
- Added runtime support for `exiles_self` in resolved spell zone handling.
- Made the `phase_out` executor use explicit rule fields for life-lock,
  protection, land inclusion, and self-exile, and emit `phase_out_resolved`
  with rule provenance.
- Added focused unit coverage in
  `test_teferis_protection_phases_all_permanents_locks_life_and_exiles_self_with_pg041_rule_provenance`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_battle_rule_pg041_precheck_20260622_223850.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_battle_rule_pg041_apply_20260622_223850.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_battle_rule_pg041_postcheck_20260622_223850.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_battle_rule_pg041_rollback_20260622_223850.sql`.

Evidence:

- PG precheck: `card_rows=1`, `distinct_oracle_ids=1`,
  `expected_oracle_hash_rows=1`, `exact_executable_rule_rows=0`,
  `legacy_enabled_phase_out_rows=2`,
  `trusted_executable_without_oracle_hash_rows=1`.
- PG apply: backup table
  `manaloom_deploy_audit.pg041_teferis_protection_battle_rule_20260622_223850`
  captured `2` rows; apply inserted `1` active rule and updated `2` old rows.
- PG postcheck: `exact_executable_rule_rows=1`,
  `legacy_enabled_phase_out_rows=0`,
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg041_teferis_protection_20260622_223850.json`.
- Direct runtime check selected PG041 with
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=bdc0faecf4420dc6162c7e72e98cc0eb`.
- Tests passed:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_support.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_pg041_focused_events_20260622_223850.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_pg041_focused_replay_summary_20260622_223850.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_224124.json`
  and `.md`.

Auditor result:

- `Teferi's Protection` moved to `pass`.
- Post-cycle counts: `high=83`, `medium=39`, `pass=23`.
- Next queue head: `Valakut Awakening // Valakut Stoneforge`.

Carry-forward caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG042 Valakut Awakening Closure - 2026-06-22 23:01 UTC

Closed card:

- `Valakut Awakening // Valakut Stoneforge`.
- Closure rule:
  `battle_rule_v1:6e1f3b876822abafe1de47610f46858d`.
- Oracle hash:
  `22b42fcc181b7aed71f78b2e1e51e887`.
- Model scope:
  `bottom_then_draw_plus_one_mdfc_land_v1`.

Rule/runtime changes:

- Activated the PostgreSQL split-name `hand_filter` rule and the front-face
  alias rule with the PostgreSQL oracle hash.
- Disabled the two legacy curated rows without `oracle_hash`/scope and the
  generated `draw_cards` `needs_review`/`review_only` shadow row as
  `deprecated`/`disabled`.
- Aligned the reviewed runtime cache with PG042 by adding the oracle hash,
  `review_status=active`, and `execution_status=auto` to the Valakut entries.
- Added focused unit coverage in
  `test_valakut_awakening_split_name_emits_pg042_rule_provenance`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg042_precheck_20260622_225355.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg042_apply_20260622_225355.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg042_postcheck_20260622_225355.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg042_rollback_20260622_225355.sql`.

Evidence:

- PostgreSQL card row has `type_line=Instant` and oracle text:
  `Put any number of cards from your hand on the bottom of your library, then draw that many cards plus one.`
- PostgreSQL rulings checked: zero bottomed cards draws one, and the player
  chooses how many cards to bottom as Valakut Awakening resolves.
- PG precheck: `card_rows=1`, `distinct_oracle_ids=1`,
  `expected_oracle_hash_rows=1`,
  `trusted_executable_without_oracle_hash_rows=4`,
  `legacy_enabled_rows=2`, `generated_review_only_shadow_rows=1`.
- PG apply: backup table
  `manaloom_deploy_audit.pg042_valakut_awakening_battle_rule_20260622_225355`
  captured `5` rows; apply updated `2` executable rows with hash and disabled
  `3` old/shadow rows.
- PG postcheck: `exact_full_executable_with_hash_rows=1`,
  `exact_alias_executable_with_hash_rows=1`,
  `legacy_enabled_rows=0`,
  `trusted_executable_without_oracle_hash_rows=0`,
  `generated_review_only_shadow_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg042_valakut_awakening_20260622_225355.json`.
- Direct runtime check selected PG042 with
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=22b42fcc181b7aed71f78b2e1e51e887`.
- Tests passed:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`.
- Tests passed:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_pg042_focused_events_20260622_225355.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_pg042_focused_replay_summary_20260622_225355.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_230104.json`
  and `.md`.

Auditor result:

- `Valakut Awakening // Valakut Stoneforge` moved to `pass`.
- Post-cycle counts: `high=82`, `medium=39`, `pass=24`.
- Next queue head: `Wheel of Fortune`.

Carry-forward caveats:

- PG042 proves the instant hand-filter executor only. The MDFC land-face
  metadata remains attached for split-name lookup, but this cycle does not
  claim land-play or tapped-red-mana execution for `Valakut Stoneforge`.
- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG043 Wheel of Fortune Closure - 2026-06-22 23:26 UTC

Closed card:

- `Wheel of Fortune`.
- Closure rule:
  `battle_rule_v1:f8bdb05cc883fda55628d6928c5562d3`.
- Oracle hash:
  `c37cd579d8132efac0c2118608f6f001`.
- Model scope:
  `multiplayer_discard_draw_v1`.

Rule/runtime changes:

- Added the oracle-backed PostgreSQL rule for the multiplayer wheel model:
  each player discards their hand, then draws seven cards.
- Disabled the legacy curated generic draw-seven row without
  `oracle_hash`/`battle_model_scope` and the generated `needs_review`
  shadow row as `deprecated`/`disabled`.
- Aligned the reviewed runtime cache with PG043 by adding the
  `Wheel of Fortune` fallback entry with `wheel_like=true`,
  `discard_hand_each_player=true`, and the PostgreSQL oracle hash.
- Added provenance emission to `wheel_resolved` so wheel replays now include
  `rule_logical_key` and `rule_oracle_hash`.
- Added focused unit coverage in
  `test_wheel_of_fortune_uses_oracle_hashed_multiplayer_wheel_rule`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_battle_rule_pg043_precheck_20260622_231859.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_battle_rule_pg043_apply_20260622_231859.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_battle_rule_pg043_postcheck_20260622_231859.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_battle_rule_pg043_rollback_20260622_231859.sql`.

Evidence:

- PostgreSQL card row has `type_line=Sorcery` and oracle text:
  `Each player discards their hand, then draws seven cards.`
- PG precheck: `card_rows=1`, `expected_oracle_hash_rows=1`,
  `legacy_curated_executable_without_hash_rows=1`,
  `generated_review_only_shadow_rows=1`,
  `trusted_draw_without_model_scope_rows=1`, and
  `trusted_executable_without_oracle_hash_rows=1`.
- PG apply: backup table
  `manaloom_deploy_audit.pg043_wheel_of_fortune_battle_rule_20260622_231859`
  captured `2` rows; apply inserted `1` active rule and disabled `2` old rows.
- PG postcheck: `oracle_hashed_multiplayer_wheel_rows=1`,
  `legacy_or_shadow_enabled_rows=0`,
  `generated_review_only_shadow_rows=0`,
  `trusted_draw_without_model_scope_rows=0`, and
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg043_wheel_of_fortune_20260622_231859.json`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py -k wheel_of_fortune`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_pg043_focused_events_20260622_231859.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_pg043_focused_replay_summary_20260622_231859.md`.

Auditor result:

- First rerun after PG043:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_232217.json`
  moved `Wheel of Fortune` to `pass`, but exposed a PostgreSQL metadata
  regression on `Valakut Awakening // Valakut Stoneforge`.
- Corrective PG044 refresh restored Valakut hash/status in PostgreSQL.
- Final rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_232608.json`
  reports both `Wheel of Fortune` and
  `Valakut Awakening // Valakut Stoneforge` as `pass`.
- Post-cycle counts: `high=81`, `medium=39`, `pass=25`.
- Next queue head: `Aetherflux Reservoir`.

Carry-forward caveats:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.
- The Valakut MDFC land face remains metadata for split-name lookup; no
  land-play or tapped-red-mana executor was claimed in this cycle.

## PG044 Valakut Awakening Hash Refresh - 2026-06-22 23:26 UTC

Corrective scope:

- PostgreSQL still had the PG042 Valakut executable full-name and alias rows
  without `oracle_hash`; the local reviewed JSON already had the hash, but
  PostgreSQL is the source of truth.
- PG044 updated those two PostgreSQL rows to `active`/`auto` with
  `oracle_hash=22b42fcc181b7aed71f78b2e1e51e887`.
- PG044 also changed the generated Valakut `draw_cards` shadow from
  `needs_review`/`disabled` to `deprecated`/`disabled`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg044_hash_refresh_precheck_20260622_232411.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg044_hash_refresh_apply_20260622_232411.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg044_hash_refresh_postcheck_20260622_232411.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg044_hash_refresh_rollback_20260622_232411.sql`.

Evidence:

- PG precheck: `full_rule_missing_hash_rows=1`,
  `alias_rule_missing_hash_rows=1`, and
  `generated_shadow_review_rows=1`.
- PG apply: backup table
  `manaloom_deploy_audit.pg044_valakut_awakening_hash_refresh_20260622_232411`
  captured `5` rows; apply updated `3` rows.
- PG postcheck: `exact_full_executable_with_hash_rows=1`,
  `exact_alias_executable_with_hash_rows=1`,
  `generated_review_only_shadow_rows=0`, and
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg044_valakut_hash_refresh_20260622_232411.json`.

## PG045 Aetherflux Reservoir Closure - 2026-06-22 23:40 UTC

Closed card:

- `Aetherflux Reservoir`.
- Closure rule:
  `battle_rule_v1:3147dc90542c79e439ca1f77df02e4e5`.
- Oracle hash:
  `ea5327899fb66a2d583e80e8ca12d9b2`.
- Model scope:
  `spell_cast_lifegain_pay_50_damage_annotation_v1`.

Rule/runtime changes:

- Added the oracle-backed PostgreSQL rule for the spell-cast lifegain trigger:
  whenever the controller casts a spell, they gain life equal to the number of
  spells they have cast this turn.
- Preserved the activated `Pay 50 life: deal 50 damage` text as
  `annotation_only`; this cycle did not add a dynamic life-payment activation
  executor.
- Disabled the legacy curated generic `finisher` row without
  `oracle_hash`/`battle_model_scope` and the generated `needs_review`
  shadow row as `deprecated`/`disabled`.
- Aligned the reviewed runtime cache with PG045 by adding the
  `Aetherflux Reservoir` fallback entry with PostgreSQL oracle hash and
  `spell_cast_lifegain_pay_50_damage_annotation_v1`.
- Added focused unit coverage in
  `test_aetherflux_reservoir_uses_oracle_hashed_spell_cast_lifegain_rule`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_battle_rule_pg045_precheck_20260622_233656.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_battle_rule_pg045_apply_20260622_233656.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_battle_rule_pg045_postcheck_20260622_233656.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_battle_rule_pg045_rollback_20260622_233656.sql`.

Evidence:

- PostgreSQL card row has `type_line=Artifact` and oracle text:
  `Whenever you cast a spell, you gain 1 life for each spell you've cast this turn.`
  plus `Pay 50 life: This artifact deals 50 damage to any target.`
- PG precheck: `card_rows=1`, `oracle_hash_rows=1`,
  `legacy_generic_enabled_rows=1`,
  `generated_review_only_shadow_rows=1`,
  `trusted_finisher_without_model_scope_rows=1`, and
  `trusted_executable_without_oracle_hash_rows=1`.
- PG apply: backup table
  `manaloom_deploy_audit.pg045_aetherflux_reservoir_battle_rule_20260622_233656`
  captured `2` rows; apply inserted `1` active rule and disabled `2` old rows.
- PG postcheck: `oracle_hashed_aetherflux_lifegain_rows=1`,
  `legacy_or_shadow_enabled_rows=0`,
  `generated_review_only_shadow_rows=0`,
  `trusted_finisher_without_model_scope_rows=0`, and
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg045_aetherflux_reservoir_20260622_233656.json`.
- Tests passed:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py docs/hermes-analysis/manaloom-knowledge/scripts/reviewed_battle_card_rules.py docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py -k aetherflux -v`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py -v`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_pg045_focused_events_20260622_233656.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_pg045_focused_replay_summary_20260622_233656.md`.

Auditor result:

- Final rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_234015.json`
  reports `Aetherflux Reservoir` as `pass`.
- Post-cycle counts: `high=80`, `medium=39`, `pass=26`.
- Next queue head: `Approach of the Second Sun`.

Carry-forward caveats:

- Aetherflux Reservoir's `Pay 50 life: deal 50 damage` activated ability
  remains `annotation_only`; PG045 proves the spell-cast lifegain trigger, not
  a dynamic life-payment activation executor.
- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

Next recommended card:

- `Approach of the Second Sun`.

## PG046 Approach of the Second Sun Closure - 2026-06-23 00:02 UTC

Closed card:

- `Approach of the Second Sun`.
- Closure rule:
  `battle_rule_v1:ed74fb069b6c1d635392d907804a1d98`.
- Oracle hash:
  `0838960b80a282fb4508532f7bae8c2b`.
- Model scope:
  `approach_second_cast_win_v2`.

Rule/runtime changes:

- Added the oracle-backed PostgreSQL rule for the second-cast win model.
- Disabled the legacy trusted no-hash `approach` rows and generated
  `needs_review`/`review_only` shadow row.
- Runtime now records Approach casts from hand at cast/payment time, so a
  countered first cast still counts for the later win check.
- Runtime excludes copied Approach spells from the cast ledger.
- Runtime gains `7` life only on the first-resolution `otherwise` branch; the
  second-cast win branch does not gain life and reports resolved destination
  `graveyard`.
- Added focused unit coverage in
  `test_approach_of_the_second_sun_counts_countered_first_cast_and_second_cast_wins`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_battle_rule_pg046_precheck_20260622_235039.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_battle_rule_pg046_apply_20260622_235039.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_battle_rule_pg046_postcheck_20260622_235039.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_battle_rule_pg046_rollback_20260622_235039.sql`.

Evidence:

- PostgreSQL card row has `type_line=Sorcery` and oracle text:
  `If this spell was cast from your hand and you've cast another spell named Approach of the Second Sun this game, you win the game. Otherwise, put Approach of the Second Sun into its owner's library seventh from the top and you gain 7 life.`
- PostgreSQL rulings confirm countered first cast counts, copied spells do not
  count, and the second Approach must be cast from hand.
- PG precheck: `card_rows=1`, `oracle_hash_rows=1`,
  `legacy_trusted_enabled_rows=2`,
  `generated_review_only_shadow_rows=1`, and
  `trusted_executable_without_oracle_hash_rows=2`.
- PG apply: backup table
  `manaloom_deploy_audit.pg046_approach_second_sun_battle_rule_20260622_235039`
  captured `3` rows; apply inserted `1` active rule and disabled `3` old rows.
- PG postcheck: `oracle_hashed_approach_second_cast_rows=1`,
  `legacy_or_shadow_enabled_rows=0`,
  `generated_review_only_shadow_rows=0`, and
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg046_approach_second_sun_20260622_235039.json`.
- Tests passed:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py -k approach -v`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py -v`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_pg046_focused_events_20260622_235039.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_pg046_focused_replay_summary_20260622_235039.md`.

Auditor result:

- Final rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_000228.json`
  reports `Approach of the Second Sun` as `pass`.
- Post-cycle counts: `high=79`, `medium=39`, `pass=27`.
- Next queue head: `Archaeomancer's Map`.

Carry-forward caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

Next recommended card:

- `Archaeomancer's Map`.

## PG047 Archaeomancer's Map Closure - 2026-06-23 00:17 UTC

Closed card:

- `Archaeomancer's Map`.
- Closure rule:
  `battle_rule_v1:69acc8f6ed179a5a32bef08190cd747e`.
- Oracle hash:
  `22b82ca6bbef42371227bc38a9a546b5`.
- Model scope:
  `basic_plains_etb_plus_opponent_land_catchup_v2`.

Rule/runtime changes:

- Added the oracle-backed PostgreSQL rule for the ETB basic Plains tutor and
  opponent-land catch-up trigger.
- Disabled the legacy trusted no-hash/no-scope `ramp_engine` row and two
  generated `needs_review`/`review_only` shadow rows.
- Runtime now requires the active land player to control more lands than the
  Map controller before the catch-up trigger can put a land from hand onto the
  battlefield.
- Runtime rechecks the same land-count condition on trigger resolution.
- Added focused unit coverage in
  `test_archaeomancers_map_opponent_land_trigger_requires_controller_behind_on_lands`
  and
  `test_archaeomancers_map_opponent_land_trigger_skips_when_controller_not_behind`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_battle_rule_pg047_precheck_20260623_001244.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_battle_rule_pg047_apply_20260623_001244.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_battle_rule_pg047_postcheck_20260623_001244.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_battle_rule_pg047_rollback_20260623_001244.sql`.

Evidence:

- PostgreSQL card row has `type_line=Artifact` and oracle text:
  `When this artifact enters, search your library for up to two basic Plains cards, reveal them, put them into your hand, then shuffle.`
  plus the opponent-land catch-up trigger.
- PostgreSQL ruling confirms the opponent must still control more lands as the
  trigger tries to resolve.
- PG precheck: `card_rows=1`, `oracle_hash_rows=1`,
  `legacy_trusted_enabled_rows=1`,
  `generated_review_only_shadow_rows=2`, and
  `trusted_executable_without_oracle_hash_rows=1`.
- PG apply: backup table
  `manaloom_deploy_audit.pg047_archaeomancers_map_battle_rule_20260623_001244`
  captured `3` rows; apply inserted `1` active rule and disabled `3` old rows.
- PG postcheck: `oracle_hashed_archaeomancers_map_rows=1`,
  `legacy_or_shadow_enabled_rows=0`,
  `generated_review_only_shadow_rows=0`, and
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg047_archaeomancers_map_20260623_001244.json`.
- Tests passed:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py -v`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_pg047_focused_events_20260623_001244.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_pg047_focused_replay_summary_20260623_001244.md`.

Auditor result:

- Final rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_001717.json`
  reports `Archaeomancer's Map` as `pass`.
- Post-cycle counts: `high=78`, `medium=39`, `pass=28`.
- Next queue head: `Blind Obedience`.

Carry-forward caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

Next recommended card:

- `Blind Obedience`.

## PG048 Blind Obedience Closure - 2026-06-23 00:35 UTC

Closed card:

- `Blind Obedience`.
- Closure rule:
  `battle_rule_v1:40f23fcea3b7955bacd550a9090c6872`.
- Oracle hash:
  `4e62bff316f784c1b468b9e53146d2aa`.
- Model scope:
  `opponent_artifact_creature_enter_tapped_extort_annotation_v1`.

Rule/runtime changes:

- Added the oracle-backed PostgreSQL rule for opponent artifacts and creatures
  entering tapped.
- Kept extort explicitly as `annotation_only`; this cycle does not add a
  dynamic optional `{W/B}` payment trigger executor.
- Disabled the legacy trusted no-hash `passive` row and the generated
  `needs_review`/`review_only` shadow row.
- Runtime now applies the static enter-tapped source on normal permanent entry
  paths when an opponent-controlled artifact or creature enters the battlefield.
- Added focused unit coverage in
  `test_blind_obedience_taps_opponent_artifacts_and_creatures_on_entry`.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_battle_rule_pg048_precheck_20260623_003029.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_battle_rule_pg048_apply_20260623_003029.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_battle_rule_pg048_postcheck_20260623_003029.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_battle_rule_pg048_rollback_20260623_003029.sql`.

Evidence:

- PostgreSQL card row has `type_line=Enchantment` and oracle text for extort
  plus `Artifacts and creatures your opponents control enter tapped.`
- PostgreSQL rulings checked: extort does not target, resolves before the
  spell, may be paid at most once per trigger, and life gained is based on
  total opponent life lost.
- PG precheck: `card_rows=1`, `oracle_hash_rows=1`,
  `legacy_trusted_enabled_rows=1`,
  `generated_review_only_shadow_rows=1`, and
  `trusted_executable_without_oracle_hash_rows=1`.
- PG apply: backup table
  `manaloom_deploy_audit.pg048_blind_obedience_battle_rule_20260623_003029`
  captured `2` rows; apply inserted `1` active rule and disabled `2` old rows.
- PG postcheck: `oracle_hashed_blind_obedience_rows=1`,
  `legacy_or_shadow_enabled_rows=0`,
  `generated_review_only_shadow_rows=0`, and
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg048_blind_obedience_20260623_003029.json`.
- Tests passed:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py -v`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_pg048_focused_events_20260623_003029.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_pg048_focused_replay_summary_20260623_003029.md`.

Auditor result:

- Final rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_003552.json`
  reports `Blind Obedience` as `pass`.
- Post-cycle counts: `high=77`, `medium=40`, `pass=28`.
- Next queue head: `Borrowed Knowledge`.

Carry-forward caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

Next recommended card:

- `Borrowed Knowledge`.

## PG049 Deck 6 L2 Hash-Only Batch - 2026-06-23 00:49 UTC

Closed lane:

- Deck-first pivot applied: the auditor now supports `--deck-id`, and this
  checkpoint stops the global alphabetical/card-by-card queue in favor of
  `deck_id=6` first, `deck_id=606` second.
- Lane: `L2` hash-only / shadow cleanup where the active model was already
  specific and no executor change was needed.

Cards included:

- `Crawlspace`.
- `Ghostly Prison`.
- `Valakut Awakening // Valakut Stoneforge`.

Rule changes:

- Added PostgreSQL `oracle_hash` to the active curated/verified/auto rules:
  - `Crawlspace`: `battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591`,
    hash `57fcd38030641ceb36bbcf1a6dcbc6c8`.
  - `Ghostly Prison`: `battle_rule_v1:99151859bece89ba3ead032e05b1f65a`,
    hash `5725b39ca4bb7c5e8e4bebf0d246be13`.
  - `Valakut Awakening`: `battle_rule_v1:245b8d2627720fadfd7a30464d07605a`,
    hash `22b42fcc181b7aed71f78b2e1e51e887`.
  - `Valakut Awakening // Valakut Stoneforge`:
    `battle_rule_v1:6e1f3b876822abafe1de47610f46858d`,
    hash `22b42fcc181b7aed71f78b2e1e51e887`.
- Deprecated the disabled generated Valakut `draw_cards` shadow row
  `battle_rule_v1:1bd5dce7cffed8d0af007d20b15e8549`.
- No `effect_json` or runtime executor behavior changed.

Applied SQL:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_batch_pg049_precheck_20260623_004614.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_batch_pg049_apply_20260623_004614.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_batch_pg049_postcheck_20260623_004614.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_batch_pg049_rollback_20260623_004614.sql`.

Evidence:

- PostgreSQL precheck confirmed all three card rows and oracle hashes:
  `card_rows=3`, `oracle_hash_rows=3`.
- PostgreSQL precheck confirmed `target_trusted_missing_hash_rows=4` and
  `valakut_generated_disabled_shadow_rows=1`.
- PG apply created backup table
  `manaloom_deploy_audit.pg049_deck6_l2_hash_only_batch_20260623_004614`
  with `9` rows, updated `4` active rule hashes, and deprecated `1` generated
  Valakut shadow row.
- PG postcheck:
  `crawlspace_hashed_rows=1`, `ghostly_prison_hashed_rows=1`,
  `valakut_hashed_rows=2`, `target_trusted_missing_hash_rows=0`, and
  `valakut_generated_review_only_shadow_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg049_deck6_l2_hash_only_20260623_004614.json`.
- Test passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`.

Auditor result:

- Deck 6 pre-batch:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_004446.json`
  reported `high=41`, `medium=33`, `pass=26`.
- Deck 6 post-batch:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_004857.json`
  reports `high=41`, `medium=30`, `pass=29`.
- Deck 606 separate post-sync report:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_20260623_004857.json`
  reports `high=43`, `medium=17`, `pass=21`.

Replay:

- Not generated. PG049 is metadata/hash-only and did not change battle
  behavior or executor dispatch.

Next recommended lane:

- `L1` deck 6 land/mana-base batch, split into simple mana lands versus
  utility/fetch lands with real battle effects. Current deck 6 L1 backlog is
  `30` cards; utility cards such as `Ancient Tomb`, `Gemstone Caverns`,
  `Hall of Heliod's Generosity`, `Inventors' Fair`, `Sunbaked Canyon`,
  `Urza's Saga`, and `War Room` should not be waived as simple basics.

Carry-forward caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.
