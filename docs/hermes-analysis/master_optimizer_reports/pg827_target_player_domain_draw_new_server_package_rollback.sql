BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('allied strategies')
   OR normalized_name LIKE 'allied strategies // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg827_pg827_target_player_domain_draw_ne_20260712_105810;

COMMIT;
