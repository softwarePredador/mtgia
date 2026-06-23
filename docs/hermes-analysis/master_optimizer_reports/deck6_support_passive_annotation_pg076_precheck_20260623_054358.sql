\pset pager off

CREATE TEMP TABLE pg076_target_cards AS
SELECT *
FROM (
  VALUES
    ('Drannith Magistrate', 'drannith magistrate', 'battle_rule_v1:673c58ea36aeaf798d78aaaa10892e3e', '2335f446bb72dcb00f41aed8faf2167a', 'static_nonhand_cast_restriction_annotation_creature_body_v1'),
    ('Giver of Runes', 'giver of runes', 'battle_rule_v1:c2736795c0d2c41d771b8a87319618bc', 'ae6856021d2bee0a8ba4d7e70ce56637', 'creature_body_protection_activation_annotation_v1'),
    ('Mother of Runes', 'mother of runes', 'battle_rule_v1:85d8c93e5ff3b531d4ab9217bd956948', '022c4e9496d2b5b6f0785bc63f8e9d11', 'creature_body_protection_activation_annotation_v1'),
    ('Professional Face-Breaker', 'professional face-breaker', 'battle_rule_v1:3d154b436fcb6b4f290cdd0246d5def4', '606b21e85871f60d1804eaabcd59ac5b', 'creature_body_menace_combat_damage_treasure_impulse_annotation_v1'),
    ('Ranger-Captain of Eos', 'ranger-captain of eos', 'battle_rule_v1:b05b64c0734daafd9c6f24ea02b39495', '43c8ec0dd0df9cecea5986a5ffb1d16d', 'creature_body_etb_small_creature_tutor_sacrifice_noncreature_silence_annotation_v1'),
    ('Storm-Kiln Artist', 'storm-kiln artist', 'battle_rule_v1:128e222b4de1e6308d98743711b54985', 'cb2cf161073de3983ac24385743ab78a', 'creature_body_artifact_power_magecraft_treasure_annotation_v1')
) AS t(card_name, normalized_name, logical_rule_key, expected_oracle_hash, expected_scope);

CREATE TEMP TABLE pg076_target_rules AS
SELECT
  c.name,
  c.type_line,
  c.mana_cost,
  c.cmc,
  md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
  c.oracle_text,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.confidence,
  cbr.rule_version,
  cbr.oracle_hash,
  cbr.effect_json,
  cbr.deck_role_json,
  cbr.notes
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
JOIN pg076_target_cards t ON t.card_name = c.name;

SELECT
  count(*) FILTER (
    WHERE c.name = t.card_name
      AND md5(coalesce(c.oracle_text, '')) = t.expected_oracle_hash
  ) AS target_cards_with_expected_oracle_hash,
  (SELECT count(*) FROM pg076_target_rules) AS existing_rule_rows,
  (
    SELECT count(*)
    FROM pg076_target_rules r
    JOIN pg076_target_cards t ON t.card_name = r.name
    WHERE r.logical_rule_key = t.logical_rule_key
      AND r.review_status = 'verified'
      AND r.execution_status = 'auto'
  ) AS target_curated_rows,
  (
    SELECT count(*)
    FROM pg076_target_rules r
    JOIN pg076_target_cards t ON t.card_name = r.name
    WHERE r.logical_rule_key <> t.logical_rule_key
      AND r.review_status = 'needs_review'
      AND r.execution_status = 'review_only'
  ) AS active_review_shadow_rows,
  (
    SELECT count(*)
    FROM pg076_target_rules r
    JOIN pg076_target_cards t ON t.card_name = r.name
    WHERE r.logical_rule_key = t.logical_rule_key
      AND (
        r.oracle_hash IS DISTINCT FROM t.expected_oracle_hash
        OR r.effect_json->>'battle_model_scope' IS DISTINCT FROM t.expected_scope
      )
  ) AS target_defect_rows,
  to_regclass('manaloom_deploy_audit.pg076_deck6_support_passive_annotation_20260623_054358') IS NOT NULL AS backup_table_already_exists
FROM cards c
JOIN pg076_target_cards t ON t.card_name = c.name;

SELECT
  name,
  type_line,
  mana_cost,
  cmc,
  current_oracle_hash,
  oracle_text
FROM pg076_target_rules
WHERE logical_rule_key IN (SELECT logical_rule_key FROM pg076_target_cards)
ORDER BY name;

SELECT
  name,
  normalized_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  confidence,
  rule_version,
  oracle_hash,
  current_oracle_hash,
  effect_json,
  deck_role_json,
  notes
FROM pg076_target_rules
ORDER BY name, review_status, execution_status, logical_rule_key;
