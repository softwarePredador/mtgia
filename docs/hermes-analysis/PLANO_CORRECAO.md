# Plano de Correcao — Audit de Estrutura

> Data: 2026-05-29 07:04 UTC
> Escopo: documentar problemas estruturais detectados em `STRUCTURE_AUDIT.md` sem alterar codigo de produto.

## Resumo executivo

O auditor gerava muito ruído por inferir imports relativos a partir do root do repositório, então os **178 "imports quebrados" não podiam ser tratados como defeitos reais** sem revalidação por `dart analyze` ou por resolução relativa ao diretório do arquivo Dart. Esse P0 foi corrigido em `docs/hermes-analysis/scripts/structure_auditor.py`; a nova execução reporta `Imports quebrados: 0`. Ainda assim, as rodadas focadas revelaram frentes prioritárias de organização:

1. **P0 — Ferramenta de auditoria com falso-positivo em massa**: **RESOLVIDO na ferramenta**. Manter como lição operacional: evidência do auditor deve ser confrontada com analyzer quando apontar falhas estruturais.
2. **P1 — Concentradores de complexidade muito grandes**: `server/lib/ai/optimize_runtime_support.dart` (4197 linhas) e `server/routes/ai/optimize/index.dart` (3495 linhas) seguem como gargalos de manutenção.
3. **P1 — Duplicação de helpers e lógica espalhada**: múltiplas funções com mesmo nome e mesma intenção aparecem em módulos de IA, meta e rotas HTTP, aumentando risco de drift.
4. **P1 — Entry point local quebrado**: `server/bin/local_test_server.dart` depende de `../.dart_frog/server.dart`, inexistente no checkout atual, e faz `dart analyze` do backend falhar.
5. **P1 — Ownership em rotas deck/AI**: aberto no checkout auditado (`codex/hermes-analysis-docs@d2b189fc`) para `POST /ai/optimize`, `GET /ai/optimize/jobs/:id` e `POST /ai/archetypes`; rotas experimentais seguem bloqueadas para promocao sem contrato owner/public/meta.
6. **P1 — Politicas por nome / semantica de cartas**: reaberto no checkout local `7014a2cc`. `commander_fallback_policy.dart` nao existe nesta branch, e ainda ha excecoes por nome em `functional_card_tags.dart`, `candidate_quality_data_support.dart`, `optimize_runtime_support.dart` e rotas de recomendacao.
7. **P2/P3 — Tabelas PostgreSQL write-only ou parcialmente consumidas**: `deck_matchups` e `deck_weakness_reports` recebem persistencia, mas nao possuem leitura/uso confirmado fora da chamada que gerou o dado. `ml_prompt_feedback` tem helper de insert sem chamador e apenas contador operacional. `commander_reference_decks`/`commander_reference_deck_cards` sao persistidas como raw corpus, mas o produto le somente o agregado `commander_reference_deck_analysis`.
8. **P1/P2 — Classes app sem uso de runtime confirmado**: rodada focada de
   2026-05-29 confirmou `LifeCounterScreen` legado sem chamada em `app/lib`,
   `DeckCard` testado mas fora da listagem real, `DeckProgressChip` sem
   chamador e `LotusPresentationMode` sem import.
9. **P1 — Drift entre deck analysis e optimize**: deck analysis prefere
   `card_function_tags`, mas optimize/validator/quality gate carregam apenas
   `semantic_tags_v2` e heuristica; alem disso, `semantic_tags_v2` multi-tag e
   colapsado em um unico role.
10. **P1/P2 — Funcoes publicas sem chamador runtime**: rodada focada de
    2026-05-29 07:04 UTC confirmou que `sync_cards_utils.dart` e coberto por
    teste, mas nao importado pelo `server/bin/sync_cards.dart`; tambem ha
    wrappers/helpers sem chamador em request trace, Commander Reference,
    PerformanceService, MTGTop8 e candidate quality sample SQL.

## Achados priorizados

### P0 — Corrigir o `structure_auditor.py` antes de usar a contagem de imports quebrados como verdade

**Status 2026-05-28: RESOLVIDO na ferramenta.**

- O auditor agora aceita `MTGIA_REPO_ROOT`/`Path.cwd()` em vez de path fixo do
  container Hermes.
- Imports relativos sao resolvidos a partir do arquivo Dart origem.
- Imports locais `package:server/...`, `package:manaloom/...` e alias historico
  `package:ai/...` sao tratados explicitamente; pacotes externos sao ignorados.
- Nova execucao do auditor: `Imports quebrados: 0`.
- O script preserva as rodadas manuais do `STRUCTURE_AUDIT.md` e substitui
  somente o bloco gerado automaticamente.

Histórico do problema:

- **Evidência**:
  - `STRUCTURE_AUDIT.md` lista imports como "não encontrado" para arquivos que existem, por exemplo:
    - `server/routes/ai/_middleware.dart` → `../../lib/auth_middleware.dart`
    - `server/routes/auth/login.dart` → `../../lib/auth_service.dart`
  - Verificação direta no filesystem confirmou que os alvos existem em `server/lib/`.
- **Impacto**: priorização errada, documentação enganosa e risco de criar refactors desnecessários.
- **Causa provável**: o auditor resolve caminhos relativos de import contra o diretório errado (provavelmente o root do repo, não o diretório do arquivo origem).
- **Ação recomendada**:
  1. manter a resolucao corrigida no script;
  2. separar "imports potencialmente quebrados pelo parser" de "imports inválidos confirmados por analyzer" se o auditor voltar a reportar falhas;
  3. deduplicar ocorrências repetidas no relatório em uma melhoria futura de legibilidade.
- **Validação**:
  - rerodar `python3 docs/hermes-analysis/scripts/structure_auditor.py`;
  - conferir redução drástica dos falsos positivos;
  - confrontar com `dart analyze` do backend.

### P1 — Quebrar os módulos centrais do otimizador em unidades menores
- **Evidência**:
  - `server/lib/ai/optimize_runtime_support.dart`: 4197 linhas
  - `server/routes/ai/optimize/index.dart`: 3495 linhas
  - A rodada focada de duplicacao em 2026-05-28 revalidou que a rota agora possui wrappers finos para helpers como `matchesFunctionalNeed`, `scoreOptimizeReplacementCandidate`, `shouldRetryOptimizeWithAiFallback`, `computeOptimizeStructuralRecoverySwapTarget` e `isOptimizeStructuralRecoveryScenario`, delegando para `optimize_support` em vez de manter corpos duplicados.
  - Ainda ha drift similar em `resolveOptimizeArchetype`: `server/lib/ai/optimize_runtime_support.dart` e `server/lib/ai/deck_state_analysis.dart` resolvem requested/detected archetype com listas genericas diferentes.
- **Impacto**: alta dificuldade de revisão, regressões sutis e risco de drift entre helpers de dominio que parecem responder a mesma pergunta.
- **Ação recomendada**:
  1. definir fronteiras explícitas para seleção de candidatos, archetype resolution, structural recovery e fallback AI;
  2. consolidar regras ainda duplicadas/similares em `server/lib/ai/*_support.dart` com cobertura focada;
  3. deixar a rota `ai/optimize` como orquestração fina.
- **Validação**:
  - `dart analyze` verde;
  - testes de optimize e quality gate verdes;
  - diff estrutural mostrando redução de linhas na rota principal.

### P1 — Consolidar helpers duplicados que indicam drift funcional
- **Evidência**:
  - `_looksLikeComboPiece`, `_looksLikeEnabler`, `_looksLikeEngine`, `_looksLikePayoff`, `_looksLikeWincon` existem tanto em `server/lib/ai/functional_card_tags.dart` quanto em `server/lib/ai/optimization_functional_roles.dart`.
  - `_isBasicLandName` aparece em quatro locais diferentes, com variantes para snow lands: `optimize_runtime_support.dart`, `generated_deck_validation_service.dart`, `meta_deck_reference_support.dart` e `routes/ai/commander-reference/index.dart`.
  - `_requestId` e `_logInvalidPayload` repetem-se em várias rotas de trades/conversations.
  - `calculateCmc` e `getMainType` duplicados em duas rotas de decks/community.
  - `_trustStatsSql`, `_responseTimeSql`, `_shippingTimeSql` e `_buildTrustInsight`
    duplicam o mesmo trust de trades entre listagem e detalhe.
  - `_validateCondition` duplica a allow-list `NM/LP/MP/HP/DMG` em duas rotas
    de mutacao de cartas do deck.
- **Impacto**: mudança semântica em um ponto não propaga automaticamente para os demais; risco de respostas inconsistentes por endpoint/fluxo.
- **Ação recomendada**:
  1. agrupar duplicações por domínio (IA semântica, utilitários HTTP, utilitários de deck);
  2. extrair helpers compartilhados apenas quando a semântica for realmente idêntica;
  3. manter wrappers locais somente se o contexto justificar nomes iguais com comportamento diferente.
- **Validação**:
  - grep/listagem de duplicados reduzida;
  - testes existentes seguem verdes;
  - revisão de imports mostra dependência convergindo para helpers compartilhados.

### P1 — Centralizar as politicas por nome restantes em policy versionada
- **Status em `codex/hermes-analysis-docs@7014a2cc`: REABERTO.** A revalidacao
  local nao encontrou `server/lib/ai/commander_fallback_policy.dart`; o unico
  arquivo `*policy*` em `server/lib` e `server/lib/edh_bracket_policy.dart`.
  Portanto a anotacao historica de resolucao em `origin/master@65f30387` nao
  deve ser aplicada a este checkout.
- **Evidência**:
  - `server/lib/ai/functional_card_tags.dart:220`-`:226` classifica ramp por
    `signet`, `talisman`, `sol ring` e `arcane signet`; `:714`-`:717`,
    `:754`-`:780` e `:859`-`:899` usam nomes conhecidos para protecao,
    aristocrats, wincon, combo, payoff e enabler.
  - `server/lib/ai/candidate_quality_data_support.dart:375`-`:379`,
    `:439`-`:445`, `:472`-`:478`, `:590`-`:605` e `:611`-`:628` repetem
    checks por nome e aplicam `highPowerNames`/`premium` ao bracket/score.
  - `server/lib/ai/optimize_runtime_support.dart:406`-`:454`, `:1296`-`:1345`,
    `:1948`-`:2052`, `:3476`-`:3509` e `:3565`-`:3615` mantem listas fixas de
    terrenos premium, staples, denylist/premium filler e fallbacks universais ou
    contextuais.
  - `server/routes/decks/[id]/recommendations/index.dart:262`-`:268` recomenda
    `Command Tower` diretamente quando `landCount < 34`.
  - `server/routes/ai/weakness-analysis/index.dart:206`-`:285` retorna listas
    fixas de nomes para ramp, draw, removal, wipes e protecao.
- **Impacto**: a maior parte do pipeline semantico ja converge, mas parte da
  decisao de score/bracket/premium ainda depende de listas inline, dificultando
  versao, auditoria e rollout controlado. No checkout local, a divergencia e
  maior que o historico sugeria, porque a policy central citada nao esta
  presente.
- **Ação recomendada**:
  1. criar/restaurar modulo/config/tabela de policy versionada para excecoes de
     nome realmente intencionais;
  2. enriquecer cada entrada com role, bracket, motivo, fonte, confidence e data;
  3. manter `oracle_text`, `type_line`, `mana_cost`, `cmc`,
     `card_function_tags`, `semantic_tags_v2`, legalidade, identidade de cor e
     budget/bracket como sinais primarios antes de qualquer bonus por nome;
  4. remover checks inline dos classificadores puros ou transforma-los em
     backfill de dados semanticos persistidos;
  5. adicionar testes focados para policy, incluindo cartas com texto equivalente
     e nomes diferentes.
- **Validação**:
  - `rg "Sol Ring|Command Tower|Thassa's Oracle|Isochron Scepter|Dramatic Reversal|Blood Artist" server/lib server/routes app/lib`
    nao encontra decisao runtime fora de fixtures, docs, prompts, seed/corpus
    declarado ou policy versionada;
  - testes provam que score/bracket/premium vem da policy e continua respeitando
    legalidade, identidade de cor e bracket.

### P1 — Unificar o adapter semantico usado por deck analysis, optimize e candidate quality

- **Status em `codex/hermes-analysis-docs@7014a2cc`: ABERTO.**
- **Evidência**:
  - `GET /decks/:id/analysis` seleciona `card_function_tags` e
    `semantic_tags_v2` em `server/routes/decks/[id]/analysis/index.dart:80`-`:96`;
    `POST /decks/:id/ai-analysis` faz o mesmo em
    `server/routes/decks/[id]/ai-analysis/index.dart:119`-`:135`.
  - `summarizeFunctionalTagsForDeck` prefere `functional_tags` persistidos e so
    usa heuristica depois em `server/lib/ai/functional_card_tags.dart:432`-`:465`.
  - `loadOptimizeDeckContext` carrega `semantic_tags_v2`, mas nao
    `card_function_tags`, em `server/lib/ai/optimize_request_support.dart:86`-`:105`
    e monta `allCardData` sem `functional_tags` em `:186`-`:198`.
  - `classifyOptimizationFunctionalRole` usa `semantic_tags_v2` primeiro e
    depois `type_line`/`oracle_text`, sem ler `functional_tags`, em
    `server/lib/ai/optimization_functional_roles.dart:55`-`:124`.
  - `OptimizationValidator` e `OptimizationSwapGateResult` chamam esse
    classificador em `server/lib/ai/optimization_validator.dart:265`-`:267` e
    `server/lib/ai/optimization_quality_gate.dart:52`-`:53`.
  - O mesmo arquivo colapsa `semantic_tags_v2` para um unico role em
    `server/lib/ai/optimization_functional_roles.dart:127`-`:180` e calcula
    `role_delta` sobre esse role unico em `:292`-`:323`.
  - Candidate quality aplica outro mapa de normalizacao em
    `server/lib/ai/candidate_quality_data_support.dart:290`-`:309`.
- **Impacto**: a aba de analise pode contar uma carta por `card_function_tags`
  persistido, enquanto optimize/validator a tratam por heuristica ou role unico
  de `semantic_tags_v2`. Swaps podem parecer seguros no gate por perderem roles
  secundarios como `engine`, `payoff`, `enabler`, `drain` ou `exile_value`.
- **Ação recomendada**:
  1. criar adapter unico `resolveCardFunctionalRoles` que receba
     `functional_tags`, `semantic_tags_v2`, `oracle_text`, `type_line`,
     `mana_cost` e `cmc`;
  2. retornar conjunto de roles + `primary_role` compatível, nao apenas string;
  3. usar o adapter em deck analysis, optimize context, validator, quality gate
     e candidate quality;
  4. carregar `card_function_tags` nas queries de optimize e additions;
  5. cobrir com testes: persisted functional sem v2, v2 multi-tag, v2 abaixo de
     confianca e fallback por oracle/tipo.
- **Validação**:
  - uma carta com `functional_tags=[draw]` e sem `semantic_tags_v2` e `draw` em
    deck analysis, validator e quality gate;
  - uma carta com `semantic_tags_v2.tags=[draw, engine]` preserva ambos os
    papeis no role delta;
  - candidate quality e optimize usam a mesma normalizacao de roles.

### P1 — Restaurar a analisabilidade do backend local
- **Evidência**:
  - `dart analyze` em `server/` falhou com:
    - `bin/local_test_server.dart:3:8 - Target of URI doesn't exist: '../.dart_frog/server.dart'`
- **Impacto**: bloqueia validação estrutural automatizada e reduz confiança em checks rápidos do backend.
- **Ação recomendada**:
  1. decidir se `bin/local_test_server.dart` exige geração prévia obrigatória de `.dart_frog/server.dart`;
  2. documentar ou automatizar esse passo no fluxo local;
  3. se o arquivo não for mais usado, substituir por entry point resiliente ou removê-lo.
- **Validação**:
  - gerar artefatos necessários ou corrigir o entry point;
  - rerodar `dart analyze` até ficar verde.

### P1 — Religar ou remover helpers publicos sem chamador runtime

- **Evidência**:
  - `server/lib/sync_cards_utils.dart` define `extractCardRow`,
    `parseSinceDays`, `extractSetCardRow`, `extractOracleIds` e
    `extractLegalities`, mas `grep -RIn "sync_cards_utils" server` encontra
    apenas `server/test/sync_cards_test.dart`.
  - O sync operacional `server/bin/sync_cards.dart` nao importa
    `sync_cards_utils.dart` e mantem copias privadas/loops inline:
    `_parseSinceDays` em `:376`, `_extractCardRow` em `:680`, montagem
    incremental de rows em `:604`-`:663` e legalidades/oracle IDs em
    `:806`-`:838`.
  - `server/lib/request_trace.dart:48` (`getRequestTrace`) e `:51`
    (`tryGetRequestId`) nao tem chamador runtime; rotas usam
    `context.read<RequestTrace>()` diretamente.
  - `server/lib/ai/commander_reference_profile_support.dart:49`
    (`normalizedCommanderReferenceCandidate`) nao tem chamador; consumidores
    usam `normalizeCommanderReferenceName`.
  - `app/lib/core/services/performance_service.dart:110`, `:130`, `:200`,
    `:210`, `:220` e `:248` expõem traces/metricas/debug manuais sem chamador
    em `app/lib`, `app/test` ou `app/integration_test`; o app usa `init`,
    `traceAsync` e `PerformanceNavigatorObserver`.
  - `server/lib/meta/mtgtop8_meta_support.dart:139`
    (`extractMtgTop8FormatCodeFromSourceUrl`) aparece apenas em teste, enquanto
    o helper de event id vizinho e usado por
    `server/bin/repair_mtgtop8_meta_history.dart`.
  - `server/lib/ai/candidate_quality_data_support.dart:631`
    (`buildCandidateQualitySamplePoolSql`) aparece apenas em teste; o runner
    `candidate_quality_data_foundation.dart` monta seus pools por outro caminho.
- **Impacto**: cobertura pode estar validando caminhos mortos, especialmente no
  sync de cartas, onde a promessa de helpers extraidos nao corresponde ao CLI
  ativo. Helpers publicos sem chamador tambem aumentam a superficie aparente da
  API interna.
- **Ação recomendada**:
  1. priorizar `sync_cards_utils.dart`: escolher entre importar os helpers no
     `server/bin/sync_cards.dart` ou remover o arquivo/testes como legado;
  2. para wrappers pequenos (`request_trace`, Commander Reference,
     PerformanceService, MTGTop8), remover se nao houver contrato planejado ou
     religar com teste focado;
  3. decidir se `buildCandidateQualitySamplePoolSql` deve virar parte real de
     um scorecard/runner ou sair junto com o teste test-only.
- **Validação**:
  - `grep -RIn "sync_cards_utils" server` passa a encontrar o binario ativo ou
    o arquivo/teste deixa de existir;
  - buscas por cada simbolo retornam pelo menos um chamador runtime/binario
    intencional alem de testes, ou o simbolo e removido;
  - testes de sync/candidate quality continuam verdes depois da decisao.

### P1 — Alinhar ownership entre `app/lib`, rotas e helpers de deck/AI
- **Status em `codex/hermes-analysis-docs@d2b189fc`: ABERTO.** A rodada local
  de 2026-05-28 23:00 UTC revalidou que `POST /ai/optimize`,
  `GET /ai/optimize/jobs/:id` e `POST /ai/archetypes` ainda nao estao
  owner-scoped de ponta a ponta neste checkout. Qualquer afirmacao historica de
  resolucao em outro SHA deve ser tratada como nao aplicavel ate a correcao
  aparecer no checkout auditado com testes.
- **Evidência**:
  - O app envia `POST /ai/optimize` com `deck_id` em
    `app/lib/features/decks/providers/deck_provider_support_ai.dart`, mas
    `server/routes/ai/optimize/index.dart` chama
    `loadOptimizeDeckContext` sem `userId`.
  - `server/lib/ai/optimize_request_support.dart` consulta `decks` e
    `deck_cards` apenas por `deckId`.
  - O app tambem envia `POST /ai/archetypes` com `deck_id` em
    `app/lib/features/decks/providers/deck_provider_support_mutation.dart`, e
    `server/routes/ai/archetypes/index.dart` consulta `decks` e `deck_cards`
    apenas por `id`/`deck_id`, sem ler `context.read<String>()` nem validar
    `decks.user_id`.
  - `GET /decks/:id/simulate`, `POST /decks/:id/recommendations`,
    `POST /ai/simulate-matchup` e `POST /ai/weakness-analysis` tambem leem
    decks/cartas por id sem ownership; os consumidores app desses endpoints
    seguem `not proven`.
  - `GET /ai/optimize/jobs/:id` permite leitura de job com `user_id = NULL`
    porque so bloqueia quando `job.userId != null && job.userId != userId`.
- **Impacto**: risco de exposicao de composicao/analise de deck privado caso um
  usuario autenticado obtenha UUID ou job ID alheio; tambem cria contratos
  ambiguos para futuras telas.
- **Ação recomendada**:
  1. corrigir primeiro os fluxos app-facing principais:
     `POST /ai/optimize`, `GET /ai/optimize/jobs/:id` e
     `POST /ai/archetypes`;
  2. antes de expor endpoints experimentais no app, escolher entre escopar por
     dono, limitar a deck publico/meta deck, ou remover/ocultar o contrato;
  3. criar rota dedicada ou teste de contrato para `/community/decks/following`,
     hoje implementada como branch `id == 'following'` em `[id].dart`.
- **Validação**:
  - `POST /ai/optimize` e `POST /ai/archetypes` retornam 404/403 para deck de
    outro usuario e continuam verdes para o dono;
  - polling de job com `user_id = NULL` retorna 404 ou fica restrito a rota
    interna documentada;
  - testes owner vs non-owner para cada rota experimental mantida;
  - `rg "/ai/simulate-matchup|/ai/weakness-analysis|/decks/.*/simulate|/decks/.*/recommendations" app/lib`
    continua vazio ate haver contrato seguro;

### P2/P3 — Decidir destino de tabelas PostgreSQL persistidas sem consumidor claro
- **Evidência**:
  - `deck_matchups` é definida em `server/database_setup.sql:162` e recebe
    upsert em `server/routes/ai/simulate-matchup/index.dart:360`, mas nao ha
    `SELECT ... FROM deck_matchups` em `app/`, `server/lib/` ou `server/routes`.
  - `deck_weakness_reports` é definida em `server/database_setup.sql:363` e
    `server/bin/migrate_create_missing_tables.dart:97`, recebe insert em
    `server/routes/ai/weakness-analysis/index.dart:374`, mas nao ha leitura em
    `app/`, `server/lib/` ou `server/routes`; o campo `addressed` tambem nao
    tem fluxo de update confirmado.
  - `ml_prompt_feedback` é definida em
    `server/bin/migrate_ml_knowledge.dart:159`, mas o unico insert fica no
    helper `MLKnowledgeService.recordFeedback`
    (`server/lib/ml_knowledge_service.dart:251`), sem chamador encontrado por
    `grep -RIn "recordFeedback" server app`; `/ai/ml-status` apenas conta rows.
  - `commander_reference_decks` e `commander_reference_deck_cards` sao definidas
    em `server/lib/ai/commander_reference_deck_corpus_support.dart:1177` e
    `:1200`, recebem inserts em `:1245` e `:1345`, mas nao possuem
    `SELECT/JOIN` confirmado; o produto consome o agregado
    `commander_reference_deck_analysis` em `:389`.
- **Impacto**: acumulacao de dados sem produto/operacao consumindo o historico,
  retencao indefinida e falsa impressao de que ha cache, dashboard, workflow
  persistente ou loop de aprendizado alimentado por essas persistencias.
- **Ação recomendada**:
  1. escolher entre manter como log bruto com retencao documentada, criar
     consumidor real ou remover a persistencia dessas rotas experimentais;
  2. ligar `ml_prompt_feedback` a um fluxo real de feedback ou remover o helper
     ate haver coleta ativa;
  3. documentar as tabelas raw do Commander Reference Corpus como lineage/audit,
     com retencao e job de reprocessamento, ou persistir apenas o agregado
     consumido;
  4. se mantiver, adicionar endpoint/job/UI que leia os dados e teste de contrato;
  5. se remover, criar migration/cleanup seguro e atualizar
     `API_CONTRACTS_AND_DATA_MAP.md`.
- **Validação**:
  - `grep -RInE "FROM[[:space:]]+deck_matchups|FROM[[:space:]]+deck_weakness_reports|FROM[[:space:]]+ml_prompt_feedback|FROM[[:space:]]+commander_reference_decks|FROM[[:space:]]+commander_reference_deck_cards" server app`
    encontra consumidores reais, ou a persistencia deixa de existir com decisao
    documentada;
  - `grep -RIn "recordFeedback" server app` encontra chamador real, caso a
    tabela de feedback seja mantida para coleta ativa;
  - testes das rotas experimentais continuam verdes;
  - contrato app-facing deixa claro se esses dados sao historico persistido ou
    apenas resposta efemera.

### P1/P2 — Remover ou documentar classes app sem uso de runtime confirmado

- **Evidência**:
  - `app/lib/features/home/life_counter_screen.dart:61` define
    `LifeCounterScreen`, mas `app/lib/main.dart:283` usa
    `LotusLifeCounterScreen()` para a rota ativa; busca em `app/lib` encontrou
    `LifeCounterScreen` apenas no proprio arquivo.
  - `app/lib/features/decks/widgets/deck_card.dart:17` define `DeckCard`, mas a
    listagem ativa usa `_DeckSpotlightCard` e `_DeckGalleryCard` em
    `app/lib/features/decks/screens/deck_list_screen.dart`; `DeckCard` aparece
    apenas em testes.
  - `app/lib/features/decks/widgets/deck_progress_indicator.dart:286` define
    `DeckProgressChip`, sem ocorrencias alem de declaracao/construtor.
  - `app/lib/features/home/lotus/lotus_presentation_mode.dart:4` define
    `LotusPresentationMode`, sem import nem chamada a `enter()`/`exit()`.
- **Impacto**: classes mortas ou legadas inflacionam a superficie de manutencao,
  mantem testes que podem nao proteger o runtime real e tornam ambigua a
  documentacao de gargalos ativos.
- **Ação recomendada**:
  1. decidir se `LifeCounterScreen` e fixture/harness legado ou deve ser removido
     em favor do Lotus runtime;
  2. remover `DeckCard`, `DeckProgressChip` e `LotusPresentationMode` se nao
     houver plano imediato de reconectar essas classes;
  3. atualizar/remover testes que hoje exercitam widgets fora do runtime real.
- **Validação**:
  - `grep -RIn --include='*.dart' '\bLifeCounterScreen\b\|\bDeckCard\b\|\bDeckProgressChip\b\|\bLotusPresentationMode\b' app/lib app/test app/integration_test`
    mostra apenas classes intencionalmente mantidas;
  - `flutter analyze --no-pub --no-fatal-infos` e suites focadas de decks/life
    counter seguem verdes apos remocao ou reconexao.

## Sequência sugerida

1. **Primeiro**: manter o auditor estrutural corrigido e confrontar novas falhas com analyzer antes de abrir tasks.
2. **Segundo**: manter `/decks/:id/recommendations` e `/ai/weakness-analysis`
   como experimentais/not-proven ate consumirem a camada semantica compartilhada
   ou terem contrato interno explicito.
3. **Terceiro**: atacar duplicações de maior risco no domínio de optimize/IA.
4. **Quarto**: modularizar os arquivos gigantes do otimizador com testes de regressão.
5. **Quinto**: decidir destino das tabelas write-only/parciais
   (`deck_matchups`, `deck_weakness_reports`, `ml_prompt_feedback` e raws do
   Commander Reference Corpus) antes de expandir novas persistencias analiticas.

Resolvido em `origin/master@32418bc6`: teste de contrato de rota para
`SEMANTIC_LAYER_V2_OPTIMIZE_ENFORCEMENT=partial` /
`OPTIMIZE_SEMANTIC_V2_REJECTED`.

## Itens explicitamente não confirmados como bug real nesta rodada

- Os **178 imports quebrados** do relatório **não** foram validados como defeitos reais de código; a amostragem conferida aponta falso-positivo do auditor.
- A seção de "funções com nomes duplicados" mistura duplicação relevante com nomes esperados (`toString`, `print`, `add`), então precisa de triagem antes de virar tarefa de engenharia.
- `battle_simulations` nao entrou como tabela nao usada nesta rodada: a rota
  `server/routes/ai/simulate/index.dart` escreve nela e
  `server/bin/ml_extract_features.dart` le a tabela para extracao de features.
- `direct_message` nao entrou como incoerencia de contrato: backend, lista de
  notificacoes e push coordinator usam `reference_id` como conversation id de
  forma compatível.

## Critério de saída para uma próxima rodada

Considerar a frente de estrutura saneada quando:

- o auditor não reportar imports existentes como ausentes;
- `dart analyze` do backend estiver verde no fluxo local documentado;
- a duplicação/similaridade restante de alto risco em IA semantica, `resolveOptimizeArchetype`, terrenos basicos e helpers HTTP cair significativamente;
- os maiores arquivos do domínio de optimize reduzirem tamanho e responsabilidade.
