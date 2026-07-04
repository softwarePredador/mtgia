BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('borderland ranger', 'call the gatewatch', 'cateran summons', 'civic wayfinder', 'daru cavalier', 'deadeye quartermaster', 'diabolic tutor', 'district guide', 'eerie procession', 'environmental scientist', 'farfinder', 'gatecreeper vine', 'goblin matron', 'heliod''s pilgrim', 'howling wolf', 'ignite the beacon', 'merchant scroll', 'nesting wurm', 'open the armory', 'plea for guidance', 'ranger of eos', 'rune-scarred demon', 'safewright quest', 'sarkhan''s triumph', 'screaming seahawk', 'seek the horizon', 'skyshroud sentinel', 'solve the equation', 'squadron hawk', 'sylvan ranger', 'time of need', 'totem-guide hartebeest', 'transit mage', 'trapmaker''s snare', 'tribute mage')
   OR normalized_name LIKE 'borderland ranger // %'
   OR normalized_name LIKE 'call the gatewatch // %'
   OR normalized_name LIKE 'cateran summons // %'
   OR normalized_name LIKE 'civic wayfinder // %'
   OR normalized_name LIKE 'daru cavalier // %'
   OR normalized_name LIKE 'deadeye quartermaster // %'
   OR normalized_name LIKE 'diabolic tutor // %'
   OR normalized_name LIKE 'district guide // %'
   OR normalized_name LIKE 'eerie procession // %'
   OR normalized_name LIKE 'environmental scientist // %'
   OR normalized_name LIKE 'farfinder // %'
   OR normalized_name LIKE 'gatecreeper vine // %'
   OR normalized_name LIKE 'goblin matron // %'
   OR normalized_name LIKE 'heliod''s pilgrim // %'
   OR normalized_name LIKE 'howling wolf // %'
   OR normalized_name LIKE 'ignite the beacon // %'
   OR normalized_name LIKE 'merchant scroll // %'
   OR normalized_name LIKE 'nesting wurm // %'
   OR normalized_name LIKE 'open the armory // %'
   OR normalized_name LIKE 'plea for guidance // %'
   OR normalized_name LIKE 'ranger of eos // %'
   OR normalized_name LIKE 'rune-scarred demon // %'
   OR normalized_name LIKE 'safewright quest // %'
   OR normalized_name LIKE 'sarkhan''s triumph // %'
   OR normalized_name LIKE 'screaming seahawk // %'
   OR normalized_name LIKE 'seek the horizon // %'
   OR normalized_name LIKE 'skyshroud sentinel // %'
   OR normalized_name LIKE 'solve the equation // %'
   OR normalized_name LIKE 'squadron hawk // %'
   OR normalized_name LIKE 'sylvan ranger // %'
   OR normalized_name LIKE 'time of need // %'
   OR normalized_name LIKE 'totem-guide hartebeest // %'
   OR normalized_name LIKE 'transit mage // %'
   OR normalized_name LIKE 'trapmaker''s snare // %'
   OR normalized_name LIKE 'tribute mage // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg406_tutor_to_hand_new_server_20260704_130304;

COMMIT;
