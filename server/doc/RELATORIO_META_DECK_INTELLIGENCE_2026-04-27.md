# Relatorio Meta Deck Intelligence - 2026-04-27

## Escopo

- repositorio: `softwarePredador/mtgia`
- foco desta rodada:
  - transformar o fluxo externo auditado em rotina operacional unica e segura
  - provar `dry-run` por padrao + `--apply` explicito
  - medir frescor e cobertura real depois da nova promocao
  - revalidar `meta/optimize/generate` no server
- superficie auditada:
  - `server/bin`
  - `server/lib/meta`
  - `server/lib/ai`
  - `server/routes/ai`
  - `server/doc`
  - `server/test/artifacts`

## Veredito

**O fluxo externo agora tem um runner operacional unico, com gate estrito antes de qualquer escrita, e a prova live terminou verde.**

- runner novo:
  - `server/bin/run_external_commander_meta_pipeline.dart`
- comportamento provado:
  - `dry-run` por padrao
  - `--source-url`, `--target-valid` e `--max-standing` obrigatorios
  - artifacts separados por etapa
  - `stage apply` e `promote apply` so com `--apply`
  - filtro obrigatorio antes do apply:
    - `subformat=competitive_commander`
    - `card_count=100`
    - `legal_status=legal`
    - `unresolved_cards=0`
    - `illegal_cards=0`
- prova live no evento:
  - `https://edhtop16.com/tournament/jokers-are-wild-monthly-1k-hosted-by-trenton`
  - `target_valid=5`
  - `max_standing=18`
  - `expanded_count=5`
  - `validation_accepted_count=4`
  - `strict_gate_eligible_count=4`
  - `promote_dry_run_promotable_count=2`
  - `promote_apply_promoted_count=2`
- decks realmente novos promovidos nesta rodada:
  - `Ob Nixilis, Captive Kingpin`
  - `Sisay, Weatherlight Captain`
- estado final da base depois do apply:
  - `meta_decks=650`
  - `mtgtop8=641`
  - `external=9`
  - `cEDH=223`
  - `EDH=162`

## Resumo do pipeline real

1. `bin/fetch_meta.dart`
   - consome `MTGTop8`
   - continua sendo a trilha principal para `meta_decks`
2. `bin/run_external_commander_meta_pipeline.dart`
   - encapsula `EDHTop16 -> TopDeck -> stage2 validation -> strict gate -> stage -> promote`
   - gera artifacts `01..08`
3. `bin/expand_external_commander_meta_candidates.dart`
   - agora reutiliza helper compartilhado de expansao
4. `bin/stage_external_commander_meta_candidates.dart`
   - continua util para debug de etapa
   - sozinho ainda aceita `warning_pending`
5. `bin/promote_external_commander_meta_candidates.dart`
   - continua aplicando duplicidade, allowlist e `staging_audit`
6. `optimize`
   - consome `meta_decks` via `server/lib/ai/optimize_runtime_support.dart`
   - referencia competitiva continua limitada a `competitive_commander`
7. `generate`
   - consome `meta_decks` via `server/routes/ai/generate/index.dart`
   - continua separado de Commander casual e `duel_commander`

## Mudancas tecnicas aplicadas

### 1. Runner operacional unico

Arquivos:

- `server/bin/run_external_commander_meta_pipeline.dart`
- `server/lib/meta/external_commander_meta_operational_runner_support.dart`

O runner agora faz, em ordem:

1. expansao dry-run
2. import validation stage 2
3. strict gate para artifacts filtrados
4. stage dry-run
5. promote dry-run
6. stage apply (`--apply`)
7. promote apply (`--apply`)
8. summary final

O filtro estrito removeu o passo manual anterior de `python inline filter`.

### 2. Reuso operacional do expansor

Arquivo:

- `server/lib/meta/external_commander_deck_expansion_support.dart`

Mudanca:

- helpers compartilhados agora fazem:
  - fetch GraphQL do `EDHTop16`
  - expansao de entry para `TopDeck deck page`
  - montagem do artifact padrao do expansor

Leitura:

- o bin antigo de expansao continua existindo
- o runner unico e o bin de expansao passaram a usar a mesma base

### 3. Reuso operacional do promote

Arquivo:

- `server/lib/meta/external_commander_meta_promotion_support.dart`

Mudanca:

- helpers compartilhados agora centralizam:
  - report de promote
  - leitura de `source_url` ja presente em `meta_decks`
  - leitura de fingerprints ja presentes
  - persistencia do promote aceito

Leitura:

- `bin/promote_external_commander_meta_candidates.dart` deixou de duplicar esse SQL
- o report agora explicita tambem:
  - `requires_unresolved_cards_zero`
  - `requires_illegal_cards_zero`

## Comandos executados

```bash
cd server && dart format \
  lib/meta/external_commander_deck_expansion_support.dart \
  lib/meta/external_commander_meta_promotion_support.dart \
  lib/meta/external_commander_meta_operational_runner_support.dart \
  bin/expand_external_commander_meta_candidates.dart \
  bin/promote_external_commander_meta_candidates.dart \
  bin/run_external_commander_meta_pipeline.dart \
  test/external_commander_deck_expansion_support_test.dart \
  test/external_commander_meta_promotion_support_test.dart \
  test/external_commander_meta_operational_runner_support_test.dart

cd server && dart analyze \
  lib/meta/external_commander_deck_expansion_support.dart \
  lib/meta/external_commander_meta_promotion_support.dart \
  lib/meta/external_commander_meta_operational_runner_support.dart \
  bin/expand_external_commander_meta_candidates.dart \
  bin/promote_external_commander_meta_candidates.dart \
  bin/run_external_commander_meta_pipeline.dart \
  test/external_commander_deck_expansion_support_test.dart \
  test/external_commander_meta_promotion_support_test.dart \
  test/external_commander_meta_operational_runner_support_test.dart

cd server && dart test -r compact \
  test/external_commander_deck_expansion_support_test.dart \
  test/external_commander_meta_promotion_support_test.dart \
  test/external_commander_meta_operational_runner_support_test.dart

cd server && dart run bin/run_external_commander_meta_pipeline.dart \
  --source-url=https://edhtop16.com/tournament/jokers-are-wild-monthly-1k-hosted-by-trenton \
  --target-valid=5 \
  --max-standing=18 \
  --output-dir=test/artifacts/meta_deck_intelligence_2026-04-27/runner_probe_jokers_target5_max18

cd server && dart run bin/run_external_commander_meta_pipeline.dart \
  --apply \
  --source-url=https://edhtop16.com/tournament/jokers-are-wild-monthly-1k-hosted-by-trenton \
  --target-valid=5 \
  --max-standing=18 \
  --output-dir=test/artifacts/meta_deck_intelligence_2026-04-27/operational_runner_jokers_target5_max18_apply

cd server && dart analyze lib/meta lib/ai routes/ai bin test \
  | tee test/artifacts/meta_deck_intelligence_2026-04-27/server_dart_analyze_meta_ai_routes_bin_test_2026-04-27.txt

cd server && dart test -r compact \
  test/external_commander_deck_expansion_support_test.dart \
  test/external_commander_meta_candidate_support_test.dart \
  test/external_commander_meta_import_support_test.dart \
  test/external_commander_meta_staging_support_test.dart \
  test/external_commander_meta_promotion_support_test.dart \
  test/external_commander_meta_operational_runner_support_test.dart \
  test/meta_deck_analytics_support_test.dart \
  test/meta_deck_card_list_support_test.dart \
  test/meta_deck_commander_shell_support_test.dart \
  test/meta_deck_format_support_test.dart \
  test/meta_deck_reference_support_test.dart \
  test/optimize_runtime_support_test.dart \
  test/optimize_complete_support_test.dart \
  test/optimize_learning_pipeline_test.dart \
  test/optimize_payload_parser_test.dart \
  test/ai_optimize_flow_test.dart \
  test/ai_optimize_telemetry_contract_test.dart \
  test/generated_deck_validation_service_test.dart \
  test/ai_generate_create_optimize_flow_test.dart \
  | tee test/artifacts/meta_deck_intelligence_2026-04-27/server_meta_optimize_generate_regression_2026-04-27.txt

cd server && dart run bin/meta_report.dart \
  > test/artifacts/meta_deck_intelligence_2026-04-27/meta_report_post_operational_runner_2026-04-27.json

cd server && dart run bin/meta_profile_report.dart \
  > test/artifacts/meta_deck_intelligence_2026-04-27/meta_profile_report_post_operational_runner_2026-04-27.json

cd server && dart run bin/meta_commander_color_identity_report.dart \
  --output=test/artifacts/meta_deck_intelligence_2026-04-27/commander_color_identity_coverage_post_operational_runner_2026-04-27.json

cd server && dart run bin/fetch_meta.dart cEDH \
  --dry-run \
  --limit-events=1 \
  --limit-decks=2 \
  --delay-event-ms=0 \
  > test/artifacts/meta_deck_intelligence_2026-04-27/fetch_meta_cedh_dry_run_post_operational_runner_2026-04-27.txt
```

## Evidencia validada

### 1. `MTGTop8` continua vivo

Artefato:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/fetch_meta_cedh_dry_run_post_operational_runner_2026-04-27.txt`

Fatos provados:

- `https://www.mtgtop8.com/format?f=cEDH` respondeu
- a pagina de formato retornou `1` evento recente
- a pagina de evento ainda expôs `115` linhas de decks parseaveis
- o crawler continuou extraindo shell/strategy em modo dry-run

Observacao:

- os dois samples lidos no `event?e=83812` sairam com `cards=101`
- isso e fato observado
- a causa raiz ainda esta `not proven`

### 2. `EDHTop16 -> TopDeck` continua vivo

Artefatos:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/runner_probe_jokers_target5_max18/08_pipeline_summary.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/operational_runner_jokers_target5_max18_apply/08_pipeline_summary.json`

Fatos provados:

- `entries_available >= 10`
- `expanded_count=5`
- `validation_accepted_count=4`
- `strict_gate_eligible_count=4`
- rejeicao correta de `Vivi Ornitier` por:
  - `card_count=85`
  - `legal_status=not_proven`
  - `unresolved_cards=2`

### 3. O runner unico executou `dry-run` e `apply` com os guards esperados

Artefatos:

- `03_strict_gate_report.json`
- `04_stage_dry_run.json`
- `05_promote_dry_run.json`
- `06_stage_apply.json`
- `07_promote_apply.json`
- `08_pipeline_summary.json`

Fatos provados:

- `dry-run` nao escreveu em `meta_decks`
- `apply` escreveu apenas depois de passar pelo strict gate
- `stage_to_persist_count=4`
- `promote_dry_run_promotable_count=2`
- `promote_apply_promoted_count=2`
- decks bloqueados no mesmo lote:
  - `standing-2` `Kinnan`
  - `standing-3` `Rograkh + Silas`
- motivo do bloqueio:
  - `source_url_already_present_in_meta_decks`
  - `deck_fingerprint_already_present_in_meta_decks`

### 4. Regressao ampla server ficou verde

Artefatos:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/server_dart_analyze_meta_ai_routes_bin_test_2026-04-27.txt`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/server_meta_optimize_generate_regression_2026-04-27.txt`

Fatos provados:

- `dart analyze lib/meta lib/ai routes/ai bin test` sem issues
- suite focada `meta/optimize/generate`:
  - `All other tests passed!`
  - `17 skipped tests`

Leitura:

- os `skips` vieram do contrato atual das suites de integracao que dependem de infra/servidor real
- nao houve falha nova introduzida por este trabalho

## Frescor da base e cobertura real

### Estado atual de `meta_decks`

Artefato:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/meta_report_post_operational_runner_2026-04-27.json`

| metrica | valor |
| --- | ---: |
| total_meta_decks | 650 |
| mtgtop8_count | 641 |
| external_count | 9 |
| cEDH | 223 |
| EDH | 162 |
| Standard | 46 |
| Pioneer | 46 |
| Vintage | 44 |
| Modern | 41 |
| Pauper | 40 |
| Legacy | 40 |
| Premodern | 8 |

Frescor provado:

- latest external samples novos:
  - `standing-7` `Sisay, Weatherlight Captain`
  - `standing-6` `Ob Nixilis, Captive Kingpin`
- `created_at` desses dois rows:
  - `2026-04-27 20:32:17Z`

### Cobertura real por subformato Commander

Fonte:

- `meta_report_post_operational_runner_2026-04-27.json`

| subformato | decks |
| --- | ---: |
| competitive_commander | 223 |
| duel_commander | 162 |

Leitura:

- cobertura externa continua inteira em `competitive_commander`
- nao ha prova local de corpus externo para Commander casual
- nao ha prova local de corpus externo para `duel_commander`

### Cobertura real por identidade de cor

Artefato:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/commander_color_identity_coverage_post_operational_runner_2026-04-27.json`

| source | format | deck_count | resolved_identity_count | unknown_identity_count |
| --- | --- | ---: | ---: | ---: |
| external | cEDH | 9 | 9 | 0 |
| mtgtop8 | cEDH | 214 | 187 | 27 |
| mtgtop8 | EDH | 162 | 155 | 7 |

Identidades externas provadas agora:

- `BRU x4`
- `BGRUW x1`
- `BR x1`
- `BRUW x1`
- `GU x1`
- `GUW x1`

Leitura:

- os externos continuam pequenos em volume, mas ja nao sao mono-shell
- a base externa agora cobre pelo menos `6` identidades competitivas distintas
- o gap de identidade continua concentrado no `MTGTop8`, nao no lote externo promovido

## Gaps observados

1. `TopDeck deckObj` continua instavel em parte dos standings
   - no lote `jokers`, houve rejeicao por `topdeck_deckobj_missing`
   - isso parece upstream, nao regressao local
   - causa exata continua `not proven`

2. `MTGTop8` ainda produz samples Commander com `101` cartas em dry-run
   - fato observado no evento `83812`
   - causa exata continua `not proven`
   - pode ser export incluindo linha extra ou regra de parse especifica do host

3. `MTGTop8` ainda carrega identidade desconhecida em parte do corpus Commander
   - `cEDH`: `27`
   - `EDH`: `7`
   - exemplos de labels ainda nao resolvidos aparecem em:
     - `Aang, Swift Savior`
     - `Cecil, Dark Knight`
     - `Emet-Selch, Unsundered`

4. o `stage` isolado continua permissivo demais para operacao normal
   - ele ainda pode persistir `warning_pending`
   - por isso a operacao segura agora deve preferir o runner unico

## Interpretacao estrategica util para `optimize` e `generate`

**Web research nao foi usada nesta rodada.** As leituras abaixo saem apenas das decklists promovidas e dos artifacts locais.

### 1. `Ob Nixilis, Captive Kingpin`

Sinais fortes provados na lista:

- `All Will Be One`
- `Agatha's Soul Cauldron`
- `Underworld Breach`
- `Grinding Station`
- `Grapeshot`
- `Mayhem Devil`
- `Kederekt Parasite`
- `Razorkin Needlehead`
- `Firebrand Archer`
- `Reckless Fireweaver`

Leitura estrategica:

- nao e Rakdos midrange
- e um shell de combo/storm com pingers e loops de dano incremental
- o comandante funciona como payoff de nao-combate e capitaliza a densidade de triggers baratas

Sinal util para produto:

- `optimize` nao deve puxar esse shell para beatdown Rakdos genérico
- `generate` competitivo para `Ob Nixilis` precisa priorizar:
  - fast mana
  - loops de dano incremental
  - `Underworld Breach`
  - payoffs de pings e cast chains

### 2. `Sisay, Weatherlight Captain`

Sinais fortes provados na lista:

- `Bloom Tender`
- `Faeburrow Elder`
- `Kinnan, Bonder Prodigy`
- `Relic of Legends`
- `Deafening Silence`
- `Lavinia, Azorius Renegade`
- `Teferi, Time Raveler`
- `Smothering Tithe`
- `Emiel the Blessed`
- `Sakashima the Impostor`

Leitura estrategica:

- nao e `5c goodstuff`
- e um shell de toolbox lendario com mana engine de legends/dorks e camada de hate/control
- a lista mistura aceleracao lendaria, bullets utilitarios e fechamentos de combo tutoraveis pela Sisay

Sinal util para produto:

- `optimize` deve preservar densidade de permanentes lendarias utilitarias
- `generate` competitivo para `Sisay` deve reconhecer o shell como `toolbox-control/combo`, nao como pilha generica de staples cinco cores

## Menores proximas acoes tecnicas

1. adicionar um probe focado para explicar por que alguns exports `MTGTop8 cEDH` saem com `101` cartas
2. manter o runner unico como caminho oficial e evitar voltar para filtro manual inline
3. continuar expandindo externos apenas onde o strict gate ficar verde; nao promover `not_proven`
4. se o volume externo crescer, adicionar um report agregado de `strict gate rejection reasons` por evento para priorizar adapters/source fixes
