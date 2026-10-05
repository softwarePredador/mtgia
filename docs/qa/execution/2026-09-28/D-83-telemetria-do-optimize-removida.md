# Receipt — `GET /ai/optimize/telemetry` removida pela regra da D-31 (D-83) — 2026-09-28

- **Decisão:** D-83. O dono aceitou em bloco as recomendações do `BT-AI-029`. O item 1 dizia
  para remover a rota pela mesma regra da D-31, junto com o teste que a tratava como recurso.
- **Dono no backlog:** `BT-AI-029`, o registry das rotas de IA que carrega as remoções. No
  registry, a rota era do `BT-AI-018`.
- **Frente A (servidor)**, branch `servidor/rodada2-2026-09-24`.
- Nada tocou a produção. Sem migration: a tabela `ai_optimize_fallback_telemetry` fica.

## Por que a rota saiu

A regra da D-31 é esta: sai a rota sem consumidor no app, no site e nos scripts que tenha
substituto. A rota se encaixava nela.

- **Consumidor.** Não havia nenhum no app, no site, nos scripts nem no ops. Só o teste ao vivo
  de contrato (`server/test/ai_optimize_telemetry_contract_test.dart`) a chamava.
- **Substituto.** A consulta de operação ao PostgreSQL em `ai_optimize_fallback_telemetry` e o
  painel de `/health/dashboard`, que lê a mesma tabela. O dashboard exige a chave de operação ou
  o JWT de administrador.
- **Estado antes.** Desligada sob `legacy_ai_routes` (`legacy_off`), com o veredito da regra
  no registry.

## O que mudou

- **Saíram** o handler `server/routes/ai/optimize/telemetry/index.dart` e o teste ao vivo
  `server/test/ai_optimize_telemetry_contract_test.dart`. Nenhuma biblioteca ficou órfã: o
  handler só usava auxiliares compartilhados.
- **Capability.** `release_capability_policy.dart` deixa de pôr o caminho em
  `legacy_ai_routes`, e quem ainda chamar cai em rota não classificada: 404
  `capability_route_unclassified`, com contador próprio. É o mesmo destino das duas rotas `/ai`
  da D-31.
- **Middlewares.** A política de acesso de `/ai` e as exceções do reaceite legal deixam de
  citar a rota.
- **Registry.** A entrada sai de `routes` e entra em `removed_routes`, com a decisão `D-83`, o
  substituto e a resposta depois da remoção. A regra do registry menciona a D-83.
- **Testes de guarda.**
  - O `ai_route_registry_test.dart` exige as cinco remoções: as quatro da D-31 e esta, que é a
    única com a decisão D-83. O handler não pode voltar, e o caminho não pode voltar a ter
    capability.
  - O `api_contracts_data_map_guard_test.dart` exige a rota só na seção de removidas, com o
    substituto.
  - A lista do reaceite legal, a das políticas de `/ai` e a de observabilidade de erro das
    rotas perderam a rota.
  - O teste ao vivo removido também saiu de onde era citado: do preset `live` do
    `server/dart_test.yaml`, da lista do `operational_boundary_contract_test.dart` (testes ao
    vivo de IA com conta isolada) e do passo de E2E ao vivo do
    `scripts/manaloom_e2e_suite.sh`, que agora se chama "Server live AI generate optimize E2E".
    A primeira rodada da suíte completa pegou a citação no teste de fronteira operacional.
- **Documentação.**
  - O `API_CONTRACTS` tira a linha viva e o teste da lista de evidência, e acrescenta a rota à
    seção de rotas removidas.
  - O comentário do `.env.example` sobre os administradores deixa de citar a rota.
  - O manual ganha, na seção histórica 61, o aviso da remoção.

## Evidência

- **Foco:** 11 arquivos e 87 testes: registry das rotas de IA, guarda do contrato da API,
  reaceite legal, ordem dos middlewares de IA, observabilidade de erro, política de capability,
  contrato dos pontos de chamada ao provedor, as fontes de autorização do Optimize e do Generate,
  a fronteira operacional e o status do gate de E2E.
- **E2E**, contra a API local buildada com a mudança às 21:31:07Z (`dart analyze` sem achados na
  mesma posse da trava). Guarda de egress (`sandbox-exec`, só loopback; o autoteste recusou
  `1.1.1.1:53`), na API e no processo de teste. Capabilities `account_registration`,
  `decks_private`, `ai_analyze_optimize_advisory` e `legacy_ai_routes`: a legada ligada de
  propósito, para provar que a remoção não depende dela.
  `server/test/ai_route_registry_e2e_live_test.dart` passou 2/2:
  - as rotas removidas respondem 404. `GET /ai/optimize/telemetry`, com e sem
    `?days=7&include_global=true`, dá `capability_route_unclassified`, como as duas `/ai` da
    D-31;
  - as rotas que ficaram seguem respondendo (`GET /decks/:id/analysis` 200 e `/ai/ml-status`,
    que continua sob `legacy_ai_routes`).

  No log do sandbox, a API não teve nenhuma recusa de rede.

## Mutações

Cada mutação foi aplicada no worktree. Rodaram então o teste do registry e a guarda do contrato,
e por fim o arquivo foi restaurado e conferido byte a byte. As 4 falham como esperado.

| Mutação | O que muda | Falha em |
| --- | --- | --- |
| M134 | a capability legada volta a cobrir o caminho | registry: removidas não voltam |
| M135 | o handler volta | registry: removidas não voltam, e rota de IA fora do registry |
| M136 | o contrato volta a listar a rota como viva | guarda do contrato |
| M137 | a remoção perde a decisão que a autoriza | registry: removidas não voltam |
