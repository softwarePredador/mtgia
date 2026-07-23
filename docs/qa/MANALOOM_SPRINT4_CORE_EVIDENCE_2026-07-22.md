# ManaLoom Sprint 4 — evidência de fluxos centrais

**Estado atual:** S4-01–S4-09 `PASS`; Sprint 4 concluída
**Branch:** `codex/free-beta-release-candidate-2026-07-17`
**Owner:** `/root`
**Execução válida S4-01:** `2026-07-22T08:26:29Z`
**Execução válida S4-02:** `2026-07-22T08:56:17Z`
**Execução válida S4-03:** `2026-07-22T09:57:41Z`
**Execução válida S4-04:** `2026-07-22T10:57:01Z`
**Execução válida S4-05:** `2026-07-22T11:26:12Z`
**Execução válida S4-06:** `2026-07-22T12:02:40Z`
**Execução válida S4-07:** `2026-07-22T13:08:36Z`
**Execução válida S4-08:** `2026-07-22T13:38:11Z`
**Execução válida S4-09:** `2026-07-22T14:36:54Z`
**Toolchain Flutter aprovada:** Flutter `3.44.6`, Dart `3.12.2`

## S4-01 — criar, importar, editar e remover deck com segurança

**Decisão:** `PASS`

O fluxo foi auditado do provider Flutter até as transações PostgreSQL. A
execução encontrou e corrigiu duas violações de atomicidade e dois contratos
de entrada incompletos:

1. a troca de edição no app executava `/cards/replace` e somente depois
   `/cards/set`; uma falha na segunda chamada deixava a primeira gravada;
2. `PUT /decks/:id` permitia trocar o formato sem validar as cartas já
   persistidas sob o formato novo;
3. listas com entradas que não eram objetos podiam ser descartadas
   silenciosamente no update;
4. formato arbitrário podia ser persistido e cair indevidamente nas regras
   genéricas de 60 cartas.

### Contrato implementado

- edição, quantidade, condição e papel de comandante agora usam uma única
  chamada a `POST /decks/:id/cards/set`, cuja alteração é transacional;
- formatos graváveis são `commander`, `brawl`, `standard`, `modern`,
  `pioneer`, `legacy`, `vintage` e `pauper`; `EDH` é aceito apenas como alias e
  normalizado para `commander`;
- create, update, import e validate rejeitam corpo/campos malformados com `400`
  antes de qualquer persistência;
- criação consolida entradas repetidas por `card_id` antes de aplicar limites
  de cópia e antes do bulk insert;
- criação inválida continua dentro de uma única transação; a linha do deck não
  sobrevive à falha de cartas ou regras;
- deck incompleto criado manualmente recebe `deck_state=draft`,
  `requires_review=true` e razões executáveis; um Commander vazio declara
  `missing_commander` e `incomplete_deck_size`;
- deck completo e estritamente válido pode sair da criação já como
  `validated`;
- troca de formato sem payload de cartas lê e valida a lista existente na
  mesma transação; falha devolve `400` e restaura formato e metadados;
- `DeckRulesService` rejeita formato, `card_id`, quantidade e marcador de
  comandante inválidos antes de consultar cartas; validação estrita de lista
  vazia não retorna mais falso positivo;
- importação nova, merge em deck existente e preview de importação usam a
  mesma normalização canônica de formato.

### Prova focada

```text
dart test <8 suites focadas do backend>
  23/23 PASS
  exit 0

dart analyze <helpers, regras, rotas e testes S4-01>
  No issues found
  exit 0

flutter 3.44.6 analyze \
  lib/features/decks/providers/deck_provider.dart \
  test/features/decks/providers/deck_provider_test.dart
  No issues found
  exit 0

flutter 3.44.6 test --no-pub \
  test/features/decks/providers/deck_provider_test.dart
  37/37 PASS
  exit 0
```

Os dois testes novos do provider provam tanto o sucesso quanto a falha: em
ambos existe exatamente uma chamada `/cards/set`, nenhuma chamada
`/cards/replace` e nenhuma tentativa de fallback após erro.

### E2E PostgreSQL/API descartável

```text
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
bash scripts/manaloom_server_contract_e2e_isolated.sh \
  test/deck_crud_atomicity_live_test.dart

1/1 PASS
summary_sha256=
  7e0f516a1bce6635d76594c458aa0cc16230d4434fd1ecf3853768892caa21e0
```

O cenário usa usuário, API e PostgreSQL efêmeros e comprova:

- formato e lista malformados retornam `400`;
- Commander vazio é salvo explicitamente como draft;
- duplicatas `3 + 2` de Sol Ring são consolidadas, rejeitadas pelo limite e a
  criação inteira sofre rollback;
- duplicatas `2 + 2` são consolidadas e persistem como quatro cópias;
- update que primeiro altera o nome e depois encontra `card_id` inexistente
  sofre rollback de nome e cartas;
- troca `standard → commander` incompatível sofre rollback do formato;
- importação inválida e merge inválido não alteram as quatro cartas;
- delete retorna `204` e a leitura posterior retorna `404`.

O harness registrou a própria trap de cleanup e removeu banco, API e fixture.

### Gate completo

```text
MANALOOM_FLUTTER_BIN=<flutter-3.44.6> \
FLUTTER_TEST_TIMEOUT_SECONDS=1800 \
bash scripts/quality_gate.sh full

backend determinístico: 1626/1626 PASS
Flutter analyze: No issues found
Flutter: 1086 PASS + 1 skip declarado Web-only
Web pública: eslint PASS, build Next.js PASS, npm audit 0, smoke HTTP PASS
exit 0
```

Log: `/tmp/manaloom_s401_full_gate_20260722.log`
SHA-256:
`c465db6de07c5973e4b5e6631b019be3b7f0b87541f4a4ad76f1f63a0d76d38e`.

### Manifesto e documentação executável

```text
MANALOOM_DART_BIN=<dart-3.12.2> \
bash scripts/manaloom_project_logic.sh --write
  8 artefatos gerados

MANALOOM_FLUTTER_BIN=<flutter-3.44.6> \
bash scripts/quality_gate.sh project-logic
  drift: 0/8
  testes do gerador: 9/9 PASS
  dart doc app/server/manaloom_lints/project_logic: sem warnings/erros
  exit 0
```

A geração e o check usaram o mesmo Dart pinado. Uma tentativa anterior com o
Dart global produziu árvore resolvida diferente e foi rejeitada antes do gate
válido; nenhum artefato dessa tentativa foi usado como evidência.

### Incidentes e validade da execução

- uma tentativa de executar `flutter analyze` e `flutter test` em paralelo no
  mesmo checkout encontrou o lock do Flutter; não é falha de produto e o teste
  foi repetido isoladamente com `37/37 PASS`;
- o formatador moderno produziu ruído mecânico em dois arquivos Flutter; o
  conteúdo foi restaurado e somente a alteração funcional e seus testes foram
  reaplicados;
- nenhum resultado parcial ou execução com toolchain mista foi usado como
  evidência de fechamento.

### Ambiente e cleanup

- nenhuma API remota, EasyPanel, SSH, migration produtiva ou credencial real
  foi utilizada;
- nenhuma escrita ocorreu fora do PostgreSQL descartável do harness;
- nenhuma base `manaloom_s1_api_*` do run permaneceu após a execução;
- nenhum listener/API/fixture criado por S4-01 permaneceu ativo;
- o servidor Web preexistente do usuário em `127.0.0.1:8088`, PID `55725`, foi
  preservado;
- nenhum commit, push ou deploy foi executado.

## S4-02 — fechar estados de validação

**Decisão:** `PASS`

O ciclo `unknown → draft → validated → draft` foi fechado no banco, na API e
na leitura Flutter. A auditoria identificou três lacunas reais:

1. sucesso e falha de `POST /decks/:id/validate` não retornavam o timestamp
   persistido;
2. em falha, a resposta expunha apenas `strict_validation_failed`, mesmo que a
   linha gravada contivesse outros motivos;
3. triggers acrescentavam motivos novos aos antigos e podiam manter razões
   obsoletas, como `missing_commander` depois de trocar o formato para
   Standard.

### Contrato implementado

- migration `047_close_deck_validation_state_transitions` e o bootstrap
  impõem o payload completo:
  - `unknown`: `validation_not_recorded`, sem timestamp;
  - `draft`: ao menos um motivo e timestamp obrigatório;
  - `validated`: motivos vazios e timestamp obrigatório;
- alterações de cartas substituem motivos anteriores por
  `deck_cards_changed_since_validation`;
- troca de formato substitui motivos anteriores por
  `deck_format_changed_since_validation`;
- alteração apenas de metadata, como nome, preserva estado, motivos e
  timestamp;
- a rota de validação bloqueia a linha do deck com `FOR UPDATE` e grava tanto
  sucesso quanto falha dentro da mesma transação;
- a resposta de sucesso/falha devolve o mesmo `validation_updated_at` e os
  mesmos `review_reasons` persistidos;
- listagem, detalhe e modelos Flutter normalizam o vocabulário fechado e
  continuam fail-closed para estado desconhecido;
- a tela de detalhe mostra quando o estado de legalidade foi atualizado;
- `/health/ready` agora exige migrations `039`, `040` e `047`, as três
  constraints de estado e os dois triggers ativos.

### Provas focadas

```text
dart test <6 suites de estado/migration/readiness>
  51/51 PASS

dart test test/api_contracts_data_map_guard_test.dart
  6/6 PASS

dart analyze <helpers, rota, migration/readiness e testes S4-02>
  No issues found

flutter 3.44.6 test \
  test/features/decks/models/deck_test.dart \
  test/features/decks/models/deck_details_test.dart \
  test/features/decks/widgets/deck_details_overview_tab_test.dart
  23/23 PASS

flutter 3.44.6 analyze <5 arquivos Flutter focados>
  No issues found
```

### E2E PostgreSQL/API descartável

```text
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
bash scripts/manaloom_server_contract_e2e_isolated.sh \
  test/deck_validation_state_live_test.dart

1/1 PASS
migration_count=47
latest_migration=047
summary_sha256=
  995639b9e7a65d542efe48bc9b532af2c81bbbcbda1197f506d2c5fb72fc2648
```

O cenário comprova:

- uma linha legada/default aparece como `unknown`, com motivo canônico e sem
  timestamp;
- criação incompleta aparece como `draft` com timestamp;
- completar 60 Plains invalida para draft com motivo de cartas;
- validação estrita promove para `validated` e a leitura devolve exatamente o
  mesmo timestamp;
- renomear preserva a validação;
- reduzir para 59 cartas invalida e a falha estrita grava e devolve os mesmos
  dois motivos;
- trocar o formato remove motivos obsoletos e mantém somente o motivo de
  formato;
- banco, API e fixture descartáveis foram removidos pela trap.

### Gate completo

```text
MANALOOM_FLUTTER_BIN=<flutter-3.44.6> \
FLUTTER_TEST_TIMEOUT_SECONDS=1800 \
bash scripts/quality_gate.sh full

backend determinístico: 1628/1628 PASS
Flutter analyze: No issues found
Flutter: 1087 PASS + 1 skip declarado Web-only
Web pública: eslint PASS, build Next.js PASS, npm audit 0, smoke HTTP PASS
exit 0
```

Log: `/tmp/manaloom_s402_full_gate_20260722_rerun.log`
SHA-256:
`108291ab3d8d60763a6d8aecdd1eb609d51ca5e24adccc4e8865db503451cb8d`.

Uma execução completa anterior foi rejeitada após um único guard documental
detectar a remoção acidental de uma expressão literal canônica. O texto foi
corrigido, o guard passou isoladamente e todo o gate foi repetido desde o
início; apenas o rerun integral acima é evidência de fechamento.

### Manifesto e documentação executável S4-02

```text
MANALOOM_DART_BIN=<dart-3.12.2> \
bash scripts/manaloom_project_logic.sh --write
  8 artefatos gerados

MANALOOM_FLUTTER_BIN=<flutter-3.44.6> \
bash scripts/quality_gate.sh project-logic
  drift: 0/8
  testes do gerador: 9/9 PASS
  dart doc app/server/manaloom_lints/project_logic: sem warnings/erros
  exit 0
```

O primeiro check foi rejeitado porque dois asserts do gerador ainda fixavam
`46`/`046`; a saída gerada já identificava corretamente a migration `047`.
Os asserts foram atualizados, os oito artefatos foram regenerados e todo o
gate foi repetido. Somente o rerun abaixo é válido:

- log: `/tmp/manaloom_s402_project_logic_20260722_rerun.log`;
- log SHA-256:
  `0b66c2c3c2a689c1c670f5e7ee41c0c9a76d0f8b8814ab956b72121736c8b7ef`;
- manifesto SHA-256:
  `72dce2d4243b697ab524aad6ad246d6919dd34e4dfd6d252747e34f3c413fed9`;
- sistema atual SHA-256:
  `56614ef23ddd5b434c56fd59649bb0f853c32020663da583f4434e00a6d02b78`;
- Contrato estrutural gerado, digest SHA-256:
  `c1f751a190b13e0f682c6127dafbd112e2538932ac64091cf61c71c44177829b`.

### Ambiente e cleanup S4-02

- nenhuma API remota, EasyPanel, SSH, migration produtiva ou credencial real
  foi utilizada;
- nenhuma base `manaloom_s1_api_*` permaneceu após o E2E;
- nenhum processo de API, fixture ou teste permaneceu ativo;
- o servidor Web preexistente do usuário em `127.0.0.1:8088`, PID `55725`, foi
  preservado;
- nenhum commit, push ou deploy foi executado.

## S4-03 — fechar analyze/optimize/apply/rollback

**Decisão:** `PASS`

A auditoria confirmou que o preview já informava origem, função, risco,
curva, preço e impacto de battle. A lacuna estava na aplicação: cartas,
validação, estratégia e histórico eram persistidos em operações separadas.
Uma falha no histórico ou na atualização de estratégia podia deixar um deck
alterado sem snapshot reversível confiável.

### Contrato implementado

- o preview assina a fotografia do deck com uma assinatura determinística,
  independente de ordem e sensível a quantidade e condição;
- apply exige essa assinatura e falha fechado se o deck mudou desde o preview;
- cartas, validação estrita, arquétipo, bracket e evento com snapshots completos
  `before/after` são gravados na mesma transação PostgreSQL;
- falha de regra ou de persistência do histórico restaura integralmente cartas,
  validação e metadata;
- a resposta atômica devolve validação e ID do evento, sem uma segunda chamada
  de validação ou estratégia sujeita a falha parcial;
- `POST /decks/:id/optimizations/:eventId/rollback` restaura cartas, estado,
  motivos, timestamp e estratégia anteriores na mesma transação;
- rollback é single-use e se recusa a sobrescrever qualquer edição posterior;
- a interface oferece `Desfazer` somente após apply confirmado;
- cancelar o preview não dispara mutação, validação ou atualização de
  estratégia.

### Provas focadas

```text
dart test \
  test/deck_optimization_history_service_test.dart \
  test/product_retention_report_contract_test.dart
  6/6 PASS

dart test test/api_contracts_data_map_guard_test.dart
  6/6 PASS

dart analyze <serviço, rotas e testes S4-03>
  No issues found

flutter 3.44.6 test <providers, fluxo e dialogs S4-03>
  90/90 PASS

flutter 3.44.6 analyze <providers, fluxo, UI e testes S4-03>
  No issues found
```

Os testes cobrem assinatura e snapshots completos, resposta de validação
embutida, propagação do contexto assinado, cancelamento sem callbacks de
mutação e a ação de undo.

### E2E PostgreSQL/API descartável

```text
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
bash scripts/manaloom_server_contract_e2e_isolated.sh \
  test/deck_optimization_apply_rollback_live_test.dart

1/1 PASS
migration_count=47
latest_migration=047
summary_sha256=
  13adcff72ae145aa63a23668b52e3acc10a1a6b649f7a697f8f4504d97173f5d
```

O cenário comprova rejeição de apply inválido sem mutação; rollback
transacional quando a tabela de histórico é tornada indisponível; apply válido
com snapshot completo e estratégia atômica; restauração exata do estado e do
timestamp anterior; rejeição de segundo rollback; e conflito seguro quando uma
edição manual ocorre depois do apply.

### Gate completo

```text
MANALOOM_FLUTTER_BIN=<flutter-3.44.6> \
FLUTTER_TEST_TIMEOUT_SECONDS=1800 \
bash scripts/quality_gate.sh full

backend determinístico: 1631/1631 PASS
Flutter analyze: No issues found
Flutter: 1089 PASS + 1 skip declarado Web-only
Web pública: eslint PASS, build Next.js PASS, npm audit 0, smoke HTTP PASS
exit 0
```

Log: `/tmp/manaloom_s403_full_gate_rerun_20260722.log`
SHA-256:
`557020d6a6303c46a9aa5e761ec01e708d6117f64dca0b5e8cd4d8dffbb034b5`.

A primeira execução completa foi rejeitada porque a nova snackbar de undo
aumentou o inventário visual de 214 para 215 superfícies. O contrato foi
atualizado, o guard passou 4/4 isoladamente e o gate integral foi repetido do
início. Somente o rerun acima é evidência de fechamento.

### Manifesto e documentação executável S4-03

```text
MANALOOM_DART_BIN=<dart-3.12.2> \
bash scripts/manaloom_project_logic.sh --write
  8 artefatos gerados

MANALOOM_FLUTTER_BIN=<flutter-3.44.6> \
bash scripts/quality_gate.sh project-logic
  drift: 0/8
  testes do gerador: 9/9 PASS
  dart doc app/server/manaloom_lints/project_logic: sem warnings/erros
  exit 0
```

- log: `/tmp/manaloom_s403_project_logic_rerun_20260722.log`;
- log SHA-256:
  `0b66c2c3c2a689c1c670f5e7ee41c0c9a76d0f8b8814ab956b72121736c8b7ef`;
- manifesto SHA-256:
  `bfed6b03587492cc4948440418237266887e3b8830a5c7476a0db55b262a3bd0`;
- sistema atual SHA-256:
  `a6e64c43cf334eb362d169ec4127c525168a2abb654be1dd5c9df1998ec0c063`;
- Contrato estrutural gerado, digest SHA-256:
  `897a4ddd116522b18e3bc7dc5dbebcc353f29093dbc1f8a303b1ef4b613c5f55`.

O manifesto e o OpenAPI gerado reconhecem
`/decks/{id}/optimizations/{eventId}/rollback` e seus consumidores Flutter.

### Ambiente e cleanup S4-03

- nenhuma API remota, EasyPanel, SSH, migration produtiva ou credencial real
  foi utilizada;
- o E2E escreveu somente em PostgreSQL e API descartáveis, removidos pela trap;
- nenhuma base `manaloom_s1_api_*`, API ou fixture do run permaneceu ativa;
- o servidor Web preexistente em `127.0.0.1:8088`, PID `55725`, foi preservado;
- nenhum commit, push ou deploy foi executado.

## S4-04 — fechar jobs longos da IA

**Decisão:** `PASS`

A auditoria confirmou que geração e otimização já possuíam polling,
mas não formavam um ciclo de vida seguro. Repetir uma requisição podia
reservar quota e iniciar outro worker; sair da tela perdia a referência do job;
cancelamento era apenas local; e um worker atrasado podia sobrescrever um
estado terminal.

### Contrato implementado

- a migration `048_close_ai_job_lifecycle` acrescenta `request_key`,
  `request_fingerprint` e `cancelled_at` aos jobs de geração e otimização;
- a chave idempotente é única por usuário; repetir o mesmo request reutiliza
  o job e payload divergente com a mesma chave retorna conflito `409`;
- quota e worker são iniciados somente quando um job novo foi criado;
- os estados terminais são `completed`, `failed` e `cancelled`; progresso,
  conclusão ou falha tardia de worker não podem sobrescrevê-los;
- `GET .../jobs/latest` recupera o job ativo do usuário e `DELETE .../jobs/:id`
  realiza cancelamento autenticado e idempotente;
- respostas `202` expõem ID, estado, progresso, `request_key` e ações de
  polling/cancelamento/retomada;
- o draft Flutter preserva job e chave de geração; reabrir a tela retoma o
  polling sem reservar nova quota;
- otimização ativa é descoberta ao voltar ao detalhe do deck e oferece
  `Retomar`; timeout mantém a referência recuperável;
- sair da tela não cancela trabalho remoto; somente a ação explícita do
  usuário envia `DELETE`;
- a readiness exige a migration `048`, seis colunas, duas constraints e dois
  índices de idempotência.

### Provas focadas

```text
dart test <lifecycle, generate, optimize, migration, readiness e docs>
  49/49 PASS

dart test <lifecycle e settlement focados>
  22/22 PASS

dart analyze <helpers, rotas e testes S4-04>
  No issues found

flutter 3.44.6 test <providers, draft, telas e dialogs S4-04>
  109/109 PASS
  rerun estendido: 108/108 PASS
  widget dedicado de retomada/cancelamento: PASS

flutter 3.44.6 analyze <9 arquivos centrais S4-04>
  No issues found
```

O inventário executável de UI foi atualizado de 215 para 220 superfícies
após a inclusão dos estados acionáveis; seu guard isolado passou `4/4`.

### E2E PostgreSQL/API descartável

```text
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
bash scripts/manaloom_server_contract_e2e_isolated.sh \
  test/ai_job_lifecycle_live_test.dart

1/1 PASS
migration_count=48
latest_migration=048
summary_sha256=
  e26519f286323602ff274632d61d25af68cc63a7c2976b15f4714d3c4ac361b9
```

O cenário comprova criação e reutilização idempotente, conflito para
payload divergente, descoberta de job ativo, isolamento por owner,
cancelamento repetível e bloqueio de conclusão tardia para geração e
otimização. Banco, API e fixture foram removidos pela trap do harness.

### Gate completo

```text
MANALOOM_FLUTTER_BIN=<flutter-3.44.6> \
MANALOOM_DART_BIN=<dart-3.12.2> \
FLUTTER_TEST_TIMEOUT_SECONDS=1800 \
bash scripts/quality_gate.sh full

backend determinístico: 1638/1638 PASS
Flutter analyze: No issues found
Flutter: 1096 PASS + 1 skip declarado Web-only
Web pública: eslint PASS, build Next.js PASS, npm audit 0, smoke HTTP PASS
exit 0
```

Log: `/tmp/manaloom_s404_full_gate_final_20260722.log`
SHA-256:
`69dd4a7faeea29ddfc909b14faf22c6ccbcb3d53471e5b32e0e4e6dc46ad7b6a`.

Duas execuções anteriores foram rejeitadas: a primeira por um falso positivo
do guard de segurança causado pelo nome interno que continha `Fingerprint(`;
o helper foi renomeado sem afrouxar o guard. A segunda detectou corretamente o
inventário de UI desatualizado. Ambos os contratos passaram isoladamente e o
gate integral acima foi executado do início; somente ele vale como fechamento.

### Manifesto e documentação executável S4-04

```text
MANALOOM_DART_BIN=<dart-3.12.2> \
bash scripts/manaloom_project_logic.sh --write
  8 artefatos gerados

MANALOOM_FLUTTER_BIN=<flutter-3.44.6> \
MANALOOM_DART_BIN=<dart-3.12.2> \
bash scripts/quality_gate.sh project-logic
  drift: 0/8
  testes do gerador: 9/9 PASS
  dart doc app/server/manaloom_lints/project_logic: sem warnings/erros
  exit 0
```

- log: `/tmp/manaloom_s404_project_logic_20260722.log`;
- log SHA-256:
  `2975e843ef552cb5720474357c89cf5b6204d668aa2b3f647346842aa53b6e24`;
- manifesto SHA-256:
  `27f8cc35f08e18ef7c2b47ebe0f5d48bf79c0bc25184ae903837b5a009b8b222`;
- sistema atual SHA-256:
  `6678c723e69f280b839f13d3d888dff2098beaa65dc961475768c1fd2cff56c6`;
- Contrato estrutural gerado, digest SHA-256:
  `77a5bf2a8e72341f7c6fd996b5eba5e403d95308731977a4a00609a9b46625eb`.

O mapa gerado reconhece as rotas de consulta/cancelamento de ambos os tipos
de job e a migration `048` como a última migration canônica.

### Ambiente e cleanup S4-04

- nenhuma API remota, EasyPanel, SSH, migration produtiva ou credencial real
  foi utilizada;
- o E2E escreveu somente em PostgreSQL e API descartáveis, removidos pela trap;
- nenhuma base `manaloom_s1_api_*`, API ou fixture do run permaneceu ativa;
- o servidor Web preexistente em `127.0.0.1:8088`, PID `55725`, foi preservado;
- nenhum commit, push ou deploy foi executado.

## S4-05 — integrar coleção ao deck

**Decisão:** `PASS`

A revisão encontrou quatro diferenças concretas entre a identidade física e a
identidade jogável: o índice anterior colidia idiomas diferentes; uso em deck
era contado somente para a impressão exata; a UI repetia o total livre global
em cada cópia física; e a busca manual do Deckbuilder não exibia posse,
alocação, compromisso ou falta. Update/delete também não protegiam itens já
incluídos em trocas ativas.

### Contrato implementado

- a migration `049_preserve_binder_physical_identity` normaliza idioma e cria
  a identidade física única por usuário, impressão, condição, foil, idioma e
  tipo de lista;
- `COALESCE(cards.oracle_id,cards.id)` permanece a única identidade jogável;
  impressões, idiomas, foil e condição não dividem posse, alocação ou falta;
- `GET /binder/availability?card_ids=` retorna, para até 100 impressões, os
  totais canônicos `owned`, `allocated`, `committed`, `free` e `missing`;
- a busca do Deckbuilder consulta essa rota de forma aditiva e mostra
  `Possui`, `Livre`, `Alocada`, `Em troca` e `Falta`; indisponibilidade desse
  resumo não bloqueia a busca de cartas;
- a listagem do Binder usa `available_quantity` para a linha física e separa
  explicitamente `Livre total`; também mostra o idioma normalizado;
- `deck_count` e `deck_quantity` passam a agregar impressões alternativas da
  mesma carta jogável;
- create do Binder valida tipos, normaliza entradas e resolve concorrência de
  duplicidade com `409 binder_item_identity_conflict`;
- update/delete bloqueiam a linha do owner e consultam compromissos ativos na
  mesma transação; identidade física, redução abaixo do comprometido ou
  remoção retornam `409 binder_item_committed`;
- `/health/ready` exige as migrations `045`/`049`, as duas views, o índice
  físico com idioma e a constraint de idioma.

### Provas focadas

```text
dart analyze <helpers, Binder, readiness e testes S4-05>
  No issues found

dart test <contratos Binder, migration, readiness e mapa API>
  57/57 PASS

flutter 3.44.6 analyze <provider, telas e testes S4-05>
  No issues found

flutter 3.44.6 test <CardProvider, busca e Binder>
  14/14 PASS
```

Os testes Flutter confirmam parsing dos cinco totais, degradação sem bloquear
a busca, pills visíveis no resultado e distinção entre disponibilidade da
entrada física e total jogável.

### E2E PostgreSQL/API descartável

```text
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
bash scripts/manaloom_server_contract_e2e_isolated.sh \
  test/collection_availability_live_test.dart

1/1 PASS
migration_count=49
latest_migration=049
summary_sha256=
  569011f06c88f95651c92b6cc49d94960f881dba3257e97d235b22048577cc95
```

O cenário criou duas impressões do mesmo Sol Ring e três entradas físicas:
inglês não foil, português normalizado de `PT_BR` para `pt-br`, e japonês
foil. Quatro cópias físicas permaneceram uma única identidade jogável. Dois
decks usando impressões distintas produziram alocação total dois; cada
impressão consultada devolveu os mesmos totais, enquanto a soma de
`available_quantity` das entradas permaneceu exatamente dois.

Duas ofertas concorrentes tentaram consumir as mesmas duas cópias. O resultado
foi exatamente um `201` e um `409 trade_quantity_unavailable`. Depois do
compromisso, livre caiu para zero em ambas as impressões; update de idioma,
redução de quantidade e delete foram bloqueados. Tentativas de outro usuário
para update/delete retornaram `404`.

Resumo:
`/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T//manaloom_server_contract_e2e_20260722T112024Z_95432/summary.txt`.

### Gate completo

```text
MANALOOM_FLUTTER_BIN=<flutter-3.44.6> \
MANALOOM_DART_BIN=<dart-3.12.2> \
FLUTTER_TEST_TIMEOUT_SECONDS=1800 \
bash scripts/quality_gate.sh full

backend determinístico: 1647/1647 PASS
Flutter analyze: No issues found
Flutter: 1099 PASS + 1 skip declarado Web-only
Web pública: eslint PASS, build Next.js PASS, npm audit 0, smoke HTTP PASS
exit 0
```

Log: `/tmp/manaloom_s405_full_gate_20260722.log`
SHA-256:
`3da9924edd16c9b6e03bb3f1223aa7279fe365cdd7fe3e8c2ad74aeba0202884`.

### Manifesto e documentação executável S4-05

```text
MANALOOM_DART_BIN=<dart-3.12.2> \
bash scripts/manaloom_project_logic.sh --write
  8 artefatos gerados

MANALOOM_FLUTTER_BIN=<flutter-3.44.6> \
MANALOOM_DART_BIN=<dart-3.12.2> \
bash scripts/quality_gate.sh project-logic
  drift: 0/8
  testes do gerador: 9/9 PASS
  dart doc app/server/manaloom_lints/project_logic: sem warnings/erros
  exit 0
```

- log: `/tmp/manaloom_s405_project_logic_gate_20260722.log`;
- log SHA-256:
  `2975e843ef552cb5720474357c89cf5b6204d668aa2b3f647346842aa53b6e24`;
- manifesto SHA-256:
  `d9bc2bbd5f1635df85d0da6a41158b9bcabeeabf1d76e2b0fd0675cf21ed8688`;
- sistema atual SHA-256:
  `5a5b514df7cca162a7fd27f50aac0c206153d5ac9da21098fb3937a0fbf3fe50`;
- Contrato estrutural gerado, digest SHA-256:
  `3a6bcdb29bde4706b8235a388e56d641a3c09a2ed58e035c18f2b448a7d91e1c`.

### Ambiente e cleanup S4-05

- nenhuma API remota, EasyPanel, SSH, migration produtiva ou credencial real
  foi utilizada;
- o E2E escreveu somente em PostgreSQL e API descartáveis, removidos pela trap;
- nenhuma base `manaloom_s1_api_*`, API ou fixture do run permaneceu ativa;
- o servidor Web preexistente em `127.0.0.1:8088`, PID `55725`, foi preservado;
- nenhum commit, push ou deploy foi executado.

## S4-06 — fechar Deck → mesa → pós-jogo

**Decisão:** `PASS`

A jornada anterior já diferenciava saída sem atividade de uma partida real e
possuía fila offline, mas transportava somente id/nome do deck. O snapshot era
calculado no servidor apenas ao salvar a nota; portanto, editar o deck entre a
abertura da mesa e o pós-jogo podia associar a partida à versão errada.

### Contrato implementado

- `GET /decks/:id` agora devolve `deck_snapshot_hash` determinístico e
  `deck_version_at`, instante em que aquela identidade foi capturada;
- `buildDeckSnapshotHash` é compartilhado pelo detalhe do deck e pelo serviço
  pós-jogo, evitando dois algoritmos para a mesma versão;
- detalhe Flutter, rota, sessão persistida, histórico, mirror Lotus e resultado
  de saída carregam o par hash/versão sem perder o contexto;
- reabrir a mesma versão continua a sessão; uma versão diferente do mesmo deck
  inicia mesa limpa e arquiva os eventos anteriores;
- saída sem alteração de jogo mantém `hadGameActivity=false` e não abre falso
  pós-jogo; mudança real de vida retorna contexto completo;
- o formulário mostra a versão curta, salva o par com a nota e a fila offline
  preserva os metadados durante merge/retry;
- hash/versão devem ser enviados juntos. Clientes antigos podem omitir ambos e
  recebem snapshot atual capturado pelo servidor;
- depois da criação, a identidade da nota é imutável: retry/update não substitui
  o snapshot persistido, mesmo se enviar a versão atual do deck;
- `play_session_id` continua único, tombstones continuam impedindo ressurreição
  e o retry offline produz uma única nota remota.

### Provas focadas

```text
dart analyze <snapshot, post-game, rota e testes S4-06>
  No issues found

dart test <snapshot, sync e mapa API>
  14/14 PASS

flutter 3.44.6 analyze <deck, rota, sessão, Lotus, pós-jogo e testes>
  No issues found

flutter 3.44.6 test <modelos, rota, sessão, Lotus, mirror e pós-jogo>
  64/64 PASS
```

Os testes Flutter cobrem JSON do detalhe, encoding URL-safe, round-trip da
sessão, mirror Lotus, versão diferente do mesmo deck, saída sem atividade,
saída com atividade, versão visível/salva e retry offline com exatamente um
upsert remoto bem-sucedido.

### E2E PostgreSQL/API descartável

```text
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
bash scripts/manaloom_server_contract_e2e_isolated.sh \
  test/post_game_two_client_live_test.dart

1/1 PASS
migration_count=49
latest_migration=049
summary_sha256=
  4f027f338d0b46843ac2502553be89c0139c507f64365621b6d521b4eb33e4ae
```

O cenário capturou a versão de um deck, editou o nome e comprovou que o hash
atual mudou. A nota criada depois da edição manteve o hash/timestamp da abertura
da mesa. Um retry enviando deliberadamente a versão nova não alterou a versão
persistida. Metadado pela metade retornou `400`; dois clientes convergiram por
cursor/revisão, sessão duplicada retornou `409`, update stale retornou `409`, e
tombstone impediu ressurreição e acesso de terceiro.

Resumo:
`/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T//manaloom_server_contract_e2e_20260722T114940Z_52131/summary.txt`.

### Gate completo

```text
MANALOOM_FLUTTER_BIN=<flutter-3.44.6> \
MANALOOM_DART_BIN=<dart-3.12.2> \
FLUTTER_TEST_TIMEOUT_SECONDS=1800 \
bash scripts/quality_gate.sh full

backend determinístico: 1650/1650 PASS
Flutter analyze: No issues found
Flutter: 1102 PASS + 1 skip declarado Web-only
Web pública: eslint PASS, build Next.js PASS, npm audit 0, smoke HTTP PASS
exit 0
```

Log: `/tmp/manaloom_s406_full_gate_20260722.log`
SHA-256:
`67956abafd55f66af1e263cbb833d05f85505869f489a160e2828047017ba05b`.

### Manifesto e documentação executável S4-06

```text
MANALOOM_DART_BIN=<dart-3.12.2> \
bash scripts/manaloom_project_logic.sh --write
  8 artefatos gerados

MANALOOM_FLUTTER_BIN=<flutter-3.44.6> \
MANALOOM_DART_BIN=<dart-3.12.2> \
bash scripts/quality_gate.sh project-logic
  drift: 0/8
  testes do gerador: 9/9 PASS
  dart doc app/server/manaloom_lints/project_logic: sem warnings/erros
  exit 0
```

- log: `/tmp/manaloom_s406_project_logic_gate_20260722.log`;
- log SHA-256:
  `609446efe4ef5c703532efe27fe8635a198ebc522afb41ca0e1fa9a77ac495ea`;
- manifesto SHA-256:
  `b565702bf9931b83634cb6f3155c326e8d61d0e77d4281fbc0762ad3e20975d6`;
- sistema atual SHA-256:
  `ebd880b20bf088963e9be2c83c0ae7f7deaf6ecf3f11b077ed727213cb7bb614`;
- Contrato estrutural gerado, digest SHA-256:
  `e32615b44780cbb27c652d63319951a0f6c741155eab6404624ee15326906df6`.

### Ambiente e cleanup S4-06

- nenhuma API remota, EasyPanel, SSH, migration produtiva ou credencial real
  foi utilizada;
- o E2E escreveu somente em PostgreSQL e API descartáveis, removidos pela trap;
- nenhuma base, API ou fixture do run permaneceu ativa;
- o servidor Web preexistente em `127.0.0.1:8088`, PID `55725`, foi preservado;
- nenhum commit, push ou deploy foi executado.

## S4-07 — decidir Scanner/OCR

**Decisão:** `PASS` para o alvo Android release atual.

O scanner deixa de ser apenas uma tela escondida por flag. A decisão de produto
e distribuição agora é explícita:

- o pipeline Android assinado e os dois probes Android do gate local compilam com
  `ENABLE_SCANNER_RELEASE=true`;
- a identidade embarcada declara `scanner_release_enabled: true`;
- Web, desenvolvimento comum e iOS sem cadeia física preservam o default
  `false`, não registram a rota `scan` e recuperam deep links para `search`;
- a busca manual, seleção de impressão e correção continuam disponíveis; OCR
  nunca autoriza mutação silenciosa da coleção/deck;
- iOS não faz parte do alvo publicável atual e permanece na Sprint 10. Não foi
  classificado como PASS físico nesta rodada.

### Implementação e provas focadas

- `CardRecognitionService.recognizeFromCameraImage` expõe callback diagnóstico
  opcional para distinguir frame sem texto de erro real de conversão/MLKit;
- `scanner_physical_runtime_test.dart` exige build habilitado, permissão real,
  câmera traseira, frame não vazio, conversão sem erro e OCR MLKit no device;
- a rota `scan` só existe quando a feature está habilitada; o redirect para
  busca manual permanece fail-safe;
- build Android release e gate local recebem a mesma flag, protegidos pelos contratos
  de release Dart/shell.

```text
flutter analyze <scanner, rota, contratos e harnesses>
  No issues found

flutter test <scanner, launch scope, menu e permissões>
  30/30 PASS

dart test server/test/mobile_release_contract_test.dart
  1/1 PASS

bash scripts/manaloom_release_ops_contract_test.sh
  25/25 contratos PASS
```

Logs:

- `/tmp/manaloom_s407_scanner_focused_20260722.log` — SHA-256
  `63a139604870eb7857edf8110153c0b2633df95a0a3b5769bfae9c9bb18905a0`;
- `/tmp/manaloom_s407_release_contracts_20260722.log` — SHA-256
  `9484fa4da65009c899a154f361a90743c888b7e5010c7bac2651dcb8e8d1303f`.

### Prova física Android

Device: Samsung `SM A135M`, serial `R58T300SREH`, Android 14/API 34.

```text
scanner_controlled_harness_runtime_test.dart
  1/1 PASS

scanner_physical_runtime_test.dart
  2/2 PASS
  câmera traseira real inicializada
  frame NV21 real aceito pelo pipeline MLKit sem erro
  OCR MLKit físico: Lightning Bolt, BLB, 157/274
```

O segundo cenário cria no próprio aparelho um layout controlado de carta; não é
um mock de OCR. Os pixels são processados pelo plugin Google MLKit instalado no
SM A135M. A câmera é provada separadamente com o mesmo preset/formato usado em
produção. O parser/provider ainda cobre token, impressão, foil, ruído externo,
fallback e recuperação manual. A matriz humana normal/foil/baixa luz permanece
calibração P2 de precisão, não um caminho de mutação sem revisão.

- harness controlado: `/tmp/manaloom_s407_scanner_android_controlled_20260722.log`,
  SHA-256 `b99f2a906cfd0b40445d16fbbb3db338e94c34adae6b4fae704c19dd77e539dc`;
- câmera/MLKit físico: `/tmp/manaloom_s407_scanner_android_physical_20260722.log`,
  SHA-256 `0b54370e3b3a0da900f1bc53a853a4bae83dcf3f3ef1434c74ddf3b266eed47f`.

### APK release Android

```text
flutter build apk --release --dart-define=ENABLE_SCANNER_RELEASE=true
  PASS — 116,2 MB

package=com.mtgia.mtg_app
versionName=1.0.0
versionCode=2
minSdk=24
targetSdk=36
assinatura APK v2=verificada
permissões sensíveis esperadas=CAMERA, POST_NOTIFICATIONS
RECORD_AUDIO/READ_EXTERNAL_STORAGE/WRITE_EXTERNAL_STORAGE=ausentes
instalação no SM A135M=PASS
abertura e primeiro frame da Activity=PASS, sem fatal exception
```

APK local de prova: `app/build/app/outputs/flutter-apk/app-release.apk`; SHA-256
`e71f884af0e93eaf819d1a5035c56c3a85e751d2adaf561c0a78aa5a14d1da10`.
Ele foi reinstalado no Samsung para teste do usuário, mas não é artefato de
Store: o checkout está sujo e nenhum publish/deploy foi executado.

Log de build: `/tmp/manaloom_s407_scanner_android_release_build_20260722.log`;
SHA-256 `b25de1ffbbba5aebb059dee1842a56f82221f65408261328313febbc89549f68`.

### Limite iOS comprovado

- o harness controlado chegou à fase de instalação, mas `flutter test` não
  inicia em device iOS conectado somente por Wi-Fi porque exige `--publish-port`,
  opção inexistente nesse subcomando;
- o compile device-release no-codesign com scanner habilitado chegou ao Xcode,
  mas o Xcode local não possui a platform image iOS 26.5 exigida pelo device;
- esses resultados não são tratados como falha Android nem como PASS iOS.
  Assinatura, device conectado por cabo/platform image e prova física iOS ficam
  no S10.

Logs de limite:

- `/tmp/manaloom_s407_scanner_ios_controlled_20260722.log` — SHA-256
  `b5b0374df939fa561ddace368437d89e46c6812c5e15d7e131e3f70edd4dc2f5`;
- `/tmp/manaloom_s407_scanner_ios_release_compile_20260722.log` — SHA-256
  `7e7c855bcff876dd830ddb6d896fad483d2fdefa400b24ae60b99bf1c61a0ee9`.

### Gate completo S4-07

```text
backend determinístico: 1650/1650 PASS
Flutter analyze: No issues found
Flutter: 1104 PASS + 1 skip declarado Web-only
Web pública: eslint PASS, build Next.js PASS, npm audit 0, smoke HTTP PASS
exit 0
```

Log: `/tmp/manaloom_s407_full_gate_20260722.log`; SHA-256
`fe5b45c60bb37c94591d16c7c48a9becaaa2c7ff613f1b85a72ed0b5abdfed0f`.

### Manifesto e documentação executável S4-07

```text
manaloom_project_logic.sh --write: 8 artefatos
quality_gate.sh project-logic: drift 0/8
testes do gerador: 9/9 PASS
dart doc app/server/manaloom_lints/project_logic: sem warnings/erros
```

- log SHA-256:
  `609446efe4ef5c703532efe27fe8635a198ebc522afb41ca0e1fa9a77ac495ea`;
- manifesto SHA-256:
  `d5d7c0a87991f61ee49f34dcf0f3756e4a60dbd8b9d26bd5240191a58386569d`;
- sistema atual SHA-256:
  `20f77d4421d040dc7d4826f48bc3fc09f461dcc3f0a51dae79a28f5bf8511f8c`;
- Contrato estrutural gerado, digest SHA-256:
  `1159bb8bdbfd2564e5d59bd263946c2db131e615363715b437ca31b367c459de`.

### Ambiente S4-07

- nenhum backend/API/banco remoto, EasyPanel, SSH, migration ou deploy foi
  utilizado;
- o Web preexistente em `127.0.0.1:8088`, PID `55725`, foi preservado;
- o APK release local ficou instalado no SM A135M para teste;
- nenhum commit, push ou publicação de Store foi executado.

## S4-08 — fechar preço, moeda, proveniência e dados ausentes

**Decisão:** `PASS`.

O contrato de preço deixou de misturar moeda, ausência e zero. A migration
`050_canonical_card_pricing` torna `cards.price_usd` a coluna canônica,
preserva `price` apenas como compatibilidade e registra fonte, moeda, data da
cotação e atualização. PostgreSQL continua sendo a fonte operacional canônica.

### Contrato implementado

- preço ausente ou inválido permanece `null`; nunca vira `0`;
- total de deck é `null` quando nenhuma cópia tem preço conhecido e informa
  cobertura parcial quando apenas parte da lista tem preço;
- preço Scryfall é persistido em USD com proveniência e instante explícitos;
- refresh é limitado, usa cache, valida resposta por carta e não derruba todo
  o lote quando uma impressão falha;
- Binder separa valores informados em BRL de referência de mercado em USD;
- Marketplace só compara valores na mesma moeda e Market Movers rejeita
  amostras sem preço;
- modelos e componentes Flutter exibem moeda e indisponibilidade sem inventar
  conversão cambial.

### Provas focadas e PostgreSQL/API

```text
backend focado de pricing/migration/readiness: 42/42 PASS
backend completo direto: 701 PASS + 3 skips de fixtures históricas declaradas
Flutter focado de pricing/Binder/Marketplace/Market: 48/48 PASS

manaloom_server_contract_e2e_isolated.sh test/pricing_contract_live_test.dart
  1/1 PASS
  migration_count=50
  latest_migration=050
```

- backend completo: `/tmp/manaloom_s408_server_full_20260722.log`, SHA-256
  `ca7e4ecd889b44e3e5c95e07dafd231c63dfd4b81377518b2f899c86044ff26d`;
- resumo E2E descartável:
  `/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T//manaloom_server_contract_e2e_20260722T133811Z_52960/summary.txt`,
  SHA-256
  `56cf8f0bc727f57abcc2df5cf75a3893c958c9f9d6e61c9bcc9fd034dd3d0a33`.

O harness removeu PostgreSQL, API e fixture pela trap. A camada semântica de
dados ManaLoom orientou a decisão de manter PostgreSQL/preço USD canônicos e
BRL explicitamente separado, em vez de inferir conversões.

## S4-09 — fechar Home, estados, navegação e retomada de sessão

**Decisão:** `PASS`.

### Contrato implementado

- Home possui estados explícitos de loading, vazio, erro recuperável, cache
  offline e sessão expirada;
- durante indisponibilidade temporária, decks já carregados continuam visíveis
  com aviso e retry; em `401`, conteúdo privado em cache é ocultado e a ação
  leva ao login;
- os atalhos Web e nativos apontam para rotas reais, incluindo decks,
  coleção, comunidade, scanner/busca e contador de vida;
- decks recentes vêm da listagem real ordenada por `created_at DESC`; a copy
  agora diz `Criado`, pois o contrato disponível não declara `updated_at`;
- cadastro autenticado ainda não verificado segue para `/verify-email`, sem o
  redirect genérico de auth interceptar a rota;
- primeiro login segue para onboarding, e o skip conclui na experiência da
  beta gratuita.

### Provas focadas, Patrol e IA

```text
Flutter Home/rotas/provider focado: 69/69 PASS
flutter analyze main.dart + Patrol: No issues found
Patrol critical E2E local: 9/9 PASS
server target audit: PASS
app AI bridge audit: PASS
Commander prompt eval: 3/3, score 100
```

O gate Patrol também foi corrigido para respeitar
`MANALOOM_FLUTTER_BIN` e executar com `--no-pub`. Uma tentativa com o Flutter
global `3.41.6` foi rejeitada após produzir artefatos Kernel incompatíveis; os
caches derivados foram limpos, o lockfile foi restaurado e somente o rerun com
Flutter `3.44.6` é evidência válida.

- Patrol oficial: `/tmp/manaloom_s409_patrol_smoke_20260722.log`, SHA-256
  `fa436dfd90ebf681aa3fd0bfbbc1baa1414c75b3dd039664435a263f085bfacd`;
- ponte IA: `/tmp/manaloom_s409_ai_bridge_20260722.log`, SHA-256
  `9a622c5f6fe568b68f12da47f2c4eab6dc967e544dfed05411af4a42c5adf2ed`.

O Patrol CLI em device/emulador não foi solicitado neste fechamento; os nove
fluxos foram compilados e executados pelo harness Patrol local. Provas físicas
já concluídas ou bloqueadas continuam registradas nas tasks específicas.

### Gate completo final da Sprint 4

```text
MANALOOM_FLUTTER_BIN=<flutter-3.44.6> \
MANALOOM_DART_BIN=<dart-3.12.2> \
bash scripts/quality_gate.sh full

backend determinístico: 1657/1657 PASS
Flutter analyze: No issues found
Flutter: 1113 PASS + 1 skip declarado Web-only
Web pública: eslint PASS, build Next.js PASS, npm audit 0, smoke HTTP PASS
exit 0
```

Log: `/tmp/manaloom_s409_full_gate_20260722.log`; SHA-256
`a04f58f4f38810a49c63190b49a621f8d5986ac97a3ee035ec8c4799001b5392`.

### Manifesto e documentação executável finais

```text
manaloom_project_logic.sh --write: 8 artefatos
quality_gate.sh project-logic: drift 0/8
testes do gerador: 9/9 PASS
dart doc app/server/manaloom_lints/project_logic: sem warnings/erros
```

Saída final: `/tmp/manaloom_s409_project_logic_final_20260722.log`.

Os hashes de `project_logic_manifest.json` e dos documentos gerados não são
copiados para esta fonte porque este próprio arquivo faz parte da entrada do
gerador. A prova canônica é o gate de drift zero executado depois da última
edição documental; isso evita uma referência circular que tornaria o
manifesto obsoleto ao registrar seu próprio hash.

### Ambiente e cleanup finais

- nenhum backend/API/banco remoto, EasyPanel, SSH, migration produtiva,
  commit, push, deploy ou publicação de Store foi executado;
- o E2E S4-08 escreveu somente no ambiente descartável e fez cleanup;
- nenhum processo de teste, API ou fixture iniciado por S4-08/S4-09 ficou
  ativo;
- o servidor Web preexistente em `127.0.0.1:8088`, PID `55725`, foi
  preservado.

## Próxima task

Sprint 4 está fechada. A próxima sequência executável começa em S5-01
(alinhamento canônico do Battle), sem antecipar `GO` de Store: S3-04 ainda
depende de validação humana TalkBack/VoiceOver e Sprints 5–10 permanecem abertas.
