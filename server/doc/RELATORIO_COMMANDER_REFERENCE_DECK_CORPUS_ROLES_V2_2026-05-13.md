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
| `other` | `27.00` | `13.33` |
| `miracle_topdeck` | `0.00` | `7.00` |
| `big_spell_payoff` | `0.00` | `7.67` |
| `ritual_treasure` | `0.00` | `10.00` |
| `spellslinger` | `0.00` | `3.67` |
| `exile_value` | `0.00` | `3.33` |
| `recursion` | `0.00` | `3.33` |

Outros roles tambem foram redistribuidos:

- `lands`: `32.00`;
- `interaction`: `4.33`;
- `protection`: `2.00`;
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
```

## Artifacts

- `server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/dry_run/lorehold_the_historian_dry_run_summary.json`;
- `server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply/lorehold_the_historian_apply_summary.json`;
- `server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply_idempotency/lorehold_the_historian_apply_summary.json`.

## Riscos

- O classificador ainda e heuristico e focado em Lorehold; ao expandir para
  outros arquétipos, novos roles devem ser adicionados com testes.
- A prova publica de `/ai/generate` precisa ser repetida apos deploy para
  confirmar que a nova estrutura melhora ou preserva a aderencia sem elevar
  fallback/latencia.

## Proximo gate

Repetir prova publica ampliada com 5 prompts com `commander_name` e 5 sem,
comparando overlap, fallback e latencia contra a rodada anterior.
