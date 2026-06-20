# Battle Focused Template Builder Contract Audit - 2026-06-19T18:01Z

## Escopo

Auditoria read-only para responder se os templates de acao de carta ja estao
criados para o backlog atual de `focused_template_dispatch`.

Fontes verificadas:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/focused_template_dispatch.json`
- `server/bin/manaloom_battle_rule_focused_evidence.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py`

Nenhuma consulta ou alteracao PostgreSQL foi feita. Nenhum swap foi aplicado.
Nenhum codigo de produto foi alterado.

## Resultado

Os templates de acao ainda nao estao criados como evidence executavel para o
backlog atual.

Resumo do latest `20260619_175911`:

- `focused_template_dispatch.status=review_required`
- `focused_template_cards=29`
- `template_predicate_match=29`
- `evidence_dispatch_ready=0`
- `focused_evidence_ready=0`
- `focused_evidence_not_ready_unwaived=29`
- `accepted_waivers=0`
- `evidence_runner_status_counts={"unsupported":29}`

Resumo estatico do source:

- `supports_template_count=47`
- `evaluate_dispatch_template_count=21`
- `build_evidence_function_count=21`
- `supports_not_dispatched_count=26`

Leitura operacional: existir `supports_*_template` nao significa que o template
de acao esta criado. Para contar como template criado para uso do gate, a
familia precisa ter rota em `evaluate_draft(...)`, builder `build_*_evidence`,
artefatos focados e/ou waiver aceito. O backlog atual bate exatamente nas
familias que ainda nao possuem dispatch/evidence.

## Builders faltantes por carta

| Card | Support predicate | Builder esperado | Builder existe | Dispatch em `evaluate_draft` | Fixture esperada | Decks |
| --- | --- | --- | --- | --- | --- | --- |
| `Ashnod's Transmogrant` | `supports_counter_type_change_template` | `build_counter_type_change_evidence` | nao | nao | `counter_and_artifact_type_change_replay` | `Magda, Brazen Outlaw #71 (real)` |
| `Banishing Knack` | `supports_granted_bounce_ability_template` | `build_granted_bounce_ability_evidence` | nao | nao | `grant_activated_bounce_ability_replay` | `Urza, Lord High Artificer #87 (real)` |
| `Candelabra of Tawnos` | `supports_utility_artifact_untap_x_lands_template` | `build_utility_artifact_untap_x_lands_evidence` | nao | nao | `x_land_untap_activated_ability_replay` | `Akiri, Line-Slinger #30 (real)` |
| `Clown Car` | `supports_x_vehicle_counters_token_template` | `build_x_vehicle_counters_token_evidence` | nao | nao | `x_cost_vehicle_counters_and_token_replay` | `Magda, Brazen Outlaw #71 (real)` |
| `Codex Shredder` | `supports_mill_graveyard_return_template` | `build_mill_graveyard_return_evidence` | nao | nao | `mill_then_graveyard_return_activated_ability_replay` | `Urza, Lord High Artificer #87 (real)` |
| `Copy Artifact` | `supports_copy_artifact_as_enters_template` | `build_copy_artifact_as_enters_evidence` | nao | nao | `copy_artifact_as_enters_replay` | `Kraum, Ludevic's Opus #50 (real)`; `Urza, Lord High Artificer #87 (real)` |
| `Cryptic Coat` | `supports_manifest_cloak_equipment_template` | `build_manifest_cloak_equipment_evidence` | nao | nao | `cloak_equipment_etb_attach_replay` | `Yorion, Sky Nomad #38 (real)` |
| `Cursed Windbreaker` | `supports_manifest_cloak_equipment_template` | `build_manifest_cloak_equipment_evidence` | nao | nao | `manifest_cloak_equipment_static_grant_replay` | `Yorion, Sky Nomad #38 (real)` |
| `Dissection Tools` | `supports_manifest_cloak_equipment_template` | `build_manifest_cloak_equipment_evidence` | nao | nao | `manifest_cloak_equipment_lifelink_replay` | `Yorion, Sky Nomad #38 (real)` |
| `Firestorm` | `supports_additional_cost_discard_multi_target_damage_template` | `build_additional_cost_discard_multi_target_damage_evidence` | nao | nao | `discard_x_multi_target_damage_replay` | `Ishai, Ojutai Dragonspeaker #28 (real)`; `Kenrith, the Returned King #113 (real)`; `Kraum, Ludevic's Opus #50 (real)` |
| `Flash Photography` | `supports_copy_permanent_flash_or_flashback_template` | `build_copy_permanent_flash_or_flashback_evidence` | nao | nao | `copy_permanent_flash_timing_and_flashback_replay` | `Ishai, Ojutai Dragonspeaker #28 (real)`; `Kenrith, the Returned King #113 (real)` |
| `God-Pharaoh's Statue` | `supports_static_tax_opponent_life_loss_template` | `build_static_tax_opponent_life_loss_evidence` | nao | nao | `static_opponent_tax_and_end_step_life_loss_replay` | `Magda, Brazen Outlaw #71 (real)` |
| `Heroes' Hangout` | `supports_impulse_topdeck_or_library_zone_template` | `build_impulse_topdeck_or_library_zone_evidence` | nao | nao | `modal_impulse_play_until_next_turn_replay` | `Gwen Stacy #65 (real)` |
| `Hidden Strings` | `supports_tap_untap_cipher_trigger_template` | `build_tap_untap_cipher_trigger_evidence` | nao | nao | `tap_untap_cipher_trigger_replay` | `Akiri, Line-Slinger #30 (real)` |
| `Kindle the Inner Flame` | `supports_copy_token_delayed_sacrifice_template` | `build_copy_token_delayed_sacrifice_evidence` | nao | nao | `copy_token_delayed_sacrifice_flashback_replay` | `Etali, Primal Conqueror #105 (real)` |
| `Liquimetal Coating` | `supports_type_change_continuous_effect_template` | `build_type_change_continuous_effect_evidence` | nao | nao | `temporary_artifact_type_change_replay` | `Magda, Brazen Outlaw #71 (real)` |
| `Mine Collapse` | `supports_alternative_cost_sacrifice_mountain_damage_template` | `build_alternative_cost_sacrifice_mountain_damage_evidence` | nao | nao | `sacrifice_mountain_alternative_cost_damage_replay` | `Magda, Brazen Outlaw #71 (real)` |
| `Nevermore` | `supports_named_card_cast_restriction_template` | `build_named_card_cast_restriction_evidence` | nao | nao | `named_card_cast_restriction_replay` | `Yorion, Sky Nomad #38 (real)` |
| `Opera Love Song` | `supports_impulse_topdeck_or_library_zone_template` | `build_impulse_topdeck_or_library_zone_evidence` | nao | nao | `instant_impulse_play_until_next_turn_replay` | `Gwen Stacy #65 (real)` |
| `Out of Time` | `supports_phase_out_mass_removal_counters_template` | `build_phase_out_mass_removal_counters_evidence` | nao | nao | `mass_phase_out_duration_counters_replay` | `Yorion, Sky Nomad #38 (real)` |
| `Power Artifact` | `supports_cost_reduction_static_aura_template` | `build_cost_reduction_static_aura_evidence` | nao | nao | `enchanted_artifact_activation_cost_reduction_replay` | `Urza, Lord High Artificer #87 (real)` |
| `Reality Acid` | `supports_vanishing_sacrifice_trigger_removal_template` | `build_vanishing_sacrifice_trigger_removal_evidence` | nao | nao | `vanishing_sacrifice_enchanted_permanent_replay` | `Yorion, Sky Nomad #38 (real)` |
| `Scroll of Fate` | `supports_manifest_from_hand_activated_ability_template` | `build_manifest_from_hand_activated_ability_evidence` | nao | nao | `manifest_card_from_hand_replay` | `Yorion, Sky Nomad #38 (real)` |
| `Stoke the Flames` | `supports_convoke_damage_template` | `build_convoke_damage_evidence` | nao | nao | `convoke_damage_payment_replay` | `Magda, Brazen Outlaw #71 (real)` |
| `Submerge` | `supports_alternative_cost_library_bounce_template` | `build_alternative_cost_library_bounce_evidence` | nao | nao | `alternative_cost_top_of_library_bounce_replay` | `Urza, Lord High Artificer #87 (real)` |
| `Sudden Shock` | `supports_split_second_damage_template` | `build_split_second_damage_evidence` | nao | nao | `split_second_damage_priority_lock_replay` | `Magda, Brazen Outlaw #71 (real)` |
| `Thorn of Amethyst` | `supports_static_noncreature_tax_template` | `build_static_noncreature_tax_evidence` | nao | nao | `static_noncreature_spell_tax_replay` | `Magda, Brazen Outlaw #71 (real)` |
| `Tragic Arrogance` | `supports_modal_mass_sacrifice_selection_template` | `build_modal_mass_sacrifice_selection_evidence` | nao | nao | `per_player_permanent_type_choice_sacrifice_replay` | `Yorion, Sky Nomad #38 (real)` |
| `Tyvar, Jubilant Brawler` | `supports_planeswalker_static_activated_graveyard_template` | `build_planeswalker_static_activated_graveyard_evidence` | nao | nao | `planeswalker_static_haste_and_graveyard_activation_replay` | `Sisay, Weatherlight Captain #31 (real)` |

## Priorizacao sugerida

1. Fechar familias que cobrem mais de uma carta: `manifest_cloak_equipment` (3)
   e `impulse_topdeck_or_library_zone` (2).
2. Em seguida, priorizar decks com maior pressao no backlog atual: `Yorion=8`,
   `Magda=8`, `Urza=5`.
3. Para cada familia, exigir quatro artefatos antes de considerar pronta:
   `focused_test.json`, `replay_events.jsonl`, `decision_trace.jsonl` e
   `replay_audit.json`.
4. Se uma familia nao deve virar builder agora, registrar waiver aceito por
   card/familia com motivo e owner.

## Criterio de fechamento

O gate so deve sair de `review_required` quando `focused_template_dispatch.json`
mostrar:

- `evidence_dispatch_ready=29`, ou waivers aceitos para os casos restantes;
- `focused_evidence_ready=29`, ou waivers aceitos para os casos restantes;
- `focused_evidence_not_ready_unwaived=0`;
- `evidence_runner_status_counts.unsupported=0`.

## Validacoes executadas

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_focused_template_dispatch_audit.py` - PASS, `3 tests passed`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py --coverage-json /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json --output /tmp/focused_template_dispatch_probe.md --json-output /tmp/focused_template_dispatch_probe.json --fail-on-not-ready` - exit `1` esperado, porque `status=review_required`, `focused_evidence_not_ready_unwaived=29` e `evidence_runner_status_counts={"unsupported":29}`.
