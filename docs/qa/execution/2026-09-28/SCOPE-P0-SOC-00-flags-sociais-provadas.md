# Receipt — SCOPE-P0-SOC-00: flags sociais desligadas, negação antes do banco e release identity — 2026-09-28

- Tarefa: `SCOPE-P0-SOC-00`, a evidência. Feita pela Frente B (deck e trocas) da coordenação do
  MVP na branch `deck/rodada2-2026-09-24`, sobre `78a77001d`.
- Aceite do backlog: "UI/deep links ausentes e API direta nega antes de PG; flags no release
  identity."
- Estado antes: `EVIDENCE_REQUIRED`. A implementação está em `b2d3fc04f` (política 29/29
  desligada, portão no `server/routes/_middleware.dart`). Faltavam:
  - um teste de negação em runtime por rota social; antes, só `/ai/battle/jobs` e
    `/auth/register` passavam pelo middleware real em teste;
  - o receipt.
- Decisão do dono em vigor: D-39. As flags sociais abrem uma a uma, depois de corrigir os
  endpoints compostos que devolvem dado de outras flags.
- Só servidor. A UI e os deep links são da raia do app.
- Nada tocou a produção. O código de produto não mudou; os testes entraram no commit da
  `SCOPE-P0-TRD-00` (`78a77001d`).

## As 9 flags e as rotas de cada uma

| Flag | Rotas (método e caminho) | Plano de controle na mesma pasta |
| --- | --- | --- |
| `gallery_public` | `GET /community/decks`, `GET /community/decks/:id`, `POST /community/decks/:id`, `POST /decks/:id/reports` | `POST /community/decks/:id/reports` (denúncia) |
| `profiles_public` | `GET /community/users/:id` | — |
| `comments` | `GET /community/decks/:id/comments`, `POST /community/decks/:id/comments` | `DELETE /community/decks/:id/comments/:commentId` |
| `follows` | `GET /community/decks/following` (feed), `GET /users/:id/follow`, `POST /users/:id/follow`, `GET /users/:id/followers`, `GET /users/:id/following` | `DELETE /users/:id/follow` |
| `user_search` | `GET /community/users` | — |
| `direct_messages` | `GET /conversations`, `POST /conversations`, `GET /conversations/unread-count`, `GET /conversations/:id/messages`, `POST /conversations/:id/messages`, `PUT /conversations/:id/read` | — |
| `social_push` | `GET /notifications`, `GET /notifications/count`, `PUT /notifications/read-all`, `PUT /notifications/:id/read`, `PUT /users/me/fcm-token` | `DELETE /users/me/fcm-token` |
| `binder_public` | `GET /community/binders/:userId` | — |
| `trades` | `GET /trades`, `POST /trades`, `GET /trades/:id`, `GET /trades/:id/messages`, `POST /trades/:id/messages`, `PUT /trades/:id/respond`, `PUT /trades/:id/status`, `GET /community/trade-matches` | — |

São 33 sondas sob as 9 flags: 32 rotas×método de `routes/` e o feed de seguidos, que é
`/community/decks/[id]` com `following` e fica sob `follows`. A elas se soma o
`GET /community/marketplace`, da flag `marketplace` (`SCOPE-P0-TRD-00`). A sonda da busca de
usuário leva `?q=scope`: sem `q`, a busca recusa antes do banco, e o controle na matriz aberta
precisa ser uma busca de verdade.

- O teste `server/test/scope_containment_route_matrix_test.dart` fixa a tabela inteira, lida de
  `routes/`. Rota nova sob uma dessas flags, rota que troca de flag ou rota que some faz o teste
  falhar.
- O mesmo teste confere que o resto das pastas sociais é plano de controle: segurança,
  moderação e privacidade.
  - As 13 rotas são as 4 da coluna acima e mais: `GET`, `POST` e `DELETE /users/:id/block`,
    `GET /users/me/blocks`, `POST /content-reports`, `POST /content-reports/:id/appeals`,
    `GET /moderation/reports`, `PUT /moderation/reports/:id` e `GET /reports/:id`.
- Ele passa cada rota contida pelo middleware raiz real, com a política de produção e com o
  núcleo aberto. Em todas, o resultado é 404 `capability_unavailable` com a flag certa, e o
  handler nunca é chamado.
  - Isso fecha o achado 5 da medição: antes, nenhuma rota social passava pelo middleware real
    em teste.

## API direta nega antes do PostgreSQL

Mesmo método da `SCOPE-P0-TRD-00` (receipt
`docs/qa/execution/2026-09-28/SCOPE-P0-TRD-00-kill-switch-provado-pelo-banco.md`):

- o harness isolado do projeto, sob `sandbox-exec` só com loopback;
- o PostgreSQL descartável com `log_statement = 'all'` em `jsonlog`;
- marcadores escritos pela conexão do teste em volta de cada requisição, e a contagem dos
  statements das conexões do servidor;
- três matrizes lidas da própria API: produção, núcleo e aberta.

- **Harness nas três matrizes:** `result=pass`.
  - Egress: `macos_sandbox_exec_loopback_only`, autoteste `pass`.
  - Banco criado do zero até a migration `073`.
  - Limpeza com `database_remaining=0`: banco apagado, sem listener, build restaurado.
- **Digest da política carregada pela API** (`GET /capabilities`):
  - produção: `ace782b3969a9ba5a2691f5ca3d97360927919739cd16c796d7b36e8124d754d`, igual ao do arquivo versionado e ao da release identity;
  - núcleo: `218c45d4a22b24ba627ffbb281bf7e91099cab034d10acb8a12287181d78661e`;
  - aberta: `21d4a6a5a0ff39609e80a71e5256fac45eec7d6f9848c441eb4c7471f2ba1be3`.

| Flag | Sondas | Produção | Núcleo | Aberta (controle) |
| --- | --- | --- | --- | --- |
| `gallery_public` | 4 | 4/4 negadas com 404, 0 statements | 4/4 negadas com 404, 0 statements | 4/4 chegaram ao banco (mín. 2 statements) |
| `profiles_public` | 1 | 1/1 negadas com 404, 0 statements | 1/1 negadas com 404, 0 statements | 1/1 chegaram ao banco (mín. 4 statements) |
| `comments` | 2 | 2/2 negadas com 404, 0 statements | 2/2 negadas com 404, 0 statements | 2/2 chegaram ao banco (mín. 2 statements) |
| `follows` | 5 | 5/5 negadas com 404, 0 statements | 5/5 negadas com 404, 0 statements | 5/5 chegaram ao banco (mín. 3 statements) |
| `user_search` | 1 | 1/1 negadas com 404, 0 statements | 1/1 negadas com 404, 0 statements | 1/1 chegaram ao banco (mín. 3 statements) |
| `direct_messages` | 6 | 6/6 negadas com 404, 0 statements | 6/6 negadas com 404, 0 statements | 6/6 chegaram ao banco (mín. 1 statements) |
| `social_push` | 5 | 5/5 negadas com 404, 0 statements | 5/5 negadas com 404, 0 statements | 5/5 chegaram ao banco (mín. 2 statements) |
| `binder_public` | 1 | 1/1 negadas com 404, 0 statements | 1/1 negadas com 404, 0 statements | 1/1 chegaram ao banco (mín. 4 statements) |
| `trades` | 8 | 8/8 negadas com 404, 0 statements | 8/8 negadas com 404, 0 statements | 8/8 chegaram ao banco (mín. 1 statements) |

- **Fase inteira, produção:** 0 statements do servidor entre as janelas e 0 na cauda de 500 ms
  depois da última negação.
- **Fase inteira, núcleo:** 0 entre as janelas e 0 na cauda.
- **Log do servidor:** produção com 39 linhas `[release_capability_denial]`, núcleo com 34.
- **Controles positivos, nas três matrizes:** o login e o `GET /auth/me`, no começo e no fim,
  apareceram no log.
- **Aberta, o controle:** as 34 sondas chegaram ao banco.

## Flags no release identity

`scripts/manaloom_release_identity.sh` rodou num clone temporário no `78a77001d`.
O clone teve o `origin/master` apontado para o HEAD e rodou sem fetch, sob o mesmo `sandbox-exec`
só com loopback. A identity traz a política inteira em `release_capabilities`:

- `policy_version`: `brewtact_free_beta_2026-08-13`;
- `policy_digest_sha256`: `ace782b3969a9ba5a2691f5ca3d97360927919739cd16c796d7b36e8124d754d`;
- `capability_count`: 29, com `configuration_status` `valid`
  e `offer_mode` `free_beta_no_commerce`;
- as 9 flags sociais saem `release_capability: off` e `allowed: false` (o `marketplace`, da
  `SCOPE-P0-TRD-00`, também):
  `binder_public`, `comments`, `direct_messages`, `follows`, `gallery_public`, `profiles_public`, `social_push`, `trades`, `user_search`.

Como a identity liga à API:

- a biblioteca `scripts/lib/manaloom_release_capabilities_contract.sh` recusa uma identity da
  beta com qualquer flag ligada;
- o deploy (`manaloom_deploy_backend_image.sh`) exige que o `/health/ready` publicado mostre o
  mesmo `policy_digest_sha256` da identity;
- no E2E da matriz de produção, a API mostrou em `GET /capabilities` o mesmo digest
  (`ace782b3…754d`) e as mesmas flags desligadas.

Não há lacuna de identity a registrar.

## Suíte de foco

Rodada dentro da trava, com o manifesto regenerado, antes do commit: 71/71 (10 arquivos).

## Mutações

Mutações que valem para esta tarefa (as do grupo `scope`, com o E2E):

- S2 token de push fora de social_push — derrubada pelos testes unitários
- S3 seguir sem flag — derrubada pelos testes unitários
- S4 portão deixa passar a flag desligada — derrubada pelos testes unitários
- S5 comentários sem flag — derrubada pelos testes unitários
- S7 política versionada abre as trocas — derrubada pelos testes unitários
- E1 o portão lê o banco antes de negar — e2e producao — derrubada pelo E2E

A lista completa, com as de comércio, está no receipt da `SCOPE-P0-TRD-00`.

## O que fica de fora

- **Raia do app:**
  - UI e deep links sociais (o guard do app já existe; a prova de UI é da raia);
  - o teste de push e polling sem flag;
  - o atalho de matches do fichário condicionado a `trades`.
- **Antes de abrir qualquer flag social (D-39):** os endpoints compostos devolvem dado de outras
  flags. O perfil entrega decks públicos e seguidores, o feed de seguidos entrega decks públicos,
  e o detalhe da galeria entrega o dono e os comentários. Com as 9 desligadas, isso não aparece.
- **`GET /reports/:id`** segue como leitura pública do plano de controle, por decisão do
  `BT-GOV-001`.
- **Prova no SHA integrado:** o mesmo E2E, rodado na integração.
