# Receipt — BT-AUTH-002: E2E da segunda correção contra a API rebuildada — 2026-09-28

- Tarefa: `BT-AUTH-002`, Frente A (servidor), branch `servidor/rodada2-2026-09-24`.
  - O receipt da tarefa é `docs/qa/execution/2026-09-24/BT-AUTH-002-limites.md`.
- Faltava o E2E por HTTP da segunda correção (`157aecca9`, que faz o 411 do corpo em partes
  chegar ao cliente). O commit de 2026-09-24 entrou sem ele porque a API ainda não tinha
  sido rebuildada. Esse build veio junto com o do BT-LEGAL-ACCEPT-001.
- Nada tocou a produção. As corridas usaram o PostgreSQL 17 descartável da frente
  (`LC_ALL=C`) e a API local presa ao loopback, parados ao fim.

## Corrida 1 — 2026-09-28, 12:51Z

- A API foi buildada de `3812b6d08` às 12:39:30Z e contém `157aecca9`.
  - Capabilities padrão da frente: `account_registration` e `decks_private`.
  - Cadastro por convite.
- `server/test/request_limits_e2e_live_test.dart`: 5/5.

  | Caso | Resultado |
  | --- | --- |
  | corpo de 2 MiB | 413 com o limite; o banco não muda |
  | corpo em partes, sem `Content-Length` | 411; o cliente recebe a resposta; o banco não muda |
  | corpo comprimido (gzip) | 415; nada é descomprimido |
  | campo e profundidade acima do teto | 413; o mesmo deck curto passa |
  | URL acima de 8 KiB | 414 com código |

- Sonda com `curl` em `POST /decks`, na mesma API:
  - em partes de 4 KiB: 411 em 0,015 s;
  - 3 MiB em partes: 411 em 1,0 s. O cliente recebe a resposta, e o descarte corta depois
    de 1 MiB;
  - o corpo é `{error: request_body_length_required, message, request_id}`.

## Corrida 2 — 2026-09-28, 15:18Z, depois do commit da D-82

- A API foi buildada de `b0f06073d` às 15:17:22Z, com as mesmas capabilities e o mesmo
  cadastro por convite.
- `server/test/request_limits_e2e_live_test.dart`: 5/5 de novo, nos mesmos cinco casos.
- Sonda com `curl` em `POST /decks` (`sonda_auth002.sh`, no apoio da frente):
  - em partes de 4 KiB: 411 em 0,002 s;
  - 3 MiB em partes: 411 em 1,007 s. O `curl` recebe a resposta e termina sem erro.
    - Ele mandou 1.639.331 bytes antes do corte.
    - A guarda lê no máximo 1 MiB do corpo. A diferença fica nos buffers de rede e no
      enquadramento das partes.
  - O corpo, nas duas medidas:

    ```json
    {"error":"request_body_length_required","message":"Envie o corpo com Content-Length; corpo em partes não é aceito.","request_id":"srv-…"}
    ```

## Resultado

- Não houve defeito.
- O buraco que o primeiro E2E achou está fechado de ponta a ponta. Era um corpo em partes
  que passava por cima dos limites e criava o deck (`POST /decks` 200).
- O 411 chega ao cliente, sem ler mais que 1 MiB do corpo.
- O `request_limits_e2e_live_test.dart` e a sonda ficam como prova. O teste liga com
  `RUN_REQUEST_LIMITS_E2E_TESTS=1`, que o `e2e.sh` da frente exporta.
