# Commander Reference Ghave/Jodah Unlock - 2026-05-15

## Resultado

**PASS.** `Ghave, Guru of Spores` e `Jodah, the Unifier` foram promovidos para
`ready_for_mini_batch` no backend publico
`https://evolution-cartinhas.8ktevp.easypanel.host` com
`backend_git_sha=4570daf8a43fbf5b79301fde8e1d8f5c40004b8b`.

Nao houve mudanca de contrato app-facing. `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
foi consultado e permaneceu sem alteracao porque nao houve mudanca de rota,
payload, response shape, diagnostics app-facing, data source ou consumidor mobile.
Scanner, camera e OCR ficaram fora do escopo.

## Diagnostico pre-proof

| Commander | Readiness pre-proof | Status pre-proof | Causa |
| --- | ---: | --- | --- |
| `Ghave, Guru of Spores` | 98 | `profile_ready_needs_proof` | Somente `public_runtime_proof_missing`; profile high, card_stats, corpus, idempotencia e deck deterministico ja estavam OK. |
| `Jodah, the Unifier` | 98 | `profile_ready_needs_proof` | Somente `public_runtime_proof_missing`; profile high, card_stats, corpus, idempotencia e deck deterministico ja estavam OK. |

Nao foi necessario alterar parser/summary nem relaxar o gate. A falha inicial do
harness foi operacional: `/ai/generate` publico exige JWT; a prova final usou
usuario QA descartavel mantido somente em memoria, sem persistir token, e-mail,
prompt bruto ou decklist completa.

## Public proof sanitizado

Artifacts:

| Commander | Public proof | Readiness final |
| --- | --- | --- |
| `Ghave, Guru of Spores` | `server/test/artifacts/commander_reference_ghave_jodah_unlock_2026-05-15/ghave_guru_of_spores/public_proof/summary.json` | `server/test/artifacts/commander_reference_ghave_jodah_unlock_2026-05-15/ghave_guru_of_spores/readiness_public/readiness_scorecard_summary.json` |
| `Jodah, the Unifier` | `server/test/artifacts/commander_reference_ghave_jodah_unlock_2026-05-15/jodah_the_unifier/public_proof/summary.json` | `server/test/artifacts/commander_reference_ghave_jodah_unlock_2026-05-15/jodah_the_unifier/readiness_public/readiness_scorecard_summary.json` |

| Commander | HTTP/validation/commander/main | profile/stats/corpus | invalid | off-id | fallback | timeout | p50 | p95 | Rate-limit |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `Ghave, Guru of Spores` | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 0 | 0 | 5 | 0 | 801ms | 1069ms | 0 retries |
| `Jodah, the Unifier` | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 0 | 0 | 5 | 0 | 793ms | 915ms | 0 retries |

`fallback_count=5` representa o caminho deterministico/reference-guided valido,
nao timeout. `timeout_fallback_count=0` em todos os probes.

## Readiness final

| Commander | Score | Status | Blockers | Warnings | Decisao |
| --- | ---: | --- | --- | --- | --- |
| `Ghave, Guru of Spores` | 100 | `ready_for_mini_batch` | nenhum | nenhuma | promovido |
| `Jodah, the Unifier` | 100 | `ready_for_mini_batch` | nenhum | nenhuma | promovido |

## Validacao e seguranca

- Mesmo sem alteracao de codigo Dart, foram executados `dart analyze` focado em
  scorecard/readiness e `dart test test/commander_reference_readiness_support_test.dart`.
  Tambem foram executados `git diff --check` e scan simples de secrets nas linhas
  adicionadas.
- Os summaries persistidos sao agregados sanitizados: sem token, JWT, e-mail QA
  completo, prompt bruto, secrets ou decklists completas.
- Resultado final: **PASS** para Ghave e **PASS** para Jodah.
