-- D-85, correção 5, passo b: apaga `card_rulings_legacy` e o enum `poststatus`
-- (higiene da D-49), só depois do arquivo do passo a
-- (`d85_5a_legacy_ruling_poststatus_archive.sql`). O operador passa o sha256 e o
-- número de linhas do arquivo; o script recalcula o mesmo conteúdo no banco, sob
-- trava, e recusa sem apagar nada se não bater (arquivo velho, incompleto ou de outro
-- banco).
--
-- A tabela sai sem CASCADE: se algo ainda depender dela, a transação inteira é
-- desfeita. O enum sai só se nenhuma coluna o usar: na produção ele acompanha a
-- tabela `posts`, que é de outra decisão (D-49, BT-DB-006). Nesse caso a tabela sai,
-- o enum fica e o resultado diz `parcial` e quem o usa; quando a `posts` sair, os
-- dois passos rodam de novo e o enum sai.
--
-- Roda no lote de deploy, depois da promoção (decisão do dono de 2026-10-10, item 11),
-- pelo wrapper de escrita e com as duas aprovações canônicas no processo chamador.
-- Primeiro a prévia (o padrão): faz tudo, imprime antes, ação, depois e resultado e
-- desfaz (ROLLBACK). Sem o arquivo, a prévia mostra o sha256 e as linhas que o banco
-- tem hoje (`arquivo:sha256_no_banco`, `arquivo:linhas_no_banco`), para conferir com
-- o arquivo do passo a; com o arquivo, confere como a gravação:
--   server/bin/with_new_server_pg.sh --write-approved psql -X -v ON_ERROR_STOP=1 \
--     [-v arquivo_sha256=<sha256 do arquivo> -v arquivo_linhas=<linhas do arquivo>] \
--     -At -F $'\t' -f server/sql/lote/d85_5b_drop_legacy_ruling_poststatus.sql
-- Depois, com a palavra do dono sobre o número da prévia, a gravação: `-v aplicar=1`
-- exige o arquivo (sha256 e linhas, que fazem de esperado para as linhas conferidas)
-- e a contagem esperada de objetos apagados, e recusa tudo (RAISE) se algo não bater:
--   ... -v aplicar=1 -v arquivo_sha256=<sha256> -v arquivo_linhas=<linhas> \
--       -v esperado_objetos_apagados=<n da prévia> ...
-- Saída: linhas `fase<TAB>objeto<TAB>quantidade` (fases modo, antes, acao, depois e
-- resultado). Uma transação só. Idempotente: sem tabela e sem enum, não faz nada.

\set ON_ERROR_STOP on
\if :{?aplicar}
\else
\set aplicar 0
\endif
\if :{?esperado_objetos_apagados}
\else
\set esperado_objetos_apagados ''
\endif
\if :{?arquivo_sha256}
\else
\set arquivo_sha256 ''
\endif
\if :{?arquivo_linhas}
\else
\set arquivo_linhas ''
\endif

BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '300s';
SET LOCAL manaloom.lote_aplicar = :'aplicar';
SET LOCAL manaloom.lote_esperado_objetos_apagados = :'esperado_objetos_apagados';
SET LOCAL manaloom.d85_5_arquivo_sha256 = :'arquivo_sha256';
SET LOCAL manaloom.d85_5_arquivo_linhas = :'arquivo_linhas';

DO $d85_5_modo$
BEGIN
  IF current_setting('manaloom.lote_aplicar') NOT IN ('0', '1') THEN
    RAISE EXCEPTION
      'd85_5b recusado: -v aplicar aceita só 1 (gravar); sem ele o script é prévia. Nada foi apagado.';
  END IF;
  IF current_setting('manaloom.lote_aplicar') = '1' THEN
    IF current_setting('manaloom.lote_esperado_objetos_apagados') !~ '^[0-9]+$' THEN
      RAISE EXCEPTION
        'd85_5b recusado: com -v aplicar=1, informe -v esperado_objetos_apagados=<n> (a contagem da prévia). Nada foi apagado.';
    END IF;
  END IF;
END;
$d85_5_modo$;

SELECT current_setting('manaloom.lote_aplicar') = '1' AS lote_grava \gset

SELECT 'modo' AS fase, 'escrita' AS objeto,
       CASE WHEN current_setting('manaloom.lote_aplicar') = '1'
            THEN 'aplicar' ELSE 'previa' END AS quantidade;

-- Objeto temporário dentro da transação: some no COMMIT ou no ROLLBACK da prévia.
CREATE TEMP VIEW d85_5_estado AS
SELECT 1 AS ordem,
       'card_rulings_legacy:linhas' AS objeto,
       CASE
         WHEN to_regclass('public.card_rulings_legacy') IS NULL THEN 'ausente'
         ELSE (
           xpath(
             '/row/c/text()',
             query_to_xml(
               'SELECT COUNT(*) AS c FROM public.card_rulings_legacy',
               false,
               true,
               ''
             )
           )
         )[1]::text
       END AS quantidade
UNION ALL
SELECT 2,
       'poststatus:estado',
       CASE
         WHEN to_regtype('public.poststatus') IS NULL THEN 'ausente'
         ELSE 'presente'
       END
UNION ALL
SELECT 3,
       'poststatus:colunas_que_usam',
       COALESCE(
         (
           SELECT string_agg(
                    format('%s.%I', attribute_row.attrelid::regclass, attribute_row.attname),
                    ',' ORDER BY attribute_row.attrelid::regclass::text, attribute_row.attname
                  )
           FROM pg_attribute attribute_row
           JOIN pg_type type_row ON type_row.oid = attribute_row.atttypid
           WHERE attribute_row.attnum > 0
             AND NOT attribute_row.attisdropped
             AND (
               attribute_row.atttypid = to_regtype('public.poststatus')
               OR type_row.typelem = to_regtype('public.poststatus')
             )
         ),
         '-'
       );

SELECT 'antes' AS fase, objeto, quantidade FROM d85_5_estado ORDER BY ordem;

DO $d85_5_drop$
DECLARE
  tem_tabela BOOLEAN := to_regclass('public.card_rulings_legacy') IS NOT NULL;
  tem_tipo BOOLEAN := to_regtype('public.poststatus') IS NOT NULL;
  esperado_sha TEXT :=
    lower(btrim(COALESCE(current_setting('manaloom.d85_5_arquivo_sha256', true), '')));
  esperado_linhas TEXT :=
    btrim(COALESCE(current_setting('manaloom.d85_5_arquivo_linhas', true), ''));
  conteudo TEXT := '';
  parte TEXT;
  linhas BIGINT := 0;
  linhas_parte BIGINT;
  sha_atual TEXT;
  uso TEXT;
  resultado TEXT := 'completo';
  conferencia TEXT := 'conferido';
  objetos_apagados INTEGER := 0;
BEGIN
  IF NOT tem_tabela AND NOT tem_tipo THEN
    PERFORM set_config('manaloom.d85_5_resultado', 'nada_a_fazer', true);
    PERFORM set_config('manaloom.d85_5_apagados', '0', true);
    PERFORM set_config('manaloom.d85_5_objetos_apagados', '0', true);
    PERFORM set_config('manaloom.d85_5_conferencia', 'nada_a_conferir', true);
    PERFORM set_config('manaloom.d85_5_sha_no_banco', '-', true);
    PERFORM set_config('manaloom.d85_5_linhas_no_banco', '0', true);
    RETURN;
  END IF;

  IF tem_tabela THEN
    LOCK TABLE public.card_rulings_legacy IN ACCESS EXCLUSIVE MODE;
  END IF;

  -- O mesmo texto do passo a, na mesma ordem.
  IF tem_tipo THEN
    SELECT json_build_object(
             'objeto', 'public.poststatus',
             'tipo', 'enum',
             'rotulos', (
               SELECT json_agg(enum_row.enumlabel ORDER BY enum_row.enumsortorder)
               FROM pg_enum enum_row
               WHERE enum_row.enumtypid = 'public.poststatus'::regtype
             )
           )::text
    INTO parte;
    conteudo := conteudo || parte || E'\n';
    linhas := linhas + 1;
  END IF;
  IF tem_tabela THEN
    EXECUTE $arquivo$
      SELECT COALESCE(
               string_agg(arquivo.linha || E'\n', '' ORDER BY arquivo.linha COLLATE "C"),
               ''
             ),
             COUNT(*)
      FROM (
        SELECT json_build_object(
                 'objeto', 'public.card_rulings_legacy',
                 'linha', row_to_json(registro)
               )::text AS linha
        FROM public.card_rulings_legacy registro
      ) arquivo
    $arquivo$
    INTO parte, linhas_parte;
    conteudo := conteudo || parte;
    linhas := linhas + linhas_parte;
  END IF;
  sha_atual := encode(sha256(convert_to(conteudo, 'UTF8')), 'hex');
  PERFORM set_config('manaloom.d85_5_sha_no_banco', sha_atual, true);
  PERFORM set_config('manaloom.d85_5_linhas_no_banco', linhas::text, true);

  -- A prévia sem o arquivo só mostra o que o banco tem; a gravação sempre confere.
  IF current_setting('manaloom.lote_aplicar') <> '1'
     AND esperado_sha = '' AND esperado_linhas = '' THEN
    conferencia := 'nao_informado';
  ELSE
    IF esperado_sha !~ '^[0-9a-f]{64}$' OR esperado_linhas !~ '^[0-9]+$' THEN
      RAISE EXCEPTION
        'd85_5b recusado: informe -v arquivo_sha256 e -v arquivo_linhas do arquivo do passo a (D-85: arquivar antes de apagar). Nada foi apagado.';
    END IF;
    IF sha_atual <> esperado_sha OR linhas <> esperado_linhas::BIGINT THEN
      RAISE EXCEPTION
        'd85_5b recusado: o arquivo (sha256 %, % linha(s)) não confere com o banco (sha256 %, % linha(s)); gere o arquivo de novo. Nada foi apagado.',
        esperado_sha, esperado_linhas, sha_atual, linhas;
    END IF;
  END IF;

  IF tem_tabela THEN
    DROP TABLE public.card_rulings_legacy;
    objetos_apagados := objetos_apagados + 1;
  END IF;

  IF tem_tipo THEN
    SELECT string_agg(
             format('%s.%I', attribute_row.attrelid::regclass, attribute_row.attname),
             ',' ORDER BY attribute_row.attrelid::regclass::text, attribute_row.attname
           )
    INTO uso
    FROM pg_attribute attribute_row
    JOIN pg_type type_row ON type_row.oid = attribute_row.atttypid
    WHERE attribute_row.attnum > 0
      AND NOT attribute_row.attisdropped
      AND (
        attribute_row.atttypid = 'public.poststatus'::regtype
        OR type_row.typelem = 'public.poststatus'::regtype
      );
    BEGIN
      DROP TYPE public.poststatus;
      objetos_apagados := objetos_apagados + 1;
    EXCEPTION WHEN dependent_objects_still_exist THEN
      resultado := 'parcial: poststatus ficou, em uso por '
        || COALESCE(uso, 'outro objeto do banco')
        || ' (sai com a posts, D-49/BT-DB-006)';
    END;
  END IF;

  PERFORM set_config('manaloom.d85_5_resultado', resultado, true);
  PERFORM set_config('manaloom.d85_5_conferencia', conferencia, true);
  PERFORM set_config(
    'manaloom.d85_5_apagados',
    CASE WHEN conferencia = 'conferido' THEN linhas::text ELSE '0' END,
    true
  );
  PERFORM set_config('manaloom.d85_5_objetos_apagados', objetos_apagados::text, true);
END;
$d85_5_drop$;

SELECT 'acao' AS fase, 'arquivo:sha256_no_banco' AS objeto,
       current_setting('manaloom.d85_5_sha_no_banco') AS quantidade;
SELECT 'acao' AS fase, 'arquivo:linhas_no_banco' AS objeto,
       current_setting('manaloom.d85_5_linhas_no_banco') AS quantidade;
SELECT 'acao' AS fase, 'arquivo:conferencia' AS objeto,
       current_setting('manaloom.d85_5_conferencia') AS quantidade;
SELECT 'acao' AS fase, 'linhas_do_arquivo_conferidas' AS objeto,
       current_setting('manaloom.d85_5_apagados') AS quantidade;
SELECT 'acao' AS fase, 'objetos_apagados' AS objeto,
       current_setting('manaloom.d85_5_objetos_apagados') AS quantidade;

SELECT 'depois' AS fase, objeto, quantidade FROM d85_5_estado ORDER BY ordem;

SELECT 'resultado' AS fase, 'd85_5' AS objeto,
       current_setting('manaloom.d85_5_resultado') AS quantidade;

DO $d85_5_pos$
BEGIN
  IF to_regclass('public.card_rulings_legacy') IS NOT NULL THEN
    RAISE EXCEPTION 'd85_5b: card_rulings_legacy continua no banco';
  END IF;
  IF current_setting('manaloom.lote_aplicar') = '1' THEN
    IF current_setting('manaloom.d85_5_objetos_apagados')::integer
       <> current_setting('manaloom.lote_esperado_objetos_apagados')::integer THEN
      RAISE EXCEPTION
        'd85_5b recusado: a ação apagou % objeto(s) e o esperado (-v esperado_objetos_apagados) é %. Nada foi apagado.',
        current_setting('manaloom.d85_5_objetos_apagados'),
        current_setting('manaloom.lote_esperado_objetos_apagados');
    END IF;
  END IF;
END;
$d85_5_pos$;

DROP VIEW d85_5_estado;

\if :lote_grava
COMMIT;
SELECT 'modo' AS fase, 'desfecho' AS objeto, 'commit' AS quantidade;
\else
ROLLBACK;
SELECT 'modo' AS fase, 'desfecho' AS objeto, 'rollback' AS quantidade;
\endif
