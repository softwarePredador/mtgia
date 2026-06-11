# Plano de Correcao — Audit de Estrutura

> Status atual: plano de correcao estrutural app/backend.
> Nao e contrato Hermes runtime. Use junto com `TECHNICAL_MAP.md` e revalide
> cada item antes de executar.

> Data: 2026-06-11 03:00 UTC
> Escopo: documentar problemas estruturais detectados em `STRUCTURE_AUDIT.md` sem alterar codigo de produto.

## Resumo executivo

O auditor gerava muito ruído por inferir imports relativos a partir do root do repositório, então os **178 "imports quebrados" não podiam ser tratados como defeitos reais** sem revalidação por `dart analyze` ou por resolução relativa ao diretório do arquivo Dart. Esse P0 foi corrigido em `docs/hermes-analysis/scripts/structure_auditor.py`; a rodada local de 2026-06-10 11:00 UTC no checkout `89261c8d` reportou `Imports quebrados: 0` no recorte backend do auditor base (`server/lib` e `server/routes`). Ainda assim, a varredura ampliada app/server segue apontando frentes prioritárias de organização:

1. **P0 — Ferramenta de auditoria com falso-positivo em massa**: **RESOLVIDO na ferramenta**. Manter como lição operacional: evidência do auditor deve ser confrontada com analyzer quando apontar falhas estruturais.
2. **P1 — Concentradores de complexidade muito grandes**: `server/lib/ai/optimize_runtime_support.dart` (4197 linhas) e `server/routes/ai/optimize/index.dart` (3497 linhas) seguem como gargalos de manutenção.
3. **P1 — Duplicação de helpers e lógica espalhada**: revalidada novamente na rotacao local Codex de 2026-06-10 19:00 UTC no checkout `b0d75728`. O auditor textual executou com sucesso (`172` arquivos backend, `99` problemas textuais, `0` imports quebrados), mas a lista bruta de duplicacao continua ruidosa por capturar termos SQL/literais como funcoes. A revalidacao manual confirmou um novo cluster de risco: `DeckArchetypeAnalyzer`/`DeckArchetypeAnalyzerCore` e `assessDeckOptimizationState`/`assessDeckOptimizationStateCore` duplicam analise de deck entre rebuild e optimize. Tambem seguem abertos `resolveOptimizeArchetype`, roles funcionais altos, terrenos basicos/snow basics, trust social, logs sociais/follow, condicao de carta e CMC/tipo. Wrappers finos em `server/routes/ai/optimize/index.dart` continuam delegando para support e nao sao o corpo duplicado de maior risco.
4. **P1 — Entry point local quebrado**: **REVALIDADO/ABERTO no checkout local
   `89261c8d` em 2026-06-10 11:00 UTC**. `server/bin/local_test_server.dart:3` ainda importa
   `../.dart_frog/server.dart` estaticamente, `server/.dart_frog/server.dart`
   nao existe neste checkout, e `dart analyze bin/local_test_server.dart` falha
   com `uri_does_not_exist`.
5. **P1/P2 — Coerencia app-facing em `app/lib` ↔ `server/routes` ↔
   `server/lib`**: **REVALIDADO no checkout local `1554a1e5` em 2026-06-10
   23:00 UTC**. Os riscos anteriores de ownership em `POST /ai/optimize`,
   `POST /ai/archetypes` e polling de jobs async estao stale nesta branch:
   optimize exige usuario, verifica acesso por `deck_id + user_id`, cria jobs
   com `String userId`, polling rejeita `job.userId.isEmpty`, e archetypes
   tambem escopa o deck por `id + user_id`. O contexto principal de optimize
   agora carrega `card_function_tags` junto de `semantic_tags_v2`. Permanecem
   abertos tres gaps: o app emite `deck_rebuild_created`, mas `_allowedEvents`
   rejeita o evento; `GET /ai/commander-learning` e consumido pela tela de
   geracao e passa por rota/helper/tabela reais, mas nao esta no API contract
   map; e a consulta automatica de learned decks usa middleware de IA custosa
   apesar de ser leitura local de `commander_learned_decks`.
6. **P1 — Politicas por nome / semantica de cartas**: revalidado novamente em
   2026-06-11 05:30 UTC no checkout `f1de55ef`. `commander_fallback_policy.dart`
   agora existe e centraliza parte relevante das listas de optimize/complete e
   candidate quality, com teste de versao. Ainda permanecem riscos inline em
   `functional_card_tags.dart`, `optimization_functional_roles.dart`,
   `rebuild_guided_service.dart`, `/decks/:id/recommendations`,
   `/ai/weakness-analysis`, no mock runtime de `/ai/optimize` quando
   `deckOptimizer == null`, em prompts runtime carregados por `otimizacao.dart`
   e no meta shell classifier por nomes/keywords. Exemplos de UI/import,
   fixtures, docs/artifacts e seeds Commander Reference seguem separados como
   allowed/allowed-with-caution. `edh_bracket_policy.dart` continua excecao
   intencional por regra externa/curadoria de bracket, com teste dedicado.
7. **P2/P3 — Tabelas PostgreSQL write-only ou parcialmente consumidas**:
   revalidado na rotacao local Codex de 2026-06-10 15:00 UTC no checkout
   `7cdd8a6e`; a rodada de coerencia de 2026-06-10 23:00 UTC nao refez essa
   auditoria de tabelas. Ajuste de stale claim: no checkout `1554a1e5`,
   `commander_learned_decks`, `deck_learning_events` e `commander_card_usage`
   existem em `server/database_setup.sql` e em `server/lib/ai/*`; portanto,
   qualquer formulacao dizendo que esses nomes aparecem apenas em docs
   historicos nao vale para a branch atual. O foco aberto desta rodada e
   documentar o contrato app-facing de `/ai/commander-learning`, nao reclassificar
   o uso de todas as tabelas.
8. **P1/P2 — Classes app sem uso de runtime confirmado**: revalidado novamente
   na rotacao local Codex de 2026-06-11 03:00 UTC no checkout `57f52c45`.
   `LifeCounterScreen` segue como caminho legado/test-only enquanto a rota viva
   usa `LotusLifeCounterScreen`; `DeckCard` continua testado mas sem
   import/chamada na listagem real; `DeckProgressChip` nao tem chamada de
   construtor; e `LotusPresentationMode` nao tem import nem chamada para
   `enter()`/`exit()`. A claim anterior contra `AuthVisualShell`,
   `AuthBrandHeader` e `AuthFormSurface` esta stale: login e register agora
   importam e instanciam os tres widgets. Controles positivos desta rodada
   descartaram `LotusLifeCounterScreen`, `DeckProgressIndicator`, o shell auth
   e candidatos backend de baixa contagem; a varredura textual ampla nao foi
   usada para acusar DTOs/helpers locais sem evidencia adicional.
9. **P1/P2 — Drift entre deck analysis e optimize**: revalidado no checkout
   `f1de55ef`. Deck analysis e o contexto principal de optimize carregam
   `card_function_tags` + `semantic_tags_v2`, e validator/quality gate ja tem
   cobertura para multi-role e precedencia persistida. O risco atual esta nos
   paths legacy de optimize que colapsam o conjunto de roles em um papel unico
   (`inferFunctionalRole`/`_legacyOptimizeRoleForResolvedRoles`), em
   `removals_detailed` sem tags persistidas, e em endpoints experimentais como
   `/decks/:id/recommendations` e `/ai/weakness-analysis`, que ainda nao
   carregam as fontes persistidas antes de chamar o adapter.
10. **P2 — Bracket state em fillers de optimize/complete**: **RESOLVIDO em
    `origin/master@1aa4da71`**. Os loaders de fillers agora recebem estado
    atual/virtual do deck e nao usam fallback `bracket: null` quando o bracket
    foi definido.
11. **P3 — Diagnosticos de bracket em sucesso parcial do optimize**:
    **RESOLVIDO em `origin/master@4913a733`**. Sucessos com sugestoes filtradas
    por bracket podem expor `optimize_diagnostics.bracket_policy`, mantendo
    `warnings.blocked_by_bracket` para compatibilidade.
12. **P1/P2 — Funcoes publicas sem chamador runtime**: revalidado novamente em
    2026-06-10 07:00 UTC como **ABERTO neste checkout `570ecfbc`**.
    `sync_cards_utils.dart` segue importado apenas por teste, enquanto
    `server/bin/sync_cards.dart` mantem copias privadas para parte do mesmo
    contrato (`_parseSinceDays`, `_getNewSetCodesSinceFromData` e
    `_extractCardRowFromSet`). Tambem seguem sem chamador runtime confirmado
    wrappers/helpers em request trace, Commander Reference, MTGTop8, candidate
    quality, optimize utility samples, `MLKnowledgeService.recordFeedback`,
    `ApiClient.loadTokenFromDisk`, API manual/custom metrics/debug de
    `PerformanceService` e conveniencias EDHREC/cache (`getTopByCategory`,
    `calculateFitScore`, `cleanupCache`, `isHighSynergy`,
    `EndpointCache.clearExpired`). Novos candidatos adicionados nesta rodada:
    `BinderProvider.applyFilters`, `CommunityProvider.clearFilters`,
    `DeckProvider.clearAllCache`, `hasSuspiciousNonLandCmc`,
    `OptimizeIntensityConfig.clampRequestedSwapCount`,
    `ArchetypeCountersService.upsertCounter` e
    `PushNotificationService.sendToMultipleTokens`. Controles positivos:
    observabilidade automatica (`init`, observer de tela e `traceAsync` em
    smoke), `safeCmcForOptimization`, EDHREC `getHighSynergyCards`,
    `NotificationService.create` -> `sendToUser`, e os fluxos app que usam
    `fetchBinderDirect`/`fetchPublicDecks` em vez dos wrappers sem chamador.
13. **P1/P2 — Imports quebrados e ciclo app/server**: **REVALIDADO/ABERTO no
    checkout local `89261c8d` em 2026-06-10 11:00 UTC.** O auditor base reportou
    `Imports quebrados: 0` em `server/lib`/`server/routes`, e o import historico
    de `server/routes/ai/commander-learning/index.dart:4` deixou de estar
    quebrado porque `server/lib/ai/commander_learned_deck_support.dart` existe
    neste checkout e `dart analyze routes/ai/commander-learning/index.dart`
    retornou `No issues found`. A varredura local ampliada encontrou 3 imports locais
    quebrados em 426 arquivos: `app/lib/features/decks/widgets/deck_analysis_tab.dart:5`
    (`../../../../core/utils/mana_helper.dart`) resolvendo para
    `app/core/utils/mana_helper.dart`,
    `app/lib/features/home/life_counter_screen.dart:7` resolvendo para
    `app/core/theme/app_theme.dart`, e `server/bin/local_test_server.dart:3`
    resolvendo para `server/.dart_frog/server.dart`. `dart analyze
    bin/local_test_server.dart` confirma o erro backend; `flutter analyze
    --no-pub` focado no app foi nao conclusivo por falta de
    `app/.dart_tool/package_config.json`, mas incluiu os dois
    `uri_does_not_exist` locais. A varredura SCC encontrou somente um ciclo
    local: `CommunityDeckDetailScreen` e `UserProfileScreen` importam e
    instanciam uma a outra por `Navigator.push`; nenhum ciclo local backend foi
    encontrado.

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
  - `server/routes/ai/optimize/index.dart`: 3497 linhas
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
- **Status 2026-06-10 19:00 UTC: REVALIDADO/ABERTO no checkout `b0d75728`.**
  O auditor textual apontou `99` problemas, mas a parte de duplicacao segue
  limitada por falsos positivos de SQL/literais; este item usa apenas evidencia
  revalidada por `rg` e leitura direta. A nova rodada adicionou o cluster
  `DeckArchetypeAnalyzer`/`DeckArchetypeAnalyzerCore` como achado confirmado.
- **Evidência**:
  - `DeckArchetypeAnalyzer` em `server/lib/ai/deck_state_analysis.dart:1`-`:279`
    e `DeckArchetypeAnalyzerCore` em
    `server/lib/ai/optimize_state_support.dart:6`-`:287` implementam o mesmo
    contrato de CMC medio, contagem de tipos, deteccao de arquetipo, analise de
    mana base, curva e confianca. `server/lib/ai/rebuild_guided_service.dart:139`-`:141`
    usa a primeira copia; `server/lib/ai/optimize_request_support.dart:264`
    e `server/lib/ai/optimize_complete_support.dart:265` usam a segunda.
  - `assessDeckOptimizationState` em
    `server/lib/ai/deck_state_analysis.dart:308`-`:468` e
    `assessDeckOptimizationStateCore` em
    `server/lib/ai/optimize_state_support.dart:337`-`:497` repetem a mesma
    avaliacao de deck incompleto, formato, cores, texto do comandante,
    severidade e plano de reparo, apenas mudando o DTO retornado. A rota
    `server/routes/ai/optimize/index.dart:310`-`:326` e wrapper/adaptador fino
    para a versao core, mas rebuild usa a versao antiga diretamente.
  - `resolveOptimizeArchetype` existe em
    `server/lib/ai/deck_state_analysis.dart:573`-`:585` e
    `server/lib/ai/optimize_runtime_support.dart:3369`-`:3389` com contratos
    diferentes: uma versao aceita `requestedArchetype` nullable e trata
    `general/tempo` como genericos; a outra exige string, trata `unknown` e usa
    `goodstuff`/lista restrita de detected especificos. `optimize_request_support.dart`
    usa a versao de optimize, enquanto `rebuild_guided_service.dart` usa a
    versao de deck state.
  - `_looksLikeComboPiece`, `_looksLikeEnabler`, `_looksLikeEngine`,
    `_looksLikePayoff` e `_looksLikeWincon` existem tanto em
    `server/lib/ai/functional_card_tags.dart:859`-`:906` quanto em
    `server/lib/ai/optimization_functional_roles.dart:529`-`:565`, mas a
    primeira familia usa nomes conhecidos e `oracle_text`, e a segunda usa
    padroes diferentes de `oracle_text` para um role unico do optimize.
  - `_isBasicLandName` aparece em quatro locais com variantes para snow lands:
    `server/lib/ai/optimize_runtime_support.dart:4184`-`:4196`,
    `server/lib/generated_deck_validation_service.dart:752`-`:763`,
    `server/lib/meta/meta_deck_reference_support.dart:890`-`:903` e
    `server/routes/ai/commander-reference/index.dart:621`-`:628`.
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
    `server/lib/request_trace.dart:48`-`:57` ja expor wrappers de trace.
  - Condicoes `NM/LP/MP/HP/DMG` estao espalhadas entre mutacoes de deck,
    binder e marketplace; algumas rotas normalizam invalido para `NM`
    (`server/routes/decks/[id]/cards/index.dart:397`-`:403`), outras rejeitam
    com `400` (`server/routes/binder/index.dart:275`-`:280`) e o marketplace
    ignora filtros invalidos (`server/routes/community/marketplace/index.dart:39`-`:43`).
  - `getMainType` e `calculateCmc` aparecem duplicados em deck privado/publico
    (`server/routes/decks/[id]/index.dart:405`-`:435`,
    `server/routes/community/decks/[id].dart:91`-`:117`) e ha variante de CMC
    em `server/routes/decks/[id]/simulate/index.dart:171`-`:186`.
- **Impacto**: mudanca semantica em um ponto nao propaga automaticamente para os demais; risco de respostas inconsistentes por endpoint/fluxo. O risco mais alto e de IA: optimize, complete, rebuild, validator e deck analysis podem discordar sobre estado do deck, arquetipo efetivo e papel funcional de cartas.
- **Ação recomendada**:
  1. priorizar uma fonte canonica para `DeckArchetypeAnalyzer*` e
     `assessDeckOptimizationState*`, mantendo wrappers/adaptadores finos so para
     compatibilidade de DTO;
  2. unificar `resolveOptimizeArchetype` e criar testes de
     generic/unknown/null antes de mexer em heuristicas maiores;
  3. criar adapter unico de roles funcionais que aceite nome, `oracle_text`,
     `type_line`, `functional_tags` e `semantic_tags_v2`, retornando conjunto
     de roles + `primary_role`;
  4. extrair helper unico para terrenos basicos/snow basics e usar em validate,
     optimize, meta e commander-reference;
  5. agrupar duplicacoes de menor risco por dominio (trust social, request/log,
     condicao de carta, CMC/tipo), mantendo wrappers locais so quando o contrato
     divergente for intencional e testado.
- **Validação**:
  - a mesma lista de cartas produz o mesmo `detected_archetype`,
    `mana_base_assessment`, `status`, `recommended_mode` e `repair_plan` em
    optimize/complete/rebuild, salvo divergencia explicitamente testada;
  - testes de optimize/rebuild provam o mesmo arquetipo efetivo para os casos
    `midrange`, `tempo`, `goodstuff`, `unknown`, vazio e detected especifico;
  - uma carta com papeis multiplos preserva roles secundarios no validator e na
    aba de analise;
  - snow basics tem comportamento igual nos quatro fluxos;
  - listagem/detalhe de trades e marketplace continuam retornando o mesmo shape
    de `trust`;
  - `dart analyze` e suites focadas seguem verdes apos cada extracao.

### P1 — Centralizar e reduzir politicas por nome restantes
- **Status 2026-06-11 05:30 UTC: REVALIDADO/ABERTO no checkout `f1de55ef`.**
  A branch atual tem `server/lib/ai/commander_fallback_policy.dart` como policy
  versionada para denylist, premium names, staples, fallbacks e foundation
  fillers; portanto a claim antiga de policy ausente esta stale. O risco aberto
  agora e menor e mais especifico: nomes ainda vivem em classificadores
  heurísticos, endpoints experimentais e prompts, e a policy por nome ainda deve
  ser tratada como dado versionado ate virar tabela/backfill.
- **Evidencia**:
  - `server/lib/ai/commander_fallback_policy.dart:1`-`:237` centraliza listas
    por nome; `server/test/optimize_runtime_support_test.dart:279`-`:282`
    valida a versao/denylist. `server/lib/ai/optimize_runtime_support.dart:669`,
    `:1795`-`:1810` e `:1848`-`:1855`, e
    `server/lib/ai/optimize_filler_loader_support.dart:111`-`:112` e
    `:951`-`:968` consomem essa policy.
  - `server/lib/ai/functional_card_tags.dart:219`-`:226`, `:713`-`:731`,
    `:767`-`:778`, `:872`-`:888` e `:900`-`:932` ainda usa nomes conhecidos
    como fallback de classificacao funcional.
  - `server/lib/ai/optimization_functional_roles.dart:176`-`:180`,
    `:387`-`:420` e `:447`-`:529` repete parte dos checks por nomes/sets
    conhecidos.
  - `server/lib/ai/candidate_quality_data_support.dart:534`-`:545` e
    `:586`-`:600` aplica bonus/escopo por nomes vindos da policy central.
  - `server/lib/ai/rebuild_guided_service.dart:1226`-`:1231` classifica ramp por
    `signet`/`sol ring`/`talisman`; `:1331`-`:1338` e `:1404`-`:1411` aplica
    penalidade/prioridade a utility lands especificas.
  - `server/routes/ai/optimize/index.dart:1063`-`:1081` ainda retorna mock
    runtime com `Sol Ring` e `Arcane Signet` quando `deckOptimizer == null`.
  - `server/routes/decks/[id]/recommendations/index.dart:49`-`:67` nao carrega
    tags persistidas, recalcula buckets por `oracle_text` em `:122`-`:146`,
    recomenda `Command Tower` diretamente em `:282`-`:289`, e `_findStaples`
    usa raridade `rare/mythic` como proxy em `:478`-`:508`.
  - `server/routes/ai/weakness-analysis/index.dart:51`-`:66` nao carrega
    `card_function_tags`, `semantic_tags_v2` nem `card_role_scores`; chama
    `resolveCardFunctionalRoles` sem essas fontes em `:115`-`:122` e
    `:343`-`:357`, e ainda retorna listas fixas de recomendacao em
    `:186`-`:220` e `:293`-`:307`.
  - `server/lib/meta/meta_deck_commander_shell_support.dart:105`-`:275` deriva
    `strategy_archetype` por nomes/keywords. Risco menor que optimize direto,
    mas pode persistir sinal de meta por nome.
  - Exemplos permitidos seguem separados: `deck_import_screen.dart:383`-`:393`
    e `:588`-`:594`, `life_counter_native_card_search_sheet.dart:39`-`:44`,
    fixtures/testes e artifacts de corpus.
  - `server/lib/edh_bracket_policy.dart:312`-`:354` e `:411`-`:535` permanece
    excecao intencional por regra externa/Game Changer, com teste em
    `server/test/optimize_runtime_support_test.dart:434`-`:442`.
- **Impacto**: as decisoes mais importantes ja tem parte da policy centralizada,
  mas classificadores puros e endpoints experimentais ainda podem divergir da
  camada persistida. Bonus por nome tambem continua dificil de auditar como
  dado operacional.
- **Acao recomendada**:
  1. manter `commander_fallback_policy.dart` como ponto unico enquanto nao houver
     tabela/backfill, adicionando `source`, `reason`, `confidence` e data para
     cada entrada quando o formato sair de `const` simples;
  2. remover checks por nome de `functional_card_tags.dart` e
     `optimization_functional_roles.dart`, ou transforma-los em backfill
     persistido/policy versionada;
  3. migrar `/decks/:id/recommendations` e `/ai/weakness-analysis` para
     `card_function_tags`, `semantic_tags_v2`, role scores, legalidade,
     identidade de cor, bracket e budget antes de qualquer sugestao por nome;
  4. tratar seeds Commander Reference como corpus/profile versionado, nao
     policy global;
  5. manter `edh_bracket_policy.dart` como excecao documentada com sync/fonte e
     teste dedicado.
- **Validacao**:
  - `rg -n "Sol Ring|Command Tower|Thassa's Oracle|Isochron Scepter|Dramatic Reversal|Blood Artist" server/lib server/routes app/lib`
    so deve mostrar fixtures/docs/UI examples, seed/corpus declarado, policy
    versionada ou excecao bracket;
  - testes provam que cartas com texto equivalente e nome diferente recebem o
    mesmo role quando nao ha dado persistido;
  - scorecard prova que bonus por nome nao supera legalidade, identidade de cor,
    bracket, role_score, synergy e quality gate.

### P1/P2 — Manter adapter semantico compartilhado entre analysis, optimize e candidate quality

- **Status 2026-06-11 05:30 UTC: PARCIALMENTE SANEADO no checkout
  `f1de55ef`.** A acao antiga de "carregar `card_function_tags` no contexto
  principal de optimize" nao se aplica mais nesta branch.
- **Evidencia atualizada**:
  - `GET /decks/:id/analysis` seleciona `card_function_tags` e
    `semantic_tags_v2` em `server/routes/decks/[id]/analysis/index.dart:91`-`:96`.
  - `POST /decks/:id/ai-analysis` tambem retorna `functional_tags` e
    `semantic_tags_v2` em `server/routes/decks/[id]/ai-analysis/index.dart:130`-`:135`.
  - `loadOptimizeDeckContext` agora monta a query com `$semanticV2Select` e
    `$functionalTagsSelect` em
    `server/lib/ai/optimize_request_support.dart:97`-`:123`, insere ambos em
    `allCardData` em `:201`-`:214` e define os selects em `:359`-`:393`.
  - `classifyOptimizationFunctionalRole` le `functional_tags` e
    `semantic_tags_v2` em `server/lib/ai/optimization_functional_roles.dart:301`-`:315`;
    `optimizationFunctionalRolesForCard` preserva conjuntos multi-role em
    `:317`-`:339`.
  - `OptimizationValidator` usa roles primarios e conjuntos multi-role em
    `server/lib/ai/optimization_validator.dart:266`-`:284` e calcula
    `roleDelta` em `:317`-`:355`.
  - `optimization_quality_gate.dart:159`-`:199` prefere
    `semantic_tags_v2`, depois `functional_tags` persistidos, depois fallback
    heuristico para roles do gate.
  - Candidate quality consulta `card_role_scores`, `card_function_tags`,
    `commander_card_synergy` e rejeicoes em
    `server/lib/ai/optimize_candidate_quality_support.dart:203`-`:275`.
- **Impacto remanescente**: a branch atual esta melhor alinhada no caminho
  principal analysis/optimize/validator, mas `inferFunctionalRole` em
  `server/lib/ai/optimize_runtime_support.dart:752`-`:859` ainda colapsa
  conjuntos em roles legacy para ranking/removal/details. `server/routes/ai/optimize/index.dart:2360`-`:2384`
  tambem monta `removals_detailed` sem passar tags persistidas. Endpoints
  experimentais/legacy como `/decks/:id/recommendations` e
  `/ai/weakness-analysis` ainda precisam carregar as mesmas fontes antes de
  promocao app-facing.
- **Acao recomendada**:
  1. manter um adapter unico para `functional_tags`, `semantic_tags_v2`,
     `oracle_text`, `type_line`, `mana_cost` e `cmc`;
  2. cobrir role primario e conjunto de roles em testes de analysis, optimize,
     validator e quality gate;
  3. trocar os paths de optimize runtime que hoje usam `inferFunctionalRole`
     por `CardRoles` completo, mantendo `primary_role` apenas como compat;
  4. alinhar `candidate_quality_sources` com as fontes realmente consultadas ou
     documentar quais fontes sao apenas diagnostico;
  5. antes de promover endpoints experimentais, exigir que reutilizem o mesmo
     adapter ou declarem contrato interno separado.
- **Validacao**:
  - carta com `functional_tags=[draw]` e sem `semantic_tags_v2` e tratada como
    draw em analysis, validator e quality gate;
  - carta com `semantic_tags_v2.tags=[draw, engine]` preserva multi-role onde o
    contrato exigir;
  - optimize deterministic removal/details preserva o conjunto
    `draw + engine` em contagem, risco e payload app-facing;
  - testes de candidate quality mostram fontes reais em
    `candidate_quality_sources`;

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
- **Status 2026-06-10 11:00 UTC: REVALIDADO/ABERTO no checkout local
  `89261c8d`.** A resolucao historica citada para `origin/master@a830f9f3` nao
  esta presente nesta branch de memoria.
- **Evidência**:
  - `dart analyze bin/local_test_server.dart` em `server/` falhou com:
    - `bin/local_test_server.dart:3:8 - Target of URI doesn't exist: '../.dart_frog/server.dart'`
  - `server/bin/local_test_server.dart:3` importa `../.dart_frog/server.dart`
    estaticamente.
  - `server/.dart_frog/server.dart` nao existe neste checkout.
- **Impacto**: bloqueia validação estrutural automatizada e reduz confiança em checks rápidos do backend.
- **Ação recomendada**:
  1. decidir se `bin/local_test_server.dart` exige geração prévia obrigatória de `.dart_frog/server.dart`;
  2. documentar ou automatizar esse passo no fluxo local;
  3. se o arquivo não for mais usado, substituir por entry point resiliente ou removê-lo.
- **Validação**:
  - `dart analyze` em `server/` deixa de falhar por
    `../.dart_frog/server.dart`.
  - Se o wrapper continuar existindo, `PORT=18082 dart run bin/local_test_server.dart`
    deve emitir erro operacional claro quando `.dart_frog/server.dart` nao
    existir, ou iniciar o servidor quando o artefato estiver presente.

### P1 — Corrigir imports quebrados no app e no entrypoint local do backend

**Status 2026-06-10 11:00 UTC: REVALIDADO/ABERTO no checkout local
`89261c8d`.** As resolucoes historicas citadas para `origin/master@640f4ab4` e
`origin/master@a830f9f3` nao estao refletidas nesta branch de memoria.

- **Evidência**:
  - `app/lib/features/decks/widgets/deck_analysis_tab.dart:5` importa
    `../../../../core/utils/mana_helper.dart`, que resolve para
    `app/core/utils/mana_helper.dart`; o arquivo real esta em
    `app/lib/core/utils/mana_helper.dart`.
  - `app/lib/features/home/life_counter_screen.dart:7` importa
    `../../../core/theme/app_theme.dart`, que resolve para
    `app/core/theme/app_theme.dart`; o arquivo real esta em
    `app/lib/core/theme/app_theme.dart`.
  - `server/bin/local_test_server.dart:3` importa
    `../.dart_frog/server.dart`; `dart analyze` confirma `uri_does_not_exist`
    porque `server/.dart_frog/server.dart` nao existe no checkout atual.
  - O import historico de `server/routes/ai/commander-learning/index.dart:4`
    para `server/lib/ai/commander_learned_deck_support.dart` nao esta mais
    quebrado neste checkout; o arquivo alvo existe e
    `dart analyze routes/ai/commander-learning/index.dart` retornou
    `No issues found`.
  - `flutter analyze --no-pub --no-fatal-infos` focado nesses dois arquivos do
    app foi nao conclusivo por falta de `app/.dart_tool/package_config.json`,
    mas a saida incluiu `uri_does_not_exist` para os dois imports locais acima.
- **Impacto**: builds/checks com package config valido tendem a falhar no app
  quando esses arquivos entram no grafo; no backend, `dart analyze` segue
  bloqueado pelo entrypoint local.
- **Ação recomendada**:
  1. corrigir a profundidade dos dois imports relativos do app ou migrar para
     imports `package:manaloom/...` consistentes;
  2. decidir se `local_test_server.dart` deve gerar/depender explicitamente do
     artefato Dart Frog ou sair do conjunto analisado;
  3. apos `flutter pub get`, rerodar `flutter analyze --no-pub --no-fatal-infos`
     para confirmar que os imports locais nao voltam a falhar.
- **Validação**:
  - resolvedor local de imports reporta 0 imports quebrados em `server/` e
    `app/`;
  - `dart analyze` em `server/` deixa de falhar por
    `../.dart_frog/server.dart`;
  - `flutter analyze` roda com `app/.dart_tool/package_config.json` presente e
    sem `uri_does_not_exist` para os imports core corrigidos.

### P2 — Quebrar o ciclo direto entre `CommunityDeckDetailScreen` e `UserProfileScreen`

**Status 2026-06-10 11:00 UTC: REVALIDADO/ABERTO no checkout local
`89261c8d`.** A resolucao historica citada para `origin/master@640f4ab4` nao
esta refletida nesta branch de memoria; o grafo local focado ainda encontrou 1
SCC com esses dois arquivos.

- **Evidência**:
  - `app/lib/features/community/screens/community_deck_detail_screen.dart:8`
    importa `../../social/screens/user_profile_screen.dart` e navega para
    `UserProfileScreen` em `:213`.
  - `app/lib/features/social/screens/user_profile_screen.dart:7` importa
    `../../community/screens/community_deck_detail_screen.dart` e navega para
    `CommunityDeckDetailScreen` em `:469`.
  - A rodada focada de 426 arquivos Dart encontrou 1 unico SCC com mais de um
    arquivo, composto por essas duas telas; nao encontrou ciclos locais no
    backend.
- **Impacto**: `community` e `social` ficam acoplados por classes concretas de
  tela, dificultando teste isolado, reorganizacao de rotas e evolucao de cada
  dominio.
- **Ação recomendada**:
  1. mover a navegacao cruzada para GoRouter/rotas nomeadas ou para helper de
     navegacao fora dos dois dominios;
  2. alternativamente, injetar callbacks de navegacao para evitar import mutuo
     entre as telas;
  3. manter testes de perfil/comunidade cobrindo os dois caminhos de navegacao.
- **Validação**:
  - grafo local de imports retorna `SCCS 0`;
  - `profile_community_runtime_test.dart` ou teste equivalente continua cobrindo
    abrir perfil a partir de deck publico e abrir deck publico a partir do
    perfil.

### P1 — Religar ou remover helpers publicos sem chamador runtime

**Status 2026-06-07 07:00 UTC:** **REABERTO no checkout local
`codex/hermes-analysis-docs@82bb454e`**. As anotacoes historicas de resolucao em
outros SHAs nao representam o estado desta branch: os helpers abaixo continuam
presentes e sem chamador runtime confirmado; a rodada tambem encontrou um helper
app-side novo sem chamada.

- **Evidência**:
  - `server/lib/sync_cards_utils.dart:16`, `:82`, `:102`, `:116`, `:161` e
    `:172` definem helpers cobertos por `server/test/sync_cards_test.dart`, mas
    `rg "sync_cards_utils"` nao encontrou import desse arquivo em `server/bin`,
    `server/lib` runtime ou rotas. `server/bin/sync_cards.dart:64` chama
    `_parseSinceDays`, definido em `:349`-`:357`; `:131` chama
    `_getNewSetCodesSinceFromData`, definido em `:386`-`:402`; `:577` chama
    `_extractCardRowFromSet`, definido em `:662`-`:710`.
  - `server/lib/request_trace.dart:48` e `:51` definem
    `getRequestTrace`/`tryGetRequestId`; os consumidores reais usam
    `context.read<RequestTrace>()` diretamente, por exemplo
    `server/lib/auth_middleware.dart:57`, `server/lib/observability.dart:225`,
    `server/routes/trades/index.dart:332` e
    `server/routes/conversations/[id]/messages.dart:249`.
  - `server/lib/ai/commander_reference_profile_support.dart:49` define
    `normalizedCommanderReferenceCandidate`; consumidores ativos usam
    `normalizeCommanderReferenceName` diretamente.
  - `server/lib/ai/commander_reference_card_stats_support.dart:257` define
    `buildLoreholdReferenceCardStatsFromProfile`, mas a busca encontrou apenas
    teste e definicao; o builder generico e usado no runtime em `:368`.
  - `server/lib/meta/mtgtop8_meta_support.dart:139` define
    `extractMtgTop8FormatCodeFromSourceUrl`; a busca encontrou apenas teste e
    definicao. O helper de event id vizinho segue usado pelo reparo operacional.
  - `server/lib/ai/candidate_quality_data_support.dart:631` define
    `buildCandidateQualitySamplePoolSql`; o runner operacional monta pools por
    `_loadCandidateCards`/`_buildSampleCandidatePools`.
  - `server/lib/ai/optimize_runtime_support.dart:3326` define
    `summarizeAggressiveOptimizeUtilitySamples`; a busca encontrou apenas teste
    e definicao.
  - `app/lib/core/api/api_client.dart:128` define
    `ApiClient.loadTokenFromDisk()`, cujo comentario diz que e chamado 1x no
    boot, mas `rg "loadTokenFromDisk" app/lib app/test app/integration_test`
    encontrou somente a definicao. O boot real le `auth_token` em
    `app/lib/features/auth/providers/auth_provider.dart:37`-`:46` e chama
    `ApiClient.setToken(savedToken)`.
  - `app/lib/core/services/performance_service.dart:110`, `:130`, `:200`,
    `:210`, `:220` e `:248` expõem traces/metricas/debug manuais sem chamador
    em `app/lib`, `app/test` ou `app/integration_test`; o app usa `init` em
    `app/lib/main.dart:121`, `PerformanceNavigatorObserver` chama
    `startScreenTrace`/`stopScreenTrace` em `performance_service.dart:295`,
    `:307`, `:334` e `:339`, e `traceAsync` aparece no smoke de observabilidade.
  - `server/lib/ai/edhrec_service.dart:333`, `:355`, `:363` e `:399` expõem
    `getTopByCategory`, `calculateFitScore`, `cleanupCache` e `isHighSynergy`
    sem chamador confirmado. Controle positivo: `getHighSynergyCards` e chamado
    em `server/lib/ai/otimizacao.dart:112`, `:120`, `:313` e `:321`.
  - `server/lib/endpoint_cache.dart:32` define `EndpointCache.clearExpired`,
    sem chamada confirmada; `EndpointCache.instance.get/set` seguem vivos em
    rotas de cards, sets, archetypes e generate performance support.
- **Impacto**: cobertura pode estar validando caminhos mortos, especialmente no
  caso de helpers publicos test-only. O risco mais alto e o sync de cartas,
  porque o teste cobre uma copia que nao participa do CLI operacional.
- **Ação recomendada**:
  1. decidir se `sync_cards_utils.dart` e fonte compartilhada real ou harness
     legado; se for fonte real, importar no CLI e remover as copias privadas;
  2. para cada wrapper test-only, ligar ao runner/rota esperado ou remover o
     helper e o teste correspondente;
  3. remover `ApiClient.loadTokenFromDisk()`/comentario ou religar
     explicitamente ao boot se esse for o contrato desejado;
  4. manter `PerformanceService` como API publica apenas se houver plano de
     observabilidade mobile/manual traces; caso contrario, simplificar para
     `init` + observer + `traceAsync`;
  5. transformar conveniencias EDHREC/cache sem consumidor em private/remover,
     ou ligar a rotina real com teste;
  6. continuar usando busca de chamadores como guardrail antes de adicionar
     novos helpers publicos.
- **Validação**:
  - `grep -RIn "sync_cards_utils" server` encontra o binario ativo, ou o arquivo
    deixa de existir;
  - `dart analyze` e testes focados do sync/Commander Reference/meta/candidate
    quality continuam verdes;
  - busca por simbolo encontra chamador runtime ou nenhum simbolo residual.

### P1/P2 — Alinhar contratos app-facing entre `app/lib`, rotas e helpers
- **Status 2026-06-10 23:00 UTC:** REVALIDADO/ABERTO no checkout local
  `1554a1e5`. Os achados anteriores de ownership em `/ai/optimize`,
  `/ai/archetypes` e jobs async de optimize/generate estao resolvidos nesta
  branch e foram removidos da lista de acoes abertas. A lacuna ativa agora e
  mais estreita: activation telemetry rejeita um evento emitido pelo app,
  `/ai/commander-learning` e app-facing mas nao esta no API contract/data map, e
  a disponibilidade automatica de learned decks usa o mesmo middleware de IA
  custosa das rotas com LLM.
- **Evidencia atualizada**:
  - O app envia `POST /ai/optimize` em
    `app/lib/features/decks/providers/deck_provider_support_ai.dart:56`. A rota
    exige usuario autenticado em `server/routes/ai/optimize/index.dart:451`-`:454`,
    verifica acesso antes de criar job async em `:466`-`:488` e passa
    `authenticatedUserId` para `loadOptimizeDeckContext` em `:569`-`:580`.
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
    `deck_rebuild_created` quando rebuild cria draft; a rota
    `server/routes/users/me/activation-events/index.dart:10`-`:18` nao inclui
    esse evento em `_allowedEvents` e rejeita fora da lista em `:46`-`:48`.
  - `app/lib/features/decks/screens/deck_generate_screen.dart:41`-`:43` carrega
    learned decks no primeiro frame; o provider chama
    `GET /ai/commander-learning` em
    `app/lib/features/decks/providers/deck_provider.dart:804`-`:824` e a rota
    retorna `commanders[]` em
    `server/routes/ai/commander-learning/index.dart:20`-`:27`. Com query, o app
    chama `fetchCommanderLearningDeck` em
    `app/lib/features/decks/providers/deck_provider.dart:778`-`:801`, e a rota
    retorna `promoted_deck`/`recommended_deck` em
    `server/routes/ai/commander-learning/index.dart:43`-`:53`.
  - A rota de learned decks le `commander_learned_decks` em
    `server/routes/ai/commander-learning/index.dart:67`-`:92` e `:110`-`:132`;
    o schema/modelo fica em
    `server/lib/ai/commander_learned_deck_support.dart:7` e `:285`-`:311`.
    `rg "/ai/commander-learning" server/doc/API_CONTRACTS_AND_DATA_MAP.md`
    nao encontrou contrato, e `server/doc/API_CONTRACTS_AND_DATA_MAP.md:310`-`:315`
    nao lista `commander_learned_decks` nos data sources.
  - `server/routes/ai/_middleware.dart:16`-`:20` aplica
    `aiPlanLimitMiddleware()` e `aiRateLimit()` a `/ai/commander-learning`.
    `server/lib/plan_middleware.dart:35`-`:53` bloqueia quando a cota de IA
    acaba, e `server/lib/rate_limit_middleware.dart:167`-`:170`/`:381`-`:397`
    aplica bucket AI de 10/min em producao. O handler de commander-learning e
    leitura local de PG, sem chamada OpenAI.
- **Impacto**: o risco de acesso cross-owner nos fluxos principais de optimize
  foi removido nesta branch. Os riscos remanescentes sao de confiabilidade e
  contrato: telemetria de rebuild some silenciosamente, um endpoint consumido
  pelo app nao esta documentado como app-facing, e a UI de learned deck pode
  desaparecer por plano/rate limit de IA mesmo quando a consulta e local.
- **Acao recomendada**:
  1. adicionar `deck_rebuild_created` a `_allowedEvents` com teste de rota, ou
     remover a emissao no app se rebuild nao pertence ao funil;
  2. atualizar `server/doc/API_CONTRACTS_AND_DATA_MAP.md` com
     `GET /ai/commander-learning`, payloads sem/com `commander`, consumidores,
     data source `commander_learned_decks`, testes e notas de compatibilidade;
  3. decidir se learned-deck availability deve sair do middleware de IA custosa,
     ganhar excecao documentada/testada ou ser explicitamente tratado como
     capacidade de IA sujeita a `402/429`;
  4. manter testes owner vs non-owner para qualquer rota nova que aceite
     `deck_id`, usando optimize/archetypes como padrao positivo atual.
- **Validacao**:
  - teste backend aceita ou elimina `deck_rebuild_created`, e a doc deixa de
    chamar consumidores app reais de `not proven`;
  - `API_CONTRACTS_AND_DATA_MAP.md` passa a listar `/ai/commander-learning` e
    `commander_learned_decks`;
  - teste/contrato cobre `GET /ai/commander-learning` sem query e com
    `commander`;
  - se o endpoint continuar sob `/ai`, teste cobre comportamento esperado para
    `402/429`; se for isento/movido, teste garante que a tela pode carregar
    disponibilidade sem consumir/bloquear cota de IA custosa;

### P2/P3 — Decidir destino de tabelas PostgreSQL persistidas sem consumidor claro
- **Status 2026-06-10 15:00 UTC: REVALIDADO no checkout `7cdd8a6e`.** A rodada local focada em
  `postgresql-tables-not-used` nao encontrou novos consumidores runtime para os
  pontos abaixo. `schema_migrations` foi explicitamente mantida fora do achado
  por ser tabela interna do migrador. Uma varredura focada de DDL versus
  `FROM/JOIN/INSERT/UPDATE/DELETE` encontrou 53 tabelas criadas no recorte de
  codigo e somente `commander_reference_decks`, `deck_matchups` e
  `deck_weakness_reports` com write sem `SELECT/JOIN`; `commander_reference_deck_cards`
  foi mantida como achado manual por ser raw corpus apagado/reinserido sem
  leitura de produto confirmada. `ml_prompt_feedback`
  tem apenas leitura de `COUNT(*)` operacional e helper de insert sem chamador.
  A revalidacao ajustou a formulacao para nao tratar schema/audit/counts como
  consumidores de produto. `battle_simulations`,
  `format_staples`, `archetype_counters`, `archetype_patterns`,
  `synergy_packages`, `activation_funnel_events` e `ai_user_preferences` foram
  separados como controles positivos por terem leitores runtime ou runners
  dedicados confirmados.
- **Evidência**:
  - `deck_matchups` é definida em `server/database_setup.sql:169` e recebe
    upsert em `server/routes/ai/simulate-matchup/index.dart:360`, mas nao ha
    leitor de produto confirmado; a referencia fora da rota e
    `server/bin/update_schema.dart:16`, que derruba/recria schema e nao consome
    `win_rate`/`notes`.
  - `deck_weakness_reports` é definida em `server/database_setup.sql:370` e
    `server/bin/migrate_create_missing_tables.dart:97`, recebe insert em
    `server/routes/ai/weakness-analysis/index.dart:374`, mas nao ha
    `SELECT/JOIN/UPDATE/DELETE` de produto confirmado; o campo `addressed`
    tambem nao tem fluxo de update confirmado.
  - `ml_prompt_feedback` é definida em
    `server/bin/migrate_ml_knowledge.dart:159`, mas o unico insert fica no
    helper `MLKnowledgeService.recordFeedback`
    (`server/lib/ml_knowledge_service.dart:251`, SQL em `:264`), sem chamador
    encontrado por busca focada de `recordFeedback(` em
    `server/lib`, `server/routes`, `server/bin`, `server/test` ou `app/lib`;
    `/ai/ml-status` apenas conta rows em
    `server/routes/ai/ml-status/index.dart:98`.
  - `commander_reference_decks` e `commander_reference_deck_cards` sao definidas
    em `server/lib/ai/commander_reference_deck_corpus_support.dart:1177` e
    `:1200`, recebem insert/delete/insert em `:1245`, `:1329` e `:1345`, mas
    nao possuem `SELECT/JOIN` confirmado; o produto consome o agregado
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
  - `grep -RInE "^[[:space:]]*(FROM|JOIN)[[:space:]]+(deck_matchups|deck_weakness_reports|commander_reference_decks|commander_reference_deck_cards)\\b" server/routes server/lib server/bin app`
    encontra consumidores reais de leitura, ou a persistencia deixa de existir
    com decisao documentada;
  - `grep -RIn "recordFeedback" server app` encontra chamador real, caso a
    tabela de feedback seja mantida para coleta ativa;
  - testes das rotas experimentais continuam verdes;
  - contrato app-facing deixa claro se esses dados sao historico persistido ou
    apenas resposta efemera.

### P1/P2 — Remover ou documentar classes app sem uso de runtime confirmado

- **Status 2026-06-11 03:00 UTC: REVALIDADO/ABERTO no checkout `57f52c45`.**
- **Evidência**:
  - `app/lib/features/home/life_counter_screen.dart:61` define
    `LifeCounterScreen`, mas `app/lib/main.dart:284` usa
    `LotusLifeCounterScreen()` para a rota ativa; busca em `app/lib` encontrou
    `LifeCounterScreen(` apenas no construtor da propria classe. A busca focada
    com limite de palavra encontrou instanciacao fora do arquivo apenas em
    `app/test/features/home/life_counter_screen_test.dart:36` e
    `app/test/features/home/life_counter_clone_proof_test.dart:277`.
  - `app/lib/features/decks/widgets/deck_card.dart:17` define `DeckCard`, mas a
    busca por import de `deck_card.dart` em `app/lib` nao retornou ocorrencias,
    e a busca por `DeckCard(` em `app/lib` encontrou somente o construtor.
    `DeckCard` aparece apenas nos testes
    `app/test/features/decks/widgets/deck_card_test.dart:4`/`:9` e
    `app/test/features/decks/widgets/deck_card_overflow_test.dart:4`/`:47`.
    As listagens reais usam widgets privados/locais como `_RecentDeckCard`,
    `_CommunityDeckCard`, `_FollowingDeckCard` e `_EmptyDeckCard`.
  - `app/lib/features/decks/widgets/deck_progress_indicator.dart:295` define
    `DeckProgressChip`, sem ocorrencias alem do construtor em `app/lib`,
    `app/test` e `app/integration_test`. `DeckProgressIndicator` no mesmo
    arquivo permanece usado e nao faz parte deste achado.
  - `app/lib/features/home/lotus/lotus_presentation_mode.dart:4` define
    `LotusPresentationMode`, sem import nem chamada a `enter()`/`exit()` em
    `app/lib`, `app/test` ou `app/integration_test`.
  - **Stale removido:** `AuthVisualShell`, `AuthBrandHeader` e
    `AuthFormSurface` nao fazem mais parte deste achado. `login_screen.dart:6`
    importa `auth_visual_shell.dart` e instancia os tres widgets em `:83`,
    `:86` e `:92`; `register_screen.dart:6` importa o mesmo arquivo e instancia
    os tres em `:86`, `:101` e `:108`.
  - Controles positivos desta revalidacao: `LotusLifeCounterScreen` e
    `DeckProgressIndicator` seguem ativos; o shell auth agora tambem esta
    ativo; candidatos
    backend de baixa contagem (`BattleSimulator`, `DistributedRateLimiter`,
    `RebuildGuidedService`, `SynergyEngine`) tambem tem chamador runtime
    confirmado.
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
