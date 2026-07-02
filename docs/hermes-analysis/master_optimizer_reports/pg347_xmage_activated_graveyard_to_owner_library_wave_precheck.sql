WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cogwork archivist', 'Cogwork Archivist', '1482657c89ba046a75f2ed25baaa3ccb', 'battle_rule_v1:d05003e38a6b3d274e08dc5154cac346', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"graveyard_to_library","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","count":1,"destination":"library_bottom","effect":"recursion","graveyard_to_library_destination":"library_bottom","graveyard_to_library_target":"any_card","graveyard_to_library_target_count":1,"library_controller":"owner","target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_graveyard_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","activated_effect":"graveyard_to_library","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","effect":"creature","graveyard_to_library_activation_cost_colors":[],"graveyard_to_library_activation_cost_generic":2,"graveyard_to_library_activation_cost_mana":"{2}","graveyard_to_library_activation_requires_sacrifice":false,"graveyard_to_library_activation_requires_tap":true,"graveyard_to_library_destination":"library_bottom","graveyard_to_library_target":"any_card","graveyard_to_library_target_count":1,"keywords":["reach"],"library_controller":"owner","reach":true,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_graveyard_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CogworkArchivist translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_library_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-library ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jade-cast sentinel', 'Jade-Cast Sentinel', '1482657c89ba046a75f2ed25baaa3ccb', 'battle_rule_v1:d05003e38a6b3d274e08dc5154cac346', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"graveyard_to_library","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","count":1,"destination":"library_bottom","effect":"recursion","graveyard_to_library_destination":"library_bottom","graveyard_to_library_target":"any_card","graveyard_to_library_target_count":1,"library_controller":"owner","target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_graveyard_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","activated_effect":"graveyard_to_library","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","effect":"creature","graveyard_to_library_activation_cost_colors":[],"graveyard_to_library_activation_cost_generic":2,"graveyard_to_library_activation_cost_mana":"{2}","graveyard_to_library_activation_requires_sacrifice":false,"graveyard_to_library_activation_requires_tap":true,"graveyard_to_library_destination":"library_bottom","graveyard_to_library_target":"any_card","graveyard_to_library_target_count":1,"keywords":["reach"],"library_controller":"owner","reach":true,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_graveyard_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JadeCastSentinel translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_library_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-library ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('junktroller', 'Junktroller', '30284983e5a4c2290724f68e2e91d7f1', 'battle_rule_v1:8a392db3a674e479dd61e8eba7379f64', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"graveyard_to_library","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","count":1,"destination":"library_bottom","effect":"recursion","graveyard_to_library_destination":"library_bottom","graveyard_to_library_target":"any_card","graveyard_to_library_target_count":1,"library_controller":"owner","target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_graveyard_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","activated_effect":"graveyard_to_library","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","defender":true,"effect":"creature","graveyard_to_library_activation_cost_colors":[],"graveyard_to_library_activation_cost_generic":0,"graveyard_to_library_activation_cost_mana":"{0}","graveyard_to_library_activation_requires_sacrifice":false,"graveyard_to_library_activation_requires_tap":true,"graveyard_to_library_destination":"library_bottom","graveyard_to_library_target":"any_card","graveyard_to_library_target_count":1,"keywords":["defender"],"library_controller":"owner","target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_graveyard_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Junktroller translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_library_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-library ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('phyrexian archivist', 'Phyrexian Archivist', '1482657c89ba046a75f2ed25baaa3ccb', 'battle_rule_v1:d05003e38a6b3d274e08dc5154cac346', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"graveyard_to_library","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","count":1,"destination":"library_bottom","effect":"recursion","graveyard_to_library_destination":"library_bottom","graveyard_to_library_target":"any_card","graveyard_to_library_target_count":1,"library_controller":"owner","target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_graveyard_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","activated_effect":"graveyard_to_library","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","effect":"creature","graveyard_to_library_activation_cost_colors":[],"graveyard_to_library_activation_cost_generic":2,"graveyard_to_library_activation_cost_mana":"{2}","graveyard_to_library_activation_requires_sacrifice":false,"graveyard_to_library_activation_requires_tap":true,"graveyard_to_library_destination":"library_bottom","graveyard_to_library_target":"any_card","graveyard_to_library_target_count":1,"keywords":["reach"],"library_controller":"owner","reach":true,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_graveyard_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PhyrexianArchivist translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_library_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-library ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reito lantern', 'Reito Lantern', '7d614dc5f48178acc94c07a17161be68', 'battle_rule_v1:c3a746488b6593a3a50eee55ff2ecf06', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"graveyard_to_library","activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","count":1,"destination":"library_bottom","effect":"recursion","graveyard_to_library_destination":"library_bottom","graveyard_to_library_target":"any_card","graveyard_to_library_target_count":1,"library_controller":"owner","target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_graveyard_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","activated_effect":"graveyard_to_library","activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_library_v1","effect":"artifact","graveyard_to_library_activation_cost_colors":[],"graveyard_to_library_activation_cost_generic":3,"graveyard_to_library_activation_cost_mana":"{3}","graveyard_to_library_activation_requires_sacrifice":false,"graveyard_to_library_activation_requires_tap":false,"graveyard_to_library_destination":"library_bottom","graveyard_to_library_target":"any_card","graveyard_to_library_target_count":1,"library_controller":"owner","target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_graveyard_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReitoLantern translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_library_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-library ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
