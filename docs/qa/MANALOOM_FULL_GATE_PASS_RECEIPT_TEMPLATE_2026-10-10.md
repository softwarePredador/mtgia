# Modelo de receipt G-10: de IMPLEMENTED_LOCAL_PENDING_FULL_GATE para PASS, 2026-10-10

Modelo para registrar, depois de um gate `full` verde num SHA, quais tarefas
saem de `IMPLEMENTED_LOCAL_PENDING_FULL_GATE` para `PASS`. Quem edita o
backlog, a fila e as decisões é a frente de governança. Este modelo só diz o
que o receipt cita para a edição se sustentar. Um receipt verde não autoriza
deploy, migration, escrita live nem promoção (contrato E2E).

Copie este arquivo para `docs/qa/execution/<AAAA-MM-DD>/G-10-pass-<SHA12>.md`
e preencha. Campo sem valor fica escrito "não se aplica" ou "pendente", nunca
vazio.

## Como gerar a lista

O script `scripts/manaloom_full_gate_eligibility.py` só lê. Ele lê o registry
e as raízes do digest de UI do próprio SHA, pelo Git, e não usa o worktree:

```bash
# condicional (ainda sem o receipt forte do full):
python3 scripts/manaloom_full_gate_eligibility.py --sha <SHA> > lista.md
# com o receipt forte do full (BT-GATE-002/003):
python3 scripts/manaloom_full_gate_eligibility.py --sha <SHA> \
  --receipt <raiz-duravel>/receipt.json > lista.md
# a mesma lista em JSON, para conferir:
python3 scripts/manaloom_full_gate_eligibility.py --sha <SHA> --format json
```

Classes:

| Classe | Significado | O que fazer |
| --- | --- | --- |
| `elegivel` | evidência no SHA; cada dependência em PASS ou `elegivel` nesta rodada, sem pendência declarada; rastro: pelo menos um commit da tarefa no SHA, que não seja merge, muda algo fora de `docs/`; e nenhum caminho nem commit da tarefa toca uma raiz do digest de UI | sobe para `PASS` com a linha do item 3, citando os commits da coluna "Commits da tarefa", se as dependências da rodada subirem no mesmo receipt |
| `elegivel_se_dependencia_subir` | como `elegivel`, mas uma dependência que não está em PASS pede prova de UI, não tem rastro, também é `elegivel_se_dependencia_subir` ou declara pendência | sobe só se cada dependência da coluna "Dependências abertas" subir neste mesmo receipt; se uma fica, esta fica |
| `elegivel_com_prova_ui` | evidência e rastro como em `elegivel`, dependências em PASS ou elegíveis na mesma rodada, mas um caminho citado (no aceite ou nos receipts citados) ou um commit da tarefa toca uma raiz do digest de UI | sobe só com a prova de UI no mesmo SHA (`ui-proof` verde e `PASS_VISUAL_REVIEWED`, G-08) e se as dependências da rodada subirem |
| `elegivel_sem_rastro_de_ui` | evidência e dependências como em `elegivel_com_prova_ui`, mas nenhum commit da tarefa no SHA, fora os merges, muda algo fora de `docs/`: o script não sabe se ela tocou a UI | não sobe como `elegivel`. Sobe com a prova de UI no mesmo SHA, ou com a confirmação do item 3 (cada commit da tarefa com a saída de `git show --name-only --format= -m <commit>`, sem raiz do digest), e se as dependências da rodada subirem; senão, fica |
| `bloqueada_por_dependencia` | alguma dependência fica fora de PASS | não sobe; a tabela mostra qual dependência falta e em que estado ela está |
| `commit_citado_fora_do_sha` | um commit citado no aceite não é ancestral do SHA | não sobe; conferir se o trabalho entrou por outro commit e corrigir a citação |
| `receipt_ausente_no_sha` | o receipt citado não existe no SHA | não sobe; o receipt precisa estar no SHA |
| `bloqueada_pelo_receipt` | `--receipt` foi dado e não prova o full verde neste SHA | nada sobe (saída 3) |

A prova de UI falha fechada. Os commits da tarefa vêm de três lugares:
- os citados no aceite;
- os citados dentro dos receipts que o aceite cita, lidos do SHA;
- os commits do SHA, sem merge, cuja mensagem cita o ID: direto, em faixa
  (`LC-P0-01..06`), em lista (`BT-GATE-002/003`) ou pela família no escopo do
  assunto (`fix(LC-P0): ...`).

Se um caminho citado no aceite ou nos receipts, ou um arquivo mudado por
qualquer desses commits, cai numa raiz do digest de UI, a tarefa pede a prova
de UI. Commit citado só como referência também conta: o erro fica do lado de
pedir prova a mais. Um merge citado (o `master` em que o receipt foi
conferido, por exemplo) conta para a UI pelo que traz (`git show -m`), mas
nunca como rastro. Commit citado num receipt e fora do SHA também não é
rastro. A busca nunca
prova que não existe outro commit da tarefa: quem conhece um commit que não
aparece na coluna "Commits da tarefa" cita-o no aceite e refaz a lista.

Dependência que não está em PASS e sobe nesta rodada só vale se subir neste
mesmo receipt. A coluna "Dependências abertas" mostra cada uma com a classe
dela, e a coluna "Revisar" diz "sobe só se subir no mesmo receipt". Se a
dependência fica (sem a prova de UI, sem a confirmação, com pendência
declarada ou recusada por quem revisa), a dependente fica também, e as que
dependem dela, em cadeia, qualquer que seja a classe.

A coluna "Revisar" marca o aceite que declara pendência ("Segue aberto",
"Falta:"). A elegibilidade nunca decide que a pendência fechou. Se a pendência
faz parte do aceite (por exemplo "aplicar a 074 na produção"), a tarefa fica
pendente até ela fechar, mesmo elegível.

## 1. Identidade

- SHA do full (completo): `<40 hex>`
- Branch ou tag: `<...>`
- Worktree limpo no início e no fim do gate: `sim` ou `não` (com `não`, não há
  receipt de PASS)
- `project_logic` source digest no SHA: `<64 hex>` (de
  `project_logic_manifest.json`)
- Registry: `git:<SHA>:docs/generated/TASK_REGISTRY.json`, sha256 `<64 hex>`
  (a saída do script traz os dois)
- UI source digest no SHA: `<64 hex>` (`scripts/manaloom_ui_source_digest.sh`)
- Toolchain: Flutter `<versão>`, Dart `<versão>`, Node `<versão>` e
  PostgreSQL `<versão>`
- Executor e janela: `<quem>`, `<início UTC>` a `<fim UTC>`

## 2. Prova do full verde

Use uma das duas formas e diga qual.

**A. Receipt forte** (depois do BT-GATE-003, com `gate_run_receipt` ligado no
`local_ci`):
- caminho durável do `receipt.json` (fora de `/tmp` e do worktree): `<...>`
- `schema`, `gate.id`/`gate.mode`, `status`, `gate_eligible` e
  `source.stable`: `manaloom.gate_run_receipt.v1`, `local_ci`/`full` (ou `e2e`
  ou `release`, que contêm o full), `PASS`, `true` e `true`
- validação forte num checkout do SHA, com a saída colada:
  `python3 scripts/manaloom_gate_run_receipt.py validate <receipt.json>
  --gate local_ci --mode full --require-clean` (o padrão recusa receipt com
  mais de 24 h; `--max-age-hours` muda isso, e o valor usado vai no receipt)
- `artifact_manifest_sha256`: `<64 hex>`

**B. Log do gate** (enquanto o `local_ci` não grava receipt):
- comando exato: `./scripts/manaloom_local_ci.sh full` (o mesmo do `pre-push`)
- código de saída: `0`
- caminho do log fora do worktree e sha256 dele: `<...>`, `<64 hex>`
- a primeira e a última linha do log com o SHA e o resultado
- `git status --porcelain` vazio antes e depois

Com a forma B, a lista do script sai como condicional. O receipt diz isso.

## 3. Uma linha por tarefa que sobe

| Tarefa | Classe | Evidência de implementação no SHA | Evidência de aceite | Prova de UI | Pendência declarada | Resultado |
| --- | --- | --- | --- | --- | --- | --- |
| `<ID>` | `elegivel` | os commits da coluna "Commits da tarefa" e o arquivo e o teste que provam | receipt da tarefa (`docs/qa/execution/...`) e os testes do aceite que rodaram no full | não se aplica: nenhum dos commits conferidos (`<sha9>`, ...) toca raiz do digest de UI | nenhuma | `PASS` |
| `<ID>` | `elegivel_com_prova_ui` | ... | ... | `ui-proof` verde no SHA, `latest.json` com o digest de UI do SHA e a revisão visual assinada (G-08) | ... | `PASS` ou "fica" |
| `<ID>` | `elegivel_sem_rastro_de_ui` | os commits da tarefa, achados por quem revisa | ... | a prova de UI como na linha acima, ou a confirmação: cada commit da tarefa com a saída de `git show --name-only --format= -m <commit>` colada, sem raiz do digest de UI | ... | `PASS` ou "fica" |
| `<ID>` | `elegivel_se_dependencia_subir` | como em `elegivel` | ... | como em `elegivel` | ... | `PASS` só se cada dependência da coluna "Dependências abertas" tiver a linha dela com `PASS` neste receipt; senão, "fica" |

Para cada linha:
- "Prova de UI: não se aplica" só vale para `elegivel` e
  `elegivel_se_dependencia_subir`, e sempre com os commits conferidos.
  `elegivel_sem_rastro_de_ui` nunca sobe com "não se aplica" sem a
  confirmação acima;
- a confirmação usa `git show` com `-m`. Num merge, sem o `-m`, a saída sai
  vazia e esconde o que o merge trouxe; com o `-m`, ela lista o que cada lado
  trouxe, e qualquer raiz do digest de UI nessa lista pede a prova de UI;
- a tarefa com dependência da rodada só sobe se cada uma dessas dependências
  tiver a linha dela com `PASS` neste mesmo receipt;
- o teste que prova o aceite precisa estar no inventário que o full rodou.
  Teste com tag `live` ou `live_db_write` não roda no full; ele precisa do
  receipt próprio em PostgreSQL descartável (por exemplo
  `scripts/manaloom_beta_invites_cli_db_test.sh`, ou o gate `schema` para os
  testes com `RUN_SCHEMA_DB_TESTS`);
- se o aceite pede produção (migration aplicada, job ligado, deploy), a tarefa
  só sobe com o receipt da produção daquele item. O full não prova produção;
- `BT-WEB-003` pede também o receipt same-SHA do site (a identidade
  `release.json` do site no mesmo SHA), além do full.

## 4. Tarefas que ficam

Copie da saída do script as linhas `bloqueada_por_dependencia`,
`commit_citado_fora_do_sha`, `receipt_ausente_no_sha`, as
`elegivel_sem_rastro_de_ui` sem prova de UI nem confirmação, as elegíveis com
pendência declarada e as que dependem de uma tarefa que fica (em cadeia,
inclusive as `elegivel_se_dependencia_subir`). Para cada uma, escreva o motivo
e o que destrava.

## 5. O que este receipt não prova

- Produção, deploy, migration aplicada ou capability ligada.
- Prova de UI de tarefa que tocou o digest, sem o G-08 no mesmo SHA.
- TalkBack humano, teclado físico e aparelho (BT-QA-001).

## 6. Depois do receipt (frente de governança)

Segue `docs/execution/CURRENT_QUEUE.md`, seção "Como mover o slot":
1. auditoria independente quando aplicável;
2. a linha canônica do backlog de cada tarefa que sobe, com o caminho deste
   receipt;
3. `./scripts/manaloom_project_logic.sh --write` e `--check`;
4. commit atômico pelos hooks.

Pela D-20, entre o congelamento do candidato e a promoção, este receipt espera
numa branch.
