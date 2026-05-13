# Commander Reference Sprint 3 Lote A app runtime - 2026-05-13

## Resultado

**BLOCKED** em 2026-05-13T19:39-03:00.

O backend publico e o build Android foram alcançados, mas o fluxo mobile
register/login -> Generate Commander -> save -> Deck Details -> validate nao foi
provado nesta rodada porque o runner travou antes da primeira interacao de UI no
Android fisico e o fallback iPhone 15 Simulator ficou bloqueado por dependencia
nativa iOS Simulator.

## Fonte lida antes da validacao

- `.github/instructions/guia.instructions.md`
- `app/doc/UI_TEST_SURFACE_MAP.md`
- `app/doc/runtime_flow_handoffs/README.md`
- `app/doc/runtime_flow_handoffs/deck_runtime_2026-04-27.md`
- `server/doc/RELATORIO_COMMANDER_ONLY_OPTIMIZATION_VALIDATION_2026-04-21.md`
- `server/doc/RELATORIO_META_DECK_INTELLIGENCE_2026-04-24.md`
- `server/manual-de-instrucao.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_PUBLIC_PROOF_2026-05-13.md`

## Repositorio/branch

- Branch alvo: `master`.
- Sync: `git fetch --prune origin` + `git pull --ff-only origin master` retornou `Already up to date`.
- HEAD local durante runtime: `9f4d56163d6d59c3297b2cea848a3d8cd5c7a143`.
- Backend publico `/health.git_sha`: `9f4d56163d6d59c3297b2cea848a3d8cd5c7a143`.

## Comandantes escolhidos

Escolhidos de arquetipos diferentes a partir do public proof Lote A:

| Commander | Arquétipo usado no app | Motivo |
| --- | --- | --- |
| `Krenko, Mob Boss` | mono-red Goblins aggro | Prova Lote A promovida e arquétipo agressivo/tribal. |
| `Teysa Karlov` | Orzhov aristocrats | Prova Lote A promovida e arquétipo sacrifice/death triggers. |

## Devices/backend

- Device primario solicitado: Android fisico `SM A135M`, id `R58T300SREH`, Android 14/API 34.
- `flutter devices`: listou `SM A135M (mobile) • R58T300SREH • android-arm • Android 14 (API 34)`.
- Fallback disponivel: iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, iOS 17.4, Booted.
- Backend usado pelo app: `https://evolution-cartinhas.8ktevp.easypanel.host`.
- `/health`: HTTP 200, `status=healthy`, `git_sha=9f4d56163d6d59c3297b2cea848a3d8cd5c7a143`.

## Harness criado

- `app/integration_test/commander_reference_sprint3_lot_a_app_runtime_test.dart`
- Escopo: register/login pela UI, gerar Commander com `commander_name`, salvar,
  abrir Deck Details e validar por `/decks/:id/validate`.
- Assertions planejadas por comandante: `validation_ok=true`, `main_qty=99`,
  `total_with_commander=100`, `commander_count=1`,
  `commander_in_99_count=0`, `off_identity_count=0`.
- Scanner/camera/OCR nao usados.

## Comandos executados

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short
flutter devices
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
curl -sS https://evolution-cartinhas.8ktevp.easypanel.host/health
```

Android principal:

```bash
cd app
flutter test integration_test/commander_reference_sprint3_lot_a_app_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --reporter expanded \
  --no-version-check
```

Resultado Android: build/install passaram, `/health` passou, mas o teste ficou
preso apos o redirect para `/login` e encerrou por timeout do runner antes da
primeira interacao/capture. O mesmo sintoma foi reproduzido no harness Android
ja existente `commander_reference_app_value_runtime_test.dart`, indicando blocker
ambiental do runner/device nesta sessao, nao falha especifica do Lote A.

Fallback iPhone 15 Simulator:

```bash
cd app
flutter test integration_test/commander_reference_sprint3_lot_a_app_runtime_test.dart \
  -d F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --reporter expanded \
  --no-version-check
```

Resultado iPhone: build bloqueado por arquitetura nativa. Com a configuracao
historica (`arm64 i386` excluidos do simulador), Xcode/iOS 26+ reportou que o
simulador Apple Silicon exige `arm64`. A tentativa controlada de permitir
`arm64` confirmou o blocker inverso: `MLImage.framework` linka objeto `arm64`
construido para `iOS` device, nao `iOS-simulator`. A configuracao iOS foi
restaurada apos a tentativa.

## Evidencia sanitizada

Diretorio:

- `app/doc/runtime_flow_proofs_2026-05-13_commander_reference_sprint3_lot_a_app/`

Logs:

- `commander_reference_sprint3_lot_a_app_runtime_raw_sanitized.log`
- `commander_reference_existing_app_value_runtime_compare_sanitized.log`
- `commander_reference_sprint3_lot_a_app_runtime_iphone15_raw_sanitized.log`

Screenshots: **nao capturados**; ambos os runtimes bloquearam antes do primeiro
checkpoint visual do fluxo Lote A.

## O que foi real, mockado e nao provado

- Real: repo `master` sincronizado, backend publico `/health`, build/install
  Android, device discovery Android, iPhone 15 Simulator discovery e tentativa
  de build iOS.
- Mockado: nada.
- Nao provado: register/login real, Generate Commander com `commander_name`,
  preview, save, Deck Details, comandante fora das 99, 100 cartas totais,
  `validation_ok`, ausencia de overflow/modal preso dentro do fluxo.

## Blockers e ownership

| Blocker | Evidencia | Owner sugerido |
| --- | --- | --- |
| Android runner/device preso no boot de UI | Android para no redirect `/login`; harness antigo reproduz o mesmo sintoma. | Mobile Runtime Device QA / App Release Engineer |
| iPhone 15 Simulator bloqueado por dependencia nativa MLImage/arquitetura | Xcode alterna entre exigencia de `arm64` para simulador e `MLImage.framework` arm64 device-only. | App Release Engineer / Scanner dependency owner |

## Menores proximas acoes

1. Reexecutar no `SM A135M` apos reiniciar device/Flutter daemon; se repetir,
   coletar `adb logcat` filtrado e validar se o isolate de teste fica bloqueado
   por platform channel ou frame scheduling.
2. Para iPhone 15, isolar scanner/MLKit do target de integration tests ou
   atualizar/remover a dependencia que impede slice `arm64-simulator`.
3. Reusar o harness criado nesta rodada para Krenko/Teysa assim que o runtime
   device voltar a executar taps.

Resultado final: **BLOCKED**.
