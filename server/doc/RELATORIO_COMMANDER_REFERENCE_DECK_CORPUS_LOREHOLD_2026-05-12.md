# Commander Reference Deck Corpus Lorehold Pilot — 2026-05-12

## Verdict

**PASS WITH RISKS** para o primeiro corpus real de decks completos.

Foram extraidos, validados e persistidos 3 decks publicos de referencia para
`Lorehold, the Historian`, a partir dos deckpreviews EDHREC fornecidos pelo
usuario. O corpus foi gravado nas tabelas `commander_reference_decks`,
`commander_reference_deck_cards` e `commander_reference_deck_analysis`.

## Fontes

| Fonte | Status |
| --- | --- |
| `https://edhrec.com/deckpreview/3SFEtbTKhht92q7FXEd3qA` | Aceito |
| `https://edhrec.com/deckpreview/A_z1s_GftOaC6u75p7_TDw` | Aceito |
| `https://edhrec.com/deckpreview/Bn4UCaNCLKSTPqkwxUnStQ` | Aceito |

O artifact versionado guarda apenas nomes, quantidades, board e metadados de
fonte necessários para analise estrutural. O app nao copia decklist em runtime.

## Backfill oficial de cartas faltantes

O primeiro dry-run rejeitou os 3 decks por lacunas de freshness no banco:

- `Improvisation Capstone`;
- `Erode`;
- `Naktamun Lorespinner`;
- `Restoration Seminar`.

As 4 cartas foram resolvidas por nome exato na API publica do Scryfall e
aplicadas por `oracle_id`, com legalidade Commander preservada.

| Carta | Set | Collector | Identidade | Commander |
| --- | --- | --- | --- | --- |
| `Erode` | `SOS` | `15` | `W` | `legal` |
| `Improvisation Capstone` | `SOS` | `120` | `R` | `legal` |
| `Naktamun Lorespinner // Wheel of Fortune` | `SOC` | `33` | `R` | `legal` |
| `Restoration Seminar` | `SOS` | `30` | `W` | `legal` |

Runner usado:

```bash
cd server && dart run bin/backfill_missing_scryfall_cards.dart --names="Improvisation Capstone|Erode|Naktamun Lorespinner|Restoration Seminar" --dry-run --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/missing_card_backfill
cd server && dart run bin/backfill_missing_scryfall_cards.dart --names="Improvisation Capstone|Erode|Naktamun Lorespinner|Restoration Seminar" --apply --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/missing_card_backfill
```

## Corpus aplicado

Depois do backfill, os 3 decks passaram nos gates:

- `commander_resolved=true`;
- `commander_quantity=1`;
- `main_quantity=99`;
- `unresolved=0`;
- `off_color=0`;
- sem violacao singleton fora de terrenos basicos.

Comandos:

```bash
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --dry-run --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/dry_run_after_backfill
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --apply --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/apply
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --apply --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/apply_idempotency
```

## Agregado estrutural

Média de roles nos 3 decks aceitos:

| Role | Média |
| --- | ---: |
| `lands` | `32.00` |
| `ramp` | `14.67` |
| `interaction` | `6.00` |
| `creature` | `5.67` |
| `draw_value` | `5.33` |
| `board_wipe` | `4.00` |
| `win_condition` | `3.00` |
| `protection` | `2.33` |
| `other` | `27.00` |

Cartas recorrentes nos 3 decks incluem `Arcane Signet`, `Arid Mesa`,
`Call Forth the Tempest`, `Command Tower`, `Dance with Calamity`,
`Deflecting Swat`, `Esper Sentinel`, `Gamble`, `Hit the Mother Lode`,
`Library of Leng` e fetch lands Boros-compatíveis.

## Validações

```bash
cd server && dart analyze bin lib routes test
cd server && dart test test/commander_reference_deck_corpus_support_test.dart test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart -r expanded
git diff --check
```

## Riscos

- O classificador de roles ainda é heurístico; `other` segue alto e deve ser
  refinado antes de virar target rígido de geração.
- O corpus ainda nao é consumido por `/ai/generate` ou `/ai/optimize`; isso
  precisa ser uma integração separada e explicitamente validada.
- EDHREC deckpreview é fonte externa publica; usamos o corpus como estatística
  agregada e evidencia estrutural, nao como lista a ser copiada.

## Proximo passo

Integrar o resumo agregado de Lorehold ao `/ai/generate` como guidance
estrutural de baixo risco: targets por role, recorrência de pacotes e alertas
de desvio, sem injetar decklists completas no prompt.
