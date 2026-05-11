# Lorehold Final Deck Validation - SM A135M - 2026-05-11

## Resultado

**PASS.** O fluxo real do app criou, salvou, abriu e validou um deck Commander
com `Lorehold, the Historian` usando o backend publico.

## Ambiente

- Device: `SM A135M` / `R58T300SREH` / Android 14 API 34
- Backend: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Health: `200`, `git_sha=ef3d9775a6d6b1a688408d8b98ecbe9f0238b1bc`
- Scanner/camera/OCR: fora de escopo
- Mock: nenhum

## Comando executado

```bash
cd app
flutter test integration_test/lorehold_generate_reference_stats_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --reporter expanded \
  --no-version-check
```

## Fluxo validado

- UI real: login, register, aba Decks, Generate Commander, campo
  `Lorehold, the Historian`, preview, salvar deck, Deck Details.
- Backend real: `/health`, `/auth/register`, `/ai/generate` async/poll,
  `/decks`, `/decks/:id`, `/decks/:id/pricing`, `/decks/:id/validate`.
- Resultado do teste: `01:00 +1: All tests passed!`.

## Resultado do deck final

Deck criado: `8457a713-f861-4477-a21d-0e3315da5fc6`.

Resumo sanitizado:

```json
{
  "validation_ok": true,
  "classification": "on_theme",
  "on_theme_reference_matches": 33,
  "main_qty": 99,
  "total_with_commander": 100,
  "lorehold_commander_count": 1,
  "lorehold_in_99_count": 0,
  "off_identity_count": 0
}
```

## Leitura do comportamento da IA

- O app recebeu feedback inicial em `807ms`, com `/ai/generate -> 202` em
  `427ms`; a geracao pesada seguiu via job async.
- O deck final foi classificado como `on_theme` pelo harness porque incluiu
  `33` matches de cartas/pacotes esperados para Lorehold.
- O comandante ficou no slot correto: exatamente `1` Lorehold como commander e
  `0` Lorehold nas 99.
- A identidade de cor ficou correta: `0` cartas fora de `R/W`.
- A validacao Commander retornou `200` e `validation_ok=true`.
- Nao houve crash, overflow reportado, erro bruto user-facing, 4xx/5xx
  inesperado ou modal preso no fluxo.

## Timings observados

- `/health`: `1539ms`
- `/auth/register`: `1004ms`
- `/ai/generate`: `202` em `427ms`
- polling `/ai/generate/jobs/:id`: `200` em `282ms` e `674ms`
- `/decks` save: `200` em `580ms`
- `/decks/:id`: `200` em `903ms` e `847ms`
- `/decks/:id/validate`: `200` em `434ms` e `244ms`
- `/decks/:id/pricing`: `200` em `959ms`

## Artefatos locais

Log local sanitizado:

- `app/doc/runtime_flow_proofs_2026-05-11_sm_a135m_lorehold_final_deck/lorehold_generate_reference_stats_runtime.log`

O diretorio de proof e ignorado pelo Git por conter screenshots/logs grandes.

## Riscos restantes

- A prova validou um deck gerado nesta rodada; geracoes futuras ainda podem
  variar por modelo/cache/rede. A regressao deve manter o criterio de
  `validation_ok`, `100` cartas, commander unico, `0` off-identity e minimo de
  matches tematicos.
- A prova nao avalia subjetivamente a qualidade de cada carta individual; ela
  mede aderencia aos pacotes de referencia persistidos e validacao Commander.
