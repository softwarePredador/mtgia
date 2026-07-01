# ManaLoom Stage 2 - Core Release Readiness

Data: 2026-07-01
Escopo: Etapa 2 do goal de produto - fechar o core para lancamento.
Status da etapa: concluida como avaliacao de readiness, com bloqueios objetivos para declarar release publico.

## 1. Veredito

O core de decks esta forte em validacao local/offline e em contratos de backend, mas ainda nao pode ser declarado pronto para release publico porque o fluxo completo contra backend publico exige escrita em PostgreSQL publico e/ou build real, ambos fora do escopo sem aprovacao explicita.

Classificacao:

- Core local/offline: `PASS`.
- Backend publico read-only do core: `PASS`.
- Fluxo publico completo com usuario/deck real: `BLOCKED_BY_APPROVAL`.
- Build Android com API publica: `PASS_COMPILE_UNSIGNED`.
- Release publico do core: `NO-GO` ate smoke E2E instalado/executado e assinatura real.

## 2. Fluxo alvo da Etapa 2

`usuario novo -> onboarding -> gerar/importar deck -> abrir detalhes -> analisar -> otimizar -> aplicar -> validar -> exportar/compartilhar`

## 3. Evidencias executadas nesta etapa

### App core recomendado

Comando:

```bash
cd app
flutter test \
  test/features/decks/models/deck_card_item_test.dart \
  test/features/decks/models/deck_details_test.dart \
  test/features/decks/models/deck_test.dart \
  test/features/decks/providers/deck_provider_test.dart \
  test/features/decks/screens/deck_flow_entry_screens_test.dart \
  test/features/decks/widgets/deck_diagnostic_panel_test.dart \
  test/features/decks/widgets/sample_hand_widget_test.dart \
  test/features/decks/widgets/deck_card_overflow_test.dart
```

Resultado:

- `All tests passed`.
- Total observado: 72 testes/casos.

Cobertura relevante:

- Models de deck/card.
- Provider de deck.
- Generate async e fallback.
- Formato vindo do onboarding para generate/import.
- Learned deck shortcut.
- Core smoke `deck details -> optimize -> apply with ids -> validate`.
- Overflow/robustez visual de cards.
- Diagnostic panel e sample hand.

### App details/import/optimize

Comando:

```bash
cd app
flutter test \
  test/features/decks/screens/deck_details_screen_smoke_test.dart \
  test/features/decks/screens/deck_import_screen_test.dart \
  test/features/decks/widgets/deck_details_actions_test.dart \
  test/features/decks/widgets/deck_details_dialogs_test.dart \
  test/features/decks/widgets/deck_details_overview_tab_test.dart \
  test/features/decks/widgets/deck_import_list_dialog_test.dart \
  test/features/decks/widgets/deck_optimize_dialogs_test.dart \
  test/features/decks/widgets/deck_optimize_flow_support_test.dart
```

Resultado:

- `All tests passed`.
- Total observado: 65 testes/casos.

Cobertura relevante:

- Loading/error/empty/success em deck details.
- Import screen e import dialog.
- Optimize preview/apply.
- `needs_repair -> rebuild_guided`.
- Deselect de sugestoes.
- Feedback de no-op/erro/falha amigavel.
- Overview actions.

### Backend offline padrao

Comando:

```bash
cd server
dart test
```

Resultado:

- `All tests passed`.
- Total observado: 625 testes/casos.
- Skips declarados: 9.

Cobertura relevante:

- Auth service.
- Deck validation.
- Import parser/list service.
- Card resolution.
- Generate/optimize support.
- Optimization validator/rules.
- Rate limit.
- Contratos offline do backend.

### Backend publico read-only

Backend alvo:

`https://evolution-cartinhas.8ktevp.easypanel.host`

Probes executados:

- `GET /ready` com `x-request-id: stage2-core-ready-20260701`
  - HTTP 200.
  - Header retornado: `x-request-id: stage2-core-ready-20260701`.
  - `status=ready`.
  - `cards_data.card_count=34331`.
- `GET /cards?name=Sol%20Ring&limit=1`
  - HTTP 200.
  - Retornou `Sol Ring`.
- `GET /cards?name=Command%20Tower&limit=1`
  - HTTP 200.
  - Retornou `Command Tower`.
- `GET /sets?limit=1`
  - HTTP 200.
  - Retornou payload de set.

Conclusao:

- API publica esta viva.
- Catalogo e busca de cartas funcionam em leitura.
- Request-id manual e preservado em readiness.

### Build Android com API publica

Comandos executados:

```bash
cd app
flutter build apk --debug \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --no-version-check

flutter build apk --release \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --no-version-check

flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --no-version-check
```

Resultado:

- `build/app/outputs/flutter-apk/app-debug.apk` gerado em `2026-07-01 10:07:28`, `237M`.
- `build/app/outputs/flutter-apk/app-release.apk` gerado em `2026-07-01 10:07:55`, `110M`.
- `build/app/outputs/bundle/release/app-release.aab` gerado em `2026-07-01 10:08:28`, `74M`.
- `apksigner verify --print-certs` no APK release confirmou assinatura
  `C=US, O=Android, CN=Android Debug`.

Conclusao:

- Compilacao Android com a API publica: `PASS`.
- Distribuicao Play Store/TestFlight equivalente: `NO-GO` sem keystore real e
  sem smoke instalado/executado.

## 4. Matriz de criterios da Etapa 2

| Criterio | Status | Evidencia | Observacao |
|---|---|---|---|
| Onboarding em sessao limpa preserva formato escolhido | PASS_LOCAL | `deck_flow_entry_screens_test.dart` passou | Ainda falta build real/sessao limpa end-to-end |
| Gerar deck via IA funciona | PASS_CONTRACT | Provider/generate async/fallback passaram | Public E2E com escrita nao executado sem aprovacao |
| Importar deck funciona | PASS_LOCAL | `deck_import_screen_test.dart` e import dialog passaram | Public E2E com escrita nao executado |
| Deck details carrega estados principais | PASS_LOCAL | `deck_details_screen_smoke_test.dart` passou | Precisa smoke visual/build real para release |
| Analise mostra dados do deck | PASS_CONTRACT | App/backend tests cobrem parsing/analysis/diagnostics | Public runtime nao reexecutado nesta etapa |
| Optimize focado retorna preview aplicavel | PASS_LOCAL | Details smoke e provider core smoke passaram | Public runtime nao executado sem escrita |
| Apply salva e valida deck final | PASS_LOCAL | Provider/tela simulam apply + validate | Public write smoke pendente |
| Export/share/copy funciona | PARTIAL | Contratos existem; nao foi foco executado nesta etapa | Precisa smoke especifico em build alvo |
| Falha de IA tem UX segura | PASS_LOCAL | `needs_repair`, no-op e erro amigavel cobertos | Boa base para tester interno |
| Fluxo completo passa em build real | PARTIAL_BUILD_ARTIFACT | APK debug, APK release e AAB release compilados com API publica | Nao instalado/executado; release assinado com debug por falta de keystore |

## 5. Bloqueios para declarar a Etapa 2 como release-ready

### Bloqueio 1 - Escrita no backend publico

Os testes live recomendados pelo backend escrevem via API:

- criam usuario;
- criam deck;
- chamam IA;
- salvam/validam deck;
- podem gerar logs/uso/custos.

Por regra operacional do projeto, isso nao deve ser feito contra PostgreSQL publico sem aprovacao explicita.

Status: `BLOCKED_BY_APPROVAL`.

### Bloqueio 2 - Smoke instalado em build real

Os testes locais e a compilacao Android provam contratos, UI simulada e
empacotamento tecnico, mas nao substituem:

- build iOS/Android;
- device/simulator com `API_BASE_URL` publico;
- login/register real;
- generate/import real;
- save/apply/validate real.

Status: `PARTIAL_BUILD_ARTIFACT`, ainda `BLOCKED_BY_RELEASE_SMOKE` para fluxo
executado.

### Bloqueio 3 - Export/share em build alvo

Export/share depende de integracao mobile e plataforma. Nao foi validado nesta etapa.

Status: `PARTIAL`.

## 6. Testes live existentes que podem fechar o gap com aprovacao

Inventario do backend:

- `server/test/core_flow_smoke_test.dart`
- `server/test/ai_generate_create_optimize_flow_test.dart`
- `server/test/ai_optimize_flow_test.dart`
- `server/test/import_to_deck_flow_test.dart`
- `server/test/deck_analysis_contract_test.dart`
- `server/test/decks_crud_test.dart`
- `server/test/decks_incremental_add_test.dart`
- `server/test/auth_flow_integration_test.dart`

Comando base documentado:

```bash
cd server
TEST_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host dart test -t live \
  test/auth_flow_integration_test.dart \
  test/core_flow_smoke_test.dart \
  test/import_to_deck_flow_test.dart \
  test/deck_analysis_contract_test.dart
```

Observacao:

Esse comando deve ser tratado como escrita em ambiente publico. Rodar apenas apos aprovacao explicita.

## 7. Conclusao da Etapa 2

A Etapa 2 esta concluida como diagnostico operacional do core:

- O core local/offline passou.
- O backend publico read-only passou.
- A malha automatizada existente e suficiente para sustentar proximo smoke real.
- O build Android com API publica compila.
- O release-ready publico ainda esta bloqueado por falta de E2E publico com
  escrita controlada, smoke instalado/executado e keystore real.

Proxima acao recomendada:

1. Obter aprovacao explicita para smoke publico com usuario/deck de teste, ou preparar ambiente staging isolado.
2. Rodar `core_flow_smoke_test.dart` e `import_to_deck_flow_test.dart` contra o alvo aprovado.
3. Rodar build real do app com `API_BASE_URL` publico/staging.
4. Atualizar este documento com `PASS_PUBLIC_E2E` quando essas provas existirem.
