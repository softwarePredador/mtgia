# Commander Reference Sprint 3 Lote A Public Proof - 2026-05-13

## Verdict

**PASS.**

Os quatro comandantes Sprint 3 Lote A aplicados passaram na prova publica 5/5
de `POST /ai/generate` e foram promovidos pelo scorecard para
`ready_for_mini_batch`: `Krenko, Mob Boss`, `Light-Paws, Emperor's Voice`,
`Niv-Mizzet, Parun` e `Teysa Karlov`.

## Escopo e seguranca

- Incluido: sync de `master`, leitura do relatorio apply Lote A e API map,
  `/health`, `git_sha`, usuario QA descartavel mantido em memoria, 5 probes
  publicas por comandante, summaries sanitizados, scorecard com
  `--runtime-summary` e decisao de promocao.
- Fora do escopo: scanner, camera, OCR, app mobile runtime, alteracao de shape
  de `/ai/generate`, decklists geradas, prompts completos, tokens, e-mails QA
  completos, JWT, Sentry DSN, `DATABASE_URL` e `OPENAI_API_KEY`.
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md` foi consultado e nao foi alterado,
  porque nao houve mudanca de contrato, payload, shape de resposta ou consumidor
  mobile.

## Commits inspecionados

| Item | Valor |
| --- | --- |
| Branch | `master` |
| Local/origin apos sync | `ac8318386d33f2b31425989fbe5dd3500ca56213` |
| Backend publico `/health.git_sha` | `ac8318386d33f2b31425989fbe5dd3500ca56213` |
| Backend publico | `https://evolution-cartinhas.8ktevp.easypanel.host` |

## Comandos executados

```bash
git pull --ff-only origin master
curl -sS https://evolution-cartinhas.8ktevp.easypanel.host/health
```

As probes publicas foram executadas por script Python temporario fora do repo,
sem persistir token, e-mail, senha, prompt completo ou decklist. Cada chamada
usou `format=Commander`, `bracket=3`, `commander_name` exato e prompt tematico
sanitizado.

Scorecards finais, a partir de `server/`:

```bash
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander="<commander>" \
  --runtime-summary="test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/public_proof/summary.json" \
  --artifact-dir="test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/readiness_public"
```

Validacao de fechamento:

```bash
git diff --check
python3 <summary_assertions_and_secret_scan_inline>
```

## Pass/fail summary

| Commander | Proof | HTTP/validation/commander/main | profile/stats/corpus | fallback | timeout | invalid | off-id | p50 | p95 | Scorecard | Decision |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `Krenko, Mob Boss` | PASS | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 5/5 | 0/5 | 0 | 0 | 888ms | 1233ms | score 100, `ready_for_mini_batch` | `promoted=true` |
| `Light-Paws, Emperor's Voice` | PASS | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 5/5 | 0/5 | 0 | 0 | 873ms | 952ms | score 100, `ready_for_mini_batch` | `promoted=true` |
| `Niv-Mizzet, Parun` | PASS | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 5/5 | 0/5 | 0 | 0 | 857ms | 981ms | score 100, `ready_for_mini_batch` | `promoted=true` |
| `Teysa Karlov` | PASS | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 5/5 | 0/5 | 0 | 0 | 856ms | 908ms | score 100, `ready_for_mini_batch` | `promoted=true` |

## Timing summary

Todos os quatro comandantes usaram o caminho deterministico Commander Reference
com `is_mock=true`, profile/stats/corpus ativos, sem timeout fallback e com p95
abaixo de 1.3s no backend publico. A latencia ficou concentrada no request HTTP
publico e na validacao backend; nao houve janela OpenAI lenta ou fallback por
timeout.

## Artifacts

| Commander | Public proof | Readiness final |
| --- | --- | --- |
| Krenko | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/krenko_mob_boss/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/krenko_mob_boss/readiness_public/readiness_scorecard_summary.json` |
| Light-Paws | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/light_paws_emperor_s_voice/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/light_paws_emperor_s_voice/readiness_public/readiness_scorecard_summary.json` |
| Niv-Mizzet | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/niv_mizzet_parun/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/niv_mizzet_parun/readiness_public/readiness_scorecard_summary.json` |
| Teysa | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/teysa_karlov/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/teysa_karlov/readiness_public/readiness_scorecard_summary.json` |

## Blockers e riscos

Nao ha blockers nesta etapa. Riscos remanescentes sao operacionais: manter
scanner/camera/OCR fora do escopo desta prova, continuar evitando persistencia
de prompts/decklists em artifacts publicos e revalidar em novo deploy caso
`/health.git_sha` mude antes do consumo mobile.

## Decisao

Promovidos para mini-batch controlado:

- `Krenko, Mob Boss`
- `Light-Paws, Emperor's Voice`
- `Niv-Mizzet, Parun`
- `Teysa Karlov`

Resultado final: **PASS**.
