# Hermes Analysis: Backend Actionable Tasks

> Tasks validadas no codigo (`origin/master` 771c9318) em 2026-05-28.
> Escopo: contratos/rotas backend, IA semantica e optimize. Nenhuma task foi criada por suposicao.
>
> Atualizacao Copilot em 2026-05-28: `origin/master@65f30387` resolveu os
> guards owner-scoped de `POST /ai/optimize`, `GET /ai/optimize/jobs/:id` com
> `user_id = NULL`, e `POST /ai/archetypes`. Backlog ativo remanescente neste
> arquivo: BE.2, BE.5, BE.6 e BE.7.
>
> Atualizacao Copilot em 2026-05-28: `origin/master@32418bc6` resolveu BE.2 com
> `server/test/ai_optimize_semantic_enforcement_route_contract_test.dart` e o
> builder de contrato `buildSemanticV2OptimizeRejectedBody(...)`. Backlog ativo:
> BE.5, BE.6 e BE.7.
>
> Atualizacao Codex em 2026-05-29: revalidado no `master` atual que ownership
> de BE.1/BE.3/archetypes permanece resolvido por source guards. BE.6 foi
> encaminhado no codigo/docs com `GET /ready` documentado como alias operacional
> estavel de `/health/ready` e source guard em `health_readiness_support_test`.
>
> Atualizacao Codex em 2026-05-29: `origin/master@1aa4da71` resolveu BE.5
> threadando `currentDeckCards`/`state.virtualDeck` nos fillers de
> optimize/complete, removendo fallback `bracket: null` quando o bracket foi
> definido e adicionando source guard em `optimize_runtime_support_test`.
>
> Atualizacao Codex em 2026-05-29: `origin/master@4913a733` resolveu BE.7 com
> `optimize_diagnostics.bracket_policy` em respostas de sucesso que tiveram
> sugestoes filtradas por bracket, mantendo `warnings.blocked_by_bracket` por
> compatibilidade e atualizando o contrato de `/ai/optimize`.
> Backlog ativo deste arquivo apos essa rodada: nenhum BE.* aberto.

## P1 — Alto

### BE.1 — `POST /ai/optimize` carrega deck sem escopo de ownership
- **Status em `origin/master@65f30387`: RESOLVIDO.** O loader de contexto de
  optimize recebe `userId`, escopa deck por `id + user_id`, e os testes source
  cobrem o guard. Mantido aqui apenas como histórico da origem do fix.
- **Evidencia:** `server/routes/ai/optimize/index.dart` le `userId` via `context.read<String>()`, mas permite `null` (`linhas 400-405`) e chama `optimize_request.loadOptimizeDeckContext` sem `userId` (`linhas 544-557`). `server/lib/ai/optimize_request_support.dart` define o loader sem parametro `userId` (`linhas 53-62`), busca o deck com `SELECT name, format FROM decks WHERE id = @id` (`linhas 63-73`) e cartas com `WHERE dc.deck_id = @id` (`linhas 87-137`). Como contraste, `server/routes/decks/[id]/cards/bulk/index.dart` usa `WHERE id = @deckId AND user_id = @userId LIMIT 1` (`linhas 68-75`).
- **Impacto de produto:** Usuario autenticado pode potencialmente solicitar otimizacao/analise de deck privado de outro usuario se obtiver o UUID, expondo composicao e sugestoes de IA.
- **Risco:** Privacidade e custo/uso indevido de IA; rota fica autenticada, mas a autorizacao do recurso nao aparece no caminho inspecionado.
- **Acao recomendada:** Passar `userId` para `loadOptimizeDeckContext`; escopar a query de deck por `id + user_id` ou implementar regra explicita de deck publico; impedir criacao de job async antes da checagem de ownership; retornar 404/403 sem vazar existencia.
- **Validacao exigida:** Testes de rota para owner consegue otimizar, non-owner recebe 404/403, deck inexistente recebe 404, e caminho async nao cria job para deck nao autorizado.
- **Prioridade:** P1.

### BE.2 — Semantic Layer v2 `partial` tem helper testado, mas falta teste de rota `OPTIMIZE_SEMANTIC_V2_REJECTED`
- **Status em `origin/master@32418bc6`: RESOLVIDO.** O contrato de payload da
  rota agora é testado por
  `server/test/ai_optimize_semantic_enforcement_route_contract_test.dart`,
  cobrindo `OPTIMIZE_SEMANTIC_V2_REJECTED`,
  `blocked_by_semantic_v2=true`, roles criticas/review e
  `optimize_diagnostics.semantic_layer_v2.enforcement_mode=partial`.
- **Evidencia:** A rota le `SEMANTIC_LAYER_V2_OPTIMIZE_ENFORCEMENT` (`server/routes/ai/optimize/index.dart` linhas 435-439), avalia `evaluateOptimizationSemanticV2Enforcement` (`linhas 2509-2518`) e retorna 422 com `quality_error.code == OPTIMIZE_SEMANTIC_V2_REJECTED`, `blocked_by_semantic_v2` e diagnosticos (`linhas 2531-2556`). `server/test/optimization_validator_test.dart` cobre helpers: default disabled nao bloqueia (`linhas 146-174`) e partial bloqueia perdas criticas (`linhas 177-189`). Busca em `server/test` por `OPTIMIZE_SEMANTIC_V2_REJECTED|SEMANTIC_LAYER_V2_OPTIMIZE_ENFORCEMENT|blocked_by_semantic_v2` encontrou apenas asserts helper-level em `optimization_validator_test.dart`.
- **Impacto de produto:** Antes de ativar `SEMANTIC_LAYER_V2_OPTIMIZE_ENFORCEMENT=partial`, nao ha prova de que o endpoint real retorna payload/diagnosticos corretos, nem de que a integracao sync/async preserva o contrato.
- **Risco:** Regressao so aparecer depois de habilitar enforcement parcial, especialmente em shape de resposta, telemetria e classificacao de quality error.
- **Acao recomendada:** Adicionar teste de rota/integracao com partial ativo e um caso que perda role critica (`draw`, `removal`, `ramp` ou `wipe`) passando pelo gate atual.
- **Validacao exigida:** Assertar 422, `quality_error.code`, `blocked_by_semantic_v2 == true`, roles criticas/review e `optimize_diagnostics.semantic_layer_v2.enforcement_mode == partial`; rodar analyze/testes focados.
- **Prioridade:** P1 antes de habilitar partial fora de staging/controlado.

## P2 — Medio/Alto

### BE.3 — `GET /ai/optimize/jobs/:id` permite leitura de job com `user_id = NULL`
- **Status em `origin/master@65f30387`: RESOLVIDO.** Polling de job user-facing
  bloqueia job sem owner e non-owner; mantido aqui apenas como histórico.
- **Evidencia:** `server/routes/ai/optimize/jobs/[id].dart` le `userId` e carrega job por id (`linhas 26-28`), mas so bloqueia quando `job.userId != null && job.userId != userId` (`linhas 39-47`). A rota de optimize cria jobs async com `userId: userId` (`server/routes/ai/optimize/index.dart` linhas 456-463 e caminho complete async equivalente), enquanto o `userId` foi capturado como nullable (`linhas 400-405`).
- **Impacto de produto:** Qualquer job salvo com `user_id = NULL` fica consultavel por quem souber o job id, podendo revelar resultado de otimizacao/analise.
- **Risco:** Menor que BE.1 por depender de job id de alta entropia, mas ainda e caminho de exposicao de dados.
- **Acao recomendada:** Exigir owner nao nulo para jobs user-facing; em polling, retornar 404 para job sem owner salvo excecao interna explicitamente marcada; reforcar contrato de `OptimizeJobStore.create`.
- **Validacao exigida:** Testes para dono consulta, outro usuario recebe 404, job null-owner recebe 404, criacao normal grava `user_id` nao nulo.
- **Prioridade:** P2.

### BE.4 — Contrato de optimize nao documenta semantica de ownership/acesso
- **Evidencia:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md` linha 164 documenta body/response de `POST /ai/optimize`, mas nao declara se `deck_id` precisa pertencer ao usuario autenticado, se decks publicos sao aceitos ou qual status para unauthorized. Linha 165 documenta `GET /ai/optimize/jobs/:id`, mas nao explicita owner-only/null-owner. A evidencia de codigo em BE.1/BE.3 mostra ambiguidade operacional.
- **Impacto de produto:** App, QA e backend ficam sem contrato para comportamento de seguranca em endpoint sensivel.
- **Risco:** Ambiguidade facilita manter ou reintroduzir bug de autorizacao.
- **Acao recomendada:** Atualizar o contrato para exigir owner do deck (ou regra publica desenhada), documentar status/body para unauthorized/missing, e declarar que polling so retorna job do criador.
- **Validacao exigida:** Testes de contrato/rota alinhados ao documento.
- **Prioridade:** P2.

### BE.5 — Fillers de optimize/complete aplicam bracket sem estado atual do deck em alguns caminhos
- **Status em `origin/master@1aa4da71`: RESOLVIDO.** Os loaders de fillers
  agora recebem o estado atual/virtual do deck em `loadCompetitiveNonLandFillers`,
  `loadBroadCommanderNonLandFillers` e `loadEmergencyNonBasicFillers`.
  `loadGuaranteedNonBasicFillers` nao cai mais para fallback `bracket: null`
  quando o bracket foi informado, e o source guard em
  `server/test/optimize_runtime_support_test.dart` bloqueia regressao para
  `currentDeckCards: const []`, fallback condicional `if (filtered.isNotEmpty)`
  e complete sem `state.virtualDeck`.
- **Evidencia:** Filtro final de optimize usa estado atual corretamente (`server/routes/ai/optimize/index.dart` linhas 1750-1753). Mas `loadDeterministicSlotFillers` recebe `currentDeckCards` para slot needs (`server/lib/ai/optimize_runtime_support.dart` linhas 840-855) e chama `loadCompetitiveNonLandFillers` sem passar esse estado (`linhas 857-863`). Dentro dos loaders, a politica de bracket e aplicada com `currentDeckCards: const []` em tres pontos (`optimize_runtime_support.dart` linhas 1106-1110, 1386-1390 e 1465-1469). `loadGuaranteedNonBasicFillers` ainda cai para chamadas com `bracket: null` quando falta preencher (`linhas 1171-1182` e 1206-1214). `optimize_complete_support.dart` chama emergency fillers com `bracket`, mas sem `currentDeckCards` (`linhas 1098-1107`).
- **Impacto de produto:** Decks low-bracket que ja consumiram budget de fast mana/tutor/free interaction podem gerar pools de filler como se nao tivessem cartas relevantes, reduzindo determinismo de power-level em complete/rebuild/top-up.
- **Risco:** Medio; filtro final pode segurar alguns casos, mas a geracao de candidatos e fallbacks sem bracket degradam explicabilidade/consistencia.
- **Acao recomendada:** Threadar estado atual/virtual para `loadCompetitiveNonLandFillers`, `loadBroadCommanderNonLandFillers` e `loadEmergencyNonBasicFillers`; evitar fallback silencioso `bracket: null` ou registrar degradacao no response.
- **Validacao exigida:** Testes com bracket 1 e deck atual contendo `Sol Ring`, candidatos incluindo `Mana Crypt`/fast mana extra; assertar bloqueio nos caminhos deterministic, broad, emergency, complete e rebuild.
- **Prioridade:** P2.

### BE.6 — `/ready` documentado como deprecated/not audited apesar de ser alias operacional de `/health/ready`
- **Status em `master` atual:** RESOLVIDO. `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
  documenta `GET /ready` como `internal/stable ops alias`, com mesmo contrato de
  `/health/ready`; `server/test/health_readiness_support_test.dart` possui source
  guard garantindo delegacao para `health/ready`.
- **Evidencia:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md` linha 306 classifica `GET /ready` como `internal/deprecated`, request/response/data source/test `Not proven`. `server/routes/ready/index.dart` linhas 5-10 documenta explicitamente `/ready` como readiness check para deploy/smoke e delega para `health_ready.onRequest(context)`. `CHECKLIST_GO_LIVE_FINAL.md` linhas 16 e 25-29 registra `/ready` publicado/validado junto de `/health/ready` e eco de `x-request-id`.
- **Impacto de produto:** Ops e agentes podem tratar uma rota ativa de smoke/deploy como deprecated e deixar de validar/monitorar corretamente.
- **Risco:** Doc drift operacional, nao bug runtime.
- **Acao recomendada:** Atualizar `API_CONTRACTS_AND_DATA_MAP.md` para `internal/stable ops alias`, response herdado de `/health/ready`, e teste/evidencia apontando para readiness support/smoke.
- **Validacao exigida:** Teste/contrato simples de delegacao `/ready` ou referencia explicita ao teste de `/health/ready`.
- **Prioridade:** P2.

## P3 — Baixo

### BE.7 — Bloqueios por bracket sao detalhados no 422, mas quase invisiveis em sucesso parcial
- **Status em `origin/master@4913a733`: RESOLVIDO.** Respostas de sucesso agora
  podem expor `optimize_diagnostics.bracket_policy` com `bracket`,
  `blocked_count`, `blocked_additions` e `message` quando a policy removeu
  sugestoes mas ainda restaram swaps acionaveis. `warnings.blocked_by_bracket`
  permanece como campo compatível. O contrato foi atualizado em
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md`, e
  `server/test/ai_optimize_semantic_enforcement_route_contract_test.dart`
  cobre preservacao de diagnosticos existentes.
- **Evidencia:** A rota calcula `blockedByBracket` e filtra `validAdditions` (`server/routes/ai/optimize/index.dart` linhas 1728-1763). O detalhe entra em `quality_error.blocked_by_bracket` quando nao sobram swaps acionaveis e retorna 422 (`linhas 1950-1972`). O mesmo dado e passado para telemetria, mas nao aparece como campo claro do JSON de sucesso parcial.
- **Impacto de produto:** Quando a otimizacao ainda tem swaps validos, o usuario/app pode nao saber que outras sugestoes foram removidas por bracket, reduzindo explicabilidade.
- **Risco:** UX/diagnostico, nao seguranca.
- **Acao recomendada:** Adicionar campo aditivo em sucesso, por exemplo `optimize_diagnostics.bracket_policy.blocked` ou `validation.blocked_by_bracket`, e documentar.
- **Validacao exigida:** Teste de sucesso com pelo menos uma adicao bloqueada e outra valida; clientes toleram campo aditivo.
- **Prioridade:** P3.
