BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc058_deck607_land_oracle_hash_backfill_20260629') IS NOT NULL THEN
    RAISE EXCEPTION 'PGC058 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc058_deck607_land_oracle_hash_backfill_20260629 AS
WITH expected(normalized_name, logical_rule_key, expected_oracle_hash) AS (
  VALUES
    ('ancient tomb', 'battle_rule_v1:c364544e9bd651211acf851db2313ccd', '5f61966c5bfc67508502d929ca891af3'),
    ('command beacon', 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be', '6dd67a5b15e472ba84c942ab36ac1786'),
    ('eiganjo, seat of the empire', 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be', '25b37ca517c49d61b17a9dc180dc8ea8'),
    ('reliquary tower', 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be', 'ff80b35ee08bb1b68ec7c0be24d6eaaa'),
    ('sunbaked canyon', 'battle_rule_v1:07c97c73f65d524510e30b6bbfca0b61', 'eae946655b75e4666adfbdb760bee0ff'),
    ('urza''s saga', 'battle_rule_v1:b62b6dfa5cdc9db4b8b21faf7bfc0498', '43e3b1636425f22bbd834442ddb93bc0'),
    ('war room', 'battle_rule_v1:9cdb33ac0e813c0a25d960b65dbc7417', 'd9c250570bb91d94ceae9fcd74081ef5')
)
SELECT r.*
FROM public.card_battle_rules r
JOIN expected e
  ON r.normalized_name = e.normalized_name
 AND r.logical_rule_key = e.logical_rule_key;

DO $$
DECLARE
  updated_count integer;
BEGIN
  WITH expected(normalized_name, logical_rule_key, expected_oracle_hash) AS (
    VALUES
      ('ancient tomb', 'battle_rule_v1:c364544e9bd651211acf851db2313ccd', '5f61966c5bfc67508502d929ca891af3'),
      ('command beacon', 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be', '6dd67a5b15e472ba84c942ab36ac1786'),
      ('eiganjo, seat of the empire', 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be', '25b37ca517c49d61b17a9dc180dc8ea8'),
      ('reliquary tower', 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be', 'ff80b35ee08bb1b68ec7c0be24d6eaaa'),
      ('sunbaked canyon', 'battle_rule_v1:07c97c73f65d524510e30b6bbfca0b61', 'eae946655b75e4666adfbdb760bee0ff'),
      ('urza''s saga', 'battle_rule_v1:b62b6dfa5cdc9db4b8b21faf7bfc0498', '43e3b1636425f22bbd834442ddb93bc0'),
      ('war room', 'battle_rule_v1:9cdb33ac0e813c0a25d960b65dbc7417', 'd9c250570bb91d94ceae9fcd74081ef5')
  ),
  checked AS (
    SELECT
      e.normalized_name,
      e.logical_rule_key,
      e.expected_oracle_hash
    FROM expected e
    JOIN public.card_battle_rules r
      ON r.normalized_name = e.normalized_name
     AND r.logical_rule_key = e.logical_rule_key
    JOIN public.cards c
      ON c.id = r.card_id
    WHERE md5(coalesce(c.oracle_text, '')) = e.expected_oracle_hash
      AND r.review_status IN ('verified', 'active')
      AND r.execution_status IN ('auto', 'executable')
  )
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = checked.expected_oracle_hash,
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC058: filled deck 607 active land oracle_hash from md5(cards.oracle_text); behavior unchanged.'
    ),
    updated_at = now(),
    last_seen_at = now()
  FROM checked
  WHERE r.normalized_name = checked.normalized_name
    AND r.logical_rule_key = checked.logical_rule_key;

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 7 THEN
    RAISE EXCEPTION 'PGC058 expected to update 7 active deck 607 land rows, updated %', updated_count;
  END IF;
END $$;

COMMIT;
