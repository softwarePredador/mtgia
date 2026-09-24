# ManaLoom — sistema atual gerado

> Gerado por `scripts/manaloom_project_logic.sh --write`. Não editar manualmente.

**Digest das fontes:** `a15c78659011da5e9012f722258b871b9d52a649cb0d170c8df6658ae5626ddf`

## Fontes de verdade

- Produto e persistência: **PostgreSQL plus backend services and versioned migrations**.
- Cache/laboratório: **Hermes/SQLite; never product source of truth**.
- Runtime de cartas: **Pinned XMage first, pinned Forge for structured gaps, native ManaLoom adapters for native execution**.
- Intenção/decisões: **ADRs and current canonical contracts; generated files never infer architectural intent**.

## Inventário

| Superfície | Quantidade |
|---|---:|
| `dart_source_files` | 706 |
| `non_dart_product_files` | 50 |
| `battle_sidecar_source_files` | 34 |
| `dart_symbols` | 5340 |
| `semantic_resolved_files` | 706 |
| `semantic_unresolved_files` | 0 |
| `semantic_resolved_call_edges` | 43347 |
| `semantic_resolved_call_sites` | 68915 |
| `semantic_resolved_type_references` | 16455 |
| `modules` | 160 |
| `app_routes` | 46 |
| `web_routes` | 11 |
| `api_routes` | 124 |
| `database_tables` | 81 |
| `database_views` | 6 |
| `migrations` | 61 |
| `scripts_and_jobs` | 693 |
| `environment_variables` | 716 |
| `tests` | 1264 |
| `flows` | 13 |
| `traceability_rules` | 12 |
| `tasks` | 244 |
| `task_dependency_edges` | 435 |
| `route_consumer_bindings` | 57 |
| `receipt_contracts` | 6 |

## Fluxos canônicos

| Fluxo | Estado declarado | Fonte de verdade |
|---|---|---|
| Autenticação, recuperação e sessão | `active_release_scope` | users/auth_version and backend auth policies |
| Home, onboarding, notificações e retenção | `active_release_scope` | notifications and activation_funnel_events in PostgreSQL; onboarding disposition lives only on the device (SharedPreferences); /notifications and PUT /users/me/fcm-token require social_push |
| Descoberta de cartas e coleção | `active_release_scope` | cards, sets, card_legalities and collection availability in PostgreSQL |
| Fichário, importação de coleção e scanner | `active_release_scope` | user_binder_items in PostgreSQL under binder_item_contract and binder_import_contract (compare-and-set per physical identity); availability derived from decks; scanner requires ENABLE_SCANNER_RELEASE build flag plus the scanner capability |
| Criar, importar, editar e validar deck | `active_release_scope` | decks and deck_cards under DeckRulesService validation |
| Gerar, analisar e otimizar deck com IA | `experimental_split: analyze_optimize=experimental_p0_open; generate_rebuild=experimental_guarded` | Commander deckbuilding contract plus backend deterministic and quality gates |
| Battle, Jogar contra IA, evidência de carta e replay | `active_guarded` | persisted battle attempts, jobs and replays plus pinned execution identity; external pins do not promote native rules |
| Life Counter, sessão e pós-jogo | `active_release_scope` | local game session stores plus PostgreSQL post_game_notes after sync |
| Comunidade, mensagens, binder e trades | `active_requires_release_e2e` | PostgreSQL ownership and transition services |
| Build, migração, deploy, observabilidade e rollback | `guarded_no_implicit_live_write` | same-SHA release contract, artifact digests, migration ledger and health/readiness |
| Plano, cota de IA e comércio (beta gratuita, sem cobrança) | `free_beta_no_commerce` | user_plans and ai_logs in PostgreSQL under PlanService; offer_mode free_beta_no_commerce in server/config/release_capabilities.json; no payment provider exists |
| Site público (brewtact.com) e relatório compartilhável | `active_release_scope` | web-public/src/lib/product-data.ts and routes.ts under the free-beta offer contract; shared_deck_reports in PostgreSQL for GET /reports/{id}; no product capability is served |
| Scheduler operacional (manaloom-ops) e sincronizações | `guarded_no_implicit_live_write` | server/bin/manaloom_ops_daemon.py with JOB_REQUIRED_CAPABILITIES (18 jobs), REFERENCE_DATA_JOBS and PRIVACY_CONTROL_JOBS reading server/config/release_capabilities.json; with every capability off only hermes_cron_governor_report (safe_housekeeping_only), manaloom_catalog_reference_refresh (reference data under the catalog_reference_apply_v1 contract, applied only after a supervised activation), manaloom_account_deletion_outbox (D-68 outbox consumer under account_deletion_outbox_v1, writing only account_deletion_outbox) and manaloom_ai_runtime_cleanup (D-70 retention cleanup under retention_cleanup_apply_v1, deleting only the inventory periods and only after a supervised activation) run; an invalid policy keeps only the governor |

## Como validar

```bash
./scripts/manaloom_project_logic.sh --check
./scripts/manaloom_local_ci.sh schema
./scripts/manaloom_local_ci.sh full
```

Consulte `project_logic_manifest.json` para a estrutura completa e `docs/generated/TRACEABILITY_MATRIX.md` para regra → implementação → teste → banco.
