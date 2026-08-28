# Ficha de execução — `BT-SCP-001`

> Ledger de execução não autoritativo. ID, prioridade, estado, dependências,
> entrega e aceite continuam resolvidos no backlog mestre/registry.

## Autoridade

- Task ID: `BT-SCP-001`
- Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`
- Registry schema: `2`
- Registry `generated_from.sha256` de abertura:
  `0ce0be74f84bd5e8eb25568601a4ce47f46a24dd6766dba67393caadd8f62abd`
- Project logic source digest de abertura:
  `bf7704ee33c99009bc878962409654df0af63d244c1b52c10eccc7aa674c80e0`
- Linha canônica: `222`
- Decisão corrente: `docs/status/CURRENT_PRODUCT_DECISION.md`
- Dependência canônica: `BT-GOV-001=PASS`

## Identidade da execução

- Owner: `/root`
- Início UTC: `2026-08-24T21:14:27Z`
- Fim UTC do checkpoint técnico: `2026-08-28T13:14:22Z`
- Branch: `codex/BT-SCP-001-cleanroom`
- Git SHA baseline antes da abertura:
  `d9f7a59cd87d032df3d076c35ffbdb17e41525a6`
- Git SHA inicial da implementação:
  `406d7dd533f0ff0ae8294f8b9de94fecc07bf24e`
- Git SHA do checkpoint: resolvido pelo objeto Git que inclui esta ficha e
  reportado no handoff, sem reescrita histórica
- Worktree digest do baseline limpo:
  `ee254fdbc66babfe86ddd041b8a28e3c458e5c13a536e0599d88d55b2b4f08a7`
  (`manaloom-worktree-v2` no SHA baseline; a abertura da ficha e o fechamento
  documental do predecessor ainda não estavam commitados)
- Fonte estável: `true` no baseline; revalidar antes de implementar
- Classe(s) de fechamento: `LOCAL_CODE`, `DISPOSABLE_PG` e
  `RELEASE_READ_ONLY` somente quando os respectivos gates forem executados
- Autorização máxima: código e documentação local, PostgreSQL loopback descartável e commit/push deste checkpoint na branch cleanroom; nenhum PR/merge, deploy, migration ou DML live, capability ON, pin, regra ou deck
- Estado desta ficha:
  `CHECKPOINT_COMMITTED_NO_GO / PAUSED_BY_USER_PRIORITY`; somente o commit e o
  push do checkpoint foram autorizados, sem fechamento canônico, promoção de
  UI/E2E/release ou nova implementação

## Rebaseline e controle de mudança

- O SHA `406d7dd533f0ff0ae8294f8b9de94fecc07bf24e` é a base limpa do
  cleanroom e contém o commit `Harden server release capability boundary`.
- Esse commit não possui `Task ID` no corpo. A rastreabilidade é compensada
  nesta ficha e deverá constar no receipt final, sem reescrever histórico.
- A execução anterior ampliou o WIP para Battle, Play vs AI, recovery,
  lifecycle de deck, UX, gerados e evidências. Uma auditoria read-only
  classificou as 271 entradas sujas do checkout original em 9 recortes
  `INCLUDE_BT_SCP`, 79 `PARK_BATTLE_OR_DECK/PARK_UX`, 172
  `EVIDENCE_STALE`, 5 `GENERATED_REBUILD_LATER` e 6 `UNRELATED`.
- Os 28 untracked do checkout original são 22 evidências stale e 6 itens
  estacionados; nenhum foi incluído no cleanroom.
- O checkout original permanece preservado. O linked worktree cleanroom é o
  único lugar autorizado para escrita desta task.
- A evidência focal Play vs AI permanece `PASS_FOCAL_NOT_TASK_CLOSURE` e não
  resolve nenhuma cláusula deste aceite.
- O auditor independente revalidou o checkpoint pós-focais como
  `GO_CHECKPOINT_BEFORE_BROAD_GATES`.
- O `GO_BROAD_GATES_CONTAINED` foi recebido para executar a sequência de
  validação, sem staging, commit, push, deploy, escrita live ou capability ON.
- Freeze de fontes: `2026-08-26T15:36:31Z`, branch
  `codex/BT-SCP-001-cleanroom`, HEAD/base
  `406d7dd533f0ff0ae8294f8b9de94fecc07bf24e`; os nove recortes continuam
  vinculados ao patch SHA-256
  `57315958cb6092555bad92ca9e26d64008dfaf5f35d725ebed10d7d7ac94ced8`
  e somente esta ficha task-scoped foi adicionada como décimo path.
- No freeze, o índice e a lista de untracked do cleanroom estavam vazios. O
  checkout original permaneceu intacto, com status SHA-256
  `61ba4a3e97ff47e33e41313e22eda57462a595694a350ca3adeb241cc44cae11`.
- O primeiro `./scripts/quality_gate.sh full`, iniciado após o freeze, encerrou
  com `FAIL` determinístico (`exit 1`): backend completo e analyzer app
  passaram; a suíte Flutter terminou com `1573` passes, `1` skip declarado e
  `1` falha no inventário de superfícies; Web/performance não foram executados
  depois da falha.
- `GO_REBASELINE_UI_INVENTORY_MINIMAL` recebido em
  `2026-08-26T16:09:29Z`: os nove recortes originais permanecem inalterados e
  dois contratos derivados entram no allowlist, totalizando onze paths de
  implementação/contrato. A ficha task-scoped e os gerados continuam
  classificados separadamente.
- O rebaseline autoriza exclusivamente
  `app/test/ui/fixtures/ui_surface_inventory.json` (`transient` total
  `115→116` e Deck Generate `14→15`) e
  `app/test/ui/ui_surface_inventory_test.dart` (`264→265`, inclusive a
  mensagem). `inventory_id`, `go_route`, contratos de domínio, rotas e
  contagens Battle permanecem byte-idênticos ao cleanroom anterior.
- A causa é um único `SnackBar` fail-closed adicionado pelo recorte já
  aprovado de `deck_generate_screen.dart`. O project logic, o gate amplo e
  qualquer digest/evidência anteriores ao rebaseline ficam invalidados e a
  sequência reinicia integralmente em `project_logic --write/--check`.
- A auditoria independente do recorte mínimo devolveu
  `GO_RESTART_PROJECT_LOGIC`: confirmou equivalência semântica hunk a hunk,
  somente os três valores autorizados, zero alteração de `inventory_id`,
  `go_route`, Battle/Play/XMage, rotas, lifecycle, UX ou evidência stale e zero
  staged/untracked.
- O freeze rebaselined reúne os onze paths de implementação/contrato e esta
  ficha em `/tmp/manaloom-bt-scp-001-source-freeze-r1.patch`, SHA-256
  `51fa17714dfde7afd3f371beb46d552a3557c6fa5326a1068e76e69ed8e1644f`.
  `project_logic --write` e `--check` passaram e produziram o source digest
  `02d08edaaad19a81e58b0cb21921492a34606d8e2602f3e5728ab8f5b8ecc64b`,
  confirmado em `project_logic_manifest.json`, `CURRENT_SYSTEM.md` e
  `TASK_REGISTRY.json` antes deste checkpoint task-only.
- A segunda execução de `./scripts/quality_gate.sh full` não emitiu resultado
  terminal nem exit code: a sessão do runner desapareceu durante a suíte
  Flutter e deixou o `flutter_tester` PID `61195` órfão (`PPID 1`) apontando
  para o cleanroom. O resultado exato é
  `ABORTED_NO_EXIT_CODE (NON_PASS)`; backend completo, analyzer e os quatro
  testes de inventário haviam passado, e foram observados pelo menos 665
  testes Flutter sem falha, mas isso não recebe crédito de `full`, `PARTIAL`
  ou `PASS`.
- O PID `61195` foi confirmado pelo executável, cwd, package config, assets e
  listener temporário do cleanroom e recebeu `TERM` em
  `2026-08-26T16:35:33Z`. A verificação posterior encontrou zero processos ou
  listeners pertencentes ao cleanroom; os dois listeners Dart restantes são
  DevTools globais iniciados em 2026-08-12, com cwd `/`, e não pertencem ao
  gate. O checkout original permaneceu intacto com status SHA-256
  `61ba4a3e97ff47e33e41313e22eda57462a595694a350ca3adeb241cc44cae11`.
- Addendum task-only de `2026-08-26T16:46:53Z`:
  `GO_DIGEST_RECOMPUTED_IDENTICAL_BY_DESIGN` corrige a exigência anterior de
  valor novo. A ficha é deliberadamente excluída de
  `lineage.digest_inputs` e lida por `_executionLedger` somente para validar
  existência, identidade e cabeçalho não autoritativo. A recomputação
  independente por `path + NUL + file_sha256 + NUL` confirmou legitimamente
  `02d08edaaad19a81e58b0cb21921492a34606d8e2602f3e5728ab8f5b8ecc64b`;
  o auditor devolveu `GO_FULL_R2_SAME_DIGEST_EXPECTED`, sem novo achado. O
  freeze R2 anterior a este addendum permanece identificado por
  `8b8a9e3dc2556ef4766c4ff8a0f483bee6623d9db031c7f511507e57556bf8f9`;
  esta ficha mantém hash próprio e não altera o source digest.
- O `FULL_R3`, executado com Node `v26.0.0` e npm `11.12.1` apenas no `PATH`
  do processo, encerrou com exit `0`: backend `2283/2283` em 45 batches,
  analyzer sem issues, Flutter `1574 PASS` e um `SKIP` condicional Web-only,
  Public Web e 22 testes de performance passaram. O caso
  `Lotus browser host runtime is covered on Chrome` permanece individualmente
  `SKIP`, nunca `PASS`.
- Addendum task-only de `2026-08-26T17:17:52Z`: o primeiro schema gate
  descartável recebeu `NON_PASS_SCHEMA_AUDITED`, exit `1`. PostgreSQL `14.18`
  iniciou somente em `127.0.0.1:58722`, aplicou as migrations `001–058`
  (`58/58`) e executou cinco testes DB; quatro ficaram verdes e o teste
  integrado `BL10-03` falhou. Esses quatro testes não recebem crédito de
  schema, Battle, `BT-PLAY` ou `BT-BAT`.
- A falha observada foi `loadedPostgresMs p95 = 540 ms` contra orçamento de
  `500 ms`, conforme o stack em
  `battle_job_integrated_load_live_test.dart:281` e as linhas `281–283` do
  source. `loadedBatchMs p95` está nas linhas `285–287` e não foi avaliado
  depois da primeira asserção; a classificação gerencial anterior como batch
  foi corrigida por evidência.
- `tbls out/doc/lint`, `schema.json`, inventário final de tabelas/views/FKs e
  comparação schema/manifesto não foram alcançados. O manifesto espera 79
  tabelas, 6 views, 98 FKs e 58 migrations, mas somente as 58 migrations foram
  comprovadas neste run. O binário `tbls 1.95.0` foi resolvido no preflight,
  não invocado pelo gate interrompido.
- Com `MANALOOM_KEEP_LOCAL_GATE_ARTIFACTS=1`, `${TMPDIR:-/tmp}` resolveu para o
  `TMPDIR` do macOS. O run ficou em
  `/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T/manaloom_tbls_local.logquz`,
  portanto não cumpriu a exigência literal de `/tmp`, embora tenha mantido o
  bind exclusivamente loopback. O log prova fast shutdown às
  `2026-08-26T14:06:06.878-03` e `database system is shut down` às
  `14:06:07.094-03`; `pg_ctl`, `pg_isready`, processo e listener confirmaram
  zero cluster residual.
- Addendum task-only de `2026-08-26T17:29:09Z`: o
  `GO_SCHEMA_R2_SINGLE_CONTROLLED_RETRY` autorizou uma única repetição, sem
  alterar fonte, script, budget, teste ou contrato. A execução usou
  `TMPDIR=/tmp MANALOOM_KEEP_LOCAL_GATE_ARTIFACTS=1` e recebeu
  `PASS_SCHEMA_R2_AUDITED`, exit `0`, com PostgreSQL `14.18` exclusivamente em
  `127.0.0.1:50787` e artefatos literalmente em
  `/tmp/manaloom_tbls_local.EJ1693`. O PostgreSQL alheio do Mailhog permaneceu
  separado e intocado em `127.0.0.1:55444`.
- Os cinco testes DB concluíram com `+5 All tests passed`. A linha estruturada
  `battle_job_integrated_local_load_v1` registrou, sob carga, p95 de create
  `195 ms`, rota `38 ms`, PostgreSQL `39 ms`, batch `9 ms` e cancel `51 ms`,
  aggregate `204 ms`, RSS delta `4.456.448 bytes` e zero jobs ativos após o
  cancelamento; todos ficaram dentro dos budgets declarados. Essa cobertura é
  estrutural e incidental ao schema e não concede aceite a Battle,
  `BT-PLAY` ou `BT-BAT`.
- `tbls 1.95.0 out/doc/lint`, Mermaid e `schema.json` foram alcançados. A
  recomputação independente contra o manifesto confirmou 79 tabelas, 6 views,
  zero drift de colunas, 98 FKs e 58 migrations. O cluster recebeu fast
  shutdown às `2026-08-26T14:23:28.784-03`, encerrou às `14:23:28.828-03` e
  deixou zero processo, socket ou listener em `50787`.
- O R1 permanece preservado separadamente, com exit `1`, como
  `NON_PASS_SCHEMA_AUDITED`. Ele fica documentado como flake/desvio histórico
  residual observado (`loadedPostgresMs p95 = 540 ms` e localização fora de
  `/tmp` literal), sem ser apagado, reclassificado ou receber crédito parcial.
  No R2, o log externo tem SHA-256 `31c9027e2d37ec227a8197e92a7c99568ba565b62e6e81b848fa9ca5f1d28c7e`,
  o exit marker `5ca383cdd0c8b9be59bad450ca709681243c12a02ca463c3723023e2fedfef9b`,
  os testes DB `0e8a06a747d540107d469e7f95337a2a790284b1a0de626f674030baa2095367`
  e o `schema.json` `330b7593a961373ec7ed5b7df381cc49e470624fbcbae8866f91ca403cd007e6`.
- Addendum task-only de `2026-08-26T17:49:33Z`: a matriz especializada
  local concluiu como `PASS_SPECIALIZED_CONTRACT_MATRIX_LOCAL_ONLY`. Os
  contratos de capabilities/release identity e Web pública passaram; o gate
  Deck/IA/Learning retornou exatamente `PASS_CODE_ONLY`, com `15/15`
  step-records, rede negada, zero mutação e `release_eligible=false`.
- A primeira tentativa de release-ops permanece preservada como `NON_PASS`,
  exit `2`, por resolver o Flutter global incompatível `3.41.6`; seus hashes
  são `aa44846adb00e8749cf31bab12a3c7ea44eb141b3c7d52a76ea1300bf89c9fea`
  para o log e
  `6c0ab672f3c3bf01b83e87b27d8f9eeadb996c0a4882616479c4c31164d1269a`
  para o exit marker. Houve exatamente um retry process-scoped com o SDK
  aprovado Flutter `3.44.6`/Dart `3.12.2`: exit `0`, 32 contratos, suites
  `5/5` e `12/12`, transição XMage `status=pass`,
  `qualification_status=pass`, `deployment_allowed=true`, 169 cartas
  classificadas e zero pendências. O log tem SHA-256
  `d3a5573e87896c5b9633e21c73149e2c9db65fa8ea1c20606520953e3104b121`
  e o exit marker
  `bbb7d445272e228d72e156ee7a14bad068e9f8f41c81c601f7bd6f17eeafb178`.
  As repetições internas de Web/capabilities são redundância, não evidência
  independente adicional; o log não ecoa o path absoluto do SDK, cuja
  identidade foi corroborada no preflight.
- O daemon ops concluiu `20/20`, exit `0` (log `57a671430fc0bc44b1e7fd9343e2bf9d8d2357a9b539c45cb2d6a89d3897388b`;
  exit marker `c55ff7ffa29f5e253c6cabb1c1080a2bb0bf16c24de4ce7c167b2906c5907d71`).
  O validator local concluiu `18/18`, exit `0` (log
  `6883072130b90e7d0542e6803f2b2ede893bdfd5a93c6a07332a248e36040286`;
  exit marker `66cee0656292b2e661fd264a272126753780f71bfe63bbed66a6cb41465cd923`).
  Esse último resultado cobre somente receipts sintéticos do contrato do
  validator: não cria nem valida receipt canônico, não concede release e não
  é prova same-SHA. O Battle product gate não foi executado e não recebe
  crédito; houve somente sua verificação sintática interna.
- Alinhamento live read-only recebido da task Hermes
  `01a03f15-9a4e-7393-8f34-1106abc07190`: classificação
  `SERVER_BEHIND + POLICY_DRIFT`. O serviço `evolution_manaloom-ops` está
  mecanicamente ativo `1/1` no SHA
  `a16e189170fecd31bb015c538dd6f2860777c602` (23 commits atrás de `406d7dd53`),
  com 16 jobs habilitados, health nativo ativo, 7.045 regras e SQLite íntegro.
  Entretanto, o ambiente live contém `MANALOOM_IMPORT_APPLY=1`,
  `MANALOOM_SYNC_CARD_LEGALITIES_APPLY=1`,
  `MANALOOM_NATIVE_BATTLE_HTTP_ENABLED=1` e
  `MANALOOM_NATIVE_BATTLE_SYNC_ON_BOOT=1`, sem
  `MANALOOM_RELEASE_CAPABILITIES_FILE`.
- O backend público observado está no SHA
  `a6ee09c8f16cf17c2867de4b089e5e65b3527254` (19 commits atrás), responde
  `404` em `/capabilities` e anuncia Battle/interactive habilitados em
  `/ready`. Assim, runtime vivo não equivale a conformidade: não há
  `same-SHA`, live PASS ou receipt release válido. Esta observação é somente
  bloqueio live/receipt; Hermes funcional continua fora do escopo e nenhuma
  correção remota, deploy ou mutação foi executada.

### Rebaseline do build offline para a evidência UI

- O `GO_REBASELINE_CANONICAL_OFFLINE_BUILD_ADAPTER` mantém este trabalho sob o
  único NOW `BT-SCP-001`, como infraestrutura indispensável à evidência UI, e
  não abre uma segunda task. O rebaseline limita-se ao adapter first-party
  fail-closed, ao wiring do harness, ao teste focal, ao digest UI e a esta
  ficha. App/backend funcional, capabilities, Battle, UX, fila e backlog não
  fazem parte desse recorte.
- As três execuções anteriores da fixture/captura UI, R1, R2 e R3, permanecem
  `NON_PASS` sem reclassificação ou crédito. O aggregate no digest
  `d517adb6…` permanece histórico e stale; R4 não foi executado.
- A auditoria da toolchain pinada confirmou que
  `DartFrogCommandRunner.run()` aciona o updater, que os hooks oficiais do
  build executam `dart pub get` e que o gerador Mason possui caminhos de
  template remoto/isolate. A primeira implementação, com `MasonGenerator`,
  produziu build mas o PID `67743` tentou resolver via `mDNSResponder`; ela
  fica preservada como `NON_PASS_ZERO_ATTEMPT`. Uma iteração síncrona posterior
  terminou com exit `70` por um path condicional vazio de Dockerfile e também
  não recebe crédito. Um analyze separado do servidor gerado acionou
  `custom_lint`/`dart pub upgrade` e foi negado pela sandbox; ele não integra o
  caminho positivo nem é reclassificado.
- O adapter final é composto por
  `scripts/manaloom_dart_frog_offline_build.sh`,
  `scripts/manaloom_dart_frog_offline_build.dart`, o wiring em
  `scripts/manaloom_server_contract_e2e_isolated.sh` e o contrato focal em
  `server/test/manaloom_offline_dart_frog_build_adapter_contract_test.dart`.
  Ele aceita somente `build`, exige ausência de `server/build`/`.dart_frog`,
  fixa Flutter `3.44.6`, Dart `3.12.2` e `dart_frog_cli 1.2.14`, atesta SDK,
  pubspec, lock, package config/graph, cache e bundle antes e depois da geração,
  e não usa command runner, updater, hooks, Mason generator, processos, socket
  ou HTTP no helper.
- O teste focal final passou `20/20`, incluindo negativos de lock,
  package-config, package-graph, cache, SDK/CLI, build preexistente, comando não
  permitido e mutação. Formatação, analyze focal, `bash -n` e
  `git diff --check` também passaram. A execução positiva final teve exit `0`,
  120 rotas, 16 middlewares, 1.128 paths esperados sem extra ou ausência,
  digest do build `52f89a36454c163105c489febd9dd21a8aaa1db96d2dc332e80e4775d6a8c1cc`
  e attestation de inputs
  `d03d36ff5bc264d26f7646ad94c51e95962171226b84525a77360476168f6827`.
  O log tem SHA-256
  `32d7a7493d727116d610bfcc963dd0b92ee11366b7c5fd665fb5a5857f638f17`.
- A compilação kernel do servidor gerado passou com SHA-256
  `4066c5e7b42b98f6be1601ef5c36bb8507c67696c911cec3844e861013530554`.
  A prova unificada do PID `83674` tem SHA-256
  `1fc34d875a3e6f72b4fb195f59a00fc2476878636c49424b1d46e69e70f0aac6`
  e registra zero resolver, conexão remota, updater, pub ou negação de rede
  atribuível ao adapter. As mensagens globais de `mDNSResponder` na janela
  eram somente eventos LaunchServices sem query e sem atribuição ao Dart/PID.
- O build aprovado foi movido para
  `/private/tmp/manaloom_offline_adapter_final.qgCiOB/build`; o cleanroom ficou
  sem `server/build`, `.dart_frog`, processo ou listener residual. Build,
  `.dart_tool`, cache e credenciais não entram no índice. As auditorias
  independentes de segurança e equivalência devolveram, respectivamente,
  `GO_CODE_AND_ZERO_ATTEMPT` e `GO_STRUCTURAL_PRE_FREEZE`; a auditoria final
  pós-regeneração devolveu `GO_FINAL_POST_PROJECT_LOGIC`, sem blocker.
- O freeze final contém 16 paths de implementação/contrato e tem SHA-256
  normalizado
  `da6bad5885642f54ecf179ade87949300d571ff49ef3995ebaaac60301db8bb9`;
  a ficha é atestada separadamente porque não participa do lineage. Uma
  primeira invocação de `project_logic --write` gerou os outputs, mas perdeu o
  marcador terminal por erro do wrapper externo e recebe zero crédito. A
  repetição rastreável concluiu `--write` e `--check` com exit `0`, alterando
  somente os quatro gerados esperados. O source digest foi recomputado de
  2.660 inputs como
  `c48ed3f1420e1ec6b990b4e74961d027b77a08193f1afa83715f1b15fbe1ed49`,
  idêntico ao manifesto; o UI source digest desta onda é
  `7e7c090b197f2f6f2d0f7537ff4a179cd9a239a7b7260e35e8fd89fa9ffbe982`.

### Rebaseline mínimo das coordenadas PostgreSQL da fixture visual

- O `NO_GO_R4_HARDCODED_PG_COORDINATES` preserva R4 como não executada: a
  fixture anterior fixava `127.0.0.1:5432`, coordenada pertencente a um
  container alheio sem credencial autorizada. Esse container não foi acessado,
  parado, reconfigurado ou usado para inferir senha.
- O `GO_REBASELINE_VISUAL_QA_PG_COORDINATES_MINIMAL` mantém o recorte no único
  NOW `BT-SCP-001` e autoriza somente o harness visual, seu contrato focal e
  fatos nesta ficha. Fluxo visual, seeds, capabilities, app/backend funcional,
  adapter offline, Battle, UX, fila e backlog permanecem inalterados.
- O harness agora recebe `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS` e banco
  administrativo, com defaults locais compatíveis. Ele aceita somente host
  literal `127.0.0.1`, porta numérica entre 1 e 65535 e identidades locais
  sintaticamente válidas antes de carregar toolchain, criar diretório, chamar
  PostgreSQL ou iniciar o child. O default local `5432` continua compatível;
  nesta máquina, uma futura R4 deverá receber explicitamente a porta efêmera do
  cluster descartável e nunca usar o container alheio.
- `pg_isready` e todos os `psql` passam por helpers únicos que removem variáveis
  libpq ambientes, aplicam host/porta/usuário/admin explícitos, usam
  `PGPASSWORD` somente no ambiente do processo e recusam prompt. O preflight
  confirma `current_user` e `current_database()`. O child recebe as mesmas
  cinco coordenadas; a senha PostgreSQL não entra em log, manifest, summary,
  arquivo de credenciais ou Git.
- O cleanup consulta o banco administrativo pelas mesmas coordenadas e não
  interpreta falha de probe como ausência. Se o child não publicar o nome do
  banco, registra `not_reported` e falha fechado; `probe_failed`,
  `probe_invalid` e banco ainda presente também permanecem não saudáveis.
- O contrato focal cobre defaults parametrizados, ausência de `-p 5432` e host
  hardcoded em comandos PostgreSQL, forwarding exato, contenção de `DB_PASS` e
  nove entradas inválidas com stubs locais. A prova dinâmica adicional confirma
  que um child não PostgreSQL não recebe `DB_PASS`/`PGPASSWORD`, enquanto o
  stub PG recebe somente `PGPASSWORD`, sem o segredo em `argv`. Nenhum teste
  abriu PostgreSQL, fixture ou captura. A primeira chamada do runner terminou
  com exit `64` por opção CLI incompatível, antes de executar testes; a primeira
  chamada canônica executou `7/8` e encontrou apenas um modificador RegExp
  incompatível no próprio teste. A iteração seguinte concluiu `9/9`, mas foi
  superseded pelo rebaseline do child descrito abaixo.
- A auditoria de segurança encontrou no child já consolidado
  `manaloom_server_contract_e2e_isolated.sh` três usos de `env DB_PASS=...` e
  um `PGPASSWORD` global. O gestor manteve R4 em `NO_GO_R4_SECRET_ARGV` e
  ampliou o allowlist somente para esse path, sem autorizar runtime, banco ou
  outro teste.
- O child agora captura e desexporta as coordenadas e o segredo antes do
  primeiro processo externo, valida host loopback e porta `1..65535`, e remove
  `PGPASSWORD` global. Seus sete comandos PostgreSQL usam um único subshell que
  exporta somente `PGPASSWORD` e executa o guard sem egress. `DB_PASS` é
  exportado somente nos três subshells `exec` destinados a migration, servidor
  e testes; nenhum `/usr/bin/env VAR=...` carrega o segredo em `argv`.
- O contrato final contém `12/12` testes: além dos casos anteriores, prova
  estaticamente os sete callsites PG e os três consumers, nega seis coordenadas
  inválidas do child antes de qualquer processo e usa sentinela dinâmica para
  provar ausência de segredo em child não-PG. Format, analyze, os dois
  `bash -n`, `diff --check`, gitleaks/literais, hardcodes PG, `argv`, path de
  host, allowlist e índice vazio terminaram com exit `0`. Evidência externa:
  `/tmp/manaloom-bt-scp-001-child-secret-final-r2.KNrGI7`, test log
  `dafb7b1908cba95359206337fddd209df7f35ac1b29be09007812e60a6ced5ad`,
  exits `e8697a9226115fce91133a98bde2eee7e67557fb1424247da9ea99ac47efb6a5`
  e contagens `eee6e98b84cbe4154fafbfcacd4591e13dd283363ef4dde2a413d7302303c48e`.
  O manifesto selado exclui a si próprio, cobre os 18 artefatos — inclusive
  `final-exit.txt` e os três hashes de source — e mede
  `403d9e26a2e6b04774191e6a99c052d84bcb0f96229b09874eecc78527689988`;
  sua verificação integral terminou sem divergência.
  A tentativa anterior em `...child-secret-final.H8StSZ` fica preservada como
  `NON_PASS_EVIDENCE_WRAPPER`: os passos haviam terminado verdes, mas o coletor
  zsh encerrou ao reutilizar sua variável reservada `status`; ela não recebe
  crédito final.
- As auditorias independentes de segurança, testes/evidência e equivalência
  emitiram, respectivamente, `GO_PRE_FREEZE`,
  `GO_PRE_FREEZE_TESTS_SEALED` e `GO_PRE_FREEZE_EQUIVALENCE`. A comparação
  incremental reconstruiu byte a byte o child anterior `334862d3…` e limitou o
  delta `0f0ad7b5…` ao scoping de credenciais e validação; adapter/build, guard,
  seeds, rotas, capabilities, Battle/XMage e UX permaneceram equivalentes.
- O freeze final contém 17 sources/contratos em
  `/tmp/manaloom-bt-scp-001-pg-source-freeze.TOfoet`: records
  `fed683cdbcd17103ddb61259e135d35f8fec03bd4e592e3d54f8ddd6745ff01c`,
  patch `c96ef0fcd982ef0ccf51a2e5820e9e6fe73b0d15754ec699ce0787ae937a952f`
  e ficha task-only `a597ccfcc20376edafcfc53f89795f2bb6f3fdd075a2beafadaff2d4a4f097e6`.
  Os 17/17 paths pertencem aos 2.660 inputs declarados; a ficha permanece fora
  do digest por desenho.
- `manaloom_project_logic.sh --write` e `--check` terminaram com exit `0` e
  alteraram conteúdo somente nos quatro gerados autorizados. Logs externos:
  write `5efc9618635beca7a584938bd712323645b0de999a3fbd0399a0f07de127b18d`
  e check `f2c0af25ec5d790e074a77dca6a044afb7bf02f4ab62574a6e5495a24848d818`.
  A recomputação independente produziu project digest
  `9b508844be048b60a6f0f841ac086fc1090319a6ac26b677337649b905a5df98`,
  igual ao manifesto, e UI digest
  `3743cf606069a3e807c2629ac1be98b52eb346c8199c8011ec187723e9858545`.
  Os digests anteriores project `c48ed3f…` e UI `7e7c090b…` ficam somente como
  histórico pré-rebaseline. R4 continua não executada e não autorizada.

## Resultado desta execução

### Dentro do escopo pretendido

- Provar uma policy server-authoritative exata, versionada e fail-closed para
  todas as 29 capabilities.
- Provar que chave ausente, extra ou inválida produz negação antes de
  PostgreSQL, fila, worker ou provider externo.
- Provar que o app apresenta e roteia somente superfícies permitidas pelo
  snapshot válido recebido do backend.
- Manter `account_registration` separada e `OFF`, sem transformar login,
  recuperação ou privacidade de contas existentes em capability de produto.
- Ligar a matriz à release identity da mesma revisão e manter
  `implementation_status`, `release_capability` e `live_verified_as_of` como
  eixos independentes.

### Fora do escopo

- Ligar qualquer capability ou alterar a oferta gratuita sem comércio.
- Declarar produção same-SHA sem observação read-only da revisão publicada.
- Fazer deploy, migration/DML live, criar conta, promover deck/regra, atualizar
  XMage/Forge ou seus pins, ou iniciar outra task funcional.
- Fechar tasks consumidoras apenas porque sua capability permanece `OFF`.
- Alterar partida Play vs AI, Battle, replay, XMage/sidecar, recovery,
  create/delete/finalize, lifecycle de deck, mesa card-first, rematch ou UX.

### Capabilities

- Antes: policy `release_capabilities_v1`, versão
  `brewtact_free_beta_2026-08-13`, oferta `free_beta_no_commerce`, `29/29 OFF`.
- Depois pretendido: `29/29 OFF`; a task prova autoridade e contenção, sem
  promoção funcional.
- Evidência baseline: `server/config/release_capabilities.json`, SHA-256
  `ace782b3969a9ba5a2691f5ca3d97360927919739cd16c796d7b36e8124d754d`.

## Critérios de entrada

- Dependência e receipt: `BT-GOV-001=PASS` em
  `docs/qa/execution/2026-08-14/BT-GOV-001.md`.
- Predecessor operacional: `BT-DOC-004=PASS`, receipt em
  `docs/qa/execution/2026-08-24/BT-DOC-004.md`; publicação do fechamento deve
  ocorrer antes da primeira mudança funcional desta task.
- Baseline reproduzível: matriz commitada com 29 entradas, zero `allowed=true`
  e digest `ace782b3969a…`; o gate `full` passou no SHA baseline.
- Contratos aplicáveis: `AGENTS.md`, decisão corrente, backlog mestre,
  `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`, contrato de release capabilities e
  contrato operacional de release.
- Dados: PostgreSQL/backend permanece verdade; qualquer banco usado nos testes
  será novo, loopback, descartável e removido pelo gate.
- Riscos: divergência app/backend/ops, bypass de rota direta, leitura da policy
  depois de tocar PG/provider, snapshot inválido aceito parcialmente e
  confusão entre código implementado, capability liberada e live verificado.
- Rollback planejado: reverter somente os commits focais, regenerar project
  logic e repetir contratos/full; nenhuma restauração live deve ser necessária.

## Plano de implementação

1. Inventariar policy, parsers, middleware, rotas, jobs, release identity e
   consumers app na mesma revisão.
2. Reproduzir primeiro os gaps com testes negativos determinísticos.
3. Corrigir apenas os pontos onde a autoridade/falha fechada ainda não estiver
   comprovada, mantendo toda capability `OFF`.
4. Provar negação anterior a storage/provider e coerência app/backend/ops.
5. Rodar gates focais, project logic, schema descartável e `full`; emitir
   receipts ligados ao SHA/digest e solicitar auditoria independente.

### Fontes candidatas, ainda sem alteração nesta abertura

- `server/config/release_capabilities.json`
- `server/lib/release_capability_policy.dart`
- middleware e rotas backend protegidas pela policy
- `server/bin/manaloom_ops_daemon.py`
- `app/lib/core/config/release_capabilities.dart`
- guards/consumers app das superfícies protegidas
- `scripts/lib/manaloom_release_capabilities_contract.sh`
- `scripts/manaloom_release_capabilities_contract_test.sh`
- `scripts/manaloom_release_ops_contract_test.sh`
- scripts de release identity e seus testes

### Manifesto de inclusão do cleanroom

O patch canônico foi materializado em
`/tmp/manaloom-bt-scp-001-include-406d7dd53-v2.patch`, com SHA-256
`57315958cb6092555bad92ca9e26d64008dfaf5f35d725ebed10d7d7ac94ced8`.
Ele altera somente os nove paths abaixo; arquivos mistos receberam apenas os
hunks descritos:

- `app/lib/core/config/release_capabilities.dart`: enum fechado de
  `implementation_status` e falha fechada; nenhuma rota Battle/Play.
- `app/test/core/config/release_capabilities_test.dart`: status inválido,
  revogação por falha e concorrência de refresh; nenhuma rota Battle/Play.
- `app/test/core/config/release_capability_surface_contract_test.dart`:
  consumers `deck_replace_all`, `learning_reads` e callback nullable.
- `app/lib/features/decks/screens/deck_details_screen.dart`: ocultação e
  revalidação de `deck_replace_all` antes do diálogo e antes do POST.
- `app/lib/features/decks/widgets/deck_details_overview_tab.dart`: callback de
  import nullable e renderização condicional.
- `app/test/features/decks/screens/deck_details_screen_smoke_test.dart`:
  cenários OFF, ON e revogação sem POST.
- `app/lib/features/decks/screens/deck_generate_screen.dart`: guarda de
  `learning_reads` antes/depois de GET e CTA condicional; copy UX preservada.
- `app/test/features/decks/screens/deck_flow_entry_screens_test.dart`: prova de
  zero GET/CTA quando OFF e capabilities explícitas nos positivos.
- `scripts/manaloom_authenticated_visual_qa_isolated.sh`: somente dois valores
  de fixture ajustados ao enum canônico `experimental_guarded`.

O auditor independente confirmou equivalência byte a byte do diff com o patch,
9 paths exatos, 464 inserções, 49 remoções, zero staged/untracked e ausência de
hunks Play/Battle/XMage/replay/UX. O parecer foi
`GO_TASK_DOCS_AND_FOCALS`; não autoriza commit ou fechamento.

### Gerados derivados esperados

- Os nove artefatos oficiais de project logic, somente via
  `./scripts/manaloom_project_logic.sh --write`.
- Receipts duráveis específicos do gate/release quando houver execução.

### Migration/DDL

- Nenhuma migration ou alteração de DDL está prevista. O gate de schema pode
  criar PostgreSQL exclusivamente loopback em `/tmp` e deve removê-lo ao fim.

## Plano de prova

### Funcional

- Positivo: policy exata 29/29 `OFF` é aceita de forma idêntica por backend,
  app e ops, com identidade versionada.
- Negativo: chave ausente/extra, tipo/enum inválido, `allowed` divergente de
  `release_capability`, digest misto e snapshot incompleto falham fechados.
- Concorrência: processos/isolates carregando a mesma revisão observam a mesma
  matriz; nenhum reload parcial abre uma capability.
- Retry/idempotência: repetir carga, health/readiness e negação de rota não
  muda estado nem toca storage/provider.
- Failure injection: policy ausente/corrompida, endpoint indisponível e chamada
  direta/deep link continuam negados.

### Integração ponta a ponta

- Producer → storage → API → consumer: policy commitada → parser backend →
  middleware antes de PG/provider → `/capabilities`/release identity → provider
  app → navegação/CTA.
- Isolamento A/B: uma identidade/snapshot inválido não herda permissão de outro
  processo, usuário ou cache anterior.
- Cleanup/rollback: PostgreSQL e artefatos temporários descartáveis removidos;
  worktree e processos verificados no fim.

### UI/runtime

- `PASS_AUTOMATED`: testes de provider, guards, rotas e contratos aplicáveis.
- `PASS_RUNTIME`: obrigatório somente se a implementação alterar superfície
  app-facing; usar Android físico ou build Web real.
- `PASS_VISUAL_REVIEWED`: obrigatório somente para delta app-facing, após abrir
  todas as capturas do mesmo digest.
- TalkBack/teclado/permissões: permanecem gates humanos separados de release e
  não recebem crédito antecipado nesta ficha.

### Observabilidade

- Eventos/métricas/logs: registrar somente versão/digest/status da policy e
  motivo estruturado de negação; nunca token, DSN ou conteúdo de deck.
- SLO/alerta/runbook: validar health/readiness e falha da policy nos contratos
  operacionais; mudanças de alerta live ficam fora da autorização.
- Redação/PII: nenhuma capability ou release identity carrega PII.

## Change-control — ownership único de sandbox no build

- R5 permanece `NO_GO_R5_NESTED_SANDBOX_REINIT`: o supervisor externo
  envolveu a fixture, e o kernel recusou o `sandbox-exec` interno. Não houve
  captura, promoção ou crédito UI; o cleanup contratual da fixture permaneceu
  `NON_PASS_NOT_REPORTED`, embora o cleanup físico tenha sido confirmado.
- R6 permanece `NO_GO_R6_COMMAND_MATRIX_BLOCKED` e não foi consumida. O
  preflight provou que o harness ainda envolvia o adapter em `run_no_egress`,
  enquanto o próprio adapter reaplicava deny-all; os controles isolados
  retornaram `0/0` e a composição retornou `71`.
- O rebaseline aprovado atribui ao adapter first-party o ownership exclusivo
  do sandbox deny-all durante o build. O harness chama o adapter diretamente e
  preserva seu guard loopback-only em migrate, servidor, testes e consumers
  PostgreSQL.
- O adapter, seus pins, attestations, validações de lock/cache, publicação
  atômica e dois boundaries Dart sob deny-all não foram alterados. Não existe
  flag de bypass. A recaptura R7, `latest.json`, manifests e PNGs continuam
  fora desta onda e sem crédito.

## Change-control — receipts canônicos de cleanup

- R7 permanece historicamente
  `NO_GO_R7_FIXTURE_CAPABILITY_POLICY_PATH_UNAUTHORIZED`, exit final `1` e
  fixture original `22`, com `0/456` PNGs e `0/26` manifests. A policy isolada
  resolveu abaixo de `/private/tmp`, fora do `Directory.systemTemp` real do
  Dart pinado,
  `/private/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T`; a primeira rota
  protegida respondeu `503 capability_policy_invalid`. O cleanup canônico da
  fixture ficou `NON_PASS_FIXTURE_CLEANUP_CONTRACT`. A recuperação física
  posterior do supervisor não o reclassifica nem concede crédito UI.
- O preflight posterior foi aceito como `NO_GO_NO_CANONICAL_R8`: a ordem então
  disponível permitiria encerrar o PostgreSQL somente depois do receipt da
  fixture, enquanto a fixture exigia o banco já ausente. R8 não foi executada,
  nenhum cluster/captura foi iniciado e não houve promoção de `latest.json`.
- O `GO_REBASELINE_MINIMAL_CANONICAL_CLEANUP_RECEIPTS` mantém a correção sob o
  único NOW `BT-SCP-001` e nos três sources/contratos já allowlisted, mais esta
  ficha task-only. Não houve alteração em app/backend funcional, policy loader,
  capabilities, Battle/Play, UX, fila/backlog ou evidência canônica. Em
  particular, nenhuma autorização da policy foi ampliada para `/tmp`: uma
  futura fixture deverá manter a policy sob o `Directory.systemTemp` real,
  enquanto o PostgreSQL descartável permanece sob `/tmp`.
- O harness backend agora cria grupos de processo próprios para servidor e
  fixture de email, verifica ownership, `TERM`/`KILL`, `wait`, ausência dos
  grupos e listeners, executa `dropdb --force` contra o banco administrativo e
  prova banco ausente. A remoção de `server/build`, `.dart_frog` e temporário
  governado é ligada ao ownership/digest e verificada. Qualquer falha gera
  diagnóstico `NON_PASS`; o receipt terminal
  `manaloom.server_contract_e2e_cleanup_receipt.v1` é atômico, run-bound e só
  existe com todas as contagens em zero.
- A fixture visual aguarda a saída do backend e valida o receipt por schema,
  run pai/filho, run dir, banco, portas e todas as contagens antes de encerrar o
  Web. Depois, prova banco/API/Web/ChromeDriver ausentes e remove/verifica
  credenciais, policy isolada e build Web. O summary é escrito após essas
  provas; o receipt global
  `manaloom.authenticated_visual_cleanup_receipt.v1` só é emitido ao final. O
  worker é one-shot/idempotente; o exit original é preservado somente quando a
  higiene passa, e falha de cleanup sempre resulta em exit não zero.
- O contrato focal final passou `18/18`, sem `SKIP` ou `PARTIAL`. Os cenários
  executáveis cobrem sucesso, falha de `kill`, `wait` e `dropdb`, filho,
  listener, banco e build residuais, receipt ausente/malformado/cross-run,
  symlink hostil e repetição do cleanup após sucesso ou falha. Esses testes
  usam somente processos/stubs e diretórios descartáveis sob
  `Directory.systemTemp`; não iniciam PostgreSQL, fixture, R8 ou captura.
  Format, analyze focal, dois `bash -n`, `git diff --check` e scans focais de
  segredo/guard também passaram.
- A prova controlada adicional com um processo real em PGID próprio confirmou
  `TERM`, `wait=143` e zero membro remanescente, exit `0`; o log externo tem
  SHA-256
  `4879a94bab716f1964f41df508a74eb3bda4933524aad2e36b6b2e952d39edb9`.
- O freeze dos três inputs de lineage está em
  `/tmp/manaloom-bt-scp-001-cleanup-receipts.TeKaic`: patch SHA-256
  `eaf27a970d0c4bd2dcf3f40f493244b7917ec9a574f45178f8c958b32c404585`
  e records SHA-256
  `356295f7651b3701dbc024e204ab46b3a09a6677109e553e9df41d8c31e7de34`.
  Os hashes finais são `47fd414ada71…` para o harness backend,
  `1aa64762213d…` para a fixture e `1c9fde1fa06d…` para o teste focal.
- `manaloom_project_logic.sh --write` e `--check` terminaram com exit `0`.
  Somente manifesto, `CURRENT_SYSTEM.md`, OpenAPI e `TASK_REGISTRY.json`
  mudaram entre as nove saídas oficiais; as outras cinco ficaram
  byte-idênticas. O project digest recomputado é
  `6269fc8f899d3dd61a01d7fe8d4f81a59d0935dea6f09348b87d86c0a6f2df93`
  e o UI source digest é
  `417a59b4b780032d54c766931ec9ad916f2f468174159b1d3c2ff423deb452d6`.
  R8, broad gates, receipt de fechamento, staging, commit, push, deploy e live
  permanecem não executados e não autorizados nesta onda.
- A auditoria independente final devolveu
  `GO_REBASELINE_MINIMAL_CANONICAL_CLEANUP_RECEIPTS`, sem achado P0/P1/P2.
  Ela reconciliou freeze, allowlist, testes, prova real, quatro gerados,
  digests, `29/29 OFF`, checkout principal e higiene final. O parecer é
  estritamente deste rebaseline e não autoriza R8, captura, broad gate,
  fechamento, receipt canônico de release ou promoção.

## Change-control — compatibilidade jq do READY manifest pós-R9

- A tentativa única R9 permanece
  `NO_GO_R9_READY_MANIFEST_JQ_PARSE_ERROR`, sem reclassificação ou crédito
  parcial. A correção process-scoped do Dart funcionou: o adapter resolveu o
  SDK pinado sob Flutter `3.44.6`, terminou `PASS_OFFLINE_BUILD_ADAPTER` com
  Dart `3.12.2`, Dart Frog CLI `1.2.14`, 120 rotas e 16 middlewares. A fixture,
  porém, encerrou com exit `3` ao compilar o READY manifest no
  `jq-1.7.1-apple`; o supervisor terminou com exit `1`.
- O bloqueio foi a única concatenação não parentizada do filtro READY,
  `global_receipt: $run_dir + "/global-cleanup-receipt.json"`, em
  `scripts/manaloom_authenticated_visual_qa_isolated.sh`. Nenhum estágio de
  captura começou: R9 preserva `0/456` PNGs e `0/26` manifests, os 682
  artefatos preexistentes ficaram byte a byte e mtime idênticos e
  `latest.json` permaneceu histórico/stale. Os receipts backend e global
  receberam `PASS_CLEANUP` somente para higiene, com SHA-256
  `5b0124c38af6…` e `c9b0e4fe1c53…`; o summary mede `f09d64722913…`.
  PG, listeners, processos, build e temporários ficaram em zero. O checkpoint
  auditado tem SHA-256
  `405962aa67fce10597842a0b949f6f46508397d9d63c706a1e64f543115bd61b`.
- O `GO_REBASELINE_MINIMAL_READY_MANIFEST_JQ_COMPAT` autoriza exclusivamente
  parentizar essa expressão, ampliar o contrato focal da fixture e registrar
  fatos nesta ficha, além dos gerados oficiais derivados. R10, fixture,
  captura, broad gates, backlog/fila, app/backend funcional, policy, Battle,
  UX, evidência, staging, commit, push, deploy e live continuam fora desta
  onda.
- A expressão agora é explicitamente
  `global_receipt: ($run_dir + "/global-cleanup-receipt.json")`. O contrato
  extrai o filtro READY versionado, resolve o `jq` real do `PATH`, executa o
  programa com todos os argumentos, valida `status`, `run_dir` e o path final
  do receipt e injeta a variante antiga para provar falha sintática. O binário
  auditado é `/usr/bin/jq`, versão `1.7.1-apple`, SHA-256
  `cf289ed3e8cee41f4b5f1a5d75bd0895faf15ed71fae8df4298a5ccf59d3d008`.
- `bash -n`, format e analyze focal passaram. A suíte focal concluiu `20/20`,
  sem `SKIP` ou `PARTIAL`, incluindo os dois casos jq positivo/negativo; log
  SHA-256 `bef0bf977fb408cec9af6c0cc0292f904d0f8ef27b87921c838619df0a6349f5`.
  Os hashes pós-hunk, antes desta ficha task-only, são
  `82bd2c50e224…` para a fixture e `67015a398adf…` para o teste.
- O freeze final em
  `/tmp/manaloom-bt-scp-001-ready-jq-rebaseline.Qsf56L` mantém os 22 paths
  anteriores; apenas fixture, teste e esta ficha divergem do freeze R9. O
  inventário congelado mede `70a96b6a8c5e…` e a comparação incremental
  `1e9fc7869461…`. `project_logic --write` e `--check` terminaram com exit
  `0`, alterando somente manifesto, `CURRENT_SYSTEM.md`, OpenAPI e
  `TASK_REGISTRY.json`; os outros cinco gerados ficaram byte-idênticos. O novo
  project digest é
  `9f2209c5216a4a78eecfd9c17dea47080ef19aade0b648a7726ea9aa8f2a2e0c`
  e o UI source digest é
  `744017c61b31f597b7b500918f3071f711428277a5c69bfcd26742615a2de110`.
  R10 não foi executada e nenhum crédito UI/E2E foi concedido.

## Change-control — contenção de egress Android visual pós-R10/R11

- R10 permanece `NO_GO_R10_ANDROID_EXTERNAL_EGRESS`. As 456 capturas e os
  26 manifests estruturalmente produzidos continuam históricos, sem crédito
  visual ou E2E; a revisão parou em `60/456` e `latest.json` permanece
  intocado no SHA-256 `be4bee6d08d3…`. A reconciliação R11 confirmou
  `456/456` hashes PNG idênticos aos records R10 e preservou os 106 outputs
  modificados sem promoção.
- O `GO_REBASELINE_MINIMAL_ANDROID_VISUAL_EGRESS_CONTAINMENT` foi limitado ao
  overlay profile Android, guard tardio de push, guard físico de rede/log,
  runner/indexador/policy/testes, lineage UI/project, contrato UI, esta ficha
  e gerados oficiais derivados. Não houve alteração em Gradle, lock, sources
  Android específicos de release, backend funcional, capabilities,
  Battle/Play, UX, backlog, fila ou evidência canônica. O único source
  funcional compartilhado do app alterado foi o guard de push, cujo default
  `false` preserva a semântica release pretendida, ainda sem prova binária.
- O delta R11 implementado cobre três camadas em 15 paths autorizados: o
  overlay profile remove 15 initializers nativos e fixa quatro kill switches;
  `DISABLE_PUSH_INIT` fecha o background handler e `_initInternal`; o guard
  físico fotografa rede/reverse, isola Wi-Fi/dados, preserva ADB USB e
  loopback, limpa app/DataTransport, coleta logcat por UID e exige receipt
  antes de copiar PNG ou indexar manifest. Release mantém os defaults
  semânticos anteriores; somente seus sources Android específicos permaneceram
  byte-idênticos, sem prova binária do artefato.
- Os focais anteriores concluíram `30/30` sem `SKIP/PARTIAL`, com analyze
  focal limpo. Depois do adapter Gradle process-scoped, o contrato Android foi
  reexecutado e concluiu `5/5`; `bash -n`, `git diff --check` e o scan focal de
  segredos também passaram. O caso R10
  `TRuntime.CctTransportBackend -> firebaselogging-pa.googleapis.com` agora é
  reproduzido como FAIL, enquanto endpoint loopback exato é aceito.
- O merged manifest profile intermediário foi produzido no SHA-256
  `22e66e9cb78f…`: os 15 componentes proibidos estão ausentes e as quatro
  metadata estão presentes. Isso é prova parcial; nenhum APK profile novo foi
  produzido. O merged release existente e o baseline anterior são
  byte-idênticos no SHA-256 `586144e5b129…`, mas o artefato release não foi
  regenerado depois dos hunks e não recebe crédito de equivalência binária.
- As três provas de build são preservadas como `NON_PASS`: R1 exit `1`, hook
  SQLite tentou GitHub (`f783f74f1e81…`); R2 exit `1`, metadata Gradle tentou
  Maven (`2d0b2c7a5523…`); R3 registrou `offline=true` duas vezes, não mostrou
  tentativa externa no log e falhou em
  `:integration_test:compileProfileJavaWithJavac` porque
  `androidx.test:runner:1.2+` não possui version listing no cache offline
  (`900eead33312…`). R3 não emitiu exit marker externo por uso incorreto de
  `PIPESTATUS` no supervisor zsh; o log interno registra exit `1`, suficiente
  apenas para `NON_PASS`. O APK R10 `565c80197d54…` continua stale e isolado;
  o path governado do APK novo está ausente.
- A auditoria independente encerrou esta onda como
  `STOP / NO_GO_R11_PROFILE_OFFLINE_BUILD`. Antes de R12 ainda são blockers:
  rebaseline explícito para as dependências dinâmicas do plugin Flutter
  (`runner:1.2+`, com riscos seguintes `rules:1.2+` e
  `espresso-core:3.3+`); janela temporal e enumeração real de todos os PIDs do
  logcat; trap antes de qualquer temporário/mutação; restauração de
  rotação/immersive no Samsung; cardinalidade correta do atestado Gradle; e
  validação XML acoplada de metadata. Nenhum contorno, edição Gradle/lock,
  download ou R12 foi executado.
- O checkpoint permanece com `142` paths (`36` fontes/contratos + `106`
  outputs R10), quatro untracked allowlisted, índice vazio e `diff --check`
  verde; fingerprint `27e09bb1e5fb…`. Capabilities continuam `29/29 OFF`, o
  checkout principal continua em 271 entradas/fingerprint `61ba4a3e97ff…`,
  e não há processo, listener, socket ou temporário operacional residual; os
  artefatos externos R1–R3 permanecem preservados como evidência. Como a regra
  de STOP foi acionada, `project_logic --write/check` não rodou: o digest declarado
  `9f2209c5216a…` e os quatro gerados estão stale para o delta R11. O UI digest
  corrente, ainda não promovido, é `22c6df916173…`.

## Change-control — checkpoint técnico pausado por prioridade do usuário

- A decisão de fechamento de 2026-08-28 substitui qualquer proposta de novo
  launcher ou nova prova: o veredito desta branch é
  `CHECKPOINT_COMMITTED_NO_GO / PAUSED_BY_USER_PRIORITY`. Não foi implementada
  invocação direta de `flutter_tools.snapshot`; R12, recaptura, promoção de
  evidência, broad gates, PR, merge, deploy, migration e escrita live não
  foram executados.
- O código preservado fecha os quatro gaps delimitados antes do checkpoint:
  binding do build/staging ao run governado; ownership e término verificável
  do process group antes do restore; canary e telemetria unificada ligados ao
  `run_id`; e recusa do modo child fora do staging/artefato governado. O
  adapter Gradle continua process-scoped, deriva os três pins do lock, mantém
  SDK/cache read-only e produz receipt fail-closed; o receipt Android v1 e o
  falso verde R10 continuam inelegíveis.
- A matriz focal pré-prova passou: `bash -n`, ShellCheck, oito heredocs Python,
  format com zero mudança, analyze, testes e provas controladas de process
  group/canary. A prova real do canary negou o TCP loopback
  `127.0.0.1:9` com exit `73`/`EPERM`, encontrou exatamente a decisão da
  sandbox no Unified Log e encontrou zero marcador de rede real. Os dois
  auditores read-only devolveram `GO_PROFILE_PROOF` somente para consumir a
  prova profile, não para UI/release.
- A única prova profile terminou em
  `NO_GO_PROFILE_PROOF_FLUTTER_SDK_BOOTSTRAP_WRITE_DENIED`, exit `1`, antes de
  o Gradle iniciar (`events=0`). `bin/flutter` entrou em
  `shared.sh -> upgrade_flutter -> update_engine_version.sh` e tentou gravar
  `engine.stamp.tmp`, `engine.stamp` e `engine.realm`; a sandbox negou essas
  escritas porque o SDK pinado é somente leitura. `--no-version-check` é
  processado tarde demais para impedir esse bootstrap. A tentativa está
  consumida e não houve retry.
- O cleanup da prova ficou em `cleanup_complete`: PID/PGID `40211`,
  listeners, quarentenas, APK, XML e receipt terminal promocional ficaram em
  zero. O `app/build` preexistente foi restaurado byte a byte no SHA-256
  `0642fda1…`, com 11.245 entradas. SDK, caches e inputs protegidos ficaram
  imutáveis. A prova externa permanece em
  `/tmp/manaloom-bt-scp-001-profile-proof.jeLhz8`; o log mede
  `523ecdea…`, o supervisor `2f73557f…` e o freeze `55343682…`.
- Os 106 outputs R10 não promovidos (`39` goldens e `67` outputs `docs/qa`)
  foram preservados 106/106, fora do Git, no pacote content-addressed
  `/Users/desenvolvimentomobile/Library/Application Support/ManaLoom/checkpoints/BT-SCP-001/r10-unpromoted/e114bf89c66590f2e6f68fcde0caf55c088053957481a3dd938cba487776688b`.
  O pacote contém 12.068.745 bytes; `manifest.json` mede
  `de1dd7fccf80…` e `SHA256SUMS` mede `79134f9fd035…`. Depois da verificação
  integral, os 106 paths foram restaurados ao `HEAD`; a cópia externa não foi
  apagada e `latest.json` continua intocado, sem crédito visual/E2E.
- O fechamento proporcional repetiu sintaxe/formatação e análise sem issues,
  `104/104` testes Flutter e `40/40` contratos backend. O focal do gerador
  detectou, antes da regeneração, exatamente os quatro gerados oficiais
  stale; esse resultado pré-write permanece registrado como
  `NON_PASS_EXPECTED_DRIFT`. Depois do freeze, `project_logic --write` e
  `--check` terminaram `0/0`, mudando somente manifesto, `CURRENT_SYSTEM.md`,
  OpenAPI e `TASK_REGISTRY.json`; os outros cinco gerados ficaram
  byte-idênticos. O rerun do gerador concluiu `27/27`. O project digest final
  é `6a48a6031e168e2c71b98704b6c38b2d492bbeb95c9c90a70b91d13044621569`
  e o UI source digest é
  `a15b6abed94510d318d9116b83243823f3182872b8ea82722286c5811c996875`.
  Logs ficam em `/tmp/manaloom-bt-scp-001-close.ZWvSbH`; sintaxe/formato mede
  `216a87041827…`, analyze válido `11fc8ea5b409…`, app `6399d9ff9867…`,
  backend `c72046d1158c…`, detector pré-write `487758dd9d98…`, write
  `5efc9618635b…`, check `f2c0af25ec5d…` e focal pós-write
  `2757fdfb11c…`.
- Nenhuma captura desta frente recebe `PASS_RUNTIME` ou
  `PASS_VISUAL_REVIEWED`; não existe receipt same-SHA/release. O próximo
  writer será a frente app/Web, e esta frente permanece pausada após o
  commit/push do checkpoint.

## Gates executados

| Gate | Comando | Esperado | Real | Exit | SHA | Artefato/hash |
| --- | --- | --- | --- | ---: | --- | --- |
| Baseline herdado | `./scripts/manaloom_local_ci.sh full` | baseline saudável antes da task | `PASS`; nenhuma implementação de `BT-SCP-001` atribuída | `0` | `d9f7a59cd87d032df3d076c35ffbdb17e41525a6` | receipt de `BT-DOC-004` |
| Cleanroom allowlist | patch v2 + buscas negativas + `git diff --check` | somente 9 recortes, sem parked/stale/generated | `PASS`; 9 paths, `464/49`, zero staged/untracked | `0` | `406d7dd533f0ff0ae8294f8b9de94fecc07bf24e` | patch SHA-256 `57315958cb60…` |
| Auditoria de equivalência | revisão read-only hunk a hunk | diff idêntico ao manifesto | `GO_TASK_DOCS_AND_FOCALS`; commit/fechamento não autorizados | `0` | `406d7dd533f0ff0ae8294f8b9de94fecc07bf24e` | status original `61ba4a3e97ff…` |
| Analyzer app focal | Flutter `analyze --no-pub` nos 8 sources/testes Dart | zero issues | `PASS`; zero issues | `0` | worktree | Flutter `3.44.6`, Dart `3.12.2` |
| Parser e consumers app | Flutter `test --no-pub` nos 4 testes focais | enum/negativos/guards/revogação `PASS` | `PASS`; `58/58` | `0` | worktree | inclui 6 status canônicos e revogação GET |
| Policy server-authoritative | Dart `test test/release_capability_policy_test.dart` | matriz/ordem/registro `PASS` | `PASS`; `16/16` | `0` | worktree | policy `ace782b3969a…` |
| Fixture isolada | `bash -n` + busca dos dois status canônicos | sintaxe válida; zero status ad hoc | `PASS`; 2 ocorrências `experimental_guarded` | `0` | worktree | `isolated_visual_fixture` ausente como status |
| Auditoria pós-focais | revisão read-only de código, testes, ficha e patch | checkpoint coerente, sem overclaim | `GO_CHECKPOINT_BEFORE_BROAD_GATES`; correção documental revalidada | `0` | worktree | patch checkpoint SHA-256 `1f350391330a…` |
| Autorização gates amplos | `GO_BROAD_GATES_CONTAINED` | sequência contida; nenhuma promoção ou escrita live | recebido; execução posterior ao freeze | — | worktree | freeze `2026-08-26T15:36:31Z` |
| Project logic pré-rebaseline | `manaloom_project_logic.sh --write` e `--check` | 9 artefatos sincronizados | `PASS/PASS`; posteriormente invalidado pelo rebaseline | `0/0` | worktree | 4 artefatos derivados mudaram |
| Full pré-rebaseline | `./scripts/quality_gate.sh full` | app/backend/Web/performance completos | `FAIL` determinístico no inventário UI; backend e analyzer app `PASS`; Flutter `1573 PASS`, `1 SKIP`, `1 FAIL`; Web/performance não iniciados | `1` | worktree | esperado 14, real 15 transients em Deck Generate |
| Rebaseline UI inventory | dois contratos governados, três valores | refletir um único `SnackBar` fail-closed | aplicado; auditoria mínima e reinício dos gates pendentes | — | worktree | `GO_REBASELINE_UI_INVENTORY_MINIMAL` |
| Auditoria mínima pós-rebaseline | revisão read-only dos dois contratos | somente três valores; zero contaminação | `GO_RESTART_PROJECT_LOGIC`; zero staged/untracked | `0` | worktree | freeze r1 `51fa17714dfd…` |
| Project logic pós-rebaseline | `manaloom_project_logic.sh --write` e `--check` | 9 artefatos sincronizados no novo digest | `PASS/PASS` antes deste checkpoint task-only | `0/0` | worktree | source digest `02d08edaaad1…` |
| Full pós-rebaseline #2 | `./scripts/quality_gate.sh full` | app/backend/Web/performance completos e exit terminal | `ABORTED_NO_EXIT_CODE (NON_PASS)`; runner perdido durante Flutter, sem resultado final; nenhum crédito parcial | não emitido | worktree | backend/analyzer/inventory verdes; `>=665` Flutter observados; PID órfão `61195` |
| Cleanup do runner órfão | `TERM` + `ps`/`pgrep`/`lsof` | zero processo/listener do cleanroom | `PASS`; zero resíduos do gate | `0` | worktree | `2026-08-26T16:35:33Z` |
| Digest R2 recomputado | algoritmo canônico + auditor independente | coerência com todos os `lineage.digest_inputs`; valor pode permanecer idêntico | `GO_FULL_R2_SAME_DIGEST_EXPECTED`; packet com identidade separada | `0` | worktree | source `02d08edaaad1…`; freeze R2 `8b8a9e3dc255…` |
| Full R3 com Node suportado | `PATH=/opt/homebrew/bin:$PATH ./scripts/quality_gate.sh full` | todas as fases e exit terminal `0` | `PASS` global; backend `2283`, analyze, Flutter `1574 PASS/1 SKIP`, Web e performance concluídos | `0` | worktree | log `9f1c8da816d5…`; exit `71a69e43f74c…`; Web `dc12dfdb1714…` |
| Schema descartável R1 | `MANALOOM_KEEP_LOCAL_GATE_ARTIFACTS=1 ./scripts/manaloom_tbls_local_gate.sh` | PG novo em `/tmp`, loopback; DB tests e tbls/schema completos | `NON_PASS_SCHEMA_AUDITED`; `loadedPostgres p95 540 > 500`; 4 DB verdes/1 falha; tbls não alcançado; run fora de `/tmp` literal | `1` | worktree | log `e6de1b37cf1e…`; exit `50d18e605365…`; artefatos `.../manaloom_tbls_local.logquz` |
| Cleanup/auditoria schema R1 | `pg_controldata`, `pg_ctl`, `pg_isready`, `ps`, `lsof` e auditor independente | cluster parado e isolamento provado | `PASS` operacional de cleanup; zero servidor/listener em `127.0.0.1:58722`; nenhum crédito de schema/Battle | `0` | worktree | `NON_PASS_SCHEMA_AUDITED`; migrations `d89532ac5792…`; DB tests `c85db960cbf7…` |
| Schema descartável R2 | `TMPDIR=/tmp MANALOOM_KEEP_LOCAL_GATE_ARTIFACTS=1 ./scripts/manaloom_tbls_local_gate.sh` | retry único; cinco testes DB; tbls/schema completos em loopback e `/tmp` literal | `PASS_SCHEMA_R2_AUDITED`; `5/5`; 79 tabelas, 6 views, zero drift de colunas, 98 FKs e 58 migrations | `0` | worktree | log `31c9027e2d37…`; exit `5ca383cdd0c8…`; artefatos `/tmp/manaloom_tbls_local.EJ1693` |
| Cleanup/auditoria schema R2 | `pg_controldata`, `pg_ctl`, `pg_isready`, `ps`, `lsof` e auditor independente | cluster parado; R1/R2 separados; Mailhog intocado | `PASS`; fast shutdown em 44 ms; zero servidor/socket/listener em `127.0.0.1:50787`; R1 continua `NON_PASS` | `0` | worktree | DB tests `0e8a06a747d5…`; schema `330b7593a961…`; digest `02d08edaaad1…` |
| Capabilities/release identity local | `bash ./scripts/manaloom_release_capabilities_contract_test.sh` | policy e identidade por fixture, sem live write | `PASS`; matriz exata 29/29 `OFF` | `0` | worktree | log `4ade0d76d0ab…`; exit `151a63895e51…` |
| Deck/IA/Learning local | `bash ./scripts/manaloom_deck_ai_learning_gate.sh --profile local` | exatamente `PASS_CODE_ONLY`, rede negada e zero mutação | `PASS_CODE_ONLY`; `15/15`, `release_eligible=false` | `0` | worktree | summary `13201fc52ec8…`; manifest `b9a4776e251a…` |
| Web pública estrutural | `bash ./scripts/manaloom_public_web_surface_contract_test.sh` | contratos estruturais locais | `PASS` | `0` | worktree | log `00fffb9e4c3b…`; exit `27cf35794819…` |
| Release-ops 4a R1 | `bash ./scripts/manaloom_release_ops_contract_test.sh` | resolver SDK aprovado | `NON_PASS` histórico; Flutter global incompatível | `2` | worktree | log `aa44846adb00…`; exit `6c0ab672f3c3…` |
| Release-ops 4a R2 | `MANALOOM_FLUTTER_BIN=.../flutter-3.44.6/bin/flutter bash ./scripts/manaloom_release_ops_contract_test.sh` | retry único process-scoped | `PASS`; 32 contratos, suites `5/5` e `12/12`; repetições Web/capabilities redundantes | `0` | worktree | log `d3a5573e8789…`; exit `bbb7d445272e…` |
| Ops daemon 4b | `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest server.test.manaloom_ops_daemon_test` | suíte local completa | `PASS`; `20/20` | `0` | worktree | log `57a671430fc0…`; exit `c55ff7ffa29f…` |
| Receipt validator local | `PYTHONDONTWRITEBYTECODE=1 python3 server/test/deck_ai_learning_receipt_validator_test.py` | contrato do validator, sem receipt canônico | `PASS`; `18/18`; somente receipts sintéticos | `0` | worktree | log `6883072130b9…`; exit `66cee0656292…` |
| Auditoria matriz especializada | revisão read-only de comandos, hashes, escopo e cleanup | distinguir local de release/Battle | `PASS_SPECIALIZED_CONTRACT_MATRIX_LOCAL_ONLY`; 4a R1 preservado `NON_PASS` | `0` | worktree | 16 paths; zero staged/untracked; zero resíduo atribuível |
| Fixture/captura UI R1–R3 | harness isolado sob guard sem egress | runtime same-digest sem tentativa de resolução | `NON_PASS`; três runs históricos preservados, sem crédito; R4 não executado | não promovido | worktree | aggregate `d517adb6…` permanece stale |
| Contrato do adapter offline | Dart focal pinado + `bash -n` + analyze | positivos/negativos fail-closed sem pub/updater | `PASS`; `20/20`, format/analyze/sintaxe limpos | `0` | worktree | sources `51948fe4…`, `74694b9d…`, `334862d3…`, `164a58dd…`, `c3058c04…` |
| Build offline positivo | adapter first-party sob sandbox deny-all | build novo e estruturalmente equivalente | `PASS_OFFLINE_BUILD_ADAPTER`; 1.128/1.128 paths, 120 rotas e 16 middlewares | `0` | worktree | log `32d7a7493d72…`; build `52f89a36454c…`; inputs `d03d36ff5bc2…` |
| Kernel/zero-attempt do adapter | kernel compile + log unificado do PID `83674` | servidor compilável; zero resolver/updater/pub/remote | `PASS`; kernel gerado e zero tentativa atribuível | `0/0` | worktree | kernel `4066c5e7b42b…`; prova `1fc34d875a3e…` |
| Auditoria independente do adapter | revisão API, equivalência, segurança, linhagem e cleanup | allowlist/fail-closed/zero-attempt coerentes | `GO_CODE_AND_ZERO_ATTEMPT` + `GO_STRUCTURAL_PRE_FREEZE` + `GO_FINAL_POST_PROJECT_LOGIC` | `0` | worktree | build/cache ausentes do cleanroom; zero resíduo |
| Project logic do adapter | `manaloom_project_logic.sh --write` e `--check` | gerados oficiais sincronizados após freeze | `PASS/PASS`; somente quatro gerados previstos; primeira invocação sem exit continua sem crédito | `0/0` | worktree | logs `5efc9618635b…`/`f2c0af25ec5d…`; source `c48ed3f1420e…`; UI `7e7c090b197f…` |
| Rebaseline PG da fixture visual | harness + child + contrato focal | coordenadas parametrizadas; credenciais fora de argv/global/non-PG | `PASS_LOCAL_REBASELINE_AUDITED`; 3 GOs; project logic `0/0`; R4/cluster não executados | `0` local | worktree | freeze `fed683cd…`; project `9b508844…`; UI `3743cf60…`; nenhuma autorização de captura/release |
| Contrato focal de coordenadas PG/credenciais do child | format + analyze + `dart test` + dois `bash -n` + scans | inválidos negados antes de child; secrets fora de argv e de filhos não-PG; PG recebe só `PGPASSWORD`; três consumers exatos | `PASS`; `12/12`; nove negativos do harness + seis do child; CLI exit `64`, RegExp `7/8`, prova `9/9` superseded e wrapper H8StSZ NON_PASS preservados | `0` final | worktree | nenhum PostgreSQL, fixture, R4 ou captura iniciado; evidência final `...final-r2.KNrGI7` |
| UI R5 — dupla sandbox externa/interna | supervisor R5 + fixture canônica | runtime same-digest ou NO-GO literal | `NO_GO_R5_NESTED_SANDBOX_REINIT`; fixture `1`, supervisor `82`; `0/456`; nenhum retry | `82` | worktree | pacote auditado `a358fe83d364…`; cleanup fixture `NON_PASS_NOT_REPORTED` |
| UI R6 — matriz de comando pré-runtime | controles sandbox isolados e composição harness → adapter | exatamente um owner antes de PG/fixture | `NO_GO_R6_COMMAND_MATRIX_BLOCKED`; controles `0/0`, nested `71`; R6 não consumida | `71` diagnóstico | worktree | pacote auditado `20596fb4a5f2…`; zero PG/fixture/captura |
| Rebaseline ownership único — focal | `bash -n`; format/analyze; `dart test`; adapter boundary direto | chamada direta, deny-all preservado, sem reentrada | `PASS`; `20/20`; build `1.128` paths, `120` rotas, `16` middlewares; zero evento de reentrada/resolver | `0` | worktree | harness `28fe6ee6…`; teste `e113f65c…`; log `02bbf720…`; build `299884ea…` |
| Project logic do ownership único | `manaloom_project_logic.sh --write` e `--check` | somente quatro gerados com delta e cinco byte-idênticos | `PASS/PASS`; lista de `2.660` inputs preservada; nenhum gerado inesperado | `0/0` | worktree | project `2eaa1bcad155…`; UI `7ef104b9fd69…`; logs `3af9799b…`/`dc31028e…` |
| Runtime live read-only | task Hermes `01a03f15-9a4e-7393-8f34-1106abc07190` | same-SHA e policy fail-closed | `SERVER_BEHIND + POLICY_DRIFT`; ops 23 commits atrás, backend 19; `/capabilities` 404 | — | live observado | sem mutação; nenhum live/release PASS |
| UI R7 — policy isolada fora do system temp | supervisor e fixture canônicos | 26 manifests/456 capturas same-digest ou NO-GO literal | `NO_GO_R7_FIXTURE_CAPABILITY_POLICY_PATH_UNAUTHORIZED`; fixture cleanup `NON_PASS`; recuperação externa sem crédito | `1` final; fixture `22` | worktree | `0/456`, `0/26`; checkpoint `/tmp/manaloom-bt-scp-001-r7.FRTVT4/checkpoint-no-go.md` |
| Preflight R8 read-only | desenho de system temp/PG/ordem de cleanup | comando canônico sem ciclo de dependência | `NO_GO_NO_CANONICAL_R8`; nenhuma tentativa, cluster ou captura | — | worktree | policy em system temp e PG em `/tmp`; ordem de receipt ainda impossível antes deste rebaseline |
| Receipts canônicos de cleanup — focal | format + dois `bash -n` + analyze + Dart focal + failure injection | cleanup one-shot/fail-closed e receipts run-bound | `PASS`; `18/18`, zero `SKIP/PARTIAL`; nenhuma R8/PG/captura | `0` | worktree | logs `201363ae…`/`e3b0c442…`/`307a08df…`/`135c6cd5…`; freeze `eaf27a97…` |
| Project logic dos receipts de cleanup | `manaloom_project_logic.sh --write` e `--check` | somente gerados oficiais derivados | `PASS/PASS`; quatro outputs com delta, cinco byte-idênticos | `0/0` | worktree | project `6269fc8f899d…`; UI `417a59b4b780…` |
| Auditoria independente dos receipts de cleanup | revisão read-only de hunks, freeze, gates, digests, policy e higiene | zero blocker e nenhuma ampliação de autorização | `GO_REBASELINE_MINIMAL_CANONICAL_CLEANUP_RECEIPTS`; nenhum P0/P1/P2; não autoriza R8 | `0` | worktree | status `748c0f2f…`; main checkout `61ba4a3e…`; process proof `4879a94b…` |
| UI R9 — Dart process-scoped e READY manifest | supervisor R9 + fixture canônica | 26 manifests/456 capturas same-digest ou NO-GO literal | `NO_GO_R9_READY_MANIFEST_JQ_PARSE_ERROR`; adapter PASS, fixture `3`, supervisor `1`; nenhum stage iniciado | `1` | worktree | `0/456`, `0/26`; checkpoint `405962aa67fc…`; cleanup canônico verde sem crédito UI |
| Rebaseline jq do READY — focal | `bash -n`; jq real; format/analyze; Dart focal | filtro versionado compila/executa; regressão antiga é recusada | `PASS`; `20/20`, zero `SKIP/PARTIAL`; dois casos jq reais | `0` | worktree | fixture `82bd2c50e224…`; teste `67015a398adf…`; log `bef0bf977fb4…` |
| Project logic do rebaseline jq | `manaloom_project_logic.sh --write` e `--check` | somente gerados oficiais derivados | `PASS/PASS`; quatro outputs com delta, cinco byte-idênticos | `0/0` | worktree | project `9f2209c5216a…`; UI `744017c61b31…`; freeze `70a96b6a8c5e…` |

## Receipts

| Contrato | Producer | Status | Path/hash | Durável | Bindings revisados |
| --- | --- | --- | --- | --- | --- |
| Baseline policy | repository | observado | `server/config/release_capabilities.json` · `ace782b3969a…` | yes | revisão baseline |
| Inclusion manifest | `/root` + auditor independente | `PASS_READ_ONLY` | patch temporário · `57315958cb60…` | no; reproduzível pelo diff | base, allowlist, hunk e checkout original |
| `BT-SCP-001` | `/root` | não emitido | será definido no fechamento | yes | SHA/digest/target obrigatórios |

## Aceite canônico

| Cláusula resolvida do registry | Evidência nesta abertura |
| --- | --- |
| Flag ausente/inválida fica OFF | `PASS` focal: 6 status canônicos aceitos; unknown/schema/matriz inválidos negam tudo |
| API nega antes de PG | `PASS` focal server: gate central, policy inválida, registro e rota futura negam antes de handler/PG |
| App só apresenta o permitido | `PASS_AUTOMATED` focal para `deck_replace_all` e `learning_reads`, inclusive revogação em voo; runtime same-digest pendente |
| Cadastro novo separado e OFF | `PASS` focal server: `account_registration` nega antes de handler/PG e control-plane permanece separado |
| Same-SHA registra a matriz | `BLOCKED`: live observado em dois SHAs anteriores, sem capability file; receipt canônico pendente |
| Três eixos permanecem distintos | `PASS` local em parser, endpoint e matriz especializada; live continua `SERVER_BEHIND + POLICY_DRIFT` |

## Fechamento

- Resultado E2E estrito: `CHECKPOINT_COMMITTED_NO_GO`; o `FULL_R3`, o schema R2 e a matriz
  especializada local passaram, mas o R1 continua preservado como
  `NON_PASS_SCHEMA_AUDITED` histórico, o live está
  `SERVER_BEHIND + POLICY_DRIFT` e ainda não há crédito E2E, release ou
  fechamento
- Gate-eligible: `false`
- Release identity: produção reobservada read-only e classificada
  `SERVER_BEHIND + POLICY_DRIFT`; ops e backend estão, respectivamente, 23 e
  19 commits atrás da base, sem matriz de capabilities conforme a policy
- Bloqueios: `FLUTTER_SDK_BOOTSTRAP_WRITE_DENIED`, evidência UI same-digest,
  convergência live/same-SHA da policy, receipt canônico final e auditoria do
  índice exato
- Riscos residuais: a policy base ainda associa todo `PUT /decks/:id` a
  `deck_replace_all`; o focal server confirma essa classificação, mas nenhuma
  cobertura universal de edição de deck ou fechamento de `DCK-P0-00` é
  reivindicada nesta task
- Rollback verificado: patch v2 foi revertido até worktree limpo e reaplicado
  com sucesso; o delta posterior de ficha/testes ainda será auditado
- Auditor independente: inclusão `GO_TASK_DOCS_AND_FOCALS`; auditoria
  pós-focais revalidada como `GO_CHECKPOINT_BEFORE_BROAD_GATES`; auditoria
  do schema R1 retornou `NON_PASS_SCHEMA_AUDITED`; retry único R2 retornou
  `PASS_SCHEMA_R2_AUDITED`, sem reclassificar R1; matriz especializada retornou
  `PASS_SPECIALIZED_CONTRACT_MATRIX_LOCAL_ONLY`, sem reclassificar o 4a R1 e
  sem conceder release, receipt ou Battle; auditoria final do índice exato
  ainda `pending`
- Veredito da execução:
  `CHECKPOINT_COMMITTED_NO_GO / PAUSED_BY_USER_PRIORITY`; isto não fecha nem
  promove `BT-SCP-001`, UI, E2E ou release
- Commit que registra este checkpoint: objeto Git desta ficha, com Task ID e
  SHA reportado no handoff; nenhuma reescrita histórica
- Próximo ID elegível depois do fechamento: `BT-OFFER-001`
