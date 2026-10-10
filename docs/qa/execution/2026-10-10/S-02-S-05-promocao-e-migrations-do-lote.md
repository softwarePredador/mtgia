# Receipt — S-02 e S-05: a promoção não volta o backend para trás do banco, e o passo de migrations do lote — 2026-10-10

- **Tarefas:** S-02 e S-05 do plano até o GO do MVP (frente "promoção", fora do digest de UI).
  Decisões: D-18 ("rollback treinado uma vez") e os itens 2, 11, 12 e 20 do pacote de decisões
  do dono de 2026-10-10. O item 12 diz: nunca voltar o backend para 41bab49c9 depois da 059;
  depois dela, rollback é restore.
- **Executado por:** agente local, frente `promo-guard`, no worktree
  `~/.manaloom/coordenacao/wt/promo`, branch `fix/release-promotion-schema-guard`, a partir do
  `origin/master` `1f525a1c1`.
- **Limites:**
  - nada tocou a produção: sem SSH, EasyPanel, deploy, `.env` nem banco live;
  - os bancos foram PostgreSQL 17 descartáveis em loopback (`LC_ALL=C`, `127.0.0.1`, sem
    socket), num diretório temporário do scratchpad da frente, parados e apagados no fim;
  - nenhum arquivo do digest de UI nem do bootstrap do pre-commit mudou;
  - também não mudaram `scripts/manaloom_deploy_backend_image.sh`, `server/bin/migrate.dart`,
    `server/database_setup.sql`, as migrations e `scripts/manaloom_deploy_ops_image.sh`.

## O problema

**S-02.** O `/health/ready` do backend exige que o `MAX(version)` de `schema_migrations` seja
exatamente a última migration que a imagem conhece. Isso está no SQL
`... = 'NNN' AS latest_migration_ready` e no `latest_migration` do check, em
`server/lib/health_readiness_support.dart`.

- O código de 41bab49c9, que é a produção, exige a 058 (conferido com o parser novo sobre
  `git show 41bab49c9:server/lib/health_readiness_support.dart`). O master exige a 076.
- O lote aplica as migrations antes da promoção (L-03 e depois L-06). A partir daí, a imagem
  antiga do backend responde 503 para sempre.
- Mesmo assim, a compensação da transação (`swarm_rollback`) voltava o backend para ela, e a
  volta passava como "provada": a sonda da promoção é o `/health`, não o `/health/ready`.

**S-05.** O passo de migrations do lote (L-03) não tinha roteiro. O caminho combinado é o
`with_new_server_pg.sh --write-approved` com o `migrate.dart`, em ordem numérica, com a 074 no
mesmo lote da 067 e da 069.

O porquê está na `BT-DB-007` (`docs/qa/execution/2026-09-28/BT-DB-007-gatilhos-de-conta-ativa.md`):

- a 067 (`deck_change_events`) e a 069 (`ai_generate_requests`) criam chave para `users` sem
  rodar o laço da trava de conta ativa da 038;
- num banco migrado, que é o caminho da produção, só a 074 reinstala os gatilhos;
- sem ela, linha nova poderia apontar para conta excluída;
- e o contrato somente leitura da 038 no deploy (`active_user_triggers`) recusaria o release.

## O que entrou

| Arquivo | Mudança |
| --- | --- |
| `scripts/manaloom_promote_release.py` | Ver "S-02 no módulo", abaixo |
| `scripts/manaloom_promote_release.sh` | Ver "S-02 no orquestrador", abaixo |
| `server/config/release_promotion.json` (`2026-10-10.1`) | `transaction.after_migration_rollback`, a guarda `schema_guard` no backend e a D-18 |
| `scripts/manaloom_lot_apply_migrations.sh` | O passo do lote (modos abaixo) |
| `scripts/manaloom_lot_migrations.py` | A lógica sem conexão: política, plano contra o código, ledger de antes e de depois, snapshot e receipt |
| `server/config/lot_migrations.json` (`2026-10-10.1`) | O lote: `from` 058, as 16 migrations de 059 a 069 e de 072 a 076 (a 070 e a 071 não existem) e o `same_lot` da 074 com a 067 e a 069, com o porquê |
| `server/test/release_promotion_test.py` | 49 testes, 10 novos |
| `server/test/lot_migrations_step_test.py` | 9 testes, 1 com banco |
| `server/test/new_server_pg_caller_mode_contract_test.py` | O script novo entra no inventário dos chamadores do wrapper, com os modos `--write-approved` (uso), `--read-only` (ledger) e `--write-approved` (migrate) |
| `scripts/manaloom_tbls_local_gate.sh` | O gate de schema roda o teste da S-05 com `RUN_SCHEMA_DB_TESTS=1` |
| `docs/project_logic_contracts.json` | O script, o módulo e o teste novos no fluxo `release_operations` |

### S-02 no módulo

`scripts/manaloom_promote_release.py` ganhou:

- `readiness_requirement`: lê a exigência de schema de uma imagem. O SQL e o check têm de
  concordar; senão, a exigência é desconhecida;
- `load_schema_snapshot`: valida o ledger do banco (`manaloom-schema-ledger`, no máximo
  30 minutos, versões em ordem, `latest` igual ao `MAX`);
- o subcomando `schema-guard`;
- a recusa em `compensation-decision`.

### S-02 no orquestrador

`scripts/manaloom_promote_release.sh` ganhou:

- `--schema-snapshot`, obrigatório no `--promote` quando o backend está na transação;
- a guarda no preflight, que vai para o resumo e para o `begin` do diário;
- a guarda passada à compensação;
- o `--help` com "Banco migrado: depois da 059, rollback é restore".

## Como a promoção decide (S-02)

**Preflight.** Com o backend na transação e o `--schema-snapshot`, ele lê três coisas:

- a exigência do candidato (o `health_readiness_support.dart` no SHA promovido);
- a exigência da imagem de base (o mesmo arquivo no `git_sha` que o `/health` da linha de
  base mostra);
- o `MAX(version)` do ledger.

**Bloqueia (código 3, nada muda)** quando:

- o ledger falta, está velho, vem do futuro ou está ilegível;
- o candidato exige outra migration que não a do banco. Esse é o caso do lote que não
  rodou: o backend novo daria 503.

**Volta do backend.** Ela é `allowed` só quando a imagem de base exige uma migration conhecida
e não menor que a do banco. Senão, é `refused`, e o preflight avisa no stderr. Exigência
desconhecida conta como recusa: SHA fora do repositório, ou SQL e check que discordam.

**Compensação.** Com a volta recusada, o backend não recebe nada: nem `docker service rollback`,
nem `updateSourceImage`. Isso vale mesmo que ele já esteja na imagem de base, porque essa base
não fica pronta com o banco à frente dela. As outras superfícies voltam como sempre.

A transação termina em `rollback_failed` (CRITICAL, `EM_ANDAMENTO` fica). A saída é corrigir
para frente ou restaurar o dump do L-01 (`docs/runbooks/BACKUP_E_RESTAURACAO.md`, seção
"Restauração da produção"), com a palavra do dono. Depois vem o `--resolve`.

**Depois da 059, rollback é restore.** Isso está:

- no `--help` e na descrição sem `--execute`;
- em `transaction.after_migration_rollback` e no `schema_guard` da política;
- neste receipt.

**Treino da D-18 (item 12).** A promoção com falha induzida dispara a compensação. Com o banco
e a base na mesma migration, o backend volta exato. Com o banco à frente da base, a ferramenta
recusa a volta e mostra o caminho do restore. O ensaio de restore em si é o do L-01.

## O passo do lote (S-05)

| Modo | O que faz |
| --- | --- |
| sem `--execute` | Descreve o lote e confere com o código deste SHA, sem conectar |
| `--execute --read-ledger --out L` | Lê o ledger pelo `with_new_server_pg.sh --read-only psql` e grava o snapshot que a promoção pede em `--schema-snapshot` (`chmod 600`, vale 30 minutos) |
| `--execute --apply --receipt-dir D` | Exige `MANALOOM_CONFIRM_LIVE_MUTATIONS` e `MANALOOM_CONFIRM_POSTGRES_WRITES` de quem chama, checkout limpo no `origin/master` e diretório durável. Aplica pelo `with_new_server_pg.sh --write-approved dart run bin/migrate.dart --target <última>`, a partir de `server/` |

**Antes de qualquer escrita, o passo recusa (código 3)** quando há:

- lacuna: migration do lote que não existe no `migrate.dart`, ou migration do código entre o
  `from` e a última do lote que não está no lote;
- lote que não termina na última do código;
- `same_lot` quebrado (sem a 074 com a 067 ou a 069);
- readiness deste SHA que exige outra migration que não a última do lote;
- ledger fora do `from`, com lacuna, com versão ou nome de outro código, ou o lote já aplicado.

**Depois de aplicar,** o ledger tem de ser o de antes mais o lote, nem mais nem menos. Senão, o
código é 1, e o receipt diz onde parou (cada migration é atômica).

**O que fica no diretório:**

- o receipt `lote-migrations-<sha>-<carimbo>.json`, com o ledger de antes e o de depois
  (versões, contagem e SHA-256), as aplicadas, a saída do migrate e os problemas;
- o `.log` do `migrate.dart`;
- o ledger de depois, já no formato do `--schema-snapshot`.

**Sequência no lote:**

1. L-01 e L-02 (backup e ensaio);
2. `scripts/manaloom_lot_apply_migrations.sh --execute --apply --receipt-dir D` (L-03);
3. `scripts/manaloom_promote_release.sh --execute --promote ... --schema-snapshot D/ledger-...json`
   (L-06), dentro dos 30 minutos; senão, um `--read-ledger` novo.

## Provas

**Testes**

- **`server/test/release_promotion_test.py`: 49 verdes, em cerca de 5 minutos.** Os 10 novos:
  - o `--help` diz que depois da 059 rollback é restore;
  - com a base na 058 e o banco na última, a falha do `/app` desfaz `/app`, site e ops, deixa
    o backend no candidato, sem nenhum comando para ele, e termina em `rollback_failed`. O
    `--resolve` depois registra o backend `committed`;
  - com o deploy do backend recusando antes de mudar, nada muda, e a falha fica CRITICAL;
  - a exigência ilegível (SHA fora do repositório ou readiness sem a exigência) recusa a volta;
  - o preflight bloqueia o candidato que exige a última com o banco na 058;
  - o `--promote` sem ledger sai com 2, e o ledger velho, do futuro, de outro tipo,
    incoerente ou ilegível bloqueia;
  - a lógica do `readiness_requirement`, do `schema_guard` e da compensação (a guarda só vale
    para o backend), e a política;
  - a constante do shell confere com a do módulo.
- **`server/test/lot_migrations_step_test.py`: 9 verdes** (8 sem banco, em menos de 1 s, e 1 com
  banco, que leva cerca de 12 s):
  - o lote versionado é o código da 058 à última;
  - as recusas de lacuna e de lote pelo módulo e pelo script;
  - a política inválida;
  - o ledger de antes (lacuna, versão de outro código, nome trocado, lote já aplicado, banco
    vazio) e o de depois (parou no meio, versão fora do lote);
  - o snapshot aceito pela promoção;
  - as recusas antes de qualquer conexão (aprovações, diretório temporário, modos).
- **Com banco:** um PostgreSQL 17 descartável monta a produção na 058 (o bootstrap de 41bab49c9
  do fixture e o `migrate.dart --target 058`, com linhas sintéticas). O script de verdade roda
  num repositório descartável no `origin/master`, com o `with_new_server_pg.sh` de verdade. O
  `ssh` é um túnel falso para o banco descartável, e tudo roda sob o sandbox do ensaio (rede só
  em localhost). O teste confere:
  1. o `--read-ledger` grava o ledger na 058;
  2. o checkout sujo é recusado sem conectar;
  3. o lote sem a 074 é recusado sem conectar, e o banco fica na 058;
  4. o ledger sem a 057 é recusado sem escrever;
  5. o lote chega à 076, com as 16 aplicadas em ordem, três túneis (ledger, migrate e ledger) e
     o receipt com antes 058 e depois 076;
  6. o ledger de depois, na guarda da promoção, recusa a volta para uma base na 058;
  7. a segunda aplicação é recusada como lote já aplicado.
- `server/test/new_server_pg_caller_mode_contract_test.py`: 5 verdes, com o chamador novo.
- `shellcheck`, `bash -n` e `scripts/manaloom_errexit_lint.py` limpos nos dois scripts.

**Mutações** (cada uma aplicada, testada, desfeita e conferida com `cmp`; todas derrubaram os
testes-alvo):

| Id | Mutação | Testes que caíram |
| --- | --- | --- |
| M1 | a compensação ignora a guarda | lógica da compensação, ferramenta com a base na 058 |
| M2 | a base menor que o banco não recusa | `schema_guard` |
| M3 | o candidato fora do banco não bloqueia | `schema_guard` e preflight |
| M4 | o `--promote` não exige o ledger | ledger obrigatório |
| M5 | a compensação não recebe a guarda | a falha que desfaz tudo (o backend deixa de voltar no caso compatível) |
| M6 | a base lida no SHA do candidato | ferramenta com a base na 058 |
| M7 | o ledger velho é aceito | `schema_guard` e ledger obrigatório |
| M8 | a política não valida a guarda | política |
| M9 | o readiness aceita SQL e check divergentes | `readiness_requirement` |
| M10 | a guarda BLOCKED não para o preflight | preflight e ledger obrigatório |
| N1 | sem a recusa de lacuna | plano e teste com banco |
| N2 | sem lacuna e sem `same_lot` | script e teste com banco (o lote sem a 074 passaria a escrever) |
| N3 | o script ignora o ledger de antes | teste com banco |
| N4 | o ledger de antes aceita lacuna | ledger de antes e teste com banco |
| N5 | o ledger de depois sempre passa | ledger de depois |
| N6 | o checkout sujo é aceito | teste com banco |
| N7 | sem o laço com o readiness | plano |

## O que fica aberto

- **Rodar na produção:** o passo do lote e a promoção, pelo roteiro da coordenação, com a
  palavra do dono.
- **O rollback próprio de `scripts/manaloom_deploy_backend_image.sh`** (`rollback_backend_deploy`)
  ainda volta a spec quando o deploy falha depois de mudar. Ele confere o readiness e acusa
  CRITICAL, mas não recusa antes. Esse arquivo é da frente do banco e não mudou aqui. A
  promoção já trata o resultado: com a volta recusada, a base não conta como restaurada.
- **A migration 077 (BT-CAT-01), da frente do banco:** quando entrar no `migrate.dart` e no
  readiness, o `server/config/lot_migrations.json` precisa listar a 077. Até lá, o plano e o
  teste com banco recusam, de propósito, o código com uma migration fora do lote.
- **Linhas do backlog** (`BT-REL-001`, `BT-DB-*`): não foram editadas aqui. A coordenação
  registra o avanço.
