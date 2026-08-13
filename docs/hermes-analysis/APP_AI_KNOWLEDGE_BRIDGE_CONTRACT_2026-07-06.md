# App AI Knowledge Bridge Contract - 2026-07-06

Status: `active_operating_contract`.

## Addendum operacional — 2026-08-12

O mapa corrente da ponte está em
`../BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md`. PostgreSQL/backend
continua verdade; Hermes fornece laboratório/candidato inativo. Preview não é
aceite: Generate não escreve learning e Optimize registra
`optimize_preview_received`, sem feedback “accepted”. Learning fica default-off,
sources não `user_created` são quarentenadas e sync/promoção automáticos com
apply estão bloqueados até `DCK-P0-05`. O app deve usar linguagem neutra para a
origem aprendida; o rótulo cru “Hermes” abaixo é compatibilidade histórica a
remover em `BT-AI-007`, não copy recomendada para o consumidor.

This contract defines how ManaLoom knowledge becomes usable by the app and by
backend AI routes. It exists to prevent research, XMage extraction, battle
traces, Hermes outputs, or markdown reports from being mistaken for product
truth before they are promoted into durable surfaces.

## Product Rule

PostgreSQL/backend is the product truth surface. Hermes SQLite is cache, lab,
runtime evidence, or sync support. Reports are evidence only. A normal app user
must receive sanitized diagnostics and recommendations, not raw Hermes metadata,
raw report paths, or historical artifact ids.

## Knowledge Promotion Paths

| Knowledge | Durable surface | Runtime consumer | App-facing shape |
| --- | --- | --- | --- |
| Card identity, Oracle text, legality | `cards`, `card_identity_bridge`, `card_legalities` | card resolver, validate, generate, optimize | resolved names, legality warnings |
| Executable card behavior | `card_battle_rules` plus ManaLoom runtime adapter/tests | battle simulator, replay/audit validation | readiness and safe rule provenance only |
| Deckbuilding functions | `card_function_tags`, `card_semantic_tags_v2`, `card_intelligence_snapshot` | optimize candidate loading and quality gate | role labels, role counts, warnings |
| Commander learned decks and usage | `commander_learned_decks`, `commander_card_usage`, `commander_learning_snapshot` | capability default-off; `/ai/generate` and `/ai/commander-learning` only after approved receipt | candidate availability and neutral, allowlisted provenance |
| External deckbuilding research | Commander contract, profile/corpus/stats tables, deterministic fallback inputs | `/ai/generate`, `/ai/optimize` | plan, lanes, source coverage, next gate |
| Battle outcomes and logs | battle feedback artifacts promoted to explicit blocked pairs or trace evidence | optimizer gates, prompt eval, battle gates | blocked reason bucket or trace-required status |
| Markdown reports | engineering audit trail | humans and governance audits only | not consumed directly by runtime |

## Required Runtime Consumers

- `/ai/generate` must load commander profile, reference stats, reference corpus,
  validation, `semantic_layer_v2`, and `deckbuilding_contract`. Learned deck
  and usage hot cards are conditional lanes: they remain unavailable unless
  their explicit capabilities, inventory/backfill and promotion receipt are
  approved together.
- `/ai/optimize` must use one-row-per-card intelligence through
  `card_intelligence_snapshot` where deck rows are involved, and must surface
  `optimize_diagnostics`/`semantic_layer_v2` without exposing raw metadata.
- The Flutter app must never expose raw Hermes names or paths. When an approved
  learned source exists, it uses neutral copy such as `Referência aprendida`,
  with safe provenance, freshness and confidence; while the capability is OFF,
  it makes no learned-source claim.
- The prompt/output eval must reject unsupported battle proof claims, protected
  anchor cuts, exact battle-feedback-blocked add/cut pairs, off-lane swaps,
  bracket violations, budget violations, and shallow explanations.

## Quality Gate

Run the bridge gate before resuming global card-rule batches or changing AI
prompt/recommendation behavior:

```bash
./scripts/quality_gate.sh ai-bridge
```

Direct audit:

```bash
./scripts/manaloom_app_ai_bridge_audit.sh
```

This gate is static and offline. It does not replace PostgreSQL migration
status checks, equal-seed battles, replay traces, or focused runtime tests for
card rules.

## Stop Condition

The app/AI bridge is prepared when:

- the app AI bridge audit passes;
- the Commander AI prompt eval passes;
- no active runtime code consumes `master_optimizer_reports` or contract
  markdown as product truth;
- the app hides raw Hermes/learned-deck metadata;
- `/ai/generate` and `/ai/optimize` still expose their current diagnostics;
- card-rule promotion remains gated by XMage source, runtime adapter, tests,
  PostgreSQL package validation, and Hermes sync.
