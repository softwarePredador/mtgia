# Receipt — BT-AUTH-001: erros públicos tipados — 2026-09-24

- Tarefa: `BT-AUTH-001`, Frente A (servidor, convite e segurança) da rodada de 2026-09-24,
  branch `servidor/rodada2-2026-09-24`.
- Decisão do dono aplicada: D-21. Códigos `dominio_motivo` em snake_case acompanham a frase
  em português, sem substituí-la.
- Aceite do backlog: "Corpus de falhas retorna código estável e request-id; zero detalhe
  interno."
- Nada tocou a produção. Os testes de banco e o E2E rodaram num PostgreSQL 17 descartável
  da frente (loopback, `LC_ALL=C`) e numa API local do worktree presa ao loopback.

## O que mudou

- **Contrato central (`server/lib/public_error_contract.dart`).** O middleware raiz passa
  toda resposta 4xx e 5xx do handler por `sanitizePublicErrorResponse`:
  - **Detalhe interno em qualquer campo:** o corpo é trocado pela frase genérica, com o
    código da rota (ou o do status) e o request-id. Conta como detalhe interno:
    - nome de exceção ou erro do Dart, e o texto dos erros do núcleo (`Bad state:`,
      `Invalid argument`...);
    - texto do PostgreSQL (severidade, SQLSTATE, relação, coluna, constraint);
    - stack, `Instance of` e erro de rede.
  - **5xx:** só passa o corpo com código estável em `error`, com `request_id`
    acrescentado. O resto vira o código do status (`server_internal_error`,
    `service_unavailable`, `upstream_failed`, `upstream_timeout`) com a frase genérica,
    mantendo o código que a rota tenha dado.
  - **5xx estruturado sem envelope de erro:** passa intacto. É o caso do 503 da
    prontidão, com os checks.
  - **4xx:** a frase fica onde a rota pôs, porque o app lê `error` ou `message`. Sem
    código estável, ganha `code` pelo status: 400 `request_invalid`, 401
    `auth_unauthorized`, 403 `access_forbidden`, 404 `resource_not_found`, 405
    `method_not_allowed`, 409 `resource_conflict`, 413 `request_too_large`, 429
    `rate_limited`, outros `request_failed`. Ganha também `request_id`.
  - **Negações que saem antes do handler:** CORS, capability e banco fora levam o código
    em `error` e o `request_id` no corpo.
  - **Header:** o request-id sai sempre em `x-request-id`.
  - **Log:** o corpo trocado vai para o log do servidor, truncado, para a operação achar
    a causa pelo request-id.
  - **Código da rota:** um `code` que a rota já mandou nunca é sobrescrito.
- **Fontes corrigidas:**
  - `apiError` e os atalhos só mandam `details` estruturado (mapa ou lista). Exceção ou
    texto livre vai só para o log.
  - `internalServerError` responde `{error: server_internal_error, message}` e loga a
    causa.
  - Cartas do deck (`POST /decks/:id/cards`, `bulk`, `replace` e `set`) e
    `PUT /decks/:id`: o deck inexistente ou de outra conta é 404 `deck_not_found`, não
    mais `Exception: Deck not found...` com 500. O `e.toString()` saiu dos 500.
  - A cópia de deck público (`POST /community/decks/:id`) tem o 404 tipado, sem o texto
    da exceção.
  - `POST /auth/register`:
    - nome ou e-mail em uso é 400 `auth_username_taken` ou `auth_email_taken`;
    - a corrida de dois cadastros iguais que bate no índice único é 400
      `auth_account_taken`, e não o texto do PostgreSQL;
    - corpo que não é objeto é 400 `request_json_invalid`;
    - a falha interna é 500 `server_internal_error`;
    - o `on Exception` que devolvia `e.toString()` saiu.
  - A validação do deck gerado pela IA punha `e.toString()` na lista de erros que vai ao
    cliente. Agora põe uma frase fixa e loga o tipo.

## Evidência

| Teste | Onde | Resultado |
| --- | --- | --- |
| `server/test/public_error_contract_test.dart` | unitário, com um corpus que passa pelo middleware raiz, as fontes sem a rede do middleware e o saneador direto | 33/33 |
| `server/test/generated_deck_validation_service_test.dart` | unitário | 12/12 |
| `server/test/battle_replay_routes_security_test.dart` | unitário, atualizado para o 500 tipado | passa |
| `server/test/public_error_db_live_test.dart` | PostgreSQL descartável (`RUN_PUBLIC_ERROR_DB_TESTS=1`) | 2/2 |
| `server/test/public_error_e2e_live_test.dart` | HTTP contra a API local (`RUN_PUBLIC_ERROR_E2E_TESTS=1`) | 10/10 |
| `server/test/beta_invite_e2e_live_test.dart` | o mesmo harness, conferindo que o convite não mudou | 6/6 |

O corpus do E2E manda um `x-request-id` próprio em cada pedido. Todo erro devolve:

- o mesmo id no header e no corpo;
- um código estável;
- nenhum detalhe interno.

Os casos:

- **Login com JSON quebrado:** 400 `request_invalid`, com a frase `Dados inválidos.`.
- **Login com senha errada:** 401 `auth_unauthorized`.
- **Cadastro com corpo que não é objeto:** 400 tipado.
- **Rota protegida sem token:** 401 tipado.
- **Carta em deck que não existe:** 404 `deck_not_found`, com a frase
  `Deck não encontrado.`.
- **Leitura de deck que não existe:** 404 tipado.
- **`PATCH /decks`:** 405 `method_not_allowed`.
- **`DELETE /auth/login`:** 404 `capability_route_unclassified`.
- **Rota fora do manifesto:** 404 tipado.
- **Origem negada:** 403 `cors_origin_denied`.

O teste de banco reproduz a corrida de dois cadastros com o mesmo e-mail e com o mesmo nome:

1. Uma transação insere a conta e segura o commit.
2. O cadastro passa da checagem de leitura e fica esperando no índice único. O teste
   confere a espera em `pg_stat_activity`.
3. O commit sai e o índice recusa o cadastro.

A resposta é 400 `auth_account_taken`, sem `Severity`, `23505` nem `duplicate key`, e fica
uma conta só.

Subconjuntos do servidor rodados fora da trava, só com os arquivos determinísticos: mais de
200 arquivos (rotas de auth, conta, deck, comunidade, social, fichário, trocas, import,
IA, battle, relatórios, saúde e o middleware raiz), todos verdes. A suíte completa roda na
trava no fim da rodada.

## Mutações

16 mutações. Cada uma foi aplicada no worktree, os testes rodaram, o arquivo foi
restaurado e conferido byte a byte. Todas falharam como esperado:

| Mutação | O que muda | Resultado |
| --- | --- | --- |
| M31 | saneador desligado | contrato 19/33 |
| M32 | detecção sem `Bad state:` | 31/33 |
| M33 | 5xx sem envelope deixa de passar (o 503 da prontidão) | 31/33 |
| M34 | 4xx com vazamento perde o `code` da rota | 32/33 |
| M35 | `apiError` volta a serializar `details.toString()` | 32/33 |
| M36 | o catch-all do cadastro ecoa a exceção | 32/33, pelo teste da fonte sem o middleware |
| M37 | cadastro sem mapear o 23505 | banco 0/2 |
| M38 | a rota de cartas volta a lançar `Exception('Deck not found...')` | 31/33 |
| M39 | a validação do deck gerado volta a pôr `e.toString()` nos erros | 11/12 |
| M40 | cadastro sem o catch de `RegistrationRejectedException` | 32/33 |
| M41 | envelope 4xx sem código não ganha `code` | 32/33 |
| M42 | envelope 4xx não ganha `request_id` | 29/33 |
| M43 | negação de CORS sem `request_id` | 32/33 |
| M44 | negação de capability sem `request_id` | 32/33 |
| M45 | o `code` fora do padrão que a rota mandou é sobrescrito | 32/33 |
| M46 | o log de saneamento perde o corpo original | 32/33 |

## O que fica para depois

- O código de domínio por rota é incremental. Hoje as frases das rotas antigas (cerca de
  228 em 64 arquivos) recebem o código pelo status.
- O catálogo ainda não entrou no `docs/generated/openapi.generated.json`.
- Tarefa do app (BT-UX-ERR-001): o `FriendlyErrorMapper` precisa preferir `message` a
  `error` e nunca mostrar código cru.
- Os `print($e)` das rotas ficam no log do servidor. Estão fora deste aceite, que trata do
  corpo público, e merecem uma limpeza própria.
