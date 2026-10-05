# Receipt — BT-REL-001: transação de promoção full-stack e rollback comprovado (D-13) — 2026-09-28

- **Tarefa:** `BT-REL-001`. A decisão do dono de 2026-09-22 é a D-13:
  - o `/app` pode ser implantado com as 29 capabilities off, como release de plano de controle;
    a regra de ao menos uma on vale só quando uma capability abrir;
  - a ordem é backend, site público, `/app` e Android;
  - o Android da primeira coorte sai por APK no release host.
- **Executado por:** Frente C (banco e operação), no worktree da frente, branch
  `banco/rodada1-2026-09-24`, na rodada 3, em modo ensaio.
- **Limites:**
  - nada tocou a produção: sem SSH, EasyPanel, deploy nem banco live;
  - a prova roda a ferramenta de verdade num repositório git descartável, contra um Swarm, um
    EasyPanel e sondas públicas falsos, e com os cinco deploys trocados por stubs.
- **Raia do app:** o conserto do loader não precisou de `app/`, `app/web/`,
  `app/tool/serve_flutter_web_app.py` nem de outra raiz do digest de UI. Tudo aqui é `scripts/`,
  `server/` e `docs/`, então foi por commit e não houve rascunho.

## O que mudou

| Arquivo | Mudança |
| --- | --- |
| `scripts/lib/manaloom_release_capabilities_contract.sh` | Função nova `manaloom_resolve_public_app_release_mode`, detalhada na seção seguinte |
| `scripts/manaloom_deploy_flutter_web.sh` | Troca o gate pelo resolvedor, antes da aprovação, e grava `release_mode` (detalhe na seção seguinte) |
| `scripts/manaloom_release_capabilities_contract_test.sh` | Prova o resolvedor: all-off vira `control_plane`, abertura verificada vira `product_open` e toda matriz incoerente bloqueia. Também exige que o deploy do `/app` use o resolvedor e não chame mais o gate direto |
| `server/test/flutter_web_deploy_contract_test.dart` e `scripts/manaloom_release_ops_contract_test.sh` | A ordem dos portões passa a valer para o resolvedor. Com a matriz all-off do SHA, quem bloqueia o deploy sem aprovação é a aprovação live, e não mais o `/app permanece inacessivel` |
| `scripts/manaloom_promote_release.sh` | O orquestrador da transação (modos na seção "A transação") |
| `scripts/manaloom_promote_release.py` | A lógica sem conexão: política, leitura de cada superfície, linha de base, conferências, decisão de volta e diário |
| `server/config/release_promotion.json` | A política versionada: superfícies, ordem da D-13, como cada uma volta e a sonda de cada uma |
| `server/test/release_promotion_test.py` | 37 testes (detalhe em "Provas") |
| `scripts/manaloom_release_ops_contract_test.sh` e `docs/project_logic_contracts.json` | Ligam a ferramenta e o teste ao contrato de release e ao fluxo `release_operations` |
| `docs/MAPA_OPERACIONAL_DO_PROJETO.md` | O Flutter Web deixa de constar como bloqueado |

## O conserto do loader x gate (D-13)

- **Antes:** o deploy do `/app` era inalcançável desde `fd0397a5a` (2026-08-24).
  - O loader canônico (`manaloom_load_release_capabilities_from_git`) exige as 29 capabilities
    off.
  - O gate do `/app` (`manaloom_require_public_app_release_open`) exige ao menos uma on, com
    verificação live datada.
  - O deploy chamava os dois em sequência, e um sempre falhava.
- **Agora, o resolvedor:** `manaloom_resolve_public_app_release_mode` devolve:
  - `control_plane` quando todas as capabilities estão off e com `allowed` false;
  - fora disso, o gate de abertura de sempre decide: `product_open` com capability on
    verificada, ou BLOCKED.
  - Matriz incoerente (off com `allowed` true, on sem verificação, sem capabilities ou texto que
    não é JSON) nunca vira plano de controle.
- **Agora, o deploy do `/app`:**
  - chama o resolvedor antes da aprovação;
  - grava `release_mode` no `release.json`;
  - confere o campo no artefato construído e no `release.json` servido;
  - devolve o modo na saída. O build local (`MANALOOM_RELEASE_BUILD_ONLY=1`) grava o mesmo modo.
- **O que segue igual:**
  - o loader continua exigindo a matriz all-off (default-deny da beta);
  - o gate de abertura continua igual para quando alguma capability abrir.

## A transação

### Superfícies e ordem

| Superfície | Serviço | Deploy | Origem no EasyPanel | Env na spec | Como volta | Sonda pública |
| --- | --- | --- | --- | --- | --- | --- |
| backend | `cartinhas` | `manaloom_deploy_backend_image.sh` | managed | sim (e-mail herdado) | spec anterior exata | `git_sha` do `/health` |
| ops | `manaloom-ops` | `manaloom_deploy_ops_image.sh` | Swarm direto | sim | spec anterior exata | nenhuma (interno) |
| site | `manaloom-web-public` | `manaloom_deploy_public_web.sh` | detectada | sim (`GIT_SHA`) | spec anterior exata | status do `/healthz` |
| `/app` | `manaloom-app` | `manaloom_deploy_flutter_web.sh` | managed | não | spec anterior exata; senão, redeploy da imagem de antes | SHA-256 do `release.json`, ou do `flutter_bootstrap.js` na imagem antiga |
| android | `manaloom-releases` | `manaloom_publish_android_release.sh` | managed | não | como o `/app` | SHA-256 do `downloads/release.json` |

- **Ordem:** a da D-13. O ops entra logo depois do backend, cuja API ele consome, e o validador
  exige backend, site, `/app` e Android nessa ordem relativa. `--surfaces` escolhe um
  subconjunto, sempre na ordem da política.
- **Redeploy pelo EasyPanel:** só é permitido onde o env vem do EasyPanel e ele é a origem. No
  backend, no ops e no site o env vive na spec, e um redeploy o perderia; o validador recusa.

### Modos

- sem `--execute`: só descreve;
- `--execute --preflight`: só lê;
- `--execute --promote`: a transação;
- `--status`: lê só os diários locais;
- `--execute --resolve`: fecha um diário aberto depois de conferir.

O `--promote` e o `--resolve` exigem aprovação explícita e um diretório durável para o diário.
O preflight e a promoção exigem as âncoras de host e do EasyPanel.

### Preflight, só leitura

O preflight bloqueia, antes de qualquer mudança, se faltar qualquer um destes:

1. O checkout está no SHA pedido e limpo, e esse SHA é o `origin/master` (os deploys exigem).
2. O loader aceita a matriz do SHA, e o resolvedor da D-13 dá o modo (hoje, `control_plane`).
3. O snapshot de capacidade do BT-CAP-001 dá PASS, com no máximo 30 minutos. Na promoção, ele é
   obrigatório, porque os builds rodam no host.
4. A linha de base de cada superfície é reversível:
   - o serviço convergiu e tem réplicas;
   - a imagem é um digest e não há atualização em andamento;
   - o EasyPanel tem o serviço quando é a origem;
   - a sonda pública respondeu.
5. Não há transação anterior aberta: nem o marcador `EM_ANDAMENTO`, nem diário sem fim, nem
   rollback não provado.

Um preflight BLOCKED na promoção grava o diário com `begin` e `end blocked`, com os motivos, e
sai com 3.

### Diário e receipt

- **Formato:** `promocao-<sha>-<carimbo>.jsonl`, com permissão 600, em diretório durável (recusa
  `/tmp` e worktree). É encadeado: cada linha traz a sequência e o SHA-256 da anterior.
- **Quando grava:** cada passo entra no diário antes de acontecer (`surface_started` antes do
  deploy).
- **O que fica junto:**
  - o log de cada deploy (`...-<superfície>.log`, 600);
  - no fim, o resumo `promocao-<sha>-<carimbo>.json`.
- **Leitura:** o diário leva a linha de base, o SHA, o modo da D-13 e o resultado de cada
  superfície, e nenhum valor de env.

### Visibilidade de uma falha antes do receipt

Uma falha antes do receipt nunca some:

- o marcador `EM_ANDAMENTO` nasce antes do `begin` e só sai com `committed`, `rolled_back` ou
  `resolved`;
- um diário sem fim (processo morto, até por SIGKILL) ou com rollback não provado faz o
  `--status` sair com 4 ou 1;
- a próxima promoção sai com 4 enquanto existir o marcador ou um diário aberto.

### Promoção

Para cada superfície, na ordem, a ferramenta:

1. grava `surface_started`;
2. roda o deploy da superfície com `MANALOOM_RELEASE_SOURCE_SHA`;
3. confere o que o deploy disse:
   - status de sucesso e `image_digest_ref` por digest;
   - o mesmo SHA;
   - no `/app`, o mesmo modo da D-13;
   - a spec e a tarefa na imagem nova;
   - a origem do EasyPanel na imagem nova;
   - a sonda pública (o SHA novo no backend; corpo mudado no `/app` e no Android; 200 no site).

No fim, relê todas as superfícies (`converged`). Uma que mudou enquanto as seguintes subiam
derruba a transação.

### Volta (tudo ou nada)

A falha de uma superfície desfaz todas as que começaram, na ordem inversa. Para cada uma, a
ferramenta decide:

- `already`, se a identidade já é a de antes (por exemplo, o próprio script já voltou);
- `swarm_rollback` (`docker service rollback`), se a spec anterior é exatamente a da linha de
  base;
- `easypanel_redeploy` (origem de volta à imagem de antes e `deployService`), se a política
  permite;
- BLOCKED, fora desses casos, sem tocar em nada daquela superfície.

A origem do EasyPanel volta ao digest da spec de antes. A volta é provada contra a linha de
base, em dois níveis:

- `exact`: a spec inteira é igual;
- `identity`: imagem, env, réplicas, recursos, origem, env do EasyPanel e a sonda são iguais; só
  a política de update, que o EasyPanel regera, pode diferir.

O fim é `rolled_back` só com tudo provado. Com qualquer superfície sem prova, o fim é
`rollback_failed` (CRITICAL), e o marcador fica.

### Parada no meio

SIGTERM, SIGINT e SIGHUP passam pelo trap: evento `aborted` e a mesma volta. Um SIGKILL deixa o
diário sem fim e o marcador, e a transação fica visível como descrito acima.

### Resolve

Com a palavra do dono, depois de conferir à mão:

- a ferramenta relê cada superfície e só aceita cada uma na linha de base ou no promovido;
- registra qual (`resolved`, com o motivo) e tira o marcador;
- uma superfície fora desses dois estados faz o resolve recusar, com 3.

### Comandos e segredos

- **Host:** os únicos comandos da ferramenta são `docker service inspect`, `docker service ps`
  (com o formato `imagem|estado`) e `docker service rollback`.
- **EasyPanel:** só `projects.listProjectsAndServices`, `services.app.updateSourceImage` e
  `services.app.deployService`.
- **Sondas:** só GET HTTPS das URLs da política.
- **Segredos:** as leituras passam pelo redator do BT-CAP-002 antes de virar arquivo, e cada
  valor de env vira `sha256:<hex>`.

## Provas

### Testes

`server/test/release_promotion_test.py` tem 37 verdes, em cerca de 2 minutos:

- **Política (3):**
  - a versão do repositório segue a D-13;
  - dez configurações que quebrariam a transação são recusadas (ordem trocada, Android ausente,
    redeploy onde o env vive na spec, redeploy sem origem managed, spec anterior fora do
    primeiro lugar, deploy inexistente, sonda sem HTTPS, sem tudo ou nada, sem a D-13, serviço
    repetido);
  - o subconjunto mantém a ordem.
- **Lógica (9):**
  - as cinco linhas de base, tiradas das specs gravadas do BT-CAP-002, são reversíveis. O `/app`
    antigo marca pelo `flutter_bootstrap.js`, e nenhum valor de env aparece;
  - linha de base por tag, sem tarefas ou sem o EasyPanel é recusada;
  - leitura de outro serviço é recusada;
  - sonda velha não é deploy;
  - a conferência do deploy pega spec, origem, SHA, modo da D-13 e saída ilegível;
  - a decisão de volta cobre `swarm_rollback`, EasyPanel fora da origem, `easypanel_redeploy`,
    `already` e BLOCKED;
  - volta `exact` e `identity`, e o backend redeployado pelo EasyPanel perde o env e não passa;
  - a volta exige origem e sonda;
  - a convergência final pega mudança posterior.
- **Diário (5):** corrente e visibilidade, rollback não provado aberto até o resolve, diário
  truncado, linha reescrita, numeração pulada, `begin` obrigatório e status de fim conhecido.
- **Ferramenta de verdade (20):**
  - só descreve sem `--execute`;
  - o preflight só lê e vê o `control_plane`;
  - a promoção completa passa nas cinco superfícies, na ordem da D-13, sem nenhuma chamada de
    volta;
  - falha no `/app` desfaz `/app`, site, ops e backend na ordem inversa, cada um `exact`, com as
    sete chamadas esperadas e sem `aborted`;
  - o backend que falha antes de mudar não muda nada;
  - o Android com duas atualizações volta por identidade;
  - deploy mentiroso, de outro SHA ou do `/app` fora do modo não entra;
  - o script que já voltou sozinho é provado como `already`;
  - volta inexata: CRITICAL, o backend mudado por fora não é tocado, o marcador fica, `--status`
    sai com 1, a próxima promoção sai com 4, e o resolve depois do conserto tira o marcador;
  - marcador sozinho e diário com rollback não provado bloqueiam cada um;
  - superfície que muda depois de promovida desfaz tudo;
  - o resolve recusa uma produção inconsistente;
  - SIGTERM no meio é desfeito pelo trap;
  - SIGKILL: o diário fica sem fim, `--status` sai com 4, a promoção sai com 4, o resolve recusa
    o `/app` no meio e aceita depois;
  - preflight BLOCKED grava o diário e não muda nada;
  - snapshot velho bloqueia;
  - o subconjunto segue a ordem;
  - recusas antes de tudo: sem aprovação, diretório temporário, sem snapshot, SHA desconhecido,
    âncoras, checkout sujo, commit fora do `origin/master`;
  - com um loader futuro que aceite abrir capability, on sem verificação bloqueia e on
    verificada vira `product_open`;
  - matriz com capability on nunca sai como plano de controle.
- **Em todos:** só comandos e sondas da lista, só HTTPS, arquivos de diário com 600 e nenhum
  valor de env em diário, saída ou arquivo de trabalho.

### Outros testes e verificações

- `scripts/manaloom_release_capabilities_contract_test.sh`: PASS, com os casos do resolvedor.
- `server/test/flutter_web_deploy_contract_test.dart` atualizado.
- `shellcheck -x` limpo nos quatro scripts.

### Mutações

O arquivo é `mutacoes_bt_rel_001.json`, rodado na cópia de trabalho da frente. As **53
mutações foram derrubadas**:

- 25 na lógica;
- 24 no orquestrador;
- 3 no resolvedor e no deploy do `/app`, pelo contrato shell;
- 1 na política.

A primeira rodada deixou três vivas, e cada uma ganhou um teste:

- a conferência da origem do EasyPanel no deploy;
- o modo da D-13 com um loader que aceite abrir;
- a falha comum, que não pode aparecer como `aborted`.

### Gates

suíte do servidor: 406 arquivos em 11 lotes, todos com rc=0 (tags live fora); `project_logic --write`, `--check` e `--test` verdes; contrato de release `passed` (36 contratos); comparação de schema do gate tbls num banco novo: PASS (86 tables, 6 views, 100 foreign keys, 67 migrations)

## Passo do lote (produção, com a palavra do dono)

O passo está pronto no roteiro do lote, fora do repositório: seção "Promoção full-stack
(BT-REL-001)" de `~/.manaloom/coordenacao/banco/ROTEIRO_LOTE_DEPLOY_BACKUP.md`, com
`~/.manaloom/coordenacao/banco/lote_promocao.sh`.

- **`preflight`:** só lê.
- **`promote`:**
  - herda o e-mail do backend da spec, sem exibir;
  - pede a aprovação de quem chama e a do PostgreSQL para o ops;
  - para o Android, pede a evidência de observabilidade.
- **`status` e `resolve`:** para o diário aberto.

O primeiro `preflight` real confirma três premissas que o ensaio não pode provar:

- a forma da lista do EasyPanel;
- se o site tem origem no EasyPanel;
- o marcador do `/app` antigo pelo `flutter_bootstrap.js`.

## Decisões do dono

Estão em `~/.manaloom/coordenacao/receipts/decisoes-pendentes.md`:

- tudo ou nada, inclusive o reinício do backend na volta;
- o Android em transação própria enquanto o APK não estiver pronto;
- o primeiro `/app` de plano de controle;
- quem assina um resolve.
