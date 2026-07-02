# PG341 XMage Recursion Auxiliary Spell Wave Precheck Evidence

- generated_at: `2026-07-02T00:38:15+00:00`
- db_target: `143.198.230.247:5433/halder`
- sql: `docs/hermes-analysis/master_optimizer_reports/pg341_xmage_recursion_auxiliary_spell_wave_precheck.sql`
- exit_code: `0`

## stdout

```
card_name     | normalized_name  |           oracle_hash            |                logical_rule_key                 |      shadow_handling       | target_card_rows |          canonical_card_id           | existing_rule_rows | expected_rule_rows_before | would_deprecate_shadow_rows 
------------------+------------------+----------------------------------+-------------------------------------------------+----------------------------+------------------+--------------------------------------+--------------------+---------------------------+-----------------------------
 Morgue Theft     | morgue theft     | 3482d9adceeb393bac3d82c542d2c3ea | battle_rule_v1:7ef10090331d934746bc0b9c4c3a2deb | deprecate_nonmatching_rows |                1 | 89489a31-2386-4087-98fa-741767f8a37e |                  0 |                         0 |                           0
 Mystic Retrieval | mystic retrieval | cdfb79bdce61ab9ea33e9f56c12b830e | battle_rule_v1:f10e702e2b0f82cc8f5b443aef4060bb | deprecate_nonmatching_rows |                1 | 3d7da2ce-8722-4ce7-9235-1f20dfaebfb9 |                  0 |                         0 |                           0
 Unburial Rites   | unburial rites   | 5c5464700efd3b715041490ae1e569a9 | battle_rule_v1:3fcbbe9325bf4d5f05deabc46c9e6e5a | deprecate_nonmatching_rows |                1 | cc564104-2e77-4b61-acce-20f6e5db69eb |                  0 |                         0 |                           0
 Unearth          | unearth          | c2d298f74835191e93848bb784b2985c | battle_rule_v1:efd07ef68567702f9ddf63eaceaea872 | deprecate_nonmatching_rows |                1 | bc3f92fd-a01b-45d0-970b-007bce684208 |                  2 |                         0 |                           2
 Wander in Death  | wander in death  | c2b6b8df32f9cb2987c9b81a14629e97 | battle_rule_v1:76aa1102386b493fec63d732eba4e344 | deprecate_nonmatching_rows |                1 | 790ea1bc-0224-40cf-952a-ff8f52f99cf8 |                  0 |                         0 |                           0
(5 rows)
```

## stderr

```

```
