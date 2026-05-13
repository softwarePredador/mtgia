# Commander Reference Deck Corpus - Edgar Markov - 2026-05-13

## Verdict

**PASS.**

O corpus preliminar offline de `Edgar Markov` foi montado com 4 paginas
publicas EDHREC Average Deck e validado somente em `--dry-run`. Nenhuma
aplicacao no banco foi executada.

## Scope

Scanner, camera, OCR, app mobile, runtime publico, `/ai/generate`, `/ai/optimize`
e escrita nas tabelas de reference corpus ficaram fora do escopo. Esta entrega
prepara apenas o JSON de corpus e o relatorio preliminar para a proxima etapa.

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
Mardu esperada. Nenhum `--apply` foi executado.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/dry_run/edgar_markov_dry_run_summary.json`

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

## Proxima etapa tecnica minima

1. Revisar o dry-run summary e, se aprovado, executar `--apply` em etapa
   separada.
2. Rodar idempotencia apos apply.
3. Rodar readiness scorecard para Edgar.
4. Fazer prova publica sanitizada de `/ai/generate` somente depois do corpus
   aplicado.
