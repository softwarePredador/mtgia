# Relatorio Meta Deck Intelligence - 2026-04-27

## Escopo

- repositorio: `softwarePredador/mtgia`
- foco:
  - provar valor real dos externos ja promovidos em `optimize/generate`
  - generalizar o scan-through para outro evento publico `EDHTop16`
  - medir cobertura final apos nova promocao pequena
- superfice auditada:
  - `server/bin`
  - `server/lib/ai`
  - `server/lib/meta`
  - `server/doc`
  - `server/test/artifacts`

## Veredito

**O pipeline externo continua vivo, ficou mais provavel de ser reaproveitado em rodadas futuras e agora tem prova operacional real de consumo.**

- os `5` externos promovidos antes desta rodada entravam como referencia `rank 1` em:
  - `optimize` competitivo (`Commander bracket >= 3`)
  - `generate` competitivo (`cEDH/high power/bracket 3+/competitive commander`)
- esses mesmos externos **nao** vazavam para:
  - `optimize` casual (`bracket <= 2`)
  - `generate` casual
  - `generate` em `duel commander`
- a validacao live encontrou um defeito real no caminho keyword-only de `generate`:
  - `queryMetaDeckReferenceCandidates(...)` passava placeholders extras para o driver Postgres
  - isso foi corrigido com um builder de query que so envia parametros realmente usados
- o scan-through foi generalizado com prova em outro evento publico:
  - `jokers-are-wild-monthly-1k-hosted-by-trenton`
  - `attempted_count=5`
  - `expanded_count=3`
  - `rejected_count=2`
  - `goal_reached=true`
- o lote pequeno novo foi promovido com guard rails verdes:
  - `Kinnan, Bonder Prodigy`
  - `Rograkh, Son of Rohgahh + Silas Renn, Seeker Adept`
- estado final da base:
  - `meta_decks=648`
  - `mtgtop8=641`
  - `external=7`
  - `external` continua inteiro em `format=cEDH`

## Resumo do pipeline real

1. `bin/fetch_meta.dart` consome `MTGTop8` e grava direto em `meta_decks`
2. `bin/expand_external_commander_meta_candidates.dart` faz:
   - `EDHTop16 tournament page`
   - `EDHTop16 GraphQL entries(maxStanding: N)`
   - `TopDeck deck page`
   - parse de `deckObj/copyDecklist`
   - artefato dry-run com `candidates/results`
3. `bin/import_external_commander_meta_candidates.dart --dry-run --validation-profile=topdeck_edhtop16_stage2` valida:
   - total de cartas
   - `competitive_commander`
   - legalidade Commander
   - `unresolved_cards`
   - identidade dos commanders
4. `bin/stage_external_commander_meta_candidates.dart --apply` persiste apenas em `external_commander_meta_candidates`
5. `bin/promote_external_commander_meta_candidates.dart --apply` sobe para `meta_decks` somente rows:
   - `staged`
   - `valid`
   - `100 cartas`
   - `source_url` unico
   - `fingerprint` unico
6. `optimize` consome `meta_decks` por:
   - `server/lib/ai/optimize_runtime_support.dart`
   - `server/lib/meta/meta_deck_reference_support.dart`
7. `generate` consome `meta_decks` por:
   - `server/routes/ai/generate/index.dart`
   - `server/lib/meta/meta_deck_format_support.dart`
   - `server/lib/meta/meta_deck_reference_support.dart`

## Mudancas tecnicas aplicadas nesta rodada

### 1. Correcao real no caminho keyword-only de `generate`

Arquivos:

- `server/lib/meta/meta_deck_reference_support.dart`
- `server/test/meta_deck_reference_support_test.dart`

Mudanca:

- novo helper:
  - `buildMetaDeckReferenceQueryParts(...)`
- `queryMetaDeckReferenceCandidates(...)` passou a enviar ao Postgres apenas os placeholders realmente usados na SQL

Defeito confirmado:

- antes do ajuste, a prova live de `generate` competitivo quebrava com:
  - `Contains superfluous variables: commander_names, commander_like_patterns`
- isso afetava justamente o caminho keyword-only da rota `generate`, que nao envia `commanderNames`

Resultado:

- o bug saiu do modo `not proven` e foi corrigido no ponto minimo necessario
- teste novo cobre o contrato:
  - lookup keyword-only nao pode enviar placeholders de commander

### 2. Probe vivo de consumo de referencias

Arquivo novo:

- `server/bin/meta_reference_probe.dart`

Uso:

- conecta no banco
- le os externos promovidos
- executa probes equivalentes aos helpers reais de:
  - `optimize`
  - `generate`
- grava:
  - se a referencia externa alvo entrou
  - em qual rank ela entrou
  - `selection_reason`
  - `source_breakdown`
  - `priority_cards`
  - `references`

Leitura:

- isso evitou inferencia manual por SQL e mostrou o comportamento real do runtime

### 3. Report deterministico de identidade de cor dos commanders

Arquivo novo:

- `server/bin/meta_commander_color_identity_report.dart`

Uso:

- mede cobertura por `source/format`
- resolve identidade com a heuristica real do repositiorio:
  - `color_identity`
  - `colors`
  - `mana_cost`
  - `oracle_text`
- preserva, por nome, a melhor identidade encontrada entre printings duplicados

Leitura:

- isso substituiu um probe SQL mais fragil, que estava degradando a cobertura por escolher printings pobres em metadados

### 4. Generalizacao comprovada do scan-through

Arquivo reaproveitado:

- `server/bin/expand_external_commander_meta_candidates.dart`

Prova nova:

- o scan-through nao ficou preso ao evento `cedh-arcanum-sanctorum-57`
- funcionou tambem em:
  - `jokers-are-wild-monthly-1k-hosted-by-trenton`

## Comandos executados

```bash
cd server && dart format \
  lib/meta/meta_deck_reference_support.dart \
  test/meta_deck_reference_support_test.dart \
  bin/meta_reference_probe.dart \
  bin/meta_commander_color_identity_report.dart

cd server && dart analyze \
  lib/meta/meta_deck_reference_support.dart \
  test/meta_deck_reference_support_test.dart \
  bin/meta_reference_probe.dart \
  bin/meta_commander_color_identity_report.dart

cd server && dart test -r compact \
  test/meta_deck_reference_support_test.dart \
  test/meta_deck_format_support_test.dart \
  test/optimize_runtime_support_test.dart \
  test/external_commander_deck_expansion_support_test.dart \
  test/external_commander_meta_candidate_support_test.dart \
  test/external_commander_meta_promotion_support_test.dart \
  | tee test/artifacts/meta_deck_intelligence_2026-04-27/meta_pipeline_focused_tests_post_jokers_2026-04-27.txt

cd server && dart run bin/meta_reference_probe.dart \
  --output=test/artifacts/meta_deck_intelligence_2026-04-27/meta_reference_probe_2026-04-27.json

cd server && dart run bin/expand_external_commander_meta_candidates.dart \
  --source-url=https://edhtop16.com/tournament/jokers-are-wild-monthly-1k-hosted-by-trenton \
  --target-valid=3 \
  --max-standing=12 \
  --output=test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_expansion_target3_max12_2026-04-27.json

cd server && dart run bin/import_external_commander_meta_candidates.dart \
  test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_expansion_target3_max12_2026-04-27.json \
  --dry-run \
  --validation-profile=topdeck_edhtop16_stage2 \
  --validation-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_expansion_target3_max12_2026-04-27.validation.json

cd server && python3 <inline filter> \
  # gera:
  # - jokers_edhtop16_promotable_batch_2026-04-27.json
  # - jokers_edhtop16_promotable_batch_2026-04-27.validation.json

cd server && dart run bin/stage_external_commander_meta_candidates.dart \
  --dry-run \
  --expansion-artifact=test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_promotable_batch_2026-04-27.json \
  --validation-artifact=test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_promotable_batch_2026-04-27.validation.json \
  --imported-by=meta_deck_intelligence_2026_04_27_jokers_scan_through \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_promotable_batch_stage_dry_run_2026-04-27.json

cd server && dart run bin/stage_external_commander_meta_candidates.dart \
  --apply \
  --expansion-artifact=test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_promotable_batch_2026-04-27.json \
  --validation-artifact=test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_promotable_batch_2026-04-27.validation.json \
  --imported-by=meta_deck_intelligence_2026_04_27_jokers_scan_through \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_promotable_batch_stage_apply_2026-04-27.json

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --source-url=https://edhtop16.com/tournament/jokers-are-wild-monthly-1k-hosted-by-trenton#standing-2 \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/jokers_promote_standing2_dry_run_2026-04-27.json

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --apply \
  --source-url=https://edhtop16.com/tournament/jokers-are-wild-monthly-1k-hosted-by-trenton#standing-2 \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/jokers_promote_standing2_apply_2026-04-27.json

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --source-url=https://edhtop16.com/tournament/jokers-are-wild-monthly-1k-hosted-by-trenton#standing-3 \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/jokers_promote_standing3_dry_run_2026-04-27.json

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --apply \
  --source-url=https://edhtop16.com/tournament/jokers-are-wild-monthly-1k-hosted-by-trenton#standing-3 \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/jokers_promote_standing3_apply_2026-04-27.json

cd server && dart run bin/meta_profile_report.dart \
  > test/artifacts/meta_deck_intelligence_2026-04-27/meta_profile_report_post_jokers_2026-04-27.json

cd server && dart run bin/meta_reference_probe.dart \
  --output=test/artifacts/meta_deck_intelligence_2026-04-27/meta_reference_probe_post_jokers_2026-04-27.json

cd server && dart run bin/meta_commander_color_identity_report.dart \
  --output=test/artifacts/meta_deck_intelligence_2026-04-27/commander_color_identity_coverage_post_jokers_2026-04-27.json

cd server && dart run bin/fetch_meta.dart cEDH \
  --dry-run \
  --limit-events=1 \
  --limit-decks=2 \
  --delay-event-ms=0 \
  > test/artifacts/meta_deck_intelligence_2026-04-27/fetch_meta_cedh_dry_run_post_jokers_2026-04-27.txt
```

## Evidencia validada

### 1. `MTGTop8` continua vivo

Artefato:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/fetch_meta_cedh_dry_run_post_jokers_2026-04-27.txt`

Fatos provados:

- `https://www.mtgtop8.com/format?f=cEDH` respondeu
- a pagina de formato retornou evento recente
- a pagina de evento ainda expoe estruturas parseaveis de deck

### 2. Os 5 externos promovidos ja viraram evidencia real para `optimize/generate`

Artefato principal:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/meta_reference_probe_2026-04-27.json`

Fatos provados:

- `optimize_competitive_external_match_count=5`
- `optimize_casual_guard_ok_count=5`
- `generate_competitive_external_match_count=5`
- `generate_casual_guard_ok_count=5`
- `generate_duel_guard_ok_count=5`

Leitura:

- os `5` externos promovidos entraram como `matched_external_reference_rank=1`
- o ganho nao foi teorico: o runtime passou a puxar prioridade real de cartas e shell competitivo

Cartas/estrategias que subiram no probe vivo:

| shell | uso provado | sinais fortes |
| --- | --- | --- |
| `Norman Osborn // Green Goblin` | `optimize`/`generate` competitivo | `Ad Nauseam`, `Beseech the Mirror`, `Birgi`, `Brain Freeze`, `Cabal Ritual` |
| `Malcolm + Vial Smasher` | `optimize`/`generate` competitivo | `Chrome Mox`, `Dark Ritual`, `Demonic Consultation`, `Demonic Tutor`, `Fierce Guardianship` |
| `Kraum + Tymna` | `optimize`/`generate` competitivo | `Borne Upon a Wind`, `Brain Freeze`, `Chain of Vapor`, `Chrome Mox`, `City of Traitors` |
| `Kefka` | `optimize`/`generate` competitivo | `An Offer You Can't Refuse`, `Badlands`, `Blood Crypt`, `Borne Upon a Wind`, `Brain Freeze` |
| `Thrasios + Yoshimaru` | `optimize`/`generate` competitivo | `Avacyn's Pilgrim`, `Birds of Paradise`, `Chord of Calling`, `Biomancer's Familiar`, `Breeding Pool` |

### 3. O defeito real de `generate` foi confirmado e corrigido

Fato provado:

- o primeiro run live do probe falhou no caminho keyword-only com:
  - `Contains superfluous variables: commander_names, commander_like_patterns`

Raiz:

- `queryMetaDeckReferenceCandidates(...)` sempre montava todos os placeholders, mesmo quando a query era montada so por `keyword_patterns`

Status:

- corrigido no menor ponto possivel
- cobertura nova em `test/meta_deck_reference_support_test.dart`

### 4. O scan-through generalizado funcionou em outro evento publico

Evento:

- `https://edhtop16.com/tournament/jokers-are-wild-monthly-1k-hosted-by-trenton`

Artefatos:

- `jokers_edhtop16_expansion_target3_max12_2026-04-27.json`
- `jokers_edhtop16_expansion_target3_max12_2026-04-27.validation.json`

Fatos provados:

- `entries_available=10`
- `attempted_count=5`
- `expanded_count=3`
- `rejected_count=2`
- `goal_reached=true`
- rejeicoes observadas:
  - `standing-1` -> `topdeck_deckobj_missing`
  - `standing-4` -> `topdeck_deckobj_missing`

Leitura:

- o scan-through nao depende mais de os primeiros standings serem bons
- o comportamento residual continua parecendo upstream/data-availability do `TopDeck`, nao regressao local

### 5. O lote pequeno novo ficou verde em stage 2

Fatos provados:

- aceitos:
  - `Kinnan, Bonder Prodigy`
  - `Rograkh, Son of Rohgahh + Silas Renn, Seeker Adept`
- rejeitado:
  - `Vivi Ornitier`

Detalhe do rejeitado:

- `card_count_below_stage2_minimum`
- `unresolved_cards=2`
- `legal_status=not_proven`

Leitura:

- o pipeline rejeitou corretamente o caso incompleto
- o lote pequeno promovido ficou restrito a `legal + unresolved=0`

### 6. `stage/promote` apply ocorreu sem romper os guards

Artefatos:

- `jokers_edhtop16_promotable_batch_stage_dry_run_2026-04-27.json`
- `jokers_edhtop16_promotable_batch_stage_apply_2026-04-27.json`
- `jokers_promote_standing2_dry_run_2026-04-27.json`
- `jokers_promote_standing2_apply_2026-04-27.json`
- `jokers_promote_standing3_dry_run_2026-04-27.json`
- `jokers_promote_standing3_apply_2026-04-27.json`

Fatos provados:

- `Kinnan` passou em `dry-run` e foi promovido
- `Rograkh + Silas` passou em `dry-run` e foi promovido
- ambos terminaram em:
  - `validation_status=promoted`
  - `legal_status=valid`

### 7. Os dois novos externos tambem entraram no consumo competitivo

Artefato:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/meta_reference_probe_post_jokers_2026-04-27.json`

Fatos provados:

- `promoted_external_count=7`
- `optimize_competitive_external_match_count=7`
- `generate_competitive_external_match_count=7`
- guards continuam `7/7` verdes para casual/duel

Novos sinais absorviveis:

- `Kinnan, Bonder Prodigy`
  - `Ancient Tomb`
  - `Arcane Signet`
  - `Basalt Monolith`
  - `Birds of Paradise`
  - `Boseiju, Who Endures`
  - `Chord of Calling`
  - `Chrome Mox`
- `Rograkh + Silas`
  - `Ad Nauseam`
  - `Ancient Tomb`
  - `Arcane Signet`
  - `Arid Mesa`
  - `Badlands`
  - `Beseech the Mirror`
  - `Blood Crypt`
  - `Brain Freeze`

## Frescor real da base

Artefato:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/db_snapshot_post_jokers_2026-04-27.json`

| source | format | decks | min(created_at) | max(created_at) |
| --- | --- | ---: | --- | --- |
| `external` | `cEDH` | `7` | `2026-04-27T12:04:17+00:00` | `2026-04-27T20:12:47+00:00` |
| `mtgtop8` | `cEDH` | `214` | `2026-02-12T20:14:20+00:00` | `2026-04-23T20:02:52+00:00` |
| `mtgtop8` | `EDH` | `162` | `2025-11-22T14:14:20+00:00` | `2026-04-23T19:58:16+00:00` |

Estado de `external_commander_meta_candidates`:

| validation_status | legal_status | decks |
| --- | --- | ---: |
| `promoted` | `valid` | `7` |
| `staged` | `warning_pending` | `1` |

Leitura:

- a base externa saiu de `5` para `7`
- o unico residual estagiado continua sendo `Scion of the Ur-Dragon`

## Cobertura real por formato e identidade de cor

Artefatos:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/meta_profile_report_post_jokers_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/commander_color_identity_coverage_post_jokers_2026-04-27.json`

### Cobertura por source/subformat

| source | subformat | decks |
| --- | --- | ---: |
| `mtgtop8` | `competitive_commander` | `214` |
| `mtgtop8` | `duel_commander` | `162` |
| `external` | `competitive_commander` | `7` |

### Cobertura por formato em `meta_profile_report`

| format | deck_count |
| --- | ---: |
| `cEDH` | `221` |
| `EDH` | `162` |

### Cobertura por identidade dos commanders

| source | format | decks | resolved | unknown |
| --- | --- | ---: | ---: | ---: |
| `external` | `cEDH` | `7` | `7` | `0` |
| `mtgtop8` | `cEDH` | `214` | `187` | `27` |
| `mtgtop8` | `EDH` | `162` | `155` | `7` |

### Top identities externas resolvidas

| source | format | commander_color_identity | decks |
| --- | --- | --- | ---: |
| `external` | `cEDH` | `BRU` | `4` |
| `external` | `cEDH` | `BRUW` | `1` |
| `external` | `cEDH` | `GU` | `1` |
| `external` | `cEDH` | `GUW` | `1` |

Leitura:

- a cobertura externa continua totalmente resolvida
- `duel_commander` continua vindo so de `MTGTop8`
- a cobertura residual ruim ficou concentrada no catalogo legado de commanders do `MTGTop8`, nao nos externos promovidos

## Gaps observados

1. `TopDeck` continua devolvendo paginas sem `deckObj` em parte dos standings
   - comprovado em `cedh-arcanum-sanctorum-57`
   - comprovado de novo em `jokers-are-wild-monthly-1k-hosted-by-trenton`
2. `Scion of the Ur-Dragon` continua corretamente bloqueado
   - `validation_status=staged`
   - `legal_status=warning_pending`
3. ainda existe cobertura residual fraca de identidade no corpus legado `MTGTop8`
   - `cEDH`: `27` shells ainda sem identidade resolvida
   - `EDH`: `7` shells ainda sem identidade resolvida
4. `Vivi Ornitier` do evento novo ficou fora por deck incompleto
   - rejeicao correta

## Interpretacao estrategica

**Web research nao foi usada nesta rodada.** A interpretacao abaixo vem do que o pipeline provou localmente nas decklists e nos probes vivos.

### `Norman Osborn // Green Goblin`

- turbo combo de baixo land count
- sinais fortes:
  - `Ad Nauseam`
  - `Beseech the Mirror`
  - `Birgi`
  - `Brain Freeze`
  - `Cabal Ritual`

Uso seguro:

- evidencia competitiva pura
- **nao comprovado** para Commander casual

### `Malcolm + Vial Smasher`

- shell Grixis turbo/combo
- sinais fortes:
  - fast mana
  - rituals
  - `Demonic Consultation`
  - `Demonic Tutor`
  - `Fierce Guardianship`

Uso seguro:

- alto valor para `competitive_commander`
- nao deve contaminar `duel_commander`

### `Kraum + Tymna`

- shell Blue Farm / midrange-combo
- sinais fortes:
  - `Borne Upon a Wind`
  - `Brain Freeze`
  - `Chain of Vapor`
  - `Chrome Mox`
  - `City of Traitors`

Uso seguro:

- bom reforco para `optimize` em `bracket >= 3`
- prompt casual continua fora do bucket competitivo

### `Kefka`

- Grixis combo/control curto de stack
- sinais fortes:
  - `An Offer You Can't Refuse`
  - `Borne Upon a Wind`
  - `Brain Freeze`
  - base de mana agressiva

Uso seguro:

- bom sinal de `competitive_commander`
- **nao comprovado** para casual

### `Thrasios + Yoshimaru`

- Bant value-combo com mana engine e dorks
- sinais fortes:
  - `Avacyn's Pilgrim`
  - `Birds of Paradise`
  - `Chord of Calling`
  - `Biomancer's Familiar`
  - `Breeding Pool`

Uso seguro:

- bom sinal para `generate` cEDH de valor-combo
- **nao comprovado** para `duel_commander`

### `Kinnan`

- UG mana-engine/combo
- sinais fortes:
  - `Basalt Monolith`
  - `Birds of Paradise`
  - `Chord of Calling`
  - `Chrome Mox`
  - `Boseiju`

Uso seguro:

- referencia muito util para `generate`/`optimize` quando o prompt pedir ramp-combo competitivo
- nao deve subir em Commander casual sem gatilho explicito

### `Rograkh + Silas`

- Grixis turbo-breach/oracle
- sinais fortes:
  - `Ad Nauseam`
  - `Beseech the Mirror`
  - `Brain Freeze`
  - `Underworld Breach`
  - fast mana pesado

Uso seguro:

- excelente evidencia para shells `BRU` competitivos
- **nao comprovado** para `duel_commander`

## Menores proximas acoes tecnicas

1. manter `meta_reference_probe.dart` como cheque padrao sempre que houver nova promocao externa
2. manter `stage2 -> lote pequeno filtrado -> promote dry-run -> promote apply` como fluxo obrigatorio
3. usar `meta_commander_color_identity_report.dart` para medir cobertura real, sem voltar a probes SQL frageis
4. reduzir o residual de identidade do corpus legado `MTGTop8` com backfill catalogado de commanders faltantes
5. continuar tratando `TopDeck deckobj missing` como gap upstream e nao como motivo para abandonar o scan-through

## Artefatos principais desta rodada

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/meta_reference_probe_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/meta_reference_probe_post_jokers_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/meta_pipeline_focused_tests_post_jokers_2026-04-27.txt`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_expansion_target3_max12_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_expansion_target3_max12_2026-04-27.validation.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_promotable_batch_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_promotable_batch_2026-04-27.validation.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_promotable_batch_stage_dry_run_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_promotable_batch_stage_apply_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/jokers_promote_standing2_dry_run_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/jokers_promote_standing2_apply_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/jokers_promote_standing3_dry_run_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/jokers_promote_standing3_apply_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/meta_profile_report_post_jokers_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/db_snapshot_post_jokers_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/commander_color_identity_coverage_post_jokers_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/fetch_meta_cedh_dry_run_post_jokers_2026-04-27.txt`
