# Lorehold Registry Candidate Runner

- generated_at: `2026-06-28T18:01:04Z`
- registry: `/tmp/lorehold-runner-registry-579-20260628.json`
- execute: `True`
- max_candidates: `1`
- status: `needs_more_evidence`
- postgres_writes: `false`
- source_db_mutated: `false`

## Queue Results

| Key | Priority | Status | Plan | Reason |
| --- | --- | --- | --- | --- |
| `candidate_607_birgi_v1` | P1 | `executed_inconclusive_candidate_unobserved` | `birgi_v1` | matching executable research plan found |

## Commands For `candidate_607_birgi_v1`

```bash
/usr/local/bin/python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_607_research_candidate.py --source-db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --plan birgi_v1 --out-dir /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_birgi_v1
MANALOOM_FOCUS_ACCESS_CARDS=["Birgi, God of Storytelling // Harnfel, Horn of Bounty"] /usr/local/bin/python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_battle_gate.py --db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --deck-ids 607 --candidate-db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_birgi_v1/knowledge_candidate.db --candidate-key candidate_607_birgi_v1 --candidate-name Lorehold 607 Research Candidate birgi_v1 --candidate-archetype research-candidate --games 1 --opponent-limit 1 --opponent-seed 20260626 --simulation-seed 42 --game-timeout-seconds 8.0 --stem lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate
/usr/local/bin/python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/seventeenlands_battle_prior_compare.py --prior-json /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/seventeenlands_replay_profile_lci_premierdraft_sample_20260628.json --gate-report-json /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate.json --candidate-key candidate_607_birgi_v1 --player-slots 2 --output-json /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.json --output-md /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.md --candidate-card Birgi, God of Storytelling // Harnfel, Horn of Bounty
```

- battle_prior_status: `inconclusive_candidate_unobserved`
- battle_prior_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.json`
- battle_prior_flags_count: `5`
