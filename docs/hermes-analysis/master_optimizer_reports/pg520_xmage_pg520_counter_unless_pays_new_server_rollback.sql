BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('convolute', 'force spike', 'it''ll quench ya!', 'mana tithe', 'mindstatic', 'quench', 'revolutionary rebuff')
   OR normalized_name LIKE 'convolute // %'
   OR normalized_name LIKE 'force spike // %'
   OR normalized_name LIKE 'it''ll quench ya! // %'
   OR normalized_name LIKE 'mana tithe // %'
   OR normalized_name LIKE 'mindstatic // %'
   OR normalized_name LIKE 'quench // %'
   OR normalized_name LIKE 'revolutionary rebuff // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg520_counter_unless_pays_new_serv_20260705_174428;

COMMIT;
