# Receipt — BT-CI-002: checagens de shell que barram no `/bin/bash` 3.2 — 2026-09-28

- **Tarefa:** `BT-CI-002`, linha registrada nesta data a pedido da coordenação (rodada 5).
  - **O achado:** saiu da mutação W04 do `BT-REL-002`. A contagem do marcador da superfície
    web passava com o valor errado.
  - **A causa:** no bash anterior ao 4.1, um `[[ ... ]]` ou `(( ... ))` solto que falha não
    encerra o script com `set -e`. Um `!` solto não encerra em versão nenhuma.
  - **O alcance:** o `/bin/bash` deste Mac é o 3.2.57, e é o único bash instalado. Então o
    `#!/usr/bin/env bash` dos scripts de deploy, promoção, ops e backup também cai nele.
- **Executado por:** Frente C (banco e operação), no worktree da frente, branch
  `banco/rodada1-2026-09-24`, em modo ensaio. Nada tocou a produção.

## O que mudou

| Arquivo | Mudança |
| --- | --- |
| `scripts/manaloom_deploy_flutter_web.sh` | As 5 checagens pós-deploy do `/app` (`/app/`, `flutter_bootstrap.js`, `release.json`, `/app/decks` e `/`) viram `[[ ... ]] \|\| postdeploy_fail "..."`. A saída não zero antes do `DEPLOY_COMMITTED=1` aciona o rollback do trap, como qualquer outra falha pós-deploy |
| `scripts/manaloom_deploy_public_web.sh` | O `healthz` do site barra com mensagem |
| `scripts/manaloom_release_capabilities_contract_test.sh` | O digest fixado da matriz barra (o digest atual confere) |
| `scripts/manaloom_release_ops_contract_test.sh` | Os 5 `! grep` soltos viram `forbid_text`, que barra, e o `[[ ! -e ... ]]` do workflow do Actions barra. O contrato roda a varredura e a prova (as linhas proibidas continuam ausentes) |
| `scripts/manaloom_errexit_lint.py` | A varredura (novo; detalhe abaixo da tabela) |
| `scripts/manaloom_errexit_lint_pending.json` | A lista fechada das 21 checagens soltas conhecidas nas raízes do digest de UI |
| `server/test/errexit_postdeploy_test.py` | 10 testes (em "Provas") |
| `docs/project_logic_contracts.json` | A varredura, a lista e o teste no fluxo `release_operations` |

- **O que a varredura lê:** o código local do script, fora de heredoc, comentário, texto
  entre aspas e `$( )`.
- **O que ela acusa:** o comando que começa com `[[`, `((` com comparação ou `!`, quando não
  está numa condição nem tem `||`, `&&` ou `|` depois.
- **O que ela não acusa:** o último comando de uma função. Ele é o retorno dela, e quem a
  chama solta sai em qualquer versão. O `}` de um grupo `{ ...; }` comum não conta como fim
  de função.
- **Com `--pending`:** falha com checagem nova numa raiz do digest e com entrada da lista que
  já não existe.

### O comportamento do 3.2, conferido no `/bin/bash` 3.2.57

| Forma, com `set -euo pipefail` | Encerra? |
| --- | --- |
| `[[ 1 == 2 ]]` solto, `{ [[ 1 == 2 ]]; }`, `(( 1 > 2 ))`, `! true` | não |
| `if true; then [[ 1 == 2 ]]; fi`, `for i in 1; do [[ 1 == 2 ]]; done` | não |
| `[ 1 = 2 ]`, `[[ 1 == 2 ]] \|\| exit 3`, `x=$( [[ 1 == 2 ]] )` | sim |
| função cujo último comando é `[[ 1 == 2 ]]` ou `! true`, chamada solta | sim |

## A varredura

Varre 131 scripts: os `.sh` de `scripts/` e de `server/bin/` com `set -e` e as bibliotecas de
`scripts/lib/`. Estão incluídos todos os de deploy, a promoção, a capacidade, os de backup e
restore e as bibliotecas que eles carregam.

- **Antes:** 13 checagens soltas fora das raízes do digest de UI:
  - `manaloom_deploy_flutter_web.sh`: 5;
  - `manaloom_deploy_public_web.sh`: 1;
  - `manaloom_release_capabilities_contract_test.sh`: 1;
  - `manaloom_release_ops_contract_test.sh`: 6.
- **Depois:** nenhuma.
- **Raízes do digest de UI:** 21 checagens soltas, que viraram a lista pendente e o
  rascunho abaixo:
  - `manaloom_play_vs_ai_e2e.sh`: 17;
  - `manaloom_authenticated_visual_qa_isolated.sh`: 4.
- **Scripts da coordenação fora do repositório:** 150 `.sh`, 41 com `set -e`, nenhum achado.

## Provas

**Pós-deploy sob o `/bin/bash` 3.2, com divergência injetada.** Os trechos reais dos dois
scripts rodam contra um `curl` falso:

| Caso | Antes (`302896c43`) | Depois |
| --- | --- | --- |
| `/app` coerente | passa | passa |
| `flutter_bootstrap.js` 500 | **passa** | barra: `/app/flutter_bootstrap.js respondeu HTTP 500` |
| `release.json` 404 | **passa** | barra: `/app/release.json respondeu HTTP 404` |
| `/app/decks` 502 com o shell em cache | **passa** | barra: `/app/decks respondeu HTTP 502` |
| `/` 503 | **passa** | barra: `/ respondeu HTTP 503` |
| `/app/` 503 com o shell em cache (30 tentativas) | **passa** | barra: `/app/ respondeu HTTP 503` |
| site coerente | passa | passa |
| site com `healthz` 200 `degraded` | **passa** | barra: `healthz publico do site nao respondeu ok` |

**`server/test/errexit_postdeploy_test.py`: 10 verdes.**
- **O lint:**
  - acusa o que não barra;
  - aceita condição, `||`, `&&`, texto entre aspas, heredoc, `$( )` e retorno de função;
  - o CLI sai com 1 e diz a linha, sem traceback.
- **O repositório:** está limpo, e os scripts de deploy, promoção, capacidade, backup e
  restore estão na varredura.
- **A lista pendente:** bate com as raízes do digest nos dois sentidos e só aceita raízes do
  digest.
- **`forbid_text`:** barra de verdade sob o `/bin/bash`.
- **O bash do Mac é mesmo o 3.2:** sem isso a prova não prova nada. Em outro bash, o teste
  vira um SKIP inventariado.
- **O pós-deploy:** o `/app` barra nas 5 divergências pela checagem, com a mensagem dela e
  sem "command not found"; o site barra no `healthz` ruim.

**Mutações (`mutacoes_bt_ci_002.json`):** as 24 foram derrubadas.
- **Deploy:** cada checagem pós-deploy do `/app` volta a ser solta; `postdeploy_fail` avisa
  e segue; o bootstrap vira um teste que sempre passa; o `healthz` volta a ser solto.
- **Contratos:** o `! grep` de volta; `forbid_text` avisa e segue; o workflow do Actions
  solto; o digest da matriz solto.
- **O lint:**
  - não vê `[[`, `((` ou `!`;
  - todo `}` vira fim de função;
  - `if` de uma linha vira continuação;
  - entrada pendente sumida passa;
  - bibliotecas fora da varredura;
  - tudo vira raiz do digest;
  - `set -e` ignorado;
  - o CLI sai 0 com achado.
- **A lista:** perde uma entrada, ou aceita um arquivo fora do digest.
- **O CLI sai 0 com achado:** esta mutação sobreviveu na primeira rodada. O teste só passava
  porque o CLI quebrava com caminho fora da raiz. O rótulo foi corrigido, e o teste passou a
  exigir a linha acusada.

## Rascunho sem commit: raízes do digest de UI e contrato E2E

`manaloom_play_vs_ai_e2e.sh` e `manaloom_authenticated_visual_qa_isolated.sh` estão no
`SOURCE_ROOTS` de `scripts/manaloom_ui_source_digest.sh`, então o conserto deles está em
rascunho, fora do repositório, em `~/.manaloom/coordenacao/banco/errexit/rascunho_digest/`.

- **Base:** a árvore do gate `679f0d35f`.
- **Patch 1:** as 21 checagens viram `... || fail_check "..."`.
- **Patch 2:** esvazia a lista pendente. Vai no mesmo commit do patch 1.
- **Conferido:** o patch aplica na árvore do gate e no HEAD; `bash -n` passa; com os dois
  patches, a varredura sai limpa e os 10 testes passam.
- **Ao aplicar:** a prova de UI, porque o digest muda.
- **Patch 3:** a regra invariante nova em `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`.
  - Esse documento é do plano de controle do escopo staged (`BOOTSTRAP_SOURCE_PATHS` de
    `scripts/manaloom_staged_ui_scope.py`), e mudar ele exige a prova de UI integral.
  - O hook barrou o commit com a prova de UI vencida, então a regra ficou em rascunho.
  - Enquanto isso, a regra está no próprio contrato: o comentário e a chamada em
    `scripts/manaloom_release_ops_contract_test.sh`.

## Gates

suíte do servidor: 406 arquivos em 11 lotes, todos com rc=0 (tags live fora); `project_logic --write`, `--check` e `--test` verdes; contrato de release `passed` (36 contratos); comparação de schema do gate tbls num banco novo: PASS (86 tables, 6 views, 100 foreign keys, 67 migrations)
