# Commander Reference Deck Corpus - Aesi, Tyrant of Gyre Strait - 2026-05-13

## Verdict

**PASS.**

O corpus offline de `Aesi, Tyrant of Gyre Strait` foi montado com 4 paginas
publicas EDHREC Average Deck e validado em `--dry-run`. Nenhuma mutacao de banco
foi executada nesta etapa.

## Scope

Scanner, camera, OCR, app mobile, rotas app-facing e runtime de geracao ficaram
fora do escopo. O trabalho foi restrito a corpus/reference pipeline e
documentacao.

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

## Proximo passo

Rodar scorecard read-only para Aesi usando o corpus aceito. Se o score continuar
bloqueado apenas por prova publica, planejar uma prova publica 5/5 separada
antes de qualquer `--apply` ou promocao de deterministic/reference-guided path.
