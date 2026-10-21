-- Semeia um deck Commander que o otimizador ACEITA otimizar.
--
-- Por que existe: a fixture visual compartilhada semeia, de propósito, 99
-- terrenos básicos e 1 comandante. Esse deck é mínimo e determinístico, e serve
-- aos outros pacotes — mas dispara "Reconstrução guiada recomendada" em vez da
-- prévia de otimização, porque:
--
--   * o alvo de terrenos para commander é 36, e excesso severo começa em 55
--     (`server/lib/commander_mana_floor.dart:88-99`);
--   * com 1 não-terreno não há massa crítica;
--   * a identidade azul do Talrand não tem fonte funcional;
--   * o comandante pede instants/sorceries e o deck tem zero.
--
-- Sem prévia não existe `optimize-suggestion-add-0-preview-button`, e sem esse
-- botão o leitor de carta nunca abre — que é justamente o que o pacote
-- `optimization-card-reader-web` precisa capturar.
--
-- O catálogo descartável tem 13 cartas, 9 não-terrenos (medido em 2026-09-24),
-- então não há como montar o deck com o que existe. Este script semeia cartas
-- sintéticas próprias.
--
-- DETERMINISMO. Tudo tem id fixo, derivado de um prefixo por posição. A mesma
-- corrida produz sempre o mesmo deck e, portanto, as mesmas sugestões. Nada
-- depende de ordem de consulta, de catálogo externo, de rede ou de IA — a rota
-- `decks/[id]/optimizations` é determinística e não referencia provedor de IA.
--
-- ARTE. Toda carta recebe `image_url` apontando para o servidor de assets da
-- fixture, que serve com CORS. Sem isso a arte cai no fallback do verso, e a
-- captura deixaria de provar o caminho de platform view que o pacote existe
-- para provar.

\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------------
-- Terrenos: 36 no total, com fontes azuis para a identidade do comandante.
-- ---------------------------------------------------------------------------
INSERT INTO cards (
  id, scryfall_id, name, mana_cost, type_line, oracle_text,
  colors, color_identity, image_url, set_code, rarity, is_reserved
)
SELECT
  ('20000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  ('30000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  CASE WHEN i <= 18 THEN 'Ilha de Prova ' || i ELSE 'Ermo de Prova ' || i END,
  NULL,
  'Basic Land — ' || CASE WHEN i <= 18 THEN 'Island' ELSE 'Wastes' END,
  CASE WHEN i <= 18 THEN '{T}: Adicione {U}.' ELSE '{T}: Adicione {C}.' END,
  ARRAY[]::text[],
  CASE WHEN i <= 18 THEN ARRAY['U']::text[] ELSE ARRAY[]::text[] END,
  :'image_url',
  'TST',
  'common',
  FALSE
FROM generate_series(1, 36) AS i
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  type_line = EXCLUDED.type_line,
  oracle_text = EXCLUDED.oracle_text,
  color_identity = EXCLUDED.color_identity,
  image_url = EXCLUDED.image_url;

-- ---------------------------------------------------------------------------
-- Não-terrenos: 63, divididos nos PAPÉIS FUNCIONAIS CRÍTICOS que o piso de
-- commander exige, com oracle em INGLÊS.
--
-- Por que em inglês: os classificadores do otimizador casam texto em inglês.
-- `countsTowardCommanderCriticalRoleFloor`
-- (server/lib/ai/optimize_functional_role_support.dart:199) resolve ramp por
-- `optimizationRampProfileForCard`, wipe por `looksLikeOptimizationBoardWipeText`
-- (optimization_functional_roles.dart:353) e draw/interaction por
-- `resolveCardFunctionalRoles` — todos sobre gatilhos em inglês. Com o oracle
-- em português que este seed usava antes, o deck parecia carente de TODOS os
-- quatro papéis, o `repairMode` de `buildDeterministicOptimizeSwapCandidates`
-- passava a exigir mais remoções do que havia e a função devolvia lista vazia
-- (optimize_swap_candidate_support.dart:1150). Aí `deterministicFirstEnabled`
-- desligava e a rota tentava a IA — medido em 2026-09-28, com a tentativa
-- morrendo no EGRESS_GUARD (`Optimization failed type=_ClientSocketException`).
--
-- Pisos exigidos (optimize_functional_role_support.dart:76-95, midrange):
--   ramp >= 8, draw >= 8, interaction >= 6, wipe >= 2
-- Este seed entrega 10 ramp, 8 interaction, 3 wipe e 31 draw.
--
-- O EXCEDENTE FICA EM 'draw', DE PROPÓSITO. `buildSameLaneOptimizeSwapPairs`
-- (optimize_swap_candidate_support.dart:940) só pareia quando o
-- `functional_need` da adição é igual ao `role` da remoção. Os dois lados usam
-- classificadores diferentes: o `role` vem de `inferFunctionalRole`, que
-- devolve 'engine' para QUALQUER criatura simples
-- (optimize_functional_role_support.dart, `if (t.contains('creature')) return
-- 'engine'`), enquanto a necessidade vem de `inferOptimizeFunctionalNeed`, que
-- para criatura devolve 'creature'. 'engine' e 'creature' nunca casam, então
-- remoção de criatura não gera par nenhum -- medido em 2026-09-28: 6 remoções
-- de papel 'engine' e ZERO pares. Com o excedente em 'draw' os dois
-- classificadores dizem 'draw' e o par se forma.
--
-- As 12 criaturas no fim existem só para o deck parecer um deck; elas não são
-- material de troca por esse mesmo motivo.
-- ---------------------------------------------------------------------------
INSERT INTO cards (
  id, scryfall_id, name, mana_cost, cmc, type_line, oracle_text,
  colors, color_identity, power, toughness, image_url, set_code, rarity,
  price_usd, is_reserved
)
SELECT
  ('21000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  ('31000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  CASE
    WHEN i <= 10 THEN 'Recife de Prova ' || i
    WHEN i <= 18 THEN 'Contramagica de Prova ' || i
    WHEN i <= 21 THEN 'Mare de Prova ' || i
    WHEN i <= 51 THEN 'Presagio de Prova ' || i
    ELSE 'Invocacao de Prova ' || i
  END,
  CASE
    WHEN i <= 10 THEN '{2}'
    WHEN i <= 18 THEN '{1}{U}'
    WHEN i <= 21 THEN '{4}{U}'
    WHEN i <= 51 THEN '{' || ((i % 3) + 2)::text || '}{U}'
    ELSE '{' || ((i % 4) + 1)::text || '}{U}'
  END,
  CASE
    WHEN i <= 10 THEN 2
    WHEN i <= 18 THEN 2
    WHEN i <= 21 THEN 5
    WHEN i <= 51 THEN ((i % 3) + 3)
    ELSE ((i % 4) + 2)
  END,
  CASE
    WHEN i <= 10 THEN 'Artifact'
    WHEN i <= 18 THEN 'Instant'
    WHEN i <= 21 THEN 'Sorcery'
    WHEN i <= 51 THEN 'Sorcery'
    ELSE 'Creature — Merfolk Wizard'
  END,
  CASE
    WHEN i <= 10 THEN '{T}: Add {U}.'                 -- ramp: mana rock
    WHEN i <= 18 THEN 'Counter target spell.'         -- interaction
    WHEN i <= 21 THEN 'Destroy all creatures.'        -- wipe
    WHEN i <= 51 THEN 'Draw a card.'                  -- draw, com excedente
    ELSE 'Flying.'                                    -- criatura de sabor
  END,
  CASE WHEN i <= 10 THEN ARRAY[]::text[] ELSE ARRAY['U']::text[] END,
  CASE WHEN i <= 10 THEN ARRAY[]::text[] ELSE ARRAY['U']::text[] END,
  CASE WHEN i > 51 THEN '2' ELSE NULL END,
  CASE WHEN i > 51 THEN '2' ELSE NULL END,
  :'image_url',
  'TST',
  CASE WHEN i % 7 = 0 THEN 'rare' ELSE 'common' END,
  0.75,
  FALSE
FROM generate_series(1, 63) AS i
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  mana_cost = EXCLUDED.mana_cost,
  cmc = EXCLUDED.cmc,
  type_line = EXCLUDED.type_line,
  oracle_text = EXCLUDED.oracle_text,
  colors = EXCLUDED.colors,
  color_identity = EXCLUDED.color_identity,
  power = EXCLUDED.power,
  toughness = EXCLUDED.toughness,
  image_url = EXCLUDED.image_url,
  price_usd = EXCLUDED.price_usd;

-- ---------------------------------------------------------------------------
-- O deck: 36 terrenos + 63 não-terrenos + 1 comandante = 100.
-- ---------------------------------------------------------------------------
DELETE FROM deck_cards WHERE deck_id = :'deck_id'::uuid;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
SELECT :'deck_id'::uuid,
       ('20000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
       1, FALSE
FROM generate_series(1, 36) AS i;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
SELECT :'deck_id'::uuid,
       ('21000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
       1, FALSE
FROM generate_series(1, 63) AS i;

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
VALUES (:'deck_id'::uuid, :'commander_card_id'::uuid, 1, TRUE);

-- Conferência. Variável de psql não é visível dentro de bloco DO, então a
-- contagem sai daqui e quem confere é o roteiro que chamou -- que para a
-- corrida se não bater, em vez de capturar um deck que não é o combinado.
SELECT
  coalesce(sum(dc.quantity), 0) AS total,
  coalesce(sum(dc.quantity) FILTER (WHERE c.type_line ILIKE '%land%'), 0)
    AS terrenos,
  coalesce(sum(dc.quantity) FILTER (WHERE dc.is_commander), 0) AS comandantes
FROM deck_cards dc
JOIN cards c ON c.id = dc.card_id
WHERE dc.deck_id = :'deck_id'::uuid;

-- ---------------------------------------------------------------------------
-- Pool de candidatos de ADIÇÃO, deliberadamente FORA do deck.
--
-- Por que existe: sem candidato de adição a shortlist determinística sai
-- vazia, e aí `server/routes/ai/optimize/index.dart:1458` desliga o
-- `deterministicFirstEnabled` e o código cai em `runAiOptimizeAttempt`, que
-- TENTA sair para https://api.openai.com. Medido em 2026-09-28, o catálogo
-- descartável oferecia 1 único candidato ("Sol Ring", e as duas linhas do
-- catálogo colapsam em uma pelo `DISTINCT ON (LOWER(c.name))` da consulta),
-- com score zero e sujeito a `filterCandidatesByBracketPolicy`. Um candidato
-- só não sustenta a corrida offline.
--
-- Os filtros que a consulta de candidatos aplica
-- (`server/lib/ai/optimize_swap_candidate_support.dart:139-250`) são: fora do
-- deck, não-terreno, `oracle_text` não-vazio, nome sem os prefixos vetados, e
-- identidade contida na do comandante. NÃO existe porta de score mínimo na
-- montagem do pool (linhas 267-347): carta com `best_role_score` zero
-- sobrevive. Por isso não é preciso semear `card_intelligence_snapshot` nem
-- `commander_card_synergy`.
--
-- A seleção exige `matchesFunctionalNeedForCandidate` verdadeiro (linha 441).
-- Para a necessidade 'utility' isso é sempre verdadeiro (linha 608), e as
-- necessidades saem dos cards removidos — cujo oracle em português não casa
-- com os gatilhos em inglês de `inferOptimizeFunctionalNeed`, caindo em
-- 'utility' e 'creature'. Mesmo assim o pool cobre criatura, ramp e remoção
-- com gatilhos em inglês, para a corrida não depender dessa inferência.
--
-- `usedNames` consome um candidato por troca, então o pool tem 12 nomes
-- distintos: material para mais trocas do que qualquer intensidade pede.
--
-- DETERMINISMO. Ids fixos por posição, como o resto do seed. ARTE pelo mesmo
-- servidor de assets com CORS, senão o leitor mostra o verso de fallback e a
-- captura deixa de provar o caminho de platform view.
-- ---------------------------------------------------------------------------
INSERT INTO cards (
  id, scryfall_id, name, mana_cost, cmc, type_line, oracle_text,
  colors, color_identity, power, toughness, image_url, set_code, rarity,
  price_usd, is_reserved
)
SELECT
  ('22000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  ('32000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  CASE
    WHEN i <= 4 THEN 'Vidente de Prova ' || i
    WHEN i <= 8 THEN 'Talisma de Prova ' || i
    ELSE 'Anulacao de Prova ' || i
  END,
  CASE
    WHEN i <= 4 THEN '{2}{U}'
    WHEN i <= 8 THEN '{2}'
    ELSE '{1}{U}'
  END,
  CASE WHEN i <= 4 THEN 3 WHEN i <= 8 THEN 2 ELSE 2 END,
  CASE
    WHEN i <= 4 THEN 'Creature — Merfolk Wizard'
    WHEN i <= 8 THEN 'Artifact'
    ELSE 'Instant'
  END,
  -- Gatilhos em inglês de propósito: sao eles que `matchesFunctionalNeed`
  -- consulta para casar 'creature', 'ramp', 'removal' e 'draw'.
  CASE
    WHEN i <= 4 THEN 'Flying. When this creature enters the battlefield, draw a card.'
    WHEN i <= 8 THEN '{T}: Add {U}.'
    ELSE 'Counter target spell. Draw a card.'
  END,
  CASE WHEN i <= 8 AND i > 4 THEN ARRAY[]::text[] ELSE ARRAY['U']::text[] END,
  CASE WHEN i <= 8 AND i > 4 THEN ARRAY[]::text[] ELSE ARRAY['U']::text[] END,
  CASE WHEN i <= 4 THEN '2' ELSE NULL END,
  CASE WHEN i <= 4 THEN '2' ELSE NULL END,
  :'image_url',
  'TST',
  'common',
  1.50,
  FALSE
FROM generate_series(1, 12) AS i
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  mana_cost = EXCLUDED.mana_cost,
  cmc = EXCLUDED.cmc,
  type_line = EXCLUDED.type_line,
  oracle_text = EXCLUDED.oracle_text,
  colors = EXCLUDED.colors,
  color_identity = EXCLUDED.color_identity,
  image_url = EXCLUDED.image_url,
  price_usd = EXCLUDED.price_usd;

-- Garantia explícita: nenhum candidato do pool entra no deck. Se um dia
-- alguém semear o deck a partir deste pool por engano, o candidato deixa de
-- ser candidato e a shortlist volta a esvaziar silenciosamente.
DELETE FROM deck_cards
WHERE deck_id = :'deck_id'::uuid
  AND card_id IN (
    SELECT ('22000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid
    FROM generate_series(1, 12) AS i
  );

-- Conferência do pool, com os MESMOS filtros da consulta de candidatos, para o
-- roteiro parar a corrida antes de capturar em vez de descobrir a shortlist
-- vazia só quando a rota tentar sair para a internet. `DISTINCT ON` replicado
-- porque é ele que colapsou os dois "Sol Ring" do catálogo em um só.
WITH deck AS (
  SELECT LOWER(c.name) AS n
  FROM deck_cards dc JOIN cards c ON c.id = dc.card_id
  WHERE dc.deck_id = :'deck_id'::uuid
), ident AS (
  SELECT c.color_identity AS ci
  FROM deck_cards dc JOIN cards c ON c.id = dc.card_id
  WHERE dc.deck_id = :'deck_id'::uuid AND dc.is_commander
  LIMIT 1
), elegiveis AS (
  SELECT DISTINCT ON (LOWER(c.name)) c.name
  FROM cards c
  LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
  WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
    AND LOWER(c.name) NOT IN (SELECT n FROM deck)
    AND NOT (COALESCE(c.type_line, '') ~* '(^|[^a-z])land([^a-z]|$)')
    AND c.name NOT LIKE 'A-%'
    AND c.oracle_text IS NOT NULL
    AND LENGTH(TRIM(c.oracle_text)) > 0
    AND (c.color_identity <@ (SELECT ci FROM ident)
         OR c.color_identity = '{}' OR c.color_identity IS NULL)
  ORDER BY LOWER(c.name)
)
SELECT count(*) AS candidatos_adicao FROM elegiveis;
