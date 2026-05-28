# Plano de Correcao — Audit de Estrutura

> Data: 2026-05-28 00:01 UTC
> Escopo: documentar problemas estruturais detectados em `STRUCTURE_AUDIT.md` sem alterar codigo de produto.

## Resumo executivo

O auditor gerava muito ruído por inferir imports relativos a partir do root do repositório, então os **178 "imports quebrados" não podiam ser tratados como defeitos reais** sem revalidação por `dart analyze` ou por resolução relativa ao diretório do arquivo Dart. Esse P0 foi corrigido em `docs/hermes-analysis/scripts/structure_auditor.py`; a nova execução reporta `Imports quebrados: 0`. Ainda assim, as rodadas focadas revelaram frentes prioritárias de organização:

1. **P0 — Ferramenta de auditoria com falso-positivo em massa**: **RESOLVIDO na ferramenta**. Manter como lição operacional: evidência do auditor deve ser confrontada com analyzer quando apontar falhas estruturais.
2. **P1 — Concentradores de complexidade muito grandes**: `server/lib/ai/optimize_runtime_support.dart` (4197 linhas) e `server/routes/ai/optimize/index.dart` (3495 linhas) seguem como gargalos de manutenção.
3. **P1 — Duplicação de helpers e lógica espalhada**: múltiplas funções com mesmo nome e mesma intenção aparecem em módulos de IA, meta e rotas HTTP, aumentando risco de drift.
4. **P1 — Entry point local quebrado**: `server/bin/local_test_server.dart` depende de `../.dart_frog/server.dart`, inexistente no checkout atual, e faz `dart analyze` do backend falhar.
5. **P1 — Ownership em rotas deck/AI**: resolvido nos fluxos app-facing principais (`POST /ai/optimize`, `GET /ai/optimize/jobs/:id`, `POST /ai/archetypes`) em `origin/master@65f30387`; rotas experimentais seguem bloqueadas para promocao sem contrato owner/public/meta.
6. **P1 — Politicas por nome**: resolvido para as listas apontadas pelo verificador (`premiumLandNames`, high-power e candidate-quality premium) via `commander_fallback_policy.dart`; novas excecoes por nome devem entrar apenas em policy versionada ou fixture/teste.
7. **P2/P3 — Tabelas PostgreSQL write-only ou parcialmente consumidas**: `deck_matchups` e `deck_weakness_reports` recebem persistencia, mas nao possuem leitura/uso confirmado fora da chamada que gerou o dado. `ml_prompt_feedback` tem helper de insert sem chamador e apenas contador operacional. `commander_reference_decks`/`commander_reference_deck_cards` sao persistidas como raw corpus, mas o produto le somente o agregado `commander_reference_deck_analysis`.

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
- **Status em `origin/master@65f30387`: RESOLVIDO para as listas apontadas pelo
  verificador.** `premiumLandNames`, high-power e candidate-quality premium
  passaram a usar `server/lib/ai/commander_fallback_policy.dart`. Mantido aqui
  como histórico; novas excecoes por nome devem entrar apenas em policy
  versionada ou fixture/teste.
- **Evidência**:
  - Revalidacao Copilot em `origin/master@00437690` confirmou PASS para:
    prioridade `functional_tags_then_semantic_v2_then_heuristic`,
    preservacao multi-role no optimize, testes semanticos focados e docs
    operacionais.
  - A mesma revalidacao ficou PARTIAL para politicas por nome: fallbacks
    Commander foram centralizados em `commander_fallback_policy.dart`, mas ainda
    existem scoring/listas como `premiumLandNames` em
    `optimize_runtime_support.dart` e sets premium/high-power em
    `candidate_quality_data_support.dart`.
- **Impacto**: a maior parte do pipeline semantico ja converge, mas parte da
  decisao de score/bracket/premium ainda depende de listas inline, dificultando
  versao, auditoria e rollout controlado.
- **Ação recomendada**:
  1. mover as excecoes restantes para modulo/config/tabela de policy versionada;
  2. enriquecer cada entrada com role, bracket, motivo, fonte e data;
  3. manter filtros de legalidade, identidade de cor, budget/bracket e dados
     semanticos antes do retorno;
  4. adicionar testes focados para a policy restante.
- **Validação**:
  - `rg "Sol Ring|Command Tower|Thassa's Oracle|Isochron Scepter|Dramatic Reversal|Blood Artist" server/lib server/routes app/lib`
    nao encontra decisao runtime fora de fixtures, docs, prompts ou policy
    versionada;
  - testes provam que score/bracket/premium vem da policy e continua respeitando
    legalidade, identidade de cor e bracket.

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

### P1 — Alinhar ownership entre `app/lib`, rotas e helpers de deck/AI
- **Status em `origin/master@65f30387`: RESOLVIDO para os fluxos app-facing
  principais.** `POST /ai/optimize`, `GET /ai/optimize/jobs/:id` e
  `POST /ai/archetypes` agora sao owner-scoped e possuem testes source/live.
  Permanece a regra de produto: rotas experimentais abaixo nao devem ser
  promovidas ao app sem contrato owner/public/meta e testes.
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
  1. antes de expor endpoints experimentais no app, escolher entre escopar por
     dono, limitar a deck publico/meta deck, ou remover/ocultar o contrato;
  2. criar rota dedicada ou teste de contrato para `/community/decks/following`,
     hoje implementada como branch `id == 'following'` em `[id].dart`.
- **Validação**:
  - testes owner vs non-owner para cada rota experimental mantida;
  - `rg "/ai/simulate-matchup|/ai/weakness-analysis|/decks/.*/simulate|/decks/.*/recommendations" app/lib`
    continua vazio ate haver contrato seguro;
  - polling de job com `user_id = NULL` retorna 404 ou fica restrito a rota
    interna documentada.

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
