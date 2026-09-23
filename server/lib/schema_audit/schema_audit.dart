/// Auditoria de schema (BT-DB-001): compara o inventário de um banco-alvo com
/// o de um banco-base criado do zero pelas migrations e classifica cada
/// diferença em faltando (só na base), sobrando (só no alvo) ou divergente
/// (nos dois, com definição diferente).
///
/// Este arquivo só compara e escreve relatório; quem lê os bancos é
/// `bin/schema_audit.dart`, sempre em transação somente leitura. Nada aqui
/// apaga, cria ou altera objeto de banco: diferença vira item de relatório.
library;

import 'dart:convert';

/// Erro de uso do auditor (URL ou opção inválida), antes de qualquer conexão.
class AuditUsageException implements Exception {
  AuditUsageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Banco a ler, validado antes de conectar.
class AuditTarget {
  const AuditTarget({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.loopback,
  });

  final String host;
  final int port;
  final String database;
  final String username;

  /// Loopback dispensa TLS (PostgreSQL descartável local); host remoto exige.
  final bool loopback;
}

const auditLoopbackHosts = {'127.0.0.1', 'localhost', '::1'};

/// Valida `postgres://usuario@host:porta/banco`. A senha nunca vem na URL,
/// só do ambiente (`passwordEnvironment`); host fora do loopback só com
/// `allowRemote`. As mensagens de erro não repetem a URL.
AuditTarget parseAuditTarget(
  String url, {
  required String passwordEnvironment,
  required bool allowRemote,
}) {
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'postgres' && uri.scheme != 'postgresql')) {
    throw AuditUsageException('a URL precisa começar com postgres://');
  }
  if (uri.userInfo.contains(':')) {
    throw AuditUsageException(
      'senha na URL é recusada; use $passwordEnvironment',
    );
  }
  final loopback = auditLoopbackHosts.contains(uri.host);
  if (!loopback && !allowRemote) {
    throw AuditUsageException(
      'o host ${uri.host} está fora do loopback e exige --allow-remote',
    );
  }
  final database = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
  if (database.isEmpty || uri.userInfo.isEmpty) {
    throw AuditUsageException('a URL precisa de usuário e banco');
  }
  return AuditTarget(
    host: uri.host,
    port: uri.hasPort ? uri.port : 5432,
    database: database,
    username: Uri.decodeComponent(uri.userInfo),
    loopback: loopback,
  );
}

/// Inventário de um banco, lido só do catálogo.
class SchemaInventory {
  const SchemaInventory({
    required this.label,
    required this.database,
    required this.serverVersion,
    required this.schemas,
    required this.tables,
    required this.views,
    required this.columns,
    required this.foreignKeys,
    required this.indexes,
    required this.migrations,
  });

  final String label;
  final String database;
  final String serverVersion;

  /// Schemas fora do sistema.
  final Set<String> schemas;

  /// `schema.tabela`.
  final Set<String> tables;

  /// `schema.view` para a definição normalizada.
  final Map<String, String> views;

  /// `schema.tabela.coluna`.
  final Map<String, ColumnShape> columns;

  /// Assinatura (`schema.tabela: FOREIGN KEY (...) REFERENCES ...(...)`) para
  /// a definição completa, com ações e adiamento.
  final Map<String, ForeignKeyShape> foreignKeys;

  /// `schema.índice`.
  final Map<String, IndexShape> indexes;

  /// Ledger `schema_migrations`: versão para nome. `null` quando o banco não
  /// tem a tabela.
  final Map<String, String>? migrations;
}

class ColumnShape {
  const ColumnShape({
    required this.type,
    required this.notNull,
    required this.defaultExpression,
  });

  final String type;
  final bool notNull;
  final String? defaultExpression;

  Map<String, Object?> toJson() => {
    'tipo': type,
    'not_null': notNull,
    'default': defaultExpression,
  };
}

class ForeignKeyShape {
  const ForeignKeyShape({required this.name, required this.definition});

  final String name;
  final String definition;

  Map<String, Object?> toJson() => {'nome': name, 'definicao': definition};
}

class IndexShape {
  const IndexShape({required this.table, required this.definition});

  final String table;

  /// `pg_get_indexdef` sem o nome do índice, para dois índices iguais com
  /// nomes diferentes se reconhecerem.
  final String definition;

  Map<String, Object?> toJson() => {'tabela': table, 'definicao': definition};
}

/// Tira o nome do índice da definição de `pg_get_indexdef`.
String normalizeIndexDefinition(String definition) => definition.replaceFirst(
  RegExp(r'INDEX\s+("[^"]+"|\S+)\s+ON\s+'),
  'INDEX ON ',
);

/// Assinatura de uma chave estrangeira sem as ações: identifica "a mesma FK"
/// nos dois bancos, mesmo com nomes gerados diferentes.
String foreignKeySignature(String qualifiedTable, String definition) {
  final core =
      RegExp(
        r'^FOREIGN KEY \([^)]*\) REFERENCES [^(]+\([^)]*\)',
      ).firstMatch(definition)?.group(0) ??
      definition;
  return '$qualifiedTable: $core';
}

/// Diferenças de uma categoria.
class DiffBucket {
  final List<Object?> faltando = [];
  final List<Object?> sobrando = [];
  final List<Object?> divergente = [];

  bool get isEmpty =>
      faltando.isEmpty && sobrando.isEmpty && divergente.isEmpty;

  Map<String, Object?> toJson() => {
    'faltando': faltando,
    'sobrando': sobrando,
    'divergente': divergente,
  };

  Map<String, int> counts() => {
    'faltando': faltando.length,
    'sobrando': sobrando.length,
    'divergente': divergente.length,
  };
}

class SchemaAuditReport {
  SchemaAuditReport({
    required this.baseline,
    required this.target,
    required this.generatedAt,
  });

  final SchemaInventory baseline;
  final SchemaInventory target;
  final DateTime generatedAt;

  final schemas = DiffBucket();
  final tables = DiffBucket();
  final views = DiffBucket();
  final columns = DiffBucket();
  final foreignKeys = DiffBucket();
  final indexes = DiffBucket();
  final migrations = DiffBucket();

  /// Schemas só do alvo: resumidos (contagens), sem enumerar cada objeto.
  final extraSchemaSummaries = <String, Map<String, int>>{};

  Map<String, DiffBucket> get buckets => {
    'schemas': schemas,
    'tabelas': tables,
    'views': views,
    'colunas': columns,
    'chaves_estrangeiras': foreignKeys,
    'indices': indexes,
    'ledger_schema_migrations': migrations,
  };

  bool get hasDifferences => buckets.values.any((bucket) => !bucket.isEmpty);

  String? latestMigration(SchemaInventory inventory) {
    final versions = inventory.migrations?.keys.toList()?..sort();
    return versions == null || versions.isEmpty ? null : versions.last;
  }

  Map<String, Object?> toJson() => {
    'schema_version': 1,
    'ferramenta': 'server/bin/schema_audit.dart',
    'gerado_em': generatedAt.toUtc().toIso8601String(),
    'politica': {
      'somente_leitura': true,
      'apaga_extras': false,
      'classificacao': {
        'faltando': 'existe na base criada pelas migrations e não no alvo',
        'sobrando': 'existe no alvo e não na base',
        'divergente': 'existe nos dois com definição diferente',
      },
    },
    'base': _inventorySummary(baseline),
    'alvo': _inventorySummary(target),
    'resumo': {
      for (final entry in buckets.entries) entry.key: entry.value.counts(),
    },
    'schemas_sobrando_resumo': extraSchemaSummaries,
    'diferencas': {
      for (final entry in buckets.entries) entry.key: entry.value.toJson(),
    },
  };

  Map<String, Object?> _inventorySummary(SchemaInventory inventory) => {
    'rotulo': inventory.label,
    'banco': inventory.database,
    'versao_servidor': inventory.serverVersion,
    'schemas': inventory.schemas.length,
    'tabelas': inventory.tables.length,
    'views': inventory.views.length,
    'colunas': inventory.columns.length,
    'chaves_estrangeiras': inventory.foreignKeys.length,
    'indices': inventory.indexes.length,
    'migrations': inventory.migrations?.length,
    'ultima_migration': latestMigration(inventory),
  };

  String toJsonText() =>
      '${const JsonEncoder.withIndent('  ').convert(toJson())}\n';

  String toMarkdown() {
    final out =
        StringBuffer()
          ..writeln(
            '# Auditoria de schema — ${target.label} contra ${baseline.label}',
          )
          ..writeln()
          ..writeln(
            'Gerado por `server/bin/schema_audit.dart` em '
            '${generatedAt.toUtc().toIso8601String()}. Somente leitura: nada foi '
            'criado, alterado nem apagado; extras ficam só no relatório.',
          )
          ..writeln()
          ..writeln('| | Base (${baseline.label}) | Alvo (${target.label}) |')
          ..writeln('| --- | ---: | ---: |');
    final base = _inventorySummary(baseline);
    final alvo = _inventorySummary(target);
    for (final key in const [
      'banco',
      'versao_servidor',
      'schemas',
      'tabelas',
      'views',
      'colunas',
      'chaves_estrangeiras',
      'indices',
      'migrations',
      'ultima_migration',
    ]) {
      out.writeln('| $key | ${base[key] ?? '—'} | ${alvo[key] ?? '—'} |');
    }
    out
      ..writeln()
      ..writeln('## Resumo das diferenças')
      ..writeln()
      ..writeln('| Categoria | Faltando | Sobrando | Divergente |')
      ..writeln('| --- | ---: | ---: | ---: |');
    for (final entry in buckets.entries) {
      final counts = entry.value.counts();
      out.writeln(
        '| ${entry.key} | ${counts['faltando']} | ${counts['sobrando']} | '
        '${counts['divergente']} |',
      );
    }
    if (extraSchemaSummaries.isNotEmpty) {
      out
        ..writeln()
        ..writeln(
          'Schemas só no alvo, resumidos (seus objetos não entram nas '
          'demais categorias):',
        )
        ..writeln();
      for (final entry in extraSchemaSummaries.entries) {
        final counts = entry.value.entries
            .map((count) => '${count.value} ${count.key}')
            .join(', ');
        out.writeln('- `${entry.key}`: $counts');
      }
    }
    for (final entry in buckets.entries) {
      if (entry.value.isEmpty) continue;
      out
        ..writeln()
        ..writeln('## ${entry.key}');
      for (final kind in const ['faltando', 'sobrando', 'divergente']) {
        final items = entry.value.toJson()[kind]! as List<Object?>;
        if (items.isEmpty) continue;
        out
          ..writeln()
          ..writeln('### $kind (${items.length})')
          ..writeln();
        for (final item in items) {
          out.writeln('- ${_markdownItem(item)}');
        }
      }
    }
    return out.toString();
  }

  static String _markdownItem(Object? item) {
    if (item is String) return '`$item`';
    if (item is Map) {
      final name = item['objeto'];
      final rest = Map.of(item)..remove('objeto');
      return '`$name` — ${jsonEncode(rest)}';
    }
    return jsonEncode(item);
  }
}

/// Compara o alvo com a base. Só lê os dois inventários.
SchemaAuditReport compareSchemaInventories(
  SchemaInventory baseline,
  SchemaInventory target, {
  required DateTime generatedAt,
  Map<String, Map<String, int>> targetSchemaObjectCounts = const {},
}) {
  final report = SchemaAuditReport(
    baseline: baseline,
    target: target,
    generatedAt: generatedAt,
  );

  final extraSchemas =
      target.schemas.difference(baseline.schemas).toList()..sort();
  bool inExtraSchema(String qualified) =>
      extraSchemas.contains(qualified.split('.').first);

  for (final schema
      in baseline.schemas.difference(target.schemas).toList()..sort()) {
    report.schemas.faltando.add(schema);
  }
  for (final schema in extraSchemas) {
    report.schemas.sobrando.add(schema);
    report.extraSchemaSummaries[schema] =
        targetSchemaObjectCounts[schema] ?? const {};
  }

  _compareSets(
    baseline.tables,
    target.tables.where((table) => !inExtraSchema(table)).toSet(),
    report.tables,
  );

  _compareMaps<String>(
    baseline.views,
    {
      for (final entry in target.views.entries)
        if (!inExtraSchema(entry.key)) entry.key: entry.value,
    },
    report.views,
    describe: (definition) => definition,
    difference:
        (base, alvo) =>
            _normalizeSql(base) == _normalizeSql(alvo)
                ? null
                : {'base': base, 'alvo': alvo},
  );

  // Colunas de tabelas que faltam ou sobram inteiras já estão na categoria
  // de tabelas; aqui entram só as colunas de tabelas presentes nos dois.
  final commonTables = baseline.tables.intersection(target.tables);
  bool inCommonTable(String column) {
    final parts = column.split('.');
    return commonTables.contains('${parts[0]}.${parts[1]}');
  }

  _compareMaps<ColumnShape>(
    {
      for (final entry in baseline.columns.entries)
        if (inCommonTable(entry.key)) entry.key: entry.value,
    },
    {
      for (final entry in target.columns.entries)
        if (inCommonTable(entry.key)) entry.key: entry.value,
    },
    report.columns,
    describe: (shape) => shape.toJson(),
    difference: (base, alvo) {
      final diff = <String, Object?>{};
      if (base.type != alvo.type) diff['tipo'] = [base.type, alvo.type];
      if (base.notNull != alvo.notNull) {
        diff['not_null'] = [base.notNull, alvo.notNull];
      }
      if (base.defaultExpression != alvo.defaultExpression) {
        diff['default'] = [base.defaultExpression, alvo.defaultExpression];
      }
      return diff.isEmpty ? null : diff;
    },
  );

  _compareMaps<ForeignKeyShape>(
    baseline.foreignKeys,
    {
      for (final entry in target.foreignKeys.entries)
        if (!inExtraSchema(entry.key)) entry.key: entry.value,
    },
    report.foreignKeys,
    describe: (shape) => shape.toJson(),
    difference:
        (base, alvo) =>
            base.definition == alvo.definition
                ? null
                : {
                  'definicao': [base.definition, alvo.definition],
                  'nome': [base.name, alvo.name],
                },
  );

  _compareIndexes(baseline.indexes, {
    for (final entry in target.indexes.entries)
      if (!inExtraSchema(entry.key)) entry.key: entry.value,
  }, report.indexes);

  final baseMigrations = baseline.migrations ?? const <String, String>{};
  final targetMigrations = target.migrations;
  if (targetMigrations == null) {
    report.migrations.faltando.add({
      'objeto': 'public.schema_migrations',
      'motivo': 'o alvo não tem o ledger',
    });
  } else {
    _compareMaps<String>(
      baseMigrations,
      targetMigrations,
      report.migrations,
      describe: (name) => name,
      difference:
          (base, alvo) =>
              base == alvo
                  ? null
                  : {
                    'nome': [base, alvo],
                  },
    );
  }
  return report;
}

void _compareSets(Set<String> base, Set<String> alvo, DiffBucket bucket) {
  bucket.faltando.addAll(base.difference(alvo).toList()..sort());
  bucket.sobrando.addAll(alvo.difference(base).toList()..sort());
}

void _compareMaps<T>(
  Map<String, T> base,
  Map<String, T> alvo,
  DiffBucket bucket, {
  required Object? Function(T value) describe,
  required Map<String, Object?>? Function(T base, T alvo) difference,
}) {
  for (final key in (base.keys.toSet()..addAll(alvo.keys)).toList()..sort()) {
    final inBase = base.containsKey(key);
    final inAlvo = alvo.containsKey(key);
    if (inBase && !inAlvo) {
      bucket.faltando.add({'objeto': key, 'base': describe(base[key] as T)});
    } else if (!inBase && inAlvo) {
      bucket.sobrando.add({'objeto': key, 'alvo': describe(alvo[key] as T)});
    } else {
      final diff = difference(base[key] as T, alvo[key] as T);
      if (diff != null) bucket.divergente.add({'objeto': key, ...diff});
    }
  }
}

/// Índices: pelo nome; um índice que falta com o mesmo desenho de um que
/// sobra na mesma tabela vira divergente só no nome.
void _compareIndexes(
  Map<String, IndexShape> base,
  Map<String, IndexShape> alvo,
  DiffBucket bucket,
) {
  final missing = <String>[];
  final extra = <String>[];
  for (final key in (base.keys.toSet()..addAll(alvo.keys)).toList()..sort()) {
    final baseShape = base[key];
    final alvoShape = alvo[key];
    if (baseShape != null && alvoShape == null) {
      missing.add(key);
    } else if (baseShape == null && alvoShape != null) {
      extra.add(key);
    } else if (baseShape!.definition != alvoShape!.definition ||
        baseShape.table != alvoShape.table) {
      bucket.divergente.add({
        'objeto': key,
        'definicao': [baseShape.definition, alvoShape.definition],
      });
    }
  }
  final renamedExtras = <String>{};
  for (final key in missing) {
    final shape = base[key]!;
    final twin = extra.firstWhere(
      (candidate) =>
          !renamedExtras.contains(candidate) &&
          alvo[candidate]!.table == shape.table &&
          alvo[candidate]!.definition == shape.definition,
      orElse: () => '',
    );
    if (twin.isEmpty) {
      bucket.faltando.add({'objeto': key, 'base': shape.toJson()});
    } else {
      renamedExtras.add(twin);
      bucket.divergente.add({
        'objeto': key,
        'nome': [key, twin],
        'definicao_igual': true,
      });
    }
  }
  for (final key in extra) {
    if (renamedExtras.contains(key)) continue;
    bucket.sobrando.add({'objeto': key, 'alvo': alvo[key]!.toJson()});
  }
}

String _normalizeSql(String sql) => sql.replaceAll(RegExp(r'\s+'), ' ').trim();
