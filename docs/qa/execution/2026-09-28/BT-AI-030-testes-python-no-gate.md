# Receipt — os testes Python do BT-AI-030 entram no gate — 2026-09-28

- **Pedido da coordenação:** incluir os testes Python do `BT-AI-030` no gate, no modo em que os
  outros testes Python do servidor já rodam, sem mudar o que o `full` exige. Entram também os
  do `db_helper`, do commit `4fafa0034`.
- **Dono no backlog:** `BT-AI-030`.
- **Frente A (servidor)**, branch `servidor/rodada2-2026-09-24`.
- Nada tocou a produção nem banco nenhum: os testes contra PostgreSQL pulam no gate.

## Por que não pelo `scripts/manaloom_local_ci.sh`

A sugestão era a etapa `run_guardrail_audits` do `scripts/manaloom_local_ci.sh`. É lá que o
`full` roda os testes dos scripts do Hermes. O arquivo está fora do digest de UI. Mas ele e o
`server/test/local_ci_contract_test.dart` fazem parte do plano de controle do escopo staged
(`BOOTSTRAP_SOURCE_PATHS` em `scripts/manaloom_staged_ui_scope.py`).

- **Consequência no pre-commit.** Um commit que toca esses arquivos é classificado como
  `AFFECTS_UI`, e o pre-commit roda a prova de UI inteira
  (`manaloom_ui_live_evidence_gate.sh --check`).
- **A prova falha hoje.** Rodei a conferência numa posse da trava, às 01:04Z, e ela falhou com
  os hashes dos manifestos de captura divergentes. O gate está recapturando.
- **Não commitei esse caminho.** O commit ficaria bloqueado, e passar por cima do hook é
  proibido. Desfiz a edição.

## O que mudou

- **`server/test/hermes_db_python_contracts_test.dart`** roda os quatro arquivos com
  `python3 -m unittest`, dentro da suíte do servidor:
  - `test_db_helper.py`;
  - `test_db_helper_pg_live.py`;
  - `test_sync_pg_target_deck_to_hermes.py`;
  - `test_sync_pg_target_deck_to_hermes_pg_live.py`.
- **É o modo em que os outros testes Python do servidor já rodam.** Os contratos do expurgo e do
  alimentador rodam do mesmo jeito, pelo `hermes_learning_purge_test.dart`, com
  `PYTHONWARNINGS=error::ResourceWarning`.
- **Onde a suíte roda:**
  - no `full` do gate local (`quality_gate.sh full`, testes do backend, com as tags `live`
    excluídas; o wrapper não tem tag);
  - no `pre-push`;
  - em todo commit da frente.
- **O `full` não passa a exigir nada novo.**
  - O `python3` e o `psycopg2` já são exigidos pela etapa `run_guardrail_audits`: o
    `test_xmage_transition_postgresql_scope_reconciliation.py` importa o `db_helper`.
  - Os arquivos contra PostgreSQL pulam como classe inteira. O wrapper passa
    `RUN_HERMES_*`, `DATABASE_URL`, `MANALOOM_POSTGRES_ENV` e as confirmações vazios e exige
    `OK (skipped=2)`. Assim, o gate nunca toca num banco, nem com essas variáveis no ambiente
    de quem roda.

## Evidência

- **O wrapper passa.** O foco dele com o `hermes_learning_purge_test.dart` deu 14 testes verdes.
  Pelo `unittest`, os quatro arquivos dão 31 testes, com 2 classes puladas.
- **O gate pega regressão.** Cada mutação abaixo foi aplicada, rodou o wrapper Dart e o arquivo
  foi restaurado e conferido byte a byte. As 4 derrubam a suíte:

| Mutação | O que muda | Suíte Dart |
| --- | --- | --- |
| M153 | o `db_helper` volta a buscar `.env` subindo diretórios | falha |
| M158 | a confirmação de leitura autoriza escrita | falha |
| M145 | o sync confere o PostgreSQL sem o lock do SQLite | falha |
| M147 | o deck da lixeira passa na conferência | falha |

## Fica para a coordenação

- **A etapa `run_guardrail_audits` do `local_ci`.** Para os testes rodarem também lá, junto com
  os outros dos scripts do Hermes, o commit precisa esperar a prova de UI voltar a passar,
  depois da recaptura. O patch é pequeno: 2 linhas no `py_compile` e 4 na lista do `unittest`,
  mais a guarda no `local_ci_contract_test.dart`. Com o wrapper Dart, isso é opcional.
