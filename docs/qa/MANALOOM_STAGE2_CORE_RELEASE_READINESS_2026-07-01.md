# ManaLoom Stage 2 - Core Release Readiness

Data: 2026-07-01
Escopo: Etapa 2 do goal de produto - fechar o core para lancamento.
Status da etapa: concluida como readiness operacional, com core validado em testes locais, backend publico e smoke mobile Android.

## 1. Veredito

O core de decks esta forte em validacao local/offline, contratos de backend,
smokes publicos com escrita controlada e smoke mobile Android contra a API
publica. A Etapa 2 agora sustenta teste interno real.

Ainda nao deve ser declarado release publico/comercial porque faltam assinatura
de distribuicao, Sentry mobile configurado/confirmado e smoke de aceitacao final
com build assinado de loja.

Classificacao:

- Core local/offline: `PASS`.
- Backend publico read-only do core: `PASS`.
- Fluxos publicos controlados com usuario/deck real: `PASS_PUBLIC_CONTROLLED`.
- Smoke mobile Android de importacao localizada: `PASS_DEVICE`.
- APK release Android com API publica instalado/aberto: `PASS_INTERNAL_UNSIGNED`.
- Release publico do core: `NO-GO` ate assinatura real, Sentry e aceite final.

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

### Backend publico com escrita controlada

Backend alvo:

`https://evolution-cartinhas.8ktevp.easypanel.host`

Comando:

```bash
cd server
TEST_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host dart test -t live --concurrency=1 \
  test/auth_flow_integration_test.dart \
  test/import_to_deck_flow_test.dart \
  test/core_flow_smoke_test.dart \
  -r expanded
```

Resultado consolidado:

- `test/auth_flow_integration_test.dart`: 2 testes passaram.
- `test/import_to_deck_flow_test.dart`: 6 testes passaram apos alinhar o teste
  para usuario unico e lista Commander completa.
- `test/core_flow_smoke_test.dart`: 2 testes passaram apos alinhar o teste para
  usuario unico e registro antes de login.

Comando complementar:

```bash
cd server
dart test test/deck_pricing_export_community_contract_test.dart -r expanded
```

Resultado:

- 3 testes passaram.

Observacao operacional:

- Os smokes criaram usuarios/decks de teste no backend publico.
- Os decks criados pelos testes foram removidos pelos `tearDown`.
- Usuarios de teste podem permanecer como residuos aceitaveis de QA.

### Smoke mobile Android contra API publica

Dispositivo:

- `SM A135M`, id `R58T300SREH`, Android 14/API 34.

Comando:

```bash
cd app
flutter test integration_test/localized_import_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --no-version-check \
  --reporter expanded
```

Resultado:

- `All tests passed`.
- `POST /auth/register -> 201`.
- `POST /import/validate -> 200`.
- `POST /import -> 200`.
- Resumo emitido:
  `found_count=12`, `localized_matches_count=9`,
  `commander_detected=true`, `missing_commander=false`.
- Deck criado no smoke `f4d529aa-abdc-41fd-90c3-4316d34e1deb` foi removido com
  `DELETE /decks/... -> 204`.

Conclusao:

- Importacao localizada em portugues funciona no runtime mobile Android contra o backend publico.
- A regra atual de Commander completo esta respeitada: 99 cartas na lista mais comandante em campo separado.

### Build Android com API publica

Comandos executados:

```bash
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=SENTRY_ENVIRONMENT=staging \
  --dart-define=SENTRY_RELEASE=mtgia-ready-2026-07-01 \
  --dart-define=SENTRY_TRACES_SAMPLE_RATE=1.0 \
  --no-version-check

flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=SENTRY_ENVIRONMENT=staging \
  --dart-define=SENTRY_RELEASE=mtgia-ready-2026-07-01 \
  --dart-define=SENTRY_TRACES_SAMPLE_RATE=1.0 \
  --no-version-check
```

Resultado final observado:

- `build/app/outputs/flutter-apk/app-release.apk`, gerado em
  `2026-07-01 10:50:55`, `114044826` bytes.
- `build/app/outputs/bundle/release/app-release.aab`, gerado em
  `2026-07-01 10:51:16`, `75806976` bytes.
- `apksigner verify --print-certs` no APK release confirmou assinatura
  `C=US, O=Android, CN=Android Debug`.

Instalacao/abertura do APK release:

```bash
adb -s R58T300SREH install -r app/build/app/outputs/flutter-apk/app-release.apk
adb -s R58T300SREH shell monkey -p com.mtgia.mtg_app -c android.intent.category.LAUNCHER 1
adb -s R58T300SREH shell pidof com.mtgia.mtg_app
```

Resultado:

- Instalacao: `Success`.
- App aberto no dispositivo.
- `pidof com.mtgia.mtg_app` retornou `21012` apos reinstalar o APK release no final.

Conclusao:

- Compilacao Android com a API publica: `PASS`.
- Instalacao e abertura do APK release em Android fisico: `PASS_INTERNAL`.
- Distribuicao Play Store equivalente: `NO-GO` sem keystore real.

## 4. Matriz de criterios da Etapa 2

| Criterio | Status | Evidencia | Observacao |
|---|---|---|---|
| Onboarding em sessao limpa preserva formato escolhido | PASS_LOCAL | `deck_flow_entry_screens_test.dart` passou | Falta aceite manual/final em build assinado |
| Gerar deck via IA funciona | PASS_PUBLIC_CONTROLLED | `core_flow_smoke_test.dart` passou contra API publica | Falta aceite visual em build assinado |
| Importar deck funciona | PASS_PUBLIC_DEVICE | `import_to_deck_flow_test.dart` e `localized_import_runtime_test.dart` passaram | Teste mobile validou import localizado, nao todo o fluxo visual |
| Deck details carrega estados principais | PASS_LOCAL | `deck_details_screen_smoke_test.dart` passou | Precisa smoke visual/build real para release |
| Analise mostra dados do deck | PASS_CONTRACT | App/backend tests cobrem parsing/analysis/diagnostics | Public runtime nao reexecutado nesta etapa |
| Optimize focado retorna preview aplicavel | PASS_PUBLIC_CONTROLLED | `core_flow_smoke_test.dart` passou contra API publica | Falta aceite visual em build assinado |
| Apply salva e valida deck final | PASS_PUBLIC_CONTROLLED | `core_flow_smoke_test.dart` passou contra API publica | Falta aceite visual em build assinado |
| Export/share/copy funciona | PASS_CONTRACT | `deck_pricing_export_community_contract_test.dart` passou | Share nativo ainda precisa aceite em build assinado |
| Falha de IA tem UX segura | PASS_LOCAL | `needs_repair`, no-op e erro amigavel cobertos | Boa base para tester interno |
| Fluxo completo passa em build real | PARTIAL_DEVICE | APK release instalado/aberto e smoke mobile de import passou | Falta build assinado de distribuicao e aceite completo |

## 5. Bloqueios remanescentes para release publico

### Bloqueio 1 - Assinatura de distribuicao

O APK/AAB release local foi gerado, instalado e aberto, mas o certificado atual
e `C=US, O=Android, CN=Android Debug` porque `app/android/key.properties` nao
existe neste ambiente.

Status: `BLOCKED_BY_SIGNING`.

### Bloqueio 2 - Aceite visual completo em build assinado

O backend publico e o mobile import smoke passaram. Ainda falta o roteiro final
de aceite em build assinado:

- abrir app em sessao limpa;
- registrar/logar;
- gerar ou importar deck;
- abrir detalhes;
- analisar/otimizar/aplicar;
- exportar/compartilhar;
- registrar evidencias visuais finais.

Status: `PARTIAL_DEVICE`.

### Bloqueio 3 - Observabilidade de release

Sentry mobile ainda nao esta configurado neste ambiente; a Etapa 3 detalha o
bloqueio. Sem ingestao real, falhas de usuarios externos ficam menos
rastreaveis.

Status: `BLOCKED_BY_SENTRY_DSN`.

## 6. Testes live usados para fechar o gap publico

Inventario executado nesta etapa:

- `server/test/auth_flow_integration_test.dart`
- `server/test/import_to_deck_flow_test.dart`
- `server/test/core_flow_smoke_test.dart`
- `server/test/deck_pricing_export_community_contract_test.dart`
- `app/integration_test/localized_import_runtime_test.dart`

Observacao:

Esses testes escrevem em ambiente publico. Foram executados como smoke
controlado apos solicitacao de continuidade do trabalho. Mantem-se a regra:
qualquer novo backfill ou escrita manual em PostgreSQL continua exigindo escopo
explicito.

## 7. Conclusao da Etapa 2

A Etapa 2 esta concluida para teste interno e preparacao de release:

- O core local/offline passou.
- O backend publico read-only passou.
- Os smokes publicos com usuario/deck real passaram.
- O smoke mobile Android de importacao localizada passou.
- O APK release com API publica foi instalado e aberto no Android fisico.

O release publico ainda nao deve ser anunciado porque faltam assinatura real,
observabilidade mobile com Sentry e aceite final do build assinado.
