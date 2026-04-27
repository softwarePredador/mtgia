# Relatorio Meta Deck Intelligence - 2026-04-27

## Escopo

- repositorio: `softwarePredador/mtgia`
- foco: promocao controlada `external_commander_meta_candidates -> meta_decks`
- objetivo adicional: provar uso seguro em `optimize` e `generate` sem misturar `competitive_commander` com `duel_commander` ou Commander casual
- base de continuidade: `RELATORIO_META_DECK_INTELLIGENCE_2026-04-24.md`, `RELATORIO_COMMANDER_OPTIMIZE_FLOW_AUDIT_2026-04-27.md`, `server/manual-de-instrucao.md`

## Veredito

**Pipeline externo parcialmente vivo, promocao controlada e sem novo apply nesta rodada.**

- o fetch `MTGTop8 -> meta_decks` continua funcionando em dry-run para `cEDH`
- a cadeia externa `EDHTop16 -> TopDeck deck page` continua viva, mas com drift parcial: `2` expansoes OK e `2` `topdeck_deckobj_missing`
- a base live ja tem `source=external` em `meta_decks`, mas apenas `1` row promovida
- o gate de promocao atual bloqueou todos os `4` candidatos vivos; portanto **nenhum apply novo foi executado**
- os guards de consumo continuam corretos: `generate` so injeta meta Commander quando o prompt prova escopo; `optimize/complete` so consulta `competitive_commander` para `deckFormat=commander` com `bracket >= 3`

## Resumo do pipeline

1. `bin/fetch_meta.dart` puxa `MTGTop8` e grava direto em `meta_decks`
2. `bin/expand_external_commander_meta_candidates.dart` expande `EDHTop16` para deck pages do `TopDeck`
3. `bin/import_external_commander_meta_candidates.dart --validation-profile=topdeck_edhtop16_stage2 --dry-run` valida estrutura, legalidade e card count
4. `bin/stage_external_commander_meta_candidates.dart --apply` escreve apenas em `external_commander_meta_candidates`
5. `bin/promote_external_commander_meta_candidates.dart --apply` promove somente candidatos staged/promotable para `meta_decks`
6. `lib/meta/meta_deck_reference_support.dart` faz o consumo compartilhado para `generate` e `optimize`, com `LEFT JOIN` por `source_url` para recuperar `source_name` e `research_payload.source_chain`

## Comandos executados

```bash
cd server && dart run bin/fetch_meta.dart cEDH --dry-run --limit-events=1 --limit-decks=2

cd server && dart run bin/expand_external_commander_meta_candidates.dart \
  --source-url=https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57 \
  --limit=4 \
  --output=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_2026-04-27.json

cd server && dart run bin/import_external_commander_meta_candidates.dart \
  test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_2026-04-27.json \
  --dry-run \
  --validation-profile=topdeck_edhtop16_stage2 \
  --validation-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_2026-04-27.validation.json

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --report-json-out=test/artifacts/meta_deck_intelligence_2026-04-27/external_commander_meta_candidates_promotion_gate_dry_run_2026-04-27.json

cd server && dart run bin/extract_meta_insights.dart --report-only \
  > test/artifacts/meta_deck_intelligence_2026-04-27/extract_meta_insights_report_only_2026-04-27.json

cd server && dart run bin/meta_profile_report.dart \
  > test/artifacts/meta_deck_intelligence_2026-04-27/meta_profile_report_2026-04-27.json

cd server && python3 <db snapshots / coverage probes>

cd server && dart analyze \
  lib/meta/meta_deck_reference_support.dart \
  lib/meta/meta_deck_analytics_support.dart \
  lib/ai/optimize_runtime_support.dart \
  lib/ai/optimize_complete_support.dart \
  routes/ai/generate/index.dart \
  routes/ai/optimize/index.dart \
  bin/fetch_meta.dart \
  bin/extract_meta_insights.dart \
  bin/meta_profile_report.dart \
  bin/promote_external_commander_meta_candidates.dart \
  test/meta_deck_reference_support_test.dart \
  test/meta_deck_analytics_support_test.dart \
  test/external_commander_meta_promotion_support_test.dart \
  test/optimize_runtime_support_test.dart

cd server && dart test -r compact \
  test/meta_deck_reference_support_test.dart \
  test/meta_deck_analytics_support_test.dart \
  test/external_commander_meta_promotion_support_test.dart \
  test/optimize_runtime_support_test.dart \
  test/external_commander_meta_staging_support_test.dart \
  test/mtgtop8_meta_support_test.dart
```

## Evidencia validada

### 1. `MTGTop8` continua respondendo e o parser principal segue vivo

Artifact: `server/test/artifacts/meta_deck_intelligence_2026-04-27/fetch_meta_cedh_dry_run.txt`

- `https://www.mtgtop8.com/format?f=cEDH` respondeu e expôs `1` evento recente
- o evento `https://www.mtgtop8.com/event?e=83812` expôs `115` linhas de deck
- o parser leu deck rows reais e exportou listas:
  - `Terra, Magical Adept` (`placement=2`, `cards=101`)
  - `Kraum + Tymna` (`placement=3`, `cards=101`)
- leitura: o pipeline `format page -> event page -> export deck` continua funcional para `cEDH`

### 2. A cadeia externa continua viva, mas com drift parcial

Artifacts:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_2026-04-27.validation.json`

Resultado:

- expansao: `expanded_count=2`, `rejected_count=2`
- rejeicoes: `topdeck_deckobj_missing` nas standings `2` e `3`
- validacao stage 2: `accepted=2`, `rejected=0`
- `Scion of the Ur-Dragon`: `legal_status=not_proven`, `unresolved_cards=1` (`Prismari, the Inspiration`)
- `Norman Osborn // Green Goblin`: `legal_status=legal`, `unresolved_cards=0`

Leitura:

- `EDHTop16` segue expondo evento valido
- `TopDeck` ainda entrega deck pages usaveis em parte do evento
- houve drift real do parser/markup em metade dos samples auditados desta rodada

### 3. Frescor real da base atual

Artifact: `server/test/artifacts/meta_deck_intelligence_2026-04-27/db_snapshot_2026-04-27.json`

`meta_decks`:

| source | decks | min(created_at) | max(created_at) |
| --- | ---: | --- | --- |
| `mtgtop8` | 641 | `2025-11-22 14:14:20+00` | `2026-04-23 20:02:52+00` |
| `external` | 1 | `2026-04-27 12:04:17+00` | `2026-04-27 12:04:17+00` |

`external_commander_meta_candidates`:

| validation_status | legal_status | decks |
| --- | --- | ---: |
| `promoted` | `valid` | 1 |
| `staged` | `warning_pending` | 1 |
| `candidate` | `(null)` | 2 |

Leitura:

- o corpus principal nao esta vazio para fonte externa: **ha 1 row promovida**
- o restante da fila externa ainda esta travado em statuses que impedem promocao segura

### 4. Dry-run do gate de promocao confirmou zero candidatos novos aptos

Artifacts:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/external_commander_meta_candidates_promotion_gate_dry_run_2026-04-27.log`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/external_commander_meta_candidates_promotion_gate_dry_run_2026-04-27.json`

Resultado:

- `total=4`
- `promotable=0`
- `blocked=4`

Bloqueios observados:

1. `Norman Osborn // Green Goblin`
   - `already_promoted`
   - `validation_status_not_staged`
   - `source_url_already_present_in_meta_decks`
   - `deck_fingerprint_already_present_in_meta_decks`
2. `Scion of the Ur-Dragon`
   - `legal_status_not_promotable`
   - `commander_legality_not_confirmed`
   - `unresolved_cards_blocking`
3. `Kraum + Tymna`
   - `validation_status_not_staged`
   - `missing_or_invalid_legal_status`
   - `commander_legality_not_confirmed`
   - `missing_staging_audit`
4. `Malcolm + Vial Smasher`
   - mesmos bloqueios de `Kraum + Tymna`

Conclusao operacional:

- o guard funcionou
- **nenhum apply novo foi executado**
- a promocao live permaneceu congelada por seguranca, como pedido

### 5. `meta_profile_report` confirma fonte externa em `meta_decks`

Artifacts:

- `server/test/artifacts/meta_deck_intelligence_2026-04-27/meta_profile_report_2026-04-27.json`
- `server/test/artifacts/meta_deck_intelligence_2026-04-27/extract_meta_insights_report_only_2026-04-27.json`

Fatos provados:

- `total_competitive_decks=642`
- `sources`: `mtgtop8=641`, `external=1`
- `source_formats`: `external / cEDH / competitive_commander = 1`
- `by_source_subformat`: `external / competitive_commander = 1`
- o resumo por source/subformat nao mostrou `external / duel_commander`

Leitura:

- `meta_decks` ja expõe a fonte externa promovida
- o row externo promovido esta classificado como `competitive_commander`, nao como `EDH` legado

## Cobertura real por formato e cor

### Cobertura por formato/subformato

Base: `meta_profile_report_2026-04-27.json`

| corte | decks |
| --- | ---: |
| `cEDH / competitive_commander` | 215 |
| `EDH / duel_commander` | 162 |
| `external / competitive_commander` | 1 |
| `external / duel_commander` | 0 |

### Cobertura por cor efetiva do deck

Artifact: `server/test/artifacts/meta_deck_intelligence_2026-04-27/effective_deck_color_coverage_2026-04-27.json`

Top grupos `cEDH`:

| source | format | effective_deck_colors | decks |
| --- | --- | --- | ---: |
| `mtgtop8` | `cEDH` | `BR` | 30 |
| `mtgtop8` | `cEDH` | `GU` | 29 |
| `mtgtop8` | `cEDH` | `BGR` | 19 |
| `mtgtop8` | `cEDH` | `BRU` | 16 |
| `mtgtop8` | `cEDH` | `GW` | 15 |
| `external` | `cEDH` | `BRU` | 1 |

Top grupos `EDH` legado:

| source | format | effective_deck_colors | decks |
| --- | --- | --- | ---: |
| `mtgtop8` | `EDH` | `RU` | 30 |
| `mtgtop8` | `EDH` | `BGU` | 13 |
| `mtgtop8` | `EDH` | `G` | 13 |
| `mtgtop8` | `EDH` | `unknown` | 13 |
| `mtgtop8` | `EDH` | `BGR` | 10 |

### O que ficou **not proven**

Cobertura por identidade de cor do comandante ainda nao esta limpa o bastante para ser afirmada como completa.

Artifact: `server/test/artifacts/meta_deck_intelligence_2026-04-27/commander_color_identity_coverage_2026-04-27.json`

Problema observado:

- a tentativa de resolver `commander_name -> cards.color_identity` deixou a maioria dos rows Commander como `unknown`
- gaps mais frequentes no catalogo/lookup:
  - `Kefka, Court Mage`
  - `Ral, Monsoon Mage`
  - `Terra, Magical Adept`
  - `Brigid, Clachan's Heart`
  - `Etali, Primal Conqueror`

Leitura:

- a cobertura por **cor efetiva da lista** esta provada
- a cobertura por **identidade canonica do comandante** permanece **not proven** em parte relevante do corpus

## Validacao de uso em `optimize` e `generate`

### Guards de escopo

Codigo auditado:

- `server/lib/meta/meta_deck_reference_support.dart`
- `server/lib/ai/optimize_runtime_support.dart`
- `server/lib/ai/optimize_complete_support.dart`
- `server/routes/ai/generate/index.dart`
- `server/routes/ai/optimize/index.dart`

Fatos provados:

1. `selectMetaDeckReferenceCandidates(...)` descarta qualquer candidato cujo `candidate.commanderSubformat != commanderScope`
2. `generate` so chama meta Commander quando `_resolveCommanderMetaScopeFromPrompt(...)` encontra:
   - `duel commander`
   - `cedh`
   - `competitive commander`
   - `high power`
   - `bracket 3/4`
3. `optimize/complete` usa `resolveCommanderOptimizeMetaScope(...)`, que retorna:
   - `competitive_commander` apenas para `deckFormat=commander` com `bracket >= 3`
   - `null` para `bracket < 3` e para formatos nao Commander
4. `preferExternalCompetitive=true` so pesa score extra quando `candidate.commanderSubformat == 'competitive_commander'`

### Testes focados executados

Resultado:

- `dart analyze ...` -> OK
- `dart test meta/reference/promotion/optimize support` -> OK

Casos diretamente relevantes:

- `test/meta_deck_reference_support_test.dart`
  - prefere shell externo competitivo com partner exato
  - bloqueia row `EDH` quando o escopo pedido e `competitive_commander`
  - humaniza `source_chain` sem vazar URLs
- `test/optimize_runtime_support_test.dart`
  - usa `competitive_commander` so para `bracket >= 3`
  - mantem Commander casual fora do meta competitivo
- `test/external_commander_meta_promotion_support_test.dart`
  - bloqueia status nao staged, source duplicada, fingerprint duplicado, `warning_pending` e ausencia de `staging_audit`

## Interpretacao estrategica util para produto

### 1. O row externo promovido traz sinal cEDH coerente

Deck promovido:

- `Norman Osborn // Green Goblin`
- `source=external`
- `subformat=competitive_commander`
- cor efetiva: `BRU`
- `strategy_archetype=combo`

Leitura do shell:

- pacote de fast mana denso: `Chrome Mox`, `Lotus Petal`, `Mana Vault`, `Grim Monolith`, talismans
- pacote de combo curto: `Thassa's Oracle`, `Tainted Pact`, `Underworld Breach`, `Brain Freeze`
- interacao barata/gratis: `An Offer You Can't Refuse`, `Flusterstorm`, `Fierce Guardianship`, `Force of Will`, `Mental Misstep`
- setup explosivo com wheel/filter/ritual: `Windfall`, `Wheel of Fortune`, `Faithless Looting`, `Frantic Search`, `Dark Ritual`, `Cabal Ritual`, `Jeska's Will`

Sinal util:

- para `optimize` em `bracket >= 3`, listas `BRU` com shell combo devem priorizar pacotes de mana explosiva + interacao gratuita + wins compactas, em vez de planos midrange lentos
- para `generate`, o contexto externo promovido serve como evidencia de densidade e velocidade, nao como decklist a ser copiada

### 2. O candidato Scion confirma o tipo de lista que ainda falta destravar

`Scion of the Ur-Dragon` mostrou:

- shell `WUBRG` turbo/combo
- mesma espinha dorsal de fast mana + tutors + `Breach/Oracle`
- bloqueio real por `Prismari, the Inspiration` nao resolvida

Sinal util:

- ha valor em promover mais cEDH externo multicolorido, mas o gate esta certo em nao passar listas com carta nao resolvida

### 3. O corpus continua separando bem cEDH de Duel Commander

Comparacao source-aware:

| bucket | avg_lands | avg_instants | avg_artifacts |
| --- | ---: | ---: | ---: |
| `cEDH` total | 26.51 | 21.07 | 15.74 |
| `EDH` legado / duel | 38.15 | 19.93 | 4.41 |
| `external cEDH` (Norman) | 24.00 | 27.00 | 17.00 |

Leitura:

- `competitive_commander` vive no eixo `low land / high fast mana / combo compacta`
- `EDH` legado do `MTGTop8` segue muito mais proximo de `Duel Commander` classico, com base de mana maior e pacote de artifacts bem menor
- isso reforca que misturar os buckets derrubaria a qualidade de `optimize` e `generate`

## Gaps observados

1. **Parser drift no TopDeck**
   - `2/4` deck pages auditadas falharam com `topdeck_deckobj_missing`
   - isso reduz a taxa de expansao externa mesmo quando o evento do `EDHTop16` continua vivo

2. **Fila externa com baixa promotabilidade**
   - `0` novos promotable no dry-run atual
   - `Norman` ja foi promovido
   - `Scion` segue bloqueado por unresolved
   - `Kraum + Tymna` e `Malcolm + Vial Smasher` nao tem staging audit atualizado

3. **Identidade canonica do comandante ainda nao esta bem coberta**
   - varios commanders novos nao resolvem limpo no catalogo local
   - isso impede afirmar cobertura completa por cor de comandante

4. **Cobertura externa ainda e muito pequena**
   - `1` deck externo em `meta_decks`
   - ainda nao ha massa suficiente para mexer em heuristica casual ou em coverage claims amplas

## Menores proximas acoes tecnicas

1. Corrigir o adapter do `TopDeck` para o caso `topdeck_deckobj_missing` antes de tentar promover standings `2` e `3`
2. Adicionar fallback pequeno e focado para lookup de `commander_name` em cartas split / UB / nomes novos, para destravar cobertura por identidade do comandante
3. Rodar novo ciclo `expand -> validate -> stage/apply -> promote` apenas quando houver pelo menos `1` candidato `staged + valid + is_commander_legal=true + staging_audit`
4. Manter `generate` e `optimize` consumindo externo apenas em `competitive_commander`, sem abrir excecao para Commander casual
