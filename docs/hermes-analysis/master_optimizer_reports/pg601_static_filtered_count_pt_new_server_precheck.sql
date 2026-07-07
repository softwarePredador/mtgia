WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('drove of elves', 'Drove of Elves', '131e8cde7732eb1ef1ceb88ebbe7a947', 'battle_rule_v1:9352e2d93851d8461826603244e7dbd1', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_card_types":["permanent"],"battlefield_count_required_colors":["G"],"battlefield_count_scope":"controller_battlefield","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","hexproof":true,"keywords":["hexproof"],"stat_modifier_amount_source":"battlefield_permanent_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_permanent_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DroveOfElves translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('faerie swarm', 'Faerie Swarm', '162931175d7b53537b17167d22e72768', 'battle_rule_v1:82b03276362694236249f62c7f46bf39', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_card_types":["permanent"],"battlefield_count_required_colors":["U"],"battlefield_count_scope":"controller_battlefield","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","flying":true,"keywords":["flying"],"stat_modifier_amount_source":"battlefield_permanent_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_permanent_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FaerieSwarm translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horde of boggarts', 'Horde of Boggarts', '202d984df7fa523bc1673942adc03058', 'battle_rule_v1:96b134ca40e7c700c44ab24a4c12d8a5', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_card_types":["permanent"],"battlefield_count_required_colors":["R"],"battlefield_count_scope":"controller_battlefield","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","keywords":["menace"],"menace":true,"stat_modifier_amount_source":"battlefield_permanent_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_permanent_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HordeOfBoggarts translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('keldon warlord', 'Keldon Warlord', '8a052ef361453b8ae84c89f3bfbd1610', 'battle_rule_v1:21aa1e0e1391fe07bcc4bc862de9bdde', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_card_types":["creature"],"battlefield_count_excluded_subtypes":["wall"],"battlefield_count_scope":"controller_battlefield","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"battlefield_permanent_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_permanent_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KeldonWarlord translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kithkin rabble', 'Kithkin Rabble', '2042a91b0d2249a2a4b25559a7c88aaf', 'battle_rule_v1:5885e8f1d82653d3f0fbb5790ab38b14', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_card_types":["permanent"],"battlefield_count_required_colors":["W"],"battlefield_count_scope":"controller_battlefield","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","keywords":["vigilance"],"stat_modifier_amount_source":"battlefield_permanent_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_permanent_count","target":"self","target_controller":"self","vigilance":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KithkinRabble translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('maraxus of keld', 'Maraxus of Keld', '610f3befdae27aa5e2d6804a4bbb1152', 'battle_rule_v1:e05e5c46890e728e0fb70f04c87e27c5', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_card_types":["artifact","creature","land"],"battlefield_count_scope":"controller_battlefield","battlefield_count_tapped_state":"untapped","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"battlefield_permanent_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_permanent_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MaraxusOfKeld translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('matca rioters', 'Matca Rioters', '16e8c8b1c044ed0f5249c9b1c2656de9', 'battle_rule_v1:0e4f35386e1edff745c8827be32b833a', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"domain_basic_land_types","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"domain_basic_land_types","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MatcaRioters translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('plague rats', 'Plague Rats', '394a289c515e1a81709e58536738c665', 'battle_rule_v1:ecee88ecfb15b8589f91b0a461c96eb5', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_card_names":["plague rats"],"battlefield_count_card_types":["creature"],"battlefield_count_scope":"all_battlefields","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"battlefield_permanent_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_permanent_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PlagueRats translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('regal bunnicorn', 'Regal Bunnicorn', 'd1e92c3afdd0b36291f6f039911e456a', 'battle_rule_v1:6e4c74ea938a3e8c30a4fc90be8ec877', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_card_types":["permanent"],"battlefield_count_excluded_card_types":["land"],"battlefield_count_scope":"controller_battlefield","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"battlefield_permanent_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_permanent_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RegalBunnicorn translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('territorial maro', 'Territorial Maro', '8aae0e3ee9336add3454ef1aae6f8052', 'battle_rule_v1:4c5577adfe685e63770106958a34f4f2', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"domain_basic_land_types","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":2,"static_power_toughness_source":"domain_basic_land_types","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TerritorialMaro translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
