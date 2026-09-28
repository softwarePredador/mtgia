# Receipt — SCOPE-P0-TRD-00: kill switch de troca e marketplace, provado pelo banco — 2026-09-28

- Tarefa: `SCOPE-P0-TRD-00`, fechar a evidência da parte do servidor. Feita pela Frente B (deck e
  trocas) da coordenação do MVP na branch `deck/rodada2-2026-09-24`, sobre `9c45f2ae1`.
- Aceite do backlog: "Nenhuma listagem/match/proposta pode ser criada via API direta; copy não
  promete venda/troca."
- Estado antes: `IN_PROGRESS_CONTAINED`.
  - O kill switch do fichário já estava no código desde `28d12bc61` (rodada 1): o fichário
    responde 422 `binder_commerce_unavailable` antes do banco.
  - As rotas de troca e de marketplace ficam atrás das flags `trades` e `marketplace`
    (`b2d3fc04f`).
  - Faltava o receipt de negação por rota, com prova de que a negação vem antes do PostgreSQL.
- Nada tocou a produção: sem SSH, sem banco live, sem deploy. O código de produto não mudou;
  entraram só testes.
- Só servidor. Esconder troca e venda no editor do fichário é da raia do app (D-04). O site já tem
  os termos em português no gate (`public_web_product_contract_test.dart`) e é de outra raia.

## Como foi provado

- **API de verdade.** O servidor rodou com o harness isolado do projeto
  (`scripts/manaloom_server_contract_e2e_isolated.sh`):
  - build do `dart_frog`;
  - banco novo, criado do zero por `database_setup.sql` e `migrate.dart` do worktree;
  - API e testes sob `sandbox-exec` só com loopback. O próprio harness confere que uma conexão
    para fora é recusada antes de começar.
- **Banco de verdade.** O PostgreSQL 17 descartável da frente (`LC_ALL=C`, só em `127.0.0.1`,
  sem socket Unix) rodou com `log_statement = 'all'` em `jsonlog`, sem rotação. Foi apagado no
  fim.
- **A contagem é pelo log do banco, não pelo código.**
  - O teste `server/test/scope_containment_e2e_test.dart` escreve dois marcadores no log, pela
    própria conexão, em volta de cada requisição.
  - Conta os statements que outras conexões (as do servidor) executaram entre eles.
  - Conta também os statements do servidor entre uma janela e outra, e numa cauda de 500 ms
    depois da última requisição.
- **Controles positivos:** o login e o `GET /auth/me` precisam aparecer no log. Se o log não
  pegasse o servidor, a prova seria vazia.
- **Três matrizes.** O teste lê a matriz na própria API (`GET /capabilities`):
  - **produção:** a política versionada, com as 29 flags desligadas. A API conferiu o digest
    byte a byte (`ace782b3…754d`);
  - **núcleo:** catálogo, decks e fichário ligados; troca e marketplace desligados. É a matriz
    alvo da beta;
  - **aberta:** o núcleo mais as 10 flags contidas ligadas. É o controle: as mesmas requisições
    precisam chegar ao banco, o que prova que a negação vem da flag.

## Resultado

- **Harness nas três matrizes:** `result=pass`.
  - Egress: `macos_sandbox_exec_loopback_only`, autoteste `pass`.
  - Banco criado do zero até a migration `073`.
  - Limpeza com `database_remaining=0`: banco apagado, sem listener, build restaurado.
- **Digest da política carregada pela API** (`GET /capabilities`):
  - produção: `ace782b3969a9ba5a2691f5ca3d97360927919739cd16c796d7b36e8124d754d`, igual ao do arquivo versionado e ao da release identity;
  - núcleo: `218c45d4a22b24ba627ffbb281bf7e91099cab034d10acb8a12287181d78661e`;
  - aberta: `21d4a6a5a0ff39609e80a71e5256fac45eec7d6f9848c441eb4c7471f2ba1be3`.

**Rotas de troca e de marketplace.** Cada célula traz o status HTTP e o número de statements
que o servidor executou no PostgreSQL entre os marcadores da requisição.

| Rota | Flag | Produção | Núcleo | Aberta (controle) |
| --- | --- | --- | --- | --- |
| `GET /community/marketplace` | `marketplace` | 404, 0 | 404, 0 | 200, 3 |
| `GET /community/trade-matches` | `trades` | 404, 0 | 404, 0 | 200, 2 |
| `GET /trades` | `trades` | 404, 0 | 404, 0 | 200, 3 |
| `GET /trades/:id` | `trades` | 404, 0 | 404, 0 | 404, 3 |
| `GET /trades/:id/messages` | `trades` | 404, 0 | 404, 0 | 404, 3 |
| `POST /trades` | `trades` | 404, 0 | 404, 0 | 400, 1 |
| `POST /trades/:id/messages` | `trades` | 404, 0 | 404, 0 | 400, 2 |
| `PUT /trades/:id/respond` | `trades` | 404, 0 | 404, 0 | 400, 2 |
| `PUT /trades/:id/status` | `trades` | 404, 0 | 404, 0 | 400, 2 |

- **Produção e núcleo:** as rotas acima negaram com 404 `capability_unavailable` e zero
  statements. As 34 sondas contidas da fase também:
  - produção: 34 de 34 negadas, 0 statements nas janelas, 0 entre as janelas e 0 na cauda;
  - núcleo: 34 de 34 negadas, 0 statements nas janelas, 0 entre as janelas e 0 na cauda.
- **Log do servidor:** uma linha `[release_capability_denial]` por negação: 39 na produção (as
  34 sondas contidas e as 5 do fichário, que lá caem na flag `collection_private`) e 34 no núcleo.
- **Aberta, o controle:** as 34 sondas chegaram ao banco, com pelo menos 1 statement cada. A
  negação das outras matrizes vem da flag, não de rota ausente nem de erro anterior.

**Listagem pelo fichário.** Na matriz do núcleo, catálogo, decks e fichário ficam ligados, e
troca e marketplace, desligados. Cada célula traz o status, o código, os statements e, depois
de "fichário", quantos deles citam `user_binder_items`.

| Oferta no fichário | Produção | Núcleo | Aberta (controle) |
| --- | --- | --- | --- |
| `POST /binder {"for_trade":true}` | 404 capability_unavailable, 0, fichário 0 | 422 binder_commerce_unavailable, 1, fichário 0 | 409 binder_item_identity_conflict, 4, fichário 2 |
| `POST /binder {"for_sale":true}` | 404 capability_unavailable, 0, fichário 0 | 422 binder_commerce_unavailable, 1, fichário 0 | 409 binder_item_identity_conflict, 4, fichário 2 |
| `POST /binder {"price":12.5}` | 404 capability_unavailable, 0, fichário 0 | 422 binder_commerce_unavailable, 1, fichário 0 | 409 binder_item_identity_conflict, 4, fichário 2 |
| `PUT /binder/:id {"for_trade":true}` | 404 capability_unavailable, 0, fichário 0 | 422 binder_commerce_unavailable, 2, fichário 0 | 200, 8, fichário 2 |
| `PUT /binder/:id {"for_sale":true}` | 404 capability_unavailable, 0, fichário 0 | 422 binder_commerce_unavailable, 2, fichário 0 | 200, 8, fichário 2 |

- **Núcleo:**
  - as 5 ofertas deram 422 `binder_commerce_unavailable`, e nenhum statement cita
    `user_binder_items`;
  - o único acesso ao banco é a leitura do usuário do token, em `users`: uma vez no `POST` e
    duas no `PUT`;
  - depois, o dono tinha 0 cópias com `for_trade` ou `for_sale` e 0 com preço;
  - o mesmo `POST` sem oferta gravou, com um `INSERT INTO user_binder_items` na janela: a
    recusa é da oferta, não da rota.
- **Produção:** tudo cai antes, com 404 da flag `collection_private` e zero statements.
- **Aberta:** as mesmas ofertas chegaram ao fichário: 409 de identidade repetida no `POST` e 200
  no `PUT`.
- **Import:** o import do fichário grava `for_trade` e `for_sale` como `FALSE` no próprio
  `INSERT` (`routes/binder/import/apply/index.dart`). O contrato do import não tem campo de
  oferta.
- **Moderação:** só zera a oferta ou devolve o estado anterior.

## Copy do servidor

`server/test/scope_containment_copy_test.dart` (3 testes, na suíte de foco):

- **E-mails:** os 2 modelos (redefinir senha e verificar e-mail) não falam de troca, venda,
  compra, negociação, marketplace, pagamento, cobrança nem assinatura.
- **Mensagens de erro que a beta alcança:**
  - o 422 do fichário diz "Troca e venda de cartas não estão disponíveis nesta beta.";
  - o 403 de e-mail não verificado diz "Confirme seu e-mail para continuar.", sem citar
    troca, conversa nem publicação;
  - o checkout e o webhook de cobrança recusam, dizendo que não há compra nem cobrança;
  - a negação da flag leva `offer_mode: free_beta_no_commerce`, sem texto.
- **Mensagens de troca que ficam atrás da flag:** as da rota de propostas (por exemplo, "enviou
  uma proposta de trade") não saem na beta. O E2E mostra que `/trades` nunca chega ao handler.
- **OpenAPI gerado:** é só inventário. O resumo de cada operação é o próprio método e caminho,
  não há descrição livre, e nenhum texto fala de comércio.

## Suíte de foco

Rodada dentro da trava, com o manifesto regenerado, antes do commit: 71/71 (10 arquivos). Inclui:

- `scope_containment_route_matrix_test`: as 33 rotas×método contidas e o feed, cada uma com a sua
  flag, passando pelo middleware raiz real;
- `scope_containment_copy_test`;
- `trade_marketplace_kill_switch_test` e `release_capability_policy_test`.

O teste de banco `community_marketplace_trade_visibility_db_live_test` (D-38) passou 3/3 num
PostgreSQL descartável.

## Mutações

10 mutações unitárias e 2 do E2E. Nenhuma sobreviveu.

As unitárias rodaram com `~/.manaloom/coordenacao/deck/mutations.py scope`. As do E2E, com
`scope_e2e_mut.py`: cada uma aplicada no worktree, com o harness rodando de novo, a API
reconstruída e o arquivo restaurado e conferido por hash.

Mutações que valem para esta tarefa:

- S1 rotas de troca sem flag — derrubada pelos testes unitários
- S4 portão deixa passar a flag desligada — derrubada pelos testes unitários
- S6 marketplace sob a flag da galeria — derrubada pelos testes unitários
- S7 política versionada abre as trocas — derrubada pelos testes unitários
- S8 e-mail promete troca — derrubada pelos testes unitários
- S9 OpenAPI descreve a proposta de troca — derrubada pelos testes unitários
- S10 recusa do fichário promete para depois — derrubada pelos testes unitários
- E1 o portão lê o banco antes de negar — e2e producao — derrubada pelo E2E
- E2 o fichário lê as cartas do dono antes de recusar a oferta — e2e nucleo — derrubada pelo E2E

As outras 3 unitárias (S2, S3 e S5) valem para a `SCOPE-P0-SOC-00`.

## O que fica de fora

- **Raia do app (D-04):** esconder troca, venda e preço no editor do fichário, as estatísticas
  Troca/Venda e o atalho para os matches. Hoje o servidor recusa a escrita, mas a tela ainda
  mostra.
- **Pack 05 rotulado como capability futura (D-40):** com a sessão do gate.
- **OpenAPI gerado sem a flag de cada operação.** Ele lista `/trades` e `/community/marketplace`
  como qualquer rota: não promete nada, mas também não diz que estão desligadas. A recomendação
  está nas decisões pendentes.
- **Prova no SHA integrado:** o mesmo E2E, rodado na integração.
