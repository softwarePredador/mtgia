BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('akroan jailer', 'akroan mastiff', 'blinding mage', 'checkpoint officer', 'elite arrester', 'fan bearer', 'frostbridge guard', 'gavony trapper', 'goldmeadow harrier', 'nebelgast beguiler', 'rathi trapper', 'trip noose', 'tyrant''s machine')
   OR normalized_name LIKE 'akroan jailer // %'
   OR normalized_name LIKE 'akroan mastiff // %'
   OR normalized_name LIKE 'blinding mage // %'
   OR normalized_name LIKE 'checkpoint officer // %'
   OR normalized_name LIKE 'elite arrester // %'
   OR normalized_name LIKE 'fan bearer // %'
   OR normalized_name LIKE 'frostbridge guard // %'
   OR normalized_name LIKE 'gavony trapper // %'
   OR normalized_name LIKE 'goldmeadow harrier // %'
   OR normalized_name LIKE 'nebelgast beguiler // %'
   OR normalized_name LIKE 'rathi trapper // %'
   OR normalized_name LIKE 'trip noose // %'
   OR normalized_name LIKE 'tyrant''s machine // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg552_activated_tap_target_creature_new_20260706_052155;

COMMIT;
