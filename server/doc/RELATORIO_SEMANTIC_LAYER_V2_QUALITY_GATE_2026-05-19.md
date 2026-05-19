# Semantic Layer v2 Quality Gate - 2026-05-19

## Veredito

`PASS_WITH_RISKS` para `generate`.

`BLOCKED_FOR_HARD_GATE` para `optimize`.

Semantic Layer v2 deve permanecer em `shadow mode`.

## Ambiente

- Backend publico: `https://evolution-cartinhas.8ktevp.easypanel.host`.
- Backend SHA: `13d5d23e4bc2cd1325711dbe740f24bc856e6f46`.
- Artifacts:
  - `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-19/generate_quality_summary.json`
  - `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-19/optimize_quality_summary.json`

## Generate

Dois jobs async completos foram medidos:

- `Talrand, Sky Summoner`: `terminal=completed`, `validation_ok=true`,
  `semantic_layer_v2=true`, `fallback=true`, `elapsed_ms=72109`.
- `Lorehold, the Historian`: `terminal=completed`, `validation_ok=true`,
  `semantic_layer_v2=true`, `reference_profile_used=true`, `fallback=false`,
  `elapsed_ms=772`.

Conclusao: v2 aparece nos resultados de generate e nao quebrou validade nessa
amostra. A amostra ainda e pequena demais para transformar v2 em gate duro.

## Optimize

Optimize async em deck Commander completo legal chegou a estado terminal, mas
falhou antes de produzir output de qualidade:

- `focused`: `terminal=failed`, erro sanitizado:
  `Optimize async recebeu resposta invalida do executor interno.`
- `aggressive`: `terminal=failed`.

Optimize sync forcado respondeu com seguranca, mas sem swaps:

- `focused`: `422`, `mode=rebuild_guided`,
  `quality_error_code=OPTIMIZE_NEEDS_REPAIR`.
- `aggressive`: `422`, `mode=rebuild_guided`,
  `quality_error_code=OPTIMIZE_NEEDS_REPAIR`.

Conclusao: nao ha base para promover v2 como gate do optimize. Antes disso,
precisa corrigir o executor async ou medir em decks completos que produzam
swaps validos com diagnostics semanticos.

## Decisao

- Manter `semantic_layer_v2` em shadow mode.
- Liberar uso como explicabilidade e sinal auxiliar.
- Nao usar como bloqueio/gate duro em optimize/generate ainda.

## Proximos passos objetivos

1. Investigar o erro `Optimize async recebeu resposta invalida do executor interno`.
2. Criar corpus pequeno de decks completos que produzam swaps validos, nao apenas
   `rebuild_guided`.
3. Medir `suggestion_count`, qualidade final, off-color, roles perdidos e
   presenca de `deterministic_semantic_v2` nos diagnostics.
4. So promover v2 para gate parcial quando optimize tiver jobs completos validos
   com taxa aceitavel de falsos positivos.
