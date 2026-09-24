import 'package:postgres/postgres.dart';

/// BT-DB-004: o schema só muda por migration (`bin/migrate.dart`) e pelo gate
/// de schema. Um CLI ou serviço não cria nem altera tabela, coluna, índice ou
/// view: confere, só lendo o catálogo, que o que ele usa existe, e para com a
/// lista do que falta.
class SchemaRequirements {
  const SchemaRequirements({
    this.tables = const {},
    this.columns = const {},
    this.indexes = const {},
    this.views = const {},
  });

  /// Tabelas em `public`.
  final Set<String> tables;

  /// Colunas por tabela, em `public`.
  final Map<String, Set<String>> columns;

  /// Índices em `public`, pelo nome.
  final Set<String> indexes;

  /// Views em `public`.
  final Set<String> views;
}

/// O schema não tem o que [caller] precisa.
class MissingSchemaObjects implements Exception {
  MissingSchemaObjects(this.caller, this.missing);

  final String caller;

  /// Cada item no formato `tabela x`, `coluna t.c`, `índice i` ou `view v`.
  final List<String> missing;

  @override
  String toString() =>
      'Schema incompleto para $caller: falta ${missing.join(', ')}. O schema '
      'só muda por migration: aplique bin/migrate.dart pelo fluxo aprovado.';
}

/// Confere [requirements] no catálogo, sem escrever nada, e lança
/// [MissingSchemaObjects] se faltar algum objeto.
Future<void> requireSchemaObjects(
  Session session, {
  required String caller,
  required SchemaRequirements requirements,
}) async {
  final kinds = <String>[];
  final names = <String>[];
  final parents = <String>[];
  void want(String kind, String name, [String parent = '']) {
    kinds.add(kind);
    names.add(name);
    parents.add(parent);
  }

  for (final table in requirements.tables) {
    want('tabela', table);
  }
  for (final MapEntry(key: table, value: columns)
      in requirements.columns.entries) {
    for (final column in columns) {
      want('coluna', column, table);
    }
  }
  for (final index in requirements.indexes) {
    want('índice', index);
  }
  for (final view in requirements.views) {
    want('view', view);
  }
  if (kinds.isEmpty) return;

  final result = await session.execute(
    Sql.named('''
      SELECT wanted.kind, wanted.name, wanted.parent
      FROM unnest(
        CAST(@kinds AS text[]),
        CAST(@names AS text[]),
        CAST(@parents AS text[])
      ) WITH ORDINALITY AS wanted(kind, name, parent, position)
      WHERE NOT CASE wanted.kind
        WHEN 'coluna' THEN EXISTS (
          SELECT 1
          FROM information_schema.columns column_info
          WHERE column_info.table_schema = 'public'
            AND column_info.table_name = wanted.parent
            AND column_info.column_name = wanted.name
        )
        ELSE EXISTS (
          SELECT 1
          FROM pg_class relation
          JOIN pg_namespace namespace ON namespace.oid = relation.relnamespace
          WHERE namespace.nspname = 'public'
            AND relation.relname = wanted.name
            AND relation.relkind = ANY(
              CASE wanted.kind
                WHEN 'tabela' THEN ARRAY['r', 'p']::"char"[]
                WHEN 'índice' THEN ARRAY['i', 'I']::"char"[]
                ELSE ARRAY['v', 'm']::"char"[]
              END
            )
        )
      END
      ORDER BY wanted.position
    '''),
    parameters: {'kinds': kinds, 'names': names, 'parents': parents},
  );
  if (result.isEmpty) return;
  throw MissingSchemaObjects(caller, [
    for (final row in result)
      row[0] == 'coluna' ? 'coluna ${row[2]}.${row[1]}' : '${row[0]} ${row[1]}',
  ]);
}
