# Commander Reference Sprint 3 Lote C app runtime - 2026-05-14

## Resultado

**PASS_WITH_RISKS** em 2026-05-14T11:24-03:00.

O fluxo mobile real passou no Android fisico solicitado `SM A135M`
(`R58T300SREH`, Android 14/API 34) contra o backend publico
`https://evolution-cartinhas.8ktevp.easypanel.host`. Brago passou como
comandante Lote C promovido; Purphoros tambem passou no app/runtime, mas segue
marcado como **nao promovido no backend** conforme o public proof/scorecard do
Lote C.

## Fontes lidas antes da validacao

- `.github/instructions/guia.instructions.md`
- `app/doc/UI_TEST_SURFACE_MAP.md`
- `app/doc/runtime_flow_handoffs/README.md`
- `app/doc/runtime_flow_handoffs/deck_runtime_2026-04-27.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_PUBLIC_PROOF_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_ONLY_OPTIMIZATION_VALIDATION_2026-04-21.md`
- `server/doc/RELATORIO_META_DECK_INTELLIGENCE_2026-04-24.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/manual-de-instrucao.md`

## Repositorio/branch

- Branch alvo: `master`.
- HEAD local durante runtime: `ef2df98abb9bb8cb2d4b03ca1d3c5d1123da3c86`.
- Backend publico `/health.git_sha` durante runtime:
  `ef2df98abb9bb8cb2d4b03ca1d3c5d1123da3c86`.

## Devices/backend

- Primario usado: `SM A135M` (`R58T300SREH`), Android 14/API 34.
- `flutter devices`: listou `SM A135M • R58T300SREH • android-arm • Android 14
  (API 34)`.
- Fallback descoberto, nao usado porque o Android primario passou: iPhone 15
  Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, iOS 17.4, Booted.
- Backend usado pelo app:
  `https://evolution-cartinhas.8ktevp.easypanel.host`.
- `/health`: HTTP 200, `status=healthy`,
  `git_sha=ef2df98abb9bb8cb2d4b03ca1d3c5d1123da3c86`, latencia app-side
  1385ms.

## Comandos executados

Discovery e backend:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short --branch
git fetch origin master --quiet
git pull --ff-only origin master
git rev-parse HEAD origin/master
cd app && flutter devices --no-version-check
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
adb devices -l
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
```

Runtime final:

```bash
mkdir -p app/doc/runtime_flow_proofs_2026-05-14_commander_reference_sprint3_lot_c_app
adb -s R58T300SREH shell svc wifi disable
cd app
flutter test integration_test/commander_reference_sprint3_lot_c_app_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
adb -s R58T300SREH shell svc wifi enable
```

Validacao local:

```bash
cd app
flutter analyze lib/features/decks test/features/decks integration_test --no-version-check
flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart --no-version-check
flutter test test/features/decks/screens/deck_details_screen_smoke_test.dart \
  test/features/decks/providers/deck_provider_test.dart \
  test/features/decks/providers/deck_provider_support_test.dart \
  test/features/decks/widgets/deck_optimize_flow_support_test.dart \
  --no-version-check
```

## Resultado por comandante

| Commander | Arquetipo | Promovido no backend | Resultado app/API |
| --- | --- | --- | --- |
| `Brago, King Eternal` | Azorius blink/ETB | Sim | PASS: `validation_ok=true`, `main_qty=99`, `total_with_commander=100`, `commander_count=1`, `commander_in_99_count=0`, `off_identity_count=0`. |
| `Purphoros, God of the Forge` | Mono-red tokens/burn | Nao | PASS app-runtime adjunct: `validation_ok=true`, `main_qty=99`, `total_with_commander=100`, `commander_count=1`, `commander_in_99_count=0`, `off_identity_count=0`; nao conta como segundo promovido ate o scorecard backend passar. |

Observacao de contrato: em `GET /decks/:id`, o campo agregado
`commander_name` nao veio igual ao comandante, mas a lista `commander` retornou
exatamente uma entrada correta e a validacao DB-backed passou. A prova usou
`commander`/`deck_cards.is_commander` como fonte de verdade.

## Evidencia sanitizada

Diretorio:

- `app/doc/runtime_flow_proofs_2026-05-14_commander_reference_sprint3_lot_c_app/`

Log:

- `commander_reference_sprint3_lot_c_app_runtime_sm_a135m_2026-05-14_sanitized.log`

Screenshots:

- `commander_reference_lot_c_01_login.png`
- `commander_reference_lot_c_02_registered.png`
- `commander_reference_lot_c_03_logged_in.png`
- `commander_reference_lot_c_brago_01_generate_screen.png`
- `commander_reference_lot_c_brago_02_preview.png`
- `commander_reference_lot_c_brago_03_details.png`
- `commander_reference_lot_c_purphoros_01_generate_screen.png`
- `commander_reference_lot_c_purphoros_02_preview.png`
- `commander_reference_lot_c_purphoros_03_details.png`

## O que foi real, mockado e nao provado

- Real: device fisico Android, app Flutter instalado pelo runner, backend
  publico, register/login, Generate Commander com `commander_name`, preview,
  save, Deck Details e validacao via API.
- Mockado: nada.
- Nao provado nesta rodada: iPhone 15 Simulator, porque o Android primario
  passou; segundo comandante Lote C promovido, porque o backend/tracker ainda
  marca Purphoros, Veyran e Balan como `promoted=false`.

## Riscos e menores proximas acoes

| Risco | Evidencia | Menor proxima acao |
| --- | --- | --- |
| O objetivo literal "2 comandantes promovidos" nao e satisfazivel pelo estado atual do Lote C. | `RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_PUBLIC_PROOF_2026-05-14.md` e tracker marcam apenas Brago como promovido; Purphoros e app-runtime valid, mas `promoted_on_backend=false`. | Corrigir/aplicar profile, card stats e fallback deterministico para Purphoros/Veyran/Balan e repetir public proof + scorecard antes de declarar segundo promovido. |
| Runtime publico no `SM A135M` ainda dependeu de rede celular. | O Wi-Fi foi desabilitado antes da prova final para evitar o timeout app-side ja documentado no Lote A; o fluxo passou em rede celular. | Diagnosticar DNS/Private DNS/rede local antes de exigir prova Wi-Fi no Android. |
| `commander_name` agregado do detalhe nao refletiu o comandante salvo. | `commander` continha 1 entrada correta e `/validate` passou; UI/details nao quebraram. | Auditar preenchimento de `decks.commander_name`/summary se esse campo virar fonte visual obrigatoria. |

Resultado final desta rodada: **PASS_WITH_RISKS**.
