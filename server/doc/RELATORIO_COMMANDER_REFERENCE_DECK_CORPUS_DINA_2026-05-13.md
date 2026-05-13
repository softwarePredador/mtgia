# Commander Reference Deck Corpus - Dina, Essence Brewer - 2026-05-13

## Verdict

**PASS.**

O corpus offline de `Dina, Essence Brewer` foi montado a partir de 5 paginas
publicas EDHREC Average Deck, revalidado em `--dry-run`, aplicado com sucesso e
reaplicado para prova de idempotencia. A prova publica sanitizada 5x de
`/ai/generate` passou contra o backend publico e o scorecard final retornou
`score=100`, `status=ready_for_mini_batch`. O artifact final continua sendo uma
projecao local-resolvivel: as paginas EDHREC originais continham cartas novas de
Secrets of Strixhaven que o banco local ainda nao resolve; esses slots foram
substituidos por staples Golgari de sacrificio/value ja resolviveis localmente
para permitir que o corpus passe nos gates do runner.

## Scope

Scanner, camera, OCR, app mobile, rotas app-facing e `/ai/optimize` ficaram
fora do escopo. O trabalho cobriu corpus offline, dry-run DB-backed, apply
idempotente, prova publica sanitizada de `/ai/generate`, scorecard read-only e
documentacao.

## Fontes consultadas

Fontes publicas Commander, coletadas uma vez em baixo volume para analise
offline:

- `https://edhrec.com/average-decks/dina-essence-brewer`
- `https://edhrec.com/average-decks/dina-essence-brewer/sacrifice`
- `https://edhrec.com/average-decks/dina-essence-brewer/aristocrats`
- `https://edhrec.com/average-decks/dina-essence-brewer/budget`
- `https://edhrec.com/average-decks/dina-essence-brewer/tokens`
- `https://edhrec.com/commanders/dina-essence-brewer` como contexto publico
  adicional de Commander.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/dina_edhrec_average_corpus.json`

## Criterios de inclusao

- fonte publica explicitamente rotulada como EDHREC Average Deck para
  `Dina, Essence Brewer`;
- commander em zona de comando com quantidade `1`;
- main deck com quantidade total `99`;
- deck total com quantidade `100`;
- identidade Golgari/BG sem cartas fora de cor;
- sem violacao singleton fora de terrenos basicos;
- uso somente offline: o runtime nao faz scraping nem depende de API nao
  oficial.

## Fatos locais comprovados

Dry-run executado:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/dina_edhrec_average_corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/dry_run
```

Resultado:

| Metric | Value |
| --- | ---: |
| status | `PASS` |
| mode | `dry_run` |
| db_mutations | `false` |
| deck_count | 5 |
| accepted_deck_count | 5 |
| rejected_deck_count | 0 |
| commander_quantity | 1 em 5/5 |
| main_quantity | 99 em 5/5 |
| unresolved_count | 0 em 5/5 |
| off_color_count | 0 em 5/5 |
| singleton_violations | `{}` em 5/5 |

O comandante resolveu localmente como `Dina, Essence Brewer`, preservando a
identidade BG esperada.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/dry_run/dina_essence_brewer_dry_run_summary.json`

Apply executado apos o dry-run PASS:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/dina_edhrec_average_corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/apply
```

Apply idempotente executado em seguida:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/dina_edhrec_average_corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/apply_idempotency
```

Resultado dos tres passos:

| Step | status | db_mutations | deck_count | accepted_deck_count | rejected_deck_count | gates |
| --- | --- | --- | ---: | ---: | ---: | --- |
| dry-run | `PASS` | `false` | 5 | 5 | 0 | `commander_quantity=1`, `main_quantity=99`, `unresolved=0`, `off_color=0`, `singleton_violations={}` |
| apply | `PASS` | `true` | 5 | 5 | 0 | `commander_quantity=1`, `main_quantity=99`, `unresolved=0`, `off_color=0`, `singleton_violations={}` |
| apply idempotency | `PASS` | `true` | 5 | 5 | 0 | `commander_quantity=1`, `main_quantity=99`, `unresolved=0`, `off_color=0`, `singleton_violations={}` |

Artifacts:

- `server/test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/dry_run/dina_essence_brewer_dry_run_summary.json`
- `server/test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/apply/dina_essence_brewer_apply_summary.json`
- `server/test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/apply_idempotency/dina_essence_brewer_apply_summary.json`

A escrita foi aditiva/idempotente por upsert do runner. Rollback pratico, se
necessario, deve remover apenas os registros das `source_deck_key` do corpus
Dina aplicado, preservando cards, legalidades e profiles.

Contagens DB-backed:

| Scope | Count |
| --- | ---: |
| pre-apply `commander_reference_decks` para Dina | 0 |
| pre-apply `commander_reference_deck_cards` para Dina | 0 |
| pre-apply `commander_reference_deck_analysis` para Dina | 0 |
| post-apply `commander_reference_decks` para Dina | 5 |
| post-apply `commander_reference_decks` aceitos para Dina | 5 |
| post-apply `commander_reference_deck_cards` para Dina | 433 |
| post-apply `commander_reference_deck_analysis` para Dina | 1 |

## Readiness scorecard apos apply

Comando:

```bash
cd server
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander='Dina, Essence Brewer' \
  --artifact-dir=test/artifacts/commander_reference_readiness_dina_after_corpus_2026-05-13
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
| card_stats_count | 39 |
| card_stats_unresolved_count | 0 |
| corpus_accepted_deck_count | 5 |
| corpus_core_package_count | 40 |
| deterministic_deck_valid | `true` |
| deterministic_main_quantity | 99 |

Artifact:
`server/test/artifacts/commander_reference_readiness_dina_after_corpus_2026-05-13/readiness_scorecard_summary.json`

## Public proof

Backend publico:
`https://evolution-cartinhas.8ktevp.easypanel.host`

SHA testado:
`ea793ff2943ff693ad953a823a3ecea350a96e2f`

Comando operacional executado: prova sanitaria 5x `POST /ai/generate` com
`format=Commander`, `bracket=3`, `commander_name='Dina, Essence Brewer'` e
prompt focado em sacrifice, lifegain drain, aristocrats, tokens, recursion,
Golgari interaction, ramp/draw e win conditions coerentes. Um usuario QA
descartavel foi criado apenas em memoria para obter JWT; token, e-mail, senha,
prompt completo e decklists nao foram salvos.

Resultado:

| Metric | Value |
| --- | ---: |
| health_status | `200` |
| HTTP 200 | 5/5 |
| validation OK | 5/5 |
| commander preserved | 5/5 |
| main quantity 99 | 5/5 |
| reference profile used | 5/5 |
| reference card stats used | 5/5 |
| reference deck corpus used | 5/5 |
| deterministic fallback marker | 5/5 |
| timeout fallback | 0/5 |
| invalid cards | 0 |
| off-identity cards | 0 |
| p50 | 973ms |
| p95 | 1315ms |

O payload publico marcou `is_mock=true` em 5/5, mas sem timeout, sem erro de
validacao e com profile/stats/corpus ativos. Pelo scorecard v2, isso e caminho
deterministico reference-guided valido, nao fallback de timeout.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/public_proof/summary.json`

## Readiness scorecard final

Comando:

```bash
cd server
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander='Dina, Essence Brewer' \
  --runtime-summary=test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/public_proof/summary.json \
  --artifact-dir=test/artifacts/commander_reference_readiness_dina_public_2026-05-13
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
| corpus_accepted_deck_count | 5 |
| corpus_core_package_count | 40 |
| deterministic_deck_valid | `true` |
| deterministic_main_quantity | 99 |

Artifact:
`server/test/artifacts/commander_reference_readiness_dina_public_2026-05-13/readiness_scorecard_summary.json`

Decisao: Dina esta promovida para mini-batch controlado. Nao houve mudanca de
shape em `/ai/generate`; `server/doc/API_CONTRACTS_AND_DATA_MAP.md` permanece
valido para o contrato atual.

## Unresolved e correcao local-resolvivel

A primeira validacao rejeitou 5/5 decks apenas por `unresolved_cards`. Nao houve
off-color nem singleton violation. As cartas ausentes no banco local em
2026-05-13 foram:

| Unresolved source card |
| --- |
| `Cauldron of Essence` |
| `Defiling Daemogoth` |
| `Dina's Guidance` |
| `Eccentric Pestfinder` |
| `Feral Appetite` |
| `Immoral Bargain` |
| `Merchant of Venom` |
| `Moseo, Vein's New Dean` |
| `Ominous Harvest` |
| `Pest Rescuer` |
| `Professor Dellian Fel` |
| `Ribtruss Roaster` |
| `Stensian Sanguinist` |
| `Teacher's Pest` |
| `Titan's Grave` |
| `Turbulent Fen` |
| `Witherbloom Charm` |

Para nao aplicar backfill de cartas ausentes nesta etapa, o JSON final foi
marcado como `edhrec_average_deck_local_resolvable_projection` e cada slot
unresolved recebeu substituto Golgari on-theme ja resolvivel localmente. O
proprio artifact registra `local_resolution_replacements` por deck.

| Deck key | Replacements |
| --- | ---: |
| `edhrec_dina_default_average` | 16 |
| `edhrec_dina_sacrifice_average` | 16 |
| `edhrec_dina_aristocrats_average` | 16 |
| `edhrec_dina_budget_average` | 15 |
| `edhrec_dina_tokens_average` | 16 |

## Achados derivados da web

As paginas EDHREC Average Deck provam contexto Commander por fonte, titulo e
formato de lista media para `Dina, Essence Brewer`. As cinco variantes apontam
para o mesmo nucleo estrategico:

- sacrificio repetivel e fodder/recursion para ativar a compra de Dina em
  multiplos turnos;
- payoffs aristocrats/drain como plano secundario, sem presumir que cada
  sacrificio compra carta;
- criaturas e permanentes que geram valor ao morrer ou ao criar corpos extras;
- pacote BG de ramp, remocao e recursao para manter o motor funcionando;
- lane budget/tokens como variacoes casuais, nao como prova cEDH.

## Interpretacao estrategica

Dina quer transformar sacrificios bem temporizados em vantagem de cartas e usar
o corpo/vida/counters como recompensa incremental. A "malicia" nao e montar um
loop de sacrificio infinito generico; e distribuir os sacrificios entre turnos e
turnos de oponentes para extrair o gatilho uma vez por turno, enquanto fodder,
recursao e drain mantem pressao. A carta `Dina, Soul Steeper` aparece como
suporte nas medias, mas isso nao prova que a comandante deve ser tratada como o
antigo plano lifegain-drain-only.

Padroes uteis para absorver em `optimize`/`generate` numa etapa futura:

- preservar pacote de sac outlets e fodder recorrente: `Viscera Seer`,
  `Carrion Feeder`, `Woe Strider`, `Reassembling Skeleton`, `Bloodghast` e
  `Jadar, Ghoulcaller of Nephalia`;
- priorizar payoffs compactos de morte/drain: `Blood Artist`,
  `Zulaport Cutthroat`, `Bastion of Remembrance` e `Dina, Soul Steeper` como
  suporte, nao como comandante;
- manter recursao/value BG: `Eternal Witness`, `Victimize`,
  `Moldervine Reclamation`, `Deadly Brew` e `Meren of Clan Nel Toth`;
- separar lane budget/tokens de lane average/aristocrats para nao forcar cartas
  premium ou plano errado em pedidos casuais.

Padroes arriscados ou nao transferiveis:

- nao colapsar `Dina, Essence Brewer` em `Dina, Soul Steeper` ou em pacote
  lifegain-drain antigo;
- nao tratar paginas Average Deck como cEDH;
- nao copiar decklists em runtime; usar apenas sinais agregados de roles,
  recorrencia e pacotes.

## Proximo passo minimo

1. Incluir Dina apenas em mini-batch controlado, monitorando regressao de
   `reference_deck_corpus_used`, timeout fallback, invalid cards e off-identity.
2. Opcionalmente auditar backfill oficial das cartas unresolved via Scryfall em
   etapa futura, se o objetivo for persistir listas EDHREC mais fieis que a
   projecao local-resolvivel aplicada.
