# Receipt: BT-PRIV-002, consumidores `hermes_learning_sqlite` e `backups` (2026-10-10)

- **Tarefa:** `BT-PRIV-002`, os dois consumidores que a crítica do plano do MVP de 2026-10-10
  apontou como abertos: `hermes_learning_sqlite` (código na imagem do ops) e `backups` (rotação de
  30 dias automatizada, D-84: 30 dias mais FileVault).
- **Executado por:** frente OPS-COORTE, worktree `~/.manaloom/coordenacao/wt/ops`, branch
  `feat/ops-cohort-matrix`, a partir do `origin/master` `eac4f401b`.
- **Limites:**
  - nada rodou na produção, no servidor ou no diretório real de backups;
  - nenhum dump foi apagado;
  - os testes usam diretórios descartáveis, em `~/.cache/manaloom-backup-cadence-test/`, porque a
    própria política recusa `/tmp`, e SQLite temporário.

## `hermes_learning_sqlite`: já estava feito no master

O expurgo por titular entrou na rodada 2 do servidor (2026-09-28), e esta frente só conferiu. Nada
mudou no código.

| Peça | Onde |
| --- | --- |
| Consumidor declarado | `server/lib/privacy/account_deletion_outbox.dart`, com `hermes_learning_sqlite` e `purgesByTombstoneSweep` |
| Varredura | `server/lib/privacy/hermes_learning_purge.dart`: acha no PostgreSQL, pelo HMAC dos tombstones, os decks apagados que o `knowledge.db` guarda |
| Auxiliar do SQLite | `server/bin/hermes_learning_purge.py`: `list` só lê e não cria o arquivo; `purge` apaga eventos e cópias de deck sob `BEGIN IMMEDIATE` e confere de novo sob o mesmo lock |
| Onde o SQLite mora no ops | `HERMES_KNOWLEDGE_DB=/data/manaloom-ops/knowledge.db`, no volume `evolution_manaloom-ops-data`. O daemon põe a variável em todo job (`_base_env`) |
| Job | `manaloom_account_deletion_outbox`, a cada 15 min, sem capability, sob `account_deletion_outbox_v1`, e fechado com política inválida |
| Na imagem | `server/Dockerfile.manaloom-ops` instala `python3` e copia `server/`; o deploy do ops leva `server` no `git archive` |

O que foi rodado nesta data:

| Prova | Resultado |
| --- | --- |
| `server/test/hermes_learning_purge_test.py`, em SQLite temporário | 7 verdes |
| `server/test/pull_learning_events_deletion_test.py` | verde |
| `server/test/hermes_learning_purge_test.dart` e `server/test/account_deletion_outbox_test.dart` | verdes, na trava (detalhe no relatório da frente) |

## `backups`: rotação de 30 dias automatizada

### O que mudou

| Arquivo | Mudança |
| --- | --- |
| `scripts/manaloom_backup_cadence.py` | Subcomando `rotate --backup-dir D [--apply] [--out O]`. Sem `--apply`, só lista. Com `--apply`, apaga só o padrão governado: arquivo comum, nunca link, na raiz do diretório, com o nome exato `manaloom-postgres-AAAAMMDDTHHMMSSZ.dump`, carimbo de mais de 30 dias e fora do `keep` (o mais novo e o mais novo com ensaio aprovado). Recusa diretório temporário e política sem prazo. O recibo (`--out`) sai com `chmod 600` |
| `scripts/manaloom_backup_cycle.sh` | Depois do receipt de cada backup novo, roda `rotate --apply` e grava `<dir>/rotations/<carimbo>.json`. Roda com a cadência cumprida ou não. Se o backup ou o ensaio falharem, o ciclo para antes e nada é apagado |
| `server/config/backup_policy.json` | Versão `2026-10-10.1`: a nota da D-84 descreve a rotação, e a seção `rotation` diz o comando, onde roda, o que apaga e onde fica o recibo |
| `docs/runbooks/BACKUP_E_RESTAURACAO.md` | A seção "Guarda de 30 dias" descreve a rotação automática e o aviso sobre o consumidor `backups` |
| `server/test/backup_cadence_test.py` | Classe nova `RotationTest` (4 testes) e 2 testes novos do ciclo |

Um dump parcial, menor que 1 KiB, também sai quando vence, porque pode ter dado de conta. O `check`
não o conta como backup.

### Provas

`server/test/backup_cadence_test.py`: 22 verdes. Os 16 de antes continuam verdes, com duas
asserções de texto ajustadas à rotação. Os 6 novos:

| Teste | O que prova |
| --- | --- |
| `test_dry_run_lists_and_deletes_nothing` | sem `--apply`, lista os vencidos e não apaga nada |
| `test_apply_deletes_only_governed_dumps_older_than_30_days` | Saem só o dump de 45 dias e o parcial de 40. Ficam: o ensaiado de 35 dias, o de 30 dias exatos, os recentes e tudo fora do padrão (sufixo `.bak`, `.sql`, outro prefixo, carimbo minúsculo, recibo, dump em subpasta, link com o nome do padrão e o alvo do link). A segunda rodada não apaga nada |
| `test_cli_requires_apply_to_delete_and_writes_the_receipt` | a CLI só apaga com `--apply` e grava o recibo com `0600` |
| `test_refuses_temporary_directory_and_policy_without_retention` | `/tmp` e política sem prazo saem como entrada inválida, sem apagar |
| `test_cycle_rotates_expired_governed_dumps_after_the_backup` | o ciclo `--execute --drill` apaga o vencido do padrão e deixa o recente e o `.bak` |
| `test_cycle_rotates_even_when_the_cadence_is_blocked` | o ciclo sem ensaio sai 3 e mesmo assim roda a guarda |

### Mutações

Cada mutação foi aplicada no worktree, os testes rodaram, e o arquivo voltou e foi conferido byte a
byte (`cmp`). As 9 falham como esperado.

| Mutação | Falha em |
| --- | --- |
| apagar fora do padrão (prefixo `manaloom-postgres-` sem o `.dump` exato) | `backup_cadence_test` |
| ignorar a idade | `backup_cadence_test` |
| ignorar o `keep` | `backup_cadence_test` |
| apagar o de 30 dias exatos | `backup_cadence_test` |
| seguir link | `backup_cadence_test` |
| o modo só de leitura apaga | `backup_cadence_test` |
| varrer subpastas | `backup_cadence_test` |
| o ciclo não roda a rotação | `backup_cadence_test` |
| o ciclo só roda a rotação com a cadência cumprida | `backup_cadence_test` |

## O que segue aberto

- **O consumidor `backups` do outbox continua `blocked_backup_rotation_not_applied`.** A D-84 manda
  fechá-lo pelo tempo (30 dias mais 1) quando a rotação estiver automatizada. Hoje a rotação roda a
  cada ciclo, mas o ciclo ainda não está agendado: cada execução lê a produção e pede a aprovação
  live. Mudar o consumidor é código do backend e pede deploy.
  - **Ressalva para essa decisão:** o `keep` guarda o dump mais novo com ensaio aprovado, mesmo
    vencido. Fechar pelo tempo só é verdade se houver ensaio aprovado a cada 7 dias (D-83).
- **Agendar o ciclo na máquina de operação** é configuração persistente e fica com o dono.
- **O roteiro do lote**, fora do repositório
  (`~/.manaloom/coordenacao/banco/ROTEIRO_LOTE_DEPLOY_BACKUP.md`), ainda manda mostrar
  `retention.expired` ao dono e apagar à mão. Com esta mudança, o ciclo apaga os vencidos sozinho.
  A coordenação precisa ajustar o roteiro.
