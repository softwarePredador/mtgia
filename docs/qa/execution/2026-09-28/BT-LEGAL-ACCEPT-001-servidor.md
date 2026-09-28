# Receipt — BT-LEGAL-ACCEPT-001, parte do servidor: versionamento e reaceite — 2026-09-28

- Tarefa: `BT-LEGAL-ACCEPT-001`, só a parte do servidor. A tela de reaceite e o tratamento
  de `legal_acceptance_required` no app ficam com a raia do app.
- Frente A (servidor), branch `servidor/rodada2-2026-09-24`.
  - O trabalho começou em 2026-09-24 e ficou sem commit na pausa geral.
  - Foi retomado e fechado em 2026-09-28, sobre `157aecca9`.
- Decisão do dono aplicada: D-24.
  - O reaceite bloqueia só o que cria ou compartilha dado (deck novo, import, IA).
  - Login, exportação e exclusão seguem livres.
  - O histórico de aceites é guardado.
- Nada tocou a produção. A migration 062 rodou só no PostgreSQL 17 descartável da frente, e
  a API de teste ficou presa ao loopback.

## O que mudou

- **Migration 062 (`record_legal_acceptance_history`), espelhada em
  `server/database_setup.sql`.**
  - A tabela `user_legal_acceptances` guarda a conta, as duas versões, a origem
    (`register`, `reaccept` ou `backfill`), o request-id e a data. Só cresce.
  - Na migration entra o retrato de quem já tinha aceitado (as duas versões em `users`),
    sem conta excluída.
  - A migration refaz a trava de conta ativa (migration 038) em todas as chaves para
    `users`. Isso cobre a tabela nova e também a chave de `beta_invites` (061), que tinha
    ficado sem a trava nos bancos migrados.
  - O rollback é manual, porque o down apagaria a prova de consentimento.
  - As travas de "última migration" sobem para 062: prontidão, contrato do deploy e
    testes.
- **Situação e reaceite (`server/lib/legal_acceptance_service.dart`).**
  - `users` guarda o aceite vigente, e o histórico, cada aceite.
  - O reaceite trava a linha da conta com `FOR UPDATE`, grava as versões exatas e uma
    linha no histórico.
  - Aceitar de novo o que já está aceito não duplica.
  - Conta sem aceite (versão nula, de antes da 043) nunca está em dia.
- **Rota `GET` e `POST /users/me/legal-acceptance`, no plano de controle.** A conta
  bloqueada sai do bloqueio com qualquer capability desligada.
  - `GET` mostra as versões aceitas, as atuais, se falta o reaceite e a rota.
  - `POST` exige `legal_accepted: true` e as versões atuais. Sem isso, responde 400
    `legal_acceptance_required` com as versões atuais.
- **Trava (`server/lib/legal_acceptance_middleware.dart`).** Com
  `MANALOOM_LEGAL_REACCEPTANCE=enforce`, a conta fora da versão atual recebe 403
  `legal_acceptance_required`. O corpo leva a frase, as versões aceitas e as atuais, e a
  rota do reaceite. A trava vale só em:
  - deck novo: `POST /decks` e a cópia de deck público;
  - `POST /decks/:id/reports` (relatório público) e `POST /decks/:id/ai-analysis`;
  - `POST /import`, `POST /import/to-deck` e `POST /binder/import/apply`;
  - toda escrita sob `/ai`, menos telemetria e ações sobre um trabalho ou uma partida que já
    existem. Rota nova de IA nasce exigindo o aceite.

  Seguem livres: ler, editar o que existe, validar import, login, exportação e exclusão. A
  trava roda depois da autenticação e do e-mail verificado. Na IA, roda antes do limite e
  da cota do plano, nas quatro cadeias de `/ai`.
- **Cadastro.** Grava o aceite no histórico (`register`, com o request-id), na transação
  que cria a conta.
- **Inventário de privacidade.** A tabela nova entra como `keep_legal`.

## Evidência

Build da API: `server/build` do worktree (`157aecca9` mais este trabalho), gerado na trava
às 2026-09-28T11:53:49Z. O código do build é o deste commit.

| Teste | Onde | Resultado |
| --- | --- | --- |
| `server/test/legal_acceptance_test.dart` | unitário: situação, chave da trava, o que bloqueia, middleware, rota, cópia de deck público e as cadeias reais de `/ai` (as quatro políticas), `/import` e `/binder` | 19/19 |
| `server/test/legal_acceptance_db_live_test.dart` | PostgreSQL descartável na 062 (`RUN_LEGAL_ACCEPTANCE_DB_TESTS=1`) | 7/7 |
| `server/test/legal_acceptance_e2e_live_test.dart` | HTTP contra a API local com `MANALOOM_LEGAL_REACCEPTANCE=enforce` (`RUN_LEGAL_ACCEPTANCE_E2E_TESTS=1`) | 2/2 |
| `beta_invite_e2e_live_test` e `public_error_e2e_live_test` | a mesma API, com a trava ligada | 16/16, sem regressão |
| os 12 `*_db_live_test.dart` do servidor | o mesmo banco descartável, com as chaves de todas as frentes | 76/76, nenhum pulado |
| suíte de foco | 50 arquivos determinísticos: legal, auth, cadastro, convite, import, fichário, privacidade, migrations, prontidão, capabilities, erros públicos, limites e middlewares | 487/487 |
| `dart analyze` do server | `lib`, `bin`, `routes` e `test` | sem achados |

Banco descartável recriado do zero (`database_setup.sql` mais as 62 migrations, a última
062). As 43 chaves de uma coluna para `users` têm o trigger de conta ativa.

**O teste de banco cobre:**

- **Retrato da 062.** Rodar o `up` duas vezes grava uma linha só para a conta que já tinha
  aceitado. Não grava nada para a conta sem aceite nem para a conta excluída.
- **Trava de conta ativa.** Num banco migrado até a 061 (o trigger de `beta_invites`
  apagado), a 062 devolve o trigger, e nenhuma chave para `users` fica sem ele. As duas
  tabelas, `beta_invites` e `user_legal_acceptances`, recusam conta excluída com 23503
  `inactive_user_reference`.
- **Cadastro.** Entra no histórico como `register`, com o request-id.
- **Reaceite.** Grava uma linha; aceitar de novo não duplica.
- **Concorrência.** Dez aceites simultâneos gravam uma linha só.
- **Conta excluída.** Não aparece e não aceita.
- **Middleware real de `/decks`,** com a conta autenticada de verdade:
  - versão antiga bloqueia criar deck;
  - editar o deck segue livre;
  - depois do reaceite, criar volta a passar.

**O teste unitário das cadeias reais** passa o pedido pelos middlewares da rota, com a
conta autenticada.

- Em `/ai/explain`, `/ai/simulate`, `/ai/battle/jobs` e `/ai/commander-learning` (uma
  rota de cada política de acesso), em `/import`, `/import/to-deck` e
  `/binder/import/apply`, a trava responde 403.
  - Só a conta e o aceite são lidos: nem a cota do plano nem o limitador rodam.
- Seguem para o handler sem consultar o aceite:
  - uma ação numa partida em curso;
  - `/import/validate`;
  - `/binder/import/preview`.

**O E2E, com a trava ligada** e as capabilities `account_registration`, `decks_private`,
`deck_replace_all`, `collection_private` e `ai_analyze_optimize_advisory` no manifesto
isolado:

1. A conta entra por convite e cria um deck.
2. O teste volta a versão aceita dela no banco, como se os Termos tivessem mudado.
3. Criar deck dá 403 `legal_acceptance_required`, com o request-id e as versões.
4. `POST /import`, `POST /binder/import/apply` e `POST /ai/explain` também dão 403
   `legal_acceptance_required`.
5. Listar e editar seguem 200. Conferir o import (`/import/validate`) não é bloqueado.
6. O `GET` da rota mostra o reaceite pendente.
7. O `POST` com a versão velha dá 400; com a atual, dá 200.
8. Criar deck volta a passar, e o import deixa de ser bloqueado.
9. O histórico tem as duas linhas, `register` e `reaccept`, cada uma com o request-id do
   seu pedido.

**Sonda HTTP** na mesma API, com a conta de volta numa versão antiga:

| Pedido | Resposta |
| --- | --- |
| `POST /decks` | 403 `legal_acceptance_required` |
| `POST /import` | 403 `legal_acceptance_required` |
| `POST /import/to-deck` | 403 `legal_acceptance_required` |
| `POST /binder/import/apply` | 403 `legal_acceptance_required` |
| `POST /ai/explain` | 403 `legal_acceptance_required` |
| `POST /import/validate` | 200 |
| `POST /binder/import/preview` | 400 do próprio handler (lista vazia): a trava deixou passar |

## Mutações

17 mutações, aplicadas no worktree. Em cada uma, os testes rodaram e o arquivo foi
restaurado e conferido byte a byte. Todas falharam como esperado:

| Mutação | O que muda | Resultado |
| --- | --- | --- |
| M60 | a trava invertida (bloqueia quem está em dia, libera quem não está) | unitário 13/19; banco 6/7 |
| M61 | versão nula conta como em dia | 17/19 |
| M62 | o reaceite sem `FOR UPDATE` | banco 6/7: dez aceites simultâneos gravam mais de uma linha |
| M63 | aceitar de novo duplica o histórico | 18/19; banco 5/7 |
| M64 | o cadastro não grava o histórico | banco 6/7 |
| M65 | a trava ligada por padrão | 18/19 |
| M66 | `POST /decks` fora da trava | 16/19; banco 6/7 |
| M67 | as exceções da IA invertidas | 16/19 |
| M68 | o middleware de `/decks` sem a trava | banco 6/7 |
| M69 | a rota de reaceite fora do plano de controle | `release_capability_policy_test` 15/16: toda rota tem classificação |
| M70 | o retrato da 062 sem filtrar conta excluída | banco 5/7 |
| M71 | a cópia de deck público sem a trava | 18/19 |
| M77 | a 062 sem o laço que refaz os triggers de conta ativa | banco 6/7 |
| M78 | `POST /import` fora da trava | 17/19 |
| M79 | o import aplicado do fichário fora da trava | 17/19 |
| M80 | a cadeia cobrada de `/ai` sem a trava | 18/19 |
| M81 | a trava depois da cota do plano | 18/19 |

## Decisões, com a recomendação

Estão no diário da frente e em `decisoes-pendentes.md` da coordenação.

- **A trava fica desligada por padrão, inclusive na produção.** Com ela ligada, as contas
  sem aceite (versão nula) ficariam bloqueadas sem ter onde aceitar até o app ter a tela.
  Para ligar, basta pôr `MANALOOM_LEGAL_REACCEPTANCE=enforce` no deploy, depois da tela.
- **O que a trava cobre.** O relatório público do deck e a cópia de deck público entram
  por "compartilha dado" e "deck novo". Mensagens, trocas e comentários ficam fora, porque
  a D-24 lista deck novo, import e IA.
- **O histórico não guarda IP nem user-agent,** por minimização. O prazo de guarda fica
  para confirmar com o advogado (BT-LEGAL-001).
- **Exportação e exclusão.** A exportação leva as versões vigentes (em `users`). Pôr o
  histórico na exportação, e decidir o que a exclusão faz com ele, fica com a frente de
  privacidade. O inventário marca `keep_legal`.

## O que fica para depois

- **Publicar deck ficou fora da trava.** O `is_public` de `false` para `true` em
  `PUT /decks/:id` é "compartilha dado" pela D-24, mas não está na lista dela.
  - A frente de deck reescreve essa rota na rodada 2 e acrescenta um `PATCH`. Mudar a rota
    agora conflitaria na integração.
  - Recomendação: depois da integração, travar a passagem para público no `PUT` e no
    `PATCH`. Publicar o que já é público, e despublicar, seguem livres.
- **A rota nova de import da frente de deck** (`POST /import/to-deck/preview`) só confere e
  fica livre pela regra atual. Depois da integração, conferir com um teste.
- **Tela de reaceite e tratamento do código no app:** raia do app.
