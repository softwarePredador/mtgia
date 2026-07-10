BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bitter triumph', 'bone shards', 'final payment', 'fumarole')
   OR normalized_name LIKE 'bitter triumph // %'
   OR normalized_name LIKE 'bone shards // %'
   OR normalized_name LIKE 'final payment // %'
   OR normalized_name LIKE 'fumarole // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg705_destroy_or_pay_life_additional_cos_20260710_145650;

COMMIT;
