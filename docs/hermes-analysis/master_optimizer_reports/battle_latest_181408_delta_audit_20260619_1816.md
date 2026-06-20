# Battle Latest 181408 Delta Audit - 2026-06-19T18:16Z

## Escopo

Sanity check read-only apos o symlink `latest` avancar de
`20260619_175911` para `20260619_181408` durante a validacao.

Fontes verificadas:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_181408/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_181408/focused_template_dispatch.json`
- `/tmp/focused_template_dispatch_probe_181408.json`
- `git status --short -- server/bin/manaloom_battle_rule_focused_evidence.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py`

Nenhuma consulta ou alteracao PostgreSQL foi feita. Nenhum swap foi aplicado.
Nenhum codigo de produto foi alterado por esta auditoria.

## Nota de estado externo

O worktree atual mostra alteracoes de codigo fora desta auditoria:

- `M server/bin/manaloom_battle_rule_focused_evidence.py`
- `?? docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py`

Esta auditoria apenas leu o estado atual e registrou os artefatos gerados pelo
latest. Nao reverteu, editou ou commitou esses arquivos.

## Delta do latest

Estado agregado:

- `timestamp_utc=2026-06-19T18:14:08Z`
- `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["focused_template_dispatch=review_required","strategy_audit=review_required"]`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`
- `seeds_with_high_or_critical_forensic_findings=[]`

Mudancas relevantes contra o snapshot `20260619_175911`:

- `forensic_audit` saiu de `review_required` para `pass`.
- `forensic_rule_findings` caiu de `8` para `0`.
- `focused_template_dispatch` melhorou de `0` para `5` evidencias prontas.
- `focused_template_dispatch` ainda esta `review_required`, com `24`
  templates sem dispatch/evidence/waiver.
- `strategy_audit` permanece `review_required` pelos mesmos `3` seeds
  low-confidence.

## Focused template atual

Resumo:

- `focused_template_cards=29`
- `template_predicate_match=29`
- `evidence_dispatch_ready=5`
- `focused_evidence_ready=5`
- `focused_evidence_not_ready_unwaived=24`
- `accepted_waivers=0`
- `evidence_runner_status_counts={"evidence_ready":5,"unsupported":24}`
- `supports_template_count=47`
- `evaluate_dispatch_template_count=23`
- `build_evidence_function_count=23`
- `supports_not_dispatched=24`

Evidencias prontas:

| Card | Template | Deck |
| --- | --- | --- |
| `Cryptic Coat` | `supports_manifest_cloak_equipment_template` | `Yorion, Sky Nomad #38 (real)` |
| `Cursed Windbreaker` | `supports_manifest_cloak_equipment_template` | `Yorion, Sky Nomad #38 (real)` |
| `Dissection Tools` | `supports_manifest_cloak_equipment_template` | `Yorion, Sky Nomad #38 (real)` |
| `Heroes' Hangout` | `supports_impulse_topdeck_or_library_zone_template` | `Gwen Stacy #65 (real)` |
| `Opera Love Song` | `supports_impulse_topdeck_or_library_zone_template` | `Gwen Stacy #65 (real)` |

Templates ainda sem evidence:

| Card | Template | Decks |
| --- | --- | --- |
| `Ashnod's Transmogrant` | `supports_counter_type_change_template` | `Magda, Brazen Outlaw #71 (real)` |
| `Banishing Knack` | `supports_granted_bounce_ability_template` | `Urza, Lord High Artificer #87 (real)` |
| `Candelabra of Tawnos` | `supports_utility_artifact_untap_x_lands_template` | `Akiri, Line-Slinger #30 (real)` |
| `Clown Car` | `supports_x_vehicle_counters_token_template` | `Magda, Brazen Outlaw #71 (real)` |
| `Codex Shredder` | `supports_mill_graveyard_return_template` | `Urza, Lord High Artificer #87 (real)` |
| `Copy Artifact` | `supports_copy_artifact_as_enters_template` | `Kraum, Ludevic's Opus #50 (real)`; `Urza, Lord High Artificer #87 (real)` |
| `Firestorm` | `supports_additional_cost_discard_multi_target_damage_template` | `Ishai, Ojutai Dragonspeaker #28 (real)`; `Kenrith, the Returned King #113 (real)`; `Kraum, Ludevic's Opus #50 (real)` |
| `Flash Photography` | `supports_copy_permanent_flash_or_flashback_template` | `Ishai, Ojutai Dragonspeaker #28 (real)`; `Kenrith, the Returned King #113 (real)` |
| `God-Pharaoh's Statue` | `supports_static_tax_opponent_life_loss_template` | `Magda, Brazen Outlaw #71 (real)` |
| `Hidden Strings` | `supports_tap_untap_cipher_trigger_template` | `Akiri, Line-Slinger #30 (real)` |
| `Kindle the Inner Flame` | `supports_copy_token_delayed_sacrifice_template` | `Etali, Primal Conqueror #105 (real)` |
| `Liquimetal Coating` | `supports_type_change_continuous_effect_template` | `Magda, Brazen Outlaw #71 (real)` |
| `Mine Collapse` | `supports_alternative_cost_sacrifice_mountain_damage_template` | `Magda, Brazen Outlaw #71 (real)` |
| `Nevermore` | `supports_named_card_cast_restriction_template` | `Yorion, Sky Nomad #38 (real)` |
| `Out of Time` | `supports_phase_out_mass_removal_counters_template` | `Yorion, Sky Nomad #38 (real)` |
| `Power Artifact` | `supports_cost_reduction_static_aura_template` | `Urza, Lord High Artificer #87 (real)` |
| `Reality Acid` | `supports_vanishing_sacrifice_trigger_removal_template` | `Yorion, Sky Nomad #38 (real)` |
| `Scroll of Fate` | `supports_manifest_from_hand_activated_ability_template` | `Yorion, Sky Nomad #38 (real)` |
| `Stoke the Flames` | `supports_convoke_damage_template` | `Magda, Brazen Outlaw #71 (real)` |
| `Submerge` | `supports_alternative_cost_library_bounce_template` | `Urza, Lord High Artificer #87 (real)` |
| `Sudden Shock` | `supports_split_second_damage_template` | `Magda, Brazen Outlaw #71 (real)` |
| `Thorn of Amethyst` | `supports_static_noncreature_tax_template` | `Magda, Brazen Outlaw #71 (real)` |
| `Tragic Arrogance` | `supports_modal_mass_sacrifice_selection_template` | `Yorion, Sky Nomad #38 (real)` |
| `Tyvar, Jubilant Brawler` | `supports_planeswalker_static_activated_graveyard_template` | `Sisay, Weatherlight Captain #31 (real)` |

Remaining pressure by deck:

- `Magda, Brazen Outlaw`: `8`
- `Urza, Lord High Artificer`: `5`
- `Yorion, Sky Nomad`: `5`
- `Akiri, Line-Slinger`: `2`
- `Kraum, Ludevic's Opus`: `2`
- `Ishai, Ojutai Dragonspeaker`: `2`
- `Kenrith, the Returned King`: `2`
- `Etali, Primal Conqueror`: `1`
- `Sisay, Weatherlight Captain`: `1`

## Forensic atual

- `forensic_audit.status=pass`
- `forensic_rule_findings=0`
- `forensic_card_event_count=1518`
- `forensic_card_id_missing=530`
- `forensic_semantic_hash_missing=530`
- `forensic_rule_logical_key_missing=16`
- `forensic_lineage_status=incomplete`

Leitura: o gate forensic nao tem finding atual, mas a linhagem ainda nao esta
completa. O achado de linhagem continua valido ate existir completion ou waiver
por classe de evento.

## Strategy atual

- `strategy_audit.status=review_required`
- `strategy_findings=3`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":3}`
- `strategy_learning_confidence_counts={"high_confidence_replay":13,"low_confidence_replay":3}`
- `strategy_low_confidence_seeds=["63201739","63201740","63201741"]`
- `seeds_with_strategy_blockers=[]`

Leitura: nao ha blocker, mas o denominador de aprendizado continua sendo `13`
high-confidence e `3` low-confidence.

## Validacoes executadas

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py --coverage-json /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json --output /tmp/focused_template_dispatch_probe_181408.md --json-output /tmp/focused_template_dispatch_probe_181408.json --fail-on-not-ready` - exit `1` esperado; `status=review_required`, `focused_evidence_ready=5`, `focused_evidence_not_ready_unwaived=24`.
