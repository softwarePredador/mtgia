BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('symbiotic beast', 'symbiotic elf', 'symbiotic wurm', 'the hive')
   OR normalized_name LIKE 'symbiotic beast // %'
   OR normalized_name LIKE 'symbiotic elf // %'
   OR normalized_name LIKE 'symbiotic wurm // %'
   OR normalized_name LIKE 'the hive // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg522_token_parser_followup_new_se_20260705_182136;

COMMIT;
