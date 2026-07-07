BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('armor of shadows', 'blitzball shot', 'massive might', 'masterful flourish')
   OR normalized_name LIKE 'armor of shadows // %'
   OR normalized_name LIKE 'blitzball shot // %'
   OR normalized_name LIKE 'massive might // %'
   OR normalized_name LIKE 'masterful flourish // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg605_boost_keyword_target_creature_20260707_085825;

COMMIT;
