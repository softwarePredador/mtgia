# ManaLoom Code Structure Audit
> Data: 2026-05-28 17:47 UTC
> Rotacao local Codex: `module-coherence-server-lib-routes-app-lib`

## Rodada focada: Coerencia entre `server/lib` ↔ `server/routes` ↔ `app/lib`

Escopo desta rodada: somente coerencia de contratos, ownership e consumo entre
helpers de `server/lib`, handlers de `server/routes` e consumidores em
`app/lib`. Nao foi executada auditoria ampla de classes sem uso, funcoes nao
chamadas, imports, ciclos, tabelas PostgreSQL ou duplicacao geral.

### Limitacao da ferramenta

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado conforme
o protocolo, mas falhou antes de gerar relatorio valido porque o script ainda usa
`BASE = Path("/opt/data/workspace/mtgia")` e tentou criar
`/opt/data/workspace/mtgia/docs/hermes-analysis`, encerrando no Mac local com
`PermissionError: [Errno 13] Permission denied: '/opt/data'`.

Resultado: os achados abaixo foram produzidos por inspecao manual focada em
rotas chamadas por `app/lib`, rotas autenticadas que aceitam `deck_id` e
contratos experimentais marcados como `not proven` no app. Nao foi inventada
saida do auditor.

### Achados confirmados

#### P1 — `POST /ai/optimize` continua recebendo `deck_id` do app sem escopo de owner no helper de contexto

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:10`-`:23`
  monta payload com `deck_id`, `archetype`, `bracket`, `keep_theme` e
  `intensity`; `app/lib/features/decks/providers/deck_provider_support_ai.dart:56`
  envia `POST /ai/optimize`.
- **Handler:** `server/routes/ai/optimize/index.dart:401`-`:405` tenta ler
  `userId` do contexto autenticado; `server/routes/ai/optimize/index.dart:549`-`:558`
  chama `optimize_request.loadOptimizeDeckContext(...)` com `deckId`,
  `targetArchetype`, `requestMode`, `intensity`, `bracket` e `keepTheme`, mas
  nao passa `userId`.
- **Helper:** `server/lib/ai/optimize_request_support.dart:53`-`:62` nao
  recebe `userId`; a query do deck em
  `server/lib/ai/optimize_request_support.dart:63`-`:73` usa
  `SELECT name, format FROM decks WHERE id = @id`, e a query de cartas em
  `server/lib/ai/optimize_request_support.dart:87`-`:137` usa apenas
  `WHERE dc.deck_id = @id`.
- **Comparacao segura:** `server/routes/decks/[id]/index.dart:288`-`:317`
  usa o padrao `FROM decks WHERE id = @deckId AND user_id = @userId` para
  leitura app-facing de deck privado.
- **Por que e incoerente:** o app trata optimize como acao sobre deck do usuario
  autenticado, mas a fronteira `routes -> lib` perde o requisito de ownership
  antes de carregar deck/cartas.
- **Risco:** usuario autenticado que obtenha UUID de deck alheio pode
  potencialmente disparar analise/otimizacao sobre composicao privada e consumir
  trabalho de IA.
- **O que valida:** alterar `loadOptimizeDeckContext` para receber `userId` e
  consultar `decks` com `id + user_id` ou regra publica explicita; adicionar
  teste owner vs non-owner para caminhos sync e async de `POST /ai/optimize`.
- **O que falsifica:** contrato documentado e testado provando que optimize
  aceita decks publicos/alheios por design, com autorizacao explicita e sem
  expor composicao privada.

#### P1 — `POST /ai/archetypes` e consumido pelo app, mas tambem carrega deck/cartas sem ownership

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_mutation.dart:168`-`:173`
  chama `POST /ai/archetypes` com `{deck_id: deckId}` para buscar opcoes de
  otimizacao.
- **Middleware:** `server/routes/ai/_middleware.dart:16`-`:20` aplica
  `authMiddleware`, `aiPlanLimitMiddleware` e `aiRateLimit`, portanto a rota
  esta em namespace autenticado/custoso de IA.
- **Handler:** `server/routes/ai/archetypes/index.dart:27`-`:32` aceita
  `deck_id`; `server/routes/ai/archetypes/index.dart:39`-`:42` consulta
  `SELECT name, format FROM decks WHERE id = @id`; e
  `server/routes/ai/archetypes/index.dart:54`-`:62` consulta cartas com
  `WHERE dc.deck_id = @id`. O handler nao le `context.read<String>()` nem
  filtra por `decks.user_id`.
- **Cobertura existente:** `server/test/ai_archetypes_flow_test.dart:157`-`:234`
  cobre cache/resposta positiva, e
  `server/test/error_contract_test.dart:894`-`:934` cobre `deck_id` ausente e
  deck inexistente; nao ha prova non-owner nessas evidencias.
- **Por que e incoerente:** a rota e app-facing, usa credito/rate limit de IA e
  retorna opcoes geradas a partir da lista real do deck, mas aceita qualquer UUID
  de deck existente em vez de aplicar a mesma fronteira de owner dos endpoints
  de deck privado.
- **Risco:** usuario autenticado pode obter opcoes de arquétipo derivadas de deck
  privado de outro usuario, revelando comandante/amostra de cartas via prompt e
  diagnosticos.
- **O que valida:** escopar o deck por `id + user_id` antes de montar prompt,
  cache key e reference profile; adicionar teste owner vs non-owner para
  `POST /ai/archetypes`.
- **O que falsifica:** decisao de produto documentada que a rota analisa apenas
  decks publicos/alheios por design, com query filtrando `is_public=true` ou
  contrato separado para deck compartilhado.

#### P1 — Polling de jobs async ainda aceita jobs sem `user_id`

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:74`-`:87`
  trata `202` de optimize como job async e
  `app/lib/features/decks/providers/deck_provider_support_ai.dart:190`-`:194`
  faz polling em `/ai/optimize/jobs/$jobId`.
- **Store:** `server/lib/ai/optimize_job.dart:25`-`:30` permite
  `String? userId`; `server/lib/ai/optimize_job.dart:47`-`:64` persiste
  `user_id` nullable.
- **Criação atual:** `server/routes/ai/optimize/index.dart:457`-`:464` e
  `server/routes/ai/optimize/index.dart:1041`-`:1048` passam o `userId`
  capturado, mas ele ainda pode ser nulo porque o handler o captura de forma
  tolerante em `server/routes/ai/optimize/index.dart:401`-`:405`.
- **Handler de polling:** `server/routes/ai/optimize/jobs/[id].dart:26`-`:28`
  le o usuario autenticado e carrega o job, mas
  `server/routes/ai/optimize/jobs/[id].dart:39`-`:47` so bloqueia quando
  `job.userId != null && job.userId != userId`; jobs com `user_id = NULL`
  ficam legiveis para qualquer usuario com o `job_id`.
- **Por que e incoerente:** o app nao tem conceito de job publico e o endpoint
  fica sob `/ai` autenticado, mas a regra de acesso preserva um estado nulo que
  enfraquece a fronteira de usuario.
- **O que valida:** exigir `userId` nao nulo ao criar jobs app-facing e retornar
  404 quando `job.userId == null` no polling, salvo rota interna separada.
- **O que falsifica:** prova de que nenhum job async app-facing pode ser criado
  sem usuario e teste explicito cobrindo a politica para `user_id = NULL`.

#### P2 — Endpoints experimentais de deck/AI seguem sem ownership e sem consumidor app provado

- **Endpoints:** `GET /decks/:id/simulate`, `POST /decks/:id/recommendations`,
  `POST /ai/simulate-matchup`, `POST /ai/weakness-analysis`.
- **Evidencia de rotas:**
  - `server/routes/decks/[id]/simulate/index.dart:13`-`:26` le cartas com
    `WHERE dc.deck_id = @deckId`, sem buscar `context.read<String>()` nem
    validar `decks.user_id`.
  - `server/routes/decks/[id]/recommendations/index.dart:16`-`:27` consulta
    `SELECT name, format, description FROM decks WHERE id = @deckId`, e
    `server/routes/decks/[id]/recommendations/index.dart:39`-`:58` le cartas
    por `dc.deck_id = @deckId`, tambem sem `user_id`.
  - `server/routes/ai/simulate-matchup/index.dart:24`-`:38` le
    `my_deck_id`/`opponent_deck_id` e chama `_getDeckData`; essa funcao em
    `server/routes/ai/simulate-matchup/index.dart:76`-`:103` usa
    `SELECT id, name, format FROM decks WHERE id = @id` e cartas por
    `dc.deck_id = @id`.
  - `server/routes/ai/weakness-analysis/index.dart:17`-`:35` aceita `deck_id`
    e consulta `SELECT name, format FROM decks WHERE id = @id`; as cartas sao
    lidas em `server/routes/ai/weakness-analysis/index.dart:42`-`:60` por
    `dc.deck_id = @id`.
- **Evidencia app/contrato:** `grep -RInE` por esses endpoints em `app/lib`
  nao encontrou chamadas; `server/doc/API_CONTRACTS_AND_DATA_MAP.md:152`-`:153`
  e `:285`-`:286` marca consumidores como `not proven`/experimentais.
- **Por que e incoerente:** rotas autenticadas em `server/routes/decks/_middleware.dart:7`-`:8`
  e `server/routes/ai/_middleware.dart:16`-`:20` nao aplicam a regra de owner
  dos endpoints de deck ja consumidos pelo app.
- **O que valida:** antes de expor no app, escopar `deck_id`/`my_deck_id` por
  `user_id` e definir regra separada para oponente publico/meta deck; adicionar
  teste non-owner para cada rota mantida.
- **O que falsifica:** decisao explicita de tornar esses endpoints internos ou
  remove-los da superficie app-facing, com contrato atualizado e sem chamadas em
  `app/lib`.

#### P2 — `/community/decks/following` continua acoplado a branch especial em rota dinamica

- **Contrato app:** `app/lib/features/social/providers/social_provider.dart:563`-`:565`
  chama `/community/decks/following?page=...&limit=20` e
  `app/lib/features/social/providers/social_provider.dart:581`-`:585` registra
  o endpoint como `/community/decks/following`.
- **Handler:** `find server/routes/community/decks -maxdepth 3 -type f` mostra
  apenas `server/routes/community/decks/index.dart` e
  `server/routes/community/decks/[id].dart`; nao existe
  `server/routes/community/decks/following/index.dart`.
- **Branch especial:** `server/routes/community/decks/[id].dart:10`-`:12`
  trata `id == 'following'` como caso especial e desvia para
  `_getFollowingFeed`.
- **Por que e incoerente:** a URI consumida pelo app representa feed/colecao,
  mas esta implementada como valor magico dentro do handler de detalhe
  `/community/decks/:id`.
- **O que valida:** criar rota dedicada
  `server/routes/community/decks/following/index.dart` ou teste de contrato que
  preserve explicitamente esse caso especial.
- **O que falsifica:** decisao documentada de manter o branch magico por
  compatibilidade, com teste cobrindo `GET /community/decks/following` e
  `GET /community/decks/:id`.

### Suspeitas revalidadas e descartadas nesta rodada

- `POST /ai/rebuild` continua fora dos achados de incoerencia de ownership:
  `app/lib/features/decks/providers/deck_provider_support_ai.dart:120`-`:168`
  envia `deck_id`, e a rota ja foi revalidada na rodada anterior como escopando
  o deck por `id + user_id` antes de carregar cartas e criar draft.
- `GET /cards?set=...` e notificacoes `direct_message` nao foram reabertas nesta
  rodada porque a revalidacao anterior ja tinha evidencias compatíveis e o foco
  atual encontrou riscos de maior impacto em `deck_id` autenticado.

## Rodada focada anterior: PostgreSQL tables not used
> Data: 2026-05-28 15:00 UTC
> Rotacao local Codex: `postgresql-tables-not-used`

## Rodada focada: PostgreSQL tables not used

Escopo desta rodada: somente tabelas PostgreSQL sem uso, write-only ou com uso
persistente incoerente. Nao foi executada auditoria ampla de classes, funcoes,
imports, ciclos, duplicacao ou coerencia geral entre camadas.

### Limitacao da ferramenta

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado conforme
o protocolo, mas falhou antes de gerar relatorio valido porque o script ainda usa
`BASE = Path("/opt/data/workspace/mtgia")` e tentou criar
`/opt/data/workspace/mtgia/docs/hermes-analysis`, encerrando no Mac local com
`PermissionError: [Errno 13] Permission denied: '/opt/data'`.

Resultado: os achados abaixo foram produzidos por inspecao manual focada em
definicoes `CREATE TABLE`, referencias SQL (`FROM`, `JOIN`, `INSERT INTO`,
`UPDATE`, `DELETE FROM`) e consumidores em `server/`, `app/` e docs de contrato.
Nao foi inventada saida do auditor.

### Achados confirmados

#### P2 — `deck_matchups` continua write-only no produto atual

- **Tabela:** `deck_matchups`
- **Definicao:** `server/database_setup.sql:162`-`:170`.
- **Escrita confirmada:** `server/routes/ai/simulate-matchup/index.dart:360`
  faz `INSERT INTO deck_matchups (...) ON CONFLICT (...) DO UPDATE`.
- **Leitura/consumo encontrado:** `grep -RInE` por `FROM/JOIN/UPDATE/DELETE`
  em `server/` e `app/` encontrou somente a escrita acima; nao ha
  `SELECT ... FROM deck_matchups` em rotas, libs ou consumidores Flutter.
- **Por que parece nao usada:** `POST /ai/simulate-matchup` calcula e retorna o
  resultado na propria chamada, mas o snapshot salvo em
  `deck_matchups.win_rate/notes` nao alimenta cache, historico, ranking,
  dashboard ou contrato app-facing. `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
  marca `POST /ai/simulate-matchup` como consumidor `not proven`.
- **O que valida:** adicionar ou localizar consumidor real que leia
  `deck_matchups`, por exemplo historico/cached matchup, dashboard operacional
  ou reuso em nova simulacao.
- **O que falsifica:** um `SELECT ... FROM deck_matchups` em rota/lib consumida
  pelo app ou por job operacional documentado.

#### P2 — `deck_weakness_reports` acumula registros sem fluxo de leitura ou resolucao

- **Tabela:** `deck_weakness_reports`
- **Definicao:** `server/database_setup.sql:363`-`:376` e
  `server/bin/migrate_create_missing_tables.dart:97`.
- **Escrita confirmada:** `server/routes/ai/weakness-analysis/index.dart:374`
  faz `INSERT INTO deck_weakness_reports (...) ON CONFLICT DO NOTHING`.
- **Leitura/consumo encontrado:** `grep -RInE` por `FROM/JOIN/UPDATE/DELETE`
  em `server/` e `app/` encontrou somente a escrita acima; nao ha leitura da
  tabela nem fluxo que atualize `addressed`.
- **Por que parece nao usada:** `POST /ai/weakness-analysis` devolve
  `weaknesses` na resposta imediata, mas o dado persistido nao e listado,
  reaberto, marcado como tratado ou usado em analise futura. O campo
  `addressed` existe no schema (`server/database_setup.sql:371`) sem update
  confirmado.
- **O que valida:** criar/identificar endpoint, job ou UI que leia relatorios
  persistidos e atualize `addressed` quando o usuario corrige a fraqueza.
- **O que falsifica:** uma leitura real da tabela fora de migration/audit/teste,
  ou decisao explicita de manter a tabela apenas como log bruto com retencao.

#### P3 — `ml_prompt_feedback` tem helper de insert sem chamador e so aparece como contador operacional

- **Tabela:** `ml_prompt_feedback`
- **Definicao:** `server/bin/migrate_ml_knowledge.dart:159`-`:195`.
- **Escrita potencial:** `server/lib/ml_knowledge_service.dart:251`-`:284`
  define `MLKnowledgeService.recordFeedback` e faz
  `INSERT INTO ml_prompt_feedback (...)`.
- **Leitura/consumo encontrado:** `server/routes/ai/ml-status/index.dart:98`
  executa apenas `SELECT COUNT(*)::int as c FROM ml_prompt_feedback`.
- **Evidencia de nao acionamento:** `grep -RIn "recordFeedback" server app`
  encontrou somente a definicao em `server/lib/ml_knowledge_service.dart:251`;
  nao ha rota, provider ou job chamando o insert.
- **Por que parece nao usada:** a tabela foi criada para feedback de usuario,
  mas nenhum fluxo app/backend registra feedback. O unico uso runtime confirmado
  e um contador em endpoint interno de status, que nao consome o conteudo para
  treinamento, ranking, prompts ou produto.
- **O que valida:** ligar um fluxo real de feedback pos-otimizacao ou job que
  consuma `ml_prompt_feedback` para refinar prompts/modelo, com teste de contrato.
- **O que falsifica:** chamada existente de `recordFeedback` nao capturada nesta
  busca, trigger externo documentado, ou decisao de manter a tabela apenas como
  placeholder sem coleta ativa.

#### P3 — Tabelas raw do Commander Reference Deck Corpus sao persistidas, mas o produto le apenas o agregado

- **Tabelas:** `commander_reference_decks` e
  `commander_reference_deck_cards`.
- **Definicao:** `server/lib/ai/commander_reference_deck_corpus_support.dart:1177`
  e `:1200`.
- **Escrita confirmada:** `server/lib/ai/commander_reference_deck_corpus_support.dart:1245`
  insere em `commander_reference_decks`, `:1329` apaga cards antigos por
  `source_deck_key` e `:1345` insere em `commander_reference_deck_cards`.
- **Leitura/consumo encontrado:** a busca por `FROM/JOIN commander_reference_decks`
  e `FROM/JOIN commander_reference_deck_cards` em `server/` e `app/` nao
  encontrou leituras dessas tabelas. O caminho de produto le o agregado
  `commander_reference_deck_analysis` em
  `server/lib/ai/commander_reference_deck_corpus_support.dart:389`, e esse
  agregado e populado em `:1394`.
- **Por que parece uso parcial/incoerente:** os detalhes raw de deck/cartas
  parecem servir apenas como trilha de auditoria/reprocessamento no mesmo apply,
  enquanto generate consome somente `average_role_counts`, `top_cards` e
  `theme_counts` do agregado. Isso pode ser intencional, mas hoje nao ha
  consumidor de produto ou job que releia os raws para recomputar o agregado.
- **O que valida:** documentar essas tabelas como lineage/audit com retencao, ou
  adicionar job/endpoint que leia os raws para reprocessar o agregado e auditar
  cards aceitos/rejeitados.
- **O que falsifica:** `SELECT/JOIN` real sobre as tabelas raw em rota/lib/job
  operacional ou decisao de remover a persistencia raw e manter somente o
  agregado consumido.

### Suspeitas revalidadas e descartadas nesta rodada

- `battle_simulations` nao foi classificada como nao usada: a rota
  `server/routes/ai/simulate/index.dart:206` insere simulacoes e
  `server/bin/ml_extract_features.dart:76` le `FROM battle_simulations` para
  extracao de features.
- `ai_user_preferences` nao foi classificada como nao usada:
  `server/lib/ai/optimize_runtime_support.dart` le e persiste preferencias de
  IA.
- `card_semantic_tags_v2`, `card_function_tags`, `card_role_scores`,
  `commander_card_synergy` e `optimize_rejection_penalties` nao foram tratados
  como tabelas nao usadas: ha backfills/jobs e consumo por analysis/optimize ou
  candidate-quality metadata.
- `commander_reference_deck_analysis` nao foi tratada como nao usada: e lida por
  `loadCommanderReferenceDeckCorpusGuidance` e participa da versao/cache de
  generate.
- Tabelas operacionais como `schema_migrations`, `sync_state`, `sync_log`,
  `rate_limit_events`, `ai_logs`, `ai_optimize_jobs`, `ai_generate_jobs` e
  `activation_funnel_events` possuem referencias de leitura/escrita ou finalidade
  operacional explicita e nao entraram como achados.

## Rodada focada anterior: Coerencia entre `server/lib` ↔ `server/routes` ↔ `app/lib`
> Data: 2026-05-28 12:51 UTC
> Rotacao local Codex: `module-coherence-server-lib-routes-app-lib`

## Rodada focada: Coerencia entre `server/lib` ↔ `server/routes` ↔ `app/lib`

Escopo desta rodada: somente coerencia de contratos, ownership e consumo entre
helpers de `server/lib`, handlers de `server/routes` e consumidores em
`app/lib`. Nao foi executada auditoria ampla de classes sem uso, funcoes nao
chamadas, imports, ciclos, tabelas PostgreSQL ou duplicacao geral.

### Limitacao da ferramenta

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado conforme
o protocolo, mas falhou antes de gerar relatorio valido porque o script ainda usa
`BASE = Path("/opt/data/workspace/mtgia")` e tentou criar
`/opt/data/workspace/mtgia/docs/hermes-analysis`, encerrando no Mac local com
`PermissionError: [Errno 13] Permission denied: '/opt/data'`.

Resultado: os achados abaixo foram produzidos por inspecao manual focada em
rotas chamadas por `app/lib` e em endpoints experimentais documentados como
`not proven` no app. Nao foi inventada saida do auditor.

### Achados confirmados

#### P1 — `POST /ai/optimize` recebe `deck_id` do app, mas o loader de contexto nao escopa o deck por dono

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:10`-`:23`
  monta payload com `deck_id`, `archetype`, `bracket`, `keep_theme` e
  `intensity`; `app/lib/features/decks/providers/deck_provider_support_ai.dart:56`
  envia `POST /ai/optimize`.
- **Handler:** `server/routes/ai/optimize/index.dart:401`-`:405` le `userId`
  do contexto autenticado e `server/routes/ai/optimize/index.dart:545`-`:558`
  chama `optimize_request.loadOptimizeDeckContext(...)` passando `deckId`, mas
  nao passa `userId`.
- **Helper:** `server/lib/ai/optimize_request_support.dart:53`-`:62` nao recebe
  `userId`; a query do deck em `server/lib/ai/optimize_request_support.dart:63`-`:73`
  usa `SELECT name, format FROM decks WHERE id = @id`, e a query de cartas em
  `server/lib/ai/optimize_request_support.dart:87`-`:137` usa apenas
  `WHERE dc.deck_id = @id`.
- **Por que e incoerente:** o app chama optimize para deck privado do usuario
  autenticado, e rotas estaveis de deck usam ownership explicito, por exemplo
  `server/routes/decks/[id]/index.dart:300`-`:317` consulta
  `FROM decks WHERE id = @deckId AND user_id = @userId`. O caminho de optimize
  atravessa `server/routes` para `server/lib` sem carregar o mesmo requisito.
- **Risco:** um usuario autenticado que obtenha um UUID de deck alheio pode
  potencialmente disparar analise/otimizacao sobre esse deck, expondo composicao
  privada e consumindo trabalho de IA.
- **O que valida:** alterar `loadOptimizeDeckContext` para receber `userId` e
  consultar `decks` com `id + user_id` ou uma regra publica explicita; adicionar
  teste owner vs non-owner para `POST /ai/optimize`, incluindo caminho `202`
  async e caminho sync.
- **O que falsifica:** contrato documentado e testado provando que optimize
  aceita decks publicos/alheios por design, com autorizacao explicita e resposta
  que nao exponha lista privada.

#### P1 — Polling de jobs async aceita jobs sem `user_id`, embora o app trate `job_id` como recurso autenticado

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:74`-`:87`
  trata `202` de optimize como job async e
  `app/lib/features/decks/providers/deck_provider_support_ai.dart:190`-`:194`
  faz polling em `/ai/optimize/jobs/$jobId`.
- **Store:** `server/lib/ai/optimize_job.dart:25`-`:30` permite criar jobs com
  `String? userId`; `server/lib/ai/optimize_job.dart:47`-`:64` persiste
  `user_id` nullable.
- **Handler:** `server/routes/ai/optimize/jobs/[id].dart:26` le o usuario
  autenticado, mas `server/routes/ai/optimize/jobs/[id].dart:39`-`:47` so
  bloqueia quando `job.userId != null && job.userId != userId`; jobs com
  `user_id = NULL` ficam legiveis para qualquer usuario com o `job_id`.
- **Por que e incoerente:** o app nao tem conceito de job publico; o endpoint
  fica sob `/ai` autenticado, mas a regra de acesso permite um estado nulo que
  enfraquece a fronteira de usuario.
- **Risco:** se algum job antigo, fallback em memoria, falha de contexto ou
  criacao interna persistir `user_id = NULL`, o resultado pode ser lido por outro
  usuario que conheca o ID.
- **O que valida:** exigir `userId` nao nulo em `OptimizeJobStore.create` para
  jobs user-facing e retornar 404 quando `job.userId == null` no endpoint de
  polling, exceto se houver rota interna separada.
- **O que falsifica:** prova de que nenhum job async app-facing pode ser criado
  sem usuario e teste de regressao cobrindo explicitamente a politica para
  `user_id = NULL`.

#### P2 — Endpoints experimentais de deck/AI usam `deck_id` autenticado sem ownership e nao tem consumidor app provado

- **Endpoints:** `GET /decks/:id/simulate`, `POST /decks/:id/recommendations`,
  `POST /ai/simulate-matchup`, `POST /ai/weakness-analysis`.
- **Evidencia de rotas:**
  - `server/routes/decks/[id]/simulate/index.dart:13`-`:26` le cartas com
    `WHERE dc.deck_id = @deckId`, sem buscar `context.read<String>()` nem
    validar `decks.user_id`.
  - `server/routes/decks/[id]/recommendations/index.dart:16`-`:27` consulta
    `SELECT name, format, description FROM decks WHERE id = @deckId`, e
    `server/routes/decks/[id]/recommendations/index.dart:39`-`:58` le cartas
    por `dc.deck_id = @deckId`, tambem sem `user_id`.
  - `server/routes/ai/simulate-matchup/index.dart:24`-`:38` le
    `my_deck_id`/`opponent_deck_id` e chama `_getDeckData`; essa funcao em
    `server/routes/ai/simulate-matchup/index.dart:76`-`:103` usa
    `SELECT id, name, format FROM decks WHERE id = @id` e cartas por
    `dc.deck_id = @id`.
  - `server/routes/ai/weakness-analysis/index.dart:17`-`:35` aceita `deck_id`
    e consulta `SELECT name, format FROM decks WHERE id = @id`; as cartas sao
    lidas em `server/routes/ai/weakness-analysis/index.dart:42`-`:60` por
    `dc.deck_id = @id`.
- **Evidencia app/contrato:** `rg` nao encontrou chamadas desses endpoints em
  `app/lib`; `server/doc/API_CONTRACTS_AND_DATA_MAP.md:152`-`:153` e `:285`-`:286`
  marca os consumidores como `not proven`/experimentais.
- **Por que e incoerente:** essas rotas vivem em namespaces autenticados
  (`server/routes/decks/_middleware.dart:7`-`:8` e
  `server/routes/ai/_middleware.dart:16`-`:20`), mas nao aplicam a mesma regra
  de ownership dos endpoints de deck consumidos pelo app. Como o app ainda nao
  consome esses contratos, a incoerencia pode ficar invisivel ate alguem ligar a
  UI.
- **Risco:** ao serem reutilizados pelo app, podem expor estatisticas,
  recomendacoes ou listas derivadas de deck privado de outro usuario.
- **O que valida:** antes de expor no app, escopar `my_deck_id`/`deck_id` por
  `user_id` e definir regra separada para oponente publico/meta deck; adicionar
  teste non-owner para cada rota mantida.
- **O que falsifica:** decisao explicita de tornar esses endpoints internos ou
  remove-los da superficie app-facing, com contrato atualizado e sem chamadas em
  `app/lib`.

#### P2 — `/community/decks/following` e app-facing, mas esta acoplado a branch especial de rota dinamica

- **Contrato app:** `app/lib/features/social/providers/social_provider.dart:563`-`:584`
  chama `/community/decks/following?page=...&limit=20` e registra o endpoint
  como `/community/decks/following`.
- **Handler:** nao existe `server/routes/community/decks/following/index.dart`;
  `server/routes/community/decks/[id].dart:10`-`:12` trata
  `id == 'following'` como caso especial e desvia para `_getFollowingFeed`.
- **Por que e incoerente:** a URI consumida pelo app representa uma colecao/feed,
  mas esta implementada como valor magico dentro do handler de detalhe
  `/community/decks/:id`, que tambem atende `GET /community/decks/:id` e
  `POST /community/decks/:id`.
- **Risco:** manutencao futura pode alterar o handler de detalhe ou validacao de
  UUID de `:id` e quebrar o feed de seguidores sem tocar no provider social; a
  documentacao tambem fica menos rastreavel porque o arquivo fisico nao expressa
  o contrato app-facing.
- **O que valida:** criar rota dedicada
  `server/routes/community/decks/following/index.dart` ou teste de contrato que
  preserve explicitamente esse caso especial.
- **O que falsifica:** decisao documentada de manter o branch magico por
  compatibilidade, com teste cobrindo `GET /community/decks/following` e
  `GET /community/decks/:id` no mesmo arquivo.

### Suspeitas revalidadas e descartadas nesta rodada

- `direct_message` nao foi classificado como incoerente: o backend cria
  notificacoes com `type: 'direct_message'` e `referenceId` de conversa em
  `server/routes/conversations/[id]/messages.dart:206`-`:217`, enquanto o app
  navega para `/messages/$refId` em
  `app/lib/features/notifications/screens/notification_screen.dart:152`-`:154`
  e no push coordinator em
  `app/lib/core/services/realtime_notification_coordinator.dart:117`-`:119`.
- `GET /cards?set=...` nao foi classificado como incoerente:
  `app/lib/features/collection/screens/set_cards_screen.dart:126`-`:128` envia
  `set` e `dedupe=true`, e `server/routes/cards/index.dart:17`-`:23`,
  `:136`-`:140` normaliza e aplica `setFilter`.
- `POST /ai/rebuild` nao foi classificado como incoerente:
  `server/routes/ai/rebuild/index.dart:61`-`:78` escopa o deck por
  `id + user_id` antes de carregar cartas e criar draft para o usuario.

## Rodada focada anterior: Duplicated or similar logic
> Data: 2026-05-28 12:40 UTC
> Rotacao local Codex: `duplicated-or-similar-logic`

## Rodada focada: Duplicated or similar logic

Escopo desta rodada: somente logica duplicada ou similar. Nao foi executada
auditoria ampla de classes sem uso, funcoes nao chamadas, imports, ciclos,
tabelas PostgreSQL ou coerencia geral entre camadas.

### Limitacao da ferramenta

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado conforme
o protocolo, mas falhou antes de gerar relatorio valido porque o script ainda usa
`BASE = Path("/opt/data/workspace/mtgia")` e tentou criar
`/opt/data/workspace/mtgia/docs/hermes-analysis` no Mac local, encerrando com
`PermissionError: [Errno 13] Permission denied: '/opt/data'`.

Resultado: os achados abaixo foram produzidos por inspeção manual focada em
helpers com mesmo nome/intencao e trechos de resposta equivalentes, usando `rg`
e leitura direta dos arquivos. Nao foi inventada saida do auditor.

### Achados confirmados

#### P1 — Heuristicas semanticas de combo/engine/payoff/enabler/wincon divergem em dois classificadores

- **Simbolos:** `_looksLikeWincon`, `_looksLikeComboPiece`,
  `_looksLikeEngine`, `_looksLikePayoff`, `_looksLikeEnabler`.
- **Evidencia 1:** `server/lib/ai/functional_card_tags.dart:319`,
  `:323`, `:327`, `:331`, `:335` chama esses helpers para tags v1, e as
  definicoes em `server/lib/ai/functional_card_tags.dart:859`-`:906` usam
  `oracle` + `normalizedName`.
- **Evidencia 2:** `server/lib/ai/optimization_functional_roles.dart:113`-`:117`
  chama helpers com os mesmos nomes para `classifyOptimizationFunctionalRole`,
  e as definicoes em `server/lib/ai/optimization_functional_roles.dart:370`-`:397`
  usam apenas `oracle` e um conjunto diferente de padroes.
- **Por que parece duplicado/similar:** ambos os modulos tentam classificar os
  mesmos papeis semanticos de alto nivel, mas com heuristicas independentes.
  Exemplo: `functional_card_tags.dart` trata nomes conhecidos como
  `thassa's oracle`, `isochron scepter`, `dramatic reversal`, `blood artist`,
  `greaves` e `boots`; `optimization_functional_roles.dart` nao consulta nome
  da carta nesses helpers.
- **Risco:** uma carta pode aparecer como `combo_piece`, `engine`, `payoff`,
  `enabler` ou `wincon` na analise funcional e receber outro papel no pipeline
  de optimize, criando drift entre explicabilidade e decisao de swap.
- **O que valida:** extrair uma fonte compartilhada de sinais semanticos ou
  adicionar testes cruzados que provem que a divergencia entre tags v1 e role
  classifier e intencional.
- **O que falsifica:** documentacao/testes mostrando que os dois classificadores
  possuem contratos diferentes por design e que cartas sentinela relevantes
  continuam coerentes nos dois fluxos.

#### P2 — `getMainType` e `calculateCmc` duplicam montagem de resposta de deck privado e publico

- **Simbolos:** `getMainType`, `calculateCmc`.
- **Evidencia 1:** `server/routes/decks/[id]/index.dart:405`-`:436` define
  `getMainType` e `calculateCmc` dentro da rota de deck privado; o mesmo bloco
  usa esses helpers em `server/routes/decks/[id]/index.dart:452` e `:464` para
  `mainBoard` e `manaCurve`.
- **Evidencia 2:** `server/routes/community/decks/[id].dart:91`-`:117` define
  helpers equivalentes na rota de deck publico; o uso equivalente aparece em
  `server/routes/community/decks/[id].dart:133` e `:141`.
- **Por que parece duplicado/similar:** as duas rotas constroem agrupamento por
  tipo, curva de mana e distribuicao de cores a partir de `cardsList`, com regras
  praticamente iguais para tipo principal e CMC.
- **Risco:** correcao de regra de CMC/tipo pode ser aplicada em uma rota e
  esquecida na outra, fazendo o mesmo deck apresentar estatisticas diferentes
  quando visto pelo dono e pela comunidade.
- **O que valida:** mover estatisticas compartilhadas para um helper de resposta
  de deck e cobrir deck privado/publico com o mesmo conjunto de fixtures.
- **O que falsifica:** testes de contrato provando que as respostas devem divergir
  e que as duas implementacoes locais estao travadas por fixtures equivalentes.

#### P2 — `_isBasicLandName` aparece com quatro variantes no backend

- **Simbolo:** `_isBasicLandName` / `isBasicLandName`.
- **Evidencia 1:** `server/lib/ai/optimize_runtime_support.dart:285` expoe
  `isBasicLandName`, mas a regra privada em
  `server/lib/ai/optimize_runtime_support.dart:4184`-`:4197` compara nomes
  exatos com hifen para snow-covered lands.
- **Evidencia 2:** `server/lib/generated_deck_validation_service.dart:752`-`:764`
  aceita `startsWith('snow-covered ...')`.
- **Evidencia 3:** `server/lib/meta/meta_deck_reference_support.dart:890`-`:903`
  aceita snow lands com espaco (`snow covered plains`) em vez de hifen.
- **Evidencia 4:** `server/routes/ai/commander-reference/index.dart:621`-`:629`
  reconhece apenas as seis basics nao snow.
- **Por que parece duplicado/similar:** todos os trechos respondem a mesma
  pergunta de dominio ("este nome e terreno basico?"), mas normalizam e aceitam
  casos diferentes.
- **Risco:** validacao, optimize, referencia de meta e commander-reference podem
  discordar sobre snow-covered lands ou nomes normalizados, especialmente em
  fluxos de singleton/legality.
- **O que valida:** centralizar a regra em um utilitario de dominio e adaptar os
  chamadores para normalizacao unica.
- **O que falsifica:** testes por contexto mostrando que cada variante menor e
  exigida por contrato diferente, incluindo casos com `Wastes` e snow lands.

#### P2 — Boilerplate de `request_id` e `invalid_payload` repetido em rotas sociais

- **Simbolos:** `_requestId`, `_logInvalidPayload`.
- **Evidencia:** `_requestId` aparece com corpo equivalente em
  `server/routes/trades/index.dart:330`-`:336`,
  `server/routes/trades/[id]/messages.dart:228`-`:234`,
  `server/routes/conversations/[id]/messages.dart:247`-`:253`,
  `server/routes/trades/[id]/respond.dart:154`-`:160`,
  `server/routes/trades/[id]/status.dart:260`-`:266` e
  `server/routes/users/[id]/follow/index.dart:97`-`:103`.
- **Evidencia adicional:** `_logInvalidPayload` repete o padrao de ler usuario,
  montar log `[social_write] invalid_payload` e anexar `request_id` em
  `server/routes/trades/index.dart:338`-`:352`,
  `server/routes/trades/[id]/messages.dart:236`-`:252`,
  `server/routes/conversations/[id]/messages.dart:255`-`:271`,
  `server/routes/trades/[id]/respond.dart:162`-`:178` e
  `server/routes/trades/[id]/status.dart:268`-`:284`.
- **Por que parece duplicado/similar:** a responsabilidade e identica
  (extrair `RequestTrace` com fallback e padronizar log de payload invalido),
  variando apenas endpoint e id de recurso.
- **Risco:** mudancas futuras no formato de log, fallback de `x-request-id` ou
  sanitizacao de usuario podem ficar inconsistentes entre trades e conversas.
- **O que valida:** helper compartilhado para social write logging aceitando
  endpoint e campos extras, com testes unitarios pequenos.
- **O que falsifica:** decisao explicita de manter logs por rota para evitar
  dependencia compartilhada, com teste que confira formato equivalente.

### Suspeitas revalidadas e ajustadas nesta rodada

- A duplicacao direta entre `server/routes/ai/optimize/index.dart` e
  `server/lib/ai/optimize_runtime_support.dart` para
  `matchesFunctionalNeed`, `scoreOptimizeReplacementCandidate`,
  `shouldRetryOptimizeWithAiFallback`, `computeOptimizeStructuralRecoverySwapTarget`,
  `isOptimizeStructuralRecoveryScenario` e `resolveOptimizeArchetype` nao foi
  confirmada como corpo duplicado nesta rodada: a rota possui wrappers finos que
  delegam para `optimize_support` em `server/routes/ai/optimize/index.dart:56`-`:132`.
- Ainda ha duplicacao/similaridade real em `resolveOptimizeArchetype`:
  `server/lib/ai/optimize_runtime_support.dart:3369`-`:3389` e
  `server/lib/ai/deck_state_analysis.dart:573`-`:584` resolvem requested vs
  detected archetype com listas genericas diferentes (`goodstuff`/`unknown` em
  um lado; `general`/`tempo` em outro).

## Rodada focada anterior: PostgreSQL tables not used
> Data: 2026-05-28 12:33 UTC
> Rotacao local Codex: `postgresql-tables-not-used`

### Escopo da rodada anterior

Escopo desta rodada: somente tabelas PostgreSQL sem uso ou com uso incoerente.
Nao foi executada auditoria ampla de classes, funcoes, imports ou duplicacao.

### Limitacao da ferramenta

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado conforme
o protocolo, mas falhou antes de gerar relatorio valido porque o script ainda usa
`BASE = Path("/opt/data/workspace/mtgia")` e tentou criar
`/opt/data/workspace/mtgia/docs/hermes-analysis` no Mac local, encerrando com
`PermissionError: [Errno 13] Permission denied: '/opt/data'`.

Resultado: os dados abaixo foram produzidos por inspeção manual do schema e de
referencias SQL em `server/`, sem inventar saida do auditor.

### Achados confirmados

#### P2 — `deck_matchups` é write-only no produto atual

- **Tabela:** `deck_matchups`
- **Definicao:** `server/database_setup.sql:162`
- **Escrita confirmada:** `server/routes/ai/simulate-matchup/index.dart:360` faz
  `INSERT INTO deck_matchups (...) ON CONFLICT (...) DO UPDATE`.
- **Leitura/consumo encontrado:** nenhum `SELECT ... FROM deck_matchups` em
  `app/`, `server/lib/` ou `server/routes/`; `rg` encontrou apenas a escrita da
  rota, definicoes/migrations e scripts/audits.
- **Por que parece nao usada:** a rota `POST /ai/simulate-matchup` retorna o
  resultado calculado na propria chamada, mas o snapshot salvo em
  `deck_matchups.win_rate/notes` nao alimenta cache, historico, ranking, UI ou
  contrato app-facing. `server/doc/API_CONTRACTS_AND_DATA_MAP.md` tambem marca
  `POST /ai/simulate-matchup` com consumidor `not proven`.
- **O que valida:** adicionar ou localizar um consumidor real que leia
  `deck_matchups`, por exemplo historico/cached matchup, dashboard ou reuso na
  simulacao.
- **O que falsifica:** um `SELECT ... FROM deck_matchups` em rota/lib consumida
  pelo app ou por job operacional documentado.

#### P2 — `deck_weakness_reports` acumula registros sem fluxo de leitura

- **Tabela:** `deck_weakness_reports`
- **Definicao:** `server/database_setup.sql:363` e
  `server/bin/migrate_create_missing_tables.dart:97`
- **Escrita confirmada:** `server/routes/ai/weakness-analysis/index.dart:374`
  faz `INSERT INTO deck_weakness_reports (...) ON CONFLICT DO NOTHING`.
- **Leitura/consumo encontrado:** nenhum `SELECT ... FROM deck_weakness_reports`
  em `app/`, `server/lib/` ou `server/routes`; `rg` encontrou somente a escrita,
  definicoes/migrations e artefatos de auditoria.
- **Por que parece nao usada:** `POST /ai/weakness-analysis` calcula e devolve
  `weaknesses` na resposta imediata, mas o dado persistido nao e listado,
  reaberto, marcado como `addressed` ou usado em analise futura. O campo
  `addressed` existe no schema e nao possui fluxo de update no codigo auditado.
- **O que valida:** criar/identificar endpoint, job ou UI que leia relatórios
  persistidos e atualize `addressed` quando o usuario corrige a fraqueza.
- **O que falsifica:** uma leitura real da tabela fora de migration/audit/teste,
  ou decisao explicita de manter a tabela apenas como log bruto com retencao.

### Suspeitas revalidadas e descartadas nesta rodada

- `battle_simulations` nao foi classificada como nao usada: a rota
  `server/routes/ai/simulate/index.dart:206` insere simulacoes e
  `server/bin/ml_extract_features.dart:75` le `FROM battle_simulations` para
  extracao de features.
- `ai_user_preferences` nao foi classificada como nao usada:
  `server/lib/ai/optimize_runtime_support.dart:3910` le preferencias e
  `server/lib/ai/optimize_runtime_support.dart:3947` persiste preferencias.
- Tabelas ML auxiliares como `card_meta_insights`, `synergy_packages`,
  `archetype_patterns`, `ml_prompt_feedback`, `format_staples`,
  `ai_logs`, `ai_optimize_cache` e `activation_funnel_events` possuem
  referencias de leitura/escrita em rotas, libs ou jobs operacionais e nao foram
  tratadas como achados de "nao usadas" nesta rotacao.

## Historico gerado pelo auditor estrutural anterior
> Data: 2026-05-28 04:08 UTC

## Arquivos Mapeados
- `server/lib/`: 81 arquivos
- `server/routes/`: 86 arquivos
- **Total**: 167 arquivos

## Classes por Arquivo
- `AggressiveCandidateQualitySignal` → `server/lib/ai/optimize_runtime_support.dart`
- `AiGenerateJob` → `server/lib/ai_generate_job.dart`
- `AiGenerateJobStore` → `server/lib/ai_generate_job.dart`
- `AiGenerateOpenAiTimeoutSelection` → `server/lib/ai_generate_performance_support.dart`
- `AiLogService` → `server/lib/ai_log_service.dart`
- `ArchetypeCountersService` → `server/lib/archetype_counters_service.dart`
- `ArchetypePattern` → `server/lib/ml_knowledge_service.dart`
- `AuthService` → `server/lib/auth_service.dart`
- `BattleResult` → `server/lib/ai/battle_simulator.dart`
- `BattleSimulator` → `server/lib/ai/battle_simulator.dart`
- `BracketFilterDecision` → `server/lib/edh_bracket_policy.dart`
- `BracketPolicy` → `server/lib/edh_bracket_policy.dart`
- `BracketTagResult` → `server/lib/edh_bracket_policy.dart`
- `CandidateFunctionTag` → `server/lib/ai/candidate_quality_data_support.dart`
- `CandidateRoleScore` → `server/lib/ai/candidate_quality_data_support.dart`
- `CardInsight` → `server/lib/ml_knowledge_service.dart`
- `CardRecommendation` → `server/lib/ml_knowledge_service.dart`
- `CardResolutionDecision` → `server/lib/card_resolution_support.dart`
- `CardValidationService` → `server/lib/card_validation_service.dart`
- `ColorIdentityBackfillDecision` → `server/lib/mtg_data_integrity_support.dart`
- `CommanderReferenceArchetypeStatsLoadResult` → `server/lib/ai/commander_reference_card_stats_support.dart`
- `CommanderReferenceCardStat` → `server/lib/ai/commander_reference_card_stats_support.dart`
- `CommanderReferenceCardStatsLoadResult` → `server/lib/ai/commander_reference_card_stats_support.dart`
- `CommanderReferenceCardStatsResolution` → `server/lib/ai/commander_reference_card_stats_support.dart`
- `CommanderReferenceCommanderCardResolution` → `server/lib/ai/commander_reference_card_stats_support.dart`
- `CommanderReferenceCorpusPackages` → `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `CommanderReferenceCorpusSummary` → `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `CommanderReferenceDeckAnalysis` → `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `CommanderReferenceDeckCardInput` → `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `CommanderReferenceDeckCorpusGuidance` → `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `CommanderReferenceDeckInput` → `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `CommanderReferenceReadinessInputs` → `server/lib/ai/commander_reference_readiness_support.dart`
- `CommanderReferenceReadinessRuntimeProof` → `server/lib/ai/commander_reference_readiness_support.dart`
- `CommanderReferenceReadinessScorecard` → `server/lib/ai/commander_reference_readiness_support.dart`
- `CommanderShellMetadata` → `server/lib/meta/meta_deck_commander_shell_support.dart`
- `CompleteBuildAccumulator` → `server/lib/ai/optimize_complete_support.dart`
- `Database` → `server/lib/database.dart`
- `DeckArchetypeAnalyzer` → `server/routes/ai/optimize/index.dart`
- `DeckArchetypeAnalyzerCore` → `server/lib/ai/optimize_state_support.dart`
- `DeckOptimizationState` → `server/routes/ai/optimize/index.dart`
- `DeckOptimizationStateResult` → `server/lib/ai/optimize_state_support.dart`
- `DeckOptimizerService` → `server/lib/ai/otimizacao.dart`
- `DeckRulesException` → `server/lib/deck_rules_service.dart`
- `DeckRulesService` → `server/lib/deck_rules_service.dart`
- `DeckThemeProfile` → `server/routes/ai/optimize/index.dart`
- `DeckThemeProfileResult` → `server/lib/ai/optimize_state_support.dart`
- `DistributedRateLimiter` → `server/lib/distributed_rate_limiter.dart`
- `EdhTop16TournamentEntry` → `server/lib/meta/external_commander_deck_expansion_support.dart`
- `EdhrecAverageDeckCard` → `server/lib/ai/edhrec_service.dart`
- `EdhrecAverageDeckData` → `server/lib/ai/edhrec_service.dart`
- `EdhrecCard` → `server/lib/ai/edhrec_service.dart`
- `EdhrecCommanderData` → `server/lib/ai/edhrec_service.dart`
- `EdhrecService` → `server/lib/ai/edhrec_service.dart`
- `EndpointCache` → `server/lib/endpoint_cache.dart`
- `EndpointMetricSnapshot` → `server/lib/request_metrics_service.dart`
- `ExpandedDeckCard` → `server/lib/meta/external_commander_deck_expansion_support.dart`
- `ExpandedTopDeckDeck` → `server/lib/meta/external_commander_deck_expansion_support.dart`
- `ExternalCommanderMetaCandidate` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `ExternalCommanderMetaCandidateIllegalCard` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `ExternalCommanderMetaCandidateLegalityEvidence` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `ExternalCommanderMetaCandidateLegalityRepository` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `ExternalCommanderMetaCandidateUnresolvedCard` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `ExternalCommanderMetaCandidateValidationResult` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `ExternalCommanderMetaControlledSourcePolicy` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `ExternalCommanderMetaEligibilityBatch` → `server/lib/meta/external_commander_meta_operational_runner_support.dart`
- `ExternalCommanderMetaEligibilityDecision` → `server/lib/meta/external_commander_meta_operational_runner_support.dart`
- `ExternalCommanderMetaImportConfig` → `server/lib/meta/external_commander_meta_import_support.dart`
- `ExternalCommanderMetaOperationalConfig` → `server/lib/meta/external_commander_meta_operational_runner_support.dart`
- `ExternalCommanderMetaPersistencePlan` → `server/lib/meta/external_commander_meta_import_support.dart`
- `ExternalCommanderMetaPromotionConfig` → `server/lib/meta/external_commander_meta_promotion_support.dart`
- `ExternalCommanderMetaPromotionInsertPlan` → `server/lib/meta/external_commander_meta_promotion_support.dart`
- `ExternalCommanderMetaPromotionIssue` → `server/lib/meta/external_commander_meta_promotion_support.dart`
- `ExternalCommanderMetaPromotionPlan` → `server/lib/meta/external_commander_meta_promotion_support.dart`
- `ExternalCommanderMetaPromotionResult` → `server/lib/meta/external_commander_meta_promotion_support.dart`
- `ExternalCommanderMetaPromotionSnapshot` → `server/lib/meta/external_commander_meta_promotion_support.dart`
- `ExternalCommanderMetaStagingConfig` → `server/lib/meta/external_commander_meta_staging_support.dart`
- `ExternalCommanderMetaStagingPlan` → `server/lib/meta/external_commander_meta_staging_support.dart`
- `ExternalCommanderMetaValidationIssue` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `FormatStaplesService` → `server/lib/ai/format_staples_service.dart`
- `FunctionalCardTag` → `server/lib/ai/functional_card_tags.dart`
- `FunctionalDeckSummary` → `server/lib/ai/functional_card_tags.dart`
- `FunctionalReport` → `server/lib/ai/optimization_validator.dart`
- `GameAction` → `server/lib/ai/battle_simulator.dart`
- `GameCard` → `server/lib/ai/battle_simulator.dart`
- `GeneratedDeckRepository` → `server/lib/generated_deck_validation_service.dart`
- `GeneratedDeckValidationResult` → `server/lib/generated_deck_validation_service.dart`
- `GeneratedDeckValidationService` → `server/lib/generated_deck_validation_service.dart`
- `GoldfishResult` → `server/lib/ai/goldfish_simulator.dart`
- `GoldfishSimulator` → `server/lib/ai/goldfish_simulator.dart`
- `HateCardsService` → `server/lib/ai/hate_cards_service.dart`
- `ImportListParseResult` → `server/lib/import_list_service.dart`
- `InternalAiRequestToken` → `server/lib/internal_ai_request_token.dart`
- `Log` → `server/lib/logger.dart`
- `MLContext` → `server/lib/ml_knowledge_service.dart`
- `MLKnowledgeService` → `server/lib/ml_knowledge_service.dart`
- `Magic` → `server/routes/ai/generate/index.dart`
- `ManaAnalysis` → `server/routes/decks/[id]/analysis/index.dart`
- `MarketMoversCache` → `server/lib/market_movers.dart`
- `MatchupAnalyzer` → `server/lib/ai/goldfish_simulator.dart`
- `MatchupResult` → `server/lib/ai/goldfish_simulator.dart`
- `MetaDeckAnalyticsContext` → `server/lib/meta/meta_deck_analytics_support.dart`
- `MetaDeckFormatDescriptor` → `server/lib/meta/meta_deck_format_support.dart`
- `MetaDeckReferenceCandidate` → `server/lib/meta/meta_deck_reference_support.dart`
- `MetaDeckReferenceQueryParts` → `server/lib/meta/meta_deck_reference_support.dart`
- `MetaDeckReferenceSelectionResult` → `server/lib/meta/meta_deck_reference_support.dart`
- `MonteCarloComparison` → `server/lib/ai/optimization_validator.dart`
- `MtgTop8EventDeckRow` → `server/lib/meta/mtgtop8_meta_support.dart`
- `MulliganReport` → `server/lib/ai/optimization_validator.dart`
- `NotificationService` → `server/lib/notification_service.dart`
- `OpenAiRuntimeConfig` → `server/lib/openai_runtime_config.dart`
- `OptimizationSemanticV2EnforcementDecision` → `server/lib/ai/optimization_functional_roles.dart`
- `OptimizationSwapGateResult` → `server/lib/ai/optimization_quality_gate.dart`
- `OptimizationValidator` → `server/lib/ai/optimization_validator.dart`
- `OptimizeDeckContextData` → `server/lib/ai/optimize_request_support.dart`
- `OptimizeDeckContextException` → `server/lib/ai/optimize_request_support.dart`
- `OptimizeIntensityConfig` → `server/lib/ai/optimize_runtime_support.dart`
- `OptimizeJob` → `server/lib/ai/optimize_job.dart`
- `OptimizeJobStore` → `server/lib/ai/optimize_job.dart`
- `OptimizeStageTelemetry` → `server/lib/ai/optimize_stage_telemetry.dart`
- `ParsedMetaDeckCardEntry` → `server/lib/meta/meta_deck_card_list_support.dart`
- `ParsedMetaDeckCardList` → `server/lib/meta/meta_deck_card_list_support.dart`
- `PlanService` → `server/lib/plan_service.dart`
- `PlayerState` → `server/lib/ai/battle_simulator.dart`
- `PostgresExternalCommanderMetaCandidateLegalityRepository` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `PostgresGeneratedDeckRepository` → `server/lib/generated_deck_validation_service.dart`
- `PushNotificationService` → `server/lib/push_notification_service.dart`
- `RateLimiter` → `server/lib/rate_limit_middleware.dart`
- `RebuildException` → `server/lib/ai/rebuild_guided_service.dart`
- `RebuildGuidedService` → `server/lib/ai/rebuild_guided_service.dart`
- `RebuildResult` → `server/lib/ai/rebuild_guided_service.dart`
- `RebuildScopeDecision` → `server/lib/ai/rebuild_guided_service.dart`
- `RebuildTargetProfile` → `server/lib/ai/rebuild_guided_service.dart`
- `ReferenceGeneratedCardsIdentityFilterResult` → `server/lib/ai/commander_reference_generate_fallback_support.dart`
- `ReferenceGeneratedDeckEvaluation` → `server/lib/ai/commander_reference_card_stats_support.dart`
- `RequestMetricsService` → `server/lib/request_metrics_service.dart`
- `RequestTrace` → `server/lib/request_trace.dart`
- `SemanticCardAnalysisV2` → `server/lib/ai/functional_card_tags.dart`
- `SwapFunctionalAnalysis` → `server/lib/ai/optimization_validator.dart`
- `SynergyEngine` → `server/lib/ai/sinergia.dart`
- `SynergyPackage` → `server/lib/ml_knowledge_service.dart`
- `ThemeCheck` → `server/lib/ai/theme_contextual_rules_service.dart`
- `ThemeContextualRule` → `server/lib/ai/theme_contextual_rules_service.dart`
- `ThemeContextualRulesService` → `server/lib/ai/theme_contextual_rules_service.dart`
- `ThemeValidationResult` → `server/lib/ai/theme_contextual_rules_service.dart`
- `UserPlanSnapshot` → `server/lib/plan_service.dart`
- `ValidationReport` → `server/lib/ai/optimization_validator.dart`
- `_CacheItem` → `server/lib/endpoint_cache.dart`
- `_CachedAverageDeckResult` → `server/lib/ai/edhrec_service.dart`
- `_CachedResult` → `server/lib/ai/edhrec_service.dart`
- `_CardData` → `server/lib/deck_rules_service.dart`
- `_DeckMetrics` → `server/routes/decks/[id]/ai-analysis/index.dart`
- `_DeckStats` → `server/lib/ai/goldfish_simulator.dart`
- `_EndpointMetricBucket` → `server/lib/request_metrics_service.dart`
- `_ExternalCommanderMetaParsedCardEntry` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `_InfluencedCardInsight` → `server/lib/meta/meta_deck_reference_support.dart`
- `_LandTrimContext` → `server/lib/ai/optimization_quality_gate.dart`
- `_MarketMoversCacheEntry` → `server/lib/market_movers.dart`
- `_ParsedTradeItems` → `server/routes/trades/index.dart`
- `_PasswordPreparation` → `server/lib/auth_service.dart`
- `_PlayDecision` → `server/lib/ai/battle_simulator.dart`
- `_PromotionDeckProfile` → `server/lib/meta/external_commander_meta_promotion_support.dart`
- `_QueryBuilder` → `server/routes/cards/index.dart`
- `_RankedMetaDeckReference` → `server/lib/meta/meta_deck_reference_support.dart`
- `_ResolvedExternalCommanderMetaCardEntry` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `_SimCard` → `server/routes/decks/[id]/simulate/index.dart`
- `_TelemetryQuery` → `server/routes/ai/optimize/telemetry/index.dart`
- `_WeightedCard` → `server/lib/ai/rebuild_guided_service.dart`

## Imports Potencialmente Quebrados
- `server/routes/ai/_middleware.dart` importa `../../lib/auth_middleware.dart` (não encontrado)
- `server/routes/ai/_middleware.dart` importa `../../lib/plan_middleware.dart` (não encontrado)
- `server/routes/ai/_middleware.dart` importa `../../lib/rate_limit_middleware.dart` (não encontrado)
- `server/routes/ai/archetypes/index.dart` importa `../../../lib/endpoint_cache.dart` (não encontrado)
- `server/routes/ai/archetypes/index.dart` importa `../../../lib/ai/commander_reference_profile_support.dart` (não encontrado)
- `server/routes/ai/archetypes/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/ai/archetypes/index.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/ai/archetypes/index.dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/ai/archetypes/index.dart` importa `../../../lib/openai_runtime_config.dart` (não encontrado)
- `server/routes/ai/commander-reference/index.dart` importa `../../../lib/ai/edhrec_service.dart` (não encontrado)
- `server/routes/ai/commander-reference/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/ai/commander-reference/index.dart` importa `../../../lib/meta/meta_deck_card_list_support.dart` (não encontrado)
- `server/routes/ai/commander-reference/index.dart` importa `../../../lib/meta/meta_deck_format_support.dart` (não encontrado)
- `server/routes/ai/commander-reference/index.dart` importa `../../../lib/meta/mtgtop8_meta_support.dart` (não encontrado)
- `server/routes/ai/explain/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/ai/explain/index.dart` importa `../../../lib/openai_runtime_config.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/ai_generate_job.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/ai_generate_internal_url_support.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/ai_generate_performance_support.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/ai/commander_reference_card_stats_support.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/ai/commander_reference_deck_corpus_support.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/ai/commander_reference_generate_fallback_support.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/ai/commander_reference_profile_support.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/ai/functional_card_tags.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/color_identity.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/generated_deck_validation_service.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/import_card_lookup_service.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/internal_ai_request_token.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/meta/meta_deck_format_support.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/meta/meta_deck_reference_support.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/ai/generate/index.dart` importa `../../../lib/openai_runtime_config.dart` (não encontrado)
- `server/routes/ai/ml-status/index.dart` importa `../../../lib/database.dart` (não encontrado)
- `server/routes/ai/ml-status/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/color_identity.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/card_validation_service.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/optimize_analysis_support.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/optimize_complete_support.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/optimize_deck_support.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/optimize_request_support.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/optimize_state_support.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/optimize_stage_telemetry.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/otimizacao.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/optimization_functional_roles.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/optimization_quality_gate.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/optimize_runtime_support.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/optimize_runtime_support.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/optimization_validator.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/edhrec_service.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/optimize_job.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai/theme_contextual_rules_service.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/ai_generate_internal_url_support.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/internal_ai_request_token.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/edh_bracket_policy.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/meta/meta_deck_reference_support.dart` (não encontrado)
- `server/routes/ai/optimize/index.dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/ai/rebuild/index.dart` importa `../../../lib/ai/rebuild_guided_service.dart` (não encontrado)
- `server/routes/ai/rebuild/index.dart` importa `../../../lib/ai/deck_state_analysis.dart` (não encontrado)
- `server/routes/ai/rebuild/index.dart` importa `../../../lib/deck_rules_service.dart` (não encontrado)
- `server/routes/ai/rebuild/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/ai/simulate/index.dart` importa `../../../lib/ai/battle_simulator.dart` (não encontrado)
- `server/routes/ai/simulate/index.dart` importa `../../../lib/ai/goldfish_simulator.dart` (não encontrado)
- `server/routes/ai/simulate/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/ai/simulate/index.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/ai/simulate-matchup/index.dart` importa `../../../lib/archetype_counters_service.dart` (não encontrado)
- `server/routes/ai/simulate-matchup/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/ai/simulate-matchup/index.dart` importa `../../../lib/meta/meta_deck_card_list_support.dart` (não encontrado)
- `server/routes/ai/weakness-analysis/index.dart` importa `../../../lib/archetype_counters_service.dart` (não encontrado)
- `server/routes/ai/weakness-analysis/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/auth/_middleware.dart` importa `../../lib/rate_limit_middleware.dart` (não encontrado)
- `server/routes/auth/login.dart` importa `../../lib/auth_service.dart` (não encontrado)
- `server/routes/auth/login.dart` importa `../../lib/observability.dart` (não encontrado)
- `server/routes/auth/me.dart` importa `../../lib/auth_service.dart` (não encontrado)
- `server/routes/auth/register.dart` importa `../../lib/auth_service.dart` (não encontrado)
- `server/routes/auth/register.dart` importa `../../lib/observability.dart` (não encontrado)
- `server/routes/binder/[id]/index.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/binder/[id]/index.dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/binder/_middleware.dart` importa `../../lib/auth_middleware.dart` (não encontrado)
- `server/routes/binder/index.dart` importa `../../lib/logger.dart` (não encontrado)
- `server/routes/binder/index.dart` importa `../../lib/observability.dart` (não encontrado)
- `server/routes/cards/index.dart` importa `../../lib/card_query_contract.dart` (não encontrado)
- `server/routes/cards/index.dart` importa `../../lib/endpoint_cache.dart` (não encontrado)
- `server/routes/cards/index.dart` importa `../../lib/scryfall_image_url.dart` (não encontrado)
- `server/routes/cards/printings/index.dart` importa `../../../lib/scryfall_image_url.dart` (não encontrado)
- `server/routes/cards/resolve/index.dart` importa `../../../lib/card_resolution_support.dart` (não encontrado)
- `server/routes/cards/resolve/index.dart` importa `../../../lib/scryfall_image_url.dart` (não encontrado)
- `server/routes/community/decks/[id].dart` importa `../../../lib/auth_service.dart` (não encontrado)
- `server/routes/community/decks/[id].dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/community/decks/[id].dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/community/decks/[id].dart` importa `../../../lib/scryfall_image_url.dart` (não encontrado)
- `server/routes/community/decks/index.dart` importa `../../../lib/scryfall_image_url.dart` (não encontrado)
- `server/routes/community/decks/index.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/community/decks/index.dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/community/marketplace/index.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/community/marketplace/index.dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/community/users/[id].dart` importa `../../../lib/auth_service.dart` (não encontrado)
- `server/routes/community/users/[id].dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/community/users/[id].dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/community/users/index.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/community/users/index.dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/conversations/[id]/messages.dart` importa `../../../lib/notification_service.dart` (não encontrado)
- `server/routes/conversations/[id]/messages.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/conversations/[id]/messages.dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/conversations/[id]/messages.dart` importa `../../../lib/request_trace.dart` (não encontrado)
- `server/routes/conversations/[id]/read.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/conversations/[id]/read.dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/conversations/_middleware.dart` importa `../../lib/auth_middleware.dart` (não encontrado)
- `server/routes/conversations/index.dart` importa `../../lib/logger.dart` (não encontrado)
- `server/routes/conversations/index.dart` importa `../../lib/observability.dart` (não encontrado)
- `server/routes/conversations/unread-count.dart` importa `../../lib/logger.dart` (não encontrado)
- `server/routes/conversations/unread-count.dart` importa `../../lib/observability.dart` (não encontrado)
- `server/routes/decks/[id]/index.dart` importa `../../../lib/deck_rules_service.dart` (não encontrado)
- `server/routes/decks/[id]/index.dart` importa `../../../lib/deck_schema_support.dart` (não encontrado)
- `server/routes/decks/[id]/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/decks/[id]/index.dart` importa `../../../lib/scryfall_image_url.dart` (não encontrado)
- `server/routes/decks/_middleware.dart` importa `../../lib/auth_middleware.dart` (não encontrado)
- `server/routes/decks/index.dart` importa `../../lib/deck_schema_support.dart` (não encontrado)
- `server/routes/decks/index.dart` importa `../../lib/deck_rules_service.dart` (não encontrado)
- `server/routes/decks/index.dart` importa `../../lib/http_responses.dart` (não encontrado)
- `server/routes/decks/index.dart` importa `../../lib/logger.dart` (não encontrado)
- `server/routes/decks/index.dart` importa `../../lib/observability.dart` (não encontrado)
- `server/routes/decks/index.dart` importa `../../lib/scryfall_image_url.dart` (não encontrado)
- `server/routes/health/dashboard/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/health/dashboard/index.dart` importa `../../../lib/request_metrics_service.dart` (não encontrado)
- `server/routes/health/index.dart` importa `../../lib/http_responses.dart` (não encontrado)
- `server/routes/health/metrics/index.dart` importa `../../../lib/request_metrics_service.dart` (não encontrado)
- `server/routes/health/metrics/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/health/ready/index.dart` importa `../../../lib/health_readiness_support.dart` (não encontrado)
- `server/routes/health/ready/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/import/_middleware.dart` importa `../../lib/auth_middleware.dart` (não encontrado)
- `server/routes/import/index.dart` importa `../../lib/deck_rules_service.dart` (não encontrado)
- `server/routes/import/index.dart` importa `../../lib/http_responses.dart` (não encontrado)
- `server/routes/import/index.dart` importa `../../lib/import_card_lookup_service.dart` (não encontrado)
- `server/routes/import/index.dart` importa `../../lib/import_list_service.dart` (não encontrado)
- `server/routes/import/to-deck/index.dart` importa `../../../lib/deck_rules_service.dart` (não encontrado)
- `server/routes/import/to-deck/index.dart` importa `../../../lib/import_card_lookup_service.dart` (não encontrado)
- `server/routes/import/to-deck/index.dart` importa `../../../lib/import_list_service.dart` (não encontrado)
- `server/routes/import/to-deck/index.dart` importa `../../../lib/http_responses.dart` (não encontrado)
- `server/routes/import/validate/index.dart` importa `../../../lib/import_list_service.dart` (não encontrado)
- `server/routes/import/validate/index.dart` importa `../../../lib/import_card_lookup_service.dart` (não encontrado)
- `server/routes/notifications/[id]/read.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/notifications/[id]/read.dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/notifications/_middleware.dart` importa `../../lib/auth_middleware.dart` (não encontrado)
- `server/routes/notifications/count.dart` importa `../../lib/logger.dart` (não encontrado)
- `server/routes/notifications/count.dart` importa `../../lib/observability.dart` (não encontrado)
- `server/routes/notifications/index.dart` importa `../../lib/logger.dart` (não encontrado)
- `server/routes/notifications/index.dart` importa `../../lib/observability.dart` (não encontrado)
- `server/routes/notifications/read-all.dart` importa `../../lib/logger.dart` (não encontrado)
- `server/routes/notifications/read-all.dart` importa `../../lib/observability.dart` (não encontrado)
- `server/routes/sets/index.dart` importa `../../lib/endpoint_cache.dart` (não encontrado)
- `server/routes/sets/index.dart` importa `../../lib/sets_catalog_contract.dart` (não encontrado)
- `server/routes/trades/[id]/index.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/trades/[id]/index.dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/trades/[id]/messages.dart` importa `../../../lib/notification_service.dart` (não encontrado)
- `server/routes/trades/[id]/messages.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/trades/[id]/messages.dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/trades/[id]/messages.dart` importa `../../../lib/request_trace.dart` (não encontrado)
- `server/routes/trades/[id]/respond.dart` importa `../../../lib/notification_service.dart` (não encontrado)
- `server/routes/trades/[id]/respond.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/trades/[id]/respond.dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/trades/[id]/respond.dart` importa `../../../lib/request_trace.dart` (não encontrado)
- `server/routes/trades/[id]/status.dart` importa `../../../lib/notification_service.dart` (não encontrado)
- `server/routes/trades/[id]/status.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/trades/[id]/status.dart` importa `../../../lib/observability.dart` (não encontrado)
- `server/routes/trades/[id]/status.dart` importa `../../../lib/request_trace.dart` (não encontrado)
- `server/routes/trades/_middleware.dart` importa `../../lib/auth_middleware.dart` (não encontrado)
- `server/routes/trades/index.dart` importa `../../lib/notification_service.dart` (não encontrado)
- `server/routes/trades/index.dart` importa `../../lib/logger.dart` (não encontrado)
- `server/routes/trades/index.dart` importa `../../lib/observability.dart` (não encontrado)
- `server/routes/trades/index.dart` importa `../../lib/request_trace.dart` (não encontrado)
- `server/routes/users/_middleware.dart` importa `../../lib/auth_middleware.dart` (não encontrado)
- `server/routes/users/me/index.dart` importa `../../../lib/auth_middleware.dart` (não encontrado)
- `server/routes/users/me/index.dart` importa `../../../lib/logger.dart` (não encontrado)
- `server/routes/users/me/index.dart` importa `../../../lib/observability.dart` (não encontrado)

## Funções Públicas (primeiros 5 por arquivo)
- `server/lib/ai/aggressive_candidate_meta_signal_support.dart` (194 linhas): isCommanderCandidateLegalityAllowed, isExternalCommanderCandidateTrusted, confidenceLabel, scoreAggressiveMetaSignal, bracketScopeForMetaSignal
- `server/lib/ai/battle_simulator.dart` (880 linhas): resetForNewTurn, toString, drawCard, shuffle
- `server/lib/ai/candidate_quality_data_support.dart` (693 linhas): normalizeCandidateQualityKey, normalizeCandidateQualityRole, add, inferCandidateBudgetTier, inferCandidateBracketScope
- `server/lib/ai/commander_reference_card_stats_support.dart` (1368 linhas): normalizeCommanderReferenceCardName, buildCommanderReferenceCardStatsPrompt, buildCommanderReferenceArchetypeStatsPrompt
- `server/lib/ai/commander_reference_deck_corpus_support.dart` (1490 linhas): normalizeCommanderReferenceDeckText, buildReferenceDeckKey, buildCommanderReferenceDeckCorpusPrompt, shouldUseCompactCommanderReferenceCorpusPrompt, classifyCommanderReferenceDeckCardRole
- `server/lib/ai/commander_reference_generate_fallback_support.dart` (370 linhas): addCard
- `server/lib/ai/commander_reference_profile_support.dart` (543 linhas): normalizeCommanderReferenceName, normalizeCommanderReferenceConfidence, isLoreholdCommanderReferenceCandidate, isReferenceProfileConfidenceUsable, commanderReferenceConfidenceRank
- `server/lib/ai/commander_reference_readiness_support.dart` (495 linhas): block
- `server/lib/ai/deck_state_analysis.dart` (586 linhas): detectArchetype, addReason, resolveOptimizeArchetype
- `server/lib/ai/edhrec_service.dart` (466 linhas): cleanupCache, isHighSynergy, toString
- `server/lib/ai/functional_card_tags.dart` (1053 linhas): count, add, normalizeFunctionalCardName
- `server/lib/ai/hate_cards_service.dart` (160 linhas): generatePromptContext
- `server/lib/ai/optimization_functional_roles.dart` (399 linhas): looksLikeOptimizationBoardWipeText, looksLikeOptimizationRampText, looksLikeOptimizationLandSearchText, classifyOptimizationFunctionalRole
- `server/lib/ai/optimize_complete_support.dart` (1560 linhas): calculateCompleteMaxBasicAdditions, addUnique, rebalanceCompleteDeckForLandDeficit, mergeUniqueSpells
- `server/lib/ai/optimize_deck_support.dart` (180 linhas): commanderSignalsSpellslinger, commanderSignalsArtifacts, commanderSignalsEnchantments
- `server/lib/ai/optimize_runtime_support.dart` (4198 linhas): normalizeOptimizeReasoning, resolveOptimizeMode, clampRequestedSwapCount, shouldUseAsyncOptimizeExecutor, isBasicLandName
- `server/lib/ai/optimize_stage_telemetry.dart` (85 linhas): start, stop, logSummary
- `server/lib/ai/optimize_state_support.dart` (982 linhas): detectArchetype, assessManaBase, assessManaCurve, calculateConfidence, addReason
- `server/lib/ai/otimizacao.dart` (1046 linhas): addAll
- `server/lib/ai/rebuild_guided_service.dart` (1748 linhas): addWeight, toString
- `server/lib/ai/theme_contextual_rules_service.dart` (109 linhas): archetypeToTheme
- `server/lib/ai_generate_performance_support.dart` (197 linhas): normalizeAiGeneratePrompt, normalizeAiGenerateFormat, normalizeAiGenerateBracket, normalizeAiGenerateCommanderName, buildAiGenerateCacheKey
- `server/lib/ai_log_service.dart` (236 linhas): Function
- `server/lib/auth_middleware.dart` (85 linhas): getUserId
- `server/lib/auth_service.dart` (297 linhas): hashPassword, verifyPassword, normalizeEmail, normalizeUsername, generateToken
- `server/lib/card_validation_service.dart` (248 linhas): sanitizeCardName
- `server/lib/color_identity.dart` (61 linhas): isWithinCommanderIdentity
- `server/lib/deck_rules_service.dart` (503 linhas): toString
- `server/lib/endpoint_cache.dart` (37 linhas): set, clearExpired
- `server/lib/generated_deck_validation_service.dart` (819 linhas): addLookupName
- `server/lib/health_readiness_support.dart` (21 linhas): readinessStatusCode
- `server/lib/import_card_lookup_service.dart` (451 linhas): cleanImportLookupKey, foldImportLookupKey, canonicalizeImportLookupName, normalizeLocalizedImportName
- `server/lib/internal_ai_request_token.dart` (22 linhas): matches
- `server/lib/log_sanitizer.dart` (59 linhas): sanitizeLogMessage
- `server/lib/logger.dart` (40 linhas): d, print, i, print, w
- `server/lib/market_movers.dart` (240 linhas): normalizeMarketMoversLimit, toInt, set
- `server/lib/meta/external_commander_deck_expansion_support.dart` (638 linhas): edhTop16TournamentIdFromUrl
- `server/lib/meta/external_commander_meta_candidate_support.dart` (1333 linhas): addName, normalizeCommanderMetaFormat, normalizeExternalCommanderMetaValidationStatus, canonicalizeExternalCommanderMetaSourceName
- `server/lib/meta/external_commander_meta_promotion_support.dart` (748 linhas): buildMetaDeckCardListFingerprint
- `server/lib/meta/meta_deck_analytics_support.dart` (85 linhas): classifyMetaDeckSource
- `server/lib/meta/meta_deck_card_list_support.dart` (93 linhas): parseMetaDeckCardList, isCommanderMetaFormat, normalizeMetaDeckCardName
- `server/lib/meta/meta_deck_commander_shell_support.dart` (356 linhas): metaDeckNeedsCommanderShellRefresh, inferCommanderStrategyArchetypeFromCardNames
- `server/lib/meta/meta_deck_format_support.dart` (181 linhas): normalizeCommanderMetaScope, commanderMetaScopeLabel, metaDeckAnalyticsFormatKey
- `server/lib/meta/meta_deck_reference_support.dart` (938 linhas): buildMetaDeckEvidenceText
- `server/lib/meta/mtgtop8_meta_support.dart` (166 linhas): extractMtgTop8Placement, resolveMtgTop8Url
- `server/lib/ml_knowledge_service.dart` (502 linhas): generatePromptContext
- `server/lib/notification_service.dart` (140 linhas): createFromActorDeferred, Function
- `server/lib/observability.dart` (249 linhas): isSentryEnabled
- `server/lib/openai_runtime_config.dart` (150 linhas): shouldUseFallbackForInvalidApiKey, modelFor, intFor
- `server/lib/rate_limit_middleware.dart` (402 linhas): Function, Function, buildClientIdentifierFromHeaders, isAllowed, cleanup
- `server/lib/request_metrics_service.dart` (107 linhas): add, record
- `server/lib/request_trace.dart` (58 linhas): generateRequestId, resolveRequestId
- `server/lib/sets_catalog_contract.dart` (61 linhas): safeSetCatalogLimit, safeSetCatalogPage, resolveSetStatus
- `server/routes/ai/optimize/index.dart` (3498 linhas): resolveOptimizeArchetype, shouldRetryOptimizeWithAiFallback, matchesFunctionalNeed, scoreOptimizeReplacementCandidate, isOptimizeStructuralRecoveryScenario
- `server/routes/community/decks/[id].dart` (428 linhas): getMainType, calculateCmc
- `server/routes/decks/[id]/index.dart` (538 linhas): getMainType, calculateCmc

## Funções Não Chamadas (Execução 2 — 2026-05-28 04:00 UTC)
> Foco: funções públicas definidas em `server/lib/` que NÃO são chamadas de nenhum outro arquivo.

**Resumo:** 155 funções públicas identificadas em lib/ · **118 chamadas** de outros arquivos · **37 NÃO chamadas**

### Arquivos afetados e funções sem chamadas:

- `server/lib/ai/battle_simulator.dart` (879 linhas):
  - `drawCard()` — lógica de compra de carta potencialmente órfã
  - `resetForNewTurn()` — reset de turno sem referência externa

- `server/lib/ai/candidate_quality_data_support.dart` (692 linhas):
  - `inferCandidateBracketScope()` — inferência de bracket não utilizada
  - `isPremiumCommanderCandidateName()` — verificação de premium sem chamador

- `server/lib/ai/commander_reference_deck_corpus_support.dart` (1489 linhas):
  - `buildReferenceDeckKey()` — builder de key sem uso externo
  - `normalizeCommanderReferenceDeckText()` — normalizador sem chamada

- `server/lib/ai/commander_reference_readiness_support.dart` (494 linhas):
  - `block()` — função de bloqueio sem referência

- `server/lib/ai/edhrec_service.dart` (465 linhas):
  - `cleanupCache()` — limpeza de cache não invocada externamente
  - `isHighSynergy()` — verificação de sinergia sem chamador

- `server/lib/ai/optimize_complete_support.dart` (1559 linhas):
  - `mergeUniqueSpells()` — merge de spells sem uso externo

- `server/lib/ai/optimize_runtime_support.dart` (4198 linhas — **maior arquivo do projeto**):
  - `clampRequestedSwapCount()` — clamping sem referência
  - `commanderFillerQualityScore()` — score de filler órfão
  - `inferOptimizeFunctionalNeed()` — inferência sem chamador
  - `landProducesCommanderColors()` — verificação de mana órfã
  - `looksLikeBoardWipe()` — detecção de wipe sem uso
  - `looksLikeProtectionEffect()` — detecção de proteção sem uso
  - `looksLikeTemporaryManaBurst()` — detecção de burst sem uso
  - `recommendedLandCountForOptimizeArchetype()` — recomendação órfã
  - `resolveOptimizeMode()` — resolução de modo sem chamador

- `server/lib/ai/optimize_state_support.dart` (981 linhas):
  - `assessManaCurve()` — avaliação de curva não chamada
  - `calculateConfidence()` — cálculo de confiança sem uso
  - `qty()` — função qty órfã

- `server/lib/ai/rebuild_guided_service.dart` (1748 linhas):
  - `addWeight()` — adição de peso sem referência externa

- `server/lib/ai_generate_performance_support.dart` (196 linhas):
  - `isCommanderReferenceGuidanceFormat()` — verificação sem uso
  - `normalizeAiGenerateBracket()` — normalizador órfão
  - `normalizeAiGenerateCommanderName()` — normalizador órfão
  - `normalizeAiGeneratePrompt()` — normalizador órfão

- `server/lib/endpoint_cache.dart` (37 linhas):
  - `clearExpired()` — limpeza de expirados não invocada

- `server/lib/generated_deck_validation_service.dart` (818 linhas):
  - `addLookupName()` — lookup sem chamador

- `server/lib/import_card_lookup_service.dart` (450 linhas):
  - `foldImportLookupKey()` — key folder órfão

- `server/lib/meta/external_commander_meta_candidate_support.dart` (1332 linhas):
  - `addName()` — adição de nome sem uso
  - `canonicalizeExternalCommanderMetaSourceName()` — canonicalizador órfão
  - `normalizeCommanderMetaFormat()` — normalizador órfão
  - `normalizeExternalCommanderMetaValidationStatus()` — normalizador órfão

- `server/lib/meta/meta_deck_commander_shell_support.dart` (355 linhas):
  - `inferCommanderStrategyArchetypeFromCardNames()` — inferência de arquétipo sem chamador

- `server/lib/observability.dart` (248 linhas):
  - `isSentryEnabled()` — feature flag sem uso

- `server/lib/request_trace.dart` (57 linhas):
  - `generateRequestId()` — gerador de trace sem referência externa

### Observações:
1. **server/lib/ai/optimize_runtime_support.dart** é o maior arquivo (4198 linhas) com 9 funções órfãs — candidato prioritário para refatoração.
2. **server/lib/ai_generate_performance_support.dart** tem TODAS as 4 funções extraídas sem chamadores externos.
3. Algumas funções podem ser usadas internamente (dentro do mesmo arquivo) via closure ou callback — análise manual recomendada para confirmação.
4. As funções `cleanupCache`, `clearExpired` e `addLookupName` sugéren manutenção não sendo disparada de nenhum lugar (verificar se são chamadas por timer/evento externo).

### Execução anterior (Classes não usadas):
> Ver seção "Classes Não Chamadas" para Execução 1 (00:00 UTC).

## Tabelas PostgreSQL Referenciadas no Código
- `LATERAL`: 9 referências
- `activation_funnel_events`: 1 referências
- `ai_generate_jobs`: 1 referências
- `ai_logs`: 3 referências
- `ai_optimize_cache`: 1 referências
- `ai_optimize_fallback_telemetry`: 3 referências
- `ai_optimize_jobs`: 1 referências
- `ai_user_preferences`: 1 referências
- `archetype_counters`: 2 referências
- `archetype_patterns`: 2 referências
- `canonical_sets`: 2 referências
- `card_function_tags`: 4 referências
- `card_legalities`: 12 referências
- `card_localized_names`: 1 referências
- `card_meta_insights`: 6 referências
- `card_role_scores`: 2 referências
- `card_semantic_tags_v2`: 5 referências
- `cards`: 45 referências
- `checks`: 1 referências
- `commander_card_synergy`: 2 referências
- `commander_reference_card_stats`: 1 referências
- `commander_reference_deck_analysis`: 1 referências
- `commander_reference_deck_cards`: 1 referências
- `commander_reference_decks`: 1 referências
- `commander_reference_profiles`: 5 referências
- `conversations`: 4 referências
- `current_trade`: 2 referências
- `deck_cards`: 25 referências
- `deck_usage`: 1 referências
- `decks`: 24 referências
- `direct_messages`: 4 referências
- `external_commander_meta_candidates`: 1 referências
- `filtered_sets`: 1 referências
- `follower_counts`: 2 referências
- `following_counts`: 2 referências
- `format_staples`: 1 referências
- `have`: 1 referências
- `history`: 2 referências
- `information_schema`: 6 referências
- `input_names`: 1 referências
- `inserted`: 1 referências
- `jsonb_to_recordset`: 1 referências
- `latest`: 1 referências
- `meta_decks`: 6 referências
- `ml_learning_state`: 1 referências
- `ml_prompt_feedback`: 1 referências
- `movers`: 1 referências
- `notifications`: 2 referências
- `offer`: 1 referências
- `offering_items`: 1 referências
- `optimization_analysis_logs`: 2 referências
- `optimize_candidate_quality_summary`: 1 referências
- `optimize_rejection_penalties`: 2 referências
- `owned`: 1 referências
- `paged_users`: 1 referências
- `penalty_rows`: 1 referências
- `previous_prices`: 1 referências
- `price_history`: 3 referências
- `public_deck_counts`: 2 referências
- `rate_limit_events`: 1 referências
- `regexp_matches`: 9 referências
- `requested`: 1 referências
- `requesting_items`: 1 referências
- `role_rows`: 1 referências
- `rules`: 1 referências
- `sets`: 6 referências
- `sync_state`: 1 referências
- `synergy_packages`: 2 referências
- `synergy_rows`: 1 referências
- `tag_rows`: 1 referências
- `theme_contextual_rules`: 1 referências
- `today_prices`: 1 referências
- `totals`: 1 referências
- `trade_items`: 2 referências
- `trade_messages`: 3 referências
- `trade_offers`: 6 referências
- `trade_status_history`: 3 referências
- `unnest`: 2 referências
- `updated`: 2 referências
- `user_binder_items`: 6 referências
- `user_follows`: 6 referências
- `user_plans`: 1 referências
- `users`: 19 referências
- `validation`: 2 referências
- `want`: 1 referências

## Problemas Estruturais Identificados
- `server/lib/ai/candidate_quality_data_support.dart` referencia `semantic_tags_v2` mas não faz INSERT/UPDATE
- `server/lib/ai/functional_card_tags.dart` referencia `semantic_tags_v2` mas não faz INSERT/UPDATE
- `server/lib/ai/optimization_functional_roles.dart` referencia `semantic_tags_v2` mas não faz INSERT/UPDATE
- `server/lib/ai/optimize_request_support.dart` referencia `semantic_tags_v2` mas não faz INSERT/UPDATE
- `server/routes/ai/optimize/index.dart` referencia `semantic_tags_v2` mas não faz INSERT/UPDATE
- `server/routes/decks/[id]/analysis/index.dart` referencia `semantic_tags_v2` mas não faz INSERT/UPDATE
- Classe `AggressiveCandidateQualitySignal` é definida mas potencialmente não é usada em outros arquivos
- Classe `AiGenerateOpenAiTimeoutSelection` é definida mas potencialmente não é usada em outros arquivos
- Classe `ArchetypePattern` é definida mas potencialmente não é usada em outros arquivos
- Classe `BattleResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `BracketFilterDecision` é definida mas potencialmente não é usada em outros arquivos
- Classe `BracketTagResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `CandidateFunctionTag` é definida mas potencialmente não é usada em outros arquivos
- Classe `CandidateRoleScore` é definida mas potencialmente não é usada em outros arquivos
- Classe `CardRecommendation` é definida mas potencialmente não é usada em outros arquivos
- Classe `ColorIdentityBackfillDecision` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceArchetypeStatsLoadResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceCardStatsLoadResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceCardStatsResolution` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceCommanderCardResolution` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceCorpusPackages` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceCorpusSummary` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceDeckAnalysis` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceDeckCardInput` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceDeckInput` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceReadinessInputs` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceReadinessRuntimeProof` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceReadinessScorecard` é definida mas potencialmente não é usada em outros arquivos
- Classe `EdhTop16TournamentEntry` é definida mas potencialmente não é usada em outros arquivos
- Classe `EdhrecAverageDeckCard` é definida mas potencialmente não é usada em outros arquivos
- Classe `EdhrecCard` é definida mas potencialmente não é usada em outros arquivos
- Classe `EndpointMetricSnapshot` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExpandedDeckCard` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExpandedTopDeckDeck` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaCandidateIllegalCard` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaCandidateLegalityEvidence` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaCandidateLegalityRepository` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaCandidateUnresolvedCard` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaEligibilityBatch` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaEligibilityDecision` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaImportConfig` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaOperationalConfig` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaPersistencePlan` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaPromotionConfig` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaPromotionInsertPlan` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaPromotionIssue` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaPromotionPlan` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaPromotionResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaPromotionSnapshot` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaStagingConfig` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaStagingPlan` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaValidationIssue` é definida mas potencialmente não é usada em outros arquivos
- Classe `FunctionalReport` é definida mas potencialmente não é usada em outros arquivos
- Classe `GameAction` é definida mas potencialmente não é usada em outros arquivos
- Classe `GameCard` é definida mas potencialmente não é usada em outros arquivos
- Classe `GeneratedDeckValidationResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `ImportListParseResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `MLContext` é definida mas potencialmente não é usada em outros arquivos
- Classe `ManaAnalysis` é definida mas potencialmente não é usada em outros arquivos
- Classe `MatchupResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `MetaDeckAnalyticsContext` é definida mas potencialmente não é usada em outros arquivos
- Classe `MetaDeckReferenceQueryParts` é definida mas potencialmente não é usada em outros arquivos
- Classe `MonteCarloComparison` é definida mas potencialmente não é usada em outros arquivos
- Classe `MulliganReport` é definida mas potencialmente não é usada em outros arquivos
- Classe `OptimizationSemanticV2EnforcementDecision` é definida mas potencialmente não é usada em outros arquivos
- Classe `OptimizationSwapGateResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `ParsedMetaDeckCardEntry` é definida mas potencialmente não é usada em outros arquivos
- Classe `PlayerState` é definida mas potencialmente não é usada em outros arquivos
- Classe `PostgresExternalCommanderMetaCandidateLegalityRepository` é definida mas potencialmente não é usada em outros arquivos
- Classe `RebuildResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `RebuildScopeDecision` é definida mas potencialmente não é usada em outros arquivos
- Classe `RebuildTargetProfile` é definida mas potencialmente não é usada em outros arquivos
- Classe `ReferenceGeneratedCardsIdentityFilterResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `ReferenceGeneratedDeckEvaluation` é definida mas potencialmente não é usada em outros arquivos
- Classe `SwapFunctionalAnalysis` é definida mas potencialmente não é usada em outros arquivos
- Classe `SynergyPackage` é definida mas potencialmente não é usada em outros arquivos
- Classe `ThemeCheck` é definida mas potencialmente não é usada em outros arquivos
- Classe `UserPlanSnapshot` é definida mas potencialmente não é usada em outros arquivos
- Classe `_CacheItem` é definida mas potencialmente não é usada em outros arquivos
- Classe `_CachedAverageDeckResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `_CachedResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `_CardData` é definida mas potencialmente não é usada em outros arquivos
- Classe `_DeckMetrics` é definida mas potencialmente não é usada em outros arquivos
- Classe `_DeckStats` é definida mas potencialmente não é usada em outros arquivos
- Classe `_EndpointMetricBucket` é definida mas potencialmente não é usada em outros arquivos
- Classe `_ExternalCommanderMetaParsedCardEntry` é definida mas potencialmente não é usada em outros arquivos
- Classe `_InfluencedCardInsight` é definida mas potencialmente não é usada em outros arquivos
- Classe `_LandTrimContext` é definida mas potencialmente não é usada em outros arquivos
- Classe `_MarketMoversCacheEntry` é definida mas potencialmente não é usada em outros arquivos
- Classe `_ParsedTradeItems` é definida mas potencialmente não é usada em outros arquivos
- Classe `_PasswordPreparation` é definida mas potencialmente não é usada em outros arquivos
- Classe `_PlayDecision` é definida mas potencialmente não é usada em outros arquivos
- Classe `_PromotionDeckProfile` é definida mas potencialmente não é usada em outros arquivos
- Classe `_QueryBuilder` é definida mas potencialmente não é usada em outros arquivos
- Classe `_RankedMetaDeckReference` é definida mas potencialmente não é usada em outros arquivos
- Classe `_ResolvedExternalCommanderMetaCardEntry` é definida mas potencialmente não é usada em outros arquivos
- Classe `_SimCard` é definida mas potencialmente não é usada em outros arquivos
- Classe `_TelemetryQuery` é definida mas potencialmente não é usada em outros arquivos
- Classe `_WeightedCard` é definida mas potencialmente não é usada em outros arquivos
- Arquivos grandes (>500 linhas):
  - `server/lib/ai/optimize_runtime_support.dart`: 4198 linhas
  - `server/routes/ai/optimize/index.dart`: 3498 linhas
  - `server/lib/ai/rebuild_guided_service.dart`: 1748 linhas
  - `server/routes/ai/generate/index.dart`: 1656 linhas
  - `server/lib/ai/optimize_complete_support.dart`: 1560 linhas
  - `server/lib/ai/commander_reference_deck_corpus_support.dart`: 1490 linhas
  - `server/lib/ai/commander_reference_card_stats_support.dart`: 1368 linhas
  - `server/lib/meta/external_commander_meta_candidate_support.dart`: 1333 linhas
  - `server/lib/ai/functional_card_tags.dart`: 1053 linhas
  - `server/lib/ai/otimizacao.dart`: 1046 linhas
  - `server/lib/ai/optimize_state_support.dart`: 982 linhas
  - `server/lib/meta/meta_deck_reference_support.dart`: 938 linhas
  - `server/lib/ai/optimization_validator.dart`: 891 linhas
  - `server/lib/ai/battle_simulator.dart`: 880 linhas
  - `server/lib/generated_deck_validation_service.dart`: 819 linhas
  - `server/lib/meta/external_commander_meta_promotion_support.dart`: 748 linhas
  - `server/lib/ai/candidate_quality_data_support.dart`: 693 linhas
  - `server/routes/cards/resolve/index.dart`: 691 linhas
  - `server/routes/trades/index.dart`: 649 linhas
  - `server/routes/ai/commander-reference/index.dart`: 641 linhas
  - `server/lib/meta/external_commander_deck_expansion_support.dart`: 638 linhas
  - `server/lib/ai/goldfish_simulator.dart`: 606 linhas
  - `server/lib/ai/deck_state_analysis.dart`: 586 linhas
  - `server/routes/ai/archetypes/index.dart`: 564 linhas
  - `server/routes/decks/[id]/recommendations/index.dart`: 560 linhas
  - `server/routes/decks/[id]/ai-analysis/index.dart`: 552 linhas
  - `server/lib/ai/commander_reference_profile_support.dart`: 543 linhas
  - `server/routes/decks/[id]/index.dart`: 538 linhas
  - `server/routes/decks/[id]/analysis/index.dart`: 521 linhas
  - `server/lib/deck_rules_service.dart`: 503 linhas
  - `server/lib/ml_knowledge_service.dart`: 502 linhas
  - `server/lib/ai/optimization_quality_gate.dart`: 501 linhas
- Funções com nomes duplicados:
  - `Function` em: server/lib/ai_log_service.dart, server/lib/notification_service.dart, server/lib/rate_limit_middleware.dart, server/lib/rate_limit_middleware.dart, server/lib/rate_limit_middleware.dart
  - `_generateId` em: server/lib/ai/optimize_job.dart, server/lib/ai_generate_job.dart
  - `_getCmc` em: server/lib/ai/goldfish_simulator.dart, server/lib/ai/goldfish_simulator.dart, server/lib/ai/optimization_quality_gate.dart, server/lib/ai/optimization_validator.dart
  - `_hasResearchPayloadValue` em: server/lib/meta/external_commander_meta_candidate_support.dart, server/lib/meta/external_commander_meta_staging_support.dart
  - `_intValue` em: server/lib/ai/commander_reference_deck_corpus_support.dart, server/lib/ai/commander_reference_readiness_support.dart
  - `_isBasicLandName` em: server/lib/ai/optimize_runtime_support.dart, server/lib/generated_deck_validation_service.dart, server/lib/meta/meta_deck_reference_support.dart, server/routes/ai/commander-reference/index.dart
  - `_isLand` em: server/lib/ai/goldfish_simulator.dart, server/lib/ai/optimization_validator.dart
  - `_logInvalidPayload` em: server/routes/conversations/[id]/messages.dart, server/routes/trades/[id]/messages.dart, server/routes/trades/[id]/respond.dart, server/routes/trades/[id]/status.dart, server/routes/trades/index.dart
  - `_looksLikeComboPiece` em: server/lib/ai/functional_card_tags.dart, server/lib/ai/optimization_functional_roles.dart
  - `_looksLikeEnabler` em: server/lib/ai/functional_card_tags.dart, server/lib/ai/optimization_functional_roles.dart
  - `_looksLikeEngine` em: server/lib/ai/functional_card_tags.dart, server/lib/ai/optimization_functional_roles.dart
  - `_looksLikePayoff` em: server/lib/ai/functional_card_tags.dart, server/lib/ai/optimization_functional_roles.dart
  - `_looksLikeWincon` em: server/lib/ai/functional_card_tags.dart, server/lib/ai/optimization_functional_roles.dart
  - `_readInt` em: server/lib/meta/external_commander_meta_operational_runner_support.dart, server/lib/meta/external_commander_meta_staging_support.dart
  - `_readListLength` em: server/lib/meta/external_commander_meta_operational_runner_support.dart, server/lib/meta/external_commander_meta_staging_support.dart
  - `_requestId` em: server/routes/conversations/[id]/messages.dart, server/routes/trades/[id]/messages.dart, server/routes/trades/[id]/respond.dart, server/routes/trades/[id]/status.dart, server/routes/trades/index.dart, server/routes/users/[id]/follow/index.dart
  - `_responseTimeSql` em: server/routes/trades/[id]/index.dart, server/routes/trades/index.dart
  - `_shippingTimeSql` em: server/routes/trades/[id]/index.dart, server/routes/trades/index.dart
  - `_sourceCount` em: server/lib/ai/commander_reference_card_stats_support.dart, server/lib/ai/commander_reference_profile_support.dart
  - `_stableDeckSeed` em: server/lib/ai/goldfish_simulator.dart, server/lib/ai/optimization_validator.dart
  - `_stableHash` em: server/lib/ai/optimize_runtime_support.dart, server/routes/ai/archetypes/index.dart
  - `_sumQuantities` em: server/lib/meta/meta_deck_card_list_support.dart, server/routes/import/index.dart, server/routes/import/to-deck/index.dart
  - `_toInt` em: server/lib/ai/optimize_runtime_support.dart, server/routes/ai/ml-status/index.dart, server/routes/ai/optimize/telemetry/index.dart, server/routes/binder/[id]/index.dart, server/routes/community/marketplace/index.dart, server/routes/trades/[id]/index.dart, server/routes/trades/index.dart
  - `_trustStatsSql` em: server/routes/trades/[id]/index.dart, server/routes/trades/index.dart
  - `_validateCondition` em: server/routes/decks/[id]/cards/index.dart, server/routes/decks/[id]/cards/set/index.dart
  - `add` em: server/lib/ai/candidate_quality_data_support.dart, server/lib/ai/functional_card_tags.dart, server/lib/request_metrics_service.dart
  - `addReason` em: server/lib/ai/deck_state_analysis.dart, server/lib/ai/optimize_state_support.dart
  - `addUnique` em: server/lib/ai/optimize_complete_support.dart, server/lib/ai/optimize_runtime_support.dart
  - `calculateCmc` em: server/routes/community/decks/[id].dart, server/routes/decks/[id]/index.dart
  - `computeOptimizeStructuralRecoverySwapTarget` em: server/lib/ai/optimize_runtime_support.dart, server/routes/ai/optimize/index.dart
  - `detectArchetype` em: server/lib/ai/deck_state_analysis.dart, server/lib/ai/optimize_state_support.dart
  - `generatePromptContext` em: server/lib/ai/hate_cards_service.dart, server/lib/ml_knowledge_service.dart
  - `getMainType` em: server/routes/community/decks/[id].dart, server/routes/decks/[id]/index.dart
  - `isOptimizeStructuralRecoveryScenario` em: server/lib/ai/optimize_runtime_support.dart, server/routes/ai/optimize/index.dart
  - `matchesFunctionalNeed` em: server/lib/ai/optimize_runtime_support.dart, server/routes/ai/optimize/index.dart
  - `print` em: server/lib/logger.dart, server/lib/logger.dart, server/lib/logger.dart, server/lib/logger.dart
  - `resolveOptimizeArchetype` em: server/lib/ai/deck_state_analysis.dart, server/lib/ai/optimize_runtime_support.dart, server/routes/ai/optimize/index.dart
  - `scoreOptimizeReplacementCandidate` em: server/lib/ai/optimize_runtime_support.dart, server/routes/ai/optimize/index.dart
  - `set` em: server/lib/endpoint_cache.dart, server/lib/market_movers.dart
  - `shouldRetryOptimizeWithAiFallback` em: server/lib/ai/optimize_runtime_support.dart, server/routes/ai/optimize/index.dart
  - `toString` em: server/lib/ai/battle_simulator.dart, server/lib/ai/edhrec_service.dart, server/lib/ai/rebuild_guided_service.dart, server/lib/deck_rules_service.dart

## Gaps Conhecidos (manual)
- `card_function_tags`: 112K multi-tag records, mas otimizador usa `classifyOptimizationFunctionalRole()` (single-tag)
- `card_deck_profiles`: 670 perfis, mas `filterUnsafeOptimizeSwapsByCardData` não consulta
- `semantic_layer_v2`: Shadow mode (diagnóstico sem poder de veto)
- `archetype_patterns`: 69 registros, não validado contra código

## Rodada focada: Semantica de cartas no runtime
> Data: 2026-05-28 13:41 UTC
> Rotacao local Codex: `local-manaloom-card-semantics-audit`

Escopo desta rodada: nomes de cartas hardcoded em codigo de produto/runtime,
drift entre `functional_tags`, `semantic_tags_v2` e classificacao funcional do
optimize, e pontos onde utilidade ainda e inferida por nome ou por regra
unidimensional. A leitura priorizou `server/lib`, `server/routes` e `app/lib`.
Testes, docs, exemplos de UI, corpus e artefatos foram usados apenas para
separar fixtures permitidas de logica runtime.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: sem saida relevante.
- `git checkout codex/hermes-analysis-docs`: branch ja ativo e atualizado.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo antes das edicoes documentais desta rodada.

### Revalidacao apos ajustes na `master`
> Data: 2026-05-28 15:26 UTC
> Comando: `manaloom-fix-verifier-copilot.sh --target master`
> Commit verificado: `00437690` (`origin/master`)

Resultado: **PARTIAL**. Os pontos abaixo foram removidos do backlog ativo desta
rodada porque o verificador confirmou correcao na `master`:

- `summarizeFunctionalTagsForDeck` agora usa/documenta a prioridade
  `functional_tags_then_semantic_v2_then_heuristic`.
- O optimize preserva conjuntos de roles via `optimizationFunctionalRolesForCard`
  e calcula `role_delta` multi-role.
- Existem testes focados cobrindo semantic v2 e perda secundaria multi-tag.
- `API_CONTRACTS_AND_DATA_MAP.md` e `server/manual-de-instrucao.md` documentam
  prioridade semantica, multi-tags, diagnosticos de optimize e fallback policy.

Atualizacao Copilot 2026-05-28: `origin/master@65f30387` resolveu tambem as
politicas por nome restantes apontadas abaixo via
`server/lib/ai/commander_fallback_policy.dart`, alem de hardening owner-scoped
em `POST /ai/archetypes`.

Permanecem ativos somente os achados abaixo que nao foram marcados como
resolvidos por esta atualizacao.

#### P1 - Politicas por nome ainda nao estao totalmente centralizadas/versionadas

- **Status em `origin/master@65f30387`: RESOLVIDO para as listas apontadas pelo
  verificador.** Fallbacks universais de Commander, premium lands, high-power e
  candidate-quality premium foram centralizados em
  `server/lib/ai/commander_fallback_policy.dart`.
- **Evidencia revalidada:** o verificador encontrou scoring/listas como
  `premiumLandNames` em `server/lib/ai/optimize_runtime_support.dart` e conjuntos
  premium/high-power em `server/lib/ai/candidate_quality_data_support.dart`.
- **Por que ainda e risco:** parte da decisao de utilidade/bracket/score segue
  embutida no codigo em vez de estar em uma policy versionada, tabela/config ou
  dados semanticos auditaveis.
- **O que valida:** mover as excecoes restantes para modulo/tabela/config de
  policy com versao, `source`, `reason`, `bracket_scope` e testes focados.
- **O que falsifica:** documentacao e testes que declarem explicitamente essas
  excecoes como politica de produto intencional e versionada.

#### P2 - Endpoints experimentais de recomendacao/weakness seguem legacy, mas nao sao fluxo app-facing confirmado

- **Simbolos:** `POST /decks/:id/recommendations`,
  `POST /ai/weakness-analysis`.
- **Status:** `PASS with caveat` na revalidacao. Os contratos os marcam como
  experimentais/not-proven/advisory e nao foi encontrado consumidor direto no
  app; a pendencia permanece apenas antes de exposicao futura ou promocao a
  fluxo de produto.
- **Evidencia 1:** `server/routes/decks/[id]/recommendations/index.dart:110`-`:130`
  conta ramp/draw/removal/wipes/protection por `oracle_text` local, sem
  `functional_tags` ou `semantic_tags_v2`. Quando faltam terrenos Commander,
  `server/routes/decks/[id]/recommendations/index.dart:262`-`:267` adiciona
  `Command Tower` diretamente.
- **Evidencia 2:** `server/routes/ai/weakness-analysis/index.dart:114`-`:163`
  tambem conta categorias por `oracle_text`, `type_line`, `cmc` e dois nomes
  (`teferi's protection`, `heroic intervention`), sem v2. As recomendacoes sao
  listas fixas de nomes em `server/routes/ai/weakness-analysis/index.dart:206`-`:248`
  e `server/routes/ai/weakness-analysis/index.dart:266`-`:285`.
- **Evidencia 3:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md:152` e
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md:286` marcam esses endpoints como
  experimentais/not proven para consumo app atual.
- **Por que ainda e risco:** se essas rotas forem ligadas ao app, o usuario recebera
  recomendacoes que parecem produto runtime, mas ainda sao one-dimensional e
  parcialmente name-based, sem a camada semantica v2 que o fluxo core ja tenta
  carregar.
- **O que valida:** antes de expor no app, reusar `summarizeFunctionalTagsForDeck`
  e candidate-quality/semantic data, e trocar listas fixas por query filtrada por
  role, legalidade, identidade de cor, bracket e disponibilidade.
- **O que falsifica:** decisao explicita de manter essas rotas apenas como
  demos/diagnosticos internos, com contrato removido da superficie app-facing.

### Ocorrencias permitidas ou descartadas

- Testes, fixtures, corpus e artefatos com nomes como `Sol Ring`,
  `Command Tower`, `Thassa's Oracle`, `Isochron Scepter` e `Blood Artist` foram
  tratados como permitidos quando servem de fixture ou prova de regressao
  (`server/test/**`, `server/test/artifacts/**`).
- Exemplos de UX/contrato tambem foram tratados como permitidos:
  placeholders de import em `app/lib/features/decks/screens/deck_import_screen.dart`,
  `app/lib/features/decks/widgets/deck_import_list_dialog.dart`,
  mensagens de erro em `server/routes/import/**`, comentarios de
  `/cards/resolve/batch` e comentarios de limpeza de nome em
  `server/lib/card_validation_service.dart`.
- `server/lib/ai/prompt.md` e `server/lib/ai/prompt_complete.md` contem nomes
  em texto de prompt. Isso e runtime prompt material, mas nao foi classificado
  nesta rodada como decisao direta por nome porque a decisao final ainda passa
  por validacao/quality gate. O risco relevante ficou documentado nos pontos em
  que o codigo escolhe, ranqueia ou classifica nomes diretamente.
