# Battle Event Static Emitter Scope Audit - 2026-06-19 20:02Z

## Escopo

Auditoria documental sobre o gate `event_contract_static` do latest
`battle-strategy-audit`, com foco no escopo de arquivos usados para descobrir
eventos emitidos estaticamente.

Nao houve alteracao de PostgreSQL, swaps, runtime battle ou regras de carta.

## Fontes

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/event_contract_static.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/event_contract_static.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_support.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_support.py`

Latest real usado:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_193733`
- `timestamp_utc=2026-06-19T19:37:33Z`
- `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["forensic_audit=review_required"]`

## Resultado

O gate atual reporta:

- `event_contract_static_status=event_contract_static_ready`
- `events_observed_total=15883`
- `observed_event_types_total=54`
- `static_event_types_total=94`
- `all_event_types_total=97`
- `observed_unclassified_total=0`
- `observed_missing_required_fields=0`
- `static_contract_waiver_until_forced_fixture=0`

Mesmo com status ready, o summary ainda lista:

```json
["player_eliminated", "replacement_applied", "saga_sacrificed_by_sba"]
```

como `observed_not_static_literal`.

Contagens observadas no latest:

| Event | Observed count | Class | Consumer |
| --- | ---: | --- | --- |
| `player_eliminated` | 43 | `action_audited` | `battle_action_critic.py` |
| `replacement_applied` | 11 | `action_audited` | `battle_action_critic.py` |
| `saga_sacrificed_by_sba` | 6 | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` |

## Causa provavel

`battle_event_contract_static_audit.py` usa como `DEFAULT_ENGINE_SOURCE` apenas:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`

A funcao `static_event_emitters(...)` faz AST scan somente desse arquivo e
procura chamadas diretas `emit_replay_event("...")`.

Os tres eventos observados fora do literal estatico sao emitidos em modulos de
suporte:

| Event | File / line | Evidence |
| --- | --- | --- |
| `replacement_applied` | `battle_replacement_support.py:177` | `emitter("replacement_applied", **event.to_replay_fields())` |
| `saga_sacrificed_by_sba` | `battle_sba_support.py:217` | `emit_replay_event("saga_sacrificed_by_sba", ...)` |
| `player_eliminated` | `battle_sba_support.py:268`, `274`, `286`, `300` | SBA emits elimination for empty library, life zero, commander damage and poison |

`battle_analyst_v9.py` knows these names only in telemetry handling:

- `replacement_applied` in `EngineMetrics.record_event(...)`
- `player_eliminated` in `EngineMetrics.record_event(...)`

Those metric branches do not make the event type part of the static emitter
inventory.

## Leitura operacional

`event_contract_static_ready` currently means observed/static event types are
classified, observed fields satisfy minimum requirements, and no forced fixture
waiver is pending.

It does not prove that the static event inventory scans every file capable of
emitting replay events.

For complete battle awareness, the static event surface needs either:

- a multi-file emitter scan covering support modules; or
- an explicit manifest saying which emitter files are intentionally outside the
static source scan and why observed-only events are accepted.

## Risco

A future reader can treat `static_event_types_total=94` and
`event_contract_static_ready` as the complete static battle event surface. In
practice, at least three observed event types came from emitter files outside
the configured static source.

This can hide newly added support-module events until they appear in a replay,
and it weakens claims that the event contract covers the full runtime emitter
surface.

## Ajustes recomendados

1. Let `battle_event_contract_static_audit.py` accept multiple
   `--engine-source` paths or scan an explicit emitter manifest.
2. Include support emitters such as `battle_sba_support.py` and
   `battle_replacement_support.py` in the static surface.
3. Store `static_engine_sources` and per-event `emit_file:line` in
   `event_contract_static.json`.
4. Decide whether non-empty `observed_not_static_literal` should be:
   - a review-required condition; or
   - an explicitly waived observed-only category with owner/reason.
5. Add a fixture where a support module emits an event not present in
   `battle_analyst_v9.py`, and assert the static audit still inventories it.

## Criterio de fechamento

- `observed_not_static_literal=[]` for the latest, or every observed-only event
  has an explicit owner/reason in the static contract.
- Static event extraction includes all known replay event emitter files.
- The summary exposes the scanned file list, not only one `engine_source`.
- A test fails if a support-module `emit_replay_event("...")` literal is missed
  by the static event contract audit.

## Validacoes executadas

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py --input-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest --output /tmp/battle_event_contract_static_current.md --json-output /tmp/battle_event_contract_static_current.json --fail-on-unclassified` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` - PASS
- `git diff --check -- docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md docs/hermes-analysis/master_optimizer_reports/battle_event_static_emitter_scope_audit_20260619_200220.md` - PASS
- ASCII check do novo relatorio - PASS
