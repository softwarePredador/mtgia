# PG848 precheck/apply/postcheck evidence

## Precheck
       card_name        |    normalized_name     |           oracle_hash            |                logical_rule_key                 |      shadow_handling       | target_card_rows |          canonical_card_id           | existing_rule_rows | expected_rule_rows_before | would_deprecate_shadow_rows
------------------------+------------------------+----------------------------------+-------------------------------------------------+----------------------------+------------------+--------------------------------------+--------------------+---------------------------+-----------------------------
 Accomplished Alchemist | accomplished alchemist | c9e44029a1331371a86431a87d427627 | battle_rule_v1:0037c915258cdef18a28daeff7ccf288 | deprecate_nonmatching_rows |                1 | d9b3b694-275c-4c97-bd20-fabd5be252d8 |                  0 |                         0 |                           0
(1 row)


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
             1
(1 row)

COMMIT

## Postcheck
       card_name        |    normalized_name     |                logical_rule_key                 | promoted_rule_rows | promoted_verified_auto_rows | promoted_oracle_hash_rows | backup_rows
------------------------+------------------------+-------------------------------------------------+--------------------+-----------------------------+---------------------------+-------------
 Accomplished Alchemist | accomplished alchemist | battle_rule_v1:0037c915258cdef18a28daeff7ccf288 |                  1 |                           1 |                         1 |           0
(1 row)
