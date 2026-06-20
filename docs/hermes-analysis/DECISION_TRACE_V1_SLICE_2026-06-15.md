# Decision Trace v1 — Hermes Battle Slice

> Status 2026-06-19: documento historico de schema/slice. Use como contexto,
> nao como prova de cobertura atual de replay humano, regras ou estrategia.
> Fonte viva: [BATTLE_VALIDATION_REGISTER_2026-06-19.md](BATTLE_VALIDATION_REGISTER_2026-06-19.md).
> Indice: [BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md](BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md).

Data: 2026-06-15

## Objetivo

Adicionar rastreabilidade interna ao battle/Hermes sem mudar app Flutter, API
publica, PostgreSQL ou resultado da simulacao. O foco deste slice e parar de
tratar WR bruto como evidencia suficiente e registrar, por replay, quais opcoes
foram consideradas e por que a acao escolhida foi tomada.

## Escopo implementado

- `battle_analyst_v9.py`
  - adiciona `DECISION_TRACE_HANDLER` como side-channel opcional;
  - adiciona schema `decision_trace_v1`;
  - emite decisoes para:
    - cast de ramp;
    - cast de spell normal;
    - cast de criatura;
    - cast high-threat/wincon;
    - resposta com protection/counter;
    - ataque/combat target;
    - pass/no-action de prioridade com pilha vazia.
- `battle_replay_v10_3.py`
  - grava replay textual, eventos JSONL e `*.decision_trace.jsonl`;
  - nao altera eventos legados.
- `replay_decision_auditor.py`
  - le decision trace opcional;
  - audita campos obrigatorios, `decision_id` duplicado, opcoes vazias,
    `chosen_option` fora de `available_options`, score vazio e source/status
    ausentes;
  - `unknown` e `needs_review` aparecem como achado baixo/auditavel, sem
    bloquear comportamento do engine;
  - `--skip-baseline` permite auditar artefatos locais sem SQLite Hermes completo.
- `card_impact_analyzer.py`
  - adiciona `wns_wr`, `delta_vs_not_seen`, `sample_size`,
    `sample_quality`, `not_seen` e JSON opcional;
  - isso segue a metodologia estatistica inspirada em 17Lands sem importar
    dados 17Lands para Commander.
- `loss_mode_suggester.py`
  - bloqueia candidatos de corte/adicao quando `sample_size`/`seen` fica abaixo
    do minimo configurado.

## Schema JSONL

Cada linha de `*.decision_trace.jsonl` contem:

```json
{
  "schema_version": "decision_trace_v1",
  "decision_id": "seed_42-000001",
  "replay_id": "seed_42",
  "turn": 3,
  "phase": "precombat_main",
  "player": "Lorehold",
  "decision_type": "cast_spell",
  "available_options": [],
  "chosen_option": {},
  "rejected_options": [],
  "score_components": {},
  "rule_source": "known_cards_manual",
  "rule_status": "verified",
  "confidence": "medium",
  "expected_benefit_score": 25,
  "actual_outcome": "cast_to_stack",
  "reason": "highest_threat_main_phase_spell"
}
```

## Regras de seguranca

- Nao muda API app-facing.
- Nao escreve em PostgreSQL.
- Nao aplica swaps automaticamente.
- Nao usa dados 17Lands como fonte Commander.
- `needs_review` continua auditavel, sem comportamento duro.
- SQLite Hermes continua cache/laboratorio; backend/PostgreSQL continua fonte
  de verdade do produto.

## Validacoes executadas

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_trace_tests.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py \
  server/bin/card_impact_analyzer.py \
  server/bin/loss_mode_suggester.py
```

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 test_battle_analyst_v10_3.py
```

Resultado: suite Hermes battle passou, incluindo testes novos de decision trace.

```bash
python3 replay_decision_auditor.py \
  --events /tmp/.../events.jsonl \
  --decision-trace /tmp/.../decision_trace.jsonl \
  --require-decision-trace \
  --skip-baseline \
  --deck-id 6
```

Resultado: audit sintético limpo, `decision_traces=1`, `decision_findings=0`.

## Limitacao local

O replay completo local via `battle_replay_v10_3.py` depende do SQLite Hermes
completo. No Mac, o `knowledge.db` presente nao continha `deck_cards`; por isso
o full replay deve ser reexecutado no Hermes AWS ou em ambiente com DB completo.
O auditor agora suporta `--skip-baseline` para validar artefatos isolados sem
essa dependencia.

## Proximos passos

1. Rodar no Hermes AWS:
   - `battle_replay_v10_3.py` com `DECISION_TRACE_OUT`;
   - `replay_decision_auditor.py --require-decision-trace`;
   - salvar relatorio em `docs/hermes-analysis/master_optimizer_reports/`.
2. Ampliar trace para tutor, board wipe e bloqueio quando houver corpus de
   replays suficiente.
3. Criar tabela SQLite Hermes `decision_traces` apenas depois que o formato
   JSONL estabilizar.
4. Promover estatisticas por carta/swap somente com baseline fresco,
   `baseline_hash` e amostra minima reproduzivel.
