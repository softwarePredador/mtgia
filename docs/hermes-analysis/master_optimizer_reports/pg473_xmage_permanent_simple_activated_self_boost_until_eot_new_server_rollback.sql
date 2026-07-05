BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('foxfire oak', 'frostburn weird', 'loch korrigan', 'parapet watchers')
   OR normalized_name LIKE 'foxfire oak // %'
   OR normalized_name LIKE 'frostburn weird // %'
   OR normalized_name LIKE 'loch korrigan // %'
   OR normalized_name LIKE 'parapet watchers // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg473_xmage_permanent_simple_activated_self_boost_until_;

COMMIT;
