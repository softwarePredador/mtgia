# Receipt — BT-CAP-002: reservas, limites e rollback exato de recursos (D-14) — 2026-09-28

- **Tarefa:** `BT-CAP-002`. A decisão do dono de 2026-09-22 é a D-14: os limites e as reservas
  de cada serviço saem da leitura do `BT-CAP-001`.
- **Executado por:** Frente C (banco e operação), no worktree da frente, branch
  `banco/rodada1-2026-09-24`, na rodada 3, em modo ensaio.
- **Limites:** nada tocou a produção. Não houve SSH, EasyPanel nem banco live. A prova roda contra
  duas coisas:
  - uma spec de serviço gravada: um fixture montado com o que a leitura do `BT-CAP-001`
    registrou;
  - um plano de controle falso, com um Docker Swarm e um EasyPanel de mentira atrás dos shims de
    `ssh` e `curl`.
- **O que falta:** aplicar na produção. Isso é um passo do lote de deploy e depende da palavra do
  dono (seção "Passo do lote").

## O que mudou

| Arquivo | Mudança |
| --- | --- |
| `server/config/capacity_policy.json` | Versão `2026-09-28.1`, com a seção nova `reservations_and_limits` (dona `BT-CAP-002`). Tem duas regras, cada uma com justificativa: a soma das reservas do nó fica 2 GiB abaixo da memória, e o limite fica em pelo menos 4 vezes o uso lido. Cada serviço traz reserva, limite, CPU, quem aplica, justificativa e o uso lido, com a evidência citada do receipt de 2026-09-23 |
| `scripts/manaloom_capacity_policy.py` | O validador passou a conferir a seção nova (detalhe logo abaixo da tabela) |
| `scripts/manaloom_capacity_resources.py` | Lógica sem conexão: plano com preflight, conferência depois de aplicar, decisão de rollback, conferência do rollback, redator do env e receipt |
| `scripts/manaloom_capacity_resources.sh` | Orquestrador. Sem `--execute`, só descreve. `--plan` só lê. `--apply` e `--rollback` exigem aprovação explícita e um diretório durável para o receipt |
| `server/test/capacity_resources_test.py` | 37 testes: fixture, política, plano, conferências e a ferramenta de verdade contra o plano falso |
| `server/test/fixtures/capacity/evolution_services_2026-09-23.json` | A spec gravada (ver "O fixture") |
| `scripts/manaloom_release_ops_contract_test.sh` | Liga o teste novo, a sintaxe do script e a compilação dos dois arquivos Python |
| `docs/project_logic_contracts.json` | O fluxo `release_operations` passa a listar as ferramentas e os testes de capacidade (`BT-CAP-001` e `BT-CAP-002`) |

O validador de `scripts/manaloom_capacity_policy.py` confere:

- os números e o uso lido de cada serviço, com a evidência do receipt;
- reserva no máximo igual ao limite, e CPU dentro dos 4 vCPU;
- serviço sem limite de memória só com decisão pendente do dono;
- a ferramenta só aplica em app do EasyPanel, e o PostgreSQL só com o dono;
- a soma das reservas dentro da memória menos a margem.

## Os números (política `2026-09-28.1`)

| Serviço | Reserva / limite de memória | Reserva / limite de CPU | Quem aplica |
| --- | --- | --- | --- |
| `cartinhas` (backend) | 256 MiB / 1.536 MiB | 0,25 / 2 | esta ferramenta |
| `manaloom-ops` | 256 MiB / 2.048 MiB | 0,1 / 1 | esta ferramenta |
| `manaloom-web-public` | 32 MiB / 256 MiB | 0,05 / 0,5 | esta ferramenta |
| `manaloom-app` (`/app`) | 32 MiB / 256 MiB | 0,05 / 0,5 | esta ferramenta |
| `manaloom-releases` (APK) | 32 MiB / 256 MiB | 0,05 / 0,5 | esta ferramenta |
| `xmage-sidecar`, `xmage-interactive` | 512 MiB / 4.096 MiB | 0,25 / 2 | o deploy do Battle (0 réplicas desde a D-57) |
| `forge-sidecar` | 512 MiB / 2.560 MiB | 0,25 / 2 | o deploy do Battle |
| `manaloom-postgres` | 512 MiB / sem limite | 0,5 / sem limite | pendente do dono |

- **A soma das reservas** é de 2.656 MiB. O teto é de 5.893 MiB: 7.941 MB de memória menos a
  margem de 2.048 MiB.
- **A folga dos limites:** os serviços desta ferramenta usavam menos de 50 MiB na leitura de
  2026-09-23, e todo limite fica em pelo menos 4 vezes isso.
- **Os valores do Battle** espelham o que `scripts/manaloom_deploy_battle_sidecars.sh` já grava a
  cada deploy. A ferramenta recusa aplicar nesses três serviços.

## A ferramenta

### Preflight

O `--plan` e o `--apply` só seguem com PASS. O plano bloqueia se qualquer um destes falhar:

1. O serviço é desta ferramenta pela política.
2. O preflight de capacidade do `BT-CAP-001` dá PASS sobre um snapshot de até 30 minutos, com a
   procedência do host de produção.
3. A spec lida é do serviço pedido. Ele está no ar, com todas as réplicas rodando a imagem da
   spec, a imagem é um digest imutável e não há atualização do Swarm em andamento.
4. O EasyPanel tem o serviço como app, com a mesma imagem da spec. Os recursos gravados nele
   são iguais aos do Swarm. Sem isso, o próximo deploy do EasyPanel mudaria outra coisa.
5. A soma das reservas do nó cabe no teto de memória e nos 4 vCPU. Assim o Swarm não deixa a
   tarefa nova pendente, o que com `stop-first` seria o serviço fora do ar.
6. O limite fica em pelo menos 4 vezes o uso do serviço medido no mesmo snapshot.

### Aplicação

A ferramenta grava os recursos nos dois lugares, porque um deploy do EasyPanel recria a spec com
o que está gravado nele:

- no EasyPanel, `services.app.updateResources`, sem `deployService`;
- no Swarm, `docker service update` só com as quatro flags de recursos. Os valores exatos das
  flags saem do Python, sem depender da versão do `jq`.

Depois, ela espera convergir e confere:

- a impressão digital SHA-256 da spec inteira sem `Resources` é igual à de antes;
- os recursos são os pedidos no Swarm e no EasyPanel;
- a imagem, o env e o deploy gravados no EasyPanel não mudaram.

### Rollback exato

Há dois caminhos de rollback:

- **Automático:** quando a conferência falha ou quando a execução para no meio (trap no `EXIT`).
- **Pelo receipt:** `--rollback <receipt>`.

Em qualquer um, a decisão só libera se a nossa mudança ainda for a última nos dois lugares:

- **Swarm:** a spec atual é a que aplicamos e a anterior dela é a de antes. Assim,
  `docker service rollback` devolve a spec exata. Sem conferência gravada (parada no meio), a
  spec só pode diferir da de antes nos recursos pedidos.
- **EasyPanel:** imagem, env e deploy iguais aos de antes, e recursos iguais aos pedidos ou aos
  de antes.

Se outro deploy passou no meio, a ferramenta não desfaz nada. Ela para, grava o receipt
`rollback_failed` e mostra o plano manual. Depois do rollback, a prova exige três coisas:

- a spec inteira igual à de antes (imagem, env, recursos, deploy, rede e rótulos, pela impressão
  digital);
- o EasyPanel igual ao de antes;
- o serviço convergido.

### Receipt e segredos

- **Receipt:** fica em diretório durável e recusa `/tmp`, `/var/folders` e worktree. A permissão
  é 600 e o status é um de `applied`, `rolled_back`, `rollback_failed` ou `blocked`. Um plano
  BLOCKED no `--apply` também grava o seu, então uma falha antes da mudança não fica invisível.
- **Segredos:** nenhum valor de env chega ao disco nem ao receipt. As leituras do Swarm e do
  EasyPanel passam por um redator antes de virar arquivo, e cada valor vira `sha256:<hex>`, de
  modo que a impressão digital continua mudando com o valor. Do EasyPanel ficam só os serviços do
  projeto `evolution` e os campos usados.

### Comandos

A ferramenta só manda estes comandos ao host, e o teste confere cada chamada:

- `docker service inspect`;
- `docker service ps` com o formato `imagem|estado`;
- `docker service update` só com as flags de recursos;
- `docker service rollback`.

No EasyPanel, só chama `projects.listProjectsAndServices` e `services.app.updateResources`. As
chamadas saem por SSH com a âncora de host do deploy e pela URL do EasyPanel com a âncora
SHA-256.

## O fixture

O arquivo `server/test/fixtures/capacity/evolution_services_2026-09-23.json` traz:

- as specs do Swarm dos 8 serviços da `evolution`, a lista do EasyPanel (com um serviço de outro
  projeto) e as tarefas no ar;
- a leitura do host no formato da ferramenta do `BT-CAP-001`, com a data preenchida na hora do
  teste, e a leitura do PostgreSQL.

O que vem da leitura de 2026-09-23 tem a evidência citada. O teste exige que cada trecho esteja no
receipt `docs/qa/execution/2026-09-23/host-xmage-e-reinicio.md` com o número. São eles:

- 4 vCPU e 7.941 MB de RAM;
- os dois XMage como os únicos com limite (4 GiB) e em 0 réplicas;
- o PostgreSQL com 212 MiB, e os demais abaixo de 50 MiB;
- 6.484 MB disponíveis;
- as imagens publicadas nos receipts do dia.

O resto da forma é modelo sem valor real: políticas de update iguais às dos scripts de deploy,
rótulos e os digests que os receipts não trazem inteiros. As variáveis sensíveis do fixture valem
`modelo-nao-e-segredo-…`, e o teste prova que esse texto não aparece em receipt, saída nem arquivo
de trabalho.

## Provas

### Testes

`server/test/capacity_resources_test.py` tem 37 verdes, em cerca de 35 s:

- **Fixture (3):** os números vêm da leitura, os limites só existem no XMage e o env é só modelo.
- **Política (2):** a seção versionada vale. Doze incoerências são recusadas, entre elas limite
  abaixo da folga, reserva acima do limite, CPU acima do host, serviço sem limite, a ferramenta
  fora de app, o banco sem o dono, reservas acima da memória e evidência fora do receipt.
- **Plano (8):**
  - PASS nos 5 serviços, com as flags exatas e a soma do nó: 256 MiB do `carmatch` mais a
    reserva pedida, contra o teto de 5.893 MiB.
  - Bloqueia serviço de outra ferramenta ou desconhecido, serviço sem convergir, com imagem por
    tag, em atualização ou sem réplicas, e EasyPanel com imagem ou recursos divergentes, sem
    recursos legíveis ou sem o serviço.
  - Bloqueia snapshot velho, soma de memória ou de CPU acima do nó, limite abaixo de 4 vezes o
    uso e serviço sem medição.
  - Recusa spec de outro serviço e marca o que já está aplicado.
- **Conferências (8):**
  - A aplicação só passa com a mudança de recursos nos dois lugares. Falha com env, imagem, deploy
    ou env do EasyPanel mudados, com tarefa pendente ou com mudança de política de update.
  - A decisão de rollback segue só a nossa mudança. Bloqueia outro deploy, outra mudança seguida
    do rollback dela e EasyPanel mudado.
  - A conferência do rollback exige a spec inteira: uma mudança de rótulo é pega só pela
    impressão digital. Exige também o EasyPanel de antes.
  - O redator tira os valores e mantém a impressão digital.
- **Ferramenta contra o plano falso (16):**
  - Sem `--execute`, só descreve; o `--plan` só lê.
  - O `--apply` muda só os recursos, com o comando
    `docker service update --detach=true --limit-memory 1610612736 --reserve-memory 268435456 --limit-cpu 2 --reserve-cpu 0.25 'evolution_cartinhas'`,
    e a segunda execução não muda nada.
  - O `--rollback` pelo receipt devolve a spec exata. Bloqueia depois de outro deploy e exige
    receipt de aplicação e aprovação.
  - Cada defeito injetado cai no rollback provado ou para com CRITICAL: env mudado pelo update,
    update pausado, rollback automático do Swarm, update recusado, `updateResources` recusado,
    parada no meio depois do update, rollback que falha e outro deploy no meio (nunca
    sobrescrito).
  - Plano BLOCKED grava receipt `blocked`. Sem aprovação, com diretório temporário ou sem as
    âncoras (SSH e EasyPanel, ausentes ou erradas), nada sai da máquina.
  - Em todos: só comandos da lista fechada, só HTTPS, receipts com permissão 600 e nenhum valor
    de env em receipt, saída ou arquivo de trabalho.

`server/test/capacity_policy_test.py` segue com 21 verdes, e `python3 scripts/manaloom_capacity_policy.py validate-policy`
devolve `valid`, versão `2026-09-28.1`. O `shellcheck -x` do script está limpo.

### Mutações

O arquivo é `mutacoes_bt_cap_002.json`, rodado na cópia de trabalho da frente. As **52 mutações
foram derrubadas**:

- 26 na lógica: os seis portões do plano, a soma do nó, as conferências, a decisão de rollback, o
  receipt com env e os redatores;
- 16 no orquestrador: aprovação, diretório durável, as duas âncoras, receipt `blocked`, rollback
  automático, trap, os dois lados da restauração, a decisão, a conferência, as flags trocadas, a
  reaplicação, as leituras sem redator e o receipt de rollback;
- 8 no validador da política;
- 2 nos dados.

### Gates

suíte do servidor: 406 arquivos em 11 lotes, todos com rc=0 (tags live fora); `project_logic --write`, `--check` e `--test` verdes; contrato de release `passed` (35 contratos); comparação de schema do gate tbls num banco novo: PASS (86 tables, 6 views, 100 foreign keys, 67 migrations)

## Passo do lote (produção, com a palavra do dono)

O passo está pronto no roteiro do lote, fora do repositório: seção "Reservas e limites
(BT-CAP-002)" de `~/.manaloom/coordenacao/banco/ROTEIRO_LOTE_DEPLOY_BACKUP.md`, que chama
`~/.manaloom/coordenacao/banco/lote_capacidade.sh`. Ele roda depois dos deploys do lote, um serviço
por vez:

1. Snapshot novo, com `scripts/manaloom_capacity_snapshot.sh --execute`.
2. `--plan`, que só lê.
3. `--apply` com a palavra do dono.
4. Receipt.

A ordem vai do menos crítico ao backend: `manaloom-releases`, `manaloom-app`,
`manaloom-web-public`, `manaloom-ops` e `cartinhas`.

Cada aplicação troca a tarefa do serviço. Com `stop-first` e uma réplica, é um reinício de
segundos, como um deploy. O primeiro `--plan` também confirma duas premissas que o ensaio não
pode provar:

- que `projects.listProjectsAndServices` devolve `resources` de cada serviço. Se não devolver, o
  plano bloqueia e nada muda;
- que o `docker service update` do host mantém a spec idêntica fora de `Resources`. Se não
  mantiver, a conferência falha e a ferramenta desfaz sozinha.

## Decisões do dono

Estão em `~/.manaloom/coordenacao/receipts/decisoes-pendentes.md`, com a recomendação:

- os recursos do PostgreSQL;
- a soma dos limites do Battle quando ele abrir;
- o limite do ops sem o pico medido;
- os limites do preflight do `BT-CAP-001`, que seguem como proposta.
