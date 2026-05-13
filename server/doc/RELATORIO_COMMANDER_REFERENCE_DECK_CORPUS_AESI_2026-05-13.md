# Commander Reference Deck Corpus - Aesi, Tyrant of Gyre Strait - 2026-05-13

## Verdict

**PASS.**

O corpus offline de `Aesi, Tyrant of Gyre Strait` foi montado com 4 paginas
publicas EDHREC Average Deck, validado em `--dry-run`, aplicado com sucesso e
reaplicado para prova de idempotencia. A prova publica 5x de `/ai/generate`
passou no backend publico e o scorecard read-only final ficou em `score=100`,
`ready_for_mini_batch`.

## Scope

Scanner, camera, OCR, app mobile e criacao/aplicacao de deck no app ficaram
fora do escopo. O trabalho cobriu corpus/reference pipeline, prova publica
sanitizada de `/ai/generate` e documentacao.

## Fontes consultadas

Fontes publicas Commander, coletadas uma vez em baixo volume para analise
offline:

- `https://edhrec.com/average-decks/aesi-tyrant-of-gyre-strait`
- `https://edhrec.com/average-decks/aesi-tyrant-of-gyre-strait/landfall`
- `https://edhrec.com/average-decks/aesi-tyrant-of-gyre-strait/lands`
- `https://edhrec.com/average-decks/aesi-tyrant-of-gyre-strait/budget`
- `https://edhrec.com/commanders/aesi-tyrant-of-gyre-strait` como contexto
  publico adicional de Commander.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_aesi_2026-05-13/aesi_edhrec_average_corpus.json`

## Criterios de inclusao

- fonte publica explicitamente rotulada como EDHREC Average Deck para Aesi;
- commander em zona de comando com quantidade `1`;
- main deck com quantidade total `99`;
- deck total com quantidade `100`;
- identidade Simic/GU sem cartas fora de cor;
- sem violacao singleton fora de terrenos basicos;
- uso somente offline: o runtime nao faz scraping nem depende de API nao
  oficial.

## Fatos locais comprovados

Dry-run executado:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_deck_corpus_aesi_2026-05-13/aesi_edhrec_average_corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_deck_corpus_aesi_2026-05-13/dry_run
```

Resultado:

| Metric | Value |
| --- | ---: |
| status | `PASS` |
| db_mutations | `false` |
| deck_count | 4 |
| accepted_deck_count | 4 |
| rejected_deck_count | 0 |
| commander_quantity | 1 em 4/4 |
| main_quantity | 99 em 4/4 |
| unresolved_count | 0 em 4/4 |
| off_color_count | 0 em 4/4 |
| singleton_violations | `{}` em 4/4 |

O comandante resolveu localmente como
`Aesi, Tyrant of Gyre Strait // Aesi, Tyrant of Gyre Strait`, preservando a
primeira face esperada.

Apply executado apos o dry-run PASS:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_deck_corpus_aesi_2026-05-13/aesi_edhrec_average_corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_deck_corpus_aesi_2026-05-13/apply
```

Apply idempotente executado em seguida:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_deck_corpus_aesi_2026-05-13/aesi_edhrec_average_corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_deck_corpus_aesi_2026-05-13/apply_idempotency
```

Resultado dos tres passos:

| Step | status | db_mutations | deck_count | accepted_deck_count | rejected_deck_count | gates |
| --- | --- | --- | ---: | ---: | ---: | --- |
| dry-run | `PASS` | `false` | 4 | 4 | 0 | `commander_quantity=1`, `main_quantity=99`, `unresolved=0`, `off_color=0`, `singleton_violations={}` |
| apply | `PASS` | `true` | 4 | 4 | 0 | `commander_quantity=1`, `main_quantity=99`, `unresolved=0`, `off_color=0`, `singleton_violations={}` |
| apply idempotency | `PASS` | `true` | 4 | 4 | 0 | `commander_quantity=1`, `main_quantity=99`, `unresolved=0`, `off_color=0`, `singleton_violations={}` |

Artifacts:

- `server/test/artifacts/commander_reference_deck_corpus_aesi_2026-05-13/dry_run/aesi_tyrant_of_gyre_strait_dry_run_summary.json`
- `server/test/artifacts/commander_reference_deck_corpus_aesi_2026-05-13/apply/aesi_tyrant_of_gyre_strait_apply_summary.json`
- `server/test/artifacts/commander_reference_deck_corpus_aesi_2026-05-13/apply_idempotency/aesi_tyrant_of_gyre_strait_apply_summary.json`

## Readiness scorecard apos apply

Comando:

```bash
cd server
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander='Aesi, Tyrant of Gyre Strait' \
  --artifact-dir=test/artifacts/commander_reference_readiness_aesi_after_corpus_2026-05-13
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
| corpus_core_package_count | 31 |
| deterministic_deck_valid | `true` |
| deterministic_main_quantity | 99 |

Artifact:
`server/test/artifacts/commander_reference_readiness_aesi_after_corpus_2026-05-13/readiness_scorecard_summary.json`

## Public proof

Backend publico:
`https://evolution-cartinhas.8ktevp.easypanel.host`

SHA testado:
`5ff2e53b4a4f18ecd3b7d5e330fd34da06c634fb`

Comando operacional executado: prova sanitaria 5x `POST /ai/generate` com
`format=Commander`, `bracket=3`, `commander_name='Aesi, Tyrant of Gyre Strait'`
e prompt focado em lands/ramp/value, extra land drops, landfall payoffs,
interaction e win conditions Simic. Um usuario QA descartavel foi criado apenas
em memoria para obter JWT; token, e-mail, senha, prompt completo e decklists nao
foram salvos.

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
| p50 | 987ms |
| p95 | 1234ms |

O payload publico marcou `is_mock=true`, mas sem timeout, sem erro de validacao
e com profile/stats/corpus ativos. Isso foi classificado como caminho
deterministico reference-guided, nao como fallback de timeout.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_aesi_2026-05-13/public_proof/summary.json`

## Readiness scorecard final

Comando:

```bash
cd server
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander='Aesi, Tyrant of Gyre Strait' \
  --runtime-summary=test/artifacts/commander_reference_deck_corpus_aesi_2026-05-13/public_proof/summary.json \
  --artifact-dir=test/artifacts/commander_reference_readiness_aesi_public_2026-05-13
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
| corpus_core_package_count | 31 |
| deterministic_deck_valid | `true` |
| deterministic_main_quantity | 99 |

Artifact:
`server/test/artifacts/commander_reference_readiness_aesi_public_2026-05-13/readiness_scorecard_summary.json`

## Achados derivados da web

As paginas EDHREC Average Deck provam contexto Commander por fonte e formato da
pagina. As quatro variantes apontam para o mesmo nucleo estrategico:

- contagem alta de terrenos, media local do corpus `39.75`;
- ramp e efeitos de land drop/draw para transformar Aesi em motor de vantagem;
- payoffs de landfall e criaturas de inevitabilidade;
- pacote de bounce/recursion/utility lands para repetir triggers ou recuperar
  apos wipe;
- interacao azul/verde suficiente para proteger o motor sem virar controle
  cEDH.

## Interpretacao estrategica

Aesi recompensa o jogador por manter fluxo de terrenos, nao por jogar Simic
goodstuff generico. A "malicia" do deck e transformar cada land drop em compra
de carta, depois converter a mao cheia em mais lands, landfall e inevitabilidade.

Padroes uteis para absorver em `optimize`/`generate`:

- manter land count alto para Aesi, proximo de 39-41;
- priorizar ramp que coloca terrenos ou permite land drops extras;
- valorizar `Tatyova, Benthic Druid`, `Scute Swarm`, `Rampaging Baloths`,
  `Avenger of Zendikar`, `Ramunap Excavator`, `Meloku the Clouded Mirror` e
  utility lands recorrentes;
- tratar budget e average como lanes distintas, sem importar automaticamente
  cartas premium para perfil casual/budget.

Padroes arriscados ou nao transferiveis:

- nao colapsar Aesi em shell Simic generico de draw/ramp;
- nao tratar lista budget como nivel de poder default;
- nao promover pacote cEDH/fast-combo sem fonte explicita e lane separada;
- nao copiar decklist em runtime; usar apenas sinais agregados de roles,
  top cards e pacotes.

## Decisao

`Aesi, Tyrant of Gyre Strait` esta promovido para mini-batch controlado. A
promocao nao altera o contrato de `/ai/generate`; o app continua usando
`generated_deck` e `validation` como fonte de verdade e tratando diagnostics
como opcionais.
