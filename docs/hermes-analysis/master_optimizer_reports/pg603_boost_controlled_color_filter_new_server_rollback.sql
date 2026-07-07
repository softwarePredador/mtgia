BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('guardians'' pledge')
   OR normalized_name LIKE 'guardians'' pledge // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg603_boost_controlled_color_filter_new_20260707_080717;

COMMIT;
