# Medição P0 CORE — Gates de qualidade, QA de aceite, decisão de rollout e web pública

- Grupo: `BT-GATE-001`, `BT-GATE-002`, `BT-GATE-003`, `BT-QA-001`, `BT-DEC-001`, `BT-WEB-001`
- Data: 2026-09-22 · checkout `codex/free-beta-release-candidate-2026-07-17` @ `d15beb05b` (árvore suja: backlog, registry, `docs/project_logic_contracts.json` e `docs/status/CURRENT_PRODUCT_DECISION.md` modificados e não commitados). **`origin/master` está em `704c2c11c` (2026-08-12), 29 commits atrás do branch; nem o baseline all-OFF `b2d3fc04f` nem nenhum código deste grupo está em master** (achado 11).
- Método: aceite lido na linha do backlog (`docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:613-618,630`, via `source_line` do registry), decomposto em asserções e conferido no código. Somente leitura: `Read`, `grep`, `git log/show/diff`, `python3` sobre JSON. Nada foi executado (sem flutter, dart test, build, servidor).
- Eixos separados: **IMPLEMENTADO** (o código existe) ≠ **PROVADO** (um teste exercita o comportamento) ≠ **ABERTO** (capability/implantação deixa alcançar). Para gates, "aberto" significa "executado de ponta a ponta no digest corrente".
- Teste "de texto" = teste que lê o script e faz `contains`/`assertIn`. Ele prova que a frase existe, não que o comportamento acontece. Onde só existe esse tipo de teste, a asserção fica `PRONTO_SEM_PROVA`.
- **Revisão adversarial aplicada em 2026-09-22** (seção final). Células alteradas levam "(rev.)". Asserções marcadas "(opcional)" estão fora do aceite literal e só entram se o dono decidir.

## Resumo do grupo

| ID | Estado declarado | Estado medido | Asserções (provado · sem prova · parcial · não encontrado) | Arquivos a tocar | Testes a escrever | Migração | Prova viva | Decisão humana | Serviço externo |
| --- | --- | --- | --- | ---: | ---: | --- | --- | --- | --- |
| `BT-GATE-001` | `EVIDENCE_REQUIRED` | **quase-la** | 3 · 5 · 2 · 1 (rev.) | 6 (rev.) | 8 (rev.) | não | sim (receipt de execução) | política de skip no `full`/Patrol | — |
| `BT-GATE-002` | `EVIDENCE_REQUIRED` | **metade** (rev.: também se o escopo for só Deck/IA) | 6 · 6 · 1 · 2 (rev.) | 7 (+4 quando a `059` entrar) | 10 (rev.) | não | sim | escopo + autorização de leitura PG | PG de produção read-only via SSH |
| `BT-GATE-003` | `TODO` | **mal-comecada** | 0 · 2 · 1 · 6 (rev.; 1 opcional) | 8 (rev.) | 6 (rev.) | não | sim | estratégia de deduplicação; release exige PG a cada vez? | PG de produção read-only (perfil release) |
| `BT-QA-001` | `BLOCKED_BY_P0` | **mal-comecada** | 1 · 0 · 5 · 4 | 7 (rev.; + capturas) | 2 (rev.) | não | sim | revisor humano TalkBack/teclado; roteiro; **re-escopo das matrizes** (rev.) | aparelho Android físico |
| `BT-DEC-001` | `BLOCKED_BY_P0` | **mal-comecada** | 0 · 1 · 5 · 2 | 3 (+4 a 8 se a coorte exigir allowlist por usuário) | 1 (+2 idem) | não | não | sim — é a própria entrega | — |
| `BT-WEB-001` | `BLOCKED_BY_P0` | **metade** (rev.: era quase-la) | 3 · 2 · 6 · 2 (rev.; 1 opcional) | 10 (rev.) | 6 (rev.) | não | sim (screenshots + deploy autorizado) | copy da metadata/Termos, `/reports`, **merge em master e deploy** (rev.) | registro npm (via `BT-WEB-003`); deploy EasyPanel |
| **Total** | | | **13 · 16 · 20 · 17** (66 asserções; 2 opcionais) (rev.) | **41** (+4 a +12 condicionais) | **33** | 0 | 5 de 6 | 6 de 6 | 4 de 6 |

Leitura rápida (rev.): `001` tem o núcleo implementado e provado por teste que executa o script, e esse teste já rodou verde no gate amplo de 2026-09-21. Falta provar os wrappers e gravar o receipt. `002` tem um validador bem construído. Porém as peças que ligam o receipt ao mundo real nunca foram exercitadas: a captura do checkout, o produtor e o catálogo de 55 checks do auditor PG. Além disso, o receipt está amarrado ao schema `058`, que `BT-DB-002` vai mudar. `003` não começou, e nem o bloco isolado tem prova além de contagem de strings. `QA-001` e `DEC-001` são processo humano sobre uma infraestrutura parcial. As matrizes de acessibilidade exigem rotas que ficarão OFF no candidato. `WEB-001` está pela metade. No branch, a landing não promete Pro nem comércio e não tem link para `/app`. Faltam ainda três coisas: a metadata, o blog e os Termos prometem IA e compartilhamento; não existe screenshot corrente nem ferramenta de captura da landing; e o único ref que o deploy aceita (`origin/master`) ainda tem a landing antiga, com `Abrir app`, marketplace e preços.

## Achados transversais

1. **Nenhum commit cita `BT-GATE-*`.** `git log --grep=BT-GATE` volta vazio. `manaloom_e2e_suite.sh` com `gate_eligible`, `server/test/e2e_gate_status_contract_test.dart`, o gate Deck/IA/Learning, o validador e a política vieram do squash `b2d3fc04f` (2026-08-13). O rebaixamento para `EVIDENCE_REQUIRED` é correto pela regra do backlog (l.736-742). O link de implementação pode apontar para `b2d3fc04f`. O que não existe é um receipt **desta** tarefa. Há, porém, evidência indireta (rev.): o gate amplo de `BT-SCP-001` registrou "46 batches de backend ... passaram" (`docs/qa/execution/2026-09-21/btscp001-gate-amplo.md`, seção "Resultado do gate"). Essas batches incluem `e2e_gate_status_contract_test.dart` e `public_web_product_contract_test.dart`. Os testes Python do validador não estão nelas.
2. **O gate amplo nunca rodou inteiro no digest corrente.** `local_ci full` morre no `npm audit` (`scripts/manaloom_public_web_smoke.sh:199`; `web-public/package.json:22`) e em seguida esbarraria em `ui_live_evidence` (receipt `docs/qa/execution/2026-09-21/btscp001-gate-amplo.md`). (rev.) **Pelo menos 13 dos 19 commits** desde `354983a1e` declaram no próprio corpo ter usado `--no-verify`. O `git log -i --grep=no-verify` devolve 16, mas `ddacd71cd` e `446f602e0` só citam o bypass de outro commit, e `b4473a98a` é ambíguo ("still needs --no-verify"). Com isso, `BT-WEB-003` e `BT-UIEV-001` são pré-requisitos de fato de qualquer receipt deste grupo, e nenhum dos seis IDs os declara.
3. **Quase toda a cobertura da área de gates é de texto.** Os arquivos são `deck_ai_learning_gate_contract_test.py` (inteiro), `public_web_product_contract_test.dart` (inteiro), `local_ci_contract_test.dart`, `e2e_gate_status_contract_test.dart:179-201` e `manaloom_release_ops_contract_test.sh` (174 linhas de `grep`/`contains`, além de rodar o detector de fixtures da web pública em `:158`). Só dois pontos têm teste que executa comportamento: o mapeador de status do E2E (`e2e_gate_status_contract_test.dart:22-177`) e o validador de receipt (`deck_ai_learning_receipt_validator_test.py`).
   - (rev.) Exemplo do risco: `deck_ai_learning_gate_contract_test.py:91` "prova" `default_transaction_read_only=on` no produtor, mas a string só existe num **comentário** (`scripts/manaloom_deck_ai_learning_release_receipt.sh:99-100`).
   - (rev.) Os testes do validador só rodam **dentro** do gate Deck/IA (`manaloom_deck_ai_learning_gate.sh:546-579`), que nenhum hook chama. Não há registro de execução verde deles.
4. **SKIP contado como PASS fora do gate Deck/IA.**
   - `quality_gate.sh full` roda o backend com `RUN_INTEGRATION_TESTS=0` (`scripts/quality_gate.sh:87-91`). (rev.) 37 arquivos de `server/test` consultam essa variável e 33 deles declaram `skipIntegration`. No total são 207 linhas `skip:` em 46 arquivos (116 só em `error_contract_test.dart`), e o gate diz "Todos os checks passaram". O `full` só declara a exclusão por tag (`quality_gate.sh:68`).
   - O `patrol-smoke` sem device sai 0 (`scripts/manaloom_patrol_smoke.sh:86-94`), e o E2E estrito registra o passo como PASS.
   - `local_ci release` omite E2E e o gate Deck/IA e imprime PASS (`scripts/manaloom_local_ci.sh:253-257,264`).
   - Só `manaloom_deck_ai_learning_gate.sh:188-194` converte teste pulado em FAIL.
5. **Receipts nascem efêmeros.** Os padrões são:
   - E2E: `/tmp/manaloom_e2e_suite_reports` (`manaloom_e2e_suite.sh:10-11`).
   - Gate Deck/IA: `/tmp/manaloom_deck_ai_learning_gate` (`manaloom_deck_ai_learning_gate.sh:6`).
   - Smoke web: `/tmp/manaloom_public_web_smoke` (`manaloom_public_web_smoke.sh:10`).
   - `local_ci`: `mktemp`, apagado no `EXIT` (`manaloom_local_ci.sh:68-75`).

   Os receipts em `docs/qa/execution/` são markdown escrito à mão.
6. **O DAG de `BT-DEC-001` está incompleto.** São 33 ancestrais, e **32 `P0 CORE` abertas ficam fora**, calculado sobre `docs/generated/TASK_REGISTRY.json` da árvore e reconferido nesta revisão. As 32 são: `BT-OFFER-001`, `BT-DOC-006`, `BT-AUTH-001/002/003/004/006`, `BT-LEGAL-ACCEPT-001`, `BT-PRIV-001/002`, `DCK-P0-00/03/04/06/07`, `BT-UX-FIX-001`, `BT-UX-KIT-001`, `BT-CAT-01/02/03`, `BT-SCN-00`, `BT-AI-029`, `SCOPE-P0-SOC-00`, `SCOPE-P0-TRD-00`, `BT-DB-002/003/004`, `BT-GATE-007`, `BT-CI-001`, `BT-UIEV-001`, `BT-WEB-001` e `BT-WEB-003`. Pelo grafo, o GO/NO-GO pode ser alcançado sem a landing, sem auth e sem privacidade. O aceite de `BT-REL-003` ("o gate resolve e exige todos os P0 core aplicáveis", backlog l.613) compensaria isso, mas esse gate não existe.
7. **Itens que agente não fecha:**
   - TalkBack humano (`app/test/ui/fixtures/ui_live_evidence_policy.json:756`: `agent_visual_review_does_not_replace_screen_reader: true`).
   - Aparelho físico.
   - Assinatura do owner.
   - Leitura read-only do PostgreSQL de produção, exigida pelos receipts `release-read-only`.
   - (rev.) Merge do branch candidato em `master` e deploy.
8. **Duplicação já existente.** (rev.) O `local_ci e2e` roda duas vezes **sete** fatias (e não cinco): o smoke web, o patrol-smoke, três subconjuntos Flutter (`decks`; `commercial/retention/growth/trades`; logs/observabilidade), subconjuntos Dart e o report-retention (detalhe em `BT-GATE-003`). O critério "cada slice roda uma vez" já é violado hoje, antes de compor o gate Deck/IA.
9. **O contrato de receipt mentia sobre o consumidor.** No `HEAD`, `docs/project_logic_contracts.json` declarava `scripts/manaloom_local_ci.sh` como consumidor de `deck_ai_learning_gate_v2`, o que é falso. A árvore de trabalho corrigiu para só `scripts/quality_gate.sh`, mas a correção não está commitada.
10. **Contagem do universo.** O registry da árvore tem 58 `P0 CORE`, das quais 55 abertas, e não as 49 da premissa. As 6 novas de 2026-09-22 incluem `BT-GATE-007` e `BT-WEB-003`, que mexem exatamente no `full` e no smoke web medidos aqui.
11. **(novo, rev.) `master` não tem nada deste grupo, e só `master` pode ser implantado.**
    - `scripts/manaloom_release_identity.sh:46-54` recusa qualquer SHA diferente de `HEAD` e de `origin/master`, e o deploy da web pública passa por ele (`scripts/manaloom_deploy_public_web.sh:235-236`).
    - `origin/master` é `704c2c11c` (2026-08-12). `git merge-base --is-ancestor b2d3fc04f origin/master` é falso, e o branch está 29 commits à frente.
    - Em master, a landing tem `Abrir app` (`web-public/src/app/page.tsx:101,267` em `origin/master`), as páginas `/marketplace`, `/decks/[id]` e `/players/[id]`, e a metadata "…relatórios compartilháveis e mercado de cartas".
    - Nenhuma tarefa do registry cobre esse merge. Ele é pré-requisito não declarado de `BT-WEB-001` (superfície), `BT-REL-003`, `BT-QA-001` e `BT-DEC-001`, e exige autorização do dono.
    - O último fetch deste clone (2026-09-21) trouxe só o branch candidato; o ref de master foi atualizado por push deste clone.
12. **(novo, rev.) O receipt forte está amarrado ao schema `058` em cinco lugares.** São eles: a política (`server/config/deck_ai_learning_gate_policy.json:13-14,36`), o SQL do produtor (`scripts/manaloom_deck_ai_learning_release_receipt.sh:125,133`), o validador (`scripts/manaloom_deck_ai_learning_receipt_validator.py:615-620,672`), o fixture do teste (`server/test/deck_ai_learning_receipt_validator_test.py:70`) e o teste de texto (`deck_ai_learning_gate_contract_test.py:96`). `BT-DB-002` ("próxima migration preservadora — `059`") faz `latest_migration` virar `059`, e a partir daí **todo** receipt `release-read-only` falha até esses arquivos serem atualizados. Nenhuma das tarefas declara essa dependência.
13. **(novo, rev.) As matrizes de acessibilidade exigem superfícies que o candidato mantém OFF.**
    - TalkBack: 5 de 12 rotas obrigatórias (`app/test/ui/fixtures/ui_accessibility_matrix.json:47`), que são `/decks/generate`, `/community` e três rotas Battle.
    - Teclado Web real: 4 de 10 rotas (`app/test/ui/fixtures/ui_keyboard_focus_matrix.json:31`), que são `/community` e três rotas Battle.
    - Essas superfícies estão OFF: Generate, social e Battle (`docs/status/CURRENT_PRODUCT_DECISION.md:60,62,64`).
    - Sem re-escopo, `BT-QA-001` não fecha com a decisão de escopo vigente.

---

## BT-GATE-001 — `SKIP/PARTIAL` nunca vira sucesso

- Estado declarado: `EVIDENCE_REQUIRED` (antes `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`, rebaixado na árvore em 2026-09-22). Dependências: nenhuma.
- Entrega: "`SKIP/PARTIAL` solicitado nunca retorna sucesso nem é apresentado como PASS."
- Aceite: "E2E/quality/local CI propagam `BLOCKED` não-zero; testes cobrem runtime/PG/Flutter omitidos."
- Contrato de referência: `docs/MANALOOM_E2E_RELEASE_CONTRACT.md:25-30,49-58,183`. O `--allow-partial` pode sair 0, mas é diagnóstico, marcado `gate_eligible=false`.

| # | Asserção | Estado | Onde está | Teste (o que afirma de verdade) | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | (rev.) O E2E estrito mapeia status em exit: `PASS=0`, `FAIL=1`, `BLOCKED=2`, `PARTIAL=3` (função) | PRONTO_E_PROVADO | `scripts/manaloom_e2e_suite.sh:537-562` (`e2e_exit_code_for_status`) | `server/test/e2e_gate_status_contract_test.dart:22-35`: faz `source` do script, chama a função com cada status em `strict-gate` e compara o stdout com 0/1/2/3. Rodou verde no gate amplo de 2026-09-21 (achado 1) | — |
| 1b | (rev., separada da 1) Precedência FAIL>BLOCKED>PARTIAL, e `main()` devolvendo o código mapeado | PRONTO_SEM_PROVA (rev.: estava embutida na linha 1 como provada) | `manaloom_e2e_suite.sh:435-445` (precedência), `:644-648` e `:651-653` (retorno de `main`) | Nenhum teste mistura classes: `:37-90` só tem SKIP, `:92-126` só um BLOCKED, e nenhum tem FAIL. Nenhum teste chama `main`. Os testes reescrevem a cauda de `main` no próprio snippet (`:56-57`, `:107-108`) | 1 teste com FAIL+BLOCKED+SKIP e 1 que execute o script inteiro com etapas stub |
| 2 | `--allow-partial` é só diagnóstico: exit 0 em PARTIAL e `gate_eligible=false` | PRONTO_E_PROVADO | `manaloom_e2e_suite.sh:51-75`, `:522`, `:636-641` | `e2e_gate_status_contract_test.dart:128-177`: executa `skip_step` e `write_summary_json` reais em modo diagnóstico e lê o `summary.json` (`result=partial`, `gate_eligible=false`, `skipped=1`). (rev.) O teste injeta `E2E_EXECUTION_POLICY` direto: o parse da flag (`:51-75`) e a mensagem `PARTIAL_DIAGNOSTIC` (`:636-641`) só têm teste de texto (`:138-142`) | Opcional: exercitar `parse_args --allow-partial` |
| 3 | Flutter runtime, server live e PG read-only omitidos viram SKIP, depois PARTIAL, depois exit 3 | PRONTO_E_PROVADO | `manaloom_e2e_suite.sh:233-238`, `:302-307`, `:201-211`, `:213-221` | `e2e_gate_status_contract_test.dart:37-90`: roda as três funções reais com env vazio e afirma exit 3, `result=partial`, `gate_eligible=false` e as três etapas com `status=skip` | As omissões de runner PG mutante (`:189-199`), live product (`:322-328`), resolution (`:355-361`) e Battle mutante (`:391-393`) não têm teste |
| 4 | Camada **solicitada** sem autorização ou pré-requisito vira BLOCKED (exit 2) | PRONTO_SEM_PROVA (rev.: era PARCIAL) | Cinco camadas, dez chamadas de `block_step`: `:241-277` (Flutter, 5), `:310-315` (server live), `:330-341` (live product, 2), `:349-354` (resolution), `:379-385` (Battle) | `e2e_gate_status_contract_test.dart:92-126` cobre só o Flutter com flag e sem token (exit 2, `result=blocked`). Isso prova o mecanismo comum (`block_step` → `BLOCKED_STEPS` → `BLOCKED` → exit 2). O código das outras quatro camadas está completo; só as guardas delas não têm teste | 4 testes, um por camada |
| 5 | `quality_gate.sh e2e` propaga o exit não-zero da suíte | PRONTO_SEM_PROVA | `scripts/quality_gate.sh:2` (`set -euo pipefail`), `:336-339`, `:539-540`, com `main` chamado fora de contexto condicional (`:563`); a mensagem final só sai depois (`:553-560`) | `e2e_gate_status_contract_test.dart:179-201` é **de texto** (`contains('--strict')`, `isNot(contains('--allow-partial'))`). O wrapper PowerShell (`scripts/quality_gate.ps1`) também só tem texto | Teste comportamental com suíte stub devolvendo 2 e 3 |
| 6 | `manaloom_local_ci.sh e2e` propaga o exit sem imprimir PASS | PRONTO_SEM_PROVA | `scripts/manaloom_local_ci.sh:2`, `:69-75` (trap preserva o status), `:209-214`, `:249-252`, `:264` | Idem, só `contains('run_strict_e2e_gate')` | Teste comportamental. Na prática o modo `e2e` roda `run_full` antes e hoje morre no `npm audit` |
| 7 | BLOCKED vindo de sub-gate sai não-zero | PRONTO_SEM_PROVA (rev.: era PARCIAL) | `manaloom_e2e_suite.sh:174-186`: `run_step` grava qualquer exit≠0 como `FAIL`, então um exit 2 de sub-gate vira FAIL=1. O aceite literal ("propagam `BLOCKED` não-zero") é atendido; perde-se só a classe | nenhum | Teste de exit aninhado. Opcional (melhoria): preservar 2 como BLOCKED, como o gate Deck/IA já faz (`manaloom_deck_ai_learning_gate.sh:198-202`) |
| 8 | Dentro do E2E estrito, nenhuma camada não executada aparece como PASS | PARCIAL | O passo "Patrol product E2E local" (`manaloom_e2e_suite.sh:579-580`) chama `patrol-smoke`. Sem `MANALOOM_RUN_PATROL_DEVICE_TESTS=1`, este imprime que o Patrol CLI não rodou e sai 0 (`scripts/manaloom_patrol_smoke.sh:33,86-94`). O E2E grava PASS, e `derive_profile` (`:82-104`) ignora essa flag. (rev.) A etapa local roda de fato (`patrolTest` com harness de widget, `app/patrol_test/manaloom_patrol_smoke_test.dart`). O defeito é a camada device não aparecer como SKIP, o que `docs/MANALOOM_E2E_RELEASE_CONTRACT.md:183` exige | nenhum | Registrar a camada device como SKIP (→ PARTIAL) quando não solicitada |
| 9 | `quality`/`local_ci` não apresentam testes ou camadas omitidos como PASS | PARCIAL | `quality_gate.sh:87-91` (33 arquivos com `skipIntegration`), `:128-135` (aceita `All other tests passed!`), `local_ci:253-257,264` (release sem E2E nem gate Deck/IA). O modelo correto já existe em `manaloom_deck_ai_learning_gate.sh:188-194`. (rev.) Leitura mais estrita que o aceite ("solicitado"), mas sustentada pelo contrato (`MANALOOM_E2E_RELEASE_CONTRACT.md:183`) | nenhum para quality/local_ci | Decisão de política: inventariar skips ou declarar a exclusão no resumo final |
| 10 | Receipt/commit na linha do backlog, com a execução no digest corrente | NAO_ENCONTRADO | Nenhum commit `BT-GATE-001`. Código e teste em `b2d3fc04f`. Nada em `docs/qa/execution/` desta tarefa. (rev.) A execução verde dos testes Dart consta só no receipt de outra tarefa (`btscp001-gate-amplo.md`) | — | Rodar `e2e_gate_status_contract_test.dart` e `./scripts/quality_gate.sh e2e` (exit ≠ 0 esperado) e gravar receipt com SHA |

**O que realmente falta.** O coração da tarefa está pronto e provado por teste que executa o script de verdade: mapeamento de exit, modo diagnóstico sem crédito de gate, e omissões de Flutter, runtime e PG virando PARTIAL. Faltam cinco coisas (rev.):

1. **Provar a precedência e o `main()` real.** Os testes recompõem a cauda de `main`, sem executá-la.
2. **Provar a propagação pelos wrappers.** Hoje ela está só no `set -e`, com teste de texto.
3. **Fechar dois vazamentos do princípio "SKIP nunca é PASS".** O Patrol device não é inventariado no E2E estrito. O `quality full` conta os skips por `RUN_INTEGRATION_TESTS=0` como verde.
4. **Opcional:** não achatar BLOCKED em FAIL.
5. **Gravar o receipt.** A tarefa pode andar já. O receipt consolidado via `local_ci e2e` depende de `BT-WEB-003` e `BT-UIEV-001`, porque `run_full` vem antes.

Trabalho restante (rev.):

- Cerca de 6 arquivos: `manaloom_e2e_suite.sh`, `manaloom_patrol_smoke.sh`, `server/test/e2e_gate_status_contract_test.dart`, `quality_gate.sh` (declarar exclusões, se a política for essa), o receipt e a linha do backlog.
- Cerca de 8 testes:
  - propagação `quality_gate.sh e2e` 2/3;
  - propagação `local_ci e2e`;
  - quatro caminhos BLOCKED faltantes;
  - precedência + `main` com etapas stub;
  - Patrol device omitido vira SKIP.

  O exit 2 aninhado é opcional.
- Sem migração. Sem serviço externo.

- Dependência declarada: nenhuma. A tarefa pode andar hoje. **Não declaradas:** `BT-WEB-003` (o passo "Public web product E2E" e o `full` falham no `npm audit`) e `BT-UIEV-001` (a `ui-audit` do `melos quality`), para qualquer receipt de ponta a ponta.
- Sobreposição:
  - `BT-GATE-007` mexe no mesmo `quality_gate.sh full`.
  - `BT-GATE-003` já tem a regra skip→FAIL dentro do gate Deck/IA.
  - `BT-REL-003` exige quick/full/e2e verdes.
  - A implementação real já existe em `b2d3fc04f` sem crédito.

---

## BT-GATE-002 — Receipt forte ligado a SHA/digest/target

- Estado declarado: `EVIDENCE_REQUIRED` (rebaixado de `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`). Depende de `BT-DOC-004` (`PASS`).
- Entrega: "Receipt forte ligado a SHA, worktree/project-logic digest, schema/target e checks nomeados."
- Aceite: "Receipt fresco não pode ser forjado com um check; digest no fim igual ao início; logs/artifacts hasheados; `/tmp` não é prova durável."
- **Ambiguidade de escopo.** `docs/BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md:538-552` situa a tarefa no receipt do gate Deck/IA/Learning. Já a ficha `docs/execution/tasks/BT-DOC-004.md:68` diz: "Exigir receipt forte de todos os fluxos; isso permanece em `BT-GATE-002`". As linhas 1 a 12 medem o gate Deck/IA; as linhas 13 e 14 medem os demais fluxos; a 15 vale para os dois escopos.

| # | Asserção | Estado | Onde está | Teste (o que afirma de verdade) | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | (rev., reescrita) O validador rejeita receipt cujo estado-fonte de início ou de fim difere do estado corrente que recebe (SHA, digests, migrations, política, cache Hermes) | PRONTO_E_PROVADO | `scripts/manaloom_deck_ai_learning_receipt_validator.py:581-620`; gate `scripts/manaloom_deck_ai_learning_gate.sh:509-511` | `server/test/deck_ai_learning_receipt_validator_test.py:245-251` (receipt válido devolve o `git_sha` corrente), `:297-313` (drift em cada `*_end` é rejeitado nominalmente) e `:315-320` (dirty rejeitado). Drift só em `*_start` não tem teste; o código é simétrico (`:600-604`) | — |
| 2 | (rev., ampliada) Captura do estado-fonte **real**: SHA de 40 hex do `HEAD` (`:144-146`), `git_dirty` (`:147-149`) e digest do worktree (diff binário vs HEAD + untracked + symlink) | PRONTO_SEM_PROVA | `validator.py:82-118`, `:134-170` | Nenhum teste chama `capture_source_state`/`worktree_digest_sha256`. O teste injeta `current_source` sintético (`validator_test.py:44-58`), então nem a checagem de 40 hex nem a leitura do checkout real executam. `deck_ai_learning_gate_contract_test.py:34,37,39` só procura a string | Teste com repositório git temporário (tracked + untracked + symlink + SHA + dirty) |
| 3 | Digest de project-logic ligado ao receipt | PRONTO_E_PROVADO | `validator.py:150-152,591`; gate `:515-517` e `--check` em `:658-662` | `validator_test.py:297-313` (subTest `project_logic_source_digest`) | O digest é lido do manifesto, não recalculado. A coerência depende do `--check` que o próprio gate roda. A captura é a da linha 2 |
| 4 | Schema/target: 038–058 aplicadas, zero pendente, identidade do alvo (sha do env + host key SSH) | PRONTO_E_PROVADO | `validator.py:211-247`, `:623-683`, `:450-578` | `validator_test.py:322-332` (identity/host key) e `:334-342` (sem `058`: "required migrations are not applied"). (rev.) `pending_versions` não vazio e `latest_applied` divergente não têm teste; são `_require_exact` iguais aos testados | Ver achado 12: amarrado ao `058` |
| 5 | (rev.) Checks nomeados: cada check com status PASS e artifacts únicos e conhecidos, catálogo na ordem, summary exato | PRONTO_SEM_PROVA (rev.: era PRONTO_E_PROVADO) | `validator.py:703-759`; `server/config/deck_ai_learning_gate_policy.json` (`release_check_ids` 56, `local_step_ids` 15); catálogo local no gate `:691-716` | Os testes cobrem só IDs duplicados (`:292-295`) e `check_count` booleano (`:366-369`). Não têm teste: check com status ≠ PASS, check sem `artifact_ids` ou com artifact desconhecido (`:720-731`), artifact exigido não referenciado (`:743-747`), catálogo reordenado e `failed_count` ≠ 0. A exatidão do catálogo contra um check está contada na linha 6 | 1 teste parametrizado; o catálogo local do gate só tem teste de texto |
| 6 | Receipt fresco não pode ser forjado com um check | PRONTO_E_PROVADO | `validator.py:735-742` (receipt), `:489-504` (auditoria PG) | `validator_test.py:253-258` (1 check: "release check catalog mismatch"), `:272-285` (auditoria com 1 check e hash recalculado: "PG audit semantic check catalog mismatch"), `:260-270` (JSON legado recusado) | — |
| 7 | Digest no fim igual ao início (TOCTOU) | PRONTO_E_PROVADO (no validador) | `validator.py:173-188`; gate `:487-517`, `:665-689` | `validator_test.py:394-411` (mudança de `worktree_digest` rejeitada: "source state changed"; dirty aceito só sem `--require-clean`) | A orquestração no gate só tem teste de texto (`gate_contract_test.py:39-41`) |
| 8 | Logs hasheados por etapa | PRONTO_SEM_PROVA | Gate `:112-147` (`record_step_json`: sha256 + tamanho de cada log) | Só texto | Teste que roda o gate com etapa stub e confere o registro |
| 9 | (rev.) Artifacts hasheados e recalculados na validação | PRONTO_SEM_PROVA (rev.: era PRONTO_E_PROVADO) | `validator.py:382-385` (tamanho, depois hash), `:405-412` (manifesto); manifesto do run local no gate `:301-320` | `validator_test.py:358-364` troca o conteúdo por `"tampered\n"`, o que muda o tamanho: a validação para no *size drift* (`:382-383`). A comparação de hash (`:384-385`) e o `artifact_manifest_sha256` (`:405-412`) **nunca executam** em teste | Teste com adulteração de mesmo tamanho e com manifesto alterado |
| 10 | `/tmp` (e o próprio worktree) não é prova durável | PRONTO_E_PROVADO | Política `temporary_path_prefixes` (`/tmp`, `/private/tmp`, `/var/tmp`, `/var/folders`…); `validator.py:299-324`; gate `:478-485` (release bloqueia) e `:322-342` (`release_eligible=false`) | `validator_test.py:371-375` (temp rejeitado), `:377-385` (dentro do worktree rejeitado) | O bloqueio no gate só tem teste de texto (`gate_contract_test.py:68`) |
| 11 | Frescor: no máximo 24 h, sem timestamp futuro, ordem de timestamps | PRONTO_SEM_PROVA | `validator.py:801-811`; gate `:7,64-67` | Nenhum teste de receipt velho ou futuro | 1–2 testes |
| 12 | O produtor canônico monta um receipt v2 válido | PRONTO_SEM_PROVA | `scripts/manaloom_deck_ai_learning_release_receipt.sh:1-176`; `validator.py:882-1047` (`assemble_release_receipt`, que revalida com `max_age_hours=1`) | `gate_contract_test.py:82-102` é de texto (e a linha 91 casa com um comentário); os testes do validador usam receipt escrito à mão | Teste de ida e volta assemble → validate. (rev.) Risco de relógio: 2 dos 3 artefatos são datados pelo `clock_timestamp()` do servidor PG (`release_receipt.sh:109,130`) e precisam cair entre `started_at`/`completed_at` locais (`validator.py:463-476`) |
| 13 | Receipt do E2E ligado a SHA/digest e durável | PARCIAL | `manaloom_e2e_suite.sh:516-532`: tem `execution_policy`/`gate_eligible`/`steps`, mas não tem `git_sha`, digest de início/fim nem hash de log; o padrão `/tmp` está em `:10-11`. O contrato `manaloom_e2e_suite_v1` (`docs/project_logic_contracts.json`) não exige SHA | — | Ligar SHA, worktree digest de início/fim e raiz durável |
| 14 | Receipt de `local_ci`/`quality_gate.sh` | NAO_ENCONTRADO | `manaloom_local_ci.sh:68-75` (RUN_DIR em `mktemp`, apagado no EXIT); `quality_gate.sh` não grava nada | — | Emitir um receipt do run |
| 15 | Receipt durável produzido e citado | NAO_ENCONTRADO | Nada em `docs/qa/execution/`. `release-read-only` exige env do servidor e host key (`release_receipt.sh:51-66`) | — | Rodar o perfil `local` (PASS_CODE_ONLY) com raiz durável e o `release-read-only` contra o PG (ver riscos abaixo) |

**O que realmente falta.** No gate Deck/IA/Learning, o validador do receipt forte está bem construído e provado por comportamento nos pontos centrais: forja de um check, TOCTOU no validador, `/tmp`, schema 058 e identidade do alvo. (rev.) O que liga esse receipt ao mundo real nunca foi exercitado:

- a captura do checkout (linha 2);
- a comparação de hash dos artefatos (linha 9);
- as regras por check (linha 5);
- o frescor (linha 11);
- o produtor (linha 12).

E, principalmente, **nunca existiu um receipt de verdade**. O receipt `release-read-only` exige ler o PostgreSQL de produção por túnel SSH, com autorização do dono. Se o escopo for "todos os fluxos", como diz a ficha de `BT-DOC-004`, falta ainda levar SHA, digest de início/fim, hash de log e raiz durável ao `summary.json` do E2E e criar um receipt para o `local_ci`.

Riscos do primeiro receipt real (rev., novos):

- **Catálogo nunca observado.** O validador exige exatamente 55 checks do auditor, todos `pass` (`validator.py:489-513`). O último relatório real do auditor no repositório tem 51 (`docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260713_post_pg866_board_wipe_neutral_auxiliary_new_server_final.md`, 2026-07-13). Os 4 restantes nunca apareceram numa saída real: `sqlite_integrity.battle_rules_competing_exact_scope`, `pg_sqlite_parity.battle_rule_oracle_hashes`, `pg_integrity.battle_rules_oracle_hash_current` e `pg_integrity.battle_rules_competing_exact_scope`.
- **Qualquer `warn` derruba o receipt.** O auditor emite `warn` em vários checks: `sqlite_integrity.deck_cards_global_card_id` (`pg_hermes_sqlite_contract_audit.py:398`), `battle_rules_trusted_oracle_hash_coverage` (`:517`), snapshot de deck sem `pg_deck_id` (`:962-967`) e `sqlite_db.empty_sibling` (`:1003-1010`, check extra fora do catálogo).
- **Paridade PG↔SQLite contra cache antigo.** Ela é medida contra o `knowledge.db` local (27,9 MB, gitignored, datado de 2026-07-16), e o produtor exige esse arquivo (`release_receipt.sh:63-66`).
- **Acoplamento ao `058`** (achado 12).

Trabalho restante:

- Cerca de 7 arquivos:
  - `validator_test.py`;
  - um teste comportamental do gate;
  - `manaloom_e2e_suite.sh`;
  - `manaloom_local_ci.sh`;
  - `docs/project_logic_contracts.json` (bindings do E2E);
  - receipt;
  - backlog.

  Se o escopo for só Deck/IA, são cerca de 4. (rev.) Somam-se 4 quando a `059` entrar: a política, o produtor, o fixture do teste e o teste de texto.
- Cerca de 10 testes (rev.):
  - captura com git temporário;
  - velho;
  - futuro;
  - ida e volta do produtor;
  - log hasheado no gate;
  - hash de mesmo tamanho e manifesto;
  - regras por check;
  - E2E com SHA/digest;
  - receipt do `local_ci`.

  Se o escopo for só Deck/IA, são 8. Sem migração.

- Dependência declarada: `BT-DOC-004`, já `PASS` e real (registry de `receipt_contracts`), então a tarefa **pode andar hoje** no código. **Não declarados:**
  - acesso read-only ao PG de produção com host key aprovada;
  - worktree limpo para `--require-clean`, que hoje está sujo;
  - (rev.) `BT-DB-002`, porque a `059` invalida a política;
  - (rev.) cache Hermes local em paridade com o PG.
- Sobreposição:
  - `BT-GATE-003`: o release exige este receipt.
  - `BT-REL-002`: identidade same-SHA por superfície.
  - `BT-DB-001`: estado real do schema 058 do alvo.

---

## BT-GATE-003 — Compor o gate Deck/IA/Learning em `local_ci full/release`

- Estado declarado: `TODO`. Depende de `BT-GATE-001` e `BT-GATE-002`.
- Entrega: "Compor gate Deck/IA/Learning no `local_ci full/release` sem duplicar suites."
- Aceite: "Pre-push cobre containment Python/Dart; release exige receipt PG/runtime aplicável; cada slice roda uma vez."

| # | Asserção | Estado | Onde está | Teste (o que afirma de verdade) | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | O bloco a compor existe: perfil `local` → `PASS_CODE_ONLY`, `release-read-only` → receipt v2, cada superfície uma vez dentro do script | PRONTO_SEM_PROVA (rev.: era PRONTO_E_PROVADO) | `scripts/manaloom_deck_ai_learning_gate.sh:1-779`; `scripts/quality_gate.sh:263-267,518-519` | Só estático. `server/test/deck_ai_learning_gate_contract_test.py:116-147` conta que cada um dos 22 caminhos aparece exatamente 2 vezes **no texto** do script. O resto do arquivo é `assertIn`, e a linha 91 passa sobre um comentário do produtor. A regra deste documento (cabeçalho) manda classificar isso como sem prova. A única execução mencionada é "observado como PASS_CODE_ONLY numa execução anterior", em `/tmp` e sem receipt (`BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md:534-538`) | Receipt de execução do perfil `local` |
| 2 | `local_ci full` (pre-push) chama o gate Deck/IA | NAO_ENCONTRADO | `scripts/manaloom_local_ci.sh:225-234`; `melos.yaml:96-98`; `.githooks/pre-push:13` | `server/test/local_ci_contract_test.dart:6-29` não menciona o gate | Estágio novo no `full` |
| 3 | O pre-push cobre o containment Python | NAO_ENCONTRADO | Os 6 `server/test/*_test.py` (promote, sync, pull, gate contract, validator, knowledge import), os 2 exportadores Hermes e o tombstone do optimizer só rodam em `manaloom_deck_ai_learning_gate.sh:546-608` (reconferido: nenhum outro script, hook ou `melos.yaml` os cita). `run_guardrail_audits` (`local_ci:131-184`) roda outros unittest | — | Compor |
| 4 | O pre-push cobre o containment Dart | PARCIAL | Os 10 arquivos rodam dentro de `run_backend_full` (`quality_gate.sh:65-93`, todos os `*_test.dart`), mas sem o sandbox de rede do gate (`:519-532`) e sem a regra skip→FAIL (`:188-194`). (rev.) Pelo menos 13 dos 19 commits recentes pularam o hook | `backend_full` não tem teste de composição | Aplicar isolamento e regra anti-skip a essa fatia |
| 5 | `local_ci release` exige receipt PG/runtime aplicável | NAO_ENCONTRADO | `local_ci:253-257` (full + battle + build Android); o mecanismo existe no gate (`:718-763`) e no validador | — | Chamar `--profile release-read-only` com `MANALOOM_DECK_AI_RELEASE_RECEIPT` |
| 6 | Cada slice roda uma vez no gate composto | NAO_ENCONTRADO | Compor ingenuamente duplica três fatias: os 10 Dart (`quality_gate.sh:73` e gate `:620-632`), o `manaloom_project_logic.sh --check` (`quality_gate.sh:326` via estágio 1 do `melos quality` e gate `:658-662`) e o `operational_surface_alignment_audit.py` (`local_ci:179-180` e gate `:650-656`). O `local_ci e2e` já duplica hoje (lista abaixo da tabela). (rev.) Não existe modo "plano" que liste as fatias de cada gate; sem ele, "uma vez" só se verifica rodando tudo ou por texto | O teste "once" (`gate_contract_test.py:116-147`) só olha dentro do script do gate | Plano de composição com deduplicação, inventário de fatias e teste entre gates |
| 7 | `local_ci` diz `PASS_CODE_ONLY` quando PG/runtime não rodou | NAO_ENCONTRADO | `local_ci:264` imprime PASS genérico. Só `quality_gate.sh:556-557` faz certo, no modo isolado | — | Resumo honesto do status composto |
| 8 | O contrato de receipt declara consumidores reais | PRONTO_SEM_PROVA | `HEAD`: `deck_ai_learning_gate_v2.consumers` incluía `local_ci` (falso). A árvore corrigiu para só `quality_gate.sh` (`docs/project_logic_contracts.json:349+`, não commitado) | `tools/project_logic/test/project_logic_generator_test.dart:922-941` checa bindings, não consumidores | Commitar e reverter quando a composição existir |
| 9 | (opcional) Decisão sobre o gate `deck-quality` (`a2d044618`) dentro ou fora | NAO_ENCONTRADO | `quality_gate.sh:231-234,500-501`; fora de `local_ci`/`melos`. (rev.) Não está no aceite; só `docs/verdade/backlog-e-fila.md:158` sugere citá-lo aqui "ou linha própria" | — | Decisão + estágio, se entrar |

Duplicação que já existe hoje no `local_ci e2e` (linha 6), (rev.) sete fatias:

| Fatia | Primeira execução | Segunda execução |
| --- | --- | --- |
| Smoke web | `quality_gate.sh:467` | `manaloom_e2e_suite.sh:582-583` |
| `patrol-smoke` | `melos.yaml:98` | `e2e_suite.sh:579-580` |
| `flutter test test/features/decks` | `quality_gate.sh:143` (suíte inteira) | `e2e_suite.sh:585-586` |
| (rev.) Flutter `commercial/retention/growth/trades` | `quality_gate.sh:143` | `e2e_suite.sh:588-589` |
| (rev.) Flutter logs/observabilidade | `quality_gate.sh:143` | `e2e_suite.sh:591-592` |
| Subconjuntos Dart | `backend_full` | `e2e_suite.sh:431-432,594-595` |
| Report-retention e o teste dele | `local_ci:153,181-183` | `scripts/manaloom_report_retention_audit.sh:8-9` |

**O que realmente falta.** A composição inteira, e (rev.) até a prova de que o bloco isolado funciona: hoje há só contagem de strings.

- O `local_ci` não chama o gate.
- O pre-push não roda nenhum teste Python de contenção de learning e roda os Dart só de carona no `backend_full`, sem as proteções do gate.
- O `release` não exige receipt de PG.
- Não há mecanismo que garanta "cada slice uma vez": compor ingenuamente duplica três fatias, e o modo `e2e` já duplica sete.

Antes de codar, é preciso decidir onde cada fatia mora: tirar os 10 Dart do `backend_full`, ou fazer o gate pular a parte Dart quando rodar composto.

Trabalho restante (rev.):

- Cerca de 8 arquivos:
  - `manaloom_local_ci.sh`;
  - `quality_gate.sh` e `manaloom_deck_ai_learning_gate.sh` (deduplicação e modo composto);
  - `deck_ai_learning_gate_policy.json` (se mudar `local_step_ids`);
  - `docs/project_logic_contracts.json`;
  - `docs/MANALOOM_E2E_RELEASE_CONTRACT.md` (matriz de gates);
  - `local_ci_contract_test.dart`;
  - `deck_ai_learning_gate_contract_test.py`.
- Cerca de 6 testes:
  - `full` chama o perfil local (comportamental, não texto);
  - `release` bloqueia sem receipt;
  - plano composto sem fatia repetida;
  - mensagem `PASS_CODE_ONLY`;
  - skip na fatia Dart composta vira FAIL;
  - receipt do perfil `local`.
- Sem migração.

- Dependência declarada: `BT-GATE-001` e `BT-GATE-002`. Elas são **formais**: as duas estão `EVIDENCE_REQUIRED` por falta de receipt, não de código, e a composição pode ser implementada já. **Não declaradas:**
  - `BT-WEB-003` e `BT-UIEV-001`: sem elas o `local_ci full` não fica verde para provar a composição;
  - acesso ao PG para o perfil de release;
  - (rev.) `BT-DB-002`, pelo acoplamento ao `058`.
- Sobreposição:
  - `BT-GATE-007` mexe no mesmo `full`, com o mesmo problema de fatia duplicada.
  - `BT-GATE-005`: rastreabilidade código→teste→gate.
  - `BT-REL-003`: full/release verdes no candidato.

---

## BT-QA-001 — Homologação Web real + Android físico

- Estado declarado: `BLOCKED_BY_P0`. Depende de `BT-REL-003` e `BT-UX-PROOF-001`.
- Entrega: "Homologação Web real + Android físico."
- Aceite: "Capturas abertas, TalkBack, teclado, permissões, offline, erros e flows negativos."
- O pacote de onda `docs/execution/waves/07-beta-release.md:61` especifica "Samsung físico" e "capturas finalizadas".

| # | Asserção | Estado | Onde está | Teste (o que afirma de verdade) | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Existe candidato congelado a homologar | NAO_ENCONTRADO | Depende de `BT-REL-003` (`BLOCKED_BY_P0`). A identidade de release exige SHA = HEAD = `origin/master` e worktree limpo (`scripts/manaloom_release_identity.sh:46-62`), e a árvore está suja. (rev.) Além disso, `origin/master` está 29 commits atrás (achado 11) | — | Candidato (inclui merge em master) |
| 2 | Capturas Web reais abertas e revisadas no digest do candidato | PARCIAL | Harness `scripts/manaloom_p0_runtime_capture.sh` (perfis web mobile/desktop/wide) + `scripts/manaloom_ui_live_evidence_gate.sh`. `docs/qa/ui-live/latest.json:4` ainda no digest `865e6041`. Receipt `docs/qa/execution/2026-09-21/btuiev001-chromedriver-e-recaptura.md:3,176-180`: 22 de 23 manifests em `8bba809c`, `latest.json` não reescrito | `app/test/ui/ui_live_evidence_policy_test.dart:12-40,304-312,780-800` valida a **estrutura** da política (três níveis obrigatórios, `reviewer_must_open_every_screenshot`, cada superfície ligada a fonte, testes e checkpoints). Não valida capturas de um candidato; o gate falha fechado | Recaptura no candidato + revisão |
| 3 | Android físico atestado por adb | PARCIAL | `manaloom_p0_runtime_capture.sh:26,156-200` (perfil `android_physical_sm_a135m`: checa `ro.kernel.qemu`, serial, modelo). 54 PNG em `app/test/ui/goldens/runtime/android_physical` (último commit `fd0397a5a`). `latest.json:249` `stale_not_claimed`, `:247` `android_hardware_smoke: pending` | — | Sessão no aparelho |
| 4 | TalkBack humano | NAO_ENCONTRADO | `latest.json:246` `pending`; `app/test/ui/fixtures/ui_live_evidence_policy.json:753-756`; `app/test/ui/fixtures/ui_accessibility_matrix.json:44-50`. (rev.) São 12 rotas × 6 checagens humanas (ordem de leitura, nome/papel/estado, live region, continuidade de foco, exploração por toque, texto 200%) = 72 verificações, com 9 superfícies pendentes; 5 das 12 rotas são superfícies OFF (achado 13) | `app/test/ui/ui_accessibility_matrix_test.dart:142-150` afirma que o status **continua** `pending_physical`, que `evidence` é nulo e que `completed_surface_ids` está vazio: prova que não foi feito. (rev.) O teste **quebra** quando a revisão for registrada e terá de ser reescrito | Revisor humano + re-escopo das rotas + reescrever o teste |
| 5 | Teclado: matriz automatizada | PRONTO_E_PROVADO | `app/test/ui/ui_keyboard_focus_matrix_test.dart` + `fixtures/ui_keyboard_focus_matrix.json` | (rev., citação corrigida) A prova está nos widget tests `ui_keyboard_focus_matrix_test.dart:238-390`, que enviam Tab, Shift+Tab, Enter, Espaço e Esc e afirmam o foco; `reduced_motion` fica em `app/test/features/home/home_screen_test.dart:424-435`. As linhas `:39-60` são só um meta-teste que confere nome e âncora. É widget test, não hardware nem homologação; `visible_focus` só checa o tema (`:384-387`) | — |
| 6 | Teclado real na Web | NAO_ENCONTRADO | `latest.json:250` `web_hardware_keyboard: pending`; o backlog (DoD §5.3.7) exige gate separado. (rev.) `ui_keyboard_focus_matrix.json:25,30-31`: `manual_web` segue `pending`, com as 3 rotas Battle faltando, e 4 das 10 rotas exigidas estão OFF no candidato | — | Sessão com teclado físico + re-escopo das rotas |
| 7 | Permissões | PARCIAL | O manifesto de release remove câmera (`app/android/app/src/release/AndroidManifest.xml:4-15`), e o verificador de APK rejeita câmera e permissões fora da allowlist (`scripts/manaloom_verify_android_release_artifacts.sh:92-119`). `permission_denied` existe só como estado sintético (`ui_live_evidence_policy.json:650`, `synthetic_contract_state`). O prompt real de `POST_NOTIFICATIONS` (`app/android/app/src/main/AndroidManifest.xml:4`) não foi homologado | O verificador é executável, mas sem run no candidato | Negar/conceder no aparelho |
| 8 | Offline | PARCIAL | Contratos em `app/lib/core/resilience/offline_capability.dart:1-423`. A captura `visual_system_08_offline` (`ui_live_evidence_policy.json:344`) é estado de UI. Queda de rede real não homologada; `BT-OFF-01` (P1) está bloqueado | `app/test/core/resilience/offline_capability_test.dart:5-52` é de declaração (um contrato por fluxo, campos da matriz de reconexão não vazios, só filas reais alegam mutação offline), não de comportamento offline; também `offline_ui_contract_guard_test.dart` | Sessão com rede cortada |
| 9 | Erros e fluxos negativos | PARCIAL | ux-pack-08 (sessão expirada, erro de save, retry de submit) capturado em Web real no digest antigo | Testes de widget/servidor existem por fluxo | Reexecutar no candidato e no aparelho |
| 10 | Receipt de homologação (aparelho, build SHA, resultado por item) | NAO_ENCONTRADO | Não há template para QA-001. O precedente é `docs/qa/MANALOOM_BATTLE_LOCAL_HOMOLOGATION_TEMPLATE.md` | — | Template + receipt |

**O que realmente falta.** A homologação não começou. O que existe é ferramenta:

- captura Web e Android com atestação adb;
- gate de evidência de UI;
- matrizes de acessibilidade e teclado que registram TalkBack e teclado real como pendentes;
- contratos offline;
- verificador de permissões do APK.

Falta tudo o que é humano ou físico:

- candidato congelado;
- recaptura das matrizes no digest dele;
- sessão TalkBack (72 verificações);
- teclado físico;
- permissões e rede cortada no aparelho;
- fluxos negativos;
- o receipt.

(rev.) E falta uma decisão anterior: as matrizes exigem rotas de Generate, social e Battle, que a decisão corrente mantém OFF. Ou o dono re-escopa as matrizes para o candidato, ou a homologação não fecha. Código novo é mínimo. O custo é operacional: aparelho, revisor, tempo de sessão e cerca de 456 capturas (402 Web + 54 Android, conforme `docs/execution/waves/07-beta-release.md:59`).

Trabalho restante (rev.):

- Cerca de 7 arquivos de controle:
  - `latest.json`;
  - `ui_live_evidence_policy.json` (`release_accessibility`);
  - `ui_accessibility_matrix.json` (re-escopo + evidência);
  - `ui_keyboard_focus_matrix.json` (re-escopo);
  - `ui_accessibility_matrix_test.dart` (hoje trava o `pending`);
  - template;
  - receipt.

  Somam-se os diretórios de captura.
- Cerca de 2 testes:
  - um gate que falha se `release_checks` de TalkBack, teclado ou físico estiverem `pending` para o candidato;
  - reescrever `ui_accessibility_matrix_test.dart:142-150`.
- Sem migração.

- Dependência declarada: `BT-REL-003` e `BT-UX-PROOF-001`. É real: homologar exige candidato congelado e UI final. **Faltam como ancestrais:**
  - `BT-OFF-01`: o aceite pede offline, mas a fronteira online/offline é P1 e não está no caminho.
  - `BT-UIEV-001`: infraestrutura de evidência.
  - `BT-WEB-001`: a Web pública não entra na homologação.
  - (rev.) Merge em `master`, via `BT-REL-003` (achado 11).
- Sobreposição:
  - `BT-UX-PROOF-001`: mesmas capturas.
  - `BT-UX-A11Y-001`: TalkBack lógico e teclado real.
  - `BT-PLAY-003`: Web real + Android físico + TalkBack para Jogar contra IA.
  - `LC-P0-*`: runtime Android físico do Life Counter.

---

## BT-DEC-001 — Decisão GO/NO-GO assinada pelo owner

- Estado declarado: `BLOCKED_BY_P0`. Depende de `BT-QA-001`.
- Entrega: "Decisão GO/NO-GO assinada pelo owner."
- Aceite: "Escopo, bloqueios, riscos aceitos, rollout, monitor e rollback explícitos."

| # | Asserção | Estado | Onde está | Teste (o que afirma de verdade) | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Existe decisão GO/NO-GO **do candidato**, assinada | PARCIAL | `docs/status/CURRENT_PRODUCT_DECISION.md:3-5` (lifecycle, 2026-08-25, `NO_GO_PUBLIC_RELEASE`) é a decisão corrente de escopo, sem SHA de candidato e sem assinatura ou receipt. Há edição local não commitada (+6/−5) | `project_logic_generator_test.dart:794` só garante o lifecycle do documento | Registro GO/NO-GO ligado ao SHA do candidato |
| 2 | Escopo explícito | PRONTO_SEM_PROVA | `CURRENT_PRODUCT_DECISION.md:48-71`: (rev.) matriz de 14 linhas que, na árvore, cobre as 29 capabilities de `server/config/release_capabilities.json`; as 2 linhas que completam a cobertura não estão commitadas | Nenhum teste amarra a tabela ao JSON. `docs/verdade/FATOS.md` §2.2 registrou 27 de 29 antes da edição | Teste de coerência doc↔JSON e commit |
| 3 | Bloqueios explícitos e completos | PARCIAL | O backlog lista os P0, mas o DAG dá só 33 ancestrais a `BT-DEC-001` e deixa 32 `P0 CORE` abertas fora (achado transversal 6). Nenhum script resolve os "P0 aplicáveis" (aceite de `BT-REL-003`) | — | Completar o DAG ou dar ao gate a lista de P0 |
| 4 | Riscos aceitos explícitos | NAO_ENCONTRADO | Nenhum registro de risco aceito | — | Registro |
| 5 | Rollout explícito | PARCIAL | Só existe flag global. `experimental_allowlist` é valor aceito (`server/lib/release_capability_policy.dart:65-69`), mas `allowed` tem de ser igual a `release_capability == 'on'` (`:318-322`), então allowlist equivale a negado. A admissão de coorte depende de cadastro `OFF` + contas pré-existentes (`CURRENT_PRODUCT_DECISION.md:23,56`). (rev.) Não há mecanismo de admissão: nenhum script de convite ou criação de conta em `scripts/`, e `allowlist` só aparece na política de capabilities e em CIDR de auth. Admitir a coorte hoje exige ligar o cadastro para todos, escrever contas direto no PG (autorização live) ou código novo | Validação do schema coberta pelos testes da policy | Decidir como a coorte entra; talvez código de allowlist por usuário |
| 6 | Monitor explícito | PARCIAL | `scripts/manaloom_release_observability_gate.sh` (Sentry/FCM, exige `--execute`) existe. SLO, alertas, receiver e runbook são `BT-OBS-001` (`TODO`) | — | `BT-OBS-001` |
| 7 | Rollback explícito | PARCIAL | Rollback por serviço nos deploys (`scripts/manaloom_deploy_backend_image.sh:254-261`; também public web, flutter web e ops). Transação full-stack com rollback comprovado é `BT-REL-001` (`BLOCKED`); restore é `BT-DR-001` (`TODO`) | Testes de texto em `manaloom_release_ops_contract_test.sh` | `BT-REL-001`/`BT-DR-001` |
| 8 | Assinatura do owner | NAO_ENCONTRADO | Humana por definição | — | Assinatura |

**O que realmente falta.** O documento de decisão existe, mas diz NO_GO, é de escopo e não de candidato, e não tem assinatura. Faltam quatro coisas:

1. **Riscos aceitos.** Não há registro.
2. **Rollout.** Tecnicamente só existe ligar a flag global. A "coorte controlada" não tem alavanca além de cadastro OFF e criação manual de contas, e (rev.) não existe ferramenta para criar essas contas.
3. **Monitor e rollback.** Estão em tarefas próprias (`BT-OBS-001`, `BT-REL-001`, `BT-DR-001`) que não fecharam.
4. **Lista de bloqueios confiável.** O DAG deixa 32 `P0 CORE` fora.

A tarefa é essencialmente decisão humana sobre receipts de outras tarefas. O código só entra se o dono quiser rollout por allowlist real.

Trabalho restante:

- Cerca de 3 arquivos: registro GO/NO-GO, `CURRENT_PRODUCT_DECISION.md` e backlog. (rev.) Se a coorte exigir allowlist por usuário, somam-se 4 a 8 arquivos e 2 ou mais testes: policy, `release_capability_policy.dart`, app e testes.
- Cerca de 1 teste: coerência matriz↔JSON.
- Sem migração e sem prova viva própria. Consome as provas das outras tarefas.

- Dependência declarada: `BT-QA-001`. É real, mas **insuficiente**: 32 `P0 CORE` abertas não são ancestrais, entre elas `BT-WEB-001`, `BT-WEB-003`, `BT-GATE-007`, `BT-UIEV-001`, `BT-AUTH-*`, `BT-PRIV-001/002` e `BT-DB-002..004`.
- Sobreposição:
  - `CURRENT_PRODUCT_DECISION.md` já é o NO_GO vigente.
  - `BT-REL-001` (rollback), `BT-OBS-001` (monitor) e `BT-REL-003` (lista de P0 aplicáveis).

---

## BT-WEB-001 — Landing BrewTact coerente com a oferta e o escopo real

- Estado declarado: `BLOCKED_BY_P0`. Depende de `BT-GOV-001` (`PASS`), `BT-SCP-001` (`IN_PROGRESS_CONTAINED`) e `BT-OFFER-001` (`IMPLEMENTED_LOCAL_PENDING_FULL_GATE`).
- Entrega: "Landing BrewTact coerente com a oferta/escopo real."
- Aceite: "Sem Pro/market/social/Battle prometidos quando OFF; screenshots e release metadata corretos."
- O pacote de onda amplia para "Pro/social/Battle/Scanner/Generate/Learning" (`docs/execution/waves/07-beta-release.md:53`).

| # | Asserção | Estado | Onde está | Teste (o que afirma de verdade) | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Sem Pro, checkout, preço ou upgrade | PRONTO_E_PROVADO | `web-public/src/app/page.tsx`, `pricing/page.tsx`, `lib/product-data.ts` (grep sem ocorrência) | (rev., fonte da prova corrigida) A prova é `server/test/public_web_product_contract_test.dart:106-143`, que aplica as regex ao fonte de home + pricing + product-data e rodou verde no gate amplo de 2026-09-21. Esse teste não cobre `layout.tsx`, blog, legal nem `site-shell.tsx`. O `scripts/manaloom_public_web_surface_contract_test.sh:56-63` só prova que o **detector** (`scripts/lib/manaloom_public_web_surface_contract.sh:132-145`) funciona, com fixtures em `/tmp`. O HTML real só é checado no smoke (`manaloom_public_web_smoke.sh:300-301`), que morre antes | — |
| 2 | Sem marketplace/trade: texto, rotas e sitemap | PRONTO_E_PROVADO | Não há página marketplace/decks/players; `sitemap.ts:6-13` monta a lista a partir de `routes.ts` | (rev.) Prova: `public_web_product_contract_test.dart:145-176` (as páginas removidas não existem no fonte, e `routes.ts` não tem `marketplace:`/`deck:`/`player:`, que é o que alimenta o sitemap). `surface_contract_test.sh:39-49,65-74` prova só o detector | — |
| 3 | Sem promessa de Battle | PRONTO_SEM_PROVA | Nenhuma ocorrência de battle, batalha, "jogar contra" ou simulação em `web-public/src`. Só "histórico de partidas" em `legal/privacy/page.tsx:24` e o tagline "Monte melhor. Jogue melhor." em `components/site-shell.tsx:28` | **Nenhum** dos três contratos tem termo de Battle | Adicionar termos ao padrão negativo |
| 4 | Sem promessa social | PARCIAL | A metadata diz "relatórios compartilháveis" sem condição (`app/layout.tsx:14`), enquanto criar relatório exige `gallery_public`, que está OFF (`server/lib/release_capability_policy.dart:474-476`). (rev.) Os Termos também, sem condição: "O BrewTact oferece ferramentas para criar, organizar, compartilhar relatórios autorizados e analisar decks" (`app/legal/terms/page.tsx:22`). `product-data.ts:49` condiciona. Rotas sociais ausentes (testado) | Só `web-public/tests/free-beta-offer-contract.mjs:26` procura a palavra "social", e esse arquivo **não roda em gate nenhum** (só a existência é checada em `public_web_product_contract_test.dart:178-183`). Emulado estaticamente nesta revisão, ele passaria hoje | Corrigir metadata e Termos; incluir galeria/perfil/seguir/comentários no contrato executado |
| 5 | Sem Scanner, Generate ou Learning | PRONTO_SEM_PROVA | Grep em `web-public/src` sem ocorrência. (rev.) Ressalva: "Construa, organize e revise decks de Commander com IA explicável" (`layout.tsx:14`) pode ser lido como Generate | Sem teste | Termos no contrato |
| 6 | Sem CTA/link para `/app`; mostra "Acesso ainda não liberado" | PRONTO_E_PROVADO | `components/ui.tsx:24-36`; `page.tsx:67,134`; `site-shell.tsx:39` | `public_web_product_contract_test.dart:7-50` (fonte: `AccessPending` em shell/home/pricing/report e nenhum `href` para `/app` em todo `web-public/src`), verde em 2026-09-21; `scripts/manaloom_public_web_smoke.sh:314-324` (HTML renderizado; não alcançado hoje) | — |
| 7 | O texto não sugere acesso disponível | PARCIAL | `app/blog/page.tsx:18`: "continue pelo app para montar decks…", contra `CURRENT_PRODUCT_DECISION.md:24-25`. (rev.) Correção: o cabeçalho de todas as páginas, blog inclusive, mostra `AccessPending` (`site-shell.tsx:39`). O defeito é só a copy | Nenhum contrato olha o blog | Trocar a copy e incluir o blog no contrato |
| 8 | Metadata da landing coerente | PARCIAL | `app/layout.tsx:10` (título "Commander com IA explicável"), `:14` (descrição "…com IA explicável e relatórios compartilháveis"), `:22` (og:title). IA (`ai_analyze_optimize_advisory`) e galeria estão OFF, e o corpo da landing condiciona a IA (`page.tsx:64,100`). `sitemap.ts:17` tem `lastModified` fixo em 2026-08-13 | Nenhum teste lê `layout.tsx` procurando claims | Copy condicional ou neutra + teste |
| 9 | Metadata de release do app `/app` (PWA) coerente | PARCIAL | `app/web/manifest.json:8` e `app/web/index.html:22`: "Build, analyze, test, and track your Magic decks." (em inglês; "test" sugere Battle, que está OFF) | `app/test/core/branding/product_identity_contract_test.dart:12-19` **trava** "Monte, analise, teste e acompanhe…" e a versão em inglês | Decidir a copy (escopo discutível: é do app, não da landing) |
| 10 | Screenshots da landing correntes e revisados | NAO_ENCONTRADO | (rev.) Existem só 2 capturas históricas da landing: `docs/qa/evidence/brewtact_brand_2026-08-11/public_home_desktop_1440x900.png` e `public_home_mobile_390x844.png` (`8264ffb27`). Elas são anteriores à copy all-OFF (`b2d3fc04f`, 2026-08-13), portanto obsoletas. Os 23 manifests de `docs/qa/ui-live/latest.json` são do app Flutter. Não há script de captura da landing (nenhum em `scripts/` cita a landing), e o smoke só baixa HTML | — | Criar a captura e registrar mobile/desktop de landing, pricing, blog, legal e report |
| 11 | (opcional) "Quando OFF" executável: landing conferida contra a matriz | NAO_ENCONTRADO | `web-public` não lê `/capabilities`. Há um único fetch permitido, o de relatório (`lib/public-server.ts:47-49`), travado por `free-beta-offer-contract.mjs:68` e `public_web_product_contract_test.dart:160`. Os contratos codificam o estado all-OFF de forma fixa. (rev.) Enquanto tudo estiver OFF, contratos fixos bastam para o aceite; isto só vira necessário quando alguma capability abrir | — | Teste que lê `server/config/release_capabilities.json` e só permite o claim se a capability estiver `on` |
| 12 | Contratos verdes no gate, no digest corrente | PARCIAL | `manaloom_public_web_smoke.sh:199` (`npm audit`) falha com `next` 15.5.21 (`web-public/package.json:22`) **antes** das asserções renderizadas (`:295-324`). O `.mjs` não roda; o shell e o Dart rodam | — | `BT-WEB-003` e plugar `npm run test:contract` no smoke |
| 13 | Landing implantada corresponde a esta revisão (release metadata/SHA) | PARCIAL (rev.: era NAO_ENCONTRADO) | (rev.) O deploy já amarra a imagem ao SHA: passa pela identidade de release (`scripts/manaloom_deploy_public_web.sh:235-236`), confere o digest em execução, injeta `GIT_SHA` no serviço (`:355`) e imprime `git_sha` (`:480`). O que falta é a superfície: `/healthz` responde só "ok" (`web-public/src/app/healthz/route.ts:4`). `CURRENT_PRODUCT_DECISION.md:18-19,28-29`: o domínio não prova a implantação. E o único ref implantável é `origin/master`, que ainda tem a landing antiga (achado 11) | — | Merge em master + deploy autorizado + prova após deploy; identidade exposta na superfície, se o aceite for lido como `BT-REL-002` |

Nota: `product: "manaloom"` na identidade de release (`scripts/manaloom_release_identity.sh:89`) **não** é defeito. É identificador interno legado mantido de propósito (`docs/adr/0010-brewtact-public-brand-transition.md:43-45`).

**O que o deploy pode publicar hoje (rev., novo).** A identidade de release recusa qualquer SHA fora de `origin/master` (`manaloom_release_identity.sh:46-54`), e `origin/master` (`704c2c11c`, 2026-08-12) não contém `b2d3fc04f`. Em master, a landing tem:

- `Abrir app` (`page.tsx:101,267`);
- as páginas `/marketplace`, `/decks/[id]` e `/players/[id]`;
- preços e trocas de cartas;
- a metadata "…relatórios compartilháveis e mercado de cartas".

Ou seja, a única landing implantável hoje viola todas as proibições do aceite. A landing coerente só chega à superfície depois do merge de 29 commits em master (nenhuma tarefa registra esse merge) e de um deploy autorizado.

**O que realmente falta.** No branch candidato, o texto da landing e da página de preços já está no estado all-OFF desde `b2d3fc04f`: sem Pro, sem comércio, sem Battle, sem link para `/app`. Os três tipos de proibição mais antigos (Pro, trade, marketplace) têm contrato executado no fonte. Faltam seis coisas (rev.):

1. **Metadata e copy.**
   - A metadata global promete "IA explicável" e "relatórios compartilháveis" sem condição.
   - Os Termos prometem "compartilhar relatórios" e "analisar decks" sem condição. Mudar os Termos provavelmente pede revisão jurídica (`latest.json:240`).
   - O blog manda "continuar pelo app".
   - A metadata do app `/app` promete "teste".
2. **Contratos para Battle e social.** O único teste que olha "social" não roda em gate nenhum.
3. **Screenshots da landing.** Não existe nenhuma captura corrente, nem ferramenta para fazê-la.
4. **Smoke verde.** O smoke da landing não chega às asserções por causa do `npm audit` (`BT-WEB-003`).
5. **Merge em master e deploy autorizado.** Sem isso, a landing real continua a de 2026-08-12.
6. **Identidade de release visível na superfície implantada.**

Trabalho restante (rev.):

- Cerca de 10 arquivos:
  - `layout.tsx`;
  - `blog/page.tsx`;
  - `legal/terms/page.tsx`;
  - `manaloom_public_web_surface_contract.sh`;
  - `manaloom_public_web_surface_contract_test.sh`;
  - `public_web_product_contract_test.dart`;
  - `free-beta-offer-contract.mjs`;
  - `manaloom_public_web_smoke.sh` (rodar o `.mjs`);
  - um script ou manifesto de captura da landing;
  - `app/web/manifest.json`/`index.html`, se a metadata do `/app` estiver no escopo.
- Cerca de 6 testes:
  - termos de Battle;
  - termos sociais;
  - claims na metadata;
  - claims no blog e nos Termos;
  - `test:contract` executado no smoke;
  - manifesto da captura da landing.
- Sem migração.

- Dependência declarada: `BT-GOV-001` (`PASS`) é real. `BT-SCP-001` e `BT-OFFER-001` são **formais**: a landing do branch já está no estado all-OFF e pode ser corrigida e provada agora. **Não declaradas e reais:**
  - `BT-WEB-003`, porque o `npm audit` derruba o smoke antes das asserções;
  - (rev.) o merge em master e o deploy autorizado;
  - `BT-REL-002`, se "release metadata" for lida como identidade same-SHA.
- Sobreposição:
  - `BT-OFFER-001`: a asserção "sem Pro na landing" é a mesma.
  - `BT-WEB-003`: mesmo smoke.
  - `BT-REL-002`: identidade por superfície.
  - `BT-SCP-001`: `/reports/:id` continua público pelo plano de controle (`release_capability_policy.dart:471-473,584-585`) e renderiza até `optimization_preview` (`app/reports/[id]/page.tsx:82`) com IA OFF.
- `BT-WEB-001` não é ancestral de `BT-DEC-001`. A decisão pode sair sem esta prova.

---

## Verificação adversarial

Revisão cética feita em 2026-09-22 sobre a medição acima, só por leitura, no mesmo checkout (`d15beb05b`, árvore suja). Método:

- Abrir todo teste citado como prova, conferir o que ele afirma e comparar com a asserção.
- Abrir todo `arquivo:linha` das asserções `PRONTO_SEM_PROVA`.
- Tentar derrubar as tarefas medidas como `quase-la`.

Foram reexaminadas 60 das 65 asserções originais: as 26 prontas (16 provadas + 10 sem prova) a fundo, e 34 das parciais ou não encontradas.

### O que caiu (rebaixado)

| Tarefa | Asserção | De → para | Por quê |
| --- | --- | --- | --- |
| `BT-GATE-001` | Precedência FAIL>BLOCKED>PARTIAL e `main()` (parte da asserção 1, agora 1b) | PRONTO_E_PROVADO → PRONTO_SEM_PROVA | Nenhum teste mistura classes nem executa `main`; os testes reescrevem a cauda de `main` no próprio snippet (`e2e_gate_status_contract_test.dart:56-57,107-108`). Só a função de mapeamento está provada |
| `BT-GATE-002` | SHA de 40 hex lido do checkout corrente (parte da asserção 1, movida para a 2) | PRONTO_E_PROVADO → PRONTO_SEM_PROVA | `current_source` é injetado sintético (`validator_test.py:44-58`); a checagem de 40 hex e a leitura do `HEAD` (`validator.py:144-146`) nunca executam em teste |
| `BT-GATE-002` | 5 — checks nomeados (status por check, artifacts por check, ordem, summary) | PRONTO_E_PROVADO → PRONTO_SEM_PROVA | Os testes cobrem só ID duplicado e `check_count` booleano; status ≠ PASS, check sem artifact e catálogo reordenado não têm teste. A exatidão do catálogo já conta na linha 6 |
| `BT-GATE-002` | 9 — artifacts hasheados e recalculados | PRONTO_E_PROVADO → PRONTO_SEM_PROVA | O teste de adulteração muda o tamanho e para no *size drift* (`validator.py:382-383`); a comparação de hash (`:384-385`) e o manifesto (`:405-412`) nunca executam |
| `BT-GATE-003` | 1 — o bloco isolado existe e roda cada superfície uma vez | PRONTO_E_PROVADO → PRONTO_SEM_PROVA | A única "prova" é contagem de strings no texto do script (`gate_contract_test.py:116-147`); o próprio documento define isso como sem prova, e não há receipt de execução |

### O que subiu (promovido)

| Tarefa | Asserção | De → para | Por quê |
| --- | --- | --- | --- |
| `BT-GATE-001` | 7 — BLOCKED de sub-gate | PARCIAL → PRONTO_SEM_PROVA | O aceite literal é "propagam `BLOCKED` não-zero", e o exit 1 continua não-zero; preservar a classe é melhoria, não falta de aceite |
| `BT-GATE-001` | 4 — camada solicitada sem pré-requisito vira BLOCKED | PARCIAL → PRONTO_SEM_PROVA | O código das cinco camadas está completo e o mecanismo comum está provado pelo caso Flutter; falta só teste das quatro guardas. PARCIAL sugeria código incompleto |
| `BT-WEB-001` | 13 — landing implantada corresponde à revisão | NAO_ENCONTRADO → PARCIAL | O deploy já amarra imagem ao SHA, confere o digest em execução e injeta `GIT_SHA` (`manaloom_deploy_public_web.sh:235-236,355,480`); falta expor na superfície, fazer o merge e implantar |

Também a favor do autor:

- A contagem "16 de 19 com `--no-verify`" estava inflada: 13 declaram o próprio bypass, um é ambíguo e dois só citam o bypass de outro commit.
- A asserção 9 de `BT-GATE-003` e a 11 de `BT-WEB-001` estão fora do aceite literal e ficaram marcadas como opcionais.
- Em `BT-WEB-001`, "o blog não tem `AccessPending`" era falso: o cabeçalho comum o mostra em toda página.
- "Nenhum screenshot da landing" era falso: existem 2 históricos, obsoletos.

### Estado medido revisado

- `BT-WEB-001`: **quase-la → metade**. No branch, a copy principal está limpa e provada no fonte. Mesmo assim, dois dos três blocos do aceite não estão atendidos:
  - "screenshots": não há captura corrente nem ferramenta;
  - "release metadata corretos": a metadata promete IA e compartilhamento, e a identidade não aparece na superfície.

  O primeiro bloco ("sem social") também é violado pela metadata e pelos Termos. E a única landing implantável (`origin/master`) é a antiga, com `Abrir app` e marketplace.
- `BT-GATE-002`: mantém **metade**, mas cai a ressalva "quase-la se o escopo for só Deck/IA". Mesmo nesse escopo, nenhum receipt real foi montado e o primeiro esbarra em riscos não testados:
  - o catálogo de 55 checks nunca foi observado numa saída real;
  - qualquer `warn` do auditor derruba o receipt;
  - a paridade é medida contra um `knowledge.db` de julho;
  - o schema está amarrado ao `058`.
- `BT-GATE-001` mantém **quase-la**. Tentativa de derrubar sem sucesso: os dois blocos do aceite estão implementados, o núcleo tem teste que executa o script, e esse teste rodou verde no gate amplo de 2026-09-21. O que falta é teste de wrapper e o receipt, e o receipt verde de ponta a ponta depende de `BT-WEB-003` e `BT-UIEV-001`.
- `BT-GATE-003`, `BT-QA-001` e `BT-DEC-001` mantêm **mal-comecada**.

### Dependências ocultas encontradas nesta revisão

1. **Merge do branch candidato em `master`.** Sem tarefa no registry, com autorização do dono. É pré-requisito de qualquer deploy (`manaloom_release_identity.sh:46-54`) e, portanto, de `BT-WEB-001` na superfície, `BT-REL-003`, `BT-QA-001` e `BT-DEC-001`.
2. **`BT-DB-002` (migration `059`)** invalida o receipt forte de `BT-GATE-002`/`003` até a política, o produtor e dois testes serem atualizados (achado 12).
3. **Re-escopo das matrizes de TalkBack e teclado.** Elas exigem Generate, social e Battle, que ficam OFF no candidato (achado 13).
4. **Mecanismo de admissão da coorte**, para `BT-DEC-001`: não existe convite, allowlist por usuário nem script de criação de conta.

### Números revisados

- Asserções: 16 · 10 · 21 · 18 (65) → **13 · 16 · 20 · 17 (66)**. A linha 1 de `BT-GATE-001` foi separada em duas. Das 17 não encontradas, 2 são opcionais.
- Arquivos a tocar: 34 → **41**. Somam-se até +12 condicionais: +4 quando a `059` entrar e +4 a 8 se a coorte exigir allowlist.
- Testes a escrever: 25 → **33**:
  - precedência/`main` e o quarto caminho BLOCKED em `001`;
  - hash de mesmo tamanho e regras por check em `002`;
  - skip na fatia composta e receipt do perfil local em `003`;
  - reescrita do teste que trava o `pending` em `QA-001`;
  - manifesto de captura em `WEB-001`.

### Veredito de otimismo

**Otimista demais**, em grau moderado. A medição é cuidadosa, e quase todas as citações `arquivo:linha` conferem. Os desvios, porém, puxam para o mesmo lado:

- 5 asserções contadas como provadas não eram, e uma delas contrariava a regra do próprio documento;
- uma tarefa foi medida como `quase-la` sem olhar o que o deploy consegue publicar;
- faltaram quatro pré-requisitos não declarados, dois deles com autorização do dono (merge e deploy);
- trabalho e testes ficaram subestimados em cerca de 20% e 30%.

Os três pontos em que ele foi duro demais não compensam: dois são de classificação (PARCIAL no lugar de sem prova) e um é de grau (NAO_ENCONTRADO no lugar de PARCIAL), sem reduzir trabalho restante de forma material.
