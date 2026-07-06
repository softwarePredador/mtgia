BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('mage il-vec', 'molten vortex', 'ogre shaman', 'seismic assault', 'stormbind')
   OR normalized_name LIKE 'mage il-vec // %'
   OR normalized_name LIKE 'molten vortex // %'
   OR normalized_name LIKE 'ogre shaman // %'
   OR normalized_name LIKE 'seismic assault // %'
   OR normalized_name LIKE 'stormbind // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg539_activated_damage_discard_new_serve_20260706_003929;

COMMIT;
