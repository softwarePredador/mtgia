# Receipt — correções de segurança da D-19 em produção — 2026-09-23

- **Autorização:** o dono, nesta conversa de coordenação, em 2026-09-23, respondeu "Sim, subir agora" à
  pergunta que avisava que o deploy exigia promover o `master` com `--no-verify` e que a
  exportação do `/app` antigo pararia de funcionar.
- **Executado por:** sessão coordenadora (Claude), a partir de um worktree limpo com o SHA
  destacado. A árvore principal da sessão do gate não foi tocada.
- **Código:** a frente de segurança, um subagente da coordenação, fez 5 commits pelos hooks sobre
  `519b7e021`, com 12 provas por mutação e a suíte do servidor verde (369 arquivos, 2.407 testes):
  - `29d110d60` BT-AUTH-003, oráculo do login;
  - `934686c6c` BT-AUTH-004, reverificação na exportação e na exclusão;
  - `5850540d7` DCK-P0-06, relatório de deck apagado;
  - `5a7a3d9a8` BT-AUTH-007, usuário completo depois de trocar a senha;
  - `166aaed57` BT-AUTH-010, import com e-mail verificado.
  O diário da frente está no scratchpad da sessão coordenadora (`seguranca/DIARIO.md`).

## Passos

| Hora (UTC) | Passo | Resultado |
| --- | --- | --- |
| antes de 08:03 | Promoção a `master` com `git push --no-verify` (autorizado) | `87fd5a2e6..166aaed57`, avanço direto de 6 commits |
| 08:03:34–08:08:43 | Deploy do backend (`scripts/manaloom_deploy_backend_image.sh`), com a configuração de e-mail herdada da spec em produção, sem exibir nem gravar valores | **deployed**: `cartinhas@sha256:644b1725d21b245a4bc5e431929f5fa05fabf039a55b256007fa6ed6d141ff9a`, `git_sha 166aaed575f753745c1f3624b0d0e18689b5a46a`, 29/29 off |
| 08:08:51 | Observação externa | ver tabela abaixo |

Sem migration nova: o banco segue em 058. Não houve backup novo, porque não havia mudança de schema e a produção não tem uso desde 2026-08-03. O backup de 00:51 UTC com o ensaio de restauração (`BT-REL-000`) continua sendo o ponto de restauração.

## Observação externa (2026-09-23 08:08:51 UTC)

| Chamada | Resposta |
| --- | --- |
| `GET /health` | `healthy`, `git_sha 166aaed575f753745c1f3624b0d0e18689b5a46a` |
| `GET /ready` | `ready`, migration `058` |
| `POST /auth/login` com conta inexistente | 401 `{"message":"Credenciais inválidas"}`, sem texto de exceção |
| `POST /auth/login` com corpo que não é JSON | 400 `{"message":"Dados inválidos."}` |
| `GET /reports/<inexistente>` | 404 |
| `GET /users/me/export` | 404 `capability_route_unclassified`: a exportação por GET saiu do ar |
| `POST /users/me/export` e `DELETE /users/me` sem token | 401: exigem login e, com login, a senha |
| `POST /auth/register` | 404 `capability_unavailable`: cadastro segue fechado |

A igualdade de tempo do login (0,1 ms de diferença de mediana em 50 tentativas) e o 404 do relatório de deck apagado foram provados localmente, contra API e PostgreSQL descartáveis. Na produção não há conta de teste nem deck apagado para repetir de fora.

## O que continua aberto

- A recuperação de senha ainda denuncia a conta pelo tempo, porque espera o envio do e-mail dentro da requisição (`BT-AUTH-003`, `IN_PROGRESS_CONTAINED`).
- A exportação no `/app` antigo parou de funcionar: ele ainda usa GET. O app novo precisa pedir a senha. Isso foi pedido à sessão do gate para o lote antes da recaptura.
- A regra "escrever deck exige e-mail verificado" (D-56, `bedafe8bf`) **não subiu neste deploy**. Com `decks_private` desligada, as rotas de deck nem respondem em produção. Ela sobe no próximo deploy.
