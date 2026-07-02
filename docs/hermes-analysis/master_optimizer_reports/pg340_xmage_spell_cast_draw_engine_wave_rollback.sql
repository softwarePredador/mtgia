BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('beast whisperer', 'enchantress''s presence', 'jhoira, weatherlight captain', 'mesa enchantress', 'primordial sage', 'reki, the history of kamigawa', 'satyr enchanter', 'secrets of the dead', 'sram, senior edificer', 'tanufel rimespeaker', 'thunderous snapper', 'vedalken archmage', 'verduran enchantress', 'whirlwind of thought')
   OR normalized_name LIKE 'beast whisperer // %'
   OR normalized_name LIKE 'enchantress''s presence // %'
   OR normalized_name LIKE 'jhoira, weatherlight captain // %'
   OR normalized_name LIKE 'mesa enchantress // %'
   OR normalized_name LIKE 'primordial sage // %'
   OR normalized_name LIKE 'reki, the history of kamigawa // %'
   OR normalized_name LIKE 'satyr enchanter // %'
   OR normalized_name LIKE 'secrets of the dead // %'
   OR normalized_name LIKE 'sram, senior edificer // %'
   OR normalized_name LIKE 'tanufel rimespeaker // %'
   OR normalized_name LIKE 'thunderous snapper // %'
   OR normalized_name LIKE 'vedalken archmage // %'
   OR normalized_name LIKE 'verduran enchantress // %'
   OR normalized_name LIKE 'whirlwind of thought // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg340_xmage_spell_cast_draw_engine_wave_20260702_000636;

COMMIT;
