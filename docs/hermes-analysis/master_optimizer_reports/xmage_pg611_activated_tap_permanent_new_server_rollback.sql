BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('auriok transfixer', 'benalish trapper', 'blinding souleater', 'gideon''s lawkeeper', 'icy manipulator', 'loxodon mystic', 'master decoy', 'minister of impediments', 'ostiary thrull', 'pacification array', 'scepter of dominance')
   OR normalized_name LIKE 'auriok transfixer // %'
   OR normalized_name LIKE 'benalish trapper // %'
   OR normalized_name LIKE 'blinding souleater // %'
   OR normalized_name LIKE 'gideon''s lawkeeper // %'
   OR normalized_name LIKE 'icy manipulator // %'
   OR normalized_name LIKE 'loxodon mystic // %'
   OR normalized_name LIKE 'master decoy // %'
   OR normalized_name LIKE 'minister of impediments // %'
   OR normalized_name LIKE 'ostiary thrull // %'
   OR normalized_name LIKE 'pacification array // %'
   OR normalized_name LIKE 'scepter of dominance // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg611_activated_tap_permanent_new_server_20260707_111500;

COMMIT;
