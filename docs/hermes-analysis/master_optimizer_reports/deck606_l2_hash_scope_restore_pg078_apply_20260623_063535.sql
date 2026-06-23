BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg078_deck606_l2_hash_scope_restore_20260623_063535') IS NOT NULL THEN
    RAISE EXCEPTION 'PG078 deck606 L2 hash/scope restore backup table already exists';
  END IF;
END $$;

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

CREATE TABLE manaloom_deploy_audit.pg078_deck606_l2_hash_scope_restore_20260623_063535 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name IN (
  SELECT DISTINCT normalized_name FROM pg078_deck606_l2_target_rules
);

DO $$
DECLARE
  v_target integer;
  v_with_oracle integer;
  v_missing_hash integer;
  v_scoped integer;
BEGIN
  SELECT
    count(*),
    count(*) FILTER (WHERE c.oracle_text IS NOT NULL),
    count(*) FILTER (WHERE cbr.oracle_hash IS NULL),
    count(*) FILTER (WHERE cbr.effect_json ? 'battle_model_scope')
  INTO v_target, v_with_oracle, v_missing_hash, v_scoped
  FROM pg078_deck606_l2_target_rules t
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  JOIN cards c
    ON c.id = cbr.card_id
  WHERE cbr.source = 'curated'
    AND cbr.execution_status = 'auto'
    AND cbr.review_status IN ('active', 'verified');

  IF v_target <> 23 THEN
    RAISE EXCEPTION 'PG078 deck606 L2 precondition failed: expected 23 trusted target rules, got %', v_target;
  END IF;
  IF v_with_oracle <> 23 THEN
    RAISE EXCEPTION 'PG078 deck606 L2 precondition failed: expected 23 target oracle texts, got %', v_with_oracle;
  END IF;
  IF v_missing_hash <> 23 THEN
    RAISE EXCEPTION 'PG078 deck606 L2 precondition failed: expected 23 missing hashes, got %', v_missing_hash;
  END IF;
  IF v_scoped <> 23 THEN
    RAISE EXCEPTION 'PG078 deck606 L2 precondition failed: expected 23 scoped target rows, got %', v_scoped;
  END IF;
END $$;

DO $$
DECLARE
  v_updated integer;
BEGIN
  WITH updated AS (
    UPDATE card_battle_rules cbr
    SET
      oracle_hash = md5(coalesce(c.oracle_text, '')),
      reviewed_by = 'codex-auditor',
      reviewed_at = now(),
      updated_at = now(),
      last_seen_at = now(),
      notes = concat_ws(
        E'\n',
        nullif(cbr.notes, ''),
        'PG078: restored deck606 L2 oracle_hash provenance for an already reviewed scoped executable rule. No semantic runtime, effect_json, deck_role_json, or deck composition change.'
      )
    FROM pg078_deck606_l2_target_rules t, cards c
    WHERE cbr.normalized_name = t.normalized_name
      AND cbr.logical_rule_key = t.logical_rule_key
      AND c.id = cbr.card_id
      AND cbr.oracle_hash IS NULL
    RETURNING 1
  )
  SELECT count(*) INTO v_updated FROM updated;

  IF v_updated <> 23 THEN
    RAISE EXCEPTION 'PG078 deck606 L2 hash update failed: expected 23 updated rows, got %', v_updated;
  END IF;
END $$;

UPDATE card_battle_rules cbr
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG078: disabled superseded deck606 L2 shadow row after scoped trusted executable replacement retained oracle_hash provenance.'
  )
WHERE cbr.normalized_name IN (SELECT DISTINCT normalized_name FROM pg078_deck606_l2_target_rules)
  AND NOT EXISTS (
    SELECT 1
    FROM pg078_deck606_l2_target_rules t
    WHERE t.normalized_name = cbr.normalized_name
      AND t.logical_rule_key = cbr.logical_rule_key
  )
  AND (
    cbr.source = 'generated'
    OR (
      cbr.normalized_name = 'wayfarer''s bauble'
      AND cbr.logical_rule_key = 'battle_rule_v1:46ba2b759b0c9a870fc137d59e42ecd5'
    )
  )
  AND cbr.execution_status <> 'disabled';

COMMIT;
