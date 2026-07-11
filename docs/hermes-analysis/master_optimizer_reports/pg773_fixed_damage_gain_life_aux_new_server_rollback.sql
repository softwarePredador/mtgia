BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('covenant of blood', 'morbid hunger', 'sacred fire', 'smiting helix')
   OR normalized_name LIKE 'covenant of blood // %'
   OR normalized_name LIKE 'morbid hunger // %'
   OR normalized_name LIKE 'sacred fire // %'
   OR normalized_name LIKE 'smiting helix // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg773_fixed_damage_gain_life_aux_new_ser_20260711_163104;

COMMIT;
