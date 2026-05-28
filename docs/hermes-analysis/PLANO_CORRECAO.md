# Plano de Correcao — Audit de Estrutura

> Data: 2026-05-28 00:01 UTC
> Escopo: documentar problemas estruturais detectados em `STRUCTURE_AUDIT.md` sem alterar codigo de produto.

## Resumo executivo

O auditor gerou muito ruído por inferir imports relativos a partir do root do repositório, então os **178 "imports quebrados" não podem ser tratados como defeitos reais** sem revalidação por `dart analyze` ou por resolução relativa ao diretório do arquivo Dart. Ainda assim, o relatório revelou três frentes prioritárias de organização:

1. **P0 — Ferramenta de auditoria com falso-positivo em massa**: o próprio relatório produz evidência estrutural pouco confiável e pode induzir correções erradas.
2. **P1 — Concentradores de complexidade muito grandes**: `server/lib/ai/optimize_runtime_support.dart` (4197 linhas) e `server/routes/ai/optimize/index.dart` (3495 linhas) seguem como gargalos de manutenção.
3. **P1 — Duplicação de helpers e lógica espalhada**: múltiplas funções com mesmo nome e mesma intenção aparecem em módulos de IA, meta e rotas HTTP, aumentando risco de drift.
4. **P1 — Entry point local quebrado**: `server/bin/local_test_server.dart` depende de `../.dart_frog/server.dart`, inexistente no checkout atual, e faz `dart analyze` do backend falhar.
5. **P1 — Incoerencia de ownership em rotas deck/AI**: `POST /ai/optimize` e algumas rotas experimentais aceitam `deck_id` autenticado sem escopar a leitura por `user_id`, apesar de o app tratar decks como recursos privados do usuario.
6. **P2 — Tabelas PostgreSQL write-only em rotas experimentais**: `deck_matchups` e `deck_weakness_reports` recebem persistencia, mas nao possuem leitura/uso confirmado fora da chamada que gerou o dado.

## Achados priorizados

### P0 — Corrigir o `structure_auditor.py` antes de usar a contagem de imports quebrados como verdade
- **Evidência**:
  - `STRUCTURE_AUDIT.md` lista imports como "não encontrado" para arquivos que existem, por exemplo:
    - `server/routes/ai/_middleware.dart` → `../../lib/auth_middleware.dart`
    - `server/routes/auth/login.dart` → `../../lib/auth_service.dart`
  - Verificação direta no filesystem confirmou que os alvos existem em `server/lib/`.
- **Impacto**: priorização errada, documentação enganosa e risco de criar refactors desnecessários.
- **Causa provável**: o auditor resolve caminhos relativos de import contra o diretório errado (provavelmente o root do repo, não o diretório do arquivo origem).
- **Ação recomendada**:
  1. ajustar a resolução de imports relativos no script;
  2. separar "imports potencialmente quebrados pelo parser" de "imports inválidos confirmados por analyzer";
  3. deduplicar ocorrências repetidas no relatório.
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
- **Impacto**: mudança semântica em um ponto não propaga automaticamente para os demais; risco de respostas inconsistentes por endpoint/fluxo.
- **Ação recomendada**:
  1. agrupar duplicações por domínio (IA semântica, utilitários HTTP, utilitários de deck);
  2. extrair helpers compartilhados apenas quando a semântica for realmente idêntica;
  3. manter wrappers locais somente se o contexto justificar nomes iguais com comportamento diferente.
- **Validação**:
  - grep/listagem de duplicados reduzida;
  - testes existentes seguem verdes;
  - revisão de imports mostra dependência convergindo para helpers compartilhados.

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
- **Evidência**:
  - O app envia `POST /ai/optimize` com `deck_id` em
    `app/lib/features/decks/providers/deck_provider_support_ai.dart`, mas
    `server/routes/ai/optimize/index.dart` chama
    `loadOptimizeDeckContext` sem `userId`.
  - `server/lib/ai/optimize_request_support.dart` consulta `decks` e
    `deck_cards` apenas por `deckId`.
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
  1. passar `userId` para `loadOptimizeDeckContext` e escopar queries de deck por
     `id + user_id`, salvo regra publica explicita;
  2. exigir `userId` nao nulo para jobs async user-facing ou retornar 404 quando
     `job.userId == null`;
  3. antes de expor endpoints experimentais no app, escolher entre escopar por
     dono, limitar a deck publico/meta deck, ou remover/ocultar o contrato;
  4. criar rota dedicada ou teste de contrato para `/community/decks/following`,
     hoje implementada como branch `id == 'following'` em `[id].dart`.
- **Validação**:
  - testes owner vs non-owner para `/ai/optimize` sync/async e para cada rota
    experimental mantida;
  - `rg "/ai/simulate-matchup|/ai/weakness-analysis|/decks/.*/simulate|/decks/.*/recommendations" app/lib`
    continua vazio ate haver contrato seguro;
  - polling de job com `user_id = NULL` retorna 404 ou fica restrito a rota
    interna documentada.

### P2 — Decidir destino de tabelas PostgreSQL persistidas sem consumidor
- **Evidência**:
  - `deck_matchups` é definida em `server/database_setup.sql:162` e recebe
    upsert em `server/routes/ai/simulate-matchup/index.dart:360`, mas nao ha
    `SELECT ... FROM deck_matchups` em `app/`, `server/lib/` ou `server/routes`.
  - `deck_weakness_reports` é definida em `server/database_setup.sql:363` e
    `server/bin/migrate_create_missing_tables.dart:97`, recebe insert em
    `server/routes/ai/weakness-analysis/index.dart:374`, mas nao ha leitura em
    `app/`, `server/lib/` ou `server/routes`; o campo `addressed` tambem nao
    tem fluxo de update confirmado.
- **Impacto**: acumulacao de dados sem produto/operacao consumindo o historico,
  retencao indefinida e falsa impressao de que ha cache, dashboard ou workflow
  persistente para matchup/weakness analysis.
- **Ação recomendada**:
  1. escolher entre manter como log bruto com retencao documentada, criar
     consumidor real ou remover a persistencia dessas rotas experimentais;
  2. se mantiver, adicionar endpoint/job/UI que leia os dados e teste de contrato;
  3. se remover, criar migration/cleanup seguro e atualizar
     `API_CONTRACTS_AND_DATA_MAP.md`.
- **Validação**:
  - `rg "FROM deck_matchups|FROM deck_weakness_reports"` encontra consumidores
    reais, ou a persistencia deixa de existir com decisao documentada;
  - testes das rotas experimentais continuam verdes;
  - contrato app-facing deixa claro se esses dados sao historico persistido ou
    apenas resposta efemera.

## Sequência sugerida

1. **Primeiro**: corrigir o auditor estrutural (P0), porque ele afeta a confiabilidade do restante do relatório.
2. **Segundo**: destravar `dart analyze` do backend via `local_test_server.dart`.
3. **Terceiro**: corrigir ownership/escopo de deck nas rotas app-facing e
   experimentais antes de ligar novos consumidores no app.
4. **Quarto**: atacar duplicações de maior risco no domínio de optimize/IA.
5. **Quinto**: modularizar os arquivos gigantes do otimizador com testes de regressão.
6. **Sexto**: decidir destino das tabelas write-only (`deck_matchups`,
   `deck_weakness_reports`) antes de expandir novas persistencias analiticas.

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
