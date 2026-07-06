# ManaLoom UI Audit Automation Plan - 2026-07-06

## Objetivo

Implantar uma base pratica de vistoria UI para as proximas 2 semanas, antes de novas features, sem entrar em AAB/APK, iOS ou billing server-side ainda.

O foco imediato e detectar regressao visual, tap target quebrado, semantica basica ausente, overflow e desalinhamento nos fluxos que impactam lancamento: home, gerar/importar deck, detalhes/otimizacao, planos/upgrade, profile/legal, collection/trades e life counter.

## Escolha pub.dev

Pacotes adotados agora:

- `alchemist`: golden testing com baseline CI estavel, separando snapshot humano/plataforma de snapshot estavel para pipeline.
- `accessibility_tools 2.8.0`: checkers em widget test para tap area, labels semanticos, inputs sem label, imagens e overflow por font scale. A versao `2.7.1` foi testada para preservar Flutter `>=3.35.0`, mas nao compila no Flutter atual por mudancas em `SemanticsFlags`; por isso a base assume Flutter `>=3.38.0` para auditoria de UI.

Pacotes avaliados e deixados para depois:

- `patrol`: bom para E2E real, mas aumenta setup e custo agora. Deve entrar depois que as telas principais estiverem cobertas por widget/golden e quando formos validar flows com backend/simulador de forma mais ampla.
- `golden_toolkit`: util, mas `alchemist` entrega separacao CI/local e API declarativa suficiente para a base inicial.

## O que foi aplicado

Base inicial em:

- `app/test/ui/manaloom_commercial_ui_audit_test.dart`

Ela cobre:

- estado Free perto do limite de IA;
- estado Free esgotado com paywall;
- estado Pro com uso ativo;
- smoke de acessibilidade com `accessibility_tools`;
- guidelines Flutter de tap target Android e labels de alvo clicavel.

Baseline gerada em:

- `app/test/ui/goldens/ci/manaloom_commercial_ai_usage_states.png`

## Comandos

Gerar ou atualizar baseline visual:

```bash
cd app
flutter test test/ui/manaloom_commercial_ui_audit_test.dart --update-goldens --no-version-check
```

Validar a baseline e acessibilidade:

```bash
cd app
flutter test test/ui/manaloom_commercial_ui_audit_test.dart --no-version-check
```

Validar app depois de mudancas:

```bash
cd app
flutter analyze lib test --no-version-check
flutter test test/ui/manaloom_commercial_ui_audit_test.dart test/features/commercial --no-version-check
```

## Plano por etapas

1. Comercial e monetizacao
   - Planos, upgrade, medidor de IA, paywall, mensagens de backend remoto.
   - Criterio: sem overflow, tap targets validos, estado Free/Pro claro e sem CTA fantasma.

2. Home e entrada de fluxo
   - Hero, acoes rapidas, onboarding de criar/importar/gerar deck.
   - Criterio: primeira tela mostra produto e comandos reais, sem texto de marketing escondendo workflow.

3. Deck details e otimizacao
   - Detalhes, diagnostico, optimize/apply/validate, erros de timeout/needs_repair.
   - Criterio: usuario entende status, diff antes/depois e falha recuperavel.

4. Collection, binder e trades
   - Listas densas, filtros, cards de carta, empty/error/loading states.
   - Criterio: legivel em telefone pequeno, sem truncar nomes longos ou esconder filtros.

5. Profile, legal e conta
   - Login remoto, plano, privacidade, termos e disclaimer.
   - Criterio: tudo navegavel antes do upgrade e coerente com backend.

6. Life counter
   - Validar escopo nativo/Lotus que ja existe e screenshots no simulador.
   - Criterio: sem regressao visual no contador vivo, sem quebra de touch em mesa.

7. Simulador
   - Rodar smoke navegando telas principais em iPhone/Android emulator quando a suite de widget estiver verde.
   - Criterio: screenshot atual, ausencia de overflow visivel e resposta aceitavel por fluxo.

## Gates antes de novas features

- `flutter analyze lib test --no-version-check` verde.
- `flutter test test/ui --no-version-check` verde.
- Pelo menos uma baseline golden por fluxo de lancamento.
- Sem issue visivel do `accessibility_tools` nas superficies auditadas.
- Prints/simulador anexados para telas que dependem de runtime real, camera, WebView ou assets pesados.

## Fora do escopo desta rodada

- Build AAB/APK.
- Build iOS.
- Billing server-side.
- E2E completo com Patrol.
- Camera/OCR real em aparelho fisico.
