# Matriz De Testes Da Otimizacao - 2026-03-23

## Objetivo

Este documento registra a leitura correta da malha de testes da otimizacao de decks.

Ele existe para responder quatro perguntas:

1. quais testes realmente sustentam o carro chefe do produto
2. se eles estao corretos e significativos
3. o que foi validado nesta rodada
4. o que ainda precisa de homologacao para confianca de release

## Resposta curta

Sim, a malha de testes da otimizacao esta seria, extensa e bem montada.

O backend hoje tem cobertura forte para:

- regras formais de deck
- quality gates
- validacao final apos swaps
- consistencia e goldfish
- parser do payload de IA
- aprendizado e prioridade de sugestoes
- contratos principais do fluxo optimize

O ponto de atencao nao esta na falta de testes basicos. Esta em dois detalhes:

- parte da camada "integration" e integracao interna do pipeline, nao HTTP real
- a jornada HTTP real depende de ambiente e, fora dele, faz skip controlado

## Escopo auditado

### Backend

- `server/test/optimization_rules_test.dart` - 52 testes
- `server/test/optimization_quality_gate_test.dart` - 8 testes
- `server/test/optimization_final_validation_test.dart` - 25 testes
- `server/test/optimization_goal_validation_test.dart` - 3 testes
- `server/test/optimization_validator_test.dart` - 6 testes
- `server/test/goldfish_simulator_test.dart` - 14 testes
- `server/test/generated_deck_validation_service_test.dart` - 3 testes
- `server/test/optimize_learning_pipeline_test.dart` - 12 testes
- `server/test/optimize_payload_parser_test.dart` - 3 testes
- `server/test/optimization_pipeline_integration_test.dart` - 23 testes
- `server/test/ai_optimize_flow_test.dart` - 11 testes
- `server/test/ai_generate_create_optimize_flow_test.dart` - 2 testes
- `server/test/ai_optimize_telemetry_contract_test.dart` - 4 testes
- `server/test/deck_analysis_contract_test.dart` - 3 testes
- `server/test/card_resolution_support_test.dart` - 5 testes
- `server/test/commander_reference_atraxa_test.dart` - 1 teste
- `server/test/ml_analyzer_test.dart` - 31 testes

Total auditado no backend ligado ao core de otimizacao: `206` testes.

### App Flutter

- `app/test/features/decks/models/deck_card_item_test.dart`
- `app/test/features/decks/models/deck_details_test.dart`
- `app/test/features/decks/models/deck_test.dart`
- `app/test/features/decks/providers/deck_provider_test.dart`
- `app/test/features/decks/screens/deck_flow_entry_screens_test.dart`
- `app/test/features/decks/widgets/deck_card_overflow_test.dart`
- `app/test/features/decks/widgets/deck_diagnostic_panel_test.dart`
- `app/test/features/decks/widgets/sample_hand_widget_test.dart`

Total auditado na camada Flutter ligada ao fluxo de decks: `41` testes.

## O que cada bloco realmente prova

### 1. Regras formais e legalidade

Arquivos principais:

- `optimization_rules_test.dart`
- `optimization_final_validation_test.dart`

Prova:

- tamanho correto do deck por formato
- limite de copias
- tratamento correto de basic lands
- identidade de cor
- elegibilidade de commander
- banlist e restricted list
- rejeicao de adicoes duplicadas nao permitidas
- preservacao de deck size apos swaps

Leitura: esta camada esta forte e correta.

### 2. Qualidade de swap e seguranca funcional

Arquivos principais:

- `optimization_quality_gate_test.dart`
- `optimization_validator_test.dart`
- `optimization_goal_validation_test.dart`

Prova:

- bloqueio de swaps off-role
- bloqueio de downgrades estruturais
- preservacao de papel funcional
- recuperacao estrutural quando a base esta degenerada
- melhoria coerente para aggro, control e midrange
- aprovacao ou rejeicao final com justificativa

Leitura: esta e a camada mais importante para o diferencial do produto, e ela esta bem representada.

### 3. Consistencia e simulacao

Arquivos principais:

- `goldfish_simulator_test.dart`
- `generated_deck_validation_service_test.dart`
- `ml_analyzer_test.dart`

Prova:

- deteccao de mana screw
- score de consistencia
- comportamento deterministico quando ha seed fixa
- estatisticas de curva e performance simulada
- validacao de deck gerado com reparos tolerados
- suporte a analise adicional por ML

Leitura: boa cobertura para evitar "otimizacao bonita no JSON e ruim na mesa".

### 4. Pipeline e parser

Arquivos principais:

- `optimize_payload_parser_test.dart`
- `optimize_learning_pipeline_test.dart`
- `optimization_pipeline_integration_test.dart`

Prova:

- parsing de formatos de swap
- consolidacao de pools de prioridade
- penalizacao de sugestoes historicamente ruins
- composicao interna da pipeline apos resposta da IA
- construcao de outcome codes

Leitura:

- esta parte esta correta
- precisa ser lida como integracao interna do motor, nao como prova de endpoint real

### 5. Contrato HTTP e fluxo real

Arquivos principais:

- `ai_optimize_flow_test.dart`
- `ai_generate_create_optimize_flow_test.dart`
- `ai_optimize_telemetry_contract_test.dart`
- `deck_analysis_contract_test.dart`

Prova:

- contrato do endpoint de optimize
- erros esperados
- telemetry
- create -> validate -> optimize
- analise real por contrato

Leitura:

- estes testes sao corretos e importantes
- dependem de ambiente vivo
- hoje fazem skip controlado sem poluir `dart test` local

## Validacao executada nesta rodada

### Backend validado e verde

Executado com sucesso:

- `optimization_rules_test.dart`
- `optimization_quality_gate_test.dart`
- `optimization_final_validation_test.dart`
- `optimization_goal_validation_test.dart`
- `optimization_validator_test.dart`
- `goldfish_simulator_test.dart`
- `generated_deck_validation_service_test.dart`
- `optimize_learning_pipeline_test.dart`
- `optimize_payload_parser_test.dart`
- `optimization_pipeline_integration_test.dart`

Resultado:

- verde
- sem falhas
- sem flakiness observado nesta rodada

### Suites condicionais verificadas

Executadas nesta rodada em modo local:

- `ai_optimize_flow_test.dart`
- `ai_generate_create_optimize_flow_test.dart`
- `ai_optimize_telemetry_contract_test.dart`

Resultado:

- skip controlado por ausencia de `RUN_INTEGRATION_TESTS=1`
- comportamento esperado
- nenhum falso negativo de suite local

Validacao adicional desta rodada:

- com backend local ativo e `RUN_INTEGRATION_TESTS=1`, `ai_optimize_flow_test.dart` foi exercitado com sucesso
- `ai_generate_create_optimize_flow_test.dart` expôs dependencia externa de credencial OpenAI invalida no ambiente
- o backend foi endurecido para fallback seguro em `dev/staging` nas rotas com modo mock (`generate`, `archetypes`, `explain`)
- apos o ajuste, `ai_generate_create_optimize_flow_test.dart` voltou a passar com backend local ativo

### Banco auditado nesta rodada

Sinais observados:

- cache/meta existe e esta populado
- logs reais de IA existem e confirmam sucesso e falha por endpoint
- telemetria de fallback existe, mas hoje so mostrou eventos em `mode=optimize`
- `commander_reference_profiles` ainda cobre menos comandantes do que o corpus real de validacao

Leitura:

- a base de dados sustenta o core, mas o cache de referencia de commander ainda nao esta no mesmo nivel da suite commander operacional

### Flutter validado e verde

Executado com sucesso:

- `deck_provider_test.dart`
- `deck_diagnostic_panel_test.dart`
- `sample_hand_widget_test.dart`
- `deck_flow_entry_screens_test.dart`
- `deck_card_item_test.dart`
- `deck_details_test.dart`
- `deck_test.dart`
- `deck_card_overflow_test.dart`

Resultado:

- verde
- contratos relevantes do provider confirmados
- entrada do fluxo de onboarding protegida
- smoke do provider cobrindo `deck details -> optimize -> apply -> validate`

## Veredito da auditoria

### Estao corretas?

Sim, no geral estao corretas.

Razoes:

- cobrem regras duras do dominio, nao apenas respostas felizes
- cobrem rejeicao, warning, `needs_repair` e sucesso
- exercitam tanto comportamento estrutural quanto consistencia
- testam o que importa para o usuario final: deck valido, coerente e melhorado

### Estao suficientes para dizer "perfeito"?

Nao honestamente.

Razoes:

- ainda falta smoke de tela completa com UI, embora o smoke funcional do provider do fluxo core já exista
- os arquivos centrais do motor continuam grandes demais, o que aumenta risco de regressao futura

### Estao suficientes para dizer "forte e pronta para Sprint 1 focada no core"?

Sim.

A base atual justifica travar a Sprint 1 em otimizacao de decks e evoluir com criterio de release.

## Gaps residuais

1. transformar o corpus estavel em gate operacional recorrente, nao apenas auditoria manual
2. ampliar do smoke funcional atual para smoke de tela completa em `details -> optimize -> apply -> validate`
3. modularizar `server/routes/ai/optimize/index.dart`
4. reduzir concentracao de fluxo AI em `deck_provider.dart` e `deck_details_screen.dart`
5. adicionar cobertura dirigida para flow paths ainda sub-representados

## Aditivo - Expansao Do Corpus Commander Em 2026-03-23

Leitura consolidada nesta rodada:

- o corpus estavel de resolucao Commander saiu de `10` para `16` decks
- os `6` novos comandantes estabilizados foram:
- `Meren of Clan Nel Toth`
- `Korvold, Fae-Cursed King`
- `Kaalia of the Vast`
- `Miirym, Sentinel Wyrm`
- `Wilhelt, the Rotcleaver`
- `Prosper, Tome-Bound`

Validacao real executada:

- relatorio focado em novos comandantes: `RELATORIO_RESOLUCAO_NOVOS_COMMANDERS_2026-03-23.md`
- artifact dir: `server/test/artifacts/optimization_resolution_new_commanders_2026_03_23`
- resultado: `6/6` passaram
- flow path observado nos `6`: `safe_no_change`
- deck final valido em todos os `6`
- deck final `healthy` em todos os `6`
- land count final `36` em todos os `6`

Ajustes de logica feitos para suportar essa rodada:

- `bootstrap_resolution_corpus_decks.dart` passou a aceitar `VALIDATION_COMMANDERS` por `;` ou quebra de linha
- o bootstrap deixou de completar deck com terrenos extras quando faltam spells
- o bootstrap passou a inferir identidade de cor por `oracle_text` quando o banco nao traz `color_identity` suficiente
- `DeckRulesService` passou a inferir identidade de cor por `oracle_text`, reduzindo falso negativo em Commander quando o banco vier incompleto

Caso explicitamente removido do corpus estavel:

- `Yuriko, the Tiger's Shadow`
- motivo: o seed anterior foi montado com `47` terrenos por falta de spell density suficiente; apos o ajuste, o bootstrap agora retorna `montagem insuficiente`, o que e o comportamento correto para um corpus serio

## Conclusao operacional

O projeto nao esta "sem testes".

Ele ja tem uma malha respeitavel para o motor de otimizacao, e essa malha foi confirmada nesta rodada como util e bem alinhada com o objetivo do produto.

O caminho certo agora nao e abrir frente nova. E usar essa base para endurecer o que ainda falta para confianca de release do carro chefe.

## Aditivo - Reanalise Completa Do Core Em 2026-03-23

Validacao adicional fechada nesta rodada:

- `dart test` da bateria deterministica principal: verde
- `RUN_INTEGRATION_TESTS=1 dart test test/ai_optimize_flow_test.dart`: verde contra backend local real
- `RUN_INTEGRATION_TESTS=1 dart test test/ai_generate_create_optimize_flow_test.dart`: verde contra backend local real
- `run_optimize_validation.ps1`: verde com `start_local_test_server.ps1` + `bin/local_test_server.dart`

Furos reais encontrados e corrigidos:

- a rota `ai/optimize` ainda tinha filtros de identidade de cor que dependiam apenas de `cards.color_identity` e `cards.colors`
- isso deixava espaco para aceitar candidatos ilegais quando a base viesse incompleta e a cor real estivesse apenas no `oracle_text`
- a normalizacao de identidade de cor ainda tratava `C` como cor de Commander, o que podia marcar `Wastes` e `Sol Ring` como off-color em testes reais

Ajustes executados:

- `server/routes/ai/optimize/index.dart` passou a resolver identidade por `oracle_text` tambem nos filtros internos da otimizacao
- `server/lib/color_identity.dart` deixou de tratar `C` como cor valida de identidade de Commander
- `server/test/color_identity_test.dart` recebeu regressao para confirmar que `{C}` continua colorless e nao vira cor de identidade
- o projeto ganhou runner operacional local com:
- `server/bin/local_test_server.dart`
- `server/start_local_test_server.ps1`
- `server/stop_local_test_server.ps1`
- `server/run_optimize_validation.ps1`

Decisao sobre mais comandantes:

- nao precisamos de mais comandantes aleatorios agora
- o corpus estavel atual de `16` decks ja e suficiente para o proximo passo de endurecimento
- o gap nao e volume bruto; e distribuicao de comportamento

Distribuicao atual do corpus:

- `rebuild_guided`: `2`
- `safe_no_change`: `11`
- `expected_flow_paths` multiplos aceitando `optimized_directly` ou `safe_no_change`: `3`

Proximos comandantes so fazem sentido se forem dirigidos para estes vazios:

1. mais pelo menos `1` caso estavel que feche em `optimized_directly`
2. mais pelo menos `1` caso `rebuild_guided` fora do shell Talrand
3. `1` comandante com `partner` ou `background`
4. `1` comandante five-color
5. `1` comandante estritamente colorless
