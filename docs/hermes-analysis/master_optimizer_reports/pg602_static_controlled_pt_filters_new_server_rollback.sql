BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('builder''s blessing', 'castle', 'dire fleet neckbreaker', 'goblin oriflamme', 'honor of the pure', 'jacques le vert', 'kaysa', 'orcish oriflamme', 'war horn')
   OR normalized_name LIKE 'builder''s blessing // %'
   OR normalized_name LIKE 'castle // %'
   OR normalized_name LIKE 'dire fleet neckbreaker // %'
   OR normalized_name LIKE 'goblin oriflamme // %'
   OR normalized_name LIKE 'honor of the pure // %'
   OR normalized_name LIKE 'jacques le vert // %'
   OR normalized_name LIKE 'kaysa // %'
   OR normalized_name LIKE 'orcish oriflamme // %'
   OR normalized_name LIKE 'war horn // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg602_static_controlled_pt_filters_new_s_20260707_075017;

COMMIT;
