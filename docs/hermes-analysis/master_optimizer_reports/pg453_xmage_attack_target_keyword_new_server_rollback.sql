BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aerial guide', 'chasm drake', 'garrison griffin', 'heavenly qilin', 'kinsbaile balloonist', 'majestic heliopterus', 'pegasus courser', 'roc charger', 'trained condor', 'trusted pegasus')
   OR normalized_name LIKE 'aerial guide // %'
   OR normalized_name LIKE 'chasm drake // %'
   OR normalized_name LIKE 'garrison griffin // %'
   OR normalized_name LIKE 'heavenly qilin // %'
   OR normalized_name LIKE 'kinsbaile balloonist // %'
   OR normalized_name LIKE 'majestic heliopterus // %'
   OR normalized_name LIKE 'pegasus courser // %'
   OR normalized_name LIKE 'roc charger // %'
   OR normalized_name LIKE 'trained condor // %'
   OR normalized_name LIKE 'trusted pegasus // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg453_xmage_attack_target_keyword_new_server_20260704_23;

COMMIT;
