# Commander Reference Sprint 4 Lote 1 Public Proof - 2026-05-14

## Resultado

**PASS_WITH_RISKS backend / PASS_WITH_MINOR_HARNESS_FIX app runtime.**

O Lote 1 promove somente `Miirym, Sentinel Wyrm` para
`ready_for_mini_batch`. `Feather, the Redeemed` passou nos gates de
HTTP/validacao/comandante/main/profile/card_stats/corpus, mas nao foi promovido:
na revalidacao do deploy atual o summary ficou `status=BLOCKED` por
`invalid_cards_total=5` e p95 alto, apesar do scorecard atual retornar 100.

O harness app Sprint 4 Lote 1 foi corrigido e rerodado para
`Miirym, Sentinel Wyrm`; o runtime real ficou
**PASS_WITH_MINOR_HARNESS_FIX** no iPhone 15 Simulator contra o backend publico.
Nao houve mudanca de contrato app-facing, scanner, camera ou OCR. Artifacts
persistidos sao summaries sanitizados; corpora brutos temporarios ficaram fora
do repositorio e foram removidos ao final.

## Contexto

- Repo: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- Branch alvo: `master`
- Backend publico: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Backend `/health.git_sha`: `b472db78ef21a9d4e2c3bc3feaac4e3c7d06b20f`
- Backend `/health.git_sha` revalidado no bloqueio app:
  `5c316ab6ac0b4513a91653faceacec11039ecae8`
- Backend `/health.git_sha` revalidado no runtime iPhone 15 Simulator:
  `34576f51e710e10c950f787ae2f91aa6f77e3cba`
- Commit com a correcao do harness em `master`:
  `dd918fc5b9e95f0c1f551f48bd73752b817ab8b4`
- API map consultado e mantido sem alteracao porque nao houve drift de rota,
  payload, response shape, diagnostics app-facing, data source ou consumidor
  mobile.

## Track A - candidatos

| Commander | Decisao | Motivo |
| --- | --- | --- |
| `Feather, the Redeemed` | Elegivel para pipeline, nao promovido | Profile/card_stats resolvidos e corpus 4/4 limpo; bloqueado depois por timeout fallback publico. |
| `Miirym, Sentinel Wyrm` | Promovido | Profile/card_stats resolvidos, corpus 5/5 limpo, public proof PASS e scorecard 100. |
| `Ghave, Guru of Spores` | Bloqueado | Corpus dry-run 5/5, mas sem profile/card_stats. |
| `Jodah, the Unifier` | Bloqueado | Corpus dry-run 5/5, mas apenas profile legado `edhrec` e sem card_stats. |

## Track B - corpus/apply/idempotencia

Artifacts:
`server/test/artifacts/commander_reference_sprint4_lot1_2026-05-14/`.
Os summaries do deploy atual ficam em `public_proof_current_sha/` e
`readiness_public_current_sha/`; a rodada anterior em `7b6074...` foi preservada.

| Commander | Dry-run pre-apply | Apply | Idempotencia | Readiness sem runtime |
| --- | --- | --- | --- | --- |
| `Feather, the Redeemed` | PASS 4/4, unresolved=0, off_color=0, 1/99, singleton limpo | PASS 4/4 | PASS 4/4 | score 98, `profile_ready_needs_proof`, warning `public_runtime_proof_missing` |
| `Miirym, Sentinel Wyrm` | PASS 5/5, unresolved=0, off_color=0, 1/99, singleton limpo | PASS 5/5 | PASS 5/5 | score 98, `profile_ready_needs_proof`, warning `public_runtime_proof_missing` |

## Track C - public proof sanitizado

Cada comandante elegivel recebeu 5 probes publicas de `POST /ai/generate` com
`commander_name` exato. Nenhum artifact registra token, e-mail QA completo,
prompt bruto ou decklist completa.

| Commander | Public proof | Runtime gates | p50/p95 | Resultado |
| --- | --- | --- | --- | --- |
| `Feather, the Redeemed` | BLOCKED | HTTP 200, validation, commander, main 99, profile/stats/corpus 5/5; `invalid_cards_total=5`, off_identity=0, timeout=0 | 855ms / 25659ms na revalidacao atual | Nao promover; public proof gate falhou apesar de scorecard atual 100 |
| `Miirym, Sentinel Wyrm` | PASS | HTTP 200, validation, commander, main 99, profile/stats/corpus 5/5; invalid=0, off_identity=0, timeout=0 | 849ms / 942ms | Promover; score 100 `ready_for_mini_batch` |

Observacao: Feather teve a rodada anterior preservada em
`public_proof_timeout_attempt/` e `public_proof/`, ambas bloqueadas por
`timeout_fallback_count=5`. Na revalidacao do deploy atual
`public_proof_current_sha/`, o timeout zerou, mas o gate continuou bloqueado por
`invalid_cards_total=5` e p95 25659ms.

## Track D - scorecard de promocao

| Commander | Score | Status | Promoted |
| --- | ---: | --- | --- |
| `Feather, the Redeemed` | 100 | `ready_for_mini_batch` no scorecard atual, mas public proof `status=BLOCKED` por invalid_cards_total>0 | false |
| `Miirym, Sentinel Wyrm` | 100 | `ready_for_mini_batch`, blockers/warnings vazios | true |

## Track E - runtime app iPhone 15 Simulator

Runtime app ficou **PASS_WITH_MINOR_HARNESS_FIX** nesta rodada. O harness
`app/integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart` foi
corrigido e cobre somente o promovido backend (`Miirym, Sentinel Wyrm`) com
register/login, Generate Commander, preview, save, Deck Details e
`/decks/:id/validate`.

Validacao local focada:

```bash
cd app
dart format integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart
flutter analyze integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart --no-version-check
flutter test test/features/decks/providers/deck_provider_test.dart --no-version-check
```

Resultado local: **PASS**.

Correcao menor do harness:

- `deck_commander_name_matches` deixou de depender do agregado
  `deck['commander_name']`.
- O campo agora usa `raw_commander_names` normalizado a partir das entradas reais
  de `commander` retornadas por `GET /decks/:id`.
- A prova de runtime confirmou `raw_commander_names=["Miirym, Sentinel Wyrm"]` e
  `deck_commander_name_matches=true`.

Comando iPhone 15 Simulator:

```bash
cd app
flutter test integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart \
  -d F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Resultado iPhone 15 Simulator: **PASS** (`00:41 +1: All tests passed!`).

Latencias relevantes:

- `/health`: `latency_ms=1148`, `git_sha=34576f51e710e10c950f787ae2f91aa6f77e3cba`.
- Feedback inicial de Generate Commander: `elapsed_ms=587`.
- Public proof backend de Miirym: p50 `849ms`, p95 `942ms`.

Resumo runtime sanitizado:

```json
{
  "deck_id": "<redacted-deck-id>",
  "commander": "Miirym, Sentinel Wyrm",
  "archetype": "temur_dragons_etb_copy",
  "app_runtime_valid": true,
  "deck_commander_name_matches": true,
  "raw_commander_entries": 1,
  "raw_commander_names": ["Miirym, Sentinel Wyrm"],
  "validation_ok": true,
  "main_quantity": 99,
  "total": 100,
  "commander_count": 1,
  "commander_in_99_count": 0,
  "off_identity": 0
}
```

## Decisao final

- **Promovido:** `Miirym, Sentinel Wyrm`.
- **Bloqueados:** `Feather, the Redeemed` por public proof atual com
  `invalid_cards_total=5` e p95 alto, alem de historico de timeout fallback;
  `Ghave, Guru of Spores` e `Jodah, the Unifier` por falta de
  profile/card_stats utilizaveis.
- **Resultado operacional backend:** **PASS_WITH_RISKS**.
- **Resultado operacional app runtime:** **PASS_WITH_MINOR_HARNESS_FIX** no
  iPhone 15 Simulator.
