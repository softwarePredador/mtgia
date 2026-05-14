# Commander Reference Sprint 4 Lote 1 Public Proof - 2026-05-14

## Resultado

**PASS_WITH_RISKS.**

O Lote 1 promove somente `Miirym, Sentinel Wyrm` para
`ready_for_mini_batch`. `Feather, the Redeemed` passou nos gates de legalidade e
uso de profile/card_stats/corpus, mas nao foi promovido porque duas rodadas de
public proof ficaram com `timeout_fallback_count=5` e scorecard final 98.

Nao houve mudanca de contrato app-facing, scanner, camera ou OCR. Artifacts
persistidos sao summaries sanitizados; corpora brutos temporarios ficaram fora do
repositorio e foram removidos ao final.

## Contexto

- Repo: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- Branch alvo: `master`
- Backend publico: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Backend `/health.git_sha`: `7b607404871168aa18d920ab71f7d70c63f325a5`
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
| `Feather, the Redeemed` | BLOCKED | HTTP 200, validation, commander, main 99, profile/stats/corpus 5/5; invalid=0, off_identity=0; `timeout_fallback_count=5` em duas rodadas | 847ms / 25045ms na rodada final | Nao promover; score 98 `profile_ready_needs_proof` |
| `Miirym, Sentinel Wyrm` | PASS | HTTP 200, validation, commander, main 99, profile/stats/corpus 5/5; invalid=0, off_identity=0, timeout=0 | 848ms / 956ms | Promover; score 100 `ready_for_mini_batch` |

Observacao: Feather teve uma primeira tentativa preservada em
`public_proof_timeout_attempt/` e uma repeticao controlada no path final
`public_proof/`; ambas bloquearam pelo mesmo motivo objetivo:
`timeout_fallback_count=5`.

## Track D - scorecard de promocao

| Commander | Score | Status | Promoted |
| --- | ---: | --- | --- |
| `Feather, the Redeemed` | 98 | `profile_ready_needs_proof`, warning `public_runtime_gate_not_passed` | false |
| `Miirym, Sentinel Wyrm` | 100 | `ready_for_mini_batch`, blockers/warnings vazios | true |

## Track E - runtime app Android SM A135M

Runtime app nao foi executado nesta rodada. O proximo comando preparado cobre
somente o promovido backend (`Miirym, Sentinel Wyrm`) e deve ser rodado apos criar
ou adaptar o harness Sprint 4 Lote 1:

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

## Decisao final

- **Promovido:** `Miirym, Sentinel Wyrm`.
- **Bloqueados:** `Feather, the Redeemed` por timeout fallback publico;
  `Ghave, Guru of Spores` e `Jodah, the Unifier` por falta de
  profile/card_stats utilizaveis.
- **Resultado operacional:** **PASS_WITH_RISKS**.
