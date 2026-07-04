WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('call the gatewatch', 'Call the Gatewatch', 'c2f91fea6b8e3049f33ee913296a213c', 'battle_rule_v1:caae61758f5148c88717d895a55aa3e2', '{"battle_model_scope":"xmage_library_search_to_hand_spell_v1","count":1,"destination":"hand","effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"planeswalker_to_hand","target_card_types":["planeswalker"],"xmage_effect_class":"SearchLibraryPutInHandEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"planeswalker_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CallTheGatewatch translated into ManaLoom runtime scope xmage_library_search_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cateran summons', 'Cateran Summons', '47864ad63a4d50c1691191e60f961bc5', 'battle_rule_v1:2d7e82f759e6d816feb9c1b1054766a8', '{"battle_model_scope":"xmage_library_search_to_hand_spell_v1","count":1,"destination":"hand","effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"any_to_hand","target_card_types":["creature"],"target_subtypes":["mercenary"],"xmage_effect_class":"SearchLibraryPutInHandEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"any_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CateranSummons translated into ManaLoom runtime scope xmage_library_search_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('diabolic tutor', 'Diabolic Tutor', '7c881aaacf79f25b41c9788cf307e795', 'battle_rule_v1:3c1042b6ae3a2c610e70ad411460a46e', '{"battle_model_scope":"xmage_library_search_to_hand_spell_v1","count":1,"destination":"hand","effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"any_to_hand","xmage_effect_class":"SearchLibraryPutInHandEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"any_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DiabolicTutor translated into ManaLoom runtime scope xmage_library_search_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eerie procession', 'Eerie Procession', '98942b8c0812342e18938bf9c7ebeec4', 'battle_rule_v1:762264b1d43e6e1344585b6762d633f5', '{"battle_model_scope":"xmage_library_search_to_hand_spell_v1","count":1,"destination":"hand","effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"any_to_hand","target_subtypes":["arcane"],"xmage_effect_class":"SearchLibraryPutInHandEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"any_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EerieProcession translated into ManaLoom runtime scope xmage_library_search_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ignite the beacon', 'Ignite the Beacon', 'e6265bc22dd6b0fe6d4bb70a1ff9f1c7', 'battle_rule_v1:08ac438e086ce79989b6a0e05eed4b74', '{"battle_model_scope":"xmage_library_search_to_hand_spell_v1","count":2,"destination":"hand","effect":"tutor","instant":true,"max_count":2,"sorcery":false,"target":"planeswalker_to_hand","target_card_types":["planeswalker"],"up_to_count":true,"xmage_effect_class":"SearchLibraryPutInHandEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"planeswalker_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IgniteTheBeacon translated into ManaLoom runtime scope xmage_library_search_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('merchant scroll', 'Merchant Scroll', '9e130df41e16842e764941c6669ea620', 'battle_rule_v1:0d4352abb63d2eac010177d2e1f5f7e6', '{"battle_model_scope":"xmage_library_search_to_hand_spell_v1","count":1,"destination":"hand","effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"instant_to_hand","target_card_types":["instant"],"target_colors":["U"],"xmage_effect_class":"SearchLibraryPutInHandEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"instant_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MerchantScroll translated into ManaLoom runtime scope xmage_library_search_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('open the armory', 'Open the Armory', 'fa220f5773cf5c988e507c714b849503', 'battle_rule_v1:868d143f306cb5e8dfc486f76f8b6369', '{"battle_model_scope":"xmage_library_search_to_hand_spell_v1","count":1,"destination":"hand","effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"any_to_hand","target_subtypes":["aura","equipment"],"xmage_effect_class":"SearchLibraryPutInHandEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"any_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OpenTheArmory translated into ManaLoom runtime scope xmage_library_search_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('plea for guidance', 'Plea for Guidance', '5c417011e3ed943702026eefc309340f', 'battle_rule_v1:c0342670c739d786cd63c9aa0eb13e83', '{"battle_model_scope":"xmage_library_search_to_hand_spell_v1","count":2,"destination":"hand","effect":"tutor","instant":false,"max_count":2,"sorcery":true,"target":"enchantment_to_hand","target_card_types":["enchantment"],"up_to_count":true,"xmage_effect_class":"SearchLibraryPutInHandEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"enchantment_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PleaForGuidance translated into ManaLoom runtime scope xmage_library_search_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('safewright quest', 'Safewright Quest', '6d6ed58f38f4a9226bf9d849cbed96d1', 'battle_rule_v1:cd7fc0b01dfcf89afa14a9591f7e22bb', '{"battle_model_scope":"xmage_library_search_to_hand_spell_v1","count":1,"destination":"hand","effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"land_to_hand","target_card_types":["land"],"target_subtypes":["forest","plains"],"xmage_effect_class":"SearchLibraryPutInHandEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"land_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SafewrightQuest translated into ManaLoom runtime scope xmage_library_search_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sarkhan''s triumph', 'Sarkhan''s Triumph', 'b31496681c661b16b744df79de670d1b', 'battle_rule_v1:0f1e6a10f42f7c0c834c89ae0c6e72e4', '{"battle_model_scope":"xmage_library_search_to_hand_spell_v1","count":1,"destination":"hand","effect":"tutor","instant":true,"max_count":1,"sorcery":false,"target":"creature_to_hand","target_card_types":["creature"],"target_subtypes":["dragon"],"xmage_effect_class":"SearchLibraryPutInHandEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"creature_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SarkhansTriumph translated into ManaLoom runtime scope xmage_library_search_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('seek the horizon', 'Seek the Horizon', 'd74a1f98d1c82a4c62e872c89438fbc9', 'battle_rule_v1:18d04737564bf889d16bdd128abb8848', '{"battle_model_scope":"xmage_library_search_to_hand_spell_v1","count":3,"destination":"hand","effect":"tutor","instant":false,"max_count":3,"sorcery":true,"target":"basic_land_to_hand","up_to_count":true,"xmage_effect_class":"SearchLibraryPutInHandEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"basic_land_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SeekTheHorizon translated into ManaLoom runtime scope xmage_library_search_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('solve the equation', 'Solve the Equation', '14e38120c0e1603f7bca82f1c2b5e5f1', 'battle_rule_v1:43267ad1d8a2accee0fd7fbf8e17dcb1', '{"battle_model_scope":"xmage_library_search_to_hand_spell_v1","count":1,"destination":"hand","effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"instant_or_sorcery_to_hand","xmage_effect_class":"SearchLibraryPutInHandEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"instant_or_sorcery_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SolveTheEquation translated into ManaLoom runtime scope xmage_library_search_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('time of need', 'Time of Need', '9e4dbb5c6d939e1d3801c29b6173e7b5', 'battle_rule_v1:e5c23aff5977ec12d3a85ee773fe69df', '{"battle_model_scope":"xmage_library_search_to_hand_spell_v1","count":1,"destination":"hand","effect":"tutor","instant":false,"max_count":1,"required_supertypes":["legendary"],"sorcery":true,"target":"creature_to_hand","target_card_types":["creature"],"xmage_effect_class":"SearchLibraryPutInHandEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"creature_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TimeOfNeed translated into ManaLoom runtime scope xmage_library_search_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('trapmaker''s snare', 'Trapmaker''s Snare', '17aaa73f597367e9b8c77f1fa28f5301', 'battle_rule_v1:b9456967545569631aad27c2e338e700', '{"battle_model_scope":"xmage_library_search_to_hand_spell_v1","count":1,"destination":"hand","effect":"tutor","instant":true,"max_count":1,"sorcery":false,"target":"any_to_hand","target_subtypes":["trap"],"xmage_effect_class":"SearchLibraryPutInHandEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"any_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TrapmakersSnare translated into ManaLoom runtime scope xmage_library_search_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
