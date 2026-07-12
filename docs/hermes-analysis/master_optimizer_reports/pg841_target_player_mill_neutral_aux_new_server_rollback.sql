BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('compelling argument', 'dream twist')
   OR normalized_name LIKE 'compelling argument // %'
   OR normalized_name LIKE 'dream twist // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg841_target_player_mill_neutral_aux_new_20260712_194543;

COMMIT;
