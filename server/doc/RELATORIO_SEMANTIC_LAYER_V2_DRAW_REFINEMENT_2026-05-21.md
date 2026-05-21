# Semantic Layer v2 Draw Refinement - 2026-05-21

## Veredito

**PASS_WITH_RISKS** para refinamento focado de `draw`.

O mass audit atual mostrou um falso negativo seguro: efeitos explícitos como
`draw four cards` e `draw seven cards` ficavam fora da tag `draw` porque a
heurística só cobria `a/two/three/x` e poucos formatos agregados. A regra foi
ampliada apenas para compra explícita por cardinal ou número no texto Oracle.

## Escopo

Incluído:

- card draw explícito com `one` até `ten` ou quantidade numérica;
- fixtures focadas para `Kozilek, Butcher of Truth` e `Midnight Clock`;
- dry-run e apply idempotente do backfill Semantic v2 para atualizar tags
  persistidas em `card_semantic_tags_v2` e `card_function_tags`.

Fora do escopo:

- `target player draws`, que pode beneficiar oponente ou controlador conforme
  escolha de alvo;
- `investigate` e `connive`, que seguem como seleção/value e precisam de decisão
  de produto antes de contar como compra;
- mudanças em ramp, removal, wipe, protection, Optimize enforcement ou contrato
  app-facing.

## Comparação do mass audit

Audit corrente antes do patch:

- `coverage_pct=72.295`;
- `draw.card_rows=4516`;
- `draw.distinct_card_names=4513`.

Audit corrente depois do patch:

- `coverage_pct=72.322`;
- `draw.card_rows=4570`;
- `draw.distinct_card_names=4567`.

O ganho foi de 54 linhas de cartas `draw` sem abrir regressões agregadas no
backfill.

## Backfill controlado

Artifacts sanitizados:

- dry-run:
  `server/test/artifacts/semantic_layer_v2_draw_refinement_2026-05-21/dry_run/summary_dry_run.json`;
- apply:
  `server/test/artifacts/semantic_layer_v2_draw_refinement_2026-05-21/apply/summary_apply.json`.

Resumo:

| Métrica | Dry-run | Apply |
|---|---:|---:|
| `card_rows` | 33435 | 33435 |
| `tagged_rows` | 24181 | 24181 |
| `unknown_rows` | 9254 | 9254 |
| `ambiguous_rows` | 3654 | 3654 |
| `coverage_pct` | 72.322 | 72.322 |
| `upserted_semantic_rows` | 0 | 24181 |
| `upserted_function_tag_rows` | 0 | 52851 |
| `regressions` | `{}` | `{}` |

Os artifacts guardam apenas agregados; não salvam texto Oracle bruto, ids de
cartas, decklists, secrets, tokens ou e-mails QA.

## Validação executada

```bash
cd server && dart format \
  lib/ai/functional_card_tags.dart \
  test/functional_card_tags_test.dart
cd server && dart analyze \
  lib/ai/functional_card_tags.dart \
  test/functional_card_tags_test.dart
cd server && dart test test/functional_card_tags_test.dart -r expanded
cd server && dart run bin/audit_functional_card_tags_mass.dart \
  --artifact-dir=/tmp/functional_card_tags_mass_audit_2026_05_21_current
cd server && dart run bin/audit_functional_card_tags_mass.dart \
  --artifact-dir=/tmp/functional_card_tags_mass_audit_2026_05_21_draw_refine
cd server && dart run bin/semantic_layer_v2_backfill.dart \
  --dry-run \
  --artifact-dir=test/artifacts/semantic_layer_v2_draw_refinement_2026-05-21/dry_run
cd server && dart run bin/semantic_layer_v2_backfill.dart \
  --apply \
  --artifact-dir=test/artifacts/semantic_layer_v2_draw_refinement_2026-05-21/apply
```

## Prova pública pós-deploy

Backend público:

- SHA:
  `db04b5a105f2fc87cc42aa68ccd8e57dd41954b4`;
- Deck Analysis scorecard:
  `server/test/artifacts/semantic_layer_v2_draw_refinement_2026-05-21/public_analysis_scorecard_summary.json`.

Scorecard público:

| Métrica | Valor |
|---|---:|
| `cases_attempted` | 10 |
| `eligible_cases` | 10 |
| `analysis_http_200_cases` | 10 |
| `analysis_shape_ok_cases` | 10 |
| `blocker_count` | 0 |
| `warning_count` | 0 |
| `decision` | `analysis_payload_ready_for_real_deck_qa` |

Runtime app:

- harness: `app/integration_test/deck_functional_tags_runtime_test.dart`;
- device: iPhone 15 Pro Max Simulator
  `DABB9D79-2FDB-4585-94DB-E31F1288EE74`;
- resultado: `00:10 +1: All tests passed!`;
- runtime confirmou o mesmo backend SHA e a UI de funções do deck com
  explicabilidade visível.

Comandos:

```bash
python3 server/bin/deck_analysis_functional_scorecard.py \
  --expected-sha db04b5a105f2fc87cc42aa68ccd8e57dd41954b4 \
  --limit 10 \
  --output server/test/artifacts/semantic_layer_v2_draw_refinement_2026-05-21/public_analysis_scorecard_summary.json
cd app && flutter test integration_test/deck_functional_tags_runtime_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

## Riscos restantes

- O ganho cobre compra explícita direta; o bucket `draw` ainda não tenta
  resolver toda forma de card advantage contextual.
- Deck Analysis prioriza tags persistidas quando existem; por isso o backfill
  foi necessário nesta rodada.
- O scorecard prova coerência nos corpora completos e o runtime prova a UI, mas
  feedback de carta/tag específica ainda precisa de fixture focada antes de
  ampliar heurística.
