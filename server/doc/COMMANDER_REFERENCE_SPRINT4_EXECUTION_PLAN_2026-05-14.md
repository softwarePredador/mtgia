# Commander Reference Sprint 4 Execution Plan - 2026-05-14

## Resultado

**PASS_WITH_RISKS.**

Sprint 4 comecou como expansao controlada e documental: os subagentes paralelos
produziram cobertura, auditoria de pipeline, dry-run de corpus, data quality e
plano runtime sem alterar contratos app-facing. No Lote 1, apenas candidatos
sem blockers entraram em apply/public proof, e somente `Miirym, Sentinel Wyrm`
foi promovido.

Nao houve mudanca de codigo. Propostas de codigo foram documentadas e nao
aplicadas.

Atualizacao Lote 1: `Miirym, Sentinel Wyrm` foi promovido para
`ready_for_mini_batch` apos apply/idempotencia, public proof 5/5 e scorecard
100. `Feather, the Redeemed` nao foi promovido porque a revalidacao do deploy
atual bloqueou o public proof por `invalid_cards_total=5` e p95 alto, alem do
historico anterior de `timeout_fallback_count=5`. `Ghave, Guru of Spores` e
`Jodah, the Unifier` permanecem bloqueados por profile/card_stats ausentes ou
legados.

## Contexto operacional

- Repo: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- Branch alvo: `master`
- Backend publico: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Estado local no Lote 1: `master...origin/master`, alinhado antes da execucao.
- Scanner, camera e OCR permaneceram fora do escopo.
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md` foi consultado e nao foi alterado
  porque nao houve mudanca de rota, payload, response shape, data source,
  diagnostics app-facing ou consumidor mobile.

## Subagentes executados

| Track | Subagente | Relatorio | Resultado |
| --- | --- | --- | --- |
| A | Commander Meta Web Research Analyst | `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT4_TRACK_A_COVERAGE_2026-05-14.md` | PASS_WITH_RISKS |
| B | Commander Reference Quality Engineer | `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT4_TRACK_B_PIPELINE_AUDIT_2026-05-14.md` | PASS_WITH_RISKS / NO-GO expansao ampla |
| C | Commander Reference Quality Engineer | `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT4_TRACK_C_CORPUS_DRY_RUN_2026-05-14.md` | PASS_WITH_RISKS / NO-APPLY |
| D | MTG Data Integrity Maintainer | `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT4_TRACK_D_DATA_QUALITY_2026-05-14.md` | PASS_WITH_RISKS |
| E | Mobile Runtime Device QA | `app/doc/runtime_flow_handoffs/COMMANDER_REFERENCE_SPRINT4_TRACK_E_RUNTIME_PLAN_2026-05-14.md` | PASS_WITH_RISKS / PLAN-ONLY |

## Decisao de fila Sprint 4

### Ordem recomendada para execucao curta

| Ordem | Commander | Estado | Proximo gate |
| ---: | --- | --- | --- |
| 1 | `Feather, the Redeemed` | Profile/card_stats resolvidos; corpus dry-run PASS 4/4 | apply controlado + idempotencia + scorecard |
| 2 | `Miirym, Sentinel Wyrm` | Profile/card_stats resolvidos; corpus dry-run PASS 5/5 | apply controlado + idempotencia + scorecard |
| 3 | `Ghave, Guru of Spores` | Corpus dry-run PASS 5/5; sem profile/card_stats | criar profile/card_stats antes de apply |
| 4 | `Jodah, the Unifier` | Corpus dry-run PASS 5/5; profile legado nao utilizavel | criar profile Commander Reference e stats antes de apply |

### Alternativa de cobertura

Track A tambem recomendou `Chulane, Teller of Tales` e `K'rrik, Son of Yawgmoth`
como candidatos de cobertura forte. Como Track C/D executaram dry-run/data quality
nos quatro candidatos preselecionados pelo orquestrador, Chulane/K'rrik ficam como
backlog ate receberem o mesmo gate DB-backed.

## Resultado do corpus dry-run

Artifacts sanitizados mantidos em:
`server/test/artifacts/commander_reference_sprint4_candidates_2026-05-14/`

| Commander | Dry-run | Decks aceitos | Commander/main | unresolved | off_color | singleton | DB mutations |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `Feather, the Redeemed` | PASS | 4/4 | 1/99 em 4/4 | 0 | 0 | limpo | false |
| `Ghave, Guru of Spores` | PASS | 5/5 | 1/99 em 5/5 | 0 | 0 | limpo | false |
| `Jodah, the Unifier` | PASS | 5/5 | 1/99 em 5/5 | 0 | 0 | limpo | false |
| `Miirym, Sentinel Wyrm` | PASS | 5/5 | 1/99 em 5/5 | 0 | 0 | limpo | false |

Os `corpus.json` brutos usados para alimentar o dry-run foram removidos do
conjunto versionavel por conterem listas completas. Permanecem apenas
`source_summary_sanitized.json` e summaries de dry-run.

## Pipeline blockers antes de ampliar

1. Tratar OpenAI `429/5xx` com fallback deterministico validado ou erro
   sanitizado, sem retornar body bruto do provider.
2. Incluir prompt policy version na cache key do caminho archetype reuse.
3. Atualizar ou criar checklist de readiness operacional para diversity,
   compliance, rate-limit, iPhone e dedupe.
4. Evitar raw decklists em artifacts versionados.
5. Adicionar dedupe por canonical `source_url`/`deck_hash` no runner ou checklist.
6. Provar iPhone 15 Simulator ou registrar `not_proven` com fallback Android
   aceito explicitamente.
7. Atualizar API contracts de `reference_deck_corpus_v3` para v4 em rodada doc
   futura, sem mudar shape app-facing.

## Criterios de promocao Sprint 4

Um comandante Sprint 4 so pode ser promovido se cumprir todos os gates:

1. Corpus offline/sanitizado preparado e dry-run DB-backed PASS.
2. `--apply` executado somente apos aprovacao explicita e novo dry-run pre-apply.
3. Idempotencia PASS.
4. Readiness local sem runtime summary sem blockers criticos.
5. Public proof 5/5 no backend publico com `commander_name` exato, HTTP 200,
   validacao, comandante preservado, main deck 99, profile/stats/corpus usados,
   invalid/off-identity 0 e timeout fallback 0.
6. Scorecard com `--runtime-summary` retorna `score=100`,
   `ready_for_mini_batch`, sem blockers/warnings.
7. App runtime: iPhone 15 como alvo primario quando MLImage/scanner permitir; se
   bloqueado, Android fisico pode sustentar PASS_WITH_RISKS com o blocker
   explicitado.

## Proximos comandos de execucao

### Pre-flight

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short --branch
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
```

### Apply controlado apenas apos aprovacao

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/<source_private_or_regenerated>/<commander>/corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/<safe_path>/<commander>/dry_run_pre_apply

dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/<source_private_or_regenerated>/<commander>/corpus.json \
  --apply \
  --artifact-dir=test/artifacts/<safe_path>/<commander>/apply

dart run bin/commander_reference_readiness_scorecard.dart \
  --commander="<commander>" \
  --artifact-dir=test/artifacts/<safe_path>/<commander>/readiness_after_corpus
```

### Runtime/public proof

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
flutter devices --no-version-check
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
```

Depois de public proof sanitizado:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander="<commander>" \
  --runtime-summary="test/artifacts/<safe_path>/<commander>/public_proof/summary.json" \
  --artifact-dir="test/artifacts/<safe_path>/<commander>/readiness_public"
```

## Blockers

- Lote 1 promove apenas `Miirym, Sentinel Wyrm`; `Feather, the Redeemed`
  permanece bloqueado por public proof atual com `invalid_cards_total=5`, p95
  25659ms e historico de timeout fallback publico.
- `Ghave` e `Jodah` precisam de profile/card_stats antes de qualquer apply.
- iPhone 15 ainda depende de resolver ou contornar o blocker historico de
  `MLImage.framework`/scanner mantendo scanner/OCR fora do escopo.
- Raw corpora completos devem ficar fora do commit; se forem necessarios para
  rerun, devem ser regenerados localmente ou armazenados fora do repositorio.

## Resultado final

**PASS_WITH_RISKS.** A fila e os criterios de Sprint 4 estao definidos, os
artifacts versionaveis foram sanitizados, e a unica promocao autorizada no Lote
1 e `Miirym, Sentinel Wyrm`.
