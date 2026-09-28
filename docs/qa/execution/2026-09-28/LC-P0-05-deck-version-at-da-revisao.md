# Receipt — LC-P0-05: `deck_version_at` passa a ser o instante da revisão do deck — 2026-09-28

- Tarefa: `LC-P0-05` (achado 3 dos fluxos), parte do servidor, feita pela Frente B (deck e
  trocas) da coordenação do MVP na branch `deck/rodada2-2026-09-24`, sobre `36b9d3729`
  (DCK-P0-06).
- Aceite do backlog: "O seletor de cartas do pós-jogo funciona em partida de mais de 5
  minutos; teste de servidor fixa `deck_version_at` na revisão do deck."
- O defeito: o `GET /decks/:id` devolvia `deck_version_at = DateTime.now()` a cada leitura. A
  tela do pós-jogo exige que a versão carregada seja o mesmo instante da versão pedida
  (`isAtSameMomentAs`). O cache de 5 minutos do `DeckProvider` expira durante qualquer
  partida de verdade, e a nova leitura trazia outro instante, então o seletor de cartas
  ficava bloqueado.
- Nada tocou a produção, e a tarefa não tem migration. Os testes de banco rodaram num
  PostgreSQL 17 descartável da frente (`LC_ALL=C`, só em `127.0.0.1`), criado do zero do
  worktree (`migrations=64 latest=072`), parado e apagado no fim.

## O que mudou

- `server/lib/deck_snapshot_contract.dart`: `deckVersionAtSql(alias)` define o instante da
  versão do deck. É o `created_at` do evento do ledger que levou o deck à revisão atual
  (DCK-P0-01). Na revisão 1, vale a criação do deck. Para deck legado sem data de criação,
  vale um instante fixo, também estável.
- `GET /decks/:id` devolve esse instante em `deck_version_at`. Ler de novo a mesma revisão
  devolve o mesmo valor; mudar o deck sobe a revisão e muda o instante. A mudança do deck
  pode ser cartas, metadados, ida para a lixeira ou volta dela.
- A nota do pós-jogo criada sem a versão do app (cliente antigo) grava o mesmo instante que
  o `GET` devolve, e não mais o instante da gravação.
- O app não precisa mudar: ele já compara com `isAtSameMomentAs`, e o valor agora é estável.
- Contrato de API: as linhas de `GET /decks/:id` e de `POST /decks/:id/post-game-notes`
  foram atualizadas.

## Evidência

| Teste | Onde | Resultado |
| --- | --- | --- |
| `server/test/deck_version_at_db_live_test.dart` | PostgreSQL descartável | 3/3 |
| Os testes de banco que leem ou mudam o deck: `deck_version_at`, `deck_incremental_edit`, `deck_review_artifact`, `deck_revision_ledger`, `deck_strict_readiness`, `deck_trash`, `import_to_deck_two_phase` e `privacy_account_deletion` (8 arquivos) | PostgreSQL descartável | 72/72 |
| `server/test/deck_snapshot_contract_test.dart`, `deck_fetch_hydration_contract_test.dart`, `post_game_note_sync_contract_test.dart`, `api_contracts_data_map_guard_test.dart` e a suíte de foco | unitário, com o manifesto regenerado, dentro da trava, antes do commit | 44/44 (10 arquivos) |

Os 3 casos do teste de banco:

- a mesma revisão devolve o mesmo `deck_version_at` em duas leituras separadas no tempo, e
  ele é a criação do deck na revisão 1;
- mudar o deck (`PATCH`) muda a revisão e o instante, que passa a ser o `created_at` do
  evento da revisão 2 e fica estável nas leituras seguintes;
- a nota do pós-jogo sem versão do app grava o hash e o instante que o seletor leu.

## Mutações

4 mutações e 8 execuções, 0 sobreviventes (`~/.manaloom/coordenacao/deck/mutations.py lc05`).
Cada mutação foi aplicada no worktree, os testes rodaram, e o arquivo foi restaurado e
conferido por hash.

| Mutação | O que muda | Resultado |
| --- | --- | --- |
| L1 | o `GET` volta ao horário da requisição | falhou (esperado), no unitário e no banco |
| L2 | a versão ignora o ledger (sempre a criação do deck) | falhou (esperado), no unitário e no banco |
| L3 | a versão aponta a revisão anterior | falhou (esperado), no unitário e no banco |
| L4 | a nota grava o instante da leitura | falhou (esperado), no unitário e no banco |

## O que fica de fora

- **Prova de runtime do seletor** numa partida de mais de 5 minutos no app, com os três
  níveis do contrato de evidência de UI. É da raia do app, que está bloqueada até as
  recapturas do gate.
- **Achado A17 do fluxo do pós-jogo:** o servidor ainda aceita o par hash/versão que o app
  manda na nota sem conferir com o ledger. Não faz parte desta tarefa.
