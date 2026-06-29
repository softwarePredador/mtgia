# External Engine Crosscheck Registry

- Generated UTC: `2026-06-29T06:21:18+00:00`
- PostgreSQL writes: `False`
- Registry status: `external_engine_crosscheck_registry_ready`
- Engines: `3`
- Cards requested: `3`

## Engines

| Engine | Role | Confidence role | Adapter status | Use | Do not use for |
| --- | --- | --- | --- | --- | --- |
| [Forge](https://github.com/Card-Forge/forge) | `independent_rules_engine` | `primary_external_crosscheck_after_xmage` | `registry_ready_source_lookup_manual_or_api` | Independent implementation comparison for card families missing, ambiguous, or contradicted in XMage. | Authoritative rules, direct promotion to PostgreSQL, or bypassing ManaLoom runtime fixtures. |
| [Magarena](https://github.com/magarena/magarena) | `independent_rules_engine` | `secondary_external_crosscheck` | `registry_ready_source_lookup_manual_or_api` | Secondary comparison for card scripting and AI-visible behavior. | Authoritative rules or direct runtime promotion. |
| [Cockatrice](https://github.com/Cockatrice/Cockatrice) | `manual_game_client_and_replay_surface` | `replay_protocol_reference_not_rules_engine` | `registry_ready_replay_reference_only` | Manual replay and client state comparison. | Rules execution truth or card effect implementation. |

## Card Lookup Candidates

### Approach of the Second Sun

- `forge`: [Forge search](https://github.com/Card-Forge/forge/search?q=Approach+of+the+Second+Sun&type=code), [Forge search](https://github.com/Card-Forge/forge/search?q=approach_of_the_second_sun&type=code)
- `magarena`: [Magarena search](https://github.com/magarena/magarena/search?q=Approach+of+the+Second+Sun&type=code), [Magarena search](https://github.com/magarena/magarena/search?q=approach_of_the_second_sun&type=code)
- `cockatrice`: [Cockatrice search](https://github.com/Cockatrice/Cockatrice/search?q=Approach+of+the+Second+Sun&type=code), [Cockatrice search](https://github.com/Cockatrice/Cockatrice/search?q=approach_of_the_second_sun&type=code)
### Pinnacle Monk // Mystic Peak

- `forge`: [Forge search](https://github.com/Card-Forge/forge/search?q=Pinnacle+Monk+//+Mystic+Peak&type=code), [Forge search](https://github.com/Card-Forge/forge/search?q=pinnacle_monk&type=code)
- `magarena`: [Magarena search](https://github.com/magarena/magarena/search?q=Pinnacle+Monk+//+Mystic+Peak&type=code), [Magarena search](https://github.com/magarena/magarena/search?q=pinnacle_monk&type=code)
- `cockatrice`: [Cockatrice search](https://github.com/Cockatrice/Cockatrice/search?q=Pinnacle+Monk+//+Mystic+Peak&type=code), [Cockatrice search](https://github.com/Cockatrice/Cockatrice/search?q=pinnacle_monk&type=code)
### Molecule Man

- `forge`: [Forge search](https://github.com/Card-Forge/forge/search?q=Molecule+Man&type=code), [Forge search](https://github.com/Card-Forge/forge/search?q=molecule_man&type=code)
- `magarena`: [Magarena search](https://github.com/magarena/magarena/search?q=Molecule+Man&type=code), [Magarena search](https://github.com/magarena/magarena/search?q=molecule_man&type=code)
- `cockatrice`: [Cockatrice search](https://github.com/Cockatrice/Cockatrice/search?q=Molecule+Man&type=code), [Cockatrice search](https://github.com/Cockatrice/Cockatrice/search?q=molecule_man&type=code)

## Promotion Policy

- External engines provide comparison evidence only.
- Official Wizards rules plus Oracle/rulings remain the semantic authority.
- Any promoted ManaLoom rule still needs local runtime tests and, if PostgreSQL is touched, an explicit reviewed package.
