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

## Validações

```bash
cd server && dart analyze bin lib routes test
cd server && dart test test/commander_reference_deck_corpus_support_test.dart -r expanded
```

## Riscos

- A prova publica depende do deploy do commit desta sprint.
- `other` no classificador de roles ainda esta alto; o corpus ajuda a estrutura,
  mas ainda precisamos refinar roles como spellslinger, miracle/topdeck,
  exile/value e payoff.
- A amostra local e pequena; o proximo gate publico deve rodar 5 probes com
  `commander_name` e 5 sem, usando prompts variados.

## Proximo passo

Apos deploy, rodar prova publica em `https://evolution-cartinhas.8ktevp.easypanel.host`
confirmando `reference_deck_corpus_used=true`, `accepted_reference_deck_count=3`,
`validation.is_valid=true`, commander preservado e melhoria de overlap contra o
baseline sem `commander_name`.
