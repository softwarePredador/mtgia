# ManaLoom — sistema atual gerado

> Gerado por `scripts/manaloom_project_logic.sh --write`. Não editar manualmente.

**Digest das fontes:** `9dce68ba0b22fc00e8ec1b1101050bde19d853363f648b227ad04db3a28556ab`

## Fontes de verdade

- Produto e persistência: **PostgreSQL plus backend services and versioned migrations**.
- Cache/laboratório: **Hermes/SQLite; never product source of truth**.
- Runtime de cartas: **Pinned XMage first, pinned Forge for structured gaps, native ManaLoom adapters for native execution**.
- Intenção/decisões: **ADRs and current canonical contracts; generated files never infer architectural intent**.

## Inventário

| Superfície | Quantidade |
|---|---:|
| `dart_source_files` | 641 |
| `non_dart_product_files` | 47 |
| `battle_sidecar_source_files` | 30 |
| `dart_symbols` | 4560 |
| `semantic_resolved_files` | 641 |
| `semantic_unresolved_files` | 0 |
| `semantic_resolved_call_edges` | 37015 |
| `semantic_resolved_call_sites` | 58961 |
| `semantic_resolved_type_references` | 14477 |
| `modules` | 144 |
| `app_routes` | 41 |
| `web_routes` | 14 |
| `api_routes` | 117 |
| `database_tables` | 79 |
| `database_views` | 6 |
| `migrations` | 56 |
| `scripts_and_jobs` | 655 |
| `environment_variables` | 655 |
| `tests` | 1136 |
| `flows` | 8 |
| `traceability_rules` | 11 |

## Fluxos canônicos

| Fluxo | Estado declarado | Fonte de verdade |
|---|---|---|
| Autenticação, recuperação e sessão | `active_release_scope` | users/auth_version and backend auth policies |
| Descoberta de cartas e coleção | `active_release_scope` | cards, sets, card_legalities and collection availability in PostgreSQL |
| Criar, importar, editar e validar deck | `active_release_scope` | decks and deck_cards under DeckRulesService validation |
| Gerar, analisar e otimizar deck com IA | `experimental_guarded` | Commander deckbuilding contract plus backend deterministic and quality gates |
| Battle, evidência de carta e replay | `active_guarded` | battle request plus persisted battle_simulations; external pins do not promote native rules |
| Life Counter, sessão e pós-jogo | `active_release_scope` | local game session stores plus PostgreSQL post_game_notes after sync |
| Comunidade, mensagens, binder e trades | `active_requires_release_e2e` | PostgreSQL ownership and transition services |
| Build, migração, deploy, observabilidade e rollback | `guarded_no_implicit_live_write` | same-SHA release contract, artifact digests, migration ledger and health/readiness |

## Como validar

```bash
./scripts/manaloom_project_logic.sh --check
./scripts/manaloom_local_ci.sh schema
./scripts/manaloom_local_ci.sh full
```

Consulte `project_logic_manifest.json` para a estrutura completa e `docs/generated/TRACEABILITY_MATRIX.md` para regra → implementação → teste → banco.
