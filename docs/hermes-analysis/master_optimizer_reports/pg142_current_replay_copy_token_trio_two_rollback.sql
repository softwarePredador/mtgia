BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('jaxis, the troublemaker', 'rionya, fire dancer', 'the jolly balloon man')
   OR normalized_name LIKE 'jaxis, the troublemaker // %'
   OR normalized_name LIKE 'rionya, fire dancer // %'
   OR normalized_name LIKE 'the jolly balloon man // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg142_current_replay_copy_token_trio_two_20260624_042157;

COMMIT;
