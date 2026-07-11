BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('enemy of the guildpact', 'guardian of the guildpact', 'mistmeadow skulk', 'warren-scourge elf')
   OR normalized_name LIKE 'enemy of the guildpact // %'
   OR normalized_name LIKE 'guardian of the guildpact // %'
   OR normalized_name LIKE 'mistmeadow skulk // %'
   OR normalized_name LIKE 'warren-scourge elf // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg742_static_filtered_protection_20260711_052106;

COMMIT;
