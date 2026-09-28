# Receipt — BT-DB-007: trava de conta ativa no banco migrado (migration 074) — 2026-09-28

- **Tarefa:** `BT-DB-007`, achado da Frente C no ensaio de upgrade da `BT-DB-003` sobre o código
  integrado. A coordenação escolheu que a Frente C faz a migration, na faixa 074 a 076.
- **Executado por:** Frente C (banco e operação), no worktree da frente, branch
  `banco/rodada1-2026-09-24`, sobre `ddc910fe9`, com o código que entra no mesmo commit deste
  receipt.
- **Autorização e limites:** nada tocou a produção. Sem SSH, sem banco remoto, sem deploy. Os
  bancos foram PostgreSQL 17 descartáveis em loopback (`LC_ALL=C`), apagados no fim. O código
  integrado foi lido por `git archive`, em cópias fora de qualquer worktree, sem tocar em
  `~/.manaloom/coordenacao/wt/integ`.

## O problema

A trava de conta ativa da migration 038 é um gatilho por chave estrangeira de uma coluna para
`users`, chamado `manaloom_active_user_<oid da chave>`. Ele recusa linha nova que aponte para
conta excluída (`inactive_user_reference`, 23503). O gatilho nasce de um laço genérico sobre
`pg_constraint`, e o laço só enxerga as chaves que existem quando roda. A 038, a 041, a 053, a
054, a 056 e o bootstrap rodam o laço.

A 067 (`deck_change_events`) e a 069 (`ai_generate_requests`), da frente de deck, criam chave
para `users` e não rodam o laço:

- **banco novo** (bootstrap mais migrations): o bootstrap já tem as tabelas quando as
  migrations rodam o laço, e o gatilho existe;
- **banco migrado**, que é o caminho da produção: a chave nasce depois do último laço, e o
  gatilho falta.

Na produção, isso tem duas consequências:

- a linha nova que aponta para a conta excluída entraria nessas tabelas;
- o contrato somente leitura da 038 no deploy (`active_user_triggers`, em
  `scripts/manaloom_deploy_backend_image.sh`) recusaria o release depois das migrations do
  lote.

## O que entrou

| Arquivo | Papel |
| --- | --- |
| `server/bin/migrate.dart` | migration 074 (`reinstall_active_user_triggers`): o laço canônico da 056 sobre toda chave de uma coluna para `users`. Down neutro (`SELECT 1;`), porque os gatilhos são a trava da 038 e tirá-los reabriria o buraco. Rollback padrão |
| `server/lib/health_readiness_support.dart`, `scripts/manaloom_deploy_backend_image.sh`, `scripts/manaloom_release_ops_contract_test.sh`, testes de readiness e gerador | as travas de última migration sobem de 065 para 074 (27 migrations exigidas no readiness e 24 no contrato do deploy) |
| `server/test/active_user_trigger_rule_test.dart` | a regra, sem banco (12 testes) |
| `server/test/active_user_triggers_db_live_test.dart` | a trava no banco descartável (3 testes, `RUN_SCHEMA_DB_TESTS=1`) |
| `server/doc/API_CONTRACTS_AND_DATA_MAP.md`, `docs/project_logic_contracts.json` | readiness até a 074; o teste da regra no fluxo `release_operations` |

**A regra** (`active_user_trigger_rule_test.dart`):

- a partir da 070, toda migration com chave para `users` roda o laço canônico no fim do `up`,
  depois da última chave;
- até a 069, toda chave para `users` tem um laço depois dela, na mesma migration ou numa
  seguinte (a 067 e a 069 dependem da 074);
- no bootstrap, o laço vem depois da última chave;
- todo laço de conta ativa num `up` é igual ao canônico.

A regra enxerga chave sem coluna, com schema, entre aspas e em `ALTER TABLE`, e ignora
comentário e outra tabela. Ela vale para todas as frentes: a 070 e a 071 (servidor) e a 073
(deck) precisam rodar o laço se criarem chave para `users`.

## Conferência no código integrado

`~/.manaloom/coordenacao/banco/listar_gatilhos.py` monta dois bancos do mesmo código:

- **novo:** `database_setup.sql` e `migrate.dart`;
- **migrado:** o bootstrap da produção em `41bab49c9` (fixture da 058), `migrate --target 058` e
  depois o upgrade.

As cópias saíram de `montar_integ074.sh`: `git archive` da árvore, a `BT-DB-003` da cópia de
trabalho e, quando indicado, a 074.

| Código | Banco novo | Banco migrado (058 → última) |
| --- | --- | --- |
| integração `f81cde0e7`, sem a 074 | 42 chaves, 0 sem gatilho | 42 chaves, **1 sem gatilho**: `deck_change_events.user_id` |
| integração `f81cde0e7`, com a 074 | 42 chaves, 0 sem gatilho | 42 chaves, 0 sem gatilho |
| prévia integração + `deck/rodada2-2026-09-24` (`git merge-tree`, com 069 e 072), sem a 074 | 43 chaves, 0 sem gatilho | 43 chaves, **2 sem gatilho**: `deck_change_events.user_id` e `ai_generate_requests.user_id` |
| a mesma prévia, com a 074 | 43 chaves, 0 sem gatilho | 43 chaves, 0 sem gatilho |

**O ensaio de upgrade da `BT-DB-003`** (`migration_rehearsal_db_live_test.py`, 5 testes: perfis
canônico, deriva, só estrutura, misto e deriva fora da lista), nas mesmas cópias:

| Código | Resultado |
| --- | --- |
| integração, sem a 074 | 4 falhas; a única diferença inesperada é o gatilho de `deck_change_events` |
| integração, com a 074 | 5 verdes |
| prévia com o deck, sem a 074 | 4 falhas; as diferenças são os gatilhos de `ai_generate_requests` e `deck_change_events` |
| prévia com o deck, com a 074 | 5 verdes |

O teste da regra, nas mesmas cópias:

- com a 074: 12 verdes;
- sem a 074: falha, e aponta a 067, e na prévia também a 069. A 059 também aparece, porque
  recria só o gatilho da própria chave e não roda o laço canônico.

## Provas no worktree

| Prova | Resultado |
| --- | --- |
| Suíte de foco (a regra, SQL literal, readiness, migrations de battle, contrato de operações de IA, modelo de dados, adoção de schema, regressão SQL de privacidade, visibilidade de conta excluída, exclusão de conta) | 117 verdes; 3 pulados (o teste de banco sem a chave) |
| Testes de banco no descartável da frente (64 migrations, última 074): os 10 `*_db_live_test.dart` e os 3 `*_db_live_test.py` | todos verdes, com `active_user_triggers_db_live_test.dart` 3 de 3; o do catálogo pula os 2 casos, que pedem banco sem cartas |
| O mesmo teste de banco no banco da prévia com o deck e a 074 (68 migrations) | 3 de 3 |
| Mutações (`mutacoes_bt_db_007.json`, na cópia de trabalho da frente) | 14 de 14 derrubadas |
| Gates, na trava | suíte do servidor: 401 arquivos em 11 lotes, todos com rc=0 (tags live fora); `project_logic --write`, `--check` e `--test` verdes; contrato de release `passed` (34 contratos); comparação de schema do gate tbls num banco novo: PASS (80 tables, 6 views, 100 foreign keys, 64 migrations) |

**Mutações** (cada uma tem de derrubar um teste):

- **A01 a A04, na 074** (pegas pela regra e pelo teste de banco):
  - `up` neutro;
  - laço sem o `DROP TRIGGER`;
  - gatilho só no `UPDATE`;
  - laço que pula `decks`.
- **A05 e A06:** down que tira os gatilhos; rollback só manual.
- **A07 e A08:** uma 075 com chave para `users` sem o laço, ou com o laço antes da chave.
- **A09:** bootstrap com tabela de chave para `users` depois do laço.
- **A10 a A13, na própria regra:**
  - sem o corte da 070;
  - só enxerga chave com parênteses;
  - ignora a posição do laço;
  - aceita qualquer laço.
- **A14:** readiness que ainda exige a 065 como a última.

## Para a integração e o lote de deploy

- **Listas de migrations:** a 074 entra na união das listas (`migrate.dart`, readiness, contrato
  do deploy e contrato de release), e a 074 é a última.
- **Lote de deploy:** a 074 roda depois da 067 e da 069. Ela pega um lock curto em cada tabela
  com chave para `users`, como a 053, a 054, a 056 e a 062.
- **Ensaio de upgrade:** com a `BT-DB-003` integrada, ele passa no código integrado com a 074.
  Sem a 074, fica vermelho exatamente nesses gatilhos.
