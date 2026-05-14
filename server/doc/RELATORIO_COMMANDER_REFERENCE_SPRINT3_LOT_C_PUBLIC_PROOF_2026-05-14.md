# Commander Reference Sprint 3 Lote C Public Proof - 2026-05-14

## Verdict

**BLOCKED** para promocao do Lote C completo.

`Brago, King Eternal` passou na prova publica 5/5 de `POST /ai/generate` e foi
promovido pelo scorecard para `ready_for_mini_batch`. `Purphoros, God of the
Forge`, `Veyran, Voice of Duality` e `Balan, Wandering Knight` retornaram decks
Commander validos em 5/5 probes, mas nao ativaram profile/card_stats/corpus no
runtime publico e permaneceram bloqueados pelo scorecard.

## Escopo e seguranca

- Incluido: sync de `master`, leitura do relatorio Lote C apply/corpus prep, API
  map e manual, `/health`, `git_sha`, usuarios QA descartaveis mantidos em
  memoria, 5 probes publicas por comandante, summaries sanitizados, scorecard
  com `--runtime-summary` e decisao de promocao.
- Fora do escopo: scanner, camera, OCR, app runtime, mudanca de shape de
  `/ai/generate`, decklists geradas, prompts completos, tokens, e-mails QA
  completos, JWT, Sentry DSN, `DATABASE_URL` e `OPENAI_API_KEY`.
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md` foi consultado e nao foi alterado,
  porque nao houve mudanca de contrato, payload, response shape, diagnostics
  app-facing, data source ou consumidor mobile.

## Commits inspecionados

| Item | Valor |
| --- | --- |
| Branch | `master` |
| Local/origin apos sync | `ca23fc5a16e0b5c194d7375a537e23cf5cd34d2f` |
| Backend publico `/health.git_sha` | `ca23fc5a16e0b5c194d7375a537e23cf5cd34d2f` |
| Backend publico | `https://evolution-cartinhas.8ktevp.easypanel.host` |

## Comandos executados

```bash
git fetch origin master
git pull --ff-only origin master
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
python3 <public_probe_sanitized_inline>

cd server
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander="<commander>" \
  --runtime-summary="test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/public_proof/summary.json" \
  --artifact-dir="test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/readiness_public"
```

Cada probe usou `format=Commander`, `bracket=3`, `commander_name` exato e tema
coerente com o plano Lote C. O runner temporario ficou fora do repo e nao
persistiu token, e-mail, senha, prompt completo ou decklist.

## Pass/fail summary

| Commander | Proof | HTTP/validation/commander/main | profile/stats/corpus | fallback | timeout | invalid | off-id | p50 | p95 | Scorecard | Decision |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `Purphoros, God of the Forge` | BLOCKED | 5/5, 5/5, 5/5, 5/5 | 0/5, 0/5, 0/5 | 0/5 | 0/5 | 0 | 0 | 794ms | 12590ms | score 25, `blocked` | `promoted=false` |
| `Brago, King Eternal` | PASS | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 5/5 | 0/5 | 0 | 0 | 864ms | 942ms | score 100, `ready_for_mini_batch` | `promoted=true` |
| `Veyran, Voice of Duality` | BLOCKED | 5/5, 5/5, 5/5, 5/5 | 0/5, 0/5, 0/5 | 0/5 | 0/5 | 0 | 0 | 794ms | 11112ms | score 25, `blocked` | `promoted=false` |
| `Balan, Wandering Knight` | BLOCKED | 5/5, 5/5, 5/5, 5/5 | 0/5, 0/5, 0/5 | 0/5 | 0/5 | 0 | 0 | 826ms | 15568ms | score 25, `blocked` | `promoted=false` |

## Timing summary

Brago seguiu o caminho Commander Reference deterministico com
profile/stats/corpus ativos e p95 abaixo de 1s. Purphoros, Veyran e Balan
mantiveram validade Commander e legalidade, mas cairam no caminho sem
profile/stats/corpus; por isso tiveram primeira chamada mais lenta e p95 alto,
sem timeout fallback reportado.

Nao houve `429` nesta execucao final; o runner usou backoff entre probes para
evitar rate limit publico.

## Optimize path matrix de `/ai/generate`

| Commander | Path observado | Evidencia |
| --- | --- | --- |
| `Purphoros, God of the Forge` | Legacy/sem Commander Reference ativo | `profile_used=0`, `stats_used=0`, `corpus_used=0`, validation 5/5 |
| `Brago, King Eternal` | Commander Reference deterministico | `profile_used=5`, `stats_used=5`, `corpus_used=5`, fallback deterministico 5/5 |
| `Veyran, Voice of Duality` | Legacy/sem Commander Reference ativo | `profile_used=0`, `stats_used=0`, `corpus_used=0`, validation 5/5 |
| `Balan, Wandering Knight` | Legacy/sem Commander Reference ativo | `profile_used=0`, `stats_used=0`, `corpus_used=0`, validation 5/5 |

## App/backend contract findings

O contrato app-facing de `POST /ai/generate` permaneceu estavel. Os campos
opcionais de diagnostics existentes continuaram suficientes para detectar
`reference_profile_used`, `reference_card_stats_used` e
`reference_deck_corpus_used`; portanto nao houve atualizacao do API map.

## Legality/color-identity findings

Todos os quatro comandantes retornaram 5/5 com `validation_ok`,
`commander_preserved`, `main_quantity_99`, `invalid_cards_total=0` e
`off_identity_total=0`. A falha de promocao de Purphoros, Veyran e Balan nao foi
por deck ilegal, mas por falta do caminho Commander Reference exigido pelo gate.

## Sentry/logging findings

Nao houve erro app-facing nem runtime exception capturada nesta prova. Os
scorecards e summaries sanitizados guardam contexto suficiente para auditoria sem
registrar secrets, tokens, e-mails QA completos, prompts completos ou decklists.

## Artifacts

| Commander | Public proof | Readiness final |
| --- | --- | --- |
| Purphoros | `server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/purphoros_god_of_the_forge/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/purphoros_god_of_the_forge/readiness_public/readiness_scorecard_summary.json` |
| Brago | `server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/brago_king_eternal/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/brago_king_eternal/readiness_public/readiness_scorecard_summary.json` |
| Veyran | `server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/veyran_voice_of_duality/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/veyran_voice_of_duality/readiness_public/readiness_scorecard_summary.json` |
| Balan | `server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/balan_wandering_knight/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/balan_wandering_knight/readiness_public/readiness_scorecard_summary.json` |

## Blockers

Purphoros, Veyran e Balan seguem com blockers objetivos no scorecard:
`commander_card_not_resolved`, `profile_missing_or_below_confidence`,
`card_stats_missing`, `deterministic_reference_deck_invalid` e
`deterministic_main_quantity_not_99`, alem de warning
`public_runtime_gate_not_passed`.

## Smallest next fixes

1. Aplicar ou corrigir Commander Reference Profile e Card Stats para Purphoros,
   Veyran e Balan.
2. Garantir que o fallback deterministico desses tres comandantes resolva o
   commander e gere main deck 99 com profile/stats/corpus ativos.
3. Reexecutar public proof 5/5 e scorecard com `--runtime-summary` somente para
   os tres bloqueados.

## Decisao

Promovido para mini-batch controlado:

- `Brago, King Eternal`

Nao promovidos:

- `Purphoros, God of the Forge`
- `Veyran, Voice of Duality`
- `Balan, Wandering Knight`

Resultado final: **BLOCKED**.
