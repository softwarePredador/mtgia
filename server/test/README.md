# Server Test Suite - MTGIA

> Guia ativo de testes do backend.
> A ordem de leitura e prioridade funcional dessas suites deve seguir `docs/CONTEXTO_PRODUTO_ATUAL.md` e `docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md`.

Este diretorio concentra a malha principal de confiabilidade do produto, com foco especial no carro chefe:

- gerar deck
- criar deck
- analisar deck
- otimizar deck
- validar o resultado final

Em `2026-03-23`, a auditoria do core confirmou que a cobertura relevante de otimizacao esta forte, mas distribuida em tres camadas diferentes. A leitura correta dos testes depende dessa separacao.

## Modelo de validacao - atualizado em 2026-04-29

A suite agora esta separada por `dart_test.yaml`:

- `dart test` carrega somente testes unit/offline listados em `paths`.
- `dart test -P live` carrega somente testes HTTP marcados com `@Tags(['live', ...])`.
- testes live nao foram removidos, nao tiveram asserts enfraquecidos e nao dependem mais de `RUN_INTEGRATION_TESTS=1` para rodar quando chamados explicitamente.

Tags usadas:

| Tag | Significado |
| --- | --- |
| `live` | Teste opt-in fora da suite offline padrao. |
| `live_backend` | Exige backend HTTP vivo em `TEST_API_BASE_URL`. |
| `live_db_write` | Escreve via API/banco de teste, normalmente criando usuarios/decks. |
| `live_external` | Pode acionar IA/servico externo pelo backend, principalmente OpenAI. |

## Comandos recomendados

### Unit/offline green

```bash
cd server
dart test
```

Esse comando nao exige backend HTTP, banco externo ativo via API, OpenAI ou Scryfall. Em 2026-04-29 passou com `554` testes.

### Live-backend explicito

Pre-requisitos:

- backend vivo e saudavel;
- banco configurado no ambiente do backend;
- `TEST_API_BASE_URL` apontando para o backend alvo.

```bash
cd server
PORT=8082 dart run .dart_frog/server.dart
TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live
```

Comando equivalente usando selector por tag e arquivos explicitos:

```bash
TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -t live \
  test/ai_archetypes_flow_test.dart \
  test/ai_generate_create_optimize_flow_test.dart \
  test/ai_optimize_flow_test.dart \
  test/ai_optimize_telemetry_contract_test.dart \
  test/auth_flow_integration_test.dart \
  test/commander_reference_atraxa_test.dart \
  test/core_flow_smoke_test.dart \
  test/deck_analysis_contract_test.dart \
  test/decks_crud_test.dart \
  test/decks_incremental_add_test.dart \
  test/error_contract_test.dart \
  test/import_to_deck_flow_test.dart
```

Em 2026-04-29, contra `http://127.0.0.1:8082`, passou com `162` testes e `3` skips declarados.

### Variaveis de ambiente relevantes

| Variavel | Uso |
| --- | --- |
| `TEST_API_BASE_URL` | Base HTTP usada pelos testes live. Fallback local: `http://127.0.0.1:8082`. |
| `RUN_INTEGRATION_TESTS` | Legado. Nao e mais necessario para rodar live; `RUN_INTEGRATION_TESTS=0` desativa testes live quando um arquivo for invocado manualmente. |
| `OPENAI_API_KEY` | Usada pelo backend para rotas de IA. Em dev/staging, algumas rotas degradam para fallback; `ai_generate_create_optimize_flow_test.dart` marca skip explicito se a unica falha for credencial OpenAI invalida. |
| `DATABASE_URL` | Usada pelo backend live, nao pelo runner offline. Necessaria para testes live que criam usuarios/decks. |
| `JWT_SECRET` | Usada pelo backend live para auth/JWT. |
| `TEST_USER_EMAIL`, `TEST_USER_PASSWORD`, `TEST_USER_USERNAME` | Overrides opcionais em alguns testes live de IA. |
| `SOURCE_DECK_ID` | Override opcional para regressao live de optimize em `ai_optimize_flow_test.dart`. |
| `SENTRY_AUTH_TOKEN` | Nao e requerido por esta suite; relevante apenas para tooling de release/upload Sentry fora destes testes. |

## Inventario 2026-04-29

| Teste | Categoria | Backend HTTP | Escrita DB/API | Rede externa | `TEST_API_BASE_URL`/localhost |
| --- | --- | --- | --- | --- | --- |
| `ai_archetypes_flow_test.dart` | live-backend | Sim | Sim | Nao direto | Usa `TEST_API_BASE_URL`, fallback `127.0.0.1:8082` |
| `ai_generate_create_optimize_flow_test.dart` | live-backend/live-external | Sim | Sim | OpenAI via backend/fallback | Usa `TEST_API_BASE_URL`, fallback `127.0.0.1:8082` |
| `ai_optimize_flow_test.dart` | live-backend/live-external | Sim | Sim | OpenAI via backend/fallback | Usa `TEST_API_BASE_URL`, fallback `127.0.0.1:8082` |
| `ai_optimize_telemetry_contract_test.dart` | live-backend | Sim | Sim | Nao direto | Usa `TEST_API_BASE_URL`, fallback `127.0.0.1:8082` |
| `auth_flow_integration_test.dart` | live-backend | Sim | Sim | Nao | Usa `TEST_API_BASE_URL`, fallback `127.0.0.1:8082` |
| `commander_reference_atraxa_test.dart` | live-backend | Sim | Sim | Nao direto; depende de dados/cache do backend | Usa `TEST_API_BASE_URL`, fallback `127.0.0.1:8082` |
| `core_flow_smoke_test.dart` | live-backend/live-external | Sim | Sim | OpenAI via `/ai/optimize`/fallback | Usa `TEST_API_BASE_URL`, fallback `127.0.0.1:8082` |
| `deck_analysis_contract_test.dart` | live-backend | Sim | Sim | Nao | Usa `TEST_API_BASE_URL`, fallback `127.0.0.1:8082` |
| `decks_crud_test.dart` | live-backend | Sim | Sim | Nao | Usa `TEST_API_BASE_URL`, fallback `127.0.0.1:8082` |
| `decks_incremental_add_test.dart` | live-backend | Sim | Sim | Nao | Usa `TEST_API_BASE_URL`, fallback `127.0.0.1:8082` |
| `error_contract_test.dart` | live-backend | Sim | Sim | Nao | Usa `TEST_API_BASE_URL`, fallback `127.0.0.1:8082` |
| `import_to_deck_flow_test.dart` | live-backend | Sim | Sim | Nao | Usa `TEST_API_BASE_URL`, fallback `127.0.0.1:8082` |
| `auth_service_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `card_resolution_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `cards_route_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `color_identity_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `commander_only_runtime_validation_config_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `deck_validation_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `external_commander_deck_expansion_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `external_commander_meta_candidate_support_test.dart` | unit/offline local-file | Nao | Nao | Nao | Nao |
| `external_commander_meta_import_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `external_commander_meta_operational_runner_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `external_commander_meta_promotion_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `external_commander_meta_staging_support_test.dart` | unit/offline local-file | Nao | Nao | Nao | Nao |
| `generated_deck_validation_service_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `goldfish_simulator_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `health_readiness_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `import_list_service_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `import_parser_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `market_movers_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `meta_deck_analytics_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `meta_deck_card_list_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `meta_deck_commander_shell_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `meta_deck_format_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `meta_deck_reference_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `ml_analyzer_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `mtg_data_integrity_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `mtg_rules_validation_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `mtgtop8_meta_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `observability_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `openai_runtime_config_test.dart` | unit/offline config | Nao | Nao | Nao | Nao |
| `optimization_final_validation_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `optimization_goal_validation_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `optimization_pipeline_integration_test.dart` | integracao interna/offline | Nao | Nao | Nao | Nao |
| `optimization_quality_gate_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `optimization_rules_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `optimization_validator_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `optimize_complete_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `optimize_learning_pipeline_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `optimize_payload_parser_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `optimize_runtime_support_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `rate_limit_middleware_test.dart` | unit/offline | Nao | Nao | Nao | Contem `localhost:8080` apenas como valor de header `Host` |
| `request_trace_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `sets_route_test.dart` | unit/offline | Nao | Nao | Nao | Nao |
| `sync_cards_test.dart` | unit/offline | Nao | Nao | Nao | Apenas valida utilitarios/URLs Scryfall-like, sem chamada externa |

## Suites mais importantes para release do core

Se precisarmos de uma leitura rapida da saude da otimizacao, estas sao as baterias mais importantes:

1. `optimization_rules_test.dart`
2. `optimization_quality_gate_test.dart`
3. `optimization_final_validation_test.dart`
4. `optimization_validator_test.dart`
5. `optimization_goal_validation_test.dart`
6. `goldfish_simulator_test.dart`
7. `optimization_pipeline_integration_test.dart`
8. `TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live`

### Gate recorrente do corpus de resolucao

Para validar o corpus estavel Commander fim a fim:

```bash
./scripts/quality_gate_resolution_corpus.sh
```

Ou:

```bash
./scripts/quality_gate.sh resolution
```

Esse gate:

- sobe a API local se necessario
- usa `test/fixtures/optimization_resolution_corpus.json` por padrao
- calcula `VALIDATION_LIMIT` automaticamente pelo tamanho do corpus
- executa `bin/run_three_commander_resolution_validation.dart`
- falha se houver `failed`, `unresolved` ou `total` inconsistente

### Runner operacional local da otimizacao

Para Windows/local, o projeto agora tem bootstrap dedicado para evitar problema de `dart_frog dev` em modo nao interativo:

- `bin/local_test_server.dart`
- `start_local_test_server.ps1`
- `stop_local_test_server.ps1`
- `run_optimize_validation.ps1`

Fluxo recomendado:

```powershell
.\run_optimize_validation.ps1
```

Esse runner:

- sobe o backend local em IPv4
- valida readiness em `127.0.0.1:8080/health/live`
- roda a bateria deterministica principal
- roda `ai_optimize_flow_test.dart`
- roda `ai_generate_create_optimize_flow_test.dart`
- encerra o servidor ao final

## Resultado da auditoria de 2026-03-23

Validado nesta rodada:

- toda a bateria deterministica relevante da otimizacao
- a suite `optimization_pipeline_integration_test.dart`
- os contratos Flutter que consomem optimize e rebuild

Status observado:

- backend logico: verde
- pipeline simulada: verde
- suites HTTP protegidas por ambiente: skip controlado sem falso negativo

Leitura operacional:

- a logica principal da otimizacao esta bem coberta
- o projeto tem protecao real contra regressao em legalidade, consistencia e role preservation
- a parte que ainda depende de homologacao de ambiente e a jornada HTTP real completa

## Suites mais importantes para release do core

Se precisarmos de uma leitura rapida da saude da otimizacao, estas sao as baterias mais importantes:

1. `optimization_rules_test.dart`
2. `optimization_quality_gate_test.dart`
3. `optimization_final_validation_test.dart`
4. `optimization_validator_test.dart`
5. `optimization_goal_validation_test.dart`
6. `goldfish_simulator_test.dart`
7. `optimization_pipeline_integration_test.dart`
8. `ai_optimize_flow_test.dart` com `RUN_INTEGRATION_TESTS=1`

## Comandos recomendados

### Validacao local rapida do core de otimizacao

```bash
dart test test/optimization_rules_test.dart \
  test/optimization_quality_gate_test.dart \
  test/optimization_final_validation_test.dart \
  test/optimization_goal_validation_test.dart \
  test/optimization_validator_test.dart \
  test/goldfish_simulator_test.dart \
  test/generated_deck_validation_service_test.dart \
  test/optimize_learning_pipeline_test.dart \
  test/optimize_payload_parser_test.dart \
  test/optimization_pipeline_integration_test.dart
```

### Validacao HTTP real do core

Pre requisitos:

- servidor em `localhost:8080`
- banco configurado
- autenticacao operacional

```bash
RUN_INTEGRATION_TESTS=1 dart test test/ai_optimize_flow_test.dart \
  test/ai_generate_create_optimize_flow_test.dart \
  test/ai_optimize_telemetry_contract_test.dart \
  test/deck_analysis_contract_test.dart
```

### Gate recorrente do corpus de resolucao

Para validar o corpus estavel Commander fim a fim:

```bash
./scripts/quality_gate_resolution_corpus.sh
```

Ou:

```bash
./scripts/quality_gate.sh resolution
```

Esse gate:

- sobe a API local se necessario
- usa `test/fixtures/optimization_resolution_corpus.json` por padrao
- calcula `VALIDATION_LIMIT` automaticamente pelo tamanho do corpus
- executa `bin/run_three_commander_resolution_validation.dart`
- falha se houver `failed`, `unresolved` ou `total` inconsistente

### Runner operacional local da otimizacao

Para Windows/local, o projeto agora tem bootstrap dedicado para evitar problema de `dart_frog dev` em modo nao interativo:

- `bin/local_test_server.dart`
- `start_local_test_server.ps1`
- `stop_local_test_server.ps1`
- `run_optimize_validation.ps1`

Fluxo recomendado:

```powershell
.\run_optimize_validation.ps1
```

Esse runner:

- sobe o backend local em IPv4
- valida readiness em `127.0.0.1:8080/health/live`
- roda a bateria deterministica principal
- roda `ai_optimize_flow_test.dart`
- roda `ai_generate_create_optimize_flow_test.dart`
- encerra o servidor ao final

### Validacao total do servidor

```bash
dart test
```

## Corpus de resolucao Commander

Fixtures operacionais:

- `test/fixtures/optimization_resolution_corpus.json`: corpus estavel principal com `19` decks Commander validados
- `test/fixtures/optimization_resolution_corpus_new_commanders_2026-03-23.json`: suite focada usada para estabilizar os `6` novos comandantes da rodada

Regras novas confirmadas em `2026-03-23`:

- `bootstrap_resolution_corpus_decks.dart` aceita `VALIDATION_COMMANDERS` separados por `;` ou quebra de linha
- `bootstrap_resolution_corpus_decks.dart` aceita seed pareado via `A + B`
- o runner oficial de resolucao aceita `1` ou `2` comandantes legais com base no deck fonte
- reminder text inline nao pode mais inflar identidade de cor; `Blind Obedience` em `Sythis` passou a validar corretamente
- o bootstrap nao pode mais preencher 100 cartas adicionando terrenos extras quando faltarem spells
- se nao houver spell density suficiente, o comportamento correto agora e `montagem insuficiente`
- a identidade de cor nao depende mais apenas de `cards.color_identity`; quando esse campo vier incompleto, o servidor infere pelo `oracle_text`

Status atual do gate recorrente:

- corpus estavel principal: `19` decks
- ultima revalidacao completa: `19/19 passed`, `0 failed`, `0 unresolved`

Excecao operacional documentada:

- `Yuriko, the Tiger's Shadow` ficou fora do corpus estavel apos a rodada de 2026-03-23
- motivo: o seed anterior inflava land count para `47`; depois da correcao, o bootstrap passou a rejeitar esse caso como `montagem insuficiente`

## Regra de manutencao

Qualquer mudanca em `server/routes/ai/optimize/` ou `server/lib/ai/` deve responder estas perguntas antes de ser considerada segura:

1. alterou legalidade do deck final?
2. alterou balance de swaps?
3. alterou classificacao funcional de cartas?
4. alterou a consistencia ou o score do validator?
5. alterou contrato HTTP, telemetry ou outcome code?

Se a resposta for "sim" para qualquer uma delas, a mudanca precisa vir acompanhada de teste nesta pasta.

## Aditivo de 2026-03-23 - Reanalise Completa

Rodada adicional confirmada nesta data:

- suites deterministicas principais: verdes
- `ai_optimize_flow_test.dart` com `RUN_INTEGRATION_TESTS=1`: verde
- `ai_generate_create_optimize_flow_test.dart` com `RUN_INTEGRATION_TESTS=1`: verde

Furos fechados na rodada:

- filtros internos da rota `optimize` agora usam identidade inferida por `oracle_text` quando necessario
- `C` nao e mais tratado como cor de identidade de Commander

Decisao sobre corpus Commander:

- o corpus atual de `16` decks e suficiente para a fase atual
- as proximas adicoes devem ser dirigidas por cobertura de comportamento
- prioridades futuras:
- `optimized_directly`
- segundo `rebuild_guided`
- `partner/background`
- five-color
- colorless estrito

Atualizacao pratica desta rodada:

- `Jodah, the Unifier` foi confirmado como seed five-color viavel
- probe real do `Jodah` com backend atualizado fechou em `safe_no_change`
- colorless e `background` ainda estao em estabilizacao antes de entrar no corpus estavel
