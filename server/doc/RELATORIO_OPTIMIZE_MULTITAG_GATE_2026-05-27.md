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

## Riscos restantes

- Ainda falta rodar scorecard publico completo com janela maior para medir swaps
  reais apos multi-tag gate.
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
  --expected-sha 7329fbbdd0d5ea3e88de50d3c8235e76852380f4 \
  --limit 10 \
  --output test/artifacts/semantic_layer_v2_quality_gate_2026-05-27/optimize_scorecard_after_multitag_gate_limit10.json
```
