# Relatorio Meta Deck Intelligence

Data: 2026-04-24

## Objetivo

Atualizar a leitura operacional de `meta_decks` depois do gate de promocao externa para que `extract_meta_insights.dart` e `meta_profile_report.dart` passem a diferenciar:

- `source=mtgtop8` vs `source=external`
- `subformat=competitive_commander` / `duel_commander`
- `shell_label`
- `strategy_archetype`

Sem destruir dados.

## Etapa 1/5 - auditoria final das fontes externas

### Resultado

Politica auditada para `external_commander_meta_candidates`:

| Fonte | Classificacao | Fato provado | Status operacional |
| --- | --- | --- | --- |
| EDHTop16 | accept-with-validation | `200` em URL real de torneio + artefato local prova `EDHTop16 -> TopDeck deck page -> 100 cartas` | ativo |
| TopDeck.gg | accept-with-validation | `200` em URL real de deck + HTML da pagina de deck | ativo como elo da expansao; staging direto por `source_url=/deck/...` ainda nao provado |
| cEDH Decklist Database | enrichment-only | `200` no host + descricao publica de base curada | fora do staging |
| EDHREC | enrichment-only | `200` no host + natureza agregada provada por pagina publica | fora do staging |
| Commander Spellbook | enrichment-only | `200` no host + natureza de referencia de combos | fora do staging |
| Archidekt | accept-with-validation | `200` no host; deck host publico e suportado apenas por pesquisa web nesta rodada | policy-approved, ainda nao implementado |
| Moxfield | accept-with-validation | papel de deck host corroborado por pesquisa web; sample real no ambiente retornou `403` | policy-approved, fetch live direto ainda nao provado |

Veredito:

- `accept`: nenhum
- `accept-with-validation`: `EDHTop16`, `TopDeck.gg`, `Archidekt`, `Moxfield`
- `enrichment-only`: `cEDH Decklist Database`, `EDHREC`, `Commander Spellbook`
- `reject`: nenhum host banido nesta rodada

### Fatos provados por codigo e artefatos locais

1. A policy implementada hoje em codigo ainda e menor do que a policy auditada:
   - `EDHTop16` com path `/tournament/`
   - `TopDeck.gg` com path `/event/`
2. O fluxo real atualmente provado no repositorio e:
   - `EDHTop16 tournament` -> `TopDeck deck page` -> `card_list` de `100` cartas -> validacao stage 2
3. O artefato `server/test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json` prova:
   - `expanded_count=4`
   - `rejected_count=4`
   - `collection_method=edhtop16_graphql_topdeck_deck_page_dry_run`
4. O artefato `server/test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json` prova:
   - `validation_profile=topdeck_edhtop16_stage2`
   - `accepted_count=4`
   - `rejected_count=0`
   - `legal_status=legal` em `3` casos e `not_proven` em `1`

Leitura:

- `EDHTop16` e `TopDeck.gg` estao comprovados como cadeia operacional do sprint
- `Archidekt` e `Moxfield` ainda nao estao comprovados no codigo do repositorio
- `cEDH Decklist Database`, `EDHREC` e `Commander Spellbook` nao entram como `source_url/source_name` canonicos

### Fatos provados por fetch live

Com `curl -L -sS --max-time 20` em `2026-04-24`:

| Fonte | URL auditada | Resultado |
| --- | --- | --- |
| EDHTop16 | `https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57` | `200 text/html` |
| TopDeck.gg | `https://topdeck.gg/deck/cedh-arcanum-sanctorum-57/nwBkSm4qiOd4umllUQShekwHVXq1` | `200 text/html` |
| cEDH Decklist Database | `https://cedh-decklist-database.com/` | `200 text/html` |
| EDHREC | `https://edhrec.com/` | `200 text/html` |
| Commander Spellbook | `https://commanderspellbook.com/` | `200 text/html` |
| Archidekt | `https://www.archidekt.com/` | `200 text/html` |
| Moxfield | `https://moxfield.com/decks/eecRYCKd8kqSIdjq0YOtzA` | `403 text/html` |

Leitura:

- `EDHTop16` e `TopDeck.gg` continuam alcancaveis no ambiente atual
- `Moxfield` como host competitivo relevante foi corroborado por pesquisa web, mas o fetch direto deste ambiente permanece **not proven** por causa do `403`
- `Archidekt` respondeu no host, mas a extraçao de deck competitivo/cEDH real permanece **not proven** nesta rodada

### Pesquisa web separada de fatos locais

Pesquisa externa resumida via `Commander Meta Web Research Analyst`:

- `EDHTop16`: standings competitivos reais; decklist completa depende do encadeamento para `TopDeck.gg`
- `TopDeck.gg`: deck host competitivo forte com deck pages publicas
- `cEDH Decklist Database`: curadoria secundaria, melhor como enrichment
- `EDHREC`: agregado heuristico, nao deck canonico de torneio
- `Commander Spellbook`: referencia de combo, nao deck host
- `Archidekt`: deck host publico, mas contexto competitivo precisa validacao explicita
- `Moxfield`: deck host publico forte no ecossistema Commander/cEDH, mas scraping direto neste ambiente ficou **not proven**

### Comandos rodados nesta etapa

```bash
cd server && python3 - <<'PY'
import json
from pathlib import Path
p=Path('test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json')
obj=json.loads(p.read_text())
for item in obj.get('candidates', [])[:4]:
    print(item.get('source_url'))
    rp=item.get('research_payload', {})
    print(rp.get('collection_method'))
    print(rp.get('source_context'))
    print(rp.get('source_chain'))
PY

python3 - <<'PY'
import subprocess, shlex
urls = [
  ('EDHTop16 tournament', 'https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57'),
  ('TopDeck deck', 'https://topdeck.gg/deck/cedh-arcanum-sanctorum-57/nwBkSm4qiOd4umllUQShekwHVXq1'),
  ('cEDH Decklist Database root', 'https://cedh-decklist-database.com/'),
  ('EDHREC root', 'https://edhrec.com/'),
  ('Commander Spellbook root', 'https://commanderspellbook.com/'),
  ('Archidekt root', 'https://www.archidekt.com/'),
  ('Moxfield deck', 'https://moxfield.com/decks/eecRYCKd8kqSIdjq0YOtzA'),
]
for label, url in urls:
    cmd = f"curl -L -sS --max-time 20 -o /tmp/meta_source_audit_body.html -w '%{{http_code}}|%{{url_effective}}|%{{content_type}}' {shlex.quote(url)}"
    proc = subprocess.run(cmd, shell=True, text=True, capture_output=True)
    print(label, proc.stdout.strip())
PY
```

### Menores proximas acoes tecnicas apos a auditoria

1. manter o allowlist implementado focado em `EDHTop16` + cadeia `TopDeck` na Etapa 2
2. persistir apenas candidatos `accepted` do profile `topdeck_edhtop16_stage2`
3. manter `cEDH Decklist Database`, `EDHREC` e `Commander Spellbook` fora do staging
4. nao ativar `Archidekt` ou `Moxfield` ate existir adapter dedicado e fetch/source proof adicionais

## Etapa 2/5 - persistencia segura dos candidatos aprovados

### Resultado

Foi criado um gate separado de staging:

- script: `server/bin/stage_external_commander_meta_candidates.dart`
- suporte: `server/lib/meta/external_commander_meta_staging_support.dart`
- artefato dry-run: `server/test/artifacts/external_commander_meta_stage2_staging_dry_run_2026-04-24.json`

Mudanca de contrato:

- `external_commander_meta_candidates.validation_status` agora aceita `staged`
- o importador stage 2 continua dry-run only
- a escrita real para staging ficou separada e continua exigindo `--apply`

### Comandos rodados nesta etapa

```bash
cd server && dart analyze lib/meta bin test

cd server && dart test -r compact \
  test/external_commander_meta_candidate_support_test.dart \
  test/external_commander_meta_import_support_test.dart \
  test/external_commander_meta_promotion_support_test.dart \
  test/external_commander_meta_staging_support_test.dart

cd server && dart run bin/stage_external_commander_meta_candidates.dart \
  --report-json-out=test/artifacts/external_commander_meta_stage2_staging_dry_run_2026-04-24.json
```

### Evidencia validada

Dry-run do novo gate:

- `mode=dry_run`
- `profile=topdeck_edhtop16_stage2`
- `accepted=4`
- `to_persist=4`
- `duplicates=0`
- `validation_rejected=0`
- `expansion_rejected=4`

Distribuicao do staging planejado:

| validation_status | legal_status | decks |
| --- | --- | ---: |
| staged | valid | 3 |
| staged | warning_pending | 1 |

Decks preparados:

| source_url | deck | legal_status | observacao |
| --- | --- | --- | --- |
| `...#standing-1` | `Scion of the Ur-Dragon` | `warning_pending` | `unresolved_cards=1` (`Prismari, the Inspiration`) |
| `...#standing-4` | `Norman Osborn // Green Goblin` | `valid` | sem illegal cards |
| `...#standing-5` | `Malcolm + Vial Smasher` | `valid` | sem illegal cards |
| `...#standing-8` | `Kraum + Tymna` | `valid` | sem illegal cards |

Fatos provados por codigo:

1. o comando novo e `dry-run` por default
2. a escrita real exige `--apply`
3. a escrita vai apenas para `external_commander_meta_candidates`
4. o gate bloqueia:
   - `validation_profile` fora de `topdeck_edhtop16_stage2`
   - `validation.rejected_count > 0`
   - `card_list/cards/card_entries` ausente
   - `collection_method` ausente
   - `source_context` ausente
   - `source_name/source_url` invalidos
   - `is_commander_legal=false`
5. o gate preserva `research_payload` e adiciona `research_payload.staging_audit`
6. o gate deduplica por `source_url`

Leitura:

- o stage 2 deixou de ser um beco sem saida
- ele continua nao destrutivo por default
- a fila pronta para promocao futura passa a carregar audit trail suficiente para bloquear unresolved/illegal na Etapa 3

### Menores proximas acoes tecnicas apos a persistencia segura

1. promover apenas candidatos `staged` no gate da Etapa 3
2. impedir que `warning_pending` com unresolved bloqueante entre em `meta_decks`
3. manter `meta_decks` intocado ate a promocao separada estar guardada por `--apply`

## Etapa 3/5 - promocao controlada para `meta_decks`

### Resultado

O gate de promocao foi endurecido para o contrato da Etapa 2:

- aceita apenas `validation_status=staged`
- exige decklist completa de `100` cartas
- exige `is_commander_legal=true`
- exige source allowlisted
- exige `research_payload.source_chain`
- exige `research_payload.staging_audit`
- bloqueia `unresolved_cards`
- bloqueia `illegal_cards`
- bloqueia `warning_pending`
- bloqueia duplicidade por `source_url`
- bloqueia duplicidade por deck fingerprint

Importante:

- `meta_decks` continua sem escrita nesta rodada
- `source_name` e `research_payload` auditavel permanecem authoritative em `external_commander_meta_candidates`
- a integracao futura continua usando `JOIN` por `source_url`

### Comandos rodados nesta etapa

```bash
cd server && dart analyze lib/meta bin test

cd server && dart test -r compact \
  test/external_commander_meta_candidate_support_test.dart \
  test/external_commander_meta_import_support_test.dart \
  test/external_commander_meta_staging_support_test.dart \
  test/external_commander_meta_promotion_support_test.dart

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --report-json-out=test/artifacts/external_commander_meta_candidates_promotion_gate_dry_run_2026-04-24.current.json
```

### Evidencia validada

#### Regras provadas em teste

Casos cobertos em `server/test/external_commander_meta_promotion_support_test.dart`:

1. aceita candidato `staged` allowlisted com fingerprint unico
2. bloqueia `validation_status` fora de `staged`
3. bloqueia `source_url` ja presente em `meta_decks`
4. bloqueia ausencia de `source_chain` e `staging_audit`
5. bloqueia deck sem `100` cartas
6. bloqueia `warning_pending` com `unresolved_cards`
7. bloqueia source fora da allowlist
8. bloqueia fingerprint duplicado no stage e em `meta_decks`

#### Dry-run live atual

Resultado do gate real sobre a base atual:

- `total=4`
- `promotable=0`
- `blocked=4`

Bloqueios observados em todos os 4 rows atuais do banco:

- `validation_status_not_staged`
- `missing_or_invalid_legal_status`
- `commander_legality_not_confirmed`
- `missing_staging_audit`

Leitura:

- o gate novo esta funcional
- a ausencia de promocao live agora e explicada por falta de `stage --apply` previo, nao por permissividade do gate
- cobertura live de `external` em `meta_decks` continua **not proven**

### Rollback operacional documentado

```bash
psql $DATABASE_URL -c "
DELETE FROM meta_decks
WHERE source_url = '<source_url_promovida>';

UPDATE external_commander_meta_candidates
SET validation_status = 'staged',
    promoted_to_meta_decks_at = NULL,
    updated_at = CURRENT_TIMESTAMP
WHERE source_url = '<source_url_promovida>';
"
```

### Menores proximas acoes tecnicas apos a promocao guardada

1. aplicar o stage real apenas quando for seguro usar `--apply` no staging
2. so depois rerodar o promotion gate para observar `promotable > 0`
3. integrar o consumo competitivo em `optimize/generate` sem depender de escrita live em `meta_decks`

## Resumo do pipeline

### Fonte primaria comprovada

- `MTGTop8` continua sendo a unica fonte atualmente presente em `meta_decks`.
- O stage externo continua separado em `external_commander_meta_candidates`.

### Fluxo atual

1. `fetch_meta.dart` popula `meta_decks` a partir do `MTGTop8`.
2. `promote_external_commander_meta_candidates.dart` continua sendo o gate unico para levar candidatos externos validados para `meta_decks`.
3. `extract_meta_insights.dart` agora aceita `--report-only` e passou a imprimir resumo por `source`, `subformat`, `shell_label` e `strategy_archetype` antes de qualquer escrita.
4. `meta_profile_report.dart` agora le todo `meta_decks`, nao apenas `MTGTop8`, e expõe cortes por `source`, `source+format`, `source+subformat`, `source+color+shell` e `source+color+strategy`.

## Comandos rodados

```bash
cd server && dart analyze bin/extract_meta_insights.dart bin/meta_profile_report.dart lib/meta/meta_deck_analytics_support.dart test/meta_deck_analytics_support_test.dart
cd server && dart test test/meta_deck_analytics_support_test.dart test/meta_deck_card_list_support_test.dart test/meta_deck_commander_shell_support_test.dart test/meta_deck_format_support_test.dart test/external_commander_meta_promotion_support_test.dart
cd server && dart run bin/promote_external_commander_meta_candidates.dart --report-json-out=test/artifacts/external_commander_meta_candidates_promotion_gate_dry_run_2026-04-24.current.json
cd server && dart run bin/extract_meta_insights.dart --report-only
cd server && dart run bin/meta_profile_report.dart
python3 - <<'PY'
import psycopg2
conn=psycopg2.connect('postgresql://postgres:c2abeef5e66f21b0ce86@143.198.230.247:5433/halder')
cur=conn.cursor()
cur.execute("""
SELECT CASE WHEN source_url ILIKE 'https://www.mtgtop8.com/%' THEN 'mtgtop8' ELSE 'external' END AS source,
       COUNT(*)::int,
       MIN(created_at)::text,
       MAX(created_at)::text
FROM meta_decks
GROUP BY 1
ORDER BY 1
""")
print(cur.fetchall())
cur.execute("""
SELECT validation_status, COUNT(*)::int
FROM external_commander_meta_candidates
GROUP BY 1
ORDER BY 1
""")
print(cur.fetchall())
conn.close()
PY
```

## Evidencia validada

### 1. Gate externo continua nao destrutivo por default

Dry-run executado:

- `total=4`
- `promotable=0`
- `blocked=4`

Bloqueios observados em todos os candidatos:

- `validation_status_not_validated`
- `missing_or_invalid_legal_status`

Leitura:

- o gate continua seguro
- nao houve promocao real para `meta_decks` nesta rodada

### 2. Frescor real da base atual

Em `meta_decks`:

| source | decks | min(created_at) | max(created_at) |
| --- | ---: | --- | --- |
| mtgtop8 | 641 | 2025-11-22 14:14:20+00 | 2026-04-23 20:02:52+00 |

Estado atual:

- `external` em `meta_decks`: **0 observado**
- staging externo em `external_commander_meta_candidates`: `candidate=4`

Conclusao:

- frescor live comprovado apenas para `mtgtop8`
- cobertura live de `external` em `meta_decks`: **nao comprovado**

### 3. `extract_meta_insights.dart` agora diferencia origem e contexto sem escrever

Com `--report-only`, o script passou a imprimir:

- `by_source`
- `by_source_format`
- `by_source_subformat`
- `top_commander_shells`
- `top_commander_strategies`

Snapshot observado:

- `by_source`: `mtgtop8=641`
- `by_source_subformat`:
  - `mtgtop8|competitive_commander=214`
  - `mtgtop8|duel_commander=162`
- `top_commander_shells`:
  - `Spider-Man 2099` (`duel_commander`, `29`)
  - `Kraum, Ludevic's Opus + Tymna the Weaver` (`competitive_commander`, `21`)
  - `Kinnan, Bonder Prodigy` (`competitive_commander`, `20`)
- `top_commander_strategies`:
  - `competitive_commander|combo=126`
  - `duel_commander|control=75`
  - `duel_commander|aggro=45`

Leitura:

- o extrator deixou de tratar o corpus como um bloco unico para auditoria
- hoje o output ainda mostra apenas `mtgtop8` porque nao ha rows `external` promovidas

### 4. `meta_profile_report.dart` agora mede cobertura por `source`

Novos blocos expostos:

- `sources`
- `source_formats`
- `commander_shell_strategy_summary_by_source`
- `top_groups_source_format_color_shell`
- `top_groups_source_format_color_strategy`

Cobertura observada:

| source | format | subformat | deck_count |
| --- | --- | --- | ---: |
| mtgtop8 | cEDH | competitive_commander | 214 |
| mtgtop8 | EDH | duel_commander | 162 |
| mtgtop8 | PI | - | 46 |
| mtgtop8 | ST | - | 46 |
| mtgtop8 | VI | - | 44 |
| mtgtop8 | MO | - | 41 |
| mtgtop8 | LE | - | 40 |
| mtgtop8 | PAU | - | 40 |
| mtgtop8 | PREM | - | 8 |

Cobertura Commander por source:

| source | format | subformat | deck_count | with_shell_label | with_strategy_archetype |
| --- | --- | --- | ---: | ---: | ---: |
| mtgtop8 | cEDH | competitive_commander | 214 | 214 | 214 |
| mtgtop8 | EDH | duel_commander | 162 | 162 | 162 |

### 5. Cobertura real por identidade de cor

Top grupos `source+format+color+shell` observados:

| source | format | subformat | colors | shell | deck_count |
| --- | --- | --- | --- | --- | ---: |
| mtgtop8 | EDH | duel_commander | UR | spider-man | 27 |
| mtgtop8 | cEDH | competitive_commander | UG | kinnan | 20 |
| mtgtop8 | cEDH | competitive_commander | BR | kraum | 18 |
| mtgtop8 | cEDH | competitive_commander | WG | sisay | 8 |
| mtgtop8 | EDH | duel_commander | UBG | tasigur | 6 |

Top grupos `source+format+color+strategy` observados:

| source | format | subformat | colors | strategy | deck_count |
| --- | --- | --- | --- | --- | ---: |
| mtgtop8 | EDH | duel_commander | UR | control | 33 |
| mtgtop8 | cEDH | competitive_commander | BR | combo | 30 |
| mtgtop8 | cEDH | competitive_commander | BRG | combo | 17 |
| mtgtop8 | EDH | duel_commander | RG | aggro | 15 |
| mtgtop8 | EDH | duel_commander | UB | control | 15 |

Leitura:

- cobertura real por cor foi medida sobre o corpus armazenado
- cobertura total de todas as identidades para `external` ainda e **nao comprovada**

## Validacao commander-aware

### MTGTop8 EDH/cEDH

Continuam commander-aware:

- `EDH`: sideboard do comandante entra no `effectiveCards`
- `cEDH`: partner commanders no sideboard entram no `effectiveCards`

Prova direta:

- `test/meta_deck_card_list_support_test.dart`
- `test/meta_deck_commander_shell_support_test.dart`
- `test/meta_deck_analytics_support_test.dart`

### Externos promovidos

O comportamento de parser commander-aware para externos foi validado em unidade com lista `cEDH` de `100` cartas contendo comandante no mainboard:

- `source=external`
- `subformat=competitive_commander`
- `includesSideboardAsCommanderZone=true`
- `effectiveTotal=100`

Importante:

- isso comprova o comportamento do parser/report **quando houver row externa em `meta_decks`**
- a presenca live de rows `external` em `meta_decks` nesta rodada permanece **nao comprovada**, porque o gate dry-run bloqueou todos os 4 candidatos

## Gaps observados

1. `external` ainda nao entrou de fato em `meta_decks`
2. o gate continua certo em bloquear porque os 4 candidatos ainda estao em `validation_status=candidate` e sem `legal_status`
3. cobertura live de Commander/cEDH externo por cor ainda e **nao comprovada**

## Interpretacao estrategica util para `optimize` e `generate`

1. `competitive_commander` continua fortemente concentrado em `combo` com shells pequenos e redundancia alta
2. `duel_commander` aparece mais pesado em `control` e `aggro`, com mana base mais longa e menos fast mana
3. shells recorrentes continuam sendo sinais fortes:
   - `Kraum + Tymna`
   - `Kinnan`
   - `Sisay`
   - `Tasigur`
4. para `optimize`:
   - usar `strategy_archetype` como filtro antes de sugerir staples
   - preservar shell package pequeno quando a lista ja aponta um shell competitivo claro
5. para `generate`:
   - diferenciar `duel_commander` vs `competitive_commander`
   - evitar importar pressao de `combo` cEDH para Commander amplo sem prova de contexto

## Menores proximas acoes tecnicas

1. promover pelo menos um candidato externo so depois de resolver `validation_status=validated` e `legal_status`
2. rerodar `meta_profile_report.dart` e `extract_meta_insights.dart --report-only` apos a primeira promocao real para comprovar `source=external` live
3. manter `meta_profile_report.dart` como auditor recorrente de `source + subformat + shell + strategy`

## Atualizacao de integracao — `generate` + `optimize`

### Objetivo

Fechar o uso real das referencias Commander/cEDH externas no motor de IA sem copiar lista cegamente:

- manter `competitive_commander` restrito a contexto competitivo real;
- impedir que Commander casual consuma prioridade competitiva por default;
- preservar `source_chain` apenas como evidência estratégica auditavel;
- manter `generate` e `optimize` separados de promoção automática.

### Arquivos alterados nesta etapa

- `server/lib/ai/optimize_runtime_support.dart`
- `server/lib/ai/optimize_complete_support.dart`
- `server/routes/ai/optimize/index.dart`
- `server/test/optimize_runtime_support_test.dart`

### Comandos rodados

```bash
cd server && dart analyze lib/meta lib/ai bin routes test

cd server && dart test -r compact \
  test/meta_deck_reference_support_test.dart \
  test/optimize_runtime_support_test.dart \
  test/commander_reference_atraxa_test.dart \
  test/optimize_learning_pipeline_test.dart \
  test/ai_generate_create_optimize_flow_test.dart
```

### Fatos provados por codigo

#### 1. `generate` ja estava commander-aware

Leitura comprovada antes do patch:

- `routes/ai/generate/index.dart` ja resolvia `commanderMetaScope` apenas quando o prompt indicava `competitive_commander` ou `duel_commander`
- nenhum ajuste adicional foi necessario em `generate` nesta etapa

#### 2. `optimize` estava forçando `competitive_commander` em todo Commander

Problema comprovado no codigo anterior:

- `routes/ai/optimize/index.dart` resolvia `commanderMetaScope` para `competitive_commander` nos dois ramos do ternario
- `prepareCompleteCommanderSeed(...)` carregava referencias com `metaScope: 'competitive_commander'` de forma fixa

Impacto:

- Commander casual podia receber prioridade competitiva externa sem prova de intenção high power/cEDH

#### 3. `optimize` e `complete` agora so usam referencias competitivas em bracket `>= 3`

Patch aplicado:

- novo helper `resolveCommanderOptimizeMetaScope(...)`
- retorno `competitive_commander` apenas quando:
  - `deckFormat == 'commander'`
  - `bracket >= 3`
- retorno `null` para Commander casual e formatos nao-Commander

Efeito comprovado:

- `routes/ai/optimize/index.dart` passa a pular a query de meta competitiva quando o escopo retorna `null`
- `server/lib/ai/optimize_complete_support.dart` so carrega `loadCommanderMetaReferenceSelection(...)` e `loadCommanderCompetitivePriorities(...)` quando o escopo e competitivo
- fora disso, o seed continua apoiado em `commanderReferenceProfile` / fallback casual ja existente

#### 4. O bloqueio fora da identidade de cor continua preservado

Cobertura mantida:

- `shouldKeepCommanderFillerCandidate(...)` continua barrando sugestoes fora da identidade do comandante
- nenhum relaxamento foi introduzido nesta etapa

#### 5. Evidência meta continua sendo sinal estratégico, nao copia cega

Estado comprovado:

- `meta_deck_reference_support.dart` segue resumindo `source_chain` em texto humanizado
- o texto de evidência nao expõe URL bruta nem despeja `research_payload` completo no prompt
- as referencias continuam entrando como pool/prioridade, nao como import direto da decklist externa

### Testes focados desta etapa

Casos comprovados:

1. `resolveCommanderOptimizeMetaScope(...)` usa `competitive_commander` apenas para bracket `3+`
2. Commander casual (`bracket=2`) nao entra no escopo competitivo
3. `meta_deck_reference_support_test.dart` continua provando selecao por shell competitivo exato e bloqueio de `duel_commander` fora de escopo
4. `optimize_runtime_support_test.dart` continua cobrindo bloqueio de carta fora da identidade de cor

### Interpretacao

- o uso de referencias competitivas externas ficou alinhado com intenção/poder, nao com o simples fato do formato ser `commander`
- isso reduz risco de contaminar `optimize`/`complete` casual com staples cEDH sem contexto
- a promoção continua separada: sem `stage --apply` e sem `promotion --apply`, nao existe corpus externo live novo em `meta_decks`

### Gaps ainda abertos

1. cobertura live de `external` dentro de `meta_decks` continua **not proven** ate existir promoção real aprovada
2. inferência de intenção competitiva em `generate` ainda depende do texto do prompt; prompts vagos continuam sendo tratados de forma conservadora
3. telemetria explicita no payload final sobre qual referencia externa foi usada continua ausente e **not proven** como necessidade de produto

## Atualizacao E2E runtime do fluxo final

### Escopo desta rodada

Validacao pedida:

1. expandir `EDHTop16` em dry-run
2. validar no stage 2
3. provar que o stage 2 continua bloqueando importacao real
4. rodar promocao em dry-run
5. gerar relatorios de base/cobertura
6. provar consumo de referencia competitiva por `generate/optimize` sem `apply` destrutivo

### Comandos exatos rodados

```bash
cd server && dart analyze \
  bin/expand_external_commander_meta_candidates.dart \
  bin/import_external_commander_meta_candidates.dart \
  bin/promote_external_commander_meta_candidates.dart \
  bin/meta_report.dart \
  bin/meta_profile_report.dart \
  lib/meta/external_commander_deck_expansion_support.dart \
  lib/meta/external_commander_meta_candidate_support.dart \
  lib/meta/external_commander_meta_import_support.dart \
  lib/meta/external_commander_meta_promotion_support.dart \
  lib/meta/meta_deck_reference_support.dart \
  lib/ai/optimize_complete_support.dart \
  lib/ai/optimize_runtime_support.dart \
  routes/ai/generate/index.dart \
  routes/ai/optimize/index.dart \
  routes/ai/commander-reference/index.dart

cd server && dart test -r compact \
  test/meta_deck_reference_support_test.dart \
  test/meta_deck_analytics_support_test.dart \
  test/meta_deck_card_list_support_test.dart \
  test/meta_deck_commander_shell_support_test.dart \
  test/meta_deck_format_support_test.dart \
  test/external_commander_meta_candidate_support_test.dart \
  test/external_commander_meta_import_support_test.dart \
  test/external_commander_meta_promotion_support_test.dart

cd server && dart run bin/migrate_external_commander_meta_candidates.dart

cd server && dart run bin/expand_external_commander_meta_candidates.dart \
  --source-url=https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57 \
  --limit=8 \
  --output=test/artifacts/meta_e2e_runtime_2026-04-24.expansion.json

cd server && dart run bin/import_external_commander_meta_candidates.dart \
  test/artifacts/meta_e2e_runtime_2026-04-24.expansion.json \
  --dry-run \
  --validation-profile=topdeck_edhtop16_stage2 \
  --validation-json-out=test/artifacts/meta_e2e_runtime_2026-04-24.stage2.validation.json

cd server && dart run bin/import_external_commander_meta_candidates.dart \
  test/artifacts/meta_e2e_runtime_2026-04-24.expansion.json \
  --validation-profile=topdeck_edhtop16_stage2 \
  --imported-by=meta_deck_intelligence_2026_04_24_runtime_e2e

cd server && dart run bin/promote_external_commander_meta_candidates.dart \
  --report-json-out=test/artifacts/meta_e2e_runtime_2026-04-24.promotion_dry_run.json

cd server && dart run bin/meta_report.dart \
  > test/artifacts/meta_e2e_runtime_2026-04-24.meta_report.json

cd server && dart run bin/extract_meta_insights.dart --report-only \
  > test/artifacts/meta_e2e_runtime_2026-04-24.extract_report_only.txt

cd server && dart run bin/meta_profile_report.dart \
  > test/artifacts/meta_e2e_runtime_2026-04-24.meta_profile_report.json
```

Chamadas runtime HTTP:

```bash
# server local validado em http://127.0.0.1:18092/health

POST /auth/register
POST /auth/login
GET  /ai/commander-reference?commander=Kinnan%2C%20Bonder%20Prodigy&subformat=competitive_commander&limit=10
POST /ai/generate
  body: {
    "prompt": "Build a competitive commander cEDH Kinnan, Bonder Prodigy deck with fast mana and compact combo lines",
    "format": "Commander"
  }
POST /decks
  body: {
    "name": "Meta Runtime Kinnan E2E",
    "format": "commander",
    "description": "Runtime E2E deck for competitive reference validation",
    "cards": [{"name":"Kinnan, Bonder Prodigy","quantity":1,"is_commander":true}]
  }
POST /ai/optimize
  body: {
    "deck_id": "<deck criado>",
    "archetype": "combo",
    "bracket": 4,
    "keep_theme": true
  }
```

### Evidencia E2E do stage externo

#### 1. Expansao `EDHTop16` continua viva, mas com drift parcial

Resultado do dry-run:

- `expanded_count=4`
- `rejected_count=4`

Rejeicoes observadas:

- `topdeck_deckobj_missing=4`

Leitura:

- `EDHTop16 GraphQL` respondeu
- as entradas do torneio continuam acessiveis
- metade das paginas `TopDeck deck page` ainda expuseram `const deckObj = {...}`
- a outra metade ja mostra drift real de parser na pagina expandida

#### 2. Stage 2 validou os 4 decks expandidos

Resultado:

- `accepted_count=4`
- `rejected_count=0`

Legalidade resolvida no stage 2:

- `legal=3`
- `not_proven=1`
- `illegal=0`

Caso `not_proven` observado:

- `Scion of the Ur-Dragon`
- `unresolved_cards=["Prismari, the Inspiration"]`

Warnings recorrentes:

- `missing_color_identity` em todos os 4 candidatos

#### 3. Stage 2 bloqueou importacao real como esperado

Resultado:

- falha imediata por `topdeck_edhtop16_stage2 exige --dry-run`
- `0` rows novas em `external_commander_meta_candidates` nesta etapa

Leitura:

- o profile voltou ao contrato correto de validacao somente em artefato local
- o importador nao materializa mais nenhum staging a partir do stage 2
- a promocao continua separada e depende apenas de rows previamente validadas por outro gate

#### 4. Dry-run de promocao bloqueou corretamente

Resultado:

- `total=4`
- `promotable=0`
- `blocked=4`

Bloqueios em todos os casos:

- `validation_status_not_validated`
- `missing_or_invalid_legal_status`

Conclusao:

- o gate de promocao continua seguro
- nao houve escrita em `meta_decks`
- o bloqueio agora e intencional: stage 2 nao deve mais servir como atalho de persistencia

### Frescor atual da base

`meta_decks`:

| source | decks | min(created_at) | max(created_at) |
| --- | ---: | --- | --- |
| mtgtop8 | 641 | 2025-11-22 14:14:20+00 | 2026-04-23 20:02:52+00 |

`external` em `meta_decks`:

- **0 observado**

`external_commander_meta_candidates` apos a rodada:

- `candidate/<null>=4`

Leitura:

- frescor live continua comprovado apenas para `mtgtop8`
- presenca live de externo promovido em `meta_decks`: **nao comprovado**

### Cobertura real por formato e subformato

`meta_report.dart` e `meta_profile_report.dart` confirmaram:

| format | subformat | deck_count |
| --- | --- | ---: |
| cEDH | competitive_commander | 214 |
| EDH | duel_commander | 162 |
| ST | - | 46 |
| PI | - | 46 |
| VI | - | 44 |
| MO | - | 41 |
| PAU | - | 40 |
| LE | - | 40 |
| PREM | - | 8 |

Commander coverage derivada:

| format | subformat | with_commander_name | with_partner_commander_name | with_shell_label | with_strategy_archetype |
| --- | --- | ---: | ---: | ---: | ---: |
| cEDH | competitive_commander | 214 | 81 | 214 | 214 |
| EDH | duel_commander | 162 | 5 | 162 | 162 |

### Cobertura real por identidade de cor

Top grupos `source+format+color+shell`:

| source | format | subformat | colors | shell | deck_count |
| --- | --- | --- | --- | --- | ---: |
| mtgtop8 | EDH | duel_commander | UR | spider-man | 27 |
| mtgtop8 | cEDH | competitive_commander | UG | kinnan | 20 |
| mtgtop8 | cEDH | competitive_commander | BR | kraum | 18 |
| mtgtop8 | cEDH | competitive_commander | WG | sisay | 8 |

Top grupos `source+format+color+strategy`:

| source | format | subformat | colors | strategy | deck_count |
| --- | --- | --- | --- | --- | ---: |
| mtgtop8 | EDH | duel_commander | UR | control | 33 |
| mtgtop8 | cEDH | competitive_commander | BR | combo | 30 |
| mtgtop8 | cEDH | competitive_commander | BRG | combo | 17 |
| mtgtop8 | EDH | duel_commander | RG | aggro | 15 |
| mtgtop8 | EDH | duel_commander | UB | control | 15 |

Cobertura externa promovida por cor:

- **nao comprovada**

### Prova runtime de referencia competitiva

#### `GET /ai/commander-reference`

Comandante consultado:

- `Kinnan, Bonder Prodigy`
- `subformat=competitive_commander`

Resultado:

- `status=200`
- `meta_decks_found=49`
- `model.type=commander_competitive_reference`
- `model.meta_scope=competitive_commander`
- `meta_scope_breakdown={"competitive_commander":49}`

Top cartas retornadas:

- `Command Tower`
- `Gemstone Caverns`
- `Mana Vault`
- `Sol Ring`
- `Birds of Paradise`

Shells de amostra:

- `Thrasios, Triton Hero + Tymna the Weaver` (`control`)
- `Kinnan, Bonder Prodigy` (`combo`)
- `Akiri, Line-Slinger + Thrasios, Triton Hero` (`combo`)

Leitura:

- o motor de referencia competitiva respondeu com corpus real
- o corte foi explicitamente `competitive_commander`

#### `POST /ai/optimize`

Deck runtime criado:

- `Meta Runtime Kinnan E2E`
- somente `Kinnan, Bonder Prodigy` como comandante

Resultado:

- `status=200`
- `mode=complete`
- `additions_count=78`
- `removals_count=0`

Evidencia mais forte de consumo competitivo observada no log do servidor:

- `Optimize commander priority pool carregado: 120 cartas (competitive_meta_exact_shell_match)`

Status desta afirmacao:

- **comprovado**

Leitura:

- `optimize` usou referencia competitiva real para montar o `priority pool`
- o match foi forte o bastante para cair em `exact_shell_match`

#### `POST /ai/generate`

Prompt runtime:

- `Build a competitive commander cEDH Kinnan, Bonder Prodigy deck with fast mana and compact combo lines`

Resultado:

- `status=422`
- `error="Generated deck failed validation"`
- `meta_context_used=false`

Status desta afirmacao:

- uso de referencia competitiva por `generate` nesta rodada: **nao comprovado**

Leitura:

- o endpoint nao expôs uso de meta nessa chamada
- isso pode ser problema de selecao de contexto por keyword, de resposta do modelo, ou de falha de validacao antes de a evidencia ficar observavel
- o comportamento precisa de prova dedicada antes de ser tratado como fluxo validado

### Interpretacao estrategica absorvivel por `optimize` e `generate`

1. `competitive_commander` continua comprimido em shells de combo com mana base curta, muitos artefatos e interacao instant-speed alta
2. `Kinnan` aparece como shell `UG` muito concentrado em mana explosiva + artefatos + aceleracao de criatura
3. `Kraum/Tymna` continua sendo shell `BR`/multicolor de alta densidade de interacao, tutor e linha compacta
4. `duel_commander` segue mais pesado em `control` e `aggro`, com land count muito acima de `cEDH`

Implicacoes praticas:

- `optimize` deve manter priorizacao de `competitive_commander` para `bracket >= 3`
- `generate` nao deve reaproveitar `duel_commander` como se fosse Commander multiplayer amplo
- decks cEDH incompletos continuam se beneficiando mais de `priority pool` por shell do que de staples genericos

### Menores proximas acoes tecnicas

1. manter `topdeck_edhtop16_stage2` como gate exclusivamente de validacao e artefato local
2. se staging real voltar a ser necessario, criar um passo separado e explicito depois do aceite stage 2
3. criar uma prova runtime dedicada para `generate` que exponha se `meta_context_used` veio de `competitive_commander` ou nao

### Proximos riscos

1. `topdeck_deckobj_missing=4/8` mostra drift real do parser de expansao
2. `generate` ainda nao tem prova runtime consistente de uso de referencia competitiva
3. cobertura externa em `meta_decks` segue `nao comprovada` porque nenhuma row foi promovida nesta rodada

## Atualizacao do profile stage2 — dry-run only

### Comandos desta correcao

```bash
cd server && dart analyze
cd server && dart test
cd server && dart run bin/import_external_commander_meta_candidates.dart \
  test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json \
  --dry-run \
  --validation-profile=topdeck_edhtop16_stage2 \
  --validation-json-out=test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json
cd server && dart run bin/import_external_commander_meta_candidates.dart \
  test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json \
  --validation-profile=topdeck_edhtop16_stage2 \
  --imported-by=meta_deck_intelligence_2026_04_24_stage2_fix
```

### Evidencia

- `dart analyze`: sem issues
- `dart test`: `All other tests passed!`
- stage 2 em `--dry-run`: `accepted_count=4`, `rejected_count=0`
- tentativa sem `--dry-run`: bloqueada no parse com `topdeck_edhtop16_stage2 exige --dry-run`

### Leitura

- o profile `topdeck_edhtop16_stage2` voltou a cumprir o contrato pedido
- a validacao commander-aware continua ativa em artefato local
- a base armazenada e a cobertura real do corpus nao mudaram nesta correcao
