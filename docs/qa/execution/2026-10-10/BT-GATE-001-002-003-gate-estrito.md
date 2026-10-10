# Receipt — BT-GATE-001/002/003: gate estrito, receipt forte no `local_ci`, Deck/IA/Learning no full e no release — 2026-10-10

- **Tarefa:** Frente 2, gate estrito (BT-GATE-001, BT-GATE-002 ligado ao `local_ci`, BT-GATE-003), sessão de nuvem.
- **Branch:** `claude/bt-gate-strict-receipt`, a partir de `origin/master` (`1f525a1c`).
- **Commits:** `8b0ad8cd` (BT-GATE-001 e BT-GATE-002), `75dd3b77` (BT-GATE-003), `79a66eaf` (contrato do receipt). Se o PR entrar por squash, os hashes mudam; os títulos acima identificam o conteúdo.
- **Decisões que valem aqui:** D-17 (skip vira PARTIAL inventariado, nunca silêncio; cada fatia roda uma vez; todo release exige o receipt do banco de produção em leitura) e D-18.
- **Nada tocou produção.** Nenhum `.env`, chave, túnel ou credencial foi lido. O produtor do receipt de release só rodou contra um PostgreSQL descartável em `127.0.0.1`.
- **Fora do escopo, intocado:** `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`, `scripts/manaloom_release_ops_contract_test.sh`, `app/`, `scripts/manaloom_ui_source_digest.sh` e `SOURCE_ROOTS`, `web-public/`, `docs/status/DECISOES_PENDENTES_2026-09-22.md`.

## Inventário do skip atual do Flutter

- **Qual:** `app/test/features/home/lotus_web_host_runtime_test_stub.dart`, teste `Lotus browser host runtime is covered on Chrome`, com `skip: 'Web-only runtime contract.'`. É o único `skip:`, `@Skip` ou `markTestSkipped` em `app/test` e `app/integration_test` (busca estática). Os `skip:` do `server/test` são todos de arquivos com tag `live*`, que o gate já exclui por tag e nunca roda.
- **Por quê:** `lotus_web_host_runtime_test.dart` escolhe o stub da VM ou `lotus_web_host_runtime_test_web.dart` por import condicional (`dart.library.js_interop`). Na VM do `flutter test` o contrato real do host Web não compila, então sobra o espaço reservado declarado como skip. É o "1 skipped test" que o `full` aceitava.
- **Decisão:** allowlist com motivo, dono (`frente-app-lotus`) e prazo (`review_by 2026-12-31`), em `server/config/gate_skip_allowlist.json`. Conserto não coube: o arquivo está em `app/` (fora da área desta tarefa) e a cobertura de verdade pede `flutter test --platform chrome`, um gate novo. O `follow_up` da entrada manda ligar esse comando ao gate `integration`/`web` e então remover a entrada. Entrada vencida deixa de valer e o skip volta a ser PARTIAL.
- **Limite honesto:** a identificação é estática. Esta sessão não tem Flutter 3.44.6, então o `flutter test` não rodou e o nome do teste no reporter JSON não foi confirmado em execução real. Se o reporter nomear o teste de outro jeito, o gate devolve PARTIAL (exit 3) e a entrada precisa de ajuste. É o comportamento fail-closed esperado.

## O que mudou

### BT-GATE-001 — skip estrito

1. `scripts/manaloom_gate_skip_inventory.py` (novo). `test-report` lê o JSON do reporter (`--file-reporter json:<arquivo>`) e lista cada teste pulado; `scan-log` procura marcadores `SKIP`/`SKIPPED`/`PARTIAL`, `BLOCKED` e contadores de teste pulado (`+N ~M`, `skipped=N`, `N skipped`, `All other tests passed!`) na saída de uma etapa. Códigos: 0 sem skip ou skip na allowlist; 3 PARTIAL; 2 BLOCKED. Relatório ausente, vazio, sem evento `done` ou allowlist inválida é BLOCKED, nunca sucesso.
2. `server/config/gate_skip_allowlist.json` (novo). Entrada exige `id`, `kind`, `reason`, `owner`, `added`, `review_by`; `test` casa por sufixo do arquivo e nome exato; `log_line` casa por regex.
3. `scripts/quality_gate.sh`. Todo `dart test` e `flutter test` (quick, full, performance, ui-audit, battle-lab) passa por `run_inventoried_test`/`check_skip_inventory`. "All other tests passed!" deixou de bastar: o Flutter full só passa se o inventário JSON cobrir cada skip. O `quick` do backend passou a usar o mesmo perfil determinístico do `full` (`--exclude-tags live...`), porque sem isso ele "rodava" centenas de testes `live` como skip.
4. `scripts/manaloom_local_ci.sh`. Cada etapa roda por `run_named_step`: errexit próprio, log em arquivo e o `scan-log` mesmo com exit 0. Skip fora da allowlist vira PARTIAL (a etapa fica inventariada, o gate segue e sai com 3 no fim); BLOCKED (exit 2 ou marcador) e FAIL encerram na hora. Vale para `quick` (manual e `--staged-scope`) e `full`.

### BT-GATE-002 — receipt forte no `local_ci`

1. Cada etapa nomeada grava no ledger (`steps.tsv`, formato `local-ci-v2`) id, status, exit, log e o estado-fonte capturado ao fim dela (SHA, tree e digest do worktree).
2. `scripts/manaloom_gate_run_receipt.py`: o estado-fonte ganhou `git_tree`; `PARTIAL` virou status de etapa; o check leva `source` e `log_sha256`; `finalize` rebaixa o PASS para FAIL se alguma etapa rodou em outro SHA/tree/digest (`step_source_drift`), se o catálogo do modo não está completo (`check_catalog_mismatch`) ou se há etapa sem estado-fonte; `validate` confere tudo isso de novo. Novo subcomando `reuse` (ver BT-GATE-003).
3. O fim do `full` fecha o receipt em `~/.manaloom/receipts` (ou `MANALOOM_GATE_RECEIPT_ROOT`). Sem estado-fonte inicial o gate retorna 2. O `quick --staged-scope` do pre-commit continua sem receipt e sem crédito.

### BT-GATE-003 — Deck/IA/Learning no full e no release

1. `local_ci full|e2e|release` ganhou a etapa `deck-ai-learning` (depois de `full-quality`, antes de `schema-gate`): `quality_gate.sh deck-ai-learning local` no full, `release-read-only` no release.
2. Cada fatia roda uma vez por SHA. O local_ci passa o ledger ao gate (`MANALOOM_GATE_REUSE_STEPS`); `manaloom_deck_ai_learning_gate.sh` reaproveita `project_logic.drift_check` (de `project-logic` ou `full-quality`) e `audit.operational_surface_alignment` (de `guardrail-audits`) só quando o check passou e SHA, tree e digest do worktree de agora são os do fim dele. As fatias Dart e Python de contenção **não** são reaproveitadas: aqui elas rodam sob isolamento de rede, o que o `local_ci` não faz, então a evidência não é a mesma. Os testes do servidor (`dart test`) que o `full-quality` roda e a fatia Dart de contenção do gate ainda se sobrepõem; fechar isso exige decisão do dono (ver "O que falta").
3. O `release` falha cedo com exit 2 se faltar `MANALOOM_DECK_AI_RELEASE_RECEIPT` ou `MANALOOM_NEW_SERVER_ENV`, antes de qualquer etapa, e o gate em `release-read-only` valida o receipt v2 do PostgreSQL de produção lido em modo somente leitura.
4. **Migration:** a política deixou de fixar a 058. Guarda só o piso (`required_migration_floor: 038`); o validador deriva faixa, versões e última migration de `project_logic_manifest.json` (`database.latest_migration`, hoje `076`). Assim a 077 planejada (BT-CAT-01) não exige editar a política, e a divergência entre o manifesto e o `migrate.dart` reprova. O id do check passou de `pg_schema_migrations.038_058` para `pg_schema_migrations.range`. O SQL do produtor sai do validador (`migration-status-sql`).
5. Endurecimento do produtor: `assemble-release` apaga o receipt recusado em vez de deixá-lo no disco, e `completed_at` não é mais truncado ao segundo (um artefato gerado na mesma fração de segundo derrubava o próprio receipt).
6. O produtor foi escrito e testado só contra um PostgreSQL descartável em loopback (cluster temporário, removido no fim), com o túnel trocado por um dublê que só fala com esse loopback em transação somente leitura.

## Testes e resultado (rodados nesta sessão)

| Teste | Resultado |
|---|---|
| `server/test/gate_skip_inventory_test.py` (26) | OK |
| `server/test/gate_run_receipt_test.py` (28, 8 novos) | OK |
| `server/test/local_ci_staged_scope_dispatcher_test.py` (6) | OK |
| `server/test/local_ci_strict_gate_test.py` (16, novo) | OK |
| `server/test/local_ci_strict_gate_mutation_test.py` (31 mutações, novo) | OK, todas mortas |
| `server/test/deck_ai_learning_gate_contract_test.py` (10, 3 novos) | OK |
| `server/test/deck_ai_learning_receipt_validator_test.py` (26, 3 novos) | OK |
| `server/test/deck_ai_learning_release_producer_loopback_test.py` (7, novo, PostgreSQL descartável) | OK |
| `server/test/staged_ui_scope_classifier_test.py` (15) | OK |
| `server/test/manaloom_battle_product_e2e_audit_test.py`, `new_server_pg_caller_mode_contract_test.py` | OK |
| `scripts/manaloom_errexit_lint.py` em `manaloom_local_ci.sh`, `quality_gate.sh` e no produtor | limpo |

A mutação copia o repositório para uma árvore temporária, confirma que a seleção de testes passa sem mutação, tira uma propagação (skip→PARTIAL, BLOCKED→exit 2, PARTIAL no fim, receipt final, resultado por etapa, SHA por etapa, catálogo, deck gate no full, perfil read-only no release, exigência do receipt de produção, ledger de reaproveitamento, reaproveitar etapa que não passou ou de outro estado-fonte, `--file-reporter`, runner fora do inventário, expiração da allowlist, relatório truncado, precedência do BLOCKED, 058 fixo, receipt recusado no disco, produtor pedindo escrita) e exige o teste vermelho.

## O que não rodou (e por quê)

- **Dart/Flutter:** a sessão não tem Flutter 3.44.6 nem Dart. Não rodaram `server/test/local_ci_contract_test.dart` (ganhou 1 teste, conferido só por busca de texto contra os arquivos) nem os demais testes de contrato Dart do servidor, o `flutter test`, o `melos run quality` e o próprio gate Deck/IA contra o código Dart. Nenhum desses está declarado verde.
- **`./scripts/manaloom_project_logic.sh --write` e `--check`:** exigem o par Dart/Flutter pinado; não rodaram. O manifesto e `docs/generated/*` ficam **desatualizados** neste PR e não foram editados à mão (contrato do `AGENTS.md`). O dono precisa rodar `--write`, `--check` e commitar os gerados antes do merge.
- **`local_ci full` real e o gate Deck/IA real:** não rodaram aqui. O `local_ci` foi exercido de ponta a ponta com dublês de cada etapa; a lógica de reaproveitamento do gate real foi exercida extraindo as funções do script.
- **Hooks:** o checkout da nuvem não tem os hooks locais instalados, e os commits entraram sem eles. O `local_ci` é plano de controle do escopo staged: o commit dele no checkout do dono pede a prova de UI integral do `BT-UIEV-001`. Nenhum arquivo de `SOURCE_ROOTS` mudou.
- **`quality_gate.ps1`** (caminho Windows) não foi tocado e não tem o inventário de skip.

## O que falta

1. **Receipt de produção (só depois do lote).** O receipt v2 do PostgreSQL de produção em leitura só pode ser emitido quando o lote de migrations (até a 076, com a 077 planejada) estiver aplicado na produção, com a palavra do dono e a host key aprovada. Até lá, `local_ci release` retorna 2 (BLOCKED) por desenho.
2. Primeiro receipt real do `local_ci full` verde, na máquina do dono, com o Flutter pinado.
3. Rodar `./scripts/manaloom_project_logic.sh --write` e `--check` e commitar os gerados.
4. Confirmar em execução real o nome do teste pulado do Lotus no reporter JSON, e ligar `flutter test --platform chrome` ao gate para remover a entrada da allowlist (prazo 2026-12-31).
5. Decidir a sobreposição restante do `full` com a fatia Dart de contenção do Deck/IA (hoje roda duas vezes por desenho, por causa do isolamento de rede).
6. Texto em `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`: vai num follow-up, depois do PR-B.
