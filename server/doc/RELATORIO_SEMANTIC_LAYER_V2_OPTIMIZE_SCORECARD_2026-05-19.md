# Semantic Layer v2 Optimize Scorecard - 2026-05-19

## Veredito

`PASS_WITH_RISKS` para instrumentacao e scorecard.

`NO-GO` para enforcement parcial agora.

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

- `b8d62ffeacf93d27f6e52fad1556d1b6ada0b378`.

Amostra:

- corpora: Brago, Krenko e Edgar;
- decks criados/validados: `3/3`;
- jobs async tentados: `6`;
- jobs completos: `3`;
- jobs aprovados pelo quality gate atual: `3`;
- jobs com failure/quality gate seguro: `3`;
- jobs com sinal semantico v2: `3`.

Scorecard:

- `false_positive_candidates=2`;
- `false_negative_candidates=0`;
- `semantic_shadow_would_block_approved_jobs=2`;
- motivo dos candidatos de falso positivo: perda semantica de `protection`
  em jobs que o gate atual aprovou.

## Decisao

Manter `semantic_layer_v2` em shadow mode.

Nao habilitar enforcement parcial ainda. A v2 ja mede sinais reais, mas bloquear
perda de `protection` neste momento produziria falsos positivos provaveis em
swaps que o quality gate atual aceitou.

## Proximo passo

Refinar a regra de enforcement para considerar compensacao e contexto:

- perda de `protection` so deve bloquear quando a contagem final ficar abaixo de
  alvo minimo por arquétipo;
- nao bloquear se a troca melhora outra funcao critica ou se a protecao perdida
  era redundante;
- medir novamente com pelo menos 6-10 corpora antes de feature flag.

## Artifacts

- `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-19/optimize_shadow_scorecard_summary.json`.
