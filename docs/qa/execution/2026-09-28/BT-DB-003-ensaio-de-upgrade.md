# Receipt — BT-DB-003: upgrade e rollback por restore do mesmo dump, com perfis de origem — 2026-09-28

- **Tarefas:** `BT-DB-003` e a reconciliação da `BT-DB-002`.
- **Executado por:** Frente C (banco e operação), no worktree da frente, branch
  `banco/rodada1-2026-09-24`, com o código que entra no mesmo commit deste receipt.
- **Limites:** nada tocou a produção. Os ensaios usaram só fixtures sem dado da produção:
  - o bootstrap da produção, que está no git;
  - a deriva que a auditoria da `BT-DB-001` já publicou;
  - linhas sintéticas.

  O dump real ficou de fora. O ensaio com ele é do lote de deploy, ou antes, se a coordenação
  quiser (item em `decisoes-pendentes.md`).
- **Sem migration nova.**

## BT-DB-002 reconciliada

A linha pedia a "próxima migration preservadora, 059 somente se ainda for o próximo número".

- **O número ficou obsoleto:**
  - a 059 foi a D-66 (chave de `trade_items.owner_id`), na rodada 2 da privacidade;
  - as seguintes já estão tomadas pelas frentes: 060 a 073 nas faixas de cada uma, a 074 com a
    `BT-DB-007` desta frente, e a 066 reservada;
  - o que a D-48 dava à 059 (as 7 tabelas que o código usa e as colunas divergentes) ficou
    com a `BT-DB-005`.
- **O aceite era a disciplina: perfis de origem fechados, preflight antes de DDL, payload
  preservado e postcheck exato.** Nada disso existia no runner. Entrou agora, junto com a
  `BT-DB-003`, e vale para toda migration:
  - o preflight e os perfis estão no runner;
  - o payload e o postcheck exato estão no ensaio.

## O que entrou

| Arquivo | Papel |
| --- | --- |
| `server/lib/migration_preflight.dart` | classifica o banco pelo ledger: `sem_ledger` (sem ledger e sem contas), `canonico` (versões e nomes do código, prefixo da lista) ou `misto` (versão desconhecida, mesmo número com outro nome, pendente antes da última executada, contas sem ledger) |
| `server/bin/migrate.dart` | o preflight roda antes de qualquer DDL (antes de criar `schema_migrations`) na aplicação e no rollback; perfil misto para com código 3 sem escrever. `--preflight` só lê e imprime JSON; `--target VERSÃO` aplica só até a versão |
| `scripts/manaloom_migration_rehearsal.py` | o ensaio: PostgreSQL 17 descartável (loopback, sem socket, `sandbox-exec`), restauração (`estrutura` ou `completo`), preflight, banco novo, upgrade, pós-checagem do catálogo inteiro contra a lista fechada, payload, reaplicação, rollback pelo restore do mesmo dump e reforward |
| `server/config/schema_drift_allowlist.json` | a lista fechada da deriva aceita: 94 itens da auditoria BT-DB-001, menos o que a 058, a 059 e a 063 a 065 reconciliam; cada item com motivo e a decisão ou tarefa que o tira da lista. Proposta pendente do dono |
| `server/test/fixtures/schema_profiles/database_setup_058.sql` | o bootstrap da produção (`git show 41bab49c9:server/database_setup.sql`, sha256 `857c5642…ab057a9`) |
| `server/test/support/production_drift_fixture.py` | monta a deriva da produção item a item a partir da saída da auditoria |
| `scripts/manaloom_tbls_local_gate.sh` | o gate de schema (modos `schema` e `full`) roda o teste de banco do ensaio |
| `docs/runbooks/ENSAIO_DE_UPGRADE.md` | perfis, o ensaio, o que cada etapa confere, onde roda e como a lista fechada muda |

## Provas

| Prova | Resultado |
| --- | --- |
| `server/test/migration_preflight_test.dart` | 10 verdes |
| `server/test/migration_rehearsal_test.py` (catálogo, classificação, payload e a lista fechada contra a auditoria e as migrations 064 e 065) | 9 verdes |
| `server/test/migration_rehearsal_db_live_test.py` (`RUN_SCHEMA_DB_TESTS=1`) | 5 verdes |
| Mutações (`mutacoes_bt_db_003.json`), refeitas sobre a 074 | 14 de 14 derrubadas |
| Suíte do servidor, testes de banco e gates | suíte do servidor: 402 arquivos em 11 lotes, todos com rc=0 (tags live fora); `project_logic --write`, `--check` e `--test` verdes; contrato de release `passed` (34 contratos); comparação de schema do gate tbls num banco novo: PASS (80 tables, 6 views, 100 foreign keys, 64 migrations) |

### Os ensaios do teste de banco

- **Canônico.** O bootstrap da produção com as migrations até a 058 (`migrate --target 058`) e
  16 linhas sintéticas em 13 tabelas (28 no total, com as que o bootstrap semeia). O preflight dá `canonico`, com 6 pendentes (059, 060, 063,
  064, 065 e 074). Depois do upgrade:
  - a pós-checagem é **exata**: 0 diferença contra o banco novo em schemas, extensões, 80
    tabelas, 919 colunas, 145 restrições, 100 chaves estrangeiras, 320 índices, 6 views, 7
    funções, 47 gatilhos, 3 sequências e 64 versões do ledger;
  - o payload ficou igual nas 78 tabelas;
  - reaplicar não mudou nada;
  - o restore do mesmo dump é idêntico ao de antes, e o upgrade dele chega ao mesmo estado.
- **Deriva.** O canônico com a deriva publicada pela auditoria: 120 grupos aplicados e 2 não
  reproduzíveis sem a produção (o índice `card_rulings_pkey`, que lá está numa tabela
  renomeada, e um índice por expressão de uma tabela de backup). Depois do upgrade:
  - 186 diferenças, todas na lista fechada, nenhuma inesperada;
  - o que a 059, a 063, a 064 e a 065 reconciliam sumiu;
  - payload, rollback e reforward iguais.
- **Estrutura.** O modo sem dado restaura só a estrutura e o ledger (`public.schema_migrations`
  é a única tabela com linhas) e passa.
- **Misto.** Quatro perfis param antes de DDL, com código 3 e o banco igual ao de antes:
  - versão 999 que o código não conhece;
  - a 058 com outro nome;
  - a 057 pendente depois da 058;
  - ledger apagado com 2 contas.

  O `migrate` de verdade também recusa com 3, e o banco continua igual, sem nem a tabela do
  ledger criada.
- **Lista mais estreita.** Tirar o `uq_binder_user_card_cond_foil_list` da lista faz o ensaio
  da deriva falhar exatamente nele.

### Mutações

- B01 a B04: o preflight aceita versão desconhecida, número com outro nome, pendente antes da
  última ou contas sem ledger.
- B05: a aplicação ignora o perfil misto.
- B06: o rollback sem preflight.
- B07: `--target` ignorado.
- R01: a classificação aceita diferença fora da lista.
- R02: índice de tabela sobrando não fica coberto pela tabela.
- R03: o payload ignora linha mudada.
- R04: o rollback restaura só a estrutura.
- R05: gatilho comparado pelo nome com o OID da chave (migration 038).
- R06: o modo estrutura restaura as linhas.
- R07: a lista fechada sem um item da D-67.

## Achados

- **Gatilhos de conta ativa levam o OID da chave no nome** (migration 038, refeitos pela 059):
  o nome muda de um banco para outro. O ensaio identifica o gatilho pela definição sem o nome;
  a mutação R05 prova que sem isso o upgrade canônico acusa diferença.
- **A auditoria da BT-DB-001 não lê CHECK, gatilho nem função.** Com `list_type` em
  `varchar(4)` na produção, o CHECK da coluna ganha o cast no texto. Entrou na lista como
  inferido. O ensaio com o dump real é o que confirma o resto dessas categorias.
- **O runner aceitava ledger com versão desconhecida** e criava `schema_migrations` antes de
  olhar o ledger (achados do `docs/flows/_p0/banco.md`). Os dois fecharam.

## Achado no código integrado

Rodei o ensaio numa cópia de `integracao/2026-09-23` (`f81cde0e7`, com a 067 e a 068 da frente
de deck) mais este runner. Foi fora do worktree, sem commit.

- O upgrade canônico da 058 dá **uma** diferença contra o banco novo: falta o gatilho de conta
  ativa na chave `deck_change_events.user_id`. Payload, rollback e reforward ficam iguais.
- **A causa:** a 067 cria a tabela com chave para `users` sem rodar o laço dos gatilhos
  `manaloom_active_user_<oid>` (o padrão que a 056 roda no fim). No banco novo o gatilho existe,
  porque o bootstrap já tem a tabela quando o laço roda. No banco migrado, o caminho da
  produção, não existe.
- É a mesma classe do que a 062 conserta para `beta_invites`.
- **O conserto** é a migration 074, desta frente (`BT-DB-007`, receipt
  `BT-DB-007-gatilhos-de-conta-ativa.md`), que roda o laço depois da 067 e da 069.
  - Com ela, o ensaio passa 5 de 5 na integração e na prévia com a rodada 2 do deck.
  - A prévia acrescenta a 069 e o gatilho que faltaria em `ai_generate_requests.user_id`.
- Sem a 074, o teste de banco do ensaio fica vermelho na integração exatamente nesses gatilhos.

## Para o lote de deploy

Passo 1b, depois do backup e do ensaio de restauração:
`~/.manaloom/coordenacao/banco/lote_deploy_ensaio_upgrade.sh` roda o ensaio com o dump novo,
no modo `completo`.

- Qualquer código diferente de 0 para o lote antes das migrations.
- O `rehearsal.md` não tem linha de dado.

## O que segue aberto

- O dono aprovar a lista fechada (`decisoes-pendentes.md`).
- O ensaio com a forma real da produção, antes do lote. Ele usa o código integrado, que tem a
  061 e a 062 do servidor, a 067 a 069 e a 072 do deck, e a 074.
- As pendências que a lista carrega:
  - D-49, D-50 e D-67;
  - a migration da `BT-DB-005`;
  - os 21 índices só da produção e o `uq_binder`.
