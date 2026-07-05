BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('deadeye duelist', 'elite headhunter', 'femeref archers', 'pyroclastic elemental', 'razortip whip', 'shauku''s minion', 'slingshot goblin', 'sorcerer of the fang', 'spinal villain', 'western paladin', 'zealot of the god-pharaoh')
   OR normalized_name LIKE 'deadeye duelist // %'
   OR normalized_name LIKE 'elite headhunter // %'
   OR normalized_name LIKE 'femeref archers // %'
   OR normalized_name LIKE 'pyroclastic elemental // %'
   OR normalized_name LIKE 'razortip whip // %'
   OR normalized_name LIKE 'shauku''s minion // %'
   OR normalized_name LIKE 'slingshot goblin // %'
   OR normalized_name LIKE 'sorcerer of the fang // %'
   OR normalized_name LIKE 'spinal villain // %'
   OR normalized_name LIKE 'western paladin // %'
   OR normalized_name LIKE 'zealot of the god-pharaoh // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg504_xmage_activated_damage_target_pars_20260705_120411;

COMMIT;
