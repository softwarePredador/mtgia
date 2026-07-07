BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dogged hunter', 'haazda exonerator', 'king suleiman', 'nezumi shadow-watcher', 'northern paladin', 'quagmire druid', 'seal of doom', 'southern paladin')
   OR normalized_name LIKE 'dogged hunter // %'
   OR normalized_name LIKE 'haazda exonerator // %'
   OR normalized_name LIKE 'king suleiman // %'
   OR normalized_name LIKE 'nezumi shadow-watcher // %'
   OR normalized_name LIKE 'northern paladin // %'
   OR normalized_name LIKE 'quagmire druid // %'
   OR normalized_name LIKE 'seal of doom // %'
   OR normalized_name LIKE 'southern paladin // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg614_activated_destroy_restricted_targe_20260707_122626;

COMMIT;
