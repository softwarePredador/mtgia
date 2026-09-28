# Receipt — BT-DR-001: cadência do backup local e ensaio de restauração isolado — 2026-09-28

- **Tarefa:** `BT-DR-001`, reescopada pela D-81 (2026-09-24): sem backup fora do servidor; a
  tarefa fica com o backup local e o ensaio de restauração isolado, com cadência e receipt.
  Objetivos da D-12: RPO de 24 h e RTO de 4 h.
- **Executado por:** Frente C (banco e operação), no worktree da frente, branch
  `banco/rodada1-2026-09-24`, sobre `2d1f2cc52`, com o código que entra no mesmo commit deste
  receipt.
- **Autorização e limites:** nada tocou a produção. Sem SSH, sem banco remoto, sem deploy. O
  backup real e o ensaio com o dump novo ficam para o lote de deploy, com a palavra do dono.
- **Docker:** o Docker Desktop estava fechado e não foi aberto. O ensaio real em container fica
  para o lote; aqui o script de ensaio rodou com um `docker` de teste (abaixo).

## O que entrou

| Arquivo | Papel |
| --- | --- |
| `server/config/backup_policy.json` | RPO e RTO da D-12 (conferidos contra o texto da decisão), destino `backups/manaloom-postgres/` sem cópia fora (D-81), ensaio sem rede, cadência (backup a cada 24 h no máximo; ensaio a cada 7 dias e antes de migration na produção, proposta) e o primeiro ciclo ligado ao receipt da `BT-REL-000` |
| `scripts/manaloom_backup_cycle.sh` | `--execute [--drill]`: roda o backup e o ensaio existentes, exige `MANALOOM_BACKUP_DIR` num diretório durável, grava o receipt em `receipts/` e sai 3 quando a cadência não fecha; sem `--execute` só descreve |
| `scripts/manaloom_backup_cadence.py` | `validate-policy`, `check` e `receipt`: idade do backup contra o RPO, idade e duração do último ensaio contra a cadência e o RTO, SHA-256 do dump ensaiado igual ao do arquivo; recusa `/tmp` e worktree |
| `docs/runbooks/BACKUP_E_RESTAURACAO.md` | cadência, o passo do lote de deploy com o que cada etapa confere, o receipt e a restauração da produção passo a passo |
| `docs/project_logic_contracts.json` | o fluxo `release_operations` lista as duas ferramentas e o teste |

## Provas

| Prova | Resultado |
| --- | --- |
| `server/test/backup_cadence_test.py` (política, cadência, ciclo com shims do backup e do ensaio, e o contrato com a interface dos scripts reais) | 15 verdes |
| `server/test/backup_cycle_db_live_test.py` (`RUN_SCHEMA_DB_TESTS=1`) | 1 verde |
| Mutações (`mutacoes_bt_dr_001_r2.json`, na cópia de trabalho da frente) | 18 de 18 derrubadas |
| Gates, na trava, das 12:39 às 12:49 UTC | `project_logic --write`, `--check` e `--test` verdes (41 testes do gerador); contrato de release `passed` (34 contratos, com os 15 testes da cadência); comparação de schema do gate tbls num banco novo: PASS (80 tabelas, 6 views, 100 chaves estrangeiras, 63 migrations). A suíte completa do servidor não rodou: nenhum arquivo Dart mudou |
| `shellcheck` e `bash -n` do ciclo | limpos |

**O teste de banco.** O ciclo roda de verdade (`--execute --drill`) contra o PostgreSQL 17
descartável da frente (63 migrations, última 065), com duas trocas:

- no lugar do backup da produção, um `pg_dump -Fc` do banco descartável, com a mesma saída de
  `scripts/manaloom_easypanel_backup.sh`;
- o script de ensaio é o real (`scripts/manaloom_full_restore_drill.sh`). O `docker` do teste
  sobe um PostgreSQL local, só em loopback e sem socket, no lugar do container, e recusa
  `docker run` sem `--network none`.

Numa execução (2026-09-28, 11:45 UTC): dump de 339.589 bytes; restauração em 2 s; 80
tabelas e 100 chaves estrangeiras, iguais às do banco de origem; as contagens de `users`,
`cards`, `decks` e `deck_cards` iguais às linhas semeadas; `SET CONSTRAINTS ALL IMMEDIATE`
aceito; `remote_writes: false`; o `docker rm -f` derrubou o PostgreSQL do ensaio; receipt com
cadência **PASS** e SHA-256 do dump ensaiado igual ao do arquivo.

**Mutações** (cada uma tem de derrubar um teste):

- D01 a D12: política com cópia fora, RPO, ensaio velho, RTO, dump trocado, ensaio com rede ou
  escrita remota, diretório temporário, ensaio sem `--drill`, conexão sem `--execute`,
  evidência fora do receipt, RPO e RTO sem conferir a decisão, receipt legível por todos;
- D13: `--execute` sem `MANALOOM_BACKUP_DIR`;
- D14 e D15: ensaio com rede e ensaio sem `remote_writes` (pegos pelo contrato e pelo teste de
  banco);
- D16: backup que informa o arquivo em outro formato;
- D17 e D18, que só o teste de banco pega: ensaio que restaura só o schema, e ensaio que conta
  chaves primárias como estrangeiras.

## Estado da cadência hoje

`python3 scripts/manaloom_backup_cadence.py check` no diretório real de backups (só metadados
dos arquivos, sem ler o conteúdo):

- **BLOCKED**;
- o último backup é `manaloom-postgres-20260923T005128Z.dump`, com 130,9 h;
- não há ensaio registrado no diretório: a evidência do ensaio da `BT-REL-000` ficou em `/tmp`.

O lote de deploy fecha a cadência com o primeiro ciclo.

## Para o lote de deploy

O roteiro da coordenação fica fora do repositório:

- `~/.manaloom/coordenacao/banco/lote_deploy_backup.sh`;
- `~/.manaloom/coordenacao/banco/ROTEIRO_LOTE_DEPLOY_BACKUP.md`, com o que cada passo confere.

Ele confere:

- o Docker de pé;
- o worktree de deploy limpo;
- a âncora SSH;
- o diretório durável e o espaço livre;
- a política.

Depois roda o ciclo com `--execute --drill` e compara tabelas, chaves e as quatro contagens com
a linha de base da `BT-REL-000`: queda sai com 4 e para o lote antes da migration.

## O que segue aberto

- O ciclo na produção, no lote de deploy (coordenação, com a palavra do dono e o Docker aberto).
- Com o dono (em `decisoes-pendentes.md`):
  - a cifra do backup local (recomendação: o FileVault, que está ligado, como cifra em repouso
    do MVP);
  - o prazo de rotação da D-23 (recomendação: 14 dias, guardando o dump mais novo com ensaio
    aprovado);
  - a cadência semanal do ensaio.
