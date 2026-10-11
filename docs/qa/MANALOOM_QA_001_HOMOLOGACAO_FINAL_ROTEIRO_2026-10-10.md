# Roteiro da homologação final (BT-QA-001), 2026-10-10

Roteiro executável da passada final sobre o candidato congelado, antes do GO
(`BT-DEC-001`). Ele não muda nenhum contrato e não autoriza deploy, migration,
escrita live nem abertura de capability.

Fontes, sem editar nenhuma delas:
- `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`, critério de conclusão de release:
  build instalável, jornada crítica em aparelho, smoke live no ambiente
  aprovado, `/health`, `/ready` e SHA implantado compatíveis;
- `docs/MANALOOM_UI_LIVE_EVIDENCE_CONTRACT.md`:
  - os três níveis de prova;
  - emulador nunca vale como aparelho físico;
  - TalkBack humano e teclado Web real são verificações separadas;
  - a mesa do contador é platform view (captura por `adb screencap`);
- backlog, linha do `BT-QA-001`: capturas abertas, TalkBack, teclado,
  permissões, offline, erros e fluxos negativos; D-15 (emulador no gate e
  aparelho numa passada humana final);
- `docs/execution/waves/07-beta-release.md` (Samsung físico);
- `docs/flows/_p0/gates-qa-web.md`, seção do `BT-QA-001` (o que existe e o que
  falta);
- pacote de decisões de 2026-10-10:
  - item 2: critério do GO;
  - item 18: o teclado físico fica com um humano aqui;
  - item 20: a ordem do fecho;
  - item 23: a sessão de aparelho junto da R2.

## 0. Quem faz o quê

| Marca | Quem | Cobre |
| --- | --- | --- |
| **[DONO]** | dono (D-15) | aparelho físico, TalkBack humano, teclado físico, decisões e a sessão de leitura da produção |
| **[AGENTE]** | agente local | identidade, verificação do APK, smoke por GET, ambiente isolado em loopback, conferência das evidências e receipt |
| **[DONO+AGENTE]** | os dois | o agente prepara e confere; o dono opera o aparelho ou o navegador |

Evidência:
- toda evidência da rodada vai para `EVID=<raiz>/BT-QA-001/<AAAA-MM-DD>/`,
  fora do worktree;
- o receipt versionado vai para `docs/qa/execution/<AAAA-MM-DD>/BT-QA-001-homologacao.md`
  e cita os caminhos e o sha256 de cada arquivo (`shasum -a 256 * > SHA256SUMS`);
- vídeo fica fora do repositório, como manda o contrato de UI;
- pela D-20, o receipt espera numa branch até a promoção.

O que não se faz depois do congelamento: editar as matrizes de acessibilidade e
de teclado, o `ui_live_evidence_policy.json` ou qualquer raiz do digest de UI.
Isso muda o digest e invalida a prova do candidato. O resultado humano vai para
o receipt e para `release_checks` do `docs/qa/ui-live/latest.json`, que não é
raiz do digest.

## 1. Entrada (todas verdes, senão a homologação nem começa)

| # | Condição | Prova |
| --- | --- | --- |
| E1 | `BT-REL-003`: candidato congelado (tag), com quick, full, schema, e2e, release e segurança verdes no SHA | receipts do gate no SHA |
| E2 | `BT-UX-PROOF-001`: R2 com `PASS_VISUAL_REVIEWED` assinado pelo dono | `docs/qa/ui-live/latest.json` com o digest de UI do SHA |
| E3 | Matrizes de TalkBack e teclado re-escopadas para a beta (G-09), sem rota OFF | o PR-C com merge |
| E4 | Lote aplicado e produção no candidato (L-06), para a pista 1 | passo 3 |
| E5 | Sessão de aparelho da R2 (item 23) registrada, com o digest de UI em que rodou | receipt da sessão |

## 2. Duas pistas: onde cada coisa é homologada

Os documentos não dizem se a homologação roda sobre o `/app` implantado ou
sobre um build local (pergunta aberta no plano). A produção fica com 29/29 off
até a abertura da coorte, que é depois do GO. Logo, nenhuma jornada de produto
(decks, fichário, catálogo, contador) aparece no artefato implantado antes do
GO. A proposta são duas pistas, e a escolha final é do dono:

| Pista | O que roda | O que prova |
| --- | --- | --- |
| **1. Artefato publicado** | o `/app` da produção (Chrome e Safari) e o APK publicado em `/downloads`, contra a API da produção | instalação e atualização, identidade same-SHA, login de conta existente, plano de controle (perfil, segurança, exportação, exclusão), estados de capability OFF, permissões, offline e erros |
| **2. Jornadas da coorte em isolamento** | build do mesmo SHA, com a matriz `cohort-2026-10` num manifesto isolado (`MANALOOM_ISOLATED_RELEASE_CAPABILITIES_FILE`), contra API e PostgreSQL descartáveis em loopback, no ambiente do `scripts/manaloom_authenticated_visual_qa_isolated.sh`. Web real no Mac; Android físico por `adb reverse` para a API em loopback | cadastro por convite, catálogo, fichário, decks, contador e pós-jogo, com TalkBack e teclado |

O build da pista 2 não é o artefato publicado: ele difere só no
`API_BASE_URL`. O receipt diz isso.

O manifesto isolado da pista 2 sai da matriz versionada
(`server/config/release_capabilities_cohort.json`), pelo mesmo `jq` do passo
2.1 do roteiro da coorte
(`docs/qa/MANALOOM_COORTE_ABERTURA_ROTEIRO_2026-10-10.md`), gravado fora do
repositório. Ele liga exatamente as cinco da coorte e mais nada. A data que o
`jq` pede não muda nada no servidor isolado. O
`manaloom_authenticated_visual_qa_isolated.sh` serve de modelo só do ambiente
em loopback: o manifesto dele liga 24 capabilities, e isso não prova a
coorte. O receipt grava o sha256 do manifesto isolado e a lista ligada.

A primeira prova da matriz da coorte na produção são os passos 2.4 e 3.3 do
roteiro da coorte: o smoke depois da promoção e o canário.

## 3. Identidade da rodada [AGENTE]

```bash
SHA=$(git rev-parse <tag>^{commit})
git status --porcelain                       # vazio
scripts/manaloom_ui_source_digest.sh         # digest de UI do SHA
shasum -a 256 server/config/release_capabilities.json
jq -r .source_digest_sha256 project_logic_manifest.json
```

APK do candidato:

```bash
scripts/manaloom_verify_android_release_artifacts.sh --apk <apk> \
  --expected-package <pacote> --expected-version <versao> \
  --expected-cert-sha256 <cert> --report "$EVID/android/apk-report.json"
```

Aparelho:

```bash
adb devices -l
adb -s <id> shell getprop ro.product.model         # SM-A135M
adb -s <id> shell getprop ro.build.version.release
adb -s <id> shell getprop ro.kernel.qemu           # vazio ou 0: físico
adb -s <id> shell dumpsys package com.google.android.marvin.talkback | grep versionName
```

O que grava: `identidade.md` com o SHA, a tag, os três digests, o sha256 do APK,
o relatório do verificador e o aparelho (modelo, Android, TalkBack). Grava
também o Chrome, o Safari, o macOS e o teclado físico usado.

## 4. Smoke live somente leitura (pista 1) [AGENTE]

Roda dentro da sessão de leitura da produção que o dono autorizar (item 14).
Só GET, sem credencial:

```bash
python3 scripts/manaloom_live_readonly_smoke.py --sha "$SHA" \
  --out "$EVID/smoke-live"
```

O script lê do próprio SHA a política de promoção e a matriz e faz GET nas
fontes HTTP de identidade do backend, do site, do `/app` e do Android, mais o
`/ready` e o `/capabilities`. Depois roda o portão same-SHA do `BT-REL-002` só
com essas fontes. Esperado: `PASS`, com:
- o mesmo SHA nas quatro superfícies;
- o digest da matriz do SHA;
- o modo `control_plane`;
- `/ready` em `ready` com a última migration do lote;
- nenhuma capability permitida.

O que grava: cada corpo com status e sha256, e o `summary.json`. Um `FAIL` para
a homologação (critério 5 da conclusão de release).

Fora do escopo do agente: a leitura da spec do Swarm (`GIT_SHA` do ops e do
site), que pede SSH. Ela fica com o preflight da promoção.

## 5. Web real

### 5.1 Prova automatizada no mesmo digest [AGENTE]

```bash
./scripts/quality_gate.sh ui-proof
```

Verde no SHA, e o `latest.json` com o digest de UI do candidato. O manifesto
local de teclado por WebDriver (item 18) entra aqui, já capturado na R2.

### 5.2 Teclado físico [DONO]

Chrome e Safari no macOS, com teclado físico. No Safari, ligar "Pressionar Tab
para realçar cada item" (Ajustes > Avançado). Em cada rota de
`manual_web.required_routes` da matriz re-escopada
(`app/test/ui/fixtures/ui_keyboard_focus_matrix.json`), conferir:
- Tab e Shift+Tab;
- Enter e Espaço;
- Esc fecha o modal, e o foco volta ao botão que o abriu;
- digitação nos campos;
- foco sempre visível;
- voltar do navegador.

Pista 1 cobre login e plano de controle; pista 2, as rotas de produto.

O que grava, por navegador e rota: OK, FALHA ou NÃO SE APLICA, uma captura do
foco (`teclado-<navegador>-<rota>.png`) e uma nota curta. Uma FALHA de foco
preso ou invisível é P0.

### 5.3 Jornadas e fluxos negativos na Web [DONO+AGENTE]

Pista 2, Chrome e Safari, com 390, 1440 e 1920 de largura:

| Jornada | Esperado |
| --- | --- |
| Cadastro pelo link do convite (`?invite_code=`) | código preenchido; conta criada e verificada (D-56) |
| Convite inválido, expirado ou já usado | `invite_invalid`, `invite_expired`, `invite_already_used` com frase em português e sem conta criada |
| Login, senha errada, sessão expirada (troca de senha em outra aba derruba a sessão, `BT-AUTH-007`) | mensagens claras; nada de tela quebrada |
| Catálogo: busca, detalhe da carta | resultados e arte; vazio com estado próprio |
| Fichário: adicionar, editar e remover item | salva e reflete; a mesma carta em outro idioma não dá erro 500 |
| Decks: criar, editar carta, validar, importar lista para deck novo | salva com `If-Match` quando o app já manda (DCK-P0-01); conflito explicado |
| Rotas OFF pela URL direta (`/community`, `/decks/generate`, Battle) | "indisponível", sem quebra e sem dado |
| Offline (rede cortada no DevTools e Wi-Fi desligado) | aviso claro; nada dito como "salvo" sem salvar; volta ao normal quando a rede volta |
| Perfil: exportação e exclusão de conta (só na conta descartável) | pedido aceito e estado mostrado |

Os convites da pista 2 saem do próprio script do dono contra o banco
descartável, com a entrega num webhook de teste. Nenhum e-mail real sai. Ver o
`scripts/manaloom_beta_invites_cli_db_test.sh`, que mostra o ambiente.

O que grava: `jornadas-web.md` com uma linha por jornada, navegador e largura
(resultado e captura), mais as capturas.

## 6. Android físico (Samsung SM-A135M, D-15)

### 6.1 Instalação e atualização [DONO+AGENTE]

Pista 1:
1. Baixar o APK de `/downloads` e conferir o sha256 contra o `release.json`
   publicado.
2. Instalar por cima da versão anterior e, depois, numa instalação limpa.
3. O app abre, e o login de uma conta existente funciona.

[AGENTE] confere pelo adb:

```bash
adb -s <id> shell dumpsys package <pacote> | grep -E "versionName|versionCode|granted=true"
```

Nenhuma permissão de câmera (D-41) e nada fora da allowlist do verificador.

### 6.2 Permissões [DONO]

- O pedido de notificação (`POST_NOTIFICATIONS`): negar, e o app segue sem
  insistir; conceder; revogar em Ajustes, e o app continua.
- Nenhuma tela pede câmera ou arquivo fora de uma ação do usuário.

### 6.3 Offline e erros [DONO]

Modo avião no login, na busca do catálogo, ao salvar um deck e no meio do
contador:
- aviso claro;
- nada aparece como "salvo" sem ter salvado;
- voltar a rede refaz a ação;
- o contador segue local.

Fluxos negativos:
- senha errada;
- sessão derrubada pela troca de senha em outro aparelho (`BT-AUTH-007`);
- voltar do Android em cada tela;
- girar a tela;
- mandar para segundo plano e voltar.

### 6.4 TalkBack humano [DONO]

Item 23: a sessão completa roda junto da R2. Aqui a regra é pelo digest:
- **mesmo digest de UI da sessão da R2**: passada reduzida:
  - login;
  - home;
  - uma tela de deck;
  - entrada do contador;
  - um diálogo;
- **digest diferente**: a sessão completa de novo, nas rotas de
  `manual_screen_reader.android.required_routes` da matriz re-escopada, com as
  seis checagens:
  - ordem de leitura;
  - nome, papel e estado;
  - anúncio de região viva;
  - continuidade do foco;
  - exploração por toque;
  - texto em 200% (Ajustes > Tela > Tamanho e estilo da fonte, no máximo).

O que grava: uma linha por rota e checagem (OK, FALHA ou NÃO SE APLICA, com
nota), as capturas por `adb exec-out screencap -p` e, se houver, a gravação de
tela fora do repositório. Botão sem nome, foco que some ou anúncio que falta
numa ação principal é P0.

### 6.5 Roteiro do contador de vida no aparelho [DONO]

O contador está OFF na produção até a coorte. Ele roda na pista 2. A mesa é
platform view: capture com `adb -s <id> exec-out screencap -p > "$EVID/android/contador-<n>.png"`.
A captura da surface Flutter sai preta e não vale.

1. Conta A: abrir o contador pela home e configurar 4 jogadores, com apelidos
   e o deck. Mudar vida, veneno e dano de comandante. Girar para paisagem.
   Bloquear e desbloquear a tela. Mandar para segundo plano por 1 minuto e
   voltar. A mesa volta igual.
2. Sair da mesa pela navegação. A home só diz "pausada" quando salvou. Se
   aparecer "A mesa não foi salva", testar "Tentar salvar de novo" e
   "Continuar jogando" (`LC-P0-03`; a falha em si é provada por teste
   automatizado).
3. Sair da conta A e entrar com a conta B. B não vê nada de A: apelidos, deck,
   sessão, histórico e notas (`LC-P0-01` e `LC-P0-02`). Voltar para A: a
   sessão de A volta.
4. Partida de mais de 5 minutos e "Registrar pós-jogo". O seletor lista as
   cartas do deck (`LC-P0-05`).
5. Pós-jogo:
   - salvar uma nota;
   - uma segunda nota do mesmo pós-jogo mostra o conflito;
   - apagar a nota e reabrir: ela não volta (`LC-P0-06`).
6. TalkBack na mesa:
   - cada jogador tem nome e vida anunciados;
   - os botões de mais e menos têm nome.

O que grava: `contador.md` com o resultado de cada passo e as capturas.

## 7. O que cada passo grava

| Passo | Quem | Arquivo em `$EVID` | Bloqueia o GO se falhar |
| --- | --- | --- | --- |
| 3 identidade | [AGENTE] | `identidade.md`, `android/apk-report.json` | sim |
| 4 smoke live | [AGENTE] | `smoke-live/*.json`, `smoke-live/summary.json` | sim |
| 5.1 prova automatizada | [AGENTE] | saída do `ui-proof` | sim |
| 5.2 teclado físico | [DONO] | `teclado-*.png`, `teclado.md` | sim, em P0 |
| 5.3 jornadas Web | [DONO+AGENTE] | `jornadas-web.md`, capturas | sim, em P0 |
| 6.1 a 6.3 Android | [DONO+AGENTE] | `android/*.png`, `android.md` | sim, em P0 |
| 6.4 TalkBack | [DONO] | `talkback.md`, capturas | sim, em P0 |
| 6.5 contador | [DONO] | `contador.md`, `android/contador-*.png` | sim, em P0 |

## 8. Receipt e saída

`docs/qa/execution/<AAAA-MM-DD>/BT-QA-001-homologacao.md`:
- a identidade do passo 3 e a pista de cada passo;
- uma tabela por passo, com o resultado e o caminho das evidências, mais o
  `SHA256SUMS`;
- cada FALHA com severidade (P0 bloqueia o GO; P1 e P2 viram tarefa com dono);
- o que não rodou, como `SKIP` com o motivo. Nunca como `PASS`;
- `release_checks` do `latest.json`: `android_talkback_human`,
  `android_hardware_smoke` e `web_hardware_keyboard` saem de `pending` só com
  a sessão deste receipt no digest do candidato;
- a assinatura do dono nas partes humanas.

Saída para o `BT-DEC-001`: GO só com todos os passos em `PASS` ou com o risco
aceito por escrito pelo dono, nunca com P0 aberto. Os critérios de produção do
GO (item 2) são os do receipt do lote e do smoke do passo 4.
