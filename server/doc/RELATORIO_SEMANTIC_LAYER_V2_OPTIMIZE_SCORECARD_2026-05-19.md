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

Backend publico:

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

## Decisao

Manter `semantic_layer_v2` em shadow mode.

Nao habilitar feature flag ainda. A v2 ja mede sinais reais e a perda de
`protection` deixou de bloquear swaps aprovados pelo gate atual, mas ainda vira
item de revisao manual. Hard blockers iniciais ficam restritos a perdas de
`draw`, `removal`, `ramp` e `wipe`.

## Proximo passo

Ampliar a prova antes de qualquer flag:

- medir novamente com pelo menos 6-10 corpora antes de feature flag;
- manter `protection` como review-only ate existir alvo minimo por arquétipo;
- se hard blockers (`draw`, `removal`, `ramp`, `wipe`) aparecerem em jobs
  aprovados, manter enforcement desligado.

## Artifacts

- `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-19/optimize_shadow_scorecard_summary.json`.
