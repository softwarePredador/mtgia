# Commander Reference Deck Corpus - Prosper, Tome-Bound - 2026-05-13

## Verdict

**PASS.**

`Prosper, Tome-Bound` foi promovido como segundo comandante pronto para
mini-batch controlado depois de Lorehold. A promocao nao habilita expansao em
massa: ela prova apenas que Prosper atingiu os mesmos gates operacionais do
scorecard v2.

## Scope

Scanner, app mobile, UX e rotas app-facing ficaram fora do escopo. A mudanca
foi restrita ao corpus/reference pipeline e ao scorecard.

## Corpus

Fonte: paginas publicas EDHREC Average Deck, coletadas uma vez para analise
offline:

- `https://edhrec.com/average-decks/prosper-tome-bound/optimized`
- `https://edhrec.com/average-decks/prosper-tome-bound/control`
- `https://edhrec.com/average-decks/prosper-tome-bound/cedh`
- `https://edhrec.com/average-decks/prosper-tome-bound/artifacts`

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_prosper_2026-05-13/prosper_edhrec_average_corpus.json`

O runtime nao copia decklists. O backend consome apenas sinais agregados do
corpus: roles, top cards, pacotes e contagens sanitizadas.

## Corpus Apply

| Step | Result |
| --- | --- |
| dry-run | `PASS`, 4/4 decks accepted |
| apply | `PASS`, 4/4 decks accepted |
| apply idempotency | `PASS`, 4/4 decks accepted |

Gates de corpus:

- commander resolvido;
- commander quantity `1`;
- main quantity `99`;
- unresolved `0`;
- off-color `0`;
- singleton violations `{}`.

## Runner Fix

Durante o primeiro `--apply`, o upsert linha-a-linha em
`commander_reference_deck_cards` ficou preso contra DB remoto. O runner foi
ajustado para inserir as cartas em batch via `jsonb_to_recordset`, preservando
o mesmo contrato, os mesmos gates e a mesma tabela.

Validacao apos o patch:

- `dart analyze lib/ai/commander_reference_deck_corpus_support.dart bin/commander_reference_deck_corpus.dart test/commander_reference_deck_corpus_support_test.dart`
- `dart test test/commander_reference_deck_corpus_support_test.dart -r expanded`

## Public Proof

Backend publico:
`https://evolution-cartinhas.8ktevp.easypanel.host`

SHA testado:
`b76574711fecaf81c2eea452c7e1673f882be32f`

Resultado:

| Metric | Value |
| --- | ---: |
| HTTP 200 | 5/5 |
| validation OK | 5/5 |
| commander preserved | 5/5 |
| main quantity 99 | 5/5 |
| reference profile used | 5/5 |
| reference card stats used | 5/5 |
| reference deck corpus used | 5/5 |
| timeout fallback | 0/5 |
| invalid cards | 0 |
| off-identity cards | 0 |
| p50 | 870ms |
| p95 | 1332ms |

O payload publico marcou `is_mock=true`, mas sem timeout e com profile/stats/
corpus ativos. Isso foi classificado como deterministic reference path, nao
como falha de OpenAI. O scorecard v2 passou a diferenciar esse caso de
`timeout fallback`.

## Readiness

Scorecard final:

- score `100`;
- status `ready_for_mini_batch`;
- blockers `[]`;
- warnings `[]`;
- expansion ready `true`.

Artifact:
`server/test/artifacts/commander_reference_readiness_prosper_public_2026-05-13/readiness_scorecard_summary.json`

## Decision

Prosper pode entrar como proximo comandante de referencia controlada. A regra
operacional permanece: cada novo comandante precisa passar pelo mesmo fluxo
antes de ativar guidance forte.

## Next Step

Escolher o proximo candidato entre:

- `Aesi, Tyrant of Gyre Strait`;
- `Edgar Markov`;
- `Dina, Essence Brewer`;
- `Zimone, Infinite Analyst`.

Recomendacao: `Aesi` e a escolha mais segura para repetir a mecanica, por ter
pacotes publicos claros de lands/ramp/value.
