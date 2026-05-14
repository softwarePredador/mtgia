# Commander Reference Sprint 4 Lote 1 App Runtime Handoff - 2026-05-14

## Resultado

**PLAN-ONLY / PASS_WITH_RISKS.**

O backend promoveu somente `Miirym, Sentinel Wyrm` no Lote 1. O runtime app no
Android fisico `SM A135M` ainda nao foi executado porque nao existe harness
especifico Sprint 4 Lote 1 no repositorio.

Scanner, camera e OCR permanecem fora do escopo.

## Alvo

- Device: `SM A135M` (`R58T300SREH`)
- Backend publico: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Backend `/health.git_sha` revalidado: `b472db78ef21a9d4e2c3bc3feaac4e3c7d06b20f`
- Comandante promovido a cobrir: `Miirym, Sentinel Wyrm`
- Comandantes nao promovidos nesta rodada: `Feather, the Redeemed`, `Ghave, Guru
  of Spores`, `Jodah, the Unifier`

## Proximo comando de runtime

Criar/adaptar antes o harness
`app/integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart`
para cobrir register/login, Generate Commander com `commander_name`, preview,
save, Deck Details e `/decks/:id/validate` para `Miirym, Sentinel Wyrm`.

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
adb -s R58T300SREH shell svc wifi disable

cd app
flutter test integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check

adb -s R58T300SREH shell svc wifi enable
```

## Gates esperados

- `/health` publico HTTP 200 e SHA alinhado ao deploy alvo.
- Generate Commander usa `commander_name=Miirym, Sentinel Wyrm`.
- Preview e save concluem sem erro bruto 4xx/5xx.
- Deck Details mostra 99 cartas no main e comandante preservado fora das 99.
- `/decks/:id/validate` retorna valido, invalid=0 e off-identity=0.
- Logs/screenshots sanitizados, sem token, JWT, e-mail QA completo, prompt bruto
  ou decklist completa.

## Riscos

- iPhone 15 Simulator segue nao provado por blocker historico de
  `MLImage.framework`/scanner.
- Android fisico historicamente exigiu workaround de rede celular; reabilitar
  Wi-Fi ao final.
- `GET /decks/:id.commander_name` agregado segue instavel; usar lista
  `commander`/`deck_cards.is_commander` e `/validate` como fonte de verdade.
