# Relatorio: Optimize multi-tag gate e scorecard progress

Data: 2026-05-27

Status: PASS_WITH_RISKS

## Escopo

Implementar o primeiro ajuste de produto para o achado P1 do Hermes: o gate de
optimizacao nao deve depender apenas de `classifyOptimizationFunctionalRole()`
quando uma carta tem multiplas funcoes relevantes.

Tambem foi instrumentado o scorecard publico de Semantic Layer v2 para evitar
execucoes silenciosas sem evidencia.

## Mudancas

- `server/lib/ai/optimization_quality_gate.dart`
  - adiciona leitura multi-tag via `inferFunctionalCardTags()`;
  - converte tags funcionais para papeis usados pelo gate;
  - preserva o papel primario como fallback/compatibilidade;
  - passa a bloquear perda de funcao critica secundaria, por exemplo
    `protection` em uma carta tambem classificada como `removal`;
  - evita falso bloqueio quando uma funcao critica e preservada por outra tag,
    por exemplo `Smothering Tithe` preservando `ramp`.

- `server/bin/semantic_layer_v2_optimize_scorecard.py`
  - adiciona `SEMANTIC_SCORECARD_PROGRESS` em stderr;
  - adiciona `--global-timeout-s` / `SEMANTIC_SCORECARD_GLOBAL_TIMEOUT_S`;
  - salva status `inconclusive_timeout` em resumo parcial quando a janela global
    expira antes de concluir todos os jobs.
  - trata timeout/erro transiente de rede por request/caso sem derrubar o
    processo inteiro, preservando apenas erro sanitizado.

- `server/test/optimization_quality_gate_test.dart`
  - cobre preservacao de `ramp` em carta multi-funcao;
  - cobre bloqueio de perda secundaria de `protection`.

## Validacoes

```bash
cd server
dart format lib/ai/optimization_quality_gate.dart test/optimization_quality_gate_test.dart
python3 -m py_compile bin/semantic_layer_v2_optimize_scorecard.py
dart analyze lib/ai/optimization_quality_gate.dart test/optimization_quality_gate_test.dart
dart test test/optimization_quality_gate_test.dart -r expanded
dart analyze bin lib routes test
dart test test/optimization_quality_gate_test.dart test/optimization_validator_test.dart test/optimize_runtime_support_test.dart -r expanded
```

Resultados:

- `dart analyze`: PASS
- testes focados: PASS, 47 testes
- `optimization_quality_gate_test.dart`: PASS, 13 testes
- `py_compile`: PASS

Validacao completa adicional:

```bash
cd server
dart test
```

Resultado:

- suite backend: PASS, 603 testes

## Smoke publico do scorecard

Comando executado contra backend publico `7329fbbdd0d5ea3e88de50d3c8235e76852380f4`:

```bash
cd server
SEMANTIC_SCORECARD_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
SEMANTIC_SCORECARD_LIMIT=1 \
python3 bin/semantic_layer_v2_optimize_scorecard.py \
  --expected-sha 7329fbbdd0d5ea3e88de50d3c8235e76852380f4 \
  --limit 1 \
  --global-timeout-s 30 \
  --output test/artifacts/semantic_layer_v2_quality_gate_2026-05-27/optimize_scorecard_progress_smoke_timeout30.json
```

Resultado:

- progresso emitido corretamente;
- deck temporario criado, validado e removido;
- `unresolved_count=0`;
- `commander_qty=1`;
- `main_qty=99`;
- `validation_ok=true`;
- timeout global ocorreu antes de iniciar optimize, como esperado para a janela
  curta de 30s;
- artifact sanitizado gerado.

## Scorecard publico pos-deploy

Deploy publico confirmado em
`c98153d655b3660cb69e0ae6d019df6f07dc7967`.

Uma primeira execucao longa revelou timeout de leitura em `/cards` durante a
criacao do caso `niv_mizzet_parun`. O runner foi corrigido para converter esse
tipo de falha em caso parcial/sanitizado em vez de stack trace sem summary.

Comando resiliente executado:

```bash
cd server
SEMANTIC_SCORECARD_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
SEMANTIC_SCORECARD_LIMIT=5 \
SEMANTIC_SCORECARD_GLOBAL_TIMEOUT_S=600 \
python3 bin/semantic_layer_v2_optimize_scorecard.py \
  --expected-sha c98153d655b3660cb69e0ae6d019df6f07dc7967 \
  --limit 5 \
  --output test/artifacts/semantic_layer_v2_quality_gate_2026-05-27/optimize_scorecard_after_multitag_gate_limit5_resilient.json
```

Resultado:

- `status=BLOCKED` por `inconclusive_timeout`, nao por regressao semantic v2;
- `cases_attempted=4`;
- `eligible_cases=4`;
- `jobs_attempted=6`;
- `current_gate_approved_jobs=3`;
- `semantic_shadow_would_block_approved_jobs=0`;
- `false_positive_candidates=0`;
- `semantic_v2_actual_blocked_jobs=0`;
- `review_candidates=1`.

Interpretacao: a camada multi-tag nao bloqueou nenhum job aprovado nessa amostra
parcial, mas a rodada publica nao substitui o scorecard completo porque expirou
antes de todos os corpora solicitados.

## Riscos restantes

- Ainda falta rodar scorecard publico completo, ou em backend controlado menos
  sujeito a timeout/rate-limit, para medir swaps reais apos multi-tag gate.
- `SEMANTIC_LAYER_V2_OPTIMIZE_ENFORCEMENT` deve continuar desligado/default
  enquanto o scorecard completo nao passar.
- A conversao multi-tag e conservadora; novos papeis devem entrar com teste e
  evidencia concreta.

## Proximo comando recomendado

```bash
cd server
SEMANTIC_SCORECARD_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
SEMANTIC_SCORECARD_LIMIT=10 \
SEMANTIC_SCORECARD_GLOBAL_TIMEOUT_S=1800 \
python3 bin/semantic_layer_v2_optimize_scorecard.py \
  --expected-sha c98153d655b3660cb69e0ae6d019df6f07dc7967 \
  --limit 10 \
  --output test/artifacts/semantic_layer_v2_quality_gate_2026-05-27/optimize_scorecard_after_multitag_gate_limit10.json
```
