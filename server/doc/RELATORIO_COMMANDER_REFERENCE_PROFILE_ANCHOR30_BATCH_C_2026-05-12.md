# Commander Reference Profiles — Anchor 30 Batch C — 2026-05-12

## Verdict

**PASS.** Os 8 Commander Reference Profiles do Batch C da base Anchor 30 foram
criados, validados, aplicados e reaplicados com idempotência.

## Escopo

Batch C:

- Brago, King Eternal
- Feather, the Redeemed
- Giada, Font of Hope
- K'rrik, Son of Yawgmoth
- Krenko, Mob Boss
- Light-Paws, Emperor's Voice
- Meren of Clan Nel Toth
- Niv-Mizzet, Parun

## Gates obrigatorios

| Gate | Resultado |
| --- | --- |
| Commander card resolve | PASS, 8/8 |
| Dry-run | PASS WITH RISKS esperado, sem mutação |
| Apply | PASS, 8/8 |
| Apply idempotente | PASS, 8/8 |
| `unresolved_count=0` | PASS, 8/8 |
| `off_color_count=0` | PASS, 8/8 |
| `profile_usable_after_run=true` | PASS apos apply, 8/8 |

## Cobertura por commander

| Commander | Color identity | Tema principal | Resolved stats | Unresolved | Off-color |
| --- | --- | --- | ---: | ---: | ---: |
| Brago, King Eternal | W/U | blink ETB/control | 30 | 0 | 0 |
| Feather, the Redeemed | R/W | heroic/protection spells | 31 | 0 | 0 |
| Giada, Font of Hope | W | angels/counters | 31 | 0 | 0 |
| K'rrik, Son of Yawgmoth | B | life-as-mana combo | 28 | 0 | 0 |
| Krenko, Mob Boss | R | goblin typal/tokens | 32 | 0 | 0 |
| Light-Paws, Emperor's Voice | W | auras/voltron | 31 | 0 | 0 |
| Meren of Clan Nel Toth | B/G | graveyard sacrifice recursion | 31 | 0 | 0 |
| Niv-Mizzet, Parun | U/R | spellslinger draw-damage | 29 | 0 | 0 |

## Ajuste durante dry-run

O primeiro dry-run de Giada detectou `off_color_count=1` por `Boros Charm`.
Esse card foi removido do pacote de proteção e substituído por `Make a Stand`.
O dry-run reexecutado ficou `unresolved=0` e `off_color=0`.

## Comandos executados

```bash
cd server && dart run bin/commander_reference_profile.dart --profile-json=<profile> --dry-run --artifact-dir=test/artifacts/commander_reference_profile_anchor30_batch_c_2026-05-12/dry_run
cd server && dart run bin/commander_reference_profile.dart --profile-json=<profile> --apply --artifact-dir=test/artifacts/commander_reference_profile_anchor30_batch_c_2026-05-12/apply
cd server && dart run bin/commander_reference_profile.dart --profile-json=<profile> --apply --artifact-dir=test/artifacts/commander_reference_profile_anchor30_batch_c_2026-05-12/apply_idempotency
cd server && dart analyze bin lib routes test
cd server && dart test test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart -r expanded
```

## Artifacts

- `server/test/artifacts/commander_reference_profile_anchor30_batch_c_2026-05-12/profiles/*.json`
- `server/test/artifacts/commander_reference_profile_anchor30_batch_c_2026-05-12/dry_run/*_summary.json`
- `server/test/artifacts/commander_reference_profile_anchor30_batch_c_2026-05-12/apply/*_summary.json`
- `server/test/artifacts/commander_reference_profile_anchor30_batch_c_2026-05-12/apply_idempotency/*_summary.json`

## Riscos

- Runtime publico `/ai/generate` ainda precisa ser executado depois do deploy
  do commit que documenta/aponta o Batch C.
- Os profiles sao orientação agregada/manual; nao sao decklists copiadas.
- Fallback por timeout em `/ai/generate` continua possível, mas deve preservar
  comandante, 99 cartas no main e validação.

## Proximo gate

Depois do deploy, executar probes publicos sanitizados para os 8 comandantes com
`commander_name`, confirmar `HTTP 200`, `validation.is_valid=true`,
`reference_profile_used=true`, `reference_card_stats_used=true` e
`main_quantity=99`, e registrar relatório runtime separado.
