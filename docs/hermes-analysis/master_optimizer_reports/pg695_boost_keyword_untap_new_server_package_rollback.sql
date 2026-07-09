BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('acrobatic leap', 'aim high', 'arachnoid adaptation', 'bull''s strength', 'escape from orthanc', 'high stride', 'leaping ambush', 'magic damper', 'octopus form', 'pillar launch', 'riverguard''s reflexes', 'spidery grasp', 'steady aim', 'vines of the recluse', 'wings of the cosmos', 'witch''s web')
   OR normalized_name LIKE 'acrobatic leap // %'
   OR normalized_name LIKE 'aim high // %'
   OR normalized_name LIKE 'arachnoid adaptation // %'
   OR normalized_name LIKE 'bull''s strength // %'
   OR normalized_name LIKE 'escape from orthanc // %'
   OR normalized_name LIKE 'high stride // %'
   OR normalized_name LIKE 'leaping ambush // %'
   OR normalized_name LIKE 'magic damper // %'
   OR normalized_name LIKE 'octopus form // %'
   OR normalized_name LIKE 'pillar launch // %'
   OR normalized_name LIKE 'riverguard''s reflexes // %'
   OR normalized_name LIKE 'spidery grasp // %'
   OR normalized_name LIKE 'steady aim // %'
   OR normalized_name LIKE 'vines of the recluse // %'
   OR normalized_name LIKE 'wings of the cosmos // %'
   OR normalized_name LIKE 'witch''s web // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg695_boost_keyword_untap_new_server_20260709_062716;

COMMIT;
