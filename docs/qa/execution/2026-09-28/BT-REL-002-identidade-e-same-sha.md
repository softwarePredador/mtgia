# Receipt — BT-REL-002: gate same-SHA e identidade de release por superfície (D-13) — 2026-09-28

- **Tarefa:** `BT-REL-002`. A decisão do dono de 2026-09-22 é a D-13: um app com digest
  divergente nega as capabilities que não conhece e pede atualização.
- **Executado por:** Frente C (banco e operação), no worktree da frente, branch
  `banco/rodada1-2026-09-24`, na rodada 4, em modo ensaio.
- **Limites:** nada tocou a produção.
  - O lado do servidor e dos scripts, fora do digest de UI, vai neste commit.
  - O lado do app é rascunho sem commit sobre a árvore do gate
    (`refs/backup/2026-09-28/gate-arvore-1312` = `679f0d35f`), em
    `~/.manaloom/coordenacao/banco/app_draft/`, como nas outras frentes.
  - `app/lib/core/config/release_capabilities.dart`, que a Frente A rascunhou, não foi tocado.

## O que mudou (commit)

| Arquivo | Mudança |
| --- | --- |
| `scripts/manaloom_release_identity_gate.py` | A lógica do portão, sem conexão (detalhe logo abaixo da tabela) |
| `server/config/release_promotion.json` (`2026-09-28.2`) | Cada superfície ganhou `identity`: de onde vem a identidade e se entra no same-SHA. O núcleo `same_sha` é backend, ops, site e `/app`; o Android fica fora do núcleo e entra no escopo só quando é promovido. Novo bloco `identity_gate` (BT-REL-002) |
| `scripts/manaloom_promote_release.py` e `.sh` | O fim da transação do BT-REL-001 roda o same-SHA (detalhe logo abaixo da tabela) |
| `scripts/manaloom_deploy_flutter_web.sh` | O `/app` compila a matriz do SHA por dart-define (`RELEASE_GIT_SHA`, `RELEASE_SURFACE=app`, `RELEASE_CAPABILITIES_DIGEST`, `RELEASE_CAPABILITIES_ALLOWED`) e embarca a identidade (detalhe logo abaixo da tabela) |
| `scripts/manaloom_build_android_release.sh` e `manaloom_publish_android_release.sh` | O Android resolve o modo da D-13, compila a mesma matriz (`RELEASE_SURFACE=android`) e embarca `product`, `surface` e `release_mode`. A publicação confere tudo isso no APK e no `downloads/release.json` |
| `scripts/manaloom_deploy_public_web.sh` | O site grava `/release.json` (produto, superfície e SHA completo) no contexto do build e o confere depois do deploy |
| `scripts/manaloom_release_identity_contract_test.sh` | O contrato dessas peças nos scripts, chamado pelo contrato de release |
| `server/test/release_identity_gate_test.py` e `server/test/release_promotion_test.py` | 12 testes novos e a promoção com identidades no plano falso (ver "Provas") |
| `docs/project_logic_contracts.json` e `docs/MAPA_OPERACIONAL_DO_PROJETO.md` | O fluxo `release_operations` e a linha da promoção conjunta |

- **O portão (`scripts/manaloom_release_identity_gate.py`):**
  - identidade esperada a partir do SHA e da matriz commitada nele: digest, modo e
    capabilities liberadas;
  - identidade normalizada de cada superfície a partir das fontes: produto, superfície, SHA
    completo, digest, modo do `/app` e flags de build;
  - comparação que falha fechado;
  - um resolvedor da D-13 em Python, conferido contra o da biblioteca shell.
- **O fim da transação:**
  - lê o núcleo e as superfícies promovidas: `/health` e `/capabilities` do backend,
    `/release.json` do site, `/app/release.json` e a identidade embarcada servida pelo `/app`,
    `downloads/release.json` do Android e o `GIT_SHA` da spec do ops e do site (redigido);
  - compara com a matriz do SHA, lida do git;
  - qualquer divergência grava `surface_failed` com os problemas e desfaz tudo, provado;
  - o evento `converged` guarda a identidade de cada superfície.
- **O `/app` (`scripts/manaloom_deploy_flutter_web.sh`):**
  - embarca a identidade (`status: release`, produto, superfície, SHA, modo, flags e matriz)
    na mesma forma da do Android e a confere no build e servida;
  - `release.json` ganha produto, superfície e o hash da identidade embarcada.

## Por que a matriz vai compilada

No Flutter Web, o asset `release-identity.json` é buscado no servidor em tempo de execução. Um
`main.dart.js` antigo em cache leria a identidade nova e se acharia atualizado: o backend novo
habilitaria código antigo. Por isso o app compara o digest recebido com o que está compilado no
próprio código (dart-define). O asset servido fica como identidade conferível de fora, pela
promoção e pelo `BT-OBS-003`.

## Regras do same-SHA

| Divergência | Resultado |
| --- | --- |
| SHA diferente numa superfície do escopo (fonte HTTP ou `GIT_SHA` da spec) | FAIL: mixed SHA |
| SHA que não é o completo (40 hex) | FAIL |
| Digest da matriz diferente do commitado no SHA, ou duas fontes da mesma superfície que discordam | FAIL: mixed digest |
| Produto diferente de `brewtact`, ou identidade de outra superfície | FAIL |
| Identidade embarcada com status diferente de `release` (build de desenvolvimento) | FAIL |
| Modo do `/app` ou do Android diferente do resolvido para o SHA | FAIL |
| Flag de build ligada com a capability dela desligada no SHA (`interactive_battle_enabled`/`battle_coach`, `battle_live_spectator_enabled`/`battle_live`, `scanner_release_enabled`/`scanner`) | FAIL |
| Fonte que não responde 200, corpo que não é JSON, campo ausente, spec sem `GIT_SHA` | FAIL (fail-closed) |

Uma promoção de subconjunto que deixe o núcleo misturado agora falha. Por exemplo, `app,backend`
com ops e site no SHA antigo: a transação desfaz o que promoveu. O Android pode seguir numa
transação própria, no mesmo SHA do núcleo.

## O lado do app (rascunho, sem commit)

Os arquivos:

- `app/lib/core/config/release_identity_gate.dart` (novo);
- `app/lib/core/widgets/release_update_banner.dart` (novo);
- `app/lib/main.dart` (cinco trechos pequenos);
- dois testes novos.

O patch é `~/.manaloom/coordenacao/banco/app_draft/patches/01-bt-rel-002-app.patch`, e
`app_lib_tocados.txt` lista cada trecho.

- **A matriz embutida:** a do dart-define. Sem digest, é build de desenvolvimento e confia no
  backend, como antes. Com digest ou lista fora do contrato, é inválido e nega tudo.
- **A regra da D-13 sobre `/capabilities`:**
  - uma capability só fica liberada se o backend a libera e este artefato a liberou no build;
    é assim que o backend novo não habilita código antigo;
  - as que este código não conhece saem;
  - as que ele conhece e o backend omitiu ficam negadas;
  - digest diferente do compilado, ou capability nova oferecida, pede atualização.
- **Como entra:** como `fetcher` do `ReleaseCapabilitiesProvider`, sem mudar o provider nem o
  parser.
- **A faixa "Nova versão disponível":** fica no topo do app. Na Web pede para recarregar a
  página; no Android, para instalar o APK novo. O "Agora não" esconde a faixa na sessão, mas a
  negação continua. A faixa não é SnackBar, diálogo nem rota.

Provas do rascunho, todas com o `flutter` na trava FIFO:

- 17 testes novos verdes;
- regressão de `test/core`, `test/ui` e dos contratos que leem o `main.dart`: 258 verdes e 2
  falhas que vêm da base. São as mesmas na base e no rascunho: o inventário de superfícies e a
  revisão focal do Jogar contra IA;
- `flutter analyze` limpo;
- 11 de 11 mutações derrubadas;
- ensaio de junção por `git apply --3way` sem conflito com o combinado da Frente A, com a série
  da Frente B e com as duas juntas.

A faixa é superfície nova de UI. Quando o lote da raia do app entrar, ela pede a prova do
`docs/MANALOOM_UI_LIVE_EVIDENCE_CONTRACT.md`.

## Provas (commit)

- **`server/test/release_identity_gate_test.py`: 12 verdes.**
  - identidade esperada e SHA ou matriz inválidos;
  - resolvedor em Python igual ao shell em 7 matrizes (all-off, aberta e verificada, sem
    verificação no topo, sem verificação na entrada, on sem permissão, off com permissão e
    vazia);
  - política de identidade (10 recusas) e o núcleo;
  - portão: release coerente, mixed SHA (fonte, spec, SHA curto, Android), mixed digest,
    modo, produto, superfície, identidade de desenvolvimento, flags, fontes ilegíveis, sem
    leitura, sem campo e sem SHA;
  - leitura `self` do ops (o `BT-OBS-003`) e códigos da CLI.
- **`server/test/release_promotion_test.py`: 39 verdes.** Os testes novos:
  - a promoção completa guarda a identidade das cinco superfícies no `converged`;
  - cinco divergências injetadas depois dos deploys desfazem a promoção, cada uma provada:
    site com SHA velho, ops com o `GIT_SHA` velho na spec, backend com outro digest, `/app` com
    flag ligada e `/app` com identidade de desenvolvimento;
  - o subconjunto `app,backend` não deixa o núcleo misturado;
  - o Android segue em transação própria.
- **`scripts/manaloom_release_identity_contract_test.sh`:** PASS, e o `shellcheck -x` dos
  scripts tocados está limpo.
- **Mutações (`mutacoes_bt_rel_002.json`):** as 32 foram derrubadas. Na primeira rodada duas
  ficaram vivas, e cada uma ganhou uma correção:
  - a política passou a exigir uma fonte de SHA por superfície;
  - o contrato do `/app` passou a contar as duas marcas de superfície.
- **Achado de passagem:** o `/bin/bash` 3.2 do macOS não sai com `set -e` num `[[ ]]` que
  falha.
  - Isso esvazia checagens pós-deploy que já existiam, por exemplo os `[[ "$APP_CODE" == "200"
    ]]` do deploy do `/app` e o `[[ "$HEALTH_BODY" == "ok" ]]` do site.
  - O contrato novo usa `|| exit`. A correção das outras ficou numa tarefa separada.

## Gates

suíte do servidor: 406 arquivos em 11 lotes, todos com rc=0 (tags live fora); `project_logic --write`, `--check` e `--test` verdes; contrato de release `passed` (36 contratos); comparação de schema do gate tbls num banco novo: PASS (86 tables, 6 views, 100 foreign keys, 67 migrations)

## Passo do lote

O same-SHA roda dentro da promoção do BT-REL-001 (`lote_promocao.sh`): não há passo novo no
roteiro. A primeira promoção real grava a identidade do site e a embarcada do `/app` pela
primeira vez. O preflight não exige identidade, porque as imagens antigas não têm; o same-SHA
roda só depois dos deploys.
