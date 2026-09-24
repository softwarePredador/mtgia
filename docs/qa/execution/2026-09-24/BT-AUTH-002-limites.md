# Receipt — BT-AUTH-002: limites de requisição antes do parse — 2026-09-24

- Tarefa: `BT-AUTH-002`, Frente A (servidor, convite e segurança) da rodada de 2026-09-24,
  branch `servidor/rodada2-2026-09-24`.
- Decisão do dono aplicada: D-21, com teto de body de 1 MB e maior só no import.
- Aceite do backlog: "Oversize/chunked/compressed rejeitado antes de alocar/gravar; DB não
  cresce."
- Nada tocou a produção. Os testes de banco e o E2E rodaram num PostgreSQL 17 descartável
  da frente e numa API local presa ao loopback.

## O que mudou

`server/lib/request_body_limits.dart`, chamado pelo middleware raiz:

1. **URL.** Antes da decisão de capability: acima de 8 KiB (caminho e query) é 414
   `request_uri_too_long`.
2. **Cabeçalhos.** Depois da capability e antes da observabilidade, do banco e do handler,
   sem ler o corpo. A conexão fecha em vez de drenar o resto:
   - `Content-Encoding` diferente de `identity` → 415 `request_body_encoding_unsupported`.
     Nada é descomprimido, então não existe bomba de gzip.
   - `Transfer-Encoding` (corpo em partes, sem tamanho declarado) → 411
     `request_body_length_required`.
   - `Content-Length` inválido → 400 `request_body_length_invalid`.
   - `Content-Length` acima do limite do caminho → 413 `request_body_too_large`, com o
     limite.
3. **Tetos por caminho:**
   - 1 MiB por padrão;
   - 5 MiB nas cinco rotas de import (`/import`, `/import/to-deck`, `/import/validate`,
     `/binder/import/preview` e `/binder/import/apply`);
   - 16 KiB em `/auth`.
4. **Corpo dentro do limite.** É lido uma vez; o dart_frog guarda o texto e o handler
   recebe o mesmo. Um JSON (objeto ou lista) é conferido:
   - texto de campo ou de chave acima de 32 K caracteres, fora do import → 413
     `request_field_too_large`;
   - mais de 32 níveis → 413 `request_json_too_deep`, numa varredura linear, sem recursão e
     antes de decodificar;
   - mais de 50 mil itens → 413 `request_json_too_many_items`.

   Corpo que não é UTF-8 é 400 `request_body_unreadable`. JSON inválido segue para o
   handler, que responde como antes.
5. **Campos da conta:**
   - no cadastro, campo de tipo errado é 400 `request_invalid` (antes, a conversão lançava
     e dava 500);
   - nome de usuário acima de 30 é 400 `auth_username_too_long`;
   - e-mail sem formato mínimo ou acima de 254 é 400 `auth_email_invalid`;
   - no login, e-mail acima de 254 ou senha acima de 1024 é 400 `Dados inválidos.`, antes
     de qualquer consulta ou bcrypt. A resposta não diz nada sobre contas.

Todas as recusas têm código estável em `error`, frase em português e `request_id`, no
contrato do BT-AUTH-001.

## Correção depois do primeiro commit (`3d389f20f`)

O primeiro E2E contra a API de verdade achou um buraco que os testes em processo não
viam. O `shelf_io` tira o `Transfer-Encoding` dos cabeçalhos antes de entregar o pedido
(`shelf_io.dart`, em `_fromHttpRequest`). O corpo em partes chegava então ao middleware sem
nenhum sinal de tamanho e seguia para o handler sem limite. Numa sonda com `curl`, o
`POST /decks` em partes passou da checagem e bateu na autenticação.

A correção:

- **`guardBodyWithoutLength`** (`server/lib/request_body_limits.dart`) passa a ser a
  entrada do servidor, em `routes/_middleware.dart`, antes do middleware raiz. No pedido
  que pode ter corpo (`POST`, `PUT`, `PATCH`, `DELETE`) e não declara `Content-Length`, ela
  troca o corpo por um stream que falha no primeiro pedaço. Nada é acumulado, e a
  checagem do corpo responde 411 `request_body_length_required`, fechando a conexão. Os
  demais pedidos passam sem mudança de contexto.
- **Defesa em profundidade:** sem a guarda, a checagem do corpo também recusa corpo não
  vazio sem `Content-Length`.
- **O que o E2E mostrou sobre o cabeçalho mentiroso:** o servidor só devolve a recusa
  depois que o cliente termina de mandar o corpo que declarou. O `dart:io` descarta esse
  resto sem guardar, então o limite continua valendo antes de alocar; só a banda do
  cliente é gasta. O E2E passou a mandar o corpo inteiro, como um cliente de verdade.

Testes da correção:

- `request_body_limits_test` passou de 22 para 29 casos. Entre eles:
  - um servidor HTTP de verdade (`serve` do dart_frog, com `shelf_io`): o pedido em partes
    feito pelo cliente HTTP dá 411 e um corpo real acima do teto de `/auth` dá 413, os
    dois sem chegar ao handler;
  - dez pedaços de 1 KiB sem `Content-Length`: só o primeiro é lido;
  - a entrada do servidor usa a guarda.
- `request_limits_db_live_test` passou para 3 casos: o corpo em partes sem cabeçalho, pela
  cadeia real de `POST /decks`, dá 411, lê só o primeiro pedaço e não grava.
- Mutações:

  | Mutação | O que muda | Resultado |
  | --- | --- | --- |
  | M72 | a entrada do servidor sem a guarda | falha |
  | M73 | a guarda deixa os pedaços passarem | falha, também no teste de banco |
  | M74 | a checagem sem tamanho declarado aceita corpo não vazio | falha |

## Segunda correção (`f195ecde2` + descarte)

O E2E com o build da primeira correção mostrou um problema. A guarda parava no primeiro
pedaço cancelando o stream do `dart:io`, e o `dart:io` fechava a conexão antes de mandar o
411: o cliente via "Connection closed before full header was received". O servidor
registrava o 411, e nada era gravado, mas o cliente não recebia a resposta.

Agora a guarda sinaliza o erro no primeiro pedaço, o que dá o mesmo 411 sem chegar ao
handler, e continua lendo o resto só para descartar, sem guardar. Assim o 411 chega a quem
terminou de mandar. Passou de 1 MiB descartado (`chunkedBodyDrainLimitBytes`), o stream é
cancelado e a conexão cai, como antes.

Testes:

- `request_body_limits_test` passou a 31 casos. O caso novo pede, a um servidor HTTP de
  verdade, um corpo em partes com pausa de 200 ms entre os pedaços: o cliente recebe o
  411. Outro caso novo manda 2,5 MiB em partes, e o descarte para logo depois de 1 MiB.
- `request_limits_db_live_test` (3/3) continua sem gravar nada.
- Mutações:

  | Mutação | O que muda | Resultado |
  | --- | --- | --- |
  | M75 | volta a cancelar no primeiro pedaço | 28/31, com o cliente do servidor de verdade sem resposta |
  | M76 | descarte sem teto | 30/31 |

O E2E com clientes de verdade roda de novo com o próximo build da API, junto do
BT-LEGAL-ACCEPT-001.

## Evidência

| Teste | Onde | Resultado |
| --- | --- | --- |
| `server/test/request_body_limits_test.dart` | unitário, com o middleware raiz e um stream que conta os bytes lidos | 22/22 |
| `server/test/request_limits_db_live_test.dart` | PostgreSQL descartável (`RUN_REQUEST_LIMITS_DB_TESTS=1`), cadeia real de `POST /decks` (middleware raiz, autenticação e handler que grava) | 2/2 |
| `server/test/request_limits_e2e_live_test.dart` | HTTP contra a API local (`RUN_REQUEST_LIMITS_E2E_TESTS=1`), com clientes de verdade (corpo de 2 MiB, corpo em partes, gzip, campo, profundidade e URL) | roda com o build da API da tarefa seguinte; o resultado entra neste receipt no commit do BT-LEGAL-ACCEPT-001 |

O teste de banco mostra que o banco não cresce, e o unitário, que a recusa acontece antes
de alocar:

- Corpo declarado de 2 MiB, corpo em partes e corpo comprimido são recusados com zero byte
  lido. A contagem de decks da conta não muda.
- Um campo de 40 K caracteres dá 413 e também não grava.
- O mesmo pedido, com o nome curto, cria o deck: a contagem sobe um.

Subconjuntos do servidor no worktree, só com os arquivos determinísticos: 142 arquivos e
904 testes, todos verdes (auth, conta, convite, import, fichário, deck, comunidade, social,
trocas, IA, battle, relatórios, saúde e o middleware raiz). Os testes de banco do convite e
do BT-AUTH-001 seguem verdes com os limites (17/17 no total).

## Mutações

13 mutações. Cada uma foi aplicada na cópia de trabalho do server (a mesma aplicação do
worktree), os testes rodaram e o arquivo foi restaurado e conferido byte a byte. Todas
falharam como esperado:

| Mutação | O que muda | Resultado |
| --- | --- | --- |
| M47 | sem o teto do `Content-Length` | unitário 19/22; banco 1/2 |
| M48 | corpo em partes aceito | 19/22; banco 1/2 |
| M49 | corpo comprimido aceito | 19/22 |
| M50 | sem o teto por campo | 20/22; banco 1/2 |
| M51 | sem a varredura de profundidade | 21/22 |
| M52 | teto de itens cem vezes maior | 21/22 |
| M53 | o middleware ignora a recusa pelos cabeçalhos | 20/22; banco 1/2 |
| M54 | o middleware ignora a URL longa | 21/22 |
| M55 | cadastro sem o teto do nome | 21/22 |
| M56 | cadastro sem conferir o tipo do nome | 21/22 |
| M57 | login com teto de e-mail cem vezes maior | 21/22 |
| M58 | corpo ilegível não é recusado | 21/22 |
| M59 | cadastro sem conferir o formato do e-mail | 21/22 |

## Decisões registradas no diário, com a recomendação

- O teto do import é 5 MiB. A D-21 diz "maior só no import", sem número.
- Os demais tetos:
  - 32 K caracteres por campo;
  - 32 níveis e 50 mil itens por JSON;
  - URL de 8 KiB e 16 KiB em `/auth`;
  - nome de usuário de 30.
- Corpo em partes é recusado, não cortado no stream. O app e o navegador mandam
  `Content-Length`.
