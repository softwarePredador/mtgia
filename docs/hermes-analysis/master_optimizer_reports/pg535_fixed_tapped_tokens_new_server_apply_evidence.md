# PG535 Fixed Tapped Tokens New Server Apply Evidence

- Generated at UTC: 2026-07-05T23:02:17Z
- Database target: 143.198.230.247:5433/halder

## Precheck
    card_name     | normalized_name  |           oracle_hash            |                logical_rule_key                 |      shadow_handling       | target_card_rows |          canonical_card_id           | existing_rule_rows | expected_rule_rows_before | would_deprecate_shadow_rows
------------------+------------------+----------------------------------+-------------------------------------------------+----------------------------+------------------+--------------------------------------+--------------------+---------------------------+-----------------------------
 Servo Exhibition | servo exhibition | 986014963b1bb2a9361b04c58130bfca | battle_rule_v1:34867bd8005e3b1fb592b3dfb9a585ed | deprecate_nonmatching_rows |                1 | 2870d92a-998e-4e56-8589-261895ba14ac |                  0 |                         0 |                           0
 Shadow Summoning | shadow summoning | 86865fd932dbac3129e8d1060691bc0d | battle_rule_v1:e4509add508bcaf39e79f2811c958b41 | deprecate_nonmatching_rows |                1 | faa1e3a0-2c26-414f-9591-305dbfc2906b |                  0 |                         0 |                           0
(2 rows)


## Apply
BEGIN
CREATE SCHEMA
SELECT 0
DO
 deprecated_shadow_rows
------------------------
                      0
(1 row)

 upserted_rows
---------------
             2
(1 row)

COMMIT

## Postcheck
    card_name     | normalized_name  |                logical_rule_key                 | promoted_rule_rows | promoted_verified_auto_rows | promoted_oracle_hash_rows | backup_rows
------------------+------------------+-------------------------------------------------+--------------------+-----------------------------+---------------------------+-------------
 Servo Exhibition | servo exhibition | battle_rule_v1:34867bd8005e3b1fb592b3dfb9a585ed |                  1 |                           1 |                         1 |           0
 Shadow Summoning | shadow summoning | battle_rule_v1:e4509add508bcaf39e79f2811c958b41 |                  1 |                           1 |                         1 |           0
(2 rows)
