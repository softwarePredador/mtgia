# Commander Reference Sprint 2 Apply - 2026-05-13

## Verdict

**PASS WITH RISKS.**

Os corpora Sprint 2 de `Kinnan, Bonder Prodigy`,
`Korvold, Fae-Cursed King`, `Muldrotha, the Gravetide`,
`Yuriko, the Tiger's Shadow`, `Winota, Joiner of Forces` e
`Atraxa, Praetors' Voice` foram revalidados, aplicados e reexecutados para
idempotencia com sucesso.

O resultado permanece **WITH RISKS** porque o scorecard pos-corpus foi
executado intencionalmente sem runtime summary/prova publica. Todos os
comandantes ficaram com `public_runtime_proof_missing`; Korvold tambem ficou
com `core_package_weak`. Nao houve promocao para mini-batch nesta etapa.

## Escopo

- Incluido: dry-run recheck, `--apply`, `--apply` de idempotencia, scorecard
  read-only pos-corpus, contagens DB-backed, artifacts e documentacao.
- Fora do escopo: scanner, camera, OCR, app mobile, endpoints app-facing,
  runtime proof publico, mudancas em `/ai/generate`, `/ai/optimize` ou contratos
  mobile.

## Comandos executados

Comandos por comandante, sempre a partir de `server/`:

```bash
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint2_2026-05-13/<safe_commander>/corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_sprint2_2026-05-13/<safe_commander>/dry_run_recheck

dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint2_2026-05-13/<safe_commander>/corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_sprint2_2026-05-13/<safe_commander>/apply

dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint2_2026-05-13/<safe_commander>/corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_sprint2_2026-05-13/<safe_commander>/apply_idempotency

dart run bin/commander_reference_readiness_scorecard.dart \
  --commander="<commander>" \
  --artifact-dir=test/artifacts/commander_reference_sprint2_2026-05-13/<safe_commander>/readiness_after_corpus
```

Validação local:

```bash
dart analyze lib routes test
dart test \
  test/commander_reference_deck_corpus_support_test.dart \
  test/commander_reference_readiness_support_test.dart \
  test/commander_reference_profile_support_test.dart \
  test/commander_reference_card_stats_support_test.dart
```

## Resultado por comandante

| Commander | Decks | Dry-run recheck | Apply | Idempotency | Readiness after corpus |
| --- | ---: | --- | --- | --- | --- |
| `Kinnan, Bonder Prodigy` | 4 | PASS | PASS, 4/4 aceitos | PASS, 4/4 aceitos | PASS_WITH_RISKS, score 98, `profile_ready_needs_proof`, `public_runtime_proof_missing` |
| `Korvold, Fae-Cursed King` | 4 | PASS | PASS, 4/4 aceitos | PASS, 4/4 aceitos | PASS_WITH_RISKS, score 90, `profile_ready_needs_proof`, `core_package_weak`, `public_runtime_proof_missing` |
| `Muldrotha, the Gravetide` | 4 | PASS | PASS, 4/4 aceitos | PASS, 4/4 aceitos | PASS_WITH_RISKS, score 98, `profile_ready_needs_proof`, `public_runtime_proof_missing` |
| `Yuriko, the Tiger's Shadow` | 4 | PASS | PASS, 4/4 aceitos | PASS, 4/4 aceitos | PASS_WITH_RISKS, score 98, `profile_ready_needs_proof`, `public_runtime_proof_missing` |
| `Winota, Joiner of Forces` | 4 | PASS | PASS, 4/4 aceitos | PASS, 4/4 aceitos | PASS_WITH_RISKS, score 98, `profile_ready_needs_proof`, `public_runtime_proof_missing` |
| `Atraxa, Praetors' Voice` | 5 | PASS | PASS, 5/5 aceitos | PASS, 5/5 aceitos | PASS_WITH_RISKS, score 98, `profile_ready_needs_proof`, `public_runtime_proof_missing` |

Todos os summaries de dry-run/apply/idempotencia confirmaram:

- `accepted_deck_count == deck_count`;
- `rejected_deck_count=0`;
- `unresolved_count=0`;
- `off_color_count=0`;
- `commander_quantity=1`;
- `main_quantity=99`;
- `singleton_violations={}`.

## Contagens DB-backed

Antes do apply para os seis alvos:

| Tabela | Linhas |
| --- | ---: |
| `commander_reference_decks` | 0 |
| `commander_reference_deck_cards` | 0 |
| `commander_reference_deck_analysis` | 0 |

Apos apply/idempotencia:

| Tabela | Linhas |
| --- | ---: |
| `commander_reference_decks` | 25 |
| `commander_reference_deck_cards` | 2181 |
| `commander_reference_deck_analysis` | 6 |

O artifact
`server/test/artifacts/commander_reference_sprint2_2026-05-13/db_counts/db_integrity_after_apply.json`
registrou `all_pass=true`. Por comandante, o banco ficou com
`deck_rows=expected_decks`, `accepted_rows=expected_decks`, `analysis_rows=1`,
`unresolved_total=0`, `off_color_total=0`,
`commander_quantity_one_rows=expected_decks`,
`main_quantity_99_rows=expected_decks` e
`singleton_clean_rows=expected_decks`.

## DB changes

Foram executados apenas upserts idempotentes do runner
`bin/commander_reference_deck_corpus.dart`:

- `commander_reference_decks`: 25 decks de referencia aceitos;
- `commander_reference_deck_cards`: 2181 linhas agregadas de cartas por deck,
  board e nome normalizado;
- `commander_reference_deck_analysis`: 6 agregados por comandante.

Nenhuma tabela de `cards`, `sets`, legalidades, usuarios, decks do usuario ou
rotas app-facing foi alterada.

## Rollback

Rollback operacional deve remover somente os registros dos seis corpus aplicados.
Como `commander_reference_deck_cards` usa `ON DELETE CASCADE`, remover as linhas
de `commander_reference_decks` pelos `source_deck_key` dos artifacts remove as
cartas associadas. Em seguida, remover de
`commander_reference_deck_analysis` as seis linhas com `source =
'commander_reference_deck_corpus_v1'` e os nomes dos comandantes deste relatorio.

Nao ha rollback em `cards`, `sets` ou legalidades porque nenhum desses dados foi
mutado.

## Validacao

- `dart analyze lib routes test`: PASS, sem issues.
- Testes focados: PASS, 35 testes.
- Dry-run/apply/idempotencia: PASS para 25/25 decks.
- Scorecard read-only pos-corpus: executado para 6/6 comandantes, todos
  `PASS_WITH_RISKS` por ausencia esperada de prova publica.
- DB integrity artifact: `all_pass=true`.

## Riscos e gaps remanescentes

- `public_runtime_proof_missing` permanece para 6/6 comandantes porque a etapa
  solicitada nao incluiu runtime summary nem prova publica 5x.
- `Korvold, Fae-Cursed King` ficou com `core_package_weak` no scorecard
  pos-corpus (`corpus_core_package_count=15`), entao exige revisao de corpus/core
  package antes de qualquer promocao.
- `promoted` permanece `PENDING` para todos os comandantes deste apply.
