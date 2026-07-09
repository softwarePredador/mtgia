BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aerial maneuver', 'daring leap', 'fervent strike', 'overprotect', 'rig for war', 'rush of vitality', 'swift justice', 'whirling strike')
   OR normalized_name LIKE 'aerial maneuver // %'
   OR normalized_name LIKE 'daring leap // %'
   OR normalized_name LIKE 'fervent strike // %'
   OR normalized_name LIKE 'overprotect // %'
   OR normalized_name LIKE 'rig for war // %'
   OR normalized_name LIKE 'rush of vitality // %'
   OR normalized_name LIKE 'swift justice // %'
   OR normalized_name LIKE 'whirling strike // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg701_boost_multi_keyword_new_server_20260709_074652;

COMMIT;
