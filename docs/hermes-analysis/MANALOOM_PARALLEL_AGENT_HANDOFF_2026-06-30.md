# ManaLoom Parallel Agent Handoff - 2026-06-30

Status: `active_parallel_handoff`.

Purpose: split the current Lorehold/ManaLoom work across four Codex agents
without letting them repeat old gates, consume historical artifacts as current
truth, or promote blind deck swaps.

## Current Verified State

- Repository branch at handoff time: `master`.
- Latest pushed baseline before this handoff fix: `767a00a33 Promote Kayla Music Box exile runtime`.
- `deck 607` remains the protected Lorehold baseline.
- Do not promote a deck replacement unless a current equal battle gate and
  decision trace proof clear the frozen Commander deckbuilding contract.
- Post-PG280 runtime queue:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg280_kayla_music_box.json`.
- Post-PG280 deck/package queue:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_focus_access_package_generator_20260630_post_pg280_kayla_music_box.json`.
- Runtime candidate readiness:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_candidate_readiness_20260630_post_pg280_kayla_music_box.json`.

Current queue summary:

- blocked runtime rule gaps: `12`.
- residual lane: `split_family_scope_review_required`.
- local XMage source found for all 12 residual cards.
- manual mapper backlog for this queue: `0`.
- focus access package candidates: `52`.
- gate-ready focus packages: `0`.
- recommended package action:
  `do_not_create_blind_swap; run focused trace/runtime/cut-model work first`.

The artifact contract auditor had drifted: new runtime and focus reports were
legitimate but classified as `unknown`. This handoff updates
`lorehold_artifact_contract_audit.py` so those known report schemas are
recognized and the current workspace audit can pass again.

## Green Validation At Handoff

Run from `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`:

```bash
python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_runtime_gap_family_queue.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_runtime_candidate_readiness.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_focus_access_package_generator.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_variant_battle_gate.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_registry_candidate_runner.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_artifact_contract_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_generate_lorehold_candidate_deck.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_607_research_candidate.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_607_bridge_candidate.py -q
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_artifact_contract_audit.py --out-prefix docs/hermes-analysis/master_optimizer_reports/lorehold_artifact_contract_audit_20260630_125734_agent_split_recheck_after_patch
python3 docs/hermes-analysis/manaloom-knowledge/scripts/operational_surface_alignment_audit.py --out-prefix docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260630_125800_agent_split_after_artifact_patch
python3 docs/hermes-analysis/manaloom-knowledge/scripts/deckbuilding_contract_surface_audit.py --out-prefix docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260630_125800_agent_split_after_artifact_patch
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260630_125800_agent_split_after_artifact_patch
```

Expected current results:

- focused pytest: `94 passed, 8 subtests passed`.
- artifact contract audit: `pass`.
- operational surface alignment: `pass`.
- deckbuilding contract surface: `pass`.
- XMage strategy consistency: `pass`, `26/26`.

## Parallel Work Rules

- Each agent must start from current `master`, create its own `codex/...`
  branch, and avoid editing cards outside its assigned list.
- PostgreSQL writes are allowed only for the assigned cards and only after
  exact scope, focused tests, precheck, apply, postcheck, PG -> Hermes sync,
  and E2E evidence.
- If another agent has already promoted or changed one assigned card, rebase and
  remove that card from the local scope instead of duplicating work.
- No agent should perform a real deck swap or call a candidate better from
  aggregate battle wins without drawn/cast/used evidence.
- Agents should push their branch. If the merge to `master` is a clean
  fast-forward or clean merge after pulling latest, they may merge and push
  `master`; otherwise they should leave the branch pushed and report blockers.
- The fourth agent is the integration/gate agent and should not promote
  PostgreSQL card rules unless it is fixing a contract/audit/schema issue
  needed to unblock the other agents.

## Command For Agent 1

```text
/goal Em /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia, puxe master atual, crie a branch codex/lorehold-agent1-runtime-artifact-topdeck e trabalhe somente nas cartas: Pyxis of Pandemonium, Prototype Portal, Leyline Dowser, Orcish Spy. Use a skill manaloom-data-semantic-layer. Leia o fluxo atual em docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md e o contrato Commander em docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md. Fonte da fila: docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg280_kayla_music_box.json. Para cada carta, use XMage local em /Users/desenvolvimentomobile/Downloads/mage-master, separe battle_model_scope exato, implemente mapper/runtime/testes focados, gere pacote PostgreSQL apenas se o scope estiver exato, aplique/sincronize PG->Hermes se passar precheck, gere evidencias E2E, rerode lorehold_runtime_gap_family_queue, lorehold_runtime_candidate_readiness, lorehold_focus_access_package_generator, lorehold_artifact_contract_audit, operational_surface_alignment_audit, deckbuilding_contract_surface_audit, xmage_strategy_consistency_audit e os pytest focados. Nao mexa em deck real, nao faca swap cego e nao toque nas cartas dos outros agentes. Commite e push sua branch; se master estiver limpo e mergear sem conflito, faca merge em master e push tambem. Responda com hashes, arquivos de evidencia e cards que sairam da fila.
```

## Command For Agent 2

```text
/goal Em /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia, puxe master atual, crie a branch codex/lorehold-agent2-runtime-static-wipe-tutor e trabalhe somente nas cartas: Blood Moon, Karn, the Great Creator, Karn's Sylex, Deathbellow War Cry. Use a skill manaloom-data-semantic-layer. Leia docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md, docs/hermes-analysis/BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md e docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md. Fonte da fila: docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg280_kayla_music_box.json. Valide cada carta contra XMage local em /Users/desenvolvimentomobile/Downloads/mage-master e nao reduza efeitos estaticos/locks/wish/tutor/board wipe a familias genericas. Se houver scope exato implementavel, ajuste mapper/runtime/testes, prepare e aplique PG com precheck/postcheck/rollback/sync/e2e; se alguma carta exigir modelagem maior, isole com motivo tecnico e teste negativo. Rerode os mesmos auditores: runtime gap queue, runtime candidate readiness, focus access package generator, lorehold_artifact_contract_audit, operational_surface_alignment_audit, deckbuilding_contract_surface_audit e xmage_strategy_consistency_audit. Nao mexa em deck real nem nas cartas dos outros agentes. Commite e push sua branch; se master estiver limpo e mergear sem conflito, faca merge em master e push tambem. Responda com evidencias e status por carta.
```

## Command For Agent 3

```text
/goal Em /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia, puxe master atual, crie a branch codex/lorehold-agent3-runtime-finisher-draw-recursion e trabalhe somente nas cartas: Ancient Gold Dragon, Chandra's Ignition, Charmbreaker Devils, Naktamun Lorespinner // Wheel of Fortune. Use a skill manaloom-data-semantic-layer. Leia os contratos atuais XMage e Commander. Use a fila docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg280_kayla_music_box.json e XMage local em /Users/desenvolvimentomobile/Downloads/mage-master. O objetivo e fechar scopes exatos para d20/token/combat damage, damage baseado em poder, recursion aleatoria/de upkeep, e draw/wheel split-face sem colapsar em draw generico. Implemente runtime/mappers/testes focados quando seguro; aplique/sincronize PostgreSQL apenas com precheck/postcheck/e2e; se nao for seguro, gere isolamento tecnico com teste que prove o bloqueio. Depois rerode runtime gap queue, runtime candidate readiness, focus access package generator, artifact contract audit, operational/deckbuilding/xmage audits e pytest focados. Nao mexa em deck real, nao faca swap cego e nao toque nas cartas dos outros agentes. Commite e push sua branch; se master estiver limpo e mergear sem conflito, faca merge em master e push tambem. Responda com status por carta e impacto na fila de 12.
```

## Command For Agent 4

```text
/goal Em /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia, puxe master atual, crie a branch codex/lorehold-agent4-integration-deck-gates e trabalhe como agente de integracao/deckbuilding, sem promover cartas PostgreSQL que pertencem aos agentes 1-3. Use a skill manaloom-data-semantic-layer. Primeiro valide que docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_artifact_contract_audit.py reconhece os artefatos atuais e que lorehold_artifact_contract_audit, operational_surface_alignment_audit, deckbuilding_contract_surface_audit e xmage_strategy_consistency_audit passam. Depois reanalise os scripts de cut/gate atuais: lorehold_access_cut_model.py, lorehold_hand_filter_cut_model.py, lorehold_tutor_cut_model.py, lorehold_recursion_cut_model.py, lorehold_safe_cut_replanner.py, lorehold_focus_access_package_generator.py, lorehold_registry_candidate_runner.py e lorehold_variant_battle_gate.py. Confirme que todos usam baseline protegido 607, que nao consomem ranked_decks legado sem normalizador, que nao aceitam gate_ready quando gate_ready_package_count=0 e que exigem drawn/cast/used para conclusao por carta. Se houver furo, corrija codigo/testes/docs. Depois, quando os agentes 1-3 tiverem branches/pushes ou quando master mudar, rebase/puxe, regenere runtime_gap_family_queue, runtime_candidate_readiness e focus_access_package_generator, e so rode equal battle gate se aparecer pacote gate-ready legitimo. Nao faca deck swap real. Commite e push sua branch; se master estiver limpo e mergear sem conflito, faca merge em master e push tambem. Responda com lista de divergencias encontradas, correcoes, e se o projeto esta pronto ou ainda bloqueado para montar o deck ideal.
```
