# Runbook — ensaio de upgrade e rollback por restore do mesmo dump (`BT-DB-003`)

- **Ferramenta:** `scripts/manaloom_migration_rehearsal.py`.
- **Preflight do runner:** `server/lib/migration_preflight.dart`, chamado por
  `server/bin/migrate.dart` antes de qualquer DDL.
- **Lista fechada da deriva aceita:** `server/config/schema_drift_allowlist.json`, proposta
  pendente do dono.
- **Rollback de migration na produção:** é o restore do dump tirado antes dela. Quase todas as
  migrations desde a 034 alteram ou adotam dado e têm rollback `manualOnly`
  (`migrationRollbackPolicy` em `server/bin/migrate.dart`); o passo a passo do restore está em
  `docs/runbooks/BACKUP_E_RESTAURACAO.md`.

## Perfis de origem

O runner classifica o banco pelo ledger (`schema_migrations`) contra a lista de migrations do
código, antes de criar a tabela do ledger e antes de qualquer migration:

| Perfil | Quando | O runner |
| --- | --- | --- |
| `sem_ledger` | sem ledger (ou vazio) e sem contas em `users`: o banco novo do bootstrap | aplica tudo |
| `canonico` | toda versão do ledger existe no código com o mesmo nome, e as executadas são um prefixo da lista | aplica as pendentes |
| `misto` | versão que o código não conhece, mesmo número com outro nome, pendente anterior à última executada, ou contas sem ledger | para com código 3, sem escrever |

`dart bin/migrate.dart --preflight` só lê e imprime o perfil em JSON. `--target VERSÃO` aplica
as pendentes só até essa versão.

A deriva da produção não é um perfil do runner (D-48). As migrations a reconciliam, e o ensaio
confere o que sobra contra a lista fechada.

## O ensaio

```bash
MANALOOM_APPROVE_DISPOSABLE_POSTGRES=I_APPROVE_DISPOSABLE_LOCAL_POSTGRES \
  python3 scripts/manaloom_migration_rehearsal.py \
  --dump ARQUIVO.dump --out-dir DIRETÓRIO [--restore estrutura|completo]
```

Tudo roda num PostgreSQL 17 local e descartável, só em loopback, sem socket e, no macOS, em
`sandbox-exec` sem rede externa. O cluster é apagado no fim, e o dump só é lido.

| Etapa | O que confere |
| --- | --- |
| Restauração de antes | `pg_restore --exit-on-error`. No modo `estrutura` (padrão), só a estrutura e o ledger: nenhuma outra tabela pode ter linha |
| Preflight | o perfil do banco pelo runner. No perfil misto, o ensaio roda também o `migrate` de verdade e exige código 3 e o banco igual a antes (catálogo e linhas): sai com 3 (BLOCKED) |
| Banco novo | `server/database_setup.sql` e todas as migrations: a referência da pós-checagem |
| Upgrade | o `migrate` aplica as pendentes; o ledger fica igual ao do banco novo |
| Pós-checagem | o catálogo inteiro contra o do banco novo: schemas, extensões, tabelas, colunas, restrições, chaves, índices, views, funções, gatilhos, sequências, enums e ledger. Toda diferença tem de estar na lista fechada |
| Payload | cada tabela de antes, pelas colunas de antes: mesmas linhas e mesmo hash depois do upgrade, salvo mudança declarada na lista |
| Reaplicação | rodar o `migrate` de novo não muda nada |
| Rollback por restore | o mesmo dump restaurado outra vez é idêntico ao de antes: catálogo, ledger e linhas |
| Reforward | o upgrade do banco restaurado chega ao mesmo catálogo e às mesmas linhas do primeiro upgrade |

Saídas: `rehearsal.json` e `rehearsal.md` no diretório pedido. Códigos: 0 PASS, 1 FAIL, 2
entrada ou ambiente recusado, 3 BLOCKED (perfil misto).

## Onde roda

- **Gate de schema** (`scripts/manaloom_tbls_local_gate.sh`, nos modos `schema` e `full`):
  `server/test/migration_rehearsal_db_live_test.py` monta, sem dado da produção, os perfis
  canônico (o bootstrap da produção, `server/test/fixtures/schema_profiles/database_setup_058.sql`,
  com as migrations até a 058), deriva (o canônico com a deriva publicada pela auditoria
  BT-DB-001) e misto, e roda o ensaio em cada um.
- **Lote de deploy**, depois do backup e do ensaio de restauração e antes da primeira
  migration na produção: o ensaio com o dump novo, no modo `completo`, com a palavra do dono
  (é dado da produção, só na máquina de operação). Qualquer código diferente de 0 para o lote.

## A lista fechada

Cada item tem categoria, tipo (`faltando`, `sobrando` ou `divergente`), objeto, motivo e a
decisão ou tarefa que o cobre. Uma entrada de schema ou de tabela sobrando cobre o que está
dentro dela. Quando a decisão ou a tarefa fecha, a entrada sai. O teste
`server/test/migration_rehearsal_test.py` confere que cada item vem da auditoria (ou diz que é
inferido) e que toda diferença da auditoria está na lista, coberta, ou reconciliada por uma
migration.
