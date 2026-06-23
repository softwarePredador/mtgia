# Battle Validation Register - 2026-06-19

## Objetivo

Este documento e o registro vivo deste chat para validacao especializada do
battle ManaLoom. Use como ponto de entrada para anotar falhas encontradas em:

- `replay.txt` e logs humanos;
- `replay.events.jsonl`;
- `replay.decision_trace.jsonl`;
- auditores `battle_action_critic.py` e `battle_decision_strategy_auditor.py`;
- logica de simulacao, legalidade, alvo, custo, prioridade e aprendizagem.

Regra operacional: toda falha deve ter evidencia concreta antes de virar
implementacao. Nao aplicar swaps, nao alterar PostgreSQL e nao tratar WR ou
replay aprovado como prova absoluta sem auditoria.

## Checkpoint Auditor Central - replay.txt final hand cards - 2026-06-22 10:21 -0300

Escopo:

- Complementar o replay humano para mostrar, no fechamento `GAME OVER`, as
  cartas remanescentes na mao de cada jogador.
- Nenhum PostgreSQL apply, deck swap, cleanup, stage, commit ou push foi
  executado neste checkpoint.

Alteracao:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
  passou a escrever `HandCards=[...]` nas linhas finais de cada jogador.
- A renderizacao usa `battle.replay_card_snapshot(...)`, a mesma origem
  estruturada usada nos eventos `turn_start` e `turn_end`.
- Cobertura adicionada em
  `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
  com `test_final_player_summary_includes_hand_card_names`.

Evidencia:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`: pass.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`: 10 testes pass.
- Replay real:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/manual-replay-handcards-check/20260622_102100/replay.txt`.
- Trecho validado: linhas `416-419` do replay gerado mostram `HandCards=[...]`
  para Lorehold e os tres oponentes no `GAME OVER`.
- Relatorio:
  `docs/hermes-analysis/master_optimizer_reports/replay_final_handcards_renderer_20260622_102100.md`.

Status:

- Fechado para renderer humano. O `replay.txt` agora mostra as cartas restantes
  na mao dos jogadores tambem no fechamento do jogo.

## Checkpoint Auditor Central - commander damage survival and current candidate - 2026-06-22 13:54 -0300

Escopo:

- Corrigir e validar a janela defensiva de combate quando o dano letal vem de
  dano de comandante, nao apenas de dano de vida.
- Reexecutar a janela oficial atual e testar candidatos locais sem aplicar
  swap permanente nem PostgreSQL deck deploy.
- Registrar que o `latest` atual aponta para uma simulacao candidata
  `review_required`, nao para baseline oficial aprovado.

Alteracao de runtime:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  passou a calcular `commander_lethal` e `commander_lethal_sources` na
  projecao de dano de combate.
- `combat_defensive_response_window(...)` agora dispara resposta de
  sobrevivencia quando dano de comandante projetado chega a `21`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
  adiciona `test_combat_response_handles_commander_damage_lethal`.

Evidencia:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`: pass.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`: pass.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`: pass.
- Focus seed:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_134349/summary.json`.
  Gate-clean, tests `pass=18`, `battle_replay_final_status=trusted_for_strategy_learning`.
- Replay proof:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_134349/seed_63231325/replay.txt`.
  Linha `419` mostra `CAST Lorehold: Teferi's Protection` em
  `combat_damage`; linha `421` mostra `DAMAGE Kraum ... -> Lorehold: 0`.
- Decision trace:
  `decision-000164` tem
  `actual_outcome=combat_survival_response_cast`,
  `commander_lethal=true`, e fonte de dano `20 + 4 = 24`.

Resultado oficial apos fix:

- Full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_134502/summary.json`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `seeds_completed=16`, tests `pass=18`.
- Lorehold `1/16`, oponentes `14/16`, dano de combate dos oponentes no
  Lorehold `328`, em outros jogadores `5`.
- Leitura: bug de runtime fechado, deck ainda fraco sob foco multiplayer.

Candidatos locais:

- `Ensnaring Bridge` sobre `Electroduplicate`:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_133008/summary.json`.
  Trusted, Lorehold `1/16`, pressao no Lorehold `329`. Rejeitado.
- `Magus of the Moat` + `Sphere of Safety` sobre `Electroduplicate` +
  `Victory Chimes`:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_135408/summary.json`.
  `review_required`, Lorehold `2/16`, oponentes `14/16`, pressao no Lorehold
  `267`, pressao em outros `3`, tests `pass=18`.
- O blocker da candidata e
  `board_wipe_without_timing_justification` em
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_135408/seed_63231314/strategy_audit.md`.
- `latest` agora aponta para `20260622_135408`, mas esse artifact e candidato
  `review_required`; nao deve ser tratado como baseline oficial aprovado.

Estado:

- Nenhum PostgreSQL deploy, swap permanente, commit ou push foi feito neste
  checkpoint.
- SQLite runtime restaurado em
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`:
  `Electroduplicate=1`, `Victory Chimes=1`, deck rows `100`, deck quantity
  `100`.
- Relatorio completo:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_deck6_commander_damage_teferi_and_magus_sphere_current_20260622_135408.md`.

Proxima decisao:

- Auditar o `board_wipe_without_timing_justification` da seed `63231314` antes
  de qualquer pacote PostgreSQL. Se for erro real de estrategia, corrigir a
  sequencia; se for falso positivo do auditor, ajustar o auditor e rerodar a
  candidata.

## Checkpoint Auditor Central - eliminated player cleanup and Magus+Sphere gate clean - 2026-06-22 14:26 -0300

Escopo:

- Fechar a investigacao do blocker
  `board_wipe_without_timing_justification` da candidata Magus+Sphere na seed
  `63231314`.
- Separar beneficio real contra oponente vivo de contaminacao por permanentes
  de jogadores ja eliminados.
- Rerodar seed focada e janela completa candidata com SQLite temporaria,
  restaurando o deck oficial depois.

Correcao:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_support.py`
  remove `battlefield` e `phased_out` do jogador quando ele e eliminado.
- O evento `player_eliminated` agora inclui
  `battlefield_removed_from_game` e `phased_out_removed_from_game`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  passou a registrar no trace de board wipe:
  `actual_destroyed`, `own_creatures_destroyed`,
  `opponent_creatures_destroyed`, `live_opponent_creatures_destroyed`,
  `stale_opponent_creatures_destroyed`, `actual_asymmetry` e
  `self_protected_from_wipe`.
- A justificativa estrategica do wipe usa destruicao de oponente vivo; objeto
  obsoleto de jogador eliminado fica apenas como diagnostico.

Testes:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_support.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_zone_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`: pass.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`: pass.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`: pass.
- Regressions adicionadas:
  `test_eliminated_player_battlefield_leaves_game` e
  `test_board_wipe_trace_uses_resolution_result_after_phase_out`.

Evidencia oficial:

- Full oficial externo:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_141844/summary.json`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, tests `pass=18`, Lorehold `1/16`,
  oponentes `14/16`, pressao no Lorehold `301`, pressao em outros `12`.
- Resíduo: `forced_keep_after_bad_mulligan=1` na seed `63231422`.

Evidencia candidata:

- Focus Magus+Sphere seed `63231314`:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_142458/summary.json`.
- A seed ficou `trusted_for_strategy_learning`, sem divergencias, Lorehold
  `1/1`.
- O trace `decision-000299` registra
  `live_opponent_creatures_destroyed=1`,
  `stale_opponent_creatures_destroyed=0`, `actual_asymmetry=1` e
  `risk_flags=[]`.
- Full Magus+Sphere:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_142625/summary.json`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, tests `pass=18`, Lorehold `2/16`,
  oponentes `14/16`, pressao no Lorehold `267`, pressao em outros `3`.
- Resíduo: `forced_keep_after_bad_mulligan=1` na seed `63231318`.

Estado:

- Nenhum PostgreSQL deploy, swap permanente, commit, push ou stash foi feito.
- SQLite runtime restaurado:
  `Electroduplicate=1`, `Victory Chimes=1`, deck rows `100`, deck quantity
  `100`.
- Backups temporarios pre-swap gerados neste ciclo foram removidos.
- Relatorio completo:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_deck6_elimination_cleanup_magus_sphere_gate_clean_20260622_142625.md`.

Decisao:

- Contaminacao por permanentes de jogadores eliminados esta fechada por codigo,
  testes e artifact.
- Magus+Sphere agora e candidata gate-clean, mas `2/16` ainda nao justifica
  deploy PostgreSQL de deck.
- Proximo trabalho: analisar as 14 derrotas da candidata `20260622_142625`,
  ignorando a seed de mulligan low-confidence quando apropriado, e buscar
  proximo ajuste de estabilizacao/conversao.

## Checkpoint Auditor Central - latest 000827 trusted after Wrath variant sweep - 2026-06-20 21:08 -0300

Escopo:

- Reconciliar os runners externos que supersederam `235914` e `000525`.
- Nenhum PostgreSQL apply, cache hotfix, deck swap, cleanup, stage, commit ou
  push foi executado por este heartbeat.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_000827/summary.json`.
- `run_scope=recurring_full`,
  `invocation_kind=codex_real_deck_after_wrath_variants`,
  `seeds_requested=16`, `seeds_completed=16`, `start_seed=63212310`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.

Battle evidence:

- `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `forensic_severity_counts={}`.
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`.
- `table_intent_statuses={"pass":16}`.
- `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`.
- `test_results_status_counts={"pass":18}`.

Classificacao:

- PG-015/Wrath fica fechado para estado PostgreSQL/cache e validado pelo latest
  trusted `000827`.
- `235914` / `Arcane Epiphany` fica como drift real superseded, nao blocker
  ativo do latest.
- PG-012/PG-013/PG-014 continuam fechados.

## Checkpoint Auditor Central - latest 235914 Arcane blocker after PG-015/Wrath - 2026-06-20 20:59 -0300

Escopo:

- Reconciliar os novos artefatos PG-015/Wrath e o latest gerado depois deles.
- Nenhum PostgreSQL apply, cache hotfix, deck swap, cleanup, stage, commit ou
  push foi executado por este heartbeat.

PG-015/Wrath evidence:

- Novos artefatos:
  `wrath_of_god_battle_rule_pg015_*_20260620_205619.*` e
  `battle_card_rules_sqlite_from_pg_pg015_wrath_20260620_205900.json`.
- Postcheck read-only: `curated_executable_rows=1`,
  `stale_enabled_wipe_rows=0`.
- Regra PostgreSQL: `Wrath of God`,
  `battle_rule_v1:3c8d1d97cf71a2cb4fef4cb0439f474e`,
  effect `board_wipe`, source `curated`, confidence `1.000`,
  `review_status=verified`, `execution_status=auto`,
  `reviewed_by=codex_central_auditor_pg015`.
- Sync report: `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5236`, `sqlite_inserted_or_updated=5172`,
  `canonical_snapshot_rows_exported=3195`.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_235914/summary.json`.
- `run_scope=recurring_full`,
  `invocation_kind=codex_variant_wrath_for_guttersnipe`,
  `seeds_requested=16`, `seeds_completed=16`, `start_seed=63212310`.
- `battle_replay_final_status=blocked`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked"]`.

Battle evidence:

- `forensic_rule_findings=2`, `forensic_turn_findings=0`,
  `forensic_severity_counts={"high":1,"medium":1}`.
- Ambos os achados sao `Arcane Epiphany`, player
  `The Emperor of Palamecia #42 (real)`, seed `63212310`, turn `10`,
  phase `precombat_main`, effect `draw_cards`, source `functional_tags_json`.
- `spell_cast` e medium; `spell_resolved` e high.
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`.
- `table_intent_statuses={"pass":16}`.
- `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`.
- `test_results_status_counts={"pass":18}`.

Classificacao:

- PG-015/Wrath esta fechado para estado PostgreSQL/cache, mas nao fecha o latest
  battle porque o blocker atual e `Arcane Epiphany`.
- `Arcane Epiphany` e a pendencia ativa de battle-rule lineage; ela tem `0`
  linhas PG/local `battle_rule` conforme checks read-only anteriores.
- PG-012/PG-013/PG-014 continuam fechados.

## Checkpoint Auditor Central - latest 235219 trusted after variant sweep - 2026-06-20 20:52 -0300

Escopo:

- Reler o latest depois que o runner externo ativo no checkpoint `234900`
  terminou.
- Nenhum PostgreSQL apply, cache hotfix, deck swap, cleanup, stage, commit ou
  push foi executado.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_235219/summary.json`.
- `run_scope=recurring_full`,
  `invocation_kind=codex_real_deck_after_variants`,
  `seeds_requested=16`, `seeds_completed=16`, `start_seed=63212310`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.

Battle evidence:

- `forensic_rule_findings=0`, `forensic_turn_findings=0`.
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`.
- `table_intent_statuses={"pass":16}`.
- `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`.
- `event_contract_static_observed_unclassified_total=0` and
  `event_contract_static_static_unclassified_total=0`.
- `test_results_status_counts={"pass":18}`; compatibility fields
  `tests_passed` and `tests_total` are `null`.

Classificacao:

- `234900` / `Arcane Epiphany` fica como drift real superseded, nao blocker
  ativo do latest.
- PG-012/PG-013/PG-014 continuam fechados.
- `Arcane Epiphany` permanece candidato futuro somente se o blocker
  reaparecer ou se Rafael priorizar o pacote; nenhum apply foi autorizado.

## Checkpoint Auditor Central - latest 234900 Arcane Epiphany blocker - 2026-06-20 20:49 -0300

Escopo:

- Reconciliar a varredura externa de variants que supersedeu `234004`.
- Nenhum PostgreSQL apply, cache hotfix, deck swap, cleanup, stage, commit ou
  push foi executado.

Estado oficial full atual neste checkpoint:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_234900/summary.json`.
- `run_scope=recurring_full`,
  `invocation_kind=codex_variant_spire_for_guttersnipe`,
  `seeds_requested=16`, `seeds_completed=16`, `start_seed=63212310`.
- `battle_replay_final_status=blocked`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked"]`.

Battle evidence:

- `forensic_rule_findings=2`, `forensic_turn_findings=0`,
  `forensic_severity_counts={"high":1,"medium":1}`.
- Ambos os achados sao `Arcane Epiphany`, player
  `The Emperor of Palamecia #42 (real)`, seed `63212310`, turn `10`,
  phase `precombat_main`, effect `draw_cards`, source `functional_tags_json`.
- `spell_cast` e medium; `spell_resolved` e high.
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`.
- `table_intent_statuses={"pass":16}`.
- `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`.
- `test_results_status_counts={"pass":18}`.

Classificacao:

- PG-012/PG-013/PG-014 continuam fechados.
- O current latest neste checkpoint esta bloqueado por PG-015 candidata
  `Arcane Epiphany`.
- A varredura externa ainda iniciou outro runner apos esta leitura; futuro
  heartbeat precisa reler `latest` antes de agir.

## Historical Checkpoint Auditor Central - 234004 trusted after variant reruns - 2026-06-20 20:40 -0300

Escopo:

- Reconciliar os runners externos que supersederam o bloqueio `233350`.
- Nenhum PostgreSQL apply, cache hotfix, deck swap, cleanup, stage, commit ou
  push foi executado.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_234004/summary.json`.
- `run_scope=recurring_full`,
  `invocation_kind=codex_variant_sphere_for_victory_chimes`,
  `seeds_requested=16`, `seeds_completed=16`, `start_seed=63212310`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.

Battle evidence:

- `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `forensic_severity_counts={}`.
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`.
- `table_intent_statuses={"pass":16}`.
- `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`.
- `test_results_status_counts={"pass":18}`.

Classificacao:

- `233350` / `Arcane Epiphany` fica como drift real superseded, nao blocker
  ativo do latest.
- PG-012/PG-013/PG-014 continuam fechados.
- `Arcane Epiphany` permanece candidato futuro se o blocker reaparecer
  ou se Rafael priorizar o pacote; nenhum apply foi autorizado.

## Historical Checkpoint Auditor Central - 233350 Arcane Epiphany blocker - 2026-06-20 20:37 -0300

Escopo:

- Reconciliar o runner externo que supersedeu `232534`.
- Registrar o blocker real atual sem aplicar PostgreSQL, cache hotfix, deck
  swap, cleanup, stage, commit ou push.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_233350/summary.json`.
- `run_scope=recurring_full`,
  `invocation_kind=codex_variant_sphere_for_guttersnipe`,
  `seeds_requested=16`, `seeds_completed=16`, `start_seed=63212310`.
- `battle_replay_final_status=blocked`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked"]`.

Battle evidence:

- `forensic_rule_findings=2`, `forensic_turn_findings=0`,
  `forensic_severity_counts={"high":1,"medium":1}`.
- Ambos os achados sao `Arcane Epiphany`, player
  `The Emperor of Palamecia #42 (real)`, seed `63212310`, turn `10`,
  phase `precombat_main`, effect `draw_cards`, source `functional_tags_json`.
- `spell_cast` e medium; `spell_resolved` e high.
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`.
- `table_intent_statuses={"pass":16}`.
- `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`.
- `test_results_status_counts={"pass":18}`.

PG/cache evidence:

- SELECT-only PostgreSQL check: `Arcane Epiphany` has one `cards` row,
  `id=f5395e90-d0ef-4bf0-b042-f0cff60d31ae`, mana cost `{3}{U}{U}`,
  `type_line=Instant`, `cmc=5.0`, colors `{U}`, color identity `{U}`, oracle
  `This spell costs {1} less to cast if you control a Wizard. Draw three cards.`
- The same SELECT showed `battle_rule_rows=0`.
- Local SQLite `battle_card_rules` has `0` rows for `Arcane Epiphany`.
- The card is absent from `known_cards_canonical_snapshot.json`,
  `known_cards_generated.json`, and `reviewed_battle_card_rules.json`.

Classificacao:

- PG-012/PG-013/PG-014 continuam fechados pela validacao `232534`.
- Naquele checkpoint, o latest estava bloqueado por PG-015 candidata
  `Arcane Epiphany`; depois, `234004` superseded esse bloqueio.
- Fechamento futuro exige pacote row-level, precheck, apply aprovado,
  rollback, postcheck, sync Hermes runtime cache e novo battle rerun.

## Checkpoint Auditor Central - latest 232534 trusted after PG-012/013/014 - 2026-06-20 20:30 -0300

Escopo:

- Reconciliar PG-012 `Flame Wave`, PG-013 `Brainstone` e PG-014
  `Sphere of Safety`, detectados como aplicados externamente.
- Validar que o latest full posterior ao sync PG-014 supersede o residual
  `Flame Wave` de `224455`.
- Nenhum PostgreSQL apply, deck swap por comando, cleanup, stage, commit ou
  push foi executado por este heartbeat.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_232534/summary.json`.
- `run_scope=recurring_full`, `invocation_kind=manual_cli`,
  `seeds_requested=16`, `seeds_completed=16`, `start_seed=63212325`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `test_results_status_counts={"pass":18}`.

Battle evidence:

- `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `forensic_severity_counts={}`.
- `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`.
- `table_intent_statuses={"pass":16}`.
- `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=231`,
  `target_pressure_opponent_combat_to_other=7`,
  `target_pressure_opponent_multi_defender_attack=1`.
- `strategy_findings=5`, all low-confidence only;
  `strategy_review_required_findings=0`.

PG/cache evidence:

- PG-012 read-only postcheck: `Flame Wave` has one curated executable
  `damage_player_and_creatures` rule and no stale enabled remove rows.
- PG-013 read-only postcheck: `Brainstone` has one curated executable
  `topdeck_manipulation` rule and no stale enabled draw rows.
- PG-014 read-only postcheck: `Sphere of Safety` has one curated executable
  `attack_tax_per_enchantment` rule, no stale enabled draw rows, and one
  `protection` function-tag row from `card_battle_rules_v1`.
- PG-014 sync artifact
  `battle_card_rules_sqlite_from_pg_pg014_sphere_20260620_202250.json`
  reports `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5236`, `sqlite_inserted_or_updated=5172`, and
  `canonical_snapshot_rows_exported=3195`.
- Local SQLite and `known_cards_canonical_snapshot.json` confirm
  `Sphere of Safety` as curated/verified/auto `attack_tax`.

Focused validation:

- `python3 -m py_compile` over
  `sync_battle_card_rules_pg.py` and
  `test_sync_battle_card_rules_pg_selection.py` exited `0`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py`
  exited `0` with `7` tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  exited `0`, including `Flame Wave`, `Brainstone`, and
  `Sphere of Safety` regressions.

Classificacao:

- O residual low `Flame Wave` de `224455` esta historico e superseded.
- PG-012, PG-013 e PG-014 estao fechados como estado externo aplicado,
  postchecked, synced localmente e validado por battle full.
- Nao ha pendencia real ativa de battle gate neste snapshot.

## Checkpoint Auditor Central - latest 224455 forensic low review - 2026-06-20 19:48 -0300

Escopo:

- Reconciliar o latest full `20260620_224455`, que supersede o `221652`.
- Registrar a validacao pos-PG-011 detectado externamente.
- Nenhum PostgreSQL apply, deck swap por comando, cleanup, stage, commit ou
  push foi executado por este heartbeat.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_224455/summary.json`.
- `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63212244`.
- `battle_replay_final_status=review_required`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`.
- `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- `test_results_status_counts={"pass":18}`.
- Gates limpos: `action_critic`, `replay_decision_audit`,
  `strategy_audit`, `table_intent`, `target_pressure`, `effect_coverage`,
  `focused_template_dispatch`, `unknown_template_backlog`,
  `decision_trace_taxonomy` e `event_contract_static`.

Battle evidence:

- `forensic_rule_findings=6`, `forensic_turn_findings=0`,
  `forensic_severity_counts={"low":6}`.
- Os seis achados sao `Flame Wave`: runtime effect `passive` difere do
  registry effect `remove_creature` em `spell_cast` e `spell_resolved` nas
  seeds `63212248`, `63212253` e `63212256`.
- Recomendacao do forensic auditor: normalmente oracle normalization; revisar
  apenas se o comportamento parecer errado no replay.
- `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`.
- `table_intent_statuses={"pass":16}`.
- `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=284`,
  `target_pressure_opponent_combat_to_other=4`,
  `target_pressure_opponent_multi_defender_attack=2`.
- `strategy_findings=2`, `strategy_low_confidence_findings=2`,
  `strategy_review_required_findings=0`.

PG-011 reconciliation:

- SELECT-only PostgreSQL checks and the PG-011 postcheck confirm the
  externally applied deck/rule state:
  `out_qty_in_target_deck=0`, `in_qty_in_target_deck=6`,
  `target_deck_qty=100`, `target_deck_rows=100`,
  `active_learned_deck_ok=1`.
- `Crawlspace=attack_limit`, `Ghostly Prison=attack_tax`, and
  `Get Lost=remove_creature` are curated/verified/auto in PostgreSQL; stale
  generated duplicates are deprecated/disabled.
- Runtime sync artifact:
  `sync_pg_target_deck_to_hermes_pg011_lorehold_defense_20260620_193849.json`
  with `apply=true`, deck id `6`, `cards_written=100`,
  `quantity_written=100`.
- Runtime cache artifact:
  `battle_card_rules_sqlite_from_pg_pg011_lorehold_defense_20260620_193849.json`
  with `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5230`, `sqlite_inserted_or_updated=5148`,
  `canonical_snapshot_rows_exported=3187`.
- Fresh learned-deck audit:
  `learned_deck_coherence_audit_20260620_224441.json`; Lorehold
  `learned_deck:82` remains `issues=[]`, `parsed_quantity=100`,
  `resolved_quantity=100`, and metadata records
  `lorehold_defense_variant_b_20260620`.
- Focused local validation after detecting the extra battle-source diffs:
  `python3 -m py_compile` over modified battle scripts exited `0`;
  `test_battle_forensic_audit_supported_effects.py` exited `0`;
  `test_battle_target_pressure_audit.py` exited `0`;
  `test_battle_analyst_v10_3.py` exited `0`.
- Additional `py_compile` for the source mapping files
  `battle_rule_registry.py`,
  `derive_functional_tags_from_battle_rules.py`, and
  `sync_pg_target_deck_to_hermes.py` exited `0`.

Classificacao:

- PG-011 esta observado como aplicado externamente e synced localmente; nao
  reexecutar apply.
- O current latest nao esta bloqueado, mas tambem nao e fully trusted por causa
  do residual low `Flame Wave`.
- Nao ha novo PostgreSQL apply autorizado por este heartbeat.

## Checkpoint Auditor Central - latest 221652 trusted - 2026-06-20 19:31 -0300

Escopo:

- Reconciliar o latest full `20260620_221652`, que supersede o `212035`.
- Registrar a evidencia local de runtime/tests para attack-limit, attack-tax e
  self-preservation combat handling.
- Nenhum PostgreSQL write, deck swap, cleanup, stage, commit, push, SQLite
  sync ou battle rerun foi executado por este heartbeat.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_221652/summary.json`.
- `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63212216`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `test_results_status_counts={"pass":18}`.
- Gates limpos: `action_critic`, `replay_decision_audit`,
  `strategy_audit`, `table_intent`, `target_pressure`, `effect_coverage`,
  `focused_template_dispatch`, `unknown_template_backlog`,
  `decision_trace_taxonomy` e `event_contract_static`.

Battle evidence:

- `forensic_rule_findings=0`, `forensic_turn_findings=0`.
- `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`.
- `table_intent_statuses={"pass":16}`.
- `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=190`,
  `target_pressure_opponent_combat_to_other=2`,
  `target_pressure_opponent_multi_defender_attack=0`.
- `strategy_findings=7`, `strategy_low_confidence_findings=7`,
  `strategy_review_required_findings=0`.

Source/test evidence:

- `battle_analyst_v9.py` contains the local runtime changes for
  `attack_limit` / `attack_tax`, defender attack restriction application, and
  Lorehold self-preservation attacker reservation.
- `battle_combat_tests.py` contains regressions for:
  `test_table_intent_target_reserves_blockers_when_under_pressure`,
  `test_table_intent_target_can_attack_with_vigilance_while_reserving_blockers`,
  `test_crawlspace_effect_limits_attackers_against_defender`, and
  `test_ghostly_prison_effect_taxes_attackers_against_defender`.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_combat_tests.py`
  exited `0`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  exited `0` with the new combat/runtime regressions passing.

Classificacao:

- Neste checkpoint, `212035` estava superseded pelo latest `221652`; depois,
  `224455` superseded `221652`.
- Nao ha pendencia real ativa de battle gate neste snapshot.
- PG-011 Lorehold defense variant foi detectado como pacote candidato
  untracked (`lorehold_defense_variant_pg011_*_20260620_193420.*`). Ele
  propoe swap de deck e writes em PostgreSQL; fica bloqueado por politica ate
  aprovacao explicita do comando de apply. Evidencia lida: baseline
  `20260620_221318` trusted, variante temp
  `/tmp/manaloom_lorehold_variant_b_mE2pHv/run_20260620_192657` com `3`
  vitorias Lorehold por linhas `Winner:`, `80` combates com restricoes,
  `52` atacantes restringidos e `192` de taxa paga.
- Nao ha apply PostgreSQL autorizado ou necessario por este heartbeat.

## Checkpoint Auditor Central - latest 212035 trusted - 2026-06-20 18:21 -0300

Escopo:

- Reconciliar o latest full `20260620_212035`, que supersede o `211648`.
- Classificar os novos artefatos externos `round8` e `round9`.
- Nenhum PostgreSQL write, deck swap, cleanup, stage, commit, push, SQLite
  sync ou battle rerun foi executado por este heartbeat.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/summary.json`.
- `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63212120`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `test_results_status_counts={"pass":18}`.
- Gates limpos: `action_critic`, `replay_decision_audit`, `strategy_audit`,
  `table_intent`, `target_pressure`, `effect_coverage`,
  `focused_template_dispatch`, `unknown_template_backlog`,
  `decision_trace_taxonomy` e `event_contract_static`.

Battle evidence:

- `forensic_rule_findings=0`, `forensic_turn_findings=0`.
- `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`.
- `table_intent_statuses={"pass":16}`.
- `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=214`,
  `target_pressure_opponent_combat_to_other=3`,
  `target_pressure_opponent_multi_defender_attack=2`.
- `strategy_findings=2`, `strategy_low_confidence_findings=2`,
  `strategy_review_required_findings=0`.

Round8/round9 reconciliados:

- `card_battle_rules_pg_table_intent_promotions_round8_20260620.json`
  declara `apply_pg=true`, `pg_inserted_or_updated=2`, selected cards
  `Practical Research` e `Tellah, Great Sage`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round8_20260620.json`
  declara `apply_sqlite_from_pg=true`, `pg_rows_loaded=5232`,
  `sqlite_inserted_or_updated=5150`, `canonical_snapshot_rows_exported=3187`.
- `card_battle_rules_pg_table_intent_promotions_round9_20260620.json`
  declara `apply_pg=true`, `pg_inserted_or_updated=2`, selected card
  `Breena, the Demagogue`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round9_20260620.json`
  declara `apply_sqlite_from_pg=true`, `pg_rows_loaded=5233`,
  `sqlite_inserted_or_updated=5151`, `canonical_snapshot_rows_exported=3187`.
- Este heartbeat detectou os artefatos e o latest verde, mas nao executou
  apply, sync ou rerun.

Classificacao:

- Os blockers/reviews `210513`, `211217` e `211648` estao superseded pelo
  latest full trusted `212035`.
- Nao ha pendencia real ativa de battle gate neste snapshot.
- Nao ha apply PostgreSQL autorizado ou necessario por este heartbeat.

## Checkpoint Auditor Central - latest 211648 forensic review residual - 2026-06-20 18:17 -0300

Escopo:

- Reconciliar o latest full `20260620_211648`, que supersede o `211217`.
- Classificar a pendencia remanescente como review residual low.
- Nenhum PostgreSQL write, deck swap, cleanup, stage, commit, push, SQLite
  sync ou battle rerun foi executado por este heartbeat.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_211648/summary.json`.
- `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63212116`.
- `battle_replay_final_status=review_required`.
- `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- `test_results_status_counts={"pass":18}`.
- Gates limpos: `action_critic`, `replay_decision_audit`, `strategy_audit`,
  `table_intent`, `target_pressure`, `effect_coverage`,
  `focused_template_dispatch`, `unknown_template_backlog`,
  `decision_trace_taxonomy` e `event_contract_static`.

Pendencia real restante:

- `forensic_rule_findings=2`, `forensic_turn_findings=0`,
  `forensic_severity_counts={"low":2}`.
- Seed `63212130`: `Breena, the Demagogue` de
  `Tayam, Luminous Enigma #25 (real)` tem runtime effect `passive` diferente
  do registry effect `draw_engine` em `spell_cast` e `spell_resolved`.
- A recomendacao do auditor e revisar apenas se o comportamento parecer errado
  no replay; por si so, isto e residual de oracle/registry normalization.

Target-pressure:

- `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=200`,
  `target_pressure_opponent_combat_to_other=0`,
  `target_pressure_opponent_multi_defender_attack=0`.
- O gate esta fechado no latest atual.

Classificacao:

- O blocker high/medium `Tellah, Great Sage` / `Practical Research` do
  `211217` foi superseded.
- O latest atual nao esta bloqueado; esta em review por dois achados low de
  registry/runtime drift.
- Nao ha apply PostgreSQL autorizado por este heartbeat; qualquer pacote futuro
  precisa de dry-run/precheck/rollback e aprovacao explicita do comando exato.

## Checkpoint Auditor Central - latest 211217 post-round7 forensic blocked - 2026-06-20 18:13 -0300

Escopo:

- Reconciliar o latest full `20260620_211217`, que supersede o `210513`
  depois dos artefatos `round7`.
- Classificar a evidencia pos-round7 sem atribuir execucao ao heartbeat.
- Nenhum PostgreSQL write, deck swap, cleanup, stage, commit, push, SQLite
  sync ou battle rerun foi executado por este heartbeat.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_211217/summary.json`.
- `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63212112`.
- `battle_replay_final_status=blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- `test_results_status_counts={"pass":18}`.
- Gates limpos: `action_critic`, `replay_decision_audit`, `strategy_audit`,
  `table_intent`, `target_pressure`, `effect_coverage`,
  `focused_template_dispatch`, `unknown_template_backlog`,
  `decision_trace_taxonomy` e `event_contract_static`.

Pendencia real restante:

- `forensic_rule_findings=4`, `forensic_turn_findings=0`.
- Seed `63212112`: `Tellah, Great Sage` de
  `The Emperor of Palamecia #42 (real)` usou lineage
  `functional_tags_json` para `draw_cards` em `spell_cast` e
  `spell_resolved`.
- Seed `63212123`: `Practical Research` de
  `The Emperor of Palamecia #42 (real)` usou lineage
  `functional_tags_json` para `draw_cards` em `spell_cast` e
  `spell_resolved`.

Target-pressure:

- `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=186`,
  `target_pressure_opponent_combat_to_other=3`,
  `target_pressure_opponent_multi_defender_attack=0`.
- O gate esta fechado no latest atual.

Round7 reconciliado:

- O `210513` tinha blockers em `Apex of Power`, `Arcane Endeavor`,
  `Curator's Ward`, `Magma Opus` e `The Unagi of Kyoshi Island`.
- O `round7` declara `apply_pg=true`, `pg_inserted_or_updated=6`,
  `selected_cards=["Apex of Power","Arcane Endeavor","Curator's Ward","Magma Opus","The Unagi of Kyoshi Island"]`.
- O sync pareado declara `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5230`, `sqlite_inserted_or_updated=5148` e
  `canonical_snapshot_rows_exported=3185`.
- O latest `211217` e a primeira evidencia pos-round7 observada neste
  heartbeat; ele remove o blocker anterior do current set, mas ainda bloqueia
  por novas cartas de oponente (`Tellah, Great Sage` e
  `Practical Research`).
- Este heartbeat nao executou apply, sync ou rerun.

Classificacao:

- O blocker ativo continua sendo curadoria/runtime de cartas de oponentes via
  `functional_tags_json`; nao e decklist Lorehold.
- Nao ha apply PostgreSQL autorizado por este heartbeat; qualquer pacote futuro
  precisa de dry-run/precheck/rollback e aprovacao explicita do comando exato.

## Checkpoint Auditor Central - latest 210513 forensic blocked - 2026-06-20 18:05 -0300

Escopo:

- Reconciliar o latest full `20260620_210513`, que supersede o `205821`.
- Classificar os novos artefatos `round6` detectados em
  `master_optimizer_reports`.
- Nenhum PostgreSQL write, deck swap, cleanup, stage, commit ou push foi
  executado por este heartbeat.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_210513/summary.json`.
- `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63212105`.
- `battle_replay_final_status=blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- `test_results_status_counts={"pass":18}`.
- Gates limpos: `action_critic`, `replay_decision_audit`, `strategy_audit`,
  `table_intent`, `target_pressure`, `effect_coverage`,
  `focused_template_dispatch`, `unknown_template_backlog`,
  `decision_trace_taxonomy` e `event_contract_static`.

Pendencia real restante:

- `forensic_rule_findings=11`, `forensic_turn_findings=0`.
- High/medium `functional_tags_json` lineage:
  `Arcane Endeavor`, `Curator's Ward`, `Magma Opus` e
  `The Unagi of Kyoshi Island`.
- Low registry/runtime drift:
  `Apex of Power` runtime effect `passive` difere do registry effect
  `draw_cards` em `spell_cast` e `spell_resolved`.

Target-pressure:

- `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=179`,
  `target_pressure_opponent_combat_to_other=5`,
  `target_pressure_opponent_multi_defender_attack=1`.
- O gate esta fechado no latest atual.

Round6 detectado:

- `card_battle_rules_pg_table_intent_promotions_round6_20260620.json`
  declara `apply_pg=true`, `pg_inserted_or_updated=2`,
  `selected_cards=["Goblin Bombardment"]`, `input_rows=2`,
  `curated_rows=1`, `generated_rows=1`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round6_20260620.json`
  declara `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5225`, `sqlite_inserted_or_updated=5143` e
  `canonical_snapshot_rows_exported=3181`.
- Este heartbeat nao executou o apply; os arquivos ficam classificados como
  evidencia detectada/sync, nao como autorizacao para reexecutar.

Classificacao:

- O `205821` review residual de `Goblin Bombardment` foi superseded por
  `210513`.
- O blocker ativo voltou a ser curadoria/runtime de cartas de oponentes via
  `functional_tags_json`; nao e decklist Lorehold.
- Nao ha apply PostgreSQL autorizado por este heartbeat; qualquer pacote futuro
  precisa de dry-run/precheck/rollback e aprovacao explicita do comando exato.

Round7 pos-latest:

- Depois do `210513`, foram detectados
  `card_battle_rules_pg_table_intent_promotions_round7_20260620.json` e
  `battle_card_rules_sqlite_from_pg_full_after_table_intent_round7_20260620.json`.
- O round7 declara `apply_pg=true`, `pg_inserted_or_updated=6`,
  `selected_cards=["Apex of Power","Arcane Endeavor","Curator's Ward","Magma Opus","The Unagi of Kyoshi Island"]`.
- O sync pareado declara `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5230`, `sqlite_inserted_or_updated=5148` e
  `canonical_snapshot_rows_exported=3185`.
- Recheck 20s depois manteve latest em `20260620_210513`; ainda nao existe
  battle rerun pos-round7.
- Este heartbeat nao executou apply, sync ou rerun.

## Checkpoint Auditor Central - latest 205821 forensic review residual - 2026-06-20 18:01 -0300

Escopo:

- Reconciliar o novo latest full `20260620_205821`.
- Classificar os novos artefatos `round5` detectados em
  `master_optimizer_reports`.
- Nenhum PostgreSQL write, deck swap, cleanup, stage, commit ou push foi
  executado por este heartbeat.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_205821/summary.json`.
- `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63212058`.
- `battle_replay_final_status=review_required`.
- `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- `test_results_status_counts={"pass":18}`.
- Gates limpos: `action_critic`, `replay_decision_audit`, `strategy_audit`,
  `table_intent`, `target_pressure`, `effect_coverage`,
  `focused_template_dispatch`, `unknown_template_backlog`,
  `decision_trace_taxonomy` e `event_contract_static`.

Pendencia real restante:

- `forensic_rule_findings=2`, `forensic_turn_findings=0`.
- Ambos os achados sao low severity no seed `63212068`:
  `Goblin Bombardment` runtime effect `passive` difere do registry effect
  `remove_creature` em `spell_cast` e `spell_resolved`.
- Classificacao: review residual de registry/runtime drift; nao e bloqueio de
  decklist Lorehold e nao justifica PostgreSQL apply sem pacote aprovado.

Target-pressure:

- `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=196`,
  `target_pressure_opponent_combat_to_other=3`,
  `target_pressure_opponent_multi_defender_attack=0`.
- O gate esta fechado no latest atual.

Round5 detectado:

- `card_battle_rules_pg_table_intent_promotions_round5_20260620.json`
  declara `apply_pg=true`, `pg_inserted_or_updated=3`,
  `selected_cards=["Big Score","Spelltwine"]`, `input_rows=3`,
  `curated_rows=2`, `generated_rows=1`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round5_20260620.json`
  declara `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5224`, `sqlite_inserted_or_updated=5142` e
  `canonical_snapshot_rows_exported=3181`.
- Este heartbeat nao executou o apply; os arquivos ficam classificados como
  evidencia detectada/sync, nao como autorizacao para reexecutar.

Classificacao:

- O blocker `target_pressure=blocked` do `204002` esta superseded.
- O blocker `forensic_audit=blocked` tambem esta superseded; agora resta apenas
  `forensic_audit=review_required`.
- Nao ha apply PostgreSQL autorizado; qualquer pacote futuro precisa de
  dry-run/precheck/rollback e aprovacao explicita do comando exato.

## Checkpoint Auditor Central - latest 204002 target-pressure mandatory - 2026-06-20 17:40 -0300

Escopo:

- Tratar o novo full `20260620_202211`, que tinha
  `event_contract_static=review_required`, `forensic_audit=blocked` e
  `replay_decision_audit=blocked`.
- Corrigir o wrapper local para que `target_pressure` entre explicitamente nos
  mandatory gates do `summary.json`.
- Nenhum PostgreSQL write, deck swap, cleanup, stage, commit ou push foi
  executado nesta tratativa.

Tratamento concluido:

- Reauditoria event-contract sobre `20260620_202211` com o codigo atual gravou
  `/tmp/event_contract_static_202211_current_code.*` e retornou
  `status=event_contract_static_ready`,
  `observed_unclassified_total=0`, `static_unclassified_total=0` e
  `static_fixture_unaccepted_types=[]`.
- O wrapper
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  agora lista `target_pressure` em
  `mandatory_gates_required_for_final_status` e em
  `mandatory_gate_statuses`.
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  passou.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --dry-run --seeds 16`
  saiu `0` e gerou o artefato latest `20260620_204002`.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_204002/summary.json`.
- `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63212040`.
- `battle_replay_final_status=blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked","target_pressure=blocked"]`.
- `mandatory_gates_required_for_final_status` agora inclui
  `target_pressure`.
- `test_results_status_counts={"pass":18}`.
- Gates limpos: `action_critic`, `replay_decision_audit`, `strategy_audit`,
  `table_intent`, `effect_coverage`, `focused_template_dispatch`,
  `unknown_template_backlog`, `decision_trace_taxonomy` e
  `event_contract_static`.

Pendencias reais restantes:

- Target-pressure:
  `target_pressure_statuses={"blocked":2,"pass":14}`,
  `target_pressure_findings=4`,
  `target_pressure_opponent_combat_to_target=188`,
  `target_pressure_opponent_combat_to_other=3`,
  `target_pressure_opponent_multi_defender_attack=1`.
- Target-pressure blocking seeds:
  `63212042`, `63212046`.
- Forensic:
  `forensic_rule_findings=21`, `forensic_turn_findings=0`,
  blocking seeds `63212042`, `63212047`, `63212048`, `63212050`.
- High/medium forensic lineage continua vindo de cartas de oponentes via
  `functional_tags_json`, incluindo `Electric Revelation`,
  `Rakdos, the Muscle`, `Fateful Showdown` e `Ur-Golem's Eye`.

Classificacao:

- `event_contract_static` e `replay_decision_audit` estao fechados no latest
  atual.
- O blocker restante e de curadoria/runtime de cartas de oponentes e de
  comportamento target-pressure, nao de decklist Lorehold.
- Nao ha apply PostgreSQL autorizado; qualquer pacote futuro precisa de
  dry-run/precheck/rollback e aprovacao explicita do comando exato.

## Checkpoint Auditor Central - latest 200409 full blockers - 2026-06-20 17:06 -0300

Escopo:

- Tratar o novo `latest` focado `20260620_200056`, que bloqueou
  target-pressure por metadado `table_intent_*`, e revalidar com novo focused
  e full rerun.
- Nenhum PostgreSQL write, deck swap, cleanup, stage, commit ou push foi
  executado nesta tratativa.

Tratamento concluido:

- `battle_target_pressure_audit.py` agora aceita `target_reason` com prefixo
  `table_intent_` como metadado valido quando
  `evaluation_target_active=true` e o defensor e `Lorehold`.
- `test_battle_target_pressure_audit.py` cobre
  `test_accepts_table_intent_target_reason_when_evaluation_target_is_active`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_target_pressure_audit.py`
  passou com `5` checks.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_target_pressure_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_target_pressure_audit.py`
  passou.
- Reauditoria direta de seed `63213000` gravada em
  `/tmp/lorehold_seed63213000_target_pressure_post_table_intent_metadata_fix.*`
  retornou `status=pass`, `opponent_combat_to_target=14`,
  `opponent_combat_to_other=0`,
  `opponent_combat_missing_pressure_reason=0`, e `findings=0`.
- Focused rerun
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_200322/summary.json`
  retornou `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `target_pressure_statuses={"pass":1}`,
  `forensic_rule_findings=0`, `decision_audit_turn_findings=0`,
  `action_findings=0`, e testes `18/18` pass.

Estado oficial full atual:

- Latest full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_200409/summary.json`.
- `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63212004`.
- `battle_replay_final_status=blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked","table_intent=blocked"]`.
- `test_results_status_counts={"pass":18}`.
- `action_findings=0`.
- `replay_decision_audit` esta limpo:
  `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`.
- Target-pressure tem `15/16` pass e `1/16` blocked:
  `target_pressure_findings=2`,
  `target_pressure_opponent_combat_total=172`,
  `target_pressure_opponent_combat_to_target=171`,
  `target_pressure_opponent_combat_to_other=1`,
  `target_pressure_opponent_multi_defender_attack=1`.

Pendencias reais restantes:

- Seed `63212012`: `Kinnan, Bonder Prodigy #104 (real)` fez
  `multi_defender_attack` no turno `9`, com grupos para `Lorehold` e
  `Tayam, Luminous Enigma #25 (real)`, gerando um combate de oponente contra
  outro defensor em run de avaliacao Lorehold.
- Forensic blockers:
  `Woodland Bellower` em seed `63212015` e
  `Shantotto, Tactician Magician` em seed `63212017`, ambos executando via
  `functional_tags_json`.
- Table-intent blockers:
  seeds `63212004`, `63212009`, e `63212019`, todos com
  `opponent_interaction_absent`.

Classificacao:

- A pendencia resolvida neste heartbeat era bug de auditoria/instrumentacao
  para `table_intent_*`, nao composicao do deck Lorehold.
- As pendencias restantes sao battle runtime/curadoria de regra e modelo de
  comportamento de oponente; nao justificam PostgreSQL apply sem pacote
  dry-run/precheck/rollback explicitamente aprovado.

## Checkpoint Auditor Central - latest 195007 forensic blockers - 2026-06-20 16:50 -0300

Escopo:

- Rerodar o full recurring battle audit depois da correcao do
  `Goblin Bombardment` `review_only` e da correcao do falso positivo de
  target-pressure pos-morte do alvo.
- Nenhum PostgreSQL write, deck swap, cleanup, stage, commit ou push foi
  executado nesta tratativa.

Estado oficial atual:

- Latest:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_195007/summary.json`.
- `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63211944`.
- `battle_replay_final_status=blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked","replay_decision_audit=review_required"]`.
- `test_results_total=17`, `test_results_status_counts={"pass":17}`.
- `action_findings=0`.
- Target-pressure esta limpo:
  `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_total=193`,
  `target_pressure_opponent_combat_to_target=193`,
  `target_pressure_opponent_combat_to_other=0`,
  `target_pressure_opponent_multi_defender_attack=0`.

Tratamento concluido:

- `battle_target_pressure_audit.py` agora ignora combates de oponentes depois
  que `Lorehold` ja foi eliminado.
- `test_battle_target_pressure_audit.py` cobre
  `test_ignores_opponent_combat_after_lorehold_is_eliminated`.
- A revalidacao focada do seed `63211952` retornou `status=pass`,
  `target_player_eliminated=true`,
  `post_target_elimination_opponent_combat_ignored=1`,
  `opponent_combat_to_target=10` e `opponent_combat_to_other=0`.
- O full rerun `20260620_195007` confirma target-pressure pass `16/16`.

Pendencias reais restantes:

- `forensic_audit` segue `blocked` com `forensic_rule_findings=26` e
  `forensic_turn_findings=1`.
- Seeds blocking: `63211954` e `63211958`.
- High forensic findings por `functional_tags_json`:
  `Abandon Attachments`, `Channeled Force` e `Hypothesizzle`.
- Medium forensic lineage recorrente:
  `The Emperor of Palamecia`, `Firemind Vessel`,
  `Sisay, Weatherlight Captain` e `Kraum, Ludevic's Opus`.
- Low review/passive mismatches:
  `Laughing Mad`, `Shark Typhoon`, `One with the Multiverse` e
  `Stonespeaker Crystal`.
- `replay_decision_audit` segue `review_required` por uma pendencia low:
  seed `63211944`, turn `7`, `board_wipe_resolved`,
  `Board wipe left more protected creatures (5) than destroyed (4).`

Classificacao:

- A pendencia restante e de curadoria de `card_battle_rules`/dados para cartas
  de oponentes learned, nao de decklist Lorehold, target-pressure, action
  critic ou bug `review_only` do Goblin.
- Sem aprovacao explicita de pacote PostgreSQL, o proximo passo seguro e
  preparar pacote dry-run/precheck/rollback para as cartas acima ou revisar se
  alguma deve virar waiver runtime; nao aplicar.

## Checkpoint Auditor Central - review-only canonical snapshot suppression - 2026-06-20 16:30 -0300

Escopo:

- Tratar o novo `latest` oficial
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_191248/summary.json`.
- Separar defeito de runtime de qualquer evidencia de rollback PostgreSQL,
  deck swap ou nova pendencia real no deck Lorehold.
- Nenhum PostgreSQL write, deck swap, cleanup, stage, commit ou push foi
  executado nesta tratativa.

Estado observado no `latest`:

- `battle_replay_final_status=blocked`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`.
- `mandatory_gate_divergences=["action_critic=review_required","forensic_audit=blocked","replay_decision_audit=review_required"]`.
- `forensic_rule_findings=2`, `action_findings=2`,
  `decision_audit_decision_findings=1`.
- `test_results_total=17`, `test_results_status_counts={"pass":17}`.
- `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=84`,
  `target_pressure_opponent_combat_to_other=0`.

Blocker real:

- Seed `63211917`.
- `Goblin Bombardment`, controlado por `Dargo, the Shipwrecker #74 (real)`,
  entrou no runtime como `remove_creature` a partir de
  `known_cards_canonical_snapshot`.
- A regra local em `battle_card_rules`/snapshot tem
  `review_status=needs_review` e `execution_status=review_only`; logo ela
  deve ser auditavel, mas nao executavel como remocao.

Mudanca feita:

- `battle_analyst_v9.py` passou a suprimir regras de snapshot canonico que nao
  sejam runtime-safe em um efeito `passive`, preservando a proveniencia com
  `battle_model_scope=canonical_snapshot_rule_not_runtime_safe`.
- `battle_card_specific_tests.py` ganhou
  `test_goblin_bombardment_review_only_snapshot_does_not_remove_on_cast`,
  cobrindo que `Goblin Bombardment` `review_only` nao emite
  `removal_resolved` nem remove `Lorehold, the Historian`.

Evidencia:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passou, incluindo a nova regressao.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_target_pressure_audit.py`
  passou.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passou.
- Replay/auditores focados em `/tmp/lorehold_seed63211917_post_review_only_fix.*`
  retornaram `action_findings=0`, `forensic rule_findings=0`,
  `forensic turn_findings=0`, `decision_findings=0` e
  `decision turn_findings=0`.
- Artefatos locais auxiliares
  `docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_20260620_192955.md`
  e
  `docs/hermes-analysis/master_optimizer_reports/master_optimizer_replay_audit_20260620_192955.md`
  nao sao novo `summary.json` oficial; eles mostram forensic limpo no replay
  auditado e uma pendencia baixa de decision trace em outro seed.

Conclusao operacional:

- O defeito de runtime foi tratado localmente.
- O `latest` oficial ainda deve ser considerado `blocked` ate um novo full
  recurring rerun substituir `20260620_191248`.
- Nao ha evidencia nova que autorize PostgreSQL apply ou deck swap.

## Checkpoint Auditor Central - table intent / opponent effectiveness study - 2026-06-20 16:24 -0300

Escopo:

- Estudar a objecao de Rafael sobre intencao real de defesa/ameaca: se
  Lorehold ataca, remove permanente, monta Approach/combo ou passa a frente,
  ele pode virar nemesis/foco de um jogador ou da mesa.
- Separar regra oficial de combate de heuristica politica de Commander.
- Medir se as cartas dos oponentes realmente estao executando algo.
- Nenhum PostgreSQL write, deck swap, cleanup, stage, commit ou push foi
  executado nesta tratativa.

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_table_intent_and_opponent_effectiveness_audit_20260620.md`.

Fontes:

- Wizards rules page: `https://magic.wizards.com/en/rules`.
- Comprehensive Rules TXT:
  `https://media.wizards.com/2026/downloads/MagicCompRules%2020260417.txt`.
- Latest battle:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_185748/summary.json`.
- Eventos estruturados por seed em
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_185748/seed_*/replay.events.jsonl`.

Leitura de regra:

- A regra oficial define atacantes, defensores e bloqueadores legais.
- Ela nao define "intencao politica" de jogadores.
- Em Commander real, a intencao precisa ser modelada por IA: vinganca,
  auto-preservacao, ameaca de mesa, combo iminente e oportunidade de matar.

Evidencia de funcionamento dos oponentes:

- Oponentes tiveram `106` `spell_cast`, `51` `creature_cast`, `33`
  `spell_resolved`, `117` combates, `44` triggers resolvidos, `3` removals
  resolvidos, `7` counters e `5/16` vitorias no latest.
- Interacoes reais observadas incluem `Mental Misstep`/`An Offer You Can't
  Refuse` contra `Silence`, `Flusterstorm` contra `The One Ring`,
  `Pact of Negation` contra `Twinflame`, `Flusterstorm` contra
  `Mizzix's Mastery` e `Blasphemous Act`, `Chain of Vapor` em mana rocks de
  Lorehold, e `Swords to Plowshares` em token de Lorehold.

Red flags:

- `target_pressure` e um stress-test limpo, mas ainda nao e um modelo politico
  real de Commander.
- `target_pressure_opponent_combat_to_target=117` e
  `target_pressure_opponent_combat_to_other=0` provam foco em Lorehold, mas
  tambem mostram que o modo esta rigido demais para representar mesa real.
- `cast_illegal` dos oponentes foi `648`; principais repeticoes:
  `Kinnan, Bonder Prodigy=129`, `Thrasios, Triton Hero=107`,
  `Tayam, Luminous Enigma=95`, `Etali, Primal Conqueror=38`,
  `Rograkh, Son of Rohgahh=37`.
- Bloqueios totais em `263` eventos de combate foram apenas `16`.

Conclusao operacional:

- E falso dizer que as cartas dos oponentes nao fazem nada.
- Tambem e falso dizer que o battle ja representa uma mesa Commander real.
- O WR atual de Lorehold deve ser tratado como evidencia sob stress-test, nao
  como prova final de que o deck e o melhor.
- Proxima correcao antes de novos swaps: criar camada `table_intent` com
  memoria de nemesis por jogador, score de ameaca de mesa, auto-preservacao,
  oportunidade de lethal e auditor de efetividade dos oponentes.

## Checkpoint Auditor Central - target-pressure battle validation - 2026-06-20 16:00 -0300

Escopo:

- Corrigir a falha metodologica apontada por Rafael: a avaliacao do deck
  Lorehold nao pode deixar os tres oponentes se baterem enquanto Lorehold
  executa o proprio plano sem pressao real.
- Transformar `Lorehold` em alvo de avaliacao sob pressao nas simulacoes de
  battle usadas para estrategia.
- Nenhum PostgreSQL write, deck swap, cleanup, stage, commit ou push foi
  executado nesta tratativa.

Mudancas de runtime/auditoria:

- `battle_analyst_v9.py` agora aceita
  `MANALOOM_BATTLE_EVALUATION_TARGET_PLAYER`, default `Lorehold`, e direciona
  ataques/removals dos oponentes para o alvo de avaliacao quando ele esta vivo.
- `battle_replay_v10_3.py` para o replay quando Lorehold morre, evitando que
  combates posteriores entre oponentes sejam lidos como evidencia de
  estrategia do deck avaliado.
- `master_optimizer_common.py` passa o alvo de avaliacao para as batalhas do
  otimizador.
- `battle_target_pressure_audit.py` e
  `test_battle_target_pressure_audit.py` foram adicionados como gate de
  auditoria recorrente.
- O wrapper local
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  agora roda o target-pressure audit por seed e agrega o resultado como
  mandatory gate `target_pressure`.

Evidencia principal:

- Latest battle vivo:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_185748/summary.json`.
- `latest` aponta para esse run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `mandatory_gates_required_for_final_status` inclui
  `target_pressure`.
- `target_pressure_statuses={"pass":16}`.
- `target_pressure_findings=0`.
- `target_pressure_opponent_combat_total=117`.
- `target_pressure_opponent_combat_to_target=117`.
- `target_pressure_opponent_combat_to_other=0`.
- `target_pressure_opponent_multi_defender_attack=0`.
- `action_findings=0`, `forensic_rule_findings=0`,
  `forensic_turn_findings=0`, `decision_audit_turn_findings=0`, e
  `decision_audit_decision_findings=0`.
- `test_results_total=17`,
  `test_results_status_counts={"pass":17}`.
- Runtime surface manifest atualizado:
  `runtime_surface_manifest_total_files=112`,
  `recurring audit gate=26`, `covered_by_recurring_run=31`, e
  `recurring_audit_required=31`.

Evidencia de replay inspectavel:

- Replay manual:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_target_pressure_replay_20260620_153647.txt`.
- Eventos:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_target_pressure_replay_20260620_153647.events.jsonl`.
- Auditor target-pressure:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_target_pressure_replay_20260620_153647.target_pressure.json`.
- Resultado do auditor nesse replay: `opponent_combat_total=14`,
  `opponent_combat_to_target=14`, `opponent_combat_to_other=0`,
  `opponent_multi_defender_attack=0`, `findings=0`.
- O replay terminou com `WIN: Lorehold (elimination) turn 14`, mas essa vitoria
  passa a ser evidenciada sob pressao direta de combate dos oponentes.

Leitura operacional:

- WR ou baseline gerado antes desta correcao nao deve ser usado como prova de
  otimalidade do deck, porque podia incluir jogos em que Lorehold nao era
  pressionado como alvo real.
- A partir deste checkpoint, qualquer revisao de deck Lorehold para swap,
  baseline ou strategy learning deve exigir o mandatory gate
  `target_pressure` limpo no latest full run.
- A simulacao sob pressao reduziu a leitura operacional do smoke de battle para
  `83.3% (10W/2L/0S)` no run agregado manual, tornando o resultado mais
  plausivel para avaliacao do deck do que o snapshot anterior sem essa pressao.

## Checkpoint Auditor Central - PG-008 Machine God's Effigy - 2026-06-20T15:16Z

Estado atual verificado:

- Latest battle vivo:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_151437/summary.json`.
- Resultado: `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `test_results_total=16`, `test_results_status_counts={"pass":16}`.
- Runtime counts: `execution_status_counts={"auto":1704,"review_only":1457}`.

Tratativa fechada:

- O latest anterior
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_150241/summary.json`
  entrou em `review_required` por `forensic_audit=review_required`.
- O blocker era `Machine God's Effigy`, seed `63211509`, turno `10`, evento
  `spell_cast`, efeito `ramp_permanent`, fonte `functional_tags_json`; o auditor
  recomendou mover a carta para `card_battle_rules` com status
  `verified/active`.
- PostgreSQL precheck PG-008 confirmou: carta alvo `1`, regra alvo existente
  `0`, qualquer regra para a carta `0`, snapshot antes `battle_rules=[]`,
  `battle_rule_count=0`, `function_tags={ramp}`.
- PG-008 aplicado: `INSERT 0 1`, `COMMIT`.
- Postcheck PG-008: `pg008_target_rule_count=1`; snapshot passou a expor a
  regra em `battle_rules`; backup rows `0`.
- Sync PG -> SQLite:
  `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_1210_post_pg008.json`
  com `pg_rows_loaded=5190`, `sqlite_inserted_or_updated=5108`,
  `canonical_snapshot_rows_exported=3161`.
- Backup SQLite:
  `docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg008-runtime-sync.20260620_1210.bak`.

Conclusao operacional: PG-008 fecha o blocker de lineage do latest `150241`.
Nao houve deck swap, commit, push ou deploy de codigo nesta tratativa.

## Checkpoint Auditor Central - publication batch validation - 2026-06-20T15:54Z

Estado atual verificado:

- Latest battle vivo:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_155445/summary.json`.
- Invocation kind: `manual_publication_batch_validation`.
- Resultado: `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `test_results_total=16`, `test_results_status_counts={"pass":16}`.
- Runtime counts: `execution_status_counts={"auto":1704,"review_only":1457}`.

Validacoes relacionadas:

- Fresh battle audit executado com `--seeds 16` e exit `0`.
- `test_battle_runtime_surface_manifest.py`: `PASS`.
- PG-008 postcheck read-only manteve `pg008_target_rule_count=1`.
- Migracoes seguem `29/29` executadas e `0` pendentes.

Conclusao operacional: battle segue confiavel para strategy learning depois da
validacao de lotes de publicacao. Nao houve novo PostgreSQL write, deck swap,
commit, push ou deploy de codigo neste checkpoint.

## Artefato base desta rodada

- Run manual: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/manual-battle-simulation/20260619_135854/`
- Seed: `786135854`
- Log humano: `replay.txt`
- Eventos estruturados: `replay.events.jsonl`
- Decision trace: `replay.decision_trace.jsonl`
- Action critic desta rodada: `action_critic.json`
- Strategy audit desta rodada: `strategy_audit.json`

Resultado dos auditores atuais:

- `battle_action_critic`: `0` findings, `462` acoes `ok`.
- `battle_decision_strategy_auditor`: `0` findings, verdict
  `usable_for_strategy_learning`.

Conclusao desta rodada: o pipeline atual aprova o replay, mas a inspecao manual
achou lacunas de observabilidade e pelo menos um caso que deveria ser validado
com mais rigor antes de confiar em aprendizagem automatica.

## Passo de auditoria - latest 2026-06-19T14:29:35Z

Artefato principal monitorado:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`

Resumo verificado:

- `action_findings`: `0`
- `strategy_findings`: `1`
- `strategy_severity_counts`: `{"medium": 1}`
- `strategy_code_counts`: `{"forced_keep_after_bad_mulligan": 1}`
- `research_statuses.mulligan`: `blocked_or_needs_review`

Seed com finding:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63201430/`

Observacao critica: o auditor marcou `decision-000012` como
`forced_keep_after_bad_mulligan`, mas nao marcou `decision-000004`, que tambem
foi keep forcado apos mulligan cap, com `risk_flags=["mana_screw",
"forced_keep_after_mulligan_cap"]`, `reason="too_few_lands"`, `lands=1` e
`score=-7.0`.

Testes executados nesta rodada:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py` - PASS

## Passo de auditoria - effect coverage 2026-06-19T15:18Z

Artefatos gerados:

- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_151817.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_151817.json`

Comando executado:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py --report`

Resumo verificado:

- `opponents_loaded`: `12`
- `total_card_instances`: `1288`
- `unique_cards`: `556`
- source totals:
  - `battle_rule_curated`: `724`
  - `type_land`: `377`
  - `effect_map`: `100`
  - `battle_rule_generated`: `34`
  - `unknown`: `33`
  - `tag`: `20`
- risk flags:
  - `unknown_effect`: `33`
  - `heuristic_effect`: `154`
  - `trigger_not_explicit`: `147`
  - `cast_permission_not_explicit`: `89`
  - `temporary_effect_not_explicit`: `65`
  - `land_utility_ability_not_modeled`: `48`
  - `oracle_target_removal_mismatch`: `20`
  - `oracle_silence_mismatch`: `15`
  - `copy_effect_mismatch`: `1`

Inventario SQLite local:

- `knowledge.db` tem `3683` rows em `battle_card_rules`, `3159` nomes distintos
  e `52` efeitos distintos.
- `battle_rules.db` existe, mas tem `0B`; o cache real usado nesta rodada foi
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`.
- Existem `1981` rows `generated / needs_review / auto`, incluindo:
  `draw_cards=403`, `ramp_permanent=225`, `token_maker=200`,
  `draw_engine=149`, `remove_creature=83`, `remove_permanent=77`,
  `board_wipe=71`, `counter=46` e `unknown=10`.

Leitura operacional: os templates ja cobrem varias familias simples, mas o
coverage real contra Lorehold + 12 decks oponentes ainda nao permite afirmar
que todos os templates de acao de carta estao criados ou seguros.

Testes executados nesta etapa:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_alternatives.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_runtime_pg_rule_fallback_for_promoted_hotfixes.py` - PASS

## Passo de auditoria - unknown template triage 2026-06-19T15:23Z

Fonte:

- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_151817.json`
- `server/bin/manaloom_battle_rule_review_queue.py`
- `server/bin/manaloom_battle_rule_focused_evidence.py`

Classificacao dos `29` cards em `unknown_cards` por familia aproximada:

| Familia | Qtde | Exemplos |
| --- | ---: | --- |
| `alternative_or_additional_cost` | 6 | `Flash Photography`, `Kindle the Inner Flame`, `Submerge`, `Firestorm`, `Mine Collapse`, `Stoke the Flames` |
| `impulse_topdeck_or_library_zone` | 5 | `Heroes' Hangout`, `Opera Love Song`, `Submerge`, `Codex Shredder`, `Cryptic Coat` |
| `counter_manipulation` | 4 | `Ashnod's Transmogrant`, `Clown Car`, `Out of Time`, `Reality Acid` |
| `damage_with_special_cost_or_targeting` | 4 | `Firestorm`, `Mine Collapse`, `Stoke the Flames`, `Sudden Shock` |
| `manifest_cloak_face_down` | 4 | `Cryptic Coat`, `Cursed Windbreaker`, `Dissection Tools`, `Scroll of Fate` |
| `copy_permanent_or_creature_token` | 3 | `Flash Photography`, `Kindle the Inner Flame`, `Copy Artifact` |
| `static_tax_or_cast_restriction` | 3 | `God-Pharaoh's Statue`, `Power Artifact`, `Thorn of Amethyst` |
| `tap_untap_target` | 2 | `Hidden Strings`, `Candelabra of Tawnos` |
| `type_or_copy_continuous_effect` | 2 | `Liquimetal Coating`, `Ashnod's Transmogrant` |
| outras familias unitarias | 8 | `bounce_or_return_to_hand`, `cipher_encoded_trigger`, `convoke_cost_payment`, `modal_mass_sacrifice_selection`, `phase_out_duration_linked`, `split_second_priority_lock`, `mill`, `manual_review` |

Checagem da inferencia textual atual:

- `infer_effect_families_from_text(...)` encontrou familia para apenas `5/29`
  cards:
  - `copy_spell_or_permanent`: `Flash Photography`, `Kindle the Inner Flame`
  - `graveyard_recast_replacement`: `Flash Photography`, `Kindle the Inner Flame`
  - `counter_manipulation`: `Ashnod's Transmogrant`, `Clown Car`
  - `targeted_interaction`: `Mine Collapse`
- `24/29` nao tiveram familia inferida pela leitura textual direta, incluindo
  `Banishing Knack`, `Heroes' Hangout`, `Submerge`, `God-Pharaoh's Statue`,
  `Nevermore`, `Out of Time`, `Power Artifact`, `Stoke the Flames`,
  `Sudden Shock`, `Thorn of Amethyst` e `Tragic Arrogance`.

Templates com focused evidence suportado hoje sao estreitos:

- `Counter target spell.`
- `Destroy/Exile target ...` simples para creature/nonland permanent/artifact/
  enchantment/artifact-or-enchantment;
- `Destroy all creatures.`
- `Creatures you control gain indestructible until end of turn.`
- `Create a Treasure token.`
- `Draw a card.`, `Draw two cards.`, `Draw three cards.`
- `Return target creature/artifact/enchantment/artifact-or-enchantment card
  from your graveyard to your hand.`
- `sacrifice creature -> damage`, `extra combat + flashback`,
  `attack trigger + Treasure + artifact tutor`.

Teste executado nesta etapa:

- `python3 server/test/manaloom_review_queue_consumers_test.py` - PASS

## Passo de auditoria - forensic/manual 2026-06-19T15:27Z

Artefatos gerados:

- `docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_20260619_152725.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_forensic_manual_20260619_135854.json`
- `docs/hermes-analysis/master_optimizer_reports/master_optimizer_replay_audit_20260619_152807.md`

Comandos executados:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py --events /Users/desenvolvimentomobile/.manaloom-agents/artifacts/manual-battle-simulation/20260619_135854/replay.events.jsonl --report --json-report docs/hermes-analysis/master_optimizer_reports/battle_forensic_manual_20260619_135854.json`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py --skip-baseline --events /Users/desenvolvimentomobile/.manaloom-agents/artifacts/manual-battle-simulation/20260619_135854/replay.events.jsonl --decision-trace /Users/desenvolvimentomobile/.manaloom-agents/artifacts/manual-battle-simulation/20260619_135854/replay.decision_trace.jsonl --require-decision-trace --report`

Resultado cruzado sobre o mesmo replay manual:

- `battle_action_critic`: limpo na rodada manual anterior.
- `battle_decision_strategy_auditor`: limpo na rodada manual anterior.
- `replay_decision_auditor`: `status=turn_by_turn_clean`,
  `turn_findings=0`, `decision_findings=0`, `decision_traces=146`.
- `battle_forensic_audit`: `status=blocked`, `findings_total=10`,
  `critical=10`.

Todos os `critical` do forensic sao de:

- card: `Birgi, God of Storytelling // Harnfel, Horn of Bounty`
- evento: `trigger_resolved`
- efeito: `add_mana`
- finding: `Effect add_mana is not implemented by the active battle engine.`

Checagem de codigo local:

- `battle_analyst_v9.py` emite `trigger_resolved` com `effect="add_mana"`,
  `mana_added`, `mana_color` e `mana_pool`.
- `battle_card_specific_tests.py` tem teste especifico confirmando que Birgi
  adiciona mana vermelha e emite `effect="add_mana"`.
- `battle_forensic_audit.py` nao inclui `add_mana` em `SUPPORTED_EFFECTS`.

Leitura operacional: a falha pode ser falso positivo do auditor forense por
lista de efeitos desatualizada, mas o efeito pratico e grave: um gate retorna
`blocked/critical` enquanto os outros gates dizem que o replay esta limpo.

## Passo de auditoria - current seed rerun 2026-06-19T15:31Z

Artefato gerado fora do repo:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_current_seed786135854_153131/`

Objetivo: reexecutar a mesma seed `786135854` contra o estado atual do
workspace, que contem alteracoes battle ainda nao commitadas, para medir se os
problemas do replay manual antigo foram realmente corrigidos nos artefatos.

Comandos/validacoes executados:

- `battle_replay_v10_3.py` com `REPLAY_SEED=786135854`
- `battle_action_critic.py` sobre o novo `replay.events.jsonl`
- `battle_decision_strategy_auditor.py` sobre o novo par
  `events/decision_trace`
- `replay_decision_auditor.py --skip-baseline --require-decision-trace`
- `battle_forensic_audit.py --events`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` - PASS
- `python3 -m py_compile ...battle*.py replay_decision_auditor.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py` - FAIL

Resultados do replay atual:

- `replay.txt` agora mostra `PLAY LAND`, `PAY COST`, `ILLEGAL CAST` e snapshot
  de permanentes no fim do turno.
- O caso antigo de `Mental Misstep` melhorou: agora aparece como
  `spell_countered` com `target=Esper Sentinel`, `stack_object=Esper Sentinel`
  e `result=countered`.
- `action_critic.json`: `findings=2`, `verdict_counts={"high": 1, "ok": 472}`.
- `strategy_audit.json`: `findings=0`, `verdict=usable_for_strategy_learning`.
- `forensic_audit.json`: segue com `10` criticals de `Birgi/add_mana`.

Novo finding alto do action critic:

- Turno `8`, carta `Pyroblast`, evento `spell_resolved`, efeito `counter`.
- Codigos:
  - `counter_without_stack_target`
  - `counter_resolved_as_normal_spell`
- Evidencia: `Pyroblast` foi escolhido pelo topdeck/miracle path e entrou como
  `miracle_cast`, mas depois resolveu como spell normal sem alvo/stack object.

Falha da suite principal:

- `test_battle_analyst_v10_3.py` falha em
  `test_warp_exiles_at_end_step_then_recasts_from_exile`.
- Sequencia observada no cenario isolado:
  `cast_announced`, `cost_paid`, `warp_cast`, `warp_exiled_end_step`,
  `cast_announced`, `cost_paid`, `warp_recast_from_exile`.
- Sequencia esperada pelo teste atual:
  `cast_announced`, `warp_cast`, `warp_exiled_end_step`, `cast_announced`,
  `warp_recast_from_exile`.
- Leitura: a instrumentacao nova de `cost_paid` melhorou observabilidade, mas
  quebrou expectativa de teste que contava eventos exatos.

Lacuna residual no replay textual:

- O replay novo mostra `TRIGGER ... event=? stack=?` em `32` linhas.
- O JSONL correspondente tem `trigger_put_on_stack` com campos `card`,
  `trigger` e `timestamp`, mas o renderer procura `source`, `trigger_event` e
  `stack_depth`.
- Alem disso, ha `trigger_put_on_stack` `trigger=landfall` para land drops
  comuns como `Sunbillow Verge`, `Dryad Arbor`, `Scrubland`, `Breeding Pool`,
  `Battlefield Forge`, etc.
- Pelo codigo atual, `trigger_landfall(...)` chama `resolve_or_enqueue_trigger`
  mesmo antes de saber se existe algum permanente com landfall que produziria
  efeito real.

## Passo de auditoria - current state revalidation 2026-06-19T15:37Z

Artefato gerado fora do repo:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_current_seed786135854_postfix_153704/`

Artefatos de coverage runtime-safe:

- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_153722_runtime_safe.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_153722_runtime_safe.json`

Testes/revalidacoes executadas neste ponto:

- `python3 -m py_compile battle_analyst_v9.py battle_replay_v10_3.py battle_action_critic.py battle_decision_strategy_auditor.py battle_effect_coverage_audit.py battle_rule_registry.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_registry_runtime_safe.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py` - PASS

Leitura do rerun da seed `786135854`:

- `action_critic.json`: `findings=2`, `verdict_counts={"high": 1, "ok": 472}`.
- `strategy_audit.json`: `findings=0`, `verdict=usable_for_strategy_learning`.
- `forensic_audit.json`: `rule_findings=10`, todos `critical`, todos em
  `Birgi, God of Storytelling // Harnfel, Horn of Bounty` com `effect=add_mana`.
- Eventos relevantes: `cost_paid=30`, `miracle_cast=2`, `spell_countered=1`,
  `spell_resolved=20`, `trigger_put_on_stack=32`.
- O replay textual ainda tem `32` linhas `TRIGGER ... event=? stack=?`.
- O caso de `Pyroblast` ainda persiste:
  - `CAST Lorehold: Pyroblast (CMC=?) [counter] phase=upkeep cost={} rule=curated/verified`
  - `RESOLVE SPELL Lorehold: Pyroblast (CMC=1.0) [counter] rule=curated/verified`

Leitura do coverage runtime-safe:

- `opponents_loaded`: `12`
- `total_card_instances`: `1288`
- `unique_cards`: `556`
- `runtime_safe_rule_names`: `1702`
- `active_or_review_rule_names`: `3159`
- `review_only_rule_names`: `1457`
- source totals:
  - `battle_rule_curated`: `724`
  - `battle_rule_review_only_generated`: `34`
  - `effect_map`: `100`
  - `tag`: `20`
  - `type_land`: `377`
  - `unknown`: `33`
- risk flags:
  - `unknown_effect`: `33`
  - `heuristic_effect`: `120`
  - `trigger_not_explicit`: `147`
  - `cast_permission_not_explicit`: `89`
  - `temporary_effect_not_explicit`: `65`
  - `land_utility_ability_not_modeled`: `48`
  - `review_only_rule`: `34`
  - `oracle_target_removal_mismatch`: `20`
  - `oracle_silence_mismatch`: `15`
  - `copy_effect_mismatch`: `1`

Leitura operacional atual:

- A suite principal voltou a ficar verde; o bloqueio de teste de `cost_paid`
  deve ser tratado como historico fechado parcialmente, nao como blocker atual.
- O rerun ainda exige notificacao: existe `high` no action critic para
  `Pyroblast` e existem `critical` no forensic para `Birgi/add_mana`.
- O coverage agora separa runtime-safe de review-only. Isso melhora a leitura,
  mas revela que `1457/3159` nomes ativos/review estao fora do conjunto
  runtime-safe e que `34` instancias do corpus ainda dependem de regra
  review-only/generated.

## Tratativas fechadas - 2026-06-19T15:38:03Z

Artefato principal validado:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_153803/`
- `latest/summary.json` timestamp: `2026-06-19T15:38:03Z`

Resumo evidenciado:

- `seeds_completed`: `1`
- `action_findings`: `0`
- `strategy_findings`: `2`
- `strategy_code_counts`: `{"forced_keep_after_bad_mulligan": 2}`
- `effect_coverage_unknowns`: `33`
- `heuristic_effects`: `120`
- `trigger_not_explicit`: `147`
- `cast_permission_not_explicit`: `89`
- `land_utility_ability_not_modeled`: `48`
- `runtime_safe_rule_names`: `1702`
- `review_only_rule_names`: `1457`
- `effect_coverage_report`:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_153803/effect_coverage.md`

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-001`, `BV-004`, `BV-006`, `BV-007`, `BV-008`: o replay humano passou a
  renderizar `PLAY LAND`, `PAY COST`, `ILLEGAL CAST`, diferenciacao entre
  `CAST`/`RESOLVE SPELL`/`RESOLVE ABILITY`/`ACTIVATE` e snapshot de
  permanentes em `END`.
- `BV-002`, `BV-003`: o caso original de `Mental Misstep` passou a registrar
  `spell_countered` com `target`, `stack_object` e `result=countered`, e o
  `battle_action_critic` agora bloqueia counter sem alvo/stack object ou
  counter resolvido como spell normal. A classe remanescente via
  miracle/topdeck segue aberta em `BV-021`.
- `BV-010`: a seed `63201430` agora gera finding para `decision-000004` e
  `decision-000012`, ambos `forced_keep_after_bad_mulligan`.
- `BV-012`: a automacao principal agora executa coverage audit e inclui no
  `summary.json` os campos de coverage e link do report.
- `BV-013`: o registry e o coverage audit passaram a separar runtime-safe de
  review-only; o risco residual de consumers/summaries fica consolidado em
  `BV-025`.
- `BV-024`: `cost_paid` ficou coberto como evento esperado nas sequencias de
  cast/warp/recast e a suite principal voltou a `PASS`.

Validacoes executadas e aprovadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_registry_runtime_safe.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_alternatives.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_runtime_pg_rule_fallback_for_promoted_hotfixes.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --dry-run --seeds 1`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 63201430`

## Passo de auditoria - latest automation extra gates 2026-06-19T15:43Z

Artefatos gerados:

- `docs/hermes-analysis/master_optimizer_reports/battle_flow_inventory_audit_20260619_154320.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_latest_seed63201430_forensic_124320/`

Objetivo: cruzar a automacao latest com os gates que ela ainda nao executa no
`summary.json` principal.

Latest automatizado monitorado:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- run dir real: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_153803`
- seed: `63201430`
- `action_findings`: `0`
- `strategy_findings`: `2`
- `strategy_severity_counts`: `{"medium": 2}`
- `strategy_code_counts`: `{"forced_keep_after_bad_mulligan": 2}`
- `seeds_with_high_or_critical_action_findings`: `[]`
- `seeds_with_strategy_blockers`: `[]`
- `effect_coverage_unknowns`: `33`
- `heuristic_effects`: `120`
- `trigger_not_explicit`: `147`
- `cast_permission_not_explicit`: `89`
- `land_utility_ability_not_modeled`: `48`
- `runtime_safe_rule_names`: `1702`
- `review_only_rule_names`: `1457`

Gates extras executados manualmente sobre a seed latest `63201430`:

- `replay_decision_auditor`: `turn_by_turn_clean`, `turn_findings=0`,
  `decision_findings=0`, `critical/high/medium/low=0/0/0/0`.
- `battle_forensic_audit`: `ready_for_review`, `findings_total=0`,
  `critical/high/medium/low=0/0/0/0`.

Lacuna nova mesmo com forensic limpo:

- `card_events`: `75`
- `card_id_present/missing`: `12/63`
- `semantic_hash_present/missing`: `12/63`
- `rule_logical_key_present/missing`: `74/1`

Leitura operacional: a seed latest esta limpa nos gates extras, mas a linhagem
de evento ainda e fraca para explicar com exatidao qual card/rule/hash sustentou
cada acao. Isso nao e o mesmo problema de legalidade, mas e relevante para
aprendizagem, auditoria e reproducibilidade de template.

## Passo de auditoria - focused evidence/template gap 2026-06-19T15:50Z

Artefato gerado:

- `docs/hermes-analysis/master_optimizer_reports/battle_template_gap_audit_20260619_155005.md`

Objetivo: verificar se os templates atuais de `focused_evidence` cobrem os
`unknown_cards` atuais do coverage latest.

Comandos executados:

- `python3 -m py_compile server/bin/manaloom_battle_rule_review_queue.py server/bin/manaloom_battle_rule_focused_evidence.py server/bin/manaloom_battle_rule_promotion_gate.py` - PASS
- `python3 server/test/manaloom_review_queue_consumers_test.py` - PASS,
  `Ran 11 tests`, `OK`

Inventario objetivo:

- `supports_*_template` atuais em
  `server/bin/manaloom_battle_rule_focused_evidence.py`: `21`
- `unknown_cards` no coverage latest: `29`
- unknowns cobertos por algum `supports_*_template`: `0/29`
- unknowns com familia inferida por `infer_effect_families_from_text(...)`: `5/29`
- unknowns sem familia inferida: `24/29`

Familias inferidas nos unknowns atuais:

- `copy_spell_or_permanent`: `2`
- `graveyard_recast_replacement`: `2`
- `counter_manipulation`: `2`
- `targeted_interaction`: `1`

Unknowns por deck:

- `Magda, Brazen Outlaw #71 (real)`: `8`
- `Yorion, Sky Nomad #38 (real)`: `8`
- `Urza, Lord High Artificer #87 (real)`: `5`
- demais decks: `1-2` cada.

Leitura operacional: o pipeline simples esta saudavel, mas ele prova os
templates estreitos ja conhecidos, nao a cobertura do backlog atual. Para o
corpus atual, ainda nao e correto afirmar que todos os templates de acao de
carta existem.

## Tratativas fechadas - 2026-06-19T15:52:24Z

Artefatos principais:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_155224/`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_current_seed786135854_postfix2_154953/`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_manual_forensic_add_mana_postfix_155014/`

Resumo evidenciado no latest automatizado `2026-06-19T15:52:24Z` com
`--seeds 1 --start-seed 786135854`:

- `action_findings`: `0`
- `strategy_findings`: `0`
- `decision_audit_turn_findings`: `0`
- `decision_audit_decision_findings`: `0`
- `forensic_rule_findings`: `0`
- `forensic_turn_findings`: `0`
- `seeds_with_high_or_critical_action_findings`: `[]`
- `seeds_with_high_or_critical_decision_audit_findings`: `[]`
- `seeds_with_high_or_critical_forensic_findings`: `[]`
- replay `seed_786135854/replay.txt`: `Pyroblast` nao aparece como counter
  resolvido, `trigger_placeholder_count=0` e nao ha `event=?`/`stack=?`.

Forensic manual antigo revalidado:

- Replay: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/manual-battle-simulation/20260619_135854/replay.events.jsonl`
- `add_mana_events`: `10`
- `rule_findings`: `0`
- `turn_findings`: `0`
- `unsupported_add_mana_findings`: `[]`

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-017`: `battle_forensic_audit.py` agora reconhece `add_mana` como efeito
  suportado; o teste `test_battle_forensic_audit_supported_effects.py` exige
  isso e o forensic manual antigo ficou sem findings.
- `BV-018`: `manaloom-battle-strategy-audit.sh` agora executa
  `replay_decision_auditor.py` e `battle_forensic_audit.py` por seed; o
  `summary.json` inclui contagens/seeds para replay decision e forensic, e o
  alerta considera high/critical desses gates.
- `BV-021` e `BV-029`: o caminho Lorehold miracle/topdeck deixou de conjurar
  cartas `effect=counter` sem alvo de pilha; a seed `786135854` ficou com
  `action_findings=0` e sem linha de `Pyroblast` resolvendo como counter.
- `BV-022`: `trigger_landfall()` agora retorna sem enfileirar trigger quando
  nao ha permanente/efeito landfall real; fixture cobre land comum sem landfall
  e landfall real.
- `BV-023` e `BV-026`: o renderer de `trigger_put_on_stack` usa os campos reais
  `trigger` e `timestamp`; fixture cobre o formato real do JSONL e o replay da
  seed `786135854` nao tem `TRIGGER ... event=? stack=?`.

Validacoes executadas e aprovadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`

## Tratativas fechadas - 2026-06-19T15:56:29Z

Artefato principal:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_155629/`

Resumo evidenciado:

- `action_findings`: `0`
- `action_verdict_counts`: `{"ok": 475}`
- `decision_audit_turn_findings`: `0`
- `forensic_rule_findings`: `0`
- `forensic_turn_findings`: `0`
- `seeds_with_high_or_critical_action_findings`: `[]`

ID removido de `Achados abertos` por tratativa + evidencia:

- `BV-030`: `battle_action_critic.py` agora valida `trigger_put_on_stack` com
  fonte (`card`/`source`), trigger (`trigger`/`trigger_event`/`event_type`) e
  ordem (`stack_depth` ou `timestamp`). A fixture
  `test_critic_flags_trigger_without_auditable_stack_metadata` cobre o caso
  invalido, `test_critic_accepts_trigger_with_source_trigger_and_stack_order`
  cobre o caso valido e o rerun da seed `786135854` ficou com
  `action_findings=0`.

Validacoes executadas e aprovadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py --events /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_786135854/replay.events.jsonl --decision-trace /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_786135854/replay.decision_trace.jsonl --json-output /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_786135854/action_critic_recheck_bv030.json --output /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_786135854/action_critic_recheck_bv030.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`

## Passo de auditoria - event contract 2026-06-19T15:57Z

Artefato proprio:

- `docs/hermes-analysis/master_optimizer_reports/battle_event_contract_audit_20260619_155726.md`

Artefatos gerados fora do repo:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_event_contract_155726/action_critic_include_technical.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_event_contract_155726/action_critic_include_technical.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_event_contract_155726/replay_decision_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_event_contract_155726/forensic_audit.json`

Latest audit usado:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_155224/`
- seed `786135854`
- `events=1071`
- `unique_event_types=39`
- `action_findings=0`
- `strategy_findings=0`
- `decision_audit_turn_findings=0`
- `decision_audit_decision_findings=0`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`

Nao ha high/critical para notificar nesta rodada:

- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_high_or_critical_decision_audit_findings=[]`
- `seeds_with_high_or_critical_forensic_findings=[]`
- `seeds_with_strategy_blockers=[]`

Leitura principal:

- `battle_analyst_v9.py` emite `94` nomes literais de eventos.
- `battle_replay_v10_3.py` tem `25` branches literais e fallback generico.
- `battle_action_critic.py` default verdictou `475/1071` eventos.
- `battle_action_critic.py --include-technical` incluiu `1071/1071` eventos e
  retornou `0` findings, mas eventos fora de `ACTION_EVENTS` ainda nao possuem
  checks especificos por tipo.
- Mesmo somando `ACTION_EVENTS` e `TECHNICAL_EVENTS`, `50` eventos observados
  ficam sem classe especializada: `activated_ability_skipped=18`,
  `lorehold_upkeep_rummage_skipped=10`,
  `topdeck_manipulation_activated=8`, `lorehold_upkeep_rummage=4`,
  `saga_chapter_progressed=2` e `8` tipos one-off.
- O evento `replacement_applied` da linha `399` tem `source=null` e
  `reason=null` para `Tayam, Luminous Enigma`, mas passa como `ok`.
- Sanity check posterior: o `latest/summary.json` avancou para
  `2026-06-19T16:01:45Z` mantendo seed `786135854`, `events=1071`,
  `action_findings=0`, `strategy_findings=0`, `forensic_rule_findings=0` e
  listas high/critical/blockers vazias.

## Tratativas fechadas - 2026-06-19T16:01:45Z

Artefato principal:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_160145/`

Resumo evidenciado:

- `decision_audit_statuses`: `{"turn_invariants_clean": 1}`
- `decision_audit_status_scope`: `turn_and_decision_trace_invariants`
- `decision_audit_human_replay_complete`:
  `not_evaluated_by_replay_decision_auditor`
- `decision_audit_rules_interaction_trusted`:
  `not_evaluated_by_replay_decision_auditor`
- `action_findings`: `0`
- `decision_audit_turn_findings`: `0`
- `forensic_rule_findings`: `0`

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-020`: `replay_decision_auditor.py` nao emite mais
  `turn_by_turn_clean` como se fosse confianca geral do replay; o status limpo
  agora e `turn_invariants_clean`, com escopo
  `turn_and_decision_trace_invariants`, e declara explicitamente que
  `human_replay_complete` e `rules_interaction_trusted` nao sao avaliados por
  esse auditor.
- `BV-009`: o `summary.json` principal separa a camada aprovada
  (`decision_audit_statuses={"turn_invariants_clean": 1}`) das camadas nao
  avaliadas (`human_replay_complete` e `rules_interaction_trusted`), evitando
  interpretar strategy/replay-decision limpo como garantia completa.

Validacoes executadas e aprovadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py docs/hermes-analysis/manaloom-knowledge/scripts/test_replay_decision_auditor_scope.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_replay_decision_auditor_scope.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py --skip-baseline --events /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_786135854/replay.events.jsonl --decision-trace /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_786135854/replay.decision_trace.jsonl --require-decision-trace --json-output /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/replay_decision_scope_160110/replay_decision_audit.json`
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`

## Tratativas fechadas - 2026-06-19T16:11:10Z

Artefato principal:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_161012/`

Resumo evidenciado:

- `events`: `1071`
- `action_findings`: `0`
- `action_verdict_counts`: `{"ok": 475}`
- `replacement_events`: `1`
- `replacement_missing_causal_metadata`: `0`
- `replacement_applied` linha `399`: `card=Tayam, Luminous Enigma`,
  `reason=removal`, `source=Swords to Plowshares`,
  `source_card_id=18b46232-481b-4868-884e-1c2d2d3f8f60`,
  `source_semantic_hash=d14d4bd6d75de5a572db7f73c985c269d456e7f2ad4ead0f74fe42f49d301cc6`,
  `from_zone=battlefield`, `to_zone=command_zone` e `causal_event`
  estruturado.
- `action_critic.json` linha logica `action-000147`: verdict `ok`, evidence
  `card=Tayam, Luminous Enigma; source=Swords to Plowshares; reason=removal; zone=battlefield->command_zone`,
  `findings=[]`.

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-036`: `replacement_applied` deixou de ser aceito sem causalidade. O
  emissor normaliza `source`, `reason`, `source_card_id`,
  `source_semantic_hash` e `causal_event`; os caminhos de removal/board
  wipe/dano/custo/combat passam causa conhecida; e o `battle_action_critic`
  agora gera finding `replacement_without_causal_metadata` quando `source`,
  `reason` e `causal_event` faltam.

Validacoes executadas e aprovadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_support.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`
- Checagem programatica do JSONL latest: `replacement_events=1`,
  `missing_causal_metadata=0`.
- `git diff --check` nos arquivos alterados desta tratativa.

## Passo de auditoria - docs/runtime inventory 2026-06-19T16:08Z

Artefato proprio:

- `docs/hermes-analysis/master_optimizer_reports/battle_documentation_runtime_inventory_audit_20260619_1608.md`

Escopo validado:

- inventario de docs battle atuais e historicos;
- inventario de scripts/testes battle por superficie;
- leitura da automacao local
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`;
- sanity check do `latest/summary.json`.

Resultado de inventario:

- `BATTLE_SYSTEM_LOGIC.md`: `1271` linhas, atualizado em `2026-06-19`, forte
  fonte de arquitetura/logica.
- `BATTLE_VALIDATION_REGISTER_2026-06-19.md`: fonte viva de achados.
- `BATTLE_GENERATOR_LOREHOLD_TASK_MATRIX_2026-06-17.md`: matriz priorizada,
  atualizada em `2026-06-19`.
- `ALL_CARD_CANDIDATE_REVIEW_2026-06-19.md`: fila/template atual.
- `LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`: fonte atual de
  coerencia do deck aprendido Lorehold.
- Foram encontrados `96` arquivos Python relacionados por nome a
  battle/replay/rule/learned-deck/optimizer/coherence em
  `docs/hermes-analysis/manaloom-knowledge/scripts`, `server/bin` e
  `server/test`.
- A automacao recorrente valida um conjunto curado de scripts/testes centrais,
  gera replay/action/strategy/replay-decision/forensic por seed, agrega
  research review e effect coverage, e alerta high/critical/action,
  strategy blockers, replay-decision high/critical, forensic high/critical e
  opcionalmente coverage unknowns por threshold de env.

Docs historicos que precisam de guarda de frescor antes de serem usados como
estado atual:

- `BATTLE_AUDIT_COVERAGE_STATUS_2026-06-16.md`
- `BATTLE_DECISION_STRATEGY_AUDIT_2026-06-15.md`
- `DECISION_TRACE_V1_SLICE_2026-06-15.md`
- `BATTLE_GENERATOR_IMPLEMENTATION_SLICE_SPEC_2026-06-17.md`
- `BATTLE_GENERATOR_TRUTH_STUDY_2026-06-17.md`
- `BATTLE_GENERATOR_LOREHOLD_TRUTH_STUDY_2026-06-16.md`
- `BATTLE_MULTI_RULE_RUNTIME_READINESS_2026-06-17.md`
- `BATTLE_PHASE_RULES_DEEP_AUDIT_2026-06-16.md`
- `CARD_BATTLE_RULES_CANONICALIZATION_AUDIT_2026-06-16.md`
- `LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md`
- `LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md`

Validacoes executadas:

- `python3 -m py_compile` para scripts centrais de battle/replay/critic/
  forensic/coverage/rule registry e scripts server de review queue/focused
  evidence/promotion/coherence - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_replay_decision_auditor_scope.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_registry_runtime_safe.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS.

Sanity check do latest:

- `timestamp_utc=2026-06-19T16:10:12Z`
- `start_seed=786135854`
- `events=1071`
- `action_findings=0`
- `strategy_findings=0`
- `decision_audit_turn_findings=0`
- `decision_audit_decision_findings=0`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- high/critical/blocker seed lists vazias.

## Tratativas fechadas - 2026-06-19T16:16:09Z

Artefato principal:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_161528/`

Resumo evidenciado:

- `events`: `1073`
- `action_findings`: `0`
- `strategy_findings`: `0`
- `forensic_rule_findings`: `0`
- `replay.txt` agora explica a transicao que deixava Thrasios em `39`
  antes do combate:
  `DAMAGE Sisay, Weatherlight Captain #31 (real): Thassa's Oracle -> Thrasios, Triton Hero #54 (real) amount=1 result=player_damage cause=finisher_total_power life=40->39`.
- `replay.events.jsonl` linha `110`: `damage_resolved`,
  `card=Thassa's Oracle`, `target_player=Thrasios, Triton Hero #54 (real)`,
  `cause=finisher_total_power`, `life_before=40`, `life_after=39`.
- O combate seguinte preserva a continuidade: `target_life_before=39` e
  `combat_result` `target_life_after=38`.

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-005`: a mudanca de vida fora de combate que antes aparecia como estado
  inicial/vida arbitraria agora tem evento estruturado e linha humana antes do
  combate. O emissor de `finisher` passou a emitir `damage_resolved` com
  `cause`, `life_before` e `life_after`; o renderer escreve essa causa no
  `replay.txt`.

Validacoes executadas e aprovadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`

## Passo de auditoria - runtime logic map 2026-06-19T16:16:23Z

Artefato gerado:

- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_logic_map_audit_20260619_161623.md`

Escopo:

- Inventario estatico/runtime de `battle_analyst_v9.py`, action critic,
  forensic, decision strategy auditor, replay decision auditor e suites battle
  imediatas.
- Sem alteracao de PostgreSQL, swaps, codigo de produto ou automacao.

Resumo do mapa runtime:

- `battle_analyst_v9.py`: `13900` linhas, `8` classes, `290` funcoes
  top-level, `94` tipos literais de eventos emitidos e `34` call sites de
  `emit_decision_trace(...)`.
- Familias de funcoes relevantes: cast (`15`), land (`23`), combat (`10`),
  trigger (`11`), target (`12`), rule (`11`), effect (`16`), mulligan (`7`) e
  decision (`10`).
- Tipos de decision trace encontrados estaticamente: `mulligan_decision`,
  `pass_no_action`, `response`, `utility_land_activation`,
  `utility_artifact_activation`, `activated_sacrifice_damage`,
  `attack_trigger_artifact_tutor`, `lorehold_upkeep_rummage`, `cast_spell`,
  `saga_chapter_resolution`, `combat_attack`, `wheel`, `board_wipe`,
  `worldfire_reset` e `tutor`.
- Latest seed `786135854`: `152` linhas de decision trace, `10` tipos
  exercitados e `0` linhas sem `score_components`.
- Superficie de efeitos: engine referencia `57` efeitos literais; forensic tem
  `52` `SUPPORTED_EFFECTS`; latest ainda mostra `effect_totals.unknown=41`,
  `effect_coverage_unknowns=33`, `heuristic_effects=120`,
  `review_only_rule_names=1457` e `review_only_rule_instances=34`.

Validacoes executadas nesta etapa:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_trigger_tests.py` - PASS.

Sanity check do latest usado nesta etapa:

- `timestamp_utc=2026-06-19T16:15:28Z`
- `run_dir=/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_161528`
- `start_seed=786135854`
- `events=1073`
- `action_findings=0`
- `strategy_findings=0`
- `decision_audit_turn_findings=0`
- `decision_audit_decision_findings=0`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`

Leitura operacional: as suites centrais estao passando e o latest nao tem
high/critical/blocker nos gates principais. Mesmo assim, ainda nao existe uma
matriz unica que prove, para cada efeito e tipo de decisao emitidos pelo
runtime, qual consumidor valida, quais campos sao obrigatorios, qual fixture
cobre e qual contagem aparece no latest.

## Tratativas fechadas - 2026-06-19T16:21:11Z

Artefatos principais:

- `docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_documentation_runtime_inventory_audit_20260619_1608.md`

Resumo evidenciado:

- Criado indice de documentacao com status `current`, `historical`,
  `superseded` e `background`.
- O indice marca `BATTLE_VALIDATION_REGISTER_2026-06-19.md` como fonte viva e
  exige checagem contra `latest/summary.json`, artefatos por seed e coverage
  atual antes de qualquer afirmacao de pronto.
- Os 11 docs historicos/superseded apontados pelo inventario receberam aviso no
  topo com ponte para o register vivo e para o indice:
  `BATTLE_AUDIT_COVERAGE_STATUS_2026-06-16.md`,
  `BATTLE_DECISION_STRATEGY_AUDIT_2026-06-15.md`,
  `DECISION_TRACE_V1_SLICE_2026-06-15.md`,
  `BATTLE_GENERATOR_IMPLEMENTATION_SLICE_SPEC_2026-06-17.md`,
  `BATTLE_GENERATOR_TRUTH_STUDY_2026-06-17.md`,
  `BATTLE_GENERATOR_LOREHOLD_TRUTH_STUDY_2026-06-16.md`,
  `BATTLE_MULTI_RULE_RUNTIME_READINESS_2026-06-17.md`,
  `BATTLE_PHASE_RULES_DEEP_AUDIT_2026-06-16.md`,
  `CARD_BATTLE_RULES_CANONICALIZATION_AUDIT_2026-06-16.md`,
  `LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md` e
  `LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md`.

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-019`: os documentos historicos usados como exemplo agora declaram
  explicitamente que nao sao prova de estado atual e apontam para o register.
- `BV-037`: existe indice/status de documentacao battle e os docs historicos
  mais acessados citados pelo inventario foram marcados com ponte para a fonte
  viva.

Validacoes executadas e aprovadas:

- Checagem `rg` por documento historico: todos retornaram `OK` para
  `BATTLE_VALIDATION_REGISTER_2026-06-19.md` e
  `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`.
- Checagem `rg` do indice: linhas de status `current`, `historical`,
  `superseded`, `background` e entradas para os docs citados presentes.
- `git diff --check` nos arquivos documentais alterados desta tratativa.

## Passo de auditoria - template contract crosscheck 2026-06-19T16:22:33Z

Artefatos gerados:

- `docs/hermes-analysis/master_optimizer_reports/battle_template_contract_crosscheck_20260619_162233.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_template_contract_162233/template_contract_crosscheck.json`

Objetivo: cruzar a superficie atual de focused evidence/templates com o backlog
real de `unknown_cards` do latest, sem alterar PostgreSQL, swaps, codigo de
produto ou automacao.

Validacoes executadas:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS, `3` testes.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_registry_runtime_safe.py` - PASS.
- `python3 server/test/manaloom_review_queue_consumers_test.py` - PASS, `11` testes.

Resumo evidenciado:

- `server/bin/manaloom_battle_rule_focused_evidence.py` expoe `21`
  funcoes `supports_*_template`.
- O latest tem `29` `unknown_cards`, `effect_coverage_unknowns=33`,
  `heuristic_effects=120`, `review_only_rule_instances=34`,
  `trigger_not_explicit=147` e `cast_permission_not_explicit=89`.
- Usando texto Oracle completo do corpus quando disponivel,
  `infer_effect_families_from_text(...)` inferiu alguma familia para apenas
  `6/29` unknowns.
- `23/29` unknowns seguem sem familia textual inferida.
- `0/29` unknowns bateram em algum dos `21` focused templates.
- `29/29` unknowns seguem fora da cobertura de focused evidence.

Leitura operacional: a resposta para "todos os templates de acoes de cartas
estao criados?" continua sendo nao para o corpus atual. Existem templates
focados reais e testes verdes, mas eles cobrem familias fixtureadas; o backlog
atual de unknowns ainda precisa de familia/template/waiver explicito antes de
qualquer afirmacao de cobertura completa.

## Passo de auditoria - decision trace taxonomy 2026-06-19T16:27Z

Artefatos gerados:

- `docs/hermes-analysis/master_optimizer_reports/battle_decision_trace_taxonomy_audit_20260619_1627.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_decision_trace_taxonomy_1627/decision_trace_taxonomy.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_decision_trace_taxonomy_1627/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_decision_trace_taxonomy_1627/replay_decision_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_decision_trace_taxonomy_1627/research_review.json`

Objetivo: separar cobertura generica de `decision_trace` de contrato especifico
por tipo de decisao, sem alterar PostgreSQL, swaps, codigo de produto ou
automacao.

Validacoes executadas:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py --events ... --decision-trace ...` - PASS, `0` findings.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py --skip-baseline --require-decision-trace ...` - PASS, `0` turn findings e `0` decision findings.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py --input-dir ...` - PASS, `10` categorias `coherent_in_sample`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_replay_decision_auditor_scope.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_trace_tests.py` - PASS.

Resumo evidenciado:

- `battle_analyst_v9.py` tem `34` call sites de `emit_decision_trace(...)` e
  `15` tipos estaticos de decisao.
- Latest seed `786135854` tem `152` linhas de decision trace e exercitou
  `10/15` tipos.
- `replay_decision_auditor.py` cobre invariantes genericos para todos os tipos,
  mas declara escopo `turn_and_decision_trace_invariants` e nao avalia
  completude do replay humano nem confianca total de regras.
- `battle_decision_strategy_auditor.py` tem branches especializados para
  `7` tipos: `board_wipe`, `cast_spell`, `mulligan_decision`,
  `pass_no_action`, `tutor`, `wheel` e `worldfire_reset`.
- `battle_decision_research_review.py` cobre `8` tipos: `board_wipe`,
  `cast_spell`, `combat_attack`, `mulligan_decision`, `pass_no_action`,
  `response`, `tutor` e `wheel`.
- Tipos observados no latest sem branch estrategico especifico nem categoria
  research: `utility_artifact_activation=8`, `lorehold_upkeep_rummage=4` e
  `saga_chapter_resolution=1`.
- Tipos emitidos pelo engine sem contrato especifico e nao observados no
  latest: `activated_sacrifice_damage`, `attack_trigger_artifact_tutor` e
  `utility_land_activation`.

Leitura operacional: o latest esta limpo para formato/invariantes genericos e
para as regras estrategicas que existem hoje. Isso nao prova que todos os tipos
de decisao tem contrato especifico. `strategy_findings=0` nao deve ser lido
como confianca completa para `utility_artifact_activation`,
`lorehold_upkeep_rummage` ou `saga_chapter_resolution`.

## Tratativas fechadas - 2026-06-19T16:30:44Z

Artefatos principais:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`
- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_manifest_20260619_1700.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_manifest_20260619_1700.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_163044/runtime_surface_manifest.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_163044/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_163044/summary.json`

Resumo evidenciado:

- O manifesto classifica a superficie Python atual encontrada por nome em
  `docs/hermes-analysis/manaloom-knowledge/scripts`, `server/bin` e
  `server/test`.
- Como o proprio manifesto e seu teste agora entram no scan `battle*`, a
  superficie atual validada ficou em `98` arquivos, contra os `96` do inventario
  original.
- `unclassified_files=[]`; todos os arquivos tem `category`, `owner`, `role`,
  `gate_expected` e `automation_coverage`.
- Contagem por categoria no latest: `core runtime=31`,
  `recurring audit gate=14`, `rule registry/sync=15`, `renderer=4`,
  `review queue=1`, `focused evidence/promotion=4`,
  `learned-deck source=14` e `optimizer/scorecard=15`.
- A automacao recorrente agora grava no `summary.json`:
  `runtime_surface_manifest_total_files=98`,
  `runtime_surface_manifest_unclassified_files=[]`,
  `runtime_surface_manifest_category_counts`,
  `runtime_surface_manifest_automation_coverage_counts`,
  `runtime_surface_manifest_recurring_categories` e
  `runtime_surface_manifest_outside_recurring_categories`.
- O run principal explicita que cobre diretamente categorias
  `core runtime`, `recurring audit gate`, `renderer` e `rule registry/sync`, e
  que ainda existem caminhos fora do run principal em `core runtime`,
  `focused evidence/promotion`, `learned-deck source`, `optimizer/scorecard`,
  `renderer`, `review queue` e `rule registry/sync`.

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-038`: existe manifesto de superficie battle com dono/categoria/gate por
  arquivo e a automacao recorrente passou a publicar quais categorias cobre
  diretamente e quais ficam fora do run principal.

Validacoes executadas e aprovadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py --repo-root /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia --output docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_manifest_20260619_1700.md --json-output docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_manifest_20260619_1700.json --fail-on-unclassified`
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`

## Tratativas fechadas - 2026-06-19T16:34Z

Artefato principal:

- `docs/hermes-analysis/BATTLE_DECISION_TRACE_TAXONOMY.md`

Resumo evidenciado:

- A taxonomia lista `15` tipos estaticos de `decision_trace` emitidos pelo
  engine e a cobertura do latest `20260619_163044`.
- O latest tem `decision_trace_rows_latest=152`,
  `decision_trace_kinds_exercised=10`, `decision_trace_kinds_uncovered=5` e
  `decision_trace_missing_required_fields=0`.
- Cada tipo tem linha propria com auditor generico
  `replay_decision_auditor.py`, status de auditoria estrategica, categoria de
  research quando existe, fixture/gate e status especifico.
- A mesma taxonomia preserva lacuna separada para contratos especificos:
  `lorehold_upkeep_rummage=4`, `saga_chapter_resolution=1` e
  `utility_artifact_activation=8` foram observados no latest apenas com
  cobertura generica. Por isso `BV-042` continua aberto.

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-040`: existe taxonomia dedicada com total de tipos, tipos exercitados,
  tipos nao exercitados, campos obrigatorios faltantes e dono/auditor por tipo.

Validacoes executadas e aprovadas:

- Checagem programatica do latest
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_163044/seed_786135854/replay.decision_trace.jsonl`:
  `rows=152`, `kinds_exercised=10`, `kinds_uncovered=5` e
  `missing_required_fields=0`.
- `rg` na taxonomia para `decision_trace_kinds_total`,
  `decision_trace_kinds_exercised`, `decision_trace_kinds_uncovered`,
  `decision_trace_missing_required_fields`, `Ownership Matrix` e
  `Specific Contract Gaps`.
- `git diff --check` em
  `docs/hermes-analysis/BATTLE_DECISION_TRACE_TAXONOMY.md`.

## Passo de auditoria - action event contract 2026-06-19T16:35Z

Artefatos gerados:

- `docs/hermes-analysis/master_optimizer_reports/battle_action_event_contract_audit_20260619_1635.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/action_event_contract_1635/action_event_contract.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/action_event_contract_1635/action_critic_include_technical.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/action_event_contract_1635/forensic_audit.json`

Objetivo: medir cobertura de eventos pelo `battle_action_critic`, renderer e
forensic, separando evento auditado de evento apenas incluido em ledger.

Validacoes executadas:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py --include-technical ...` - PASS, `0` findings.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py --events ... --report ...` - PASS.

Resumo evidenciado no latest `2026-06-19T16:30:44Z`:

- `battle_analyst_v9.py` tem `143` call sites de `emit_replay_event(...)` e
  `94` tipos estaticos de evento.
- Latest seed `786135854`: `1073` eventos e `40` tipos observados.
- `battle_action_critic.py` define `24` `ACTION_EVENTS` e `4`
  `TECHNICAL_EVENTS`.
- Action critic default: `total_actions=475`, `verdict_counts={"ok":475}`,
  `findings=0`.
- Action critic com `--include-technical`: `total_actions=1073`,
  `verdict_counts={"ok":1073}`, `findings=0`.
- Eventos observados fora de `ACTION_EVENTS + TECHNICAL_EVENTS`: `52` eventos
  em `14` tipos.
- Maiores tipos fora do default: `activated_ability_skipped=18`,
  `lorehold_upkeep_rummage_skipped=10`, `topdeck_manipulation_activated=8`,
  `lorehold_upkeep_rummage=4`, `damage_resolved=2` e
  `saga_chapter_progressed=2`.
- Forensic cobre `111` card events no latest; ainda ha lacuna de linhagem:
  `card_id_present=63`, `card_id_missing=48`,
  `semantic_hash_present=63`, `semantic_hash_missing=48`.

Leitura operacional: o latest esta sem high/critical action findings. Mesmo
assim, `action_verdict_counts={"ok":475}` cobre apenas eventos default do
critic, nao todos os `1073` eventos. E `ok=1073` com `--include-technical` e um
ledger amplo, nao prova que todos os tipos tem checks especificos. Falta expor
no summary quantos eventos/tipos foram `action_audited`, `technical`,
`renderer_only`, `forensic_card_event`, `strategy_signal` ou
`ignored_with_reason`.

## Tratativas fechadas - 2026-06-19T16:36:18Z

Artefatos principais:

- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_163618/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_163618/summary.md`

Resumo evidenciado:

- A matriz define gates obrigatorios para status final:
  `action_critic`, `strategy_audit`, `replay_decision_audit`,
  `forensic_audit` e `effect_coverage`.
- O wrapper recorrente agora publica `mandatory_gates_required_for_final_status`,
  `mandatory_gate_statuses`, `mandatory_gate_divergences`,
  `battle_replay_final_status` e `battle_replay_final_status_reason`.
- No run `20260619_163618`, os gates `action_critic`, `strategy_audit`,
  `replay_decision_audit` e `forensic_audit` ficaram `pass`.
- `effect_coverage` ficou `review_required` por `unknown_effects=33`,
  `heuristic_effects=120`, `trigger_not_explicit=147`,
  `cast_permission_not_explicit=89`, `land_utility_ability_not_modeled=48` e
  `review_only_rule_instances=34`.
- O status final unico do replay foi `battle_replay_final_status=review_required`
  com `mandatory_gate_divergences=["effect_coverage=review_required"]`.

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-016`: o replay agora so recebe leitura agregada por status final unico
  depois dos gates obrigatorios; divergencias entre gates aparecem no summary.

Validacoes executadas e aprovadas:

- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`
- Checagem programatica de
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`:
  `battle_replay_final_status=review_required`,
  `mandatory_gate_statuses.effect_coverage.status=review_required` e
  `mandatory_gate_divergences` contem `effect_coverage=review_required`.
- `rg` em `summary.md` para `Mandatory gate statuses`,
  `Mandatory gate divergences` e `Battle replay final status`.
- `git diff --check` em `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`.

## Tratativas fechadas - 2026-06-19T16:39:24Z

Artefatos principais:

- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_1638_runtime_status.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_1638_runtime_status.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_163924/summary.json`

Resumo evidenciado:

- `battle_effect_coverage_audit.py` agora separa regras nao executaveis por
  `review_status` e `execution_status` em vez de inferir `review_only` pela
  diferenca entre `active_or_review` e `runtime_safe`.
- O coverage dedicado mostrou: `runtime_safe_rule_names=1702`,
  `active_or_review_rule_names=3159`,
  `non_runtime_safe_rule_names=1457`,
  `needs_review_rule_names=1457`, `review_only_rule_names=0`,
  `annotation_only_rule_names=0` e `non_runtime_other_rule_names=0`.
- `review_status_counts={"active": 27, "needs_review": 1457, "verified": 1675}`
  e `execution_status_counts={"auto": 3159}`.
- No corpus latest, os `34` usos antes expostos como `review_only_rule`
  passaram a aparecer como `needs_review_rule`; `review_only_rule_instances=0`.
- O `summary.json` recorrente replica esses campos e o gate
  `effect_coverage` inclui `needs_review_rule_names=1457` como motivo de
  `review_required`, junto com `effect_coverage_unknowns=33`.

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-025`: summaries e gates agora exibem separadamente `runtime_safe`,
  `needs_review`, `review_only`, `non_runtime_safe` e `unknown`, sem tratar
  regra `needs_review` como `review_only` executavel.

Validacoes executadas e aprovadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - `5` testes OK.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_registry_runtime_safe.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --output docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_1638_runtime_status.md --json-output docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_1638_runtime_status.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`
- Checagem programatica do latest `summary.json` para
  `needs_review_rule_names=1457`, `review_only_rule_names=0`,
  `review_only_rule_instances=0` e
  `mandatory_gate_statuses.effect_coverage.needs_review_rule_names=1457`.
- `git diff --check` nos arquivos/artefatos desta tratativa.

## Passo de auditoria - documentation freshness 2026-06-19T16:42Z

Artefato gerado:

- `docs/hermes-analysis/master_optimizer_reports/battle_documentation_freshness_audit_20260619_1642.md`

Objetivo: verificar se a documentacao battle atual aponta para este register e
se o indice de status inclui os artefatos de validacao criados depois das
auditorias iniciais de 2026-06-19.

Validacoes executadas:

- `rg --files docs server/doc | rg -i '(battle|replay|lorehold|strategy|decision|forensic|effect|template|learned|optimizer)'`
- Checagem programatica de presenca no indice e referencia ao register para
  docs atuais.
- Checagem do latest
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`.

Resumo evidenciado:

- Latest `summary.json` em `2026-06-19T16:39:24Z`: `events=1073`,
  `decisions=152`, `action_findings=0`, `strategy_findings=0`,
  `forensic_rule_findings=0`, `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["effect_coverage=review_required"]`,
  `effect_coverage_unknowns=33` e `heuristic_effects=120`.
- Nao ha high/critical/action, strategy blockers, replay-decision high/critical
  ou forensic high/critical no latest.
- `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` aponta corretamente este
  register como fonte viva, mas sua tabela de `Current Sources` nao inclui
  artefatos criados depois, incluindo `BATTLE_DECISION_TRACE_TAXONOMY.md`,
  `BATTLE_REPLAY_GATE_MATRIX.md`,
  `battle_action_event_contract_audit_20260619_1635.md`,
  `battle_decision_trace_taxonomy_audit_20260619_1627.md`,
  `battle_template_contract_crosscheck_20260619_162233.md`,
  `battle_runtime_surface_manifest_20260619_1700.md`,
  `battle_effect_coverage_audit_20260619_1638_runtime_status.md` e
  `battle_forensic_audit_20260619_163318.md`.
- `BATTLE_SYSTEM_LOGIC.md` se declara documento canonico completo, esta com
  `Ultima atualizacao: 2026-06-18` e nao referencia este register, a gate
  matrix ou o status agregado `review_required` atual.

Leitura operacional: docs amplos continuam uteis para arquitetura, mas nao
podem ser usados como prova atual de prontidao sem cruzar com este register e o
latest `summary.json`.

## Tratativas fechadas - 2026-06-19T16:42:53Z

Artefatos principais:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_164253/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_164253/seed_786135854/action_critic.json`

Resumo evidenciado:

- `battle_action_critic.py` agora publica `event_contract` com classe e motivo
  para cada tipo de evento observado.
- O wrapper recorrente agrega no `summary.json`:
  `action_events_total`, `action_event_types_total`,
  `action_event_contract_class_counts`,
  `action_event_type_class_counts`, `action_events_unclassified` e
  `action_event_types_unclassified`.
- No run `20260619_164253`, `events=1073`,
  `action_events_total=1073`, `action_event_types_total=40` e
  `action_events_unclassified=0`.
- Classes agregadas: `action_audited=475`, `technical=547`,
  `ignored_with_reason=29`, `strategy_signal=17` e `renderer_only=5`.
- `action_verdict_counts={"ok":475}` agora fica acompanhado do denominador
  correto; `--include-technical` continua sendo ledger/pass-through, nao prova
  validacao especializada para todos os eventos.

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-035`: o summary mostra total de eventos, eventos auditados, tecnicos,
  ignorados com motivo, sinais estrategicos, renderer-only e nao classificados.
- `BV-043`: o denominador do action critic ficou explicito e
  `action_event_types_unclassified={}` / `action_events_unclassified=0` no
  latest validado.

Validacoes executadas e aprovadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`
- Checagem programatica do latest `summary.json`:
  `action_events_total=events=1073`, `action_event_types_total=40`,
  `action_events_unclassified=0`, `action_event_types_unclassified={}` e
  `action_event_contract_class_counts` com as cinco classes acima.
- `rg` em `summary.md` para `Action events total`,
  `Action event contract class counts`, `Action events unclassified` e
  `Action event types unclassified`.
- `git diff --check` em `battle_action_critic.py` e
  `test_battle_action_critic.py`.

## Tratativas fechadas - 2026-06-19T16:44Z

Artefatos principais:

- `docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`
- `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md`

Resumo evidenciado:

- O indice agora declara que, quando houver divergencia, omissao ou artefato
  novo ainda nao listado, este register prevalece.
- A tabela `Current Sources` do indice passou a incluir os artefatos current
  recentes: `BATTLE_DECISION_TRACE_TAXONOMY.md`,
  `BATTLE_REPLAY_GATE_MATRIX.md`,
  `battle_action_event_contract_audit_20260619_1635.md`,
  `battle_template_contract_crosscheck_20260619_162233.md`,
  `battle_runtime_surface_manifest_20260619_1700.md`,
  `battle_effect_coverage_audit_20260619_1638_runtime_status.md`,
  `battle_forensic_audit_20260619_163318.md` e
  `battle_documentation_freshness_audit_20260619_1642.md`.
- `BATTLE_SYSTEM_LOGIC.md` recebeu aviso no topo declarando que e referencia
  de arquitetura/logica, nao prova de prontidao atual, e aponta para este
  register, para o latest `summary.json` e para `BATTLE_REPLAY_GATE_MATRIX.md`.
- `BATTLE_SYSTEM_LOGIC.md` tambem registra o status agregado atual
  `battle_replay_final_status=review_required`.

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-044`: o indice current foi atualizado e tambem declara explicitamente que
  o register prevalece sobre lista incompleta.
- `BV-045`: o documento canonico agora aponta para register/latest/gate matrix
  antes de qualquer conclusao de pronto.

Validacoes executadas e aprovadas:

- `rg` no indice para os artefatos current adicionados.
- Checagem direta do bloco inicial do indice confirmando `register prevalece`
  e lista nao exaustiva.
- `rg` em `BATTLE_SYSTEM_LOGIC.md` para `Status de prontidao atual`,
  `BATTLE_VALIDATION_REGISTER_2026-06-19.md`, `latest/summary.json`,
  `BATTLE_REPLAY_GATE_MATRIX.md` e
  `battle_replay_final_status=review_required`.
- `git diff --check` nos dois documentos.

## Passo de auditoria - unknown template backlog 2026-06-19T16:46Z

Artefatos gerados:

- `docs/hermes-analysis/master_optimizer_reports/battle_unknown_template_backlog_manifest_20260619_1646.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/unknown_template_backlog_1642/unknown_template_backlog.json`

Objetivo: transformar a pergunta "todos os templates de acoes de cartas estao
criados?" em backlog por carta, usando o coverage atual, a inferencia atual da
fila de review e os templates atuais de focused evidence.

Validacoes executadas:

- Manifesto gerado a partir de
  `battle_effect_coverage_audit_20260619_1638_runtime_status.json`, importando
  `infer_effect_families_from_text(...)` e `supports_*_template(...)` atuais.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS, `5` testes.
- `python3 server/test/manaloom_review_queue_consumers_test.py` - PASS, `11` testes.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_registry_runtime_safe.py` - PASS.

Resumo evidenciado:

- `unknown_cards=29`.
- `with_current_inferred_family=5`.
- `without_current_inferred_family=24`.
- `with_focused_template_match=0`.
- `without_focused_template_match=29`.
- O backlog nao e um unico template generico faltante; e composto por familias
  distintas como custo alternativo/adicional, static tax/cast restriction,
  manifest/cloak, tap/untap, activated utility, copy/type/counter manipulation,
  split second e modal mass sacrifice.

Leitura operacional: as suites verdes provam o pipeline e os templates
fixtureados, mas o backlog real atual ainda nao tem focused template nem waiver
por carta. A resposta atual para cobertura completa de templates de acoes de
cartas continua sendo nao.

## Passo de auditoria - effect/template contract 2026-06-19T16:50Z

Artefatos gerados:

- `docs/hermes-analysis/master_optimizer_reports/battle_effect_template_contract_manifest_20260619_1650.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/effect_template_contract_1650/effect_template_contract.json`

Objetivo: cruzar os `effect_json.effect` observados no coverage atual contra
runtime, forensic e focused evidence, sem assumir que suite verde prova contrato
efeito-a-efeito.

Validacoes executadas:

- Manifesto gerado a partir de
  `battle_effect_coverage_audit_20260619_1638_runtime_status.json`.
- AST/read-only scan em `battle_analyst_v9.py` para literais de efeito e
  handlers primarios/composite.
- AST/read-only scan em `battle_forensic_audit.py` para `SUPPORTED_EFFECTS`.
- Scan em `manaloom_battle_rule_focused_evidence.py` para
  `supports_*_template`.

Resumo evidenciado:

- `40` familias de efeito observadas no coverage atual, cobrindo `1288`
  instancias.
- `0/40` efeitos observados ficaram sem literal detectado no runtime.
- `2/40` efeitos nao estao em `SUPPORTED_EFFECTS` do forensic:
  `unknown` e `worldfire_reset`.
- `30/40` efeitos observados nao tem mapeamento para focused template.
- `27/40` efeitos observados ainda possuem flags de coverage.
- Status do contrato:
  - `mapped_no_current_flags=2`: `deal_damage` e `board_wipe`.
  - `mapped_but_incomplete_contract=36`.
  - `gap=2`: `unknown` e `worldfire_reset`.

Leitura operacional: a lacuna nao e mais "runtime nao menciona o efeito" para
o corpus atual; todos os nomes observados aparecem no runtime. A lacuna atual e
contrato completo por efeito: suporte forensic/waiver, focused template ou
subcontrato aceito, flags zeradas/triadas e status por coverage.

## Tratativas fechadas - 2026-06-19T16:47:22Z

Artefato principal:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_164722/summary.json`

Resumo evidenciado:

- O wrapper recorrente agora propaga para o `summary.json` principal os
  contadores de linhagem do `battle_forensic_audit.py`.
- No latest `20260619_164722`, `forensic_rule_findings=0` e
  `forensic_turn_findings=0`, mas `forensic_lineage_status=incomplete`.
- Cobertura de linhagem exibida no summary:
  `forensic_card_event_count=111`,
  `forensic_card_id_present/missing=63/48`,
  `forensic_semantic_hash_present/missing=63/48` e
  `forensic_rule_logical_key_present/missing=109/2`.
- Assim, forensic limpo nao e mais apresentado como prova de linhagem completa;
  status de regra limpa e status de linhagem incompleta aparecem separados.

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-031`: o summary separa explicitamente ausencia de findings forensic de
  linhagem semantica incompleta.

Validacoes executadas e aprovadas:

- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`
- Checagem programatica do latest `summary.json` para todos os contadores de
  linhagem e `forensic_lineage_status=incomplete`.
- `rg` em `summary.md` para `Forensic card event count`,
  `Forensic card_id present/missing`,
  `Forensic semantic_hash present/missing`,
  `Forensic rule_logical_key present/missing` e
  `Forensic lineage status`.

## Tratativas fechadas - 2026-06-19T16:54:21Z

Artefatos principais:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_165421/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_165421/seed_786135854/deck_provenance.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_165421/seed_786135854/replay.txt`

Resumo evidenciado:

- O replay humano agora inclui bloco `DECK SOURCE PROVENANCE`, declarando que
  lands, CMC e curva sao derivados das listas runtime resolvidas e que metadata
  cacheada de learned deck nao e usada para essas metricas.
- Cada seed tambem escreve `deck_provenance.json` com
  `metrics_policy=runtime_derived_from_resolved_card_lists`,
  `cached_metadata_used_for_replay_metrics=false` e
  `blocker_domain_policy=deck_source_or_legality_findings_are_reported_separately_from_battle_engine_findings`.
- O wrapper recorrente agrega esses campos no `summary.json` principal. No run
  `20260619_165421`, Lorehold aparece como
  `source_kind=sqlite_deck_cards`, `source_ref=deck_id:6`,
  `metrics_basis=runtime_derived_from_resolved_card_list`,
  `cached_metadata_used_for_metrics=false`, `lands=33`,
  `avg_cmc_nonlands=2.97` e curva
  `{"0":2,"1":16,"2":13,"3":19,"4":7,"5":2,"6":2,"7+":5}`.
- O mesmo `deck_provenance.json` traz `construction_report.is_valid=true`,
  `issues=[]`, `off_color_cards=[]` e `blocker_domain=none` para Lorehold.
  Assim, se uma futura falha vier de fonte/legalidade de deck, ela tem dominio
  proprio e nao se mistura com findings de action/strategy/forensic da partida.
- O status agregado do run ficou `battle_replay_final_status=review_required`
  por `effect_coverage=review_required`; nao houve blocker de deck source nesta
  seed (`deck_source_blocker_domains={"none":4}`).

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-027`: os reports da seed passam a declarar a fonte e a base das metricas
  de lands, CMC e curva, todas derivadas da lista resolvida em runtime, com
  metadata cacheada explicitamente ignorada.
- `BV-028`: o replay, o JSON de proveniencia e o summary separam o dominio
  `deck_source`/legalidade dos gates de simulacao da partida.

Validacoes executadas e aprovadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`
- Checagem programatica do latest `summary.json`, do
  `seed_786135854/deck_provenance.json` e do cabecalho do `replay.txt`.

## Passo de auditoria - static event contract 2026-06-19T17:08-03:00

Artefatos gerados:

- `docs/hermes-analysis/master_optimizer_reports/battle_event_contract_static_manifest_20260619_1708.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/event_contract_static_observed_1708/event_contract_static_observed.json`

Resumo evidenciado:

- O latest `summary.json` continua sem high/critical em action findings,
  strategy blockers, decision audit ou forensic findings:
  `seeds_with_high_or_critical_action_findings=[]`,
  `seeds_with_strategy_blockers=[]`,
  `seeds_with_high_or_critical_decision_audit_findings=[]` e
  `seeds_with_high_or_critical_forensic_findings=[]`.
- A rodada observada esta limpa para evento sem classificacao:
  `observed_events_total=1073`, `observed_event_types_total=40`,
  `observed_unclassified_total=0` e `observed_unclassified_types=[]`.
- A cobertura preventiva ainda nao esta fechada: `battle_analyst_v9.py` tem
  `94` tipos literais emitidos por `emit_replay_event(...)`, mas `55` tipos
  estaticos ainda caem em `unclassified` pelo `battle_action_critic.py`.
- Desses eventos estaticos, `57` nao apareceram no latest; portanto o seed
  atual nao prova que esses caminhos raros tenham contrato de campos minimos,
  renderer, forensic/strategy ou motivo de ignore.
- O renderer tem branch exato para `25` tipos estaticos, branch dinamico
  `_activated` para `5`, e `64` tipos ficam no maximo em fallback de vida
  (`only_life_note_fallback_if_life_fields`) se carregarem campos de vida.
- O forensic cobre `9` tipos estaticos como `CARD_EVENT_KINDS`; o restante nao
  tem auditoria de linhagem de carta por esse caminho.
- Eventos observados sem chamada literal direta no AST, mas classificados:
  `player_eliminated`, `replacement_applied` e `saga_sacrificed_by_sba`. Isso
  deve continuar no manifesto para diferenciar emissao indireta de falta real de
  contrato.

Falha/ajuste registrado:

- BV-034 permanece aberto, agora com evidencia mais precisa: o problema nao e
  mais evento observado sem classe no latest; e a falta de contrato preventivo
  para todos os eventos emitíveis. Uma rodada futura pode ativar um evento raro,
  cair em `unclassified` ou renderer generico, e ainda assim nao produzir finding
  proporcional.

Validacoes executadas:

- Geracao do manifesto static+observed via AST de `battle_analyst_v9.py`,
  `battle_action_critic.py`, `battle_replay_v10_3.py`,
  `battle_forensic_audit.py` e latest `replay.events.jsonl`.

## Tratativas fechadas - 2026-06-19T17:08:28Z

Artefatos gerados:

- `docs/hermes-analysis/master_optimizer_reports/battle_unknown_template_backlog_audit_20260619_170609.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/unknown_template_backlog_latest_170609/unknown_template_backlog.json`

Resumo evidenciado:

- O auditor `battle_unknown_template_backlog_audit.py` foi reexecutado contra
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_170609/effect_coverage.json`
  com `--fail-on-unplanned`.
- O resultado ficou `status=backlog_manifest_ready`, `unknown_cards=29`,
  `with_current_inferred_family=29`, `without_current_inferred_family=0`,
  `with_reviewed_family=29`, `without_reviewed_family=0`,
  `with_plan_or_waiver=29` e `without_plan_or_waiver=0`.
- Todos os `29` unknowns atuais possuem familia revisada e proximo fixture
  planejado, todos com `plan_status=template_required`.
- A lacuna restante continua sendo runtime/template, nao triagem: o mesmo rerun
  mostra `with_focused_template_match=0`,
  `without_focused_template_match=29` e `unknowns_without_template` contendo os
  `29` cards.
- O wrapper recorrente tambem foi atualizado e validado no run
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_170609/summary.json`.
  Nesse latest, `unknown_template_backlog` aparece em
  `mandatory_gate_statuses` com `status=pass`,
  `status_detail=backlog_manifest_ready`,
  `without_current_inferred_family=0`, `without_reviewed_family=0`,
  `without_plan_or_waiver=0` e `without_focused_template_match=29`.
- O status final da rodada segue `battle_replay_final_status=review_required`
  por `effect_coverage=review_required`; a integracao do gate de triagem nao
  reclassifica a falta de focused templates como resolvida.
- Maiores familias revisadas do backlog: `manifest_cloak_equipment=3` e
  `impulse_topdeck_or_library_zone=2`; as demais familias revisadas aparecem uma
  vez cada, incluindo `convoke_damage`, `split_second_damage`,
  `static_noncreature_tax`, `static_tax_and_opponent_life_loss`,
  `tap_untap_cipher_trigger`, `modal_mass_sacrifice_selection` e
  `x_cost_counters_vehicle_token`.

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-014`: o backlog atual esta decomposto por familia revisada, com plano e
  proximo fixture por card.
- `BV-015`: a inferencia/triagem atual nao fica mais em `5/29`; o rerun mostra
  `29/29` com familia corrente e `29/29` com familia revisada.

Validacoes executadas e aprovadas:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py --coverage-json /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_170609/effect_coverage.json --output docs/hermes-analysis/master_optimizer_reports/battle_unknown_template_backlog_audit_20260619_170609.md --json-output /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/unknown_template_backlog_latest_170609/unknown_template_backlog.json --fail-on-unplanned`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`

## Passo de auditoria - decision trace contract 2026-06-19T17:12Z

Artefatos gerados:

- `docs/hermes-analysis/master_optimizer_reports/battle_decision_trace_contract_audit_20260619_1712.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/decision_trace_contract_170609/decision_trace_contract.json`

Resumo evidenciado:

- O latest `20260619_170609` tem `152` linhas de
  `replay.decision_trace.jsonl`, `10` tipos observados e `0` linhas com campos
  genericos/estrategicos obrigatorios faltando.
- `replay_decision_auditor.py` continua limpo, mas seu escopo declarado e
  `turn_and_decision_trace_invariants`; ele nao avalia completude do replay
  humano nem confianca de interacao de regras.
- `battle_decision_strategy_auditor.py` retornou
  `verdict=usable_for_strategy_learning` e `findings=0`, mas possui branch
  especifico para apenas `7/15` tipos estaticos de decision trace.
- `battle_decision_research_review.py` mapeia categorias de pesquisa para
  `8/15` tipos estaticos.
- Tipos estaticos extraidos de `emit_decision_trace(...)`: `15`; call sites:
  `34`.
- Tipos observados com contrato completo strategy+research: `5`.
- Tipos observados `generic_only_gap`: `3`, somando `13` linhas:
  `utility_artifact_activation=8`, `lorehold_upkeep_rummage=4` e
  `saga_chapter_resolution=1`.
- Tipos observados com contrato parcial research-only: `2`, somando `25`
  linhas: `combat_attack=24` e `response=1`.
- Assim, `observed_without_full_contract_rows=38` mesmo com
  `decision_audit_decision_findings=0` e `strategy_findings=0`.
- Tipos estaticos nao observados no latest: `activated_sacrifice_damage`,
  `attack_trigger_artifact_tutor`, `board_wipe`, `utility_land_activation` e
  `worldfire_reset`.
- Tipos estaticos ainda `generic_only_gap`: `activated_sacrifice_damage`,
  `attack_trigger_artifact_tutor`, `lorehold_upkeep_rummage`,
  `saga_chapter_resolution`, `utility_artifact_activation` e
  `utility_land_activation`.
- `worldfire_reset` tem branch no strategy auditor, mas segue sem categoria de
  research review.

Falha/ajuste registrado:

- `BV-042` permanece aberto. A falha nao e formato de decision trace, e sim
  falta de contrato completo por tipo. O estado atual prova shape generico
  limpo; nao prova que todos os tipos de decisao sejam learning-grade.

## Tratativas fechadas - 2026-06-19T17:16:23Z

Tratativa aplicada para `BV-042`:

- Criado `battle_decision_trace_taxonomy_audit.py` como gate recorrente de
  taxonomia de `decision_trace`.
- Criado `test_battle_decision_trace_taxonomy_audit.py`; o teste falha quando
  um tipo observado fica sem contrato, e tambem falha quando um tipo com waiver
  aceito perde campos especificos obrigatorios.
- `battle_runtime_surface_manifest.py` agora classifica o auditor e seu teste
  como `recurring audit gate`.
- O wrapper recorrente
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  passou a executar o gate, publicar `decision_trace_taxonomy.md/json` e expor
  os contadores no `summary.json` e em `mandatory_gate_statuses`.
- Atualizado `BATTLE_DECISION_TRACE_TAXONOMY.md` para refletir a matriz atual:
  todos os `15` tipos estaticos tem dono, status especifico ou waiver aceito.

Evidencia da rodada oficial:

- Run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_171605`
- Summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_171605/summary.json`
- Taxonomia recorrente:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_171605/decision_trace_taxonomy.md`
  e
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_171605/decision_trace_taxonomy.json`
- `decision_trace_taxonomy_status=decision_trace_taxonomy_ready`
- `decision_trace_taxonomy_rows=152`
- `decision_trace_kinds_total=15`
- `decision_trace_kinds_observed=10`
- `decision_trace_contract_findings=0`
- `decision_trace_missing_required_fields=0`
- `decision_trace_static_without_contract=0`
- `decision_trace_observed_without_contract=0`
- `decision_trace_kinds_without_specific_contract=0`
- `decision_trace_observed_without_specific_contract=0`
- `mandatory_gate_statuses.decision_trace_taxonomy.status=pass`
- Waivers aceitos e vinculados a contrato de campos:
  `activated_sacrifice_damage`, `attack_trigger_artifact_tutor`,
  `lorehold_upkeep_rummage`, `saga_chapter_resolution`,
  `utility_artifact_activation` e `utility_land_activation`.

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-042`: o gap deixou de ser invisivel/generico; agora existe gate
  recorrente no summary, contrato por tipo e waiver aceito para todos os tipos
  que nao tem branch/categoria dedicada. O gate fica `pass` na rodada
  `20260619_171605` e falha em teste quando surge tipo observado sem contrato
  ou quando um tipo com waiver perde campo especifico obrigatorio.

Validacoes executadas e aprovadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_trace_taxonomy_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_trace_taxonomy_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_trace_taxonomy_audit.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_trace_taxonomy_audit.py --input-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest --json-output /tmp/decision_trace_taxonomy_probe.json --output /tmp/decision_trace_taxonomy_probe.md`
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`

## Tratativas fechadas - 2026-06-19T17:22:50Z

Tratativa aplicada para `BV-034`:

- Expandida a classificacao central de contratos em
  `battle_action_critic.py` para cobrir os eventos raros emitidos pelo engine,
  sem reclassificar tudo como acao auditada. Os eventos foram atribuidos a
  `action_audited`, `technical`, `strategy_signal`, `renderer_only`,
  `ignored_with_reason` ou `forensic_card_event`.
- Criado `battle_event_contract_static_audit.py` como gate recorrente:
  ele extrai os tipos literais de `emit_replay_event(...)`, cruza com eventos
  observados no JSONL, aplica `classify_event_contract`, exige campos minimos
  por classe e registra consumidor esperado.
- Criado `test_battle_event_contract_static_audit.py`; o teste falha quando
  surge evento estatico/observado sem contrato e quando evento observado perde
  campo minimo da classe.
- `battle_runtime_surface_manifest.py` agora classifica o auditor e seu teste
  como `recurring audit gate`.
- O wrapper recorrente
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  passou a executar o gate, publicar `event_contract_static.md/json` e expor
  os contadores no `summary.json` e em `mandatory_gate_statuses`.

Evidencia da rodada oficial:

- Run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172250`
- Summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172250/summary.json`
- Auditoria recorrente:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172250/event_contract_static.md`
  e
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172250/event_contract_static.json`
- `event_contract_static_status=event_contract_static_ready`
- `event_contract_static_events_observed_total=1073`
- `event_contract_static_observed_event_types_total=40`
- `event_contract_static_static_event_types_total=94`
- `event_contract_static_all_event_types_total=97`
- `event_contract_static_observed_unclassified_total=0`
- `event_contract_static_static_unclassified_total=0`
- `event_contract_static_observed_missing_required_fields=0`
- `mandatory_gate_statuses.event_contract_static.status=pass`
- `event_contract_static_static_class_counts={"action_audited":22,"forensic_card_event":2,"ignored_with_reason":6,"renderer_only":13,"strategy_signal":42,"technical":9}`

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-034`: o contrato de eventos deixou de validar apenas os tipos observados.
  O summary recorrente agora cobre o dominio estatico literal, falha quando um
  novo evento emitivel fica sem classificacao e valida campos minimos para
  eventos observados.

Validacoes executadas e aprovadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py --input-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest --output /tmp/event_contract_static_probe.md --json-output /tmp/event_contract_static_probe.json`
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`

## Passo de auditoria - event contract fixture depth 2026-06-19T17:22Z

Artefatos:

- `docs/hermes-analysis/master_optimizer_reports/battle_event_contract_fixture_depth_audit_20260619_172250.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/event_contract_fixture_depth_172250/event_contract_fixture_depth.json`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172250/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172250/event_contract_static.json`

Resumo:

- `event_contract_static` permanece uma tratativa fechada para `BV-034`:
  `status=pass`, `observed_unclassified_total=0`,
  `static_unclassified_total=0` e `observed_missing_required_fields=0`.
- A lacuna residual e profundidade de fixture, nao classificacao: `57` tipos
  emitíveis estaticos ainda nao apareceram no replay observado e estao com
  `fixture_or_waiver=static_contract_waiver_until_forced_fixture`.
- Distribuicao dos `57` waivers: `strategy_signal=36`, `renderer_only=9`,
  `technical=4`, `ignored_with_reason=4`, `action_audited=2` e
  `forensic_card_event=2`.
- Primeiros candidatos a fixture forcada: `additional_cost_failed`,
  `spell_countered`, `instant_removal`, `multi_target_resolution`,
  `adventure_cast`, `adventure_creature_cast_from_exile`,
  `board_wipe_resolved`, `extra_turn_taken`, `flashback_cast`,
  `removal_countered_by_ward`, `utility_artifact_activated`,
  `utility_land_activated`, `ward_countered`, `warp_cast` e
  `worldfire_resolved`.
- O latest segue sem alerta high/critical em action findings e sem strategy
  blockers:
  `seeds_with_high_or_critical_action_findings=[]` e
  `seeds_with_strategy_blockers=[]`.

Falha/ajuste registrado:

- `BV-047`: o contrato minimo de eventos esta coberto, mas a cobertura por
  replay forcado ainda nao prova todos os emissores raros. Para learning-grade,
  os eventos action/forensic/strategy que hoje estao em waiver precisam de
  fixtures que gerem JSONL real e passem pelos consumidores esperados.

## Passo de auditoria - effect coverage priority 2026-06-19T17:16Z

Artefatos:

- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_priority_audit_20260619_171605.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/effect_coverage_priority_171605/effect_coverage_priority.json`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_171605/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_171605/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_171605/unknown_template_backlog.json`

Estado verificado:

- `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["effect_coverage=review_required"]`
- `action_findings=0`
- `strategy_findings=0`
- `decision_audit_decision_findings=0`
- listas high/critical/blocker vazias:
  `seeds_with_high_or_critical_action_findings=[]`,
  `seeds_with_strategy_blockers=[]`,
  `seeds_with_high_or_critical_decision_audit_findings=[]` e
  `seeds_with_high_or_critical_forensic_findings=[]`.

Achado principal:

- O gate de `unknown_template_backlog` ja consegue identificar e planejar o
  backlog atual, mas ainda nao prova suporte executavel: `29` unknown cards,
  `29` com familia revisada, `29` com plano/owner, porem `0/29` com focused
  template match e `plan_status_counts={"template_required": 29}`.
- O gate de `effect_coverage` continua bloqueando a aprovacao do replay:
  `effect_coverage_unknowns=33`, `heuristic_effects=120`,
  `needs_review_rule_names=1457`, `trigger_not_explicit=147`,
  `cast_permission_not_explicit=89`, `temporary_effect_not_explicit=65` e
  `land_utility_ability_not_modeled=48`.
- Prioridade por deck: `Magda` (`48` flagged, `8` unknown), `Yorion` (`40`
  flagged, `8` unknown), `Urza` (`36` flagged, `5` unknown), `Ishai` (`37`
  flagged, `2` unknown) e `Akiri` (`36` flagged, `2` unknown).
- Isso confirma que o fluxo de auditoria esta funcionando melhor que antes,
  mas a logica de battle ainda nao deve ser tratada como learning-grade para
  todas as acoes reais de cartas.

Avaliar / ajustar:

- Implementar templates focados, fixtures executaveis ou waivers aceitos para
  os `29` unknowns atuais.
- Priorizar familias que cobrem varias lacunas de regra: `Hidden Strings`,
  `Submerge`, `Stoke the Flames`, `Sudden Shock`, `Tragic Arrogance`,
  `Cryptic Coat`, `God-Pharaoh's Statue`, `Candelabra of Tawnos` e
  `Firestorm`.
- Para flags de timing/trigger/permissao, exigir no evento/decision trace:
  fonte do trigger, janela de cast permission, duracao do efeito temporario,
  alvo, objeto de stack quando existir e resultado.

Conferencia posterior:

- Enquanto esta anotacao era fechada, o `latest` avancou para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172250/summary.json`.
- A rodada `20260619_172250` manteve o mesmo diagnostico central:
  `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["effect_coverage=review_required"]`,
  `effect_coverage_unknowns=33`, `heuristic_effects=120`,
  `needs_review_rule_names=1457` e
  `unknown_template_without_focused_template_match=29`.
- Tambem manteve vazias as listas de alerta:
  `seeds_with_high_or_critical_action_findings=[]` e
  `seeds_with_strategy_blockers=[]`.

## Tratativas fechadas - 2026-06-19T17:28:42Z

Tratativa aplicada para `BV-032`, `BV-033`, `BV-041` e `BV-046`:

- Adicionados contratos `supports_*_template` focados em
  `server/bin/manaloom_battle_rule_focused_evidence.py` para as familias do
  backlog atual, incluindo `tap_untap_cipher_trigger`,
  `alternative_cost_library_bounce`, `convoke_damage`, `split_second_damage`,
  `modal_mass_sacrifice_selection`, `manifest_cloak_equipment`,
  `utility_artifact_untap_x_lands`, `additional_cost_discard_multi_target_damage`,
  `static_tax_and_opponent_life_loss`, `static_noncreature_tax`,
  `copy_artifact_static_as_enters`, `phase_out_mass_removal_counters`,
  `vanishing_sacrifice_trigger_removal` e demais familias revisadas.
- `battle_unknown_template_backlog_audit.py` agora calcula match usando a uniao
  da familia inferida corrente com a familia revisada do plano. Isso cobre casos
  em que a inferencia ainda e generica, como `Clown Car`, mas o review ja
  definiu familia estreita.
- Itens que deixam de faltar template passam de `template_required` para
  `focused_template_ready`.
- O status global do auditor agora so fica pronto como
  `focused_template_backlog_ready` quando `without_focused_template_match=0`.
- O gate recorrente `unknown_template_backlog` no wrapper agora falha/requer
  review se algum card atual ficar sem focused template.
- `test_battle_unknown_template_backlog_audit.py` foi ampliado para falhar se
  representantes do backlog atual ficarem sem focused template, incluindo
  `Hidden Strings`, `Submerge`, `Stoke the Flames`, `Sudden Shock`,
  `Tragic Arrogance`, `Cryptic Coat`, `Candelabra of Tawnos` e `Firestorm`.

Evidencia da rodada oficial:

- Run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172842`
- Summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172842/summary.json`
- Auditoria de backlog:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172842/unknown_template_backlog.md`
  e
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172842/unknown_template_backlog.json`
- `unknown_template_backlog_status=focused_template_backlog_ready`
- `unknown_template_backlog_cards=29`
- `unknown_template_with_focused_template_match=29`
- `unknown_template_without_focused_template_match=0`
- `unknown_template_with_plan_or_waiver=29`
- `unknown_template_without_plan_or_waiver=0`
- `unknown_template_plan_status_counts={"focused_template_ready":29}`
- `unknowns_without_template=[]`
- `mandatory_gate_statuses.unknown_template_backlog.status=pass`

IDs removidos de `Achados abertos` por tratativa + evidencia:

- `BV-032`: o backlog atual deixou de ter `0/29` matches; a rodada
  `20260619_172842` mostra `29/29` focused template matches.
- `BV-033`: o teste dedicado agora inclui representantes do backlog atual e
  falha quando eles nao batem em focused template.
- `BV-041`: o gate recorrente passou a usar focused templates como criterio de
  passagem e esta `pass` com `without_focused_template_match=0`.
- `BV-046`: o manifesto por carta agora mostra `focused_template_ready` para os
  `29` cards e `unknowns_without_template=[]`.

Escopo que permanece aberto:

- `BV-011` e `BV-039` nao foram fechados: `effect_coverage` ainda diverge com
  `unknown_effect=33` e demais flags de timing/trigger/permissao/heuristica.
  Esta tratativa cobre focused evidence/backlog, nao resolve todo o contrato de
  efeitos do engine.

Validacoes executadas e aprovadas:

- `python3 -m py_compile server/bin/manaloom_battle_rule_focused_evidence.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py --coverage-json /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json --output /tmp/unknown_template_probe.md --json-output /tmp/unknown_template_probe.json --fail-on-unplanned`
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`

## Tratativa parcial - effect coverage unknowns 2026-06-19T17:32:13Z

Tratativa aplicada:

- `battle_effect_coverage_audit.py` passou a reconhecer cartas `source=unknown`
  que possuem focused template como `source=focused_template_ready`.
- O coverage remove apenas o flag `unknown_effect` desses cards; os demais
  riscos continuam visiveis para nao mascarar heuristicas, triggers, permissoes
  de cast, duracao de efeitos temporarios, terrenos utilitarios ou regras
  `needs_review`.
- O relatorio agora lista `focused_template_cards` com o template que justificou
  cada contrato focado.

Evidencia da rodada oficial:

- Run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_173213`
- Summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_173213/summary.json`
- Coverage:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_173213/effect_coverage.json`
- `effect_coverage_unknowns=0`
- `source_totals.focused_template_ready=33`
- `unknown_cards=[]`
- `focused_template_cards=29`
- `unknown_template_backlog.status=focused_template_backlog_ready`
- `mandatory_gate_statuses.unknown_template_backlog.status=pass`

Escopo que permanece aberto:

- `effect_coverage` ainda diverge por riscos nao-unknown:
  `heuristic_effects=120`, `trigger_not_explicit=147`,
  `cast_permission_not_explicit=89`, `temporary_effect_not_explicit=65`,
  `land_utility_ability_not_modeled=48` e `needs_review_rule_names=1457`.
- Por isso `BV-011` e `BV-039` seguem abertos, mas sem pendencia de
  `unknown_effect`.

Validacoes executadas e aprovadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --output /tmp/effect_coverage_probe.md --json-output /tmp/effect_coverage_probe.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 786135854`

## Passo de auditoria - focused template dispatch gap 2026-06-19T17:32Z

Artefatos:

- `docs/hermes-analysis/master_optimizer_reports/battle_focused_template_dispatch_gap_audit_20260619_173213.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/focused_template_dispatch_gap_173213/focused_template_dispatch_gap.json`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_173213/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_173213/effect_coverage.json`
- `server/bin/manaloom_battle_rule_focused_evidence.py`

Resumo:

- `effect_coverage_unknowns=0` e `source_totals.focused_template_ready=33`
  significam que os `29` cards antes unknown agora tem familia/template
  revisado no coverage.
- Isso ainda nao prova focused evidence executavel: o arquivo
  `manaloom_battle_rule_focused_evidence.py` tem `47` predicados
  `supports_*_template`, mas `evaluate_draft(...)` despacha apenas `21`.
- Os `29` cards `focused_template_ready` atuais batem em predicados da
  superficie nao despachada.
- Ao chamar `evaluate_draft(...)` para esses `29` cards, todos retornaram
  `status=unsupported` e
  `reason=no_focused_evidence_template_for_effect_family`.
- Resultado medido:
  `focused_template_cards_with_match=29`,
  `focused_template_cards_with_dispatchable_match=0`,
  `focused_template_cards_without_dispatchable_match=29` e
  `evidence_runner_status_counts={"unsupported":29}`.

Falha/ajuste registrado:

- `BV-048`: o gate precisa separar `template_predicate_match`,
  `evidence_dispatch_ready` e `focused_evidence_ready`. Enquanto isso nao
  acontecer, `focused_template_ready` e `effect_coverage_unknowns=0` podem
  superestimar a prontidao real dos templates de acao de carta.

## Passo de auditoria - latest blockers/effect residual 2026-06-19T17:34Z

Artefatos:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_blockers_effect_residual_audit_20260619_173448.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/latest_blockers_effect_residual_173448/latest_blockers_effect_residual.json`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_173448/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_173448/effect_coverage.json`

Resumo:

- O `latest` oficial resolve para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_173448`.
- `battle_replay_final_status=blocked`.
- `mandatory_gate_divergences=["action_critic=blocked",
  "effect_coverage=review_required", "forensic_audit=blocked",
  "strategy_audit=review_required"]`.
- `action_findings=1`, com high/critical em seed `63201749`.
- `strategy_findings=3`, sem `seeds_with_strategy_blockers`.
- `forensic_audit` tem high/critical nas seeds `63201736` e `63201744`.
- `effect_coverage_unknowns=0`, mas `heuristic_effects=120` e coverage ainda
  esta `review_required`.

High/critical que exige alerta:

- `BV-049`: seed `63201749`, turno `5`, `action-000109`,
  `replacement_applied`, label `prevention:life_total_cant_change`,
  `replacement_without_zone_or_object_metadata`.
- `BV-050`: seed `63201736`, turno `2`, `Veil of Summer`,
  `spell_resolved/draw_cards` dependente de `functional_tags_json`.
- `BV-050`: seed `63201744`, turno `1`, `Veil of Summer`,
  `spell_resolved/draw_cards` dependente de `functional_tags_json`.

Strategy review, sem blocker:

- `BV-051`: seeds `63201739`, `63201740` e `63201741` tiveram
  `forced_keep_after_bad_mulligan` por `negative_keep_score` e
  `no_early_game_plan`; esses replays nao devem alimentar conclusao de WR com
  alta confianca.

Residual de effect coverage que permanece aberto:

- `runtime_safe_rule_names=1702`, `needs_review_rule_names=1457`.
- `source_totals`: `battle_rule_curated=724`, `type_land=377`,
  `effect_map=100`, `battle_rule_needs_review_generated=34`,
  `focused_template_ready=33`, `tag=20`.
- `flag_totals`: `trigger_not_explicit=147`, `heuristic_effect=120`,
  `cast_permission_not_explicit=89`, `temporary_effect_not_explicit=65`,
  `land_utility_ability_not_modeled=48`, `needs_review_rule=34`,
  `oracle_target_removal_mismatch=20`, `oracle_silence_mismatch=15`,
  `copy_effect_mismatch=1`.
- Decks com maior pressao residual: `Lumra=52`, `Magda=51`, `Akiri=44`,
  `Ishai=44`, `Kinnan=44`, `Gwen=43`, `Sisay=41`, `Kenrith=40`.

Falhas/ajustes registrados:

- `replacement_applied` precisa emitir objeto afetado, zona origem, zona
  destino, fonte/regra de substituicao e valor impedido/substituido.
- Eventos forensic gerados por `functional_tags_json` precisam ser promovidos
  para `card_battle_rules` verificado/ativo ou virar waiver auditavel antes de
  serem usados como sinal confiavel de aprendizagem.
- `effect_coverage_unknowns=0` nao fecha cobertura battle: triggers, permissoes
  de cast, efeitos temporarios, terrenos utilitarios, regras `needs_review` e
  heuristicas ainda precisam de fixture, handler ou waiver aceito.

## Passo de auditoria - focused dispatch oficial/latest 2026-06-19T17:44Z

Artefatos:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_focused_dispatch_forensic_audit_20260619_174452.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_174452/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_174452/seed_63201744/forensic_audit.json`

Fonte principal:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_174452/summary.json`

Resumo:

- O `latest` oficial agora resolve para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_174452`.
- `battle_replay_final_status=blocked`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`.
- `mandatory_gate_divergences=["focused_template_dispatch=review_required",
  "forensic_audit=blocked"]`.
- `action_findings=0`, `strategy_findings=0` e
  `decision_audit_decision_findings=0`.
- `seeds_with_high_or_critical_forensic_findings=["63201744"]`.

Leitura de template dispatch:

- `focused_template_dispatch` agora aparece como gate obrigatorio oficial no
  `summary.json`, nao apenas como auditoria paralela.
- `focused_template_cards=29`.
- `template_predicate_match=29` e `without_template_predicate_match=0`.
- `supports_template_count=47`, `evaluate_dispatch_template_count=21` e
  `build_evidence_function_count=21`.
- `evidence_dispatch_ready=0`, `without_evidence_dispatch=29`,
  `focused_evidence_ready=0`, `focused_evidence_not_ready_unwaived=29`,
  `accepted_waivers=0`.
- `evidence_runner_status_counts={"unsupported":29}`.
- Existem `26` predicados `supports_*_template` que nao sao despachados por
  `evaluate_draft(...)`, incluindo familias de additional/alternative cost,
  copy, manifest/cloak, static tax, impulse/topdeck, cipher, split second,
  convoke e mass sacrifice.

Leitura forensic:

- `forensic_audit.status=blocked`, `forensic_rule_findings=5`,
  `forensic_severity_counts={"high":1,"medium":2,"low":2}`.
- High atual: seed `63201744`, turno `1`, `Veil of Summer`,
  `spell_resolved/draw_cards`, fonte `functional_tags_json`.
- Medias relacionadas: `Veil of Summer` em `spell_cast` e
  `Reckless Barbarian` em `spell_cast`, ambas por `functional_tags_json`.
- Linhagem segue incompleta: `forensic_card_event_count=164`,
  `card_id_present/missing=118/46`, `semantic_hash_present/missing=118/46`,
  `rule_logical_key_present/missing=160/4`.

Leitura de coverage residual:

- `effect_coverage.status=pass` e
  `effect_coverage_residual_status=effect_coverage_residual_accepted`.
- Isso nao prova runtime completo: `effect_coverage_residual_raw_flag_total=539`
  e `effect_coverage_residual_card_flag_rows=293`; o que mudou foi que todos
  os residuais tem owner/contrato aceito (`raw_unaccepted_flags=[]`).

Falha documental nova:

- `BATTLE_REPLAY_GATE_MATRIX.md` esta marcado como `current` no indice de docs,
  mas sua lista de gates obrigatorios ainda documenta apenas
  `action_critic`, `strategy_audit`, `replay_decision_audit`,
  `forensic_audit` e `effect_coverage`.
- O `summary.json` atual exige tambem `focused_template_dispatch`,
  `unknown_template_backlog`, `decision_trace_taxonomy` e
  `event_contract_static`.
- `BV-052`: a matriz de gates/status docs precisa ser atualizada para nao
  induzir agentes futuros a uma conclusao de prontidao incompleta.

## Sanity check latest - 2026-06-19T17:46Z

Durante a validacao final desta rodada, o ponteiro `latest` avancou para:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_174618`

Leitura do `summary.json` atual:

- `battle_replay_final_status=blocked`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`.
- `mandatory_gate_divergences=["focused_template_dispatch=review_required",
  "forensic_audit=blocked", "strategy_audit=review_required"]`.
- `action_findings=0`.
- `strategy_findings=3`,
  `strategy_code_counts={"forced_keep_after_bad_mulligan":3}` e sem
  `seeds_with_strategy_blockers`.
- `focused_template_dispatch_status=review_required`,
  `focused_template_cards=29`, `focused_template_evidence_ready=0`,
  `focused_template_evidence_not_ready_unwaived=29` e
  `focused_template_evidence_runner_status_counts={"unsupported":29}`.
- `forensic_rule_findings=17`,
  `forensic_severity_counts={"high":2,"medium":5,"low":10}`,
  `seeds_with_high_or_critical_forensic_findings=["63201736","63201744"]`.
- Linhagem forensic continua incompleta:
  `forensic_card_event_count=1512`, `forensic_card_id_missing=541`,
  `forensic_semantic_hash_missing=541`,
  `forensic_rule_logical_key_missing=18`.

Este sanity check nao altera os achados novos desta rodada; ele confirma que:

- `BV-048` segue aberto no latest oficial.
- `BV-050` segue aberto e voltou a incluir as seeds `63201736` e `63201744`.
- `BV-051` segue aberto como review de confianca estrategica, sem blocker.
- `BV-052` segue valido porque o latest confirma gates obrigatorios que a matriz
  current ainda nao lista.

## Sanity check latest - 2026-06-19T17:52Z

O ponteiro `latest` avancou novamente para:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175202`

Leitura do `summary.json` atual:

- `battle_replay_final_status=review_required`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`.
- `mandatory_gate_divergences=["focused_template_dispatch=review_required"]`.
- `action_findings=0`, `strategy_findings=0`, `forensic_rule_findings=0`.
- `seeds_with_high_or_critical_action_findings=[]`.
- `seeds_with_strategy_blockers=[]`.
- `seeds_with_high_or_critical_forensic_findings=[]`.
- `focused_template_dispatch.status=review_required`,
  `focused_template_cards=29`, `template_predicate_match=29`,
  `evidence_dispatch_ready=0`, `focused_evidence_ready=0`,
  `focused_evidence_not_ready_unwaived=29` e
  `evidence_runner_status_counts={"unsupported":29}`.
- `forensic_lineage_status=incomplete` permanece, mesmo sem findings:
  `forensic_card_id_missing=42`, `forensic_semantic_hash_missing=42`,
  `forensic_rule_logical_key_missing=0`.

Leitura operacional atual:

- Nao ha alerta atual de high/critical em action findings nem strategy blocker.
- O unico gate divergente atual e `focused_template_dispatch`.
- `BV-048` e o achado ativo mais importante no latest.
- `BV-050` deixa de ser alerta atual no `175202`, mas permanece no register como
  falha historica/intermitente e como lacuna de linhagem enquanto
  `forensic_lineage_status=incomplete`.

## Passo de auditoria - runtime surface fora do recorrente 2026-06-19T17:54Z

Artefatos:

- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_outside_recurring_audit_20260619_175415.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175415/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175415/summary.json`

Resumo do latest verificado:

- `battle_replay_final_status=review_required`.
- `mandatory_gate_divergences=["focused_template_dispatch=review_required"]`.
- Nao ha high/critical atual em action, strategy blocker ou forensic.
- `focused_template_dispatch` continua o unico gate divergente atual.

Resumo do manifesto de superficie:

- `runtime_surface_manifest_total_files=108`.
- `runtime_surface_manifest_unclassified_files=0`.
- `automation_coverage_counts={"covered_by_recurring_run":29,
  "imported_by_core_runtime":6,"outside_recurring_run":73}`.
- `gate_expected_counts={"recurring_audit_required":29,
  "core_runtime_import_regression":6,
  "targeted_manual_gate_required_before_change":31,
  "targeted_test_required_before_change":42}`.
- Arquivos fora do recorrente por categoria:
  `core runtime=23`, `focused evidence/promotion=4`,
  `learned-deck source=14`, `optimizer/scorecard=15`, `renderer=2`,
  `review queue=1`, `rule registry/sync=14`.

Leitura operacional:

- A automacao recorrente cobre os gates obrigatorios do replay e parte do core,
  mas nao prova sozinha a prontidao de todos os arquivos battle.
- Qualquer mudanca futura em core runtime test-only, focused evidence/promotion,
  review queue, rule registry/sync, learned-deck source, optimizer/scorecard ou
  renderer precisa do gate direcionado indicado no manifesto.
- `summary.json` limpo ou `review_required` por apenas um gate nao deve ser lido
  como prova global de que todo o fluxo battle esta validado.

Testes fora do recorrente executados nesta rodada e aprovados:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_targeting_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_combat_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_permanents_complex_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`
- `python3 server/bin/test_auto_promote_battle_rules.py`
- `python3 server/bin/test_battle_runtime_cli_paths.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_audit_multi_rule_runtime_readiness.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_learned_deck_completeness.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_materialize_learned_deck_to_deck_cards.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_universal_optimizer_known_cards.py`

Falha/ajuste registrado:

- `BV-053`: sucesso da automacao recorrente nao prova a superficie battle
  inteira; o register precisa exigir gate direcionado para qualquer area fora
  do recorrente antes de aceitar conclusao de prontidao ampla.

## Sanity check latest - 2026-06-19T17:55Z

O ponteiro `latest` avancou para:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175500`

Leitura do `summary.json` atual:

- `battle_replay_final_status=review_required`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`.
- `mandatory_gate_divergences=["focused_template_dispatch=review_required",
  "forensic_audit=review_required", "strategy_audit=review_required"]`.
- `action_findings=0`.
- `strategy_findings=3`, todos `medium`,
  `strategy_code_counts={"forced_keep_after_bad_mulligan":3}`.
- `forensic_rule_findings=8`,
  `forensic_severity_counts={"medium":2,"low":6}`.
- `focused_template_evidence_not_ready_unwaived=29`.
- `seeds_with_high_or_critical_action_findings=[]`.
- `seeds_with_strategy_blockers=[]`.
- `seeds_with_high_or_critical_forensic_findings=[]`.

Detalhe dos reviews nao bloqueantes:

- Strategy medium: seeds `63201739`, `63201740` e `63201741` repetem
  `forced_keep_after_bad_mulligan`.
- Forensic medium: seed `63201738` com `Moonsnare Prototype` e seed
  `63201739` com `Sacrifice`, ambos por fonte heuristica
  `functional_tags_json`.
- Forensic low: seeds `63201740`, `63201741` e `63201745` com
  `Rise of the Eldrazi`, em que runtime `remove_permanent` difere de registry
  `extra_turn`.

Leitura operacional:

- Nao ha alerta atual de high/critical em action findings nem strategy blocker.
- O run ainda nao e trusted; continua review-required por focused dispatch,
  strategy confidence e forensic review.

## Passo de auditoria - focused template missing builders 2026-06-19T17:55Z

Artefatos:

- `docs/hermes-analysis/master_optimizer_reports/battle_focused_template_missing_builder_priority_audit_20260619_175500.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175500/focused_template_dispatch.json`
- `server/bin/manaloom_battle_rule_focused_evidence.py`

Resumo:

- `focused_template_cards=29`.
- `template_predicate_match=29`.
- `without_template_predicate_match=0`.
- `supports_template_count=47`.
- `evaluate_dispatch_template_count=21`.
- `build_evidence_function_count=21`.
- `evidence_dispatch_ready=0`.
- `focused_evidence_ready=0`.
- `focused_evidence_not_ready_unwaived=29`.
- `accepted_waivers=0`.
- `evidence_runner_status_counts={"unsupported":29}`.

Leitura tecnica:

- Os `29` cards nao estao sem classificacao; todos tem predicado de template.
- Nenhum desses predicados atuais esta ligado a builder em `evaluate_draft(...)`.
- O gap atual e de `builder/dispatch/evidence`, nao mais de deteccao da familia.

Concentracao por familia:

- `supports_manifest_cloak_equipment_template`: `3` cards (`Cryptic Coat`,
  `Cursed Windbreaker`, `Dissection Tools`).
- `supports_impulse_topdeck_or_library_zone_template`: `2` cards
  (`Heroes' Hangout`, `Opera Love Song`).
- Outras `24` familias aparecem com `1` card cada, incluindo additional/
  alternative cost, convoke, copy, static tax, split second, phase out,
  vanishing, cipher, type-change, named restriction e mass sacrifice.

Concentracao por deck:

- `Yorion, Sky Nomad #38 (real)`: `8` cards.
- `Magda, Brazen Outlaw #71 (real)`: `8` cards.
- `Urza, Lord High Artificer #87 (real)`: `5` cards.
- Demais decks tem `1-2` cards cada.

Falha/ajuste registrado:

- `BV-054`: o backlog de focused templates precisa ser fechado por matriz de
  familia/card/fixture/waiver. A proxima leitura de prontidao nao deve aceitar
  "29 unsupported" como numero generico sem priorizacao de builder.

## Sanity check latest - 2026-06-19T17:59Z

O ponteiro `latest` avancou para:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911`

Leitura do `summary.json` atual:

- `battle_replay_final_status=review_required`.
- `mandatory_gate_divergences=["focused_template_dispatch=review_required",
  "forensic_audit=review_required", "strategy_audit=review_required"]`.
- `action_findings=0`.
- `strategy_findings=3`.
- `forensic_rule_findings=8`.
- `focused_template_dispatch_status=review_required`.
- `focused_template_evidence_not_ready_unwaived=29`.
- `seeds_with_high_or_critical_action_findings=[]`.
- `seeds_with_strategy_blockers=[]`.
- `seeds_with_high_or_critical_forensic_findings=[]`.

Leitura operacional:

- Nao ha alerta atual de high/critical em action findings nem strategy blocker.
- O estado mais recente continua `review_required`; `BV-048`, `BV-050`,
  `BV-051` e `BV-054` seguem relevantes.

## Tratativa - replacement lineage, strategy confidence e docs 2026-06-19T17:59Z

Artefatos:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/seed_63201749/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/seed_63201749/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/seed_63201739/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/seed_63201740/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/seed_63201741/strategy_audit.json`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`

Resumo:

- `replacement_applied` agora emite `original_amount`, `final_amount`,
  `original_delta`, `final_delta`, `replacement_rule_source` e
  `replacement_rule_sources`; no caso `prevention:life_total_cant_change` da
  seed `63201749`, o JSONL mostra `original_amount=4`, `final_amount=0`,
  `original_delta=-4`, `final_delta=0`,
  `replacement_rule_source=Teferi's Protection` e
  `source=Teferi's Protection`.
- O run equivalente `20260619_175911` ficou com `action_findings=0`,
  `action_verdict_counts={"ok":5891}` e
  `seeds_with_high_or_critical_action_findings=[]`.
- O strategy auditor agora separa confiança de aprendizagem. O mesmo run mostra
  `strategy_learning_confidence_counts={"high_confidence_replay":13,
  "low_confidence_replay":3}`, `strategy_low_confidence_seeds=["63201739",
  "63201740","63201741"]` e
  `strategy_high_confidence_learning_seeds` com os outros `13` seeds.
- `BATTLE_REPLAY_GATE_MATRIX.md` e o indice de docs foram atualizados para os
  gates obrigatorios atuais e para a leitura correta de
  `effect_coverage_residual_accepted`, `focused_template_dispatch` e
  `runtime_surface_manifest.json`.
- Para esta tratativa, a evidencia por area ficou separada: runtime/replacement
  por `test_battle_analyst_v10_3.py` e action critic; strategy auditor por
  `test_battle_decision_strategy_auditor.py`; docs por `git diff --check`; e
  estado agregado pelo recorrente `20260619_175911`.

Validacoes executadas e aprovadas:

- `python3 -m py_compile battle_replacement_support.py battle_action_critic.py test_battle_action_critic.py battle_replay_v10_3.py battle_analyst_v9.py test_battle_analyst_v10_3.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
- `python3 -m py_compile battle_decision_strategy_auditor.py test_battle_decision_strategy_auditor.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py`
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `MANALOOM_BATTLE_STRATEGY_SEEDS=16 /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 16 --start-seed 63201734`
- `git diff --check -- docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`

Fechamentos:

- `BV-049`: fechado por contrato de `replacement_applied` enriquecido,
  fixture/regressao e run equivalente sem high/critical action.
- `BV-051`: fechado porque forced keeps ruins agora ficam em bucket de baixa
  confianca e nao contam como amostras high-confidence.
- `BV-052`: fechado porque a matriz e o indice documentam todos os gates
  obrigatorios atuais.
- `BV-053`: fechado para o registro atual porque este bloco declara, por area
  alterada, se a evidencia veio do recorrente, de teste direcionado, de import
  regression ou de doc check; nenhuma conclusao "battle completo" aqui usa
  apenas a automacao recorrente.

## Passo de auditoria - focused template builder contract 2026-06-19T18:01Z

Artefato gerado:

- `docs/hermes-analysis/master_optimizer_reports/battle_focused_template_builder_contract_audit_20260619_180140.md`

Evidencia consultada:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/focused_template_dispatch.json`
- `server/bin/manaloom_battle_rule_focused_evidence.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py`

Resultado:

- `supports_template_count=47`, mas somente `21` supports estao roteados em
  `evaluate_draft(...)`.
- `build_evidence_function_count=21`.
- Existem `26` `supports_*_template` sem dispatch.
- Os `29` cards atuais com `focused_template_ready` caem exatamente nessas
  familias sem dispatch/evidence.
- Para os `29` cards atuais, o builder esperado por nome nao existe, a rota em
  `evaluate_draft(...)` nao existe e `evidence_runner_status=unsupported`.

Leitura operacional: os templates de acao de carta ainda nao estao criados para
o backlog atual. O que existe hoje e triagem/predicado de familia
(`supports_*_template`); o que falta e builder executavel
(`build_*_evidence`), rota em `evaluate_draft(...)`, fixture/replay focado e
waiver aceito quando a familia nao for implementada.

Impacto em achados:

- `BV-048`: permanece P1 porque `template_predicate_match=29` nao prova
  evidence executavel; `evidence_dispatch_ready=0` e
  `focused_evidence_ready=0`.
- `BV-054`: ganha matriz por carta/familia/builder esperado; a priorizacao deve
  comecar por `manifest_cloak_equipment` (`3` cartas),
  `impulse_topdeck_or_library_zone` (`2` cartas), depois decks com maior
  pressao (`Yorion=8`, `Magda=8`, `Urza=5`).
- `BV-055`: novo achado explicito para impedir que "support predicate criado"
  seja lido como "template de acao implementado".

Validacoes executadas:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_focused_template_dispatch_audit.py`
  - PASS, `3 tests passed`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py --coverage-json /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json --output /tmp/focused_template_dispatch_probe.md --json-output /tmp/focused_template_dispatch_probe.json --fail-on-not-ready`
  - exit `1` esperado; `status=review_required`,
    `focused_template_cards=29`, `evidence_dispatch_ready=0`,
    `focused_evidence_ready=0`,
    `focused_evidence_not_ready_unwaived=29` e
    `evidence_runner_status_counts={"unsupported":29}`.

## Passo de auditoria - strategy e forensic gates latest 2026-06-19T18:12Z

Artefato gerado:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_strategy_forensic_gate_audit_20260619_1812.md`

Evidencia consultada:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/summary.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/research_review.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/seed_*/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/seed_*/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/seed_*/replay.decision_trace.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/seed_*/replay.events.jsonl`

Resultado strategy:

- `strategy_audit.status=review_required`.
- `strategy_findings=3`, todos `medium` e todos
  `forced_keep_after_bad_mulligan`.
- Seeds afetadas: `63201739`, `63201740`, `63201741`.
- `strategy_learning_confidence_counts={"high_confidence_replay":13,"low_confidence_replay":3}`.
- `seeds_with_strategy_blockers=[]`.
- As tres decisoes problemáticas sao forced keep apos mulligan cap, com keep
  score negativo e `high_confidence_learning_weight=0.0`.

Resultado forensic:

- `forensic_audit.status=review_required`.
- `forensic_rule_findings=8`: `2` medium e `6` low.
- Medium: `Moonsnare Prototype` seed `63201738` e `Sacrifice` seed
  `63201739`, ambos por fonte heuristica `functional_tags_json`.
- Low: `Rise of the Eldrazi` em seeds `63201740`, `63201741` e `63201745`,
  por divergencia runtime `remove_permanent` vs registry `extra_turn`.
- Linhagem agregada: `card_event_count=1487`, `card_id_missing=534`,
  `semantic_hash_missing=534` e `rule_logical_key_missing=18`.
- `forensic_lineage_status=incomplete`.

Leitura operacional:

- Nao ha alerta atual de high/critical em action findings nem strategy blocker.
- O status segue `review_required` porque a estrategia tem tres amostras
  low-confidence e o forensic ainda tem fonte heuristica e linhagem incompleta.
- `BV-050` permanece P1 e agora tem denominador agregado de linhagem.
- `BV-056` foi aberto para garantir que consumidores de aprendizado/WR nunca
  usem os `3` seeds low-confidence como amostras high-confidence.

Validacoes executadas:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py`
  - PASS, `15` testes.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`
  - PASS, `6` testes.
- `git diff --check -- docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md docs/hermes-analysis/master_optimizer_reports/battle_latest_strategy_forensic_gate_audit_20260619_1812.md`
  - PASS.

## Tratativa parcial - focused builders prioritarios 2026-06-19T18:16Z

Artefatos:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_181408_delta_audit_20260619_1816.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_181408/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_181408/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_181408/focused_template_dispatch_artifacts/cryptic-coat/focused_artifacts/focused_template_dispatch_audit/focused_test.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_181408/focused_template_dispatch_artifacts/heroes-hangout/focused_artifacts/focused_template_dispatch_audit/focused_test.json`
- `server/bin/manaloom_battle_rule_focused_evidence.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_focused_template_dispatch_audit.py`

Tratativa aplicada:

- Criados builders focused de contrato para as duas familias compartilhadas de
  maior prioridade em `BV-054`:
  `supports_manifest_cloak_equipment_template` e
  `supports_impulse_topdeck_or_library_zone_template`.
- As duas rotas foram ligadas em `evaluate_draft(...)`.
- Cada builder escreve `focused_test.json`, `replay_events.jsonl`,
  `decision_trace.jsonl` e `replay_audit.json`, e roda
  `replay_decision_auditor` nos artefatos gerados.
- Os artefatos sao explicitamente `promotion_gate_still_required=true`; eles
  reduzem o gap de dispatch/evidencia focused, mas nao promovem regra para
  runtime completo nem encerram cobertura battle global.

Resultado no run oficial `20260619_181408`:

- `battle_replay_final_status=review_required`.
- `mandatory_gate_divergences=["focused_template_dispatch=review_required",
  "strategy_audit=review_required"]`.
- `focused_template_dispatch.status=review_required`.
- `focused_template_cards=29`.
- `evidence_dispatch_ready=5`.
- `focused_evidence_ready=5`.
- `focused_evidence_not_ready_unwaived=24`.
- `evidence_runner_status_counts={"evidence_ready":5,"unsupported":24}`.
- Cards que passaram a ter evidencia focused: `Cryptic Coat`,
  `Cursed Windbreaker`, `Dissection Tools`, `Heroes' Hangout` e
  `Opera Love Song`.
- `forensic_audit` passou nesta rodada (`forensic_rule_findings=0`), mas
  `forensic_lineage_status=incomplete`, com `card_event_count=1518`,
  `card_id_missing=530`, `semantic_hash_missing=530` e
  `rule_logical_key_missing=16`.
- `strategy_audit` segue `review_required`, com
  `strategy_learning_confidence_counts={"high_confidence_replay":13,
  "low_confidence_replay":3}` e `strategy_low_confidence_seeds=["63201739",
  "63201740","63201741"]`.

Validacoes executadas:

- `python3 -m py_compile server/bin/manaloom_battle_rule_focused_evidence.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_focused_template_dispatch_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_focused_template_dispatch_audit.py`
  - PASS, `4 tests passed`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py --coverage-json /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json --evidence-output-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/focused-template-dispatch-20260619_181346/artifacts --output /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/focused-template-dispatch-20260619_181346/focused_template_dispatch.md --json-output /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/focused-template-dispatch-20260619_181346/focused_template_dispatch.json`
  - PASS, `evidence_ready=5`, `unsupported=24`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`
  - PASS.
- `MANALOOM_BATTLE_STRATEGY_SEEDS=16 /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 16 --start-seed 63201734`
  - PASS, latest avancou para `20260619_181408`.

Impacto em achados:

- `BV-048`: permanece aberto; o gap caiu de `29` para `24` cards sem
  evidencia focused.
- `BV-054`: permanece aberto; `5/29` cards tem status `evidence_ready`, mas
  ainda ha `24` cards sem builder/waiver.
- `BV-055`: permanece aberto; `evaluate_dispatch_template_count` e
  `build_evidence_function_count` subiram de `21` para `23`, mas ainda ha `24`
  supports relevantes sem dispatch no backlog atual.
- `BV-050`: nao foi fechado; a rodada atual zerou findings forensic, mas a
  linhagem agregada ainda esta `incomplete`.

## Tratativa fechada - strategy confidence consumer 2026-06-19T18:22Z

Artefatos:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_182219/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_182219/research_review.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_182219/research_review.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py`

Tratativa aplicada:

- `battle_decision_research_review.py` agora agrega, renderiza e exporta
  `strategy_learning_confidence_counts`,
  `strategy_high_confidence_learning_seeds`,
  `strategy_low_confidence_seeds` e
  `strategy_not_learning_eligible_seeds` a partir de cada `strategy_audit.json`.
- A regressao cobre explicitamente uma seed `low_confidence_replay` e uma seed
  `high_confidence_replay`, provando que a seed low-confidence nao entra na
  lista high-confidence.
- O wrapper oficial foi executado novamente depois dessa alteracao; o
  `latest/research_review.json` recorrente agora carrega os mesmos campos.

Evidencia no latest oficial `20260619_182219`:

- `strategy_learning_confidence_counts={"high_confidence_replay":13,
  "low_confidence_replay":3}`.
- `strategy_low_confidence_seeds=["63201739","63201740","63201741"]`.
- `strategy_high_confidence_learning_seeds=["63201734","63201735",
  "63201736","63201737","63201738","63201742","63201743","63201744",
  "63201745","63201746","63201747","63201748","63201749"]`.
- `strategy_not_learning_eligible_seeds=[]`.
- `finding_counts={"forced_keep_after_bad_mulligan":3}`.

Validacoes executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py`
  - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py --input-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest --output /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/research-review-20260619_182210/research_review.md --json-output /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/research-review-20260619_182210/research_review.json`
  - PASS, `13` high-confidence e `3` low-confidence.
- `MANALOOM_BATTLE_STRATEGY_SEEDS=16 /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 16 --start-seed 63201734`
  - PASS, latest avancou para `20260619_182219`.

Fechamento:

- `BV-056`: fechado porque tanto o summary recorrente quanto o research review
  recorrente mostram denominador separado e provam que as seeds `63201739`,
  `63201740` e `63201741` nao entram em
  `strategy_high_confidence_learning_seeds`.

## Passo de auditoria - WR/optimizer gate guardrail 2026-06-19T18:25Z

Artefato gerado:

- `docs/hermes-analysis/master_optimizer_reports/battle_strategy_confidence_consumer_audit_20260619_182529.md`

Evidencia consultada:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/research_review.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_baseline.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_confirmation.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_quality_gate.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_handoff.py`
- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_manifest_20260619_1700.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_outside_recurring_audit_20260619_175415.md`

Resultado:

- `BV-056` continua fechado para a superficie recorrente: o summary e o
  research review separam `13` high-confidence e `3` low-confidence, e as seeds
  `63201739`, `63201740` e `63201741` nao entram em
  `strategy_high_confidence_learning_seeds`.
- O latest oficial `20260619_182534` ainda esta
  `battle_replay_final_status=review_required`, agora com
  `mandatory_gate_divergences=["focused_template_dispatch=review_required"]`.
  O `strategy_audit.status` passou a `pass` porque os `3` findings restantes
  sao todos `low_confidence_findings`, com
  `strategy_review_required_findings=0`.
- Nao foi encontrada prova de que os scripts de optimizer/WR consultem
  automaticamente `battle_replay_final_status`, `mandatory_gate_divergences`,
  `strategy_low_confidence_seeds` ou
  `strategy_high_confidence_learning_seeds` antes de apresentar WR, baseline,
  delta ou handoff como evidencia.
- Isto nao prova contaminacao direta dos `3` seeds low-confidence no optimizer;
  prova uma lacuna de guardrail entre a superficie optimizer/scorecard e o gate
  agregado do audit recorrente.

Impacto em achados:

- `BV-057`: novo achado para exigir que WR, baseline, confirmation e handoff
  carreguem status do gate agregado ou waiver explicito de corpus antes de
  serem usados como evidencia final.

## Passo de auditoria - strategy gate semantics 2026-06-19T18:30Z

Artefato gerado:

- `docs/hermes-analysis/master_optimizer_reports/battle_strategy_gate_semantics_audit_20260619_1830.md`

Evidencia consultada:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Resultado:

- Latest oficial atual: `20260619_182534`.
- `battle_replay_final_status=review_required`.
- `mandatory_gate_divergences=["focused_template_dispatch=review_required"]`.
- `mandatory_gate_statuses.strategy_audit.status=pass`.
- `strategy_findings=3`.
- `strategy_low_confidence_findings=3`.
- `strategy_review_required_findings=0`.
- `strategy_learning_confidence_counts={"high_confidence_replay":13,
  "low_confidence_replay":3}`.
- `strategy_low_confidence_seeds=["63201739","63201740","63201741"]`.

Leitura operacional:

- `strategy_findings > 0` nao significa automaticamente
  `strategy_audit=review_required`.
- Forced keep apos mulligan cap, quando isolado, fica como amostra
  low-confidence com peso `0.0`, mas nao segura mais o gate
  `strategy_audit` em review.
- O unico gate que ainda segura o status final no latest atual e
  `focused_template_dispatch`.
- `BV-056` permanece fechado, porque os seeds low-confidence continuam fora de
  `strategy_high_confidence_learning_seeds`.
- A `BATTLE_REPLAY_GATE_MATRIX.md` foi atualizada para refletir essa semantica.

## Tratativa fechada - focused templates e lineage latest 2026-06-19T18:38Z

Artefatos:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_trusted_focused_lineage_audit_20260619_1838.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/focused-template-current-probe-20260619_1836/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/focused-template-current-probe-20260619_1836/focused_template_dispatch.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_183529/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_183529/focused_template_dispatch.json`

Validacao executada:

- Probe targeted de `battle_focused_template_dispatch_audit.py` com
  `--fail-on-not-ready`
  - PASS, `focused_template_dispatch_ready`, `29/29` evidence ready,
    `supports_not_dispatched=[]`.
- Wrapper completo:
  - `MANALOOM_BATTLE_STRATEGY_SEEDS=16 /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 16 --start-seed 63201734`
  - PASS, latest avancou para `20260619_183529`.

Resultado latest `20260619_183529`:

- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `focused_template_dispatch.status=pass`.
- `focused_template_cards=29`.
- `evidence_dispatch_ready=29`.
- `focused_evidence_ready=29`.
- `focused_evidence_not_ready_unwaived=0`.
- `supports_template_count=47`.
- `evaluate_dispatch_template_count=47`.
- `build_evidence_function_count=47`.
- `supports_not_dispatched=[]`.
- `forensic_lineage_status=complete`.
- `forensic_card_id_missing=530`,
  `forensic_card_id_missing_accepted=530`,
  `forensic_card_id_missing_unaccepted=0`.
- `forensic_semantic_hash_missing=530`,
  `forensic_semantic_hash_missing_accepted=530`,
  `forensic_semantic_hash_missing_unaccepted=0`.
- `forensic_rule_logical_key_missing=16`,
  `forensic_rule_logical_key_missing_accepted=16`,
  `forensic_rule_logical_key_missing_unaccepted=0`.
- `forensic_lineage_unaccepted_missing_samples=[]`.
- `strategy_findings=3`,
  `strategy_low_confidence_findings=3`,
  `strategy_review_required_findings=0`.

Fechamentos por evidencia:

- `BV-011`: fechado para o corpus/latest atual; residual de coverage aceito e
  focused dispatch pronto. Os contadores residuais continuam visiveis como
  contexto, nao blocker.
- `BV-039`: fechado para o corpus/latest atual; effect coverage, backlog,
  focused dispatch e gates obrigatorios passaram.
- `BV-048`: fechado; `29/29` focused cards estao `evidence_ready`.
- `BV-050`: fechado; todos os missing de linhagem sao accepted e nao ha missing
  unaccepted.
- `BV-054`: fechado; todos os `29` cards/familias focados tem evidencia.
- `BV-055`: fechado; `supports_not_dispatched=[]` e os contadores subiram para
  `47/47`.

Leitura operacional:

- O battle recorrente atual esta trusted para o corpus/gates cobertos pelo
  wrapper.
- Isto nao encerra o objetivo global de entender 100% do battle: `BV-047`
  continua cobrando fixture depth de branches raros emitíveis. `BV-057` foi
  fechado na tratativa de optimizer guardrail abaixo.

## Tratativa fechada - optimizer gate guardrail 2026-06-19T18:40Z

Artefatos:

- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_baseline.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_confirmation.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_quality_gate.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_handoff.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_183529/summary.json`

Tratativa aplicada:

- `master_optimizer_common.py` agora expoe `load_battle_gate_summary(...)`,
  `battle_gate_report_lines(...)` e `battle_gate_cli_lines(...)`.
- `master_optimizer_baseline.py`, `master_optimizer_quality_gate.py`,
  `master_optimizer_confirmation.py` e `master_optimizer_handoff.py` inserem o
  bloco Markdown `Battle Replay Gate` antes das tabelas de WR/candidato/handoff.
- `slot_optimizer.py` imprime as mesmas chaves do gate em formato chave-valor
  antes de iniciar o scan de WR.
- O bloco inclui `battle_replay_final_status`,
  `battle_replay_final_status_reason`, `mandatory_gate_divergences`,
  `mandatory_gate_statuses`, `strategy_learning_confidence_counts`,
  amostras de `strategy_low_confidence_seeds` e
  `strategy_high_confidence_learning_seeds`,
  `focused_template_dispatch_status`, contadores de focused evidence,
  `forensic_lineage_status` e
  `battle_gate_weight=required_for_optimizer_wr_evidence`.
- Se o `summary.json` do gate estiver ausente, o helper emite
  `battle_replay_final_status=missing_summary` e
  `mandatory_gate_divergences=["battle_gate_summary_missing"]`, evitando que um
  relatorio de WR pareca final sem contexto do gate.

Validacoes executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_baseline.py docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_quality_gate.py docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_confirmation.py docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_handoff.py docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py`
  - PASS, `5` testes.

Fechamento:

- `BV-057`: fechado porque os relatorios/saidas de optimizer/WR citados agora
  carregam automaticamente o gate agregado ou um estado explicito de
  `missing_summary`, com divergencias, amostras high/low-confidence e peso do
  gate antes de qualquer leitura de WR como evidencia final.

## Tratativa fechada - event fixture depth 2026-06-19T18:47Z

Artefatos:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/event-contract-static-fixture-depth-20260619_1840/event_contract_static.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/event-contract-static-fixture-depth-20260619_1840/event_contract_static.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_184721/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_184721/summary.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_184721/event_contract_static.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`

Tratativa aplicada:

- `battle_event_contract_static_audit.py` agora separa
  `observed_in_latest`, `static_contract_accepted_waiver` e
  `static_contract_waiver_until_forced_fixture`.
- Eventos estaticos classificados mas nao observados recebem waiver aceito com
  motivo por classe/consumer. Eventos futuros sem classificacao continuam
  `review_required` e contam como `static_contract_waiver_until_forced_fixture`.
- O wrapper recorrente agrega os contadores de fixture-depth e faz
  `event_contract_static` ficar em review se houver qualquer
  `event_contract_static_waiver_until_forced_fixture`.

Evidencia no latest oficial `20260619_184721`:

- `battle_replay_final_status=trusted_for_strategy_learning`.
- `mandatory_gate_divergences=[]`.
- `event_contract_static_status=event_contract_static_ready`.
- `event_contract_static_observed_event_types_total=53`.
- `event_contract_static_static_event_types_total=94`.
- `event_contract_static_observed_unclassified_total=0`.
- `event_contract_static_static_unclassified_total=0`.
- `event_contract_static_observed_missing_required_fields=0`.
- `event_contract_static_fixture_or_waiver_counts={"observed_in_latest":53,"static_contract_accepted_waiver":44}`.
- `event_contract_static_fixture_accepted_waiver_total=44`.
- `event_contract_static_waiver_until_forced_fixture=0`.
- `event_contract_static_fixture_unaccepted_types=[]`.
- `event_contract_static_fixture_accepted_waiver_reasons={"accepted_explicitly_ignored_event_contract":4,"accepted_forensic_card_event_static_contract_until_observed":2,"accepted_renderer_only_event_no_guardrail_consumer":7,"accepted_strategy_context_signal_static_contract":27,"accepted_technical_ledger_event_no_forced_replay_required":4}`.

Validacoes executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py`
  - PASS, `4` testes.
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py --input-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest --output /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/event-contract-static-fixture-depth-20260619_1840/event_contract_static.md --json-output /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/event-contract-static-fixture-depth-20260619_1840/event_contract_static.json --fail-on-unclassified`
  - PASS.
- `MANALOOM_BATTLE_STRATEGY_SEEDS=16 /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 16 --start-seed 63201734`
  - PASS, latest avancou para `20260619_184721`.

Fechamento:

- `BV-047`: fechado porque o gate recorrente agora mostra
  `static_contract_waiver_until_forced_fixture=0`; todos os eventos estaticos
  nao observados no latest tem waiver aceito explicito por classe/consumer, e
  eventos futuros sem contrato continuam falhando o gate.

## Passo de auditoria - documentation router current 2026-06-19T18:50Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_documentation_router_current_audit_20260619_185036.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md`
- `docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`

Resultado atual do latest no momento da auditoria:

- `timestamp_utc=2026-06-19T18:47:21Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `event_contract_static_waiver_until_forced_fixture=0`.
- `event_contract_static_fixture_unaccepted_types=[]`.
- `seeds_with_high_or_critical_action_findings=[]`.
- `seeds_with_strategy_blockers=[]`.

Evidencia documental:

- `BATTLE_SYSTEM_LOGIC.md` aponta corretamente para este register, para o
  latest `summary.json` e para `BATTLE_REPLAY_GATE_MATRIX.md`, mas ainda
  embute no topo o snapshot antigo `2026-06-19T16:42:53Z` com
  `battle_replay_final_status=review_required`.
- `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` define corretamente que o
  register prevalece em divergencia, omissao ou artefato novo nao listado.
- O mesmo indice ainda nao lista relatorios/artefatos tardios relevantes,
  incluindo o run oficial `20260619_184721`,
  `battle_latest_trusted_focused_lineage_audit_20260619_1838.md`,
  `battle_strategy_gate_semantics_audit_20260619_1830.md`,
  `battle_strategy_confidence_consumer_audit_20260619_182529.md` e
  `battle_event_contract_fixture_depth_current_audit_20260619_184651.md`.
- `LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md` e seguro como
  auditoria cronologica: contem estados antigos `review_required/blocked`, mas
  tambem registra depois o run oficial `20260619_183529` como trusted.

Leitura operacional:

- Isto nao e blocker do engine nem altera o status trusted do latest.
- E uma falha de roteamento documental: um agente futuro pode ler o status
  antigo no topo do doc canonico, ou seguir o indice sem passar pelos relatorios
  tardios, e reabrir perguntas ja fechadas ou perder que `BV-047` agora foi
  fechado por waiver aceito de fixture-depth.

## Passo de auditoria - effect/template residual contract 2026-06-19T18:56Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_effect_template_residual_contract_audit_20260619_185606.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage_residual.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/focused_template_dispatch.json`
- `server/bin/manaloom_battle_rule_focused_evidence.py`

Resultado atual:

- Latest `2026-06-19T18:47:21Z` segue
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, sem high/critical action e sem strategy
  blocker.
- `focused_template_dispatch.status=focused_template_dispatch_ready`.
- `focused_template_cards=29`.
- `focused_evidence_ready=29`.
- `focused_evidence_not_ready_unwaived=0`.
- `supports_template_count=47`,
  `evaluate_dispatch_template_count=47`,
  `build_evidence_function_count=47`,
  `supports_not_dispatched=[]`.
- `effect_coverage_residual_status=effect_coverage_residual_accepted`.
- `effect_coverage_residual_raw_flag_total=539`.
- `effect_coverage_residual_card_flag_rows=293`.
- `effect_coverage_residual_unique_flagged_cards=240`.
- `effect_coverage_residual_unaccepted_card_flag_rows=0`.
- `effect_coverage_residual_raw_unaccepted_flags=[]`.

Leitura operacional:

- Para o backlog focado atual, e correto dizer que os templates estao prontos:
  `29/29` cards tem evidencia e `47/47` supports/build/dispatch estao
  cobertos.
- Para o universo de acoes de carta no corpus, ainda nao e correto dizer
  "todos os templates/acoes estao implementados": existem `293` linhas
  residuais aceitas por contrato, incluindo `90` `heuristic_effect`, `63`
  `trigger_not_explicit`, `35` `cast_permission_not_explicit`, `29`
  `needs_review_rule` e `21` `land_utility_ability_not_modeled`.
- Esses residuais nao bloqueiam o latest porque tem owner/contrato aceito, mas
  tambem nao devem virar evidencia de comportamento card-specific completo.

## Passo de auditoria - runtime surface trusted scope 2026-06-19T19:00Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_trusted_scope_audit_20260619_190005.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/runtime_surface_manifest.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_outside_recurring_audit_20260619_175415.md`

Resultado atual:

- Latest `2026-06-19T18:47:21Z` segue
  `battle_replay_final_status=trusted_for_strategy_learning` e
  `mandatory_gate_divergences=[]`.
- Manifesto atual classifica `108` arquivos Python relacionados a battle, com
  `0` unclassified.
- `automation_coverage_counts={"covered_by_recurring_run":29,
  "imported_by_core_runtime":6,"outside_recurring_run":73}`.
- `gate_expected_counts={"recurring_audit_required":29,
  "core_runtime_import_regression":6,
  "targeted_manual_gate_required_before_change":31,
  "targeted_test_required_before_change":42}`.
- Os `73` arquivos fora do recorrente se dividem em: `core runtime=23`,
  `optimizer/scorecard=15`, `rule registry/sync=14`,
  `learned-deck source=14`, `focused evidence/promotion=4`, `renderer=2` e
  `review queue=1`.

Testes direcionados amostrados e aprovados:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`
  - `18` tests, OK.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py`
  - `5` tests, OK.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_learned_deck_completeness.py`
  - `4` tests, OK.
- `python3 server/bin/test_battle_runtime_cli_paths.py`
  - `5` CLI help checks, PASS.

Leitura operacional:

- `BV-053` permanece fechado porque a gate matrix e este register ja dizem que
  a automacao recorrente nao e cobertura global de todos os arquivos battle.
- A ressalva continua obrigatoria: qualquer mudanca futura em area
  `outside_recurring_run` precisa do `gate_expected` direcionado antes de
  conclusao ampla de readiness.
- A amostra acima aumenta a evidencia corrente, mas nao equivale a cobertura
  completa dos `73` arquivos fora do recorrente.

## Passo de auditoria - decision trace current scope 2026-06-19T19:05Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_decision_trace_current_scope_audit_20260619_190511.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/decision_trace_taxonomy.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/decision_trace_taxonomy.md`
- `docs/hermes-analysis/BATTLE_DECISION_TRACE_TAXONOMY.md`

Resultado atual:

- Latest `2026-06-19T18:47:21Z` segue
  `battle_replay_final_status=trusted_for_strategy_learning`, com
  `mandatory_gate_divergences=[]`, `events=14679` e `decisions=2265`.
- `decision_trace_taxonomy_status=decision_trace_taxonomy_ready`.
- `decision_trace_kinds_total=15`, `decision_trace_kinds_observed=12` e
  `decision_trace_kinds_uncovered=3`.
- `decision_trace_kinds_without_specific_contract=0`,
  `decision_trace_observed_without_specific_contract=0`,
  `decision_trace_contract_findings=0` e
  `decision_trace_missing_required_fields=0`.
- Sem alerta atual: `seeds_with_high_or_critical_action_findings=[]` e
  `seeds_with_strategy_blockers=[]`.

Tipos observados no latest:

- `pass_no_action=1094`, `cast_spell=530`, `combat_attack=237`,
  `mulligan_decision=116`, `lorehold_upkeep_rummage=109`,
  `utility_artifact_activation=93`, `tutor=47`,
  `utility_land_activation=21`, `response=9`, `wheel=6`,
  `saga_chapter_resolution=2`, `board_wipe=1`.

Tipos estaticos nao observados no latest:

- `activated_sacrifice_damage`: waiver aceito de field-contract, mas branch nao
  exercitado neste corpus.
- `attack_trigger_artifact_tutor`: waiver aceito de field-contract, mas branch
  nao exercitado neste corpus.
- `worldfire_reset`: contrato especifico via strategy auditor/fixture, mas
  branch nao exercitado neste corpus.

Leitura operacional:

- O gate atual esta verde: nao ha tipo estatico/observado sem owner, contrato
  especifico ou waiver aceito.
- `decision_trace_taxonomy_ready` nao significa que todos os `15` tipos de
  decisao foram exercitados no latest; significa que os tipos estaticos e
  observados possuem ownership/contrato/waiver.
- `docs/hermes-analysis/BATTLE_DECISION_TRACE_TAXONOMY.md` esta marcado como
  current em `2026-06-19T17:16:23Z`, com run `20260619_171605`,
  `decision_trace_rows=152`, `decision_trace_kinds_observed=10` e
  `decision_trace_kinds_uncovered=5`. O latest atual tem `2265` linhas,
  `12/15` tipos observados e `3` nao cobertos. Logo, esse doc e explicacao de
  contrato, mas nao deve ser usado sozinho como status atual.

## Passo de auditoria - action template denominators 2026-06-19T19:09Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_action_template_denominator_audit_20260619_190955.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage_residual.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/unknown_template_backlog.json`

Resultado atual:

- Latest `2026-06-19T18:47:21Z` segue
  `battle_replay_final_status=trusted_for_strategy_learning`, com
  `mandatory_gate_divergences=[]`.
- Sem alerta atual: `seeds_with_high_or_critical_action_findings=[]` e
  `seeds_with_strategy_blockers=[]`.
- `unknown_template_backlog_status=focused_template_backlog_ready` e
  `unknown_template_backlog_cards=0`.
- `focused_template_dispatch_status=focused_template_dispatch_ready`.
- `focused_template_cards=29`, `focused_template_predicate_match=29`,
  `focused_template_evidence_dispatch_ready=29`,
  `focused_template_evidence_ready=29`,
  `focused_template_evidence_not_ready_unwaived=0`,
  `focused_template_supports_template_count=47`,
  `focused_template_evaluate_dispatch_template_count=47` e
  `focused_template_build_evidence_function_count=47`.
- `effect_coverage_residual_status=effect_coverage_residual_accepted`,
  `effect_coverage_residual_raw_flag_total=539`,
  `effect_coverage_residual_card_flag_rows=293`,
  `effect_coverage_residual_unique_flagged_cards=240` e
  `effect_coverage_residual_unaccepted_card_flag_rows=0`.
- `runtime_safe_rule_names=1702`,
  `active_or_review_rule_names=3159`,
  `non_runtime_safe_rule_names=1457`,
  `needs_review_rule_names=1457`,
  `review_only_rule_names=0` e
  `review_status_counts={"active":27,"needs_review":1457,"verified":1675}`.

Leitura operacional:

- E correto dizer que o backlog atual de unknowns esta zerado e que o focused
  dispatch atual esta pronto para `29` cards / `47` funcoes support/build/
  dispatch.
- Ainda nao e correto dizer que todos os efeitos/templates de acao de carta do
  corpus estao runtime-safe/card-specific: existem `539` flags residuais
  aceitas, `293` card-flag rows, `240` cards flagged e `1457` rule names em
  `needs_review`/`non_runtime_safe`.
- `review_only_rule_names=0` e um campo estreito; nao deve ser lido como
  "nao ha backlog de review". O denominador correto para backlog de revisao e
  `needs_review_rule_names=1457` / `non_runtime_safe_rule_names=1457`.

## Passo de auditoria - forensic lineage scope 2026-06-19T19:13Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_forensic_lineage_scope_audit_20260619_191327.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/forensic_audit.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`

Resultado atual:

- Latest `2026-06-19T18:47:21Z` segue
  `battle_replay_final_status=trusted_for_strategy_learning`, com
  `mandatory_gate_divergences=[]`.
- Sem alerta atual: `seeds_with_high_or_critical_action_findings=[]`,
  `seeds_with_high_or_critical_forensic_findings=[]` e
  `seeds_with_strategy_blockers=[]`.
- `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `forensic_lineage_status=complete` e
  `forensic_lineage_unaccepted_missing_samples=[]`.
- Em `1518` card events, `card_id_present/missing=988/530`,
  `semantic_hash_present/missing=988/530` e
  `rule_logical_key_present/missing=1502/16`.
- Todos os missings atuais estao aceitos:
  `card_id_missing_accepted/unaccepted=530/0`,
  `semantic_hash_missing_accepted/unaccepted=530/0` e
  `rule_logical_key_missing_accepted/unaccepted=16/0`.
- Motivos de waiver agregados:
  `land_played_curated_runtime_rule_without_pg_card_identity=584`,
  `battle_rule_registry_without_card_identity_columns=430`,
  `type_line_creature_fact_no_rule_identity=48` e
  `manual_runtime_waiver_without_pg_identity=14`.

Leitura operacional:

- O contrato forense atual esta funcionando: nao ha missing de lineage nao
  aceito, e o teste dedicado garante que missing nao aceito continue visivel.
- `forensic_lineage_status=complete` significa `missing_unaccepted=0`; nao
  significa que todo card event tem `card_id`, `semantic_hash` e
  `rule_logical_key`.
- Para aprendizagem card-specific, confirmacao WR ou explicacao exata por regra,
  os contadores present/missing e os waiver reasons precisam acompanhar o status
  agregado.

## Passo de auditoria - strategy learning confidence scope 2026-06-19T19:16Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_strategy_learning_confidence_scope_audit_20260619_191643.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/research_review.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/research_review.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/strategy_audit.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Resultado atual:

- Latest `2026-06-19T18:47:21Z` segue
  `battle_replay_final_status=trusted_for_strategy_learning`, com
  `battle_replay_final_status_reason=all_mandatory_gates_pass` e
  `mandatory_gate_divergences=[]`.
- `mandatory_gate_statuses.strategy_audit.status=pass`.
- `strategy_findings=3`, `strategy_low_confidence_findings=3`,
  `strategy_review_required_findings=0`,
  `strategy_code_counts={"forced_keep_after_bad_mulligan":3}` e
  `strategy_severity_counts={"medium":3}`.
- `research_statuses.mulligan=blocked_or_needs_review`.
- `strategy_learning_confidence_counts={"high_confidence_replay":13,
  "low_confidence_replay":3}`.
- `strategy_high_confidence_learning_seeds=["63201734","63201735",
  "63201736","63201737","63201738","63201742","63201743","63201744",
  "63201745","63201746","63201747","63201748","63201749"]`.
- `strategy_low_confidence_seeds=["63201739","63201740","63201741"]`.
- `strategy_not_learning_eligible_seeds=[]`.

Leitura operacional:

- Nao ha novo BV nesta passada: `BV-056` foi fechado corretamente para a
  superficie recorrente atual, porque summary, research review, strategy audit
  por seed e gate matrix separam as `13` seeds high-confidence das `3` seeds
  low-confidence.
- As seeds `63201739`, `63201740` e `63201741` tem
  `Verdict=low_confidence_replay`, `High-confidence learning eligible=False`,
  `High-confidence learning weight=0.0` e motivo
  `forced_keep_after_bad_mulligan`.
- `trusted_for_strategy_learning` nao significa que todas as seeds sao amostras
  high-confidence; significa que todos os gates obrigatorios passaram, enquanto
  a confianca por seed ainda controla o que pode ensinar estrategia/WR com peso
  alto.
- Ao citar WR, baseline ou handoff, sempre carregar
  `strategy_high_confidence_learning_seeds` e `strategy_low_confidence_seeds`
  junto do status final.

## Passo de auditoria - event contract observed/static scope 2026-06-19T19:19Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_event_contract_observed_static_scope_audit_20260619_191905.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/event_contract_static.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/event_contract_static.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Resultado atual:

- Latest `2026-06-19T18:47:21Z` segue
  `battle_replay_final_status=trusted_for_strategy_learning`, com
  `mandatory_gate_divergences=[]`.
- `event_contract_static_status=event_contract_static_ready`.
- `event_contract_static_events_observed_total=14679`.
- `event_contract_static_observed_event_types_total=53`.
- `event_contract_static_static_event_types_total=94`.
- `event_contract_static_all_event_types_total=97`.
- `event_contract_static_observed_unclassified_total=0`.
- `event_contract_static_static_unclassified_total=0`.
- `event_contract_static_observed_missing_required_fields=0`.
- `event_contract_static_waiver_until_forced_fixture=0`.
- `event_contract_static_fixture_unaccepted_types=[]`.
- `event_contract_static_fixture_or_waiver_counts={"observed_in_latest":53,
  "static_contract_accepted_waiver":44}`.

Eventos observados que nao aparecem como literal estatico no AST:

- `player_eliminated`: `48`, classe `action_audited`, consumidor
  `battle_action_critic.py`, campos minimos `event, turn`.
- `replacement_applied`: `11`, classe `action_audited`, consumidor
  `battle_action_critic.py`, campos minimos `event, turn`.
- `saga_sacrificed_by_sba`: `2`, classe `ignored_with_reason`, consumidor
  `skip_guardrail_or_state_cleanup`, campo minimo `event`.

Leitura operacional:

- Nao ha novo BV nesta passada: os tres tipos acima estao classificados,
  observados e continuam visiveis em `observed_not_static_literal`.
- `event_contract_static_ready` nao significa que todo tipo observado foi
  encontrado como literal estatico; significa que tipos observados/estaticos
  estao classificados, tem campos minimos e nao tem waiver de fixture pendente.
- Para qualquer leitura de contrato de eventos, usar juntos:
  `all_event_types_total`, `observed_not_static_literal`,
  `observed_unclassified_total`, `static_unclassified_total`,
  `observed_missing_required_fields` e
  `static_contract_waiver_until_forced_fixture`.

## Passo de auditoria - human replay renderer scope 2026-06-19T19:26Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_human_replay_renderer_scope_audit_20260619_192625.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.txt`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.decision_trace.jsonl`

Resultado atual:

- Latest `2026-06-19T18:47:21Z` segue
  `battle_replay_final_status=trusted_for_strategy_learning`, com
  `battle_replay_final_status_reason=all_mandatory_gates_pass` e
  `mandatory_gate_divergences=[]`.
- Sem alerta atual: `seeds_with_high_or_critical_action_findings=[]` e
  `seeds_with_strategy_blockers=[]`.
- Total agregado do latest: `replay.txt` tem `7826` linhas,
  `replay.events.jsonl` tem `14679` rows e `replay.decision_trace.jsonl`
  tem `2265` rows.
- `decision_audit_human_replay_complete=not_evaluated_by_replay_decision_auditor`.
- `decision_audit_rules_interaction_trusted=not_evaluated_by_replay_decision_auditor`.
- Placeholders antigos de trigger seguem fechados:
  `event=?=0`, `stack=?=0`, `target=?=0` e `stack_object=?=0`.
- Placeholders/lacunas atuais no log humano: `life=?->=11` e `CMC=?=106`.

Detalhe da lacuna de vida:

- `utility_land_activated` apareceu para `Ancient Tomb=11`,
  `Sunbaked Canyon=4`, `Urza's Saga=1`,
  `Hall of Heliod's Generosity=2`, `Inventors' Fair=1` e `War Room=2`.
- Existem `13` eventos `utility_land_activated` com `life_paid` mas sem
  `life_before`.
- Exemplo: seed `63201734`, `replay.events.jsonl` linha `192`, `Ancient Tomb`
  tem `life_after=38` e `life_paid=2`, mas nao tem `life_before`; o
  `replay.txt` linha `129` imprime `life=?->38 life_paid=2`.
- Exemplo adicional: seed `63201744`, `War Room` linhas `899` e `1049` tem
  `life_paid=2`, mas nao trazem `life_before` nem `life_after`; o `replay.txt`
  imprime apenas `life_paid=2`.

Detalhe da lacuna de CMC:

- `spell_cast=418` e `creature_cast=86` estao com `cmc` preenchido.
- `commander_cast=28/28`, `miracle_cast=46/46` e
  `end_step_instant=32/32` estao sem `cmc`, gerando `CMC=?` no replay humano.

Leitura operacional:

- O fluxo atual esta correto para os gates obrigatorios: o latest esta trusted,
  sem high/critical action findings e sem strategy blockers.
- O `replay.txt` nao deve ser usado sozinho como fonte de aprendizagem ou prova
  completa de interacao de regra. Ele e uma projecao humana; a fonte de
  auditoria continua sendo `replay.events.jsonl`, `replay.decision_trace.jsonl`
  e os gates action/decision/forensic/event-contract/coverage/strategy.
- As lacunas atuais sao de observabilidade do log humano e completude de campos
  emitidos por alguns caminhos, ate prova em contrario de impacto em legalidade
  ou peso de aprendizagem.

## Passo de auditoria - counter priority window scope 2026-06-19T19:31Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_counter_priority_window_scope_audit_20260619_193149.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.txt`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`

Resultado atual:

- Latest `2026-06-19T18:47:21Z` segue
  `battle_replay_final_status=trusted_for_strategy_learning`, com
  `mandatory_gate_divergences=[]`.
- Sem alerta atual: `seeds_with_high_or_critical_action_findings=[]` e
  `seeds_with_strategy_blockers=[]`.
- Existem `7` eventos `spell_countered` no latest.
- Todos os `7/7` tem `counter`, `target`, `stack_object`,
  `target_controller`, `target_effect`, `result=countered` e
  `stack_depth=1`.
- Todos os `7/7` estao sem `phase` e sem `priority_window`.

Exemplos:

- Seed `63201742`, JSONL linhas `694-697`: `Grand Abolisher` e anunciado,
  pago e conjurado em `precombat_main`; em seguida `Pact of Negation` gera
  `spell_countered`, mas o proprio evento de counter nao carrega `phase` nem
  `priority_window`.
- Seed `63201746`, JSONL linhas `683-686`: `Orim's Chant` entra por
  `miracle_cast` em `draw_step`; em seguida `Mental Misstep` gera
  `spell_countered`, tambem sem `phase`/`priority_window`.
- O replay humano imprime a linha `COUNTER ... target=... stack_object=...
  result=countered cost=...`, mas tambem nao mostra a janela de prioridade.

Leitura operacional:

- O problema antigo de counter sem alvo/stack/result continua fechado no corpus
  atual.
- A falha atual e mais estreita: a legalidade temporal do counter depende de
  inferencia por eventos vizinhos, nao de campo proprio no evento
  `spell_countered`.
- Como o checklist deste register exige, para cada counter, alvo, stack object,
  janela de prioridade e resultado, a ausencia de `phase`/`priority_window`
  deve permanecer rastreada ate virar campo, fixture ou waiver explicito.

## Passo de auditoria - latest counter priority window recheck 2026-06-19T21:20Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_counter_priority_window_recheck_20260619_182020.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.decision_trace.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.txt`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`

Resultado atual:

- Latest real: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826`.
- `timestamp_utc=2026-06-19T20:48:26Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- Sem alerta atual: `seeds_with_high_or_critical_action_findings=[]`,
  `seeds_with_strategy_blockers=[]` e
  `seeds_with_high_or_critical_forensic_findings=[]`.
- Existem `10` eventos `spell_countered` no latest.
- Todos os `10/10` possuem `counter`, `target`, `stack_object`,
  `target_controller`, `target_effect`, `result=countered`, `stack_depth=1`
  e `cost`.
- Todos os `10/10` estao sem `phase` e sem `priority_window` no proprio
  evento `spell_countered`.
- As `10` decisoes correspondentes em `replay.decision_trace.jsonl` carregam
  `phase=precombat_main`, entao ha evidencia proxima para inferencia, mas ela
  nao esta propagada para o evento primario de counter.
- O renderer humano em `battle_replay_v10_3.py` imprime `COUNTER ... target=...
  stack_object=... result=... cost=...`, tambem sem `phase` ou
  `priority_window`.

Leitura operacional:

- O gate atual esta correto para o contrato existente: action critic, replay
  renderer e stack tests aceitam counter com alvo/stack/result.
- A lacuna restante e de contrato/provenance: a janela temporal do counter
  depende de correlacao com decision trace, nao de campo proprio no evento que
  representa a interacao.
- `test_battle_action_critic.py` possui fixture aceita sem `phase`/`priority_window`;
  `battle_stack_casting_tests.py` so exige que `spell_countered` exista, embora
  ja exista assert de `phase`/`priority_window` para `spell_resolved`.

## Passo de auditoria - removal target declaration scope 2026-06-19T19:35Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_removal_target_declaration_scope_audit_20260619_193558.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.txt`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_targeting_tests.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`

Resultado atual:

- Latest `2026-06-19T18:47:21Z` segue
  `battle_replay_final_status=trusted_for_strategy_learning`, com
  `mandatory_gate_divergences=[]`.
- Sem alerta atual: `seeds_with_high_or_critical_action_findings=[]` e
  `seeds_with_strategy_blockers=[]`.
- Existem `49` eventos cast-like de removal/redirect no latest:
  `cast_announced`, `spell_cast`, `miracle_cast` e `end_step_instant` para
  `remove_creature`, `remove_permanent` e `redirect_removal`.
- Todos os `49/49` estao sem `target` e com `targets=[]` ou ausente.
- Existem `31` `spell_resolved` de removal/redirect; todos os `31/31` estao
  sem `target`.
- Existem `13` `removal_resolved`; todos os `13/13` tem alvo, tipo de alvo,
  `targeting_pipeline=targeting_formal_minimal` e `target_legal=true`.

Exemplos:

- Seed `63201734`, linhas `242`, `244`, `249` e `250`:
  `Generous Gift` e anunciado/conjurado/resolvido sem target; apenas
  `removal_resolved` escolhe `Kraum, Ludevic's Opus`.
- Seed `63201747`, linhas `451`, `453` e `454`: `Path to Exile` entra na stack
  sem target declarado e depois e counterado por `Pact of Negation`; o
  `spell_countered` conhece o spell na stack, mas nao o objeto que o removal
  ameacava.

Leitura operacional:

- Este gap e mais forte que lacuna de renderer: `CastingContext` ja suporta
  `targets`, mas o caminho normal de removal chama `begin_cast_context(...)`
  sem alvo e so escolhe alvo em `apply_effect_immediate(...)`.
- `battle_targeting_tests.py` valida hexproof/protection/ward e metadata em
  `removal_resolved`, mas nao exige target declarado em `cast_announced` ou
  preservado em `spell_cast`.
- Para regra de target declaration, a engine deveria escolher/persistir alvo no
  cast e depois apenas revalidar esse alvo na resolucao. Hoje ela pode escolher
  o melhor alvo disponivel no momento da resolucao.

## Passo de auditoria - latest removal target provenance recheck 2026-06-19T21:25Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_removal_target_provenance_recheck_20260619_182514.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.txt`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_targeting_tests.py`

Resultado atual:

- Latest real: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826`.
- `timestamp_utc=2026-06-19T20:48:26Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `action_findings=0`; os `16` `action_critic.json` por seed somam
  `total_findings=0`.
- Sem alerta atual: `seeds_with_high_or_critical_action_findings=[]`,
  `seeds_with_strategy_blockers=[]` e
  `seeds_with_high_or_critical_forensic_findings=[]`.
- Para `remove_creature` e `remove_permanent`, `37/37` eventos cast-like agora
  possuem alvo declarado e `targeting_pipeline=targeting_formal_minimal`.
- `21/21` `spell_resolved` de targeted removal preservam o mesmo alvo do
  evento cast-like correspondente.
- `22/22` `removal_resolved` possuem `target`, `target_legal=true` e
  `targeting_pipeline=targeting_formal_minimal`.

ID removido de `Achados abertos` por evidencia atual:

- `BV-065`: o blocker antigo `targeted_removal_without_declared_target` nao se
  reproduz no latest `20260619_204826`; os testes atuais tambem cobrem alvo
  declarado no cast e revalidacao sem reselecao para targeted removal.

Novo achado aberto:

- `BV-076`: `Deflecting Swat`/`redirect_removal` nao entra no contrato de
  targeted removal. No latest ha `12` eventos relacionados a `Deflecting Swat`
  em `5` seeds; os cast/resolution rows nao tem spell/ability alvo,
  `old_target` ou `new_target`. No codigo, `redirect_removal` atualmente concede
  indestrutivel e finaliza o spell, aproximando protecao em vez de redirecionar
  alvo.

## Passo de auditoria - spell resolution provenance scope 2026-06-19T19:41Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_spell_resolution_provenance_scope_audit_20260619_194143.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`
- `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`

Resultado atual:

- Latest `2026-06-19T19:37:33Z` aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_193733`.
- `battle_replay_final_status=review_required`, com
  `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- Sem alerta high/critical/action/blocker definido pelo usuario:
  `seeds_with_high_or_critical_action_findings=[]` e
  `seeds_with_strategy_blockers=[]`.
- O gate forensic esta incompleto por `2` findings medium de lineage:
  `Mardu Devotee` seed `63201940` e `Orcish Lumberjack` seed `63201943`,
  ambos em `spell_cast` vindo de `functional_tags_json`.
- Existem `293` eventos `spell_resolved` no latest.
- Todos os `293/293` estao sem `phase`, `priority_window`, `stack_depth`,
  `source_zone`, `destination`, `zone_after`, `from_zone`, `to_zone`,
  `cast_pipeline`, `locked_cost`, `resolved_from_stack`, `target`, `targets`,
  `stack_object`, `stack_object_id` e `result`.
- Nos mesmos `293` `spell_resolved`, `card_id` e `semantic_hash` aparecem em
  `232` linhas e faltam em `61`; `rule_logical_key` aparece em `293/293`.
- `trigger_resolved` traz `phase` em `89/89`, mas tambem nao traz
  `stack_depth`, `source_zone`, `destination` ou `resolved_from_stack`.

Leitura operacional:

- Esta falha e diferente do gate forensic atual: forensic aponta identidade
  incompleta em `spell_cast`; aqui o problema e que o proprio evento
  `spell_resolved` nao prova fase, stack, zona, resultado nem alvo.
- `CastingContext.to_replay_fields()` ja tem `cast_pipeline`, `locked_cost`,
  `targets` e `source_zone`, mas `apply_effect_immediate(...)` nao recebe/propaga
  esse contexto quando emite `spell_resolved`.
- `BATTLE_SYSTEM_LOGIC.md` descreve `spell_resolved` como contendo resultado, mas
  o corpus atual tem `result` ausente em todos os `293/293` eventos.
- O renderer humano so consegue imprimir `RESOLVE SPELL` com carta, CMC, efeito e
  regra; a legalidade da resolucao depende de inferencia por linhas vizinhas.

## Passo de auditoria - latest spell resolution provenance recheck 2026-06-19T21:32Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_spell_resolution_provenance_recheck_20260619_183224.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/event_contract_static.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/action_critic.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py`

Resultado atual:

- Latest real: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826`.
- `timestamp_utc=2026-06-19T20:48:26Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `action_findings=0`.
- Sem alerta atual: `seeds_with_high_or_critical_action_findings=[]`,
  `seeds_with_strategy_blockers=[]` e
  `seeds_with_high_or_critical_forensic_findings=[]`.
- Existem `310` eventos `spell_resolved`.
- `0/310` estao sem `phase`, `priority_window`, `stack_object`,
  `stack_depth`, `source_zone`, `from_zone`, `to_zone`, `destination`,
  `zone_after`, `resolved_from_stack`, `result`, `cast_pipeline` ou
  `locked_cost`.
- Split de resolucao: `231` stack resolutions normais, `51` miracle stack
  resolutions, `21` end-step direct resolutions e `7` response direct
  resolutions.
- `remove_creature` e `remove_permanent` em `spell_resolved` trazem alvo; o
  caso sem alvo relevante agora e `redirect_removal`, rastreado em `BV-076`.
- `event_contract_static.json` ainda define `spell_resolved.minimum_fields` como
  apenas `["event", "turn"]`, apesar de o evento real carregar muito mais
  provenance.

Leitura operacional:

- A falha runtime antiga de `BV-066` nao se reproduz no latest atual.
- O achado permanece aberto em escopo mais estreito: o contrato estatico e parte
  dos testes ainda nao exigem a mesma profundidade de campos que o runtime ja
  emite. O action critic exige `phase`, `source_zone`, `resolved_from_stack`,
  `result`, stack fields quando `resolved_from_stack=true` e zona de destino,
  mas nao fixa `priority_window`/`locked_cost` como contrato universal.
- Fechamento deve exigir contrato typed/static ou fixture/action critic cobrindo
  explicitamente o conjunto completo de campos de resolucao, com waiver para
  caminhos diretos.

## Passo de auditoria - functional tag lineage gate 2026-06-19T19:47Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_functional_tag_lineage_gate_audit_20260619_194712.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63201940/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63201940/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63201940/forensic_audit.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63201943/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63201943/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63201943/forensic_audit.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`

Resultado atual:

- Latest `2026-06-19T19:37:33Z` segue
  `battle_replay_final_status=review_required`, com
  `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- Sem alerta high/critical/action/blocker definido pelo usuario:
  `seeds_with_high_or_critical_action_findings=[]`,
  `seeds_with_high_or_critical_forensic_findings=[]` e
  `seeds_with_strategy_blockers=[]`.
- O latest tem exatamente `6` eventos com `rule_source=functional_tags_json`:
  `2` `cast_announced`, `2` `cost_paid` e `2` `spell_cast`.
- Todos os `6/6` sao `ramp_permanent` e todos os `6/6` estao sem
  `rule_logical_key`, `card_id` e `semantic_hash`.
- Os unicos cards afetados sao `Mardu Devotee` e `Orcish Lumberjack`.
- `Mardu Devotee`, seed `63201940`, linhas `39`-`41`: entra como
  `functional_tags_json`, `heuristic`, `confidence=0.35`, sem lineage. O
  forensic da seed emite `1` finding medium e recomenda mover a carta para
  `card_battle_rules` com status verified/active.
- `Orcish Lumberjack`, seed `63201943`, linhas `819`-`821`: mesmo padrao, com
  `1` finding medium e a mesma recomendacao.

Leitura operacional:

- Esta falha explica o `review_required` atual sem depender de inferencia: duas
  cartas ainda executam por fallback amplo de `functional_tags_json`.
- `get_card_effect(...)` cai em `TAG_EFFECTS[tag]` quando nao encontra regra no
  registry/canonical/manual; esse caminho adiciona `source=functional_tags_json`,
  `review_status=heuristic` e `confidence=0.35`, mas nao fornece
  `logical_rule_key`.
- O forensic esta correto em nao aceitar esse missing como waiver automatico:
  nao e uma regra battle revisada, e sim uma aproximacao generica de deckbuilding
  usada como acao de carta.
- Para dizer que templates/acoes estao completos, e preciso separar
  focused-template readiness de qualquer evento que ainda venha de
  `functional_tags_json`.

## Passo de auditoria - latest functional tag lineage recheck 2026-06-19T21:37Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_functional_tag_lineage_recheck_20260619_183724.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/runtime_surface_manifest.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_functional_tags_json.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`

Resultado atual:

- Latest real: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826`.
- `timestamp_utc=2026-06-19T20:48:26Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `forensic_lineage_status=complete`, `forensic_rule_findings=0` e
  `forensic_turn_findings=0`.
- Sem alerta atual: `seeds_with_high_or_critical_action_findings=[]`,
  `seeds_with_strategy_blockers=[]` e
  `seeds_with_high_or_critical_forensic_findings=[]`.
- Busca no latest encontrou `0` eventos com `rule_source=functional_tags_json`,
  `source=functional_tags_json` ou `lineage_source=functional_tags_json`.
- Agregado forensic por source no latest: `curated=1367`,
  `manual_runtime_waiver=4`, `type_line_creature=18`,
  `functional_tags_json=0`.
- Eventos com `rule_source=manual_runtime_waiver` no replay envolvem
  `Moonsnare Prototype`, `Neoform` e `Orcish Lumberjack`, todos com
  `rule_review_status=verified` e `rule_logical_key`.
- Prova sintetica read-only com `spell_resolved/draw_cards` vindo de
  `functional_tags_json` gerou forensic `high`, com missing unaccepted para
  `rule_logical_key`, `card_id` e `semantic_hash`.

Leitura operacional:

- O blocker antigo de `BV-067` nao se reproduz no latest atual.
- O gate forensic continua protegendo aprendizado quando `functional_tags_json`
  reaparece como acao de carta.
- O fallback ainda existe em `get_card_effect(...)`, e
  `test_battle_functional_tags_json.py` segue validando que linhas sinteticas de
  deck podem derivar efeito por functional tags; esse teste esta
  `outside_recurring_run` no manifest.
- O achado deve continuar aberto em escopo menor: publicar contagem/lista de
  eventos `functional_tags_json` no summary e/ou adicionar fixture recorrente
  que prove explicitamente o bloqueio de aprendizado para esse source.

## Passo de auditoria - unknown effect denominator 2026-06-19T19:52Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_unknown_effect_denominator_audit_20260619_195209.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage_residual.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/unknown_template_backlog.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py`

Resultado atual:

- Latest `2026-06-19T19:37:33Z` segue
  `battle_replay_final_status=review_required`, com
  `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- Sem alerta high/critical/action/blocker definido pelo usuario:
  `seeds_with_high_or_critical_action_findings=[]` e
  `seeds_with_strategy_blockers=[]`.
- `effect_coverage_unknowns=0`, `unknown_template_backlog_cards=0` e
  `unknown_template_backlog_status=focused_template_backlog_ready`.
- Mesmo assim, `effect_coverage.json` tem `effect_totals.unknown=41`.
- Existem `28` cards unicos `focused_template_ready` com `effect=unknown`; dos
  `29` focused-template cards, apenas `Banishing Knack` aparece como
  `remove_permanent`.
- Existem `5` cards `battle_rule_needs_review_generated` com `effect=unknown`
  em flagged cards: `Amulet of Vigor`, `Blood Moon`, `Exploration`,
  `Ghostly Flicker` e `Grasp of Fate`.

Leitura operacional:

- `effect_coverage_unknowns=0` mede `flag_totals.unknown_effect`, que hoje so
  aparece quando `source == "unknown"`.
- `unknown_template_backlog` tambem itera apenas `coverage["unknown_cards"]`,
  que usa `source == "unknown"`, nao `effect == "unknown"`.
- Portanto, `unknown_template_backlog_cards=0` prova backlog source-unknown
  zerado; nao prova que nao existem efeitos `unknown` no coverage.
- Para responder se todos os templates de acoes de cartas estao criados, e
  obrigatorio reportar tambem `effect_totals.unknown` e os cards
  `focused_template_ready` ou `needs_review` que ainda carregam `effect=unknown`.

## Passo de auditoria - effect coverage deck table source keys 2026-06-19T19:57Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_deck_table_source_key_audit_20260619_195720.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py`

Resultado atual:

- O JSON do latest `2026-06-19T19:37:33Z` usa `source_totals` atuais:
  `battle_rule_curated=724`, `battle_rule_needs_review_generated=34`,
  `effect_map=100`, `focused_template_ready=33`, `handcrafted=2`, `tag=18` e
  `type_land=377`.
- A tabela humana `Deck Coverage` ainda tem colunas historicas
  `Battle Manual` e `Battle Generated`, mas o renderer le
  `battle_rule_manual` e `battle_rule_generated`.
- Essas duas chaves nao existem em `deck_totals` do latest; por isso o Markdown
  mostra `0` em `Battle Manual` e `Battle Generated` para todos os decks.
- Com isso, `758` instancias de fonte battle-rule ficam ocultas no nivel
  humano do deck: `724` `battle_rule_curated` e `34`
  `battle_rule_needs_review_generated`.
- Exemplos objetivos:
  - `Lorehold target deck`: Markdown `0/0`; JSON `battle_rule_curated=67`,
    `battle_rule_needs_review_generated=0`.
  - `Lumra, Bellow of the Woods #49 (real)`: Markdown `0/0`; JSON
    `battle_rule_curated=33`, `battle_rule_needs_review_generated=9`.
  - `Yorion, Sky Nomad #38 (real)`: Markdown `0/0`; JSON
    `battle_rule_curated=35`, `battle_rule_needs_review_generated=8`.

Leitura operacional:

- `effect_coverage.md` continua util para listar flags e high-risk cards, mas a
  tabela `Deck Coverage` nao deve ser usada como prova de ausencia de regras
  battle por deck enquanto as chaves estiverem defasadas.
- Para handoff e priorizacao, usar `effect_coverage.json.deck_totals` e
  `source_totals` ate o renderer reconciliar os nomes atuais.
- O ajuste correto e trocar ou dinamizar as colunas do Markdown para
  `battle_rule_curated` e `battle_rule_needs_review_generated`, com teste que
  falhe quando uma fonte nao nula do JSON for omitida/zerada na tabela humana.

Validacoes executadas nesta etapa:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_residual_audit.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py` - PASS
- `git diff --check -- docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_deck_table_source_key_audit_20260619_195720.md` - PASS

## Passo de auditoria - event static emitter scope 2026-06-19T20:02Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_event_static_emitter_scope_audit_20260619_200220.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/event_contract_static.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/event_contract_static.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_support.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_support.py`

Resultado atual:

- O latest `2026-06-19T19:37:33Z` reporta
  `event_contract_static_status=event_contract_static_ready`.
- O mesmo summary tem `observed_not_static_literal` com
  `["player_eliminated", "replacement_applied", "saga_sacrificed_by_sba"]`.
- Contagens observadas:
  - `player_eliminated=43`
  - `replacement_applied=11`
  - `saga_sacrificed_by_sba=6`
- `battle_event_contract_static_audit.py` usa `DEFAULT_ENGINE_SOURCE` apontando
  apenas para `battle_analyst_v9.py` e faz AST scan desse arquivo.
- Os eventos fora do literal estatico sao emitidos em modulos de suporte:
  - `battle_replacement_support.py:177`: `replacement_applied`
  - `battle_sba_support.py:217`: `saga_sacrificed_by_sba`
  - `battle_sba_support.py:268`, `274`, `286`, `300`:
    `player_eliminated`

Leitura operacional:

- `event_contract_static_ready` significa que os tipos observados/estaticos
  estao classificados, tem campos minimos e nao ha fixture waiver pendente.
- Nao significa que o inventario estatico varreu todos os arquivos que emitem
  eventos de replay.
- Para validar a superficie completa de eventos battle, o auditor precisa
  escanear multiplos emitter files ou publicar um manifesto explicito de
  arquivos emissores/waivers.

Validacoes executadas nesta etapa:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py --input-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest --output /tmp/battle_event_contract_static_current.md --json-output /tmp/battle_event_contract_static_current.json --fail-on-unclassified` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` - PASS
- `git diff --check -- docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md docs/hermes-analysis/master_optimizer_reports/battle_event_static_emitter_scope_audit_20260619_200220.md` - PASS

## Passo de auditoria - runtime surface manifest test contract 2026-06-19T20:06Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_manifest_test_contract_audit_20260619_200606.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/runtime_surface_manifest.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`

Resultado atual:

- O latest `2026-06-19T19:37:33Z` tem
  `runtime_surface_manifest_total_files=108`,
  `runtime_surface_manifest_unclassified_files=[]`.
- Coverage atual: `covered_by_recurring_run=29`,
  `imported_by_core_runtime=6`, `outside_recurring_run=73`.
- Gate expectations atuais: `recurring_audit_required=29`,
  `core_runtime_import_regression=6`,
  `targeted_manual_gate_required_before_change=31`,
  `targeted_test_required_before_change=42`.
- `test_battle_runtime_surface_manifest.py` passa, mas o assert de denominador
  principal e `summary["total_files"] >= 98`.
- Como o manifest atual tem `108` arquivos, ate `10` arquivos poderiam sair do
  inventario sem esse assert falhar, desde que as categorias minimas ainda
  existissem.

Leitura operacional:

- O manifest atual segue util e sem unclassified files.
- A lacuna esta no contrato do teste: ele protege contra colapso grosseiro, mas
  nao fixa o denominador atual da superficie battle.
- Para sustentar consciencia completa, o teste deve validar total/snapshot,
  contagens por categoria/gate/coverage e arquivos high-signal nominais.

Validacao executada nesta etapa:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py --repo-root /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia --output /tmp/battle_runtime_surface_manifest_current.md --json-output /tmp/battle_runtime_surface_manifest_current.json --fail-on-unclassified` - PASS
- `git diff --check -- docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_manifest_test_contract_audit_20260619_200606.md` - PASS

## Passo de auditoria - current action blocker target/provenance 2026-06-19T20:10Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_current_action_blocker_target_provenance_audit_20260619_201005.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/action_critic.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`

Resultado atual:

- O latest agora aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_200324`.
- `battle_replay_final_status=blocked`.
- `mandatory_gate_divergences=["action_critic=blocked","forensic_audit=review_required"]`.
- `action_findings=19`, com `action_verdict_counts={"high":16,"medium":3,"ok":6479}`.
- `seeds_with_high_or_critical_action_findings=["63202004","63202005","63202006","63202007","63202008","63202010","63202018"]`.
- Nao ha strategy blockers: `seeds_with_strategy_blockers=[]`.

Alerta:

- Existe high em action findings no latest atual. As seeds afetadas sao
  `63202004`, `63202005`, `63202006`, `63202007`, `63202008`, `63202010` e
  `63202018`.

Leitura operacional:

- Os `16` highs sao todos `targeted_removal_without_declared_target`, cobrindo
  `Swords to Plowshares` (`8`), `Generous Gift` (`4`), `Path to Exile` (`2`) e
  `Dismember` (`2`).
- Isso reconfirma `BV-065` como blocker atual do action critic.
- Os `3` mediums sao `spell_resolved_without_resolution_provenance`, em
  `Teferi's Protection` e `Flawless Maneuver`, reconfirmando `BV-066`.
- Nao foi criado novo BV porque a causa raiz ja esta aberta em `BV-065` e
  `BV-066`; esta etapa atualiza a severidade operacional com evidencia do
  latest bloqueado.

Validacoes executadas nesta etapa:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` - PASS
- `git diff --check -- docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md docs/hermes-analysis/master_optimizer_reports/battle_current_action_blocker_target_provenance_audit_20260619_201005.md` - PASS

## Passo de auditoria - cross-gate learning eligibility 2026-06-19T20:13Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_cross_gate_learning_eligibility_audit_20260619_201337.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`

Resultado atual:

- O latest `2026-06-19T20:03:24Z` esta `blocked` por
  `action_critic=blocked` e `forensic_audit=review_required`.
- `seeds_with_high_or_critical_action_findings=["63202004","63202005","63202006","63202007","63202008","63202010","63202018"]`.
- O mesmo summary publica `strategy_learning_confidence_counts={"high_confidence_replay":12,"low_confidence_replay":4}` e
  `strategy_not_learning_eligible_seeds=[]`.
- Intersecoes:
  - Action-blocked e strategy high-confidence: `63202005`, `63202007`,
    `63202008`, `63202010`.
  - Action-blocked e strategy low-confidence: `63202004`, `63202006`,
    `63202018`.
  - Action-blocked e not-learning-eligible: nenhum.

Leitura operacional:

- `strategy_high_confidence_learning_seeds` hoje significa "limpo no auditor
  estrategico", nao "globalmente elegivel para aprendizado".
- Em run bloqueado, seeds podem aparecer como `high_confidence_replay` mesmo
  tendo high action findings.
- Qualquer consumidor de aprendizado precisa cruzar `battle_replay_final_status`,
  `mandatory_gate_divergences` e blockers de action/forensic antes de usar as
  listas de confidence estrategica.

Validacoes executadas nesta etapa:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` - PASS
- `git diff --check -- docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md docs/hermes-analysis/master_optimizer_reports/battle_cross_gate_learning_eligibility_audit_20260619_201337.md` - PASS

## Passo de auditoria - focused template effect label recheck 2026-06-19T20:19Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_focused_template_effect_label_recheck_20260619_201916.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_200324/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_200324/effect_coverage_residual.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_200324/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_200324/unknown_template_backlog.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py`

Resultado atual:

- O latest real segue em
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_200324`.
- `focused_template_dispatch_status=focused_template_dispatch_ready`.
- `focused_template_cards=29`, `template_predicate_match=29`,
  `evidence_dispatch_ready=29`, `focused_evidence_ready=29`.
- `unknown_template_backlog_cards=0`, mas `effect_coverage.effect_totals.unknown=41`.
- Dos `29` cards `focused_template_ready`, `28` ainda aparecem com
  `effect=unknown`; somente `Banishing Knack` aparece como `remove_permanent`.
- O residual atual ainda tem `7` rows `source=focused_template_ready` e
  `effect=unknown`; o summary tambem publica `needs_review_rule_names=1457` e
  `heuristic_effects=117`.

Leitura operacional:

- `focused_template_dispatch_ready` prova que a fila focada atual tem predicado,
  dispatch e evidencia por card.
- Isso nao prova que todos os templates de acoes de cartas do corpus foram
  criados, porque o coverage ainda preserva `effect=unknown` para cards ja
  promovidos para `source=focused_template_ready`.
- A causa observada permanece a mesma de `BV-068`: o auditor troca `source` para
  `focused_template_ready`, mas nao troca o `effect` vindo de
  `battle.get_card_effect(...)`; depois, `unknown_template_backlog` mede apenas
  `source=unknown`, nao `effect=unknown`.
- Nao foi criado novo BV porque `BV-068` ja cobre a falha; esta etapa atualiza a
  evidencia com o latest bloqueado atual.

Validacoes executadas nesta etapa:

- Parse de `summary.json`, `effect_coverage.json`,
  `effect_coverage_residual.json`, `focused_template_dispatch.json` e
  `unknown_template_backlog.json`.
- Inspecao estatica de `battle_effect_coverage_audit.py`,
  `battle_focused_template_dispatch_audit.py` e
  `battle_unknown_template_backlog_audit.py`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_focused_template_dispatch_audit.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_residual_audit.py` - PASS

## Passo de auditoria - recent forensic functional tag blocker 2026-06-19T20:27Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_current_forensic_functional_tag_blocker_audit_20260619_202711.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_202217/seed_63202036/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_202217/seed_63202036/forensic_audit.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_202217/seed_63202036/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_202217/seed_63202036/strategy_audit.json`

Resultado do run:

- O run completo auditado e
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_202217`.
- `battle_replay_final_status=blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- `action_findings=0`, `seeds_with_high_or_critical_action_findings=[]`.
- `seeds_with_strategy_blockers=[]`.
- `seeds_with_high_or_critical_forensic_findings=["63202036"]`.
- A seed `63202036` tem `Neoform` em `spell_resolved` com finding `high`:
  `Game event depended on heuristic source functional_tags_json`.
- A mesma seed passa no action critic (`findings=0`) e no strategy audit
  (`high_confidence_replay`), reforcando que action/strategy clean nao bastam
  sem forensic gate limpo.

Leitura operacional:

- Este e o mesmo problema raiz de `BV-067`, com severidade maior nesse run:
  carta
  executada por fallback `functional_tags_json`, sem `card_id`/`semantic_hash`
  aceitos, e sem regra battle verified/active confiavel.
- `Neoform` tambem mostra divergencia de efeito: runtime `tutor` contra registry
  `draw_cards`, reportada como low.
- Nao foi criado novo BV porque `BV-067` cobre a classe raiz; esta etapa atualiza
  a evidencia para o latest bloqueado atual.

Validacoes executadas nesta etapa:

- Parse de `summary.json` do latest `20260619_202217`.
- Parse de `seed_63202036/forensic_audit.json`.
- Leitura de `seed_63202036/forensic_audit.md`.
- Parse de `seed_63202036/action_critic.json`.
- Parse de `seed_63202036/strategy_audit.json`.

## Passo de auditoria - latest trusted recheck 2026-06-19T20:29Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_trusted_recheck_20260619_202918.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_202628/test_*.log`

Resultado atual:

- O latest completo agora e
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_202628`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `action_findings=0`, `seeds_with_high_or_critical_action_findings=[]`.
- `seeds_with_strategy_blockers=[]`.
- `seeds_with_high_or_critical_forensic_findings=[]`.
- `forensic_rule_findings=0`.
- `strategy_findings=2`, com
  `strategy_learning_confidence_counts={"high_confidence_replay":14,"low_confidence_replay":2}`.
- O latest atual nao dispara a regra de notificacao original de high/critical
  action findings ou strategy blockers.
- Mesmo neste latest trusted, `test_battle_effect_coverage_known_cards.log`
  continua vazio e o `summary.json` segue sem matriz `test_results`, mantendo
  `BV-073` aberto.

Validacoes executadas nesta etapa:

- Parse de `summary.json` do latest `20260619_202628`.
- Inventario dos `test_*.log` do latest `20260619_202628`.
- Parse do summary para confirmar ausencia de matriz `test_results`.

## Passo de auditoria - test log provenance 2026-06-19T20:24Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_test_log_provenance_audit_20260619_202408.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_200324/test_*.log`
- `/Users/desenvolvimentomobile/.manaloom-agents/logs/battle-strategy-audit.log`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py`

Resultado atual:

- A lacuna foi observada no run `20260619_200324` e reproduzida nos runs
  completos `20260619_202217` e `20260619_202628`.
- O wrapper executa `15` testes antes dos replays e antes de montar o
  `summary.json`.
- Os `15` arquivos `test_*.log` esperados existem no run completo.
- `test_battle_effect_coverage_known_cards.log` esta vazio (`0` bytes, `0`
  linhas).
- Reexecucao isolada de `test_battle_effect_coverage_known_cards.py` confirmou
  `exit=0`, `stdout_bytes=0`, `stderr_bytes=103`; o resumo `Ran 5 tests ... OK`
  vai para stderr.
- O log global da automacao contem `Ran 5 tests ... OK` para esse teste, mas o
  artefato de run fica vazio porque o wrapper redireciona apenas stdout.
- `summary.json` nao publica matriz de testes, exit code por teste, caminhos dos
  `test_*.log` nem bytes stdout/stderr.

Leitura operacional:

- Como o wrapper usa `set -e`, a existencia do `summary.json` implica que os
  testes anteriores nao falharam no shell.
- Ainda assim, o resultado principal da automacao nao prova diretamente quais
  testes foram executados nem onde esta a evidencia de cada um.
- Isso nao muda o blocker atual do battle, mas enfraquece futuras afirmacoes de
  "validado e testado" baseadas apenas no `summary.json`.

Validacoes executadas nesta etapa:

- Inventario dos `test_*.log` dos runs `20260619_200324`, `20260619_202217` e
  `20260619_202628`.
- Parse de `summary.json` para confirmar ausencia de `test_results`,
  `test_logs`, `test_exit_codes` ou equivalente.
- Inspecao estatica do wrapper `manaloom-battle-strategy-audit.sh`.
- Reexecucao isolada de `test_battle_effect_coverage_known_cards.py`
  redirecionando stdout/stderr para arquivos temporarios.

## Passo de auditoria - latest focused template effect scope 2026-06-19T20:34Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_focused_template_effect_scope_recheck_20260619_203428.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage_residual.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/unknown_template_backlog.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/focused_template_dispatch_artifacts/*/focused_artifacts/focused_template_dispatch_audit/replay_events.jsonl`
- `server/bin/manaloom_battle_rule_focused_evidence.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py`

Resultado atual:

- O latest real e
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855`.
- `battle_replay_final_status=trusted_for_strategy_learning` e
  `mandatory_gate_divergences=[]`.
- `focused_template_dispatch_status=focused_template_dispatch_ready`.
- `focused_template_cards=29`, `template_predicate_match=29`,
  `supports_template_count=47`, `evaluate_dispatch_template_count=47`,
  `build_evidence_function_count=47`, `focused_template_evidence_ready=29`.
- `focused_template_dispatch.summary.supports_not_dispatched=[]`,
  `focused_template_cards_without_dispatch=[]` e
  `focused_template_cards_not_ready_unwaived=[]`.
- `unknown_template_backlog_cards=0` e `unknown_cards=[]`.
- Mesmo assim, `effect_coverage.effect_totals.unknown=41`.
- Dos `29` cards `focused_template_ready`, `28` continuam com
  `effect=unknown` em `effect_coverage.json`; somente `Banishing Knack` aparece
  como `remove_permanent`.
- Os artifacts focados desses `28` cards trazem escopos semanticos concretos,
  como `counter_type_change`, `utility_artifact_untap_x_lands`,
  `x_vehicle_counters_token`, `copy_artifact_as_enters`,
  `impulse_topdeck_or_library_zone`, `convoke_damage` e
  `planeswalker_static_activated_graveyard`.

Leitura operacional:

- O gate focado esta pronto para a fila focada atual: ha predicado, dispatch,
  builder e evidencia por card.
- Isso nao fecha o denominador de labels de efeito: o coverage ainda publica
  `effect=unknown` para a maior parte dos focused-template cards.
- A classe raiz continua sendo `BV-068`; nao foi criado novo BV.
- A frase correta e: "focused template dispatch atual esta pronto"; nao e:
  "todos os templates/efeitos de acoes de carta do corpus estao completos".

Validacoes executadas nesta etapa:

- Parse de `summary.json`, `focused_template_dispatch.json`,
  `unknown_template_backlog.json`, `effect_coverage.json` e
  `effect_coverage_residual.json`.
- Inspecao dos `replay_events.jsonl` gerados pelos artifacts focados.
- Inspecao estatica de `manaloom_battle_rule_focused_evidence.py` e
  `battle_focused_template_dispatch_audit.py`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_focused_template_dispatch_audit.py` - PASS, `5 tests passed`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS, `Ran 5 tests ... OK`.

## Passo de auditoria - latest strategy confidence recheck 2026-06-19T20:39Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_strategy_learning_confidence_recheck_20260619_203931.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/research_review.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/research_review.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202025/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202025/replay.decision_trace.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202025/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202025/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202025/replay_decision_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202031/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202031/replay.decision_trace.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202031/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202031/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202031/replay_decision_audit.json`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_strategy_learning_confidence_scope_audit_20260619_191643.md`

Resultado atual:

- O latest real e
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass` e
  `mandatory_gate_divergences=[]`.
- `mandatory_gate_statuses.strategy_audit.status=pass`,
  `findings=2`, `low_confidence_findings=2`,
  `review_required_findings=0` e `blocking_seeds=[]`.
- `strategy_learning_confidence_counts={"high_confidence_replay":14,
  "low_confidence_replay":2}`.
- `strategy_high_confidence_learning_seeds=["63202022","63202023",
  "63202024","63202026","63202027","63202028","63202029","63202030",
  "63202032","63202033","63202034","63202035","63202036","63202037"]`.
- `strategy_low_confidence_seeds=["63202025","63202031"]`.
- `strategy_not_learning_eligible_seeds=[]`.
- `research_review.categories.mulligan.status=blocked_or_needs_review`,
  com `finding_counts={"forced_keep_after_bad_mulligan":2}`.

Leitura dos dois seeds low-confidence:

- `63202025`: `decision-000005`, player `Kraum, Ludevic's Opus #83 (real)`,
  keep forcado apos `mulligan_count=3`, `score=-7.0`,
  `risk_flags=["mana_screw","forced_keep_after_mulligan_cap"]`, `lands=1`,
  `cards_in_hand=5`; finding medio:
  `mana_screw, negative_keep_score, too_few_lands`.
- `63202031`: `decision-000005`, player `Kraum, Ludevic's Opus #83 (real)`,
  keep forcado apos `mulligan_count=3`, `score=-3.0`,
  `risk_flags=["no_early_game_plan","reactive_only_opener",
  "forced_keep_after_mulligan_cap"]`, `lands=3`, `cards_in_hand=5`; finding
  medio: `negative_keep_score, no_early_game_plan`.
- Nos dois seeds, `strategy_audit.summary.high_confidence_learning_eligible=false`
  e `high_confidence_learning_weight=0.0`.
- Nos dois seeds, action critic, forensic audit e replay decision audit tem
  `0` findings.

Leitura operacional:

- Nao ha novo BV para o contrato de learning confidence: a separacao entre seed
  high-confidence e low-confidence esta funcionando no latest atual.
- `trusted_for_strategy_learning` continua significando "todos os gates
  obrigatorios passaram", nao "todos os seeds sao high-confidence".
- O risco operacional continua sendo consumo downstream: WR/baseline/handoff
  deve usar `strategy_high_confidence_learning_seeds`, e nao todos os seeds
  completados.
- `BATTLE_REPLAY_GATE_MATRIX.md` ainda documenta o contrato correto, mas a
  secao "Current Gate Reading" esta stale: aponta `20260619_184721` e `13/3`,
  enquanto o latest atual e `20260619_203855` com `14/2`. Isso atualiza a
  evidencia de `BV-058`.

Validacoes executadas nesta etapa:

- Parse do `summary.json` atual.
- Parse de `research_review.json` e `research_review.md`.
- Parse de `strategy_audit.json` e `strategy_audit.md` dos seeds `63202025` e
  `63202031`.
- Parse de `replay.decision_trace.jsonl` dos dois seeds para confirmar os keeps
  forcados.
- Parse de `action_critic.json`, `forensic_audit.json` e
  `replay_decision_audit.json` dos dois seeds.
- Inspecao de `BATTLE_REPLAY_GATE_MATRIX.md` e comparacao com
  `battle_strategy_learning_confidence_scope_audit_20260619_191643.md`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py` - PASS.

## Passo de auditoria - documentation/artifact contract recheck 2026-06-19T20:47Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_documentation_artifact_contract_recheck_20260619_204742.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/event_contract_static.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/test_*.log`
- `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md`
- `docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Resultado atual:

- Latest real: `20260619_203855`, `timestamp_utc=2026-06-19T20:38:55Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass` e
  `mandatory_gate_divergences=[]`.
- Sem high/critical em action findings, sem strategy blockers e sem
  high/critical forensic findings.
- `BATTLE_REPLAY_GATE_MATRIX.md` agora esta current as of
  `2026-06-19T20:38Z` e aponta para `20260619_203855`; a parte antiga de
  `BV-058` sobre a secao `Current Gate Reading` da matriz ficou superada.
- `BATTLE_SYSTEM_LOGIC.md` ainda traz no topo o snapshot historico
  `2026-06-19T16:42:53Z` com
  `battle_replay_final_status=review_required`.
- `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` ainda diz que
  `BATTLE_REPLAY_GATE_MATRIX.md` foi atualizada para o latest
  `20260619_184721`, apesar da propria matriz ja apontar para `20260619_203855`.
- `event_contract_static.json.summary.static_engine_sources` agora inclui
  `battle_analyst_v9.py`, `battle_sba_support.py` e
  `battle_replacement_support.py`; `observed_not_static_literal=[]`,
  `field_findings_count=0`, `all_event_types_total=100` e
  `test_battle_event_contract_static_audit.log` mostra `5 tests passed`.
- `summary.json` ainda nao publica matriz de testes: `.test_results` retorna
  `null`. O diretorio do run tem `15` `test_*.log`, mas
  `test_battle_effect_coverage_known_cards.log` segue vazio (`0` bytes).
- A divergencia semantica de `BV-068` segue atual:
  `mandatory_gate_statuses.effect_coverage.unknown_effects=0` e
  `effect_coverage_unknowns=0`, mas
  `effect_coverage_effect_totals_unknown=41` e
  `focused_template_ready_unknown_effect_count=28`.

Leitura operacional:

- `BV-070` foi fechado por evidencia atual: o auditor estatico ja varre os
  emissores de suporte e nao ha evento observado fora do inventario estatico.
- `BV-058` permanece aberto, mas agora limitado ao router/status index e ao
  snapshot antigo no `BATTLE_SYSTEM_LOGIC.md`; a gate matrix em si nao esta mais
  stale.
- `BV-073` permanece aberto porque `summary.json` ainda nao prova comandos,
  exit codes, duracoes e stdout/stderr dos testes.
- `BV-068` permanece aberto porque `unknown_template_backlog_cards=0` e
  `unknown_effects=0` no gate nao significam zero `effect=unknown`.

ID removido de `Achados abertos` por evidencia atual:

- `BV-070`

Validacoes executadas nesta etapa:

- Parse de `summary.json`, `event_contract_static.json`,
  `effect_coverage.json` e `runtime_surface_manifest.json`.
- `wc` e leitura inicial dos `15` arquivos `test_*.log` do latest.
- `rg` em `BATTLE_SYSTEM_LOGIC.md`,
  `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`,
  `BATTLE_REPLAY_GATE_MATRIX.md` e neste register.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py` - PASS, `5 tests passed`.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS, `Ran 6 tests ... OK`.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py` - PASS.

## Passo de auditoria - optimizer surface gate coverage 2026-06-19T20:53Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_optimizer_surface_gate_coverage_recheck_20260619_205344.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826/runtime_surface_manifest.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_baseline.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_quality_gate.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_confirmation.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_handoff.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_apply.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_loop.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_post_apply_gate.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_product_handoff.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_rollback.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/universal_optimizer.py`

Resultado atual:

- Latest real: `20260619_204826`, `timestamp_utc=2026-06-19T20:48:26Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass` e
  `mandatory_gate_divergences=[]`.
- Sem high/critical em action findings, sem strategy blockers e sem
  high/critical forensic findings.
- `runtime_surface_manifest_total_files=108`; `optimizer/scorecard=15`;
  todo arquivo `optimizer/scorecard` esta em `outside_recurring_run`.
- Busca estatica por `battle_gate`, `Battle Replay Gate`,
  `load_battle_gate_summary`, `battle_replay_final_status`,
  `mandatory_gate_divergences` e campos de strategy confidence encontrou gate
  em `master_optimizer_common.py`, `master_optimizer_baseline.py`,
  `master_optimizer_quality_gate.py`, `master_optimizer_confirmation.py`,
  `master_optimizer_handoff.py` e `slot_optimizer.py`.
- A mesma busca nao encontrou gate em `master_optimizer_apply.py`,
  `master_optimizer_loop.py`, `master_optimizer_post_apply_gate.py`,
  `master_optimizer_product_handoff.py`, `master_optimizer_rollback.py` e
  `universal_optimizer.py`.

Leitura operacional:

- `BV-057` permanece fechado para os scripts explicitamente cobertos:
  baseline, quality gate, confirmation, handoff, slot optimizer e helper comum.
- A superficie completa `optimizer/scorecard` ainda nao esta uniformemente
  carimbada com o contexto do `Battle Replay Gate`.
- Isto nao prova swap errado; prova que os relatorios/CLI de apply, post-apply,
  product handoff, rollback, preflight loop e universal optimizer podem ser
  lidos sem o status de gate agregado, splits high/low-confidence e divergencias
  obrigatorias.

Novo achado aberto:

- `BV-074`

Validacoes executadas nesta etapa:

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_apply.py docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_loop.py docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_post_apply_gate.py docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_product_handoff.py docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_rollback.py docs/hermes-analysis/manaloom-knowledge/scripts/universal_optimizer.py` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py` - PASS, `Ran 5 tests ... OK`.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_slot_optimizer_real_roles.py` - PASS, `Ran 4 tests ... OK`.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_universal_optimizer_known_cards.py` - PASS, `Ran 2 tests ... OK`.

## Passo de auditoria - learned deck source provenance 2026-06-19T21:00Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_learned_deck_source_provenance_recheck_20260619_210007.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826/seed_*/deck_provenance.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260619_205609.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`

Resultado atual:

- Latest real: `20260619_204826`, `timestamp_utc=2026-06-19T20:48:26Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass` e
  `mandatory_gate_divergences=[]`.
- Sem high/critical em action findings, sem strategy blockers e sem
  high/critical forensic findings.
- `summary.json` publica fonte e metricas do Lorehold:
  `sqlite_deck_cards deck_id:6`,
  `runtime_derived_from_resolved_card_list`, cached metadata `false`,
  `lands=33` e `avg_cmc_nonlands=2.97`.
- Nos `deck_provenance.json`, os oponentes learned do latest aparecem com
  `source_kind=learned_decks`, `source_system=pg_meta_decks`,
  `source_card_count=100`, `battle_card_count=99`,
  `metrics_basis=runtime_derived_from_resolved_built_deck`,
  cached metadata `false` e `blocker_domain=none`, mas sem
  `construction_report`.
- O `summary.json` agrega `deck_source_blocker_domains={"none":64}` e campos
  Lorehold, mas nao agrega lista/resumo de oponentes learned, `source_system`,
  `source_card_count`, `battle_card_count`, `construction_valid`,
  `commander_count` ou issues de coerencia por oponente.
- O audit de coerencia learned-deck `20260619_205609` e read-only e ainda
  mostra `active_learned_decks=60`, `high=173`, `medium=21`.
- Exemplo de ambiguidade: no latest de battle,
  `source_system=pg_meta_decks source_ref=learned_deck:116` aparece como
  `Tayam, Luminous Enigma #116 (real)`; no audit de coerencia learned-deck, o
  mesmo par `pg_meta_decks/learned_deck:116` aparece como
  `K-9, Mark I + The Fourteenth Doctor`, com issues high e
  `commander_deck_shape.passes_shape=false`. A leitura conservadora e nao
  concluir troca de deck so por isso, mas exigir chave/provenance inequivoca
  antes de usar `source_ref` isolado em handoff ou consumo downstream.

Leitura operacional:

- O replay passa o gate obrigatorio e nao esta usando metadata cacheada para as
  metricas publicadas.
- A fronteira de source deck dos oponentes learned ainda nao esta visivel no
  resultado principal.
- Falhas de coerencia/source deck devem continuar separadas de falhas de engine
  battle, mas precisam aparecer como warning/gate proprio de aprendizagem quando
  a partida depender de learned decks oponentes.

Novo achado aberto:

- `BV-075`

Validacoes executadas nesta etapa:

- `jq` no latest `summary.json` - PASS.
- `jq` agregado em `seed_*/deck_provenance.json` - PASS.
- `jq` no `learned_deck_coherence_audit_20260619_205609.json` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_learned_deck_completeness.py` - PASS, `Ran 4 tests ... OK`.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_materialize_learned_deck_to_deck_cards.py` - PASS, `Ran 1 test ... OK`.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_export_hermes_learned_deck_metadata.py` - PASS, `Ran 3 tests ... OK`.

## Passo de auditoria - latest action template effect denominator 2026-06-19T21:04Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_action_template_effect_denominator_recheck_20260619_210435.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826/unknown_template_backlog.json`

Resultado atual:

- Latest real: `20260619_204826`, `timestamp_utc=2026-06-19T20:48:26Z`.
- `battle_replay_final_status=trusted_for_strategy_learning` e
  `mandatory_gate_divergences=[]`.
- Sem high/critical em action findings, sem strategy blockers e sem
  high/critical forensic findings.
- `focused_template_dispatch_status=focused_template_dispatch_ready`.
- `focused_template_cards=29`, `focused_template_evidence_ready=29`,
  `focused_template_supports_template_count=47`,
  `focused_template_build_evidence_function_count=47` e
  `focused_template_evaluate_dispatch_template_count=47`.
- `focused_template_cards_without_dispatch=[]`,
  `focused_template_cards_without_predicate=[]` e
  `focused_template_cards_not_ready_unwaived=[]`.
- `unknown_template_backlog_status=focused_template_backlog_ready`,
  `unknown_template_backlog_cards=0` e `effect_coverage_unknowns=0`.
- Mesmo assim, `effect_coverage_effect_totals_unknown=41`.
- `focused_template_ready_known_effect_count=1` e
  `focused_template_ready_unknown_effect_count=28`.
- `effect_coverage.json` confirma `focused_template_unknown_effect_scope_cards`
  com `28` cards; todos tem escopo focado, como `copy_artifact_as_enters`,
  `manifest_cloak_equipment`, `convoke_damage`, `split_second_damage`,
  `modal_mass_sacrifice_selection` e `planeswalker_static_activated_graveyard`.

Leitura operacional:

- A resposta atual para "todos os templates de acoes de cartas estao criados?"
  deve ser: a fila focada atual esta pronta, mas o coverage principal ainda nao
  prova fechamento total de templates/efeitos.
- `unknown_template_backlog_cards=0` fecha o denominador de source/backlog
  unknown, nao o denominador de `effect=unknown`.
- `focused_template_dispatch_ready` prova suporte/build/dispatch/evidence para
  os `29` cards focados, mas nao reconcilia automaticamente o `effect` do
  coverage principal.
- `BV-068` permanece aberto, agora com evidencia atualizada no latest
  `20260619_204826`.

Novo achado aberto:

- Nenhum; esta etapa revalida `BV-068`.

Validacoes executadas nesta etapa:

- `jq` no latest `summary.json` - PASS.
- `jq` em `effect_coverage.json` - PASS.
- `jq` em `focused_template_dispatch.json` - PASS.
- `jq` em `unknown_template_backlog.json` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS, `Ran 6 tests ... OK`.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py` - PASS.

## Passo de auditoria - latest test log provenance 2026-06-19T21:08Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_test_log_provenance_recheck_20260619_210807.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826/test_*.log`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`

Resultado atual:

- Latest real: `20260619_204826`, `timestamp_utc=2026-06-19T20:48:26Z`.
- `battle_replay_final_status=trusted_for_strategy_learning` e
  `mandatory_gate_divergences=[]`.
- Sem high/critical em action findings, sem strategy blockers e sem
  high/critical forensic findings.
- No `summary.json`, `test_results=null`, `test_logs=null`,
  `py_compile=null` e `tests=null`.
- No run real existem `15` arquivos `test_*.log`.
- `test_battle_effect_coverage_known_cards.log` tem `0` bytes e `0` linhas.
- Os demais logs variam de `15` bytes a `14929` bytes.
- O wrapper executa `python3 -m py_compile` e depois `15` testes com stdout
  redirecionado para `$run_dir/test_*.log`.
- O wrapper depende de `set -e` para abortar antes do `summary.json` se algum
  comando falhar, mas nao materializa exit code, stderr bytes, comando ou status
  individual por teste no resultado principal.

Leitura operacional:

- `BV-073` permanece aberto.
- A existencia do `summary.json` prova indiretamente que a etapa de teste nao
  abortou, mas nao e uma matriz de teste auditavel.
- Log vazio nao deve ser tratado como teste nao executado nem como prova plena
  de sucesso; precisa de `exit_code=0`, comando e bytes stdout/stderr no
  `summary.json`.

Novo achado aberto:

- Nenhum; esta etapa revalida `BV-073`.

Validacoes executadas nesta etapa:

- `jq` no latest `summary.json` - PASS.
- `find`/`stat`/`wc` nos logs do run real `20260619_204826` - PASS.
- Leitura somente de trechos do wrapper `manaloom-battle-strategy-audit.sh` -
  PASS.

## Passo de auditoria - current docs router/taxonomy recheck 2026-06-19T21:10Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_documentation_current_router_recheck_20260619_211033.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826/decision_trace_taxonomy.json`
- `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md`
- `docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_DECISION_TRACE_TAXONOMY.md`

Resultado atual:

- Latest real: `20260619_204826`, `timestamp_utc=2026-06-19T20:48:26Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass` e
  `mandatory_gate_divergences=[]`.
- `BATTLE_SYSTEM_LOGIC.md` ainda embute no topo o snapshot antigo
  `2026-06-19T16:42:53Z` com
  `battle_replay_final_status=review_required`.
- `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` ainda diz que
  `BATTLE_REPLAY_GATE_MATRIX.md` foi atualizado para latest `20260619_184721`
  e nao lista os reports tardios que hoje explicam `BV-068`, `BV-073`,
  `BV-074` e `BV-075`.
- `BATTLE_REPLAY_GATE_MATRIX.md` esta em estado melhor, mas seu
  `Current Gate Reading` aponta para `20260619_203855`, nao para o latest real
  `20260619_204826`.
- A gate matrix cita `event_contract_static` com `53` event types observed e
  `44` waivers; latest real mostra `52` observed event types, `100` static
  event types e `48` accepted fixture waivers.
- `BATTLE_DECISION_TRACE_TAXONOMY.md` ainda aponta para `20260619_171605`,
  com `decision_trace_rows=152`, `decision_trace_kinds_observed=10` e
  `decision_trace_kinds_uncovered=5`.
- Latest real mostra `decision_trace_taxonomy_rows=2221`,
  `decision_trace_kinds_observed=12`,
  `decision_trace_kinds_uncovered=3` e
  `decision_trace_static_uncovered_types=["activated_sacrifice_damage","attack_trigger_artifact_tutor","worldfire_reset"]`.

Leitura operacional:

- `BV-058` permanece aberto: os docs marcados como current ainda podem levar um
  leitor para snapshots antigos antes de chegar ao latest real e ao register.
- `BV-060` permanece aberto: a taxonomia markdown continua util como contrato
  conceitual, mas nao prova mais as contagens/corpus atuais.
- Nao foi criado novo BV porque as causas raiz ja estao representadas por
  `BV-058` e `BV-060`.

Validacoes executadas nesta etapa:

- `jq` no latest `summary.json` - PASS.
- `jq` em `decision_trace_taxonomy.json` do latest - PASS.
- Leitura de `BATTLE_SYSTEM_LOGIC.md` - PASS.
- Leitura de `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` - PASS.
- Leitura de `BATTLE_REPLAY_GATE_MATRIX.md` - PASS.
- Leitura de `BATTLE_DECISION_TRACE_TAXONOMY.md` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_trace_taxonomy_audit.py` - PASS, `3 tests passed`.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py` - PASS, `5 tests passed`.

## Passo de auditoria - latest human replay renderer 2026-06-19T21:14Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_human_replay_renderer_recheck_20260619_211452.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826/seed_*/replay.txt`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826/seed_*/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826/seed_*/replay.decision_trace.jsonl`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py`

Resultado atual:

- Latest real: `20260619_204826`, `timestamp_utc=2026-06-19T20:48:26Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass` e
  `mandatory_gate_divergences=[]`.
- Sem high/critical em action findings, sem strategy blockers e sem
  high/critical forensic findings.
- `decision_audit_human_replay_complete=not_evaluated_by_replay_decision_auditor`.
- `decision_audit_rules_interaction_trusted=not_evaluated_by_replay_decision_auditor`.
- Nas 16 seeds, `replay.txt` soma `7608` linhas, contra `14457` eventos JSONL
  e `2221` decision traces.
- Busca no texto humano encontrou `100` placeholders: `97` `CMC=?` e `3`
  `life=?->`; nao encontrou `event=?`, `stack=?`, `target=?`, `phase=?` ou
  `priority_window=?`.
- No JSONL fonte, ha `8` `utility_land_activated` com `life_paid` sem
  `life_before/life_after`, `25` `commander_cast` sem `cmc`, `51`
  `miracle_cast` sem `cmc` e `21` `end_step_instant` sem `cmc`.
- Todos os `10/10` `spell_countered` continuam sem `phase` e sem
  `priority_window`, mas isto permanece coberto por `BV-064`.
- `spell_resolved` melhorou neste latest: `0/310` estao sem `phase`, entao a
  parte de fase de `BV-066` precisa ser lida como historica/parcialmente
  superada para este run especifico, sem fechar o criterio completo de
  provenance de resolucao.
- O teste atual do renderer ainda aceita explicitamente placeholder de vida:
  `assert "life=?->38 life_paid=2" in activation_line`.

Leitura operacional:

- `BV-063` permanece aberto.
- O latest e trusted pelos mandatory gates, mas `replay.txt` continua sendo uma
  projecao humana, nao o ledger completo de aprendizagem.
- Houve melhora contra a evidencia antiga, mas os placeholders atuais ainda
  impedem usar o texto sozinho para auditar custo/curva/vida.
- O contrato de teste atual ainda legitima `life=?->`, entao a ausencia nao
  sera removida apenas por suite verde.

Novo achado aberto:

- Nenhum; esta etapa revalida `BV-063`.

Validacoes executadas nesta etapa:

- `jq` no latest `summary.json` - PASS.
- `wc -l` em todos os `replay.txt`, `replay.events.jsonl` e
  `replay.decision_trace.jsonl` - PASS.
- `rg` dos placeholders no `replay.txt` - PASS.
- `jq` dos eventos sem `cmc`, `life_before/life_after`, phase/priority e
  `spell_resolved.phase` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_replay_decision_auditor_scope.py` - PASS.

## Passo de auditoria - latest review-required functional tag/decision trace 2026-06-19T21:45Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_review_required_functional_tag_decision_trace_recheck_20260619_184507.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_213957/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_213957/seed_63202142/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_213957/seed_63202142/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_213957/seed_63202150/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_213957/seed_63202150/replay.decision_trace.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_213957/seed_63202150/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_213957/seed_63202150/forensic_audit.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`

Resultado atual:

- Latest real mudou para `20260619_213957`, `timestamp_utc=2026-06-19T21:39:57Z`.
- `battle_replay_final_status=review_required`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`.
- `mandatory_gate_divergences=["action_critic=review_required","forensic_audit=review_required"]`.
- `action_findings=1`.
- `forensic_rule_findings=4`, `forensic_turn_findings=0`.
- `forensic_severity_counts={"low":2,"medium":2}`.
- `forensic_lineage_status=incomplete`.
- `forensic_card_id_missing_unaccepted=2`.
- `forensic_semantic_hash_missing_unaccepted=2`.
- Sem high/critical action findings, sem strategy blockers e sem high/critical
  forensic findings.
- Strategy segue com `14` high-confidence e `2` low-confidence seeds, mas o
  run nao e globalmente learning-trusted por gates obrigatorios.

Falha A - `functional_tags_json` voltou:

- O latest anterior `20260619_204826` tinha `0` eventos
  `functional_tags_json`; o latest atual voltou a exercitar esse fallback.
- Foram encontrados `6` eventos `functional_tags_json`, todos de
  `Faeburrow Elder`:
  - seed `63202142`, turn `11`, `cast_announced`, `cost_paid`, `spell_cast`;
  - seed `63202150`, turn `7`, `cast_announced`, `cost_paid`, `spell_cast`.
- Todos os `6/6` eventos tem `rule_source=functional_tags_json`,
  `rule_review_status=heuristic`, sem `card_id`, sem `semantic_hash`, sem
  `rule_logical_key` e sem `decision_trace_id`.
- Forensic gerou `2` findings medium por fonte heuristica e `2` findings low
  porque `ramp_permanent` difere do registry effect `ramp_ritual`.
- `Faeburrow Elder` nao aparece no conjunto atual de
  `MANUAL_RULE_RUNTIME_WAIVERS`; portanto caiu no fallback amplo de
  `card_functional_tags(card)` -> `TAG_EFFECTS[tag]`.
- `BV-067` deixa de ser somente risco latente: no latest atual voltou a ser
  achado ativo de run.

Falha B - correlacao de decision trace em `Silence`:

- O action critic emitiu `missing_decision_trace` low para
  `seed_63202150`, `action-000154`, event index `399`, turn `6`,
  `precombat_main`, `Lorehold`, `spell_cast`, card `Silence`.
- O evento do cast esta bem formado quanto a regra: `curated/verified`,
  `effect=silence_spell`, `locked_cost={white=1,generic=0}`,
  `source_zone=hand`, com `card_id`, `semantic_hash` e `rule_logical_key`.
- Existe decision trace plausivel: `decision-000070`, turn `6`,
  `precombat_main`, `Lorehold`, `decision_type=cast_spell`,
  `chosen_option.card=Silence`, `actual_outcome=cast_to_stack`,
  `rule_source=curated`, `rule_status=verified`.
- O action critic, porem, associou `decision-000070` ao `miracle_cast` anterior
  de `Silence` no `draw_step` (`action-000143`), e o `spell_cast` posterior de
  `Silence` ficou sem match.
- O codigo do critic usa chave `(turn, player, card)` para casar action event e
  decision trace; isso nao diferencia fase, tipo de evento, cast pipeline ou um
  `decision_trace_id` explicito.

Leitura operacional:

- O resultado principal atual exige revisao, mesmo sem high/critical.
- `BV-067` deve permanecer aberto como P2 e ativo no latest.
- Novo achado aberto `BV-077`: quando a mesma carta aparece mais de uma vez no
  mesmo turno, o matching por `(turn, player, card)` pode consumir a decision
  trace errada e mascarar/gerar `missing_decision_trace`.
- O caso `Silence` nao indica regra de carta ruim; indica gap de correlacao
  entre ledger de eventos e ledger de decisoes.

Validacoes executadas nesta etapa:

- `jq` no latest `summary.json` - PASS.
- `jq` dos findings em `action_critic.json` e `forensic_audit.json` - PASS.
- `jq` dos eventos `functional_tags_json` nas 16 seeds - PASS.
- `jq` do evento `Silence` e da `decision-000070` - PASS.
- `rg`/`sed` de `battle_analyst_v9.py`, `battle_action_critic.py` e
  `battle_forensic_audit.py` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_functional_tags_json.py` - PASS.

## Passo de auditoria - latest cross-gate learning eligibility 2026-06-19T21:49Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_cross_gate_learning_eligibility_recheck_20260619_184956.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539/seed_*/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539/seed_*/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539/seed_*/forensic_audit.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py`

Resultado atual:

- Latest real mudou para `20260619_214539`, `timestamp_utc=2026-06-19T21:45:39Z`.
- `battle_replay_final_status=review_required`.
- `mandatory_gate_divergences=["action_critic=review_required","forensic_audit=review_required"]`.
- `action_findings=1`.
- `forensic_rule_findings=2`.
- `forensic_lineage_status=incomplete`.
- `strategy_audit.status=pass`, com `strategy_audit.findings=8` e
  `strategy_audit.low_confidence_findings=8`.
- `strategy_learning_confidence_counts={"high_confidence_replay":11,"low_confidence_replay":5}`.
- `strategy_high_confidence_learning_seeds=["63202145","63202146","63202148","63202149","63202151","63202152","63202153","63202154","63202156","63202158","63202159"]`.
- `strategy_low_confidence_seeds=["63202147","63202150","63202155","63202157","63202160"]`.
- `strategy_not_learning_eligible_seeds=[]`.
- Sem high/critical action findings, sem strategy blockers e sem high/critical
  forensic findings.

Leitura por seed:

- A seed com problemas de action/forensic no latest atual e `63202150`.
- `63202150` esta em `strategy_low_confidence_seeds`, nao em
  `strategy_high_confidence_learning_seeds`.
- Ou seja: diferente da evidencia antiga de `BV-072`, este snapshot nao
  contamina a lista high-confidence com a seed que tem action/forensic review.
- O gap semantico continua porque `strategy_not_learning_eligible_seeds=[]` e
  apenas campo do auditor estrategico; nao e lista global apos action,
  forensic, decision, template e event contract.
- O summary ainda nao publica `global_learning_eligible_seeds`,
  `global_not_learning_eligible_seeds` ou reasons por seed.

Evidencia de codigo:

- `battle_decision_strategy_auditor.py` define `learning_confidence`,
  `high_confidence_learning_eligible` e `high_confidence_learning_weight` apenas
  a partir dos findings estrategicos da seed.
- `battle_decision_research_review.py` agrega
  `strategy_high_confidence_learning_seeds`, `strategy_low_confidence_seeds` e
  `strategy_not_learning_eligible_seeds` apenas a partir de
  `strategy_audit.json`.
- `master_optimizer_common.py` mostra gates obrigatorios e amostras de
  `strategy_*`, mas nao publica uma lista global por seed depois de todos os
  gates.
- Busca por `global_learning_eligible`/`global_not_learning` nao encontrou campo
  equivalente nos helpers de strategy/optimizer.

Leitura operacional:

- `BV-072` permanece aberto, mas com nuance atual: o latest `214539` nao mostra
  high-confidence contaminado; mostra ausencia de contrato global pos-gate.
- O fechamento correto ainda e publicar elegibilidade global com reasons, ou
  renomear/expor claramente os campos atuais como `strategy_audit_*`.

Validacoes executadas nesta etapa:

- `jq` do latest `summary.json` - PASS.
- `jq` por seed de `strategy_audit.json`, `action_critic.json` e
  `forensic_audit.json` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py --input-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539` - PASS.

## Passo de auditoria - latest template completeness denominator 2026-06-19T21:54Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_template_completeness_denominator_recheck_20260619_185443.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539/effect_coverage.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539/focused_template_dispatch.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539/unknown_template_backlog.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539/unknown_template_backlog.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_214539/effect_coverage_residual.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_residual_audit.py`

Resultado atual:

- Latest real: `20260619_214539`, `timestamp_utc=2026-06-19T21:45:39Z`.
- `battle_replay_final_status=review_required` por
  `action_critic=review_required` e `forensic_audit=review_required`.
- Sem high/critical action findings, sem strategy blockers e sem high/critical
  forensic findings.
- `focused_template_dispatch_status=focused_template_dispatch_ready`.
- `focused_template_cards=29`, `focused_template_evidence_ready=29`,
  `focused_template_cards_not_ready_unwaived=[]`.
- `focused_template_supports_template_count=47`,
  `focused_template_build_evidence_function_count=47`,
  `focused_template_evaluate_dispatch_template_count=47`.
- `unknown_template_backlog_cards=0` e `effect_coverage_unknowns=0`.
- Mas `effect_coverage_effect_totals_unknown=41`.
- `focused_template_ready_unknown_effect_count=28` e
  `focused_template_ready_known_effect_count=1`.
- `effect_coverage_residual_status=effect_coverage_residual_accepted`, com
  `accepted_card_flag_rows=290`, `unique_flagged_cards=237` e
  `raw_flag_total=536`.

Leitura dos denominadores:

- A fila focada atual esta pronta para dispatch/evidence; isso e uma boa
  evidencia de contrato para a lista focada.
- Isso nao prova que todos os templates/efeitos de acoes de cartas estao
  criados ou reconciliados.
- `unknown_template_backlog_cards=0` significa que nao ha carta source-unknown
  sem familia/plano/template; nao significa zero `effect=unknown`.
- `effect_coverage_effect_totals_unknown=41` e `28/29` cartas focused-template
  ready ainda com `effect=unknown` mostram que a familia de evidencia existe,
  mas o coverage principal ainda nao promoveu essas familias para effect labels
  estaveis.
- `effect_coverage_residual_accepted` e politica de aceitacao de residuos, nao
  eliminacao de residuos.

Cartas focused-template ready que ainda carregam `effect=unknown`:

- `Ashnod's Transmogrant`, `Candelabra of Tawnos`, `Clown Car`,
  `Codex Shredder`, `Copy Artifact`, `Cryptic Coat`, `Cursed Windbreaker`,
  `Dissection Tools`, `Firestorm`, `Flash Photography`,
  `God-Pharaoh's Statue`, `Heroes' Hangout`, `Hidden Strings`,
  `Kindle the Inner Flame`, `Liquimetal Coating`, `Mine Collapse`,
  `Nevermore`, `Opera Love Song`, `Out of Time`, `Power Artifact`,
  `Reality Acid`, `Scroll of Fate`, `Stoke the Flames`, `Submerge`,
  `Sudden Shock`, `Thorn of Amethyst`, `Tragic Arrogance` e
  `Tyvar, Jubilant Brawler`.

Residuos aceitos atuais:

- Owner totals: `battle-effect-contract=153`,
  `battle-heuristic-fallback=87`, `battle-land-utility-contract=21`,
  `battle-rule-review-queue=29`.
- Flag totals: `cast_permission_not_explicit=35`,
  `copy_effect_mismatch=1`, `heuristic_effect=87`,
  `land_utility_ability_not_modeled=21`, `needs_review_rule=29`,
  `oracle_silence_mismatch=4`, `oracle_target_removal_mismatch=12`,
  `temporary_effect_not_explicit=38`, `trigger_not_explicit=63`.

Leitura operacional:

- `BV-059` permanece aberto: residual aceito nao e completude runtime.
- `BV-068` permanece aberto: `effect_totals.unknown=41` e `28/29` focused
  cards com `effect=unknown`.
- A resposta operacional para "todos os templates estao criados?" e: a fila
  focada atual tem dispatch/evidence pronta, mas a completude total de
  templates/efeitos de battle ainda nao esta provada.

Validacoes executadas nesta etapa:

- `jq` do latest `summary.json`, `effect_coverage.json`,
  `focused_template_dispatch.json`, `unknown_template_backlog.json` e
  `effect_coverage_residual.json` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_focused_template_dispatch_audit.py` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_residual_audit.py` - PASS.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS.

## Passo de auditoria - latest forensic/gate matrix recheck 2026-06-19T22:27Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_forensic_gate_matrix_recheck_20260619_192717.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/seed_63202164/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/seed_63202164/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/seed_63202164/replay_decision_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/seed_63202164/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/seed_63202164/replay.events.jsonl`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Resultado atual:

- Latest real: `20260619_215228`, `timestamp_utc=2026-06-19T21:52:28Z`.
- `battle_replay_final_status=review_required`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
  e `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- Nao ha high/critical em action findings, nao ha strategy blockers e nao ha
  high/critical forensic findings.
- O unico gate obrigatorio em review e `forensic_audit`: `rule_findings=1`,
  `turn_findings=0`, severidade agregada `medium=1`.
- A seed `63202164` tem `Infernal Plunge` em `spell_cast`, turno `3`,
  `precombat_main`, player `Dargo, the Shipwrecker #74 (real)`,
  `effect=ramp_permanent`, `rule_source=functional_tags_json`,
  `rule_review_status=heuristic` e `rule_confidence=0.35`.
- O forensic da mesma seed mostra `lineage_unaccepted_missing_samples` para
  `Infernal Plunge` faltando `rule_logical_key`, `card_id` e `semantic_hash`.
- Na mesma seed, `action_critic.json` tem `findings=0`,
  `replay_decision_audit.json` tem `decision_findings=0` e `turn_findings=0`,
  e `strategy_audit.json` marca `high_confidence_learning_eligible=true`,
  `high_confidence_learning_weight=1.0` e
  `learning_confidence=high_confidence_replay`.
- O summary inclui `63202164` em `strategy_high_confidence_learning_seeds`,
  mantem `strategy_not_learning_eligible_seeds=[]`, mas o run final esta
  `review_required` por forensic e ainda nao publica campos globais de
  elegibilidade pos-gates.
- `BATTLE_REPLAY_GATE_MATRIX.md` se declara current as of `2026-06-19T21:40Z`,
  mas seu `Current Gate Reading` aponta para `20260619_204826` como
  `trusted_for_strategy_learning` e `mandatory_gate_divergences=[]`, divergindo
  do latest real `20260619_215228` review-required.

Leitura operacional:

- `BV-067` permanece aberto e ativo: a falha funcional por
  `functional_tags_json` reapareceu com outro card (`Infernal Plunge`), agora
  com uma finding medium que mantem o gate forense em review.
- `BV-072` volta a ter evidencia direta no latest: uma seed considerada
  high-confidence pelo strategy auditor (`63202164`) nao pode ser lida como
  globalmente learning-grade porque o gate final do run esta `review_required`
  por forensic na mesma seed.
- `BV-058` permanece aberto: a gate matrix contem contrato correto, mas seu
  bloco de leitura atual esta stale e contradiz o latest summary.
- Nao foi criado novo BV porque as causas raiz ja estao representadas por
  `BV-058`, `BV-067` e `BV-072`.

Validacoes executadas nesta etapa:

- `git status --short` - arvore ja estava suja; nenhuma mudanca externa foi
  revertida.
- `realpath` do symlink `latest` - PASS.
- `jq` no latest `summary.json` - PASS.
- `jq` em `seed_63202164/forensic_audit.json` - PASS.
- `jq` em `seed_63202164/action_critic.json`,
  `replay_decision_audit.json` e `strategy_audit.json` - PASS.
- `jq` em `seed_63202164/replay.events.jsonl` para eventos de
  `Infernal Plunge` - PASS.
- Leitura de `BATTLE_REPLAY_GATE_MATRIX.md` - PASS.

## Passo de auditoria - latest learned-deck opponent provenance recheck 2026-06-19T22:32Z

Artefato:

- `docs/hermes-analysis/master_optimizer_reports/battle_latest_learned_deck_opponent_provenance_recheck_20260619_193206.md`

Fonte:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/seed_*/deck_provenance.json`

Resultado atual:

- O latest `summary.json` lista `16` arquivos em `deck_provenance_files` e
  publica `deck_source_blocker_domains={"none":64}`.
- O summary publica a fonte do deck Lorehold
  (`lorehold_deck_source_kind=sqlite_deck_cards`,
  `lorehold_deck_source_ref=deck_id:6`) e a politica
  `deck_metrics_policy=runtime_derived_from_resolved_card_lists`.
- O summary nao publica campos agregados como `learned_deck_opponents`,
  `opponent_deck_provenance` ou `learned_opponent_source_counts`.
- Os `16` arquivos por-seed contem `48` aparicoes de learned opponents,
  agrupadas em `12` refs unicos.
- Todos os learned opponents observados tem `source_system=pg_meta_decks`,
  `source_kind=learned_decks`, `source_card_count=100`,
  `battle_card_count=99`, `cached_metadata_used_for_metrics=false`,
  `metrics_basis=runtime_derived_from_resolved_built_deck` e
  `blocker_domain=none`.
- Para todos os learned opponents observados, `construction_report=null`.
- O deck Lorehold fonte aparece nos `16` arquivos com `construction_report`
  valido (`is_valid=true`, `main_quantity=99`, `total_quantity=100`,
  `commander_count=1`, sem off-color/singleton issues).

Leitura operacional:

- `BV-075` permanece aberto: a provenance por-seed esta disponivel e melhorou,
  mas o resultado principal ainda nao agrega learned opponents nem status de
  construction/coherence por oponente.
- `battle_replay_final_status` deve continuar sendo lido como gate de engine, e
  nao como prova de coerencia dos source decks learned.

Validacoes executadas nesta etapa:

- `jq` no latest `summary.json` - PASS.
- `jq` em todos os `seed_*/deck_provenance.json` - PASS.
- Agrupamento read-only dos learned opponents por `source_ref` - PASS:
  `48` aparicoes e `12` refs unicos.
- Checagem de campos agregados ausentes no summary - PASS.

## Passo de auditoria - fechamento BV-067/BV-073/BV-076/BV-077 2026-06-19T22:40Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_224052/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_224052/seed_*/`

Resultado do wrapper oficial:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `action_findings=0`
- `forensic_rule_findings=0`
- `forensic_lineage_status=complete`
- `forensic_card_id_missing_unaccepted=0`
- `forensic_semantic_hash_missing_unaccepted=0`
- `forensic_rule_logical_key_missing_unaccepted=0`
- `forensic_lineage_unaccepted_missing_samples=[]`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`
- `test_log_empty_successes=[]`
- `test_log_empty_failures=[]`

Validacoes adicionais executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` - PASS, incluindo `test_critic_does_not_consume_decision_trace_from_wrong_phase`, `test_critic_accepts_redirect_with_target_change_provenance` e `test_critic_flags_redirect_without_target_change_provenance`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py` - PASS, incluindo waivers de `Faeburrow Elder`, `Infernal Plunge` e `Geosurge`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py` - PASS, incluindo `test_redirect_removal_changes_declared_target_on_stack` e `test_redirect_removal_without_stack_target_does_not_grant_indestructible`.
- Reproducao controlada da seed `63202240` com `MANALOOM_BATTLE_REAL_OPPONENT_SEED=2026061512` apos o waiver de `Geosurge`: `action_findings=0`, `forensic_rule_findings=0`, `functional_tags_json_events=[]`, `card_id_missing_unaccepted=0`, `semantic_hash_missing_unaccepted=0`.

Tratativa aplicada:

- `BV-067`: removido do quadro aberto. Foram adicionados waivers runtime temporarios e verificados para os reincidentes `Faeburrow Elder`, `Infernal Plunge` e `Geosurge`, sem alterar PostgreSQL. O latest oficial nao possui eventos `rule_source=functional_tags_json`.
- `BV-073`: removido do quadro aberto. O wrapper agora publica `test_results`, `py_compile`, `tests`, paths de logs, exit codes e contagens de bytes/linhas no `summary.json`; o latest oficial tem `16/16` checks `pass` e nenhum log esperado vazio sem registro.
- `BV-076`: removido do quadro aberto. `redirect_removal` foi modelado como interacao de alvo/stack com `old_target`, `new_target`, controlador, legalidade e `target_change_applied`; o action critic passou a falhar quando a provenance de target mutation falta.
- `BV-077`: removido do quadro aberto. O action critic passou a casar decision trace por fase antes de consumir fallback legado; o fixture de mesma carta/mesmo turno (`draw_step` + `precombat_main`) cobre a regressao e o latest oficial nao tem `missing_decision_trace`.

## Passo de auditoria - fechamento BV-058 2026-06-19T22:40Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_224052/summary.json`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`
- `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md`

Tratativa aplicada:

- `BATTLE_REPLAY_GATE_MATRIX.md` agora declara `Status: current as of 2026-06-19T22:40Z`, aponta para `20260619_224052/summary.json`, e lista o status atual `battle_replay_final_status=trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`, residual coverage, forensic lineage, taxonomy, strategy low/high-confidence e test provenance do latest real.
- `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` agora referencia o latest `20260619_224052` para a gate matrix.
- `BATTLE_SYSTEM_LOGIC.md` segue como doc de arquitetura, com aviso explicito de que register + latest summary + gate matrix decidem readiness atual.

Validacao executada:

- `rg` nos roteadores battle citados por BV-058 - PASS: nao ha mais referencia a `20260619_204826` ou `20260619_215228` como current nesses docs.
- Checagem programatica do texto da gate matrix contra o latest summary - PASS: run `20260619_224052`, final status, divergencias, `test_results_total=16` e `decision_trace_taxonomy_rows=2443` batem com o summary atual.

Resultado: `BV-058` removido do quadro aberto.

## Passo de auditoria - fechamento BV-059 2026-06-19T22:40Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_224052/summary.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Resultado atual do latest:

- `focused_template_dispatch_status=focused_template_dispatch_ready`
- `focused_template_cards=29`
- `focused_template_evidence_ready=29`
- `focused_template_supports_template_count=47`
- `effect_coverage_residual_status=effect_coverage_residual_accepted`
- `effect_coverage_residual_raw_flag_total=535`
- `effect_coverage_residual_card_flag_rows=289`
- `effect_coverage_residual_accepted_card_flag_rows=289`
- `effect_coverage_residual_unaccepted_card_flag_rows=0`
- `effect_coverage_residual_accepted_flag_totals={"cast_permission_not_explicit":35,"copy_effect_mismatch":1,"heuristic_effect":86,"land_utility_ability_not_modeled":21,"needs_review_rule":29,"oracle_silence_mismatch":4,"oracle_target_removal_mismatch":12,"temporary_effect_not_explicit":38,"trigger_not_explicit":63}`

Tratativa aplicada:

- `battle_gate_report_lines(...)` e `battle_gate_cli_lines(...)` agora publicam `effect_coverage_residual_scope_note=accepted_residual_is_not_full_runtime_coverage` junto dos denominadores de residual.
- `BATTLE_REPLAY_GATE_MATRIX.md` tambem declara que residual aceito nao prova runtime completo.
- `test_master_optimizer_hashes.py` agora falha se a nota de escopo residual desaparecer do markdown ou CLI de handoff.

Validacoes executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py` - PASS (`Ran 5 tests`).
- Amostra gerada de `battle_gate_report_lines(summary)` e `battle_gate_cli_lines(summary)` contra o latest real - PASS: ambos exibem `effect_coverage_residual_scope_note`.

Resultado: `BV-059` removido do quadro aberto.

## Passo de auditoria - fechamento BV-060 2026-06-19T22:43Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_224052/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_224052/decision_trace_taxonomy.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_224052/decision_trace_taxonomy.md`
- `docs/hermes-analysis/BATTLE_DECISION_TRACE_TAXONOMY.md`

Resultado atual:

- `decision_trace_taxonomy_status=decision_trace_taxonomy_ready`
- `decision_trace_taxonomy_rows=2443`
- `decision_trace_kinds_total=15`
- `decision_trace_kinds_observed=12`
- `decision_trace_kinds_uncovered=3`
- `decision_trace_static_uncovered_types=["activated_sacrifice_damage","attack_trigger_artifact_tutor","worldfire_reset"]`
- `decision_trace_contract_findings=0`
- `decision_trace_missing_required_fields=0`
- `decision_trace_accepted_waivers=["activated_sacrifice_damage","attack_trigger_artifact_tutor","lorehold_upkeep_rummage","saga_chapter_resolution","utility_artifact_activation","utility_land_activation"]`

Tratativa aplicada:

- `BATTLE_DECISION_TRACE_TAXONOMY.md` foi atualizado para o latest `20260619_224052`.
- O doc agora declara explicitamente que `decision_trace_taxonomy_ready` nao significa que todos os `15/15` tipos foram observados.
- A ownership matrix do doc foi atualizada com os counts atuais por tipo e preserva os `3` tipos estaticos nao observados.

Validacoes executadas:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_trace_taxonomy_audit.py` - PASS (`3 tests passed`).
- Checagem programatica do doc contra o latest summary - PASS: run `20260619_224052`, rows `2443`, observed `12`, uncovered `3`, nota `15/15` e `worldfire_reset` presentes.
- `rg` em `BATTLE_DECISION_TRACE_TAXONOMY.md`, `BATTLE_REPLAY_GATE_MATRIX.md` e `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` - PASS: nenhum snapshot antigo `2221`, `171605`, `10/15`, `63202022` ou `20260619_204826` permanece nesses docs roteadores.

Resultado: `BV-060` removido do quadro aberto.

## Passo de auditoria - fechamento BV-061 2026-06-19T22:43Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_224052/summary.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Resultado atual do latest:

- `review_only_rule_names=0`
- `needs_review_rule_names=1457`
- `non_runtime_safe_rule_names=1457`
- `runtime_safe_rule_names=1702`
- `review_status_counts={"active":27,"needs_review":1457,"verified":1675}`

Tratativa aplicada:

- `battle_gate_report_lines(...)` e `battle_gate_cli_lines(...)` continuam publicando todos os denominadores de review juntos.
- Foi adicionada a nota explicita `review_rule_denominator_scope_note=review_only_zero_is_not_review_backlog_zero`.
- `BATTLE_REPLAY_GATE_MATRIX.md` tambem declara que `review_only_rule_names=0` e estreito e nao elimina o backlog real `needs_review/non_runtime_safe`.

Validacoes executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py` - PASS (`Ran 5 tests`).
- Amostra gerada de `battle_gate_report_lines(summary)` e `battle_gate_cli_lines(summary)` contra o latest real - PASS: ambos exibem `review_only=0`, `needs_review=1457`, `non_runtime_safe=1457`, `runtime_safe=1702` e a nota de escopo.

Resultado: `BV-061` removido do quadro aberto.

## Passo de auditoria - fechamento BV-062 2026-06-19T22:43Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_224052/summary.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Resultado atual do latest:

- `forensic_lineage_status=complete`
- `forensic_card_id_present=791`
- `forensic_card_id_missing=595`
- `forensic_card_id_missing_accepted=595`
- `forensic_card_id_missing_unaccepted=0`
- `forensic_semantic_hash_present=791`
- `forensic_semantic_hash_missing=595`
- `forensic_semantic_hash_missing_accepted=595`
- `forensic_semantic_hash_missing_unaccepted=0`
- `forensic_rule_logical_key_present=1365`
- `forensic_rule_logical_key_missing=21`
- `forensic_rule_logical_key_missing_accepted=21`
- `forensic_rule_logical_key_missing_unaccepted=0`

Tratativa aplicada:

- `battle_gate_report_lines(...)` e `battle_gate_cli_lines(...)` continuam publicando present/missing/accepted/unaccepted para `card_id`, `semantic_hash` e `rule_logical_key`.
- Foi adicionada a nota explicita `forensic_lineage_scope_note=complete_means_zero_unaccepted_missing_not_full_identity_coverage`.
- `BATTLE_REPLAY_GATE_MATRIX.md` tambem declara que lineage `complete` nao significa identidade completa por evento.

Validacoes executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py` - PASS (`Ran 5 tests`).
- Amostra gerada de `battle_gate_report_lines(summary)` e `battle_gate_cli_lines(summary)` contra o latest real - PASS: ambos exibem missings aceitos/unaccepted zero e a nota de escopo.

Resultado: `BV-062` removido do quadro aberto.

## Fechamento BV-072 - 2026-06-19T21:10:55-03:00

Evidencia:

- Relatorio: `docs/hermes-analysis/master_optimizer_reports/battle_latest_000720_global_learning_eligibility_recheck_20260619_211055.md`
- Latest audit: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_000720/summary.json`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `strategy_learning_confidence_counts={"high_confidence_replay": 12, "low_confidence_replay": 4}`
- `global_learning_eligibility_policy=requires_high_confidence_strategy_seed_and_all_mandatory_gates_pass`
- `global_learning_eligible_seeds=["63210007","63210009","63210010","63210011","63210012","63210013","63210014","63210015","63210016","63210018","63210019","63210022"]`
- `global_not_learning_eligible_seeds=["63210008","63210017","63210020","63210021"]`
- `global_learning_eligibility_reasons` publica todas as 16 seeds; as 4 seeds low-confidence tem `["strategy_audit:low_confidence_replay"]`.
- `test_results_total=16`
- `test_results_status_counts={"pass": 16}`
- `test_result_failures=[]`

Tratativa aplicada:

- `battle_decision_strategy_auditor.py` passou a expor `compute_global_learning_eligibility(...)` com a politica `requires_high_confidence_strategy_seed_and_all_mandatory_gates_pass`.
- O wrapper `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` agora calcula elegibilidade global somente depois de todos os mandatory gates e publica `global_learning_eligible_seeds`, `global_not_learning_eligible_seeds` e `global_learning_eligibility_reasons`.
- Seeds high-confidence no strategy audit deixam de ser prova global quando ha findings action/decision/forensic ou quando `battle_replay_final_status != trusted_for_strategy_learning`.
- `summary.md` tambem mostra a politica, listas globais e reasons.

Validacoes executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS, incluindo `test_global_learning_eligibility_blocks_high_strategy_seed_when_other_gates_review_required` e `test_global_learning_eligibility_allows_clean_high_seed_and_excludes_low_confidence_seed`.
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` - PASS.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` - PASS, gerando `20260620_000720`.
- `test_battle_decision_strategy_auditor` no `test_results.jsonl` oficial - PASS, `exit_code=0`, `log_lines=17`.

Resultado: `BV-072` removido do quadro aberto.

## Fechamento BV-074 - 2026-06-19T21:17:54-03:00

Evidencia:

- Relatorio: `docs/hermes-analysis/master_optimizer_reports/battle_optimizer_surface_gate_coverage_closure_20260619_211754.md`
- Manifest latest: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/runtime_surface_manifest.json`
- Gate latest: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- Manifest `optimizer/scorecard`: `15` arquivos.

Tratativa aplicada:

- `master_optimizer_apply.py`, `master_optimizer_post_apply_gate.py`, `master_optimizer_product_handoff.py` e `master_optimizer_rollback.py` agora incluem `battle_gate_report_lines()` nos Markdown operacionais.
- `master_optimizer_loop.py` agora inclui `battle_gate_report_lines()` no report de preflight e `battle_gate_cli_lines()` na saida de plano/CLI.
- `universal_optimizer.py` agora imprime `universal_optimizer_status=legacy_deprecated_not_authorized_for_handoff`, o aviso `universal_optimizer_auto_apply_warning=use_master_optimizer_apply_pipeline_instead` e `battle_gate_cli_lines()`.
- `master_optimizer_common.py` tambem publica amostras globais (`global_learning_eligible_seed_sample` e `global_not_learning_eligible_seed_sample`) nos helpers de gate.
- A regressao estatica `test_optimizer_operational_surfaces_publish_battle_gate` cobre as superficies operacionais de report/CLI e o banner legacy.

Validacoes executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_apply.py docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_loop.py docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_post_apply_gate.py docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_product_handoff.py docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_rollback.py docs/hermes-analysis/manaloom-knowledge/scripts/universal_optimizer.py docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py` - PASS.
- `python3 test_master_optimizer_hashes.py` em `docs/hermes-analysis/manaloom-knowledge/scripts` - PASS (`Ran 6 tests`).
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_loop.py --plan` - PASS; a saida mostra `Battle Replay Gate`, `battle_replay_final_status=trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`, `battle_gate_weight=required_for_optimizer_wr_evidence`, splits high/low e amostras globais.
- Chamada sintetica de `master_optimizer_loop.render_report(...)` - PASS; Markdown contem `## Battle Replay Gate`, `battle_replay_final_status`, `mandatory_gate_divergences` e `battle_gate_weight`.
- Varredura do manifest confirmou as superficies operacionais: `master_optimizer_apply.py`, `master_optimizer_baseline.py`, `master_optimizer_confirmation.py`, `master_optimizer_handoff.py`, `master_optimizer_loop.py`, `master_optimizer_post_apply_gate.py`, `master_optimizer_product_handoff.py`, `master_optimizer_quality_gate.py`, `master_optimizer_rollback.py`, `slot_optimizer.py` e `universal_optimizer.py` publicam gate por report/CLI ou banner legacy.

Nao executado por seguranca:

- `master_optimizer_apply.py`, `master_optimizer_post_apply_gate.py`, `master_optimizer_product_handoff.py`, `master_optimizer_rollback.py` e `universal_optimizer.py` nao foram executados porque podem aplicar, validar, persistir handoff ou restaurar swaps no SQLite local.

Resultado: `BV-074` removido do quadro aberto.

## Fechamento BV-075 - 2026-06-19T21:31:59-03:00

Evidencia:

- Relatorio final: `docs/hermes-analysis/master_optimizer_reports/battle_latest_002832_learned_deck_opponent_provenance_closure_20260619_213159.md`
- Latest audit: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_002832/summary.json`
- `battle_replay_final_status=blocked`
- `mandatory_gate_divergences=["forensic_audit=blocked"]`
- `learned_deck_source_lookup_status=loaded`
- `learned_deck_source_lookup_rows=120`
- `learned_opponent_source_counts={"pg_meta_decks": 48}`
- `opponent_deck_provenance.status=learned_opponent_provenance_present_with_shape_waiver`
- `opponent_deck_provenance.learned_opponent_appearance_count=48`
- `opponent_deck_provenance.learned_opponent_unique_count=12`
- `opponent_deck_provenance.source_url_missing_count=0`
- `opponent_deck_provenance.construction_report_missing_count=48`
- `opponent_deck_provenance.deck_coherence_report_missing_count=48`
- `learned_deck_opponents` publica `12` itens unicos com `source_system`, `source_ref`, `source_url`, `source_row_id`, `name`, `commander`, `deck_name`, `appearances`, `seeds`, `source_card_count`, `battle_card_count`, `metrics_basis`, `cached_metadata_used_for_metrics`, `blocker_domain`, `construction_status`, `deck_coherence_status`, `source_url_status` e `provenance_status`.
- `test_results_total=16`
- `test_results_status_counts={"pass": 16}`
- `test_result_failures=[]`

Interpretacao:

- O run atual nao e evidence trusted para aprendizado de estrategia porque o aggregate esta `blocked` por `forensic_audit`.
- O source-deck gate agora esta separado do engine gate: o summary principal publica os oponentes learned usados no run e a chave estavel `source_url=pg:meta_decks:<uuid>` resolvida do SQLite Hermes local em modo read-only.
- Construction/coherence para learned opponents segue com waiver explicito porque esses reports nao sao emitidos pelo `deck_provenance.json` do replay.

Tratativa aplicada:

- `battle_decision_strategy_auditor.py` passou a expor `summarize_learned_opponent_provenance(...)` com suporte a `source_url`, `commander`, `deck_name` e `source_url_status`.
- O wrapper `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` le `knowledge.db` local em modo read-only, resolve `learned_deck:<id>` contra `learned_decks.source_url` e publica `learned_deck_opponents`, `opponent_deck_provenance` e `learned_opponent_source_counts`.
- `summary.md` tambem mostra lookup, source counts, provenance e lista de opponents.

Validacoes executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS, incluindo `test_summarize_learned_opponent_provenance_groups_sources_and_seeds` e `test_summarize_learned_opponent_provenance_marks_present_reports`.
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` - PASS.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` - PASS, gerando `20260620_002832`.
- `test_battle_decision_strategy_auditor` no `test_results.jsonl` oficial - PASS, `exit_code=0`, `log_lines=19`.
- Assert read-only contra `latest/summary.json` - PASS: `len(learned_deck_opponents)=12`, `learned_opponent_source_counts={"pg_meta_decks":48}`, appearance count `48`, unique count `12`, `source_url_missing_count=0`, e todos os itens possuem os campos minimos exigidos.

Resultado: `BV-075` removido do quadro aberto como gap de provenance/source-deck. O bloqueio atual `forensic_audit=blocked` permanece separado e nao foi tratado como readiness de engine.

## Fechamento BV-067 - 2026-06-19T21:37:32-03:00

Evidencia:

- Relatorio: `docs/hermes-analysis/master_optimizer_reports/battle_latest_003647_aura_of_silence_forensic_blocker_closure_20260619_213732.md`
- Latest focused audit: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_003647/summary.json`
- Seed evidence: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_003647/seed_63210031/replay.events.jsonl`
- Run: `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 63210031`
- `seeds_completed=1`
- `start_seed=63210031`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `forensic_severity_counts={}`
- `seeds_with_high_or_critical_forensic_findings=[]`
- `forensic_card_id_missing_unaccepted=0`
- `forensic_semantic_hash_missing_unaccepted=0`
- `forensic_rule_logical_key_missing_unaccepted=0`
- `test_results_total=16`
- `test_results_status_counts={"pass": 16}`
- `test_result_failures=[]`

Tratativa aplicada:

- `battle_analyst_v9.py` recebeu runtime waiver manual para `Aura of Silence`, modelando tax artifact/enchantment e sacrifice-removal com identidade local estavel.
- `Aura of Silence` foi adicionada a `MANUAL_RULE_RUNTIME_WAIVERS` e `MANUAL_RULE_RUNTIME_WAIVER_METADATA`.
- O caminho `functional_tags_json` deixa de ser usado para `Aura of Silence`.

Evidencia de evento:

- `spell_cast` e `spell_resolved` de `Aura of Silence` na seed `63210031` agora publicam `rule_source=manual_runtime_waiver`, `rule_review_status=verified`, `rule_confidence=1.0`, `card_id=e7faf8eb-e829-4109-8dfe-42865a23ba86`, `semantic_hash=e6276e51fdd5341a5632356f36fb5333eb2ac061679dd0605a557b903affb060`, `rule_logical_key=battle_rule_v1:20333b472cd73a52371a0317ea8a14ff`, `effect=remove_permanent` e `target_type=artifact_or_enchantment`.

Validacoes executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py` - PASS, incluindo `test_aura_of_silence_manual_runtime_waiver_has_identity_for_forensic`.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 1 --start-seed 63210031` - PASS, gerando `20260620_003647`.
- `test_battle_forensic_audit_supported_effects` no `test_results.jsonl` oficial - PASS, `exit_code=0`, `log_lines=13`.

Resultado: `BV-067` removido do quadro aberto para o blocker reproduzido `Aura of Silence`/`functional_tags_json`.

## Passo de auditoria - BV-081 latest/focused run scope 2026-06-19T21:50-03:00

Evidencia:

- Na auditoria de 21:50, `latest` apontava para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_003647`.
- O `summary.json` do run `20260620_003647` publica
  `seeds_requested=1`, `seeds_completed=1`, `start_seed=63210031`,
  `battle_replay_final_status=trusted_for_strategy_learning` e
  `mandatory_gate_divergences=[]`.
- O run imediatamente anterior `20260620_002832` publica
  `seeds_requested=16`, `seeds_completed=16`,
  `battle_replay_final_status=blocked`,
  `mandatory_gate_divergences=["forensic_audit=blocked"]` e
  `seeds_with_high_or_critical_forensic_findings=["63210031"]`.
- O wrapper `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  aceita `--seeds` e `--start-seed`, grava `seeds_requested`,
  `start_seed` e `seeds_completed`, mas nao publica um campo explicito de
  perfil da execucao como `run_profile`, `run_scope` ou `invocation_kind`.
- O mesmo wrapper sempre troca o symlink `latest` apos qualquer run:
  `rm -f "$latest_link"` seguido de `ln -s "$run_dir" "$latest_link"`.
- O bloco de alerta atual cobre action high/critical, strategy blockers,
  replay-decision high/critical, forensic high/critical e threshold de coverage;
  nao ha alerta/rotulo para distinguir run recorrente de 16 seeds de run focado.

Interpretacao:

- Isto nao reabre `BV-067` e nao e blocker de engine/gameplay. O run focado
  `20260620_003647` e evidencia valida para o fechamento da seed `63210031`.
- O problema validado e de observabilidade/governanca: como `latest` e a fonte
  principal viva, um consumidor pode ler `battle_replay_final_status=trusted`
  sem perceber que o artefato atual e um recheck focado de `1` seed, nao o run
  recorrente completo de `16` seeds.
- Pela regra deste chat, qualquer conclusao de prontidao precisa reportar
  `run_dir`, `seeds_requested`, `seeds_completed` e `start_seed` junto com
  `battle_replay_final_status` e `mandatory_gate_divergences`.

Tarefa clara para o chat "Ajustar battle":

- Adicionar ao `summary.json` e ao `summary.md` um campo explicito de escopo,
  por exemplo `run_profile`, `run_scope` ou `invocation_kind`, diferenciando
  `scheduled_16_seed`, `manual_focused_seed` e `manual_custom_seed_count`.
- Avaliar separar symlinks como `latest_full` e `latest_focused`, ou exigir que
  consumidores/docs validem `seeds_requested`, `seeds_completed`, `start_seed` e
  `run_dir` antes de tratar `latest` como readiness recorrente.
- Criar fixture/teste que prove que um run `--seeds 1 --start-seed <seed>` nao
  pode ser interpretado como run recorrente completo.

Resultado: `BV-081` aberto como P2 de observabilidade/governanca. Naquele
snapshot nao havia notificacao de action high/critical nem strategy blocker: o latest
`20260620_003647` tem `seeds_with_high_or_critical_action_findings=[]` e
`seeds_with_strategy_blockers=[]`.

Recheck atual - 2026-06-19T21:58-03:00:

- `latest` agora aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504`.
- O run `20260620_004504` e um run de 16 seeds:
  `seeds_requested=16`, `seeds_completed=16`, `start_seed=63210045`.
- Gate final atual: `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass` e
  `mandatory_gate_divergences=[]`.
- Nao ha notificacao atual de action/strategy:
  `seeds_with_high_or_critical_action_findings=[]` e
  `seeds_with_strategy_blockers=[]`.
- Tambem nao ha blocker atual de replay-decision/forensic:
  `seeds_with_high_or_critical_decision_audit_findings=[]` e
  `seeds_with_high_or_critical_forensic_findings=[]`.
- `test_results_status_counts={"pass":16}` e `test_result_failures=[]`.
- O `summary.json` atual ainda nao publica `run_profile`, `run_scope` nem
  `invocation_kind` (`has_run_profile=false`, `has_run_scope=false`,
  `has_invocation_kind=false`).

Resultado do recheck: o risco operacional imediato de `latest` estar focado foi
resolvido pelo novo run recorrente de 16 seeds, mas `BV-081` permanece aberto
porque o contrato de escopo ainda depende de inferencia por
`seeds_requested/seeds_completed/start_seed` e nao de campo explicito/fixture.

Recheck atual - 2026-06-19T23:59-03:00:

- `latest` agora aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808`.
- O run atual e um run recorrente de 16 seeds por inferencia operacional:
  `seeds_requested=16`, `seeds_completed=16`, `start_seed=63210148` e
  `run_dir=/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808`.
- Gate final atual: `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["forensic_audit=review_required"]` e
  `global_learning_eligible_seeds=[]`.
- Nao ha notificacao atual de action/strategy high/critical:
  `seeds_with_high_or_critical_action_findings=[]` e
  `seeds_with_strategy_blockers=[]`.
- O `summary.json` atual ainda nao publica `run_profile`, `run_scope` nem
  `invocation_kind` (`*_present=false`), embora publique `run_dir`,
  `seeds_requested`, `seeds_completed` e `start_seed`.
- O `summary.md` atual mostra `Seeds completed: 16/16`, mas tambem nao contem
  `run_profile`, `run_scope` nem `invocation_kind`.
- O wrapper confirma a causa de contrato: a montagem do `summary` inclui
  `timestamp_utc`, `run_dir`, `seeds_requested`, `start_seed` e
  `seeds_completed`, mas nao campo de perfil/escopo; qualquer execucao troca
  `latest` por `rm -f "$latest_link"` seguido de `ln -s "$run_dir" "$latest_link"`.

Conclusao: `BV-081` permanece aberto, mas nao como blocker de gameplay. A
pendencia real e de governanca/observabilidade: para declarar readiness
recorrente, o consumidor ainda precisa inferir o perfil do run por
`seeds_requested/seeds_completed/start_seed`, e essa inferencia pode voltar a
falhar quando um recheck manual focado atualizar `latest`. A tarefa para
"Ajustar battle" permanece publicar `run_profile`/`run_scope`/`invocation_kind`
e/ou separar `latest_full` de `latest_focused`, com fixture para `--seeds 1
--start-seed <seed>`.

## Passo de auditoria - BV-082 learned opponent coherence recheck 2026-06-20T00:05-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/deck_provenance.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_005400.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_005400.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Recheck:

- `summary.json` atual publica
  `opponent_deck_provenance.status=learned_opponent_provenance_present_with_shape_waiver`,
  `learned_opponent_appearance_count=48`, `learned_opponent_unique_count=11`,
  `source_counts={"pg_meta_decks":48}`, `source_url_missing_count=0`,
  `construction_report_missing_count=48` e
  `deck_coherence_report_missing_count=48`.
- Os `11` registros de `summary.learned_deck_opponents[]` tem
  `source_url_status=present`, `source_system=pg_meta_decks`,
  `source_card_count=100`, `battle_card_count=99` e
  `waiver_reason=learned_deck_construction_and_coherence_reports_not_emitted_by_battle_replay_deck_provenance`.
- Scan recursivo dos `16` `seed_*/deck_provenance.json` encontrou `48`
  registros learned (`source_kind=learned_decks` ou
  `source_system=pg_meta_decks`), mas todos os `48/48` estao sem
  `source_url`, sem `construction_report` e sem `deck_coherence_report`.
- Exemplo estrutural: `seed_63210153/deck_provenance.json` contem Lorehold com
  `construction_report`, mas os oponentes `Kinnan #104`, `Rograkh #62` e
  `Sisay #31` aparecem apenas com `name`, `source_kind=learned_decks`,
  `source_ref=learned_deck:<id>`, `source_system=pg_meta_decks`, metricas e
  contagens; nao ha `source_url` nem report de coherence por opponent nesse
  artifact por seed.
- O report read-only de coherence atual foi gerado em
  `2026-06-20T00:53:57.869651+00:00`, checou `60` decks ativos e reporta
  `High issues=173`, `Medium issues=21`; na fonte `pg_meta_decks`, sao `52`
  ativos, `158` high e `18` medium.
- Cruzamento dos `11` oponentes do battle summary contra
  `learned_deck_coherence_audit_20260620_005400.json`:
  - por `summary.source_url` convertido de `pg:meta_decks:<uuid>` para
    `coherence.decks[].row_id`: `0/11` matches;
  - por `source_ref`: `4/11` matches, mas os quatro sao comandantes diferentes
    no report de coherence:
    `learned_deck:104` = Kinnan no battle e Ral no coherence,
    `learned_deck:105` = Etali no battle e Aang no coherence,
    `learned_deck:116` = Tayam no battle e K-9 no coherence,
    `learned_deck:83` = Kraum no battle e Ob Nixilis no coherence.

Conclusao: `BV-082` permanece aberto. O aggregate do battle ja tem uma
melhoria util (`source_url` presente nos 11 oponentes), mas a evidencia por
seed ainda nao carrega a chave estavel, e o report de coherence atual nao pode
ser juntado por `source_ref` sem risco de falso match. Isto nao prova erro da
engine battle nem exige swap/DB; e um gap de lineage/coherence entre artifacts.
A tarefa para "Ajustar battle" continua: persistir a mesma chave estavel
(`source_url`/PG UUID/backend id) em cada `deck_provenance.json` por seed e
fazer o coherence report emitir a mesma chave ou um crosswalk explicito,
separando status de source-coherence do final status da engine.

## Passo de auditoria - BV-085 decision trace waiver recheck 2026-06-20T00:12-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/decision_trace_taxonomy.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/decision_trace_taxonomy.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.decision_trace.jsonl`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_trace_taxonomy_audit.py`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Recheck:

- `summary.json` publica `decision_trace_taxonomy_status=decision_trace_taxonomy_ready`,
  `decision_trace_taxonomy_rows=2263`, `decision_trace_contract_findings=0`,
  `decision_trace_missing_required_fields=0`,
  `decision_trace_observed_without_contract=0` e
  `decision_trace_observed_without_specific_contract=0`.
- `decision_trace_observed_counts` no latest:
  `board_wipe=2`, `cast_spell=510`, `combat_attack=268`,
  `lorehold_upkeep_rummage=106`, `mulligan_decision=132`,
  `pass_no_action=1126`, `response=6`, `saga_chapter_resolution=6`,
  `tutor=42`, `utility_artifact_activation=41`,
  `utility_land_activation=17`, `wheel=7`.
- `decision_trace_accepted_waivers` lista
  `activated_sacrifice_damage`, `attack_trigger_artifact_tutor`,
  `lorehold_upkeep_rummage`, `saga_chapter_resolution`,
  `utility_artifact_activation` e `utility_land_activation`.
- Recomputacao direta dos `16` `seed_*/replay.decision_trace.jsonl` mostrou
  `170` linhas observadas em tipos `accepted_field_contract_waiver`:
  `lorehold_upkeep_rummage=106`, `saga_chapter_resolution=6`,
  `utility_artifact_activation=41` e `utility_land_activation=17`.
- Nessas `170` linhas, `parent_links=0` e `missing_parent=170` para campos como
  `parent_decision_id`, `source_decision_id`, `engine_decision_id` ou
  `causal_decision_id`.
- O `summary.json` atual publica apenas a lista de waiver aceita; ele nao
  publica `accepted_field_contract_waiver_observed_rows`, contador por tipo nem
  `decision_learning_grade`.
- Exemplos atuais sem parent/source link incluem
  `63210148/decision-000048` (`lorehold_upkeep_rummage` descartando
  `Blasphemous Act`), `63210148/decision-000054`
  (`utility_land_activation` por `Ancient Tomb`) e
  `63210148/decision-000079` (`utility_land_activation` por `War Room`).

Conclusao: `BV-085` permanece aberto. O taxonomy gate passa corretamente para
contrato de campos, mas `decision_trace_taxonomy_ready` nao deve ser lido como
prova de que todas as `2263` decisoes sao strategy-audited. O gap real e de
grade/observabilidade de aprendizado: `170` linhas atuais sao field-contract-only
ou generic strategy fields, e as linhas que dependem de decisao pai nao carregam
link causal explicito. A tarefa para "Ajustar battle" continua publicar
`accepted_field_contract_waiver_observed_rows` por tipo, `decision_learning_grade`
por tipo, e `parent_decision_id`/`source_decision_id` quando a waiver depender
de escolha de engine pai.

## Passo de auditoria - runtime surface manifest current recheck 2026-06-19T23:27-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/runtime_surface_manifest.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Recheck:

- `latest` ainda aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808`.
- O `runtime_surface_manifest.json` atual foi gerado em
  `2026-06-20T01:51:06Z`.
- `summary.json` e `runtime_surface_manifest.json.summary` batem nos campos
  principais: `total_files=108`, `unclassified_files=[]`,
  `automation_coverage_counts={"covered_by_recurring_run":29,"imported_by_core_runtime":6,"outside_recurring_run":73}`,
  `category_counts={"core runtime":31,"focused evidence/promotion":4,"learned-deck source":14,"optimizer/scorecard":15,"recurring audit gate":24,"renderer":4,"review queue":1,"rule registry/sync":15}` e
  `gate_expected_counts={"core_runtime_import_regression":6,"recurring_audit_required":29,"targeted_manual_gate_required_before_change":31,"targeted_test_required_before_change":42}`.
- O manifest lista `108` arquivos e todos tem `owner`, `gate_expected` e
  `automation_coverage`.
- Exemplos cobertos pela recorrente: `battle_action_critic.py`,
  `battle_analyst_v9.py`, `battle_decision_research_review.py`,
  `battle_decision_strategy_auditor.py` e
  `battle_decision_trace_taxonomy_audit.py`.
- Exemplos importados pelo core runtime: `battle_card_characteristics_support.py`,
  `battle_land_support.py`, `battle_mana_cost_support.py`,
  `battle_replacement_support.py` e `battle_sba_support.py`.
- Exemplos fora da recorrente: `battle_card_specific_tests.py`,
  `battle_combat_tests.py`, `battle_rule_registry.py`,
  `export_hermes_learned_deck.py`, `master_optimizer_apply.py`,
  `server/bin/manaloom_battle_rule_focused_evidence.py`,
  `server/bin/manaloom_battle_rule_review_queue.py` e
  `server/bin/learned_deck_coherence_audit.py`.
- `test_battle_runtime_surface_manifest.py` fixa o denominador atual com
  `EXPECTED_TOTAL_FILES=108`, `EXPECTED_CATEGORY_COUNTS`,
  `EXPECTED_AUTOMATION_COVERAGE_COUNTS`, `EXPECTED_GATE_EXPECTED_COUNTS` e
  `REQUIRED_HIGH_SIGNAL_PATHS`.

Validacoes:

- `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py` - PASS.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py` - PASS.

Leitura: nenhum novo BV aberto nesta fatia. O runtime surface manifest atual
esta coerente e testado como inventario/roteador de gates, mas ele tambem
confirma a fronteira de escopo: a recorrente nao e cobertura global de todos os
arquivos battle/Hermes. Para qualquer mudanca futura nos `73`
`outside_recurring_run`, a evidencia de readiness precisa vir do gate alvo
(`targeted_manual_gate_required_before_change` ou
`targeted_test_required_before_change`), nao apenas do `battle_replay_final_status`.

## Passo de auditoria - final status aggregation recheck 2026-06-19T23:29-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Recheck:

- `latest` ainda aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808`.
- O `summary.json` publica os `9` gates obrigatorios em
  `mandatory_gates_required_for_final_status`: `action_critic`,
  `strategy_audit`, `replay_decision_audit`, `forensic_audit`,
  `effect_coverage`, `focused_template_dispatch`,
  `unknown_template_backlog`, `decision_trace_taxonomy` e
  `event_contract_static`.
- O wrapper local inicializa essa lista em
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  nas linhas `598-608` e monta `mandatory_gate_statuses` nas linhas
  `1081-1222`.
- O mesmo wrapper calcula `mandatory_gate_divergences` nas linhas `1224-1230`
  e aplica a ordem final nas linhas `1231-1239`: qualquer `blocked` torna o
  status final `blocked`; sem blocker, qualquer `review_required` torna o
  status final `review_required`; todos `pass` tornam
  `trusted_for_strategy_learning`.
- Recalculo independente a partir do `summary.json` atual:
  - `missing=[]`
  - `extra=[]`
  - `computed_divergences=["forensic_audit=review_required"]`
  - `computed_status=review_required`
  - `computed_reason=one_or_more_mandatory_gates_require_review`
  - os quatro checks batem com o summary:
    `{"divergences":true,"reason":true,"required_complete":true,"status":true}`.
- O unico gate em divergencia e `forensic_audit`, com
  `status=review_required`, `rule_findings=1`, `turn_findings=0` e
  `blocking_seeds=[]`.
- Como o status final e `review_required`, `global_learning_eligible_seeds=[]`
  e todas as `16` seeds aparecem em `global_not_learning_eligible_seeds` com
  motivo `final_status:review_required` e
  `mandatory_gate:forensic_audit=review_required`; a seed `63210153` tambem
  recebe `forensic_rule_findings=1`.

Leitura: nenhum novo BV aberto nesta fatia. O agregador de final status esta
coerente com a matriz e com o `summary.json` atual. A conclusao operacional
continua sendo negativa para readiness global: mesmo com action critic,
strategy audit, replay decision, effect coverage, focused template, unknown
template, decision taxonomy e event contract passando, o replay recorrente
`20260620_014808` nao e trusted porque o forensic mandatory gate esta
`review_required`. Este recheck reforca a regra do chat: nao usar auditor
isolado limpo para declarar battle pronto.

## Achados abertos

| ID | Severidade | Area | Evidencia | Risco | Avaliar / ajustar | Criterio de fechamento |
| --- | --- | --- | --- | --- | --- | --- |
| `BV-082` | P2 | Learned-deck source lineage / coherence | Latest `20260620_040120` publica `12` learned opponents, `48` aparicoes e `opponent_deck_provenance.source_url_missing_count=0`, mas `construction_report_missing_count=48` e `deck_coherence_report_missing_count=48` continuam sob shape waiver. O report read-only mais novo `learned_deck_coherence_audit_20260620_034458` mostra `60` learned decks ativos com `high=167` e `medium=22`; o cruzamento atual por `summary.source_url` contra `row_id`/`source_url` do coherence achou `0/12` matches, e por `source_ref` achou `5/12` matches, todos por colisao de namespace entre artifacts (`104` Kinnan vs Ral, `105` Etali vs Aang, `116` Tayam vs K-9, `83` Kraum vs Ob Nixilis, `84` Kinnan vs Sisay). | Consumidores podem juntar reports por `source_ref` errado ou ler status final do battle como se tambem validasse coerencia do corpus learned usado como oponente. | Chat "Ajustar battle": namespacear explicitamente `source_ref` local Hermes versus `commander_learned_decks.source_ref`; publicar uma chave estavel comum nos dois artifacts (`source_url`/PG UUID/backend id) e um status agregado de source-coherence por learned opponent usado no battle, separado do status de engine. | Os `12` learned opponents do latest casam 1:1 com um report de coherence por chave estavel, sem colisao por `source_ref`; cada `deck_provenance.json` por seed inclui a mesma chave estavel; o summary mostra `source_coherence_status`/waiver por opponent e a gate matrix declara explicitamente se isso entra ou nao no final status. |
| `BV-085` | P2 | Decision trace field-contract waivers / learning grade | Latest `20260620_040120`: `decision_trace_taxonomy.json` passa com `contract_findings=0`, mas `179` decisoes observadas estao em tipos `accepted_field_contract_waiver` com `strategy_auditor=generic_strategy_fields_only` e `research_category=null`: `lorehold_upkeep_rummage=109`, `saga_chapter_resolution=2`, `utility_artifact_activation=50` e `utility_land_activation=18`. Recomputacao dos `16` `seed_*/replay.decision_trace.jsonl` mostrou `parent_link_rows=0` e `rows_missing_parent_link=179`; o `summary.json` lista apenas `decision_trace_accepted_waivers`, sem contador observado nem `learning_grade` por tipo. | Consumidor pode ler `decision_trace_taxonomy_ready` como se todas as `2326` decisoes fossem strategy-audited, quando `179` linhas sao apenas field-contract/generic. Para `lorehold_upkeep_rummage`, a waiver fala que a qualidade estrategica fica coberta por escolhas de engine pai, mas o trace nao publica link explicito para essa decisao pai. | Chat "Ajustar battle": publicar no `summary.json`/taxonomy contadores de `accepted_field_contract_waiver_observed_rows` por tipo e um `decision_learning_grade` (`strategy_audited`, `research_specific`, `field_contract_only`, `not_observed`); quando uma waiver depender de "parent engine choices", emitir `parent_decision_id`/`source_decision_id` ou rebaixar para non-learning/needs-review. | O latest mostra contadores de waiver observada por tipo e separa explicitamente linhas field-contract-only das linhas strategy/research-specific; `lorehold_upkeep_rummage` tem link de decisao pai ou waiver revisada que nao dependa de parent implicito; fixture cobre waiver observada sem branch estrategico dedicada. |
| `BV-086` | P2 | Forensic / `functional_tags_json` regression coverage | Run `20260620_014808` expos `Machine God's Effigy` via `functional_tags_json`; o run `20260620_033246` reativou a mesma classe em `seed=63210333`, turno `10`, com `Breena, the Demagogue` como `spell_cast`/`spell_resolved`, `effect=draw_cards`, `rule_source=functional_tags_json`, `rule_review_status=heuristic`, sem `card_id`/`semantic_hash` aceitos e com `forensic_audit=blocked`. O latest `20260620_040120` esta `trusted_for_strategy_learning`, `forensic_rule_findings=0` e `forensic_lineage_status=complete`, mas isso nao publica contador zero da classe nem cobre os cards recorrentes com regra/waiver dedicada. | A classe ja reapareceu com cards diferentes; um run limpo sem ocorrencia nao prova regressao fechada nem fornece observabilidade do fallback. | Chat "Ajustar battle": publicar `functional_tags_json_event_count`/cards no summary e promover cada card recorrente (`Machine God's Effigy`, `Breena, the Demagogue`) para regra battle verified/active com identidade e `rule_logical_key`, ou adicionar waiver runtime explicito e testado quando a aproximacao for intencional. | Novo run 16-seed mostra `battle_replay_final_status=trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`, nenhum evento `functional_tags_json` learning/action-audited sem regra/waiver, summary publica contador da classe mesmo quando zero, e fixtures cobrem os cards recorrentes ou os rebaixam explicitamente para non-learning. |
| `BV-087` | P2 | Unknown template backlog / effect-unknown contract | Latest `20260620_040120`: `summary.effect_coverage_unknowns=0`, mas `effect_coverage_effect_totals_unknown=41`, `effect_coverage_unknown_effect_cards` tem `34` cards, `focused_template_ready_unknown_effect_count=28`, `needs_review_unknown_effect_count=5` e `unknown_template_backlog.json` publica `status=focused_template_backlog_ready`, `items=[]`, `source_unknown_cards=0`, `effect_unknown_cards=34`, `without_plan_or_waiver=0` e `without_focused_template_match=0`. O script `battle_unknown_template_backlog_audit.py` monta `items` apenas de `coverage.get("unknown_cards")`, enquanto apenas conta `unknown_effect_cards`; o teste `test_backlog_separates_source_unknown_from_effect_unknown_denominator` valida essa separacao, mas nao exige contrato por carta para os `34` effect-unknown. | Consumidor pode ler `unknown_template_backlog_status=focused_template_backlog_ready` ou `unknown_template_backlog_cards=0` como se o denominador de `effect=unknown` estivesse todo planejado/waived, quando o contrato por carta esta vazio para esse denominador. Isto nao e prova de erro de replay e nao cria mandatory-gate divergence sozinho; e uma lacuna de contrato/observabilidade entre source-unknown e effect-unknown. | Chat "Ajustar battle": renomear o status atual para `source_unknown_template_backlog_status` ou publicar campos separados para `effect_unknown_template_contract_status`; gerar `items`/contadores por carta para `unknown_effect_cards`, distinguindo `focused_template_ready`, `needs_review` e `waived_curated_unknown_effect`; ajustar `summary.md` para nao apresentar backlog ready como cobertura de todo `effect=unknown`. | O latest separa explicitamente source-unknown backlog de effect-unknown contract; `unknown_template_backlog.md/json` mostram contrato por carta ou waiver para os `34` effect-unknown atuais, incluindo os `5` needs-review, e teste falha se `effect_unknown_cards>0` mas o contrato por efeito ficar vazio sem explicitar o escopo. |
| `BV-088` | P1 | Forensic final gate / lineage incompleta | Latest `20260620_040120` esta `trusted_for_strategy_learning` com `forensic_lineage_status=complete`, mas a falha latente do gate permanece sem fixture: no wrapper, `mandatory_gate_statuses.forensic_audit.status` ainda depende de `forensic_rule_findings`/`forensic_turn_findings` e blockers high/critical; o teste `test_forensic_keeps_unaccepted_lineage_missing_visible` prova que um evento com lineage faltante nao aceita pode ter `findings == []` enquanto os tres contadores unaccepted ficam `1`. O run `20260620_033246` mostrou a classe operacional com lineage incompleta, embora ja bloqueada por finding high. | Um run futuro pode ficar com lineage unaccepted visivel e `forensic_rule_findings=0`, fazendo o `forensic_audit` passar e liberando `trusted_for_strategy_learning`/elegibilidade global sem lineage confiavel. | Chat "Ajustar battle": incluir `forensic_*_missing_unaccepted` ou `forensic_lineage_status=incomplete` diretamente na condicao de review do `mandatory_gate_statuses.forensic_audit`; calcular/publicar essa condicao antes de `compute_global_learning_eligibility`; adicionar fixture do wrapper em que `forensic_rule_findings=0` mas missing unaccepted > 0 resulte em `battle_replay_final_status=review_required`. | Teste do wrapper cobre lineage unaccepted sem findings; novo run mostra `forensic_audit.status=review_required` sempre que qualquer `forensic_*_missing_unaccepted>0`, ou `pass` somente quando `forensic_lineage_status=complete`; `global_learning_eligibility_reasons` inclui o motivo de lineage quando aplicavel. |

Estado atual do quadro aberto: `BV-082` permanece aberto contra a linhagem
cross-artifact dos oponentes learned-deck, `BV-085` permanece
aberto contra a falta de grade/contador explicito para decisoes
`accepted_field_contract_waiver` observadas, `BV-086` permanece aberto contra a
cobertura/observabilidade do fallback heuristico `functional_tags_json`,
`BV-087` permanece aberto contra a ambiguidade entre backlog source-unknown e
contrato effect-unknown, e `BV-088` permanece aberto contra a falta de
acoplamento direto entre lineage unaccepted e o gate final `forensic_audit`.
O latest atual `20260620_040120` esta `trusted_for_strategy_learning`, com
`mandatory_gate_divergences=[]`, `test_results_status_counts={"pass":16}` e
`global_learning_eligible_seeds` preenchido para `11/16` seeds. Isto fecha
`BV-084`, mas nao fecha automaticamente as pendencias de governanca/contrato
que ainda exigem campos, fixtures ou chaves estaveis dedicadas. `BV-081` e
`BV-089` permanecem removidos do quadro aberto.

Atualizacao Auditor Central - latest `20260620_090636`:

- Esta atualizacao prevalece sobre as leituras de estado corrente ainda
  escritas como `latest 20260620_040120` no quadro aberto acima.
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest`
  agora aponta para `20260620_090636`.
- `summary.json`: `battle_replay_final_status=review_required`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`,
  `mandatory_gate_divergences=["forensic_audit=review_required"]`,
  `forensic_rule_findings=1`, `forensic_turn_findings=0`,
  `forensic_lineage_status=incomplete`,
  `forensic_card_id_missing_unaccepted=1`,
  `forensic_semantic_hash_missing_unaccepted=1`,
  `forensic_rule_logical_key_missing_unaccepted=1`,
  `strategy_low_confidence_findings=3`,
  `strategy_review_required_findings=0`,
  `global_learning_eligible_seeds=[]`, `test_results_total=16` e
  `test_results_status_counts={"pass":16}`.
- O finding atual reforca `BV-086`: seed `63210916`, turno `12`,
  `Leyline of Abundance`, `spell_cast`, `effect=ramp_permanent`,
  `rule_source=functional_tags_json`, severity `medium`,
  recomendacao do forensic: mover a carta para `card_battle_rules` com status
  `verified/active` ou fornecer waiver runtime explicito e testado.
- O mesmo run reforca `BV-088`: a lineage incompleta aparece junto de finding
  forensic; ainda falta fixture para o caso sem findings mas com
  `forensic_*_missing_unaccepted>0`.
- `BV-083` esta fechado pelo run `090636`: o summary distingue
  `action_event_types_seed_sum=561` de
  `action_event_types_distinct_total=55` e o `summary.md` renderiza os dois
  denominadores.

## Passo de auditoria - runtime surface manifest latest 040120 recheck 2026-06-20T06:07-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/runtime_surface_manifest.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/test_results.jsonl`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Recheck:

- `latest` aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120`.
- O `runtime_surface_manifest.md` foi gerado em
  `2026-06-20T04:04:05Z`.
- `summary.json` publica `runtime_surface_manifest_status=runtime_surface_manifest_ready`,
  `runtime_surface_manifest_total_files=108`,
  `runtime_surface_manifest_unclassified_files=[]`,
  `runtime_surface_manifest_automation_coverage_counts={"covered_by_recurring_run":29,"imported_by_core_runtime":6,"outside_recurring_run":73}`,
  `runtime_surface_manifest_gate_expected_counts={"core_runtime_import_regression":6,"recurring_audit_required":29,"targeted_manual_gate_required_before_change":31,"targeted_test_required_before_change":42}` e
  `runtime_surface_manifest_category_counts={"core runtime":31,"focused evidence/promotion":4,"learned-deck source":14,"optimizer/scorecard":15,"recurring audit gate":24,"renderer":4,"review queue":1,"rule registry/sync":15}`.
- O `runtime_surface_manifest.json.summary` bate com esses denominadores:
  `total_files=108`, `unclassified_files=[]`,
  `automation_coverage_counts={"covered_by_recurring_run":29,"imported_by_core_runtime":6,"outside_recurring_run":73}` e
  `gate_expected_counts={"core_runtime_import_regression":6,"recurring_audit_required":29,"targeted_manual_gate_required_before_change":31,"targeted_test_required_before_change":42}`.
- Dentro dos `73` arquivos `outside_recurring_run`, a distribuicao atual e:
  `23` `core runtime`, `4` `focused evidence/promotion`, `14`
  `learned-deck source`, `15` `optimizer/scorecard`, `2` `renderer`,
  `1` `review queue` e `14` `rule registry/sync`.
- Esses `73` arquivos se dividem em `31`
  `targeted_manual_gate_required_before_change` e `42`
  `targeted_test_required_before_change`.
- `test_results.jsonl` do run `040120` registra
  `test_battle_runtime_surface_manifest` com `status=pass`, finalizado em
  `2026-06-20T04:01:29Z`; o stdout contem
  `PASS test_manifest_classifies_current_battle_surface`.
- O teste fixa `EXPECTED_TOTAL_FILES=108`, `EXPECTED_CATEGORY_COUNTS`,
  `EXPECTED_AUTOMATION_COVERAGE_COUNTS`,
  `EXPECTED_GATE_EXPECTED_COUNTS` e `REQUIRED_HIGH_SIGNAL_PATHS`.

Leitura: nenhum novo BV aberto nesta fatia. O manifest atual esta coerente com
o `summary.json`, com o teste de denominador e com a gate matrix. A restricao
operacional segue valida: `battle_replay_final_status=trusted_for_strategy_learning`
do run `040120` cobre a recorrencia e seus imports declarados, mas nao deve ser
usado como evidencia unica para mudancas nos `73` arquivos
`outside_recurring_run`; nesses casos, o chat "Ajustar battle" precisa rodar o
gate alvo indicado pelo proprio manifest antes de declarar readiness.

## Passo de auditoria - BV-082 learned opponent coherence 040120/034458 recheck 2026-06-20T06:13-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/seed_*/deck_provenance.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034458.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034458.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Recheck:

- `summary.json` atual publica `learned_deck_source_lookup_status=loaded`,
  `learned_deck_source_lookup_rows=120`,
  `opponent_deck_provenance.status=learned_opponent_provenance_present_with_shape_waiver`,
  `learned_opponent_appearance_count=48`,
  `learned_opponent_unique_count=12`,
  `source_counts={"pg_meta_decks":48}`,
  `source_url_missing_count=0`,
  `construction_report_missing_count=48` e
  `deck_coherence_report_missing_count=48`.
- Os `12` registros de `summary.learned_deck_opponents[]` tem
  `source_url_status=present`, `source_system=pg_meta_decks`,
  `source_card_count=100`, `battle_card_count=99`,
  `construction_report_present=false`,
  `deck_coherence_report_present=false` e
  `waiver_reason=learned_deck_construction_and_coherence_reports_not_emitted_by_battle_replay_deck_provenance`.
- Scan dos `16` `seed_*/deck_provenance.json` do run `040120` encontrou `48`
  registros learned (`source_kind=learned_decks` ou
  `source_system=pg_meta_decks`), todos com `source_url_missing=48`,
  `construction_report_missing=48` e `deck_coherence_report_missing=48`.
  Exemplo atual: `Kinnan, Bonder Prodigy #84 (real)` tem
  `source_ref=learned_deck:84`, `source_system=pg_meta_decks`,
  `source_card_count=100`, `battle_card_count=99`, mas nao traz
  `source_url` no artifact por seed.
- O coherence report `034458` foi gerado em
  `2026-06-20T03:44:55.241649+00:00`, checou `60` learned decks ativos e
  reporta `High issues=167`, `Medium issues=22`; para `pg_meta_decks`, sao
  `52` ativos, `154` high e `19` medium.
- Cruzamento dos `12` oponentes do battle summary contra
  `learned_deck_coherence_audit_20260620_034458.json` por
  `summary.source_url` convertido de `pg:meta_decks:<uuid>` para
  `coherence.decks[].row_id` achou `0/12` matches.
- Cruzamento por `source_ref` achou `5/12` matches, todos colisao de namespace
  entre artifacts:
  `learned_deck:104` = Kinnan no battle e Ral no coherence,
  `learned_deck:105` = Etali no battle e Aang no coherence,
  `learned_deck:116` = Tayam no battle e K-9 no coherence,
  `learned_deck:83` = Kraum no battle e Ob Nixilis no coherence,
  `learned_deck:84` = Kinnan no battle e Sisay no coherence.

Conclusao: `BV-082` permanece aberto no estado atual. Isto nao invalida o
`battle_replay_final_status=trusted_for_strategy_learning` da engine no run
`040120`, porque o proprio artifact trata construction/coherence por opponent
como shape waiver; tambem nao autoriza alterar PostgreSQL ou aplicar swaps. A
pendencia real para o chat "Ajustar battle" e publicar uma chave estavel comum
entre `summary.learned_deck_opponents[]`, cada `seed_*/deck_provenance.json` e
o coherence report, ou publicar um crosswalk explicito, alem de separar no
summary o `source_coherence_status` dos oponentes learned do final status da
engine.

## Fechamento BV-089 - 2026-06-20T00:16:00-03:00

Evidencia:

- Relatorio: `docs/hermes-analysis/master_optimizer_reports/battle_latest_031128_human_replay_renderer_bv089_closure_20260620_0016.md`
- Latest oficial: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_031128/summary.json`
- Summary markdown: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_031128/summary.md`
- Test results: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_031128/test_results.jsonl`

Tratativa:

- `battle_replay_v10_3.py` agora renderiza `trigger_resolved` usando
  `activation_kind -> trigger_kind -> trigger -> trigger_event -> event_type`.
- Quando `trigger_spell` existe, a linha humana inclui
  `trigger_spell=<card>`.
- `test_battle_replay_v10_3_renderer.py` ganhou fixture para `trigger_resolved`
  sem `activation_kind`/`trigger_kind`, mas com `trigger` e `trigger_spell`.
- `manaloom-battle-strategy-audit.sh` publica contadores de placeholders
  humanos no `summary.json` e no `summary.md`.

Validacao:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS.
- Re-render dos `15048` eventos do run `20260620_025107`: `kind=?` caiu de
  `100` para `0` e `cause=?` ficou `0`.
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` - PASS.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` - PASS, gerando `20260620_031128`.
- No run `20260620_031128`: `human_replay_resolve_ability_kind_unknown_lines=0`,
  `human_replay_damage_cause_unknown_lines=0`,
  `human_replay_unknown_lines=0`, `human_replay_placeholder_lines=0` e
  `human_replay_placeholder_samples=[]`.
- Scan direto dos `16` `seed_*/replay.txt` do run `031128`: `kind_unknown=0`,
  `cause_unknown=0`, `UNKNOWN=0`, `PLACEHOLDER=0`.
- `test_battle_replay_v10_3_renderer` no `test_results.jsonl` oficial - PASS,
  `exit_code=0`, `log_lines=8`.

Resultado historico: `BV-089` foi removido do quadro aberto naquele snapshot
como gap de auditabilidade do `replay.txt` humano. Esse fechamento foi
superseded pelo run recorrente `20260620_032709`, que reintroduziu
`human_replay_damage_cause_unknown_lines=1`.

## Regressao temporaria BV-089 - 2026-06-20T00:39:00-03:00

Escopo: leitura read-only do run recorrente atual `20260620_032709`; sem
PostgreSQL, sem deck swap, sem alteracao de codigo e sem commit/push.

Fontes:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_032709/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_032709/seed_63210337/replay.txt`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_032709/seed_63210337/action_critic.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_032709/test_results.jsonl`

Evidencia:

- O summary do run recorrente atual publica
  `human_replay_damage_cause_unknown_lines=1`,
  `human_replay_resolve_ability_kind_unknown_lines=0`,
  `human_replay_unknown_lines=0` e `human_replay_placeholder_lines=0`.
- Scan direto dos `16` `seed_*/replay.txt` encontrou uma unica linha com
  `cause=?`:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_032709/seed_63210337/replay.txt:201`.
- Linha real:
  `DAMAGE Etali, Primal Conqueror #105 (real): Lightning Bolt -> Kraum, Ludevic's Opus #83 (real) amount=3 result=creature_destroyed cause=?`.
- Contexto do replay: linhas `195-200` anunciam, pagam, conjuram e resolvem
  `Lightning Bolt` com `rule=curated/verified` e `[deal_damage]`, antes da
  linha de dano com `cause=?`.
- `action_critic.md` para `seed_63210337` reporta `findings=0`, e
  `test_battle_replay_v10_3_renderer` esta `pass` no `test_results.jsonl`; a
  regressao portanto e de auditabilidade do replay humano/contador de summary,
  nao de action gate.

Conclusao historica intermediaria: `BV-089` teria voltado ao quadro aberto se o
run `032709` fosse a evidencia final. A secao seguinte corrige e revalida a
regressao no run recorrente `033246`; portanto esta secao nao representa
pendencia aberta atual.

## Fechamento BV-081 e revalidacao BV-089 - 2026-06-20T00:39:00-03:00

Escopo: ajuste no wrapper local da automacao, renderer humano, teste focado e
runs oficiais; sem PostgreSQL, sem deck swap, sem commit/push.

Fontes:

- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_033208/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_033246/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_033246/summary.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_033246/test_results.jsonl`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_033246_run_scope_and_replay_renderer_revalidation_20260620_0039.md`

Tratativa:

- O wrapper calcula `run_profile`, `run_scope`, `invocation_kind`,
  `seeds_source`, `start_seed_source` e `run_scope_contract` antes do run.
- `SEEDS=1` vira `run_scope=focused_seed` e `run_profile=focused_single_seed`.
- `SEEDS=16` vira `run_scope=recurring_full` e `run_profile=recurring_16_seed`.
- `summary.json` e `summary.md` publicam esses campos no topo do artifact.
- Durante a validacao de `BV-081`, o run `20260620_032709` reintroduziu uma
  regressao de `BV-089`: `human_replay_damage_cause_unknown_lines=1` em
  `seed_63210337/replay.txt`, linha de `Lightning Bolt` com `cause=?`.
- O renderer de `damage_resolved` agora usa fallback
  `cause -> effect -> reason -> source -> card -> ?`, e o teste do renderer
  cobre `Lightning Bolt` sem `cause/effect/reason` explicito.

Validacao:

- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` - PASS.
- Dry-run `--seeds 1 --start-seed 63219981` registrou no log
  `run_profile=focused_single_seed run_scope=focused_seed invocation_kind=manual_cli`.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS, `9` testes, incluindo
  `test_renderer_uses_trigger_fields_for_resolved_ability_kind` e
  `test_renderer_uses_card_as_damage_cause_fallback`.
- Re-render do run `20260620_032709`: `original_cause_unknown=1` e
  `rerendered_cause_unknown=0`; `kind=?` permaneceu `0`.
- Run focado oficial `20260620_033208`: `run_scope=focused_seed`,
  `run_profile=focused_single_seed`, `invocation_kind=manual_cli`,
  `seeds_requested=1`, `seeds_completed=1`, `start_seed=63219981`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]` e placeholders humanos todos `0`.
- Run recorrente oficial `20260620_033246`: `run_scope=recurring_full`,
  `run_profile=recurring_16_seed`, `invocation_kind=default_or_scheduled`,
  `seeds_requested=16`, `seeds_completed=16`, `start_seed=63210332`,
  `battle_replay_final_status=blocked`,
  `mandatory_gate_divergences=["forensic_audit=blocked"]`, `test_results_total=16`
  e `test_results_status_counts={"pass":16}`.
- No run `033246`: `human_replay_resolve_ability_kind_unknown_lines=0`,
  `human_replay_damage_cause_unknown_lines=0`, `human_replay_unknown_lines=0`,
  `human_replay_placeholder_lines=0` e `human_replay_placeholder_samples=[]`.
- Scan direto dos `16` `seed_*/replay.txt` do run `033246`: `kind_unknown=0`,
  `cause_unknown=0`, `UNKNOWN=0`, `PLACEHOLDER=0`.

Resultado: `BV-081` fechado e removido do quadro aberto. `latest` ainda pode
apontar para run focado ou recorrente, mas cada summary agora declara o escopo
de forma consumivel e a gate matrix exige `run_scope=recurring_full` para
readiness recorrente. `BV-089` permanece fechado apos a regressao de
`Lightning Bolt` ser corrigida e revalidada no run recorrente `033246`.

## Passo de auditoria - BV-082 learned coherence 034458/033246 cross-check 2026-06-20T00:45-03:00

Escopo: leitura read-only dos artifacts atuais; sem PostgreSQL, sem deck swap,
sem alteracao de codigo e sem commit/push.

Fontes:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_033246/summary.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034458.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034458.md`
- `seed_*/deck_provenance.json` do run `20260620_033246`

Evidencia:

- O latest recorrente principal continua `blocked`:
  `battle_replay_final_status=blocked`,
  `mandatory_gate_divergences=["forensic_audit=blocked"]`
  e `global_learning_eligible_seeds=[]`.
- O report `learned_deck_coherence_audit_20260620_034458` e read-only,
  `generated_at=2026-06-20T03:44:55.241649+00:00`, cobre `60` learned decks
  ativos e reporta `high=167`, `medium=22`.
- O summary do battle publica `12` learned opponents, `48` aparicoes,
  `opponent_deck_provenance.source_url_missing_count=0` e
  `learned_opponent_source_counts={"pg_meta_decks":48}`.
- Cruzamento `summary.learned_deck_opponents[].source_url`
  (`pg:meta_decks:<uuid>`) contra `coherence.decks[].row_id`: `0/12` matches.
- Cruzamento por `source_ref=learned_deck:<id>`: `5/12` matches, mas todos
  indicam colisao de namespace e nao podem ser usados como join estavel:
  `104` Kinnan vs Ral, `105` Etali vs Aang, `116` Tayam vs K-9,
  `83` Kraum vs Ob Nixilis, `84` Kinnan vs Sisay.
- Os `deck_provenance.json` por seed ainda registram `48` learned opponent
  records sem `source_url`, sem `construction_report` e sem
  `deck_coherence_report`.

Conclusao: `BV-082` permanece aberto. O novo report reduziu o total de high
issues do corpus (`169` -> `167` em comparacao ao snapshot `031157`), mas nao
fechou a lacuna de chave estavel entre oponentes learned usados no battle e o
report de coherence. A tarefa para o chat "Ajustar battle" permanece publicar
uma chave comum estavel nos dois artifacts e separar explicitamente
source-coherence de status de engine.

## Fechamento BV-084 - 2026-06-20T01:01:00-03:00

Escopo: ajuste do `research_review`, teste focado, run oficial recorrente e
atualizacao documental; sem PostgreSQL write, sem deck swap e sem promover
regra battle.

Fontes:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/research_review.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/research_review.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/test_results.jsonl`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_040120_research_review_bv084_closure_20260620_0101.md`

Tratativa:

- `battle_decision_research_review.py` agora preserva `finding_samples` por
  categoria, juntando cada finding do `strategy_audit.json` com a decisao de
  `replay.decision_trace.jsonl` pelo `decision_id`.
- Cada sample publica `seed`, `decision_id`, `decision_type`, `code`,
  `severity`, `detail`, `recommendation`, `chosen_option`, `reason`,
  `risk_flags`, `player`, `turn`, `phase` e `actual_outcome`.
- `research_review.md` renderiza uma tabela de findings por categoria com
  `Seed | Decision | Code | Severity | Chosen option | Reason | Risk flags | Detail`.
- O teste focado cobre categoria bloqueada com exemplo neutro preservado e
  `finding_samples` apontando para a decisao real do finding.

Validacao:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py` - PASS.
- `python3 test_battle_decision_research_review.py` - PASS, `2` testes.
- Recalculo local do run `20260620_033246` antes do wrapper gerou
  `mulligan.finding_samples` com `6` entries e a tabela Markdown esperada.
- Run oficial recorrente `20260620_040120`: `run_scope=recurring_full`,
  `seeds_requested=16`, `seeds_completed=16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`,
  `test_results_total=16` e `test_results_status_counts={"pass":16}`.
- `test_results.jsonl` do run `040120`: `test_battle_decision_research_review`
  passou com `exit_code=0`.
- `research_review.json` do run `040120` mostra
  `categories.mulligan.status=blocked_or_needs_review`,
  `finding_codes={"forced_keep_after_bad_mulligan":6}` e
  `finding_samples` com `6` entries:
  `63210405/decision-000007`, `63210405/decision-000011`,
  `63210407/decision-000006`, `63210410/decision-000010`,
  `63210415/decision-000005` e `63210416/decision-000009`.
- `research_review.md` do run `040120` contem a tabela `Seed | Decision | Code
  | Severity` para `forced_keep_after_bad_mulligan`.

Resultado: `BV-084` fechado e removido do quadro aberto. A categoria
`mulligan` continua `blocked_or_needs_review` por qualidade estrategica de
algumas seeds, mas agora o artifact aponta exatamente quais seeds/decisoes
devem ser investigadas.

## Passo de auditoria - latest 014808 forensic review 2026-06-19T22:58-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/summary.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/seed_63210153/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/seed_63210153/forensic_audit.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/seed_63210153/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/seed_63210153/action_critic.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`

Estado do latest:

- `latest -> /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808`.
- `timestamp_utc=2026-06-20T01:48:08Z`.
- `seeds_requested=16`, `seeds_completed=16`, `start_seed=63210148`.
- `battle_replay_final_status=review_required`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`.
- `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- `mandatory_gate_statuses.forensic_audit={"blocking_seeds":[],"rule_findings":1,"status":"review_required","turn_findings":0}`.
- `action_findings=0`.
- `strategy_findings=6`, todos `low_confidence_findings=6`, sem
  `review_required_findings`.
- `test_results_status_counts={"pass":16}` e `test_result_failures=[]`.
- `global_learning_eligible_seeds=[]`; todos os `16` seeds entraram em
  `global_not_learning_eligible_seeds` por `final_status:review_required` e
  `mandatory_gate:forensic_audit=review_required`.

Finding forensic:

- Unico arquivo com finding: `seed_63210153/forensic_audit.json`.
- Finding:
  - `severity=medium`;
  - `card="Machine God's Effigy"`;
  - `event=spell_cast`;
  - `effect=ramp_permanent`;
  - `turn=11`;
  - `phase=precombat_main`;
  - `player="Kinnan, Bonder Prodigy #104 (real)"`;
  - `rule_source=functional_tags_json`;
  - `finding="Game event depended on heuristic source functional_tags_json."`;
  - recomendacao do auditor: mover o card para `card_battle_rules` com status
    `verified/active`.
- O `replay.events.jsonl` confirma que `cast_announced`, `cost_paid` e
  `spell_cast` de `Machine God's Effigy` carregam `rule_source=functional_tags_json`,
  `rule_review_status=heuristic`, `rule_confidence=0.35`, `rule_execution_status=auto`,
  sem `card_id`, `semantic_hash` ou `rule_logical_key`.
- O `summary.json` confirma `forensic_lineage_status=incomplete`,
  `forensic_card_id_missing_unaccepted=1`,
  `forensic_semantic_hash_missing_unaccepted=1` e
  `forensic_rule_logical_key_missing_unaccepted=1`.
- `forensic_lineage_unaccepted_missing_samples` aponta os tres campos ausentes
  para `Machine God's Effigy`, `seed=63210153`, `source=functional_tags_json`.
- O `action_critic.json` para a mesma seed marcou `cost_paid` e `spell_cast` de
  `Machine God's Effigy` como `verdict=ok`, com evidencia
  `rule=functional_tags_json/heuristic; effect=ramp_permanent; decision=decision-000133`.
  Logo, a falha atual nao e custo/cast ilegal detectado pelo action critic; e
  lineage/confianca de runtime detectada pelo forensic/final gate.

Codigo/auditor:

- `battle_forensic_audit.py` inclui `functional_tags_json` em
  `HEURISTIC_SOURCES`.
- Para `source in HEURISTIC_SOURCES` e efeito diferente de `creature`/`land`,
  o auditor emite finding; se o evento for `spell_resolved` a severidade sobe
  para `high`, caso contrario fica `medium`.
- `test_battle_forensic_audit_supported_effects.py` ja cobre o fechamento antigo
  de `Aura of Silence` por `manual_runtime_waiver`, mas nao cobre
  `Machine God's Effigy`.

Resultado: `BV-086` aberto como P1. Nao ha high/critical action finding nem
strategy blocker, mas o latest recorrente nao pode ser usado para aprendizado
global porque o status agregado esta `review_required` e todas as seeds estao
globalmente inelegiveis.

## Passo de auditoria - BV-086 functional_tags_json event count recheck 2026-06-19T23:55-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63210153/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63210153/forensic_audit.json`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`

Recheck:

- `latest` ainda aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808`.
- `summary.json` mantem `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["forensic_audit=review_required"]`,
  `forensic_rule_findings=1`, `forensic_turn_findings=0`,
  `forensic_severity_counts={"medium":1}` e
  `forensic_lineage_status=incomplete`.
- `summary.json` confirma que os unaccepted missing fields do forensic sao
  exatamente `forensic_card_id_missing_unaccepted=1`,
  `forensic_semantic_hash_missing_unaccepted=1` e
  `forensic_rule_logical_key_missing_unaccepted=1`, todos em amostras de
  `Machine God's Effigy`, seed `63210153`, `source=functional_tags_json`.
- Scan dos `16` arquivos `seed_*/replay.events.jsonl` encontrou
  `rule_source_counts={"curated":2524,"functional_tags_json":3,
  "manual_runtime_waiver":17,"type_line_creature":475}` alem de fontes
  pontuais de overrides (`Blasphemous Act`, `Generous Gift`,
  `Path to Exile`, `Swords to Plowshares`, `Teferi's Protection` e
  `replay_wrapper_survivor_inference`).
- Os `3` eventos `functional_tags_json` sao todos da mesma jogada:
  `cast_announced`, `cost_paid` e `spell_cast` de `Machine God's Effigy`,
  seed `63210153`, linha `1003-1005`, turno `11`, fase `precombat_main`,
  jogador `Kinnan, Bonder Prodigy #104 (real)`,
  `effect=ramp_permanent`, `rule_review_status=heuristic`,
  `rule_confidence=0.35`, `rule_execution_status=auto`, sem `card_id`,
  `semantic_hash` ou `rule_logical_key`.
- `seed_63210153/forensic_audit.json` agrega essa superficie como
  `summary.by_source.functional_tags_json=1`,
  `cards_by_source.functional_tags_json=["Machine God's Effigy"]` e um
  unico `rule_findings[]` medium no evento `spell_cast`.
- Codigo confirmado: `battle_forensic_audit.py` mantem
  `functional_tags_json` em `HEURISTIC_SOURCES` e emite finding quando
  `source in HEURISTIC_SOURCES` e `effect` nao e `creature`/`land`; a
  severidade e `high` apenas para `spell_resolved`, portanto o caso atual
  fica `medium`.

Conclusao: `BV-086` continua aberto. A pendencia real nao e apenas "1 evento
spell_cast"; sao `3` eventos de uma mesma jogada carregando fallback
heuristico sem identidade, com o forensic reportando `1` card-event/finding.
A tarefa para o chat "Ajustar battle" deve preservar essa distincao:
promover/waivar `Machine God's Effigy` com `card_id`, `semantic_hash` e
`rule_logical_key` rastreaveis, e publicar no summary contadores explicitos
como `functional_tags_json_event_count` e `functional_tags_json_cards` para
que o reaparecimento dessa classe nao dependa de scan manual de JSONL.

## Passo de auditoria - BV-088 forensic lineage gate coupling 2026-06-20T00:31-03:00

Artefatos e codigo lidos:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`

Estado confirmado no latest:

- `latest` aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808`.
- `summary.json` publica `forensic_lineage_status=incomplete`,
  `forensic_card_id_missing_unaccepted=1`,
  `forensic_semantic_hash_missing_unaccepted=1` e
  `forensic_rule_logical_key_missing_unaccepted=1`.
- O final status atual continua `review_required` por
  `mandatory_gate_divergences=["forensic_audit=review_required"]`, mas isso
  tambem depende do finding medium de `BV-086`: `forensic_rule_findings=1` e
  `forensic_turn_findings=0`.

Leitura do wrapper recorrente:

- O gate `forensic_audit` em
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  usa `blocked` quando ha `seeds_with_high_or_critical_forensic_findings`; caso
  contrario usa `review_required` apenas quando
  `summary["forensic_rule_findings"]` ou `summary["forensic_turn_findings"]`
  sao nao zero.
- `summary.update(compute_global_learning_eligibility(...))` roda antes do
  bloco que define `summary["forensic_lineage_status"]` como `incomplete` ou
  `complete`.
- Portanto, por codigo, os campos `forensic_card_id_missing_unaccepted`,
  `forensic_semantic_hash_missing_unaccepted`,
  `forensic_rule_logical_key_missing_unaccepted` e `forensic_lineage_status`
  nao sao hoje condicao direta do gate final quando nao houver finding forensic.

Leitura do auditor forensic:

- `battle_forensic_audit.py` incrementa contadores unaccepted quando faltam
  `rule_logical_key`, `card_id` ou `semantic_hash` e nao existe waiver aceito de
  lineage.
- O teste `test_forensic_keeps_unaccepted_lineage_missing_visible` monta um
  evento `spell_cast` de `Ambiguous Spell` com `rule_source=missing` e
  `rule_review_status=missing`; o resultado esperado e `findings == []`, mas
  `rule_logical_key_missing_unaccepted=1`, `card_id_missing_unaccepted=1` e
  `semantic_hash_missing_unaccepted=1`.

Conclusao:

- `BV-088` e uma falha latente real de acoplamento de gate. Ela nao altera a
  leitura operacional do latest atual, porque `BV-086` ja mantem
  `forensic_audit=review_required`.
- Mesmo assim, um run futuro com missing lineage unaccepted mas sem finding
  forensic pode ser marcado como `trusted_for_strategy_learning`; isso violaria a
  regra de que aprendizado precisa de lineage forensic confiavel.

Tarefa para o chat "Ajustar battle":

- Fazer `mandatory_gate_statuses.forensic_audit.status` considerar diretamente
  qualquer `forensic_*_missing_unaccepted>0` ou
  `forensic_lineage_status=incomplete`.
- Calcular a condicao de lineage antes de
  `compute_global_learning_eligibility(...)` ou incluir os contadores unaccepted
  explicitamente nas razoes de inelegibilidade global.
- Adicionar teste do wrapper para o caso `forensic_rule_findings=0`,
  `forensic_turn_findings=0`, mas algum contador unaccepted > 0; o esperado e
  `battle_replay_final_status=review_required` e
  `global_learning_eligible_seeds=[]`.

## Passo de auditoria - optimizer battle gate consumers recheck 2026-06-20T00:39-03:00

Arquivos e comandos lidos:

- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_apply.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_loop.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_post_apply_gate.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_handoff.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_product_handoff.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_rollback.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/universal_optimizer.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py`
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py`

Evidencia:

- `master_optimizer_common.py` expoe `load_battle_gate_summary(...)`,
  `battle_gate_report_lines(...)` e `battle_gate_cli_lines(...)` com
  `battle_replay_final_status`, `battle_replay_final_status_reason`,
  `mandatory_gate_divergences`, confidence split, elegibilidade global,
  contadores focused/effect, lineage forensic e notas de escopo.
- Busca estatica encontrou `battle_gate_report_lines` nos scripts
  `master_optimizer_apply.py`, `master_optimizer_baseline.py`,
  `master_optimizer_confirmation.py`, `master_optimizer_handoff.py`,
  `master_optimizer_loop.py`, `master_optimizer_post_apply_gate.py`,
  `master_optimizer_product_handoff.py`, `master_optimizer_quality_gate.py` e
  `master_optimizer_rollback.py`.
- Busca estatica encontrou `battle_gate_cli_lines` em `master_optimizer_loop.py`,
  `slot_optimizer.py` e `universal_optimizer.py`.
- Busca por `strategy_high_confidence_learning_seeds`,
  `global_learning_eligible_seeds` e `global_learning_eligibility_policy` em
  `docs/hermes-analysis/manaloom-knowledge/scripts`, `server/bin`, `server/lib`,
  `server/routes` e `server/test` nao encontrou consumidor operacional usando a
  lista high-confidence como elegibilidade global fora dos produtores/tests e do
  helper de exibicao.
- `test_master_optimizer_hashes.py` passou `6` testes e confirma que as
  superficies operacionais publicam o Battle Replay Gate.
- Saida atual de `battle_gate_cli_lines()` contra o `latest/summary.json`:
  `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["forensic_audit=review_required"]`,
  `global_learning_eligible_seed_sample=[]`,
  `forensic_lineage_status=incomplete`,
  `forensic_card_id_missing_accepted_unaccepted=546/1`,
  `forensic_semantic_hash_missing_accepted_unaccepted=546/1` e
  `forensic_rule_logical_key_missing_accepted_unaccepted=25/1`.

Conclusao: nenhum novo BV foi aberto para consumidores optimizer nesta fatia. A
superficie de optimizer/scorecard expõe o gate vivo e nao foi encontrada leitura
operacional direta de `strategy_high_confidence_learning_seeds` como
elegibilidade global. O risco atual continua no produtor/gate forensic
documentado em `BV-086` e `BV-088`, nao no consumo desses campos pelo optimizer.

## Passo de auditoria - BV-073 test log provenance recheck 2026-06-20T00:47-03:00

Artefatos lidos:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/test_results.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/test_*.log`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Estado confirmado do latest:

- `latest` aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808`.
- `summary.json.test_results_total=16`.
- `summary.json.test_results_status_counts={"pass":16}`.
- `summary.json.test_result_failures=[]`.
- `summary.json.test_log_empty_successes=[]` e
  `summary.json.test_log_empty_failures=[]`.
- `summary.json.test_results_jsonl` aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/test_results.jsonl`.

Reconciliacao programatica:

- `test_results.jsonl` tem `16` linhas, todas com `status=pass` e `exit_code=0`.
- Todos os `log_path`, `stdout_path` e `stderr_path` publicados existem no
  filesystem.
- Nenhum teste (`kind=test`) possui `log_bytes=0`.
- O unico item com `log_bytes=0` e `py_compile`; ele tambem tem
  `stdout_bytes=0`, `stderr_bytes=0`, `status=pass` e `exit_code=0`, que e
  compatível com sucesso silencioso de `python3 -m py_compile`.
- Nao houve mismatch entre `stdout_bytes`/`stderr_bytes` publicados e o tamanho
  real dos arquivos.
- Amostras verificadas:
  - `test_battle_effect_coverage_known_cards.log` tem `106` bytes e contem
    `Ran 8 tests ... OK`; o conteudo vem de stderr e agora tambem aparece no
    log combinado.
  - `test_battle_runtime_surface_manifest.log` contem
    `PASS test_manifest_classifies_current_battle_surface`.
  - `test_battle_decision_trace_taxonomy_audit.log` contem `3 tests passed`.

Leitura: `BV-073` continua fechado no latest atual. O run ainda nao e trusted
para aprendizado global por causa de `forensic_audit=review_required`, mas a
provenance dos testes recorrentes esta auditavel no resultado principal: comando,
status, exit code, paths, bytes stdout/stderr e JSONL por check.

## Passo de auditoria - BV-089 human replay placeholder provenance 2026-06-19T23:46-03:00

Artefatos e codigo lidos:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.txt`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`

Estado do latest:

- `latest` aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808`.
- `timestamp_utc=2026-06-20T01:48:08Z`.
- `seeds_requested=16`, `seeds_completed=16`, `start_seed=63210148`.
- `battle_replay_final_status=review_required`.
- `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- `decision_audit_human_replay_complete=not_evaluated_by_replay_decision_auditor`.
- `decision_audit_rules_interaction_trusted=not_evaluated_by_replay_decision_auditor`.
- `decision_audit_status_scope=turn_and_decision_trace_invariants`.

Scan controlado do replay humano:

- Os `16` arquivos `seed_*/replay.txt` somam `7630` linhas.
- O scan encontrou `67` linhas `RESOLVE ABILITY ... kind=?`.
- O scan encontrou `1` linha `DAMAGE ... cause=?`:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63210150/replay.txt:95`.
- O scan nao encontrou `CMC=?` nem `life=?`, mas isso nao cobre placeholders
  genericos de `kind`/`cause`.
- Distribuicao dos `67` `kind=?` por fonte no JSONL:
  - `Guttersnipe`, `effect=damage_each_opponent`: `28`;
  - `Esper Sentinel`, `effect=draw_cards`: `21`;
  - `Birgi, God of Storytelling // Harnfel, Horn of Bounty`,
    `effect=add_mana`: `17`;
  - `Springheart Nantuko`, `effect=token_maker`: `1`.

Origem dos `kind=?`:

- Os `67` eventos `trigger_resolved` em `replay.events.jsonl` possuem
  `trigger`.
- `66/67` tambem possuem `trigger_spell`.
- Nenhum dos `67` possui `activation_kind` ou `trigger_kind`.
- Exemplo:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63210148/replay.events.jsonl:276`
  tem `card=Guttersnipe`, `effect=damage_each_opponent`,
  `trigger=instant_sorcery_cast`, `trigger_spell=Silence`,
  `rule_source=curated`, `rule_review_status=verified` e
  `rule_logical_key=battle_rule_v1:3dd2ca2e14e74719f377887f16a84722`.
- Codigo: `battle_replay_v10_3.py:274-287` ja usa `trigger` como fallback em
  `trigger_put_on_stack`, mas `battle_replay_v10_3.py:290-297` renderiza
  `trigger_resolved` apenas com `activation_kind` ou `trigger_kind`, caindo em
  `?` mesmo quando `trigger` existe.
- Teste atual: `test_battle_replay_v10_3_renderer.py:102-128` cobre
  `trigger_resolved` apenas quando `activation_kind` existe, e so valida o
  prefixo `RESOLVE ABILITY`, sem assertar ausencia de `kind=?`.

Origem do `cause=?`:

- O unico `damage_resolved` sem causa aparece em
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63210150/replay.events.jsonl:109`:
  `card=Lightning Bolt`, `amount=3`, `result=creature_destroyed`,
  `target=Greedy Freebooter`, `target_player=Dargo, the Shipwrecker #74 (real)`.
- Esse evento nao possui `cause`, `effect` nem `reason`.
- Codigo: `battle_replay_v10_3.py:252-263` tenta
  `cause`/`effect`/`reason` e cai para `?`.
- Teste atual: `test_battle_replay_v10_3_renderer.py:196-216` cobre
  `damage_resolved` apenas quando `cause=finisher_total_power` ja foi
  fornecido.

Conclusao:

- `BV-089` aberto como P2 de auditabilidade do `replay.txt` humano.
- Isto nao muda o status final do battle por si so: o latest ja esta
  `review_required` por `forensic_audit`, e o auditor de decisao declara que
  completude humana e interacao de regras humanas nao foram avaliadas.
- A tarefa para o chat "Ajustar battle" e tratar `kind=?`/`cause=?` como
  placeholders reais do artefato humano: usar `trigger`/`trigger_spell` na
  renderizacao de `trigger_resolved`, garantir causa em `damage_resolved` ou
  derivar do contexto de stack/spell, adicionar testes negativos para
  `kind=?`/`cause=?`, e publicar contadores de placeholders humanos no
  `summary.json`.

## Passo de auditoria - BV-084 research review finding samples recheck 2026-06-19T23:58-03:00

Artefatos e codigo lidos:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/research_review.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/research_review.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.decision_trace.jsonl`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py`

Estado do latest:

- `research_review.md` aponta o input para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808`.
- `research_review.md` publica `Decision counts` com
  `mulligan_decision=132`.
- `research_review.md` publica `Finding counts:
  {"forced_keep_after_bad_mulligan": 6}`.
- `research_review.json.categories.mulligan.status=blocked_or_needs_review`,
  `finding_count=6` e
  `finding_codes={"forced_keep_after_bad_mulligan": 6}`.
- `research_review.json.examples.mulligan_decision` e um exemplo neutro:
  `seed_63210148`, `decision-000001`, `action=mulligan`,
  `forced_keep=false`, `reason=too_few_lands`.

Reconstrucao dos seis findings reais:

- `seed_63210149/strategy_audit.json`:
  `decision-000010`, `severity=medium`,
  `detail="Mulligan cap forced a risky keep: mana_screw, negative_keep_score, too_few_lands."`.
- `seed_63210150/strategy_audit.json`:
  `decision-000011`, `severity=medium`,
  `detail="Mulligan cap forced a risky keep: mana_screw, negative_keep_score, too_few_lands."`.
- `seed_63210158/strategy_audit.json`:
  `decision-000004`, `severity=medium`,
  `detail="Mulligan cap forced a risky keep: mana_screw, negative_keep_score, too_few_lands."`.
- `seed_63210160/strategy_audit.json`:
  `decision-000008`, `severity=medium`,
  `detail="Mulligan cap forced a risky keep: negative_keep_score, no_early_game_plan."`.
- `seed_63210161/strategy_audit.json`:
  `decision-000007`, `severity=medium`,
  `detail="Mulligan cap forced a risky keep: mana_screw, negative_keep_score, too_few_lands."`.
- `seed_63210162/strategy_audit.json`:
  `decision-000009`, `severity=medium`,
  `detail="Mulligan cap forced a risky keep: negative_keep_score, no_early_game_plan."`.

Decision trace correspondente:

- `seed_63210149/replay.decision_trace.jsonl:10`: player
  `Rograkh, Son of Rohgahh #62 (real)`, `chosen_option.action=keep`,
  `forced_keep=true`, `mulligan_count=3`, `score=-7.0`,
  `reason=too_few_lands`, risk flags
  `["mana_screw", "forced_keep_after_mulligan_cap"]`.
- `seed_63210150/replay.decision_trace.jsonl:11`: player
  `Thrasios, Triton Hero #58 (real)`, `chosen_option.action=keep`,
  `forced_keep=true`, `mulligan_count=3`, `score=-10.0`,
  `reason=too_few_lands`, risk flags
  `["mana_screw", "forced_keep_after_mulligan_cap"]`.
- `seed_63210158/replay.decision_trace.jsonl:4`: player `Lorehold`,
  `chosen_option.action=keep`, `forced_keep=true`, `mulligan_count=3`,
  `score=-10.0`, `reason=too_few_lands`, risk flags
  `["mana_screw", "forced_keep_after_mulligan_cap"]`.
- `seed_63210160/replay.decision_trace.jsonl:8`: player
  `Etali, Primal Conqueror #105 (real)`, `chosen_option.action=keep`,
  `forced_keep=true`, `mulligan_count=3`, `score=-5.0`,
  `reason=no_castable_early_play_by_color`, risk flags
  `["no_early_game_plan", "off_color_early_hand", "forced_keep_after_mulligan_cap"]`.
- `seed_63210161/replay.decision_trace.jsonl:7`: player
  `The Emperor of Palamecia #42 (real)`, `chosen_option.action=keep`,
  `forced_keep=true`, `mulligan_count=3`, `score=-7.0`,
  `reason=too_few_lands`, risk flags
  `["mana_screw", "forced_keep_after_mulligan_cap"]`.
- `seed_63210162/replay.decision_trace.jsonl:9`: player
  `Kraum, Ludevic's Opus #83 (real)`, `chosen_option.action=keep`,
  `forced_keep=true`, `mulligan_count=3`, `score=-3.0`,
  `reason=reactive_only_opener`, risk flags
  `["no_early_game_plan", "reactive_only_opener", "forced_keep_after_mulligan_cap"]`.

Codigo/auditor:

- `battle_decision_research_review.py:219-228` usa `examples.setdefault(...)`,
  portanto guarda a primeira decisao observada por tipo, nao uma amostra do
  finding.
- `battle_decision_research_review.py:240-249` agrega cada finding em
  `finding_items` apenas com `code`, `severity` e `detail`.
- `battle_decision_research_review.py:291-302` retorna `finding_counts`,
  listas de seeds por confidence, `categories` e `examples`, mas nao retorna
  `finding_items` nem `finding_samples`.
- `battle_decision_research_review.py:316-333` escreve o Markdown com
  contadores e matriz por categoria, sem linhas por seed/decision.

Conclusao:

- `BV-084` permanece aberto e comprovado no latest atual.
- O problema nao e ausencia total de rastreio no filesystem: os seis
  `decision_id` existem em `strategy_audit.json` e podem ser cruzados com
  `replay.decision_trace.jsonl`.
- O problema e que o artifact agregado `research_review.md/json`, que e a
  superficie natural para revisar a categoria `mulligan`, nao publica essas
  amostras. A tarefa para o chat "Ajustar battle" continua: adicionar
  `finding_samples` por categoria no JSON/Markdown, com `seed`, `decision_id`,
  `code`, `severity`, `detail`, `player`, `chosen_option`, `reason` e
  `risk_flags`.

## Passo de auditoria - latest 025107 gate e learned-source recheck 2026-06-19T23:57-03:00

Artefatos e codigo lidos:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_025107/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_025107/seed_*/deck_provenance.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_025107/seed_*/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_025107/seed_*/replay.txt`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_005400.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_005400.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Estado do latest:

- Durante esta auditoria, `latest` avancou de
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808`
  para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_025107`.
- Leitura congelada atual: `latest -> 20260620_025107`.
- `timestamp_utc=2026-06-20T02:51:07Z`.
- `seeds_requested=16`, `seeds_completed=16`, `start_seed=63210251`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `test_results_status_counts={"pass":16}` e `test_result_failures=[]`.
- `seeds_with_high_or_critical_action_findings=[]` e
  `seeds_with_strategy_blockers=[]`; portanto nao ha notificacao high/critical
  de action finding ou strategy blocker neste run.

Gates e elegibilidade global:

- `mandatory_gate_statuses.action_critic.status=pass` com `findings=0`.
- `mandatory_gate_statuses.strategy_audit.status=pass` com `findings=5`,
  `low_confidence_findings=5`, `review_required_findings=0` e
  `blocking_seeds=[]`.
- `mandatory_gate_statuses.replay_decision_audit.status=pass` com
  `turn_findings=0` e `decision_findings=0`.
- `mandatory_gate_statuses.forensic_audit.status=pass` com
  `rule_findings=0`, `turn_findings=0` e `blocking_seeds=[]`.
- `forensic_lineage_status=complete`;
  `forensic_card_id_missing_unaccepted=0`,
  `forensic_semantic_hash_missing_unaccepted=0` e
  `forensic_rule_logical_key_missing_unaccepted=0`.
- Scan dos `16` `replay.events.jsonl` encontrou
  `rule_source_counts={"curated":2549,"manual_runtime_waiver":11,"type_line_creature":543}`
  e `functional_tags_json_events=0`.
- `global_learning_eligible_seeds` contem `11` seeds:
  `63210251`, `63210254`, `63210255`, `63210256`, `63210257`, `63210258`,
  `63210259`, `63210260`, `63210263`, `63210265`, `63210266`.
- `global_not_learning_eligible_seeds` contem `5` seeds:
  `63210252`, `63210253`, `63210261`, `63210262`, `63210264`, todas com motivo
  `strategy_audit:low_confidence_replay`.

Learned-deck opponents:

- `opponent_deck_provenance.status=learned_opponent_provenance_present_with_shape_waiver`.
- `learned_opponent_appearance_count=48`.
- `learned_opponent_unique_count=12`.
- `learned_opponent_source_counts={"pg_meta_decks":48}`.
- `opponent_deck_provenance.source_url_missing_count=0`.
- `construction_report_missing_count=48` e
  `deck_coherence_report_missing_count=48`, cobertos por
  `waiver_reason=learned_deck_construction_and_coherence_reports_not_emitted_by_battle_replay_deck_provenance`.
- Scan recursivo dos `16` `seed_*/deck_provenance.json` encontrou `48`
  learned opponent records por seed (`3` por seed), mas `48/48` estao sem
  `source_url`, `construction_report` e `deck_coherence_report`; o `source_url`
  so aparece no aggregate `summary.learned_deck_opponents[]`.

Cross-check com coherence report:

- `learned_deck_coherence_audit_20260620_005400.json` tem `60` learned decks
  ativos, `high=173`, `medium=21`, e fonte `pg_meta_decks` com `52` ativos,
  `158` high e `18` medium.
- Cruzamento por `summary.learned_deck_opponents[].source_url`
  (`pg:meta_decks:<uuid>`) contra `coherence.decks[].row_id`: `0/12` matches.
- Cruzamento por `source_ref`: `5/12` matches, todos conflitantes por commander:
  - `learned_deck:104`: battle `Kinnan, Bonder Prodigy`, coherence
    `Ral, Monsoon Mage`;
  - `learned_deck:105`: battle `Etali, Primal Conqueror`, coherence
    `Aang, at the Crossroads`;
  - `learned_deck:116`: battle `Tayam, Luminous Enigma`, coherence
    `K-9, Mark I`;
  - `learned_deck:83`: battle `Kraum, Ludevic's Opus`, coherence
    `Ob Nixilis, Captive Kingpin`;
  - `learned_deck:84`: battle `Kinnan, Bonder Prodigy`, coherence
    `Sisay, Weatherlight Captain`.

Outras pendencias revalidadas no run atual:

- `BV-089`: scan dos `16` `replay.txt` do run `025107` encontrou
  `kind=?=100` e `cause=?=0`; o placeholder de `trigger_resolved` permanece.
- `BV-085`: os tipos `accepted_field_contract_waiver` observados somam `168`
  linhas (`lorehold_upkeep_rummage=96`, `saga_chapter_resolution=3`,
  `utility_artifact_activation=48`, `utility_land_activation=21`) e `0`
  parent links.
- `BV-084`: `research_review` agora tem
  `finding_codes={"forced_keep_after_bad_mulligan":5}` em `mulligan`, mas
  continua sem `finding_samples`; os findings atuais sao
  `63210252/decision-000006`, `63210253/decision-000008`,
  `63210261/decision-000006`, `63210262/decision-000010` e
  `63210264/decision-000008`.

Conclusao:

- O run `20260620_025107` esta trusted pelos gates obrigatorios da engine e
  possui `11` seeds globalmente elegiveis para aprendizado.
- Isto nao fecha o objetivo completo nem todos os BVs: `BV-082` permanece
  aberto porque source/coherence learned-deck nao junta 1:1 entre artifacts;
  `BV-081`, `BV-083`, `BV-084`, `BV-085`, `BV-086`, `BV-087`, `BV-088` e
  `BV-089` seguem como pendencias reais de governanca, observabilidade,
  regression coverage ou auditabilidade humana conforme o quadro aberto.
- Nenhuma mutacao de PostgreSQL, swap de deck, codigo ou commit foi feita.

## Passo de auditoria - latest 004504 action/effect denominators 2026-06-19T22:08-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/seed_*/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/event_contract_static.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/effect_coverage_residual.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/unknown_template_backlog.json`

Action/event denominator:

- `events=15662` e `action_events_total=15662`.
- Agregado dos `16` arquivos `seed_*/action_critic.json`:
  `findings_total=0`, `verdict_counts={"ok":6226}`,
  `event_rows_total=15662` e `unclassified_samples=[]`.
- `action_event_contract_class_counts={"action_audited":6226,"ignored_with_reason":374,"renderer_only":32,"strategy_signal":242,"technical":8788}`.
- `action_event_type_class_counts={"action_audited":326,"ignored_with_reason":37,"renderer_only":32,"strategy_signal":92,"technical":73}`.
- `event_contract_static.json` confirma `events_observed_total=15662`,
  `observed_event_types_total=53`, `observed_missing_required_fields=0`,
  `observed_unclassified_total=0`, `static_event_types_total=101`,
  `static_fixture_unaccepted_types=[]` e
  `static_contract_waiver_until_forced_fixture=0`.

Effect/template denominator:

- `effect_coverage_effect_totals_unknown=41`, com `34` cards no denominador
  `unknown_effect_cards`.
- `effect_coverage_unknown_effect_source_counts={"battle_rule_curated":1,"battle_rule_needs_review_generated":5,"focused_template_ready":28}`.
- `effect_coverage_unknown_effect_status_counts={"focused_template_ready":28,"needs_review":5,"waived_curated_unknown_effect":1}`.
- Os `5` cards ainda `needs_review` sao: `Amulet of Vigor`, `Blood Moon`,
  `Exploration`, `Ghostly Flicker` e `Grasp of Fate`.
- `Mirrormade` permanece como `waived_curated_unknown_effect` com waiver
  `curated_rule_with_unknown_effect_family_kept_visible_in_unknown_effect_denominator`.
- `effect_coverage_residual.json` publica
  `status=effect_coverage_residual_accepted`, `raw_flag_total=535`,
  `accepted_card_flag_rows=289`, `unaccepted_card_flag_rows=0`,
  `raw_unaccepted_flags=[]` e `unaccepted_cards=[]`.
- `focused_template_dispatch.json` publica
  `status=focused_template_dispatch_ready`, `focused_template_cards=29`,
  `focused_evidence_ready=29`, `evidence_runner_status_counts={"evidence_ready":29}`,
  `focused_template_cards_without_dispatch=[]` e
  `focused_template_cards_not_ready_unwaived=[]`.
- `unknown_template_backlog.json` publica
  `status=focused_template_backlog_ready`, `cards=0`,
  `unknowns_without_plan_or_waiver=[]`, `without_reviewed_family=0` e
  `without_focused_template_match=0`.

Interpretacao:

- O action critic esta limpo no denominador observado atual, mas a leitura
  correta e: `6226` eventos foram action-audited e o restante do ledger foi
  classificado como tecnico, renderer-only, strategy-signal ou ignored com
  razao. Portanto `action_findings=0` nao significa que todo evento do JSONL
  recebeu regra de action critic, e sim que nao houve evento sem classificacao
  nem finding nos eventos que pertencem ao critic.
- O gate de effect coverage esta pass porque nao ha residual unaccepted e a
  fila focada esta pronta, mas `effect_coverage_effect_totals_unknown=41` segue
  visivel. Isto nao e blocker atual, porem tambem nao e prova de que todos os
  efeitos unknown possuem implementacao runtime card-specific.

Resultado:

- Nenhum novo BV aberto. `BV-068` permanece fechado como gap de denominador
  porque o summary agora publica as listas/contagens necessarias.
- Neste passo, `BV-081` permanecia como o unico achado aberto no quadro; ver
  quadro aberto atual para o estado posterior a `BV-082`.
- Tarefa para o chat "Ajustar battle" ja coberta pelos pontos de implementacao:
  continuar reduzindo os `5` `needs_review_unknown_effect_cards` e manter o
  denominador `effect_totals.unknown` separado de `focused_template_ready`.

## Passo de auditoria - latest 004504 runtime-safe/focused recheck 2026-06-19T22:09-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/effect_coverage_residual.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/unknown_template_backlog.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/runtime_surface_manifest.json`
- Logs oficiais do run atual:
  `test_battle_effect_coverage_known_cards.log`,
  `test_battle_effect_coverage_residual_audit.log`,
  `test_battle_focused_template_dispatch_audit.log`,
  `test_battle_rule_registry_runtime_safe.log`,
  `test_battle_runtime_surface_manifest.log` e
  `test_battle_unknown_template_backlog_audit.log`.

Effect/runtime denominator:

- Latest real confirmado: `20260620_004504`, `seeds_requested=16`,
  `seeds_completed=16`, `battle_replay_final_status=trusted_for_strategy_learning`
  e `mandatory_gate_divergences=[]`.
- `effect_coverage` no `mandatory_gate_statuses` esta `pass`, com
  `unknown_effects=0`, `residual_status=effect_coverage_residual_accepted`,
  `residual_unaccepted_card_flag_rows=0`, `residual_raw_unaccepted_flags=[]`,
  `needs_review_rule_names=1457`, `heuristic_effects=114`,
  `trigger_not_explicit=147`, `cast_permission_not_explicit=89` e
  `land_utility_ability_not_modeled=48`.
- `effect_coverage.json` publica `total_card_instances=1288`,
  `unique_cards=556`, `opponents_loaded=12`,
  `runtime_safe_rule_names=1702`, `needs_review_rule_names=1457`,
  `non_runtime_safe_rule_names=1457`, `review_only_rule_names=0`,
  `annotation_only_rule_names=0` e `non_runtime_other_rule_names=0`.
- `review_status_counts={"active":27,"needs_review":1457,"verified":1675}`.
- `source_totals={"battle_rule_curated":724,"type_land":377,"effect_map":100,"battle_rule_needs_review_generated":34,"focused_template_ready":33,"tag":14,"handcrafted":6}`.
- `effect_totals.unknown=41`, `unknown_effect_cards=34`,
  `focused_template_ready_unknown_effect_cards=28`,
  `unknown_effect_source_counts={"battle_rule_curated":1,"battle_rule_needs_review_generated":5,"focused_template_ready":28}` e
  `unknown_effect_status_counts={"focused_template_ready":28,"needs_review":5,"waived_curated_unknown_effect":1}`.
- Os `5` `needs_review_unknown_effect_cards` atuais continuam:
  `Amulet of Vigor`, `Blood Moon`, `Exploration`, `Ghostly Flicker` e
  `Grasp of Fate`.

Focused/residual/backlog:

- `effect_coverage_residual.json.summary` publica
  `status=effect_coverage_residual_accepted`, `raw_flag_total=535`,
  `card_flag_rows=289`, `accepted_card_flag_rows=289`,
  `unaccepted_card_flag_rows=0`, `raw_unaccepted_flags=[]` e
  `unaccepted_cards=[]`.
- Os accepted residuals continuam separados por owner:
  `battle-effect-contract=153`, `battle-heuristic-fallback=86`,
  `battle-land-utility-contract=21` e `battle-rule-review-queue=29`.
- `focused_template_dispatch.json.summary` publica
  `status=focused_template_dispatch_ready`, `focused_template_cards=29`,
  `focused_evidence_ready=29`, `evidence_dispatch_ready=29`,
  `template_predicate_match=29`, `without_evidence_dispatch=0`,
  `without_template_predicate_match=0`,
  `focused_evidence_not_ready_unwaived=0`,
  `focused_template_cards_without_dispatch=[]`,
  `focused_template_cards_not_ready_unwaived=[]`,
  `supports_template_count=47`, `evaluate_dispatch_template_count=47` e
  `build_evidence_function_count=47`.
- Consulta direta aos `focused_template_dispatch.items` encontrou `0` itens com
  `focused_evidence_ready != true`, `evidence_dispatch_ready != true` ou
  `nondispatched_template_matches` nao vazio.
- `unknown_template_backlog.json.summary` publica
  `status=focused_template_backlog_ready`, `unknown_cards=0`,
  `source_unknown_cards=0`, `effect_unknown_cards=34`,
  `without_plan_or_waiver=0`, `without_reviewed_family=0`,
  `without_focused_template_match=0` e
  `without_current_inferred_family=0`.

Runtime surface:

- `runtime_surface_manifest.json.summary` publica `total_files=108`,
  `unclassified_files=[]`,
  `automation_coverage_counts={"covered_by_recurring_run":29,"imported_by_core_runtime":6,"outside_recurring_run":73}`.
- `gate_expected_counts={"core_runtime_import_regression":6,"recurring_audit_required":29,"targeted_manual_gate_required_before_change":31,"targeted_test_required_before_change":42}`.
- `category_counts={"core runtime":31,"focused evidence/promotion":4,"learned-deck source":14,"optimizer/scorecard":15,"recurring audit gate":24,"renderer":4,"review queue":1,"rule registry/sync":15}`.
- Isto reforca a leitura ja registrada: o recurring audit cobre o nucleo
  esperado e os gates recorrentes, mas nao e cobertura global de todos os
  arquivos Python battle/Hermes. As `73` superficies fora do recurring run
  continuam exigindo gate direcionado antes de mudanca.

Test provenance:

- No `summary.json`, os testes relacionados a esta fatia passaram com
  `exit_code=0`: `test_battle_effect_coverage_known_cards`,
  `test_battle_effect_coverage_residual_audit`,
  `test_battle_focused_template_dispatch_audit`,
  `test_battle_rule_registry_runtime_safe`,
  `test_battle_runtime_surface_manifest` e
  `test_battle_unknown_template_backlog_audit`.

Leitura operacional:

- Nenhum novo blocker de engine/gameplay foi validado nesta fatia.
- `effect_coverage=pass` significa que nao ha unknown/unaccepted residual que
  bloqueie o final status atual; nao significa que `1457` regras
  `needs_review/non_runtime_safe` sejam seguras para aprendizagem como regra
  card-specific.
- `unknown_template_backlog_cards=0` continua significando que nao ha source
  unknown sem plano/waiver/template; nao significa que `effect_totals.unknown`
  foi zerado.
- `focused_template_dispatch_ready` prova dispatch/evidence dos 29 templates
  focados, mas nao substitui promotion/runtime-safe card-specific.

Resultado:

- Nenhum novo BV aberto nesta etapa. `BV-068` e `BV-069` permanecem fechados
  pelos criterios de denominador/source-key ja registrados.
- O quadro aberto atual permanece `BV-081` e `BV-082`.
- Tarefa para o chat "Ajustar battle": continuar reduzindo os `5`
  `needs_review_unknown_effect_cards`, e nao permitir que consumidores tratem
  `focused_template_ready`, `accepted_residual_contract` ou `needs_review` como
  prova de regra runtime-safe/card-specific.

## Passo de auditoria - latest 004504 action/event/decision recheck 2026-06-19T22:13-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/seed_*/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/seed_*/replay_decision_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/event_contract_static.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/decision_trace_taxonomy.json`
- Logs oficiais do run atual:
  `test_battle_action_critic.log`,
  `test_battle_decision_trace_taxonomy_audit.log`,
  `test_battle_event_contract_static_audit.log` e
  `test_replay_decision_auditor_scope.log`.

Gates finais:

- Latest real confirmado: `20260620_004504`, `seeds_requested=16`,
  `seeds_completed=16`, `battle_replay_final_status=trusted_for_strategy_learning`
  e `mandatory_gate_divergences=[]`.
- `mandatory_gate_statuses.action_critic.status=pass`,
  `blocking_seeds=[]` e `findings=0`.
- `mandatory_gate_statuses.replay_decision_audit.status=pass`,
  `blocking_seeds=[]`, `turn_findings=0` e `decision_findings=0`.
- `mandatory_gate_statuses.decision_trace_taxonomy.status=pass`,
  `status_detail=decision_trace_taxonomy_ready`, `rows=2416`,
  `kinds_observed=12`, `kinds_total=15`, `contract_findings=0`,
  `missing_required_fields=0`, `observed_without_contract=0`,
  `observed_without_specific_contract=0`, `static_without_contract=0` e
  `kinds_without_specific_contract=0`.
- `mandatory_gate_statuses.event_contract_static.status=pass`,
  `status_detail=event_contract_static_ready`, `events_observed_total=15662`,
  `observed_event_types_total=53`, `static_event_types_total=101`,
  `observed_missing_required_fields=0`, `observed_unclassified_total=0`,
  `static_unclassified_total=0`, `accepted_fixture_waivers=48` e
  `waiver_until_forced_fixture=0`.

Action critic agregado:

- Agregado dos `16` `seed_*/action_critic.json`:
  `findings_total=0`, `event_rows_total=15662`, `actions_total=6226`,
  `verdict_counts={"ok":6226}`, `severity_counts={}`,
  `unclassified_total=0` e `sample_findings=[]`.
- A distribuicao correta do ledger vem do contrato:
  `action_event_contract_class_counts={"action_audited":6226,"ignored_with_reason":374,"renderer_only":32,"strategy_signal":242,"technical":8788}`.
- Portanto `action_findings=0` significa que os `6226` eventos pertencentes ao
  action critic foram auditados e o ledger completo foi classificado; nao
  significa que todos os `15662` eventos receberam regra de action critic.

Event contract static:

- `event_contract_static.json.summary` publica
  `observed_counts` para `53` tipos observados e `15662` eventos.
- `observed_missing_required_fields=0`,
  `observed_unclassified_types=[]`,
  `observed_not_static_literal=[]`,
  `static_unclassified_types=[]` e `static_fixture_unaccepted_types=[]`.
- `static_fixture_accepted_waiver_total=48`, com razoes aceitas:
  `accepted_action_branch_static_contract_until_natural_or_targeted_regression=1`,
  `accepted_explicitly_ignored_event_contract=6`,
  `accepted_forensic_card_event_static_contract_until_observed=2`,
  `accepted_renderer_only_event_no_guardrail_consumer=7`,
  `accepted_strategy_context_signal_static_contract=28` e
  `accepted_technical_ledger_event_no_forced_replay_required=4`.
- `static_not_observed` tem `48` tipos, todos cobertos por waiver aceito ou
  contrato estatico. Isto e coverage de contrato, nao evidencia de que todos os
  tipos estaticos ocorreram neste run.

Replay decision audit e decision trace taxonomy:

- Agregado dos `16` `seed_*/replay_decision_audit.json`:
  `turn_findings_total=0`, `decision_findings_total=0`,
  `decisions_total=2416`, `structured_events_total=15662`,
  `structured_trace_usable_false=0`,
  `status_counts=[{"status":"turn_invariants_clean","count":16}]` e
  `severity_counts={"critical":0,"high":0,"low":0,"medium":0}`.
- Todos os `replay_decision_audit.json` mantem
  `human_replay_complete=not_evaluated_by_replay_decision_auditor` e
  `rules_interaction_trusted=not_evaluated_by_replay_decision_auditor`.
- `decision_trace_taxonomy.json.summary` publica:
  `decision_trace_rows=2416`, `decision_trace_kinds_observed=12`,
  `decision_trace_kinds_total=15`, `decision_trace_kinds_uncovered=3`,
  `decision_trace_missing_required_fields=0`,
  `decision_trace_contract_findings=0`,
  `decision_trace_observed_without_contract=0`,
  `decision_trace_observed_without_specific_contract=0` e
  `decision_trace_static_without_contract=0`.
- Os `3` tipos estaticos nao observados neste run sao:
  `activated_sacrifice_damage`, `attack_trigger_artifact_tutor` e
  `worldfire_reset`. O estado `decision_trace_taxonomy_ready` nao deve ser lido
  como "15/15 tipos observados".
- Dentro dos `12` tipos observados, `4` tipos passam por
  `accepted_field_contract_waiver`, nao por branch estrategico dedicado:
  `lorehold_upkeep_rummage=101`, `saga_chapter_resolution=4`,
  `utility_artifact_activation=37` e `utility_land_activation=16`, totalizando
  `158` linhas. O `decision_trace_taxonomy.json` lista esses tipos com
  `strategy_auditor=generic_strategy_fields_only` e `research_category=null`.
- Recomputacao direta dos `16` `seed_*/replay.decision_trace.jsonl` mostrou
  `parent_link_rows=0` e `rows_missing_parent_link=158` para essas linhas
  `accepted_field_contract_waiver`. O `summary.json` atual publica
  `decision_trace_accepted_waivers`, mas nao publica contador observado por
  waiver nem grade de aprendizado por tipo.
- `BV-085` aberto: isto nao invalida o status de engine do run, mas impede ler
  todas as `2416` decisoes como strategy-audited; as linhas field-contract-only
  precisam aparecer como tal no summary/taxonomy, ou carregar link explicito
  quando a waiver depender de "parent engine choices".

Test provenance:

- No `summary.json`, `test_results_status_counts={"pass":16}` e
  `test_result_failures=[]`.
- Logs oficiais relacionados:
  `test_battle_action_critic` passou com `17` checks,
  `test_battle_decision_trace_taxonomy_audit` passou com `3 tests passed`,
  `test_battle_event_contract_static_audit` passou com `7 tests passed`, e
  `test_replay_decision_auditor_scope` passou com `4` checks de escopo/
  remocao.

Leitura operacional:

- Nenhum novo blocker de action/event/decision foi validado no latest
  recorrente `20260620_004504`.
- `event_contract_static_ready` valida que os tipos observados e os tipos
  estaticos conhecidos estao classificados/waived; nao prova exercicio runtime
  natural de todos os `101` tipos estaticos.
- `decision_trace_taxonomy_ready` valida contrato dos `12` tipos observados e
  dos tipos estaticos conhecidos; nao prova que `activated_sacrifice_damage`,
  `attack_trigger_artifact_tutor` ou `worldfire_reset` foram exercitados neste
  run.
- `replay_decision_audit=pass` valida invariantes de turno e decision trace;
  nao avalia completude do replay humano nem confianca de interacao de regras.

Resultado:

- Nenhum novo BV aberto nesta etapa.
- O quadro aberto atual permanece `BV-081` e `BV-082`.
- Tarefa para o chat "Ajustar battle": se algum consumidor quiser declarar
  cobertura runtime para todos os tipos estaticos de evento ou decision trace,
  criar targeted fixtures/gates para os tipos nao observados em vez de usar
  `event_contract_static_ready` ou `decision_trace_taxonomy_ready` como prova
  de execucao completa.

## Passo de auditoria - latest 004504 human replay renderer 2026-06-19T22:24-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/seed_*/replay.txt`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/seed_*/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/seed_*/replay.decision_trace.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/test_battle_replay_v10_3_renderer.log`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/test_replay_decision_auditor_scope.log`
- `docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_replay_decision_auditor_scope.py`

Resultado atual:

- Latest real: `20260620_004504`, `timestamp_utc=2026-06-20T00:45:04Z`,
  `seeds_requested=16`, `seeds_completed=16` e `start_seed=63210045`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass` e
  `mandatory_gate_divergences=[]`.
- Sem high/critical em action findings, strategy blockers, decision audit ou
  forensic findings.
- `decision_audit_human_replay_complete=not_evaluated_by_replay_decision_auditor`.
- `decision_audit_rules_interaction_trusted=not_evaluated_by_replay_decision_auditor`.
- Nas 16 seeds, `replay.txt` soma `8380` linhas, contra `15662` eventos JSONL
  e `2416` decision traces.
- Scan textual em todos os `seed_*/replay.txt` encontrou `0` ocorrencias para
  `CMC=?`, `life=?->`, `event=?`, `stack=?`, `target=?`, `phase=?` e
  `priority=?`.
- Scan dos `replay.events.jsonl` encontrou `0` missing fields para os pontos
  que causavam placeholders em snapshots antigos:
  `utility_land_life_fields_missing=0`, `commander_cast_cmc_missing=0`,
  `miracle_cast_cmc_missing=0`, `end_step_instant_cmc_missing=0`,
  `spell_countered_phase_missing=0`, `spell_countered_priority_missing=0` e
  `spell_resolved_phase_missing=0`.
- `test_battle_replay_v10_3_renderer` passou no run atual com `7` testes:
  land-cost/cast-illegal/board details, diferenciacao spell/ability/trigger/
  counter, CMC em casts especiais, campos reais de trigger put on stack,
  explicacao de noncombat damage/life change, metricas de deck derivadas de
  cartas resolvidas e provenance de line names/source metrics/blocker domain.
- `test_replay_decision_auditor_scope` passou no run atual com `4` testes e
  confirma que o auditor de decisao declara `status_scope` restrito a
  `turn_and_decision_trace_invariants`, com `human_replay_complete` e
  `rules_interaction_trusted` marcados como `not_evaluated_by_replay_decision_auditor`.
- O codigo do auditor tambem fixa essa fronteira em
  `replay_decision_auditor.py`: `AUDIT_SCOPE` e `NOT_EVALUATED` sao publicados
  no summary/markdown, e os testes exigem esses campos.

Leitura operacional:

- A falha de placeholder humano de `BV-063` nao reproduz no latest recorrente
  `20260620_004504`; a evidencia atual reforca o fechamento ja registrado.
- Isto nao transforma `replay.txt` em ledger primario de aprendizagem. O texto
  humano e uma projecao; a prova tecnica continua sendo `summary.json`,
  `replay.events.jsonl`, `replay.decision_trace.jsonl` e os gates obrigatorios.
- O fato de `replay_decision_auditor` nao avaliar completude do replay humano
  nao e novo bug neste ponto porque o escopo e explicito e testado; porem
  impede usar o status desse auditor como prova de completude humana do
  `replay.txt`.

Resultado:

- Nenhum novo BV aberto. `BV-063` permanece fechado no snapshot atual.
- Neste passo de replay humano, nenhum novo achado foi aberto. O quadro aberto
  atual deve ser lido na tabela `Achados abertos`, porque checks posteriores
  podem abrir pendencias novas.
- Tarefa para o chat "Ajustar battle", somente se o produto quiser promover
  `replay.txt` de artefato humano para prova primaria: criar um gate/metric
  dedicado de `human_replay_renderer_status` ou `human_replay_completeness`,
  separado de `replay_decision_auditor`, com fixture que falhe para
  placeholders e para campos fonte ausentes no JSONL.

## Passo de auditoria - latest 004504 learned-deck lineage/coherence 2026-06-19T22:45-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/seed_*/deck_provenance.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_005400.md`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_005400.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py`
- `server/bin/learned_deck_coherence_audit.py`

Evidencia do latest:

- `learned_deck_source_lookup_status=loaded` e
  `learned_deck_source_lookup_rows=120`.
- `opponent_deck_provenance.status=learned_opponent_provenance_present_with_shape_waiver`.
- `opponent_deck_provenance.learned_opponent_appearance_count=48`.
- `opponent_deck_provenance.learned_opponent_unique_count=11`.
- `opponent_deck_provenance.source_url_missing_count=0`.
- `opponent_deck_provenance.construction_report_missing_count=48`.
- `opponent_deck_provenance.deck_coherence_report_missing_count=48`.
- `learned_opponent_source_counts={"pg_meta_decks":48}`.
- `learned_deck_opponents` tem `11` itens; soma de `appearances=48`;
  `source_url_missing=0`; todos os itens tem `battle_card_count=99`,
  `source_card_count=100`, `metrics_basis=runtime_derived_from_resolved_built_deck`,
  `cached_metadata_used_for_metrics=false` e `blocker_domain=none`.
- Agregado dos `16` `seed_*/deck_provenance.json`: `48` rows
  `source_kind=learned_decks`, `11` `source_ref` unicos, todos
  `source_system=pg_meta_decks`, `source_ref_missing=0`,
  `source_system_missing=0`, `source_card_count_missing=0`,
  `battle_card_count_bad=0`, `metrics_basis_bad=0`,
  `cached_metadata_true=0`, `blocker_domain_non_none=0`,
  `construction_report_present=0` e `deck_coherence_report_present=0`.

Evidencia do auditor de coherence:

- `learned_deck_coherence_audit_20260620_005400.json` publica
  `read_only=true`.
- O aggregate do report mostra `active_learned_decks=60`,
  `severity_counts={"high":173,"medium":21}`.
- Por fonte, `pg_meta_decks` aparece com `active=52`, `high=158`,
  `medium=18`, `metadata_total_lands_mismatch=52`,
  `metadata_zero_lands=51`, `off_color_cards=4`,
  `partner_identity_not_modeled=9` e `land_count_low_review=7`.
- O report traz plano de off-color com `status=ready_for_review`,
  `db_mutations=false`, `apply_requires_explicit_approval=true` e `entry_count=5`.
- O report de Lorehold esta coerente no shape derivado:
  `strategy_checks.passed=true`, `no_premium_mox_present=[]`,
  `PG saved deck rows=100`, `PG saved deck lands=33`, `Derived learned lands=33`.
  Ele ainda registra mismatch de metadata cache para Lorehold:
  metadata `total_lands=30` contra derivado `33`.

Namespace/cross-artifact gap validado:

- Cruzamento dos `11` opponents do latest por `source_url=pg:meta_decks:<uuid>`
  contra `learned_deck_coherence_audit_20260620_005400.json.decks[].row_id`
  retornou `matched_by_row_id=0`.
- `source_ref` sozinho tambem nao e chave segura entre artifacts. Exemplos
  concretos:
  - No battle summary, `source_system=pg_meta_decks source_ref=learned_deck:104`
    e `source_url=pg:meta_decks:33899d41-c1e5-4827-8145-d370360cdf7e`
    representam `Kinnan, Bonder Prodigy`.
  - No coherence report, `source_system=pg_meta_decks source_ref=learned_deck:104`
    e `row_id=d50716d0-2991-4a2e-ae7d-7d050fb024c6` representam
    `Ral, Monsoon Mage`.
  - No battle summary, `source_ref=learned_deck:105` representa
    `Etali, Primal Conqueror`; no coherence report, o mesmo `source_ref`
    representa `Aang, at the Crossroads`.
  - No battle summary, `source_ref=learned_deck:84` representa
    `Kinnan, Bonder Prodigy`; no coherence report, o mesmo `source_ref`
    representa `Sisay, Weatherlight Captain`.
- O codigo confirma a raiz provavel da colisao:
  `battle_replay_v10_3.py` escreve `source_ref=learned_deck:{profile.get('learned_deck_id')}`
  a partir do perfil local usado no replay; o wrapper resolve esse valor contra
  a tabela Hermes SQLite `learned_decks` e publica `source_url`. Ja
  `server/bin/learned_deck_coherence_audit.py` le `commander_learned_decks` e
  publica `source_ref`/`row_id` desse outro namespace.

Leitura operacional:

- A source provenance de `BV-075` continua fechada para o criterio anterior:
  o summary atual lista opponents, aparicoes, `source_url`, card counts,
  metric basis e waivers de construction/coherence.
- O problema novo nao e que os `11` opponents do battle estao invalidos; isto
  nao foi provado. O problema validado e que o report de coherence mais novo
  nao pode ser juntado com seguranca aos `11` opponents usados no battle por
  `source_ref` nem por `source_url` atual.
- `battle_replay_final_status=trusted_for_strategy_learning` continua falando
  dos gates obrigatorios do replay. Ele nao deve ser lido como prova de
  coherence do corpus learned-deck usado como fonte de oponentes.

Resultado: `BV-082` aberto como P2 de lineage/governanca learned-deck.

Tarefa para o chat "Ajustar battle":

- Namespacear explicitamente no battle summary o `source_ref` local Hermes
  versus qualquer `commander_learned_decks.source_ref`.
- Fazer `learned_deck_coherence_audit.py` publicar a mesma chave estavel que o
  battle summary usa (`source_url=pg:meta_decks:<uuid>` ou outro backend-owned
  id comum), ou fazer o wrapper publicar tambem a chave que o coherence auditor
  usa, desde que nao haja colisao.
- Adicionar fixture/teste que pegue os `learned_deck_opponents` do latest e
  exija join 1:1 com o report de coherence por chave estavel antes de qualquer
  consumidor anexar issues/coherence status ao opponent.
- Publicar no `summary.json` um campo separado por opponent, por exemplo
  `source_coherence_status`, `source_coherence_report_key` e
  `source_coherence_waiver_reason`, sem misturar esse status com o
  `battle_replay_final_status` da engine.

## Passo de auditoria - latest 004504 forensic/strategy gates 2026-06-19T23:05-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/seed_*/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/seed_*/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/test_battle_decision_strategy_auditor.log`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/test_battle_forensic_audit_supported_effects.log`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`

Gate final e escopo:

- Latest real confirmado: `20260620_004504`, `timestamp_utc=2026-06-20T00:45:04Z`,
  `seeds_requested=16`, `seeds_completed=16` e `start_seed=63210045`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass` e
  `mandatory_gate_divergences=[]`.
- `mandatory_gate_statuses.strategy_audit.status=pass`, `findings=3`,
  `low_confidence_findings=3`, `review_required_findings=0` e
  `blocking_seeds=[]`.
- `mandatory_gate_statuses.forensic_audit.status=pass`,
  `rule_findings=0`, `turn_findings=0` e `blocking_seeds=[]`.

Strategy audit por seed:

- Agregado dos `16` `seed_*/strategy_audit.json`:
  `findings=3`, `low_confidence_learning_findings=3`,
  `review_required_findings=0`,
  `verdict_counts={"usable_for_strategy_learning":13,"low_confidence_replay":3}`,
  `learning_confidence_counts={"high_confidence_replay":13,"low_confidence_replay":3}`,
  `code_counts={"forced_keep_after_bad_mulligan":3}` e
  `severity_counts={"medium":3}`.
- Seeds `63210046`, `63210055` e `63210059` tem
  `verdict=low_confidence_replay`, `high_confidence_learning_weight=0.0`,
  `low_confidence_learning_codes=["forced_keep_after_bad_mulligan"]` e
  `review_required_findings=0`.
- As outras `13` seeds tem `verdict=usable_for_strategy_learning`,
  `learning_confidence=high_confidence_replay` e
  `high_confidence_learning_weight=1.0`.
- O produtor confirma essa semantica: `battle_decision_strategy_auditor.py`
  separa `low_confidence_findings` dos demais findings; quando ha apenas
  low-confidence, o verdict vira `low_confidence_replay`, e quando nao ha
  findings o learning confidence vira `high_confidence_replay`.

Global learning eligibility:

- `global_learning_eligibility_policy=requires_high_confidence_strategy_seed_and_all_mandatory_gates_pass`.
- `global_learning_eligible_seeds` contem exatamente as `13` seeds high-confidence:
  `63210045`, `63210047`, `63210048`, `63210049`, `63210050`, `63210051`,
  `63210052`, `63210053`, `63210054`, `63210056`, `63210057`, `63210058` e
  `63210060`.
- `global_not_learning_eligible_seeds=["63210046","63210055","63210059"]`,
  todas com `global_learning_eligibility_reasons[seed]=["strategy_audit:low_confidence_replay"]`.
- O wrapper calcula esse campo depois de montar `battle_replay_final_status` e
  `mandatory_gate_divergences`; se qualquer gate obrigatorio nao estiver `pass`,
  o helper adiciona `final_status:<status>` e `mandatory_gate:<gate=status>` aos
  motivos por seed.

Forensic audit por seed:

- Agregado dos `16` `seed_*/forensic_audit.json`:
  `card_event_count=1441`, `rule_findings=0`, `turn_findings=0`,
  `card_id_missing=498`, `card_id_missing_accepted=498`,
  `card_id_missing_unaccepted=0`, `semantic_hash_missing=498`,
  `semantic_hash_missing_accepted=498`,
  `semantic_hash_missing_unaccepted=0`, `rule_logical_key_missing=17`,
  `rule_logical_key_missing_accepted=17` e
  `rule_logical_key_missing_unaccepted=0`.
- `forensic_lineage_status=complete` significa que nao ha missing de
  `card_id`, `semantic_hash` ou `rule_logical_key` sem waiver aceito. Nao
  significa que todos os `1441` eventos de carta tenham identidade PG completa.
- Waivers aceitos agregados:
  `battle_rule_registry_without_card_identity_columns=376`,
  `land_played_curated_runtime_rule_without_pg_card_identity=568`,
  `manual_runtime_waiver_without_pg_identity=16` e
  `type_line_creature_fact_no_rule_identity=53`.
- O codigo confirma a regra: `battle_forensic_audit.py` cria finding
  `critical/high` para `effect == unknown`, efeito fora de `SUPPORTED_EFFECTS`
  ou regra `needs_review` impactante; para lineage, campos ausentes so passam
  como aceitos quando `accepted_lineage_missing_reason(...)` retorna motivo
  explicito. O wrapper marca `forensic_lineage_status=incomplete` se qualquer
  missing unaccepted for maior que `0`.

Test provenance:

- `test_battle_decision_strategy_auditor.log` passou `19` checks, incluindo
  os testes de global learning eligibility e learned opponent provenance.
- `test_battle_forensic_audit_supported_effects.log` passou `13` checks,
  incluindo cobertura de supported effects, manual runtime waiver, type-line
  creature fact, land played curated runtime rule e unaccepted lineage missing
  visivel.

Leitura operacional:

- Nenhum novo blocker de forensic ou strategy foi validado no latest recorrente
  `20260620_004504`.
- Os `3` strategy findings atuais sao low-confidence e removem essas seeds do
  aprendizado global de alta confianca; eles nao mantem o mandatory gate em
  review porque `review_required_findings=0`.
- O forensic limpo prova que nao ha effect/support/needs-review/lineage
  unaccepted blocker nos `1441` eventos card-level observados. Nao prova
  coverage total de todos os efeitos estaticos, nem remove a necessidade de
  reduzir waivers de identidade quando o produto exigir lineage PG completa.
- Esta fatia nao fecha `BV-081` nem `BV-082`; tambem nao abre novo BV, porque
  os waivers de forensic lineage ja sao publicados, testados e separados do
  status de source-coherence learned-deck.

Resultado:

- O quadro aberto atual permanece `BV-081` e `BV-082`.
- Tarefa para o chat "Ajustar battle": se o produto quiser elevar lineage de
  "complete por waiver aceito" para "complete por identidade PG completa",
  criar gate separado exigindo `card_id`/`semantic_hash` para regras ativas com
  identidade conhecida e reduzindo os waivers
  `battle_rule_registry_without_card_identity_columns` e
  `land_played_curated_runtime_rule_without_pg_card_identity`; nao alterar a
  semantica atual de `forensic_lineage_status` sem fixture de compatibilidade.

## Passo de auditoria - latest 004504 research review samples 2026-06-19T23:07-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/research_review.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/research_review.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/seed_63210046/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/seed_63210055/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/seed_63210059/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/test_battle_decision_research_review.log`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py`

Evidencia verificada:

- `research_review.json` publica `seeds=16`,
  `strategy_learning_confidence_counts={"high_confidence_replay":13,"low_confidence_replay":3}`,
  `strategy_low_confidence_seeds=["63210046","63210055","63210059"]`,
  `finding_counts={"forced_keep_after_bad_mulligan":3}` e
  `decision_counts.mulligan_decision=128`.
- A categoria `mulligan` em `research_review.md/json` esta
  `status=blocked_or_needs_review`, com `observed_decisions=128`,
  `finding_count=3` e
  `finding_codes={"forced_keep_after_bad_mulligan":3}`.
- O mesmo `research_review.json` tambem publica
  `examples.mulligan_decision` como a primeira decisao de mulligan observada:
  `seed_63210045`, `decision-000001`, `chosen_option.score=10.0`,
  `risk_flags=[]` e `reason=early_ramp:Ruby Medallion:2`. Esta amostra e limpa,
  nao e uma das decisoes que causaram o bloqueio da categoria.
- As tres decisoes problemáticas reais estao apenas nos artifacts por seed:
  - `seed_63210046`, `decision-000010`, jogador
    `Etali, Primal Conqueror #105 (real)`, `forced_keep=true`,
    `mulligan_count=3`, `score=-7.0`, `reason=too_few_lands`,
    `risk_flags=["mana_screw","forced_keep_after_mulligan_cap"]`,
    `lands=1`.
  - `seed_63210055`, `decision-000007`, jogador
    `Thrasios, Triton Hero #58 (real)`, `forced_keep=true`,
    `mulligan_count=3`, `score=-5.0`, `reason=reactive_only_opener`,
    `risk_flags=["no_early_game_plan","reactive_only_opener","forced_keep_after_mulligan_cap"]`.
  - `seed_63210059`, `decision-000010`, jogador
    `Tayam, Luminous Enigma #25 (real)`, `forced_keep=true`,
    `mulligan_count=3`, `score=-5.0`, `reason=no_castable_early_play_by_color`,
    `risk_flags=["no_early_game_plan","off_color_early_hand","forced_keep_after_mulligan_cap"]`.
- O codigo explica a lacuna: `battle_decision_research_review.py` usa
  `examples.setdefault(...)` para guardar apenas a primeira decisao por
  `decision_type`, e `finding_items` guarda `code`, `severity` e `detail` sem
  `seed`/`decision_id`.
- `test_battle_decision_research_review.log` passou `2` checks; os testes atuais
  cobrem classificacao de categoria e renderizacao de fontes, mas nao exigem
  samples por finding em categoria bloqueada.

Leitura operacional:

- Isto nao muda o gate final: o `summary.json` ja exclui as tres seeds de
  `global_learning_eligible_seeds` e publica
  `global_learning_eligibility_reasons[seed]=["strategy_audit:low_confidence_replay"]`.
- A falha validada e de rastreabilidade do report: um consumidor do
  `research_review.md/json` ve a categoria `mulligan` bloqueada, mas precisa
  abrir os `seed_*/strategy_audit.json` para descobrir quais decisoes causaram
  o bloqueio. Alem disso, o exemplo limpo em `examples.mulligan_decision` pode
  parecer contraditorio se for lido como amostra da categoria bloqueada.

Resultado: `BV-084` aberto como P3 de observabilidade do research review.

- Tarefa para o chat "Ajustar battle": publicar `finding_samples` por categoria
  em `research_review.json` e renderizar no Markdown, com `seed`, `decision_id`,
  `code`, `severity`, `detail`, `chosen_option`, `reason` e `risk_flags`; manter
  `examples` como exemplo neutro ou renomear para `first_observed_examples`.
- O quadro aberto atual passa a ser `BV-081`, `BV-082`, `BV-083` e `BV-084`.

## Passo de auditoria - latest 004504 engine/replay/gate flow 2026-06-19T23:18-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/runtime_surface_manifest.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`

Pipeline confirmado pelo wrapper:

- Antes das seeds, o wrapper roda `py_compile` sobre engine/auditores/testes e
  executa os `16` checks recorrentes listados em `test_results`.
- Para cada seed, o wrapper chama `battle_replay_v10_3.py` com
  `REPLAY_OUT`, `REPLAY_EVENTS_OUT`, `DECISION_TRACE_OUT` e
  `REPLAY_DECK_PROVENANCE_OUT`; em seguida executa `battle_action_critic.py`,
  `battle_decision_strategy_auditor.py`, `replay_decision_auditor.py` e
  `battle_forensic_audit.py` sobre os artefatos daquela seed.
- Depois das seeds, o wrapper executa os gates agregados:
  `battle_decision_research_review.py`, `battle_effect_coverage_audit.py`,
  `battle_effect_coverage_residual_audit.py`,
  `battle_focused_template_dispatch_audit.py`,
  `battle_unknown_template_backlog_audit.py`,
  `battle_decision_trace_taxonomy_audit.py`,
  `battle_event_contract_static_audit.py` e
  `battle_runtime_surface_manifest.py --fail-on-unclassified`.

Artefatos materiais do run:

- O diretorio `20260620_004504` contem `16` diretorios `seed_*`.
- Existem `16` `replay.txt`, `16` `replay.events.jsonl`,
  `16` `replay.decision_trace.jsonl` e `64` JSONs de auditoria por seed
  (`action_critic`, `strategy_audit`, `replay_decision_audit`,
  `forensic_audit`).
- `test_results_total=16`, `test_results_status_counts={"pass":16}` e
  `test_result_failures=[]`.
- `py_compile.status=pass`, `exit_code=0`, `log_bytes=0`,
  `stdout_bytes=0` e `stderr_bytes=0`.

Renderer/engine linkage:

- `battle_replay_v10_3.py` grava o JSONL tecnico em `replay.events.jsonl`,
  chama `write_replay_event(...)` para projetar a linha humana no `replay.txt`
  e grava decision traces em `replay.decision_trace.jsonl`.
- O mesmo renderer carrega `battle_analyst_v9.py`, reseta o contador de
  decision trace quando disponivel e usa `simulate_game_v8(...)` /
  `simulate_game_with_real_opponents(...)` para produzir as partidas.
- `battle_analyst_v9.py` seleciona opponents learned quando
  `load_learned_opponents()` retorna pelo menos `3` decks; caso contrario cai
  para archetypes genericos. No latest atual, a evidencia de
  `learned_deck_opponents` confirma que a rota real/learned foi usada.

Runtime surface manifest:

- `runtime_surface_manifest.total_files=108` e `unclassified_files=[]`.
- `automation_coverage_counts={"covered_by_recurring_run":29,"imported_by_core_runtime":6,"outside_recurring_run":73}`.
- `gate_expected_counts={"core_runtime_import_regression":6,"recurring_audit_required":29,"targeted_manual_gate_required_before_change":31,"targeted_test_required_before_change":42}`.
- Categorias cobertas pelo recurring: `core runtime`, `recurring audit gate`,
  `renderer` e `rule registry/sync`.
- Categorias fora do recurring: `core runtime`, `focused evidence/promotion`,
  `learned-deck source`, `optimizer/scorecard`, `renderer`, `review queue` e
  `rule registry/sync`.

Leitura operacional:

- O run recorrente atual cobre o pipeline principal de replay/auditoria e tem
  manifesto sem arquivos nao classificados.
- As `73` superficies `outside_recurring_run` nao sao falha do latest; elas sao
  contrato de escopo. Qualquer mudanca nelas exige gate direcionado
  (`targeted_manual_gate_required_before_change` ou
  `targeted_test_required_before_change`) antes de declarar a mudanca segura.
- Esta etapa reforca `BV-081`: mesmo com pipeline completo, o `summary.json`
  ainda nao publica `run_profile`, `run_scope` ou `invocation_kind`, entao o
  consumidor precisa validar `run_dir`, `seeds_requested`, `seeds_completed` e
  `start_seed` antes de inferir readiness recorrente.

Resultado:

- Nenhum novo BV aberto nesta etapa.
- O quadro aberto atual permanece `BV-081` e `BV-082`.
- Tarefa para o chat "Ajustar battle": manter o runtime surface manifest como
  fonte obrigatoria antes de alterar scripts fora do recurring run, e adicionar
  fixture que falhe quando arquivo battle/Hermes novo entra sem categoria,
  owner, gate esperado e coverage esperado.

## Passo de auditoria - latest 004504 runtime-safe/focused evidence contract 2026-06-19T23:34-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/unknown_template_backlog.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py`
- `server/bin/manaloom_battle_rule_focused_evidence.py`
- Logs oficiais do latest: `test_battle_effect_coverage_known_cards.log`,
  `test_battle_rule_registry_runtime_safe.log`,
  `test_battle_focused_template_dispatch_audit.log` e
  `test_battle_unknown_template_backlog_audit.log`.

Runtime-safe vs needs-review:

- `effect_coverage.json` publica `active_or_review_rule_names=3159`,
  `runtime_safe_rule_names=1702`, `non_runtime_safe_rule_names=1457`,
  `needs_review_rule_names=1457`, `review_only_rule_names=0`,
  `annotation_only_rule_names=0` e `non_runtime_other_rule_names=0`.
- `review_status_counts={"active":27,"needs_review":1457,"verified":1675}`
  e `execution_status_counts={"auto":3159}`.
- `battle_rule_registry._is_runtime_safe_rule(...)` so considera runtime-safe
  regras com `review_status in {"verified","active"}` e
  `execution_status in {"auto","executable"}`.
- `test_battle_rule_registry_runtime_safe.log` passou
  `test_runtime_safe_filter_separates_review_only_rules`, que cria regra
  verified/auto, needs_review/auto, verified/review_only e
  active/annotation_only, e exige que somente a verified/auto apareca quando
  `runtime_safe_only=True`.

Coverage/effect denominator:

- `source_totals={"battle_rule_curated":724,"type_land":377,"effect_map":100,"battle_rule_needs_review_generated":34,"focused_template_ready":33,"tag":14,"handcrafted":6}`.
- `effect_totals.unknown=41`, `unknown_effect_cards=34`,
  `unknown_effect_source_counts={"battle_rule_curated":1,"battle_rule_needs_review_generated":5,"focused_template_ready":28}` e
  `unknown_effect_status_counts={"focused_template_ready":28,"needs_review":5,"waived_curated_unknown_effect":1}`.
- `needs_review_unknown_effect_cards=5`: `Amulet of Vigor`, `Blood Moon`,
  `Exploration`, `Ghostly Flicker` e `Grasp of Fate`.
- `focused_template_cards=29`, mas `focused_template_ready_unknown_effect_cards=28`
  porque `Banishing Knack` esta `source=focused_template_ready` com
  `effect=remove_permanent` e match
  `supports_granted_bounce_ability_template`.
- `Mirrormade` permanece como `status=waived_curated_unknown_effect` com
  `waiver_reason=curated_rule_with_unknown_effect_family_kept_visible_in_unknown_effect_denominator`.

Naming/semantica do gate:

- O wrapper preenche `effect_coverage_unknowns` a partir de
  `coverage.flag_totals.unknown_effect`.
- `battle_effect_coverage_audit.py.risk_flags(...)` so adiciona
  `unknown_effect` quando `source == "unknown"`.
- Portanto, no latest atual, `mandatory_gate_statuses.effect_coverage.unknown_effects=0`
  significa zero source-unknown bloqueante; nao significa que
  `effect_totals.unknown` foi zerado.
- O denominador de familia de efeito unknown continua publicado separadamente
  como `effect_coverage_effect_totals_unknown=41` e nao deve ser usado como
  substituto de `mandatory_gate_divergences`.

Focused evidence:

- `focused_template_dispatch.json.summary` publica
  `status=focused_template_dispatch_ready`, `focused_template_cards=29`,
  `template_predicate_match=29`, `evidence_dispatch_ready=29`,
  `focused_evidence_ready=29`, `focused_evidence_not_ready_unwaived=0`,
  `without_template_predicate_match=0`, `without_evidence_dispatch=0`,
  `accepted_waivers=0`, `supports_template_count=47`,
  `evaluate_dispatch_template_count=47` e
  `build_evidence_function_count=47`.
- Os `29` itens possuem `focused_evidence_ready=true`,
  `evidence_dispatch_ready=true` e `template_predicate_match=true`.
- Os `29` itens apontam para `116` artefatos de evidencia, e a checagem direta
  confirmou `116/116` arquivos existentes e nao vazios.
- `battle_focused_template_dispatch_audit.py` define o status como
  `focused_template_dispatch_ready` quando nao ha item sem
  `focused_evidence_ready` e sem waiver aceito; o Markdown do proprio auditor
  documenta que predicate, dispatch e evidence sao camadas diferentes.

Unknown template backlog:

- `unknown_template_backlog.json.summary` publica
  `status=focused_template_backlog_ready`, `unknown_cards=0`,
  `source_unknown_cards=0`, `effect_unknown_cards=34`,
  `effect_unknown_status_counts={"focused_template_ready":28,"needs_review":5,"waived_curated_unknown_effect":1}`,
  `without_plan_or_waiver=0`, `without_reviewed_family=0`,
  `without_focused_template_match=0` e `without_current_inferred_family=0`.
- `battle_unknown_template_backlog_audit.py` monta `items` somente a partir de
  `coverage.unknown_cards` e publica `effect_unknown_cards` apenas como
  denominador separado.
- O teste `test_backlog_separates_source_unknown_from_effect_unknown_denominator`
  fixa exatamente essa separacao: `unknown_cards=0` e `source_unknown_cards=0`
  podem coexistir com `effect_unknown_cards > 0`.

Test provenance:

- `test_battle_effect_coverage_known_cards.log`: `8` tests, `OK`.
- `test_battle_rule_registry_runtime_safe.log`: `PASS test_runtime_safe_filter_separates_review_only_rules`.
- `test_battle_focused_template_dispatch_audit.log`: `5 tests passed`.
- `test_battle_unknown_template_backlog_audit.log`: `4` checks `PASS`,
  incluindo a separacao source-unknown/effect-unknown.

Leitura operacional:

- Nenhum novo blocker validado nesta etapa.
- `focused_template_dispatch_ready` prova que os `29` itens focados tem
  predicate, dispatch e evidence artifact prontos; nao promove automaticamente
  os `28` focused-template-ready unknown effects para regra card-specific
  runtime-safe.
- `unknown_template_backlog_cards=0` prova que nao ha card com `source=unknown`
  sem plano/template; nao prova que `effect_totals.unknown=41` foi resolvido.
- `needs_review_rule_names=1457` continua visivel e separado de runtime-safe;
  consumidores nao podem tratar regra `needs_review` como segura para
  aprendizagem/acao sem promotion ou waiver explicito.

Resultado:

- Nenhum novo BV aberto nesta etapa.
- O quadro aberto atual permanece `BV-081` e `BV-082`.
- Tarefa para o chat "Ajustar battle": renomear ou documentar no
  `summary.json` a diferenca entre `effect_coverage_unknowns` (source-unknown
  bloqueante) e `effect_coverage_effect_totals_unknown` (familia de efeito
  unknown visivel), e manter fixture que falhe quando consumidor tratar
  `focused_template_ready`, `needs_review` ou backlog ready como runtime-safe
  card-specific.

## Passo de auditoria - latest 004504 action-event denominator naming 2026-06-19T22:58-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/seed_*/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_004504/event_contract_static.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`

Evidencia verificada:

- Latest real confirmado: `20260620_004504`, `seeds_requested=16`,
  `seeds_completed=16`, `battle_replay_final_status=trusted_for_strategy_learning`
  e `mandatory_gate_divergences=[]`.
- `summary.json` publica `action_events_total=15662`,
  `action_event_types_total=560`,
  `action_event_contract_class_counts={"action_audited":6226,"ignored_with_reason":374,"renderer_only":32,"strategy_signal":242,"technical":8788}`
  e
  `action_event_type_class_counts={"action_audited":326,"ignored_with_reason":37,"renderer_only":32,"strategy_signal":92,"technical":73}`.
- Recomputacao direta dos `16` `seed_*/action_critic.json` confirmou:
  `sum_seed_event_types=560`,
  `sum_seed_summary_event_types_total=560`,
  `global_distinct_event_types=53` e
  `events_unclassified=0`.
- O denominador global distinto ja existe em outro campo:
  `event_contract_static_observed_event_types_total=53`,
  com `event_contract_static_all_event_types_total=101`,
  `observed_unclassified_total=0`,
  `static_unclassified_total=0` e
  `static_fixture_unaccepted_types=[]`.
- O wrapper agrega os campos de action critic por soma de seeds:
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh:714`
  soma `event_types_total`, e `:718-719` soma
  `event_type_class_counts`. O mesmo wrapper publica o denominador global do
  auditor estatico em `:1025`.

Leitura operacional:

- Isto nao e blocker de gameplay e nao invalida o status final do latest, porque
  `mandatory_gate_statuses.action_critic.status=pass`,
  `mandatory_gate_statuses.event_contract_static.status=pass` e
  `mandatory_gate_divergences=[]`.
- A falha e de nomenclatura/observabilidade: `action_event_types_total=560`
  parece "tipos globais distintos", mas na pratica e uma soma dos tipos unicos
  vistos dentro de cada seed. O denominador global distinto para o run e `53`.
- O risco e um consumidor inflar a superficie de eventos coberta pelo replay ou
  comparar incorretamente `560` contra `101` tipos estaticos.

Resultado: `BV-083` aberto como P2 de contrato do `summary.json`.

- Tarefa para o chat "Ajustar battle": renomear
  `action_event_types_total`/`action_event_type_class_counts` para campos
  explicitamente `*_seed_sum`, ou publicar tambem
  `action_event_types_distinct_total` e
  `action_event_type_class_distinct_counts`; atualizar `summary.md` e fixture
  multi-seed para impedir que repeticao do mesmo tipo em varias seeds infle o
  denominador global.
- O quadro aberto atual passa a ser `BV-081`, `BV-082` e `BV-083`.

## Passo de auditoria - recheck BV-068 2026-06-19T22:40Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_224052/summary.json`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Resultado atual do latest:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `effect_coverage.unknown_effects=0` no rollup de mandatory gates.
- `focused_template_dispatch_status=focused_template_dispatch_ready`
- `focused_template_cards=29`
- `focused_template_evidence_ready=29`
- `focused_template_ready_unknown_effect_cards` publica `29` cartas.
- `effect_totals_unknown=null`
- `needs_review_unknown_effect_cards=null`

Tratativa aplicada nesta auditoria:

- O achado continua aberto, mas a leitura corrente nao deve usar o run
  `20260619_214539` como latest atual.
- O latest `20260619_224052` ja expõe a lista
  `focused_template_ready_unknown_effect_cards`, mas ainda nao fecha o criterio
  de BV-068 porque o resultado principal continua sem `effect_totals_unknown` e
  sem `needs_review_unknown_effect_cards`.
- Interpretacao obrigatoria: `focused_template_dispatch_ready` prova a fila
  focada pronta para evidencia; nao prova que todo denominador de
  `effect == unknown` foi reconciliado no coverage principal.

Resultado: `BV-068` permanece aberto ate o wrapper/coverage publicar
`effect_totals_unknown` e separar `focused_template_ready` de
`needs_review_unknown_effect_cards`, ou ate `effect_totals.unknown=0` ser
provado por artifact atualizado.

## Passo de auditoria - latest transition 2026-06-19T22:55Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_225500/summary.json`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`

Resultado atual do wrapper oficial:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `action_findings=0`
- `strategy_findings=3`
- `strategy_review_required_findings=0`
- `strategy_low_confidence_findings=3`
- `strategy_low_confidence_seeds=["63202259","63202261","63202266"]`
- `strategy_high_confidence_learning_seeds=["63202255","63202256","63202257","63202258","63202260","63202262","63202263","63202264","63202265","63202267","63202268","63202269","63202270"]`
- `forensic_lineage_status=complete`
- `forensic_card_id_missing=573`, todos aceitos: `forensic_card_id_missing_unaccepted=0`
- `forensic_semantic_hash_missing=573`, todos aceitos: `forensic_semantic_hash_missing_unaccepted=0`
- `forensic_rule_logical_key_missing=20`, todos aceitos: `forensic_rule_logical_key_missing_unaccepted=0`
- `decision_trace_taxonomy_rows=2337`
- `decision_trace_kinds_observed=12/15`
- `event_contract_static_fixture_or_waiver_counts={"observed_in_latest":52,"static_contract_accepted_waiver":49}`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`
- `test_log_empty_successes=[]`
- `test_log_empty_failures=[]`

Reconciliacao documental aplicada:

- `BATTLE_REPLAY_GATE_MATRIX.md` foi atualizado de `20260619_224052` para
  `20260619_225500`.
- `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` agora aponta a gate matrix
  para o latest `20260619_225500`.

Pendencias que continuam abertas apos o latest:

- `global_learning_eligible_seeds=null` e `global_not_learning_eligible_seeds=null`;
  portanto `strategy_high_confidence_learning_seeds` ainda nao deve ser lido
  como elegibilidade global pos-gates.
- `effect_totals_unknown=null` e `needs_review_unknown_effect_cards=null`;
  portanto `BV-068` continua aberto apesar de `focused_template_ready_unknown_effect_cards`
  listar `29` cartas.
- `learned_deck_opponents=null`, `opponent_deck_provenance=null` e
  `learned_opponent_source_counts=null`; portanto `BV-075` continua aberto.
- `functional_tags_json_event_count=null` e `functional_tags_json_cards=null`;
  o absence/presence de eventos `functional_tags_json` ainda precisa de campo
  agregado no summary antes de ser usado como prova principal.

## Passo de auditoria - latest transition 2026-06-19T22:58Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_225846/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_225846/seed_63202272/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_225846/seed_63202272/forensic_audit.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`

Resultado atual do wrapper oficial:

- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["forensic_audit=review_required"]`
- `action_findings=0`
- `strategy_findings=3`
- `strategy_review_required_findings=0`
- `strategy_low_confidence_findings=3`
- `strategy_low_confidence_seeds=["63202259","63202261","63202266"]`
- `strategy_high_confidence_learning_seeds=["63202258","63202260","63202262","63202263","63202264","63202265","63202267","63202268","63202269","63202270","63202271","63202272","63202273"]`
- `forensic_lineage_status=complete`
- `forensic_rule_findings=2`
- `forensic_turn_findings=0`
- `forensic_severity_counts={"low":2}`
- `forensic_card_id_missing=608`, todos aceitos: `forensic_card_id_missing_unaccepted=0`
- `forensic_semantic_hash_missing=608`, todos aceitos: `forensic_semantic_hash_missing_unaccepted=0`
- `forensic_rule_logical_key_missing=27`, todos aceitos: `forensic_rule_logical_key_missing_unaccepted=0`
- `decision_trace_taxonomy_rows=2360`
- `decision_trace_kinds_observed=12/15`
- `event_contract_static_fixture_or_waiver_counts={"observed_in_latest":53,"static_contract_accepted_waiver":48}`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`
- `test_log_empty_successes=[]`
- `test_log_empty_failures=[]`

Achado forensic novo:

- Seed `63202272`, turno `13`, fase `precombat_main`, player
  `Kraum, Ludevic's Opus #83 (real)`, carta `Snapback`.
- Evento `spell_cast`: runtime effect `remove_permanent` diverge do registry
  effect `remove_creature`.
- Evento `spell_resolved`: runtime effect `remove_permanent` diverge do registry
  effect `remove_creature`.
- Ambos os findings sao `low`; o auditor recomenda tratar como possivel
  normalizacao de oracle se o replay parecer correto.

Reconciliacao documental aplicada:

- `BATTLE_REPLAY_GATE_MATRIX.md` foi atualizado de `20260619_225500`
  `trusted_for_strategy_learning` para `20260619_225846` `review_required`.
- `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` agora aponta a gate matrix
  para o latest `20260619_225846`.
- `BV-078` foi aberto para impedir que o run stale `20260619_225500` seja usado
  como prova atual de aprendizado confiavel.

Pendencias que continuam abertas apos o latest:

- `global_learning_eligible_seeds=null` e `global_not_learning_eligible_seeds=null`;
  portanto `strategy_high_confidence_learning_seeds` ainda nao deve ser lido
  como elegibilidade global pos-gates, especialmente porque o aggregate atual
  esta em `review_required`.
- `effect_coverage_effect_totals_unknown=41`, `focused_template_ready_unknown_effect_count=28`
  e `needs_review_unknown_effect_cards=null`; portanto `BV-068` continua aberto
  ate o coverage separar todo denominador unknown por foco/needs-review/waiver.
- `learned_deck_opponents=null`, `opponent_deck_provenance=null` e
  `learned_opponent_source_counts=null`; portanto `BV-075` continua aberto.
- `functional_tags_json_event_count=null` e `functional_tags_json_cards=null`;
  o absence/presence de eventos `functional_tags_json` ainda precisa de campo
  agregado no summary antes de ser usado como prova principal.

## Passo de auditoria - latest transition 2026-06-19T23:08Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_230829/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_230829/seed_63202308/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_230829/seed_63202308/replay_decision_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_230829/seed_63202310/forensic_audit.json`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`

Resultado atual do wrapper oficial:

- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["forensic_audit=review_required","replay_decision_audit=review_required"]`
- `action_findings=0`
- `strategy_findings=4`
- `strategy_review_required_findings=0`
- `strategy_low_confidence_findings=4`
- `strategy_low_confidence_seeds=["63202311","63202314","63202315","63202318"]`
- `strategy_high_confidence_learning_seeds=["63202308","63202309","63202310","63202312","63202313","63202316","63202317","63202319","63202320","63202321","63202322","63202323"]`
- `forensic_lineage_status=complete`
- `forensic_rule_findings=2`
- `forensic_turn_findings=1`
- `forensic_severity_counts={"low":3}`
- `forensic_card_id_missing=559`, todos aceitos: `forensic_card_id_missing_unaccepted=0`
- `forensic_semantic_hash_missing=559`, todos aceitos: `forensic_semantic_hash_missing_unaccepted=0`
- `forensic_rule_logical_key_missing=23`, todos aceitos: `forensic_rule_logical_key_missing_unaccepted=0`
- `decision_trace_taxonomy_rows=2284`
- `decision_trace_kinds_observed=12/15`
- `event_contract_static_fixture_or_waiver_counts={"observed_in_latest":54,"static_contract_accepted_waiver":47}`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`
- `test_log_empty_successes=[]`
- `test_log_empty_failures=[]`

Achados novos do latest:

- Seed `63202310`, turno `7`, fase `precombat_main`, player
  `Kraum, Ludevic's Opus #83 (real)`, carta `Into the Flood Maw`.
- Evento `spell_cast`: runtime effect `remove_creature` diverge do registry
  effect `remove_permanent`.
- Evento `spell_resolved`: runtime effect `remove_creature` diverge do registry
  effect `remove_permanent`.
- Seed `63202308`, turno `10`, player `Lorehold`, evento `removal_resolved`:
  `Removal hit a low-power target while multiple targets were available.`
- O mesmo finding de alvo aparece em `replay_decision_audit.json`, mantendo
  `replay_decision_audit` em `review_required`.

Reconciliacao documental aplicada:

- `BATTLE_REPLAY_GATE_MATRIX.md` foi atualizado de `20260619_225846` para
  `20260619_230829`.
- `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` agora aponta a gate matrix
  para o latest `20260619_230829`.
- `BV-078` saiu da lista aberta porque seu caso `Snapback` ficou historico no
  run `20260619_225846`; `BV-079` foi aberto para o blocker/review atual.

Pendencias que continuam abertas apos o latest:

- `global_learning_eligible_seeds=null` e `global_not_learning_eligible_seeds=null`;
  portanto `strategy_high_confidence_learning_seeds` ainda nao deve ser lido
  como elegibilidade global pos-gates, especialmente porque o aggregate atual
  esta em `review_required`.
- `effect_coverage_effect_totals_unknown=41`, `focused_template_ready_unknown_effect_count=28`
  e `needs_review_unknown_effect_cards=null`; portanto `BV-068` continua aberto
  ate o coverage separar todo denominador unknown por foco/needs-review/waiver.
- `learned_deck_opponents=null`, `opponent_deck_provenance=null` e
  `learned_opponent_source_counts=null`; portanto `BV-075` continua aberto.
- `functional_tags_json_event_count=null` e `functional_tags_json_cards=null`;
  o absence/presence de eventos `functional_tags_json` ainda precisa de campo
  agregado no summary antes de ser usado como prova principal.

## Passo de auditoria - deep dive historico BV-079 target choice 2026-06-19T23:20Z

Fonte do run `20260619_230829`:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_230829/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_230829/seed_63202308/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_230829/seed_63202308/replay.decision_trace.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_230829/seed_63202308/replay.txt`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_230829/seed_63202308/replay_decision_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_230829/seed_63202308/forensic_audit.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_removal_target_choice_recheck_20260619_202022.md`

Evidencia confirmada:

- O run `20260619_230829` estava `battle_replay_final_status=review_required` por
  `mandatory_gate_divergences=["forensic_audit=review_required","replay_decision_audit=review_required"]`.
- Seed `63202308`, turno `10`, carta `Rise of the Eldrazi`: o evento
  `removal_resolved` escolhe `Fiend Artisan`, informa `available_targets=3`,
  `target_power=1`, `target_toughness=1`, mas nao publica `target_score` nem
  `target_options`.
- `replay_decision_audit.json` e `forensic_audit.json` registram o mesmo finding
  low: `Removal hit a low-power target while multiple targets were available.`
- `replay.decision_trace.jsonl` nao tem entrada para `Rise of the Eldrazi` nem
  para a selecao do alvo de remocao.
- `replay.txt` renderiza apenas `REMOVAL Lorehold: Rise of the Eldrazi removed
  Fiend Artisan...`, sem count/opcoes/score/razao do alvo.
- O worktree sujo atual de `battle_analyst_v9.py` contem diff local adicionando
  `target_score`/`target_options` em emissoes de remocao, mas essa mudanca e
  posterior ao artifact oficial: `replay.events.jsonl` mtime
  `2026-06-19T20:08:47-0300`, `summary.json` mtime
  `2026-06-19T20:11:08-0300`, `battle_analyst_v9.py` mtime
  `2026-06-19T20:16:43-0300`.

Leitura de validacao:

- Nao ha prova no artifact atual de que o alvo escolhido foi incorreto; ha prova
  de que o ledger oficial nao guarda as opcoes/score suficientes para separar
  erro de estrategia de lacuna de registro.
- Diff local nao fecha gate. `BV-079` so pode sair do quadro aberto apos novo
  wrapper oficial gerar `summary.json` com `battle_replay_final_status` trusted
  ou waiver formal que remova `forensic_audit` e `replay_decision_audit` de
  review.

Tarefa para o chat "Ajustar battle":

- Persistir `target_score`, `target_options` e/ou `target_choice_reason` em todo
  `removal_resolved` com `available_targets > 1`, incluindo componentes de
  `composite_resolution`.
- Emitir decision trace de selecao de alvo ou expor campo equivalente consumivel
  pelo `replay_decision_auditor.py`.
- Renderizar no `replay.txt` a contagem/opcoes resumidas e a razao do alvo
  quando houver multiplos alvos legais.
- Rerodar o wrapper oficial e usar somente o novo `latest/summary.json` para
  decidir se `BV-079` fecha, continua como bug de targeting ou vira waiver
  formal.

Resultado naquele momento: `BV-079` permanecia aberto; nada foi fechado por diff
local. A secao seguinte revalida o novo latest e fecha `BV-079` como stale
latest regression.

## Passo de auditoria - latest transition 2026-06-19T23:18Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_231827/summary.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_231827_gate_lineage_recheck_20260619_202435.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`

Resultado atual do wrapper oficial:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `mandatory_gate_statuses.forensic_audit.status=pass`
- `mandatory_gate_statuses.replay_decision_audit.status=pass`
- `action_findings=0`
- `strategy_findings=4`
- `strategy_review_required_findings=0`
- `strategy_low_confidence_findings=4`
- `strategy_low_confidence_seeds=["63202318","63202332","63202333"]`
- `strategy_high_confidence_learning_seeds=["63202319","63202320","63202321","63202322","63202323","63202324","63202325","63202326","63202327","63202328","63202329","63202330","63202331"]`
- `strategy_learning_confidence_counts={"high_confidence_replay":13,"low_confidence_replay":3}`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `decision_audit_turn_findings=0`
- `decision_audit_decision_findings=0`
- `decision_trace_taxonomy_rows=2187`
- `decision_trace_kinds_observed=12/15`
- `event_contract_static_fixture_or_waiver_counts={"observed_in_latest":54,"static_contract_accepted_waiver":47}`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`
- `test_log_empty_successes=[]`
- `test_log_empty_failures=[]`

Reconciliacao documental aplicada:

- `BATTLE_REPLAY_GATE_MATRIX.md` foi atualizado de `20260619_230829`
  `review_required` para `20260619_231827`
  `trusted_for_strategy_learning`.
- `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` agora aponta a gate matrix
  para o latest `20260619_231827`.
- `BV-079` saiu da lista aberta porque o criterio de fechamento foi atendido
  pelo wrapper oficial: latest trusted e `mandatory_gate_divergences=[]`.

Nova pendencia aberta naquele run:

- `BV-080`: o run `20260619_231827` trusted ainda publicava
  `forensic_lineage_status=incomplete`, `forensic_card_id_missing_unaccepted=2`
  e `forensic_semantic_hash_missing_unaccepted=2`.
- `forensic_lineage_unaccepted_missing_samples` aponta `Bridgeworks Battle`,
  seed `63202328`, eventos `spell_cast` e `spell_resolved`, `effect=draw_cards`,
  source `curated`, sem `card_id` e sem `semantic_hash`.

Leitura operacional:

- O status agregado de battle voltou a trusted para os gates obrigatorios daquele
  run.
- Isso nao fecha os follow-ups de lineage/coverage/provenance. Em especial,
  `trusted_for_strategy_learning` nao deve ser usado como prova de lineage
  completo sem checar os contadores `forensic_*_missing_unaccepted`.

## Passo de auditoria - latest transition 2026-06-19T23:23Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/summary.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_232324_gate_recheck_20260619_202744.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`

Resultado atual do wrapper oficial:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `mandatory_gate_statuses.forensic_audit.status=pass`
- `mandatory_gate_statuses.replay_decision_audit.status=pass`
- `action_findings=0`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `decision_audit_turn_findings=0`
- `decision_audit_decision_findings=0`
- `strategy_findings=4`
- `strategy_review_required_findings=0`
- `strategy_low_confidence_findings=4`
- `forensic_lineage_status=complete`
- `forensic_card_id_missing_unaccepted=0`
- `forensic_semantic_hash_missing_unaccepted=0`
- `forensic_rule_logical_key_missing_unaccepted=0`
- `forensic_lineage_unaccepted_missing_samples=[]`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`
- `test_log_empty_successes=[]`
- `test_log_empty_failures=[]`

Recheck de alvo e lineage:

- Scan dos `16` `forensic_audit.json`: `total_rule_findings=0`,
  `total_turn_findings=0` e `with_unaccepted=0`.
- Scan dos `16` `replay_decision_audit.json`: `total_decision_findings=0` e
  `total_turn_findings=0`.
- Scan dos `24` eventos `removal_resolved`: apenas `1` tinha
  `available_targets > 1`, em `seed_63202325`, turno `7`, carta
  `Rise of the Eldrazi`, alvo `Etali, Primal Conqueror`,
  `available_targets=2`, `target_score=[1,1,4,4,4]` e
  `target_options_len=2`.
- Multi-target removals sem target provenance no latest `232324`: `0`.
- `Bridgeworks Battle` aparece em `seed_63202328` e `Into the Flood Maw`
  aparece em `seed_63202335`, mas nenhum deles gera finding forense ou missing
  lineage nao aceito no latest atual.

Reconciliacao documental aplicada:

- `BV-080` saiu de `Achados abertos` porque o latest `232324` fechou a lineage
  que estava incompleta no run `231827`.
- `BATTLE_REPLAY_GATE_MATRIX.md` e
  `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` foram atualizados para
  `20260619_232324`.
- O report `battle_latest_231827_gate_lineage_recheck_20260619_202435.md`
  permanece como evidencia historica do run `231827`, nao como status atual.

Pendencias que continuam abertas apos o latest:

- `BV-069`, `BV-071`, `BV-072`, `BV-074` e `BV-075` permanecem no quadro
  aberto.
- `effect_coverage_effect_totals_unknown=41`,
  `focused_template_ready_unknown_effect_count=28`,
  `needs_review_rule_names=1457` e `non_runtime_safe_rule_names=1457` continuam
  como denominadores que nao sao fechados apenas por
  `battle_replay_final_status=trusted_for_strategy_learning`.

## Passo de auditoria - BV-072/BV-075 latest recheck 2026-06-19T23:36Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/seed_*/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/seed_*/deck_provenance.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_global_learning_and_learned_opponents_recheck_20260619_203626.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`

Evidencia de gate/strategy:

- O latest segue `battle_replay_final_status=trusted_for_strategy_learning` e
  `mandatory_gate_divergences=[]`.
- Scans por seed: `16` `action_critic.json` com `findings=0`, `16`
  `forensic_audit.json` com `rule_findings=0` e `turn_findings=0`, e `16`
  `replay_decision_audit.json` com `decision_findings=0` e `turn_findings=0`.
- Strategy por seed: `13` `high_confidence_replay`, `3`
  `low_confidence_replay`, `review_required_findings=0`, `4` findings totais,
  todos `forced_keep_after_bad_mulligan` nas seeds `63202332`, `63202333` e
  `63202338`, com peso `0.0`.
- `strategy_high_confidence_learning_seeds` lista `13` seeds com peso `1.0`.
- `global_learning_eligible_seeds=null` e
  `global_not_learning_eligible_seeds=null` no resultado principal.

Resultado para `BV-072`:

- `BV-072` permanece aberto. Inferencia: como o run final esta trusted, a lista
  `strategy_high_confidence_learning_seeds` e consistente com elegibilidade
  global neste snapshot, mas isso ainda nao e contrato publicado pelo summary.
- Fechamento exige campos globais pos-gates com reasons por seed, para impedir
  que consumidor leia campo `strategy_*` como contrato global.

Evidencia de learned opponents:

- O summary lista `16` `deck_provenance_files` e
  `deck_source_blocker_domains={"none":64}`, mas publica
  `learned_deck_opponents=null`, `opponent_deck_provenance=null` e
  `learned_opponent_source_counts=null`.
- Nos `deck_provenance.json`, ha `64` linhas de deck: `16` de Lorehold
  (`sqlite_deck_cards`, `deck_id:6`, construction report valido) e `48`
  aparicoes de oponentes `learned_decks`.
- Os `48` oponentes learned somam `11` `source_ref` unicos, todos
  `source_system=pg_meta_decks`, `source_card_count=100`,
  `battle_card_count=99`, `cached_metadata_used_for_metrics=false`,
  `metrics_basis=runtime_derived_from_resolved_built_deck`,
  `blocker_domain=none` e `construction_report=null`.
- Maiores aparicoes atuais: `learned_deck:105` (`8`), `learned_deck:116` (`7`),
  `learned_deck:104` (`6`), `learned_deck:84` (`5`),
  `learned_deck:74` (`5`) e `learned_deck:42` (`5`).

Resultado para `BV-075`:

- `BV-075` permanece aberto. A provenance existe nos artifacts por seed, mas o
  resultado principal ainda nao agrega os oponentes learned nem construction/
  coherence status.
- Tarefa para o chat "Ajustar battle": agregar no `summary.json` os learned
  opponents por `source_system`, `source_ref`, `name`, aparicoes/seeds,
  contagens de cartas, basis de metrica, cached flag, blocker domain e status de
  construction/coherence; adicionar teste que falhe quando esses campos ficarem
  `null` apesar de existirem learned opponents nos `deck_provenance.json`.

## Passo de auditoria - fechamento BV-063 2026-06-19T23:24Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/seed_*/replay.txt`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/seed_*/replay.events.jsonl`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`

Tratativa aplicada:

- `utility_land_activated` com pagamento de vida agora propaga
  `life_before`/`life_after`; o renderer nao precisa mais emitir
  `life=?->`.
- `commander_cast`, `miracle_cast` e `end_step_instant` propagam `cmc`; o
  renderer nao precisa mais emitir `CMC=?` para os caminhos atuais.
- O teste do renderer foi ajustado para exigir vida real em pagamento por
  Ancient Tomb e para rejeitar placeholders de CMC em cast especial.
- A leitura operacional continua: `replay.txt` e projecao humana; o ledger de
  prova segue sendo JSONL + gates + auditors.

Evidencia do latest oficial:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`
- Placeholders textuais nos `replay.txt` do run `232324`: `CMC=?=0`,
  `life=?->=0`, `event=?=0`, `stack=?=0`, `target=?=0`, `phase=?=0` e
  `priority_window=?=0`.
- Missing fields no `replay.events.jsonl` do run `232324`:
  `utility_land_life_fields=0`, `commander_cast_cmc=0`,
  `miracle_cast_cmc=0`, `end_step_instant_cmc=0`.

Validacoes executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS.
- Scan controlado do latest `232324` para placeholders textuais - PASS, todos
  zerados.
- Scan controlado do latest `232324` para campos fonte vida/CMC no JSONL - PASS,
  todos zerados.

Resultado: `BV-063` removido do quadro aberto.

## Passo de auditoria - fechamento BV-064 2026-06-19T23:24Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/seed_*/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/seed_*/replay.txt`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`

Tratativa aplicada:

- `spell_countered` agora carrega `phase` e `priority_window` no evento
  primario, alem de `counter`, `target`, `stack_object`, `target_controller`,
  `target_effect`, `result`, `stack_depth` e `cost`.
- O renderer humano imprime `phase=... priority_window=...` na linha
  `COUNTER`.
- O action critic passou a emitir `counter_without_priority_window` quando
  `spell_countered` nao trouxer `phase` ou `priority_window`.
- A suite de stack casting cobre a janela `stack_response` no evento de counter.

Evidencia do latest oficial:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `spell_countered_total=8`
- `spell_countered` sem `phase`: `0`
- `spell_countered` sem `priority_window`: `0`
- Linhas `COUNTER` do `replay.txt` sem `phase=` ou `priority_window=`: `0`

Validacoes executadas:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS.
- Scan controlado do latest `232324` em `replay.events.jsonl` e `replay.txt` -
  PASS: zero counters sem janela.

Resultado: `BV-064` removido do quadro aberto.

## Passo de auditoria - fechamento BV-066 2026-06-19T23:24Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/event_contract_static.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/seed_*/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/seed_*/replay.decision_trace.jsonl`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`

Tratativa aplicada:

- O contrato estatico de `spell_resolved` agora publica `minimum_fields` com
  `phase`, `priority_window`, `stack_object`, `stack_depth`, `source_zone`,
  `from_zone`, `to_zone`, `destination`, `zone_after`,
  `resolved_from_stack`, `result`, `cast_pipeline` e `locked_cost`.
- O action critic agora exige o mesmo pacote de provenance para
  `spell_resolved` e emite `spell_resolved_without_resolution_provenance` quando
  qualquer campo estiver ausente.
- O runner manual de `test_battle_action_critic.py` passou a executar as
  fixtures negativa/positiva de `spell_resolved`.
- A fixture positiva do action critic foi alinhada ao contrato completo,
  incluindo `priority_window`, `zone_after` e `locked_cost`.

Evidencia do latest oficial:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `spell_resolved_total=307`
- Missing fields nos `307` `spell_resolved`: `phase=0`,
  `priority_window=0`, `stack_object=0`, `stack_depth=0`, `source_zone=0`,
  `from_zone=0`, `to_zone=0`, `destination=0`, `zone_after=0`,
  `resolved_from_stack=0`, `result=0`, `cast_pipeline=0`, `locked_cost=0`.
- `event_contract_static.json` para `spell_resolved`: `observed_count=307`,
  `minimum_fields` completo, `summary.observed_missing_required_fields=0` e
  `field_findings=[]`.
- Action critic local sobre os `15277` eventos do latest com decision traces:
  `findings=0`, `code_counts={}`,
  `spell_resolved_without_resolution_provenance=0`.

Validacoes executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` - PASS, `17` testes.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py` - PASS, `7` testes.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py` - PASS.
- Scan controlado do latest `232324` para missing fields de
  `spell_resolved` - PASS, todos zerados.

Resultado: `BV-066` removido do quadro aberto.

## Passo de auditoria - fechamento BV-068 2026-06-19T23:42Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/unknown_template_backlog.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py`

Tratativa aplicada:

- `effect_coverage.json` agora publica `unknown_effect_cards` com `source`,
  `status`, `owner`, flags, decks e escopos de focused template.
- `effect_coverage_unknown_effect_source_counts` e
  `effect_coverage_unknown_effect_status_counts` foram expostos no
  `summary.json` principal do wrapper.
- `needs_review_unknown_effect_cards` e `needs_review_unknown_effect_count`
  foram expostos no `summary.json`.
- `unknown_template_backlog.json` agora separa `source_unknown_cards` de
  `effect_unknown_cards`; `unknown_template_backlog_cards=0` nao significa mais
  zero `effect=unknown`.
- `Mirrormade`, unico `battle_rule_curated` com `effect=unknown`, recebeu status
  explicito `waived_curated_unknown_effect` com owner `battle-effect-contract`.

Evidencia do latest oficial:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `effect_coverage_effect_totals_unknown=41`
- `effect_coverage_unknown_effect_cards=34`
- `effect_coverage_unknown_effect_source_counts={"battle_rule_curated":1,"battle_rule_needs_review_generated":5,"focused_template_ready":28}`
- `effect_coverage_unknown_effect_status_counts={"focused_template_ready":28,"needs_review":5,"waived_curated_unknown_effect":1}`
- `focused_template_ready_unknown_effect_count=28`
- `needs_review_unknown_effect_count=5`
- `unknown_template_backlog_cards=0`
- `unknown_template_backlog.summary.source_unknown_cards=0`
- `unknown_template_backlog.summary.effect_unknown_cards=34`
- `unknown_template_backlog.summary.effect_unknown_status_counts={"focused_template_ready":28,"needs_review":5,"waived_curated_unknown_effect":1}`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`
- `test_log_empty_successes=[]`
- `test_log_empty_failures=[]`

Validacoes executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS, `7` testes.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py` - PASS, `4` testes.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_residual_audit.py` - PASS, `3` testes.
- Wrapper oficial `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` - PASS, latest `20260619_234218`.

Resultado: `BV-068` removido do quadro aberto. O efeito `unknown` nao foi
eliminado; ele agora fica em denominador proprio com source, owner e status.
Handoffs continuam proibidos de usar `unknown_template_backlog_cards=0` como
prova de zero unknown effects.

## Passo de auditoria - latest 234218 effect/learning/provenance recheck 2026-06-19T23:42Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/effect_coverage.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/seed_*/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/seed_*/deck_provenance.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_234218_effect_learning_provenance_recheck_20260619_204548.md`

Leitura do snapshot:

- O run esta `trusted_for_strategy_learning`, `battle_replay_final_status_reason=all_mandatory_gates_pass` e `mandatory_gate_divergences=[]`.
- `BV-068` esta fechado no snapshot `234218`: `effect_coverage_effect_totals_unknown=41`, `effect_coverage_unknown_effect_cards=34` e a soma de aparicoes por deck desses cards tambem e `41`; as listas agora separam `focused_template_ready=28`, `needs_review=5` e `waived_curated_unknown_effect=1`.
- `BV-069` permanecia aberto neste snapshot `234218`: o JSON tinha `battle_rule_curated=724` e `battle_rule_needs_review_generated=34`, mas a tabela Markdown `Deck Coverage` ainda renderizava `Battle Manual=0` e `Battle Generated=0` para todos os decks por usar chaves historicas. Esse ponto foi superado pelo fechamento `BV-069` no report `battle_effect_coverage_audit_20260619_234917.*`.
- `BV-072` permanece aberto: o summary publica `strategy_learning_confidence_counts={"high_confidence_replay":13,"low_confidence_replay":3}`, mas `global_learning_eligible_seeds=null` e `global_not_learning_eligible_seeds=null`.
- `BV-075` permanece aberto: os `deck_provenance.json` por seed mostram `48` aparicoes de learned opponents e `12` refs unicos, mas `summary.json` ainda publica `learned_deck_opponents=null`, `opponent_deck_provenance=null` e `learned_opponent_source_counts=null`.

Tarefas para o chat "Ajustar battle":

- Para `BV-069`, tarefa cumprida posteriormente no report `battle_effect_coverage_audit_20260619_234917.*`; ver fechamento abaixo.
- Para `BV-072`, publicar elegibilidade global pos-gates com reasons por seed.
- Para `BV-075`, agregar learned opponents no `summary.json` com `source_system`, `source_ref`, nome, aparicoes/seeds, card counts, metrics basis, cached flag, blocker domain e construction/coherence status.

## Passo de auditoria - fechamento BV-069 2026-06-19T23:49Z

Fonte atual:

- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_234917.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_234917.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py`

Tratativa aplicada:

- `battle_effect_coverage_audit.py` agora calcula as colunas de `Deck Coverage`
  a partir de `source_totals` e `deck_totals`, preservando ordem preferencial em
  `SOURCE_COLUMN_ORDER` e adicionando qualquer source nova dinamicamente.
- O teste focado exige `Battle Rule Curated` e
  `Battle Rule Needs Review Generated` no Markdown, e tambem exige que
  `Battle Manual` e `Battle Generated` nao aparecam.
- O report `battle_effect_coverage_audit_20260619_234917.md` renderiza a tabela
  com `Battle Rule Curated` e `Battle Rule Needs Review Generated`.

Evidencia do report atual:

- `source_totals.battle_rule_curated=724`
- `source_totals.battle_rule_needs_review_generated=34`
- `Deck Coverage` mostra `Battle Rule Curated` e
  `Battle Rule Needs Review Generated` por deck, incluindo `Lorehold target
  deck` com `67` curated e `0` needs-review generated.
- `battle_effect_coverage_audit_20260619_234917.json` mantem
  `unknown_effect_cards=34`,
  `unknown_effect_source_counts={"battle_rule_curated":1,"battle_rule_needs_review_generated":5,"focused_template_ready":28}`
  e
  `unknown_effect_status_counts={"focused_template_ready":28,"needs_review":5,"waived_curated_unknown_effect":1}`.

Validacoes executadas:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS, `8` testes.

Resultado: `BV-069` removido do quadro aberto. A tabela Markdown agora reconcilia
as source keys atuais do JSON; a existencia de `needs_review` e `effect=unknown`
continua sendo backlog de runtime/review, nao um problema de renderizacao do
denominador por deck.

## Passo de auditoria - BV-071 latest runtime surface recheck 2026-06-19T23:45Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/runtime_surface_manifest.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/summary.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_runtime_surface_manifest_denominator_recheck_20260619_205228.md`

Evidencia:

- `runtime_surface_manifest.json.summary.total_files=108`
- `runtime_surface_manifest.json.summary.unclassified_files=[]`
- `runtime_surface_manifest.json.summary.automation_coverage_counts={"covered_by_recurring_run":29,"imported_by_core_runtime":6,"outside_recurring_run":73}`
- `runtime_surface_manifest.json.summary.gate_expected_counts={"core_runtime_import_regression":6,"recurring_audit_required":29,"targeted_manual_gate_required_before_change":31,"targeted_test_required_before_change":42}`
- `summary.json.runtime_surface_manifest_total_files=108`
- `summary.json.runtime_surface_manifest_gate_expected_counts=null`
- `summary.json.runtime_surface_manifest_status=null`
- `test_battle_runtime_surface_manifest.py` ainda usa `assert summary["total_files"] >= 98`, sem fixar `108` nem as contagens por categoria/gate/coverage.

Resultado:

- `BV-071` permanece aberto. O manifest atual e detalhado, mas o teste continua permissivo para drift do denominador e o summary principal ainda nao publica os `gate_expected_counts`.
- Tarefa para o chat "Ajustar battle": fixar denominador/snapshot ou exigir waiver versionado quando `total_files` mudar; validar contagens exatas por categoria, coverage e gate; publicar `runtime_surface_manifest_gate_expected_counts` e status no `summary.json`.

## Passo de auditoria - latest 234922 gate/learning/provenance recheck 2026-06-19T23:49Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest` -> `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234922`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234922/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234922/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234922/effect_coverage.json`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_234922_current_open_recheck_20260619_205457.md`

Leitura do latest:

- `timestamp_utc=2026-06-19T23:49:22Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass` e
  `mandatory_gate_divergences=[]`.
- `test_results_total=16` e `test_results_status_counts={"pass":16}`.
- `strategy_learning_confidence_counts={"high_confidence_replay":13,"low_confidence_replay":3}`.
- `strategy_high_confidence_learning_seeds=["63202349","63202350","63202351","63202352","63202354","63202355","63202356","63202358","63202359","63202360","63202361","63202362","63202363"]`.
- `strategy_low_confidence_seeds=["63202353","63202357","63202364"]`.
- `global_learning_eligible_seeds=null` e
  `global_not_learning_eligible_seeds=null`.
- `learned_deck_opponents=null`, `opponent_deck_provenance=null` e
  `learned_opponent_source_counts=null`.
- `effect_coverage_effect_totals_unknown=41`,
  `effect_coverage_unknown_effect_source_counts={"battle_rule_curated":1,"battle_rule_needs_review_generated":5,"focused_template_ready":28}` e
  `effect_coverage_unknown_effect_status_counts={"focused_template_ready":28,"needs_review":5,"waived_curated_unknown_effect":1}`.
- `runtime_surface_manifest_total_files=108`, mas
  `runtime_surface_manifest_gate_expected_counts=null` e
  `runtime_surface_manifest_status=null` continuam ausentes do summary principal.
- `runtime_surface_manifest.json.summary.gate_expected_counts={"core_runtime_import_regression":6,"recurring_audit_required":29,"targeted_manual_gate_required_before_change":31,"targeted_test_required_before_change":42}` e
  `automation_coverage_counts={"covered_by_recurring_run":29,"imported_by_core_runtime":6,"outside_recurring_run":73}`.

Resultado:

- `BV-068` permanece fechado: o latest ainda publica o denominador de
  `effect=unknown` com source/status/owner, mas isso nao prova runtime completo
  para todos os efeitos unknown.
- `BV-069` permanece fechado: `effect_coverage.json` e a matriz atual mantem as
  source keys reconciliadas; nenhuma evidencia nova reabriu o mismatch
  `Battle Manual`/`Battle Generated`.
- `BV-071` permanecia aberto neste snapshot: o manifest tinha as contagens
  corretas, mas o summary principal ainda nao publicava
  `runtime_surface_manifest_gate_expected_counts` nem
  `runtime_surface_manifest_status`. Esse ponto foi superado pelo fechamento
  `20260619_235553` abaixo.
- `BV-072` permanece aberto: as listas `strategy_*` sao por strategy audit, nao
  elegibilidade global pos-gates; os campos globais seguem `null`.
- `BV-075` permanece aberto: a provenance por seed existe em artifacts, mas o
  `summary.json` segue sem `learned_deck_opponents`,
  `opponent_deck_provenance` e `learned_opponent_source_counts`.
- Nenhum PostgreSQL write, swap, commit, push ou mudanca de runtime foi feito por
  este recheck; foi uma reconciliacao documental read-only contra artifacts
  vivos.

## Passo de auditoria - fechamento BV-071 2026-06-19T23:55Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_235553/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_235553/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_235553/test_battle_runtime_surface_manifest.log`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_235553_runtime_surface_closure_recheck_20260619_205915.md`

Evidencia:

- `runtime_surface_manifest_total_files=108`
- `runtime_surface_manifest_category_counts={"core runtime":31,"focused evidence/promotion":4,"learned-deck source":14,"optimizer/scorecard":15,"recurring audit gate":24,"renderer":4,"review queue":1,"rule registry/sync":15}`
- `runtime_surface_manifest_automation_coverage_counts={"covered_by_recurring_run":29,"imported_by_core_runtime":6,"outside_recurring_run":73}`
- `runtime_surface_manifest_gate_expected_counts={"core_runtime_import_regression":6,"recurring_audit_required":29,"targeted_manual_gate_required_before_change":31,"targeted_test_required_before_change":42}`
- `runtime_surface_manifest_status=runtime_surface_manifest_ready`
- `test_battle_runtime_surface_manifest.py` agora fixa `EXPECTED_TOTAL_FILES=108`, `EXPECTED_CATEGORY_COUNTS`, `EXPECTED_AUTOMATION_COVERAGE_COUNTS`, `EXPECTED_GATE_EXPECTED_COUNTS` e `REQUIRED_HIGH_SIGNAL_PATHS`.
- `test_battle_runtime_surface_manifest.log` registra `PASS test_manifest_classifies_current_battle_surface`.

Resultado: `BV-071` removido do quadro aberto. O denominador do manifest deixou
de ser apenas `>=98`, e o summary principal agora publica status e contagens de
gate esperadas.

## Passo de auditoria - BV-074 latest optimizer recheck 2026-06-19T23:58Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_235553/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_235553/runtime_surface_manifest.json`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_235553_optimizer_surface_gate_coverage_recheck_20260619_210709.md`

Evidencia:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `runtime_surface_manifest_status=runtime_surface_manifest_ready`
- O manifest atual lista `15` arquivos `optimizer/scorecard`, todos
  `outside_recurring_run`.
- `master_optimizer_common.py` publica helpers de gate para Markdown e CLI com
  `battle_replay_final_status`, `mandatory_gate_divergences`, confidence split e
  `battle_gate_weight`.
- O gate esta ligado em `master_optimizer_baseline.py`,
  `master_optimizer_quality_gate.py`, `master_optimizer_confirmation.py`,
  `master_optimizer_handoff.py` e `slot_optimizer.py`.
- A busca estatica nao encontrou `battle_replay_final_status`/
  `mandatory_gate_divergences` em `master_optimizer_apply.py`,
  `master_optimizer_loop.py`, `master_optimizer_post_apply_gate.py`,
  `master_optimizer_product_handoff.py`, `master_optimizer_rollback.py` e
  `universal_optimizer.py`.
- Esses arquivos ainda produzem saidas operacionais de apply/preflight/
  post-apply/product handoff/rollback/WR/top results.

Resultado: `BV-074` permanece aberto. A correcao precisa propagar
`battle_gate_report_lines(...)` ou `battle_gate_cli_lines(...)` para toda saida
optimizer/scorecard operacional, ou marcar explicitamente qualquer script
legacy como deprecated/blocked para handoff sem gate.

## Passo de auditoria - fechamento BV-072 2026-06-20T00:07Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_000720/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_000720/test_battle_decision_strategy_auditor.log`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_000720_global_learning_eligibility_recheck_20260619_211055.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_000720_global_learning_eligibility_closure_20260619_211103.md`

Evidencia:

- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `strategy_learning_confidence_counts={"high_confidence_replay":12,"low_confidence_replay":4}`
- `global_learning_eligibility_policy=requires_high_confidence_strategy_seed_and_all_mandatory_gates_pass`
- `global_learning_eligible_seeds=["63210007","63210009","63210010","63210011","63210012","63210013","63210014","63210015","63210016","63210018","63210019","63210022"]`
- `global_not_learning_eligible_seeds=["63210008","63210017","63210020","63210021"]`
- `global_learning_eligibility_reasons` esta presente para todas as seeds; as
  seeds low-confidence trazem `strategy_audit:low_confidence_replay`.
- O wrapper calcula `battle_replay_final_status` e `mandatory_gate_divergences`
  antes de chamar `compute_global_learning_eligibility(...)`.
- `compute_global_learning_eligibility(...)` bloqueia aprendizado quando o
  status final nao e `trusted_for_strategy_learning`, incorpora divergencias de
  gate e inclui blockers/action/decision/forensic nas razoes por seed.
- O log oficial do run registra PASS para os testes
  `test_global_learning_eligibility_blocks_high_strategy_seed_when_other_gates_review_required`
  e
  `test_global_learning_eligibility_allows_clean_high_seed_and_excludes_low_confidence_seed`.

Resultado: `BV-072` removido do quadro aberto. A elegibilidade global de
aprendizado deixou de ser inferida por campos `strategy_*` e passou a ser campo
primario pos-gates no `summary.json`.

## Passo de auditoria - BV-075 latest learned provenance recheck 2026-06-20T00:07Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_000720/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_000720/seed_*/deck_provenance.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_000720_learned_deck_opponent_provenance_recheck_20260619_211603.md`

Evidencia:

- `summary.json` nao contem as chaves `learned_deck_opponents`,
  `opponent_deck_provenance` nem `learned_opponent_source_counts`.
- Os arquivos `deck_provenance.json` por seed contem `64` linhas de deck:
  `16` Lorehold e `48` learned opponents.
- Ha `12` `source_ref` learned unicos, todos com `source_system=pg_meta_decks`,
  `source_card_count=100`, `battle_card_count=99`,
  `metrics_basis=runtime_derived_from_resolved_built_deck`,
  `cached_metadata_used_for_metrics=false` e `blocker_domain=none`.
- Nenhum learned row tem `construction_report` ou `deck_coherence_report`.
- `battle_replay_v10_3.py` grava learned provenance por seed com
  `source_kind=learned_decks`, `source_ref`, `source_system`,
  `source_card_count`, `battle_card_count`, metrics e blocker domain.
- O wrapper recorrente le `deck_provenance.json`, agrega
  `deck_source_blocker_domains` e campos do Lorehold, mas nao agrega lista de
  learned opponents para o `summary.json`.

Resultado: `BV-075` permanece aberto. A provenance existe no nivel por seed,
mas o resultado principal ainda nao expõe o inventario learned-opponent que um
consumidor downstream precisa para diferenciar gate da engine de gate da fonte
do deck.

## Passo de auditoria - BV-075 source key stability 2026-06-19T21:23Z

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_000720/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_000720/seed_*/deck_provenance.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_meta_decks_to_hermes.py`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_000720_learned_deck_source_key_stability_audit_20260619_212318.md`

Evidencia:

- `learned_decks.id` no Hermes SQLite e `INTEGER PRIMARY KEY AUTOINCREMENT`.
- `sync_pg_meta_decks_to_hermes.py` usa `source="pg_meta_decks"` e
  `source_url="pg:meta_decks:<uuid>"`, com upsert por `(source, source_url)`.
- `battle_analyst_v9.py` passa `learned_deck_id=row["id"]` para o perfil de
  oponente, e `battle_replay_v10_3.py` renderiza isso como
  `source_ref=learned_deck:<id>`.
- Consulta read-only ao SQLite local mostrou que os `12` refs learned do latest
  possuem `source_url=pg:meta_decks:<uuid>`, mas esse campo nao aparece no
  `deck_provenance.json` nem no `summary.json`.

Resultado: `BV-075` permanece aberto com criterio mais preciso: o agregado
principal precisa incluir tanto a chave local `source_ref=learned_deck:<sqlite_id>`
quanto a chave estavel `source_url=pg:meta_decks:<uuid>` ou equivalente
backend-owned.

## Passo de auditoria - latest 002230 forensic blocker e learned delta 2026-06-19T21:32-03:00

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_002230/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_002230/seed_63210031/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_002230/seed_63210031/forensic_audit.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_002230/seed_63210031/replay.events.jsonl`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_002230_forensic_blocker_learned_provenance_delta_20260619_2132.md`

Evidencia do latest:

- `timestamp_utc=2026-06-20T00:22:30Z`.
- `battle_replay_final_status=blocked`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- `mandatory_gate_statuses.forensic_audit.status=blocked`.
- `mandatory_gate_statuses.forensic_audit.blocking_seeds=["63210031"]`.
- `forensic_rule_findings=2`, `forensic_turn_findings=0`.
- `forensic_severity_counts={"high":1,"medium":1}`.
- `seeds_with_high_or_critical_forensic_findings=["63210031"]`.
- `action_findings=0`, `seeds_with_high_or_critical_action_findings=[]` e
  `seeds_with_strategy_blockers=[]`.
- `global_learning_eligible_seeds=[]`; todas as `16` seeds entraram em
  `global_not_learning_eligible_seeds`.

Resultado para `BV-067`:

- `BV-067` voltou ao quadro aberto. A seed `63210031` executou
  `Aura of Silence` turn `10`, `precombat_main`, como
  `rule_source=functional_tags_json`, `rule_review_status=heuristic`,
  `rule_confidence=0.35`, `effect=remove_permanent` e alvo
  `Esper Sentinel`.
- O forensic emitiu finding `medium` no `spell_cast` e `high` no
  `spell_resolved`; o high bloqueia o gate.
- O problema e da mesma classe raiz ja rastreada em `BV-067`: gameplay
  executado por fallback heuristico `functional_tags_json` sem lineage aceita
  em vez de regra battle verified/active ou waiver runtime explicito.

Resultado para `BV-075`:

- O latest `20260620_002230` melhorou o agregado: `learned_deck_opponents`,
  `opponent_deck_provenance` e `learned_opponent_source_counts` agora existem
  no `summary.json`.
- O agregado lista `48` aparicoes e `12` learned opponents unicos, com
  `source_counts={"pg_meta_decks":48}` e waivers explicitos de
  construction/coherence ausentes.
- `BV-075` permanece aberto em escopo menor: as rows learned ainda nao
  publicam `source_url`; amostra validada: `source_ref=learned_deck:104`,
  `source_system=pg_meta_decks`, `source_row_id=104`, `source_url=null`.
  O `source_url=pg:meta_decks:<uuid>` existe no cache Hermes, mas ainda nao
  aparece no resultado principal.

## Checklist para proximas validacoes battle

1. Sempre comparar `replay.txt` contra `replay.events.jsonl`.
2. Para cada `spell_resolved`, confirmar se houve `cast` ou trigger/ability
   correspondente.
3. Para cada `counter`, exigir alvo, stack object, janela de prioridade e
   resultado.
4. Para cada cast com custo, exigir fonte de mana, custo travado e pagamento.
5. Para cada mudanca de vida, exigir causa.
6. Para cada fim de turno, verificar se o board textual permite auditar estado.
7. Nao aceitar `usable_for_strategy_learning` como prova de que o log humano esta
   completo.
8. Quando houver divergencia entre texto e JSONL, o JSONL e a fonte primaria, mas
   o texto deve ser corrigido para nao induzir decisao errada.
9. Para mulligan, `forced_keep_after_mulligan_cap` com `mana_screw`,
   `too_few_lands` ou score negativo relevante deve virar finding ou justificativa
   auditavel explicita.
10. Rodar `battle_effect_coverage_audit.py --report` antes de dizer que os
    templates battle estao completos para o corpus alvo.
11. Conferir se o `summary.json` principal inclui coverage de templates, nao
    apenas action/strategy findings.
12. Separar contagem de regras existentes de contagem de regras runtime-safe.
13. Para cada `unknown_card`, classificar familia de template antes de decidir
    implementacao ou waiver.
14. Conferir se a fila de review infere uma familia util; quando nao inferir,
    registrar como lacuna de triagem, nao apenas lacuna de executor.
15. Rodar ou considerar `battle_forensic_audit.py` quando o objetivo for
    confiar em efeitos de carta, nao apenas em formato de turn/decision trace.
16. Quando auditores divergirem, registrar a divergencia como finding proprio e
    nao escolher o resultado mais conveniente.
17. Tratar documentos de status por data/corpus/gate; nao usar conclusao
    historica como estado atual sem rerun.
18. Depois de qualquer mudanca de instrumentacao, reexecutar a mesma seed antiga
    e comparar se a falha foi fechada ou apenas migrou para outro caminho.
19. Validar que eventos tecnicos novos, como `cost_paid`, nao quebrem suites que
    esperam sequencia exata, ou formalizar esses eventos como parte do contrato.
20. Para trigger/landfall, confirmar se ha fonte real antes de aceitar
    `trigger_put_on_stack` como evento de stack.
21. Sempre registrar se a cobertura reportada e runtime-safe ou inclui
    review-only/needs-review.
22. Quando um teste volta a PASS depois de falhar, manter a falha historica no
    register ate existir criterio de fechamento e fixture cobrindo o contrato.
23. Para qualquer replay produzido a partir de learned deck, conferir se curva,
    lands e CMC foram calculados da lista resolvida de cartas, nao de metadata
    stale.
24. Separar blocker de deck source/legalidade de blocker de engine battle.
25. Quando a automacao mudar, reclassificar achados historicos como
    `historico`, `parcialmente fechado` ou `ainda atual`, sem apagar a evidencia.
26. Nao tratar `hard_modelled/verified` em matriz antiga como prova de que todos
    os caminhos de cast/resolution da carta estao seguros.
27. Forensic limpo deve ser lido junto com cobertura de `card_id`,
    `semantic_hash` e `rule_logical_key`.
28. Trigger no action critic precisa de fonte/causa/stack do mesmo modo que
    counter precisa de alvo/stack object.
29. Antes de afirmar que os templates estao completos, cruzar os `unknown_cards`
    atuais contra os `supports_*_template` reais de focused evidence.
30. Suite verde de `manaloom_review_queue_consumers_test.py` prova os templates
    fixtureados; nao prova que o backlog atual de unknowns tem familia/template.
31. Para contrato de eventos, validar dois denominadores separados: eventos
    observados no latest e eventos emitíveis extraidos estaticamente de
    `emit_replay_event(...)`.
32. Para qualquer evento novo emitido pelo battle, exigir classificacao explicita:
    `action_audited`, `technical`, `renderer_only`, `forensic_card_event`,
    `strategy_signal` ou `ignored_with_reason`.
33. Comparar `events` total do JSONL com `total_actions` do action critic; se
    houver diferenca, registrar quais eventos ficaram fora do critic default.
34. Para `replacement_applied`, exigir causa/fonte ou evento causal auditavel,
    alem de zonas origem/destino e objeto afetado.
35. Antes de usar qualquer doc battle anterior a `2026-06-19` como verdade
    atual, verificar se ele aponta para este register ou reexecutar os gates
    relevantes.
36. Quando uma suite ou automacao passar, registrar explicitamente qual
    superficie ela cobre e quais scripts/caminhos battle ficam fora dela.
37. Para cada `effect_json.effect`, exigir mapa para handler runtime, eventos
    emitidos, action critic, forensic, focused fixture, modo
    runtime-safe/review-only/needs-review e contagem no latest.
38. Para cada tipo de `decision_trace`, exigir campos obrigatorios, latest
    count, auditor dono, status no `summary.json` e fixture/gate esperado.
39. Cruzar `unknown_cards` atuais contra os `supports_*_template` reais e
    registrar `unknowns_without_template` explicitamente.
40. Suite verde de review/focused evidence so pode ser usada como prova para
    familias cobertas por fixture; backlog real precisa de template ou waiver.
41. Para `decision_trace`, separar `generic_invariant_coverage` de contrato
    especifico por tipo de decisao.
42. `strategy_findings=0` so prova as regras estrategicas existentes; nao prova
    tipos sem branch/categoria como `utility_artifact_activation`,
    `lorehold_upkeep_rummage` e `saga_chapter_resolution`.
43. Para action critic, sempre comparar `events` total com `total_actions` e
    registrar eventos fora de `ACTION_EVENTS + TECHNICAL_EVENTS`.
44. Tratar `--include-technical` como ledger amplo ate existir classificacao
    explicita por tipo de evento.
45. Ao usar doc battle marcado como `current`, confirmar se ele aponta para este
    register; se nao apontar, tratar como contexto ate cruzar com o latest.
46. Nao aceitar `BATTLE_SYSTEM_LOGIC.md` como prova de prontidao atual sem
    checar `battle_replay_final_status` e `mandatory_gate_divergences`.
47. Para cada `unknown_card`, manter linha propria com familia, focused template,
    fixture, waiver ou dono; nao agrupar tudo como `unknown` generico.
48. Para cada `effect_json.effect`, separar `runtime_literal_detected` de
    contrato completo; efeitos amplos precisam de subcontrato ou waiver aceito.
49. Antes de usar WR, baseline, confirmation ou handoff como evidencia final,
    cruzar com `battle_replay_final_status` e `mandatory_gate_divergences`, ou
    declarar waiver explicito de corpus/gate.
50. Para docs canonicos ou indices current, tratar qualquer status embutido com
    timestamp como snapshot historico; a decisao atual sempre vem deste
    register, do latest `summary.json` e da gate matrix.
51. Ao perguntar se "todos os templates de acoes de cartas estao criados",
    separar `focused_template_dispatch` de `effect_coverage_residual`; o
    primeiro prova backlog focado, o segundo mostra waivers/denominadores ainda
    nao equivalentes a runtime card-specific.
52. Para decision trace, separar `decision_trace_taxonomy_ready` de
    `all_decision_types_observed`; sempre listar `static_uncovered_types` e
    `accepted_waivers` antes de usar o trace para aprendizado.
53. Para templates/efeitos, nunca ler `review_only_rule_names=0` isoladamente;
    cruzar com `needs_review_rule_names`, `non_runtime_safe_rule_names`,
    `runtime_safe_rule_names` e `review_status_counts`.
54. Para forensic lineage, nunca ler `forensic_lineage_status=complete`
    isoladamente; cruzar com `card_id_present/missing`,
    `semantic_hash_present/missing`, `rule_logical_key_present/missing` e
    waiver reasons.
55. Para confianca estrategica, nunca ler
    `battle_replay_final_status=trusted_for_strategy_learning` como se todas as
    seeds fossem high-confidence; cruzar com
    `strategy_high_confidence_learning_seeds`, `strategy_low_confidence_seeds`
    e `strategy_learning_confidence_counts`.
56. Para event contract, nunca ler `static_event_types_total` como a superficie
    completa isolada; cruzar com `all_event_types_total`,
    `observed_not_static_literal`, unclassified totals, missing required fields
    e fixture-depth waiver.
57. Para `replay.txt`, separar texto humano de ledger de aprendizagem; sempre
    cruzar `decision_audit_human_replay_complete`,
    `decision_audit_rules_interaction_trusted`, total de linhas do texto e total
    de eventos JSONL antes de usar o log como evidencia.
58. Para cast/ativacao renderizados no texto, procurar placeholders `CMC=?` e
    `life=?->`; se aparecerem, localizar o evento fonte e registrar se falta
    dado no JSONL ou se e apenas perda do renderer.
59. Para `spell_countered`, validar quatro campos juntos: alvo,
    `stack_object`, resultado e janela (`phase` ou `priority_window`). Nao
    inferir legalidade temporal apenas por proximidade de linhas quando o
    objetivo for provar regras/stack.
60. Para removals targeted, exigir alvo declarado no cast-like event
    (`cast_announced`, `spell_cast`, `miracle_cast`, `end_step_instant`) e no
    `spell_resolved`; `removal_resolved` sozinho prova resolucao, nao target
    declaration.
61. Para `spell_resolved`, exigir provenance propria de resolucao: fase/janela,
    stack object/depth, source zone, cast context, locked cost, target/result
    quando aplicavel e transicao/link de zona; nao inferir esses campos apenas
    por proximidade de eventos.
62. Para qualquer evento com `rule_source=functional_tags_json`, tratar como
    heuristic/non-learning ate existir regra `card_battle_rules` verified/active,
    waiver formal ou identidade/regra estavel explicita no evento.
63. Para templates de acao, sempre separar `source == unknown` de
    `effect == unknown`; `unknown_template_backlog_cards=0` nao fecha
    `effect_totals.unknown` sem lista/waiver dos cards restantes.
64. Para effect coverage humano, comparar `effect_coverage.md` contra
    `effect_coverage.json.deck_totals/source_totals`; colunas de fonte zeradas
    no Markdown nao provam ausencia de cobertura se as chaves do JSON mudaram.
65. Para event contract estatico, confirmar quais arquivos emissores foram
    escaneados; `event_contract_static_ready` com `observed_not_static_literal`
    nao prova inventario completo da superficie de eventos.
66. Para runtime surface manifest, nao aceitar teste com limite historico amplo
    como prova de superficie completa; comparar total, categorias, gates,
    coverage e arquivos high-signal contra snapshot atual ou waiver.
67. Para aprendizado, nunca usar `strategy_high_confidence_learning_seeds` como
    lista global sem cruzar `battle_replay_final_status`,
    `mandatory_gate_divergences`, action blockers e forensic blockers.
68. Para afirmar que um run foi testado, nao depender apenas da existencia de
    `summary.json`; confirmar matriz de testes, exit codes e logs por teste,
    especialmente quando algum `test_*.log` estiver vazio por stdout/stderr.
69. Para templates de acao, quando `focused_template_dispatch_ready` estiver
    verde, ainda comparar `effect_coverage.effect_totals.unknown` e os
    `focused_template_cards` com `effect=unknown`; o artifact focado pode ter
    `fixture_scope` sem isso estar reconciliado no coverage principal.
70. Para estrategia/WR, quando o latest for `trusted_for_strategy_learning`,
    reportar tambem `strategy_learning_confidence_counts`,
    `strategy_high_confidence_learning_seeds` e `strategy_low_confidence_seeds`;
    seeds low-confidence com `high_confidence_learning_weight=0.0` nao podem
    virar amostra high-confidence por causa do status global.
71. Ao revalidar achado aberto contra um latest mais novo, atualizar a linha do
    BV com o estado corrente e remover da lista aberta qualquer item que tenha
    criterio de fechamento comprovado; nao deixar o register carregar falha que
    ja foi fechada por artefato atual.
72. Para optimizer/scorecard, nao basta verificar baseline, quality gate,
    confirmation, handoff e slot optimizer; conferir tambem apply, post-apply,
    product handoff, rollback, loop/preflight e scripts legacy antes de dizer
    que todo o ciclo carrega o `Battle Replay Gate`.
73. Para oponentes vindos de learned deck, nunca usar `source_ref` isolado como
    chave; reportar `source_system`, nome/row id quando houver,
    `source_card_count`, `battle_card_count`, status de construction/coherence e
    separar blocker de source deck de blocker da engine battle.
74. Ao usar `latest/summary.json`, sempre reportar `run_dir`,
    `seeds_requested`, `seeds_completed` e `start_seed`; se `seeds_requested < 16`,
    tratar o resultado como recheck focado/manual, nao como readiness recorrente
    de 16 seeds.
75. Para denominadores action/event no `summary.json`, separar soma por seed de
    contagem global distinta: `action_event_types_total` atual e seed-sum, nao
    substitui `event_contract_static_observed_event_types_total`.
76. Para `research_review`, quando uma categoria ficar
    `blocked_or_needs_review`, exigir samples dos findings por seed/decision;
    exemplos neutros/primeira ocorrencia nao podem ser lidos como amostra do
    bloqueio.
77. Para `decision_trace`, separar tipos `accepted_field_contract_waiver`
    observados de tipos strategy/research-specific; publicar contadores por tipo
    e `decision_learning_grade` antes de usar todas as decisoes como evidencia
    de aprendizado.
78. Para forensic lineage, nao aceitar `forensic_audit.status=pass` se qualquer
    `forensic_*_missing_unaccepted` for maior que zero; o gate final precisa
    bloquear/requerer review mesmo quando `forensic_rule_findings=0`.

## Passo de auditoria - BV-082 learned source coherence 2026-06-19T23:22-03:00

Artefatos lidos:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/seed_63210148/deck_provenance.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_005400.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_005400.md`

Estado confirmado do latest:

- `opponent_deck_provenance.status=learned_opponent_provenance_present_with_shape_waiver`
- `learned_opponent_unique_count=11`
- `learned_opponent_appearance_count=48`
- `learned_opponent_source_counts={"pg_meta_decks":48}`
- `source_url_missing_count=0`
- `construction_report_missing_count=48`
- `deck_coherence_report_missing_count=48`
- `learned_deck_source_lookup_status=loaded`
- `learned_deck_source_lookup_rows=120`

Estado confirmado do report de coerencia:

- `active_learned_decks=60`
- `severity_counts={"high":173,"medium":21}`
- `by_source.pg_meta_decks.active=52`
- `by_source.pg_meta_decks.high=158`
- `by_source.pg_meta_decks.medium=18`

Cruzamento feito sem mutacao:

- Os `11` `source_url=pg:meta_decks:<uuid>` publicados no summary do battle
  foram procurados no JSON do report de coerencia por `row_id`.
- Resultado: `0/11` opponents do latest `20260620_014808` casaram por
  `source_url`/`row_id` no report `learned_deck_coherence_audit_20260620_005400`.
- Busca textual direta pelos `11` UUIDs do summary dentro do JSON de coherence
  tambem nao retornou matches.
- Amostra do `deck_provenance.json` da seed `63210148`: os oponentes
  `Thrasios, Triton Hero #58`, `Kraum, Ludevic's Opus #83` e
  `Rograkh, Son of Rohgahh #62` carregam `source_kind=learned_decks`,
  `source_system=pg_meta_decks`, `source_ref`, `source_card_count`,
  `battle_card_count` e metricas runtime-derived, mas nao carregam
  `source_url`, `construction_report` nem `deck_coherence_report`.
- Colisao nominal validada: no summary do battle `source_ref=learned_deck:105`
  e `commander=Etali, Primal Conqueror`; no report de coherence
  `source_ref=learned_deck:105` e `commander_name=Aang, at the Crossroads`.
  Outro exemplo: `learned_deck:104` e Kinnan no summary, mas Ral no coherence.

Leitura: `BV-082` segue aberto, agora com escopo mais preciso. O latest publica
provenance agregada suficiente para saber que houve `48` aparicoes learned e
`0` `source_url` ausentes no agregado, mas os artifacts por seed nao carregam a
mesma chave estavel; alem disso o report de coherence atual nao e cruzavel com
os `11` oponentes usados no replay por `source_url`/`row_id`. Portanto o status
final do battle nao deve ser lido como validacao de source-coherence dos
oponentes learned.

Tarefa para o chat "Ajustar battle":

- Adicionar `source_url`/PG UUID ou backend id estavel aos
  `deck_provenance.json` por seed para cada learned opponent.
- Fazer o report de coherence exportar a mesma chave estavel dos oponentes que
  o battle usa, ou o wrapper anexar um `source_coherence_status` por opponent
  a partir de uma fonte cruzavel.
- Namespacear `source_ref` local Hermes (`learned_deck:<sqlite_id>`) versus
  `source_ref`/id do corpus learned para evitar joins falsos.
- Manter `construction_report_missing_count` e `deck_coherence_report_missing_count`
  como waiver explicito de source deck, separado do final status de engine.

## Passo de auditoria - BV-087 unknown effect contract 2026-06-19T23:37-03:00

Artefatos e codigo lidos:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/effect_coverage.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/unknown_template_backlog.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/unknown_template_backlog.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py`

Estado confirmado no summary/effect coverage:

- `effect_coverage_unknowns=0`
- `effect_coverage_effect_totals_unknown=41`
- `effect_coverage_unknown_effect_cards` lista `34` cards.
- `focused_template_ready_unknown_effect_count=28`
- `needs_review_unknown_effect_count=5`
- `unknown_template_backlog_cards=0`
- `unknown_template_unknowns_without_plan_or_waiver=[]`
- `unknown_template_without_focused_template_match=0`
- `unknown_template_without_reviewed_family=0`

Estado confirmado no unknown template backlog:

- `status=focused_template_backlog_ready`
- `items=[]`
- `source_unknown_cards=0`
- `effect_unknown_cards=34`
- `effect_unknown_source_counts={"battle_rule_curated":1,"battle_rule_needs_review_generated":5,"focused_template_ready":28}`
- `effect_unknown_status_counts={"focused_template_ready":28,"needs_review":5,"waived_curated_unknown_effect":1}`
- `without_plan_or_waiver=0`
- `without_focused_template_match=0`
- `without_reviewed_family=0`

Leitura do codigo:

- `battle_unknown_template_backlog_audit.py` conta
  `effect_unknown_cards = coverage.get("unknown_effect_cards") or []`, mas cria
  `items` apenas de `coverage.get("unknown_cards")`.
- `test_backlog_separates_source_unknown_from_effect_unknown_denominator`
  valida que o denominador `effect_unknown_cards` e contado separadamente quando
  `unknown_cards=[]`, mas nao exige contrato por carta para esse denominador.

Leitura: esta e uma lacuna de contrato/observabilidade, nao uma prova de erro de
simulacao. O backlog atual parece ser source-unknown-only; porem o report tambem
mostra `Effect-unknown cards: 34` e status `focused_template_backlog_ready` com
tabela vazia, o que pode levar consumidor a concluir que todo `effect=unknown`
ja esta planejado/waived. O fechamento correto e separar explicitamente
`source_unknown_template_backlog_status` de `effect_unknown_template_contract_status`
ou gerar manifest por carta para os `unknown_effect_cards`.

Tarefa para o chat "Ajustar battle":

- Renomear ou duplicar o status do backlog para deixar claro que
  `focused_template_backlog_ready` cobre source-unknown, nao necessariamente
  `effect=unknown`.
- Adicionar `effect_unknown_items`/contrato por carta no JSON/Markdown, com
  `status`, `owner`, `focused_template_matches`, `reviewed_family`,
  `plan_status` e waiver.
- Exigir teste em que `unknown_cards=[]` e `unknown_effect_cards>0`; o report
  deve publicar contadores/contrato effect-unknown ou declarar escopo
  source-only no nome dos campos.

## Passo de auditoria - BV-083 action denominator recheck 2026-06-19T23:10-03:00

Artefatos lidos:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/seed_*/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/event_contract_static.json`

Estado confirmado do latest:

- `mandatory_gate_statuses.action_critic.status=pass`
- `mandatory_gate_statuses.event_contract_static.status=pass`
- `action_findings=0`
- `action_verdict_counts={"ok":5964}`
- `action_events_total=14404`
- `action_event_contract_class_counts={"action_audited":5964,"ignored_with_reason":314,"renderer_only":36,"strategy_signal":232,"technical":7858}`
- `action_events_unclassified=0`
- `action_event_types_unclassified={}`
- `event_contract_static_observed_event_types_total=50`
- `event_contract_static_observed_unclassified_total=0`
- `event_contract_static_observed_missing_required_fields=0`

Recomputacao direta dos `16` arquivos `seed_*/action_critic.json`:

- `sum_seed_events_total=14404`
- `sum_seed_event_types=534`
- `sum_seed_event_type_class_counts={"action_audited":310,"ignored_with_reason":37,"renderer_only":35,"strategy_signal":81,"technical":71}`
- `global_distinct_event_types_from_action_rows=50`
- `events_unclassified_sum=0`

Leitura: `BV-083` segue aberto somente como contrato de nomenclatura do
`summary.json`. O critic e o event contract passam no latest corrente, mas
`action_event_types_total=534` e `action_event_type_class_counts` continuam
sendo somas por seed; o denominador global distinto observado e `50`. Portanto,
`action_findings=0` significa que os `5964` eventos action-audited passaram e
que o ledger completo ficou classificado, nao que todos os `14404` eventos
receberam regra de action critic.

## Passo de auditoria - BV-084 research review recheck 2026-06-19T23:18-03:00

Artefatos e codigo lidos:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/research_review.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/research_review.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/seed_*/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/seed_*/replay.decision_trace.jsonl`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py`

Estado confirmado no latest:

- `research_statuses.mulligan=blocked_or_needs_review`
- `research_review.categories.mulligan.observed_decisions=132`
- `research_review.categories.mulligan.finding_count=6`
- `research_review.categories.mulligan.finding_codes={"forced_keep_after_bad_mulligan":6}`
- `research_review.json` nao publica `summary`, `finding_samples` nem `findings`.
- `research_review.json.examples.mulligan_decision` continua sendo a primeira
  decisao de mulligan observada: `seed_63210148/decision-000001`,
  `action=mulligan`, `forced_keep=false`, `reason=too_few_lands`.

Seis decisoes problemáticas confirmadas diretamente nos `strategy_audit.json` e
`replay.decision_trace.jsonl`:

- `63210149/decision-000010`: `Rograkh, Son of Rohgahh #62 (real)`,
  `forced_keep=true`, `mulligan_count=3`, `score=-7.0`,
  `reason=too_few_lands`, `risk_flags=["mana_screw","forced_keep_after_mulligan_cap"]`.
- `63210150/decision-000011`: `Thrasios, Triton Hero #58 (real)`,
  `forced_keep=true`, `mulligan_count=3`, `score=-10.0`,
  `reason=too_few_lands`, `risk_flags=["mana_screw","forced_keep_after_mulligan_cap"]`.
- `63210158/decision-000004`: `Lorehold`, `forced_keep=true`,
  `mulligan_count=3`, `score=-10.0`, `reason=too_few_lands`,
  `risk_flags=["mana_screw","forced_keep_after_mulligan_cap"]`.
- `63210160/decision-000008`: `Etali, Primal Conqueror #105 (real)`,
  `forced_keep=true`, `mulligan_count=3`, `score=-5.0`,
  `reason=no_castable_early_play_by_color`,
  `risk_flags=["no_early_game_plan","off_color_early_hand","forced_keep_after_mulligan_cap"]`.
- `63210161/decision-000007`: `The Emperor of Palamecia #42 (real)`,
  `forced_keep=true`, `mulligan_count=3`, `score=-7.0`,
  `reason=too_few_lands`, `risk_flags=["mana_screw","forced_keep_after_mulligan_cap"]`.
- `63210162/decision-000009`: `Kraum, Ludevic's Opus #83 (real)`,
  `forced_keep=true`, `mulligan_count=3`, `score=-3.0`,
  `reason=reactive_only_opener`,
  `risk_flags=["no_early_game_plan","reactive_only_opener","forced_keep_after_mulligan_cap"]`.

Leitura: `BV-084` permanece aberto, mas o escopo segue sendo observabilidade do
report agregado. O strategy audit por seed identifica exatamente os seis
findings e rebaixa essas seeds para `low_confidence_replay`; o aggregate
`research_review` mostra a categoria bloqueada, mas nao entrega as amostras que
permitiriam investigar o bloqueio sem abrir os artifacts por seed. Isto nao cria
mandatory-gate divergence porque `strategy_audit.status=pass` e as seeds low
confidence ja ficam fora da lista global de aprendizado pelo final status atual.

## Passo de auditoria - replay decision/human replay recheck 2026-06-19T23:10-03:00

Artefatos lidos:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/seed_*/replay_decision_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/seed_*/replay.txt`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/seed_*/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_014808/seed_*/replay.decision_trace.jsonl`
- `docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_replay_decision_auditor_scope.py`

Estado confirmado:

- `mandatory_gate_statuses.replay_decision_audit.status=pass`
- `decision_audit_status_scope=turn_and_decision_trace_invariants`
- `decision_audit_human_replay_complete=not_evaluated_by_replay_decision_auditor`
- `decision_audit_rules_interaction_trusted=not_evaluated_by_replay_decision_auditor`
- `decision_audit_decision_findings=0`
- `decision_audit_turn_findings=0`
- `decision_audit_severity_counts={"critical":0,"high":0,"medium":0,"low":0}`
- Todos os `16` `seed_*/replay_decision_audit.json` estao
  `status=turn_invariants_clean`.
- Soma dos arquivos atuais: `replay.txt=7630` linhas,
  `replay.events.jsonl=14404` linhas e `replay.decision_trace.jsonl=2263`
  linhas.
- Scan textual controlado nos `16` `replay.txt` encontrou `0` ocorrencias para
  `CMC=?`, `life=?`, `?->`, `undefined`, `null`, `TODO`, `UNKNOWN`,
  `unknown target`, `target=?`, `phase=?` ou `priority_window=?`.

Validacao executada:

- `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_replay_decision_auditor_scope.py` - PASS, `4` checks.

Leitura: nenhum novo BV aberto nesta fatia. O `replay_decision_audit` esta limpo
para invariantes de turno e decision trace no latest, e os placeholders humanos
procurados nao reapareceram. Ainda assim, por contrato, `replay.txt` continua
sendo projecao humana: o auditor declara explicitamente que nao prova
`human_replay_complete` nem `rules_interaction_trusted`.

## Pontos de implementacao sugeridos

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  - garantir causa explicita para mudancas de vida como shock land, dano,
    custo, trigger ou efeito.
  - emitir `life_before` e `life_after` em `utility_land_activated` sempre que
    `life_paid` existir, incluindo `Ancient Tomb` e `War Room`.
  - emitir `cmc` nos caminhos `commander_cast`, `miracle_cast` e
    `end_step_instant`, alinhando esses eventos com `spell_cast` e
    `creature_cast`.
  - propagar `phase` ou `priority_window` para `spell_countered` quando
    `use_counterspell(...)` for chamado a partir da priority loop.
  - escolher e persistir target de `remove_creature`, `remove_permanent` e
    `redirect_removal` antes/durante `begin_cast_context(...)`, usando
    `targets` do `CastingContext`, e fazer a resolucao apenas revalidar esse
    alvo declarado.
  - propagar `CastingContext` ou `StackItem` para `spell_resolved`, incluindo
    `phase`, `priority_window` quando existir, `stack_depth`, `stack_object`,
    `source_zone`, `cast_pipeline`, `locked_cost`, `targets`, `result` e
    transicao/link de zona.
  - bloquear ou rebaixar eventos action-audited vindos de `functional_tags_json`
    quando nao houver `card_id`, `semantic_hash` e `rule_logical_key`; para
    exploracao, marcar explicitamente como non-learning/heuristic.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
  - adicionar finding para spell/ability resolvida sem evento causal suficiente.
  - expor contagem de eventos auditados, tecnicos, ignorados e nao classificados.
  - diferenciar `include_technical` como modo ledger de cobertura especializada
    e emitir resumo de tipos sem classificacao especifica.
  - validar `replacement_applied` sem `source`, `reason` ou evento causal.
  - validar `spell_countered` sem `phase`/`priority_window`, ou registrar waiver
    formal quando a janela for intencionalmente inferida pelo item de stack.
  - validar cast-like removal/redirect sem target declarado antes da resolucao.
  - validar `spell_resolved` sem phase/priority, stack, source/destination,
    cast context, target/result aplicavel ou waiver formal.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py`
  - manter cobertura multi-source para `battle_analyst_v9.py`,
    `battle_sba_support.py` e `battle_replacement_support.py`, incluindo modulos
    de suporte que recebem `emit_replay_event` por injecao.
  - publicar tambem `emit_file:line` por evento no JSON, alem de
    `static_engine_sources`.
  - classificar `observed_not_static_literal` como review ou waiver explicito
    quando o evento observado nao estiver no inventario estatico.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py`
  - separar confianca de estrategia da completude do log humano.
  - adicionar branch especifico ou waiver explicito para tipos de decisao
    observados sem contrato estrategico: `utility_artifact_activation`,
    `lorehold_upkeep_rummage` e `saga_chapter_resolution`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_trace_taxonomy_audit.py`
  - publicar `accepted_field_contract_waiver_observed_rows` e contadores por
    tipo.
  - publicar `decision_learning_grade` por tipo, distinguindo
    `strategy_audited`, `research_specific`, `field_contract_only` e
    `not_observed`.
  - quando uma waiver depender de "parent engine choices", exigir
    `parent_decision_id`/`source_decision_id` ou marcar a linha como
    non-learning/needs-review ate existir link explicito.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py`
  - publicar `finding_samples` por categoria bloqueada, com seed,
    `decision_id`, codigo, severidade, detalhe, `chosen_option`, `reason` e
    `risk_flags`.
  - renomear ou documentar `examples` como primeira ocorrencia neutra quando
    nao for sample do finding que deixou a categoria em review.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py`
  - manter como gate de templates/efeitos, nao apenas report opcional.
  - continuar reduzindo `unknown_effect`, `heuristic_effect` e flags de
    trigger/cast permission/land utility no corpus alvo.
  - publicar contagem/lista de `effect == unknown` separada de
    `source == unknown`, incluindo focused-template-ready e needs-review.
  - renderizar `Deck Coverage` com chaves atuais (`battle_rule_curated`,
    `battle_rule_needs_review_generated`) ou colunas dinamicas derivadas de
    `deck_totals/source_totals`, evitando colunas historicas que zeram.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py`
  - renomear o status atual para source-unknown ou publicar status separado para
    `effect_unknown_cards`.
  - gerar contrato por carta para `unknown_effect_cards`, mesmo quando
    `unknown_cards=[]`, ou declarar no JSON/Markdown que o manifest e
    source-unknown-only.
  - publicar contadores por status (`focused_template_ready`, `needs_review`,
    `waived_curated_unknown_effect`) com plano/waiver ou dono de revisao.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`
  - expor cobertura de linhagem (`card_id`, `semantic_hash`,
    `rule_logical_key`) separada de ausencia de findings.
  - manter `functional_tags_json` como finding unaccepted quando virar acao de
    carta sem regra battle/waiver, e reportar lista de cards afetados no resumo.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
  - renderizar causa explicita para mudancas de vida fora de combate.
  - evitar placeholders silenciosos em campos usados para auditoria humana; se
    `life_before`, `life_after` ou `cmc` forem intencionalmente ausentes,
    renderizar a ausencia como contrato/waiver explicito.
  - incluir `phase` ou `priority_window` nas linhas `COUNTER` quando o evento
    `spell_countered` trouxer essa informacao.
  - incluir `phase`, stack object/depth, source/destination e result nas linhas
    `RESOLVE SPELL` quando o evento `spell_resolved` trouxer essa informacao.
  - incluir `source_url`/PG UUID ou backend id estavel nos `deck_provenance.json`
    por seed para oponentes `source_kind=learned_decks`.
  - incluir `construction_report` ou `deck_coherence_report` tambem para
    oponentes `source_kind=learned_decks`, com chave de origem inequivoca e
    namespace de `source_ref` que nao colida com outros artifacts.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  - manter o resumo de coverage no `summary.json`;
  - manter forensic e replay decision audit no `summary.json` principal;
  - expor contagem especifica de `needs_review` quando existir no coverage.
  - expor no `summary.json` contagem de eventos totais, eventos auditados pelo
    action critic default e tipos de eventos nao classificados.
  - incluir `event_types_unclassified` e `events_unclassified` no resultado
    principal antes de tratar `ok` como cobertura total.
  - expor contagem de `spell_resolved` sem provenance de fase/stack/zona/contexto
    no `summary.json` ou gate equivalente.
  - expor `functional_tags_json_event_count`, cards afetados e se esses eventos
    sao learning-grade, waived ou bloqueadores forensic.
  - expor `effect_totals_unknown`, `focused_template_ready_unknown_effect_cards`
    e `needs_review_unknown_effect_cards` no `summary.json`.
  - expor separadamente `source_unknown_template_backlog_status` e
    `effect_unknown_template_contract_status`, ou documentar que o status atual
    nao cobre `effect=unknown`.
  - publicar elegibilidade global de aprendizado apos todos os mandatory gates,
    separada da confidence especifica do strategy audit.
  - remover/rotular seeds bloqueadas por action/forensic das listas globais de
    aprendizado, com motivo por seed.
  - redirecionar stdout e stderr dos testes para os respectivos `test_*.log`, ou
    registrar explicitamente no `summary.json` onde cada canal foi capturado.
  - publicar `test_results` no `summary.json` com comando, status, exit code,
    log path, stdout/stderr bytes e duracao aproximada, incluindo o passo
    `py_compile`.
  - renomear ou duplicar os denominadores de tipo de evento para diferenciar
    `action_event_types_seed_sum` de `action_event_types_distinct_total`, e
    ajustar `summary.md` para nao apresentar soma por seed como superficie
    global distinta.
  - publicar resumo de oponentes learned no `summary.json`, por
    `source_system + source_ref + name`, com contagem de aparicoes,
    `source_card_count`, `battle_card_count`, metric basis, cached flag, blocker
    domain e status de construction/coherence.
  - publicar tambem uma chave estavel comum ao report de coherence
    (`source_url`, PG UUID ou backend id) e explicitar quando `source_ref` for
    apenas id local Hermes.
  - publicar `run_profile`/`run_scope`/`invocation_kind` no `summary.json` e no
    `summary.md`, distinguindo run recorrente de 16 seeds de recheck manual
    focado.
  - considerar symlinks separados como `latest_full` e `latest_focused`, ou
    documentar/testar que consumidores sempre validam `seeds_requested`,
    `seeds_completed`, `start_seed` e `run_dir` antes de inferir readiness.
- `docs/hermes-analysis/BATTLE_DOCUMENTATION_INDEX.md` ou equivalente
  - criar indice/status de docs battle com `current`, `historical`,
    `superseded` ou `background`, apontando para este register como fonte viva.
  - manter o indice sincronizado com taxonomia, gate matrix, event contract,
    runtime surface manifest e coverage reports atuais; se nao for exaustivo,
    declarar que o register prevalece.
- `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md`
  - adicionar ponte obrigatoria para este register, `BATTLE_REPLAY_GATE_MATRIX.md`
    e latest `summary.json` antes de qualquer conclusao de prontidao.
- `docs/hermes-analysis/BATTLE_RUNTIME_SURFACE_MANIFEST.md` ou equivalente
  - classificar scripts/testes battle por categoria e gate esperado, para evitar
    interpretar a automacao recorrente como cobertura total do repositorio.
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`
  - fixar o denominador atual do manifest ou usar snapshot versionado.
  - validar contagens exatas por categoria, `automation_coverage` e
    `gate_expected`.
  - validar presenca nominal de arquivos high-signal da engine, registry,
    learned-deck, optimizer, focused evidence, review queue e renderer.
- `docs/hermes-analysis/BATTLE_EFFECT_TEMPLATE_CONTRACT.md` ou equivalente
  - criar o contrato efeito/template cruzando runtime, critic, forensic,
    focused evidence, modo runtime-safe/review-only/needs-review e coverage
    latest.
  - incluir colunas para `unknowns_with_focused_template`,
    `unknowns_without_family`, `unknowns_without_template` e waiver/plano por
    card do backlog atual.
  - persistir manifesto por carta para os `29` unknowns atuais, com familias
    revisadas e status de focused evidence/waiver.
  - publicar por efeito `contract_status`, `forensic_supported`,
    `focused_template_functions`, `coverage_flags` e waiver/subcontrato aceito.
  - diferenciar explicitamente `unknown source backlog` de `unknown effect
    family`, com fechamento proprio para cada denominador.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`
  - incluir `worldfire_reset` em suporte forensic ou emitir waiver explicito
    quando o efeito for validado por outro gate.
- `docs/hermes-analysis/BATTLE_DECISION_TRACE_TAXONOMY.md` ou equivalente
  - declarar os tipos de decision trace, campos obrigatorios por tipo, auditor
    responsavel, fixture/gate esperado e status agregado no summary.
  - incluir contadores `decision_trace_kinds_without_specific_contract` e
    `decision_trace_observed_without_specific_contract`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py`
  - validar consumidores que leem `needs_review` para nao confundir cobertura
    ampla com execucao confiavel.
  - manter API explicita para runtime-safe vs review-only e exigir que reports
    mostrem qual modo foi usado.
- `server/bin/manaloom_battle_rule_review_queue.py`
  - ampliar inferencia textual para familias hoje invisiveis: tax/static,
    alternative/additional cost, manifest/cloak, tap/untap, bounce, convoke,
    split second e mass sacrifice.
  - adicionar cobertura de backlog real para cards atuais como `Hidden Strings`,
    `Submerge`, `Stoke the Flames`, `Sudden Shock`, `Tragic Arrogance`,
    `Cryptic Coat` e `God-Pharaoh's Statue`.
- `server/bin/manaloom_battle_rule_focused_evidence.py`
  - manter templates estreitos; adicionar evidence somente por familia segura,
    nunca por `unknown` generico.
  - registrar explicitamente quando uma familia inferida ainda nao tem
    `supports_*_template` seguro, para diferenciar triagem de execucao.
  - incluir candidatos atuais do gate forensic (`Mardu Devotee`,
    `Orcish Lumberjack`) na fila de evidencia/regra ou declarar waiver/dono.
- `server/bin/learned_deck_coherence_audit.py`
  - usar como apoio de validacao de fonte do deck quando a seed vier de learned
    deck, mantendo a separacao entre problema de deck source e problema de
    engine battle.
  - exportar identificador/chave que possa ser cruzado sem ambiguidade pelo
    battle audit; `learned_deck:<id>` sem source/nome/row id nao deve ser chave
    unica de handoff.
- Testes focados:
  - fixture de shock land com perda de vida explicita;
  - fixture da fila de review com representantes de static tax, manifest/cloak,
    alternative cost, tap/untap e mass sacrifice.
  - fixture de divergencia entre auditores exigindo status final que mostre
    exatamente quais gates passaram e quais bloquearam.
  - fixture de coverage garantindo que review-only nao entra como runtime-safe.
  - fixture de learned deck que detecta metadata stale antes de simular.
  - fixture de learned deck provenance garantindo que cada opponent por seed
    exponha chave estavel cruzavel com o report de coherence e que
    `source_ref=learned_deck:<id>` isolado nao seja aceito como chave global.
  - fixture de forensic/provenance exigindo `card_id` e `semantic_hash` quando
    a regra ativa possui esses campos.
  - fixture/auditoria que cruza os `unknown_cards` atuais contra
    `supports_*_template` e falha quando um card fica sem familia e sem waiver.
  - fixture forensic garantindo que `functional_tags_json` sem regra battle
    verified/active nao passa como evento learning-grade.
  - fixture de coverage garantindo que `unknown_template_backlog_cards=0` nao
    oculta `effect_totals.unknown > 0`.
  - fixture de unknown-template backlog garantindo que `unknown_cards=[]` e
    `unknown_effect_cards>0` nao produzem status ambíguo de backlog ready sem
    contrato effect-unknown ou campo source-only explicito.
  - fixture de coverage garantindo que a tabela Markdown `Deck Coverage`
    reconcilia com `effect_coverage.json.deck_totals/source_totals` e falha
    quando uma source key nao nula e omitida ou zerada.
  - fixture de event contract garantindo que eventos emitidos por modulos de
    suporte, como `battle_sba_support.py` e `battle_replacement_support.py`,
    entram no inventario estatico ou possuem waiver explicito.
  - fixture de runtime surface manifest que falha quando arquivos atuais saem
    do inventario sem snapshot/waiver, mesmo que `total_files` continue acima
    de um limite historico.
  - fixture cross-gate em que uma seed `high_confidence_replay` no strategy
    audit tem high action finding e, portanto, nao pode aparecer como
    globalmente elegivel para aprendizado.
  - fixture de escopo do wrapper garantindo que `--seeds 1 --start-seed <seed>`
    seja marcado como run focado/manual e nao possa ser usado como prova de run
    recorrente completo.

## Relacao com a matriz de tarefas

A task resumida correspondente foi registrada na matriz:

- `docs/hermes-analysis/BATTLE_GENERATOR_LOREHOLD_TASK_MATRIX_2026-06-17.md`
  - task P1: `Replay textual auditavel e coerente com JSONL`.

## Passo de auditoria - BV-088 current latest gate/lineage recheck 2026-06-20T00:55-03:00

Escopo: leitura read-only do latest recorrente, do wrapper produtor de
`summary.json`, da matriz de gates e dos testes ja executados pelo proprio
artefato. Nao houve alteracao de codigo, PostgreSQL, deck swap, commit ou push.

Evidencia de artefato atual:

- `latest` aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_033246`.
- `summary.json`: `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `battle_replay_final_status=blocked`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked` e
  `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- O mesmo `summary.json` mostra que nao ha high/critical em action nem strategy
  blockers: `seeds_with_high_or_critical_action_findings=[]` e
  `seeds_with_strategy_blockers=[]`.
- O bloqueio atual vem de forensic: `seeds_with_high_or_critical_forensic_findings=["63210333"]`,
  `forensic_rule_findings=4` e
  `mandatory_gate_statuses.forensic_audit.status=blocked`.
- A linhagem forensic tambem esta incompleta:
  `forensic_lineage_status=incomplete`,
  `forensic_card_id_missing_unaccepted=2`,
  `forensic_semantic_hash_missing_unaccepted=2` e
  `forensic_rule_logical_key_missing_unaccepted=0`.
- `global_learning_eligible_seeds=[]`; portanto este latest nao e elegivel para
  aprendizado global.

Evidencia de codigo:

- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh:1182-1195`
  monta `mandatory_gate_statuses.forensic_audit` a partir de
  `forensic_blocking`, `forensic_rule_findings`, `forensic_turn_findings` e
  seeds high/critical. Os contadores `forensic_*_missing_unaccepted` nao entram
  diretamente nessa decisao.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh:1296-1311`
  calcula `mandatory_gate_divergences` e `battle_replay_final_status` a partir
  de `gate_statuses`.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh:1313-1317`
  chama `compute_global_learning_eligibility` depois do status final ja
  calculado.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh:1320-1327`
  calcula `forensic_lineage_status` depois da elegibilidade global e depois do
  status final.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py:545-612`
  bloqueia elegibilidade global por `final_status`,
  `mandatory_gate_divergences` e findings por seed; nao recebe
  `forensic_*_missing_unaccepted` como motivo proprio.
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py:720-745`
  mantem uma fixture em que lineage unaccepted faltante fica visivel
  (`rule_logical_key_missing_unaccepted=1`,
  `card_id_missing_unaccepted=1`, `semantic_hash_missing_unaccepted=1`) sem
  gerar `findings`.

Evidencia de teste no artefato:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_033246/test_results.jsonl`
  registra `py_compile` e `16` testes com `status=pass`.
- O mesmo arquivo registra
  `test_battle_forensic_audit_supported_effects` com `status=pass`,
  `exit_code=0`, `log_lines=13` e log em
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_033246/test_battle_forensic_audit_supported_effects.log`.

Conclusao validada:

- `BV-088` permanece aberto. O latest corrente ja esta bloqueado por forensic
  high/critical, entao nao ha falsa liberacao neste run. Ainda assim, a falha
  latente permanece real por codigo: se um run futuro tiver
  `forensic_rule_findings=0`, `forensic_turn_findings=0` e nenhum
  high/critical, mas mantiver `forensic_*_missing_unaccepted>0`, o gate
  `forensic_audit` pode passar antes de `forensic_lineage_status` ser
  calculado.

Tarefa clara para o chat "Ajustar battle":

- Alterar o wrapper para fazer qualquer `forensic_*_missing_unaccepted>0` ou
  `forensic_lineage_status=incomplete` participar do
  `mandatory_gate_statuses.forensic_audit` antes de calcular
  `battle_replay_final_status` e `compute_global_learning_eligibility`.
- Adicionar fixture do wrapper cobrindo o caso
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `seeds_with_high_or_critical_forensic_findings=[]` e
  `forensic_*_missing_unaccepted>0`, exigindo
  `mandatory_gate_statuses.forensic_audit.status=review_required`,
  `battle_replay_final_status=review_required` e motivo explicito em
  `global_learning_eligibility_reasons`.

## Passo de auditoria - BV-086 Breena forensic blocker 2026-06-20T01:05-03:00

Escopo: leitura read-only da seed bloqueadora atual, replay humano, JSONL de
eventos, action critic, decision trace, replay decision audit, strategy audit e
codigo de origem do fallback. Nao houve alteracao de codigo, PostgreSQL, deck
swap, commit ou push.

Evidencia de artefato atual:

- Latest `20260620_033246`, seed `63210333`, arquivo
  `seed_63210333/forensic_audit.json`: `rule_findings` contem `4` findings
  para `Breena, the Demagogue`, turno `10`, fase `precombat_main`, player
  `Tayam, Luminous Enigma #25 (real)`.
- Os findings forensic sao:
  `spell_resolved` high e `spell_cast` medium por
  `Game event depended on heuristic source functional_tags_json`, mais dois
  lows por divergencia `draw_cards` versus registry `draw_engine`.
- `forensic_audit.md:118-121` renderiza os mesmos quatro findings; a
  recomendacao high/medium e mover a carta para `card_battle_rules` com status
  `verified/active`.
- `replay.txt:422-425` mostra a jogada humana: announce, pay cost, cast e
  resolve de `Breena, the Demagogue` como `[draw_cards]` com
  `rule=functional_tags_json/heuristic`.
- `replay.events.jsonl` para Breena inclui `cast_announced`, `cost_paid`,
  `spell_cast`, `spell_resolved` e `draw_cards_resolved`; todos os eventos de
  regra carregam `rule_source=functional_tags_json`,
  `rule_review_status=heuristic`, `rule_confidence=0.35` e `rule_version=null`.
- O mesmo `forensic_audit.json` mostra lineage unaccepted exatamente nesses
  eventos: `card_id_missing_unaccepted=2`,
  `semantic_hash_missing_unaccepted=2`,
  `lineage_unaccepted_missing_samples` para `spell_cast` e `spell_resolved`
  de Breena; `rule_logical_key_missing_unaccepted=0` porque a ausencia de
  logical key foi aceita para essa classe.
- `action_critic.json` desta seed tem `findings=[]`,
  `verdict_counts={"ok":457}` e `events_unclassified=0`; em
  `action_critic.md:412-413`, `spell_cast` e `spell_resolved` de Breena estao
  `ok` com `rule=functional_tags_json/heuristic`.
- `replay_decision_audit.json` desta seed tem `decision_findings=0`,
  `turn_findings=0` e `status=turn_invariants_clean`.
- `strategy_audit.json` desta seed tem uma finding medium
  `forced_keep_after_bad_mulligan` em `decision-000006`, rebaixando a seed para
  `low_confidence_replay`; isso e separado do blocker forensic de Breena.
- `summary.json.global_learning_eligibility_reasons["63210333"]` contem
  `strategy_audit:low_confidence_replay`, `forensic_rule_findings=4`,
  `forensic_audit_high_or_critical`, `final_status:blocked` e
  `mandatory_gate:forensic_audit=blocked`.

Evidencia de codigo:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py:2914-2925`
  usa `card_functional_tags(card)` como fallback e anota o efeito com
  `source="functional_tags_json"`, `review_status="heuristic"` e
  `confidence=0.35`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py:134-141`
  classifica `functional_tags_json` como `HEURISTIC_SOURCES`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py:459-467`
  transforma qualquer evento de carta com source heuristico e efeito diferente
  de `creature`/`land` em finding, com severidade high quando o evento e
  `spell_resolved` e medium nos demais.

Conclusao validada:

- `BV-086` permanece aberto como blocker real do latest. O fluxo operacional
  funcionou no sentido de impedir aprendizado global: o action critic aceitou a
  acao como legal/coerente no replay, mas o forensic detectou que a execucao de
  efeito veio de fallback heuristico sem lineage confiavel e bloqueou o gate
  final. A falha nao e "so log"; e runtime-safe vs needs-review: Breena esta
  sendo executada como efeito de carta por `functional_tags_json` quando deveria
  ter regra battle `verified/active` com identidade e hash, ou waiver runtime
  explicito testado.

Tarefa clara para o chat "Ajustar battle":

- Criar/promover regra battle para `Breena, the Demagogue` com
  `effect_json` coerente com a semantica esperada (`draw_engine` ou
  normalizacao explicita para `draw_cards`), `review_status=verified/active`,
  `rule_logical_key`, `card_id` e `semantic_hash`; ou declarar waiver runtime
  especifico, com teste, se o fallback for intencional.
- Adicionar fixture garantindo que `functional_tags_json/heuristic` em
  `spell_resolved` de efeito impactante continua bloqueando forensic/global
  learning, enquanto a regra promovida de Breena deixa de emitir
  `functional_tags_json` e zera os missing unaccepted dessa carta.

## Passo de auditoria - BV-083 action-event denominator recheck 2026-06-20T01:15-03:00

Escopo: leitura read-only do latest recorrente, `summary.json`, todos os
`seed_*/action_critic.json`, wrapper produtor do summary e auditores de
contrato de evento. Nao houve alteracao de codigo, PostgreSQL, deck swap,
commit ou push.

Evidencia de artefato atual:

- Latest `20260620_033246`, `summary.json`:
  `action_events_total=14198`, `action_event_types_total=530`,
  `event_contract_static_events_observed_total=14198` e
  `event_contract_static_observed_event_types_total=54`.
- Recomputacao dos `16` `seed_*/action_critic.json`:
  `summary.event_contract.event_types_total` soma `530`, com minimo `26` e
  maximo `42` tipos por seed.
- Recomputacao global dos mesmos `action_critic.json` por `event` unico:
  `global_distinct_count=54`.
- Distribuicao global distinta por classe, recomputada por `event` unico:
  `action_audited=24`, `ignored_with_reason=4`, `renderer_only=6`,
  `strategy_signal=15`, `technical=5`.
- O `summary.json` atual publica `action_event_type_class_counts` como soma por
  seed: `{"action_audited":310,"ignored_with_reason":33,"renderer_only":34,"strategy_signal":77,"technical":76}`.
- Portanto, `action_event_types_total=530` nao e denominador global distinto;
  e soma de tipos unicos por seed. O denominador global distinto atual e `54`.

Evidencia de codigo:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py:522-548`
  calcula `event_types_total=len(event_type_counts)` e
  `event_type_class_counts` dentro de um unico arquivo de eventos/seed.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh:782-795`
  soma por seed: adiciona `events_total`, adiciona `event_types_total` e faz
  `Counter.update(...)` de `event_type_class_counts`.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh:1090-1102`
  tambem copia do auditor estatico o denominador global observado,
  incluindo `event_contract_static_observed_event_types_total`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py:288-300`
  define esse denominador global como `observed_event_types_total=len(observed_types)`.

Conclusao validada:

- `BV-083` permanece aberto como problema de nomenclatura/observabilidade, nao
  como blocker de legalidade: os eventos estao classificados e
  `event_contract_static_observed_unclassified_total=0`, mas o nome
  `action_event_types_total` induz leitura de superficie global distinta quando
  na verdade publica soma por seed.

Tarefa clara para o chat "Ajustar battle":

- Renomear os campos atuais para `action_event_types_seed_sum` e
  `action_event_type_class_seed_sum`, ou publicar adicionalmente
  `action_event_types_distinct_total=54` e
  `action_event_type_class_distinct_counts={"action_audited":24,"ignored_with_reason":4,"renderer_only":6,"strategy_signal":15,"technical":5}`.
- Atualizar `summary.md` e fixture multi-seed para provar que o mesmo tipo de
  evento aparecendo em varias seeds nao infla o denominador global distinto.

## Passo de auditoria - BV-087 unknown backlog/effect contract recheck 2026-06-20T01:25-03:00

Escopo: leitura read-only do latest recorrente, `summary.json`,
`effect_coverage.json`, `unknown_template_backlog.json/md` e script/teste do
backlog. Nao houve alteracao de codigo, PostgreSQL, deck swap, commit ou push.

Evidencia de artefato atual:

- Latest `20260620_033246`, `summary.json`:
  `effect_coverage_unknowns=0`, mas
  `effect_coverage_effect_totals_unknown=41`.
- O mesmo summary publica `effect_coverage_unknown_effect_cards` com `34`
  cartas, sendo `focused_template_ready_unknown_effect_count=28` e
  `needs_review_unknown_effect_count=5`.
- `unknown_template_backlog.json.summary` mostra
  `status=focused_template_backlog_ready`, `source_unknown_cards=0`,
  `effect_unknown_cards=34`,
  `effect_unknown_source_counts={"battle_rule_curated":1,"battle_rule_needs_review_generated":5,"focused_template_ready":28}` e
  `effect_unknown_status_counts={"focused_template_ready":28,"needs_review":5,"waived_curated_unknown_effect":1}`.
- O mesmo `unknown_template_backlog.json` tem `items=[]`; portanto
  `items_count=0` apesar de `effect_unknown_cards=34`.
- `unknown_template_backlog.md` mostra `Effect-unknown cards: 34`, mas a tabela
  `Per-Card Contract` fica vazia. Os campos `With focused template match`,
  `Without focused template match`, `With plan or waiver` e
  `Without plan or waiver` aparecem todos `0` porque sao calculados sobre
  `items=[]`, nao sobre as `34` cartas effect-unknown.
- `mandatory_gate_statuses.unknown_template_backlog.status=pass` com
  `unknown_cards=0`, `without_plan_or_waiver=0` e
  `without_focused_template_match=0`.

Evidencia de codigo:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py:315-323`
  le `unknown_effect_cards` apenas para contagens de source/status.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py:324-327`
  monta `items` exclusivamente a partir de `coverage.get("unknown_cards")`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py:335-379`
  calcula `without_*`, `with_*` e `status` sobre `items`; com `items=[]`, o
  status vira `focused_template_backlog_ready`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py:68-105`
  fixa a separacao atual: com `unknown_cards=[]` e `unknown_effect_cards`
  preenchido, o teste exige `unknown_cards=0`, `source_unknown_cards=0` e
  contagens de effect unknown, mas nao exige tabela/contrato por carta para os
  effect-unknown.

Conclusao validada:

- `BV-087` permanece aberto como lacuna de contrato/escopo. O artifact nao
  esconde totalmente o denominador effect-unknown, porque summary e Markdown
  publicam `effect_unknown_cards=34` e contagens por status/source. A falha e
  que o gate `unknown_template_backlog` e a tabela `Per-Card Contract` avaliam
  apenas source-unknown (`unknown_cards`), entao passam com contrato vazio mesmo
  quando existem `34` cartas `effect=unknown`, incluindo `5` `needs_review`.

Tarefa clara para o chat "Ajustar battle":

- Separar explicitamente `source_unknown_template_backlog_status` de
  `effect_unknown_template_contract_status`, ou gerar `items`/contrato por
  carta tambem para `unknown_effect_cards`.
- A fixture deve falhar quando `effect_unknown_cards>0` e a tabela/JSON de
  contrato por effect-unknown estiver vazia sem escopo explicito, especialmente
  quando houver status `needs_review`.

## Passo de auditoria - BV-084 research review samples recheck 2026-06-20T01:35-03:00

Escopo: leitura read-only do latest recorrente, `research_review.json/md`,
`seed_*/strategy_audit.json` e codigo local atual do auditor de research
review. Nao houve alteracao de codigo, PostgreSQL, deck swap, commit ou push.

Evidencia de artefato atual:

- Latest `20260620_033246`, `research_review.md`: `Finding counts` mostra
  `{"forced_keep_after_bad_mulligan": 6}` e `Strategy low-confidence seeds`
  mostra `["63210332","63210333","63210338","63210345","63210346"]`.
- `research_review.json.categories.mulligan` tem as chaves
  `current_guardrail`, `expected_trace`, `finding_codes`, `finding_count`,
  `observed_decisions`, `official_sources`, `status` e `strategy_sources`.
  Nao ha chave `finding_samples` no artifact oficial.
- `research_review.md` mostra `Findings: {"forced_keep_after_bad_mulligan": 6}`
  em `mulligan`, mas nao renderiza tabela `Seed | Decision | Code | Severity`.
- Recomputacao direta dos `16` `seed_*/strategy_audit.json` identificou os
  seis findings reais:
  `63210332/decision-000010`, `63210333/decision-000006`,
  `63210338/decision-000007`, `63210338/decision-000011`,
  `63210345/decision-000009` e `63210346/decision-000011`.
- O `summary.json` confirma `strategy_findings=6`,
  `strategy_low_confidence_findings=6`,
  `strategy_review_required_findings=0`,
  `strategy_learning_confidence_counts={"high_confidence_replay":11,"low_confidence_replay":5}`
  e `strategy_not_learning_eligible_seeds=[]`.

Evidencia de codigo local atual:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py:203-225`
  define `finding_sample(...)` com `seed`, `decision_id`, `code`,
  `severity`, `detail`, `chosen_option`, `reason`, `risk_flags`, `player`,
  `turn`, `phase` e `actual_outcome`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py:300-315`
  adiciona `finding_samples=category_items[:20]` nas categorias.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py:382-400`
  renderiza a tabela Markdown de samples quando `data["finding_codes"]`
  existe.

Conclusao validada:

- `BV-084` permanece aberto contra o latest oficial. A lacuna ja parece
  parcialmente tratada no codigo local modificado, mas o artifact oficial
  `20260620_033246` ainda nao publica `finding_samples` nem a tabela de samples
  no Markdown. Portanto, nao ha evidencia oficial para fechar o BV ate um novo
  run gerar `research_review.json/md` com as seis seeds/decisions listadas.

Tarefa clara para o chat "Ajustar battle":

- Garantir que o wrapper recorrente rode a versao do
  `battle_decision_research_review.py` que publica `finding_samples`, e
  revalidar em novo run oficial.
- O criterio de fechamento e `research_review.json.categories.mulligan.finding_samples`
  contendo os seis findings atuais com seed/decision/detail, e
  `research_review.md` contendo a tabela `Seed | Decision | Code | Severity`
  para `forced_keep_after_bad_mulligan`.

## Passo de auditoria - BV-085 decision trace waiver/grade recheck 2026-06-20T01:45-03:00

Escopo: leitura read-only do latest recorrente, `decision_trace_taxonomy.json/md`,
`summary.json`, todos os `seed_*/replay.decision_trace.jsonl` e documento de
taxonomia. Nao houve alteracao de codigo, PostgreSQL, deck swap, commit ou
push.

Evidencia de artefato atual:

- Latest `20260620_033246`, `decision_trace_taxonomy.json.summary`:
  `decision_trace_rows=2214`, `decision_trace_contract_findings=0`,
  `decision_trace_kinds_observed=11`, `decision_trace_kinds_total=15`,
  `decision_trace_observed_without_contract=0` e
  `decision_trace_observed_without_specific_contract=0`.
- O mesmo summary lista waivers aceitas:
  `["activated_sacrifice_damage","attack_trigger_artifact_tutor","lorehold_upkeep_rummage","saga_chapter_resolution","utility_artifact_activation","utility_land_activation"]`.
- O artifact oficial nao publica `accepted_field_contract_waiver_observed_rows`,
  `decision_learning_grade_counts` nem `observed_status_counts`; esses campos
  voltaram `null` na leitura direta do JSON.
- O `summary.json` principal publica `decision_trace_accepted_waivers`, mas nao
  publica quantas linhas observadas caem nessa classe nem grade de aprendizado
  por tipo.
- Recomputacao direta dos `16` `replay.decision_trace.jsonl` confirmou os
  `2214` rows e estes tipos observados:
  `cast_spell=496`, `combat_attack=279`,
  `lorehold_upkeep_rummage=79`, `mulligan_decision=125`,
  `pass_no_action=1127`, `response=9`, `saga_chapter_resolution=3`,
  `tutor=30`, `utility_artifact_activation=46`,
  `utility_land_activation=11`, `wheel=9`.
- Linhas observadas em tipos `accepted_field_contract_waiver`: `139` no total:
  `lorehold_upkeep_rummage=79`, `saga_chapter_resolution=3`,
  `utility_artifact_activation=46`, `utility_land_activation=11`.
- Recomputacao direta encontrou `parent_link_rows=0` quando procurando
  `parent_decision_id`, `source_decision_id` ou `parent_decision`.

Evidencia documental:

- `docs/hermes-analysis/BATTLE_DECISION_TRACE_TAXONOMY.md:15-16` ja declara que
  tipos `accepted_field_contract_waiver` sao field-contract-only ate o
  summary/taxonomy publicar `decision_learning_grade`.
- `docs/hermes-analysis/BATTLE_DECISION_TRACE_TAXONOMY.md:44`,
  `:48`, `:50` e `:51` classificam os quatro tipos observados acima como
  `accepted_field_contract_waiver`.
- `docs/hermes-analysis/BATTLE_DECISION_TRACE_TAXONOMY.md:59` diz que a
  qualidade estrategica de `lorehold_upkeep_rummage` permanece coberta por
  escolhas de engine pai, mas os traces atuais nao publicam link para essa
  decisao pai.

Conclusao validada:

- `BV-085` permanece aberto. O gate de taxonomia esta correto ao passar o
  contrato de campos, mas ainda nao torna consumivel no `summary.json` que `139`
  linhas observadas sao field-contract-only. Sem `decision_learning_grade` e sem
  `parent_decision_id`/`source_decision_id`, consumidor pode tratar essas linhas
  como strategy-audited quando elas sao apenas aceitacao de contrato de campo.

Tarefa clara para o chat "Ajustar battle":

- Publicar no `summary.json` e em `decision_trace_taxonomy.json/md`
  `accepted_field_contract_waiver_observed_rows=139`, contadores por tipo e
  `decision_learning_grade` por tipo (`strategy_audited`,
  `research_specific`, `field_contract_only`, `not_observed`).
- Para waivers que dependem de "parent engine choices", emitir
  `parent_decision_id`/`source_decision_id`; se o link nao existir, marcar a
  linha como `field_contract_only`/non-learning de forma explicita.

## Passo de auditoria - producer de gate final e lineage forensic 2026-06-20T00:08-03:00

Escopo: leitura read-only do produtor real de `summary.json` e dos testes
locais embutidos. Nao houve alteracao de codigo, PostgreSQL, deck swap,
commit ou push.

Evidencia de codigo:

- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh:1081-1123`
  monta `mandatory_gate_statuses`. O gate `forensic_audit` usa
  `seeds_with_high_or_critical_forensic_findings`, `forensic_rule_findings` e
  `forensic_turn_findings`; os contadores
  `forensic_*_missing_unaccepted` nao entram diretamente nessa condicao.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh:1224-1239`
  calcula `mandatory_gate_divergences` e `battle_replay_final_status` a partir
  de `gate_statuses`.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh:1241-1245`
  chama `compute_global_learning_eligibility` com o final status ja calculado.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh:1248-1255`
  so depois disso calcula `forensic_lineage_status` como
  `incomplete`/`complete` a partir dos contadores unaccepted de lineage.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py:545-612`
  confirma que a elegibilidade global bloqueia por `final_status !=
  trusted_for_strategy_learning`, por `mandatory_gate_divergences`, por
  findings action/decision/forensic e por confianca de strategy; ela nao recebe
  os contadores `forensic_*_missing_unaccepted` como motivo proprio.
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py:720-740`
  confirma o caso de teste em que lineage unaccepted faltante permanece visivel
  (`rule_logical_key_missing_unaccepted=1`,
  `card_id_missing_unaccepted=1`, `semantic_hash_missing_unaccepted=1`) sem
  gerar `findings`.

Evidencia executada:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py`
  - PASS: `19` testes embutidos, incluindo
    `test_global_learning_eligibility_blocks_high_strategy_seed_when_other_gates_review_required`
    e
    `test_global_learning_eligibility_allows_clean_high_seed_and_excludes_low_confidence_seed`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`
  - PASS: `13` testes embutidos, incluindo
    `test_forensic_keeps_unaccepted_lineage_missing_visible`.

Conclusao validada:

- Este passo reforca `BV-088`, sem abrir uma pendencia nova duplicada. O latest
  `20260620_025107` esta limpo por artifact atual
  (`forensic_lineage_status=complete`, `forensic_*_missing_unaccepted=0`,
  `mandatory_gate_divergences=[]`), mas o produtor do gate final ainda permite
  uma falha latente: um futuro run pode ter lineage unaccepted visivel sem
  findings forensic e ainda assim o `forensic_audit` passar, porque
  `forensic_lineage_status` e calculado depois do final status e nao participa
  diretamente do gate. A tarefa correta para o chat "Ajustar battle" continua:
  fazer `forensic_*_missing_unaccepted>0` ou
  `forensic_lineage_status=incomplete` participar do gate forensic antes de
  computar `battle_replay_final_status` e elegibilidade global.

## Fechamento cronologico - BV-084 research review samples 2026-06-20T01:01-03:00

Escopo: validacao posterior aos rechecks historicos acima; sem PostgreSQL
write, sem deck swap e sem promocao de regra battle.

Evidencia oficial final:

- Latest recorrente:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/summary.json`.
- `summary.json`: `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `test_results_total=16` e
  `test_results_status_counts={"pass":16}`.
- `research_review.json`: `categories.mulligan.finding_codes={"forced_keep_after_bad_mulligan":6}`
  e `categories.mulligan.finding_samples` com `6` entries:
  `63210405/decision-000007`, `63210405/decision-000011`,
  `63210407/decision-000006`, `63210410/decision-000010`,
  `63210415/decision-000005` e `63210416/decision-000009`.
- `research_review.md`: contem tabela `Seed | Decision | Code | Severity`
  para os findings `forced_keep_after_bad_mulligan`.
- `test_results.jsonl`: `test_battle_decision_research_review` passou com
  `exit_code=0`.
- Report persistente:
  `docs/hermes-analysis/master_optimizer_reports/battle_latest_040120_research_review_bv084_closure_20260620_0101.md`.

Resultado: `BV-084` fechado. As mencoes historicas anteriores de `BV-084`
aberto foram superadas pelo run oficial `20260620_040120`; o quadro aberto
atual nao contem mais linha `BV-084`.

## Fechamento cronologico - BV-083 action-event denominator 2026-06-20T06:12-03:00

Escopo: tratativa posterior aos rechecks historicos acima; sem PostgreSQL
write, sem deck swap, sem promocao de regra battle e sem alteracao de deck
builder.

Evidencia oficial final:

- Wrapper local:
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`.
- Sintaxe do wrapper: `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  - PASS.
- Latest recorrente:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_090636/summary.json`.
- `summary.json`: `run_scope=recurring_full`, `run_profile=recurring_16_seed`,
  `seeds_requested=16`, `seeds_completed=16`, `test_results_total=16` e
  `test_results_status_counts={"pass":16}`.
- `summary.json`: `action_event_types_total=561`,
  `action_event_types_total_semantics=legacy_seed_sum_across_seed_action_critics`,
  `action_event_types_seed_sum=561` e
  `action_event_types_distinct_total=55`.
- `summary.json`: `action_event_type_class_seed_sum={"action_audited":328,"ignored_with_reason":39,"renderer_only":33,"strategy_signal":85,"technical":76}`.
- `summary.json`: `action_event_type_class_distinct_counts={"action_audited":24,"ignored_with_reason":4,"renderer_only":6,"strategy_signal":16,"technical":5}`.
- `summary.json`: `event_contract_static_observed_event_types_total=55` e
  `event_contract_static_observed_type_class_counts={"action_audited":24,"ignored_with_reason":4,"renderer_only":6,"strategy_signal":16,"technical":5}`.
- `summary.md`: renderiza `Action event types seed-sum: 561`,
  `Action event types distinct global: 55`, `Action event type class seed-sum`
  e `Action event type class distinct global`.
- Report persistente:
  `docs/hermes-analysis/master_optimizer_reports/battle_latest_090636_action_event_denominator_bv083_closure_20260620_0612.md`.

Resultado: `BV-083` fechado. O `summary.json` e o `summary.md` agora distinguem
explicitamente a soma por seed do denominador global distinto. O run
`20260620_090636` ficou `battle_replay_final_status=review_required` por
`mandatory_gate_divergences=["forensic_audit=review_required"]`; isso e pendencia
de forensic/gate separada, nao reabre `BV-083`. As mencoes historicas anteriores
de `BV-083` aberto foram superadas por este fechamento; o quadro aberto atual
nao contem mais linha `BV-083`.

## Reconciliacao Auditor Central single-operator - latest 090636 - 2026-06-20 07:48 -0300

Escopo: leitura e reconciliacao de estado corrente pelo Auditor Central em
modo single-operator. Nao houve PostgreSQL write, deck swap, promocao de regra
battle, commit, push, revert, stash ou cleanup.

Evidencia executada:

- `git status --short --branch`: worktree segue em `master...origin/master`,
  com alteracoes amplas em `app/`, `server/`, `docs/` e artefatos untracked.
- `git diff --shortstat`: `67 files changed, 7967 insertions(+), 1768 deletions(-)`.
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  - PASS.
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
  aponta para `run_dir=.../20260620_090636`, `run_scope=recurring_full`,
  `run_profile=recurring_16_seed`.
- `test_results.jsonl`: `16` entradas, todas com `status=pass`.

Estado atual prevalente:

- `battle_replay_final_status=review_required`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`.
- `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- `forensic_lineage_status=incomplete`.
- `forensic_rule_findings=1`, `forensic_turn_findings=0`.
- Unaccepted lineage faltante:
  `forensic_rule_logical_key_missing_unaccepted=1`,
  `forensic_card_id_missing_unaccepted=1`,
  `forensic_semantic_hash_missing_unaccepted=1`.
- Amostra nao aceita atual: `Leyline of Abundance`, seed `63210916`,
  `event=spell_cast`, `effect=ramp_permanent`,
  `source=functional_tags_json`.
- Gates obrigatorios que passaram no artifact atual: `action_critic`,
  `strategy_audit`, `replay_decision_audit`, `effect_coverage`,
  `focused_template_dispatch`, `unknown_template_backlog`,
  `decision_trace_taxonomy` e `event_contract_static`.
- `effect_coverage_unknown_effect_status_counts` permanece:
  `{"focused_template_ready":28,"needs_review":5,"waived_curated_unknown_effect":1}`.
- `decision_trace_taxonomy`: `rows=2207`, `kinds_observed=12/15`,
  `contract_findings=0`, `missing_required_fields=0`.

Pendencias ainda abertas por estado corrente:

- `BV-082`: source lineage/coherence dos learned opponents segue aberto; o
  status final do engine nao valida automaticamente a coerencia do corpus
  learned usado como oponente.
- `BV-085`: waivers `accepted_field_contract_waiver` ainda precisam de
  contadores/grade de aprendizado explicitos para impedir leitura indevida como
  strategy-audited.
- `BV-086`: `functional_tags_json` voltou a aparecer no latest atual, agora em
  `Leyline of Abundance`; requer decisao tecnica entre regra battle
  verified/active, waiver runtime explicito, ou ajuste de observabilidade/gate.
- `BV-087`: contrato effect-unknown segue separado do backlog source-unknown;
  os `needs_review=5` continuam exigindo contrato/waiver claro.
- `BV-088`: o latest atual ja bloqueia por forensic finding, mas ainda falta
  fixture de gate para o caso em que `forensic_*_missing_unaccepted>0` ocorra
  com `forensic_rule_findings=0`.

Conclusao operacional:

- `BV-081`, `BV-083`, `BV-084` e `BV-089` permanecem fechados.
- Battle nao tem deploy PostgreSQL autorizado nem pronto neste momento.
- Um futuro `PG-004` so deve existir depois de uma decisao documentada sobre
  `Leyline of Abundance` e de um pacote com precheck/apply/rollback/postcheck.
- A proxima acao correta para battle e desenhar e testar a correcao
  `BV-086/BV-088` no runtime/gate antes de qualquer escrita em banco.

## Reconciliacao Auditor Central - PG-006 execution_status drift - 2026-06-20 08:08 -0300

Escopo: leitura read-only de PostgreSQL, migration status e latest
`summary.json`, seguida de atualizacao documental. Nao houve PostgreSQL write,
deck swap, promocao de regra battle, commit, push, revert, stash ou cleanup.

Evidencia PostgreSQL read-only:

- `dart run bin/migrate.dart --status` reporta a migration `029
  add_card_battle_rules_execution_status` como pendente.
- `card_battle_rules.execution_status` ja existe em PostgreSQL, esta `NOT NULL`
  e tem default `'auto'::text`.
- A constraint `chk_card_battle_rules_execution_status` nao existe no banco
  atual.
- `schema_migrations.version='029'` nao esta registrado.
- Distribuicao atual de `card_battle_rules`:
  - `curated / active / auto = 26`;
  - `curated / verified / auto = 1725`;
  - `generated / needs_review / auto = 1970`;
  - `generated / needs_review / review_only = 1467`.
- O precheck PG-006 em
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_precheck_20260620_0808.sql`
  retornou `pg006_rows_to_normalize=1970`.

Evidencia latest battle:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
  reporta `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["forensic_audit=review_required"]`,
  `forensic_lineage_status=incomplete`,
  `execution_status_counts={"auto":3159}`,
  `needs_review_rule_names=1457`, `review_only_rule_names=0` e
  `review_only_rule_instances=0`.

Conclusao operacional:

- PG-006 foi aberto no PostgreSQL deploy register como drift de migracao/dados,
  status `package_ready_for_approval`, com pacote em
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_package_20260620_0808.md`.
- PG-006 nao fecha `BV-086` nem `BV-088`: ele normaliza a governanca
  `execution_status` e registra a migration `029`; a lineage incompleta de
  `Leyline of Abundance` e o acoplamento do forensic gate continuam sendo
  trabalho de runtime/gate.
- Nao rodar `dart run bin/migrate.dart` como solucao isolada para este drift:
  a migration nativa so normaliza linhas com `execution_status` nulo/vazio, e
  as `1970` linhas problematicas ja estao como `auto`.

## Reconciliacao Auditor Central - PG-006 aplicado e latest battle confiavel - 2026-06-20 08:51 -0300

Escopo:

- Fechamento operacional do drift PG-006 em PostgreSQL.
- Rerun do auditor battle depois do deploy e correcao do manifest de superficie
  runtime.

Evidencia PostgreSQL:

- PG-006 apply executado em
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_apply_20260620_0808.sql`.
- Resultado do apply: `COMMIT`, `normalized_rows=1970`, backup rollback
  `1970` linhas.
- Postcheck PG-006:
  `execution_status_counts={"auto":1751,"review_only":3437}`,
  `generated / needs_review / review_only = 3437`,
  `remaining_needs_review_not_review_only=0`,
  `rollback_backup_rows=1970`, constraint
  `chk_card_battle_rules_execution_status` presente, migration `029` presente,
  e `card_intelligence_snapshot_view.mentions_execution_status=true`.
- `dart run bin/migrate.dart --status` depois do apply reportou `29/29`
  migrations executadas e `0` pendentes.

Evidencia runtime/battle:

- Primeiro rerun manual apos PG-006 criou
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_114638`,
  mas falhou em `test_battle_runtime_surface_manifest` porque dois arquivos de
  learned-deck entraram na superficie sem classificacao:
  `server/bin/plan_learned_deck_partner_identity_backfill.py` e
  `server/test/plan_learned_deck_partner_identity_backfill_test.py`.
- `battle_runtime_surface_manifest.py` passou a classificar esses dois arquivos
  como `learned-deck source`; `test_battle_runtime_surface_manifest.py` foi
  atualizado para `EXPECTED_TOTAL_FILES=110`,
  `learned-deck source=16`, `outside_recurring_run=75`,
  `targeted_manual_gate_required_before_change=32` e
  `targeted_test_required_before_change=43`.
- Validacoes da correcao:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`
  PASS; manifest com `--fail-on-unclassified` PASS; `py_compile` dos dois
  arquivos PASS.
- Rerun completo do auditor battle concluiu com exit `0` e atualizou `latest`
  para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_115516`.
- Novo `summary.json`: `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `test_results_total=16`, `test_results_status_counts={"pass":16}`.
- Novo manifest runtime: `runtime_surface_manifest_status=runtime_surface_manifest_ready`,
  `runtime_surface_manifest_total_files=110`,
  `runtime_surface_manifest_category_counts={"core runtime":31,"focused evidence/promotion":4,"learned-deck source":16,"optimizer/scorecard":15,"recurring audit gate":24,"renderer":4,"review queue":1,"rule registry/sync":15}`.

Conclusao operacional:

- O blocker forensic de `090636` esta superado pelo latest `115516`; nao criar
  pacote PG-004/Leyline com base no run antigo.
- PG-006 esta aplicado e validado em PostgreSQL.
- O `summary.json` battle pre-sync `20260620_115516` ainda reportava
  `execution_status_counts={"auto":3159}` e `review_only_rule_names=0` porque
  esse contador pertencia a superficie Hermes/runtime do auditor, nao ao
  postcheck PostgreSQL. Esse follow-up foi fechado depois pelo sync
  `20260620_120904` e pelo latest `20260620_121005`.

## Reconciliacao Auditor Central - PG-006 runtime cache sync - 2026-06-20 09:15 -0300

Escopo:

- Fechamento do follow-up de alinhamento entre PostgreSQL PG-006 e a superficie
  Hermes/runtime usada pelo auditor battle.
- Operacao local em SQLite Hermes e snapshot canonico. Nao houve novo write em
  PostgreSQL, deck swap, rule promotion, commit, push, revert, stash ou cleanup.

Evidencia de origem:

- PostgreSQL ja estava limpo pelo PG-006:
  `execution_status_counts={"auto":1751,"review_only":3437}`,
  `generated / needs_review / review_only = 3437`,
  `remaining_needs_review_not_review_only=0`, migration `029` presente e
  `dart run bin/migrate.dart --status` com `29/29` executadas.
- Antes do sync, SQLite Hermes ainda tinha `battle_card_rules` com:
  `curated/active/auto=27`, `curated/verified/auto=1675` e
  `generated/needs_review/auto=1981`.

Aplicacao controlada:

- Backup criado:
  `docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg006-runtime-sync.20260620_120904.bak`.
- Comando executado:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --include-needs-review --apply-sqlite-from-pg --export-canonical-fallback-json docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json --report docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_120904.json`.
- Report:
  `apply_pg=false`, `apply_sqlite_from_pg=true`, `pg_rows_loaded=5188`,
  `sqlite_inserted_or_updated=5106`,
  `canonical_snapshot_rows_exported=3159`.

Evidencia pos-sync:

- SQLite direto:
  `execution_status auto = 1702` e `review_only = 1981` linhas; por nome,
  `auto = 1702` e `review_only = 1981`.
- Caminho do auditor battle apos colapso por nome/prioridade:
  `runtime_safe_rule_names=1702`,
  `active_or_review_rule_names=3159`,
  `execution_status_counts={"auto":1702,"review_only":1457}`,
  `needs_review_rule_names=1457`, `review_only_rule_names=1457`.
- Efeito/cobertura pos-sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.json`
  e `.md`.
- O script tambem gerou
  `battle_effect_coverage_audit_20260620_120952.json` e `.md`; esses arquivos
  tem hash identico ao par `120904_post_sqlite_sync` e foram movidos para a
  proposta de cleanup, sem apagar nada.

Latest battle:

- Full recurring audit executado com
  `MANALOOM_BATTLE_STRATEGY_RUN_PROFILE=manual_post_pg006_sqlite_sync`,
  `MANALOOM_BATTLE_STRATEGY_INVOCATION_KIND=manual_auditor_post_sqlite_sync`,
  `--seeds 16 --start-seed 61620904`.
- Latest agora aponta para
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_121005`.
- `summary.json`:
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`,
  `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `test_results_total=16`, `test_results_status_counts={"pass":16}`,
  `execution_status_counts={"auto":1702,"review_only":1457}`,
  `needs_review_rule_names=1457`, `review_only_rule_names=1457`.

Conclusao operacional:

- O follow-up de escopo PG-006 versus Hermes/runtime esta fechado para o cache
  local atual: PostgreSQL segue como fonte final, e o runtime Hermes agora
  reflete `review_only` no `summary.json`.
- `review_only_rule_instances=0` permanece como contador estreito do corpus
  jogado; os `34` usos no corpus aparecem como
  `battle_rule_needs_review_generated` / `needs_review_rule`, nao como falha do
  sync.
- Nao ha pacote PG-004/Leyline pronto nem necessario a partir do latest
  `20260620_121005`.

## Reconciliacao Auditor Central - focused evidence extra combat - 2026-06-20 10:09 -0300

Escopo:

- Correcao do harness focado de evidencia para contratos de extra combat com
  flashback.
- Correcao de isolamento do teste de ambiente do daemon operacional.
- Nao houve novo write em PostgreSQL, rule promotion, deck swap, cleanup,
  commit, push, revert ou stash.

Evidencia:

- `server/bin/manaloom_battle_rule_focused_evidence.py` agora passa o effect
  data original da spell ao resolver evidencia de `extra_combat` e tambem ao
  resolver o item de stack de flashback.
- O caso que expunha o problema era `Seize the Day`: sem o effect data original,
  a evidencia focada podia ser reclassificada pelo snapshot conhecido e falhar
  contra o contrato esperado `extra_combat`.
- `python3 -m unittest server.test.manaloom_review_queue_consumers_test.ManaloomReviewQueueConsumersTest.test_focused_evidence_unblocks_supported_low_risk_templates -v`
  passou e registrou `MANALOOM_BATTLE_RULE_FOCUSED_EVIDENCE` com
  `evaluated_count=14` e `evidence_count=14`.
- `server/test/manaloom_ops_daemon_test.py` agora isola `DB_HOST` e `DB_NAME`
  durante o teste de carregamento do `.env`.
- `python3 -m unittest server.test.manaloom_ops_daemon_test.ManaLoomOpsDaemonTest.test_base_env_loads_database_values_from_env_file -v`
  passou.
- `python3 -m py_compile server/bin/manaloom_battle_rule_focused_evidence.py server/test/manaloom_ops_daemon_test.py`
  passou.
- `python3 -m unittest discover -s server/test -p '*_test.py' -v` passou
  `96/96`; houve um `ResourceWarning` de sqlite nao fechado em teste de
  learned-deck, sem falha de exit status.

Conclusao:

- A fila de promocao/evidencia focada volta a desbloquear os `14` templates
  suportados de baixo risco.
- Esta reconciliacao nao muda o status do latest battle `20260620_121005`,
  que continua `trusted_for_strategy_learning`.
- Nao ha novo pacote PG-004 ou outro deploy PostgreSQL a partir desta correcao.

## Reconciliacao Auditor Central - latest voltou para review_required / PG-007 preparado - 2026-06-20 10:22 -0300

Escopo:

- Releitura obrigatoria do `latest/summary.json` depois do ciclo anterior.
- Preparacao de pacote PostgreSQL para o novo blocker de forensic lineage.
- Nenhum write em PostgreSQL foi executado nesta reconciliacao.

Latest atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_125745/summary.json`
- `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63211257`
- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["forensic_audit=review_required"]`
- `forensic_lineage_status=incomplete`
- `forensic_rule_findings=1`, `forensic_turn_findings=0`
- `test_results_total=16`, `test_results_status_counts={"pass":16}`

Finding ativo:

- Seed:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_125745/seed_63211258/forensic_audit.json`
- Card: `Leyline of Abundance`
- Evento: `spell_cast`
- Efeito: `ramp_permanent`
- Fonte atual: `functional_tags_json`
- Severidade: `medium`
- Recomendacao do auditor forensic: mover a carta para `card_battle_rules`
  com status `verified/active`.

Evidencia PostgreSQL read-only:

- `cards` possui `Leyline of Abundance` com
  `id=d524183f-6430-411b-8a9b-48eda6cb0f7d`.
- `card_battle_rules` ainda nao possui nenhuma linha para Leyline:
  `pg007_existing_target_rule=0` e `pg007_existing_any_leyline_rule=0`.
- `card_intelligence_snapshot` atual tem `battle_rules=[]` e
  `function_tags={engine}` para a carta.

Pacote preparado:

- `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_package_20260620_1018.md`
- `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_precheck_20260620_1018.sql`
- `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_apply_20260620_1018.sql`
- `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_rollback_20260620_1018.sql`
- `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_postcheck_20260620_1018.sql`

Conclusao:

- O latest `20260620_121005` virou evidencia historica; ele nao e mais o estado
  ativo.
- Naquele checkpoint historico de 10:22, o estado de battle era
  `review_required`.
- Naquele checkpoint historico, PG-007 estava preparado, mas nao aplicado.
  Aplicar requeria aprovacao explicita do comando exato, postcheck, sync PG ->
  SQLite Hermes e rerun battle.

## Reconciliacao Auditor Central - PG-007 aplicado / latest trusted - 2026-06-20 10:31 -0300

Escopo:

- Aplicacao PostgreSQL do pacote PG-007 para `Leyline of Abundance`.
- Postcheck PostgreSQL.
- Sync PostgreSQL -> SQLite Hermes.
- Rerun completo do battle recurring gate com `16` seeds.

Evidencia PostgreSQL:

- Apply:
  `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_apply_20260620_1018.sql`.
- Resultado do apply: `INSERT 0 1` e `COMMIT`.
- Linha aplicada em `card_battle_rules`:
  `normalized_name='leyline of abundance'`,
  `logical_rule_key='battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941'`,
  `source='curated'`, `review_status='active'`,
  `execution_status='auto'`, `confidence=0.820`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_postcheck_20260620_1018.sql`.
- Resultado do postcheck: `pg007_target_rule_count=1`; o
  `card_intelligence_snapshot` da carta passou a expor a regra em
  `battle_rules`.

Evidencia runtime:

- Backup SQLite:
  `docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg007-runtime-sync.20260620_102701.bak`.
- Sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_102701_post_pg007.json`.
- Resultado do sync: `pg_rows_loaded=5189`,
  `sqlite_inserted_or_updated=5107`,
  `canonical_snapshot_rows_exported=3160`.
- Coverage pos-sync:
  `runtime_safe_rule_names=1703`,
  `active_or_review_rule_names=3160`,
  `execution_status_counts={"auto":1703,"review_only":1457}`.

Latest atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_132812/summary.json`
- `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63211328`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `forensic_lineage_status=complete`
- `forensic_rule_findings=0`, `forensic_turn_findings=0`
- `test_results_total=16`, `test_results_status_counts={"pass":16}`
- Checagem programatica dos seeds: `forensic_files=16`,
  `bad_forensic_files=0`.

Conclusao:

- PG-007 esta fechado.
- O blocker `Leyline of Abundance` de `20260620_125745` virou historico
  pre-apply.
- O estado ativo de battle volta a ser `trusted_for_strategy_learning` com base
  no latest `20260620_132812`.

## Reconciliacao Auditor Central - heartbeat single-operator - 2026-06-20 10:57 -0300

Escopo:

- Continuidade do modo Auditor Central como operador unico.
- Releitura do estado real do repo, docs obrigatorios e latest battle.
- Nenhum write em PostgreSQL, rule promotion, deck swap, cleanup, commit, push,
  revert ou stash.

Evidencia atual:

- `git status --short --branch`: `master...origin/master`, `72 M`, `78 ??`.
- `git diff --shortstat`:
  `72 files changed, 24397 insertions(+), 2028 deletions(-)`.
- `git ls-files --others --exclude-standard | wc -l`: `79`.
- `git diff --check`: clean.
- Latest battle continua:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_132812/summary.json`.
- Latest result:
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`, tests `16/16`.
- O deploy register foi reconciliado para rotular a antiga secao PG-004 /
  `20260620_121005` como historica e supersedida por PG-007.

Conclusao:

- O estado ativo de battle permanece confiavel para estrategia pelo latest
  `20260620_132812`.
- Nao ha novo pacote PostgreSQL ou promocao de regra battle pronto a partir
  deste heartbeat.
- Cleanup segue nao autorizado; os artefatos de evidencia devem ser preservados
  ate aprovacao explicita de uma lista exata.

## Reconciliacao Auditor Central - latest 140016 / fila PG sem apply - 2026-06-20 11:19 -0300

Escopo:

- Releitura do latest battle depois da mudanca de symlink para `20260620_140016`.
- Recheck do manifesto de superficie runtime battle.
- Recheck read-only da fila PostgreSQL aplicada.
- Nenhum write em PostgreSQL, promocao de regra, deck swap, cleanup, commit,
  push, stash ou revert foi executado.

Latest atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_140016/summary.json`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `forensic_lineage_status=complete`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`
- `execution_status_counts={"auto":1703,"review_only":1457}`
- `strategy_high_confidence_learning_seeds=14`
- `strategy_low_confidence_seeds=["63211407","63211414"]`
- `strategy_review_required_findings=0`
- `unknown_template_backlog_cards=0`
- `focused_template_dispatch_status=focused_template_dispatch_ready`
- `focused_template_evidence_ready=29`
- `focused_template_evidence_not_ready_unwaived=0`

Manifesto runtime:

- `python3 test_battle_runtime_surface_manifest.py` retornou
  `PASS test_manifest_classifies_current_battle_surface`.
- Scan do manifesto: `total_files=110`, `unclassified_files=[]`.
- Cobertura: `covered_by_recurring_run=29`, `imported_by_core_runtime=6`,
  `outside_recurring_run=75`.

PostgreSQL read-only:

- Migracoes: `29/29` executadas, `0` pendentes.
- PG-001 planner: `planned_row_count=0`, `db_mutations=false`.
- PG-002 postcheck: `after_matches=59`, `still_before_rows=0`,
  `all_post_apply_checks_ok=true`.
- PG-003 oracle planner: `backfill_ready=0`, `db_mutations=false`.
- PG-005 Lorehold dry-run: `applied_counts=0`, `db_mutations=false`.
- PG-006 postcheck: migracao `029` presente, constraint presente,
  `remaining_needs_review_not_review_only=0`.
- PG-007 postcheck: `pg007_target_rule_count=1`.

Conclusao:

- O latest ativo e `20260620_140016` e esta confiavel para strategy learning.
- `20260620_132812` continua sendo evidencia historica de fechamento PG-007,
  mas nao e mais o latest ativo.
- Nao ha novo apply PostgreSQL pronto neste heartbeat.

## Checkpoint Auditor Central - Batch 0/1 readiness - 2026-06-20 13:12 -0300

Scope:

- Re-read live latest battle and current dirty worktree before preparing the
  first publication boundary.
- Created `MANALOOM_BATCH_0_1_READINESS_2026-06-20.md` to isolate Batch 0
  local-evidence hygiene and Batch 1 audit/PostgreSQL/Battle/Lorehold docs.
- No stage, commit, push, deck swap, cleanup, PostgreSQL write, code deploy, or
  app/backend source edit was performed.

Evidence:

- Latest battle now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_160459/summary.json`.
- Latest status: `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `test_results_total=16`, and `test_results_status_counts={'pass': 16}`.
- `git diff --check`: clean.
- Worktree checkpoint before this register addition: `73` tracked modified
  files, `75` untracked files, and shortstat
  `73 files changed, 24752 insertions(+), 2022 deletions(-)`.

Conclusion:

- Current battle remains trusted after PG-008.
- Batch 0/1 is ready for explicit staging approval, but it was not staged.
- No current PostgreSQL apply is ready.

## Auditor Central Aven Mindcensor Runtime Rule Closure - 2026-06-20 15:15 -0300

Scope:

- Closed the concrete `Aven Mindcensor` blocker found in the post-fix Lorehold
  battle review.
- Applied a PostgreSQL battle-rule correction, refreshed the Hermes SQLite rule
  cache, regenerated the canonical known-cards snapshot, and audited one
  structured replay.

PostgreSQL/runtime changes:

- `Aven Mindcensor` now has a curated verified primary creature rule:
  `effect=creature`, `power=2`, `toughness=1`, `flash=true`, `flying=true`,
  `execution_status=auto`.
- Its static anti-tutor text is preserved as a separate curated active
  annotation-only rule:
  `opponent_library_search_limited_to_top_cards=4`,
  `execution_status=annotation_only`.
- The old generated `needs_review/review_only` generic creature row remains as
  lower-priority historical evidence and is no longer selected by runtime.

Evidence:

- PG apply report:
  `docs/hermes-analysis/master_optimizer_reports/pg_apply_aven_mindcensor_rules_20260620_1803.json`
  with `pg_inserted_or_updated=2`.
- Runtime refresh:
  `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_1803_post_aven.json`
  with `pg_rows_loaded=5192`, `sqlite_inserted_or_updated=5110`, and
  `canonical_snapshot_rows_exported=3161`.
- Runtime direct check selected `curated/verified/auto` for the creature body
  and reported the anti-tutor static rule as `execution_status_annotation_only`.
- Single structured replay:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_single_battle_replay_20260620_1810.txt`.
- Replay action critic:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_single_battle_replay_20260620_1810.action_critic.json`
  with `total_actions=458`, `findings=0`, and `verdict_counts={"ok":458}`.
- Replay forensic audit:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_single_battle_replay_20260620_1810.forensic.json`
  with `findings_total=0`.
- Replay decision audit:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_single_battle_replay_20260620_1810.decision_audit.json`
  with `turn_findings=0` and `decision_findings=0`.

Conclusion:

- The Aven-specific `needs_review` blocker is resolved for runtime selection.
- The fix does not pretend the static search-limiter replacement layer is fully
  implemented; it records that ability as annotation-only until a library-search
  replacement executor exists.
- The full 16-seed battle-strategy audit completed after this fix at
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_181004/summary.json`
  with `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `test_results_status_counts={"pass":16}`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `decision_audit_decision_findings=0`, `decision_audit_turn_findings=0`, and
  `action_findings=0`.
- The latest quality gate with the clean audit is
  `docs/hermes-analysis/master_optimizer_reports/master_optimizer_quality_gate_20260620_181826.md`.

## Auditor Central Table-Intent Real Battle Closure - 2026-06-20 18:27 -0300

Scope:

- Consolidated Rafael's full authorization for this thread to own battle
  correction, PostgreSQL promotion, Hermes SQLite cache refresh, documentation,
  worktree organization, commit, and push for the real-battle cycle.
- Reconciled the stale latest states `20260620_210513`, `20260620_211217`, and
  `20260620_211648` against the current latest full recurring audit.

Evidence:

- Current latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/summary.json`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `test_results_status_counts={"pass":18}`.
- Mandatory blockers are clean:
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`,
  `decision_trace_contract_findings=0`,
  `target_pressure_findings=0`, and `table_intent_findings=0`.
- Table-intent proof:
  `combat_total=294`, `scored_combat_total=294`, `missing_scores=0`,
  `opponent_spell_cast=270`, `opponent_spell_resolved=153`,
  `opponent_creature_cast=101`, `opponent_commander_cast=59`,
  `opponent_cast_illegal=0`, `opponent_interaction_events=72`,
  `opponent_trigger_interaction_events=32`, `opponent_wins=15`,
  `target_wins=1`.
- Target-pressure proof:
  `target_pressure_statuses={"pass":16}`, `opponent_combat_to_target=214`,
  `opponent_combat_to_other=3`, and `opponent_multi_defender_attack=2`.
- Unknown-template/effect residual gates are accepted:
  `unknown_template_backlog_cards=0`,
  `effect_coverage_residual_raw_unaccepted_flags=[]`, and
  `effect_coverage_residual_unaccepted_cards=[]`.
- Human-readable seed evidence:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/seed_63212120/replay.txt`,
  with `table-intent-realistic`, target `Lorehold`, three real learned-deck
  opponents, `action_critic findings=0`, table-intent pass, target-pressure
  pass, and Lorehold eliminated on turn `11`.
- Closure report:
  `docs/hermes-analysis/master_optimizer_reports/battle_table_intent_real_battle_closure_20260620_1827.md`.

Conclusion:

- Current battle is trusted for strategy learning under table-intent pressure.
- The result does not prove Lorehold is optimized; it proves the battle surface
  can now evaluate Lorehold under realistic opponent pressure. The latest
  16-seed result is harsh for Lorehold (`opponent_wins=15`, `target_wins=1`)
  and should become the baseline for the next deck-improvement cycle.

## Auditor Central PG018 Pending Battle Closure - 2026-06-20 22:14 -0300

Scope:

- Rechecked latest battle, PostgreSQL/cache evidence, and Lorehold learned-deck
  coherence after external PG-016, PG-017, and PG-018 artifacts appeared.
- This heartbeat performed read-only checks and documentation only. It did not
  execute PostgreSQL apply/sync, deck swaps, cleanup, stash, revert, stage,
  commit, or push.

Evidence:

- Latest completed battle summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_010452/summary.json`.
- `run_scope=custom_multi_seed`,
  `invocation_kind=codex_pg017_full64_real_deck_baseline`,
  `seeds_requested=64`, `seeds_completed=64`.
- `battle_replay_final_status=blocked`,
  `mandatory_gate_divergences=["forensic_audit=blocked"]`,
  `forensic_rule_findings=2`,
  `forensic_severity_counts={"high":1,"medium":1}`.
- Clean non-forensic gates: target-pressure `pass=64`,
  table-intent `pass=64`, action findings `0`, replay-decision findings `0`,
  and `test_results_status_counts={"pass":18}`.
- The blocker was opponent card-rule lineage for `Jin-Gitaxias, Core Augur`,
  effect `draw_cards`, source `functional_tags_json`, seed `63212362`,
  turn `8`.
- PG-018 package/sync artifacts appeared after the blocked run:
  `opponent_forensic_rules_pg018_*_20260621_011600.*` and
  `battle_card_rules_sqlite_from_pg_pg018_opponent_forensic_20260621_011800.json`.
- Read-only PG-018 postcheck returned `card_rows=2`,
  `curated_executable_rows=2`, and `function_tag_rows=2` for
  `Jin-Gitaxias, Core Augur` and `Chandra, Flameshaper`; local Hermes SQLite
  selects both rows as curated/verified/auto.
- A post-PG018 battle runner was active:
  `manaloom-battle-strategy-audit.sh --seeds 64 --start-seed 63212310`.

Conclusion:

- PG-018 is closed for PostgreSQL/cache evidence but not yet battle-closed in
  this register.
- Battle closure requires the next completed `latest` summary after PG-018.
- Lorehold learned-deck coherence remains clean in
  `learned_deck_coherence_audit_20260620_233027.json`; the active battle drift
  is opponent card-rule governance, not a Lorehold decklist coherence failure.

## Auditor Central PG019 Pending Battle Closure - 2026-06-20 22:44 -0300

Scope:

- Rechecked the post-PG018 64-seed result and the new PG-019 package/sync
  evidence.
- This heartbeat performed read-only checks and documentation only. It did not
  execute PostgreSQL apply/sync, deck swaps, cleanup, stash, revert, stage,
  commit, or push.

Evidence:

- Latest completed battle summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_012833/summary.json`.
- `run_scope=custom_multi_seed`,
  `invocation_kind=codex_pg018_full64_real_deck_baseline`,
  `seeds_requested=64`, `seeds_completed=64`.
- `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["strategy_audit=review_required"]`.
- Forensic is closed: `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  and `forensic_severity_counts={}`.
- Clean non-strategy gates: target-pressure `pass=64`,
  target-pressure findings `0`, table-intent `pass=64`, action findings `0`,
  replay-decision findings `0`, and `test_results_status_counts={"pass":18}`.
- Strategy audit has `strategy_findings=17`,
  `strategy_low_confidence_findings=16`, and
  `strategy_review_required_findings=1`.
- The review-required finding is seed `63212362`,
  `wheel_opponent_refill_risk`, decision `decision-000141`, caused by
  `Jin-Gitaxias, Core Augur` being treated as a wheel-like draw-seven effect.
- PG-019 package/sync artifacts appeared after the `012833` run:
  `jin_gitaxias_non_wheel_pg019_*_20260621_013900.*` and
  `battle_card_rules_sqlite_from_pg_pg019_jin_non_wheel_20260621_014100.json`.
- Read-only PG-019 postcheck and local Hermes SQLite both verify the
  `Jin-Gitaxias, Core Augur` curated/verified/auto row with
  `wheel_like=false`.
- A post-PG019 battle runner was active:
  `manaloom-battle-strategy-audit.sh --seeds 64 --start-seed 63212310`.

Conclusion:

- PG-018 is now battle-forensic closed.
- PG-019 is closed for PostgreSQL/cache evidence but not yet battle-closed in
  this register.
- Battle closure requires the next completed `latest` summary after PG-019.

## Auditor Central Local Windborn Battle Closure - 2026-06-20 23:14 -0300

Scope:

- Rechecked the latest post-PG019 battle result and the new local Hermes
  optimizer apply evidence.
- This heartbeat performed read-only checks and documentation only. It did not
  execute PostgreSQL apply/sync, deck swaps, cleanup, stash, revert, stage,
  commit, or push.

Evidence:

- Latest completed battle summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_020427/summary.json`.
- `run_scope=recurring_full`,
  `invocation_kind=codex_pg019_post_apply_windborn_16`,
  `seeds_requested=16`, `seeds_completed=16`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`.
- Clean gates: forensic findings `0`, target-pressure `pass=16`,
  table-intent `pass=16`, action findings `0`, replay-decision findings `0`,
  and `test_results_status_counts={"pass":18}`.
- Strategy audit has `strategy_findings=5`,
  `strategy_low_confidence_findings=5`, and
  `strategy_review_required_findings=0`.
- Local Hermes optimizer apply artifact:
  `master_optimizer_apply_20260621_020406.md`, applying `Windborn Muse` over
  `Guttersnipe` to local Hermes `deck_id=6` only.
- Local SQLite confirms `Windborn Muse=1`, no `Guttersnipe`, and `100/100`
  cards.
- PostgreSQL materialized deck check confirms `Guttersnipe=1`, no
  `Windborn Muse`, and `100/100` cards.

Conclusion:

- PG-019 strategy-audit issue is closed in the completed 16-seed latest.
- The trusted battle result validates local Hermes runtime state, not a
  PostgreSQL/learned-deck Windborn swap.
- A newer 64-seed run was still active and should be reconciled next.

Final 64-seed reconciliation:

- Latest advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_020729/summary.json`.
- `invocation_kind=codex_pg019_post_apply_windborn_64`,
  `seeds_requested=64`, `seeds_completed=64`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, target-pressure
  `pass=64`, table-intent `pass=64`, action findings `0`, replay-decision
  findings `0`, tests `18/18`, and `strategy_review_required_findings=0`.
- No active battle runner remained in the final process check.

## Auditor Central PG020 Candidate Check - 2026-06-20 23:45 -0300

Scope:

- Rechecked the latest candidate battle after PG-020 and the fresh learned-deck
  coherence audit.
- This heartbeat did not execute PostgreSQL apply/sync, deck swaps, cleanup,
  stash, revert, stage, commit, or push.

Evidence:

- Latest completed battle summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024220/summary.json`.
- `invocation_kind=codex_pg020_candidate_ensnaring_bridge_for_monument_16`,
  `seeds_requested=16`, `seeds_completed=16`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`.
- Clean gates: forensic findings `0`, target-pressure `pass=16`,
  table-intent `pass=16`, action findings `0`, replay-decision findings `0`,
  and tests `18/18`.
- Strategy audit has `strategy_findings=7`,
  `strategy_low_confidence_findings=7`, and
  `strategy_review_required_findings=0`.
- No PostgreSQL package exists for the Ensnaring Bridge candidate in
  `master_optimizer_reports`.
- Fresh learned-deck coherence artifact
  `learned_deck_coherence_audit_20260621_024551.json` reports Lorehold
  `issues=[]` but active learned deck name drift against PG/Hermes runtime.

Conclusion:

- Candidate battle is clean, but Ensnaring Bridge over Monument to Endurance is
  not approved/applied.
- PG-020 remains battle-trusted.
- Active learned-deck name drift remains open.

Final candidate reconciliation:

- Latest advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024527/summary.json`.
- `invocation_kind=codex_pg020_candidate_silent_arbiter_for_monument_16`,
  `seeds_requested=16`, `seeds_completed=16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, target-pressure
  `pass=16`, table-intent `pass=16`, tests `18/18`, and
  `strategy_review_required_findings=0`.
- No PG package exists for this candidate; it is clean battle evidence only.

## PG-020 Post-PostgreSQL Windborn Validation - 2026-06-20 23:40 -0300

Scope:

- Validated the canonical PostgreSQL promotion of `Windborn Muse` over
  `Guttersnipe` after PG-020 apply and PG -> Hermes sync.

Evidence:

- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_windborn_deck_swap_pg020_package_20260621_022046.md`.
- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/sync_pg_target_deck_to_hermes_pg020_windborn_20260621_022046.json`.
- Local runtime deck after sync: `deck_id=6`, `100/100`, `Windborn Muse=1`,
  `Guttersnipe=0`.

Battle results:

- Smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_022403/summary.json`
  with `2/16`, `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, tests `18/18`,
  and `strategy_code_counts={"forced_keep_after_bad_mulligan":5}`.
- Full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_022700/summary.json`
  with `4/64 = 6.25%`, `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, tests `18/18`,
  `target_pressure_opponent_combat_to_target=912`,
  `target_pressure_opponent_combat_to_other=12`, and
  `strategy_code_counts={"forced_keep_after_bad_mulligan":15}`.

Conclusion:

- The Windborn swap is now canonical PostgreSQL state and validated by battle.
- The deck still fails as a competitive battle list: it loses `60/64` in the
  current seed window and still becomes the table focus. Next validation must
  test additional survival/keep-stability changes, not treat PG-020 as final.

## Candidate Battle Reconciliation - 2026-06-20 23:49 -0300

- Latest candidate summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024906/summary.json`.
- `invocation_kind=codex_pg020_candidate_norns_annex_for_monument_16`,
  `seeds_requested=16`, `seeds_completed=16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, target-pressure
  `pass=16`, table-intent `pass=16`, tests `18/18`, and
  `strategy_review_required_findings=0`.
- No PG package exists for Norn's Annex over Monument to Endurance in
  `docs/hermes-analysis/master_optimizer_reports`.
- Classification: candidate-only battle validation. No PostgreSQL apply, deck
  swap, commit, push, stash, revert, cleanup, or file deletion was performed by
  this heartbeat.

## Review-Required Candidate Battle Reconciliation - 2026-06-20 23:52 -0300

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_025233/summary.json`.
- `invocation_kind=codex_pg020_candidate_magus_moat_for_monument_16`,
  `seeds_requested=16`, `seeds_completed=16`,
  `battle_replay_final_status=review_required`.
- Mandatory gate divergences:
  `forensic_audit=review_required` and
  `replay_decision_audit=review_required`.
- Specific finding: seed `63212318`, turn `12`, `board_wipe_resolved`,
  low severity, board wipe left `9` protected creatures versus `7` destroyed.
- Tests are still green (`18/18`), with target-pressure `pass=16`,
  table-intent `pass=16`, forensic rule findings `0`, and replay decision
  findings `0`.
- No PG package exists for Magus of the Moat over Monument to Endurance; this
  run is not promotion evidence.

## Review-Required Candidate Battle Reconciliation - 2026-06-21 00:17 -0300

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_030022/summary.json`.
- `invocation_kind=codex_pg020_candidate_magus_moat_for_monument_64`,
  `run_scope=custom_multi_seed`, `seeds_requested=64`,
  `seeds_completed=64`, and
  `battle_replay_final_status=review_required`.
- Mandatory gate divergences:
  `forensic_audit=review_required` and
  `replay_decision_audit=review_required`.
- Specific finding: seed `63212318`, turn `12`, `board_wipe_resolved`,
  low severity, board wipe left `9` protected creatures versus `7` destroyed.
- Tests are still green (`18/18`), with target-pressure `pass=64`,
  table-intent `pass=64`, forensic rule findings `0`, and replay decision
  findings `0`.
- Strategy signal in the 64-seed window: target wins `9`, opponent wins `54`,
  opponent combat to target `883`, opponent combat to other `21`, and
  `forced_keep_after_bad_mulligan=14`.
- No PG package exists for Magus of the Moat over Monument to Endurance; this
  run is blocked candidate evidence, not promotion evidence.

## Corrected Candidate Battle Reconciliation - 2026-06-21 00:18 -0300

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_031617/summary.json`.
- `invocation_kind=codex_pg021_corrected_candidate_magus_moat_for_monument_16`,
  `run_scope=recurring_full`, `seeds_requested=16`, `seeds_completed=16`,
  and `battle_replay_final_status=trusted_for_strategy_learning`.
- Mandatory gate divergences are empty, with forensic rule findings `0`,
  forensic turn findings `0`, replay decision findings `0`, target-pressure
  `pass=16`, table-intent `pass=16`, and tests `18/18`.
- Strategy signal: target wins `2`, opponent wins `12`,
  opponent combat to target `215`, opponent combat to other `2`, and
  `forced_keep_after_bad_mulligan=5`.
- No PG package exists for Magus of the Moat over Monument to Endurance; this
  is clean candidate evidence, not promotion evidence.

## Corrected Silent Arbiter Battle Reconciliation - 2026-06-21 00:52 -0300

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_032623/summary.json`.
- `invocation_kind=codex_pg021_corrected_candidate_silent_arbiter_for_monument_64`,
  `run_scope=custom_multi_seed`, `seeds_requested=64`,
  `seeds_completed=64`, and
  `battle_replay_final_status=trusted_for_strategy_learning`.
- Mandatory gate divergences are empty, with forensic rule findings `0`,
  forensic turn findings `0`, replay decision findings `0`, target-pressure
  `pass=64`, table-intent `pass=64`, and tests `18/18`.
- Strategy signal: target wins `8`, opponent wins `54`,
  opponent combat to target `1103`, opponent combat to other `14`, and
  `forced_keep_after_bad_mulligan=15`.
- No PG package exists for Silent Arbiter over Monument to Endurance; this is
  clean candidate evidence, not promotion evidence.

## PG022 Post-Sync Battle Validation - 2026-06-21 01:55 -0300

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044419/summary.json`.
- `invocation_kind=codex_pg022_post_pg_sync_silent_arbiter_16`,
  `run_scope=recurring_full`, `seeds_requested=16`, `seeds_completed=16`,
  and `battle_replay_final_status=trusted_for_strategy_learning`.
- Mandatory gate divergences are empty, with forensic rule findings `0`,
  forensic turn findings `0`, replay decision findings `0`, target-pressure
  `pass=16`, table-intent `pass=16`, and tests `18/18`.
- Strategy signal: target wins `3`, opponent wins `13`,
  opponent combat to target `274`, opponent combat to other `10`, and
  `forced_keep_after_bad_mulligan=4`.
- PG022 postcheck and PG -> Hermes sync confirm runtime deck now contains
  `Silent Arbiter=1` and `Windborn Muse=1`, with `100/100` cards.

## PG022 Full Post-Sync Battle Validation - 2026-06-21 01:58 -0300

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044758/summary.json`.
- `invocation_kind=codex_pg022_post_pg_sync_silent_arbiter_64`,
  `run_scope=custom_multi_seed`, `seeds_requested=64`,
  `seeds_completed=64`, and
  `battle_replay_final_status=trusted_for_strategy_learning`.
- Mandatory gate divergences are empty, with forensic rule findings `0`,
  forensic turn findings `0`, replay decision findings `0`, target-pressure
  `pass=64`, table-intent `pass=64`, and tests `18/18`.
- Strategy signal: target wins `8`, opponent wins `54`,
  opponent combat to target `1103`, opponent combat to other `14`, and
  `forced_keep_after_bad_mulligan=15`.
- Compared with corrected baseline
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_041725/summary.json`,
  PG022 improves Lorehold from `4/64` to `8/64`.

## Post-PG022 Candidate Battle Reconciliation - 2026-06-21 02:27 -0300

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_052416/summary.json`.
- `run_profile=candidate_reprieve_for_generous_gift_16`,
  `invocation_kind=codex_candidate_scan`, `run_scope=recurring_full`,
  `seeds_requested=16`, `seeds_completed=16`.
- Final status is `review_required` because
  `mandatory_gate_divergences=["strategy_audit=review_required"]`.
- Mandatory technical surfaces are otherwise clean: forensic rule findings `0`,
  forensic turn findings `0`, replay decision findings `0`,
  target-pressure `pass=16`, table-intent `pass=16`, tests `18/18`.
- Strategy signal: Lorehold wins `5/16`, opponents win `9/16`,
  opponent combat to Lorehold `291`, opponent combat to others `4`,
  `forced_keep_after_bad_mulligan=5`, `wheel_opponent_refill_risk=1`.
- Local SQLite restoration check after the temporary candidate runner:
  `Generous Gift=1`; no persisted `Reprieve`, `Artist's Talent`, or
  `Brainstone` candidate rows in `deck_id=6`.
- Result: Reprieve over Generous Gift is blocked candidate evidence, not
  promotion evidence.
- Intermediate candidate evidence since PG022:
  `20260621_051800` Brainstone over Generous Gift after forensic fix was
  `4/16`, trusted, clean gates; `20260621_052117` Artist's Talent over
  Generous Gift was `3/16`, trusted, clean gates. Both still require an
  approved PostgreSQL package before any mutation.

## Post-Engine-Fix Candidate Battle Reconciliation - 2026-06-21 03:06 -0300

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_054803/summary.json`.
- `run_profile=recurring_16_seed`,
  `invocation_kind=codex_candidate_combo_scan`, `run_scope=recurring_full`,
  `seeds_requested=16`, `seeds_completed=16`.
- Final status is `trusted_for_strategy_learning` because all mandatory gates
  pass: `mandatory_gate_divergences=[]`, forensic findings `0`, replay
  decision findings `0`, target-pressure `pass=16`, table-intent `pass=16`,
  tests `18/18`.
- Strategy signal: Lorehold wins `1/16`, opponents win `15/16`,
  opponent combat to Lorehold `213`, opponent combat to others `5`,
  `forced_keep_after_bad_mulligan=7`.
- Post-fix sequence:
  `053446` candidate `4/16`, `053937` baseline-after-engine-fix `3/16`,
  `054357` candidate-after-engine-fix `4/16`, and latest `054803` combo scan
  `1/16`; all four are gate-clean.
- Result: the latest combo scan is valid replay evidence but not promotion
  evidence; its win count is worse than the existing PG022 full validation.

## Aborted Runner Reconciliation - 2026-06-21 04:48 -0300

- Newer run directory:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_060733/`.
- It does not contain `summary.json`, and `latest` still points to
  `20260621_054803`.
- `test_results.jsonl` shows `py_compile=pass` and
  `test_battle_analyst_v10_3=failed`.
- The failure happened after `963s` with
  `psycopg2.OperationalError: server closed the connection unexpectedly` while
  opening PostgreSQL in the promoted-hotfix runtime fallback test.
- A follow-up read-only `select 1` succeeded (`pg_select_1=1`), so the failure
  is classified as aborted runner/infrastructure evidence, not a validated
  battle result.
- No deck or PostgreSQL state should be changed based on `060733`.

## Latest Manual 64-Seed Battle Reconciliation - 2026-06-21 05:17 -0300

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_080706/summary.json`.
- `run_profile=custom_64_seed`, `invocation_kind=manual_cli`,
  `run_scope=custom_multi_seed`, `seeds_requested=64`,
  `seeds_completed=64`.
- Final status is `trusted_for_strategy_learning`: all mandatory gates pass,
  with forensic findings `0`, replay decision findings `0`,
  target-pressure `pass=64`, table-intent `pass=64`, and tests `18/18`.
- Strategy signal: Lorehold wins `14/64`, opponents win `49/64`,
  opponent combat to Lorehold `1050`, opponent combat to others `46`,
  `forced_keep_after_bad_mulligan=13`.
- Deck-state check: local SQLite `deck_id=6` remains `100/100` and contains
  `Silent Arbiter=1`, `Windborn Muse=1`, `Generous Gift=1`.
- Result: `080706` is the latest valid battle result and improves the observed
  64-seed outcome versus the earlier PG022 full validation, but it is not a
  PostgreSQL deploy package or learned-deck mutation approval.

## PG023 Candidate Package Reconciliation - 2026-06-21 05:17 -0300

- Package:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_brainstone_deck_swap_pg023_package_20260621_114447.md`.
- Proposed swap: `Brainstone` over `Generous Gift`.
- Package status: `prepared`.
- Candidate evidence is the latest 64-seed battle:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_080706/summary.json`,
  `14/64`, trusted, clean gates.
- Baseline cited by package:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044758/summary.json`,
  `8/64`, trusted, clean gates.
- Local SQLite has not been swapped: `Generous Gift=1`, no `Brainstone`.
- Result: PG023 is candidate/deploy-package evidence only until explicit apply,
  postcheck, sync, and rerun occur.

## PG023 Applied Validation Reconciliation - 2026-06-21 10:07 -0300

- The previous PG023 candidate-only classification is superseded by newer
  package, postcheck, sync, and battle evidence.
- This heartbeat did not run PG023 apply or rollback; it ran only the PG023
  postcheck SQL against PostgreSQL in read-only mode.
- PG023 package status:
  `applied_and_postchecked_and_battle_validated`.
- Read-only PG postcheck: `deck_rows=100`, `deck_quantity=100`,
  `gift_rows=0`, `brainstone_rows=1`, `brainstone_is_commander=false`,
  `deck_backup_rows=1`, `rule_backup_rows=1`,
  `brainstone_rule_verified=true`, `postcheck_passed=true`.
- Sync evidence:
  `sync_pg_target_deck_to_hermes_pg023_brainstone_20260621_114447.json`
  reports `apply=true`, `cards_written=100`, `quantity_written=100`;
  `battle_card_rules_sqlite_from_pg_pg023_brainstone_20260621_114447.json`
  reports `apply_sqlite_from_pg=true`, `sqlite_inserted_or_updated=5211`.
- Current local SQLite `deck_id=6` returns `Brainstone=1`,
  `Silent Arbiter=1`, `Windborn Muse=1`, and no `Generous Gift`.
- Post-sync smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_121648/summary.json`,
  `4/16`, trusted, clean gates.
- Latest post-sync full validation:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_122732/summary.json`,
  `64/64`, `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, target-pressure `pass=64`,
  table-intent `pass=64`, tests `18/18`, Lorehold `14/64`,
  `forced_keep_after_bad_mulligan=13`.
- Result: PG023 is validated and should not be reapplied. Remaining battle
  strategy work is consistency/mulligan, not gate repair.

## Temporary Expedition Map Candidate Validation - 2026-06-21 10:15 -0300

- New latest external battle artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_131126/summary.json`.
- Observed runner command temporarily modified local SQLite from PG023 state by
  adding `Expedition Map` and cutting `Electroduplicate`, then restored the DB
  from a backup after exit.
- Summary: `run_profile=recurring_16_seed`, `manual_cli`, `16/16`,
  `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  target-pressure `pass=16`, table-intent `pass=16`, tests `18/18`.
- Strategy signal: Lorehold wins `1/16`, opponents win `14/16`,
  `forced_keep_after_bad_mulligan=3`, high-confidence seeds `14`,
  low-confidence seeds `2`.
- Post-run SQLite check shows persistent runtime restored:
  `Brainstone=1`, `Electroduplicate=1`, `Silent Arbiter=1`,
  `Windborn Muse=1`, no `Expedition Map`, no `Generous Gift`, `100/100`.
- Result: candidate is gate-clean but worse than PG023 post-sync full evidence;
  no promotion or PostgreSQL action follows from it.

## Latest PG023 Recurring Smoke Validation - 2026-06-21 10:20 -0300

- Latest external battle artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_131606/summary.json`.
- Summary: `run_profile=recurring_16_seed`, `run_scope=recurring_full`,
  `manual_cli`, `16/16`, `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`,
  table-intent `pass=16`, tests `18/18`.
- Strategy signal: Lorehold wins `3/16`, opponents win `13/16`,
  `forced_keep_after_bad_mulligan=5`, high-confidence seeds `12`,
  low-confidence seeds `4`.
- Runtime check after run: `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, `Windborn Muse=1`, no `Generous Gift`,
  no `Expedition Map`, `100/100`.
- Result: current latest is gate-clean recurring smoke on PG023; still no new
  promotion or deploy action.

## Temporary Thrill Candidate Validation - 2026-06-21 10:25 -0300

- Latest external battle artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132027/summary.json`.
- Observed runner command temporarily added `Thrill of Possibility` and cut
  `Boros Charm`, then restored SQLite from backup on exit.
- Summary: `recurring_16_seed`, `recurring_full`, `manual_cli`, `16/16`,
  `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  target-pressure `pass=16`, table-intent `pass=16`, tests `18/18`.
- Strategy signal: Lorehold wins `2/16`, opponents win `13/16`,
  `forced_keep_after_bad_mulligan=4`.
- Post-run SQLite check shows persistent runtime restored:
  `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, `Windborn Muse=1`, no `Thrill of Possibility`,
  `100/100`.
- Result: temporary candidate is not promotion evidence and does not create a
  deploy item.

## Temporary Reprieve Candidate Validation - 2026-06-21 10:30 -0300

- Latest external battle artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132537/summary.json`.
- Previously active temporary runner completed: `Reprieve` over `Boros Charm`,
  with SQLite backup/restore.
- Summary: `recurring_16_seed`, `recurring_full`, `manual_cli`, `16/16`,
  `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  target-pressure `pass=16`, table-intent `pass=16`, tests `18/18`.
- Strategy signal: Lorehold wins `4/16`, opponents win `12/16`,
  `forced_keep_after_bad_mulligan=5`.
- Post-run SQLite check shows persistent runtime restored:
  `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, `Windborn Muse=1`, no `Reprieve`, no `Generous Gift`,
  `100/100`.
- Result: gate-clean temporary candidate evidence only; no promotion and no
  deploy item.

## PG023 Candidate Scan Summary - 2026-06-21 10:30 -0300

- New artifact:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_pg023_candidate_scan_20260621_132537.md`.
- Status: `no_promotion`.
- Rejected temporary candidates:
  `Expedition Map` over `Electroduplicate` (`1/16`),
  `Reforge the Soul` over `Boros Charm` (`3/16`),
  `Thrill of Possibility` over `Boros Charm` (`2/16`), and
  `Reprieve` over `Boros Charm` (`4/16`).
- All candidate gates were trusted/clean, but none beat PG023 enough to promote;
  `Reprieve` tied the PG023 smoke win count but worsened pressure and
  `forced_keep_after_bad_mulligan`.
- No PostgreSQL apply or package was generated for these candidates.

## PG023 Post-Sync Battle Validation - 2026-06-21 10:06 -0300

- Package:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_brainstone_deck_swap_pg023_package_20260621_114447.md`.
- PostgreSQL package status: applied, postchecked, synced, and battle
  validated.
- Post-sync smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_121648/summary.json`,
  `seeds_completed=16`, `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, tests `18/18`, Lorehold `4/16`.
- Post-sync full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_122732/summary.json`,
  `seeds_completed=64`, `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, tests `18/18`, Lorehold `14/64`,
  opponents `49/64`.
- Gate details on full run: target-pressure `pass=64`, table-intent `pass=64`,
  forensic findings `0`, replay decision findings `0`.
- Strategy signal on full run:
  `forced_keep_after_bad_mulligan=13`, low-confidence seeds
  `63212323`, `63212326`, `63212328`, `63212330`, `63212331`, `63212336`,
  `63212341`, `63212346`, `63212354`, `63212369`.
- Sync state after validation: local SQLite has `Brainstone=1`, no
  `Generous Gift`, and Brainstone curated rule is `verified/auto`.
- Result: PG023 is valid battle evidence and supersedes PG022 as the current
  Lorehold runtime deck state.

## PG023 Candidate Smoke Rejections - 2026-06-21 10:06 -0300

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_pg023_candidate_scan_20260621_132537.md`.
- All four candidate runs are gate-clean but do not beat the PG023 smoke
  baseline `20260621_121648` (`4/16`).
- Rejected candidates:
  `Expedition Map` over `Electroduplicate` (`1/16`),
  `Reforge the Soul` over `Boros Charm` (`3/16`),
  `Thrill of Possibility` over `Boros Charm` (`2/16`), and
  `Reprieve` over `Boros Charm` (`4/16` with worse pressure/low-confidence
  profile).
- No PostgreSQL apply or package was created for these candidates.
- Local SQLite restoration check after the final candidate: `Boros Charm=1`,
  `Brainstone=1`, `Electroduplicate=1`.
- Note: `latest` now points to the final rejected candidate
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132537/summary.json`;
  canonical PG023 runtime validation remains
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_122732/summary.json`.

## Focused Zone Transition Validation - 2026-06-21 11:03 -0300

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_140346/summary.json`.
- Scope: focused one-seed zone-transition validation, not a full Lorehold deck
  validation.
- Summary: `run_profile=focused_zone_transition_fix_v3`,
  `run_scope=focused_seed`,
  `invocation_kind=codex_focused_zone_transition_fix_63212310_v3`,
  `seeds_completed=1/1`.
- Final status: `trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`.
- Gate details: target-pressure `pass=1`, table-intent `pass=1`,
  test results `pass=18`, strategy review findings `0`.
- Strategy counts: `strategy_code_counts={}` and
  `strategy_severity_counts={}`.
- Runtime deck check after the focused latest read: SQLite deck `6` remains
  `100` rows / `100` quantity with `Boros Charm=1`, `Brainstone=1`,
  `Electroduplicate=1`, `Silent Arbiter=1`, and `Windborn Muse=1`.
- Result: focused runtime-support validation is clean. PG023 canonical full
  deck validation remains `20260621_122732` (`14/64`, trusted, clean gates).

## PG023 Combat-Survival Rebaseline - 2026-06-21 11:30 -0300

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_142400/summary.json`.
- Scope: PG023 16-seed recurring full rebaseline after combat-survival runtime
  response.
- Summary: `run_profile=pg023_rebaseline_after_combat_survival_16_seed`,
  `run_scope=recurring_full`,
  `invocation_kind=codex_pg023_rebaseline_after_combat_survival_response`,
  `seeds_completed=16/16`.
- Final status: `trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`.
- Gate details: target-pressure `pass=16`, table-intent `pass=16`,
  test results `pass=18`, strategy review findings `0`.
- Strategy counts: `forced_keep_after_bad_mulligan=2`, medium severity `2`.
- Outcome: Lorehold target wins `1/16`, opponents `15/16`; opponent combat to
  Lorehold `246`, to other players `2`.
- Runtime deck check: SQLite deck `6` remains `100` rows / `100` quantity with
  `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, and `Windborn Muse=1`.
- Result: gates are clean, but PG023 remains strategically weak under pressure.
  No PostgreSQL rollback/apply or deck swap is authorized by this sample.

## PG023 Priority-Fix And Angel's Grace Candidate Sweep - 2026-06-21 12:04 -0300

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_145948/summary.json`.
- `140846`: PG023 rebaseline after zone/declared-target-controller fix,
  trusted, clean gates, tests `pass=18`, Lorehold `2/16`, opponents `14/16`.
- `141620`: PG023 rebaseline after reactive-hold fix, trusted, clean gates,
  tests `pass=18`, Lorehold `1/16`, opponents `15/16`.
- `144336`: pre-priority-fix Angel's Grace over Boros Charm candidate, blocked
  by `forensic_audit=blocked`; not valid strategy evidence.
- `145423`: PG023 rebaseline after cannot-lose priority fix, trusted, clean
  gates, tests `pass=18`, Lorehold `1/16`, opponents `15/16`.
- `145948`: post-priority-fix Angel's Grace over Boros Charm candidate,
  trusted, clean gates, tests `pass=18`, target-pressure `pass=16`,
  table-intent `pass=16`, Lorehold `2/16`, opponents `13/16`,
  `forced_keep_after_bad_mulligan=3`.
- SQLite restoration after runner: deck `6` returned to `100` rows / `100`
  quantity with `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, and `Windborn Muse=1`.
- Result: Angel's Grace is not promoted. The latest trusted candidate improves
  over the immediate `145423` rebaseline but remains below PG023 smoke
  baseline and does not justify apply/rollback/swap.

## Latest Manual 16-Seed Review Checkpoint - 2026-06-21 12:35 -0300

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_151645/summary.json`.
- A `manaloom-battle-strategy-audit.sh --seeds 16 --start-seed 63212310`
  process was still active at read time; this is a checkpoint, not a final
  active-run conclusion.
- Summary: `run_profile=recurring_16_seed`, `run_scope=recurring_full`,
  `invocation_kind=manual_cli`, `seeds_completed=16/16`.
- Final status: `review_required`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`.
- Mandatory divergences:
  `forensic_audit=review_required`, `replay_decision_audit=review_required`,
  and `strategy_audit=review_required`.
- Green gates/tests: target-pressure `pass=16`, table-intent `pass=16`,
  tests `pass=18`.
- Strategy findings: `strategy_review_required_findings=4`,
  `forced_keep_after_bad_mulligan=4`,
  `resource_cost_without_selection_context=1`,
  `spending_unique_color_land=1`, `tutor_no_target=2`.
- Outcome: Lorehold target wins `1/16`, opponents `12/16`; opponent combat to
  Lorehold `310`, to other players `8`.
- Runtime SQLite check at read time: deck `6` is `100` rows / `100` quantity
  with `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, and `Windborn Muse=1`.
- Result: no deck promotion, no PostgreSQL rollback/apply, and no trusted
  learning update from this artifact until the review gates are handled.

## PG023 Oracle-Specific Finisher Contract Rebaseline - 2026-06-21 12:37 -0300

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_152154/summary.json`.
- No `manaloom-battle-strategy-audit` runner was active at final read time.
- Summary:
  `run_profile=pg023_rebaseline_after_oracle_specific_finisher_contract_fix_16_seed`,
  `run_scope=recurring_full`,
  `invocation_kind=codex_pg023_rebaseline_after_oracle_specific_finisher_contract_fix`,
  `seeds_completed=16/16`.
- Final status: `trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`.
- Gate/test summary: target-pressure `pass=16`, table-intent `pass=16`,
  tests `pass=18`, strategy review findings `0`.
- Strategy counts: `forced_keep_after_bad_mulligan=2`, medium severity `2`.
- Outcome: Lorehold target wins `1/16`, opponents `14/16`; opponent combat to
  Lorehold `252`, to other players `2`.
- Runtime SQLite check: deck `6` is `100` rows / `100` quantity with
  `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, and `Windborn Muse=1`.
- Result: review gates from `151645` are cleared, but deck outcome remains
  weak. No PostgreSQL apply/rollback or deck swap is authorized by this run.

## Magus Candidate Over Electroduplicate Blocked - 2026-06-21 13:03 -0300

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_153944/summary.json`.
- Context: `151200` was blocked by event-contract/static plus forensic gates;
  `152154` later cleared those gates for PG023.
- `153944` summary:
  `run_profile=candidate_magus_of_the_moat_for_electroduplicate_16_seed`,
  `run_scope=recurring_full`,
  `invocation_kind=codex_candidate_magus_of_the_moat_for_electroduplicate_16_seed`,
  `seeds_completed=16/16`.
- Final status: `blocked`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`,
  `mandatory_gate_divergences=["strategy_audit=blocked"]`.
- Green side channels: target-pressure `pass=16`, table-intent `pass=16`,
  tests `pass=18`.
- Strategy findings: `spending_last_land=1`,
  `spending_unique_color_land=1`, `forced_keep_after_bad_mulligan=2`;
  severity `high=1`, `medium=3`.
- Outcome: Lorehold target wins `3/16`, opponents `12/16`; opponent combat to
  Lorehold `256`, to other players `7`.
- Runtime SQLite check: deck `6` restored to `100` rows / `100` quantity with
  `Electroduplicate=1`; no focused `Magus of the Moat` row.
- Result: candidate rejected as blocked; no PostgreSQL apply/rollback or deck
  swap is authorized.

## Magus Candidate After Mox Trace Fix - 2026-06-21 13:19 -0300

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_160405/summary.json`.
- `160405` summary:
  `run_profile=candidate_magus_of_the_moat_for_electroduplicate_after_mox_trace_fix_16_seed`,
  `run_scope=recurring_full`,
  `invocation_kind=codex_candidate_magus_of_the_moat_for_electroduplicate_after_mox_trace_fix_16_seed`,
  `seeds_completed=16/16`.
- Final status: `trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`.
- Green gates/tests: target-pressure `pass=16`, table-intent `pass=16`,
  tests `pass=18`.
- Strategy blockers cleared: `strategy_review_required_findings=0`; residual
  signal is `forced_keep_after_bad_mulligan=2`.
- Outcome: Lorehold target wins `3/16`, opponents `12/16`; opponent combat to
  Lorehold `256`, to other players `7`.
- Runtime SQLite check: deck `6` restored to `100` rows / `100` quantity with
  `Electroduplicate=1`; no focused `Magus of the Moat` row.
- Result: candidate is valid evidence but rejected for promotion; no PostgreSQL
  apply/rollback or deck swap is authorized.

## Victory Chimes Rule Fix Rebaseline - 2026-06-21 13:52 -0300

- Latest completed run is
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_164710/summary.json`.
- `run_profile=recurring_16_seed`,
  `run_scope=recurring_full`, `invocation_kind=manual_cli`,
  `seeds_completed=16/16`.
- Final status is `trusted_for_strategy_learning` with
  `battle_replay_final_status_reason=all_mandatory_gates_pass` and
  `mandatory_gate_divergences=[]`.
- Gate/test summary: target-pressure `pass=16`, table-intent `pass=16`,
  tests `pass=18`, strategy review findings `0`.
- Strategy residual: `forced_keep_after_bad_mulligan=2`, medium severity `2`.
- Outcome: Lorehold target wins `2/16`, opponents `13/16`; opponent combat to
  Lorehold `246`, to other players `1`.
- Preceding Victory Chimes-specific run `20260621_164101` was also trusted and
  gate-clean but weaker: Lorehold `1/16`, opponents `14/16`.
- Victory Chimes rule evidence: local reviewed-rule data now marks
  `Victory Chimes` as verified `ramp_permanent`, and the SQLite sync report
  `victory_chimes_reviewed_rule_sqlite_sync_20260621_161900.json` records
  `inserted_or_updated=122` and `deleted_stale_reviewed_rows=1`.
- Focused Victory Chimes regression tests passed (`Ran 3 tests ... OK`).
  The broader reviewed-rule suite still has 2 Top/Scroll Rack failures, which
  remain outside this Victory Chimes closure.
- Runtime SQLite deck check after the final latest: deck `6` is `100/100` with
  `Electroduplicate=1`, `Brainstone=1`, `Victory Chimes=1`, and no focused
  `Magus of the Moat` row.
- Result: Victory Chimes draw/ramp modeling is no longer an active battle
  pending. No PostgreSQL apply/rollback or deck swap is authorized.

## Magus Same-Seed Candidate After Victory Fix - 2026-06-21 14:38 -0300

- Latest completed run is now
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_173334/summary.json`.
- `run_profile=candidate_magus_after_victory_chimes_fix_same_seed_16_seed`,
  `run_scope=recurring_full`,
  `invocation_kind=codex_candidate_magus_after_victory_chimes_fix_same_seed_16_seed`,
  `seeds_completed=16/16`.
- Final status is `trusted_for_strategy_learning` with
  `battle_replay_final_status_reason=all_mandatory_gates_pass` and
  `mandatory_gate_divergences=[]`.
- Gate/test summary: target-pressure `pass=16`, table-intent `pass=16`,
  tests `pass=18`, strategy review findings `0`.
- Strategy residual: `forced_keep_after_bad_mulligan=2`, medium severity `2`.
- Outcome: Lorehold target wins `3/16`, opponents `12/16`; opponent combat to
  Lorehold `256`, to other players `7`.
- Runtime SQLite deck check after `173334`: deck `6` is `100/100` with
  `Electroduplicate=1`, `Brainstone=1`, `Victory Chimes=1`, and no focused
  `Magus of the Moat` row.
- Result: candidate is gate-clean but rejected for promotion; no PostgreSQL
  apply/rollback or deck swap is authorized.

## Runtime Cache Drift After Latest Battle - 2026-06-21 14:42 -0300

- Battle `latest` still points to `20260621_173334`; no newer completed battle
  artifact or active runner was found.
- New local backup:
  `knowledge_db_backup_candidate_magus_sphere_after_victory_fix_20260621_174200.sqlite`.
- Backup focused deck `6` state: `100/100`, `Electroduplicate`,
  `Victory Chimes`.
- Current SQLite focused deck `6` state: `100/100`, `Magus of the Moat`,
  `Sphere of Safety`.
- Reading: the current runtime cache is now an unvalidated Magus+Sphere
  candidate state after the latest completed battle. This is not battle
  validation and does not authorize PostgreSQL apply/rollback or deck swap.

## Magus+Sphere Candidate Review Required - 2026-06-21 14:46 -0300

- Latest completed run is now
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_174142/summary.json`.
- `run_profile=candidate_magus_sphere_after_victory_fix_same_seed_16_seed`,
  `run_scope=recurring_full`,
  `invocation_kind=codex_candidate_magus_sphere_after_victory_fix_same_seed_16_seed`,
  `seeds_completed=16/16`.
- Final status is `review_required` with
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`.
- Mandatory gate divergences:
  `["forensic_audit=review_required","replay_decision_audit=review_required","strategy_audit=review_required"]`.
- Side channels remain green: target-pressure `pass=16`, table-intent
  `pass=16`, tests `pass=18`.
- Strategy findings: `strategy_review_required_findings=1`,
  `forced_keep_after_bad_mulligan=3`, `tutor_no_target=1`, medium severity
  `4`.
- Outcome: Lorehold target wins `5/16`, opponents `11/16`; opponent combat to
  Lorehold `248`, to other players `3`.
- Runtime SQLite deck check after `174142`: deck `6` is `100/100` with
  `Electroduplicate=1`, `Brainstone=1`, `Victory Chimes=1`, and no focused
  `Magus of the Moat` or `Sphere of Safety`.
- Result: Magus+Sphere is rejected as review-required candidate evidence; no
  PostgreSQL apply/rollback or deck swap is authorized.

## Quantity Guard And Clean Candidate Reruns - 2026-06-21 15:32 -0300

- Bug found: `load_deck_cards()` treated `quantity=0` as one copy via
  `row["quantity"] or 1`, contaminating temporary deck-swap simulations.
- Runtime fix: `battle_analyst_v9.py` now skips `quantity <= 0` rows while
  preserving legacy `NULL` quantity as one copy.
- Regression: `battle_card_import_tests.py`
  `test_load_deck_ignores_zero_quantity_rows`.
- Test evidence:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.

Clean rerun evidence:

- `20260621_180442` Magus+Sphere after quantity guard:
  `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  `deck_source_blocker_domains={"none":64}`, tests `pass=18`,
  target-pressure/table-intent `pass=16/16`, Lorehold `5/16`, opponents
  `11/16`.
- `20260621_181316` Magus+Sphere+Wrath:
  gate-clean but worse, Lorehold `4/16`, opponents `12/16`.
- `20260621_181905` Magus+Sphere+Norn's Annex:
  gate-clean, Lorehold `5/16`, opponents `10/16`, one stall, five
  low-confidence mulligan findings.

Battle log proof:

- `20260621_180442/seed_63212311/replay.txt` is a clean Lorehold win by
  elimination. `Sphere of Safety` resolved on turn 15, `Silent Arbiter`
  resolved on turn 16, and Lorehold won on turn 17.

Current reading:

- Loader quantity guard is closed by code and test evidence.
- Magus+Sphere is valid candidate evidence but not enough for deployment.
- Wrath and Norn variants are rejected for now because they do not improve the
  clean Magus+Sphere result.
- No PostgreSQL deploy, rollback, official deck swap, commit, push, stash,
  revert, cleanup, or file deletion was performed.

## Replay HandCards And Survival-Reserve Gate Closure - 2026-06-22 12:10 -0300

- Replay visibility was extended so `replay.txt` records the player's hand as
  `HandCards=[...]` in the mulligan block, turn-start lines, and turn-end
  lines. This closes the observability gap raised for validating whether cards
  in hand were actually being considered.
- Runtime files touched for this closure:
  `battle_analyst_v9.py`, `battle_replay_v10_3.py`,
  `test_battle_replay_v10_3_renderer.py`, and
  `battle_stack_casting_tests.py`.
- Battle-pilot fix: low-life main-phase choices now reserve mana for survival
  response effects such as `Teferi's Protection`/`phase_out` and
  `cannot_lose_turn` unless the spell being considered is itself a survival,
  removal, wipe, or win-line exemption.
- Replay-ledger fix: stack items with cast context now have a recovery guard so
  the audit cannot see a non-triggered spell resolve without a corresponding
  cast ledger.

Test evidence:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.

Gate evidence:

- Focused seed after replay-ledger cleanup:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_120747/summary.json`.
  It is `trusted_for_strategy_learning`, action critic `pass`, no mandatory
  divergences, and tests `pass=18`.
- Full same-seed official window:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_121049/summary.json`.
  It is `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `seeds_completed=16/16`,
  `test_results_status_counts={"pass":18}`, target-pressure/table-intent
  `pass=16/16`, Lorehold `2/16`, opponents `13/16`, one no-winner/stall, and
  opponent combat pressure `303` to Lorehold vs `11` to other players.
- Mandatory gate statuses in `121049`: action critic `pass`, forensic audit
  `pass`, replay decision audit `pass`, strategy audit `pass`, table intent
  `pass`, target pressure `pass`, effect coverage `pass`, event contract
  static `pass`, focused template dispatch `pass`, unknown template backlog
  `pass`.

Current validation reading:

- The replay hand-card request is implemented and covered by renderer tests and
  generated battle artifacts.
- The survival-response pilot bug is closed for the tested failure pattern.
- Remaining open battle/deck issue is strategic, not a broken replay gate:
  `forced_keep_after_bad_mulligan=7` across five low-confidence seeds.
- No PostgreSQL deploy, rollback, official deck swap, commit, push, stash,
  revert, cleanup, or file deletion was performed by this closure.

## Opening Fetch Mulligan Gate Closure - 2026-06-22 12:25 -0300

- Follow-up audit of the `forced_keep_after_bad_mulligan` set found only two
  Lorehold-owned cases: seed `63231114` was a real weak opener, while seed
  `63231121` was a false off-color opening-hand evaluation caused by fetchland
  color fixing not being counted in the mulligan evaluator.
- Runtime correction: `battle_analyst_v9.py` now treats fetchlands as
  `wildcard` fixing inside the opening-hand evaluator only. This does not
  modify global land `source_colors()`, PostgreSQL, SQLite deck rows, or the
  deck list.
- Regression: `battle_turn_flow_tests.py`
  `test_mulligan_treats_fetch_land_as_opening_color_fixing`.

Test evidence:

- Direct post-patch evaluation:
  - `63231121` Lorehold-style hand:
    `keep=True`, `reason=early_card_flow:Esper Sentinel:1`, no
    `off_color_early_hand`.
  - `63231114` Lorehold-style hand remains `keep=False`; its interaction-only
    opener is still a real low-quality hand.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.

Gate evidence:

- Focused proof:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_122423/summary.json`.
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `test_results_status_counts={"pass":18}`,
  strategy findings `0`, Lorehold `1/1`.
- Full window:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_122526/summary.json`.
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `seeds_completed=16/16`,
  `test_results_status_counts={"pass":18}`, target-pressure/table-intent
  `pass=16/16`, Lorehold `2/16`, opponents `13/16`.
- Strategy residue improved from
  `forced_keep_after_bad_mulligan=7` across five seeds to
  `forced_keep_after_bad_mulligan=1` in seed `63231124`; the remaining forced
  keep belongs to Sisay, not Lorehold.

Validation reading:

- The mulligan evaluator bug is closed by code, tests, focused seed evidence,
  and a gate-clean 16-seed rerun.
- This is a battle-pilot/evidence-quality fix, not a deck promotion signal:
  Lorehold remains at `2/16`.
- No PostgreSQL deploy, rollback, official deck swap, commit, push, stash,
  revert, cleanup, or file deletion was performed.

## Survival Defense And Counter-Legality Gate Reading - 2026-06-22 12:48 UTC

Gate changes:

- `replay.txt` hand visibility is confirmed in the latest generated artifacts:
  mulligan, turn-start, and turn-end rows expose `HandCards=[...]`.
- Survival-response reservation now starts at life `15`, preserving live
  `phase_out`/cannot-lose responses before exact lethal.
- At critical life, proactive combat defenses (`attack_tax`, `attack_limit`)
  are prioritized over commander and non-defense casts.
- Counter legality now filters by target mana value. `Mental Misstep` is
  runtime-scoped to mana value `1` and no longer counters `Windborn Muse`.

Latest completed run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_124815/summary.json`
- `run_profile=full_after_survival_defense_counter_legality_16_seed`
- `invocation_kind=codex_full_after_survival_defense_counter_legality`
- `seeds_completed=16/16`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `test_results_status_counts={"pass":18}`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":1}`
- `strategy_low_confidence_seeds=["63231124"]`

Battle outcome:

- Lorehold remains `2/16`; opponents remain `13/16`; one seed has no winner.
- Opponent combat to Lorehold is `316`; opponent combat to other players is
  `13`.
- Focus seed `63231114` proves the fixed sequence: hand visible, Teferi's
  Protection cast during combat damage, Windborn Muse cast/resolved next turn,
  Mental Misstep retained in Thrasios hand, and Lorehold still dying only after
  Rograkh pushes through `2` damage.

Gate interpretation:

- This artifact is trusted for strategy learning.
- The remaining issue is not replay observability, low-life response spending,
  proactive-defense sequencing, or Mental Misstep target legality.
- The deck remains strategically weak under focused multiplayer pressure.
- No PostgreSQL deploy, rollback, official deck swap, commit, push, stash,
  revert, cleanup, or file deletion was performed in this checkpoint.

## PG024 Mental Misstep Registry Gate Reading - 2026-06-22 13:07 UTC

Gate change:

- `Mental Misstep` is no longer a manual runtime waiver.
- PostgreSQL now has a curated verified/auto `card_battle_rules` row with
  `counter_target_cmc=1`.
- The previous broad counter rows are `deprecated`/`disabled`.

Data evidence:

- PostgreSQL postcheck:
  `exact_executable_rule_rows=1`, `broad_enabled_counter_rows=0`.
- SQLite sync:
  `pg_rows_loaded=3`, `sqlite_inserted_or_updated=3`,
  `canonical_snapshot_rows_exported=3193`.
- Runtime resolution:
  `_rule_source=curated`, `_rule_review_status=verified`,
  `_rule_execution_status=auto`,
  `_rule_logical_key=battle_rule_v1:da6a568dbdfeda5d4009574d953db55e`.

Battle evidence:

- Focused:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_130646/summary.json`.
  Trusted, gate-clean, tests `pass=18`.
- Full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_130732/summary.json`.
  Trusted, gate-clean, `seeds_completed=16/16`, tests `pass=18`,
  Lorehold `2/16`, opponents `13/16`.

Gate interpretation:

- The invalid `Mental Misstep` counter legality issue is closed at runtime and
  source-of-truth level.
- The remaining battle problem is deck/strategy under focused table pressure.

## PG025 The One Ring / Orim's Chant Registry Gate Reading - 2026-06-22 15:29 UTC

Gate change:

- `The One Ring` is no longer only a broad PostgreSQL `draw_engine` row.
- `Orim's Chant` is no longer only a broad silence row.
- PostgreSQL, SQLite/Hermes, runtime resolution, and replay artifacts now agree
  on the exact modeled semantics for both cards.

Data evidence:

- PostgreSQL postcheck:
  `one_ring_exact_executable_rule_rows=1`,
  `one_ring_legacy_enabled_draw_engine_rows=0`,
  `orims_chant_exact_executable_rule_rows=1`,
  `orims_chant_legacy_enabled_silence_rows=0`.
- SQLite sync:
  `pg_rows_loaded=6`, `sqlite_inserted_or_updated=6`,
  `canonical_snapshot_rows_exported=3193`.
- Runtime resolution:
  - `The One Ring`:
    `_rule_logical_key=battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1`.
  - `Orim's Chant`:
    `_rule_logical_key=battle_rule_v1:2332a82b6395a065b6516702d3e326c7`.

Battle evidence:

- Controlled full artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_152901/summary.json`.
- `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `seeds_completed=16/16`, tests `pass=18`.
- `seed_63231322/replay.events.jsonl` lines `453-461` prove `The One Ring`
  uses the new PG025 logical key and grants protection from everything.
- `seed_63231314/replay.events.jsonl` lines `533-537` prove kicked
  `Orim's Chant` uses the new PG025 logical key and prevents attack
  declaration.
- `replay.txt` includes `HandCards=[...]` in turn and final summaries.

Gate interpretation:

- The two rule/data defects are closed at source-of-truth and battle-runtime
  level.
- Lorehold deck quality is still unresolved: the comparable controlled matrix
  remains Lorehold `0/16`, opponents `16/16`, with opponent combat pressure
  `296` to Lorehold and `4` to other players.

## PG026 Magus+Sphere Official Deck Gate - 2026-06-22 17:09 UTC

Gate change:

- The Magus+Sphere package is no longer only a temporary candidate. PostgreSQL
  deck `528c877f-f829-4207-95e6-73981776c323` and Hermes SQLite deck `6` now
  contain `Magus of the Moat` and `Sphere of Safety` instead of
  `Electroduplicate` and `Victory Chimes`.
- `replay.txt` now includes the current player hand in opening/mulligan,
  turn-start, turn-end, and final player summaries.

Data evidence:

- PostgreSQL postcheck for PG026 confirmed `Magus of the Moat=1`,
  `Sphere of Safety=1`, `Electroduplicate=0`, `Victory Chimes=0`, and deck
  quantity `100`.
- SQLite direct validation confirmed `Magus of the Moat|1|0`,
  `Sphere of Safety|1|0`, and deck rows/quantity `100/100`.
- SQLite sync report:
  `docs/hermes-analysis/master_optimizer_reports/sync_pg_target_deck_to_hermes_pg026_magus_sphere_20260622_165810.json`.

Battle evidence:

- Artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_170304/summary.json`.
- `run_profile=pg026_magus_sphere_post_deploy_16_seed`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `test_results_status_counts={"pass":18}`.
- `table_intent_statuses={"pass":16}`.
- `target_pressure_statuses={"pass":16}`.
- Lorehold won `6/16`; opponents won `10/16`.

Replay proof:

- `seed_63231314/replay.txt` line `19` shows Lorehold opening
  `HandCards=[Sphere of Safety, Esper Sentinel, Pyroblast, Mana Confluence, Jeska's Will, Birgi, God of Storytelling // Harnfel, Horn of Bounty, Clifftop Retreat]`.
- `seed_63231314/replay.txt` line `142` shows cleanup
  `DiscardedCards=[War Room, Urza's Saga, Drannith Magistrate]` while
  preserving `HandCards=[Sphere of Safety, Pyroblast, Giver of Runes, Get Lost, Flawless Maneuver, Spectator Seating, Deflecting Swat]`.
- `seed_63231314/replay.txt` ends with `Winner: Lorehold (approach)` on turn
  `11` and final `HandCards=[...]` for all players.

Gate interpretation:

- The battle gate is trusted for learning from the new official deck state.
- PG026 is a meaningful improvement over the PG025 official matrix
  (`0/16` to `6/16`), but the deck is still not complete because opponents
  still win `10/16`.
- Next work should analyze the post-PG026 losses in `20260622_170304` before
  another deck/PG change.

## Lorehold Variant Intake And Deck 606 Harness Gate - 2026-06-22 18:17 UTC

Closed/validated harness work:

- Candidate deck selection is now explicit through
  `MANALOOM_BATTLE_TARGET_DECK_ID`.
- `battle_replay_v10_3.py` writes target deck id/provenance in replay
  metadata, so an isolated variant can be tested without mutating official
  deck `6`.
- `replay.txt` includes current hand cards in turn-start, turn-end, cleanup,
  mulligan/opening, and final summaries.
- Action/replay cleanup audits now accept `hand > 7` only when visible board
  state contains a no-maximum-hand-size source such as `Library of Leng`,
  `Reliquary Tower`, or `Thought Vessel`.
- Forensic/event support recognizes the Variant 01 modeled effects
  `equipment_static_attachment`, `damage_wipe_treasure`, and
  `redistribute_life_totals`.
- Land-tutor artifact decision traces now include rejected option scores and
  score gaps when there is more than one target option.

Test evidence:

- `python3 -m py_compile` passed for the changed battle/replay/audit modules.
- `test_battle_replay_v10_3_renderer.py` passed, including
  `test_target_deck_id_env_defaults_validates_and_overrides`.
- `test_battle_action_critic.py` passed, including no-maximum-hand-size
  positive and negative cases.
- `test_replay_decision_auditor_scope.py` passed, including cleanup hand-size
  scope.
- `test_battle_event_contract_static_audit.py` passed with `7 tests passed`.
- `test_battle_forensic_audit_supported_effects.py` passed.
- `test_battle_analyst_v10_3.py` passed, including
  `test_land_tutor_artifact_trace_scores_rejected_options`.
- `test_lorehold_variant_stager.py` passed with `Ran 3 tests`.

Battle evidence:

- Single-seed gate check:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_181641/summary.json`.
  Status `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`.
- Final 16-seed matrix:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_181727/summary.json`.
  Status `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  `seeds_completed=16/16`, tests `pass=18`, action findings `0`, forensic
  findings `{}`, and decision audit severities all `0`.

Deck/source evidence:

- The tested candidate was `deck_id:606`, not official deck `6`.
- `seed_64270208/deck_provenance.json` confirms `target_deck_id=606`,
  `source_kind=sqlite_deck_cards`, valid construction, `100/99/1` quantities,
  no off-color cards, and no singleton violations.

Register reading:

- The remaining result is strategic, not a battle gate blocker.
- Variant 01 can be used as a clean rejected candidate in future deck-learning
  comparisons.

## Deck Card Battle Rule Coherence Gate - 2026-06-22 18:39 UTC

New gate:

- Added a deck-card-wide battle-rule coherence auditor:
  `docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py`.
- Added focused tests:
  `docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`.
- Added workflow/goal contract:
  `docs/hermes-analysis/CARD_BATTLE_RULE_COHERENCE_WORKFLOW_2026-06-22.md`.

Purpose:

- Apply the PG025 `The One Ring` / `Orim's Chant` care level to every card that
  appears in `deck_cards`.
- Detect cards that look covered but still have broad/generic semantics,
  lingering `needs_review` rows, missing oracle hash, missing active rules, or
  non-executable review-only rules.

Read-only baseline command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --limit 120
```

Generated baseline:

- JSON:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_183944.json`.
- Markdown:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_183944.md`.

Baseline result:

- Distinct deck cards audited: `145`.
- `high=134`, `medium=3`, `pass=8`.
- Top finding families:
  - `review_only_or_needs_review_rule=133`.
  - `trusted_rule_without_oracle_hash=99`.
  - `generic_effect_without_model_scope=43`.

Current interpretation:

- This does not prove all high cards are broken in current battle runtime.
- It proves they are not clean enough to be treated as One Ring-level coherent
  inputs for battle learning and deck generation.
- Future card promotion must close this queue with PostgreSQL package evidence,
  SQLite sync, tests, replay/events when battle-relevant, and living-doc updates.

## Deck Card Battle Rule Coherence Gate Review - 2026-06-22 18:47 UTC

Reviewed/adjusted gate logic:

- The initial gate was safe but over-prioritized land-only
  `needs_review`/`review_only` rows as `high`, putting generic land backlog in
  the same queue tier as battle-changing effects such as `copy_spell`,
  `board_wipe`, `draw_engine`, `counter`, `silence_opponents`, and `tutor`.
- The auditor now keeps land-only backlog actionable as `medium` with
  `impact_tier=land_or_mana_base`, while battle-changing effects sort first as
  `impact_tier=battle_critical` or `battle_support`.
- This is a queue/prioritization correction only. It did not promote a card,
  did not change PostgreSQL, and did not mark any rule as trusted.

Evidence:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py` passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py` passed with `Ran 5 tests`.
- New baseline command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --limit 200
```

Generated reviewed baseline:

- JSON:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_184733.json`.
- Markdown:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_184733.md`.

Reviewed baseline result:

- Distinct deck cards audited: `145`.
- `high=97`, `medium=40`, `pass=8`.
- Top finding families remain:
  - `review_only_or_needs_review_rule=133`.
  - `trusted_rule_without_oracle_hash=99`.
  - `generic_effect_without_model_scope=43`.
- Top cards now start with battle-critical effects: `Austere Command`,
  `Blasphemous Act`, `Boros Charm`, `Deflecting Swat`,
  `Flawless Maneuver`, `Land Tax`, `Lightning Greaves`,
  `Lorehold, the Historian`, `Past in Flames`, `Path to Exile`,
  `Reverberate`, `Sensei's Divining Top`, `Swords to Plowshares`,
  `Teferi's Protection`, `Valakut Awakening // Valakut Stoneforge`, and
  `Wheel of Fortune`.

Current interpretation:

- The workflow is coherent as a conservative card-by-card gate, with the
  corrected queue priority.
- The remaining caveat is intentional: this auditor reads Hermes SQLite
  `deck_cards`/`battle_card_rules` as the local queue surface. Any durable fix
  still must be sourced from PostgreSQL, applied through precheck/apply/
  postcheck/rollback evidence, then synced back into SQLite/Hermes.

## PG028 Austere Command Coherence Closure - 2026-06-22 19:10 UTC

Scope:

- Closed the first card from the deck-card battle-rule coherence queue:
  `Austere Command`.
- PostgreSQL was treated as source of truth. Hermes SQLite was refreshed from
  PostgreSQL before the audit cycle and again after the PG028 apply.
- No deck swap, rollback, stage, commit, or push was performed in this cycle.

Rule/runtime changes:

- Disabled the old broad curated `board_wipe/selective` row and the generated
  `needs_review`/`review_only` shadow row as `deprecated`/`disabled`.
- Added executable rule
  `battle_rule_v1:5f19a608b87445bcc5c7ebb7ad96eb64` with oracle hash
  `bce631c9a75d6856dd8c0d7de442b47f` and
  `battle_model_scope=austere_command_choose_two_destroy_modes_v1`.
- Added runtime support for modal destroy-board-wipe rules with
  `modal_destroy_modes` and `choose_modes`, while preserving the legacy
  creature-only board-wipe path for rules without modal metadata.

Evidence:

- PG package:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_battle_rule_pg028_precheck_20260622_190701.sql`,
  `docs/hermes-analysis/master_optimizer_reports/austere_command_battle_rule_pg028_apply_20260622_190701.sql`,
  `docs/hermes-analysis/master_optimizer_reports/austere_command_battle_rule_pg028_postcheck_20260622_190701.sql`,
  `docs/hermes-analysis/master_optimizer_reports/austere_command_battle_rule_pg028_rollback_20260622_190701.sql`.
- PG postcheck: `exact_executable_rule_rows=1`,
  `legacy_enabled_board_wipe_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg028_austere_command_20260622_190701.json`.
- Tests:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Tests:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_pg028_focused_events_20260622_190701.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/austere_command_pg028_focused_decision_trace_20260622_190701.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/austere_command_pg028_focused_replay_summary_20260622_190701.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_190930.json`
  and `.md`.

Reading:

- `Austere Command` is closed for the current coherence gate and moved to
  `pass`.
- The next card in the queue is `Blasphemous Act`.

## PG029 Blasphemous Act Coherence Closure - 2026-06-22 19:29 UTC

Scope:

- Closed the second card from the deck-card battle-rule coherence queue:
  `Blasphemous Act`.
- PostgreSQL remained the durable source of truth. Hermes SQLite was refreshed
  from PostgreSQL before the cycle and again after the PG029 apply.
- No deck swap, rollback, stage, commit, or push was performed in this cycle.

Rule/runtime changes:

- Disabled the old broad curated `board_wipe` row and the generated
  `needs_review`/`review_only` shadow row as `deprecated`/`disabled`.
- Added executable rule
  `battle_rule_v1:56271789d639ef390213dbc90059e4d2` with oracle hash
  `826022a579db4551b45ad35e4cfab973` and
  `battle_model_scope=blasphemous_act_damage_13_each_creature_v1`.
- Added runtime support for `damage_wipe`: lethal damage to each creature
  using the existing simplified toughness threshold, preserving indestructible
  and high-toughness survivors.
- The card's `{1}` cost reduction per creature is stored as
  `annotation_only` metadata. This cycle proves the damage resolution, not a
  dynamic generic-cost executor.

Evidence:

- PG package:
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_battle_rule_pg029_precheck_20260622_192517.sql`,
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_battle_rule_pg029_apply_20260622_192517.sql`,
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_battle_rule_pg029_postcheck_20260622_192517.sql`,
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_battle_rule_pg029_rollback_20260622_192517.sql`.
- PG precheck: `card_rows=1`, `expected_oracle_hash_rows=1`,
  `exact_executable_rule_rows=0`, `legacy_enabled_wipe_rows=2`.
- PG apply: backup table
  `manaloom_deploy_audit.pg029_blasphemous_act_battle_rule_20260622_192517`
  captured `2` rows; apply inserted `1` active rule and updated `2` old rows.
- PG postcheck: `exact_executable_rule_rows=1`,
  `legacy_enabled_wipe_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg029_blasphemous_act_20260622_192517.json`.
- Tests:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Tests:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_pg029_focused_events_20260622_192517.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_pg029_focused_replay_summary_20260622_192517.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_192856.json`
  and `.md`.

Reading:

- `Blasphemous Act` is closed for the current coherence gate and moved to
  `pass`.
- The next card in the queue is `Boros Charm`.

## PG030 Boros Charm Coherence Closure - 2026-06-22 19:42 UTC

Scope:

- Closed the third card from the deck-card battle-rule coherence queue:
  `Boros Charm`.
- PostgreSQL remained the durable source of truth. Hermes SQLite was refreshed
  from PostgreSQL before the cycle and again after the PG030 apply.
- No deck swap, rollback, stage, commit, or push was performed in this cycle.

Rule/runtime changes:

- Disabled the old broad curated `modal_boros_charm` row and the generated
  `needs_review`/`review_only` `indestructible` shadow row as
  `deprecated`/`disabled`.
- Added executable rule
  `battle_rule_v1:32605a838d7a519f44eaa0899d2c40bf` with oracle hash
  `98a7be829075118b499a7c283a23501f` and
  `battle_model_scope=boros_charm_choose_one_damage_indestructible_double_strike_v1`.
- Updated runtime semantics so the indestructible mode affects all permanents
  you control until EOT and the double-strike mode affects one target creature
  until EOT.
- Added `modal_boros_charm_resolved` event output with selected mode and
  PG030 rule provenance.

Evidence:

- PG package:
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_battle_rule_pg030_precheck_20260622_193818.sql`,
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_battle_rule_pg030_apply_20260622_193818.sql`,
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_battle_rule_pg030_postcheck_20260622_193818.sql`,
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_battle_rule_pg030_rollback_20260622_193818.sql`.
- PG precheck: `card_rows=1`, `expected_oracle_hash_rows=1`,
  `exact_executable_rule_rows=0`,
  `legacy_enabled_modal_or_shadow_rows=2`.
- PG apply: backup table
  `manaloom_deploy_audit.pg030_boros_charm_battle_rule_20260622_193818`
  captured `2` rows; apply inserted `1` active rule and updated `2` old rows.
- PG postcheck: `exact_executable_rule_rows=1`,
  `legacy_enabled_modal_or_shadow_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg030_boros_charm_20260622_193818.json`.
- Tests:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Tests:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_pg030_focused_events_20260622_193818.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_pg030_focused_replay_summary_20260622_193818.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_194227.json`
  and `.md`.

Reading:

- `Boros Charm` is closed for the current coherence gate and moved to `pass`.
- The next card in the queue is `Deflecting Swat`.

## PG031 Deflecting Swat Coherence Closure - 2026-06-22 19:56 UTC

Scope:

- Closed the fourth card from the deck-card battle-rule coherence queue:
  `Deflecting Swat`.
- PostgreSQL remained the durable source of truth. Hermes SQLite was refreshed
  from PostgreSQL before the cycle and again after the PG031 apply.
- No deck swap, rollback, stage, commit, or push was performed in this cycle.

Rule/runtime changes:

- Disabled the old broad curated `redirect_removal` row and the generated
  `needs_review`/`review_only` `draw_cards` shadow row as
  `deprecated`/`disabled`.
- Added executable rule
  `battle_rule_v1:bac48343654a53205d790a8268bd2631` with oracle hash
  `a34c89817f87f32bedfb3d66a5bdc672` and
  `battle_model_scope=deflecting_swat_control_commander_free_redirect_target_spell_or_ability_v1`.
- Updated runtime payment semantics so `redirect_removal` rules can use
  `alternative_cost={0}` when their controller controls a commander.
- Updated redirect target selection to prefer opponent-controlled legal
  targets before self-controlled fallback targets.
- Updated threat scoring so `damage_wipe` is treated as a board-wipe threat
  for protection responses.

Evidence:

- PG package:
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_battle_rule_pg031_precheck_20260622_195126.sql`,
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_battle_rule_pg031_apply_20260622_195126.sql`,
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_battle_rule_pg031_postcheck_20260622_195126.sql`,
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_battle_rule_pg031_rollback_20260622_195126.sql`.
- PG precheck: `card_rows=1`, `expected_oracle_hash_rows=1`,
  `exact_executable_rule_rows=0`,
  `legacy_enabled_redirect_or_shadow_rows=2`.
- PG apply: backup table
  `manaloom_deploy_audit.pg031_deflecting_swat_battle_rule_20260622_195126`
  captured `2` rows; apply inserted `1` active rule and updated `2` old rows.
- PG postcheck: `exact_executable_rule_rows=1`,
  `legacy_enabled_redirect_or_shadow_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg031_deflecting_swat_20260622_195126.json`.
- Tests:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Tests:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_pg031_focused_events_20260622_195126.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_pg031_focused_replay_summary_20260622_195126.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_195607.json`
  and `.md`.

Reading:

- `Deflecting Swat` is closed for the current coherence gate and moved to
  `pass`.
- The next card in the queue is `Flawless Maneuver`.

## PG032 Flawless Maneuver Coherence Closure - 2026-06-22 20:10 UTC

Scope:

- Closed the fifth card from the deck-card battle-rule coherence queue:
  `Flawless Maneuver`.
- PostgreSQL remained the durable source of truth. Hermes SQLite was refreshed
  from PostgreSQL before the cycle and again after the PG032 apply.
- No deck swap, rollback, stage, commit, or push was performed in this cycle.

Rule/runtime changes:

- Disabled the old broad curated `indestructible` row and the generated
  `needs_review`/`review_only` `indestructible` shadow row as
  `deprecated`/`disabled`.
- Added executable rule
  `battle_rule_v1:73622071c1ad89267708f914a0729bf2` with oracle hash
  `fa955216fa827bf75c5b79dcbdb4b97e` and
  `battle_model_scope=flawless_maneuver_control_commander_free_creatures_indestructible_until_eot_v1`.
- Updated stack-protection response casting so protection instants can use
  oracle-specific alternative costs when the rule provides them.
- Added `protection_resolved` event provenance for generic
  `indestructible` protection resolution.

Evidence:

- PG package:
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_battle_rule_pg032_precheck_20260622_200215.sql`,
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_battle_rule_pg032_apply_20260622_200215.sql`,
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_battle_rule_pg032_postcheck_20260622_200215.sql`,
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_battle_rule_pg032_rollback_20260622_200215.sql`.
- PG precheck: `card_rows=1`, `expected_oracle_hash_rows=1`,
  `exact_executable_rule_rows=0`,
  `legacy_enabled_indestructible_or_shadow_rows=2`.
- PG apply: backup table
  `manaloom_deploy_audit.pg032_flawless_maneuver_battle_rule_20260622_200215`
  captured `2` rows; apply inserted `1` active rule and updated `2` old rows.
- PG postcheck: `exact_executable_rule_rows=1`,
  `legacy_enabled_indestructible_or_shadow_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg032_flawless_maneuver_20260622_200215.json`.
- Tests:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Tests:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_events_20260622_200215.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_replay_summary_20260622_200215.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_201035.json`
  and `.md`.

Reading:

- `Flawless Maneuver` is closed for the current coherence gate and moved to
  `pass`.
- The next card in the queue is `Land Tax`.
- PG029 `Blasphemous Act` still has its cost reduction as `annotation_only`;
  only the 13-damage creature wipe executor is implemented and proved.

## PG037 Path to Exile - Closed 2026-06-22 21:25 UTC

Status:

- Closed for the current card battle-rule coherence gate.
- Auditor status: `pass`.
- Deck coverage: decks `6` and `606`, quantity `2`.

Rule:

- `logical_rule_key=battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd`.
- `oracle_hash=861c960a37be744e45f13200349e2532`.
- `battle_model_scope=path_to_exile_creature_exile_basic_land_compensation_annotation_v1`.
- Executed behavior: instant creature removal sends the target to exile.
- Non-executed rider: target-controller basic-land search/tapped battlefield
  compensation is `annotation_only`.

Validation:

- PostgreSQL precheck/apply/postcheck passed.
- Hermes SQLite synced from PostgreSQL after apply.
- Runtime selected the PG037 rule from `knowledge.db`.
- Focused unit test passed:
  `test_path_to_exile_exiles_creature_with_pg037_rule_provenance`.
- Full battle regression suite passed.
- Auditor rerun
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_212554.json`
  reports `Path to Exile` as `pass`.

Replay evidence:

- `docs/hermes-analysis/master_optimizer_reports/path_to_exile_pg037_focused_events_20260622_212057.jsonl`.
- `docs/hermes-analysis/master_optimizer_reports/path_to_exile_pg037_focused_replay_summary_20260622_212057.md`.
- `removal_resolved` event includes
  `rule_logical_key=battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd`,
  `destination=exile`, and
  `basic_land_compensation_status=annotation_only`.

Caveat carried forward:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; no dynamic cost-reduction executor was claimed.

## PG035 Lorehold, the Historian Coherence Closure - 2026-06-22 20:52 UTC

Scope:

- Closed the eighth card from the deck-card battle-rule coherence queue:
  `Lorehold, the Historian`.
- PostgreSQL remained the durable source of truth. Hermes SQLite was refreshed
  from PostgreSQL before the cycle and again after the PG035 apply.
- No deck swap, rollback execution, stage, commit, or push was performed in
  this cycle.

Rule/runtime changes:

- Added executable rule
  `battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4` with oracle hash
  `f1b6d4f38a533e56f0efb5a3f1547214` and
  `battle_model_scope=lorehold_opponent_upkeep_miracle_v1`.
- Corrected the durable rule to match oracle structure: `cmc=5.0`,
  `flying=true`, `haste=true`, miracle `{2}`, and opponent-upkeep rummage.
- Disabled the legacy `commander` row, the old `cmc=4.0` passive row, and the
  generated `needs_review`/`review_only` `draw_engine` shadow row as
  `deprecated`/`disabled`.
- Updated local reviewed-runtime cache for Lorehold so Hermes sync keeps the
  new PG035 PostgreSQL rule.
- Added Lorehold rule provenance to `lorehold_upkeep_rummage` and
  `lorehold_upkeep_rummage_skipped` replay events.

Evidence:

- PG package:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_battle_rule_pg035_precheck_20260622_204549.sql`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_battle_rule_pg035_apply_20260622_204549.sql`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_battle_rule_pg035_postcheck_20260622_204549.sql`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_battle_rule_pg035_rollback_20260622_204549.sql`.
- PG precheck: `card_rows=4`, `distinct_oracle_ids=1`,
  `expected_oracle_hash_rows=4`, `exact_executable_rule_rows=0`,
  `legacy_enabled_lorehold_rows=3`,
  `trusted_executable_without_oracle_hash_rows=2`.
- PG apply: backup table
  `manaloom_deploy_audit.pg035_lorehold_historian_battle_rule_20260622_204549`
  captured `3` rows; apply inserted `1` active rule and updated `3` old rows.
- PG postcheck: `exact_executable_rule_rows=1`,
  `legacy_enabled_lorehold_rows=0`,
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg035_lorehold_historian_20260622_204549.json`.
- Tests:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py docs/hermes-analysis/manaloom-knowledge/scripts/reviewed_battle_card_rules.py`
  passed.
- Tests:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_pg035_focused_events_20260622_204549.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_pg035_focused_decision_trace_20260622_204549.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_pg035_focused_replay_summary_20260622_204549.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_205233.json`
  and `.md`.

Reading:

- `Lorehold, the Historian` is closed for the current coherence gate and moved
  to `pass`.
- The next card in the queue is `Past in Flames`.
- The runtime model remains an explicit approximation for opponent-upkeep
  rummage and miracle windows; it does not claim every Magic policy edge.
- PG029 `Blasphemous Act` still has its cost reduction as `annotation_only`;
  only the 13-damage creature wipe executor is implemented and proved.

## PG033 Land Tax Coherence Closure - 2026-06-22 20:25 UTC

Scope:

- Closed the sixth card from the deck-card battle-rule coherence queue:
  `Land Tax`.
- PostgreSQL remained the durable source of truth. Hermes SQLite was refreshed
  from PostgreSQL before the cycle and again after the PG033 apply.
- No deck swap, rollback, stage, commit, or push was performed in this cycle.

Rule/runtime changes:

- Disabled the old broad curated `passive` row and the generated
  `needs_review`/`review_only` `tutor any` shadow row as
  `deprecated`/`disabled`.
- Added executable rule
  `battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef` with oracle hash
  `83b074e38da3e6c4eb6ec3e7568c914b` and
  `battle_model_scope=land_tax_upkeep_opponent_more_lands_basic_land_tutor_to_hand_v1`.
- Added runtime support for the Land Tax upkeep trigger: if any live opponent
  controls more lands than the controller, move up to three basic land cards
  from library to hand.
- Added `land_tax_trigger_resolved`/`land_tax_trigger_skipped` event
  provenance and a `land_tax_upkeep_tutor` decision trace.

Evidence:

- PG package:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_battle_rule_pg033_precheck_20260622_201417.sql`,
  `docs/hermes-analysis/master_optimizer_reports/land_tax_battle_rule_pg033_apply_20260622_201417.sql`,
  `docs/hermes-analysis/master_optimizer_reports/land_tax_battle_rule_pg033_postcheck_20260622_201417.sql`,
  `docs/hermes-analysis/master_optimizer_reports/land_tax_battle_rule_pg033_rollback_20260622_201417.sql`.
- PG precheck: `card_rows=1`, `expected_oracle_hash_rows=1`,
  `exact_executable_rule_rows=0`,
  `legacy_enabled_passive_or_shadow_rows=2`.
- PG apply: backup table
  `manaloom_deploy_audit.pg033_land_tax_battle_rule_20260622_201417`
  captured `2` rows; apply inserted `1` active rule and updated `2` old rows.
- PG postcheck: `exact_executable_rule_rows=1`,
  `legacy_enabled_passive_or_shadow_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg033_land_tax_20260622_201417.json`.
- Tests:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Tests:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_pg033_focused_events_20260622_201417.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/land_tax_pg033_focused_decision_trace_20260622_201417.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/land_tax_pg033_focused_replay_summary_20260622_201417.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_202458.json`
  and `.md`.

Reading:

- `Land Tax` is closed for the current coherence gate and moved to `pass`.
- The next card in the queue is `Lightning Greaves`.
- Reveal and shuffle are tracked as event metadata in the focused proof; this
  deterministic replay does not randomize library order after the search.
- PG029 `Blasphemous Act` still has its cost reduction as `annotation_only`;
  only the 13-damage creature wipe executor is implemented and proved.

## PG034 Lightning Greaves Coherence Closure - 2026-06-22 20:36 UTC

Scope:

- Closed the seventh card from the deck-card battle-rule coherence queue:
  `Lightning Greaves`.
- PostgreSQL remained the durable source of truth. Hermes SQLite was refreshed
  from PostgreSQL before the cycle and again after the PG034 apply.
- No deck swap, rollback, stage, commit, or push was performed in this cycle.

Rule/runtime changes:

- Disabled two old curated `equipment_haste_shroud` rows and the generated
  `needs_review`/`review_only` `indestructible` shadow row as
  `deprecated`/`disabled`.
- Added executable rule
  `battle_rule_v1:5ea7f2a8349a93ea46e05b60ee8cdaac` with oracle hash
  `4a4c71d3cc58637cf00a3d7fe2331353` and
  `battle_model_scope=lightning_greaves_auto_attach_haste_shroud_equip_0_v1`.
- Updated local reviewed-runtime cache for Lightning Greaves so Hermes sync no
  longer filters out the new active PostgreSQL rule.
- Added rule provenance to `equipment_attached` and `equipment_unattached`
  replay events.

Evidence:

- PG package:
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_battle_rule_pg034_precheck_20260622_202908.sql`,
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_battle_rule_pg034_apply_20260622_202908.sql`,
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_battle_rule_pg034_postcheck_20260622_202908.sql`,
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_battle_rule_pg034_rollback_20260622_202908.sql`.
- PG precheck: `card_rows=1`, `expected_oracle_hash_rows=1`,
  `exact_executable_rule_rows=0`,
  `legacy_enabled_equipment_or_shadow_rows=3`.
- PG apply: backup table
  `manaloom_deploy_audit.pg034_lightning_greaves_battle_rule_20260622_202908`
  captured `3` rows; apply inserted `1` active rule and updated `3` old rows.
- PG postcheck: `exact_executable_rule_rows=1`,
  `legacy_enabled_equipment_or_shadow_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg034_lightning_greaves_retry_20260622_202908.json`.
- Tests:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py docs/hermes-analysis/manaloom-knowledge/scripts/reviewed_battle_card_rules.py`
  passed.
- Tests:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_pg034_focused_events_20260622_202908.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_pg034_focused_replay_summary_20260622_202908.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_203604.json`
  and `.md`.

Reading:

- `Lightning Greaves` is closed for the current coherence gate and moved to
  `pass`.
- The next card in the queue is `Lorehold, the Historian`.
- The runtime model remains the documented battle approximation
  `auto_attach_best_creature_on_resolution`; it does not claim full Equipment
  attach/retarget timing.
- PG029 `Blasphemous Act` still has its cost reduction as `annotation_only`;
  only the 13-damage creature wipe executor is implemented and proved.

## PG036 Past in Flames Coherence Closure - 2026-06-22 21:11 UTC

Scope:

- Closed the ninth card from the deck-card battle-rule coherence queue:
  `Past in Flames`.
- PostgreSQL remained the durable source of truth. Hermes SQLite was refreshed
  from PostgreSQL before the cycle and again after the PG036 apply.
- No deck swap, rollback, stage, commit, or push was performed in this cycle.

Rule/runtime changes:

- Disabled the old curated generic `recursion` row and generated
  `needs_review`/`review_only` `recursion` shadow row as
  `deprecated`/`disabled`.
- Added executable rule
  `battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be` with oracle hash
  `12f293d8d746fbc4e5ba80828919dec5` and
  `battle_model_scope=past_in_flames_graveyard_instants_sorceries_flashback_until_eot_v1`.
- Added runtime executor `graveyard_flashback_grant`: instant/sorcery cards in
  the controller graveyard gain `flashback_cost` equal to their `mana_cost`
  until end of turn.
- Added `graveyard_flashback_granted` replay event and
  `flashback_granted_by`/`flashback_granted_rule_key` provenance on
  `flashback_cast`.

Evidence:

- PG package:
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_battle_rule_pg036_precheck_20260622_210425.sql`,
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_battle_rule_pg036_apply_20260622_210425.sql`,
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_battle_rule_pg036_postcheck_20260622_210425.sql`,
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_battle_rule_pg036_rollback_20260622_210425.sql`.
- PG precheck: `card_rows=1`, `distinct_oracle_ids=1`,
  `expected_oracle_hash_rows=1`, `exact_executable_rule_rows=0`,
  `legacy_enabled_recursion_rows=2`,
  `trusted_executable_without_oracle_hash_rows=1`.
- PG apply: backup table
  `manaloom_deploy_audit.pg036_past_in_flames_battle_rule_20260622_210425`
  captured `2` rows; apply inserted `1` active rule and updated `2` old rows.
- PG postcheck: `exact_executable_rule_rows=1`,
  `legacy_enabled_recursion_rows=0`,
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg036_past_in_flames_20260622_210425.json`.
- Tests:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py`
  passed.
- Tests:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Tests:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`
  passed (`Ran 5 tests`).
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_pg036_focused_events_20260622_210425.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_pg036_focused_replay_summary_20260622_210425.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_211117.json`
  and `.md`.

Reading:

- `Past in Flames` is closed for the current coherence gate and moved to
  `pass`.
- The next card in the queue is `Path to Exile`.
- The runtime model covers the temporary flashback grant and provenance; full
  priority/timing policy for every possible flashback spell is not claimed.
- PG029 `Blasphemous Act` still has its cost reduction as `annotation_only`;
  only the 13-damage creature wipe executor is implemented and proved.

## PG038 Reverberate - Closed 2026-06-22 21:43 UTC

Status:

- Closed for the deck-card battle-rule coherence gate.
- PostgreSQL source rule:
  `battle_rule_v1:0269136edf067f696c8576740b720e14`.
- Oracle hash:
  `cbae05dee4261e3ed5412fd5f3591c17`.
- Model scope:
  `reverberate_copy_stack_instant_or_sorcery_new_targets_annotation_v1`.

Validation:

- Oracle text validated from PostgreSQL card row:
  `Copy target instant or sorcery spell. You may choose new targets for the copy.`
- Old active/shadow rows were corrected in PostgreSQL, then Hermes SQLite was
  synced from PostgreSQL.
- Runtime selected the PG038 rule from `knowledge.db`.
- Focused unit test proved `Reverberate` casts in response to a sorcery on the
  stack, creates a non-cast copy, resolves the copy for the responder, and
  leaves the original spell to resolve for the original controller.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/reverberate_pg038_focused_events_20260622_213615.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/reverberate_pg038_focused_replay_summary_20260622_213615.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_215028.json`
  reports `Reverberate` as `pass`.

Gate result:

- `high=86`, `medium=39`, `pass=20`.
- The next card in the queue is `Sensei's Divining Top`.

Caveats:

- `Reverberate` `may_choose_new_targets` is preserved as
  `choose_new_targets_status=annotation_only`; dynamic target reassignment is
  not implemented by PG038.
- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG047 Archaeomancer's Map - Closed 2026-06-23 00:17 UTC

Status:

- Closed for the deck-card battle-rule coherence gate.
- PostgreSQL source rule:
  `battle_rule_v1:69acc8f6ed179a5a32bef08190cd747e`.
- Oracle hash:
  `22b82ca6bbef42371227bc38a9a546b5`.
- Model scope:
  `basic_plains_etb_plus_opponent_land_catchup_v2`.

Validation:

- Oracle text validated from PostgreSQL card row:
  `When this artifact enters, search your library for up to two basic Plains cards, reveal them, put them into your hand, then shuffle.`
  and
  `Whenever a land an opponent controls enters, if that player controls more lands than you, you may put a land card from your hand onto the battlefield.`
- PostgreSQL ruling checked: the opponent-land trigger only resolves if that
  player still controls more lands than the Map controller as the trigger tries
  to resolve.
- PG047 inserted one oracle-hashed curated `ramp_engine` rule with
  `trigger_condition=opponent_controls_more_lands_than_you` and
  `trigger_rechecks_on_resolution=true`.
- PG047 disabled the legacy trusted no-hash/no-scope row and the two generated
  `needs_review`/`review_only` shadow rows.
- Runtime now checks the active land player's land count before putting a land
  from hand, and rechecks the same condition on trigger resolution.
- PG postcheck:
  `oracle_hashed_archaeomancers_map_rows=1`,
  `legacy_or_shadow_enabled_rows=0`,
  `generated_review_only_shadow_rows=0`, and
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite was resynced from PostgreSQL:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg047_archaeomancers_map_20260623_001244.json`.
- Focused unit coverage:
  `test_archaeomancers_map_opponent_land_trigger_requires_controller_behind_on_lands`
  and
  `test_archaeomancers_map_opponent_land_trigger_skips_when_controller_not_behind`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_pg047_focused_events_20260623_001244.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_pg047_focused_replay_summary_20260623_001244.md`.
- The focused replay proves the ETB basic Plains tutor, the successful
  catch-up land put when the opponent has more lands, and the skipped trigger
  when land counts are equal. Each material event carries the PG047
  `rule_logical_key` and `rule_oracle_hash`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_001717.json`
  reports `Archaeomancer's Map` as `pass`.

Gate result:

- `high=78`, `medium=39`, `pass=28`.
- The next card in the queue is `Blind Obedience`.

Caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG048 Blind Obedience - Closed 2026-06-23 00:35 UTC

Status:

- Closed for the deck-card battle-rule coherence gate.
- PostgreSQL source rule:
  `battle_rule_v1:40f23fcea3b7955bacd550a9090c6872`.
- Oracle hash:
  `4e62bff316f784c1b468b9e53146d2aa`.
- Model scope:
  `opponent_artifact_creature_enter_tapped_extort_annotation_v1`.

Validation:

- Oracle text validated from PostgreSQL card row:
  `Extort (Whenever you cast a spell, you may pay {W/B}. If you do, each opponent loses 1 life and you gain that much life.)`
  and `Artifacts and creatures your opponents control enter tapped.`
- PostgreSQL rulings checked for extort payment timing, no targeting, and
  life-gain amount. Extort remains `annotation_only`; no dynamic optional
  hybrid-mana trigger executor was promoted.
- PG048 inserted one oracle-hashed curated `passive` rule with
  `opponents_artifacts_creatures_enter_tapped=true` and
  `extort_execution_status=annotation_only`.
- PG048 disabled the legacy trusted no-hash `passive` row and the generated
  `draw_engine` `needs_review`/`review_only` shadow row.
- Runtime now applies the static enter-tapped source on normal permanent entry
  paths for opponent-controlled artifact or creature permanents.
- PG postcheck:
  `oracle_hashed_blind_obedience_rows=1`,
  `legacy_or_shadow_enabled_rows=0`,
  `generated_review_only_shadow_rows=0`, and
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite was resynced from PostgreSQL:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg048_blind_obedience_20260623_003029.json`.
- Focused unit coverage:
  `test_blind_obedience_taps_opponent_artifacts_and_creatures_on_entry`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_pg048_focused_events_20260623_003029.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_pg048_focused_replay_summary_20260623_003029.md`.
- The focused replay proves an opponent creature and opponent artifact enter
  tapped, while the controller's own artifact does not enter tapped from its
  own Blind Obedience. The `static_enter_tapped_applied` events carry the
  PG048 `rule_logical_key` and `rule_oracle_hash`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_003552.json`
  reports `Blind Obedience` as `pass`.

Gate result:

- `high=77`, `medium=40`, `pass=28`.
- The next card in the queue is `Borrowed Knowledge`.

Caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG049 Deck 6 L2 Hash-Only Batch - Closed 2026-06-23 00:49 UTC

Status:

- Closed for the deck 6 L2 hash-only lane.
- Cards included: `Crawlspace`, `Ghostly Prison`, and
  `Valakut Awakening // Valakut Stoneforge`.
- No runtime behavior changed; no replay was required.

Validation:

- The auditor now supports `--deck-id`, allowing separate reports for official
  Lorehold deck `6` and variant deck `606`.
- PostgreSQL oracle/type validation:
  - `Crawlspace`: `Artifact`, oracle hash
    `57fcd38030641ceb36bbcf1a6dcbc6c8`.
  - `Ghostly Prison`: `Enchantment`, oracle hash
    `5725b39ca4bb7c5e8e4bebf0d246be13`.
  - `Valakut Awakening // Valakut Stoneforge`: `Instant`, oracle hash
    `22b42fcc181b7aed71f78b2e1e51e887`.
- `cards.card_faces_json` is not populated for these rows in PostgreSQL; the
  Valakut MDFC back-face metadata remains represented in the active
  `mdfc_land_face` rule payload.
- PG049 updated four active curated/verified/auto rows with oracle hashes and
  deprecated one disabled generated Valakut `draw_cards` shadow row.
- PG049 did not change `effect_json`, executor dispatch, or battle behavior.
- PG postcheck:
  `crawlspace_hashed_rows=1`,
  `ghostly_prison_hashed_rows=1`,
  `valakut_hashed_rows=2`,
  `target_trusted_missing_hash_rows=0`, and
  `valakut_generated_review_only_shadow_rows=0`.
- SQLite was resynced from PostgreSQL:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg049_deck6_l2_hash_only_20260623_004614.json`.
- Focused test:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`.

Auditor result:

- Deck 6 before:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_004446.json`
  reported `high=41`, `medium=33`, `pass=26`.
- Deck 6 after:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_004857.json`
  reports `high=41`, `medium=30`, `pass=29`.
- Deck 606 separate report after sync:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_20260623_004857.json`
  reports `high=43`, `medium=17`, `pass=21`.

Gate result:

- Removed from deck 6 queue: `Crawlspace`, `Ghostly Prison`, and
  `Valakut Awakening // Valakut Stoneforge`.
- Next recommended lane: deck 6 `L1` land/mana-base, split simple mana lands
  from utility/fetch lands with real battle effects.

Caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG046 Approach of the Second Sun Coherence Closure - 2026-06-23 00:02 UTC

Status:

- Closed for the deck-card battle-rule coherence gate.
- PostgreSQL source rule:
  `battle_rule_v1:ed74fb069b6c1d635392d907804a1d98`.
- Oracle hash:
  `0838960b80a282fb4508532f7bae8c2b`.
- Model scope:
  `approach_second_cast_win_v2`.

Validation:

- Oracle text and rulings were validated from PostgreSQL. Relevant rulings
  confirmed that a countered first Approach still counts, a copied spell does
  not count, and the second Approach must be cast from hand.
- PG046 inserted one oracle-hashed curated `approach` rule and disabled the
  two legacy trusted no-hash rows plus the generated `needs_review`/
  `review_only` shadow row.
- PG postcheck:
  `oracle_hashed_approach_second_cast_rows=1`,
  `legacy_or_shadow_enabled_rows=0`,
  `generated_review_only_shadow_rows=0`, and
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite was resynced from PostgreSQL:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg046_approach_second_sun_20260622_235039.json`.
- Focused unit coverage:
  `test_approach_of_the_second_sun_counts_countered_first_cast_and_second_cast_wins`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_pg046_focused_events_20260622_235039.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_pg046_focused_replay_summary_20260622_235039.md`.
- The focused replay proves copied Approach does not increment the cast ledger,
  the first countered cast from hand increments Approach count to `1`, the
  second cast from hand increments it to `2`, no second-cast life gain occurs,
  the second spell resolves to `graveyard`, and `game_won` fires with
  `reason=approach`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_000228.json`
  reports `Approach of the Second Sun` as `pass`.

Gate result:

- `high=79`, `medium=39`, `pass=27`.
- The next card in the queue is `Archaeomancer's Map`.

Caveats:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG039 Sensei's Divining Top - Closed 2026-06-22 22:01 UTC

Status:

- Closed for the deck-card battle-rule coherence gate.
- PostgreSQL source rule:
  `battle_rule_v1:70c8478871f352b46cee1af296117951`.
- Oracle hash:
  `f2c5ac0f52963cd710470adc25cc6d7c`.
- Model scope:
  `senseis_top_reorder_draw_lorehold_first_draw_miracle_v1`.

Validation:

- Oracle text validated from PostgreSQL card row:
  `{1}: Look at the top three cards of your library, then put them back in any order. {T}: Draw a card, then put this artifact on top of its owner's library.`
- Three old/shadow rows were disabled in PostgreSQL, then Hermes SQLite was
  synced from PostgreSQL after aligning the reviewed runtime cache.
- Runtime selected the PG039 rule from `knowledge.db`.
- Focused unit test proved the Top reorder line sets
  `Approach of the Second Sun` as Lorehold's first draw and emits PG039
  provenance on `topdeck_manipulation_activated`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/senseis_top_pg039_focused_events_20260622_215306.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/senseis_top_pg039_focused_decision_trace_20260622_215306.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/senseis_top_pg039_focused_replay_summary_20260622_215306.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_220121.json`
  reports `Sensei's Divining Top` as `pass`.

Gate result:

- `high=85`, `medium=39`, `pass=21`.
- The next card in the queue is `Swords to Plowshares`.

Caveats:

- Generic activated draw policy remains `annotation_only`; PG039 executes only
  the top-three reorder and the restricted Lorehold first-draw miracle
  draw-put-self line.
- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG040 Swords to Plowshares - Closed 2026-06-22 22:22 UTC

Status:

- Closed for the deck-card battle-rule coherence gate.
- PostgreSQL source rule:
  `battle_rule_v1:379008f3f03f94258292123453e3041c`.
- Oracle hash:
  `702f566e95dd477f5cf5a551e41e9df8`.
- Model scope:
  `swords_to_plowshares_creature_exile_life_equal_power_v1`.

Validation:

- Oracle text validated from PostgreSQL card row:
  `Exile target creature. Its controller gains life equal to its power.`
- Two old rows were disabled in PostgreSQL: the curated generic executable row
  without `oracle_hash`/scope and the generated `needs_review`/`review_only`
  shadow row.
- Runtime selected the PG040 rule from `knowledge.db`.
- Focused unit test proved that Swords exiles the target creature and gives
  its controller life equal to target power while emitting PG040 provenance on
  `removal_resolved`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_pg040_focused_events_20260622_221254.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_pg040_focused_replay_summary_20260622_221254.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_222210.json`
  reports `Swords to Plowshares` as `pass`.

Gate result:

- `high=84`, `medium=39`, `pass=22`.
- The next card in the queue is `Teferi's Protection`.

Caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG041 Teferi's Protection - Closed 2026-06-22 22:41 UTC

Status:

- Closed for the deck-card battle-rule coherence gate.
- PostgreSQL source rule:
  `battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a`.
- Oracle hash:
  `bdc0faecf4420dc6162c7e72e98cc0eb`.
- Model scope:
  `teferis_protection_life_lock_protection_all_permanents_phase_out_self_exile_v1`.

Validation:

- Oracle text validated from PostgreSQL card row:
  `Until your next turn, your life total can't change and you gain protection from everything. All permanents you control phase out. ... Exile Teferi's Protection.`
- Two old rows were disabled in PostgreSQL: the curated generic executable
  `phase_out` row without `oracle_hash`/scope and the generated
  `needs_review`/`review_only` shadow row.
- Runtime selected the PG041 rule from `knowledge.db`.
- Focused unit test proved all permanents including a land phase out, life
  total changes are prevented, protection from everything is active, and
  Teferi's Protection exiles itself while emitting PG041 provenance.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_pg041_focused_events_20260622_223850.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_pg041_focused_replay_summary_20260622_223850.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_224124.json`
  reports `Teferi's Protection` as `pass`.

Gate result:

- `high=83`, `medium=39`, `pass=23`.
- The next card in the queue is `Valakut Awakening // Valakut Stoneforge`.

Caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG042 Valakut Awakening // Valakut Stoneforge - Closed 2026-06-22 23:01 UTC

Status:

- Closed for the deck-card battle-rule coherence gate.
- PostgreSQL source rule:
  `battle_rule_v1:6e1f3b876822abafe1de47610f46858d`.
- Oracle hash:
  `22b42fcc181b7aed71f78b2e1e51e887`.
- Model scope:
  `bottom_then_draw_plus_one_mdfc_land_v1`.

Validation:

- Oracle text validated from PostgreSQL card row:
  `Put any number of cards from your hand on the bottom of your library, then draw that many cards plus one.`
- PostgreSQL rulings checked: putting zero cards on bottom draws one card, and
  the number of cards to bottom is chosen as Valakut Awakening resolves.
- PG042 updated the split-name rule and front-face alias with the PostgreSQL
  oracle hash, then disabled the two legacy no-scope/no-hash curated rows and
  the generated `draw_cards` `needs_review`/`review_only` shadow row.
- Runtime selected the PG042 split-name rule from `knowledge.db`.
- Focused unit test:
  `test_valakut_awakening_split_name_emits_pg042_rule_provenance`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_pg042_focused_events_20260622_225355.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_pg042_focused_replay_summary_20260622_225355.md`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_230104.json`
  reports `Valakut Awakening // Valakut Stoneforge` as `pass`.

Gate result:

- `high=82`, `medium=39`, `pass=24`.
- The next card in the queue is `Wheel of Fortune`.

Caveats:

- PG042 proves the instant hand-filter executor: bottom chosen cards, then draw
  that many plus one. The MDFC land-face metadata remains attached for
  split-name lookup, but this cycle does not claim a land-play/tapped-red-mana
  executor for `Valakut Stoneforge`.
- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG043 Wheel of Fortune - Closed 2026-06-22 23:26 UTC

Status:

- Closed for the deck-card battle-rule coherence gate.
- PostgreSQL source rule:
  `battle_rule_v1:f8bdb05cc883fda55628d6928c5562d3`.
- Oracle hash:
  `c37cd579d8132efac0c2118608f6f001`.
- Model scope:
  `multiplayer_discard_draw_v1`.

Validation:

- Oracle text validated from PostgreSQL card row:
  `Each player discards their hand, then draws seven cards.`
- PG043 inserted the oracle-hashed curated wheel rule, then disabled the
  legacy no-hash/no-scope curated `draw_cards` row and the generated
  `needs_review`/`review_only` shadow row.
- Runtime selected the PG043 rule from `knowledge.db`.
- Focused unit test proved `Wheel of Fortune` resolves as multiplayer
  discard-hand/draw-seven and emits PG043 provenance on `wheel_resolved`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_pg043_focused_events_20260622_231859.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_pg043_focused_replay_summary_20260622_231859.md`.
- The focused replay includes `rule_logical_key`,
  `rule_oracle_hash`, participant discard/draw counts, and a Smothering Tithe
  payoff creating `7` Treasure tokens from opponent draws.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_232608.json`
  reports `Wheel of Fortune` as `pass`.

Gate result:

- `high=81`, `medium=39`, `pass=25`.
- The next card in the queue is `Aetherflux Reservoir`.

Caveats:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG044 Valakut Awakening Hash Refresh - Closed 2026-06-22 23:26 UTC

Status:

- Corrective closure for a PostgreSQL metadata regression found by the
  post-PG043 auditor.
- PostgreSQL source rules refreshed:
  `battle_rule_v1:6e1f3b876822abafe1de47610f46858d` and
  `battle_rule_v1:245b8d2627720fadfd7a30464d07605a`.
- Oracle hash:
  `22b42fcc181b7aed71f78b2e1e51e887`.

Validation:

- PG044 did not change Valakut battle behavior. It restored durable
  PostgreSQL metadata: `review_status=active`, `execution_status=auto`, and
  `oracle_hash` on the full-name and front-face alias rules.
- The generated Valakut `draw_cards` shadow was moved from
  `needs_review`/`disabled` to `deprecated`/`disabled`.
- PG postcheck: full-name hash row `1`, alias hash row `1`,
  generated review-only shadow `0`, trusted executable without hash `0`.
- SQLite was resynced from PostgreSQL:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg044_valakut_hash_refresh_20260622_232411.json`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_232608.json`
  reports `Valakut Awakening // Valakut Stoneforge` as `pass`.

Caveat:

- PG044 still does not claim a land-play or tapped-red-mana executor for
  `Valakut Stoneforge`; the MDFC land face remains metadata for split-name
  lookup.

## PG045 Aetherflux Reservoir - Closed 2026-06-22 23:40 UTC

Status:

- Closed for the deck-card battle-rule coherence gate.
- PostgreSQL source rule:
  `battle_rule_v1:3147dc90542c79e439ca1f77df02e4e5`.
- Oracle hash:
  `ea5327899fb66a2d583e80e8ca12d9b2`.
- Model scope:
  `spell_cast_lifegain_pay_50_damage_annotation_v1`.

Validation:

- Oracle text validated from PostgreSQL card row:
  `Whenever you cast a spell, you gain 1 life for each spell you've cast this turn.`
  and `Pay 50 life: This artifact deals 50 damage to any target.`
- PG045 inserted the oracle-hashed curated `aetherflux_reservoir` rule, then
  disabled the legacy no-hash/no-scope curated `finisher` row and the
  generated `needs_review`/`review_only` shadow row.
- PG postcheck:
  `oracle_hashed_aetherflux_lifegain_rows=1`,
  `legacy_or_shadow_enabled_rows=0`,
  `generated_review_only_shadow_rows=0`,
  `trusted_finisher_without_model_scope_rows=0`, and
  `trusted_executable_without_oracle_hash_rows=0`.
- SQLite was resynced from PostgreSQL:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg045_aetherflux_reservoir_20260622_233656.json`.
- Focused unit coverage:
  `test_aetherflux_reservoir_uses_oracle_hashed_spell_cast_lifegain_rule`.
- Focused replay:
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_pg045_focused_events_20260622_233656.jsonl`,
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_pg045_focused_replay_summary_20260622_233656.md`.
- The focused replay includes `rule_logical_key`,
  `rule_oracle_hash`, `aetherflux_reservoir_resolved`, and
  `trigger_resolved` lifegain events for `1` then `2` life; no
  `damage_resolved` event is emitted.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_234015.json`
  reports `Aetherflux Reservoir` as `pass`.

Gate result:

- `high=80`, `medium=39`, `pass=26`.
- The next card in the queue is `Approach of the Second Sun`.

Caveats:

- Aetherflux Reservoir's spell-cast lifegain trigger is executable. Its
  `Pay 50 life: deal 50 damage` activated ability remains `annotation_only`;
  PG045 does not add a dynamic life-payment activation executor.
- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG050 Deck 6 L1A Land Model Cleanup - Closed 2026-06-23 01:05 UTC

Status:

- Closed for the deck-card battle-rule coherence gate for `11` official
  Lorehold deck `6` land/mana-base cards.
- Cards:
  `Ancient Den`, `Ancient Tomb`, `Command Tower`, `Gemstone Caverns`,
  `Great Furnace`, `Hall of Heliod's Generosity`, `Inventors' Fair`,
  `Plateau`, `Sunbaked Canyon`, `Urza's Saga`, and `War Room`.

Validation:

- PostgreSQL oracle/type checked for every card in the batch.
- Existing trusted land models were preserved; no `effect_json` or runtime
  executor behavior was changed.
- PG050 added oracle hashes to `20` trusted curated rows, aligned `5` active
  trusted rows to the deck `6` printing when the prior row used a different
  printing with the same `oracle_id`, and disabled `11` generated
  `needs_review` / `review_only` shadows.
- PG postcheck:
  `generated_review_only_rows=0`, `trusted_missing_hash_rows=0`,
  `trusted_hash_mismatch_rows=0`,
  `active_card_id_mismatch_same_oracle_rows=0`,
  `active_card_id_mismatch_unknown_or_mismatch_oracle_rows=0`,
  `generated_disabled_or_deprecated_rows=11`, and `backup_rows=31`.
- SQLite was resynced from PostgreSQL:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg050_deck6_l1a_land_model_cleanup_20260623_010026.json`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`.
- Auditor rerun:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_010510.json`
  reports all 11 included cards as `pass`.

Gate result:

- Deck 6 moved from `high=41`, `medium=30`, `pass=29` to
  `high=41`, `medium=19`, `pass=40`.
- Deck 606, measured separately after the same PG sync, reports
  `high=43`, `medium=13`, `pass=25`.

Replay:

- No new replay/event artifact was generated because PG050 is metadata and
  shadow cleanup only. Runtime utility-land behavior was covered by the
  existing focused unit suite.

Remaining risk:

- The remaining L1 land/mana-base backlog is `19` cards. Fetchlands and
  lands with ETB/life-loss/surveil/conditional behavior are not closed by this
  batch.
- The note about `Blasphemous Act` cost reduction `{1}` per creature is an
  audit cue, not a closing premise. Revalidate oracle/PG/runtime when that card
  returns to the queue.

## PG051 Deck 6 L1B Non-Fetch Land Mana Batch - Closed 2026-06-23 01:25 UTC

Status:

- Closed `11` official Lorehold deck `6` non-fetch land/mana-base cards:
  `Battlefield Forge`, `City of Brass`, `Clifftop Retreat`, `Elegant Parlor`,
  `Inspiring Vantage`, `Mana Confluence`, `Rugged Prairie`,
  `Sacred Foundry`, `Spectator Seating`, `Sunbillow Verge`, and
  `Sundown Pass`.
- Excluded and still open:
  `Arid Mesa`, `Bloodstained Mire`, `Flooded Strand`, `Marsh Flats`,
  `Prismatic Vista`, `Scalding Tarn`, `Windswept Heath`, and
  `Wooded Foothills`.

Evidence:

- PG051 precheck:
  `deck_target_cards=11`, `fetchland_names_in_target=0`,
  `target_rule_rows=22`, `generated_review_only_rows=11`,
  `trusted_missing_hash_rows=11`, `trusted_without_scope_rows=11`,
  `trusted_without_produces_rows=11`, and no active card-id mismatches.
- PG apply created backup table
  `manaloom_deploy_audit.pg051_deck6_l1b_nonfetch_land_mana_20260623_011438`
  with `22` rows, updated `11` curated trusted rules, and disabled `11`
  generated review-only shadows.
- PG postcheck:
  `generated_review_only_rows=0`, `trusted_missing_hash_rows=0`,
  `trusted_hash_mismatch_rows=0`, `trusted_without_scope_rows=0`,
  `trusted_without_produces_rows=0`, `curated_l1b_family_rows=11`,
  `generated_disabled_or_deprecated_rows=11`, and `backup_rows=22`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg051_deck6_l1b_nonfetch_land_mana_20260623_011438.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l1b_nonfetch_land_mana_pg051_focused_events_20260623_012230.jsonl`.
- Focused event assertions covered `11` rule resolutions plus `3`
  `land_played` events with `rule_logical_key` and `rule_oracle_hash`.
- Tests passed:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`.

Gate result:

- Deck 6 moved from `high=41`, `medium=19`, `pass=40` to
  `high=41`, `medium=9`, `pass=50` after PG051.
- Remaining L1 open cards are the eight fetchlands listed above.

## PG052 Valakut Awakening Hash-Only Repair - Closed 2026-06-23 01:25 UTC

Status:

- Closed `Valakut Awakening // Valakut Stoneforge` for missing hash on the
  already verified PG042 runtime rule.
- No `effect_json` or runtime behavior changed.

Evidence:

- The first PG052 precheck attempt exposed a CTE-scope error after printing
  metrics; no apply ran before correction.
- Corrected precheck:
  `deck_target_cards=1`, `target_rule_rows=3`, `active_curated_rows=1`,
  `trusted_missing_hash_rows=1`, and no active card-id mismatches.
- PG apply created backup table
  `manaloom_deploy_audit.pg052_valakut_awakening_hash_only_20260623_012000`
  with `3` rows and updated `1` active curated rule hash.
- PG postcheck:
  `trusted_missing_hash_rows=0`, `trusted_hash_mismatch_rows=0`, and
  `backup_rows=3`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg052_valakut_hash_only_20260623_012000.json`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`.

Final auditor result:

- Deck 6:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_012130.json`
  reports `high=41`, `medium=8`, `pass=51`.
- Deck 606:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_20260623_012130.json`
  reports `high=43`, `medium=8`, `pass=30`.

## PG054 Deck 6 L6 Silence-Lock Batch - Closed 2026-06-23 01:36 UTC

Status:

- Closed `Silence` and `Grand Abolisher` for the current battle-rule coherence
  gate.
- `Drannith Magistrate` and `Ranger-Captain of Eos` were intentionally kept
  open because their current trusted rows do not fully model their real oracle
  effects.

Evidence:

- PG054 precheck:
  `deck_target_cards=2`, `target_rule_rows=5`, `active_curated_rows=3`,
  `trusted_missing_hash_rows=3`, `generated_review_only_rows=2`,
  `silence_legacy_active_rows=1`, `target_active_runtime_rows=2`, and no
  active card-id mismatches.
- PG apply created backup table
  `manaloom_deploy_audit.pg054_deck6_l6_silence_lock_20260623_013119`
  with `5` rows, updated `2` curated trusted rules, and disabled `3`
  legacy/shadow rows.
- PG postcheck:
  `active_curated_rows=2`, `trusted_missing_hash_rows=0`,
  `trusted_hash_mismatch_rows=0`, `trusted_without_scope_rows=0`,
  `generated_review_only_rows=0`, `silence_legacy_active_rows=0`,
  `target_active_runtime_rows=2`, `disabled_or_deprecated_rows=3`, and
  `backup_rows=5`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg054_deck6_l6_silence_lock_20260623_013119.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l6_silence_lock_pg054_focused_events_20260623_013520.jsonl`.
- The focused events prove:
  `Silence` resolves with
  `rule_logical_key=battle_rule_v1:74b210b77b004a677906e0216d44e445` and
  `rule_oracle_hash=a0ca3c09a7db091c435ab31adb9c1780`, blocking an opponent
  counter response until EOT; `Grand Abolisher` casts/resolves with
  `rule_logical_key=battle_rule_v1:4df98360e4467568504b19219c8ba5d0` and
  `rule_oracle_hash=57c98b7e49853c5e0afff526da052e3c`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`.

Gate result:

- Deck 6 moved from `high=41`, `medium=8`, `pass=51` to
  `high=39`, `medium=8`, `pass=53`.
- Deck 606 stayed at `high=43`, `medium=8`, `pass=30`.

Caveat:

- Grand Abolisher's activated-ability lock is stored as `annotation_only`.
  PG054 proves the current opponent spell-cast lock runtime path, not a full
  activated-ability-lock executor.

## PG057 Deck 6 L3A Artifact Mana-Rock Batch - Closed 2026-06-23 01:50 UTC

Status:

- Closed `7` official Lorehold deck `6` L3 artifact mana rocks:
  `Arcane Signet`, `Boros Signet`, `Fellwar Stone`, `Mana Vault`,
  `Mox Amber`, `Sol Ring`, and `Talisman of Conviction`.
- Excluded and still open:
  `Lotus Petal`, `Ruby Medallion`, `Birgi, God of Storytelling // Harnfel, Horn of Bounty`,
  `Jeska's Will`, `Rite of Flame`, `Seething Song`, `Smothering Tithe`,
  `Storm-Kiln Artist`, `Professional Face-Breaker`, and
  `Unexpected Windfall`.

Evidence:

- PG057 precheck:
  `deck_target_cards=7`, `target_rule_rows=18`,
  `target_runtime_rows=7`, `generated_review_only_rows=7`,
  `curated_shadow_rows_to_disable=4`, `trusted_missing_hash_rows=11`,
  `trusted_without_scope_rows=7`,
  `target_runtime_rows_without_produces=3`,
  `active_card_id_mismatch_same_oracle_rows=2`,
  `active_card_id_mismatch_unknown_or_mismatch_oracle_rows=0`, and
  `target_names_missing_rules=0`.
- PG apply created backup table
  `manaloom_deploy_audit.pg055_deck6_l3a_artifact_mana_rocks_20260623_014032`
  with `18` rows, updated `7` trusted runtime rows, and disabled `11`
  generated/legacy shadows.
- PG postcheck:
  `trusted_missing_hash_rows=0`, `trusted_hash_mismatch_rows=0`,
  `trusted_without_scope_rows=0`, `target_runtime_rows_without_produces=0`,
  `target_runtime_rows_bad_mana_produced=0`,
  `target_runtime_rows_bad_scope=0`, `generated_review_only_rows=0`,
  `active_curated_shadow_rows=0`, `active_card_id_mismatch_same_oracle_rows=0`,
  `active_card_id_mismatch_unknown_or_mismatch_oracle_rows=0`,
  `disabled_or_deprecated_rows=11`, and `backup_rows=18`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg055_deck6_l3a_artifact_mana_rocks_20260623_014032.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3a_artifact_mana_rocks_pg055_focused_events_20260623_014032.jsonl`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`.
- Tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`.

Gate result:

- Deck 6 moved from `high=39`, `medium=8`, `pass=53` to
  `high=32`, `medium=8`, `pass=60`.
- Deck 606 moved from `high=43`, `medium=8`, `pass=30` after PG054 to
  `high=38`, `medium=8`, `pass=35` after the shared PG057 rule sync.

Caveats:

- Boros Signet activation cost is modeled as net one mana, not a full tap/cost
  activation executor.
- Mana Vault untap and damage clauses remain annotation-only.
- Talisman life loss remains annotation-only.
- Mox Amber's legendary-permanent gate is executable, but exact produced-color
  choice remains abstracted.
- Numbering note: the physical SQL/sync/event artifacts and PG backup table use
  a `pg055_deck6_l3a_artifact_mana_rocks...` prefix because this package was
  generated and applied before the parallel `PG055 Lorehold Variant 03` register
  entry and separate `PG056` deck 608 package artifacts appeared in this
  worktree. This batch is tracked logically as `PG057`.
- A separate code-path fix in the same validation run corrected
  `Dragon's Approach` name normalization in its existing graveyard-copy test.
  The later `PG056 Deck 608 Dragon Package` promoted the PostgreSQL rule
  provenance and scope for `Dragon's Approach` and `Thrumming Stone`.

## PG056 Deck 608 Dragon Package - Closed 2026-06-23 01:58 UTC

Status:

- Closed `Dragon's Approach` and `Thrumming Stone` for deck `608`.
- Corrected the simulator model so `Dragon's Approach` deals fixed `3` damage
  to each opponent and uses five graveyard copies only for the optional Dragon
  tutor cost.
- No deck swap and no `deck_cards` mutation was executed.

Evidence:

- PG056 precheck:
  `target_cards=2`, `target_rule_rows=4`, `trusted_active_rows=1`,
  `trusted_missing_hash_rows=1`, `trusted_without_scope_rows=1`,
  `generated_review_only_rows=3`, `thrumming_trusted_active_rows=0`, and no
  active card-id mismatches.
- PG apply created backup table
  `manaloom_deploy_audit.pg056_deck608_dragons_approach_thrumming_20260623_015223`
  with `4` rows, updated `2` trusted runtime rows, and disabled `2`
  generated/shadow rows.
- PG postcheck:
  `trusted_active_rows=2`, `trusted_missing_hash_rows=0`,
  `trusted_hash_mismatch_rows=0`, `trusted_without_scope_rows=0`,
  `generated_review_only_rows=0`, `disabled_or_deprecated_rows=2`, and
  `backup_rows=4`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg056_deck608_dragons_approach_thrumming_20260623_015223.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck608_dragons_approach_thrumming_pg056_focused_events_20260623_015223.jsonl`.
- Deck 608 auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck608_20260623_015223.json`
  reports `high=38`, `medium=11`, `pass=19`.

Gate result:

- Deck 608 moved from `high=43`, `medium=11`, `pass=14` to `high=38`,
  `medium=11`, `pass=19`.
- `Dragon's Approach` and `Thrumming Stone` are both `pass` in the current
  deck `608` coherence audit.

Caveats:

- Thrumming Stone is modeled as same-name `ripple 4` free-cast support for
  spells the controller casts. The current gate does not claim a complete
  Magic-equivalent priority stack implementation.
- The Dragon tutor picks a Dragon creature from library into battlefield using
  the current simulator abstraction. Search/shuffle and all replacement effects
  remain outside this focused gate.

## PG058 Deck 6 L3B Simple Red Ritual Batch - Closed 2026-06-23 02:11 UTC

Status:

- Closed `Rite of Flame` and `Seething Song` for deck `6`.
- Applied the validated PostgreSQL package in this cycle after precheck matched
  the expected target row counts.
- No deck swap and no `deck_cards` mutation was executed.

Evidence:

- Precheck output:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_pg058_precheck_20260623_020031.out`.
- PG postcheck:
  `target_runtime_rows=2`, `trusted_missing_hash_rows=0`,
  `trusted_hash_mismatch_rows=0`, `trusted_without_scope_rows=0`,
  `target_runtime_rows_without_produces=0`,
  `target_runtime_rows_bad_mana_produced=0`,
  `target_runtime_rows_bad_scope=0`, `generated_review_only_rows=0`,
  `active_curated_shadow_rows=0`, `disabled_or_deprecated_rows=3`, and
  `backup_rows=5`.
- Apply output:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_pg058_apply_20260623_020031.out`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg058_deck6_l3b_simple_red_rituals_20260623_020031.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_pg058_focused_events_20260623_020031.jsonl`.
- Deck 6 auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_021017.json`
  reports `high=30`, `medium=8`, `pass=62`.
- Deck 606 auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_20260623_021017.json`
  reports `high=38`, `medium=8`, `pass=35`.

Gate result:

- Deck 6 moved from `high=32`, `medium=8`, `pass=60` to `high=30`,
  `medium=8`, `pass=62`.
- Deck 606 stayed at `high=38`, `medium=8`, `pass=35`.
- Global deck-card audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_021017.json`
  reports `high=116`, `medium=23`, `pass=66`.
- `Rite of Flame` and `Seething Song` are both `pass` in the current deck `6`
  coherence audit.

Caveats:

- `Rite of Flame` graveyard named-copy scaling remains annotation-only.
- Red color production is provenance metadata; the current executor adds ritual
  mana into the generic pool abstraction.

## PG059 Deck 6 L2 Hash-Only Regression Repair - Closed 2026-06-23 02:18 UTC

Status:

- Applied external package
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_regression_repair_pg059_apply_20260623_021840.sql`.
- Scope was hash-only for already trusted runtime rows:
  `Fellwar Stone`, `Mana Vault`, `Mox Amber`, `Seething Song`, `Silence`,
  `Talisman of Conviction`, `Valakut Awakening`, and
  `Valakut Awakening // Valakut Stoneforge`.
- No `effect_json`, executor, deck list, or shadow state change was intended in
  this package.

Evidence:

- Apply output:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_regression_repair_pg059_apply_20260623_021840.out`
  reports `UPDATE 8` and `COMMIT`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_regression_repair_pg059_postcheck_20260623_021840.out`
  reports `target_runtime_rows=8`,
  `target_runtime_missing_hash_rows=0`,
  `target_runtime_hash_mismatch_rows=0`,
  `target_runtime_live_hash_mismatch_rows=0`,
  `target_runtime_bad_effect_rows=0`,
  `target_runtime_bad_scope_rows=0`, and `backup_rows=23`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg059_deck6_l2_hash_regression_repair_20260623_021840.json`.

## PG059 Sync Metadata Guard/Restore - Closed 2026-06-23 02:29 UTC

Status:

- Added a sync guard in
  `docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py`
  so same-key curated/manual upserts preserve existing PG-only metadata and do
  not blank existing `oracle_hash` when reviewed JSON lacks that field.
- Applied central-auditor follow-up package
  `docs/hermes-analysis/master_optimizer_reports/pg059_sync_metadata_restore_apply_20260623_022328.sql`.
- Scope was metadata-only for:
  `Fellwar Stone`, `Mana Vault`, `Mox Amber`, `Seething Song`, `Silence`,
  `Talisman of Conviction`, and
  `Valakut Awakening // Valakut Stoneforge`.
- The package restored the missing oracle-runtime annotation keys on six rows;
  `Valakut Awakening // Valakut Stoneforge` remained hash-confirmed only.

Evidence:

- Precheck output:
  `docs/hermes-analysis/master_optimizer_reports/pg059_sync_metadata_restore_precheck_20260623_022328.out`
  reported `target_cards=7`, `target_rule_rows=7`,
  `target_missing_hash_rows=0`, `target_hash_mismatch_rows=0`,
  `target_missing_effect_patch_rows=6`, and
  `target_card_id_missing_rows=0`.
- Apply output:
  `docs/hermes-analysis/master_optimizer_reports/pg059_sync_metadata_restore_apply_20260623_022328.out`
  reports `INSERT 0 7`, `UPDATE 7`, and `COMMIT`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg059_sync_metadata_restore_postcheck_20260623_022328.out`
  reports `target_missing_hash_rows=0`,
  `target_hash_mismatch_rows=0`,
  `target_missing_effect_patch_rows=0`, and `backup_rows=7`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg059_sync_metadata_restore_20260623_022328.json`.
- Guard test:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py -v`
  passed `8` tests.

Current audit cut after sync:

- Deck `6`:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_023130.json`
  reports `high=30`, `medium=8`, `pass=62`.
- Deck `606`:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_20260623_023130.json`
  reports `high=38`, `medium=8`, `pass=35`.
- Deck `607`:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_20260623_022929.json`
  reports `high=50`, `medium=16`, `pass=28`.
- Deck `608`:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck608_20260623_022929.json`
  reports `high=38`, `medium=11`, `pass=19`.

Superseded/incomplete external artifact note:

- `deck6_l3b_simple_red_rituals_metadata_pg060_*_20260623_022418` was not
  accepted as an applied package in this register: its apply output stops before
  `UPDATE`/`COMMIT`, its postcheck output is empty, and live PG inspection found
  no backup table
  `manaloom_deploy_audit.pg060_deck6_l3b_simple_red_rituals_metadata_20260623_022418`.
- The missing Seething Song metadata covered by that attempted PG060 is closed
  by the central-auditor PG059 sync metadata restore above and by the PG061
  confirmation package below.

## PG061 Deck 6 L3B Simple Red Ritual Metadata Confirmation - Closed 2026-06-23 02:31 UTC

Status:

- Accepted external package
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_metadata_pg061_apply_20260623_022418.sql`.
- The package captures a durable backup for current `Rite of Flame` and
  `Seething Song` rows after the aborted PG060 attempt, then reapplies the
  intended metadata idempotently.
- No executor, deck list, or shadow row state changed.

Evidence:

- Apply output:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_metadata_pg061_apply_20260623_022418.out`
  reports `SELECT 5`, `UPDATE 2`, and `COMMIT`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_metadata_pg061_postcheck_20260623_022418.out`
  reports `target_runtime_rows=2`, `target_hash_mismatch_rows=0`,
  `target_bad_effect_rows=0`, `target_bad_mana_rows=0`,
  `target_bad_scope_rows=0`, `target_missing_runtime_scope_rows=0`,
  `target_missing_mana_color_status_rows=0`, and `backup_rows=5`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg061_deck6_l3b_simple_red_rituals_metadata_20260623_023130.json`.

Final cycle tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py -v`
  passed `8` tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`
  passed `6` tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed, including the existing `Blasphemous Act` damage-model test and the
  PG058 ritual provenance tests.

Final cycle audit:

- Required global auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_023224.json`
  reports `total_cards=205`, `high=116`, `medium=23`, `pass=66`.
- Deck `6`:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_023130.json`
  reports `total_cards=100`, `high=30`, `medium=8`, `pass=62`.
- Deck `606`:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_20260623_023130.json`
  reports `total_cards=81`, `high=38`, `medium=8`, `pass=35`.

Gate note:

- PG061 is a metadata/provenance confirmation package only. No new focused
  event file was generated because no executor behavior changed after PG058;
  runtime evidence remains the PG058 focused ritual event gate.

## PG062 Deck 6 L1 Fetchland Cleanup - Closed 2026-06-23 02:46 UTC

Status:

- Closed the deck `6` L1 fetchland land/mana-base queue for:
  `Arid Mesa`, `Bloodstained Mire`, `Flooded Strand`, `Marsh Flats`,
  `Prismatic Vista`, `Scalding Tarn`, `Windswept Heath`, and
  `Wooded Foothills`.
- This is a conservative cleanup/provenance package: trusted runtime remains
  `effect=land`; fetch activation clauses are `annotation_only`.
- No deck swap and no `deck_cards` mutation was executed.

Evidence:

- PG precheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l1_fetchlands_pg062_precheck_20260623_024200.out`
  reports `deck_target_cards=8`, `target_rule_rows=16`,
  `trusted_runtime_rows=8`, `trusted_missing_hash_rows=8`,
  `trusted_without_scope_rows=8`, `generated_review_only_rows=8`,
  `target_bad_type_rows=0`, `target_faces_json_rows=0`,
  `target_missing_fetch_oracle_rows=0`, and `backup_table_exists=0`.
- PG apply:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l1_fetchlands_pg062_apply_20260623_024200.out`
  reports `SELECT 16`, `UPDATE 8`, `UPDATE 8`, and `COMMIT`.
- PG postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l1_fetchlands_pg062_postcheck_20260623_024200.out`
  reports `trusted_missing_hash_rows=0`,
  `trusted_hash_mismatch_rows=0`, `trusted_missing_scope_rows=0`,
  `active_review_only_or_needs_review_rows=0`,
  `disabled_generated_shadow_rows=8`, and `backup_rows=16`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg062_deck6_l1_fetchlands_20260623_024200.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l1_fetchlands_pg062_focused_events_20260623_024200.jsonl`.

Gate result:

- The focused event proves `8` trusted fetchland rows with
  `battle_model_scope=fetchland_land_play_with_activation_annotation_v1` and
  `8` disabled generated shadows.
- The runtime sample proves `Bloodstained Mire` participates in current
  name-based opening-hand fetchland color fixing; dynamic fetch activation
  remains `annotation_only`.
- Deck `6` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_024200.json`
  reports `high=30`, `pass=70`.
- Deck `606` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_20260623_024200.json`
  reports `high=38`, `medium=7`, `pass=36`.
- Global auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_024200.json`
  reports `high=116`, `medium=15`, `pass=74`.

Tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`
  passed `7` tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py -v`
  passed `8` tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.

Caveat:

- This gate does not claim Magic-equivalent fetchland activation sequencing.
  It records the current runtime-safe land play model plus opening-hand
  name-based fixing and keeps sacrifice/search/shuffle as annotations.

## PG063 Deck 608 Tutor/Search Runtime Gate - Closed 2026-06-23 02:54 UTC

Status:

- Closed the deck `608` tutor/search runtime gate for `Enlightened Tutor`,
  `Idyllic Tutor`, `Goblin Engineer`, and `Imperial Recruiter`.
- This is a runtime plus PostgreSQL package: code now supports tutor
  destination-specific movement for hand, graveyard, battlefield, and library
  top, and creature ETB rules can invoke the generic library tutor path.
- No deck swap and no `deck_cards` mutation was executed.

Runtime validation:

- `test_enlightened_tutor_puts_artifact_or_enchantment_on_library_top`
  proves `Enlightened Tutor` puts the selected artifact/enchantment on top of
  the library, not into hand.
- `test_idyllic_tutor_finds_enchantment_to_hand_only` proves `Idyllic Tutor`
  filters enchantments only and moves the selected card to hand.
- `test_goblin_engineer_etb_tutors_artifact_to_graveyard` proves
  `Goblin Engineer` resolves as a creature and its ETB moves an artifact from
  library to graveyard.
- `test_imperial_recruiter_etb_tutors_power_two_creature_to_hand` proves
  `Imperial Recruiter` resolves as a creature and its ETB selects a creature
  with power 2 or less into hand.

PostgreSQL validation:

- PG063 apply created backup table
  `manaloom_deploy_audit.pg063_deck608_tutor_search_20260623_024856` with
  `8` rows, inserted `4` curated runtime rules, and disabled `8` superseded
  broad/shadow rows.
- PG063 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck608_tutor_search_pg063_postcheck_20260623_024856.out`
  reports `target_runtime_rows=4`, zero hash/effect/target/destination/scope
  defects, `old_active_shadow_rows=0`, and `backup_rows=8`.

Tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`
  passed `7` tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py -v`
  passed `8` tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed after the PG -> SQLite/snapshot sync.

Auditor result:

- Deck `608` moved from `high=38`, `medium=11`, `pass=19` to
  `high=34`, `medium=6`, `pass=28`.
- The four target cards all report `pass/coherent_for_current_gate`, one
  trusted executable rule, and zero review-only rows in
  `deck_card_battle_rule_coherence_audit_deck608_20260623_025416.json`.
- Global deck-card audit moved from `high=116`, `medium=15`, `pass=74` after
  PG062 fetchlands to `high=112`, `medium=15`, `pass=78`.

Next queue:

- Deck `608` still has `34` high findings and `6` medium findings.
- Continue with high-impact shared executor families before running battle
  evaluation on deck `608`: interaction/protection/removal, draw/wheel/card
  flow, combo/payoff, and remaining cost/ramp engines.

## PG064 Deck 6 Recruiter of the Guard Runtime Gate - Closed 2026-06-23 03:03 UTC

Status:

- Closed the deck `6` runtime gate for `Recruiter of the Guard`.
- Runtime supports `creature_toughness_lte_2` as an ETB library tutor target
  to hand.
- No deck swap and no `deck_cards` mutation was executed.

Apply note:

- The central precheck passed before apply with `new_rule_key_rows_already_present=0`
  and `backup_table_exists=0`.
- Apply output is present and reports `SELECT 2`, `INSERT 0 1`, `UPDATE 2`,
  and `COMMIT`.

Runtime validation:

- `test_recruiter_of_the_guard_etb_tutors_toughness_two_creature_to_hand`
  proves the card resolves as a creature and its ETB selects a creature with
  toughness 2 or less into hand.

PostgreSQL validation:

- PG064 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_recruiter_guard_pg064_postcheck_20260623_025848.out`
  reports `target_runtime_rows=1`, zero hash/effect/target/destination/scope
  defects, `old_active_shadow_rows=0`, and `backup_rows=2`.

Tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`
  passed `7` tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py -v`
  passed `8` tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed, including
  `test_recruiter_of_the_guard_etb_tutors_toughness_two_creature_to_hand`.

Auditor result:

- Deck `6` moved from `high=28`, `pass=72` after PG063 to
  `high=27`, `pass=73`.
- Global deck-card audit moved from `high=112`, `medium=15`, `pass=78` after
  PG063 to `high=111`, `medium=15`, `pass=79`.

Next queue:

- Deck `6` still has `27` high findings. Continue with high-impact shared
  executor families before battle evaluation: interaction/protection/removal,
  draw/wheel/card-flow, copy/token-copy, and remaining cost/ramp engines.

## PG065/PG066 Deck 6 Shared Resource Engine Gate - Closed 2026-06-23 03:24 UTC

Status:

- Closed the current deck `6` resource/topdeck engine gate for `Scroll Rack`,
  `Smothering Tithe`, and `Birgi, God of Storytelling // Harnfel, Horn of
  Bounty`.
- PG065 was already applied for `Scroll Rack` and `Smothering Tithe` before
  this checkpoint was registered; live PostgreSQL confirmed the backup table
  `manaloom_deploy_audit.pg065_shared_engine_rules_20260623_031553`.
- PG066 was applied only for `Birgi` after precheck showed the real remaining
  failure: trusted runtime row without `oracle_hash`/`battle_model_scope` plus
  one generated `review_only` shadow.
- No deck swap and no `deck_cards` mutation was executed.

Runtime validation:

- `test_scroll_rack_sets_up_lorehold_approach_second_cast_on_opponent_upkeep`
  remains the focused Scroll Rack runtime proof; PG065 keeps full arbitrary
  exchange as `annotation_only`.
- `test_smothering_tithe_draw_step_creates_treasure_with_rule_provenance`
  proves the opponent-draw Treasure trigger emits rule provenance from the
  synced PG065 row.
- `test_birgi_adds_red_mana_when_controller_casts_spell` proves the PG066
  front-face spell-cast red mana trigger.
- Focused event:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg066_birgi_smothering_focused_events_20260623_032200.jsonl`
  contains `Birgi` with
  `rule_logical_key=battle_rule_v1:05576012d8fca56910da7ea072abe15e` and
  `Smothering Tithe` with
  `rule_logical_key=battle_rule_v1:242df1cde958c67ece11aae4af5f4bc6`.

PostgreSQL validation:

- PG065 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/shared_engine_rules_pg065_postcheck_20260623_031553.out`
  reports `target_runtime_rows=2`, zero hash/effect/scope defects,
  `old_active_shadow_rows=0`, `trusted_executable_without_oracle_hash_rows=0`,
  and `backup_rows=5`.
- PG066 precheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_birgi_spellcast_resource_engine_pg066_precheck_20260623_032200.out`
  reports `target_rule_rows=2`, `current_trusted_missing_hash_rows=1`,
  `new_rule_key_rows_already_present=0`, and `backup_table_exists=0`.
- PG066 apply:
  `docs/hermes-analysis/master_optimizer_reports/deck6_birgi_spellcast_resource_engine_pg066_apply_20260623_032200.out`
  reports `SELECT 2`, `INSERT 0 1`, `UPDATE 2`, and `COMMIT`.
- PG066 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_birgi_spellcast_resource_engine_pg066_postcheck_20260623_032200.out`
  reports `target_runtime_rows=1`, zero hash/effect/trigger/mana/scope
  defects, `old_active_shadow_rows=0`, and `backup_rows=2`.

Tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed, including the new `Smothering Tithe` event-provenance test and the
  existing `Birgi` trigger test.

Auditor result:

- After PG065 sync, deck `6` reported `high=25`, `medium=7`, `pass=68`.
- After PG066 sync, deck `6` reports `high=24`, `pass=76`; `Scroll Rack`,
  `Smothering Tithe`, `Birgi`, and `Blasphemous Act` all report
  `pass/coherent_for_current_gate`.
- Deck `606` now reports `high=37`, `medium=7`, `pass=37`.
- Global deck-card audit now reports `high=108`, `medium=15`, `pass=82`.

Caveat:

- `Blasphemous Act` was not changed in this cycle. Its cost reduction remains
  a known `annotation_only` caveat, not a blocker and not an inferred runtime
  rule.
- `Smothering Tithe` models the optional `{2}` payment as
  `compact_assume_unpaid_v1`; the payment decision remains a compact
  assumption rather than a dynamic tax executor.

Next queue:

- Deck `6` still has `24` high findings: `Chaos Warp`, `Drannith Magistrate`,
  `Dualcaster Mage`, `Esper Sentinel`, `Faithless Looting`, `Gamble`,
  `Get Lost`, `Giver of Runes`, `Heat Shimmer`, `Molten Duplication`,
  `Mother of Runes`, `Pyroblast`, `Ranger-Captain of Eos`, `Reiterate`,
  `The One Ring`, `Twinflame`, `Wheel of Misfortune`, `Jeska's Will`,
  `Lotus Petal`, `Mizzix's Mastery`, `Professional Face-Breaker`,
  `Ruby Medallion`, `Storm-Kiln Artist`, and `Unexpected Windfall`.

## PG066 Runtime Hash Backfill and PG067 Seething Song Metadata - Verified 2026-06-23 03:27 UTC

Status:

- Live PostgreSQL and worktree artifacts show two additional already-applied
  packages in this cycle:
  `runtime_hash_backfill_pg066_20260623_032021` and
  `seething_song_runtime_metadata_pg067_20260623_032307`.
- PG066 numbering is therefore duplicated with the `Birgi` package above, but
  the backup tables are distinct:
  `manaloom_deploy_audit.pg066_runtime_hash_backfill_20260623_032021` and
  `manaloom_deploy_audit.pg066_deck6_birgi_spellcast_resource_engine_20260623_032200`.
- Next deploy package id should start at PG068.

PostgreSQL validation:

- Runtime hash backfill PG066 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/runtime_hash_backfill_pg066_postcheck_20260623_032021.out`
  reports `expected_rows=8`, `trusted_runtime_rows=8`,
  `expected_hash_rows=8`, `hash_mismatch_rows=0`, and `backup_rows=8`.
- PG067 `Seething Song` postcheck:
  `docs/hermes-analysis/master_optimizer_reports/seething_song_runtime_metadata_pg067_postcheck_20260623_032307.out`
  reports `target_rows=1`, `expected_runtime_rows=1`, and `backup_rows=1`.

Auditor result:

- Latest available cut after PG067:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_032427.json`
  reports `high=24`, `pass=76`.
- `Seething Song`, `Rite of Flame`, `Birgi`, `Scroll Rack`, and
  `Smothering Tithe` all report `pass/coherent_for_current_gate` in that cut.
- Deck `606` remains `high=37`, `medium=7`, `pass=37`; global remains
  `high=108`, `medium=15`, `pass=82`.
- Repeat no-change Deck 6/606 smoke:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_cycle_deck6_20260623_033223.json`
  reloaded the PG source into SQLite, and
  `deck_card_battle_rule_coherence_audit_deck6_20260623_033223.json` plus
  `deck_card_battle_rule_coherence_audit_deck606_20260623_033223.json`
  reproduced the same deck `6` and deck `606` counts without a new PostgreSQL
  apply.

## PG068 Deck 6 Copy Spell Stack Gate - Applied 2026-06-23 03:45 UTC

Status:

- `applied_validated`.
- Closed `Reiterate` and `Dualcaster Mage` for deck `6` copy-spell stack
  coherence.
- No deck swap and no `deck_cards` mutation was executed.
- The Blasphemous Act cost-reduction note remains only a future caveat to
  check in its own lane; it did not drive this package.

PostgreSQL validation:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l5a_copy_spell_stack_pg068_precheck_20260623_004158.out`
  reported `target_cards_with_expected_oracle_hash=2`,
  `existing_rule_rows=4`, `new_rule_key_rows_already_present=0`,
  `current_active_or_review_rows=4`, and `backup_table_already_exists=f`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l5a_copy_spell_stack_pg068_apply_20260623_004158.out`
  reported `SELECT 4`, `UPDATE 4`, `INSERT 0 2`, and `COMMIT`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l5a_copy_spell_stack_pg068_postcheck_20260623_004158.out`
  reported `target_rule_rows=6`, `expected_runtime_rows=2`,
  `old_active_shadow_rows=0`, and `backup_rows=4`.

Runtime gate:

- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg068_copy_spell_stack_focused_events_20260623_004158.jsonl`.
- `Reiterate` emits `spell_copied` with
  `rule_logical_key=battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405` and
  `rule_oracle_hash=996fb5f02f16605ff7f1c899f2c50f60`.
- `Dualcaster Mage` resolves as a flash creature, enters the battlefield, then
  emits ETB `spell_copied` with
  `rule_logical_key=battle_rule_v1:e176019b87d68d22e2388e08a4efbf55` and
  `rule_oracle_hash=e26f613394b72e9724d299512983218a`.

Tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed, including the new Reiterate and Dualcaster PG068 tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py -v`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`
  passed.

Auditor result:

- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg068_copy_spell_stack_20260623_004158.json`
  reloaded `pg_rows_loaded=5296` and `sqlite_inserted_or_updated=5252`.
- Deck `6` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg068_20260623_004158.json`
  reports `high=22`, `pass=78`; `Reiterate` and `Dualcaster Mage` both
  report `pass/coherent_for_current_gate`.
- Deck `606` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_pg068_20260623_004158.json`
  remains `high=37`, `medium=7`, `pass=37`.
- Global deck-card audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_pg068_20260623_004158.json`
  reports `high=106`, `medium=15`, `pass=84`.

## PG068 Deck 6 Copy Token Stack Gate - Applied 2026-06-23 03:50 UTC

Status:

- `applied_validated`.
- Closed `Heat Shimmer`, `Twinflame`, and `Molten Duplication` for the current
  copy-token gate, while preserving the Reiterate/Dualcaster copy-spell rows
  already proven earlier in PG068.
- No deck swap and no `deck_cards` mutation was executed.

PostgreSQL validation:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_copy_token_stack_rules_pg068_precheck_20260623_034443.out`
  reported `expected_rows=5`, `target_card_rows=5`,
  `oracle_hash_match_rows=5`, `deck6_rows=5`,
  `new_rule_key_rows_already_present=2`, and `backup_table_exists=0`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/deck6_copy_token_stack_rules_pg068_apply_20260623_034443.out`
  reported `SELECT 12`, `INSERT 0 5`, `UPDATE 6`, and `COMMIT`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_copy_token_stack_rules_pg068_postcheck_20260623_034443.out`
  reported `exact_runtime_rows=5`, `hash_mismatch_rows=0`,
  `effect_mismatch_rows=0`, `scope_mismatch_rows=0`,
  `old_active_shadow_rows=0`,
  `trusted_executable_without_oracle_hash_rows=0`, and `backup_rows=12`.

Runtime gate:

- `Heat Shimmer` copies the best target creature from any controller, gives the
  token haste, and exiles it at the end step.
- `Twinflame` copies a controller-owned creature, gives the token haste, and
  exiles it at the end step; strive multi-target expansion remains
  `annotation_only_single_best_own_creature`.
- `Molten Duplication` copies a controller-owned artifact or creature as an
  artifact in addition, gives the token haste, and sacrifices it at the end
  step.

Tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed, including the PG068 copy-spell and copy-token tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py -v`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`
  passed.

Auditor result:

- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg068_deck6_copy_token_stack_rules_20260623_034443.json`
  loaded `pg_rows_loaded=1826`, wrote `sqlite_inserted_or_updated=2493`, and
  exported `canonical_snapshot_rows_exported=3201`.
- Deck `6` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_035001.json`
  reports `high=7`, `medium=11`, `pass=82`; `Reiterate`,
  `Dualcaster Mage`, `Heat Shimmer`, `Molten Duplication`, and `Twinflame`
  all report `pass/coherent_for_current_gate`.
- Deck `606` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_20260623_035001.json`
  reports `high=7`, `medium=30`, `pass=44`.
- Deck `607` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_20260623_035001.json`
  reports `high=30`, `medium=18`, `pass=46`.
- Deck `608` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck608_20260623_035001.json`
  reports `high=21`, `medium=9`, `pass=38`.
- Global deck-card audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_035001.json`
  reports `high=57`, `medium=45`, `pass=103`.

Remaining deck `6` high queue:

- `Chaos Warp`, `Esper Sentinel`, `Faithless Looting`, `Gamble`, `Get Lost`,
  `Pyroblast`, and `Wheel of Misfortune`.

Numbering note:

- PG068 was used for two related copy-family packages with distinct backup
  tables. The next PostgreSQL package must use PG069.

## PG069 Deck 6 L2 Specific Runtime Cleanup - Applied 2026-06-23 04:02 UTC

Status:

- `applied_validated`.
- Closed the current hash/scope defects for `The One Ring` and
  `Unexpected Windfall`.
- No deck swap and no `deck_cards` mutation was executed.

PostgreSQL validation:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_specific_runtime_cleanup_pg069_precheck_20260623_005736.out`
  reported `target_cards_with_expected_oracle_hash=2`,
  `existing_rule_rows=6`, `target_specific_rule_rows=2`,
  `old_active_shadow_rows=3`, `target_specific_hash_defect_rows=2`, and
  `backup_table_already_exists=f`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_specific_runtime_cleanup_pg069_apply_20260623_005736.out`
  reported `SELECT 6`, `UPDATE 1`, `UPDATE 1`, `UPDATE 3`, and `COMMIT`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_specific_runtime_cleanup_pg069_postcheck_20260623_005736.out`
  reported `target_rule_rows=6`, `expected_runtime_rows=2`,
  `old_active_shadow_rows=0`, `runtime_missing_hash_rows=0`, and
  `backup_rows=6`.

Runtime gate:

- `The One Ring` keeps the PG025 runtime behavior:
  ETB/cast protection from everything until next turn, no ETB draw, upkeep
  burden life loss, and tap burden draw.
- `Unexpected Windfall` keeps the discard/draw/two-Treasure executor and now
  has current oracle hash plus
  `oracle_runtime_scope=additional_cost_discard_draw_two_create_two_treasures_v1`.
- Runtime replay now emits `rule_logical_key` and `rule_oracle_hash` on the
  `treasure_created` event for this card.
- Focused runtime events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg069_specific_runtime_cleanup_focused_events_20260623_011015.jsonl`.

Tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed, including
  `test_unexpected_windfall_discards_draws_two_creates_two_treasures_with_pg069_rule_provenance`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py -v`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`
  passed.

Auditor result:

- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg069_l2_specific_runtime_cleanup_20260623_040215.json`
  used `include_needs_review=false`, loaded `pg_rows_loaded=1825`, wrote
  `sqlite_inserted_or_updated=2493`, and exported
  `canonical_snapshot_rows_exported=3201`.
- Deck `6` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg069_20260623_040215.json`
  reports `high=7`, `medium=10`, `pass=83`.
- Deck `606` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_pg069_20260623_040215.json`
  reports `high=7`, `medium=30`, `pass=44`.
- Deck `607` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_pg069_20260623_040215.json`
  reports `high=30`, `medium=17`, `pass=47`.
- Deck `608` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck608_pg069_20260623_040215.json`
  reports `high=21`, `medium=9`, `pass=38`.
- Global deck-card audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_pg069_20260623_040215.json`
  reports `high=57`, `medium=44`, `pass=104`.

Remaining deck `6` high queue:

- `Chaos Warp`, `Esper Sentinel`, `Faithless Looting`, `Gamble`, `Get Lost`,
  `Pyroblast`, and `Wheel of Misfortune`.

Numbering note:

- The next PostgreSQL package must use PG070.

## PG070 Deck 6 Red Discard Runtime - Applied 2026-06-23 04:29 UTC

Status:

- `applied_validated`.
- Closed `Faithless Looting` and `Gamble` from the deck `6` high queue with
  runtime evidence, PostgreSQL evidence, SQLite sync, and auditor evidence.
- No deck swap and no `deck_cards` mutation was executed.

PostgreSQL validation:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_red_discard_runtime_pg070_precheck_20260623_042617.out`
  reported `target_cards_with_expected_oracle_hash=2`,
  `existing_rule_rows=4`, `target_specific_rule_rows=2`,
  `old_active_shadow_rows=2`, `target_specific_defect_rows=2`, and
  `backup_table_already_exists=f`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/deck6_red_discard_runtime_pg070_apply_20260623_042617.out`
  reported `SELECT 4`, `UPDATE 1`, `UPDATE 1`, `UPDATE 2`, and `COMMIT`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_red_discard_runtime_pg070_postcheck_20260623_042617.out`
  reported `target_rule_rows=4`, `expected_runtime_rows=2`,
  `old_active_shadow_rows=0`, `runtime_missing_hash_rows=0`, and
  `backup_rows=4`.

Runtime gate:

- `Faithless Looting` now resolves as `loot`: draw two, discard two, then the
  spell finishes normally; flashback is documented as annotation-only metadata
  for this runtime slice.
- `Gamble` now resolves as any-card tutor to hand followed by random discard
  from hand; hidden-zone library shuffle remains annotation-only because the
  simulator does not model hidden library order.
- Focused runtime events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_red_discard_runtime_focused_events_20260623_042617.jsonl`.

Tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py -v`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`
  passed.

Auditor result:

- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg070_deck6_red_discard_runtime_20260623_042617.json`
  used `include_needs_review=false`, loaded `pg_rows_loaded=1825`, wrote
  `sqlite_inserted_or_updated=2493`, and exported
  `canonical_snapshot_rows_exported=3201`.
- Deck `6` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg070_20260623_042617.json`
  reports `high=5`, `medium=10`, `pass=85`.
- Deck `606` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_pg070_20260623_042617.json`
  reports `high=7`, `medium=30`, `pass=44`.
- Deck `607` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_pg070_20260623_042617.json`
  reports `high=30`, `medium=17`, `pass=47`.
- Deck `608` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck608_pg070_20260623_042617.json`
  reports `high=21`, `medium=9`, `pass=38`.
- Global deck-card audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_pg070_20260623_042617.json`
  reports `high=55`, `medium=44`, `pass=106`.

Remaining deck `6` high queue:

- `Chaos Warp`, `Esper Sentinel`, `Get Lost`, `Pyroblast`, and
  `Wheel of Misfortune`.

Numbering note:

- The next PostgreSQL package must use PG072.

## PG070 Deck 6 L2 Hash Cleanup + Red Discard Runtime - 2026-06-23 04:30 UTC

Status:

- `validated`.
- Closed the current deck `6` medium L2 hash-only queue for `Fellwar Stone`,
  `Mana Vault`, `Mox Amber`, `Scroll Rack`, `Seething Song`, `Silence`,
  `Talisman of Conviction`, `Unexpected Windfall`, and
  `Valakut Awakening // Valakut Stoneforge`.
- Closed `Faithless Looting` and `Gamble` from the deck `6` high queue with
  scoped red card-flow/tutor runtime rows.
- No deck swap and no `deck_cards` mutation was executed.

PostgreSQL validation:

- L2 precheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_runtime_rules_pg070_precheck_20260623_011859.out`
  reported `expected_target_rows=9`,
  `target_cards_with_single_oracle_hash=9`,
  `matching_runtime_rows=9`,
  `runtime_rows_missing_oracle_hash=9`, and
  `active_needs_review_shadow_rows=0`.
- L2 postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_runtime_rules_pg070_postcheck_20260623_011859.out`
  reported `target_runtime_rows=9`, `hashed_runtime_rows=9`,
  `runtime_missing_hash_rows=0`, `hash_mismatch_rows=0`,
  `scope_mismatch_rows=0`, and `backup_rows=27`.
- L2 Seething metadata addendum:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_runtime_rules_pg070_seething_metadata_postcheck_20260623_011859.out`
  reported `seething_metadata_restored_rows=1` and preserved the
  `single_shot_red_ritual_v1` executor.
- Red-discard postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_red_discard_runtime_pg070_postcheck_20260623_042617.out`
  reported `target_rule_rows=4`, `expected_runtime_rows=2`,
  `old_active_shadow_rows=0`, `runtime_missing_hash_rows=0`, and
  `backup_rows=4`.

Runtime gate:

- `Faithless Looting` now resolves as `loot`: draw two cards, then discard two
  cards. Flashback is explicitly
  `annotation_only_cost_2r_exile_on_resolution_not_autocast`.
- `Gamble` now resolves as any-card tutor to hand followed by a random discard
  from hand. Library shuffle remains
  `annotation_only_hidden_zone_shuffle_no_order_model`.
- L2 cards did not receive new semantics; the package persisted oracle hashes
  and restored required runtime metadata where missing.
- `Blasphemous Act` was not part of PG070. Its cost reduction remains only the
  existing annotation caveat and is not treated as a blocking rule for this
  lane.

Replay/event evidence:

- L2 focused event artifact:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_l2_hash_only_runtime_focused_events_20260623_011859.jsonl`.
- Red-discard focused event artifact:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_red_discard_runtime_focused_events_20260623_042617.jsonl`.
- Red-discard events prove:
  `Faithless Looting` `loot_resolved` with
  `battle_rule_v1:554fe811b81e8a284b8a5ca9c6543caa` and
  `oracle_hash=2e734d8bae3f331866abf1b030c92781`;
  `Gamble` `tutor_resolved` plus `random_discard_after_tutor` with
  `battle_rule_v1:2861739f22e978549e28d2339288df2a` and
  `oracle_hash=9b3fc8ab7f664f6c084e0bda0ccf9a7c`.

Auditor result:

- Accepted SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg070_deck6_red_discard_runtime_20260623_042617.json`
  used `include_needs_review=false`, loaded `pg_rows_loaded=1825`, wrote
  `sqlite_inserted_or_updated=2493`, and exported
  `canonical_snapshot_rows_exported=3201`.
- Deck `6` accepted audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg070_20260623_042617.json`
  reports `high=5`, `medium=10`, `pass=85`.
- Deck `606` accepted audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_pg070_20260623_042617.json`
  reports `high=7`, `medium=30`, `pass=44`.
- Deck `607` accepted audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_pg070_20260623_042617.json`
  reports `high=30`, `medium=17`, `pass=47`.
- Deck `608` accepted audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck608_pg070_20260623_042617.json`
  reports `high=21`, `medium=9`, `pass=38`.
- Global accepted audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_pg070_20260623_042617.json`
  reports `high=55`, `medium=44`, `pass=106`.
- The review-rule sync generated during the batch was rejected for battle
  validation gating because it imported untrusted review rows.

Tests:

- `py_compile` for the touched battle/sync/audit scripts passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py -v`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`
  passed.

Remaining deck `6` high queue:

- `Chaos Warp`, `Esper Sentinel`, `Get Lost`, `Pyroblast`, and
  `Wheel of Misfortune`.

Next lane recommendation:

- Use PG072 for the next PostgreSQL package.
- If following the lane order, continue with the remaining L3 mana/ramp support
  (`Storm-Kiln Artist`, `Jeska's Will`) only after confirming they are in the
  accepted queue for the target deck.
- If prioritizing battle-critical first, use the L6 interaction/protection
  sublane (`Chaos Warp`, `Get Lost`, `Pyroblast`, plus the Runes/Magistrate
  silence/protection cards as separate scoped models).

## PG071 Deck 6 L3 Fast Mana/Cost Reduction - Applied 2026-06-23 04:45 UTC

PostgreSQL evidence:

- Precheck/apply/postcheck/rollback:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3_fast_mana_cost_reduction_pg071_precheck_20260623_043623.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3_fast_mana_cost_reduction_pg071_apply_20260623_043623.out`,
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3_fast_mana_cost_reduction_pg071_postcheck_20260623_043623.out`,
  and
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3_fast_mana_cost_reduction_pg071_rollback_20260623_043623.sql`.
- Postcheck reported `target_rule_rows=4`, `expected_runtime_rows=2`,
  `old_active_shadow_rows=0`, `runtime_missing_hash_rows=0`, and
  `backup_rows=4`.

Runtime gate:

- `Lotus Petal` now resolves as one-shot artifact fast mana:
  `battle_model_scope=zero_mana_artifact_sacrifice_one_mana_one_shot_runtime_v1`.
- `Ruby Medallion` now resolves as `passive` cost-reduction metadata:
  `battle_model_scope=red_spell_cost_reduction_annotation_only_v1`; it is not
  a recurring mana source.
- Focused event artifact:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg071_l3_fast_mana_runtime_focused_events_20260623_043623.jsonl`.

Auditor result:

- Trusted SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/pg071_l3_fast_mana_cost_reduction_trusted_sync_report_20260623_043623.json`
  used `include_needs_review=false`, loaded `pg_rows_loaded=1825`, wrote
  `sqlite_inserted_or_updated=2493`, and exported
  `canonical_snapshot_rows_exported=3201`.
- Accepted audits:
  deck `6` `high=5`, `medium=8`, `pass=87`; deck `606` `high=7`,
  `medium=30`, `pass=44`; deck `607` `high=30`, `medium=16`,
  `pass=48`; deck `608` `high=21`, `medium=7`, `pass=40`; global
  `high=55`, `medium=42`, `pass=108`.
- The broad sync generated with review rows was rejected as a gate source.

Remaining deck `6` high queue:

- `Chaos Warp`, `Esper Sentinel`, `Get Lost`, `Pyroblast`, and
  `Wheel of Misfortune`.

Next lane recommendation:

- Use PG072 for the next PostgreSQL package.
- Prefer the battle-critical lane first: `Chaos Warp`, `Get Lost`,
  `Pyroblast`, `Esper Sentinel`, and `Wheel of Misfortune`.

## PG072 Deck 6 L6 Interaction/Removal/Counter - Applied 2026-06-23 05:04 UTC

Status:

- `applied_validated`.
- Closed `Get Lost` and `Pyroblast` from the deck `6` high queue.
- No deck swap and no `deck_cards` mutation was executed.

PostgreSQL validation:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l6_interaction_removal_counter_pg072_precheck_20260623_045642.out`
  reported `target_cards_with_expected_oracle_hash=2`,
  `existing_rule_rows=4`, `target_specific_rule_rows=2`,
  `old_active_shadow_rows=1`, `target_specific_defect_rows=2`, and
  `backup_table_already_exists=f`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l6_interaction_removal_counter_pg072_apply_20260623_045642.out`
  completed `SELECT 4`, `UPDATE 1`, `UPDATE 1`, `UPDATE 1`, and `COMMIT`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l6_interaction_removal_counter_pg072_postcheck_20260623_045642.out`
  reported `target_rule_rows=4`, `expected_runtime_rows=2`,
  `old_active_shadow_rows=0`, `runtime_missing_hash_rows=0`, and
  `backup_rows=4`.

Runtime gate:

- `Get Lost` now resolves as `remove_permanent` for
  `creature_enchantment_or_planeswalker` and creates two Map artifact tokens
  for the target controller; Map activation/explore is annotation-only.
- `Pyroblast` now requires a blue stack spell for the counter runtime; the
  destroy-blue-permanent mode is annotation-only.
- Focused runtime events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_pg072_l6_interaction_removal_counter_focused_events_20260623_045642.jsonl`.

Auditor result:

- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/pg072_l6_interaction_removal_counter_sync_report_20260623_045642.json`
  used `include_needs_review=false`, loaded `pg_rows_loaded=1825`, wrote
  `sqlite_inserted_or_updated=1802`, and exported
  `canonical_snapshot_rows_exported=3201`.
- Final resync after fixing the oracle-normalizer branch for `target creature,
  enchantment, or planeswalker`:
  `docs/hermes-analysis/master_optimizer_reports/pg072_l6_interaction_removal_counter_resync_report_20260623_050816.json`;
  `known_cards_canonical_snapshot.json` now keeps `Get Lost` as
  `remove_permanent` with `target=creature_enchantment_or_planeswalker`.
- Deck `6` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg072_l6_interaction_removal_counter_20260623_045642.json`
  reports `high=3`, `medium=8`, `pass=89`.
- Deck `606` auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_pg072_l6_interaction_removal_counter_20260623_045642.json`
  reports `high=7`, `medium=30`, `pass=44`.
- Global auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_pg072_l6_interaction_removal_counter_20260623_045642.json`
  reports `high=53`, `medium=42`, `pass=110`.

Tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules.py docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed, including the PG072 Pyroblast/Get Lost tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py -v`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py -v`
  passed.

Remaining deck `6` high queue:

- `Chaos Warp`, `Esper Sentinel`, and `Wheel of Misfortune`.

Next lane recommendation:

- Use PG073 for the next PostgreSQL package.
- Prefer `Esper Sentinel` + the Runes/Magistrate medium support family only if
  modeling static/triggered protection/silence together; otherwise take
  `Wheel of Misfortune` as L4 card-flow and keep `Chaos Warp` as L8 unique.
