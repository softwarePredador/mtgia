# Semantic Layer v2 Track B - Backfill/Audit - 2026-05-18

## Veredito

PASS_WITH_RISKS.

## Entrega

- Criado `server/bin/semantic_layer_v2_backfill.dart`.
- Modos: `--dry-run` default e `--apply` idempotente.
- Artefato sanitizado: `server/test/artifacts/semantic_layer_v2_backfill_2026-05-18_dry_run/summary_dry_run.json`.
- Apply controlado executado com artefato sanitizado em
  `server/test/artifacts/semantic_layer_v2_backfill_2026-05-18_apply/summary_apply.json`.

## Dry-run sanitizado

- `db_mutations=false`
- `card_rows=33435`
- `tagged_rows=24172`
- `unknown_rows=9263`
- `ambiguous_rows=3643`
- `coverage_pct=72.295`
- `false_positive_candidates`: `blink_like_removal=59`, `expensive_ramp_review=40`
- `regressions={}`

O artefato contem somente agregados e nao salva texto de regras bruto, ids,
decklists, tokens, chaves, URLs de conexao ou e-mails QA.

## Apply controlado

- `db_mutations=true`
- `card_rows=33435`
- `tagged_rows=24172`
- `unknown_rows=9263`
- `ambiguous_rows=3643`
- `coverage_pct=72.295`
- `upserted_semantic_rows=24172`
- `upserted_function_tag_rows=52797`
- `false_positive_candidates`: `blink_like_removal=59`, `expensive_ramp_review=40`
- `regressions={}`

O apply cria/atualiza apenas tabelas semanticas aditivas e preserva o uso em
shadow mode para optimize/generate.
