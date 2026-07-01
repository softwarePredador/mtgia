BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aquus steed', 'captive flame', 'devotee of strength', 'flowstone overseer', 'ghitu war cry', 'ghost warden', 'ghosts of the damned', 'grandmother sengir', 'hagra sharpshooter', 'icatian priest', 'nantuko disciple', 'sacred armory', 'saltfield recluse', 'smokespew invoker', 'staff of zegon', 'thriss, nantuko primus', 'tower of champions', 'ursapine', 'wyluli wolf')
   OR normalized_name LIKE 'aquus steed // %'
   OR normalized_name LIKE 'captive flame // %'
   OR normalized_name LIKE 'devotee of strength // %'
   OR normalized_name LIKE 'flowstone overseer // %'
   OR normalized_name LIKE 'ghitu war cry // %'
   OR normalized_name LIKE 'ghost warden // %'
   OR normalized_name LIKE 'ghosts of the damned // %'
   OR normalized_name LIKE 'grandmother sengir // %'
   OR normalized_name LIKE 'hagra sharpshooter // %'
   OR normalized_name LIKE 'icatian priest // %'
   OR normalized_name LIKE 'nantuko disciple // %'
   OR normalized_name LIKE 'sacred armory // %'
   OR normalized_name LIKE 'saltfield recluse // %'
   OR normalized_name LIKE 'smokespew invoker // %'
   OR normalized_name LIKE 'staff of zegon // %'
   OR normalized_name LIKE 'thriss, nantuko primus // %'
   OR normalized_name LIKE 'tower of champions // %'
   OR normalized_name LIKE 'ursapine // %'
   OR normalized_name LIKE 'wyluli wolf // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg315_xmage_permanent_activated_target_boost_wave_202607;

COMMIT;
