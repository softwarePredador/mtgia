# Deck Functional Tags Persisted Source Runtime - 2026-05-18

## Status

`PASS`

## Escopo

Validar no app que a aba de analise do deck consome `functional_tags` do
backend publico e que o backend esta usando a camada semantica persistida
em `card_function_tags`, com fallback heuristico apenas quando necessario.

Scanner/camera/OCR/MLKit ficaram fora do escopo.

## Ambiente

- App runtime: iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`.
- Backend: `https://evolution-cartinhas.8ktevp.easypanel.host`.
- Backend SHA: `04ec676f42f452acbbca3f96a2ee1852015d7974`.
- Teste: `app/integration_test/deck_functional_tags_runtime_test.dart`.

## Resultado

`00:09 +1: All tests passed!`

Resumo sanitizado:

- `analysis_http_status=200`;
- `functional_tags_schema_version=functional_card_tags_v1_2026_05_18`;
- `source_priority=persisted_then_heuristic`;
- `persisted_rows=5`;
- `persisted_copies=5`;
- `heuristic_rows=2`;
- `heuristic_copies=2`;
- `counts.ramp=2`;
- `counts.draw=1`;
- `counts.removal=2`;
- `coverage.card_rows=7`;
- `coverage.tagged_rows=6`;
- UI renderizou a secao de funcoes e exibiu amostra de ramp.

## Evidencia

- `app/doc/runtime_flow_proofs_2026-05-18_deck_functional_tags_persisted_source/summary.json`

## Riscos

- Prova feita em simulador iOS, nao em build assinado em device fisico.
- O warning conhecido de plugins iOS arm64 apareceu no simulador, mas nao
  bloqueou build nem execucao.
- A fixture e pequena; prova contrato runtime e origem persistida, nao
  corretude semantica exaustiva de todas as cartas.
