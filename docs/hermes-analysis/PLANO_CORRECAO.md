# Plano de Correcao — Audit de Estrutura

> Status atual: plano de correcao estrutural app/backend.
> Nao e contrato Hermes runtime. Use junto com `TECHNICAL_MAP.md` e revalide
> cada item antes de executar.

> Data: 2026-06-18 15:00 UTC
> Escopo: documentar problemas estruturais detectados em `STRUCTURE_AUDIT.md` sem alterar codigo de produto.

## Resumo executivo

O auditor gerava muito ruído por inferir imports relativos a partir do root do repositório, então os **178 "imports quebrados" não podiam ser tratados como defeitos reais** sem revalidação por `dart analyze` ou por resolução relativa ao diretório do arquivo Dart. Esse P0 foi corrigido em `docs/hermes-analysis/scripts/structure_auditor.py`. Na rodada local de 2026-06-17 19:00 UTC no checkout `e47adcd5`, o auditor base voltou a executar com sucesso (`205` arquivos backend, `92` tabelas PostgreSQL textualmente referenciadas, `0` imports quebrados). A revalidacao focada em duplicacao nao encontrou delta de produto desde a rodada anterior do mesmo foco (`5ce943fa..HEAD`), manteve os clusters de produto ja abertos e adicionou um achado P2 ao recorte de duplicacao: `server/lib/sync_cards_utils.dart` contem helpers extraidos/testados, mas `server/bin/sync_cards.dart` ainda usa copias privadas/inline para janela incremental, parsing de set e legalidades. O achado P2 script-level dos exporters Hermes de learned deck segue aberto: `server/bin/export_hermes_learned_deck.py` e `docs/hermes-analysis/manaloom-knowledge/scripts/export_hermes_learned_deck.py` continuam bifurcados em completude, contagem, fallback de schema e metadata multi-role. A revalidacao de tabelas PostgreSQL de 2026-06-18 15:00 UTC no checkout `024903d6` confirmou que nao houve delta de produto desde a rodada anterior deste foco (`c33e15ba..HEAD`) nem novo achado P1/P2 app-facing; seguem apenas os mesmos riscos P3 (`ml_prompt_feedback` count-only/sem chamador/sem DDL local confirmado e raws do Commander Reference Corpus sem leitor raw direto). A frente aberta de aciclicidade foi revalidada em 2026-06-18 11:00 UTC no checkout `88fa4a1e`: 0 imports/exports/parts locais quebrados em 1082 diretivas locais e os mesmos 2 SCCs. A revalidacao de classes de 2026-06-18 03:00 UTC no checkout `94f73400` nao encontrou delta de codigo de produto desde `2edcc757` nem novo candidato confiavel alem dos quatro ja abertos. A auditoria local de semantica de cartas de 2026-06-17 05:30 UTC no checkout `6d25e447` nao encontrou delta de produto desde `e458c074`, mas atualizou a triagem de rebuild guiado e basic-land checks locais. A revalidacao de funcoes sem chamador de 2026-06-18 07:00 UTC no checkout `2a9f76ee` nao encontrou delta de produto desde `caeade55` e manteve abertos os mesmos candidatos principais; o achado menor de `normalize_commander` continua estreito para a copia Hermes docs.

A revalidacao de coerencia app/server de 2026-06-17 23:00 UTC no checkout
`831c6ac8` nao encontrou delta de produto/testes/API/manual desde `5ce943fa` e
nao abriu novo achado. Permanecem os mesmos tres gaps estreitos:
`deck_rebuild_created` emitido/testado no app mas rejeitado por
`_allowedEvents`, `GET /ai/commander-learning` consumido pelo app e ligado a
`commander_learned_decks` mas ausente do API contract map, e consulta local de
learned decks herdando middleware de IA custosa.

1. **P0 — Ferramenta de auditoria com falso-positivo em massa**: **RESOLVIDO na ferramenta**. Manter como lição operacional: evidência do auditor deve ser confrontada com analyzer quando apontar falhas estruturais.
2. **P1 — Concentradores de complexidade muito grandes**: revalidado em
   2026-06-11; `server/lib/ai/optimize_runtime_support.dart` (~2386 linhas) e
   `server/routes/ai/optimize/index.dart` (~2498 linhas) reduziram, mas seguem
   como gargalos de manutenção.
3. **P1 — Duplicação de helpers e lógica espalhada**: revalidada novamente em
   2026-06-11. `resolveOptimizeArchetype` foi removido do risco por delegar
   para `optimize_archetype_support.dart`; os roles estratégicos
   `wincon/combo_piece/engine/payoff/enabler` também passaram a reutilizar
   `resolveCardFunctionalRoles` em `functional_card_tags.dart`. O drift de
   terrenos básicos/snow basics foi fechado em 2026-06-11 com
   `server/lib/basic_land_utils.dart`. Os maiores riscos restantes são trust
   social, logs sociais/follow, condição de carta e CMC/tipo.
4. **P1 — Entry point local quebrado**: **REVALIDADO/ABERTO no checkout local
   `2061f291` em 2026-06-07 11:00 UTC**. `server/bin/local_test_server.dart:3` ainda importa
   `../.dart_frog/server.dart` estaticamente, `server/.dart_frog/server.dart`
   nao existe neste checkout, e `dart analyze bin/local_test_server.dart` falha
   com `uri_does_not_exist`.
5. **P1 — Ownership, jobs async e contratos app-facing em rotas deck/AI**:
   **PARCIAL em 2026-06-11**. O achado antigo de optimize sem owner-scope foi
   resolvido: `POST /ai/optimize` exige usuário autenticado,
   `loadOptimizeDeckContext` consulta por `id + user_id`, jobs async têm
   `userId` obrigatório e polling rejeita job sem owner ou de outro usuário.
   Deck analysis e optimize também carregam `functional_tags`. Ainda precisam
   de rodada própria os endpoints experimentais fora do caminho principal
   (`/ai/archetypes`, activation telemetry e rotas legacy/experimentais).
6. **P1 — Politicas por nome / semantica de cartas**: revalidado novamente em
   2026-06-12. `/ai/weakness-analysis` e `/decks/:id/recommendations` deixaram
   de retornar listas fixas de staples em seus fallbacks principais; a rota de
   recommendations tambem removeu `Command Tower` literal e raridade como proxy
   de impacto, passando a buscar sugestoes por `card_function_tags`,
   `card_semantic_tags_v2`, `card_legalities` e `cards.color_identity` quando
   disponiveis. Ainda ha excecoes por nome em `functional_card_tags.dart`,
   `candidate_quality_data_support.dart`, `optimize_runtime_support.dart`,
   `rebuild_guided_service.dart`, no mock runtime de `/ai/optimize` quando
   `deckOptimizer == null` e em prompts runtime carregados por `otimizacao.dart`.
   A rodada separou exemplos de UI/import, comentarios, seeds de busca,
   docs/corpus/artifacts/test fixtures e seeds Commander Reference dos riscos
   reais. `edh_bracket_policy.dart` continua excecao intencional por regra
   externa/curadoria de bracket, mas precisa manter fonte/versionamento/teste
   dedicado.
7. **P2/P3 — Tabelas PostgreSQL write-only ou parcialmente consumidas**: revalidado na rotacao local Codex de 2026-06-07 15:00 UTC no checkout `52f6084e` e atualizado em 2026-06-11. `deck_matchups` e `deck_weakness_reports` recebem persistencia, mas nao possuem leitura/uso confirmado fora da chamada que gerou o dado. `ml_prompt_feedback` deixou de ser "helper sem chamador": `/ai/optimize` agora registra feedback automático via `optimize_feedback.recordOptimizeMlFeedback(...)`, com schema declarado em `database_setup.sql`/`verify_schema.dart` e contador em `/ai/ml-status`. O risco restante é usar esse histórico para seleção/score de prompts, não coletá-lo. `commander_reference_decks`/`commander_reference_deck_cards` sao persistidas como raw corpus, mas o produto le somente o agregado `commander_reference_deck_analysis`. A varredura focada de DDL versus operacoes SQL encontrou 53 tabelas criadas no recorte de codigo e somente `commander_reference_decks`, `deck_matchups` e `deck_weakness_reports` com write sem `SELECT/JOIN`; `commander_reference_deck_cards` foi mantida como achado manual por ser raw corpus apagado/reinserido sem leitura de produto confirmada. Nenhum novo candidato foi confirmado; `deck_learning_events` e `commander_card_usage` aparecem apenas em docs historicos neste checkout, nao em `server/database_setup.sql` ou codigo Dart runtime.
8. **P1/P2 — Classes app sem uso de runtime confirmado**: revalidado novamente
   na rotacao local Codex de 2026-06-07 03:00 UTC no checkout `ee74c6a9`.
   `LifeCounterScreen` segue
   como caminho legado/test-only enquanto a rota viva usa `LotusLifeCounterScreen`;
   `DeckCard` continua testado mas sem import/chamada na listagem real;
   `DeckProgressChip` nao tem chamada de construtor; `LotusPresentationMode`
   nao tem import nem chamada para `enter()`/`exit()`; `AuthVisualShell`,
   `AuthBrandHeader` e `AuthFormSurface` aparecem somente no proprio arquivo
   `auth_visual_shell.dart`. Controles positivos desta rodada descartaram
   `LotusLifeCounterScreen` e `DeckProgressIndicator`; a varredura textual
   ampla nao foi usada para acusar DTOs/helpers locais sem evidencia adicional.
9. **P1 — Drift entre deck analysis e optimize**: **PARCIAL em 2026-06-11**.
   O caminho principal já carrega `functional_tags` e o validator/gate usa
   precedência `functional_tags -> semantic_tags_v2 -> heurística`. O risco
   restante é consolidar heurísticas secundárias e endpoints legacy que ainda
   não reutilizam explicitamente a camada compartilhada.
10. **P2 — Bracket state em fillers de optimize/complete**: **RESOLVIDO em
    `origin/master@1aa4da71`**. Os loaders de fillers agora recebem estado
    atual/virtual do deck e nao usam fallback `bracket: null` quando o bracket
    foi definido.
11. **P3 — Diagnosticos de bracket em sucesso parcial do optimize**:
    **RESOLVIDO em `origin/master@4913a733`**. Sucessos com sugestoes filtradas
    por bracket podem expor `optimize_diagnostics.bracket_policy`, mantendo
    `warnings.blocked_by_bracket` para compatibilidade.
12. **P1/P2 — Funcoes publicas sem chamador runtime**: revalidado em
    2026-06-07 07:00 UTC como **ABERTO neste checkout `82bb454e`** e
    atualizado em 2026-06-11. `sync_cards_utils.dart` deixou de ser helper
    test-only: `server/bin/sync_cards.dart` importa o utilitário compartilhado
    para `parseSinceDays`, `getNewSetCodesSinceFromData` e
    `extractSetCardSyncRow`, removendo as cópias privadas do CLI operacional.
    Ainda seguem sem chamador runtime confirmado
    wrappers/helpers em request trace, Commander Reference, MTGTop8, candidate
    quality e optimize utility samples. `MLKnowledgeService.recordFeedback`
    deixou esta lista em 2026-06-11 (`f32c0e28`): `/ai/optimize` agora chama
    `optimize_feedback.recordOptimizeMlFeedback(...)`. Novo achado app-side:
    `ApiClient.loadTokenFromDisk()` diz ser chamado no
    boot, mas nao tem chamada em `app/lib`; o boot real usa
    `AuthProvider.initialize` + `ApiClient.setToken`. A API manual/custom
    metrics/debug de `PerformanceService` e conveniencias EDHREC/cache
    (`getTopByCategory`, `calculateFitScore`, `cleanupCache`, `isHighSynergy`,
    `EndpointCache.clearExpired`) seguem sem chamador confirmado. A
    observabilidade automatica do `PerformanceService` foi separada como
    controle positivo (`init`, observer de tela e `traceAsync` em smoke), nao
    como codigo morto.
13. **P1/P2 — Imports quebrados e ciclo app/server**: **REVALIDADO/ABERTO no
    checkout local `2061f291` em 2026-06-07 11:00 UTC.** O auditor base reportou
    `Imports quebrados: 0` em `server/lib`/`server/routes`, e o import historico
    de `server/routes/ai/commander-learning/index.dart:4` deixou de estar
    quebrado porque `server/lib/ai/commander_learned_deck_support.dart` existe
    neste checkout. A varredura local ampliada encontrou 3 imports locais
    quebrados em 426 arquivos: `app/lib/features/decks/widgets/deck_analysis_tab.dart:5`
    resolvendo para `app/core/utils/mana_helper.dart`,
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
- **Status 2026-06-11: PARCIAL.** `resolveOptimizeArchetype` foi unificado, os
  roles estratégicos `wincon`, `combo_piece`, `engine`, `payoff` e `enabler`
  agora usam o adapter único `resolveCardFunctionalRoles` também na geração de
  `functional_tags`, e basic/snow basic lands passaram a usar
  `server/lib/basic_land_utils.dart` como fonte canônica. As duplicações
  restantes abaixo continuam abertas conforme domínio.
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
  - **Novo P2 no recorte de duplicacao:** `server/lib/sync_cards_utils.dart:1`-`:4`
    declara que helpers foram extraidos de `sync_cards.dart` para teste
    independente e define `extractCardRow`, `getNewSetCodesSinceFromData`,
    `parseSinceDays`, `extractSetCardRow`, `extractOracleIds` e
    `extractLegalities` em `:16`, `:82`, `:102`, `:121`, `:178` e `:189`.
    `rg "sync_cards_utils"` encontrou apenas
    `server/test/sync_cards_test.dart:3`, enquanto o CLI real ainda chama
    copias privadas/inline em `server/bin/sync_cards.dart:64`,
    `:130`-`:131`, `:349`-`:357`, `:385`-`:402`, `:661`-`:722` e monta
    legalidades inline em `:766`-`:770`.
  - **Novo P2 script-level:** `server/bin/export_hermes_learned_deck.py` e
    `docs/hermes-analysis/manaloom-knowledge/scripts/export_hermes_learned_deck.py`
    tem o mesmo prologo/uso e fluxo geral de exportacao
    (`server/bin/export_hermes_learned_deck.py:1`-`:11`;
    `docs/hermes-analysis/manaloom-knowledge/scripts/export_hermes_learned_deck.py:1`-`:13`), repetem
    `parse_card_list`, `normalize_commander`, `compute_score`, `build_metadata`
    e `export_learned_deck`, mas agora divergem: o `server/bin` usa
    `validate_commander_100` + `HERMES_EXPORT_ALLOW_INCOMPLETE` e grava
    `card_count` como `len(parsed_cards)`
    (`server/bin/export_hermes_learned_deck.py:46`-`:64`, `:193`-`:202`,
    `:235`-`:236`), enquanto o script Hermes usa
    `learned_deck_completeness`, bloqueia incompletos, injeta o comandante
    ausente e grava `total_with_commander`
    (`docs/hermes-analysis/manaloom-knowledge/scripts/export_hermes_learned_deck.py:13`,
    `:233`-`:251`, `:299`). Tambem ha drift de metadata:
    `server/bin/export_hermes_learned_deck.py:84`-`:151` usa
    `role_in_deck` + `elif`, enquanto o script Hermes usa `pg_roles` quando
    existe e multiplos `if`
    (`docs/hermes-analysis/manaloom-knowledge/scripts/export_hermes_learned_deck.py:80`-`:118`,
    `:158`-`:175`).
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
  6. decidir se `sync_cards_utils.dart` e fonte compartilhada real ou harness
     legado; se for fonte real, importar no CLI e substituir as copias privadas,
     mantendo `sync_cards_test` como cobertura do caminho operacional.
  7. decidir qual exporter Hermes de learned deck e canonico; fazer um wrapper
     chamar a implementacao unica, ou documentar `server/bin` como legado com
     teste/fixture que prove as divergencias esperadas.
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
  - `rg "sync_cards_utils" server` encontra o binario ativo, ou o helper deixa
    de ser anunciado como codigo compartilhado operacional.
  - ambos os exporters de learned deck geram o mesmo JSON para fixtures SQLite
    com lista texto, lista JSON, comandante ausente/presente, `pg_roles` e
    metricas ausentes, ou o exporter legado deixa de existir/ser anunciado como
    operacional.

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
- **Status 2026-06-16 23:00 UTC:** REVALIDADO/ABERTO no checkout local
  `5ce943fa`. Desde a rodada anterior deste mesmo foco (`9adb0989..HEAD`),
  nao houve delta em `app/lib`, `server/lib`, `server/routes`, `server/bin`,
  `server/database_setup.sql`, testes app/server ou
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md`. Os achados anteriores de
  ownership em `/ai/optimize`, `/ai/archetypes` e jobs async de
  optimize/generate continuam resolvidos/stale. A lacuna ativa permanece
  estreita: activation telemetry rejeita um evento emitido pelo app,
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
    `server/routes/ai/commander-learning/index.dart:67`-`:92` e `:106`-`:132`;
    o schema/modelo fica em
    `server/lib/ai/commander_learned_deck_support.dart:7` e `:283`-`:315`.
    `rg "/ai/commander-learning" server/doc/API_CONTRACTS_AND_DATA_MAP.md`
    nao encontrou contrato, e `server/doc/API_CONTRACTS_AND_DATA_MAP.md:310`-`:315`
    nao lista `commander_learned_decks` nos data sources.
  - `server/routes/ai/_middleware.dart:16`-`:20` aplica
    `aiPlanLimitMiddleware()` e `aiRateLimit()` a `/ai/commander-learning`.
    `server/lib/plan_middleware.dart:35`-`:53` bloqueia quando a cota de IA
    acaba, e `server/lib/rate_limit_middleware.dart:167`-`:170`/`:381`-`:397`
    aplica bucket AI de 10/min em producao. O handler de commander-learning e
    leitura local de PG; busca focada por `OpenAI|openai|http` encontrou apenas
    o import de `http_responses.dart`.
  - `cd server && dart analyze routes/ai/commander-learning/index.dart routes/users/me/activation-events/index.dart routes/ai/_middleware.dart`
    retornou `No issues found!`.
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
- **Status 2026-06-07 15:00 UTC: REVALIDADO no checkout `52f6084e`.** A rodada local focada em
  `postgresql-tables-not-used` nao encontrou novos consumidores runtime para os
  pontos abaixo. `schema_migrations` foi explicitamente mantida fora do achado
  por ser tabela interna do migrador. Uma varredura focada de DDL versus
  `FROM/JOIN/INSERT/UPDATE/DELETE` encontrou 53 tabelas criadas no recorte de
  codigo e somente `commander_reference_decks`, `deck_matchups` e
  `deck_weakness_reports` com write sem `SELECT/JOIN`; `commander_reference_deck_cards`
  foi mantida como achado manual por ser raw corpus apagado/reinserido sem
  leitura de produto confirmada. `ml_prompt_feedback` agora tem writer runtime
  em `/ai/optimize`, schema verificado e leitura de `COUNT(*)` operacional.
  `battle_simulations`,
  `format_staples`, `archetype_counters`, `archetype_patterns`,
  `synergy_packages`, `activation_funnel_events` e `ai_user_preferences` foram
  separados como controles positivos por terem leitores runtime ou runners
  dedicados confirmados.
- **Evidência**:
  - `deck_matchups` é definida em `server/database_setup.sql:169` e recebe
    upsert em `server/routes/ai/simulate-matchup/index.dart:360`, mas nao ha
    leitura operacional em `app/lib`, `server/bin`, `server/lib` ou
    `server/routes`.
  - `deck_weakness_reports` é definida em `server/database_setup.sql:370` e
    `server/bin/migrate_create_missing_tables.dart:97`, recebe insert em
    `server/routes/ai/weakness-analysis/index.dart:374`, mas nao ha leitura em
    `app/lib`, `server/bin`, `server/lib` ou `server/routes`; o campo
    `addressed` tambem nao tem fluxo de update confirmado.
  - `ml_prompt_feedback` é definida em `server/database_setup.sql` e
    `server/bin/verify_schema.dart`, recebe insert via
    `MLKnowledgeService.recordFeedback` e tem chamador runtime em
    `server/routes/ai/optimize/index.dart` por meio de
    `server/lib/ai/optimize_feedback_support.dart`; `/ai/ml-status` conta rows
    e exige a tabela no check de schema ML.
  - `commander_reference_decks` e `commander_reference_deck_cards` sao definidas
    em `server/lib/ai/commander_reference_deck_corpus_support.dart:1177` e
    `:1200`, recebem insert/delete/insert em `:1245`, `:1329` e `:1345`, mas
    nao possuem `SELECT/JOIN` runtime confirmado; o produto consome o agregado
    `commander_reference_deck_analysis` em `:389`.
  - `card_battle_rules` foi descartada como achado: alem do DDL em
    `server/database_setup.sql:109` e `server/bin/migrate.dart:493`,
    `server/bin/auto_promote_battle_rules.py:113`-`:147` le/atualiza a tabela,
    `docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py:164`-`:175`
    le/sincroniza, e
    `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py:204`-`:207`
    faz join para montar o deck alvo.
  - `server/doc/API_CONTRACTS_AND_DATA_MAP.md:285`-`:286` e
    `server/manual-de-instrucao.md:18040`-`:18045` ainda dizem que
    `deck_matchups`/`deck_weakness_reports` sao write-only/audit logs sem
    leitura runtime. A fonte atual falsifica esse texto, mas esses arquivos nao
    foram editados por restricao de escrita desta rotina.
- **Impacto**: para as raws Commander Reference, acumulacao de dados sem
  politica documentada de lineage/retencao ou reprocessamento. Para
  `ml_prompt_feedback`, risco de schema drift e falsa impressao de coleta ativa
  de feedback quando nao ha chamador nem consumidor do payload. Para
  `deck_matchups`/`deck_weakness_reports`, o risco atual e documental: contratos
  fora de `docs/hermes-analysis` ainda podem induzir auditorias futuras ao erro.
- **Ação recomendada**:
  1. escolher entre manter como log bruto com retencao documentada, criar
     consumidor real ou remover a persistencia dessas rotas experimentais;
  2. usar o histórico de `ml_prompt_feedback` em métrica/seleção de prompt
     quando houver volume suficiente; a coleta ativa já existe;
  3. documentar as tabelas raw do Commander Reference Corpus como lineage/audit,
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

- **Status 2026-06-18 03:00 UTC: REVALIDADO/ABERTO no checkout `94f73400`.**
  Desde a rodada anterior de classes (`2edcc757..HEAD`), nao houve delta de
  codigo de produto, testes, contrato API, contexto de produto ou manual no
  recorte app/backend.
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
  - **Sem novo achado nesta revalidacao:** `LotusLifeCounterScreen` e
    `DeckProgressIndicator` seguem ativos; a saida bruta do auditor para classes
    backend nao foi promovida como achado porque e inventario textual, nao grafo
    de chamadas.
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
  `local_test_server.dart`, `commander-learning/index.dart` e o ciclo
  Community/Social nao estao abertos no checkout `ea37f3cf`; foram substituidos
  pelos SCCs atuais listados acima.
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
