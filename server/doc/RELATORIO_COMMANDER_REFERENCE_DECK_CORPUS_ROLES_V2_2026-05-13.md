# Commander Reference Deck Corpus Roles v2 — 2026-05-13

## Verdict

**PASS** para o refinamento do classificador de roles do corpus Lorehold.

O objetivo era reduzir o bucket generico `other` antes de expandir o corpus
para mais comandantes. O corpus de `Lorehold, the Historian` foi reprocessado
com roles especificos de spellslinger/topdeck/big spells.

## Roles adicionados

- `spellslinger`;
- `miracle_topdeck`;
- `exile_value`;
- `big_spell_payoff`;
- `recursion`;
- `ritual_treasure`.

## Resultado agregado

| Role | Antes | Depois |
| --- | ---: | ---: |
| `other` | `27.00` | `13.00` |
| `miracle_topdeck` | `0.00` | `4.33` |
| `big_spell_payoff` | `0.00` | `7.67` |
| `ritual_treasure` | `0.00` | `10.00` |
| `spellslinger` | `0.00` | `3.67` |
| `exile_value` | `0.00` | `3.67` |
| `recursion` | `0.00` | `4.33` |
| `protection` | `2.33` | `3.67` |

Outros roles tambem foram redistribuidos:

- `lands`: `32.00`;
- `interaction`: `4.33`;
- `draw_value`: `2.67`;
- `creature`: `3.67`;
- `board_wipe`: `2.00`;
- `win_condition`: `1.33`;
- `ramp`: `3.67`.

## Comandos executados

```bash
cd server && dart test test/commander_reference_deck_corpus_support_test.dart -r expanded
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --dry-run --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/dry_run
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --apply --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --apply --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply_idempotency
cd server && dart analyze lib routes test
cd server && dart test test/commander_reference_deck_corpus_support_test.dart test/ai_generate_performance_support_test.dart test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart -r expanded
```

## Correcao de falsos positivos

A primeira passada publica mostrou que a nova taxonomia estava semanticamente
melhor, mas ainda havia falso positivo em roles relevantes:

- `Deflecting Swat` caiu como `big_spell_payoff`; agora e `protection`.
- `Hit the Mother Lode` e `Call Forth the Tempest` agora priorizam
  `big_spell_payoff` antes de heuristicas de topdeck.

Tambem foi ajustado o budget default do caminho OpenAI com referencia
Commander/Brawl de `20s` para `24s`. O caminho legado sem referencia continua
usando o timeout existente.

## Artifacts

- `server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/dry_run/lorehold_the_historian_dry_run_summary.json`;
- `server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply/lorehold_the_historian_apply_summary.json`;
- `server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply_idempotency/lorehold_the_historian_apply_summary.json`.

## Riscos

- O classificador ainda e heuristico e focado em Lorehold; ao expandir para
  outros arquétipos, novos roles devem ser adicionados com testes.
- A primeira prova publica v2 antes do ajuste de timeout preservou legalidade,
  mas subiu fallback por timeout. A expansao para novos comandantes permanece
  bloqueada ate a prova publica pos-deploy do ajuste de `24s`.

## Prova publica pos-deploy

Backend publico: `353ab5737e407a802eaac78733bdde53303f9ab6`.

| Modo | HTTP 200 | Validacao | Lorehold preservado | Corpus usado | Fallback | Overlap top40 medio | p95 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| com `commander_name` | `5/5` | `5/5` | `5/5` | `5/5` | `1/5` | `11.6` | `24922ms` |
| sem `commander_name` | `5/5` | `5/5` | `0/5` | `0/5` | `5/5` | `0.0` | `12667ms` |

Comparacao com a prova publica anterior (`9909e0b`):

- antes com corpus: fallback `0/5`, overlap medio `16.2`, p95 `21034ms`;
- agora com roles v2 + timeout `24s`: fallback `1/5`, overlap medio `11.6`,
  p95 `24922ms`;
- baseline sem comandante piorou na amostra atual e nao preservou Lorehold.

Conclusao: a taxonomia ficou semanticamente mais correta e reduz `other`, mas
o gate de expansao nao foi atingido porque a prova publica piorou fallback,
overlap e latencia contra a rodada anterior. Nao expandir corpus ainda.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/public_expanded/summary.json`.

## Proximo gate

Antes de expandir para novos comandantes, ajustar guidance/prompt de corpus
para recuperar aderencia top40 sem depender de fallback. Candidatos:

- separar cards obrigatorios/core package de cards apenas contextuais;
- reduzir tokens do prompt mantendo top packages mais importantes;
- medir `reference_deck_evaluation` por roles, nao apenas overlap top40;
- repetir prova publica ate atingir fallback `0/5` ou justificar
  explicitamente a latencia/risco.
