# Receipt — `GET /ai/optimize/jobs/latest` sem job responde 200 `{"job": null}` — 2026-09-28

- **Origem:** achado da sessão do gate (`BT-UIEV-001`). Quando não havia job ativo, a rota
  respondia 404. O navegador registra no console, como erro, toda resposta 404, e isso aparecia
  como SEVERE na captura a cada abertura da folha de otimização.
- **Dono no backlog:** `BT-AI-031`, o dono de `GET /ai/optimize/jobs/:id` no registry das
  rotas de IA.
- **Frente A (servidor)**, branch `servidor/rodada2-2026-09-24`.
- Nada tocou a produção. Os testes rodaram num PostgreSQL 17 descartável e numa API local presa
  ao loopback, sob a guarda de egress.

## O contrato antes e agora

| Pedido | Antes | Agora |
| --- | --- | --- |
| `latest?deck_id=<deck da conta>&active=true`, sem job ativo | 404 `{error, job_id: "latest"}` | **200 `{"job": null}`** |
| `latest` sem `deck_id` e sem job | 404 | **200 `{"job": null}`** |
| `latest` com job | 200 com o JSON do job na raiz | igual |
| `deck_id` de outra conta | 404, indistinguível de "sem job" | **404 `deck_not_found`** |
| `deck_id` que não existe | 404 | 404 `deck_not_found` |
| `deck_id` que não é UUID | **500** (o `CAST` do PostgreSQL falhava) | 404 `deck_not_found` |
| `DELETE .../latest` | 405 | igual |

- A conferência de dono é a mesma do `POST /ai/optimize`, o `verifyOptimizeDeckAccess`. Na
  integração com a lixeira de decks (`DCK-P0-06`, Frente B), ela ganha `deleted_at IS NULL`, e
  um deck na lixeira passa a dar 404 também aqui, sem outra mudança.
- `GET /ai/optimize/jobs/<id>` com um id concreto segue igual: 404 para id inválido, vencido ou
  de outra conta.

## O app já aceita a resposta nova

A função `fetchLatestOptimizeJobRequest` (`app/lib/features/decks/providers/deck_provider_support_ai.dart`)
trata 404 como "sem job" (`null`) e 200 como o job. O único chamador,
`_offerResumableOptimization` (`deck_details_screen.dart`), lê `job_id` e `archetype`. Com
`{"job": null}` os dois faltam, e ele não oferece retomar: é o mesmo resultado de hoje. Por
isso o conserto é no servidor.

O rascunho da raia do app (`~/.manaloom/coordenacao/servidor/app_draft/`) também faz a função
devolver `null` para `{"job": null}`, para deixar a leitura explícita.

## Evidência

- **Banco:** `server/test/optimize_job_latest_db_live_test.dart` chama o handler da rota contra
  o PostgreSQL descartável, com a fixture de três contas da privacidade. Os 7 testes passam:
  - sem job ativo (a fixture tem um job concluído), 200 `{"job": null}`;
  - com job ativo, 200 com o job na raiz e sem a chave `job`;
  - o job concluído some com `active=true` e aparece sem ele;
  - deck de outra conta, mesmo com job ativo nele, dá 404 `deck_not_found`;
  - deck que não existe, id que não é UUID e injeção dão 404, não 500;
  - sem `deck_id`, vem o job mais recente da conta ou job nulo, e o job de outra conta nunca
    aparece;
  - `DELETE` segue 405.
- **E2E**, contra a API local buildada com a mudança às 19:00:05Z. Guarda de egress
  (`sandbox-exec`, só loopback; o autoteste recusou `1.1.1.1:53`). Capabilities
  `account_registration`, `decks_private` e `ai_analyze_optimize_advisory`. Duas contas por
  convite, com decks criados pela API. `server/test/optimize_job_latest_e2e_live_test.dart`
  passou 3/3:
  - sem job, 200 `{"job": null}` para o deck e para a conta;
  - com um job ativo gravado pelo `OptimizeJobStore`, 200 com o job, e a outra conta continua
    com job nulo;
  - deck de outra conta, inexistente ou que não é UUID dá 404 `deck_not_found`, com
    `request_id`.

  O E2E da D-82 passou 2/2 na mesma API.
- **Foco:** 8 arquivos e 70 testes (ciclo de vida dos jobs, suporte assíncrono do Optimize,
  registry das rotas de IA, contratos da API e erros).
- **Na trava:** `dart analyze` sem achados; a suíte completa roda com o commit.

## Mutações

Cada mutação foi aplicada no worktree. Depois rodou o teste de banco da rota e, por fim, o
arquivo foi restaurado e conferido byte a byte. As 5 falham como esperado.

| Mutação | O que muda | Falha em |
| --- | --- | --- |
| M124 | sem job volta a ser 404 | banco 4/7 |
| M125 | sem a conferência de dono do deck | banco 5/7 |
| M126 | sem a validação do UUID (500 de novo) | banco 6/7 |
| M127 | a resposta sem job perde a chave `job` | banco 4/7 |
| M128 | o filtro `active=true` é ignorado | banco 4/7 |
