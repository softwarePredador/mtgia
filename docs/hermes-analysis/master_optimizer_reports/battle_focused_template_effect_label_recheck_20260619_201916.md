# Battle Focused Template Effect Label Recheck - 2026-06-19 20:19Z

## Escopo

Rechecagem somente documental do achado `BV-068` no latest atual da automacao
local de battle. Nao houve alteracao de PostgreSQL, swaps, runtime battle,
wrapper, regra de carta ou commit.

## Fontes

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_200324/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_200324/effect_coverage_residual.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_200324/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_200324/unknown_template_backlog.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py`

## Latest usado

- Run real: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_200324`
- `timestamp_utc=2026-06-19T20:03:24Z`
- `battle_replay_final_status=blocked`
- `mandatory_gate_divergences=["action_critic=blocked","forensic_audit=review_required"]`

## Resultado

O status de fila focada continua pronto:

| Campo | Valor |
| --- | ---: |
| `focused_template_dispatch_status` | `focused_template_dispatch_ready` |
| `focused_template_cards` | 29 |
| `template_predicate_match` | 29 |
| `evidence_dispatch_ready` | 29 |
| `focused_evidence_ready` | 29 |
| `focused_template_cards_without_dispatch` | 0 |
| `focused_template_cards_not_ready_unwaived` | 0 |
| `accepted_waivers` | 0 |

Mas o coverage de efeito ainda nao esta fechado:

| Campo | Valor |
| --- | ---: |
| `effect_coverage_unknowns` | 0 |
| `unknown_template_backlog_cards` | 0 |
| `unknown_template_backlog_status` | `focused_template_backlog_ready` |
| `effect_coverage.effect_totals.unknown` | 41 |
| Cards unicos `focused_template_ready` | 29 |
| Cards unicos `focused_template_ready` com `effect=unknown` | 28 |
| Cards unicos `focused_template_ready` com `effect!=unknown` | 1 |
| Residual rows `focused_template_ready` + `effect=unknown` | 7 |
| `needs_review_rule_names` | 1457 |
| `heuristic_effects` no summary | 117 |

## Cards focados ainda com effect=unknown

| Card | Template/familia de evidencia |
| --- | --- |
| `Flash Photography` | `copy_permanent_flash_or_flashback_contract_supported` |
| `Heroes' Hangout` | `impulse_topdeck_or_library_zone_contract_supported` |
| `Hidden Strings` | `tap_untap_cipher_trigger_contract_supported` |
| `Kindle the Inner Flame` | `copy_token_delayed_sacrifice_contract_supported` |
| `Liquimetal Coating` | `type_change_continuous_effect_contract_supported` |
| `Opera Love Song` | `impulse_topdeck_or_library_zone_contract_supported` |
| `Submerge` | `alternative_cost_library_bounce_contract_supported` |
| `Ashnod's Transmogrant` | `counter_type_change_contract_supported` |
| `Candelabra of Tawnos` | `utility_artifact_untap_x_lands_contract_supported` |
| `Clown Car` | `x_vehicle_counters_token_contract_supported` |
| `Codex Shredder` | `mill_graveyard_return_contract_supported` |
| `Copy Artifact` | `copy_artifact_as_enters_contract_supported` |
| `Cryptic Coat` | `manifest_cloak_equipment_contract_supported` |
| `Cursed Windbreaker` | `manifest_cloak_equipment_contract_supported` |
| `Dissection Tools` | `manifest_cloak_equipment_contract_supported` |
| `Firestorm` | `additional_cost_discard_multi_target_damage_contract_supported` |
| `God-Pharaoh's Statue` | `static_tax_opponent_life_loss_contract_supported` |
| `Mine Collapse` | `alternative_cost_sacrifice_mountain_damage_contract_supported` |
| `Nevermore` | `named_card_cast_restriction_contract_supported` |
| `Out of Time` | `phase_out_mass_removal_counters_contract_supported` |
| `Power Artifact` | `cost_reduction_static_aura_contract_supported` |
| `Reality Acid` | `vanishing_sacrifice_trigger_removal_contract_supported` |
| `Scroll of Fate` | `manifest_from_hand_activated_ability_contract_supported` |
| `Stoke the Flames` | `convoke_damage_contract_supported` |
| `Sudden Shock` | `split_second_damage_contract_supported` |
| `Thorn of Amethyst` | `static_noncreature_tax_contract_supported` |
| `Tragic Arrogance` | `modal_mass_sacrifice_selection_contract_supported` |
| `Tyvar, Jubilant Brawler` | `planeswalker_static_activated_graveyard_contract_supported` |

`Banishing Knack` e a unica carta da fila focada cujo `effect` aparece como
`remove_permanent` no coverage atual.

## Causa observada

No `battle_effect_coverage_audit.py`, o `effect` vem de
`battle.get_card_effect(card).get("effect", "unknown")`. Quando uma carta tem
`source == "unknown"` e bate em um focused template, o script altera somente o
`source` para `focused_template_ready`; o `effect` original permanece
`unknown`.

O mesmo script monta:

- `unknown_cards` com `card["source"] == "unknown"`;
- `focused_template_cards` com `card["source"] == "focused_template_ready"`;
- `effect_totals` a partir do valor literal de `effect`.

Portanto, `unknown_template_backlog_cards=0` prova que nao ha cards com
`source=unknown` no backlog atual. Isso nao prova que `effect=unknown` caiu para
zero no corpus de coverage.

## Leitura operacional

`focused_template_dispatch_ready` e uma afirmacao valida sobre a fila focada
atual: todos os 29 cards focados possuem predicado, dispatch e evidencia pronta.

Ela nao deve ser usada como afirmacao de que todos os templates de acoes de
cartas do corpus foram criados. Ainda existem:

- `41` instancias com `effect=unknown`;
- `28/29` cards focados ainda sem effect family estavel no coverage;
- `1457` regras `needs_review`;
- `117` efeitos heuristicos no summary.

Esse achado continua coberto por `BV-068`; nao foi aberto novo BV para evitar
duplicidade.

## Ajustes recomendados

1. Separar explicitamente no summary/report:
   - `source_unknown_cards`;
   - `effect_unknown_cards`;
   - `focused_template_ready_unknown_effect_cards`;
   - `needs_review_unknown_effect_cards`.
2. Ao promover uma carta para `focused_template_ready`, publicar tambem a familia
   de efeito focada ou um waiver explicito para manter `effect=unknown`.
3. Ajustar wording de `unknown_template_backlog_status` para deixar claro que ele
   mede source-unknown backlog, nao todos os unknown effects.
4. Adicionar teste que falhe quando `unknown_template_backlog_cards=0` e
   `effect_totals.unknown>0` forem publicados sem lista/waiver dos cards.

## Validacoes executadas

- Parse de `summary.json` do latest atual.
- Parse de `effect_coverage.json`.
- Parse de `effect_coverage_residual.json`.
- Parse de `focused_template_dispatch.json`.
- Parse de `unknown_template_backlog.json`.
- Inspecao estatica de:
  - `battle_effect_coverage_audit.py`
  - `battle_focused_template_dispatch_audit.py`
  - `battle_unknown_template_backlog_audit.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_focused_template_dispatch_audit.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_residual_audit.py` - PASS
- `git diff --check -- docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md docs/hermes-analysis/master_optimizer_reports/battle_focused_template_effect_label_recheck_20260619_201916.md` - PASS
- ASCII check do novo relatorio - PASS
