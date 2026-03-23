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

## Modelo de validacao

### 1. Suites deterministicas e de regra

Rodam em `dart test` puro, sem servidor externo.

Essas suites provam a maior parte da logica critica do motor de otimizacao:

- `optimization_rules_test.dart` - 52 testes
- `optimization_quality_gate_test.dart` - 8 testes
- `optimization_final_validation_test.dart` - 25 testes
- `optimization_goal_validation_test.dart` - 3 testes
- `optimization_validator_test.dart` - 6 testes
- `goldfish_simulator_test.dart` - 14 testes
- `generated_deck_validation_service_test.dart` - 3 testes
- `optimize_learning_pipeline_test.dart` - 12 testes
- `optimize_payload_parser_test.dart` - 3 testes
- `card_resolution_support_test.dart` - 5 testes
- `commander_reference_atraxa_test.dart` - 1 teste
- `ml_analyzer_test.dart` - 31 testes

Cobrem principalmente:

- tamanho final do deck por formato
- limite de copias
- identidade de cor
- elegibilidade de commander
- banlist e restricted list
- classificacao funcional por papel
- quality gates para swaps inseguros
- validacao final da lista virtual apos swaps
- consistencia e goldfish simulation
- parser e aprendizado do pipeline

### 2. Suites de integracao estilo simulacao

Tambem rodam em `dart test` puro, mas nao fazem a jornada HTTP real.

- `optimization_pipeline_integration_test.dart` - 23 testes

Importante:

- o nome "integration" aqui significa integracao interna do pipeline
- ela valida composicao de helpers, parser, analise virtual e derivacao de outcome
- ela nao substitui a validacao real de endpoint, auth, persistencia ou banco

### 3. Suites de contrato e integracao HTTP real

Essas suites sao opt-in por ambiente e ficam protegidas por `RUN_INTEGRATION_TESTS=1`.

- `ai_optimize_flow_test.dart` - 11 testes
- `ai_generate_create_optimize_flow_test.dart` - 2 testes
- `ai_optimize_telemetry_contract_test.dart` - 4 testes
- `deck_analysis_contract_test.dart` - 3 testes
- `decks_crud_test.dart`
- `core_flow_smoke_test.dart`
- `error_contract_test.dart`
- `import_to_deck_flow_test.dart`

Essas suites devem ser lidas como:

- passam de verdade quando servidor, auth e banco estao disponiveis
- fazem skip controlado quando o ambiente nao foi armado
- suites que dependem de geracao por IA tambem podem ser puladas quando a credencial OpenAI do ambiente estiver invalida
- nao devem derrubar a suite local por ausencia de infraestrutura

Observacao operacional nova:

- rotas com fallback seguro de IA (`generate`, `archetypes`, `explain`) agora degradam em `dev/staging` quando a chave existe mas esta invalida, preservando a validacao local do fluxo

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
