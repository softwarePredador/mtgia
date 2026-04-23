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

Padrao:

- `dry-run` por default
- `--apply` para escrita real
- aceita `--format` ou `--formats`
- aceita limites curtos para saneamento progressivo

Exemplos:

```bash
./scripts/backfill_mtgtop8_meta_repairs.sh --formats EDH,cEDH --limit-events 1 --limit-decks 10
./scripts/backfill_mtgtop8_meta_repairs.sh --apply --formats EDH,cEDH --limit-events 3 --limit-decks 20
```

## Cobertura real da base atual

### Por formato

Base atual:

- `PI`: `46`
- `ST`: `46`
- `VI`: `44`
- `MO`: `41`
- `PAU`: `40`
- `LE`: `40`
- `EDH`: `33`
- `cEDH`: `27`
- `PREM`: `8`

Leitura:

- a base e ampla em formatos
- mas a fatia Commander, que mais importa para nosso carro-chefe, ainda e relativamente pequena: `60` decks somando `EDH + cEDH`

### Por identidade de cor em `EDH`

Comprovado hoje:

- `BGR`: `5`
- `BGU`: `1`
- `BR`: `3`
- `BU`: `2`
- `C`: `4`
- `G`: `2`
- `GRW`: `1`
- `GU`: `1`
- `R`: `1`
- `RU`: `6`
- `RUW`: `2`
- `U`: `3`
- `UW`: `1`
- `W`: `1`

### Por identidade de cor em `cEDH`

Comprovado hoje:

- `B`: `2`
- `BG`: `2`
- `BGR`: `2`
- `BGW`: `1`
- `BR`: `3`
- `BU`: `3`
- `BW`: `1`
- `G`: `1`
- `GU`: `5`
- `GW`: `6`
- `R`: `1`

### Leitura da cobertura de cores

Conclusao objetiva:

- a base atual **nao** cobre todas as combinacoes possiveis
- faltam varias shells Commander relevantes
- em `cEDH`, nao ha prova atual de:
  - `U`
  - `W`
  - `UR`
  - `UGW`
  - `WUB`
  - `WUBR`
  - `WUBRG`
  - `colorless`
- em `EDH`, tambem ha ausencia de muitas combinacoes bi, tri, four-color e five-color

Portanto:

- `meta_decks` hoje **nao** pode ser tratado como base completa de cobertura de cores/combinacoes

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

Mesmo com cobertura incompleta, a base ainda e util para aprender:

### 1. Intencao do jogador competitivo

Essas listas tendem a maximizar:

- redundancia funcional
- compressao de curva
- consistencia de mana
- pacotes pequenos de sinergia real
- slots com papel claro

Em geral, o jogador nao esta “enchendo tema”.

Ele esta tentando:

- aumentar velocidade
- reduzir draw morto
- concentrar engine
- evitar cartas de valor bonito mas pouco convergente

### 2. Malicia competitiva aproveitavel

Os sinais mais valiosos para nos:

- cartas que aparecem juntas com alta recorrencia
- pacotes de protecao pequenos, mas decisivos
- proporcao real entre engine, ramp, interaction e fechamento
- compressao de wincons em slots de dupla funcao

Isso deve influenciar:

- `optimize`: priorizar pacotes mais coesos e nao apenas staples soltas
- `generate`: evitar listas “tematicas demais” e pouco funcionais

### 3. O que nao pode ser importado cegamente

Nao devemos copiar deck meta como se fosse verdade universal porque:

- meta local depende de formato
- cEDH nao equivale a Commander casual
- listas de torneio aceitam compromissos que podem piorar UX do usuario casual

Traducao correta:

- usar meta deck como sinal
- nao como molde final automatico

## Problemas encontrados

### Problema 1 - ingestao parcial

Status:

- comprovado

Sintoma:

- fonte responde
- eventos aparecem
- base existe
- mas `archetype` veio vazio em `325/325`

Impacto:

- empobrece `extract_meta_insights`
- dificulta aprendizado por arquétipo
- prejudica leitura estrategica do dado

### Problema 2 - cobertura Commander incompleta

Status:

- comprovado

Sintoma:

- apenas `33` decks `EDH`
- apenas `27` decks `cEDH`
- varias combinacoes de cor ausentes

Impacto:

- base insuficiente para dizer que “puxa de todas as cores e combinacoes”

### Problema 3 - base desatualizada

Status:

- comprovado

Sintoma:

- ultimo `created_at` em `2026-02-27`

Impacto:

- mesmo que o crawler continue tecnicamente funcional, a operacao hoje nao esta mantendo a base viva

## Veredito

### A busca meta funciona?

Resposta curta:

- **parcialmente**

O que esta funcionando:

- acesso a fonte
- descoberta de eventos
- existencia de base carregada

O que nao esta saudavel:

- frescor da base
- parse de `archetype`
- parse limpo de `placement`
- cobertura Commander por cores/combinacoes

### A base puxa de todas as cores e combinacoes possiveis?

- **nao**

O banco atual nao comprova isso.

## Proximas acoes pequenas

1. endurecer `fetch_meta.dart` para extrair `archetype` e `placement` com parse mais robusto do HTML atual
2. adicionar um modo `--dry-run` no crawler para validacao sem escrita
3. gerar um relatorio automatico de cobertura Commander por identidade de cor apos cada ingestao
4. definir criterio minimo de cobertura:
   - mono
   - bi
   - tri
   - four-color
   - five-color
   - colorless
5. rodar refresh controlado da base Commander e cEDH

## Menor proxima acao tecnica recomendada

Implementar primeiro:

- `fetch_meta.dart --dry-run --format EDH`

com saida contendo:

- eventos encontrados
- decks encontrados
- exemplo de `archetype`
- exemplo de `placement`
- quantidade que seria inserida

Isso fecha rapidamente a duvida operacional sem escrever no banco.
