# Grupo P0 CORE — Catálogo read-only, contenção de upstream e arte de carta

Medição contra o código em `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`,
branch `codex/free-beta-release-candidate-2026-07-17`, HEAD `d15beb05b`
(2026-09-21, "docs: record the resumption point for the 2026-09-21 pause").
Medição original em 2026-09-21; conferida e completada em 2026-09-22 contra o mesmo HEAD
(`git status` não mostra nenhuma alteração de working tree nos arquivos de código deste
grupo — só docs). Somente leitura. Nenhum teste, build ou servidor foi executado — as
afirmações sobre teste dizem o que o arquivo de teste **afirma**, lido linha a linha, não
o resultado de uma execução.

**Revisão adversarial em 2026-09-22 (segundo revisor, mesmo HEAD).** Todas as 26
asserções foram reabertas: cada teste citado como prova foi lido inteiro, cada
`arquivo:linha` foi reconferido. O resultado está incorporado nas tabelas abaixo (as
linhas alteradas estão marcadas com **[REV]**) e resumido na seção "Verificação
adversarial" no fim. O veredito mudou para `BT-ART-01`: de `quase-la` para `metade`.
`BT-CAT-01/02/03` mantiveram o estado medido, com correções de inventário a favor delas.

**Conferência por amostragem em 2026-09-22 (terceira passagem, HEAD `d15beb05b`, inalterado).**
A execução anterior foi interrompida antes de devolver o resultado estruturado. Nesta
passagem o documento não foi remedido: (1) `git log -1` confirma o HEAD `d15beb05b`
(2026-09-21) e `git status --porcelain` nos caminhos de código do grupo (`server/routes/
{cards,sets,rules}`, `server/lib`, `server/bin`, `server/test`, `server/config`,
`app/lib/{features/cards,core/widgets,core/services,features/social}`, `app/test`) devolve
apenas um arquivo untracked fora do escopo (`server/test/community_marketplace_privacy_contract_test.dart`);
(2) `docs/generated/TASK_REGISTRY.json` e as linhas 384-387 do backlog batem com os
cabeçalhos de cada seção (ids, estados, dependências, aceites, `source_line`);
(3) três asserções `PRONTO_E_PROVADO` foram reabertas lendo o teste citado — ver a seção
"Conferência por amostragem" no fim. Nenhuma divergência; o estruturado foi devolvido a
partir deste texto.

**Revisão adversarial em 2026-09-22 (quarta passagem, revisor cético, HEAD `d15beb05b`).**
As 27 asserções foram reabertas (as 3 da amostragem anterior e as outras 24). Três
caíram: `BT-CAT-01` #1 e #5 (PRONTO_SEM_PROVA → PARCIAL) e `BT-ART-01` #3
(PRONTO_E_PROVADO → PARCIAL). Nenhuma subiu. `BT-CAT-01` passou de `metade` para
`mal-comecada`. Três achados novos mudam o planejamento do grupo e não apareciam em
nenhuma passagem anterior: (1) **a base do catálogo é gravada no grão Oracle, não no de
impressão** — o seed legado e o modo full do job gravam `scryfall_id = oracle_id` a
partir do `AtomicCards.json` (`server/bin/seed_database.dart:123-124`,
`server/bin/sync_cards_full_fast.py:200-202`); só o modo incremental grava impressões, e
só de sets novos; (2) **o único invólucro do job não roda contra a imagem atual da API**
— `cron_sync_cards.sh:19,61` faz `dart run bin/sync_cards.dart` num container cujo
runtime é só AOT desde `5edf7ce66` (`server/Dockerfile:22-31`); (3) **o job de
legalidades usado como "molde" nunca aplicou em produção**: é filtrado por
`catalog_private` e o daemon força o apply a `"0"` (`server/bin/manaloom_ops_daemon.py:236-247`,
`:711-745`). As linhas alteradas nesta passagem estão marcadas **[REV4]**. O detalhe está
na seção "Verificação adversarial (2026-09-22, quarta passagem)", no fim.

## Resumo do grupo

| Tarefa | Estado declarado | Estado medido | Asserções PRONTO_E_PROVADO / total | Arquivos a tocar | Testes a escrever | Migração | Prova viva |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `BT-CAT-01` | `TODO` | **mal-comecada [REV4]** (era metade) | 0 / 7 (**1** `PRONTO_SEM_PROVA`, **4** `PARCIAL`, 2 `NAO_ENCONTRADO`) **[REV4]** | **8 [REV4]** (≈12 se o grão for corrigido) | **6 [REV4]** (+ refator de injeção do cliente HTTP) | não de schema; **migração de dados provável** se o grão for corrigido **[REV4]** | não |
| `BT-CAT-02` | `BLOCKED_BY_P0` | mal-comecada | 0 / 5 | 7 | 6 (+ 3 testes a inverter) | não | não |
| `BT-CAT-03` | `BLOCKED_BY_P0` | mal-comecada | 0 / 6 | 8 **[REV]** | 7 **[REV]** | não (reuso de `rate_limit_events`) | não |
| `BT-ART-01` | `TODO` | metade | **4 / 9 [REV4]** (5 `PARCIAL`) | **10 (11 se o UA mudar) [REV4]** | **4 (5 se o UA mudar) [REV4]** | não | não exigida pelo aceite; recomendada para o gate nativo e o selo do herói do deck **[REV4]** |

Leitura em uma frase **[REV4]**: **a arte está provada no widget, mas não no caminho de
rede que a beta usa (mobile) nem no selo visual das superfícies pequenas (incluindo o
herói do Deck Details), e o próprio contrato descreve um gate que o código nativo não
tem; o catálogo está invertido em relação ao aceite e no grão errado.** Hoje as rotas de
leitura de catálogo são as que escrevem no banco e chamam o Scryfall; a base foi gravada
por carta Oracle, de modo que as impressões antigas só entram pelas mesmas rotas que
`BT-CAT-02` manda calar; e o job interno que deveria substituí-las não está agendado, não
roda na imagem de produção da API e, se registrado no daemon, cairia na mesma
neutralização de apply que o job de legalidades.

### Achados que valem para o grupo todo

1. **A contenção atual é o kill-switch global, não o desenho.** `catalog_private` está
   `release_capability: off` em `server/config/release_capabilities.json:19-24`, e o
   middleware nega antes de tocar o Postgres
   (`server/routes/_middleware.dart:105-144`). Toda rota `/cards*`, `/sets*`, `/rules*`
   cai nessa capability (`server/lib/release_capability_policy.dart:525-532`). Ou seja:
   hoje ninguém dispara upstream **porque nada do catálogo está aberto**. No dia em que a
   beta ligar `catalog_private`, os caminhos de escrita voltam a existir intactos. O eixo
   ABERTO está mascarando o eixo IMPLEMENTADO.
2. **Não existe `_middleware.dart` sob `server/routes/cards/`** (confirmado: os
   middlewares existentes são `binder`, `auth`, `trades`, `health`, `decks`,
   `conversations`, `ai`, `users`, `content-reports`, `community`, `import`,
   `notifications`, `moderation`). Logo, catálogo não tem rate limit próprio, não tem
   auth e não tem gate de sync. Qualquer solução de `BT-CAT-02`/`BT-CAT-03` provavelmente
   nasce como um `server/routes/cards/_middleware.dart` novo.
3. **Há um teste que trava o comportamento errado.** `server/test/cards_route_test.dart:56`
   — `'printings sync boundary is explicit and write-capable'` — afirma por leitura de
   fonte que `routes/cards/printings/index.dart` **contém** `INSERT INTO cards`,
   `INSERT INTO sets`, `_syncPrintingsFromScryfall` e `params['sync'] == 'true'`. Esse
   teste falha no dia em que `BT-CAT-02` for implementada. Ele precisa ser invertido, não
   apenas removido: vira o guard de "0 DML e 0 upstream".
4. **O teste de rota de catálogo é grep de string, não exercício de comportamento.**
   `server/test/cards_route_test.dart:27-118` lê os arquivos com `File(...).readAsStringSync()`
   e faz `expect(source, contains(...))`. Nenhum desses testes sobe handler, nenhum toca
   Postgres, nenhum conta chamadas HTTP. Para o eixo PROVADO do catálogo, a cobertura
   real é **zero**. **[REV]** Uma exceção pequena e a favor: `server/test/sets_route_test.dart:106-116`
   já tem um guard **negativo** (`isNot(contains('api.scryfall.com/sets'))`) — é o único
   "0 upstream" do catálogo, ainda que por grep.
5. **`BT-GOV-001` (dependência declarada de `BT-CAT-01` e `BT-ART-01`) está `PASS`** no
   registry. Nenhuma das duas está bloqueada por dependência. `BT-CAT-02` e `BT-CAT-03`
   estão marcadas `BLOCKED_BY_P0`, mas a dependência é **de produto, não de código**:
   ver a discussão em cada seção.
6. **[REV] O inventário de rotas de catálogo tem 7 entradas, não 3, e 5 já são
   read-only.** `find server/routes/cards server/routes/sets server/routes/rules`:
   `cards/index.dart` (http=0, DML=0), `cards/[id]/rulings/index.dart` (0/0),
   `cards/resolve/batch/index.dart` (0/0 — só `card_resolution_support.dart` e
   `deck_card_name_resolution_support.dart`, ambos sem `http` e sem DML),
   `sets/index.dart` (0/0), `rules/index.dart` (0/0); os dois que escrevem são
   `cards/resolve/index.dart` (5 `http.get`, 7 DML) e `cards/printings/index.dart`
   (3 `http.get`, 3 DML). A medição original não listou `resolve/batch` nem `rulings`;
   ambos precisam entrar no guard de 0 DML/0 upstream, mas não precisam de mudança de
   código.
7. **[REV] Já existe um job de catálogo registrado, com lock e budget — só não é o de
   cartas.** `server/bin/manaloom_ops_daemon.py:597-606` registra
   `manaloom_sync_card_legalities_from_scryfall` (cron `30 */6 * * *`, `flock` por
   lockfile), que roda `sync_card_legalities_from_scryfall.py` — dry-run por padrão,
   `--limit` (`:293`), `--delay_ms` entre lotes (`:335`), escopo estrito a
   `card_legalities`. Serve de molde e reduz a decisão de "daemon vs crontab".
   **[REV4] Correção: ele não está "em produção".** O daemon só executa jobs cujas
   capabilities estão abertas (`JOB_REQUIRED_CAPABILITIES`, `manaloom_ops_daemon.py:711-733`,
   filtro em `:736-745`; este exige `catalog_private`, que está off), e força
   `MANALOOM_SYNC_CARD_LEGALITIES_APPLY="0"` depois de ler o `.env`
   (`manaloom_ops_daemon.py:236-247`, com o comentário: esses caminhos ficam
   neutralizados "until their versioned receipt/state-machine contracts are
   implemented"). O `manaloom-ops` sobe com um único job habilitado,
   `hermes_cron_governor_report` (`docs/MAPA_OPERACIONAL_DO_PROJETO.md:256-259`;
   `docs/DECK_QUALITY_MODEL.md:241-262`: "nenhum job agendado escreve em PostgreSQL
   hoje"). O molde, portanto, também ensina a dependência que `BT-CAT-01` herda: registrar
   o job não basta, a escrita autônoma de catálogo precisa de um contrato de autorização de
   apply que ainda não existe.
8. **[REV4] A base do catálogo está no grão Oracle, não no de impressão.** O seed legado
   (`server/bin/seed_database.dart:9,123-124`) e o modo full do job
   (`server/bin/sync_cards.dart:122-127` → `server/bin/sync_cards_full_fast.py:174-229`)
   leem `AtomicCards.json` e gravam uma linha por carta Oracle com
   `scryfall_id = oracle_id` (`sync_cards_full_fast.py:200-202`). Quando a entrada não
   traz `identifiers.scryfallId` — o caso típico nos próprios testes do time
   (`server/test/sync_cards_test.dart:26-57`, imagem esperada `cards/named?...&set=lea`) —,
   a `image_url` gravada é o lookup nomeado `api.scryfall.com/cards/named`
   (`sync_cards_full_fast.py:151-155`). O modo incremental grava impressões
   (`server/lib/sync_cards_utils.dart:153-158`), mas só dos sets lançados depois do
   checkpoint (`:79-97`). As impressões anteriores entram **só** pelas rotas que
   escrevem: `/cards/printings?sync=true` dispara exatamente quando há ≤ 1 linha
   (`server/routes/cards/printings/index.dart:44`). O backfill que converteria parte disso
   (`server/bin/backfill_card_image_urls.py`) exige dupla aprovação e não tem receipt de
   aplicação no repositório. Três consequências: `BT-CAT-02` depende de **completude de
   impressões**, não só de frescor; em `BT-ART-01`, o lookup nomeado é a URL **primária**
   dessas linhas, não só fallback; e "exact printing first" entrega referência para a
   maior parte da base. A composição real em produção não foi medida: requer uma
   consulta read-only autorizada (contagem de `scryfall_id = oracle_id` e distribuição
   de host de `image_url`).
9. **[REV4] O único invólucro do job não roda na imagem de produção da API.**
   `server/bin/cron_sync_cards.sh:19,61` executa `docker exec -w /app <container da API>
   dart run bin/sync_cards.dart`. Desde `5edf7ce66` (2026-07-17) o runtime de
   `server/Dockerfile` recebe só os executáveis AOT, o script de boot e o JSON de
   capabilities (`:22-31`, com o comentário "Código-fonte, testes, ferramentas de build
   ... ficam fora da imagem final"): não há `bin/sync_cards.dart`, `pubspec` nem Python/
   `psycopg2` para o modo full (`sync_cards.dart:450-463`). O deploy usa esse Dockerfile
   (`docs/EASYPANEL_RUNBOOK_MTGIA_2026-03-24.md:117,133`). Só a imagem de ops tem fonte e
   `python3-psycopg2` (`server/Dockerfile.manaloom-ops:12-13,21`).
10. **[REV4] Os testes Flutter rodam só na VM.** Nenhum script ou gate chama
    `flutter test --platform chrome` (`scripts/quality_gate.sh`, `melos.yaml:22`,
    `scripts/manaloom_e2e_suite.sh:586-592`). Os ramos `kIsWeb` dos testes de imagem nunca
    executam, então nem a fiação Web do gate de rate limit é exercitada por teste.

---

## `BT-CAT-01` — Refresh de catálogo em job/CLI interno, com lock, idempotência, budget e audit

- Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:384` (registry `source_line: 384`)
- Aceite: *"Usuário/anônimo não dispara upstream; 200/404/429/5xx/timeout e retry cobertos."*
- Entrega: *"Refresh de catálogo em job/CLI interno, com lock, idempotência, budget e audit."*
- Estado declarado: `P0 CORE · TODO` · depende de `BT-GOV-001` (`PASS`)

### Asserções

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Existe um job/CLI interno que faz o refresh do catálogo | **PARCIAL [REV4]** (era PRONTO_SEM_PROVA) | `server/bin/sync_cards.dart:45` (`main`), invólucro em `server/bin/cron_sync_cards.sh:1-70` | `server/test/sync_cards_test.dart` exercita **só os extratores puros** (`extractCardRow`, `extractSetCardRow`, `getNewSetCodesSinceFromData`, `parseSinceDays`) — linhas 25, 262, 415, 505. Nenhum teste chama `main`, nenhum sobe Postgres, nenhum mede o ciclo. | prova de que o ciclo completo roda (dry-run com fixture, ou receipt de execução). **[REV]** Observação: `_httpGetWithRetry` (`:313`) chama `http.get` direto, sem cliente injetável — a matriz HTTP da asserção 6 exige esse refator antes de qualquer teste. **[REV4] O job existe como código, mas não como coisa executável em produção.** O único invólucro (`cron_sync_cards.sh:19,61`) roda `dart run bin/sync_cards.dart` dentro do container da API, cuja imagem de runtime só tem os executáveis AOT desde `5edf7ce66` (`server/Dockerfile:22-31`): sem fonte, sem `pubspec`, sem Python/`psycopg2` para o modo full (`sync_cards.dart:450-463`). Só a imagem de ops tem as duas coisas (`server/Dockerfile.manaloom-ops:12-13,21`). Além disso, o modo full grava a base no grão Oracle (achado 8) — o job, tal como está, não produz as impressões que as rotas de escrita hoje importam sob demanda |
| 2 | O job é idempotente | PRONTO_SEM_PROVA | upserts em `server/bin/sync_cards.dart:570` (`sets ON CONFLICT (code) DO UPDATE`), `:702` (`cards ON CONFLICT (scryfall_id) DO UPDATE`), `:849` (`card_legalities ON CONFLICT (card_id, format)`), checkpoint em `:93-94` e `:164-168` (`sync_state`). **[REV]** O guard mais forte é `:98-103`: se `mtgjson_meta_version` já é a versão remota e não há `--force`, o job retorna sem processar cartas. **[REV4] Correção: não é no-op.** Antes do guard, toda execução roda DDL (`:80-83`), baixa `SetList.json` (`:86`) e reescreve todas as linhas de `sets` com `updated_at = CURRENT_TIMESTAMP` (`:87`, `:568-577`); o guard só consulta `Meta.json` depois disso (`:89-103`). É idempotente no conteúdo, não no efeito. E o modo full (`sync_cards_full_fast.py:262-278`, `ON CONFLICT (scryfall_id)`) é idempotente sobre linhas no grão Oracle, que convivem com as linhas de impressão do incremental | **[REV]** `server/test/sync_cards_test.dart:8` é **grep de string** (`File('bin/sync_cards.dart').readAsStringSync()` + `contains(...)`): afirma que a fonte contém as duas cláusulas `LIKE 'https://cards.scryfall.io/%'`. Não executa o upsert. | teste que roda o job duas vezes sobre a mesma fixture e exige delta zero |
| 3 | O job tem **lock** (duas execuções não se sobrepõem) | PARCIAL | o mecanismo existe: `server/bin/manaloom_ops_daemon.py:982-984` usa `flock` com `Job.lockfile` (`:211`). Mas **`cron_sync_cards.sh` não está na lista `JOBS`** (`server/bin/manaloom_ops_daemon.py:565-712` — os jobs de carta registrados são `manaloom_sync_card_legalities_from_scryfall`, `manaloom_new_card_candidate_review`, `manaloom_card_data_gap_review`; `sync_cards` não aparece em lugar nenhum do daemon, `grep -n sync_cards` devolve vazio). Dentro de `sync_cards.dart` não há `pg_advisory_lock` nem lockfile. | nenhum | registrar o job no daemon **ou** um advisory lock próprio; hoje dois `docker exec` simultâneos rodam o sync em paralelo |
| 4 | O job tem **budget** (teto de custo/requisições/tempo por execução) | NAO_ENCONTRADO | nada em `sync_cards.dart`. `grep budget` em `server/bin/**` e `server/lib/**` só devolve `budget_tier` de deck (`candidate_quality_data_foundation.dart`), que é outro domínio. **[REV]** O job irmão `sync_card_legalities_from_scryfall.py` tem `--limit` (`:293`) e `--delay_ms` (`:335`) — é o desenho de budget a copiar. | nenhum | desenhar e implementar: teto de requisições upstream por execução, teto de linhas escritas, e corte explícito quando estourar |
| 5 | O job tem **audit** (registro do que a execução fez) | **PARCIAL [REV4]** (era PRONTO_SEM_PROVA) | `server/bin/sync_cards.dart:358-392` — `_logSync` insere em `sync_log` (`sync_type`, `records_inserted/updated/deleted`, `status`, `error_message`, `started_at`, `finished_at`). **[REV]** A tabela é criada por `server/database_setup.sql:1563-1574` (não pelo script), e já existe leitor: `server/bin/sync_status.dart:18-35` imprime `sync_state` e as últimas linhas de `sync_log`. | nenhum | (a) o `INSERT` está dentro de `try { ... } catch (_) {}` na linha 391: **falha de audit é engolida em silêncio**; (b) nenhum teste afirma que a linha de audit é escrita. **[REV4]** (c) O ramo "nada a fazer" (`:98-103`) retorna **sem nenhuma linha em `sync_log`**, embora a execução já tenha chamado o upstream duas vezes e reescrito todas as linhas de `sets` (`:86-89`); (d) a escrita de `sets` nunca é auditada como `sync_type` próprio (só `cards` e `card_legalities` no sucesso, `:172-197`, e `cards` na falha, `:205-215`). O audit registra parte das execuções, não "o que a execução fez" |
| 6 | 200/404/429/5xx/timeout e retry cobertos | PARCIAL | `server/bin/sync_cards.dart:313-356` (`_httpGetWithRetry`): 3 tentativas, backoff `attempt*2s`, trata `200`, retry em `429` e `>=500`, `TimeoutException` e `SocketException`, timeout de 3 min (`:42`) | nenhum | **404 não é tratado como caso nomeado** — cai no ramo "não-retryable" e vira `Exception` genérica. E nenhum teste cobre a matriz: são 5 cenários (200/404/429/5xx/timeout) sem um único caso de teste |
| 7 | Usuário/anônimo não dispara upstream | NAO_ENCONTRADO | o oposto é verdade: `server/routes/cards/resolve/index.dart:151-171` e `server/routes/cards/printings/index.dart:44-64` disparam Scryfall a partir de requisição de usuário. Ver `BT-CAT-02`. | nenhum | esta metade do aceite de `BT-CAT-01` **é** o escopo de `BT-CAT-02` — ver sobreposição abaixo |

### O que realmente falta

O job existe e é sério: retry com backoff, checkpoint por versão do MTGJSON, upsert em
três tabelas, log de sync. O que não existe é o que transforma um script em um job
operável: **ele não está agendado em lugar nenhum** (não está em `JOBS` do
`manaloom_ops_daemon.py`; `cron_sync_cards.sh` é uma receita de crontab manual que
descobre o container por `docker ps`), **não tem lock**, e **não tem budget**. O audit
existe mas é silenciosamente descartável. Concretamente **[REV]**: registrar o job no
daemon (`manaloom_ops_daemon.py`) com um wrapper `.sh` no padrão dos outros jobs
(`cd "$MTGIA_HOME" && ./server/bin/x.sh` — `cron_sync_cards.sh` usa `docker ps` e não
serve dentro do container de ops; é 1 script novo), adicionar advisory lock ou depender
do `flock` do daemon, implementar teto de requisições/linhas (`sync_cards.dart`), tornar
a falha de `_logSync` visível (`sync_cards.dart`), e injetar o cliente HTTP em
`_httpGetWithRetry` para a matriz ser testável — **5 arquivos** (daemon, wrapper novo,
`sync_cards.dart`, `sync_cards_utils.dart` se o retry for extraído, e o teste). Testes:
matriz HTTP 200/404/429/5xx/timeout (1), dupla execução idempotente (1), audit escreve
linha (1), lock impede concorrência (1) — **4 testes**. Sem migração de banco
(`sync_state` é criada pelo script em `:229`; `sync_log` já está em
`database_setup.sql:1563`). Sem decisão humana de produto — exceto uma: **qual é o
budget** (quantas requisições/quanto tempo por execução é aceitável), que é decisão de
custo do dono. Sem serviço externo novo (MTGJSON já é usado). Sem prova viva de UI.

**[REV4] Revisão do que falta.** O núcleo de ingestão (download com retry, checkpoint,
upsert) existe e não é o gargalo. O que falta é maior do que a medição anterior contou:

- **O job não roda em produção como está ligado** (achado 9): o invólucro aponta para a
  imagem AOT da API. O runner tem de viver na imagem de ops, que já tem fonte, Dart e
  `python3-psycopg2`. `cron_sync_cards.sh` precisa ser removido ou reescrito, não só
  "substituído dentro do ops".
- **Registrar no daemon não autoriza escrita** (achado 7): o daemon filtra por capability
  e neutraliza as flags de apply dos jobs que escrevem. Um job de catálogo sem flag de
  apply escaparia dessa governança; com flag, fica neutralizado como o de legalidades.
  Falta decidir e implementar o contrato de autorização de apply (receipt ou máquina de
  estados) que o próprio daemon cita em `:236-238`.
- **O audit é parcial** (asserção 5): execuções "nada a fazer" não deixam linha, e a
  escrita de `sets` nunca é auditada.
- **O grão** (achado 8) não está no aceite literal de `BT-CAT-01`, mas é o que
  `BT-CAT-02` precisa dele: sem uma fonte no grão de impressão (Scryfall
  `default_cards`, que `backfill_card_image_urls.py:28` já consome, ou MTGJSON
  `AllPrintings`) e sem reconciliar as linhas-alias Oracle referenciadas por
  `deck_cards`/`user_binder_items`, o refresh não substitui o self-healing.

Contagem revisada: `server/bin/<wrapper novo>.sh`, `server/bin/manaloom_ops_daemon.py`
(`JOBS`, `JOB_REQUIRED_CAPABILITIES`, flag de apply), `server/bin/sync_cards.dart`
(budget, lock ou advisory lock, audit do ramo "nada a fazer", falha de audit visível),
`server/lib/sync_cards_utils.dart` (retry com cliente injetável),
`server/bin/cron_sync_cards.sh` (remover ou reescrever), `server/test/sync_cards_test.dart`,
`server/test/manaloom_ops_daemon_test.py` e o runbook — **8 arquivos**; **≈12** se o grão
for corrigido (`sync_cards_full_fast.py`, `test_sync_cards_full_fast.py`, script de
reconciliação e a migração de dados). Testes: matriz HTTP (1), dupla execução sobre
Postgres descartável com delta zero (1), audit inclusive do ramo "nada a fazer" (1), lock
(1), **corte por budget (1, a medição anterior não o contava)**, registro no daemon
filtrado por capability e com apply neutralizado (1) — **6 testes**. Decisões humanas:
budget; **contrato de autorização de apply para escrita autônoma de catálogo**; e, se o
grão entrar, fonte, volume e o destino das linhas-alias Oracle.

### A dependência declarada é real?

`BT-GOV-001` está `PASS`, então nada bloqueia. A dependência **não declarada** que
descobri: o valor prático de `BT-CAT-01` depende de uma decisão de agendamento — o
`manaloom_ops_daemon.py` roda no container de ops, e registrar um job de catálogo lá
significa que o refresh passa a ser responsabilidade do daemon, não do crontab do
droplet. **[REV]** Essa decisão já foi tomada na prática para legalidades
(`manaloom_ops_daemon.py:597-606`), só não está escrita para cartas. **[REV4]** Mas a
mesma decisão trouxe a neutralização de apply (`:236-247`): o job de legalidades está
registrado e nunca aplicou. A dependência não declarada real é de **governança**: um
contrato de autorização de apply para escrita autônoma de catálogo. Nenhuma tarefa do
grupo o declara.

### Sobreposição

A cláusula *"usuário/anônimo não dispara upstream"* do aceite de `BT-CAT-01` é
literalmente o trabalho de `BT-CAT-02`. Uma das duas tarefas fecha essa frase; o backlog
conta ela duas vezes. `BT-PRICE-01` e `BT-FRESH-001`
(`docs/execution/PROPOSED_TASKS_DECK_QUALITY_2026-09-18.md:74`) dependem do mesmo job.
**[REV]** `sync_card_legalities_from_scryfall.py` (agendado, com lock, dry-run, `--limit`)
já cobre a parte "legalidades" do refresh; `BT-CAT-01` deveria declarar que herda esse
padrão em vez de desenhar do zero. **[REV4] Correção:** ele cobre a parte "legalidades"
só no desenho. Em produção não roda (capability off) e, se rodasse, seria dry-run
(`MANALOOM_SYNC_CARD_LEGALITIES_APPLY="0"` forçado em `manaloom_ops_daemon.py:247`). A
última data das legalidades é a mesma do catálogo: 2026-06-06, 104 dias
(`docs/DECK_QUALITY_MODEL.md:284-285`).

---

## `BT-CAT-02` — `/cards`, `/resolve` e `/printings` estritamente read-only

- Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:385` (registry `source_line: 385`)
- Aceite: *"Leitura causa 0 DML e 0 upstream calls; `sync=true` rejeitado; app não o envia."*
- Estado declarado: `P0 CORE · BLOCKED_BY_P0` · depende de `BT-CAT-01`

### Asserções

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | `GET /cards` é read-only (0 DML, 0 upstream) | PRONTO_SEM_PROVA | `server/routes/cards/index.dart:9-137` — só `SELECT` (`_buildQuery` `:145-380`) e `to_regclass` (`:382-393`). Nenhum `import 'package:http/http.dart'`. **[REV]** Idem para `cards/[id]/rulings/index.dart`, `cards/resolve/batch/index.dart` (`:1-8` importa só `card_resolution_support` e `deck_card_name_resolution_support`, ambos sem http/DML), `sets/index.dart` e `rules/index.dart` — 5 das 7 rotas de catálogo já cumprem o aceite. | `server/test/cards_route_test.dart:27` afirma apenas que a **fonte contém** certas strings de filtro/dedupe. Não afirma ausência de DML nem de upstream. `sets_route_test.dart:106-116` afirma ausência de `api.scryfall.com/sets` na fonte de `/sets` — único guard negativo. | guard que afirme a ausência (0 DML / 0 upstream) para as 7 rotas, não a presença de filtros |
| 2 | `POST /cards/resolve` é read-only | NAO_ENCONTRADO | o contrário: o docstring da rota diz explicitamente que é *"self-healing"* (`server/routes/cards/resolve/index.dart:11-21`). Caminho de miss: `_fetchFromScryfall` (`:152`, upstream em `:355`, `:387`, `:425`), depois `_insertScryfallCard` (`:164`, `INSERT INTO cards ... ON CONFLICT DO UPDATE` em `:532-542`), depois `_insertLegalities` (`:172`, `INSERT INTO card_legalities` em `:678-680`) e `INSERT INTO sets` em `:705-707`. O ramo de token (`:80-96`) faz o mesmo. Há um quinto `http.get` em `:601`. | `server/test/cards_route_test.dart:84` (`'resolve route preserves reserved-list metadata'`) **exige** que a fonte contenha `is_reserved = COALESCE` e `image_url = COALESCE(EXCLUDED...)` — ou seja, exige que o UPDATE exista. | remover o caminho de escrita/upstream do handler e decidir o que a rota responde num miss (404? 409 com "catálogo desatualizado"?) |
| 3 | `GET /cards/printings` é read-only | NAO_ENCONTRADO | `server/routes/cards/printings/index.dart:23` (`final syncFromScryfall = params['sync'] == 'true'`), `:44-64` (dispara em `data.length <= 1`), `_syncPrintingsFromScryfall` em `:309-484`: `http.get` para `api.scryfall.com` em `:318` e `:330`, `INSERT INTO cards ... ON CONFLICT DO UPDATE` em `:410-429`, `INSERT INTO sets` em `:468-471`. | `server/test/cards_route_test.dart:56` **afirma que a rota é write-capable** e lista, string por string, cada linha de escrita que precisa existir. | remover `sync`, remover `_syncPrintingsFromScryfall`, e **inverter esse teste** |
| 4 | `sync=true` é rejeitado | NAO_ENCONTRADO | nada rejeita. `server/lib/release_capability_policy.dart` inspeciona `queryParameters` apenas para `mode` (`:414`), nunca para `sync`. | nenhum | decidir entre 400 explícito (`sync_not_supported`) e ignorar em silêncio; implementar e testar |
| 5 | O app não envia `sync=true` | NAO_ENCONTRADO | o app envia: `app/lib/features/cards/providers/card_provider.dart:531` — `'/cards/printings?name=$encoded&limit=50&dedupe=false&sync=true'`, no método `resolveAndFetchPrintings` (`:525`), com o comentário `// Usa o parâmetro sync=true que importa automaticamente do Scryfall` (`:528`). Chamadores: `app/lib/features/binder/widgets/binder_item_editor.dart:173`, `app/lib/features/decks/screens/deck_details_screen.dart:1794` e `:1850`. | **[REV]** `app/test/features/cards/providers/card_provider_search_test.dart:312-320` não só cobre — **trava**: `expect(api.requestedEndpoints, ['/cards/printings?name=Sol+Ring&limit=50&dedupe=false&sync=true'])` é igualdade exata; remover o parâmetro quebra esse teste. | remover o parâmetro do provider, decidir o que os 3 chamadores fazem quando a edição não está no catálogo, atualizar o teste do app |

### O que realmente falta

Esta tarefa está **mal começada, não bloqueada**. Das sete rotas de catálogo, cinco
(`/cards`, `/cards/[id]/rulings`, `/cards/resolve/batch`, `/sets`, `/rules`) já cumprem
o aceite por implementação, e as outras duas violam-no por desenho declarado — o
comentário em `resolve/index.dart:16-17` chama isso de *"self-healing"*, que era a
feature. O trabalho é uma remoção com consequência de produto: hoje, quando o usuário
procura uma carta que não está no Postgres, o backend vai buscar no Scryfall e importa na
hora. Tirando isso, **a carta simplesmente não existe até o job rodar** — e o job não
está agendado (ver `BT-CAT-01`). Essa é a razão real do `BLOCKED_BY_P0`: não é que o
código não possa ser mudado, é que mudá-lo antes do job virar operável degrada o produto
de forma visível.

Concretamente: `server/routes/cards/resolve/index.dart` (remover ~330 linhas de
upstream+DML), `server/routes/cards/printings/index.dart` (remover ~180 linhas),
`server/routes/cards/_middleware.dart` (novo, para rejeitar `sync`),
`app/lib/features/cards/providers/card_provider.dart`, e os 3 chamadores do app
(`binder_item_editor.dart`, `deck_details_screen.dart` ×2 — mas é 1 arquivo cada, então
2) — **7 arquivos**. Testes: guard de 0 DML nas 7 rotas (pode ser 1 teste parametrizado,
conto 3 pela granularidade útil), guard de 0 upstream / nenhum import de `http` nas rotas
de catálogo (1), `sync=true` rejeitado (1), guard de que o app não emite `sync` (1) —
**6 testes**, mais a **inversão** do teste existente `cards_route_test.dart:56`, o ajuste
de `:84` e do teste do app `:312-320`. Sem migração. Sem serviço externo. **Exige decisão
humana de produto**: qual é a resposta de uma carta ausente do catálogo (404 puro, ou 409
com "catálogo em atualização", ou fila de pedido de refresh) — isso muda UI em Binder e
Deck Details. Sem prova viva obrigatória, embora a mudança de UX provavelmente peça
captura.

### A dependência declarada é real?

**Sim, e é mais forte do que o registry diz.** Não basta `BT-CAT-01` existir como
arquivo — ele precisa estar *agendado e com frescor aceitável*, senão remover o
self-healing quebra a busca de cartas novas. O documento de fila mediu o catálogo em 104
dias de idade (`docs/execution/PROPOSED_TASKS_DECK_QUALITY_2026-09-18.md:46`). Há
também uma dependência **não declarada** de UX: 3 telas do app mudam de comportamento.

**[REV4] A dependência é de completude, não só de frescor.** A base foi gravada no grão
Oracle (achado 8). O incremental só acrescenta impressões de sets novos, e as impressões
anteriores entram hoje **só** pelo self-healing que esta tarefa remove
(`printings/index.dart:44` dispara exatamente quando há ≤ 1 linha). Remover o
self-healing com o `BT-CAT-01` atual, mesmo agendado e em dia, deixa "Escolher edição" no
Binder (`binder_item_editor.dart:173`) e no Deck Details (`deck_details_screen.dart:1794`,
`:1850`) com uma única linha-alias para toda carta impressa antes da base. Antes de
planejar esta tarefa, é preciso medir em produção, com consulta read-only autorizada,
quantas linhas têm `scryfall_id = oracle_id`, e o `BT-CAT-01` precisa entregar uma fonte
no grão de impressão.

### Sobreposição

`BT-SCN-00` (backlog `:389`, *"chamada direta não aciona sync"*) é resolvida pelo mesmo
trabalho — se `/cards/resolve` e `/cards/printings` não escrevem mais, a chamada direta do
Scanner (`app/lib/features/scanner/services/scanner_card_search_service.dart:96`) deixa
de acionar sync por construção. `BT-DISC-01`, `BT-COL-01`, `BT-COL-03` e `BT-OFF-01`
todas declaram depender de `BT-CAT-02` e todas dependem, de fato, da mesma decisão de
"o que acontece quando a carta não está no catálogo".

---

## `BT-CAT-03` — Rate limit/cache/freshness/observabilidade do catálogo

- Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:386` (registry `source_line: 386`)
- Aceite: *"Limiter-down fail-closed quando caro; alerta de DML/upstream em leitura >0."*
- Estado declarado: `P0 CORE · BLOCKED_BY_P0` · depende de `BT-CAT-01`, `BT-CAT-02`

### Asserções

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Existe rate limit nas rotas de catálogo | NAO_ENCONTRADO | os únicos consumidores de rate limit são `server/routes/ai/_middleware.dart:66-72`, `server/routes/auth/_middleware.dart`, `server/routes/decks/[id]/ai-analysis/_middleware.dart`, `server/routes/decks/[id]/recommendations/_middleware.dart`, `server/routes/content-reports/index.dart` e `server/routes/community/decks/[id]/reports/index.dart`. Não há `_middleware.dart` sob `server/routes/cards/`, `sets/` ou `rules/`, e nenhuma dessas rotas tem auth (`grep authMiddleware|AuthUser` devolve vazio) — o bucket teria de ser por IP anônimo. | nenhum | criar o middleware e ligar `DistributedRateLimiter` |
| 2 | O limiter é **fail-closed** quando cai | NAO_ENCONTRADO | `server/lib/distributed_rate_limiter.dart:16-72` — `isAllowed` roda tudo dentro de `pool.runTx` e **não tem `try`/`catch`**. **[REV]** O invólucro compartilhado `server/lib/rate_limit_middleware.dart:244-266` (`_isAllowedDistributedIfAvailable`) é **fail-open por desenho**: em não-prod ou em erro devolve `null` e o chamador cai no limiter em memória (`:429`). E há um detalhe de Dart: o `try` envolve `return limiter.isAllowed(clientId)` **sem `await`** (`:263`), então uma rejeição do `Future` (Postgres fora) não é capturada pelo `catch (_)` de `:264` e sobe como exceção não tratada para `await _isAllowedDistributedIfAvailable` (`:399`) — o resultado prático é 500, não o 503 desenhado. **[REV4] Grau de certeza: plausível, não verificado.** A linha é real, mas o efeito depende da semântica de `return` de um `Future` dentro de `try` numa função `async`, e esta revisão não executa código. O conserto (`return await`) custa uma linha e vale fazer de qualquer jeito, mas o "vira 500" não deve entrar no plano como fato medido. Já existe vocabulário fail-closed reutilizável: `_rateLimitIdentityUnavailable()` (`:268-280`, `'rate_limit_backend': 'fail_closed'`, `Retry-After`). Não há conceito de "caro" vs "barato" em lugar nenhum. | nenhum | (a) classificar quais leituras de catálogo são "caras"; (b) capturar a falha do limiter (com `await`) e negar explicitamente nessas; (c) teste que derruba o limiter e exige 429/503 |
| 3 | Cache de catálogo existe | PARCIAL | `server/lib/endpoint_cache.dart:1-36` — cache em memória, por processo, TTL. Usado em `server/routes/cards/index.dart:49-54` e `:124-128` (TTL 45 s) e em `server/routes/sets/index.dart:23-33` e `:159`. **`/cards/printings`, `/cards/resolve` e `/rules` não usam cache nenhum.** **[REV]** O cache é **ilimitado**: `_store` é um `Map` sem teto (`:13`), a única remoção é lazy no `get` da mesma chave depois de expirar (`:18-20`), e `clearExpired()` (`:32-35`) **nunca é chamado** (`grep -rn clearExpired server/` só devolve a definição). A chave é a query string crua (`cards/index.dart:49`: `'cards:${uri.query}'`) numa rota sem auth — uma varredura anônima de queries únicas cresce a memória do processo sem limite. **[REV4]** Parâmetros desconhecidos também entram na chave (é a query crua), então `?name=x&z=<aleatório>` basta para gerar chaves únicas, cada uma com uma cópia do payload de até 200 cartas (`limit.clamp(1, 200)`). O singleton é o mesmo usado por `/ai/generate` e `/ai/archetypes` (`server/lib/ai_generate_performance_support.dart:417,468`; `server/routes/ai/archetypes/index.dart:128`), então o teto precisa valer para todos os usos. | nenhum teste em `server/test/` toca `EndpointCache` (o único arquivo com "cache" no nome é `optimize_cache_support_test.dart`, outro domínio) | cache nas rotas que faltam; **teto de entradas + varredura periódica**; e uma decisão sobre o cache ser por processo (não compartilhado entre réplicas, não invalidável pelo job de refresh) |
| 4 | O catálogo expõe **freshness** ao cliente | PARCIAL | só `/rules` expõe: `server/routes/rules/index.dart:84-104` (`_tryLoadRulesMeta` lê `rules_source_url`, `rules_version_date`, `rules_last_sync_at` de `sync_state`) e devolve em `meta` quando `?meta=true` (`:62-68`). `/cards` e `/sets` não devolvem nada de frescor (`grep last_sync|freshness|stale|sync_state` em `routes/cards/index.dart`, `routes/sets/index.dart`, `lib/sets_catalog_contract.dart`, `lib/card_query_contract.dart` devolve vazio); `/sets` só devolve headers de timing (`server/lib/sets_catalog_contract.dart:77`). | `server/test/sets_route_test.dart:118` afirma que os headers de telemetria não alteram o corpo — é sobre timing, não frescor. | expor `cards_last_sync_at` (já gravado por `sync_cards.dart:166-168`) em `/cards`; definir o limite de idade que vira `stale` |
| 5 | Há alerta quando leitura causa DML > 0 | NAO_ENCONTRADO | nada. A observabilidade do root middleware (`server/routes/_middleware.dart:265-334`) só dispara para caminhos sociais (`/trades`, `/conversations`, `/users`, `/community` — linhas `:273-281`) e só por lentidão ou status ≥ 400. Catálogo está fora. | nenhum | contador de DML por requisição de leitura + alerta; hoje não existe nem o contador |
| 6 | Há alerta quando leitura causa upstream > 0 | NAO_ENCONTRADO | nada. Não há instrumentação das chamadas `http.get` em `printings/index.dart:318,330` nem em `resolve/index.dart:355,387,425,601`. | nenhum | contador de chamadas upstream por requisição + alerta |

### O que realmente falta

Praticamente tudo, e por uma razão estrutural: **os dois alertas do aceite só fazem sentido
depois de `BT-CAT-02`**. "Alerta de DML/upstream em leitura > 0" é um detector de regressão
— ele existe para garantir que o zero conquistado em `BT-CAT-02` continue zero. Enquanto
as rotas escrevem por desenho, o alerta dispararia em toda requisição.

Concretamente **[REV]**: `server/routes/cards/_middleware.dart` (novo — rate limit +
contadores), `server/lib/distributed_rate_limiter.dart` (adicionar modo fail-closed),
`server/lib/rate_limit_middleware.dart` (`await` no `return` de `:263` e modo caro/barato),
`server/lib/endpoint_cache.dart` (teto de entradas + varredura + invalidação),
`server/routes/cards/index.dart` e `server/routes/cards/printings/index.dart` (expor
frescor + cache), `server/routes/sets/index.dart` (frescor), e um
`server/lib/catalog_read_observability.dart` novo — **8 arquivos**. Testes: limiter-down
→ fail-closed (1), classificação caro/barato (1), cache hit/miss e TTL (1), **cache
limitado sob varredura de chaves únicas (1)**, frescor presente e `stale` acima do limite
(1), contador de DML dispara alerta (1), contador de upstream dispara alerta (1) — **7
testes**. **Migração: não**, `rate_limit_events` já existe (usado em
`distributed_rate_limiter.dart:32` e no cron de limpeza `manaloom_ops_daemon.py:576-580`)
— mas se o bucket de catálogo for por IP anônimo, vale checar índices. **Exige decisão
humana**: qual leitura é "cara" (é o gatilho do fail-closed) e qual é o limite de idade
que torna o catálogo `stale`. Sem serviço externo. Sem prova viva.

### A dependência declarada é real?

`BT-CAT-02` é dependência real e dura (asserções 5 e 6 são inverificáveis antes dela).
`BT-CAT-01` é dependência real para a asserção 4 (frescor só é honesto se alguém atualiza
o catálogo). Mas as asserções 1, 2 e 3 — rate limit, fail-closed, cache — **podem andar
hoje**, sem esperar nada. Isso é cerca de metade do arquivo novo de middleware. **[REV]**
O teto do `EndpointCache` em particular é uma correção de segurança independente de tudo.

### Sobreposição

O rate limit do catálogo e o middleware novo resolvem, de graça, parte de `BT-SCN-00`
(chamada direta ao backend passa a ser limitada). `BT-PRICE-01` (`freshness`/`stale` de
preço) usa exatamente a mesma mecânica de frescor da asserção 4 — vale desenhar uma vez
só. `BT-OFF-01` (`online_required/cached_read_only/stale/current`) é a face de app do
mesmo contrato de frescor. **[REV]** O ajuste em `rate_limit_middleware.dart:263` corrige
de tabela o limiter de `auth` e `ai`, que hoje **provavelmente** viram 500 com Postgres fora em prod **[REV4: plausível, não verificado por execução]**.

---

## `BT-ART-01` — Contrato técnico/legal de arte e provenance BrewTact para beta gratuita

- Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:387` (registry `source_line: 387`)
- Aceite: *"Exact printing first; reference label; full-card contain; hosts/cache/rate; zero proxy/crop/paywall."*
- Estado declarado: `P0 CORE · TODO` · depende de `BT-GOV-001` (`PASS`)

### Asserções

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Existe o contrato escrito de arte/provenance | PARCIAL | `docs/MANALOOM_CARD_ART_SOURCE_CACHE_AND_RIGHTS_CONTRACT.md` — 143 linhas, `Status: accepted_for_free_beta`, datado 2026-08-05, com decisão (`:14-33`), proveniência (`:35-47`), cache/rede (`:66-81`), crédito (`:83-92`), inventário/enforcement (`:94-105`), gates (`:114-128`) e 5 fontes oficiais verificadas (`:130-143`) | n/a (documento) | **[REV]** Dois problemas, e o segundo é pior que o primeiro. (a) O documento é "ManaLoom", não "BrewTact" — título, texto, nome do arquivo; a tarefa pede o contrato **BrewTact**; fontes verificadas em 2026-08-05, antes do backlog. (b) **O contrato afirma algo que o código não faz**: `:74-76` diz que *"requisições de imagem via `api.scryfall.com` são iniciadas em série com intervalo mínimo de 125 ms ... e possuem somente duas tentativas adicionais"* e `:97` diz que `CachedCardImage` *"concentra ... rate gate, retry"*; no código isso só vale em Web (ver asserção 6). Um contrato legal que descreve uma contenção inexistente na plataforma principal precisa ser corrigido (doc→código ou código→doc), não só rebatizado |
| 2 | Exact printing first (a impressão concreta manda; oracle nunca vira chave de imagem) | PRONTO_E_PROVADO | `server/lib/scryfall_image_url.dart:11-20` (`scryfallPrintingIdFromPayload` recusa `oracle_id` explicitamente), `:27-34` (URL CDN só a partir de printing id validado), `:42-62` (payload `image_uris.normal` só ganha se apontar para a **mesma** printing), `:173-187` (`_provenPrintingCdnUrl` exige que printing ≠ oracle); no app, `CardArtwork` carrega `imageUrl` (impressão) antes de `fallbackImageUrl` (`card_artwork.dart:262-267`) | **[REV]** Provas de comportamento: `server/test/scryfall_image_url_test.dart:12-29` (prefere `identifiers.scryfallId`), `:31-53` (`image_uris.normal` só da mesma printing), `:55-71` (oracle nunca vira chave; fallback nomeado não contém oracle), `:79-105` (upgrade de URL legada só com evidência printing≠oracle); `server/test/sync_cards_test.dart:59` e `:78` (extrator usa CDN da printing concreta); `app/test/core/widgets/card_artwork_test.dart:19-65` (primário requisitado antes do fallback). **Correção de citação**: `sync_cards_test.dart:8` é grep de string, não prova; `:103/:115` testam ausência de oracle, não exact-first — removidas da prova | — **[REV4] Mantido, com ressalva de alcance.** A regra está provada; o que ela entrega é menor do que parece. A base do catálogo está no grão Oracle com `image_url` nomeada (achado 8), e o servidor mantém o lookup nomeado quando `scryfall_id = oracle_id` (`server/lib/scryfall_image_url.dart:173-186`, provado em `scryfall_image_url_test.dart:93-105`). Para essas linhas não há impressão exata a mostrar primeiro, só referência. Além disso, o widget remove o `set` do lookup nomeado (`cached_card_image.dart:127-134`, travado por `cached_card_image_test.dart:125-158`), então a referência exibida é a impressão padrão do Scryfall, nem sequer a do set gravado na linha. |
| 3 | Fallback de referência é **rotulado** ao usuário | **PARCIAL [REV4]** (era PRONTO_E_PROVADO) | `app/lib/core/widgets/card_artwork.dart:198-205` (`_primaryIsReference`, incluindo `_looksLikeReferenceArtwork` em `:376-381` que detecta `api.scryfall.com/cards/named`), estado `reference` em `:217-221`, badge visível em `:321-330` (`'Referência'` / `'Arte de referência'`), rótulo semântico em `:299-319` (`'arte de referência'`) | `app/test/core/widgets/card_artwork_test.dart:19-65` — carrega primário, força falha, espera o fallback, e afirma o label semântico exato `'Fallback card, arte de referência'` (sucesso) ou `'Fallback card, falha ao carregar imagem'` (falha) e a chave `card-artwork-status-reference`/`-error`; `:207-234` afirma o texto `'Referência'` visível para URL `/cards/named` | **[REV]** Ressalva, não rebaixamento: 11 chamadores de produto passam `showStatusBadge: false` (`grep -rn "showStatusBadge: false" app/lib`: `battle_live_spectator_screen.dart:1164,:1365`, `home_screen.dart:1096`, `sets_catalog_screen.dart:619`, `post_game_notes_screen.dart:704,:1636,:1860`, `deck_workshop_tab.dart:705`, `deck_details_overview_tab.dart:276`, `deck_optimize_sheet_widgets.dart:1286`, `scanned_card_preview.dart:578`); nessas superfícies só o rótulo **semântico** sobrevive (`_semanticLabel` em `:299` não depende de `showStatusBadge`). Para usuário vidente, 11 superfícies não rotulam a referência **[REV4] Rebaixada: a ressalva acima é a própria asserção.** O contrato promete "estado visual `reference`" (`docs/MANALOOM_CARD_ART_SOURCE_CACHE_AND_RIGHTS_CONTRACT.md:43-45`) e "referência visual explicitamente rotulada" (`:16-18`). O teste prova o widget com o selo ligado (o padrão); nenhum teste cobre as 11 superfícies que o desligam. Pelo menos três delas estão no escopo da beta (`docs/status/CURRENT_PRODUCT_DECISION.md:58`) e podem mostrar referência. O caso mais visível é o **herói do Deck Details**, que passa o lookup nomeado como fallback e marca `imageIsReference: exactImageUrl == null` com `showStatusBadge: false` (`app/lib/features/decks/widgets/deck_details_overview_tab.dart:266-277`). Pelo achado 8, `printingImageUrl` é nulo para toda linha-alias Oracle (`deck_card_item.dart:121-148`), então ali a referência sem selo é o caso comum, não a exceção. Os outros dois: `deck_workshop_tab.dart:699-706` e `home_screen.dart:1090-1097`. O que falta: decidir se miniaturas abaixo de um tamanho ficam isentas (e escrever a isenção no contrato), religar o selo no herói (78×109 comporta o selo só com ícone, mínimo de 24 px, `card_artwork.dart:422`) e um guard que restrinja `showStatusBadge: false` a uma allowlist. |
| 4 | Full-card usa `contain` (e a geometria 63:88) | PRONTO_E_PROVADO | `app/lib/core/widgets/card_artwork.dart:66` (`mtgCardAspectRatio = 63 / 88`), `:74-93` (gallery/spotlight/recentDeck/fullCard todos `BoxFit.contain` + razão da carta), aplicação em `:271` e `:295-296`. **[REV]** `contain` é inescapável por construção: o construtor de `CardArtwork` (`:109-127`) **não tem parâmetro `fit`** | `app/test/core/widgets/card_artwork_test.dart:114-125` itera as 4 variantes e afirma `spec.aspectRatio == mtgCardAspectRatio` **e** `spec.fit == BoxFit.contain`; `:127-135` fixa as razões dos crops intencionais; `:168-205` afirma o `AspectRatio` renderizado e o `fit` da `CachedNetworkImage` | **[REV]** Ressalva sobre a metade "63:88": 41 chamadores de produto passam **[REV4: eram 42]** `constrainAspectRatio: false` (`grep -rn` em `app/lib/features`) e impõem `width/height` à mão — amostra: `card_search_screen.dart:877-878` (126×176 = 0,716), `deck_list_screen.dart:1539-1543` (92×128 = 0,719), `binder_screen.dart:1911-1913` (`touchTargetMin`×68). Estão perto de 63/88 = 0,716, e `contain` garante que nunca cortam, mas **a constante só governa 3 chamadores** **[REV4: eram 2]**; o resto é razão à mão. Isso não fere o aceite de `BT-ART-01` ("full-card contain"), mas fere o de `BT-UX-IMG-001` ("63:88") — ver sobreposição **[REV4] Mantido; contagem corrigida:** são **41** de 44 chamadores com `constrainAspectRatio: false`, e a constante governa **3** (`card_detail_screen.dart:316`, `:381`, `deck_optimize_sheet_widgets.dart:2832`), não 2. As únicas imagens de carta cheia fora de `contain` são os dois `cover` da asserção 7, com corte subpixel. |
| 5 | Hosts permitidos são restritos e verificados | **PARCIAL [REV]** (era PRONTO_E_PROVADO) | os **reconhecedores** existem: `app/lib/core/services/scryfall_image_request_policy.dart:69-89` (`isScryfallApiImageUrl` exige `https`, `api.scryfall.com`, `cards/...`, `format=image`; `isScryfallArtworkImageUrl` aceita só `cards.scryfall.io` ou o anterior). **Mas nenhum deles é um gate.** No app, `_sanitizeImageUrl` (`app/lib/core/widgets/cached_card_image.dart:90-137`) aceita **qualquer host** `http/https` (`:118-125` só exige esquema e host não vazio) e `isScryfallArtworkImageUrl` só decide o ramo Web (`:284-288`). No servidor, `normalizeScryfallImageUrl` (`server/lib/scryfall_image_url.dart:124-127`) **devolve inalterada** qualquer URL de host que não seja Scryfall (`if (host != 'api.scryfall.com') return normalized;`). A restrição real é **por construção dos produtores**: `scryfallNormalCdnUrlForPrinting` (`:27-34`) e `scryfallNamedImageFallback` (`:69-83`) só geram Scryfall. O contrato admite isso (`:40-42`: "normalização de transporte no widget não concede proveniência") e empurra a garantia para o backend — que também não a tem. | `app/test/core/services/scryfall_image_request_policy_test.dart:5-35` e `:37-62` provam que os **reconhecedores** aceitam Scryfall e rejeitam sósias (`cards.scryfall.io.example.test`). Nenhum teste afirma que uma URL de host estranho é **recusada** pelo widget ou pelo servidor, nem que os produtores de URL só emitem Scryfall | um ponto de recusa (no `_sanitizeImageUrl` do app ou no `normalizeScryfallImageUrl` do servidor — 1 arquivo) + teste que injeta `https://evil.example/card.jpg` e exige `null`/placeholder **[REV4] Correções, sem mudar o estado.** (a) Existe **uma** recusa parcial: `ScryfallImageHelper.canonicalCardImageUrl` (`app/lib/core/utils/scryfall_image_helper.dart:88-96`) troca host desconhecido pelo lookup nomeado, testada em `app/test/core/utils/scryfall_image_helper_test.dart:48-69`. Mas só dois chamadores a usam (`deck_list_screen.dart:1478`, `:1906`), e o mesmo arquivo de teste **trava o oposto** para `preferredImageUrl` (`:71-80`, "keeps non-Scryfall persisted artwork"). (b) Um gate no widget custa mais do que "1 ponto + 1 teste". `cached_card_image_test.dart:72-99` afirma que `images.example.test` é aceito, e os testes de ciclo de vida usam `https://artwork-lifecycle.invalid/...` (6 em `cached_card_image_test.dart:357-573` e 2 em `card_artwork_test.dart:19-112`). Sem um ponto de injeção para teste, esse gate quebra 8 testes e inverte 1. O gate no servidor (`normalizeScryfallImageUrl`, `server/lib/scryfall_image_url.dart:124-127`) é mais barato e é onde o contrato põe a garantia (`:40-42`). |
| 6 | Rate/retry de imagem respeitam o limite do Scryfall | **PARCIAL [REV]** (era PRONTO_E_PROVADO) | a **política** existe: `app/lib/core/services/scryfall_image_request_policy.dart:11-47` (gate serializa os inícios com 125 ms, ≤ 8/s), `:50-67` (2 tentativas extras, 500/1500 ms). **Mas o widget só a usa em Web.** `cached_card_image.dart:284-301`: `needsScryfallWebResilience = kIsWeb && (...)` → só então instancia `_ScryfallWebCardImage`, que é o único lugar onde `scryfallImageRequestGate.acquire()` (`:700`) e `scryfallImageRetryPolicy` (`:647`, `:747`) aparecem (`grep -rn scryfallImageRequestGate app/lib` confirma: 3 usos, todos dentro de `_ScryfallWebCardImage`). Em **iOS/Android** — a plataforma da beta, com perfil Android P0 nos commits recentes — o ramo é `CachedNetworkImage` (`:303-356`), que dispara `api.scryfall.com/cards/named?...&format=image` sem serialização, sem intervalo mínimo e sem retry limitado (só o comportamento padrão do `flutter_cache_manager`). O app usa esse fallback nomeado em 35 chamadores (`grep -rn "fallbackImageUrl:" app/lib/features`) — uma grade de 50 cartas sem CDN dispara 50 lookups simultâneos no host que o Scryfall limita a 10/s. | `app/test/core/services/scryfall_image_request_policy_test.dart:64-113` testa a **classe de política isolada** (permits serializados, permit falho não envenena a fila, delays limitados). Nenhum teste em `app/test/core/widgets/cached_card_image_test.dart` (`grep Gate|retry` devolve vazio nos 12 testes) afirma que o widget passa pelo gate em qualquer plataforma | aplicar o gate no ramo nativo — `CachedNetworkImage` não tem hook pré-fetch, então é um `BaseCacheManager`/`FileService` custom que faz `acquire()` antes do `get` (1 arquivo novo + fiação em `cached_card_image.dart`) + teste que monta N imagens `api.scryfall.com` e afirma os inícios serializados; ou, alternativamente, decidir e escrever no contrato que nativo é sem gate (arriscado: é a plataforma principal) **[REV4] Correções, sem mudar o estado.** (a) "50 lookups simultâneos" está exagerado. O `flutter_cache_manager` 3.4.1 (`app/pubspec.lock:473-480`) limita a 10 downloads em voo (`FileService.concurrentFetches = 10`, `lib/src/web/file_service.dart:17`, com fila em `lib/src/web/web_helper.dart:54-56`). O problema continua: sem intervalo mínimo, 10 downloads em voo com redirects curtos passam de 10 req/s. (b) **A materialidade é maior do que a medição disse.** Pelo achado 8, o lookup nomeado é a URL **primária** das linhas-alias Oracle, não só o fallback de 35 chamadores. Uma grade de deck feita dessa base dispara um lookup `api.scryfall.com` por carta. (c) Nem o ramo Web está provado: os testes Flutter rodam só na VM (achado 10), então a fiação de `_ScryfallWebCardImage` também nunca é exercitada. |
| 7 | Zero proxy e zero crop | **PARCIAL [REV]** (era PRONTO_E_PROVADO) | **zero proxy: confirmado** — não há rota de imagem no servidor (`find server/routes -iname '*image*' -o -iname '*proxy*'` devolve nada relevante; nenhum `Content-Type: image/*` servido), o backend só persiste URL (`server/routes/cards/index.dart:79-83`, `printings/index.dart:264-268`). **zero crop: dois contraexemplos e um buraco no guard.** `app/lib/features/social/screens/user_profile_screen.dart:696-701` e `:820-825` renderizam `deck.commanderImageUrl` (imagem de carta) via `CachedCardImage(... width: 62, height: 86, fit: BoxFit.cover)` — a única forma de `CachedCardImage` cortar é receber `fit: cover` explícito (padrão é `contain`, `:66`), e é o que acontece aqui. A superfície está fora da beta (`profiles_public: off`), mas o eixo é IMPLEMENTADO. `CardArtworkVariant.artCrop` continua sem caller de produto. | `app/test/core/widgets/card_image_source_policy_guard_test.dart:6-36` trava a allowlist de 8 arquivos com `CachedNetworkImage(/Image.network(/NetworkImage(/CachedNetworkImageProvider(` (usa `unorderedEquals`, qualquer caller novo quebra); `:38-45` exige zero `art_crop` em `lib/features`. **O guard não olha `CachedCardImage(... fit: BoxFit.cover)`** — por isso os dois callers acima passam | trocar os 2 `cover` por `contain` (1 arquivo) e estender o guard para recusar `BoxFit.cover` em `CachedCardImage`/`CardArtwork` de superfícies de carta (1 teste) **[REV4] Estado mantido, severidade menor.** As caixas são 62×86 e 66×92; contra 63:88 (0,716), `cover` corta **0,6 px e 0,2 px** no total. É violação nominal do contrato ("cobrir", `:19-21`), sem corte visível. O que falta de verdade é o guard; a troca por `contain` é trivial. Os dois usos também contornam `CardArtwork`, então não têm estado de referência nem rótulo semântico. |
| 8 | Zero paywall sobre arte/dados | **PRONTO_E_PROVADO [REV]** (era PARCIAL) | `art_paywall`, `billing_checkout`, `subscriptions`, `marketplace`, `ads` estão `release_capability: off` em `server/config/release_capabilities.json` (`art_paywall` em `:154`; é uma capability própria, listada em `server/lib/release_capability_policy.dart:40`, então ligar billing no futuro **não** liga paywall de arte); aviso legal em `app/lib/features/commercial/screens/legal_screen.dart:153` usa `ProductIdentity.displayName` (= `'BrewTact'`, `app/lib/core/branding/product_identity.dart:7`) | `server/test/release_capability_policy_test.dart:14-31` (`'canonical free-beta policy is valid and starts fully closed'`) afirma `policy.capabilities.values.every((entry) => !entry.allowed)` sobre o JSON canônico; `:393-499` afirma com handler falso que o gate nega antes de chamar o handler | — . **[REV] Sobre o User-Agent `'ManaLoom/1.0'` (`cached_card_image.dart:43`) que a medição original tratou como defeito**: não é. É decisão registrada — ADR `docs/adr/0010-brewtact-public-brand-transition.md:43-45` (§8: *"valores de protocolo ... permanecem legados"*) e `:46-47` (§9: cada string é classificada como pública ou interna); o teste de contrato de marca `app/test/core/branding/product_identity_contract_test.dart:71-108` **allowlista explicitamente** `'ManaLoom/1.0'` como literal machine-facing (`:78`), e `app/test/core/widgets/cached_card_image_test.dart:155` **trava** `image.httpHeaders?['User-Agent'] == 'ManaLoom/1.0'`. O contrato de arte também documenta esse UA (`:77`). A frase "não há teste que afirme o User-Agent" da medição original estava errada: há dois, e ambos fixam o valor atual. Mudar o UA é uma **decisão de classificação** (um UA enviado a terceiro é string pública ou valor de protocolo?), e custa 3 arquivos (`cached_card_image.dart`, os 2 testes), não 1 **[REV4] Mantido, com ressalva de durabilidade.** A prova é "tudo fechado" (`every(!allowed)`), não "comércio fechado". Esse teste terá de ser reescrito no dia em que a beta abrir `catalog_private` e `decks_private`. Nada amarra estruturalmente `free_beta_no_commerce` às capabilities comerciais: o parser valida `offer_mode` (`release_capability_policy.dart:285-296`) mas não exige `billing_checkout`, `subscriptions` e `art_paywall` desligadas. `art_paywall` não mapeia rota nenhuma (`not_implemented`), então o "off" dela sozinho não protege nada. Ao reescrever o teste, é preciso manter uma asserção dedicada ao comércio. |
| 9 | **[REV]** Cache de imagem limitado (a metade "cache" de "hosts/cache/rate", não medida originalmente) | PRONTO_E_PROVADO | `app/lib/core/services/image_cache_policy.dart:12-17` (`maximumLiveEntries = 96`, `maximumBytes = 32 MiB`, `maximumDecodeDimension = 1400`, buckets de thumbnail), aplicado em `:30-31` e chamado no boot em `app/lib/main.dart:274` (`AppImageCachePolicy.apply()`); o widget deriva o alvo de decode por `AppImageCachePolicy.targetFor` (`cached_card_image.dart:247-253`) e `_sizeScryfallImageUrl` (`:139-159`) escolhe `small/normal/large` pelo alvo | `app/test/core/services/image_cache_policy_test.dart:6` (`'applies bounded global memory cache policy'`), `:15` (`'buckets physical decode width and caps oversized artwork'`), `:45` (`'falls back to height when width is unbounded'`); `cached_card_image_test.dart:101` (`'selects a bounded Scryfall CDN variant for the decode target'`) e `:181` (`'bounds thumbnail decode without a second disk resize'`) | — **[REV4] Mantido.** O teto provado é o de memória. O disco usa o padrão do `flutter_cache_manager` (200 objetos, 30 dias, `lib/src/config/_config_io.dart:14-15`), sem configuração nem teste na app. O contrato só afirma o teto de memória (`:68-69`), então não há divergência. |

### O que realmente falta

**[REV]** A medição original dizia "6 de 8 asserções prontas e provadas; o que falta é
pequeno e específico: rebatizar o contrato e trocar o User-Agent". A revisão derruba isso
em três pontos e sobe em dois:

- **Cai (1): o gate de rate limit é só Web.** `cached_card_image.dart:284-288` —
  `kIsWeb && ...` é a única porta para `_ScryfallWebCardImage`, o único lugar com
  `scryfallImageRequestGate.acquire()`. No mobile, o ramo `CachedNetworkImage` (`:303`)
  faz lookups `api.scryfall.com/cards/named` sem serialização. O contrato (`:74-76`,
  `:97`) diz o contrário. Isso é engenharia real, não rename: `CachedNetworkImage` não
  tem hook pré-fetch; a forma limpa é um `FileService`/`BaseCacheManager` próprio que
  chama `acquire()` antes do `get` — 1 arquivo novo + fiação + 1 teste de widget.
- **Cai (2): não há gate de host em ponta nenhuma.** Reconhecedores provados
  (`scryfall_image_request_policy_test.dart:5-62`); recusa inexistente no app
  (`cached_card_image.dart:118-125`) e no servidor (`scryfall_image_url.dart:124-127`).
  Pequeno: 1 ponto de recusa + 1 teste.
- **Cai (3): há crop de carta em produto.** `user_profile_screen.dart:700` e `:824`
  (`fit: BoxFit.cover` sobre `commanderImageUrl`), invisível ao guard porque ele só
  procura construtores crus e `art_crop`. Pequeno: 2 linhas + 1 extensão do guard.
- **Sobe (1): zero paywall está provado**, não parcial — `art_paywall` é capability
  própria e `release_capability_policy_test.dart:14-31` afirma tudo fechado.
- **Sobe (2): o User-Agent não é defeito.** É decisão registrada (ADR-0010 §8/§9),
  allowlistada (`product_identity_contract_test.dart:78`) e travada
  (`cached_card_image_test.dart:155`). Vira pergunta ao dono, não item de trabalho.
- **Sobe (3): cache de imagem limitado existe e é testado** (asserção 9 nova).

Concretamente: o contrato (`docs/MANALOOM_CARD_ART_SOURCE_CACHE_AND_RIGHTS_CONTRACT.md` —
renomear, reescrever a identidade, **corrigir `:74-79` e `:97` para bater com o código
ou vice-versa**, re-verificar as 5 fontes de `:130-143`), o índice de docs que referencia
o arquivo, `app/lib/core/widgets/cached_card_image.dart` (gate no ramo nativo + recusa
de host), um `FileService`/cache manager novo em `app/lib/core/services/`,
`app/lib/features/social/screens/user_profile_screen.dart` (2× `cover`→`contain`),
`app/test/core/widgets/card_image_source_policy_guard_test.dart` (guard de `cover`),
`app/test/core/widgets/cached_card_image_test.dart` (gate + host) — **7 arquivos**;
**8** se o dono decidir mudar o UA (`+ product_identity_contract_test.dart`). Testes:
gate aplicado no ramo nativo (1), host estranho recusado (1), guard de `cover` em
superfície de carta (1) — **3 testes**; **4** se o UA mudar. Sem migração. Sem prova
viva obrigatória (a evidência do badge de referência já é widget test), embora o gate
nativo mereça um receipt de rede real (captura de N requisições serializadas no
simulador) porque é o que o Scryfall mede. **Exige decisão humana**: (a) UA é string
pública ou valor de protocolo (ADR-0010 §9); (b) contrato→código (implementar o gate
nativo) ou código→contrato (documentar que nativo é sem gate — desaconselhado, é a
plataforma principal); (c) se a re-verificação das políticas do Scryfall/Wizards precisa
ser refeita por causa da mudança de marca; (d) se o contrato fica como documento de
engenharia ou entra no pacote de `BT-LEGAL-001` (que declara depender de `BT-ART-01`,
backlog `:653`).

**[REV4] Revisão do que falta.** Três ajustes à lista acima:

- **Cai (4): o rótulo de referência não chega às superfícies pequenas nem ao herói do
  deck** (asserção 3). Custa 1 decisão (isentar miniaturas abaixo de um tamanho?), 1
  arquivo (`deck_details_overview_tab.dart`), a isenção escrita no contrato e 1 guard de
  allowlist para `showStatusBadge: false`.
- **"Cai (2)" custa mais se feito no widget.** O gate de host no widget quebra 8 testes
  de ciclo de vida e inverte 1 (asserção 5). No servidor, custa
  `server/lib/scryfall_image_url.dart` + `server/test/scryfall_image_url_test.dart`, e é
  onde o contrato põe a garantia.
- **"Cai (1)" pesa mais do que parecia.** Com a base no grão Oracle (achado 8), o lookup
  nomeado é a URL primária de boa parte do catálogo no nativo, não uma exceção de
  fallback. A frase de "Cai (2)", "não há gate de host em ponta nenhuma", também precisa
  de ressalva: `canonicalCardImageUrl` recusa host desconhecido em 2 superfícies de deck.

Contagem revisada: contrato, índice de docs, `cached_card_image.dart` (fiação do gate
nativo), `FileService` novo em `app/lib/core/services/`, `user_profile_screen.dart`,
`card_image_source_policy_guard_test.dart` (guard de `cover` e de `showStatusBadge`),
`cached_card_image_test.dart` (gate nativo), `server/lib/scryfall_image_url.dart` e
`server/test/scryfall_image_url_test.dart` (recusa de host) e `deck_details_overview_tab.dart`
(selo no herói) — **10 arquivos**, **11** se o UA mudar. Testes: gate nativo (1), host
recusado (1), guard de `cover` (1), guard de `showStatusBadge` (1) — **4**, **5** se o UA
mudar. Decisão humana nova: **(e) isenção de selo para miniaturas**. Prova viva continua
não exigida pelo aceite literal, mas o selo no herói é mudança visual e o gate nativo é o
que o Scryfall mede. Pela governança de evidência de UI do projeto, os dois pedem captura.

### A dependência declarada é real?

`BT-GOV-001` está `PASS`. Nada bloqueia. Há uma dependência **inversa não declarada**:
boa parte de `BT-ART-01` foi resolvida por commits anteriores (`git log` em
`card_artwork.dart`: `f6f791098`, `e6737c53b`, `776b9e25d`; em `cached_card_image.dart`:
`f6f791098`, `e6737c53b`, `383c61902`) e o estado `TODO` no registry nunca foi
atualizado. **[REV]** Mas "resolvida em boa parte" ≠ "quase lá": o que falta é a parte
que a beta mobile exercita de fato.

### Sobreposição

**`BT-UX-IMG-001` (backlog `:335`, `P0 CORE`, `TODO`) é praticamente a mesma tarefa.**
Seu aceite — *"Aspect ratio `63:88`, `contain`, exact-first, fallback rotulado, nome sem
imagem e sem layout shift"* — é coberto pelas asserções 2, 3 e 4 acima. "Nome sem
imagem" **está provado** — `app/test/core/widgets/card_artwork_test.dart:268-297` monta
`CardArtwork` com `imageUrl: null` e afirma a chave `card-artwork-status-missing` e o
label semântico `'Carta de teste, imagem não disponível'`. "Sem layout shift" está
**parcialmente** provado: `:192-198` afirma que o widget `AspectRatio` renderizado usa
`mtgCardAspectRatio` antes de a imagem carregar, mas nenhum teste mede tamanho
antes/depois do load. **[REV]** "63:88" está **menos** fechada do que a medição original
disse: 41 **[REV4: eram 42]** de 44 chamadores desligam o `AspectRatio` do widget (`constrainAspectRatio:
false`) e impõem a razão à mão — perto de 63/88, mas sem contrato nem teste. Ou seja:
`BT-UX-IMG-001` herda de `BT-ART-01` o `contain`, o exact-first e o fallback rotulado;
o que ela tem de próprio é fazer a razão 63:88 ser regra (ou aceitar o "à mão" e
travá-lo com guard) e medir layout shift — ~2 asserções residuais, não uma. `BT-ART-02`
e `BT-SCN-02` declaram depender de `BT-ART-01`; ambas podem destravar assim que o
contrato for corrigido e rebatizado — o gate nativo não as bloqueia, mas `BT-SCN-02`
("prova Android física") vai esbarrar nele.

---

## Ordem que o código sugere (não é estimativa de tempo)

0. **[REV4] Medir antes de planejar o catálogo.** Uma consulta read-only autorizada em
   produção: quantas linhas de `cards` têm `scryfall_id = oracle_id`, a distribuição de
   host de `image_url` (`cards.scryfall.io` × `api.scryfall.com/cards/named`) e quantas
   linhas de `deck_cards`/`user_binder_items` apontam para linhas-alias Oracle. A
   resposta decide o tamanho de `BT-CAT-01` (fonte no grão de impressão e reconciliação,
   ou só agendamento) e a urgência do gate nativo de `BT-ART-01`. Pela governança do
   projeto, até leitura em produção pede autorização.
1. **`BT-ART-01`** — **[REV]** não são "2 mudanças pequenas e um documento": são 3
   correções pequenas (host, crop, contrato), 1 de engenharia (gate no ramo nativo) e 1
   pergunta ao dono (UA). Ainda é a primeira da fila, porque destrava `BT-ART-02`,
   `BT-SCN-02` e `BT-LEGAL-001`, e porque o contrato legal hoje afirma uma contenção que
   não existe. Fechar junto com `BT-UX-IMG-001`.
2. **Metade de `BT-CAT-03`** (rate limit + fail-closed + cache **com teto**) — não
   depende de nada, está marcada `BLOCKED_BY_P0` sem ser. **[REV]** O teto do
   `EndpointCache` e o `await` em `rate_limit_middleware.dart:263` são correções de
   segurança que valem sozinhas.
3. **`BT-CAT-01`** — registrar o job no daemon copiando o molde de
   `manaloom_sync_card_legalities_from_scryfall`, lock, budget, audit visível, matriz
   HTTP (com refator de injeção do cliente). **[REV4]** Antes disso, duas coisas que o
   molde não resolve: o runner tem de ir para a imagem de ops (o invólucro atual aponta
   para a imagem AOT da API), e o dono precisa decidir o contrato de autorização de
   apply, porque o daemon neutraliza a escrita dos jobs de catálogo. Se o passo 0 mostrar
   base majoritariamente Oracle, este passo inclui trocar a fonte do modo full para o grão
   de impressão e reconciliar as linhas-alias. Sem isso, o passo 4 quebra "Escolher
   edição".
4. **`BT-CAT-02`** — só depois que o refresh for operável **e completo no grão de
   impressão [REV4]**, porque a remoção do self-healing é visível para o usuário. Exige a decisão de produto sobre carta ausente.
   **[REV]** 5 das 7 rotas já estão prontas; o trabalho é nas 2 que escrevem e na
   inversão de 3 testes que travam o comportamento atual (`cards_route_test.dart:56`,
   `:84`, `card_provider_search_test.dart:312-320`).
5. **A outra metade de `BT-CAT-03`** (alertas de DML/upstream) — é o guard de regressão
   do passo 4 e só faz sentido depois dele.

---

## Verificação adversarial (2026-09-22, segundo revisor)

Método: reabri as 26 asserções da medição original (7 + 5 + 6 + 8). Para cada
`PRONTO_E_PROVADO`, li o arquivo de teste inteiro e conferi se o que ele **afirma**
cobre o que a asserção **diz**. Para cada `PRONTO_SEM_PROVA`, abri o `arquivo:linha` e
procurei a guarda ausente ou o caso que escapa. Para `BT-ART-01` (`quase-la`), tentei
derrubar ativamente: segui o caminho de rede que o mobile usa, não o que o teste usa.
Somente leitura; nenhum teste executado.

### O que caiu

| Tarefa | Asserção | De → Para | Por quê (arquivo:linha) |
| --- | --- | --- | --- |
| `BT-ART-01` | #6 Rate/retry de imagem respeitam o limite do Scryfall | PRONTO_E_PROVADO → **PARCIAL** | O gate e o retry só existem em `_ScryfallWebCardImage`, instanciado apenas sob `kIsWeb` (`app/lib/core/widgets/cached_card_image.dart:284-288`); os 3 usos de `scryfallImageRequestGate`/`scryfallImageRetryPolicy` em `app/lib` estão em `:647`, `:700`, `:747`, todos dentro dessa classe. O ramo nativo (`:303-356`) é `CachedNetworkImage` sem gate. O teste citado (`scryfall_image_request_policy_test.dart:64-113`) prova a classe de política isolada, não que o widget a usa; `cached_card_image_test.dart` não tem nenhum teste de gate. O contrato (`:74-76`, `:97`) afirma o que o código nativo não faz. |
| `BT-ART-01` | #5 Hosts permitidos são restritos e verificados | PRONTO_E_PROVADO → **PARCIAL** | Os reconhecedores são provados (`scryfall_image_request_policy_test.dart:5-62`), mas nenhum ponto recusa host estranho: `_sanitizeImageUrl` aceita qualquer `http/https` (`cached_card_image.dart:118-125`); `normalizeScryfallImageUrl` devolve inalterada qualquer URL não-Scryfall (`server/lib/scryfall_image_url.dart:124-127`). A restrição real é por construção dos produtores (`:27-34`, `:69-83`), sem teste que afirme isso. |
| `BT-ART-01` | #7 Zero proxy e zero crop | PRONTO_E_PROVADO → **PARCIAL** | Zero proxy confere. Zero crop tem 2 contraexemplos: `app/lib/features/social/screens/user_profile_screen.dart:696-701` e `:820-825` (`CachedCardImage(... fit: BoxFit.cover)` sobre `commanderImageUrl`). O guard `card_image_source_policy_guard_test.dart:6-45` não inspeciona `fit`, só construtores crus e `art_crop`. Superfície fora da beta (`profiles_public: off`), mas o eixo medido é IMPLEMENTADO. |
| `BT-ART-01` | #1 Existe o contrato escrito | PARCIAL → PARCIAL (**pior**) | Não é só marca: o contrato descreve em `:74-79` e `:97` um gate de 125 ms e retry limitado que o código nativo não tem. Um contrato legal com afirmação técnica falsa precisa de correção de conteúdo, não de rename. |
| `BT-ART-01` | (tarefa) | `quase-la` → **`metade`** | 5/9 provadas em vez de 6/8; o que falta inclui engenharia no caminho de rede da plataforma principal; "2 mudanças pequenas e um documento" subestimava. |
| `BT-CAT-01` | #2 Idempotente (citação de prova) | PRONTO_SEM_PROVA (mantido) | `sync_cards_test.dart:8` é grep de string (`readAsStringSync` + `contains`), não exercício do upsert; a medição original não dizia isso. O estado já era SEM_PROVA, então não muda — mas a citação estava inflada. |
| `BT-ART-01` | #2 Exact printing first (citação de prova) | PRONTO_E_PROVADO (mantido) | Idem: `sync_cards_test.dart:8` retirado da prova; `:103/:115` testam ausência de oracle, não exact-first. A asserção continua provada por `scryfall_image_url_test.dart:12-105`, `sync_cards_test.dart:59,:78` e `card_artwork_test.dart:19-65`. |

### O que subiu

| Tarefa | Asserção | De → Para | Por quê (arquivo:linha) |
| --- | --- | --- | --- |
| `BT-ART-01` | #8 Zero paywall | PARCIAL → **PRONTO_E_PROVADO** | `art_paywall` é capability própria (`release_capability_policy.dart:40`, `release_capabilities.json:154`, `off`); `release_capability_policy_test.dart:14-31` afirma `every((entry) => !entry.allowed)` sobre o JSON canônico; `:393-499` afirma que o gate não chama o handler. |
| `BT-ART-01` | #8 (UA `ManaLoom/1.0`) | "defeito sem teste" → **decisão registrada, com 2 testes** | ADR `docs/adr/0010-brewtact-public-brand-transition.md:43-47` (§8 valores de protocolo ficam legados; §9 cada string é classificada); `product_identity_contract_test.dart:78` allowlista o literal; `cached_card_image_test.dart:155` trava o valor. Vira pergunta ao dono. Custo se mudar: 3 arquivos, não 1. |
| `BT-ART-01` | #9 Cache de imagem limitado (nova) | (não medida) → **PRONTO_E_PROVADO** | `image_cache_policy.dart:12-17,:30-31`, aplicado em `main.dart:274`; `image_cache_policy_test.dart:6,:15,:45`; `cached_card_image_test.dart:101,:181`. É a metade "cache" do aceite "hosts/cache/rate". |
| `BT-CAT-02` | #1 Rotas read-only | PRONTO_SEM_PROVA (mantido, inventário corrigido) | 5 das 7 rotas de catálogo já são read-only: `cards/index.dart`, `cards/[id]/rulings/index.dart`, `cards/resolve/batch/index.dart` (importa só `card_resolution_support.dart` e `deck_card_name_resolution_support.dart`, ambos sem http/DML), `sets/index.dart`, `rules/index.dart`. A medição original só olhou 3. |
| `BT-CAT-01` | #5 Audit | PRONTO_SEM_PROVA (mantido, contexto corrigido) | `sync_log` é criada por `server/database_setup.sql:1563-1574` (não pelo script) e já tem leitor: `server/bin/sync_status.dart:18-35`. |
| `BT-CAT-01` | #3/#4 Lock/budget (referência) | (sem mudança de estado) | `manaloom_ops_daemon.py:597-606` já agenda `sync_card_legalities_from_scryfall.py` com `flock`, dry-run por padrão, `--limit` (`:293`) e `--delay_ms` (`:335`). O molde existe; a medição original dizia que a decisão daemon-vs-crontab "ninguém tomou". **[REV4: "agenda" = registra. O job é filtrado por `catalog_private` e tem o apply forçado a `"0"` (`:236-247`, `:711-745`); nunca aplicou.]** |
| `BT-CAT-03` | #1 (guard negativo) | (sem mudança de estado) | `sets_route_test.dart:106-116` já tem `isNot(contains('api.scryfall.com/sets'))` — único guard "0 upstream" do catálogo, por grep. |

### Achados novos que a medição original não tinha

1. **`EndpointCache` é ilimitado e nunca é varrido** (`server/lib/endpoint_cache.dart:13`,
   `:32-35`; `clearExpired` sem chamador em `server/`). Chave = query string crua
   (`routes/cards/index.dart:49`) numa rota sem auth. Vetor de crescimento de memória por
   varredura anônima. Entra em `BT-CAT-03` #3 e sobe o arquivo/teste dela em +1/+1.
2. **`rate_limit_middleware.dart:263` faz `return limiter.isAllowed(...)` sem `await`
   dentro do `try`** — o `catch (_)` de `:264` não cobre a rejeição do `Future`. Com
   Postgres fora em prod, `auth`/`ai` viram 500 em vez do fallback em memória desenhado.
   **[REV4: plausível, não verificado por execução; ver `BT-CAT-03` #2.]**
   Fora do grupo, mas é o helper que `BT-CAT-03` vai reutilizar.
3. **11 superfícies escondem o badge visual de referência** (`showStatusBadge: false`);
   só o rótulo semântico sobrevive. Ressalva em `BT-ART-01` #3.
4. **42 de 44 chamadores de `CardArtwork` desligam a razão 63:88 do widget** **[REV4: são 41 de 44]**
   (`constrainAspectRatio: false`). Não fere `BT-ART-01`; fere `BT-UX-IMG-001`.
5. **`_httpGetWithRetry` (`sync_cards.dart:313`) usa `http.get` direto** — a matriz
   HTTP de `BT-CAT-01` #6 exige refator de injeção antes do primeiro teste.

### Revisão de `arquivosATocar` / `testesAEscrever`

| Tarefa | Original | Revisado | Motivo |
| --- | --- | --- | --- |
| `BT-CAT-01` | 4 / 4 | **5 / 4** | wrapper `.sh` no padrão do daemon (`cron_sync_cards.sh` usa `docker ps`, não serve no container de ops) + refator de injeção do cliente HTTP |
| `BT-CAT-02` | 7 / 6 | 7 / 6 | mantido; `resolve/batch` e `rulings` entram no guard sem mudança de código; 3 testes a inverter (não 2) |
| `BT-CAT-03` | 7 / 6 | **8 / 7** | `rate_limit_middleware.dart` (await + modo caro) e teste de cache limitado |
| `BT-ART-01` | 3 / 2 | **7 (8) / 3 (4)** | gate nativo (1 arquivo novo + fiação), recusa de host, 2 crops, guard de `cover`, contrato com correção de conteúdo; UA condicional à decisão do dono |

### Veredito de otimismo

**[REV4: a quarta passagem discorda da metade sobre o catálogo — `BT-CAT-01` também estava otimista; ver a seção seguinte.]** **Otimista demais** — concentrado onde mais custa. As três tarefas de catálogo estavam
medidas com rigor (e até um pouco duras: inventário incompleto de rotas read-only, job
de legalidades agendado ignorado, leitor de audit ignorado). Mas a única tarefa declarada
`quase-la` não estava: o gate de rate limit — a cláusula que o Scryfall de fato mede e
que o contrato legal afirma existir — só roda em Web, e a beta é mobile. Duas das seis
"provas" eram testes de classe isolada ou de reconhecedor que o widget não usa como gate,
e o "defeito" apontado (UA) era decisão registrada com dois testes travando o valor. O
plano que saísse da versão original começaria por "rename + 1 linha" e descobriria no
meio um `FileService` custom e um contrato a corrigir. A ordem sugerida continua válida;
o tamanho do primeiro passo, não.

---

## Conferência por amostragem (2026-09-22, terceira passagem)

Somente leitura; nenhum teste executado. Três asserções `PRONTO_E_PROVADO` reabertas,
mais duas conferências de apoio.

| Tarefa · asserção | Teste aberto | O que o teste afirma de verdade | Veredito |
| --- | --- | --- | --- |
| `BT-ART-01` #2 Exact printing first | `server/test/scryfall_image_url_test.dart:12-29` | payload com `id` genérico e `identifiers.scryfallId` → `scryfallPrintingIdFromPayload` devolve o `scryfallId` e a URL é `cards.scryfall.io/normal/front/0/0/<printing>.jpg` | confere |
| | `:31-40` | `image_uris.normal` da **mesma** printing é persistida tal qual | confere |
| | `:55-71` | payload só com `scryfallOracleId` → id `null`, URL `null`; `scryfallNamedImageFallback` começa com `api.scryfall.com/cards/named?`, contém `exact=` e `set=dmr`, **não** contém o oracle | confere |
| | `:79-92` | URL legada `cards/named` só vira CDN quando `printingId ≠ oracleId`; com `printingId == oracleId` (`:94-105`) preserva o lookup nomeado | confere |
| | `app/test/core/widgets/card_artwork_test.dart:19-65` | registra primário e fallback no cache falso, falha o primário, **espera a requisição do fallback aparecer** (`cache.requests.contains(fallback)`) — ordem primário→fallback afirmada | confere |
| `BT-ART-01` #4 Full-card `contain` | `app/test/core/widgets/card_artwork_test.dart:114-125` | itera `gallery/spotlight/recentDeck/fullCard` e afirma `spec.aspectRatio == mtgCardAspectRatio` **e** `spec.fit == BoxFit.contain` | confere |
| | `:168-205` | monta `CardArtwork(fullCard)` em `SizedBox(width: 315)`, afirma o `AspectRatio` renderizado `== mtgCardAspectRatio` antes do load e `CachedNetworkImage.fit == BoxFit.contain` | confere |
| `BT-ART-01` #8 Zero paywall | `server/test/release_capability_policy_test.dart:14-31` | `ReleaseCapabilityPolicy.load()` sobre o JSON canônico: `product == 'brewtact'`, `releaseChannel == 'free_beta'`, `offerMode == 'free_beta_no_commerce'`, chaves == `releaseCapabilityKeys`, `every((entry) => !entry.allowed)` | confere |
| | `:393-412` | handler falso; `GET /ai/battle/jobs` → 404 `capability_unavailable`, `handlerCalled == false` | confere (é gate antes do handler, como o documento diz) |
| | `server/config/release_capabilities.json:154-158` · `server/lib/release_capability_policy.dart:40` | `art_paywall` é capability própria, `release_capability: off`, `allowed: false` | confere |
| apoio · `BT-ART-01` #9 Cache limitado | `app/test/core/services/image_cache_policy_test.dart:6-13`, `:15-43`, `:45-55` | `apply(cache:)` fixa `maximumSize`/`maximumSizeBytes` da política; `targetFor` bucketiza thumbnail em 256, artwork em 1024, cap em `maximumDecodeDimension`; sem largura usa altura | confere |
| apoio · `BT-ART-01` #6 Gate só Web | `app/lib/core/widgets/cached_card_image.dart:284-288` · `grep scryfallImageRequestGate\|scryfallImageRetryPolicy app/lib` | `needsScryfallWebResilience = kIsWeb && (...)`; os únicos usos fora da política são `:647`, `:700`, `:747`, todos em `_ScryfallWebCardImage` | confere — o rebaixamento para PARCIAL se sustenta |

**[REV4]** A amostra não incluía `BT-ART-01` #3, que caiu na quarta passagem, nem as asserções de `BT-CAT-01`; ver a seção seguinte.

Resultado: nenhuma correção ao documento. Os vetores `arquivosATocar` / `testesAEscrever`
/ estados do "Resumo do grupo" foram devolvidos como estão.

---

## Verificação adversarial (2026-09-22, quarta passagem)

Método: somente leitura, HEAD `d15beb05b`, nenhum teste, build ou servidor executado.
Reabri as 27 asserções. Para cada `PRONTO_E_PROVADO`, li o teste inteiro e o que o
código de produção faz **fora** do caminho que o teste monta. Para cada
`PRONTO_SEM_PROVA`, segui o código até onde ele roda de verdade: a imagem Docker, o
daemon, os dados que ele grava. Conferi também as citações de apoio (daemon,
Dockerfiles, `flutter_cache_manager` travado no `pubspec.lock`, testes Python do sync
full).

### O que caiu

| Tarefa | Asserção | De → Para | Por quê (arquivo:linha) |
| --- | --- | --- | --- |
| `BT-CAT-01` | #1 Existe um job/CLI interno de refresh | PRONTO_SEM_PROVA → **PARCIAL** | O código existe, mas o único invólucro (`server/bin/cron_sync_cards.sh:19,61`) roda `dart run bin/sync_cards.dart` no container da API, cujo runtime é só AOT desde `5edf7ce66` (`server/Dockerfile:22-31`): sem fonte, sem `pubspec`, sem Python/`psycopg2` para o modo full (`sync_cards.dart:450-463`). Hoje o job não roda em produção como está ligado. |
| `BT-CAT-01` | #5 Audit | PRONTO_SEM_PROVA → **PARCIAL** | Além do `catch (_) {}` (`:391`), o ramo "nada a fazer" (`:98-103`) sai sem nenhuma linha em `sync_log`, depois de já ter chamado o upstream duas vezes e reescrito `sets` (`:86-89`, `:568-577`). A escrita de `sets` nunca é auditada. |
| `BT-ART-01` | #3 Fallback de referência rotulado | PRONTO_E_PROVADO → **PARCIAL** | O teste (`card_artwork_test.dart:19-65`, `:207-266`) prova o widget com o selo ligado. O contrato promete "estado visual `reference`" (`:43-45`). O herói do Deck Details, superfície da beta, mostra o lookup nomeado com `showStatusBadge: false` (`deck_details_overview_tab.dart:266-277`), e para linhas-alias Oracle esse é o caso comum (`deck_card_item.dart:121-148`). 11 superfícies desligam o selo; nenhum teste as cobre. |
| `BT-CAT-01` | (tarefa) | `metade` → **`mal-comecada`** | 0/7 provadas; 1 `PRONTO_SEM_PROVA`, 4 `PARCIAL`, 2 `NAO_ENCONTRADO`. O núcleo de ingestão existe. Faltam: runner executável, autorização de apply no daemon, lock, budget, audit completo, cliente HTTP injetável e testes. E, para servir a `BT-CAT-02`, falta o grão de impressão. |

### O que subiu

Nada. Ataquei cada `PRONTO_E_PROVADO` que ficou de pé e não o derrubei:

- **`BT-ART-01` #2 exact-first**: `scryfall_image_url_test.dart:12-105` chama as funções e
  compara saídas, sem grep. `card_artwork_test.dart:19-65` afirma a ordem só
  indiretamente: na iteração de sucesso, o selo `reference` só aparece se o primário
  falhou antes, porque o fallback nativo só é construído dentro do `errorWidget` do
  primário (`cached_card_image.dart:325-352`), e `cached_card_image_test.dart:471-502`
  afirma `[loading, fallbackReady]`, sem `primaryReady`. Ficou com ressalva de alcance
  (base no grão Oracle).
- **`BT-ART-01` #4 contain**: o construtor de `CardArtwork` não tem `fit`
  (`card_artwork.dart:109-127`), e o teste afirma spec e render (`card_artwork_test.dart:114-125`,
  `:168-205`).
- **`BT-ART-01` #8 zero paywall**: `release_capability_policy_test.dart:14-31` afirma
  `every(!allowed)` sobre o JSON canônico, e `:393-412` afirma que o handler não é
  chamado. Ficou com ressalva de durabilidade.
- **`BT-ART-01` #9 cache limitado**: `image_cache_policy_test.dart:6-55` prova
  `maximumSize`/`maximumSizeBytes` e o bucket de decode.
- **`BT-CAT-02` #1 (5 rotas read-only)**: 0 DML e 0 HTTP nas 5 rotas e em todos os
  imports diretos; o middleware raiz não grava no banco por requisição
  (`server/routes/_middleware.dart:105-190`, métricas em memória). Continua sem prova:
  todos os testes de catálogo são grep de fonte (`cards_route_test.dart`,
  `sets_route_test.dart`, `card_resolution_support_test.dart:100`,
  `cards_reserved_schema_contract_test.dart:22`).

### Correções que não mudam estado

1. **`BT-CAT-01` #2**: "segunda execução na mesma versão é no-op por construção" é
   falso. O guard vem depois do DDL, do download de `SetList.json` e do upsert de todos
   os `sets` (`sync_cards.dart:80-103`). A execução é idempotente no conteúdo, não no
   efeito.
2. **Job de legalidades "já em produção"**: não está. Está registrado, filtrado por
   `catalog_private` e com apply forçado a `"0"` (`manaloom_ops_daemon.py:236-247`,
   `:711-745`). O `manaloom-ops` roda um único job, `hermes_cron_governor_report`
   (`docs/MAPA_OPERACIONAL_DO_PROJETO.md:256-259`).
3. **`BT-ART-01` #6**: não são "50 lookups simultâneos", e sim até 10 em voo
   (`flutter_cache_manager` 3.4.1, `file_service.dart:17`). Por outro lado, a
   materialidade é maior do que a medição disse: o lookup nomeado é a URL primária das
   linhas-alias Oracle. E nem o ramo Web do gate é exercitado, porque os testes Flutter
   rodam só na VM.
4. **`BT-ART-01` #5**: existe uma recusa parcial de host (`canonicalCardImageUrl`, 2
   superfícies de deck, testada em `scryfall_image_helper_test.dart:48-69`). O oposto
   está travado em `:71-80`, e um gate no widget quebra 8 testes de ciclo de vida. O
   gate no servidor é o caminho barato.
5. **`BT-ART-01` #7**: os dois `cover` cortam 0,6 px e 0,2 px. É violação nominal; o
   que falta é o guard.
6. **`BT-ART-01` #4**: são 41 de 44 chamadores com `constrainAspectRatio: false`, não 42.
7. **`BT-CAT-03` #2**: o "vira 500" do `return` sem `await`
   (`rate_limit_middleware.dart:263`) é plausível, não medido. O conserto é barato de
   qualquer jeito.
8. Citações ajustadas: `PROPOSED_TASKS_DECK_QUALITY_2026-09-18.md:46` (não `:48-52`) e
   `:74` (não `:80`).

### Achados novos (não apareciam em nenhuma passagem)

1. **Base do catálogo no grão Oracle** (achado 8 do topo). O seed e o modo full gravam
   `scryfall_id = oracle_id` a partir do AtomicCards. As impressões antigas só chegam
   pelas rotas que `BT-CAT-02` manda calar. Esse é o maior item de trabalho do grupo, e
   nenhuma contagem anterior o incluía. Primeiro é preciso medir a produção (passo 0 da
   ordem).
2. **O runner do job está quebrado desde `5edf7ce66`** (achado 9).
3. **Dependência de governança não declarada**: escrita autônoma de catálogo precisa
   de um contrato de autorização de apply. O daemon o exige e nenhuma tarefa o declara
   (achado 7).
4. **Web nunca testado** (achado 10): nenhum gate roda `flutter test --platform chrome`.

### Revisão de `arquivosATocar` / `testesAEscrever`

| Tarefa | Segunda passagem | Quarta passagem | Motivo |
| --- | --- | --- | --- |
| `BT-CAT-01` | 5 / 4 | **8 / 6** (≈12 arquivos com o grão) | runner na imagem de ops, `cron_sync_cards.sh` a remover ou reescrever, teste do daemon (`manaloom_ops_daemon_test.py`), runbook; teste de corte por budget e de registro no daemon. Com o grão: `sync_cards_full_fast.py` + teste, script de reconciliação e migração de dados |
| `BT-CAT-02` | 7 / 6 | 7 / 6 (+3 inversões) | mantido; o custo que faltava está em `BT-CAT-01` (grão) |
| `BT-CAT-03` | 8 / 7 | 8 / 7 | mantido; o teto do cache vale também para `/ai/generate` e `/ai/archetypes`, que usam o mesmo singleton |
| `BT-ART-01` | 7 (8) / 3 (4) | **10 (11) / 4 (5)** | selo no herói do deck + guard de `showStatusBadge`; recusa de host no servidor (2 arquivos) em vez do widget |

**Totais do grupo**: de ~27 arquivos / ~20 testes / 0 migrações / 4 decisões humanas
para **~33 arquivos (≈38 com o grão e o UA) / ~23 testes (+3 inversões) / 0 migrações de
schema, mas migração de dados provável (a confirmar pelo censo) / 7 decisões humanas**.
As 3 decisões novas: contrato de autorização de apply para escrita autônoma de catálogo;
fonte e volume do grão de impressão e destino das linhas-alias Oracle; isenção de selo de
referência para miniaturas. Serviço externo novo: nenhum. O `default_cards` da Scryfall
já é consumido por `backfill_card_image_urls.py:28`.

### Veredito de otimismo

**Otimista demais**, e desta vez o erro estava no catálogo, não só na arte. A segunda
passagem achou as três tarefas de catálogo "medidas com rigor, até um pouco duras". Não
estavam:

- `BT-CAT-01` foi medida como `metade` sem ninguém seguir o job até onde ele roda. O
  invólucro aponta para uma imagem sem fonte, e o "molde" citado como "já em produção"
  nunca aplicou.
- A dependência `BT-CAT-02` → `BT-CAT-01` foi descrita como frescor ("cartas novas").
  O problema é completude: a base não tem as impressões antigas, e o self-healing que
  `BT-CAT-02` remove é hoje a única fonte delas. Um plano que agendasse o job e depois
  removesse o self-healing quebraria "Escolher edição" no Binder e no Deck Details.
- Em `BT-ART-01`, uma asserção provada caiu: o selo de referência que o teste prova some
  na superfície mais visível da beta.

Nos dois sentidos, a medição anterior também exagerou em três pontos ("50 simultâneos",
o corte dos `cover`, o "vira 500" dado como certo), mas nenhum deles muda estado. O
tamanho real do grupo depende de um número que ninguém mediu: quanto do catálogo de
produção está no grão Oracle. Esse censo vem antes de qualquer planejamento de
`BT-CAT-01/02`.
