# Plano de Correcao — Audit de Estrutura

> Status atual: plano de correcao estrutural app/backend.
> Nao e contrato Hermes runtime. Use junto com `TECHNICAL_MAP.md` e revalide
> cada item antes de executar.

> Data: 2026-06-07 19:00 UTC
> Escopo: documentar problemas estruturais detectados em `STRUCTURE_AUDIT.md` sem alterar codigo de produto.

> Atualizacao Codex 2026-06-19: a triagem de
> `origin/codex/hermes-analysis-docs@8ddc978a` foi incorporada de forma
> seletiva. `swap_integrity` ficou resolvido no fluxo app, `DeckProgressChip`
> foi removido e `LotusPresentationMode` foi ligado ao ciclo de vida do Lotus.
> `DeckCard` e `LifeCounterScreen` seguem pendentes por exigirem decisao de
> produto/teste antes de apagar fixtures legadas.

## Resumo executivo

O auditor gerava muito ruído por inferir imports relativos a partir do root do repositório, então os **178 "imports quebrados" não podiam ser tratados como defeitos reais** sem revalidação por `dart analyze` ou por resolução relativa ao diretório do arquivo Dart. Esse P0 foi corrigido em `docs/hermes-analysis/scripts/structure_auditor.py`; a rodada local de 2026-06-07 11:00 UTC no checkout `2061f291` reportou `Imports quebrados: 0` no recorte backend do auditor base (`server/lib` e `server/routes`). Ainda assim, a varredura ampliada app/server segue apontando frentes prioritárias de organização:

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
   `DeckCard` continua testado mas sem import/chamada na listagem real.
   `DeckProgressChip` foi removido em 2026-06-19, e `LotusPresentationMode`
   passou a ser chamado por `LotusLifeCounterScreen`; `AuthVisualShell`,
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
    O achado de `verifySwapIntegrity` sem protecao app ficou resolvido em
    2026-06-19: o app valida `swap_integrity` e assinatura local antes do apply.
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
- **Impacto**: mudanca semantica em um ponto nao propaga automaticamente para os demais; risco de respostas inconsistentes por endpoint/fluxo. O risco mais alto e de IA: optimize, rebuild, validator e deck analysis podem discordar sobre arquetipo efetivo e papel funcional de cartas.
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

### P1 — Centralizar as politicas por nome restantes em policy versionada
- **Status 2026-06-07 05:30 UTC: REVALIDADO/ABERTO no checkout `84a97d75`.**
  A revalidacao local confirmou que nomes hardcoded ainda participam de tags,
  score, fillers, rebuild, recomendacoes, weakness suggestions, mock runtime e
  prompt runtime. A separacao de classificacao segue: exemplos de UI/import,
  comentarios, corpus/test fixtures e seeds declaradas nao sao bug por si so;
  decisoes de runtime por nome continuam risco salvo policy versionada.
- **Evidência**:
  - `server/lib/ai/functional_card_tags.dart:220`-`:226` classifica ramp por
    `signet`, `talisman`, `sol ring` e `arcane signet`; `:714`-`:717`,
    `:754`-`:780` e `:859`-`:899` usam nomes conhecidos para protecao,
    aristocrats, wincon, combo, payoff e enabler.
  - `server/lib/ai/candidate_quality_data_support.dart:375`-`:379`,
    `:421`-`:428`, `:439`-`:445`, `:472`-`:478`, `:531`-`:542`,
    `:590`-`:605` e `:611`-`:628` repetem checks por nome e aplicam
    bonus/escopo `highPowerNames`/`premium` ao bracket/score.
  - `server/lib/ai/commander_reference_generate_fallback_support.dart:182`-`:245`
    contem seed deterministica Lorehold por nomes fixos (`Sol Ring`,
    `Arcane Signet`, `Boros Charm`, equipamentos/protecao etc.). Classificacao
    desta rodada: allowed-with-caution se tratada como seed/profile versionado;
    risco se for usada como policy implicita de utilidade global.
  - `server/lib/ai/optimize_runtime_support.dart:406`-`:454`, `:1296`-`:1360`,
    `:1966`-`:2051`, `:2318`-`:2341` e `:3476`-`:3512` mantem listas fixas de
    terrenos premium, staples, bonus premium, bonus de `preferredNames` e
    fallbacks universais.
  - `server/routes/ai/optimize/index.dart:1113`-`:1123` ainda pode retornar
    mock runtime com `Sol Ring` e `Arcane Signet` quando `deckOptimizer == null`.
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

### P1 — Unificar o adapter semantico usado por deck analysis, optimize e candidate quality

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
- **Status 2026-06-07 11:00 UTC: REVALIDADO/ABERTO no checkout local
  `2061f291`.** A resolucao historica citada para `origin/master@a830f9f3` nao
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

**Status 2026-06-07 11:00 UTC: REVALIDADO/ABERTO no checkout local
`2061f291`.** As resolucoes historicas citadas para `origin/master@640f4ab4` e
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
    quebrado neste checkout; o arquivo alvo existe.
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

**Status 2026-06-07 11:00 UTC: REVALIDADO/ABERTO no checkout local
`2061f291`.** A resolucao historica citada para `origin/master@640f4ab4` nao
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
- **Impacto**: cobertura pode estar validando caminhos mortos nos helpers
  restantes, mas o risco mais alto do sync de cartas foi fechado; os testes
  agora cobrem o mesmo extrator usado pelo CLI operacional.
- **Ação recomendada**:
  1. ✅ Resolvido 2026-06-11: `sync_cards_utils.dart` virou fonte
     compartilhada real do CLI;
  2. para cada wrapper test-only restante, ligar ao runner/rota esperado ou remover o
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
  - `grep -RIn "sync_cards_utils" server` encontra o binário ativo:
    `server/bin/sync_cards.dart`;
  - `dart analyze lib/sync_cards_utils.dart bin/sync_cards.dart test/sync_cards_test.dart`;
  - `dart test test/sync_cards_test.dart --reporter compact`;
  - busca por simbolo encontra chamador runtime ou nenhum simbolo residual.

### P1 — Alinhar ownership e contratos app-facing entre `app/lib`, rotas e helpers
- **Status 2026-06-05 23:00 UTC:** REVALIDADO/ABERTO no checkout local
  `49939bb6`. A coerencia app-facing de `/ai/optimize`, `/ai/archetypes` e
  jobs async de optimize/generate nao esta resolvida nesta branch. `POST /ai/rebuild`,
  `GET /decks/:id/analysis` e `POST /decks/:id/ai-analysis` foram usados como
  controles positivos de owner gate. `/decks/:id/recommendations`,
  `/decks/:id/simulate`, `/ai/simulate-matchup` e `/ai/weakness-analysis` nao
  tem consumidor app atual na busca focada, mas continuam sem contrato de owner
  antes de eventual promocao. A
  rodada tambem confirmou incoerencia de activation telemetry:
  `deck_rebuild_created` e emitido pelo app, rejeitado pela allow-list backend e
  ausente da doc app-facing atual. Tambem foi revalidado que deck analysis
  consome `functional_tags`, enquanto optimize ainda nao propaga
  `card_function_tags` para o contexto/validator.
- **Evidência**:
  - O app envia `POST /ai/optimize` com `deck_id` em
    `app/lib/features/decks/providers/deck_provider_support_ai.dart:56`; a
    rota tenta ler `userId`, mas chama `loadOptimizeDeckContext` em
    `server/routes/ai/optimize/index.dart:549`-`:558` sem passar usuario.
  - `server/lib/ai/optimize_request_support.dart:53`-`:73` declara o loader
    sem `userId` e consulta `SELECT name, format FROM decks WHERE id = @id`;
    `:87`-`:110` carrega cartas por `WHERE dc.deck_id = @id`.
  - O app tambem envia `POST /ai/archetypes` com `deck_id` em
    `app/lib/features/decks/providers/deck_provider_support_mutation.dart:168`-`:173`;
    `server/routes/ai/archetypes/index.dart:39`-`:42` busca o deck por `id`
    apenas e `:54`-`:60` carrega cartas por `dc.deck_id = @id`.
  - `OptimizeJobStore.create` aceita `String? userId` em
    `server/lib/ai/optimize_job.dart:25`-`:30`, e
    `server/routes/ai/optimize/jobs/[id].dart:39`-`:47` so bloqueia quando o
    job tem owner diferente; job nulo continua legivel.
  - O app envia `POST /ai/generate` com `async: true` em
    `app/lib/features/decks/providers/deck_provider_support_generation.dart:230`-`:236`
    e faz polling pelo `poll_url` em `:379`. `server/routes/ai/generate/index.dart:786`-`:813`
    cria jobs com `String? userId`; `server/lib/ai_generate_job.dart:12`-`:17`
    aceita usuario nullable; `server/routes/ai/generate/jobs/[id].dart:16`-`:19`
    so bloqueia quando o job tem owner diferente.
  - `GET /decks/:id/analysis` seleciona `card_function_tags` e
    `semantic_tags_v2`, e o app parseia `functional_tags`; em contraste,
    `server/lib/ai/optimize_request_support.dart:86`-`:106` carrega apenas
    `card_semantic_tags_v2`, e `:186`-`:198` monta `allCardData` sem
    `functional_tags`.
  - `server/routes/decks/[id]/recommendations/index.dart:24`-`:27` busca deck
    por `id` e `:39`-`:58` busca cartas por `deckId`; a rota esta documentada
    como experimental/not proven em `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
    e nao tem chamada atual em `app/lib`.
  - `server/routes/decks/[id]/simulate/index.dart:13`-`:25` carrega cartas por
    `deckId` sem owner; busca focada em `app/lib` nao encontrou consumidor.
  - `app/lib/features/decks/providers/deck_provider.dart:605`-`:607` emite
    `_trackActivationEvent('deck_rebuild_created', deckId: draftDeckId)`.
    `app/lib/core/services/activation_funnel_service.dart:17`-`:23` envia o
    evento para `POST /users/me/activation-events`, mas o catch em `:24`-`:26`
    engole falhas. A rota aceita somente `_allowedEvents` em
    `server/routes/users/me/activation-events/index.dart:10`-`:18`, sem
    `deck_rebuild_created`, e rejeita fora da lista em `:46`-`:48`.
    `server/doc/API_CONTRACTS_AND_DATA_MAP.md:61` ainda chama o endpoint de
    `internal` com consumidor `not proven`, embora haja chamadas reais em
    `app/lib`.
- **Impacto**: usuario autenticado pode potencialmente disparar analise/opcoes
  ou leitura de job para recursos sem owner-scope se obtiver IDs validos. Alem
  disso, a memoria tecnica anterior registrava um estado resolvido que nao bate
  com o codigo local. No caso de activation, o fluxo de rebuild guiado perde
  telemetria silenciosamente, o que mascara funil/metricas de produto.
- **Ação recomendada**:
  1. adicionar `userId` obrigatorio a `loadOptimizeDeckContext` e filtrar
     `decks`/`deck_cards` por dono;
  2. aplicar o mesmo owner-scope em `/ai/archetypes`;
  3. tornar `OptimizeJobStore.create` e `AiGenerateJobStore.create`
     owner-obrigatorios para jobs app-facing e retornar 404 quando
     `job.userId == null || job.userId != userId`;
  4. decidir se `/decks/:id/recommendations` e `/decks/:id/simulate` serao
     removidas, owner-scoped ou publicas somente para `is_public=true`;
  5. adicionar `deck_rebuild_created` a `_allowedEvents` com teste, ou remover a
     emissao app se rebuild nao deve entrar no funil; atualizar
     `API_CONTRACTS_AND_DATA_MAP.md` para listar consumidores reais do endpoint;
  6. threadar `card_function_tags` no contexto de optimize ou documentar/testar
     que optimize ignora essa camada por design;
  7. exigir teste owner vs non-owner quando qualquer rota nova aceitar
     `deck_id`.
- **Validação**:
  - teste de `POST /ai/optimize` com deck de outro usuario retorna 404;
  - teste de `POST /ai/archetypes` com deck de outro usuario retorna 404;
  - source mostra `loadOptimizeDeckContext` com `userId` obrigatorio e query de
    `decks` por `id + user_id`;
  - source mostra polling de optimize/generate bloqueando
    `job.userId == null` ou owner diferente;
  - source mostra `functional_tags` chegando ao adapter de optimize, ou testes
    provam a divergencia intencional;
  - source mostra recommendations/simulate lendo cartas via `deck_cards` +
    `decks` filtrado por owner, ou docs/testes marcando contrato publico;
  - teste de activation aceita ou elimina `deck_rebuild_created`, e a doc deixa
    de chamar consumidores app reais de `not proven`;
  - `rg "/ai/simulate-matchup|/ai/weakness-analysis|/decks/.*/simulate|/decks/.*/recommendations" app/lib`
    continua vazio ate haver contrato seguro;

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
    nao possuem `SELECT/JOIN` confirmado; o produto consome o agregado
    `commander_reference_deck_analysis` em `:389`.
- **Impacto**: acumulacao de dados sem produto/operacao consumindo o historico,
  retencao indefinida e falsa impressao de que ha cache, dashboard, workflow
  persistente ou loop de aprendizado alimentado por essas persistencias.
- **Ação recomendada**:
  1. escolher entre manter como log bruto com retencao documentada, criar
     consumidor real ou remover a persistencia dessas rotas experimentais;
  2. usar o histórico de `ml_prompt_feedback` em métrica/seleção de prompt
     quando houver volume suficiente; a coleta ativa já existe;
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

- **Status 2026-06-04 03:00 UTC: REVALIDADO/ABERTO.**
- **Evidência**:
  - `app/lib/features/home/life_counter_screen.dart:61` define
    `LifeCounterScreen`, mas `app/lib/main.dart:282`-`:283` usa
    `LotusLifeCounterScreen()` para a rota ativa; busca em `app/lib` encontrou
    `LifeCounterScreen(` apenas no construtor da propria classe. Os testes
    `app/test/features/home/life_counter_screen_test.dart:1`-`:2` e
    `app/test/features/home/life_counter_clone_proof_test.dart:1`-`:2`
    declaram que sao suites legadas e que a cobertura viva mira
    `LotusLifeCounterScreen`; ambos ainda importam e instanciam a tela legada.
  - `app/lib/features/decks/widgets/deck_card.dart:17` define `DeckCard`, mas a
    busca por import de `deck_card.dart` em `app/lib` nao retornou ocorrencias,
    e a busca por `DeckCard(` em `app/lib` encontrou somente o construtor.
    `DeckCard` aparece apenas nos testes
    `app/test/features/decks/widgets/deck_card_test.dart:4`/`:9` e
    `app/test/features/decks/widgets/deck_card_overflow_test.dart:4`/`:47`.
    As listagens reais usam widgets privados/locais como `_RecentDeckCard`,
    `_CommunityDeckCard`, `_FollowingDeckCard`, `_DeckGalleryCard` e
    `_EmptyDeckCard`.
  - **Resolvido em 2026-06-19:** `DeckProgressChip` foi removido de
    `app/lib/features/decks/widgets/deck_progress_indicator.dart` porque nao
    possuia consumidor runtime; `DeckProgressIndicator` permanece usado e nao
    faz parte deste achado.
  - **Resolvido em 2026-06-19:** `LotusPresentationMode` passou a ser importado
    e chamado por `LotusLifeCounterScreen` em `initState`/`dispose`, exceto Web.
  - `app/lib/features/auth/widgets/auth_visual_shell.dart:5`, `:105` e `:196`
    definem `AuthVisualShell`, `AuthBrandHeader` e `AuthFormSurface`; busca por
    esses simbolos e por `auth_visual_shell.dart` em arquivos Dart encontrou
    apenas definicoes/construtores no proprio arquivo.
  - Controles positivos desta revalidacao: `LotusLifeCounterScreen` e
    `DeckProgressIndicator` seguem ativos; `PerformanceNavigatorObserver`,
    `AppObservabilityNavigatorObserver`, classes do scanner com chamadores reais
    e candidatos backend como `PushNotificationService`, `DistributedRateLimiter`,
    `MarketMoversCache`, `MatchupAnalyzer` e `SynergyEngine` foram descartados.
- **Impacto**: classes mortas ou legadas inflacionam a superficie de manutencao,
  mantem testes que podem nao proteger o runtime real e tornam ambigua a
  documentacao de gargalos ativos.
- **Ação recomendada**:
  1. decidir se `LifeCounterScreen` e fixture/harness legado ou deve ser removido
     em favor do Lotus runtime;
  2. remover ou reconectar `DeckCard`, `LifeCounterScreen` e o shell auth
     (`AuthVisualShell`/`AuthBrandHeader`/`AuthFormSurface`);
  3. atualizar/remover testes que hoje exercitam widgets fora do runtime real.
- **Validação**:
  - `rg -n '\b(LifeCounterScreen|DeckCard|DeckProgressChip|LotusPresentationMode|AuthVisualShell|AuthBrandHeader|AuthFormSurface)\b|auth_visual_shell\.dart' app/lib app/test app/integration_test --glob '*.dart'`
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
- a duplicação/similaridade restante de alto risco em IA semantica e helpers
  HTTP cair significativamente;
- os maiores arquivos do domínio de optimize reduzirem tamanho e responsabilidade.
