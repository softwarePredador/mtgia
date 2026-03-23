# Contexto Produto Atual

> Fonte de verdade operacional para os proximos pedidos do `mtgia`.
> Sempre consultar este arquivo antes de ampliar escopo, mudar fluxo core ou reorganizar prioridades.
> Se alguma decisao estrutural mudar, este documento deve ser atualizado primeiro.

## Resumo Executivo

- produto ativo: `app/` + `server/`
- proposta central: gerar, importar, validar, analisar e otimizar decks de Magic com confiabilidade real
- carro chefe do produto: fluxo `criar/importar -> analisar -> otimizar -> aplicar -> validar`
- prioridade operacional atual: blindar o fluxo core de decks sem deixar telas adjacentes derrubarem a percepcao de confianca
- prioridade operacional imediata: Sprint 1 totalmente dedicada a deixar a otimizacao de decks no maior nivel possivel de confiabilidade antes de qualquer outra frente
- superficie auditada nesta rodada: `25` telas Flutter em `app/lib/features/**/screens`
- status tecnico local em `2026-03-23`:
- `app/flutter analyze`: verde
- `app/flutter test`: verde
- `server/dart test`: verde

## Documentos Que Abrem Contexto Rapido

- `docs/README.md`
- `docs/AUDITORIA_UX_LOGICA_PERFORMANCE_2026-03-23.md`
- `docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md`
- `README.md`
- `ROADMAP.md`
- `CHECKLIST_GO_LIVE_FINAL.md`
- `RELATORIO_VALIDACAO_2026-03-16.md`
- `server/manual-de-instrucao.md`

## Regra Rapida De Decisao

Se um pedido novo nao disser o contrario:

1. assumir que o escopo principal e o fluxo de decks
2. tratar `geracao`, `analise`, `otimizacao`, `importacao` e `validacao` como trilha critica do produto
3. nao deixar features adjacentes (`community`, `trades`, `binder`, `messages`, `scanner`) degradarem a confianca do fluxo core
4. toda tela do fluxo core precisa preservar contexto do usuario, especialmente `formato`, `deckId`, feedback de erro e estado de carregamento
5. toda melhoria de UX precisa ser acompanhada de validacao tecnica minimamente repetivel

## Ultima Atualizacao

- data: 2026-03-23
- status: ativo
- prioridade atual: consolidar confiabilidade do core de decks e mapear riscos de usabilidade/performance das telas
- regra funcional nova: o formato escolhido no onboarding precisa chegar intacto nas telas de geracao e importacao
- regra executiva nova: nenhuma frente secundaria deve competir com a frente de otimizacao de decks enquanto o carro chefe do produto nao atingir nivel de confianca de release
- regra de UX nova: a home nao pode mostrar estado vazio definitivo antes de buscar os decks reais do usuario
- regra tecnica nova de confiabilidade: testes de integracao do backend devem ser opt-in por ambiente (`RUN_INTEGRATION_TESTS=1`) e nao podem falhar a suite local por ausencia de servidor
- regra tecnica nova de consistencia: simulacoes do `OptimizationValidator` devem ser deterministicas para reduzir flakiness de score e aumentar confianca do CI
- regra documental nova: toda decisao sobre a frente de otimizacao deve consultar `docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md` antes de ampliar escopo ou declarar confianca de release

## Estrutura Oficial Do Produto

### 1. Core Deck Builder

- `app/lib/features/decks/`
- `server/routes/decks/`
- `server/routes/ai/generate`
- `server/routes/ai/optimize`
- `server/routes/ai/rebuild`

Esse bloco define valor direto de produto e deve continuar sendo a frente dominante.

### 2. Superficies De Apoio

- `cards`
- `collection`
- `binder`
- `market`
- `scanner`
- `community`
- `social`
- `messages`
- `notifications`
- `trades`
- `profile`
- `life_counter`

Essas areas aumentam utilidade e retencao, mas nao podem consumir a prioridade do fluxo core enquanto ainda houver risco de confianca em decks.

## Mapa De Risco Atual

### P0 Resolvido Nesta Rodada

- onboarding perdia o `format` escolhido ao entrar em `deck_generate_screen` e `deck_import_screen`
- home podia sugerir "nenhum deck criado" antes do primeiro fetch real
- `server/dart test` falhava localmente por suites de integracao disparando autenticacao sem servidor ativo
- score do `OptimizationValidator` tinha oscilacao estatistica desnecessaria por RNG nao deterministico no mulligan report

### P1 Aberto

- `app/lib/features/decks/screens/deck_details_screen.dart` continua muito grande e concentra logica critica demais em uma unica tela
- `app/lib/features/decks/providers/deck_provider.dart` ainda carrega responsabilidade excessiva para criacao, importacao, analise, otimizacao e manutencao de cache
- `server/routes/ai/optimize/index.dart` segue muito acima do tamanho ideal e representa gargalo de manutencao
- cobertura automatizada do app ainda esta abaixo do ideal para as `25` telas; a maior parte da protecao continua em widgets especificos e no backend
- validacao manual em device real ainda e necessaria para `scanner`, permissao de camera, push notifications e compartilhamento

## Norte De Qualidade

Para considerar o produto confiavel:

1. o usuario precisa conseguir sair do onboarding e chegar no primeiro deck otimizado sem perda de contexto
2. o backend precisa continuar respondendo com contratos previsiveis e suites verdes
3. telas do fluxo core precisam ter estados claros de loading, erro, vazio e sucesso
4. resultados de IA precisam ser explicaveis, aplicaveis e validaveis
5. qualquer regressao no core precisa ser detectada por teste ou por checklist operacional explicito

## Sprint Operacional Atual

### Objetivo

Fechar o ciclo de confiabilidade do deck builder principal e transformar a auditoria desta rodada em base oficial de trabalho.

### Ordem De Execucao

1. proteger onboarding, home e entrada no fluxo core
2. dedicar a Sprint 1 inteira a qualidade da otimizacao de decks
3. endurecer a confiabilidade dos testes locais e da validacao estatistica
4. mapear e corrigir gargalos logicos da pipeline `generate -> analyze -> optimize -> apply -> validate`
5. somente depois retomar UX lateral, social, scanner e superfices secundarias

### Entregas Fechadas Nesta Rodada

- `main.dart` agora propaga `format` para `DeckGenerateScreen` e `DeckImportScreen`
- `DeckGenerateScreen` e `DeckImportScreen` agora respeitam `initialFormat`
- `HomeScreen` passou a buscar decks ao abrir e mostra carregamento antes do estado vazio
- novo teste de widget garante que o formato vindo do onboarding chega nas telas de entrada do fluxo
- suites de integracao do backend agora respeitam melhor o modo local sem servidor
- `OptimizationValidator` passou a usar seed estavel para reduzir flakiness nos scores
- auditoria formal da malha de testes da otimizacao foi consolidada em documento proprio com distincoes entre regra, simulacao e HTTP real

### Definicao Oficial Da Sprint 1

Objetivo unico:

- elevar a otimizacao de decks ao maior nivel possivel de confiabilidade pratica

Escopo permitido:

- `server/routes/ai/optimize`
- `server/lib/ai/**`
- `server/routes/decks/**/analysis`
- `server/routes/decks/**/validate`
- `app/lib/features/decks/**`
- testes e artefatos diretamente ligados ao fluxo de otimizacao

Escopo bloqueado ate segunda ordem:

- expansao de `community`
- evolucao de `trades`
- melhorias cosmeticas fora do fluxo core
- novas features de `binder`, `market`, `messages` ou `scanner` que nao protejam o deck builder

Critério de saida da Sprint 1:

1. suite estatica e automatizada verde e estavel
2. corpus de decks de referencia cobrindo casos reais e extremos
3. quality gates objetivos para piora de consistencia, legalidade, role preservation e identidade de cor
4. contrato claro de erro, warning e sucesso da otimizacao
5. smoke manual guiado comprovando jornada completa no app

## Como Devemos Trabalhar A Partir De Agora

Antes de implementar qualquer pedido novo, confirmar internamente:

1. isso melhora ou protege o fluxo principal de decks?
2. existe alguma tela do core perdendo contexto do usuario?
3. a mudanca precisa de teste automatico ou checklist manual?
4. ha algum arquivo gigante demais para receber mais responsabilidade?
5. a documentacao ativa continua coerente com o estado real do sistema?
