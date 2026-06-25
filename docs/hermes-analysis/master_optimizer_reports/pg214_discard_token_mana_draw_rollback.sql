BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bone miser', 'waste not')
   OR normalized_name LIKE 'bone miser // %'
   OR normalized_name LIKE 'waste not // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg214_discard_token_mana_draw_20260625_095341;

COMMIT;
