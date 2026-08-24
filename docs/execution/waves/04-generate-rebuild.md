# Onda 04 — Generate e Rebuild allowlisted

Objetivo: gerar e reconstruir somente como preview reidratável, vinculando
entrada, comandante, constraints, job e materialização server-side.

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 1 | `DCK-P0-04` | request/fingerprint persistido e materialização pelo job | resultado A não salva com controles B; cliente não injeta lista; cross-device reidrata input; save usa artifact/ledger |
| 2 | `BT-AI-020` | mock/fallback separado do canônico | mock nunca entra em cache/save/análise persistida; app mantém source/is_mock/persisted e reconcilia por revision |
| 3 | `BT-AI-011` | comandante exato ponta a ponta | primeira resposta e cache hit usam/validam exatamente commander/partner/background solicitados |
| 4 | `DCK-P1-05` | review de Commander + 99 cartas | 100/100 contabilizadas; arte/fallback, função, fonte e blockers inspecionáveis; nada salva antes da decisão |
| 5 | `BT-AI-005` | busca collection-aware sem top-400 cego | corpus prova false-block=0; busca legal/on-color bounded e budgeted |
| 6 | `BT-CAT-01` | refresh de catálogo interno exigido pelo preço | lock/idempotência/budget/audit; usuário não aciona upstream; falhas e retry cobertos |
| 7 | `BT-PRICE-01` | snapshot de preço/freshness | provider/currency/as-of/missing price e cache definidos sem upstream em leitura de usuário |
| 8 | `BT-AI-006` | transparência de preço e incerteza | hard budget bloqueia missing; fonte/câmbio/freshness visíveis; copy não promete loja/frete |
| 9 | `DCK-P1-08` | Rebuild preview-first e clone privado | default não clona; original invariável; stale bloqueia; retry não duplica; lineage e constraints persistem |
| 10 | `DCK-P1-11` | E2E do ciclo completo | create/import/edit/analyze/preview/apply/undo/delete/restore, isolamento A/B, stale=0 aceito e artifact mismatch=100% bloqueado |

## Prova transversal

- execução assíncrona usa o executor/custo da Onda 03;
- fingerprint inclui formato, comandante composto, bracket e constraints;
- cache hit, miss e primeira execução passam o mesmo validator;
- provider fake, deterministic fallback e timeout ficam rotulados;
- materialização ocorre no backend sob revision/artifact/ledger;
- Generate/Rebuild permanecem `OFF` ou allowlist experimental até receipt e
  release próprios; a beta core não os abre por implicação.

Saída da onda: Generate/Rebuild tecnicamente reprodutíveis e recuperáveis, ainda
sem aprendizado nem abertura pública geral.
