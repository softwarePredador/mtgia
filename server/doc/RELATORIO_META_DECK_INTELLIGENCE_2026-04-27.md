# Relatorio Meta Deck Intelligence - 2026-04-27

## Escopo

- repositorio: `softwarePredador/mtgia`
- foco: pipeline externo `EDHTop16 -> TopDeck -> external_commander_meta_candidates -> meta_decks`
- objetivo adicional: confirmar cobertura real apos promocao pequena e validar consumo seguro em `optimize` e `generate`

## Veredito

**O pipeline externo ficou operacional em lote pequeno, com `2` novas promocoes seguras para `meta_decks`, mas o blocker estrutural do TopDeck ainda existe em parte do evento.**

- `MTGTop8 -> meta_decks` continua vivo em dry-run para `cEDH`
- `EDHTop16 -> TopDeck` continua vivo, mas **nao completamente**:
  - standings `1`, `4`, `5`, `8` expandidos com decklist completa
  - standings `2`, `3`, `6`, `7` continuam sem dados de deck utilizaveis no HTML atual
- o lote pequeno filtrado (`standing-5`, `standing-8`) passou por:
  - `expand`
  - `stage2 validation`
  - `staging apply`
  - `promotion dry-run`
  - `promotion apply`
- `meta_decks` agora tem `644` rows:
  - `mtgtop8=641`
  - `external=3`
- a cobertura de identidade de cor do comandante deixou de ficar majoritariamente em `unknown`:
  - `mtgtop8 cEDH`: `212/214` resolvidos
  - `mtgtop8 EDH`: `161/162` resolvidos
  - `external cEDH`: `3/3` resolvidos

## Mudancas tecnicas aplicadas

### 1. Parser TopDeck endurecido

Arquivos:

- `server/lib/meta/external_commander_deck_expansion_support.dart`
- `server/test/external_commander_deck_expansion_support_test.dart`

Mudanca:

- `parseTopDeckDeckObjectFromHtml(...)` deixou de depender so de `const deckObj = ...`
- agora tenta, nesta ordem:
  1. `deckObj`
  2. template `copyDecklist() / decklistContent`
  3. DOM renderizado (`commanders-sidebar` + `text-list-item`)

Leitura:

- isso reduz drift para variacoes de pagina TopDeck que ainda entregam decklist, mas nao no mesmo marcador JS
- **nao ficou provado** que o fallback resolve os standings `2/3/6/7` deste evento; nesses casos a resposta live continua vindo sem decklist usavel

### 2. Lookup de identidade de cor do comandante ampliado

Arquivos:

- `server/lib/import_card_lookup_service.dart`
- `server/lib/meta/external_commander_meta_candidate_support.dart`
- `server/test/external_commander_meta_candidate_support_test.dart`
- `server/bin/meta_profile_report.dart`

Mudanca:

- lookup passou a carregar tambem `mana_cost`
- a identidade agora deriva de:
  - `color_identity`
  - `colors`
  - `mana_cost`
  - `oracle_text`
- labels de parceiros no formato `A / B` agora sao separados com seguranca quando `partner_commander_name` nao existe
- `meta_profile_report` passou a usar a mesma resolucao expandida, em vez de ler apenas `cards.color_identity`

Leitura:

- isso fecha o gap dos commanders que existem no catalogo mas chegam com `color_identity` nulo
- casos como `Norman Osborn // Green Goblin`, `Scion of the Ur-Dragon`, `Kraum`, `Tymna`, `Malcolm`, `Vial Smasher`, `Kefka`, `Brigid`, `Etali` deixam de depender exclusivamente da coluna quebrada/incompleta

## Pipeline comprovado

1. `bin/fetch_meta.dart` consome `MTGTop8` e grava direto em `meta_decks`
2. `bin/expand_external_commander_meta_candidates.dart` busca standings em `EDHTop16` e tenta expandir deck pages do `TopDeck`
3. `bin/import_external_commander_meta_candidates.dart --dry-run --validation-profile=topdeck_edhtop16_stage2` valida:
   - card count
   - legalidade Commander
   - identidade de cor
   - unresolved/illegal cards
4. `bin/stage_external_commander_meta_candidates.dart --apply` persiste somente em `external_commander_meta_candidates`
5. `bin/promote_external_commander_meta_candidates.dart --apply` sobe apenas candidates `staged` e `valid`
6. `bin/meta_profile_report.dart` e `bin/extract_meta_insights.dart --report-only` confirmam o consumo source-aware

## Comandos executados

```bash
cd server && dart format \
  lib/meta/external_commander_deck_expansion_support.dart \
  lib/import_card_lookup_service.dart \
  lib/meta/external_commander_meta_candidate_support.dart \
  bin/meta_profile_report.dart \
  test/external_commander_deck_expansion_support_test.dart \
  test/external_commander_meta_candidate_support_test.dart

cd server && dart analyze \
  lib/meta/external_commander_deck_expansion_support.dart \
  lib/import_card_lookup_service.dart \
  lib/meta/external_commander_meta_candidate_support.dart \
  bin/meta_profile_report.dart \
  test/external_commander_deck_expansion_support_test.dart \
  test/external_commander_meta_candidate_support_test.dart

cd server && dart test -r compact \
  test/external_commander_deck_expansion_support_test.dart \
  test/external_commander_meta_candidate_support_test.dart \
  test/external_commander_meta_staging_support_test.dart \
  test/external_commander_meta_promotion_support_test.dart \
  test/meta_deck_reference_support_test.dart \
  test/meta_deck_analytics_support_test.dart \
  test/mtgtop8_meta_support_test.dart \
  test/optimize_runtime_support_test.dart

cd server && dart run bin/fetch_meta.dart cEDH --dry-run --limit-events=1 --limit-decks=2 --delay-event-ms=0

cd server && dart run bin/expand_external_commander_meta_candidates.dart \
  --source-url=https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57 \
  --limit=8 \
  --output=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_limit8_2026-04-27.json

cd server && dart run bin/import_external_commander_meta_candidates.dart \
  test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_limit8_2026-04-27.json \
  --dry-run \
  --validation-profile=topdeck_edhtop16_stage2 \
  --validation-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_limit8_2026-04-27.validation.json

cd server && dart run bin/stage_external_commander_meta_candidates.dart \
  --dry-run \
  --expansion-artifact=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_promotable_batch_2026-04-27.json \
  --validation-artifact=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_promotable_batch_2026-04-27.validation.json \
  --imported-by=meta_deck_intelligence_2026_04_27 \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_promotable_batch_stage_dry_run_2026-04-27.json

cd server && dart run bin/stage_external_commander_meta_candidates.dart \
  --apply \
  --expansion-artifact=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_promotable_batch_2026-04-27.json \
  --validation-artifact=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_promotable_batch_2026-04-27.validation.json \
  --imported-by=meta_deck_intelligence_2026_04_27 \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_promotable_batch_stage_apply_2026-04-27.json

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --source-url=https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57#standing-5 \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing5_dry_run_2026-04-27.json

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --apply \
  --source-url=https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57#standing-5 \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing5_apply_2026-04-27.json

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --source-url=https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57#standing-8 \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing8_dry_run_2026-04-27.json

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --apply \
  --source-url=https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57#standing-8 \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing8_apply_2026-04-27.json

cd server && dart run bin/meta_profile_report.dart \
  > test/artifacts/meta_deck_intelligence_2026-04-27/meta_profile_report_2026-04-27.json

cd server && dart run bin/extract_meta_insights.dart --report-only \
  > test/artifacts/meta_deck_intelligence_2026-04-27/extract_meta_insights_report_only_2026-04-27.json
```

## Evidencia validada

### 1. `MTGTop8` segue vivo

Artifact:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/fetch_meta_cedh_dry_run_2026-04-27.txt`

Fatos provados:

- `https://www.mtgtop8.com/format?f=cEDH` respondeu
- o evento `https://www.mtgtop8.com/event?e=83812` expôs `115` rows
- o parser leu:
  - `Terra, Magical Adept`
  - `Kraum + Tymna`

### 2. `EDHTop16 -> TopDeck` segue parcialmente vivo

Artifacts:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_limit8_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_limit8_2026-04-27.validation.json`

Resultado:

- `expanded_count=4`
- `rejected_count=4`
- expandidos:
  - `standing-1` `Scion of the Ur-Dragon`
  - `standing-4` `Norman Osborn // Green Goblin`
  - `standing-5` `Malcolm + Vial Smasher`
  - `standing-8` `Kraum + Tymna`
- rejeitados:
  - `standing-2`
  - `standing-3`
  - `standing-6`
  - `standing-7`
- motivo em todos os rejeitados:
  - `topdeck_deckobj_missing`

Leitura:

- o parser cobre mais de um formato de deck page agora
- **nao ficou provado** que o restante do erro e apenas parser drift
- o HTML live dos rejeitados continua sem decklist utilizavel; logo o blocker restante parece upstream/data-availability do `TopDeck`, nao so seletor local

### 3. Stage 2 ficou verde para o lote novo

Artifacts:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_promotable_batch_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_promotable_batch_2026-04-27.validation.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_promotable_batch_stage_dry_run_2026-04-27.json`

Fatos provados:

- batch pequeno filtrado:
  - `standing-5`
  - `standing-8`
- `accepted=2`
- `rejected=0`
- ambos com:
  - `legal_status=legal`
  - `unresolved=0`
  - `illegal=0`

### 4. Staging e promotion apply ocorreram com guards verdes

Artifacts:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_promotable_batch_stage_apply_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing5_dry_run_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing5_apply_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing8_dry_run_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing8_apply_2026-04-27.json`

Fatos provados:

- `standing-5` promotable em dry-run e promovido em apply
- `standing-8` promotable em dry-run e promovido em apply
- nenhum dos dois bateu em:
  - `duplicate_source_url_in_stage`
  - `source_url_already_present_in_meta_decks`
  - `duplicate_deck_fingerprint_in_stage`
  - `deck_fingerprint_already_present_in_meta_decks`

## Frescor real da base

Artifact:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/db_snapshot_2026-04-27.json`

`meta_decks_by_source`:

| source | decks | min(created_at) | max(created_at) |
| --- | ---: | --- | --- |
| `mtgtop8` | 641 | `2025-11-22T14:14:20+00:00` | `2026-04-23T20:02:52+00:00` |
| `external` | 3 | `2026-04-27T12:04:17+00:00` | `2026-04-27T19:32:47+00:00` |

`external_candidate_status`:

| validation_status | legal_status | decks |
| --- | --- | ---: |
| `promoted` | `valid` | 3 |
| `staged` | `warning_pending` | 1 |

Leitura:

- a fonte externa ja nao esta em `1` row isolada
- o corpus externo continua pequeno, mas ja tem `3` listas competitivas promovidas com prova de guard verde
- `Scion` permanece staged e **nao promovido**, como deveria

## Cobertura real por formato e identidade de cor

Artifacts:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/meta_profile_report_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/extract_meta_insights_report_only_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/commander_color_identity_coverage_2026-04-27.json`

### Cobertura por fonte/subformato

`extract_meta_insights_report_only_2026-04-27.json`:

| source | subformat | decks |
| --- | --- | ---: |
| `mtgtop8` | `competitive_commander` | 214 |
| `mtgtop8` | `duel_commander` | 162 |
| `external` | `competitive_commander` | 3 |

### Cobertura por formato em `meta_profile_report`

`meta_profile_report_2026-04-27.json`:

| format | deck_count |
| --- | ---: |
| `cEDH` | 217 |
| `EDH` | 162 |

Leitura:

- `cEDH` agora soma `214 mtgtop8 + 3 external`
- `external / duel_commander = 0`

### Cobertura por identidade do comandante

`commander_color_identity_coverage_2026-04-27.json`:

| source | format | decks | resolved | unknown |
| --- | --- | ---: | ---: | ---: |
| `mtgtop8` | `cEDH` | 214 | 212 | 2 |
| `mtgtop8` | `EDH` | 162 | 161 | 1 |
| `external` | `cEDH` | 3 | 3 | 0 |

Top unknowns restantes:

| source | format | commander_label | decks |
| --- | --- | --- | ---: |
| `mtgtop8` | `cEDH` | `Prismari, the Inspiration` | 2 |
| `mtgtop8` | `EDH` | `Witherbloom, the Balancer` | 1 |

Leitura:

- a cobertura por identidade do comandante saiu de um estado **not proven** amplo para um estado operacionalmente forte
- o que resta em `unknown` ficou pequeno e localizavel
- o lote externo promovido ficou `3/3` resolvido

## Gaps observados

1. `TopDeck` ainda devolve paginas sem decklist utilizavel em parte do evento
   - standings `2`, `3`, `6`, `7`
   - o parser local agora cobre mais variantes, mas isso nao basta quando o upstream realmente nao entrega o deck
2. `Scion of the Ur-Dragon` segue bloqueado por `Prismari, the Inspiration`
   - status atual correto: `warning_pending`
   - promocao segura continua bloqueada
3. ainda existem poucos commanders residuais em `unknown`
   - `Prismari, the Inspiration`
   - `Witherbloom, the Balancer`

## Interpretacao estrategica

### `Malcolm + Vial Smasher`

Lista Grixis de tesouro/rituais com kill compacta.

Sinais fortes:

- fast mana muito denso
- wheels e loot para acelerar mao e cemitério
- `Underworld Breach`
- `Thassa's Oracle`
- interacao gratis/barata

Uso seguro no produto:

- bom sinal para `competitive_commander`
- ruim como referencia para Commander casual ou `duel_commander`

### `Kraum + Tymna`

Shell classico de Blue Farm / midrange-combo.

Sinais fortes:

- pares de parceiros que geram card advantage natural
- free interaction e stack wars
- plano de grind com consulta/oracle e linhas compactas de combo
- mana base de quatro cores muito eficiente

Uso seguro no produto:

- referencia de alto valor para `optimize` quando `deckFormat=commander` e `bracket >= 3`
- nao deve vazar para prompts Commander amplos sem prova de escopo competitivo

### `Norman Osborn // Green Goblin`

Shell Grixis recente que confirma que o pipeline externo tambem captura commanders novos/UB quando a deck page do TopDeck esta completa.

Sinais fortes:

- pacote `Breach / Oracle / Tainted Pact`
- wheels/filter
- free interaction
- baixa contagem de terrenos

### O que absorver em `optimize` e `generate`

1. manter prioridade alta para:
   - fast mana
   - free interaction
   - pacotes compactos `Oracle / Consultation / Tainted Pact`
   - `Underworld Breach` onde a shell suporta
2. tratar `Malcolm/Vial`, `Kraum/Tymna`, `Norman` como **competitive-only evidence**
3. continuar exibindo provenance/source chain, nunca como instrucao cega

## Validacao de uso seguro em `optimize` e `generate`

Estado comprovado por codigo e testes focados:

- `generate` continua usando meta Commander apenas quando o prompt prova o escopo
- `optimize`/`complete` continuam restringindo `competitive_commander` para `deckFormat=commander` com `bracket >= 3`
- `meta_deck_reference_support` continua separando `competitive_commander` de `duel_commander`
- testes focados continuam verdes:
  - `test/meta_deck_reference_support_test.dart`
  - `test/optimize_runtime_support_test.dart`

Conclusao:

- as `3` listas externas promovidas entram no corpus certo
- o consumo continua source-aware e scope-aware
- **nao houve prova de vazamento inseguro** para `duel_commander` ou Commander casual

## Menores proximas acoes tecnicas

1. adicionar modo de expansao que continue escaneando standings ate coletar `N` decks expandidos, para nao desperdiçar limite em paginas vazias do TopDeck
2. corrigir/backfill do catalogo para os poucos commanders residuais ainda `unknown`
3. manter promocao externa apenas por batch filtrado com `stage2 -> staging -> promotion dry-run -> apply`

## Artefatos principais

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/fetch_meta_cedh_dry_run_2026-04-27.txt`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_limit8_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_limit8_2026-04-27.validation.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_promotable_batch_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_promotable_batch_2026-04-27.validation.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_promotable_batch_stage_dry_run_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_promotable_batch_stage_apply_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing5_dry_run_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing5_apply_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing8_dry_run_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing8_apply_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/meta_profile_report_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/extract_meta_insights_report_only_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/db_snapshot_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/commander_color_identity_coverage_2026-04-27.json`
