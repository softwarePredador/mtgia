# Commander Reference Sprint 3 Lote A app runtime - 2026-05-14

## Resultado

**PASS_WITH_RISKS** em 2026-05-14T09:10-03:00.

O fluxo mobile real foi rerodado no Android fisico solicitado `SM A135M`
(`R58T300SREH`, Android 14/API 34) contra o backend publico
`https://evolution-cartinhas.8ktevp.easypanel.host`. Krenko e Teysa passaram por
register/login, Generate Commander com `commander_name`, preview, save, Deck
Details e validacao por `/decks/:id/validate`.

## Fontes lidas antes da validacao

- `.github/instructions/guia.instructions.md`
- `app/doc/UI_TEST_SURFACE_MAP.md`
- `app/doc/runtime_flow_handoffs/README.md`
- `app/doc/runtime_flow_handoffs/deck_runtime_2026-04-27.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_FINAL_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_PUBLIC_PROOF_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_ONLY_OPTIMIZATION_VALIDATION_2026-04-21.md`
- `server/doc/RELATORIO_META_DECK_INTELLIGENCE_2026-04-24.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/manual-de-instrucao.md`

## Repositorio/branch

- Branch alvo: `master`.
- HEAD local durante runtime: `40c71f905af6a3389f37bc4e1085e71dd26a414b`.
- Backend publico `/health.git_sha` durante runtime:
  `40c71f905af6a3389f37bc4e1085e71dd26a414b`.

## Devices/backend

- Primario usado: `SM A135M` (`R58T300SREH`), Android 14/API 34.
- `flutter devices`: listou `SM A135M • R58T300SREH • android-arm • Android 14
  (API 34)`.
- Fallback descoberto, nao usado para prova final porque o Android passou:
  iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, iOS 17.4,
  Booted.
- Backend usado pelo app:
  `https://evolution-cartinhas.8ktevp.easypanel.host`.
- `/health`: HTTP 200, `status=healthy`, `git_sha=40c71f905af6a3389f37bc4e1085e71dd26a414b`,
  latencia app-side 1458ms.

## Diagnostico do BLOCKED anterior

O BLOCKED de 2026-05-13 tinha dois sintomas:

1. Android: build/install e redirect para `/login` passavam, mas o harness ficava
   preso antes da primeira interacao. O arquivo especifico do Lote A ainda usava
   helpers locais `_waitUntilFound/_waitUntilAnyFound` com `runAsync`, duplicando
   o helper compartilhado de runtime e deixando o timeout opaco.
2. iPhone 15 Simulator: o build seguia bloqueado por `MLImage.framework` com
   objeto `arm64` construido para iOS device, nao iOS Simulator.

Na rodada de 2026-05-14 tambem apareceu um blocker ambiental novo no Wi-Fi do
Android: o app dentro do device fazia timeout em `/health` apos 15s, enquanto o
Mac respondia em ~0.6s e o device pingava o host. A prova passou ao desabilitar
temporariamente o Wi-Fi e usar a rede celular do aparelho; o Wi-Fi foi reabilitado
ao final.

## Correcao aplicada

- `app/integration_test/commander_reference_sprint3_lot_a_app_runtime_test.dart`
  deixou de usar helpers locais duplicados e passou a usar
  `pumpUntilFound/pumpUntilAnyFound` de
  `app/integration_test/runtime_test_helpers.dart`.
- O primeiro checkpoint de login passou a ancorar no texto visivel `Entrar` e
  capturar screenshot antes de tocar no botao com key
  `login-open-register-button`.
- Nenhum endpoint, payload, provider, contrato backend ou scanner/camera/OCR foi
  alterado.

## Comandos executados

Discovery e backend:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short
flutter devices --no-version-check
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
adb devices
curl -sS https://evolution-cartinhas.8ktevp.easypanel.host/health
curl -sS https://evolution-cartinhas.8ktevp.easypanel.host/git_sha
```

Runtime final:

```bash
cd app
flutter test integration_test/commander_reference_sprint3_lot_a_app_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Observacao operacional: antes do runtime final, `adb -s R58T300SREH shell svc wifi
disable` foi usado para contornar o timeout HTTP do Wi-Fi do aparelho; ao final
foi executado `adb -s R58T300SREH shell svc wifi enable`.

## Resultado por comandante

| Commander | Arquétipo | Resultado app/API |
| --- | --- | --- |
| `Krenko, Mob Boss` | mono-red Goblins aggro | PASS: `validation_ok=true`, `main_qty=99`, `total_with_commander=100`, `commander_count=1`, `commander_in_99_count=0`, `off_identity_count=0`. |
| `Teysa Karlov` | Orzhov aristocrats | PASS: `validation_ok=true`, `main_qty=99`, `total_with_commander=100`, `commander_count=1`, `commander_in_99_count=0`, `off_identity_count=0`. |

## Evidencia sanitizada

Diretorio:

- `app/doc/runtime_flow_proofs_2026-05-14_commander_reference_sprint3_lot_a_app/`

Log:

- `commander_reference_sprint3_lot_a_app_runtime_sm_a135m_2026-05-14_sanitized.log`

Screenshots:

- `commander_reference_lot_a_01_login.png`
- `commander_reference_lot_a_02_registered.png`
- `commander_reference_lot_a_03_logged_in.png`
- `commander_reference_lot_a_krenko_01_generate_screen.png`
- `commander_reference_lot_a_krenko_02_preview.png`
- `commander_reference_lot_a_krenko_03_details.png`
- `commander_reference_lot_a_teysa_01_generate_screen.png`
- `commander_reference_lot_a_teysa_02_preview.png`
- `commander_reference_lot_a_teysa_03_details.png`

## O que foi real, mockado e nao provado

- Real: device fisico Android, app Flutter instalado pelo runner, backend publico,
  register/login, Generate Commander, preview, save, Deck Details e validacao via
  API.
- Mockado: nada.
- Nao provado nesta rodada: iPhone 15 Simulator, porque o Android primario passou
  e o blocker historico de `MLImage.framework` no simulador permanece conhecido.

## Riscos e menores proximas acoes

| Risco | Evidencia | Menor proxima acao |
| --- | --- | --- |
| Wi-Fi do `SM A135M` causa timeout HTTP app-side para o backend publico. | Mac respondeu `/health` em ~0.6s; device pingou o host; app no Wi-Fi timeoutou em 15s; celular passou. | Validar DNS/Private DNS/rede `Predador - Mobile` ou manter cellular como workaround para runtimes publicos ate estabilizar. |
| iPhone 15 Simulator segue bloqueado por MLImage/scanner. | Mesmo blocker documentado em 2026-05-13. | Isolar scanner/MLKit do target de integration tests ou atualizar dependencia para slice `arm64-simulator`. |

Resultado final desta rodada: **PASS_WITH_RISKS**.
