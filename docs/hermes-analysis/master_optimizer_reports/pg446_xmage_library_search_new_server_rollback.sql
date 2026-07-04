BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('call the gatewatch', 'cateran summons', 'diabolic tutor', 'eerie procession', 'ignite the beacon', 'merchant scroll', 'open the armory', 'plea for guidance', 'safewright quest', 'sarkhan''s triumph', 'seek the horizon', 'solve the equation', 'time of need', 'trapmaker''s snare')
   OR normalized_name LIKE 'call the gatewatch // %'
   OR normalized_name LIKE 'cateran summons // %'
   OR normalized_name LIKE 'diabolic tutor // %'
   OR normalized_name LIKE 'eerie procession // %'
   OR normalized_name LIKE 'ignite the beacon // %'
   OR normalized_name LIKE 'merchant scroll // %'
   OR normalized_name LIKE 'open the armory // %'
   OR normalized_name LIKE 'plea for guidance // %'
   OR normalized_name LIKE 'safewright quest // %'
   OR normalized_name LIKE 'sarkhan''s triumph // %'
   OR normalized_name LIKE 'seek the horizon // %'
   OR normalized_name LIKE 'solve the equation // %'
   OR normalized_name LIKE 'time of need // %'
   OR normalized_name LIKE 'trapmaker''s snare // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg446_xmage_library_search_new_server_20260704_230107;

COMMIT;
