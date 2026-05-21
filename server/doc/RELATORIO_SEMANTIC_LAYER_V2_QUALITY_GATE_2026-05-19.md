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

Reprova pos-deploy em `6076dc1554c4575ee5a049ade079c78dfdf0e98f`:

- `--limit 6`: `false_positive_candidates=0`,
  `semantic_shadow_would_block_approved_jobs=0`, `review_candidates=2`;
- `--limit 10`: `cases_attempted=6`, `false_positive_candidates=0`,
  `semantic_shadow_would_block_approved_jobs=0`, `review_candidates=2`.

O resultado autoriza preparar feature flag limitada desligada por padrão, mas
nao autoriza enforcement real ainda: antes disso, o conjunto precisa ter pelo
menos 10 corpora elegiveis efetivos.

## Scorecard expandido para 10 corpora elegiveis

Rodada publica no backend `740a4e96b059568a329bc2b528679dc9118b1ce9`:

- o runner foi expandido de 6 para 10 corpora Commander Reference versionados;
- `--limit 10` agora executa 10 casos efetivos, nao apenas 6;
- `cases_attempted=10`;
- `eligible_cases=10`;
- `skipped_or_invalid_cases=0`;
- `jobs_attempted=20`;
- `completed_jobs=10`;
- `current_gate_approved_jobs=10`;
- `semantic_signal_jobs=10`;
- `false_positive_candidates=0`;
- `semantic_shadow_would_block_approved_jobs=0`;
- `review_candidates=4`;
- `unresolved_count=0`, `off_identity=0`, `commander_qty=1` e `main_qty=99`
  para todos os corpora.

Corpora adicionados ao scorecard: Aesi, Winota, Urza e Sythis, cobrindo
Simic lands/ramp/draw, Boros combat triggers, mono-blue artifacts e Selesnya
enchantress.

Decisao: `PASS_WITH_RISKS`.

Semantic Layer v2 permanece em shadow mode. Como nao houve blocker shadow em
`draw`, `removal`, `ramp` ou `wipe`, o resultado permite continuar preparando
feature flag limitada desligada por padrao, mas sem ligar enforcement em
producao nesta rodada.

Artifact:

- `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-19/optimize_shadow_scorecard_summary_limit10_expanded.json`.

## Validacao pos-feature-flag

Rodada publica com default `disabled` no backend
`73f298a53868d2b61390765cc43e3300e64e18a6`:

- `cases_attempted=10`;
- `eligible_cases=10`;
- `current_gate_approved_jobs=7`;
- `semantic_shadow_would_block_approved_jobs=0`;
- `semantic_v2_actual_blocked_jobs=0`;
- `false_positive_candidates=0`;
- `review_candidates=4`.

Rodada local controlada com
`SEMANTIC_LAYER_V2_OPTIMIZE_ENFORCEMENT=partial`:

- `cases_attempted=1`;
- `eligible_cases=1`;
- `current_gate_approved_jobs=1`;
- `semantic_shadow_would_block_approved_jobs=0`;
- `semantic_v2_actual_blocked_jobs=0`;
- `false_positive_candidates=0`;
- `review_candidates=1`.

Decisao: `PASS_WITH_RISKS`. A flag esta implementada com default seguro e o
modo `partial` foi provado em amostra controlada mínima, mas deve continuar
restrito a ambiente controlado ate existir scorecard maior com worker async
estavel.

Revalidacao publica do deploy `64beabff5a80ccd293c8da119d04c52784e8ba7d`
com default `disabled`:

- `cases_attempted=10`;
- `eligible_cases=10`;
- `current_gate_approved_jobs=6`;
- `semantic_shadow_would_block_approved_jobs=0`;
- `semantic_v2_actual_blocked_jobs=0`;
- `false_positive_candidates=0`;
- `review_candidates=3`.

Conclusao: producao segue segura com `disabled`; `partial` permanece restrito a
staging/controlado.
