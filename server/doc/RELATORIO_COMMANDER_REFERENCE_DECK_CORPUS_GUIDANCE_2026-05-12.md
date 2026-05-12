# Commander Reference Deck Corpus Guidance — 2026-05-12

## Verdict

**PASS WITH RISKS** para a integracao inicial do corpus agregado no
`/ai/generate`.

O endpoint agora carrega o corpus aceito de `Lorehold, the Historian` quando há
`commander_name` com profile exato e injeta apenas sinais agregados no prompt:

- tamanho do corpus aceito;
- media de roles;
- cartas/pacotes recorrentes com contagem de aparicao;
- instrucao explicita para nao copiar decklist.

Nenhuma decklist completa e enviada para OpenAI.

## Mudancas

- Novo guidance em `server/lib/ai/commander_reference_deck_corpus_support.dart`:
  - `loadCommanderReferenceDeckCorpusGuidance`;
  - `buildCommanderReferenceDeckCorpusPrompt`;
  - `commanderReferenceDeckCorpusCacheVersion`;
  - diagnostics sanitizados via `toDiagnostics`.
- `/ai/generate` agora:
  - carrega corpus apenas quando existe exact reference profile;
  - inclui corpus no cache version;
  - inclui `reference_deck_corpus_*` em diagnostics;
  - preserva fallback/archetype reuse sem corpus.

## Diagnostics novos

Quando corpus e usado, `diagnostics` pode incluir:

- `reference_deck_corpus_used`;
- `reference_deck_corpus_source`;
- `reference_deck_count`;
- `accepted_reference_deck_count`;
- `average_role_counts`;
- `top_card_count`;
- `top_cards` sanitizados (`card_name`, `deck_count`, `role`);
- `theme_counts`.

## Prova local

Backend local: `http://127.0.0.1:8082`.

Resumo da amostra:

| Modo | Probes | Validos | Commander correto | Corpus usado | Overlap top40 |
| --- | ---: | ---: | ---: | ---: | ---: |
| `commander_name=Lorehold, the Historian` | 2 | 2/2 | 2/2 | 2/2 | 10-14 |
| Sem `commander_name` | 2 | 2/2 | 0/2 | 0/2 | 0 |

Observacao: uma amostra com corpus usou fallback por timeout, mas ainda
preservou commander, 99 cartas no main e diagnostics do corpus.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_guidance_lorehold_2026-05-12/local_probe_summary.json`.

## Prova publica

Backend publico:
`https://evolution-cartinhas.8ktevp.easypanel.host`.

Commit publicado: `547cf708e5bac7d3bb771a9c0fa8926113be28f4`.

Resultado sanitizado:

| Campo | Valor |
| --- | --- |
| HTTP | `200` |
| `validation.is_valid` | `true` |
| Commander | `Lorehold, the Historian` |
| Main quantity | `99` |
| `reference_profile_used` | `true` |
| `reference_card_stats_used` | `true` |
| `reference_deck_corpus_used` | `true` |
| `accepted_reference_deck_count` | `3` |
| `reference_deck_count` | `3` |
| `top_card_count` | `40` |
| Fallback | `false` |
| `timings.total_ms` | `15097` |

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_guidance_lorehold_2026-05-12/public_probe_summary.json`.

## Prova publica ampliada

Backend publico:
`https://evolution-cartinhas.8ktevp.easypanel.host`.

Commit publicado: `9909e0be054a16ec1ee10f3fcba121c4e0e2a06f`.

Resultado:

| Modo | Probes | HTTP 200 | Validos | Lorehold preservado | Corpus usado | Fallback | Overlap top40 | p50 | p95 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `commander_name=Lorehold, the Historian` | 5 | 5/5 | 5/5 | 5/5 | 5/5 | 0/5 | 13-19, avg `16.2` | `18232ms` | `21034ms` |
| Sem `commander_name` | 5 | 5/5 | 5/5 | 0/5 | 0/5 | 1/5 | 0-6, avg `3.0` | `11519ms` | `12742ms` |

Conclusao: o guidance de corpus aumentou aderencia estrutural e preservou
Lorehold em todas as amostras. A latencia ficou maior no caminho com corpus,
mas sem fallback e dentro do envelope atual de `/ai/generate`.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_guidance_lorehold_2026-05-12/public_expanded/summary.json`.

## Validações

```bash
cd server && dart analyze bin lib routes test
cd server && dart test test/commander_reference_deck_corpus_support_test.dart -r expanded
```

## Riscos

- `other` no classificador de roles ainda esta alto; o corpus ajuda a estrutura,
  mas ainda precisamos refinar roles como spellslinger, miracle/topdeck,
  exile/value e payoff.
- O caminho com corpus teve p95 `21034ms`; aceitavel para async, mas deve
  seguir monitorado.

## Proximo passo

Refinar o classificador de roles do corpus para reduzir `other` e separar
spellslinger, miracle/topdeck, exile/value, big-spell payoff, recursion e
ritual/treasure antes de expandir o corpus para muitos comandantes.
