# Relatorio Meta Deck Intelligence

Data: 2026-04-24

## Escopo desta rodada

Implementar e provar a validacao de `color_identity` e legalidade Commander para candidatos `stage2` de `external_commander_meta_candidates`, sem escrita em banco.

## Resumo do pipeline validado

Pipeline auditado nesta task:

1. `EDHTop16 /tournament/<slug>`
2. `server/bin/expand_external_commander_meta_candidates.dart`
3. artefato local `topdeck_edhtop16_expansion_dry_run_latest.json`
4. `server/bin/import_external_commander_meta_candidates.dart --dry-run --validation-profile=topdeck_edhtop16_stage2`
5. resolucao read-only em `cards`
6. legalidade read-only em `card_legalities`
7. artefato final `topdeck_edhtop16_expansion_dry_run_latest.validation.json`

O stage 2 agora nao para mais em schema/source validation: ele tenta provar identidade de cor e legalidade Commander com dados do banco quando possivel.

## Comandos executados

```bash
cd server && dart analyze lib/meta/external_commander_meta_candidate_support.dart bin/import_external_commander_meta_candidates.dart test/external_commander_meta_candidate_support_test.dart
cd server && dart test test/external_commander_meta_candidate_support_test.dart
cd server && dart test
cd server && dart run bin/import_external_commander_meta_candidates.dart test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json --dry-run --validation-profile=topdeck_edhtop16_stage2 --validation-json-out=test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json
cd server && set -a && source .env >/dev/null 2>&1 && python3 - <<'PY'
# query de frescor e cobertura por formato/identidade em meta_decks
PY
python3 - <<'PY'
# resumo do artifact stage2 regenerado
PY
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

- o stage 2 agora prova identidade dos commanders para `3/4` decks expandidos
- existe `1` caso `not_proven`, nao `illegal`
- nenhum deck resolveu para `illegal_cards`
- `unresolved_cards` ficou corretamente nao fatal em `--dry-run`
- `is_commander_legal=false` continua bloqueante por regra de validacao

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

## Gaps observados

1. O campo persistido `candidate.color_identity` continua vazio nos expandidos; a prova real agora fica no artifact de validacao.
2. `Prismari, the Inspiration` nao resolveu em `cards`, deixando `Scion of the Ur-Dragon` como `not_proven`.
3. O bucket `COLORLESS_OR_UNRESOLVED` ainda precisa ser separado para medir colorless real vs. falha de resolucao.
4. A base principal `meta_decks` continua fresca para Commander/cEDH, mas os formatos nao Commander estao congelados em fevereiro.

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
2. Separar `COLORLESS` de `UNRESOLVED` nos relatórios de cobertura Commander.
3. Se a validacao stage 2 continuar estavel, considerar promover `legal_status` para o payload operacional de futuras rodadas multi-fonte antes de qualquer escrita em banco.
