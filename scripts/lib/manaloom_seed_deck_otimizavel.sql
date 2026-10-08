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
--
-- LEGALIDADE (D-28). Legalidade ausente passou a bloquear: a consulta de
-- candidatos do otimizador só aceita `card_legalities` em 'legal' ou
-- 'restricted' para o formato, e a validação de deck não trata mais carta sem
-- linha como legal. Por isso toda carta sintética recebe `commander`/`legal`
-- de forma explícita, e as linhas do deck e do comandante entram ANTES de
-- `deck_cards`, para o deck já nascer sobre legalidade conhecida.
--
-- CONFERÊNCIA QUE PARA. São duas conferências: a do deck, logo depois dos
-- `INSERT` em `deck_cards` (no meio do arquivo), e a do pool de candidatos,
-- no fim. As duas são blocos `DO` que levantam `RAISE EXCEPTION`: com
-- `ON_ERROR_STOP` o psql sai com código 3 e a corrida para ali, em vez de
-- depender de alguém ler a contagem impressa. Variável de psql não é
-- interpolada dentro de `$$ ... $$`, então o `deck_id` entra nos blocos por
-- `SET manaloom.seed_deck_id` e `current_setting(...)`.
--
-- TRANSAÇÃO. O seed inteiro é UMA transação: `BEGIN` logo depois do
-- `ON_ERROR_STOP` e `COMMIT` na última linha. Parar a corrida não bastava:
-- sem a transação, cada comando era confirmado sozinho, e uma conferência
-- reprovada deixava gravados as cartas sintéticas, as legalidades e o deck
-- já reescrito (o `DELETE` e os `INSERT` em `deck_cards`). Com ela, o erro
-- encerra o psql com a transação aberta e o servidor desfaz tudo, inclusive
-- o `DELETE`: o deck volta ao que era antes da corrida. Medido em 2026-10-08
-- num PostgreSQL 17 descartável -- legalidades apagadas ou só o pool sem
-- legalidade: código 3 e zero linhas do seed; as mesmas falhas sem o
-- `BEGIN`/`COMMIT` deixavam 99 ou 111 cartas e 100 linhas de `deck_cards`.
--
-- BANCO DESCARTÁVEL. O seed apaga as linhas de `deck_cards` do deck informado
-- e grava, com `ON CONFLICT ... DO UPDATE`, cartas sintéticas de id fixo no
-- catálogo. Só pode rodar contra um PostgreSQL descartável, e quem chama tem
-- de dizer isso com `-v descartavel=sim`. É a guarda principal: logo depois
-- do `BEGIN`, antes de qualquer escrita, um bloco `DO` levanta
-- `RAISE EXCEPTION` se a variável não for exatamente `sim`. Sem a variável o
-- psql nem chega ao bloco: `:'descartavel'` fica sem interpolar, o `SET`
-- falha com erro de sintaxe e o `ON_ERROR_STOP` encerra a corrida ali.
-- A segunda camada é barata e NÃO prova nada sozinha: recusa a conexão TCP
-- cujo endereço do servidor (`inet_server_addr()`) não seja loopback
-- (127.0.0.0/8 ou ::1); socket unix (endereço NULL) passa. Loopback não
-- prova que o banco é descartável -- um proxy ou túnel local pode apontar
-- para outro banco --, por isso a confirmação explícita é a guarda principal.
-- Medido em 2026-10-08 num PostgreSQL 17 descartável, com o deck já
-- populado antes da corrida: com `descartavel=sim`, código 0 e 100/36/1;
-- sem a variável ou com `descartavel=nao`, código 3, nenhuma carta sintética
-- nem legalidade gravada e o deck intacto (o `DELETE` não aconteceu). A
-- camada de endereço, numa cópia com `inet_server_addr()` trocado por valor
-- fixo: 10.0.0.5, 192.168.0.10 e 2001:db8::1 recusados com código 3 e nada
-- gravado; NULL, 127.0.0.5 e ::1 passam. Só esses dois intervalos passam:
-- `::ffff:127.0.0.1` também é recusado.
--
-- QUEM CHAMA. Nenhum script versionado chama este arquivo; ele roda à mão,
-- com `psql -f` e as variáveis abaixo, sem `-1` -- numa linha só, aqui
-- quebrada para caber:
--
--   psql -X -h 127.0.0.1 -p <porta> -U <usuario> -d <banco_descartavel>
--     -v descartavel=sim -v deck_id=<uuid> -v commander_card_id=<uuid>
--     -v image_url=<url> -f scripts/lib/manaloom_seed_deck_otimizavel.sql
--
-- O `BEGIN`/`COMMIT` ficam no arquivo para a atomicidade não depender de
-- quem chama lembrar de `-1`/`--single-transaction`. Chamar com `-1` é
-- redundante e não muda o resultado (medido: o psql avisa "there is already
-- a transaction in progress" e "there is no transaction in progress", sai
-- com 0 no caminho feliz e com 3, sem resto, numa conferência reprovada).
-- Nada aqui exige rodar fora de transação. A forma é conferida por
-- `server/test/seed_deck_otimizavel_test.py`: o único metacomando do psql é
-- `\set ON_ERROR_STOP on`, uma vez, antes do `BEGIN`; `BEGIN` primeiro, a
-- guarda de banco descartável logo depois, `COMMIT` por último e nenhum
-- outro controle de transação no meio.
--
-- Variáveis exigidas: `descartavel` (só `sim` passa), `deck_id`,
-- `commander_card_id` e `image_url`.

\set ON_ERROR_STOP on

BEGIN;

-- Guarda de banco descartável (ver BANCO DESCARTÁVEL no topo). Fica antes de
-- qualquer escrita: recusada aqui, a corrida para sem ter tocado em nada.
SET manaloom.seed_descartavel = :'descartavel';

DO $guarda_descartavel$
DECLARE
  v_confirmacao text := current_setting('manaloom.seed_descartavel');
  v_servidor inet := inet_server_addr();
BEGIN
  IF v_confirmacao IS DISTINCT FROM 'sim' THEN
    RAISE EXCEPTION
      'seed do deck otimizavel: sem confirmacao de banco descartavel '
      '(descartavel=%); rode com -v descartavel=sim, e so contra um '
      'PostgreSQL descartavel; nada foi gravado', v_confirmacao;
  END IF;
  IF v_servidor IS NOT NULL
     AND NOT (v_servidor <<= '127.0.0.0/8'::inet
              OR v_servidor <<= '::1/128'::inet) THEN
    RAISE EXCEPTION
      'seed do deck otimizavel: o servidor responde em % (nem loopback nem '
      'socket unix); nada foi gravado', host(v_servidor);
  END IF;
END
$guarda_descartavel$;

SET manaloom.seed_deck_id = :'deck_id';

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
-- Legalidade das cartas do deck (D-28), ANTES de `deck_cards`.
--
-- As sintéticas têm id próprio deste seed, então a linha é afirmada como
-- 'legal'. O comandante vem do catálogo da fixture: a linha só é criada se
-- não existir. Uma legalidade já registrada para ele não é reescrita -- se
-- ela não for 'legal', a conferência do deck levanta exceção e a corrida
-- para, em vez de o seed esconder um comandante ilegal.
-- ---------------------------------------------------------------------------
INSERT INTO card_legalities (card_id, format, status)
SELECT ('20000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
       'commander', 'legal'
FROM generate_series(1, 36) AS i
UNION ALL
SELECT ('21000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
       'commander', 'legal'
FROM generate_series(1, 63) AS i
ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status;

INSERT INTO card_legalities (card_id, format, status)
VALUES (:'commander_card_id'::uuid, 'commander', 'legal')
ON CONFLICT (card_id, format) DO NOTHING;

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

-- Conferência do deck. PARA a corrida (RAISE EXCEPTION) se o comandante não
-- estiver 'legal' em commander -- linha ausente conta como não legal (D-28)
-- -- ou se o deck não for o combinado (100 cartas, 36 terrenos, 1
-- comandante, todas legais). Capturar sobre um deck diferente provaria outra
-- coisa; a contagem também sai como NOTICE para o log da corrida.
DO $conferencia_deck$
DECLARE
  v_deck uuid := current_setting('manaloom.seed_deck_id')::uuid;
  v_total integer;
  v_terrenos integer;
  v_comandantes integer;
  v_cartas_legais integer;
  v_status_comandante text;
BEGIN
  SELECT
    coalesce(sum(dc.quantity), 0),
    coalesce(sum(dc.quantity) FILTER (WHERE c.type_line ILIKE '%land%'), 0),
    coalesce(sum(dc.quantity) FILTER (WHERE dc.is_commander), 0),
    coalesce(sum(dc.quantity) FILTER (WHERE cl.status = 'legal'), 0)
  INTO v_total, v_terrenos, v_comandantes, v_cartas_legais
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  LEFT JOIN card_legalities cl
    ON cl.card_id = c.id AND cl.format = 'commander'
  WHERE dc.deck_id = v_deck;

  SELECT coalesce(min(cl.status), 'sem linha de legalidade')
  INTO v_status_comandante
  FROM deck_cards dc
  LEFT JOIN card_legalities cl
    ON cl.card_id = dc.card_id AND cl.format = 'commander'
  WHERE dc.deck_id = v_deck AND dc.is_commander;

  RAISE NOTICE 'deck semeado: total=%, terrenos=%, comandantes=%, '
    'cartas_legais=%, comandante=%',
    v_total, v_terrenos, v_comandantes, v_cartas_legais, v_status_comandante;

  IF v_total <> 100 OR v_terrenos <> 36 OR v_comandantes <> 1 THEN
    RAISE EXCEPTION
      'seed do deck otimizavel: deck fora do combinado (total=%, '
      'terrenos=%, comandantes=%; esperado 100/36/1); a corrida para aqui',
      v_total, v_terrenos, v_comandantes;
  END IF;
  IF v_status_comandante IS DISTINCT FROM 'legal' THEN
    RAISE EXCEPTION
      'seed do deck otimizavel: comandante nao e legal em commander (%); '
      'a corrida para aqui', v_status_comandante;
  END IF;
  IF v_cartas_legais <> 100 THEN
    RAISE EXCEPTION
      'seed do deck otimizavel: % de 100 cartas legais em commander; '
      'a corrida para aqui', v_cartas_legais;
  END IF;
END
$conferencia_deck$;

-- ---------------------------------------------------------------------------
-- Pool de candidatos de ADIÇÃO, deliberadamente FORA do deck.
--
-- Por que existe: sem candidato de adição a shortlist determinística sai
-- vazia, `deterministicFirstEnabled` fica falso em
-- `server/routes/ai/optimize/index.dart` e, sem provedor de IA, a rota
-- devolve o mock `mock_non_actionable` (D-82) -- sem sugestão, sem leitor de
-- carta. Antes da D-82 o mesmo galho TENTAVA sair para o provedor. Medido em
-- 2026-09-28, o catálogo descartável oferecia 1 único candidato ("Sol Ring",
-- e as duas linhas do catálogo colapsam em uma pelo
-- `DISTINCT ON (LOWER(c.name))` da consulta), com score zero e sujeito a
-- `filterCandidatesByBracketPolicy`. Um candidato só não sustenta a corrida.
--
-- Os filtros que a consulta de candidatos aplica
-- (`server/lib/ai/optimize_swap_candidate_support.dart`) são: legalidade
-- 'legal' ou 'restricted' no formato (D-28: sem linha, a carta não entra),
-- fora do deck, não-terreno, `oracle_text` não-vazio, nome sem os prefixos
-- vetados, e identidade contida na do comandante. NÃO existe porta de score
-- mínimo na montagem do pool: carta com `best_role_score` zero sobrevive. Por
-- isso não é preciso semear `card_intelligence_snapshot` nem
-- `commander_card_synergy`.
--
-- A seleção exige `matchesFunctionalNeedForCandidate` verdadeiro. Para a
-- necessidade 'utility' isso é sempre verdadeiro, e as necessidades saem das
-- cartas removidas. O pool cobre criatura, ramp e remoção com gatilhos em
-- inglês, para a corrida não depender dessa inferência.
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

-- Legalidade do pool (D-28): sem a linha, a consulta de candidatos descarta a
-- carta e o pool some em silêncio.
INSERT INTO card_legalities (card_id, format, status)
SELECT ('22000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
       'commander', 'legal'
FROM generate_series(1, 12) AS i
ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status;

-- Garantia explícita: nenhum candidato do pool entra no deck. Se um dia
-- alguém semear o deck a partir deste pool por engano, o candidato deixa de
-- ser candidato e a shortlist volta a esvaziar silenciosamente.
DELETE FROM deck_cards
WHERE deck_id = :'deck_id'::uuid
  AND card_id IN (
    SELECT ('22000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid
    FROM generate_series(1, 12) AS i
  );

-- Conferência do pool, com os MESMOS filtros da consulta de candidatos. PARA
-- a corrida (RAISE EXCEPTION) com menos de 12 candidatos de adição, antes de
-- capturar, em vez de descobrir a shortlist vazia só quando a rota devolver o
-- mock. `DISTINCT ON` replicado porque é ele que colapsou os dois "Sol Ring"
-- do catálogo em um só. Legalidade ausente NÃO conta (D-28), exatamente como
-- na consulta do otimizador. 12 é o pool que este seed semeia: abaixo disso
-- algum candidato dele sumiu do filtro, e a corrida já não é a combinada.
DO $conferencia_pool$
DECLARE
  v_deck uuid := current_setting('manaloom.seed_deck_id')::uuid;
  v_candidatos integer;
BEGIN
  WITH deck AS (
    SELECT LOWER(c.name) AS n
    FROM deck_cards dc JOIN cards c ON c.id = dc.card_id
    WHERE dc.deck_id = v_deck
  ), ident AS (
    SELECT c.color_identity AS ci
    FROM deck_cards dc JOIN cards c ON c.id = dc.card_id
    WHERE dc.deck_id = v_deck AND dc.is_commander
    LIMIT 1
  ), elegiveis AS (
    SELECT DISTINCT ON (LOWER(c.name)) c.name
    FROM cards c
    LEFT JOIN card_legalities cl
      ON cl.card_id = c.id AND cl.format = 'commander'
    WHERE (cl.status = 'legal' OR cl.status = 'restricted')
      AND LOWER(c.name) NOT IN (SELECT n FROM deck)
      AND NOT (COALESCE(c.type_line, '') ~* '(^|[^a-z])land([^a-z]|$)')
      AND c.name NOT LIKE 'A-%'
      AND c.name NOT LIKE '\_%' ESCAPE '\'
      AND c.name NOT LIKE '%World Champion%'
      AND c.name NOT LIKE '%Heroes of the Realm%'
      AND c.oracle_text IS NOT NULL
      AND LENGTH(TRIM(c.oracle_text)) > 0
      AND (c.color_identity <@ (SELECT ci FROM ident)
           OR c.color_identity = '{}' OR c.color_identity IS NULL)
    ORDER BY LOWER(c.name)
  )
  SELECT count(*) INTO v_candidatos FROM elegiveis;

  RAISE NOTICE 'candidatos_adicao=%', v_candidatos;

  IF v_candidatos < 12 THEN
    RAISE EXCEPTION
      'seed do deck otimizavel: candidatos_adicao=% (minimo 12); sem pool '
      'a shortlist sai vazia e a rota volta ao mock; a corrida para aqui',
      v_candidatos;
  END IF;
END
$conferencia_pool$;

-- Só chega aqui com as duas conferências aprovadas. Ver TRANSAÇÃO no topo.
COMMIT;
