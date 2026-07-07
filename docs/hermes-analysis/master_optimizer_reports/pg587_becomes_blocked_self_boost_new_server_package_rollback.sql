BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('deeproot warrior', 'deepwood wolverine', 'elvish berserker', 'gang of elk', 'johtull wurm', 'jungle wurm', 'norwood warrior', 'rabid elephant', 'razorclaw bear', 'slashing tiger', 'snorting gahr', 'sparring golem', 'trained cheetah')
   OR normalized_name LIKE 'deeproot warrior // %'
   OR normalized_name LIKE 'deepwood wolverine // %'
   OR normalized_name LIKE 'elvish berserker // %'
   OR normalized_name LIKE 'gang of elk // %'
   OR normalized_name LIKE 'johtull wurm // %'
   OR normalized_name LIKE 'jungle wurm // %'
   OR normalized_name LIKE 'norwood warrior // %'
   OR normalized_name LIKE 'rabid elephant // %'
   OR normalized_name LIKE 'razorclaw bear // %'
   OR normalized_name LIKE 'slashing tiger // %'
   OR normalized_name LIKE 'snorting gahr // %'
   OR normalized_name LIKE 'sparring golem // %'
   OR normalized_name LIKE 'trained cheetah // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg587_becomes_blocked_self_boost_new_ser_20260707_024042;

COMMIT;
