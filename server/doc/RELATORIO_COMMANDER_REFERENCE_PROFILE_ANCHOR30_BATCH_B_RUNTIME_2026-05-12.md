# Commander Reference Profile Anchor 30 Batch B Runtime — 2026-05-12

## Verdict

**PASS WITH RISKS** para deploy e runtime publico do Anchor 30 Batch B.

O backend publico `https://evolution-cartinhas.8ktevp.easypanel.host` ja estava
atualizado em `75c0addf08faa85e5c4fcfb9cbf7673fc348367b`, correspondente ao
commit local `75c0add` (`docs: add anchor 30 commander profiles batch b`). Nao
foi necessario acionar deploy manual adicional.

## Backend

| Check | Resultado |
| --- | --- |
| `/health` | `200`, `status=healthy`, `git_sha=75c0addf08faa85e5c4fcfb9cbf7673fc348367b` |
| `/ready` | `200`, database/cards healthy |
| Profiles Batch B | deploy publico atualizado |
| Scanner | fora do escopo |

## Runtime publico

Foram executados 12 probes sanitizados com `commander_name` para os 8
comandantes do Batch B, mais 2 baselines sem `commander_name`.

| Metrica | Resultado |
| --- | ---: |
| Reference probes | 12 |
| HTTP 200 | 12/12 |
| `validation.is_valid=true` | 12/12 |
| `reference_profile_used=true` | 12/12 |
| `reference_card_stats_used=true` | 12/12 |
| `main_quantity=99` | 12/12 |
| Fallbacks determinísticos | 2/12 |
| `invalid_cards_count` total | 1 na amostra primaria |
| p50 aproximado | 14155ms |
| max observado | 20783ms |

## Commanders validados

| Commander | Resultado |
| --- | --- |
| Edgar Markov | PASS, profile/stats ativos, 99 main, validacao OK |
| Miirym, Sentinel Wyrm | PASS, profile/stats ativos, 99 main, validacao OK |
| Isshin, Two Heavens as One | PASS, fallback por timeout, 99 main, validacao OK |
| Teysa Karlov | PASS, profile/stats ativos, 99 main, validacao OK |
| Lathril, Blade of the Elves | PASS, profile/stats ativos, 99 main, validacao OK |
| Aesi, Tyrant of Gyre Strait | PASS WITH NOTE, backend retornou nome normalizado com `//`, primeira face preservada |
| Sythis, Harvest's Hand | PASS WITH NOTE, amostra primaria teve `invalid_cards_count=1`, follow-up retornou `0` |
| Urza, Lord High Artificer | PASS, uma amostra extra usou fallback por timeout, 99 main, validacao OK |

## Follow-up Aesi/Sythis

Um follow-up publico foi executado para separar risco real de artefato de parsing:

- Aesi retornou `Aesi, Tyrant of Gyre Strait // Aesi, Tyrant of Gyre Strait`;
  a comparação exata falha, mas a primeira face preserva o comandante correto,
  `main_quantity=99`, `validation.is_valid=true`, `invalid_cards_count=0`,
  `reference_profile_used=true` e `reference_card_stats_used=true`.
- Sythis retornou comandante exato, `main_quantity=99`,
  `validation.is_valid=true`, `invalid_cards_count=0`,
  `reference_profile_used=true` e `reference_card_stats_used=true`.

## Baseline

Os baselines sem `commander_name` continuaram compativeis, mas demonstraram por
que o app deve enviar o campo:

- Edgar baseline foi valido, mas sem diagnostics de profile/card-stats.
- Urza baseline foi valido, porem retornou comandante generico no fallback.

## Riscos

- `Aesi` expõe uma normalizacao de nome de card dupla-face no retorno; nao
  bloqueia validacao nem salvamento, mas consumidores que comparam string devem
  comparar primeira face normalizada.
- `Sythis` teve um `invalid_cards_count=1` isolado na amostra primaria; follow-up
  publico repetiu com `0`, entao fica classificado como warning nao bloqueante.
- Fallbacks por timeout ainda existem em amostras isoladas, mas preservaram
  comandante, 99 main, profile/stats e validacao OK.

## Artifacts

- `server/test/artifacts/commander_reference_profile_anchor30_batch_b_runtime_2026-05-12/summary.json`
- `server/test/artifacts/commander_reference_profile_anchor30_batch_b_runtime_2026-05-12/follow_up_aesi_sythis.json`

## Status final

**PASS WITH RISKS**. Batch B esta publicado e consumivel pelo app via
`commander_name`; proximo passo recomendado e Batch C apos manter o mesmo gate:
apply DB-backed, deploy publico, runtime publico e documentacao.
