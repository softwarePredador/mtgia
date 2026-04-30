# Relatorio Commander Optimize Flow Audit - 2026-04-30

## Escopo

- Repo: `softwarePredador/mtgia`
- Branch: `master`
- Pasta auditada: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- Areas auditadas antes da alteracao:
  - `app/lib/features/decks`
  - `app/lib/features/cards`
  - `server/routes/ai`
  - `server/routes/decks`
  - `server/lib/meta`
  - `server/lib/ai`

## Veredito

**PASS.** O sprint conectou o pipeline Commander/meta/IA a valor visivel no app sem alterar contratos JSON obrigatorios.

O usuario agora consegue entender:

- se o deck Commander tem comandante, identidade de cor e contagem correta;
- por que uma validacao falhou e qual acao tomar;
- quais referencias meta influenciaram uma otimizacao quando o backend envia contexto;
- a diferenca entre ajuste leve, rebuild guiado e competitivo/cEDH;
- que preview vem antes de apply.

## Mudancas implementadas

| Area | Mudanca | Contrato |
| --- | --- | --- |
| Deck Detail | Resumo Commander com comandante, identidade, contagem 100, preco/curva e status visual. | Sem alteracao JSON. |
| Validate Deck | Falhas comuns viram explicacao amigavel + acao sugerida. | Consome `error`/`card_name` atuais. |
| Apply validation | `isDeckValidationOk()` aceita `ok`, `valid` e `is_valid`. | Compatibilidade com `POST /decks/:id/validate` atual (`ok: true`). |
| Meta Intelligence UI | Preview mostra `meta_reference_context` quando disponivel. | Campo opcional ja emitido pelo backend. |
| Optimize/Generate | Copy diferencia proposta revisavel, ajuste leve, rebuild guiado e competitivo/cEDH. | Sem alteracao JSON. |
| Optimize empty state | Fallback `midrange` visivel se `/ai/archetypes` retorna sem opcoes. | Sem alteracao JSON. |

## Contratos relevantes

- `server/routes/decks/[id]/validate/index.dart` retorna `{"ok": true}` em sucesso e `{"ok": false, "error": "...", "card_name": "..."}` em falhas de regra.
- `server/routes/ai/optimize/index.dart` e `server/lib/ai/optimize_complete_support.dart` ja emitem `meta_reference_context` em respostas de optimize/complete.
- `server/lib/meta/meta_deck_reference_support.dart` monta campos como `meta_scope`, `selection_reason`, `priority_source`, `references` e `suggested_cards_influenced`.

## Validacao executada

| Check | Resultado |
| --- | --- |
| `cd app && flutter analyze lib/features/decks lib/features/cards test/features/decks test/features/cards --no-version-check` | PASS sem issues |
| `cd app && flutter test test/features/decks test/features/cards --no-version-check` | PASS: `00:17 +137: All tests passed!` |
| `cd server && dart analyze routes/decks routes/ai lib/ai lib/meta test` | PASS sem issues |
| `cd server && dart test -r expanded` | PASS: `00:04 +556: All tests passed!` |
| Backend temporario `PORT=8082 dart run .dart_frog/server.dart` + `/health` | PASS healthy |
| `cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart run bin/run_commander_only_optimization_validation.dart --dry-run` | PASS, 19 candidatos |
| `cd app && flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" ...` | PASS, `01:13 +1: All tests passed!` |

## Runtime iPhone 15

Fluxo provado com backend real `http://127.0.0.1:8082`:

1. Registro e login.
2. Criacao de deck Commander.
3. Import do comandante `Talrand, Sky Summoner`.
4. Deck Detail com commander importado.
5. Sheet de otimizacao com acao visivel.
6. Complete async: `POST /ai/optimize -> 202` e 4 polls `GET /ai/optimize/jobs/<id> -> 200`.
7. Preview antes de apply.
8. Bulk/apply persistido.
9. Validate final alcançado com screenshot `10_complete_validated`.

Tempos observados no runtime:

- `POST /auth/register -> 201 (2600ms)`
- `POST /import/to-deck -> 200 (5268ms)`
- `POST /ai/archetypes -> 200 (8591ms)`
- `POST /ai/optimize -> 202 (5502ms)`
- `POST /decks/<id>/cards/bulk -> 200 (4944ms)`

Observabilidade:

- Slow requests foram registrados como breadcrumbs de observability.
- Nao houve crash, overflow visual, timeout final, erro cru user-facing, 4xx ou 5xx no runtime final.
- Warning local esperado: plugins iOS simulator sem arm64 para Apple Silicon iOS 26+, mas o build/test no iPhone 15 executou e passou.

## Evidencias

- Handoff: `app/doc/runtime_flow_handoffs/deck_runtime_iphone15_simulator_2026-04-30.md`
- Proof logs: `app/doc/runtime_flow_proofs_2026-04-30_deck_meta_validate/`
- App audit: `app/doc/APP_AUDIT_2026-04-29.md`
- UX audit: `docs/qa/manaloom_ux_psychology_design_audit_2026-04-30.md`

## Riscos e proximos passos

- O runtime final passou, mas `/ai/archetypes` ainda e lento em deck minimo (`~8.6s`). O fallback visual impede vazio/travamento, mas otimizacao futura deve reduzir tempo ou mostrar progresso mais granular.
- Meta Intelligence depende de `meta_reference_context`; quando o backend nao envia o campo, o preview permanece sem a secao meta por design.
