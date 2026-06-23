\pset pager off

CREATE TEMP TABLE pg078_deck606_l2_target_rules(
  normalized_name text,
  logical_rule_key text
);

INSERT INTO pg078_deck606_l2_target_rules(normalized_name, logical_rule_key)
VALUES
  ('borrowed knowledge', 'battle_rule_v1:ab8c8e79988c1b44ccf6f4cd8324aa78'),
  ('chandra, hope''s beacon', 'battle_rule_v1:207d63694c9c3f9c9ee4bf5eb22689f1'),
  ('combustible gearhulk', 'battle_rule_v1:6a93d9061542e1b4b2c92baa569c56e9'),
  ('commander''s plate', 'battle_rule_v1:abc69abda697439c441b557d2ddf27ad'),
  ('farewell', 'battle_rule_v1:c5aef30c5a5904e02c4cfe40957080d3'),
  ('hit the mother lode', 'battle_rule_v1:3c85508fc77f408ea77c6ad8c81cab34'),
  ('hit the mother lode', 'battle_rule_v1:96918f32221fe2908cf49d33a457af2f'),
  ('improvisation capstone', 'battle_rule_v1:4a001137f9a15f1a45b994a4d63f1689'),
  ('increasing vengeance', 'battle_rule_v1:30ea39d59aa1ffc3158a49675b767c30'),
  ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3'),
  ('mithril coat', 'battle_rule_v1:af0db3c4541fbb0e337359c8420a613c'),
  ('olórin''s searing light', 'battle_rule_v1:ff60d5ae64eccde0c80bc7fb7b463ff4'),
  ('ondu inversion // ondu skyruins', 'battle_rule_v1:89baba2dcd27be9d4b7d0fcbdb82bb8f'),
  ('reckless endeavor', 'battle_rule_v1:58cf44e1552692ff62aeaf4ae3c7eaee'),
  ('restoration seminar', 'battle_rule_v1:e354df66477b8437134c5fb0bbb3e371'),
  ('reverse the sands', 'battle_rule_v1:70d3cbd28ace705feb076fb737205e90'),
  ('soulfire eruption', 'battle_rule_v1:57f8434c0cd32364c89eaf074940d0ec'),
  ('sunforger', 'battle_rule_v1:6e364810e102d8ab6c2ce482573d2f66'),
  ('swiftfoot boots', 'battle_rule_v1:86b568648669ceb1eef6d7f6b95d4f1c'),
  ('thought vessel', 'battle_rule_v1:93ac5946d2f83cec409a2892520f26d0'),
  ('tibalt''s trickery', 'battle_rule_v1:c3821ae5e8f44d1820ba5c1ed48c3366'),
  ('wayfarer''s bauble', 'battle_rule_v1:97eb0d5868d1c777b74aa7d35fc85eab'),
  ('wear // tear', 'battle_rule_v1:a89224366575c83b24415529fe686a0e');

WITH target_rows AS (
  SELECT
    t.normalized_name,
    t.logical_rule_key,
    c.name,
    md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
    cbr.source,
    cbr.review_status,
    cbr.execution_status,
    cbr.oracle_hash,
    cbr.effect_json,
    cbr.deck_role_json,
    backup.payload AS backup_payload
  FROM pg078_deck606_l2_target_rules t
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  JOIN cards c
    ON c.id = cbr.card_id
  LEFT JOIN manaloom_deploy_audit.pg078_deck606_l2_hash_scope_restore_20260623_063535 backup
    ON backup.payload->>'normalized_name' = cbr.normalized_name
   AND backup.payload->>'logical_rule_key' = cbr.logical_rule_key
),
shadow_rows AS (
  SELECT
    count(*) FILTER (
      WHERE cbr.execution_status NOT IN ('disabled', 'review_only')
        AND cbr.review_status NOT IN ('deprecated', 'needs_review')
    ) AS active_shadow_rows,
    count(*) FILTER (
      WHERE cbr.execution_status = 'disabled'
        AND cbr.review_status = 'deprecated'
    ) AS disabled_shadow_rows
  FROM card_battle_rules cbr
  WHERE cbr.normalized_name IN (SELECT DISTINCT normalized_name FROM pg078_deck606_l2_target_rules)
    AND NOT EXISTS (
      SELECT 1
      FROM pg078_deck606_l2_target_rules t
      WHERE t.normalized_name = cbr.normalized_name
        AND t.logical_rule_key = cbr.logical_rule_key
    )
)
SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (WHERE oracle_hash = expected_oracle_hash) AS target_hash_match_rows,
  count(*) FILTER (WHERE oracle_hash IS NULL) AS target_missing_hash_rows,
  count(*) FILTER (WHERE source = 'curated' AND execution_status = 'auto' AND review_status IN ('active', 'verified')) AS trusted_auto_rows,
  count(*) FILTER (WHERE effect_json ? 'battle_model_scope') AS scoped_target_rows,
  count(*) FILTER (WHERE backup_payload IS NOT NULL) AS target_backup_rows,
  count(*) FILTER (WHERE effect_json = backup_payload->'effect_json') AS effect_json_unchanged_rows,
  count(*) FILTER (WHERE deck_role_json = backup_payload->'deck_role_json') AS deck_role_json_unchanged_rows,
  (SELECT active_shadow_rows FROM shadow_rows) AS active_shadow_rows,
  (SELECT disabled_shadow_rows FROM shadow_rows) AS disabled_shadow_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg078_deck606_l2_hash_scope_restore_20260623_063535) AS total_backup_rows
FROM target_rows;

SELECT
  c.name,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.review_status,
  cbr.execution_status,
  cbr.confidence,
  cbr.rule_version,
  cbr.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
  cbr.effect_json->>'effect' AS effect,
  cbr.effect_json->>'battle_model_scope' AS battle_model_scope
FROM pg078_deck606_l2_target_rules t
JOIN card_battle_rules cbr
  ON cbr.normalized_name = t.normalized_name
 AND cbr.logical_rule_key = t.logical_rule_key
JOIN cards c
  ON c.id = cbr.card_id
ORDER BY c.name, cbr.logical_rule_key;
