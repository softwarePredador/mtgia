# Plano de Correcao — Audit de Estrutura

> Status atual: plano de correcao estrutural app/backend.
> Nao e contrato Hermes runtime. Use junto com `TECHNICAL_MAP.md` e revalide
> cada item antes de executar.

> Data: 2026-06-19 19:00 UTC
> Escopo: documentar problemas estruturais detectados em `STRUCTURE_AUDIT.md` sem alterar codigo de produto.

## Resumo executivo

O auditor gerava muito ruído por inferir imports relativos a partir do root do repositório, então os **178 "imports quebrados" não podiam ser tratados como defeitos reais** sem revalidação por `dart analyze` ou por resolução relativa ao diretório do arquivo Dart. Esse P0 foi corrigido em `docs/hermes-analysis/scripts/structure_auditor.py`. Na rodada local de duplicacao de 2026-06-19 19:00 UTC no checkout `ced006f2`, o auditor base executou com sucesso (`221` arquivos backend, `116` tabelas PostgreSQL textualmente referenciadas, `0` imports quebrados), mas voltou a inserir inventario gerado e duplicar historico manual sob o marcador do bloco gerado; essa mutacao mecanica foi revertida e os achados foram triados manualmente. A revalidacao manteve fechadas claims antigas: `basic_land_utils.dart` segue como fonte unica para basic/snow basics, `resolveOptimizeArchetype` segue centralizado em `optimize_archetype_support.dart`, e os wrappers da rota de optimize continuam delegando para helpers. Permanecem abertos os clusters de analise de estado rebuild/optimize, fallback/scoring funcional do optimize, trust social, request/log social, condition, CMC/tipo e runtime path de alguns crons/scripts Hermes. A revalidacao de tabelas PostgreSQL de 2026-06-19 15:00 UTC no checkout `f80b2da2` encontrou delta amplo desde a rodada anterior deste foco (`cac5012b..HEAD`), mas nao abriu novo achado P1/P2 app-facing: `deck_matchups` e `deck_weakness_reports` agora possuem leitura runtime nas proprias rotas, `deck_learning_events`/`commander_card_usage`/`commander_card_synergy`/`commander_learning_snapshot` possuem leitores/escritores ou consumidores operacionais, `ml_prompt_feedback` tem DDL/writer/count vivos e segue apenas sem consumidor de payload para selecao de prompt, e os raws `commander_reference_decks`/`commander_reference_deck_cards` permanecem P3 sem leitor direto. A frente aberta de aciclicidade foi revalidada em 2026-06-18 11:00 UTC no checkout `88fa4a1e`: 0 imports/exports/parts locais quebrados em 1082 diretivas locais e os mesmos 2 SCCs. A revalidacao de classes de 2026-06-19 03:00 UTC no checkout `ad2238a9` executou o auditor base com sucesso (`221` arquivos backend, `205` classes, `0` imports quebrados), encontrou delta de produto desde `94f73400`, mas nao abriu novo candidato confiavel alem dos quatro ja abertos; a unica mudanca app runtime relevante (`deck_generate_screen.dart`) manteve suas classes privadas chamadas no proprio arquivo. A auditoria local de semantica de cartas de 2026-06-17 05:30 UTC no checkout `6d25e447` nao encontrou delta de produto desde `e458c074`, mas atualizou a triagem de rebuild guiado e basic-land checks locais. A revalidacao de funcoes sem chamador de 2026-06-19 07:00 UTC no checkout `895fb545` encontrou delta amplo desde `88fa4a1e`: fechou como stale o achado P1 amplo de `sync_cards_utils.dart` test-only e confirmou `MLKnowledgeService.recordFeedback`/`hasSuspiciousNonLandCmc` como vivos, mas manteve abertos `verifySwapIntegrity`, a extracao parcial de `optimize_response_support.dart`, wrappers/conveniencias app/backend sem chamada e helpers P2/P3 de IA/scripts operacionais sem consumidor confirmado.

A revalidacao de coerencia app/server de 2026-06-18 23:00 UTC no checkout
`523589bc` fechou os tres gaps estreitos da rodada anterior:
`deck_rebuild_created` agora esta aceito/documentado na rota de activation
events, `GET /ai/commander-learning` esta documentado no API contract map com
`commander_learned_decks`, e a rota de learned deck availability ficou
autenticada sem herdar plano/rate-limit de IA custosa. Nao surgiu novo achado
confiavel de coerencia no recorte `server/lib` <-> `server/routes` <->
`app/lib`; o residual foi apenas operacional: `flutter test --no-pub` nao
executou no app sem `app/.dart_tool/package_config.json`.

A revalidacao local de semantica de cartas de 2026-06-19 05:30 UTC no checkout
`708541a5` encontrou delta amplo de produto desde a rodada anterior, mas fechou
duas claims antigas como stale: o quality gate agora preserva `functional_tags`
persistidos mesmo com `semantic_tags_v2` parcial, e `/ai/weakness-analysis` +
`/decks/:id/recommendations` passaram a carregar snapshot/tags semanticas e
buscar recomendacoes por tags/semantica/legalidade em vez de listas fixas de
staples. Permanecem abertos fallbacks por nome, prompts runtime, payload/ranking
inicial do optimize, rebuild guiado, candidate-quality foundation, check local de
basic lands em analysis e corpus/analises auxiliares.

A revalidacao de imports quebrados e dependencias circulares de 2026-06-19
11:00 UTC no checkout `8ddc978a` confirmou `0` imports/exports/parts Dart
locais quebrados em 1155 diretivas locais checadas (`app/lib`, `server/lib`,
`server/routes`, `server/bin`) e `0` imports Python locais quebrados em
`server/bin`. O ciclo backend antigo entre `optimize_runtime_support.dart` e
`optimize_filler_loader_support.dart` ficou stale: o filler loader nao importa
mais o runtime e passou a depender de modulos neutros. Permanece aberto somente
o SCC app entre `life_counter_tabletop_engine.dart` e
`life_counter_turn_tracker_engine.dart`.

1. **P0 — Ferramenta de auditoria com falso-positivo em massa**: **RESOLVIDO na ferramenta**. Manter como lição operacional: evidência do auditor deve ser confrontada com analyzer quando apontar falhas estruturais.
2. **P1 — Concentradores de complexidade muito grandes**: revalidado em
   2026-06-11; `server/lib/ai/optimize_runtime_support.dart` (~2386 linhas) e
   `server/routes/ai/optimize/index.dart` (~2498 linhas) reduziram, mas seguem
   como gargalos de manutenção.
3. **P1 — Duplicação de helpers e lógica espalhada**: revalidada novamente em
   2026-06-19 19:00 UTC. `resolveOptimizeArchetype`, strategic roles em
   `functional_card_tags.dart`, o sync principal de cartas e o exporter Hermes
   de learned deck foram retirados das claims amplas por terem fonte canonica
   ou wrapper atual. Os maiores riscos restantes sao analise de estado
   rebuild/optimize, fallback/scoring funcional do optimize, trust social,
   request/log social, condition, CMC/tipo e resolucao de runtime path em crons
   Hermes.
4. **P1 — Entry point local quebrado**: **RESOLVIDO/STALE em 2026-06-19**.
   `server/bin/local_test_server.dart` nao tem mais import estatico para
   `.dart_frog/server.dart`; a varredura ampliada encontrou 0 imports locais
   quebrados e o item nao deve ser reaberto sem nova falha de analyzer ou do
   resolvedor local.
5. **P1 — Ownership, jobs async e contratos app-facing em rotas deck/AI**:
   **PARCIAL em 2026-06-11**. O achado antigo de optimize sem owner-scope foi
   resolvido: `POST /ai/optimize` exige usuário autenticado,
   `loadOptimizeDeckContext` consulta por `id + user_id`, jobs async têm
   `userId` obrigatório e polling rejeita job sem owner ou de outro usuário.
   Deck analysis e optimize também carregam `functional_tags`. Ainda precisam
   de rodada própria os endpoints experimentais fora do caminho principal
   (`/ai/archetypes`, activation telemetry e rotas legacy/experimentais).
6. **P1 — Politicas por nome / semantica de cartas**: revalidado novamente em
   2026-06-19 no checkout `708541a5`. `/ai/weakness-analysis` e
   `/decks/:id/recommendations` continuam fora da claim antiga de listas fixas:
   ambas carregam `card_intelligence_snapshot` ou fallbacks agregados de
   `card_function_tags`/`card_semantic_tags_v2` e usam legalidade/identidade de
   cor nas sugestoes. Ainda ha excecoes por nome em
   `functional_card_tags.dart`, `optimization_functional_roles.dart`,
   `candidate_quality_data_support.dart`, `optimize_functional_role_support.dart`,
   `optimize_swap_candidate_support.dart` (pool inicial sem tags),
   `rebuild_guided_service.dart`, no mock runtime de `/ai/optimize` quando
   `deckOptimizer == null`, em prompts runtime carregados por `otimizacao.dart` e
   em analises/corpus auxiliares. Exemplos de UI/import, comentarios de contrato,
   seeds de busca, docs/corpus/artifacts/test fixtures e seeds Commander
   Reference seguem separados dos riscos reais. `commander_fallback_policy.dart`
   e `edh_bracket_policy.dart` continuam excecoes intencionais por policy
   versionada/regra externa, desde que mantenham fonte, escopo e teste dedicado.
7. **P2/P3 — Tabelas PostgreSQL write-only ou parcialmente consumidas**:
   revalidado em 2026-06-19 15:00 UTC no checkout `f80b2da2`.
   `deck_matchups` e `deck_weakness_reports` ja possuem leitura runtime nas
   proprias rotas; o risco atual e baixa retroalimentacao de produto, nao
   ausencia total de consumidor. `ml_prompt_feedback` tem schema, writer runtime
   em `/ai/optimize` e contador em `/ai/ml-status`; o risco restante e usar esse
   historico para selecao/score de prompts. `commander_reference_decks` e
   `commander_reference_deck_cards` seguem como raw corpus P3 sem `SELECT/JOIN`
   direto confirmado, enquanto o produto le o agregado
   `commander_reference_deck_analysis`. `deck_learning_events`,
   `commander_card_usage`, `commander_card_synergy` e
   `commander_learning_snapshot` foram descartadas como achados por terem
   leitores/escritores ou consumidores operacionais confirmados.
8. **P1/P2 — Classes app sem uso de runtime confirmado**: revalidado novamente
   na rotacao local Codex de 2026-06-19 03:00 UTC no checkout `ad2238a9`.
   `LifeCounterScreen` segue
   como caminho legado/test-only enquanto a rota viva usa `LotusLifeCounterScreen`;
   `DeckCard` continua testado mas sem import/chamada na listagem real;
   `DeckProgressChip` nao tem chamada de construtor; `LotusPresentationMode`
   nao tem import nem chamada para `enter()`/`exit()`. Controles positivos desta
   rodada descartaram `LotusLifeCounterScreen`, `DeckProgressIndicator` e as
   classes privadas de `deck_generate_screen.dart`; a varredura textual ampla
   nao foi usada para acusar DTOs/helpers locais sem evidencia adicional.
9. **P1 — Drift entre deck analysis e optimize**: **PARCIAL em 2026-06-19**.
   O caminho principal carrega `functional_tags`/`semantic_tags_v2`; deck
   analysis, validator e quality gate preservam multi-tags com precedencia
   `functional_tags -> semantic_tags_v2 -> heuristica`. O risco restante nao esta
   no gate principal, mas em payload `removals_detailed`, need/replacement
   ranking inicial, fallbacks de role por nome e modulos auxiliares que ainda nao
   reutilizam plenamente a camada compartilhada.
10. **P2 — Bracket state em fillers de optimize/complete**: **RESOLVIDO em
    `origin/master@1aa4da71`**. Os loaders de fillers agora recebem estado
    atual/virtual do deck e nao usam fallback `bracket: null` quando o bracket
    foi definido.
11. **P3 — Diagnosticos de bracket em sucesso parcial do optimize**:
    **RESOLVIDO em `origin/master@4913a733`**. Sucessos com sugestoes filtradas
    por bracket podem expor `optimize_diagnostics.bracket_policy`, mantendo
    `warnings.blocked_by_bracket` para compatibilidade.
12. **P1/P2 — Funcoes publicas sem chamador runtime**: revalidado em
    2026-06-19 07:00 UTC no checkout `895fb545`. `sync_cards_utils.dart` deixou
    de ser achado P1 amplo porque `server/bin/sync_cards.dart` importa o
    utilitario e chama `parseSinceDays`, `getNewSetCodesSinceFromData` e
    `extractSetCardSyncRow`; restam apenas helpers legados/test-only no mesmo
    arquivo (`extractCardRow`, `extractSetCardRow`, `extractOracleIds`,
    `extractLegalities`). `MLKnowledgeService.recordFeedback` e
    `hasSuspiciousNonLandCmc` sairam da lista por terem chamador runtime.
    Permanecem abertos `verifySwapIntegrity`, `buildOptimizeResponse` e o
    top-level `respondWithOptimizeTelemetry` extraidos mas nao ligados ao fluxo,
    wrappers/conveniencias em request trace, app providers, token boot,
    performance manual, `EndpointCache.clearExpired`, EDHREC/log/counter/push
    auxiliares, `buildLoreholdReferenceCardStatsFromProfile`,
    `summarizeAggressiveOptimizeUtilitySamples`, `normalize_commander` na copia
    Hermes docs e dois helpers script-level (`classify_loss_v2`,
    `compute_loss_tags_from_replays`). Funcoes historicas
    `normalizedCommanderReferenceCandidate`, `extractMtgTop8FormatCodeFromSourceUrl`
    e `buildCandidateQualitySamplePoolSql` nao existem mais no checkout vivo.
13. **P1/P2 — Imports quebrados e dependencias circulares**: revalidado em
    2026-06-19 11:00 UTC no checkout `8ddc978a`. O auditor base reportou
    `Imports quebrados: 0`; o scanner ampliado encontrou `0` diretivas Dart
    locais quebradas em 429 arquivos e `0` imports Python locais quebrados em
    33 scripts de `server/bin`. As claims antigas contra `deck_analysis_tab.dart`,
    `life_counter_screen.dart`, `local_test_server.dart`,
    `commander-learning/index.dart` e o ciclo Community/Social seguem stale. O
    ciclo backend `optimize_runtime_support.dart` <->
    `optimize_filler_loader_support.dart` tambem foi fechado: o filler loader
    agora usa `optimize_filler_candidate_support.dart` e
    `optimize_functional_role_support.dart` sem importar o runtime. O unico SCC
    aberto nesta frente e o par
    `life_counter_tabletop_engine.dart` <->
    `life_counter_turn_tracker_engine.dart`, com analyzer focado verde.

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
  - `server/lib/ai/optimize_runtime_support.dart`: 2374 linhas
  - `server/routes/ai/optimize/index.dart`: 2498 linhas
  - A rodada focada de duplicacao em 2026-05-28 revalidou que a rota agora possui wrappers finos para helpers como `matchesFunctionalNeed`, `scoreOptimizeReplacementCandidate`, `shouldRetryOptimizeWithAiFallback`, `computeOptimizeStructuralRecoverySwapTarget` e `isOptimizeStructuralRecoveryScenario`, delegando para `optimize_support` em vez de manter corpos duplicados.
  - Status 2026-06-11: o drift de `resolveOptimizeArchetype` foi fechado em
    `server/lib/ai/optimize_archetype_support.dart`; runtime optimize e
    deck-state analysis agora delegam para a mesma política. Permanecem como
    foco de modularização os blocos de seleção de candidatos, structural
    recovery e fallback AI.
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
- **Status 2026-06-19 19:00 UTC: PARCIAL no checkout `ced006f2`.**
  `resolveOptimizeArchetype` foi unificado, os roles estratégicos
  `wincon`, `combo_piece`, `engine`, `payoff` e `enabler` usam
  `resolveCardFunctionalRoles` também na geração de `functional_tags`,
  basic/snow basic lands seguem centralizados em `server/lib/basic_land_utils.dart`,
  `sync_cards.dart` passou a consumir `sync_cards_utils.dart` no caminho
  operacional principal, e `server/bin/export_hermes_learned_deck.py` virou
  wrapper da implementacao canonica em
  `docs/hermes-analysis/manaloom-knowledge/scripts/export_hermes_learned_deck.py`.
  As duplicações restantes abaixo continuam abertas conforme dominio; a
  duplicacao de maior risco atual e a familia de analise de estado ainda
  separada entre rebuild e optimize.
- **Evidência**:
  - Resolvido: `resolveOptimizeArchetype` agora delega para
    `server/lib/ai/optimize_archetype_support.dart`, com teste em
    `server/test/optimize_archetype_support_test.dart` cobrindo
    `midrange`, `tempo`, `goodstuff`, `general`, `unknown`, vazio e detected
    específico em runtime e deck-state analysis.
  - Resolvido: `functional_card_tags.dart` removeu cópias privadas de
    `_looksLikeComboPiece`, `_looksLikeEnabler`, `_looksLikeEngine`,
    `_looksLikePayoff` e `_looksLikeWincon`; `inferFunctionalCardTags` agora
    consulta `resolveCardFunctionalRoles` para os roles estratégicos. O teste
    `functional_card_tags_test.dart` prova alinhamento com
    `optimizationFunctionalRolesForCard`.
  - Resolvido: basic/snow basic lands agora usam
    `server/lib/basic_land_utils.dart`. `optimize_runtime_support.dart`
    preserva somente wrapper público fino, `commander_reference_deck_corpus_support.dart`
    preserva `basicLandNames` como alias do utilitário e testes de regras/optimize
    importam o helper em vez de copiar `_isBasicLandName`.
  - Resolvido: o achado amplo de `sync_cards_utils.dart` test-only ficou stale.
    `server/bin/sync_cards.dart:12` importa `../lib/sync_cards_utils.dart` e
    usa `parseSinceDays`, `getNewSetCodesSinceFromData` e
    `extractSetCardSyncRow` no fluxo operacional. Residuo P3 estreito:
    `extractLegalities` ainda aparece somente em `sync_cards_utils.dart` e
    `sync_cards_test.dart`, enquanto `_upsertLegalitiesFromSet` monta rows
    inline.
  - Resolvido: o exporter de learned deck em `server/bin` deixou de duplicar a
    implementacao. Ele carrega o arquivo canonico de docs e reexporta seus
    simbolos; `test_export_hermes_learned_deck_wrapper_parity.py` protege essa
    paridade.
  - `DeckArchetypeAnalyzer`/`assessDeckOptimizationState` continuam em duas
    familias: `server/lib/ai/deck_state_analysis.dart:3`-`:100` e `:311`-`:500`
    para rebuild, e `server/lib/ai/optimize_state_support.dart:6`-`:103` e
    `:337`-`:520` para optimize.
  - `server/lib/ai/optimize_functional_role_support.dart:3`-`:68`,
    `:167`-`:217`, `:219`-`:245` e `:248`-`:303` mantem fallback/matching/scoring
    proprio para optimize mesmo depois de usar `resolveCardFunctionalRoles`
    quando tags persistidas ou semantic v2 existem.
  - `_trustStatsSql`, `_responseTimeSql`, `_shippingTimeSql` e
    `_buildTrustInsight` duplicam o mesmo trust em listagem/detalhe de trades
    (`server/routes/trades/index.dart:557`-`:635`,
    `server/routes/trades/[id]/index.dart:260`-`:338`). O marketplace repete
    os LATERALs inline em `server/routes/community/marketplace/index.dart:131`-`:162`
    e tambem duplica o serializer em `:316`-`:348`.
  - `_requestId` e `_logInvalidPayload` repetem o mesmo padrao em
    `server/routes/trades/[id]/status.dart:260`-`:284`,
    `server/routes/trades/[id]/respond.dart:154`-`:178`,
    `server/routes/trades/[id]/messages.dart:228`-`:252` e
    `server/routes/conversations/[id]/messages.dart:247`-`:271`; a rodada de
    2026-06-01 tambem confirmou `_requestId` em
    `server/routes/trades/index.dart:330`-`:336` e
    `server/routes/users/[id]/follow/index.dart:97`-`:103`, apesar de
    `server/lib/request_trace.dart:35`-`:49` ja expor wrappers de trace.
  - Condicoes `NM/LP/MP/HP/DMG` estao espalhadas entre mutacoes de deck,
    binder e marketplace; algumas rotas normalizam invalido para `NM`
    (`server/routes/decks/[id]/cards/index.dart:409`-`:413`,
    `server/routes/decks/[id]/cards/set/index.dart:249`-`:253` e
    `server/routes/decks/[id]/index.dart:525`-`:529`), outras rejeitam
    com `400` (`server/routes/binder/index.dart:275`-`:280`) e o marketplace
    ignora filtros invalidos (`server/routes/community/marketplace/index.dart:39`-`:43`).
  - `getMainType` e `calculateCmc` aparecem duplicados em deck privado/publico
    (`server/routes/decks/[id]/index.dart:411`-`:441`,
    `server/routes/community/decks/[id].dart:91`-`:117`) e ha variante de CMC
    em `server/routes/decks/[id]/simulate/index.dart:199`-`:214`.
  - `server/bin/repo_runtime_paths.py:34`-`:75` oferece helper compartilhado
    para repo root, scripts de battle e diretorios de replay, mas
    `server/bin/manaloom_ops_daemon.py:15`-`:18`,
    `server/bin/hermes_mana_base_validator.py:18`-`:24`,
    `server/bin/auto_promote_learned_decks.py:19`-`:29` e
    `docs/hermes-analysis/manaloom-knowledge/scripts/run_import.py:25`-`:35`
    ainda mantem resolucao propria.
- **Impacto**: mudanca semantica em um ponto nao propaga automaticamente para os demais; risco de respostas inconsistentes por endpoint/fluxo. O risco mais alto e de IA: optimize, complete, rebuild, validator e deck analysis podem discordar sobre estado do deck, arquetipo efetivo e papel funcional de cartas.
- **Ação recomendada**:
  1. manter `optimize_archetype_support.dart` como fonte única de arquétipo
     efetivo;
  2. manter `resolveCardFunctionalRoles` como adapter único de roles funcionais
     para análise, optimize, validator e quality gate;
  3. manter `basic_land_utils.dart` como fonte única para terrenos básicos/snow
     basics e não reintroduzir listas locais em novos fluxos;
  4. agrupar duplicacoes de menor risco por dominio (trust social, request/log,
     condicao de carta, CMC/tipo), mantendo wrappers locais so quando o contrato
     divergente for intencional e testado.
  5. mover `extractLegalities` para o fluxo real de `_upsertLegalitiesFromSet`
     ou remover o helper/teste residual;
  6. migrar crons elegiveis para `repo_runtime_paths.py` ou documentar/testar as
     divergencias de ambiente de cada copia.
- **Validação**:
  - ✅ `optimize_archetype_support_test.dart` prova o mesmo arquetipo efetivo
    para `midrange`, `tempo`, `goodstuff`, `general`, `unknown`, vazio e
    detected especifico;
  - ✅ `functional_card_tags_test.dart` prova que os roles estratégicos do
    tagger (`wincon`, `combo_piece`, `engine`, `payoff`, `enabler`) seguem o
    mesmo adapter usado pelo optimize;
  - uma carta com papeis multiplos preserva roles secundarios no validator e na
    aba de analise;
  - ✅ snow basics tem comportamento igual nos fluxos cobertos e `Snow-Covered
    Wastes` está em teste;
  - listagem/detalhe de trades e marketplace continuam retornando o mesmo shape
    de `trust`;
  - `dart analyze` e suites focadas seguem verdes apos cada extracao.
  - `rg "extractLegalities\\(" server/bin server/lib server/test` mostra
    chamador operacional ou helper/teste removidos.
  - scripts que mantiverem `_resolve_repo_root` proprio tem teste cobrindo
    variaveis aceitas e defaults.

### P1 — Centralizar e reduzir politicas por nome restantes
- **Status 2026-06-18 05:30 UTC: REVALIDADO/ABERTO no checkout `abfe1497`.**
  Sem delta de produto desde `6d25e447`/`e458c074` no recorte `server/lib`,
  `server/routes` e `app/lib`; os commits novos da branch sao documentais.
  A branch atual ja tem excecoes aceitaveis e testadas:
  `edh_bracket_policy.dart` como regra externa/Game Changer e
  `commander_fallback_policy.dart` como policy versionada para fallbacks
  Commander. O risco aberto sao nomes ainda espalhados em classificadores
  heuristics, foundation de candidate quality, prompts runtime, replacement
  ranking, endpoints advisory, rebuild guiado, advanced analysis e meta shell,
  alem de um gap estreito no quality gate quando semantic v2 existe mas
  `functional_tags` persistidos tem multi-tags adicionais.
- **Evidencia**:
  - `server/lib/ai/functional_card_tags.dart:219`-`:226`, `:713`-`:730`,
    `:767`-`:793`, `:836`-`:848`, `:863`-`:884` e `:900`-`:924` usa nomes como
    `Sol Ring`, signets/talismans, `Teferi's Protection`, `Heroic Intervention`,
    `Swiftfoot Boots`, `Lightning Greaves`, `Blood Artist`, `Ephemerate`,
    `Jeska's Will`, `Thassa's Oracle`, `Isochron Scepter` e
    `Dramatic Reversal` em fallbacks funcionais.
  - `server/lib/ai/optimization_functional_roles.dart:176`-`:179`,
    `:228`-`:240`, `:387`-`:420` e `:447`-`:529` mantem nomes/sets conhecidos no
    fallback do adapter de optimize.
  - `server/bin/candidate_quality_data_foundation.dart:99`-`:126` gera
    `card_function_tags`/`card_role_scores` chamando helpers heuristicos; estes
    usam nomes em `server/lib/ai/candidate_quality_data_support.dart:376`-`:380`,
    `:422`-`:448`, `:475`-`:481` e policy em `:586`-`:605`.
  - `server/lib/ai/otimizacao.dart:854`-`:865` e `:1002`-`:1009` leem
    `prompt.md`/`prompt_complete.md` como system prompt runtime. Os prompts tem
    exemplos nomeados em `server/lib/ai/prompt.md:93`, `:121`-`:123` e
    `server/lib/ai/prompt_complete.md:66`-`:80`.
  - `server/lib/ai/optimize_runtime_support.dart:435`-`:463` e `:470`-`:500`
    montam candidatos de replacement sem tags persistidas; `:520`-`:530` ranqueia
    por texto/tipo, `preferredNames`, popularidade, rejeicao, CMC e tipo. Em modo
    aggressive ha rerank com signals persistidos em
    `server/lib/ai/optimize_candidate_quality_support.dart:203`-`:285`, mas o pool
    inicial segue semantica-parcial.
  - `server/routes/decks/[id]/recommendations/index.dart:48`-`:67` nao carrega
    tags persistidas, recalcula buckets por `oracle_text` em `:122`-`:145`,
    recomenda `Command Tower` diretamente em `:282`-`:289`, e `_findStaples` usa
    raridade `rare/mythic` como proxy em `:478`-`:506`.
  - `server/routes/ai/weakness-analysis/index.dart:50`-`:68` nao carrega
    `card_function_tags`, `semantic_tags_v2` nem `card_role_scores`; chama
    `resolveCardFunctionalRoles` sem essas fontes em `:115`-`:122` e retorna
    listas fixas de recomendacao em `:193`-`:199`, `:212`-`:217`,
    `:230`-`:235`, `:248`-`:253`, `:282`-`:287` e `:299`-`:304`.
  - `server/lib/ai/rebuild_guided_service.dart:1226`-`:1231` classifica ramp por
    `signet`/`sol ring`/`talisman`, e `:1331`-`:1338`, `:1404`-`:1411` aplicam
    penalidade/prioridade a utility lands especificas por nome.
  - `server/routes/decks/[id]/recommendations/index.dart:110`-`:130` calcula
    buckets por `oracle_text` local; `:262`-`:268` recomenda `Command Tower`
    diretamente quando `landCount < 34`; `_findStaples` em `:408`-`:438` trata
    raridade `rare/mythic` como proxy de alto impacto sem role semantico.
  - **Status 2026-06-12:** a parte de contagem em
    `server/routes/ai/weakness-analysis/index.dart` foi parcialmente saneada:
    a rota carrega `card_function_tags` e `card_semantic_tags_v2` quando as
    tabelas existem e usa `resolveCardFunctionalRoles` antes do fallback
    textual. Permanece pendente a troca das listas fixas de nomes retornadas
    em recomendações por busca/policy versionada.
  - `server/lib/ai/otimizacao.dart:856`-`:865` e `:1004`-`:1009` carregam
    `server/lib/ai/prompt.md` e `prompt_complete.md`; os prompts incluem nomes
    em `prompt.md:93`-`:123`/`:158`-`:172` e
    `prompt_complete.md:63`-`:80`/`:112`-`:117`. Isso nao e branch
    deterministico, mas e comportamento de produto quando a IA e chamada.
  - `server/lib/edh_bracket_policy.dart:134`-`:142` usa listas por nome para
    combos infinitos e Game Changers; este caso e excecao intencional de regra
    externa, mas ainda precisa de fonte/versionamento/teste dedicado.
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
  - `grep -RIn --include='*.dart' -E "Sol Ring|Command Tower|Thassa's Oracle|Isochron Scepter|Dramatic Reversal|Blood Artist" server/lib server/routes app/lib`
    nao encontra decisao runtime fora de fixtures, docs, exemplos de UI/import,
    seed/corpus declarado, prompts gerados por policy ou policy versionada;
  - testes provam que score/bracket/premium vem da policy e continua respeitando
    legalidade, identidade de cor e bracket.

### P1/P2 — Manter adapter semantico compartilhado entre analysis, optimize e candidate quality

- **Status 2026-06-07 05:30 UTC: REVALIDADO/ABERTO no checkout `84a97d75`.**
- **Evidência**:
  - `GET /decks/:id/analysis` seleciona `card_function_tags` e
    `semantic_tags_v2` em `server/routes/decks/[id]/analysis/index.dart:80`-`:96`;
    `POST /decks/:id/ai-analysis` faz o mesmo em
    `server/routes/decks/[id]/ai-analysis/index.dart:119`-`:135`.
  - `summarizeFunctionalTagsForDeck` prefere `functional_tags` persistidos e so
    usa heuristica depois em `server/lib/ai/functional_card_tags.dart:432`-`:465`.
  - `loadOptimizeDeckContext` carrega `semantic_tags_v2`, mas nao
    `card_function_tags`, em `server/lib/ai/optimize_request_support.dart:86`-`:107`
    e monta `allCardData` sem `functional_tags` em `:186`-`:198`.
    O helper de select em `:323`-`:339` tambem agrega apenas
    `card_semantic_tags_v2`.
  - `classifyOptimizationFunctionalRole` usa `semantic_tags_v2` primeiro e
    depois `type_line`/`oracle_text`, sem ler `functional_tags`, em
    `server/lib/ai/optimization_functional_roles.dart:55`-`:124`.
  - `OptimizationValidator` e o quality gate chamam esse classificador em
    `server/lib/ai/optimization_validator.dart:266`-`:268` e
    `server/lib/ai/optimization_quality_gate.dart:53`-`:54`.
  - O checkout atual nao contem `optimizationFunctionalRolesForCard`; o caminho
    vivo ainda e `classifyOptimizationFunctionalRole`, escalar. O mesmo arquivo
    colapsa `semantic_tags_v2` para um unico role em
    `server/lib/ai/optimization_functional_roles.dart:127`-`:180` e calcula
    `role_delta` sobre esse role unico em `:292`-`:323`.
    A precedencia tambem diverge no fallback textual: o comentario em `:111`-`:112`
    diz que roles altos sao checados antes do fallback de tipo, mas o codigo
    retorna wipe/protection/removal/ramp/draw/tutor antes de
    `wincon`/`engine`/`combo_piece`/`payoff`/`enabler` em `:63`-`:117`.
  - Candidate quality aplica outro mapa de normalizacao em
    `server/lib/ai/candidate_quality_data_support.dart:290`-`:309`.
  - `server/routes/ai/optimize/index.dart:2090`-`:2099` monta
    `additionsData` com `semantic_tags_v2`, mas sem `functional_tags`; o helper
    local de select v2 em `:3197`-`:3213` tambem nao agrega
    `card_function_tags`.
  - Nuance revalidada: candidate quality nao deve ser descrito como totalmente
    sem `card_function_tags`, porque
    `server/lib/ai/optimize_runtime_support.dart:2650`-`:2658` consulta
    `card_function_tags` para sinais de candidatos. A lacuna ativa e o caminho de
    contexto/validator/role preservation e o adapter unico.
  - **Status 2026-06-12:** `server/routes/ai/weakness-analysis/index.dart`
    passou a carregar `card_function_tags`/`card_semantic_tags_v2` opcionalmente
    e a contar funções via `resolveCardFunctionalRoles`, com fallback textual.
    Ainda recomenda nomes fixos em alguns blocos, o que segue como pendência de
    policy/busca versionada.
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

### P2 — Threadar estado atual do deck nos fillers de optimize/complete

**Status 2026-05-29: RESOLVIDO em `origin/master@1aa4da71`.**

- `loadDeterministicSlotFillers` passa `currentDeckCards` para fillers
  competitivos.
- `loadBroadCommanderNonLandFillers`, `loadCompetitiveNonLandFillers` e
  `loadEmergencyNonBasicFillers` recebem `currentDeckCards` e aplicam a policy
  de bracket contra o estado real/virtual.
- `loadGuaranteedNonBasicFillers` so usa fallback sem bracket quando
  `bracket == null`, evitando degradacao silenciosa de power-level.
- `optimize_complete_support.dart` passa `state.virtualDeck` para os caminhos
  broad/spells/emergency.
- `server/test/optimize_runtime_support_test.dart` possui source guard contra
  regressao para `currentDeckCards: const []`, `if (filtered.isNotEmpty)` e
  complete sem `state.virtualDeck`.

- **Validacao executada**:
  - `dart analyze bin lib routes test`
  - `dart test` em `server/` com 612 testes
  - `dart test test/optimize_runtime_support_test.dart -r expanded`
  - `git diff --check`
  - smoke Hermes pos-push para `1aa4da71cb012698372923438a58716ab2f7a75a`

### P3 — Expor bracket policy em sucesso parcial do optimize

**Status 2026-05-29: RESOLVIDO em `origin/master@4913a733`.**

- `server/routes/ai/optimize/index.dart` adiciona
  `optimize_diagnostics.bracket_policy` quando `blockedByBracket` nao esta
  vazio em uma resposta de sucesso.
- O payload inclui `bracket`, `blocked_count`, `blocked_additions` e `message`.
- `warnings.blocked_by_bracket` continua existindo para compatibilidade com
  clientes antigos.
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md` documenta o campo aditivo.
- `server/test/ai_optimize_semantic_enforcement_route_contract_test.dart` cobre
  o helper e garante que diagnosticos existentes sao preservados.

- **Validacao executada**:
  - `dart analyze bin lib routes test`
  - `dart test` em `server/` com 612 testes
  - `dart test test/ai_optimize_semantic_enforcement_route_contract_test.dart -r expanded`
  - `git diff --check`
  - smoke Hermes pos-push para `4913a733bb6984bf9eb97d22d0c9598018aa05dc`

### P1 — Restaurar a analisabilidade do backend local
- **Status 2026-06-19 11:00 UTC: RESOLVIDO/STALE no checkout local `8ddc978a`.**
  A resolucao historica segue refletida nesta branch de memoria.
- **Evidência**:
  - `server/bin/local_test_server.dart:5`-`:13` checa
    `.dart_frog/server.dart` em runtime e retorna erro operacional claro quando
    o artefato nao existe.
  - Nao ha import estatico para `../.dart_frog/server.dart`.
  - `cd server && dart analyze bin/local_test_server.dart` retornou
    `No issues found`.
- **Impacto atual**: o bug estrutural de import estatico deixou de bloquear a
  analise focada do entrypoint local. O wrapper ainda depende do artefato gerado
  para executar servidor, mas isso agora e uma condicao operacional runtime, nao
  import quebrado.
- **Ação recomendada**:
  1. manter a checagem runtime clara para `.dart_frog/server.dart`;
  2. nao reabrir este item como import quebrado sem nova falha de analyzer ou
     resolvedor local.
- **Validação**:
  - `dart analyze bin/local_test_server.dart` permanece verde.
  - Se o wrapper continuar existindo, `PORT=18082 dart run bin/local_test_server.dart`
    deve emitir erro operacional claro quando `.dart_frog/server.dart` nao
    existir, ou iniciar o servidor quando o artefato estiver presente.

### P1 — Corrigir imports quebrados no app e no entrypoint local do backend

**Status 2026-06-19 11:00 UTC: RESOLVIDO/STALE no checkout local `8ddc978a`.**
As resolucoes historicas para os imports app e o entrypoint local estao
refletidas nesta branch de memoria; nao ha import local quebrado confirmado no
recorte auditado.

- **Evidência**:
  - `app/lib/features/decks/widgets/deck_analysis_tab.dart:3`-`:4` importa
    `AppTheme` e `ManaHelper` via `package:manaloom/...`.
  - `app/lib/features/home/life_counter_screen.dart:5` importa `AppTheme` via
    `package:manaloom/...`.
  - `server/bin/local_test_server.dart:5`-`:13` valida
    `.dart_frog/server.dart` em runtime, sem import estatico quebrado.
  - A varredura focada de 429 arquivos Dart em `app/lib`, `server/lib`,
    `server/routes` e `server/bin` encontrou 0 imports/exports/parts locais
    quebrados em 1155 diretivas locais checadas.
  - A checagem estreita de 33 scripts Python em `server/bin` encontrou 0
    imports locais quebrados.
  - `cd server && dart analyze bin/local_test_server.dart` retornou
    `No issues found`.
  - O import historico de `server/routes/ai/commander-learning/index.dart:4`
    para `server/lib/ai/commander_learned_deck_support.dart` nao esta mais
    quebrado neste checkout; o arquivo alvo existe e
    `dart analyze routes/ai/commander-learning/index.dart` retornou
    `No issues found`.
- **Impacto atual**: nenhuma acao de correcao de import quebrado foi confirmada
  nesta rodada. O analyzer app focado nos dois arquivos do SCC atual retornou
  `No issues found!`; o app inteiro ainda deve ser confirmado apos `flutter pub get`.
- **Ação recomendada**:
  1. nao abrir task para `deck_analysis_tab.dart`, `life_counter_screen.dart` ou
     `local_test_server.dart` sem nova evidencia;
  2. apos `flutter pub get`, rerodar `flutter analyze --no-pub --no-fatal-infos`
     para confirmar o app inteiro quando o package config existir.
- **Validação**:
  - resolvedor local de imports reporta 0 imports quebrados em `server/` e
    `app/`;
  - `dart analyze bin/local_test_server.dart` e
    `dart analyze routes/ai/commander-learning/index.dart` seguem verdes;
  - `flutter analyze` roda com `app/.dart_tool/package_config.json` presente e
    sem `uri_does_not_exist` para imports core.

### P2 — Quebrar o ciclo direto entre `CommunityDeckDetailScreen` e `UserProfileScreen`

**Status 2026-06-11 11:00 UTC: RESOLVIDO/STALE no checkout local `372cdfca`.**
A resolucao historica esta refletida nesta branch de memoria; o grafo local
focado nao encontrou SCC com esses dois arquivos.

- **Evidência**:
  - `app/lib/features/community/screens/community_deck_detail_screen.dart:2`
    importa `package:go_router/go_router.dart` e nao importa
    `user_profile_screen.dart`.
  - `app/lib/features/social/screens/user_profile_screen.dart:3` importa
    `package:go_router/go_router.dart` e nao importa
    `community_deck_detail_screen.dart`.
  - A rodada focada de 409 arquivos Dart encontrou 2 SCCs, nenhum deles
    contendo Community/Social.
- **Impacto atual**: a dependencia direta entre as duas telas nao e mais um
  achado aberto nesta branch.
- **Ação recomendada**:
  1. manter navegacao cruzada por GoRouter/rotas, evitando reintroduzir import
     mutuo entre `community` e `social`;
  2. manter testes de perfil/comunidade cobrindo os dois caminhos de navegacao.
- **Validação**:
  - grafo local de imports continua sem SCC contendo `CommunityDeckDetailScreen`
    e `UserProfileScreen`;
  - `profile_community_runtime_test.dart` ou teste equivalente continua cobrindo
    abrir perfil a partir de deck publico e abrir deck publico a partir do
    perfil.

### P1/P2 — Quebrar ciclo entre engines do life counter

**Status 2026-06-11:** **PARCIAL.** O item de maior risco operacional desta
seção foi resolvido: `sync_cards_utils.dart` agora é importado por
`server/bin/sync_cards.dart`, e o CLI usa os helpers compartilhados para
parsing de `--since-days`, seleção incremental de sets e extração completa de
cards de Set.json. As anotações históricas de 2026-06-07 continuam válidas
apenas para os demais helpers abaixo.

- **Evidência**:
  - ✅ Resolvido 2026-06-11: `server/bin/sync_cards.dart` importa
    `server/lib/sync_cards_utils.dart` e chama `parseSinceDays`,
    `getNewSetCodesSinceFromData` e `extractSetCardSyncRow`. As antigas cópias
    privadas `_parseSinceDays`, `_getNewSetCodesSinceFromData` e
    `_extractCardRowFromSet` foram removidas do binário. O helper legado
    `extractSetCardRow` foi preservado como projeção compatível de 12 colunas,
    enquanto `extractSetCardSyncRow` expõe a linha operacional de 15 colunas
    com `power`, `toughness` e `keywords`.
  - `server/lib/request_trace.dart:48` e `:51` definem
    `getRequestTrace`/`tryGetRequestId`; os consumidores reais usam
    `context.read<RequestTrace>()` diretamente, por exemplo
    `server/lib/auth_middleware.dart:57`, `server/lib/observability.dart:225`,
    `server/routes/trades/index.dart:332` e
    `server/routes/conversations/[id]/messages.dart:249`.
  - `server/lib/ai/commander_reference_card_stats_support.dart:252` define
    `buildLoreholdReferenceCardStatsFromProfile`, mas a busca encontrou apenas
    teste e definicao; o builder generico e usado no mesmo arquivo em `:363`.
  - `server/lib/ai/optimize_runtime_support.dart:1671` define
    `summarizeAggressiveOptimizeUtilitySamples`; a busca encontrou apenas teste
    e definicao.
  - `app/lib/core/api/api_client.dart:140` define
    `ApiClient.loadTokenFromDisk()`, cujo comentario diz que e chamado 1x no
    boot, mas `rg "loadTokenFromDisk" app/lib app/test app/integration_test`
    encontrou somente a definicao.
  - `app/lib/core/services/performance_service.dart:115`, `:135`, `:205`,
    `:215`, `:225` e `:253` expoem traces/metricas/debug manuais sem chamador
    em `app/lib`, `app/test` ou `app/integration_test`; o app usa `init` em
    `app/lib/main.dart:122`, `PerformanceNavigatorObserver` em
    `app/lib/main.dart:209`, e `traceAsync` aparece no smoke de observabilidade.
  - `server/lib/ai/edhrec_service.dart:350`, `:372`, `:380` e `:416` expoem
    `getTopByCategory`, `calculateFitScore`, `cleanupCache` e `isHighSynergy`
    sem chamador confirmado. Controle positivo: `getHighSynergyCards` e chamado
    em `server/lib/ai/otimizacao.dart:112`, `:120`, `:313` e `:321`.
  - `server/lib/ai/commander_reference_card_stats_support.dart:252` define
    `buildLoreholdReferenceCardStatsFromProfile`, chamado apenas por teste e
    pela propria delegacao para `buildCommanderReferenceCardStatsFromProfile`;
    o builder generico segue vivo no mesmo arquivo em `:363`.
    `server/lib/ai/optimize_runtime_support.dart:1671` define
    `summarizeAggressiveOptimizeUtilitySamples`, com chamada encontrada apenas
    em `server/test/optimize_runtime_support_test.dart:215`.
  - `server/lib/endpoint_cache.dart:32` define `EndpointCache.clearExpired`,
    sem chamada confirmada; `EndpointCache.instance.get/set` seguem vivos em
    rotas de cards, sets, archetypes e generate performance support.
- **Impacto**: cobertura pode estar validando caminhos mortos nos helpers
  restantes, mas o risco mais alto do sync de cartas foi fechado; os testes
  agora cobrem o mesmo extrator usado pelo CLI operacional.
- **Ação recomendada**:
  1. ✅ Resolvido 2026-06-11: `sync_cards_utils.dart` virou fonte
     compartilhada real do CLI;
  2. para cada wrapper test-only restante, ligar ao runner/rota esperado ou remover o
     helper e o teste correspondente;
  5. remover `ApiClient.loadTokenFromDisk()`/comentario ou religar
     explicitamente ao boot se esse for o contrato desejado;
  6. manter `PerformanceService` como API publica apenas se houver plano de
     observabilidade mobile/manual traces; caso contrario, simplificar para
     `init` + observer + `traceAsync`;
  7. transformar conveniencias EDHREC/cache/counters/push/read-side sem
     consumidor em private/remover, ou ligar a rotina real com teste;
  8. continuar usando busca de chamadores como guardrail antes de adicionar
     novos helpers publicos.
- **Validação**:
  - `grep -RIn "sync_cards_utils" server` encontra o binário ativo:
    `server/bin/sync_cards.dart`;
  - `dart analyze lib/sync_cards_utils.dart bin/sync_cards.dart test/sync_cards_test.dart`;
  - `dart test test/sync_cards_test.dart --reporter compact`;
  - busca por simbolo encontra chamador runtime ou nenhum simbolo residual.

### P1/P2 — Alinhar contratos app-facing entre `app/lib`, rotas e helpers
- **Status 2026-06-18 23:00 UTC:** RESOLVIDO para os tres gaps estreitos
  revalidados no checkout local `523589bc`. Os achados anteriores de ownership
  em `/ai/optimize`, `/ai/archetypes` e jobs async de optimize/generate
  continuam resolvidos/stale. A lacuna de activation telemetry foi fechada, o
  contrato app-facing de `/ai/commander-learning` foi documentado, e a rota de
  learned deck availability agora e auth-only no middleware de IA.
- **Evidencia atualizada**:
  - O app envia `POST /ai/optimize` em
    `app/lib/features/decks/providers/deck_provider_support_ai.dart:56`. A rota
    exige usuario autenticado em `server/routes/ai/optimize/index.dart:479`-`:480`
    e passa `authenticatedUserId` para `loadOptimizeDeckContext` em `:560`-`:575`.
    O helper consulta `decks` por `id + user_id` em
    `server/lib/ai/optimize_request_support.dart:64`-`:84`.
  - O contexto principal de optimize carrega `$semanticV2Select` e
    `$functionalTagsSelect` em
    `server/lib/ai/optimize_request_support.dart:97`-`:123`. O classificador de
    roles declara precedencia `functional_tags -> semantic_tags_v2 ->
    heuristica` em `server/lib/ai/optimization_functional_roles.dart:301`-`:338`.
  - `POST /ai/archetypes` le `userId` e busca o deck por `id + user_id` em
    `server/routes/ai/archetypes/index.dart:35`-`:47`.
  - `OptimizeJobStore.create` exige `String userId` em
    `server/lib/ai/optimize_job.dart:32`-`:37`; o polling rejeita
    `job.userId.isEmpty || job.userId != userId` em
    `server/routes/ai/optimize/jobs/[id].dart:26`-`:47`. O mesmo padrao existe
    para generate em `server/lib/ai_generate_job.dart:18`-`:23` e
    `server/routes/ai/generate/jobs/[id].dart:16`-`:27`.
  - `app/lib/features/decks/providers/deck_provider.dart:603`-`:614` emite
    `deck_rebuild_created` quando rebuild cria draft. A rota
    `server/routes/users/me/activation-events/index.dart:10`-`:18` agora inclui
    esse evento em `_allowedEvents`, e
    `server/doc/API_CONTRACTS_AND_DATA_MAP.md:61` documenta o evento aceito.
    `server/test/activation_events_contract_test.dart:7`-`:20` guarda a
    coerencia entre eventos emitidos pelo provider e eventos aceitos pela rota.
  - `app/lib/features/decks/screens/deck_generate_screen.dart:127`-`:130` carrega
    learned decks no primeiro frame; `:132`-`:143` indexa a disponibilidade por
    comandante; o provider chama
    `GET /ai/commander-learning` em
    `app/lib/features/decks/providers/deck_provider.dart:804`-`:824` e a rota
    retorna `commanders[]` em
    `server/routes/ai/commander-learning/index.dart:20`-`:27`. Com query, o app
    chama `fetchCommanderLearningDeck` em
    `app/lib/features/decks/providers/deck_provider.dart:778`-`:801`, e a rota
    retorna `promoted_deck`/`recommended_deck` em
    `server/routes/ai/commander-learning/index.dart:43`-`:53`.
  - A rota de learned decks le `commander_learned_decks` em
    `server/routes/ai/commander-learning/index.dart:69`-`:94` e `:112`-`:178`;
    o schema/modelo fica em
    `server/lib/ai/commander_learned_deck_support.dart:7` e `:283`-`:315`.
    `server/doc/API_CONTRACTS_AND_DATA_MAP.md:290` documenta o endpoint, as
    variantes sem/com `commander`, consumidores, payloads, data source e
    ausencia de chamada OpenAI/externa; `:313` lista `commander_learned_decks`
    nos data sources AI/meta.
  - `server/routes/ai/_middleware.dart:16`-`:31` separa `authOnlyHandler` de
    `costlyAiHandler` e envia o path exato `/ai/commander-learning` para o
    handler auth-only em `:27`-`:29`.
  - `server/test/api_contracts_data_map_guard_test.dart:39`-`:54` exige a linha
    de contrato de `/ai/commander-learning`; `server/test/commander_learned_deck_support_test.dart:160`-`:169`
    guarda o bypass auth-only; `server/test/ai_generate_learning_boundary_test.dart:46`-`:60`
    preserva `/ai/commander-learning` como rota explicita de learned decks.
  - `cd server && dart analyze routes/ai/commander-learning/index.dart routes/users/me/activation-events/index.dart routes/ai/_middleware.dart test/activation_events_contract_test.dart test/ai_generate_learning_boundary_test.dart test/api_contracts_data_map_guard_test.dart`
    retornou `No issues found!`. As suites
    `activation_events_contract_test.dart`, `ai_generate_learning_boundary_test.dart`,
    `api_contracts_data_map_guard_test.dart` e
    `commander_learned_deck_support_test.dart` passaram.
  - Limite local: `cd app && flutter test --no-pub ...` nao executou testes
    porque `app/.dart_tool/package_config.json` esta ausente; `app/pubspec.yaml`
    declara `flutter_test`, mas sem package config o runner nao resolveu a
    dependencia.
- **Impacto**: o risco de acesso cross-owner nos fluxos principais de optimize
  continua removido. Os tres riscos remanescentes de confiabilidade/contrato
  desta secao foram fechados no checkout atual; o risco residual e manter os
  source guards quando o fluxo de learned decks evoluir.
- **Acao recomendada**:
  1. manter `activation_events_contract_test.dart` quando novos eventos forem
     emitidos pelo app;
  2. manter `api_contracts_data_map_guard_test.dart` quando endpoints
     app-facing forem adicionados ao fluxo de IA/decks;
  3. preservar a decisao auth-only de `/ai/commander-learning` enquanto a rota
     seguir sendo leitura local de PostgreSQL sem chamada LLM/externa;
  4. manter testes owner vs non-owner para qualquer rota nova que aceite
     `deck_id`, usando optimize/archetypes como padrao positivo atual.
- **Validacao**:
  - `cd server && dart test test/activation_events_contract_test.dart test/ai_generate_learning_boundary_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`;
  - `cd server && dart test test/commander_learned_deck_support_test.dart -r expanded`;
  - apos restaurar `app/.dart_tool/package_config.json`, rodar
    `cd app && flutter test --no-pub test/features/decks/screens/deck_flow_entry_screens_test.dart test/features/decks/providers/deck_provider_test.dart`.

### P2/P3 — Decidir destino de tabelas PostgreSQL persistidas sem consumidor claro
- **Status 2026-06-19 15:00 UTC: REVALIDADO no checkout `f80b2da2`.**
  A rodada local focada em `postgresql-tables-not-used` encontrou delta amplo
  desde `cac5012b`, mas nao confirmou novo achado P1/P2 app-facing de tabela
  PostgreSQL totalmente sem uso. O auditor base executou com sucesso
  (`221` arquivos backend, `116` tabelas PostgreSQL textualmente
  referenciadas, `0` imports quebrados), mas ainda e textual e limitado a
  `server/lib`/`server/routes`; a classificacao abaixo veio de varredura manual
  de DDL versus `SELECT/JOIN/INSERT/UPDATE/DELETE` em
  `server/database_setup.sql`, `server/bin`, `server/lib`, `server/routes` e
  `app/lib`.
- **Evidência**:
  - `deck_matchups` e uma suspeita descartada: e definida em
    `server/database_setup.sql:245`, recebe upsert em
    `server/routes/ai/simulate-matchup/index.dart:392`, le historico em
    `:458`-`:459` e retorna `stored_matchup.previous` em `:430`-`:431`.
  - `deck_weakness_reports` e uma suspeita descartada: e definida em
    `server/database_setup.sql:509`, recebe insert em
    `server/routes/ai/weakness-analysis/index.dart:602`, le historico em
    `:690`-`:709` e retorna `history` em `:677`.
  - `ml_prompt_feedback` e definida em `server/database_setup.sql:550`, recebe
    insert via `server/lib/ml_knowledge_service.dart:264`, tem chamador runtime
    em `server/routes/ai/optimize/index.dart:761` por meio de
    `server/lib/ai/optimize_feedback_support.dart:94`, e `/ai/ml-status` conta
    rows em `server/routes/ai/ml-status/index.dart:108`. A busca focada ainda
    encontrou apenas `COUNT(*)`, nenhum consumidor de payload para
    selecao/score de prompt.
  - `commander_reference_decks` e `commander_reference_deck_cards` sao definidas
    em `server/lib/ai/commander_reference_deck_corpus_support.dart:1166` e
    `:1189`; recebem insert/delete/insert em `:1234`, `:1318` e `:1334`, mas
    nao possuem `SELECT/JOIN` runtime confirmado. O produto consome o agregado
    `commander_reference_deck_analysis` em `:378`.
  - `deck_learning_events` foi descartada como achado: existe em
    `server/database_setup.sql:364` e `server/bin/migrate.dart:681`;
    `server/lib/ai/deck_learning_event_support.dart:226` e `:254` escrevem
    eventos; `server/bin/pull_learning_events.py:76` le pendentes e `:158`
    marca sincronizados.
  - `commander_card_usage` foi descartada como achado: existe em
    `server/database_setup.sql:383` e `server/bin/migrate.dart:697`;
    `server/lib/ai/deck_learning_event_support.dart:82` faz upsert e
    `loadUsageHotCardsSql` le `FROM commander_card_usage` em
    `server/lib/ai/deck_learning_event_support.dart:14`.
  - `commander_card_synergy` foi descartada como achado: o DDL fica em
    `server/lib/ai/candidate_quality_data_support.dart:76`, o snapshot de
    qualidade agrega `FROM commander_card_synergy` em `:320`, e
    `server/lib/ai/optimize_candidate_quality_support.dart:240` tambem consulta
    a tabela.
  - As tabelas `new_card_battle_rule_*`, `new_card_data_gap_review_*` e
    `new_card_candidate_*` que apareceram no classificador sao caches SQLite de
    ferramentas Python, nao tabelas PostgreSQL: por exemplo
    `server/bin/manaloom_battle_rule_focused_evidence.py:9` declara que nao
    escreve em PostgreSQL e `:19` importa `sqlite3`; o mesmo padrao aparece em
    `server/bin/manaloom_card_data_gap_review.py:5`/`:14`.
- **Impacto**: para as raws Commander Reference, acumulacao de dados sem
  politica documentada de lineage/retencao ou reprocessamento. Para
  `ml_prompt_feedback`, a coleta esta viva; o risco residual e acumular payload
  sem usar esse historico em metrica, selecao de prompt ou score.
- **Ação recomendada**:
  1. documentar as tabelas raw do Commander Reference Corpus como lineage/audit,
     com retencao e job de reprocessamento, ou persistir apenas o agregado
     consumido;
  2. usar o histórico de `ml_prompt_feedback` em metrica/selecao de prompt
     quando houver volume suficiente, ou documentar retencao de log operacional;
  3. manter `deck_matchups` e `deck_weakness_reports` fora da lista de
     write-only enquanto suas rotas continuarem lendo historico/cache.
- **Validação**:
  - `rg -n "\\b(FROM|JOIN)\\s+(commander_reference_decks|commander_reference_deck_cards)\\b" server app docs/hermes-analysis/manaloom-knowledge/scripts -g '*.dart' -g '*.py' -g '*.sh'`
    encontra consumidores reais de leitura, ou a persistencia deixa de existir
    com decisao documentada;
  - `rg -n "\\bFROM\\s+ml_prompt_feedback\\b|\\bJOIN\\s+ml_prompt_feedback\\b" server app docs/hermes-analysis/manaloom-knowledge/scripts -g '*.dart' -g '*.py' -g '*.sh'`
    encontra consumidor real do payload alem de `COUNT(*)`, ou uma decisao de
    log/retencao fica documentada;
  - testes das rotas experimentais continuam verdes;
  - contrato app-facing deixa claro se esses dados sao historico persistido ou
    apenas resposta efemera.

### P1/P2 — Remover ou documentar classes app sem uso de runtime confirmado

- **Status 2026-06-19 03:00 UTC: REVALIDADO/ABERTO no checkout `ad2238a9`.**
  Desde a rodada anterior de classes (`94f73400..HEAD`), houve delta de produto
  em backend/Hermes, rotas/testes/contratos e `deck_generate_screen.dart`, mas
  nenhum novo candidato confiavel de classe sem uso foi confirmado. O auditor
  textual executou com sucesso (`221` arquivos backend, `205` classes,
  `0` imports quebrados), mas continua limitado a inventario de
  `server/lib`/`server/routes`.
- **Evidência**:
  - `app/lib/features/home/life_counter_screen.dart:61` define
    `LifeCounterScreen`, mas `app/lib/main.dart:282`-`:284` usa
    `LotusLifeCounterScreen()` para a rota ativa. A busca focada por
    `LifeCounterScreen(` em `app/lib`, `app/test` e `app/integration_test`
    encontrou apenas o construtor da propria classe e duas instanciacoes em
    teste:
    `app/test/features/home/life_counter_screen_test.dart:36` e
    `app/test/features/home/life_counter_clone_proof_test.dart:277`.
  - `app/lib/features/decks/widgets/deck_card.dart:17` define `DeckCard`, mas a
    busca por `deck_card.dart`/`DeckCard` em `app/lib` encontrou somente o
    proprio arquivo. `DeckCard` aparece apenas nos testes
    `app/test/features/decks/widgets/deck_card_test.dart:4`/`:9` e
    `app/test/features/decks/widgets/deck_card_overflow_test.dart:4`/`:47`.
    As listagens reais usam widgets privados/locais como `_RecentDeckCard`,
    `_CommunityDeckCard`, `_FollowingDeckCard` e `_EmptyDeckCard`
    (`home_screen.dart:519`, `community_screen.dart:341`/`:542`,
    `deck_list_screen.dart:1777`).
  - `app/lib/features/decks/widgets/deck_progress_indicator.dart:295` define
    `DeckProgressChip`, sem ocorrencias alem do construtor em `app/lib`,
    `app/test` e `app/integration_test`. `DeckProgressIndicator` no mesmo
    arquivo permanece usado em `deck_details_screen.dart:403` e
    `deck_details_overview_tab.dart:328`, e nao faz parte deste achado.
  - `app/lib/features/home/lotus/lotus_presentation_mode.dart:4` define
    `LotusPresentationMode`, sem import nem chamada a `enter()`/`exit()` em
    `app/lib`, `app/test` ou `app/integration_test`.
  - `app/lib/features/decks/screens/deck_generate_screen.dart` foi o unico app
    runtime alterado nesta rodada; suas classes privadas de UI continuam
    chamadas no proprio arquivo (`_LearnedDeckCallout` em `:649`/`:1009`,
    `_ExamplePromptList` em `:672`/`:1110`, `_LearnedDeckPreviewSummary` em
    `:844`/`:1173`, `_PreviewSectionHeader` em `:848`/`:1222`,
    `_GenerateProgressPanel` em `:663`/`:1243`, `_GenerateProgressChip` em
    `:1307`/`:1319` e `_AiTrustPanel` em `:550`/`:1355`).
  - **Sem novo achado nesta revalidacao:** `LotusLifeCounterScreen` e
    `DeckProgressIndicator` seguem ativos; a saida bruta do auditor para classes
    backend e o inventario de 94 declaracoes em Dart alterado nao foram
    promovidos como achado porque sao inventario textual, nao grafo de chamadas.
- **Impacto**: classes mortas ou legadas inflacionam a superficie de manutencao,
  mantem testes que podem nao proteger o runtime real e tornam ambigua a
  documentacao de gargalos ativos.
- **Ação recomendada**:
  1. decidir se `LifeCounterScreen` e fixture/harness legado ou deve ser removido
     em favor do Lotus runtime;
  2. remover ou reconectar `DeckCard`, `DeckProgressChip` e
     `LotusPresentationMode`;
  3. atualizar/remover testes que hoje exercitam widgets fora do runtime real.
- **Validação**:
  - `rg -n '\b(LifeCounterScreen|DeckCard|DeckProgressChip|LotusPresentationMode)\b|deck_card\.dart|lotus_presentation_mode\.dart' app/lib app/test app/integration_test --glob '*.dart'`
    mostra apenas classes intencionalmente mantidas;
  - `flutter analyze --no-pub --no-fatal-infos` e suites focadas de decks/auth/life
    counter seguem verdes apos remocao ou reconexao.

## Sequência sugerida

1. **Primeiro**: manter o auditor estrutural corrigido e confrontar novas falhas com analyzer antes de abrir tasks.
2. **Segundo**: quebrar o SCC atual com menor blast radius:
   `life_counter_tabletop_engine.dart`/`life_counter_turn_tracker_engine.dart`.
   O SCC antigo de `optimize_runtime_support.dart`/
   `optimize_filler_loader_support.dart` foi fechado pela dependencia em
   modulos neutros.
3. **Terceiro**: manter `/decks/:id/recommendations` e `/ai/weakness-analysis`
   como experimentais/not-proven ate consumirem a camada semantica compartilhada
   ou terem contrato interno explicito.
4. **Quarto**: atacar duplicações de maior risco no domínio de optimize/IA.
5. **Quinto**: modularizar os arquivos gigantes do otimizador com testes de regressão.
6. **Sexto**: decidir destino das tabelas write-only/parciais remanescentes
   (`ml_prompt_feedback` e raws do Commander Reference Corpus) antes de
   expandir novas persistencias analiticas.

Resolvido em `origin/master@32418bc6`: teste de contrato de rota para
`SEMANTIC_LAYER_V2_OPTIMIZE_ENFORCEMENT=partial` /
`OPTIMIZE_SEMANTIC_V2_REJECTED`.

## Itens explicitamente não confirmados como bug real nesta rodada

- Os **178 imports quebrados** do relatório **não** foram validados como defeitos reais de código; a amostragem conferida aponta falso-positivo do auditor.
- Os achados antigos contra `deck_analysis_tab.dart`, `life_counter_screen.dart`,
  `local_test_server.dart`, `commander-learning/index.dart`, o ciclo
  Community/Social e o SCC backend de optimize nao estao abertos no checkout
  `8ddc978a`; foram substituidos pelo SCC app atual entre os engines do life
  counter.
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
- a duplicação/similaridade restante de alto risco em IA semantica e helpers
  HTTP cair significativamente;
- os maiores arquivos do domínio de optimize reduzirem tamanho e responsabilidade.
