# Commander Reference Deck Corpus - Edgar Markov - 2026-05-13

## Verdict

**PASS.**

O corpus offline de `Edgar Markov` foi montado com 4 paginas publicas EDHREC
Average Deck, revalidado em `--dry-run`, aplicado com sucesso e reaplicado para
prova de idempotencia. O scorecard read-only apos corpus ficou em
`PASS_WITH_RISKS`, `score=98`, bloqueado apenas pela ausencia de prova publica
5x de `/ai/generate`. A prova publica sanitizada foi executada em seguida contra
o backend publico e promoveu Edgar para `ready_for_mini_batch` com `score=100`.

## Scope

Scanner, camera, OCR, app mobile e `/ai/optimize` ficaram fora do escopo. A
entrega cobriu o corpus/reference pipeline, escrita idempotente nas tabelas de
reference corpus, prova publica sanitizada de `/ai/generate` e scorecard final
para decisao de promocao.

## Fontes consultadas

Fontes publicas Commander, coletadas uma vez em baixo volume para analise
offline:

- `https://edhrec.com/average-decks/edgar-markov`
- `https://edhrec.com/average-decks/edgar-markov/optimized`
- `https://edhrec.com/average-decks/edgar-markov/vampires`
- `https://edhrec.com/average-decks/edgar-markov/budget`
- `https://edhrec.com/commanders/edgar-markov` como contexto publico adicional
  de Commander.

Tambem foram sondadas paginas tematicas que ficaram fora do corpus final por
lacunas locais de resolucao de cartas ou por baixa utilidade para este dry-run:
`lifegain`, `tokens`, `aggro`, `aristocrats`, `combo`, `reanimator` e
`sacrifice`.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/edgar_edhrec_average_corpus.json`

## Criterios de inclusao

- fonte publica explicitamente rotulada como EDHREC Average Deck para Edgar
  Markov;
- commander em zona de comando com quantidade `1`;
- main deck com quantidade total `99`;
- deck total com quantidade `100`;
- identidade Mardu/BRW sem cartas fora de cor;
- sem violacao singleton fora de terrenos basicos;
- uso somente offline: runtime nao faz scraping nem depende de API nao oficial.

## Fatos locais comprovados

Dry-run executado:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/edgar_edhrec_average_corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/dry_run
```

Resultado:

| Metric | Value |
| --- | ---: |
| status | `PASS` |
| mode | `dry_run` |
| db_mutations | `false` |
| deck_count | 4 |
| accepted_deck_count | 4 |
| rejected_deck_count | 0 |
| commander_quantity | 1 em 4/4 |
| main_quantity | 99 em 4/4 |
| unresolved_count | 0 em 4/4 |
| off_color_count | 0 em 4/4 |
| singleton_violations | `{}` em 4/4 |

O comandante resolveu localmente como `Edgar Markov`, preservando a identidade
Mardu esperada.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/dry_run/edgar_markov_dry_run_summary.json`

Apply executado apos o dry-run PASS:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/edgar_edhrec_average_corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/apply
```

Apply idempotente executado em seguida:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/edgar_edhrec_average_corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/apply_idempotency
```

Resultado dos tres passos:

| Step | status | db_mutations | deck_count | accepted_deck_count | rejected_deck_count | gates |
| --- | --- | --- | ---: | ---: | ---: | --- |
| dry-run | `PASS` | `false` | 4 | 4 | 0 | `commander_quantity=1`, `main_quantity=99`, `unresolved=0`, `off_color=0`, `singleton_violations={}` |
| apply | `PASS` | `true` | 4 | 4 | 0 | `commander_quantity=1`, `main_quantity=99`, `unresolved=0`, `off_color=0`, `singleton_violations={}` |
| apply idempotency | `PASS` | `true` | 4 | 4 | 0 | `commander_quantity=1`, `main_quantity=99`, `unresolved=0`, `off_color=0`, `singleton_violations={}` |

Artifacts:

- `server/test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/dry_run/edgar_markov_dry_run_summary.json`
- `server/test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/apply/edgar_markov_apply_summary.json`
- `server/test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/apply_idempotency/edgar_markov_apply_summary.json`

A escrita foi aditiva/idempotente por upsert do runner. Rollback pratico, se
necessario, deve remover apenas os registros das `source_deck_key` do corpus
Edgar aplicado, preservando cards, legalidades e profiles.

Contagens DB-backed apos apply/idempotencia:

| Scope | Count |
| --- | ---: |
| pre-apply dry-run baseline | `deck_count=4`, `accepted_deck_count=4`, `db_mutations=false` |
| `commander_reference_decks` para Edgar | 4 |
| `commander_reference_decks` aceitos para Edgar | 4 |
| `commander_reference_deck_cards` para Edgar | 350 |
| `commander_reference_deck_analysis` para Edgar | 1 |

A contagem direta de linhas DB antes do primeiro `--apply` nao foi persistida;
o dry-run sem mutacao foi usado como baseline seguro antes da escrita.

## Readiness scorecard apos apply

Comando:

```bash
cd server
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander='Edgar Markov' \
  --artifact-dir=test/artifacts/commander_reference_readiness_edgar_after_corpus_2026-05-13
```

Resultado:

| Metric | Value |
| --- | ---: |
| status | `PASS_WITH_RISKS` |
| score | 98 |
| readiness status | `profile_ready_needs_proof` |
| expansion_ready | `false` |
| blockers | `[]` |
| warnings | `public_runtime_proof_missing` |
| corpus_accepted_deck_count | 4 |
| corpus_core_package_count | 40 |
| deterministic_deck_valid | `true` |
| deterministic_main_quantity | 99 |

Artifact:
`server/test/artifacts/commander_reference_readiness_edgar_after_corpus_2026-05-13/readiness_scorecard_summary.json`

## Prova publica sanitizada de `/ai/generate`

Backend publico:
`https://evolution-cartinhas.8ktevp.easypanel.host`

Health:

| Metric | Value |
| --- | ---: |
| health_status | 200 |
| backend_git_sha | `eeb31238fc5df045af95cedd563bf3ee87b30a32` |

Prova executada com usuario QA descartavel criado apenas em memoria, sem
registrar credenciais, token, e-mail completo, prompt completo ou decklists. Os
5 probes usaram `format=Commander`, `bracket=3` e
`commander_name='Edgar Markov'`, com prompt focado em vampire typal, token
pressure, aristocrats, anthem/lord effects, sacrifice payoffs,
draw/ramp/removal/protection Mardu e win conditions coerentes.

Resultado:

| Metric | Value |
| --- | ---: |
| status | `PASS` |
| http_200 | 5/5 |
| validation_ok | 5/5 |
| commander_preserved | 5/5 |
| main_quantity_99 | 5/5 |
| profile_used | 5/5 |
| stats_used | 5/5 |
| corpus_used | 5/5 |
| fallback_count | 5/5 |
| timeout_fallback_count | 0/5 |
| invalid_cards_total | 0 |
| off_identity_total | 0 |
| p50 | 866ms |
| p95 | 867ms |

O payload publico marcou `is_mock=true`, mas sem timeout, sem erro de validacao
e com profile/stats/corpus ativos. Pela regra do scorecard v2, isso e caminho
deterministico reference-guided valido, nao fallback de timeout.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/public_proof/summary.json`

## Readiness scorecard final

Comando:

```bash
cd server
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander='Edgar Markov' \
  --runtime-summary=test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/public_proof/summary.json \
  --artifact-dir=test/artifacts/commander_reference_readiness_edgar_public_2026-05-13
```

Resultado:

| Metric | Value |
| --- | ---: |
| status | `PASS` |
| score | 100 |
| readiness status | `ready_for_mini_batch` |
| expansion_ready | `true` |
| blockers | `[]` |
| warnings | `[]` |
| runtime_public_gate_passed | `true` |
| corpus_accepted_deck_count | 4 |
| corpus_core_package_count | 40 |
| deterministic_deck_valid | `true` |
| deterministic_main_quantity | 99 |

Artifact:
`server/test/artifacts/commander_reference_readiness_edgar_public_2026-05-13/readiness_scorecard_summary.json`

## Achados derivados da web

As paginas EDHREC Average Deck provam contexto Commander pela propria fonte,
titulo e formato das listas medias. As quatro variantes aceitas apontam para o
mesmo nucleo estrategico:

- alta densidade de criaturas Vampire, com media local `21.75`;
- base de mana Mardu com media `35.5` terrenos;
- plano de mesa largo via eminence, lords e payoff tribal;
- subplano aristocrats/drain com `Blood Artist`, `Cruel Celebrant`,
  `Sanctum Seeker` e `Vito, Thorn of the Dusk Rose`;
- protecao e interacao suficientes para preservar o board sem transformar a
  lista casual/optimized em shell cEDH.

## Interpretacao estrategica

Edgar Markov quer converter cada Vampire pequeno em pressao adicional antes
mesmo de resolver o comandante. A "malicia" do deck e usar eminence para
transformar curva baixa em largura de mesa, depois amplificar com lords,
contadores, drain e efeitos de sacrificio. O modo `optimized` reforca tutores e
combos Mardu, mas nao deve ser tratado como cEDH sem uma fonte cEDH separada.

Padroes uteis para absorver em `optimize`/`generate` na proxima etapa:

- preservar o pacote de identidade tribal: `Captivating Vampire`,
  `Cordial Vampire`, `Legion Lieutenant`, `Markov Baron`,
  `Mavren Fein, Dusk Apostle` e `Edgar, Charmed Groom`;
- priorizar payoff de mesa larga e drain: `Blood Artist`, `Cruel Celebrant`,
  `Sanctum Seeker`, `Elenda, the Dusk Rose`, `Shared Animosity`;
- manter suporte de compra/sac outlet compacto: `Skullclamp`, `Village Rites`,
  `Pact of the Serpent`, `Viscera Seer`, `Yahenni, Undying Partisan`;
- separar lane budget de lane optimized, evitando forcar tutores caros em
  pedidos casuais.

Padroes arriscados ou nao transferiveis:

- nao colapsar Edgar em Mardu aristocrats generico sem densidade Vampire;
- nao importar automaticamente a pagina `optimized` como cEDH;
- nao usar paginas com cartas locais nao resolvidas ate backfill/DB freshness
  corrigir `Scheming Silvertongue` e `Emeritus of Woe`;
- nao copiar decklists em runtime; usar apenas sinais agregados de roles,
  recorrencia e pacotes.

## Decisao final

Edgar Markov esta promovido para mini-batch controlado. Nao houve mudanca de
shape em `/ai/generate`; a prova apenas confirmou o contrato publico ja
documentado com diagnosticos opcionais de Commander Reference Profile, Card
Stats e Deck Corpus.
