BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('acid web spider', 'acidic slime', 'aven cloudchaser', 'cloudchaser eagle', 'manticore', 'rooftop assassin', 'stingblade assassin')
   OR normalized_name LIKE 'acid web spider // %'
   OR normalized_name LIKE 'acidic slime // %'
   OR normalized_name LIKE 'aven cloudchaser // %'
   OR normalized_name LIKE 'cloudchaser eagle // %'
   OR normalized_name LIKE 'manticore // %'
   OR normalized_name LIKE 'rooftop assassin // %'
   OR normalized_name LIKE 'stingblade assassin // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg500_etb_destroy_static_keywords_20260705_103310;

COMMIT;
