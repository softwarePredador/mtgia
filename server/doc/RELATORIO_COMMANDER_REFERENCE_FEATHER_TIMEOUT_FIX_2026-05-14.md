# Commander Reference Feather Timeout Fix - 2026-05-14

## Resultado

**PASS.** `Feather, the Redeemed` foi promovida para
`ready_for_mini_batch` no Sprint 4 apos correcao do caminho
reference-guided/deterministico e nova prova publica 5/5.

Nao houve mudanca de contrato app-facing. `API_CONTRACTS_AND_DATA_MAP.md` foi
consultado e permaneceu sem alteracao porque rotas, payloads, response shape,
diagnostics app-facing, data sources e consumidores mobile nao mudaram. Scanner,
camera e OCR ficaram fora do escopo.

## Fleet tracks

| Track | Resultado | Evidencia |
| --- | --- | --- |
| A - diagnostico | O scorecard aceitava proof normal com `invalid_cards_total>0` e p95 alto quando `fallback_count=0`; o generate tambem podia cachear resposta valida com cartas nao resolvidas. | Gate antigo reprocessado em `readiness_pre_fix_summary/` agora fica `PASS_WITH_RISKS`, score 98, `public_runtime_gate_not_passed`. |
| B - profile/stats/corpus | Feather tinha profile high, 31 card_stats resolvidos, corpus 4/4 e core_package 20; o threshold compacto anterior exigia 24 e empurrava o fluxo para OpenAI. | `corpus_accepted_deck_count=4`, `corpus_core_package_count=20`, `card_stats_count=31`. |
| C - fix deterministico | Fast path agora aceita corpus 4 decks/core 20 com >=20 stats resolvidos, remove cartas nao resolvidas antes da validacao/refill, nao cacheia respostas com invalids e versiona cache/prompt para `ai_generate_reference_prompt_v6`. | Commit de codigo `73d9f886c4959ff0ab9f60ec075ba787ffbe5144`. |
| D - public proof | 5 probes publicos com backoff para 429, sem token/e-mail/prompt/decklist em artifact. | `public_proof/summary.json`: HTTP 200 5/5, validation 5/5, commander 5/5, main 99 5/5, profile/stats/corpus 5/5, invalid/off_identity 0, timeout 0, p95 1243ms. |
| E - readiness | Scorecard com runtime summary retornou score 100, `ready_for_mini_batch`, sem blockers/warnings. | `readiness_public/readiness_scorecard_summary.json`. |

## Public proof sanitizado

Artifact principal:
`server/test/artifacts/commander_reference_feather_timeout_fix_2026-05-14/public_proof/summary.json`.

Resumo:

```json
{
  "status": "PASS",
  "backend_git_sha": "73d9f886c4959ff0ab9f60ec075ba787ffbe5144",
  "http_200": 5,
  "validation_ok": 5,
  "commander_preserved": 5,
  "main_quantity_99": 5,
  "profile_used": 5,
  "stats_used": 5,
  "corpus_used": 5,
  "invalid_cards_total": 0,
  "off_identity_total": 0,
  "timeout_fallback_count": 0,
  "p50_ms": 828,
  "p95_ms": 1243
}
```

`fallback_count=5` representa o caminho deterministico/reference-guided valido
e nao timeout. `timeout_fallback_count=0` em todos os probes.

## Readiness

Artifact:
`server/test/artifacts/commander_reference_feather_timeout_fix_2026-05-14/readiness_public/readiness_scorecard_summary.json`.

Resumo: `score=100`, `status=ready_for_mini_batch`, `expansion_ready=true`,
`blockers=[]`, `warnings=[]`.

## Validacao local

```bash
cd server
dart analyze lib/ai/commander_reference_readiness_support.dart \
  lib/ai/commander_reference_deck_corpus_support.dart \
  lib/ai/commander_reference_generate_fallback_support.dart \
  routes/ai/generate/index.dart \
  test/commander_reference_readiness_support_test.dart \
  test/commander_reference_deck_corpus_support_test.dart \
  test/commander_reference_card_stats_support_test.dart

dart test \
  test/commander_reference_deck_corpus_support_test.dart \
  test/commander_reference_profile_support_test.dart \
  test/commander_reference_card_stats_support_test.dart \
  test/commander_reference_readiness_support_test.dart \
  test/generated_deck_validation_service_test.dart \
  -r expanded
```

Resultado: PASS.

## Decisao

`Feather, the Redeemed` sai de bloqueada por timeout/invalid proof e fica
promovida para mini-batch. Resultado final: **PASS**.
