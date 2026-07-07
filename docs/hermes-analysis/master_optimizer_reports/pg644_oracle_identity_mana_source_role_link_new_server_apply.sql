BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg644_oracle_identity_mana_source_role_link_20260707 AS
SELECT *
FROM public.card_battle_rules
WHERE card_id IN (
    '037e2cf5-cd46-4d03-975d-fb877e4de51a'::uuid,
    '083da955-e31c-4d6b-a0f1-dfdf1569d9d8'::uuid,
    'db2d9112-7066-44cb-beea-29e30ade8fe3'::uuid,
    'c971ff63-79d9-45e4-a7d9-4aec4eecd525'::uuid
  )
  OR lower(card_name) IN (
    lower('Birds of Paradise'),
    lower('Birds of Paradise // Birds of Paradise'),
    lower('Sol Ring'),
    lower('Sol Ring // Sol Ring')
  );

DO $$
DECLARE
  v_bad jsonb;
BEGIN
  WITH plan(target_name, target_card_id, donor_name, donor_card_id, donor_logical_rule_key, expected_oracle_hash, repaired_deck_role_json) AS (
    VALUES
      (
        'Birds of Paradise // Birds of Paradise',
        'db2d9112-7066-44cb-beea-29e30ade8fe3'::uuid,
        'Birds of Paradise',
        '037e2cf5-cd46-4d03-975d-fb877e4de51a'::uuid,
        'battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba',
        '2119fc1976cfab2480a9d86c57f1859b',
        '{"category":"ramp","effect":"creature","subtype":"mana_dork","timing":"battlefield"}'::jsonb
      ),
      (
        'Sol Ring // Sol Ring',
        'c971ff63-79d9-45e4-a7d9-4aec4eecd525'::uuid,
        'Sol Ring',
        '083da955-e31c-4d6b-a0f1-dfdf1569d9d8'::uuid,
        'battle_rule_v1:42621fcae461313f674d46db0da059af',
        '7d286f5619ac8934fb07abf152ffcb60',
        '{"category":"ramp","effect":"ramp_permanent","subtype":"fast_mana_rock"}'::jsonb
      )
  ),
  checks AS (
    SELECT
      p.target_name,
      p.donor_name,
      t.id AS target_id,
      d.id AS donor_id,
      r.logical_rule_key,
      t.oracle_id AS target_oracle_id,
      d.oracle_id AS donor_oracle_id,
      md5(coalesce(t.oracle_text, '')) AS target_oracle_hash,
      md5(coalesce(d.oracle_text, '')) AS donor_oracle_hash,
      r.oracle_hash AS donor_rule_hash,
      r.review_status,
      r.execution_status
    FROM plan p
    LEFT JOIN public.cards t ON t.id = p.target_card_id
    LEFT JOIN public.cards d ON d.id = p.donor_card_id
    LEFT JOIN public.card_battle_rules r
      ON r.card_id = p.donor_card_id
     AND r.logical_rule_key = p.donor_logical_rule_key
  )
  SELECT jsonb_agg(checks ORDER BY target_name)
    INTO v_bad
  FROM checks
  WHERE target_id IS NULL
     OR donor_id IS NULL
     OR logical_rule_key IS NULL
     OR target_oracle_id IS DISTINCT FROM donor_oracle_id
     OR target_oracle_hash <> donor_rule_hash
     OR donor_oracle_hash <> donor_rule_hash
     OR review_status NOT IN ('verified', 'active')
     OR execution_status = 'disabled';

  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'PG644 abort: unsafe oracle identity rule link precheck failed: %', v_bad;
  END IF;
END $$;

WITH role_repair(card_id, logical_rule_key, deck_role_json, effect_patch_json) AS (
  VALUES
    (
      '037e2cf5-cd46-4d03-975d-fb877e4de51a'::uuid,
      'battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba',
      '{"category":"ramp","effect":"creature","subtype":"mana_dork","timing":"battlefield"}'::jsonb,
      '{"is_mana_source":true,"mana_activation_requires_tap":true}'::jsonb
    ),
    (
      '083da955-e31c-4d6b-a0f1-dfdf1569d9d8'::uuid,
      'battle_rule_v1:42621fcae461313f674d46db0da059af',
      '{"category":"ramp","effect":"ramp_permanent","subtype":"fast_mana_rock"}'::jsonb,
      '{"is_mana_source":true,"mana_activation_requires_tap":true}'::jsonb
    )
),
updated AS (
  UPDATE public.card_battle_rules r
  SET
    effect_json = r.effect_json || rr.effect_patch_json,
    deck_role_json = rr.deck_role_json,
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG644: effect_json/deck_role_json repaired to match executable tapped mana-source purpose for battle and deckbuilder/AI consumption.'),
    reviewed_by = 'codex-pg644-oracle-identity-rule-link',
    reviewed_at = now()
  FROM role_repair rr
  WHERE r.card_id = rr.card_id
    AND r.logical_rule_key = rr.logical_rule_key
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status <> 'disabled'
  RETURNING r.card_name, r.logical_rule_key
)
SELECT count(*) AS donor_role_and_effect_rows_repaired FROM updated;

WITH plan(target_name, target_card_id, donor_name, donor_card_id, donor_logical_rule_key, repaired_deck_role_json) AS (
  VALUES
    (
      'Birds of Paradise // Birds of Paradise',
      'db2d9112-7066-44cb-beea-29e30ade8fe3'::uuid,
      'Birds of Paradise',
      '037e2cf5-cd46-4d03-975d-fb877e4de51a'::uuid,
      'battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba',
      '{"category":"ramp","effect":"creature","subtype":"mana_dork","timing":"battlefield"}'::jsonb
    ),
    (
      'Sol Ring // Sol Ring',
      'c971ff63-79d9-45e4-a7d9-4aec4eecd525'::uuid,
      'Sol Ring',
      '083da955-e31c-4d6b-a0f1-dfdf1569d9d8'::uuid,
      'battle_rule_v1:42621fcae461313f674d46db0da059af',
      '{"category":"ramp","effect":"ramp_permanent","subtype":"fast_mana_rock"}'::jsonb
    )
),
source_rows AS (
  SELECT
    lower(p.target_name) AS target_normalized_name,
    p.target_name,
    p.target_card_id,
    p.donor_name,
    r.effect_json,
    p.repaired_deck_role_json AS deck_role_json,
    r.source,
    r.confidence,
    'verified'::text AS review_status,
    'auto'::text AS execution_status,
    greatest(r.rule_version, 2) AS rule_version,
    r.oracle_hash,
    r.logical_rule_key,
    concat_ws(
      E'\n',
      nullif(r.notes, ''),
      format(
        'PG644 oracle identity rule link: copied from verified same-oracle rule %s to %s after oracle_id and oracle_hash match.',
        p.donor_name,
        p.target_name
      )
    ) AS notes
  FROM plan p
  JOIN public.cards target ON target.id = p.target_card_id
  JOIN public.cards donor ON donor.id = p.donor_card_id
  JOIN public.card_battle_rules r
    ON r.card_id = p.donor_card_id
   AND r.logical_rule_key = p.donor_logical_rule_key
  WHERE target.oracle_id = donor.oracle_id
    AND md5(coalesce(target.oracle_text, '')) = r.oracle_hash
    AND md5(coalesce(donor.oracle_text, '')) = r.oracle_hash
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status <> 'disabled'
),
upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at,
    logical_rule_key,
    execution_status
  )
  SELECT
    target_normalized_name,
    target_card_id,
    target_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    'codex-pg644-oracle-identity-rule-link',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM source_rows
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
    card_id = EXCLUDED.card_id,
    card_name = EXCLUDED.card_name,
    effect_json = EXCLUDED.effect_json,
    deck_role_json = EXCLUDED.deck_role_json,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    review_status = EXCLUDED.review_status,
    rule_version = EXCLUDED.rule_version,
    oracle_hash = EXCLUDED.oracle_hash,
    notes = EXCLUDED.notes,
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at,
    execution_status = EXCLUDED.execution_status
  RETURNING card_name, logical_rule_key
)
SELECT count(*) AS oracle_identity_rows_upserted FROM upserted;

COMMIT;
