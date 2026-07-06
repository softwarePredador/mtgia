BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('alesha''s legacy', 'assault strobe', 'battle-rage blessing', 'double cleave', 'horrid vigor', 'jump', 'offer immortality', 'serpent''s gift', 'ticked off', 'unnatural speed')
   OR normalized_name LIKE 'alesha''s legacy // %'
   OR normalized_name LIKE 'assault strobe // %'
   OR normalized_name LIKE 'battle-rage blessing // %'
   OR normalized_name LIKE 'double cleave // %'
   OR normalized_name LIKE 'horrid vigor // %'
   OR normalized_name LIKE 'jump // %'
   OR normalized_name LIKE 'offer immortality // %'
   OR normalized_name LIKE 'serpent''s gift // %'
   OR normalized_name LIKE 'ticked off // %'
   OR normalized_name LIKE 'unnatural speed // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg560_target_keyword_spell_new_server_pg_20260706_102811;

COMMIT;
