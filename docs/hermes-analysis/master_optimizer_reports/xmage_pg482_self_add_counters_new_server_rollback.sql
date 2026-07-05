BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('carnivorous moss-beast', 'chronomaton', 'energizer', 'hungry megasloth', 'jenara, asura of war', 'jungle delver', 'ruins recluse', 'sledding otter-penguin', 'unholy officiant', 'verdant automaton')
   OR normalized_name LIKE 'carnivorous moss-beast // %'
   OR normalized_name LIKE 'chronomaton // %'
   OR normalized_name LIKE 'energizer // %'
   OR normalized_name LIKE 'hungry megasloth // %'
   OR normalized_name LIKE 'jenara, asura of war // %'
   OR normalized_name LIKE 'jungle delver // %'
   OR normalized_name LIKE 'ruins recluse // %'
   OR normalized_name LIKE 'sledding otter-penguin // %'
   OR normalized_name LIKE 'unholy officiant // %'
   OR normalized_name LIKE 'verdant automaton // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg482_self_add_counters_new_server_20260705_044704;

COMMIT;
