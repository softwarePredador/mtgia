BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('defile', 'desert''s due', 'drag down', 'feeding frenzy', 'gaea''s might', 'hunger of the nim', 'inner calm, outer strength', 'irradiate', 'might of alara', 'might of the masses', 'nightmarish end', 'strength of cedars', 'warped physique', 'wirewood pride')
   OR normalized_name LIKE 'defile // %'
   OR normalized_name LIKE 'desert''s due // %'
   OR normalized_name LIKE 'drag down // %'
   OR normalized_name LIKE 'feeding frenzy // %'
   OR normalized_name LIKE 'gaea''s might // %'
   OR normalized_name LIKE 'hunger of the nim // %'
   OR normalized_name LIKE 'inner calm, outer strength // %'
   OR normalized_name LIKE 'irradiate // %'
   OR normalized_name LIKE 'might of alara // %'
   OR normalized_name LIKE 'might of the masses // %'
   OR normalized_name LIKE 'nightmarish end // %'
   OR normalized_name LIKE 'strength of cedars // %'
   OR normalized_name LIKE 'warped physique // %'
   OR normalized_name LIKE 'wirewood pride // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg445_xmage_dynamic_count_boost_new_server_20260704_2254;

COMMIT;
