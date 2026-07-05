BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('annihilate', 'eastern paladin', 'execute', 'slay')
   OR normalized_name LIKE 'annihilate // %'
   OR normalized_name LIKE 'eastern paladin // %'
   OR normalized_name LIKE 'execute // %'
   OR normalized_name LIKE 'slay // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg513_xmage_pg513_destroy_draw_color_tar_20260705_150547;

COMMIT;
