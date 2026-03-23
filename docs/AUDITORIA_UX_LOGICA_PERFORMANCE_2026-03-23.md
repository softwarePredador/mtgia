# Auditoria UX Logica Performance - 2026-03-23

## Escopo

Auditoria completa do `mtgia` com foco em:

- todas as telas Flutter em `app/lib/features/**/screens`
- fluxo principal de decks
- confiabilidade do backend que sustenta `geracao`, `analise`, `importacao` e `otimizacao`
- gargalos de usabilidade, manutencao e performance

## Metodologia

### Leitura estrutural

- mapeamento das `25` telas do app
- leitura das rotas em `app/lib/main.dart`
- revisao das superficies centrais:
- `app/lib/features/decks/screens/deck_list_screen.dart`
- `app/lib/features/decks/screens/deck_generate_screen.dart`
- `app/lib/features/decks/screens/deck_import_screen.dart`
- `app/lib/features/decks/screens/deck_details_screen.dart`
- `app/lib/features/cards/screens/card_search_screen.dart`
- `app/lib/features/home/home_screen.dart`
- `app/lib/features/home/onboarding_core_flow_screen.dart`

### Validacao tecnica executada

- `app/flutter analyze`
- `app/flutter test`
- `server/dart test`

Resultado final da rodada:

- `app/flutter analyze`: verde
- `app/flutter test`: verde
- `server/dart test`: verde

## Resumo Executivo

O produto esta em um ponto bom de maturidade funcional, especialmente no backend do deck builder e na camada de validacao/otimizacao. O principal risco nao esta mais em "falta de feature", e sim em tres frentes:

1. pontos de UX que reduzem confianca percebida mesmo quando a logica do backend esta correta
2. concentracao excessiva de responsabilidade em arquivos grandes demais
3. cobertura de testes do app ainda inferior ao nivel de importancia do fluxo core

Depois dos ajustes desta rodada, o fluxo principal ficou mais coerente e a base local ficou mais confiavel para evolucao.

## Decisao Executiva Da Rodada

A partir desta definicao, o Sprint 1 do projeto deve ser tratado como sprint monotematica:

- foco total em `otimizacao de decks`
- nenhuma frente secundaria entra na fila antes de elevar o carro chefe para nivel de confianca de release

Interpretacao pratica:

- qualquer item novo so entra se melhorar ou provar a qualidade da pipeline `generate -> analyze -> optimize -> apply -> validate`
- melhorias visuais ou funcionais fora do core ficam suspensas, salvo se removerem risco direto para a confianca da otimizacao

## Avaliacao De Satisfacao E Usabilidade

Escala interna desta auditoria: `0-10`

| Area auditada | Nota | Leitura |
| --- | --- | --- |
| Descoberta do fluxo principal | 8.0 | Home e onboarding ficaram mais coerentes depois dos ajustes |
| Criacao/Importacao de deck | 8.3 | Fluxo forte, mas ainda depende de muito contexto em poucas telas |
| Analise/Otimizacao | 8.7 | Backend forte, UX boa, mas sustentada por arquivos gigantes |
| Confianca percebida | 8.1 | Melhorou com os fixes de formato, loading e testes |
| Funcionalidades adjacentes | 6.8 | Existem e agregam valor, mas maturidade e cobertura sao desiguais |
| Readiness operacional local | 8.5 | Suite verde e sinais mais confiaveis do que no inicio da rodada |

Leitura final:

- satisfacao esperada do usuario focado em deck builder: alta
- satisfacao esperada do usuario explorando toda a superficie social/comercial: media
- confiabilidade tecnica local: boa
- confiabilidade para device real e cenario publicado: boa no core, parcial nas integracoes externas

## Mapa Das Telas Auditadas

- `auth`: login, register, splash
- `home`: home, onboarding core flow, life counter
- `decks`: list, generate, import, details
- `cards`: search, detail
- `collection`: collection hub, latest set
- `binder`: binder, marketplace tab host
- `market`: market screen legado
- `community`: listagem e detalhe
- `social`: busca de usuarios, perfil
- `messages`: inbox, chat
- `notifications`: notification screen
- `scanner`: card scanner
- `trades`: inbox, detalhe, criacao

## Achados Prioritarios

### P0 Resolvidos Nesta Rodada

#### 1. Onboarding perdia o formato escolhido

Sintoma:

- o usuario escolhia `modern`, `pauper` ou outro formato no onboarding
- ao seguir para gerar ou importar, as telas voltavam ao default

Impacto:

- quebra direta de confianca no fluxo principal
- aumento de risco de deck criado no formato errado

Ajuste aplicado:

- `app/lib/main.dart`
- `app/lib/features/decks/screens/deck_generate_screen.dart`
- `app/lib/features/decks/screens/deck_import_screen.dart`
- `app/test/features/decks/screens/deck_flow_entry_screens_test.dart`

#### 2. Home podia mostrar vazio falso

Sintoma:

- a home abria sem buscar decks
- usuario autenticado podia ver "nenhum deck criado ainda" antes do fetch real

Impacto:

- percepcao de perda de dados
- piora imediata da confianca logo na entrada do app

Ajuste aplicado:

- `app/lib/features/home/home_screen.dart`

#### 3. Suite do backend falhava localmente por ambiente, nao por regressao

Sintoma:

- `server/dart test` derrubava o status local tentando autenticar em `localhost:8080` sem servidor ativo

Impacto:

- sinal falso negativo de qualidade
- menor confiabilidade do pipeline local

Ajuste aplicado:

- guards em `setUpAll`/`tearDownAll` das suites de integracao
- reforco em `server/test/decks_crud_test.dart`

Arquivos ajustados:

- `server/test/ai_generate_create_optimize_flow_test.dart`
- `server/test/core_flow_smoke_test.dart`
- `server/test/deck_analysis_contract_test.dart`
- `server/test/decks_crud_test.dart`
- `server/test/error_contract_test.dart`
- `server/test/import_to_deck_flow_test.dart`

#### 4. Validacao estatistica com flakiness

Sintoma:

- teste de score neutro do `OptimizationValidator` oscilava sem mudanca funcional real

Impacto:

- risco de CI instavel
- menor confianca no score exibido ao usuario

Ajuste aplicado:

- seed deterministica no mulligan report

Arquivo ajustado:

- `server/lib/ai/optimization_validator.dart`

## Gargalos Reais Identificados

### Gargalo 1. Arquivos criticos muito grandes

Medicoes da rodada:

- `app/lib/features/decks/screens/deck_details_screen.dart`: `4703` linhas
- `app/lib/features/decks/providers/deck_provider.dart`: `1840` linhas
- `server/routes/ai/optimize/index.dart`: `7979` linhas
- `server/lib/ai/rebuild_guided_service.dart`: `1747` linhas
- `app/lib/features/home/life_counter_screen.dart`: `2669` linhas

Leitura:

- o sistema tem boa capacidade funcional, mas a manutencao futura esta ficando cara
- regressao pequena em `deck details` ou `ai/optimize` pode vazar para varias partes do produto
- esse e o maior risco estrutural do projeto hoje

### Gargalo 2. Cobertura do app ainda nao acompanha a importancia do produto

Estado observado:

- o app esta verde em analyze e widget tests
- a cobertura ainda se concentra em widgets especificos, overflow e alguns contratos do provider
- muitas telas importantes nao possuem smoke dedicado

Leitura:

- backend esta mais protegido do que a jornada percebida pelo usuario
- o produto pode "funcionar tecnicamente" e ainda assim parecer inconsistente no app

### Gargalo 3. Superficies adjacentes com maturidade desigual

Areas de atencao:

- `community`
- `social`
- `messages`
- `trades`
- `scanner`
- `binder`/`marketplace`

Leitura:

- essas areas ampliam valor e retencao
- mas ainda nao foram validadas nesta rodada no mesmo nivel de profundidade do deck builder
- devem ser tratadas como frentes P1/P2 enquanto o core continua dominante

## Avaliacao Por Fluxo

### 1. Auth e boot

Status:

- consistente
- sem findings criticos nesta rodada

Risco residual:

- nao houve validacao em device real para push, firebase e todos os cenarios de sessao expirada

### 2. Home e onboarding

Status:

- melhorou claramente apos os ajustes
- CTA principal do produto esta visivel
- descoberta do fluxo core esta boa

Risco residual:

- `home_screen.dart` ainda concentra muita responsabilidade visual

### 3. Criacao, importacao, busca e detalhes de deck

Status:

- melhor area do produto em valor real
- backend e app estao alinhados para deck builder
- importacao, validacao e otimizacao estao bem representadas no sistema

Risco residual:

- detalhe de deck ainda concentra UI, diagnostico, validacao, pricing, sharing e otimizacao num unico arquivo

### 4. Colecao, fichario e marketplace

Status:

- bons como ecossistema de apoio
- arquitetura de hub em `collection_screen.dart` ajuda navegacao

Risco residual:

- maturidade funcional percebida e menor do que no core de decks

### 5. Social, comunidade, mensagens e trades

Status:

- relevantes para retencao
- nao sao o ponto mais forte do produto hoje

Risco residual:

- coverage e validacao de jornada ainda menores do que o ideal

### 6. Scanner

Status:

- feature valiosa para entrada de cartas

Risco residual:

- depende de camera, OCR, permissao e condicoes de device real
- esta rodada nao validou esse fluxo ponta a ponta em hardware

## Comandos Executados

- `app/flutter analyze`
- `app/flutter test`
- `server/dart test`

## Ajustes Aplicados Nesta Rodada

- preservacao de `format` entre onboarding e geracao/importacao
- carregamento automatico de decks na home
- placeholder de loading na home antes de declarar vazio
- novo teste de widget para entrada do fluxo core
- endurecimento das suites de integracao do backend em ambiente local
- seed estavel no `OptimizationValidator`

## Aditivo - Auditoria Da Malha De Testes De Otimizacao

Leitura consolidada nesta rodada:

- a malha de otimizacao do backend esta forte e significativa
- o projeto nao depende apenas de smoke superficial ou "mock feliz"
- existe separacao real entre testes de regra, testes de pipeline simulada e testes HTTP condicionais

Validacao confirmada em `2026-03-23`:

- suites deterministicas do backend da otimizacao: verdes
- suite `optimization_pipeline_integration_test.dart`: verde
- camada Flutter relevante do fluxo de decks: verde
- suites HTTP reais: skip controlado sem falso negativo quando `RUN_INTEGRATION_TESTS` nao esta ativo

Conclusao pratica:

- o core de otimizacao esta pronto para Sprint 1 monotematica
- a documentacao oficial dessa leitura agora esta em `docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md`
- o maior gap restante nao e ausencia de regra testada, e sim homologacao completa de ambiente e jornada final do app

## Aditivo - Auditoria De Banco E Infra Da Otimizacao

Leitura confirmada em `2026-03-23`:

- `meta_decks`: `325` registros
- `format_staples`: `748` registros
- `card_legalities`: `312942` registros
- `ai_logs`: `492` registros
- `ai_optimize_fallback_telemetry`: `77` registros

Achados importantes:

- a tabela operacional de telemetria do fallback e `ai_optimize_fallback_telemetry`, nao `ai_optimization_logs`
- a tabela de logs de IA em uso e `ai_logs`
- `commander_reference_profiles` tem apenas `7` perfis cacheados, enquanto o corpus operacional de commander ja cobre `10` comandantes

Gap concreto de dados observado:

- faltam perfis de referencia para `Talrand, Sky Summoner`
- faltam perfis de referencia para `Jin-Gitaxias // The Great Synthesis`
- faltam perfis de referencia para `Auntie Ool, Cursewretch`

Impacto pratico:

- o `complete` ainda depende mais de fallback/live fetch do que o ideal em parte do corpus
- isso nao invalida a pipeline, mas reduz previsibilidade e aumenta custo/latencia potencial

## Pendencias Recomendadas

### P1 Imediato

1. criar corpus oficial de decks de referencia para otimizacao:
   - commander incompleto
   - commander quase fechado
   - listas com identidade de cor complexa
   - decks agressivos, controle, midrange, combo e tribal
2. transformar esse corpus em suite obrigatoria com quality gates objetivos:
   - legalidade
   - consistencia
   - delta funcional por papel
   - proibicao de cartas off-color
   - deck size final correto
3. modularizar `server/routes/ai/optimize/index.dart` em servicos/coordenadores menores
4. separar `deck_provider.dart` e `deck_details_screen.dart` por responsabilidades do fluxo AI
5. criar smoke tests do app para:
   - onboarding -> generate
   - onboarding -> import
   - deck list -> details
   - deck details -> optimize
6. consolidar contrato de retorno da otimizacao no app:
   - sucesso
   - warning parcial
   - needs_repair
   - no_safe_upgrade_found
   - falha real

### P2 Curto Prazo

1. validar `scanner`, `share`, `notifications` e `messages` em device real
2. ampliar metricas de tempo real do fluxo core no app
3. mapear p95 real de `deck details`, `analysis`, `pricing` e `optimize job polling`

## Conclusao

O `mtgia` esta em um estado bom e serio para um produto cujo diferencial esta no deck builder com IA. O core tem qualidade funcional acima da media do restante da superficie e agora esta mais coerente tambem na experiencia inicial do usuario.

O que mais ameaca a evolucao do projeto hoje nao e ausencia de feature. Sao os monolitos de app/backend, a cobertura ainda insuficiente no app para as jornadas mais criticas e a necessidade de validar em device real tudo o que envolve integracoes externas.

Com a decisao de dedicar a Sprint 1 integralmente a otimizacao de decks, o caminho mais forte e correto e perseguir confianca maxima no core antes de qualquer outra expansao. Isso coloca o projeto na direcao certa.

## Aditivo - Corpus Estavel De Commander Em 2026-03-23

Evolucao confirmada nesta rodada:

- o corpus estavel de resolucao Commander agora cobre `16` decks
- os `6` novos casos estabilizados foram `Meren`, `Korvold`, `Kaalia`, `Miirym`, `Wilhelt` e `Prosper`
- a execucao focada desses `6` fechou `6/6` verde em `RELATORIO_RESOLUCAO_NOVOS_COMMANDERS_2026-03-23.md`
- o comportamento observado nos `6` foi conservador e coerente: `safe_no_change` com deck final valido, healthy e `36` terrenos

Achados tecnicos importantes:

- o bootstrap do corpus tinha um furo de confiabilidade: quando faltavam spells, ele completava 100 cartas adicionando terrenos extras
- esse comportamento produziu um falso baseline para `Yuriko`, que apareceu com `47` terrenos mesmo em `safe_no_change`
- o bootstrap foi corrigido para falhar honestamente com `montagem insuficiente` em vez de inflar land count
- a validacao de identidade de cor do servidor passou a inferir cores pelo `oracle_text` quando o banco vier com `color_identity` vazio, reduzindo risco de aceitar lands/duals fora da identidade real

Decisao operacional:

- `Yuriko, the Tiger's Shadow` foi retirada do corpus estavel
- ela deve voltar apenas quando houver material de referencia suficiente para seed saudavel e repetivel

## Aditivo - Revalidacao Ponta A Ponta Da Otimizacao Em 2026-03-23

Reanalise concluida com foco em:

- logica interna da otimizacao
- filtros de identidade de cor
- fluxo HTTP real
- retorno efetivo do optimize em modo `complete`, `rebuild_guided` e `safe_no_change`
- coerencia operacional entre prompt, banco e contrato do endpoint

Furos reais fechados:

- a rota `server/routes/ai/optimize/index.dart` ainda tinha trechos usando apenas `color_identity` e `colors` do banco para filtrar candidatos
- em cenarios onde o banco viesse incompleto, a identidade real podia existir apenas no `oracle_text`, abrindo margem para falso positivo na selecao
- `server/lib/color_identity.dart` ainda aceitava `C` como se fosse cor valida de identidade, o que e incorreto para Commander

Resultado pratico apos o ajuste:

- `Wastes` voltou a ser tratado como colorless valido
- `Sol Ring` deixou de cair como fora da identidade em testes reais
- a rota `optimize` passou a validar candidatos com a mesma regra mais robusta usada na camada de regras/validacao

Validacao executada nesta rodada:

- `dart test` das suites deterministicas principais da otimizacao: verde
- `RUN_INTEGRATION_TESTS=1 dart test test/ai_optimize_flow_test.dart`: verde com backend local real
- `RUN_INTEGRATION_TESTS=1 dart test test/ai_generate_create_optimize_flow_test.dart`: verde com backend local real
- `server/run_optimize_validation.ps1`: verde usando bootstrap local nao interativo em IPv4

Leitura de produto e engenharia:

- o core de otimizacao ficou mais confiavel de verdade, nao apenas "com mais testes"
- a resposta do endpoint foi acompanhada em conteudo e persistencia, nao so em status code
- o principal gargalo restante nao e falta de comandantes; e a concentracao exagerada de responsabilidade em `optimize/index.dart`

Decisao sobre expansao de comandantes:

- nao ha necessidade de adicionar mais comandantes genericamente nesta rodada
- as proximas adicoes devem ser dirigidas para cobrir flow paths ainda raros no corpus atual
- prioridade de cobertura futura:
- `optimized_directly` estavel
- segundo caso `rebuild_guided`
- `partner/background`
- five-color
- colorless estrito
