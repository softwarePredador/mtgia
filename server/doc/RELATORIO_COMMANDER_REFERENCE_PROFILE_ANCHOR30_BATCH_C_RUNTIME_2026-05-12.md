# Commander Reference Profile Anchor 30 Batch C Runtime — 2026-05-12

## Verdict

**PASS WITH RISKS** para runtime publico do Anchor 30 Batch C.

O backend publico `https://evolution-cartinhas.8ktevp.easypanel.host` estava
atualizado em `b90d50731c71750194306c61d4a84c8ec3696305`, correspondente ao
commit `b90d507` (`docs: add anchor 30 commander profiles batch c`).

## Backend

| Check | Resultado |
| --- | --- |
| `/health` | `200`, `status=healthy`, `git_sha=b90d50731c71750194306c61d4a84c8ec3696305` |
| `/ready` | `200`, database/cards healthy |
| Profiles Batch C | deploy publico atualizado |
| Scanner | fora do escopo |

## Runtime publico

Foram executados 8 probes sanitizados com `commander_name` para os 8
comandantes do Batch C.

| Metrica | Resultado |
| --- | ---: |
| Reference probes | 8 |
| HTTP 200 | 8/8 |
| `validation.is_valid=true` | 8/8 |
| `reference_profile_used=true` | 8/8 |
| `reference_card_stats_used=true` | 8/8 |
| `main_quantity=99` | 8/8 |
| Comandante preservado por primeira face | 8/8 |
| Fallbacks determinísticos | 0/8 |
| p50 aproximado | 15793ms |
| max observado | 21232ms |

## Commanders validados

| Commander | Resultado |
| --- | --- |
| Brago, King Eternal | PASS, profile/stats ativos, 99 main, validacao OK |
| Feather, the Redeemed | PASS, profile/stats ativos, 99 main, validacao OK |
| Giada, Font of Hope | PASS WITH NOTE, amostra primaria teve warning reparado; follow-up limpo |
| K'rrik, Son of Yawgmoth | PASS, profile/stats ativos, 99 main, validacao OK |
| Krenko, Mob Boss | PASS, profile/stats ativos, 99 main, validacao OK |
| Light-Paws, Emperor's Voice | PASS, profile/stats ativos, 99 main, validacao OK |
| Meren of Clan Nel Toth | PASS, profile/stats ativos, 99 main, validacao OK |
| Niv-Mizzet, Parun | PASS, profile/stats ativos, 99 main, validacao OK |

## Follow-up Giada

A amostra primaria de Giada retornou `invalid_cards_count=7` junto com
`validation.is_valid=true`, indicando reparo/filtragem antes da resposta final.
Um follow-up publico cache-bypass retornou:

- `HTTP 200`;
- `commander_returned=Giada, Font of Hope`;
- `main_quantity=99`;
- `validation.is_valid=true`;
- `invalid_cards_count=0`;
- `reference_profile_used=true`;
- `reference_card_stats_used=true`;
- `unresolved_reference_cards_count=0`.

Classificacao: warning isolado nao bloqueante.

## Artifacts

- `server/test/artifacts/commander_reference_profile_anchor30_batch_c_runtime_2026-05-12/summary.json`
- `server/test/artifacts/commander_reference_profile_anchor30_batch_c_runtime_2026-05-12/follow_up_giada.json`

## Riscos

- `/ai/generate` continua sujeito a latencia da OpenAI/rede; maior tempo
  observado nesta rodada foi `21232ms`.
- Giada teve warning primario reparado; follow-up limpo reduz risco, mas vale
  observar futuras amostras.

## Status final

**PASS WITH RISKS**. Batch C esta publicado e consumivel pelo app via
`commander_name`; proximo passo recomendado e Batch D mantendo o mesmo gate:
apply DB-backed, deploy publico, runtime publico e documentacao.
