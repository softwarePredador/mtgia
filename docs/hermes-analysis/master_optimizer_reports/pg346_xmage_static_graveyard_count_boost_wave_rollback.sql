BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('liliana''s elite', 'salvage slasher', 'wight of precinct six')
   OR normalized_name LIKE 'liliana''s elite // %'
   OR normalized_name LIKE 'salvage slasher // %'
   OR normalized_name LIKE 'wight of precinct six // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg346_xmage_static_graveyard_count_boost_wave_20260702_0;

COMMIT;
