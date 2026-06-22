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
