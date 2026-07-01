WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('circuitous route', 'Circuitous Route', '6051a63cb1cdefe77244332e49b7ec9e', 'battle_rule_v1:75415f78fc41506cb6643e4da4c75645', '{"battle_model_scope":"xmage_library_search_to_battlefield_spell_v1","count":2,"effect":"tutor","instant":false,"max_count":2,"sorcery":true,"target":"basic_land_or_gate_to_battlefield","tutor_enters_tapped":true,"up_to_count":true,"xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"basic_land_or_gate_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CircuitousRoute translated into ManaLoom runtime scope xmage_library_search_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('farseek', 'Farseek', '3d220e13d39f456332fd1942b5f1b5ff', 'battle_rule_v1:01875ca2bef2ef737db5dd4dd89f3072', '{"battle_model_scope":"xmage_library_search_to_battlefield_spell_v1","count":1,"effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"plains_island_swamp_or_mountain_to_battlefield","tutor_enters_tapped":true,"xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"plains_island_swamp_or_mountain_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Farseek translated into ManaLoom runtime scope xmage_library_search_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('into the north', 'Into the North', 'bc846fd3be2dcc0f1289cb69136332a9', 'battle_rule_v1:643cb2ee6b30c8f266da6e0404dae862', '{"battle_model_scope":"xmage_library_search_to_battlefield_spell_v1","count":1,"effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"snow_land_to_battlefield","tutor_enters_tapped":true,"xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"snow_land_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IntoTheNorth translated into ManaLoom runtime scope xmage_library_search_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('natural connection', 'Natural Connection', '28a2eb8332c9a62d91c0045cb30b2789', 'battle_rule_v1:a73b5a8c526f65079dbf3ae06ead3cc0', '{"battle_model_scope":"xmage_library_search_to_battlefield_spell_v1","count":1,"effect":"tutor","instant":true,"max_count":1,"sorcery":false,"target":"basic_land_to_battlefield","tutor_enters_tapped":true,"xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"basic_land_to_battlefield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NaturalConnection translated into ManaLoom runtime scope xmage_library_search_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nature''s lore', 'Nature''s Lore', 'b5e10173aed1f51d6b673caf6ca6323a', 'battle_rule_v1:fd63f77a10200998a64bc33684bfcebe', '{"battle_model_scope":"xmage_library_search_to_battlefield_spell_v1","count":1,"effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"forest_to_battlefield","tutor_enters_tapped":false,"xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"forest_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NaturesLore translated into ManaLoom runtime scope xmage_library_search_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('personal tutor', 'Personal Tutor', '6f129458377e78394c9c0ca13ade5d7b', 'battle_rule_v1:24ba4d4516d812c41b7e1885110c8f7a', '{"battle_model_scope":"xmage_library_search_to_library_top_spell_v1","count":1,"effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"sorcery_to_top","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"sorcery_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PersonalTutor translated into ManaLoom runtime scope xmage_library_search_to_library_top_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ranger''s path', 'Ranger''s Path', '926eced288bafabfd7121fe0ae4e9cd8', 'battle_rule_v1:526efb31e105216651991ce18a6e3b29', '{"battle_model_scope":"xmage_library_search_to_battlefield_spell_v1","count":2,"effect":"tutor","instant":false,"max_count":2,"sorcery":true,"target":"forest_to_battlefield","tutor_enters_tapped":true,"up_to_count":true,"xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"forest_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RangersPath translated into ManaLoom runtime scope xmage_library_search_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reshape the earth', 'Reshape the Earth', '7753335b897bc2a4fbbaee2add490fc8', 'battle_rule_v1:3697d8196d752ec777cd6309eb097870', '{"battle_model_scope":"xmage_library_search_to_battlefield_spell_v1","count":10,"effect":"tutor","instant":false,"max_count":10,"sorcery":true,"target":"land_to_battlefield","tutor_enters_tapped":true,"up_to_count":true,"xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"land_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReshapeTheEarth translated into ManaLoom runtime scope xmage_library_search_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shared roots', 'Shared Roots', '28a2eb8332c9a62d91c0045cb30b2789', 'battle_rule_v1:be58bb6c0abf293ab9dd69ea3b920420', '{"battle_model_scope":"xmage_library_search_to_battlefield_spell_v1","count":1,"effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"basic_land_to_battlefield","tutor_enters_tapped":true,"xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"basic_land_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SharedRoots translated into ManaLoom runtime scope xmage_library_search_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skyshroud claim', 'Skyshroud Claim', '0307634c09fa9cefb39d181b40dfd9e2', 'battle_rule_v1:e717d04e6efe4dd1210b5957130e0581', '{"battle_model_scope":"xmage_library_search_to_battlefield_spell_v1","count":2,"effect":"tutor","instant":false,"max_count":2,"sorcery":true,"target":"forest_to_battlefield","tutor_enters_tapped":false,"up_to_count":true,"xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"forest_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkyshroudClaim translated into ManaLoom runtime scope xmage_library_search_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spoils of victory', 'Spoils of Victory', '0fcc8920a6fda054684bf4910b1ec6b9', 'battle_rule_v1:a9555c00ddbaa0fd30462074fa9dbc81', '{"battle_model_scope":"xmage_library_search_to_battlefield_spell_v1","count":1,"effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"basic_land_type_to_battlefield","tutor_enters_tapped":false,"xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"basic_land_type_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpoilsOfVictory translated into ManaLoom runtime scope xmage_library_search_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('three visits', 'Three Visits', '8758675234ffaa37187cf88be86fd490', 'battle_rule_v1:fd63f77a10200998a64bc33684bfcebe', '{"battle_model_scope":"xmage_library_search_to_battlefield_spell_v1","count":1,"effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"forest_to_battlefield","tutor_enters_tapped":false,"xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"forest_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThreeVisits translated into ManaLoom runtime scope xmage_library_search_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('untamed wilds', 'Untamed Wilds', 'bea1c0ffd5d697464a73cda5bc2ba751', 'battle_rule_v1:1dd26ac252db3cdd036cab38b068c82e', '{"battle_model_scope":"xmage_library_search_to_battlefield_spell_v1","count":1,"effect":"tutor","instant":false,"max_count":1,"sorcery":true,"target":"basic_land_to_battlefield","tutor_enters_tapped":false,"xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"tutor","effect":"tutor","target":"basic_land_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UntamedWilds translated into ManaLoom runtime scope xmage_library_search_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
