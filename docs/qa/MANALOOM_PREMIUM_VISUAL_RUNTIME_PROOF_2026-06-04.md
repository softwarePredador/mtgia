# ManaLoom Premium Visual Runtime Proof

Data: 2026-06-04

Status: `PASS_WITH_RISKS`

## Ambiente

- Device: `iPhone 15 Pro Max`
- UDID: `DABB9D79-2FDB-4585-94DB-E31F1288EE74`
- Backend: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Gate estatico premium: `VISUAL_PREMIUM_QA_RESULT: signals=304 P1=0 P2=304 visual_pass=false`
- Auditor estatico Hermes/local: `UI_AUDIT_RESULT: findings=193 P0=0 P1=0 P2=193`

## Comandos executados

### Gate premium

```bash
python3 server/bin/premium_visual_audit.py \
  --include-life-counter \
  --output docs/qa/manaloom_premium_visual_audit_latest.md
```

### App non-Life-Counter

```bash
cd app
flutter test integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Resultado: `00:47 +1: All tests passed!`

### Life Counter / Lotus

```bash
cd app
flutter test \
  integration_test/life_counter_lotus_visual_capture_smoke_test.dart \
  integration_test/life_counter_native_card_search_smoke_test.dart \
  integration_test/life_counter_set_life_live_smoke_test.dart \
  integration_test/life_counter_native_player_appearance_color_card_live_smoke_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Resultado: `02:59 +5: All tests passed!`

## Evidencia local gerada

Os screenshots foram extraidos dos logs para:

```text
app/doc/runtime_flow_proofs_2026-06-04_premium_visual_gate_iphone15/
```

Essa pasta e ignorada por `.gitignore` (`app/doc/*proofs*/`) e nao foi
versionada.

Arquivos principais locais:

- `contact_sheet_non_life_counter.jpg`
- `contact_sheet_life_counter.jpg`
- `summary.json`

## Verificacao visual da rodada

### Aprovado na prova viva

- Splash/login/cadastro usam logo/arte atual e nao mostram Material default.
- Home usa a arte nova no hero e mantem Obsidian/Brass/Frost.
- Meus Decks empty state esta coerente, centralizado e com CTAs claros.
- Criar deck/import/generate usam modais/forms alinhados ao sistema visual.
- Collection nao reproduziu o bug antigo de menus deslocados para a direita.
- Life Counter/Lotus passou nos harnesses de overlays, set-life e player
  appearance com `apply_strategy=live_runtime`.

### Riscos visuais restantes

- Home esta coerente, mas o header/logo e o hero ocupam bastante altura no
  iPhone 15 Pro Max; se o alvo for ficar mais proximo do mockup compacto,
  precisa de rodada de ajuste especifica.
- Deck Details foi capturado com deck recem-criado/vazio; nao prova layout rico
  com deck completo, cards, graficos e analise preenchida.
- Generate preview ficou em `06_generate_preview_not_proven`, com pedido aceito
  e fila inicial; nao prova preview positivo completo nessa rodada.
- Life Counter gerou apenas duas capturas visuais de overlays no contact sheet;
  os outros harnesses passaram funcionalmente, mas nao produziram screenshots
  amplos suficientes para um `PASS` visual total de todos os sheets.

## Veredito

`PASS_WITH_RISKS` para o runtime visual executado.

Nao declarar `PASS` visual global ainda, porque o gate premium esta correto em
manter `visual_pass=false` ate haver revisao de screenshots ricos por tela e
estado preenchido.
