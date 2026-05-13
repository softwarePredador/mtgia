# Commander Reference Deck Corpus - Zimone, Infinite Analyst - 2026-05-13

## Verdict

**PASS WITH RISKS.**

O corpus offline de `Zimone, Infinite Analyst` foi montado com 5 paginas
publicas EDHREC Average Deck, revalidado em `--dry-run`, aplicado com sucesso e
reaplicado para prova de idempotencia. O scorecard read-only apos corpus ficou
em `PASS_WITH_RISKS`, `score=98`, bloqueado apenas pela ausencia de prova
publica 5x de `/ai/generate`. O artifact final continua sendo uma projecao
local-resolvivel: as paginas EDHREC originais usam cartas novas de Secrets of
Strixhaven que o banco local ainda nao resolve; esses slots foram substituidos
por cartas Simic on-theme ja resolviveis localmente.

## Scope

Scanner, camera, OCR, app mobile, rotas app-facing, `/ai/optimize` e prova
publica de `/ai/generate` ficaram fora do escopo. O trabalho cobriu pesquisa de
baixo volume, montagem do JSON offline, dry-run DB-backed, apply idempotente,
scorecard read-only e documentacao.

## Fontes consultadas

Fontes publicas Commander, coletadas uma vez em baixo volume para analise
offline:

| Fonte | Uso |
| --- | --- |
| `https://edhrec.com/average-decks/zimone-infinite-analyst` | incluido |
| `https://edhrec.com/average-decks/zimone-infinite-analyst/plus-1-plus-1-counters` | incluido |
| `https://edhrec.com/average-decks/zimone-infinite-analyst/x-spells` | incluido |
| `https://edhrec.com/average-decks/zimone-infinite-analyst/big-mana` | incluido |
| `https://edhrec.com/average-decks/zimone-infinite-analyst/budget` | incluido |
| `https://edhrec.com/average-decks/zimone-infinite-analyst/lands` | excluido: amostra publica de apenas 1 deck medio |
| `https://edhrec.com/average-decks/zimone-infinite-analyst/landfall` | excluido: 404 |
| `https://edhrec.com/commanders/zimone-infinite-analyst` | contexto Commander e tags publicas |

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_zimone_2026-05-13/zimone_edhrec_average_corpus.json`

## Criterios de inclusao

- fonte publica explicitamente rotulada como EDHREC Average Deck para
  `Zimone, Infinite Analyst`;
- commander em zona de comando com quantidade `1`;
- main deck com quantidade total `99`;
- deck total com quantidade `100`;
- identidade Simic/GU sem cartas fora de cor;
- sem violacao singleton fora de terrenos basicos;
- uso somente offline: o runtime nao faz scraping nem depende de EDHREC ou API
  nao oficial.

## Fatos locais comprovados

Dry-run executado:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_deck_corpus_zimone_2026-05-13/zimone_edhrec_average_corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_deck_corpus_zimone_2026-05-13/dry_run
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

O comandante resolveu localmente como `Zimone, Infinite Analyst`, preservando a
identidade GU esperada.

Artifact de validacao:
`server/test/artifacts/commander_reference_deck_corpus_zimone_2026-05-13/dry_run/zimone_infinite_analyst_dry_run_summary.json`

Apply executado apos o dry-run PASS:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_deck_corpus_zimone_2026-05-13/zimone_edhrec_average_corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_deck_corpus_zimone_2026-05-13/apply
```

Apply idempotente executado em seguida:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_deck_corpus_zimone_2026-05-13/zimone_edhrec_average_corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_deck_corpus_zimone_2026-05-13/apply_idempotency
```

Resultado dos tres passos:

| Step | status | db_mutations | deck_count | accepted_deck_count | rejected_deck_count | gates |
| --- | --- | --- | ---: | ---: | ---: | --- |
| dry-run | `PASS` | `false` | 5 | 5 | 0 | `commander_quantity=1`, `main_quantity=99`, `unresolved=0`, `off_color=0`, `singleton_violations={}` |
| apply | `PASS` | `true` | 5 | 5 | 0 | `commander_quantity=1`, `main_quantity=99`, `unresolved=0`, `off_color=0`, `singleton_violations={}` |
| apply idempotency | `PASS` | `true` | 5 | 5 | 0 | `commander_quantity=1`, `main_quantity=99`, `unresolved=0`, `off_color=0`, `singleton_violations={}` |

Artifacts:

- `server/test/artifacts/commander_reference_deck_corpus_zimone_2026-05-13/dry_run/zimone_infinite_analyst_dry_run_summary.json`
- `server/test/artifacts/commander_reference_deck_corpus_zimone_2026-05-13/apply/zimone_infinite_analyst_apply_summary.json`
- `server/test/artifacts/commander_reference_deck_corpus_zimone_2026-05-13/apply_idempotency/zimone_infinite_analyst_apply_summary.json`

A escrita foi aditiva/idempotente por upsert do runner. Rollback pratico, se
necessario, deve remover apenas os registros das `source_deck_key` do corpus
Zimone aplicado, preservando cards, legalidades e profiles.

Contagens DB-backed apos apply/idempotencia:

| Scope | Count |
| --- | ---: |
| pre-apply dry-run baseline | `deck_count=5`, `accepted_deck_count=5`, `db_mutations=false` |
| `commander_reference_decks` para Zimone | 5 |
| `commander_reference_decks` aceitos para Zimone | 5 |
| `commander_reference_deck_cards` para Zimone | 431 |
| `commander_reference_deck_analysis` para Zimone | 1 |
| analysis `deck_count` / `accepted_deck_count` | `5` / `5` |

## Readiness scorecard apos apply

Comando:

```bash
cd server
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander='Zimone, Infinite Analyst' \
  --artifact-dir=test/artifacts/commander_reference_readiness_zimone_after_corpus_2026-05-13
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
| card_stats_count | 42 |
| card_stats_unresolved_count | 0 |
| corpus_accepted_deck_count | 5 |
| corpus_core_package_count | 40 |
| deterministic_deck_valid | `true` |
| deterministic_main_quantity | 99 |

Artifact:
`server/test/artifacts/commander_reference_readiness_zimone_after_corpus_2026-05-13/readiness_scorecard_summary.json`

## Decks aceitos

| Deck key | Source | Lane | Replacements |
| --- | --- | --- | ---: |
| `edhrec_zimone_default_average` | `https://edhrec.com/average-decks/zimone-infinite-analyst` | `edhrec_average_default` | 13 |
| `edhrec_zimone_plus_1_plus_1_counters_average` | `https://edhrec.com/average-decks/zimone-infinite-analyst/plus-1-plus-1-counters` | `edhrec_average_plus_1_plus_1_counters` | 12 |
| `edhrec_zimone_x_spells_average` | `https://edhrec.com/average-decks/zimone-infinite-analyst/x-spells` | `edhrec_average_x_spells` | 12 |
| `edhrec_zimone_big_mana_average` | `https://edhrec.com/average-decks/zimone-infinite-analyst/big-mana` | `edhrec_average_big_mana` | 11 |
| `edhrec_zimone_budget_average` | `https://edhrec.com/average-decks/zimone-infinite-analyst/budget` | `edhrec_average_budget` | 12 |

## Unresolved e correcao local-resolvivel

A primeira validacao rejeitou 5/5 decks apenas por `unresolved_cards`. Nao houve
off-color nem singleton violation. As cartas ausentes no banco local em
2026-05-13 foram:

| Unresolved source card |
| --- |
| `Brass Infiniscope` |
| `Expansion Algorithm` |
| `Geometer's Arthropod` |
| `Kinetic Ooze` |
| `Lattice Library` |
| `Mind into Matter` |
| `Nev, the Practical Dean` |
| `Nexus Mentality` |
| `Owlin Spiralmancer` |
| `Paradox Gardens` |
| `Quandrix Charm` |
| `Striding Shotcaller` |
| `Turbulent Wilderness` |
| `Yavimaya Bloomsage` |

Para nao aplicar backfill nesta etapa, o JSON final foi marcado como
`edhrec_average_deck_local_resolvable_projection`. Cada slot unresolved recebeu
substituto Simic on-theme ja resolvivel localmente; o proprio artifact registra
`local_resolution_replacements` por deck.

## Achados derivados da web

As paginas EDHREC Average Deck provam contexto Commander por fonte, titulo,
`total_card_count=100` e commander no primeiro slot da lista media. As tags e
listas publicas apontam para o mesmo nucleo estrategico:

- X spells como eixo principal de escala;
- suporte de +1/+1 counters para aumentar Zimone e baratear futuros X spells;
- ramp e big mana para converter desconto em mesa, compra e finalizacao;
- Hydras, clones e payoffs escalaveis como finalizadores flexiveis;
- budget como lane casual separada, nao como prova cEDH.

## Interpretacao estrategica

Zimone nao deve ser tratada como Simic goodstuff generico. A malicia do deck e
criar um ciclo de crescimento: conjurar X spells, colocar counters em Zimone,
reduzir o proximo X spell e transformar mana extra em draw, criaturas grandes ou
finishers. Counter doublers e proliferate sao aceleradores desse motor, nao um
plano independente. Linhas de mana infinita para X spell existem como risco de
poder, mas nao foram provadas como default Commander/casual pelas fontes usadas.

Padroes uteis para absorver futuramente em `optimize`/`generate`:

- manter densidade real de X spells e payoffs escalaveis;
- priorizar ramp que ajuda big turns: rocks Simic, land ramp e dorks que escalam
  com counters;
- valorizar pacote de counters: `Hardened Scales`, `Branching Evolution`,
  `The Ozolith`, `Evolution Sage`, `Kami of Whispered Hopes` e
  `Forgotten Ancient`;
- separar lane budget de average/big mana para nao forcar cartas premium em
  pedidos casuais.

Padroes arriscados ou nao transferiveis:

- nao colapsar Zimone em landfall Simic, porque `/lands` tinha amostra media de
  apenas 1 deck e `/landfall` nao estava disponivel;
- nao promover combo/cEDH sem fonte explicita e lane separada;
- nao copiar decklists em runtime; usar apenas sinais agregados de roles,
  recorrencia e pacotes.

## Proximo passo minimo

1. Executar prova publica sanitizada 5x de `/ai/generate` com
   `commander_name='Zimone, Infinite Analyst'`, sem registrar token, e-mail,
   senha, prompt completo ou decklists.
2. Opcionalmente auditar backfill oficial das cartas Secrets of Strixhaven
   unresolved via Scryfall, caso o objetivo seja substituir a projecao por listas
   EDHREC mais fieis.
