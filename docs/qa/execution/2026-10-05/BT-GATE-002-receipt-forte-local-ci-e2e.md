# Receipt — BT-GATE-002: receipt forte do `local_ci` e da suíte E2E — 2026-10-05

- **Tarefa:** `BT-GATE-002` (P0 CORE), frente de servidor e release, branch
  `claude/frente-servidor-release-nknr66`, a partir de `integracao/2026-09-23` (`71ab7bd`).
- **Aceite:** receipt fresco não pode ser forjado com um check; digest no fim igual ao início;
  logs e artifacts hasheados; `/tmp` não é prova durável.
- **Decisão que vale aqui:** D-17, o receipt forte começa por Deck/IA e cresce para todos os
  fluxos. Esta rodada leva o receipt ao `local_ci` e ao E2E (linhas 13 e 14 da medição de
  `docs/flows/_p0/gates-qa-web.md`) e fecha os testes que faltavam no validador Deck/IA
  (linhas 2, 5, 9 e 11).
- **Digest de UI intacto:** nenhum arquivo das `SOURCE_ROOTS` mudou; o digest segue `8bba809c`.
- **Nada tocou a produção.**

## O que mudou

1. **`scripts/manaloom_gate_run_receipt.py` (novo).** `capture` grava o estado-fonte (SHA de 40
   hex do `HEAD`, sujo ou limpo, digest do worktree com tracked, untracked e symlink, digest e
   hash do manifesto de project logic), com a mesma captura do validador Deck/IA. `finalize`
   captura de novo e exige igualdade, copia cada log para
   `~/.manaloom/receipts/<gate>/<sha>/<run_id>/` (ou `MANALOOM_GATE_RECEIPT_ROOT`), guarda sha256 e
   tamanho, e grava o `receipt.json` (`manaloom.gate_run_receipt.v1`). `validate` refaz tudo contra
   o checkout corrente.
   - Só é `gate_eligible` com status `PASS`, todos os checks `PASS` com exit 0 e log, estado-fonte
     estável e raiz durável (fora de `/tmp`, `/var/folders`, `/dev/shm` e do worktree).
   - O `local_ci` tem catálogo fechado por modo, na ordem do script: um receipt com um check só,
     ou com a ordem trocada, não valida.
   - Raiz de evidência já existente nunca é sobrescrita.
2. **`scripts/manaloom_local_ci.sh` (pronto, fora deste commit).** O `local_ci` e o teste do
   despachante são plano de controle do escopo staged: qualquer mudança neles faz o pre-commit
   exigir a prova de UI inteira, que segue vermelha até o `BT-UIEV-001`. A ligação abaixo está
   escrita e testada (10 testes do despachante, 4 novos) e entra num commit próprio quando a prova
   de UI fechar, ou antes com a palavra do dono. Cada etapa roda por `run_named_step`, com errexit próprio e
   log em arquivo. Etapa que falha fecha um receipt `FAIL` e sai com o mesmo código. O fim fecha
   o receipt `PASS`; estado-fonte alterado durante o gate derruba o `PASS`. O
   `quick --staged-scope` do pre-commit não emite receipt, porque não concede crédito.
3. **`scripts/manaloom_e2e_suite.sh`.** Captura o estado-fonte no início e fecha o receipt no fim.
   O `summary.json` passou para `schema_version` 2 e leva `git_sha`, `source` e `receipt`;
   `gate_eligible` agora também exige o receipt elegível. Sem estado-fonte capturado, ou com
   estado-fonte alterado, o `PASS` vira `FAIL` (exit 1).
4. **`docs/project_logic_contracts.json`.** Contrato novo `manaloom_gate_run_receipt_v1` e as
   ligações novas do `manaloom_e2e_suite_v1`.

## Evidência

- `server/test/gate_run_receipt_test.py`: 20 testes. Captura num git temporário (tracked,
  untracked, symlink, SHA, sujo); ida e volta `finalize` → `validate`; raiz em `/tmp` e dentro do
  worktree inelegíveis; mudança de fonte durante o gate vira `FAIL`; drift de SHA e de project
  logic depois do gate; `--require-clean`; adulteração de log com o mesmo tamanho (pega pelo
  hash); manifesto alterado; check único forjado; catálogo reordenado; regras por check;
  frescor (velho, futuro, ordem); log trocado por symlink; raiz já existente; formato do E2E;
  catálogo do Python igual à ordem do script; código de saída do CLI.
- `server/test/local_ci_staged_scope_dispatcher_test.py` (no commit do `local_ci`): 10 testes (4 novos): o `quick` manual
  grava receipt ligado ao `HEAD` com os 6 checks; etapa que falha grava `FAIL` e mantém o
  código 7; mudança do índice durante o gate derruba o `PASS`; o `--staged-scope` não grava nada.
- `server/test/e2e_gate_status_contract_test.dart`: 8 testes (3 novos): `PASS` com SHA, digest e
  log hasheado em raiz durável; `PASS` em raiz temporária inelegível; `PASS` sem estado-fonte vira
  `FAIL`.
- `server/test/deck_ai_learning_receipt_validator_test.py`: 23 testes (5 novos): captura do
  checkout real (linha 2), adulteração de mesmo tamanho e manifesto (linha 9), regras por check
  com a mensagem de cada recusa (linha 5), receipt velho, futuro e fora de ordem (linha 11).
- `./scripts/manaloom_project_logic.sh --write`, `--check` e `--test` (41) verdes; 10 suítes de
  contrato do servidor que leem esses scripts verdes (100 testes); `manaloom_errexit_lint.py`
  limpo nos dois scripts.

## O que falta

- **Commit do `local_ci`.** Espera a prova de UI (`BT-UIEV-001`) ou a palavra do dono para
  passar sem o hook. Até lá, o teste do catálogo do `local_ci` em `gate_run_receipt_test.py` se
  declara pulado.
- **Primeiro receipt real.** O `local_ci full` ainda fica vermelho até o `BT-UIEV-001` fechar, e o
  receipt `PASS` durável sai do primeiro `full` verde, na máquina do dono ou na nuvem.
- **Deck/IA `release-read-only`** (linhas 12 e 15): o produtor exige ler o PostgreSQL de produção
  por túnel SSH com a host key aprovada, o que pede a palavra do dono, e a política está amarrada à
  `058` enquanto a integração traz da `059` à `076` (achado 12).
- **`quality_gate.sh`** sozinho segue sem receipt; o `local_ci` que o chama já grava.
