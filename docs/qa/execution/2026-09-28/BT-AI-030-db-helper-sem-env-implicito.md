# Receipt — o `db_helper` do Hermes não carrega mais `.env` achado subindo diretórios — 2026-09-28

- **Origem:** achado da Frente A durante o `BT-AI-030`. A coordenação o pôs como prioridade da
  lista seguinte.
- **Dono no backlog:** a linha do `BT-AI-030`, em que o achado apareceu. O guarda também cobre o
  "nenhum apply" do `BT-AI-014`: as importações que escrevem no PostgreSQL por `run_sql`.
- **Frente A (servidor)**, branch `servidor/rodada2-2026-09-24`.
- Nada tocou a produção. Os testes rodaram sob a guarda de egress (`sandbox-exec`, só
  loopback), e o teste ao vivo usou o PostgreSQL 17 descartável da frente.

## O risco

`docs/hermes-analysis/manaloom-knowledge/scripts/db_helper.py` é a conexão de 24 scripts do
Hermes com o PostgreSQL. Entre eles estão os syncs do `master_optimizer_preflight`, os auditores
globais e os importadores.

- **O comportamento antigo.** Sem `DATABASE_URL` nem `DB_*` completos no ambiente, o helper
  procurava um `.env` subindo diretórios. Procurava a partir do diretório corrente e também do
  próprio script. O primeiro que achava ele carregava no `os.environ`.
- **Onde isso pega.** Rodando de um worktree, os diretórios acima do script levam ao checkout
  principal, e o `server/.env` dele pode apontar para o banco de produção.
- **Senha vazia contava como incompleta.** Por isso até um ambiente local com senha vazia caía
  na busca.
- **O `run_sql` escondia a falha.** Ele engolia a falha de configuração e devolvia `""`.

## O que mudou

- **Só configuração explícita.** Vale, nesta ordem:
  1. `DATABASE_URL` no ambiente;
  2. `DB_HOST`, `DB_NAME` e `DB_USER` (ou os `PG*`) no ambiente, com a senha opcional para
     banco local com `trust`;
  3. um arquivo nomeado em `MANALOOM_POSTGRES_ENV`. É o nome que o
     `master_optimizer_preflight.sh` e o `run_local_battle_replay_audit.sh` já usam. Nele o
     ambiente vence o arquivo, chave por chave, como antes.
- **Nenhum `.env` é procurado.** O helper também não escreve mais no `os.environ`.
- **Host fora do loopback exige a confirmação do projeto.**
  - O loopback é 127.0.0.0/8, `::1` ou `localhost`.
  - Para ler, basta `MANALOOM_CONFIRM_POSTGRES_READS=I_HAVE_EXPLICIT_APPROVAL`, ou a de
    escrita.
  - Para escrever por `run_sql`, só `MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL`.
  - A comparação é exata, como no `scripts/lib/manaloom_mutation_guard.sh`.
- **A checagem conta o que o libpq aplica por cima do host da URL.**
  - Conta `host` e `hostaddr` na consulta, `service` na consulta ou em `PGSERVICE`, e
    `PGHOSTADDR` do ambiente.
  - Também conta vários hosts na URL, URL sem host, socket (`/var/run/...`) e esquema que não é
    `postgres`/`postgresql`.
  - Nomes parecidos não passam, como `localhost.example.com`, `127.0.0.1.example.com` e
    `0.0.0.0`.
- **Falha fechada.** Sem configuração, sem a confirmação ou com o arquivo nomeado ausente, o
  helper levanta `DatabaseConfigError`. A mensagem diz o que definir e não mostra a URL, o host
  nem a senha.
- **`run_sql`:**
  - confere a configuração antes do `try`, então a falha sobe em vez de virar `""`;
  - só trata como leitura um `SELECT` sem `;` no meio;
  - `SELECT 1; DELETE ...` e `WITH ... DELETE` contam como escrita.
- **`connect()` e `sanitized_database_target()`** mantêm a assinatura. `connect(access=...)` é
  opcional.

## Os chamadores e a produção

A produção continua recebendo a URL como hoje.

- **Imagem de ops** (`server/Dockerfile.manaloom-ops`).
  - O `.dockerignore` já tira `.env` e `server/.env` da imagem, então a busca antiga nunca
    achava arquivo ali.
  - O banco vem do ambiente do serviço: `DB_HOST=evolution_manaloom-postgres`, `DB_PORT=5432` e
    `DB_NAME=halder`, conferidos pelo `scripts/manaloom_deploy_ops_image.sh`, mais o usuário e a
    senha.
  - O daemon passa esse ambiente aos jobs pelo `_base_env`. O `master_optimizer_preflight.sh`
    exporta os `PG*` a partir dos `DB_*`, e o helper os usa como antes.
- **O daemon de ops agora confirma a leitura.**
  - O `_base_env` põe `MANALOOM_CONFIRM_POSTGRES_READS=I_HAVE_EXPLICIT_APPROVAL`. O banco
    configurado no serviço é o dele.
  - Ele nunca confirma escrita.
  - A única escrita no PostgreSQL do preflight (`sync_battle_card_rules_pg.py --apply-pg`) já
    exige `MANALOOM_CONFIRM_POSTGRES_WRITES` pelo guarda do próprio script, e o daemon
    neutraliza `MANALOOM_BATTLE_RULES_APPLY_PG=0`.
  - Hoje nenhum job ligado na produção usa o helper. O preflight está desligado por
    capability. Sem a confirmação, ele quebraria quando fosse ligado.
- **Imagem da API** (`server/Dockerfile`). Só leva o binário compilado; nenhum script do Hermes.
- **Laboratório Hermes** (`server/Dockerfile.hermes-lab`).
  - Os jobs dele são os gates dos provedores e não usam o helper.
  - O `.env` do `$HERMES_HOME` guarda só as chaves do agente.
- **`server/bin/with_new_server_pg.sh`**, o caminho auditado do operador até a produção.
  - Ele expõe o banco num túnel SSH em `127.0.0.1:<porta efêmera>`. É loopback, e o helper não
    pede outra confirmação.
  - O wrapper tem as travas próprias: fingerprint do host, modo só leitura com
    `default_transaction_read_only` e as duas aprovações para escrita.
  - Loopback não quer dizer banco descartável: o túnel é o jeito explícito de chegar à
    produção.
- **Execução à mão com o `server/.env` do repositório**, o do `master_optimizer_preflight.sh` e o
  do `run_local_battle_replay_audit.sh`. Se o arquivo apontar para fora do loopback, os scripts
  do Hermes agora recusam sem a confirmação de leitura. O README dos scripts diz isso.
- **Gates locais** (`manaloom_battle_product_gate.sh`, tbls, QA visual isolado). Usam
  `DB_HOST=127.0.0.1` e seguem iguais.

## Evidência

- **Unidade:** `test_db_helper.py`, 14 testes. Antes era 1.
  - não carrega `.env` subindo a partir do diretório corrente, nem a partir do próprio script;
    o arquivo aponta para loopback, e se fosse carregado seria aceito;
  - o arquivo só vale quando nomeado; nomeado e ausente, falha fechado;
  - com partes remotas no arquivo, ainda pede a confirmação;
  - loopback não pede confirmação; partes sem senha funcionam em loopback;
  - host remoto exige a confirmação exata, e leitura não autoriza escrita;
  - nomes parecidos não passam por loopback;
  - as sobreposições do libpq não disfarçam o host remoto, nem as da URL nem as do ambiente;
  - `run_sql` exige a confirmação de escrita para escrever num host remoto, e sem configuração
    levanta erro em vez de devolver `""`.
- **Contra PostgreSQL:** `test_db_helper_pg_live.py`, 2/2, contra o PostgreSQL descartável.
  - Em loopback, `run_sql`, `connect()` e `sanitized_database_target()` funcionam.
  - Com um alvo remoto e sem confirmação, os três recusam antes de abrir conexão (o
    `psycopg2.connect` real, espiado, não é chamado), sem a senha nem o host na mensagem.
- **Daemon de ops:** `server/test/manaloom_ops_daemon_test.py`, 27/27, com 2 testes novos.
  - O ambiente dos jobs confirma a leitura e nunca a escrita.
  - Com o ambiente do serviço de produção (host `evolution_manaloom-postgres`), o helper recusa
    sem o daemon. Com o ambiente do daemon, lê e dá `evolution_manaloom-postgres:5432/halder`,
    e continua recusando escrita.
- **Regressão dos chamadores.** Os 16 arquivos de teste do Hermes que importam um usuário do
  helper passam: 15 em `unittest` e o `test_battle_package_end_to_end_validation.py`, 175 testes
  em `pytest`. Os contratos Python do servidor ligados a ele também passam:
  - `new_server_pg_caller_mode_contract_test.py`;
  - `master_optimizer_preflight_artifact_contract_test.py`;
  - `operational_boundary_auditors_test.py`;
  - `manaloom_knowledge_import_test.py`;
  - `hermes_learning_purge_test.py`;
  - `pull_learning_events_deletion_test.py`.

## Mutações

Cada mutação foi aplicada no worktree. Rodaram então `test_db_helper.py` e o teste do daemon de
ops, sob a guarda de egress, e por fim o arquivo foi restaurado e conferido byte a byte. As 9
falham como esperado.

| Mutação | O que muda | Falha em |
| --- | --- | --- |
| M153 | volta a buscar `.env` subindo diretórios | helper: as duas buscas (2) |
| M154 | host fora do loopback sem confirmação | helper (21) e daemon (1) |
| M155 | `localhost.algo` e `127.0.0.1.algo` passam por loopback | helper: nomes parecidos (2) |
| M156 | `host` e `hostaddr` da consulta são ignorados | helper: sobreposições do libpq (2) |
| M157 | `PGHOSTADDR` do ambiente é ignorado | helper: ambiente (1) |
| M158 | a confirmação de leitura autoriza escrita | helper (5) e daemon (1) |
| M159 | a recusa mostra a URL | helper (12) |
| M160 | `SELECT` seguido de escrita passa como leitura | helper: `run_sql` (2) |
| M161 | o daemon de ops não confirma a leitura | daemon (2) |

## Fica para a coordenação

- **Os testes novos entram no gate na tarefa seguinte da lista** (testes Python no
  `scripts/manaloom_local_ci.sh`).
  - O teste do daemon de ops já roda no gate de Battle (`manaloom_battle_product_gate.sh`, modo
    `release`).
  - O `test_db_helper.py` e o teste ao vivo ainda não rodam em gate nenhum.
- **Scripts que escrevem no PostgreSQL por `connect()` sem guarda próprio** (por exemplo o
  `global_commander_fixture_cleanup_audit.py`) passam a exigir a confirmação para host remoto.
  Mesmo assim, a confirmação de leitura basta para eles. Um guarda de escrita por script fica
  para o `BT-AI-014`.
