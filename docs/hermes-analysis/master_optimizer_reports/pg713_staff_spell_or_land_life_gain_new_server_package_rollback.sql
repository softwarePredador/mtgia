BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('staff of the death magus', 'staff of the flame magus', 'staff of the mind magus', 'staff of the sun magus', 'staff of the wild magus')
   OR normalized_name LIKE 'staff of the death magus // %'
   OR normalized_name LIKE 'staff of the flame magus // %'
   OR normalized_name LIKE 'staff of the mind magus // %'
   OR normalized_name LIKE 'staff of the sun magus // %'
   OR normalized_name LIKE 'staff of the wild magus // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg713_staff_spell_or_land_life_gain_new_20260710_181601;

COMMIT;
