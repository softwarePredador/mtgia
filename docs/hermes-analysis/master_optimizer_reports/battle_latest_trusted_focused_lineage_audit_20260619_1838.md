# Battle Latest Trusted Focused and Lineage Audit - 2026-06-19T18:38Z

## Escopo

Auditoria read-only apos executar o wrapper recorrente completo com as mesmas
16 seeds, para reconciliar o `latest/summary.json` com o worktree atual de
focused evidence.

Comando executado:

`MANALOOM_BATTLE_STRATEGY_SEEDS=16 /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 16 --start-seed 63201734`

Nenhuma consulta ou alteracao PostgreSQL foi feita. Nenhum swap foi aplicado.
Nenhum codigo foi alterado por esta auditoria. Nenhum commit foi feito.

## Resultado principal

- Latest: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_183529/summary.json`
- `timestamp_utc=2026-06-19T18:35:29Z`
- `seeds_completed=16`
- `events=14679`
- `decisions=2265`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`

Nao ha alerta atual pelo criterio do usuario: nenhum high/critical em action
findings e nenhum strategy blocker.

## Focused template dispatch

O gate `focused_template_dispatch` agora passou no latest oficial:

- `focused_template_cards=29`
- `template_predicate_match=29`
- `evidence_dispatch_ready=29`
- `focused_evidence_ready=29`
- `focused_evidence_not_ready_unwaived=0`
- `accepted_waivers=0`
- `supports_template_count=47`
- `evaluate_dispatch_template_count=47`
- `build_evidence_function_count=47`
- `supports_not_dispatched=[]`
- `evidence_runner_status_counts={"evidence_ready":29}`

Antes da execucao completa, um probe targeted tambem confirmou o mesmo estado:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/focused-template-current-probe-20260619_1836/focused_template_dispatch.json`
- `focused_template_dispatch_ready`
- `29/29` evidence ready
- `116` arquivos de evidencia gerados no probe targeted

## Templates prontos por card

| Card | Template | Decks |
| --- | --- | --- |
| Ashnod's Transmogrant | `supports_counter_type_change_template` | Magda, Brazen Outlaw |
| Banishing Knack | `supports_granted_bounce_ability_template` | Urza, Lord High Artificer |
| Candelabra of Tawnos | `supports_utility_artifact_untap_x_lands_template` | Akiri, Line-Slinger |
| Clown Car | `supports_x_vehicle_counters_token_template` | Magda, Brazen Outlaw |
| Codex Shredder | `supports_mill_graveyard_return_template` | Urza, Lord High Artificer |
| Copy Artifact | `supports_copy_artifact_as_enters_template` | Kraum, Ludevic's Opus; Urza, Lord High Artificer |
| Cryptic Coat | `supports_manifest_cloak_equipment_template` | Yorion, Sky Nomad |
| Cursed Windbreaker | `supports_manifest_cloak_equipment_template` | Yorion, Sky Nomad |
| Dissection Tools | `supports_manifest_cloak_equipment_template` | Yorion, Sky Nomad |
| Firestorm | `supports_additional_cost_discard_multi_target_damage_template` | Ishai, Ojutai Dragonspeaker; Kenrith, the Returned King; Kraum, Ludevic's Opus |
| Flash Photography | `supports_copy_permanent_flash_or_flashback_template` | Ishai, Ojutai Dragonspeaker; Kenrith, the Returned King |
| God-Pharaoh's Statue | `supports_static_tax_opponent_life_loss_template` | Magda, Brazen Outlaw |
| Heroes' Hangout | `supports_impulse_topdeck_or_library_zone_template` | Gwen Stacy |
| Hidden Strings | `supports_tap_untap_cipher_trigger_template` | Akiri, Line-Slinger |
| Kindle the Inner Flame | `supports_copy_token_delayed_sacrifice_template` | Etali, Primal Conqueror |
| Liquimetal Coating | `supports_type_change_continuous_effect_template` | Magda, Brazen Outlaw |
| Mine Collapse | `supports_alternative_cost_sacrifice_mountain_damage_template` | Magda, Brazen Outlaw |
| Nevermore | `supports_named_card_cast_restriction_template` | Yorion, Sky Nomad |
| Opera Love Song | `supports_impulse_topdeck_or_library_zone_template` | Gwen Stacy |
| Out of Time | `supports_phase_out_mass_removal_counters_template` | Yorion, Sky Nomad |
| Power Artifact | `supports_cost_reduction_static_aura_template` | Urza, Lord High Artificer |
| Reality Acid | `supports_vanishing_sacrifice_trigger_removal_template` | Yorion, Sky Nomad |
| Scroll of Fate | `supports_manifest_from_hand_activated_ability_template` | Yorion, Sky Nomad |
| Stoke the Flames | `supports_convoke_damage_template` | Magda, Brazen Outlaw |
| Submerge | `supports_alternative_cost_library_bounce_template` | Urza, Lord High Artificer |
| Sudden Shock | `supports_split_second_damage_template` | Magda, Brazen Outlaw |
| Thorn of Amethyst | `supports_static_noncreature_tax_template` | Magda, Brazen Outlaw |
| Tragic Arrogance | `supports_modal_mass_sacrifice_selection_template` | Yorion, Sky Nomad |
| Tyvar, Jubilant Brawler | `supports_planeswalker_static_activated_graveyard_template` | Sisay, Weatherlight Captain |

## Forensic lineage

O gate forensic passou e a linhagem agregada ficou `complete` porque todos os
campos ausentes foram aceitos por waiver explicito:

- `forensic_card_event_count=1518`
- `forensic_card_id_present=988`
- `forensic_card_id_missing=530`
- `forensic_card_id_missing_accepted=530`
- `forensic_card_id_missing_unaccepted=0`
- `forensic_semantic_hash_present=988`
- `forensic_semantic_hash_missing=530`
- `forensic_semantic_hash_missing_accepted=530`
- `forensic_semantic_hash_missing_unaccepted=0`
- `forensic_rule_logical_key_present=1502`
- `forensic_rule_logical_key_missing=16`
- `forensic_rule_logical_key_missing_accepted=16`
- `forensic_rule_logical_key_missing_unaccepted=0`
- `forensic_lineage_unaccepted_missing_samples=[]`
- `forensic_lineage_status=complete`

Waiver reasons agregados:

- `battle_rule_registry_without_card_identity_columns=520`
- `land_played_curated_runtime_rule_without_pg_card_identity=494`
- `manual_runtime_waiver_without_pg_identity=14`
- `type_line_creature_fact_no_rule_identity=48`

Leitura: ainda existem campos missing brutos, mas nao existem missing
unaccepted. Portanto o achado antigo de linhagem incompleta deve ser fechado
para este corpus/latest, mantendo apenas a recomendacao de nao esconder os
contadores accepted/unaccepted nos relatorios.

## Strategy confidence

- `strategy_findings=3`
- `strategy_low_confidence_findings=3`
- `strategy_review_required_findings=0`
- `strategy_learning_confidence_counts={"high_confidence_replay":13,"low_confidence_replay":3}`
- `strategy_low_confidence_seeds=["63201739","63201740","63201741"]`

Leitura: os tres forced keeps continuam fora de high-confidence learning, com
peso `0.0`, mas nao seguram o gate strategy em review.

## Impacto nos achados

Fechados por evidencia do latest `20260619_183529`:

- `BV-011`: coverage residual aceito e focused dispatch pronto.
- `BV-039`: contrato efeito/template passa para o corpus atual; focused
  dispatch tambem passa.
- `BV-048`: focused template dispatch pronto, `29/29`.
- `BV-050`: forensic lineage completa por accepted/unaccepted, sem missing
  unaccepted.
- `BV-054`: todos os `29` cards focados tem evidencia pronta.
- `BV-055`: `supports_not_dispatched=[]`, `47/47` supports com dispatch.

Ainda aberto:

- `BV-047`: fixture depth estatica ainda exige validacao de branches raros
  emissiveis, mesmo que o event contract atual passe.
- `BV-057`: optimizer/WR ainda precisa carregar gate status ou waiver de corpus
  antes de usar WR como evidencia final.

## Validacoes executadas

- Probe targeted:
  - `battle_focused_template_dispatch_audit.py --fail-on-not-ready`
  - PASS, `focused_template_dispatch_ready`, `29/29` evidence ready.
- Wrapper completo:
  - `manaloom-battle-strategy-audit.sh --seeds 16 --start-seed 63201734`
  - PASS, latest avancou para `20260619_183529`.
