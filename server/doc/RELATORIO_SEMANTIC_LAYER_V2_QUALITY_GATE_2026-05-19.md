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

## Optimize com diagnostics semanticos v2

Implementacao publicada em:

- `754d08d3eb33091438f2c1345dd8b844c109cc95`: expõe
  `optimize_diagnostics.semantic_layer_v2` e
  `post_analysis.validation.functional_analysis.semantic_layer_v2`;
- `a5bfdc9029653bdc0d77f2721dcb9164a6652091`: carrega
  `card_semantic_tags_v2` para cartas atuais do deck e para cartas adicionadas.

Medição pública multi-corpus em `a5bfdc9029653bdc0d77f2721dcb9164a6652091`:

- corpora reais versionados: Brago, Krenko e Edgar;
- decks temporarios criados: `3/3`;
- decks validos antes do optimize: `3/3`;
- unresolved total: `0`;
- off-identity total: `0`;
- jobs async: `6`;
- jobs completos com swaps: `3`;
- jobs com quality gate/falha segura: `3`;
- jobs completos com diagnostics semanticos v2: `3`.

Resumo dos jobs completos:

- Brago agressivo: `20` sugestões, `18/20` pares com sinal semântico;
- Krenko focado: `9` sugestões, `9/9` pares com sinal semântico;
- Edgar focado: `10` sugestões, `10/10` pares com sinal semântico.

Artifact:

- `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-19/optimize_multi_corpus_semantic_diagnostics_summary.json`.

## Decisao

- Manter `semantic_layer_v2` em shadow mode.
- Liberar uso como explicabilidade e sinal auxiliar.
- Nao usar como bloqueio/gate duro em optimize/generate ainda.
- Diagnostics semanticos v2 já estão observáveis no optimize; o próximo gate é
  revisão de falsos positivos e critérios de aceitação para enforcement parcial.

## Proximos passos objetivos

1. Definir scorecard de falsos positivos para `role_delta` semântico.
2. Ampliar corpus para mais arquétipos e cores com swaps completos.
3. Comparar decisão atual do quality gate vs. decisão sugerida por v2 em shadow.
4. Promover v2 apenas para enforcement parcial quando a divergência for
   aceitável e reversível por feature flag.

## Scorecard shadow de falsos positivos

Rodada adicional publicada no relatório:

- `server/doc/RELATORIO_SEMANTIC_LAYER_V2_OPTIMIZE_SCORECARD_2026-05-19.md`.

Resultado:

- `false_positive_candidates=0`;
- `false_negative_candidates=0`;
- `semantic_shadow_would_block_approved_jobs=0`;
- `semantic_shadow_review_approved_jobs=2`;
- decisão: `eligible_for_limited_flagged_enforcement_review`.

Motivo: perda de `protection` foi rebaixada para revisão manual na fase inicial,
sem bloquear swaps aprovados pelo quality gate atual. Hard blockers continuam
restritos a perdas de `draw`, `removal`, `ramp` e `wipe`. A feature flag ainda
fica desligada até ampliar o corpus e confirmar que não há blocker semântico em
jobs aprovados.
