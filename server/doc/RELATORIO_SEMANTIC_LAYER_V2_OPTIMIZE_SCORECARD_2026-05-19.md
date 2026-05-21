# Semantic Layer v2 Optimize Scorecard - 2026-05-19

## Veredito

`PASS_WITH_RISKS` para instrumentacao e scorecard.

`PASS_WITH_RISKS` para a regra refinada de `protection`.

`NO-GO` para ligar feature flag ainda, porque a amostra continua pequena.

## O que foi feito

- Criado runner reexecutavel:
  `server/bin/semantic_layer_v2_optimize_scorecard.py`.
- O runner cria decks temporarios a partir de corpora Commander Reference
  versionados, roda `/ai/optimize` async, apaga os decks temporarios e salva
  apenas resumo agregado.
- O runner nao salva token, e-mail QA, deck id, decklist, nomes de cartas ou
  payload bruto.

## Prova publica

Backend publico inicial:

- `4a94b6592460ce382fa1b97ac5cb33b1228814ce`.

Amostra:

- corpora: Brago, Krenko e Edgar;
- decks criados/validados: `3/3`;
- jobs async tentados: `6`;
- jobs completos: `2`;
- jobs aprovados pelo quality gate atual: `2`;
- jobs com failure/quality gate seguro: `4`;
- jobs com sinal semantico v2: `2`.

Scorecard:

- `false_positive_candidates=0`;
- `false_negative_candidates=0`;
- `semantic_shadow_would_block_approved_jobs=0`;
- `semantic_shadow_review_approved_jobs=2`;
- `review_candidates=2`;
- decisao do artifact: `eligible_for_limited_flagged_enforcement_review`.

## Reprova pos-deploy

Backend publico:

- `6076dc1554c4575ee5a049ade079c78dfdf0e98f`.

Comando `--limit 6`:

- corpora elegiveis: `6`;
- jobs async tentados: `10`;
- jobs completos: `4`;
- jobs aprovados pelo quality gate atual: `4`;
- jobs com failure/quality gate seguro: `6`;
- jobs com sinal semantico v2: `4`;
- `false_positive_candidates=0`;
- `false_negative_candidates=0`;
- `semantic_shadow_would_block_approved_jobs=0`;
- `semantic_shadow_review_approved_jobs=2`;
- `review_candidates=2`.

Comando `--limit 10`:

- corpora elegiveis: `6`;
- jobs async tentados: `8`;
- jobs completos: `4`;
- jobs aprovados pelo quality gate atual: `4`;
- jobs com failure/quality gate seguro: `4`;
- jobs com sinal semantico v2: `4`;
- `false_positive_candidates=0`;
- `false_negative_candidates=0`;
- `semantic_shadow_would_block_approved_jobs=0`;
- `semantic_shadow_review_approved_jobs=2`;
- `review_candidates=2`.

Observacao: `--limit 10` nao atingiu 10 corpora porque o conjunto versionado
elegivel atual tem apenas 6 corpora aproveitaveis pelo runner.

## Decisao

Manter `semantic_layer_v2` em shadow mode.

Nao habilitar feature flag ainda. A v2 ja mede sinais reais e a perda de
`protection` deixou de bloquear swaps aprovados pelo gate atual, mas ainda vira
item de revisao manual. Hard blockers iniciais ficam restritos a perdas de
`draw`, `removal`, `ramp` e `wipe`.

## Proximo passo

Ampliar a prova antes de qualquer flag:

- ampliar o conjunto para pelo menos 10 corpora elegiveis reais antes de feature
  flag;
- manter `protection` como review-only ate existir alvo minimo por arquétipo;
- se hard blockers (`draw`, `removal`, `ramp`, `wipe`) aparecerem em jobs
  aprovados, manter enforcement desligado.

## Artifacts

- `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-19/optimize_shadow_scorecard_summary.json`.
- `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-19/optimize_shadow_scorecard_summary_limit6.json`.
- `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-19/optimize_shadow_scorecard_summary_limit10.json`.

## Expansao para 10 corpora elegiveis

Backend publico:

- `740a4e96b059568a329bc2b528679dc9118b1ce9`.

Motivo da rodada anterior com `--limit 10` ter atingido apenas 6 corpora:

- o runner usa `DEFAULT_CORPORA[:limit]`;
- `DEFAULT_CORPORA` tinha somente 6 entradas versionadas;
- portanto o limite 10 nao podia selecionar mais casos, mesmo existindo outros
  corpora Commander Reference no repositorio.

Corpora ja elegiveis pelo runner antes da expansao:

- Brago, King Eternal — Azorius blink/ETB value;
- Krenko, Mob Boss — mono-red goblin tokens aggro;
- Edgar Markov — Mardu vampire tokens/aristocrats;
- Teysa Karlov — Orzhov aristocrats/tokens;
- Niv-Mizzet, Parun — Izzet spellslinger/draw-damage control;
- Prosper, Tome-Bound — Rakdos exile/treasure.

Corpora adicionados ao runner, todos ja versionados com corpus/profile/stats e
sem necessidade de gerar novos artifacts de corpus/dry-run/apply:

- Aesi, Tyrant of Gyre Strait — Simic lands/ramp/draw;
- Winota, Joiner of Forces — Boros combat trigger/humans;
- Urza, Lord High Artificer — mono-blue artifact combo/control;
- Sythis, Harvest's Hand — Selesnya enchantress value.

Resultado do scorecard publico `--limit 10`:

- `cases_attempted=10`;
- `eligible_cases=10`;
- `skipped_or_invalid_cases=0`;
- `jobs_attempted=20`;
- `completed_jobs=10`;
- `current_gate_approved_jobs=10`;
- `quality_failed_jobs=10`;
- `semantic_signal_jobs=10`;
- `false_positive_candidates=0`;
- `false_negative_candidates=0`;
- `semantic_shadow_would_block_approved_jobs=0`;
- `semantic_shadow_review_approved_jobs=4`;
- `review_candidates=4`;
- decisao do artifact: `eligible_for_limited_flagged_enforcement_review`.

Sanidade dos corpora criados temporariamente:

- `unresolved_count=0` em todos os 10 casos;
- `off_identity=0` em todos os 10 casos;
- `commander_qty=1` e `main_qty=99` em todos os 10 casos;
- decks temporarios removidos ao fim de cada caso;
- artifact segue sanitizado: sem token, e-mail QA completo, deck id, decklist,
  nomes de cartas ou payload bruto.

## Decisao expandida

`PASS_WITH_RISKS`.

Nao houve blocker shadow em perdas criticas de `draw`, `removal`, `ramp` ou
`wipe` entre jobs aprovados pelo quality gate atual. As perdas de `protection`
continuam review-only nesta fase.

Manter `semantic_layer_v2` em shadow mode e recomendar qualquer feature flag
desligada por padrao. Nao alterar enforcement de producao nesta rodada.

Artifact expandido:

- `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-19/optimize_shadow_scorecard_summary_limit10_expanded.json`.

## Feature flag segura de enforcement parcial - 2026-05-20

Implementado preparo controlado para enforcement no `/ai/optimize`:

- flag de ambiente `SEMANTIC_LAYER_V2_OPTIMIZE_ENFORCEMENT`;
- valores aceitos: `disabled` e `partial`;
- default seguro: `disabled` para valor ausente, vazio ou desconhecido;
- em `disabled`, a Semantic Layer v2 permanece shadow/diagnostic e nao bloqueia
  respostas;
- em `partial`, o bloqueio so ocorre depois que o fluxo atual aprovar a
  otimizacao e apenas para perda semantica critica em `draw`, `removal`,
  `ramp` ou `wipe`;
- perda de `protection` continua review-only em `review_loss_roles`;
- requests com `partial` bypassam read/write de `ai_optimize_cache` para evitar
  reaproveitar decisoes geradas com enforcement desligado.
- o runner `server/bin/semantic_layer_v2_optimize_scorecard.py` tambem reconhece
  diagnostics em `quality_error.optimize_diagnostics` quando `partial` bloqueia
  um job async e registra `semantic_v2_actual_blocked_jobs` no resumo agregado.

Diagnostics opcionais adicionados em
`optimize_diagnostics.semantic_layer_v2`:

- `enforcement_mode`;
- `critical_loss_roles`;
- `review_loss_roles`;
- `blocked_by_semantic_v2`;
- `enforcement_signal=role_delta_negative`.

Quando `partial` bloqueia, a resposta usa `422` com
`quality_error.code=OPTIMIZE_SEMANTIC_V2_REJECTED` e
`rejection_source=semantic_layer_v2`, preservando o contrato app-facing
aditivo.

Validacao local:

- `dart analyze lib/ai/optimization_functional_roles.dart lib/ai/optimization_validator.dart routes/ai/optimize/index.dart test/optimization_validator_test.dart`: PASS;
- `dart test test/optimization_validator_test.dart -r expanded`: PASS.

Resultado: `PASS_WITH_RISKS`. A flag continua recomendada desligada por padrao
em producao; `partial` deve ser usado primeiro em ambiente controlado.

## Validacao pos-flag - 2026-05-20

### Publico com default `disabled`

Backend publico:

- `73f298a53868d2b61390765cc43e3300e64e18a6`.

Artifact:

- `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-20/optimize_scorecard_disabled_public.json`.

Resultado:

- `cases_attempted=10`;
- `eligible_cases=10`;
- `jobs_attempted=20`;
- `completed_jobs=7`;
- `current_gate_approved_jobs=7`;
- `quality_failed_jobs=13`;
- `semantic_signal_jobs=16`;
- `semantic_shadow_would_block_approved_jobs=0`;
- `semantic_v2_actual_blocked_jobs=0`;
- `false_positive_candidates=0`;
- `review_candidates=4`;
- decisao: `eligible_for_limited_flagged_enforcement_review`.

Conclusao: com a flag desligada, producao manteve comportamento atual e nao
houve bloqueio real por Semantic v2.

### Local controlado com `partial`

Ambiente:

- `http://127.0.0.1:8083`;
- `SEMANTIC_LAYER_V2_OPTIMIZE_ENFORCEMENT=partial`;
- `/health.git_sha=null`, por ser servidor local.

Artifact:

- `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-20/optimize_scorecard_partial_local_limit1.json`.

Resultado:

- `cases_attempted=1`;
- `eligible_cases=1`;
- `jobs_attempted=2`;
- `completed_jobs=1`;
- `current_gate_approved_jobs=1`;
- `quality_failed_jobs=1`;
- `semantic_signal_jobs=2`;
- `semantic_shadow_would_block_approved_jobs=0`;
- `semantic_v2_actual_blocked_jobs=0`;
- `false_positive_candidates=0`;
- `review_candidates=1`;
- decisao: `eligible_for_limited_flagged_enforcement_review`.

Conclusao: `partial` executou em ambiente controlado sem bloquear perda de
`protection` e sem gerar falso positivo na amostra mínima. A tentativa local
`limit=10` foi interrompida por custo operacional do pipeline real de optimize
local, nao por falha semantica; a cobertura ampla continua sendo a prova publica
com `disabled`.

### Decisao pos-flag

`PASS_WITH_RISKS`.

- Manter `SEMANTIC_LAYER_V2_OPTIMIZE_ENFORCEMENT=disabled` em producao.
- Permitir `partial` apenas em ambiente controlado/staging.
- Antes de qualquer rollout publico com `partial`, repetir scorecard em ambiente
  controlado com amostra maior ou criar staging com worker async estavel.

### Revalidacao publica do deploy `64beabf`

Backend publico:

- `64beabff5a80ccd293c8da119d04c52784e8ba7d`.

Artifact:

- `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-20/optimize_scorecard_disabled_public_64beabf.json`.

Resultado:

- `cases_attempted=10`;
- `eligible_cases=10`;
- `jobs_attempted=20`;
- `completed_jobs=6`;
- `current_gate_approved_jobs=6`;
- `quality_failed_jobs=14`;
- `semantic_signal_jobs=17`;
- `semantic_shadow_would_block_approved_jobs=0`;
- `semantic_v2_actual_blocked_jobs=0`;
- `false_positive_candidates=0`;
- `review_candidates=3`;
- decisao: `eligible_for_limited_flagged_enforcement_review`.

Conclusao: o deploy posterior manteve producao segura com a flag desligada e
sem bloqueio real por Semantic v2. O proximo gate continua sendo staging com
`partial`, nao producao.
