# Runtime testability handoff - iPhone 15 Simulator - 2026-05-08

## Resultado

**PASS WITH RISKS** para os gaps reais de testabilidade UI/runtime apos
`684ba3a`, `eb26435` e `c74bdc9`.

O escopo ficou restrito a keys, harnesses, helpers e docs. Nao houve alteracao
de backend, banco, IA, Scanner/camera/OCR ou regra de negocio.

## Ambiente

| Item | Valor |
|---|---|
| Branch | `master` |
| Backend publico | `https://evolution-cartinhas.8ktevp.easypanel.host` |
| Backend `/health` | `healthy`, `git_sha=c74bdc92d30538105cd79cf2ce543296c5736084` |
| Device | iPhone 15 Simulator |
| UDID | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime | iOS 17.4 |
| Estado | Booted |

Observacao: o Flutter emitiu o aviso conhecido de plugins iOS/arm64 para
simuladores iOS 26+, mas os testes abaixo compilaram e executaram no iPhone 15
iOS 17.4.

## Superficies cobertas

| Area | Resultado |
|---|---|
| Criar deck | Keys de dialog/campos/acoes adicionadas e usadas por runtime. |
| Importar lista | Keys separadas para dialog no deck e tela full-screen. |
| Community/User search | Campos, listas e rows por `userId`/`deckId`. |
| Optimize | Preview, apply, no-op/outcome, rebuild e snackbars de erro amigavel por key. |
| Search/Sets | Linha de set por `setCode`; detalhe aceita lista ou empty state por key. |
| Life Counter/Lotus | Overlays/sheets principais ancorados por key. |
| Helpers runtime | Harnesses migrados para `runtime_test_helpers.dart` onde havia espera generica duplicada. |

## Comandos executados

```bash
cd app && flutter analyze lib test integration_test --no-version-check
cd app && flutter test test --no-version-check
cd app && flutter test integration_test/sets_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --reporter expanded --no-version-check
cd app && flutter test integration_test/collection_entrypoints_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --reporter expanded --no-version-check
cd app && flutter test integration_test/profile_community_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --reporter expanded --no-version-check
cd app && flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --reporter expanded --no-version-check
```

## Evidencias

| Prova | Resultado |
|---|---|
| Analyze app | PASS |
| Unit/widget tests app | PASS |
| `sets_catalog_runtime_test.dart` | PASS no iPhone 15 Simulator |
| `collection_entrypoints_runtime_test.dart` | PASS no iPhone 15 Simulator |
| `profile_community_runtime_test.dart` | PASS no iPhone 15 Simulator |
| `deck_runtime_m2006_test.dart` | PASS no iPhone 15 Simulator (`00:38 +1: All tests passed!`) |

No `deck_runtime_m2006_test.dart`, o backend publico retornou uma falha
amigavel para o job async de Optimize. O harness validou o fallback por
`optimize-ai-error-snackbar`/`optimize-apply-error-snackbar` e confirmou ausencia
de copy tecnica sensivel como "executor interno" ou "resposta invalida" na UI.
Como `RUNTIME_OPTIMIZE_REQUIRE_APPLY` nao foi habilitado, esse caminho e aceito
como prova de fallback runtime, nao como prova de apply.

## Riscos restantes

- Nem todos os harnesses modificados foram executados isoladamente no simulador
  nesta rodada; Binder/Marketplace/Trades e o smoke visual amplo ficaram sem
  nova prova runtime, embora analyze/testes unitarios tenham passado e os
  seletores tenham sido migrados.
- Labels de tabs, textos de confirmacao e evidencias visuais nao-acionaveis
  ainda podem usar `find.text` como fallback documentado em
  `app/doc/UI_TEST_SURFACE_MAP.md`.
- Scanner/camera/OCR permaneceram fora de escopo.
