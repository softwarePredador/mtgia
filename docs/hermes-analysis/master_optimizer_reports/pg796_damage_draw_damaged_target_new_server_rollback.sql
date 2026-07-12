BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('needle drop')
   OR normalized_name LIKE 'needle drop // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg796_damage_draw_damaged_target_new_ser_20260712_005146;

COMMIT;
