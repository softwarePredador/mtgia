WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('runaway trash-bot', 'Runaway Trash-Bot', '3e2e7609e4267fc6e89824d487e207a1', 'battle_rule_v1:913735c6f27a40d02848b0feb763d625', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_equal_graveyard_count_v1","effect":"creature","graveyard_count_card_types":["artifact","enchantment"],"graveyard_count_scope":"controller_graveyard","keywords":["trample"],"static_effect":"source_power_toughness_boost_equal_graveyard_count","static_power_bonus_per_graveyard_count":1,"static_toughness_bonus_per_graveyard_count":0,"target":"self","target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RunawayTrashBot translated into ManaLoom runtime scope xmage_static_source_boost_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('xande, dark mage', 'Xande, Dark Mage', '7492ac3535b38c79b1b59cece65be02a', 'battle_rule_v1:4e025c36a4e055acfdf8f7f974c35192', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_equal_graveyard_count_v1","effect":"creature","graveyard_count_card_types":["noncreature_nonland"],"graveyard_count_scope":"controller_graveyard","keywords":["menace"],"menace":true,"static_effect":"source_power_toughness_boost_equal_graveyard_count","static_power_bonus_per_graveyard_count":1,"static_toughness_bonus_per_graveyard_count":1,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class XandeDarkMage translated into ManaLoom runtime scope xmage_static_source_boost_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
