# Grupo P0 CORE — Capacidade, disaster recovery e identidade de release

Medição estática contra o código em `d15beb05b` mais a árvore de trabalho de
2026-09-22. Nada foi executado: nenhum teste, build, deploy, SSH ou consulta
a PostgreSQL. Toda afirmação sobre código leva `arquivo:linha`.

> **Revisado por verificação adversarial em 2026-09-22** (seção final). Onde
> a revisão mudou um estado, uma contagem ou uma linha citada, o texto abaixo
> já está corrigido. A seção final lista o que caiu, o que subiu e por quê.

Convenções usadas nas tabelas:

- **PP** = PRONTO_E_PROVADO; **PSP** = PRONTO_SEM_PROVA; **PARC** = PARCIAL;
  **NE** = NAO_ENCONTRADO.
- **Teste estático** = teste que só procura texto no script (`grep -Fq`,
  `contains`, ordem de índices) sem executá-lo. Ele confirma que a linha
  existe, não que o comportamento funciona. Por isso não conta como prova.
- **Teste de caminho feliz** = teste que executa o código, mas só no caminho
  que aceita. Não prova a guarda que recusa.
- Caminhos de scripts são relativos ao repositório (`scripts/…`, `server/…`).
- "Arquivos a tocar" inclui, para cada tarefa, a ficha em
  `docs/execution/tasks/<ID>.md` (o gerador a exige para a tarefa ocupar o
  NOW: `tools/project_logic/lib/project_logic_generator.dart:1620-1662`) e o
  receipt em `docs/qa/execution/`. Nenhuma das seis tem um nem outro hoje.

## Tabela-resumo do grupo

| ID | Estado declarado | Estado medido | Asserções PP / PSP / PARC / NE | Arquivos a tocar | Testes a escrever | Migração | Prova viva | O que trava de verdade |
| --- | --- | --- | --- | ---: | ---: | --- | --- | --- |
| `BT-CAP-001` | TODO | **não começada** | 0 / 0 / 1 / 7 | 8 | 5 | não | sim (medição no host) | Autorização para ler o host e o PG de produção. O slot WIP-1 está com `BT-SCP-001` |
| `BT-CAP-002` | BLOCKED_BY_P0 | **mal começada** | 0 / 2 / 3 / 4 | 13 | 8 | não | sim (limites e treino de rollback) | Números de `BT-CAP-001`, autorização de deploy e o branch candidato fora de `master` |
| `BT-DR-001` | TODO | **metade do código; nada executado** | 0 / 5 / 4 / 4 | 10 | 7 | não | sim (dump, upload, download e restore) | Bucket S3 com versionamento, custódia da chave age, decisão LGPD e autorização |
| `BT-REL-001` | BLOCKED_BY_P0 | **mal começada** | 0 / 1 / 4 / 4 | 13 | 9 | sim: aplicar ao vivo a 058 (rollback `manualOnly`) | sim | Gates que se contradizem, produção em 057, branch candidato 29 commits à frente de `origin/master` e as dependências declaradas |
| `BT-REL-002` | BLOCKED_BY_P0 | **mal começada** (era "metade") | 2 / 3 / 6 / 3 | 14 | 9 | não | sim (leitura das superfícies em produção) | O gate same-SHA não existe; o app não compara nada; decisão de compatibilidade quando o digest diverge |
| `BT-REL-003` | BLOCKED_BY_P0 | **mal começada** | 0 / 1 / 2 / 3 | 9 | 5 | não | sim (receipt local da matriz) | Gates vermelhos (npm audit, prova de UI), branch fora de `master` e 28 dependências transitivas abertas |

Somando o grupo: **67 arquivos a tocar (55 de código e teste, 12 de
governança: ficha e receipt de cada tarefa), 43 testes novos, 6 de 6 tarefas
com prova viva ou receipt obrigatório e 1 migração live** (aplicar a 058, que
já existe em `server/bin/migrate.dart:3865` e cuja política de rollback é
`manualOnly`, `:4100`, ou seja: desfazer só por restore). Nenhuma das seis
tarefas tem receipt em `docs/qa/execution/`.

## Achados que valem para o grupo todo

1. **Nenhum deploy, rollback, backup off-site ou restore foi executado desde
   que estes contratos existem.** A última observação registrada de produção
   foi `a6ee09c8f`, de 2026-08-03, com `SERVER_BEHIND`, `/capabilities` em 404
   e readiness em `057` (`docs/execution/CURRENT_QUEUE.md:100-103`). Esse SHA
   está 10 commits atrás da ref local `origin/master` e 39 atrás de `HEAD`. O
   dump mais recente fora do servidor também é de 2026-08-03: é o mais novo em
   `backups/manaloom-postgres/`, pasta ignorada pelo git (`.gitignore:23`), e
   tem 50 dias.
2. **O candidato não está em `master`, e todo deploy exige que esteja.**
   - `HEAD` (`d15beb05b`, branch `codex/free-beta-release-candidate-2026-07-17`)
     está 29 commits à frente da ref local `origin/master` (`704c2c11c`, de
     2026-08-12). Essa ref foi atualizada por push naquela data; o fetch de
     2026-09-21 trouxe só o branch candidato (`.git/FETCH_HEAD`). O estado
     remoto de `master` só se confirma com um `git fetch`.
   - `b2d3fc04f` (matriz all-OFF) e `fd0397a5a` (gates da beta) não estão em
     `origin/master`. Lá não existem `server/config/release_capabilities.json`
     nem `scripts/lib/manaloom_release_capabilities_contract.sh`.
   - Todo deploy e todo build de release exige source == `HEAD` ==
     `origin/master` (`scripts/manaloom_release_identity.sh:46-54`; backend
     `scripts/manaloom_deploy_backend_image.sh:1205-1208`; ops
     `scripts/manaloom_deploy_ops_image.sh:209-212`).
   - Promover o branch é um push que dispara o hook `pre-push`, que roda
     `local_ci full` (`.githooks/pre-push:13`; `AGENTS.md:25-27`). Esse gate
     está vermelho hoje (npm audit, `BT-WEB-003`) e depende de `BT-UIEV-001`.
     A alternativa é um bypass autorizado pelo dono, como o registrado em
     `docs/qa/execution/2026-09-21/btscp001-gate-amplo.md:3`.
   - Isso é dependência não declarada de `BT-CAP-002` (treino live),
     `BT-REL-001`, `BT-REL-002` (parte viva) e `BT-REL-003`.
3. **Quase todo teste do grupo é estático.**
   `server/test/deploy_rollback_convergence_contract_test.dart:15-164`,
   `server/test/ops_sidecar_digest_release_contract_test.dart` (nenhum
   `Process.run`) e a maior parte de
   `scripts/manaloom_release_ops_contract_test.sh` só procuram strings.
   Estes executam código de verdade:
   - identidade de release: `scripts/manaloom_release_ops_contract_test.sh:361-396`
     (só o caminho feliz);
   - parser de RepoDigest com MOTD: `scripts/manaloom_release_ops_contract_test.sh:98-118`;
   - contrato de capabilities: `scripts/manaloom_release_capabilities_contract_test.sh:25-125`;
   - rota `/capabilities`: `server/test/release_capability_policy_test.dart:159-183`;
   - `/health` do ops: `server/test/manaloom_ops_daemon_test.py:274-311`, que
     não verifica `git_sha` nem `policy_digest_sha256`;
   - no app, o AND servidor×artefato:
     `app/test/core/config/release_capabilities_test.dart:198-218,445-460`
     (só scanner e checkout);
   - dry-run e recusas de backup e restore:
     `scripts/manaloom_release_ops_contract_test.sh:293-353`.
4. **Contradição estrutural nos gates de capability.**
   - O loader canônico recusa qualquer policy que não tenha as 29 capabilities
     `off` com `allowed=false`
     (`scripts/lib/manaloom_release_capabilities_contract.sh:104-117`).
   - O gate do `/app` exige ao menos uma capability `on` com verificação live
     datada (`:171-189`).
   - O deploy do Flutter Web chama os dois em sequência
     (`scripts/manaloom_deploy_flutter_web.sh:38-41`). Esse deploy é
     inalcançável desde `fd0397a5a` (2026-08-24). O contrato fixa essa metade
     de propósito: `scripts/manaloom_release_capabilities_contract_test.sh:64-69`
     falha se o `/app` abrir com a matriz all-OFF.
   - Isso contradiz `docs/status/CURRENT_PRODUCT_DECISION.md:23` (decisão de
     2026-08-25), que diz que o `/app` serve o plano de controle de conta
     mesmo com a matriz toda OFF.
   - Para promover um release com capability ON: o loader (que toda
     superfície chama via `manaloom_release_identity.sh:78`) e a asserção
     Python do ops (`scripts/manaloom_deploy_ops_image.sh:366`, exige as 29
     OFF) recusam qualquer ON. O readiness do backend recusa ON só em
     `battle_batch`, `battle_live`, `battle_coach` e
     `ai_analyze_optimize_advisory`
     (`scripts/manaloom_deploy_backend_image.sh:1746-1750`). **Abrir
     catálogo ou decks exige mudar 2 gates; abrir Analyze/Optimize, 3**
     (a medição anterior dizia "pelo menos quatro"). Some-se a isso os testes
     que fixam all-OFF (`scripts/manaloom_release_capabilities_contract_test.sh:45-46,109`).
5. **Quase todo rollback restaura só a imagem: 5 de 6 caminhos.**
   - ops (`scripts/manaloom_deploy_ops_image.sh:152-163`), web público
     (`scripts/manaloom_deploy_public_web.sh:110-121`), app Web
     (`scripts/manaloom_deploy_flutter_web.sh:182-271`), release host Android
     (`scripts/manaloom_publish_android_release.sh:378-467`) e sidecars
     (`scripts/manaloom_deploy_battle_sidecars.sh:1099-1157`) restauram
     origem e/ou `--image`. Só o backend usa `docker service update
     --rollback` (spec inteira, `:1104`).
   - O env, os resources, a config de deploy do EasyPanel (`updateDeploy` no
     app Web `:577`, no release host `:628` e nos sidecars `:971-974`) e os
     arquivos do Traefik (app Web `:580-611`, release host `:631-633`)
     continuam os do candidato.
   - No ops, o `/health` lê `git_sha` do env
     (`server/bin/manaloom_ops_daemon.py:420`), e nenhum Dockerfile grava a
     revisão na imagem (`server/Dockerfile`, `server/Dockerfile.manaloom-ops`,
     `web-public/Dockerfile`). Depois de um rollback, o ops informa o SHA novo
     rodando a imagem antiga. A verificação do rollback compara só `status`,
     `engine_contract` e `configuration_status`
     (`scripts/manaloom_deploy_ops_image.sh:172-178`), então não percebe a
     identidade mista.
   - Nuance a favor: quando o próprio Swarm reverte
     (`--update-failure-action rollback`), a spec inteira volta. O env do
     candidato só fica quando a tarefa sobe e a verificação do script falha,
     que é o caso mais provável.
6. **Não existe número de capacidade em lugar nenhum.** O único documento é
   `server/doc/CAPACITY_PLAN_10K_MAU.md:1-42`, de 2026-02-27 (`853ababcd`).
   Ele cita `server/bin/load_test_core_flow.dart` (`:25,31`), que foi apagado
   em `8cab6400b`. Nenhum script lê memória, swap, CPU, disco ou os
   `Resources` dos serviços (buscas por `/proc/meminfo`, `MemAvailable`,
   `docker stats`, `loadavg`, `nproc`, `swapon`, `TaskTemplate.Resources` em
   `scripts/`, `server/bin/`, `tools/` e `services/` não retornam nada).
7. **Falha sem receipt.**
   - Os deploys imprimem JSON só em caso de sucesso: backend
     (`scripts/manaloom_deploy_backend_image.sh:1795-1819`), ops (`:436-439`),
     web público (`:480-482`) e app Web (`:683-710`). Mesmo o JSON de sucesso
     vai só para stdout.
   - Nas falhas, só aparece stderr ou `CRITICAL`.
   - O gate local apaga o próprio diretório de execução
     (`scripts/manaloom_local_ci.sh:68-75`), onde ficam as saídas das
     auditorias (`:161-183`).
   - Nenhuma falha deixa rastro durável.
8. **Há mutações antes de o rollback ser armado.**
   - No backend, a chave ops é instalada com `docker service update --env-add`
     (`scripts/manaloom_deploy_backend_image.sh:1218-1236`) e a tag mutável
     `:latest` é publicada (`:1290`). As duas coisas acontecem antes de
     capturar a baseline e de `DEPLOY_MUTATION_STARTED=1` (`:1395`).
   - O mesmo push de `:latest` ocorre antes do marco em ops (`:287`), web
     público (`:315`), app Web (`:503`) e release host Android
     (`scripts/manaloom_publish_android_release.sh:557`, antes de `:614`).
9. **Governança.**
   - O repositório trata como live até a leitura via SSH. O backup exige
     `require_live_mutation_approval`
     (`scripts/manaloom_easypanel_backup.sh:7`), e o contrato falha se o
     backup aceitar "leitura live sem acknowledgement"
     (`scripts/manaloom_release_ops_contract_test.sh:340-346`). A medição de
     `BT-CAP-001` e o dump de `BT-DR-001` dependem de autorização explícita do
     dono, uma por ação.
   - O gerador impõe que as dependências da tarefa no NOW estejam em `PASS`
     (`tools/project_logic/lib/project_logic_generator.dart:1692-1711`), e
     `local_ci quick` roda esse `--check`. Começar a parte local de
     `BT-CAP-002` ou de `BT-REL-002` antes das dependências exige exceção de
     contenção `IN_PROGRESS_CONTAINED` autorizada ou redeclarar a
     dependência no backlog. "Pode andar já" vale para o código, não para a
     governança.
10. **Há padrões reaproveitáveis que baixam o custo** (a favor):
    - hash de env com restauração verificada (sidecars
      `scripts/manaloom_deploy_battle_sidecars.sh:1230-1297`);
    - rótulo OCI `org.opencontainers.image.revision` gravado no build (sidecars
      `:863,870`) e conferido no deploy (backend
      `scripts/manaloom_deploy_backend_image.sh:387,403`);
    - SQL do ledger 038–058 (`server/lib/health_readiness_support.dart:137-173`);
    - receipt v2 com raiz durável fora de `/tmp`
      (`scripts/manaloom_deck_ai_learning_release_receipt.sh:12,51-53`);
    - pin da chave SSH do host
      (`scripts/lib/manaloom_release_runtime_contract.sh:155-162`);
    - leitura do registry com checagem de dependências
      (`tools/project_logic/lib/project_logic_generator.dart:1692-1711`).

---

## BT-CAP-001 — Medir host e criar política de capacidade atual versionada

- **Estado declarado:** TODO. **Estado medido:** não começada.
- **Aceite** (backlog, linha 606): "Memória/CPU/swap/DB/resources por
  serviço; sem reutilizar números de worktree temporário". O fechamento da
  onda (`docs/execution/waves/01-platform-safety.md:13`) acrescenta
  "thresholds versionados e preflight reproduzível".

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Memória do host (total e disponível) medida, com procedência | NE | nada: não há `/proc/meminfo`, `free -`, `MemAvailable` nem `docker stats` em `scripts/`, `server/bin/`, `tools/` ou `services/` | nenhum | Script read-only de snapshot via SSH verificado |
| 2 | CPU e load do host medidos | NE | nada | nenhum | Idem |
| 3 | Swap medido | NE | nada | nenhum | Idem |
| 4 | PostgreSQL medido: tamanho, maiores relações, `max_connections`, `shared_buffers`, conexões ativas, pool | PARC | `pg_database_size` só em cópia restaurada (`scripts/manaloom_full_restore_drill.sh:181-182`, `scripts/manaloom_install_remote_backup_cron.sh:239`); pool configurável em `server/lib/database.dart:148-156` (padrão 10, `server/.env.example:26`); os números de banco do MAPA vêm de um backup local de 2026-08-03 (`docs/MAPA_OPERACIONAL_DO_PROJETO.md:457-458,486-487`). O wrapper read-only já existe (`server/bin/with_new_server_pg.sh:19-25`) e o deploy do backend já o usa em produção (`scripts/manaloom_deploy_backend_image.sh:1179`) | nenhum | Medir o PG vivo em modo read-only |
| 5 | Resources atuais de cada serviço (backend, ops, web público, app Web, postgres, release host, sidecars) | NE | nenhum script lê `.Spec.TaskTemplate.Resources`. Os únicos números são defaults de configuração dos sidecars (`scripts/manaloom_deploy_battle_sidecars.sh:104-105,966-969,1037-1040`), não medições. Resources podem estar configurados no EasyPanel, fora do repositório; nada aqui permite saber | nenhum | Inventário por serviço |
| 6 | Política versionada com thresholds e headroom | NE | só `server/doc/CAPACITY_PLAN_10K_MAU.md:1-42`, que traz suposições de MAU e nenhum número de host, e cita um script de carga apagado (`:25,31`) | nenhum | Arquivo de política versionado e marcar o plano de 2026-02 como histórico |
| 7 | Procedência que impeça "números de worktree temporário": host fingerprint, `measured_at`, SHA | NE | nenhum validador. O pin da chave SSH do host (`scripts/lib/manaloom_release_runtime_contract.sh:155-162`) serve de âncora de procedência, mas nenhuma medição o usa | nenhum | Validador que recuse medição sem procedência de host de produção |
| 8 | Preflight reproduzível (critério da onda 01) | NE | nada (compartilhado com `BT-CAP-002` e `BT-GATE-006`) | nenhum | Função de preflight que leia a política |

**O que realmente falta.** Não existe nenhuma medição. É preciso construir:

1. `scripts/manaloom_capacity_snapshot.sh` (novo, somente leitura): usa
   `initialize_manaloom_secure_ssh` (com o pin da chave do host como
   procedência) e `with_new_server_pg.sh --read-only`. Coleta do host
   memória, swap, CPU, load e disco, mais `docker stats --no-stream` e
   `Resources` de cada serviço do projeto `evolution`. Do PG, coleta tamanho,
   maiores relações, `max_connections`, `shared_buffers` e conexões ativas.
2. `server/config/capacity_policy.json` (novo): medições, procedência,
   thresholds, headroom e limits/reservations por serviço.
3. `scripts/lib/manaloom_capacity_policy.sh` (novo): validador de
   procedência e função de preflight, que `BT-CAP-002` e `BT-GATE-006` vão
   reusar.
4. Um teste de contrato novo com fixtures e a ligação dele no gate
   (`scripts/manaloom_local_ci.sh` ou `scripts/manaloom_release_ops_contract_test.sh`).
5. `server/doc/CAPACITY_PLAN_10K_MAU.md` marcado como histórico.
6. Ficha e receipt da medição.

Custo: **8 arquivos (6 de código e teste, mais ficha e receipt), 5 testes,
1 captura viva autorizada.** Os 5 testes: sem procedência → recusa; host ou
caminho de worktree/`/tmp` → recusa; schema inválido → recusa; preflight com
folga insuficiente → `BLOCKED`; snapshot com shims de `ssh`/`docker` produz o
JSON esperado sem chamar nenhum comando de mutação.

A dependência declarada, `BT-GOV-001`, já está em `PASS`. O que trava hoje é
o slot WIP-1 e a autorização de leitura live. Esta política também precisa
contabilizar o restore semanal que o cron faz no próprio host de produção
(`scripts/manaloom_install_remote_backup_cron.sh:20,207`) e o `pg_dump` que o
backup roda dentro do container de produção
(`scripts/manaloom_easypanel_backup.sh:42-44`).

---

## BT-CAP-002 — Aplicar e provar reservations/limits e rollback exato de resources

- **Estado declarado:** BLOCKED_BY_P0. **Estado medido:** mal começada.
- **Aceite** (linha 607): "Preflight antes de mutação; rollback restaura
  image/env/resources/deploy".

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Reservations e limits aplicados aos serviços do core | NE | nenhum `--limit-*`, `--reserve-*` ou `updateResources` em `scripts/manaloom_deploy_backend_image.sh:1417-1455`, `scripts/manaloom_deploy_ops_image.sh:326-354`, `scripts/manaloom_deploy_public_web.sh:346-357`, `scripts/manaloom_deploy_flutter_web.sh:564-578` e `scripts/manaloom_publish_android_release.sh:615-629`. PostgreSQL não tem script de deploy | nenhum | Aplicar a política de `BT-CAP-001` em cada deploy |
| 2 | Limites nos sidecars de Battle | PARC | EasyPanel `updateResources` (cpuLimit 2, cpuReservation 0.25, memoryLimit, memoryReservation 512) em `scripts/manaloom_deploy_battle_sidecars.sh:966-969`, e `--limit/--reserve` só na criação do XMage interativo (`:1037-1040`). O script inteiro é recusado enquanto `battle_*` estiver OFF (`:48-55`). Os números não vêm de medição | nenhum (buscas por `updateResources` e `limit-memory` nos testes não retornam nada) | Números medidos e teste |
| 3 | Preflight de segurança de rollback antes da primeira mutação: baseline 1/1, spec igual à tarefa, digest imutável | PSP | backend `:1328-1350`, antes de `DEPLOY_MUTATION_STARTED=1` (`:1395`); ops `:237-268`, antes de `:322`; web público `:271-295`, antes de `:343`; app Web `:543-561`, antes de `:563`; release host `:593-612`, antes de `:614` | estático: `server/test/deploy_rollback_convergence_contract_test.dart:37-66` só compara a posição do texto. Só o parser de RepoDigest tem teste que executa (`scripts/manaloom_release_ops_contract_test.sh:98-118`) | Teste comportamental com shims de docker, ssh e curl |
| 4 | Preflight de capacidade antes da mutação: RAM, disco e swap livres ≥ reservations + build | NE | nada | nenhum | Função de preflight que leia a política |
| 5 | Nenhuma mutação antes de o preflight terminar | PARC | backend grava `MANALOOM_OPS_API_KEY` via `docker service update` (`:1218-1236`) e publica `:latest` (`:1290`) antes da baseline. Ops (`:287`), web público (`:315`), app Web (`:503`) e release host (`manaloom_publish_android_release.sh:557`) também publicam `:latest` antes do marco | nenhum | Mover as duas ações para depois do preflight |
| 6 | Rollback restaura a imagem | PSP | backend `:1068-1158` (`--rollback` em `:1104`); ops `:143-194`; web público `:92-173`; app Web `:182-271`; release host `:378-467`; sidecars `:1099-1157` | estático: `deploy_rollback_convergence_contract_test.dart:97-164` e `ops_sidecar_digest_release_contract_test.dart:61-79,265-300` só usam `contains` | Execução real (shim local e treino live) |
| 7 | Rollback restaura o env | PARC | backend usa `docker service update --rollback` (spec anterior inteira), mas só verifica imagem, origem e readiness (`:1093-1113,1127-1149`). Env exato só é verificado para o backend dentro do deploy de sidecars (`scripts/manaloom_deploy_battle_sidecars.sh:1230-1297`, sha256 em `:1247-1268`), e esse padrão é reaproveitável. Ops, web público e sidecars restauram só origem/`--image` e ficam com o `GIT_SHA`/`DEPLOY_TIMESTAMP` do candidato (ops `:335-336`, web público `:355-356`) e com o `updateEnv` dos sidecars (`:961-964`). App Web e release host não mudam env pelo deploy. No ops isso gera identidade mista não detectada (`server/bin/manaloom_ops_daemon.py:420` e `scripts/manaloom_deploy_ops_image.sh:172-178`) | nenhum | Capturar o hash do env antes, restaurar e verificar depois |
| 8 | Rollback restaura resources | NE | os sidecars alteram resources (`:966-969`) e `rollback_one_sidecar` nem captura nem restaura. Nenhum script lê `Resources` antes da mutação | nenhum | Capturar, restaurar e verificar |
| 9 | Rollback restaura a config de deploy (EasyPanel e roteamento) | NE | `updateDeploy` no app Web (`:577`), no release host (`:628`) e nos sidecars (`:971-974`) não é revertido. Os arquivos do Traefik escritos pelo app Web (`:580-611`) e pelo release host (`:631-633`) não são restaurados nos rollbacks (`:182-271` e `:378-467`) | nenhum | Salvar o estado anterior e restaurar |

**O que realmente falta.** Resources só existem nos sidecars de Battle, que
estão bloqueados enquanto Battle está OFF. Nos serviços que a beta usa, nenhum
limit ou reservation é aplicado. O rollback reverte só a imagem em cinco dos
seis caminhos. Faltam cinco coisas:

1. Uma biblioteca comum, por exemplo `scripts/lib/manaloom_service_spec_snapshot.sh`,
   que capture antes da primeira mutação imagem, hash do env, `Resources`,
   `UpdateConfig`, config EasyPanel e o arquivo do Traefik, e que restaure e
   verifique tudo isso no rollback. O hash de env dos sidecars
   (`:1230-1297`) é o ponto de partida.
2. Aplicar os limits e reservations da política aos cinco scripts de deploy
   do core (backend, ops, web público, app Web e release host), criar o
   procedimento de resources do PostgreSQL (não há script) e corrigir
   `rollback_one_sidecar`, que é o único lugar que hoje muda resources.
3. O preflight de capacidade, com o bootstrap da chave ops e o `:latest`
   movidos para depois dele.
4. Testes comportamentais com shims de `docker`, `ssh` e `curl`.
5. Um treino live autorizado com receipt.

Custo: **13 arquivos (11 de código e teste, mais ficha e receipt), 8 testes.**
Arquivos: a biblioteca nova; os cinco deploys do core; o deploy dos sidecars;
o procedimento de resources do PostgreSQL; o teste comportamental novo com
seus shims; e os dois testes estáticos que quebram quando a ordem do script
mudar (`server/test/deploy_rollback_convergence_contract_test.dart:37-66` e
`server/test/ops_sidecar_digest_release_contract_test.dart`). Testes: um
rollback por superfície com restauração verificada de imagem, env, resources
e deploy (backend, ops, web público, app Web, release host e sidecar: 6); o
preflight recusando (1); nenhuma mutação antes do fim do preflight (1).

A dependência declarada, `BT-CAP-001`, é real para os números. Os itens 1, 3 e
4 podem ser feitos e testados sem ela, mas a governança só deixa a tarefa
ocupar o NOW com `BT-CAP-001` em `PASS` ou com exceção de contenção (achado
9). Não há ambiente de staging: o treino de rollback só pode ser feito em
produção, com autorização, e só depois de o candidato chegar a `master`
(achado 2).

---

## BT-DR-001 — Backup fresco criptografado off-site, download do objeto exato e restore isolado

- **Estado declarado:** TODO. **Estado medido:** metade do código; nada
  executado.
- **Aceite** (linha 610): "Manifest/checksum/object version; RPO/RTO
  medidos; dados e schema validados".

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Backup fresco de produção pode ser gerado | PSP | `scripts/manaloom_easypanel_backup.sh:42-63` (`pg_dump -Fc` via SSH, ≥1024 bytes, `pg_restore --list`). A escrita não é atômica: o SSH redireciona direto para o nome final (`:42-44`); se a conexão cair, fica um arquivo truncado com nome válido, e as checagens (`:47-53`) nem rodam. O cron do host faz `tmp` + `mv` (`scripts/manaloom_install_remote_backup_cron.sh:98-134`), com sha256 ao lado (`:130-136`) e retenção de 14 dias (`:138-139`). Evidência histórica do cron com restore em modo `schema`: `docs/qa/runtime/manaloom-commercial-quality-gate-20260706T182123Z/remote_cron.txt:1-2` | só a recusa sem aprovação (`scripts/manaloom_release_ops_contract_test.sh:340-353`) e um grep (`:355`) | Executar o dump e tornar a escrita local atômica. O último fora do host tem 50 dias |
| 2 | Criptografia no cliente (age X25519) mais SSE | PSP | `scripts/manaloom_offsite_backup.sh:109` (age); `:143-146` (SSE AES256/KMS); `:171-174` (SSE conferido) | só o JSON de dry-run (`release_ops_contract_test.sh:293-297`), que sai antes de qualquer validação (`:56-60`); nada é cifrado | Executar |
| 3 | Envio off-site com allowlist de destino e recipient | PSP | `:148-153` (`aws s3 cp`); allowlist em `:73-84`; trava dupla em `:56-72`. Nunca rodou: não há recipient age nem destino S3 configurados, e a cadeia não foi provada (`docs/qa/MANALOOM_FREE_BETA_RELEASE_OPS_GATE_2026-07-16.md:304-310`) | só a primeira trava (ack) é exercitada (`release_ops_contract_test.sh:309-319`); a segunda (`MANALOOM_OFFSITE_BACKUP_EXECUTE`) e a allowlist não | Bucket, credenciais e execução |
| 4 | Manifest | PARC | `:115-136` (sha256 e bytes da origem e do arquivo cifrado, `recipient_sha256`). O `created_at` (`:117`) é a hora da cifragem. A hora do dump só existe por convenção no nome do arquivo de origem (`scripts/manaloom_easypanel_backup.sh:17-18`; cron `:97-99`), que o manifest carrega em `source.file` (`:118,128`). Não traz SHA do código, versão de schema nem contagens de origem | nenhum | Hora do dump como campo, `schema_migrations`, contagens e fingerprint de schema |
| 5 | Checksum verificado no destino | PARC | `:158-170` compara o tamanho e o metadado `sha256` que o próprio script gravou (`:149`). Não é checksum calculado pelo servidor, nem hash do conteúdo baixado | nenhum | `--checksum-algorithm SHA256` e verificação após o download |
| 6 | Object version (VersionId do S3) registrado | NE | o `head-object` lê só `ContentLength`, `Metadata` e `ServerSideEncryption` (`:158-162`). Não há checagem de versionamento nem de Object Lock no bucket | nenhum | Capturar o VersionId e exigir versionamento |
| 7 | Download do objeto exato, pela versão, com verificação | NE | `scripts/manaloom_full_restore_drill.sh` recebe um arquivo local (`:4,33,69-72`). Não existe `get-object` | nenhum | Download por `--version-id` e hash |
| 8 | Cadeia manifest → arquivo cifrado → arquivo decifrado | PSP | `scripts/manaloom_full_restore_drill.sh:105-132`. O próprio manifest não é autenticado: o drill não confere o hash dele, gravado como metadado no upload (`scripts/manaloom_offsite_backup.sh:151-153`), então manifest e arquivo trocados juntos passam. Fecha com a asserção 7 | só dry-run (`release_ops_contract_test.sh:299-302`). A "recusa" (`:320-328`) é vazia: o drill não tem guarda de acknowledgement; recusa porque `MANALOOM_RESTORE_DRILL_EXECUTE` não está definido (`:65-68`) | Executar |
| 9 | Restore isolado | PSP | `:141-170` (`--network none`, PG17 pinado em `:8,53-56`, `--exit-on-error`). Variante no host em `scripts/manaloom_install_remote_backup_cron.sh:145-244`, mas não se sabe qual versão está instalada: a última evidência (2026-07-06) roda em modo `schema` (`remote_cron.txt:2`); o instalador passou a exigir `full` em `2139ec9f6` (2026-07-23), sem registro de reinstalação. Evidência histórica: só restore de schema (87 tabelas) de um dump de 2026-07, fora da cadeia off-site (`docs/qa/MANALOOM_FREE_BETA_RELEASE_OPS_GATE_2026-07-16.md:306-309`) | só dry-run | Restore full a partir da cadeia off-site |
| 10 | RTO medido | PARC | o drill registra `started_at`/`completed_at` (`:91,198`); o intervalo inclui decifragem e restore (`:126` fica entre os dois), mas não download, e não calcula `rto_seconds`. O cron do host calcula `rto_seconds` (`scripts/manaloom_install_remote_backup_cron.sh:199-200,242-243`) só do restore, sem cifra. Não há meta | estático: grep da string `rto_seconds` (`release_ops_contract_test.sh:359`) | RTO de ponta a ponta, com download, contra uma meta |
| 11 | RPO medido | NE | nada calcula a idade do backup contra uma meta, e não existe meta. Dá para derivar do carimbo no nome do arquivo (asserção 4), mas nada o faz | nenhum | Calcular a partir da hora do dump |
| 12 | Dados validados | PARC | contagem de tabelas ≥ 80 (`:10,172-177`), de FKs (`:179-180`) e de linhas de 4 tabelas (`:187-196`), sem comparar com a origem. O `SET CONSTRAINTS ALL IMMEDIATE` (`:183-185`) não valida nada numa transação nova, mas o receipt grava `constraints_immediate: true` (`:236`), o que engana quem lê. A validação real de FK acontece no `pg_restore --exit-on-error` | nenhum | Gravar contagens de origem no backup e comparar |
| 13 | Schema validado contra o baseline | NE | não compara com o ledger 038–058. O SQL pronto do readiness (`server/lib/health_readiness_support.dart:137-173`) pode rodar contra a cópia restaurada | nenhum | Comparar com o ledger e com o inventário de `BT-DB-001` |

**O que realmente falta.** A metade que roda localmente existe: cifragem com
age e SSE, allowlist, manifest, cadeia de hashes, restore num container sem
rede. Mas nada disso rodou, porque não há bucket, recipient nem receipt.
"Metade" aqui é metade do código; das decisões e da prova viva, nada existe.
Faltam as cláusulas que tornam o backup verificável de ponta a ponta:

- VersionId, com versionamento exigido no bucket;
- download do objeto exato pela versão, com hash do conteúdo baixado e do
  manifest;
- hora do dump e contagens de origem no manifest;
- RPO e RTO de ponta a ponta contra metas;
- comparação do schema com o ledger e o inventário de `BT-DB-001`;
- escrita atômica do dump local.

Também não há ligação entre o dump diário do host, que não é cifrado e fica
na mesma máquina, e o envio off-site.

Custo: **10 arquivos (8 de código e teste, mais ficha e receipt)**:
`scripts/manaloom_offsite_backup.sh`, `scripts/manaloom_full_restore_drill.sh`,
um script novo de download por versão, `scripts/manaloom_easypanel_backup.sh`
(hora do dump, contagens, escrita atômica), o instalador do cron (se o dump do
host for a origem e para reinstalar a versão `full`), um arquivo de metas de
RPO/RTO, o contrato de release ops e um teste novo com shims. **7 testes**
com shims de `aws` e `age`: VersionId ausente → falha; bucket sem
versionamento → falha; hash divergente no download → falha; manifest sem hora
do dump → falha; RPO acima da meta → falha; schema divergente → falha;
contagem divergente → falha. Some-se **uma execução viva autorizada**: dump
fresco, upload, download e restore.

A dependência declarada, `BT-DB-001`, é parcial: só a asserção 13 precisa do
inventário. O resto pode andar já, e estes scripts não exigem
`HEAD == origin/master`. Há três dependências não declaradas: um provedor de
object storage com credenciais, a custódia da chave privada age e autorização
para tirar PII de produção para um terceiro (LGPD, região).

---

## BT-REL-001 — Transação de promoção full-stack e rollback comprovado

- **Estado declarado:** BLOCKED_BY_P0. **Estado medido:** mal começada.
- **Aceite** (linha 611): "Backend, public Web, Flutter Web/Android e ops
  convergem; failure pre-receipt não fica invisível".

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Orquestrador transacional: uma SHA, ordem definida, todas as superfícies | NE | nenhum script encadeia os `manaloom_deploy_*.sh`. Os únicos chamadores são `scripts/manaloom_build_beta_release.sh:32-34` (build-only) e `scripts/manaloom_battle_product_gate.sh:778-782` (só `bash -n`). `manaloom_build_beta_release.sh:13-122` constrói Web e Android localmente, sem backend, ops ou web público, e sem deploy | nenhum | Orquestrador com estado persistido |
| 2 | Convergência por superfície: spec = tarefa = origem EasyPanel = digest | PSP | backend `:1457-1478,1697-1716,1768-1789`; ops `:356-381,388-430`; web público `:360-408`; app Web `:613-670`; Android `scripts/manaloom_publish_android_release.sh:614-700`. Cada superfície converge para o próprio digest; nada confere que todas estão no mesmo SHA (ver `BT-REL-002`, asserção 13) | estático: `deploy_rollback_convergence_contract_test.dart:15-164` e `ops_sidecar_digest_release_contract_test.dart` | Execução real |
| 3 | Rollback por superfície comprovado | PARC | existe e verifica imagem, origem e marcador externo: backend `:1068-1158`, web público `:92-173`, app Web `:182-271`, ops `:143-194`, Android `:378-467`. Mas em cinco superfícies restaura só imagem/origem (ver `BT-CAP-002`, asserções 7 a 9), não confere o SHA nem a policy anteriores do backend (só `status==ready`, `:1141-1149`) e nunca rodou ao vivo | estático | Rollback exato e treino |
| 4 | Rollback entre superfícies: se a N falhar, reverte de 1 a N-1 | NE | cada script grava `DEPLOY_COMMITTED=1` ao terminar (backend `:1794`, ops `:432`, web público `:478`, app Web `:682`, Android `:710`). Depois disso não há como reverter | nenhum | Ponto de entrada "reverter para o estado salvo" |
| 5 | Flutter Web implantável no estado canônico | PARC (bloqueio estrutural) | `scripts/manaloom_deploy_flutter_web.sh:38-41` chama o loader que exige tudo OFF (`scripts/lib/manaloom_release_capabilities_contract.sh:104-117`) e depois o gate que exige algo ON com `live_verified_as_of` (`:171-189`). Nenhuma policy commitada passa nos dois. Contradiz `docs/status/CURRENT_PRODUCT_DECISION.md:23` | `scripts/manaloom_release_capabilities_contract_test.sh:64-83` testa cada metade isolada (a fixture "aberta" é montada em memória, sem o loader), e `:109` confirma que o loader recusa `allowed=true` com `off`. A composição nunca é testada | Decisão e correção do gate |
| 6 | Backend implantável contra o schema de produção | PARC | a pré-condição `require_migrations_041_058_contract` (`:931-999`, chamada em `:1169`) e o readiness exigem `latest_migration == "058"` (`:1743-1744`). A última observação de produção anunciava `057` (`docs/execution/CURRENT_QUEUE.md:100-103`, histórico). A 058 existe (`server/bin/migrate.dart:3865`) e só se desfaz por restore (`:4100`) | nenhum | Aplicar a 058 ao vivo, depois do backup de `BT-DR-001` |
| 7 | Candidato com capability ON pode ser promovido | NE | o loader recusa qualquer ON (`lib/...contract.sh:114-115`) e a asserção do ops exige 29 OFF (`scripts/manaloom_deploy_ops_image.sh:366`). O readiness do backend recusa ON em `battle_batch`, `battle_live`, `battle_coach` e `ai_analyze_optimize_advisory` (`scripts/manaloom_deploy_backend_image.sh:1746-1750`) | o teste de "non-default-deny" (`release_capabilities_contract_test.sh:109`) só cobre `allowed=true` com `off` | Mudar 2 gates (loader e ops) para catálogo/decks, 3 com Analyze/Optimize, aceitando ON com receipt |
| 8 | Falha antes do receipt fica visível | PARC | saída não-zero e `CRITICAL` no stderr (backend `:1156`, ops `:190`, web público `:171`, app Web `:269`). O JSON só sai no sucesso (backend `:1795-1819`, ops `:436-439`, web público `:480-482`, app Web `:683-710`). Não há arquivo de receipt de falha, evento no Sentry nem alerta (`BT-OBS-001` está TODO). O receipt v2 do deck/IA (`scripts/manaloom_deck_ai_learning_release_receipt.sh`) é um molde reaproveitável | nenhum | Receipt de falha durável e alerta |
| 9 | Prova viva: promoção e rollback comprovados | NE | nenhum receipt de deploy ou rollback em `docs/qa/execution/`. Produção está em `a6ee09c8f`, 39 commits atrás de `HEAD` | — | Treino live autorizado |

**O que realmente falta.** Os blocos por superfície existem: cinco scripts de
deploy com baseline, digest imutável e rollback próprio. A transação não
existe: não há orquestrador, rollback entre superfícies nem receipt de falha.
Antes de qualquer prova há quatro bloqueios estruturais:

1. **O candidato não está em `master`** (achado 2). Todos os deploys exigem
   `HEAD == origin/master`, e promover o branch passa pelo `pre-push` com
   `full` vermelho.
2. **O deploy do Flutter Web é inalcançável**, e o mesmo loader impede
   qualquer release com capability ON. Além disso, `live_verified_as_of`
   precisa de verificação live antes do deploy que a tornaria possível.
3. **Produção precisa estar na migration 058.** A última observação mostrava
   057. É uma migração live sem rollback automático, precedida do backup
   fresco de `BT-DR-001`.
4. **O rollback de env, resources e deploy** depende de `BT-CAP-002`.

Falta ainda: o orquestrador (preflight de todas as superfícies, backup,
backend, ops, web público, app Web e release host, nessa ordem), estado
salvo por superfície, reversão em ordem inversa, receipt de sucesso e de
falha, hook de alerta e o treino live.

Custo: **13 arquivos (11 de código e teste, mais ficha e receipt)**: o
orquestrador novo; uma biblioteca nova de estado e receipt; os cinco deploys
do core (ponto de reversão pós-commit e receipt de falha); o loader comum
(aceitar ON com receipt e compor com o gate do `/app`); o hook de alerta; o
teste novo do orquestrador; e o contrato de capabilities. **9 testes**: falha
em cada uma das cinco etapas reverte as anteriores (5); falha antes do receipt
deixa receipt de falha e alerta (1); sucesso deixa receipt (1); composição do
loader com o gate do `/app` na matriz canônica (1); candidato com capability ON
passa pelo loader, pelo ops e pelo readiness (1).

As quatro dependências declaradas (`BT-SCP-001`, `BT-CAP-002`, `BT-DR-001` e
`BT-OBS-001`) são reais. Há cinco não declaradas: a decisão sobre o `/app`
com a matriz toda OFF; a migração 058 live; a promoção do branch candidato a
`master`; e, por causa do `pre-push`, `BT-WEB-003` e `BT-UIEV-001` (ou um
bypass autorizado).

---

## BT-REL-002 — Gate same-SHA e identidade de release por superfície

- **Estado declarado:** BLOCKED_BY_P0. **Estado medido:** mal começada
  (a medição anterior dizia "metade"; ver a seção final).
- **Aceite** (linha 612): "SHA completo, product/surface e flags; app compara
  o digest recebido com a matriz embutida no próprio artefato; backend novo
  não habilita código antigo; mixed SHA/digest falha fechado".

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | SHA completo (40 hex, igual a `HEAD`) na identidade de build | PP | `scripts/manaloom_release_identity.sh:41-44,80-97` | `scripts/manaloom_release_ops_contract_test.sh:361-396` roda o script num repositório de fixture e exige `git_sha == HEAD`, versão `semver+build` e 29 capabilities válidas (inclui a regressão de SIGPIPE). `scripts/manaloom_release_capabilities_contract_test.sh:25-47` roda de novo e confere digest, contagem e tudo `off` | — |
| 2 | Recusa de worktree suja e de SHA ≠ `HEAD` ≠ `origin/master` | PSP (rebaixada de PP) | `manaloom_release_identity.sh:46-62` | nenhum teste negativo: os dois testes acima só rodam o caminho feliz. A guarda é contornável: os deploys herdam `MANALOOM_RELEASE_REQUIRE_CLEAN` do ambiente (`scripts/manaloom_deploy_flutter_web.sh:298-301`, `scripts/manaloom_deploy_public_web.sh:234-237`, `scripts/manaloom_build_android_release.sh:62-65`, `scripts/manaloom_publish_android_release.sh:50-53`), e `worktree_clean_required` (`:95`) não é conferido por nenhum consumidor. Risco baixo para o conteúdo, porque os builds saem de `git worktree add`/`git archive` do SHA (`flutter_web :312`, `build_android :105`, `public_web :297`) | Testes negativos das duas recusas e fixar `REQUIRE_CLEAN=1` nos chamadores |
| 3 | Backend expõe SHA e digest da policy | PARC | `/health` devolve `git_sha` lido do env (`server/routes/health/index.dart:27`) e o digest via `readinessCheck()` (`:29`; `server/lib/release_capability_policy.dart:213-219`); `/health/ready` não devolve SHA (`server/lib/health_readiness_support.dart:1731-1747`), e a onda 07 exige que `/ready` concorde com o SHA (`docs/execution/waves/07-beta-release.md:70-71`). `/capabilities` expõe matriz e digest (`release_capability_policy.dart:198-211`). O deploy confere o `GIT_SHA` do env do container (`scripts/manaloom_deploy_backend_image.sh:1697`) | `server/test/release_capability_policy_test.dart:159-183` verifica que o `/capabilities` devolve o digest do próprio objeto. Nenhum teste verifica `git_sha` | SHA (de preferência gravado na imagem) no readiness, e um teste |
| 4 | Ops expõe SHA e digest | PARC (rebaixada de PSP) | `server/bin/manaloom_ops_daemon.py:420,427`; o deploy confere (`scripts/manaloom_deploy_ops_image.sh:366,427`). O `git_sha` vem do env do serviço, não da imagem, e nenhum Dockerfile grava a revisão. Qualquer troca só de imagem, inclusive o rollback do próprio ops (`:152-163`), faz o `/health` relatar o SHA errado | `server/test/manaloom_ops_daemon_test.py:274-311` sobe o `/health` e não verifica `git_sha` nem `policy_digest_sha256` | Gravar a revisão na imagem (rótulo OCI, como os sidecars em `scripts/manaloom_deploy_battle_sidecars.sh:863,870`) ou restaurar o env no rollback; verificar no teste |
| 5 | Flutter Web e Android carregam a identidade no artefato | PARC (rebaixada de PSP) | Android: embute `assets/release/release-identity.json` (`scripts/manaloom_build_android_release.sh:122-168`), passa `RELEASE_GIT_SHA`/`RELEASE_IDENTITY_SHA256` (`:177-178`) e confere APK e AAB (`:204-211`). Web: o bundle compilado leva o placeholder `release_identity_embedded: false` (`app/assets/release/release-identity.json:1-5`), porque o deploy não regrava o asset nem passa `RELEASE_GIT_SHA` (`scripts/manaloom_deploy_flutter_web.sh:312-350`, build args em `:314-327`). A identidade Web existe só como arquivo lateral `/app/release.json` (`:380-448`, conferido ao vivo em `:654-670`), que o app não lê | estático (`release_ops_contract_test.sh:458-460`) | Embutir a identidade no bundle Web e teste comportamental |
| 6 | Web público expõe identidade | NE | `web-public/src/app/healthz/route.ts:3-10` devolve `ok`. O deploy grava `GIT_SHA` no env (`scripts/manaloom_deploy_public_web.sh:355`), mas nada em `web-public/src` o lê (só há `process.env` para URLs em `web-public/src/lib/public-server.ts:27` e `web-public/src/lib/routes.ts:26`) | nenhum | Rota de identidade |
| 7 | product e surface normalizados | PARC | a identidade diz `product: "manaloom"` (`manaloom_release_identity.sh:89`; `release.json` com `platform: "web"` em `manaloom_deploy_flutter_web.sh:407-408`). A policy diz `product: "brewtact"` (verificado no app em `app/lib/core/config/release_capabilities.dart:198`). O backend diz `service: 'mtgia-server'` (`server/routes/health/index.dart:23`). A identidade embutida no Android não tem `product` (`manaloom_build_android_release.sh:141-168`). Não há campo `surface` comum | parcial (o app recusa product diferente de `brewtact` só na policy) | Um schema comum |
| 8 | Matriz e digest na identidade de build | PP | `manaloom_release_identity.sh:96`, via loader (`scripts/lib/manaloom_release_capabilities_contract.sh:136-153`) | `release_capabilities_contract_test.sh:25-47` roda o script e exige digest igual ao sha256 do blob, contagem e tudo `off` | — |
| 9 | Matriz e digest na identidade de cada superfície | PSP (rebaixada de PP) | `release.json` (`manaloom_deploy_flutter_web.sh:414`), identidade Android (`manaloom_build_android_release.sh:152`), `/capabilities` do backend (`release_capability_policy.dart:198-211`). O ops expõe o digest e só 2 das 29 flags (`server/bin/manaloom_ops_daemon.py:423-434`) | só o backend tem teste que executa (`release_capability_policy_test.dart:159-173`); Web e Android só grep (`release_capabilities_contract_test.sh:159-163`) | Teste comportamental por superfície |
| 10 | App compara o digest recebido com a matriz embutida | NE | `ReleaseCapabilitiesSnapshot.fromJson` (`app/lib/core/config/release_capabilities.dart:112-142`) só valida o formato do digest (`:193-208`). Nada em `app/lib` lê `assets/release/release-identity.json` ou `release.json`. `RELEASE_IDENTITY_SHA256` só alimenta a prova de startup no Sentry, que não roda no Web (`app/lib/core/observability/app_observability.dart:152-162`) | `app/test/core/config/release_capabilities_test.dart:34-49` **afirma o oposto do aceite**: um payload com digest arbitrário (`'a' * 64`, `:18`) é aceito como válido | Carregar a identidade embutida e negar quando divergir |
| 11 | Backend novo não habilita código antigo | PARC | o artefato só limita 4 capabilities. No guard de rotas, 3 (`scanner` `:392`, `battleCoach` `:404`, `billingCheckout` `:515`); o campo `battleLive` de `ReleaseRouteBuildSupport` (`:339,345`) nunca é lido e nem é preenchido em `app/lib/main.dart:104-109`; o Live Spectator usa `LaunchFeatures` na própria tela (`app/lib/features/battle/screens/battle_live_spectator_screen.dart:30`). Para as outras 25, o app obedece o `allowed` do backend (`:185-187`), e não há negociação de versão do cliente (busca por `client_version`, `min_app_version` e `x-app-version` em `app/lib`, `server/lib` e `server/routes` não retorna nada) | `release_capabilities_test.dart:198-218` (scanner, no provider) e `:445-460` (scan e checkout, na rota). Battle coach e live não têm teste com build support negado | Teto do artefato para todas as 29 (a matriz embutida resolve esta asserção e a 10) |
| 12 | Digest de policy misto falha fechado no deploy do backend | PSP (rebaixada de PP) | `manaloom_require_exact_release_capabilities` (`lib/...contract.sh:156-169`), usado só em `scripts/manaloom_deploy_backend_image.sh:1764-1766`. Ops usa uma asserção Python própria (`:366,427`); Web e Android comparam o manifest com o valor que eles mesmos acabaram de gravar (`manaloom_deploy_flutter_web.sh:445,667`) | `release_capabilities_contract_test.sh:118-125` prova a função isolada. A chamada no deploy só tem grep (`:164-165`) | Executar o deploy com shim |
| 13 | SHA ou digest misto entre superfícies falha fechado (o gate same-SHA) | NE | nenhum script compara backend, ops, Web, Android e web público (buscas por `SERVER_BEHIND`, `same_sha` e `mixed` em `scripts/`, `server/bin/` e `tools/` não retornam nada). O único invariante cruzado é de build local, Web igual a Android (`scripts/manaloom_build_beta_release.sh:58-67,106`). Os harness live conferem só o backend (`server/test/commander_ai_real_provider_lifecycle_live_test.dart:85-94`) | estático (`release_ops_contract_test.sh:460`) | Script de gate que leia todas as superfícies |
| 14 | Rollback não deixa identidade mista | PARC | o backend volta a spec inteira (`:1104`). Ops e web público voltam só `--image`, e no ops o `/health` passa a informar o SHA do candidato (`server/bin/manaloom_ops_daemon.py:420`, sem detecção em `scripts/manaloom_deploy_ops_image.sh:172-178`) | nenhum | Restaurar o env (ou gravar a revisão na imagem) e comparar `git_sha` |

**O que realmente falta.** A identidade é boa no build: SHA completo, matriz
e digest, com teste. Em runtime ela está exposta em parte, e quase sempre
presa ao env do serviço, não à imagem: `/health` e `/capabilities` do backend,
`/health` do ops e `release.json` do app Web. Só o Android embute a
identidade no artefato. Nenhuma das seis cláusulas do aceite está fechada, e
as duas que dão nome à tarefa estão em zero:

- não há gate que compare SHA ou digest entre superfícies;
- o app não compara nada com a matriz embutida, e o teste atual aceita digest
  arbitrário;
- o bundle Web nem embute a identidade;
- o site público não expõe identidade;
- "backend novo não habilita código antigo" vale só para 4 de 29
  capabilities;
- product e surface não têm schema comum.

Custo: **14 arquivos (12 de código e teste, mais ficha e receipt)**:
`app/lib/core/config/release_capabilities.dart`, a fiação em
`app/lib/main.dart` e o teste do app (corrigir o que aceita digest
arbitrário); `scripts/manaloom_deploy_flutter_web.sh` para embutir a
identidade; `scripts/manaloom_release_identity.sh` para normalizar
product/surface; `server/routes/health/index.dart` e
`server/lib/health_readiness_support.dart`, com um teste de servidor para o
SHA; uma rota de identidade no `web-public` e seu teste; o script novo de gate
same-SHA e seu teste; e o binding de revisão do ops (rótulo OCI no build ou
env no rollback de `scripts/manaloom_deploy_ops_image.sh`). **9 testes**: app
com digest divergente nega; app sem identidade embutida nega; capability ON no
servidor e OFF no artefato fica negada; gate com SHA misto; gate com digest
misto; gate sem uma superfície; `/health` e `/health/ready` com SHA; rota do
web público; `/health` do ops com `git_sha` e digest.

A dependência declarada, `BT-REL-001`, é parcial no código: tudo acima pode
ser feito e testado localmente. Mas a governança não deixa a tarefa ocupar o
NOW antes de `BT-REL-001` em `PASS` sem exceção de contenção (achado 9), e a
leitura das superfícies em produção depende da promoção e de o candidato
chegar a `master`. Há sobreposição com a cláusula "same-SHA registra a
matriz" de `BT-SCP-001`, que está pendente de receipt; com `BT-OBS-002`, que
pode reutilizar o mesmo gate como monitor agendado; e com `BT-CAP-002`, cuja
restauração de env também resolve a asserção 14 no ops.

---

## BT-REL-003 — Candidato congelado e matriz local completa

- **Estado declarado:** BLOCKED_BY_P0. **Estado medido:** mal começada.
- **Aceite** (linha 613): "quick/full/schema/e2e/release e segurança verdes
  no commit candidato; o gate resolve e exige todos os P0 core aplicáveis".

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Candidato congelado: SHA limpo igual a `origin/master` e artefatos com a mesma identidade | PARC | `scripts/manaloom_release_identity.sh:46-62` com `scripts/manaloom_build_beta_release.sh:13-122` (`beta-candidate.json` com o invariante Web == Android, gravado em `$HOME/.manaloom/releases`, fora do repositório, `:22`). Hoje o candidato nem pode ser congelado: `HEAD` está 29 commits à frente de `origin/master` e a worktree está suja. Faltam backend, ops e web público no candidato, e nenhuma tag de congelamento é criada | a identidade é executada no caminho feliz (`release_ops_contract_test.sh:361-396`); o `build_beta_release` só tem grep (`:460`) | Promover o branch a `master`, digests de todas as superfícies e uma tag |
| 2 | Os cinco modos existem | PSP | `scripts/manaloom_local_ci.sh:216-262`. `full` chama `melos run quality` (`melos.yaml:96-98`: project-logic, full, ui-audit, custom-lint, patrol-smoke, deps). O modo `release` é `full` + gate canônico de Battle + build Android (`:253-256`): não constrói o Web nem o `beta-candidate.json` | nenhum teste do orquestrador | — |
| 3 | Verdes no commit candidato | NE (vermelho hoje) | `full` termina com `EXIT=1` no `npm audit` (`docs/execution/CURRENT_QUEUE.md:92-95`; `docs/qa/execution/2026-09-21/PONTO_DE_RETOMADA.md:67-76`). `ui-audit` depende de `BT-UIEV-001`. `custom-lint`, `patrol-smoke` e `deps` nunca foram exercitados. O `release` exige ainda o bootstrap Maven pinado do XMage (`:204`), embora Battle esteja OFF, e a keystore | — | Fechar `BT-WEB-003` e `BT-UIEV-001` e rodar tudo |
| 4 | Segurança no gate | PARC | secret scan (`scripts/manaloom_local_ci.sh:126-129`), dependency audit (melos `deps`), `npm audit` no `quality_gate.sh full`, OSV nos builds Web e Android (`scripts/manaloom_deploy_flutter_web.sh:364-376`). Não há um estágio `security` nomeado, e hoje está vermelho (`next` crítico, `BT-WEB-003`) | nenhum | Estágio nomeado e verde |
| 5 | Resultado ligado ao commit (receipt durável) | NE | `scripts/manaloom_local_ci.sh:68-75` apaga o `RUN_DIR` na saída; `:264` só imprime PASS. O receipt v2 do deck/IA (`scripts/manaloom_deck_ai_learning_release_receipt.sh:12,51-53`) é um molde | nenhum | Receipt com SHA e digests (`BT-GATE-002`) |
| 6 | O gate resolve e exige os P0 CORE aplicáveis | NE | nenhum gate de release lê `docs/generated/TASK_REGISTRY.json`; só o gerador lê (`tools/project_logic/lib/project_logic_generator.dart:291,530`), e ele já sabe checar se dependências estão em `PASS` (`:1692-1711`). O registry não tem campo de aplicabilidade; o estado `DEFERRED_BY_SCOPE` existe (ex.: backlog linha 595) e pode servir de "não aplicável", mas a escolha do que está no escopo é decisão | nenhum | Critério de aplicabilidade e verificação fail-closed |

**O que realmente falta.** Os modos do gate existem, e o candidato Web e
Android pode ser construído com identidade única. Mas a matriz está vermelha
hoje: `npm audit` crítico no `full`, `ui-audit` preso a `BT-UIEV-001` e três
estágios nunca exercitados. O candidato não pode ser congelado enquanto o
branch não chegar a `master`. O resultado não é gravado num receipt ligado ao
SHA. E nenhum gate lê o registry para exigir os P0 CORE aplicáveis.

Custo: **9 arquivos (7 de código e teste, mais ficha e receipt)**: um script
novo de gate do candidato e seu teste; a aplicabilidade no
`tools/project_logic` (gerador e teste) e na fonte, o backlog;
`scripts/manaloom_local_ci.sh` para persistir o receipt e completar o modo
`release`; `scripts/manaloom_build_beta_release.sh` para incluir os digests
das outras superfícies. **5 testes**: registry com P0 aplicável aberto →
`BLOCKED`; tudo `PASS` segue adiante; receipt com SHA divergente falha; P0 não
aplicável é ignorado explicitamente, com motivo; candidato sem uma superfície
→ `BLOCKED`.

As dependências declaradas são reais (`BT-REL-002`, `BT-GATE-003`,
`BT-GATE-005` e `BT-UX-PROOF-001`). Pelo registry, o fecho transitivo tem 31
tarefas, 28 abertas e 22 delas P0 (inclui as oito de UX por trás de
`BT-UX-PROOF-001`). Há cinco não declaradas: `BT-WEB-003`, `BT-UIEV-001`,
`BT-GATE-007` (que muda o que `full` executa), a promoção do branch a `master`
e, via `BT-GATE-003`, `BT-GATE-001` e `BT-GATE-002`. O modo `release` também
exige a keystore Android e as senhas no Keychain
(`scripts/manaloom_build_android_release.sh:6,55-57,94-95`).

---

## Verificação adversarial

Revisão cética de 2026-09-22 sobre o mesmo `d15beb05b`, somente leitura.
Foram reexaminadas as 57 asserções da medição original: as 3 PP e as 11 PSP
abertas uma a uma (código e teste), e as PARC/NE conferidas pelas linhas
citadas e por buscas no repositório.

### O que caiu

| Tarefa | Asserção | De → para | Por quê |
| --- | --- | --- | --- |
| `BT-REL-002` | Identidade com SHA completo, worktree limpa e igual a `origin/master` | PP → PSP (a parte da guarda; o "SHA completo" continua PP, linha 1) | Os dois testes só rodam o caminho feliz. Nenhum exercita a recusa de worktree suja nem de SHA divergente (`manaloom_release_identity.sh:46-62`). A guarda é contornável pelo env herdado nos deploys, e `worktree_clean_required` não é conferido por ninguém |
| `BT-REL-002` | Flags (matriz e digest) na identidade | PP → PSP (a parte por superfície; a do script continua PP, linha 8) | O teste prova só a saída do script de identidade. `release.json` e a identidade Android só têm grep; o ops expõe 2 das 29 flags |
| `BT-REL-002` | Digest de policy misto falha fechado no deploy | PP → PSP | O teste prova a função isolada. A chamada no deploy só tem grep, e só o backend a usa. A comparação entre superfícies passou para a linha 13 (NE) |
| `BT-REL-002` | Ops expõe SHA e digest | PSP → PARC | O SHA vem do env, não da imagem, e mente depois de qualquer troca só de imagem, inclusive o rollback do próprio ops. O teste não confere `git_sha` nem digest |
| `BT-REL-002` | Flutter Web e Android carregam a identidade no artefato | PSP → PARC | O bundle Web leva o placeholder `release_identity_embedded: false`. A identidade Web é só um arquivo lateral que o app não lê |

Estado medido revisado: **`BT-REL-002` de "metade" para "mal começada"**.
Nenhuma das seis cláusulas do aceite está fechada. As duas que dão nome à
tarefa (gate same-SHA e comparação no app) estão em zero, e o teste do app
afirma o contrário do aceite. O que existe é identidade de build e
autoverificação por superfície.

### O que subiu

Nenhuma asserção mudou de estado para cima. Houve quatro correções a favor,
que baixam custo sem mudar estado:

- abrir a primeira capability exige mudar 2 gates (3 com Analyze/Optimize),
  não "pelo menos quatro": o readiness do backend só recusa ON em quatro
  capabilities (`manaloom_deploy_backend_image.sh:1746-1750`);
- há padrões prontos para reaproveitar (achado 10): hash de env com
  restauração verificada, rótulo OCI de revisão, SQL do ledger, receipt v2,
  pin da chave SSH e checagem de dependências no gerador;
- o intervalo de tempo do restore drill já inclui a decifragem
  (`manaloom_full_restore_drill.sh:91,126,198`);
- a hora do dump existe no nome do arquivo de origem, que o manifest carrega.

### Correções factuais

- O rollback restaura só imagem/origem em 5 de 6 caminhos, não em 4 de 5: o
  release host Android também não reverte `updateDeploy` (`:628`) nem o
  Traefik (`:631-633`) e também publica `:latest` antes do marco (`:557`).
- O teste "non-default-deny" está em `release_capabilities_contract_test.sh:109`,
  não em `:112`, e só cobre `allowed=true` com `off`.
- O AND servidor×artefato cobre 4 capabilities no app, mas o guard de rotas
  usa 3; `battleLive` é campo morto. O teste cobre só scanner e checkout
  (`release_capabilities_test.dart:198-218,445-460`), não "as 4".
- A "recusa" do restore drill no contrato é vazia: o drill não tem guarda de
  acknowledgement.
- O receipt do drill grava `constraints_immediate: true` sem validar nada
  (`:236`).
- A versão do cron instalada no host é desconhecida; a última evidência é de
  modo `schema`.
- A 058 tem rollback `manualOnly` (`server/bin/migrate.dart:4100`), o que
  torna o backup de `BT-DR-001` pré-requisito duro de `BT-REL-001`.

### Bloqueios que a medição não viu

1. **O candidato não está em `master`** (achado 2). Isso afeta `BT-CAP-002`
   (treino), `BT-REL-001`, `BT-REL-002` (parte viva) e `BT-REL-003`, e arrasta
   `BT-WEB-003` e `BT-UIEV-001` via `pre-push`.
2. **A governança impõe as dependências declaradas** (achado 9). "Pode andar
   já" exige exceção de contenção autorizada.
3. **`BT-REL-003` é a cauda do programa**: 28 dependências transitivas
   abertas, 22 P0.

### Custos revisados

| Tarefa | Arquivos (antes → depois) | Testes (antes → depois) | O que faltava na conta |
| --- | ---: | ---: | --- |
| `BT-CAP-001` | 5 → 8 | 3 → 5 | ligação do teste no gate, ficha, receipt; testes do preflight e do snapshot |
| `BT-CAP-002` | 8 → 13 | 6 → 8 | release host, sidecars, resources do PostgreSQL, harness de shims, 2 testes estáticos que quebram, ficha, receipt; rollback do sidecar e "nenhuma mutação antes do preflight" |
| `BT-DR-001` | 6 → 10 | 5 → 7 | metas RPO/RTO, teste com shims, ficha, receipt; versionamento do bucket e hora do dump |
| `BT-REL-001` | 9 → 13 | 7 → 9 | biblioteca de estado, contrato de capabilities, ficha, receipt; composição dos gates e candidato ON |
| `BT-REL-002` | 9 → 14 | 7 → 9 | arquivos de teste (servidor, web público, gate), binding de revisão do ops, ficha, receipt; teto do artefato e `/health` do ops |
| `BT-REL-003` | 5 → 9 | 4 → 5 | teste do gate, teste do gerador, fonte do backlog, ficha, receipt; candidato sem superfície |
| **Total** | **42 → 67** | **32 → 43** | |

### Veredito de otimismo

**Otimista demais.** Os estados medidos se sustentam em 5 de 6 tarefas, e a
leitura estrutural (gates contraditórios, rollback só de imagem, zero dado de
capacidade) está certa. Mas:

- 3 das 3 asserções PP não se sustentaram inteiras: uma caiu e duas foram
  partidas;
- 2 PSP viraram PARC;
- `BT-REL-002` estava uma faixa acima do que o código mostra;
- a conta de arquivos subiu 60% e a de testes 34%;
- a medição não viu o bloqueio que antecede qualquer prova viva de release:
  o candidato está 29 commits fora de `master`, e chegar lá passa por um
  `pre-push` hoje vermelho.

No outro sentido, a medição foi dura demais em um ponto (os gates de ON) e não
viu padrões reaproveitáveis que baixam o custo do rollback exato e da
identidade presa à imagem.
