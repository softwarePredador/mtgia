# Relatorio Meta Deck Intelligence

Data: 2026-04-23

## Objetivo

Validar se a rotina de busca de `meta_decks` ainda funciona, medir a cobertura real da base atual e apontar o que esses decks ensinam para o motor do produto.

## Pipeline atual comprovado

### Fonte externa

O pipeline atual puxa listas de:

- `https://www.mtgtop8.com`

Script principal:

- `server/bin/fetch_meta.dart`

### Fluxo de ingestao

O script:

1. abre a pagina de formato `format?f=<code>`
2. extrai links `event?e=...`
3. visita cada evento
4. tenta localizar decks no evento
5. monta `deckUrl`
6. extrai `deckId`
7. baixa a lista por `mtgo?d=<deckId>`
8. salva em `meta_decks`

Formatos suportados hoje:

- `ST`
- `PI`
- `MO`
- `LE`
- `VI`
- `EDH`
- `cEDH`
- `PAU`
- `PREM`

### Consumo posterior

Os `meta_decks` alimentam:

- `server/bin/extract_meta_insights.dart`
- `server/bin/meta_report.dart`
- `server/bin/meta_profile_report.dart`
- `server/doc/DECK_ENGINE_CONSISTENCY_FLOW.md`

Uso esperado no produto:

- sinal de priorizacao
- base para `card_meta_insights`
- base para `synergy_packages`
- base para `archetype_patterns`

## Validacao executada

### Comandos rodados

```bash
curl -I -L --max-time 20 'https://www.mtgtop8.com/format?f=EDH'
cd server && dart run bin/meta_report.dart
cd server && dart run bin/meta_profile_report.dart
python3 - <<'PY'
import requests,re
html=requests.get('https://www.mtgtop8.com/format?f=EDH',timeout=20).text
links=sorted(set(re.findall(r'event\\?e=\\d+', html)))
print('event_links', len(links))
print('\\n'.join(links[:10]))
PY
python3 - <<'PY'
import requests,re
html=requests.get('https://www.mtgtop8.com/event?e=83905',timeout=20).text
print('hover_tr', len(re.findall(r'class=\"hover_tr\"', html)))
print('deck_like_links', len(re.findall(r'href=\"([^\"]*event\\?e=\\d+&d=\\d+[^\"]*)\"', html)))
PY
python3 - <<'PY'
import psycopg2, json
conn=psycopg2.connect('postgresql://postgres:c2abeef5e66f21b0ce86@143.198.230.247:5433/halder')
cur=conn.cursor()
cur.execute(\"\"\"
SELECT COUNT(*)::int,
       COUNT(*) FILTER (WHERE COALESCE(TRIM(archetype),'')='')::int,
       MIN(created_at),
       MAX(created_at)
FROM meta_decks
\"\"\")
print(cur.fetchone())
conn.close()
PY
```

## Resultado da validacao

### 1. A fonte externa responde

Prova:

- `https://www.mtgtop8.com/format?f=EDH` respondeu `200 OK`

Leitura:

- a etapa de acesso HTTP ainda funciona

### 2. A pagina de formato ainda expõe eventos

Prova:

- a pagina `format?f=EDH` retornou `33` links `event?e=...`

Leitura:

- a primeira metade do crawler continua funcional

### 3. A pagina de evento ainda tem estrutura parecida o bastante

Prova:

- `event?e=83905` retornou HTML com `82` ocorrencias de `hover_tr`

Leitura:

- a estrategia de procurar linhas de deck por evento ainda tem base estrutural

### 4. O banco atual nao esta fresco

Prova:

- `total_meta_decks`: `325`
- `min_created_at`: `2025-11-22`
- `max_created_at`: `2026-02-27`

Leitura:

- a rotina existe e ja populou a base
- mas nao ha evidencia de renovacao recente em abril
- entao a busca nao esta operacionalmente confiavel como feed vivo hoje

### 5. O parse persistido esta quebrado em campos importantes

Prova:

- `blank_archetype`: `325`

Leitura:

- todos os registros atuais ficaram com `archetype` vazio
- isso indica que o crawler salva o deck list, mas nao extrai corretamente o nome do arquétipo
- o campo `placement` tambem ja aparece poluido nos samples do `meta_report.dart`, com texto inteiro da linha em vez de rank limpo

Conclusao tecnica:

- a rotina de busca funciona parcialmente
- a rotina de persistencia semantica nao esta saudavel

## Atualizacao apos hardening do crawler

Nesta mesma data, o crawler foi endurecido em:

- `server/lib/meta/mtgtop8_meta_support.dart`
- `server/bin/fetch_meta.dart`
- `server/routes/ai/commander-reference/index.dart`

Melhorias aplicadas:

- parser compartilhado para `event links`, `deck rows` e `placement`
- `fetch_meta.dart` com `--dry-run`
- `fetch_meta.dart` com `--refresh-existing`
- `fetch_meta.dart` com `--limit-events` e `--limit-decks`
- validacao live sem escrita obrigatoria em banco
- eliminacao do drift entre o script de fetch e o refresh de `commander-reference`

### Validacao do hardening

Comandos rodados:

```bash
cd server && dart test test/mtgtop8_meta_support_test.dart
cd server && dart analyze lib/meta/mtgtop8_meta_support.dart bin/fetch_meta.dart routes/ai/commander-reference/index.dart test/mtgtop8_meta_support_test.dart
cd server && dart run bin/fetch_meta.dart EDH --dry-run --limit-events=1 --limit-decks=3 --delay-event-ms=0 --delay-deck-ms=0
cd server && dart run bin/fetch_meta.dart EDH --limit-events=1 --limit-decks=1 --delay-event-ms=0 --delay-deck-ms=0
cd server && dart run bin/fetch_meta.dart EDH --refresh-existing --limit-events=1 --limit-decks=1 --delay-event-ms=0 --delay-deck-ms=0
```

Prova observada:

- `dry-run` validou `3` decks reais do evento `83905`
- `placement` foi extraido como `2`, `3` e `4`
- uma importacao real curta inseriu `Spider-man 2099`
- um registro existente corrompido foi reparado com `--refresh-existing`
- `meta_decks` passou para `326`
- `max(created_at)` passou para `2026-04-23`

Leitura atualizada:

- a busca `MTGTop8 -> parser -> export -> insert` ficou comprovada ponta a ponta
- o gap de implementacao em `fetch_meta.dart` para parser, validacao segura e reparo de existentes foi fechado
- o que continua pendente aqui ja nao e parser basico; e cobertura/frescura operacional, backfill da base antiga e expansao de fontes

### Script operacional de backfill

Para rodar reparo em lote dos registros antigos sem improvisar comando manual, o repositorio agora expõe:

- `scripts/backfill_mtgtop8_meta_repairs.sh`
- `server/bin/repair_mtgtop8_meta_history.dart`

Padrao:

- `dry-run` por default
- `--apply` para escrita real
- aceita `--format` ou `--formats`
- aceita limites curtos para saneamento progressivo

Exemplos:

```bash
./scripts/backfill_mtgtop8_meta_repairs.sh --formats EDH,cEDH --limit-events 1 --limit-decks 10
./scripts/backfill_mtgtop8_meta_repairs.sh --apply --formats EDH,cEDH --limit-events 3 --limit-decks 20
cd server && dart run bin/repair_mtgtop8_meta_history.dart --dry-run --formats EDH,cEDH --limit-events 20
cd server && dart run bin/repair_mtgtop8_meta_history.dart --apply --formats EDH,cEDH --limit-events 50
```

## Resultado consolidado apos backfill e reparo historico

Atualizado em: 2026-04-24

Rodadas executadas:

- backfill recente `EDH,cEDH` com `fetch_meta.dart`
- reparo historico Commander por `source_url` com `repair_mtgtop8_meta_history.dart`
- reparo historico completo dos formatos nao Commander com `repair_mtgtop8_meta_history.dart --apply --limit-events 100 --limit-rows-per-event 100`

Estado consolidado observado no banco:

- `meta_decks` total: `641`
- `mtgtop8_count`: `641`
- `blank archetype` total: `0`
- `blank placement` total: `0`
- `missing_matches` no reparo final: `0`

Estado por formato:

- `cEDH`: `214`, `blank_archetype=0`, `bad_placement=0`
- `EDH`: `162`, `blank_archetype=0`, `bad_placement=0`
- `ST`: `46`, `blank_archetype=0`, `bad_placement=0`
- `PI`: `46`, `blank_archetype=0`, `bad_placement=0`
- `VI`: `44`, `blank_archetype=0`, `bad_placement=0`
- `MO`: `41`, `blank_archetype=0`, `bad_placement=0`
- `PAU`: `40`, `blank_archetype=0`, `bad_placement=0`
- `LE`: `40`, `blank_archetype=0`, `bad_placement=0`
- `PREM`: `8`, `blank_archetype=0`, `bad_placement=0`

Validacao executada apos o reparo final:

```bash
cd server && dart test test/mtgtop8_meta_support_test.dart
cd server && dart analyze lib/meta/mtgtop8_meta_support.dart bin/repair_mtgtop8_meta_history.dart test/mtgtop8_meta_support_test.dart
cd server && dart run bin/meta_profile_report.dart
```

Resultados:

- `mtgtop8_meta_support_test.dart`: todos os testes passaram
- `dart analyze`: sem issues
- `meta_profile_report.dart`: confirmou `641` decks competitivos e `376` decks `EDH + cEDH`

Leitura final desta frente:

- a ingestao recente esta funcional
- o parser atual esta funcional
- o reparo historico de `archetype` e `placement` foi concluido para todos os formatos importados do MTGTop8
- nao ficou pendencia conhecida de implementacao no pipeline `MTGTop8 -> parser -> meta_decks`

## Decisao estrutural aplicada nesta rodada

Para nao misturar pesquisa web exploratoria com o corpus principal do motor, o repositorio agora tem uma fila controlada separada:

- tabela `external_commander_meta_candidates`
- migration `server/bin/migrate_external_commander_meta_candidates.dart`
- import controlado `server/bin/import_external_commander_meta_candidates.dart`
- workflow `server/doc/EXTERNAL_COMMANDER_META_CANDIDATES_WORKFLOW_2026-04-23.md`

Regra nova:

- pesquisa web multi-fonte entra primeiro em `external_commander_meta_candidates`
- so candidatos `validated` podem ser promovidos para `meta_decks`

## O que os decks meta ensinam

A base agora e util para aprender sinais competitivos com campos semanticos confiaveis:

### 1. Intencao do jogador competitivo

Essas listas tendem a maximizar:

- redundancia funcional
- compressao de curva
- consistencia de mana
- pacotes pequenos de sinergia real
- slots com papel claro

Em geral, o jogador nao esta enchendo tema. Ele esta tentando aumentar velocidade, reduzir draw morto, concentrar engine e evitar cartas de valor bonito mas pouco convergente.

### 2. Malicia competitiva aproveitavel

Os sinais mais valiosos para nos:

- cartas que aparecem juntas com alta recorrencia
- pacotes de protecao pequenos, mas decisivos
- proporcao real entre engine, ramp, interaction e fechamento
- compressao de wincons em slots de dupla funcao

Isso deve influenciar:

- `optimize`: priorizar pacotes mais coesos e nao apenas staples soltas
- `generate`: evitar listas tematicas demais e pouco funcionais

### 3. O que nao pode ser importado cegamente

Nao devemos copiar deck meta como se fosse verdade universal porque:

- meta local depende de formato
- cEDH nao equivale a Commander casual
- listas de torneio aceitam compromissos que podem piorar UX do usuario casual

Traducao correta:

- usar meta deck como sinal
- nao como molde final automatico

## Problemas fechados

### Problema 1 - ingestao parcial

Status:

- fechado

Evidencia:

- `fetch_meta.dart` ganhou parser compartilhado, `--dry-run`, `--refresh-existing` e limites operacionais
- importacao real curta inseriu deck novo com `archetype` e `placement` limpos
- reparo historico zerou `blank_archetype` e `bad_placement`

### Problema 2 - base desatualizada para Commander

Status:

- mitigado

Evidencia:

- `EDH` subiu para `162`
- `cEDH` subiu para `214`
- `max(created_at)` passou para 2026-04-23 na rodada de backfill recente

### Problema 3 - registros historicos corrompidos

Status:

- fechado

Evidencia:

- `265` registros nao Commander restantes foram reparados
- `missing_matches=0` no reparo final
- todos os formatos ficaram com `blank_archetype=0` e `bad_placement=0`

## Veredito

### A busca meta funciona?

Resposta curta:

- **sim, para MTGTop8**

O que esta comprovado:

- acesso a fonte
- descoberta de eventos
- parse de decks por evento
- export de listas por `deckId`
- persistencia em `meta_decks`
- reparo de registros existentes
- saneamento historico por `source_url`

### A base puxa de todas as cores e combinacoes possiveis?

- **nao da para afirmar ainda**

O banco agora esta semanticamente limpo, mas cobertura completa de todas as identidades Commander e uma meta de corpus, nao uma garantia do MTGTop8. O caminho correto e continuar alimentando `external_commander_meta_candidates` com pesquisa web multi-fonte e promover somente candidatos validados.

## Proximas acoes pequenas

1. gerar um relatorio automatico de cobertura Commander por identidade de cor apos cada ingestao
2. definir criterio minimo de cobertura Commander por mono, bi, tri, four-color, five-color e colorless
3. rodar o agente `meta-deck-intelligence-analyst` para pesquisar fontes externas e salvar candidatos em `external_commander_meta_candidates`
4. promover candidatos validados para `meta_decks` somente quando houver decklist verificavel e formato Commander/cEDH confirmado
5. usar `meta_profile_report.dart` como medicao recorrente depois de cada rodada de ingestao

## Menor proxima acao tecnica recomendada

Rodar um ciclo multi-fonte controlado:

```bash
cd server && dart run bin/import_external_commander_meta_candidates.dart candidates.json --dry-run
```

Depois, validar amostras e aplicar apenas candidatos confiaveis.
