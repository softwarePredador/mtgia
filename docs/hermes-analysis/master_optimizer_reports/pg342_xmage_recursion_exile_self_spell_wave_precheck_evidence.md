# PG342 XMage Recursion Exile-Self Spell Wave Precheck Evidence

- generated_at: `2026-07-02T01:01:58+00:00`
- db_target: `143.198.230.247:5433/halder`
- sql: `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_precheck.sql`
- exit_code: `0`

## stdout

```
      card_name      |   normalized_name   |           oracle_hash            |                logical_rule_key                 |      shadow_handling       | target_card_rows |          canonical_card_id           | existing_rule_rows | expected_rule_rows_before | would_deprecate_shadow_rows
---------------------+---------------------+----------------------------------+-------------------------------------------------+----------------------------+------------------+--------------------------------------+--------------------+---------------------------+-----------------------------
 Reconstruct History | reconstruct history | fef076b46b9660e2f9eb20dbce095b86 | battle_rule_v1:5891f73a4c159c6a7e04ab4a73194bb2 | deprecate_nonmatching_rows |                1 | 3f48f4f5-02f1-4be6-bc90-63cf7369e1f6 |                  2 |                         0 |                           2
 Retrieve            | retrieve            | 18bc4cc44ffd6382912e0c7fe24e7335 | battle_rule_v1:3fb7ce15a27a11482bfeb0a35cc5e088 | deprecate_nonmatching_rows |                1 | 20cf8847-ae0c-41a2-bb18-26eb093d2cb6 |                  0 |                         0 |                           0
 Vivid Revival       | vivid revival       | 9f4629b135cb2888979404fca4a71cea | battle_rule_v1:0eaec04572207c2751454d4b4793493b | deprecate_nonmatching_rows |                1 | 81ccf4ee-d60b-46ed-9250-3de5748ba905 |                  0 |                         0 |                           0
(3 rows)
```

## stderr

```

```
