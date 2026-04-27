# Relatorio Meta Deck Intelligence - 2026-04-27

## Escopo

- repositorio: `softwarePredador/mtgia`
- foco: `MTGTop8 -> meta_decks` e `EDHTop16 -> TopDeck -> external_commander_meta_candidates -> meta_decks`
- delta desta rodada:
  - validar consumo pos-promocao dos externos em `optimize/generate`
  - impedir vazamento de `competitive_commander` para casual/duel
  - implementar scan-through no expansor para coletar `N` decks validos mesmo com standings sem decklist utilizavel
  - promover apenas lote pequeno com `legal` + `unresolved=0` + guards verdes

## Veredito

**O pipeline externo continua operacional e agora ficou mais util em producao local: o expansor conseguiu coletar `6` decks validos ao tentar `10` standings, e `2` novos decks externos foram promovidos com seguranca.**

- `MTGTop8` continua vivo em dry-run para `cEDH`
- `EDHTop16 -> TopDeck` continua parcialmente vivo, mas o scan-through evitou desperdiçar o alvo em standings sem decklist
- `meta_decks` agora tem `646` rows:
  - `mtgtop8=641`
  - `external=5`
- os `5` externos promovidos continuam todos em `format=cEDH`
- o consumo continua seguro:
  - `optimize/complete` so entra em `competitive_commander` para `Commander` com `bracket >= 3`
  - `generate` so entra em `competitive_commander` quando o prompt prova `cEDH/high power/bracket 3+/competitive commander`
  - `duel_commander` continua isolado de `competitive_commander`

## Resumo do pipeline

1. `bin/fetch_meta.dart` consome `MTGTop8` e grava direto em `meta_decks`
2. `bin/expand_external_commander_meta_candidates.dart` agora aceita:
   - `--target-valid=<n>`
   - `--max-standing=<n>`
   e continua tentando standings ate bater o alvo de decks validos ou esgotar o teto
3. `bin/import_external_commander_meta_candidates.dart --dry-run --validation-profile=topdeck_edhtop16_stage2` valida:
   - total de cartas
   - subformato `competitive_commander`
   - legalidade Commander
   - `unresolved_cards`
   - identidade de cor dos commanders
4. `bin/stage_external_commander_meta_candidates.dart --apply` persiste apenas em `external_commander_meta_candidates`
5. `bin/promote_external_commander_meta_candidates.dart --apply` sobe para `meta_decks` somente rows `staged`, `valid`, `100 cartas`, `source_url` unico e `fingerprint` unico
6. `optimize` e `generate` consomem `meta_decks` via:
   - `server/lib/meta/meta_deck_reference_support.dart`
   - `server/lib/ai/optimize_runtime_support.dart`
   - `server/routes/ai/generate/index.dart`

## Mudancas tecnicas aplicadas

### 1. Scan-through no expansor EDHTop16/TopDeck

Arquivos:

- `server/bin/expand_external_commander_meta_candidates.dart`

Mudanca:

- `--limit` passou a funcionar como alias de `--target-valid`
- novo `--max-standing` define quantos standings pedir ao GraphQL
- o loop agora continua escaneando standings ate:
  - coletar `N` decks expandidos validos, ou
  - esgotar os standings retornados
- o artefato agora registra:
  - `target_valid_count`
  - `max_standing_scanned`
  - `entries_available`
  - `attempted_count`
  - `goal_reached`
  - `stop_reason`

Leitura:

- isso fecha o defeito operacional confirmado na rodada anterior: perder o alvo de expansao quando parte do TopDeck devolve HTML sem decklist utilizavel

### 2. Gating compartilhado e testavel para `generate`

Arquivos:

- `server/lib/meta/meta_deck_format_support.dart`
- `server/routes/ai/generate/index.dart`

Mudanca:

- a decisao de escopo do prompt saiu da rota e virou helper compartilhado:
  - `resolveCommanderMetaScopeFromPromptText(...)`

Leitura:

- isso deixou o gating de `generate` testavel sem depender da rota inteira
- o contrato ficou explicito:
  - `duel commander` -> `duel_commander`
  - `cedh / competitive commander / high power / bracket 3-4` -> `competitive_commander`
  - prompt casual/amplo -> `null`

### 3. Testes focados de isolamento competitivo

Arquivos:

- `server/test/meta_deck_format_support_test.dart`
- `server/test/meta_deck_reference_support_test.dart`

Cobertura nova:

- prompt casual nao sobe `competitive_commander`
- prompt `duel commander` continua isolado
- referencia `competitive_commander` nao vaza para `duel_commander`
- preferencia externa competitiva continua funcionando quando o escopo certo e provado

## Comandos executados

```bash
cd server && dart format \
  lib/meta/meta_deck_format_support.dart \
  routes/ai/generate/index.dart \
  bin/expand_external_commander_meta_candidates.dart \
  test/meta_deck_format_support_test.dart \
  test/meta_deck_reference_support_test.dart

cd server && dart analyze \
  lib/meta/meta_deck_format_support.dart \
  routes/ai/generate/index.dart \
  bin/expand_external_commander_meta_candidates.dart \
  test/meta_deck_format_support_test.dart \
  test/meta_deck_reference_support_test.dart

cd server && dart test -r compact \
  test/meta_deck_format_support_test.dart \
  test/meta_deck_reference_support_test.dart \
  test/optimize_runtime_support_test.dart \
  test/external_commander_deck_expansion_support_test.dart \
  test/external_commander_meta_candidate_support_test.dart \
  test/external_commander_meta_promotion_support_test.dart

cd server && dart run bin/expand_external_commander_meta_candidates.dart \
  --source-url=https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57 \
  --target-valid=6 \
  --max-standing=24 \
  --output=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_scan_through_target6_max24_2026-04-27.json

cd server && dart run bin/import_external_commander_meta_candidates.dart \
  test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_scan_through_target6_max24_2026-04-27.json \
  --dry-run \
  --validation-profile=topdeck_edhtop16_stage2 \
  --validation-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_scan_through_target6_max24_2026-04-27.validation.json

cd server && python3 <inline filter> \
  # gera:
  # - topdeck_edhtop16_new_promotable_batch_2026-04-27.json
  # - topdeck_edhtop16_new_promotable_batch_2026-04-27.validation.json

cd server && dart run bin/stage_external_commander_meta_candidates.dart \
  --dry-run \
  --expansion-artifact=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_new_promotable_batch_2026-04-27.json \
  --validation-artifact=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_new_promotable_batch_2026-04-27.validation.json \
  --imported-by=meta_deck_intelligence_2026_04_27_scan_through \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_new_promotable_batch_stage_dry_run_2026-04-27.json

cd server && dart run bin/stage_external_commander_meta_candidates.dart \
  --apply \
  --expansion-artifact=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_new_promotable_batch_2026-04-27.json \
  --validation-artifact=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_new_promotable_batch_2026-04-27.validation.json \
  --imported-by=meta_deck_intelligence_2026_04_27_scan_through \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_new_promotable_batch_stage_apply_2026-04-27.json

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --source-url=https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57#standing-9 \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing9_dry_run_2026-04-27.json

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --apply \
  --source-url=https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57#standing-9 \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing9_apply_2026-04-27.json

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --source-url=https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57#standing-10 \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing10_dry_run_2026-04-27.json

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --apply \
  --source-url=https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57#standing-10 \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing10_apply_2026-04-27.json

cd server && dart run bin/fetch_meta.dart cEDH \
  --dry-run \
  --limit-events=1 \
  --limit-decks=2 \
  --delay-event-ms=0

cd server && dart test -r compact \
  test/meta_deck_format_support_test.dart \
  test/meta_deck_reference_support_test.dart \
  test/optimize_runtime_support_test.dart

cd server && dart run bin/meta_profile_report.dart \
  > test/artifacts/meta_deck_intelligence_2026-04-27/meta_profile_report_post_scan_through_2026-04-27.json

cd server && dart run bin/extract_meta_insights.dart --report-only \
  > test/artifacts/meta_deck_intelligence_2026-04-27/extract_meta_insights_report_only_post_scan_through_2026-04-27.json

cd server && python3 <inline db snapshot probe>
cd server && dart run <temporary in-package coverage probe> \
  test/artifacts/meta_deck_intelligence_2026-04-27/commander_color_identity_coverage_post_scan_through_2026-04-27.json
```

## Evidencia validada

### 1. `MTGTop8` continua vivo

Artefato:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/fetch_meta_cedh_dry_run_post_scan_through_2026-04-27.txt`

Fatos provados:

- `https://www.mtgtop8.com/format?f=cEDH` respondeu
- a pagina de formato retornou evento recente
- `event?e=83812` expôs `115` rows
- o parser continua lendo estruturas reais:
  - `Terra, Magical Adept`
  - `Kraum + Tymna`

### 2. O scan-through do externo funcionou

Artefatos:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_scan_through_target6_max24_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_scan_through_target6_max24_2026-04-27.validation.json`

Fatos provados:

- `entries_available=14`
- `attempted_count=10`
- `expanded_count=6`
- `rejected_count=4`
- `goal_reached=true`
- novos decks validos encontrados alem do lote anterior:
  - `standing-9` `Kefka, Court Mage // Kefka, Ruler of Ruin`
  - `standing-10` `Thrasios, Triton Hero + Yoshimaru, Ever Faithful`

Rejeicoes persistentes:

- `standing-2`
- `standing-3`
- `standing-6`
- `standing-7`

Motivo observado:

- `topdeck_deckobj_missing`

Leitura:

- o pipeline nao depende mais de os primeiros `N` standings serem todos bons
- o problema remanescente continua parecendo upstream/data-availability do `TopDeck`, nao falha local nova

### 3. Stage 2 ficou verde no lote ampliado e no recorte promovivel

Artefatos:

- `topdeck_edhtop16_expansion_scan_through_target6_max24_2026-04-27.validation.json`
- `topdeck_edhtop16_new_promotable_batch_2026-04-27.json`
- `topdeck_edhtop16_new_promotable_batch_2026-04-27.validation.json`

Fatos provados:

- `accepted=6`, `rejected=0` no lote ampliado
- recorte novo promovivel:
  - `standing-9`
  - `standing-10`
- ambos com:
  - `legal_status=legal`
  - `unresolved_cards=0`
  - `illegal_cards=0`

### 4. `stage/promote` apply ocorreu sem romper os guards

Artefatos:

- `topdeck_edhtop16_new_promotable_batch_stage_dry_run_2026-04-27.json`
- `topdeck_edhtop16_new_promotable_batch_stage_apply_2026-04-27.json`
- `promote_standing9_dry_run_2026-04-27.json`
- `promote_standing9_apply_2026-04-27.json`
- `promote_standing10_dry_run_2026-04-27.json`
- `promote_standing10_apply_2026-04-27.json`

Fatos provados:

- `standing-9` passou em `dry-run` e foi promovido
- `standing-10` passou em `dry-run` e foi promovido
- nenhum dos dois bateu em:
  - `source_url_already_present_in_meta_decks`
  - `deck_fingerprint_already_present_in_meta_decks`
  - `duplicate_deck_fingerprint_in_stage`

### 5. Consumo pos-promocao em `optimize/generate` continua seguro

Artefatos:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/optimize_generate_scope_tests_2026-04-27.txt`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/db_snapshot_post_scan_through_2026-04-27.json`

Fatos provados por codigo/teste:

- `generate`:
  - `high power / cEDH / bracket 3+` -> `competitive_commander`
  - `duel commander` -> `duel_commander`
  - prompt casual/amplo -> `null`
- `optimize/complete`:
  - `Commander + bracket >= 3` -> `competitive_commander`
  - `Commander + bracket <= 2` -> fora do bucket competitivo
  - formatos nao-Commander -> fora do bucket competitivo
- `meta_deck_reference_support` continua descartando `competitive_commander` quando o escopo pedido e `duel_commander`

Fatos provados por banco:

- apos a promocao, todos os externos em `meta_decks` continuam em `format=cEDH`
- `external / duel_commander = 0`
- `external / casual commander = not proven` como corpus separado; nao houve escrita fora de `cEDH`

## Frescor real da base

Artefato:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/db_snapshot_post_scan_through_2026-04-27.json`

| source | format | decks | min(created_at) | max(created_at) |
| --- | --- | ---: | --- | --- |
| `external` | `cEDH` | 5 | `2026-04-27 12:04:17+00` | `2026-04-27 19:50:11+00` |
| `mtgtop8` | `cEDH` | 214 | `2026-02-12 20:14:20+00` | `2026-04-23 20:02:52+00` |
| `mtgtop8` | `EDH` | 162 | `2025-11-22 14:14:20+00` | `2026-04-23 19:58:16+00` |

Estado de `external_commander_meta_candidates`:

| validation_status | legal_status | decks |
| --- | --- | ---: |
| `promoted` | `valid` | 5 |
| `staged` | `warning_pending` | 1 |

Leitura:

- a base externa deixou de ser lote de `3` rows e passou para `5`
- o candidato `Scion` continua corretamente fora da promocao

## Cobertura real por formato e identidade de cor

Artefatos:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/meta_profile_report_post_scan_through_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/extract_meta_insights_report_only_post_scan_through_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/commander_color_identity_coverage_post_scan_through_2026-04-27.json`

### Cobertura por source/subformat

| source | subformat | decks |
| --- | --- | ---: |
| `mtgtop8` | `competitive_commander` | 214 |
| `mtgtop8` | `duel_commander` | 162 |
| `external` | `competitive_commander` | 5 |

### Cobertura por formato em `meta_profile_report`

| format | deck_count |
| --- | ---: |
| `cEDH` | 219 |
| `EDH` | 162 |

### Cobertura por identidade dos commanders

| source | format | decks | resolved | unknown |
| --- | --- | ---: | ---: | ---: |
| `external` | `cEDH` | 5 | 5 | 0 |
| `mtgtop8` | `cEDH` | 214 | 211 | 3 |
| `mtgtop8` | `EDH` | 162 | 161 | 1 |

Top identities externas resolvidas:

| source | format | commander_color_identity | decks |
| --- | --- | --- | ---: |
| `external` | `cEDH` | `BRU` | 3 |
| `external` | `cEDH` | `BRUW` | 1 |
| `external` | `cEDH` | `GUW` | 1 |

Unknowns restantes:

| source | format | commander_label | decks |
| --- | --- | --- | ---: |
| `mtgtop8` | `cEDH` | `Prismari, the Inspiration` | 2 |
| `mtgtop8` | `EDH` | `Witherbloom, the Balancer` | 1 |
| `mtgtop8` | `cEDH` | `Zhulodok, Void Gorger` | 1 |

Leitura:

- a cobertura `external cEDH` ficou `5/5` resolvida
- `duel_commander` continua vindo so de `MTGTop8`
- a malha de cor residual esta pequena e localizada

## Gaps observados

1. `TopDeck` continua devolvendo paginas sem decklist utilizavel em parte do evento
   - `standing-2`, `3`, `6`, `7`
2. `Scion of the Ur-Dragon` segue bloqueado por `unresolved_cards`
   - status correto: `warning_pending`
3. ainda existem poucos commanders residuais sem identidade resolvida
   - `Prismari, the Inspiration`
   - `Witherbloom, the Balancer`
   - `Zhulodok, Void Gorger`

## Interpretacao estrategica

**Web research nao foi usada nesta rodada.** A interpretacao abaixo e derivada apenas das decklists, do subformato persistido e do que o pipeline provou localmente.

### `Malcolm + Vial Smasher`

- shell Grixis turbo/combo
- sinais fortes:
  - fast mana muito denso
  - wheels/loot
  - `Underworld Breach`
  - `Thassa's Oracle`
  - interacao barata

Uso seguro:

- evidencia forte para `competitive_commander`
- nao deve contaminar Commander casual ou `duel_commander`

### `Kraum + Tymna`

- Blue Farm / midrange-combo
- sinais fortes:
  - parceiros com card advantage
  - free interaction
  - `Oracle / Consultation`
  - mana base de quatro cores muito eficiente

Uso seguro:

- referencia de alto valor para `optimize` em `Commander bracket >= 3`
- nao deve entrar em prompt casual sem gatilho explicito

### `Kefka, Court Mage // Kefka, Ruler of Ruin`

- shell Grixis combo/control com stack wars curtas
- sinais fortes:
  - `Oracle / Tainted Pact / Breach`
  - fast mana alto
  - interacao instant-speed barata
  - baixo numero de terrenos

Uso seguro:

- bom reforco para `competitive_commander`
- **nao comprovado** como referencia para Commander casual

### `Thrasios + Yoshimaru`

- shell Bant value-combo baseada em mana engine
- sinais fortes:
  - pacote de dorks/tutors
  - `Training Grounds`, `Cryptolith Rite`, `Gaea's Cradle`
  - linhas de untap/combo com `Palinchron`, `Peregrine Drake`, `Derevi`
  - interacao branca/azul leve para abrir janela

Uso seguro:

- bom sinal para `generate` quando o prompt pedir cEDH/high power de valor-combo
- **nao comprovado** para `duel_commander`

### O que absorver em `optimize` e `generate`

1. manter prioridade alta para:
   - fast mana
   - free interaction
   - pacotes compactos `Oracle / Consultation / Tainted Pact`
   - `Underworld Breach` onde a shell suporta
   - engines de mana/untap quando o shell indica `Thrasios`
2. tratar `Malcolm/Vial`, `Kraum/Tymna`, `Norman`, `Kefka`, `Thrasios/Yoshimaru` como **competitive-only evidence**
3. continuar expondo provenance (`source_chain`), nunca como instrucao cega

## Menores proximas acoes tecnicas

1. manter o scan-through como padrao do expansor e, se necessario, adicionar `--resume-from-standing` apenas se outro evento provar necessidade real
2. resolver os poucos commanders residuais sem identidade (`Prismari`, `Witherbloom`, `Zhulodok`) no catalogo local
3. seguir promovendo externo apenas por recorte filtrado com `stage2 -> staging -> promotion dry-run -> apply`

## Artefatos principais

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/fetch_meta_cedh_dry_run_post_scan_through_2026-04-27.txt`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/optimize_generate_scope_tests_2026-04-27.txt`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_scan_through_target6_max24_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_scan_through_target6_max24_2026-04-27.validation.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_new_promotable_batch_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_new_promotable_batch_2026-04-27.validation.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_new_promotable_batch_stage_dry_run_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_new_promotable_batch_stage_apply_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing9_dry_run_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing9_apply_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing10_dry_run_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/promote_standing10_apply_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/meta_profile_report_post_scan_through_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/extract_meta_insights_report_only_post_scan_through_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/db_snapshot_post_scan_through_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/commander_color_identity_coverage_post_scan_through_2026-04-27.json`
