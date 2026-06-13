# Plano de Correcao — Audit de Estrutura

> Status atual: plano de correcao estrutural app/backend.
> Nao e contrato Hermes runtime. Use junto com `TECHNICAL_MAP.md` e revalide
> cada item antes de executar.

> Data: 2026-06-13 05:30 UTC
> Escopo: documentar problemas estruturais detectados em `STRUCTURE_AUDIT.md` sem alterar codigo de produto.

## Resumo executivo

O auditor gerava muito ruído por inferir imports relativos a partir do root do repositório, então os **178 "imports quebrados" não podiam ser tratados como defeitos reais** sem revalidação por `dart analyze` ou por resolução relativa ao diretório do arquivo Dart. Esse P0 foi corrigido em `docs/hermes-analysis/scripts/structure_auditor.py`. Na rodada local de 2026-06-12 11:00 UTC no checkout `b22063f6`, o auditor base reportou `Imports quebrados: 0` no recorte backend (`server/lib` e `server/routes`), e a varredura ampliada de 409 arquivos em `app/lib`, `server/lib`, `server/routes` e `server/bin` reportou 1082 diretivas locais resolvidas, 0 imports/exports/parts locais quebrados e 2 SCCs. A frente aberta agora e aciclicidade.

1. **P0 — Ferramenta de auditoria com falso-positivo em massa**: **RESOLVIDO na ferramenta**. Manter como lição operacional: evidência do auditor deve ser confrontada com analyzer quando apontar falhas estruturais.
2. **P1 — Concentradores de complexidade muito grandes**: `server/lib/ai/optimize_runtime_support.dart` (4197 linhas) e `server/routes/ai/optimize/index.dart` (3497 linhas) seguem como gargalos de manutenção.
3. **P1 — Duplicação de helpers e lógica espalhada**: revalidada novamente na rotacao local Codex de 2026-06-12 19:00 UTC no checkout `641a4b40`. O auditor textual executou com sucesso (`205` arquivos backend, `115` problemas textuais, `0` imports quebrados), mas a lista bruta continua ruidosa por regex e nao foi usada como evidencia direta. A revalidacao manual nao encontrou novo achado confiavel alem dos clusters ja abertos: `DeckArchetypeAnalyzer`/`DeckArchetypeAnalyzerCore`, `assessDeckOptimizationState`/`assessDeckOptimizationStateCore`, `resolveOptimizeArchetype`, roles funcionais altos, trust social, logs sociais/follow, condicao de carta e CMC/tipo. A claim antiga de terrenos basicos/snow basics segue stale porque `basic_land_utils.dart` centraliza regular/snow basics. `buildOptimizeCacheKey`/`buildOptimizeDeckSignature` e wrappers finos em `server/routes/ai/optimize/index.dart` continuam delegando para support e nao sao o corpo duplicado de maior risco.
4. **P1 — Entry point local quebrado**: **RESOLVIDO/STALE no checkout local
   `372cdfca` em 2026-06-11 11:00 UTC**. `server/bin/local_test_server.dart`
   nao importa mais `../.dart_frog/server.dart` estaticamente; valida
   `.dart_frog/server.dart` em runtime, e `dart analyze bin/local_test_server.dart`
   retornou `No issues found`.
5. **P1/P2 — Coerencia app-facing em `app/lib` ↔ `server/routes` ↔
   `server/lib`**: **REVALIDADO no checkout local `3d9fe518` em 2026-06-12
   23:00 UTC**. Os riscos anteriores de ownership em `POST /ai/optimize`,
   `POST /ai/archetypes` e polling de jobs async seguem stale nesta branch:
   optimize exige usuario, passa `userId` para o loader owner-scoped, jobs
   rejeitam owner vazio/diferente, e archetypes escopa deck por `id + user_id`.
   O contexto principal de optimize continua carregando `card_function_tags`
   junto de `semantic_tags_v2`. Permanecem abertos tres gaps: o app emite/testa
   `deck_rebuild_created`, mas `_allowedEvents` rejeita o evento; `GET
   /ai/commander-learning` e consumido pela tela de geracao e passa por
   rota/helper/tabela reais, mas nao esta no API contract map; e a consulta
   automatica de learned decks herda middleware de IA custosa apesar de ser
   leitura local de `commander_learned_decks`, sem chamada LLM/externa no
   handler.
6. **P1 — Politicas por nome / semantica de cartas**: revalidado novamente em
   2026-06-13 05:30 UTC no checkout `5f09b309`. `commander_fallback_policy.dart`
   segue como policy versionada para parte relevante das listas de
   optimize/complete e candidate quality, e `edh_bracket_policy.dart` continua
   excecao intencional por regra externa/Game Changer. Permanecem riscos inline
   em `functional_card_tags.dart`, `optimization_functional_roles.dart`,
   `candidate_quality_data_support.dart`, `rebuild_guided_service.dart`,
   `/decks/:id/recommendations`, `/ai/weakness-analysis`, no mock runtime de
   `/ai/optimize` quando `deckOptimizer == null`, em prompts runtime carregados
   por `otimizacao.dart`, em `deck_advanced_analysis.dart` e no meta shell
   classifier por nomes/keywords. Exemplos de UI/import, fixtures,
   docs/artifacts, aliases localizados e seeds Commander Reference seguem
   separados como allowed/allowed-with-caution.
7. **P2/P3 — Tabelas PostgreSQL write-only ou parcialmente consumidas**:
   revalidado na rotacao local Codex de 2026-06-11 15:00 UTC no checkout
   `76ec897f`. As claims antigas contra `deck_matchups` e
   `deck_weakness_reports` estao stale: ambas agora sao lidas no runtime e
   retornadas no payload das proprias rotas experimentais. Tambem nao devem ser
   tratadas como sem uso `commander_learned_decks`, `deck_learning_events` e
   `commander_card_usage`, que possuem writers/readers no loop Hermes. Restam
   como riscos menores as raws `commander_reference_decks` /
   `commander_reference_deck_cards` sem leitor direto confirmado e
   `ml_prompt_feedback`, que tem helper de insert sem chamador, count-only em
   `/ai/ml-status` e nenhum DDL local encontrado neste checkout.
8. **P1/P2 — Classes app sem uso de runtime confirmado**: revalidado novamente
   na rotacao local Codex de 2026-06-13 03:00 UTC no checkout `5bfc9706`.
   O auditor textual executou com sucesso (`205` arquivos backend, `196`
   classes, `0` imports quebrados), mas continua limitado a `server/lib` e
   `server/routes`; a evidencia app veio de `rg` e leitura direta.
   `LifeCounterScreen` segue como caminho legado/test-only enquanto a rota viva
   usa `LotusLifeCounterScreen`; `DeckCard` continua testado mas sem
   import/chamada na listagem real; `DeckProgressChip` nao tem chamada de
   construtor; e `LotusPresentationMode` nao tem import nem chamada para
   `enter()`/`exit()`. Nao surgiram novos achados confiaveis: low-counts de
   observabilidade, scanner, rotas, widgets de deck details e backend foram
   falsificados por chamadas runtime.
9. **P1/P2 — Drift entre deck analysis e optimize**: revalidado no checkout
   `5f09b309`. Deck analysis, `loadOptimizeDeckContext`, validator, quality gate
   e addition data de quality gate carregam ou preservam `card_function_tags` +
   `semantic_tags_v2`, com multi-role onde essas fontes chegam ao fluxo. O risco
   atual esta nos paths legacy de optimize que colapsam o conjunto de roles em um
   papel unico (`inferFunctionalRole`/`_legacyOptimizeRoleForResolvedRoles`), em
   `removals_detailed` sem threadar as tags ja presentes em `allCardData`, e em
   endpoints experimentais como `/decks/:id/recommendations` e
   `/ai/weakness-analysis`, que ainda nao carregam as fontes persistidas antes de
   chamar o adapter.
10. **P2 — Bracket state em fillers de optimize/complete**: **RESOLVIDO em
    `origin/master@1aa4da71`**. Os loaders de fillers agora recebem estado
    atual/virtual do deck e nao usam fallback `bracket: null` quando o bracket
    foi definido.
11. **P3 — Diagnosticos de bracket em sucesso parcial do optimize**:
    **RESOLVIDO em `origin/master@4913a733`**. Sucessos com sugestoes filtradas
    por bracket podem expor `optimize_diagnostics.bracket_policy`, mantendo
    `warnings.blocked_by_bracket` para compatibilidade.
12. **P1/P2 — Funcoes publicas sem chamador runtime**: revalidado novamente em
    2026-06-12 07:00 UTC como **ABERTO neste checkout `086ab624`**. O auditor
    textual executou com sucesso (`205` arquivos backend, `0` imports
    quebrados), mas nao prova ausencia de chamadas; a mutacao automatica do
    bloco gerado foi descartada antes da atualizacao manual. Permanecem abertos
    `sync_cards_utils.dart` test-only enquanto `server/bin/sync_cards.dart`
    mantem copias privadas/fluxo Python; `verifySwapIntegrity` sem chamador
    apesar de `swap_integrity` ser anexado; builders de
    `optimize_response_support.dart` ainda fora do fluxo real; wrappers app sem
    chamada (`BinderProvider.applyFilters`, `CommunityProvider.clearFilters`,
    `DeckProvider.clearAllCache`); e helpers de suporte sem chamada confirmada
    em request trace, Commander Reference, optimize utility sample, ML feedback,
    `ApiClient.loadTokenFromDisk`, performance manual/debug, EDHREC/cache, CMC
    safety/counters/push e read-side de `AiLogService`. Correcoes: helpers de
    aggressive meta/candidate quality sao usados por bins operacionais e
    `isLikelyLandCard` permanece vivo via `safeCmcForOptimization`.
13. **P1/P2 — Imports quebrados e ciclos locais**: **REVALIDADO/ABERTO no
    checkout local `b22063f6` em 2026-06-12 11:00 UTC.** O auditor base reportou
    `Imports quebrados: 0` em `server/lib`/`server/routes`, e a varredura local
    ampliada encontrou 1082 diretivas locais resolvidas, 0 imports/exports/parts
    locais quebrados e 2 SCCs em 409 arquivos. Claims anteriores contra
    `deck_analysis_tab.dart`, `life_counter_screen.dart`,
    `server/bin/local_test_server.dart` e o ciclo
    `CommunityDeckDetailScreen`/`UserProfileScreen` seguem stale. Permanecem
    abertos os mesmos 2 SCCs atuais: `life_counter_tabletop_engine.dart` ↔
    `life_counter_turn_tracker_engine.dart`, e
    `optimize_runtime_support.dart` ↔ `optimize_filler_loader_support.dart`.

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
- **Status 2026-06-12 19:00 UTC: REVALIDADO/ABERTO no checkout `641a4b40`.**
  O auditor textual apontou `115` problemas em `205` arquivos backend, mas a
  parte de duplicacao segue limitada por falsos positivos de regex e wrappers;
  este item usa apenas evidencia revalidada por `rg` e leitura direta. A rodada
  atual nao encontrou novo achado confiavel alem dos clusters ja abertos; tambem
  manteve stale a duplicacao antiga de basic lands e descartou
  `buildOptimizeCacheKey`/`buildOptimizeDeckSignature` como wrappers de
  compatibilidade sobre `optimize_cache_support.dart`.
- **Evidência**:
  - `DeckArchetypeAnalyzer` em `server/lib/ai/deck_state_analysis.dart:1`-`:210`
    e `DeckArchetypeAnalyzerCore` em
    `server/lib/ai/optimize_state_support.dart:6`-`:210` implementam o mesmo
    contrato de CMC medio, contagem de tipos, deteccao de arquetipo, analise de
    mana base, curva e confianca. `server/lib/ai/rebuild_guided_service.dart:138`-`:140`
    usa a primeira copia; `server/lib/ai/optimize_request_support.dart:286`-`:302`
    usa a segunda para o contexto de optimize.
  - `assessDeckOptimizationState` em
    `server/lib/ai/deck_state_analysis.dart:308`-`:470` e
    `assessDeckOptimizationStateCore` em
    `server/lib/ai/optimize_state_support.dart:337`-`:500` repetem a mesma
    avaliacao de deck incompleto, formato, cores, texto do comandante,
    severidade e plano de reparo, apenas mudando o DTO retornado. Rebuild usa
    a versao antiga diretamente em `server/lib/ai/rebuild_guided_service.dart:141`-`:147`
    e `:263`-`:268`; a rota optimize apenas adapta a versao core em
    `server/routes/ai/optimize/index.dart:343`-`:360`.
  - `resolveOptimizeArchetype` existe em
    `server/lib/ai/deck_state_analysis.dart:573`-`:585` e
    `server/lib/ai/optimize_runtime_support.dart:1714`-`:1734` com contratos
    diferentes: uma versao aceita `requestedArchetype` nullable e trata
    `general/tempo` como genericos; a outra exige string, trata `unknown` e usa
    `goodstuff`/lista restrita de detected especificos. `optimize_request_support.dart`
    usa a versao de optimize em `:303`-`:313`, enquanto
    `rebuild_guided_service.dart:171`-`:174` usa a versao de deck state.
  - `_looksLikeComboPiece`, `_looksLikeEnabler`, `_looksLikeEngine`,
    `_looksLikePayoff` e `_looksLikeWincon` existem tanto em
    `server/lib/ai/functional_card_tags.dart:872`-`:933` quanto em
    `server/lib/ai/optimization_functional_roles.dart:387`-`:456`, mas a
    primeira familia e a segunda mantem padroes textuais diferentes quando nao
    ha `functional_tags`/`semantic_tags_v2`. O adapter
    `resolveCardFunctionalRoles` em
    `server/lib/ai/optimization_functional_roles.dart:37`-`:91` centraliza
    precedencia de fonte, mas nao elimina os fallbacks duplicados.
  - A claim antiga de `_isBasicLandName` duplicado esta stale:
    `server/lib/basic_land_utils.dart:1`-`:47` centraliza nomes regulares,
    snow basics, normalizacao e type line; consumidores atuais importam esse
    helper em `server/lib/ai/optimize_runtime_support.dart:2`,
    `server/lib/generated_deck_validation_service.dart:3`,
    `server/lib/meta/meta_deck_reference_support.dart:5` e
    `server/routes/ai/commander-reference/index.dart:17`.
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
    (`server/routes/decks/[id]/cards/index.dart:407`-`:413`,
    `server/routes/decks/[id]/cards/set/index.dart:247`-`:253` e
    `server/routes/decks/[id]/index.dart:518`-`:524`), outras rejeitam
    com `400` (`server/routes/binder/index.dart:275`-`:280`) e o marketplace
    ignora filtros invalidos (`server/routes/community/marketplace/index.dart:39`-`:43`).
  - `getMainType` e `calculateCmc` aparecem duplicados em deck privado/publico
    (`server/routes/decks/[id]/index.dart:405`-`:435`,
    `server/routes/community/decks/[id].dart:91`-`:117`) e ha variante de CMC
    em `server/routes/decks/[id]/simulate/index.dart:199`-`:214`.
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
  4. manter `basic_land_utils.dart` como fonte canonica e remover wrappers
     locais que nao agregam contrato;
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
- **Status 2026-06-13 05:30 UTC: REVALIDADO/ABERTO no checkout `5f09b309`.**
  A branch atual tem `server/lib/ai/commander_fallback_policy.dart` como policy
  versionada para denylist, premium names, staples, fallbacks e foundation
  fillers; portanto a claim antiga de policy ausente esta stale. O risco aberto
  agora e menor e mais especifico: nomes ainda vivem em classificadores
  heurísticos, endpoints experimentais e prompts, e a policy por nome ainda deve
  ser tratada como dado versionado ate virar tabela/backfill.
- **Evidencia**:
  - `server/lib/ai/commander_fallback_policy.dart:1`-`:237` centraliza listas
    por nome; tratar essas entradas como dado versionado enquanto nao houver
    tabela/backfill equivalente.
  - `server/lib/ai/functional_card_tags.dart:219`-`:226`, `:713`-`:731`,
    `:767`-`:778`, `:872`-`:888` e `:900`-`:932` ainda usa nomes conhecidos
    como fallback de classificacao funcional.
  - `server/lib/ai/optimization_functional_roles.dart:387`-`:420`,
    `:447`-`:463` e `:491`-`:529` repete parte dos checks por nomes/sets
    conhecidos.
  - `server/lib/ai/candidate_quality_data_support.dart:376`-`:381`,
    `:422`-`:429`, `:440`-`:449`, `:475`-`:481`, `:534`-`:538` e
    `:586`-`:600` aplica tags, bonus ou escopo por nomes.
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
  - `server/lib/ai/deck_advanced_analysis.dart:43`-`:57` tambem chama
    `resolveCardFunctionalRoles` sem fontes persistidas; `:104`-`:131` e
    `:507`-`:524` usam nomes em analises de wincon/drain/protecao, e `:457`-`:477`
    retorna lista fixa para shallow card advantage.
  - `server/lib/ai/otimizacao.dart:856`-`:868` e `:1004`-`:1006` carrega
    prompts runtime (`prompt.md` e `prompt_complete.md`) que citam staples por
    nome; isso nao e branch deterministica, mas influencia a resposta de IA.
  - `server/lib/meta/meta_deck_commander_shell_support.dart:105`-`:275` deriva
    `strategy_archetype` por nomes/keywords. Risco menor que optimize direto,
    mas pode persistir sinal de meta por nome.
  - Exemplos permitidos seguem separados: `deck_import_screen.dart:383`-`:393`
    e `:588`-`:594`, `life_counter_native_card_search_sheet.dart:39`-`:44`,
    fixtures/testes e artifacts de corpus.
  - `server/lib/edh_bracket_policy.dart:335`-`:408` e `:411`-`:535` permanece
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

- **Status 2026-06-13 05:30 UTC: PARCIALMENTE SANEADO no checkout
  `5f09b309`.** A acao antiga de "carregar `card_function_tags` no contexto
  principal de optimize" nao se aplica mais nesta branch.
- **Evidencia atualizada**:
  - `GET /decks/:id/analysis` seleciona `card_function_tags` e
    `semantic_tags_v2` em `server/routes/decks/[id]/analysis/index.dart:34`-`:96`.
  - `POST /decks/:id/ai-analysis` tambem retorna `functional_tags` e
    `semantic_tags_v2` em `server/routes/decks/[id]/ai-analysis/index.dart:74`-`:135`.
  - `loadOptimizeDeckContext` insere `semantic_tags_v2` e `functional_tags` em
    `allCardData` em `server/lib/ai/optimize_request_support.dart:201`-`:214`
    e define os selects em `:359`-`:393`.
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
  - `fetchOptimizeAdditionDataForQualityGate` busca `semantic_tags_v2` e
    `functional_tags` para additions em
    `server/lib/ai/optimize_route_addition_data_support.dart:84`-`:129`.
  - Candidate quality consulta `card_role_scores`, `card_function_tags`,
    `commander_card_synergy` e rejeicoes em
    `server/lib/ai/optimize_candidate_quality_support.dart:203`-`:275`.
- **Impacto remanescente**: a branch atual esta melhor alinhada no caminho
  principal analysis/optimize/validator, mas `inferFunctionalRole` em
  `server/lib/ai/optimize_runtime_support.dart:752`-`:859` ainda colapsa
  conjuntos em roles legacy para ranking/removal/details. `server/routes/ai/optimize/index.dart:2257`-`:2260`
  monta `originalCardByName` a partir de `allCardData`, mas `:2360`-`:2384`
  monta `removals_detailed` sem passar as tags persistidas ja disponiveis. Endpoints
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
- **Status 2026-06-11 11:00 UTC: RESOLVIDO no checkout local `372cdfca`.**
  A resolucao historica ja esta refletida nesta branch de memoria.
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

**Status 2026-06-11 11:00 UTC: RESOLVIDO/STALE no checkout local `372cdfca`.**
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
  - A varredura focada de 409 arquivos em `app/lib`, `server/lib`,
    `server/routes` e `server/bin` encontrou 0 imports/exports/parts locais
    quebrados.
  - `cd server && dart analyze bin/local_test_server.dart` retornou
    `No issues found`.
  - O import historico de `server/routes/ai/commander-learning/index.dart:4`
    para `server/lib/ai/commander_learned_deck_support.dart` nao esta mais
    quebrado neste checkout; o arquivo alvo existe e
    `dart analyze routes/ai/commander-learning/index.dart` retornou
    `No issues found`.
- **Impacto atual**: nenhuma acao de correcao de import quebrado foi confirmada
  nesta rodada. `app/.dart_tool/package_config.json` ainda esta ausente, entao
  `flutter analyze --no-pub` nao foi usado como prova limpa app-side.
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

**Status 2026-06-12 11:00 UTC: REVALIDADO/ABERTO no checkout local `b22063f6`.**

- **Evidência**:
  - `app/lib/features/home/life_counter/life_counter_tabletop_engine.dart:3`
    importa `life_counter_turn_tracker_engine.dart`.
  - `life_counter_tabletop_engine.dart:429` chama
    `LifeCounterTurnTrackerEngine.sanitizeTrackerPointersForActivePlayers(...)`.
  - `app/lib/features/home/life_counter/life_counter_turn_tracker_engine.dart:2`
    importa `life_counter_tabletop_engine.dart`.
  - `life_counter_turn_tracker_engine.dart:13`, `:108`, `:165` e `:268`
    chamam `LifeCounterTabletopEngine` para detectar jogadores ativos e
    normalizar o tracker.
  - A varredura SCC de 409 arquivos/1082 diretivas locais encontrou um
    componente de 2 arquivos com essas engines.
- **Impacto**: regras de mesa e regras de turno ficam acopladas
  bidirecionalmente, o que dificulta teste unitario isolado e aumenta o risco de
  refactor parcial no life counter.
- **Ação recomendada**:
  1. mover a nocao de jogador ativo/sanitizacao compartilhada para helper neutro;
  2. ou inverter a chamada de sanitizacao para manter dependencia unidirecional;
  3. cobrir knockout/poison/commander damage + turn tracker em teste focado.
- **Validação**:
  - grafo local nao contem mais SCC entre `life_counter_tabletop_engine.dart` e
    `life_counter_turn_tracker_engine.dart`;
  - testes focados do life counter seguem verdes.

### P1/P2 — Quebrar ciclo entre runtime e filler loader do optimize

**Status 2026-06-12 11:00 UTC: REVALIDADO/ABERTO no checkout local `b22063f6`.**

- **Evidência**:
  - `server/lib/ai/optimize_runtime_support.dart:13` importa e `:14` reexporta
    `optimize_filler_loader_support.dart`.
  - `optimize_runtime_support.dart:1478` chama `loadDeterministicSlotFillers(...)`,
    definido em `server/lib/ai/optimize_filler_loader_support.dart:494`.
  - `server/lib/ai/optimize_filler_loader_support.dart:6` importa
    `optimize_runtime_support.dart`.
  - O filler loader usa helpers/constantes do runtime, incluindo
    `commanderPremiumFixingLandNames` em `:112`,
    `shouldKeepCommanderFillerCandidate(...)` em `:85`, `:641`, `:738`,
    `:941`, `:1062`, `:1186` e `:1279`, e `dedupeCandidatesByName(...)` em
    `:154`, `:650`, `:746`, `:779`, `:949`, `:983`, `:1013`, `:1068`,
    `:1090`, `:1200` e `:1305`.
  - As definicoes chamadas ficam em `optimize_runtime_support.dart:597` e `:612`.
  - A varredura SCC de 409 arquivos/1082 diretivas locais encontrou exatamente
    esse componente no backend e nenhum ciclo em `server/routes`.
- **Impacto**: a extracao do filler loader ainda nao forma uma fronteira
  aciclica; o modulo extraido depende do runtime que o importa, dificultando
  novas quebras modulares do optimize.
- **Ação recomendada**:
  1. mover dedupe/identity/filler policy compartilhados para modulo neutro;
  2. ou mover as chamadas de loader para uma camada que dependa de ambos;
  3. manter wrappers/exportacoes apenas onde forem contrato deliberado.
- **Validação**:
  - grafo local nao contem mais SCC entre `optimize_runtime_support.dart` e
    `optimize_filler_loader_support.dart`;
  - `dart analyze` e testes focados de optimize/complete seguem verdes.

### P1 — Religar ou remover helpers publicos sem chamador runtime

**Status 2026-06-12 07:00 UTC:** **REVALIDADO/ABERTO no checkout local
`086ab624`**. As anotacoes historicas de resolucao em outros SHAs nao
representam automaticamente o estado desta branch. A rodada atual manteve os
achados de maior impacto (`sync_cards_utils.dart` test-only,
`verifySwapIntegrity` sem chamador apesar de `swap_integrity` e builders de
response do optimize fora do fluxo real), corrigiu classificacoes ruidosas
(`isLikelyLandCard` e vivo; helpers de aggressive meta/candidate quality sao
consumidos por bins operacionais) e adicionou achados menores no read-side de
`AiLogService`, em `ArchetypeCountersService` e em
`PushNotificationService.sendToMultipleTokens`.

- **Evidência**:
  - `server/lib/sync_cards_utils.dart:16`, `:82`, `:102`, `:121`, `:178` e
    `:189` definem helpers cobertos por `server/test/sync_cards_test.dart`, mas
    `rg "sync_cards_utils"` nao encontrou import desse arquivo em `server/bin`,
    `server/lib` runtime ou rotas. `server/bin/sync_cards.dart:64` chama
    `_parseSinceDays`, definido em `:349`-`:357`; `:131` chama
    `_getNewSetCodesSinceFromData`, definido em `:386`-`:402`; `:577` chama
    `_extractCardRowFromSet`, definido em `:662`-`:710`; o full sync atual
    delega para `server/bin/sync_cards_full_fast.py`.
  - `server/routes/ai/optimize/index.dart:752`-`:758` anexa
    `swap_integrity`, mas `verifySwapIntegrity` em
    `server/lib/ai/optimize_swap_integrity.dart:112`-`:134` nao tem chamador em
    `server` ou `app`.
  - `server/lib/ai/optimize_response_support.dart:92` e `:125` definem
    `buildOptimizeResponse` e o top-level `respondWithOptimizeTelemetry`; a rota
    ainda define uma funcao local homonima em
    `server/routes/ai/optimize/index.dart:689`, e as chamadas da rota resolvem
    para a funcao local. Controles positivos: `buildSemanticV2OptimizeRejectedBody`
    e `attachOptimizeBracketPolicyDiagnostics` do mesmo arquivo sao chamados.
  - `server/lib/request_trace.dart:48` define `getRequestTrace`; os
    consumidores reais usam `context.read<RequestTrace>()` diretamente, por
    exemplo
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
  - `server/lib/endpoint_cache.dart:32` define `EndpointCache.clearExpired`,
    sem chamada confirmada; `EndpointCache.instance.get/set` seguem vivos em
    rotas de cards, sets, archetypes e generate performance support.
  - `app/lib/features/binder/providers/binder_provider.dart:639`,
    `app/lib/features/community/providers/community_provider.dart:179` e
    `app/lib/features/decks/providers/deck_provider.dart:1067` definem
    `applyFilters`, `clearFilters` e `clearAllCache` sem chamada runtime
    confirmada; os fluxos app usam `fetchBinderDirect`, `fetchPublicDecks` e
    invalidacao especifica de deck.
  - `server/lib/ai/cmc_safety.dart:64`,
    `server/lib/archetype_counters_service.dart:67`/`:104`/`:204`,
    `server/lib/push_notification_service.dart:295` e
    `server/lib/ai_log_service.dart:120`/`:163`/`:204` definem helpers sem
    chamada runtime confirmada; controles vivos existem para
    `safeCmcForOptimization`, uso de `ArchetypeCountersService` em rotas de
    analise/simulacao, `sendToUser` e escrita de logs via `_logService?.log`.
- **Impacto**: cobertura pode estar validando caminhos mortos, especialmente no
  caso de helpers publicos test-only. O risco mais alto e o sync de cartas,
  porque o teste cobre uma copia que nao participa do CLI operacional.
- **Ação recomendada**:
  1. decidir se `sync_cards_utils.dart` e fonte compartilhada real ou harness
     legado; se for fonte real, importar no CLI e remover as copias privadas;
  2. decidir se `swap_integrity` e contrato operacional; se for, chamar
     `verifySwapIntegrity` antes da mutacao de deck e cobrir hash/deck antigo;
  3. completar a extracao de `optimize_response_support.dart` ou remover
     builders/exportacoes que nao participam do fluxo real;
  4. para cada wrapper test-only, ligar ao runner/rota esperado ou remover o
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
  - `grep -RIn "sync_cards_utils" server` encontra o binario ativo, ou o arquivo
    deixa de existir;
  - teste de apply/optimize falha com `swap_integrity.hash` invalido ou
    `deck_signature` antigo, se o campo continuar app-facing;
  - `rg "buildOptimizeResponse|respondWithOptimizeTelemetry"` mostra um unico
    contrato de response vivo, sem builder top-level e funcao local divergentes;
  - `dart analyze` e testes focados do sync/Commander Reference/meta/candidate
    quality continuam verdes;
  - busca por simbolo encontra chamador runtime ou nenhum simbolo residual.

### P1/P2 — Alinhar contratos app-facing entre `app/lib`, rotas e helpers
- **Status 2026-06-12 23:00 UTC:** REVALIDADO/ABERTO no checkout local
  `3d9fe518`. Os achados anteriores de ownership em `/ai/optimize`,
  `/ai/archetypes` e jobs async de optimize/generate estao resolvidos nesta
  branch e foram removidos da lista de acoes abertas. A lacuna ativa agora e
  mais estreita: activation telemetry rejeita um evento emitido pelo app,
  `/ai/commander-learning` e app-facing mas nao esta no API contract/data map, e
  a disponibilidade automatica de learned decks usa o mesmo middleware de IA
  custosa das rotas com LLM.
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
    `deck_rebuild_created` quando rebuild cria draft; a rota
    `server/routes/users/me/activation-events/index.dart:10`-`:18` nao inclui
    esse evento em `_allowedEvents` e rejeita fora da lista em `:46`-`:48`.
    `app/test/features/decks/providers/deck_provider_test.dart:874`-`:891`
    espera explicitamente esse evento no provider.
  - `app/lib/features/decks/screens/deck_generate_screen.dart:36`-`:43` carrega
    learned decks no primeiro frame; `:127`-`:143` indexa a disponibilidade por
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
    `server/routes/ai/commander-learning/index.dart:67`-`:92` e `:110`-`:132`;
    o schema/modelo fica em
    `server/lib/ai/commander_learned_deck_support.dart:7` e `:283`-`:318`.
    `rg "/ai/commander-learning|commander_learned_decks" server/doc/API_CONTRACTS_AND_DATA_MAP.md`
    nao encontrou contrato nem data source, e `server/doc/API_CONTRACTS_AND_DATA_MAP.md:310`-`:315`
    nao lista `commander_learned_decks` nos data sources.
  - `server/routes/ai/_middleware.dart:16`-`:20` aplica
    `aiPlanLimitMiddleware()` e `aiRateLimit()` a `/ai/commander-learning`.
    `server/lib/plan_middleware.dart:35`-`:53` bloqueia quando a cota de IA
    acaba, e `server/lib/rate_limit_middleware.dart:167`-`:170`/`:381`-`:397`
    aplica bucket AI de 10/min em producao. O handler de commander-learning e
    leitura local de PG; busca focada por `OpenAI|openai|http` encontrou apenas
    o import de `http_responses.dart`.
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
- **Status 2026-06-12 15:00 UTC: REVALIDADO no checkout `129d647f`.** A rodada
  local focada em `postgresql-tables-not-used` revalidou os achados historicos
  com `rg` literal e varredura whole-repo de `CREATE TABLE` versus
  `FROM/JOIN/INSERT/UPDATE/DELETE/TRUNCATE` em `.dart`, `.sql`, `.py` e `.sh`.
  Nao houve novo achado P1/P2 app-facing. `deck_matchups` e
  `deck_weakness_reports` nao continuam write-only: ambas possuem leitores
  runtime e campos retornados no payload das rotas. `card_battle_rules` tambem
  nao foi classificada como unused, porque jobs/scripts Hermes leem, atualizam
  e sincronizam a tabela. `schema_migrations` segue fora do achado por ser
  tabela interna do migrador, e `user_learning_events` foi excluida por ser
  ponte SQLite local. O risco remanescente fica restrito a raws do Commander
  Reference Corpus sem leitor direto confirmado e a `ml_prompt_feedback`, que
  nao tem DDL local no checkout atual, possui helper de insert sem chamador e
  aparece em `/ai/ml-status` apenas como `COUNT(*)`.
- **Evidência**:
  - `deck_matchups` é definida em `server/database_setup.sql:222`; a rota
    `/ai/simulate-matchup` le o historico anterior por `_loadStoredMatchup` em
    `server/routes/ai/simulate-matchup/index.dart:382`, executa
    `SELECT win_rate, notes, updated_at FROM deck_matchups` em `:456`-`:463`,
    grava o upsert em `:390`-`:403` e retorna `stored_matchup.previous` em
    `:430`-`:435`. Portanto, a claim write-only esta stale.
  - `deck_weakness_reports` é definida em `server/database_setup.sql:484`; a
    rota `/ai/weakness-analysis` grava reports em
    `server/routes/ai/weakness-analysis/index.dart:480`-`:499`, chama
    `_loadWeaknessHistory` em `:506`, le resumo por severidade em `:572`-`:579`,
    le recentes em `:588`-`:595` e retorna `history` em `:559`. Portanto, a
    claim write-only esta stale, embora `addressed` ainda nao tenha update
    confirmado.
  - `ml_prompt_feedback` nao tem `CREATE TABLE` local encontrado em
    `server/database_setup.sql`, `server/lib`, `server/routes`, `server/bin`,
    `server/test` ou `app/lib` neste checkout. O insert fica apenas no helper
    `MLKnowledgeService.recordFeedback`
    (`server/lib/ml_knowledge_service.dart:251`, SQL em `:264`), sem chamador
    encontrado por busca focada de `recordFeedback(` em `server` ou `app`;
    `/ai/ml-status` apenas conta rows em
    `server/routes/ai/ml-status/index.dart:98`.
  - `commander_reference_decks` e `commander_reference_deck_cards` sao definidas
    em `server/lib/ai/commander_reference_deck_corpus_support.dart:1177` e
    `:1200`, recebem insert/delete/insert em `:1245`, `:1329` e `:1345`, mas
    nao possuem `SELECT/JOIN` confirmado; o produto consome o agregado
    `commander_reference_deck_analysis` em `:389`.
  - `card_battle_rules` foi descartada como achado: alem do DDL em
    `server/database_setup.sql:109` e `server/bin/migrate.dart:493`,
    `server/bin/auto_promote_battle_rules.py:113`-`:147` le/atualiza a tabela,
    `docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py:164`-`:175`
    le/sincroniza, e
    `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py:204`-`:207`
    faz join para montar o deck alvo.
- **Impacto**: para as raws Commander Reference, acumulacao de dados sem
  politica documentada de lineage/retencao ou reprocessamento. Para
  `ml_prompt_feedback`, risco de schema drift e falsa impressao de coleta ativa
  de feedback quando nao ha chamador nem consumidor do payload.
- **Ação recomendada**:
  1. documentar as tabelas raw do Commander Reference Corpus como lineage/audit,
     com retencao e job de reprocessamento, ou persistir apenas o agregado
     consumido;
  2. ligar `ml_prompt_feedback` a um fluxo real de feedback com DDL/migration
     versionada, ou remover o helper/count ate haver coleta ativa;
  3. se mantiver qualquer persistencia raw, adicionar endpoint/job/UI que leia
     os dados e teste de contrato;
  4. se remover, criar migration/cleanup seguro e atualizar
     `API_CONTRACTS_AND_DATA_MAP.md`.
- **Validação**:
  - `rg -n "\\b(FROM|JOIN)\\s+(commander_reference_decks|commander_reference_deck_cards)\\b" server app docs/hermes-analysis/manaloom-knowledge/scripts -g '*.dart' -g '*.py' -g '*.sh'`
    encontra consumidores reais de leitura, ou a persistencia deixa de existir
    com decisao documentada;
  - `rg -n "recordFeedback\\(" server app docs/hermes-analysis/manaloom-knowledge/scripts`
    encontra chamador real, caso a tabela de feedback seja mantida para coleta
    ativa;
  - testes das rotas experimentais continuam verdes;
  - contrato app-facing deixa claro se esses dados sao historico persistido ou
    apenas resposta efemera.

### P1/P2 — Remover ou documentar classes app sem uso de runtime confirmado

- **Status 2026-06-13 03:00 UTC: REVALIDADO/ABERTO no checkout `5bfc9706`.**
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
  - **Sem novo achado nesta revalidacao:** low-counts app como
    `AppObservabilityNavigatorObserver`, `PerformanceNavigatorObserver`,
    `CardRecognitionService`, `ImagePreprocessor`, `ScannerOverlay`,
    `LatestSetCollectionScreen`, `DeckAddCardsMenu` e widgets de
    `deck_details_aux_widgets.dart` tem chamadas runtime confirmadas.
  - Controles positivos desta revalidacao: `LotusLifeCounterScreen` e
    `DeckProgressIndicator` seguem ativos; candidatos backend de baixa contagem
    (`BattleSimulator`, `DistributedRateLimiter`, `RebuildGuidedService`,
    `SynergyEngine`, `PushNotificationService`, `DeckThemeProfile`) tambem tem
    chamador runtime confirmado.
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
2. **Segundo**: quebrar os dois SCCs atuais com menor blast radius:
   `life_counter_tabletop_engine.dart`/`life_counter_turn_tracker_engine.dart`
   e `optimize_runtime_support.dart`/`optimize_filler_loader_support.dart`.
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
  `local_test_server.dart` e o ciclo Community/Social nao estao abertos no
  checkout `b22063f6`; foram substituidos pelos SCCs atuais listados acima.
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
- o grafo local nao tiver SCCs nao documentados em `app/lib`, `server/lib`,
  `server/routes` ou `server/bin`;
- a duplicação/similaridade restante de alto risco em IA semantica, `resolveOptimizeArchetype`, terrenos basicos e helpers HTTP cair significativamente;
- os maiores arquivos do domínio de optimize reduzirem tamanho e responsabilidade.
