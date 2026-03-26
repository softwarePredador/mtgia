# Flutter Test Suite - MTGIA

> Guia ativo de testes do app.
> A prioridade funcional dessas suites deve seguir `docs/CONTEXTO_PRODUTO_ATUAL.md`.

Esta pasta cobre o comportamento do app que sustenta o fluxo principal de decks.

O backend carrega a maior parte da logica de otimizacao, mas o app precisa preservar contexto, interpretar contratos corretamente e nao degradar a confianca percebida do usuario.

## Foco atual

Em `2026-03-23`, a prioridade oficial do projeto passou a ser proteger a jornada:

- onboarding
- gerar ou importar deck
- abrir details
- otimizar
- aplicar e validar

## Estrutura relevante hoje

- `test/features/decks/models/`
- `test/features/decks/providers/`
- `test/features/decks/screens/`
- `test/features/decks/widgets/`

## Suites relevantes do core

### Models

- `deck_card_item_test.dart`
- `deck_details_test.dart`
- `deck_test.dart`

Cobrem:

- parsing de contratos JSON
- defaults e fallbacks
- serializacao
- preservacao de cores e dados de carta

### Provider

- `deck_provider_test.dart`

Cobertura principal:

- falha quando o batch resolve quebra
- falha quando ha nomes nao resolvidos
- falha quando ha nomes ambiguos
- preserva ids diretos e nomes resolvidos na criacao
- interpreta corretamente payload estruturado de `needs_repair`
- preserva contrato de `rebuild` em sucesso

### Screens

- `deck_flow_entry_screens_test.dart`

Cobertura principal:

- o formato escolhido no onboarding chega intacto em generate
- o formato escolhido no onboarding chega intacto em import

### Widgets

- `deck_diagnostic_panel_test.dart`
- `sample_hand_widget_test.dart`
- `deck_card_overflow_test.dart`

Cobrem:

- exibicao de metricas e insights do deck
- comportamento de sample hand
- robustez visual em larguras pequenas e nomes longos

## Resultado da auditoria de 2026-03-23

Validado nesta rodada:

- suites de models ligadas a deck
- `deck_provider_test.dart`
- widgets que sustentam diagnostico, sample hand e robustez visual
- entrada do fluxo de onboarding para generate e import

Status:

- camada Flutter relevante auditada nesta rodada: verde

Leitura operacional:

- o app esta protegendo melhor os contratos do backend
- ja existe smoke funcional do provider para `deck details -> optimize -> apply -> validate`
- a maior fragilidade continua sendo cobertura insuficiente de jornadas completas, nao de widgets isolados

## Comandos recomendados

### Validacao Flutter do core

```bash
flutter test test/features/decks/models/deck_card_item_test.dart \
  test/features/decks/models/deck_details_test.dart \
  test/features/decks/models/deck_test.dart \
  test/features/decks/providers/deck_provider_test.dart \
  test/features/decks/screens/deck_flow_entry_screens_test.dart \
  test/features/decks/widgets/deck_diagnostic_panel_test.dart \
  test/features/decks/widgets/sample_hand_widget_test.dart \
  test/features/decks/widgets/deck_card_overflow_test.dart
```

### Validacao completa do app

```bash
flutter test
```

### Prova visual do life counter clone

```bash
flutter test test/features/home/life_counter_clone_proof_test.dart --update-goldens
powershell -ExecutionPolicy Bypass -File tool/generate_life_counter_clone_proof.ps1
flutter test test/features/home/life_counter_clone_proof_test.dart
```

Essa suite gera a prova side-by-side do clone:

- screenshots atuais do app em `test/features/home/goldens/`
- benchmarks convertidos em `test/features/home/benchmarks/`
- provas side-by-side finais em `test/features/home/proofs/`

Leitura de aceite:

- a mesa, o hub e os overlays precisam bater visualmente na leitura imediata
- banners promocionais do app de referencia nao entram como criterio de aceite
- qualquer regressao visual relevante passa a aparecer no diff do golden

## Proximo salto de cobertura

Para colocar o app no mesmo nivel de exigencia do backend, as proximas suites devem cobrir:

1. `deck list -> deck details`
2. elevar o smoke funcional atual para smoke de tela completa em `deck details -> optimize -> apply -> validate`
3. erros de loading, timeout e `needs_repair` na tela de details
