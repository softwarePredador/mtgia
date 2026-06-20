# Battle Event Contract Static Manifest - 2026-06-19T17:08-03:00

## Escopo

Validacao artifact-only do contrato de eventos do simulador battle. Este passo
nao altera PostgreSQL, swaps, codigo de produto, automacoes ou commits.

Entradas:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- Latest run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_165421`
- Latest events:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_165421/seed_786135854/replay.events.jsonl`
- Manifesto JSON gerado:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/event_contract_static_observed_1708/event_contract_static_observed.json`
- Fontes analisadas:
  `battle_analyst_v9.py`, `battle_action_critic.py`,
  `battle_replay_v10_3.py`, `battle_forensic_audit.py`.

## Resultado

O latest esta limpo para eventos observados sem classificacao:

- eventos observados: `1073`
- tipos observados: `40`
- eventos observados `unclassified`: `0`
- tipos observados `unclassified`: `[]`

Mas o contrato ainda nao e preventivo para todos os eventos que o simulador pode
emitir:

- tipos literais emitidos por `emit_replay_event(...)`: `94`
- tipos literais estaticos ainda `unclassified` no `action_critic`: `55`
- tipos estaticos nao observados no latest: `57`
- tipos estaticos classificados mas nao observados: `2`
- tipos observados que nao aparecem como chamada literal direta no AST: `3`
- branches exatos no renderer para eventos estaticos: `25`
- branches dinamicos `_activated` no renderer para eventos estaticos: `5`
- eventos estaticos tratados apenas por fallback de vida, se houver campo de vida:
  `64`
- eventos estaticos cobertos pelo forensic como `CARD_EVENT_KINDS`: `9`

Leitura operacional: a rodada atual nao falha em `action_critic`, porem isso
nao prova que todo evento emitivel ja tem dono. Se qualquer um dos `55` tipos
estaticos abaixo aparecer em uma rodada futura, ele entra sem classificacao
explicita de action/technical/renderer/strategy/ignore.

## Classes Observadas

| Classe | Tipos observados |
| --- | ---: |
| `action_audited` | 22 |
| `technical` | 5 |
| `strategy_signal` | 6 |
| `renderer_only` | 4 |
| `ignored_with_reason` | 3 |

## Classes Estaticas

| Classe | Tipos estaticos |
| --- | ---: |
| `action_audited` | 22 |
| `technical` | 5 |
| `strategy_signal` | 6 |
| `renderer_only` | 4 |
| `ignored_with_reason` | 2 |
| `unclassified` | 55 |

## Eventos Observados Sem Chamada Literal Direta

Esses eventos foram classificados pelo `action_critic`, mas nao surgiram como
primeiro argumento literal de `emit_replay_event(...)` no AST analisado. Isso
indica emissao indireta, wrapper interno ou outro caminho de metricas.

| Event | Observed | Class | Renderer |
| --- | ---: | --- | --- |
| `player_eliminated` | 3 | `action_audited` | `exact_branch` |
| `replacement_applied` | 1 | `action_audited` | `only_life_note_fallback_if_life_fields` |
| `saga_sacrificed_by_sba` | 1 | `ignored_with_reason` | `only_life_note_fallback_if_life_fields` |

## Eventos Estaticos Classificados Mas Nao Observados

| Event | Class | Renderer |
| --- | --- | --- |
| `additional_cost_failed` | `action_audited` | `only_life_note_fallback_if_life_fields` |
| `spell_countered` | `action_audited` | `exact_branch` |

## Eventos Estaticos Ainda Sem Classificacao

| Event | Emit lines | Observed | Renderer | Forensic |
| --- | ---: | ---: | --- | --- |
| `activated_ability` | `6224, 9451, 9503` | 0 | `exact_branch` | `not_card_event_kind` |
| `adventure_cast` | `10036` | 0 | `exact_branch` | `not_card_event_kind` |
| `adventure_creature_cast_from_exile` | `10091` | 0 | `exact_branch` | `not_card_event_kind` |
| `battle_back_face_cast` | `869` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `battle_damage` | `845` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `board_wipe_resolved` | `11750` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `cannot_lose_turn_resolved` | `11885` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `cantrip_mana_filter_artifact_resolved` | `11437` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `composite_rule_component_resolved` | `11337` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `composite_rule_resolved` | `11374` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `copy_creature_token_failed` | `9712` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `creature_to_battlefield` | `11393` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `draw_cards_resolved` | `11516` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `end_step_token_sacrificed` | `9758` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `equipment_unattached` | `9582` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `extra_combat_cap_reached` | `13242` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `extra_combat_scheduled` | `12300` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `extra_combat_taken` | `13230` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `extra_turn_cap_reached` | `13366` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `extra_turn_taken` | `13345` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `flashback_cast` | `1030` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `game_lost` | `13356` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `game_win_prevented` | `11957` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `hand_filter_resolved` | `9684` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `hate_artifact_resolved` | `12227` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `imprint_failed` | `5127` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `imprint_resolved` | `5155` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `instant_removal` | `12646` | 0 | `only_life_note_fallback_if_life_fields` | `card_event_kind` |
| `land_ramp_resolved` | `9214` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `land_recursion_creature_resolved` | `9560` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `land_recursion_resolved` | `9236` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `lander_token_created` | `11562` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `life_artifact_resolved` | `12216` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `loot_resolved` | `12243` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `loyalty_ability_activated` | `807` | 0 | `dynamic_suffix_branch` | `not_card_event_kind` |
| `multi_target_resolution` | `3897` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `multikicker_paid` | `10786` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `paradigm_exiled` | `1142` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `phase_creatures_resolved` | `11874` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `planeswalker_damage` | `822` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `prepared_copies_removed` | `1126` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `prepared_copy_created` | `1106` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `protection_resolved` | `11917` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `removal_countered_by_ward` | `11296, 11596` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `station_activated` | `1083` | 0 | `dynamic_suffix_branch` | `not_card_event_kind` |
| `token_ceased_to_exist` | `6172, 6455` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `utility_artifact_activated` | `6781, 7017, 7106, 7228` | 0 | `dynamic_suffix_branch` | `not_card_event_kind` |
| `utility_land_activated` | `6014, 8381, 8482, 8584, ...` | 0 | `dynamic_suffix_branch` | `not_card_event_kind` |
| `utility_land_triggered` | `5446` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `ward_countered` | `9992, 10004` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `ward_paid` | `10000` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `warp_cast` | `935` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `warp_exiled_end_step` | `962` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `warp_recast_from_exile` | `993` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |
| `worldfire_resolved` | `11855` | 0 | `only_life_note_fallback_if_life_fields` | `not_card_event_kind` |

## Falha Registrada

O `action_critic` atual ja resolve o problema de eventos observados sem classe,
mas a matriz ainda nao cobre o dominio estatico completo. O risco principal e
uma rodada futura ativar um evento raro, receber `ok` por ausencia de finding
direto ou cair no replay textual generico, sem campos minimos, consumidor
esperado e motivo de ignorar.

## Ajustes Recomendados

1. Promover este manifesto para auditoria recorrente e expor no `summary.json`:
   `static_event_types_total`, `static_event_types_unclassified`,
   `observed_event_types_unclassified` e `observed_not_static_literal`.
2. Para cada um dos `55` eventos, escolher uma classe explicita:
   `action_audited`, `technical`, `renderer_only`, `strategy_signal`,
   `forensic_card_event` ou `ignored_with_reason`.
3. Definir campos minimos por evento raro, principalmente `activated_ability`,
   `instant_removal`, `ward_countered`, `ward_paid`, `worldfire_resolved`,
   `extra_turn_taken`, `extra_combat_taken`, `flashback_cast`, `warp_cast` e
   `adventure_cast`.
4. Adicionar fixtures que forcem pelo menos um representante de cada familia
   rara, para que renderer, critic e forensic nao sejam validados apenas por
   eventos comuns.
5. Tratar `only_life_note_fallback_if_life_fields` como cobertura insuficiente
   para eventos de regra/carta: o fallback preserva uma mudanca de vida, mas
   nao prova stack, fonte, alvo, custo, decisao ou resolucao.

## Criterio De Fechamento

Fechar o achado somente quando uma auditoria equivalente retornar:

- `observed_unclassified_total=0`
- `static_unclassified_total=0`
- todo evento emitivel tem classe, campos minimos e consumidor esperado
- eventos raros tem fixture ou waiver documentado
- o summary recorrente falha se um novo evento emitivel surgir sem contrato
