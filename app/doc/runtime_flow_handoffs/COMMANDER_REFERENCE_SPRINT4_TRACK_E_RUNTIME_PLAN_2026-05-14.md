# Commander Reference Sprint 4 Track E Runtime Plan - 2026-05-14

## Verdict

**PASS_WITH_RISKS / PLAN-ONLY.**

Track E define o plano de prova publica e runtime app para Sprint 4 sem executar
fluxos que criem usuarios/decks, sem expor secrets, tokens, JWT, Sentry DSN,
`DATABASE_URL`, `OPENAI_API_KEY`, e-mail QA completo ou decklists completas.

Nao atualizar manual, tracker ou API map nesta track. Nao commitar
individualmente.

## Fontes lidas

- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/manual-de-instrucao.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_FINAL_2026-05-14.md`
- `app/doc/COMMANDER_REFERENCE_MOBILE_TEST_STRATEGY_2026-05-14.md`
- `app/doc/runtime_flow_handoffs/commander_reference_sprint3_lot_a_app_2026-05-14.md`
- `app/doc/runtime_flow_handoffs/commander_reference_sprint3_lot_b_app_2026-05-14.md`
- `app/doc/runtime_flow_handoffs/commander_reference_sprint3_lot_c_app_2026-05-14.md`

## Estado base

- Backend publico: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Sprint 3 final: 20 promovidos totais, com apenas `Brago, King Eternal`
  promovido no Lote C.
- Purphoros/Veyran/Balan seguem bloqueados por ausencia de
  profile/card_stats/corpus no runtime publico.
- iPhone 15 Simulator foi descoberto em handoffs recentes como
  `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, iOS 17.4, mas segue sem prova por
  blocker historico de `MLImage.framework`/scanner.
- Android fisico `SM A135M` passou nos Lotes A/B/C com workaround de rede celular.

## Plano de prova publica backend 5/5

### Pre-condicoes

1. `master` sincronizado e backend publico `/health.git_sha` alinhado ao HEAD alvo.
2. Candidato Sprint 4 so entra em public proof apos corpus DB-backed PASS,
   `--apply` aprovado explicitamente, idempotencia PASS, profile/card_stats
   validos e readiness sem runtime summary sem blockers criticos.
3. Probes nao devem persistir token, e-mail completo, senha, prompt completo ou
   decklist completa.
4. Artifacts versionaveis devem conter apenas summaries sanitizados.

### Gate minimo por comandante

Para cada candidato Sprint 4:

- 5/5 HTTP 200 em `POST /ai/generate`;
- `format=Commander`, `bracket=3`, `commander_name` exato;
- `validation.is_valid=true` 5/5;
- comandante preservado 5/5;
- main deck 99 em 5/5;
- `reference_profile_used=true` 5/5;
- `reference_card_stats_used=true` 5/5;
- `reference_deck_corpus_used=true` 5/5;
- invalid cards total 0;
- off-identity total 0;
- timeout fallback 0/5;
- scorecard `score=100`, `ready_for_mini_batch`, sem blockers.

### Backoff para 429

- Rodar baixo volume: 1 comandante por vez.
- Esperar 15-30s entre probes.
- Ao receber `429`, parar o comandante atual, aguardar 60-120s com jitter e
  repetir no maximo 3 vezes.
- Registrar `429` como risco operacional se rerun com backoff passar.
- Nao promover se 429 impedir obter 5/5 limpos.

## Plano app runtime

### Alvo primario

iPhone 15 Simulator.

Comandos de discovery obrigatorios:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short --branch
flutter devices --no-version-check
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
```

### Condicao para rodar iPhone

Rodar iPhone somente se o blocker `MLImage.framework`/scanner permitir build, ou
se existir workaround claro de target/flavor nao-scanner que exclua scanner/OCR
do runtime de integration test.

Scanner, camera e OCR permanecem fora do escopo.

### Comando base iPhone

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
flutter test integration_test/commander_reference_representative_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Se o harness representativo ainda nao existir, usar o batch existente:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
for test_file in \
  integration_test/commander_reference_app_value_runtime_test.dart \
  integration_test/commander_reference_sprint3_lot_a_app_runtime_test.dart \
  integration_test/commander_reference_sprint3_lot_b_app_runtime_test.dart \
  integration_test/commander_reference_sprint3_lot_c_app_runtime_test.dart
do
  flutter test "$test_file" \
    -d "iPhone 15" \
    --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
    --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
    --dart-define=DISABLE_FIREBASE_STARTUP=true \
    --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
    --reporter expanded \
    --no-version-check
done
```

### Fallback Android fisico

Usar apenas se iPhone continuar bloqueado.

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
adb devices -l

cd app
flutter test integration_test/commander_reference_representative_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Se Wi-Fi repetir timeout, usar workaround documentado de rede celular e registrar
como risco, reabilitando Wi-Fi ao final.

## Artifacts sanitizados

Permitidos:

- summaries com contagens;
- commander name;
- HTTP status;
- timings p50/p95;
- booleans de profile/stats/corpus;
- validation flags;
- screenshots sem e-mail completo;
- logs sanitizados sem headers, tokens, payload bruto ou decklist.

Proibidos:

- JWT;
- Authorization header;
- e-mail QA completo;
- senha;
- Sentry DSN;
- `DATABASE_URL`;
- `OPENAI_API_KEY`;
- prompts completos;
- decklists completas;
- provider raw error body.

## Criterios de promocao

### PASS

- Backend public proof 5/5 passa para todos os candidatos promovidos.
- Scorecard retorna `score=100`, `ready_for_mini_batch`.
- App runtime passa no iPhone 15 Simulator com backend publico.
- Sem crash, overflow, modal preso, raw 4xx/5xx copy ou timeout inesperado.
- Artifacts sanitizados.

### PASS_WITH_RISKS

Aceitavel apenas se:

- backend public proof e scorecard passam;
- app runtime passa no Android fisico, mas iPhone segue bloqueado por MLImage;
- ou ocorre 429 inicial, mas rerun com backoff passa limpo;
- riscos sao documentados com menor proxima acao.

### BLOCKED

- profile/stats/corpus nao usados 5/5;
- invalid/off-identity > 0;
- timeout fallback > 0 sem explicacao aceita;
- scorecard != 100;
- iPhone bloqueado e Android fallback tambem nao prova fluxo;
- logs/artifacts expoem token, e-mail completo, prompt ou decklist completa.

## Blockers atuais

1. iPhone 15 Simulator nao provado por `MLImage.framework`/scanner.
2. Android publico dependeu de workaround de rede celular em A/B/C.
3. `GET /decks/:id.commander_name` agregado segue instavel; usar
   `commander`/`deck_cards.is_commander` como fonte de verdade.
4. Sprint 4 nao deve promover candidatos com apenas corpus dry-run; exige
   apply/idempotencia/profile/card_stats/public proof/scorecard.
5. Rate limit publico `429` exige backoff obrigatorio.

## Proximos comandos

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short --branch
flutter devices --no-version-check
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
```

Depois de apply/profile/card_stats aprovados para Sprint 4:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander="<commander>" \
  --runtime-summary="test/artifacts/<safe_path>/public_proof/summary.json" \
  --artifact-dir="test/artifacts/<safe_path>/readiness_public"
```

Resultado desta Track E: **PASS_WITH_RISKS / PLAN-ONLY**.
