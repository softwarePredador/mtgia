# Lorehold Registry Candidate Runner

- generated_at: `2026-06-26T19:31:56Z`
- registry: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
- execute: `True`
- max_candidates: `1`
- status: `ready`
- postgres_writes: `false`
- source_db_mutated: `false`

## Queue Results

| Key | Priority | Status | Plan | Reason |
| --- | --- | --- | --- | --- |
| `candidate_607_galvanoth_v1` | P2 | `executed` | `galvanoth_v1` | matching executable research plan found |

## Commands For `candidate_607_galvanoth_v1`

```bash
/usr/local/bin/python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_607_research_candidate.py --source-db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --plan galvanoth_v1 --out-dir /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_galvanoth_v1
/usr/local/bin/python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_battle_gate.py --db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --deck-ids 607 --candidate-db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_galvanoth_v1/knowledge_candidate.db --candidate-key candidate_607_galvanoth_v1 --candidate-name Lorehold 607 Research Candidate galvanoth_v1 --candidate-archetype research-candidate --games 3 --opponent-limit 3 --opponent-seed 20260626 --simulation-seed 42 --game-timeout-seconds 45.0 --stem lorehold_registry_candidate_runner_20260626_galvanoth_v1_galvanoth_v1_gate
```
