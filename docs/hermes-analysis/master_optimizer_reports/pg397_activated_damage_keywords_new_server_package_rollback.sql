BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aven archer', 'crimson manticore', 'cunning sparkmage', 'dive bomber', 'divebomber griffin', 'fanatical firebrand', 'jeska, warrior adept', 'kamahl, pit fighter', 'mawcor', 'sarpadian simulacrum', 'scaldkin', 'shivan hellkite', 'skyway sniper', 'stinging barrier', 'storm spirit', 'thornwind faeries', 'vulshok sorcerer')
   OR normalized_name LIKE 'aven archer // %'
   OR normalized_name LIKE 'crimson manticore // %'
   OR normalized_name LIKE 'cunning sparkmage // %'
   OR normalized_name LIKE 'dive bomber // %'
   OR normalized_name LIKE 'divebomber griffin // %'
   OR normalized_name LIKE 'fanatical firebrand // %'
   OR normalized_name LIKE 'jeska, warrior adept // %'
   OR normalized_name LIKE 'kamahl, pit fighter // %'
   OR normalized_name LIKE 'mawcor // %'
   OR normalized_name LIKE 'sarpadian simulacrum // %'
   OR normalized_name LIKE 'scaldkin // %'
   OR normalized_name LIKE 'shivan hellkite // %'
   OR normalized_name LIKE 'skyway sniper // %'
   OR normalized_name LIKE 'stinging barrier // %'
   OR normalized_name LIKE 'storm spirit // %'
   OR normalized_name LIKE 'thornwind faeries // %'
   OR normalized_name LIKE 'vulshok sorcerer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg397_activated_damage_keywords_new_server_20260704_0931;

COMMIT;
