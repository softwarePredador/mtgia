WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('boneyard wurm', 'Boneyard Wurm', '868db55b4c54a9775793499c3b172f50', 'battle_rule_v1:ffedf5481ab19e7e4456d7d4cefa88e8', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_graveyard_count_v1","dynamic_power_equals_graveyard_count":true,"dynamic_toughness_equals_graveyard_count":true,"effect":"creature","graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","static_effect":"source_power_toughness_equal_graveyard_count","static_power_toughness_source":"graveyard_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoneyardWurm translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cantivore', 'Cantivore', '3adff21ac37d8460783bc26d29fe7952', 'battle_rule_v1:49c405fb50f9657a736715ece58c1cf2', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_graveyard_count_v1","dynamic_power_equals_graveyard_count":true,"dynamic_toughness_equals_graveyard_count":true,"effect":"creature","graveyard_count_card_types":["enchantment"],"graveyard_count_scope":"all_graveyards","keywords":["vigilance"],"static_effect":"source_power_toughness_equal_graveyard_count","static_power_toughness_source":"graveyard_count","target":"self","target_controller":"self","vigilance":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cantivore translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cognivore', 'Cognivore', 'c6e6afdc059fb07d89c674364b55e2d8', 'battle_rule_v1:68aa0a5a89c35b136144ea06eda2b2e7', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_graveyard_count_v1","dynamic_power_equals_graveyard_count":true,"dynamic_toughness_equals_graveyard_count":true,"effect":"creature","flying":true,"graveyard_count_card_types":["instant"],"graveyard_count_scope":"all_graveyards","keywords":["flying"],"static_effect":"source_power_toughness_equal_graveyard_count","static_power_toughness_source":"graveyard_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cognivore translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lord of extinction', 'Lord of Extinction', '4ad2f40f824019f50855ca4422e1bc8a', 'battle_rule_v1:d97a0e25b307046d4efbf53fd7bd1643', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_graveyard_count_v1","dynamic_power_equals_graveyard_count":true,"dynamic_toughness_equals_graveyard_count":true,"effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"all_graveyards","static_effect":"source_power_toughness_equal_graveyard_count","static_power_toughness_source":"graveyard_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LordOfExtinction translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magnivore', 'Magnivore', '6937ec01983fb5f782b75c9b8a674ea9', 'battle_rule_v1:ad96db5904f1b3dae2fbbad9858c9cde', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_graveyard_count_v1","dynamic_power_equals_graveyard_count":true,"dynamic_toughness_equals_graveyard_count":true,"effect":"creature","graveyard_count_card_types":["sorcery"],"graveyard_count_scope":"all_graveyards","haste":true,"keywords":["haste"],"static_effect":"source_power_toughness_equal_graveyard_count","static_power_toughness_source":"graveyard_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Magnivore translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revenant', 'Revenant', '12c2d3cd639198b6abb2d318fd963827', 'battle_rule_v1:45d2bc9afccf65066bbf30329eaf1ecc', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_graveyard_count_v1","dynamic_power_equals_graveyard_count":true,"dynamic_toughness_equals_graveyard_count":true,"effect":"creature","flying":true,"graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","keywords":["flying"],"static_effect":"source_power_toughness_equal_graveyard_count","static_power_toughness_source":"graveyard_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Revenant translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slag fiend', 'Slag Fiend', 'b5c07008c68627664343cef40a6d7da9', 'battle_rule_v1:9409b61e3a26aa64382a8dd06a768287', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_graveyard_count_v1","dynamic_power_equals_graveyard_count":true,"dynamic_toughness_equals_graveyard_count":true,"effect":"creature","graveyard_count_card_types":["artifact"],"graveyard_count_scope":"all_graveyards","static_effect":"source_power_toughness_equal_graveyard_count","static_power_toughness_source":"graveyard_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlagFiend translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('terravore', 'Terravore', '4d0cfe4cd8a6ae904d654899166a0fca', 'battle_rule_v1:ffa2d1bd2c22db6e3464b84bc934017d', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_graveyard_count_v1","dynamic_power_equals_graveyard_count":true,"dynamic_toughness_equals_graveyard_count":true,"effect":"creature","graveyard_count_card_types":["land"],"graveyard_count_scope":"all_graveyards","keywords":["trample"],"static_effect":"source_power_toughness_equal_graveyard_count","static_power_toughness_source":"graveyard_count","target":"self","target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Terravore translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
