# Receipt — BT-AI-029: registry das rotas de IA e a remoção da D-31 — 2026-09-28

- Tarefa: `BT-AI-029`, Frente A (servidor), branch `servidor/rodada2-2026-09-24`.
- Aceite do backlog: um registry de todas as rotas de IA, com consumidor, escritas,
  capability, dono e substituto.
- Decisão do dono aplicada: D-31, de 2026-09-22. Ela manda remover as quatro rotas sem
  consumidor, junto com os testes que as tratam como recurso:
  - `POST /decks/:id/recommendations`;
  - `GET /decks/:id/simulate`;
  - `POST /ai/simulate-matchup`;
  - `POST /ai/weakness-analysis`.

  Os substitutos são Optimize, Battle e Analyze. A janela de telemetria na produção foi
  dispensada. `GET /ai/ml-status` fica com o `BT-AI-027`. `/ai/optimize/telemetry` segue off,
  e o registry decide por ela com a mesma regra.
- Pedido da coordenação: anotar por rota quem chama um provedor externo, se a URL do
  provedor é configurável e o que acontece sem chave. Isso sai do achado da sessão do gate
  sobre `OPENAI_BASE_URL`.
- Nada tocou a produção. O E2E rodou numa API local presa ao loopback, sobre o PostgreSQL
  descartável da frente.

## O registry

`server/config/ai_route_registry.json` (`ai_route_registry_v1`) tem 34 entradas: 24 sob
`/ai` e 10 de IA sob `/decks/:id`.

**Regra de escopo.** Rota de IA é:

- toda rota sob `/ai`;
- toda rota que `requiredCapabilityForRequest` põe numa capability de IA
  (`ai_analyze_optimize_advisory`, `ai_generate_rebuild`, `legacy_ai_routes`,
  `learning_reads`, `learning_writes`, `battle_batch`, `battle_live` ou `battle_coach`);
- todo handler que fala com o provedor direto (`api.openai.com` ou `OpenAiRuntimeConfig`).

**Campos de cada entrada:**

| Campo | Conteúdo |
| --- | --- |
| método, caminho e handler | a rota e o arquivo que a atende |
| `status` | `guarded_off` (tem consumidor; capability desligada até as tarefas fecharem) ou `legacy_off` (sem consumidor; tem veredito e substituto) |
| `capability` | a mesma da política de capability |
| `access_policy` | só em `/ai`: cobrada no plano, auxiliar com limite, acompanhamento ou só autenticada |
| `legal_reacceptance` | se a trava do reaceite (D-24) vale |
| `owner` e `lane` | a tarefa do backlog dona da próxima decisão e a raia (`deck_e_ia` ou `battle`) |
| `consumers` | arquivo e trecho que chama a rota; sem consumidor, o motivo |
| `writes` | tabelas que a rota grava, direto ou pelos serviços que chama |
| `external_providers` e `without_provider` | provedor externo e o que acontece sem ele |
| `substitute` e `rule_verdict` | nas rotas legadas |
| `provider_calls`, `provider_calls_without_key` e `evidence_note` | por enquanto só no `/ai/optimize`: cada ponto em que a rota tenta o provedor, o que é tentado sem chave e como ler a prova |

**Provedores** (bloco `providers`):

| Provedor | URL | Configurável | Sem ele |
| --- | --- | --- | --- |
| OpenAI (chat completions) | `https://api.openai.com/v1/chat/completions` | **não**: a URL está fixa em 8 pontos de 7 arquivos; a fixture isolada exporta `OPENAI_BASE_URL` vazia, e nenhum código do servidor a lê | produção: 503; fora dela: mock ou fallback local marcado `is_mock`, nunca cacheado nem aplicável; o Optimize entrega as trocas determinísticas quando há shortlist (D-82) |
| EDHREC | `https://json.edhrec.com` | não | com a coleta desligada (padrão), nada sai e a validação é pulada |
| Sidecars de Battle (XMage, Forge, nativo, interativo) | variáveis `*_SIDECAR_URL` | sim | o motor falha fechado com 503 e código estável |
| MTGTop8 | `https://www.mtgtop8.com` | não | só na atualização de referência (administrador); a leitura segue do PostgreSQL |

**Achados da sessão do gate, agora no registry:**

- **`OPENAI_BASE_URL` é inerte.**
  - A fixture isolada exporta a variável, mas nenhum código do servidor (`lib` e `routes`) a
    lê.
  - Só o entrypoint do laboratório Hermes (`server/bin/hermes_lab_entrypoint.sh`) a usa, e
    para o próprio Hermes.
  - O teste falha se o código do servidor passar a ler a variável enquanto o registry disser
    que a URL não é configurável.
- **A URL fica fixa em cada ponto de chamada.**
  - A sessão do gate achou quatro pontos em `server/lib`.
  - A varredura completa acha 9 pontos em 8 arquivos antes da D-31 e 8 em 7 depois, porque
    `deck_recommendations_route_support.dart` saiu.
  - O registry guarda a contagem por arquivo (`callsite_occurrences`), e o teste conta de
    novo: um ponto novo falha, inclusive num arquivo já registrado.
- **O `POST /ai/optimize` tenta o provedor em quatro pontos** (`provider_calls`). Cada um diz
  o endpoint com que grava em `ai_logs`, quando acontece e o que acontece se falhar:
  - a tentativa primária do otimizador, quando não há shortlist determinística;
  - o fallback por IA, uma vez por pedido;
  - o Critic IA, na validação depois das trocas, **inclusive das determinísticas**. Se ele
    falhar, a resposta sai normalmente, sem o crítico;
  - a montagem no modo complete.
- **Sem chave, nenhum desses pontos é tentado** (D-82, `provider_calls_without_key`).
- **O `evidence_note` muda a leitura de um manifesto de captura.** Com chave,
  `ai_upstream_called: false` quer dizer que as trocas não vieram da IA, e não que nada foi
  tentado.

**Achados que o registry torna visíveis**, com a recomendação em `decisoes-pendentes.md`:

- `POST /ai/explain` grava a explicação do provedor em `cards.ai_description`, um cache
  compartilhado do catálogo.
- `/ai/optimize/telemetry` não tem consumidor.
- A URL do provedor é fixa.

## O teste que falha quando surge rota de IA fora do registry

`server/test/ai_route_registry_test.dart`:

1. **Descoberta.** Varre `server/routes`, deduz caminho e métodos de cada handler e aplica a
   regra de escopo. Rota de IA que não está no registry falha, e entrada do registry sem rota
   também.
2. **Coerência de cada entrada:**
   - o handler existe e declara o método;
   - a capability é a da política;
   - o dono é uma tarefa do backlog;
   - cada consumidor existe e contém o trecho que chama a rota;
   - handler que grava tem `writes`;
   - handler que fala com o provedor declara a OpenAI;
   - a política de `/ai` e a trava do reaceite batem com o código;
   - rota legada tem substituto e veredito.
3. **Provedores.**
   - Cada provedor diz a URL, se ela é configurável e o que acontece sem ele.
   - O conjunto de arquivos com a URL do provedor é igual à lista registrada, e a contagem
     por arquivo também. Uma chamada nova ao provedor falha, e um ponto novo num arquivo já
     registrado também.
   - Nenhum código lê `OPENAI_BASE_URL` enquanto o registry disser que a URL não é
     configurável.
4. **As chamadas ao provedor do `/ai/optimize`.**
   - Cada uma aponta para um arquivo registrado.
   - Esse arquivo grava a chamada em `ai_logs` com o endpoint declarado.
   - O Critic IA está na lista.
   - A entrada diz o que é tentado sem chave.
5. **As quatro rotas da D-31 não voltam.**
   - Nenhum handler delas existe.
   - As duas de `/ai` não têm capability: caem em rota não classificada.

## A remoção da D-31

**Saíram 19 arquivos:**

- os 5 de rota: `recommendations` (handler e middleware), `decks/[id]/simulate`,
  `ai/simulate-matchup` e `ai/weakness-analysis`;
- as 6 bibliotecas que só elas usavam: `deck_recommendations_*` (4 arquivos),
  `archetype_counters_service.dart` e `ai/deck_advanced_analysis.dart`;
- os 7 testes que as tratavam como recurso;
- `server/test/test_reco.sh`, o smoke de produção das recomendações.

**Ajustados:**

- `routes/ai/_middleware.dart`: as duas rotas saíram da lista auxiliar.
- `lib/release_capability_policy.dart`: sem o mapeamento das quatro. As de `/ai` caem em
  rota não classificada (404 e contador próprio); as de `/decks/:id` não têm handler.
- `lib/deck_write_verification_policy.dart`: a exceção da rota removida saiu.
- `lib/openai_runtime_config.dart`, `lib/openai_structured_output_support.dart` e
  `.env.example`: o modelo, o schema e as variáveis das recomendações saíram.
- Testes de contrato que citavam as rotas: `ai_middleware_order_contract_test`,
  `ai_error_observability_contract_test`, `deck_write_verified_email_test`,
  `experimental_deck_ai_authorization_source_test`, `land_type_boundary_contract_test`,
  `ramp_floor_consumer_contract_test`, `openai_structured_output_support_test`,
  `error_contract_test`, `api_contracts_data_map_guard_test` e
  `semantic_tag_query_contract_test`. Este último virou guarda global contra a consulta por
  chave de texto.
- Scripts de E2E legados (`e2e_general_tests.py`, `e2e_ml_tests.py`) e a etapa do
  `scripts/manaloom_e2e_suite.sh`, que agora roda o teste do registry.
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`: as quatro linhas saíram, e uma seção nova diz
  como a rota responde depois da remoção e qual é o substituto.
- `docs/BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md`: o inventário aponta para o
  registry.
- `docs/privacy/data_retention_inventory.json`: `deck_weakness_reports` e `deck_matchups`
  ficam sem escritor. As linhas antigas seguem na exportação e na exclusão, e descartar as
  tabelas fica com o `BT-DB-005`.
- `server/bin/cron_sync_combos.sh`: o comentário diz que o consumidor saiu.

**Ficou de fora:**

- `app/lib/core/api/api_client.dart` ainda tem a heurística de tempo limite
  `endsWith('/recommendations')`. É raiz do digest de UI e fica com a raia do app. Não chama
  a rota.
- Não houve migration: as tabelas `deck_weakness_reports` e `deck_matchups` ficam.

## Evidência

Tudo local: o PostgreSQL 17 descartável da frente (`LC_ALL=C`, 62 migrações, última 062) e
a API presa ao loopback, parados ao fim.

- **Registry e foco:**
  - `server/test/ai_route_registry_test.dart`: 6/6.
  - O foco tem 76 arquivos e 647 testes verdes, sem os `*_live_test`. Cobre rotas de IA,
    capability, contratos, erros, privacidade e inventário, optimize e os guardas de contrato
    que o patch mudou.
- **Na trava, das 16:09Z às 16:11Z:**
  - o patch foi aplicado sobre `edac29e0b`, seguido do `project_logic --write`;
  - `dart analyze` de `lib`, `bin`, `routes` e `test` saiu sem achados;
  - o build da API é das 16:11:46Z.
- **E2E por HTTP**, contra esse build:
  - **Guarda de egress:** sem chave, sob a mesma guarda da D-82 (`sandbox-exec`, só
    loopback). O autoteste recusou `1.1.1.1:53`.
  - **Capabilities:** `account_registration`, `decks_private`, `ai_analyze_optimize_advisory`
    e `legacy_ai_routes`.
  - `ai_route_registry_e2e_live_test.dart`: 2/2.
    - As quatro rotas removidas dão 404, mesmo com `legacy_ai_routes` ligada. As duas de
      `/ai` respondem `capability_route_unclassified`.
    - `GET /decks/:id/analysis` responde 200, e `GET /ai/ml-status` continua existindo.
  - `optimize_without_provider_e2e_live_test.dart`, na mesma API: 2/2. A D-82 segue igual.
  - **Sonda sem token:**
    - `POST /ai/weakness-analysis` e `POST /ai/simulate-matchup` dão 404
      `capability_route_unclassified`, com `request_id`;
    - `GET /ai/ml-status` dá 401 `auth_unauthorized`, porque a rota existe.
  - O log da API tem zero `ClientSocketException`, `Critic AI`, `ai_optimize_call` e
    `Optimization failed`.
  - **Regressão com as capabilities padrão:** erros públicos, convite e limites, 21/21.
  - **Regressão do reaceite:** 2/2, com `MANALOOM_LEGAL_REACCEPTANCE=enforce` e as
    capabilities do BT-LEGAL-ACCEPT-001.
- **Banco:** os 13 `*_db_live_test` da frente, com 78 verdes e 2 pulados. Os pulados são a
  rodada com chave da D-82, que roda no roteiro próprio.

## Mutações

Cada mutação foi aplicada no worktree. Depois rodou o teste do registry. Por fim, o arquivo
foi restaurado e conferido byte a byte; arquivo criado pela mutação foi apagado. As 15
falham como esperado. O roteiro fica no apoio da frente: `mutations_ai029.py` e
`run_mutation_ai029.sh`.

| Mutação | O que muda | Falha em |
| --- | --- | --- |
| M92 | rota de IA nova sem entrada no registry | descoberta, 5/6 |
| M93 | a entrada de uma rota existente some do registry | descoberta, 5/6 |
| M94 | a capability da entrada diverge da política | coerência, 5/6 |
| M95 | ponto novo com a URL fixa num arquivo já registrado | provedores, 5/6 |
| M96 | chamada nova ao provedor num arquivo fora do registry | provedores, 5/6 |
| M97 | o código passa a ler `OPENAI_BASE_URL` | provedores, 5/6 |
| M98 | o handler de uma rota da D-31 volta | D-31 e descoberta, 4/6 |
| M99 | a política volta a classificar uma rota da D-31 | D-31, 5/6 |
| M100 | o trecho do consumidor não está no arquivo do app | coerência, 5/6 |
| M101 | a trava do reaceite no registry diverge do código | coerência, 5/6 |
| M102 | a política de acesso de `/ai` diverge do middleware | coerência, 5/6 |
| M103 | o Critic IA sai das chamadas ao provedor do `/ai/optimize` | chamadas ao provedor, 5/6 |
| M104 | o validador grava o Critic IA com outro endpoint | chamadas ao provedor, 5/6 |
| M105 | o dono não é tarefa do backlog | coerência, 5/6 |
| M106 | rota legada sem substituto | coerência, 5/6 |
