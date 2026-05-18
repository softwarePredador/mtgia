# Optimize Aggressive Utility + Rate Limit Tuning - 2026-05-18

## Scope

Objetivo: transformar os riscos aceitos do release interno non-scanner em
criterios objetivos de acompanhamento:

- `intensity=aggressive` deve diferenciar sugestoes aplicaveis, no-op seguro,
  bloqueio por quality gate e baixa cobertura de candidatos;
- respostas `429` devem carregar metadados suficientes para retry/backoff e
  telemetria sem expor payload sensivel.

Scanner/camera/OCR nao entrou no escopo.

## Changes

### Aggressive optimize utility

`/ai/optimize` agora adiciona o campo opcional
`optimize_diagnostics.aggressive_candidate_quality.utility_signal` para
`intensity=aggressive`.

Campos:

- `status`: `actionable`, `partial_actionable`, `quality_rejected`,
  `low_coverage` ou `no_safe_swaps`;
- `requested_swaps` e `returned_swaps`;
- `returned_ratio`;
- `has_actionable_swaps`;
- `needs_product_explanation`;
- `user_message_key` para UX amigavel.

Tambem foi adicionada a funcao de scorecard
`summarizeAggressiveOptimizeUtilitySamples`, usada para medir taxa de decks
eligiveis com swaps aplicaveis. O gate recomendado para producao ampla e
`>=70%` de amostras elegiveis com ao menos uma sugestao aplicavel.

### Rate limit contract

Respostas `429` agora usam shape padronizado e aditivo:

- `retry_after`;
- `retry_after_seconds`;
- `retry_after_ms`;
- `rate_limit_bucket` (`generic`, `auth`, `ai`);
- `rate_limit_scope=client`;
- `rate_limit_backend` quando aplicavel.

Headers 429 tambem incluem:

- `Retry-After`;
- `X-RateLimit-Limit`;
- `X-RateLimit-Remaining=0`;
- `X-RateLimit-Window`;
- `X-RateLimit-Reset`.

## Validation plan

Comandos esperados para fechamento:

```bash
cd server && dart analyze lib routes test
cd server && dart test test/rate_limit_middleware_test.dart test/optimize_runtime_support_test.dart test/optimize_learning_pipeline_test.dart
cd app && flutter analyze lib test --no-version-check
cd app && flutter test test/features/decks/providers/deck_provider_test.dart --no-version-check
```

## Remaining risks

- Este patch melhora contrato, medicao e UX explainability; ele nao garante que
todo deck real agressivo retorne swaps aplicaveis.
- A promocao para producao ampla deve exigir uma rodada publica com fixtures de
Commander variados e scorecard `passes_utility_gate=true`.
