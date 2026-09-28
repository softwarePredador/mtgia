# Receipt — `GET /ai/generate/jobs/latest` sem job responde 200 `{"job": null}` — 2026-09-28

- **Origem:** a coordenação pediu, depois do conserto do Optimize (`51f58cdbb`), o mesmo
  conserto no Generate. Sem job, a rota respondia 404, e o navegador registra no console, como
  erro, toda resposta 404: cada abertura da tela de geração deixava um SEVERE.
- **Dono no backlog:** a linha do `BT-AI-031`, a mesma do conserto do Optimize. No registry das
  rotas de IA, `GET /ai/generate/jobs/:id` é do `DCK-P0-04`; a nota da rota foi atualizada.
- **Frente A (servidor)**, branch `servidor/rodada2-2026-09-24`.
- Nada tocou a produção. Os testes rodaram num PostgreSQL 17 descartável e numa API local presa
  ao loopback, sob a guarda de egress.

## O contrato antes e agora

| Pedido | Antes | Agora |
| --- | --- | --- |
| `latest?active=true`, sem job ativo | 404 `{error, job_id: "latest"}` | **200 `{"job": null}`** |
| `latest` sem `active` e sem job nenhum | 404 | **200 `{"job": null}`** |
| `latest` com job | 200 com o JSON do job na raiz | igual |
| job de outra conta | nunca aparece no `latest` (a busca é da conta) | igual |
| `GET /ai/generate/jobs/<id>` que não existe ou é de outra conta | 404 | igual |
| `DELETE .../latest` | 405 | igual |

- **O Generate não tem deck.** O pedido falava em manter o 404 para deck alheio, inexistente ou
  id que não é UUID, como no Optimize. Mas o job de geração não tem `deck_id`: a busca do
  `latest` é sempre da conta, e não há deck para conferir.
- **O id do job é texto, não UUID.** Na tabela `ai_generate_jobs`, `id` é `TEXT`. Por isso um
  id qualquer já dava 404, e não 500. O teste de banco fixa esse comportamento.

## O app atual continua compatível

- `fetchLatestGenerateJobRequest` (`app/lib/features/decks/providers/deck_provider_support_generation.dart`)
  trata 404 como "sem job" e devolve o mapa do corpo para 200.
- O único chamador, `_resumeLatestGenerateJobIfAvailable` (`deck_generate_screen.dart`), só
  retoma com `job_id`. Com `{"job": null}` não há `job_id`, e ele não oferece retomar: é o mesmo
  resultado de hoje.
- O dublê da prova visual (`app/integration_test/deck_workshop_visual_runtime_proof_test.dart`)
  responde 404 por conta própria e não depende do servidor.
- Por isso o conserto é só no servidor. Uma leitura explícita do job nulo no app, como a do
  Optimize no rascunho da raia do app, pode ir junto quando a raia abrir.

## Evidência

- **Banco:** `server/test/generate_job_latest_db_live_test.dart` chama o handler da rota contra
  o PostgreSQL descartável, com a fixture de três contas da privacidade (a conta A tem um job de
  geração concluído). Os 7 testes passam:
  - conta sem job ativo, com um concluído: 200 `{"job": null}`;
  - conta sem job nenhum: 200 `{"job": null}` com `active=true`, `active=false` e sem `active`;
  - job ativo: 200 com o job na raiz e sem a chave `job`;
  - o job que terminou some com `active=true` e aparece sem ele;
  - o job de outra conta nunca aparece no `latest`;
  - id concreto de outra conta, inexistente, com injeção ou em forma de UUID: 404, não 500; o
    dono continua vendo o próprio job;
  - `DELETE` em `latest` segue 405.
- **E2E**, contra a API local buildada com a mudança às 20:38:24Z (`dart analyze` sem achados na
  mesma posse da trava). Guarda de egress (`sandbox-exec`, só loopback; o autoteste recusou
  `1.1.1.1:53`), na API e no processo de teste. Capabilities `account_registration`,
  `decks_private` e `ai_generate_rebuild`. Duas contas por convite.
  `server/test/generate_job_latest_e2e_live_test.dart` passou 3/3:
  - sem job, 200 `{"job": null}` com e sem `active`;
  - com um job ativo gravado pelo `AiGenerateJobStore`, 200 com o job; a outra conta continua
    com job nulo, e o id concreto do job alheio dá 404 com `request_id`;
  - id que não existe dá 404, não 500.

  No log do sandbox, a API não teve nenhuma recusa de rede. O processo `dart` do executor de
  testes teve uma consulta ao resolvedor de DNS local recusada pela guarda.
- **Foco:** 16 arquivos e 102 testes (registry das rotas de IA, guarda dos contratos da API,
  autorização e ciclo de vida dos jobs, observabilidade de erro e ordem dos middlewares de IA).
- **Na trava:** `dart analyze` sem achados; a suíte completa roda com o commit.

## Mutações

Cada mutação foi aplicada no worktree. Depois rodou o teste de banco da rota e, por fim, o
arquivo foi restaurado e conferido byte a byte. As 5 falham como esperado.

| Mutação | O que muda | Falha em |
| --- | --- | --- |
| M129 | sem job volta a ser 404 | banco 4/7 |
| M130 | a resposta sem job perde a chave `job` | banco 4/7 |
| M131 | o `latest` responde job nulo mesmo com job | banco 2/7 |
| M132 | o filtro `active=true` é ignorado | banco 2/7 |
| M133 | id concreto que não existe também vira job nulo | banco 1/7 |
