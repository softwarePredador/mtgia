# Deck Generation Focus Readiness - 2026-06-16

## Objetivo

Validar se o projeto ja pode voltar o foco para geracao/otimizacao de decks ou
se ainda existe bloqueio imediato na camada de battle/Hermes.

## Conclusao

Status: **pronto para focar geracao/optimize com riscos controlados**.

Battle/Hermes continua importante como laboratorio e scorecard, mas os achados
recentes de blocker imediato ja foram tratados em `master`:

- decisoes de fast mana/land tutor foram endurecidas para nao gastar recurso
  sem payoff claro;
- tapped lands passaram a atrasar mana no goldfish;
- checks recentes de stax, value engine, ritual simples e combo pieces ja
  estao cobertos por testes focados;
- decision trace/estrategia continua como backlog Hermes, nao como bloqueio
  para melhorar ranking de candidatos.

## Slice implementado

O primeiro slice de geracao/optimize foi limitado ao pipeline interno de
qualidade de candidatos:

- `server/lib/ai/candidate_quality_data_support.dart`
  - `buildCandidateRoleScores` agora aceita `edhrecInclusionRate` e
    `edhrecSampleDecks`;
  - o bonus EDHREC e limitado e combinado com sinais ja existentes
    (`card_meta_insights`, tags deterministicas, preco/CMC);
  - a evidencia do role score passa a registrar
    `edhrec_inclusion_rate` e `edhrec_sample_decks` quando usados.
- `server/bin/candidate_quality_data_foundation.dart`
  - le `edhrec_card_snapshots` opcionalmente;
  - se a tabela nao existir, cai para `0` e preserva comportamento antigo;
  - agrega por `LOWER(card_name)` antes de juntar com `cards`, evitando fanout;
  - adiciona `cards_with_edhrec_signal` ao resumo de dry-run.
  - `--apply` agora aborta stale prune grande por padrao; para ultrapassar o
    limite por tabela e obrigatorio passar `--allow-large-stale-prune` depois
    de revisar `stale_generated_rows_preview.*`.
- `server/test/candidate_quality_data_support_test.dart`
  - cobre que o sinal EDHREC aumenta score de forma bounded e aparece na
    evidencia.

Este slice nao muda API publica, nao muda app Flutter e nao promove metadata
Hermes para usuarios normais.

## Evidencia de dry-run real

Comando:

```bash
cd server
dart run bin/candidate_quality_data_foundation.dart \
  --dry-run \
  --artifact-dir=/tmp/mtgia_candidate_quality_edhrec_dry_run_20260616
```

Resumo:

- `cards_scanned`: 33839
- `cards_with_edhrec_signal`: 4183
- `role_score_rows_planned`: 54417
- `function_tag_coverage_pct`: 74.08611365584089
- `edhrec_card_snapshots`: 10586
- `card_role_scores` atuais antes do apply: 46335

Observacao: o dry-run mostrou `3263` stale `card_role_scores` gerados pela
fonte heuristica. Isso nao foi aplicado neste slice; qualquer prune/apply deve
ser feito em janela controlada e com artefato revisado.

## Validacoes executadas

```bash
cd server
dart format lib/ai/candidate_quality_data_support.dart \
  bin/candidate_quality_data_foundation.dart \
  test/candidate_quality_data_support_test.dart
dart analyze bin/candidate_quality_data_foundation.dart \
  lib/ai/candidate_quality_data_support.dart \
  test/candidate_quality_data_support_test.dart
dart test test/candidate_quality_data_support_test.dart -r expanded
dart run bin/candidate_quality_data_foundation.dart \
  --dry-run \
  --artifact-dir=/tmp/mtgia_candidate_quality_edhrec_dry_run_20260616
dart run bin/candidate_quality_data_foundation.dart \
  --apply \
  --max-stale-prune-on-apply=0 \
  --artifact-dir=/tmp/mtgia_candidate_quality_apply_guard_20260616
```

Resultado: analyze sem issues, testes focados passando, dry-run concluido e
guard de apply confirmado. Com limite zero, o comando abortou antes de mutar o
banco com:

```text
Apply abortado: stale prune acima do limite por tabela
```

## Riscos restantes

- O sinal EDHREC melhora ranking, mas nao deve ser tratado como verdade final de
  Commander para todos os contextos.
- O apply em `card_role_scores` ainda precisa de janela controlada e revisao do
  preview/stale cleanup.
- Battle decision trace ainda e necessario para reduzir falso positivo de WR,
  mas nao bloqueia este slice de geracao.

## Proximos passos

1. Rodar dry-run ampliado e revisar os role scores com maior delta EDHREC.
2. Se aprovado, executar `candidate_quality_data_foundation.dart --apply` em
   janela controlada. Se o stale prune continuar acima do limite, usar
   `--allow-large-stale-prune` somente apos revisar o preview.
3. Rodar scorecard de optimize/generate com Lorehold e outros comandantes.
4. Manter Hermes em report-only para decision trace e estrategia de jogadas.
