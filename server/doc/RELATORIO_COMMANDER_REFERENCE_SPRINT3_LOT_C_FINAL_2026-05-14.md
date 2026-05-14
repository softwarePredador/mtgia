# Commander Reference Sprint 3 Lote C Final - 2026-05-14

## Verdict

**PASS_WITH_RISKS** para a auditoria/consolidacao final do Lote C.

`Purphoros, God of the Forge` passou no app runtime como deck Commander valido,
mas nao foi promovido no scorecard/backend por gate correto: o runtime publico
nao ativou Commander Reference profile/card_stats/corpus e o scorecard DB-backed
nao encontra profile/card_stats/deterministic reference deck para o comandante.
Nao houve bug seguro de parser, scorecard ou tracker para corrigir nesta rodada.

Decisao para Lote D: **NO-GO** para ampliar como se o Lote C tivesse fechado com
dois promovidos. **GO condicionado** apenas para preparar o menor patch de dados
de Purphoros, Veyran ou Balan, repetir public proof 5/5 e scorecard antes de
qualquer promocao.

## Commits inspecionados

| Item | Valor |
| --- | --- |
| Branch alvo | `master` |
| HEAD local/origin apos sync final | `c182df4ac3a3fb3ad4c88bd61402502434692fa6` |
| Backend publico `/health.git_sha` final | `c182df4ac3a3fb3ad4c88bd61402502434692fa6` |
| Public proof Lote C original | `ca23fc5a16e0b5c194d7375a537e23cf5cd34d2f` |
| App runtime Lote C original | `ef2df98abb9bb8cb2d4b03ca1d3c5d1123da3c86` |
| Backend publico | `https://evolution-cartinhas.8ktevp.easypanel.host` |

## Fontes lidas

- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_PUBLIC_PROOF_2026-05-14.md`
- `app/doc/runtime_flow_handoffs/commander_reference_sprint3_lot_c_app_2026-05-14.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
- `server/manual-de-instrucao.md`
- `server/lib/ai/commander_reference_readiness_support.dart`
- Artifacts `public_proof/` e `readiness_public/` de Purphoros e Brago.

## Comandos executados

```bash
git fetch origin master --quiet
git pull --ff-only origin master --quiet
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health

cd server
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander="Purphoros, God of the Forge" \
  --runtime-summary="test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/purphoros_god_of_the_forge/public_proof/summary.json" \
  --artifact-dir="test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/purphoros_god_of_the_forge/readiness_public_rerun_final"
dart analyze lib routes test
dart test test/commander_reference_readiness_support_test.dart \
  test/commander_reference_deck_corpus_support_test.dart \
  test/ai_generate_performance_support_test.dart
```

## Pass/fail summary

| Item | Resultado |
| --- | --- |
| Sync `master` | PASS |
| Backend publico `/health` | PASS, `git_sha` alinhado com `master` final |
| Scorecard Purphoros rerun | PASS_WITH_RISKS operacional; `score=25`, `blocked`, `ready_count=0` |
| `dart analyze lib routes test` | PASS |
| Testes focados Commander Reference | PASS |
| Mudanca de API shape | Nao houve |
| Secrets/decklists | Nao registrados neste relatorio |

## Purphoros vs Brago

| Campo | Purphoros | Brago |
| --- | --- | --- |
| App runtime | PASS adjunct: deck valido, 99 main, 1 comandante, off-identity 0 | PASS do comandante promovido |
| Public proof | BLOCKED | PASS |
| HTTP/validation/commander/main | 5/5, 5/5, 5/5, 5/5 | 5/5, 5/5, 5/5, 5/5 |
| `profile_used` / `stats_used` / `corpus_used` | 0/5, 0/5, 0/5 | 5/5, 5/5, 5/5 |
| `fallback_count` | 0/5 | 5/5 |
| `timeout_fallback_count` | 0/5 | 0/5 |
| invalid/off-identity | 0 / 0 | 0 / 0 |
| p50 / p95 | 794ms / 12590ms | 864ms / 942ms |
| Scorecard original | 25, `blocked` | 100, `ready_for_mini_batch` |
| Scorecard rerun final | 25, `blocked` | Nao necessario; artifact original ja PASS |
| Promoted | false | true |

## Por que Purphoros passou no app runtime mas nao promoveu

O app runtime prova que o fluxo mobile consegue pedir, salvar, abrir e validar um
deck Commander legal para Purphoros. Esse gate e menor que o gate de promocao
Commander Reference: ele nao exige que a resposta venha do caminho deterministic
reference com profile, card stats e corpus usados.

O scorecard de promocao exige que o backend tenha dados reference suficientes e
que o runtime publico demonstre o uso desses dados. Purphoros falhou nesses
pontos:

- `profile_available=false`, `profile_confidence=not_proven` e
  `profile_source_count=0`.
- `card_stats_count=0` e `card_stats_package_count=0`.
- `commander_card_resolved=false` no scorecard porque nao ha profile carregado
  para alimentar a resolucao do comandante no caminho readiness.
- `deterministic_deck_valid=false` e `deterministic_main_quantity=0`, pois o
  fallback deterministic reference nao pode ser montado sem profile/card_stats.
- O runtime summary mostra `profile_used=0`, `stats_used=0`, `corpus_used=0` e
  `fallback_count=0`; portanto o deck valido veio pelo caminho legacy/nao
  reference.

Isso nao contradiz o app runtime: Purphoros pode ser valido e ainda assim nao
estar promovido como Commander Reference.

## Parser/scorecard/tracker

Nao foi identificado bug seguro:

- O parser `parseCommanderReferenceReadinessRuntimeProof` aceitou o summary
  sanitizado de Purphoros e marcou `available=true`.
- `CommanderReferenceReadinessRuntimeProof.gatePassed` retornou `false` porque
  `corpus_used` ficou 0/5 e o caminho deterministic reference nao foi provado.
- O scorecard adicionou corretamente os blockers de dados e manteve
  `runtime_public_gate_passed=false`.
- O tracker ja marcava Purphoros como `promoted=false`; a app proof ja declarava
  Purphoros como adjunct, nao como segundo promovido.

## Timing summary

Brago ficou no caminho deterministic reference, com `p95=942ms`. Purphoros ficou
no caminho legacy/sem reference, com primeira chamada lenta e `p95=12590ms`, sem
timeout fallback. A latencia alta reforca o blocker de nao promocao, mas nao e o
blocker primario; a falha principal e a ausencia de profile/card_stats/corpus
usados no runtime.

## App/backend contract findings

Nao houve mudanca no shape de `/ai/generate`, nos diagnostics app-facing ou no
contrato de `GET /decks/:id`/validate. `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
permanece sem alteracao.

## Legality/color-identity findings

Purphoros e Brago retornaram `invalid_cards_total=0` e
`off_identity_total=0` no public proof. A nao promocao de Purphoros nao veio de
legalidade Commander, identidade de cor ou preservacao de comandante.

## Sentry/logging findings

Nao houve erro app-facing ou exception nova a registrar. Os artifacts atuais
preservam contadores, gates e timings suficientes para auditoria sem registrar
tokens, e-mails QA completos, JWT, Sentry DSN, `DATABASE_URL`, `OPENAI_API_KEY`,
prompts completos ou decklists geradas.

## Blockers

Purphoros segue bloqueado por:

- `commander_card_not_resolved`
- `profile_missing_or_below_confidence`
- `card_stats_missing`
- `deterministic_reference_deck_invalid`
- `deterministic_main_quantity_not_99`
- warning `public_runtime_gate_not_passed`

## Promovidos, adjuntos e bloqueados

| Commander | Estado final Lote C | Decisao |
| --- | --- | --- |
| `Brago, King Eternal` | Promovido; public proof PASS e score 100 | Pode seguir como mini-batch controlado |
| `Purphoros, God of the Forge` | App runtime adjunct PASS, backend blocked | Nao promover |
| `Veyran, Voice of Duality` | Public proof valido mas sem reference ativo | Nao promover |
| `Balan, Wandering Knight` | Public proof valido mas sem reference ativo | Nao promover |

## Menor proximo patch

1. Criar/aplicar Commander Reference Profile e card_stats resolvidos para
   Purphoros, ou escolher Veyran/Balan se o dado estiver mais barato.
2. Garantir que o scorecard sem runtime summary suba de `blocked` para
   `profile_ready_needs_proof` sem blockers de deterministic deck.
3. Repetir public proof 5/5 com backoff e rerodar scorecard com
   `--runtime-summary`.
4. Promover somente se `profile/stats/corpus` forem usados 5/5, invalid/off-id
   ficarem 0, timeout fallback 0 e scorecard retornar `ready_for_mini_batch`.

## Resultado final

**PASS_WITH_RISKS**: a investigacao esta fechada e os gates estao coerentes, mas
o Lote C final tem apenas um comandante promovido. Lote D fica **NO-GO** para
expansao sem antes corrigir dados reference e reexecutar public proof/scorecard
de um segundo comandante.
