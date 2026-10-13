# Runbook — backup local e ensaio de restauração (`BT-DR-001`)

- **Política:** `server/config/backup_policy.json` (D-12, D-23, D-81, D-83 e D-84).
- **Objetivos (D-12):** RPO de 24 h e RTO de 4 h.
- **Onde fica o backup (D-81):** em `backups/manaloom-postgres/` na máquina de operação que
  roda o ciclo, fora do git. Não há cópia fora do servidor. Risco aceito: perder juntos a
  máquina do backup e o servidor.
- **Cifra e guarda (D-84, 2026-09-28):**
  - a cifra em repouso do MVP é o FileVault do disco da máquina de operação; o `age` volta
    quando houver cópia fora da máquina;
  - cada dump fica 30 dias;
  - o dump mais novo com ensaio aprovado fica sempre, e o mais novo de todos também.

## Cadência

| O quê | Quando | Como |
| --- | --- | --- |
| Backup | no máximo a cada 24 h (RPO) | `scripts/manaloom_backup_cycle.sh --execute` |
| Ensaio de restauração isolado | no máximo a cada 7 dias, e antes de aplicar migration na produção | `scripts/manaloom_backup_cycle.sh --execute --drill` |
| Conferência da cadência | a qualquer momento | `python3 scripts/manaloom_backup_cadence.py check --backup-dir <dir>` |

- O intervalo do backup sai do RPO. A cadência semanal do ensaio e o ensaio antes de toda
  migration na produção foram aceitos pelo dono (D-83). A semana é a mesma do check semanal do
  instalador de cron remoto.
- O ciclo lê a produção por `pg_dump`, pela aprovação live do próprio
  `scripts/manaloom_easypanel_backup.sh`. O ensaio roda num PostgreSQL 17 local e sem rede
  (`scripts/manaloom_full_restore_drill.sh`, que pede `MANALOOM_RESTORE_DRILL_EXECUTE=1`).
- Defina `MANALOOM_BACKUP_DIR` num diretório durável, o mesmo de todos os ciclos, para a
  cadência enxergar o histórico. Com `--execute`, o ciclo para sem essa variável e recusa
  `/tmp` e worktree temporária.

## Guarda de 30 dias (D-84)

- **Quais dumps estão vencidos:** `python3 scripts/manaloom_backup_cadence.py check --backup-dir <dir>`
  lista, em `retention`, os que passaram de 30 dias (`expired`) e os que ficam de qualquer jeito
  (`keep`):
  - o dump mais novo com ensaio aprovado;
  - o dump mais novo de todos.
- **O check não apaga nada.**
- **A rotação é automática (2026-10-10):** cada `scripts/manaloom_backup_cycle.sh --execute`,
  depois do receipt do backup novo, roda
  `python3 scripts/manaloom_backup_cadence.py rotate --backup-dir <dir> --apply` e grava
  `<dir>/rotations/<carimbo>.json`. Roda com a cadência cumprida ou não; se o backup ou o ensaio
  falharem, o ciclo para antes e nada é apagado.
- **O que a rotação apaga:** só o padrão governado:
  - arquivo comum, nunca link, na raiz do diretório (não desce em `receipts/`, `drills/`,
    `rotations/` nem em outra pasta);
  - nome `manaloom-postgres-AAAAMMDDTHHMMSSZ.dump`, exatamente;
  - carimbo do nome com mais de 30 dias (`retention_days`); 30 dias exatos ficam;
  - fora do `keep`.

  Um dump parcial, menor que 1 KiB, também sai quando vence, porque pode ter dado de conta.
- **Sem `--apply`, a rotação só lista** (`status: dry_run`). Rodar à mão fora do ciclo é para
  conferir antes; apagar à mão continua pedindo o sim do dono.
- **Consumidor `backups` da exclusão de conta (BT-PRIV-002):** segue bloqueado até o ciclo rodar
  agendado de fato. A D-84 manda fechar pelo tempo (30 dias mais 1) quando a rotação estiver
  automatizada. Atenção: o `keep` guarda o dump mais novo com ensaio aprovado mesmo vencido.
  Fechar pelo tempo só é verdade se houver ensaio aprovado a cada 7 dias (D-83).

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
com o dump novo (`docs/runbooks/ENSAIO_DE_UPGRADE.md`, modo `completo`). Depois vem o passo
de migrations (`scripts/manaloom_lot_apply_migrations.sh`):

1. `--execute --preview` faz a prévia do dedupe da D-74 na produção e desfaz (ROLLBACK). Ela
   imprime as contagens da gravação.
2. Com a palavra do dono sobre esses números, rode `--execute --apply` com as provas deste
   ciclo e do ensaio e um `--esperado d74:<objeto>=<n>` para cada contagem. O dedupe grava
   antes da primeira migration, e o script recusa sem gravar se uma contagem não bater.
   Depois vêm as migrations, e tudo vai para o mesmo receipt.
3. Para repetir o `--apply` depois de uma falha, refaça antes o `--execute --preview`. Se o
   dedupe já gravou e o migrate falhou com o banco ainda na 058 (o receipt diz o passo), os
   sets já estão fundidos: as contagens da prévia nova (em geral 0) são as que vão no
   `--esperado`. Com as contagens antigas, o script recusa sem gravar (código 3). As provas
   do ciclo e do ensaio continuam valendo só dentro das 24 h do RPO. Com o banco além da
   058 (o migrate gravou parte do lote), o passo recusa repetir; o receipt diz onde parou,
   e a saída é a palavra do dono: terminar o lote à mão ou o restore da seção abaixo.

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
7. Apontar a API para o banco restaurado, com uma imagem do backend que aceite esse banco,
   e conferir `/health/ready`. O readiness exige que a última migration do banco seja a que
   a imagem conhece; o dump do passo 1 do lote está na 058, que só a imagem anterior ao
   lote aceita. Depois de um deploy do backend que falhou com o banco migrado, o serviço
   pode estar na imagem nova (veja a seção seguinte):
   - confira o estado com `docker service inspect <serviço> --format
     '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}'` e
     `docker service ls --filter name=<serviço>`;
   - só com o banco já restaurado, volte o serviço para a imagem anterior com
     `docker service update --image <imagem anterior> --env-add GIT_SHA=<GIT_SHA anterior>
     <serviço>`, a partir de `paused`, `rollback_paused`, `updating` ou `completed`. A
     imagem anterior (`repo@sha256:…`) e o GIT_SHA dela estão na mensagem do deploy. O
     comando é explícito e idempotente: rodar de novo não muda nada. Espere `completed`,
     1/1 e a imagem anterior na spec e na tarefa;
   - não use `docker service rollback`: ele troca a spec pela anterior (PreviousSpec), e
     todo update, o `--force` inclusive, grava a spec atual como a anterior. Depois de um
     `--force`, ele volta para a imagem nova, e ele não é idempotente: rodado duas vezes,
     volta para ela;
   - se o deploy já tinha trocado a origem no EasyPanel (a mensagem do deploy diz), volte-a
     para o mesmo digest. Sem isso, um redeploy pelo painel sobe a imagem nova de novo;
   - `/health/ready` tem de responder `ready`. Nesse estado (1/1, spec igual à tarefa,
     `completed`), o próximo deploy volta a aceitar o serviço.
8. Registrar o fim e o tempo total no receipt da coordenação.

O ensaio semanal mede só a restauração (passos 4 a 6). Os outros passos dependem de onde a
produção for reerguida e estão fora do ensaio.

## Deploy do backend que falhou depois do lote

Depois do lote, o banco está numa migration que a imagem anterior do backend não aceita
(D-104, item 12 do pacote de decisões de 2026-10-10). Por isso o
`scripts/manaloom_deploy_backend_image.sh` não volta sozinho: o Swarm roda o update com
`--update-failure-action pause`, e o trap recusa a volta e imprime o caminho. Toda saída
abaixo é escrita na produção e pede a palavra do dono.

O estado em que o serviço fica depende de onde o deploy falhou. A mensagem do deploy diz qual:

| Onde falhou | Estado do Swarm | O próximo deploy |
| --- | --- | --- |
| Antes do `docker service update` ("nada foi mandado ao Swarm") | o de antes do deploy | aceita |
| No update do Swarm (a tarefa nova não subiu em 90 s) | `paused`, ou ainda `updating`; a réplica pode estar 0/1 | recusa ("baseline backend nao e rollback-safe") |
| Sem saber se o update chegou ao Swarm (o ssh caiu ou o `docker service update` falhou) | desconhecido: confira com `docker service inspect` | depende do estado |
| Numa conferência depois do update (spec, readiness, origem no EasyPanel) | `completed`, com a imagem nova 1/1 | aceita |

O deploy só aceita um serviço com 1/1, a imagem da spec igual à da tarefa e o update vazio,
`completed` ou `rollback_completed`. Um `docker service update` novo começa outro update e
tira o serviço de `paused`, `rollback_paused` ou `updating`. Para sair desses estados antes
de um deploy de correção:

1. `docker service update --force <serviço>` refaz o update da mesma imagem nova. Serve
   quando a falha foi passageira. Se ele convergir (`completed`, 1/1), siga para o deploy
   de correção.
2. Se a imagem nova não sobe, `docker service update --image <imagem anterior> --env-add
   GIT_SHA=<GIT_SHA anterior> <serviço>` põe a imagem anterior pelo digest, com o GIT_SHA
   dela, que a guarda do deploy seguinte lê da spec. A mensagem do deploy imprime os dois.
   O comando é idempotente: rodar de novo não muda nada. O serviço pode voltar a 1/1,
   porque o healthcheck do container é o `/health/live`, que não olha o banco. Mas
   `/health/ready` segue em 503, porque essa imagem exige a migration de antes do lote. A
   API já estava fora; o comando só limpa o estado do Swarm.
   Não use `docker service rollback` aqui: todo update, o `--force` do passo 1 inclusive,
   grava a spec atual como a anterior, e o rollback depois dele volta para a imagem nova.
3. Com o serviço em 1/1 e `completed`, rode o deploy de uma imagem que exige a migration
   em que o banco está. A guarda decide de novo pela imagem que estiver no serviço: depois
   do passo 2, ela é a de antes do lote, e o deploy segue sem volta automática (`pause`).

Se a correção não sair a tempo do RTO, o caminho é o restore da seção anterior, com o
dump do passo 1 do lote, e o passo 7 dela.
