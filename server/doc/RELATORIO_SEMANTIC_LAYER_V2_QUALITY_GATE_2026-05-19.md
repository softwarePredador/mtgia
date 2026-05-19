# Semantic Layer v2 Quality Gate - 2026-05-19

## Veredito

`PASS_WITH_RISKS` para `generate`.

`PASS_WITH_RISKS` para `optimize` apos correcao do executor async.

Semantic Layer v2 deve permanecer em `shadow mode`.

## Ambiente

- Backend publico: `https://evolution-cartinhas.8ktevp.easypanel.host`.
- Backend SHA inicial de generate: `13d5d23e4bc2cd1325711dbe740f24bc856e6f46`.
- Backend SHA pos-fix de optimize: `981a02f6b4f00b688903714d60138b596a244195`.
- Artifacts:
  - `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-19/generate_quality_summary.json`
  - `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-19/optimize_quality_summary.json`
  - `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-19/optimize_async_executor_fix_summary.json`

## Generate

Dois jobs async completos foram medidos:

- `Talrand, Sky Summoner`: `terminal=completed`, `validation_ok=true`,
  `semantic_layer_v2=true`, `fallback=true`, `elapsed_ms=72109`.
- `Lorehold, the Historian`: `terminal=completed`, `validation_ok=true`,
  `semantic_layer_v2=true`, `reference_profile_used=true`, `fallback=false`,
  `elapsed_ms=772`.

Conclusao: v2 aparece nos resultados de generate e nao quebrou validade nessa
amostra. A amostra ainda e pequena demais para transformar v2 em gate duro.

## Optimize antes da correcao

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

Conclusao inicial: nao havia base para promover v2 como gate do optimize.

## Optimize depois da correcao

Correcao publicada em `981a02f6b4f00b688903714d60138b596a244195`.

Resultados publicos sanitizados:

- o erro `Optimize async recebeu resposta invalida do executor interno` nao
  reapareceu;
- probe estrutural Talrand completo teve jobs async aceitos, mas continuou sem
  swaps por quality gate;
- corpus real Brago, vindo de Commander Reference versionado, criou deck
  temporario com `commander=1`, `main=99`, `unresolved=0`,
  `off_identity=0`, `validation_ok=true`;
- optimize async Brago `focused`: `terminal=completed`, `mode=optimize`,
  `quality_error=false`, `suggestion_count=10`, `elapsed_ms=5130`.

Conclusao pos-fix: o executor async esta funcional e ja existe uma prova
publica de corpus real produzindo swaps. A promocao de v2 para gate duro ainda
fica bloqueada porque esse job com swaps nao expôs sinal semantico v2 nos
diagnostics do optimize (`semantic_signal_jobs=0`).

## Decisao

- Manter `semantic_layer_v2` em shadow mode.
- Liberar uso como explicabilidade e sinal auxiliar.
- Nao usar como bloqueio/gate duro em optimize/generate ainda.
- Proximo gate deve medir diagnostics semanticos explicitamente no optimize e
  ampliar a amostra de corpus com swaps antes de enforcement.

## Proximos passos objetivos

1. Expor/registrar diagnostics semanticos v2 no optimize quando os dados
   semanticos participarem da analise funcional.
2. Ampliar corpus pequeno de decks completos que produzam swaps validos, nao
   apenas `rebuild_guided`.
3. Medir `suggestion_count`, qualidade final, off-color, roles perdidos e
   presenca de `deterministic_semantic_v2` nos diagnostics.
4. So promover v2 para gate parcial quando optimize tiver jobs completos validos
   com taxa aceitavel de falsos positivos e diagnostics semanticos observaveis.
