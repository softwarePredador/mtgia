import 'dart:io';
import 'dart:math';

import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;

/// BT-DB-007: a trava de conta ativa (`manaloom_active_user_<oid>`, migration
/// 038) em toda chave estrangeira de uma coluna para `users`.
///
/// O gatilho leva o OID da chave no nome e nasce de um laço genérico sobre
/// `pg_constraint`, que só enxerga as chaves que existem quando ele roda. No
/// banco novo, o bootstrap (`database_setup.sql`) já tem todas as tabelas
/// quando as migrations rodam o laço. No banco migrado, que é o caminho da
/// produção, a chave criada depois do último laço fica sem gatilho: foi o que
/// a 067 e a 069 fizeram, e a 074 refaz o laço.
///
/// A regra: toda migration a partir da 070 que cria chave para `users` roda o
/// laço canônico no fim do `up`, depois da última chave. Até a 069, cada chave
/// para `users` precisa de um laço depois dela, na mesma migration ou numa
/// seguinte.
void main() {
  final setupSql = File('database_setup.sql').readAsStringSync();
  final canonicalLoop = _canonicalLoop(
    migrate.migrations.singleWhere((migration) => migration.version == '056'),
  );

  test('o laço canônico (o da 056) é o do bootstrap, e todo laço de conta '
      'ativa num up é igual a ele', () {
    expect(
      canonicalLoop,
      allOf(
        contains("confrelid = 'users'::regclass"),
        contains('DROP TRIGGER IF EXISTS %I ON %I.%I'),
        contains('manaloom_require_active_user(%L)'),
      ),
    );
    expect(
      [
        for (final statement in splitPostgresStatements(setupSql))
          if (_isActiveUserLoop(statement)) _normalized(statement),
      ],
      [canonicalLoop],
    );
    for (final migration in migrate.migrations) {
      for (final statement in splitPostgresStatements(migration.up)) {
        if (!_isActiveUserLoop(statement)) continue;
        expect(
          _normalized(statement),
          canonicalLoop,
          reason: '${migration.fullName} roda um laço diferente do canônico',
        );
      }
    }
  });

  test('no bootstrap, o laço vem depois de toda chave para users', () {
    final statements = splitPostgresStatements(setupSql);
    final loop = statements.indexWhere(_isActiveUserLoop);
    final lastKey = statements.lastIndexWhere(_createsUsersKey);
    expect(loop, greaterThan(lastKey));
  });

  test('a 074 roda só o laço canônico, com down neutro e rollback padrão', () {
    final migration = migrate.migrations.singleWhere(
      (migration) => migration.version == '074',
    );
    expect(migration.name, 'reinstall_active_user_triggers');
    expect(
      [
        for (final statement in splitPostgresStatements(migration.up))
          _normalized(statement),
      ],
      [canonicalLoop],
    );
    // O down não tira gatilho: eles são a trava da 038.
    expect(migration.down, 'SELECT 1;');
    expect(
      migrate.migrationRollbackPolicy('074'),
      migrate.MigrationRollbackPolicy.standard,
    );
  });

  test('toda chave para users tem um laço depois dela; a partir da 070, na '
      'própria migration', () {
    expect(
      activeUserRuleViolations(migrate.migrations, canonicalLoop),
      isEmpty,
    );
  });

  test('sem a 074, a regra acusa as chaves criadas depois do último laço', () {
    final withoutTheFix = [
      for (final migration in migrate.migrations)
        if (migration.version != '074') migration,
    ];
    final flagged = activeUserRuleViolations(withoutTheFix, canonicalLoop);
    expect(flagged, isNotEmpty);
    for (final violation in flagged) {
      final version = int.parse(violation.substring(0, 3));
      expect(version, inInclusiveRange(57, 73), reason: violation);
    }
  });

  group('uma migration futura', () {
    final key = migrate.Migration(
      version: '080',
      name: 'future_table',
      up: '''
        CREATE TABLE IF NOT EXISTS future_table (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
        );
      ''',
    );
    List<String> check(List<migrate.Migration> future) =>
        activeUserRuleViolations([
          ...migrate.migrations,
          ...future,
        ], canonicalLoop);
    migrate.Migration withUp(String version, String up) =>
        migrate.Migration(version: version, name: 'future_$version', up: up);

    test('que cria chave para users e esquece o laço quebra a regra', () {
      expect(check([key]), [
        '080_future_table: cria chave para users e não roda o laço canônico '
            'no fim do up',
      ]);
    });

    test('com o laço antes da chave também quebra', () {
      expect(
        check([withUp('080', '$canonicalLoop;\n${key.up}')]),
        hasLength(1),
      );
    });

    test('com o laço canônico no fim passa', () {
      expect(check([withUp('080', '${key.up}\n$canonicalLoop;')]), isEmpty);
    });

    test('um laço seguinte não dispensa a da 070 em diante', () {
      expect(check([key, withUp('081', '$canonicalLoop;')]), hasLength(1));
    });

    test('a regra enxerga a chave sem coluna, com schema, entre aspas e '
        'num ALTER TABLE, e ignora comentário e outra tabela', () {
      for (final up in const [
        'ALTER TABLE t ADD COLUMN owner UUID REFERENCES users ON DELETE SET NULL;',
        'ALTER TABLE t ADD CONSTRAINT t_owner_fkey FOREIGN KEY (owner) '
            'REFERENCES public.users(id);',
        'CREATE TABLE t (owner UUID REFERENCES "users" ("id"));',
      ]) {
        expect(check([withUp('080', up)]), hasLength(1), reason: up);
      }
      for (final up in const [
        '-- REFERENCES users(id)\nCREATE TABLE t (id UUID);',
        'CREATE TABLE t (owner UUID REFERENCES users_profiles(id));',
        '/* REFERENCES users(id) */ CREATE TABLE t (id UUID);',
      ]) {
        expect(check([withUp('080', up)]), isEmpty, reason: up);
      }
    });

    test('um laço diferente do canônico não conta como laço', () {
      final partial = canonicalLoop.replaceFirst(
        "AND array_length(constraint_row.conkey, 1) = 1",
        "AND relation_row.relname = 'future_table'",
      );
      expect(partial, isNot(canonicalLoop));
      expect(check([withUp('080', '${key.up}\n$partial;')]), hasLength(1));
    });

    test('antes da 070, um laço numa migration seguinte cobre a chave', () {
      final older = withUp('069', key.up);
      expect(activeUserRuleViolations([older], canonicalLoop), [
        '069_future_069: a chave para users fica sem gatilho no banco '
            'migrado (nenhum laço canônico depois dela)',
      ]);
      expect(
        activeUserRuleViolations([
          older,
          withUp('074', '$canonicalLoop;'),
        ], canonicalLoop),
        isEmpty,
      );
    });
  });
}

/// A primeira migration sob a regra. Até a 069 as migrations já existiam
/// quando a regra nasceu (2026-09-28); a 067 e a 069 dependem da 074.
const firstVersionUnderRule = 70;

final _usersKey = RegExp(
  r'REFERENCES\s+(?:public\.)?"?users"?(?![A-Za-z0-9_$])',
  caseSensitive: false,
);

String _withoutComments(String sql) => sql
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ')
    .replaceAll(RegExp(r'--[^\n]*'), ' ');

String _normalized(String sql) => _withoutComments(
  sql,
).split(RegExp(r'\s+')).where((part) => part.isNotEmpty).join(' ');

bool _isActiveUserLoop(String statement) =>
    _normalized(statement).startsWith(r'DO $active_user_triggers$');

bool _createsUsersKey(String statement) =>
    _usersKey.hasMatch(_withoutComments(statement));

String _canonicalLoop(migrate.Migration migration) => _normalized(
  splitPostgresStatements(migration.up).lastWhere(_isActiveUserLoop),
);

/// As violações da regra numa lista de migrations, na ordem em que o runner as
/// aplica.
List<String> activeUserRuleViolations(
  List<migrate.Migration> migrations,
  String canonicalLoop,
) {
  final scans = [
    for (final migration in migrations)
      _scan(splitPostgresStatements(migration.up), canonicalLoop),
  ];
  final violations = <String>[];
  for (var index = 0; index < migrations.length; index++) {
    final migration = migrations[index];
    final scan = scans[index];
    if (scan.keys.isEmpty) continue;
    final lastKey = scan.keys.reduce(max);
    final loopAtTheEnd = scan.loops.any((loop) => loop > lastKey);
    if (int.parse(migration.version) >= firstVersionUnderRule) {
      if (!loopAtTheEnd) {
        violations.add(
          '${migration.fullName}: cria chave para users e não roda o laço '
          'canônico no fim do up',
        );
      }
      continue;
    }
    final coveredLater = scans
        .skip(index + 1)
        .any((later) => later.loops.isNotEmpty);
    if (!loopAtTheEnd && !coveredLater) {
      violations.add(
        '${migration.fullName}: a chave para users fica sem gatilho no banco '
        'migrado (nenhum laço canônico depois dela)',
      );
    }
  }
  return violations;
}

({List<int> keys, List<int> loops}) _scan(
  List<String> statements,
  String canonicalLoop,
) {
  final keys = <int>[];
  final loops = <int>[];
  for (var index = 0; index < statements.length; index++) {
    final statement = statements[index];
    if (_normalized(statement) == canonicalLoop) {
      loops.add(index);
    } else if (_createsUsersKey(statement)) {
      keys.add(index);
    }
  }
  return (keys: keys, loops: loops);
}
