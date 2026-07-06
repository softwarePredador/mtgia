BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('elven ambush', 'elvish promenade')
   OR normalized_name LIKE 'elven ambush // %'
   OR normalized_name LIKE 'elvish promenade // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg546_controlled_subtype_tokens_new_serv_20260706_031919;

COMMIT;
