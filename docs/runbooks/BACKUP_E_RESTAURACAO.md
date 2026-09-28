# Runbook — backup local e ensaio de restauração (`BT-DR-001`)

- **Política:** `server/config/backup_policy.json` (D-12, D-23 e D-81).
- **Objetivos (D-12):** RPO de 24 h e RTO de 4 h.
- **Onde fica o backup (D-81):** em `backups/manaloom-postgres/` na máquina de operação que
  roda o ciclo, fora do git. Não há cópia fora do servidor. Risco aceito: perder juntos a
  máquina do backup e o servidor.
- **Pendências do dono:** cifrar o backup local (D-12 pedia `age`) e o prazo de rotação dos
  dumps (D-23).

## Cadência

| O quê | Quando | Como |
| --- | --- | --- |
| Backup | no máximo a cada 24 h (RPO) | `scripts/manaloom_backup_cycle.sh --execute` |
| Ensaio de restauração isolado | no máximo a cada 7 dias, e antes de aplicar migration na produção | `scripts/manaloom_backup_cycle.sh --execute --drill` |
| Conferência da cadência | a qualquer momento | `python3 scripts/manaloom_backup_cadence.py check --backup-dir <dir>` |

- O intervalo do backup sai do RPO. A cadência semanal do ensaio é proposta desta tarefa,
  igual ao check semanal do instalador de cron remoto, e fica para o dono confirmar.
- O ciclo lê a produção por `pg_dump`, pela aprovação live do próprio
  `scripts/manaloom_easypanel_backup.sh`. O ensaio roda num PostgreSQL 17 local e sem rede
  (`scripts/manaloom_full_restore_drill.sh`, que pede `MANALOOM_RESTORE_DRILL_EXECUTE=1`).
- Defina `MANALOOM_BACKUP_DIR` num diretório durável, o mesmo de todos os ciclos, para a
  cadência enxergar o histórico. Com `--execute`, o ciclo para sem essa variável e recusa
  `/tmp` e worktree temporária.

## Antes de migration na produção (lote de deploy)

É o passo 1 do lote, antes da primeira migration: só com a palavra do dono para o lote,
porque o backup lê a produção.

```bash
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_RESTORE_DRILL_EXECUTE=1 \
MANALOOM_BACKUP_DIR=<diretório durável dos backups> \
./scripts/manaloom_backup_cycle.sh --execute --drill
```

O Docker tem de estar de pé, porque o ensaio roda num container. `MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256`
tem de fixar o host, como em todo deploy.

| Passo | O que confere |
| --- | --- |
| Política | `validate-policy`: RPO e RTO iguais ao texto da D-12, destino local sem cópia fora (D-81), ensaio sem rede e o primeiro ciclo igual ao receipt da `BT-REL-000` |
| Diretório | durável, fora de `/tmp` e de worktree; a checagem anterior ao ciclo sai BLOCKED, e isso é esperado |
| Backup | host SSH pela fingerprint fixada; `pg_dump -Fc` do banco `halder` do serviço `evolution_manaloom-postgres`; arquivo com pelo menos 1 KiB, `chmod 600`; `pg_restore --list` lê o arquivo |
| Ensaio | imagem PostgreSQL 17 pelo digest aprovado, container `--network none`; `pg_restore --exit-on-error` sem dono nem privilégios; ao menos 80 tabelas; chaves estrangeiras contadas; `SET CONSTRAINTS ALL IMMEDIATE`; contagens de `users`, `cards`, `decks` e `deck_cards`; `remote_writes: false`; o container sai no fim |
| Receipt | nome, tamanho e SHA-256 do dump; o SHA-256 que o ensaio restaurou é o do arquivo; backup com menos de 24 h (RPO); ensaio com menos de 7 dias e duração abaixo de 4 h (RTO) |
| Depois | comparar tabelas, chaves e as quatro contagens com o ciclo anterior: queda sem motivo conhecido para o lote antes da migration |

O ciclo sai com 0 quando tudo passa e com 3 quando a cadência não fecha; 1 e 2 são falha do
backup ou do ensaio e entrada recusada. Qualquer código diferente de 0 para o lote.

Com o ciclo em 0, o passo seguinte do lote, ainda antes da migration, é o ensaio do upgrade
com o dump novo (`docs/runbooks/ENSAIO_DE_UPGRADE.md`, modo `completo`).

## Receipt

Cada ciclo grava `<dir>/receipts/<carimbo>.json` com:

- nome, tamanho e SHA-256 do dump;
- a evidência do ensaio (`drills/<carimbo>/restore-result.json`), quando houver;
- o resultado da cadência: idade do último backup contra o RPO, idade do último ensaio,
  duração da restauração contra o RTO e se o dump ensaiado é o mesmo arquivo.

O ciclo sai com 0 quando a cadência está cumprida e com 3 quando não está. O receipt fica na
máquina do backup, fora do git. Para registrar a execução no repositório, copie os números,
nunca o dump, para `docs/qa/execution/<data>/`.

## Restauração da produção (RTO de 4 h)

Só com a palavra do dono: é escrita na produção.

1. Registrar o início (UTC). O RTO conta daqui.
2. Escolher o dump mais novo com ensaio aprovado: o receipt diz qual é e o SHA-256.
3. Conferir o SHA-256 do arquivo contra o receipt.
4. Subir um PostgreSQL 17 com a imagem aprovada
   (`postgres:17.10-alpine3.23@sha256:8189a1f6…`) e criar um banco novo.
5. `pg_restore --exit-on-error --no-owner --no-privileges` no banco novo.
6. Conferir como no ensaio: número de tabelas, chaves estrangeiras, `SET CONSTRAINTS ALL
   IMMEDIATE` e as contagens de `users`, `cards`, `decks` e `deck_cards`.
7. Apontar a API para o banco restaurado e conferir `/health/ready` (a última migration
   tem de ser a que o deploy exige).
8. Registrar o fim e o tempo total no receipt da coordenação.

O ensaio semanal mede só a restauração (passos 4 a 6). Os outros passos dependem de onde a
produção for reerguida e estão fora do ensaio.
