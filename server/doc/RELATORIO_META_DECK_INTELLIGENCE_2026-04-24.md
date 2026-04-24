# Relatorio Meta Deck Intelligence

Data: 2026-04-24

## Veredito objetivo

- **O pipeline `MTGTop8 -> fetch_meta.dart -> meta_decks` continua funcionando depois do commit `9947a71`.**
- **A cobertura Commander do corpus atual nao e "Commander geral": o bucket `EDH` do pipeline e `Duel Commander`, enquanto `cEDH` e `Competitive EDH`.**
- **A base esta fresca em 2026-04-23, mas a analise Commander/cEDH ainda tem um risco estrutural aberto: os exports do MTGTop8 colocam o(s) comandante(s) no `Sideboard`, e os relatorios locais que ignoram sideboard subcontam o deck final e podem distorcer identidade de cor.**
- **Nao existe expansao multi-fonte validada hoje: `external_commander_meta_candidates` esta vazia.**

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

## Conclusao

- **Estado atual:** ingestao MTGTop8 funcional e base fresca.
- **Lacunas:** Commander multiplayer ainda nao esta coberto de forma provada; `external_commander_meta_candidates` esta vazia; `archetype` nao e taxonomia estrategica.
- **Riscos:** confundir `Duel Commander` com Commander geral e usar `archetype` como taxonomia estrategica pronta.
- **Proximo passo recomendado:** separar formalmente subformatos e iniciar staging controlado por `TopDeck.gg` + `EDHTop16`, sem promover nada para `meta_decks` antes de validacao.
