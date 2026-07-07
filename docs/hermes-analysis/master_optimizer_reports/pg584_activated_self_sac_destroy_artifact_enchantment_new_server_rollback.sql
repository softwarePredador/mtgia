BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('capashen unicorn', 'caustic caterpillar', 'dispeller''s capsule', 'inspired insurgent', 'seal of cleansing', 'sylvok replica', 'thrashing brontodon', 'viridian zealot')
   OR normalized_name LIKE 'capashen unicorn // %'
   OR normalized_name LIKE 'caustic caterpillar // %'
   OR normalized_name LIKE 'dispeller''s capsule // %'
   OR normalized_name LIKE 'inspired insurgent // %'
   OR normalized_name LIKE 'seal of cleansing // %'
   OR normalized_name LIKE 'sylvok replica // %'
   OR normalized_name LIKE 'thrashing brontodon // %'
   OR normalized_name LIKE 'viridian zealot // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg584_activated_self_sac_destroy_artifac_20260707_011753;

COMMIT;
