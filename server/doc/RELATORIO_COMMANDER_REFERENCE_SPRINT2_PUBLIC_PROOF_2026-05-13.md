# Commander Reference Sprint 2 Public Proof - 2026-05-13

## Verdict

**PASS WITH RISKS.**

Cinco comandantes Sprint 2 aplicados passaram na prova publica 5/5 de
`POST /ai/generate` e foram promovidos pelo scorecard:
`Kinnan, Bonder Prodigy`, `Muldrotha, the Gravetide`,
`Yuriko, the Tiger's Shadow`, `Winota, Joiner of Forces` e
`Atraxa, Praetors' Voice`.

`Korvold, Fae-Cursed King` permanece com `promoted=false` porque o scorecard
final ficou em `score=90`, `status=profile_ready_needs_proof`, com
`core_package_weak` e `public_runtime_gate_not_passed`.

## Escopo e seguranca

- Incluido: `/health`, `git_sha`, usuario QA descartavel em memoria, 5 probes
  publicas por comandante, summaries sanitizados, scorecard com
  `--runtime-summary` e decisao de promocao.
- Fora do escopo: scanner, camera, OCR, app mobile runtime, alteracao de shape
  de `/ai/generate`, decklists geradas, prompts completos, tokens, e-mails QA
  completos, JWT, Sentry DSN, `DATABASE_URL` e `OPENAI_API_KEY`.
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md` nao foi alterado porque nao houve
  mudanca de contrato ou shape de resposta.

## Commits inspecionados

| Item | Valor |
| --- | --- |
| Branch | `master` |
| Local/origin apos sync | `f280a97f865f87eb9e1dfcbe65765c5828ff93a4` |
| Backend publico `/health.git_sha` | `f280a97f865f87eb9e1dfcbe65765c5828ff93a4` |
| Backend publico | `https://evolution-cartinhas.8ktevp.easypanel.host` |

## Comandos executados

```bash
git fetch origin master --prune
git pull --ff-only origin master
curl -sS https://evolution-cartinhas.8ktevp.easypanel.host/health
```

As probes publicas foram executadas por script Python local, sem persistir token,
e-mail, senha, prompt completo ou decklist. O primeiro lote confirmou o rate
limit publico de IA (`10` chamadas/minuto); Yuriko, Winota e Atraxa foram
reexecutados em janelas controladas e os summaries finais foram sobrescritos
somente com a prova limpa.

Scorecards finais, a partir de `server/`:

```bash
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander="<commander>" \
  --runtime-summary="test/artifacts/commander_reference_sprint2_2026-05-13/<safe_commander>/public_proof/summary.json" \
  --artifact-dir="test/artifacts/commander_reference_sprint2_2026-05-13/<safe_commander>/readiness_public"
```

Validação de fechamento:

```bash
git diff --check
python3 <summary_assertions_and_secret_scan_inline>
```

## Pass/fail summary

| Commander | Proof | HTTP/validation/commander/main | profile/stats/corpus | fallback | timeout | invalid | off-id | p50 | p95 | Scorecard | Decision |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `Kinnan, Bonder Prodigy` | `PASS` | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 5/5 | 0/5 | 0 | 0 | 927ms | 998ms | score 100, `ready_for_mini_batch` | `promoted=true` |
| `Korvold, Fae-Cursed King` | `PASS_WITH_RISKS` | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 2/5 | 2/5 | 0 | 0 | 20223ms | 24991ms | score 90, `profile_ready_needs_proof` | `promoted=false` |
| `Muldrotha, the Gravetide` | `PASS` | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 5/5 | 0/5 | 0 | 0 | 894ms | 939ms | score 100, `ready_for_mini_batch` | `promoted=true` |
| `Yuriko, the Tiger's Shadow` | `PASS` | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 5/5 | 0/5 | 0 | 0 | 893ms | 910ms | score 100, `ready_for_mini_batch` | `promoted=true` |
| `Winota, Joiner of Forces` | `PASS` | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 5/5 | 0/5 | 0 | 0 | 887ms | 945ms | score 100, `ready_for_mini_batch` | `promoted=true` |
| `Atraxa, Praetors' Voice` | `PASS` | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 5/5 | 0/5 | 0 | 0 | 904ms | 914ms | score 100, `ready_for_mini_batch` | `promoted=true` |

## Timing summary

- Kinnan, Muldrotha, Yuriko, Winota e Atraxa usaram o caminho deterministico
  Commander Reference (`is_mock=true`) com profile/stats/corpus ativos, sem
  timeout fallback e com p95 abaixo de 1s no backend publico.
- Korvold usou caminho OpenAI/reference em parte das chamadas e sofreu
  `timeout_fallback_count=2`; o p95 ficou em `24991ms`, concentrando a latencia
  no caminho nao-deterministico.
- O rate limit publico de IA exigiu janelas de execucao; isso nao apareceu nos
  summaries finais de Yuriko/Winota/Atraxa, mas fica registrado como cuidado
  operacional para futuras provas em lote.

## Artifacts

| Commander | Public proof | Readiness final |
| --- | --- | --- |
| Kinnan | `server/test/artifacts/commander_reference_sprint2_2026-05-13/kinnan_bonder_prodigy/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint2_2026-05-13/kinnan_bonder_prodigy/readiness_public/readiness_scorecard_summary.json` |
| Korvold | `server/test/artifacts/commander_reference_sprint2_2026-05-13/korvold_fae_cursed_king/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint2_2026-05-13/korvold_fae_cursed_king/readiness_public/readiness_scorecard_summary.json` |
| Muldrotha | `server/test/artifacts/commander_reference_sprint2_2026-05-13/muldrotha_the_gravetide/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint2_2026-05-13/muldrotha_the_gravetide/readiness_public/readiness_scorecard_summary.json` |
| Yuriko | `server/test/artifacts/commander_reference_sprint2_2026-05-13/yuriko_the_tigers_shadow/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint2_2026-05-13/yuriko_the_tigers_shadow/readiness_public/readiness_scorecard_summary.json` |
| Winota | `server/test/artifacts/commander_reference_sprint2_2026-05-13/winota_joiner_of_forces/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint2_2026-05-13/winota_joiner_of_forces/readiness_public/readiness_scorecard_summary.json` |
| Atraxa | `server/test/artifacts/commander_reference_sprint2_2026-05-13/atraxa_praetors_voice/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint2_2026-05-13/atraxa_praetors_voice/readiness_public/readiness_scorecard_summary.json` |

## Blockers

| Commander | Blocker | Smallest next fix |
| --- | --- | --- |
| `Korvold, Fae-Cursed King` | `core_package_weak` e `public_runtime_gate_not_passed` por timeout fallback 2/5 | Reforcar corpus/core package de sacrifice/treasure/value ate o gate `corpus_core_package_strong`; repetir prova publica em janela rate-limit-safe e confirmar timeout fallback 0/5 antes de promocao. |

## Decisao

Promovidos para mini-batch controlado:

- `Kinnan, Bonder Prodigy`
- `Muldrotha, the Gravetide`
- `Yuriko, the Tiger's Shadow`
- `Winota, Joiner of Forces`
- `Atraxa, Praetors' Voice`

Nao promovido:

- `Korvold, Fae-Cursed King`

Resultado final do sprint nesta etapa: **PASS WITH RISKS**.
