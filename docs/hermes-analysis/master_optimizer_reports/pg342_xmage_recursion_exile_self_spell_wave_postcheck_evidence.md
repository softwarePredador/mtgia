# PG342 XMage Recursion Exile-Self Spell Wave Postcheck Evidence

- generated_at: `2026-07-02T01:01:58+00:00`
- db_target: `143.198.230.247:5433/halder`
- sql: `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_postcheck.sql`
- exit_code: `0`

## stdout

```
      card_name      |   normalized_name   |                logical_rule_key                 | promoted_rule_rows | promoted_verified_auto_rows | promoted_oracle_hash_rows | backup_rows
---------------------+---------------------+-------------------------------------------------+--------------------+-----------------------------+---------------------------+-------------
 Reconstruct History | reconstruct history | battle_rule_v1:5891f73a4c159c6a7e04ab4a73194bb2 |                  1 |                           1 |                         1 |           2
 Retrieve            | retrieve            | battle_rule_v1:3fb7ce15a27a11482bfeb0a35cc5e088 |                  1 |                           1 |                         1 |           2
 Vivid Revival       | vivid revival       | battle_rule_v1:0eaec04572207c2751454d4b4793493b |                  1 |                           1 |                         1 |           2
(3 rows)
```

## stderr

```

```
