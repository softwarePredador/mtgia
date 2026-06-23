BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name = 'emeria''s call // emeria, shattered skyclave';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg114_emerias_call_token_maker_20260623_200501;

COMMIT;
