# ManaLoom Code Structure Audit
> Atualizacao local Codex: 2026-06-06 23:00 UTC
> Rotacao: `module-coherence-server-lib-routes-app-lib`
> Branch de memoria: `codex/hermes-analysis-docs`

## Rodada focada: Coherence between modules — revalidacao 2026-06-06 23:00 UTC

Escopo desta rodada: somente coerencia entre `server/lib`, `server/routes` e
`app/lib`. Nao foi feita auditoria ampla de classes sem uso, funcoes sem
chamada, ciclos/imports fora do auditor base, tabelas PostgreSQL sem uso ou
duplicacao geral fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `1fbc07d8`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 171.
- Classes encontradas: 169.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor cobre `server/lib` e `server/routes`,
mas nao entende consumidores Flutter nem contratos entre app, rota e service.
A execucao tambem reescreveu `STRUCTURE_AUDIT.md` porque o arquivo atual nao
tem o marcador de merge esperado; essa mutacao automatica foi descartada para
preservar o historico manual, e somente os numeros acima mais os achados
focados abaixo foram incorporados.

### Metodo manual focado

- `rg` por consumidores app de `/ai/optimize`, `/ai/optimize/jobs`,
  `/ai/generate`, `/ai/generate/jobs`, `/ai/archetypes`, `/ai/rebuild`,
  `/users/me/activation-events`, `functional_tags` e `semantic_tags_v2`.
- Leitura pontual das rotas e supports que carregam dados de deck:
  `server/routes/ai/optimize/index.dart`,
  `server/lib/ai/optimize_request_support.dart`,
  `server/routes/ai/archetypes/index.dart`,
  `server/routes/ai/rebuild/index.dart`,
  `server/routes/decks/[id]/analysis/index.dart` e
  `server/routes/decks/[id]/ai-analysis/index.dart`.
- Leitura dos stores/polling de jobs async:
  `server/lib/ai/optimize_job.dart`, `server/lib/ai_generate_job.dart`,
  `server/routes/ai/optimize/jobs/[id].dart` e
  `server/routes/ai/generate/jobs/[id].dart`.
- Checagem de controles positivos owner-scoped em `/ai/rebuild`,
  `/decks/:id/analysis` e `/decks/:id/ai-analysis`.

### Achados revalidados

#### P1 — `POST /ai/optimize` e `POST /ai/archetypes` continuam app-facing sem owner-scope no loader real

- **Consumidores app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:10`-`:23`
  monta payload de optimize com `deck_id`; `:56` chama `POST /ai/optimize`.
  `app/lib/features/decks/providers/deck_provider_support_mutation.dart:168`-`:173`
  chama `POST /ai/archetypes` com `deck_id`.
- **Rota optimize:** `server/routes/ai/optimize/index.dart:401`-`:406` le
  `userId`, mas `:545`-`:559` chama
  `optimize_request.loadOptimizeDeckContext(...)` sem passar `userId`.
- **Support optimize:** `server/lib/ai/optimize_request_support.dart:53`-`:62`
  nao aceita `userId`; a query do deck em `:63`-`:73` usa
  `SELECT name, format FROM decks WHERE id = @id`; a query de cartas em
  `:87`-`:137` usa `WHERE dc.deck_id = @id`.
- **Rota archetypes:** `server/routes/ai/archetypes/index.dart:39`-`:42`
  busca `SELECT name, format FROM decks WHERE id = @id`; `:54`-`:62` carrega
  cartas por `WHERE dc.deck_id = @id`.
- **Por que e incoerente:** o app trata os dois endpoints como operacoes do
  deck autenticado, e os contratos documentam AI como app-facing, mas a camada
  `routes -> server/lib` nao propaga ownership para o SQL que efetivamente
  carrega deck/cartas.
- **Controles positivos:** `server/routes/ai/rebuild/index.dart:62`-`:78`
  busca `decks` por `id + user_id`; `server/routes/decks/[id]/analysis/index.dart:22`-`:31`
  e `server/routes/decks/[id]/ai-analysis/index.dart:35`-`:47` tambem fazem
  gate por `deck_id + user_id` antes de carregar cartas.
- **O que valida:** passar `userId` para `loadOptimizeDeckContext`, escopar
  `decks` por `id + user_id` ou regra publica explicita, aplicar o mesmo padrao
  em `/ai/archetypes` e adicionar teste owner vs non-owner.
- **O que falsifica:** contrato e teste provando que estes endpoints podem
  operar em decks publicos/de terceiros sem vazar composicao privada.

#### P1/P2 — Polling de jobs app-facing ainda aceita jobs com `user_id = NULL`

- **Consumidores app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:190`-`:211`
  faz polling de `/ai/optimize/jobs/$jobId`; `app/lib/features/decks/providers/deck_provider_support_generation.dart:230`-`:301`
  solicita `/ai/generate` com `async=true` e depois usa `poll_url`.
- **Stores permitem nulo:** `server/lib/ai/optimize_job.dart:25`-`:42` cria
  `OptimizeJob` com `String? userId`; `:54` persiste
  `CAST(@user_id AS uuid)`. `server/lib/ai_generate_job.dart:12`-`:17` tambem
  aceita `String? userId`, e o schema em `:164`-`:167` permite `user_id` nulo
  por `ON DELETE SET NULL`.
- **Polling optimize:** `server/routes/ai/optimize/jobs/[id].dart:26`-`:49`
  le o usuario autenticado, mas so bloqueia quando
  `job.userId != null && job.userId != userId`; jobs nulos passam.
- **Polling generate:** `server/routes/ai/generate/jobs/[id].dart:16`-`:29`
  usa a mesma regra: `job == null || (job.userId != null && job.userId != userId)`.
- **Por que e incoerente:** os jobs sao consumidos por fluxo app autenticado,
  mas a rota de leitura preserva um estado sem dono como legivel por qualquer
  usuario que conheca o ID.
- **O que valida:** exigir `userId` nao nulo na criacao de jobs app-facing e
  retornar 404 quando `job.userId == null || job.userId != userId`, ou separar
  jobs internos com token/rota nao app-facing.
- **O que falsifica:** evidencia de que jobs nulos sao exclusivamente internos,
  protegidos por segredo/nonce forte e nunca retornados em `poll_url` do app.

#### P2 — Telemetria de rebuild e enviada pelo app, rejeitada pela rota e documentada como nao provada

- **Consumidor app:** `app/lib/features/decks/providers/deck_provider.dart:603`-`:614`
  envia `_trackActivationEvent('deck_rebuild_created', ...)` apos criar draft
  de rebuild.
- **Service app:** `app/lib/core/services/activation_funnel_service.dart:17`-`:23`
  posta `event_name`, `deck_id`, `source` e `metadata` em
  `/users/me/activation-events`; `:24`-`:26` engole erro para nao quebrar fluxo.
- **Rota:** `server/routes/users/me/activation-events/index.dart:10`-`:18`
  permite `core_flow_started`, `format_selected`, `base_choice_generate`,
  `base_choice_import`, `deck_created`, `deck_optimized` e
  `onboarding_completed`, mas nao `deck_rebuild_created`; `:46`-`:48` retorna
  400 para evento fora da allow-list.
- **Contrato:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md:61` ainda classifica
  `POST /users/me/activation-events` como `internal`, com consumidor
  `onboarding/activation code not proven`.
- **Por que e incoerente:** existe consumidor real em `app/lib`, mas a rota
  rejeita um evento emitido por esse consumidor e o contrato ainda o trata como
  nao provado.
- **O que valida:** adicionar `deck_rebuild_created` a allow-list e atualizar o
  contrato/teste de telemetria, ou remover o envio do app se o evento nao deve
  existir.
- **O que falsifica:** decisao explicita de descartar rebuild telemetry, com
  teste garantindo que o app nao conte esse evento como sinal de funil.

#### P1 — Deck analysis e optimize ainda usam fontes semanticas diferentes para o mesmo deck app-facing

- **Consumidor app analysis:** `app/lib/features/decks/providers/deck_provider.dart:227`-`:263`
  chama `fetchDeckAnalysis`; `app/lib/features/decks/widgets/deck_analysis_tab.dart:99`
  dispara a busca e a UI usa `functional_tags` para explicar funcoes do deck.
- **Rotas analysis:** `server/routes/decks/[id]/analysis/index.dart:80`-`:99`
  agrega `card_function_tags` e `card_semantic_tags_v2` por carta antes de
  montar `functional_tags`; `server/routes/decks/[id]/ai-analysis/index.dart:74`-`:100`
  carrega semantic v2 e `:134`-`:135` inclui `functional_tags` e
  `semantic_tags_v2`.
- **Optimize support:** `server/lib/ai/optimize_request_support.dart:86`-`:137`
  carrega somente `$semanticV2Select AS semantic_tags_v2` no contexto de deck;
  nao ha coluna `functional_tags` nesse loader.
- **Optimize route legacy local:** `server/routes/ai/optimize/index.dart:3198`-`:3213`
  tem outro helper local para `semantic_tags_v2`, tambem sem `card_function_tags`.
- **Contrato:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md:164` lista
  `card_function_tags` entre as fontes principais de `/ai/optimize`, mas o
  contexto primario de optimize nao threada esses dados como analysis faz.
- **Por que e incoerente:** a aba de analise e o optimize sao fluxos do mesmo
  deck no app; analysis prioriza tags funcionais persistidas, enquanto optimize
  ainda depende de semantic v2/fallbacks no loader principal, podendo discordar
  sobre papeis como ramp/draw/removal/wipe/protection.
- **O que valida:** threadar `card_function_tags` no contexto de optimize e no
  adapter de roles, com teste comparando uma carta multi-role entre analysis,
  validator e optimize.
- **O que falsifica:** contrato/teste provando que optimize deve ignorar
  `card_function_tags` persistidas e que a divergencia com analysis e esperada.

### Resultado desta revalidacao

No checkout `1fbc07d8`, o auditor base nao achou imports quebrados no recorte
backend, e `server/lib/ai/commander_learned_deck_support.dart` existe no
checkout atual. O risco de coerencia continua concentrado em endpoints deck/AI
consumidos pelo app: ownership nao propagado no loader de optimize/archetypes,
jobs async nulos legiveis por polling app-facing, telemetry de rebuild emitida
mas rejeitada, e divergencia entre a fonte semantica usada pela aba de analise
e pelo optimize.

## Rodada focada: Duplicated or similar logic — revalidacao 2026-06-06 19:00 UTC

Escopo desta rodada: somente logica duplicada ou similar com risco de drift.
Nao foi feita auditoria ampla de classes sem uso, funcoes sem chamada,
imports/ciclos, tabelas PostgreSQL sem uso ou coerencia entre camadas fora
deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `2f283904`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor detecta duplicidade por nomes de funcoes
publicas e texto, sem comparar corpo, sem entender funcoes privadas e sem
classificar se duas copias divergiram por contrato intencional. A execucao
tambem reescreve `STRUCTURE_AUDIT.md` quando o arquivo nao tem o marcador de
merge esperado; essa mutacao automatica foi descartada para preservar o
historico manual, e somente os numeros acima mais os achados focados abaixo
foram incorporados.

### Metodo manual focado

- Revalidacao por `rg` dos candidatos historicos de duplicacao em
  `server/lib`, `server/routes` e `app/lib`.
- Leitura das faixas exatas dos helpers duplicados para separar wrappers finos,
  duplicidade aceitavel e drift real.
- Checagem de controles positivos: `server/routes/ai/optimize/index.dart`
  ainda contem wrappers como `resolveOptimizeArchetype` em `:56`-`:61`, mas
  delega para `optimize_support`, portanto nao foi contado como corpo duplicado
  independente.

### Achados revalidados

#### P1 — `resolveOptimizeArchetype` segue duplicado com contratos diferentes

- **Funcoes:** `resolveOptimizeArchetype` em
  `server/lib/ai/deck_state_analysis.dart:573`-`:585` e
  `server/lib/ai/optimize_runtime_support.dart:3369`-`:3389`.
- **Divergencia concreta:** a versao de `deck_state_analysis` aceita
  `requestedArchetype` nullable, trata `general` e `tempo` como genericos e
  retorna `detected` quando `requested` esta vazio. A versao de
  `optimize_runtime_support` exige string, trata `unknown` como detected vazio,
  considera `goodstuff` generico e so promove detected especifico para
  `aggro/control/combo/stax/tribal`.
- **Por que parece duplicacao de risco:** ambas respondem qual arquetipo efetivo
  deve guiar optimize/rebuild, mas `optimize_request_support.dart:289`-`:294`
  usa a versao de optimize enquanto `rebuild_guided_service.dart:171` usa a
  versao de deck state.
- **O que valida:** unificar em helper unico com testes para vazio/null,
  `unknown`, `general`, `tempo`, `goodstuff` e detected especifico.
- **O que falsifica:** contrato documentado e coberto mostrando que optimize e
  rebuild devem divergir nesses casos.

#### P1 — Heuristicas contextuais de roles existem em dois classificadores vivos

- **Funcoes duplicadas:** `_looksLikeWincon`, `_looksLikeComboPiece`,
  `_looksLikeEngine`, `_looksLikePayoff` e `_looksLikeEnabler` em
  `server/lib/ai/functional_card_tags.dart:859`-`:906` e
  `server/lib/ai/optimization_functional_roles.dart:370`-`:398`.
- **Divergencia concreta:** `functional_card_tags.dart` mistura `oracle_text`
  com nome normalizado (`blood artist`, `isochron scepter`,
  `dramatic reversal`, `thassa's oracle`, `greaves`, `boots`) e tags multiplas;
  `optimization_functional_roles.dart` usa outro conjunto de padroes de texto e
  retorna role escalar para optimize.
- **Por que parece duplicacao de risco:** deck analysis e optimize podem
  classificar a mesma carta de forma diferente, especialmente em cartas
  multi-role ou dependentes de nome conhecido.
- **O que valida:** adapter unico que aceite nome, texto, tipo,
  `functional_tags` persistidas e `semantic_tags_v2`, retornando roles
  multiplos e `primary_role`.
- **O que falsifica:** teste de contrato provando que as duas familias devem
  responder perguntas diferentes e que essa diferenca e esperada pelo produto.

#### P1/P2 — Terrenos basicos e snow basics continuam com quatro variantes

- **Helpers:** `server/lib/ai/optimize_runtime_support.dart:4184`-`:4197`,
  `server/lib/generated_deck_validation_service.dart:752`-`:763`,
  `server/lib/meta/meta_deck_reference_support.dart:890`-`:903` e
  `server/routes/ai/commander-reference/index.dart:621`-`:628`.
- **Divergencia concreta:** optimize usa nomes com hifen (`snow-covered plains`);
  generated deck validation aceita prefixo `startsWith('snow-covered ...')`;
  meta reference usa nomes normalizados com espaco (`snow covered plains`);
  commander-reference reconhece apenas basics nao snow.
- **Por que parece duplicacao de risco:** validacao, optimize, meta reference e
  Commander Reference podem divergir sobre a mesma carta basica/snow quando o
  normalizador muda ou quando snow basics entram no corpus.
- **O que valida:** helper compartilhado com normalizacao unica para hifen/espaco
  e teste cobrindo `Wastes` e os cinco snow basics.
- **O que falsifica:** evidencia de que Commander Reference deve excluir snow
  basics por regra de dominio, com teste dedicado.

#### P2 — Trust social e marketplace repetem SQL/serializer de reputacao

- **Copias em trades:** `_trustStatsSql`, `_responseTimeSql`,
  `_shippingTimeSql` e `_buildTrustInsight` em
  `server/routes/trades/index.dart:557`-`:635` e
  `server/routes/trades/[id]/index.dart:260`-`:338`.
- **Copia em marketplace:** LATERALs inline equivalentes em
  `server/routes/community/marketplace/index.dart:131`-`:166` e serializer
  `_buildTrustInsight` em `:316`-`:348`.
- **Por que parece duplicacao de risco:** listagem de trades, detalhe de trade e
  marketplace expõem o mesmo shape `trust`, mas qualquer mudanca de sinal,
  periodo, thresholds ou campos precisa ser copiada em tres lugares.
- **O que valida:** helper SQL/serializer compartilhado com testes para os tres
  consumidores manterem o mesmo shape.
- **O que falsifica:** contrato app-facing demonstrando que marketplace deve
  calcular trust de forma diferente de trades.

#### P2 — Request id e log de payload invalido repetem o mesmo padrao social

- **Helpers repetidos:** `_requestId` em
  `server/routes/trades/index.dart:330`-`:336`,
  `server/routes/trades/[id]/status.dart:260`-`:266`,
  `server/routes/trades/[id]/respond.dart:154`-`:160`,
  `server/routes/trades/[id]/messages.dart:228`-`:234`,
  `server/routes/conversations/[id]/messages.dart:247`-`:252` e
  `server/routes/users/[id]/follow/index.dart:97`-`:103`.
- **Log duplicado:** `_logInvalidPayload` repete a leitura defensiva de `userId`
  e o formato `[social_write] invalid_payload` nos mesmos handlers de trades e
  conversations.
- **Controle positivo:** `server/lib/request_trace.dart` ja expoe
  `getRequestTrace` e `tryGetRequestId`, mas a rodada de funcoes sem chamada
  confirmou que esses wrappers seguem sem consumidor runtime.
- **O que valida:** adotar helper comum para request id e invalid-payload log,
  mantendo endpoint/id como parametros.
- **O que falsifica:** decisao de manter logs completamente locais por rota,
  coberta por testes/snapshots de observabilidade.

#### P2 — `condition` de carta tem allow-list repetida e comportamento divergente

- **Deck mutations:** `server/routes/decks/[id]/cards/index.dart:398`-`:404`,
  `server/routes/decks/[id]/cards/set/index.dart:245`-`:249` e
  `server/routes/decks/[id]/index.dart:520`-`:524` normalizam valores invalidos
  para `NM`.
- **Binder mutations:** `server/routes/binder/index.dart:258`-`:280` e
  `server/routes/binder/[id]/index.dart:339`-`:347` rejeitam valores invalidos
  com 400.
- **Marketplace filter:** `server/routes/community/marketplace/index.dart:39`-`:43`
  aplica filtro apenas se a condicao estiver na allow-list, ignorando invalido.
- **Por que parece duplicacao de risco:** a mesma taxonomia `NM/LP/MP/HP/DMG`
  aparece em varios dominios, mas o contrato de erro/default muda por endpoint.
- **O que valida:** policy/helper comum que separe `parse`, `defaultToNm`,
  `rejectInvalid` e `ignoreInvalidFilter`.
- **O que falsifica:** contrato atualizado provando que cada comportamento
  divergente e intencional e testado.

#### P2/P3 — Helpers de tipo principal e CMC continuam duplicados em rotas

- **Copias:** `getMainType` e `calculateCmc` em
  `server/routes/decks/[id]/index.dart:405`-`:435` e
  `server/routes/community/decks/[id].dart:91`-`:117`; variante
  `_calculateCmc` em `server/routes/decks/[id]/simulate/index.dart:171`-`:186`.
- **Divergencia concreta:** as duas primeiras copias sao praticamente iguais; a
  variante de simulate assume `String manaCost` nao nullable e compara `symbol`
  com `X` sem `toUpperCase()`.
- **O que valida:** helper compartilhado de mana/type com teste de simbolos
  numericos, `X`, hibridos e custo vazio/null.
- **O que falsifica:** migrar estes calculos para coluna persistida/servico
  externo e remover os helpers locais.

### Resultado desta revalidacao

Os achados historicos de duplicacao/similaridade continuam abertos no checkout
`2f283904`, sem novo cluster de maior prioridade confirmado. O risco pratico
segue concentrado em duplicacoes que podem alterar decisao de IA/deck
(`resolveOptimizeArchetype`, roles funcionais, basics/snow basics) e em
duplicacoes app-facing que podem gerar resposta inconsistente por endpoint
(`trust`, request/log, `condition`, CMC/tipo).

## Rodada focada: PostgreSQL tables not used — revalidacao 2026-06-06 15:00 UTC

Escopo desta rodada: somente tabelas PostgreSQL persistidas sem consumidor
claro, write-only ou parcialmente consumidas. Nao foi feita auditoria ampla de
classes, funcoes sem chamada, imports/ciclos, duplicacao geral ou coerencia
entre camadas fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `bd5add18`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor e textual e lista tabelas referenciadas,
mas nao diferencia schema/migracao, escrita, leitura operacional, contador
diagnostico ou consumidor app-facing. A execucao tambem reescreve
`STRUCTURE_AUDIT.md` com inventario gerado; essa mutacao automatica foi
descartada para preservar o historico manual, e somente os numeros acima mais
os achados focados abaixo foram incorporados.

### Metodo manual focado

- `rg -n "\b(deck_matchups|deck_weakness_reports|ml_prompt_feedback|commander_reference_decks|commander_reference_deck_cards|commander_reference_deck_analysis)\b" server/database_setup.sql server/bin server/lib server/routes app/lib --glob '*.dart' --glob '*.sql'`.
- `rg -n "\b(FROM|JOIN)\s+(deck_matchups|deck_weakness_reports|commander_reference_decks|commander_reference_deck_cards)\b" server/routes server/lib server/bin app/lib --glob '*.dart'`.
- `rg -n "\b(SELECT|FROM|JOIN|INSERT INTO|UPDATE|DELETE FROM)\s+(deck_matchups|deck_weakness_reports|ml_prompt_feedback|commander_reference_decks|commander_reference_deck_cards|commander_reference_deck_analysis)\b" server/routes server/lib server/bin app/lib --glob '*.dart'`.
- `rg -n "recordFeedback\(" server/lib server/routes server/bin server/test app/lib --glob '*.dart'`.
- Leitura pontual dos arquivos que definem, escrevem ou leem as tabelas
  candidatas para separar resposta efemera de historico consumido.

### Achados revalidados

#### P2 — `deck_matchups` continua write-only no produto atual

- **Tabela:** `deck_matchups`, definida em `server/database_setup.sql:162`.
- **Escrita confirmada:** `server/routes/ai/simulate-matchup/index.dart:360`
  faz `INSERT INTO deck_matchups (...) ON CONFLICT (...) DO UPDATE`.
- **Ausencia de leitura confirmada:** a busca por `FROM/JOIN deck_matchups` em
  `server/routes`, `server/lib`, `server/bin` e `app/lib` nao retornou
  consumidor runtime.
- **Por que parece nao usada:** o endpoint experimental calcula e retorna a
  simulacao no proprio request; `deck_matchups.win_rate` e `notes` nao alimentam
  cache, historico, dashboard, recomendador ou app confirmado.
- **O que valida:** criar consumidor real de `deck_matchups` com contrato/teste
  ou documentar a tabela como log bruto com retencao.
- **O que falsifica:** `rg "\b(FROM|JOIN)\s+deck_matchups\b" server app`
  encontrar leitura real fora de migracao/verificacao de schema.

#### P2 — `deck_weakness_reports` persiste fraquezas, mas nao tem workflow de leitura/addressing

- **Tabela:** `deck_weakness_reports`, definida em
  `server/database_setup.sql:363`; o campo `addressed` fica em `:371`.
- **Escrita confirmada:** `server/routes/ai/weakness-analysis/index.dart:374`
  faz `INSERT INTO deck_weakness_reports`.
- **Ausencia de leitura/update confirmada:** a busca por `FROM/JOIN
  deck_weakness_reports` em `server/routes`, `server/lib`, `server/bin` e
  `app/lib` nao retornou consumidor; `addressed` nao tem fluxo runtime de
  update confirmado.
- **Por que parece nao usada:** a rota experimental devolve a analise no
  response atual, mas o historico salvo nao e recuperado nem marcado como
  tratado por nenhum fluxo confirmado.
- **O que valida:** criar leitura por deck/usuario, update de `addressed` e
  teste de contrato, ou remover/documentar a persistencia como log bruto.
- **O que falsifica:** leitura runtime da tabela ou update real de `addressed`
  fora de migradores/verificadores de schema.

#### P2 — `ml_prompt_feedback` ainda nao coleta feedback real

- **Tabela:** `ml_prompt_feedback`, criada em
  `server/bin/migrate_ml_knowledge.dart:159`.
- **Helper de escrita:** `MLKnowledgeService.recordFeedback` em
  `server/lib/ml_knowledge_service.dart:251` insere na tabela em `:264`.
- **Ausencia de chamador confirmada:** `rg "recordFeedback\("` em `server/lib`,
  `server/routes`, `server/bin`, `server/test` e `app/lib` encontrou somente a
  propria definicao.
- **Leitura existente:** `/ai/ml-status` conta linhas em
  `server/routes/ai/ml-status/index.dart:98`, mas isso e contador operacional,
  nao consumo de feedback para aprendizado ou produto.
- **Por que parece nao usada:** ha schema e helper, mas nenhum fluxo app/job/rota
  registra feedback do usuario.
- **O que valida:** rota/app/job chamar `recordFeedback` e algum consumidor usar
  o feedback, com teste de contrato.
- **O que falsifica:** chamada runtime nova a `recordFeedback(...)` fora do
  service.

#### P3 — `commander_reference_decks` e `commander_reference_deck_cards` seguem raw corpus sem leitura runtime direta

- **Tabelas:** `commander_reference_decks` e
  `commander_reference_deck_cards`, definidas em
  `server/lib/ai/commander_reference_deck_corpus_support.dart:1177` e `:1200`.
- **Escrita confirmada:** o apply do corpus faz insert/upsert em
  `commander_reference_decks` em `:1245`, delete de cards em `:1329` e insert
  em `commander_reference_deck_cards` em `:1345`.
- **Controle positivo:** o produto le o agregado
  `commander_reference_deck_analysis` em
  `server/lib/ai/commander_reference_deck_corpus_support.dart:389`, e esse
  agregado e persistido em `:1394`.
- **Ausencia de leitura direta confirmada:** a busca por `FROM/JOIN` nas duas
  tabelas brutas nao retornou consumidor; apareceu apenas o delete de refresh
  de `commander_reference_deck_cards`.
- **Por que parece parcialmente usada:** as tabelas brutas guardam lineage/audit
  do corpus, mas o runtime confirmado usa somente o resumo agregado.
- **O que valida:** documentar retencao/reprocessamento das tabelas brutas,
  adicionar job que releia o raw corpus, ou persistir apenas o agregado.
- **O que falsifica:** `SELECT`/`JOIN` runtime real nas tabelas brutas fora do
  fluxo de apply/refresh.

### Controles positivos e negativos

- `commander_reference_deck_analysis` foi descartada como candidata porque tem
  leitura runtime confirmada em
  `server/lib/ai/commander_reference_deck_corpus_support.dart:389`.
- A varredura focada nao encontrou novo candidato alem dos itens revalidados.
- `deck_learning_events` e `commander_card_usage` continuam aparecendo somente
  em docs historicos neste checkout; nao aparecem em `server/database_setup.sql`
  nem em codigo Dart runtime.
- `schema_migrations` segue fora do achado por ser tabela interna de migrador,
  nao tabela de produto.

### Resultado desta revalidacao

Os achados historicos de tabelas PostgreSQL sem consumidor claro permanecem
abertos no checkout `bd5add18`, sem novo candidato confirmado. O risco pratico
segue concentrado em persistencias que parecem prometer historico/feedback, mas
nao alimentam nenhum fluxo confirmado: `deck_matchups`,
`deck_weakness_reports`, `ml_prompt_feedback` e as tabelas raw do Commander
Reference Corpus.

## Rodada focada: Broken imports and circular dependencies - revalidacao 2026-06-06 11:00 UTC

Escopo desta rodada: somente imports quebrados e dependencias circulares. Nao foi feita auditoria ampla de classes, funcoes sem chamada, tabelas PostgreSQL, duplicacao geral ou coerencia entre camadas fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio: `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `6364db29`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor textual cobre apenas `server/lib` e `server/routes`, portanto nao enxerga imports quebrados em `app/lib` nem em `server/bin`, e tambem nao monta grafo/SCC para ciclos. A execucao reescreve `STRUCTURE_AUDIT.md` com inventario gerado; essa mutacao automatica foi descartada para preservar o historico manual, e somente os numeros acima mais os achados focados abaixo foram incorporados.

### Metodo manual focado

- Resolucao local de imports Dart em 424 arquivos de `app/lib`, `server/lib`, `server/routes` e `server/bin`.
- Imports `dart:` e pacotes externos foram ignorados; `package:manaloom/...` foi resolvido para `app/lib`, `package:server/...` para `server/lib` e o alias historico `package:ai/...` para `server/lib/ai`.
- Imports relativos foram resolvidos a partir do diretorio do arquivo Dart origem.
- O mesmo grafo local foi usado para SCCs; foram reportados apenas componentes fortemente conexos com mais de um arquivo.
- Validador complementar: `cd server && dart analyze routes/ai/commander-learning/index.dart bin/local_test_server.dart` confirmou os dois imports quebrados de backend. `cd app && flutter analyze --no-pub --no-fatal-infos lib/features/decks/widgets/deck_analysis_tab.dart lib/features/home/life_counter_screen.dart` nao foi conclusivo para o app porque `package:flutter`, `package:provider` e `package:fl_chart` nao resolvem neste checkout, mas a saida inclui os dois `uri_does_not_exist` locais abaixo.

### Achados revalidados

#### P1/P2 - Quatro imports locais quebrados permanecem no checkout atual

- **Backend app-facing Commander Learning:** `server/routes/ai/commander-learning/index.dart:4` importa `../../../lib/ai/commander_learned_deck_support.dart`, resolvendo para `server/lib/ai/commander_learned_deck_support.dart`, arquivo ausente neste checkout. `dart analyze` focado confirma `uri_does_not_exist` e erros em cascata para `CommanderLearnedDeckInput` em `:61`, `:105`, `:141`, `:169`, `:248`, `:265`, `:283` e `:305`. Validacao: restaurar/criar o support esperado ou remover/desativar a rota ate o contrato existir; falsificacao: o arquivo passar a existir e o analyzer focado deixar de reportar `uri_does_not_exist`.
- **Entry point local de teste:** `server/bin/local_test_server.dart:3` importa `../.dart_frog/server.dart`, resolvendo para `server/.dart_frog/server.dart`, artefato ausente em clone limpo desta branch. `dart analyze` focado confirma `uri_does_not_exist`. Validacao: gerar o artefato antes do analyze/uso, trocar para entrypoint suportado pelo Dart Frog, ou documentar o binario como dependente de build local; falsificacao: `server/.dart_frog/server.dart` existir no fluxo suportado ou o import deixar de ser estatico.
- **App deck analysis:** `app/lib/features/decks/widgets/deck_analysis_tab.dart:5` importa `../../../../core/utils/mana_helper.dart`, resolvendo para `app/core/utils/mana_helper.dart`; o arquivo real existe em `app/lib/core/utils/mana_helper.dart`. A importacao vizinha `../../../core/theme/app_theme.dart` em `:4` mostra o nivel relativo esperado para sair de `features/decks/widgets` ate `app/lib/core`. Validacao: trocar para `../../../core/utils/mana_helper.dart` ou `package:manaloom/core/utils/mana_helper.dart`; falsificacao: criar intencionalmente `app/core/utils/mana_helper.dart`, o que seria incoerente com a estrutura atual.
- **App life counter nativo:** `app/lib/features/home/life_counter_screen.dart:7` importa `../../../core/theme/app_theme.dart`, resolvendo para `app/core/theme/app_theme.dart`; o arquivo real existe em `app/lib/core/theme/app_theme.dart`. A partir de `features/home`, o caminho relativo correto teria dois `..` (`../../core/theme/app_theme.dart`) ou package import. Validacao: corrigir o caminho ou usar `package:manaloom/core/theme/app_theme.dart`; falsificacao: criar intencionalmente `app/core/theme/app_theme.dart`, tambem incoerente com a estrutura atual.

A varredura ampliada nao encontrou outros imports locais quebrados nos 424 arquivos do recorte.

#### P2 - Ciclo Flutter entre perfil publico e detalhe de deck publico segue presente

- **Componente SCC:** `app/lib/features/community/screens/community_deck_detail_screen.dart` e `app/lib/features/social/screens/user_profile_screen.dart`.
- **Aresta 1:** `community_deck_detail_screen.dart:8` importa `../../social/screens/user_profile_screen.dart` e instancia `UserProfileScreen` em `:213` para navegar do deck publico ao dono/perfil.
- **Aresta 2:** `user_profile_screen.dart:7` importa `../../community/screens/community_deck_detail_screen.dart` e instancia `CommunityDeckDetailScreen` em `:469` para navegar do perfil ao deck publico.
- **Por que e ciclo real:** o SCC do grafo local contem exatamente esses dois arquivos e nao depende de pacote externo nem de teste. Nao foi encontrado ciclo local backend.
- **Impacto:** ciclo pequeno e funcionalmente compreensivel, mas aumenta acoplamento entre features `community` e `social`; qualquer inicializacao top-level futura nesses arquivos pode transformar uma navegacao legitima em problema de carregamento/testabilidade.
- **O que valida:** extrair a navegacao para rotas nomeadas, callback/factory comum ou shell/router compartilhado, deixando `community` e `social` dependerem de uma camada comum em vez de uma da outra.
- **O que falsifica:** SCC local zerado apos remover pelo menos uma das importacoes diretas, mantendo as navegacoes cobertas por teste/widget smoke.

### Resultado desta revalidacao

Os achados historicos de imports/ciclo foram revalidados no checkout `6364db29` sem novos candidatos no recorte. O risco mais alto continua sendo `server/routes/ai/commander-learning/index.dart`, porque o import ausente quebra a rota e o tipo `CommanderLearnedDeckInput` em cascata. O ciclo app e P2 por acoplamento, nao por falha de compilacao imediata.


## Rodada focada: Functions not called - revalidacao 2026-06-06 07:00 UTC

Escopo desta rodada: somente funcoes/metodos sem chamador confirmado. Nao foi
feita auditoria ampla de classes, imports/ciclos, tabelas PostgreSQL,
duplicacao geral ou coerencia entre camadas fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `bb1870de`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor textual cobre `server/lib` e
`server/routes`, mas nao constroi grafo de chamadas. A docstring do script diz
explicitamente que achados de "nao usado" exigem validacao manual com grep. A
execucao tambem reescreveu `STRUCTURE_AUDIT.md` em formato de inventario
gerado; essa mutacao automatica foi descartada para preservar o historico
manual, e somente os numeros acima mais os achados focados abaixo foram
incorporados.

### Metodo manual focado

- Revalidacao por `rg` dos candidatos historicos em `server/lib`,
  `server/routes`, `server/bin`, `server/test`, `app/lib`, `app/test` e
  `app/integration_test`.
- Separacao entre uso runtime, uso por teste, docs e definicao propria.
- Varredura auxiliar de baixa ocorrencia em `server/lib`, `server/routes`,
  `server/bin` e `app/lib`, seguida de validacao manual para descartar
  definicoes chamadas por rotas, services, bins, observers ou falsos positivos
  vindos de SQL/comentarios.

### Achados revalidados

#### P1 — `sync_cards_utils.dart` segue test-only enquanto o CLI real duplica a logica

- **Funcoes:** `extractCardRow`, `getNewSetCodesSinceFromData`,
  `parseSinceDays`, `extractSetCardRow`, `extractOracleIds` e
  `extractLegalities` em `server/lib/sync_cards_utils.dart:16`, `:82`,
  `:102`, `:116`, `:161` e `:172`.
- **Evidencia de uso restrito a teste:** busca por chamadas em Dart encontrou
  `server/test/sync_cards_test.dart:3` importando
  `../lib/sync_cards_utils.dart` e exercitando os helpers; nao encontrou import
  de `sync_cards_utils.dart` em `server/bin`, `server/lib` runtime ou
  `server/routes`.
- **Evidencia de duplicacao no caminho vivo:** `server/bin/sync_cards.dart:9`-`:10`
  importa `database.dart` e `mtg_data_integrity_support.dart`, mas nao
  `sync_cards_utils.dart`. O CLI chama `_extractCardRow` em `:554`, define
  `_extractCardRow` em `:680`, e mantem coleta inline de oracle IDs/legalidades
  em `:806`-`:838`; tambem preserva helpers privados/inline equivalentes para
  parse de `--since-days`, selecao de sets e montagem incremental de rows.
- **Por que parece nao chamada:** o arquivo publico foi criado para tornar o
  parsing testavel, mas o binario operacional nao usa esses helpers.
- **O que valida:** trocar o CLI real para importar `sync_cards_utils.dart` e
  remover as copias privadas/inline, mantendo `server/test/sync_cards_test.dart`
  como cobertura do mesmo caminho usado em producao.
- **O que falsifica:** chamada/import runtime novo a
  `server/lib/sync_cards_utils.dart` por `server/bin/sync_cards.dart`, ou
  decisao documentada de transformar o arquivo em fixture de teste.

#### P2 — Wrappers de `request_trace.dart` seguem sem consumidor externo

- **Funcoes:** `getRequestTrace` e `tryGetRequestId` em
  `server/lib/request_trace.dart:48` e `:51`.
- **Evidencia de ausencia:** busca por `getRequestTrace(` encontrou somente a
  propria definicao e a chamada interna dentro de `tryGetRequestId`; busca por
  `tryGetRequestId(` encontrou somente a propria definicao.
- **Controle positivo:** `RequestTrace` esta vivo: `_middleware.dart` injeta o
  objeto e headers `x-request-id`, `auth_middleware.dart:57` grava `userId`,
  `server/lib/observability.dart:225` le `context.read<RequestTrace>()`, e
  rotas como `server/routes/trades/index.dart:332`,
  `server/routes/conversations/[id]/messages.dart:249` e
  `server/routes/users/[id]/follow/index.dart:99` leem
  `context.read<RequestTrace>().requestId` diretamente.
- **Por que parece nao chamada:** o modelo/contexto e usado, mas os wrappers
  publicos nao foram adotados pelas rotas.
- **O que valida:** substituir os reads diretos por `getRequestTrace`/
  `tryGetRequestId` onde o fallback for desejado, ou remover os wrappers.
- **O que falsifica:** chamada runtime nova a `getRequestTrace(context)` ou
  `tryGetRequestId(context)` fora de `request_trace.dart`.

#### P2 — Helpers de Commander Reference/MTGTop8/Candidate Quality continuam test-only ou sem chamada

- **Funcoes sem chamada runtime confirmada:**
  `normalizedCommanderReferenceCandidate` em
  `server/lib/ai/commander_reference_profile_support.dart:49`;
  `buildLoreholdReferenceCardStatsFromProfile` em
  `server/lib/ai/commander_reference_card_stats_support.dart:257`;
  `extractMtgTop8FormatCodeFromSourceUrl` em
  `server/lib/meta/mtgtop8_meta_support.dart:139`;
  `buildCandidateQualitySamplePoolSql` em
  `server/lib/ai/candidate_quality_data_support.dart:631`; e
  `summarizeAggressiveOptimizeUtilitySamples` em
  `server/lib/ai/optimize_runtime_support.dart:3326`.
- **Evidencia de ausencia:** busca por chamada em `server/lib`, `server/routes`,
  `server/bin`, `server/test`, `app/lib` e `app/test` encontrou
  `normalizedCommanderReferenceCandidate` somente na definicao. Os demais
  aparecem na definicao e em testes dedicados:
  `server/test/commander_reference_card_stats_support_test.dart:13`,
  `server/test/mtgtop8_meta_support_test.dart:147`,
  `server/test/candidate_quality_data_support_test.dart:123` e
  `server/test/optimize_runtime_support_test.dart:169`.
- **Controles positivos:** o runtime usa funcoes vizinhas/genericas:
  `buildCommanderReferenceCardStatsFromProfile` e chamado em
  `commander_reference_card_stats_support.dart:368`,
  `extractMtgTop8EventIdFromSourceUrl` e usado por
  `server/bin/repair_mtgtop8_meta_history.dart:59`, e
  `isLoreholdCommanderReferenceCandidate` e usado por rotas/support de
  Commander Reference.
- **Por que parece nao chamada:** sao APIs publicas exercitadas como unidade
  isolada, mas sem ligacao comprovada ao pipeline runtime atual.
- **O que valida:** conectar cada helper ao respectivo runner/rota/service vivo
  ou rebaixar para helper privado/test fixture quando for somente prova de
  contrato.
- **O que falsifica:** chamada runtime existente fora dos testes acima.

#### P2 — `MLKnowledgeService.recordFeedback` ainda nao alimenta `ml_prompt_feedback`

- **Funcao:** `recordFeedback` em `server/lib/ml_knowledge_service.dart:251`;
  o insert em `ml_prompt_feedback` esta em `:264`.
- **Evidencia de ausencia:** busca por `recordFeedback(` em runtime encontrou
  somente a propria definicao.
- **Controle positivo:** `MLKnowledgeService` e instanciado em
  `server/lib/ai/otimizacao.dart:33` e usado para contexto/recomendacao por
  outros metodos, mas esse caminho nao chama `recordFeedback`.
- **Por que parece nao chamada:** a tabela tem caminho de escrita teorico, mas
  nenhuma rota/job/app aciona feedback de otimizacao.
- **O que valida:** rota/app/job chamar `recordFeedback` com teste de contrato e
  algum consumidor usar `ml_prompt_feedback` para avaliacao ou ajuste.
- **O que falsifica:** chamada runtime a `recordFeedback(...)` fora do service.

#### P3 — API manual de metricas do `PerformanceService` segue sem uso app-facing

- **Funcoes/metodos sem chamador externo confirmado:** `startTrace` em
  `app/lib/core/services/performance_service.dart:110`, `stopTrace` em `:130`,
  `addMetric` em `:200`, `addAttribute` em `:210`, `getLocalStats` em `:220`
  e `printLocalStats` em `:248`.
- **Evidencia de ausencia:** busca por `.startTrace(`, `.stopTrace(`,
  `.addMetric(`, `.addAttribute(`, `.getLocalStats(` e `.printLocalStats(` em
  `app/lib`, `app/test` e `app/integration_test` nao encontrou chamada externa
  para esses metodos; `getLocalStats` e chamado apenas internamente por
  `printLocalStats`.
- **Controles positivos:** a parte automatica esta viva:
  `PerformanceService.instance.init()` roda em `app/lib/main.dart:121`,
  `PerformanceNavigatorObserver` aciona `startScreenTrace`/`stopScreenTrace` em
  `performance_service.dart:295`, `:307`, `:334` e `:339`, e `traceAsync` e
  exercitado pelo smoke
  `app/integration_test/release_observability_smoke_test.dart:51`.
- **Por que parece nao chamada:** a instrumentacao automatica existe, mas a API
  manual/custom/debug nao foi conectada a fluxos app-facing.
- **O que valida:** usar esses metodos em operacoes app reais ou documentar a
  API como reservada/debug-only com cobertura explicita.
- **O que falsifica:** chamada externa nova a qualquer metodo listado.

#### P3 — Conveniencias EDHREC/cache seguem sem chamador

- **Funcoes:** `EdhrecService.getTopByCategory`,
  `EdhrecService.calculateFitScore`, `EdhrecService.cleanupCache` e
  `EdhrecCommanderData.isHighSynergy` em
  `server/lib/ai/edhrec_service.dart:333`, `:355`, `:363` e `:399`;
  `EndpointCache.clearExpired` em `server/lib/endpoint_cache.dart:32`.
- **Evidencia de ausencia:** busca por chamadas em `server/lib`,
  `server/routes`, `server/bin`, `server/test`, `app/lib` e `app/test`
  encontrou apenas as definicoes para esses cinco simbolos.
- **Controles positivos:** EDHREC/cache nao estao mortos inteiros:
  `getHighSynergyCards` e chamado por `server/lib/ai/otimizacao.dart:112`,
  `:120`, `:313` e `:321`; `EndpointCache.instance.get/set` sao usados em
  `server/routes/cards/index.dart`, `server/routes/sets/index.dart`,
  `server/routes/ai/archetypes/index.dart` e
  `server/lib/ai_generate_performance_support.dart`.
- **Por que parece nao chamada:** sao conveniencias publicas residuais ou hooks
  de manutencao de cache sem scheduler/rota chamadora.
- **O que valida:** conectar limpeza proativa de cache e uso de fit/category em
  rota/service vivo, ou remover/rebaixar as conveniencias.
- **O que falsifica:** chamada runtime a qualquer simbolo listado.

### Resultado desta revalidacao

Nao surgiu novo P1 com evidencia mais forte que os itens ja conhecidos. O risco
principal desta rotacao continua sendo `sync_cards_utils.dart`: ha um helper
testado que parece prometer compartilhamento, mas o CLI operacional ainda roda
copias privadas. Os demais achados permanecem P2/P3 porque podem representar API
reservada, diagnostico ou contrato experimental, mas hoje nao tem chamador
runtime confirmado.

## Rodada focada: Semantica de cartas e hardcoded names - revalidacao 2026-06-06 05:30 UTC

Escopo desta rodada: somente semantica de cartas em codigo runtime de produto,
com prioridade para `server/lib`, `server/routes` e `app/lib`. Testes, docs,
prompts, comentarios, exemplos de UI/import e corpus foram lidos somente para
separar fixtures/exemplos de logica de produto.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `3a83ae79`.

### Metodo manual focado

- `rg` em `server/lib`, `server/routes` e `app/lib` para nomes especificos:
  `Sol Ring`, `Command Tower`, `Thassa`, `Isochron`, `Dramatic Reversal`,
  `Blood Artist`, `Boros Charm`, `Arcane Signet`, `Swords to Plowshares`,
  `Path to Exile`, `Cyclonic Rift`.
- Busca adicional por `normalizedName`, `name ==`, `name.contains`,
  `preferredNames`, `premium`, `stapleNames`, `functional_tags` e
  `semantic_tags_v2`.
- Leitura pontual dos fluxos `inferFunctionalCardTags`,
  `inferSemanticCardAnalysisV2`, `summarizeFunctionalTagsForDeck`,
  `classifyOptimizationFunctionalRole`, `OptimizationValidator`,
  `optimization_quality_gate`, `candidate_quality_data_support`,
  `loadOptimizeDeckContext`, `/ai/optimize`, `/decks/:id/analysis`,
  `/decks/:id/recommendations` e `/ai/weakness-analysis`.

### Classificacao de hardcoded card names

#### Allowed - exemplos, comentarios, UI search/defaults e aliases localizados

- `server/routes/import/to-deck/index.dart:102`,
  `server/routes/import/index.dart:182`,
  `app/lib/features/decks/widgets/deck_import_list_dialog.dart:154`,
  `app/lib/features/decks/screens/deck_import_screen.dart:385`-`:387` e
  `:592`, `app/lib/features/decks/providers/deck_provider.dart:1027` usam
  `Sol Ring`/`Arcane Signet`/`Command Tower` como exemplo de formato de lista ou
  texto inicial de importacao. Nao ha decisao de utilidade nesses pontos.
- `server/routes/cards/resolve/batch/index.dart:15`-`:21`,
  `app/lib/features/scanner/services/card_recognition_service.dart:122` e
  `server/lib/card_validation_service.dart:242` usam nomes como comentario de
  contrato/parser.
- `server/lib/import_card_lookup_service.dart:26` mapeia o alias localizado
  `espadas em arados` para `Swords to Plowshares`; classificacao allowed como
  dado de resolucao de nome/localizacao, nao regra de score.
- `app/lib/features/home/life_counter_screen.dart:2200`-`:2203` e
  `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:40`-`:43`
  usam sugestoes de busca visual no life counter. Classificacao allowed como
  UI example/search seed; nao altera optimize, recomendacao ou validacao.

#### Allowed with caution - seed/corpus declarado

- `server/lib/ai/commander_reference_generate_fallback_support.dart:183`-`:245`
  contem seed deterministica Lorehold por nomes fixos (`Sol Ring`,
  `Arcane Signet`, `Swords to Plowshares`, `Path to Exile`, `Boros Charm`).
  Classificacao allowed-with-caution enquanto permanecer seed/profile
  versionado de Commander Reference. Vira risco se for tratado como policy
  global de utilidade.
- `server/lib/ai/commander_reference_profile_support.dart:154`-`:155` contem
  pacote/fixture de profile com `Swords to Plowshares` e `Path to Exile`;
  mesma classificacao: corpus/profile, nao regra global.

#### Risk - decisoes runtime por nome especifico ou lista inline

- `server/lib/ai/functional_card_tags.dart:220`-`:226` classifica ramp por
  `signet`, `talisman`, `sol ring` e `arcane signet`; `:714`-`:717`,
  `:754`-`:780` e `:859`-`:899` adicionam tags por nomes como
  `Teferi's Protection`, `Heroic Intervention`, `Swiftfoot Boots`,
  `Lightning Greaves`, `Blood Artist`, `Thassa's Oracle`,
  `Isochron Scepter` e `Dramatic Reversal`. Isso e runtime semantico e deve
  migrar para `oracle_text`/`type_line`/dados persistidos ou policy versionada.
- `server/lib/ai/candidate_quality_data_support.dart:375`-`:379`,
  `:421`-`:428`, `:439`-`:445`, `:472`-`:478`, `:590`-`:605` e
  `:611`-`:628` inferem tags, bracket scope e bonus premium por nomes/listas
  (`highPowerNames`, `premium`). Embora a view em `:237`-`:241` junte
  `card_function_tags` e `card_semantic_tags_v2`, a inferencia local ainda pode
  mudar score/bracket por nome.
- `server/lib/ai/optimize_runtime_support.dart:406`-`:454` da bonus de fixing
  a `premiumLandNames`; `:1296`-`:1360` usa `stapleNames` como fallback de
  candidatos; `:1966`-`:2051` aplica bonus a `_premiumCommanderFillerNames`;
  `:2318`-`:2341` soma `preferredScore` por `preferredNames`; `:3476`-`:3512`
  busca fallbacks universais por nomes. Todos sao decisoes runtime de optimize.
- `server/routes/ai/optimize/index.dart:1113`-`:1123` retorna mock runtime
  quando `deckOptimizer == null` com adicoes `Sol Ring` e `Arcane Signet`.
  Mesmo sendo dev/mock, o endpoint runtime pode entregar isso se nao houver
  optimizer configurado; deveria ser fixture isolado ou resposta explicitamente
  nao-produto.
- `server/lib/ai/rebuild_guided_service.dart:1226`-`:1231` classifica ramp por
  `signet`/`sol ring`/`talisman`; `:1331`-`:1338` e `:1404`-`:1411` priorizam
  utility lands especificas (`Temple of the False God`, `Terrain Generator`,
  `Scavenger Grounds`, `Myriad Landscape`, `Reliquary Tower`, `War Room`,
  `Ancient Tomb`).
- `server/routes/decks/[id]/recommendations/index.dart:40`-`:57` carrega apenas
  dados basicos de carta, `:110`-`:130` recalcula buckets por heuristicas locais,
  `:263`-`:266` recomenda `Command Tower` diretamente quando faltam terrenos e
  `:417`-`:427` usa raridade `rare/mythic` como proxy de staple sem role
  semantico persistido.
- `server/routes/ai/weakness-analysis/index.dart:42`-`:59` nao carrega
  `card_function_tags`, `semantic_tags_v2` ou `card_role_scores`; `:114`-`:162`
  recalcula utilidade localmente e ainda reconhece protecao por nomes; `:206`-`:248`
  e `:352`-`:357` retornam listas fixas de recomendacoes por nomes.

#### Intentional exception - policy externa ainda precisa fonte/teste dedicado

- `server/lib/edh_bracket_policy.dart` continua sendo a excecao correta para
  nomes quando a regra vem de bracket/Game Changer/combo externo. Essa
  classificacao nao autoriza listas inline em optimize/recommendations; exige
  fonte, versao e teste da policy.

### Drift entre tags funcionais, semantic v2 e optimize roles

#### P1 - Optimize ainda nao threada `card_function_tags` no contexto/validator

- **Deck analysis (controle positivo):**
  `server/routes/decks/[id]/analysis/index.dart:34`-`:66` seleciona
  `card_semantic_tags_v2`; `:80`-`:96` seleciona `card_function_tags` e
  `semantic_tags_v2`; `:279` chama `summarizeFunctionalTagsForDeck`.
  `server/lib/ai/functional_card_tags.dart:432`-`:445` prefere
  `functional_tags` persistidos e so cai para `inferFunctionalCardTags` depois.
- **Optimize context:** `server/lib/ai/optimize_request_support.dart:86`-`:107`
  seleciona `semantic_tags_v2`, mas nao seleciona `card_function_tags`;
  `:186`-`:198` monta `allCardData` sem `functional_tags`; `_semanticV2SelectSql`
  em `:323`-`:339` agrega somente `card_semantic_tags_v2`.
- **Optimize additions/gate:** `server/routes/ai/optimize/index.dart:2090`-`:2099`
  monta `additionsData` com `semantic_tags_v2`, sem `functional_tags`, antes de
  chamar `filterUnsafeOptimizeSwapsByCardData` em `:2103`-`:2109`.
- **Validator/gate:** `server/lib/ai/optimization_quality_gate.dart:52`-`:53`
  e `server/lib/ai/optimization_validator.dart:265`-`:267` usam
  `classifyOptimizationFunctionalRole`. Esse classificador usa
  `semantic_tags_v2` primeiro e fallback `type_line`/`oracle_text` em
  `server/lib/ai/optimization_functional_roles.dart:55`-`:124`, mas nao le
  `functional_tags`.
- **Nuance:** candidate quality nao esta totalmente sem `card_function_tags`.
  A view em `server/lib/ai/candidate_quality_data_support.dart:237`-`:241`
  junta `card_function_tags`, `card_role_scores` e `card_semantic_tags_v2`, e
  `server/lib/ai/optimize_runtime_support.dart:2655` consulta
  `card_function_tags`. A lacuna ativa e o adapter usado por contexto,
  role-preservation e validator.
- **Por que e drift:** uma carta pode contar como `draw`/`engine`/`payoff` na
  aba de analise por `card_function_tags`, mas optimize decide seguranca por
  `semantic_tags_v2` ou heuristica local.
- **O que valida:** queries de optimize carregarem `card_function_tags` para
  removals e additions, e um adapter unico preservar roles persistidos no
  quality gate e no validator.
- **O que falsifica:** teste mostrando uma carta com apenas
  `card_function_tags=[draw]` preservada como `draw` em deck analysis,
  `filterUnsafeOptimizeSwapsByCardData`, `OptimizationValidator` e diagnostics.

#### P1 - `semantic_tags_v2` multi-tag ainda colapsa para role unico no optimize

- `server/lib/ai/optimization_functional_roles.dart:127`-`:180` escolhe o
  melhor objeto de `semantic_tags_v2`, extrai tags, mas retorna a primeira role
  pela ordem fixa `draw`, `removal`, `ramp`, `tutor`, `protection`,
  `recursion`, `wincon`, `combo_piece`, depois flags `engine`/`payoff`/`enabler`.
- `buildOptimizationSemanticV2Diagnostics` em
  `server/lib/ai/optimization_functional_roles.dart:292`-`:323` calcula
  `role_delta` somente com esse role escalar.
- `OptimizationValidator` tambem calcula `roleDelta` por um unico
  `removedRole`/`addedRole` em `server/lib/ai/optimization_validator.dart:317`-`:340`.
- **Por que e drift:** deck analysis preserva conjunto de tags em
  `summarizeFunctionalTagsForDeck`, mas optimize perde roles secundarios. Uma
  carta `draw + engine` pode ser tratada so como `draw`; uma troca que perde
  engine/payoff/enabler pode passar se o role primario for preservado.
- **O que valida:** diagnostics retornarem `roles` como conjunto e
  `primary_role` separado, com delta por role secundario.
- **O que falsifica:** teste de v2 multi-tag provando que `draw` e `engine`
  aparecem ambos no role delta e no gate.

#### P2 - Fallback textual diverge entre classificadores

- `functional_card_tags.dart` usa nomes conhecidos dentro de `_looksLikeWincon`,
  `_looksLikeComboPiece`, `_looksLikePayoff` e `_looksLikeEnabler` em
  `:859`-`:899`.
- `optimization_functional_roles.dart:370`-`:397` usa outro conjunto de padroes,
  sem nomes conhecidos. Alem disso, o comentario em `:111`-`:112` diz que roles
  altos sao checados antes do fallback de tipo, mas o codigo ja retornou
  `wipe`, `protection`, `removal`, `ramp`, `draw` e `tutor` em `:63`-`:108`.
- **O que valida:** um adapter compartilhado coberto por fixtures equivalentes
  e uma ordem documentada (`persisted functional -> semantic v2 -> oracle/type`).
- **O que falsifica:** testes demonstrando paridade de output entre os dois
  classificadores para combo, engine, payoff, enabler e wincon.

### Avaliacao de utilidade real

- Caminhos mais proximos do desejado: `GET /decks/:id/analysis` usa
  `card_function_tags`, `semantic_tags_v2`, `oracle_text`, `type_line`,
  `mana_cost` e `cmc` antes de montar `functional_tags`.
- Caminhos ainda one-dimensional/name-based:
  `/decks/:id/recommendations` usa heuristicas locais e nomeia `Command Tower`;
  `/ai/weakness-analysis` nao carrega semantica persistida e devolve listas fixas;
  candidate quality e optimize ainda aplicam bonus/listas por nome. A correcao
  estreita e reutilizar a camada semantica compartilhada nesses pontos, mantendo
  listas por nome somente como policy versionada ou seed/corpus declarado.

## Rodada focada: Classes not used - revalidacao 2026-06-06 03:00 UTC

Escopo desta rodada: somente classes sem uso runtime confirmado. Nao foi feita
auditoria ampla de funcoes sem chamada, imports/ciclos, tabelas PostgreSQL,
duplicacao geral ou coerencia entre camadas fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `fd4c2620`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor textual cobre apenas `server/lib` e
`server/routes`. Ele inventaria classes, mas nao monta grafo de uso, nao cobre
`app/lib` e nao distingue widget runtime de teste. A execucao reescreveu
`STRUCTURE_AUDIT.md` em formato de inventario gerado; essa mutacao automatica
foi descartada para preservar o historico manual, e somente os numeros acima e
a triagem focada abaixo foram incorporados.

### Metodo manual focado

- `rg` para declaracoes, imports e chamadas de construtor dos candidatos
  historicos de classes sem uso em `app/lib`, `app/test` e
  `app/integration_test`.
- Busca separada em `app/lib` para diferenciar uso runtime de uso test-only.
- Varredura textual ampla de classes publicas em `app/lib`, `server/lib` e
  `server/routes` usada somente como triagem auxiliar. Itens encontrados apenas
  no proprio arquivo nao foram reportados sem leitura/grep adicional, porque
  muitos sao DTOs ou classes auxiliares vivas dentro do mesmo arquivo.

### Achados revalidados

#### P1/P2 - `LifeCounterScreen` segue legado/test-only; rota viva usa Lotus

- **Classe:** `app/lib/features/home/life_counter_screen.dart:61` declara
  `LifeCounterScreen`, com construtor em `:66`.
- **Busca runtime:** `rg -n "\bLifeCounterScreen\b" app/lib` retornou somente
  o proprio `life_counter_screen.dart`; nao ha import ou builder runtime desse
  widget em `app/lib`.
- **Controle positivo:** `app/lib/main.dart:54` importa
  `features/home/lotus_life_counter_screen.dart`, e a rota do contador em
  `app/lib/main.dart:283` usa `const LotusLifeCounterScreen()`.
- **Teste/documentacao:** `app/test/features/home/life_counter_screen_test.dart:9`
  importa o arquivo legado e `:36` instancia `LifeCounterScreen`; tambem ha uso
  test-only em `app/test/features/home/life_counter_clone_proof_test.dart:10`
  e `:277`. `app/test/README.md:137` afirma que o caminho vivo segue em
  `LotusLifeCounterScreen`, e `app/test/README.md:149` diz que o caminho oficial
  nao e mais `LifeCounterScreen`.
- **Por que parece sem uso runtime:** o unico ponto app-facing mapeado para o
  contador e a rota de `main.dart`, que instancia Lotus; as referencias restantes
  ao widget antigo estao em teste ou no proprio arquivo.
- **O que valida:** remover a tela legada junto com os testes dependentes, ou
  reclassifica-la explicitamente como fixture/benchmark test-only.
- **O que falsifica:** uma rota, feature flag ou chamada em `app/lib` que
  importe `life_counter_screen.dart` e instancie `LifeCounterScreen`.

#### P2 - `DeckCard` continua sem uso na listagem runtime

- **Classe:** `app/lib/features/decks/widgets/deck_card.dart:17` declara
  `DeckCard`, com construtor em `:22`.
- **Busca runtime:** `rg -n "\bDeckCard\b" app/lib` retornou somente a propria
  definicao; nao ha import de `deck_card.dart` em `app/lib`.
- **Test-only:** `app/test/features/decks/widgets/deck_card_test.dart:4`
  importa `deck_card.dart` e `:9` instancia `DeckCard`;
  `app/test/features/decks/widgets/deck_card_overflow_test.dart:4` importa o
  mesmo arquivo e `:47` instancia `DeckCard`.
- **Controle de listagem:** `app/lib/features/decks/screens/deck_list_screen.dart:1`-`:12`
  importa tema, widgets genericos e modelos/providers, mas nao importa
  `deck_card.dart`; a tela usa seus proprios widgets privados, como
  `_EmptyDeckCard` em `app/lib/features/decks/screens/deck_list_screen.dart:1770`
  e `:1823`.
- **Por que parece sem uso runtime:** o componente publico existe com testes,
  mas a listagem real nao o importa nem constroi.
- **O que valida:** religar `DeckCard` na listagem real ou remover o widget e os
  testes dedicados se a listagem atual substituiu o componente.
- **O que falsifica:** import runtime de `features/decks/widgets/deck_card.dart`
  e construcao de `DeckCard(...)` fora de teste.

#### P2 - `DeckProgressChip` nao tem chamada de construtor

- **Classe:** `app/lib/features/decks/widgets/deck_progress_indicator.dart:286`
  declara `DeckProgressChip`, com construtor em `:292`.
- **Busca:** `rg -n "DeckProgressChip\(" app/lib app/test app/integration_test`
  retornou somente o construtor em `deck_progress_indicator.dart:292`.
- **Controle positivo:** `DeckProgressIndicator` permanece vivo: declarado em
  `app/lib/features/decks/widgets/deck_progress_indicator.dart:14` e chamado em
  `app/lib/features/decks/widgets/deck_details_overview_tab.dart:328` e
  `app/lib/features/decks/screens/deck_details_screen.dart:403`.
- **Por que parece sem uso runtime:** o arquivo contem um indicador vivo, mas o
  chip compacto exportado nao e instanciado por app nem testes.
- **O que valida:** substituir usos locais por `DeckProgressChip` se ele ainda
  for o componente compacto desejado, ou remover a classe se o design consolidou
  em `DeckProgressIndicator`.
- **O que falsifica:** qualquer chamada `DeckProgressChip(...)` em app/test ou
  codigo runtime.

#### P2 - `LotusPresentationMode` segue sem integracao com Lotus

- **Classe:** `app/lib/features/home/lotus/lotus_presentation_mode.dart:4`
  declara `LotusPresentationMode`.
- **Metodos:** `enter()` em `app/lib/features/home/lotus/lotus_presentation_mode.dart:15`
  e `exit()` em `:26`.
- **Busca:** `rg` por `LotusPresentationMode`, `enter()` e `exit()` em
  `app/lib/features/home`, `app/test/features/home` e `app/integration_test`
  retornou somente a propria classe/metodos.
- **Por que parece sem uso runtime:** a tela Lotus viva nao importa nem chama o
  helper de presentation mode, entao o modo nunca e acionado.
- **O que valida:** chamar `LotusPresentationMode.enter/exit` no ciclo de vida
  da tela Lotus, com teste de plataforma/fallback, ou remover o helper.
- **O que falsifica:** import e chamada real do helper em
  `lotus_life_counter_screen.dart` ou modulo runtime equivalente.

#### P2 - Shell visual de auth esta isolado e nao e usado por login/register

- **Classes:** `app/lib/features/auth/widgets/auth_visual_shell.dart:5`
  declara `AuthVisualShell`, `:105` declara `AuthBrandHeader` e `:196` declara
  `AuthFormSurface`.
- **Busca:** `rg -n "\bAuthVisualShell\(|\bAuthBrandHeader\(|\bAuthFormSurface\(" app/lib app/test app/integration_test`
  retornou somente os construtores no proprio arquivo.
- **Controles de telas:** `app/lib/features/auth/screens/login_screen.dart:1`-`:5`
  e `app/lib/features/auth/screens/register_screen.dart:1`-`:5` importam
  `app_theme.dart` e `auth_provider.dart`, mas nao importam
  `auth_visual_shell.dart`.
- **Por que parece sem uso runtime:** o shell visual foi criado como componente
  publico, mas as telas de auth continuam montando seu proprio layout.
- **O que valida:** migrar login/register/splash para o shell, ou remover o
  arquivo se ele foi abandonado durante o polish visual.
- **O que falsifica:** construcao real de `AuthVisualShell`, `AuthBrandHeader`
  ou `AuthFormSurface` fora do proprio arquivo.

### Controles positivos descartados

- `LotusLifeCounterScreen` nao e classe sem uso: `app/lib/main.dart:283`
  instancia o widget na rota do contador e ha cobertura extensa em testes e
  integration tests.
- `DeckProgressIndicator` nao e classe sem uso: alem da declaracao em
  `deck_progress_indicator.dart`, ha chamadas runtime em
  `deck_details_overview_tab.dart:328` e `deck_details_screen.dart:403`.
- A varredura textual ampla encontrou varias classes publicas referenciadas
  apenas no proprio arquivo, mas elas foram descartadas nesta rodada quando a
  leitura indicou DTO/model/helper local vivo dentro do mesmo modulo. Sem uso
  externo nao e evidencia suficiente de codigo morto para esses casos.

## Rodada focada: Coerencia entre `server/lib` <-> `server/routes` <-> `app/lib` — revalidacao 2026-06-05 23:00 UTC

Escopo desta rodada: somente coerencia entre consumidores em `app/lib`,
handlers em `server/routes` e helpers em `server/lib`. Nao foi feita auditoria
ampla de classes sem uso, funcoes sem chamada, imports/ciclos, tabelas
PostgreSQL ou duplicacao geral fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `49939bb6`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor textual cobre `server/lib` e
`server/routes`; ele nao entende consumidores Flutter, contratos app-facing,
ownership, propagacao de `userId` entre rota e helper, nem DTOs consumidos pelo
app. A execucao reescreveu `STRUCTURE_AUDIT.md` em formato de inventario
gerado; essa mutacao automatica foi descartada para preservar o historico
manual, e somente os numeros acima e a triagem focada abaixo foram incorporados.

### Metodo manual focado

- Busca por endpoints consumidos em `app/lib` e leitura pontual dos handlers em
  `server/routes` e helpers em `server/lib`.
- Comparacao de contratos de ownership para rotas de deck/IA chamadas pelo app.
- Verificacao de controles positivos: `POST /ai/rebuild`,
  `GET /decks/:id/analysis` e `POST /decks/:id/ai-analysis` continuam escopando
  o deck por `id + user_id` antes de carregar cartas.
- Comparacao com `server/doc/API_CONTRACTS_AND_DATA_MAP.md` para detectar
  consumidores marcados como `not proven` apesar de uso real em `app/lib`.

### Achados revalidados

#### P1 — `POST /ai/optimize` continua recebendo `deck_id` do app sem owner-scope no helper

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:10`-`:23`
  monta payload com `deck_id`, `archetype`, `bracket`, `keep_theme` e
  `intensity`; `app/lib/features/decks/providers/deck_provider_support_ai.dart:56`
  envia `POST /ai/optimize`.
- **Handler:** `server/routes/ai/optimize/index.dart:401`-`:405` tenta ler
  `userId`, mas `server/routes/ai/optimize/index.dart:549`-`:558` chama
  `optimize_request.loadOptimizeDeckContext(...)` sem passar `userId`.
- **Helper:** `server/lib/ai/optimize_request_support.dart:53`-`:62` nao
  recebe `userId`; a query do deck em `server/lib/ai/optimize_request_support.dart:63`-`:73`
  usa `SELECT name, format FROM decks WHERE id = @id`, e as queries de cartas
  em `server/lib/ai/optimize_request_support.dart:87`-`:137` usam apenas
  `WHERE dc.deck_id = @id`.
- **Por que e incoerente:** o app trata optimize como acao sobre deck privado do
  usuario autenticado, mas a fronteira `routes -> lib` carrega qualquer deck por
  UUID.
- **O que valida:** `loadOptimizeDeckContext` receber `userId`, consultar o deck
  por `id + user_id` ou regra publica explicita, e testes owner vs non-owner
  para caminhos sync e async.
- **O que falsifica:** contrato documentado e testado provando que optimize
  aceita deck publico/alheio por design sem expor composicao privada.

#### P1 — `POST /ai/archetypes` tambem carrega deck/cartas por id sem owner-scope

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_mutation.dart:168`-`:173`
  chama `POST /ai/archetypes` com apenas `{'deck_id': deckId}`.
- **Handler:** `server/routes/ai/archetypes/index.dart:27`-`:35` le `deck_id`
  e `Pool`, mas nao le `context.read<String>()`; a query do deck em
  `server/routes/ai/archetypes/index.dart:39`-`:42` usa
  `SELECT name, format FROM decks WHERE id = @id`, e a query de cartas em
  `server/routes/ai/archetypes/index.dart:54`-`:62` usa `WHERE dc.deck_id = @id`.
- **Por que e incoerente:** as opcoes de arquetipo derivam da lista real do
  deck, mas qualquer usuario autenticado pode analisar um UUID de deck existente.
- **O que valida:** escopar `POST /ai/archetypes` por `deck_id + user_id` antes
  de montar cache/prompt/reference profile e adicionar teste non-owner.
- **O que falsifica:** contrato explicito para analisar apenas decks publicos ou
  compartilhados, com filtro `is_public=true` ou regra equivalente.

#### P1 — Polling de jobs async aceita `user_id = NULL` em optimize e generate

- **Optimize app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:74`-`:87`
  trata `202` de `/ai/optimize` como job async; `:190`-`:194` faz polling em
  `/ai/optimize/jobs/$jobId`.
- **Optimize backend:** `server/lib/ai/optimize_job.dart:25`-`:30` permite
  `String? userId`; `server/lib/ai/optimize_job.dart:47`-`:64` persiste
  `user_id` nullable; `server/routes/ai/optimize/jobs/[id].dart:39`-`:47`
  bloqueia apenas quando `job.userId != null && job.userId != userId`.
- **Generate app:** `app/lib/features/decks/providers/deck_provider_support_generation.dart:230`-`:236`
  envia `POST /ai/generate` com `async: true`; `:248`-`:301` exige
  `job_id`/`poll_url`; `:379` faz `GET` no `poll_url`.
- **Generate backend:** `server/routes/ai/generate/index.dart:786`-`:813` le
  `userId` de forma tolerante e chama `AiGenerateJobStore.create` com
  `String? userId`; `server/lib/ai_generate_job.dart:12`-`:17` aceita usuario
  nullable; `server/routes/ai/generate/jobs/[id].dart:16`-`:19` tambem bloqueia
  apenas quando `job.userId != null && job.userId != userId`.
- **Contrato documental:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md:168`
  descreve `GET /ai/generate/jobs/:id` como rota autenticada e diz que `404`
  pode significar `not owned`, mas o handler permite jobs sem dono.
- **Por que e incoerente:** o app nao tem conceito de job publico, e os
  endpoints ficam sob `/ai` autenticado; `user_id = NULL` enfraquece a fronteira
  de usuario se algum job interno/legado/falha de contexto persistir sem dono.
- **O que valida:** exigir `userId` nao nulo em jobs app-facing e retornar 404
  quando `job.userId == null`, salvo rota interna separada e documentada.
- **O que falsifica:** teste provando que nenhum job app-facing pode ser criado
  sem usuario e que o estado nulo tem politica segura.

#### P1/P2 — Deck analysis usa `functional_tags`, mas optimize ainda nao threada a mesma camada

- **App:** `app/lib/features/decks/providers/deck_provider_support_fetch.dart:135`-`:140`
  chama `GET /decks/$deckId/analysis`; `app/lib/features/decks/models/deck_analysis.dart:14`-`:28`
  parseia `functional_tags`; `:38`-`:48` usa esses counts/samples antes do
  fallback `stats.composition`.
- **Rotas de analysis:** `server/routes/decks/[id]/analysis/index.dart:80`-`:96`
  seleciona `card_function_tags` e `semantic_tags_v2`; `server/routes/decks/[id]/ai-analysis/index.dart:119`-`:135`
  faz o mesmo para `metrics.functional_tags`.
- **Optimize:** `server/lib/ai/optimize_request_support.dart:86`-`:106`
  agrega apenas `card_semantic_tags_v2`; `server/lib/ai/optimize_request_support.dart:186`-`:198`
  monta `allCardData` com `semantic_tags_v2`, mas sem `functional_tags`.
  O caminho local de additions em `server/routes/ai/optimize/index.dart:2063`-`:2099`
  repete a mesma ausencia.
- **Por que e incoerente:** a aba de analise app-facing explica cartas por
  `functional_tags`, enquanto optimize/validator continuam decidindo roles sem
  receber a mesma evidencia persistida.
- **O que valida:** threadar `card_function_tags` no contexto de optimize e usar
  um adapter unico de roles para analysis, optimize, validator e quality gate.
- **O que falsifica:** contrato testado provando que optimize deve ignorar
  `functional_tags` persistidas e usar somente `semantic_tags_v2`/heuristica.

#### P2 — Telemetria de ativacao tem consumidor real no app, mas contrato/allow-list ainda divergem

- **App service:** `app/lib/core/services/activation_funnel_service.dart:17`-`:23`
  envia `POST /users/me/activation-events` e engole falhas em `:24`-`:26`.
- **Consumidores reais:** `app/lib/features/home/onboarding_core_flow_screen.dart:32`-`:72`
  envia eventos de onboarding presentes na allow-list; `app/lib/features/decks/providers/deck_provider.dart:603`-`:614`
  envia `deck_rebuild_created` apos draft de rebuild.
- **Backend:** `server/routes/users/me/activation-events/index.dart:10`-`:18`
  permite somente `core_flow_started`, `format_selected`, `base_choice_generate`,
  `base_choice_import`, `deck_created`, `deck_optimized` e
  `onboarding_completed`; `:46`-`:48` rejeita qualquer outro evento.
- **Contrato documental:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md:61` ainda
  marca `POST /users/me/activation-events` como `internal` e consumidor
  `onboarding/activation code not proven`, apesar dos consumidores acima em
  `app/lib`.
- **Por que e incoerente:** a telemetria `deck_rebuild_created` e emitida pelo
  app, mas sempre rejeitada pelo backend e silenciosamente perdida pelo service.
- **O que valida:** adicionar `deck_rebuild_created` a `_allowedEvents` com
  teste, ou remover/renomear a emissao app; atualizar o contrato para listar os
  consumidores reais.
- **O que falsifica:** decisao explicita de nao coletar rebuild na telemetria,
  com app deixando de emitir o evento.

#### P2 — Endpoints experimentais deck/AI seguem sem owner-scope antes de promocao app-facing

- **Endpoints:** `GET /decks/:id/simulate`, `POST /decks/:id/recommendations`,
  `POST /ai/simulate-matchup`, `POST /ai/weakness-analysis`.
- **Evidencia de rotas:** `server/routes/decks/[id]/simulate/index.dart:13`-`:26`
  le cartas por `WHERE dc.deck_id = @deckId`; `server/routes/decks/[id]/recommendations/index.dart:23`-`:58`
  le deck/cartas por `deckId`; `server/routes/ai/simulate-matchup/index.dart:76`-`:103`
  usa `SELECT id, name, format FROM decks WHERE id = @id` e cartas por
  `dc.deck_id = @id`; `server/routes/ai/weakness-analysis/index.dart:30`-`:60`
  faz o mesmo com `deck_id`.
- **Evidencia app/contrato:** busca focada em `app/lib` nao encontrou chamadas
  para esses endpoints; o API map ainda marca esses consumidores como
  `not proven`/experimentais.
- **Por que e incoerente:** as rotas vivem em namespaces autenticados, mas nao
  aplicam o padrao de ownership dos endpoints de deck estaveis; se forem ligadas
  no app, podem expor estatisticas ou recomendacoes derivadas de deck privado.
- **O que valida:** antes de expor no app, escopar `deck_id`/`my_deck_id` por
  `user_id`, definir regra separada para oponente publico/meta deck e adicionar
  teste non-owner.
- **O que falsifica:** decisao explicita de manter esses endpoints internos ou
  remove-los da superficie app-facing, com contrato atualizado e sem chamada em
  `app/lib`.

### Controles positivos

- `POST /ai/rebuild` nao foi reaberto: `server/routes/ai/rebuild/index.dart:16`
  le `userId`, e `server/routes/ai/rebuild/index.dart:61`-`:78` escopa o deck
  por `id + user_id` antes de carregar cartas.
- `GET /decks/:id/analysis` nao foi reaberto para ownership:
  `server/routes/decks/[id]/analysis/index.dart:18`-`:25` filtra `decks` por
  `deckId + userId` antes da consulta de cartas.
- `POST /decks/:id/ai-analysis` tambem permanece owner-scoped:
  `server/routes/decks/[id]/ai-analysis/index.dart:25`-`:40` le `userId` e
  consulta `decks` com `id + user_id`.
- Onboarding activation events enviados por
  `app/lib/features/home/onboarding_core_flow_screen.dart:32`-`:72` batem com a
  allow-list backend; a divergencia concreta e `deck_rebuild_created`.

## Rodada focada: Duplicated or similar logic — revalidacao 2026-06-05 19:00 UTC

Escopo desta rodada: somente logica duplicada ou similar com risco de drift.
Nao foi feita auditoria ampla de classes sem uso, funcoes sem chamada, imports,
ciclos, tabelas PostgreSQL ou coerencia geral entre camadas fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `82592f5d`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor textual cobre apenas `server/lib` e
`server/routes` e sua deteccao de duplicacao e apenas heuristica de nomes iguais
em funcoes publicas. Ele nao compara corpos, semantica, SQL inline, helpers
privados, `app/lib` ou contratos de resposta. A execucao reescreveu
`STRUCTURE_AUDIT.md` em formato de inventario gerado; essa mutacao automatica
foi descartada para preservar o historico manual, e somente os numeros acima e
a triagem focada abaixo foram incorporados.

### Metodo manual focado

- Revalidacao por `rg` e leitura pontual de clusters historicos de duplicacao:
  `resolveOptimizeArchetype`, `_looksLike*`, `_isBasicLandName`, trust social,
  `_requestId`/`_logInvalidPayload`, `condition`, `getMainType` e
  `calculateCmc`.
- Comparacao manual dos contratos e diferencas de regra, nao apenas nome de
  simbolo.
- Controles positivos: o wrapper
  `server/routes/ai/optimize/index.dart:56`-`:63` foi tratado como delegacao
  fina para `optimize_support.resolveOptimizeArchetype`, nao como duplicacao
  real de corpo.

### Achados revalidados

#### P1 — `resolveOptimizeArchetype` segue com duas semanticas runtime

- **Simbolos:** `resolveOptimizeArchetype` em
  `server/lib/ai/deck_state_analysis.dart:573` e
  `server/lib/ai/optimize_runtime_support.dart:3369`.
- **Evidencia de divergencia:** a versao de deck state aceita
  `requestedArchetype` nullable, trata `general` e `tempo` como genericos e
  retorna `detected ?? 'midrange'` quando o requested esta vazio
  (`deck_state_analysis.dart:573`-`:584`). A versao de optimize exige
  `requestedArchetype`, trata `unknown` como detected vazio, considera
  `goodstuff` generico e so promove detected especificos em
  `{aggro, control, combo, stax, tribal}`
  (`optimize_runtime_support.dart:3369`-`:3388`).
- **Chamadores vivos:** `rebuild_guided_service.dart:171` usa a versao de deck
  state; `optimize_request_support.dart:289` e `:294` usam a versao de optimize.
- **Por que parece defeito estrutural:** optimize e rebuild podem resolver
  arquetipo efetivo diferente para os mesmos pares requested/detected, inclusive
  `tempo`, `general`, `goodstuff` e `unknown`.
- **O que valida:** consolidar um unico helper compartilhado com testes para
  requested nulo/vazio, `unknown`, `general`, `tempo`, `goodstuff`,
  `midrange` e detected especifico.
- **O que falsifica:** contrato documentado e testado mostrando que rebuild e
  optimize devem resolver arquetipos por politicas diferentes.

#### P1 — Heuristicas de roles altos continuam duplicadas e divergentes

- **Simbolos duplicados:** `_looksLikeWincon`, `_looksLikeComboPiece`,
  `_looksLikeEngine`, `_looksLikePayoff` e `_looksLikeEnabler` em
  `server/lib/ai/functional_card_tags.dart:859`-`:905` e
  `server/lib/ai/optimization_functional_roles.dart:370`-`:398`.
- **Evidencia de divergencia:** `functional_card_tags.dart` mistura
  `oracle_text` com nomes conhecidos como `thassa's oracle`, `isochron scepter`,
  `dramatic reversal`, `blood artist`, `greaves` e `boots`
  (`:859`-`:900`). `optimization_functional_roles.dart` classifica um role
  escalar em ordem fixa (`:113`-`:117`) e usa apenas padroes de texto, com
  regras bem mais estreitas para wincon/combo/payoff/enabler (`:370`-`:398`).
- **Por que parece defeito estrutural:** deck analysis e optimize podem dar
  papeis diferentes para a mesma carta; o primeiro produz tags multiplas, o
  segundo retorna um role unico e nao herda as mesmas excecoes por nome.
- **O que valida:** criar adapter unico que aceite nome, `oracle_text`,
  `type_line`, `functional_tags` e `semantic_tags_v2`, retornando conjunto de
  roles mais `primary_role`, com testes de cartas multi-role.
- **O que falsifica:** regra explicita e testada dizendo que optimize deve usar
  um classificador propositalmente menor/escala unico, independente das tags de
  analysis.

#### P1/P2 — Basic lands e snow basics ainda usam quatro listas locais

- **Simbolos:** `isBasicLandName`/`_isBasicLandName` em
  `server/lib/ai/optimize_runtime_support.dart:285` e `:4184`-`:4197`,
  `server/lib/generated_deck_validation_service.dart:752`-`:763`,
  `server/lib/meta/meta_deck_reference_support.dart:890`-`:903` e
  `server/routes/ai/commander-reference/index.dart:621`-`:628`.
- **Evidencia de divergencia:** optimize aceita nomes com hifen
  `snow-covered ...`; generated deck validation usa `startsWith`, tambem com
  hifen; meta reference usa `snow covered ...` sem hifen; commander-reference
  nao aceita snow basics nesse helper.
- **Por que parece defeito estrutural:** singleton/copy-limit, validate, meta
  reference e commander-reference podem discordar sobre a mesma carta basica,
  especialmente snow basics ou nomes normalizados sem hifen.
- **O que valida:** extrair helper unico de normalizacao de basic/snow basic e
  usar nos quatro fluxos com teste de hifen, espaco, case e `Wastes`.
- **O que falsifica:** decisao documentada de que commander-reference deve
  tratar snow basics de forma diferente, com cobertura dedicada.

#### P2 — Trust social repete SQL e serializer em trades e marketplace

- **SQL duplicado:** `_trustStatsSql`, `_responseTimeSql` e `_shippingTimeSql`
  em `server/routes/trades/index.dart:557`-`:601` e
  `server/routes/trades/[id]/index.dart:260`-`:304`; marketplace repete os
  mesmos LATERALs inline em
  `server/routes/community/marketplace/index.dart:131`-`:164`.
- **Serializer duplicado:** `_buildTrustInsight` em
  `server/routes/trades/index.dart:603`-`:635`,
  `server/routes/trades/[id]/index.dart:306`-`:338` e
  `server/routes/community/marketplace/index.dart:316`-`:348`.
- **Por que parece defeito estrutural:** qualquer alteracao na definicao de
  historico insuficiente, conta nova, perfil incompleto ou medias de resposta
  precisa ser replicada em tres superficies app-facing.
- **O que valida:** helper SQL/serializer compartilhado por dominio social, com
  testes garantindo mesmo shape para listagem/detalhe de trades e marketplace.
- **O que falsifica:** contratos app-facing diferentes por superficie,
  documentados no API map e cobertos por testes de resposta.

#### P2 — Request-id e log de payload invalido seguem repetidos em rotas sociais

- **Simbolos:** `_requestId` e `_logInvalidPayload` em
  `server/routes/trades/index.dart:330`-`:353`,
  `server/routes/trades/[id]/status.dart:260`-`:284`,
  `server/routes/trades/[id]/respond.dart:154`-`:178`,
  `server/routes/trades/[id]/messages.dart:228`-`:252` e
  `server/routes/conversations/[id]/messages.dart:247`-`:271`.
- **Evidencia de helper existente:** `server/lib/request_trace.dart:48`-`:57`
  ja expoe `getRequestTrace` e `tryGetRequestId`, mas as rotas ainda duplicam o
  fallback `context.read<RequestTrace>().requestId` ou header `x-request-id`.
- **Por que parece defeito estrutural:** a correlacao operacional de
  `x-request-id` fica espalhada e qualquer mudanca de fallback/log format deve
  ser replicada manualmente.
- **O que valida:** helper compartilhado de logging social que use
  `tryGetRequestId` e padronize `endpoint`, `reason`, `user_id` e id de
  entidade.
- **O que falsifica:** diferencas intencionais de formato por rota, declaradas
  como contrato operacional e cobertas em teste/log snapshot.

#### P2/P3 — Condicao de carta e CMC/tipo ainda tem pequenas duplicacoes app-facing

- **Condicao:** marketplace ignora filtro invalido ao limitar a allow-list
  `NM/LP/MP/HP/DMG` em `server/routes/community/marketplace/index.dart:39`-`:43`;
  binder rejeita condicao invalida em `server/routes/binder/index.dart:258` em
  diante; mutacoes/imports de deck usam default `NM` em caminhos como
  `server/routes/decks/[id]/cards/set/index.dart:124` e
  `server/routes/import/to-deck/index.dart:189`.
- **CMC/tipo:** `getMainType` e `calculateCmc` existem dentro de
  `server/routes/decks/[id]/index.dart:405`-`:435` e
  `server/routes/community/decks/[id].dart:91`-`:116`; a simulacao tem variante
  `_calculateCmc` em `server/routes/decks/[id]/simulate/index.dart:171`-`:185`.
- **Por que parece defeito estrutural:** condicao invalida tem comportamento
  diferente por endpoint (default/reject/ignore), e CMC/tipo podem divergir em
  estatisticas privadas, publicas e simulacao.
- **O que valida:** policy compartilhada de condicao por operacao
  (`normalize`, `reject`, `ignore_filter`) e helper comum de CMC/tipo com testes
  para X, hibrido, phyrexian e cartas sem custo.
- **O que falsifica:** contratos documentados no API map explicando que filtros
  invalidos devem ser ignorados, mutacoes invalidas devem ser rejeitadas e
  imports devem defaultar para `NM`, com testes separados por fluxo.

### Resultado desta revalidacao

- Os principais clusters de duplicacao de 2026-06-03 continuam abertos neste
  checkout `82592f5d`.
- O maior risco segue no dominio de IA/decks: arquetipo, roles funcionais e
  basic lands podem divergir entre optimize, rebuild, analysis, validate e
  commander-reference.
- As duplicacoes sociais e de DTO/estatistica sao menores, mas continuam
  app-facing e devem ser consolidadas com cuidado para nao alterar shape de
  resposta.

## Rodada focada: Broken imports and circular dependencies — revalidacao 2026-06-05 11:00 UTC

Escopo desta rodada: somente imports locais quebrados e ciclos de dependencia
em Dart. Nao foi feita auditoria ampla de classes sem uso, funcoes sem chamada,
tabelas PostgreSQL, duplicacao ou coerencia geral entre camadas fora deste
foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `61749fe2`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor textual cobre apenas `server/lib` e
`server/routes`; nao analisa `app/lib`, `server/bin`, `app/test` ou
`app/integration_test`, e tambem nao constroi grafo de ciclos. A execucao
reescreve `STRUCTURE_AUDIT.md` em formato de inventario gerado; essa mutacao
automatica foi descartada para preservar o historico manual, e somente os
numeros acima mais a triagem focada abaixo foram incorporados.

### Metodo manual focado

- Resolvedor local de imports Dart executado sobre 424 arquivos em `app/lib`,
  `server/lib`, `server/routes` e `server/bin`.
- O resolvedor tratou imports relativos a partir do diretorio do arquivo origem
  e reconheceu imports locais `package:server/...`, `package:manaloom/...` e o
  alias historico `package:ai/...`.
- Foi calculado grafo de imports locais e SCCs para detectar ciclos fortes no
  mesmo recorte.
- Validacao pontual com analyzer:
  `cd server && dart analyze bin/local_test_server.dart routes/ai/commander-learning/index.dart`
  confirmou os dois imports quebrados backend e a cascata de tipos ausentes.
- `cd app && flutter analyze --no-pub --no-fatal-infos lib/features/decks/widgets/deck_analysis_tab.dart lib/features/home/life_counter_screen.dart`
  foi nao conclusivo como analise geral porque `app/.dart_tool/package_config.json`
  esta ausente e pacotes como Flutter/provider/fl_chart nao foram resolvidos;
  ainda assim, a saida incluiu `uri_does_not_exist` para
  `deck_analysis_tab.dart:5`.

### Achados revalidados

#### P1 — Rota `commander-learning` importa suporte inexistente

- **Import quebrado:** `server/routes/ai/commander-learning/index.dart:4`
  importa `../../../lib/ai/commander_learned_deck_support.dart`, resolvendo para
  `server/lib/ai/commander_learned_deck_support.dart`.
- **Evidencia:** `find server/lib/ai -maxdepth 1 -name '*learned*' -o -name '*learning*'`
  nao encontrou arquivo correspondente neste checkout.
- **Analyzer:** `dart analyze bin/local_test_server.dart routes/ai/commander-learning/index.dart`
  reportou `uri_does_not_exist` em `routes/ai/commander-learning/index.dart:4`
  e erros em cascata para `CommanderLearnedDeckInput` em `:61`, `:105`,
  `:141`, `:146`, `:169`, `:248`, `:265`, `:283` e `:305`.
- **Por que parece defeito real:** o endpoint depende do tipo e dos helpers do
  support ausente para montar/validar learned decks, entao o arquivo nao e
  analisavel neste checkout.
- **O que valida:** restaurar/criar `server/lib/ai/commander_learned_deck_support.dart`
  com `CommanderLearnedDeckInput` e rerodar o analyzer focado.
- **O que falsifica:** remover a rota deste checkout ou alterar o import para
  um support existente que defina exatamente os simbolos usados.

#### P1 — `server/bin/local_test_server.dart` depende de artefato Dart Frog ausente

- **Import quebrado:** `server/bin/local_test_server.dart:3` importa
  `../.dart_frog/server.dart`, resolvendo para `server/.dart_frog/server.dart`.
- **Evidencia:** `find server/.dart_frog -maxdepth 2 -type f` nao encontrou
  arquivo gerado neste checkout.
- **Analyzer:** o mesmo `dart analyze` focado reportou
  `bin/local_test_server.dart:3:8 - Target of URI doesn't exist:
  '../.dart_frog/server.dart'`.
- **Por que parece defeito real:** o entrypoint local fica inutil em clone limpo
  sem uma etapa previa que gere `.dart_frog/server.dart`.
- **O que valida:** documentar/automatizar a geracao antes do wrapper ou trocar
  o entrypoint para um caminho que exista no checkout.
- **O que falsifica:** `.dart_frog/server.dart` passar a ser gerado antes da
  analise/execucao local ou o wrapper ser removido por nao fazer parte do
  contrato operacional.

#### P1 — Dois imports relativos do app saem de `app/lib`

- **Import quebrado:** `app/lib/features/decks/widgets/deck_analysis_tab.dart:5`
  importa `../../../../core/utils/mana_helper.dart`, resolvendo para
  `app/core/utils/mana_helper.dart`; o arquivo real fica em
  `app/lib/core/utils/mana_helper.dart`.
- **Import quebrado:** `app/lib/features/home/life_counter_screen.dart:7`
  importa `../../../core/theme/app_theme.dart`, resolvendo para
  `app/core/theme/app_theme.dart`; o arquivo real fica em
  `app/lib/core/theme/app_theme.dart`.
- **Evidencia:** a varredura de 424 arquivos apontou exatamente esses dois
  imports app quebrados. No mesmo arquivo `deck_analysis_tab.dart`, o import
  vizinho de theme em `:4` usa `../../../core/theme/app_theme.dart`, que resolve
  corretamente para `app/lib/core/theme/app_theme.dart`.
- **Analyzer:** `flutter analyze --no-pub` nao foi conclusivo por dependencias
  ausentes (`app/.dart_tool/package_config.json` nao existe), mas a saida
  incluiu `uri_does_not_exist` para
  `lib/features/decks/widgets/deck_analysis_tab.dart:5`.
- **Por que parece defeito real:** ambos os caminhos sobem um nivel alem de
  `app/lib`, diferentemente dos imports core corretos em arquivos vizinhos.
- **O que valida:** corrigir os relativos para caminhos dentro de `app/lib`
  ou migrar para `package:manaloom/core/...`, depois rerodar analyzer com
  dependencias resolvidas.
- **O que falsifica:** existencia intencional de `app/core/...` versionado, o
  que nao foi observado neste checkout.

#### P2 — Ciclo direto permanece entre telas de comunidade e perfil social

- **Arquivos no SCC:** `app/lib/features/community/screens/community_deck_detail_screen.dart`
  e `app/lib/features/social/screens/user_profile_screen.dart`.
- **Aresta 1:** `community_deck_detail_screen.dart:8` importa
  `../../social/screens/user_profile_screen.dart`; em `:209`-`:216`, navega
  para `UserProfileScreen`.
- **Aresta 2:** `user_profile_screen.dart:7` importa
  `../../community/screens/community_deck_detail_screen.dart`; em `:466`-`:470`,
  navega para `CommunityDeckDetailScreen`.
- **Evidencia do grafo:** a varredura SCC encontrou somente esse componente
  fortemente conectado em `app/lib`, `server/lib`, `server/routes` e
  `server/bin`; nenhum ciclo local foi encontrado no backend.
- **Por que e risco:** Dart aceita ciclos em muitos casos, mas essas features
  conhecem classes concretas uma da outra e ficam mais dificeis de separar,
  testar isoladamente e reorganizar por rotas.
- **O que valida:** mover a navegacao cruzada para uma camada de router/callback
  ou extrair intents compartilhadas sem import concreto entre as telas.
- **O que falsifica:** decisao documentada de manter esse acoplamento como
  contrato intencional, com teste que cubra navegacao nos dois sentidos.

### Resultado desta revalidacao

- A varredura focada encontrou exatamente 4 imports locais quebrados no recorte
  de 424 arquivos: `commander-learning`, `local_test_server.dart`,
  `deck_analysis_tab.dart` e `life_counter_screen.dart`.
- O auditor base apontou somente o import quebrado de `commander-learning`
  porque seu recorte nao inclui `app/lib` nem `server/bin`.
- O grafo focado encontrou exatamente 1 SCC local de dois arquivos:
  `CommunityDeckDetailScreen` <-> `UserProfileScreen`.
- Nao foi encontrado novo ciclo local no backend.

## Rodada focada: Functions not called — revalidacao 2026-06-05 07:00 UTC

Escopo desta rodada: somente funcoes/metodos sem chamador runtime confirmado.
Nao foi feita auditoria ampla de classes sem uso, imports/ciclos, tabelas
PostgreSQL, duplicacao ou coerencia geral entre modulos fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `1c1c34ca`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor textual cobre `server/lib` e
`server/routes`, mas nao constroi grafo de chamadas. A docstring do script
continua dizendo que achados de "nao usado" exigem validacao manual com grep. A
execucao tambem reescreve `STRUCTURE_AUDIT.md` em formato de inventario gerado;
essa mutacao automatica foi descartada para preservar o historico manual, e
somente os numeros acima mais os achados focados abaixo foram incorporados.

### Metodo manual focado

- Revalidacao por `rg` dos candidatos historicos em `server/lib`,
  `server/routes`, `server/bin`, `server/test`, `app/lib`, `app/test` e
  `app/integration_test`.
- Separacao entre uso runtime, uso por teste, docs e definicao propria.
- Scan auxiliar de declaracoes Dart com baixa contagem textual em runtime
  (`server/lib`, `server/routes`, `server/bin`, `app/lib`) usado apenas como
  gerador de candidatos; resultados com chamadas por UI/provider, override,
  observer, teste runtime ou falso positivo de SQL foram descartados.

### Achados revalidados

#### P1 — `sync_cards_utils.dart` segue test-only enquanto o CLI real duplica a logica

- **Funcoes:** `extractCardRow`, `getNewSetCodesSinceFromData`,
  `parseSinceDays`, `extractSetCardRow`, `extractOracleIds` e
  `extractLegalities` em `server/lib/sync_cards_utils.dart:16`, `:82`,
  `:102`, `:116`, `:161` e `:172`.
- **Evidencia de uso restrito a teste:** `server/test/sync_cards_test.dart:3`
  importa `../lib/sync_cards_utils.dart` e chama os helpers diretamente; busca
  por `sync_cards_utils` em Dart runtime nao encontrou import em `server/bin`,
  `server/lib` ou `server/routes`.
- **Evidencia de duplicacao no caminho vivo:** `server/bin/sync_cards.dart`
  ainda importa apenas `../lib/mtg_data_integrity_support.dart`, chama
  `_parseSinceDays` em `:62`, `_getNewSetCodesSinceFromData` em `:141` e
  `_extractCardRow` em `:554`; as copias privadas estao em `:376`, `:413` e
  `:680`. O sync incremental tambem monta inline os dados equivalentes a
  `extractSetCardRow`, `extractOracleIds` e `extractLegalities` em
  `_upsertCardsFromSet`/`_upsertLegalitiesFromSet`.
- **Por que parece nao chamada:** o arquivo publico foi criado para tornar o
  parsing testavel, mas o binario operacional nao usa esses helpers.
- **O que valida:** trocar o CLI real para importar `sync_cards_utils.dart` e
  remover as copias privadas/inline, mantendo `server/test/sync_cards_test.dart`
  como cobertura do mesmo caminho usado em producao.
- **O que falsifica:** chamada/import runtime novo a
  `server/lib/sync_cards_utils.dart` por `server/bin/sync_cards.dart` ou decisao
  documentada de transformar o arquivo em fixture de teste.

#### P2 — Wrappers de `request_trace.dart` seguem sem consumidor externo

- **Funcoes:** `getRequestTrace` e `tryGetRequestId` em
  `server/lib/request_trace.dart:48` e `:51`.
- **Evidencia de ausencia:** busca por `getRequestTrace(` encontrou somente a
  propria definicao e a chamada interna dentro de `tryGetRequestId`; busca por
  `tryGetRequestId(` encontrou somente a propria definicao.
- **Controle positivo:** `RequestTrace` esta vivo: `_middleware.dart` cria e
  injeta o objeto, `auth_middleware.dart` grava `userId`, e rotas como
  `server/routes/trades/index.dart:332`,
  `server/routes/conversations/[id]/messages.dart:249` e
  `server/routes/users/[id]/follow/index.dart:99` leem
  `context.read<RequestTrace>().requestId` diretamente.
- **Por que parece nao chamada:** o modelo/contexto e usado, mas os wrappers
  publicos nao foram adotados pelas rotas.
- **O que valida:** substituir os reads diretos por `getRequestTrace`/
  `tryGetRequestId` onde o fallback for desejado, ou remover os wrappers.
- **O que falsifica:** chamada runtime nova a `getRequestTrace(context)` ou
  `tryGetRequestId(context)` fora de `request_trace.dart`.

#### P2 — Helpers de Commander Reference/MTGTop8/Candidate Quality continuam test-only ou sem chamada

- **Funcoes sem chamada runtime confirmada:**
  `normalizedCommanderReferenceCandidate` em
  `server/lib/ai/commander_reference_profile_support.dart:49`;
  `buildLoreholdReferenceCardStatsFromProfile` em
  `server/lib/ai/commander_reference_card_stats_support.dart:257`;
  `extractMtgTop8FormatCodeFromSourceUrl` em
  `server/lib/meta/mtgtop8_meta_support.dart:139`;
  `buildCandidateQualitySamplePoolSql` em
  `server/lib/ai/candidate_quality_data_support.dart:631`; e
  `summarizeAggressiveOptimizeUtilitySamples` em
  `server/lib/ai/optimize_runtime_support.dart:3326`.
- **Evidencia de ausencia:** busca por chamada em `server/lib`, `server/routes`,
  `server/bin`, `server/test`, `app/lib` e `app/test` encontrou
  `normalizedCommanderReferenceCandidate` somente na definicao. Os demais
  aparecem na definicao e em testes dedicados:
  `server/test/commander_reference_card_stats_support_test.dart:13`,
  `server/test/mtgtop8_meta_support_test.dart:147`,
  `server/test/candidate_quality_data_support_test.dart:123` e
  `server/test/optimize_runtime_support_test.dart:169`.
- **Por que parece nao chamada:** sao APIs publicas exercitadas como unidade
  isolada, mas sem ligacao comprovada ao pipeline runtime atual.
- **O que valida:** conectar cada helper ao respectivo runner/rota/service vivo
  ou rebaixar para helper privado/test fixture quando for somente prova de
  contrato.
- **O que falsifica:** chamada runtime existente fora dos testes acima.

#### P2 — `MLKnowledgeService.recordFeedback` ainda nao alimenta `ml_prompt_feedback`

- **Funcao:** `recordFeedback` em `server/lib/ml_knowledge_service.dart:251`;
  o insert em `ml_prompt_feedback` esta em `:264`.
- **Evidencia de ausencia:** busca por `recordFeedback(` em runtime encontrou
  somente a propria definicao.
- **Controle positivo:** `MLKnowledgeService` e instanciado em
  `server/lib/ai/otimizacao.dart:33` e usado para contexto/recomendacao por
  outros metodos, mas esse caminho nao chama `recordFeedback`.
- **Por que parece nao chamada:** a tabela tem caminho de escrita teorico, mas
  nenhuma rota/job/app aciona feedback de otimizacao.
- **O que valida:** rota/app/job chamar `recordFeedback` com teste de contrato e
  algum consumidor usar `ml_prompt_feedback` para avaliacao ou ajuste.
- **O que falsifica:** chamada runtime a `recordFeedback(...)` fora do service.

#### P3 — API manual de metricas do `PerformanceService` segue sem uso app-facing

- **Funcoes/metodos sem chamador externo confirmado:** `startTrace` em
  `app/lib/core/services/performance_service.dart:110`, `stopTrace` em `:130`,
  `addMetric` em `:200`, `addAttribute` em `:210`, `getLocalStats` em `:220`
  e `printLocalStats` em `:248`.
- **Evidencia de ausencia:** busca por `.startTrace(`, `.stopTrace(`,
  `.addMetric(`, `.addAttribute(`, `.getLocalStats(` e `.printLocalStats(` em
  `app/lib`, `app/test` e `app/integration_test` nao encontrou chamada externa
  para esses metodos.
- **Controles positivos:** a parte automatica esta viva:
  `PerformanceService.instance.init()` roda em `app/lib/main.dart:121`,
  `PerformanceNavigatorObserver` e registrado em `app/lib/main.dart:208`, e o
  observer chama `startScreenTrace`/`stopScreenTrace`. `traceAsync` tambem e
  exercitado pelo smoke `app/integration_test/release_observability_smoke_test.dart:51`.
- **Por que parece nao chamada:** a instrumentacao automatica existe, mas a API
  manual/custom/debug nao foi conectada a fluxos app-facing.
- **O que valida:** usar esses metodos em operacoes app reais ou documentar a
  API como reservada/debug-only com cobertura explicita.
- **O que falsifica:** chamada externa nova a qualquer metodo listado.

#### P3 — Conveniencias EDHREC/cache seguem sem chamador

- **Funcoes:** `EdhrecService.getTopByCategory`,
  `EdhrecService.calculateFitScore`, `EdhrecService.cleanupCache` e
  `EdhrecCommanderData.isHighSynergy` em
  `server/lib/ai/edhrec_service.dart:333`, `:355`, `:363` e `:399`;
  `EndpointCache.clearExpired` em `server/lib/endpoint_cache.dart:32`.
- **Evidencia de ausencia:** busca por chamadas em `server/lib`,
  `server/routes`, `server/bin`, `server/test`, `app/lib` e `app/test`
  encontrou apenas as definicoes para esses cinco simbolos.
- **Controle positivo:** EDHREC nao esta morto inteiro:
  `getHighSynergyCards` e chamado por `server/lib/ai/otimizacao.dart:112`,
  `:120`, `:313` e `:321`.
- **Por que parece nao chamada:** sao conveniencias publicas residuais ou hooks
  de manutencao de cache sem scheduler/rota chamadora.
- **O que valida:** conectar limpeza proativa de cache e uso de fit/category em
  rota/service vivo, ou remover/rebaixar as conveniencias.
- **O que falsifica:** chamada runtime a qualquer simbolo listado.

### Resultado desta revalidacao

Nao surgiu novo P1 com evidencia mais forte que os itens ja conhecidos. O risco
principal desta rotacao continua sendo `sync_cards_utils.dart`: ha um helper
testado que parece prometer compartilhamento, mas o CLI operacional ainda roda
copias privadas. Os demais achados permanecem P2/P3 porque podem representar API
reservada, diagnostico ou contrato experimental, mas hoje nao tem chamador
runtime confirmado.

## Rodada focada: Card semantics — revalidacao 2026-06-05 05:30 UTC

Escopo desta rodada: nomes hardcoded de cartas em codigo runtime, drift entre
`functional_tags`, `semantic_tags_v2` e roles de optimize, e pontos em que
utilidade ainda e inferida por nome ou heuristica local estreita. Produto/runtime
auditado primeiro: `server/lib`, `server/routes` e `app/lib`. Testes, docs,
artefatos e corpus foram usados apenas para separar fixture/exemplo permitido de
logica de produto.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `b9ee4c80`.

### Metodo manual focado

- Leitura dos arquivos pedidos na task, incluindo estes docs, contrato de API,
  manual, classificadores semanticos, candidate quality, optimize route e
  `optimize_request_support.dart`.
- `rg` focado em `server/lib`, `server/routes` e `app/lib` para nomes como
  `Sol Ring`, `Command Tower`, `Thassa's Oracle`, `Isochron Scepter`,
  `Dramatic Reversal`, `Blood Artist`, `Boros Charm`, alem de checks
  `normalizedName ==`, `normalizedName.contains`, `name ==` e `name.contains`.
- `rg` de pipeline para `inferFunctionalCardTags`,
  `inferSemanticCardAnalysisV2`, `summarizeFunctionalTagsForDeck`,
  `classifyOptimizationFunctionalRole`, `semantic_tags_v2`,
  `card_function_tags`, `functional_tags` e `role_delta`.
- Busca ampla no repositorio para classificar aparicoes em docs, testes,
  fixtures, corpus e artefatos sem trata-las automaticamente como bug runtime.

### Resultado desta revalidacao

Nao apareceu uma nova tarefa evidence-backed alem dos achados ja documentados na
rodada de 2026-06-04 05:30 UTC; os riscos principais permanecem abertos neste
checkout.

- **Risk revalidado:** `server/lib/ai/functional_card_tags.dart:219`-`:226`
  ainda marca ramp por `signet`, `talisman`, `sol ring` e `arcane signet`;
  `:700`-`:717`, `:754`-`:780` e `:859`-`:905` ainda usam nomes conhecidos para
  protecao, aristocrats/drain, wincon/combo, payoff e enabler.
- **Risk revalidado:** `server/lib/ai/candidate_quality_data_support.dart:375`-`:379`,
  `:421`-`:428`, `:439`-`:445`, `:472`-`:478`, `:531`-`:542`,
  `:590`-`:605` e `:611`-`:628` ainda aplicam tags, premium bonus ou bracket
  scope por nome.
- **Risk revalidado:** `server/lib/ai/optimize_runtime_support.dart:1296`-`:1345`,
  `:3476`-`:3515` e `:3568`-`:3618` ainda usam listas fixas de staples,
  fallbacks universais e fillers contextuais; `:2133`-`:2148`,
  `:2192`-`:2212`, `:2214`-`:2234` e `:2317`-`:2355` ainda misturam texto com
  nome/preferred names em role/score.
- **Risk revalidado:** `server/lib/ai/rebuild_guided_service.dart:1226`-`:1231`
  classifica ramp por `signet`/`sol ring`/`talisman`; `:1331`-`:1338` e
  `:1404`-`:1411` penalizam/priorizam utility lands por nome.
- **Drift revalidado:** deck analysis carrega `card_function_tags` e
  `semantic_tags_v2` (`server/routes/decks/[id]/analysis/index.dart:80`-`:96`,
  `server/routes/decks/[id]/ai-analysis/index.dart:119`-`:135`) e
  `summarizeFunctionalTagsForDeck` prefere tags persistidas
  (`server/lib/ai/functional_card_tags.dart:432`-`:465`). O optimize context
  carrega `semantic_tags_v2`, mas nao `functional_tags`
  (`server/lib/ai/optimize_request_support.dart:86`-`:107`, `:186`-`:198`,
  `:323`-`:339`), e `server/routes/ai/optimize/index.dart:2062`-`:2099` /
  `:3197`-`:3213` faz o mesmo para additions.
- **Drift revalidado:** `classifyOptimizationFunctionalRole` em
  `server/lib/ai/optimization_functional_roles.dart:55`-`:124` usa
  `semantic_tags_v2` primeiro e oracle/type fallback depois, mas nao le
  `functional_tags`; `OptimizationValidator` e quality gate consomem esse role
  escalar em `server/lib/ai/optimization_validator.dart:265`-`:267` e
  `server/lib/ai/optimization_quality_gate.dart:52`-`:53`. O delta v2 em
  `optimization_functional_roles.dart:292`-`:349` ainda preserva apenas um role
  por carta.
- **Risk se promovidas:** `server/routes/decks/[id]/recommendations/index.dart:110`-`:130`
  recalcula buckets por `oracle_text` local, recomenda `Command Tower`
  diretamente em `:262`-`:267` e usa raridade como proxy em `_findStaples`
  (`:408`-`:438`). `server/routes/ai/weakness-analysis/index.dart:41`-`:60`
  nao carrega `card_function_tags`, `semantic_tags_v2` nem `card_role_scores`;
  `:114`-`:163` reconta utilidade por heuristicas locais e `:206`-`:285`
  retorna listas fixas de nomes. O contrato ainda marca `/ai/weakness-analysis`
  como experimental/not proven em `server/doc/API_CONTRACTS_AND_DATA_MAP.md:286`.

### Classificacao de candidatos permitidos

- **Allowed:** exemplos de UI/import como `1 Sol Ring`, comentarios de contrato
  do resolver, sugestoes de busca do life counter, testes, artifacts, corpus e
  docs historicos. Eles nao decidem optimize, validacao, recomendacao ou score.
- **Allowed with caution:** o seed Lorehold de
  `commander_reference_generate_fallback_support.dart` continua aceitavel apenas
  se tratado como seed/profile versionado, nao como regra global de utilidade.
- **Intentional exception:** `server/lib/edh_bracket_policy.dart` segue como
  excecao por regra externa de bracket/Game Changer; deve permanecer versionado,
  com fonte e teste dedicado.
- **Correcao estreita recomendada:** criar adapter unico que aceite
  `functional_tags`, `semantic_tags_v2`, `oracle_text`, `type_line`,
  `mana_cost` e `cmc`, retornando roles multiplos + `primary_role`; carregar
  `card_function_tags` no optimize; mover excecoes reais de nome para policy ou
  tabela versionada.

## Rodada focada: Classes not used — revalidacao 2026-06-05 03:00 UTC

Escopo desta rodada: somente classes sem uso runtime confirmado. Nao foi feita
auditoria ampla de funcoes sem chamador, imports/ciclos, tabelas PostgreSQL,
duplicacao ou coerencia geral entre modulos fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `5fc3cafb`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor base cobre `server/lib` e
`server/routes`, nao cobre `app/lib` e nao constroi grafo de chamadas. A propria
docstring do script diz que achados de "nao usado" exigem validacao manual com
grep. A execucao reescreveu `STRUCTURE_AUDIT.md` com inventario amplo gerado;
essa mutacao automatica foi descartada para preservar o historico manual,
mantendo aqui somente o resultado numerico do auditor e os achados de classes
revalidados manualmente. O import quebrado reportado
(`server/routes/ai/commander-learning/index.dart` ->
`../../../lib/ai/commander_learned_deck_support.dart`) fica fora desta rotacao
e nao foi tratado como achado de classes.

### Metodo manual focado

- `rg` dos candidatos historicos em `app/lib`, `app/test` e
  `app/integration_test`: `LifeCounterScreen`, `DeckCard`,
  `DeckProgressChip`, `LotusPresentationMode`, `AuthVisualShell`,
  `AuthBrandHeader` e `AuthFormSurface`.
- Busca de wiring vivo: `lifeCounterRoutePath`, `LotusLifeCounterScreen`,
  imports de `deck_card.dart`, imports de `auth_visual_shell.dart` e chamadas
  dos construtores candidatos.
- Varredura auxiliar de 733 declaracoes `class` em `app/lib`, `server/lib` e
  `server/routes`, separando classes com baixa contagem textual e descartando
  manualmente classes construidas por `main.dart`, rotas, services, binarios,
  providers, scanner services ou testes runtime de Lotus.

### Achados revalidados

#### P1 — `LifeCounterScreen` legado segue fora do caminho runtime do app

- **Classe:** `LifeCounterScreen` em
  `app/lib/features/home/life_counter_screen.dart:61`, construtor em `:66`.
- **Rota ativa:** `app/lib/main.dart:282`-`:283` registra
  `lifeCounterRoutePath` com `const LotusLifeCounterScreen()`, importado em
  `app/lib/main.dart:54`.
- **Evidencia de ausencia em runtime app:** busca por `LifeCounterScreen(` em
  `app/lib` encontrou somente o construtor da propria classe. As chamadas reais
  encontradas estao em testes: `app/test/features/home/life_counter_screen_test.dart:36`
  e `app/test/features/home/life_counter_clone_proof_test.dart:277`.
- **Por que parece nao usada:** a tela ainda existe em `app/lib` e tem testes,
  mas o roteamento de produto e a malha viva usam `LotusLifeCounterScreen`.
- **O que valida:** remover a tela legada ou move-la para harness/fixture
  explicitamente documentado, ajustando os testes para nao sugerirem cobertura
  runtime.
- **O que falsifica:** `app/lib` passar a importar e instanciar
  `LifeCounterScreen` em uma rota ou superficie viva.

#### P2 — `DeckCard` permanece testado, mas sem uso confirmado na listagem real

- **Classe:** `DeckCard` em
  `app/lib/features/decks/widgets/deck_card.dart:17`, construtor em `:22`.
- **Evidencia de ausencia em `app/lib`:** busca por import de `deck_card.dart`
  em `app/lib` nao retornou ocorrencias, e busca por `DeckCard(` em `app/lib`
  encontrou somente o construtor.
- **Usos encontrados:** apenas testes importam e instanciam o widget:
  `app/test/features/decks/widgets/deck_card_test.dart:4`/`:9` e
  `app/test/features/decks/widgets/deck_card_overflow_test.dart:4`/`:47`.
- **Controles positivos:** as listagens reais usam widgets locais:
  `_RecentDeckCard` em `app/lib/features/home/home_screen.dart:523`/`:532`,
  `_CommunityDeckCard` em `app/lib/features/community/screens/community_screen.dart:312`/`:736`,
  `_FollowingDeckCard` em `community_screen.dart:515`/`:950`, e
  `_DeckGalleryCard` em `app/lib/features/decks/screens/deck_list_screen.dart:626`/`:1401`.
- **Por que parece nao usada:** ha uma implementacao generica de card de deck,
  mas as superficies ativas usam implementacoes privadas divergentes.
- **O que valida:** reutilizar `DeckCard` na listagem real de decks, ou remover
  `DeckCard` e seus testes se a divergencia local for a decisao de produto.
- **O que falsifica:** import ou chamada `DeckCard(...)` em `app/lib` que a
  busca focada nao encontrou.

#### P2 — `DeckProgressChip` nao tem chamada de construtor confirmada

- **Classe:** `DeckProgressChip` em
  `app/lib/features/decks/widgets/deck_progress_indicator.dart:286`,
  construtor em `:292`.
- **Evidencia de ausencia:** busca por `DeckProgressChip(` em `app/lib`,
  `app/test` e `app/integration_test` encontrou somente o construtor.
- **Controle positivo:** `DeckProgressIndicator`, no mesmo arquivo em
  `app/lib/features/decks/widgets/deck_progress_indicator.dart:14`, segue vivo
  em `app/lib/features/decks/widgets/deck_details_overview_tab.dart:328` e
  `app/lib/features/decks/screens/deck_details_screen.dart:403`.
- **Por que parece nao usada:** o chip compacto parece sobra de uma listagem que
  nao o instancia mais.
- **O que valida:** usar o chip nas listagens ou remover a classe.
- **O que falsifica:** chamada `DeckProgressChip(...)` em `app/lib` ou teste
  runtime que represente uma superficie viva.

#### P2 — `LotusPresentationMode` existe, mas Lotus nao chama `enter()`/`exit()`

- **Classe:** `LotusPresentationMode` em
  `app/lib/features/home/lotus/lotus_presentation_mode.dart:4`.
- **Metodos publicos:** `enter()` em `:15` e `exit()` em `:26`.
- **Evidencia de ausencia:** busca por `lotus_presentation_mode.dart`,
  `LotusPresentationMode.` e `LotusPresentationMode` em `app/lib`, `app/test` e
  `app/integration_test` encontrou somente a declaracao e o construtor privado
  no proprio arquivo.
- **Por que parece nao usada:** o modo de apresentacao/sistema imersivo foi
  isolado em helper, mas a tela Lotus ativa nao importa nem chama esse helper.
- **O que valida:** chamar `LotusPresentationMode.enter()`/`exit()` no lifecycle
  correto da tela viva, com restauracao em dispose, ou remover o helper se a
  decisao atual for nao forcar orientacao/overlays.
- **O que falsifica:** import do arquivo e chamadas `LotusPresentationMode.*`
  em `app/lib` ou harness runtime que prove uso ativo.

#### P2 — Shell visual de auth aparece isolado e sem consumidor

- **Classes:** `AuthVisualShell` em
  `app/lib/features/auth/widgets/auth_visual_shell.dart:5`,
  `AuthBrandHeader` em `:105`, e `AuthFormSurface` em `:196`.
- **Evidencia de ausencia:** busca por `auth_visual_shell.dart`,
  `AuthVisualShell(`, `AuthBrandHeader(` e `AuthFormSurface(` em `app/lib`,
  `app/test` e `app/integration_test` encontrou somente os construtores no
  proprio arquivo.
- **Por que parece nao usada:** login/registro/splash foram redesenhados em
  arquivos de tela, mas estes widgets compartilhados nao foram conectados.
- **O que valida:** usar o shell nas telas de auth ou remover o arquivo se o
  layout atual ficou inline por decisao.
- **O que falsifica:** import de `auth_visual_shell.dart` e construcao das
  classes por `login_screen.dart`, `register_screen.dart`, `splash_screen.dart`
  ou teste runtime representativo.

### Controles positivos e candidatos descartados

- `LotusLifeCounterScreen` foi descartado como classe sem uso: `app/lib/main.dart:283`
  instancia a tela no roteamento vivo e ha ampla cobertura em `app/test` e
  `app/integration_test`.
- Classes de observabilidade com baixa contagem textual foram descartadas:
  `PerformanceNavigatorObserver` e `AppObservabilityNavigatorObserver` sao
  instanciadas em `app/lib/main.dart:208`-`:209`.
- Candidatos backend com baixa contagem foram descartados quando havia chamada
  runtime clara, por exemplo `DistributedRateLimiter` em
  `server/lib/rate_limit_middleware.dart:207`, `BattleSimulator` em
  `server/routes/ai/simulate/index.dart:63`, `MatchupAnalyzer` em
  `server/routes/ai/simulate/index.dart:99` e `RebuildGuidedService` em
  `server/routes/ai/rebuild/index.dart:173`.

## Rodada focada: Coherence between modules `server/lib` ↔ `server/routes` ↔ `app/lib` — revalidacao 2026-06-04 23:00 UTC

Escopo desta rodada: somente coerencia entre contratos app-facing em `app/lib`,
rotas em `server/routes` e helpers em `server/lib`. Nao foi feita auditoria
ampla de classes sem uso, funcoes sem chamada, imports/ciclos, tabelas
PostgreSQL ou duplicacao fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `5243686c`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor textual cobre principalmente inventario
de `server/lib` e `server/routes`, nao cruza consumidores reais em `app/lib` com
contratos de rota e tambem emite achados amplos fora do foco. A execucao
reescreveu `STRUCTURE_AUDIT.md` com inventario gerado; essa alteracao foi
descartada para preservar o historico manual, mantendo abaixo somente achados
focados e validados. O import quebrado reportado pelo auditor base e o mesmo ja
documentado na rodada de imports (`server/routes/ai/commander-learning/index.dart:4`).

### Metodo manual focado

- `rg` em `app/lib`, `server/routes` e `server/lib` para endpoints app-facing de
  decks/IA e funil de ativacao.
- Comparacao entre chamadas do app, SQL real das rotas/helpers e contrato em
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md`.
- Triagem de controles positivos: rotas consumidas pelo app que fazem gate por
  `deck_id + user_id` antes de carregar cartas.

### Achados revalidados

#### P1 — `POST /ai/optimize` segue app-facing, mas o helper de contexto nao recebe owner

- **Consumidor app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:56`
  envia `POST /ai/optimize` com `deck_id`; `deck_provider.dart:533`-`:579`
  expoe o fluxo como operacao do usuario autenticado.
- **Rota:** `server/routes/ai/optimize/index.dart:400`-`:406` tenta ler
  `userId`, e `:457`-`:464` cria job async com esse `userId`.
- **Incoerencia:** a mesma rota chama
  `optimize_request.loadOptimizeDeckContext(...)` em
  `server/routes/ai/optimize/index.dart:545`-`:558` sem passar `userId`.
- **Helper afetado:** `server/lib/ai/optimize_request_support.dart:53`-`:62`
  declara `loadOptimizeDeckContext` sem parametro de usuario; `:63`-`:73`
  consulta `SELECT name, format FROM decks WHERE id = @id`; `:87`-`:110` e
  `:114`-`:137` carregam cartas com `WHERE dc.deck_id = @id`.
- **Por que parece incoerente:** a borda da rota e app-facing/autenticada, mas o
  ownership nao atravessa a fronteira `server/routes` -> `server/lib`; qualquer
  decisao de permissao fica ausente no ponto que efetivamente carrega deck e
  cartas.
- **O que valida:** adicionar `userId` obrigatorio ao helper, filtrar `decks`
  por `id + user_id`, garantir que a consulta de cartas derive de deck ja
  autorizado e criar teste owner vs non-owner para sync e async.
- **O que falsifica:** provar por middleware/policy externa que `deck_id` ja foi
  validado como pertencente ao usuario antes de chamar o helper, com teste de
  rota cobrindo deck de outro usuario.

#### P1 — `POST /ai/archetypes` e chamado pelo app, mas carrega deck/cartas so por id

- **Consumidor app:** `app/lib/features/decks/providers/deck_provider_support_mutation.dart:168`-`:173`
  envia `POST /ai/archetypes` com `deck_id`; `deck_provider.dart:528`-`:530`
  expoe `fetchOptimizationOptions`.
- **Rota:** `server/routes/ai/archetypes/index.dart:27`-`:32` exige
  `deck_id`, mas `:39`-`:42` busca `SELECT name, format FROM decks WHERE id = @id`
  e `:54`-`:60` carrega cartas por `WHERE dc.deck_id = @id`.
- **Contrato:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md:282` lista o endpoint
  como `experimental` e consumidor `deck_provider_support_mutation.dart`, mas
  nao explicita regra publica para deck alheio.
- **Por que parece incoerente:** a UI usa a rota como opcao de otimizacao de
  deck privado do usuario, mas o backend nao aplica o mesmo owner-scope das rotas
  de deck estaveis.
- **O que valida:** filtrar o deck por `id + user_id`, retornar 404 para deck de
  outro usuario e cobrir em `ai_archetypes_flow_test`.
- **O que falsifica:** documentar e testar contrato publico explicito, por
  exemplo apenas para `decks.is_public = true`, sem expor decks privados.

#### P1 — Polling de optimize ainda aceita job com `user_id = NULL`

- **Consumidor app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:190`-`:211`
  faz polling em `/ai/optimize/jobs/$jobId` e trata `completed` como resultado
  do fluxo de deck do usuario.
- **Rota:** `server/routes/ai/optimize/jobs/[id].dart:26`-`:28` le `userId` e
  busca o job; `:39`-`:47` bloqueia somente quando
  `job.userId != null && job.userId != userId`; `:49` retorna `job.toJson()`.
- **Por que parece incoerente:** jobs app-facing criados por optimize carregam
  dono quando possivel, mas a rota preserva legibilidade de jobs sem dono. Isso
  enfraquece a regra de ownership justamente no endpoint de polling usado pelo
  app.
- **O que valida:** tratar `job.userId == null` como 404 para endpoint
  app-facing, ou separar um endpoint interno com token proprio para jobs sem
  dono, e adicionar teste de job nulo/non-owner.
- **O que falsifica:** provar que jobs sem `user_id` nunca podem conter payload
  de deck user-facing nem ser acessados pelo endpoint mobile.

#### P2 — Telemetria de rebuild e emitida pelo app, rejeitada pela allow-list e documentada como `not proven`

- **Consumidores app reais:** `app/lib/features/home/onboarding_core_flow_screen.dart:32`-`:70`
  chama `ActivationFunnelService.instance.track(...)` para eventos de onboarding;
  `app/lib/features/decks/providers/deck_provider.dart:397`-`:409` emite
  `deck_created`, `:567`-`:577` emite `deck_optimized`, e `:603`-`:615` emite
  `deck_rebuild_created`.
- **Servico app:** `app/lib/core/services/activation_funnel_service.dart:17`-`:23`
  envia `POST /users/me/activation-events`; `:24`-`:26` engole falhas para nao
  quebrar o fluxo principal.
- **Rota:** `server/routes/users/me/activation-events/index.dart:10`-`:18`
  permite `core_flow_started`, `format_selected`, `base_choice_generate`,
  `base_choice_import`, `deck_created`, `deck_optimized` e
  `onboarding_completed`; `deck_rebuild_created` nao esta na lista. A validacao
  em `:46`-`:48` retorna `event_name inválido`.
- **Contrato:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md:61` ainda lista
  `POST /users/me/activation-events` como `internal`, consumidor
  `onboarding/activation code not proven` e evidencia `Not proven`, apesar dos
  consumidores reais em `app/lib`.
- **Por que parece incoerente:** parte do funil de rebuild guiado e perdida
  silenciosamente, e o contrato nao reflete que o endpoint ja e usado pelo app.
- **O que valida:** adicionar `deck_rebuild_created` a `_allowedEvents` com
  teste, ou remover a emissao do app; atualizar o contrato para listar
  consumidores reais e status adequado.
- **O que falsifica:** remover todos os consumidores app do endpoint ou provar
  que `deck_rebuild_created` nao deve ser um evento aceito.

### Controles positivos e candidatos descartados

- `POST /ai/rebuild` foi descartado como incoerente: o app chama a rota em
  `app/lib/features/decks/providers/deck_provider_support_ai.dart:143`-`:188`,
  e `server/routes/ai/rebuild/index.dart:61`-`:82` busca o deck com
  `WHERE d.id = @deckId AND d.user_id = @userId` antes de carregar cartas.
- `GET /decks/:id/analysis` foi descartado como incoerente: o app chama em
  `app/lib/features/decks/providers/deck_provider_support_fetch.dart:135`-`:140`,
  e `server/routes/decks/[id]/analysis/index.dart:21`-`:31` valida
  `deckId + userId` antes de consultar `deck_cards`.
- `POST /decks/:id/ai-analysis` foi descartado como incoerente: o app chama em
  `app/lib/features/decks/providers/deck_provider_support_fetch.dart:273`-`:281`,
  e `server/routes/decks/[id]/ai-analysis/index.dart:34`-`:47` valida
  `deckId + userId` antes de carregar cartas.
- A varredura de eventos encontrou os nomes de onboarding, `deck_created` e
  `deck_optimized` alinhados com `_allowedEvents`; `deck_rebuild_created` foi o
  unico nome emitido pelo app e rejeitado pela allow-list.
- `/decks/:id/recommendations`, `/decks/:id/simulate`,
  `/ai/simulate-matchup` e `/ai/weakness-analysis` continuam candidatos de
  owner-scope antes de promocao, mas nao foram promovidos como incoerencia
  app-facing desta rodada porque a busca focada em `app/lib` nao encontrou
  consumidor atual.

## Rodada focada: PostgreSQL tables not used — revalidacao 2026-06-04 15:00 UTC

Escopo desta rodada: somente tabelas PostgreSQL sem consumidor claro,
write-only ou com consumo parcial. Nao foi feita auditoria ampla de classes,
funcoes, imports/ciclos, duplicacao ou coerencia entre modulos fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `92281194`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor e textual, cobre `server/lib` e
`server/routes` para o inventario principal, e lista tabelas referenciadas sem
distinguir consumidor produtivo, escrita, CTE, tabela temporaria ou tabela raw de
lineage. A execucao tambem reescreve `STRUCTURE_AUDIT.md` com inventario amplo
fora do foco; essa alteracao gerada foi descartada para preservar o historico
manual, mantendo abaixo somente achados focados e validados.

### Metodo manual focado

- `rg` direto para as tabelas candidatas historicas em `server/lib`,
  `server/routes`, `server/bin`, `server/test`, `server/database_setup.sql` e
  `app/lib`.
- Varredura auxiliar de operacoes SQL (`CREATE TABLE`, `INSERT INTO`, `FROM`,
  `JOIN`, `UPDATE`, `DELETE FROM`) em `server/lib`, `server/routes` e
  `server/bin`, seguida de triagem manual para separar tabelas reais de CTEs,
  temp tables, aliases e comentarios.
- Consulta ao contrato app-facing em `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
  para validar se a tabela aparece como dependency declarada sem consumidor
  correspondente.

### Achados revalidados

#### P2 — `deck_matchups` continua write-only no produto atual

- **Tabela:** `deck_matchups`.
- **DDL encontrado:** `server/database_setup.sql:162`.
- **Escrita encontrada:** `server/routes/ai/simulate-matchup/index.dart:360`
  faz `INSERT INTO deck_matchups (...) ON CONFLICT (...) DO UPDATE`.
- **Leitura encontrada:** nenhuma ocorrencia de `SELECT ... FROM deck_matchups`,
  `JOIN deck_matchups`, `UPDATE deck_matchups` ou `DELETE FROM deck_matchups`
  em `server/lib`, `server/routes`, `server/bin`, `server/test` ou `app/lib`;
  `server/bin/update_schema.dart:16` apenas derruba a tabela em script legado e
  `server/bin/verify_schema.dart:78` so verifica schema esperado.
- **Por que parece nao usada:** a rota calcula `winRate`/analise em memoria e
  retorna a resposta imediatamente; os campos persistidos
  `deck_matchups.win_rate` e `deck_matchups.notes` nao alimentam cache,
  historico, ranking, UI ou nova simulacao.
- **O que valida:** criar consumidor real de `deck_matchups`, por exemplo
  historico/cached matchup, dashboard ou reuso na simulacao, com contrato e
  teste.
- **O que falsifica:** encontrar `SELECT`/`JOIN` real sobre `deck_matchups` em
  rota/lib/job consumido pelo produto ou por rotina operacional documentada.

#### P2 — `deck_weakness_reports` acumula registros sem fluxo de leitura ou resolucao

- **Tabela:** `deck_weakness_reports`.
- **DDL encontrado:** `server/database_setup.sql:363` e migration redundante em
  `server/bin/migrate_create_missing_tables.dart:97`.
- **Escrita encontrada:** `server/routes/ai/weakness-analysis/index.dart:374`
  faz `INSERT INTO deck_weakness_reports (...) ON CONFLICT DO NOTHING`.
- **Leitura encontrada:** nenhuma ocorrencia de `SELECT ... FROM
  deck_weakness_reports`, `JOIN deck_weakness_reports`, `UPDATE
  deck_weakness_reports` ou `DELETE FROM deck_weakness_reports` em `server/lib`,
  `server/routes`, `server/bin`, `server/test` ou `app/lib`; as demais
  ocorrencias sao indices/schema em `database_setup.sql`, migration e
  `verify_schema`.
- **Por que parece nao usada:** a rota retorna as fraquezas calculadas na propria
  chamada, mas a tabela persistida nao e consultada depois para historico,
  deduplicacao, status de resolucao, trends ou feedback de melhoria.
- **O que valida:** endpoint/job que leia reports por deck, marque resolucao ou
  use a serie historica para melhorar recomendacoes.
- **O que falsifica:** consumidor runtime/documentado lendo
  `deck_weakness_reports` fora da chamada que insere.

#### P3 — `ml_prompt_feedback` tem helper de insert sem chamador e apenas contador operacional

- **Tabela:** `ml_prompt_feedback`.
- **DDL encontrado:** `server/bin/migrate_ml_knowledge.dart:159`.
- **Escrita potencial:** `server/lib/ml_knowledge_service.dart:251` define
  `recordFeedback(...)` e `:264` faz `INSERT INTO ml_prompt_feedback (...)`.
- **Evidencia de ausencia de chamador:** busca por `recordFeedback(` em
  `server` e `app` encontrou somente a propria definicao; nao ha rota/app/job
  chamando o helper.
- **Leitura encontrada:** `server/routes/ai/ml-status/index.dart:98` executa
  apenas `SELECT COUNT(*)::int as c FROM ml_prompt_feedback`.
- **Por que e uso insuficiente:** a tabela tem intencao de feedback de usuario
  para refinar prompts, mas nesta branch nao ha ingestao real nem consumo do
  conteudo; o status conta linhas se elas existirem, sem fechar loop de produto.
- **O que valida:** rota/app/job de feedback chamar `recordFeedback` e outro
  fluxo consumir esse feedback para prompt/modelo, com teste de contrato.
- **O que falsifica:** chamada runtime nova a `recordFeedback(...)` ou query que
  use `cards_accepted`, `cards_rejected`, `effectiveness_score` ou
  `user_comment`.

#### P3 — Raw corpus de Commander Reference e persistido, mas o produto le somente o agregado

- **Tabelas:** `commander_reference_decks` e
  `commander_reference_deck_cards`.
- **DDL encontrado:** `server/lib/ai/commander_reference_deck_corpus_support.dart:1177`
  e `:1200`.
- **Escritas encontradas:** `server/lib/ai/commander_reference_deck_corpus_support.dart:1245`
  insere em `commander_reference_decks`; `:1329` apaga cards antigos por
  `source_deck_key`; `:1345` insere em `commander_reference_deck_cards`.
- **Leitura encontrada:** nenhuma ocorrencia de `FROM/JOIN
  commander_reference_decks` ou `FROM/JOIN commander_reference_deck_cards` em
  `server/lib`, `server/routes`, `server/bin`, `server/test` ou `app/lib`. O
  caminho consumido pelo produto le `commander_reference_deck_analysis` em
  `server/lib/ai/commander_reference_deck_corpus_support.dart:389`.
- **Por que e consumo parcial, nao necessariamente lixo:** as raw tables podem
  ser lineage/audit do corpus, e o agregado `commander_reference_deck_analysis`
  tem escrita em `:1394` e leitura real em `:389`. O problema e que o contrato
  atual (`server/doc/API_CONTRACTS_AND_DATA_MAP.md:167`) lista as raw tables como
  fonte de `POST /ai/generate`, apesar de o runtime desta branch consumir apenas
  o agregado.
- **O que valida:** documentar as raw tables como lineage/audit com politica de
  retencao, ou adicionar job/rota que leia raw decks/cards para reprocessamento,
  debug ou explicabilidade.
- **O que falsifica:** `SELECT`/`JOIN` real sobre as tabelas raw em rota/lib/job
  runtime, ou ajuste contratual que deixe claro que o app-facing path depende
  somente de `commander_reference_deck_analysis`.

### Controles positivos e candidatos descartados

- A varredura auxiliar de operacoes SQL confirmou leitores runtime ou runners
  dedicados para as tabelas candidatas historicamente ruidosas:
  `battle_simulations`, `format_staples`, `archetype_counters`,
  `archetype_patterns`, `synergy_packages`, `activation_funnel_events`,
  `ai_user_preferences`, `card_function_tags`, `card_role_scores`,
  `card_semantic_tags_v2`, `commander_card_synergy`,
  `optimize_rejection_penalties`, `optimization_analysis_logs`,
  `ai_optimize_cache`, `ai_optimize_jobs` e `ai_generate_jobs`.
- `commander_reference_deck_analysis` foi descartada como nao usada porque tem
  escrita em `server/lib/ai/commander_reference_deck_corpus_support.dart:1394`
  e leitura real em `:389`.
- `deck_learning_events` e `commander_card_usage` aparecem em docs historicos,
  mas nao aparecem em `server/database_setup.sql`, `server/lib`,
  `server/routes` ou `server/bin` neste checkout; nao foram promovidas como
  tabelas PostgreSQL atuais desta branch.
- A varredura regex produz falsos positivos para CTEs, tabelas temporarias,
  aliases e comentarios (`SET`, `UNIQUE`, `tmp_*`, `filtered_sets`, `latest`,
  etc.); esses itens nao foram tratados como tabelas PostgreSQL de produto.


## Rodada focada: Broken imports and circular dependencies — revalidacao 2026-06-04 11:00 UTC

Escopo desta rodada: somente imports quebrados e ciclos de dependencia local.
Nao foi feita auditoria ampla de classes sem uso, funcoes sem chamada, tabelas
PostgreSQL, duplicacao ou coerencia entre modulos fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `aa6d3216`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor textual cobre apenas `server/lib` e
`server/routes`, nao cobre `app/lib` nem `server/bin`, e tambem emite inventario
amplo fora do foco. A execucao reescreveu `STRUCTURE_AUDIT.md` com esse
inventario; a alteracao gerada foi descartada para preservar o historico manual,
mantendo abaixo somente achados focados e validados. O achado util do auditor
base foi preservado: `server/routes/ai/commander-learning/index.dart:4` importa
um arquivo ausente.

### Metodo manual focado

- Resolver local de imports para 424 arquivos Dart em `app/lib`, `server/lib`,
  `server/routes` e `server/bin`, tratando imports relativos a partir do arquivo
  origem e imports locais `package:manaloom/...`, `package:server/...` e
  `package:ai/...`.
- Tarjan/SCC sobre o grafo de imports locais gerado pela mesma varredura.
- `cd server && dart analyze routes/ai/commander-learning/index.dart bin/local_test_server.dart`.
- `cd app && flutter analyze --no-pub --no-fatal-infos ...` nos quatro arquivos
  app relacionados; resultado nao conclusivo porque `app/.dart_tool/package_config.json`
  esta ausente e o analyzer falhou primeiro em pacotes Flutter/provider.

### Achados revalidados

#### P1 — Rota `commander-learning` importa suporte inexistente

- **Import quebrado:** `server/routes/ai/commander-learning/index.dart:4`
  importa `../../../lib/ai/commander_learned_deck_support.dart`.
- **Alvo resolvido:** `server/lib/ai/commander_learned_deck_support.dart`.
- **Evidencia de ausencia:** `ls server/lib/ai/commander_learned_deck_support.dart`
  retornou `No such file or directory`; `ls server/lib/ai | rg 'commander_learned|learn'`
  nao encontrou arquivo equivalente.
- **Impacto confirmado por analyzer:** `cd server && dart analyze
  routes/ai/commander-learning/index.dart bin/local_test_server.dart` reportou
  `uri_does_not_exist` nessa linha e cascata de erros para
  `CommanderLearnedDeckInput` em `:61`, `:105`, `:141`, `:146`, `:169`,
  `:248`, `:265`, `:283` e `:305`.
- **Por que parece quebrado:** a rota depende do tipo
  `CommanderLearnedDeckInput` e de `learnedDeck.cards`, mas a biblioteca que
  deveria defini-los nao existe neste checkout.
- **O que valida:** restaurar/criar `server/lib/ai/commander_learned_deck_support.dart`
  com o contrato esperado e rerodar `dart analyze` no arquivo.
- **O que falsifica:** encontrar outro arquivo runtime que defina e exporte
  `CommanderLearnedDeckInput` e ajustar o import para esse alvo existente.

#### P1 — Entry point local de teste continua dependente de artefato gerado ausente

- **Import quebrado:** `server/bin/local_test_server.dart:3` importa
  `../.dart_frog/server.dart` como `generated`.
- **Alvo resolvido:** `server/.dart_frog/server.dart`.
- **Evidencia de ausencia:** `ls server/.dart_frog/server.dart` retornou
  `No such file or directory`.
- **Impacto confirmado por analyzer:** o mesmo `dart analyze` reportou
  `uri_does_not_exist` em `server/bin/local_test_server.dart:3`.
- **Por que parece quebrado:** o binario e versionado como bootstrap local, mas
  importa estaticamente um artefato gerado que nao existe em clone limpo desta
  branch.
- **O que valida:** gerar/versionar o bootstrap esperado antes do analyze local,
  ou alterar o launcher para um contrato que nao dependa de import estatico para
  `.dart_frog/server.dart` ausente.
- **O que falsifica:** `server/.dart_frog/server.dart` existir no checkout antes
  de analisar/executar `bin/local_test_server.dart`.

#### P2 — Dois imports relativos do app ainda escapam de `app/lib`

- **Import quebrado:** `app/lib/features/decks/widgets/deck_analysis_tab.dart:5`
  importa `../../../../core/utils/mana_helper.dart`.
- **Alvo resolvido:** `app/core/utils/mana_helper.dart`.
- **Arquivo existente correto:** `app/lib/core/utils/mana_helper.dart`.
- **Import quebrado:** `app/lib/features/home/life_counter_screen.dart:7`
  importa `../../../core/theme/app_theme.dart`.
- **Alvo resolvido:** `app/core/theme/app_theme.dart`.
- **Arquivo existente correto:** `app/lib/core/theme/app_theme.dart`.
- **Evidencia de limitacao do analyzer:** `flutter analyze --no-pub` nos arquivos
  app nao foi conclusivo neste checkout porque `app/.dart_tool/package_config.json`
  esta ausente; o analyzer falhou primeiro em `package:flutter/...` e
  `package:provider/...`.
- **Por que parecem quebrados:** ambos os imports usam `../` demais e saem de
  `app/lib`; a varredura local resolve o caminho real a partir do arquivo origem.
- **O que valida:** trocar para imports que resolvam dentro de `app/lib`
  (`../../../core/utils/...` no primeiro caso e `../../core/theme/...` no
  segundo, ou `package:manaloom/...`) e rerodar `flutter analyze` com dependencias
  restauradas.
- **O que falsifica:** `app/core/utils/mana_helper.dart` e
  `app/core/theme/app_theme.dart` passarem a existir como fontes validas.

#### P2 — Ciclo local entre detalhe de deck publico e perfil de usuario

- **Ciclo encontrado:** `app/lib/features/community/screens/community_deck_detail_screen.dart`
  <-> `app/lib/features/social/screens/user_profile_screen.dart`.
- **Aresta A:** `community_deck_detail_screen.dart:8` importa
  `../../social/screens/user_profile_screen.dart`; o tap no owner cria
  `UserProfileScreen` em `:209`-`:216`.
- **Aresta B:** `user_profile_screen.dart:7` importa
  `../../community/screens/community_deck_detail_screen.dart`; a lista de decks
  cria `CommunityDeckDetailScreen` em `:466`-`:470`.
- **Por que parece ciclo real:** as duas telas importam e instanciam uma a outra
  diretamente via `Navigator.push`, criando SCC de 2 arquivos no grafo de imports.
- **O que valida:** extrair navegacao para rota nomeada/router/factory comum ou
  widget intermediario sem import cruzado, mantendo os dois fluxos de navegação
  cobertos por teste.
- **O que falsifica:** remover uma das importacoes diretas ou provar que um dos
  arquivos nao participa mais do build/runtime.

### Controles positivos e candidatos descartados

- A varredura focada encontrou 4 imports locais quebrados e 1 SCC em 424 arquivos
  Dart. Nenhum outro ciclo local foi encontrado em `app/lib`, `server/lib`,
  `server/routes` e `server/bin`.
- O auditor base apontou somente o import quebrado de `commander-learning`
  porque seu escopo nao inclui `app/lib` nem `server/bin`.
- Imports externos (`dart:*`, Flutter, Dart Frog, Postgres, Provider etc.) nao
  foram promovidos a achado por esta varredura textual; dependem de
  package_config/pubspec e analyzer do pacote.
- O app analyzer nao foi usado como prova de inexistencia dos imports locais
  porque o ambiente atual esta sem `app/.dart_tool/package_config.json`.


## Rodada focada: Functions not called — revalidacao 2026-06-04 07:00 UTC

Escopo desta rodada: somente funcoes/metodos publicos ou wrappers expostos sem
chamador runtime confirmado. Nao foi feita auditoria ampla de classes, imports,
tabelas PostgreSQL, duplicacao ou coerencia entre modulos fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `6cdda72f`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor textual nao compila codigo nem constroi
grafo de chamadas; a docstring do script tambem avisa que achados de "nao usado"
exigem validacao manual com grep. A execucao continua produzindo inventario amplo
fora do foco e pode duplicar historico manual quando reescreve
`STRUCTURE_AUDIT.md`; nesta atualizacao o bloco gerado redundante foi removido
para preservar a legibilidade, mantendo abaixo somente achados manuais com
evidencia de chamada/ausencia.

### Metodo manual focado

- `rg -n "sync_cards_utils|\bextractCardRow\b|\bextractSetCardRow\b|\bparseSinceDays\b|\bextractOracleIds\b|\bextractLegalities\b|getNewSetCodesSinceFromData" server app --glob '*.dart'`.
- `rg -n "\bgetRequestTrace\b|\btryGetRequestId\b|context\.read<RequestTrace>\(\)" server app --glob '*.dart'`.
- `rg -n "\bnormalizedCommanderReferenceCandidate\b|\bbuildLoreholdReferenceCardStatsFromProfile\b|\bextractMtgTop8FormatCodeFromSourceUrl\b|\bbuildCommanderReferenceCardStatsFromProfile\b|\bextractMtgTop8EventIdFromSourceUrl\b" server app --glob '*.dart'`.
- `rg -n "\bbuildCandidateQualitySamplePoolSql\b|\bsummarizeAggressiveOptimizeUtilitySamples\b|\brecordFeedback\b|\bMLKnowledgeService\b" server app --glob '*.dart'`.
- `rg -n "\b(startTrace|stopTrace|traceAsync|addMetric|addAttribute|getLocalStats|printLocalStats|PerformanceNavigatorObserver|startScreenTrace|stopScreenTrace)\b" app/lib app/test app/integration_test --glob '*.dart'`.
- Varredura auxiliar de baixa ocorrencia em `server/lib`, `server/routes`,
  `server/bin` e `app/lib`, seguida de validacao manual para descartar
  definicoes chamadas por rotas, services, bins ou observers.

### Achados revalidados

#### P1 — `sync_cards_utils.dart` segue test-only enquanto o CLI real duplica a logica

- **Funcoes:** `extractCardRow`, `getNewSetCodesSinceFromData`,
  `parseSinceDays`, `extractSetCardRow`, `extractOracleIds` e
  `extractLegalities` em `server/lib/sync_cards_utils.dart:16`, `:82`,
  `:102`, `:116`, `:161` e `:172`.
- **Evidencia de ausencia runtime:** busca por `sync_cards_utils` em Dart
  encontrou apenas `server/test/sync_cards_test.dart:3` importando o arquivo.
  `server/bin/sync_cards.dart` nao importa essa biblioteca.
- **Controle positivo:** o CLI operacional usa copias privadas/inline:
  `_parseSinceDays` em `server/bin/sync_cards.dart:376`,
  `_getNewSetCodesSinceFromData` em `:413`, chamada de
  `_extractCardRow` em `:554` e definicao em `:680`, coleta de oracle IDs
  em `:807`-`:813`, e legalidades inline em `:834`-`:837`.
- **Por que parece nao chamada:** os testes validam a biblioteca publica, mas o
  caminho que sincroniza MTGJSON no produto nao usa essa biblioteca.
- **O que valida:** importar `sync_cards_utils.dart` no CLI real e remover as
  copias privadas/inline, ou declarar/remover o arquivo como harness legado.
- **O que falsifica:** `rg "sync_cards_utils" server/bin server/lib server/routes`
  encontrar import runtime real.

#### P2 — Wrappers de `RequestTrace` continuam sem consumidor direto

- **Funcoes:** `getRequestTrace` e `tryGetRequestId` em
  `server/lib/request_trace.dart:48` e `:51`.
- **Evidencia de ausencia:** `getRequestTrace` aparece somente na propria
  definicao e dentro de `tryGetRequestId`; `tryGetRequestId` aparece somente
  na propria definicao.
- **Controle positivo:** consumidores reais acessam `RequestTrace` diretamente,
  por exemplo `server/lib/auth_middleware.dart:57`,
  `server/lib/observability.dart:225`, `server/routes/trades/index.dart:332`,
  `server/routes/trades/[id]/messages.dart:230`,
  `server/routes/users/[id]/follow/index.dart:99` e
  `server/routes/conversations/[id]/messages.dart:249`.
- **Por que parece nao chamada:** a API publica promete fallback seguro, mas as
  rotas usam leituras diretas ou wrappers privados locais.
- **O que valida:** substituir os reads diretos pelos wrappers quando o fallback
  for desejado, ou remover os wrappers se a leitura direta for o contrato.
- **O que falsifica:** chamada runtime a `getRequestTrace(context)` ou
  `tryGetRequestId(context)` fora de `request_trace.dart`.

#### P2 — Wrappers especificos de Commander Reference/MTGTop8 seguem test-only ou sem chamada

- **Funcoes:** `normalizedCommanderReferenceCandidate` em
  `server/lib/ai/commander_reference_profile_support.dart:49`,
  `buildLoreholdReferenceCardStatsFromProfile` em
  `server/lib/ai/commander_reference_card_stats_support.dart:257` e
  `extractMtgTop8FormatCodeFromSourceUrl` em
  `server/lib/meta/mtgtop8_meta_support.dart:139`.
- **Evidencia de ausencia:** `normalizedCommanderReferenceCandidate` aparece
  apenas na propria definicao; `buildLoreholdReferenceCardStatsFromProfile`
  aparece apenas na propria definicao e em
  `server/test/commander_reference_card_stats_support_test.dart:13`;
  `extractMtgTop8FormatCodeFromSourceUrl` aparece apenas na propria definicao e
  em `server/test/mtgtop8_meta_support_test.dart:147`.
- **Controle positivo:** o runtime usa caminhos vizinhos/genericos:
  `buildCommanderReferenceCardStatsFromProfile` e chamado no mesmo modulo em
  `server/lib/ai/commander_reference_card_stats_support.dart:368`, e
  `server/bin/repair_mtgtop8_meta_history.dart:59` usa
  `extractMtgTop8EventIdFromSourceUrl`, nao o helper de format code.
- **Por que parece nao chamada:** os wrappers ficaram como conveniencias
  especificas de teste enquanto o produto usa a funcao generica ou outro campo.
- **O que valida:** ligar os wrappers a runners/rotas reais ou remover os
  wrappers especificos e ajustar testes para o helper generico.
- **O que falsifica:** chamada runtime nova aos tres simbolos fora de
  `server/test`.

#### P2 — Helpers de sample/diagnostic de optimize permanecem test-only

- **Funcoes:** `buildCandidateQualitySamplePoolSql` em
  `server/lib/ai/candidate_quality_data_support.dart:631` e
  `summarizeAggressiveOptimizeUtilitySamples` em
  `server/lib/ai/optimize_runtime_support.dart:3326`.
- **Evidencia de ausencia:** busca focada encontrou
  `buildCandidateQualitySamplePoolSql` somente na definicao e em
  `server/test/candidate_quality_data_support_test.dart:123`; encontrou
  `summarizeAggressiveOptimizeUtilitySamples` somente na definicao e em
  `server/test/optimize_runtime_support_test.dart:169`.
- **Por que parece nao chamada:** os testes validam SQL/resumo de amostras, mas
  nenhum runner, rota ou service runtime consome esses helpers nesta branch.
- **O que valida:** runner operacional chamar os helpers ao construir pool ou
  resumo de amostras agressivas.
- **O que falsifica:** chamada runtime em `server/bin`, `server/lib` ou
  `server/routes` fora das suites de teste.

#### P2 — `MLKnowledgeService.recordFeedback` ainda nao alimenta `ml_prompt_feedback`

- **Funcao:** `recordFeedback` em `server/lib/ml_knowledge_service.dart:251`.
- **Evidencia de ausencia:** busca por `recordFeedback(` encontrou somente a
  propria definicao. `MLKnowledgeService` e instanciado em
  `server/lib/ai/otimizacao.dart:33`, e esse fluxo usa o service para contexto
  de IA, mas nao chama `recordFeedback`.
- **Por que parece nao chamada:** o insert em `ml_prompt_feedback` existe em
  `server/lib/ml_knowledge_service.dart:262`-`:284`, mas nenhuma rota, job ou
  app action aciona essa escrita.
- **O que valida:** rota/app/job de feedback chamar `recordFeedback` com teste
  de contrato e consumo posterior do feedback.
- **O que falsifica:** chamada runtime a `recordFeedback(...)` fora do service.

#### P3 — API manual de metricas do `PerformanceService` segue sem uso app-facing

- **Funcoes:** `startTrace`, `stopTrace`, `addMetric`, `addAttribute`,
  `getLocalStats` e `printLocalStats` em
  `app/lib/core/services/performance_service.dart:110`, `:130`, `:200`,
  `:210`, `:220` e `:248`.
- **Evidencia de ausencia:** busca em `app/lib`, `app/test` e
  `app/integration_test` encontrou esses nomes apenas nas definicoes; excecao:
  `getLocalStats` e chamado internamente por `printLocalStats`.
- **Controle positivo:** a observabilidade viva usa
  `PerformanceService.instance.init()` em `app/lib/main.dart:121`,
  `PerformanceNavigatorObserver` em `app/lib/main.dart:208`,
  `startScreenTrace`/`stopScreenTrace` em
  `app/lib/core/services/performance_service.dart:295`, `:307`, `:334` e
  `:339`, e `traceAsync` no smoke
  `app/integration_test/release_observability_smoke_test.dart:51`.
- **Por que parece nao chamada:** a parte automatica do service esta viva, mas a
  API manual/custom metrics/debug nao tem consumidor app-facing confirmado.
- **O que valida:** usar esses metodos em fluxos app reais ou simplificar o
  service para `init`, observer e `traceAsync`.
- **O que falsifica:** chamada app-facing aos metodos manuais em `app/lib`.

#### P3 — Conveniencias publicas de EDHREC/cache estao sem chamador confirmado

- **Funcoes:** `EdhrecService.getTopByCategory`,
  `EdhrecService.calculateFitScore`, `EdhrecService.cleanupCache` e
  `EdhrecCommanderData.isHighSynergy` em
  `server/lib/ai/edhrec_service.dart:333`, `:355`, `:363` e `:399`;
  `EndpointCache.clearExpired` em `server/lib/endpoint_cache.dart:32`.
- **Evidencia de ausencia:** busca exata pelos nomes encontrou somente essas
  definicoes para `getTopByCategory`, `calculateFitScore`, `cleanupCache`,
  `isHighSynergy` e `clearExpired`.
- **Controle positivo:** metodos adjacentes estao vivos: `getHighSynergyCards`
  e chamado em `server/lib/ai/otimizacao.dart:112`, `:120`, `:313` e
  `:321`; `EndpointCache.instance.get/set` sao usados em
  `server/routes/cards/index.dart`, `server/routes/sets/index.dart`,
  `server/routes/ai/archetypes/index.dart` e
  `server/lib/ai_generate_performance_support.dart`.
- **Por que parece nao chamada:** sao APIs auxiliares publicas ao lado de caminhos
  vivos, mas nenhum fluxo runtime atual usa categoria, fit score explicito,
  limpeza proativa de cache ou check direto `isHighSynergy`.
- **O que valida:** ligar essas conveniencias a uma rotina real ou torna-las
  privadas/remover se eram sobra de design.
- **O que falsifica:** chamada runtime nova aos metodos em `server/bin`,
  `server/lib` ou `server/routes`.

### Controles positivos e candidatos descartados

- O scan de baixa ocorrencia gerou muitos falsos positivos por funcoes chamadas
  uma vez por rota/bin ou por nomes presentes em SQL/comentarios; eles nao foram
  promovidos a achado sem evidencia manual.
- `PerformanceNavigatorObserver`, `startScreenTrace`, `stopScreenTrace` e
  `traceAsync` nao foram classificados como mortos porque ha chamadas reais em
  `app/lib/main.dart`, no proprio observer e no smoke de observabilidade.
- `buildCommanderReferenceCardStatsFromProfile`,
  `extractMtgTop8EventIdFromSourceUrl`, `getHighSynergyCards` e
  `EndpointCache.instance.get/set` foram descartados como controles positivos
  porque possuem consumidores runtime confirmados.


## Rodada focada: Card semantics — revalidacao 2026-06-04 05:30 UTC

Escopo desta rodada: nomes hardcoded de cartas em runtime, drift entre
`functional_tags`, `semantic_tags_v2` e roles de optimize, e pontos em que
utilidade ainda e inferida por nome ou heuristica local estreita. Produto/runtime
auditado primeiro: `server/lib`, `server/routes` e `app/lib`. Testes, docs,
artefatos e corpus foram usados apenas para separar fixtures/exemplos permitidos
de logica de produto.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `08637d2c`.

### Metodo manual focado

- Leitura dos documentos e arquivos pedidos na task:
  `docs/hermes-analysis/STRUCTURE_AUDIT.md`,
  `docs/hermes-analysis/PLANO_CORRECAO.md`,
  `docs/hermes-analysis/TECHNICAL_MAP.md`,
  `docs/hermes-analysis/PRODUCT_DIRECTION.md`,
  `docs/CONTEXTO_PRODUTO_ATUAL.md`, `server/manual-de-instrucao.md`,
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md`,
  `server/lib/ai/functional_card_tags.dart`,
  `server/lib/ai/optimization_functional_roles.dart`,
  `server/lib/ai/candidate_quality_data_support.dart`,
  `server/routes/ai/optimize/index.dart` e
  `server/lib/ai/optimize_request_support.dart`.
- Buscas focadas em `server/lib`, `server/routes` e `app/lib`:
  - `rg -n "Sol Ring|Command Tower|Thassa's Oracle|Isochron Scepter|Dramatic Reversal|Blood Artist|Boros Charm|..." server/lib server/routes app/lib --glob '*.dart'`.
  - `rg -n "normalizedName\\s*(==|!=)|normalizedName\\.contains|name\\s*(==|!=)|name\\.contains|cardName\\s*(==|!=)|cardName\\.contains|nameLower\\s*(==|!=)|nameLower\\.contains" server/lib server/routes app/lib --glob '*.dart'`.
  - `rg -n "inferFunctionalCardTags|inferSemanticCardAnalysisV2|summarizeFunctionalTagsForDeck|classifyOptimizationFunctionalRole|semantic_tags_v2|card_function_tags|functional_tags|role_delta" server/lib server/routes app/lib --glob '*.dart'`.
- Busca ampla no repositorio para classificar aparicoes em docs, fixtures,
  corpus e artefatos sem promover esses nomes automaticamente a bugs de runtime.

### Achados revalidados

#### P1 — Nomes hardcoded ainda participam de decisoes de runtime

- **Risk:** `server/lib/ai/functional_card_tags.dart:219`-`:226` marca ramp por
  `signet`, `talisman`, `sol ring` e `arcane signet`; `:700`-`:717` marca
  protecao por nomes como `Teferi's Protection`, `Heroic Intervention`,
  `Swiftfoot Boots` e `Lightning Greaves`; `:754`-`:780`, `:859`-`:874` e
  `:887`-`:905` usam nomes conhecidos para aristocrats/drain, wincon/combo,
  payoff e enabler.
- **Risk:** `server/lib/ai/candidate_quality_data_support.dart:375`-`:379`,
  `:421`-`:428`, `:439`-`:445`, `:472`-`:478`, `:531`-`:542`,
  `:590`-`:605` e `:611`-`:628` repetem checks por nome e aplicam bonus ou
  bracket scope via `highPowerNames`/`premium`.
- **Risk:** `server/lib/ai/optimize_runtime_support.dart:1296`-`:1310`,
  `:3476`-`:3515` e `:3568`-`:3618` mantem listas fixas para staples,
  fallbacks universais e fillers contextuais. `:2192`-`:2212` e `:2214`-`:2234`
  tambem inferem protecao/mana burst por `greaves`/`boots`/`ritual` alem de
  texto.
- **Risk:** `server/lib/ai/rebuild_guided_service.dart:1226`-`:1231` classifica
  ramp por `signet`/`sol ring`/`talisman`; `:1331`-`:1338` e
  `:1404`-`:1411` penalizam ou priorizam utility lands por nome.
- **O que valida:** mover excecoes realmente intencionais para policy/tabela
  versionada com `source`, `reason`, `role`, `scope`, `confidence` e testes; nos
  classificadores puros, preferir `oracle_text`, `type_line`, `mana_cost`, `cmc`
  e dados persistidos.
- **O que falsifica:** documentacao e testes provando que cada lista e seed
  controlada, policy versionada ou corpus, sem influenciar score/role/gate fora
  desse contrato.

#### P1 — Drift: deck analysis usa `functional_tags`, optimize nao carrega esse dado no gate

- **Controle positivo:** `GET /decks/:id/analysis` carrega `card_function_tags` e
  `semantic_tags_v2` em `server/routes/decks/[id]/analysis/index.dart:80`-`:96`
  e chama `summarizeFunctionalTagsForDeck` em `:278`-`:284`; a funcao prefere
  `functional_tags` persistidos antes de heuristica em
  `server/lib/ai/functional_card_tags.dart:432`-`:465`.
- **Controle positivo:** `POST /decks/:id/ai-analysis` faz selecao equivalente em
  `server/routes/decks/[id]/ai-analysis/index.dart:119`-`:135` e tambem resume
  por `summarizeFunctionalTagsForDeck` em `:331`-`:334`.
- **Drift:** `loadOptimizeDeckContext` monta `allCardData` com
  `semantic_tags_v2`, mas sem `functional_tags`, em
  `server/lib/ai/optimize_request_support.dart:169`-`:198`; o helper
  `_semanticV2SelectSql` em `:323`-`:339` agrega somente `card_semantic_tags_v2`.
- **Drift:** `server/routes/ai/optimize/index.dart:2078`-`:2099` monta
  `additionsData` com `semantic_tags_v2`, sem `functional_tags`; o helper local
  `_semanticV2SelectSql` em `:3197`-`:3213` tambem nao agrega
  `card_function_tags`.
- **Drift:** `classifyOptimizationFunctionalRole` em
  `server/lib/ai/optimization_functional_roles.dart:55`-`:124` usa
  `semantic_tags_v2` primeiro e `type_line`/`oracle_text` como fallback, mas nao
  le `functional_tags`. `OptimizationValidator` e quality gate chamam esse
  classificador em `server/lib/ai/optimization_validator.dart:265`-`:267` e
  `server/lib/ai/optimization_quality_gate.dart:52`-`:53`.
- **Drift multi-role:** o checkout atual nao contem simbolo
  `optimizationFunctionalRolesForCard`; o codigo vivo e escalar. O delta v2 em
  `server/lib/ai/optimization_functional_roles.dart:292`-`:349` soma apenas um
  role por carta, entao `semantic_tags_v2.tags` secundarios podem sumir do
  `role_delta`.
- **O que valida:** adapter unico que receba `functional_tags`,
  `semantic_tags_v2`, `oracle_text`, `type_line`, `mana_cost` e `cmc`, retornando
  conjunto de roles + `primary_role`; queries de optimize devem carregar
  `card_function_tags`.
- **O que falsifica:** teste mostrando que uma carta com `functional_tags=[draw]`
  sem v2 e uma carta com `semantic_tags_v2.tags=[draw, engine]` preservam os
  mesmos papeis em deck analysis, validator, quality gate e `role_delta`.

#### P2 — Rotas legacy avaliam utilidade de forma unidimensional

- **Risk se promovidas:** `server/routes/decks/[id]/recommendations/index.dart:110`-`:130`
  recalcula ramp/draw/removal/wipe/protection por `oracle_text` local, sem
  `functional_tags` ou `semantic_tags_v2`; `:262`-`:267` recomenda
  `Command Tower` diretamente; `_findStaples` em `:408`-`:438` usa raridade
  `rare/mythic` como proxy de impacto.
- **Risk se promovida:** `server/routes/ai/weakness-analysis/index.dart:41`-`:60`
  nao carrega `card_function_tags`, `semantic_tags_v2` nem `card_role_scores`;
  `:114`-`:163` reconta utilidade por heuristicas locais e dois nomes de
  protecao; `:206`-`:285` retorna listas fixas de nomes.
- **Contexto:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md:152` e `:286`
  classificam essas rotas como experimentais/not proven. O risco e liga-las ao
  app sem antes reutilizar a camada semantica compartilhada.
- **O que valida:** manter contrato interno/demo ou trocar sugestoes por query em
  `cards` + `card_legalities` + `card_function_tags` + `card_semantic_tags_v2` +
  `card_role_scores`, filtrando identidade, budget/bracket e cartas ja presentes.

### Candidatos permitidos ou intencionais

- **Allowed — UI/example/comment:** exemplos `1 Sol Ring` em importacao
  (`server/routes/import/index.dart:182`,
  `server/routes/import/to-deck/index.dart:102`,
  `app/lib/features/decks/screens/deck_import_screen.dart:385`-`:392` e
  `:592`, `app/lib/features/decks/widgets/deck_import_list_dialog.dart:154`) e
  comentarios de contrato em `server/routes/cards/resolve/batch/index.dart:15`-`:21`.
- **Allowed — search seed UI:** `app/lib/features/home/life_counter_screen.dart:2200`-`:2201`
  e `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:40`-`:41`
  sao sugestoes de busca do life counter, nao recomendacao/validacao de deck.
- **Allowed — docs/corpus/artifacts/tests:** nomes em `server/test/**`,
  `server/test/artifacts/**`, `docs/**`, `decks/**` e `server/manual-de-instrucao.md`
  foram tratados como fixtures, corpus, exemplos ou historico quando nao alimentam
  decisao runtime.
- **Allowed with caution — seed/fallback profile:** `loreholdDeterministicReferenceFallbackCards`
  em `server/lib/ai/commander_reference_generate_fallback_support.dart:182`-`:245`
  e seed deterministica de Commander Reference, nao classificador generico por
  nome. Ainda deve ser versionada/descrita como seed para nao parecer policy
  implicita de utilidade global.
- **Intentional exception:** `server/lib/edh_bracket_policy.dart:134`-`:142` usa
  listas curadas para combos infinitos e Game Changers, uma regra externa que nao
  e inferivel com seguranca so por oracle text. Precisa permanecer testada e
  versionada com fonte oficial.

## Rodada focada: Classes not used — revalidacao 2026-06-04 03:00 UTC

Escopo desta rodada: somente classes sem uso runtime confirmado. Nao foi feita
auditoria ampla de funcoes sem chamador, imports/ciclos, tabelas PostgreSQL,
duplicacao ou coerencia geral entre modulos fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `1c082553`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 170.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 87.
- Problemas identificados pelo relatorio gerado: 100.
- Imports quebrados: 1.

Limitacao para esta rotacao: o auditor base cobre `server/lib` e
`server/routes`, nao cobre `app/lib` e tambem nao constroi grafo de chamadas.
A propria docstring do script diz que achados de "nao usado" exigem validacao
manual com grep. A execucao tambem tentou inserir um bloco gerado grande e
duplicado em `STRUCTURE_AUDIT.md`; essa mutacao automatica foi descartada para
preservar a legibilidade, mantendo aqui apenas o resultado numerico do auditor e
os achados de classes revalidados manualmente. O import quebrado reportado
(`server/routes/ai/commander-learning/index.dart` ->
`../../../lib/ai/commander_learned_deck_support.dart`) fica fora desta rotacao e
nao foi tratado como achado de classes.

### Metodo manual focado

- `rg -n "class (LifeCounterScreen|DeckCard|DeckProgressChip|LotusPresentationMode)\b|\b(LifeCounterScreen|DeckCard|DeckProgressChip|LotusPresentationMode)\b" app/lib app/test app/integration_test --glob '*.dart'`.
- `rg -n "lifeCounterRoutePath|LotusLifeCounterScreen|life_counter_screen|lotus_life_counter_screen" app/lib/main.dart app/lib app/test app/integration_test --glob '*.dart'`.
- `rg -n "deck_card\.dart|\bDeckCard\(" app/lib app/test app/integration_test --glob '*.dart'`.
- `rg -n "\bDeckProgressIndicator\b|\bDeckProgressChip\(" app/lib app/test app/integration_test --glob '*.dart'`.
- `rg -n "\bLotusPresentationMode\b|lotus_presentation_mode\.dart|\.enter\(|\.exit\(" app/lib app/test app/integration_test --glob '*.dart'`.
- `rg -n "\b(AuthVisualShell|AuthBrandHeader|AuthFormSurface)\b|auth_visual_shell\.dart" . --glob '*.dart' --glob '!docs/**' --glob '!build/**'`.
- Varredura auxiliar de classes em `app/lib`, `server/lib` e `server/routes`
  com baixa contagem textual, seguida de verificacao manual para descartar
  `State` privados, observers, providers, scanner services, singletons e DTOs
  usados localmente ou por rotas/bin/tests.

### Achados revalidados

#### P1 — `LifeCounterScreen` legado segue fora do caminho runtime do app

- **Classe:** `LifeCounterScreen` em
  `app/lib/features/home/life_counter_screen.dart:61`, construtor em `:66`.
- **Rota ativa:** `app/lib/main.dart:282`-`:283` registra
  `lifeCounterRoutePath` com `const LotusLifeCounterScreen()`, importado em
  `app/lib/main.dart:54`.
- **Evidencia de ausencia em runtime app:** busca por `LifeCounterScreen(` em
  `app/lib` encontrou somente o construtor da propria classe. As chamadas reais
  encontradas estao em testes: `app/test/features/home/life_counter_screen_test.dart:36`
  e `app/test/features/home/life_counter_clone_proof_test.dart:277`.
- **Contexto de teste:** `app/test/features/home/life_counter_screen_test.dart:1`-`:2`
  declara a suite como referencia legada e diz que a cobertura viva agora mira
  `LotusLifeCounterScreen`; `app/test/features/home/life_counter_clone_proof_test.dart:1`-`:2`
  repete o mesmo contexto.
- **Por que parece nao usada:** a tela ainda existe em `app/lib` e tem testes,
  mas o roteamento de produto e a malha viva usam `LotusLifeCounterScreen`.
- **O que valida:** remover a tela legada ou move-la para harness/fixture
  explicitamente documentado, ajustando os testes para nao sugerirem cobertura
  runtime.
- **O que falsifica:** `app/lib` passar a importar e instanciar
  `LifeCounterScreen` em uma rota ou superficie viva.

#### P2 — `DeckCard` permanece testado, mas sem uso confirmado na listagem real

- **Classe:** `DeckCard` em
  `app/lib/features/decks/widgets/deck_card.dart:17`, construtor em `:22`.
- **Evidencia de ausencia em `app/lib`:** busca por import de `deck_card.dart`
  em `app/lib` nao retornou ocorrencias, e busca por `DeckCard(` em `app/lib`
  encontrou somente o construtor.
- **Usos encontrados:** apenas testes importam e instanciam o widget:
  `app/test/features/decks/widgets/deck_card_test.dart:4`/`:9` e
  `app/test/features/decks/widgets/deck_card_overflow_test.dart:4`/`:47`.
- **Controles positivos:** as listagens reais usam widgets locais:
  `_RecentDeckCard` em `app/lib/features/home/home_screen.dart:523`/`:529`,
  `_CommunityDeckCard` em `app/lib/features/community/screens/community_screen.dart:312`/`:732`,
  `_FollowingDeckCard` em `community_screen.dart:515`/`:946`, e
  `_DeckGalleryCard` em `app/lib/features/decks/screens/deck_list_screen.dart:626`/`:1401`.
- **Por que parece nao usada:** ha uma implementacao generica de card de deck,
  mas as superficies ativas usam implementacoes privadas divergentes.
- **O que valida:** reutilizar `DeckCard` na listagem real de decks, ou remover
  `DeckCard` e seus testes se a divergencia local for a decisao de produto.
- **O que falsifica:** import ou chamada `DeckCard(...)` em `app/lib` que a
  busca focada nao encontrou.

#### P2 — `DeckProgressChip` nao tem chamada de construtor confirmada

- **Classe:** `DeckProgressChip` em
  `app/lib/features/decks/widgets/deck_progress_indicator.dart:286`, construtor
  em `:292`.
- **Evidencia de ausencia:** busca por `DeckProgressChip(` em `app/lib`,
  `app/test` e `app/integration_test` encontrou somente o construtor.
- **Controle positivo:** `DeckProgressIndicator` no mesmo arquivo esta ativo:
  definido em `app/lib/features/decks/widgets/deck_progress_indicator.dart:14`
  e usado por `app/lib/features/decks/widgets/deck_details_overview_tab.dart:328`
  e `app/lib/features/decks/screens/deck_details_screen.dart:403`.
- **Por que parece nao usada:** o arquivo mistura o indicador vivo com um chip
  compacto que nao e chamado por cards/listas/testes.
- **O que valida:** chamar `DeckProgressChip` em uma superficie real ou remover
  a classe mantendo `DeckProgressIndicator`.
- **O que falsifica:** chamada direta a `DeckProgressChip(...)` em `app/lib` ou
  teste que prove contrato planejado para esse chip.

#### P2 — `LotusPresentationMode` parece utilitario morto no fluxo Lotus atual

- **Classe:** `LotusPresentationMode` em
  `app/lib/features/home/lotus/lotus_presentation_mode.dart:4`.
- **API exposta:** `enter()` em `:15` e `exit()` em `:26`.
- **Evidencia de ausencia:** busca por `LotusPresentationMode`,
  `lotus_presentation_mode.dart`, `.enter(` e `.exit(` em `app/lib`, `app/test`
  e `app/integration_test` encontrou somente a propria classe/metodos.
- **Por que parece nao usada:** o modo fullscreen/orientacao existe como helper,
  mas `LotusLifeCounterScreen` nao importa o arquivo nem chama `enter()`/`exit()`.
- **O que valida:** chamar `LotusPresentationMode.enter/exit` no lifecycle do
  Lotus com teste de contrato, ou remover o helper.
- **O que falsifica:** import vivo de `lotus_presentation_mode.dart` e chamadas
  de `LotusPresentationMode.enter/exit`.

#### P2 — `AuthVisualShell`, `AuthBrandHeader` e `AuthFormSurface` parecem sobras de UI auth

- **Classes:** `AuthVisualShell` em
  `app/lib/features/auth/widgets/auth_visual_shell.dart:5`, `AuthBrandHeader` em
  `:105` e `AuthFormSurface` em `:196`.
- **Evidencia de ausencia:** busca por `AuthVisualShell`, `AuthBrandHeader`,
  `AuthFormSurface` e `auth_visual_shell.dart` em todo o repositorio Dart
  encontrou apenas as definicoes/construtores no proprio arquivo.
- **Por que parecem nao usadas:** login/registro existem em
  `app/lib/features/auth/screens/login_screen.dart:7` e
  `app/lib/features/auth/screens/register_screen.dart:7`, mas nao importam esse
  shell compartilhado. O arquivo define uma superficie visual completa que nao
  participa do runtime auth nem da suite de testes.
- **O que valida:** reconectar login/registro ao shell compartilhado com teste
  de widget, ou remover o arquivo se o auth atual ja incorporou o visual direto
  nas telas.
- **O que falsifica:** import vivo de `auth_visual_shell.dart` ou chamadas a
  `AuthVisualShell(...)`, `AuthBrandHeader(...)` ou `AuthFormSurface(...)` fora
  do proprio arquivo.

### Controles positivos e candidatos descartados

- `LotusLifeCounterScreen` nao esta unused: `app/lib/main.dart:282`-`:283`
  instancia a rota ativa, e ha muitos testes/integration tests importando
  `lotus_life_counter_screen.dart`.
- `DeckProgressIndicator` nao esta unused: ele e usado na visao geral e na tela
  de detalhes do deck.
- `PerformanceNavigatorObserver` e `AppObservabilityNavigatorObserver` foram
  descartados porque `app/lib/main.dart:208`-`:209` instancia ambos em
  `navigatorObservers`.
- `CardRecognitionService`, `ImagePreprocessor`, `ScannerOcrParser`,
  `ScannerOverlay` e `ScannerGuideGeometry` foram descartados porque possuem
  chamadas reais em `ScannerProvider` ou `CardScannerScreen`; scanner continua
  deferido em produto, mas essas classes tem chamadores.
- Candidatos backend como `PushNotificationService`, `DistributedRateLimiter`,
  `MarketMoversCache`, `MatchupAnalyzer`, `SynergyEngine` e
  `PostgresExternalCommanderMetaCandidateLegalityRepository` foram descartados
  porque `rg` encontrou chamadas em services, rotas, binarios operacionais ou
  testes.
- Classes privadas `State` com baixa contagem textual foram descartadas porque
  sao referenciadas por `createState()` e pelo proprio lifecycle Flutter.

## Rodada focada: Coerencia entre modulos `server/lib` <-> `server/routes` <-> `app/lib` — revalidacao 2026-06-03 23:00 UTC

Escopo desta rodada: somente coerencia entre consumidores Flutter em `app/lib`,
rotas Dart Frog em `server/routes` e helpers em `server/lib`. Nao foi feita
auditoria ampla de classes sem uso, funcoes sem chamador, imports/ciclos,
tabelas PostgreSQL ou duplicacao fora deste foco.

### Setup executado

- `pwd` e `git rev-parse --show-toplevel` confirmaram o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `534f5672`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor base cobre `server/lib` e
`server/routes`, nao constroi grafo app -> rota -> helper, nao valida ownership
por contrato e nao compara allow-lists de eventos consumidos pelo app. A
execucao reescreveu `STRUCTURE_AUDIT.md` com um bloco gerado/duplicado; essa
mutacao automatica foi descartada e os achados abaixo foram revalidados por
busca focada e leitura direta.

### Metodo manual focado

- `rg -n "apiClient\\.(get|post|put|patch|delete)\\(" app/lib --glob '*.dart'`.
- `rg -n "ai/optimize|optimize/jobs|ai/archetypes|ai/rebuild|/analysis|ai-analysis|recommendations|simulate" app/lib server/routes server/lib --glob '*.dart'`.
- `rg -n "loadOptimizeDeckContext|SELECT name, format FROM decks|WHERE id = @id|dc.deck_id = @id|job.userId|context.read<String>|getUserId" server/routes/ai server/routes/decks server/lib/ai --glob '*.dart'`.
- `rg -n "ActivationFunnelService|activation-events|deck_rebuild_created|_allowedEvents" app/lib server/routes server/doc/API_CONTRACTS_AND_DATA_MAP.md --glob '*.dart' --glob '*.md'`.
- Leitura direta dos providers de deck/activation em `app/lib`, das rotas de
  AI/decks/activation correspondentes e dos helpers em `server/lib/ai`.

### Achados revalidados

#### P1 — `POST /ai/optimize` ainda perde ownership ao atravessar `routes -> lib`

- **Chamador app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:56`
  envia `apiClient.post('/ai/optimize', payload)`; o payload inclui
  `deck_id` em `:48`.
- **Rota:** `server/routes/ai/optimize/index.dart:401`-`:405` tenta ler
  `userId`, mas a chamada para `optimize_request.loadOptimizeDeckContext` em
  `:549`-`:558` passa `deckId`, archetype, modo e preferencias sem passar
  usuario.
- **Helper:** `server/lib/ai/optimize_request_support.dart:53`-`:62` declara o
  loader sem parametro de usuario; a query de deck usa
  `SELECT name, format FROM decks WHERE id = @id` em `:66`-`:72`, e as cartas
  sao carregadas por `WHERE dc.deck_id = @id` em `:107`-`:110`.
- **Por que e incoerente:** o app trata optimize como acao sobre deck do usuario
  autenticado, mas o helper backend cruza a fronteira `server/routes` ->
  `server/lib` sem owner-scope. Isso diverge do contrato global de ownership
  mobile em `server/doc/API_CONTRACTS_AND_DATA_MAP.md`.
- **O que valida:** adicionar `userId` obrigatorio ao loader, filtrar
  `decks` por `id + user_id`, carregar cartas via join owner-scoped e cobrir
  sync/async com teste owner vs non-owner.
- **O que falsifica:** contrato explicito e testado dizendo que optimize pode
  analisar deck privado de outro usuario por UUID, ou middleware/helper externo
  comprovado aplicando owner-scope antes dessas queries.

#### P1 — `POST /ai/archetypes` e consumido pelo app, mas carrega deck/cartas sem owner-scope

- **Chamador app:** `app/lib/features/decks/providers/deck_provider_support_mutation.dart:168`-`:173`
  envia `POST /ai/archetypes` com `{'deck_id': deckId}`.
- **Rota:** `server/routes/ai/archetypes/index.dart:27`-`:32` le `deck_id`,
  mas nao le usuario autenticado; `:39`-`:42` busca
  `SELECT name, format FROM decks WHERE id = @id`, e `:54`-`:60` carrega
  cartas por `WHERE dc.deck_id = @id`.
- **Por que e incoerente:** o endpoint fornece opcoes de estrategia para um
  deck do usuario no app, mas a rota usa existencia global do deck antes de
  montar cache/reference profile.
- **O que valida:** ler `userId`, buscar deck por `id + user_id`, carregar
  cartas atraves de deck owner-scoped e adicionar teste non-owner que retorne
  404 antes de qualquer cache/prompt.
- **O que falsifica:** mover o endpoint para contrato publico explicito, com
  teste e doc dizendo quais decks podem ser analisados sem ownership.

#### P1 — Polling de optimize ainda preserva jobs ownerless como legiveis

- **Chamador app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:190`-`:194`
  faz polling em `/ai/optimize/jobs/$jobId`.
- **Store:** `server/lib/ai/optimize_job.dart:25`-`:30` aceita
  `String? userId`; o job em memoria recebe esse valor nullable em `:37`-`:42`,
  e a persistencia grava `@user_id` em `:49`-`:64`.
- **Rota:** `server/routes/ai/optimize/jobs/[id].dart:26`-`:39` le o usuario,
  mas so bloqueia quando `job.userId != null && job.userId != userId`; job sem
  owner chega ao `job.toJson()` em `:49`.
- **Por que e incoerente:** o polling app-facing e uma continuacao de optimize
  de deck privado. Mesmo que a criacao normal passe `userId`, a API e a store
  ainda aceitam/expõem estado ownerless.
- **O que valida:** tornar `userId` obrigatorio para jobs app-facing, recusar
  criacao async sem usuario e retornar 404 quando
  `job.userId == null || job.userId != userId`.
- **O que falsifica:** separar jobs internos ownerless em rota interna com token
  interno e teste provando que `/ai/optimize/jobs/:id` publico nunca retorna
  esses jobs.

#### P2 — App envia evento de ativacao que a rota rejeita e a doc ainda marca como "not proven"

- **Chamador app:** `app/lib/features/decks/providers/deck_provider.dart:605`-`:607`
  chama `_trackActivationEvent('deck_rebuild_created', deckId: draftDeckId)`.
- **Wrapper app:** `app/lib/core/services/activation_funnel_service.dart:17`-`:23`
  envia `POST /users/me/activation-events`; o catch em `:24`-`:26` engole a
  falha para nao quebrar o fluxo principal.
- **Rota:** `server/routes/users/me/activation-events/index.dart:10`-`:18`
  define `_allowedEvents` sem `deck_rebuild_created`, e `:46`-`:48` rejeita
  qualquer evento fora da lista com `event_name invalido`.
- **Doc de contrato:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md:61` ainda
  classifica `POST /users/me/activation-events` como `internal`, com consumidor
  `onboarding/activation code not proven` e evidencia `Not proven`, apesar de
  chamadas reais em `app/lib/core/services/activation_funnel_service.dart`,
  `app/lib/features/home/onboarding_core_flow_screen.dart:32`-`:70` e
  `app/lib/features/decks/providers/deck_provider.dart:397`-`:605`.
- **Por que e incoerente:** um evento app-facing do fluxo de rebuild guiado e
  descartado silenciosamente pela combinacao allow-list backend + wrapper que
  engole erro; alem disso, a documentacao operacional nao reflete o consumo real
  do app.
- **O que valida:** adicionar `deck_rebuild_created` a `_allowedEvents` com
  teste, ou remover/renomear a emissao no app; atualizar o contrato para listar
  os consumidores reais e manter o endpoint como telemetria tolerante, nao como
  estado de produto.
- **O que falsifica:** teste/documento provando que rebuild guiado nao deve ser
  medido por activation funnel e que a chamada app sera removida.

#### P2 — Rotas experimentais de deck/AI seguem sem contrato de ownership antes de promocao app-facing

- **Rotas:** `server/routes/decks/[id]/recommendations/index.dart:24`-`:27`
  busca `decks` por `id` e `:39`-`:58` busca cartas por `dc.deck_id`; e
  `server/routes/decks/[id]/simulate/index.dart:13`-`:25` simula cartas por
  `dc.deck_id` sem ler usuario.
- **Consumidor app atual:** a busca focada em `app/lib` nao encontrou chamadas
  atuais para `/decks/:id/recommendations` nem `/decks/:id/simulate`.
- **Por que e incoerente:** as rotas vivem no namespace privado de decks e leem
  composicao do deck, mas nao seguem a fronteira owner-scoped das rotas estaveis.
  O risco imediato e promocao acidental antes de definir se o contrato e owner,
  publico por `is_public=true` ou interno.
- **O que valida:** remover/descontinuar as rotas, aplicar gate `id + user_id`
  com teste non-owner, ou documentar contrato publico restrito a decks publicos.
- **O que falsifica:** consumidor app novo mais contrato/teste provando a regra
  de acesso antes de usar esses endpoints.

### Controles positivos

- `POST /ai/rebuild` continua fora dos achados: o app chama
  `app/lib/features/decks/providers/deck_provider_support_ai.dart:165`-`:168`,
  e a rota busca o deck em `server/routes/ai/rebuild/index.dart:62`-`:78` com
  `WHERE d.id = @deckId AND d.user_id = @userId`.
- `GET /decks/:id/analysis` continua owner-scoped: o app chama
  `app/lib/features/decks/providers/deck_provider_support_fetch.dart:139`, e a
  rota faz gate em `server/routes/decks/[id]/analysis/index.dart:16`-`:26`
  antes de ler cartas.
- `POST /decks/:id/ai-analysis` e `POST /decks/:id/pricing` continuam controles
  de padrao porque as rotas verificam `deck_id + user_id` antes de carregar
  dados do deck.
- Os demais eventos de activation atualmente emitidos pelo app
  (`core_flow_started`, `format_selected`, `base_choice_generate`,
  `base_choice_import`, `deck_created`, `deck_optimized`,
  `onboarding_completed`) existem em `_allowedEvents`; o mismatch confirmado
  nesta rodada e `deck_rebuild_created`.

## Rodada focada: Duplicated or similar logic — revalidacao 2026-06-03 19:00 UTC

Escopo desta rodada: somente logica duplicada ou similar com risco de drift.
Nao foi feita auditoria ampla de classes sem uso, funcoes sem chamador, imports,
ciclos, tabelas PostgreSQL ou coerencia entre modulos fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa apos uma tentativa
  inicial bloqueada por `.git/index.lock` transitorio; o lock desapareceu antes
  de qualquer remocao manual.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `18b2949d`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor textual detecta duplicacao por nomes de
funcoes e regex, mas tambem captura tokens SQL/texto como `COUNT`, `FROM`,
`LATERAL`, `card_function_tags` e palavras em prompts. A execucao tentou
appendar historico gerado e duplicar blocos manuais; esse ruido foi descartado.
Os achados abaixo foram revalidados por busca focada e leitura de linhas.

### Metodo manual focado

- `rg -n "resolveOptimizeArchetype|_looksLikeComboPiece|_looksLikeEnabler|_looksLikeEngine|_looksLikePayoff|_looksLikeWincon|_isBasicLandName\\b" server/lib server/routes --glob '*.dart'`.
- `rg -n "_trustStatsSql|_responseTimeSql|_shippingTimeSql|_buildTrustInsight|LATERAL\\s*\\(|trust" server/routes/trades server/routes/community/marketplace --glob '*.dart'`.
- `rg -n "_requestId|_logInvalidPayload|getRequestTrace|tryGetRequestId" server/routes/trades server/routes/conversations server/routes/users server/lib/request_trace.dart --glob '*.dart'`.
- `rg -n "NM|LP|MP|HP|DMG|validConditions|condition" server/routes/decks server/routes/binder server/routes/community/marketplace --glob '*.dart'`.
- `rg -n "calculateCmc|getMainType" server/routes/decks server/routes/community --glob '*.dart'`.

### Achados revalidados

#### P1 — `resolveOptimizeArchetype` continua duplicado com contratos diferentes

- **Implementacao A:** `server/lib/ai/deck_state_analysis.dart:573`-`:585`
  aceita `requestedArchetype` nullable, trata `midrange/general/value/tempo`
  como genericos e retorna `detected` quando o requested e generico.
- **Implementacao B:** `server/lib/ai/optimize_runtime_support.dart:3369`-`:3389`
  exige `requestedArchetype`, trata `unknown` no detected, considera
  `midrange/value/goodstuff` como genericos e so aceita detected especifico em
  `aggro/control/combo/stax/tribal`.
- **Consumidores divergentes:** `server/routes/ai/optimize/index.dart:56`-`:63`
  delega para a versao de optimize, enquanto
  `server/lib/ai/rebuild_guided_service.dart:171`-`:174` usa a versao de
  `deck_state_analysis.dart`.
- **Por que e duplicacao de risco:** os dois helpers respondem a mesma pergunta
  de produto, mas casos como `tempo`, `goodstuff`, `unknown` e detected fora da
  allow-list podem produzir arquetipos efetivos diferentes entre optimize e
  rebuild.
- **O que valida:** extrair uma funcao unica com tabela de casos para
  `null/vazio/unknown`, `tempo`, `goodstuff`, `general`, requested igual ao
  detected e detected especifico; substituir os dois consumidores.
- **O que falsifica:** teste documentando que optimize e rebuild devem divergir
  nesses casos, com nomes de helper/contrato diferentes para refletir a regra.

#### P1 — Heuristicas de roles altos existem em dois classificadores semanticos

- **Deck analysis / functional tags:** `server/lib/ai/functional_card_tags.dart:319`-`:336`
  adiciona tags multiplas para `wincon`, `combo_piece`, `engine`, `payoff` e
  `enabler`; os helpers em `:859`-`:906` usam `oracle_text` e tambem nomes
  conhecidos como `thassa's oracle`, `isochron scepter`, `dramatic reversal`,
  `blood artist`, `greaves` e `boots`.
- **Optimize role delta:** `server/lib/ai/optimization_functional_roles.dart:111`-`:119`
  decide um unico role alto antes do fallback por tipo; os helpers em
  `:370`-`:397` usam somente `oracle_text` e padroes diferentes.
- **Por que e duplicacao de risco:** a mesma carta pode entrar como multi-role
  na analise do deck e como um unico role diferente no optimize. Isso mantém o
  drift ja mapeado entre explicabilidade e gate de substituicao.
- **O que valida:** criar adapter unico que aceite `functional_tags`,
  `semantic_tags_v2`, `oracle_text`, `type_line` e nome, retornando roles
  multiplos + `primary_role`; usar o adapter em deck analysis, validator/role
  delta e candidate quality.
- **O que falsifica:** teste de contrato provando que analysis e optimize podem
  intencionalmente usar taxonomias diferentes sem afetar remocoes/substituicoes.

#### P1 — Deteccao de basic/snow basic lands esta duplicada e diverge

- **Optimize:** `server/lib/ai/optimize_runtime_support.dart:285` expoe
  `isBasicLandName`, e `_isBasicLandName` em `:4184`-`:4197` reconhece basics,
  `wastes` e `snow-covered ...` com hifen.
- **Generated deck validation:** `server/lib/generated_deck_validation_service.dart:744`-`:763`
  combina type line com `_isBasicLandName`, usando `startsWith('snow-covered ...')`.
- **Meta reference:** `server/lib/meta/meta_deck_reference_support.dart:890`-`:903`
  reconhece `snow covered ...` com espaco, nao `snow-covered ...` com hifen.
- **Commander Reference route:** `server/routes/ai/commander-reference/index.dart:621`-`:628`
  reconhece somente basics regulares e `wastes`, sem snow basics.
- **Por que e duplicacao de risco:** copy-limit, filtros de corpus/meta e
  rotas Commander Reference podem discordar sobre a mesma carta snow basic.
- **O que valida:** extrair helper unico de land basics/snow basics para
  `server/lib` e trocar os quatro pontos, com testes para `Snow-Covered Island`,
  `snow covered island`, `Wastes`, `Command Tower` e nomes com espacos/hifens.
- **O que falsifica:** contrato explicito provando que Commander Reference/meta
  devem excluir snow basics por regra propria, com teste dedicado.

#### P2 — Trust de trades/marketplace repete SQL e serializer

- **Trades list:** `server/routes/trades/index.dart:557`-`:635` define
  `_trustStatsSql`, `_responseTimeSql`, `_shippingTimeSql` e
  `_buildTrustInsight`.
- **Trade detail:** `server/routes/trades/[id]/index.dart:260`-`:338` repete os
  mesmos helpers para sender/receiver.
- **Marketplace:** `server/routes/community/marketplace/index.dart:131`-`:164`
  repete os LATERALs de trust/response/shipping inline, e
  `:316`-`:348` repete o serializer `_buildTrustInsight`.
- **Por que e duplicacao de risco:** qualquer ajuste de trust, conta nova,
  perfil incompleto, response time ou shipping time precisa ser aplicado em
  tres superficies app-facing.
- **O que valida:** mover SQL fragments e serializer para helper compartilhado
  de trust social, mantendo aliases/prefixos por caller e testes de shape para
  listagem, detalhe e marketplace.
- **O que falsifica:** diferencas documentadas por superficie com testes que
  provem shapes divergentes intencionais.

#### P2 — Request id e log de payload invalido repetem helper ja existente

- **Helper existente:** `server/lib/request_trace.dart:48`-`:57` expoe
  `getRequestTrace` e `tryGetRequestId`.
- **Duplicacoes:** `_requestId` aparece em
  `server/routes/trades/index.dart:330`-`:336`,
  `server/routes/trades/[id]/respond.dart:154`-`:160`,
  `server/routes/trades/[id]/status.dart:260`-`:266`,
  `server/routes/conversations/[id]/messages.dart:247`-`:253` e
  `server/routes/users/[id]/follow/index.dart:97`-`:103`. O padrao
  `_logInvalidPayload` tambem se repete em rotas sociais, por exemplo
  `server/routes/trades/index.dart:338`-`:352` e
  `server/routes/conversations/[id]/messages.dart:255`-`:270`.
- **Por que e duplicacao de risco:** fallback de request id, formato
  `[social_write] invalid_payload`, user id opcional e campos de contexto podem
  divergir entre rotas de escrita social.
- **O que valida:** usar `tryGetRequestId` ou helper compartilhado de log social,
  com parametros para endpoint e ids (`trade_id`, `conversation_id`, etc.).
- **O que falsifica:** cada rota ter formato de log intencionalmente distinto e
  coberto por teste/contrato operacional.

#### P2 — Validacao de `condition` tem regras duplicadas e comportamentos diferentes

- **Deck update:** `server/routes/decks/[id]/index.dart:518`-`:523` normaliza
  invalido para `NM`; `server/routes/decks/[id]/cards/index.dart:399`-`:403` e
  `server/routes/decks/[id]/cards/set/index.dart:244`-`:248` repetem o mesmo
  fallback.
- **Binder:** `server/routes/binder/index.dart:275`-`:280` e
  `server/routes/binder/[id]/index.dart:339`-`:345` rejeitam condition invalida
  com `400`.
- **Marketplace filter:** `server/routes/community/marketplace/index.dart:39`-`:43`
  so aplica filtro se a condition estiver na allow-list; invalida e ignorada.
- **Por que e duplicacao de risco:** o mesmo dominio `NM/LP/MP/HP/DMG` tem tres
  contratos: normalizar, rejeitar e ignorar filtro. Isso pode ser intencional,
  mas hoje esta espalhado sem helper/contrato compartilhado.
- **O que valida:** centralizar allow-list e expor helpers separados
  (`normalizeOrDefault`, `parseOrReject`, `parseOptionalFilter`) com testes.
- **O que falsifica:** contrato app-facing documentando explicitamente os tres
  comportamentos e testes por rota.

#### P3 — CMC e tipo principal ainda sao calculados inline em rotas de deck

- **Deck privado:** `server/routes/decks/[id]/index.dart:405`-`:436` define
  `getMainType` e `calculateCmc`.
- **Deck publico:** `server/routes/community/decks/[id].dart:91`-`:117` repete
  a mesma logica com pequenas diferencas de estilo.
- **Simulate:** `server/routes/decks/[id]/simulate/index.dart:171`-`:186` tem
  uma terceira variante de CMC.
- **Por que e duplicacao de risco:** hoje e baixo risco por ser logica simples,
  mas mudancas em custo hibrido, phyrexian, split/adventure ou tipo principal
  podem divergir entre privado, publico e simulacao.
- **O que valida:** helper unico de parsing leve de mana/type usado nas tres
  rotas, ou consumo direto de campos normalizados do banco quando disponiveis.
- **O que falsifica:** testes provando equivalencia das tres rotas para custos
  hibridos, `X`, split cards e type lines complexos.

### Controles positivos

- `server/routes/ai/optimize/index.dart:56`-`:63` e wrapper fino que delega para
  `optimize_runtime_support.dart`; nao foi classificado como duplicacao direta.
- A duplicacao historica no provider app entre caminhos de persistencia do
  optimize continua reduzida: `app/lib/features/decks/providers/deck_provider.dart:787`
  centraliza `_persistDeckCardsPayload`, `:836` chama
  `buildNamedOptimizationPayload`, e `:869`-`:986` reutiliza o mesmo persist
  para `applyOptimizationWithIds`.
- Nenhum codigo de produto foi alterado nesta rodada.

## Rodada focada: PostgreSQL tables not used — revalidacao 2026-06-03 15:00 UTC

Escopo desta rodada: somente tabelas PostgreSQL persistidas sem consumidor
claro, write-only ou com uso incoerente. Nao foi feita auditoria ampla de
classes, funcoes sem chamador, imports/ciclos, duplicacao ou coerencia entre
modulos fora deste foco.

### Setup executado

- `pwd` e `git rev-parse --show-toplevel` confirmaram o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `0ecce9f6`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor base faz varredura textual em
`server/lib` e `server/routes`; ele lista referencias a tabelas, mas nao separa
persistencia de consumo efetivo, nao resolve CTEs/aliases com confianca e nao
prova que uma tabela e lida por fluxo produto. A execucao tambem tentou inserir
um bloco gerado duplicando historico manual; esse ruido foi descartado, mantendo
somente a triagem manual focada abaixo.

### Metodo manual focado

- `rg -n "\\b(deck_matchups|deck_weakness_reports|ml_prompt_feedback|commander_reference_decks|commander_reference_deck_cards|commander_reference_deck_analysis)\\b" server/database_setup.sql server/bin server/lib server/routes app/lib --glob '*.dart' --glob '*.sql'`.
- `rg -n "\\b(FROM|JOIN)\\s+(deck_matchups|deck_weakness_reports|commander_reference_decks|commander_reference_deck_cards)\\b" server/routes server/lib server/bin app/lib --glob '*.dart'`.
- `rg -n "\\b(SELECT|FROM|JOIN|INSERT INTO|UPDATE|DELETE FROM)\\s+(deck_matchups|deck_weakness_reports|ml_prompt_feedback|commander_reference_decks|commander_reference_deck_cards|commander_reference_deck_analysis)\\b" server/routes server/lib server/bin app/lib --glob '*.dart'`.
- Varredura complementar de operacoes SQL em `server/routes`, `server/lib` e
  `server/bin` para separar falsos candidatos de tabelas com leitores reais.

### Achados revalidados

#### P2 — `deck_matchups` continua write-only no produto atual

- **Tabela:** `deck_matchups`, definida em `server/database_setup.sql:162`.
- **Escrita encontrada:** `server/routes/ai/simulate-matchup/index.dart:360`
  faz `INSERT INTO deck_matchups (...) ON CONFLICT (...) DO UPDATE`.
- **Leitura encontrada:** nenhum `SELECT ... FROM deck_matchups`, `JOIN
  deck_matchups`, `UPDATE deck_matchups` ou `DELETE FROM deck_matchups` em
  `server/routes`, `server/lib`, `server/bin` ou `app/lib`.
- **Por que parece sem consumidor:** a rota calcula `winRate` em memoria e
  retorna a resposta imediatamente; `deck_matchups.win_rate/notes` nao alimenta
  cache, historico, ranking, UI ou proxima simulacao neste checkout.
- **O que valida:** criar consumidor real de `deck_matchups` com contrato e
  teste, por exemplo historico/cached matchup, dashboard operacional ou reuso na
  simulacao.
- **O que falsifica:** `rg "\\b(FROM|JOIN)\\s+deck_matchups\\b" server app`
  encontrar leitura runtime real, ou a persistencia ser removida por decisao
  documentada.

#### P2 — `deck_weakness_reports` acumula registros sem fluxo de leitura ou resolucao

- **Tabela:** `deck_weakness_reports`, definida em
  `server/database_setup.sql:363`.
- **Escrita encontrada:** `server/routes/ai/weakness-analysis/index.dart:374`
  faz `INSERT INTO deck_weakness_reports (...) ON CONFLICT DO NOTHING`.
- **Leitura encontrada:** nenhum `SELECT ... FROM deck_weakness_reports`,
  `JOIN deck_weakness_reports`, `UPDATE deck_weakness_reports` ou `DELETE FROM
  deck_weakness_reports` em `server/routes`, `server/lib`, `server/bin` ou
  `app/lib`.
- **Por que parece sem consumidor:** os reports persistidos nao sao usados para
  historico, comparacao entre rodadas, dashboard ou fluxo de `addressed`; o campo
  `addressed` existe no schema, mas nao tem update confirmado.
- **O que valida:** endpoint/job/UI ler reports por deck e atualizar
  `addressed`, com teste de contrato.
- **O que falsifica:** leitura/update runtime confirmado para
  `deck_weakness_reports`, ou remocao da persistencia em favor de resposta
  efemera.

#### P3 — `ml_prompt_feedback` tem helper de insert sem chamador e apenas contador operacional

- **Tabela:** `ml_prompt_feedback`, definida em
  `server/bin/migrate_ml_knowledge.dart:159`.
- **Escrita potencial:** `MLKnowledgeService.recordFeedback` em
  `server/lib/ml_knowledge_service.dart:251` possui SQL `INSERT INTO
  ml_prompt_feedback` em `server/lib/ml_knowledge_service.dart:264`.
- **Chamador encontrado:** nenhum; `rg -n "\\brecordFeedback\\b|\\bMLKnowledgeService\\("`
  encontrou apenas a definicao do service, a definicao do metodo e a injecao de
  `MLKnowledgeService` em `server/lib/ai/otimizacao.dart:33`.
- **Leitura encontrada:** `/ai/ml-status` executa apenas
  `SELECT COUNT(*)::int as c FROM ml_prompt_feedback` em
  `server/routes/ai/ml-status/index.dart:98`.
- **Por que parece sem consumidor:** nao ha fluxo app, rota, job ou teste
  acionando feedback real, e o unico read confirmado e contador operacional, nao
  loop de aprendizado ou refinamento de prompt.
- **O que valida:** app/rota/job chamar `recordFeedback` e algum fluxo consumir
  esse feedback com contrato e teste.
- **O que falsifica:** chamada runtime a `recordFeedback(...)` fora do service ou
  remocao/documentacao da tabela como contador operacional apenas.

#### P2/P3 — Raw Commander Reference corpus persiste, mas o produto le somente o agregado

- **Tabelas:** `commander_reference_decks` e
  `commander_reference_deck_cards`, definidas em
  `server/lib/ai/commander_reference_deck_corpus_support.dart:1177` e `:1200`.
- **Escritas encontradas:** `INSERT INTO commander_reference_decks` em
  `server/lib/ai/commander_reference_deck_corpus_support.dart:1245`, `DELETE
  FROM commander_reference_deck_cards` em `:1329` e `INSERT INTO
  commander_reference_deck_cards` em `:1345`.
- **Leitura encontrada:** nenhum `SELECT/JOIN` runtime confirmado para as duas
  tabelas raw em `server/routes`, `server/lib`, `server/bin` ou `app/lib`.
- **Controle positivo:** o produto consome o agregado
  `commander_reference_deck_analysis` em
  `server/lib/ai/commander_reference_deck_corpus_support.dart:389`, e o mesmo
  modulo atualiza esse agregado em `:1394`.
- **Por que parece parcialmente consumido:** as raw tables servem como lineage
  de corpus durante apply/reprocessamento, mas nao ha leitor runtime confirmado;
  a geracao le apenas os sinais agregados.
- **O que valida:** documentar e testar as raw tables como audit/lineage com job
  de reprocessamento, ou criar consumidor real de raw corpus.
- **O que falsifica:** `rg "\\b(FROM|JOIN)\\s+(commander_reference_decks|commander_reference_deck_cards)\\b" server app`
  encontrar leitura runtime real, ou persistir somente
  `commander_reference_deck_analysis`.

### Controles positivos

- `battle_simulations` nao foi classificada como nova tabela sem consumidor:
  embora receba insert em `server/routes/ai/simulate/index.dart:206`, ha leitura
  em `server/bin/ml_extract_features.dart:76` para extracao de features.
- `format_staples`, `archetype_counters`, `archetype_patterns`,
  `synergy_packages`, `activation_funnel_events` e `ai_user_preferences` tem
  leitores runtime ou runners dedicados confirmados nesta varredura, portanto
  nao entram como achados desta rodada.
- A varredura focada nao encontrou novo candidato de tabela persistida sem
  leitura alem dos itens acima.

## Rodada focada: Broken imports and circular dependencies — revalidacao 2026-06-03 11:00 UTC

Escopo desta rodada: somente imports locais quebrados e ciclos diretos/fortemente
conectados no grafo de imports Dart. Nao foi feita auditoria ampla de classes,
funcoes sem chamador, tabelas PostgreSQL, duplicacao ou coerencia entre modulos
fora deste foco.

### Setup executado

- `pwd` e `git rev-parse --show-toplevel` confirmaram o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `4795a07b`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor base cobre apenas `server/lib` e
`server/routes`, faz analise textual e nao constroi grafo de dependencias. A
execucao automatica tambem tentou reescrever parte do historico manual de
`STRUCTURE_AUDIT.md`; essa escrita gerada foi descartada e substituida pela
triagem focada abaixo.

### Metodo manual focado

- Resolver imports locais de 420 arquivos Dart em `app/lib`, `server/lib`,
  `server/routes` e `server/bin`, tratando `package:manaloom/...` como
  `app/lib/...`, `package:server/...` como `server/lib/...`, `package:ai/...`
  como alias historico de `server/lib/ai/...`, e imports relativos a partir do
  arquivo origem.
- Calcular componentes fortemente conectados (SCC/Tarjan) no mesmo grafo de
  imports locais.
- Conferir linhas com `nl -ba` nos arquivos apontados.
- `dart analyze` em `server/` foi usado como validacao extra para o import
  quebrado do backend.
- `flutter analyze --no-pub --no-fatal-infos` em `app/` foi nao conclusivo neste
  checkout: sem `app/.dart_tool/package_config.json`, o analyzer reportou
  milhares de `uri_does_not_exist` para `package:flutter`, `package:manaloom` e
  dependencias externas antes de isolar os imports relativos locais.

### Achados revalidados

#### P1 — Dois imports relativos do app ainda escapam de `app/lib`

- **Import quebrado:** `app/lib/features/decks/widgets/deck_analysis_tab.dart:5`
  importa `../../../../core/utils/mana_helper.dart`. Resolvido a partir do
  arquivo origem, esse caminho aponta para `app/core/utils/mana_helper.dart`, que
  nao existe. O alvo existente e `app/lib/core/utils/mana_helper.dart`.
- **Import quebrado:** `app/lib/features/home/life_counter_screen.dart:7`
  importa `../../../core/theme/app_theme.dart`. Resolvido a partir de
  `app/lib/features/home`, esse caminho aponta para `app/core/theme/app_theme.dart`,
  que nao existe. O alvo existente e `app/lib/core/theme/app_theme.dart`.
- **Por que parece quebrado:** a resolucao de caminho local nao depende de
  package config; os dois caminhos relativos saem um nivel acima de `app/lib`.
- **O que valida:** trocar para imports que resolvam dentro de `app/lib`
  (`../../../core/utils/...` no primeiro caso, `../../core/theme/...` no segundo)
  ou para `package:manaloom/...`, depois rerodar `flutter analyze` com
  `app/.dart_tool/package_config.json` presente.
- **O que falsifica:** criar intencionalmente os arquivos em `app/core/...` ou
  provar com analyzer configurado que esses imports sao redirecionados, o que nao
  e indicado pela semantica de imports relativos Dart.

#### P1 — `server/bin/local_test_server.dart` importa artefato Dart Frog ausente

- **Import quebrado:** `server/bin/local_test_server.dart:3` importa
  `../.dart_frog/server.dart` como `generated`.
- **Evidencia de filesystem:** o caminho resolve para
  `server/.dart_frog/server.dart`, ausente neste checkout.
- **Evidencia de analyzer:** `cd server && dart analyze` falhou com um unico
  erro: `bin/local_test_server.dart:3:8 - Target of URI doesn't exist:
  '../.dart_frog/server.dart' - uri_does_not_exist`.
- **Por que parece quebrado:** o entry point local depende de um artefato gerado
  que nao esta versionado nem presente apos o sync da branch.
- **O que valida:** gerar o artefato antes do analyze/uso local ou substituir o
  entry point por um caminho que nao tenha import estatico para arquivo ausente;
  o criterio minimo e `dart analyze` verde em `server/`.
- **O que falsifica:** `server/.dart_frog/server.dart` existir no checkout ou
  `dart analyze` deixar de reportar `uri_does_not_exist` nesse arquivo.

#### P2 — Um ciclo direto permanece entre telas de comunidade e perfil social

- **Ciclo encontrado:** o grafo de 420 arquivos Dart teve 1 SCC com mais de um
  arquivo, de tamanho 2.
- **Aresta 1:** `app/lib/features/community/screens/community_deck_detail_screen.dart:8`
  importa `../../social/screens/user_profile_screen.dart`, resolvendo para
  `app/lib/features/social/screens/user_profile_screen.dart`.
- **Uso runtime da aresta 1:** a tela de detalhe de deck publico instancia
  `UserProfileScreen` via `Navigator.push` em
  `app/lib/features/community/screens/community_deck_detail_screen.dart:209`-`:213`.
- **Aresta 2:** `app/lib/features/social/screens/user_profile_screen.dart:7`
  importa `../../community/screens/community_deck_detail_screen.dart`, resolvendo
  para `app/lib/features/community/screens/community_deck_detail_screen.dart`.
- **Uso runtime da aresta 2:** o perfil social instancia
  `CommunityDeckDetailScreen` via `Navigator.push` em
  `app/lib/features/social/screens/user_profile_screen.dart:466`-`:469`.
- **Por que e risco:** o ciclo nao prova falha de compilacao por si so, mas une
  duas telas de dominios diferentes e torna navegacao/composicao mais fragil;
  qualquer inicializacao estatica, export ou refactor em uma tela pode puxar a
  outra de volta.
- **O que valida:** mover a navegacao para rotas nomeadas/GoRouter ou para um
  adapter/shared navigation helper sem import cruzado entre as duas telas, depois
  rerodar a varredura SCC.
- **O que falsifica:** nova varredura de SCC sem componente contendo esses dois
  arquivos, ou evidencia de que um dos imports deixou de existir e a navegacao
  passou por boundary compartilhado.

### Controles positivos

- A varredura focada nao encontrou outros imports locais quebrados alem dos tres
  listados acima.
- A varredura SCC nao encontrou outros ciclos locais entre `app/lib`,
  `server/lib`, `server/routes` e `server/bin`.
- O auditor base continuou reportando `Imports quebrados: 0` dentro do recorte
  limitado `server/lib` + `server/routes`.

## Rodada focada: Functions not called — revalidacao 2026-06-03 07:00 UTC

Escopo desta rodada: somente funcoes/metodos publicos ou wrappers expostos sem
chamador runtime confirmado. Nao foi feita auditoria ampla de classes, imports,
tabelas PostgreSQL, duplicacao ou coerencia entre modulos fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `0d55a920`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor textual nao compila codigo nem constroi
grafo de chamadas; a docstring do script tambem avisa que achados de "nao
usado" exigem validacao manual com grep. A execucao reescreveu e duplicou parte
do historico manual de `STRUCTURE_AUDIT.md`; essa escrita automatica foi
descartada, mantendo somente os achados abaixo, revalidados por busca focada.

### Metodo manual focado

- `rg -n "sync_cards_utils|\\bextractCardRow\\b|\\bextractSetCardRow\\b|\\bparseSinceDays\\b|\\bextractOracleIds\\b|\\bextractLegalities\\b" server app --glob '*.dart'`.
- `rg -n "\\bgetRequestTrace\\b|\\btryGetRequestId\\b|context\\.read<RequestTrace>\\(\\)" server app --glob '*.dart'`.
- `rg -n "\\bnormalizedCommanderReferenceCandidate\\b|\\bbuildLoreholdReferenceCardStatsFromProfile\\b|\\bextractMtgTop8FormatCodeFromSourceUrl\\b|\\bbuildCandidateQualitySamplePoolSql\\b|\\bsummarizeAggressiveOptimizeUtilitySamples\\b|\\brecordFeedback\\b" server app --glob '*.dart'`.
- `rg -n "\\b(startTrace|stopTrace|traceAsync|addMetric|addAttribute|getLocalStats|printLocalStats|PerformanceNavigatorObserver)\\b" app/lib app/test app/integration_test --glob '*.dart'`.

### Achados revalidados

#### P1 — `sync_cards_utils.dart` segue test-only enquanto o CLI real duplica a logica

- **Funcoes:** `extractCardRow`, `getNewSetCodesSinceFromData`,
  `parseSinceDays`, `extractSetCardRow`, `extractOracleIds` e
  `extractLegalities` em `server/lib/sync_cards_utils.dart:16`, `:82`, `:102`,
  `:116`, `:161` e `:172`.
- **Evidencia de ausencia runtime:** busca por `sync_cards_utils` em Dart
  encontrou apenas `server/test/sync_cards_test.dart:3` importando o arquivo.
  `server/bin/sync_cards.dart:9`-`:10` importa `database.dart` e
  `mtg_data_integrity_support.dart`, mas nao importa `sync_cards_utils.dart`.
- **Controle positivo:** o CLI operacional mantem copias privadas/inline:
  `_parseSinceDays` em `server/bin/sync_cards.dart:376`,
  `_getNewSetCodesSinceFromData` em `:413`, `_upsertCardsFromSet` em `:577`,
  `_extractCardRow` em `:680`, coleta de oracle IDs em `:807`-`:813` e
  legalidades inline em `:834`-`:837`.
- **Por que parece nao chamada:** os testes validam a biblioteca publica, mas o
  caminho que sincroniza MTGJSON no produto nao usa essa biblioteca.
- **O que valida:** importar `sync_cards_utils.dart` no CLI real e remover as
  copias privadas/inline, ou declarar/remover o arquivo como harness legado.
- **O que falsifica:** `rg "sync_cards_utils" server/bin server/lib server/routes`
  encontrar import runtime real.

#### P2 — Wrappers de `RequestTrace` continuam sem consumidor direto

- **Funcoes:** `getRequestTrace` e `tryGetRequestId` em
  `server/lib/request_trace.dart:48` e `:51`.
- **Evidencia de ausencia:** `getRequestTrace` aparece somente na propria
  definicao e dentro de `tryGetRequestId`; `tryGetRequestId` aparece somente na
  propria definicao.
- **Controle positivo:** consumidores reais acessam `RequestTrace` diretamente,
  por exemplo `server/lib/auth_middleware.dart:57`,
  `server/lib/observability.dart:225`, `server/routes/trades/index.dart:332`,
  `server/routes/trades/[id]/messages.dart:230`,
  `server/routes/users/[id]/follow/index.dart:99` e
  `server/routes/conversations/[id]/messages.dart:249`.
- **Por que parece nao chamada:** a API publica promete fallback seguro, mas as
  rotas usam leituras diretas ou wrappers privados locais.
- **O que valida:** substituir os reads diretos pelos wrappers quando o fallback
  for desejado, ou remover os wrappers se a leitura direta for o contrato.
- **O que falsifica:** chamada runtime a `getRequestTrace(context)` ou
  `tryGetRequestId(context)` fora de `request_trace.dart`.

#### P2 — Wrappers especificos de Commander Reference/MTGTop8 seguem test-only

- **Funcoes:** `normalizedCommanderReferenceCandidate` em
  `server/lib/ai/commander_reference_profile_support.dart:49`,
  `buildLoreholdReferenceCardStatsFromProfile` em
  `server/lib/ai/commander_reference_card_stats_support.dart:257` e
  `extractMtgTop8FormatCodeFromSourceUrl` em
  `server/lib/meta/mtgtop8_meta_support.dart:139`.
- **Evidencia de ausencia:** `normalizedCommanderReferenceCandidate` aparece
  apenas na propria definicao; `buildLoreholdReferenceCardStatsFromProfile`
  aparece apenas na propria definicao e em teste; `extractMtgTop8FormatCodeFromSourceUrl`
  aparece apenas na propria definicao e em teste.
- **Controle positivo:** o runtime usa caminhos vizinhos/genericos:
  `buildCommanderReferenceCardStatsFromProfile` e chamado no mesmo modulo em
  `server/lib/ai/commander_reference_card_stats_support.dart:368`, e
  `server/bin/repair_mtgtop8_meta_history.dart:59` usa
  `extractMtgTop8EventIdFromSourceUrl`, nao o helper de format code.
- **Por que parece nao chamada:** os wrappers ficaram como conveniencias
  especificas de teste enquanto o produto usa a funcao generica ou outro campo.
- **O que valida:** ligar os wrappers a runners/rotas reais ou remover os
  wrappers especificos e ajustar testes para o helper generico.
- **O que falsifica:** chamada runtime nova aos tres simbolos fora de `server/test`.

#### P2 — Helpers de sample/diagnostic de optimize permanecem test-only

- **Funcoes:** `buildCandidateQualitySamplePoolSql` em
  `server/lib/ai/candidate_quality_data_support.dart:631` e
  `summarizeAggressiveOptimizeUtilitySamples` em
  `server/lib/ai/optimize_runtime_support.dart:3326`.
- **Evidencia de ausencia:** busca focada encontrou
  `buildCandidateQualitySamplePoolSql` somente na definicao e em
  `server/test/candidate_quality_data_support_test.dart:123`; encontrou
  `summarizeAggressiveOptimizeUtilitySamples` somente na definicao e em
  `server/test/optimize_runtime_support_test.dart:169`.
- **Por que parece nao chamada:** os testes validam SQL/resumo de amostras, mas
  nenhum runner, rota ou service runtime consome esses helpers nesta branch.
- **O que valida:** runner operacional chamar os helpers ao construir pool ou
  resumo de amostras agressivas.
- **O que falsifica:** chamada runtime em `server/bin`, `server/lib` ou
  `server/routes` fora das suites de teste.

#### P2 — `MLKnowledgeService.recordFeedback` ainda nao alimenta `ml_prompt_feedback`

- **Funcao:** `recordFeedback` em `server/lib/ml_knowledge_service.dart:251`.
- **Evidencia de ausencia:** busca por `recordFeedback(` encontrou somente a
  propria definicao. `MLKnowledgeService` e instanciado em
  `server/lib/ai/otimizacao.dart:33`, e esse fluxo chama
  `getContextForDeck`/`generatePromptContext` em `:167`, `:173`, `:361` e
  `:367`, mas nao chama `recordFeedback`.
- **Por que parece nao chamada:** o insert em `ml_prompt_feedback` existe em
  `server/lib/ml_knowledge_service.dart:262`-`:284`, mas nenhuma rota, job ou
  app action aciona essa escrita.
- **O que valida:** rota/app/job de feedback chamar `recordFeedback` com teste
  de contrato e consumo posterior do feedback.
- **O que falsifica:** chamada runtime a `recordFeedback(...)` fora do service.

#### P3 — API manual de metricas do `PerformanceService` segue sem uso app-facing

- **Funcoes:** `startTrace`, `stopTrace`, `addMetric`, `addAttribute`,
  `getLocalStats` e `printLocalStats` em
  `app/lib/core/services/performance_service.dart:110`, `:130`, `:200`, `:210`,
  `:220` e `:248`.
- **Evidencia de ausencia:** busca em `app/lib`, `app/test` e
  `app/integration_test` encontrou esses nomes apenas nas definicoes; excecao:
  `getLocalStats` e chamado internamente por `printLocalStats`.
- **Controle positivo:** a observabilidade viva usa `PerformanceService.instance.init()`
  em `app/lib/main.dart:121`; `PerformanceNavigatorObserver` e instanciado em
  `app/lib/main.dart:208` e chama `startScreenTrace`/`stopScreenTrace` em
  `app/lib/core/services/performance_service.dart:295`, `:307`, `:334` e
  `:339`; `traceAsync` aparece no smoke de observabilidade em
  `app/integration_test/release_observability_smoke_test.dart:51`.
- **Por que parece nao chamada:** a parte automatica do service esta viva, mas a
  API manual/custom metrics/debug nao tem consumidor app-facing confirmado.
- **O que valida:** usar esses metodos em fluxos app reais ou simplificar o
  service para `init`, observer e `traceAsync`.
- **O que falsifica:** chamada app-facing aos metodos manuais em `app/lib`.

## Rodada focada: Card semantics — revalidacao 2026-06-03 05:30 UTC

Escopo desta rodada: nomes hardcoded de cartas, drift entre tags funcionais /
`semantic_tags_v2` / roles de optimize, e avaliacao de utilidade por dados da
carta. Produto/runtime auditado primeiro: `server/lib`, `server/routes` e
`app/lib`. Testes, docs, artefatos e exemplos foram usados apenas como controle
para separar fixtures permitidas de logica de produto.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `9a41032b`.

### Metodo manual focado

- Leitura dos documentos obrigatorios de contexto:
  `docs/hermes-analysis/STRUCTURE_AUDIT.md`,
  `docs/hermes-analysis/PLANO_CORRECAO.md`,
  `docs/hermes-analysis/TECHNICAL_MAP.md`,
  `docs/hermes-analysis/PRODUCT_DIRECTION.md`,
  `docs/CONTEXTO_PRODUTO_ATUAL.md`, `server/manual-de-instrucao.md` e
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md`.
- Leitura dos arquivos-alvo de runtime:
  `server/lib/ai/functional_card_tags.dart`,
  `server/lib/ai/optimization_functional_roles.dart`,
  `server/lib/ai/candidate_quality_data_support.dart`,
  `server/routes/ai/optimize/index.dart` e
  `server/lib/ai/optimize_request_support.dart`.
- Buscas focadas:
  - `rg -n "Sol Ring|Command Tower|Thassa'?s Oracle|Isochron Scepter|Dramatic Reversal|Blood Artist|Boros Charm|..." server/lib server/routes app/lib --glob '*.dart'`.
  - `rg -n "normalizedName\\s*(==|!=|\\.contains)|normalizedName\\.contains|name\\.contains|highPowerNames|premiumLandNames" server/lib server/routes app/lib --glob '*.dart'`.
  - `rg -n "card_function_tags|semantic_tags_v2|summarizeFunctionalTagsForDeck|classifyOptimizationFunctionalRole" server/lib server/routes --glob '*.dart'`.

### Achados revalidados

#### P1 — Classificadores funcionais ainda usam nomes de cartas em runtime

- **Risco:** `inferFunctionalCardTags` mistura texto/tipo com nomes especificos
  para decidir tags. Em `server/lib/ai/functional_card_tags.dart:219`-`:226`,
  ramp aceita `signet`, `talisman`, `sol ring` e `arcane signet` por nome.
  Protecao usa `teferi's protection`, `heroic intervention`, `swiftfoot boots` e
  `lightning greaves` em `:700`-`:717`; aristocrats/drain/payoff usam
  `Blood Artist`/`Zulaport Cutthroat` em `:754`-`:780` e `:887`-`:895`;
  wincon/combo usam `Thassa's Oracle`, `Isochron Scepter` e
  `Dramatic Reversal` em `:859`-`:874`.
- **Risco espelhado:** `server/lib/ai/candidate_quality_data_support.dart:375`-`:379`,
  `:421`-`:428`, `:439`-`:445`, `:472`-`:478`, `:531`-`:542`,
  `:590`-`:605` e `:611`-`:628` repetem checks por nome e ainda aplicam bonus ou
  bracket scope via `highPowerNames`/`premium`.
- **Por que e risco:** cartas com texto equivalente e nome diferente podem ser
  classificadas com menos utilidade que as listas conhecidas; cartas da lista
  recebem utilidade/power por nome antes de um dado versionado ou policy auditavel.
- **O que valida:** mover esses casos para backfill de `card_function_tags` /
  `card_semantic_tags_v2`, ou para policy versionada com `source`, `reason`,
  `scope`, `confidence` e teste. Os classificadores puros devem preferir
  `oracle_text`, `type_line`, `mana_cost`, `cmc` e dados persistidos.
- **O que falsifica:** teste e documentacao declarando cada excecao por nome como
  regra intencional de produto, com policy central e sem listas inline.

#### P1 — Optimize e rebuild ainda usam listas fixas para score/filler/recomendacao

- **Risco:** `server/lib/ai/optimize_runtime_support.dart:406`-`:454` aplica
  `+250` de fixing score para `premiumLandNames` como `command tower` e
  `city of brass`; `:1296`-`:1345` usa uma lista fallback de staples; `:3476`-`:3512`
  carrega fallbacks universais por nomes como `Sol Ring`, `Command Tower`,
  `Cyclonic Rift` e `Rhystic Study`; `:3568`-`:3615` adiciona fillers
  contextuais por identidade/tema a partir de nomes fixos.
- **Risco:** `scoreOptimizeReplacementCandidate` em
  `server/lib/ai/optimize_runtime_support.dart:2317`-`:2355` ainda aceita
  `preferredNames` como bonus direto (`:2338`), mesmo tambem avaliando
  `oracle_text`, `type_line`, CMC, popularidade e rejeicoes.
- **Risco:** `server/lib/ai/rebuild_guided_service.dart:1226`-`:1231` classifica
  ramp por `signet`/`sol ring`/`talisman`; `:1331`-`:1338` e `:1400`-`:1411`
  penalizam ou priorizam utility lands por nome (`Temple of the False God`,
  `Terrain Generator`, `Scavenger Grounds`, etc.).
- **Por que e risco:** essas listas decidem utilidade e prioridade em fluxo de
  produto, nao apenas exemplos. Parte delas pode ser policy legitima, mas hoje fica
  espalhada e sem fonte/versionamento unico nesta branch.
- **O que valida:** centralizar excecoes restantes em modulo/config/tabela de
  policy, ou substituir selecao de staples/fillers por query usando roles
  persistidos, legalidade, identidade de cor, bracket, budget, meta e sinergia.
- **O que falsifica:** contrato testado mostrando que esses nomes sao seeds
  deterministicas controladas e nao interferem no score final fora de fallback
  sem dados.

#### P2 — Rotas experimentais continuam fora do adapter semantico compartilhado

- **Risco:** `server/routes/decks/[id]/recommendations/index.dart:39`-`:57`
  carrega cartas sem `card_function_tags` ou `semantic_tags_v2`; `:110`-`:130`
  recalcula ramp/draw/removal/wipe/protection por heuristicas locais de
  `oracle_text`; `:262`-`:267` recomenda `Command Tower` diretamente quando
  faltam terrenos Commander; `_findStaples` em `:408`-`:438` usa raridade
  `rare/mythic` como proxy de alto impacto.
- **Risco:** `server/routes/ai/weakness-analysis/index.dart:41`-`:59` tambem
  carrega apenas dados basicos da carta; `:114`-`:163` reconta funcoes por texto e
  nomes (`teferi's protection`, `heroic intervention`); `:206`-`:285` retorna
  listas fixas de nomes para ramp, draw, removal, wipes e protecao.
- **Por que e risco:** os endpoints estao documentados como experimentais/not
  proven, mas se forem ligados ao app entregarão recomendacoes que parecem produto
  core sem usar a camada semantica versionada.
- **O que valida:** manter como internos/demo ou, antes de promocao, reutilizar o
  mesmo adapter semantico de deck analysis/optimize e selecionar cartas via dados
  persistidos + legalidade/identidade/bracket.
- **O que falsifica:** ausencia permanente de consumidor app-facing e contrato
  explicito de diagnostico interno, sem promessa de recomendacao produtizada.

#### P1 — Drift: deck analysis prefere `functional_tags`, validator/role delta nao

- **Controle positivo:** `GET /decks/:id/analysis` carrega
  `card_function_tags` e `semantic_tags_v2` em
  `server/routes/decks/[id]/analysis/index.dart:80`-`:96`, e
  `summarizeFunctionalTagsForDeck` prefere `functional_tags` persistidos antes da
  heuristica em `server/lib/ai/functional_card_tags.dart:432`-`:465`.
- **Drift:** `loadOptimizeDeckContext` carrega `semantic_tags_v2`, mas nao
  `card_function_tags`, em `server/lib/ai/optimize_request_support.dart:86`-`:107`
  e monta `allCardData` sem `functional_tags` em `:186`-`:198`. O helper de select
  `:323`-`:339` agrega somente `card_semantic_tags_v2`.
- **Drift:** `classifyOptimizationFunctionalRole` em
  `server/lib/ai/optimization_functional_roles.dart:55`-`:124` usa
  `semantic_tags_v2` primeiro e depois `type_line`/`oracle_text`, mas nao le
  `functional_tags`. `OptimizationValidator` chama esse classificador para cada
  swap em `server/lib/ai/optimization_validator.dart:265`-`:267`.
- **Drift:** `_classifySemanticV2FunctionalRole` escolhe uma entrada v2 por maior
  `role_confidence` e retorna um unico role em
  `server/lib/ai/optimization_functional_roles.dart:127`-`:180`; o delta v2 em
  `:292`-`:349` soma apenas esse role unico por carta. Multi-tag como
  `draw + engine` ou `drain + wincon` pode perder significado secundario.
- **Nuance:** optimize nao e totalmente cego a `card_function_tags`:
  `server/lib/ai/optimize_runtime_support.dart:2650`-`:2658` usa
  `card_function_tags` dentro de SQL de sinais de candidate quality. O gap
  revalidado e o caminho de contexto/validator/role preservation, nao toda a
  superficie de candidate quality.
- **O que valida:** criar adapter unico que receba `functional_tags`,
  `semantic_tags_v2`, `oracle_text`, `type_line`, `mana_cost` e `cmc`, retornando
  conjunto de roles + `primary_role`; usar esse adapter em deck analysis,
  optimize context, validator, quality gate e candidate quality.
- **O que falsifica:** teste provando que uma carta com `functional_tags`
  persistido e sem v2 recebe o mesmo role em analysis, validator e quality gate,
  e que v2 multi-tag preserva roles secundarios no delta.

### Ocorrencias permitidas ou intencionais

- **Permitidas como exemplos/UX:** placeholder de import em
  `app/lib/features/decks/screens/deck_import_screen.dart:383`-`:392` e
  `:591`-`:592`; sugestoes de busca do life counter em
  `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:39`-`:44`;
  comentarios de contrato em `server/routes/cards/resolve/batch/index.dart:9`-`:24`;
  mensagem de erro de import em `server/routes/import/index.dart:176`-`:183`.
- **Permitida como seed/corpus versionado:** o perfil Lorehold em
  `server/lib/ai/commander_reference_profile_support.dart:6`-`:17` declara
  versao/source e inclui pacotes/avoid examples em `:117`-`:190`. Ainda e runtime,
  mas foi classificado como seed/profile controlado, nao como heuristica generica
  escondida.
- **Excecao intencional com ressalva:** `server/lib/edh_bracket_policy.dart:134`-`:142`
  usa listas curadas para infinite combos e Game Changers; as listas aparecem em
  `:271`-`:294`. Isso faz sentido por depender de regra externa/curadoria, mas
  deve manter fonte, versao e teste dedicado.

## Rodada focada: Classes not used — revalidacao 2026-06-03 03:00 UTC

Escopo desta rodada: somente classes sem uso runtime confirmado. Nao foi feita
auditoria ampla de funcoes sem chamador, imports/ciclos, tabelas PostgreSQL,
duplicacao ou coerencia geral entre modulos fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs` apos uma tentativa inicial bloqueada por
  `.git/index.lock` transitorio que desapareceu antes de qualquer remocao.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `071386f4`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor base cobre `server/lib` e
`server/routes`, nao cobre `app/lib` e tambem nao constroi grafo de chamadas.
A propria docstring do script diz que achados de "nao usado" exigem validacao
manual com grep. A execucao reescreveu o bloco gerado de
`STRUCTURE_AUDIT.md` e duplicou historico manual; essa escrita automatica foi
revertida, mantendo apenas os achados abaixo, revalidados por busca focada.

### Metodo manual focado

- `rg -n "class (LifeCounterScreen|DeckCard|DeckProgressChip|LotusPresentationMode)\\b|\\b(LifeCounterScreen|DeckCard|DeckProgressChip|LotusPresentationMode)\\b" app/lib app/test app/integration_test --glob '*.dart'`.
- `rg -n "\\bLifeCounterScreen\\(" app/lib app/test app/integration_test --glob '*.dart'`.
- `rg -n "\\bDeckCard\\(" app/lib app/test app/integration_test --glob '*.dart'`.
- `rg -n "\\bDeckProgressChip\\(" app/lib app/test app/integration_test --glob '*.dart'`.
- `rg -n "\\bLotusPresentationMode\\b|lotus_presentation_mode\\.dart|\\.enter\\(|\\.exit\\(" app/lib app/test app/integration_test --glob '*.dart'`.
- Varredura auxiliar de classes em `app/lib` com baixa contagem de referencias,
  seguida de verificacao manual para descartar `State` privados, observers e
  providers ativos.

### Achados revalidados

#### P1 — `LifeCounterScreen` legado segue fora do caminho runtime do app

- **Classe:** `LifeCounterScreen` em
  `app/lib/features/home/life_counter_screen.dart:61`, construtor em `:66`.
- **Rota ativa:** `app/lib/main.dart:282`-`:283` registra
  `lifeCounterRoutePath` com `const LotusLifeCounterScreen()`, importado em
  `app/lib/main.dart:54`.
- **Evidencia de ausencia em runtime app:** busca por `LifeCounterScreen(` em
  `app/lib` encontrou somente o construtor da propria classe. As chamadas reais
  encontradas estao em testes: `app/test/features/home/life_counter_screen_test.dart:36`
  e `app/test/features/home/life_counter_clone_proof_test.dart:277`.
- **Contexto de teste:** `app/test/README.md:137` diz que a suite e legada de
  paridade historica e que o caminho vivo segue em `LotusLifeCounterScreen`;
  `app/test/README.md:149` reforca que o caminho oficial do contador hoje nao e
  mais `LifeCounterScreen`.
- **Por que parece nao usada:** a tela ainda existe em `app/lib` e tem testes,
  mas o roteamento de produto e a malha viva usam `LotusLifeCounterScreen`.
- **O que valida:** remover a tela legada ou move-la para harness/fixture
  explicitamente documentado, ajustando os testes para nao sugerirem cobertura
  runtime.
- **O que falsifica:** `app/lib` passar a importar e instanciar
  `LifeCounterScreen` em uma rota ou superficie viva.

#### P2 — `DeckCard` permanece testado, mas sem uso confirmado na listagem real

- **Classe:** `DeckCard` em
  `app/lib/features/decks/widgets/deck_card.dart:17`, construtor em `:22`.
- **Evidencia de ausencia em `app/lib`:** busca por import de `deck_card.dart`
  em `app/lib` nao retornou ocorrencias, e busca por `DeckCard(` em `app/lib`
  encontrou somente o construtor.
- **Usos encontrados:** apenas testes importam e instanciam o widget:
  `app/test/features/decks/widgets/deck_card_test.dart:4`/`:9` e
  `app/test/features/decks/widgets/deck_card_overflow_test.dart:4`/`:47`.
- **Controles positivos:** as listagens reais usam widgets locais:
  `_RecentDeckCard` em `app/lib/features/home/home_screen.dart:523`/`:529`,
  `_CommunityDeckCard` em `app/lib/features/community/screens/community_screen.dart:312`/`:732`,
  `_FollowingDeckCard` em `community_screen.dart:515`/`:946`, e
  `_DeckGalleryCard` em `app/lib/features/decks/screens/deck_list_screen.dart:626`/`:1401`.
- **Por que parece nao usada:** ha uma implementacao generica de card de deck,
  mas as superficies ativas usam implementacoes privadas divergentes.
- **O que valida:** reutilizar `DeckCard` na listagem real de decks, ou remover
  `DeckCard` e seus testes se a divergencia local for a decisao de produto.
- **O que falsifica:** import ou chamada `DeckCard(...)` em `app/lib` que a
  busca focada nao encontrou.

#### P2 — `DeckProgressChip` nao tem chamada de construtor confirmada

- **Classe:** `DeckProgressChip` em
  `app/lib/features/decks/widgets/deck_progress_indicator.dart:286`, construtor
  em `:292`.
- **Evidencia de ausencia:** busca por `DeckProgressChip(` em `app/lib`,
  `app/test` e `app/integration_test` encontrou somente o construtor.
- **Controle positivo:** `DeckProgressIndicator` no mesmo arquivo esta ativo:
  definido em `app/lib/features/decks/widgets/deck_progress_indicator.dart:14`
  e usado por `app/lib/features/decks/widgets/deck_details_overview_tab.dart:328`
  e `app/lib/features/decks/screens/deck_details_screen.dart:403`.
- **Por que parece nao usada:** o arquivo mistura o indicador vivo com um chip
  compacto que nao e chamado por cards/listas/testes.
- **O que valida:** chamar `DeckProgressChip` em uma superficie real ou remover
  a classe mantendo `DeckProgressIndicator`.
- **O que falsifica:** chamada direta a `DeckProgressChip(...)` em `app/lib` ou
  teste que prove contrato planejado para esse chip.

#### P2 — `LotusPresentationMode` parece utilitario morto no fluxo Lotus atual

- **Classe:** `LotusPresentationMode` em
  `app/lib/features/home/lotus/lotus_presentation_mode.dart:4`.
- **API exposta:** `enter()` em `:15` e `exit()` em `:26`.
- **Evidencia de ausencia:** busca por `LotusPresentationMode`,
  `lotus_presentation_mode.dart`, `.enter(` e `.exit(` em `app/lib`, `app/test`
  e `app/integration_test` encontrou somente a propria classe/metodos.
- **Por que parece nao usada:** o modo fullscreen/orientacao existe como helper,
  mas `LotusLifeCounterScreen` nao importa o arquivo nem chama `enter()`/`exit()`.
- **O que valida:** chamar `LotusPresentationMode.enter/exit` no lifecycle do
  Lotus com teste de contrato, ou remover o helper.
- **O que falsifica:** import vivo de `lotus_presentation_mode.dart` e chamadas
  de `LotusPresentationMode.enter/exit`.

### Controles positivos e candidatos descartados

- `LotusLifeCounterScreen` nao esta unused: `app/lib/main.dart:282`-`:283`
  instancia a rota ativa, e ha muitos testes/integration tests importando
  `lotus_life_counter_screen.dart`.
- `DeckProgressIndicator` nao esta unused: ele e usado na visao geral e na tela
  de detalhes do deck.
- `PerformanceNavigatorObserver` e `AppObservabilityNavigatorObserver` foram
  descartados como candidatos porque `app/lib/main.dart:208`-`:209` instancia
  ambos em `navigatorObservers`.
- `CardRecognitionService` foi descartado porque
  `app/lib/features/scanner/providers/scanner_provider.dart:25` instancia o
  servico; scanner continua deferido em produto, mas a classe tem chamador.
- Classes privadas `State` com baixa contagem textual foram descartadas porque
  sao pareadas por `createState()` com seus widgets, nao classes soltas.

## Rodada focada: Coerencia entre modulos `server/lib` <-> `server/routes` <-> `app/lib` — revalidacao 2026-06-02 23:00 UTC

Escopo desta rodada: somente coerencia entre chamadas do app, rotas Dart Frog e
helpers em `server/lib`. Nao foi feita auditoria ampla de classes, funcoes sem
chamador, imports/ciclos, tabelas PostgreSQL ou duplicacao fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `69b0c42b`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor base cobre `server/lib` e
`server/routes`, nao constroi grafo app->rota->helper e nao valida ownership por
contrato. A execucao reescreveu o bloco gerado de `STRUCTURE_AUDIT.md` e
introduziu duplicacao de historico manual; essa escrita automatica foi revertida
por patch reverso, e os achados abaixo foram revalidados por leitura direta e
buscas focadas.

### Metodo manual focado

- `rg -n "ai/optimize|optimize/jobs|ai/archetypes|ai/rebuild|/analysis|ai-analysis|recommendations|weakness-analysis" app/lib server/routes server/lib --glob '*.dart'`.
- `rg -n "loadOptimizeDeckContext|SELECT name, format FROM decks|WHERE id = @id|dc.deck_id = @id|job.userId|context.read<String>|getUserId" server/routes/ai server/routes/decks server/lib/ai --glob '*.dart'`.
- `rg -n "apiClient\\.(get|post|put|patch|delete)\\(" app/lib --glob '*.dart'`.
- Leitura direta dos providers de deck em `app/lib/features/decks/providers`,
  das rotas de AI/decks correspondentes e dos helpers em `server/lib/ai`.

### Achados revalidados

#### P1 — `POST /ai/optimize` ainda perde ownership ao atravessar `routes -> lib`

- **Chamador app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:56`
  chama `apiClient.post('/ai/optimize', payload)`; o payload registra
  `deck_id` em `:48` e e montado para deck do usuario.
- **Rota:** `server/routes/ai/optimize/index.dart:401`-`:405` ate tenta ler
  `userId`, mas a chamada para `optimize_request.loadOptimizeDeckContext` em
  `:549`-`:558` passa `deckId`, `archetype`, modo e preferencias sem passar
  `userId`.
- **Helper:** `server/lib/ai/optimize_request_support.dart:53`-`:62` nao tem
  parametro de usuario; a query de deck usa
  `SELECT name, format FROM decks WHERE id = @id` em `:66`-`:72`, e as cartas
  sao carregadas por `WHERE dc.deck_id = @id` em `:107`-`:110` e `:132`-`:135`.
- **Por que e incoerente:** o contrato global em
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md` diz que rotas protegidas leem o
  usuario autenticado e que ownership mobile fica no backend; as rotas estaveis
  de deck fazem gate `deck_id + user_id`, mas este fluxo app-facing perde essa
  fronteira dentro de `server/lib`.
- **O que valida:** adicionar `userId` obrigatorio a `loadOptimizeDeckContext`,
  filtrar `decks` por `id + user_id`, carregar `deck_cards` via join com
  `decks` owner-scoped e criar teste owner vs non-owner para `POST /ai/optimize`
  nos caminhos sync e async.
- **O que falsifica:** contrato explicito e testado dizendo que optimize pode
  analisar deck privado de outro usuario por UUID, ou middleware/helper externo
  comprovado aplicando owner-scope antes dessas queries.

#### P1 — `POST /ai/archetypes` e consumido pelo app, mas carrega deck/cartas sem owner-scope

- **Chamador app:** `app/lib/features/decks/providers/deck_provider_support_mutation.dart:168`-`:173`
  envia `POST /ai/archetypes` com `{'deck_id': deckId}`.
- **Rota:** `server/routes/ai/archetypes/index.dart:27`-`:32` le `deck_id`,
  mas nao le `context.read<String>()`; `:39`-`:42` busca
  `SELECT name, format FROM decks WHERE id = @id` e `:54`-`:60` carrega cartas
  por `WHERE dc.deck_id = @id`.
- **Por que e incoerente:** o endpoint e apresentado ao app como opcoes de
  estrategia para o deck autenticado, mas a rota usa existencia global do deck,
  nao ownership. Isso tambem contamina cache/reference profile antes de qualquer
  regra de permissao.
- **O que valida:** ler `userId` na rota, buscar deck por `id + user_id`,
  carregar cartas atraves de deck owner-scoped e adicionar teste non-owner que
  retorne 404 antes de montar prompt/cache.
- **O que falsifica:** mover o endpoint para contrato publico explicito, com
  teste e doc dizendo quais decks podem ser analisados sem ownership.

#### P1 — Polling de optimize ainda preserva jobs ownerless como legiveis

- **Chamador app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:190`-`:194`
  faz polling em `/ai/optimize/jobs/$jobId`.
- **Store:** `server/lib/ai/optimize_job.dart:25`-`:30` aceita `String? userId`;
  o job em memoria recebe esse valor nullable em `:37`-`:42`, e a persistencia
  grava `@user_id` em `:49`-`:64`.
- **Rota:** `server/routes/ai/optimize/jobs/[id].dart:26`-`:39` le o usuario,
  mas so bloqueia quando `job.userId != null && job.userId != userId`; se o job
  estiver sem owner, qualquer usuario autenticado com o id recebe `job.toJson()`
  em `:49`.
- **Por que e incoerente:** o app trata o job como continuation de um optimize
  de deck privado. Mesmo que a criacao normal tente passar `userId`, a API
  app-facing e a store ainda aceitam e expõem o estado ownerless.
- **O que valida:** tornar `userId` obrigatorio para jobs app-facing, recusar
  criacao async sem usuario e alterar o polling para retornar 404 quando
  `job.userId == null || job.userId != userId`.
- **O que falsifica:** separar jobs internos ownerless em rota interna nao
  app-facing, com token interno e teste que prove que `/ai/optimize/jobs/:id`
  publico nunca retorna esses jobs.

#### P2 — Rotas experimentais de deck/AI seguem sem contrato de ownership antes de promocao app-facing

- **Rotas:** `server/routes/decks/[id]/recommendations/index.dart:16`-`:27`
  busca `decks` por `id` e `:39`-`:58` busca cartas por `dc.deck_id`; e
  `server/routes/decks/[id]/simulate/index.dart:13`-`:25` simula cartas por
  `dc.deck_id` sem ler usuario. A busca focada em `app/lib` nao encontrou
  chamadas atuais para `/decks/:id/recommendations` nem `/decks/:id/simulate`.
- **Documento de contrato:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md:152`
  marca `POST /decks/:id/recommendations` como experimental e `not proven`, com
  nota para preferir `/ai/optimize` app-facing.
- **Por que e incoerente:** essas rotas ficam no namespace privado de decks e
  compartilham dados sensiveis de deck, mas nao seguem a fronteira owner-scoped
  das rotas estaveis. Como nao ha consumidor app atual, o risco imediato e
  promocao acidental ou uso por automacao antes de definir o contrato.
- **O que valida:** ou remover/descontinuar essas rotas, ou aplicar o mesmo
  gate `id + user_id` das rotas de deck e adicionar teste non-owner antes de
  qualquer uso em `app/lib`.
- **O que falsifica:** documenta-las como publicas, restringindo a decks
  `is_public=true`, com teste de private deck negado e app atualizado para esse
  contrato.

### Controles positivos

- `POST /ai/rebuild` nao foi promovido como achado: o app chama
  `app/lib/features/decks/providers/deck_provider_support_ai.dart:165`-`:168`,
  e a rota busca o deck em `server/routes/ai/rebuild/index.dart:62`-`:78` com
  `WHERE d.id = @deckId AND d.user_id = @userId`.
- `GET /decks/:id/analysis` nao foi promovido como achado: o app chama
  `app/lib/features/decks/providers/deck_provider_support_fetch.dart:135`-`:140`,
  e a rota faz gate em `server/routes/decks/[id]/analysis/index.dart:16`-`:26`
  antes de ler cartas.
- `POST /decks/:id/ai-analysis` tambem fica fora dos achados: o app chama
  `app/lib/features/decks/providers/deck_provider_support_fetch.dart:273`-`:280`,
  e a rota busca `decks` por `id + user_id` em
  `server/routes/decks/[id]/ai-analysis/index.dart:34`-`:40`.
- `POST /decks/:id/pricing` foi usado como controle de padrao: a rota valida
  ownership em `server/routes/decks/[id]/pricing/index.dart:28`-`:35` antes de
  carregar cartas por `deckId`.

## Rodada focada: Duplicated or similar logic — revalidacao 2026-06-02 19:00 UTC

Escopo desta rodada: somente logica duplicada ou similar com risco de drift.
Nao foi feita auditoria ampla de classes, funcoes sem chamador, imports,
ciclos, tabelas PostgreSQL ou coerencia geral entre `server/lib`,
`server/routes` e `app/lib` fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `0504d64b`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor base usa regex textual e a heuristica de
"funcoes publicas duplicadas" mistura SQL, palavras em prompts e helpers reais.
A execucao tambem reescreve um bloco gerado amplo em `STRUCTURE_AUDIT.md`;
essa escrita automatica foi descartada nesta rodada. Os achados abaixo foram
revalidados por leitura direta e buscas focadas nos simbolos duplicados.

### Metodo manual focado

- `rg -n "resolveOptimizeArchetype|_looksLikeComboPiece|_looksLikeEnabler|_looksLikeEngine|_looksLikePayoff|_looksLikeWincon|_isBasicLandName|getMainType|calculateCmc|_trustStatsSql|_responseTimeSql|_shippingTimeSql|_buildTrustInsight|_requestId|_logInvalidPayload" server/lib server/routes --glob '*.dart'`.
- `rg -n "NM|LP|MP|HP|DMG|validConditions|condition" server/routes/decks server/routes/binder server/routes/community/marketplace --glob '*.dart'`.
- Leitura direta dos corpos de funcao em `server/lib/ai`, rotas de `trades`,
  `conversations`, `community`, `decks`, `binder` e
  `commander-reference`.

### Achados revalidados

#### P1 — `resolveOptimizeArchetype` continua com duas semanticas runtime

- **Simbolos:** `resolveOptimizeArchetype` em
  `server/lib/ai/deck_state_analysis.dart:573` e
  `server/lib/ai/optimize_runtime_support.dart:3369`.
- **Consumidores confirmados:** `server/lib/ai/rebuild_guided_service.dart:171`
  usa a versao de `deck_state_analysis`; `server/lib/ai/optimize_request_support.dart:289`
  e `:294` usam a versao de `optimize_runtime_support`.
- **Divergencia concreta:** a versao de deck state aceita
  `requestedArchetype` nullable, trata `general` e `tempo` como genericos e
  retorna `detected ?? 'midrange'`; a versao de optimize exige string,
  considera `unknown`, trata `goodstuff` como generico e so promove detected
  especifico em `{aggro, control, combo, stax, tribal}`.
- **Por que parece duplicacao real:** as duas funcoes respondem ao mesmo
  contrato de produto, "qual arquetipo efetivo usar", mas rebuild e optimize
  podem divergir para entradas como `tempo`, `general`, `goodstuff`, vazio e
  `unknown`.
- **O que valida:** extrair um resolver unico com testes para null/vazio,
  `unknown`, `tempo`, `general`, `goodstuff` e detected especifico; fazer
  optimize e rebuild chamarem esse resolver.
- **O que falsifica:** evidencia de contrato intencional separado por fluxo,
  documentado e coberto por testes que provem a divergencia esperada.

#### P1 — Heuristicas de roles funcionais altos existem em dois classificadores com regras diferentes

- **Simbolos em `functional_card_tags`:**
  `_looksLikeWincon`, `_looksLikeComboPiece`, `_looksLikeEngine`,
  `_looksLikePayoff`, `_looksLikeEnabler` em
  `server/lib/ai/functional_card_tags.dart:859`, `:868`, `:877`, `:887` e
  `:898`.
- **Simbolos em optimize roles:** os mesmos conceitos aparecem em
  `server/lib/ai/optimization_functional_roles.dart:370`, `:376`, `:383`,
  `:388` e `:394`.
- **Divergencia concreta:** `functional_card_tags` usa `normalizedName` para
  nomes conhecidos como `thassa's oracle`, `isochron scepter`,
  `dramatic reversal`, `blood artist`, `greaves` e `boots`, alem de padroes de
  `oracle_text`; `optimization_functional_roles` usa apenas `oracle_text`,
  outros padroes de engine/payoff/enabler e retorna um role unico no fluxo de
  optimize.
- **Por que parece duplicacao real:** deck analysis, candidate quality,
  validator e optimize podem classificar a mesma carta com papeis diferentes,
  especialmente quando nome conhecido e texto funcional equivalente entram por
  caminhos diferentes.
- **O que valida:** um adapter compartilhado que receba nome, `oracle_text`,
  `type_line`, `functional_tags`, `semantic_tags_v2`, `mana_cost` e `cmc`,
  retornando conjunto de roles mais `primary_role`.
- **O que falsifica:** testes de contrato que demonstrem que esses dois
  classificadores sao intencionalmente separados e que a divergencia nao afeta
  swaps, analise nem quality gate.

#### P1/P2 — Deteccao de terreno basico tem quatro variantes

- **Simbolos:** `_isBasicLandName` em
  `server/lib/ai/optimize_runtime_support.dart:4184`,
  `server/lib/generated_deck_validation_service.dart:752`,
  `server/lib/meta/meta_deck_reference_support.dart:890` e
  `server/routes/ai/commander-reference/index.dart:621`.
- **Divergencia concreta:** optimize compara nomes com hifen
  (`snow-covered plains`), generated validation aceita prefixo
  `startsWith('snow-covered ...')`, meta reference usa forma sem hifen
  (`snow covered plains`) e commander-reference nao aceita snow basics.
- **Por que parece duplicacao real:** filtros de optimize, validacao de deck
  gerado, meta reference e commander-reference podem discordar sobre a mesma
  carta basica ou snow basic.
- **O que valida:** helper unico para basic/snow-basic normalizando hifen,
  espacos e faces, usado nos quatro fluxos com testes.
- **O que falsifica:** prova de que commander-reference deve excluir snow
  basics enquanto os outros fluxos devem aceitar, documentada e testada.

#### P2 — Trust social repete SQL e serializer entre trades e marketplace

- **Simbolos:** `_trustStatsSql`, `_responseTimeSql`, `_shippingTimeSql` e
  `_buildTrustInsight` em `server/routes/trades/index.dart:557`, `:569`,
  `:588` e `:603`; mesmos helpers em detalhe de trade em
  `server/routes/trades/[id]/index.dart:260`, `:272`, `:291` e `:306`.
- **Duplicacao inline adicional:** marketplace repete os LATERALs de trust em
  `server/routes/community/marketplace/index.dart:131`-`:162` e o serializer
  `_buildTrustInsight` em `:316`.
- **Por que parece duplicacao real:** listagem de trades, detalhe de trade e
  marketplace retornam o mesmo conceito app-facing de `trust`, mas qualquer
  ajuste em `has_insufficient_history`, profile completeness, response time ou
  shipping time precisa ser aplicado em tres locais.
- **O que valida:** helper compartilhado de SQL/serializacao de trust social,
  com teste comparando shape de listagem, detalhe e marketplace.
- **O que falsifica:** contratos app-facing diferentes por endpoint,
  explicitamente documentados e testados.

#### P2 — Request id e log de payload invalido estao copiados em rotas sociais

- **Simbolos:** `_requestId` e `_logInvalidPayload` em
  `server/routes/conversations/[id]/messages.dart:247`/`:255`,
  `server/routes/trades/[id]/messages.dart:228`/`:236`,
  `server/routes/trades/[id]/respond.dart:154`/`:162`,
  `server/routes/trades/[id]/status.dart:260`/`:268` e
  `server/routes/trades/index.dart:330`/`:338`. `server/routes/users/[id]/follow/index.dart:97`
  tambem tem `_requestId`.
- **Duplicacao concreta:** todos tentam `context.read<RequestTrace>().requestId`,
  caem para header `x-request-id` ou `n/a`, tentam `context.read<String>()` para
  user id e escrevem log `[social_write] invalid_payload`.
- **Controle positivo:** `server/lib/request_trace.dart:48` e `:51` ja expoem
  wrappers `getRequestTrace` e `tryGetRequestId`, mas essas rotas usam copias
  locais em vez do helper compartilhado.
- **O que valida:** helper unico para request id e log social invalid payload,
  com preservacao dos campos endpoint/reason/user/resource.
- **O que falsifica:** necessidade comprovada de formato de log divergente por
  rota, documentada e coberta.

#### P2/P3 — Condicao de carta e calculos CMC/tipo continuam duplicados em rotas

- **Condicao:** `_validateCardCondition` em `server/routes/decks/[id]/index.dart:520`,
  `_validateCondition` em `server/routes/decks/[id]/cards/index.dart:400` e
  `server/routes/decks/[id]/cards/set/index.dart:245` normalizam invalido para
  `NM`; `server/routes/binder/index.dart:276` e
  `server/routes/binder/[id]/index.dart:341` rejeitam invalido com `400`;
  marketplace filtra somente se `validConditions.contains(...)` em
  `server/routes/community/marketplace/index.dart:39`.
- **CMC/tipo:** `getMainType` e `calculateCmc` sao copiados em
  `server/routes/community/decks/[id].dart:91`/`:104` e
  `server/routes/decks/[id]/index.dart:405`/`:419`; `server/routes/decks/[id]/simulate/index.dart:171`
  possui outra variante `_calculateCmc`.
- **Por que parece duplicacao real:** o mesmo dominio de condition/CMC/tipo tem
  regras locais por endpoint, algumas tolerantes e outras estritas, sem helper
  ou contrato comum que explique a diferenca.
- **O que valida:** helper compartilhado para condition com modos
  `normalize`/`reject`, e helper comum de CMC/tipo usado por rotas privadas,
  publicas e simulacao.
- **O que falsifica:** contrato documentado dizendo quais endpoints devem
  normalizar versus rejeitar condition, e testes preservando essas diferencas.

### Controle negativo

O wrapper `resolveOptimizeArchetype` em `server/routes/ai/optimize/index.dart:56`
nao foi contado como duplicacao de corpo porque delega para
`optimize_support.resolveOptimizeArchetype` em `:60`-`:63`. O achado real fica
entre `server/lib/ai/deck_state_analysis.dart` e
`server/lib/ai/optimize_runtime_support.dart`.

## Rodada focada: PostgreSQL tables not used — revalidacao 2026-06-02 15:00 UTC

Escopo desta rodada: somente tabelas PostgreSQL persistidas sem consumidor
runtime claro. Nao foi feita auditoria ampla de classes, funcoes, imports,
ciclos, duplicacao ou coerencia entre `server/lib`, `server/routes` e `app/lib`
fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `cc4418f8`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor base faz inventario textual de
`FROM`/`JOIN`/`CREATE TABLE` em `server/lib` e `server/routes`, mas nao separa
escrita de leitura nem cobre todos os migradores/CLIs. A execucao tambem
reescreve um bloco gerado amplo em `STRUCTURE_AUDIT.md`; essa escrita automatica
foi descartada nesta rodada, e os achados abaixo foram revalidados por buscas
SQL focadas em `server/database_setup.sql`, `server/bin`, `server/lib`,
`server/routes` e `app/lib`.

### Metodo manual focado

- `rg -n "\b(deck_matchups|deck_weakness_reports|ml_prompt_feedback|commander_reference_decks|commander_reference_deck_cards|commander_reference_deck_analysis)\b" server/database_setup.sql server/bin server/lib server/routes app/lib --glob '*.dart' --glob '*.sql'`.
- `rg -n "\b(FROM|JOIN)\s+(deck_matchups|deck_weakness_reports|commander_reference_decks|commander_reference_deck_cards)\b" server/routes server/lib server/bin app/lib --glob '*.dart'`.
- `rg -n "\b(SELECT|FROM|JOIN|INSERT INTO|UPDATE|DELETE FROM)\s+(deck_matchups|deck_weakness_reports|ml_prompt_feedback|commander_reference_decks|commander_reference_deck_cards|commander_reference_deck_analysis)\b" server/routes server/lib server/bin app/lib --glob '*.dart'`.
- `rg -n "recordFeedback\(" server/lib server/routes server/bin server/test app/lib --glob '*.dart'`.

### Achados revalidados

#### P2 — `deck_matchups` continua write-only no produto atual

- **Tabela:** `deck_matchups`, definida em
  `server/database_setup.sql:162`.
- **Escrita confirmada:** `server/routes/ai/simulate-matchup/index.dart:360`
  faz `INSERT INTO deck_matchups (...) ON CONFLICT ... DO UPDATE`.
- **Ausencia de leitura confirmada:** a busca por
  `FROM/JOIN deck_matchups` em `server/routes`, `server/lib`, `server/bin` e
  `app/lib` nao retornou consumidor runtime.
- **Por que parece nao usada:** o endpoint experimental persiste o resultado do
  matchup, mas a resposta do proprio request ja contem a simulacao calculada; nao
  ha dashboard, cache, rota de historico ou recomendador lendo a tabela.
- **O que valida:** endpoint/job/UI consultar `deck_matchups` com teste de
  contrato, ou documentar a tabela como log bruto com retencao.
- **O que falsifica:** `rg "\b(FROM|JOIN)\s+deck_matchups\b" server app`
  encontrar leitura real fora de migracao/verificacao de schema.

#### P2 — `deck_weakness_reports` persiste fraquezas, mas nao tem workflow de leitura/addressing

- **Tabela:** `deck_weakness_reports`, definida em
  `server/database_setup.sql:363` com campo `addressed` em `:371`.
- **Escrita confirmada:** `server/routes/ai/weakness-analysis/index.dart:374`
  faz `INSERT INTO deck_weakness_reports`.
- **Ausencia de leitura/update confirmada:** a busca por
  `FROM/JOIN deck_weakness_reports` em `server/routes`, `server/lib`,
  `server/bin` e `app/lib` nao retornou consumidor; `addressed` aparece apenas
  no schema/verificador.
- **Por que parece nao usada:** a rota experimental devolve a analise no
  response atual, mas o historico salvo nao e recuperado nem marcado como
  tratado por nenhum fluxo confirmado.
- **O que valida:** criar leitura por deck/usuario, update de `addressed` e
  teste de contrato, ou remover/documentar a persistencia como log bruto.
- **O que falsifica:** leitura runtime da tabela ou update real de `addressed`
  fora de migradores/verificadores de schema.

#### P2 — `ml_prompt_feedback` ainda nao coleta feedback real

- **Tabela:** `ml_prompt_feedback`, criada em
  `server/bin/migrate_ml_knowledge.dart:159`.
- **Helper de escrita:** `MLKnowledgeService.recordFeedback` em
  `server/lib/ml_knowledge_service.dart:251` insere na tabela em `:264`.
- **Ausencia de chamador confirmada:** `rg "recordFeedback\("` em
  `server/lib`, `server/routes`, `server/bin`, `server/test` e `app/lib`
  encontrou somente a propria definicao.
- **Leitura existente:** `/ai/ml-status` conta linhas em
  `server/routes/ai/ml-status/index.dart:98`, mas isso e contador operacional,
  nao consumo de feedback para aprendizado ou produto.
- **Por que parece nao usada:** ha schema e helper, mas nenhum fluxo app/job/rota
  registra feedback do usuario.
- **O que valida:** rota/app/job chamar `recordFeedback` e algum consumidor usar
  o feedback, com teste de contrato.
- **O que falsifica:** chamada runtime nova a `recordFeedback(...)` fora do
  service.

#### P3 — `commander_reference_decks` e `commander_reference_deck_cards` seguem raw corpus sem leitura runtime direta

- **Tabelas:** `commander_reference_decks` e
  `commander_reference_deck_cards`, definidas em
  `server/lib/ai/commander_reference_deck_corpus_support.dart:1177` e `:1200`.
- **Escrita confirmada:** o apply do corpus faz insert/upsert em
  `commander_reference_decks` em `:1245`, delete de cards em `:1329` e insert
  em `commander_reference_deck_cards` em `:1345`.
- **Controle positivo:** o produto le o agregado
  `commander_reference_deck_analysis` em
  `server/lib/ai/commander_reference_deck_corpus_support.dart:389`, e esse
  agregado e persistido em `:1394`.
- **Ausencia de leitura direta confirmada:** a busca por `FROM/JOIN` nas duas
  tabelas brutas nao retornou consumidor; apareceu apenas o delete de refresh
  de `commander_reference_deck_cards`.
- **Por que parece parcialmente usada:** as tabelas brutas guardam lineage/audit
  do corpus, mas o runtime confirmado usa somente o resumo agregado.
- **O que valida:** documentar retencao/reprocessamento das tabelas brutas,
  adicionar job que releia o raw corpus, ou persistir apenas o agregado.
- **O que falsifica:** `SELECT`/`JOIN` runtime real nas tabelas brutas fora do
  fluxo de apply/refresh.

### Controle negativo

Nenhum novo candidato de tabela persistida sem consumidor claro apareceu nesta
rodada alem dos itens ja revalidados. `schema_migrations` continua fora do
achado por ser tabela interna do migrador.

## Rodada focada: Broken imports and circular dependencies — revalidacao 2026-06-02 11:00 UTC

Escopo desta rodada: somente imports locais quebrados e dependencias circulares
em Dart. Nao foi feita auditoria ampla de classes nao usadas, funcoes sem
chamador, tabelas PostgreSQL, duplicacao ou coerencia entre `server/lib`,
`server/routes` e `app/lib` fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `eecb2f95`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor base cobre `server/lib` e
`server/routes`, mas nao cobre `app/lib` nem `server/bin`. Por isso o resultado
`Imports quebrados: 0` e valido apenas para o recorte textual do script; os
achados abaixo foram revalidados por resolucao manual/automatizada de imports
locais a partir do arquivo origem e por `dart analyze` no backend.

### Validacao complementar

- Resolver focado em imports Dart locais (`app/lib`, `server/lib`,
  `server/routes`, `server/bin`) encontrou **3 imports quebrados** e **1 SCC**
  com mais de um arquivo.
- `dart analyze` em `server/`: **falhou** com `uri_does_not_exist` para
  `bin/local_test_server.dart:3`.
- `flutter analyze --no-pub --no-fatal-infos` em `app/`: **nao conclusivo**
  para imports do app porque este checkout nao possui resolucao de dependencias
  Flutter; o analyzer reportou milhares de `uri_does_not_exist` para pacotes
  externos e para `package:manaloom/...` antes de isolar os imports relativos.

### Achados revalidados

#### P1 — Entry point local do backend importa artefato Dart Frog ausente

- **Import quebrado:** `server/bin/local_test_server.dart:3` importa
  `../.dart_frog/server.dart`.
- **Alvo resolvido:** `server/.dart_frog/server.dart`.
- **Evidencia:** `ls server/.dart_frog` retornou `No such file or directory`.
  `dart analyze` em `server/` falhou com:
  `Target of URI doesn't exist: '../.dart_frog/server.dart'`.
- **Por que parece quebrado:** o arquivo gerado pelo Dart Frog nao existe no
  checkout atual, mas o import e estatico e participa do analyzer.
- **O que valida:** gerar/restaurar `server/.dart_frog/server.dart` antes do
  analyze, ou alterar/remover o entry point para nao importar artefato ausente
  em clone limpo.
- **O que falsifica:** `dart analyze` verde em `server/` com
  `server/.dart_frog/server.dart` presente ou com outro entry point valido.

#### P1 — Dois imports relativos do app escapam de `app/lib`

- **Import quebrado:** `app/lib/features/decks/widgets/deck_analysis_tab.dart:5`
  importa `../../../../core/utils/mana_helper.dart`.
- **Alvo resolvido:** `app/core/utils/mana_helper.dart`.
- **Arquivo existente esperado:** `app/lib/core/utils/mana_helper.dart`.
- **Por que parece quebrado:** a partir de
  `app/lib/features/decks/widgets/`, quatro `..` sobem ate `app/`, nao ate
  `app/lib/`. O import equivalente dentro de `app/lib` deveria permanecer sob
  `app/lib/core`.
- **Import quebrado:** `app/lib/features/home/life_counter_screen.dart:7`
  importa `../../../core/theme/app_theme.dart`.
- **Alvo resolvido:** `app/core/theme/app_theme.dart`.
- **Arquivo existente esperado:** `app/lib/core/theme/app_theme.dart`.
- **Por que parece quebrado:** a partir de `app/lib/features/home/`, tres `..`
  tambem sobem ate `app/`. O alvo real esta em `app/lib/core/theme`.
- **O que valida:** corrigir os imports relativos para alvos sob `app/lib/core`
  ou converter para `package:manaloom/core/...`, depois rodar analyzer do app
  com dependencias resolvidas.
- **O que falsifica:** existencia de `app/core/...` como fonte real desses
  imports ou analyzer Flutter verde no app com estes imports inalterados.

#### P2 — Ciclo direto entre detalhe de deck publico e perfil de usuario

- **Arquivos no SCC:** `app/lib/features/community/screens/community_deck_detail_screen.dart`
  e `app/lib/features/social/screens/user_profile_screen.dart`.
- **Evidencia de import A -> B:** `community_deck_detail_screen.dart:8`
  importa `../../social/screens/user_profile_screen.dart`.
- **Evidencia de uso A -> B:** `community_deck_detail_screen.dart:213`
  instancia `UserProfileScreen` no `Navigator.push`.
- **Evidencia de import B -> A:** `user_profile_screen.dart:7` importa
  `../../community/screens/community_deck_detail_screen.dart`.
- **Evidencia de uso B -> A:** `user_profile_screen.dart:469` instancia
  `CommunityDeckDetailScreen` no `Navigator.push`.
- **Por que parece circular:** as duas telas conhecem e instanciam uma a outra
  diretamente, criando ciclo de import entre features `community` e `social`.
- **Impacto:** aumenta acoplamento entre features e dificulta extrair, testar ou
  trocar navegacao por rotas nomeadas/go_router sem carregar a tela vizinha.
- **O que valida:** mover a navegacao cruzada para rotas nomeadas, callbacks ou
  um adapter compartilhado de navegacao, removendo pelo menos um dos imports.
- **O que falsifica:** grafo de imports sem SCC apos a mudanca ou evidencia de
  que uma das referencias e removida/isolada sem afetar navegacao.

## Rodada focada: Functions not called — revalidacao 2026-06-02 07:00 UTC

Escopo desta rodada: somente funcoes/metodos publicos ou wrappers expostos sem
chamador runtime confirmado. Nao foi feita auditoria ampla de classes, imports,
tabelas PostgreSQL, duplicacao ou coerencia entre modulos fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `1600cd01`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor textual nao compila codigo nem constroi
grafo de chamadas; ele tambem reescreve um bloco gerado amplo que nao pertence
ao foco desta rodada. Essa reescrita automatica foi descartada, e os achados
abaixo foram revalidados por `rg`/leitura direta.

### Metodo manual focado

- `rg -n "sync_cards_utils|\\bextractCardRow\\b|\\bextractSetCardRow\\b|\\bparseSinceDays\\b|\\bextractOracleIds\\b|\\bextractLegalities\\b" server app --glob '*.dart'`.
- `rg -n "\\bgetRequestTrace\\b|\\btryGetRequestId\\b|context\\.read<RequestTrace>\\(\\)" server app --glob '*.dart'`.
- `rg -n "\\bnormalizedCommanderReferenceCandidate\\b|\\bbuildLoreholdReferenceCardStatsFromProfile\\b|\\bextractMtgTop8FormatCodeFromSourceUrl\\b" server app --glob '*.dart'`.
- `rg -n "\\bbuildCandidateQualitySamplePoolSql\\b|\\bsummarizeAggressiveOptimizeUtilitySamples\\b|\\brecordFeedback\\b|\\bMLKnowledgeService\\b" server app --glob '*.dart'`.
- `rg -n "\\bPerformanceService\\b|\\bstartTrace\\b|\\bstopTrace\\b|\\baddMetric\\b|\\baddAttribute\\b|\\bprintLocalStats\\b|\\bgetLocalStats\\b" app/lib app/test app/integration_test --glob '*.dart'`.

### Achados revalidados

#### P1 — `sync_cards_utils.dart` segue test-only enquanto o CLI real duplica a logica

- **Funcoes:** `extractCardRow`, `getNewSetCodesSinceFromData`,
  `parseSinceDays`, `extractSetCardRow`, `extractOracleIds` e
  `extractLegalities` em `server/lib/sync_cards_utils.dart:16`, `:82`, `:102`,
  `:116`, `:161` e `:172`.
- **Evidencia de ausencia runtime:** busca por `sync_cards_utils` em Dart
  encontrou apenas `server/test/sync_cards_test.dart:3` importando o arquivo e
  exercitando esses helpers. `server/bin/sync_cards.dart:9`-`:10` importa
  `database.dart` e `mtg_data_integrity_support.dart`, mas nao importa
  `sync_cards_utils.dart`.
- **Controle positivo:** o CLI operacional mantem copias privadas/inline:
  `_parseSinceDays` em `server/bin/sync_cards.dart:376`-`:384`,
  `_getNewSetCodesSinceFromData` em `:413`-`:429`,
  montagem incremental inline em `:604`-`:663` e `_extractCardRow` em
  `:680`-`:735`.
- **Por que parece nao chamada:** os testes validam a biblioteca publica, mas o
  caminho que sincroniza MTGJSON no produto nao usa essa biblioteca.
- **O que valida:** importar `sync_cards_utils.dart` no CLI real e remover as
  copias privadas/inline, ou declarar/remover o arquivo como harness legado.
- **O que falsifica:** `rg "sync_cards_utils" server/bin server/lib server/routes`
  encontrar import runtime real.

#### P2 — Wrappers de `RequestTrace` continuam sem consumidor direto

- **Funcoes:** `getRequestTrace` e `tryGetRequestId` em
  `server/lib/request_trace.dart:48` e `:51`.
- **Evidencia de ausencia:** `getRequestTrace` aparece somente na propria
  definicao e dentro de `tryGetRequestId`; `tryGetRequestId` aparece somente na
  propria definicao.
- **Controle positivo:** consumidores reais acessam `RequestTrace` diretamente,
  por exemplo `server/lib/auth_middleware.dart:57`,
  `server/lib/observability.dart:225`, `server/routes/trades/index.dart:332`,
  `server/routes/trades/[id]/messages.dart:230`,
  `server/routes/users/[id]/follow/index.dart:99` e
  `server/routes/conversations/[id]/messages.dart:249`.
- **Por que parece nao chamada:** a API publica promete fallback seguro, mas as
  rotas usam leituras diretas ou wrappers privados locais.
- **O que valida:** substituir os reads diretos pelos wrappers quando o fallback
  for desejado, ou remover os wrappers se a leitura direta for o contrato.
- **O que falsifica:** chamada runtime a `getRequestTrace(context)` ou
  `tryGetRequestId(context)` fora de `request_trace.dart`.

#### P2 — Wrappers especificos de Commander Reference/MTGTop8 seguem test-only

- **Funcoes:**
  - `normalizedCommanderReferenceCandidate` em
    `server/lib/ai/commander_reference_profile_support.dart:49`.
  - `buildLoreholdReferenceCardStatsFromProfile` em
    `server/lib/ai/commander_reference_card_stats_support.dart:257`.
  - `extractMtgTop8FormatCodeFromSourceUrl` em
    `server/lib/meta/mtgtop8_meta_support.dart:139`.
- **Evidencia de ausencia:** `normalizedCommanderReferenceCandidate` aparece
  apenas na propria definicao; `buildLoreholdReferenceCardStatsFromProfile`
  aparece apenas na propria definicao e em
  `server/test/commander_reference_card_stats_support_test.dart:13`;
  `extractMtgTop8FormatCodeFromSourceUrl` aparece apenas na propria definicao e
  em `server/test/mtgtop8_meta_support_test.dart:147`.
- **Controle positivo:** o runtime usa os caminhos genericos/vizinhos:
  `buildCommanderReferenceCardStatsFromProfile` e chamado dentro do proprio
  modulo em `server/lib/ai/commander_reference_card_stats_support.dart:368`, e
  `server/bin/repair_mtgtop8_meta_history.dart:59` usa
  `extractMtgTop8EventIdFromSourceUrl`, mas nao o helper de format code.
- **Por que parece nao chamada:** os wrappers ficaram como conveniencias
  especificas de teste enquanto o produto usa a funcao generica ou outro campo.
- **O que valida:** ligar os wrappers a runners/rotas reais ou remover os
  wrappers especificos e ajustar testes para o helper generico.
- **O que falsifica:** chamada runtime nova aos tres simbolos fora de `server/test`.

#### P2 — Helpers de sample/diagnostic de optimize permanecem test-only

- **Funcoes:** `buildCandidateQualitySamplePoolSql` em
  `server/lib/ai/candidate_quality_data_support.dart:631` e
  `summarizeAggressiveOptimizeUtilitySamples` em
  `server/lib/ai/optimize_runtime_support.dart:3326`.
- **Evidencia de ausencia:** busca focada encontrou
  `buildCandidateQualitySamplePoolSql` somente na definicao e em
  `server/test/candidate_quality_data_support_test.dart:123`; encontrou
  `summarizeAggressiveOptimizeUtilitySamples` somente na definicao e em
  `server/test/optimize_runtime_support_test.dart:169`.
- **Por que parece nao chamada:** os testes validam SQL/resumo de amostras, mas
  nenhum runner, rota ou service runtime consome esses helpers nesta branch.
- **O que valida:** runner operacional chamar os helpers ao construir pool ou
  resumo de amostras agressivas.
- **O que falsifica:** chamada runtime em `server/bin`, `server/lib` ou
  `server/routes` fora das suites de teste.

#### P2 — `MLKnowledgeService.recordFeedback` ainda nao alimenta `ml_prompt_feedback`

- **Funcao:** `recordFeedback` em `server/lib/ml_knowledge_service.dart:251`.
- **Evidencia de ausencia:** busca por `recordFeedback(` encontrou somente a
  propria definicao. `MLKnowledgeService` e instanciado em
  `server/lib/ai/otimizacao.dart:33`, e esse fluxo chama
  `getContextForDeck`/`generatePromptContext` em `:167` e `:173`, mas nao chama
  `recordFeedback`.
- **Por que parece nao chamada:** o insert em `ml_prompt_feedback` existe em
  `server/lib/ml_knowledge_service.dart:262`-`:284`, mas nenhuma rota, job ou
  app action aciona essa escrita.
- **O que valida:** rota/app/job de feedback chamar `recordFeedback` com teste
  de contrato e consumo posterior do feedback.
- **O que falsifica:** chamada runtime a `recordFeedback(...)` fora do service.

#### P3 — API manual de metricas do `PerformanceService` segue sem uso app-facing

- **Funcoes:** `startTrace`, `stopTrace`, `addMetric`, `addAttribute`,
  `getLocalStats` e `printLocalStats` em
  `app/lib/core/services/performance_service.dart:110`, `:130`, `:200`, `:210`,
  `:220` e `:248`.
- **Evidencia de ausencia:** busca em `app/lib`, `app/test` e
  `app/integration_test` encontrou esses nomes apenas nas definicoes; excecao:
  `getLocalStats` e chamado internamente por `printLocalStats`.
- **Controle positivo:** a observabilidade viva usa `PerformanceService.instance.init()`
  em `app/lib/main.dart:121`; `PerformanceNavigatorObserver` chama
  `startScreenTrace`/`stopScreenTrace` em
  `app/lib/core/services/performance_service.dart:295`, `:307`, `:334` e
  `:339`; `traceAsync` aparece no smoke de observabilidade em
  `app/integration_test/release_observability_smoke_test.dart:51`.
- **Por que parece nao chamada:** a parte automatica do service esta viva, mas a
  API manual/custom metrics/debug nao tem consumidor app-facing confirmado.
- **O que valida:** usar esses metodos em fluxos app reais ou simplificar o
  service para `init`, observer e `traceAsync`.
- **O que falsifica:** chamada app-facing aos metodos manuais em `app/lib`.

## Rodada focada: Card semantics audit — revalidacao 2026-06-02 05:30 UTC

Escopo desta rodada: hardcoded card names em codigo de produto/runtime, drift
entre `functional_tags`, `semantic_tags_v2` e classificacao funcional do
optimize, e pontos onde utilidade ainda e inferida por nome em vez de
`oracle_text`, `type_line`, `mana_cost`, `cmc` ou dados semanticos persistidos.
A leitura priorizou `server/lib`, `server/routes` e `app/lib`; testes/docs/
artefatos foram usados apenas para separar fixtures permitidas de logica viva.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `37679299`.
- `rg` esta disponivel neste shell local em `/opt/homebrew/bin/rg`.

### Achados revalidados

#### P1 — Classificadores runtime ainda inferem papeis por nomes especificos

- **Fluxo:** `inferFunctionalCardTags`, `inferSemanticCardAnalysisV2` e
  `inferCandidateFunctionTags`.
- **Evidencia:**
  - `server/lib/ai/functional_card_tags.dart:220`-`:226` classifica ramp por
    `normalizedName.contains('signet')`, `normalizedName.contains('talisman')`,
    `normalizedName == 'sol ring'` e `normalizedName == 'arcane signet'`.
  - `server/lib/ai/functional_card_tags.dart:714`-`:717`, `:754`-`:780`,
    `:823`-`:851` e `:859`-`:899` usam nomes como `Teferi's Protection`,
    `Heroic Intervention`, `Swiftfoot Boots`, `Lightning Greaves`,
    `Blood Artist`, `Ephemerate`, `Jeska's Will`, `Thassa's Oracle`,
    `Isochron Scepter` e `Dramatic Reversal` para protecao, aristocrats,
    blink, ritual, wincon, combo, payoff e enabler.
  - `server/lib/ai/candidate_quality_data_support.dart:375`-`:379`,
    `:421`-`:428`, `:439`-`:445`, `:472`-`:478`, `:590`-`:605` e
    `:611`-`:628` repetem parte dessas excecoes e ainda aplicam
    `highPowerNames`/`premium` para bracket e score.
- **Classificacao:** **Risk**. Sao caminhos de runtime que afetam analise,
  candidate quality, bracket scope e optimize; nao sao fixtures, docs ou corpus.
- **O que valida:** teste com cartas de texto equivalente e nomes diferentes,
  alem de policy versionada para cada excecao realmente intencional.
- **O que falsifica:** excecoes movidas para `card_semantic_tags_v2`,
  `card_function_tags`, `card_role_scores` ou policy versionada com `role`,
  `reason`, `source`, `bracket` e cobertura.
- **Correcao recomendada:** manter heuristicas por `oracle_text`/`type_line`
  como fonte principal, backfillar excecoes reais em dado persistido ou policy,
  e remover checks inline de nome dos classificadores puros.

#### P1 — Optimize usa listas fixas de staples/fillers em selecao e score

- **Fluxo:** mana base, complete/filler, fallback universal e fallback
  contextual do optimize.
- **Evidencia:**
  - `server/lib/ai/optimize_runtime_support.dart:406`-`:454` define
    `premiumLandNames` e soma `+250` para terrenos como `Command Tower`,
    `City of Brass`, `Exotic Orchard`, `Mana Confluence`, `Path of Ancestry` e
    `Reflecting Pool`.
  - `server/lib/ai/optimize_runtime_support.dart:1296`-`:1345` consulta lista
    fixa de staples quando o pool inicial tem menos candidatos.
  - `server/lib/ai/optimize_runtime_support.dart:1948`-`:1995` define
    `_weakCommanderFillerDenylist` e `_premiumCommanderFillerNames`; `:2033`-`:2052`
    aplica bonus de score para nomes premium.
  - `server/lib/ai/optimize_runtime_support.dart:3476`-`:3509` e `:3565`-`:3615`
    carregam fallbacks universais/contextuais por nomes fixos.
  - Busca local por `commander_fallback_policy` continuou vazia; o unico
    `*policy*` em `server/lib` relacionado ao tema e `edh_bracket_policy.dart`.
- **Classificacao:** **Risk**. A selecao ainda consulta banco, legalidade e
  identidade de cor, mas prioridade inicial e bonus de utilidade seguem por nome.
- **O que valida:** extrair as listas para policy/tabela versionada com fonte,
  motivo e testes que provem que legalidade, identidade, bracket, budget e role
  semantico continuam prevalecendo.
- **O que falsifica:** demonstrar que essas listas sao corpus/benchmark inerte;
  nesta leitura elas participam de score/selecao runtime.
- **Correcao recomendada:** centralizar as listas em policy versionada ou tabela
  seed e preferir `semantic_tags_v2`, `card_role_scores`, `card_function_tags`,
  meta usage, `oracle_text`, `type_line`, `mana_cost` e `cmc` no score final.

#### P1 — Deck analysis usa `card_function_tags`; optimize/validator nao

- **Fluxos comparados:** `summarizeFunctionalTagsForDeck`,
  `loadOptimizeDeckContext`, `classifyOptimizationFunctionalRole`,
  `OptimizationValidator` e `filterUnsafeOptimizeSwapsByCardData`.
- **Evidencia:**
  - `server/routes/decks/[id]/analysis/index.dart:80`-`:96` seleciona
    `card_function_tags` e `semantic_tags_v2`; `:278`-`:284` chama
    `summarizeFunctionalTagsForDeck` para ramp/draw/removal/wipe/protection.
  - `server/lib/ai/functional_card_tags.dart:432`-`:465` prefere
    `functional_tags` persistidos e so cai para heuristica quando nao ha tag
    persistida.
  - `server/lib/ai/optimize_request_support.dart:86`-`:106`, `:186`-`:198` e
    `:323`-`:339` carregam `semantic_tags_v2`, mas nao carregam
    `card_function_tags`/`functional_tags` para `allCardData`.
  - `server/routes/ai/optimize/index.dart:2068`-`:2099` monta `additionsData`
    com `semantic_tags_v2`, sem `functional_tags`; `:3197`-`:3213` tambem so
    agrega `card_semantic_tags_v2`.
  - `server/lib/ai/optimization_functional_roles.dart:55`-`:58` usa
    `semantic_tags_v2` primeiro e depois `type_line`/`oracle_text`; nao ha
    leitura de `functional_tags`.
  - `server/lib/ai/optimization_validator.dart:265`-`:267` e
    `server/lib/ai/optimization_quality_gate.dart:52`-`:53` chamam esse
    classificador e herdam a ausencia.
- **Classificacao:** **Risk / semantic drift**.
- **O que valida:** teste com carta contendo `functional_tags` persistido e
  `semantic_tags_v2` ausente provando o mesmo papel em deck analysis, validator
  e quality gate.
- **O que falsifica:** queries de optimize/additions carregarem
  `functional_tags` e `classifyOptimizationFunctionalRole` aplicar prioridade
  unica: `functional_tags`, depois `semantic_tags_v2`, depois heuristica por
  texto/tipo/custo.
- **Correcao recomendada:** criar adapter `resolveCardFunctionalRoles` com
  `functional_tags`, `semantic_tags_v2`, `oracle_text`, `type_line`,
  `mana_cost` e `cmc`, retornando roles + `primary_role`.

#### P1 — `semantic_tags_v2` multi-tag ainda e colapsado no optimize

- **Fluxo:** `classifyOptimizationFunctionalRole` e diagnostics v2.
- **Evidencia:**
  - `server/lib/ai/optimization_functional_roles.dart:127`-`:180` escolhe uma
    unica entrada de maior `role_confidence` e retorna primeiro papel em ordem
    fixa (`board_wipe`, `draw`, `removal`, `ramp`, `tutor`, `protection`,
    `recursion`, `wincon`, `combo_piece`, depois flags `engine`/`payoff`/
    `enabler`).
  - `server/lib/ai/optimization_functional_roles.dart:292`-`:323` calcula
    `role_delta` usando somente esse papel unico para cada remocao/adicao.
  - `server/lib/ai/candidate_quality_data_support.dart:290`-`:309` usa outro
    mapa de normalizacao (`drain -> wincon`, `lifegain -> protection`,
    `exile_value -> draw`, `token_maker -> token`), criando outro eixo de role.
- **Classificacao:** **Risk / semantic drift**.
- **O que valida:** testes com `semantic_tags_v2.tags` multi-role que exercitem
  validator, quality gate e candidate quality, provando que roles secundarios
  criticos nao somem.
- **O que falsifica:** `role_delta` operar sobre conjunto de roles por carta,
  com `primary_role` apenas para compatibilidade.
- **Correcao recomendada:** substituir retorno escalar por conjunto/objeto de
  roles preservados e usar a mesma normalizacao em candidate quality.

#### P2 — Rotas legacy de recomendacao/weakness seguem name-based ou unidimensionais

- **Fluxos:** `/decks/:id/recommendations` e `/ai/weakness-analysis`.
- **Evidencia:**
  - `server/routes/decks/[id]/recommendations/index.dart:110`-`:130` conta
    ramp/draw/removal/wipe/protection por `oracle_text` local, sem
    `functional_tags` ou `semantic_tags_v2`.
  - `server/routes/decks/[id]/recommendations/index.dart:262`-`:268`
    recomenda `Command Tower` diretamente quando `landCount < 34`.
  - `_findStaples` em `server/routes/decks/[id]/recommendations/index.dart:408`-`:438`
    usa raridade `rare/mythic` como proxy de alto impacto, sem role semantico.
  - `server/routes/ai/weakness-analysis/index.dart:41`-`:60` nao carrega
    `card_function_tags`, `semantic_tags_v2` nem `card_role_scores`; `:114`-`:163`
    recalcula buckets por heuristica local e dois nomes de protecao; `:206`-`:285`
    retorna listas fixas de recomendacoes; `:302`-`:310` e `:350`-`:358`
    tambem retornam sugestoes nomeadas/textuais.
- **Classificacao:** **Risk** se promovidas a fluxo app-facing; hoje seguem
  legacy/experimental e sem consumidor app direto confirmado nesta rodada.
- **O que valida:** antes de exposicao, gerar nomes por consulta a `cards`,
  `card_legalities`, `card_function_tags`, `semantic_tags_v2` e
  `card_role_scores`, filtrando identidade, budget/bracket e cartas ja presentes.
- **O que falsifica:** contrato explicito removendo essas rotas da superficie de
  produto e mantendo-as como demos/diagnosticos internos.
- **Correcao recomendada:** manter as mensagens agregadas, mas substituir nomes
  fixos e raridade por query semantica versionada.

### Candidatos permitidos ou intencionais

- **Allowed — UI/example/route comment:** exemplos `1 Sol Ring` em
  `app/lib/features/decks/screens/deck_import_screen.dart:383`-`:392` e
  `:591`-`:592`, `app/lib/features/decks/widgets/deck_import_list_dialog.dart:153`-`:154`,
  mensagens de importacao em `server/routes/import/index.dart:181`-`:182` e
  `server/routes/import/to-deck/index.dart:101`-`:102`, e comentarios de
  `server/routes/cards/resolve/batch/index.dart:13`-`:22`.
- **Allowed — card search suggestion UI:** `app/lib/features/home/life_counter_screen.dart:2199`-`:2204`
  e `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:39`-`:44`
  sao sugestoes de busca, nao optimize/validator/analise.
- **Allowed — localized alias:** `server/lib/import_card_lookup_service.dart:20`-`:30`
  mapeia aliases PT para nomes canonicos; isso e resolucao de nome localizado,
  nao julgamento de utilidade.
- **Allowed with caution — prompt examples:** `server/lib/ai/prompt.md` e
  `server/lib/ai/prompt_complete.md` contem nomes como exemplos para o modelo.
  Influenciam prompt, mas nao sao gate deterministico; nao devem virar fonte de
  verdade de classificacao.
- **Intentional exception — EDH/bracket external policy:** `server/lib/edh_bracket_policy.dart:134`-`:142`
  e `:251`-`:286` usam listas por nome para fast mana, combos infinitos e Game
  Changers. A excecao e plausivel porque representa regra externa/curada, mas
  ainda precisa fonte/versionamento/teste dedicado.
- **Intentional seed/corpus — Commander Reference fallback:** `server/lib/ai/commander_reference_generate_fallback_support.dart:182`-`:245`
  embute pacote Lorehold deterministico. Tratar como seed de perfil Commander;
  se crescer, deve virar corpus/policy versionada.

### Resumo da checagem pedida

- A pipeline core nao usa `functional_tags_then_semantic_v2_then_heuristic` de
  ponta a ponta: deck analysis prefere `functional_tags`, mas optimize usa
  apenas `semantic_tags_v2` e fallback por `type_line`/`oracle_text`.
- `semantic_tags_v2` e usado antes da heuristica no optimize quando presente,
  mas e reduzido a um unico papel; roles secundarios como `engine`, `payoff`,
  `enabler`, `drain` e `exile_value` podem desaparecer do delta.
- Candidate quality reaproveita `inferFunctionalCardTags`, mas adiciona aliases,
  `premium` e `highPowerNames` por nome, criando drift de role/bracket.
- Ainda ha utilidade name-based em classificadores, score de candidatos,
  fillers/fallbacks de optimize e rotas legacy de recomendacao/weakness.

## Rodada focada: Classes not used — revalidacao 2026-06-02 03:00 UTC

Escopo desta rodada: somente classes definidas sem uso runtime/producao
confirmado. Nao foi executada auditoria ampla de funcoes sem chamada,
imports/ciclos, tabelas PostgreSQL, duplicacao ou coerencia entre modulos fora
deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `rg` esta disponivel neste shell local em `/opt/homebrew/bin/rg`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor inventaria apenas `server/lib` e
`server/routes`, nao analisa `app/lib` e nao constroi grafo de instanciacao ou
uso de tipos. Como o proprio script alerta, achados de "nao usado" exigem grep
manual. A execucao tambem voltou a reescrever um bloco gerado grande do
Markdown; essa escrita automatica foi descartada e os achados abaixo foram
registrados por leitura direta e `rg`.

### Metodo manual focado

- `rg -n "class (LifeCounterScreen|DeckCard|DeckProgressChip|LotusPresentationMode)\\b|\\b(LifeCounterScreen|DeckCard|DeckProgressChip|LotusPresentationMode)\\b" app/lib app/test app/integration_test`.
- `rg -n "\\bLifeCounterScreen\\(" app/lib app/test app/integration_test`.
- `rg -n "\\bDeckCard\\(" app/lib app/test app/integration_test`.
- `rg -n "\\bDeckProgressChip\\(" app/lib app/test app/integration_test`.
- `rg -n "\\bLotusPresentationMode\\b|lotus_presentation_mode\\.dart|\\.enter\\(|\\.exit\\(" app/lib app/test app/integration_test`.
- Triagem textual de classes publicas em `app/lib`, `server/lib`,
  `server/routes`, `server/bin` e `server/test` para separar candidatos com
  ausencia real de instanciacao de DTOs/classes usados no proprio arquivo.
- `nl -ba` + `sed` foram usados para confirmar as linhas citadas.

### Achados revalidados

#### P1 — `LifeCounterScreen` legado segue fora do caminho runtime do app

- **Classe:** `LifeCounterScreen` em
  `app/lib/features/home/life_counter_screen.dart:61`; construtor em `:66`.
- **Rota viva:** `app/lib/main.dart:54` importa
  `lotus_life_counter_screen.dart`, e `app/lib/main.dart:281`-`:283` registra
  `lifeCounterRoutePath` com `const LotusLifeCounterScreen()`.
- **Evidencia de ausencia em `app/lib`:** busca por `LifeCounterScreen(` em
  `app/lib` encontrou somente o construtor da propria classe.
- **Evidencia de uso apenas legado/teste:** `app/test/README.md:149` declara
  que o caminho oficial do contador nao e mais `LifeCounterScreen`, e
  `:163`-`:168` lista `life_counter_screen_test.dart` e
  `life_counter_clone_proof_test.dart` como suites legadas. Esses testes ainda
  importam a tela legada em `app/test/features/home/life_counter_screen_test.dart:9`
  e `app/test/features/home/life_counter_clone_proof_test.dart:10`, e instanciam
  `LifeCounterScreen` em `life_counter_screen_test.dart:36` e
  `life_counter_clone_proof_test.dart:277`-`:280`.
- **Por que parece nao usada em runtime:** a rota de producao aponta para Lotus,
  enquanto a classe antiga so aparece como referencia historica/teste.
- **O que valida:** remover a tela legada e migrar/remover os testes de paridade,
  ou documenta-la explicitamente como fixture legado fora do runtime.
- **O que falsifica:** rota, feature flag ou navegacao em `app/lib` passar a
  instanciar `LifeCounterScreen` fora dos testes.

#### P2 — `DeckCard` permanece testado, mas sem uso confirmado na listagem real

- **Classe:** `DeckCard` em
  `app/lib/features/decks/widgets/deck_card.dart:17`; construtor em `:22`.
- **Evidencia de ausencia em `app/lib`:** busca por `DeckCard(` em `app/lib`
  encontrou somente o construtor da propria classe. Busca por import de
  `deck_card.dart` em `app/lib` nao encontrou consumidor.
- **Uso test-only:** `app/test/features/decks/widgets/deck_card_test.dart:4`
  importa `deck_card.dart` e instancia `DeckCard` em `:9`;
  `app/test/features/decks/widgets/deck_card_overflow_test.dart:4` importa o
  mesmo widget e instancia `DeckCard` em `:47`.
- **Controle positivo:** as listagens reais usam cards privados/locais:
  `_RecentDeckCard` em `app/lib/features/home/home_screen.dart:523` e `:529`,
  `_CommunityDeckCard` em `app/lib/features/community/screens/community_screen.dart:312`
  e `:732`, `_FollowingDeckCard` em `community_screen.dart:515` e `:946`, e
  `_DeckGalleryCard` em `app/lib/features/decks/screens/deck_list_screen.dart:626`
  e `:1401`.
- **Por que parece nao usada em runtime:** o widget publico parece ter sido
  substituido por implementacoes locais nas telas vivas, mantendo apenas testes
  dedicados a um componente sem consumidor.
- **O que valida:** reutilizar `DeckCard` na listagem real de decks, ou remover
  o widget e seus testes se o design atual for `_DeckGalleryCard`.
- **O que falsifica:** import ou chamada `DeckCard(...)` em `app/lib` que a
  busca textual nao encontrou.

#### P2 — `DeckProgressChip` nao tem chamada de construtor confirmada

- **Classe:** `DeckProgressChip` em
  `app/lib/features/decks/widgets/deck_progress_indicator.dart:286`;
  construtor em `:292`.
- **Evidencia de ausencia:** busca por `DeckProgressChip(` em `app/lib`,
  `app/test` e `app/integration_test` encontrou apenas o construtor.
- **Controle positivo:** `DeckProgressIndicator` no mesmo arquivo continua
  usado em `app/lib/features/decks/widgets/deck_details_overview_tab.dart:328`
  e `app/lib/features/decks/screens/deck_details_screen.dart:403`; o achado e
  somente sobre o chip compacto.
- **Por que parece nao usada:** nao ha instanciacao do widget compacto em cards,
  listas ou testes, apesar do comentario de que ele serve para cards/listas.
- **O que valida:** chamar `DeckProgressChip` em uma superficie real ou remover
  a classe se o indicador completo for o unico componente mantido.
- **O que falsifica:** chamada direta a `DeckProgressChip(...)` em `app/lib` ou
  teste que proteja intencionalmente o chip.

#### P2 — `LotusPresentationMode` parece utilitario morto no fluxo Lotus atual

- **Classe:** `LotusPresentationMode` em
  `app/lib/features/home/lotus/lotus_presentation_mode.dart:4`.
- **Evidencia de ausencia:** busca por `LotusPresentationMode`,
  `lotus_presentation_mode.dart`, `.enter(` e `.exit(` em `app/lib`, `app/test`
  e `app/integration_test` retornou somente a propria declaracao
  (`lotus_presentation_mode.dart:4`-`:5`).
- **Por que parece nao usada:** o utilitario configura orientacao/fullscreen em
  `enter()`/`exit()`, mas o caminho vivo `LotusLifeCounterScreen` nao o importa.
  Se fullscreen/orientacao forem requisitos do Lotus, hoje nao ha evidencia de
  que este helper esteja aplicando o contrato.
- **O que valida:** chamar `LotusPresentationMode.enter/exit` no ciclo de vida
  do Lotus com teste de contrato, ou remover o helper.
- **O que falsifica:** import real de `lotus_presentation_mode.dart` e chamada
  de `LotusPresentationMode.enter/exit`.

### Itens verificados e nao promovidos

- A lista bruta de classes publicas em `server/lib`/`server/routes` nao foi
  promovida como achado. A triagem textual encontrou muitos DTOs/classes
  usados apenas dentro do proprio arquivo por construtor, retorno ou colecoes
  tipadas, por exemplo `EdhrecAverageDeckCard`,
  `ExternalCommanderMetaPromotionIssue`, `OptimizeJob` e `ManaAnalysis`.
- A lista bruta de `app/lib` tambem gerou varios helpers same-file esperados
  (`DeckFunctionalTags`, `OptimizePreviewData`, dialogs/sections do optimize,
  DTOs de binder/trades e classes Lotus internas). Esses itens nao foram
  promovidos porque havia uso no mesmo arquivo ou contrato de modelo/helper.
- `LotusLifeCounterScreen` nao esta unused: `app/lib/main.dart:281`-`:283`
  registra a rota viva com esse widget e a suite principal do contador tambem o
  instancia diretamente.

## Rodada focada: Coerencia entre modulos `server/lib` <-> `server/routes` <-> `app/lib` — revalidacao 2026-06-01 23:00 UTC

Escopo desta rodada: somente coerencia entre camadas app-facing do Flutter,
rotas Dart Frog e helpers de `server/lib`. Nao foi executada auditoria ampla de
classes sem uso, funcoes sem chamada, imports/ciclos, tabelas PostgreSQL ou
duplicacao fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `rg` esta disponivel neste shell local em `/opt/homebrew/bin/rg`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor textual nao entende contrato entre app,
rota e helper. Ele tambem voltou a reescrever uma parte gerada do Markdown e a
duplicar rodadas manuais antigas; essa escrita automatica foi descartada antes
dos achados manuais abaixo. Os achados desta rodada foram derivados de leitura
direta de codigo e `rg`.

### Metodo manual focado

- `rg -n "optimizeDeck|rebuildDeck|fetchOptimizationOptions|ai/optimize|ai/archetypes|ai/rebuild|optimize/jobs|deck_id|deckId" app/lib/features/decks app/lib/features/cards app/lib/core`.
- `rg -n "loadOptimizeDeckContext|deck_id|userId|user_id|FROM decks|JOIN deck_cards|optimize/jobs|OptimizeJob|ai/archetypes|ai/rebuild" server/routes/ai server/lib/ai server/lib`.
- `rg -n "functional_tags|semantic_tags_v2|classifyOptimizationFunctionalRole|summarizeFunctionalTagsForDeck|loadOptimizeDeckContext|card_function_tags|card_semantic_tags_v2" server/routes/decks server/routes/ai server/lib/ai app/lib/features/decks`.
- `rg -n "weakness-analysis|simulate-matchup|ai/simulate|simulate" app/lib server/doc/API_CONTRACTS_AND_DATA_MAP.md`.
- `nl -ba` + `sed` foram usados para confirmar as linhas citadas.

### Achados revalidados

#### P1 — `POST /ai/optimize` continua incoerente com o contrato app-facing de deck do usuario

- **Fluxo app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:10`-`:23`
  monta payload com `deck_id`, `archetype`, `bracket`, `keep_theme` e
  `intensity`; `:56` envia `POST /ai/optimize`.
- **Rota:** `server/routes/ai/optimize/index.dart:401`-`:405` tenta ler
  `userId` do contexto autenticado, mas `:549`-`:558` chama
  `optimize_request.loadOptimizeDeckContext(...)` sem passar `userId`.
- **Helper:** `server/lib/ai/optimize_request_support.dart:53`-`:62` nao aceita
  `userId`; `:66`-`:72` busca `SELECT name, format FROM decks WHERE id = @id`;
  `:107`-`:110` e `:131`-`:134` carregam cartas por `WHERE dc.deck_id = @id`.
- **Por que e incoerente:** o app opera sobre um deck selecionado do usuario
  autenticado, mas a rota/helper carregam o deck e as cartas sem escopo de dono.
  O usuario autenticado que obtiver um UUID de outro deck pode potencialmente
  disparar analise/otimizacao sobre esse deck.
- **Controle positivo:** `POST /ai/rebuild` faz o gate correto em
  `server/routes/ai/rebuild/index.dart:61`-`:78` com
  `WHERE d.id = @deckId AND d.user_id = @userId` antes de carregar cartas.
  `GET /decks/:id/analysis` tambem escopa por dono em
  `server/routes/decks/[id]/analysis/index.dart:22`-`:26`.
- **O que valida:** alterar `loadOptimizeDeckContext` para receber `userId` e
  consultar `decks` com `id + user_id`, ou documentar e testar uma regra
  explicita de deck publico/compartilhado antes de carregar cartas.
- **O que falsifica:** teste de rota provando que um usuario autenticado recebe
  404/403 ao chamar `/ai/optimize` com `deck_id` de outro usuario.

#### P1 — `POST /ai/archetypes` e chamado pelo app, mas a rota ignora ownership

- **Fluxo app:** `app/lib/features/decks/providers/deck_provider_support_mutation.dart:168`-`:173`
  chama `POST /ai/archetypes` com `{'deck_id': deckId}` para buscar opcoes de
  otimizacao.
- **Rota:** `server/routes/ai/archetypes/index.dart:27`-`:32` le `deck_id`,
  mas nao le `context.read<String>()`; `:39`-`:42` executa
  `SELECT name, format FROM decks WHERE id = @id`; `:54`-`:61` carrega cartas
  por `WHERE dc.deck_id = @id`.
- **Por que e incoerente:** o endpoint e consumido como passo do fluxo de deck
  privado do app, mas a rota nao usa o usuario autenticado para filtrar o deck.
  Isso deixa o mesmo risco de leitura indireta de nome/formato/comandante/cartas
  que o optimize.
- **O que valida:** escopar a query inicial por `decks.id + decks.user_id` ou
  criar uma permissao publica explicita para decks compartilhados, com teste
  owner versus non-owner.
- **O que falsifica:** prova de rota/app mostrando que `/ai/archetypes` esta
  protegido por outro middleware/helper que injeta e aplica ownership antes das
  queries citadas.

#### P1/P2 — Polling de optimize aceita jobs sem dono no endpoint app-facing

- **Fluxo app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:190`-`:194`
  faz polling em `GET /ai/optimize/jobs/$jobId`; `:196`-`:240` trata
  `completed`, `failed` e progresso como estados normais do app.
- **Rota:** `server/routes/ai/optimize/jobs/[id].dart:26`-`:28` le `userId` e
  carrega o job, mas `:39` bloqueia apenas quando
  `job.userId != null && job.userId != userId`.
- **Store:** `server/lib/ai/optimize_job.dart:25`-`:30` permite `String? userId`;
  `:37`-`:42` cria `OptimizeJob` com owner nullable; `:49`-`:56` persiste
  `user_id` tambem nullable.
- **Por que e incoerente:** o polling e app-facing e autenticado, mas qualquer
  job salvo com `user_id = NULL` fica legivel por qualquer usuario que conheca o
  `job_id`. A criacao normal em `/ai/optimize` passa `userId`, mas o contrato da
  store/rota ainda permite o estado ownerless.
- **O que valida:** tornar `userId` obrigatorio para jobs de optimize criados
  por endpoints app-facing e retornar 404 para `job.userId == null`, salvo
  excecao interna documentada e separada.
- **O que falsifica:** teste provando que nao ha nenhum caminho runtime capaz de
  criar `ai_optimize_jobs.user_id IS NULL` e migracao/constraint impedindo esse
  estado.

#### P1/P2 — Deck analysis e optimize ainda usam fontes semanticas diferentes para papeis funcionais

- **Fluxo app:** `app/lib/features/decks/providers/deck_provider_support_fetch.dart:135`-`:140`
  chama `GET /decks/:id/analysis`; `app/lib/features/decks/models/deck_analysis.dart:14`-`:23`
  parseia `functional_tags`; `app/lib/features/decks/widgets/deck_analysis_tab.dart:94`-`:99`
  agenda o fetch automatico da analise funcional.
- **Rota de analysis:** `server/routes/decks/[id]/analysis/index.dart:34`-`:65`
  prepara leitura de `card_semantic_tags_v2`; `:91`-`:96` seleciona
  `card_function_tags` e `semantic_tags_v2`; `:279` e `:430` retornam
  `summarizeFunctionalTagsForDeck(cards)` como `functional_tags`.
- **Helper de analysis:** `server/lib/ai/functional_card_tags.dart:432`-`:465`
  prefere `card['functional_tags']` persistido antes de cair para semantic v2
  ou heuristica.
- **Optimize:** `server/lib/ai/optimize_request_support.dart:86`-`:106`
  seleciona apenas `semantic_tags_v2`; `:186`-`:198` monta `allCardData` sem
  `functional_tags`. A rota de optimize tambem monta `additionsData` em
  `server/routes/ai/optimize/index.dart:2063`-`:2099` com `semantic_tags_v2`,
  mas sem `functional_tags`; `_semanticV2SelectSql` em `:3197`-`:3213` so
  consulta `card_semantic_tags_v2`.
- **Classificador de optimize:** `server/lib/ai/optimization_functional_roles.dart:55`-`:58`
  usa apenas `semantic_tags_v2` como fonte persistida antes de heuristicas.
- **Por que e incoerente:** a aba de analise apresenta papeis funcionais vindos
  de `card_function_tags` quando disponiveis, mas optimize/validator/quality
  gate tomam decisoes com outro input. A mesma carta pode aparecer como
  essencial na analise e ser tratada como outro papel no gate de troca.
- **O que valida:** passar `functional_tags` pelo contexto de optimize e usar um
  adapter unico de papel funcional que preserve multi-role e exponha
  `primary_role`; adicionar teste com uma carta onde `card_function_tags` e
  `semantic_tags_v2` divergem.
- **O que falsifica:** contrato e testes afirmando que analysis e optimize devem
  usar fontes semanticas diferentes, com UX explicando essa diferenca.

### Itens verificados e nao promovidos

- `POST /ai/rebuild` nao foi promovido como achado de ownership porque a rota
  faz gate `deck_id + user_id` antes de carregar cartas
  (`server/routes/ai/rebuild/index.dart:61`-`:78`).
- `GET /decks/:id/analysis` tambem nao foi promovido como achado de ownership
  porque a rota escopa por `deck_id + user_id`
  (`server/routes/decks/[id]/analysis/index.dart:22`-`:26`).
- `/ai/simulate`, `/ai/simulate-matchup` e `/ai/weakness-analysis` continuam
  experimentais/not-proven no mapa de contratos e nao tiveram consumidor atual
  em `app/lib` encontrado por `rg`; por isso nao foram tratados como drift
  app-facing nesta rodada.

## Rodada focada: Duplicated or similar logic — revalidacao 2026-06-01 19:00 UTC

Escopo desta rodada: somente logica duplicada ou similar com risco de drift.
Nao foi executada auditoria ampla de classes sem uso, funcoes sem chamada,
imports/ciclos, tabelas PostgreSQL ou coerencia entre camadas fora deste foco.

### Setup executado

- `pwd` e `git rev-parse --show-toplevel` confirmaram o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido sem saida.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `rg` esta disponivel neste shell local em `/opt/homebrew/bin/rg`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor textual lista nomes duplicados e
colisoes por regex, mas mistura wrappers legitimos, SQL, nomes comuns e
duplicacao real. A execucao voltou a anexar blocos historicos duplicados no
Markdown; essa escrita automatica foi descartada antes dos achados manuais
abaixo.

### Metodo manual focado

- `rg -n "resolveOptimizeArchetype|looksLikeComboPiece|looksLikeEngine|looksLikePayoff|looksLikeEnabler|looksLikeWincon|isBasicLandName|_isBasicLandName|_trustStatsSql|_buildTrustInsight|_requestId|_logInvalidPayload|getMainType|calculateCmc" server/lib server/routes app/lib`.
- `rg -n "String _requestId\\(|void _logInvalidPayload\\(" server/routes server/lib`.
- `rg -n "String resolveOptimizeArchetype\\(|bool _looksLikeWincon\\(|bool _isBasicLandName\\(|Map<String, dynamic> _buildTrustInsight\\(|String _trustStatsSql\\(|int calculateCmc\\(|String getMainType\\(" server/lib server/routes`.
- `rg -n "const allowedConditions|allowedConditions|_validConditions|NM|LP|MP|HP|DMG" server/routes/decks server/routes/binder server/routes/community/marketplace server/lib app/lib`.
- `nl -ba` + `sed` foram usados para confirmar as linhas citadas.

### Achados revalidados

#### P1 — `resolveOptimizeArchetype` continua com duas semanticas runtime

- **Duplicacao:** `server/lib/ai/deck_state_analysis.dart:573`-`:585` e
  `server/lib/ai/optimize_runtime_support.dart:3369`-`:3389` definem
  `resolveOptimizeArchetype`.
- **Evidencia de drift:** a versao de deck state aceita
  `requestedArchetype` nullable, trata `general` e `tempo` como genericos e
  retorna `detected` quando `requested` esta vazio. A versao de optimize exige
  string, trata `unknown` como vazio, usa `goodstuff` como generico e so aceita
  detected especifico em `aggro/control/combo/stax/tribal`.
- **Consumo runtime divergente:** `server/lib/ai/optimize_request_support.dart:289`
  e `:294` usam a versao de optimize; `server/lib/ai/rebuild_guided_service.dart:171`
  usa a versao de deck state.
- **O que valida:** helper unico com testes para `null`, vazio, `unknown`,
  `general`, `tempo`, `goodstuff`, `midrange` e detected especifico.
- **O que falsifica:** contrato documentado e testado dizendo que optimize e
  rebuild devem resolver arquetipos por regras diferentes.

#### P1 — Heuristicas de roles semanticos altos seguem duplicadas e divergentes

- **Duplicacao:** `server/lib/ai/functional_card_tags.dart:859`-`:907` define
  `_looksLikeWincon`, `_looksLikeComboPiece`, `_looksLikeEngine`,
  `_looksLikePayoff` e `_looksLikeEnabler`; `server/lib/ai/optimization_functional_roles.dart:370`-`:397`
  define os mesmos conceitos para o optimize.
- **Evidencia de drift:** `functional_card_tags.dart` recebe nome normalizado e
  usa nomes conhecidos (`Thassa's Oracle`, `Isochron Scepter`,
  `Dramatic Reversal`, `Blood Artist`, `Greaves`, `Boots`) junto de
  `oracle_text`; `optimization_functional_roles.dart` nao recebe nome da carta e
  usa outro conjunto de padroes textuais para um unico role primario.
- **Por que e duplicacao relevante:** deck analysis, candidate quality,
  validator e optimize podem classificar a mesma carta com papeis diferentes.
- **O que valida:** adapter compartilhado que aceite nome, `oracle_text`,
  `type_line`, `functional_tags` e `semantic_tags_v2`, preservando multi-role e
  expondo `primary_role` explicitamente.
- **O que falsifica:** prova de que essas heuristicas rodam em dominios isolados
  sem comparacao ou decisao cruzada.

#### P2 — Basic lands/snow basics ainda tem quatro variantes incompatíveis

- **Duplicacao:** `server/lib/ai/optimize_runtime_support.dart:4184`-`:4197`,
  `server/lib/generated_deck_validation_service.dart:752`-`:763`,
  `server/lib/meta/meta_deck_reference_support.dart:890`-`:903` e
  `server/routes/ai/commander-reference/index.dart:621`-`:628`.
- **Evidencia de drift:** optimize faz match exato para `snow-covered ...`;
  generated validation aceita `startsWith('snow-covered ...')`; meta reference
  procura `snow covered ...` sem hifen; commander-reference nao inclui snow
  basics.
- **Por que e duplicacao relevante:** snow basics podem ser ignoradas ou
  contadas de forma diferente em optimize, validacao de deck gerado, meta
  reference e commander-reference.
- **O que valida:** helper unico de terrenos basicos/snow basics reutilizado
  nesses fluxos, com testes de hifen, sem hifen, whitespace e sufixos.
- **O que falsifica:** regra intencional diferente por fluxo, com teste e
  justificativa de produto.

#### P2 — Trust social repete SQL e serializer entre trades e marketplace

- **Duplicacao:** `server/routes/trades/index.dart:557`-`:635` e
  `server/routes/trades/[id]/index.dart:260`-`:338` duplicam
  `_trustStatsSql`, `_responseTimeSql`, `_shippingTimeSql` e
  `_buildTrustInsight`. `server/routes/community/marketplace/index.dart:131`-`:166`
  repete os LATERALs inline e `:316`-`:348` repete o serializer.
- **Evidencia de drift:** os shapes de resposta ainda parecem equivalentes
  (`completed_trades`, tempos medios, `is_new_account`,
  `profile_incomplete`, `has_insufficient_history`), mas marketplace nao
  reutiliza os helpers das rotas de trades.
- **O que valida:** extrair SQL/serializer de trust para helper compartilhado
  com testes de listagem, detalhe e marketplace.
- **O que falsifica:** contratos diferentes por superficie, documentados e
  testados separadamente.

#### P2 — Request-id/log de payload invalido duplicado em rotas sociais

- **Duplicacao:** `_requestId` aparece em
  `server/routes/trades/index.dart:330`-`:336`,
  `server/routes/trades/[id]/status.dart:260`-`:266`,
  `server/routes/trades/[id]/respond.dart:154`-`:160`,
  `server/routes/trades/[id]/messages.dart:228`-`:234`,
  `server/routes/conversations/[id]/messages.dart:247`-`:253` e
  `server/routes/users/[id]/follow/index.dart:97`-`:103`.
- **Duplicacao adjacente:** `_logInvalidPayload` repete o mesmo formato de
  log social em `server/routes/trades/index.dart:338`-`:351`,
  `server/routes/trades/[id]/status.dart:268`-`:283`,
  `server/routes/trades/[id]/respond.dart:162`-`:177`,
  `server/routes/trades/[id]/messages.dart:236`-`:251` e
  `server/routes/conversations/[id]/messages.dart:255`-`:270`.
- **Evidencia de helper existente:** `server/lib/request_trace.dart:48`-`:57`
  ja expoe `getRequestTrace` e `tryGetRequestId`, mas as rotas mantem fallback
  local para header `x-request-id`/`n/a`.
- **Por que e duplicacao relevante:** qualquer mudanca no formato de trace ou
  sanitizacao de log precisa ser replicada em seis rotas.
- **O que valida:** helper compartilhado para request id opcional e log de
  payload invalido com endpoint/recurso parametrizados.
- **O que falsifica:** decisao documentada de manter mensagens e fallback
  locais por rota, com testes de observabilidade.

#### P2/P3 — CMC/tipo e condicao de carta continuam com normalizadores locais

- **Duplicacao CMC/tipo:** `getMainType` e `calculateCmc` aparecem em
  `server/routes/decks/[id]/index.dart:405`-`:435` e
  `server/routes/community/decks/[id].dart:91`-`:116`; ha variante de CMC em
  `server/routes/decks/[id]/simulate/index.dart:171`-`:185`.
- **Duplicacao de condicao:** sets `NM/LP/MP/HP/DMG` aparecem em
  `server/routes/community/marketplace/index.dart:39`,
  `server/routes/binder/index.dart:276`-`:279`,
  `server/routes/binder/[id]/index.dart:341`-`:344`,
  `server/routes/decks/[id]/index.dart:520`-`:523`,
  `server/routes/decks/[id]/cards/index.dart:400`-`:403`,
  `server/routes/decks/[id]/cards/set/index.dart:245`-`:248` e no app em
  `app/lib/features/decks/models/deck_card_item.dart:5`-`:9`.
- **Evidencia de drift:** decks normalizam condicao invalida para `NM`; binder
  rejeita com `400`; marketplace valida filtro por allow-list propria.
- **O que valida:** helpers/DTOs compartilhados por dominio ou contrato
  explicitando quando normalizar versus rejeitar.
- **O que falsifica:** testes garantindo que as diferencas de comportamento por
  endpoint sao intencionais.

### Itens verificados e nao promovidos

- `server/routes/ai/optimize/index.dart:56` tambem define
  `resolveOptimizeArchetype`, mas e wrapper fino que delega para
  `optimize_support.resolveOptimizeArchetype` em `:60`-`:63`; nao foi tratado
  como duplicacao funcional nova.
- A busca de condicoes no app encontrou tambem labels e widgets de UI; eles
  foram usados apenas como evidencia de contrato exposto, nao como bug por si.

## Rodada focada: PostgreSQL tables not used — revalidacao 2026-06-01 15:00 UTC

Escopo desta rodada: somente tabelas PostgreSQL persistidas sem consumidor claro,
write-only ou parcialmente consumidas. Nao foi executada auditoria ampla de
classes sem uso, funcoes sem chamada, imports/ciclos, duplicacao ou coerencia
entre camadas fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: concluido sem saida.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa e rastreando
  `origin/codex/hermes-analysis-docs`.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `rg` esta disponivel neste shell local em `/opt/homebrew/bin/rg`; buscas
  focadas usaram `rg`, `nl -ba`, `sed` e uma varredura local de operacoes SQL
  por tabela definida.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor textual lista referencias de tabela por
regex, mas nao distingue tabela real de alias/CTE nem classifica leitura,
escrita, consumidor runtime ou count operacional. A execucao tambem voltou a
inserir blocos historicos duplicados no Markdown; essa escrita automatica foi
descartada antes dos achados manuais abaixo.

### Metodo manual focado

- `rg -n "deck_matchups|deck_weakness_reports|ml_prompt_feedback|commander_reference_decks|commander_reference_deck_cards|commander_reference_deck_analysis" server app docs/hermes-analysis docs/CONTEXTO_PRODUTO_ATUAL.md server/doc/API_CONTRACTS_AND_DATA_MAP.md`.
- `rg -n "recordFeedback|MLKnowledgeService|ml-status|ml_prompt_feedback" server/lib server/routes server/bin server/test app/lib`.
- `rg -n "deck_matchups|deck_weakness_reports" server/lib server/routes server/bin server/test app/lib`.
- `rg` com padroes focados de `FROM`, `JOIN`, `UPDATE`, `DELETE FROM` e
  `INSERT INTO` para `deck_matchups`, `deck_weakness_reports`,
  `ml_prompt_feedback`, `commander_reference_decks` e
  `commander_reference_deck_cards` em `server/routes`, `server/lib`,
  `server/bin` e `app/lib`.
- Varredura local de `CREATE TABLE` versus `FROM/JOIN/INSERT/UPDATE/DELETE`
  em `server/**/*.dart`, `app/lib/**/*.dart` e `server/database_setup.sql`.

Resultado da varredura de operacoes SQL: nao apareceu novo candidato de tabela
persistida sem leitura alem dos ja conhecidos. Tabelas com `SELECT/JOIN == 0`:
`deck_matchups`, `deck_weakness_reports` e os raws
`commander_reference_decks`/`commander_reference_deck_cards`. `ml_prompt_feedback`
tem `SELECT`, mas somente como `COUNT(*)` operacional em `/ai/ml-status`, sem
leitura de payload ou loop de aprendizado.

### Achados revalidados

#### P2 — `deck_matchups` continua write-only no produto atual

- **Tabela:** `deck_matchups`.
- **Definicao:** `server/database_setup.sql:162` cria a tabela com
  `deck_id`, `opponent_deck_id`, `win_rate`, `notes` e `updated_at`.
- **Escrita encontrada:** `server/routes/ai/simulate-matchup/index.dart:360`
  faz `INSERT INTO deck_matchups (...) ON CONFLICT (...) DO UPDATE`.
- **Leitura/consumo encontrado:** nenhum `SELECT ... FROM deck_matchups`,
  `JOIN deck_matchups`, `UPDATE deck_matchups` fora do proprio upsert, ou
  `DELETE FROM deck_matchups` em `server/routes`, `server/lib`, `server/bin`
  ou `app/lib`.
- **Por que parece nao usada:** o endpoint calcula a simulacao em memoria e
  retorna a resposta da chamada atual; `deck_matchups.win_rate` e `notes` nao
  alimentam cache, historico, ranking, UI ou recomendacao posterior.
- **O que valida:** criar consumidor real de `deck_matchups`, por exemplo
  historico/cached matchup, dashboard operacional ou reuso na simulacao, com
  contrato e teste.
- **O que falsifica:** um `SELECT ... FROM deck_matchups` em rota/lib consumida
  ou job operacional que use `win_rate`/`notes` para alguma decisao.

#### P2 — `deck_weakness_reports` acumula registros sem fluxo de leitura

- **Tabela:** `deck_weakness_reports`.
- **Definicao:** `server/database_setup.sql:363` cria a tabela; o migrador
  `server/bin/migrate_create_missing_tables.dart:97` tambem cria a mesma tabela
  quando ausente.
- **Escrita encontrada:** `server/routes/ai/weakness-analysis/index.dart:374`
  faz `INSERT INTO deck_weakness_reports (...) ON CONFLICT DO NOTHING` para cada
  fraqueza detectada.
- **Leitura/consumo encontrado:** nenhum `SELECT ... FROM deck_weakness_reports`,
  `JOIN deck_weakness_reports`, `UPDATE deck_weakness_reports` ou
  `DELETE FROM deck_weakness_reports` em `server/routes`, `server/lib`,
  `server/bin` ou `app/lib`.
- **Por que parece nao usada:** a rota retorna a analise da execucao atual e a
  tabela nao tem fluxo confirmado para listar historico, marcar `addressed`,
  deduplicar por deck/tipo ou alimentar recomendacao futura.
- **O que valida:** endpoint/job/UI que leia historico por deck e atualize
  `addressed`, ou migracao removendo a persistencia se a resposta for efemera.
- **O que falsifica:** consumidor real de leitura/update usando
  `deck_weakness_reports` fora da propria gravacao.

#### P3 — `ml_prompt_feedback` tem helper de insert sem chamador e so aparece como contador operacional

- **Tabela:** `ml_prompt_feedback`.
- **Definicao:** `server/bin/migrate_ml_knowledge.dart:159` cria a tabela com
  campos de feedback, rating, comentario, cards aceitos/rejeitados e contexto.
- **Escrita potencial:** `server/lib/ml_knowledge_service.dart:251` define
  `MLKnowledgeService.recordFeedback`, com `INSERT INTO ml_prompt_feedback` em
  `:264`.
- **Chamador encontrado:** nenhum. `rg -n "recordFeedback|MLKnowledgeService|ml-status|ml_prompt_feedback" server/lib server/routes server/bin server/test app/lib`
  encontrou `recordFeedback` somente na propria definicao; `MLKnowledgeService`
  e instanciado, mas o metodo de feedback nao e chamado.
- **Leitura encontrada:** `server/routes/ai/ml-status/index.dart:98` executa
  apenas `SELECT COUNT(*)::int as c FROM ml_prompt_feedback`.
- **Por que parece nao usada:** nao ha endpoint/app/job gravando feedback de
  usuario nem consumidor que leia o conteudo para ajustar prompt/modelo; o count
  apenas informa volume bruto no status ML.
- **O que valida:** endpoint ou job app-facing/interno que chame
  `recordFeedback` e consuma os campos de feedback para avaliacao ou ajuste.
- **O que falsifica:** chamada runtime nova a `recordFeedback(...)` ou query que
  leia payload de `ml_prompt_feedback` alem de `COUNT(*)`.

#### P3 — `commander_reference_decks` e `commander_reference_deck_cards` sao lineage bruto, nao consumo runtime direto

- **Tabelas:** `commander_reference_decks` e
  `commander_reference_deck_cards`.
- **Definicao:** `server/lib/ai/commander_reference_deck_corpus_support.dart:1177`
  cria `commander_reference_decks`, `:1200` cria
  `commander_reference_deck_cards`, e `:1215` cria o agregado consumido
  `commander_reference_deck_analysis`.
- **Escritas encontradas:** `server/lib/ai/commander_reference_deck_corpus_support.dart:1245`
  insere/upserta `commander_reference_decks`, `:1329` remove cards antigos por
  `source_deck_key`, e `:1345` insere `commander_reference_deck_cards`.
- **Leitura runtime encontrada:** o runtime de guidance le o agregado
  `commander_reference_deck_analysis` em `server/lib/ai/commander_reference_deck_corpus_support.dart:389`.
  `server/routes/ai/generate/index.dart:82` e `:920`, e
  `server/lib/ai/commander_reference_readiness_support.dart:338`, chamam
  `loadCommanderReferenceDeckCorpusGuidance`, que usa esse agregado.
- **Leitura raw nao encontrada:** nenhum `SELECT/JOIN` de
  `commander_reference_decks` ou `commander_reference_deck_cards` em
  `server/routes`, `server/lib`, `server/bin` ou `app/lib` fora da manutencao
  do corpus.
- **Por que parece parcialmente consumida:** as tabelas raw podem ser uteis como
  lineage/audit/reprocessamento, mas o produto atual nao consulta os decks ou
  cartas brutas; a decisao runtime vem do agregado.
- **O que valida:** documentar essas tabelas como lineage com retencao e job de
  reprocessamento, ou criar consumidor operacional dos raws.
- **O que falsifica:** `SELECT/JOIN` runtime usando os raws para gerar guidance,
  diagnostico, reprocessamento incremental ou auditoria operacional.

### Itens verificados e nao promovidos

- `commander_reference_deck_analysis` nao foi tratada como nao usada: ha leitura
  direta em `loadCommanderReferenceDeckCorpusGuidance` e chamadas runtime em
  `/ai/generate` e readiness.
- `battle_simulations`, `format_staples`, `rules` e `sync_state` apareceram em
  checks auxiliares, mas possuem leitura operacional confirmada e nao entraram
  como achado desta rodada.
- O script `server/bin/audit_schema_usage.py` nao foi executado porque contem
  `DB_URL` hardcoded; apenas foi lido como referencia de abordagem. O arquivo
  tambem gera relatorio de colunas, nao prova tabela sem uso.

## Rodada focada: Duplicated or similar logic — revalidacao 2026-05-31 19:00 UTC

Escopo desta rodada: somente logica duplicada ou similar com risco de drift.
Nao foi executada auditoria ampla de classes sem uso, funcoes sem chamada,
imports/ciclos, tabelas PostgreSQL ou coerencia entre camadas fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `rg` nao esta instalado neste shell local (`command -v rg` sem saida);
  buscas focadas usaram `grep`, `git grep`, `nl -ba` e `sed`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor textual lista nomes duplicados e
colisoes por regex, mas mistura SQL, palavras comuns e wrappers legitimos com
duplicacao real. A execucao tambem voltou a duplicar blocos historicos do
Markdown; essa escrita automatica foi descartada antes dos achados manuais
abaixo.

### Achados revalidados

#### P1 — `resolveOptimizeArchetype` ainda tem duas semanticas runtime

- **Duplicacao:** `server/lib/ai/deck_state_analysis.dart:573`-`:585` e
  `server/lib/ai/optimize_runtime_support.dart:3369`-`:3389` definem
  `resolveOptimizeArchetype`.
- **Evidencia de drift:** a versao de deck state aceita
  `requestedArchetype` nullable, trata `general` e `tempo` como genericos e
  retorna `detected` quando `requested` e vazio. A versao de optimize exige
  string, trata `unknown` como vazio, usa `goodstuff` como generico e so aceita
  detected especifico em `aggro/control/combo/stax/tribal`.
- **Consumo runtime divergente:** `server/lib/ai/optimize_request_support.dart:289`
  e `:294` usam a versao de optimize; `server/lib/ai/rebuild_guided_service.dart:171`
  usa a versao de deck state.
- **Por que e duplicacao relevante:** optimize e rebuild podem resolver
  arquetipo efetivo diferente para o mesmo par `requested/detected`.
- **O que valida:** um helper unico com testes para `null`, vazio, `unknown`,
  `general`, `tempo`, `goodstuff`, `midrange` e detected especifico.
- **O que falsifica:** contrato documentado e testado dizendo que optimize e
  rebuild devem resolver arquetipos por regras diferentes.

#### P1 — Heuristicas de roles semanticos altos continuam duplicadas e divergentes

- **Duplicacao:** `server/lib/ai/functional_card_tags.dart:859`-`:907` define
  `_looksLikeWincon`, `_looksLikeComboPiece`, `_looksLikeEngine`,
  `_looksLikePayoff` e `_looksLikeEnabler`; `server/lib/ai/optimization_functional_roles.dart:370`-`:397`
  define os mesmos conceitos para o optimize.
- **Evidencia de drift:** `functional_card_tags.dart` usa nomes conhecidos
  (`Thassa's Oracle`, `Isochron Scepter`, `Dramatic Reversal`, `Blood Artist`,
  `Greaves`, `Boots`) mais padroes de `oracle_text`. `optimization_functional_roles.dart`
  usa outro conjunto de padroes textuais e nao recebe o nome da carta nesses
  helpers.
- **Por que e duplicacao relevante:** deck analysis e candidate quality podem
  classificar uma carta como combo/payoff/enabler enquanto o optimize reduz a
  mesma carta a outro role primario ou `utility`.
- **O que valida:** adapter compartilhado que aceite nome, `oracle_text`,
  `type_line`, `functional_tags` e `semantic_tags_v2`, preservando multi-role e
  expondo `primary_role` de forma explicita.
- **O que falsifica:** prova de que as heuristicas duplicadas rodam em dominios
  isolados sem comparacao/decisao cruzada entre analysis, candidate quality,
  validator e optimize.

#### P2 — `isBasicLandName`/`_isBasicLandName` tem quatro variantes incompatíveis

- **Duplicacao:** `server/lib/ai/optimize_runtime_support.dart:4184`-`:4197`,
  `server/lib/generated_deck_validation_service.dart:752`-`:763`,
  `server/lib/meta/meta_deck_reference_support.dart:890`-`:903` e
  `server/routes/ai/commander-reference/index.dart:621`-`:628`.
- **Evidencia de drift:** optimize faz match exato para `snow-covered ...`;
  generated validation aceita `startsWith('snow-covered ...')`; meta reference
  procura `snow covered ...` sem hifen; commander-reference nao inclui snow
  basics.
- **Por que e duplicacao relevante:** a mesma carta basica snow pode ser
  ignorada/contada de forma diferente em optimize, validacao de deck gerado,
  meta reference e commander-reference.
- **O que valida:** helper unico de terrenos basicos/snow basics reutilizado nos
  quatro fluxos, com testes de hifen, sem hifen, whitespace e sufixos.
- **O que falsifica:** se cada fluxo tiver regra intencional diferente para
  snow basics, com teste e justificativa de produto por fluxo.

#### P2 — Trust social repete SQL e serializer entre trades e marketplace

- **Duplicacao:** `server/routes/trades/index.dart:557`-`:635` e
  `server/routes/trades/[id]/index.dart:260`-`:338` duplicam
  `_trustStatsSql`, `_responseTimeSql`, `_shippingTimeSql` e
  `_buildTrustInsight`. `server/routes/community/marketplace/index.dart:131`-`:162`
  repete os LATERALs de trust/response/shipping inline e `:316`-`:348` repete
  o serializer `_buildTrustInsight`.
- **Evidencia de drift:** os shapes de resposta sao equivalentes hoje
  (`completed_trades`, tempos medios, `is_new_account`,
  `profile_incomplete`, `has_insufficient_history`), mas marketplace nao
  reutiliza os mesmos helpers SQL das rotas de trades.
- **Por que e duplicacao relevante:** qualquer mudanca em calculo de trust,
  janela de conta nova ou campos obrigatorios de perfil precisa ser replicada
  em tres pontos.
- **O que valida:** extrair helper/lib de trust social com SQL fragments e
  serializer compartilhado, coberto por testes de listagem, detalhe e
  marketplace.
- **O que falsifica:** contrato separado de marketplace que prove shape/calculo
  diferente de trust, com divergencia esperada e testada.

#### P2 — Logging de payload invalido e request id se repetem nas rotas sociais

- **Duplicacao:** `_requestId` + `_logInvalidPayload` aparecem com corpos quase
  iguais em `server/routes/trades/[id]/status.dart:260`-`:284`,
  `server/routes/trades/[id]/respond.dart:154`-`:178`,
  `server/routes/trades/[id]/messages.dart:228`-`:252` e
  `server/routes/conversations/[id]/messages.dart:247`-`:271`.
- **Controle existente:** `server/lib/request_trace.dart:48`-`:57` ja expoe
  `getRequestTrace` e `tryGetRequestId`, mas essas rotas continuam lendo
  `RequestTrace` diretamente e repetindo fallback para header/`n/a`.
- **Por que e duplicacao relevante:** alteracoes de formato do log social,
  fallback de request id ou campos sanitizados podem ficar dessincronizadas.
- **O que valida:** helper unico para log social de payload invalido, usando
  `tryGetRequestId(context)` e aceitando endpoint/id/reason.
- **O que falsifica:** razao operacional documentada para manter cada log com
  formato local independente.

#### P2/P3 — Regras de `condition`, CMC e tipo principal seguem espalhadas

- **Duplicacao de condition:** `server/routes/decks/[id]/cards/index.dart:397`-`:404`
  normaliza invalido para `NM`; `server/routes/binder/index.dart:275`-`:280`
  rejeita invalido com `400`; `server/routes/community/marketplace/index.dart:39`-`:42`
  filtra apenas quando a condition e valida.
- **Duplicacao de CMC/tipo:** `server/routes/decks/[id]/index.dart:405`-`:435`
  e `server/routes/community/decks/[id].dart:91`-`:117` repetem
  `getMainType`/`calculateCmc`; `server/routes/decks/[id]/simulate/index.dart:171`-`:186`
  tem terceira variante de CMC.
- **Por que e duplicacao relevante:** condition invalida tem comportamento
  diferente por endpoint, e CMC/type grouping pode divergir entre deck privado,
  deck publico e simulacao.
- **O que valida:** helper compartilhado para condition com modo explicito
  `defaultToNm` vs `rejectInvalid`, e helper compartilhado para CMC/tipo.
- **O que falsifica:** documentacao de contrato afirmando que cada endpoint deve
  responder de forma diferente para condition invalida, com testes que protejam
  essa diferenca.

### Itens verificados e nao classificados como novo problema

- `server/routes/ai/optimize/index.dart:56`-`:62` e wrapper fino que delega para
  `optimize_support.resolveOptimizeArchetype`; nao foi contado como corpo
  duplicado novo.
- O relatorio textual do auditor listou muitos falsos positivos como `COUNT`,
  `COALESCE`, `LATERAL`, `NOW`, `AND`, nomes de tabelas e palavras de SQL.
  Esses itens nao foram promovidos sem evidencia manual de duplicacao semantica.

## Rodada focada: Functions not called — revalidacao 2026-05-31 07:00 UTC

Escopo desta rodada: somente funcoes definidas sem chamador runtime confirmado.
Nao foi executada auditoria ampla de classes, imports/ciclos, tabelas
PostgreSQL, duplicacao geral ou coerencia entre camadas fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `rg` nao esta instalado neste shell local (`command -v rg` sem saida);
  buscas focadas usaram `grep`, `git grep` e `nl -ba`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor textual nao constroi grafo de chamadas e
nao prova funcao sem uso. A execucao tambem voltou a duplicar blocos historicos
do Markdown ao escrever a secao gerada; essa escrita automatica foi descartada
antes de registrar os achados manuais abaixo.

### Achados revalidados

#### P1 — `server/lib/sync_cards_utils.dart` segue testavel, mas sem consumo pelo sync real

- **Funcoes:** `extractCardRow`, `getNewSetCodesSinceFromData`,
  `parseSinceDays`, `extractSetCardRow`, `extractOracleIds` e
  `extractLegalities` em `server/lib/sync_cards_utils.dart:16`, `:82`, `:102`,
  `:116`, `:161` e `:172`.
- **Evidencia de uso encontrado:** `server/test/sync_cards_test.dart` importa
  `../lib/sync_cards_utils.dart` e chama essas funcoes em testes.
- **Evidencia de ausencia runtime:** `git grep` em `server/lib`,
  `server/routes`, `server/bin`, `app/lib` e testes encontrou as funcoes
  publicas somente no arquivo utilitario e em `server/test/sync_cards_test.dart`.
- **Controle no sync real:** `server/bin/sync_cards.dart:62`, `:141` e `:554`
  chamam copias privadas `_parseSinceDays`, `_getNewSetCodesSinceFromData` e
  `_extractCardRow`, definidas em `:376`, `:413` e `:680`. O caminho
  incremental tambem monta rows e legalidades inline em `:604`-`:663` e
  `:806`-`:839`, em vez de usar `extractSetCardRow`, `extractOracleIds` ou
  `extractLegalities`.
- **Por que parece nao chamada:** o arquivo extraido como utilitario e coberto
  por teste, mas o entrypoint operacional `sync_cards.dart` continua mantendo
  as versoes privadas/inline.
- **O que valida:** trocar o CLI para importar `sync_cards_utils.dart` e usar os
  helpers publicos, mantendo `sync_cards_test` como cobertura do caminho real.
- **O que falsifica:** um entrypoint runtime fora de teste que importe
  `sync_cards_utils.dart` ou a decisao documentada de manter o arquivo apenas
  como fixture/test oracle.

#### P2 — Wrappers de request trace existem, mas rotas/libs leem `RequestTrace` diretamente

- **Funcoes:** `getRequestTrace` e `tryGetRequestId` em
  `server/lib/request_trace.dart:48` e `:51`.
- **Evidencia de ausencia:** `git grep` em `server`/`app` encontrou
  `getRequestTrace` apenas na propria definicao e dentro de `tryGetRequestId`;
  `tryGetRequestId` apareceu apenas na propria definicao.
- **Controle positivo:** a middleware cria/prove `RequestTrace` em
  `server/routes/_middleware.dart:29`-`:64`, e o uso runtime existe por
  `context.read<RequestTrace>()`, por exemplo em
  `server/lib/auth_middleware.dart:57`, `server/lib/observability.dart:225`,
  `server/routes/_middleware.dart:208`,
  `server/routes/trades/[id]/status.dart:262`,
  `server/routes/trades/[id]/respond.dart:156`,
  `server/routes/trades/[id]/messages.dart:230`,
  `server/routes/conversations/[id]/messages.dart:249`,
  `server/routes/trades/index.dart:332` e
  `server/routes/users/[id]/follow/index.dart:99`.
- **Por que parece nao chamada:** o provider de trace e vivo, mas os wrappers
  publicos nao foram adotados pelos consumidores.
- **O que valida:** substituir os reads diretos por `getRequestTrace`/
  `tryGetRequestId` onde o fallback for desejado, ou remover os wrappers e
  padronizar o acesso direto.
- **O que falsifica:** chamada runtime nova a `getRequestTrace(context)` ou
  `tryGetRequestId(context)` fora do arquivo de definicao.

#### P2 — Wrappers especificos de Commander Reference/Lorehold ficaram apenas em testes

- **Funcoes:** `normalizedCommanderReferenceCandidate` em
  `server/lib/ai/commander_reference_profile_support.dart:49` e
  `buildLoreholdReferenceCardStatsFromProfile` em
  `server/lib/ai/commander_reference_card_stats_support.dart:257`.
- **Evidencia de ausencia:** `git grep` encontrou
  `normalizedCommanderReferenceCandidate` somente na propria definicao.
  `buildLoreholdReferenceCardStatsFromProfile` e chamado por
  `server/test/commander_reference_card_stats_support_test.dart:13`, mas nao
  por `server/lib`, `server/routes` ou `server/bin`.
- **Controle positivo:** as funcoes genericas continuam vivas:
  `normalizeCommanderReferenceName` e `isLoreholdCommanderReferenceCandidate`
  sao chamados em `commander_reference_card_stats_support.dart`,
  `commander_reference_generate_fallback_support.dart`,
  `commander_reference_readiness_support.dart`,
  `server/routes/ai/archetypes/index.dart` e
  `server/routes/ai/generate/index.dart`; o fluxo de stats chama
  `buildCommanderReferenceCardStatsFromProfile` em
  `commander_reference_card_stats_support.dart:368`.
- **Por que parece nao chamada:** os wrappers especificos duplicam conveniencia
  sobre helpers genericos, mas o runtime usa os genericos diretamente.
- **O que valida:** remover os wrappers especificos ou religar testes/seeders ao
  caminho generico que o produto usa.
- **O que falsifica:** job/rota/bin que consuma os wrappers especificos fora de
  teste.

#### P2 — `extractMtgTop8FormatCodeFromSourceUrl` nao participa do reparo MTGTop8

- **Funcao:** `extractMtgTop8FormatCodeFromSourceUrl` em
  `server/lib/meta/mtgtop8_meta_support.dart:139`.
- **Evidencia de ausencia:** `git grep` encontrou chamada runtime apenas para
  `extractMtgTop8EventIdFromSourceUrl` em
  `server/bin/repair_mtgtop8_meta_history.dart:59`; a variante de format code
  apareceu somente na propria definicao e em
  `server/test/mtgtop8_meta_support_test.dart:147`.
- **Por que parece nao chamada:** o reparo historico usa o event id do source
  URL, mas nenhum fluxo usa o parametro `f` como dado operacional.
- **O que valida:** consumir o format code no reparo/ingestao MTGTop8 quando ele
  for parte do contrato, ou remover o helper e o teste especifico.
- **O que falsifica:** chamada runtime nova a
  `extractMtgTop8FormatCodeFromSourceUrl`.

#### P2 — Helpers de diagnostico de candidate quality/aggressive optimize continuam sem runtime

- **Funcoes:** `buildCandidateQualitySamplePoolSql` em
  `server/lib/ai/candidate_quality_data_support.dart:631` e
  `summarizeAggressiveOptimizeUtilitySamples` em
  `server/lib/ai/optimize_runtime_support.dart:3326`.
- **Evidencia de ausencia:** `git grep` em `server`/`app`, excluindo docs e
  testes, encontrou somente as definicoes. Chamadas existem em
  `server/test/candidate_quality_data_support_test.dart:123` e
  `server/test/optimize_runtime_support_test.dart:169`.
- **Por que parece nao chamada:** os helpers descrevem suporte de diagnostico/
  amostragem, mas nao ha rota, bin ou job que execute a amostra ou publique o
  resumo.
- **O que valida:** criar runner/rota interna documentada para a amostragem de
  candidate quality e usar o summary como gate operacional.
- **O que falsifica:** um consumidor runtime desses helpers fora de teste.

#### P2 — `MLKnowledgeService.recordFeedback` tem tabela e insert, mas nenhum chamador

- **Funcao:** `recordFeedback` em `server/lib/ml_knowledge_service.dart:251`.
- **Evidencia de ausencia:** `git grep -n "recordFeedback" -- server app`
  encontrou somente a propria definicao.
- **Controle positivo:** `MLKnowledgeService` e instanciado em
  `server/lib/ai/otimizacao.dart:33`, e outras leituras do service aparecem no
  mesmo modulo; o problema e especifico do caminho de feedback.
- **Por que parece nao chamada:** ha `INSERT INTO ml_prompt_feedback` em
  `recordFeedback`, mas nenhuma rota/app/job chama o metodo, entao o feedback
  de usuario nao entra no fluxo operacional.
- **O que valida:** adicionar endpoint/job app-facing ou interno para gravar
  feedback e teste de contrato, ou remover o metodo/tabela se o produto nao vai
  coletar feedback.
- **O que falsifica:** chamada runtime a `recordFeedback(...)` fora do service.

#### P3 — API manual de metricas do `PerformanceService` nao tem uso em `app/lib`

- **Funcoes:** `startTrace`, `stopTrace`, `traceAsync`, `addMetric`,
  `addAttribute`, `getLocalStats` e `printLocalStats` em
  `app/lib/core/services/performance_service.dart:110`, `:130`, `:158`,
  `:200`, `:210`, `:220` e `:248`.
- **Evidencia de ausencia no app runtime:** `git grep` em `app/lib` encontrou
  essas funcoes somente no proprio arquivo; `traceAsync` aparece em
  `app/integration_test/release_observability_smoke_test.dart:51`, mas nao em
  codigo runtime do app.
- **Controle positivo:** a coleta automatica por navegacao esta ativa:
  `app/lib/main.dart:121` inicializa `PerformanceService.instance.init()` e
  `app/lib/main.dart:208` registra `PerformanceNavigatorObserver()`, que chama
  `startScreenTrace`/`stopScreenTrace` em
  `performance_service.dart:295`, `:307`, `:334` e `:339`.
- **Por que parece nao chamada:** a camada automatica de screen traces e viva,
  mas a API manual/custom metrics ficou sem consumidor em features, providers ou
  API client.
- **O que valida:** instrumentar operacoes reais com `traceAsync`/metricas ou
  reduzir a API publica para a parte automatica usada.
- **O que falsifica:** chamada em `app/lib` para qualquer uma das APIs manuais.

### Itens verificados e nao classificados como novo problema

- `headerValueIgnoreCase`, `generateRequestId` e `resolveRequestId` em
  `server/lib/request_trace.dart` continuam vivos: `resolveRequestId` e chamado
  por `server/routes/_middleware.dart:29`, e os demais sao usados por esse
  caminho ou cobertos por teste.
- `PerformanceService`, `startScreenTrace`, `stopScreenTrace` e
  `PerformanceNavigatorObserver` nao foram classificados como sem uso porque
  `app/lib/main.dart:121` e `:208` ativam o servico e o observer no app.
- `buildCommanderReferenceCardStatsFromProfile` nao foi classificado como sem
  uso porque e chamado pelo fluxo real em
  `server/lib/ai/commander_reference_card_stats_support.dart:368`.

## Rodada focada: Semantica de cartas por nome — revalidacao 2026-05-31 05:30 UTC

Escopo desta rodada: nomes hardcoded em runtime, drift entre
`functional_tags`, `semantic_tags_v2` e classificacao funcional do optimize, e
uso real de sinais de utilidade (`oracle_text`, `type_line`, `mana_cost`,
`cmc`, tags persistidas e deltas de roles). O foco primario foi `server/lib`,
`server/routes` e `app/lib`; testes/docs/artifacts foram considerados apenas
para separar exemplos/fixtures de logica de produto.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `rg` nao esta instalado neste shell local (`command -v rg` sem saida);
  buscas focadas usaram `grep -RIn --include='*.dart'` e `nl -ba`.

### Classificacao de nomes hardcoded

#### Allowed — exemplos de UI, contrato ou comentario sem decisao semantica

- `server/routes/cards/resolve/batch/index.dart:13`-`:22` usa `Sol Ring`,
  `Command Tower` e `Arcane Signet` apenas como exemplo de contrato em comentario
  da rota.
- `server/routes/import/index.dart:182`,
  `server/routes/import/to-deck/index.dart:102`,
  `app/lib/features/decks/providers/deck_provider.dart:1027`,
  `app/lib/features/decks/screens/deck_import_screen.dart:385`-`:392` e
  `:591`-`:592`, e
  `app/lib/features/decks/widgets/deck_import_list_dialog.dart:154` usam nomes
  como exemplo de formato de lista/importacao. Isso nao decide utilidade, score
  ou validacao.
- `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:39`-`:44`
  e `app/lib/features/home/life_counter_screen.dart:2199`-`:2204` usam nomes
  conhecidos como sugestoes de busca no life counter. E runtime de UI, mas nao
  participa de optimize, recomendacao, validacao ou analise funcional.
- `server/lib/card_validation_service.dart:242`,
  `server/lib/ai/otimizacao.dart:514` e
  `app/lib/features/scanner/services/card_recognition_service.dart:122`
  apareceram como comentarios/exemplos. Sem acao.

O que falsificaria esta classificacao: qualquer um desses exemplos passar a
alimentar score, role, bracket, validacao, sugestao automatica ou filtro de
candidate quality.

#### Intentional exception — policy de regras externas EDH/bracket

- `server/lib/edh_bracket_policy.dart:134`-`:142` classifica combo infinito e
  Game Changer por listas curadas, e `:251`-`:264`, `:271`-`:276`,
  `:280`-`:292` declaram nomes de fast mana, combo pieces e Game Changers.
- Por que e excecao intencional: Game Changers e combos infinitos conhecidos
  sao regras externas/listas curadas que nao sao inferiveis com seguranca apenas
  por `oracle_text`.
- Risco residual: as listas ainda estao inline no codigo, com comentarios de
  placeholder/lista inicial. Devem virar policy versionada com fonte, data e
  teste dedicado.
- O que valida: teste especifico para Game Changers e infinite combo policy,
  com fonte/versionamento e snapshot sanitizado da lista esperada.
- O que falsifica: se a policy passar a ser gerada de tabela/config versionada
  e o codigo deixar de carregar nomes inline.

#### Risk — classificadores funcionais ainda inferem roles por nomes especificos

- `server/lib/ai/functional_card_tags.dart:220`-`:226` marca ramp por
  `signet`, `talisman`, `sol ring` e `arcane signet`; `:714`-`:717` marca
  protecao por nomes como `Teferi's Protection`, `Heroic Intervention`,
  `Swiftfoot Boots` e `Lightning Greaves`; `:755`-`:756`, `:780`, `:824`,
  `:835`, `:851`, `:860`-`:871`, `:888`-`:899` usam nomes conhecidos para
  aristocrats, drain, blink, ritual/big spell, wincon, combo, payoff e enabler.
- `server/lib/ai/candidate_quality_data_support.dart:375`-`:379`,
  `:421`-`:428`, `:439`-`:445`, `:472`-`:478`, `:531`-`:542`,
  `:590`-`:605` e `:611`-`:628` repetem parte dessas decisoes e ainda aplicam
  bonus premium/bracket por listas `highPowerNames` e `premium`.
- Por que e risco: a classificacao de utilidade muda por nome mesmo quando
  `oracle_text`, `type_line`, `mana_cost`, `cmc` ou tags persistidas poderiam
  explicar a funcao. Tambem ha drift: `functional_card_tags.dart` reconhece
  `Thassa's Oracle`/`Isochron Scepter`/`Dramatic Reversal` por nome, enquanto o
  fallback de `optimization_functional_roles.dart:370`-`:397` nao usa esses
  nomes e reconhece outro conjunto de padroes textuais.
- O que valida: mover excecoes por nome para policy/tabela versionada com
  `role`, `reason`, `source`, `confidence` e teste; manter os classificadores
  puros dependentes de texto/tipo/custo ou tags persistidas.
- O que falsifica: prova de que todos esses nomes sao apenas backfill
  offline/seed e nunca influenciam runtime de optimize, candidate quality,
  analysis ou validator.

#### Risk — optimize, generate fallback, rebuild e recomendacoes ainda usam listas fixas de cartas

- `server/lib/ai/commander_reference_generate_fallback_support.dart:182`-`:194`
  e `:232`-`:244` contem fallback deterministico Lorehold com nomes fixos como
  `Sol Ring`, `Arcane Signet`, `Boros Charm`, `Swiftfoot Boots`,
  `Lightning Greaves` e `Teferi's Protection`.
- `server/lib/ai/optimize_runtime_support.dart:406`-`:454` da bonus forte para
  terrenos premium por nome; `:1296`-`:1312` adiciona staples fixos quando a
  busca retorna poucos candidatos; `:1948`-`:2051` combina denylist/premium
  filler por nome com score; `:3476`-`:3510` usa fallback universal por nomes;
  `:3571`-`:3578` inicia fallback contextual com nomes fixos.
- `server/lib/ai/rebuild_guided_service.dart:1226`-`:1231` classifica ramp por
  `signet`/`sol ring`/`talisman`, e `:1331`-`:1338`, `:1404`-`:1411` penalizam
  ou priorizam utility lands especificas por nome.
- `server/routes/decks/[id]/recommendations/index.dart:262`-`:267` recomenda
  `Command Tower` diretamente quando Commander tem poucos terrenos; `:408`-`:426`
  busca staples por raridade `rare/mythic`, nao por role semantico.
- `server/routes/ai/weakness-analysis/index.dart:41`-`:59` carrega so
  nome/tipo/oracle/custo/cores/quantidade/cmc, `:114`-`:162` recalcula buckets
  por heuristicas locais, e `:206`-`:284` retorna listas fixas de nomes para
  ramp, draw, removal, wipes e protecao.
- Por que e risco: esses caminhos estao em runtime e podem recomendar/adicionar
  cartas por fama/lista local em vez de sinais persistidos, legalidade, cor,
  bracket, budget e papel funcional compartilhado.
- O que valida: substituir listas inline por query de candidatos com
  `card_function_tags`, `card_semantic_tags_v2`, `card_role_scores`,
  commander synergy, legalidade, identidade de cor, bracket e budget, mantendo
  listas conhecidas apenas como policy versionada ou corpus declarado.
- O que falsifica: testes que provem que essas listas rodam somente como fallback
  interno controlado, depois de falha de dados semanticos, com diagnostico
  explicito e sem alterar fluxo app-facing padrao.

### Drift semantico confirmado

#### P1 — Deck analysis prefere `card_function_tags`; optimize/validator nao carrega esse sinal

- `server/routes/decks/[id]/analysis/index.dart:80`-`:96` seleciona
  `card_function_tags` e `semantic_tags_v2`, e `:278`-`:284` usa
  `summarizeFunctionalTagsForDeck`.
- `server/routes/decks/[id]/ai-analysis/index.dart:119`-`:135` faz o mesmo e
  `:331`-`:335` consome `summarizeFunctionalTagsForDeck`.
- `server/lib/ai/functional_card_tags.dart:400`-`:465` prefere
  `functional_tags` persistidos quando existem e so cai para heuristica depois.
- Em contraste, `server/lib/ai/optimize_request_support.dart:91`-`:109` carrega
  `semantic_tags_v2`, mas nao `card_function_tags`; `:186`-`:198` monta
  `allCardData` sem `functional_tags`; `:323`-`:339` confirma que o select
  auxiliar agrega apenas `card_semantic_tags_v2`.
- `server/routes/ai/optimize/index.dart:2068`-`:2099` e `:3197`-`:3213` repetem
  o mesmo padrao para dados das adicoes: `semantic_tags_v2` sim,
  `functional_tags` nao.
- Impacto: uma carta pode contar como `engine`, `payoff`, `enabler`, ramp ou
  protecao na aba de analise por tag persistida e cair para outro role no
  optimize/validator se a v2 estiver ausente, baixa confianca ou incompleta.
- Correcao estreita: incluir `card_function_tags` nos loaders de optimize e
  criar um adapter unico que retorne `roles` multi-valor + `primary_role`,
  usando ordem `functional_tags` persistidos -> `semantic_tags_v2` persistido ->
  fallback textual.

#### P1 — `semantic_tags_v2` multi-tag e colapsado em um unico role no optimize

- `server/lib/ai/optimization_functional_roles.dart:55`-`:58` usa
  `_classifySemanticV2FunctionalRole` antes do fallback textual.
- `:127`-`:180` escolhe o registro v2 de maior `role_confidence` e retorna o
  primeiro role conforme uma ordem fixa (`board_wipe`, depois draw/removal/ramp
  etc.; flags `engine`, `payoff`, `enabler` so depois). Roles secundarios sao
  descartados.
- `:292`-`:324` calcula `role_delta` tambem com um role unico por carta.
- `server/lib/ai/optimization_validator.dart:266`-`:267` e `:342` usam esse
  classificador/delta; `server/lib/ai/optimization_quality_gate.dart:52`-`:53`
  usa o mesmo role unico para bloquear swaps.
- Impacto: uma carta multi-funcao pode ser preservada como `draw`, mas perder
  `engine`/`payoff`/`combo_piece` sem que o delta mostre a perda. O comentario
  em `optimization_functional_roles.dart:111`-`:112` diz que high-level roles
  sao checados antes do fallback de tipo, mas no fallback textual eles ficam
  depois de wipe/protection/removal/ramp/draw/tutor (`:63`-`:117`), entao o
  proprio codigo ja expressa precedencia divergente.
- Correcao estreita: trocar o retorno scalar por estrutura com `primary_role`,
  `roles`, `source`, `confidence_by_role`; manter compatibilidade serializando o
  `primary_role` antigo enquanto o validator/gate calcula deltas multi-role.

### Avaliacao de utilidade real

- Positivo: deck analysis usa dados persistidos primeiro
  (`card_function_tags` + `semantic_tags_v2`) e fallback textual depois.
- Positivo parcial: optimize/validator usam `semantic_tags_v2` quando existe e
  tem confianca minima (`optimization_functional_roles.dart:145`-`:146`), depois
  caem para `type_line`/`oracle_text`.
- Risco: candidate quality ainda soma bonus por nome em
  `candidate_quality_data_support.dart:531`-`:542`, `:590`-`:605` e
  `:611`-`:628`.
- Risco: weakness-analysis nao le `card_function_tags`, `semantic_tags_v2` nem
  `card_role_scores`; recalcula tudo localmente e retorna nomes fixos.
- Risco: recommendations usa `Command Tower` direto e usa raridade como proxy
  de alto impacto.

### Itens verificados e nao promovidos a problema

- Nomes em testes, corpus, docs, comentarios de contrato e exemplos de import
  nao foram tratados como bug de produto.
- Listas de terrenos basicos (`Island`, `Forest`, etc.) nao foram classificadas
  como problema sem evidencia de decisao de utilidade; elas sao necessarias para
  regras de deckbuilding, import e fallback de mana base.

## Rodada focada: Classes not used — revalidacao 2026-05-31 03:00 UTC

Escopo desta rodada: somente classes definidas sem uso runtime confirmado. Nao
foi executada auditoria ampla de funcoes sem chamada, imports/ciclos, tabelas
PostgreSQL, duplicacao geral ou coerencia entre camadas fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `a1a48fe9`.
- `rg` nao esta instalado neste shell local (`command -v rg` sem saida);
  buscas focadas usaram `grep -RIn --include='*.dart'`, `find`, `nl -ba` e
  uma triagem textual local para filtrar classes publicas sem referencia fora
  do arquivo de definicao.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor textual cobre `server/lib` e
`server/routes`, inventaria classes, mas nao constroi grafo de chamadas nem
cobre consumo do Flutter em `app/lib`. A escrita automatica do script tambem
pode duplicar blocos historicos no Markdown; nesta rodada a duplicacao gerada
foi descartada antes de registrar os achados manuais abaixo.

### Achados revalidados

#### P1 — `LifeCounterScreen` legado segue fora do caminho runtime do app

- **Classe:** `LifeCounterScreen` em
  `app/lib/features/home/life_counter_screen.dart:61`.
- **Rota ativa:** `app/lib/main.dart:54` importa
  `features/home/lotus_life_counter_screen.dart`; `app/lib/main.dart:281`-`:283`
  registra `path: lifeCounterRoutePath` com `const LotusLifeCounterScreen()`.
- **Evidencia de ausencia em `app/lib`:** busca focada por `LifeCounterScreen`
  em `app/lib` encontrou apenas a propria definicao/construtor/createState em
  `app/lib/features/home/life_counter_screen.dart:61`-`:77`.
- **Evidencia de teste legado:** `app/test/features/home/life_counter_screen_test.dart:9`
  e `app/test/features/home/life_counter_clone_proof_test.dart:10` importam
  `life_counter_screen.dart`; os testes instanciam `LifeCounterScreen`, mas nao
  provam a rota viva do app.
- **Por que parece nao usada:** o runtime roteado para `/life-counter` usa Lotus,
  enquanto a tela Flutter nativa permanece como caminho legado/test harness.
- **O que valida:** remover a tela nativa ou documenta-la como fixture legado
  com ownership claro e testes nomeados como legacy.
- **O que falsifica:** uma rota, flag ou chamada em `app/lib` que instancie
  `LifeCounterScreen` fora dos testes.

#### P2 — `DeckCard` permanece testado, mas sem uso confirmado na listagem real

- **Classe:** `DeckCard` em `app/lib/features/decks/widgets/deck_card.dart:17`.
- **Evidencia de ausencia em `app/lib`:** busca focada por import de
  `deck_card.dart` em `app/lib` nao retornou ocorrencias; busca por `DeckCard`
  em `app/lib` encontrou apenas a definicao e o construtor em
  `app/lib/features/decks/widgets/deck_card.dart:17` e `:22`.
- **Evidencia de uso apenas por testes:**
  `app/test/features/decks/widgets/deck_card_test.dart:4` e
  `app/test/features/decks/widgets/deck_card_overflow_test.dart:4` importam o
  widget e instanciam `DeckCard`.
- **Por que parece nao usada:** a listagem real de decks parece ter migrado para
  outros cards locais, enquanto esse widget mantem cobertura de teste sem
  consumidor runtime.
- **O que valida:** remover `DeckCard` e seus testes, ou religar a listagem real
  de decks para usar este widget.
- **O que falsifica:** import de `deck_card.dart` ou chamada `DeckCard(...)` em
  uma tela ativa de `app/lib`.

#### P2 — `DeckProgressChip` nao tem chamada de construtor confirmada

- **Classe:** `DeckProgressChip` em
  `app/lib/features/decks/widgets/deck_progress_indicator.dart:286`.
- **Evidencia de ausencia:** busca focada por `DeckProgressChip` em `app/lib` e
  `app/test` encontrou somente a declaracao da classe e o construtor em
  `app/lib/features/decks/widgets/deck_progress_indicator.dart:286` e `:292`.
- **Controle positivo no mesmo arquivo:** `DeckProgressIndicator` permanece vivo:
  `app/lib/features/decks/screens/deck_details_screen.dart:403` e
  `app/lib/features/decks/widgets/deck_details_overview_tab.dart:328` instanciam
  `DeckProgressIndicator`.
- **Por que parece nao usada:** o componente compacto ficou no arquivo, mas nao
  aparece em cards/listas nem em testes.
- **O que valida:** remover `DeckProgressChip` ou conecta-lo explicitamente a uma
  lista/card que precise do indicador compacto.
- **O que falsifica:** chamada direta a `DeckProgressChip(...)` em `app/lib` ou
  teste dedicado que represente um contrato de componente ainda planejado.

#### P2 — `LotusPresentationMode` nao e usado pelo fluxo Lotus atual

- **Classe:** `LotusPresentationMode` em
  `app/lib/features/home/lotus/lotus_presentation_mode.dart:4`.
- **Evidencia de ausencia:** busca focada por `LotusPresentationMode` em
  `app/lib`, `app/test` e `app/integration_test` encontrou somente a classe e o
  construtor privado em `lotus_presentation_mode.dart:4`-`:5`; busca por
  `enter()`/`exit()` nesse escopo nao encontrou chamada aos metodos estaticos em
  `:15` e `:26`.
- **Por que parece nao usada:** o fluxo vivo `LotusLifeCounterScreen` nao importa
  `lotus_presentation_mode.dart`, entao as chamadas de fullscreen/orientacao nao
  participam do ciclo de vida atual.
- **O que valida:** remover o utilitario ou chamar `LotusPresentationMode.enter`
  e `LotusPresentationMode.exit` no lifecycle do Lotus com teste de contrato.
- **O que falsifica:** import do arquivo e chamada dos metodos no fluxo vivo.

### Itens verificados e nao classificados como novo problema

- `AppObservabilityNavigatorObserver`, `PerformanceNavigatorObserver`,
  `CardRecognitionService` e `MatchupAnalyzer` apareceram em baixa contagem na
  triagem textual, mas tem chamadores runtime confirmados em `app/lib/main.dart`,
  `scanner_provider.dart` e `server/routes/ai/simulate/index.dart`.
- `PostgresExternalCommanderMetaCandidateLegalityRepository` parecia sem uso
  quando a busca cobria apenas `server/lib`/`server/routes`, mas e instanciado
  em `server/bin/import_external_commander_meta_candidates.dart:36` e
  `server/bin/run_external_commander_meta_pipeline.dart:62`.
- DTOs/classes publicas usadas como retorno interno no proprio arquivo nao foram
  promovidas a achado sem prova de que o entrypoint que as produz tambem esta
  sem uso.

## Rodada focada: Coerencia entre modulos `server/lib` ↔ `server/routes` ↔ `app/lib` — revalidacao 2026-05-30 23:00 UTC

Escopo desta rodada: somente coerencia entre `server/lib`, `server/routes` e
`app/lib`, com foco em endpoints app-facing chamados pelo Flutter. Nao foi
executada auditoria ampla de classes sem uso, funcoes sem chamada,
imports/ciclos, tabelas PostgreSQL ou duplicacao geral fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `ea158a39`.
- `rg` nao esta instalado neste shell local (`command -v rg` sem saida);
  buscas focadas usaram `grep -RIn --include='*.dart'`, `nl -ba` e leitura
  pontual dos arquivos.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado reportado pelo script:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor textual cobre `server/lib` e
`server/routes`, mas nao constroi mapa de consumo do Flutter nem valida
ownership/contratos app-facing. Nesta execucao local, a escrita automatica do
script tambem duplicou historico manual no fim do Markdown; a duplicacao gerada
foi descartada e os achados abaixo foram registrados manualmente com evidencia
direta.

### Achados revalidados

#### P1 — `POST /ai/optimize` continua incoerente com o contrato app-facing de deck do usuario

- **Fluxo app-facing:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:10`-`:23`
  monta payload com `deck_id`, `archetype`, `bracket`, `keep_theme` e
  `intensity`; `:56` envia esse payload para `POST /ai/optimize`.
- **Rota:** `server/routes/ai/optimize/index.dart:401`-`:406` le `userId`
  do contexto, mas `:549`-`:558` chama
  `optimize_request.loadOptimizeDeckContext(...)` sem passar `userId`.
- **Support lib:** `server/lib/ai/optimize_request_support.dart:53`-`:62`
  nao aceita `userId`; a query de deck em `:66` usa
  `SELECT name, format FROM decks WHERE id = @id`, e as queries de cartas em
  `:107`-`:109` e `:132`-`:134` filtram somente `dc.deck_id = @id`.
- **Por que parece risco real:** o app trata optimize como acao autenticada no
  deck do usuario, mas a camada `routes -> lib` nao aplica o mesmo ownership
  guard usado por rotas de deck. Um usuario autenticado com UUID de outro deck
  pode potencialmente carregar composicao privada ou gastar processamento de IA.
- **O que valida:** mudar `loadOptimizeDeckContext` para receber `userId` e
  buscar `decks` com `WHERE id = @id AND user_id = @userId` antes de carregar
  cartas, com teste owner vs non-owner para `POST /ai/optimize`.
- **O que falsifica:** documentar e testar uma regra explicita de acesso a deck
  publico/compartilhado para optimize, incluindo resposta esperada do app.

#### P1 — `POST /ai/archetypes` tambem carrega deck/cartas por id sem owner-scope

- **Fluxo app-facing:** `app/lib/features/decks/providers/deck_provider_support_mutation.dart:168`-`:173`
  chama `POST /ai/archetypes` com apenas `{'deck_id': deckId}` e espera
  `options` em status 200.
- **Rota:** `server/routes/ai/archetypes/index.dart:27`-`:32` aceita
  `deck_id`, mas o arquivo nao le `context.read<String>()` nem `getUserId`.
  A query de deck em `:39`-`:41` usa
  `SELECT name, format FROM decks WHERE id = @id`; a query de cartas em
  `:54`-`:60` usa somente `WHERE dc.deck_id = @id`.
- **Por que parece risco real:** o endpoint e consumido pelo provider de decks
  como parte do fluxo autenticado do usuario, mas a rota consegue gerar opcoes
  de arquétipo para qualquer deck cujo UUID seja conhecido, sem alinhar com a
  politica de ownership das rotas `/decks`.
- **O que valida:** ler `userId` na rota e aplicar `WHERE d.id = @id AND
  d.user_id = @userId`, ou centralizar o lookup em support compartilhado com
  `POST /ai/optimize`.
- **O que falsifica:** contrato app-facing que permita archetypes para decks
  publicos/terceiros, com checagem explicita de `is_public` e teste cobrindo
  deck privado alheio.

#### P2 — Polling de jobs optimize ainda aceita jobs persistidos sem dono

- **Fluxo app-facing:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:190`-`:194`
  faz polling em `GET /ai/optimize/jobs/$jobId`.
- **Rota:** `server/routes/ai/optimize/jobs/[id].dart:26` le o usuario
  autenticado e `:28` carrega o job; o bloqueio em `:39`-`:47` so retorna 404
  quando `job.userId != null && job.userId != userId`.
- **Support lib:** `server/lib/ai/optimize_job.dart:25`-`:30` permite criar
  job com `String? userId`; `OptimizeJob.userId` tambem e nullable em
  `server/lib/ai/optimize_job.dart:268`-`:272`, e `fromRow` preserva
  `row['user_id'] as String?` em `:303`-`:308`.
- **Por que parece risco real:** a rota de IA esta sob auth middleware, mas o
  contrato de storage ainda permite `user_id = NULL` e o polling considera
  esses jobs legiveis para qualquer usuario com o id do job. Isso fica
  incoerente com o app, que trata jobs de optimize como resultado privado de um
  deck.
- **O que valida:** exigir `userId` non-null na criacao de jobs app-facing,
  migrar/expirar jobs nulos ou retornar 404 quando `job.userId == null` fora de
  uma rota interna documentada.
- **O que falsifica:** separar jobs internos sem dono de jobs app-facing, com
  endpoint/prefixo distinto e teste que prove que o app nunca recebe job nulo.

### Itens verificados e nao classificados como novo problema

- `POST /ai/rebuild` esta mais coerente com o contrato de deck do usuario:
  `server/routes/ai/rebuild/index.dart:61`-`:78` busca o deck com
  `WHERE d.id = @deckId AND d.user_id = @userId` antes de carregar cartas em
  `:96`-`:128`.
- A middleware de IA continua exigindo auth:
  `server/routes/ai/_middleware.dart:16`-`:20` aplica `authMiddleware`,
  `aiPlanLimitMiddleware` e `aiRateLimit`; o problema acima nao e ausencia de
  auth, e sim falta de owner-scope no lookup de deck dentro de rotas/libs.

## Rodada focada: Duplicated or similar logic — revalidacao 2026-05-30 19:00 UTC

Escopo desta rodada: somente logica duplicada ou similar com risco de drift.
Nao foi executada auditoria ampla de classes sem uso, funcoes sem chamada,
imports/ciclos, tabelas PostgreSQL ou coerencia entre camadas fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: sem saida no inicio da rodada.
- `git rev-parse --short HEAD`: `2079ad28`.
- `rg` nao esta instalado neste shell local (`command -v rg` sem saida);
  buscas focadas usaram `grep -RIn --include='*.dart'`, `nl -ba` e leitura
  pontual dos arquivos.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor textual aponta gargalos, inventario de
funcoes e colisao de nomes, mas nao prova duplicacao semantica. A triagem abaixo
mantem apenas casos em que a leitura direta confirmou mesma pergunta de dominio,
corpo equivalente ou divergencia funcional entre caminhos runtime.

### Achados revalidados

#### P1 — `resolveOptimizeArchetype` continua duplicado entre optimize e deck state

- **Simbolos:** `resolveOptimizeArchetype` em
  `server/lib/ai/deck_state_analysis.dart` e
  `server/lib/ai/optimize_runtime_support.dart`.
- **Evidencia:** `server/lib/ai/deck_state_analysis.dart:573`-`:585`
  aceita `requestedArchetype` nullable e trata `midrange/general/value/tempo`
  como genericos. `server/lib/ai/optimize_runtime_support.dart:3369`-`:3389`
  exige `requestedArchetype` non-null, trata `detected == 'unknown'`, usa
  `midrange/value/goodstuff` como genericos e so troca pelo detected quando ele
  esta em `aggro/control/combo/stax/tribal`.
- **Chamadores que bifurcam o comportamento:** `server/lib/ai/optimize_request_support.dart:289`
  chama a versao de optimize, enquanto
  `server/lib/ai/rebuild_guided_service.dart:171` chama a versao de
  `deck_state_analysis.dart`. O wrapper em
  `server/routes/ai/optimize/index.dart:56`-`:63` apenas delega para
  `optimize_support` e nao foi contado como duplicacao real.
- **Por que parece risco real:** a mesma pergunta de dominio ("qual arquetipo
  efetivo usar?") recebe respostas diferentes para `tempo`, `general`,
  `goodstuff` e `unknown`, podendo fazer optimize e rebuild perseguirem metas
  diferentes para o mesmo deck.
- **O que valida:** centralizar uma unica policy de resolucao de arquetipo e
  adicionar testes cobrindo requested vazio/null, detected `unknown`, genericos
  (`midrange`, `tempo`, `goodstuff`) e detected especifico.
- **O que falsifica:** renomear/documentar contratos distintos para optimize e
  rebuild, com testes provando que a divergencia e intencional.

#### P1 — Roles semanticos altos continuam duplicados com heuristicas divergentes

- **Simbolos:** `_looksLikeWincon`, `_looksLikeComboPiece`,
  `_looksLikeEngine`, `_looksLikePayoff` e `_looksLikeEnabler`.
- **Evidencia em functional tags:** `server/lib/ai/functional_card_tags.dart:319`-`:335`
  chama os helpers para tags multi-role; as definicoes em
  `server/lib/ai/functional_card_tags.dart:859`-`:906` usam `oracle` e
  `normalizedName`, incluindo sentinelas por nome como `Thassa's Oracle`,
  `Isochron Scepter`, `Dramatic Reversal`, `Blood Artist`, `greaves` e `boots`.
- **Evidencia em optimize roles:** `server/lib/ai/optimization_functional_roles.dart:111`-`:117`
  chama helpers de mesmo nome para retornar um role unico; as
  definicoes em `server/lib/ai/optimization_functional_roles.dart:370`-`:397`
  usam apenas `oracle` e padroes diferentes.
- **Chamadores impactados:** `OptimizationValidator` usa
  `classifyOptimizationFunctionalRole` em
  `server/lib/ai/optimization_validator.dart:265`-`:267`, e o quality gate usa
  o mesmo classificador em `server/lib/ai/optimization_quality_gate.dart:52`-`:53`.
- **Por que parece risco real:** deck analysis/candidate quality podem explicar
  uma carta como payoff/combo/enabler por nome ou por heuristica ampla, enquanto
  optimize/validator ve outro papel ou nenhum papel.
- **O que valida:** criar adapter compartilhado que retorne conjunto de roles +
  `primary_role`, usando nome, `oracle_text`, `type_line`, `functional_tags` e
  `semantic_tags_v2`.
- **O que falsifica:** testes cruzados demonstrando que os dois classificadores
  devem divergir por design e que essa divergencia e esperada por fluxo.

#### P2 — Reconhecimento de terrenos basicos segue copiado com variantes

- **Simbolos:** `_isBasicLandName` / `isBasicLandName`.
- **Evidencia:** `server/lib/ai/optimize_runtime_support.dart:4184`-`:4196`
  reconhece snow basics com hifen; `server/lib/generated_deck_validation_service.dart:752`-`:763`
  usa `startsWith('snow-covered ...')`; `server/lib/meta/meta_deck_reference_support.dart:890`-`:903`
  reconhece snow basics com espaco (`snow covered plains`); e
  `server/routes/ai/commander-reference/index.dart:621`-`:628` reconhece
  apenas `plains/island/swamp/mountain/forest/wastes`.
- **Por que parece risco real:** optimize, validacao, meta reference e
  commander-reference usam o mesmo conceito de dominio, mas snow basics podem
  ser aceitos, aceitos por prefixo, aceitos sem hifen ou ignorados dependendo do
  arquivo.
- **O que valida:** extrair helper unico de dominio e cobrir `Snow-Covered
  Plains`, `Snow Covered Plains`, `Wastes`, casing e whitespace.
- **O que falsifica:** contrato/teste mostrando que algum fluxo deve rejeitar
  snow basics propositalmente.

#### P2 — Trust social repete SQL e serializer entre trades e marketplace

- **Simbolos:** `_trustStatsSql`, `_responseTimeSql`, `_shippingTimeSql` e
  `_buildTrustInsight`.
- **Evidencia de SQL duplicado:** `server/routes/trades/index.dart:557`-`:601`
  e `server/routes/trades/[id]/index.dart:260`-`:304` definem os mesmos tres
  snippets para estatisticas, tempo de resposta e tempo de envio.
- **Evidencia de resposta duplicada:** `_buildTrustInsight` tem corpo
  equivalente em `server/routes/trades/index.dart:603`-`:635`,
  `server/routes/trades/[id]/index.dart:306`-`:338` e
  `server/routes/community/marketplace/index.dart:316`-`:348`.
- **Por que parece risco real:** listagem, detalhe e marketplace deveriam
  expor trust com o mesmo contrato; regras de conta nova, perfil incompleto,
  historico insuficiente ou medias podem divergir se editadas em um arquivo so.
- **O que valida:** extrair fragments SQL e serializer para support
  compartilhado de trust social, com testes de shape para os tres endpoints.
- **O que falsifica:** documentar contratos diferentes para marketplace e
  trades e renomear campos/helpers para refletir a diferenca.

#### P2 — Logging de payload invalido em rotas sociais repete `request_id` e usuario

- **Simbolos:** `_requestId` e `_logInvalidPayload`.
- **Evidencia:** `_requestId` e `_logInvalidPayload` aparecem com o mesmo
  padrao try/catch em `server/routes/trades/[id]/status.dart:260`-`:284`,
  `server/routes/trades/[id]/respond.dart:154`-`:178`,
  `server/routes/trades/[id]/messages.dart:228`-`:252` e
  `server/routes/conversations/[id]/messages.dart:247`-`:271`; a rota
  `server/routes/trades/index.dart:330`-`:351` tambem repete fallback para
  `x-request-id`.
- **Observacao:** `server/lib/request_trace.dart:48`-`:57` ja expoe
  `getRequestTrace`/`tryGetRequestId`, mas as rotas mantem wrappers privados
  com fallback proprio.
- **Por que parece risco real:** formato de log, correlacao por request e
  fallback sem provider podem divergir entre trades/conversas se alterados
  localmente.
- **O que valida:** helper compartilhado para log social de payload invalido,
  aceitando endpoint e campos extras, com teste para fallback sem
  `RequestTrace`.
- **O que falsifica:** decisao explicita de logs por rota, com testes que
  preservem os formatos locais.

#### P3 — Condicao de carta usa allow-list repetida com contratos divergentes

- **Simbolos:** `_validateCondition` e allow-list `NM/LP/MP/HP/DMG`.
- **Evidencia:** `server/routes/decks/[id]/cards/index.dart:397`-`:403` e
  `server/routes/decks/[id]/cards/set/index.dart:243`-`:248` normalizam valor
  invalido para `NM`; `server/routes/binder/index.dart:275`-`:280` e
  `server/routes/binder/[id]/index.dart:339`-`:345` rejeitam valor invalido com
  `400`; `server/routes/community/marketplace/index.dart:39` repete a mesma
  allow-list para filtro.
- **Por que parece risco real:** deck cards, binder items e marketplace usam o
  mesmo vocabulario app-facing, mas a politica `fallback vs reject` fica
  implícita e espalhada.
- **O que valida:** helper compartilhado que contenha a allow-list e exponha
  explicitamente modos `normalizeOrDefault` e `validateStrict`, com testes por
  endpoint.
- **O que falsifica:** contrato documentado dizendo que mutacoes de deck sao
  tolerantes e binder e estrito, com testes preservando essa diferenca.

#### P3 — CMC/tipo principal continuam copiados em deck privado, publico e simulacao

- **Simbolos:** `getMainType`, `calculateCmc`, `_calculateCmc`.
- **Evidencia:** `server/routes/decks/[id]/index.dart:405`-`:435` e
  `server/routes/community/decks/[id].dart:91`-`:117` repetem classificacao de
  tipo e calculo aproximado de CMC por regex de custo de mana;
  `server/routes/decks/[id]/simulate/index.dart:171`-`:186` possui outra
  variante de `_calculateCmc`.
- **Por que parece risco real:** mana curve e agrupamento por tipo podem
  divergir entre deck privado, deck comunitario e simulacao se um custo novo ou
  tipo novo for ajustado em apenas uma rota.
- **O que valida:** extrair helper compartilhado para matematica/estatistica de
  carta de deck ou reutilizar `cmc` persistido quando disponivel, com testes
  para custo numerico, `X`, hibrido/phyrexian e custo vazio.
- **O que falsifica:** demonstrar que esses blocos sao apenas apresentacao
  legacy sem impacto app-facing e remover/encapsular quando os endpoints forem
  simplificados.

### Itens verificados e nao classificados como novo problema

- Wrappers finos em `server/routes/ai/optimize/index.dart:56`-`:63` continuam
  delegando para `optimize_support.resolveOptimizeArchetype`; o duplicado real
  fica entre `deck_state_analysis.dart` e `optimize_runtime_support.dart`.
- Colisoes genericas do auditor (`toString`, `print`, `add`, `build`,
  `fromJson`, `onRequest`) nao foram promovidas a achado sem prova de mesma
  regra de dominio.
- A duplicacao encontrada nesta rodada confirma os clusters documentados em
  2026-05-29 19:00 UTC; nao houve evidencia suficiente para abrir outro cluster
  fora dos grupos acima sem ampliar o foco.


## Rodada focada: PostgreSQL tables not used — revalidacao 2026-05-30 15:00 UTC

Escopo desta rodada: somente tabelas PostgreSQL sem uso, write-only ou com
consumo parcial. Nao foi executada auditoria ampla de classes, funcoes sem
chamada, imports/ciclos, duplicacao geral ou coerencia entre camadas.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada.
- `git rev-parse --short HEAD`: `e601c43d`.
- `rg` nao esta instalado neste shell local; buscas focadas usaram
  `grep -RIn --include='*.dart' --include='*.sql'`, `grep -RInE`, `nl -ba` e
  leitura pontual de SQL/Dart.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor estrutural faz analise textual e conta
referencias `FROM`/`JOIN`/`CREATE TABLE`; ele nao distingue leitura operacional,
escrita, CTEs, tabelas temporarias ou tabelas raw mantidas apenas como lineage.
A triagem abaixo cruzou definicoes, inserts/upserts, selects/joins/updates e
deletes no recorte `server/routes`, `server/lib`, `server/bin`, `server/test`,
`app/lib` e `server/database_setup.sql`.

### Achados revalidados

#### P2 — `deck_matchups` continua write-only no produto atual

- **Tabela:** `deck_matchups`.
- **Definicao:** `server/database_setup.sql:162`.
- **Escrita encontrada:** `server/routes/ai/simulate-matchup/index.dart:360`
  faz `INSERT INTO deck_matchups (...) ON CONFLICT (...) DO UPDATE`.
- **Leitura encontrada:** nenhuma leitura operacional em `server/routes`,
  `server/lib`, `server/bin` ou `app/lib`. A busca focada por
  `deck_matchups` encontrou somente o upsert da rota, definicao/setup e
  validadores/migradores (`server/bin/update_schema.dart:16`,
  `server/bin/verify_schema.dart:78`, `server/database_setup.sql:162`).
- **Por que parece nao usada:** a rota calcula `winRate` em memoria e retorna o
  resultado imediatamente em `simulate-matchup`; nenhum consumidor posterior
  consulta `deck_matchups.win_rate` ou `deck_matchups.notes` para cache,
  historico, ranking, dashboard ou recomendacao.
- **O que valida:** criar consumidor real de `deck_matchups` com contrato e
  teste, por exemplo historico/cached matchup ou painel operacional.
- **O que falsifica:** encontrar um `SELECT/JOIN` runtime dessa tabela em rota,
  lib, job ou app, ou declarar/documentar a tabela como log bruto com retencao.

#### P2 — `deck_weakness_reports` acumula registros sem fluxo de leitura ou resolucao

- **Tabela:** `deck_weakness_reports`.
- **Definicoes:** `server/database_setup.sql:363` e
  `server/bin/migrate_create_missing_tables.dart:97`.
- **Escrita encontrada:** `server/routes/ai/weakness-analysis/index.dart:374`
  faz `INSERT INTO deck_weakness_reports (...) ON CONFLICT DO NOTHING`.
- **Leitura/update encontrada:** nenhuma leitura operacional em `server/routes`,
  `server/lib`, `server/bin` ou `app/lib`; tambem nao ha fluxo confirmado que
  atualize `addressed`. A busca focada encontrou apenas insert, definicoes,
  indices e schema verification.
- **Por que parece nao usada:** a rota responde ao cliente com as fraquezas
  calculadas na chamada atual; o historico persistido nao e lido para tela,
  status, deduplicacao operacional ou acompanhamento de resolucao.
- **O que valida:** endpoint/job/UI que leia historico por deck e/ou atualize
  `addressed`, ou decisao explicita de tratar a tabela como log bruto com
  politica de retencao.
- **O que falsifica:** uma leitura runtime da tabela com uso app-facing ou
  operacional, ou contrato documentado de log/audit.

#### P3 — `ml_prompt_feedback` tem helper de insert sem chamador e apenas contador operacional

- **Tabela:** `ml_prompt_feedback`.
- **Definicao:** `server/bin/migrate_ml_knowledge.dart:159`.
- **Escrita potencial:** `MLKnowledgeService.recordFeedback` em
  `server/lib/ml_knowledge_service.dart:251` executa
  `INSERT INTO ml_prompt_feedback` em `:264`.
- **Chamada encontrada:** nenhuma chamada para `recordFeedback(` em
  `server/lib`, `server/routes`, `server/bin`, `server/test` ou `app/lib`.
- **Leitura encontrada:** somente contador operacional em
  `server/routes/ai/ml-status/index.dart:98`
  (`SELECT COUNT(*)::int as c FROM ml_prompt_feedback`).
- **Por que parece nao usada:** a tabela foi criada para feedback de usuario,
  mas nao ha rota/app/job que grave feedback nem consumidor que use os dados
  para refinar prompts/modelo; o status apenas conta linhas existentes.
- **O que valida:** expor fluxo real de feedback ou job que consuma a tabela,
  com teste de contrato.
- **O que falsifica:** chamador runtime de `recordFeedback`, outro caminho de
  insert documentado, trigger externo documentado, ou decisao de manter a
  tabela apenas como métrica/ledger operacional.

#### P3 — Raw corpus Commander Reference persiste lineage sem leitura direta confirmada

- **Tabelas:** `commander_reference_decks` e
  `commander_reference_deck_cards`.
- **Definicoes:** `server/lib/ai/commander_reference_deck_corpus_support.dart:1177`
  e `:1200`.
- **Escritas encontradas:** `INSERT INTO commander_reference_decks` em `:1245`,
  `DELETE FROM commander_reference_deck_cards` em `:1329` e
  `INSERT INTO commander_reference_deck_cards` em `:1345`.
- **Leitura encontrada:** nenhum `SELECT/JOIN` runtime confirmado contra as
  tabelas raw; o caminho consumido pelo produto le o agregado
  `commander_reference_deck_analysis` em `server/lib/ai/commander_reference_deck_corpus_support.dart:389`.
- **Por que e consumo parcial, nao necessariamente lixo:** as raw tables podem
  ser lineage/audit do corpus e material para recomputar o agregado, mas esse
  contrato nao esta explicito no codigo app-facing; sem retencao/reprocessamento
  documentado, parecem dados persistidos sem consumidor direto.
- **O que valida:** documentar as tabelas como lineage/audit com politica de
  retencao e job de reprocessamento, ou adicionar leitor operacional.
- **O que falsifica:** `SELECT/JOIN` real sobre as tabelas raw em rota/lib/job
  runtime ou decisao de persistir apenas `commander_reference_deck_analysis`.

### Itens verificados e nao classificados como problema

- `commander_reference_deck_analysis` nao foi classificada como nao usada:
  `loadCommanderReferenceDeckCorpusGuidance` le o agregado em
  `server/lib/ai/commander_reference_deck_corpus_support.dart:389`.
- `battle_simulations` nao foi reclassificada como tabela nao usada nesta
  rodada: historicamente ha leitura por extração de features e a rotacao atual
  nao encontrou evidencia nova para contrariar esse status.
- `schema_migrations` continua fora do achado por ser tabela interna do
  migrador, nao uma tabela de produto.
- Tabelas temporarias e CTEs listadas pelo inventario de 13:00 UTC nao foram
  tratadas como tabelas PostgreSQL de produto.

## Rodada focada: Broken imports and circular dependencies — revalidacao 2026-05-30 11:00 UTC

Escopo desta rodada: somente imports quebrados e ciclos de dependencia em Dart.
Nao foi executada auditoria ampla de classes, funcoes sem chamada, tabelas
PostgreSQL, duplicacao geral ou coerencia entre camadas.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada.
- `git rev-parse --short HEAD`: `df8291d7`.
- `rg` nao esta instalado neste shell local; buscas focadas usaram
  `grep -RIn --include='*.dart'`, `find`, `nl -ba` e uma triagem local
  read-only de grafo de imports.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 99.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor base ainda analisa somente
`server/lib` e `server/routes`. Ele nao cobre `app/lib` nem `server/bin`, onde
a triagem focada encontrou os problemas abaixo. Portanto, `Imports quebrados: 0`
vale apenas para o recorte do script.

### Triagem focada de imports locais

Foi executado um resolvedor read-only para arquivos Dart em `app/lib`,
`server/lib`, `server/routes` e `server/bin`, cobrindo imports relativos e
imports locais `package:manaloom/...`, `package:server/...` e
`package:ai/...`.

Resultado da triagem:

- Arquivos Dart analisados no recorte focado: 420.
- Arestas locais de import: 702.
- Imports locais quebrados: 3.
- Componentes fortemente conectados com mais de um arquivo: 1.

`flutter analyze --no-pub --no-fatal-infos` em `app/` nao foi conclusivo como
prova de app, porque `app/.dart_tool/package_config.json` nao existe neste
checkout e o analyzer reportou milhares de `uri_does_not_exist` para pacotes
externos antes de isolar os imports locais. `dart analyze` em `server/`
confirmou o problema de `server/bin/local_test_server.dart` com
`Target of URI doesn't exist: '../.dart_frog/server.dart'`.

### Achados revalidados

#### P1 — Dois imports relativos do app apontam para fora de `app/lib`

- **Import quebrado 1:** `app/lib/features/decks/widgets/deck_analysis_tab.dart:5`
  importa `../../../../core/utils/mana_helper.dart`.
- **Alvo resolvido pelo filesystem:** `app/core/utils/mana_helper.dart`.
- **Alvo existente esperado:** `app/lib/core/utils/mana_helper.dart`.
- **Evidencia:** o arquivo fonte esta em
  `app/lib/features/decks/widgets/`; quatro subidas (`../../../../`) saem de
  `app/lib` para `app/`. `find app/lib -path '*mana_helper.dart'` encontrou
  `app/lib/core/utils/mana_helper.dart`.
- **Import quebrado 2:** `app/lib/features/home/life_counter_screen.dart:7`
  importa `../../../core/theme/app_theme.dart`.
- **Alvo resolvido pelo filesystem:** `app/core/theme/app_theme.dart`.
- **Alvo existente esperado:** `app/lib/core/theme/app_theme.dart`.
- **Evidencia:** o arquivo fonte esta em `app/lib/features/home/`; tres subidas
  (`../../../`) saem de `app/lib` para `app/`. `find app/lib -path
  '*app_theme.dart'` encontrou `app/lib/core/theme/app_theme.dart`.
- **Por que e risco:** em checkout limpo, esses imports relativos nao resolvem
  para os arquivos existentes. Isso contradiz a anotacao historica que marcava
  estes imports como convertidos para `package:manaloom/...` em outro SHA.
- **O que valida:** trocar ambos para imports `package:manaloom/...` ou
  corrigir a profundidade relativa e reexecutar a triagem focada com
  `BROKEN_IMPORTS 0` para `app/lib`.
- **O que falsifica:** apontar um artefato/geracao intencional que crie
  `app/core/...` antes do analyze, ou demonstrar via `flutter analyze` completo
  que o analyzer resolve esses imports sem erro apos `flutter pub get`.

#### P1 — `server/bin/local_test_server.dart` ainda depende de arquivo gerado ausente

- **Import quebrado:** `server/bin/local_test_server.dart:3` importa
  `../.dart_frog/server.dart` como `generated`.
- **Alvo resolvido:** `server/.dart_frog/server.dart`.
- **Evidencia filesystem:** `test -e server/.dart_frog/server.dart` retornou
  ausente neste checkout.
- **Evidencia analyzer:** `dart analyze` em `server/` retornou
  `bin/local_test_server.dart:3:8 - Target of URI doesn't exist:
  '../.dart_frog/server.dart'`.
- **Por que e risco:** o binario local nao e analisavel em clone limpo sem
  artefato gerado. A anotacao historica de resolucao em `origin/master@a830f9f3`
  nao se aplica ao checkout atual `codex/hermes-analysis-docs@df8291d7`.
- **O que valida:** remover o import estatico e validar `.dart_frog/server.dart`
  em runtime antes de subir `dart run .dart_frog/server.dart`, ou garantir que o
  artefato seja gerado como precondicao explicita do comando e do analyze.
- **O que falsifica:** adicionar processo documentado que gere
  `server/.dart_frog/server.dart` antes de `dart analyze`, com teste/CI que
  prove esse contrato.

#### P1 — Ciclo direto entre detalhe de deck publico e perfil social permanece no app

- **Ciclo detectado:** `app/lib/features/community/screens/community_deck_detail_screen.dart`
  ↔ `app/lib/features/social/screens/user_profile_screen.dart`.
- **Aresta 1:** `community_deck_detail_screen.dart:8` importa
  `../../social/screens/user_profile_screen.dart`; o uso direto ocorre em
  `community_deck_detail_screen.dart:209`-`:217`, onde `Navigator.push`
  instancia `UserProfileScreen`.
- **Aresta 2:** `user_profile_screen.dart:7` importa
  `../../community/screens/community_deck_detail_screen.dart`; o uso direto
  ocorre em `user_profile_screen.dart:466`-`:470`, onde `Navigator.push`
  instancia `CommunityDeckDetailScreen`.
- **Evidencia do grafo:** a triagem focada encontrou `SCCS 1`, com componente
  de tamanho 2 contendo exatamente esses dois arquivos.
- **Por que e risco:** as duas telas se conhecem concretamente e impedem que
  comunidade/social evoluam como modulos independentes. Tambem contradiz a
  memoria historica que dizia que o ciclo havia sido removido via GoRouter.
- **O que valida:** trocar os pushes diretos por navegacao centralizada
  (`GoRouter` ou helper de routing) de modo que nenhum dos dois arquivos importe
  o outro; reexecutar a triagem focada e obter `SCCS 0` para `app/lib`.
- **O que falsifica:** demonstrar que o ciclo e intencional, documentado e
  coberto por teste de navegacao que aceite dependencia bidirecional entre esses
  modulos.

### Itens verificados e nao classificados como problema

- O auditor base continua util para imports relativos dentro de `server/lib` e
  `server/routes`; nessa area ele nao encontrou imports quebrados.
- Imports de pacotes externos (`flutter`, `provider`, `dart_frog`, `postgres`,
  etc.) nao foram classificados nesta rodada porque dependem do package config.
- Imports locais `package:manaloom/...` e `package:server/...` que apontam para
  arquivos existentes foram tratados como saudaveis.

## Rodada focada: Functions not called — revalidacao 2026-05-30 07:00 UTC

Escopo desta rodada: somente funcoes/metodos aparentemente sem chamador runtime
confirmado, ou chamados apenas por testes/harnesses. Nao foi executada auditoria
ampla de classes, imports/ciclos, tabelas PostgreSQL, duplicacao geral ou
coerencia entre camadas.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada.
- `git rev-parse --short HEAD`: `af3d8575`.
- `rg` nao esta instalado neste shell local; buscas focadas usaram
  `grep -RIn --include='*.dart'`, `nl -ba` e uma triagem local read-only.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor estrutural nao prova chamadores de
funcao. Ele lista os primeiros simbolos publicos por arquivo e nomes duplicados,
mas nao constroi grafo de chamadas. A triagem abaixo foi manual e manteve apenas
simbolos cuja busca textual encontrou definicao + teste, ou definicao + wrapper
sem uso.

### Achados revalidados

#### P1 — `sync_cards_utils.dart` segue testado, mas nao e chamado pelo sync real neste checkout

- **Funcoes:** `extractCardRow`, `getNewSetCodesSinceFromData`,
  `parseSinceDays`, `extractSetCardRow`, `extractOracleIds` e
  `extractLegalities`.
- **Definicoes:** `server/lib/sync_cards_utils.dart:16`, `:82`, `:102`,
  `:116`, `:161` e `:172`.
- **Evidencia de nao chamada runtime:** `grep -RIn --include='*.dart'
  "sync_cards_utils\|extractCardRow\|extractSetCardRow\|parseSinceDays\|extractOracleIds\|extractLegalities"
  server/bin server/lib server/routes server/test` encontrou o import apenas em
  `server/test/sync_cards_test.dart:3`; nenhum `server/bin`, `server/lib`
  runtime ou rota importa `sync_cards_utils.dart`.
- **Comparacao com o CLI ativo:** `server/bin/sync_cards.dart:9`-`:10` importa
  `database.dart` e `mtg_data_integrity_support.dart`, mas nao
  `sync_cards_utils.dart`. O mesmo CLI ainda mantem `_parseSinceDays` em
  `server/bin/sync_cards.dart:376`-`:384`, monta rows incrementais inline em
  `:604`-`:663`, define `_extractCardRow` a partir de `:679`, e coleta oracle
  IDs/legalidades inline em `:806`-`:839`.
- **Por que e risco:** `server/test/sync_cards_test.dart` valida helpers que nao
  participam do caminho operacional de sync. Isso pode dar falsa confianca caso
  o CLI real derive em paralelo.
- **O que valida:** importar `sync_cards_utils.dart` no CLI real e substituir as
  copias privadas/loops equivalentes, mantendo os testes como cobertura do
  caminho usado.
- **O que falsifica:** remover `sync_cards_utils.dart` e seus testes como
  harness legado, ou apontar outro entrypoint operacional que importe esse
  arquivo.

#### P2 — Wrappers de `RequestTrace` continuam sem chamador externo

- **Funcoes:** `getRequestTrace` e `tryGetRequestId`.
- **Definicoes:** `server/lib/request_trace.dart:48` e
  `server/lib/request_trace.dart:51`.
- **Evidencia:** `grep -RIn --include='*.dart'
  "context.read<RequestTrace>()\|getRequestTrace\|tryGetRequestId"
  server/lib server/routes server/bin server/test` encontrou
  `getRequestTrace` apenas na definicao e dentro de `tryGetRequestId`; encontrou
  `tryGetRequestId` apenas na propria definicao. Os consumidores reais acessam
  `RequestTrace` diretamente, por exemplo `server/lib/auth_middleware.dart:57`,
  `server/lib/observability.dart:225`, `server/routes/trades/index.dart:332` e
  `server/routes/conversations/[id]/messages.dart:249`.
- **Por que parece nao chamada:** o wrapper nullable foi mantido, mas o contrato
  efetivo do backend e `context.read<RequestTrace>()`.
- **O que valida:** trocar chamadores que precisam de fallback por
  `tryGetRequestId`/`getRequestTrace` e cobrir por teste.
- **O que falsifica:** remover os wrappers e manter acesso direto como contrato
  unico.

#### P2 — Helpers backend continuam test-only ou wrapper-only

- **`normalizedCommanderReferenceCandidate`:** definido em
  `server/lib/ai/commander_reference_profile_support.dart:49`; busca por simbolo
  encontrou apenas a definicao. Consumidores ativos usam
  `normalizeCommanderReferenceName`, por exemplo
  `server/lib/ai/commander_reference_card_stats_support.dart:308`,
  `:559`, `:717`, `server/lib/ai/commander_reference_readiness_support.dart:304`
  e `server/routes/ai/generate/index.dart:581`.
- **`buildLoreholdReferenceCardStatsFromProfile`:** definido em
  `server/lib/ai/commander_reference_card_stats_support.dart:257` como wrapper
  fino sobre `buildCommanderReferenceCardStatsFromProfile`; busca por simbolo
  encontrou somente `server/test/commander_reference_card_stats_support_test.dart:13`
  e a definicao. O builder generico e usado no runtime no mesmo arquivo em
  `:368`.
- **`extractMtgTop8FormatCodeFromSourceUrl`:** definido em
  `server/lib/meta/mtgtop8_meta_support.dart:139`; busca por simbolo encontrou
  somente `server/test/mtgtop8_meta_support_test.dart:147` e a definicao. O
  helper vizinho `extractMtgTop8EventIdFromSourceUrl` e usado pelo reparo
  operacional em `server/bin/repair_mtgtop8_meta_history.dart:59`.
- **`buildCandidateQualitySamplePoolSql`:** definido em
  `server/lib/ai/candidate_quality_data_support.dart:631`; busca por simbolo
  encontrou somente `server/test/candidate_quality_data_support_test.dart:123`
  e a definicao. O runner operacional
  `server/bin/candidate_quality_data_foundation.dart` importa o support, mas
  carrega pools por `_loadCandidateCards` em `:403` e
  `_buildSampleCandidatePools` em `:640`.
- **`summarizeAggressiveOptimizeUtilitySamples`:** definido em
  `server/lib/ai/optimize_runtime_support.dart:3326`; busca por simbolo
  encontrou somente `server/test/optimize_runtime_support_test.dart:169` e a
  definicao.
- **Por que e risco:** baixo/medio por simbolo isolado, mas em conjunto mantem
  testes cobrindo APIs que nao necessariamente protegem o caminho operacional.
- **O que valida:** ligar cada helper ao runner/rota que deveria consumi-lo ou
  documentar explicitamente como API publica de harness.
- **O que falsifica:** remover os wrappers/helpers test-only e seus testes
  correspondentes quando o contrato canonico ja tem outro simbolo.

#### P2 — API manual de `PerformanceService` segue sem chamada app runtime

- **Metodos sem chamador externo confirmado:** `startTrace`, `stopTrace`,
  `addMetric`, `addAttribute`, `getLocalStats` e `printLocalStats`.
- **Definicoes:** `app/lib/core/services/performance_service.dart:110`,
  `:130`, `:200`, `:210`, `:220` e `:248`.
- **Evidencia:** `grep -RIn --include='*.dart'
  "\.startTrace(\|\.stopTrace(\|\.addMetric(\|\.addAttribute(\|\.getLocalStats(\|\.printLocalStats("
  app/lib app/test app/integration_test` nao encontrou chamadas externas. A
  observabilidade ativa usa `PerformanceService.instance.init()` em
  `app/lib/main.dart:121`; `PerformanceNavigatorObserver` usa
  `startScreenTrace`/`stopScreenTrace` em
  `app/lib/core/services/performance_service.dart:295`, `:307`, `:334` e
  `:339`; `traceAsync` aparece no smoke
  `app/integration_test/release_observability_smoke_test.dart:51`, nao em
  `app/lib`.
- **Por que e risco:** a classe sugere suporte a metricas customizadas manuais,
  mas o app runtime atual nao instrumenta essas chamadas. Isso e aceitavel se a
  API for reserva intencional de observabilidade; caso contrario, e superficie
  publica morta.
- **O que valida:** instrumentar operacoes criticas do app com esses metodos, ou
  declarar `traceAsync` + observer como contrato unico e remover a API manual.
- **O que falsifica:** encontrar chamadas runtime fora de testes/harnesses ou
  documentar plano ativo que trate esses metodos como API publica deliberada.

### Itens verificados e nao classificados como problema

- `onRequest` em rotas Dart Frog nao foi classificado como sem chamada, porque
  e chamado por convencao do framework.
- Funcoes com baixa contagem mas chamadas por `server/bin` foram tratadas como
  suporte operacional, nao como codigo morto.
- O status historico que marcava alguns helpers como removidos em outro SHA nao
  foi usado como evidencia para este checkout; a conclusao acima vale para
  `codex/hermes-analysis-docs@af3d8575`.

## Rodada focada: Card semantics runtime — auditoria 2026-05-30 05:30 UTC

Escopo desta rodada: nomes hardcoded de cartas, drift entre
`functional_tags`, `semantic_tags_v2` e roles do optimize, e sinais de
utilidade derivados de nome em codigo runtime. A auditoria priorizou
`server/lib`, `server/routes` e `app/lib`; testes/docs/artifacts foram usados
somente para classificar fixtures, exemplos ou protecoes existentes.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada.
- `rg` nao esta instalado neste shell local; buscas focadas usaram
  `grep -RInE`, `nl -ba` e leitura direta dos arquivos.

### Achados revalidados

#### P1 — Classificadores funcionais ainda usam excecoes por nome dentro da regra runtime

- **Classificador deck analysis:** `inferFunctionalCardTags` em
  `server/lib/ai/functional_card_tags.dart:219`-`:226` marca ramp por
  `signet`, `talisman`, `sol ring` e `arcane signet`, mesmo quando a decisao
  deveria ser explicavel por `oracle_text`, `type_line`, `mana_cost` e dados
  persistidos.
- **Outras excecoes no mesmo classificador:** protecao por nomes/equipamentos em
  `server/lib/ai/functional_card_tags.dart:700`-`:717`, aristocrats/drain por
  `Blood Artist` em `:754`-`:780`, blink/ritual/big spell por `Ephemerate` e
  `Jeska's Will` em `:823`-`:851`, e wincon/combo/payoff/enabler por
  `Thassa's Oracle`, `Isochron Scepter`, `Dramatic Reversal`, `Blood Artist`,
  `greaves` e `boots` em `:859`-`:906`.
- **Candidate quality repete outro mapa:** `inferCandidateFunctionTags` em
  `server/lib/ai/candidate_quality_data_support.dart:375`-`:379`, `:421`-`:428`,
  `:439`-`:445` e `:472`-`:478` reclassifica ramp, protecao, combo e
  aristocrats com nomes/substring proprios; `inferCandidateBracketScope` usa
  `highPowerNames` em `:583`-`:605`; `isPremiumCommanderCandidateName` aplica
  bonus por lista fixa em `:611`-`:628`.
- **Por que e risco:** sao decisoes de produto/runtime, nao exemplos ou corpus.
  Duas cartas com texto equivalente podem receber tags/score diferentes por nao
  estarem na lista, e uma carta reprintada/renomeada pode ser classificada por
  substring em vez de semantica persistida.
- **O que valida:** mover essas excecoes para policy/tabela versionada com
  `role`, `reason`, `confidence`, `source` e teste; ou provar que cada nome
  restante e excecao intencional indisponivel em `oracle_text`.
- **O que falsifica:** testes mostrando que cartas equivalentes sem esses nomes
  recebem a mesma tag/score e que as listas inline sao usadas apenas para
  backfill de dados persistidos, nao para decisao runtime.

#### P1 — Optimize/validator ignora `card_function_tags` persistidos no caminho principal e colapsa `semantic_tags_v2` em um unico role

- **Deck analysis carrega as duas camadas:** `GET /decks/:id/analysis` seleciona
  `card_function_tags` e `semantic_tags_v2` em
  `server/routes/decks/[id]/analysis/index.dart:80`-`:96` e retorna
  `functional_tags` em `:420`-`:430`. `POST /decks/:id/ai-analysis` faz o
  mesmo em `server/routes/decks/[id]/ai-analysis/index.dart:119`-`:135` e passa
  as colunas para `summarizeFunctionalTagsForDeck` em `:306`-`:315`.
- **A sumarizacao prefere functional tags persistidos:** `summarizeFunctionalTagsForDeck`
  le `functional_tags` em `server/lib/ai/functional_card_tags.dart:432`-`:465`
  e usa heuristica so quando nao ha tag persistida.
- **Optimize nao carrega functional tags no contexto:** `loadOptimizeDeckContext`
  seleciona `semantic_tags_v2`, mas nao `card_function_tags`, em
  `server/lib/ai/optimize_request_support.dart:86`-`:107`; o `cardData`
  montado em `:186`-`:198` contem `semantic_tags_v2`, mas nao
  `functional_tags`.
- **Additions e gate seguem o mesmo recorte:** a rota de optimize monta
  `additionsData` com `semantic_tags_v2` em
  `server/routes/ai/optimize/index.dart:2068`-`:2099`, e o SQL helper de v2 em
  `:3197`-`:3213` tambem nao agrega `card_function_tags`.
- **Validator/quality gate dependem do role unico:** `OptimizationValidator`
  chama `classifyOptimizationFunctionalRole` em
  `server/lib/ai/optimization_validator.dart:265`-`:267`, e o quality gate faz
  o mesmo em `server/lib/ai/optimization_quality_gate.dart:52`-`:56`.
  `classifyOptimizationFunctionalRole` prioriza apenas
  `semantic_tags_v2` em
  `server/lib/ai/optimization_functional_roles.dart:55`-`:58`; se nao houver
  v2 suficiente, cai para `type_line`/`oracle_text`.
- **Perda de multi-role:** `_classifySemanticV2FunctionalRole` escolhe uma unica
  entrada de maior confianca e devolve o primeiro role em ordem fixa
  (`board_wipe`, `draw`, `removal`, `ramp`, `tutor`, `protection`,
  `recursion`, `wincon`, `combo_piece`) em
  `server/lib/ai/optimization_functional_roles.dart:127`-`:180`. O diagnostico
  `role_delta` tambem conta um role por swap em `:292`-`:323`.
- **Por que e risco:** a aba de analise pode contar uma carta como
  `engine`, `payoff`, `enabler`, `drain` ou `exile_value` via
  `card_function_tags`, enquanto optimize/validator a ve como role unico ou
  heuristico. Isso pode aprovar troca que preserva o role primario mas perde um
  papel secundario importante.
- **O que valida:** carregar `card_function_tags` nos contexts de optimize e
  additions; criar adapter unico que retorne conjunto de roles + `primary_role`;
  usar esse adapter em deck analysis, optimize, validator, quality gate e
  candidate quality.
- **O que falsifica:** prova de contrato/teste mostrando que optimize deve
  deliberadamente ignorar `card_function_tags` e que todos os consumers aceitam
  perda de roles secundarios.

#### P1 — Recomendacoes e fallbacks de optimize ainda escolhem cartas por listas fixas

- **Fallback universal do optimize:** `loadUniversalCommanderFallbacks` usa lista
  fixa `preferred` com `Sol Ring`, `Arcane Signet`, `Command Tower`,
  `Swords to Plowshares`, `Cyclonic Rift`, `Rhystic Study` e outros em
  `server/lib/ai/optimize_runtime_support.dart:3476`-`:3555`.
- **Foundation fillers por arquétipo/identidade:** `loadArchetypeCommanderFoundationFillers`
  inicia com nomes fixos como `The One Ring`, `Fellwar Stone`, `Mystic Remora`
  e adiciona pools azuis/proliferate em
  `server/lib/ai/optimize_runtime_support.dart:3558`-`:3615`.
- **Reserva de staples por nome:** outro caminho de fallback em
  `server/lib/ai/optimize_runtime_support.dart:1296`-`:1346` consulta uma lista
  fixa de staples antes de buscar no banco.
- **Rota de recomendacoes:** `server/routes/decks/[id]/recommendations/index.dart:262`-`:267`
  recomenda `Command Tower` diretamente quando um Commander tem menos de 34
  terrenos. A mesma rota chama `_findStaples` em `:270`-`:283`, mas esse helper
  busca raridade `rare/mythic` por nome ordenado em `:408`-`:438`, sem role
  semantico, EDHREC/meta score ou `card_function_tags`.
- **Mock optimize:** quando nao ha `deckOptimizer`, a rota retorna
  `Sol Ring`/`Arcane Signet` em
  `server/routes/ai/optimize/index.dart:1113`-`:1123`. Isso e aceitavel como
  mock de desenvolvimento (`is_mock: true`), mas deve permanecer isolado do
  runtime real.
- **Por que e risco:** fallbacks sao runtime e podem decidir utilidade por nome
  em vez de `oracle_text`, `type_line`, legalidade, identidade de cor, bracket,
  `semantic_tags_v2`, `card_function_tags`, score/role persistido ou deltas de
  validacao.
- **O que valida:** substituir listas inline por consulta a dados versionados
  (`card_role_scores`, `card_function_tags`, `card_semantic_tags_v2`,
  Commander Reference/meta) com fallback minimo e auditavel; manter listas de
  nomes apenas como seed/policy versionada.
- **O que falsifica:** testes de runtime mostrando que essas listas so entram
  depois de filtros semanticos equivalentes e que cartas equivalentes fora da
  lista competem em igualdade.

#### P2 — `/ai/weakness-analysis` calcula utilidade por heuristica propria e devolve sugestoes fixas

- **Sem camada semantica persistida:** a rota consulta apenas `name`,
  `type_line`, `oracle_text`, `mana_cost`, `colors`, `quantity` e `cmc` em
  `server/routes/ai/weakness-analysis/index.dart:41`-`:59`; nao carrega
  `card_function_tags` nem `semantic_tags_v2`.
- **Classificacao local:** ramp/draw/removal/wipes/protecao sao contados por
  `oracle_text`/`type_line` e excecao de nome para `Teferi's Protection` e
  `Heroic Intervention` em
  `server/routes/ai/weakness-analysis/index.dart:114`-`:162`.
- **Sugestoes fixas:** quando faltam categorias, a rota retorna nomes fixos
  (`Sol Ring`, `Arcane Signet`, `Rhystic Study`, `Swords to Plowshares`,
  `Wrath of God`, `Cyclonic Rift`) em
  `server/routes/ai/weakness-analysis/index.dart:206`-`:249`.
- **Por que e risco:** a rota pode divergir de deck analysis e optimize porque
  nao usa o mesmo adapter nem os dados persistidos. O usuario pode ver
  contagens/recomendacoes diferentes para o mesmo deck.
- **O que valida:** reutilizar `summarizeFunctionalTagsForDeck` ou o adapter
  unico proposto; gerar sugestoes por roles e filtros de legalidade/identidade,
  nao por lista inline.
- **O que falsifica:** documentar `/ai/weakness-analysis` como endpoint legado
  nao consumido por app, ou cobrir por teste que seu output e deliberadamente
  independente do fluxo core.

#### P2 — Politicas por nome existem tambem como excecoes intencionais e precisam ficar protegidas

- **Bracket policy:** `server/lib/edh_bracket_policy.dart:134`-`:142` declara
  que combos infinitos nao sao bem inferidos so por oracle text e usa lista
  curada; `_knownInfiniteComboPieces` contem `Thassa's Oracle`,
  `Demonic Consultation` e `Tainted Pact` em `:271`-`:276`. A lista oficial de
  Game Changers com nomes curados comeca em `:280`.
- **Classificacao:** **Intentional exception**, porque bracket/Game Changer e
  regra de produto externa por carta conhecida. O risco e operacional:
  a lista inline precisa de fonte/versionamento/testes dedicados.
- **Teste existente:** `server/test/optimize_runtime_support_test.dart:274`-`:298`
  cobre bloqueio de adicao acima do bracket baixo usando `Mana Crypt`, mas nao
  protege diretamente a lista de Game Changers ou os combos conhecidos.
- **Correcao estreita:** manter excecao por nome, mas extrair para policy
  versionada com fonte e teste especifico para `knownInfiniteComboPieces` e
  amostra de Game Changer.

### Itens verificados e classificados como permitidos

- **Exemplos de UI/import:** `app/lib/features/decks/screens/deck_import_screen.dart:383`-`:391`
  preenche exemplo de lista;
  `app/lib/features/decks/widgets/deck_import_list_dialog.dart:149`-`:154`
  usa `1 Sol Ring` como formato. Permitido como UI example, nao decisao de
  utilidade.
- **Sugestoes de busca do life counter:** `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:39`-`:44`
  e `app/lib/features/home/life_counter_screen.dart:2198`-`:2204` usam nomes
  populares como sugestao de busca. Permitido como UX seed, desde que nao seja
  usado para recomendar/validar/otimizar deck.
- **Docs/comments de resolver/import:** comentarios em
  `server/routes/cards/resolve/batch/index.dart:13`-`:23` e mensagens de erro
  em `server/routes/import/index.dart:176`-`:183` e
  `server/routes/import/to-deck/index.dart:96`-`:103` usam `Sol Ring` como
  exemplo de formato. Permitido.
- **Aliases localizados manuais:** `server/lib/import_card_lookup_service.dart:19`-`:30`
  contem aliases PT-BR para nomes ingleses, incluindo `Swords to Plowshares`.
  Permitido como seed/backward compatibility de importacao localizada, nao como
  avaliacao de utilidade.
- **Lorehold deterministic fallback:** `server/lib/ai/commander_reference_generate_fallback_support.dart:182`-`:245`
  e uma lista fallback de Commander Reference para Lorehold. Classificacao:
  aceitavel como corpus/seed de geracao deterministica, mas deve continuar
  separado do otimizador generico e de recomendacoes runtime.

> Atualizacao local Codex: 2026-05-31 05:13 UTC
> Rotacao: `functions-duplication`
> Branch de memoria: `codex/hermes-analysis-docs`

## Rodada focada: Classes not used — revalidacao 2026-05-30 03:00 UTC

Escopo desta rodada: somente classes sem uso runtime confirmado. Nao foi
executada auditoria ampla de funcoes sem chamada, imports/ciclos, tabelas
PostgreSQL, duplicacao ou coerencia entre camadas fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada; depois o auditor base
  atualizou este arquivo.
- `git rev-parse --short HEAD`: `da337c5e`.
- `rg` nao esta instalado neste shell local; buscas focadas usaram
  `grep -RIn`, `nl -ba` e leitura direta dos arquivos.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor base mapeia apenas `server/lib` e
`server/routes`; ele nao varre `app/lib`. Alem disso, a heuristica de classe
"potencialmente nao usada" marca classes que sao consumidas no mesmo arquivo
como suspeitas porque so procura mencoes em outros arquivos. Exemplos
revalidados como falso positivo do auditor: `AggressiveCandidateQualitySignal`
em `server/lib/ai/optimize_runtime_support.dart:2433` e usado no mesmo arquivo
em `:2503`, `:2544`, `:2601`, `:2735` e `:3181`;
`CommanderReferenceDeckCardInput` em
`server/lib/ai/commander_reference_deck_corpus_support.dart:30` e usado no
mesmo arquivo em `:65` e `:305`; `ExpandedDeckCard` em
`server/lib/meta/external_commander_deck_expansion_support.dart:40` e usado no
mesmo arquivo em `:28`, `:29`, `:392`, `:557`, `:566`, `:572` e `:622`.
A triagem abaixo, portanto, foi manual e ficou restrita a classes com ausencia
de chamador/constructor/import em `app/lib`, confrontando tambem `app/test`.

### Achados revalidados

#### P1 — `LifeCounterScreen` legado segue fora do caminho runtime do app

- **Classe:** `LifeCounterScreen` em
  `app/lib/features/home/life_counter_screen.dart:61`.
- **Evidencia de runtime:** `app/lib/main.dart:54` importa
  `lotus_life_counter_screen.dart`, e a rota `lifeCounterRoutePath` renderiza
  `const LotusLifeCounterScreen()` em `app/lib/main.dart:281`-`:283`.
- **Evidencia de ausencia em `app/lib`:** busca focada por
  `LifeCounterScreen(` em `app/lib` encontrou somente a propria definicao em
  `life_counter_screen.dart:66`; nao ha import de `life_counter_screen.dart` no
  codigo runtime.
- **Evidencia de uso apenas em teste/legado:** `app/test/features/home/life_counter_screen_test.dart:1`-`:2`
  declara a suite como referencia legada e diz que a cobertura viva mira
  `LotusLifeCounterScreen`; o teste ainda importa
  `life_counter_screen.dart` em `:9` e instancia `LifeCounterScreen` em `:36`.
  `app/test/features/home/life_counter_clone_proof_test.dart:1`-`:2` tambem
  declara paridade historica e instancia `LifeCounterScreen` em `:277`-`:280`.
- **Por que parece unused real:** o app vivo navega para o Lotus WebView, mas
  ainda mantem uma tela nativa grande e testada apenas como legado. Isso aumenta
  custo de manutencao e pode criar falsa confianca se suites antigas passarem
  enquanto o caminho real e outro.
- **O que valida:** restaurar chamada runtime explicita para
  `LifeCounterScreen`, ou documentar oficialmente como referencia legada/test
  fixture e retirar do caminho de produto.
- **O que falsifica:** uma rota, flag runtime ou import em `app/lib` que
  instancie `LifeCounterScreen` fora dos testes.

#### P2 — `DeckCard` permanece testado, mas sem uso confirmado na listagem real

- **Classe:** `DeckCard` em
  `app/lib/features/decks/widgets/deck_card.dart:17`.
- **Evidencia de ausencia em `app/lib`:** busca focada por `DeckCard(` em
  `app/lib` encontrou apenas classes privadas com nomes similares
  (`_RecentDeckCard`, `_EmptyDeckCard`, `_CommunityDeckCard`,
  `_FollowingDeckCard`) e a propria definicao de `DeckCard`; nao ha import de
  `deck_card.dart` em `app/lib`.
- **Evidencia de uso apenas em testes:** `app/test/features/decks/widgets/deck_card_test.dart:4`
  importa `deck_card.dart` e instancia `DeckCard` em `:9`;
  `app/test/features/decks/widgets/deck_card_overflow_test.dart:4` importa o
  mesmo arquivo e instancia `DeckCard` em `:47`.
- **Por que parece unused real:** o widget tem suite propria e historico de
  overflow, mas a listagem de decks atual parece usar implementacao inline ou
  cards privados. Alteracoes nele nao protegem necessariamente a UI que o
  usuario ve.
- **O que valida:** reutilizar `DeckCard` na listagem real de decks, ou remover
  a classe/testes se o card oficial passou a ser outro componente.
- **O que falsifica:** import ou chamada `DeckCard(...)` em `app/lib` que a
  busca textual nao encontrou.

#### P2 — `DeckProgressChip` nao tem chamada de construtor confirmada

- **Classe:** `DeckProgressChip` em
  `app/lib/features/decks/widgets/deck_progress_indicator.dart:286`.
- **Evidencia de ausencia:** busca focada por `DeckProgressChip(` em `app/lib`
  e `app/test` encontrou apenas o construtor na propria classe
  (`deck_progress_indicator.dart:292`); nenhum teste ou widget runtime instancia
  o chip.
- **Contexto:** o arquivo e usado por `DeckProgressIndicator`:
  `app/lib/features/decks/widgets/deck_progress_indicator.dart:14`, importado
  por `app/lib/features/decks/screens/deck_details_screen.dart:26` e
  `app/lib/features/decks/widgets/deck_details_overview_tab.dart:10`. O achado
  nao vale para `DeckProgressIndicator`; vale apenas para o chip compacto.
- **Por que parece unused real:** e uma segunda apresentacao publica de
  progresso no mesmo arquivo, mas sem consumidor. Pode ser leftover de uma
  listagem antiga.
- **O que valida:** chamar `DeckProgressChip` em cards/listas ou adicionar um
  teste que represente uso planejado e uma rota para ele.
- **O que falsifica:** uma instanciacao dinamica/indireta inexistente na busca
  textual, ou um import gerado fora de `app/lib`/`app/test`.

#### P2 — `LotusPresentationMode` nao e usado pelo fluxo Lotus atual

- **Classe:** `LotusPresentationMode` em
  `app/lib/features/home/lotus/lotus_presentation_mode.dart:4`.
- **Evidencia de ausencia:** busca focada por `LotusPresentationMode` em
  `app/lib` e `app/test` encontrou apenas a definicao e o construtor privado
  em `lotus_presentation_mode.dart:4`-`:5`; nao ha chamada para `enter()` ou
  `exit()`.
- **Por que parece unused real:** a classe encapsula orientacao e system UI do
  modo apresentacao (`enter` em `:15`-`:24`, `exit` em `:26`-`:30`), mas o
  caminho vivo `LotusLifeCounterScreen` nao a importa. Se o modo fullscreen
  ainda for requisito, a ausencia de chamada e um gap funcional; se nao for, e
  codigo morto.
- **O que valida:** chamar `LotusPresentationMode.enter/exit` no ciclo de vida
  do Lotus ou mover a responsabilidade para outro helper com teste.
- **O que falsifica:** outro mecanismo documentado/testado que substitua este
  helper e justifique remover a classe.

### Itens verificados e nao classificados como novo problema

- A lista bruta do auditor para classes de backend nao foi promovida como
  finding. Ela inclui muitos DTOs/helpers usados somente no arquivo onde sao
  definidos, o que e comum em rotas e supports Dart. Exemplos revalidados:
  `AggressiveCandidateQualitySignal`,
  `CommanderReferenceDeckCardInput`, `ExpandedDeckCard` e
  `EdhrecAverageDeckCard`.
- `DeckProgressIndicator` nao esta unused: o achado e somente para o
  `DeckProgressChip` compacto no mesmo arquivo.
- `LotusLifeCounterScreen` nao esta unused: `app/lib/main.dart:281`-`:283`
  continua apontando a rota do life counter para ele.

## Rodada focada: Coerencia entre modulos `server/lib` ↔ `server/routes` ↔ `app/lib` — revalidacao 2026-05-29 23:05 UTC

Escopo desta rodada: somente coerencia entre camada de suporte backend
(`server/lib`), rotas Dart Frog (`server/routes`) e consumidores Flutter
(`app/lib`). Nao foi executada auditoria ampla de classes sem uso, funcoes sem
chamada, imports/ciclos, tabelas PostgreSQL ou duplicacao fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada; depois o auditor base
  atualizou este arquivo.
- `git rev-parse --short HEAD`: `b071080e`.
- `rg` nao esta instalado neste shell local; buscas focadas usaram
  `grep -RIn`, `nl -ba` e leitura direta dos arquivos.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor base nao compara contrato app-facing
entre app, rota e camada de support. A triagem abaixo foi manual e ficou
restrita aos fluxos onde o app chama uma rota que delega para `server/lib` ou
usa dados calculados por `server/lib`.

### Achados revalidados

#### P1 — `POST /ai/optimize` continua carregando deck por `id` sem owner-scope na camada `server/lib`

- **Consumidor app:** `app/lib/features/decks/providers/deck_provider.dart:543`-`:550`
  chama `requestOptimizeDeck(...)`; `app/lib/features/decks/providers/deck_provider_support_ai.dart:56`
  envia `POST /ai/optimize` com `deck_id`.
- **Rota:** `server/routes/ai/optimize/index.dart:401`-`:406` tenta ler
  `userId`, mas a chamada para `loadOptimizeDeckContext` em
  `server/routes/ai/optimize/index.dart:549`-`:558` passa `pool`, `deckId`,
  `targetArchetype`, `requestMode`, `intensity`, `bracket`, `keepTheme` e
  `telemetry`, sem `userId`.
- **Camada `server/lib`:** `server/lib/ai/optimize_request_support.dart:53`-`:73`
  declara `loadOptimizeDeckContext` sem parametro `userId` e executa
  `SELECT name, format FROM decks WHERE id = @id`; a consulta de cartas em
  `server/lib/ai/optimize_request_support.dart:87`-`:110` usa somente
  `WHERE dc.deck_id = @id`.
- **Por que e incoerente:** o app trata optimize como operacao do deck do
  usuario autenticado, e o contrato global em
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md` exige ownership mobile em rotas
  protegidas. Nesta branch, a rota autentica, mas a camada que monta o contexto
  nao escopa `decks` por `user_id`, entao o contrato app-facing e a query real
  divergem.
- **O que valida:** adicionar `userId` obrigatorio a
  `loadOptimizeDeckContext`, aplicar `WHERE id = @id AND user_id = @userId`
  na query de deck e proteger a query de `deck_cards` por `JOIN decks d ON
  d.id = dc.deck_id AND d.user_id = @userId`; criar teste owner vs non-owner
  cobrindo `POST /ai/optimize`.
- **O que falsifica:** documentar uma regra explicita de optimize para decks
  publicos ou compartilhados, implementar essa regra na query e cobrir o caso
  com teste de contrato app/backend.

#### P1 — `POST /ai/archetypes` tambem diverge do contrato app-facing de ownership

- **Consumidor app:** `app/lib/features/decks/providers/deck_provider_support_mutation.dart:168`-`:173`
  chama `POST /ai/archetypes` com `deck_id` e espera `data['options']`.
- **Rota:** `server/routes/ai/archetypes/index.dart:27`-`:42` le `deck_id`,
  mas busca `SELECT name, format FROM decks WHERE id = @id`, sem
  `context.read<String>()` nem filtro por `user_id`. A consulta de cartas em
  `server/routes/ai/archetypes/index.dart:54`-`:60` tambem usa apenas
  `WHERE dc.deck_id = @id`.
- **Camada `server/lib`:** a rota usa
  `loadUsableCommanderReferenceProfile` de
  `server/lib/ai/commander_reference_profile_support.dart` quando encontra um
  comandante; a escolha do profile e das opcoes fica correta para o comandante,
  mas recebe um deck ja carregado sem owner-scope.
- **Por que e incoerente:** o app so apresenta opcoes para decks do usuario,
  mas a rota pode montar opcoes a partir de qualquer UUID de deck existente. O
  `TECHNICAL_MAP.md` anterior dizia que `/ai/archetypes` ja lia
  `context.read<String>()` e escopava owner; isso nao e verdadeiro no checkout
  local `b071080e`.
- **O que valida:** ler `userId` na rota, trocar a query de deck para
  `WHERE id = @id AND user_id = @userId`, proteger a query de cartas com join
  em `decks`, e adicionar teste de non-owner retornando 404.
- **O que falsifica:** mover `/ai/archetypes` para um contrato formal de deck
  publico/compartilhado e provar por teste que decks privados continuam
  inacessiveis.

#### P2 — Jobs async de optimize ainda aceitam `user_id` nulo em `server/lib` e na rota de polling

- **Consumidor app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:74`-`:87`
  aceita `202` de `/ai/optimize` e faz polling em
  `app/lib/features/decks/providers/deck_provider_support_ai.dart:190`-`:194`.
- **Camada `server/lib`:** `OptimizeJobStore.create` em
  `server/lib/ai/optimize_job.dart:25`-`:30` declara `String? userId`, persiste
  `user_id` nullable em `:49`-`:64`, e `OptimizeJob.userId` tambem e nullable
  em `server/lib/ai/optimize_job.dart:268`-`:290`.
- **Rota de polling:** `server/routes/ai/optimize/jobs/[id].dart:39`-`:47`
  bloqueia apenas quando `job.userId != null && job.userId != userId`; jobs sem
  dono salvo continuam legiveis por qualquer usuario autenticado que conheca o
  ID.
- **Por que e incoerente:** a rota app-facing de polling e consumida como
  recurso do usuario autenticado, mas o modelo `server/lib` permite job sem
  owner e a rota preserva esse estado como legivel. Mesmo que a criacao normal
  passe `userId`, o contrato estrutural continua permitindo drift por chamadas
  internas futuras, persistencia antiga ou falha de contexto.
- **O que valida:** tornar `userId` obrigatorio em `OptimizeJobStore.create` e
  em `OptimizeJob`, migrar/rejeitar jobs nulos, e trocar a rota de polling para
  retornar 404 quando `job.userId == null || job.userId != userId`, salvo uma
  rota interna separada.
- **O que falsifica:** documentar uma categoria de job interno sem usuario,
  impedir seu uso pelo endpoint app-facing e cobrir esse isolamento com teste.

### Itens verificados e nao classificados como novo problema

- `POST /ai/rebuild` esta coerente com o contrato de ownership: a rota le
  `userId` em `server/routes/ai/rebuild/index.dart:16` e busca o deck com
  `WHERE d.id = @deckId AND d.user_id = @userId` em
  `server/routes/ai/rebuild/index.dart:61`-`:78`; o app chama esse endpoint em
  `app/lib/features/decks/providers/deck_provider_support_ai.dart:165`-`:174`.
- Notificacoes DB/FCM mantem coerencia de tipos e destinos para os fluxos
  app-facing verificados: `direct_message`, `trade_*` e `new_follower` sao
  emitidos por `NotificationService.createFromActorDeferred` e mapeados no app
  por `RealtimeNotificationCoordinator.routeForPayload` e
  `NotificationScreen._navigateToContext`.
- `/decks/:id/analysis` continua alinhado entre rota e app para
  `functional_tags`: a rota retorna `functionalSummary.toJson()` em
  `server/routes/decks/[id]/analysis/index.dart:430`, e
  `DeckAnalysisData.fromJson` consome `json['functional_tags']` em
  `app/lib/features/decks/models/deck_analysis.dart:14`-`:28`.

## Rodada focada: Duplicated or similar logic — revalidacao 2026-05-29 19:00 UTC

Escopo desta rodada: somente logica duplicada ou similar com risco de drift.
Nao foi executada auditoria ampla de classes sem uso, funcoes sem chamada,
imports/ciclos, tabelas PostgreSQL ou coerencia entre camadas fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada; depois o auditor base
  atualizou este arquivo.
- `git rev-parse --short HEAD`: `4172eb02`.
- `rg` nao esta instalado neste shell local; buscas focadas usaram
  `grep -RIn`, `nl -ba` e leitura direta dos arquivos.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor base lista "Funcoes com nomes
duplicados", mas mistura duplicacao real com nomes esperados ou convencionais
como `toString`, `print`, `add` e wrappers de rota. A triagem abaixo manteve
somente casos com mesma intencao funcional, evidencia de corpos similares ou
semantica divergente em caminhos runtime.

### Achados revalidados

#### P1 — `resolveOptimizeArchetype` existe em dois modulos com regras diferentes

- **Simbolos:** `resolveOptimizeArchetype` em
  `server/lib/ai/deck_state_analysis.dart` e
  `server/lib/ai/optimize_runtime_support.dart`.
- **Evidencia de duplicacao:** `server/lib/ai/deck_state_analysis.dart:573`-`:585`
  aceita `requestedArchetype` nullable, usa `generic = {'midrange',
  'general', 'value', 'tempo'}` e retorna `detected` quando o requested e
  generico. `server/lib/ai/optimize_runtime_support.dart:3369`-`:3389`
  exige `requestedArchetype` non-null, trata `detected == 'unknown'` como caso
  especial, usa `genericRequested = {'midrange', 'value', 'goodstuff'}` e so
  troca pelo detected quando ele esta em `{'aggro', 'control', 'combo', 'stax',
  'tribal'}`.
- **Chamadores que bifurcam o comportamento:** `server/lib/ai/optimize_request_support.dart:289`-`:296`
  importa `optimize_runtime_support.dart` e usa a versao de optimize; ja
  `server/lib/ai/rebuild_guided_service.dart:171`-`:173` importa
  `deck_state_analysis.dart` e usa a outra versao.
- **Por que parece risco real:** a pergunta de dominio e a mesma ("qual
  arquetipo efetivo usar?"), mas `tempo`, `general`, `goodstuff` e `unknown`
  recebem tratamento diferente dependendo do fluxo. Optimize e rebuild podem
  aplicar metas diferentes para o mesmo deck/request.
- **O que valida:** centralizar uma unica policy de resolucao de arquetipo e
  adicionar testes cobrindo requested vazio/null, detected `unknown`, generic
  requested (`midrange`, `tempo`, `goodstuff`) e detected especifico.
- **O que falsifica:** documentar contratos distintos para optimize e rebuild
  com nomes diferentes e testes provando a divergencia intencional.

#### P1 — Heuristicas de roles semanticos altos foram duplicadas e ja divergiram

- **Simbolos:** `_looksLikeWincon`, `_looksLikeComboPiece`,
  `_looksLikeEngine`, `_looksLikePayoff` e `_looksLikeEnabler`.
- **Evidencia em functional tags:** `server/lib/ai/functional_card_tags.dart:319`-`:336`
  chama estes helpers para adicionar tags multi-role; as definicoes em
  `:859`-`:905` usam uma mistura de `oracle_text` e nomes conhecidos como
  `Thassa's Oracle`, `Isochron Scepter`, `Dramatic Reversal`, `Blood Artist`,
  `greaves` e `boots`.
- **Evidencia em optimize roles:** `server/lib/ai/optimization_functional_roles.dart:111`-`:117`
  chama helpers com os mesmos nomes para classificar um role unico; as
  definicoes em `:370`-`:397` usam padroes diferentes e nao recebem nome da
  carta.
- **Chamadores impactados:** `OptimizationValidator` usa
  `classifyOptimizationFunctionalRole` em
  `server/lib/ai/optimization_validator.dart:265`-`:267`, e o quality gate usa
  o mesmo classificador em `server/lib/ai/optimization_quality_gate.dart:52`-`:53`.
- **Por que parece risco real:** deck analysis/candidate quality podem marcar
  uma carta como payoff/combo/enabler por nome ou por heuristica ampla, enquanto
  o validator/quality gate do optimize enxerga outro papel ou nenhum papel. O
  drift e funcional, nao apenas cosmetico.
- **O que valida:** criar um adapter compartilhado que retorne conjunto de
  roles + `primary_role`, e usar esse adapter em functional tags, optimize
  validator, quality gate e candidate quality.
- **O que falsifica:** provar por testes que os dois conjuntos de heuristicas
  tem contratos diferentes e que a divergencia e desejada para cada fluxo.

#### P2 — Reconhecimento de terrenos basicos esta copiado com variantes incompatíveis

- **Simbolos:** `_isBasicLandName` / `isBasicLandName`.
- **Evidencia:** `server/lib/ai/optimize_runtime_support.dart:4184`-`:4196`
  reconhece `snow-covered ...`; `server/lib/generated_deck_validation_service.dart:752`-`:763`
  usa `startsWith('snow-covered ...')`; `server/lib/meta/meta_deck_reference_support.dart:890`-`:903`
  reconhece nomes com espaco (`snow covered plains`) em vez de hifen; e
  `server/routes/ai/commander-reference/index.dart:621`-`:628` reconhece apenas
  `plains/island/swamp/mountain/forest/wastes`.
- **Por que parece risco real:** o mesmo conceito de dominio e usado em
  singleton/validacao, optimize, meta reference e commander-reference, mas snow
  basics podem ser permitidos, tratados por prefixo ou ignorados dependendo do
  arquivo.
- **O que valida:** mover a normalizacao para helper unico de dominio e cobrir
  `Snow-Covered Plains`, `Snow Covered Plains`, `Wastes`, casing e whitespace
  em testes compartilhados.
- **O que falsifica:** documentar que algum fluxo deve rejeitar snow basics de
  proposito e adicionar teste especifico para essa excecao.

#### P2 — Trust de marketplace/trades repete SQL e montagem de resposta

- **Simbolos:** `_trustStatsSql`, `_responseTimeSql`, `_shippingTimeSql` e
  `_buildTrustInsight`.
- **Evidencia de SQL duplicado:** `server/routes/trades/index.dart:482`-`:487`
  e `server/routes/trades/[id]/index.dart:50`-`:55` montam os mesmos `LEFT JOIN
  LATERAL` para sender/receiver. Os helpers SQL aparecem duplicados em
  `server/routes/trades/index.dart:557`-`:601` e
  `server/routes/trades/[id]/index.dart:260`-`:304`.
- **Evidencia de resposta duplicada:** `_buildTrustInsight` aparece com corpo
  equivalente em `server/routes/trades/index.dart:603`-`:635`,
  `server/routes/trades/[id]/index.dart:306`-`:338` e
  `server/routes/community/marketplace/index.dart:316`-`:348`.
- **Por que parece risco real:** a confianca exibida em listagem, detalhe e
  marketplace deveria ter mesmo contrato. Qualquer ajuste de regra para conta
  nova, perfil incompleto, historico insuficiente ou medias de resposta/envio
  pode divergir se for alterado em um arquivo so.
- **O que valida:** extrair SQL fragments e serializer para um support de
  trades/trust com testes de shape e source guard para os tres endpoints.
- **O que falsifica:** provar que marketplace e trades precisam de contratos
  diferentes e renomear os helpers/campos para refletir essa diferenca.

#### P2 — Logging de payload invalido em rotas sociais repete `request_id` e usuario

- **Simbolos:** `_requestId` e `_logInvalidPayload`.
- **Evidencia:** `_requestId` + `_logInvalidPayload` aparecem com o mesmo
  padrao try/catch em `server/routes/trades/[id]/status.dart:260`-`:284`,
  `server/routes/trades/[id]/respond.dart:154`-`:178`,
  `server/routes/trades/[id]/messages.dart:228`-`:252` e
  `server/routes/conversations/[id]/messages.dart:247`-`:271`. A rota
  `server/routes/trades/index.dart:330`-`:351` tambem repete o fallback para
  `x-request-id`.
- **Observacao:** `server/lib/request_trace.dart:48`-`:57` ja possui
  `getRequestTrace`/`tryGetRequestId`, mas as rotas ainda mantem wrappers
  privados com fallback proprio.
- **Por que parece risco real:** logs de erro social devem manter formato e
  fallback identicos; hoje qualquer mudanca em campos de correlacao precisa ser
  repetida em varias rotas.
- **O que valida:** criar helper compartilhado para log social invalid payload,
  usando `tryGetRequestId` ou substituindo-o por contrato unico, e cobrir
  fallback sem provider de `RequestTrace`.
- **O que falsifica:** remover o wrapper central e documentar cada rota como
  dona independente do formato de log.

#### P3 — Normalizacao de `condition` de carta continua espalhada

- **Simbolos:** `_validateCardCondition`, `_validateCondition` e allow-list
  `NM/LP/MP/HP/DMG`.
- **Evidencia:** `server/routes/decks/[id]/index.dart:518`-`:523`,
  `server/routes/decks/[id]/cards/index.dart:397`-`:403` e
  `server/routes/decks/[id]/cards/set/index.dart:243`-`:248` normalizam para
  `NM` em valor invalido; `server/routes/binder/index.dart:275`-`:280` e
  `server/routes/binder/[id]/index.dart:339`-`:345` rejeitam valores invalidos
  com erro; `server/routes/community/marketplace/index.dart:39` tambem define a
  mesma allow-list para filtro.
- **Por que parece risco real:** deck cards e binder items usam o mesmo
  vocabulario app-facing de condicao, mas alguns fluxos fazem fallback silencioso
  para `NM` e outros retornam `400`. Pode ser intencional por compatibilidade,
  mas a regra nao esta centralizada.
- **O que valida:** mover a allow-list e a decisao `fallback vs reject` para
  helper compartilhado, mantendo testes que explicitem qual endpoint aceita
  fallback e qual endpoint rejeita.
- **O que falsifica:** documentar formalmente que deck mutations sao tolerantes
  e binder mutations sao estritas, com testes de contrato por endpoint.

#### P3 — `calculateCmc` e `getMainType` ainda estao copiados em rotas de deck publico/privado

- **Simbolos:** `getMainType`, `calculateCmc`, `_calculateCmc`.
- **Evidencia:** `server/routes/decks/[id]/index.dart:405`-`:435` e
  `server/routes/community/decks/[id].dart:91`-`:117` repetem classificacao de
  tipo e calculo aproximado de CMC por regex de mana cost; `server/routes/decks/[id]/simulate/index.dart:171`-`:186`
  possui outra variante de `_calculateCmc`.
- **Por que parece risco real:** mana curve e agrupamento por tipo podem divergir
  entre deck privado, deck comunitario e simulacao se um formato de custo novo
  ou tipo novo for tratado em apenas uma rota.
- **O que valida:** extrair helper compartilhado para `deck_card_math` ou
  reutilizar campo `cmc` persistido quando disponivel, com testes para custo
  numerico, `X`, hibrido/phyrexian e custo vazio.
- **O que falsifica:** demonstrar que esses blocos sao apenas apresentacao
  legacy sem impacto app-facing e remover/encapsular quando os endpoints forem
  simplificados.

### Itens verificados e nao classificados como novo problema

- Wrappers finos em `server/routes/ai/optimize/index.dart:56`-`:63` delegam para
  `optimize_support.resolveOptimizeArchetype`; a duplicacao relevante fica entre
  os modulos `deck_state_analysis.dart` e `optimize_runtime_support.dart`.
- `toString`, `print`, `add`, `build`, `fromJson` e `onRequest` aparecem como
  duplicados no relatorio gerado, mas sao convencoes ou APIs de framework e nao
  foram tratados como achados desta rodada.
- A lista de condicoes `NM/LP/MP/HP/DMG` tambem existe na UI Flutter
  (`binder_item_editor.dart`, `binder_screen.dart`, modelos de deck). Foi
  mantida como evidencia secundaria; o achado acima foca primeiro na divergencia
  de contrato no backend.

## Rodada focada: PostgreSQL tables not used — revalidacao 2026-05-29 15:00 UTC

Escopo desta rodada: somente tabelas PostgreSQL sem uso, write-only ou com
consumo parcial. Nao foi executada auditoria ampla de classes, funcoes, imports,
ciclos, duplicacao ou coerencia entre camadas fora deste foco.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada; depois o auditor base
  tocou este arquivo.
- `git rev-parse --short HEAD`: `88c4af78`.
- `rg` nao esta instalado neste shell local; buscas focadas usaram
  `grep -RIn`, `find` e scripts Python somente leitura.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor base conta ocorrencias de `FROM`/`JOIN`
em `server/lib` e `server/routes`, mas nao separa schema/migration, leitura,
escrita, CTEs e tabelas reais. A triagem focada cruzou `CREATE TABLE`, `INSERT
INTO`, `UPDATE`, `DELETE FROM`, `FROM` e `JOIN` em `server/`, excluindo apenas
migrations/verificadores quando o objetivo era achar consumo runtime.

### Achados revalidados

#### P2 — `deck_matchups` continua write-only no produto atual

- **Tabela:** `deck_matchups`.
- **Schema:** definida em `server/database_setup.sql:162`.
- **Escrita encontrada:** `server/routes/ai/simulate-matchup/index.dart:360`
  faz `INSERT INTO deck_matchups (...) ON CONFLICT (...) DO UPDATE`.
- **Leitura encontrada:** nenhum `SELECT ... FROM deck_matchups`, `JOIN
  deck_matchups`, `UPDATE deck_matchups` ou `DELETE FROM deck_matchups` em
  `server/routes`, `server/lib` ou `server/bin`, exceto verificadores/schema.
- **Por que parece nao usada:** a resposta da propria rota e calculada em
  memoria e retornada imediatamente; `deck_matchups.win_rate/notes` nao
  alimenta historico, cache, dashboard, ranking ou UI.
- **O que valida:** criar consumidor real de `deck_matchups` com contrato e
  teste, por exemplo historico/cached matchup ou dashboard operacional.
- **O que falsifica:** encontrar um `SELECT/JOIN` runtime dessa tabela em rota
  ou lib consumida pelo app/operacao.

#### P2 — `deck_weakness_reports` acumula registros sem fluxo de leitura ou resolucao

- **Tabela:** `deck_weakness_reports`.
- **Schema:** definida em `server/database_setup.sql:363` e no migrador
  `server/bin/migrate_create_missing_tables.dart:97`.
- **Escrita encontrada:** `server/routes/ai/weakness-analysis/index.dart:374`
  faz `INSERT INTO deck_weakness_reports (...) ON CONFLICT DO NOTHING`.
- **Leitura encontrada:** nenhum `SELECT ... FROM deck_weakness_reports`,
  `JOIN deck_weakness_reports`, `UPDATE deck_weakness_reports` ou `DELETE FROM
  deck_weakness_reports` em `server/routes`, `server/lib` ou `server/bin`,
  exceto schema/verificadores.
- **Por que parece nao usada:** a rota devolve a analise recem-calculada e nao
  le historico; o campo `addressed` tambem nao tem fluxo confirmado para marcar
  correcao pelo usuario.
- **O que valida:** endpoint/job/UI que leia reports persistidos e fluxo que
  atualize `addressed`, ou decisao explicita de tratar a tabela como log bruto
  com retencao.
- **O que falsifica:** uma leitura runtime da tabela com uso app-facing ou
  operacional claro.

#### P3 — `ml_prompt_feedback` tem helper de insert sem chamador e apenas contador operacional

- **Tabela:** `ml_prompt_feedback`.
- **Schema:** definida em `server/bin/migrate_ml_knowledge.dart:159`.
- **Escrita potencial:** `MLKnowledgeService.recordFeedback` em
  `server/lib/ml_knowledge_service.dart:251` executa `INSERT INTO
  ml_prompt_feedback` em `:264`.
- **Chamada encontrada:** `grep -RIn "recordFeedback" server app` encontrou
  somente a definicao do helper.
- **Leitura encontrada:** `/ai/ml-status` executa apenas `SELECT COUNT(*)::int
  as c FROM ml_prompt_feedback` em `server/routes/ai/ml-status/index.dart:98`.
- **Por que parece nao usada:** nao ha coleta ativa de feedback do app/API nem
  loop de aprendizado que consuma as linhas; o status operacional so conta rows.
- **O que valida:** ligar `recordFeedback` a uma rota/acao real e criar job que
  use feedback para refinar prompts/modelo, com teste de contrato.
- **O que falsifica:** remover a persistencia/helper ate existir fluxo de
  feedback, ou provar chamador runtime fora deste grep.

#### P3 — Tabelas raw do Commander Reference Deck Corpus seguem como lineage sem leitura direta

- **Tabelas:** `commander_reference_decks` e
  `commander_reference_deck_cards`.
- **Schema:** criadas em
  `server/lib/ai/commander_reference_deck_corpus_support.dart:1177` e `:1200`.
- **Escritas encontradas:** `INSERT INTO commander_reference_decks` em `:1245`,
  `DELETE FROM commander_reference_deck_cards` em `:1329` e `INSERT INTO
  commander_reference_deck_cards` em `:1345`.
- **Leitura app-facing encontrada:** o produto le o agregado
  `commander_reference_deck_analysis` em `:389`; nao ha `SELECT/JOIN` runtime
  confirmado contra as tabelas raw.
- **Por que parece parcialmente usada:** as raws preservam lineage/audit do
  corpus, mas o caminho de geracao consome somente o agregado sanitizado.
- **O que valida:** documentar oficialmente retencao/reprocessamento das raws
  ou adicionar job/endpoint que as leia.
- **O que falsifica:** leitura runtime das raws para gerar diagnostics,
  reprocessar corpus ou alimentar qualidade.

### Itens verificados e nao classificados como problema

- `schema_migrations` aparece sem consumidor de produto, mas e tabela interna do
  migrador (`server/bin/migrate.dart`) e nao foi classificada como unused.
- `battle_simulations` recebe insert de `/ai/simulate` e e lida pelo CLI
  `server/bin/ml_extract_features.dart`; nao entrou como achado desta rodada
  porque ha consumidor ML operacional, ainda que nao app-facing.
- Tabelas como `format_staples`, `external_commander_meta_candidates`,
  `optimization_analysis_logs`, `card_meta_insights`, `synergy_packages`,
  `archetype_patterns`, `ml_learning_state`, `sync_state` e `sync_log` possuem
  leituras/escritas em servicos, rotas internas ou CLIs e nao foram
  classificadas como sem uso.

> Atualizacao Copilot: 2026-05-29 12:10 UTC
> Commit verificado: `origin/master@2396956e`

## Revalidacao pos-correcao: `sync_cards_utils.dart` ligado ao sync operacional

O Copilot cruzou o achado de helper testado sem chamador runtime contra a
`master` real e aplicou correcao segura em `origin/master@2396956e`.

### Resolvido em `origin/master@2396956e`

- `server/bin/sync_cards.dart` agora importa `server/lib/sync_cards_utils.dart`.
- O CLI operacional passou a usar `parseSinceDays`,
  `getNewSetCodesSinceFromData`, `extractCardRow`, `extractSetCardRow`,
  `extractOracleIds` e `extractLegalities`.
- As copias privadas `_parseSinceDays`, `_getNewSetCodesSinceFromData` e
  `_extractCardRow` foram removidas do binario.
- Os loops inline de rows incrementais, oracle IDs e legalidades foram
  substituidos pelos helpers compartilhados.
- `extractSetCardRow` foi alinhado ao prepared statement real de sync
  incremental e agora retorna tambem `collector_number` e `foil`.

### Validacao executada

- `dart format lib/sync_cards_utils.dart bin/sync_cards.dart test/sync_cards_test.dart`
- `dart analyze lib/sync_cards_utils.dart bin/sync_cards.dart test/sync_cards_test.dart`
- `dart test test/sync_cards_test.dart -r expanded`
- `dart analyze bin lib routes test`
- `dart test` em `server/`: 610 testes passaram.
- `git diff --check`
- Scan simples de segredos no diff/stage.
- Hermes post-push smoke para `2396956e`: `PASS`.

### Observacoes

- Esta rodada nao executou o sync MTGJSON real contra banco. A alteracao foi
  limitada a religar o caminho operacional aos helpers ja testados e preservar o
  contrato SQL existente.
- Permanecem abertos os outros helpers publicos sem chamador runtime listados
  nesta auditoria (`request_trace`, Commander Reference, PerformanceService,
  MTGTop8 e candidate quality sample SQL).

> Atualizacao Copilot: 2026-05-29 11:56 UTC
> Commit verificado: `origin/master@640f4ab4`

## Revalidacao pos-correcao: imports app e ciclo Community/Social

O Copilot cruzou os achados desta rodada contra a `master` real e aplicou
correcao segura em `origin/master@640f4ab4`.

### Resolvido em `origin/master@640f4ab4`

- `app/lib/features/decks/widgets/deck_analysis_tab.dart` e
  `app/lib/features/home/life_counter_screen.dart` agora importam
  `AppTheme`/`ManaHelper` via `package:manaloom/...`, removendo dependencia de
  profundidade relativa fragil.
- `CommunityDeckDetailScreen` nao importa mais `UserProfileScreen`; navega para
  `/community/user/:userId` via `GoRouter`.
- `UserProfileScreen` nao importa mais `CommunityDeckDetailScreen`; navega para
  `/community/decks/:deckId` via `GoRouter`.
- `app/lib/main.dart` registrou a rota `/community/decks/:deckId`.

### Validacao executada

- `flutter analyze lib/main.dart lib/features/decks/widgets/deck_analysis_tab.dart lib/features/home/life_counter_screen.dart lib/features/community/screens/community_deck_detail_screen.dart lib/features/social/screens/user_profile_screen.dart --no-version-check`
- `flutter analyze lib test --no-version-check`
- Grafo local de imports em `app/lib`: `SCCS 0`
- `flutter test test/features/community/providers/community_provider_test.dart test/features/community/providers/social_provider_test.dart test/features/home/life_counter_screen_test.dart --no-version-check --reporter compact`
- `git diff --check`
- Hermes post-push smoke para `640f4ab4`: `PASS`

### Observacoes

- `server/bin/local_test_server.dart` foi corrigido em
  `origin/master@a830f9f3`: nao importa mais `../.dart_frog/server.dart`
  estaticamente, valida `.dart_frog/server.dart` em runtime e encerra o processo
  filho em `SIGINT`/`SIGTERM`. `dart analyze bin/local_test_server.dart` passou
  sem depender do arquivo gerado.
- A rodada mista com `home_screen_test.dart` falhou por expectativa preexistente
  (`Gerar com IA` ausente) e golden longa; ela nao foi usada como gate desta
  correcao. Os testes diretamente afetados passaram.

> Atualizacao: 2026-05-29 11:00 UTC
> Rotacao local Codex: `broken-imports-and-circular-dependencies`

## Rodada focada: Broken imports and circular dependencies

Escopo desta rodada: somente imports quebrados e ciclos de dependencias locais.
Nao foi executada auditoria ampla de classes, funcoes, tabelas PostgreSQL,
duplicacao geral ou coerencia funcional entre camadas.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada; depois o auditor base
  atualizou este arquivo.
- `git rev-parse --short HEAD`: `ba3b74ad`.
- `rg` nao esta instalado neste shell local; buscas focadas usaram
  `grep -RIn`, `find` e um resolvedor local somente leitura para diretivas Dart.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados no recorte `server/lib` + `server/routes`: 0.

Limitacao para esta rotacao: o auditor base nao cobre `server/bin`, `app/lib`,
`app/test` ou `app/integration_test`, e tambem nao calcula ciclos de imports.
Por isso a triagem focada montou um grafo de imports locais para 721 arquivos
Dart em `server/` e `app/`, resolvendo `package:server/...`,
`package:manaloom/...`, alias historico `package:ai/...` e imports relativos a
partir do arquivo origem.

Validação adicional:

- `dart analyze` em `server/` confirmou 1 erro de import na rodada original:
  `bin/local_test_server.dart:3:8 - Target of URI doesn't exist:
  '../.dart_frog/server.dart'`. Esse ponto foi resolvido posteriormente em
  `origin/master@a830f9f3`.
- `flutter analyze --no-pub --no-fatal-infos` em `app/` nao foi conclusivo para
  estes achados porque `app/.dart_tool/package_config.json` nao existe neste
  checkout; o analyzer reportou dezenas de milhares de erros de pacote ausente
  (`package:flutter`, `package:manaloom`, `package:flutter_lints`, etc.) antes
  de uma leitura util dos imports locais.

### Achados confirmados

#### P1 — Dois imports relativos em `app/lib` apontam para `app/core`, que nao existe

- **Imports quebrados:**
  - `app/lib/features/decks/widgets/deck_analysis_tab.dart:5` importa
    `../../../../core/utils/mana_helper.dart`.
  - `app/lib/features/home/life_counter_screen.dart:7` importa
    `../../../core/theme/app_theme.dart`.
- **Evidencia filesystem:** os arquivos reais existem em
  `app/lib/core/utils/mana_helper.dart` e `app/lib/core/theme/app_theme.dart`.
  Resolvidos a partir dos arquivos origem, os imports atuais apontam para
  `app/core/utils/mana_helper.dart` e `app/core/theme/app_theme.dart`, que nao
  existem.
- **Por que parece quebrado:** a profundidade relativa esta um nivel acima do
  necessario. Em `deck_analysis_tab.dart`, outros imports core vizinhos usam
  `../../../core/...`; em `life_counter_screen.dart`, o arquivo esta em
  `app/lib/features/home/`, entao `../../../core/...` tambem sobe ate `app/`,
  nao ate `app/lib/`.
- **Impacto:** qualquer build/analyze com package config valido deve falhar ao
  resolver esses arquivos, ou entao esses arquivos ficam fora do grafo efetivo
  de compilacao se nao forem atingidos.
- **O que valida:** corrigir os imports para alvos sob `app/lib/core/...` e
  rerodar `flutter analyze` depois de recriar `app/.dart_tool/package_config.json`
  com `flutter pub get`.
- **O que falsifica:** provar que estes arquivos nao entram mais no produto e
  remove-los/retira-los do grafo, ou demonstrar outro mecanismo de resolucao que
  faca `app/core/...` existir no ambiente de build.

#### P1 — `server/bin/local_test_server.dart` importa artefato Dart Frog ausente

**Status 2026-05-29: RESOLVIDO em `origin/master@a830f9f3`.**

- O import estatico para `../.dart_frog/server.dart` foi removido.
- O wrapper checa `.dart_frog/server.dart` em runtime e imprime instrucao clara
  quando o artefato ainda nao foi gerado.
- Quando o artefato existe, o wrapper executa `dart run .dart_frog/server.dart`
  com `PORT`, repassa stdout/stderr e encerra o processo filho em
  `SIGINT`/`SIGTERM`.
- Validado com `dart analyze bin/local_test_server.dart`, health local em
  `PORT=18082`, encerramento sem listener residual, `dart analyze bin lib routes
  test`, `dart test` e Hermes smoke.

- **Import quebrado:** `server/bin/local_test_server.dart:3` importa
  `../.dart_frog/server.dart`.
- **Evidencia:** `dart analyze` em `server/` falhou com
  `uri_does_not_exist` exatamente nesse import. `ls server/.dart_frog` nao
  encontrou o diretorio no checkout atual.
- **Por que parece quebrado:** o binario depende de um artefato gerado pelo Dart
  Frog, mas o artefato nao esta versionado nem presente localmente.
- **Impacto:** o backend nao fica analisavel com `dart analyze` puro enquanto o
  arquivo existir nesse estado; isso reduz a confianca de checks locais e ja
  aparece como risco recorrente em `PLANO_CORRECAO.md`.
- **O que valida:** documentar/automatizar a geracao de `.dart_frog/server.dart`
  antes do analyze, ou trocar o entrypoint por um caminho resiliente que nao
  exija artefato ausente.
- **O que falsifica:** remover o binario se ele for legado, ou provar que o
  fluxo oficial de analyze sempre gera `.dart_frog/server.dart` antes da
  verificacao.

#### P2 — Ciclo direto entre detalhe de deck comunitario e perfil social

- **Ciclo confirmado:**
  - `app/lib/features/community/screens/community_deck_detail_screen.dart:8`
    importa `../../social/screens/user_profile_screen.dart`.
  - `app/lib/features/social/screens/user_profile_screen.dart:7` importa
    `../../community/screens/community_deck_detail_screen.dart`.
- **Chamadas que fecham o ciclo:**
  - `community_deck_detail_screen.dart:213` navega para
    `UserProfileScreen(userId: deck['owner_id'] as String)`.
  - `user_profile_screen.dart:469` navega para
    `CommunityDeckDetailScreen(deckId: deck.id)`.
- **Evidencia do grafo:** a triagem de 721 arquivos Dart encontrou 1 unico SCC
  com mais de um arquivo, composto exatamente por essas duas telas; nao foram
  encontrados ciclos locais em `server/lib`, `server/routes` ou `server/bin`.
- **Por que importa:** telas de dominios diferentes (`community` e `social`)
  conhecem as classes concretas uma da outra. Mesmo que Dart aceite ciclos de
  import em alguns cenarios, isso dificulta recorte, testes isolados e evolucao
  de rotas/navegacao.
- **O que valida:** mover a navegacao cruzada para rotas nomeadas/GoRouter, um
  callback de navegacao injetado, ou um helper de navegacao fora dos dois
  dominios, e rerodar o grafo local mostrando `SCCS 0`.
- **O que falsifica:** demonstrar que um dos imports nao e mais necessario no
  runtime ou que a tela foi retirada do fluxo app-facing.

### Itens verificados e nao classificados como problema

- O auditor estrutural base continua reportando `Imports quebrados: 0` para
  `server/lib` e `server/routes`; os achados acima estao fora desse recorte.
- O resolvedor focado nao encontrou outros imports/exports/parts locais
  quebrados em `server/` e `app/` alem dos 3 listados.
- O grafo focado nao encontrou ciclos de imports locais no backend.

## Rodada focada: Functions not called

Escopo desta rodada: somente funcoes aparentemente nao chamadas ou chamadas
apenas por testes/harnesses fora do fluxo runtime. Nao foi executada auditoria
ampla de classes, imports/ciclos, tabelas PostgreSQL, duplicacao geral ou
coerencia entre camadas.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativo.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada.
- `git rev-parse --short HEAD`: `e5de80fd`.
- `rg` nao esta instalado neste shell local; buscas focadas usaram
  `grep -RIn --include='*.dart' --include='*.md'`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor lista apenas "Funcoes Publicas
(primeiros 5 por arquivo)" e "Funcoes com nomes duplicados"; ele nao prova
chamadores. A triagem abaixo usou busca textual de simbolos e manteve apenas
casos em que o nome aparece so na propria definicao, em testes, ou em scripts
operacionais fora do runtime app/API.

### Achados confirmados

#### P1 — `sync_cards_utils.dart` estava testado, mas nao era chamado pelo sync real

**Status 2026-05-29: RESOLVIDO em `origin/master@2396956e`.**

- **Funcoes:** `extractCardRow`, `parseSinceDays`, `extractSetCardRow`,
  `extractOracleIds` e `extractLegalities`.
- **Correcao aplicada:** `server/bin/sync_cards.dart` agora importa
  `sync_cards_utils.dart` e usa esses helpers no full sync, sync incremental,
  selecao de sets, oracle IDs e legalidades. O helper `extractSetCardRow` foi
  expandido para devolver `collector_number` e `foil`, mantendo compatibilidade
  com o INSERT incremental de 12 colunas.
- **Validacao:** `dart analyze bin lib routes test` e `dart test` em `server/`
  passaram; `test/sync_cards_test.dart` foi ampliado para o shape incremental
  real.

Historico do achado:

- **Definicoes:** `server/lib/sync_cards_utils.dart:16`, `:102`, `:116`,
  `:161` e `:172`.
- **Evidencia de nao chamada no runtime:** `grep -RIn --include='*.dart'
  "sync_cards_utils" server` encontrou apenas
  `server/test/sync_cards_test.dart:3`; nenhum `server/bin/*.dart`,
  `server/lib/*.dart` ou rota importa esse arquivo.
- **Comparacao com o sync ativo:** `server/bin/sync_cards.dart` importa
  `mtg_data_integrity_support.dart`, mas nao `sync_cards_utils.dart`; ele mantem
  implementacoes privadas equivalentes em `server/bin/sync_cards.dart:376`
  (`_parseSinceDays`), `:680` (`_extractCardRow`) e loops inline para oracle IDs
  e legalidades em `:806`-`:838`. O bloco incremental de carta tambem monta rows
  inline em `:604`-`:663`, em vez de chamar `extractSetCardRow`.
- **Por que parece nao chamada:** as buscas por simbolo mostram os helpers
  publicos usados somente por `server/test/sync_cards_test.dart`; o binario que
  roda o sync operacional usa codigo privado no proprio arquivo.
- **Risco:** os testes podem estar validando uma copia morta da logica, enquanto
  mudancas no sync real passam sem exercitar os helpers testados. Isso tambem
  preserva duplicacao entre a promessa do comentario de `sync_cards_utils.dart`
  ("extraidas do sync_cards.dart") e o estado real do CLI.
- **O que valida:** importar `sync_cards_utils.dart` em
  `server/bin/sync_cards.dart` e substituir as copias privadas/loops inline por
  esses helpers, mantendo `server/test/sync_cards_test.dart` como cobertura
  direta do caminho operacional.
- **O que falsifica:** remover `sync_cards_utils.dart` e seus testes como
  harness legado, ou provar outro entrypoint operacional que o importe.

#### P2 — Wrapper de request trace existe, mas os chamadores usam `context.read<RequestTrace>()` direto

- **Funcoes:** `getRequestTrace` e `tryGetRequestId`.
- **Definicoes:** `server/lib/request_trace.dart:48` e
  `server/lib/request_trace.dart:51`.
- **Evidencia:** `grep -RIn --include='*.dart' "\btryGetRequestId\b" server app`
  encontrou apenas a propria definicao. `getRequestTrace` aparece apenas na
  definicao e dentro de `tryGetRequestId`. Em contraste, rotas e middlewares
  acessam `RequestTrace` diretamente, por exemplo
  `server/routes/_middleware.dart:29` cria o trace,
  `server/routes/_middleware.dart:64` injeta o provider,
  `server/routes/trades/index.dart:332` e
  `server/routes/conversations/[id]/messages.dart:249` leem
  `context.read<RequestTrace>().requestId`.
- **Por que parece nao chamada:** nao ha chamador runtime nem teste direto para
  `tryGetRequestId`; o wrapper `getRequestTrace` so existe para alimentar esse
  helper sem uso.
- **O que valida:** trocar rotas/helpers que fazem acesso direto por
  `getRequestTrace`/`tryGetRequestId` quando o fallback for intencional.
- **O que falsifica:** remover os wrappers e manter o contrato atual de acesso
  direto, ou adicionar chamador real coberto por teste.

#### P2 — `normalizedCommanderReferenceCandidate` nao tem chamador

- **Funcao:** `normalizedCommanderReferenceCandidate`.
- **Definicao:** `server/lib/ai/commander_reference_profile_support.dart:49`.
- **Evidencia:** `grep -RIn --include='*.dart'
  "\bnormalizedCommanderReferenceCandidate\b" server/lib server/routes
  server/bin server/test` encontrou apenas a propria definicao. O codigo ativo
  usa `normalizeCommanderReferenceName` diretamente em
  `server/lib/ai/commander_reference_card_stats_support.dart:308`, `:559`,
  `:717`, `server/lib/ai/commander_reference_readiness_support.dart:304` e
  `server/routes/ai/generate/index.dart:581`.
- **Por que parece nao chamada:** a funcao nullable parece ser um wrapper
  residual de normalizacao, mas os consumidores fazem normalizacao direta.
- **O que valida:** substituir consumidores que precisam de retorno nullable
  por esse wrapper e adicionar teste.
- **O que falsifica:** apagar o wrapper e manter `normalizeCommanderReferenceName`
  como API unica.

#### P2 — Parte da API customizada de `PerformanceService` nao e chamada pelo app

- **Funcoes/metodos:** `startTrace`, `stopTrace`, `addMetric`,
  `addAttribute`, `getLocalStats` e `printLocalStats`.
- **Definicoes:** `app/lib/core/services/performance_service.dart:110`,
  `:130`, `:200`, `:210`, `:220` e `:248`.
- **Evidencia:** `grep -RIn --include='*.dart'
  "\bPerformanceService\b\|\bstartTrace\b\|\bstopTrace\b\|\baddMetric\b\|\baddAttribute\b\|\bprintLocalStats\b\|\bgetLocalStats\b"
  app/lib app/test app/integration_test` encontrou inicializacao em
  `app/lib/main.dart:121`, uso de `traceAsync` no smoke
  `app/integration_test/release_observability_smoke_test.dart:51` e o
  `PerformanceNavigatorObserver`, mas nao encontrou chamadas runtime para os
  metodos customizados listados alem das proprias definicoes. `getLocalStats`
  so e chamado por `printLocalStats`, que tambem nao tem chamador externo.
- **Por que parece nao chamada:** a observabilidade ativa usa `init`,
  `traceAsync` e o observer de navegacao; a API manual de traces/metricas parece
  ter ficado como superficie planejada ou legado de debug.
- **Risco:** baixo/medio. Nao afeta fluxo de produto diretamente, mas aumenta a
  superficie de observabilidade aparente e pode sugerir que metricas customizadas
  estao instrumentadas quando nao estao.
- **O que valida:** instrumentar chamadas reais para operacoes criticas
  (`fetch_decks`, optimize, import, etc.) usando esses metodos, ou adicionar
  testes/smokes que provem consumo.
- **O que falsifica:** remover os metodos manuais e manter `traceAsync`/observer
  como contrato unico de performance.

#### P2 — `extractMtgTop8FormatCodeFromSourceUrl` e test-only no checkout atual

- **Funcao:** `extractMtgTop8FormatCodeFromSourceUrl`.
- **Definicao:** `server/lib/meta/mtgtop8_meta_support.dart:139`.
- **Evidencia:** `grep -RIn --include='*.dart'
  "\bextractMtgTop8FormatCodeFromSourceUrl\b" .` encontrou somente
  `server/test/mtgtop8_meta_support_test.dart:147` e a definicao. A funcao
  vizinha `extractMtgTop8EventIdFromSourceUrl` e usada pelo reparo operacional
  em `server/bin/repair_mtgtop8_meta_history.dart:59`, mas o format code nao e
  consumido.
- **Por que parece nao chamada:** o helper de formato foi mantido junto do
  helper de event id, mas o pipeline atual nao usa o parametro `f` extraido da
  URL.
- **O que valida:** usar o helper no reparo/import/promocao quando o formato da
  URL for parte do contrato.
- **O que falsifica:** remover o helper e o teste, se o formato for derivado de
  outra fonte mais confiavel.

#### P2 — `buildCandidateQualitySamplePoolSql` so e exercitado por teste

- **Funcao:** `buildCandidateQualitySamplePoolSql`.
- **Definicao:** `server/lib/ai/candidate_quality_data_support.dart:631`.
- **Evidencia:** `grep -RIn --include='*.dart'
  "\bbuildCandidateQualitySamplePoolSql\b" server/bin server/lib server/routes
  server/test` encontrou apenas
  `server/test/candidate_quality_data_support_test.dart:123` e a definicao. O
  runner operacional `server/bin/candidate_quality_data_foundation.dart` importa
  `candidate_quality_data_support.dart`, mas monta seus pools via
  `_loadCandidateCards`, `_buildSampleCandidatePools` e SQL proprio; a busca por
  `optimize_candidate_quality_summary cqs` aparece somente no builder sem uso.
- **Por que parece nao chamada:** o SQL builder pode ser resquicio de uma
  amostragem anterior; hoje nao ha rota, lib runtime ou binario que execute a
  string retornada.
- **O que valida:** chamar esse builder a partir do runner/scorecard que precisa
  da amostra, com teste de integracao ou dry-run.
- **O que falsifica:** remover o builder e seu teste se a amostragem atual for
  responsabilidade definitiva de `candidate_quality_data_foundation.dart`.

### Itens verificados e nao classificados como problema

- `auditCommanderReferenceTables`, `ensureCommanderReferenceProfileTable`,
  `ensureCommanderReferenceCardStatsTable`, `ensureCardLocalizedNamesTable`,
  `decodeExternalCommanderMetaArtifact`, `isCommanderCandidateLegalityAllowed`,
  `loadExistingMetaDeckFingerprints` e `metaDeckAnalyticsFormatKey` aparecem com
  baixa contagem em `server/lib`, mas tem chamadores em `server/bin`; foram
  classificados como suporte operacional, nao como funcoes mortas.
- Funcoes top-level em rotas Dart Frog chamadas por convencao (`onRequest`) nao
  foram auditadas como "nao chamadas".

## Rodada focada: Card semantics audit

Escopo desta rodada: hardcoded card names em runtime, drift entre
`functional_tags`, `semantic_tags_v2` e classificacao funcional do optimize, e
pontos onde utilidade ainda e inferida por nome em vez de texto/tipo/custo/dados
semanticos persistidos.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativo.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada.
- `git rev-parse --short HEAD`: `7014a2cc`.
- `rg` nao esta instalado neste shell local; buscas focadas usaram
  `grep -RIn` em `server/lib`, `server/routes` e `app/lib`.

### Achados confirmados

#### P1 — Excecoes por nome ainda entram na classificacao semantica de runtime

- **Fluxo:** `inferFunctionalCardTags`, `inferSemanticCardAnalysisV2` e
  `inferCandidateFunctionTags`.
- **Evidencia:**
  - `server/lib/ai/functional_card_tags.dart:220`-`:226` classifica ramp por
    `normalizedName.contains('signet')`, `normalizedName.contains('talisman')`,
    `normalizedName == 'sol ring'` e `normalizedName == 'arcane signet'`.
  - `server/lib/ai/functional_card_tags.dart:714`-`:717`, `:754`-`:780`,
    `:823`-`:851` e `:859`-`:899` usam nomes como `Teferi's Protection`,
    `Heroic Intervention`, `Swiftfoot Boots`, `Lightning Greaves`,
    `Blood Artist`, `Ephemerate`, `Jeska's Will`, `Thassa's Oracle`,
    `Isochron Scepter` e `Dramatic Reversal` para protecao, aristocrats,
    blink, ritual, wincon, combo, payoff e enabler.
  - `server/lib/ai/candidate_quality_data_support.dart:375`-`:379`,
    `:421`-`:428`, `:439`-`:445`, `:472`-`:478`, `:590`-`:605` e
    `:611`-`:628` repetem parte dessas excecoes e ainda aplicam
    `highPowerNames`/`premium` para bracket e score.
- **Classificacao:** **Risk**. Estes sao caminhos de runtime que afetam analise,
  candidate quality e optimize; nao sao fixtures, docs ou corpus. Algumas
  cartas podem merecer excecao conhecida, mas no checkout local elas nao estao
  versionadas como policy nem ligadas a dados persistidos com motivo/fonte.
- **Por que importa:** uma carta pode ganhar papel funcional por nome mesmo que
  `oracle_text`, `type_line`, `mana_cost`, `cmc` ou `semantic_tags_v2`
  persistidos nao justifiquem o papel; isso tambem torna o comportamento dificil
  de auditar quando Oracle muda ou quando uma carta com texto equivalente nao
  esta na lista.
- **O que valida:** testes que comparem cartas com texto equivalente e nomes
  diferentes, alem de teste de policy versionada para cada excecao realmente
  intencional.
- **O que falsifica:** mover essas excecoes para dados semanticos persistidos ou
  policy versionada com `role`, `reason`, `source`, `bracket` e testes que
  provem que o fallback por texto continua suficiente para cartas equivalentes.
- **Correcao recomendada:** manter heuristicas por `oracle_text`/`type_line`
  como fonte principal, backfillar excecoes reais em `card_semantic_tags_v2` ou
  policy versionada, e remover checks inline de nome dos classificadores puros.

#### P1 — Optimize ainda possui listas fixas de staples/fillers que influenciam score e selecao

- **Fluxo:** mana base, complete/filler, fallback universal e fallback
  contextual do optimize.
- **Evidencia:**
  - `server/lib/ai/optimize_runtime_support.dart:406`-`:454` define
    `premiumLandNames` e soma `+250` para terrenos como `Command Tower`,
    `City of Brass`, `Exotic Orchard`, `Mana Confluence`, `Path of Ancestry` e
    `Reflecting Pool`.
  - `server/lib/ai/optimize_runtime_support.dart:1296`-`:1345` consulta uma
    lista fixa de staples quando o pool inicial tem menos candidatos.
  - `server/lib/ai/optimize_runtime_support.dart:1948`-`:1995` define
    `_weakCommanderFillerDenylist` e `_premiumCommanderFillerNames`; `:2033`-`:2052`
    aplica bonus de score para nomes premium.
  - `server/lib/ai/optimize_runtime_support.dart:3476`-`:3509` e `:3565`-`:3615`
    carregam fallbacks universais/contextuais por nomes fixos antes de ordenar
    por legalidade/meta.
  - Busca local encontrou apenas `server/lib/edh_bracket_policy.dart` como
    modulo `*policy*`; o `commander_fallback_policy.dart` citado em anotacoes
    historicas nao existe neste checkout.
- **Classificacao:** **Risk**. A selecao ainda consulta banco/legality/color
  identity, mas a prioridade inicial e o bonus de utilidade sao por nome.
- **Por que importa:** a promessa operacional de `functional_tags_then_semantic_v2_then_heuristic`
  nao se sustenta nesses caminhos; staples nomeadas podem superar cartas mais
  adequadas por oracle/role/custo/semantic score.
- **O que valida:** extrair as listas para policy versionada ou tabela de seed
  com fonte e motivo, e testes que provem que legalidade, identidade de cor,
  bracket, budget e role semantic continuam bloqueando sugestoes inadequadas.
- **O que falsifica:** se essas listas forem apenas corpus/benchmark inerte;
  nesta leitura elas sao usadas por score/selecao runtime, entao nao sao inertes.
- **Correcao recomendada:** centralizar os nomes em policy versionada
  (`commander_fallback_policy` ou tabela), registrar `source/reason`, e preferir
  `semantic_tags_v2`, `card_role_scores`, `card_function_tags`, meta usage,
  `oracle_text`, `type_line`, `mana_cost` e `cmc` no score final.

#### P1 — Deck analysis usa `card_function_tags`, mas optimize/validator nao carrega esse sinal

- **Fluxos comparados:** `summarizeFunctionalTagsForDeck`,
  `loadOptimizeDeckContext`, `classifyOptimizationFunctionalRole`,
  `OptimizationValidator` e `filterUnsafeOptimizeSwapsByCardData`.
- **Evidencia:**
  - `server/routes/decks/[id]/analysis/index.dart:80`-`:96` e
    `server/routes/decks/[id]/ai-analysis/index.dart:119`-`:135` selecionam
    `card_function_tags` e `semantic_tags_v2`.
  - `server/lib/ai/functional_card_tags.dart:432`-`:465` prefere
    `functional_tags` persistidos e so cai para heuristica quando nao ha tag
    persistida; `:551`-`:607` le `semantic_tags_v2` para detalhes/explicacao.
  - `server/lib/ai/optimize_request_support.dart:86`-`:105`, `:186`-`:198` e
    `:323`-`:339` carregam `semantic_tags_v2`, mas nao carregam
    `card_function_tags`/`functional_tags` para `allCardData`.
  - `server/lib/ai/optimization_functional_roles.dart:55`-`:58` usa
    `semantic_tags_v2` primeiro, depois cai para `type_line`/`oracle_text`
    (`:60`-`:124`); nao ha leitura de `functional_tags`.
  - `server/lib/ai/optimization_validator.dart:265`-`:267` e
    `server/lib/ai/optimization_quality_gate.dart:52`-`:53` chamam
    `classifyOptimizationFunctionalRole`, portanto herdam essa ausencia.
- **Classificacao:** **Risk / semantic drift**.
- **Por que importa:** uma carta pode aparecer corretamente como `draw`,
  `ramp`, `removal`, `engine`, `payoff` etc. na aba de analise por causa de
  `card_function_tags`, mas o optimize/quality gate pode ignorar esse dado se
  `semantic_tags_v2` estiver ausente/abaixo de confianca e recair em heuristica.
- **O que valida:** teste end-to-end com carta contendo `functional_tags`
  persistido e `semantic_tags_v2` ausente provando que deck analysis e optimize
  classificam o mesmo papel.
- **O que falsifica:** `loadOptimizeDeckContext` e as queries de additions
  passarem a carregar `functional_tags`, e `classifyOptimizationFunctionalRole`
  aplicar a mesma prioridade documentada: `functional_tags` persistidos,
  depois `semantic_tags_v2`, depois heuristica por oracle/tipo/custo.
- **Correcao recomendada:** criar um adapter unico de role funcional que aceite
  `functional_tags`, `semantic_tags_v2`, `oracle_text`, `type_line`,
  `mana_cost` e `cmc`, e usar esse adapter em deck analysis, quality gate,
  validator e candidate quality.

#### P1 — `semantic_tags_v2` multi-tag e colapsado em um unico papel no optimize

- **Fluxo:** `classifyOptimizationFunctionalRole` e diagnostico v2 do optimize.
- **Evidencia:**
  - `server/lib/ai/optimization_functional_roles.dart:127`-`:180` escolhe uma
    unica entrada de maior `role_confidence` e retorna o primeiro papel conforme
    ordem fixa: `board_wipe`, `draw`, `removal`, `ramp`, `tutor`, `protection`,
    `recursion`, `wincon`, `combo_piece`, e so depois flags `engine`, `payoff`,
    `enabler`.
  - `server/lib/ai/optimization_functional_roles.dart:292`-`:323` calcula
    `role_delta` usando somente esse papel unico para cada remocao/adicao.
  - `server/lib/ai/candidate_quality_data_support.dart:290`-`:309` usa outro
    mapa de colapso (`drain -> wincon`, `lifegain -> protection`,
    `exile_value -> draw`, `token_maker -> token`, etc.), criando outro eixo de
    interpretacao para o mesmo conjunto de tags.
- **Classificacao:** **Risk / semantic drift**.
- **Por que importa:** uma carta com tags `draw + engine`, `combo_piece +
  enabler`, ou `aristocrat_payoff + drain + payoff` pode preservar uma funcao
  importante, mas o optimize so enxerga o primeiro papel escolhido pela ordem
  local. Isso reduz a fidelidade do validator e da decisao `role_delta`.
- **O que valida:** testes com `semantic_tags_v2.tags` contendo multiplos papeis
  que exercitem validator, quality gate e candidate quality, verificando que
  papeis secundarios relevantes nao somem.
- **O que falsifica:** `role_delta` passar a operar sobre conjunto de roles por
  carta, com roles criticos e secundarios ponderados, e candidate quality usar o
  mesmo adapter.
- **Correcao recomendada:** substituir retorno escalar por `Set<String>`/objeto
  de roles preservados, mantendo um `primary_role` apenas para compatibilidade
  de resposta.

#### P2 — Rotas de recomendacao ainda retornam nomes fixos por metrica simples

- **Fluxos:** `/decks/:id/recommendations` e `/ai/weakness-analysis`.
- **Evidencia:**
  - `server/routes/decks/[id]/recommendations/index.dart:262`-`:268` recomenda
    `Command Tower` quando `landCount < 34`, sem passar por busca semantica de
    terrenos/fixing.
  - A mesma rota busca categorias por `oraclePatterns` em `:244`-`:253` e
    staples por raridade em `:408`-`:438`; isso e melhor que lista fixa, mas
    ainda nao usa `semantic_tags_v2`/`card_function_tags`.
  - `server/routes/ai/weakness-analysis/index.dart:206`-`:285` retorna listas
    fixas de nomes para ramp, draw, removal, wipes e protecao; `:345`-`:358`
    tambem recomenda texto com `Swords to Plowshares`.
- **Classificacao:** **Risk** para logica runtime; nao e fixture nem doc.
- **Por que importa:** utilidade e inferida de buckets agregados e nomes
  genericos, sem garantir que a carta recomendada respeita identidade de cor,
  budget/bracket, legalidade, tema, cartas ja presentes ou dados persistidos.
- **O que valida:** testes de recomendacao com decks de identidades diferentes
  provando que sugestoes fixas off-color/fora de bracket nao aparecem.
- **O que falsifica:** trocar listas fixas por consulta a `cards` +
  `card_legalities` + `card_function_tags`/`semantic_tags_v2`/`card_role_scores`
  com filtros de identidade, budget, bracket e exclusao de cartas ja presentes.
- **Correcao recomendada:** manter mensagens genericas, mas gerar nomes por
  consulta semantica versionada em vez de literals inline.

### Candidatos permitidos ou intencionais

- **Allowed — UI/example/route comment:** exemplos como `1 Sol Ring` em
  `app/lib/features/decks/screens/deck_import_screen.dart:383`-`:392` e
  `:591`-`:592`, comentarios de `server/routes/cards/resolve/batch/index.dart`
  e mensagens de importacao sao exemplos de formato, nao decisao funcional.
- **Allowed — card search suggestion UI:** `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:39`-`:44`
  e lista de busca rapida; nao participa de optimize, validator ou analise.
- **Allowed — prompt example, with caution:** `server/lib/ai/prompt.md` e
  `server/lib/ai/prompt_complete.md` contem nomes como exemplos para o modelo.
  Eles influenciam prompt, mas nao sao gate deterministico; devem continuar fora
  da fonte de verdade de classificacao.
- **Allowed — localized alias:** `server/lib/import_card_lookup_service.dart:26`
  mapeia alias PT para `Swords to Plowshares`; isso e resolucao de nome
  localizado, nao julgamento de utilidade.
- **Intentional exception / seed data:** `server/lib/ai/commander_reference_profile_support.dart:153`-`:171`
  e `server/lib/ai/commander_reference_generate_fallback_support.dart:182`-`:245`
  embutem pacotes Lorehold/fallback. Ha cobertura relacionada em
  `server/test/commander_reference_card_stats_support_test.dart`, entao isto se
  comporta como seed/corpus de perfil Commander, nao como regra generica de
  optimize. Ainda assim, se esse fallback crescer, deve virar corpus/policy
  versionada para manter fonte, bracket e motivo auditaveis.

### Resumo da checagem pedida

- `semantic_tags_v2` e usado antes de heuristica no optimize quando esta
  presente (`classifyOptimizationFunctionalRole`), mas `functional_tags`
  persistidos nao entram no optimize.
- `summarizeFunctionalTagsForDeck` prefere `functional_tags` persistidos e
  usa heuristica depois; isso diverge do optimize.
- Candidate quality reaproveita `inferFunctionalCardTags`, mas adiciona aliases,
  `premium` e `highPowerNames` por nome, criando drift de role/bracket.
- Ha utilidade ainda name-based em classificadores, score de candidatos, filler
  do optimize e rotas de recomendacao/weakness.

## Rodada focada: Classes not used

Escopo desta rodada: somente classes aparentemente sem uso em runtime/producao.
Nao foi executada auditoria ampla de funcoes nao chamadas, imports/ciclos,
tabelas PostgreSQL, duplicacao geral ou coerencia entre camadas.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativo.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada.
- `git rev-parse --short HEAD`: `f0eaf872`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados: 0.

Limitacao atual: o auditor estrutural marca como "classe potencialmente nao
usada" quando uma classe nao aparece em outro arquivo. Para Flutter e Dart isso
gera muitos falsos positivos esperados: `State` privado, widgets auxiliares,
DTOs retornados por metodos do mesmo arquivo e classes usadas por inferencia de
tipo. A triagem abaixo manteve apenas classes cujo nome nao aparece em runtime
fora da propria declaracao/constructor, ou aparece somente em testes.

Como `rg` nao esta instalado neste shell local, a validacao usou buscas focadas
com `grep -RIn --include='*.dart'`.

### Achados confirmados

#### P1 — `LifeCounterScreen` legado segue em `app/lib`, mas a rota de producao usa `LotusLifeCounterScreen`

- **Classe:** `LifeCounterScreen`.
- **Definicao:** `app/lib/features/home/life_counter_screen.dart:61`.
- **Rota ativa:** `app/lib/main.dart:283` constroi
  `LotusLifeCounterScreen()` para a rota do life counter; `app/lib/main.dart:54`
  importa `features/home/lotus_life_counter_screen.dart`.
- **Busca de uso em producao:** `grep -RIn --include='*.dart' '\bLifeCounterScreen\b' app/lib`
  encontrou apenas a propria declaracao, construtor e `State` em
  `app/lib/features/home/life_counter_screen.dart:61`-`:77`.
- **Uso fora de producao:** a classe ainda aparece em
  `app/test/features/home/life_counter_screen_test.dart:36` e
  `app/test/features/home/life_counter_clone_proof_test.dart:277`.
- **Por que parece nao usada:** nao ha import/chamada de
  `life_counter_screen.dart` em `app/lib`; o fluxo app-facing usa a tela Lotus.
- **Risco:** `life_counter_screen.dart` tem cerca de 6400 linhas e continua
  citado como gargalo/risco visual, mas pode estar funcionando apenas como
  legado/test harness. Isso infla o mapa tecnico e cria ambiguidade sobre qual
  superficie e produto ativo.
- **O que valida:** remover a classe/arquivo e migrar ou remover os testes
  dependentes, ou documentar explicitamente que e fixture/harness legado fora do
  runtime.
- **O que falsifica:** algum entrypoint, flag de runtime ou fallback em
  `app/lib` passar a instanciar `LifeCounterScreen`.

#### P2 — `DeckCard` e testado, mas nao e usado na listagem real de decks

- **Classe:** `DeckCard`.
- **Definicao:** `app/lib/features/decks/widgets/deck_card.dart:17`.
- **Busca de uso em producao:** `grep -RIn --include='*.dart' '\bDeckCard\b' app/lib server/lib server/routes`
  encontrou somente `app/lib/features/decks/widgets/deck_card.dart:17` e o
  construtor em `app/lib/features/decks/widgets/deck_card.dart:22`.
- **Uso fora de producao:** `app/test/features/decks/widgets/deck_card_test.dart:9`
  e `app/test/features/decks/widgets/deck_card_overflow_test.dart:47`.
- **Comparacao com tela ativa:** a listagem em
  `app/lib/features/decks/screens/deck_list_screen.dart:606` usa
  `_DeckSpotlightCard`, e `app/lib/features/decks/screens/deck_list_screen.dart:626`
  usa `_DeckGalleryCard`; o arquivo define essas classes em `:989` e `:1401`.
- **Por que parece nao usada:** o widget publico antigo nao aparece em runtime,
  mas ainda possui testes dedicados, que podem dar falsa confianca sobre a
  listagem real.
- **O que valida:** apagar `DeckCard` e seus testes, ou religar a listagem real
  a esse widget se ele ainda for o contrato pretendido.
- **O que falsifica:** algum import de `deck_card.dart` em `app/lib` ou uso
  direto de `DeckCard(...)` em tela ativa.

#### P2 — `DeckProgressChip` nao tem nenhum chamador

- **Classe:** `DeckProgressChip`.
- **Definicao:** `app/lib/features/decks/widgets/deck_progress_indicator.dart:286`.
- **Busca de uso:** `grep -RIn --include='*.dart' '\bDeckProgressChip\b' .`
  encontrou apenas a declaracao em `:286` e o construtor em `:292`.
- **Classe relacionada ativa:** o mesmo arquivo e usado por
  `DeckProgressIndicator`, importado em
  `app/lib/features/decks/screens/deck_details_screen.dart:26` e
  `app/lib/features/decks/widgets/deck_details_overview_tab.dart:10`.
- **Por que parece nao usada:** `DeckProgressChip` nao e instanciado nem em
  producao nem em testes.
- **O que valida:** remover o chip ou adicionar uso real/teste se houver
  necessidade de um componente compacto.
- **O que falsifica:** chamada direta a `DeckProgressChip(...)` em `app/lib` ou
  testes que travem seu contrato como componente planejado.

#### P2 — `LotusPresentationMode` parece utilitario morto

- **Classe:** `LotusPresentationMode`.
- **Definicao:** `app/lib/features/home/lotus/lotus_presentation_mode.dart:4`.
- **Busca de uso:** `grep -RIn --include='*.dart' '\bLotusPresentationMode\b' app/lib app/test app/integration_test`
  encontrou apenas `app/lib/features/home/lotus/lotus_presentation_mode.dart:4`
  e o construtor privado em `:5`.
- **Busca por import:** `grep -RIn --include='*.dart' 'lotus_presentation_mode.dart' app/lib app/test app/integration_test`
  nao retornou ocorrencias.
- **Por que parece nao usada:** nenhum runtime, teste ou integration test chama
  `enter()`/`exit()`, apesar de a classe alterar orientacao e overlays do
  sistema.
- **O que valida:** remover o arquivo ou conectar `enter()`/`exit()` ao ciclo da
  `LotusLifeCounterScreen` com teste de contrato.
- **O que falsifica:** import real de `lotus_presentation_mode.dart` e chamada
  de `LotusPresentationMode.enter/exit`.

### Suspeitas revalidadas e descartadas nesta rodada

- A lista bruta de classes sem referencia cross-file contem muitos falsos
  positivos em widgets privados e classes `State`, por exemplo
  `_DeckDetailsScreenState`, `_HomeScreenState`, `_TradeDetailScreenState` e
  outros auxiliares locais; esses nao foram reportados.
- Classes publicas usadas apenas dentro do mesmo arquivo como DTO/resultado de
  helper tambem nao foram classificadas como defeito sem evidencia adicional.
  Exemplos descartados: `ManaSymbol`, `FallbackManaSymbol`,
  `FallbackColorPip`, `OptimizeProgressDialog` e os DTOs de
  `deck_optimize_flow_support.dart`.
- Nenhuma classe backend foi confirmada como realmente sem uso nesta rodada; a
  maioria dos candidatos backend sem referencia cross-file e DTO interno,
  retorno inferido de service, classe usada por `server/bin`, ou helper
  instanciado dentro do mesmo modulo.

## Rodada focada anterior: Coerencia entre `server/lib` <-> `server/routes` <-> `app/lib`

## Rodada focada: Coerencia entre `server/lib` <-> `server/routes` <-> `app/lib`

Escopo desta rodada: somente coerencia de contratos, ownership e consumo entre
helpers de `server/lib`, handlers de `server/routes` e consumidores em
`app/lib`. Nao foi executada auditoria ampla de classes sem uso, funcoes nao
chamadas, imports/ciclos, tabelas PostgreSQL ou duplicacao geral.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativo.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada.
- `git rev-parse --short HEAD`: `d2b189fc`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados: 0.

Limitacao atual: o auditor estrutural continua util para mapa bruto de classes,
imports, tabelas e nomes duplicados, mas nao entende contratos app-facing nem
propagacao de ownership entre provider, rota e helper. Os achados abaixo foram
produzidos por leitura direta focada usando `grep`, porque `rg` nao esta
instalado neste shell local.

### Achados confirmados

#### P1 — `POST /ai/optimize` ainda perde ownership ao atravessar `routes -> lib`

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:10`-`:23`
  monta o payload com `deck_id`, `archetype`, `bracket`, `keep_theme` e
  `intensity`; `app/lib/features/decks/providers/deck_provider_support_ai.dart:56`
  envia `POST /ai/optimize`.
- **Handler:** `server/routes/ai/optimize/index.dart:401`-`:405` le
  `userId` de forma tolerante, mas `server/routes/ai/optimize/index.dart:549`-`:558`
  chama `optimize_request.loadOptimizeDeckContext(...)` sem passar `userId`.
- **Helper:** `server/lib/ai/optimize_request_support.dart:53`-`:62` nao recebe
  `userId`; a query do deck em
  `server/lib/ai/optimize_request_support.dart:63`-`:73` usa
  `SELECT name, format FROM decks WHERE id = @id`, e as queries de cartas em
  `server/lib/ai/optimize_request_support.dart:87`-`:137` usam apenas
  `WHERE dc.deck_id = @id`.
- **Comparacao segura:** `server/routes/decks/[id]/index.dart:288`-`:317`
  usa `FROM decks WHERE id = @deckId AND user_id = @userId`; `server/routes/decks/[id]/analysis/index.dart:16`-`:25`
  tambem escopa por `deckId + userId` antes de ler analise.
- **Por que e incoerente:** o app trata optimize como acao sobre deck privado
  do usuario autenticado, mas a fronteira de helper carrega qualquer deck por
  UUID.
- **O que valida:** `loadOptimizeDeckContext` receber `userId`, consultar o deck
  por `id + user_id` ou por regra publica explicita, e testes owner vs non-owner
  para caminhos sync e async.
- **O que falsifica:** contrato documentado e testado provando que optimize
  aceita deck publico/alheio por design sem expor composicao privada.

#### P1 — `POST /ai/archetypes` e consumido pelo app, mas carrega deck/cartas sem owner

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_mutation.dart:168`-`:173`
  chama `POST /ai/archetypes` com `{deck_id: deckId}`.
- **Handler:** `server/routes/ai/archetypes/index.dart:27`-`:35` le o
  `deck_id` e o `Pool`, mas nao le `context.read<String>()`; a query do deck em
  `server/routes/ai/archetypes/index.dart:39`-`:42` usa
  `SELECT name, format FROM decks WHERE id = @id`, e a query de cartas em
  `server/routes/ai/archetypes/index.dart:53`-`:62` usa `WHERE dc.deck_id = @id`.
- **Middleware:** `server/routes/ai/_middleware.dart:16`-`:20` aplica auth,
  limite de plano e rate limit, entao a rota e autenticada/custosa, mas o
  handler nao usa o usuario autenticado para escopar o deck.
- **Por que e incoerente:** as opcoes de arquétipo derivam da lista real do deck
  privado, mas qualquer UUID existente pode ser analisado por um usuario
  autenticado.
- **O que valida:** escopar `POST /ai/archetypes` por `deck_id + user_id` antes
  de montar prompt/cache/reference profile e adicionar teste non-owner.
- **O que falsifica:** contrato explicito para analisar apenas decks publicos ou
  compartilhados, com filtro `is_public=true` ou regra de acesso equivalente.

#### P1 — Polling de optimize aceita job com `user_id = NULL`

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:74`-`:87`
  trata `202` como job async e
  `app/lib/features/decks/providers/deck_provider_support_ai.dart:190`-`:194`
  faz polling em `/ai/optimize/jobs/$jobId`.
- **Criacao:** `server/routes/ai/optimize/index.dart:459`-`:464` passa o
  `userId` para `OptimizeJobStore.create`, mas esse `userId` pode ser `null`
  porque foi lido de forma tolerante em `server/routes/ai/optimize/index.dart:401`-`:405`.
- **Store:** `server/lib/ai/optimize_job.dart:50`-`:64` persiste `user_id` com
  parametro nullable.
- **Polling:** `server/routes/ai/optimize/jobs/[id].dart:26`-`:28` le o usuario
  autenticado e carrega o job, mas `server/routes/ai/optimize/jobs/[id].dart:39`-`:47`
  bloqueia apenas quando `job.userId != null && job.userId != userId`. Jobs
  nulos ficam legiveis para qualquer usuario com o `job_id`.
- **Por que e incoerente:** o app nao tem conceito de job publico, e a rota fica
  sob `/ai` autenticado.
- **O que valida:** exigir `userId` nao nulo para jobs app-facing e retornar 404
  quando `job.userId == null`, salvo uma rota interna separada e documentada.
- **O que falsifica:** teste provando que nenhum job app-facing pode ser criado
  sem usuario e que o estado nulo tem politica segura.

#### P2 — Endpoints experimentais de deck/AI continuam sem ownership antes de promocao app-facing

- **Endpoints:** `GET /decks/:id/simulate`, `POST /decks/:id/recommendations`,
  `POST /ai/simulate-matchup`, `POST /ai/weakness-analysis`.
- **Evidencia de rotas:**
  - `server/routes/decks/[id]/simulate/index.dart:13`-`:26` le cartas por
    `WHERE dc.deck_id = @deckId`, sem ler `context.read<String>()`.
  - `server/routes/decks/[id]/recommendations/index.dart:23`-`:27` consulta
    `SELECT name, format, description FROM decks WHERE id = @deckId`, e
    `server/routes/decks/[id]/recommendations/index.dart:39`-`:58` le cartas
    por `dc.deck_id = @deckId`.
  - `server/routes/ai/simulate-matchup/index.dart:23`-`:38` le
    `my_deck_id`/`opponent_deck_id` e chama `_getDeckData`; essa funcao em
    `server/routes/ai/simulate-matchup/index.dart:76`-`:103` usa
    `SELECT id, name, format FROM decks WHERE id = @id` e cartas por
    `dc.deck_id = @id`.
  - `server/routes/ai/weakness-analysis/index.dart:17`-`:31` aceita `deck_id`
    e consulta `SELECT name, format FROM decks WHERE id = @id`; as cartas sao
    lidas em `server/routes/ai/weakness-analysis/index.dart:41`-`:60` por
    `dc.deck_id = @id`.
- **Evidencia app/contrato:** busca focada em `app/lib` nao encontrou chamadas
  para esses endpoints; `server/doc/API_CONTRACTS_AND_DATA_MAP.md:152`-`:153`
  e `:285`-`:286` marca os consumidores como `not proven`/experimentais.
- **Por que e incoerente:** as rotas vivem em namespaces autenticados
  (`server/routes/decks/_middleware.dart:7`-`:8` e
  `server/routes/ai/_middleware.dart:16`-`:20`), mas nao aplicam o padrao de
  owner dos endpoints estaveis de deck.
- **O que valida:** antes de expor no app, escopar `deck_id`/`my_deck_id` por
  `user_id`, definir regra separada para oponente publico/meta deck e adicionar
  teste non-owner.
- **O que falsifica:** decisao explicita de manter esses endpoints internos ou
  remove-los da superficie app-facing, com contrato atualizado e sem chamada em
  `app/lib`.

#### P2 — `/community/decks/following` segue como branch magico em rota dinamica

- **Contrato app:** `app/lib/features/social/providers/social_provider.dart:550`-`:584`
  chama `/community/decks/following?page=...&limit=20` e registra o endpoint
  como `/community/decks/following`.
- **Handler:** `server/routes/community/decks/[id].dart:10`-`:12` trata
  `id == 'following'` como caso especial e desvia para `_getFollowingFeed`.
- **Implementacao:** `server/routes/community/decks/[id].dart:294`-`:410`
  implementa o feed dentro do arquivo de detalhe dinamico; `find
  server/routes/community/decks -maxdepth 3 -type f` mostrou apenas
  `index.dart` e `[id].dart`, sem `following/index.dart`.
- **Contrato documentado:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md:77`
  ja registra o risco de manutencao e recomenda rota dedicada.
- **Por que e incoerente:** a URI app-facing representa uma colecao/feed, mas o
  arquivo fisico e a dispatch rule tratam `following` como valor magico de
  `:id`.
- **O que valida:** criar `server/routes/community/decks/following/index.dart`
  ou teste de contrato explicito cobrindo `GET /community/decks/following` e
  `GET /community/decks/:id`.
- **O que falsifica:** decisao documentada de manter o branch por compatibilidade
  com teste que trave o comportamento.

### Suspeitas revalidadas e descartadas nesta rodada

- `POST /ai/rebuild` nao foi reaberto: `server/routes/ai/rebuild/index.dart:16`
  le `userId`, e o carregamento inicial em `server/routes/ai/rebuild/index.dart:70`
  parte de query com deck/user antes de carregar cartas.
- `GET /decks/:id/analysis` nao foi reaberto: `server/routes/decks/[id]/analysis/index.dart:18`-`:25`
  le `userId` e filtra `decks` por `id + user_id` antes de consultar cartas.
- A afirmacao historica de que `POST /ai/optimize`, `GET /ai/optimize/jobs/:id`
  e `POST /ai/archetypes` estavam saneados em `origin/master@65f30387` nao foi
  sustentada pelo checkout auditado (`d2b189fc`); os documentos de plano/mapa
  foram ajustados para refletir a evidencia atual.

## Rodada focada anterior: Duplicated or similar logic

## Rodada focada: Duplicated or similar logic

Escopo desta rodada: somente logica duplicada ou similar. Nao foi executada
auditoria ampla de classes sem uso, funcoes nao chamadas, imports/ciclos,
tabelas PostgreSQL ou coerencia geral entre camadas.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativo.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local depois da correcao do root/path resolver.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados: 0.

Limitacao atual: para duplicacao, o auditor ainda usa colisao de nomes de
funcoes como sinal bruto. A lista inclui falsos positivos esperados (`toString`,
`print`, callbacks chamados `Function`, wrappers finos de rota e helpers locais
sem semantica compartilhada). Os achados abaixo foram mantidos apenas quando a
leitura direta confirmou mesma intencao de dominio ou corpo equivalente.

### Achados confirmados

#### P1 — Heuristicas semanticas de combo/engine/payoff/enabler/wincon seguem divergindo em dois classificadores

- **Simbolos:** `_looksLikeWincon`, `_looksLikeComboPiece`,
  `_looksLikeEngine`, `_looksLikePayoff`, `_looksLikeEnabler`.
- **Evidencia 1:** `server/lib/ai/functional_card_tags.dart:319`-`:335`
  chama os helpers para tags v1; as definicoes em
  `server/lib/ai/functional_card_tags.dart:859`-`:906` usam `oracle` +
  `normalizedName` e incluem sentinelas por nome como `thassa's oracle`,
  `isochron scepter`, `dramatic reversal`, `blood artist`, `greaves` e
  `boots`.
- **Evidencia 2:** `server/lib/ai/optimization_functional_roles.dart:113`-`:117`
  chama helpers com os mesmos nomes para `classifyOptimizationFunctionalRole`;
  as definicoes em `server/lib/ai/optimization_functional_roles.dart:370`-`:397`
  usam apenas `oracle` e padroes diferentes.
- **Por que parece duplicado/similar:** ambos classificam os mesmos papeis
  semanticos de alto nivel, mas mantem heuristicas independentes.
- **Risco:** a analise funcional pode explicar uma carta como `combo_piece`,
  `engine`, `payoff`, `enabler` ou `wincon`, enquanto o pipeline de optimize
  atribui outro papel para a mesma carta.
- **O que valida:** extrair uma fonte compartilhada de sinais semanticos ou
  adicionar testes cruzados para cartas sentinela.
- **O que falsifica:** contrato/testes demonstrando que os classificadores
  divergem por design e que essa divergencia e esperada nos fluxos de analise e
  optimize.

#### P2 — `getMainType` e `calculateCmc` duplicam estatisticas de deck privado e publico

- **Simbolos:** `getMainType`, `calculateCmc`.
- **Evidencia 1:** `server/routes/decks/[id]/index.dart:405`-`:435` define
  `getMainType` e `calculateCmc` na rota privada; os helpers alimentam
  `groupedMainBoard` e `manaCurve` em `server/routes/decks/[id]/index.dart:452`
  e `:464`.
- **Evidencia 2:** `server/routes/community/decks/[id].dart:91`-`:117` define
  os mesmos helpers na rota publica; o uso equivalente aparece em
  `server/routes/community/decks/[id].dart:133` e `:141`.
- **Por que parece duplicado/similar:** as duas rotas constroem tipo principal,
  curva de mana e distribuicao de cores a partir de `cardsList` com regras quase
  iguais.
- **Risco:** um ajuste de regra de CMC/tipo pode chegar a uma rota e nao a outra,
  fazendo o mesmo deck exibir estatisticas diferentes para dono e comunidade.
- **O que valida:** helper compartilhado de estatisticas de deck, com fixture
  comum para resposta privada e publica.
- **O que falsifica:** testes de contrato provando que as respostas devem
  divergir e que ambas as implementacoes locais estao travadas por fixtures.

#### P2 — `_isBasicLandName` ainda tem variantes de normalizacao no backend

- **Simbolo:** `_isBasicLandName` / `isBasicLandName`.
- **Evidencia 1:** `server/lib/ai/optimize_runtime_support.dart:285` expoe
  `isBasicLandName`; a regra privada em
  `server/lib/ai/optimize_runtime_support.dart:4184`-`:4197` aceita nomes
  exatos e snow lands com hifen.
- **Evidencia 2:** `server/lib/generated_deck_validation_service.dart:752`-`:763`
  aceita snow lands por `startsWith('snow-covered ...')`.
- **Evidencia 3:** `server/lib/meta/meta_deck_reference_support.dart:890`-`:903`
  aceita snow lands com espaco (`snow covered plains`), sem hifen.
- **Evidencia 4:** `server/routes/ai/commander-reference/index.dart:621`-`:628`
  reconhece apenas as seis basics nao snow.
- **Por que parece duplicado/similar:** todos os trechos respondem a mesma
  pergunta de dominio ("este nome e terreno basico?"), mas normalizam casos
  diferentes.
- **Risco:** validacao, optimize, referencia de meta e commander-reference podem
  discordar sobre snow lands ou nomes normalizados.
- **O que valida:** centralizar a regra em utilitario de dominio e adicionar
  testes para `Wastes`, snow lands com hifen e variantes normalizadas.
- **O que falsifica:** testes por contexto mostrando que cada variante e
  exigida por contrato diferente.

#### P2 — Boilerplate de `request_id` e `invalid_payload` segue repetido em rotas sociais

- **Simbolos:** `_requestId`, `_logInvalidPayload`.
- **Evidencia:** `_requestId` tem corpo equivalente em
  `server/routes/trades/index.dart:330`-`:336`,
  `server/routes/trades/[id]/messages.dart:228`-`:234`,
  `server/routes/conversations/[id]/messages.dart:247`-`:253`,
  `server/routes/trades/[id]/respond.dart:154`-`:160`,
  `server/routes/trades/[id]/status.dart:260`-`:266` e
  `server/routes/users/[id]/follow/index.dart:97`-`:103`.
- **Evidencia adicional:** `_logInvalidPayload` repete leitura tolerante de
  usuario, prefixo `[social_write] invalid_payload`, `request_id` e ids de
  recurso em `server/routes/trades/index.dart:338`-`:352`,
  `server/routes/trades/[id]/messages.dart:236`-`:252`,
  `server/routes/conversations/[id]/messages.dart:255`-`:271`,
  `server/routes/trades/[id]/respond.dart:162`-`:178` e
  `server/routes/trades/[id]/status.dart:268`-`:284`.
- **Por que parece duplicado/similar:** a responsabilidade e identica, variando
  apenas endpoint e campo extra.
- **Risco:** formato de log, fallback de `x-request-id` ou sanitizacao de usuario
  podem divergir entre trades/conversas/follow.
- **O que valida:** helper compartilhado de social write logging aceitando
  endpoint e campos extras.
- **O que falsifica:** decisao explicita de manter logs por rota, com teste que
  preserve formato equivalente.

#### P2 — SQL de trust em trades e duplicado entre lista e detalhe

- **Simbolos:** `_trustStatsSql`, `_responseTimeSql`, `_shippingTimeSql`,
  `_buildTrustInsight`.
- **Evidencia 1:** `server/routes/trades/index.dart:557`-`:601` define os tres
  SQL snippets para estatisticas, tempo de resposta e tempo de envio usados na
  listagem de trades.
- **Evidencia 2:** `server/routes/trades/[id]/index.dart:260`-`:304` define os
  mesmos tres snippets para o detalhe de trade.
- **Por que parece duplicado/similar:** listagem e detalhe calculam exatamente o
  mesmo bloco de trust para sender/receiver via `LEFT JOIN LATERAL`.
- **Risco:** alteracoes futuras em trust score, status considerados ou janela de
  tempo podem ser aplicadas em uma rota e esquecidas na outra.
- **O que valida:** mover snippets e builder de trust para helper compartilhado
  de trades, com teste para list/detail.
- **O que falsifica:** diferenca intencional documentada entre trust de lista e
  trust de detalhe.

#### P3 — Normalizacao de `condition` de carta esta duplicada nas mutacoes de deck

- **Simbolo:** `_validateCondition`.
- **Evidencia 1:** `server/routes/decks/[id]/cards/index.dart:397`-`:403`
  normaliza `condition` para `NM`, `LP`, `MP`, `HP` ou `DMG`, com fallback
  `NM`.
- **Evidencia 2:** `server/routes/decks/[id]/cards/set/index.dart:243`-`:248`
  repete a mesma regra para ajuste de quantidade/condicao.
- **Por que parece duplicado/similar:** ambas as mutacoes de deck aceitam o
  mesmo campo app-facing e aplicam a mesma allow-list.
- **Risco:** se a lista de condicoes mudar ou ganhar mapeamento mais rico, uma
  rota pode aceitar valores que a outra normaliza para `NM`.
- **O que valida:** extrair `normalizeCardCondition` compartilhado e testar as
  duas rotas ou o helper.
- **O que falsifica:** contrato documentado dizendo que as rotas podem normalizar
  condicao de formas diferentes.

### Suspeitas revalidadas e descartadas nesta rodada

- A duplicacao direta entre `server/routes/ai/optimize/index.dart` e
  `server/lib/ai/optimize_runtime_support.dart` para
  `matchesFunctionalNeed`, `scoreOptimizeReplacementCandidate`,
  `shouldRetryOptimizeWithAiFallback`,
  `computeOptimizeStructuralRecoverySwapTarget` e
  `isOptimizeStructuralRecoveryScenario` segue descartada: a rota possui
  wrappers finos que delegam para `optimize_support` em
  `server/routes/ai/optimize/index.dart:56`-`:132`.
- `resolveOptimizeArchetype` ainda e similar, mas o duplicado real fica entre
  `server/lib/ai/optimize_runtime_support.dart:3369`-`:3389` e
  `server/lib/ai/deck_state_analysis.dart:573`-`:584`; o wrapper da rota apenas
  delega.
- Colisoes do auditor como `toString`, `print`, `Function`, `add`, `set` e
  `_toInt` nao foram promovidas a achados sem prova de mesma regra de dominio.

## Rodada focada anterior: Correcao do auditor estrutural

Escopo desta rodada: corrigir o proprio `structure_auditor.py` antes de usar a
contagem de imports quebrados como evidência de produto.

### Resultado

- `docs/hermes-analysis/scripts/structure_auditor.py` agora resolve o root do
  repo por `MTGIA_REPO_ROOT` ou `Path.cwd()`, evitando o caminho fixo
  `/opt/data/workspace/mtgia` em execucoes locais.
- Imports relativos agora sao resolvidos a partir do diretorio do arquivo Dart
  que contem o import, alinhado ao comportamento do analyzer.
- Imports `package:server/...`, `package:manaloom/...` e o alias historico
  `package:ai/...` sao resolvidos apenas quando pertencem ao repositorio;
  pacotes externos continuam fora do escopo do auditor estrutural.
- O script preserva rodadas manuais do `STRUCTURE_AUDIT.md` e substitui somente
  o bloco gerado automaticamente.
- Nova execucao: `Imports quebrados: 0`.

### Validacao

- `MTGIA_REPO_ROOT=/Users/desenvolvimentomobile/.manaloom-agents/mtgia python3 docs/hermes-analysis/scripts/structure_auditor.py`
- `python3 -m py_compile docs/hermes-analysis/scripts/structure_auditor.py`

### Impacto no backlog

O P0 de falso-positivo em massa de imports fica **resolvido para a ferramenta**.
As rodadas historicas abaixo foram preservadas como contexto, mas as referencias
antigas a 178 imports quebrados nao devem mais ser usadas como bug real.

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
- **Leitura/consumo encontrado:** a busca por leituras `SELECT/JOIN` de
  `commander_reference_decks` e `commander_reference_deck_cards` em
  `server/routes`, `server/lib`, `server/bin` e `app/` nao encontrou
  consumidores dessas tabelas raw. O caminho de produto le o agregado
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
