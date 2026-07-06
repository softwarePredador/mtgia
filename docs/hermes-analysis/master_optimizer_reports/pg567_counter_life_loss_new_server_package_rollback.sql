BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('countersquall', 'psychic barrier', 'undermine')
   OR normalized_name LIKE 'countersquall // %'
   OR normalized_name LIKE 'psychic barrier // %'
   OR normalized_name LIKE 'undermine // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg567_counter_life_loss_new_server_20260706_124236;

COMMIT;
