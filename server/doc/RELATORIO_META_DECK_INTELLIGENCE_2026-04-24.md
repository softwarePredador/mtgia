# Relatorio Meta Deck Intelligence

Data: 2026-04-24

## Objetivo

Atualizar a leitura operacional de `meta_decks` depois do gate de promocao externa para que `extract_meta_insights.dart` e `meta_profile_report.dart` passem a diferenciar:

- `source=mtgtop8` vs `source=external`
- `subformat=competitive_commander` / `duel_commander`
- `shell_label`
- `strategy_archetype`

Sem destruir dados.

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
