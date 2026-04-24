# Relatorio Meta Deck Intelligence

Data: 2026-04-24

## Veredito objetivo

- **O pipeline `MTGTop8 -> fetch_meta.dart -> meta_decks` continua funcionando depois do commit `9947a71`.**
- **A cobertura Commander do corpus atual nao e "Commander geral": o bucket `EDH` do pipeline e `Duel Commander`, enquanto `cEDH` e `Competitive EDH`.**
- **A base esta fresca em 2026-04-23, mas a analise Commander/cEDH ainda tem um risco estrutural aberto: os exports do MTGTop8 colocam o(s) comandante(s) no `Sideboard`, e os relatorios locais que ignoram sideboard subcontam o deck final e podem distorcer identidade de cor.**
- **Nao existe expansao multi-fonte validada hoje: `external_commander_meta_candidates` esta vazia.**
- **Apos o commit `21d0c4a`, o risco residual principal nao esta no crawler; esta nos consumidores que ainda fundem `EDH` e `cEDH` como se ambos fossem `Commander multiplayer meta`.**

## Pipeline atual comprovado

### Fonte externa provada em codigo

- `server/bin/fetch_meta.dart`
- `server/lib/meta/mtgtop8_meta_support.dart`

Mapeamento atual de formatos:

- `EDH` -> `Duel Commander`
- `cEDH` -> `Competitive EDH`

Fluxo provado:

1. abre `https://www.mtgtop8.com/format?f=<code>`
2. extrai eventos `event?e=...`
3. visita o evento
4. parseia `div.hover_tr`
5. extrai `deckUrl`, `deckId`, `placement`, rotulo do deck
6. baixa a lista por `mtgo?d=<deckId>`
7. persiste em `meta_decks`

Consumo local observado:

- `server/bin/extract_meta_insights.dart`
- `server/bin/meta_report.dart`
- `server/bin/meta_profile_report.dart`

## Comandos rodados

```bash
git --no-pager status --short
git --no-pager show --stat --oneline --no-patch 9947a71
git --no-pager rev-parse --short HEAD
```

```bash
cd server && dart test test/mtgtop8_meta_support_test.dart
cd server && dart run bin/fetch_meta.dart EDH --dry-run --limit-events=1 --limit-decks=3 --delay-event-ms=0 --delay-deck-ms=0
cd server && dart run bin/fetch_meta.dart cEDH --dry-run --limit-events=1 --limit-decks=3 --delay-event-ms=0 --delay-deck-ms=0
cd server && dart run bin/meta_report.dart
cd server && dart run bin/meta_profile_report.dart > /tmp/meta_profile_report_20260424.json && tail -n 120 /tmp/meta_profile_report_20260424.json
```

```bash
python3 - <<'PY'
from pathlib import Path
import psycopg2
env = {}
for line in Path('.env').read_text().splitlines():
    if '=' in line and not line.strip().startswith('#'):
        k, v = line.split('=', 1)
        env[k.strip()] = v.strip()
conn = psycopg2.connect(
    host=env['DB_HOST'],
    port=env['DB_PORT'],
    dbname=env['DB_NAME'],
    user=env['DB_USER'],
    password=env['DB_PASS'],
)
cur=conn.cursor()
cur.execute("""
SELECT COUNT(*)::int total,
       MIN(created_at),
       MAX(created_at),
       COUNT(*) FILTER (WHERE COALESCE(TRIM(archetype),'')='')::int blank_archetype,
       COUNT(*) FILTER (WHERE COALESCE(TRIM(placement),'')='')::int blank_placement,
       COUNT(*) FILTER (WHERE source_url ILIKE 'https://www.mtgtop8.com/%')::int mtgtop8_count
FROM meta_decks
""")
print(cur.fetchone())
conn.close()
PY
```

```bash
git --no-pager rev-parse --short HEAD
git --no-pager grep -n "meta_decks" -- server/bin server/lib server/routes docs scripts
git --no-pager grep -n "format IN ('EDH', 'cEDH')\\|addAll(\\['EDH', 'cEDH'\\])\\|Duel Commander\\|Competitive EDH" -- server/bin server/lib server/routes
cd server && dart run bin/meta_report.dart
cd server && python3 - <<'PY'
from pathlib import Path
import psycopg2

env = {}
for line in Path('.env').read_text().splitlines():
    line = line.strip()
    if not line or line.startswith('#') or '=' not in line:
        continue
    k, v = line.split('=', 1)
    env[k.strip()] = v.strip()

conn = psycopg2.connect(
    host=env['DB_HOST'],
    port=env['DB_PORT'],
    dbname=env['DB_NAME'],
    user=env['DB_USER'],
    password=env['DB_PASS'],
)
cur = conn.cursor()
cur.execute("""
SELECT format, COUNT(*)::int, MIN(created_at)::text, MAX(created_at)::text
FROM meta_decks
GROUP BY format
ORDER BY COUNT(*) DESC, format ASC
""")
print(cur.fetchall())
cur.execute("""
SELECT format,
       COUNT(*) FILTER (WHERE card_list ILIKE '%Sideboard%')::int,
       COUNT(*)::int
FROM meta_decks
WHERE format IN ('EDH','cEDH')
GROUP BY format
ORDER BY format
""")
print(cur.fetchall())
conn.close()
PY
```

```bash
python3 - <<'PY'
from pathlib import Path
import psycopg2
env = {}
for line in Path('.env').read_text().splitlines():
    if '=' in line and not line.strip().startswith('#'):
        k, v = line.split('=', 1)
        env[k.strip()] = v.strip()
conn = psycopg2.connect(
    host=env['DB_HOST'],
    port=env['DB_PORT'],
    dbname=env['DB_NAME'],
    user=env['DB_USER'],
    password=env['DB_PASS'],
)
cur=conn.cursor()
cur.execute("""
SELECT format, created_at::date AS day, COUNT(*)::int
FROM meta_decks
WHERE format IN ('EDH','cEDH')
GROUP BY format, created_at::date
ORDER BY format, day DESC
""")
for row in cur.fetchall():
    print(row)
conn.close()
PY
```

```bash
python3 - <<'PY'
from pathlib import Path
import psycopg2
env = {}
for line in Path('.env').read_text().splitlines():
    if '=' in line and not line.strip().startswith('#'):
        k, v = line.split('=', 1)
        env[k.strip()] = v.strip()
conn = psycopg2.connect(
    host=env['DB_HOST'],
    port=env['DB_PORT'],
    dbname=env['DB_NAME'],
    user=env['DB_USER'],
    password=env['DB_PASS'],
)
cur=conn.cursor()
for fmt in ['EDH','cEDH']:
    cur.execute("SELECT archetype, source_url, card_list FROM meta_decks WHERE format=%s ORDER BY created_at DESC LIMIT 1", (fmt,))
    print(cur.fetchone())
cur.execute("SELECT COUNT(*)::int FROM external_commander_meta_candidates")
print(cur.fetchone())
conn.close()
PY
```

## Validacao objetiva

### 1. A fonte externa responde

**Provado.**

- `fetch_meta.dart EDH --dry-run` acessou `format?f=EDH`
- `fetch_meta.dart cEDH --dry-run` acessou `format?f=cEDH`

### 2. A pagina de formato ainda expoe eventos

**Provado.**

- `EDH`: 1 evento processado no dry-run, `event?e=83905`
- `cEDH`: 1 evento processado no dry-run, `event?e=83812`

### 3. A pagina de evento ainda expoe estruturas esperadas pelo parser

**Provado.**

- `EDH`: `80` linhas `hover_tr`
- `cEDH`: `115` linhas `hover_tr`

### 4. O export de deck continua funcional

**Provado.**

Dry-run real:

- `EDH`: `Spider-man 2099`, `Lumra, Bellow Of The Woods`, `Spider-man 2099`
- `cEDH`: `Terra, Magical Adept`, `Kraum + Tymna`, `Rograkh + Silas Renn`

### 5. O banco local esta povoado e fresco

**Provado.**

| metrica | valor |
| --- | ---: |
| total `meta_decks` | 641 |
| `mtgtop8_count` | 641 |
| `blank_archetype` | 0 |
| `blank_placement` | 0 |
| `max(created_at)` | 2026-04-23 20:02:52Z |

### 6. Commander/cEDH ainda exigem leitura especifica de sideboard

**Provado.**

Todos os registros `EDH` e `cEDH` atuais contem marcador `Sideboard`:

| formato | decks com `Sideboard` | total |
| --- | ---: | ---: |
| `EDH` | 162 | 162 |
| `cEDH` | 214 | 214 |

Amostra real:

```text
=== EDH Ertai
...
1 Counterspell
Sideboard
1 Ertai Resurrected

=== cEDH Kraum + Tymna
...
1 Windswept Heath
Sideboard
1 Kraum, Ludevic's Opus
1 Tymna the Weaver
```

Leitura:

- o corpus salvo esta correto como export bruto do MTGTop8
- mas relatorios que ignoram sideboard em Commander/cEDH tratam decks de `100` cartas como `99` ou `98`
- isso afeta qualquer contagem de total de cartas e pode afetar identidade de cor em casos limite

## Frescor atual da base

### Frescor por formato

| formato | decks | primeiro registro | ultimo registro |
| --- | ---: | --- | --- |
| `cEDH` | 214 | 2026-02-12 | 2026-04-23 |
| `EDH` | 162 | 2025-11-22 | 2026-04-23 |
| `ST` | 46 | 2026-04-23 | 2026-04-23 |
| `PI` | 46 | 2026-04-23 | 2026-04-23 |
| `VI` | 44 | 2026-04-23 | 2026-04-23 |
| `MO` | 41 | 2026-04-23 | 2026-04-23 |
| `PAU` | 40 | 2026-04-23 | 2026-04-23 |
| `LE` | 40 | 2026-04-23 | 2026-04-23 |
| `PREM` | 8 | 2026-04-23 | 2026-04-23 |

### Frescor Commander por dia

`EDH`:

- `2026-04-23`: 129
- `2025-11-24`: 15
- `2025-11-22`: 18

`cEDH`:

- `2026-04-23`: 187
- `2026-02-27`: 7
- `2026-02-12`: 20

Leitura:

- ha backfill recente forte em 2026-04-23
- `cEDH` esta operacionalmente fresco
- `EDH` tambem foi refrescado, mas esse bucket representa `Duel Commander`, nao multiplayer Commander geral

## Cobertura real por formato e identidade de cor

## Regra de interpretacao

As contagens abaixo foram recalculadas **incluindo sideboard** para Commander/cEDH. Sem isso, os relatorios locais ficam errados em total de cartas e parcialmente errados em identidade.

### `EDH` no pipeline atual = `Duel Commander`

| metrica | valor |
| --- | ---: |
| decks | 162 |
| identidades cobertas | 23 / 32 |
| histogram de total de cartas | `100` em 162 / 162 |

Identidades com maior cobertura:

- `UR`: 30
- `G`: 13
- `C`: 13
- `UBG`: 13
- `BR`: 10
- `BRG`: 10
- `UB`: 9
- `WR`: 9

Identidades ausentes:

- `B`
- `WG`
- `WUG`
- `WBG`
- `UBR`
- `WURG`
- `WBRG`
- `UBRG`
- `WUBRG`

### `cEDH` no pipeline atual = `Competitive EDH`

| metrica | valor |
| --- | ---: |
| decks | 214 |
| identidades cobertas | 28 / 32 |
| histogram de total de cartas | `100` em 214 / 214 |

Identidades com maior cobertura:

- `BR`: 34
- `UG`: 24
- `WG`: 21
- `BRG`: 19
- `R`: 12
- `UBR`: 12
- `BG`: 11
- `UB`: 10

Identidades ausentes:

- `W`
- `WUBG`
- `WURG`
- `WBRG`

### O que isso prova

- **A cobertura cEDH por identidade de cor e boa, mas nao completa.**
- **A cobertura `EDH` tambem nao e completa e nao pode ser usada como proxy de Commander multiplayer.**
- **Nao esta provado que o corpus atual cobre Commander multiplayer por identidade de cor.**

## Lacunas de arquetipo

### 1. O campo `archetype` nao e um arquetipo normalizado em Commander/cEDH

**Provado por amostra e por distribuicao.**

Amostras recentes:

- `Kraum + Tymna`
- `Dargo + Tymna`
- `Rograkh + Silas Renn`
- `Spider-man 2099`
- `Tifa Lockhart`

Medicao:

| formato | decks | rotulos distintos | `+` / `&` explicitos | labels com keyword estrategica |
| --- | ---: | ---: | ---: | ---: |
| `EDH` | 162 | 79 | 5 | 4 |
| `cEDH` | 214 | 84 | 81 | 0 |

Leitura:

- em `cEDH`, o campo e essencialmente rotulo de comandante / partner shell
- em `EDH`, o campo tambem e majoritariamente nome de comandante
- o corpus **nao** traz hoje taxonomia estavel de arquétipo (`stax`, `turbo`, `midrange`, `control`, etc.) pronta para treino direto

### 2. Ha drift de canonicalizacao de rotulos

Exemplos reais:

- `Spider-man 2099` vs `Spider-Man 2099`
- `Slimefoot And Squee` vs `Slimefoot and Squee`
- `Aminatou, The Fateshifter` vs `Aminatou, the Fateshifter`

Leitura:

- cobertura de "arquetipo" esta inflada por diferencas de casing, pontuacao e grafia
- qualquer agrupamento por `archetype` hoje mistura duplicatas semanticas

### 3. `meta_profile_report.dart` agrupa "theme" por tokens do rotulo, nao por estrategia

Evidencia do proprio report:

- grupos como `thrasios`, `tayam`, `glarb`, `malcolm`

Leitura:

- isso pode ser util como proxy de shell/comandante
- isso **nao** prova cobertura de arquetipo estrategico

## Estado atual da fila externa

`external_commander_meta_candidates`:

- total: `0`
- status por validacao: vazio
- subformatos: vazio

Leitura:

- hoje nao existe amortecedor multi-fonte validado
- qualquer expansao Commander/cEDH fora do MTGTop8 ainda nao entrou nem como candidato controlado

## Fontes externas confiaveis para `external_commander_meta_candidates`

## Separacao obrigatoria

O bloco abaixo vem de **pesquisa web**; nao e prova local de banco/codigo.

### Fontes mais fortes para cEDH

1. **TopDeck.gg** - fonte de resultados de torneio com URLs de deck; melhor candidata para fila de `candidate` em cEDH.
2. **EDHTop16** - fonte de resultados de torneio focada em Commander competitivo; forte para cobertura por evento.
3. **MTG Melee** - suplementar; boa quando o evento realmente publica listas, mas cobertura cEDH e mais irregular.

### Fonte de referencia curada

4. **cEDH Decklist Database** - forte como referencia curada de shell/arquetipo; util para preencher lacunas de representacao, mas **nao** equivale automaticamente a resultado de torneio.

### Fontes amplas de hosting / agregacao

5. **Moxfield**
6. **Archidekt**
7. **EDHREC**

Uso recomendado:

- `Moxfield` / `Archidekt`: so como candidato estagiado e preferencialmente quando cruzado com evento real ou referencia curada
- `EDHREC`: sinal agregado por comandante, nao fonte canonica de deck competitivo individual

### O que esta provado vs nao provado

**Provado por pesquisa web:**

- TopDeck.gg e EDHTop16 sao fontes orientadas a resultados de torneio com deck URLs
- cEDH Decklist Database e referencia curada de shells competitivos
- Moxfield e Archidekt hospedam listas com URLs estaveis

**Nao provado aqui:**

- estabilidade de scraping / API publica dessas fontes
- licenca operacional para ingestao automatizada em larga escala
- que tags de usuario em Moxfield/Archidekt separem cEDH de Commander casual com confianca suficiente sem revisao

## Interpretacao estrategica util para `optimize` e `generate`

### Sinais validos para absorver

1. **cEDH atual esta concentrado em shells de comandante/partner bem definidos**, nao em taxonomia textual pronta.
   - exemplos fortes: `Kraum + Tymna`, `Thrasios + Tymna`, `Rograkh + Silas Renn`, `Kinnan, Bonder Prodigy`, `Sisay, Weatherlight Captain`
2. **As shells vencedoras comprimem funcoes**:
   - fast mana
   - interacao barata
   - tutor density
   - wincons compactas
3. **O bucket `EDH` do MTGTop8 tende a refletir 1v1 / Duel Commander**, com sinais de curva, tempo e consistencia que nao devem ser misturados cegamente com multiplayer casual.

### Traducao pratica

- `optimize`:
  - pode usar `cEDH` como sinal forte apenas quando o alvo for competitivo / bracket alto
  - deve separar `duel_commander` de multiplayer Commander
  - deve aprender packages por shell/comandante, nao confiar no campo `archetype` como taxonomia final
- `generate`:
  - precisa distinguir `commander shell` de `strategy label`
  - nao deve usar `EDH` do MTGTop8 como se fosse base geral de Commander multiplayer

## Riscos atuais

1. **Risco de interpretacao errada de formato**
   - `EDH` no pipeline e `Duel Commander`
   - tratar isso como Commander multiplayer generalista cria vies de geracao e optimize

2. **Risco de arquetipo falso**
   - o campo `archetype` nao e taxonomia competitiva; e principalmente label de comandante

3. **Risco de cobertura ilusoria**
   - o reparo do MTGTop8 esta fechado
   - mas a cobertura Commander multiplayer continua incompleta e sem segunda fonte validada

4. **Risco operacional de dependencia unica**
   - `external_commander_meta_candidates` esta vazia
   - hoje nao ha pipeline validado alem do MTGTop8

## Correcao aplicada em 2026-04-24

O risco de relatorio/insight incompleto por ignorar `Sideboard` em Commander foi corrigido no codigo.

Arquivos alterados:

- `server/lib/meta/meta_deck_card_list_support.dart`
- `server/bin/meta_profile_report.dart`
- `server/bin/extract_meta_insights.dart`
- `server/routes/ai/simulate-matchup/index.dart`
- `server/test/meta_deck_card_list_support_test.dart`

Regra implementada:

- em `EDH` e `cEDH`, `Sideboard` e tratado como zona do(s) comandante(s) e entra na lista efetiva
- nos demais formatos, `Sideboard` continua excluido da lista efetiva
- nomes com sufixo de set, como `Sol Ring (CMM)`, sao normalizados antes da agregacao

Validacao:

```bash
cd server && dart analyze lib/meta/meta_deck_card_list_support.dart bin/meta_profile_report.dart bin/extract_meta_insights.dart routes/ai/simulate-matchup/index.dart test/meta_deck_card_list_support_test.dart
cd server && dart test test/meta_deck_card_list_support_test.dart test/mtgtop8_meta_support_test.dart
cd server && dart run bin/meta_profile_report.dart
```

Resultado observado apos a correcao:

- `cEDH`: `214` decks, `avg_total_cards=100.0`
- `EDH`: `162` decks, `avg_total_cards=100.0`
- grupos por cor passaram a usar ordem canonica `WUBRG`

## Menores proximas acoes tecnicas

1. **Separar formalmente os buckets**
   - `EDH` do MTGTop8 -> `duel_commander`
   - `cEDH` -> `competitive_commander`
   - nao chamar o bucket `EDH` atual de Commander geral

2. **Introduzir campos derivados de shell**
   - `commander_name`
   - `partner_commander_name`
   - `shell_label`
   - deixar `archetype` estrategico para classificacao separada

3. **Abrir o funil multi-fonte sem promocao automatica**
   - primeiro `TopDeck.gg` e `EDHTop16`
   - depois `cEDH Decklist Database` como referencia curada
   - `Moxfield` / `Archidekt` apenas quando cruzados com evento ou curadoria

4. **Gerar um relatorio recorrente de cobertura**
   - por `subformat`
   - por identidade de cor
   - por completude de `100` cartas
   - por `% labels commander-like` vs `% arquétipos normalizados`

## Auditoria dos consumidores apos `21d0c4a`

### Resumo

O parser base ja separa corretamente:

- `EDH` -> `Duel Commander`
- `cEDH` -> `Competitive EDH`

O risco residual esta nos consumidores que ainda colapsam esses buckets em um unico conceito de "Commander meta".

### Matriz objetiva

| arquivo | risco | evidencia objetiva | correcao recomendada |
| --- | --- | --- | --- |
| `server/lib/ai/optimize_runtime_support.dart` | **alto** | `loadCommanderCompetitivePriorities()` consulta `format IN ('EDH', 'cEDH')` e devolve um unico pool competitivo para Commander. Isso mistura `Duel Commander` com `Competitive EDH` antes do ranking do `optimize`. | Separar pools por subformato. Para Commander multiplayer, priorizar `cEDH` e/ou fonte explicitamente multiplayer; tratar `EDH` apenas como `duel_commander` opt-in. |
| `server/lib/ai/optimize_complete_support.dart` | **alto** | `prepareCompleteCommanderSeed()` consome `loadCommanderCompetitivePriorities()`, entao o modo `complete` herda a mesma mistura `EDH+cEDH`. | Aplicar a mesma separacao no seed competitivo e expor `priority_source` por subformato. |
| `server/routes/ai/commander-reference/index.dart` | **alto** | O endpoint busca `meta_decks` com `format IN ('EDH', 'cEDH')`, faz refresh nos dois buckets e responde `commander_competitive_reference` sem distinguir escopo. | Retornar contagens e samples por subformato, incluir `subformat_scope` no payload e nao importar `EDH` por default quando a intencao for Commander multiplayer. |
| `server/routes/ai/generate/index.dart` | **alto** | Para `format=Commander/edh`, `metaFormats.addAll(['EDH', 'cEDH'])` e o prompt chama isso de `successful meta decks for inspiration`. | Em `generate`, nao fundir `EDH` e `cEDH` silenciosamente. Usar `cEDH`/`commander_reference` para multiplayer e exigir `subformat` explicito para incluir `Duel Commander`. |
| `server/routes/decks/[id]/analysis/index.dart` | **alto** | A tela de analise converte `format=commander` para `EDH` apenas, ou seja, usa `Duel Commander` como proxy de meta Commander e ainda ignora `cEDH`. | Parar de mapear `commander -> EDH`. Ou exige `subformat`, ou compara separadamente `duel_commander` e `competitive_commander`. |
| `server/bin/extract_meta_insights.dart` | **medio-alto** | O extrator consome todo `meta_decks` e persiste `common_formats`/`supported_formats` com os codigos crus. Como `EDH` aqui e `Duel Commander`, o conhecimento derivado pode ser lido depois como Commander geral. | Normalizar o subformato na extracao (`duel_commander`, `competitive_commander`) e nao tratar `archetype` de `EDH/cEDH` como taxonomia estrategica sem classificacao adicional. |
| `server/bin/meta_profile_report.dart` | **medio** | O report agora esta correto em total/cores por causa do parse Commander-aware, mas ainda publica `format: EDH/cEDH` sem label humano. Isso facilita leitura errada de cobertura como "Commander geral". | Incluir `format_label` e `subformat_scope` no JSON final. |
| `server/bin/meta_report.dart` | **medio** | O resumo de cobertura mostra apenas `EDH`/`cEDH` em `by_format` e `latest_samples`, sem deixar explicito que `EDH` = `Duel Commander`. | Enriquecer o report com label canonico por formato. |
| `server/bin/meta_report.py` | **medio** | Replica a mesma ambiguidade do report Dart. | Aplicar o mesmo mapeamento de labels ou descontinuar o script duplicado. |

### Consumidores sem risco semantico novo relevante

- `server/lib/meta/mtgtop8_meta_support.dart`: **seguro**; mapeamento explicito `EDH -> Duel Commander` e `cEDH -> Competitive EDH`.
- `server/lib/meta/meta_deck_card_list_support.dart`: **seguro**; corrige a leitura Commander-aware do `Sideboard` sem redefinir significado de formato.
- `server/routes/ai/ml-status/index.dart`: **baixo / neutro**; apenas conta registros em `meta_decks`.

## Implementacao aplicada em 2026-04-24

### Resumo da mudanca

Foi implementada uma camada formal e derivada de subformatos sem alterar os dados existentes em `meta_decks`.

Regra canonica agora aplicada em codigo:

- `meta_decks.format = EDH` -> `duel_commander`
- `meta_decks.format = cEDH` -> `competitive_commander`
- `commander` amplo -> uniao explicita de `duel_commander + competitive_commander`

### Arquivos alterados

- `server/lib/meta/meta_deck_format_support.dart`
- `server/lib/ai/optimize_runtime_support.dart`
- `server/routes/ai/commander-reference/index.dart`
- `server/routes/ai/generate/index.dart`
- `server/routes/decks/[id]/analysis/index.dart`
- `server/bin/extract_meta_insights.dart`
- `server/bin/fetch_meta.dart`
- `server/bin/meta_report.dart`
- `server/bin/meta_report.py`
- `server/bin/meta_profile_report.dart`
- `server/bin/basic_land_audit.dart`
- `server/lib/meta/external_commander_meta_candidate_support.dart`
- `server/test/meta_deck_format_support_test.dart`
- `server/test/external_commander_meta_candidate_support_test.dart`
- `server/doc/EXTERNAL_COMMANDER_META_CANDIDATES_WORKFLOW_2026-04-23.md`

### Comandos rodados nesta implementacao

```bash
cd server && dart analyze \
  lib/meta/meta_deck_format_support.dart \
  lib/meta/external_commander_meta_candidate_support.dart \
  lib/ai/optimize_runtime_support.dart \
  bin/fetch_meta.dart \
  bin/extract_meta_insights.dart \
  bin/meta_report.dart \
  bin/meta_profile_report.dart \
  bin/basic_land_audit.dart \
  routes/ai/commander-reference/index.dart \
  routes/ai/generate/index.dart \
  routes/decks/[id]/analysis/index.dart \
  test/meta_deck_format_support_test.dart \
  test/external_commander_meta_candidate_support_test.dart \
  test/meta_deck_card_list_support_test.dart \
  test/mtgtop8_meta_support_test.dart \
  test/optimize_runtime_support_test.dart
```

```bash
cd server && dart test \
  test/meta_deck_format_support_test.dart \
  test/external_commander_meta_candidate_support_test.dart \
  test/meta_deck_card_list_support_test.dart \
  test/mtgtop8_meta_support_test.dart \
  test/optimize_runtime_support_test.dart
cd server && dart test
```

```bash
cd server && dart run bin/fetch_meta.dart EDH --dry-run --limit-events=1 --limit-decks=2 --delay-event-ms=0 --delay-deck-ms=0
cd server && dart run bin/fetch_meta.dart cEDH --dry-run --limit-events=1 --limit-decks=2 --delay-event-ms=0 --delay-deck-ms=0
cd server && dart run bin/meta_report.dart
cd server && dart run bin/meta_profile_report.dart
```

### Evidencia objetiva

1. **Fonte e parser continuam vivos**
   - `EDH` dry-run: `Spider-man 2099`, `Lumra, Bellow Of The Woods`
   - `cEDH` dry-run: `Terra, Magical Adept`, `Kraum + Tymna`
2. **O log operacional agora publica o subformato derivado**
   - `format=EDH subformat=duel_commander`
   - `format=cEDH subformat=competitive_commander`
3. **A suite atual do servidor permaneceu verde**
   - `dart test`: `All other tests passed!` com `164 skipped tests`
4. **Cobertura atual continua igual, mas agora exposta sem ambiguidade**

| bucket | decks |
| --- | ---: |
| `competitive_commander` | 214 |
| `duel_commander` | 162 |

5. **Nao houve migracao nem rewrite de dados**
   - nenhuma coluna nova foi exigida
   - nenhum row existente em `meta_decks` foi alterado
   - `commander` generico pesquisado externamente permanece em staging e nao e promovido automaticamente para `EDH`

### Impacto tecnico por consumidor

- `optimize_runtime_support.dart`: `loadCommanderCompetitivePriorities()` agora consulta por escopo derivado; default = `competitive_commander`, sem misturar `EDH` por padrao.
- `commander-reference`: aceita `scope`/`subformat`, continua compativel com chamadas antigas e passa a responder `meta_scope` + `meta_scope_breakdown`.
- `generate`: continua aceitando `Commander`, mas o contexto de meta agora explicita quando a inspiracao veio de `duel_commander` ou `competitive_commander`; prompts com `cEDH`/`competitive` passam a filtrar para `competitive_commander`.
- `decks/[id]/analysis`: parou de mapear silenciosamente `commander -> EDH`; a comparacao agora usa escopo Commander amplo e devolve `format_label/subformat` do melhor match.
- `extract_meta_insights.dart`: futuros rebuilds vao persistir `duel_commander` / `competitive_commander` em `common_formats` e padroes analiticos, em vez de reespalhar o legado cru.
- `meta_report*` e `meta_profile_report.dart`: passam a expor `format_label` e `subformat`.
- `external_commander_meta_candidate_support.dart`: `commander` generico nao vira mais `EDH` legado por default; promocao automatica ficou restrita a `duel_commander` e `competitive_commander`.

## Conclusao

- **Estado atual:** ingestao MTGTop8 funcional e base fresca.
- **Lacunas:** Commander multiplayer ainda nao esta coberto de forma provada; `external_commander_meta_candidates` esta vazia; `archetype` nao e taxonomia estrategica.
- **Riscos:** confundir `Duel Commander` com Commander geral e usar `archetype` como taxonomia estrategica pronta.
- **Proximo passo recomendado:** se o produto precisar persistir `subformat` no banco, fazer isso por script dedicado `dry-run/apply`, preservando compatibilidade com os codigos legados enquanto a migracao nao termina.

## Implementacao aplicada em 2026-04-24 — shell de comandante derivado sem sobrescrever `archetype`

### Objetivo fechado

- **Fechado:** `meta_decks` agora separa formalmente `shell` de comandante e `strategy` heuristica para `EDH/cEDH`, sem reclassificar o `archetype` legado.

### Mudanca aplicada

Campos novos em `meta_decks`:

- `commander_name`
- `partner_commander_name`
- `shell_label`
- `strategy_archetype`

Regra aplicada:

1. `archetype` continua guardando o label bruto vindo da fonte (`Kraum + Tymna`, `Spider-man 2099`, etc.).
2. `commander_name` / `partner_commander_name` sao derivados da zona de comandante do export do MTGTop8 (`Sideboard` em Commander/cEDH), com fallback para o rotulo cru quando necessario.
3. `shell_label` guarda a forma canonica do shell (`Kraum, Ludevic's Opus + Tymna the Weaver`).
4. `strategy_archetype` guarda a leitura estrategica separada (`combo`, `control`, `aggro`, `midrange`, `aristocrats`, `ramp_value`, etc.).

### Arquivos alterados

- `server/lib/meta/meta_deck_commander_shell_support.dart`
- `server/test/meta_deck_commander_shell_support_test.dart`
- `server/bin/migrate_meta_decks.dart`
- `server/database_setup.sql`
- `server/bin/fetch_meta.dart`
- `server/bin/repair_mtgtop8_meta_history.dart`
- `server/bin/extract_meta_insights.dart`
- `server/bin/meta_report.dart`
- `server/bin/meta_report.py`
- `server/bin/meta_profile_report.dart`
- `server/lib/ai/optimize_runtime_support.dart`
- `server/routes/ai/commander-reference/index.dart`
- `server/routes/ai/generate/index.dart`

### Comandos rodados

```bash
cd server && dart analyze \
  bin/fetch_meta.dart \
  bin/repair_mtgtop8_meta_history.dart \
  bin/migrate_meta_decks.dart \
  bin/meta_report.dart \
  bin/meta_profile_report.dart \
  bin/extract_meta_insights.dart \
  lib/meta/meta_deck_commander_shell_support.dart \
  lib/ai/optimize_runtime_support.dart \
  routes/ai/commander-reference/index.dart \
  routes/ai/generate/index.dart \
  test/meta_deck_commander_shell_support_test.dart \
  test/meta_deck_card_list_support_test.dart \
  test/mtgtop8_meta_support_test.dart \
  test/meta_deck_format_support_test.dart \
  test/optimize_runtime_support_test.dart
```

```bash
cd server && dart test \
  test/meta_deck_commander_shell_support_test.dart \
  test/meta_deck_card_list_support_test.dart \
  test/mtgtop8_meta_support_test.dart \
  test/meta_deck_format_support_test.dart \
  test/optimize_runtime_support_test.dart
cd server && dart test
```

```bash
cd server && dart run bin/migrate_meta_decks.dart
cd server && dart run bin/repair_mtgtop8_meta_history.dart --dry-run --formats EDH,cEDH --limit-events 50 --limit-rows-per-event 100
cd server && dart run bin/repair_mtgtop8_meta_history.dart --apply --formats EDH,cEDH --limit-events 50 --limit-rows-per-event 100
cd server && dart run bin/fetch_meta.dart EDH --dry-run --limit-events=1 --limit-decks=2 --delay-event-ms=0 --delay-deck-ms=0
cd server && dart run bin/fetch_meta.dart cEDH --dry-run --limit-events=1 --limit-decks=2 --delay-event-ms=0 --delay-deck-ms=0
cd server && dart run bin/meta_report.dart
cd server && dart run bin/meta_profile_report.dart
```

### Evidencia objetiva

#### 1. Backfill aplicado de forma completa em Commander/cEDH

`repair_mtgtop8_meta_history.dart --apply` terminou com:

- `repaired=376`
- `missing_matches=0`

#### 2. Cobertura derivada atual em banco

```text
('cEDH', 214, 214, 81, 214, 214, 86, 6)
('EDH', 162, 162, 5, 162, 162, 57, 7)
```

Leitura dos campos:

```text
(format, deck_count, with_commander_name, with_partner_commander_name,
 with_shell_label, with_strategy_archetype, distinct_shells, distinct_strategies)
```

Isso prova:

- `cEDH`: `214/214` com `commander_name`, `214/214` com `shell_label`, `214/214` com `strategy_archetype`
- `EDH`: `162/162` com `commander_name`, `162/162` com `shell_label`, `162/162` com `strategy_archetype`

#### 3. O crawler live agora expõe shell vs strategy no dry-run

Exemplos provados:

- `EDH`: `Spider-Man 2099 -> shell=Spider-Man 2099, strategy=control`
- `EDH`: `Lumra, Bellow of the Woods -> shell=Lumra, Bellow of the Woods, strategy=midrange`
- `cEDH`: `Terra, Magical Adept -> shell=Terra, Magical Adept, strategy=combo`
- `cEDH`: `Kraum + Tymna -> shell=Kraum, Ludevic's Opus + Tymna the Weaver, strategy=combo`

#### 4. Os relatórios locais agora expõem shell e strategy separadamente

`meta_report.dart` passou a publicar:

- `commander_shell_strategy_coverage`
- `latest_samples[].commander_name`
- `latest_samples[].partner_commander_name`
- `latest_samples[].shell_label`
- `latest_samples[].strategy_archetype`

`meta_profile_report.dart` passou a publicar:

- `commander_shell_strategy_summary`
- `top_groups_format_color_shell`
- `top_groups_format_color_strategy`

Exemplo observado:

- `competitive_commander`: `214` decks, `86` shells distintos, `6` estrategias distintas
- `duel_commander`: `162` decks, `57` shells distintos, `7` estrategias distintas
- top shell atual forte: `spider-man` em `EDH UR` (`27`)
- top shell atual forte: `kinnan` em `cEDH UG` (`20`)
- top strategy atual forte: `control` em `EDH UR` (`33`)
- top strategy atual forte: `combo` em `cEDH BR` (`30`)

### Impacto tecnico real

- `optimize_runtime_support.dart` agora consegue priorizar Commander usando `commander_name` / `partner_commander_name` / `shell_label` antes de cair para busca textual no `card_list`.
- `commander-reference` deixa de devolver apenas o label cru e passa a expor o shell canonico e a strategy derivada nos `sample_decks`.
- `generate` passa a distinguir no prompt:
  - `Stored label`
  - `Commander shell`
  - `Strategy archetype`

Isso reduz o risco de o modelo ou o pipeline interpretarem `Kraum + Tymna` como se fosse um arquétipo textual autossuficiente, quando na pratica isso e um shell de comandante.

### Gaps observados que continuam abertos

1. `strategy_archetype` ainda e heuristica local; ela melhora muito a separacao semantica, mas **nao prova** taxonomia competitiva perfeita.
2. Commander multiplayer amplo continua `nao comprovado`; a tabela principal ainda representa `Duel Commander` (`EDH`) e `Competitive Commander` (`cEDH`), nao `Commander geral`.
3. Fontes externas continuam fora da tabela principal; `external_commander_meta_candidates` permanece o lugar correto para qualquer expansao multi-fonte.

### Menores proximas acoes tecnicas

1. Trocar consumidores restantes que ainda fazem fallback direto em `archetype ILIKE` por `shell_label` / `strategy_archetype` onde fizer sentido.
2. Medir regressao de `strategy_archetype` por shell recorrente (`Kraum + Tymna`, `Kinnan`, `Spider-Man 2099`) para descobrir onde a heuristica ainda varia demais.
3. Se o produto decidir endurecer a taxonomia, promover uma camada controlada de normalizacao de strategy por shell frequente, sem reescrever o `archetype` bruto vindo da fonte.

---

## 2026-04-24 — Plano de ingestao controlada Stage 1 para TopDeck.gg + EDHTop16

## Veredito desta rodada

- **O stage 1 foi implementado como `dry-run + schema validation`, sem qualquer promocao para `meta_decks`.**
- **O importador agora aceita um profile controlado `topdeck_edhtop16_stage1` e produz saida objetiva de `accept/reject` por candidato.**
- **Foi gerado um artefato JSON de candidatos e um artefato JSON de validacao em `server/test/artifacts/`.**
- **TopDeck.gg ficou provado como fonte de metadata publica de evento cEDH.**
- **EDHTop16 ficou provado como fonte de pagina de torneio cEDH, mas o endpoint legado `cedhtop16.com/api/req` nao devolveu JSON nesta rodada; API live atual permanece `not proven`.**

## Pipeline resumido desta fase

1. montar payload controlado em JSON
2. rodar `import_external_commander_meta_candidates.dart` em `--dry-run`
3. aplicar validacao de schema + politica de origem
4. salvar artefato `.validation.json`
5. encerrar sem gravar em `external_commander_meta_candidates`
6. encerrar sem promover nada para `meta_decks`

## Artefatos

- payload de candidatos:
  - `server/test/artifacts/external_commander_meta_candidates_topdeck_edhtop16_stage1_2026-04-24.json`
- resultado do dry-run:
  - `server/test/artifacts/external_commander_meta_candidates_topdeck_edhtop16_stage1_2026-04-24.validation.json`

## Comandos rodados

```bash
curl -L --max-time 20 -s 'https://topdeck.gg/event/the-quest-part-1'
curl -L --max-time 20 -s 'https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57'
curl -L --max-time 20 -s 'https://edhtop16.com/about'
python3 - <<'PY'
import requests
resp = requests.post(
    'https://cedhtop16.com/api/req',
    json={'standing': {'$lte': 2}},
    headers={'Content-Type': 'application/json', 'Accept': 'application/json'},
    timeout=20,
)
print(resp.status_code)
print(resp.headers.get('content-type'))
print(resp.text[:200])
PY
```

```bash
cd server
dart analyze bin/import_external_commander_meta_candidates.dart \
  lib/meta/external_commander_meta_candidate_support.dart \
  test/external_commander_meta_candidate_support_test.dart

dart test test/external_commander_meta_candidate_support_test.dart

dart run bin/import_external_commander_meta_candidates.dart \
  test/artifacts/external_commander_meta_candidates_topdeck_edhtop16_stage1_2026-04-24.json \
  --dry-run \
  --validation-profile=topdeck_edhtop16_stage1 \
  --validation-json-out=test/artifacts/external_commander_meta_candidates_topdeck_edhtop16_stage1_2026-04-24.validation.json
```

## Evidencia objetiva observada

### 1. TopDeck.gg expõe metadata publica de evento

**Provado.**

Leitura direta da pagina `https://topdeck.gg/event/the-quest-part-1` mostrou:

- titulo do evento: `The Quest for a Cause - $10k cEDH Charity Main Event`
- texto explicito de `charity cEDH event`
- secao de `About this event`

Conclusao:

- TopDeck.gg serve como fonte valida de `event metadata` para staging inicial
- expansao automatica de decklist individual a partir dessa pagina ainda e `not proven`

### 2. EDHTop16 expõe pagina publica de torneio cEDH

**Provado.**

Leitura direta da pagina `https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57` mostrou:

- nome do torneio: `cEDH @ Arcanum Sanctorum!`
- secao `Players`
- secao `Standings`
- referencia visivel a `TopDeck.gg`

Conclusao:

- EDHTop16 serve como fonte valida de `tournament metadata` para staging inicial
- decklist fetch automatizado a partir dessa pagina ainda e `not proven`

### 3. API legada do EDHTop16 nao ficou provada como fonte live atual

**Nao provado.**

Observacao executada:

- `POST https://cedhtop16.com/api/req` respondeu `200`
- `content-type: text/html`
- corpo retornou HTML do site, nao JSON de API

Conclusao:

- a documentacao historica existe
- mas a disponibilidade live do endpoint legado nao foi comprovada nesta rodada
- para stage 1, a fonte considerada valida e a pagina publica `edhtop16.com/tournament/...`, nao a API

## Regra de accept/reject implementada

O profile `topdeck_edhtop16_stage1` aceita um candidato somente quando:

1. `source_name` normaliza para `TopDeck.gg` ou `EDHTop16`
2. `source_url` bate com a fonte esperada
   - `TopDeck.gg` -> host `topdeck.gg` e path `/event/...`
   - `EDHTop16` -> host `edhtop16.com` e path `/tournament/...`
3. `format` persiste como `commander`
4. `subformat` normaliza para `competitive_commander`
5. `card_list` ou `card_entries` existe
6. `research_payload.collection_method` existe
7. `research_payload.source_context` existe
8. `validation_status != promoted`
9. `is_commander_legal != false`

Rejeita quando qualquer uma dessas regras falha.

## Resultado do dry-run controlado

| deck | source | decisao | evidencia |
| --- | --- | --- | --- |
| `Quest Dry-Run Rograkh Silas` | `TopDeck.gg` | `ACCEPT` | host/path corretos + `competitive_commander` + schema completo |
| `Arcanum Dry-Run Kraum Tymna` | `EDHTop16` | `ACCEPT` | host/path corretos + `competitive_commander` + schema completo |
| `Reject Broad Commander Example` | `TopDeck.gg` | `REJECT` | `invalid_subformat` |
| `Reject Bad Path Example` | `EDHTop16` | `REJECT` | `invalid_source_path` |

Resumo do artefato `.validation.json`:

- `accepted_count = 2`
- `rejected_count = 2`
- nenhuma escrita em banco
- nenhuma promocao para `meta_decks`

## Menores proximas acoes tecnicas

1. Automatizar descoberta de candidatos TopDeck.gg e EDHTop16 para preencher o payload JSON sem montagem manual.
2. Provar um caminho reprodutivel de decklist expansion por candidato antes de qualquer persistencia em `external_commander_meta_candidates`.
3. So depois habilitar `persist candidate` como fase separada.
4. Manter promocao para `meta_decks` desligada ate existir prova consistente de decklist completa + Commander legality + subformat correto.
