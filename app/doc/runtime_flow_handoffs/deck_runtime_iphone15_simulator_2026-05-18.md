# Deck Runtime iPhone 15 Simulator - 2026-05-18

## Resultado

**PASS** para a UI de `functional_tags` na aba Analise do Deck no iPhone 15
Simulator contra backend local vivo.

## Data/hora

- Inicio da rodada: 2026-05-18 12:10 BRT
- Agente: Mobile Runtime Device QA

## Alvo mobile

- Simulator: iPhone 15
- ID: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`
- Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`
- Estado descoberto: Booted
- `flutter devices`: encontrou `iPhone 15 (mobile)` com o ID acima, alem de
  iPhone fisico, macOS e Chrome.

## Backend

- URL usada pelo app: `http://127.0.0.1:8081`
- Comando:
  `cd server && PORT=8081 dart run .dart_frog/server.dart`
- Health:
  `{"status":"healthy","service":"mtgia-server","environment":"development","version":"1.0.0","git_sha":null}`
- Backend publico informado na task:
  `https://evolution-cartinhas.8ktevp.easypanel.host` em
  `git_sha=4ec129f66053a4c22c217ef6727177308166ba2d` foi usado como contexto de
  contrato, nao como alvo runtime desta prova local.

## Comando runtime

```bash
cd app
flutter test integration_test/deck_functional_tags_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8081 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8081 \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

## O que foi real

- App Flutter compilado e executado no iPhone 15 Simulator.
- Backend local real em `127.0.0.1:8081`.
- Registro de usuario QA descartavel via API, token mantido apenas no runtime.
- Resolucao de cartas por `/cards`, criacao de deck sanitizado por `/decks`,
  abertura de detalhes por `/decks/:id` e leitura funcional por
  `/decks/:id/analysis`.
- UI real do `DeckAnalysisTab` renderizou a secao `Funcoes do deck`, origem
  `functional_tags`, bucket de ramp e amostra de carta.

## O que foi mockado

- Nada no runtime device.
- O teste nao usa scanner, camera, OCR, Sentry real nem Firebase startup.

## Evidencias

- Log sanitizado:
  `app/doc/runtime_flow_proofs_2026-05-18_iphone15_simulator/deck_functional_tags_runtime_sanitized.txt`
- Screenshots: nao capturados nesta rodada.
- Deck ID, UUIDs e dados sensiveis foram redigidos na evidencia persistida.

## Observacoes e riscos

- O Xcode emitiu aviso de plugins/transitivos sem suporte arm64 no simulador
  Apple Silicon/iOS 26+, mas a build e o teste passaram no iPhone 15 iOS 17.4.
- O deck usado e uma lista pequena de prova funcional, nao um Commander completo;
  o objetivo desta rodada era provar a UI/contrato de `functional_tags`, nao o
  fluxo completo de optimize.

## Menores proximas acoes

- Quando o backend publico estiver atualizado com o mesmo contrato, repetir a
  prova contra `https://evolution-cartinhas.8ktevp.easypanel.host` se for
  necessario validar release remoto.
