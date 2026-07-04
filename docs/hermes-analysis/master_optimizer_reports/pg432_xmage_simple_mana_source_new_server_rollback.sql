BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('agent of stromgald', 'bog initiate', 'charcoal diamond', 'darksteel ingot', 'deathbloom gardener', 'druid of the anima', 'fire diamond', 'fire sprites', 'hedron crawler', 'helionaut', 'leyline prowler', 'llanowar envoy', 'lotus guardian', 'maraleaf pixie', 'marble diamond', 'moss diamond', 'nomadic elf', 'noxious newt', 'obelisk of bant', 'obelisk of esper', 'obelisk of grixis', 'obelisk of jund', 'obelisk of naya', 'orochi leafcaller', 'prismite', 'signpost scarecrow', 'sky diamond', 'steward of valeron', 'sylvan caryatid', 'timeless lotus', 'urborg elf', 'vine trellis', 'viridian acolyte', 'warden of geometries')
   OR normalized_name LIKE 'agent of stromgald // %'
   OR normalized_name LIKE 'bog initiate // %'
   OR normalized_name LIKE 'charcoal diamond // %'
   OR normalized_name LIKE 'darksteel ingot // %'
   OR normalized_name LIKE 'deathbloom gardener // %'
   OR normalized_name LIKE 'druid of the anima // %'
   OR normalized_name LIKE 'fire diamond // %'
   OR normalized_name LIKE 'fire sprites // %'
   OR normalized_name LIKE 'hedron crawler // %'
   OR normalized_name LIKE 'helionaut // %'
   OR normalized_name LIKE 'leyline prowler // %'
   OR normalized_name LIKE 'llanowar envoy // %'
   OR normalized_name LIKE 'lotus guardian // %'
   OR normalized_name LIKE 'maraleaf pixie // %'
   OR normalized_name LIKE 'marble diamond // %'
   OR normalized_name LIKE 'moss diamond // %'
   OR normalized_name LIKE 'nomadic elf // %'
   OR normalized_name LIKE 'noxious newt // %'
   OR normalized_name LIKE 'obelisk of bant // %'
   OR normalized_name LIKE 'obelisk of esper // %'
   OR normalized_name LIKE 'obelisk of grixis // %'
   OR normalized_name LIKE 'obelisk of jund // %'
   OR normalized_name LIKE 'obelisk of naya // %'
   OR normalized_name LIKE 'orochi leafcaller // %'
   OR normalized_name LIKE 'prismite // %'
   OR normalized_name LIKE 'signpost scarecrow // %'
   OR normalized_name LIKE 'sky diamond // %'
   OR normalized_name LIKE 'steward of valeron // %'
   OR normalized_name LIKE 'sylvan caryatid // %'
   OR normalized_name LIKE 'timeless lotus // %'
   OR normalized_name LIKE 'urborg elf // %'
   OR normalized_name LIKE 'vine trellis // %'
   OR normalized_name LIKE 'viridian acolyte // %'
   OR normalized_name LIKE 'warden of geometries // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg432_xmage_simple_mana_source_new_server_20260704_21084;

COMMIT;
