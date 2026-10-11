# Roteiro da abertura da coorte beta (BT-COH-001), 2026-10-10

Roteiro executável da abertura da primeira coorte, depois do GO. Este documento
não autoriza nada. Cada escrita na produção (promoção da matriz, convites
gravados e e-mails enviados) pede a palavra do dono na hora, como manda a D-117.

Fontes:
- decisões D-16 (convite de uso único, lotes de 20 a 30, por e-mail, com
  expiração e revogável), D-56 (convite aceito verifica o e-mail) e o pacote de
  2026-10-10: itens 13 (matriz nomeada, promoção própria depois do GO; D-104),
  17 (telemetria) e 19 (conferir a entrega antes do primeiro lote);
- a matriz `cohort-2026-10` (`server/config/release_capabilities_cohort.json`)
  e o contrato que só a aceita quando `MANALOOM_RELEASE_CAPABILITY_MATRIX` a
  pede (`scripts/lib/manaloom_release_capabilities_contract.sh`), no master
  desde o #38 (S-07, `2feb843be`);
- `docs/qa/execution/2026-09-24/BT-AUTH-006-convites.md` (o que o servidor faz);
- `server/bin/beta_invites.dart` (o script do dono, com as instruções de uso no
  cabeçalho);
- `docs/MANALOOM_E2E_RELEASE_CONTRACT.md` (aprovações, read-only e conclusão de
  release).

## 0. Quem faz o quê

| Marca | Quem | O que cobre |
| --- | --- | --- |
| **[DONO]** | dono, com a palavra dele na hora | promoção, escrita na produção (convites e e-mails), lista de e-mails, conta e domínio do Resend, aparelho |
| **[AGENTE]** | agente local | testes em PostgreSQL descartável, leituras públicas por GET, conferência dos números e redação dos receipts |
| **[DONO+AGENTE]** | os dois | o agente prepara o comando e lê a saída; quem executa a escrita é o dono |

Regras que valem em todos os passos:
- nenhum e-mail em claro, código de convite ou segredo entra em receipt, log
  versionado ou conversa. O script só mostra a pista mascarada (`an***@…`);
- a lista de e-mails fica fora do repositório (por exemplo
  `~/.manaloom/coorte/lote-01.txt`) e nunca é commitada;
- pela D-20, os receipts esperam numa branch até o candidato ser promovido;
- toda saída do script termina numa linha JSON (`comando`, `modo`, `lote`,
  `resumo` e, em emitir e reenviar, `entrega`). Essa linha é a evidência que
  vai para o receipt.

## 1. Pré-condições (todas verdes antes da promoção, passo 2.3)

| # | Pré-condição | Como conferir | Quem |
| --- | --- | --- | --- |
| P1 | `BT-DEC-001`: GO assinado | receipt do GO com o SHA congelado (`<SHA_GO>`) | [DONO] |
| P2 | Produção no candidato: same-SHA, migrations do lote aplicadas (061 ou depois, com `beta_invites`), 29/29 off | passo 2.2 | [AGENTE] |
| P3 | App do candidato com o campo de convite e a leitura do `invite_code` do link (`BT-AUTH-006`, lado do app, P-01 do APP-C1) | o receipt da R2 nomeia a superfície de cadastro com convite | [AGENTE] |
| P4 | Matriz `cohort-2026-10` e contrato que só a aceita quando pedida (S-07) | já no master desde o #38 (`2feb843be`); no `<SHA_COORTE>`, `scripts/manaloom_release_capabilities_contract_test.sh` verde | [AGENTE] |
| P5 | Teste do script de convites verde no SHA da coorte | passo 3.1 | [AGENTE] |
| P6 | Telemetria do app: parecer do advogado ou app com telemetria desligada e só a ativação medida no servidor (item 17) | decisão registrada | [DONO] |
| P7 | Termos e política publicados na versão que o cadastro exige (`BT-LEGAL-ACCEPT-001`) | `GET` das páginas públicas | [AGENTE] |
| P8 | Commit da coorte no `origin/master` (`<SHA_COORTE>`), com a data da verificação decidida | passo 2.1 | [DONO+AGENTE] |

Se uma pré-condição falha, a abertura para nela. Não existe "abrir parcial".

## 2. Matriz `cohort-2026-10` e promoção própria (item 13, D-104)

A matriz da coorte está versionada em
`server/config/release_capabilities_cohort.json` (`matrix: cohort-2026-10`,
`registration_admission: invite`). Ela liga exatamente `account_registration`
(modo convite), `catalog_private`, `collection_private`, `decks_private` e
`life_counter_local`. As outras 24 capabilities continuam `off`.

O arquivo da matriz sozinho não abre nada. Quem decide o que fica ligado é a
política candidata, `server/config/release_capabilities.json`, lida do SHA da
promoção. O contrato do deploy
(`scripts/lib/manaloom_release_capabilities_contract.sh`) funciona assim:

| `MANALOOM_RELEASE_CAPABILITY_MATRIX` | O que o contrato exige da política no SHA | Fora disso |
| --- | --- | --- |
| ausente (`all-off`) | as 29 `off` e `allowed: false` | `BLOCKED: release capabilities`, saída 2 |
| `cohort-2026-10` | exatamente as cinco com `release_capability: "on"` e `allowed: true`, as outras 24 `off`; e o arquivo da matriz no mesmo SHA igual ao conjunto fixado na biblioteca | `BLOCKED`, saída 2 |
| qualquer outro nome | — | `BLOCKED: … matriz desconhecida`, saída 2 |

Com uma capability ligada, vale ainda o resolvedor da D-13: o topo da política
e ao menos uma capability ligada precisam de `live_verified_as_of` datado. Aí o
`/app` sai em `product_open`. Sem a data, o preflight da promoção e o deploy
do `/app` recusam com "capability ON com verificacao live datada ausente".

Duas consequências práticas:
- a variável não serve para o `<SHA_GO>`: com ela, a política 29/29 off é
  recusada. Ela vale só para SHAs com a política da coorte;
- depois do merge do commit da coorte, **todo** deploy desse master pede
  `MANALOOM_RELEASE_CAPABILITY_MATRIX=cohort-2026-10`. Sem a variável, o
  contrato recusa, e a falha é fechada.

A promoção é uma transação própria, depois do GO. Ela só aceita o SHA do
`origin/master`, com o checkout limpo nesse SHA.

### 2.1 O commit da coorte (`<SHA_COORTE>`) [DONO+AGENTE]

Depois do GO, um PR próprio muda a política candidata a partir da matriz
versionada. O comando é reprodutível e lê a lista do próprio arquivo da matriz:

```bash
STAMP='<AAAA-MM-DDTHH:MM:SSZ>'   # data da verificação (ver o ponto aberto abaixo)
jq --slurpfile matrix server/config/release_capabilities_cohort.json \
   --arg stamp "$STAMP" '
  .live_verified_as_of = $stamp
  | reduce $matrix[0].capabilities_on[] as $key (.;
      .capabilities[$key] += {release_capability: "on", allowed: true,
                              live_verified_as_of: $stamp})
' server/config/release_capabilities.json > "$TMPDIR/policy.json" &&
  mv "$TMPDIR/policy.json" server/config/release_capabilities.json
git diff --stat   # só server/config/release_capabilities.json: 16 linhas trocadas
```

O `jq` mantém a ordem das chaves e a indentação do arquivo. Ele troca só o
`live_verified_as_of` do topo e, nas cinco, `release_capability`, `allowed` e
`live_verified_as_of`. O `policy_version` pode ficar ou mudar: o contrato só
exige texto não vazio, e o digest já distingue as duas políticas.

Conferência local antes do PR [AGENTE]. Só lê o Git:

```bash
cat > "$TMPDIR/matriz.sh" <<'EOF'
source scripts/lib/manaloom_release_capabilities_contract.sh
manaloom_load_release_capabilities_from_git "$PWD" "$1" || exit $?
manaloom_resolve_public_app_release_mode "$MANALOOM_RELEASE_CAPABILITIES_POLICY_JSON" || exit $?
echo "$MANALOOM_RELEASE_CAPABILITY_MATRIX_NAME $MANALOOM_RELEASE_CAPABILITIES_ON_JSON $MANALOOM_PUBLIC_APP_RELEASE_MODE $MANALOOM_RELEASE_CAPABILITIES_DIGEST_SHA256"
EOF
MANALOOM_RELEASE_CAPABILITY_MATRIX=cohort-2026-10 bash "$TMPDIR/matriz.sh" <SHA_COORTE>
bash "$TMPDIR/matriz.sh" <SHA_COORTE>   # sem a variável: tem de recusar
```

Esperado:
- com a variável: `cohort-2026-10`, as cinco, `product_open` e o digest do blob;
- sem a variável: `BLOCKED: release capabilities`, saída 2.

O ensaio destes dois blocos, num repositório descartável com a política e a
biblioteca de `8f371030a`, deu exatamente esse resultado: 16 linhas trocadas,
`product_open` com a variável e `BLOCKED` sem ela. Ele também recusou outro
nome de matriz e recusou a variável sobre a política 29/29 off.

O mesmo PR acerta os testes que fixam a política canônica toda off no arquivo
real. Pela leitura de `8f371030a`, são estes:
- `server/test/release_capability_policy_test.dart`, no teste "canonical
  free-beta policy is valid and starts fully closed";
- `scripts/manaloom_release_capabilities_contract_test.sh`, que fixa o digest
  do arquivo real e o carrega sem a variável;
- `server/test/manaloom_ops_daemon_test.py`, em
  `test_all_off_policy_schedules_only_governor_catalog_and_privacy_jobs`.

O `full` dos hooks confirma se falta algum.

**Ponto aberto: a data da verificação.** Decisão do dono, registrada no PR. A
regra vigente diz que nenhum status local altera `live_verified_as_of` sem
prova same-SHA fresca (`docs/CONTEXTO_PRODUTO_ATUAL.md`). Só que as cinco nunca
estiveram ligadas na produção, e a D-13 exige a data antes de abrir. A
proposta é datar pela pista 2 do QA-001: são as jornadas da coorte no mesmo
código, com esta matriz em isolamento. A primeira prova na produção vem logo
depois, nos passos 2.4 e 3.3. Se qualquer um dos dois falha, a coorte fecha
pelo passo 6.

### 2.2 Antes: leitura pública da produção [AGENTE]

Só GET, sem credencial. Grava em `$EVID/antes/` (`EVID` é o diretório de
evidência da rodada, fora do repositório):

```bash
python3 scripts/manaloom_live_readonly_smoke.py --sha <SHA_GO> --out "$EVID/antes"
```

Esperado: `PASS`, com o mesmo `<SHA_GO>` nas superfícies, o modo
`control_plane`, o `/ready` em `ready` com a última migration do lote e
nenhuma capability permitida (`summary.json`: `capabilities.live` vazio).

### 2.3 Preflight e promoção [DONO]

A promoção segue `scripts/manaloom_promote_release.sh`, a partir de um checkout
limpo no `<SHA_COORTE>`, igual ao `origin/master`. O preflight só lê. A
promoção escreve e repassa o ambiente aos deploys de cada superfície. Por isso
a variável da matriz chega ao backend, ao ops, ao site e ao `/app`.

```bash
export MANALOOM_RELEASE_CAPABILITY_MATRIX=cohort-2026-10
scripts/manaloom_promote_release.sh --execute --preflight --sha <SHA_COORTE> \
  --capacity-snapshot <snapshot.json>
# esperado: saída 0 e "release_mode": "product_open"
# com a palavra do dono:
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
  scripts/manaloom_promote_release.sh --execute --promote --sha <SHA_COORTE> \
    --receipt-dir <dir-receipts> --capacity-snapshot <snapshot.json>
```

O deploy do ops confere a política dentro da imagem contra o conjunto que o
contrato aceitou, e lista os jobs que o daemon desse SHA agenda para essa
política (S-01). O receipt da promoção guarda o diário, o modo e o digest.

### 2.4 Depois: a matriz no ar é a `cohort-2026-10` [AGENTE]

O mesmo smoke, agora contra a lista da matriz versionada:

```bash
python3 scripts/manaloom_live_readonly_smoke.py --sha <SHA_COORTE> \
  --out "$EVID/depois" \
  --expect-allowed "$(git show <SHA_COORTE>:server/config/release_capabilities_cohort.json |
                      jq -r '.capabilities_on | join(",")')"
```

Esperado: `PASS`, com:
- `<SHA_COORTE>` no backend, no site, no `/app` e no Android, pela identidade
  same-SHA do `BT-REL-002`, só com as fontes HTTP;
- o digest no `/health` e no `/capabilities` igual ao sha256 do blob
  `server/config/release_capabilities.json` do `<SHA_COORTE>`;
- o modo `product_open`;
- `capabilities.live` igual a `capabilities.expected`, exatamente as cinco.

Qualquer diferença: parar e fechar pelo passo 6.

### 2.5 Modo de admissão [DONO]

O cadastro na produção fica em `invite`. É o padrão da produção
(`MANALOOM_REGISTRATION_ADMISSION` ausente ou `invite`); `open` abre o
cadastro para qualquer pessoa. A matriz declara `registration_admission:
invite`, mas o contrato confere só o arquivo: o modo no ar é o env do backend.
A conferência é a leitura do env da spec do backend (SSH, sem exibir valores),
feita pelo dono ou pela coordenação. Uma sonda `POST /auth/register` sem código
responde `403 invite_required`, mas conta uma tentativa no limite distribuído
por IP, ou seja, grava no banco: só com a palavra do dono.

## 3. Conferência da entrega de e-mail (item 19)

### 3.1 Teste do script em PostgreSQL descartável [AGENTE]

No SHA da coorte, nesta máquina dentro da trava FIFO:

```bash
MANALOOM_FRENTE=<frente> ~/.manaloom/coordenacao/locks/with_pubcache_lock.sh \
  scripts/manaloom_beta_invites_cli_db_test.sh
```

O script sobe um PostgreSQL 17 em `127.0.0.1` (sem socket), aplica o
`database_setup.sql` e as migrations, roda o processo real do
`beta_invites.dart` contra ele, com a entrega num webhook de teste em loopback,
e apaga o cluster no fim. Recusa rodar pelo wrapper da produção. Cobre:
- a simulação: nada gravado nem enviado, com o ensaio da entrega;
- `--aplicar` sem as aprovações: `BLOCKED`, saída 3;
- `--aplicar` sem entrega pronta: `BLOCKED`, saída 3, antes de gravar;
- o lote: 3 novos, 3 e-mails com o template `beta_invite`, link e código, e o
  banco sem o código e sem o e-mail;
- a repetição do lote: `ja_convidado`, sem e-mail novo;
- o convite expirado: `listar` mostra `expirado`, `emitir` reemite com código
  novo, e o código antigo é negado (`invite_revoked`);
- o convite usado: o código que chegou pelo webhook cria a conta com o e-mail
  verificado; depois o script responde `ja_tem_conta` em emitir e em
  reenviar, `sem_convite_aberto` em revogar, e o replay é negado
  (`invite_already_used`).

Evidência: a saída do script (contagem de testes e "cluster descartável parado
e apagado") e o SHA.

### 3.2 Ensaio da entrega na produção [DONO+AGENTE]

Emitir e reenviar fazem antes um **ensaio da entrega**. A mensagem de exemplo
passa pelo mesmo transporte e pelas mesmas validações do envio real (provedor,
configuração do Resend ou do webhook, link https e regras da produção), com um
cliente HTTP que não abre conexão. Nada sai da máquina. Com `--aplicar`, o
script para antes de gravar, com saída 3, nestes dois casos:
- a entrega não está pronta;
- o banco é o da produção (wrapper) e `ENVIRONMENT` não é `production`.

O motivo: o código do convite só existe no e-mail. Um convite gravado sem
e-mail entregue não chega a ninguém.

O e-mail da produção usa o Resend (`MANALOOM_EMAIL_DELIVERY_PROVIDER=resend` e
`RESEND_*`, na spec do backend). O dono traz essas variáveis para o processo
sem exibir nem gravar valores, do mesmo jeito da herança do deploy do backend,
e acrescenta:
- `ENVIRONMENT=production`;
- `BETA_INVITE_APP_URL`: o endereço do cadastro do `/app` que lê o
  `invite_code`. A rota sai do P-01. Sem essa variável, o link padrão é
  localhost, e o ensaio recusa com `email_action_url_invalid`.

O comando, rodado em `server/` de um checkout limpo no `<SHA_COORTE>`, pelo
wrapper de escrita aprovada (o modo read-only do wrapper não aceita este
script):

```bash
cd server
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
ENVIRONMENT=production BETA_INVITE_APP_URL='<url-do-cadastro>' \
  bin/with_new_server_pg.sh --write-approved \
  dart run bin/beta_invites.dart emitir --lote canario-<AAAAMMDD> \
    --email <endereco-do-dono-sem-conta>
```

O wrapper pede as âncoras de sempre (`MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256` e o
arquivo de ambiente do servidor) e abre um túnel próprio até o PostgreSQL da
produção. O `dart run` em `server/` também lê o `server/.env` para as chaves
que o processo não traz: por isso `ENVIRONMENT` e as variáveis de entrega vêm
sempre do processo.

Sem `--aplicar`, isso só lê o banco. Esperado:
- `Entrega (ensaio, nada saiu da máquina): pronta, resend para api.resend.com`;
- na linha JSON, `entrega.remetente_dominio` igual ao domínio verificado no
  Resend;
- `entrega.link` começa por `BETA_INVITE_APP_URL` e termina em
  `?invite_code=XXXX-XXXX-XXXX-XXXX`;
- `Com --aplicar: liberado.`;
- no `resumo`, `novo: 1`.

[AGENTE] também confere, só com consultas públicas de DNS, os registros SPF,
DKIM e DMARC do domínio do remetente (`dig +short TXT <dominio>`,
`dig +short TXT resend._domainkey.<dominio>` e
`dig +short TXT _dmarc.<dominio>`). O estado "verified" no painel do Resend
fica com o [DONO].

### 3.3 Canário [DONO]

Um convite real para um endereço do dono **sem conta** (um alias serve). Um
endereço que já tem conta recebe `ja_tem_conta` e nenhum e-mail.

1. Repita o comando do 3.2 com `--aplicar`. Esperado: saída 0, `resumo` com
   `novo: 1` e `envio_enviado: 1`.
2. Na caixa de entrada:
   - o e-mail chegou, fora do spam;
   - assunto "Seu convite para a beta do BrewTact";
   - remetente no domínio verificado;
   - o link abre o cadastro do `/app` com o código preenchido;
   - o código aparece no corpo.
3. Sem cadastrar, revogue:

   ```bash
   … dart run bin/beta_invites.dart revogar --email <endereco> \
     --motivo "canario da abertura" --aplicar
   ```

   Esperado: `revogado`.
4. Se o dono quiser provar o cadastro de ponta a ponta, emite um segundo
   canário e cadastra a conta de teste dele. Essa conta é real e fica na
   produção.

Evidência: as três linhas JSON (simulação, aplicar e revogar), o horário de
chegada e as respostas do item 2. Nunca o código.

## 4. Lotes de 20 a 30 (D-16) [DONO+AGENTE]

Para cada lote `beta-<AAAA-MM>-<letra>`:

1. **Lista** [DONO]: um e-mail por linha, em arquivo fora do repositório.
   Linhas vazias e as começadas por `#` são ignoradas. No máximo 30 e-mails
   distintos; mais que isso, o script recusa com saída 2.
2. **Simulação** [DONO]: o comando do 3.2 com
   `--lote <lote> --emails <arquivo>`. [AGENTE] lê o `resumo`. Antes de
   aplicar:
   - `email_invalido` e `repetido` voltam para a lista e são corrigidos;
   - `ja_tem_conta` sai da lista;
   - `ja_convidado` não recebe nada novo (use o item 6 para reenviar).

   A entrega tem de estar `pronta` e `Com --aplicar: liberado.`
3. **Aplicar** [DONO]: o mesmo comando com `--aplicar`. Esperado:
   - saída 0;
   - `resumo.novo + resumo.reemitir == resumo.envio_enviado`.

   Saída 1 quer dizer que alguma entrega falhou: o convite foi gravado e o
   e-mail não saiu. Para cada `falha_envio`, depois de corrigir a causa, use
   `reenviar --email <e-mail> --aplicar`. Rodar `emitir` de novo não reenvia:
   ele responde `ja_convidado`.
4. **Acompanhar** [AGENTE lê, DONO roda]:
   - `listar --lote <lote>` mostra as contagens por estado (`aberto`, `aceito`,
     `expirado`, `revogado`), sem e-mail em claro;
   - a ativação da D-47 (primeiro deck em até 24 h do cadastro) sai do
     `GET /health/commercial`, com a chave de ops;
   - os alertas de SLO e de erro seguem o `docs/runbooks/SLO_E_ALERTAS.md`.
5. **Próximo lote**: o critério é do dono. A recomendação é esperar 72 h, ou
   metade do lote aceita, sem alerta crítico aberto e sem regressão no
   Sentry.
6. **Expirados e reenvio**:
   - a validade padrão é de 14 dias (`--validade-dias` aceita de 1 a 60);
   - `emitir` com a mesma lista reemite só os expirados, com código novo, e o
     antigo deixa de valer;
   - `reenviar --email` troca o código de um convite aberto e manda de novo.
7. **Revogar a pedido**: `revogar --email <e-mail> --motivo <texto> --aplicar`
   ou `revogar --convite <id> --motivo <texto> --aplicar`. É idempotente: a
   segunda vez responde `sem_convite_aberto`.

Receipt de cada lote, `docs/qa/execution/<data>/BT-COH-001-lote-<n>.md`, com:
- SHA e política em vigor;
- as linhas JSON da simulação e do aplicar;
- a saída e as contagens do `listar`;
- o que foi reenviado ou revogado e por quê;
- nenhum e-mail em claro.

## 5. Durante a coorte

- Cada e-mail tem no máximo um convite aberto. Repetir comandos é seguro.
- Aceitar o convite verifica o e-mail (D-56). A conta já escreve deck sem o
  e-mail de verificação.
- Pedido de exclusão de conta segue o fluxo da conta (`BT-PRIV-002`). Ainda não
  existe regra de retenção para convite não aceito (digest e pista do e-mail).
  Fica aberto no `BT-AUTH-006` e precisa de decisão antes do segundo lote.

## 6. Parar a coorte ou voltar [DONO]

| Situação | Ação |
| --- | --- |
| Parar de admitir, mantendo quem já entrou | revogar os convites `aberto` do lote (`listar`, depois `revogar --convite <id>` em cada um) |
| Fechar o produto para todos | a promoção só aceita o SHA do `origin/master`, então não existe "voltar para o `<SHA_GO>`". Um PR reverte o commit da coorte (a política volta a 29/29 off), e esse SHA (`<SHA_FECHA>`) é promovido pela transação do passo 2.3 **sem** `MANALOOM_RELEASE_CAPABILITY_MATRIX`, em `control_plane`. A conferência é o smoke do passo 2.2 com `--sha <SHA_FECHA>`. As contas criadas continuam e entram no plano de controle (login, exportação, exclusão) |
| Defeito de dados | `docs/runbooks/BACKUP_E_RESTAURACAO.md`. Depois da 059, voltar é restaurar, nunca descer o backend para um SHA antigo (item 12) |

## 7. O que este roteiro não cobre

- O GO e a homologação final: `docs/qa/MANALOOM_QA_001_HOMOLOGACAO_FINAL_ROTEIRO_2026-10-10.md`.
- A política de telemetria e o parecer jurídico (item 17).
- Mudar o conjunto da matriz: a `cohort-2026-10` é a da D-104. Outro conjunto
  pede decisão do dono e um PR que mude, juntos, a biblioteca do contrato e o
  arquivo da matriz. O contrato recusa qualquer outra combinação.
