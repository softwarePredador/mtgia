BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aggressive mammoth', 'bloodcrusher of khorne', 'groundshaker sliver', 'khenra charioteer', 'nylea''s forerunner', 'primal rage', 'roughshod mentor', 'thicket crasher')
   OR normalized_name LIKE 'aggressive mammoth // %'
   OR normalized_name LIKE 'bloodcrusher of khorne // %'
   OR normalized_name LIKE 'groundshaker sliver // %'
   OR normalized_name LIKE 'khenra charioteer // %'
   OR normalized_name LIKE 'nylea''s forerunner // %'
   OR normalized_name LIKE 'primal rage // %'
   OR normalized_name LIKE 'roughshod mentor // %'
   OR normalized_name LIKE 'thicket crasher // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg586_static_controlled_trample_new_serv_20260707_021928;

COMMIT;
