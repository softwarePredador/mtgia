# Battle Event Contract Audit - 2026-06-19T15:57:26Z

## Escopo

Esta auditoria verifica o contrato real entre:

- eventos emitidos por `battle_analyst_v9.py`;
- eventos gravados no `replay.events.jsonl`;
- renderer humano `battle_replay_v10_3.py`;
- `battle_action_critic.py`;
- `replay_decision_auditor.py`;
- `battle_forensic_audit.py`.

Nao houve alteracao em PostgreSQL, swaps ou codigo de produto. Os comandos
geraram somente artefatos/logs.

## Artefatos usados

- Latest audit:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_155224/`
- Summary principal:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- Seed auditada:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_786135854/replay.events.jsonl`
- Artefatos desta auditoria:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_event_contract_155726/`

## Resultado de alerta

Nao ha high/critical para notificar nesta rodada:

- `seeds_with_high_or_critical_action_findings`: `[]`
- `seeds_with_high_or_critical_decision_audit_findings`: `[]`
- `seeds_with_high_or_critical_forensic_findings`: `[]`
- `seeds_with_strategy_blockers`: `[]`

O ponto de atencao nao e blocker imediato da seed; e lacuna de contrato/cobertura
dos consumidores de evento.

Sanity check posterior: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
avancou para `2026-06-19T16:01:45Z` mantendo a mesma seed `786135854`,
`events=1071`, `action_findings=0`, `strategy_findings=0`,
`forensic_rule_findings=0` e listas high/critical/blockers vazias.

## Estado latest

| Metrica | Valor |
| --- | ---: |
| `timestamp_utc` | `2026-06-19T15:52:24Z` |
| `start_seed` | `786135854` |
| `events` | `1071` |
| `decisions` | `152` |
| `action_findings` | `0` |
| `strategy_findings` | `0` |
| `decision_audit_turn_findings` | `0` |
| `decision_audit_decision_findings` | `0` |
| `forensic_rule_findings` | `0` |
| `forensic_turn_findings` | `0` |
| `effect_coverage_unknowns` | `33` |
| `heuristic_effects` | `120` |
| `trigger_not_explicit` | `147` |
| `cast_permission_not_explicit` | `89` |
| `runtime_safe_rule_names` | `1702` |
| `review_only_rule_names` | `1457` |

## Eventos observados na seed latest

`replay.events.jsonl` tem `1071` eventos, `39` tipos unicos, `0` eventos sem
turno e `54` eventos sem ator direto. Dos `54` sem ator direto, `53` sao
`combat_step` sem ataque/defensor e `1` e `replacement_applied`.

| Evento | Count |
| --- | ---: |
| `priority_pass` | 375 |
| `combat_step` | 155 |
| `cast_announced` | 82 |
| `cast_illegal` | 47 |
| `turn_start` | 42 |
| `mana_refreshed` | 42 |
| `combat_result` | 39 |
| `cost_paid` | 35 |
| `turn_end` | 29 |
| `land_played` | 26 |
| `spell_cast` | 26 |
| `spell_resolved` | 25 |
| `combat` | 24 |
| `trigger_put_on_stack` | 19 |
| `trigger_resolved` | 19 |
| `activated_ability_skipped` | 18 |
| `multi_defender_attack` | 13 |
| `lorehold_upkeep_rummage_skipped` | 10 |
| `creature_cast` | 8 |
| `topdeck_manipulation_activated` | 8 |
| `end_step_instant` | 4 |
| `lorehold_upkeep_rummage` | 4 |
| `player_eliminated` | 3 |
| `saga_chapter_progressed` | 2 |
| `commander_cast` | 2 |
| one-off event types | 14 |

One-off event types nesta seed:

- `additional_cost_paid`
- `copy_creature_token_created`
- `equipment_attached`
- `extra_turn_scheduled`
- `game_won`
- `miracle_cast`
- `recursion_resolved`
- `removal_resolved`
- `replacement_applied`
- `saga_chapter_resolved`
- `saga_sacrificed_by_sba`
- `treasure_created`
- `tutor_resolved`
- `wheel_resolved`

## Contrato observado por consumidor

| Camada | Cobertura estatica/observada | Leitura |
| --- | ---: | --- |
| Emissao `battle_analyst_v9.py` | `94` nomes literais de eventos | O simulador emite muito mais tipos do que os gates especializados consomem. |
| Renderer `battle_replay_v10_3.py` | `25` branches literais + fallback generico para `_activated` e vida | Muitos eventos sao renderizados por fallback ou nao viram linha dedicada. |
| `battle_action_critic.py` default | `24` `ACTION_EVENTS`; `475/1071` eventos verdictados no latest | O summary `action_verdict_counts={"ok":475}` nao cobre todos os eventos do JSONL. |
| `battle_action_critic.py --include-technical` | `1071/1071` eventos na tabela, `0` findings | Inclui todos, mas eventos fora de `ACTION_EVENTS` recebem poucos checks especificos. |
| `replay_decision_auditor.py` | `turn_by_turn_clean`, `1071` eventos, `152` decisions | Valida invariantes de turno/decision trace, nao contrato completo de todos os eventos. |
| `battle_forensic_audit.py` | `9` `CARD_EVENT_KINDS`, `111/1071` eventos forenses | Limpo para eventos de carta suportados, mas nao cobre eventos tecnicos, saga, skipped, topdeck activated etc. |

## Eventos observados fora do critic default + tecnico

Mesmo somando `ACTION_EVENTS` e `TECHNICAL_EVENTS`, `50` eventos observados
ficam sem classe especializada:

| Evento | Count |
| --- | ---: |
| `activated_ability_skipped` | 18 |
| `lorehold_upkeep_rummage_skipped` | 10 |
| `topdeck_manipulation_activated` | 8 |
| `lorehold_upkeep_rummage` | 4 |
| `saga_chapter_progressed` | 2 |
| `additional_cost_paid` | 1 |
| `copy_creature_token_created` | 1 |
| `equipment_attached` | 1 |
| `extra_turn_scheduled` | 1 |
| `saga_chapter_resolved` | 1 |
| `saga_sacrificed_by_sba` | 1 |
| `treasure_created` | 1 |
| `wheel_resolved` | 1 |

Esses eventos podem ser legitimos, mas precisam de classificacao explicita:
`technical/noop`, `renderer_only`, `action_audited`, `forensic_card_event`,
`strategy_signal` ou `ignored_with_reason`.

## Evento com linhagem insuficiente

Linha `399` do latest `replay.events.jsonl`:

```json
{
  "affected_player": "Tayam, Luminous Enigma #116 (real)",
  "amount": 0,
  "card": "Tayam, Luminous Enigma",
  "delta": 0,
  "event": "replacement_applied",
  "event_type": "zone_change",
  "from_zone": "battlefield",
  "prevented": false,
  "reason": null,
  "replacement_order": [
    "commander_to_command_zone"
  ],
  "replacement_pipeline": "replacement_prevention_minimal",
  "replacements": [
    "commander_to_command_zone"
  ],
  "replay_id": "seed_786135854",
  "source": null,
  "to_zone": "command_zone",
  "turn": 5
}
```

Leitura: o evento provavelmente e correto como replacement de comandante para
command zone, mas a linhagem ainda nao e auditavel o suficiente. `source` e
`reason` estao `null`, e o `action_critic` aceita o evento como `ok`.

## Forensic limpo, mas com lacuna de linhagem

`battle_forensic_audit.py` retornou `findings_total=0`, mas a cobertura de
linhagem segue parcial:

- `card_events`: `111`
- `card_id_present`: `63`
- `card_id_missing`: `48`
- `semantic_hash_present`: `63`
- `semantic_hash_missing`: `48`
- `rule_logical_key_present`: `109`
- `rule_logical_key_missing`: `2`

Isto confirma ausencia de findings forenses suportados, mas ainda nao confirma
linhagem completa para aprendizado/comparacao semantica.

## Conclusao

A seed latest esta limpa nos gates atuais e nao exige notificacao high/critical.
O fluxo operacional melhorou: triggers atuais nao exibem mais `event=?` ou
`stack=?`, Pyroblast nao aparece como counter resolvido sem alvo nessa seed, e
forensic/decision/action estao no summary principal.

Ainda falta um contrato central de eventos. Hoje um evento novo pode ser
emitido, renderizado por fallback ou incluido em `--include-technical` e ainda
assim nao receber validacao especifica. Para validacao battle, o proximo ajuste
deve ser uma matriz obrigatoria por tipo de evento, declarando campos minimos,
renderer esperado, critic esperado, forensic esperado e quando o evento pode ser
ignorado com justificativa.
