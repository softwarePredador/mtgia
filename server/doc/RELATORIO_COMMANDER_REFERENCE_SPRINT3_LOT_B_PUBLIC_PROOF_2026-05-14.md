# Commander Reference Sprint 3 Lote B Public Proof - 2026-05-14

## Verdict

**PASS_WITH_RISKS**, atualizado em 2026-05-14 com prova app runtime real.

Os quatro comandantes Sprint 3 Lote B aplicados passaram na prova publica 5/5
de `POST /ai/generate` no backend publico e foram promovidos pelo scorecard para
`ready_for_mini_batch`: `Meren of Clan Nel Toth`,
`Korvold, Fae-Cursed King`, `Sythis, Harvest's Hand` e
`Urza, Lord High Artificer`. Em 2026-05-14, `Urza, Lord High Artificer` e
`Meren of Clan Nel Toth` tambem passaram por prova app runtime real no Android
fisico `SM A135M`.

## Escopo e seguranca

- Incluido: sync de `master`, leitura do relatorio Lote B apply/corpus prep,
  API map e manual, `/health`, `git_sha`, usuarios QA descartaveis mantidos em
  memoria, 5 probes publicas por comandante, summaries sanitizados, scorecard
  com `--runtime-summary` e decisao de promocao.
- Fora do escopo da prova publica original: scanner, camera, OCR, app mobile
  runtime, alteracao de shape de `/ai/generate`, decklists geradas, prompts
  completos, tokens, e-mails QA completos, JWT, Sentry DSN, `DATABASE_URL` e
  `OPENAI_API_KEY`. A prova app runtime complementar foi registrada em
  `app/doc/runtime_flow_handoffs/commander_reference_sprint3_lot_b_app_2026-05-14.md`.
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md` foi consultado e nao foi alterado,
  porque nao houve mudanca de contrato, payload, response shape, diagnostics
  app-facing, data source ou consumidor mobile.

## Commits inspecionados

| Item | Valor |
| --- | --- |
| Branch | `master` |
| Local/origin apos sync | `025d2c36e925793ba0779091527bd922180dc4f4` |
| Backend publico `/health.git_sha` | `025d2c36e925793ba0779091527bd922180dc4f4` |
| Backend publico | `https://evolution-cartinhas.8ktevp.easypanel.host` |

## Comandos executados

```bash
git pull --ff-only origin master
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
python3 <public_probe_sanitized_inline>

cd server
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander="<commander>" \
  --runtime-summary="test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/public_proof/summary.json" \
  --artifact-dir="test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/readiness_public"
```

Fechamento local:

```bash
git diff --check
python3 <summary_assertions_and_secret_scan_inline>
```

As probes publicas foram executadas por script temporario fora do repo, sem
persistir token, e-mail, senha, prompt completo ou decklist. Cada chamada usou
`format=Commander`, `bracket=3`, `commander_name` exato e tema coerente com o
plano Lote B.

## Pass/fail summary

| Commander | Proof | HTTP/validation/commander/main | profile/stats/corpus | fallback | timeout | invalid | off-id | p50 | p95 | Cache hits | Scorecard | Decision |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `Meren of Clan Nel Toth` | PASS | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 5/5 | 0/5 | 0 | 0 | 854ms | 1238ms | 4/5 | score 100, `ready_for_mini_batch` | `promoted=true` |
| `Korvold, Fae-Cursed King` | PASS | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 5/5 | 0/5 | 0 | 0 | 878ms | 942ms | 4/5 | score 100, `ready_for_mini_batch` | `promoted=true` |
| `Sythis, Harvest's Hand` | PASS | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 5/5 | 0/5 | 0 | 0 | 651ms | 667ms | 5/5 | score 100, `ready_for_mini_batch` | `promoted=true` |
| `Urza, Lord High Artificer` | PASS | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5 | 5/5 | 0/5 | 0 | 0 | 652ms | 757ms | 4/5 | score 100, `ready_for_mini_batch` | `promoted=true` |

## Timing summary

Todos os quatro comandantes usaram o caminho deterministico Commander Reference
com `is_mock=true`, profile/stats/corpus ativos, sem timeout fallback e com p95
abaixo de 1.3s no backend publico. A latencia ficou concentrada no request HTTP
publico e na validacao backend; nao houve janela OpenAI lenta ou fallback por
timeout.

O primeiro disparo em sequencia encontrou limite publico `429` apos dez chamadas
bem-sucedidas, afetando Sythis e Urza. Esses summaries iniciais foram preservados
em `public_proof_rate_limited_attempt/` e a prova final foi refeita com backoff.
O rate limit e um risco operacional para scripts de auditoria em lote, nao um
defeito de qualidade do deck gerado.

## App runtime 2026-05-14

| Item | Status | Evidencia | Impacto |
| --- | --- | --- | --- |
| App runtime Lote B fim a fim no `SM A135M` | PASS_WITH_RISKS | `app/doc/runtime_flow_handoffs/commander_reference_sprint3_lot_b_app_2026-05-14.md` | Prova register/login -> Generate Commander -> preview -> save -> Deck Details -> validate para Urza/Meren no backend publico. |
| Urza app/API | PASS | `validation_ok=true`, `main_qty=99`, `total_with_commander=100`, `commander_count=1`, `commander_in_99_count=0`, `off_identity_count=0` | Mono-blue artifacts/control provado no app. |
| Meren app/API | PASS | `validation_ok=true`, `main_qty=99`, `total_with_commander=100`, `commander_count=1`, `commander_in_99_count=0`, `off_identity_count=0` | Golgari graveyard recursion provado no app. |

Riscos app remanescentes: runtime publico usou rede celular no Android, mantendo
o workaround ambiental do Wi-Fi documentado no Lote A; iPhone 15 Simulator nao
foi usado porque o Android primario passou; `GET /decks/:id` retornou o
comandante correto em `commander`, mas o campo agregado `commander_name` nao
refletiu o comandante salvo.

## Artifacts

| Commander | Public proof | Readiness final |
| --- | --- | --- |
| Meren | `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/meren_of_clan_nel_toth/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/meren_of_clan_nel_toth/readiness_public/readiness_scorecard_summary.json` |
| Korvold | `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/korvold_fae_cursed_king/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/korvold_fae_cursed_king/readiness_public/readiness_scorecard_summary.json` |
| Sythis | `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/sythis_harvest_s_hand/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/sythis_harvest_s_hand/readiness_public/readiness_scorecard_summary.json` |
| Urza | `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/urza_lord_high_artificer/public_proof/summary.json` | `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/urza_lord_high_artificer/readiness_public/readiness_scorecard_summary.json` |

## Blockers e riscos

Nao ha blockers para promocao backend/public proof do Lote B. Riscos
remanescentes:

1. O rate limit publico exige backoff em provas de lote para evitar `429`.
2. Urza continua exigindo monitoramento de lane/poder para nao contaminar
   Commander bracket 3 casual com pacote cEDH/stax como default.
3. App runtime real passou com risco ambiental de rede celular no Android; Wi-Fi
   e iPhone 15 Simulator permanecem nao provados nesta rodada.
4. Scanner/camera/OCR permaneceram fora do escopo.

## Decisao

Promovidos para mini-batch controlado:

- `Meren of Clan Nel Toth`
- `Korvold, Fae-Cursed King`
- `Sythis, Harvest's Hand`
- `Urza, Lord High Artificer`

Resultado final: **PASS_WITH_RISKS**.
