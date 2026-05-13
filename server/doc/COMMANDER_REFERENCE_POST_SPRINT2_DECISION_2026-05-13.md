# Commander Reference Post-Sprint 2 Decision - 2026-05-13

## Resultado final

**PASS WITH RISKS.**

Sprint 3 pode ser aberto apenas em modo controlado e com gates obrigatorios. A
decisao e **GO condicionado** para discovery/corpus pequenos e **NO-GO** para
promocao ampla ou guidance forte sem repetir as provas por comandante e sem
manter prova de valor app + comparativo publico atualizados.

## Evidencias lidas

| Evidencia | Resultado | Impacto |
| --- | --- | --- |
| Sprint 2 public proof | PASS WITH RISKS | Kinnan, Muldrotha, Yuriko, Winota e Atraxa promovidos; Korvold bloqueado por `core_package_weak`, `public_runtime_gate_not_passed` e timeout fallback 2/5. |
| App Value Proof | PASS | Fluxo app provou register/login, generate async com `commander_name`, preview, save, Deck Details e validate para Prosper, Edgar e Aesi, sem scanner/camera/OCR. |
| Value Comparison | PASS | `commander_name` preservou comandante em 18/18, ativou profile/stats/corpus em 18/18 e teve p95 1084ms; baseline prompt-only preservou 1/18 e teve 17/18 timeout fallbacks. |
| API contract map | Stable | `server/doc/API_CONTRACTS_AND_DATA_MAP.md` continua coerente; nao houve drift real de metodo, rota, body obrigatorio, response shape, diagnostics opcionais, async jobs ou consumer mobile. |

## GO/NO-GO para Sprint 3

| Escopo | Decisao | Condicao |
| --- | --- | --- |
| Planejar fila e preparar corpus offline | GO | Manter batch pequeno, fontes publicas agregadas, sem decklists completas em prompt/runtime e sem scraping em runtime. |
| Dry-run/apply/idempotencia por comandante | GO condicionado | Executar somente com artifacts sanitizados, comandante resolvido, `main_quantity=99`, `unresolved=0`, `off_color=0` e singleton limpo fora de terrenos basicos. |
| Promover comandante para guidance forte | NO-GO ate prova completa | Exige public proof 5/5, scorecard PASS score 100, timeout fallback 0, app value proof atualizado e comparativo publico atualizado. |
| Expandir em massa ou tratar diagnostics como obrigatorios | NO-GO | Diagnostics, timings, cache/profile/stats/corpus continuam opcionais/experimentais; `generated_deck` e `validation` seguem fonte app-facing de verdade. |

## Regra operacional

Nao iniciar Sprint 3 sem prova de valor app PASS e comparativo publico PASS
registrados. Para cada fechamento de batch, repetir ou referenciar evidencia
atual que prove:

1. O app gera valor no fluxo mobile real: preview, save, Deck Details e validate
   com `commander_name`, sem scanner/camera/OCR e sem raw 4xx/5xx exposto ao
   usuario.
2. O comparativo publico mostra ganho claro de `commander_name` contra baseline
   prompt-only em preservacao do comandante, profile/stats/corpus, latencia e
   ausencia de timeout fallback.
3. Qualquer mudanca de rota, payload, response field, diagnostics app-facing,
   async job ou consumer mobile atualiza `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
   no mesmo commit.

## Riscos aceitos

| Risco | Mitigacao |
| --- | --- |
| Korvold ainda fraco/lento | Reentrar apenas apos reforco de corpus/core package e public proof sem timeout fallback. |
| App value proof nao foi target-specific para os seis Sprint 2 commanders | Usar a prova como evidencia de fluxo, nao como aprovacao individual; novos batches devem atualizar a prova quando houver mudanca de fluxo ou risco de UX. |
| Comparativo publico foi contract-level, nao por cada Sprint 2 target | Tratar como prova de valor de `commander_name`; qualquer comandante novo ainda precisa public proof proprio. |
| Rate limit publico pode contaminar probes | Executar janelas rate-limit-safe e sobrescrever summaries somente com probes limpos. |
| Drift acidental em diagnostics/async jobs | Manter diagnostics opcionais e conferir o API map antes de qualquer mudanca app-facing. |

## Decisao

**PASS WITH RISKS** para seguir para Sprint 3 com guardrails. **NO-GO** para
promocao automatica, expansao em massa ou qualquer Sprint 3 sem prova de valor app
e comparativo publico atuais.
