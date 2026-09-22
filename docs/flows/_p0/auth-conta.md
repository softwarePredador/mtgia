# P0 CORE — Autenticação, conta e aceite legal

Medição contra o código em `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
(branch `codex/free-beta-release-candidate-2026-07-17`, HEAD `d15beb05b`), medida em
2026-09-21 sobre `9a9ba66de` e **conferida em 2026-09-22 sobre `d15beb05b`**.
Os três commits entre os dois HEADs (`b397f477b`, `d08c18717`, `d15beb05b`) tocam só
`docs/qa/execution/2026-09-21/*` e `server/test/play_vs_ai_real_xmage_e2e_test.dart`;
nada de auth/conta mudou. Linhas do backlog abaixo referem-se à working tree atual
(o arquivo `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md` está modificado e
não commitado; as linhas batem com `source_line` do `TASK_REGISTRY.json`).

**Segunda verificação adversarial (2026-09-22, mesmo HEAD, somente leitura).** Correções
aplicadas no corpo e resumidas na seção final "Verificação adversarial — 2ª rodada":
os três testes live que sustentam o eixo PROVADO **já passaram** (receipts de 2026-07-21,
arquivos com SHA-256 idêntico ao atual) — a rodada anterior disse que "ninguém roda";
AUTH-001 e LEGAL-ACCEPT-001 caem de "metade" para "mal-comecada"; AUTH-001 sobe de ~85
para ~110 arquivos de servidor + ~12 do app; AUTH-004 e AUTH-006 passam a exigir prova
viva de UI (mexem em tela); LEGAL ganha uma asserção nova (versão legal duplicada no app,
sem gate de paridade); o login é um oráculo de enumeração por tempo, aberto hoje, que
nenhuma tarefa cobre. Atenção: existe uma cópia **anterior e desatualizada** desta medição
dentro do repo, não rastreada, em `docs/flows/_p0/auth-conta.md` (2026-09-21, HEAD
`9a9ba66de`, números de antes das duas verificações).

Conferência por amostragem em 2026-09-22 (abri os testes, não confiei nos nomes):
- AUTH-003 #1/#5/#6 — `server/test/account_security_live_test.dart:98-104` afirma 202
  para email inexistente e existente e `message` igual; `:135-140` reusa token consumido
  e afirma 400 `reset_token_invalid`; `:141-149` afirma 401 para `tokenA`, `tokenB` e
  para a senha antiga. **Confere.**
- AUTH-004 #2 — `server/test/privacy_account_live_test.dart:185-189` (400
  `invalid_deletion_confirmation`), `:199-200` (401 `invalid_password`), `:237` (sessão
  antiga 401 após exclusão). **Confere.**
- LEGAL-ACCEPT-001 #1 — `server/test/legal_consent_live_test.dart:67-101` (400
  `legal_acceptance_required` sem linha; versão obsoleta 400 sem linha; 201 e as 4 colunas
  com versão exata + `DateTime`; plano na mesma transação) e
  `server/test/legal_consent_contract_test.dart:19-36` (4 colunas em `database_setup.sql`
  e na migração `043`, as duas constraints de par, rollback `manualOnly`). **Confere.**
- Greps de ausência reconfirmados sobre `d15beb05b`: `legal_acceptance_required` em
  `app/lib` = 0; `invite|allowlist|waitlist|admission` em `database_setup.sql` +
  `migrate.dart` = 0; `step_up|reauth` em `server/lib`, `server/routes`, `app/lib` = 0;
  `content-encoding|gzip` em `server/routes` + `server/lib` = 0; os 7 pontos de
  `e.toString()` no corpo continuam nos mesmos arquivos:linhas; `server/routes/users/_middleware.dart:4-6`
  continua só com `authMiddleware()`; `server/lib/rate_limit_middleware.dart:251` e
  `:264-266` continuam iguais (a caracterização "fail-open" foi **corrigida** na
  verificação adversarial — ver achado transversal 1); `rate_limit_middleware_test.dart:224`
  continua afirmando `in_memory_fallback`.

Somente leitura. Nenhum teste foi executado: os estados "PROVADO" abaixo significam
**existe um teste que afirma aquilo** (li o teste), não "o teste passou hoje". Onde há
receipt de execução, ele é citado com data e SHA-256 do arquivo de teste.

## Tabela-resumo do grupo

| ID | Estado declarado | Estado medido | Asserções PRONTO_E_PROVADO | PRONTO_SEM_PROVA | PARCIAL | NAO_ENCONTRADO | Arquivos a tocar | Testes a escrever | Migração |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BT-AUTH-001 | TODO | **mal-comecada** (era metade) | 1 (trivial) | 2 | 3 | 0 | **~110 servidor + ~12 app** (era ~85) | 7 | não |
| BT-AUTH-002 | TODO | mal-comecada | 0 | 0 | 3 | 4 | ~10 (até ~45 se "limite por campo" valer para a API inteira) | 4 | não |
| BT-AUTH-003 | TODO | quase-la (só no eixo IMPLEMENTADO) | 3 | 3 | 0 | 1 | 3 | 4 (+1 se bucket por email) + re-rodar o harness | não |
| BT-AUTH-004 | TODO | mal-comecada | 0 | 0 | 4 | 2 | **~10 (inclui 2 do app)** | 8 | condicional |
| BT-AUTH-006 | TODO | nao-comecada | 0 | 1 | 1 | 7 | ~12 (inclui app) | 7 | **sim** |
| BT-LEGAL-ACCEPT-001 | TODO | **mal-comecada** (era metade) | 1 | 0 | 1 | 5 | **~13 (inclui app)** | 6 | condicional |

(Tabela recontada duas vezes. 1ª rodada: a versão original somava errado em 5 das 6
linhas. 2ª rodada: AUTH-003 passa a ter 7 asserções (a #5 foi dividida em 5a/5b) e
LEGAL-ACCEPT-001 passa a ter 7 (asserção #7 nova); AUTH-003 #2 e AUTH-006 #5 subiram
para PRONTO_SEM_PROVA. **Prova viva de UI** (contrato `docs/MANALOOM_E2E_RELEASE_CONTRACT.md:180-182`:
toda UI alterada exige `PASS_AUTOMATED`, `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED`) é
exigida por AUTH-004, AUTH-006 e LEGAL-ACCEPT-001, e por AUTH-001 se o código de erro
substituir a frase — ver cada seção.)

Leitura rápida do grupo: **BT-AUTH-003 é a única que está a um passo de fechar no
código** (falta timing, a asserção de shape e decidir rate limit por email) — e o teste
que a prova passou em 2026-07-21 com o arquivo idêntico ao de hoje, mas não roda desde
então. Fechar AUTH-003 **não** torna as contas não-enumeráveis: o login responde mais
rápido para email inexistente (sem bcrypt) e está aberto hoje (achado transversal 11).
**BT-AUTH-006 não existe: zero linha de código.** As outras quatro têm a parte
"mecânica" pronta e a parte "contrato" ausente — e em AUTH-001 e LEGAL-ACCEPT-001 a
parte ausente é a maior.

**Aviso sobre o eixo PROVADO, válido para todo o grupo (reescrito na 2ª rodada — a
versão anterior deste aviso estava errada):** os três testes live que sustentam os
`PRONTO_E_PROVADO` deste grupo (`server/test/account_security_live_test.dart`,
`server/test/privacy_account_live_test.dart`, `server/test/legal_consent_live_test.dart`)
não estão em preset de `server/dart_test.yaml` (`:1-49`; preset `live` em `:61-79`) e o
gate `full` os exclui por tag (`scripts/quality_gate.sh:89`). **Mas já foram executados
com PASS.** O runner deles é o harness isolado `scripts/manaloom_server_contract_e2e_isolated.sh`,
que recebe caminhos de teste como argumento (`:795-798`; sem argumento roda só
`error_contract_test.dart`), sobe o servidor com `MANALOOM_E2E_ISOLATED_RUNTIME=1` (`:656`),
`MANALOOM_PASSWORD_RESET_TEST_RESPONSE` (`:647`), fixture local de email (`:649`) e
`MANALOOM_REQUIRE_LEGAL_ACCEPTANCE` configurável (`:661`). Os receipts estão em
`docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md` — fora de
`docs/qa/execution/`, por isso a rodada anterior não os achou: S1-05 (`:133-158`,
export/exclusão, `1/1` PASS), S1-08 (`:250-289`, recuperação, `3/3` PASS combinado) e
S1-09 (`:297-318`, legal, no mesmo `3/3`). **O SHA-256 dos arquivos de hoje bate com o
dos receipts:** `account_security_live_test.dart` = `57e109cf…2218` (receipt `:286`) e
`legal_consent_live_test.dart` = `c344e77f…b454` (receipt `:316`);
`privacy_account_live_test.dart` difere só no prefixo do filename afirmado
(`manaloom-` → `brewtact-`, commit `8264ffb27`; receipt `:156` tem o hash da versão
anterior). Deriva de código desde o checkpoint `776b9e25d` (`git diff --stat 776b9e25d HEAD`):
`routes/auth/*` e `auth_service.dart` **não mudaram**; `user_data_privacy_service.dart`
(+211) e `routes/users/me/index.dart` (+41) mudaram; o middleware raiz ganhou o gate de
capability (+70), que hoje nega `POST /auth/register` — por onde os três começam
(`account_security_live_test.dart:80`, `legal_consent_live_test.dart:21-22`,
`privacy_account_live_test.dart:35-43`). Portanto "PROVADO" aqui significa **"passou em
2026-07-21, num SHA anterior, e não roda desde então"**: evidência real, porém velha; nenhum
receipt no HEAD. Re-rodar é barato mas não é um comando só: exige um arquivo de capability
isolado com `account_registration` ligado (molde em `scripts/manaloom_play_vs_ai_e2e.sh:441`
e `scripts/manaloom_authenticated_visual_qa_isolated.sh:304`) e **duas execuções**, porque
os testes são incompatíveis entre si no mesmo runtime: `privacy_account_live_test.dart:35-43`
registra **sem** aceite legal (exige `MANALOOM_REQUIRE_LEGAL_ACCEPTANCE=false`) e
`legal_consent_live_test.dart:67-73` exige `true`. O harness tem corrida conhecida em
execuções seguidas (`docs/qa/execution/2026-09-21/PONTO_DE_RETOMADA.md:40-43`).

---

## BT-AUTH-001 — Padronizar erros públicos tipados

Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:258` (registry `source_line: 258`)
Aceite: *"Corpus de falhas retorna código estável e request-id; zero detalhe interno."*

Decomposição em 6 asserções.

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Existe um corpus de falhas exercitado (bateria de casos de erro por rota) | PRONTO_E_PROVADO (asserção trivial — ver nota) | — | `server/test/error_contract_test.dart:188-1702`: 116 `test(` live contra `/auth`, `/decks`, `/ai`, `/trades`, `/conversations`, `/notifications`. **O que afirma de verdade:** só 41 dos 116 casos usam `expectJsonErrorContract` (`:116-122`, `body['error'] is String`); 6 usam `expectJsonOrPlainErrorContract` (`:124-138`, aceita `error` **ou** `message`, e aceita corpo não-JSON); 3 usam `expectJsonMessageContract` (`:148-154`, só `message`); os `expectOptional*` (`:156-186`) somam 58 chamadas, das quais **49** aceitam status ambíguo (`anyOf(400, 404)` ×11, `anyOf(401, 404)` ×22, `anyOf(405, 404)` ×16) — contagem refeita na 2ª rodada; a anterior dizia "~66 ambíguas". Zero leituras de `x-request-id`, zero `equals('<código>')` no campo `error` (só `:449` afirma `isNotEmpty`). **Agravante (2ª rodada):** a negação de capability responde **404** `capability_unavailable` (`server/lib/release_capability_policy.dart:186-192`), então toda chamada que aceita 404 passa sem chegar ao handler quando a capability da rota está OFF no arquivo usado — o corpus não distingue "a rota respondeu um erro tipado" de "o gate negou". E o `setUpAll` registra **sem** aceite legal (`:19-23`, `:46-50`), então só roda com `MANALOOM_REQUIRE_LEGAL_ACCEPTANCE=false` e registro aberto. É o teste padrão do harness isolado (`scripts/manaloom_server_contract_e2e_isolated.sh:797`), mas não achei receipt de execução dele em `docs/qa/` | Esta asserção só afirma que o corpus **existe**; não prova nenhuma das três exigências do aceite (código estável, request-id, zero detalhe). Contar como "provado" infla o placar de AUTH-001: no eixo do aceite, ela está em 0/3 provado |
| 2 | Toda falha devolve **código estável** (snake_case), não frase humana | PARCIAL | Onde acerta: `server/lib/legal_policy.dart:38-41`, `server/lib/verified_email_middleware.dart:22-47`, `server/routes/auth/reset-password.dart:22-34`, `server/routes/_middleware.dart:74,95,131`. **Correção:** `server/lib/rate_limit_middleware.dart:103-121` é só o construtor do corpo; quem o chama passa **frase**: `'Too Many Login Attempts'` (`:411`, `:433`), `'Too Many Requests'` (`:302`), `'Too Many AI Requests'` (`:527`, `:550`). Os 429 do grupo inteiro são frase, não código | `server/test/error_contract_test.dart:116-122` só afirma `body['error'] is A<String>` — aceita frase em português como se fosse código | Recontagem (regex `'error': '<valor>'` sobre `server/routes/**`): **224 ocorrências de frase em 64 arquivos** vs. 64 ocorrências de código snake_case em 30 arquivos (2ª rodada: 228 na working tree de hoje — `server/routes/community/marketplace/index.dart` está modificada e não commitada); mais **16 arquivos / 21 ocorrências** de `server/lib/` com frase (2ª rodada: a lista anterior tinha 8 porque o grep por linha não pega string multilinha; faltavam `ai/generate_bracket_support.dart:271`, `ai/generate_structural_quality_support.dart:173`, `ai/optimize_route_bracket_policy_filter_support.dart:113`, `ai/optimize_route_final_gate_support.dart:48`, `ai_generate_performance_support.dart:345`, `decks/optimization_apply_authorization_support.dart:10`, `decks/optimization_bracket_support.dart:80`, `decks/optimization_functional_role_floor_support.dart:19`). 15 corpos só com `message` (`server/routes/auth/login.dart:29,36`; `register.dart:45,51,57,65`, …). Não existe catálogo: `docs/generated/openapi.generated.json` tem 121 paths e **zero** schema de erro. **Dependência não declarada descoberta:** o app decide "sessão caiu" por **substring da frase** — `app/lib/core/api/api_client.dart:104-114` procura `'token'`, `'faça login novamente'`, `'authentication_required'` em `error + message`; trocar as frases de `auth_middleware.dart:31,49` por um código que não contenha `token`/`invalid_session`/`authentication_required` quebra a limpeza de sessão. **Acoplamento maior (2ª rodada):** o `FriendlyErrorMapper` do app prefere `error` a `message` (`app/lib/core/utils/friendly_error_mapper.dart:266`), casa substrings de frase (`:272-313`) e **devolve o texto cru** quando ele não "parece técnico" (`:317-318`) — um código como `deck_not_found` não parece técnico, então iria direto para a tela. É o que já acontece hoje com os códigos existentes no cadastro (LEGAL-ACCEPT-001 #4). 29 arquivos de `app/lib` referenciam o mapper (contando ele mesmo) e 17 leem `['error']` direto (ex. `features/decks/providers/deck_provider.dart:1471`, `features/decks/widgets/deck_details_actions.dart:44`). Se o código **substituir** a frase, o app entra no escopo (mapper vira catálogo código→mensagem + ~10 leitores diretos); se vier **ao lado** (campo novo), o app fica opcional. Essa escolha é decisão humana e muda o tamanho da tarefa |
| 3 | Toda resposta (inclusive falha) traz request-id | PRONTO_SEM_PROVA (confirmado) | `server/routes/_middleware.dart:196` injeta `x-request-id` no merge final; caminhos de erro em `:75`, `:96`, `:101`, `:141`, `:156`, `:240`. Geração/validação em `server/lib/request_trace.dart:48-59`. Conferi o caminho que escapa: as únicas linhas fora do `try` (`:57-144`) são funções puras sobre strings (`resolveRequestId`, `_corsPolicy.isAllowed`, `decisionFor`); se alguma delas lançar, a resposta sai do framework sem o header — improvável, mas é o único buraco | **Correção (2ª rodada): existe um, e só um.** `server/test/ai_provider_failure_injection_live_test.dart:83-90` envia `x-request-id` para `POST /ai/generate` e afirma que o **503** devolve o mesmo id (`:90`) — prova o merge de `:196` para **uma** rota de handler; é live, exige aprovação explícita de mutação (`:13-20`), está atrás de `ai_generate_rebuild` OFF e fora de preset. (Ele também afirma `error == 'AI provider is not configured'`, `:92` — consagra frase como código.) Os caminhos precoces (`:75`, `:96`, `:141`, `:156`) e o `catch` (`:240`) seguem sem teste. `server/test/request_trace_test.dart` cobre só `resolveRequestId`. O harness de runtime do middleware raiz já existe (`server/test/release_capability_policy_test.dart:419-437` chama `root_middleware.middleware(...)` direto, sem PG) e nenhum dos seus testes lê o header | Uma asserção de header no corpus e nos testes do harness raiz; estado mantido em PRONTO_SEM_PROVA porque "toda resposta" não é exercitado |
| 4 | Zero detalhe interno (texto de exceção/SQL) no corpo público | PARCIAL — **falha concreta, e parte dela ABERTA hoje** | Vazamentos (7, recontados por regex e confirmados): `server/routes/decks/[id]/cards/index.dart:436`, `.../cards/bulk/index.dart:393`, `.../cards/replace/index.dart:225`, `.../cards/set/index.dart:243` — todos `body: {'error': e.toString()}`; `server/routes/decks/[id]/index.dart:592` `notFound(e.toString())`; `server/routes/auth/login.dart:60` e `server/routes/auth/register.dart:138` devolvem `e.toString()` como `message` com 400 — `ServerException extends PgException implements Exception` (`~/.pub-cache/hosted/pub.dev/postgres-3.5.9/lib/src/exceptions.dart:64,86`), então falha de banco no login vira corpo público; também `FormatException` de JSON malformado (`login.dart:22`) e `Exception('Invalid password hash format: $e')` (`server/lib/auth_service.dart:74`) saem como `message`. 17 chamadas passam `details: error` para `server/lib/http_responses.dart:11-12`. **Eixo ABERTO:** `POST /auth/login`, `GET /users/me/plan` (`details: e`, `server/routes/users/me/plan/index.dart:33`) e `GET/POST /users/me/activation-events` (`:87`, `:122`) estão em `_exactControlPlaneRequests` (`server/lib/release_capability_policy.dart:601,613,615-616`) — são alcançáveis **hoje**, com a matriz toda OFF. Dos 7 `toString()`, só o de login está aberto; dos 17 `details:`, 6 estão no plano de controle (3 em `/health/*`, 3 em `/users/me/*`). **Correção (2ª rodada):** os 3 de `/health/*` (`ai-history`, `commercial`, `dashboard`) estão atrás de `operationalAdminMiddleware` (`server/routes/health/_middleware.dart:5-12`; só `/health`, `/health/live` e `/health/ready` são públicos, `server/lib/admin_access_support.dart:14-22`) — vazam só para quem tem chave de ops ou é admin. Alcançáveis por usuário comum hoje: **4** (login, anônimo; `plan` e `activation-events`, com bearer, vazando para o próprio dono). O de login é o pior: além de `ServerException`, qualquer corpo JSON malformado vira `FormatException` e sai como `message` com 400 (`login.dart:22` → `:57-72`) | Nenhum | Corrigir os 7 pontos de `toString()` e os 17 `details:`; adicionar gate estático que proíba o padrão |
| 5 | Stack trace nunca sai do middleware raiz | **PRONTO_SEM_PROVA** (rebaixada de PRONTO_E_PROVADO) | `server/routes/_middleware.dart:237-241` devolve corpo fixo `{'error': 'Erro interno do servidor'}`; `:225-228` loga só `type=${e.runtimeType}` — confirmado | `server/test/root_error_logging_contract_test.dart:6-13` afirma **quatro strings no fonte**: que `print('[ERROR] middleware: $e')` e `print('[ERROR] stack: $st')` não existem, e que `type=${e.runtimeType}` e `captureObservedException(` existem. **Não afirma nada sobre a resposta**: nem status 500, nem corpo fixo, nem ausência de `$e`/`$st` em `Response.json`. `grep "Erro interno do servidor" server/test/` = 0. A asserção é sobre o que **sai** para o cliente; o teste cobre só o que vai para o **log** | Um teste de runtime que injete um handler que lança e afirme `500`, corpo exatamente `{'error': 'Erro interno do servidor'}` e `x-request-id` presente. Barato (2ª rodada): o harness de `server/test/release_capability_policy_test.dart:419-437` já chama o middleware raiz sem PG, e com `GET /health/live` (`processLiveness`, `routes/_middleware.dart:67-69,147`) o handler é chamado sem conectar ao banco |
| 6 | Logs não imprimem exceção crua | PARCIAL — **muito maior do que 2 arquivos** | Recontagem: **51 `print(... $e ...)` em 27 arquivos de `server/routes/`** (ex. `auth/login.dart:58,74,75`, `auth/register.dart:136,144,145`, `cards/index.dart:131`, `cards/resolve/index.dart:193,576`, `decks/index.dart:581`) **+ 13 em 5 arquivos de `server/lib/`**, mais 28 `Log.e/Log.w(... $e ...)` em `routes`+`lib` (ex. `server/routes/users/me/index.dart:302`) | O teste da linha 5 cobre **só** `routes/_middleware.dart` | Remover/normalizar 64 `print` em 32 arquivos e decidir se `Log.e('... error=$e')` conta como "cru" (28 pontos); gate estático |

### O que realmente falta

A infraestrutura existe e é boa: há request-id em toda resposta, há captura de Sentry,
há um corpus vivo com 116 casos de falha. O que não existe é o **contrato**: nenhum
lugar define a lista de códigos estáveis, o corpus aceita frase em português como se
fosse código (e em 49 chamadas aceita até status ambíguo, o que o faz passar pelo gate
de capability sem tocar a rota), e sete rotas ainda devolvem o texto da exceção — a de
login está aberta hoje no plano de controle, onde uma falha do Postgres ou um JSON
malformado vira corpo público com 400. **Status medido revisto na 2ª rodada: de "metade"
para "mal-comecada".** Pelas ocorrências, o código estável cobre ~20% dos erros
(64 códigos contra 228 + 21 frases); no eixo do aceite, 0 de 3 exigências está provada; e
o volume que resta é o maior do grupo. O trabalho é: (a) escrever o catálogo de códigos e
publicá-lo no OpenAPI; (b) converter os **64 arquivos de rota + 16 de lib** que usam frase
no campo `error` (228 + 21 ocorrências) — é trabalho mecânico, mas é o volume da tarefa;
(c) matar os 7 `toString()` e os 17 `details:`; (d) normalizar os 64 `print($e)` em
32 arquivos; (e) endurecer `error_contract_test.dart` para afirmar código exato +
`x-request-id` + ausência de detalhe interno, e adicionar um gate estático contra o
padrão; (f) **o app**: `api_client.dart:104-114` decide logout por substring, e o
`FriendlyErrorMapper` mostra o texto cru de `error` na tela — se o código substituir a
frase, o mapper vira catálogo código→mensagem e ~10 leitores diretos de `['error']` mudam
junto. Não exige migração nem serviço externo. **Decisões humanas:** a nomenclatura do
catálogo (barata) e se o código **substitui** a frase em `error` ou vem **ao lado** (campo
novo) — a segunda opção tira o app do caminho crítico; a primeira muda texto em tela e,
pelo contrato de UI (`docs/MANALOOM_E2E_RELEASE_CONTRACT.md:180-182`), passa a exigir
prova viva das telas afetadas. **Volume revisado na 2ª rodada: ~110 arquivos de servidor**
(união, por regex, de 85 arquivos de rota com frase, `print`/`Log` de exceção, vazamento
ou corpo só com `message`; 21 de lib; `http_responses.dart`; catálogo novo; gerador do
OpenAPI; 2 testes) **+ ~12 do app** se o código substituir a frase (mapper, `api_client.dart`,
~8 leitores diretos, 2 testes). 7 testes (os 6 anteriores + 1 do mapper do app).

**Dependência declarada:** nenhuma. É real: pode começar hoje.
**Sobreposição:** é a tarefa-base de forma de erro para BT-AUTH-002 (código do 413),
BT-AUTH-006 (códigos de negação de admissão) e BT-LEGAL-ACCEPT-001 (`legal_acceptance_required`).
Se ela for feita depois das outras três, as outras três serão reescritas.

---

## BT-AUTH-002 — Limites de body antes do parse

Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:259` (registry `source_line: 259`)
Aceite: *"Oversize/chunked/compressed rejeitado antes de alocar/gravar; DB não cresce."*

Decomposição em 7 asserções.

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Limite **global** de body, aplicado antes do parse | NAO_ENCONTRADO | `server/main.dart:8-14` chama `serve(handler, ip, port, poweredByHeader: null)` sem limite; `server/routes/_middleware.dart:56-144` nunca lê `content-length` da requisição (o `content-length` de `:181-183` é da **resposta**, para corrigir 405) | Nenhum | Todo o mecanismo |
| 2 | Existe limite por rota em alguma parte | PARCIAL (com um teste que a medição anterior não viu) | Só 5 rotas, todas de Battle: `server/routes/ai/battle/jobs/index.dart:50-59`, `server/routes/ai/battle/sessions/index.dart:77`, `server/routes/ai/battle/sessions/[id]/actions/index.dart:22-28`, `server/routes/ai/battle/sessions/[id]/concede/index.dart:24`, `server/routes/decks/[id]/battle-replays/[replayId]/annotations/index.dart:76-85` | **Existe:** `server/test/battle_replay_annotation_routes_test.dart:45-66` chama a rota com corpo de `16 KiB + 1` e um `_ThrowingPool`, e afirma 413, `error == 'battle_annotation_body_too_large'` e `pool.calls == 0` (rejeita antes do banco). `server/test/battle_job_routes_contract_test.dart:14` é só leitura estática do fonte | As outras 131 rotas (`find server/routes -name '*.dart'` = 136). E essas 5 estão atrás de capability OFF, ou seja, o único limite que existe hoje está em código inalcançável. O teste que existe é molde bom para o teste global |
| 3 | Rejeição acontece **antes de alocar** | PARCIAL | O padrão atual não cumpre: `server/routes/ai/battle/jobs/index.dart:57` faz `await context.request.body()` (aloca o corpo inteiro) e só mede em `:58`. O check de `content-length` em `:50-54` só atua se o cliente declarar. O mesmo vale para `annotations/index.dart:76-77` | O teste da linha 2 prova "antes de **gravar**" (`pool.calls == 0`), não "antes de **alocar**" — o corpo já está na memória quando é medido | Interceptar no stream, não depois de `body()` |
| 4 | Chunked (sem `content-length`) rejeitado | NAO_ENCONTRADO | O guard de `:50-54` é `if (declaredLength != null && ...)` — sem header, passa direto para o `body()` completo | Nenhum | Todo o mecanismo |
| 5 | Compressed (gzip bomb) rejeitado | NAO_ENCONTRADO | `grep -i "content-encoding\|gzip"` em `server/routes` e `server/lib`: **zero ocorrências** | Nenhum | Todo o mecanismo de **rejeição**. Nuance (2ª rodada): como nada no servidor descomprime corpo de requisição (nenhum `Content-Encoding`/`GZipCodec` no código; `server/main.dart:13` usa o `serve` padrão), um corpo gzip chega cru e conta pelo tamanho comprimido — a "bomba" não expande; o risco colapsa no de oversize (#1/#4). Falta só recusar `Content-Encoding` diferente de `identity` com 415 e um teste — poucas linhas |
| 6 | Limites por campo e por URL | PARCIAL | Existe: senha 12–256 (`server/lib/password_policy.dart:4-5,13,19`), token opaco ≤512 (`server/lib/auth_service.dart:400` e `:508`), request-id ≤96 (`server/lib/request_trace.dart:14`). Não existe: tamanho de `email`/`username` em `server/routes/auth/login.dart:23-24` e `server/routes/auth/register.dart:27-28`; nenhum limite de comprimento de URL ou de query em lugar nenhum. (2ª rodada) Existe também, e a medição não citou: `PATCH /users/me` limita `display_name` 50, `avatar_url` 500, `location_city` 100, `trade_notes` 500 (`server/routes/users/me/index.dart:115,146,181,198`). No cadastro, `username` só tem mínimo (`register.dart:63-68`) e `email` não tem nem formato nem tamanho (`:49-54`), com as duas colunas `TEXT UNIQUE` sem teto (`server/database_setup.sql:9-10`); um valor pouco compressível acima do limite de linha de índice btree do Postgres (~2,7 KB) deve falhar no `INSERT` com `ServerException` — não executei — e qualquer `ServerException` sai crua pelo `on Exception` de `register.dart:135-142` (cruza com AUTH-001 #4; fechado hoje pela capability) | `server/test/rate_limit_middleware_test.dart` não cobre isto | Limites de campo nas rotas de auth e um limite de URL/query no middleware raiz. Se "limites por campo" da entrega valer para a API inteira: 55 arquivos de rota leem corpo e só 19 têm algum teto de tamanho (heurística por regex) — mais ~36 arquivos |
| 7 | "DB não cresce" demonstrado | NAO_ENCONTRADO | — | Nenhum | Um teste live que empurra oversize/chunked e conta linhas antes/depois |

### O que realmente falta

Praticamente tudo. Existe um bom *padrão de referência* em `ai/battle/jobs/index.dart:50-59`
(código de erro tipado `battle_job_body_too_large`, 413, mensagem) — mas ele mede depois
de já ter alocado o corpo, não trata chunked, não trata gzip, e vive em 5 rotas que hoje
estão atrás de capability OFF. O trabalho é: um middleware/limite global no `serve` de
`server/main.dart` ou no `routes/_middleware.dart` que corte no stream antes de `body()`,
com teto por rota para as poucas que precisam de mais; limite de campo em `/auth/login`
e `/auth/register`; limite de URL/query; 4 testes (oversize declarado, chunked sem header,
gzip expandindo acima do teto, e o teste de "DB não cresce"). Sem migração, sem serviço
externo, sem decisão humana além de escolher o número do teto global.
Prova viva não é obrigatória, mas o teste de "DB não cresce" é live (precisa de Postgres).
(2ª rodada) Os ~10 arquivos cobrem o **aceite**; a **entrega** ("limites por campo/URL")
lida literalmente para a API inteira soma mais ~36 arquivos de rota que leem corpo sem teto
de campo — decidir o escopo antes de estimar. O caso gzip é mais barato do que parecia (nada
descomprime; basta recusar `Content-Encoding`).

**Dependência declarada:** nenhuma. É real: pode começar hoje.
**Dependência não declarada que eu descobri:** o código de erro 413 deveria sair do
catálogo de BT-AUTH-001. Fazer as duas fora de ordem gera retrabalho no corpo de resposta.
**Sobreposição:** BT-SEC-001 (`rate limiting distribuído fail-closed`) declara depender
desta; na prática as duas mexem no mesmo middleware raiz e poderiam ser um PR só.

---

## BT-AUTH-003 — Recuperação de senha não enumerável

Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:260` (registry `source_line: 260`)
Aceite: *"Conta existente/inexistente indistinguível em status, shape e timing aceitável; replay de token falha."*

Decomposição em 7 asserções (a #5 original foi dividida em 5a/5b na 2ª rodada, porque o
teste prova uma metade e não a outra).

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | **Status** indistinguível entre conta existente e inexistente | PRONTO_E_PROVADO (teste com PASS em 2026-07-21, receipt S1-08, arquivo idêntico ao atual; não re-executado — ver aviso no topo) | `server/routes/auth/forgot-password.dart:59-67` devolve 202 sempre; o `try/catch` de `:28-48` engole falha de banco **e** de entrega, então até com o Postgres fora a resposta é 202; `server/lib/auth_service.dart:449-451,469` documenta que `null` significa "desconhecida ou inativa" (`deleted_at IS NULL`, `:464`) | `server/test/account_security_live_test.dart:98-104` — dispara forgot para `missing_<suffix>@example.invalid` e para o email real, afirma 202 nos dois (`:102-103`) e `message` igual (`:104`). Confere. **Mas o teste depende de `test_reset_token`** (`:105`, `:117`, `:129`) — só roda com `MANALOOM_PASSWORD_RESET_TEST_RESPONSE` e `ENVIRONMENT != production`, e começa por `POST /auth/register` (`:80-88`), atrás de `account_registration: off`. (2ª rodada) Rodou com PASS no harness isolado: `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md:277` (`3/3`), hash do arquivo em `:286` = SHA-256 atual (`57e109cf…2218`); `forgot-password.dart` e `auth_service.dart` não mudaram desde o checkpoint `776b9e25d` | Nada no código; falta re-rodar no HEAD (capability isolada com registro ligado) e ter receipt atual |
| 2 | **Shape** (conjunto de chaves) indistinguível | **PRONTO_SEM_PROVA** (promovida de PARCIAL na 2ª rodada) | Em produção sim: só `message` (`forgot-password.dart:61-66`). Fora de produção, `test_reset_token` aparece **só** para conta existente (`:63-65`), guardado por `server/lib/password_reset_delivery_service.dart:13-20` (exige `ENVIRONMENT != production` **e** `MANALOOM_PASSWORD_RESET_TEST_RESPONSE=I_UNDERSTAND_RESET_TOKENS_ARE_TEST_ONLY`). **Por que subiu:** em produção a diferença é impossível por duas travas — o guarda devolve `false` com `ENVIRONMENT=production` mesmo com a frase de aprovação, e o preflight de produção **recusa subir** se a variável existir (`server/lib/auth_runtime_policy.dart:94-97`). O "oráculo de staging" é um gancho de teste deliberado, com trava dupla, não um defeito do aceite — e nem existe staging: o servidor só sobe com `ENVIRONMENT` = `development` ou `production` (`server/lib/auth_runtime_policy.dart:41-45`, chamado no boot por `server/main.dart:10-12`); o único risco residual é um servidor de *development* exposto com a frase de aprovação ligada | `account_security_live_test.dart:104` compara **só** `body['message']`, não o conjunto de chaves. O guarda tem teste unitário que roda no gate `full`: `server/test/account_security_schema_contract_test.dart:40-64` afirma `false` em produção com a frase de aprovação, `true` em development com ela e `false` com valor errado. O preflight é testado para a variável-irmã de verificação de email (`server/test/auth_runtime_policy_test.dart:161-164`), mesma condição `||` | Uma asserção sobre `body.keys` numa execução **sem** a variável de teste (o live atual precisa dela para o resto do fluxo, então é uma execução separada). Decidir se algum ambiente público roda em `development` com a variável ligada (hoje nada no repo faz isso: só o harness isolado a liga, `scripts/manaloom_server_contract_e2e_isolated.sh:647`, em loopback) |
| 3 | **Timing** aceitável | NAO_ENCONTRADO (confirmado) | Para conta inexistente: 1 SELECT e retorna (`auth_service.dart:460-469`). Para conta existente: transação com 2 statements (`:474-494`) **mais** `await PasswordResetDeliveryService().deliver(...)` (`forgot-password.dart:33-37`) → `AccountEmailDeliveryTransport.deliver` (`password_reset_delivery_service.dart:66-81`), HTTP síncrono com timeout de 10s (`:31`). A diferença é de centenas de ms a segundos, e é um oráculo direto | Nenhum (`grep Stopwatch\|elapsed` nos testes que mencionam `forgot`: 0) | Tirar a entrega do caminho síncrono (fila/`unawaited`) ou aplicar um piso de tempo constante; um teste de timing. **Atenção ao custo da prova:** em dev a entrega pode ser omitida (`password_reset_delivery_service.dart:24-26`), então um teste de timing em dev mede só a transação; para provar o caso de produção o teste precisa de um transporte stub com latência — mais do que "um teste" |
| 4 | Rate-limited | **PRONTO_SEM_PROVA** (rebaixada de PRONTO_E_PROVADO na 1ª rodada; mantida na 2ª, mas a prova por composição está a um teste de distância: a classificação de `forgot-password` (`rate_limit_middleware_test.dart:227-248`) somada ao bloqueio do 6º pedido pelo mesmo `authRateLimit` (`:203-225`) só deixa de fora a junção das duas — copiar `:203-225` trocando o path, ~15 linhas. A identidade do cliente é sólida: em produção exige proxy confiável explícito e escolhe o hop pela direita do `X-Forwarded-For`, falhando fechado com 503 — `server/lib/auth_runtime_policy.dart:190-297`) | `/auth/forgot-password` está na lista de `isAuthCredentialAttempt` (`server/lib/rate_limit_middleware.dart:348-357`), aplicada em `server/routes/auth/_middleware.dart:12` — confirmado | `server/test/rate_limit_middleware_test.dart:227-248` afirma **só** que `isAuthCredentialAttempt(Request('POST', '/auth/forgot-password'))` é `true` e que `GET` é `false`: é um teste de classificação de path, não observa nenhum 429. O 429 só é observado para `/auth/register` (`:203-225`) e `/auth/login` (`:168-201`), e sempre com `limiterOverrideForTesting` — o limiter de produção (5/min, `:150-153`) e a ligação em `routes/auth/_middleware.dart:12` não são exercitados por teste nenhum. Nenhum teste envia `POST /auth/forgot-password` e recebe 429 | Um teste que mande N+1 `POST /auth/forgot-password` pela pilha real e afirme 429. Ressalvas que continuam: bucket por cliente/IP (`:379-393`), não por email; em dev teto 200/min (`:155-158`) e `anonymous` passa direto (`:395-397`); o distribuído só liga em produção (`:251`) e o comportamento sob falha do Postgres é indefinido e não testado (ver achado transversal 1, corrigido) |
| 5a | Reset invalida **sessões (JWT)** anteriores | PRONTO_E_PROVADO (PASS em 2026-07-21, receipt S1-08; não re-executado) | `server/lib/auth_service.dart:553-566` (`auth_version = auth_version + 1`); a checagem de versão está em `:337-339` (`getUserFromToken`), e `authMiddleware` usa exatamente essa função (`server/lib/auth_middleware.dart:42-43`), então a invalidação vale para `/users/*` também | `account_security_live_test.dart:141-142` afirma que `tokenA` e `tokenB`, emitidos antes, passam a devolver 401 em `/auth/me`; `:143-149` afirma que a senha antiga não loga mais. Confere | Nada |
| 5b | Reset (e cada novo pedido) invalida os **demais reset tokens** pendentes | **PRONTO_SEM_PROVA** (separada na 2ª rodada: a asserção original dizia "sessões e tokens" e o teste só prova sessões) | `auth_service.dart:567-574` consome todos os tokens pendentes no reset; `:474-482` faz o mesmo a cada novo `forgot-password` (o token anterior morre quando outro é pedido) | Nenhum. O teste emite `firstResetToken` (`:105`), pede outro (`:114`) e nunca volta a usar o primeiro; o replay de `:135-140` reusa o **mesmo** token (asserção #6), não um token irmão | Duas linhas no live existente: depois de `:114` (ou do reset de `:130`), tentar `firstResetToken` e afirmar 400 `reset_token_invalid`. Efeito colateral não medido: como cada pedido mata o anterior e o bucket é por IP, quem tem vários IPs pode invalidar o link da vítima indefinidamente — é o argumento a favor de bucket por email |
| 6 | Replay de token falha | PRONTO_E_PROVADO (PASS em 2026-07-21, receipt S1-08 — "token expirado ou reutilizado é rejeitado", `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md:257-258`; não re-executado) | `server/lib/auth_service.dart:536-542` rejeita `consumed_at != null` ou expirado, dentro de `runTx` com `FOR UPDATE OF t, u` (`:524`); `reset-password.dart:22-26` mapeia para 400 + `error.code` | `account_security_live_test.dart:135-140` reusa o token já consumido e afirma 400 com `error == 'reset_token_invalid'`; `:118-124` afirma o mesmo para token expirado artificialmente. Confere | Nada |

### O que realmente falta

Esta é a tarefa mais adiantada do grupo — **no eixo IMPLEMENTADO**: seis das sete
asserções existem no código (só timing não). **No eixo PROVADO** são três: status,
invalidação de sessões e replay são afirmados por um teste live que afirma exatamente o
que o aceite pede (202 nos dois casos, replay 400, sessões antigas 401) e que **passou em
2026-07-21** (receipt S1-08, arquivo com SHA-256 idêntico ao de hoje, código de recuperação
sem mudança desde então) — mas não roda desde que o registro foi fechado pelo gate de
capability. "Rate-limited", o shape e o consumo dos reset tokens irmãos estão em
PRONTO_SEM_PROVA, cada um a um teste pequeno de distância. Falta **timing**, que hoje é um
oráculo grosseiro porque a entrega do email é awaited dentro da rota — não é ajuste: é
tirar um HTTP externo do caminho da requisição e provar com um transporte stub com
latência; e falta decidir se "rate-limited" no aceite significa também por email, não só
por IP. Trabalho concreto: 3 arquivos (`server/routes/auth/forgot-password.dart` para tirar
o `deliver` do caminho síncrono, `server/lib/auth_service.dart` se entrar piso de tempo,
`server/lib/rate_limit_middleware.dart` se entrar bucket por email) e **4 testes** (timing
com transporte stub, `body.keys` numa execução sem a variável de teste, 429 real em
forgot-password, token irmão rejeitado) **+1** se entrar bucket por email, **mais**
re-rodar o live no HEAD pelo harness isolado (capability isolada com registro ligado) e
guardar receipt. Sem migração. Prova viva de UI não é necessária (nada muda em tela).
**Decisões humanas:** o que é "timing aceitável" (um número) e se o bucket por email entra.

**O que fechar AUTH-003 não entrega (2ª rodada):** as contas continuam enumeráveis pelo
**login**, que está aberto hoje no plano de controle: para email inexistente
`AuthService.login` lança em `server/lib/auth_service.dart:282-283`, antes do bcrypt de
`:294`; para email existente paga o bcrypt. Status e corpo são iguais (401 `Credenciais
inválidas`), o tempo não. E quando o registro abrir (AUTH-006), `POST /auth/register`
responde `Email já está em uso` / `Username já está em uso` (`auth_service.dart:167,178`
→ `register.dart:135-142`). Nenhuma das seis tarefas cobre isso (achado transversal 11).

**Dependência declarada:** nenhuma. É real.
**Dependência não declarada:** o comportamento sob falha do bucket distribuído
(`rate_limit_middleware.dart:255-267`; "fail-open" na medição original, provavelmente 500
segundo a 1ª rodada, indefinido e sem teste em qualquer leitura) é vizinho do que BT-SEC-001
existe para corrigir. Se o aceite de AUTH-003 exigir rate limit confiável sob falha, AUTH-003
depende de BT-SEC-001 — decisão a explicitar (achado transversal 1). Fora isso, o trabalho
de login (achado 11) não tem dono.

---

## BT-AUTH-004 — Step-up/reautenticação para export e exclusão

Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:261` (registry `source_line: 261`)
Aceite: *"Token antigo ou sessão roubada não executa ação sensível; rate limit distribuído."*

Decomposição em 6 asserções.

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Step-up exigido no **export** | NAO_ENCONTRADO (confirmado, e ABERTO hoje) | `server/routes/users/me/export/index.dart:8-30` só chama `getUserId(context)`; `server/routes/users/_middleware.dart:4-6` aplica **só** `authMiddleware()` — nem `verifiedEmailForMutations()`, nem rate limit. `grep -i "step_up\|step-up\|reauth\|reautent"` em `server/lib`, `server/routes` e `app/lib`: **zero ocorrências**. `GET /users/me/export` está em `_exactControlPlaneRequests` (`server/lib/release_capability_policy.dart:612`) → alcançável com a matriz toda OFF | `server/test/privacy_account_live_test.dart:143` só afirma que sem token dá 401. **Pior:** `:145-149` afirma **200 para export com bearer simples** e `:159-178` lê o conteúdo — o teste **consagra** a ausência de step-up; fechar esta asserção obriga a reescrevê-lo | Todo o mecanismo. Hoje um bearer válido de 24h exporta a conta inteira |
| 2 | Step-up exigido na **exclusão** | PARCIAL | Existe reverificação de senha + confirmação literal: `server/routes/users/me/index.dart:322-339` e `server/lib/user_data_privacy_service.dart:600-623` (`InvalidAccountPasswordException`; `verifyPassword` bcrypt em `:619`) | O mecanismo parcial é afirmado por `server/test/privacy_account_live_test.dart:185-189` (confirmação errada → 400 `invalid_deletion_confirmation`), `:199-200` (senha errada → 401 `invalid_password`), `:237` (sessão antiga 401 depois da exclusão). Confere. Teste fora de gate | Não é step-up no sentido do aceite: não há janela de frescor de autenticação, nem token de reautenticação, nem verificação de que a sessão em uso é recente. É "pede a senha de novo" — melhor que nada, mas não cobre "token antigo". **Achado novo:** essa reverificação **não tem limite de tentativas** — `users/_middleware.dart` não aplica limiter e `authRateLimit` só cobre `/auth/*` (`rate_limit_middleware.dart:348-357`); `grep -i "attempt\|throttle\|lockout"` em `user_data_privacy_service.dart` só acha o nome da tabela `battle_simulation_attempts` (`:355-364`), nada de throttle. Quem tem um bearer roubado pode chamar `DELETE /users/me` com senhas diferentes sem teto: é um **oráculo de senha ilimitado** (cada tentativa custa um `FOR UPDATE` + bcrypt no servidor). Precisão da 2ª rodada: o acerto **apaga a conta** (a confirmação literal vai junto), então o que o atacante ganha é sabotagem (exclusão da conta da vítima) e a senha em claro para reuso em outros serviços, e o servidor paga bcrypt por tentativa (vetor de CPU). As rotas irmãs que também reverificam senha (`POST /auth/change-password`, `/auth/revoke-sessions`) estão no bucket de credenciais; só esta escapa. O teste `:199-200` faz 1 tentativa errada e afirma que a sessão sobrevive (`:202-212`) — nunca faz N. O mecanismo parcial passou em 2026-07-21 (receipt S1-05, `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md:133-158`), mas o código de exclusão mudou depois (`user_data_privacy_service.dart` +211, `users/me/index.dart` +41 desde `776b9e25d`) |
| 3 | Token **antigo** não executa ação sensível | PARCIAL | A única invalidação existente é por `auth_version` (`server/lib/auth_service.dart:337-339`), e ela só muda depois de reset/change/revoke (`:558`, `:641`). Um token emitido há 23h e roubado continua plenamente válido; a duração é fixa em 24h (`auth_service.dart:49`) | Indireto: `account_security_live_test.dart:141-142,171,186` provam a invalidação **após** rotação, não frescor | Conceito de "autenticação recente" (timestamp no token ou tabela de step-up) |
| 4 | **Sessão roubada** não executa ação sensível | NAO_ENCONTRADO para export; PARCIAL para exclusão | Export: item 1. Exclusão: exige a senha, então uma sessão roubada isolada não exclui (`users/me/index.dart:334-339`) | idem item 2 | Fechar o export |
| 5 | Rate limit nas ações sensíveis | NAO_ENCONTRADO (confirmado; gravidade maior do que descrita) | `server/routes/users/_middleware.dart:4-6` não aplica nenhum limiter. `authRateLimit` cobre só os paths de `/auth` listados em `server/lib/rate_limit_middleware.dart:348-357`. Consequências concretas: (a) `DELETE /users/me` é oráculo de senha sem teto (item 2); (b) `GET /users/me/export` monta o dump completo da conta a cada chamada (`user_data_privacy_service.dart:23-370`, dezenas de consultas) sem teto — vetor de custo | Nenhum | Bucket próprio para export e exclusão; teste que faz N tentativas de senha errada em `DELETE /users/me` e afirma 429 |
| 6 | Rate limit **distribuído** (e confiável) | PARCIAL | `server/lib/distributed_rate_limiter.dart:16-72` existe e é correto (advisory lock por bucket+identidade, janela deslizante em `rate_limit_events`). Mas `server/lib/rate_limit_middleware.dart:251` só o ativa em produção, e o `catch (_)` de `:264-266` **provavelmente não faz o que o comentário e a medição anterior dizem** — ver achado transversal 1 corrigido: `:263` faz `return limiter.isAllowed(clientId)` **sem `await`** dentro do `try`; em Dart, o erro de um `Future` devolvido sem `await` não cai no `catch` do mesmo bloco (o próprio `server/lib` usa `return await` dentro de `try` em ~10 pontos por isso). Logo, falha assíncrona do Postgres na consulta de rate limit sobe pelo `await` de `:399` e chega ao middleware raiz como **500**, não como fallback em memória. O fallback em memória (`:428-445`) só é alcançado fora de produção (`:251`) ou se `context.read<Pool>()` lançar de forma síncrona (`:256`) | **Classe provada, ligação não:** `server/test/ai_postgres_atomicity_live_test.dart:120-138` dispara 6 `isAllowed` concorrentes com `maxRequests: 2` e afirma exatamente 2 permitidos e 2 linhas em `rate_limit_events` — prova a classe, live. `server/test/rate_limit_middleware_test.dart:224` afirma `rate_limit_backend == 'in_memory_fallback'` no caminho não-produção. **Nenhum teste** exercita `_isAllowedDistributedIfAvailable` em modo produção, nem com Pool que falha. Os scripts de E2E desligam o distribuído de propósito (`RATE_LIMIT_DISTRIBUTED=false` em `scripts/quality_gate_resolution_corpus.sh:1241`, consagrado por `test/mutating_e2e_entrypoint_guard_test.dart:145`) | Definir e testar o comportamento sob falha (hoje é indefinido: 500 provável, memória possível), ligar o distribuído fora de produção quando configurado, e um teste com Pool que lança em modo produção. Sem executar não posso cravar a semântica de `return` sem `await` neste ponto (SDK resolvido `pub 3.12.2`, language version `3.7`, `server/.dart_tool/package_config.json`); o que posso cravar é que **nenhum teste a exercita**. Nota da 2ª rodada: em produção o distribuído está **ligado por padrão** (`RATE_LIMIT_DISTRIBUTED` ausente = `true`, `rate_limit_middleware.dart:238-242`) — o problema é só o comportamento sob falha e a falta de prova, não a ausência |

### O que realmente falta

O buraco central é objetivo e vale repetir: **`GET /users/me/export` devolve a conta
inteira (decks, binder, notas, replays) com nada além de um bearer**, sem step-up, sem
email verificado e sem rate limit — enquanto `DELETE /users/me`, a operação
irreversível, já pede senha e confirmação. A metade fácil já foi feita; a difícil não
começou. **E a metade fácil tem um furo que a medição anterior não viu:** a
reverificação de senha da exclusão não tem teto de tentativas — com um bearer roubado,
`DELETE /users/me` é um oráculo de senha ilimitado. Trabalho concreto: definir e
implementar o step-up (novo `server/lib/` + middleware), aplicá-lo ao export e
endurecê-lo na exclusão, dar bucket próprio às duas em
`server/routes/users/_middleware.dart`, definir e testar o comportamento do distribuído
sob falha em `server/lib/rate_limit_middleware.dart:255-267`, e **reescrever
`server/test/privacy_account_live_test.dart:145-178`**, que hoje afirma 200 para export
com bearer simples. **O app entra obrigatoriamente (2ª rodada):** o export hoje é um
`GET /users/me/export` sem corpo (`app/lib/features/profile/account_privacy_service.dart:36`)
disparado da tela de perfil (`app/lib/features/profile/profile_screen.dart`, mesma tela que
já pede a confirmação da exclusão, `:158`, `:399-406`); qualquer step-up — senha ou token —
obriga o app a pedir e enviar algo. **~10 arquivos** (servidor: lib de step-up,
`users/_middleware.dart` ou um `users/me/_middleware.dart`, `export/index.dart`,
`users/me/index.dart`, `rate_limit_middleware.dart`, `auth_service.dart` se for token, o
live reescrito; app: `account_privacy_service.dart`, `profile_screen.dart`, 1 teste), **8
testes** (step-up export, step-up exclusão, frescor, 429 no export, 429 no oráculo de
senha, Pool que falha em modo produção; no app, serviço e widget).
**Exige decisão humana:** qual é o step-up — reverificação de senha por requisição
(sem migração), ou um token de step-up curto com tabela própria (com migração)? E qual
a janela de frescor. **Exige prova viva: sim** (2ª rodada: não é mais condicional) — a
tela de perfil muda, e o contrato de UI (`docs/MANALOOM_E2E_RELEASE_CONTRACT.md:180-182`)
exige `PASS_AUTOMATED`, `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED` para toda UI alterada.
Cuidado de sequência: BT-PRIV-001 transforma o export em job allowlisted; o step-up tem de
ser desenhado para servir ao job, ou será refeito.

**Dependência declarada:** `BT-AUTH-003`. Na prática **já está satisfeita** — a
invalidação de sessão de que AUTH-004 precisaria está pronta e provada
(`auth_service.dart:553-566` + `account_security_live_test.dart:141-142`). AUTH-004
pode andar hoje.
**Dependência não declarada:** a metade "rate limit distribuído" do aceite toca BT-SEC-001
só se "distribuído" for lido como "confiável sob falha" (2ª rodada: o limiter distribuído
já está ligado por padrão em produção; aplicá-lo a `/users/me` é trabalho desta tarefa, não
de SEC-001). **Sobreposição:** BT-PRIV-001 e BT-PRIV-002 declaram depender desta e mexem
nas mesmas duas rotas; o step-up, o allowlist de export e a orquestração de exclusão
são três tarefas sobre `server/routes/users/me/`.

---

## BT-AUTH-006 — Admissão controlada de contas

Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:263` (registry `source_line: 263`)
Aceite: *"Convite/allowlist server-side single-use, expirável e revogável; rate limit distribuído, idempotência e auditoria; negação ocorre antes de criar usuário ou enviar email; E2E cobre válido, inválido, expirado, replay e concorrência."*

Decomposição em 9 asserções.

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Existe convite/allowlist server-side | NAO_ENCONTRADO | `grep -i "invite\|invitation\|allowlist\|waitlist\|admission"` em `server/database_setup.sql`: **zero**. Em `server/bin/migrate.dart` (58 migrações): **zero**. Nenhuma rota. A única ocorrência de "allowlist" em `server/lib/auth_runtime_policy.dart:401` é comentário sobre CIDR de proxy confiável. (2ª rodada, busca ampliada: `convite`, `whitelist`, `waitlist`, `beta_access`, `access_code`, `signup_code`, `early_access`, `referral` = 0 em servidor e app; `admission` só aparece em `server/lib/battle/*`, admissão de deck. O valor `experimental_allowlist` existe no enum de capability, `server/lib/release_capability_policy.dart:65-69`, mas a validação força `allowed == (release_capability == 'on')`, `:320` — é rótulo sem mecanismo, não admite ninguém) | Nenhum | Tudo |
| 2 | Single-use | NAO_ENCONTRADO | — | Nenhum | Tudo |
| 3 | Expirável | NAO_ENCONTRADO | — | Nenhum | Tudo |
| 4 | Revogável | NAO_ENCONTRADO | — | Nenhum | Tudo |
| 5 | Rate limit distribuído no registro | **PRONTO_SEM_PROVA** (promovida de PARCIAL na 2ª rodada: em produção o registro **já passa** pelo limiter distribuído — o aceite pede "distribuído", não "à prova de falha"; o comportamento sob falha é escopo de BT-SEC-001) | `POST /auth/register` está no bucket `auth` (`server/lib/rate_limit_middleware.dart:350`), aplicado por `server/routes/auth/_middleware.dart:12`; em produção o caminho é `DistributedRateLimiter` por padrão (`:238-242`, `:251`, `:399-419`) | `server/test/rate_limit_middleware_test.dart:203-225` prova 5 e bloqueia o 6º — **com `limiterOverrideForTesting`** (`:205-207`), não com o limiter de produção, e no caminho não-produção (`:224` afirma `in_memory_fallback`) | "Distribuído" não é exercitado por teste nenhum em modo produção; comportamento sob falha do Postgres indefinido (ver AUTH-004 item 6 corrigido) |
| 6 | Idempotência | NAO_ENCONTRADO (mas há molde) | Nenhum `Idempotency-Key` em `server/routes/auth/register.dart` | Nenhum | O mecanismo para o registro; **o molde já existe** em três lugares: `server/routes/decks/[id]/battle-replays/[replayId]/annotations/index.dart:96-106,129-133` (header `idempotency-key` ou campo no corpo, conflito tipado), `server/routes/ai/battle/sessions/index.dart:105`, `server/routes/trades/[id]/messages.dart:311` e `conversations/[id]/messages.dart:316`; no schema, `UNIQUE (user_id, idempotency_key)` + constraint de formato em `server/database_setup.sql:741-748`. Reduz o esforço; não muda o estado |
| 7 | Auditoria | NAO_ENCONTRADO | Nenhuma tabela ou log de emissão/resgate/revogação de convite | Nenhum | Tudo |
| 8 | Negação **antes** de criar usuário ou enviar email | PARCIAL | A negação que existe hoje é o gate de capability: `server/routes/_middleware.dart:105-144` responde antes de conectar ao Postgres (`:146-161`) e antes do handler, com `account_registration` em `off`/`allowed: false` (`server/config/release_capabilities.json:10-15`, chave em `server/lib/release_capability_policy.dart:16` e `:386`) | `server/test/release_capability_policy_test.dart:188` mapeia `POST /auth/register → account_registration`; `:436` afirma `body['capability'] == 'account_registration'` | Isso é BT-SCP-001, não admissão. É um interruptor binário: ou ninguém se cadastra, ou todo mundo. Não há a camada intermediária que o aceite pede |
| 9 | E2E cobre válido, inválido, expirado, replay e concorrência | NAO_ENCONTRADO | — | Nenhum | Os 5 cenários |

### O que realmente falta

Tudo. Esta é a única tarefa do grupo com **zero linha de código**: não há tabela, não há
serviço, não há rota, não há teste. O que existe é um interruptor de capability que hoje
mantém o cadastro fechado (e por isso a beta não está vazando contas), mas ele não
distingue convidado de estranho. Trabalho concreto: 1 migração nova (tabela de convites
com hash do código, `expires_at`, `consumed_at`, `revoked_at`, emissor, auditoria —
o padrão de token opaco de `server/lib/auth_service.dart:701-708` já existe e serve de
molde); serviço em `server/lib/`; rota de resgate mais rota administrativa de emissão e
revogação (há `server/lib/admin_access_support.dart` para o controle de acesso); alteração
em `server/routes/auth/register.dart` para negar **antes** do `AuthService().register`
(`:87`) e antes do `EmailVerificationDeliveryService().deliver` (`:100`); `Idempotency-Key`
(molde em `annotations/index.dart:96-106`); atualização de
`server/config/release_capabilities.json` e do OpenAPI; **e o app**, que precisa mandar
o convite — `app/lib/features/auth/screens/register_screen.dart` e
`app/lib/features/auth/providers/auth_provider.dart:260-268` hoje só mandam
username/email/password/aceite legal. ~12 arquivos (9 de servidor + 2 de app + 1 teste de app), 7 testes (os 5 cenários do
aceite + o de auditoria + o do app enviando o convite). **Exige migração: sim.**
**Exige decisão humana: sim** — quem emite convites, quantos, por qual canal, se há lista
de espera, e o que acontece com o convite quando a beta abre. Isso é decisão de produto
e não pode ser inferida do código. **Exige prova viva: sim** (2ª rodada; a medição dizia
"não"): a tela de cadastro muda para receber o convite, e o contrato de UI
(`docs/MANALOOM_E2E_RELEASE_CONTRACT.md:180-182`) exige `PASS_AUTOMATED`, `PASS_RUNTIME` e
`PASS_VISUAL_REVIEWED` para toda UI alterada. **Trabalho que o aceite não nomeia mas a
admissão herda:** hoje o cadastro diz se o email ou o username já existem (`Email já está
em uso` / `Username já está em uso`, `server/lib/auth_service.dart:167,178`, devolvidos por
`register.dart:135-142`); ao abrir o registro para convidados, isso vira enumeração para
quem tiver um convite — amarrar o convite a um email resolve.

**Dependência declarada:** `BT-AUTH-001`, `BT-AUTH-002`, `BT-SCP-001`. `BT-SCP-001` está
`IN_PROGRESS_CONTAINED` mas o gate já funciona e é testado. `BT-AUTH-001` e `BT-AUTH-002`
são conveniência de contrato, não bloqueio técnico: **o schema e o serviço de convite
podem ser escritos hoje**; só a forma final dos códigos de negação depende de AUTH-001.
**Sobreposição:** nenhuma outra tarefa do grupo entrega isto. **Dependência não declarada
(2ª rodada):** BT-LEGAL-ACCEPT-001 mexe no mesmo fluxo e na mesma tela de cadastro
(`server/routes/auth/register.dart`, `app/lib/features/auth/screens/register_screen.dart`);
a ordem entre resgate do convite e aceite legal tem de ser decidida uma vez, e as duas
tarefas feitas em paralelo vão colidir.

---

## BT-LEGAL-ACCEPT-001 — Versionamento e reaceite de Termos e Privacidade

Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:264` (registry `source_line: 264`)
Aceite: *"Aceite registra versões exatas; versão nova bloqueia só o necessário; mensagens traduzidas e acionáveis."*

Decomposição em 7 asserções (a #7 foi acrescentada na 2ª rodada).

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | O aceite registra as **versões exatas** | PRONTO_E_PROVADO (PASS em 2026-07-21, receipt S1-09, arquivo **byte a byte idêntico** ao atual — SHA-256 `c344e77f…b454` em `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md:316`; não re-executado — ver aviso no topo) | Versões correntes em `server/lib/legal_policy.dart:1-2`; validação estrita (exige `legal_accepted == true` **e** as duas versões idênticas às correntes) em `:33-42`; gravação na mesma transação do usuário e do plano em `server/lib/auth_service.dart:181-206` (`terms_version`, `terms_accepted_at`, `privacy_version`, `privacy_accepted_at`, com `CASE WHEN ... IS NULL THEN NULL ELSE CURRENT_TIMESTAMP`) — confirmado | `server/test/legal_consent_live_test.dart:67-102`: consulta o banco direto e afirma que as 4 colunas ficaram com a versão exata e `DateTime` (`:92-97`), que aceite ausente dá 400 `legal_acceptance_required` **sem criar linha** (`:68-73`), que versão obsoleta é rejeitada com 400 **sem criar linha** (`:81-82` — afirma só o status, não o código), e que o plano free entrou na mesma transação (`:98-102`). Confere. `server/test/legal_consent_contract_test.dart:19-36` afirma que `database_setup.sql` e a migração `043` têm as 4 colunas e as constraints `chk_users_terms_acceptance_pair` / `chk_users_privacy_acceptance_pair`, e que o rollback é `manualOnly`; `:38-63` afirma a política pura (`isRequired` em produção, `parse` estrito). Confere. (2ª rodada: este teste de contrato não tem tag live, então roda no gate `full`, que varre `test/` inteiro excluindo só as tags live — `scripts/quality_gate.sh:65-92`.) **Pré-requisitos do live que ninguém declara no `skip:`:** `MANALOOM_REQUIRE_LEGAL_ACCEPTANCE=true` (senão `:68` falha, porque `parse` devolve `null` fora de produção — `legal_policy.dart:8-17,30`), `DB_NAME`/`DB_USER` (`:32-33`) e `account_registration` aberta | Nada — **para o caminho de registro**. Note que esse caminho está atrás de `account_registration: off`, então hoje ninguém o percorre |
| 2 | Versão nova **bloqueia** quem já tem conta (reaceite) | NAO_ENCONTRADO | `users.terms_version` / `privacy_version` só são lidos em: o INSERT de `auth_service.dart:181-206`, a migração `server/bin/migrate.dart`, e o inventário de colunas de `server/lib/health_readiness_support.dart:200-202`. **Nenhuma leitura em tempo de requisição.** Não há middleware, não há 403, não há rota de reaceite | Nenhum | Todo o mecanismo: comparar a versão gravada com a corrente e barrar |
| 3 | Bloqueia **só o necessário** (escopo do bloqueio) | NAO_ENCONTRADO | Não existe bloqueio, logo não existe escopo | Nenhum | Definir o que continua permitido durante a pendência (ler o próprio deck? exportar? só mutações?) — o padrão de `server/lib/verified_email_middleware.dart:12-18` (libera GET/HEAD/OPTIONS, barra mutação) é o molde mais próximo no repo |
| 4 | UX de `legal_acceptance_required` no app | NAO_ENCONTRADO (confirmado) | `grep "legal_acceptance_required"` em `app/lib`: **zero**. O app só manda as versões no registro (`app/lib/features/auth/providers/auth_provider.dart:260-268`, `app/lib/features/auth/screens/register_screen.dart:110-111`) e, em erro, **exibe o código cru** — correção da 2ª rodada: `auth_provider.dart:375-376` é o caminho das ações de segurança (troca de senha, revogação), não o do cadastro; o cadastro com erro passa por `FriendlyErrorMapper.fromApiResponse(..., authRegister)` (`auth_provider.dart:309-312`), que prefere `error` a `message` (`app/lib/core/utils/friendly_error_mapper.dart:266`) e devolve o texto quando ele não "parece técnico" (`:317-318`); `legal_acceptance_required` não casa nenhuma palavra de `_looksTechnical`, então o usuário leria **"legal_acceptance_required"** em vez de "Leia e aceite os Termos…". O caminho é latente hoje (cadastro OFF e a tela manda as versões correntes), mas é exatamente o que acontece quando o servidor sobe a versão e um app antigo tenta cadastrar (ver #7). Telas em `app/lib/features/auth/screens/`: login, register, forgot, reset, splash, verify_email — **não há tela de reaceite**. **Agravante:** o app também não trata o código-irmão `email_verification_required` (`grep verification_required app/lib`: 0) — o "molde" de estado-de-conta que existe no servidor (`verified_email_middleware.dart`) **não tem contraparte no app**; o `api_client.dart:104-114` só reconhece sinais de sessão inválida, por substring. O tratamento de código de estado-de-conta no app começa do zero | Nenhum | Tela/sheet de reaceite, tratamento do código no `api_client`/provider, e o caminho de volta ao fluxo interrompido |
| 5 | Mensagens **traduzidas** e acionáveis | PARCIAL | A mensagem existe, fixa em pt-BR, no servidor: `server/lib/legal_policy.dart:38-41` (`'Leia e aceite os Termos de uso e a Política de privacidade atuais.'`). Não há camada de i18n: `app/lib/l10n` **não existe** | Nenhum | Ou i18n de verdade, ou a decisão explícita de que pt-BR é a única língua da beta (2ª rodada: o app não tem nenhuma camada de i18n — nem `.arb`, nem `flutter_localizations` em `app/pubspec.yaml`, nem `supportedLocales` em `app/lib`; `docs/status/CURRENT_PRODUCT_DECISION.md` não fixa idioma). E "acionável" hoje é falso: a mensagem não traz link, nem a versão pendente, nem o que mudou — e, pelo #4, o app nem a mostra: mostra o código. Mantida em PARCIAL só porque a frase pt-BR existe no servidor |
| 6 | Contas antigas com versão NULL são tratadas | NAO_ENCONTRADO | As colunas são anuláveis por construção (o `CASE WHEN ... IS NULL` de `auth_service.dart:190-195` grava NULL quando o aceite é omitido, e `LegalAcceptancePolicy.isRequired` é falso fora de produção — `legal_policy.dart:8-17`). Todo usuário criado antes da `043`, ou em dev sem `MANALOOM_REQUIRE_LEGAL_ACCEPTANCE`, tem NULL | Nenhum | O reaceite tem de tratar NULL como "nunca aceitou", não como erro |
| 7 | **Fonte única** da versão vigente (o servidor diz qual é; o app não fixa) — sem isso, "versão nova" bloqueia mais do que o necessário | NAO_ENCONTRADO (asserção nova, 2ª rodada) | As versões estão **duplicadas**: `server/lib/legal_policy.dart:1-2` e `app/lib/features/commercial/legal_policy.dart:1-2` (hoje iguais, `2026-08-05` / `2026-07-21`). Nenhuma rota expõe a versão corrente (`grep currentTermsVersion` em `server/routes`: só `auth/register.dart` a importa para validar). O texto legal vive no bundle do app (`app/lib/features/commercial/screens/legal_screen.dart:227,245`). Consequência: subir a versão no servidor sem publicar o app ao mesmo tempo faz **todo** cadastro de app antigo falhar com 400 (`legal_policy.dart:33-41` exige igualdade exata), com o código cru na tela (#4) | Nenhum gate de paridade: os scripts leem só o arquivo do servidor (`scripts/lib/manaloom_safe_env.sh:57-92`); o único teste do app que usa a versão só confere que ela aparece na tela (`app/test/features/commercial/legal_account_cycle_test.dart:47`) | Expor versão (e, de preferência, URL do texto) pelo servidor — em `/capabilities` ou rota própria — e o app ler de lá; ou, no mínimo, um teste de paridade app↔servidor. Decidir onde mora o texto legal (bundle do app obriga release de loja no Android a cada versão) |

### O que realmente falta

**Status medido revisto na 2ª rodada: de "metade" para "mal-comecada".** A leitura "duas
metades, uma pronta" contava cláusulas, não trabalho: das três cláusulas do aceite só a
primeira está feita, das 7 asserções só 1 está pronta, e a entrega nomeia justamente o que
falta ("corrigir versionamento/**reaceite** … incluindo **UX** de `legal_acceptance_required`").
**Registrar** o aceite está completo e é a asserção mais bem provada de todo o grupo — um
teste live que abre conexão com o Postgres e confere as quatro colunas (PASS em 2026-07-21,
arquivo idêntico ao de hoje), mais um teste de contrato que confere o schema e as
constraints de par e roda no gate. **Reaceitar** não existe em lugar nenhum: nem no servidor
(nada lê `users.terms_version` em runtime), nem no app (o código `legal_acceptance_required`
não aparece em `app/lib`, não há tela, e o mapper mostraria o código cru). E a **versão
vigente** está duplicada entre app e servidor sem gate de paridade (#7). Trabalho
concreto: middleware de versão legal + rota `POST /auth/legal-acceptance` + expor o estado
em `/auth/me` (hoje `getUserFromToken`, `auth_service.dart:313-345`, nem seleciona
`terms_version`) + expor a versão vigente, no servidor; tratamento do código no
`api_client`/provider/`FriendlyErrorMapper`, tela de reaceite, rota de navegação e leitura da
versão pelo servidor, no app; definição do escopo do bloqueio; **~13 arquivos** (servidor:
middleware novo, rota nova, `auth/me.dart`, `auth_service.dart`, `routes/_middleware.dart` ou
o middleware de grupo, exposição da versão; app: `api_client.dart`, `auth_provider.dart`,
`friendly_error_mapper.dart`, `commercial/legal_policy.dart`, tela nova, roteamento; teste de
paridade) e **6 testes** (os 5 anteriores + paridade de versão). **Migração: só se** a decisão
for guardar histórico de consentimento — hoje o aceite é last-write-wins na própria linha de
`users`, o que basta para o aceite escrito no backlog mas costuma não bastar juridicamente.
**Exige decisão humana:** (a) o que o bloqueio impede e o que continua liberado;
(b) se é preciso histórico de aceites (jurídico → vira migração); (c) se a beta é
pt-BR-only; (d) onde mora o texto legal — no bundle do app (como hoje) cada versão nova
exige release de loja no Android, e o reaceite num app antigo mostraria o texto velho. **Exige prova viva: sim** — é tela nova, e pela régua visual do projeto ela
precisa da mesma qualidade do contador, não de um modal de formulário.

**Dependência declarada:** `BT-GOV-001`, que está `PASS` (receipt em
`docs/qa/execution/2026-08-14/BT-GOV-001.md`). A dependência é real e **já está satisfeita**:
pode começar hoje.
**Sobreposição:** a rota de reaceite e o step-up de BT-AUTH-004 querem o mesmo tipo de
middleware "estado da conta barra a requisição" que `verified_email_middleware.dart` já
implementa para email. Vale escrever um mecanismo e três políticas, não três mecanismos.
**Dependências não declaradas (2ª rodada):** (1) a parte "mensagens traduzidas" depende do
tratamento de códigos no app, que é o mesmo trabalho do lado app de BT-AUTH-001 (o
`FriendlyErrorMapper` mostra código cru); (2) BT-AUTH-006 mexe no mesmo fluxo e na mesma
tela de cadastro — ver a seção dela.

---

## Achados transversais do grupo

1. **O comportamento do rate limit distribuído sob falha é indefinido — e não é o
   "fail-open" que o código e a medição anterior dizem.** (Corrigido na verificação
   adversarial.) `server/lib/rate_limit_middleware.dart:255-267` tem `try { ...; return
   limiter.isAllowed(clientId); } catch (_) { return null; }` — o `return` de `:263` devolve
   o `Future` **sem `await`**. Em Dart, o erro de um `Future` devolvido de dentro de um
   `try` não passa pelo `catch` do mesmo bloco (é por isso que `server/lib` usa `return
   await` dentro de `try` em ~10 pontos). Logo: (a) falha **síncrona** (`context.read<Pool>()`
   sem provider, `:256`) → `null` → memória; (b) falha **assíncrona** do Postgres dentro de
   `isAllowed` (`distributed_rate_limiter.dart:16-72`, que não captura nada) → o erro sobe
   pelo `await` de `:399`, `authRateLimit` não captura, e o middleware raiz responde **500**
   (`routes/_middleware.dart:215-241`). Em produção o Pool está sempre provido para `/auth/*`,
   então o caso real é (b): com `rate_limit_events` indisponível, **toda tentativa de credencial em `/auth` (login inclusive; `GET /auth/me` não passa pelo limiter) devolve 500**
   — fechado por acidente, sem teste, e derrubando login. O único teste do caminho
   (`server/test/rate_limit_middleware_test.dart:224`, `in_memory_fallback`) roda fora de
   produção, onde o distribuído nem é tentado (`:251`). Não executei nada, então não cravo
   a semântica; cravo que **nenhum teste injeta um Pool que falha em modo produção**.
   **Correção de alcance (2ª rodada):** só **duas** tarefas pedem "rate limit distribuído"
   no aceite (AUTH-004 e AUTH-006); AUTH-003 pede "rate-limited" na entrega. E o
   distribuído está **ligado por padrão** em produção (`rate_limit_middleware.dart:238-242`),
   então lido ao pé da letra o aceite de AUTH-006 já é atendido no código (falta prova) e o
   de AUTH-004 só exige aplicar o limiter às duas rotas de `/users/me`. Só se o dono ler
   "distribuído" como "confiável sob falha" as tarefas passam a depender de BT-SEC-001 (P1)
   — e nem assim é automático, porque o aceite de SEC-001 fala de "mutações caras", não de
   `/auth`. Isso é uma decisão a explicitar, não um bloqueio técnico.

2. **O distribuído também está desligado fora de produção** (`rate_limit_middleware.dart:251`),
   e em dev o teto é 200/min com `anonymous` passando direto (`:155-158`, `:395-397`).
   Os próprios scripts de E2E o desligam de propósito (`RATE_LIMIT_DISTRIBUTED=false` em
   `scripts/quality_gate_resolution_corpus.sh:1241`, exigido por
   `server/test/mutating_e2e_entrypoint_guard_test.dart:145` e
   `resolution_corpus_preflight_source_test.dart:137`). Ou seja: nenhum ambiente onde se
   testa exercita o caminho que vai para produção — e há testes que **garantem** que
   continue assim. A classe em si tem prova live de concorrência
   (`server/test/ai_postgres_atomicity_live_test.dart:120-138`); a ligação pelo middleware
   em modo produção, não.

3. **`GET /users/me/export` é o buraco mais grave que eu encontrei neste grupo — e o
   `DELETE` ao lado tem um segundo.** `server/routes/users/me/export/index.dart` +
   `server/routes/users/_middleware.dart:4-6`: a conta inteira sai com um bearer, sem
   step-up, sem email verificado, sem rate limit — enquanto o `DELETE` ao lado já pede
   senha e confirmação. Os dois estão no plano de controle sempre aberto
   (`release_capability_policy.dart:611-612`), ou seja, alcançáveis **hoje** com a matriz
   toda OFF. E `server/test/privacy_account_live_test.dart:145-149` afirma 200 para o
   export com bearer simples: o teste **consagra** o buraco. (Adicionado na verificação:)
   `DELETE /users/me` pede a senha (`users/me/index.dart:334-339`,
   `user_data_privacy_service.dart:617-623`) **sem nenhum teto de tentativas** — nem
   `users/_middleware.dart` nem `authRateLimit` (só `/auth/*`, `rate_limit_middleware.dart:348-357`)
   o cobrem. Com um bearer roubado, é um oráculo de senha ilimitado, com bcrypt + `FOR UPDATE`
   a cada tentativa (2ª rodada: o acerto apaga a conta — o ganho do atacante é sabotagem e a
   senha em claro para reuso fora do BrewTact; as rotas irmãs que reverificam senha,
   `change-password` e `revoke-sessions`, estão no bucket de credenciais).

4. **Sete pontos devolvem o texto da exceção ao cliente**, dois deles em `/auth`
   (`server/routes/auth/login.dart:60`, `server/routes/auth/register.dart:138`), e como
   `ServerException extends PgException implements Exception`
   (`postgres-3.5.9/lib/src/exceptions.dart:64,86`), uma falha de banco no login vira
   corpo público com 400. Mais 17 chamadas passam `details: error`, que
   `server/lib/http_responses.dart:11-12` serializa no corpo. **Eixo ABERTO:** `POST
   /auth/login` (`toString`), `GET /users/me/plan` e `GET/POST /users/me/activation-events`
   (`details:`) e os três `/health/*` com `details:` estão no plano de controle
   (`release_capability_policy.dart:597-601,613,615-616`) — 7 dos 24 vazamentos estão no
   plano de controle. **Correção (2ª rodada):** os 3 de `/health/*` estão atrás de
   `operationalAdminMiddleware` (`server/routes/health/_middleware.dart:5-12`), só para
   operador; alcançáveis por usuário comum hoje são **4**, e o único anônimo é o login.

5. **O corpus de erro existe mas afirma pouco — menos ainda do que a medição anterior
   disse.** `server/test/error_contract_test.dart` tem 116 casos e 1703 linhas. Só 40
   chamadas afirmam `body['error'] is String` (`:116-122`); o helper de `:124-138` aceita
   `error` **ou** `message` ou corpo não-JSON; 2 chamadas afirmam só `message`
   (`:148-154`); os `expectOptional*` (`:156-186`) somam 58 chamadas, **49** com status
   **ambíguo** (`anyOf(400|401|405, 404)`) — contagem refeita na 2ª rodada. Como a negação de
   capability é **404** (`release_capability_policy.dart:186-192`), essas 49 passam pelo gate
   sem tocar a rota sempre que a capability estiver OFF. Zero leituras de `x-request-id`,
   zero `equals('<código>')` em `error`, zero busca de detalhe interno. Está no preset `live`
   (`dart_test.yaml:75`) e é o teste padrão do harness isolado
   (`scripts/manaloom_server_contract_e2e_isolated.sh:797`), mas não achei receipt dele em
   `docs/qa/`. É um corpus de forma, não de contrato —
   endurecê-lo é barato e fecha a maior parte de BT-AUTH-001 sem escrever teste novo do
   zero, mas "endurecer" significa reescrever 9 helpers e revisar 116 casos, não só um.

6. **O mecanismo "estado da conta barra a requisição" já existe uma vez e vai ser pedido
   mais duas.** `server/lib/verified_email_middleware.dart` faz exatamente isso para email
   verificado (libera leitura, barra mutação, código tipado). AUTH-004 (step-up) e
   LEGAL-ACCEPT-001 (reaceite) querem a mesma forma. Generalizar uma vez economiza as
   outras duas.

7. **O eixo triplo é visível no grupo.** BT-LEGAL-ACCEPT-001 está *implementada e provada*
   na metade "registrar" e *inexistente* na metade "reaceitar". BT-AUTH-006 está *fechada*
   (capability OFF) sem estar *implementada*. BT-AUTH-003 está *implementada e provada*
   (receipt de julho) mas a prova depende de `test_reset_token`, um gancho que só existe
   em development com frase de aprovação — o live, sozinho, não prova o shape de produção
   (2ª rodada: em produção o gancho é impossível por duas travas, ver AUTH-003 #2). E o
   plano de controle está *aberto* (login, recuperação, export, exclusão) com buracos que
   nenhuma capability fecha. Nenhum dos três estados implica o outro.

8. **Três tarefas declaram dependências que já estão satisfeitas** e poderiam começar hoje:
   AUTH-004 (depende de AUTH-003, cuja parte relevante está pronta e provada — e conferi
   que `authMiddleware` usa `getUserFromToken`, `auth_middleware.dart:42-43`, logo a
   invalidação por `auth_version` protege `/users/*`), LEGAL-ACCEPT-001 (depende de
   GOV-001, `PASS` no registry; o receipt `docs/qa/execution/2026-08-14/BT-GOV-001.md:3`
   diz `PASS_LOCAL · COMMITTED · NOT_PUSHED`), e AUTH-006 na parte de schema e serviço
   (o gate de SCP-001 já funciona: `release_capability_policy_test.dart:418-437`).

9. **(Adicionado na verificação) O app está acoplado às frases de erro do servidor.**
   `app/lib/core/api/api_client.dart:104-114` decide "sessão caiu" por substring
   (`'token'`, `'faça login novamente'`, `'authentication_required'`) em `error + message`.
   AUTH-001 (trocar frase por código) e qualquer tarefa que mexa nos 401 de
   `auth_middleware.dart:31,49` precisam tocar o app junto, ou o app deixa de limpar a
   sessão. Nenhuma das seis tarefas declara essa dependência. **Ampliado na 2ª rodada:** o
   acoplamento maior é o `FriendlyErrorMapper` (`app/lib/core/utils/friendly_error_mapper.dart:266,317-318`),
   que prefere `error` a `message` e devolve o texto cru quando não "parece técnico" — um
   código snake_case vai direto para a tela. Hoje isso já acontece, de forma latente, com
   `legal_acceptance_required` e os códigos de senha no cadastro. O app também é
   inconsistente: recuperação e verificação leem `message`
   (`app/lib/features/auth/account_security_service.dart:85-89`), cadastro lê `error` via
   mapper. Qualquer catálogo de códigos precisa de um catálogo espelho no app.

10. **(Reescrito na 2ª rodada — a versão anterior estava errada) Os três testes live que
    provam o grupo passaram, mas há dois meses.** Não estão em preset nem no gate `full`,
    mas rodam pelo harness isolado `scripts/manaloom_server_contract_e2e_isolated.sh`
    (recebe os caminhos como argumento, `:795-798`) e têm receipt de PASS em
    `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md` (S1-05, S1-08, S1-09).
    Dois dos três arquivos têm hoje o mesmo SHA-256 registrado no receipt; o terceiro difere
    só no prefixo do filename. O que falta é **re-rodar no HEAD**: o gate de capability
    (BT-SCP-001) passou a negar o registro por onde os três começam, então a re-execução
    precisa de capability isolada com `account_registration` ligado e de duas execuções
    (os testes de privacidade e de legal exigem valores opostos de
    `MANALOOM_REQUIRE_LEGAL_ACCEPTANCE`). No vocabulário do projeto, nenhuma capability
    deste grupo tem `live_verified_as_of` — e o plano de controle (login, recuperação,
    export, exclusão) nem é capability, então não tem esse campo.

11. **(Novo, 2ª rodada) O login é um oráculo de enumeração de contas, aberto hoje, que
    nenhuma tarefa cobre.** `AuthService.login` lança `Credenciais inválidas` **antes** do
    bcrypt quando o email não existe (`server/lib/auth_service.dart:282-283`) e só paga o
    bcrypt quando existe (`:294`). Status e corpo são iguais (401), o tempo não — a
    diferença é o custo de um bcrypt. `POST /auth/login` está no plano de controle
    (`release_capability_policy.dart:601`), alcançável com a matriz toda OFF, limitado só
    pelo bucket de 5/min por IP. Consequência para o plano: BT-AUTH-003 pode fechar com o
    aceite inteiro atendido e as contas continuarem enumeráveis. O conserto é pequeno (rodar
    `verifyPassword` contra um hash fixo quando o usuário não existe), mas precisa de dono:
    ou AUTH-003 absorve, ou vira tarefa nova. Quando o registro abrir (AUTH-006), soma-se
    `Email já está em uso` / `Username já está em uso` (`auth_service.dart:167,178`).

12. **(Novo, 2ª rodada) A versão legal vigente tem duas fontes de verdade e nenhum gate de
    paridade.** `server/lib/legal_policy.dart:1-2` e `app/lib/features/commercial/legal_policy.dart:1-2`
    repetem as mesmas datas; os scripts leem só o servidor (`scripts/lib/manaloom_safe_env.sh:57-92`);
    nenhum teste compara as duas. Subir a versão no servidor antes de o app novo estar na
    loja bloqueia **todo** cadastro vindo de app antigo, com o código cru na tela — o
    contrário de "bloqueia só o necessário". É parte de BT-LEGAL-ACCEPT-001 (asserção #7).

---

## Verificação adversarial — 1ª rodada

*(Mantida para rastreabilidade. Três afirmações desta rodada foram derrubadas pela 2ª
rodada, no fim do documento: "os testes live não têm receipt / ninguém roda" — têm, de
2026-07-21; "7 dos 24 vazamentos alcançáveis hoje" — 3 deles só para operador; e o
veredito "justo" — a 2ª rodada conclui "otimista demais" no status e no volume.)*

Revisão cética feita em 2026-09-22 sobre o mesmo HEAD `d15beb05b`, somente leitura,
sem executar teste nenhum. Método: abri **todos** os testes citados como prova (não confiei
nos nomes), abri todos os `arquivo:linha` de PRONTO_SEM_PROVA, recontei os volumes por
regex sobre `server/routes/**` e `server/lib/**`, e tentei derrubar a única tarefa marcada
"quase-la". 40 asserções reexaminadas (6 + 7 + 6 + 6 + 9 + 6).

### O que caiu

| Tarefa | Asserção | De → Para | Por quê |
| --- | --- | --- | --- |
| BT-AUTH-001 | #5 Stack trace nunca sai do middleware raiz | PRONTO_E_PROVADO → **PRONTO_SEM_PROVA** | `server/test/root_error_logging_contract_test.dart:6-13` afirma quatro strings **no fonte** (dois `print` ausentes, `type=${e.runtimeType}` e `captureObservedException(` presentes). Não afirma status, corpo nem header da **resposta**. A asserção é sobre o que sai para o cliente; o teste cobre o que vai para o log. O código (`routes/_middleware.dart:237-241`) está certo; a prova não existe |
| BT-AUTH-003 | #4 Rate-limited | PRONTO_E_PROVADO → **PRONTO_SEM_PROVA** | `server/test/rate_limit_middleware_test.dart:227-248` afirma só que `isAuthCredentialAttempt('/auth/forgot-password')` é `true` — classificação de path. Nenhum teste envia `POST /auth/forgot-password` e observa 429; os 429 observados (`:168-225`) são para login/register, com `limiterOverrideForTesting`, sem exercitar o limiter de produção nem a ligação em `routes/auth/_middleware.dart:12` |
| BT-AUTH-001 | #1 Existe um corpus de falhas | PRONTO_E_PROVADO (mantido) → **anotado como trivial** | A asserção é verdadeira (116 casos), mas 41 afirmam `error is String`, 6 aceitam `error` ou `message` ou não-JSON, ~66 aceitam status ambíguo (`anyOf(401, 404)`). Zero `x-request-id`, zero código exato. Contar isso como "provado" para AUTH-001 é contar a existência do papel, não o que está escrito nele. No eixo do aceite, AUTH-001 está em **0/3 provado** |
| BT-AUTH-001 | #2 onde "acerta" | correção factual | `server/lib/rate_limit_middleware.dart:103-121` foi citado como exemplo de código estável; é só o construtor do corpo — os chamadores passam `'Too Many Login Attempts'` (`:411`, `:433`), `'Too Many Requests'` (`:302`), `'Too Many AI Requests'` (`:527`, `:550`). Os 429 do grupo são frase |
| Transversal | #1 "distribuído é fail-open" | correção de caracterização | `rate_limit_middleware.dart:263` faz `return limiter.isAllowed(clientId)` sem `await` dentro do `try`; o `catch (_)` de `:264` só pega falha síncrona. Falha assíncrona do Postgres provavelmente sobe até o middleware raiz como **500** — fechado por acidente, sem teste, derrubando `/auth`. Não cravo a semântica sem executar; cravo que nenhum teste injeta Pool que falha em modo produção |
| Tabela-resumo | contagens | recontada | 5 das 6 linhas somavam errado (AUTH-002 `0/1/3/3` para 7 asserções, AUTH-003 `4/0/2/1` = 7 para 6, AUTH-004 contava #2 como PROVADO quando a tabela diz PARCIAL, AUTH-006 `0/0/2/6` = 8 para 9, LEGAL `1/0/2/3` com 1 PARCIAL na tabela). Corrigida |

### O que subiu (ou ficou menos ruim)

| Tarefa | Asserção | Mudança | Por quê |
| --- | --- | --- | --- |
| BT-AUTH-002 | #2 Existe limite por rota | PARCIAL (mantido) → **ganhou teste** | `server/test/battle_replay_annotation_routes_test.dart:45-66` chama a rota com `16 KiB + 1` e um `_ThrowingPool`, afirma 413, `error == 'battle_annotation_body_too_large'` e `pool.calls == 0`. A medição anterior dizia "nenhum teste de oversize". É molde bom para o teste global. Estado não muda: 5/136 rotas, todas atrás de capability OFF, e mede depois de `body()` |
| BT-AUTH-004 | #6 Distribuído existe e é correto | PARCIAL (mantido) → **classe provada live** | `server/test/ai_postgres_atomicity_live_test.dart:120-138`: 6 `isAllowed` concorrentes, `maxRequests: 2`, afirma exatamente 2 permitidos e 2 linhas em `rate_limit_events`. A classe é correta sob concorrência; o que não é provado é a ligação pelo middleware em produção e o comportamento sob falha |
| BT-AUTH-006 | #6 Idempotência | NAO_ENCONTRADO (mantido) → **há molde** | `annotations/index.dart:96-106,129-133`, `ai/battle/sessions/index.dart:105`, `trades/[id]/messages.dart:311`, `conversations/[id]/messages.dart:316`; `UNIQUE (user_id, idempotency_key)` em `database_setup.sql:741-748`. Reduz esforço, não muda estado |
| BT-AUTH-004 | dependência AUTH-003 | confirmada satisfeita | `authMiddleware` usa `getUserFromToken` (`auth_middleware.dart:42-43`), que checa `auth_version` (`auth_service.dart:337-339`) → a invalidação de sessão vale para `/users/*`, não só para `/auth/me` |

Nenhuma asserção subiu de estado. As três "promoções" são enriquecimento de PARCIAL/NAO_ENCONTRADO
com prova ou molde que a medição anterior não viu; nenhuma delas fecha nada.

### O que foi confirmado (PRONTO_E_PROVADO que resistiu)

- AUTH-003 #1 status (202 nos dois, `message` igual — `account_security_live_test.dart:98-104`),
  #5 invalidação (`:141-149`), #6 replay (`:135-140`, `:118-124`). Conferem linha a linha.
- LEGAL-ACCEPT-001 #1 registro (`legal_consent_live_test.dart:67-102` consulta o banco;
  `legal_consent_contract_test.dart:19-63`). Confere.
- AUTH-004 #2 mecanismo parcial da exclusão (`privacy_account_live_test.dart:185-200,237`). Confere.
- **Ressalva comum aos cinco:** os três testes live estão fora de todo preset de
  `server/dart_test.yaml`, sem receipt, e os três começam por um registro que a capability nega.
  *[Superado na 2ª rodada: há receipts de PASS de 2026-07-21 com o mesmo SHA-256 dos arquivos
  atuais; o que falta é re-rodar no HEAD.]*
  Mantive PRONTO_E_PROVADO porque o critério desta medição é "há teste que afirma", mas no
  vocabulário do projeto (`live_verified_as_of`) o grupo inteiro está em `null`.

### Achados novos (não estavam no documento)

1. **`DELETE /users/me` é um oráculo de senha ilimitado.** A reverificação de senha
   (`users/me/index.dart:334-339` → `user_data_privacy_service.dart:617-623`) não tem teto:
   `users/_middleware.dart` não aplica limiter e `authRateLimit` só cobre `/auth/*`. Com um
   bearer roubado, tentativas ilimitadas, cada uma com bcrypt + `FOR UPDATE`. Está no plano
   de controle aberto. AUTH-004 #5 sobe de "falta bucket" para "falta bucket **e** há um
   oráculo ativo".
2. **`privacy_account_live_test.dart:145-178` consagra o export sem step-up** (afirma 200
   com bearer simples e lê o conteúdo). Fechar AUTH-004 #1 obriga a reescrever o teste.
3. **O app decide logout por substring de frase** (`app/lib/core/api/api_client.dart:104-114`).
   AUTH-001 toca o app; nenhuma tarefa declara isso.
4. **O app não trata `email_verification_required`** (`grep` em `app/lib`: 0) — o "molde"
   de estado-de-conta do servidor não tem contraparte no cliente; a UX de
   `legal_acceptance_required` (LEGAL-ACCEPT-001 #4) começa do zero no app.
5. **Eixo ABERTO mapeado:** `POST /auth/login`, `GET /users/me/export`, `DELETE /users/me`,
   `GET /users/me/plan`, `/users/me/activation-events` e os três `/health/*` estão em
   `_exactControlPlaneRequests` (`release_capability_policy.dart:590-620`) — os vazamentos e
   os buracos de AUTH-001 #4 e AUTH-004 #1/#5 nesses paths são alcançáveis hoje, com a matriz
   toda OFF.
6. **Volumes recontados:** frase no campo `error` = 224 ocorrências em 64 arquivos de rota
   (+ 8 de lib), não 200/61; `print($e)` = 51 em 27 arquivos de rota + 13 em 5 de lib
   (a medição anterior citava só login/register); mais 28 `Log.e/w(... $e)`.

### Revisão de `arquivosATocar` / `testesAEscrever`

| Tarefa | Antes | Depois | Motivo |
| --- | --- | --- | --- |
| BT-AUTH-001 | ~66 / 5 | **~85 / 6** | 70 arquivos de rota (frase ou `print`), ~10 de lib, `http_responses.dart`, catálogo, OpenAPI, 2 testes de servidor, `api_client.dart` + teste no app; +1 teste de runtime do middleware raiz |
| BT-AUTH-002 | ~10 / 4 | ~10 / 4 | Mantido; o teste de annotations é molde |
| BT-AUTH-003 | 3 / 3 | **3 / 4 + preset e receipt** | +1 teste (429 real em forgot-password); o teste de timing precisa de transporte stub (em dev a entrega é omitida, `password_reset_delivery_service.dart:24-26`); incluir o live num preset e rodar |
| BT-AUTH-004 | ~6 / 5 | **~8 / 6** | + reescrita de `privacy_account_live_test.dart`, + tela do app se step-up interativo; +1 teste (429 no oráculo de senha) |
| BT-AUTH-006 | ~9 / 6 | **~11 / 6** | + `register_screen.dart` e `auth_provider.dart` no app (o convite tem de ser enviado) |
| BT-LEGAL-ACCEPT-001 | ~7 / 5 | **~10 / 5** | servidor: middleware, rota, `auth/me.dart`, `auth_service.dart` (`getUserFromToken` nem seleciona `terms_version`), middleware de grupo; app: `api_client.dart`, provider, tela, roteamento |

### Tentativa de derrubar "quase-la" (BT-AUTH-003)

Não caiu, mas ficou mais honesto. No eixo IMPLEMENTADO, 5/6 asserções existem (só timing
não) e o trabalho de código restante é pequeno (`unawaited` do `deliver`, asserção de
`body.keys`). No eixo PROVADO, são 3/6 (não 4/6), todas por um teste que nenhum gate roda e
que depende de `test_reset_token` — o mesmo campo que é o oráculo de enumeração fora de
produção. E o pilar "timing" do aceite não é um ajuste: é tirar um HTTP externo do caminho
da requisição e provar isso com um transporte stub. Mantenho "quase-la" **para o código**;
para a régua do projeto (receipt), está tão em `null` quanto as outras cinco.

### Veredito de otimismo

**Justo, com o eixo PROVADO um pouco inflado.** Os seis estados medidos (metade,
mal-comecada, quase-la, mal-comecada, nao-comecada, metade) resistiram. O que estava
otimista: duas asserções "provadas" por testes que afirmam menos do que a asserção
(AUTH-001 #5, AUTH-003 #4); o placar de AUTH-001 contando um corpus que não afirma o
aceite; o volume de AUTH-001 subestimado em ~30% e sem o app; a caracterização "fail-open"
do distribuído (provavelmente 500, não memória); e a tabela-resumo com soma errada em 5
linhas. O que estava pessimista: AUTH-002 #2 tem teste, o limiter distribuído tem prova
de classe, e a idempotência tem molde. Os achados novos (oráculo de senha em `DELETE
/users/me`, teste que consagra o export sem step-up, app acoplado a frases) pioram o
quadro de AUTH-004 e AUTH-001, mas não mudam a ordem: AUTH-006 é a única do zero,
AUTH-003 é a única perto, e nada do grupo tem receipt.
*[A frase final — "nada do grupo tem receipt" — foi derrubada na 2ª rodada.]*

---

## Verificação adversarial — 2ª rodada

Revisão cética em 2026-09-22 sobre o HEAD `d15beb05b` + working tree, somente leitura,
nada executado (nem `dart`, nem `flutter`, nem servidor). Escrevi só neste arquivo.
Método: reabri cada teste citado como prova e cada `arquivo:linha` marcado
PRONTO_SEM_PROVA; comparei o SHA-256 dos testes live com os hashes registrados nos
receipts; recontei os volumes com Python (a contagem por linha perde as strings
multilinha); li o harness isolado, o mapper de erros do app, o preflight de runtime, a
resolução de identidade do rate limit e o histórico (`git diff --stat 776b9e25d HEAD`).
**40 asserções reexaminadas** (6 + 7 + 6 + 6 + 9 + 6); uma dividida (AUTH-003 #5) e uma
acrescentada (LEGAL #7), total do grupo agora **42**.

### O que caiu

| Tarefa | Item | De → Para | Por quê |
| --- | --- | --- | --- |
| BT-AUTH-001 | status medido | metade → **mal-comecada** | O código estável cobre ~20% das ocorrências de erro (64 códigos contra 228 frases em rotas + 21 em lib); a lib tem **16** arquivos com frase, não 8 (a contagem por linha perdia as multilinhas); 0 de 3 exigências do aceite provadas; e o app mostra o texto cru de `error` (`friendly_error_mapper.dart:266,317-318`), então trocar frase por código muda telas |
| BT-AUTH-001 | arquivos a tocar | ~85 → **~110 servidor + ~12 app** | União por regex: 85 arquivos de rota (frase, `print`/`Log` de exceção, vazamento ou corpo só com `message`) + 21 de lib + `http_responses.dart`, catálogo, OpenAPI e testes; o app entra se o código substituir a frase |
| BT-AUTH-003 | #5 "sessões e tokens anteriores" | PRONTO_E_PROVADO → **5a PROVADO (sessões) + 5b PRONTO_SEM_PROVA (reset tokens irmãos)** | `account_security_live_test.dart` nunca volta a usar `firstResetToken` (`:105`) depois do novo pedido (`:114`); o consumo em `auth_service.dart:474-482` e `:567-574` não é afirmado. A regra desta verificação é: teste que afirma menos que a asserção não prova |
| BT-AUTH-004 | prova viva | condicional → **sim** | Todo step-up obriga o export do app (`app/lib/features/profile/account_privacy_service.dart:36`, disparado de `profile_screen.dart`) a pedir e enviar algo; o contrato de UI (`docs/MANALOOM_E2E_RELEASE_CONTRACT.md:180-182`) exige as três evidências |
| BT-AUTH-004 | arquivos / testes | ~8 / 6 → **~10 / 8** | + `account_privacy_service.dart`, `profile_screen.dart` e 2 testes no app |
| BT-AUTH-006 | prova viva | não → **sim** | A tela de cadastro muda para receber o convite (a própria seção já listava `register_screen.dart`) |
| BT-AUTH-006 | arquivos / testes | ~11 / 6 → **~12 / 7** | + teste do app enviando o convite |
| BT-LEGAL-ACCEPT-001 | status medido | metade → **mal-comecada** | 1 de 3 cláusulas do aceite, 1 de 7 asserções; a entrega nomeia exatamente o que falta (reaceite + UX) |
| BT-LEGAL-ACCEPT-001 | #4 (descrição) | "o app exibe cru o `message`" → **"o app exibe cru o código"** | O cadastro com erro passa pelo `FriendlyErrorMapper` (`auth_provider.dart:309-312`), que prefere `error`; o usuário leria `legal_acceptance_required`. `auth_provider.dart:375-376` é o caminho de outra ação |
| BT-LEGAL-ACCEPT-001 | #7 (nova) | — → **NAO_ENCONTRADO** | Versão vigente duplicada em `server/lib/legal_policy.dart:1-2` e `app/lib/features/commercial/legal_policy.dart:1-2`, sem rota que a exponha e sem teste de paridade; subir a versão sem release simultâneo bloqueia todo cadastro de app antigo |
| BT-LEGAL-ACCEPT-001 | arquivos / testes | ~10 / 5 → **~13 / 6** | + exposição da versão, `friendly_error_mapper.dart`, `commercial/legal_policy.dart`, teste de paridade |
| BT-AUTH-002 | escopo | ~10 → **~10 a ~45** | Os ~10 cobrem o aceite; a entrega ("limites por campo/URL") lida para a API inteira soma ~36 rotas que leem corpo sem teto de campo (55 leem corpo, 19 têm algum teto) |

### O que subiu

| Tarefa | Item | De → Para | Por quê |
| --- | --- | --- | --- |
| Grupo | evidência do eixo PROVADO | "teste que ninguém roda" (1ª rodada) → **"PASS em 2026-07-21 com o mesmo arquivo; não re-executado"** | Receipts S1-05, S1-08 e S1-09 em `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md` (fora de `docs/qa/execution/`). SHA-256 atual = receipt para `account_security_live_test.dart` (`57e109cf…2218`, `:286`) e `legal_consent_live_test.dart` (`c344e77f…b454`, `:316`); o de privacidade mudou só o prefixo do filename. Runner: `scripts/manaloom_server_contract_e2e_isolated.sh:795-798` |
| BT-AUTH-003 | #2 shape | PARCIAL → **PRONTO_SEM_PROVA** | Em produção a diferença é impossível: o guarda devolve `false` com `ENVIRONMENT=production` (testado no gate, `account_security_schema_contract_test.dart:40-64`), o preflight recusa subir com a variável (`auth_runtime_policy.dart:94-97`) e o servidor só aceita `development` ou `production` (`:41-45`, chamado em `server/main.dart:10-12`) — o "oráculo de staging" não tem onde existir |
| BT-AUTH-006 | #5 distribuído no registro | PARCIAL → **PRONTO_SEM_PROVA** | Em produção o registro já passa pelo `DistributedRateLimiter` por padrão (`rate_limit_middleware.dart:238-242`, `:251`, `:399-419`). O aceite pede "distribuído", não "à prova de falha"; falta prova, e a semântica sob falha é assunto de SEC-001 |
| BT-AUTH-001 | #4 alcance do vazamento | "7 alcançáveis hoje" → **4 por usuário comum + 3 só operador** | `/health/ai-history`, `/commercial` e `/dashboard` estão atrás de `operationalAdminMiddleware` (`server/routes/health/_middleware.dart:5-12`; públicos só `/health`, `/live`, `/ready` — `admin_access_support.dart:14-22`) |
| BT-AUTH-001 | #3 request-id | "nenhum teste lê o header" → **um lê, para uma rota** | `server/test/ai_provider_failure_injection_live_test.dart:83-90` afirma o eco no 503 de `/ai/generate`. Estado mantido (PRONTO_SEM_PROVA): "toda resposta" continua sem prova |
| BT-AUTH-002 | #5 gzip | risco menor | Nada descomprime corpo de requisição no servidor; a "bomba" não expande e o caso colapsa no de oversize. Estado mantido; custo cai para recusar `Content-Encoding` |
| Transversal 1 | alcance da dependência de SEC-001 | "3 tarefas não fecham sem SEC-001" → **decisão a explicitar** | Só AUTH-004 e AUTH-006 pedem "distribuído" no aceite, e ele já está ligado em produção; SEC-001 só entra se "distribuído" for lido como "confiável sob falha" (e o aceite de SEC-001 fala de "mutações caras", não de `/auth`) |

### O que resistiu (todo PRONTO_E_PROVADO foi reaberto)

- **AUTH-003 #1** — `account_security_live_test.dart:98-104`: 202 nos dois pedidos e `message`
  igual. Confere; receipt S1-08.
- **AUTH-003 #5a** — `:141-149`: `tokenA` e `tokenB` viram 401, senha antiga não loga. Confere.
- **AUTH-003 #6** — `:135-140` (reuso → 400 `reset_token_invalid`) e `:118-124` (expirado →
  idem). Confere; receipt S1-08 cita "token expirado ou reutilizado é rejeitado" (`:257-258`).
- **LEGAL #1** — `legal_consent_live_test.dart:67-102` consulta o Postgres e confere as 4
  colunas e a transação do plano; `legal_consent_contract_test.dart:19-63` roda no gate.
  Confere; receipt S1-09 com o mesmo arquivo.
- **AUTH-001 #1** (trivial) — o corpus existe e é o teste padrão do harness, mas, por aceitar
  404 em 49 chamadas, prova o gate de capability mais do que as rotas.

Todos os PRONTO_SEM_PROVA foram reabertos: AUTH-001 #3 e #5 (código confere; caminhos
precoces e `catch` sem teste), AUTH-003 #4 (identidade do cliente robusta em
`auth_runtime_policy.dart:190-297`; falta só o teste de junção). Nenhum caiu para PARCIAL.

### Achados novos desta rodada

1. **Login enumera contas por tempo, aberto hoje** (transversal 11): `auth_service.dart:282-283`
   lança antes do bcrypt de `:294`. Fechar AUTH-003 não resolve; nenhuma tarefa cobre.
2. **O app mostra código de erro cru** (`friendly_error_mapper.dart:266,317-318`): afeta a UX
   de LEGAL (#4), o tamanho de AUTH-001 e a escolha "código substitui ou acompanha a frase".
3. **Versão legal com duas fontes de verdade** (transversal 12, LEGAL #7).
4. **Os testes live de privacidade e de legal não passam no mesmo runtime**:
   `privacy_account_live_test.dart:35-43` registra sem aceite (exige
   `MANALOOM_REQUIRE_LEGAL_ACCEPTANCE=false`), `legal_consent_live_test.dart:67-73` exige `true`
   — re-provar o grupo custa duas execuções do harness, com a corrida conhecida entre execuções
   seguidas (`PONTO_DE_RETOMADA.md:40-43`).
5. **O corpus de erro passa pelo gate sem tocar a rota** sempre que a capability está OFF
   (negação = 404, e 49 chamadas aceitam 404).
6. **Cada pedido de recuperação mata o link anterior** (`auth_service.dart:474-482`) e o bucket é
   por IP: com vários IPs, um atacante mantém o link da vítima sempre inválido — argumento
   concreto para o bucket por email de AUTH-003.
7. **`PATCH /users/me` já tem limites de campo** (`users/me/index.dart:115,146,181,198`) e o
   cadastro não tem teto nem formato para `email` (`register.dart:49-54`) — enriquece AUTH-002 #6.
8. **Cópia desatualizada desta medição dentro do repo**, não rastreada:
   `docs/flows/_p0/auth-conta.md` (2026-09-21, HEAD `9a9ba66de`, tabela anterior às duas
   verificações). Quem abrir aquela versão vai planejar com os números otimistas.

### Revisão de `arquivosATocar` / `testesAEscrever`

| Tarefa | 1ª rodada | 2ª rodada | Motivo |
| --- | --- | --- | --- |
| BT-AUTH-001 | ~85 / 6 | **~110 servidor + ~12 app / 7** | União real de arquivos; lib 16, não 8; app (mapper, `api_client`, leitores diretos) se o código substituir a frase; +1 teste do mapper |
| BT-AUTH-002 | ~10 / 4 | ~10 / 4 (até ~45 arquivos com a leitura ampla da entrega) | Escopo de "limites por campo" a decidir |
| BT-AUTH-003 | 3 / 4 + preset | **3 / 4 (+1 com bucket por email) + 2 execuções do harness** | O teste de reset token irmão entra no lugar de parte do antigo; re-prova precisa de capability isolada e duas execuções |
| BT-AUTH-004 | ~8 / 6 | **~10 / 8** | App obrigatório |
| BT-AUTH-006 | ~11 / 6 | **~12 / 7** | Teste do app |
| BT-LEGAL-ACCEPT-001 | ~10 / 5 | **~13 / 6** | Fonte única da versão + mapper + paridade |

### Tentativa de derrubar "quase-la" (BT-AUTH-003)

**Não caiu.** Implementado 6/7 (só timing falta). Provado 3/7, por um receipt de julho com
o arquivo de teste idêntico e o código de recuperação sem mudança desde então — é a prova
mais sólida do grupo, não a mais fraca como a 1ª rodada sugeriu. O que resta é concreto e
pequeno, com uma exceção: **timing** exige tirar a entrega de email do caminho da requisição
e provar com transporte stub, mais um número de "aceitável" que só o dono pode dar. As
outras pendências cabem em testes curtos (chaves da resposta, 429, token irmão) e na
re-execução do harness. **A ressalva que muda o plano:** fechar AUTH-003 cumpre o aceite mas
não entrega "recuperação não enumerável" como objetivo, porque o login enumera por tempo
hoje (achado 1). Se o objetivo for "contas não enumeráveis", falta uma tarefa.

### Números finais do grupo (42 asserções)

| Estado | Quantidade | Onde |
| --- | --- | --- |
| PRONTO_E_PROVADO | 5 | AUTH-001 #1 (trivial); AUTH-003 #1, #5a, #6; LEGAL #1 — todos por teste que passou em julho ou pelo corpus, nenhum no HEAD |
| PRONTO_SEM_PROVA | 6 | AUTH-001 #3, #5; AUTH-003 #2, #4, #5b; AUTH-006 #5 |
| PARCIAL | 12 | AUTH-001 3; AUTH-002 3; AUTH-004 4; AUTH-006 1; LEGAL 1 |
| NAO_ENCONTRADO | 19 | AUTH-002 4; AUTH-003 1; AUTH-004 2; AUTH-006 7; LEGAL 5 |

Eixo triplo: **implementado por inteiro** 11/42 (26%), mais 12 parciais; **provado** 5/42
(12%), e nenhum no HEAD; **aberto** — o plano de controle está no ar com três buracos que
nenhuma capability fecha: export sem step-up, `DELETE /users/me` sem teto de tentativas e
login que vaza exceção e enumera por tempo.

### Veredito de otimismo

**Otimista demais — moderadamente, e em direções diferentes nos dois eixos.** A ordem do
grupo resiste: AUTH-006 é a única do zero, AUTH-003 é a única perto. O que estava otimista:
dois status um degrau acima (AUTH-001 e LEGAL-ACCEPT-001 não estão na "metade"); o volume
de AUTH-001 ~30% abaixo e sem o app; AUTH-004, AUTH-006 e LEGAL sem o trabalho de app e
sem a prova viva de UI que o contrato do projeto exige; um PROVADO que afirmava mais do que
o teste (AUTH-003 #5); uma asserção inteira faltando (LEGAL #7); e a omissão do oráculo de
enumeração do login. O que estava pessimista, quase tudo vindo da 1ª rodada: "ninguém roda
os testes" (há receipts de PASS com os mesmos arquivos); AUTH-003 #2 e AUTH-006 #5 como
PARCIAL; os três vazamentos de `/health/*` contados como públicos; e SEC-001 tratado como
bloqueio técnico de três tarefas. Para planejar: **há mais trabalho do que a medição dizia,
principalmente no app e na prova de UI, mas a prova que já existe é melhor do que a 1ª
rodada dizia e custa pouco para renovar.**
