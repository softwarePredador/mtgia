# Relatorio Meta Deck Intelligence

Data: 2026-04-24

## Escopo desta rodada

Habilitar e provar persistencia segura do `stage2` em `external_commander_meta_candidates`, e separar um gate explicito de promocao `external_commander_meta_candidates -> meta_decks` com `dry-run` por padrao.

## Resumo do pipeline validado

Pipeline auditado nesta task:

1. `EDHTop16 /tournament/<slug>`
2. `server/bin/expand_external_commander_meta_candidates.dart`
3. artefato local `topdeck_edhtop16_expansion_dry_run_latest.json`
4. `server/bin/import_external_commander_meta_candidates.dart --validation-profile=topdeck_edhtop16_stage2`
5. resolucao em `cards`
6. legalidade em `card_legalities`
7. persistencia deduplicada em `external_commander_meta_candidates`
8. `server/bin/promote_external_commander_meta_candidates.dart`
9. validacao de imutabilidade de `meta_decks`

O stage 2 agora nao para mais em schema/source validation: ele valida contra o banco, bloqueia rejeitados, persiste apenas na fila externa e deixa `meta_decks` fora do caminho.

## Comandos executados

```bash
cd server && dart analyze
cd server && dart test
cd server && dart run bin/migrate_external_commander_meta_candidates.dart
cd server && dart run bin/import_external_commander_meta_candidates.dart test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json --validation-profile=topdeck_edhtop16_stage2 --imported-by=meta_deck_intelligence_2026_04_24
cd server && dart run bin/promote_external_commander_meta_candidates.dart --report-json-out=test/artifacts/external_commander_meta_candidates_promotion_gate_dry_run_2026-04-24.json
cd server && set -a && source .env >/dev/null 2>&1 && set +a && psql "$DATABASE_URL" -Atqc "SELECT COUNT(*)::text || '|' || md5(COALESCE(string_agg(source_url || '|' || format || '|' || COALESCE(archetype,'') || '|' || COALESCE(card_list,'') || '|' || COALESCE(placement,''), '||' ORDER BY source_url), '')) FROM meta_decks"
cd server && dart run bin/meta_profile_report.dart > /tmp/meta_profile_report_2026-04-24.json
```

## Evidencia da validacao stage 2

Artifact gerado:

- `server/test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json`

Resultado observado:

| Medida | Valor |
| --- | --- |
| accepted_count | 4 |
| rejected_count | 0 |
| legal | 3 |
| not_proven | 1 |
| illegal | 0 |

Detalhe comprovado no artifact:

- `commander_color_identity` agora aparece por deck
- `unresolved_cards` agora aparece por deck
- `illegal_cards` agora aparece por deck
- `legal_status` agora aparece por deck

Estado por deck no artifact regenerado:

| Deck | commander_color_identity | legal_status | unresolved_cards | illegal_cards |
| --- | --- | --- | --- | --- |
| Scion of the Ur-Dragon | `WUBRG` | `not_proven` | `Prismari, the Inspiration` | `0` |
| Norman Osborn // Green Goblin | `BRU` | `legal` | `0` | `0` |
| Malcolm, Keen-Eyed Navigator + Vial Smasher the Fierce | `BRU` | `legal` | `0` | `0` |
| Kraum, Ludevic's Opus + Tymna the Weaver | `BRUW` | `legal` | `0` | `0` |

Leitura:

- o stage 2 prova identidade dos commanders para `3/4` decks expandidos
- existe `1` caso `not_proven`, nao `illegal`
- nenhum deck resolveu para `illegal_cards`
- o aceite do stage 2 continua suficiente para staging seguro na fila externa
- `is_commander_legal=false` continua bloqueante por regra de validacao

## Evidencia da persistencia segura stage 2

Resultado observado no import real:

| Medida | Valor |
| --- | --- |
| `accepted_count` | `4` |
| `rejected_count` | `0` |
| `external_commander_meta_candidates` persistidos para o torneio | `4` |
| `meta_decks` antes | `641|a7ce915e5f489cb6282856238ddab088` |
| `meta_decks` depois | `641|a7ce915e5f489cb6282856238ddab088` |

Provas adicionais:

- o importador rejeita `--promote-validated` em qualquer profile
- a deduplicacao por `source_url` ficou coberta por teste unitario dedicado
- um candidato persistido manteve `research_payload` com as chaves:
  - `collection_method`
  - `commander_count`
  - `mainboard_count`
  - `player_name`
  - `source_chain`
  - `source_context`
  - `standing`
  - `topdeck_deck_url`
  - `topdeck_imported_from`
  - `total_cards`
  - `tournament_id`
  - `tournament_url`
- sample persistido:
  - `validation_status=candidate`
  - `imported_by=meta_deck_intelligence_2026_04_24`
  - `collection_method=edhtop16_graphql_topdeck_deck_page_dry_run`
  - `source_context=edhtop16_tournament_entry`

Leitura:

- `meta_decks` nao foi alterado nem por count nem por hash agregado
- a persistencia ficou confinada a `external_commander_meta_candidates`
- a fila externa preserva o payload de pesquisa completo, sem promocao automatica

## Evidencia do gate separado de promocao

Artifact gerado:

- `server/test/artifacts/external_commander_meta_candidates_promotion_gate_dry_run_2026-04-24.json`

Resultado observado no dry-run:

| Medida | Valor |
| --- | --- |
| total | `4` |
| promotable | `0` |
| blocked | `4` |

Bloqueios observados em `4/4` rows:

- `validation_status_not_validated`
- `missing_or_invalid_legal_status`

Leitura:

- o gate novo usa somente a fila `external_commander_meta_candidates`
- ele **nao** reutiliza `--promote-validated` do importador antigo
- ele so aceitaria `validation_status=validated` e `legal_status` em `valid|warning_reviewed`
- o banco atual ainda nao tem nenhum row apto para promocao, entao o dry-run prova que o corte ficou conservador
- `meta_decks` continuou intocado

## Frescor da base atual

`meta_decks` hoje:

| Metrica | Valor |
| --- | --- |
| total | `641` |
| min_created_at | `2025-11-22` |
| max_created_at | `2026-04-23` |
| Commander family (`EDH` + `cEDH`) | `376` |

Leitura:

- a base principal continua fresca para Commander/cEDH ate `2026-04-23`
- formatos nao Commander permanecem concentrados em fevereiro
- a fila `external_commander_meta_candidates` ficou fresca em `2026-04-24`, mas ainda com apenas `4` rows `competitive_commander`

## Cobertura real por formato

| Formato | Decks | Min created_at | Max created_at |
| --- | ---: | --- | --- |
| cEDH | 214 | 2026-02-12 | 2026-04-23 |
| EDH | 162 | 2025-11-22 | 2026-04-23 |
| PI | 46 | 2026-02-12 | 2026-02-12 |
| ST | 46 | 2026-02-09 | 2026-02-12 |
| VI | 44 | 2026-02-12 | 2026-02-12 |
| MO | 41 | 2026-02-12 | 2026-02-12 |
| LE | 40 | 2026-02-12 | 2026-02-12 |
| PAU | 40 | 2026-02-12 | 2026-02-12 |
| PREM | 8 | 2026-02-12 | 2026-02-12 |

## Cobertura real por identidade de cor Commander

`cEDH`:

- `COLORLESS_OR_UNRESOLVED=28`
- `GU=24`
- `BRUW=22`
- `BRU=17`
- `BGUW=15`
- `W=13`
- `BUW=13`
- `GRU=8`
- `R=7`
- `BRW=7`
- `GUW=5`
- `BGW=5`
- `RW=4`
- `BGRU=4`
- `BG=4`
- `BU=4`
- `RU=4`
- `U=4`
- `B=3`
- `BR=3`
- `RUW=3`
- `UW=2`
- `BGRUW=2`
- `GW=2`
- `G=2`
- `BGU=1`
- `BW=1`
- `GR=1`
- `GRUW=2`

`EDH`:

- `RU=30`
- `G=16`
- `B=14`
- `W=13`
- `BGR=10`
- `BR=10`
- `RUW=8`
- `RW=8`
- `U=8`
- `COLORLESS_OR_UNRESOLVED=8`
- `BU=6`
- `BGU=5`
- `BUW=5`
- `GR=6`
- `BG=3`
- `R=3`
- `BRW=2`
- `GRW=2`
- `UW=1`
- `BRUW=1`
- `BGUW=1`
- `BGRUW=1`
- `GRU=1`

Leitura:

- cobertura de Commander competitivo existe em mono, bi, tri, four-color e five-color
- isso **nao prova** cobertura completa de todas as shells Commander
- o bucket `COLORLESS_OR_UNRESOLVED` ainda mistura casos realmente incolores com mapeamentos nao resolvidos
- na fila externa stage 2 persistida, `color_identity` continua vazia em `4/4`; a identidade comprovada ainda mora no artifact/legality evidence

## Gaps observados

1. O campo persistido `color_identity` continua vazio nos stage2 expandidos; a prova real segue no artifact/legality evidence.
2. `Prismari, the Inspiration` nao resolveu em `cards`, deixando `Scion of the Ur-Dragon` como `not_proven`.
3. O bucket `COLORLESS_OR_UNRESOLVED` ainda precisa ser separado para medir colorless real vs. falha de resolucao.
4. A base principal `meta_decks` continua fresca para Commander/cEDH, mas os formatos nao Commander estao congelados em fevereiro.
5. Os candidatos externos atuais continuam com `validation_status=candidate` e `legal_status` ausente; logo, a promocao real segue `not proven` ate revisao operacional.

## Interpretacao estrategica util para `optimize` e `generate`

Mesmo nessa amostra curta, os decks competitivos expandidos repetem sinais fortes:

- compressao de wincons em shells de baixo slot (`Thassa's Oracle`, `Tainted Pact`, `Underworld Breach`, `Ad Nauseam`)
- alta densidade de fast mana e interacao de custo baixo
- commanders funcionando como ancora de identidade e de plano, nao como tema decorativo
- uso de cartas multi-papel para proteger combo sem perder velocidade

Traducao pratica para o produto:

1. `optimize` deve continuar tratando a identidade do comandante como gate duro, nao heuristica fraca.
2. `optimize` deve priorizar pacotes compactos de combo/protecao por shell, e nao apenas staples isoladas.
3. `generate` deve evitar listas que acertam tema mas erram densidade de aceleracao e interacao.
4. `generate` e `optimize` ganham valor ao diferenciar `legal`, `illegal` e `not_proven` na ingestao de fontes externas.

## Separacao entre fato provado e nao provado

Provado em codigo e artifact:

- stage 2 resolve commanders e mainboard contra `cards` quando a base responde
- stage 2 consulta `card_legalities` para `commander`
- stage 2 produz `commander_color_identity`, `unresolved_cards`, `illegal_cards` e `legal_status`
- `unresolved_cards` nao mata `--dry-run`
- `illegal_cards` e `is_commander_legal=false` bloqueiam

Nao provado nesta rodada:

- que `Prismari, the Inspiration` seja realmente uma carta ausente do ecossistema e nao apenas um gap local de catalogo
- que a cobertura atual de identidades Commander seja completa o bastante para todos os shells competitivos relevantes

## Menores proximas acoes tecnicas

1. Adicionar alias/resolution targeted para `Prismari, the Inspiration` e revalidar o artifact.
2. Definir revisao operacional da fila externa para preencher `validation_status=validated` e `legal_status=valid|warning_reviewed` antes de qualquer `--apply`.
3. Persistir `commander_color_identity` derivada na fila externa para parar de depender so do artifact.
4. Separar `COLORLESS` de `UNRESOLVED` nos relatórios de cobertura Commander.
